unit uDMPlanner;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.DateUtils,
  System.Generics.Collections,
  Data.DB, Data.Win.ADODB,
  uDataConnector, uSQLServerConnector, uDBMigrations, uUserPreferencesRepo,
  uCalendarsRepo, uCentresRepo, uNodesRepo, uNodeDataRepo, uAlertRulesRepo,
  uSnapshotRepo;

function UserCanAccessProject(AUserId, AProjectId: Integer): Boolean;

const
  // Colores distintivos de los nodos manuales (Source='MAN', V066), para
  // diferenciarlos de un vistazo de los nodos ERP. Compartidos por todas las
  // pantallas que crean nodos manuales.
  MANUAL_NODE_FILL   = 16444380;  // azul muy claro (relleno)
  MANUAL_NODE_BORDER = 13135400;  // azul medio (borde)

type
  TEstructuraNodos = (enSimple, enCompleja);
    // enSimple   : 1 OF = 1 OT = 1 OP
    // enCompleja : 1 OF = N OT = N OP

  // Resumen de un lote para el visor (cabecera + KPIs).
  TLoteInfo = record
    LoteId: Integer;
    Caption: string;
    CenterId: Integer;
    CentroNombre: string;
    Modo: Integer;            // 0=secuencial (suma), 1=paralelo (max)
    SetupMin: Double;         // setup compartido, en minutos
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    NumOps: Integer;          // nº de operaciones (miembros)
    DuracionOriginalTotal: Double;  // suma de DuracionMinOriginal (sin agrupar)
    DuracionOriginalMax: Double;    // maximo de DuracionMinOriginal
    function DuracionBase: Double;     // base segun Modo (suma o max)
    function DuracionEfectiva: Double; // base + SetupMin = duracion teorica del lote
    function AhorroMin: Double;        // DuracionOriginalTotal - DuracionEfectiva
    function AhorroPct: Double;        // % de ahorro sobre el total original
  end;

  TDMPlanner = class(TDataModule)
    ADOConnection: TADOConnection;
  private
    FConnector: IGanttDataConnector;
    FConnectorObj: TObject;   // referencia paralela al objeto concreto
    FServer: string;
    FDatabase: string;
    FUserName: string;
    FPassword: string;
    FUseWindowsAuth: Boolean;
    FCurrentProjectId: Integer;
    FCurrentProjectName: string;
    FCurrentProjectIsMaster: Boolean;
    FCurrentProjectFechaBloqueo: TDateTime;
    FCurrentProjectTieneBloqueo: Boolean;
    FCurrentProjectRowMode: string;
    FCurrentProjectNivelAgrupacion: Integer;
    FEnModoDemo: Boolean;
    FProjectIdAntesDemo: Integer;   // proyecto real al que volver al salir de demo
    FCodigoEmpresa: SmallInt;
    FCurrentEmpresaNombre: string;
    FPlanificaOperarios: Boolean;
    FPlanificaMoldes: Boolean;
    FEstructuraNodos: TEstructuraNodos;
    FCalendarsRepo: TCalendarsRepo;
    FCentresRepo: TCentresRepo;
    FNodesRepo: TNodesRepo;
    FNodeDataRepo: TNodeDataRepo;
    FUserPrefs: TUserPreferencesRepo;
    FAlertRulesRepo: TAlertRulesRepo;
    FSnapshotRepo: TSnapshotRepo;
    procedure BuildConnectionString;
    function GetConnectionString: string;
    procedure SetCodigoEmpresa(AValue: SmallInt);
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;

    // Conexión
    function Connect: TConnectorResult;
    function ConnectWith(const AServer, ADatabase: string;
      AWindowsAuth: Boolean; const AUser: string = ''; const APassword: string = ''): TConnectorResult;
    procedure Disconnect;
    function IsConnected: Boolean;
    procedure InstallTvfPendingErp;

    // Gestión de proyecto activo
    procedure LoadMasterProject;
    procedure LoadUserActiveProject(AUserId: Integer);
    procedure SetCurrentProject(AProjectId: Integer);

    // --- Modo demo del Gantt (V070) ----------------------------------------
    // Los nodos demo viven en un PROYECTO propio marcado con EsDemo=1, aislado
    // de los datos reales. Como todo filtra por ProjectId, entrar en modo demo
    // es solo cambiar el proyecto activo a ese proyecto (y volver al real al
    // salir). Nada de los datos reales se toca ni se mezcla.

    // Devuelve el ProjectId del proyecto demo de la empresa, creandolo si aun no
    // existe. 0 si no hay conexion.
    function GetOrCreateDemoProjectId: Integer;
    // Cambia el proyecto activo al proyecto demo, recordando el real para poder
    // volver. Idempotente. Devuelve el ProjectId demo (0 si fallo).
    function EntrarModoDemo: Integer;
    // Vuelve al proyecto real que estaba activo antes de entrar en modo demo.
    procedure SalirModoDemo;
    // Cuenta cuantos nodos tiene un proyecto (para saber si el demo esta vacio).
    function ContarNodosProyecto(AProjectId: Integer): Integer;
    // Genera ACantidad nodos ficticios repartidos por los centros REALES en el
    // proyecto AProjectId (normalmente el demo). Borra antes los nodos previos
    // de ese proyecto (regenera). Reparte fechas en el horizonte hoy..hoy+45,
    // crea NodeData completo (prioridad, entregas, articulo, cliente...) y
    // algunas dependencias en cadena. Todo en una transaccion. No toca otros
    // proyectos. Devuelve el numero de nodos creados.
    function GenerarNodosDemoEnProyecto(AProjectId, ACantidad: Integer): Integer;

    procedure LoadEmpresaInfo;
    procedure LoadCalendars;
    procedure LoadCentres;
    procedure LoadNodes;
    function CountTable(const ATableName: string): Integer;

    // Desplanifica (borra del plan) los nodos indicados: elimina dependencias,
    // asignaciones de operarios, NodeData y el propio Node, en una transaccion.
    // No comprueba bloqueo (eso es responsabilidad del llamador). Devuelve el
    // numero de nodos borrados. Compartida por Backlog y Gantt.
    function DesplanificarNodes(const ANodeIds: TArray<Integer>): Integer;

    // Crea un nodo manual (Source='MAN', V066) en el proyecto activo: inserta
    // FS_PL_Node + FS_PL_NodeData en una transaccion y devuelve el NodeId creado
    // (0 si fallo). El llamador calcula las fechas como quiera (el Gantt via el
    // motor de colocacion; el Kanban de capacidad finita via el centro/lane), por
    // eso AFechaInicio/AFechaFin llegan ya resueltas. ACenterId < 0 = "Sin Centro"
    // (CenterId NULL). El nodo nace LIBRE (LibreMovimiento=1). Compartida por
    // uVistaGantt y uFiniteCapacityPlanner para no duplicar la persistencia.
    function CrearNodoManual(const ACaption, AOperacion: string;
      ACenterId: Integer; ADuracionMin: Double;
      AFechaInicio, AFechaFin, AFechaCompromiso: TDateTime;
      const ARawItemTipoOrigen, ARawItemClaveERP: string): Integer;

    // --- Lotes (batch) de planificacion (V057) -----------------------------
    // Agrupa varios nodos en un lote: valida mismo centro, crea el lote, asigna
    // LoteId a los nodos y alinea su ventana (inicio=min, fin=max de miembros).
    // Devuelve el LoteId creado, o 0 si no se pudo (centros distintos, <2 nodos).
    function CrearLote(const ANodeIds: TArray<Integer>): Integer;
    // Deshace un lote: pone LoteId NULL a sus miembros y borra el lote.
    procedure DesagruparLote(ALoteId: Integer);
    // Saca un solo nodo del lote (LoteId NULL). No borra el lote aunque quede
    // con un solo miembro (el llamador decide si desagrupar del todo).
    procedure QuitarNodoDeLote(ANodeId: Integer);
    // Lee la cabecera + KPIs de un lote (para el visor). Devuelve True si existe.
    function GetLoteInfo(ALoteId: Integer; out AInfo: TLoteInfo): Boolean;
    // Actualiza modo y setup de un lote y RECALCULA su duracion efectiva,
    // repartiendola como ventana compartida: DuracionMin de cada miembro = la
    // efectiva (base+setup); FechaFin de miembros y lote = FechaInicio + efectiva.
    // DuracionMinOriginal NO se toca. Recalculo de calendario lo hace el reflow al
    // recargar; aqui se hace en tiempo natural (la recarga lo afina).
    procedure ActualizarLote(ALoteId, AModo: Integer; ASetupMin: Double);
    // Cuenta los miembros de un lote (para auto-desagrupar si quedan <2).
    function ContarMiembrosLote(ALoteId: Integer): Integer;

    property CalendarsRepo: TCalendarsRepo read FCalendarsRepo;
    property CentresRepo: TCentresRepo read FCentresRepo;
    property NodesRepo: TNodesRepo read FNodesRepo;
    property NodeDataRepo: TNodeDataRepo read FNodeDataRepo;
    property AlertRulesRepo: TAlertRulesRepo read FAlertRulesRepo;
    property SnapshotRepo: TSnapshotRepo read FSnapshotRepo;
    property UserPrefs: TUserPreferencesRepo read FUserPrefs;

    // Acceso al conector
    property Connector: IGanttDataConnector read FConnector;
    property CurrentProjectId: Integer read FCurrentProjectId write FCurrentProjectId;
    property CurrentProjectName: string read FCurrentProjectName;
    property EnModoDemo: Boolean read FEnModoDemo;
    property CurrentProjectIsMaster: Boolean read FCurrentProjectIsMaster;
    property CurrentProjectFechaBloqueo: TDateTime read FCurrentProjectFechaBloqueo;
    property CurrentProjectTieneBloqueo: Boolean read FCurrentProjectTieneBloqueo;
    property CurrentProjectRowMode: string read FCurrentProjectRowMode;
    property CurrentProjectNivelAgrupacion: Integer read FCurrentProjectNivelAgrupacion;
    property CurrentEmpresaNombre: string read FCurrentEmpresaNombre;
    property CodigoEmpresa: SmallInt read FCodigoEmpresa write SetCodigoEmpresa;
    property PlanificaOperarios: Boolean read FPlanificaOperarios;
    property PlanificaMoldes: Boolean read FPlanificaMoldes;
    property EstructuraNodos: TEstructuraNodos read FEstructuraNodos;
    procedure SaveEmpresaPreferencias(APlanificaOperarios, APlanificaMoldes: Boolean;
      AEstructuraNodos: TEstructuraNodos);

    // Configuración
    property Server: string read FServer write FServer;
    property Database: string read FDatabase write FDatabase;
    property UserName: string read FUserName write FUserName;
    property Password: string read FPassword write FPassword;
    property UseWindowsAuth: Boolean read FUseWindowsAuth write FUseWindowsAuth;

    // Cadena de conexion completa (incluye password si es autenticacion SQL)
    // reconstruida desde la configuracion. La deben usar los hilos que abren su
    // propia TADOConnection, en lugar de clonar ADOConnection.ConnectionString
    // (que OLE DB devuelve sin el password).
    property ConnectionStringForThreads: string read GetConnectionString;
  end;

