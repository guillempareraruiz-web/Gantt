unit uSnapshotRepo;
// Repositorio de PUNTOS DE RESTAURACION del plan (FS_PL_Snapshot, V062).
//
// Un snapshot es una foto JSON del plan de un proyecto (ver uPlanSnapshot):
//   - AUTO   : se crea al PRIMER cambio del dia (estado ANTES de tocarlo). Como
//              mucho uno por (empresa, proyecto, dia). Se purga por retencion.
//   - MANUAL : lo crea el usuario con una etiqueta. NUNCA se purga.
//
// Restaurar = reemplazar el plan del proyecto por el del snapshot (borrar +
// insertar), creando antes un snapshot 'pre-restauracion' para poder deshacer.
//
// El repo se apoya en el connector (LoadPlanning/SaveNodes) para leer/escribir
// el plan, y en ADO directo para la tabla de snapshots.
interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  System.Generics.Collections, Data.Win.ADODB,
  uGanttTypes, uDataConnector, uPlanSnapshot;

type
  TSnapshotInfo = record
    SnapshotId: Integer;
    Tipo: string;          // 'AUTO' | 'MANUAL'
    Nombre: string;
    Descripcion: string;
    FechaCreacion: TDateTime;
    FechaDia: TDate;
    NodeCount: Integer;
    SizeBytes: Integer;
    CreadoPor: string;
    CreadoPorUserId: Integer;
  end;

  TSnapshotRepo = class
  private
    FConnection: TADOConnection;
    FConnector: IGanttDataConnector;
    FCodigoEmpresa: SmallInt;
    FUserId: Integer;
    FUserLogin: string;
    // Retencion AUTO (la decide el codigo): dias recientes a conservar TODOS.
    FRetencionDias: Integer;
    // Memoria de sesion de "el AUTO de hoy ya esta hecho", para no consultar la
    // BD en cada movimiento de nodo (ver CrearAutoDiarioSiHaceFalta). Es una
    // cache de UN solo proyecto: en la practica se trabaja sobre uno cada vez, y
    // al cambiar de proyecto la clave deja de coincidir y se comprueba de nuevo.
    FAutoHechoProjectId: Integer;
    FAutoHechoDia: TDate;
    // Obliga a volver a preguntar a la BD. La llama todo lo que pueda hacer
    // desaparecer el AUTO de hoy (borrar, purgar, restaurar): si la memoria se
    // queda diciendo "ya esta hecho" cuando ya no existe, ese dia el plan se
    // queda SIN punto de restauracion y no hay forma de notarlo.
    procedure InvalidarCacheAuto;
    function SqlS(const S: string): string;
    function ExisteAutoHoy(AProjectId: Integer): Boolean;
    procedure InsertSnapshot(AProjectId: Integer; const ATipo, ANombre,
      ADescripcion, AJson: string; ANodeCount: Integer; AFechaDia: TDate);
    // Reinserta el plan del snapshot (nodos+datos+dependencias+asignaciones) en
    // la transaccion abierta por Restaurar, usando el Cmd dado.
    procedure InsertarNodos(ACmd: TADOCommand; AProjectId: Integer;
      const AData: TPlanningData);
  public
    constructor Create(AConnection: TADOConnection;
      const AConnector: IGanttDataConnector);

    procedure SetContext(ACodigoEmpresa: SmallInt; AUserId: Integer;
      const AUserLogin: string);

    // Crea el snapshot AUTO del dia para AProjectId SI aun no existe (estado
    // actual del plan en BD = el "antes" de los cambios de hoy). Idempotente:
    // si ya hay AUTO de hoy, no hace nada. Devuelve True si lo creo.
    function CrearAutoDiarioSiHaceFalta(AProjectId: Integer): Boolean;

    // Crea un snapshot MANUAL etiquetado del estado actual del plan.
    function CrearManual(AProjectId: Integer;
      const ANombre, ADescripcion: string): Boolean;

    // Lista los snapshots de un proyecto (mas reciente primero).
    function GetList(AProjectId: Integer): TArray<TSnapshotInfo>;

    // Restaura el plan del proyecto al estado del snapshot. Antes crea un
    // snapshot MANUAL 'pre-restauracion'. Devuelve mensaje de error ('' = ok).
    function Restaurar(ASnapshotId, AProjectId: Integer): string;

    // Borra un snapshot por id (para limpieza manual desde el form).
    procedure Borrar(ASnapshotId: Integer);

    // Aplica la politica de retencion de los AUTO del proyecto: conserva los de
    // los ultimos FRetencionDias dias + el primero (mas antiguo) de cada semana
    // anterior; borra el resto. Los MANUAL no se tocan.
    procedure PurgarAuto(AProjectId: Integer);

    property RetencionDias: Integer read FRetencionDias write FRetencionDias;
  end;

