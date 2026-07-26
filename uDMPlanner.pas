unit uDMPlanner;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.DateUtils,
  System.StrUtils, System.Generics.Collections,
  Data.DB, Data.Win.ADODB,
  uDataConnector, uSQLServerConnector, uDBMigrations, uUserPreferencesRepo,
  uCalendarsRepo, uCentresRepo, uNodesRepo, uNodeDataRepo, uAlertRulesRepo,
  uSnapshotRepo, uSetupRules;

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
    // Conector del hilo de guardado, con conexion propia (ver ConnectorParaHilo).
    // El candado de su creacion perezosa es el propio DataModule (TMonitor
    // funciona sobre cualquier TObject), asi no hace falta crear ni liberar
    // nada: este DataModule no tiene constructor propio donde hacerlo.
    FConnectorHilo: IGanttDataConnector;
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

    // Perfil de reglas de tiempo de cambio (setup secuencia-dependiente) activo
    // del proyecto/empresa. Lee FS_PL_SetupRule si existe; si la tabla aun no
    // esta (BD sin la migracion) o no hay reglas, devuelve un perfil vacio y el
    // planificador se comporta como antes. Ver uSetupRules.
    function GetActiveSetupProfile: TSetupProfile;
    // Persiste el conjunto completo de reglas de setup de la empresa (borra las
    // existentes e inserta las nuevas, en una transaccion). Editor: tab
    // "Tiempo de cambio" de TfrmPlanningRulesEditor.
    procedure SaveSetupRules(const ARules: TArray<TSetupRule>);

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
    // La generacion de nodos demo vive ahora en uGenerarNodosDemo (form rico +
    // planificacion con el motor real). Ver TfrmGenerarNodosDemo.Execute /
    // ExecuteSilent.

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

    // Conector para el GUARDADO EN SEGUNDO PLANO. Tiene su PROPIA
    // TADOConnection: NO se puede usar el de arriba desde un hilo secundario.
    //
    // Una TADOConnection es un objeto COM en apartamento monohilo: si el hilo
    // de guardado la ocupa (mas aun dentro de una transaccion) y el hilo
    // principal lanza cualquier consulta sobre ella, la llamada se serializa
    // contra un apartamento bloqueado y la aplicacion se CUELGA entera, sin
    // excepcion ni timeout. Era la causa de los cuelgues al mover nodos en el
    // Gantt.
    //
    // Se crea perezosamente en la primera llamada y se libera en Disconnect.
    // Devuelve nil si todavia no hay conexion configurada.
    function ConnectorParaHilo: IGanttDataConnector;
    property CurrentProjectId: Integer read FCurrentProjectId write FCurrentProjectId;
    property CurrentProjectName: string read FCurrentProjectName;
    property EnModoDemo: Boolean read FEnModoDemo;
    property CurrentProjectIsMaster: Boolean read FCurrentProjectIsMaster;
    property CurrentProjectFechaBloqueo: TDateTime read FCurrentProjectFechaBloqueo;
    property CurrentProjectTieneBloqueo: Boolean read FCurrentProjectTieneBloqueo;
    // El setter permite conmutar el RowMode en caliente desde el propio Gantt
    // (selector de "Modo filas"), sin pasar por Gestion de Proyectos. Solo
    // cambia el estado en memoria; la persistencia (por usuario) la decide la
    // pantalla que lo usa.
    property CurrentProjectRowMode: string read FCurrentProjectRowMode
      write FCurrentProjectRowMode;
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

function TDMPlanner.GetActiveSetupProfile: TSetupProfile;
var
  Q: TADOQuery;
  L: TList<TSetupRule>;
  R: TSetupRule;
begin
  Result.Name := 'Activo';
  SetLength(Result.Rules, 0);
  if (ADOConnection = nil) or not ADOConnection.Connected then Exit;

  L := TList<TSetupRule>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    // Tolerante: si la tabla no existe (BD sin la migracion) o falla, se
    // devuelve el perfil vacio y el planificador usa la distancia fija.
    try
      Q.SQL.Text :=
        'SELECT AttrName, SetupMin, CentreCode, Enabled ' +
        'FROM FS_PL_SetupRule ' +
        'WHERE Enabled = 1 AND CodigoEmpresa = :Emp ' +
        'ORDER BY Id';
      Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        R.AttrName := Q.FieldByName('AttrName').AsString;
        R.SetupMin := Q.FieldByName('SetupMin').AsInteger;
        R.CentreCode := Q.FieldByName('CentreCode').AsString;
        // El WHERE ya filtra Enabled=1; evitamos AsBoolean sobre BIT (fragil
        // segun driver ADO, mismo motivo que FieldBoolVar en uBacklog).
        R.Enabled := True;
        L.Add(R);
        Q.Next;
      end;
      Result.Rules := L.ToArray;
    except
      // Tabla ausente o error: perfil vacio (comportamiento clasico).
      SetLength(Result.Rules, 0);
    end;
  finally
    Q.Free;
    L.Free;
  end;