var
  DMPlanner: TDMPlanner;

implementation

{$R *.dfm}

uses
  uLogin, uAppConfig, uCentreCalendar, uPlanLog, System.Diagnostics;

procedure TDMPlanner.InstallTvfPendingErp;
var
  ErpCfg: TErpSage200Config;
  Cmd: TADOCommand;
begin
  if not ADOConnection.Connected then Exit;
  try
    ErpCfg := LoadErpSage200Config;
  except
    Exit;
  end;
  if Trim(ErpCfg.Database) = '' then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := ADOConnection;
    Cmd.CommandText := 'EXEC dbo.FS_PL_sp_InstallTvfPendingErp :SageDbName';
    Cmd.Parameters.ParamByName('SageDbName').Value := ErpCfg.Database;
    try
      Cmd.Execute;
    except
      // Ignorat: la TVF mantindra el body provisional (retorna 0). El
      // dashboard mostrara "0 pendientes" en comptes de fallar.
    end;
  finally
    Cmd.Free;
  end;
end;

function UserCanAccessProject(AUserId, AProjectId: Integer): Boolean;
var
  Q: TADOQuery;
begin
  if IsAdmin then Exit(True);
  if (AUserId <= 0) or (AProjectId <= 0) then Exit(False);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT 1 FROM FS_PL_ProjectUser WHERE CodigoEmpresa = ' +
      IntToStr(DMPlanner.CodigoEmpresa) +
      ' AND UserId = ' + IntToStr(AUserId) +
      ' AND ProjectId = ' + IntToStr(AProjectId);
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

procedure TDMPlanner.AfterConstruction;
begin
  inherited;
  FCurrentProjectId := -1;
  FEnModoDemo := False;
  FProjectIdAntesDemo := 0;
  FCodigoEmpresa := 9999;
  FUseWindowsAuth := True;
  FCalendarsRepo := TCalendarsRepo.Create(ADOConnection);
  FCentresRepo := TCentresRepo.Create(ADOConnection, FCalendarsRepo);
  FNodesRepo := TNodesRepo.Create(ADOConnection);
  FNodeDataRepo := TNodeDataRepo.Create;
  FUserPrefs := TUserPreferencesRepo.Create(ADOConnection, FCodigoEmpresa);
  FAlertRulesRepo := TAlertRulesRepo.Create(ADOConnection);
end;

procedure TDMPlanner.SetCodigoEmpresa(AValue: SmallInt);
begin
  FCodigoEmpresa := AValue;
  // Propagar al conector concreto para que los INSERT/UPDATE puedan rellenar
  // la columna CodigoEmpresa de las tablas FS_PL_*.
  if Assigned(FConnectorObj) and (FConnectorObj is TSQLServerConnector) then
    TSQLServerConnector(FConnectorObj).CodigoEmpresa := AValue;
  if Assigned(FUserPrefs) then
    FUserPrefs.CodigoEmpresa := AValue;
  if Assigned(FSnapshotRepo) then
    FSnapshotRepo.SetContext(AValue, CurrentSession.UserId, CurrentSession.Login);
end;

destructor TDMPlanner.Destroy;
begin
  FUserPrefs.Free;
  FNodeDataRepo.Free;
  FNodesRepo.Free;
  FCentresRepo.Free;
  FCalendarsRepo.Free;
  FAlertRulesRepo.Free;
  FSnapshotRepo.Free;
  inherited;
end;

procedure TDMPlanner.LoadCalendars;
begin
  if (FCalendarsRepo <> nil) and IsConnected then
    FCalendarsRepo.LoadFromDB(FCodigoEmpresa);
  // Reglas de alertas (seed + carga). Se hace aqui porque LoadCalendars se
  // invoca al abrir la conexion, antes de mostrar el Gantt.
  if (FAlertRulesRepo <> nil) and IsConnected then
    FAlertRulesRepo.LoadFromDB(FCodigoEmpresa);
end;

procedure TDMPlanner.LoadCentres;
begin
  if (FCentresRepo <> nil) and IsConnected then
    FCentresRepo.LoadFromDB(FCodigoEmpresa);
end;

procedure TDMPlanner.LoadNodes;
begin
  if Assigned(FNodeDataRepo) then
    FNodeDataRepo.Clear;
  if (FNodesRepo <> nil) and IsConnected and (FCurrentProjectId > 0) then
    FNodesRepo.LoadFromDB(FCodigoEmpresa, FCurrentProjectId, FNodeDataRepo);
end;

function TDMPlanner.CountTable(const ATableName: string): Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  if not IsConnected then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT COUNT(*) AS N FROM ' + ATableName +
      ' WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa);
    Q.Open;
    if not Q.Eof then
      Result := Q.FieldByName('N').AsInteger;
  finally
    Q.Free;
  end;
end;

function TDMPlanner.DesplanificarNodes(const ANodeIds: TArray<Integer>): Integer;
var
  Cmd: TADOCommand;
  IdList, CE: string;
  I: Integer;
begin
  Result := 0;
  if Length(ANodeIds) = 0 then Exit;
  if not IsConnected then Exit;

  IdList := '';
  for I := 0 to High(ANodeIds) do
  begin
    if IdList <> '' then IdList := IdList + ',';
    IdList := IdList + IntToStr(ANodeIds[I]);
  end;
  CE := IntToStr(FCodigoEmpresa);

  ADOConnection.BeginTrans;
  try
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := ADOConnection;

      // Dependencias que referencian estos nodos
      Cmd.CommandText :=
        'DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa = ' + CE +
        ' AND (FromNodeId IN (' + IdList + ') OR ToNodeId IN (' + IdList + '))';
      Cmd.Execute;

      // Asignaciones de operarios
      Cmd.CommandText :=
        'DELETE FROM FS_PL_OperatorAssignment WHERE CodigoEmpresa = ' + CE +
        ' AND NodeId IN (' + IdList + ')';
      Cmd.Execute;

      // NodeData
      Cmd.CommandText :=
        'DELETE FROM FS_PL_NodeData WHERE CodigoEmpresa = ' + CE +
        ' AND NodeId IN (' + IdList + ')';
      Cmd.Execute;

      // Nodos.
      Cmd.CommandText :=
        'DELETE FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
        ' AND NodeId IN (' + IdList + ')';
      Cmd.Execute;
      // TADOCommand no expone RowsAffected; devolvemos los solicitados (el
      // numero de nodos borrados coincide salvo que algun id ya no existiera).
      Result := Length(ANodeIds);
    finally
      Cmd.Free;
    end;
    ADOConnection.CommitTrans;
  except
    ADOConnection.RollbackTrans;
    raise;
  end;
end;