implementation

constructor TSnapshotRepo.Create(AConnection: TADOConnection;
  const AConnector: IGanttDataConnector);
begin
  inherited Create;
  FConnection := AConnection;
  FConnector := AConnector;
  FRetencionDias := 14;   // conservar todos los AUTO de los ultimos 14 dias
end;

procedure TSnapshotRepo.SetContext(ACodigoEmpresa: SmallInt; AUserId: Integer;
  const AUserLogin: string);
begin
  FCodigoEmpresa := ACodigoEmpresa;
  FUserId := AUserId;
  FUserLogin := AUserLogin;
end;

function TSnapshotRepo.SqlS(const S: string): string;
begin
  Result := '''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TSnapshotRepo.ExisteAutoHoy(AProjectId: Integer): Boolean;
var
  Q: TADOQuery;
begin
  Result := False;
  if FConnection = nil then Exit;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM FS_PL_Snapshot ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID AND Tipo = ''AUTO'' ' +
      '  AND FechaDia = CAST(GETDATE() AS DATE)';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Open;
    Result := Q.FieldByName('N').AsInteger > 0;
  finally
    Q.Free;
  end;
end;

procedure TSnapshotRepo.InsertSnapshot(AProjectId: Integer;
  const ATipo, ANombre, ADescripcion, AJson: string; ANodeCount: Integer;
  AFechaDia: TDate);
var
  Cmd: TADOCommand;
  fechaDiaSql: string;
begin
  if FConnection = nil then Exit;
  if AFechaDia = 0 then fechaDiaSql := 'NULL'
  else fechaDiaSql := '''' + FormatDateTime('yyyy-mm-dd', AFechaDia) + '''';

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.ParamCheck := False;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_Snapshot (CodigoEmpresa, ProjectId, Nombre, ' +
      '  Descripcion, FechaCreacion, CreadoPor, DatosJSON, Tipo, FechaDia, ' +
      '  NodeCount, SizeBytes, CreadoPorUserId) VALUES (' +
      IntToStr(FCodigoEmpresa) + ', ' + IntToStr(AProjectId) + ', ' +
      SqlS(ANombre) + ', ' + SqlS(ADescripcion) + ', GETDATE(), ' +
      SqlS(FUserLogin) + ', ' + SqlS(AJson) + ', ' + SqlS(ATipo) + ', ' +
      fechaDiaSql + ', ' + IntToStr(ANodeCount) + ', ' +
      IntToStr(Length(AJson)) + ', ' + IntToStr(FUserId) + ')';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TSnapshotRepo.InvalidarCacheAuto;
begin
  FAutoHechoProjectId := 0;
  FAutoHechoDia := 0;
end;

function TSnapshotRepo.CrearAutoDiarioSiHaceFalta(AProjectId: Integer): Boolean;
var
  Data: TPlanningData;
  R: TConnectorResult;
  Json: string;
begin
  Result := False;
  if (FConnection = nil) or (FConnector = nil) or (AProjectId <= 0) then Exit;

  // Atajo EN MEMORIA: este metodo se llama en CADA modificacion del plan (cada
  // nodo que se mueve), y sin esto cada movimiento pagaba un viaje a BD solo
  // para responder "si, el de hoy ya esta hecho". Con el plan cargado y el
  // usuario arrastrando nodos, eso son decenas de consultas sincronas en el
  // hilo de la interfaz.
  //
  // Se recuerda por (proyecto, dia): si cambia el dia con la aplicacion abierta
  // la clave deja de coincidir y se vuelve a comprobar de verdad.
  if (FAutoHechoProjectId = AProjectId) and
     (FAutoHechoDia = DateOf(Now)) then Exit;

  // La unicidad la garantiza ademas el indice UX_FS_PL_Snapshot_AutoDia; esta
  // comprobacion evita el coste de serializar si ya existe.
  if ExisteAutoHoy(AProjectId) then
  begin
    FAutoHechoProjectId := AProjectId;
    FAutoHechoDia := DateOf(Now);
    Exit;
  end;

  R := FConnector.LoadPlanning(AProjectId, Data);
  if not R.Success then Exit;

  Json := SerializePlan(Data);
  try
    InsertSnapshot(AProjectId, 'AUTO',
      'Inicio del dia ' + FormatDateTime('dd/mm/yyyy', Now),
      'Punto automatico (estado al inicio del dia, antes de los cambios).',
      Json, Length(Data.Nodes), DateOf(Now));
    Result := True;
  except
    // Si dos procesos compiten, el indice unico puede rechazar el segundo: lo
    // tratamos como "ya existe" (no es error funcional).
    on E: Exception do
      Result := ExisteAutoHoy(AProjectId);
  end;

  if Result then
  begin
    // Anotar que el de hoy ya esta: a partir de aqui los siguientes
    // movimientos de nodo no vuelven a consultar la BD.
    FAutoHechoProjectId := AProjectId;
    FAutoHechoDia := DateOf(Now);
    PurgarAuto(AProjectId);
  end;
end;

function TSnapshotRepo.CrearManual(AProjectId: Integer;
  const ANombre, ADescripcion: string): Boolean;
var
  Data: TPlanningData;
  R: TConnectorResult;
  Json: string;
begin
  Result := False;
  if (FConnection = nil) or (FConnector = nil) or (AProjectId <= 0) then Exit;
  R := FConnector.LoadPlanning(AProjectId, Data);
  if not R.Success then Exit;
  Json := SerializePlan(Data);
  InsertSnapshot(AProjectId, 'MANUAL', ANombre, ADescripcion, Json,
    Length(Data.Nodes), 0);   // MANUAL no usa FechaDia (no compite por unicidad)
  Result := True;
end;

function TSnapshotRepo.GetList(AProjectId: Integer): TArray<TSnapshotInfo>;
var
  Q: TADOQuery;
  L: TList<TSnapshotInfo>;
  Info: TSnapshotInfo;
begin
  Result := nil;
  if FConnection = nil then Exit;
  L := TList<TSnapshotInfo>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT SnapshotId, Tipo, Nombre, Descripcion, FechaCreacion, FechaDia, ' +
      '  NodeCount, SizeBytes, CreadoPor, CreadoPorUserId ' +
      'FROM FS_PL_Snapshot WHERE CodigoEmpresa = :CE AND ProjectId = :PID ' +
      'ORDER BY FechaCreacion DESC';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Open;
    while not Q.Eof do
    begin
      Info := Default(TSnapshotInfo);
      Info.SnapshotId := Q.FieldByName('SnapshotId').AsInteger;
      Info.Tipo := Q.FieldByName('Tipo').AsString;
      Info.Nombre := Q.FieldByName('Nombre').AsString;
      if not Q.FieldByName('Descripcion').IsNull then
        Info.Descripcion := Q.FieldByName('Descripcion').AsString;
      Info.FechaCreacion := Q.FieldByName('FechaCreacion').AsDateTime;
      if not Q.FieldByName('FechaDia').IsNull then
        Info.FechaDia := Q.FieldByName('FechaDia').AsDateTime;
      Info.NodeCount := Q.FieldByName('NodeCount').AsInteger;
      Info.SizeBytes := Q.FieldByName('SizeBytes').AsInteger;
      if not Q.FieldByName('CreadoPor').IsNull then
        Info.CreadoPor := Q.FieldByName('CreadoPor').AsString;
      if not Q.FieldByName('CreadoPorUserId').IsNull then
        Info.CreadoPorUserId := Q.FieldByName('CreadoPorUserId').AsInteger;
      L.Add(Info);
      Q.Next;
    end;
    Result := L.ToArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

procedure TSnapshotRepo.InsertarNodos(ACmd: TADOCommand; AProjectId: Integer;
  const AData: TPlanningData);
var
  CE, PID: string;
  i: Integer;
  N: TNode;
  D: TNodeData;

  function FNum(const V: Double): string;
  begin
    Result := StringReplace(FloatToStr(V), ',', '.', [rfReplaceAll]);
  end;

  function FDate(const V: TDateTime): string;
  begin
    if V = 0 then Result := 'NULL'
    else Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', V) + '''';
  end;

  // LoteId: en BD, NULL = nodo libre (0 NO existe en FS_PL_Lote -> rompe la FK).
  // Ademas, el snapshot no guarda los lotes, asi que un LoteId>0 puede apuntar a
  // un lote ya borrado; devolvemos NULL salvo que el lote exista todavia.
  function FLote(const ALoteId: Integer): string;
  begin
    if ALoteId <= 0 then
      Result := 'NULL'
    else
      // Subconsulta: usa el LoteId solo si sigue existiendo; si no, NULL.
      Result := '(SELECT LoteId FROM FS_PL_Lote WHERE CodigoEmpresa = ' + CE +
        ' AND LoteId = ' + IntToStr(ALoteId) + ')';
  end;