end;

procedure TDMPlanner.SaveSetupRules(const ARules: TArray<TSetupRule>);
var
  Cmd: TADOCommand;
  I: Integer;
  InTran: Boolean;
begin
  if (ADOConnection = nil) or not ADOConnection.Connected then Exit;

  InTran := False;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := ADOConnection;
    ADOConnection.BeginTrans;
    InTran := True;

    // Reemplazo completo: borrar las de la empresa e insertar el nuevo conjunto.
    Cmd.CommandText :=
      'DELETE FROM dbo.FS_PL_SetupRule WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa);
    Cmd.Execute;

    for I := 0 to High(ARules) do
    begin
      if Trim(ARules[I].AttrName) = '' then Continue;  // regla vacia: ignorar
      Cmd.CommandText :=
        'INSERT INTO dbo.FS_PL_SetupRule ' +
        '(CodigoEmpresa, AttrName, SetupMin, CentreCode, Enabled) VALUES (' +
        IntToStr(FCodigoEmpresa) + ', ' +
        QuotedStr(ARules[I].AttrName) + ', ' +
        IntToStr(ARules[I].SetupMin) + ', ' +
        QuotedStr(ARules[I].CentreCode) + ', ' +
        IfThen(ARules[I].Enabled, '1', '0') + ')';
      Cmd.Execute;
    end;

    ADOConnection.CommitTrans;
    InTran := False;
  finally
    if InTran then
      try ADOConnection.RollbackTrans; except end;
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

function TDMPlanner.ConnectorParaHilo: IGanttDataConnector;
var
  Conn: TSQLServerConnector;
begin
  Result := nil;
  if not ADOConnection.Connected then Exit;

  // Creacion perezosa protegida: el primer guardado en segundo plano puede
  // coincidir con otro, y no queremos abrir dos conexiones ni devolver una a
  // medio construir.
  TMonitor.Enter(Self);
  try
    if FConnectorHilo = nil then
    begin
      try
        Conn := TSQLServerConnector.CreateParaHilo(ConnectionStringForThreads,
          ADOConnection.CommandTimeout);
        Conn.CodigoEmpresa := FCodigoEmpresa;
        FConnectorHilo := Conn;
      except
        on E: Exception do
        begin
          // Sin conexion propia NO se devuelve la compartida como apano: eso es
          // justo lo que colgaba la aplicacion. Mejor que el guardado falle y
          // se reintente (los nodos siguen marcados como sucios).
          PlanLog.Linea('AUTOSAVE: no se pudo abrir conexion propia: %s',
            [E.Message]);
          FConnectorHilo := nil;
        end;
      end;
    end;
    Result := FConnectorHilo;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TDMPlanner.Disconnect;
begin
  FConnector := nil;
  FConnectorObj := nil;

  // Soltar el conector del hilo de guardado. OJO con lo que esto NO hace:
  // es una INTERFAZ con recuento de referencias, asi que si en este momento
  // hay un guardado en marcha, el hilo conserva su propia referencia y el
  // objeto (y su conexion) siguen vivos hasta que ese hilo termine. Es
  // deliberado: cortarle la conexion a media transaccion seria peor.
  //
  // La consecuencia es que el conector puede acabar destruyendose EN EL HILO
  // de guardado. No pasa nada porque su conexion se creo con COM en modo
  // multithreaded (ver uPlanAutoSaver), que no ata el objeto a un apartamento
  // concreto.
  //
  // Aun asi, lo ordenado antes de desconectar es dejar que el auto-save acabe
  // (TPlanAutoSaver.Flush), como ya hace el cierre de la aplicacion.
  TMonitor.Enter(Self);
  try
    FConnectorHilo := nil;
  finally
    TMonitor.Exit(Self);
  end;
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

  var TL := Now;
  LoadCalendars;
  PlanLog.Linea('    DM.LoadCalendars: %d ms', [MilliSecondsBetween(Now, TL)]); TL := Now;
  LoadCentres;
  PlanLog.Linea('    DM.LoadCentres: %d ms', [MilliSecondsBetween(Now, TL)]);
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

end.