function TDMPlanner.CrearNodoManual(const ACaption, AOperacion: string;
  ACenterId: Integer; ADuracionMin: Double;
  AFechaInicio, AFechaFin, AFechaCompromiso: TDateTime;
  const ARawItemTipoOrigen, ARawItemClaveERP: string): Integer;
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  CE, PID: string;

  function QS(const S: string): string;
  begin
    Result := QuotedStr(S);
  end;
  function DT(const V: TDateTime): string;
  begin
    Result := QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', V));
  end;
  // Fecha SQL, o 'NULL' literal si no hay fecha (V < 1).
  function DTorNull(const V: TDateTime): string;
  begin
    if V >= 1 then
      Result := DT(V)
    else
      Result := 'NULL';
  end;
  function Flt(const V: Double): string;
  begin
    Result := FloatToStr(V, TFormatSettings.Invariant);
  end;
  // Devuelve la clave SQL entre comillas, o 'NULL' literal si esta vacia.
  function StrOrNull(const S: string): string;
  begin
    if S <> '' then
      Result := QuotedStr(S)
    else
      Result := 'NULL';
  end;
  // CenterId SQL: el valor, o 'NULL' literal si es "Sin Centro" (<0).
  function CenterOrNull(const ACId: Integer): string;
  begin
    if ACId >= 0 then
      Result := IntToStr(ACId)
    else
      Result := 'NULL';
  end;

begin
  Result := 0;
  if not IsConnected then Exit;

  CE  := IntToStr(FCodigoEmpresa);
  PID := IntToStr(FCurrentProjectId);

  ADOConnection.BeginTrans;
  try
    // 1) FS_PL_Node con Source='MAN'. CenterId NULL si es "Sin Centro" (<0).
    //    Color distintivo (azul claro / borde azul) para diferenciarlos de un
    //    vistazo de los nodos ERP (amarillo). (V066)
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := ADOConnection;
      Cmd.CommandText :=
        'INSERT INTO FS_PL_Node (CodigoEmpresa, ProjectId, CenterId, ' +
        '  FechaInicio, FechaFin, DuracionMin, Caption, ColorFondo, ColorBorde, ' +
        '  Visible, Habilitado, Source) VALUES (' +
        CE + ', ' + PID + ', ' +
        CenterOrNull(ACenterId) + ', ' +
        DT(AFechaInicio) + ', ' + DT(AFechaFin) + ', ' + Flt(ADuracionMin) + ', ' +
        QS(ACaption) + ', ' + IntToStr(MANUAL_NODE_FILL) + ', ' +
        IntToStr(MANUAL_NODE_BORDER) + ', 1, 1, ''MAN'')';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;

    // 2) Recuperar el NodeId creado (MAX dentro del mismo proyecto).
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := ADOConnection;
      Q.SQL.Text :=
        'SELECT MAX(NodeId) AS NewId FROM FS_PL_Node ' +
        'WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID;
      Q.Open;
      Result := Q.FieldByName('NewId').AsInteger;
    finally
      Q.Free;
    end;

    // 3) FS_PL_NodeData: caption como Operacion, duracion y vinculo ERP opcional.
    //    LibreMovimiento=1 -> el nodo manual entra en el recalculo automatico.
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := ADOConnection;
      Cmd.CommandText :=
        'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, ' +
        '  DuracionMin, DuracionMinOriginal, OperariosNecesarios, ' +
        '  LibreMovimiento, FechaEntrega, FechaNecesaria, ' +
        '  RawItemClaveERP, RawItemTipoOrigen, ' +
        '  ColorFondoOp, ColorBordeOp) VALUES (' +
        CE + ', ' + IntToStr(Result) + ', ' + QS(AOperacion) + ', ' +
        Flt(ADuracionMin) + ', ' + Flt(ADuracionMin) + ', 0, 1, ' +
        DTorNull(AFechaCompromiso) + ', ' +
        DTorNull(AFechaCompromiso) + ', ' +
        StrOrNull(ARawItemClaveERP) + ', ' +
        StrOrNull(ARawItemTipoOrigen) + ', ' +
        '15251072, 11166760)';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;

    ADOConnection.CommitTrans;
  except
    ADOConnection.RollbackTrans;
    Result := 0;
    raise;
  end;
end;

// --- Lotes (batch) ---------------------------------------------------------

function TDMPlanner.CrearLote(const ANodeIds: TArray<Integer>): Integer;
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  IdList, CE, PID: string;
  I, CenterId: Integer;
  FIni, FFin: TDateTime;
begin
  Result := 0;
  if Length(ANodeIds) < 2 then Exit;   // un lote tiene sentido con >=2 nodos
  if not IsConnected then Exit;

  IdList := '';
  for I := 0 to High(ANodeIds) do
  begin
    if IdList <> '' then IdList := IdList + ',';
    IdList := IdList + IntToStr(ANodeIds[I]);
  end;
  CE := IntToStr(FCodigoEmpresa);
  PID := IntToStr(FCurrentProjectId);

  // Validar: todos del mismo centro + recoger la ventana (min/max) y el centro.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text :=
      'SELECT COUNT(DISTINCT CenterId) AS NumCentros, MIN(CenterId) AS Centro, ' +
      '  MIN(FechaInicio) AS FIni, MAX(FechaFin) AS FFin ' +
      'FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
      '  AND NodeId IN (' + IdList + ')';
    Q.Open;
    if Q.Eof or (Q.FieldByName('NumCentros').AsInteger <> 1) then
      Exit;   // centros distintos o sin centro -> no se puede agrupar
    CenterId := Q.FieldByName('Centro').AsInteger;
    if Q.FieldByName('FIni').IsNull or Q.FieldByName('FFin').IsNull then
      Exit;
    FIni := Q.FieldByName('FIni').AsDateTime;
    FFin := Q.FieldByName('FFin').AsDateTime;
  finally
    Q.Free;
  end;

  ADOConnection.BeginTrans;
  try
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := ADOConnection;

      // Crear el lote con la ventana comun.
      Cmd.CommandText :=
        'INSERT INTO FS_PL_Lote (CodigoEmpresa, ProjectId, CenterId, Caption, ' +
        '  FechaInicio, FechaFin) VALUES (' + CE + ', ' + PID + ', ' +
        IntToStr(CenterId) + ', ' +
        'N''Lote '' + CONVERT(NVARCHAR(20), ' + IntToStr(Length(ANodeIds)) + ') + N'' op.'', ' +
        '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FIni) + ''', ' +
        '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FFin) + ''')';
      Cmd.Execute;

      // Recuperar el LoteId recien creado.
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := ADOConnection;
        Q.SQL.Text :=
          'SELECT MAX(LoteId) AS NewId FROM FS_PL_Lote ' +
          'WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID;
        Q.Open;
        Result := Q.FieldByName('NewId').AsInteger;
      finally
        Q.Free;
      end;

      // Asignar el lote a los nodos y alinear su ventana a la del lote.
      Cmd.CommandText :=
        'UPDATE FS_PL_Node SET LoteId = ' + IntToStr(Result) + ', ' +
        '  FechaInicio = ''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FIni) + ''', ' +
        '  FechaFin = ''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FFin) + ''' ' +
        'WHERE CodigoEmpresa = ' + CE + ' AND NodeId IN (' + IdList + ')';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
    ADOConnection.CommitTrans;
  except
    ADOConnection.RollbackTrans;
    raise;
  end;
end;

procedure TDMPlanner.DesagruparLote(ALoteId: Integer);
var
  Cmd: TADOCommand;
  CE: string;
begin
  if ALoteId <= 0 then Exit;
  if not IsConnected then Exit;
  CE := IntToStr(FCodigoEmpresa);

  ADOConnection.BeginTrans;
  try
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := ADOConnection;
      // RESTAURAR la duracion real de cada OP del lote: dentro del lote
      // DuracionMin (en FS_PL_NodeData) guardaba el ancho de la ventana
      // compartida; al salir, cada OP vuelve a su duracion real
      // (DuracionMinOriginal). FechaFin se recalcula al recargar el plan.
      Cmd.CommandText :=
        'UPDATE nd SET nd.DuracionMin = nd.DuracionMinOriginal ' +
        'FROM FS_PL_NodeData nd ' +
        'INNER JOIN FS_PL_Node n ON n.CodigoEmpresa = nd.CodigoEmpresa ' +
        '  AND n.NodeId = nd.NodeId ' +
        'WHERE nd.CodigoEmpresa = ' + CE +
        ' AND n.LoteId = ' + IntToStr(ALoteId) +
        ' AND nd.DuracionMinOriginal IS NOT NULL AND nd.DuracionMinOriginal > 0';
      Cmd.Execute;
      // Liberar los nodos del lote (FK), luego se borra el lote.
      Cmd.CommandText :=
        'UPDATE FS_PL_Node SET LoteId = NULL WHERE CodigoEmpresa = ' + CE +
        ' AND LoteId = ' + IntToStr(ALoteId);
      Cmd.Execute;
      Cmd.CommandText :=
        'DELETE FROM FS_PL_Lote WHERE CodigoEmpresa = ' + CE +
        ' AND LoteId = ' + IntToStr(ALoteId);
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
    ADOConnection.CommitTrans;
  except
    ADOConnection.RollbackTrans;
    raise;
  end;