begin
  CE := IntToStr(FCodigoEmpresa);
  PID := IntToStr(AProjectId);

  // Nodos: IDENTITY_INSERT para conservar los NodeId originales (las
  // dependencias y asignaciones referencian esos ids).
  ACmd.CommandText := 'SET IDENTITY_INSERT FS_PL_Node ON'; ACmd.Execute;
  try
    for i := 0 to High(AData.Nodes) do
    begin
      N := AData.Nodes[i];
      ACmd.CommandText :=
        'INSERT INTO FS_PL_Node (CodigoEmpresa, NodeId, ProjectId, CenterId, ' +
        '  FechaInicio, FechaFin, DuracionMin, Caption, ColorFondo, ColorBorde, ' +
        '  Visible, Habilitado, LoteId) VALUES (' +
        CE + ', ' + IntToStr(N.Id) + ', ' + PID + ', ' + IntToStr(N.CentreId) +
        ', ' + FDate(N.StartTime) + ', ' + FDate(N.EndTime) + ', ' +
        FNum(N.DurationMin) + ', ' + SqlS(N.Caption) + ', ' +
        IntToStr(Integer(N.FillColor)) + ', ' + IntToStr(Integer(N.BorderColor)) +
        ', ' + IntToStr(Ord(N.Visible)) + ', ' + IntToStr(Ord(N.Enabled)) + ', ' +
        FLote(N.LoteId) + ')';
      ACmd.Execute;
    end;
  finally
    ACmd.CommandText := 'SET IDENTITY_INSERT FS_PL_Node OFF'; ACmd.Execute;
  end;

  // NodeData (mismo NodeId/DataId).
  for i := 0 to High(AData.NodeDataList) do
  begin
    D := AData.NodeDataList[i];
    ACmd.CommandText :=
      'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, ' +
      '  NumeroPedido, SeriePedido, NumeroOF, SerieOF, NumeroTrabajo, ' +
      '  FechaEntrega, FechaNecesaria, CodigoCliente, CodigoArticulo, ' +
      '  DescripcionArticulo, CodigoColor, CodigoTalla, Stock, ' +
      '  UnidadesFabricadas, UnidadesAFabricar, TiempoUnidadFabSecs, ' +
      '  DuracionMin, DuracionMinOriginal, OperariosNecesarios, ' +
      '  OperariosAsignados, Estado, Tipo, Prioridad, ColorFondoOp, ' +
      '  ColorBordeOp, LibreMovimiento) VALUES (' +
      CE + ', ' + IntToStr(D.DataId) + ', ' + SqlS(D.Operacion) + ', ' +
      IntToStr(D.NumeroPedido) + ', ' + SqlS(D.SeriePedido) + ', ' +
      IntToStr(D.NumeroOrdenFabricacion) + ', ' + SqlS(D.SerieFabricacion) +
      ', ' + SqlS(D.NumeroTrabajo) + ', ' + FDate(D.FechaEntrega) + ', ' +
      FDate(D.FechaNecesaria) + ', ' + SqlS(D.CodigoCliente) + ', ' +
      SqlS(D.CodigoArticulo) + ', ' + SqlS(D.DescripcionArticulo) + ', ' +
      SqlS(D.CodigoColor) + ', ' + SqlS(D.CodigoTalla) + ', ' + FNum(D.Stock) +
      ', ' + FNum(D.UnidadesFabricadas) + ', ' + FNum(D.UnidadesAFabricar) +
      ', ' + FNum(D.TiempoUnidadFabSecs) + ', ' + FNum(D.DurationMin) + ', ' +
      FNum(D.DurationMinOriginal) + ', ' + IntToStr(D.OperariosNecesarios) +
      ', ' + IntToStr(D.OperariosAsignados) + ', ' + IntToStr(Ord(D.Estado)) +
      ', ' + IntToStr(Ord(D.Tipo)) + ', ' + IntToStr(D.Prioridad) + ', ' +
      IntToStr(Integer(D.bkColorOp)) + ', ' + IntToStr(Integer(D.borderColorOp)) +
      ', ' + IntToStr(Ord(D.LibreMoviment)) + ')';
    ACmd.Execute;
  end;

  // Dependencias.
  for i := 0 to High(AData.Links) do
  begin
    ACmd.CommandText :=
      'INSERT INTO FS_PL_Dependency (CodigoEmpresa, ProjectId, FromNodeId, ' +
      '  ToNodeId, TipoLink, PorcentajeDependencia) VALUES (' +
      CE + ', ' + PID + ', ' + IntToStr(AData.Links[i].FromNodeId) + ', ' +
      IntToStr(AData.Links[i].ToNodeId) + ', ' +
      IntToStr(Ord(AData.Links[i].LinkType)) + ', ' +
      FNum(AData.Links[i].PorcentajeDependencia) + ')';
    ACmd.Execute;
  end;

  // Asignaciones de operarios.
  for i := 0 to High(AData.Asignaciones) do
  begin
    ACmd.CommandText :=
      'INSERT INTO FS_PL_OperatorAssignment (CodigoEmpresa, OperatorId, ' +
      '  NodeId, Horas) VALUES (' + CE + ', ' +
      IntToStr(AData.Asignaciones[i].OperarioId) + ', ' +
      IntToStr(AData.Asignaciones[i].DataId) + ', ' +
      FNum(AData.Asignaciones[i].Horas) + ')';
    ACmd.Execute;
  end;
