unit uSQLServerConnector;

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.DateUtils, System.Math, System.StrUtils,
  System.Generics.Collections, Data.DB, Data.Win.ADODB,
  uDataConnector, uGanttTypes, uErpTypes, uOperariosTypes, uMoldeTypes,
  uCentreCalendar, uPlanningRules;

type
  TSQLServerConnectorConfig = record
    Server: string;
    Database: string;
    UserName: string;
    Password: string;
    UseWindowsAuth: Boolean;
    ConnectionTimeout: Integer;
    CommandTimeout: Integer;
    function BuildConnectionString: string;
  end;

  TSQLServerConnector = class(TInterfacedObject, IGanttDataConnector)
  private
    FConfig: TSQLServerConnectorConfig;
    FConnection: TADOConnection;
    FOwnsConnection: Boolean;
    FOnProgress: TConnectorProgressEvent;

    procedure DoProgress(const APaso: string; APorcentaje: Integer);
    function ExecSQL(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;

    // --- Helpers de carga ---
    function LoadCentres: TArray<TCentreTreball>;
    function LoadNodes(AProjectId: Integer): TArray<TNode>;
    function LoadNodeDataList(AProjectId: Integer): TArray<TNodeData>;
    function LoadNodeCentresAllowed(AProjectId: Integer): TDictionary<Integer, TArray<Integer>>;
    function LoadNodeCustomFields(AProjectId: Integer): TDictionary<Integer, TArray<TCustomFieldValue>>;
    function LoadLinks(AProjectId: Integer): TArray<TErpLink>;
    function LoadMarkers(AProjectId: Integer): TArray<TGanttMarker>;
    function LoadShifts: TArray<TTurno>;
    function LoadOperarios: TArray<TOperario>;
    function LoadDepartamentos: TArray<TDepartamento>;
    function LoadOperarioDepts: TArray<TOperarioDepartamento>;
    function LoadCapacitaciones: TArray<TCapacitacion>;
    function LoadAsignaciones(AProjectId: Integer): TArray<TAsignacionOperario>;
    function LoadMoldes: TArray<TMolde>;
    function LoadCustomFieldDefs: TArray<TCustomFieldDef>;
    function LoadPlanningProfiles(out AActiveIndex: Integer): TArray<TPlanningProfile>;

    // --- Helpers de guardado ---
    procedure InternalSaveCentres(const ACentres: TArray<TCentreTreball>);
    procedure InternalSaveNodes(AProjectId: Integer; const ANodes: TArray<TNode>;
      const ANodeData: TArray<TNodeData>);
    procedure InternalSaveLinks(AProjectId: Integer; const ALinks: TArray<TErpLink>);
    procedure InternalSaveMarkers(AProjectId: Integer; const AMarkers: TArray<TGanttMarker>);
    procedure InternalSaveShifts(const AShifts: TArray<TTurno>);
    procedure InternalSaveOperarios(const AOperarios: TArray<TOperario>;
      const ADepts: TArray<TDepartamento>;
      const ARels: TArray<TOperarioDepartamento>;
      const ACaps: TArray<TCapacitacion>;
      const AAsig: TArray<TAsignacionOperario>);
    procedure InternalSaveMoldes(const AMoldes: TArray<TMolde>);
    procedure InternalSaveCustomFieldDefs(const ADefs: TArray<TCustomFieldDef>);
    procedure InternalSavePlanningProfiles(const AProfiles: TArray<TPlanningProfile>;
      AActiveIndex: Integer);

    function QuotedStr(const S: string): string;
    function DateTimeToSQL(const DT: TDateTime): string;
    function TimeToSQL(const T: TDateTime): string;
    function ColorToSQL(C: Integer): string;
    function SQLToColor(const V: Variant): Integer;
    function SQLToDateTime(const V: Variant): TDateTime;
    function SQLToStr(const V: Variant): string;
    function SQLToInt(const V: Variant; ADefault: Integer = 0): Integer;
    function SQLToFloat(const V: Variant; ADefault: Double = 0): Double;
    function SQLToBool(const V: Variant; ADefault: Boolean = False): Boolean;

  public
    constructor Create(const AConfig: TSQLServerConnectorConfig); overload;
    constructor Create(AConnection: TADOConnection); overload;
    destructor Destroy; override;

    // --- IGanttDataConnector ---
    function Connect: TConnectorResult;
    procedure Disconnect;
    function IsConnected: Boolean;

    function GetProjects: TArray<TProjectInfo>;
    function CreateProject(var AProject: TProjectInfo): TConnectorResult;
    function DeleteProject(AProjectId: Integer): TConnectorResult;

    function LoadPlanning(AProjectId: Integer; out AData: TPlanningData): TConnectorResult;
    function SavePlanning(const AData: TPlanningData): TConnectorResult;

    function SaveNodes(AProjectId: Integer; const ANodes: TArray<TNode>;
      const ANodeData: TArray<TNodeData>): TConnectorResult;
    function SaveCentres(const ACentres: TArray<TCentreTreball>): TConnectorResult;
    function SaveLinks(AProjectId: Integer; const ALinks: TArray<TErpLink>): TConnectorResult;
    function SaveMarkers(AProjectId: Integer; const AMarkers: TArray<TGanttMarker>): TConnectorResult;
    function SaveOperarios(const AOperarios: TArray<TOperario>;
      const ADepts: TArray<TDepartamento>;
      const ARelaciones: TArray<TOperarioDepartamento>;
      const ACapacitaciones: TArray<TCapacitacion>;
      const AAsignaciones: TArray<TAsignacionOperario>): TConnectorResult;
    function SaveShifts(const AShifts: TArray<TTurno>): TConnectorResult;
    function SaveMoldes(const AMoldes: TArray<TMolde>): TConnectorResult;
    function SaveCustomFieldDefs(const ADefs: TArray<TCustomFieldDef>): TConnectorResult;
    function SavePlanningProfiles(const AProfiles: TArray<TPlanningProfile>;
      AActiveIndex: Integer): TConnectorResult;

    function CreateSnapshot(AProjectId: Integer; const ANombre: string;
      const ADescripcion: string): TConnectorResult;
    function GetSnapshots(AProjectId: Integer): TArray<TProjectInfo>;
    function LoadSnapshot(ASnapshotId: Integer; out AData: TPlanningData): TConnectorResult;

    function SetErpMapping(const ATipoEntidad: string; AEntidadId: Integer;
      const AErpSistema, AErpClave: string): TConnectorResult;
    function GetErpMapping(const ATipoEntidad: string; AEntidadId: Integer;
      const AErpSistema: string): string;

    function GetOnProgress: TConnectorProgressEvent;
    procedure SetOnProgress(AValue: TConnectorProgressEvent);

    property Config: TSQLServerConnectorConfig read FConfig write FConfig;
  end;

implementation

uses
  System.JSON;

{ TSQLServerConnectorConfig }

function TSQLServerConnectorConfig.BuildConnectionString: string;
begin
  Result := 'Provider=SQLOLEDB.1;Data Source=' + Server +
            ';Initial Catalog=' + Database;
  if UseWindowsAuth then
    Result := Result + ';Integrated Security=SSPI'
  else
    Result := Result + ';User ID=' + UserName + ';Password=' + Password;
  if ConnectionTimeout > 0 then
    Result := Result + ';Connect Timeout=' + IntToStr(ConnectionTimeout);
end;

{ TSQLServerConnector }

constructor TSQLServerConnector.Create(const AConfig: TSQLServerConnectorConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FConnection := TADOConnection.Create(nil);
  FConnection.LoginPrompt := False;
  FOwnsConnection := True;
  if FConfig.CommandTimeout > 0 then
    FConnection.CommandTimeout := FConfig.CommandTimeout
  else
    FConnection.CommandTimeout := 60;
end;

constructor TSQLServerConnector.Create(AConnection: TADOConnection);
begin
  inherited Create;
  FConnection := AConnection;
  FOwnsConnection := False;
end;

destructor TSQLServerConnector.Destroy;
begin
  if FOwnsConnection then
  begin
    Disconnect;
    FConnection.Free;
  end;
  inherited;
end;

procedure TSQLServerConnector.DoProgress(const APaso: string; APorcentaje: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self, APaso, APorcentaje);
end;

function TSQLServerConnector.GetOnProgress: TConnectorProgressEvent;
begin
  Result := FOnProgress;
end;

procedure TSQLServerConnector.SetOnProgress(AValue: TConnectorProgressEvent);
begin
  FOnProgress := AValue;
end;

// ════════════════════════════════════════════════════════════════════
//  HELPERS SQL
// ════════════════════════════════════════════════════════════════════

function TSQLServerConnector.QuotedStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TSQLServerConnector.DateTimeToSQL(const DT: TDateTime): string;
begin
  if DT = 0 then
    Result := 'NULL'
  else
    Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', DT) + '''';
end;

function TSQLServerConnector.TimeToSQL(const T: TDateTime): string;
begin
  Result := '''' + FormatDateTime('hh:nn:ss', T) + '''';
end;

function TSQLServerConnector.ColorToSQL(C: Integer): string;
begin
  if C = 0 then
    Result := 'NULL'
  else
    Result := IntToStr(C);
end;

function TSQLServerConnector.SQLToColor(const V: Variant): Integer;
begin
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := 0
  else
    Result := V;
end;

function TSQLServerConnector.SQLToDateTime(const V: Variant): TDateTime;
begin
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := 0
  else
    Result := VarToDateTime(V);
end;

function TSQLServerConnector.SQLToStr(const V: Variant): string;
begin
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := ''
  else
    Result := VarToStr(V);
end;

function TSQLServerConnector.SQLToInt(const V: Variant; ADefault: Integer): Integer;
begin
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := ADefault
  else
    Result := V;
end;

function TSQLServerConnector.SQLToFloat(const V: Variant; ADefault: Double): Double;
begin
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := ADefault
  else
    Result := V;
end;

function TSQLServerConnector.SQLToBool(const V: Variant; ADefault: Boolean): Boolean;
begin
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := ADefault
  else
    Result := V;
end;

function TSQLServerConnector.ExecSQL(const ASQL: string): Integer;
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText := ASQL;
    Cmd.CommandType := cmdText;
    Cmd.Execute(Result, EmptyParam);
  finally
    Cmd.Free;
  end;
end;

function TSQLServerConnector.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := FConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

// ════════════════════════════════════════════════════════════════════
//  CONEXIÓN
// ════════════════════════════════════════════════════════════════════

function TSQLServerConnector.Connect: TConnectorResult;
begin
  try
    FConnection.ConnectionString := FConfig.BuildConnectionString;
    FConnection.Connected := True;
    Result := TConnectorResult.OK;
  except
    on E: Exception do
      Result := TConnectorResult.Fail('Error de conexión: ' + E.Message);
  end;
end;

procedure TSQLServerConnector.Disconnect;
begin
  if FConnection.Connected then
    FConnection.Connected := False;
end;

function TSQLServerConnector.IsConnected: Boolean;
begin
  Result := FConnection.Connected;
end;

// ════════════════════════════════════════════════════════════════════
//  PROYECTOS
// ════════════════════════════════════════════════════════════════════

function TSQLServerConnector.GetProjects: TArray<TProjectInfo>;
var
  Q: TADOQuery;
  I: Integer;
begin
  Q := OpenQuery('SELECT ProjectId, Codigo, Nombre, Descripcion, ' +
    'FechaCreacion, FechaModificacion, Activo FROM FS_PL_Project WHERE Activo = 1 ORDER BY Nombre');
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      Result[I].ProjectId := Q.FieldByName('ProjectId').AsInteger;
      Result[I].Codigo := Q.FieldByName('Codigo').AsString;
      Result[I].Nombre := Q.FieldByName('Nombre').AsString;
      Result[I].Descripcion := Q.FieldByName('Descripcion').AsString;
      Result[I].FechaCreacion := Q.FieldByName('FechaCreacion').AsDateTime;
      Result[I].FechaModificacion := Q.FieldByName('FechaModificacion').AsDateTime;
      Result[I].Activo := Q.FieldByName('Activo').AsBoolean;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.CreateProject(var AProject: TProjectInfo): TConnectorResult;
var
  Q: TADOQuery;
begin
  try
    ExecSQL('INSERT INTO FS_PL_Project (Codigo, Nombre, Descripcion) VALUES (' +
      QuotedStr(AProject.Codigo) + ',' +
      QuotedStr(AProject.Nombre) + ',' +
      QuotedStr(AProject.Descripcion) + ')');
    Q := OpenQuery('SELECT SCOPE_IDENTITY() AS NewId');
    try
      AProject.ProjectId := Q.FieldByName('NewId').AsInteger;
    finally
      Q.Free;
    end;
    AProject.FechaCreacion := Now;
    AProject.FechaModificacion := Now;
    AProject.Activo := True;
    Result := TConnectorResult.OK(1);
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

function TSQLServerConnector.DeleteProject(AProjectId: Integer): TConnectorResult;
begin
  try
    ExecSQL('UPDATE FS_PL_Project SET Activo = 0, FechaModificacion = GETDATE() ' +
      'WHERE ProjectId = ' + IntToStr(AProjectId));
    Result := TConnectorResult.OK(1);
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

// ════════════════════════════════════════════════════════════════════
//  CARGA COMPLETA
// ════════════════════════════════════════════════════════════════════

function TSQLServerConnector.LoadPlanning(AProjectId: Integer;
  out AData: TPlanningData): TConnectorResult;
var
  Q: TADOQuery;
  CentresAllowed: TDictionary<Integer, TArray<Integer>>;
  CustomFieldVals: TDictionary<Integer, TArray<TCustomFieldValue>>;
  Allowed: TArray<Integer>;
  CFVals: TArray<TCustomFieldValue>;
  I: Integer;
begin
  try
    DoProgress('Cargando proyecto...', 0);

    // Proyecto
    Q := OpenQuery('SELECT * FROM FS_PL_Project WHERE ProjectId = ' + IntToStr(AProjectId));
    try
      if Q.Eof then
        Exit(TConnectorResult.Fail('Proyecto no encontrado'));
      AData.Project.ProjectId := Q.FieldByName('ProjectId').AsInteger;
      AData.Project.Codigo := Q.FieldByName('Codigo').AsString;
      AData.Project.Nombre := Q.FieldByName('Nombre').AsString;
      AData.Project.Descripcion := SQLToStr(Q.FieldByName('Descripcion').Value);
      AData.Project.FechaCreacion := Q.FieldByName('FechaCreacion').AsDateTime;
      AData.Project.FechaModificacion := Q.FieldByName('FechaModificacion').AsDateTime;
      AData.Project.Activo := Q.FieldByName('Activo').AsBoolean;
    finally
      Q.Free;
    end;

    DoProgress('Cargando centros...', 10);
    AData.Centres := LoadCentres;

    DoProgress('Cargando nodos...', 20);
    AData.Nodes := LoadNodes(AProjectId);

    DoProgress('Cargando datos de nodos...', 30);
    AData.NodeDataList := LoadNodeDataList(AProjectId);

    // Mezclar centros permitidos y custom fields en NodeData
    CentresAllowed := LoadNodeCentresAllowed(AProjectId);
    CustomFieldVals := LoadNodeCustomFields(AProjectId);
    try
      for I := 0 to High(AData.NodeDataList) do
      begin
        if CentresAllowed.TryGetValue(AData.NodeDataList[I].DataId, Allowed) then
          AData.NodeDataList[I].CentresPermesos := Allowed;
        if CustomFieldVals.TryGetValue(AData.NodeDataList[I].DataId, CFVals) then
          AData.NodeDataList[I].CustomFields := CFVals;
      end;
    finally
      CentresAllowed.Free;
      CustomFieldVals.Free;
    end;

    DoProgress('Cargando dependencias...', 50);
    AData.Links := LoadLinks(AProjectId);

    DoProgress('Cargando marcadores...', 55);
    AData.Markers := LoadMarkers(AProjectId);

    DoProgress('Cargando turnos...', 60);
    AData.Shifts := LoadShifts;

    DoProgress('Cargando operarios...', 65);
    AData.Operarios := LoadOperarios;
    AData.Departamentos := LoadDepartamentos;
    AData.OperarioDepts := LoadOperarioDepts;
    AData.Capacitaciones := LoadCapacitaciones;
    AData.Asignaciones := LoadAsignaciones(AProjectId);

    DoProgress('Cargando moldes...', 75);
    AData.Moldes := LoadMoldes;

    DoProgress('Cargando campos personalizados...', 80);
    AData.CustomFieldDefs := LoadCustomFieldDefs;

    DoProgress('Cargando perfiles de planificación...', 90);
    AData.PlanningProfiles := LoadPlanningProfiles(AData.ActiveProfileIndex);

    DoProgress('Carga completada', 100);
    Result := TConnectorResult.OK;
  except
    on E: Exception do
      Result := TConnectorResult.Fail('Error cargando planning: ' + E.Message);
  end;
end;

// ════════════════════════════════════════════════════════════════════
//  FUNCIONES DE CARGA INDIVIDUAL
// ════════════════════════════════════════════════════════════════════

function TSQLServerConnector.LoadCentres: TArray<TCentreTreball>;
var
  Q: TADOQuery;
  I: Integer;
  C: TCentreTreball;
begin
  Q := OpenQuery('SELECT c.*, a.Codigo AS AreaCodigo FROM FS_PL_Center c ' +
    'LEFT JOIN FS_PL_Area a ON a.AreaId = c.AreaId ORDER BY c.Orden');
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FillChar(C, SizeOf(C), 0);
      C.Id := Q.FieldByName('CenterId').AsInteger;
      C.CodiCentre := Q.FieldByName('CodigoCentro').AsString;
      C.Titulo := Q.FieldByName('Titulo').AsString;
      C.Subtitulo := SQLToStr(Q.FieldByName('Subtitulo').Value);
      C.IsSequencial := SQLToBool(Q.FieldByName('EsSecuencial').Value);
      C.MaxLaneCount := SQLToInt(Q.FieldByName('MaxLanes').Value);
      C.BaseHeight := SQLToFloat(Q.FieldByName('AlturaBase').Value, 40);
      C.Order := SQLToInt(Q.FieldByName('Orden').Value);
      C.Visible := SQLToBool(Q.FieldByName('Visible').Value, True);
      C.Enabled := SQLToBool(Q.FieldByName('Habilitado').Value, True);
      C.BkColor := SQLToColor(Q.FieldByName('ColorFondo').Value);
      C.Area := SQLToStr(Q.FieldByName('AreaCodigo').Value);
      Result[I] := C;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadNodes(AProjectId: Integer): TArray<TNode>;
var
  Q: TADOQuery;
  I: Integer;
  N: TNode;
begin
  Q := OpenQuery('SELECT * FROM FS_PL_Node WHERE ProjectId = ' + IntToStr(AProjectId));
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FillChar(N, SizeOf(N), 0);
      N.Id := Q.FieldByName('NodeId').AsInteger;
      N.CentreId := SQLToInt(Q.FieldByName('CenterId').Value, -1);
      N.StartTime := SQLToDateTime(Q.FieldByName('FechaInicio').Value);
      N.EndTime := SQLToDateTime(Q.FieldByName('FechaFin').Value);
      N.DurationMin := SQLToFloat(Q.FieldByName('DuracionMin').Value);
      N.Caption := SQLToStr(Q.FieldByName('Caption').Value);
      N.FillColor := SQLToColor(Q.FieldByName('ColorFondo').Value);
      N.BorderColor := SQLToColor(Q.FieldByName('ColorBorde').Value);
      N.Visible := SQLToBool(Q.FieldByName('Visible').Value, True);
      N.Enabled := SQLToBool(Q.FieldByName('Habilitado').Value, True);
      N.DataId := N.Id; // DataId = NodeId
      Result[I] := N;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadNodeDataList(AProjectId: Integer): TArray<TNodeData>;
var
  Q: TADOQuery;
  I: Integer;
  D: TNodeData;
begin
  Q := OpenQuery(
    'SELECT nd.* FROM FS_PL_NodeData nd ' +
    'INNER JOIN FS_PL_Node n ON n.NodeId = nd.NodeId ' +
    'WHERE n.ProjectId = ' + IntToStr(AProjectId));
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FillChar(D, SizeOf(D), 0);
      D.DataId := Q.FieldByName('NodeId').AsInteger;
      D.Operacion := SQLToStr(Q.FieldByName('Operacion').Value);
      D.NumeroPedido := SQLToInt(Q.FieldByName('NumeroPedido').Value);
      D.SeriePedido := SQLToStr(Q.FieldByName('SeriePedido').Value);
      D.NumeroOrdenFabricacion := SQLToInt(Q.FieldByName('NumeroOF').Value);
      D.SerieFabricacion := SQLToStr(Q.FieldByName('SerieOF').Value);
      D.NumeroTrabajo := SQLToStr(Q.FieldByName('NumeroTrabajo').Value);
      D.FechaEntrega := SQLToDateTime(Q.FieldByName('FechaEntrega').Value);
      D.FechaNecesaria := SQLToDateTime(Q.FieldByName('FechaNecesaria').Value);
      D.CodigoCliente := SQLToStr(Q.FieldByName('CodigoCliente').Value);
      D.CodigoColor := SQLToStr(Q.FieldByName('CodigoColor').Value);
      D.CodigoTalla := SQLToStr(Q.FieldByName('CodigoTalla').Value);
      D.Stock := SQLToFloat(Q.FieldByName('Stock').Value);
      D.CodigoArticulo := SQLToStr(Q.FieldByName('CodigoArticulo').Value);
      D.DescripcionArticulo := SQLToStr(Q.FieldByName('DescripcionArticulo').Value);
      D.PorcentajeDependencia := SQLToFloat(Q.FieldByName('PorcentajeDependencia').Value);
      D.UnidadesFabricadas := SQLToFloat(Q.FieldByName('UnidadesFabricadas').Value);
      D.UnidadesAFabricar := SQLToFloat(Q.FieldByName('UnidadesAFabricar').Value);
      D.TiempoUnidadFabSecs := SQLToFloat(Q.FieldByName('TiempoUnidadFabSecs').Value);
      D.DurationMin := SQLToFloat(Q.FieldByName('DuracionMin').Value);
      D.DurationMinOriginal := SQLToFloat(Q.FieldByName('DuracionMinOriginal').Value);
      D.OperariosNecesarios := SQLToInt(Q.FieldByName('OperariosNecesarios').Value);
      D.OperariosAsignados := SQLToInt(Q.FieldByName('OperariosAsignados').Value);
      D.Estado := TNodoEstado(SQLToInt(Q.FieldByName('Estado').Value));
      D.Tipo := TNodoTipo(SQLToInt(Q.FieldByName('Tipo').Value));
      D.Prioridad := SQLToInt(Q.FieldByName('Prioridad').Value);
      D.bkColorOp := SQLToColor(Q.FieldByName('ColorFondoOp').Value);
      D.borderColorOp := SQLToColor(Q.FieldByName('ColorBordeOp').Value);
      D.LibreMoviment := SQLToBool(Q.FieldByName('LibreMovimiento').Value);
      Result[I] := D;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadNodeCentresAllowed(AProjectId: Integer): TDictionary<Integer, TArray<Integer>>;
var
  Q: TADOQuery;
  NodeId: Integer;
  Lst: TList<Integer>;
  Pair: TPair<Integer, TList<Integer>>;
  Temp: TDictionary<Integer, TList<Integer>>;
begin
  Result := TDictionary<Integer, TArray<Integer>>.Create;
  Temp := TDictionary<Integer, TList<Integer>>.Create;
  try
    Q := OpenQuery(
      'SELECT nca.NodeId, nca.CenterId FROM FS_PL_NodeCenterAllowed nca ' +
      'INNER JOIN FS_PL_Node n ON n.NodeId = nca.NodeId ' +
      'WHERE n.ProjectId = ' + IntToStr(AProjectId));
    try
      while not Q.Eof do
      begin
        NodeId := Q.FieldByName('NodeId').AsInteger;
        if not Temp.TryGetValue(NodeId, Lst) then
        begin
          Lst := TList<Integer>.Create;
          Temp.Add(NodeId, Lst);
        end;
        Lst.Add(Q.FieldByName('CenterId').AsInteger);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    for Pair in Temp do
      Result.Add(Pair.Key, Pair.Value.ToArray);
  finally
    for Pair in Temp do
      Pair.Value.Free;
    Temp.Free;
  end;
end;

function TSQLServerConnector.LoadNodeCustomFields(AProjectId: Integer): TDictionary<Integer, TArray<TCustomFieldValue>>;
var
  Q: TADOQuery;
  NodeId: Integer;
  CFV: TCustomFieldValue;
  Lst: TList<TCustomFieldValue>;
  Pair: TPair<Integer, TList<TCustomFieldValue>>;
  Temp: TDictionary<Integer, TList<TCustomFieldValue>>;
begin
  Result := TDictionary<Integer, TArray<TCustomFieldValue>>.Create;
  Temp := TDictionary<Integer, TList<TCustomFieldValue>>.Create;
  try
    Q := OpenQuery(
      'SELECT cfv.NodeId, cfd.FieldName, cfv.Valor FROM FS_PL_CustomFieldValue cfv ' +
      'INNER JOIN FS_PL_CustomFieldDef cfd ON cfd.FieldDefId = cfv.FieldDefId ' +
      'INNER JOIN FS_PL_Node n ON n.NodeId = cfv.NodeId ' +
      'WHERE n.ProjectId = ' + IntToStr(AProjectId));
    try
      while not Q.Eof do
      begin
        NodeId := Q.FieldByName('NodeId').AsInteger;
        CFV.FieldName := Q.FieldByName('FieldName').AsString;
        CFV.Value := Q.FieldByName('Valor').Value;
        if not Temp.TryGetValue(NodeId, Lst) then
        begin
          Lst := TList<TCustomFieldValue>.Create;
          Temp.Add(NodeId, Lst);
        end;
        Lst.Add(CFV);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    for Pair in Temp do
      Result.Add(Pair.Key, Pair.Value.ToArray);
  finally
    for Pair in Temp do
      Pair.Value.Free;
    Temp.Free;
  end;
end;

function TSQLServerConnector.LoadLinks(AProjectId: Integer): TArray<TErpLink>;
var
  Q: TADOQuery;
  I: Integer;
  L: TErpLink;
begin
  Q := OpenQuery('SELECT * FROM FS_PL_Dependency WHERE ProjectId = ' + IntToStr(AProjectId));
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      L.FromNodeId := Q.FieldByName('FromNodeId').AsInteger;
      L.ToNodeId := Q.FieldByName('ToNodeId').AsInteger;
      L.LinkType := TLinkType(SQLToInt(Q.FieldByName('TipoLink').Value));
      L.PorcentajeDependencia := SQLToFloat(Q.FieldByName('PorcentajeDependencia').Value, 100);
      Result[I] := L;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadMarkers(AProjectId: Integer): TArray<TGanttMarker>;
var
  Q: TADOQuery;
  I: Integer;
  M: TGanttMarker;
begin
  Q := OpenQuery('SELECT * FROM FS_PL_Marker WHERE ProjectId = ' + IntToStr(AProjectId));
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FillChar(M, SizeOf(M), 0);
      M.Id := Q.FieldByName('MarkerId').AsInteger;
      M.DateTime := SQLToDateTime(Q.FieldByName('FechaHora').Value);
      M.Caption := SQLToStr(Q.FieldByName('Caption').Value);
      M.Color := SQLToColor(Q.FieldByName('Color').Value);
      M.Style := TMarkerStyle(SQLToInt(Q.FieldByName('Estilo').Value));
      M.StrokeWidth := SQLToFloat(Q.FieldByName('GrosorLinea').Value, 1);
      M.Moveable := SQLToBool(Q.FieldByName('Movible').Value);
      M.Visible := SQLToBool(Q.FieldByName('Visible').Value, True);
      M.Tag := SQLToInt(Q.FieldByName('Tag').Value);
      M.FontName := SQLToStr(Q.FieldByName('FontName').Value);
      M.FontSize := SQLToInt(Q.FieldByName('FontSize').Value, 9);
      M.FontColor := SQLToColor(Q.FieldByName('FontColor').Value);
      M.TextOrientation := TMarkerTextOrientation(SQLToInt(Q.FieldByName('OrientacionTexto').Value));
      M.TextAlign := TMarkerTextAlign(SQLToInt(Q.FieldByName('AlineacionTexto').Value));
      Result[I] := M;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadShifts: TArray<TTurno>;
var
  Q: TADOQuery;
  I: Integer;
  T: TTurno;
begin
  Q := OpenQuery('SELECT * FROM FS_PL_Shift ORDER BY Orden');
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FillChar(T, SizeOf(T), 0);
      T.Id := Q.FieldByName('ShiftId').AsInteger;
      T.Nombre := Q.FieldByName('Nombre').AsString;
      T.HoraInicio := Q.FieldByName('HoraInicio').AsDateTime;
      T.HoraFin := Q.FieldByName('HoraFin').AsDateTime;
      T.Color := SQLToColor(Q.FieldByName('Color').Value);
      T.Activo := SQLToBool(Q.FieldByName('Activo').Value, True);
      T.Order := SQLToInt(Q.FieldByName('Orden').Value);
      Result[I] := T;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadOperarios: TArray<TOperario>;
var
  Q: TADOQuery;
  I: Integer;
  O: TOperario;
begin
  Q := OpenQuery('SELECT * FROM FS_PL_Operator WHERE Activo = 1');
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      O.Id := Q.FieldByName('OperatorId').AsInteger;
      O.Nombre := Q.FieldByName('Nombre').AsString;
      O.Calendario := SQLToStr(Q.FieldByName('CalendarId').Value);
      Result[I] := O;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadDepartamentos: TArray<TDepartamento>;
var
  Q: TADOQuery;
  I: Integer;
  D: TDepartamento;
begin
  Q := OpenQuery('SELECT * FROM FS_PL_Department');
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      D.Id := Q.FieldByName('DepartmentId').AsInteger;
      D.Nombre := Q.FieldByName('Nombre').AsString;
      D.Descripcion := SQLToStr(Q.FieldByName('Descripcion').Value);
      Result[I] := D;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadOperarioDepts: TArray<TOperarioDepartamento>;
var
  Q: TADOQuery;
  I: Integer;
  R: TOperarioDepartamento;
begin
  Q := OpenQuery('SELECT * FROM FS_PL_OperatorDepartment');
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      R.OperarioId := Q.FieldByName('OperatorId').AsInteger;
      R.DepartamentoId := Q.FieldByName('DepartmentId').AsInteger;
      Result[I] := R;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadCapacitaciones: TArray<TCapacitacion>;
var
  Q: TADOQuery;
  I: Integer;
  C: TCapacitacion;
begin
  Q := OpenQuery('SELECT * FROM FS_PL_OperatorSkill');
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      C.OperarioId := Q.FieldByName('OperatorId').AsInteger;
      C.Operacion := Q.FieldByName('Operacion').AsString;
      Result[I] := C;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadAsignaciones(AProjectId: Integer): TArray<TAsignacionOperario>;
var
  Q: TADOQuery;
  I: Integer;
  A: TAsignacionOperario;
begin
  Q := OpenQuery(
    'SELECT oa.* FROM FS_PL_OperatorAssignment oa ' +
    'INNER JOIN FS_PL_Node n ON n.NodeId = oa.NodeId ' +
    'WHERE n.ProjectId = ' + IntToStr(AProjectId));
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      A.OperarioId := Q.FieldByName('OperatorId').AsInteger;
      A.DataId := Q.FieldByName('NodeId').AsInteger;
      A.Horas := SQLToFloat(Q.FieldByName('Horas').Value);
      Result[I] := A;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadMoldes: TArray<TMolde>;
var
  Q: TADOQuery;
  I: Integer;
  M: TMolde;
begin
  Q := OpenQuery('SELECT * FROM FS_PL_Mold');
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FillChar(M, SizeOf(M), 0);
      M.IdMolde := Q.FieldByName('MoldId').AsInteger;
      M.CodigoMolde := Q.FieldByName('Codigo').AsString;
      M.Descripcion := SQLToStr(Q.FieldByName('Descripcion').Value);
      M.TipoMolde := TTipoMolde(SQLToInt(Q.FieldByName('TipoMolde').Value));
      M.Estado := TEstadoMolde(SQLToInt(Q.FieldByName('Estado').Value));
      M.UbicacionActual := SQLToStr(Q.FieldByName('UbicacionActual').Value);
      M.NumeroCavidades := SQLToInt(Q.FieldByName('NumeroCavidades').Value, 1);
      M.TiempoMontaje := SQLToFloat(Q.FieldByName('TiempoMontaje').Value);
      M.TiempoDesmontaje := SQLToFloat(Q.FieldByName('TiempoDesmontaje').Value);
      M.TiempoAjuste := SQLToFloat(Q.FieldByName('TiempoAjuste').Value);
      M.CiclosAcumulados := SQLToInt(Q.FieldByName('CiclosAcumulados').Value);
      M.FechaProximoMantenimiento := SQLToDateTime(Q.FieldByName('FechaProxMantenimiento').Value);
      M.DisponiblePlanificacion := SQLToBool(Q.FieldByName('DisponiblePlanificacion').Value, True);
      M.Observaciones := SQLToStr(Q.FieldByName('Observaciones').Value);
      Result[I] := M;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadCustomFieldDefs: TArray<TCustomFieldDef>;
var
  Q: TADOQuery;
  I: Integer;
  D: TCustomFieldDef;
  ListStr: string;
begin
  Q := OpenQuery('SELECT * FROM FS_PL_CustomFieldDef ORDER BY Orden');
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FillChar(D, SizeOf(D), 0);
      D.FieldName := Q.FieldByName('FieldName').AsString;
      D.Caption := Q.FieldByName('Caption').AsString;
      D.FieldType := TCustomFieldType(SQLToInt(Q.FieldByName('TipoCampo').Value));
      D.DefaultValue := Q.FieldByName('ValorDefecto').Value;
      ListStr := SQLToStr(Q.FieldByName('ValoresLista').Value);
      if ListStr <> '' then
        D.ListValues := ListStr.Split(['|']);
      D.Required := SQLToBool(Q.FieldByName('Requerido').Value);
      D.ReadOnly := SQLToBool(Q.FieldByName('SoloLectura').Value);
      D.Order := SQLToInt(Q.FieldByName('Orden').Value);
      D.Visible := SQLToBool(Q.FieldByName('Visible').Value, True);
      D.Grupo := SQLToStr(Q.FieldByName('Grupo').Value);
      D.Tooltip := SQLToStr(Q.FieldByName('Tooltip').Value);
      D.MinValue := SQLToFloat(Q.FieldByName('ValorMinimo').Value);
      D.MaxValue := SQLToFloat(Q.FieldByName('ValorMaximo').Value);
      D.FormatMask := SQLToStr(Q.FieldByName('FormatoMascara').Value);
      Result[I] := D;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadPlanningProfiles(out AActiveIndex: Integer): TArray<TPlanningProfile>;
var
  QProf, QSort, QFilter, QGroup: TADOQuery;
  I, J: Integer;
  P: TPlanningProfile;
  SR: TSortRule;
  FR: TFilterRule;
  GR: TGroupRule;
  ProfId: Integer;
  SortList: TList<TSortRule>;
  FilterList: TList<TFilterRule>;
  GroupList: TList<TGroupRule>;
begin
  AActiveIndex := -1;
  QProf := OpenQuery('SELECT * FROM FS_PL_PlanningProfile ORDER BY ProfileId');
  try
    SetLength(Result, QProf.RecordCount);
    I := 0;
    while not QProf.Eof do
    begin
      ProfId := QProf.FieldByName('ProfileId').AsInteger;
      P.Name := QProf.FieldByName('Nombre').AsString;
      P.Description := SQLToStr(QProf.FieldByName('Descripcion').Value);
      if SQLToBool(QProf.FieldByName('EsActivo').Value) then
        AActiveIndex := I;

      // Sort rules
      SortList := TList<TSortRule>.Create;
      try
        QSort := OpenQuery('SELECT * FROM FS_PL_SortRule WHERE ProfileId = ' +
          IntToStr(ProfId) + ' ORDER BY Orden');
        try
          while not QSort.Eof do
          begin
            SR.FieldName := QSort.FieldByName('FieldName').AsString;
            SR.Direction := TSortDirection(SQLToInt(QSort.FieldByName('Direccion').Value));
            SR.Weight := SQLToInt(QSort.FieldByName('Peso').Value, 1);
            SR.Enabled := SQLToBool(QSort.FieldByName('Habilitado').Value, True);
            SortList.Add(SR);
            QSort.Next;
          end;
        finally
          QSort.Free;
        end;
        P.SortRules := SortList.ToArray;
      finally
        SortList.Free;
      end;

      // Filter rules
      FilterList := TList<TFilterRule>.Create;
      try
        QFilter := OpenQuery('SELECT * FROM FS_PL_FilterRule WHERE ProfileId = ' +
          IntToStr(ProfId) + ' ORDER BY Orden');
        try
          while not QFilter.Eof do
          begin
            FR.FieldName := QFilter.FieldByName('FieldName').AsString;
            FR.Operator := TFilterOperator(SQLToInt(QFilter.FieldByName('Operador').Value));
            FR.Value := QFilter.FieldByName('Valor').Value;
            FR.Action := TFilterAction(SQLToInt(QFilter.FieldByName('Accion').Value));
            FR.TargetCentreId := SQLToInt(QFilter.FieldByName('CentroDestinoId').Value, -1);
            FR.Enabled := SQLToBool(QFilter.FieldByName('Habilitado').Value, True);
            FilterList.Add(FR);
            QFilter.Next;
          end;
        finally
          QFilter.Free;
        end;
        P.FilterRules := FilterList.ToArray;
      finally
        FilterList.Free;
      end;

      // Group rules
      GroupList := TList<TGroupRule>.Create;
      try
        QGroup := OpenQuery('SELECT * FROM FS_PL_GroupRule WHERE ProfileId = ' +
          IntToStr(ProfId) + ' ORDER BY Orden');
        try
          while not QGroup.Eof do
          begin
            GR.FieldName := QGroup.FieldByName('FieldName').AsString;
            GR.Mode := TGroupMode(SQLToInt(QGroup.FieldByName('Modo').Value));
            GR.Weight := SQLToInt(QGroup.FieldByName('Peso').Value, 1);
            GR.Enabled := SQLToBool(QGroup.FieldByName('Habilitado').Value, True);
            GroupList.Add(GR);
            QGroup.Next;
          end;
        finally
          QGroup.Free;
        end;
        P.GroupRules := GroupList.ToArray;
      finally
        GroupList.Free;
      end;

      Result[I] := P;
      Inc(I);
      QProf.Next;
    end;
    SetLength(Result, I);
  finally
    QProf.Free;
  end;
end;

// ════════════════════════════════════════════════════════════════════
//  GUARDADO COMPLETO
// ════════════════════════════════════════════════════════════════════

function TSQLServerConnector.SavePlanning(const AData: TPlanningData): TConnectorResult;
begin
  try
    FConnection.BeginTrans;
    try
      DoProgress('Guardando centros...', 5);
      InternalSaveCentres(AData.Centres);

      DoProgress('Guardando nodos...', 20);
      InternalSaveNodes(AData.Project.ProjectId, AData.Nodes, AData.NodeDataList);

      DoProgress('Guardando dependencias...', 40);
      InternalSaveLinks(AData.Project.ProjectId, AData.Links);

      DoProgress('Guardando marcadores...', 50);
      InternalSaveMarkers(AData.Project.ProjectId, AData.Markers);

      DoProgress('Guardando turnos...', 55);
      InternalSaveShifts(AData.Shifts);

      DoProgress('Guardando operarios...', 60);
      InternalSaveOperarios(AData.Operarios, AData.Departamentos,
        AData.OperarioDepts, AData.Capacitaciones, AData.Asignaciones);

      DoProgress('Guardando moldes...', 75);
      InternalSaveMoldes(AData.Moldes);

      DoProgress('Guardando campos personalizados...', 80);
      InternalSaveCustomFieldDefs(AData.CustomFieldDefs);

      DoProgress('Guardando perfiles...', 90);
      InternalSavePlanningProfiles(AData.PlanningProfiles, AData.ActiveProfileIndex);

      // Actualizar fecha modificación del proyecto
      ExecSQL('UPDATE FS_PL_Project SET FechaModificacion = GETDATE() WHERE ProjectId = ' +
        IntToStr(AData.Project.ProjectId));

      FConnection.CommitTrans;
      DoProgress('Guardado completado', 100);
      Result := TConnectorResult.OK;
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TConnectorResult.Fail('Error guardando planning: ' + E.Message);
  end;
end;

// ════════════════════════════════════════════════════════════════════
//  GUARDADO INCREMENTAL (público)
// ════════════════════════════════════════════════════════════════════

function TSQLServerConnector.SaveNodes(AProjectId: Integer;
  const ANodes: TArray<TNode>; const ANodeData: TArray<TNodeData>): TConnectorResult;
begin
  try
    FConnection.BeginTrans;
    try
      InternalSaveNodes(AProjectId, ANodes, ANodeData);
      FConnection.CommitTrans;
      Result := TConnectorResult.OK(Length(ANodes));
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

function TSQLServerConnector.SaveCentres(const ACentres: TArray<TCentreTreball>): TConnectorResult;
begin
  try
    FConnection.BeginTrans;
    try
      InternalSaveCentres(ACentres);
      FConnection.CommitTrans;
      Result := TConnectorResult.OK(Length(ACentres));
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

function TSQLServerConnector.SaveLinks(AProjectId: Integer;
  const ALinks: TArray<TErpLink>): TConnectorResult;
begin
  try
    FConnection.BeginTrans;
    try
      InternalSaveLinks(AProjectId, ALinks);
      FConnection.CommitTrans;
      Result := TConnectorResult.OK(Length(ALinks));
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

function TSQLServerConnector.SaveMarkers(AProjectId: Integer;
  const AMarkers: TArray<TGanttMarker>): TConnectorResult;
begin
  try
    FConnection.BeginTrans;
    try
      InternalSaveMarkers(AProjectId, AMarkers);
      FConnection.CommitTrans;
      Result := TConnectorResult.OK(Length(AMarkers));
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

function TSQLServerConnector.SaveOperarios(const AOperarios: TArray<TOperario>;
  const ADepts: TArray<TDepartamento>;
  const ARelaciones: TArray<TOperarioDepartamento>;
  const ACapacitaciones: TArray<TCapacitacion>;
  const AAsignaciones: TArray<TAsignacionOperario>): TConnectorResult;
begin
  try
    FConnection.BeginTrans;
    try
      InternalSaveOperarios(AOperarios, ADepts, ARelaciones, ACapacitaciones, AAsignaciones);
      FConnection.CommitTrans;
      Result := TConnectorResult.OK;
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

function TSQLServerConnector.SaveShifts(const AShifts: TArray<TTurno>): TConnectorResult;
begin
  try
    FConnection.BeginTrans;
    try
      InternalSaveShifts(AShifts);
      FConnection.CommitTrans;
      Result := TConnectorResult.OK(Length(AShifts));
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

function TSQLServerConnector.SaveMoldes(const AMoldes: TArray<TMolde>): TConnectorResult;
begin
  try
    FConnection.BeginTrans;
    try
      InternalSaveMoldes(AMoldes);
      FConnection.CommitTrans;
      Result := TConnectorResult.OK(Length(AMoldes));
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

function TSQLServerConnector.SaveCustomFieldDefs(const ADefs: TArray<TCustomFieldDef>): TConnectorResult;
begin
  try
    FConnection.BeginTrans;
    try
      InternalSaveCustomFieldDefs(ADefs);
      FConnection.CommitTrans;
      Result := TConnectorResult.OK(Length(ADefs));
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

function TSQLServerConnector.SavePlanningProfiles(const AProfiles: TArray<TPlanningProfile>;
  AActiveIndex: Integer): TConnectorResult;
begin
  try
    FConnection.BeginTrans;
    try
      InternalSavePlanningProfiles(AProfiles, AActiveIndex);
      FConnection.CommitTrans;
      Result := TConnectorResult.OK(Length(AProfiles));
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

// ════════════════════════════════════════════════════════════════════
//  FUNCIONES DE GUARDADO INTERNAS
// ════════════════════════════════════════════════════════════════════

procedure TSQLServerConnector.InternalSaveCentres(const ACentres: TArray<TCentreTreball>);
var
  I: Integer;
  C: TCentreTreball;
begin
  for I := 0 to High(ACentres) do
  begin
    C := ACentres[I];
    ExecSQL(
      'IF EXISTS (SELECT 1 FROM FS_PL_Center WHERE CenterId = ' + IntToStr(C.Id) + ') ' +
      'UPDATE FS_PL_Center SET ' +
        'CodigoCentro = ' + QuotedStr(C.CodiCentre) + ', ' +
        'Titulo = ' + QuotedStr(C.Titulo) + ', ' +
        'Subtitulo = ' + QuotedStr(C.Subtitulo) + ', ' +
        'EsSecuencial = ' + IfThen(C.IsSequencial, '1', '0') + ', ' +
        'MaxLanes = ' + IntToStr(C.MaxLaneCount) + ', ' +
        'AlturaBase = ' + FloatToStr(C.BaseHeight) + ', ' +
        'Orden = ' + IntToStr(C.Order) + ', ' +
        'Visible = ' + IfThen(C.Visible, '1', '0') + ', ' +
        'Habilitado = ' + IfThen(C.Enabled, '1', '0') + ', ' +
        'ColorFondo = ' + ColorToSQL(C.BkColor) +
      ' WHERE CenterId = ' + IntToStr(C.Id) + ' ' +
      'ELSE ' +
      'SET IDENTITY_INSERT FS_PL_Center ON; ' +
      'INSERT INTO FS_PL_Center (CenterId, CodigoCentro, Titulo, Subtitulo, EsSecuencial, ' +
        'MaxLanes, AlturaBase, Orden, Visible, Habilitado, ColorFondo) VALUES (' +
        IntToStr(C.Id) + ', ' +
        QuotedStr(C.CodiCentre) + ', ' +
        QuotedStr(C.Titulo) + ', ' +
        QuotedStr(C.Subtitulo) + ', ' +
        IfThen(C.IsSequencial, '1', '0') + ', ' +
        IntToStr(C.MaxLaneCount) + ', ' +
        FloatToStr(C.BaseHeight) + ', ' +
        IntToStr(C.Order) + ', ' +
        IfThen(C.Visible, '1', '0') + ', ' +
        IfThen(C.Enabled, '1', '0') + ', ' +
        ColorToSQL(C.BkColor) + '); ' +
      'SET IDENTITY_INSERT FS_PL_Center OFF;'
    );
  end;
end;

procedure TSQLServerConnector.InternalSaveNodes(AProjectId: Integer;
  const ANodes: TArray<TNode>; const ANodeData: TArray<TNodeData>);
var
  I, J: Integer;
  N: TNode;
  D: TNodeData;
  DataMap: TDictionary<Integer, Integer>;
begin
  // Construir mapa DataId -> índice en ANodeData
  DataMap := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to High(ANodeData) do
      DataMap.AddOrSetValue(ANodeData[I].DataId, I);

    // Borrar nodos del proyecto que ya no existen
    ExecSQL('DELETE FROM FS_PL_Node WHERE ProjectId = ' + IntToStr(AProjectId) +
      ' AND NodeId NOT IN (SELECT NodeId FROM FS_PL_Node WHERE ProjectId <> ' +
      IntToStr(AProjectId) + ')');

    for I := 0 to High(ANodes) do
    begin
      N := ANodes[I];

      // MERGE Node
      ExecSQL(
        'IF EXISTS (SELECT 1 FROM FS_PL_Node WHERE NodeId = ' + IntToStr(N.Id) + ') ' +
        'UPDATE FS_PL_Node SET ' +
          'CenterId = ' + IntToStr(N.CentreId) + ', ' +
          'FechaInicio = ' + DateTimeToSQL(N.StartTime) + ', ' +
          'FechaFin = ' + DateTimeToSQL(N.EndTime) + ', ' +
          'DuracionMin = ' + FloatToStr(N.DurationMin) + ', ' +
          'Caption = ' + QuotedStr(N.Caption) + ', ' +
          'ColorFondo = ' + ColorToSQL(N.FillColor) + ', ' +
          'ColorBorde = ' + ColorToSQL(N.BorderColor) + ', ' +
          'Visible = ' + IfThen(N.Visible, '1', '0') + ', ' +
          'Habilitado = ' + IfThen(N.Enabled, '1', '0') +
        ' WHERE NodeId = ' + IntToStr(N.Id) + ' ' +
        'ELSE ' +
        'SET IDENTITY_INSERT FS_PL_Node ON; ' +
        'INSERT INTO FS_PL_Node (NodeId, ProjectId, CenterId, FechaInicio, FechaFin, ' +
          'DuracionMin, Caption, ColorFondo, ColorBorde, Visible, Habilitado) VALUES (' +
          IntToStr(N.Id) + ', ' +
          IntToStr(AProjectId) + ', ' +
          IntToStr(N.CentreId) + ', ' +
          DateTimeToSQL(N.StartTime) + ', ' +
          DateTimeToSQL(N.EndTime) + ', ' +
          FloatToStr(N.DurationMin) + ', ' +
          QuotedStr(N.Caption) + ', ' +
          ColorToSQL(N.FillColor) + ', ' +
          ColorToSQL(N.BorderColor) + ', ' +
          IfThen(N.Visible, '1', '0') + ', ' +
          IfThen(N.Enabled, '1', '0') + '); ' +
        'SET IDENTITY_INSERT FS_PL_Node OFF;'
      );

      // NodeData (si existeix)
      if DataMap.ContainsKey(N.DataId) then
      begin
        D := ANodeData[DataMap[N.DataId]];
        ExecSQL(
          'IF EXISTS (SELECT 1 FROM FS_PL_NodeData WHERE NodeId = ' + IntToStr(N.Id) + ') ' +
          'UPDATE FS_PL_NodeData SET ' +
            'Operacion = ' + QuotedStr(D.Operacion) + ', ' +
            'NumeroPedido = ' + IntToStr(D.NumeroPedido) + ', ' +
            'SeriePedido = ' + QuotedStr(D.SeriePedido) + ', ' +
            'NumeroOF = ' + IntToStr(D.NumeroOrdenFabricacion) + ', ' +
            'SerieOF = ' + QuotedStr(D.SerieFabricacion) + ', ' +
            'NumeroTrabajo = ' + QuotedStr(D.NumeroTrabajo) + ', ' +
            'FechaEntrega = ' + DateTimeToSQL(D.FechaEntrega) + ', ' +
            'FechaNecesaria = ' + DateTimeToSQL(D.FechaNecesaria) + ', ' +
            'CodigoCliente = ' + QuotedStr(D.CodigoCliente) + ', ' +
            'CodigoColor = ' + QuotedStr(D.CodigoColor) + ', ' +
            'CodigoTalla = ' + QuotedStr(D.CodigoTalla) + ', ' +
            'Stock = ' + FloatToStr(D.Stock) + ', ' +
            'CodigoArticulo = ' + QuotedStr(D.CodigoArticulo) + ', ' +
            'DescripcionArticulo = ' + QuotedStr(D.DescripcionArticulo) + ', ' +
            'PorcentajeDependencia = ' + FloatToStr(D.PorcentajeDependencia) + ', ' +
            'UnidadesFabricadas = ' + FloatToStr(D.UnidadesFabricadas) + ', ' +
            'UnidadesAFabricar = ' + FloatToStr(D.UnidadesAFabricar) + ', ' +
            'TiempoUnidadFabSecs = ' + FloatToStr(D.TiempoUnidadFabSecs) + ', ' +
            'DuracionMin = ' + FloatToStr(D.DurationMin) + ', ' +
            'DuracionMinOriginal = ' + FloatToStr(D.DurationMinOriginal) + ', ' +
            'OperariosNecesarios = ' + IntToStr(D.OperariosNecesarios) + ', ' +
            'OperariosAsignados = ' + IntToStr(D.OperariosAsignados) + ', ' +
            'Estado = ' + IntToStr(Ord(D.Estado)) + ', ' +
            'Tipo = ' + IntToStr(Ord(D.Tipo)) + ', ' +
            'Prioridad = ' + IntToStr(D.Prioridad) + ', ' +
            'ColorFondoOp = ' + ColorToSQL(D.bkColorOp) + ', ' +
            'ColorBordeOp = ' + ColorToSQL(D.borderColorOp) + ', ' +
            'LibreMovimiento = ' + IfThen(D.LibreMoviment, '1', '0') +
          ' WHERE NodeId = ' + IntToStr(N.Id) + ' ' +
          'ELSE ' +
          'INSERT INTO FS_PL_NodeData (NodeId, Operacion, NumeroPedido, SeriePedido, ' +
            'NumeroOF, SerieOF, NumeroTrabajo, FechaEntrega, FechaNecesaria, ' +
            'CodigoCliente, CodigoColor, CodigoTalla, Stock, CodigoArticulo, ' +
            'DescripcionArticulo, PorcentajeDependencia, UnidadesFabricadas, ' +
            'UnidadesAFabricar, TiempoUnidadFabSecs, DuracionMin, DuracionMinOriginal, ' +
            'OperariosNecesarios, OperariosAsignados, Estado, Tipo, Prioridad, ' +
            'ColorFondoOp, ColorBordeOp, LibreMovimiento) VALUES (' +
            IntToStr(N.Id) + ', ' +
            QuotedStr(D.Operacion) + ', ' +
            IntToStr(D.NumeroPedido) + ', ' +
            QuotedStr(D.SeriePedido) + ', ' +
            IntToStr(D.NumeroOrdenFabricacion) + ', ' +
            QuotedStr(D.SerieFabricacion) + ', ' +
            QuotedStr(D.NumeroTrabajo) + ', ' +
            DateTimeToSQL(D.FechaEntrega) + ', ' +
            DateTimeToSQL(D.FechaNecesaria) + ', ' +
            QuotedStr(D.CodigoCliente) + ', ' +
            QuotedStr(D.CodigoColor) + ', ' +
            QuotedStr(D.CodigoTalla) + ', ' +
            FloatToStr(D.Stock) + ', ' +
            QuotedStr(D.CodigoArticulo) + ', ' +
            QuotedStr(D.DescripcionArticulo) + ', ' +
            FloatToStr(D.PorcentajeDependencia) + ', ' +
            FloatToStr(D.UnidadesFabricadas) + ', ' +
            FloatToStr(D.UnidadesAFabricar) + ', ' +
            FloatToStr(D.TiempoUnidadFabSecs) + ', ' +
            FloatToStr(D.DurationMin) + ', ' +
            FloatToStr(D.DurationMinOriginal) + ', ' +
            IntToStr(D.OperariosNecesarios) + ', ' +
            IntToStr(D.OperariosAsignados) + ', ' +
            IntToStr(Ord(D.Estado)) + ', ' +
            IntToStr(Ord(D.Tipo)) + ', ' +
            IntToStr(D.Prioridad) + ', ' +
            ColorToSQL(D.bkColorOp) + ', ' +
            ColorToSQL(D.borderColorOp) + ', ' +
            IfThen(D.LibreMoviment, '1', '0') + ')'
        );

        // Centros permitidos
        ExecSQL('DELETE FROM FS_PL_NodeCenterAllowed WHERE NodeId = ' + IntToStr(N.Id));
        for J := 0 to High(D.CentresPermesos) do
          ExecSQL('INSERT INTO FS_PL_NodeCenterAllowed (NodeId, CenterId) VALUES (' +
            IntToStr(N.Id) + ', ' + IntToStr(D.CentresPermesos[J]) + ')');

        // Custom fields
        ExecSQL('DELETE FROM FS_PL_CustomFieldValue WHERE NodeId = ' + IntToStr(N.Id));
        for J := 0 to High(D.CustomFields) do
          ExecSQL(
            'INSERT INTO FS_PL_CustomFieldValue (NodeId, FieldDefId, Valor) ' +
            'SELECT ' + IntToStr(N.Id) + ', FieldDefId, ' +
              QuotedStr(VarToStr(D.CustomFields[J].Value)) +
            ' FROM FS_PL_CustomFieldDef WHERE FieldName = ' +
              QuotedStr(D.CustomFields[J].FieldName));
      end;
    end;
  finally
    DataMap.Free;
  end;
end;

procedure TSQLServerConnector.InternalSaveLinks(AProjectId: Integer;
  const ALinks: TArray<TErpLink>);
var
  I: Integer;
  L: TErpLink;
begin
  ExecSQL('DELETE FROM FS_PL_Dependency WHERE ProjectId = ' + IntToStr(AProjectId));
  for I := 0 to High(ALinks) do
  begin
    L := ALinks[I];
    ExecSQL('INSERT INTO FS_PL_Dependency (ProjectId, FromNodeId, ToNodeId, TipoLink, ' +
      'PorcentajeDependencia) VALUES (' +
      IntToStr(AProjectId) + ', ' +
      IntToStr(L.FromNodeId) + ', ' +
      IntToStr(L.ToNodeId) + ', ' +
      IntToStr(Ord(L.LinkType)) + ', ' +
      FloatToStr(L.PorcentajeDependencia) + ')');
  end;
end;

procedure TSQLServerConnector.InternalSaveMarkers(AProjectId: Integer;
  const AMarkers: TArray<TGanttMarker>);
var
  I: Integer;
  M: TGanttMarker;
begin
  ExecSQL('DELETE FROM FS_PL_Marker WHERE ProjectId = ' + IntToStr(AProjectId));
  for I := 0 to High(AMarkers) do
  begin
    M := AMarkers[I];
    ExecSQL('INSERT INTO FS_PL_Marker (ProjectId, FechaHora, Caption, Color, Estilo, ' +
      'GrosorLinea, Movible, Visible, Tag, FontName, FontSize, FontColor, FontStyle, ' +
      'OrientacionTexto, AlineacionTexto) VALUES (' +
      IntToStr(AProjectId) + ', ' +
      DateTimeToSQL(M.DateTime) + ', ' +
      QuotedStr(M.Caption) + ', ' +
      ColorToSQL(M.Color) + ', ' +
      IntToStr(Ord(M.Style)) + ', ' +
      FloatToStr(M.StrokeWidth) + ', ' +
      IfThen(M.Moveable, '1', '0') + ', ' +
      IfThen(M.Visible, '1', '0') + ', ' +
      IntToStr(M.Tag) + ', ' +
      QuotedStr(M.FontName) + ', ' +
      IntToStr(M.FontSize) + ', ' +
      ColorToSQL(M.FontColor) + ', ' +
      IntToStr(Byte(M.FontStyle)) + ', ' +
      IntToStr(Ord(M.TextOrientation)) + ', ' +
      IntToStr(Ord(M.TextAlign)) + ')');
  end;
end;

procedure TSQLServerConnector.InternalSaveShifts(const AShifts: TArray<TTurno>);
var
  I: Integer;
  T: TTurno;
begin
  ExecSQL('DELETE FROM FS_PL_Shift');
  for I := 0 to High(AShifts) do
  begin
    T := AShifts[I];
    ExecSQL(
      'SET IDENTITY_INSERT FS_PL_Shift ON; ' +
      'INSERT INTO FS_PL_Shift (ShiftId, Nombre, HoraInicio, HoraFin, Color, Activo, Orden) VALUES (' +
        IntToStr(T.Id) + ', ' +
        QuotedStr(T.Nombre) + ', ' +
        TimeToSQL(T.HoraInicio) + ', ' +
        TimeToSQL(T.HoraFin) + ', ' +
        ColorToSQL(T.Color) + ', ' +
        IfThen(T.Activo, '1', '0') + ', ' +
        IntToStr(T.Order) + '); ' +
      'SET IDENTITY_INSERT FS_PL_Shift OFF;');
  end;
end;

procedure TSQLServerConnector.InternalSaveOperarios(const AOperarios: TArray<TOperario>;
  const ADepts: TArray<TDepartamento>;
  const ARels: TArray<TOperarioDepartamento>;
  const ACaps: TArray<TCapacitacion>;
  const AAsig: TArray<TAsignacionOperario>);
var
  I: Integer;
begin
  // Departamentos
  ExecSQL('DELETE FROM FS_PL_OperatorDepartment');
  ExecSQL('DELETE FROM FS_PL_OperatorSkill');
  ExecSQL('DELETE FROM FS_PL_OperatorAssignment');

  for I := 0 to High(ADepts) do
    ExecSQL(
      'IF NOT EXISTS (SELECT 1 FROM FS_PL_Department WHERE DepartmentId = ' + IntToStr(ADepts[I].Id) + ') ' +
      'BEGIN SET IDENTITY_INSERT FS_PL_Department ON; ' +
      'INSERT INTO FS_PL_Department (DepartmentId, Nombre, Descripcion) VALUES (' +
        IntToStr(ADepts[I].Id) + ', ' +
        QuotedStr(ADepts[I].Nombre) + ', ' +
        QuotedStr(ADepts[I].Descripcion) + '); ' +
      'SET IDENTITY_INSERT FS_PL_Department OFF; END ' +
      'ELSE UPDATE FS_PL_Department SET Nombre = ' + QuotedStr(ADepts[I].Nombre) +
        ', Descripcion = ' + QuotedStr(ADepts[I].Descripcion) +
        ' WHERE DepartmentId = ' + IntToStr(ADepts[I].Id));

  // Operarios
  for I := 0 to High(AOperarios) do
    ExecSQL(
      'IF NOT EXISTS (SELECT 1 FROM FS_PL_Operator WHERE OperatorId = ' + IntToStr(AOperarios[I].Id) + ') ' +
      'BEGIN SET IDENTITY_INSERT FS_PL_Operator ON; ' +
      'INSERT INTO FS_PL_Operator (OperatorId, Nombre) VALUES (' +
        IntToStr(AOperarios[I].Id) + ', ' +
        QuotedStr(AOperarios[I].Nombre) + '); ' +
      'SET IDENTITY_INSERT FS_PL_Operator OFF; END ' +
      'ELSE UPDATE FS_PL_Operator SET Nombre = ' + QuotedStr(AOperarios[I].Nombre) +
        ' WHERE OperatorId = ' + IntToStr(AOperarios[I].Id));

  // Relaciones
  for I := 0 to High(ARels) do
    ExecSQL('INSERT INTO FS_PL_OperatorDepartment (OperatorId, DepartmentId) VALUES (' +
      IntToStr(ARels[I].OperarioId) + ', ' + IntToStr(ARels[I].DepartamentoId) + ')');

  // Capacitaciones
  for I := 0 to High(ACaps) do
    ExecSQL('INSERT INTO FS_PL_OperatorSkill (OperatorId, Operacion) VALUES (' +
      IntToStr(ACaps[I].OperarioId) + ', ' + QuotedStr(ACaps[I].Operacion) + ')');

  // Asignaciones
  for I := 0 to High(AAsig) do
    ExecSQL('INSERT INTO FS_PL_OperatorAssignment (OperatorId, NodeId, Horas) VALUES (' +
      IntToStr(AAsig[I].OperarioId) + ', ' + IntToStr(AAsig[I].DataId) + ', ' +
      FloatToStr(AAsig[I].Horas) + ')');
end;

procedure TSQLServerConnector.InternalSaveMoldes(const AMoldes: TArray<TMolde>);
var
  I, J: Integer;
  M: TMolde;
begin
  // Limpiar relaciones
  ExecSQL('DELETE FROM FS_PL_MoldCenter');
  ExecSQL('DELETE FROM FS_PL_MoldArticle');
  ExecSQL('DELETE FROM FS_PL_MoldOperation');

  for I := 0 to High(AMoldes) do
  begin
    M := AMoldes[I];
    ExecSQL(
      'IF NOT EXISTS (SELECT 1 FROM FS_PL_Mold WHERE MoldId = ' + IntToStr(M.IdMolde) + ') ' +
      'BEGIN SET IDENTITY_INSERT FS_PL_Mold ON; ' +
      'INSERT INTO FS_PL_Mold (MoldId, Codigo, Descripcion, TipoMolde, Estado, ' +
        'UbicacionActual, NumeroCavidades, TiempoMontaje, TiempoDesmontaje, TiempoAjuste, ' +
        'CiclosAcumulados, FechaProxMantenimiento, DisponiblePlanificacion, Observaciones) VALUES (' +
        IntToStr(M.IdMolde) + ', ' +
        QuotedStr(M.CodigoMolde) + ', ' +
        QuotedStr(M.Descripcion) + ', ' +
        IntToStr(Ord(M.TipoMolde)) + ', ' +
        IntToStr(Ord(M.Estado)) + ', ' +
        QuotedStr(M.UbicacionActual) + ', ' +
        IntToStr(M.NumeroCavidades) + ', ' +
        FloatToStr(M.TiempoMontaje) + ', ' +
        FloatToStr(M.TiempoDesmontaje) + ', ' +
        FloatToStr(M.TiempoAjuste) + ', ' +
        IntToStr(M.CiclosAcumulados) + ', ' +
        DateTimeToSQL(M.FechaProximoMantenimiento) + ', ' +
        IfThen(M.DisponiblePlanificacion, '1', '0') + ', ' +
        QuotedStr(M.Observaciones) + '); ' +
      'SET IDENTITY_INSERT FS_PL_Mold OFF; END ' +
      'ELSE UPDATE FS_PL_Mold SET ' +
        'Codigo = ' + QuotedStr(M.CodigoMolde) + ', ' +
        'Descripcion = ' + QuotedStr(M.Descripcion) + ', ' +
        'TipoMolde = ' + IntToStr(Ord(M.TipoMolde)) + ', ' +
        'Estado = ' + IntToStr(Ord(M.Estado)) + ', ' +
        'UbicacionActual = ' + QuotedStr(M.UbicacionActual) + ', ' +
        'NumeroCavidades = ' + IntToStr(M.NumeroCavidades) + ', ' +
        'TiempoMontaje = ' + FloatToStr(M.TiempoMontaje) + ', ' +
        'TiempoDesmontaje = ' + FloatToStr(M.TiempoDesmontaje) + ', ' +
        'TiempoAjuste = ' + FloatToStr(M.TiempoAjuste) + ', ' +
        'CiclosAcumulados = ' + IntToStr(M.CiclosAcumulados) + ', ' +
        'FechaProxMantenimiento = ' + DateTimeToSQL(M.FechaProximoMantenimiento) + ', ' +
        'DisponiblePlanificacion = ' + IfThen(M.DisponiblePlanificacion, '1', '0') + ', ' +
        'Observaciones = ' + QuotedStr(M.Observaciones) +
      ' WHERE MoldId = ' + IntToStr(M.IdMolde));

    // Centros permitidos del molde
    for J := 0 to High(M.CentrosTrabajoPermitidos) do
      ExecSQL('INSERT INTO FS_PL_MoldCenter (MoldId, CenterId) ' +
        'SELECT ' + IntToStr(M.IdMolde) + ', CenterId FROM FS_PL_Center ' +
        'WHERE CodigoCentro = ' + QuotedStr(M.CentrosTrabajoPermitidos[J]));

    // Artículos
    for J := 0 to High(M.ArticulosAsociados) do
      ExecSQL('INSERT INTO FS_PL_MoldArticle (MoldId, CodigoArticulo) VALUES (' +
        IntToStr(M.IdMolde) + ', ' + QuotedStr(M.ArticulosAsociados[J]) + ')');

    // Operaciones
    for J := 0 to High(M.OperacionesAsociadas) do
      ExecSQL('INSERT INTO FS_PL_MoldOperation (MoldId, Operacion) VALUES (' +
        IntToStr(M.IdMolde) + ', ' + QuotedStr(M.OperacionesAsociadas[J]) + ')');
  end;
end;

procedure TSQLServerConnector.InternalSaveCustomFieldDefs(const ADefs: TArray<TCustomFieldDef>);
var
  I: Integer;
  D: TCustomFieldDef;
  ListStr: string;
begin
  for I := 0 to High(ADefs) do
  begin
    D := ADefs[I];
    ListStr := String.Join('|', D.ListValues);
    ExecSQL(
      'IF EXISTS (SELECT 1 FROM FS_PL_CustomFieldDef WHERE FieldName = ' + QuotedStr(D.FieldName) + ') ' +
      'UPDATE FS_PL_CustomFieldDef SET ' +
        'Caption = ' + QuotedStr(D.Caption) + ', ' +
        'TipoCampo = ' + IntToStr(Ord(D.FieldType)) + ', ' +
        'ValorDefecto = ' + QuotedStr(VarToStr(D.DefaultValue)) + ', ' +
        'ValoresLista = ' + QuotedStr(ListStr) + ', ' +
        'Requerido = ' + IfThen(D.Required, '1', '0') + ', ' +
        'SoloLectura = ' + IfThen(D.ReadOnly, '1', '0') + ', ' +
        'Orden = ' + IntToStr(D.Order) + ', ' +
        'Visible = ' + IfThen(D.Visible, '1', '0') + ', ' +
        'Grupo = ' + QuotedStr(D.Grupo) + ', ' +
        'Tooltip = ' + QuotedStr(D.Tooltip) + ', ' +
        'ValorMinimo = ' + FloatToStr(D.MinValue) + ', ' +
        'ValorMaximo = ' + FloatToStr(D.MaxValue) + ', ' +
        'FormatoMascara = ' + QuotedStr(D.FormatMask) +
      ' WHERE FieldName = ' + QuotedStr(D.FieldName) + ' ' +
      'ELSE ' +
      'INSERT INTO FS_PL_CustomFieldDef (FieldName, Caption, TipoCampo, ValorDefecto, ' +
        'ValoresLista, Requerido, SoloLectura, Orden, Visible, Grupo, Tooltip, ' +
        'ValorMinimo, ValorMaximo, FormatoMascara) VALUES (' +
        QuotedStr(D.FieldName) + ', ' +
        QuotedStr(D.Caption) + ', ' +
        IntToStr(Ord(D.FieldType)) + ', ' +
        QuotedStr(VarToStr(D.DefaultValue)) + ', ' +
        QuotedStr(ListStr) + ', ' +
        IfThen(D.Required, '1', '0') + ', ' +
        IfThen(D.ReadOnly, '1', '0') + ', ' +
        IntToStr(D.Order) + ', ' +
        IfThen(D.Visible, '1', '0') + ', ' +
        QuotedStr(D.Grupo) + ', ' +
        QuotedStr(D.Tooltip) + ', ' +
        FloatToStr(D.MinValue) + ', ' +
        FloatToStr(D.MaxValue) + ', ' +
        QuotedStr(D.FormatMask) + ')');
  end;
end;

procedure TSQLServerConnector.InternalSavePlanningProfiles(
  const AProfiles: TArray<TPlanningProfile>; AActiveIndex: Integer);
var
  I, J, ProfId: Integer;
  P: TPlanningProfile;
  Q: TADOQuery;
begin
  // Limpiar todo y reinsertar
  ExecSQL('DELETE FROM FS_PL_SortRule');
  ExecSQL('DELETE FROM FS_PL_FilterRule');
  ExecSQL('DELETE FROM FS_PL_GroupRule');
  ExecSQL('DELETE FROM FS_PL_PlanningProfile');

  for I := 0 to High(AProfiles) do
  begin
    P := AProfiles[I];
    ExecSQL('INSERT INTO FS_PL_PlanningProfile (Nombre, Descripcion, EsActivo) VALUES (' +
      QuotedStr(P.Name) + ', ' +
      QuotedStr(P.Description) + ', ' +
      IfThen(I = AActiveIndex, '1', '0') + ')');

    Q := OpenQuery('SELECT SCOPE_IDENTITY() AS NewId');
    try
      ProfId := Q.FieldByName('NewId').AsInteger;
    finally
      Q.Free;
    end;

    // Sort rules
    for J := 0 to High(P.SortRules) do
      ExecSQL('INSERT INTO FS_PL_SortRule (ProfileId, FieldName, Direccion, Peso, Habilitado, Orden) VALUES (' +
        IntToStr(ProfId) + ', ' +
        QuotedStr(P.SortRules[J].FieldName) + ', ' +
        IntToStr(Ord(P.SortRules[J].Direction)) + ', ' +
        IntToStr(P.SortRules[J].Weight) + ', ' +
        IfThen(P.SortRules[J].Enabled, '1', '0') + ', ' +
        IntToStr(J) + ')');

    // Filter rules
    for J := 0 to High(P.FilterRules) do
      ExecSQL('INSERT INTO FS_PL_FilterRule (ProfileId, FieldName, Operador, Valor, Accion, ' +
        'CentroDestinoId, Habilitado, Orden) VALUES (' +
        IntToStr(ProfId) + ', ' +
        QuotedStr(P.FilterRules[J].FieldName) + ', ' +
        IntToStr(Ord(P.FilterRules[J].Operator)) + ', ' +
        QuotedStr(VarToStr(P.FilterRules[J].Value)) + ', ' +
        IntToStr(Ord(P.FilterRules[J].Action)) + ', ' +
        IntToStr(P.FilterRules[J].TargetCentreId) + ', ' +
        IfThen(P.FilterRules[J].Enabled, '1', '0') + ', ' +
        IntToStr(J) + ')');

    // Group rules
    for J := 0 to High(P.GroupRules) do
      ExecSQL('INSERT INTO FS_PL_GroupRule (ProfileId, FieldName, Modo, Peso, Habilitado, Orden) VALUES (' +
        IntToStr(ProfId) + ', ' +
        QuotedStr(P.GroupRules[J].FieldName) + ', ' +
        IntToStr(Ord(P.GroupRules[J].Mode)) + ', ' +
        IntToStr(P.GroupRules[J].Weight) + ', ' +
        IfThen(P.GroupRules[J].Enabled, '1', '0') + ', ' +
        IntToStr(J) + ')');
  end;
end;

// ════════════════════════════════════════════════════════════════════
//  SNAPSHOTS
// ════════════════════════════════════════════════════════════════════

function TSQLServerConnector.CreateSnapshot(AProjectId: Integer;
  const ANombre, ADescripcion: string): TConnectorResult;
var
  Data: TPlanningData;
  JSON: TJSONObject;
  R: TConnectorResult;
begin
  R := LoadPlanning(AProjectId, Data);
  if not R.Success then
    Exit(R);

  // Serializar a JSON simplificado (usamos el conteo como indicador)
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('centres', TJSONNumber.Create(Length(Data.Centres)));
    JSON.AddPair('nodes', TJSONNumber.Create(Length(Data.Nodes)));
    JSON.AddPair('links', TJSONNumber.Create(Length(Data.Links)));
    // TODO: serialización completa a JSON

    try
      ExecSQL('INSERT INTO FS_PL_Snapshot (ProjectId, Nombre, Descripcion, DatosJSON) VALUES (' +
        IntToStr(AProjectId) + ', ' +
        QuotedStr(ANombre) + ', ' +
        QuotedStr(ADescripcion) + ', ' +
        QuotedStr(JSON.ToString) + ')');
      Result := TConnectorResult.OK(1);
    except
      on E: Exception do
        Result := TConnectorResult.Fail(E.Message);
    end;
  finally
    JSON.Free;
  end;
end;

function TSQLServerConnector.GetSnapshots(AProjectId: Integer): TArray<TProjectInfo>;
var
  Q: TADOQuery;
  I: Integer;
begin
  Q := OpenQuery('SELECT SnapshotId, Nombre, Descripcion, FechaCreacion, CreadoPor ' +
    'FROM FS_PL_Snapshot WHERE ProjectId = ' + IntToStr(AProjectId) + ' ORDER BY FechaCreacion DESC');
  try
    SetLength(Result, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      Result[I].ProjectId := Q.FieldByName('SnapshotId').AsInteger;
      Result[I].Nombre := Q.FieldByName('Nombre').AsString;
      Result[I].Descripcion := SQLToStr(Q.FieldByName('Descripcion').Value);
      Result[I].FechaCreacion := Q.FieldByName('FechaCreacion').AsDateTime;
      Result[I].Activo := True;
      Inc(I);
      Q.Next;
    end;
    SetLength(Result, I);
  finally
    Q.Free;
  end;
end;

function TSQLServerConnector.LoadSnapshot(ASnapshotId: Integer;
  out AData: TPlanningData): TConnectorResult;
begin
  // TODO: deserializar el JSON del snapshot
  Result := TConnectorResult.Fail('LoadSnapshot: pendiente de implementar deserialización JSON completa');
end;

// ════════════════════════════════════════════════════════════════════
//  MAPEO ERP
// ════════════════════════════════════════════════════════════════════

function TSQLServerConnector.SetErpMapping(const ATipoEntidad: string;
  AEntidadId: Integer; const AErpSistema, AErpClave: string): TConnectorResult;
begin
  try
    ExecSQL(
      'IF EXISTS (SELECT 1 FROM FS_PL_ErpMapping WHERE TipoEntidad = ' + QuotedStr(ATipoEntidad) +
        ' AND EntidadId = ' + IntToStr(AEntidadId) +
        ' AND ErpSistema = ' + QuotedStr(AErpSistema) + ') ' +
      'UPDATE FS_PL_ErpMapping SET ErpClave = ' + QuotedStr(AErpClave) +
        ', FechaSincro = GETDATE() ' +
        'WHERE TipoEntidad = ' + QuotedStr(ATipoEntidad) +
        ' AND EntidadId = ' + IntToStr(AEntidadId) +
        ' AND ErpSistema = ' + QuotedStr(AErpSistema) + ' ' +
      'ELSE ' +
      'INSERT INTO FS_PL_ErpMapping (TipoEntidad, EntidadId, ErpSistema, ErpClave) VALUES (' +
        QuotedStr(ATipoEntidad) + ', ' +
        IntToStr(AEntidadId) + ', ' +
        QuotedStr(AErpSistema) + ', ' +
        QuotedStr(AErpClave) + ')');
    Result := TConnectorResult.OK(1);
  except
    on E: Exception do
      Result := TConnectorResult.Fail(E.Message);
  end;
end;

function TSQLServerConnector.GetErpMapping(const ATipoEntidad: string;
  AEntidadId: Integer; const AErpSistema: string): string;
var
  Q: TADOQuery;
begin
  Result := '';
  Q := OpenQuery(
    'SELECT ErpClave FROM FS_PL_ErpMapping WHERE TipoEntidad = ' + QuotedStr(ATipoEntidad) +
    ' AND EntidadId = ' + IntToStr(AEntidadId) +
    ' AND ErpSistema = ' + QuotedStr(AErpSistema));
  try
    if not Q.Eof then
      Result := Q.FieldByName('ErpClave').AsString;
  finally
    Q.Free;
  end;
end;

end.