end;

procedure TDMPlanner.QuitarNodoDeLote(ANodeId: Integer);
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  CE, NID: string;
  LoteId: Integer;
  FinLote: TDateTime;
  TeFinLote: Boolean;
  DurReal: Double;
begin
  if ANodeId <= 0 then Exit;
  if not IsConnected then Exit;
  CE := IntToStr(FCodigoEmpresa);
  NID := IntToStr(ANodeId);

  // Leer el lote del nodo, el fin de su ventana y la duracion real del nodo,
  // para recolocar el nodo JUSTO detras del lote al salir (si no, quedaria
  // solapado con la barra del lote). Calculo en Delphi -> SQL simple con literales.
  LoteId := 0; FinLote := 0; TeFinLote := False; DurReal := 0;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text :=
      'SELECT n.LoteId, l.FechaFin, ' +
      '  ISNULL(NULLIF(nd.DuracionMinOriginal,0), ISNULL(nd.DuracionMin, ISNULL(n.DuracionMin,1))) AS Dur ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_Lote l ON l.CodigoEmpresa = n.CodigoEmpresa AND l.LoteId = n.LoteId ' +
      'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = ' + CE + ' AND n.NodeId = ' + NID;
    Q.Open;
    if not Q.Eof and not Q.FieldByName('LoteId').IsNull then
    begin
      LoteId := Q.FieldByName('LoteId').AsInteger;
      DurReal := Q.FieldByName('Dur').AsFloat;
      if not Q.FieldByName('FechaFin').IsNull then
      begin
        FinLote := Q.FieldByName('FechaFin').AsDateTime;
        TeFinLote := True;
      end;
    end;
  finally
    Q.Free;
  end;
  if DurReal < 1 then DurReal := 1;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := ADOConnection;
    // Restaurar duracion real del nodo que sale del lote (ver DesagruparLote).
    Cmd.CommandText :=
      'UPDATE FS_PL_NodeData SET DuracionMin = DuracionMinOriginal ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND NodeId = ' + NID +
      ' AND DuracionMinOriginal IS NOT NULL AND DuracionMinOriginal > 0';
    Cmd.Execute;

    // Sacar del lote y, si tenemos el fin del lote, recolocar el nodo justo
    // detras: FechaInicio = fin del lote; FechaFin = inicio + duracion real
    // (tiempo natural; el reflow del Gantt al recargar lo ajusta al calendario
    // y resuelve colisiones con otros nodos del centro).
    if TeFinLote then
      Cmd.CommandText :=
        'UPDATE FS_PL_Node SET LoteId = NULL, FechaInicio = ''' +
          FormatDateTime('yyyy-mm-dd hh:nn:ss', FinLote) + ''', FechaFin = ''' +
          FormatDateTime('yyyy-mm-dd hh:nn:ss', IncMinute(FinLote, Round(DurReal))) + ''' ' +
        'WHERE CodigoEmpresa = ' + CE + ' AND NodeId = ' + NID
    else
      Cmd.CommandText :=
        'UPDATE FS_PL_Node SET LoteId = NULL WHERE CodigoEmpresa = ' + CE +
        ' AND NodeId = ' + NID;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

// --- TLoteInfo: KPIs derivados ----------------------------------------------
function TLoteInfo.DuracionBase: Double;
begin
  if Modo = 1 then            // paralelo (hornada): la duracion la marca la OP mas larga
    Result := DuracionOriginalMax
  else                        // secuencial: una tras otra -> suma
    Result := DuracionOriginalTotal;
end;

function TLoteInfo.DuracionEfectiva: Double;
begin
  Result := DuracionBase + SetupMin;
end;

function TLoteInfo.AhorroMin: Double;
begin
  // Cuanto se ahorra frente a hacerlas sueltas (suma de reales).
  Result := DuracionOriginalTotal - DuracionEfectiva;
end;

function TLoteInfo.AhorroPct: Double;
begin
  if DuracionOriginalTotal > 0 then
    Result := AhorroMin / DuracionOriginalTotal * 100.0
  else
    Result := 0;
end;

function TDMPlanner.GetLoteInfo(ALoteId: Integer; out AInfo: TLoteInfo): Boolean;
var
  Q: TADOQuery;
begin
  Result := False;
  AInfo := Default(TLoteInfo);
  if (ALoteId <= 0) or not IsConnected then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    // Cabecera del lote + nombre del centro + agregados de duracion de miembros.
    Q.SQL.Text :=
      'SELECT l.LoteId, ISNULL(l.Caption,'''') AS Caption, l.CenterId, ' +
      '  ISNULL(c.Titulo,'''') AS Centro, ISNULL(l.Modo,0) AS Modo, ' +
      '  ISNULL(l.SetupMin,0) AS SetupMin, l.FechaInicio, l.FechaFin, ' +
      '  (SELECT COUNT(*) FROM FS_PL_Node n ' +
      '     WHERE n.CodigoEmpresa = l.CodigoEmpresa AND n.LoteId = l.LoteId) AS NumOps, ' +
      '  (SELECT ISNULL(SUM(nd.DuracionMinOriginal),0) FROM FS_PL_Node n ' +
      '     JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa=n.CodigoEmpresa AND nd.NodeId=n.NodeId ' +
      '     WHERE n.CodigoEmpresa = l.CodigoEmpresa AND n.LoteId = l.LoteId) AS SumOrig, ' +
      '  (SELECT ISNULL(MAX(nd.DuracionMinOriginal),0) FROM FS_PL_Node n ' +
      '     JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa=n.CodigoEmpresa AND nd.NodeId=n.NodeId ' +
      '     WHERE n.CodigoEmpresa = l.CodigoEmpresa AND n.LoteId = l.LoteId) AS MaxOrig ' +
      'FROM FS_PL_Lote l ' +
      'LEFT JOIN FS_PL_Center c ON c.CodigoEmpresa = l.CodigoEmpresa AND c.CenterId = l.CenterId ' +
      'WHERE l.CodigoEmpresa = :Emp AND l.LoteId = :Lote';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Lote').Value := ALoteId;
    Q.Open;
    if Q.Eof then Exit;

    AInfo.LoteId       := Q.FieldByName('LoteId').AsInteger;
    AInfo.Caption      := Q.FieldByName('Caption').AsString;
    AInfo.CenterId     := Q.FieldByName('CenterId').AsInteger;
    AInfo.CentroNombre := Q.FieldByName('Centro').AsString;
    AInfo.Modo         := Q.FieldByName('Modo').AsInteger;
    AInfo.SetupMin     := Q.FieldByName('SetupMin').AsFloat;
    if not Q.FieldByName('FechaInicio').IsNull then
      AInfo.FechaInicio := Q.FieldByName('FechaInicio').AsDateTime;
    if not Q.FieldByName('FechaFin').IsNull then
      AInfo.FechaFin := Q.FieldByName('FechaFin').AsDateTime;
    AInfo.NumOps                := Q.FieldByName('NumOps').AsInteger;
    AInfo.DuracionOriginalTotal := Q.FieldByName('SumOrig').AsFloat;
    AInfo.DuracionOriginalMax   := Q.FieldByName('MaxOrig').AsFloat;
    Result := True;
  finally
    Q.Free;
  end;
end;

procedure TDMPlanner.ActualizarLote(ALoteId, AModo: Integer; ASetupMin: Double);
var
  Cmd: TADOCommand;
  CE, LID: string;
  Info: TLoteInfo;
  Efectiva: Double;
begin
  if (ALoteId <= 0) or not IsConnected then Exit;
  CE := IntToStr(FCodigoEmpresa);
  LID := IntToStr(ALoteId);

  ADOConnection.BeginTrans;
  try
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := ADOConnection;

      // 1) Guardar modo + setup.
      Cmd.CommandText :=
        'UPDATE FS_PL_Lote SET Modo = ' + IntToStr(AModo) +
        ', SetupMin = ' + StringReplace(FloatToStr(ASetupMin), ',', '.', [rfReplaceAll]) +
        ' WHERE CodigoEmpresa = ' + CE + ' AND LoteId = ' + LID;
      Cmd.Execute;

      // 2) Recalcular la duracion efectiva con los nuevos valores y repartirla
      //    como ventana compartida. Releemos info DESPUES del update de modo/setup.
      if GetLoteInfo(ALoteId, Info) then
      begin
        Efectiva := Info.DuracionEfectiva;
        if Efectiva < 1 then Efectiva := 1;

        // Todos los miembros: DuracionMin = efectiva (ancho de la ventana del lote).
        // DuracionMinOriginal queda intacto (duracion real de cada OP).
        Cmd.CommandText :=
          'UPDATE nd SET nd.DuracionMin = ' +
          StringReplace(FloatToStr(Efectiva), ',', '.', [rfReplaceAll]) + ' ' +
          'FROM FS_PL_NodeData nd ' +
          'JOIN FS_PL_Node n ON n.CodigoEmpresa = nd.CodigoEmpresa AND n.NodeId = nd.NodeId ' +
          'WHERE nd.CodigoEmpresa = ' + CE + ' AND n.LoteId = ' + LID;
        Cmd.Execute;

        // FechaFin (miembros + lote) = FechaInicio + efectiva (tiempo natural; el
        // reflow del Gantt al recargar lo ajusta al calendario laboral).
        Cmd.CommandText :=
          'UPDATE FS_PL_Node SET FechaFin = DATEADD(MINUTE, ' +
          IntToStr(Round(Efectiva)) + ', FechaInicio) ' +
          'WHERE CodigoEmpresa = ' + CE + ' AND LoteId = ' + LID +
          ' AND FechaInicio IS NOT NULL';
        Cmd.Execute;

        Cmd.CommandText :=
          'UPDATE FS_PL_Lote SET FechaFin = DATEADD(MINUTE, ' +
          IntToStr(Round(Efectiva)) + ', FechaInicio) ' +
          'WHERE CodigoEmpresa = ' + CE + ' AND LoteId = ' + LID +
          ' AND FechaInicio IS NOT NULL';
        Cmd.Execute;
      end;
    finally
      Cmd.Free;
    end;
    ADOConnection.CommitTrans;
  except
    ADOConnection.RollbackTrans;
    raise;
  end;
end;

function TDMPlanner.ContarMiembrosLote(ALoteId: Integer): Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  if (ALoteId <= 0) or not IsConnected then Exit;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM FS_PL_Node WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa) + ' AND LoteId = ' + IntToStr(ALoteId);
    Q.Open;
    Result := Q.FieldByName('N').AsInteger;
  finally
    Q.Free;
  end;
end;

function TDMPlanner.GetConnectionString: string;
begin
  // Cadena de conexion del Planner construida desde SU PROPIA configuracion
  // ([Database] del INI). No se mezcla con la del ERP: aunque compartan servidor,
  // el catalogo (BD de las tablas FS_PL_*) es distinto del de Sage.
  //
  // Si no hay servidor configurado, la conexion principal se abrio con la cadena
  // de diseno del DFM; devolvemos la cadena viva en lugar de generar un Data
  // Source vacio (-> "Named Pipes: error 2").
  if Trim(FServer) = '' then
    Exit(ADOConnection.ConnectionString);

  Result := 'Provider=MSOLEDBSQL.1;Data Source=' + FServer +
            ';Initial Catalog=' + FDatabase;
  if FUseWindowsAuth then
    Result := Result + ';Integrated Security=SSPI'
  else
    // Persist Security Info=True: necesario para que el password sobreviva al
    // leer ConnectionString despues de conectar (lo necesitan los hilos que
    // clonan la conexion, p.ej. la carga del Backlog). Sin esto, OLE DB elimina
    // el password al exportar la cadena y la reconexion en el hilo falla.
    Result := Result + ';User ID=' + FUserName + ';Password=' + FPassword +
              ';Persist Security Info=True';
end;

procedure TDMPlanner.BuildConnectionString;
begin
  ADOConnection.ConnectionString := GetConnectionString;
end;

function TDMPlanner.Connect: TConnectorResult;
var
  Migrator: TDBMigrator;
  MigResult: TMigrationResult;
  MigrationsPath: string;
begin
  try
    if FServer <> '' then
      BuildConnectionString;
    ADOConnection.Connected := True;
    var SQLConn := TSQLServerConnector.Create(ADOConnection);
    SQLConn.CodigoEmpresa := FCodigoEmpresa;
    FConnectorObj := SQLConn;
    FConnector := SQLConn;

    // Repo de puntos de restauracion (necesita el connector ya creado).
    FreeAndNil(FSnapshotRepo);
    FSnapshotRepo := TSnapshotRepo.Create(ADOConnection, FConnector);
    FSnapshotRepo.SetContext(FCodigoEmpresa, CurrentSession.UserId,
      CurrentSession.Login);

    // Aplicar migraciones pendientes automáticamente
    MigrationsPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'SQL\migrations');
    if not TDirectory.Exists(MigrationsPath) then
      MigrationsPath := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\SQL\migrations');

    if TDirectory.Exists(MigrationsPath) then
    begin
      Migrator := TDBMigrator.Create(ADOConnection, MigrationsPath);
      try
        MigResult := Migrator.RunPendingMigrations;
        if not MigResult.Success then
          Exit(TConnectorResult.Fail('Error aplicando migraciones: ' + MigResult.ErrorMessage));
      finally
        Migrator.Free;
      end;
    end;

    // Instala el body real de la TVF FS_PL_fn_PendingErpOFs apuntando a la
    // BD Sage configurada en el INI. Si no hay Sage configurado o falla,
    // ignoramos: la TVF se queda con el body provisional (retorna 0).
    InstallTvfPendingErp;

    Result := TConnectorResult.OK;
  except
    on E: Exception do
      Result := TConnectorResult.Fail('Error de conexión: ' + E.Message);
  end;
end;

function TDMPlanner.ConnectWith(const AServer, ADatabase: string;
  AWindowsAuth: Boolean; const AUser, APassword: string): TConnectorResult;
begin
  FServer := AServer;
  FDatabase := ADatabase;
  FUseWindowsAuth := AWindowsAuth;
  FUserName := AUser;
  FPassword := APassword;
  Result := Connect;
end;

procedure TDMPlanner.Disconnect;
begin
  FConnector := nil;
  FConnectorObj := nil;
  if ADOConnection.Connected then
    ADOConnection.Connected := False;
end;

function TDMPlanner.IsConnected: Boolean;
begin
  Result := ADOConnection.Connected;
end;

procedure TDMPlanner.LoadEmpresaInfo;
var
  Q: TADOQuery;
begin
  FCurrentEmpresaNombre := '';
  FPlanificaOperarios := True;
  FPlanificaMoldes := False;
  FEstructuraNodos := enCompleja;

  if not IsConnected then Exit;

  // Primera consulta: solo Nombre (funciona aunque V008 no se haya aplicado).
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT Nombre FROM FS_PL_Empresa WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa);
    Q.Open;
    if not Q.Eof then
      FCurrentEmpresaNombre := Q.FieldByName('Nombre').AsString;
  finally
    Q.Free;
  end;

  // Segunda consulta: columnas de V008. Si no existen, quedarán los defaults.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text :=
      'SELECT PlanificaOperarios, PlanificaMoldes, EstructuraNodos ' +
      'FROM FS_PL_Empresa WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa);
    try
      Q.Open;
      if not Q.Eof then
      begin
        FPlanificaOperarios := Q.FieldByName('PlanificaOperarios').AsBoolean;
        FPlanificaMoldes := Q.FieldByName('PlanificaMoldes').AsBoolean;
        if Q.FieldByName('EstructuraNodos').AsInteger = 0 then
          FEstructuraNodos := enSimple
        else
          FEstructuraNodos := enCompleja;
      end;
    except
      // Columnas V008 aún no creadas: seguimos con los defaults en memoria.
    end;
  finally
    Q.Free;
  end;

  LoadCalendars;
  LoadCentres;
end;

procedure TDMPlanner.SaveEmpresaPreferencias(APlanificaOperarios,
  APlanificaMoldes: Boolean; AEstructuraNodos: TEstructuraNodos);
var
  Cmd: TADOCommand;
begin
  if not IsConnected then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := ADOConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_Empresa SET ' +
      '  PlanificaOperarios = ' + IntToStr(Ord(APlanificaOperarios)) + ', ' +
      '  PlanificaMoldes    = ' + IntToStr(Ord(APlanificaMoldes)) + ', ' +
      '  EstructuraNodos    = ' + IntToStr(Ord(AEstructuraNodos)) + ' ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  FPlanificaOperarios := APlanificaOperarios;
  FPlanificaMoldes := APlanificaMoldes;
  FEstructuraNodos := AEstructuraNodos;
end;

procedure TDMPlanner.LoadMasterProject;
var
  Q: TADOQuery;
begin
  FCurrentProjectId := -1;
  FCurrentProjectName := '';
  FCurrentProjectIsMaster := False;
  FCurrentProjectFechaBloqueo := 0;
  FCurrentProjectTieneBloqueo := False;
  FCurrentProjectRowMode := 'CENTROS';
  FCurrentProjectNivelAgrupacion := 1;

  if not IsConnected then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT ProjectId, Nombre, EsMaster, FechaBloqueo, RowMode, NivelAgrupacion ' +
      'FROM FS_PL_Project ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      ' AND EsMaster = 1 AND Activo = 1';
    Q.Open;
    if not Q.Eof then
    begin
      FCurrentProjectId := Q.FieldByName('ProjectId').AsInteger;
      FCurrentProjectName := Q.FieldByName('Nombre').AsString;
      FCurrentProjectIsMaster := True;
      FCurrentProjectTieneBloqueo := not Q.FieldByName('FechaBloqueo').IsNull;
      if FCurrentProjectTieneBloqueo then
        FCurrentProjectFechaBloqueo := Q.FieldByName('FechaBloqueo').AsDateTime;
      if Q.FindField('RowMode') <> nil then
        FCurrentProjectRowMode := Q.FieldByName('RowMode').AsString;
      if Q.FindField('NivelAgrupacion') <> nil then
        FCurrentProjectNivelAgrupacion := Q.FieldByName('NivelAgrupacion').AsInteger;
    end;
  finally
    Q.Free;
  end;
end;

procedure TDMPlanner.LoadUserActiveProject(AUserId: Integer);
var
  Q: TADOQuery;
  ProjId: Integer;
begin
  if (not IsConnected) or (AUserId <= 0) then
  begin
    LoadMasterProject;
    Exit;
  end;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT ProjectId FROM FS_PL_UserActiveProject ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      ' AND UserId = ' + IntToStr(AUserId);
    Q.Open;
    if not Q.Eof then
    begin
      ProjId := Q.FieldByName('ProjectId').AsInteger;
      if UserCanAccessProject(AUserId, ProjId) then
      begin
        SetCurrentProject(ProjId);
        if FCurrentProjectId > 0 then Exit;
      end;
    end;
  finally
    Q.Free;
  end;

  // Fallback: admin -> MASTER; resto -> primer proyecto asignado
  if IsAdmin then
    LoadMasterProject
  else
  begin
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := ADOConnection;
      Q.SQL.Text :=
        'SELECT TOP 1 pu.ProjectId FROM FS_PL_ProjectUser pu ' +
        'INNER JOIN FS_PL_Project p ON p.CodigoEmpresa = pu.CodigoEmpresa ' +
        '  AND p.ProjectId = pu.ProjectId ' +
        'WHERE pu.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
        ' AND pu.UserId = ' + IntToStr(AUserId) +
        ' AND p.Activo = 1 ' +
        'ORDER BY p.EsMaster DESC, p.FechaCreacion DESC';
      Q.Open;
      if not Q.Eof then
        SetCurrentProject(Q.FieldByName('ProjectId').AsInteger);
    finally
      Q.Free;
    end;
  end;
end;

procedure TDMPlanner.SetCurrentProject(AProjectId: Integer);
var
  Q: TADOQuery;
begin
  if not IsConnected then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT ProjectId, Nombre, EsMaster, FechaBloqueo, RowMode, NivelAgrupacion ' +
      'FROM FS_PL_Project ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      ' AND ProjectId = ' + IntToStr(AProjectId);
    Q.Open;
    if not Q.Eof then
    begin
      FCurrentProjectId := Q.FieldByName('ProjectId').AsInteger;
      FCurrentProjectName := Q.FieldByName('Nombre').AsString;
      FCurrentProjectIsMaster := Q.FieldByName('EsMaster').AsBoolean;
      FCurrentProjectTieneBloqueo := not Q.FieldByName('FechaBloqueo').IsNull;
      if FCurrentProjectTieneBloqueo then
        FCurrentProjectFechaBloqueo := Q.FieldByName('FechaBloqueo').AsDateTime
      else
        FCurrentProjectFechaBloqueo := 0;
      if Q.FindField('RowMode') <> nil then
        FCurrentProjectRowMode := Q.FieldByName('RowMode').AsString
      else
        FCurrentProjectRowMode := 'CENTROS';
      if Q.FindField('NivelAgrupacion') <> nil then
        FCurrentProjectNivelAgrupacion := Q.FieldByName('NivelAgrupacion').AsInteger
      else
        FCurrentProjectNivelAgrupacion := 1;
    end;
  finally
    Q.Free;
  end;
end;

{ --- Modo demo del Gantt (V070) ------------------------------------------- }

function TDMPlanner.GetOrCreateDemoProjectId: Integer;
var
  Q: TADOQuery;
  Cmd: TADOCommand;
  CE: string;
begin
  Result := 0;
  if not IsConnected then Exit;
  CE := IntToStr(FCodigoEmpresa);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    // 1. Ya existe el proyecto demo de esta empresa.
    Q.SQL.Text :=
      'SELECT TOP 1 ProjectId FROM FS_PL_Project ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND ISNULL(EsDemo, 0) = 1 ' +
      'ORDER BY ProjectId';
    Q.Open;
    if not Q.Eof then
    begin
      Result := Q.FieldByName('ProjectId').AsInteger;
      Exit;
    end;
  finally
    Q.Free;
  end;

  // 2. No existe: crearlo. Codigo unico por empresa (UQ_FS_PL_Project_Codigo).
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := ADOConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_Project ' +
      '  (CodigoEmpresa, Codigo, Nombre, Descripcion, EsMaster, EsDemo, Activo) ' +
      'VALUES (' + CE + ', ' + QuotedStr('DEMO') + ', ' +
      QuotedStr(#9733' DEMOSTRACI'#211'N') + ', ' +
      QuotedStr('Proyecto de demostraci'#243'n (datos ficticios, aislados del plan real)') +
      ', 0, 1, 1)';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // 3. Releer el ProjectId recien creado.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text :=
      'SELECT TOP 1 ProjectId FROM FS_PL_Project ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND ISNULL(EsDemo, 0) = 1 ' +
      'ORDER BY ProjectId DESC';
    Q.Open;
    if not Q.Eof then
      Result := Q.FieldByName('ProjectId').AsInteger;
  finally
    Q.Free;
  end;
end;

function TDMPlanner.EntrarModoDemo: Integer;
var
  DemoId: Integer;
begin
  Result := 0;
  DemoId := GetOrCreateDemoProjectId;
  if DemoId <= 0 then Exit;

  if not FEnModoDemo then
    FProjectIdAntesDemo := FCurrentProjectId;   // recordar el real solo una vez
  FEnModoDemo := True;
  SetCurrentProject(DemoId);
  Result := DemoId;
end;

procedure TDMPlanner.SalirModoDemo;
begin
  if not FEnModoDemo then Exit;
  FEnModoDemo := False;
  if FProjectIdAntesDemo > 0 then
    SetCurrentProject(FProjectIdAntesDemo);
  FProjectIdAntesDemo := 0;
end;

function TDMPlanner.ContarNodosProyecto(AProjectId: Integer): Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  if (not IsConnected) or (AProjectId <= 0) then Exit;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM FS_PL_Node ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      ' AND ProjectId = ' + IntToStr(AProjectId);
    Q.Open;
    Result := Q.FieldByName('N').AsInteger;
  finally
    Q.Free;
  end;
end;

function TDMPlanner.GenerarNodosDemoEnProyecto(AProjectId, ACantidad: Integer): Integer;
const
  OPS: array[0..9] of string = (
    'CORTAR', 'MECANIZAR', 'FRESAR', 'TORNEAR', 'SOLDAR',
    'PULIR', 'PINTAR', 'MONTAR', 'REVISAR', 'EMBALAR');
  ARTS: array[0..7] of string = (
    'ART-1001', 'ART-1002', 'ART-2050', 'ART-2051',
    'ART-3100', 'ART-3101', 'ART-4200', 'ART-4201');
  DESCS: array[0..7] of string = (
    'Pieza A grande', 'Pieza A peque'#241'a', 'Pieza B chasis', 'Pieza B soporte',
    'Caja electr'#243'nica', 'Caja sensores', 'Conjunto C ensamblado', 'Conjunto C revisi'#243'n');
  CLIS: array[0..4] of string = ('CLI-001', 'CLI-002', 'CLI-003', 'CLI-004', 'CLI-005');
const
  FILAS_POR_INSERT = 900;   // SQL Server admite hasta 1000 filas por INSERT VALUES
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  CE, PID: string;
  Centros, Operarios: TArray<Integer>;
  I, K, NumOF, ArtIdx, CliIdx, Prio, CenterId, DurInt: Integer;
  NumOpsNec, UnidTotal, UnidHechas, NumOpsAsig, NumAsig: Integer;
  BaseId, NodeId, PrevNodeId: Integer;
  Inicio, Fin, FEnt, FNec, Horizonte: TDateTime;
  DurMin, DurOrig, HorasOp: Double;
  Op: string;
  Inv: TFormatSettings;
  Cursor: TDictionary<Integer, TDateTime>;   // CenterId -> proximo hueco libre
  CalCache: TDictionary<Integer, TCentreCalendar>;
  Cal: TCentreCalendar;
  // Acumuladores de filas (VALUES) para INSERT multifila por tabla.
  SbNode, SbData, SbAsig, SbDep: TStringBuilder;
  NNode, NData, NAsig, NDep: Integer;
  // --- Instrumentacion de tiempos ---
  SW, SW2: TStopwatch;
  MsInserts: Int64;

  function DT(const V: TDateTime): string;
  begin
    Result := QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', V));
  end;

  // Ejecuta un INSERT multifila (INSERT ... VALUES (f1),(f2),...) y limpia el
  // acumulador. APrefix es "INSERT INTO tabla (cols) VALUES ". El acumulador
  // contiene las filas ya con coma inicial: ",(...)". El primer caracter (la
  // coma) se salta.
  procedure EjecutarMultifila(const APrefix: string; ASb: TStringBuilder;
    AWrapIdentity: Boolean);
  var
    Sql: string;
    T: TStopwatch;
  begin
    if ASb.Length = 0 then Exit;
    Sql := APrefix + ASb.ToString.Substring(1);   // quitar la coma inicial
    if AWrapIdentity then
      Sql := 'SET IDENTITY_INSERT FS_PL_Node ON; ' + Sql +
             '; SET IDENTITY_INSERT FS_PL_Node OFF;';
    T := TStopwatch.StartNew;
    Cmd.CommandText := Sql;
    Cmd.Execute;
    MsInserts := MsInserts + T.ElapsedMilliseconds;
    ASb.Clear;
  end;

  // Descarga TODO lo pendiente. ORDEN OBLIGATORIO por las FK: Node primero (las
  // demas tablas referencian NodeId), luego NodeData/Asignacion/Dependencia.
  procedure FlushTodo;
  begin
    EjecutarMultifila('INSERT INTO FS_PL_Node (CodigoEmpresa, NodeId, ProjectId, ' +
      'CenterId, FechaInicio, FechaFin, DuracionMin, Caption, ColorFondo, ' +
      'ColorBorde, Source) VALUES ', SbNode, True);
    NNode := 0;
    EjecutarMultifila('INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, ' +
      'NumeroOF, DuracionMin, DuracionMinOriginal, UnidadesAFabricar, ' +
      'UnidadesFabricadas, OperariosNecesarios, OperariosAsignados, ColorFondoOp, ' +
      'ColorBordeOp, Prioridad, FechaEntrega, FechaNecesaria, CodigoArticulo, ' +
      'DescripcionArticulo, CodigoCliente) VALUES ', SbData, False);
    NData := 0;
    EjecutarMultifila('INSERT INTO FS_PL_OperatorAssignment (CodigoEmpresa, ' +
      'OperatorId, NodeId, Horas) VALUES ', SbAsig, False);
    NAsig := 0;
    EjecutarMultifila('INSERT INTO FS_PL_Dependency (CodigoEmpresa, ProjectId, ' +
      'FromNodeId, ToNodeId, TipoLink, PorcentajeDependencia) VALUES ', SbDep, False);
    NDep := 0;
  end;

  // Calendario del centro (cacheado). nil = sin calendario -> tiempo natural.
  function CalendarioDe(ACenter: Integer): TCentreCalendar;
  begin
    if ACenter <= 0 then Exit(nil);
    if not CalCache.TryGetValue(ACenter, Result) then
    begin
      Result := nil;
      if FCentresRepo <> nil then
        Result := FCentresRepo.GetCalendarFor(ACenter);
      CalCache.AddOrSetValue(ACenter, Result);
    end;
  end;

begin
  Result := 0;
  if (not IsConnected) or (AProjectId <= 0) or (ACantidad <= 0) then Exit;
  Randomize;
  Inv := TFormatSettings.Invariant;
  CE := IntToStr(FCodigoEmpresa);
  PID := IntToStr(AProjectId);

  // Instrumentacion de tiempos.
  NumAsig := 0; MsInserts := 0;
  SW := TStopwatch.StartNew;
  PlanLog.Inicio(Format('GenerarNodosDemo: %d nodos, proyecto %d', [ACantidad, AProjectId]));

  // Centros reales visibles/habilitados: los nodos demo se reparten entre ellos.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT CenterId FROM FS_PL_Center WHERE CodigoEmpresa = ' + CE +
      ' AND ISNULL(Visible,1) = 1 AND ISNULL(Habilitado,1) = 1 ORDER BY CenterId';
    Q.Open;
    SetLength(Centros, 0);
    while not Q.Eof do
    begin
      SetLength(Centros, Length(Centros) + 1);
      Centros[High(Centros)] := Q.FieldByName('CenterId').AsInteger;
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  PlanLog.Linea('t+%d ms: leidos %d centros', [SW.ElapsedMilliseconds, Length(Centros)]);
  if Length(Centros) = 0 then Exit;   // sin centros no hay donde colocar nodos

  // Operarios activos: para asignar algunos nodos (realismo). Tolerante a que
  // la tabla no exista (instalacion sin V019).
  SetLength(Operarios, 0);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT OperatorId FROM FS_PL_Operator WHERE CodigoEmpresa = ' + CE +
      ' AND ISNULL(Activo,1) = 1 ORDER BY OperatorId';
    try
      Q.Open;
      while not Q.Eof do
      begin
        SetLength(Operarios, Length(Operarios) + 1);
        Operarios[High(Operarios)] := Q.FieldByName('OperatorId').AsInteger;
        Q.Next;
      end;
    except
      on E: Exception do
        PlanLog.Linea('  AVISO: fallo al leer operarios: %s', [E.Message]);
    end;
  finally
    Q.Free;
  end;

  // Si la empresa no tiene operarios, crear unos cuantos demo para que el Gantt
  // demo pueda mostrar asignaciones. Se insertan como operarios normales de la
  // empresa (no molestan: son datos de la empresa, no del proyecto).
  if Length(Operarios) = 0 then
  begin
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := ADOConnection;
      for I := 0 to 7 do
        try
          Cmd.CommandText :=
            'IF NOT EXISTS (SELECT 1 FROM FS_PL_Operator WHERE CodigoEmpresa = ' + CE +
            ' AND Nombre = ' + QuotedStr('Operario Demo ' + IntToStr(I + 1)) + ') ' +
            'INSERT INTO FS_PL_Operator (CodigoEmpresa, Nombre, Activo) VALUES (' +
            CE + ', ' + QuotedStr('Operario Demo ' + IntToStr(I + 1)) + ', 1)';
          Cmd.Execute;
        except
          // Si FS_PL_Operator no existe, no se pueden crear: seguimos sin ellos.
          Break;
        end;
    finally
      Cmd.Free;
    end;
    // Releer los ids recien creados.
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := ADOConnection;
      Q.SQL.Text := 'SELECT OperatorId FROM FS_PL_Operator WHERE CodigoEmpresa = ' + CE +
        ' AND ISNULL(Activo,1) = 1 ORDER BY OperatorId';
      try
        Q.Open;
        while not Q.Eof do
        begin
          SetLength(Operarios, Length(Operarios) + 1);
          Operarios[High(Operarios)] := Q.FieldByName('OperatorId').AsInteger;
          Q.Next;
        end;
      except
      end;
    finally
      Q.Free;
    end;
  end;

  PlanLog.Linea('t+%d ms: preparados %d operarios', [SW.ElapsedMilliseconds, Length(Operarios)]);

  Cursor := TDictionary<Integer, TDateTime>.Create;
  CalCache := TDictionary<Integer, TCentreCalendar>.Create;
  SbNode := TStringBuilder.Create;
  SbData := TStringBuilder.Create;
  SbAsig := TStringBuilder.Create;
  SbDep := TStringBuilder.Create;
  NNode := 0; NData := 0; NAsig := 0; NDep := 0;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := ADOConnection;
    ADOConnection.BeginTrans;
    try
      // 1. Regenerar: limpiar los nodos previos de ESTE proyecto (solo demo).
      Cmd.CommandText := 'DELETE FROM FS_PL_OperatorAssignment WHERE CodigoEmpresa = ' + CE +
        ' AND NodeId IN (SELECT NodeId FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
        ' AND ProjectId = ' + PID + ')';
      Cmd.Execute;
      Cmd.CommandText := 'DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa = ' + CE +
        ' AND ProjectId = ' + PID;
      Cmd.Execute;
      Cmd.CommandText := 'DELETE FROM FS_PL_NodeData WHERE CodigoEmpresa = ' + CE +
        ' AND NodeId IN (SELECT NodeId FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
        ' AND ProjectId = ' + PID + ')';
      Cmd.Execute;
      Cmd.CommandText := 'DELETE FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
        ' AND ProjectId = ' + PID;
      Cmd.Execute;

      // Reservar el rango de NodeIds: como los asignamos NOSOTROS (IDENTITY_INSERT),
      // podemos usar INSERT multifila masivo sin necesitar SCOPE_IDENTITY por nodo.
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := ADOConnection;
        Q.SQL.Text := 'SELECT ISNULL(MAX(NodeId), 0) AS M FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE;
        Q.Open;
        BaseId := Q.FieldByName('M').AsInteger + 1;
      finally
        Q.Free;
      end;
      PlanLog.Linea('t+%d ms: DELETE previo hecho, BaseId=%d (empieza generacion)',
        [SW.ElapsedMilliseconds, BaseId]);

      // 2. Generar ACantidad nodos. Cada ~4 nodos forman una "OF" encadenada
      //    (dependencias FS entre operaciones consecutivas de la misma OF).
      //    Cada nodo se coloca EN HORARIO LABORABLE de su centro (calendario) y
      //    SIN SOLAPARSE: por centro se lleva un "cursor" que avanza tras cada
      //    nodo, de modo que el siguiente empieza donde acabo el anterior.
      //    Los NodeId se asignan explicitos (BaseId + I) y las filas se acumulan
      //    en 4 INSERT multifila (Node/NodeData/Asignacion/Dependencia).
      Horizonte := Trunc(Date) + 45;
      NumOF := 1000;
      PrevNodeId := 0;
      for I := 0 to ACantidad - 1 do
      begin
        NodeId := BaseId + I;

        // Nueva OF cada 4 operaciones: rompe la cadena de dependencias.
        if (I mod 4) = 0 then
        begin
          Inc(NumOF);
          PrevNodeId := 0;
        end;

        // Centro real (round-robin para repartir de forma pareja).
        CenterId := Centros[I mod Length(Centros)];

        // Duracion teorica (original) y duracion real segun estado de
        // optimizacion (3.4). Se calcula ANTES de las fechas para que la barra
        // del Gantt (FechaFin-FechaInicio) refleje la duracion REAL.
        //   - OPTIMIZADO   (~35%): real < original (ahorro 10-30%).
        //   - SIN OPTIMIZAR(~35%): real = original.
        //   - NO OPTIMIZADO(~30%): real > original (sobrecoste 15-40%).
        DurOrig := 30 + Random(271);         // 30..300 min teoricos
        K := Random(100);
        if K < 35 then
          DurMin := DurOrig * (0.70 + Random(21) / 100.0)
        else if K < 70 then
          DurMin := DurOrig
        else
          DurMin := DurOrig * (1.15 + Random(26) / 100.0);
        DurInt := Round(DurMin);

        Cal := CalendarioDe(CenterId);

        // Punto de partida = cursor del centro (o inicio del horizonte).
        if not Cursor.TryGetValue(CenterId, Inicio) then
          Inicio := Trunc(Date) + 6 / 24;    // arranque nominal 06:00 del dia 1

        if Cal <> nil then
        begin
          // Saltar a horario laborable y calcular fin respetando el calendario
          // (los huecos no laborables no cuentan como duracion).
          Inicio := Cal.NextWorkingTime(Inicio);
          Fin := Cal.AddWorkingMinutes(Inicio, DurInt);
        end
        else
        begin
          // Sin calendario: tiempo natural, saltando noches (jornada 06-22).
          if Frac(Inicio) > 22 / 24 then Inicio := Trunc(Inicio) + 1 + 6 / 24;
          if Frac(Inicio) < 6 / 24 then Inicio := Trunc(Inicio) + 6 / 24;
          Fin := Inicio + DurMin / (24 * 60);
        end;

        // Avanzar el cursor del centro (mas un pequeno respiro entre nodos).
        Cursor.AddOrSetValue(CenterId, Fin + 5 / (24 * 60));

        // Si nos salimos del horizonte, reciclar al principio (para no estirar
        // indefinidamente cuando se piden muchos nodos con pocos centros).
        if Inicio > Horizonte then
        begin
          Inicio := Trunc(Date) + 6 / 24;
          if Cal <> nil then Inicio := Cal.NextWorkingTime(Inicio);
          if Cal <> nil then Fin := Cal.AddWorkingMinutes(Inicio, DurInt)
          else Fin := Inicio + DurMin / (24 * 60);
          Cursor.AddOrSetValue(CenterId, Fin + 5 / (24 * 60));
        end;

        Op := OPS[I mod Length(OPS)];
        ArtIdx := Random(Length(ARTS));
        CliIdx := Random(Length(CLIS));
        Prio := 1 + Random(5);

        // 3.2 Fecha de entrega repartida en 3 grupos para ver los 3 estados:
        //   ~25% VENCIDA (antes de hoy), ~25% A PUNTO (hoy..hoy+3), ~50% FUTURA.
        K := Random(4);
        if K = 0 then
          FEnt := Trunc(Date) - (1 + Random(8))       // vencida: 1..8 dias atras
        else if K = 1 then
          FEnt := Trunc(Date) + Random(4)             // a punto: hoy..hoy+3
        else
          FEnt := Trunc(Fin) + 3 + Random(20);        // futura: unos dias tras el fin
        FNec := FEnt - 2 - Random(5);

        // 3.3 Avance: unidades a fabricar y ya fabricadas (0%, parcial, 100%).
        UnidTotal := 100 + Random(900);
        K := Random(10);
        if K < 4 then      UnidHechas := 0                              // 40% sin empezar
        else if K < 9 then UnidHechas := Random(UnidTotal)             // 50% parcial
        else               UnidHechas := UnidTotal;                     // 10% completo
        NumOpsNec := 1 + Random(3);

        // --- Acumular las filas (VALUES) de este nodo en cada acumulador ---
        // Node (NodeId explicito).
        SbNode.Append(',(' + CE + ', ' + IntToStr(NodeId) + ', ' + PID + ', ' +
          IntToStr(CenterId) + ', ' + DT(Inicio) + ', ' + DT(Fin) + ', ' +
          FloatToStr(DurMin, Inv) + ', ' + QuotedStr(Op) + ', 15251072, 11166760, ' +
          QuotedStr('ERP') + ')');
        Inc(NNode);

        // 3.1 Decidir CUANTOS operarios se asignan a este nodo ANTES del NodeData,
        //   para poder rellenar OperariosAsignados (la vista gvmOperarios pinta
        //   verde/amarillo/rojo comparando Asignados vs Necesarios). ~70% de los
        //   nodos reciben 1-2 operarios; ~30% ninguno.
        NumOpsAsig := 0;
        if (Length(Operarios) > 0) and (Random(10) < 7) then
        begin
          NumOpsAsig := 1;
          if (Length(Operarios) > 1) and (Random(2) = 0) then NumOpsAsig := 2;
        end;

        SbData.Append(',(' + CE + ', ' + IntToStr(NodeId) + ', ' + QuotedStr(Op) + ', ' +
          IntToStr(NumOF) + ', ' + FloatToStr(DurMin, Inv) + ', ' + FloatToStr(DurOrig, Inv) +
          ', ' + IntToStr(UnidTotal) + ', ' + IntToStr(UnidHechas) + ', ' +
          IntToStr(NumOpsNec) + ', ' + IntToStr(NumOpsAsig) + ', 15251072, 11166760, ' +
          IntToStr(Prio) + ', ' + DT(FEnt) + ', ' + DT(FNec) + ', ' + QuotedStr(ARTS[ArtIdx]) +
          ', ' + QuotedStr(DESCS[ArtIdx]) + ', ' + QuotedStr(CLIS[CliIdx]) + ')');
        Inc(NData);

        // Insertar las asignaciones reales en FS_PL_OperatorAssignment.
        if NumOpsAsig > 0 then
        begin
          HorasOp := (DurMin / 60.0) / NumOpsAsig;
          for K := 0 to NumOpsAsig - 1 do
          begin
            SbAsig.Append(',(' + CE + ', ' +
              IntToStr(Operarios[(I + K) mod Length(Operarios)]) + ', ' +
              IntToStr(NodeId) + ', ' + FloatToStr(HorasOp, Inv) + ')');
            Inc(NAsig); Inc(NumAsig);
          end;
        end;

        // Dependencia FS con la operacion anterior de la misma OF.
        if PrevNodeId > 0 then
        begin
          SbDep.Append(',(' + CE + ', ' + PID + ', ' + IntToStr(PrevNodeId) + ', ' +
            IntToStr(NodeId) + ', 0, 100)');
          Inc(NDep);
        end;
        PrevNodeId := NodeId;

        // Descargar los 4 acumuladores (en orden FK) cuando cualquiera se acerca
        // al limite de 900 filas/INSERT. NAsig es el que mas crece (hasta 2/nodo).
        if (NNode >= FILAS_POR_INSERT) or (NAsig >= FILAS_POR_INSERT) then
          FlushTodo;
        Inc(Result);
      end;
      FlushTodo;   // volcar todo lo pendiente
      PlanLog.Linea('t+%d ms: generados %d nodos (suma INSERTs %d ms). ' +
        'Asignaciones de operario: %d',
        [SW.ElapsedMilliseconds, Result, MsInserts, NumAsig]);

      SW2 := TStopwatch.StartNew;
      ADOConnection.CommitTrans;
      PlanLog.Linea('t+%d ms: COMMIT hecho en %d ms',
        [SW.ElapsedMilliseconds, SW2.ElapsedMilliseconds]);
    except
      ADOConnection.RollbackTrans;
      Result := 0;
      raise;
    end;
  finally
    Cmd.Free;
    Cursor.Free;
    SbNode.Free; SbData.Free; SbAsig.Free; SbDep.Free;
    // OJO: los TCentreCalendar del cache son propiedad de CentresRepo
    // (GetCalendarFor devuelve referencias compartidas). Solo liberar el
    // diccionario, NUNCA los calendarios.
    CalCache.Free;
  end;
  PlanLog.Linea('TOTAL: %d ms para %d nodos', [SW.ElapsedMilliseconds, Result]);
  PlanLog.Fin;
end;

end.