end;

function TSnapshotRepo.Restaurar(ASnapshotId, AProjectId: Integer): string;
var
  Q: TADOQuery;
  Json: string;
  Data: TPlanningData;
  Cmd: TADOCommand;
  CE, PID: string;
begin
  Result := '';
  if (FConnection = nil) or (FConnector = nil) then
    Exit('Sin conexion.');

  // 1. Leer el JSON del snapshot.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT DatosJSON FROM FS_PL_Snapshot ' +
      'WHERE CodigoEmpresa = :CE AND SnapshotId = :SID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('SID').Value := ASnapshotId;
    Q.Open;
    if Q.Eof then Exit('El punto de restauracion no existe.');
    Json := Q.FieldByName('DatosJSON').AsString;
  finally
    Q.Free;
  end;

  try
    Data := DeserializePlan(Json);
  except
    on E: Exception do Exit('Snapshot ilegible: ' + E.Message);
  end;

  // 2. Snapshot 'pre-restauracion' del estado ACTUAL (para poder deshacer).
  try
    CrearManual(AProjectId,
      'Pre-restauracion ' + FormatDateTime('dd/mm/yyyy hh:nn', Now),
      'Estado del plan justo antes de restaurar el punto #' +
      IntToStr(ASnapshotId) + '.');
  except
    // Si falla el pre-snapshot, abortamos: no restauramos sin red de seguridad.
    on E: Exception do
      Exit('No se pudo crear el punto de seguridad previo: ' + E.Message);
  end;

  CE := IntToStr(FCodigoEmpresa);
  PID := IntToStr(AProjectId);

  // 3. Borrar el plan actual del proyecto e insertar el del snapshot en UNA
  //    transaccion propia (no usamos el connector aqui para no anidar
  //    transacciones): o se restaura todo o no se toca nada.
  FConnection.BeginTrans;
  try
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := FConnection;
      Cmd.ParamCheck := False;

      // --- Borrado del plan actual (hijos antes que padres) ---
      Cmd.CommandText := 'DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa = ' +
        CE + ' AND ProjectId = ' + PID; Cmd.Execute;
      Cmd.CommandText := 'DELETE FROM FS_PL_OperatorAssignment WHERE ' +
        'CodigoEmpresa = ' + CE + ' AND NodeId IN (SELECT NodeId FROM ' +
        'FS_PL_Node WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID +
        ')'; Cmd.Execute;
      Cmd.CommandText := 'DELETE FROM FS_PL_NodeData WHERE CodigoEmpresa = ' +
        CE + ' AND NodeId IN (SELECT NodeId FROM FS_PL_Node WHERE ' +
        'CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID + ')'; Cmd.Execute;
      Cmd.CommandText := 'DELETE FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
        ' AND ProjectId = ' + PID; Cmd.Execute;

      // --- Reinsertar nodos (con IDENTITY_INSERT para conservar NodeId) ---
      InsertarNodos(Cmd, AProjectId, Data);
    finally
      Cmd.Free;
    end;

    FConnection.CommitTrans;
    // El plan es OTRO: lo que sabiamos del AUTO de hoy ya no describe este
    // estado, asi que se vuelve a comprobar contra la BD.
    InvalidarCacheAuto;
  except
    on E: Exception do
    begin
      // Blindado: si RollbackTrans lanza (conexion caida, transaccion ya
      // abortada), esa excepcion taparia el error real Y dejaria la
      // transaccion abierta, bloqueando FS_PL_Node para todos.
      try
        if FConnection.InTransaction then FConnection.RollbackTrans;
      except
        // Nada que deshacer: el error que importa es el de fuera.
      end;
      Exit('Error al restaurar (no se ha modificado el plan): ' + E.Message);
    end;
  end;
end;

procedure TSnapshotRepo.Borrar(ASnapshotId: Integer);
var
  Cmd: TADOCommand;
begin
  if FConnection = nil then Exit;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.ParamCheck := False;
    Cmd.CommandText := 'DELETE FROM FS_PL_Snapshot WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa) + ' AND SnapshotId = ' + IntToStr(ASnapshotId);
    Cmd.Execute;
    InvalidarCacheAuto;   // puede haberse borrado justo el AUTO de hoy
  finally
    Cmd.Free;
  end;
end;

procedure TSnapshotRepo.PurgarAuto(AProjectId: Integer);
var
  Cmd: TADOCommand;
begin
  if FConnection = nil then Exit;
  // Retencion AUTO: conservar los de los ultimos FRetencionDias dias y, de los
  // mas antiguos, solo el PRIMERO (mas antiguo) de cada semana ISO; borrar el
  // resto. Los MANUAL nunca se tocan. Se hace en SQL con una CTE.
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.ParamCheck := False;
    Cmd.CommandText :=
      'WITH auto AS (' +
      '  SELECT SnapshotId, FechaDia, ' +
      '    ROW_NUMBER() OVER (PARTITION BY DATEPART(YEAR, FechaDia), ' +
      '      DATEPART(ISO_WEEK, FechaDia) ORDER BY FechaDia ASC) AS rnSemana ' +
      '  FROM FS_PL_Snapshot ' +
      '  WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      '    AND ProjectId = ' + IntToStr(AProjectId) +
      '    AND Tipo = ''AUTO'' AND FechaDia IS NOT NULL ' +
      '    AND FechaDia < DATEADD(DAY, -' + IntToStr(FRetencionDias) +
      ', CAST(GETDATE() AS DATE)) ' +
      ') ' +
      'DELETE FROM FS_PL_Snapshot WHERE SnapshotId IN (' +
      '  SELECT SnapshotId FROM auto WHERE rnSemana > 1) ' +
      '  AND CodigoEmpresa = ' + IntToStr(FCodigoEmpresa);
    Cmd.Execute;
    // La purga solo borra AUTOs mas viejos que la retencion, asi que hoy no
    // deberia caer. Se invalida igualmente por si algun dia se baja la
    // retencion a 0: es barato y evita quedarse sin punto del dia en silencio.
    InvalidarCacheAuto;
  finally
    Cmd.Free;
  end;
end;

end.
