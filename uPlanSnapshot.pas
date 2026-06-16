unit uPlanSnapshot;
// Serializacion / deserializacion del PLAN de un proyecto a JSON, para los
// puntos de restauracion (FS_PL_Snapshot).
//
// Captura SOLO lo que define la planificacion y que el usuario puede estropear:
//   - Nodes (posicion temporal: centro, inicio, fin, duracion, lote, visible).
//   - NodeData (datos de negocio + operarios asignados + centros permitidos).
//   - Links (dependencias entre nodos).
//   - Asignaciones (operarios por nodo).
//   - Markers (marcadores del Gantt).
// NO incluye datos maestros (centros, operarios, calendarios, moldes): son
// entidades propias y no se revierten al restaurar el plan.
//
// El formato lleva 'version' para poder evolucionar sin romper snapshots viejos.
interface

uses
  System.SysUtils, System.Classes, System.JSON, System.DateUtils,
  System.Generics.Collections, System.UITypes,
  uGanttTypes, uErpTypes, uOperariosTypes, uDataConnector;

const
  SNAPSHOT_FORMAT_VERSION = 1;

// Serializa el plan (Nodes/NodeData/Links/Asignaciones/Markers de AData) a JSON.
function SerializePlan(const AData: TPlanningData): string;

// Deserializa un JSON de snapshot a un TPlanningData (solo rellena las partes
// del plan; el resto de campos quedan vacios). Lanza excepcion si el JSON es
// invalido o de version no soportada.
function DeserializePlan(const AJson: string): TPlanningData;

implementation

// ---------------------------------------------------------------------------
// Helpers JSON (lectura tolerante: valores ausentes -> default).
// ---------------------------------------------------------------------------
function JInt(O: TJSONObject; const Name: string; Def: Integer = 0): Integer;
var V: TJSONValue;
begin
  V := O.Values[Name];
  if (V <> nil) and (V is TJSONNumber) then Result := TJSONNumber(V).AsInt
  else Result := Def;
end;

function JFloat(O: TJSONObject; const Name: string; Def: Double = 0): Double;
var V: TJSONValue;
begin
  V := O.Values[Name];
  if (V <> nil) and (V is TJSONNumber) then Result := TJSONNumber(V).AsDouble
  else Result := Def;
end;

function JStr(O: TJSONObject; const Name: string; const Def: string = ''): string;
var V: TJSONValue;
begin
  V := O.Values[Name];
  if (V <> nil) and not (V is TJSONNull) then Result := V.Value
  else Result := Def;
end;

function JBool(O: TJSONObject; const Name: string; Def: Boolean = False): Boolean;
var V: TJSONValue;
begin
  V := O.Values[Name];
  if V is TJSONTrue then Result := True
  else if V is TJSONFalse then Result := False
  else Result := Def;
end;

// Fechas: ISO 8601 (sortable, sin ambiguedad de locale). 0 -> "".
function DateToJ(const D: TDateTime): string;
begin
  if D = 0 then Result := '' else Result := DateToISO8601(D, False);
end;

function JToDate(O: TJSONObject; const Name: string): TDateTime;
var s: string;
begin
  s := JStr(O, Name);
  if s = '' then Exit(0);
  if not TryISO8601ToDate(s, Result, False) then Result := 0;
end;

function IntArrayToJ(const A: TArray<Integer>): TJSONArray;
var i: Integer;
begin
  Result := TJSONArray.Create;
  for i := 0 to High(A) do Result.Add(A[i]);
end;

function JToIntArray(Arr: TJSONArray): TArray<Integer>;
var i: Integer;
begin
  if Arr = nil then Exit(nil);
  SetLength(Result, Arr.Count);
  for i := 0 to Arr.Count - 1 do
    Result[i] := StrToIntDef(Arr.Items[i].Value, 0);
end;

// ---------------------------------------------------------------------------
// SERIALIZAR
// ---------------------------------------------------------------------------
function NodeToJson(const N: TNode): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(N.Id));
  Result.AddPair('centreId', TJSONNumber.Create(N.CentreId));
  Result.AddPair('start', DateToJ(N.StartTime));
  Result.AddPair('end', DateToJ(N.EndTime));
  Result.AddPair('durMin', TJSONNumber.Create(N.DurationMin));
  Result.AddPair('caption', N.Caption);
  Result.AddPair('fill', TJSONNumber.Create(Integer(N.FillColor)));
  Result.AddPair('border', TJSONNumber.Create(Integer(N.BorderColor)));
  Result.AddPair('visible', TJSONBool.Create(N.Visible));
  Result.AddPair('enabled', TJSONBool.Create(N.Enabled));
  Result.AddPair('dataId', TJSONNumber.Create(N.DataId));
  Result.AddPair('loteId', TJSONNumber.Create(N.LoteId));
end;

function NodeDataToJson(const D: TNodeData): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('dataId', TJSONNumber.Create(D.DataId));
  Result.AddPair('operacion', D.Operacion);
  Result.AddPair('numPed', TJSONNumber.Create(D.NumeroPedido));
  Result.AddPair('serPed', D.SeriePedido);
  Result.AddPair('numOF', TJSONNumber.Create(D.NumeroOrdenFabricacion));
  Result.AddPair('serOF', D.SerieFabricacion);
  Result.AddPair('numTrab', D.NumeroTrabajo);
  Result.AddPair('fEntrega', DateToJ(D.FechaEntrega));
  Result.AddPair('fNecesaria', DateToJ(D.FechaNecesaria));
  Result.AddPair('cliente', D.CodigoCliente);
  Result.AddPair('color', D.CodigoColor);
  Result.AddPair('talla', D.CodigoTalla);
  Result.AddPair('stock', TJSONNumber.Create(D.Stock));
  Result.AddPair('articulo', D.CodigoArticulo);
  Result.AddPair('descArt', D.DescripcionArticulo);
  Result.AddPair('pctDep', TJSONNumber.Create(D.PorcentajeDependencia));
  Result.AddPair('uFab', TJSONNumber.Create(D.UnidadesFabricadas));
  Result.AddPair('uAFab', TJSONNumber.Create(D.UnidadesAFabricar));
  Result.AddPair('tUnidSecs', TJSONNumber.Create(D.TiempoUnidadFabSecs));
  Result.AddPair('durMin', TJSONNumber.Create(D.DurationMin));
  Result.AddPair('durMinOrig', TJSONNumber.Create(D.DurationMinOriginal));
  Result.AddPair('opNec', TJSONNumber.Create(D.OperariosNecesarios));
  Result.AddPair('opAsig', TJSONNumber.Create(D.OperariosAsignados));
  Result.AddPair('estado', TJSONNumber.Create(Ord(D.Estado)));
  Result.AddPair('tipo', TJSONNumber.Create(Ord(D.Tipo)));
  Result.AddPair('prioridad', TJSONNumber.Create(D.Prioridad));
  Result.AddPair('bkColor', TJSONNumber.Create(Integer(D.bkColorOp)));
  Result.AddPair('bdColor', TJSONNumber.Create(Integer(D.borderColorOp)));
  Result.AddPair('libreMov', TJSONBool.Create(D.LibreMoviment));
  Result.AddPair('centresPerm', IntArrayToJ(D.CentresPermesos));
end;

function LinkToJson(const L: TErpLink): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('from', TJSONNumber.Create(L.FromNodeId));
  Result.AddPair('to', TJSONNumber.Create(L.ToNodeId));
  Result.AddPair('type', TJSONNumber.Create(Ord(L.LinkType)));
  Result.AddPair('pctDep', TJSONNumber.Create(L.PorcentajeDependencia));
end;

function AsigToJson(const A: TAsignacionOperario): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('opId', TJSONNumber.Create(A.OperarioId));
  Result.AddPair('dataId', TJSONNumber.Create(A.DataId));
  Result.AddPair('horas', TJSONNumber.Create(A.Horas));
end;

function MarkerToJson(const M: TGanttMarker): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(M.Id));
  Result.AddPair('dt', DateToJ(M.DateTime));
  Result.AddPair('caption', M.Caption);
  Result.AddPair('color', TJSONNumber.Create(Integer(M.Color)));
end;

function SerializePlan(const AData: TPlanningData): string;
var
  Root: TJSONObject;
  Arr: TJSONArray;
  i: Integer;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('version', TJSONNumber.Create(SNAPSHOT_FORMAT_VERSION));
    Root.AddPair('projectId', TJSONNumber.Create(AData.Project.ProjectId));

    Arr := TJSONArray.Create;
    for i := 0 to High(AData.Nodes) do Arr.AddElement(NodeToJson(AData.Nodes[i]));
    Root.AddPair('nodes', Arr);

    Arr := TJSONArray.Create;
    for i := 0 to High(AData.NodeDataList) do
      Arr.AddElement(NodeDataToJson(AData.NodeDataList[i]));
    Root.AddPair('nodeData', Arr);

    Arr := TJSONArray.Create;
    for i := 0 to High(AData.Links) do Arr.AddElement(LinkToJson(AData.Links[i]));
    Root.AddPair('links', Arr);

    Arr := TJSONArray.Create;
    for i := 0 to High(AData.Asignaciones) do
      Arr.AddElement(AsigToJson(AData.Asignaciones[i]));
    Root.AddPair('asignaciones', Arr);

    Arr := TJSONArray.Create;
    for i := 0 to High(AData.Markers) do
      Arr.AddElement(MarkerToJson(AData.Markers[i]));
    Root.AddPair('markers', Arr);

    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

// ---------------------------------------------------------------------------
// DESERIALIZAR
// ---------------------------------------------------------------------------
function JsonToNode(O: TJSONObject): TNode;
begin
  Result := Default(TNode);
  Result.Id := JInt(O, 'id');
  Result.CentreId := JInt(O, 'centreId');
  Result.StartTime := JToDate(O, 'start');
  Result.EndTime := JToDate(O, 'end');
  Result.DurationMin := JFloat(O, 'durMin');
  Result.Caption := JStr(O, 'caption');
  Result.FillColor := TColor(JInt(O, 'fill'));
  Result.BorderColor := TColor(JInt(O, 'border'));
  Result.Visible := JBool(O, 'visible', True);
  Result.Enabled := JBool(O, 'enabled', True);
  Result.DataId := JInt(O, 'dataId');
  Result.LoteId := JInt(O, 'loteId');
end;

function JsonToNodeData(O: TJSONObject): TNodeData;
begin
  Result := Default(TNodeData);
  Result.DataId := JInt(O, 'dataId');
  Result.Operacion := JStr(O, 'operacion');
  Result.NumeroPedido := JInt(O, 'numPed');
  Result.SeriePedido := JStr(O, 'serPed');
  Result.NumeroOrdenFabricacion := JInt(O, 'numOF');
  Result.SerieFabricacion := JStr(O, 'serOF');
  Result.NumeroTrabajo := JStr(O, 'numTrab');
  Result.FechaEntrega := JToDate(O, 'fEntrega');
  Result.FechaNecesaria := JToDate(O, 'fNecesaria');
  Result.CodigoCliente := JStr(O, 'cliente');
  Result.CodigoColor := JStr(O, 'color');
  Result.CodigoTalla := JStr(O, 'talla');
  Result.Stock := JFloat(O, 'stock');
  Result.CodigoArticulo := JStr(O, 'articulo');
  Result.DescripcionArticulo := JStr(O, 'descArt');
  Result.PorcentajeDependencia := JFloat(O, 'pctDep');
  Result.UnidadesFabricadas := JFloat(O, 'uFab');
  Result.UnidadesAFabricar := JFloat(O, 'uAFab');
  Result.TiempoUnidadFabSecs := JFloat(O, 'tUnidSecs');
  Result.DurationMin := JFloat(O, 'durMin');
  Result.DurationMinOriginal := JFloat(O, 'durMinOrig');
  Result.OperariosNecesarios := JInt(O, 'opNec');
  Result.OperariosAsignados := JInt(O, 'opAsig');
  Result.Estado := TNodoEstado(JInt(O, 'estado'));
  Result.Tipo := TNodoTipo(JInt(O, 'tipo'));
  Result.Prioridad := JInt(O, 'prioridad');
  Result.bkColorOp := TColor(JInt(O, 'bkColor'));
  Result.borderColorOp := TColor(JInt(O, 'bdColor'));
  Result.LibreMoviment := JBool(O, 'libreMov');
  Result.CentresPermesos := JToIntArray(O.Values['centresPerm'] as TJSONArray);
end;

function JsonToLink(O: TJSONObject): TErpLink;
begin
  Result := Default(TErpLink);
  Result.FromNodeId := JInt(O, 'from');
  Result.ToNodeId := JInt(O, 'to');
  Result.LinkType := TLinkType(JInt(O, 'type'));
  Result.PorcentajeDependencia := JFloat(O, 'pctDep');
end;

function JsonToAsig(O: TJSONObject): TAsignacionOperario;
begin
  Result := Default(TAsignacionOperario);
  Result.OperarioId := JInt(O, 'opId');
  Result.DataId := JInt(O, 'dataId');
  Result.Horas := JFloat(O, 'horas');
end;

function JsonToMarker(O: TJSONObject): TGanttMarker;
begin
  Result := Default(TGanttMarker);
  Result.Id := JInt(O, 'id');
  Result.DateTime := JToDate(O, 'dt');
  Result.Caption := JStr(O, 'caption');
  Result.Color := TColor(JInt(O, 'color'));
  Result.Visible := True;
end;

function DeserializePlan(const AJson: string): TPlanningData;
var
  Root: TJSONObject;
  Arr: TJSONArray;
  i, ver: Integer;
begin
  Result := Default(TPlanningData);
  Root := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  if Root = nil then
    raise Exception.Create('Snapshot JSON invalido.');
  try
    ver := JInt(Root, 'version', 0);
    if ver > SNAPSHOT_FORMAT_VERSION then
      raise Exception.CreateFmt(
        'Snapshot de version %d no soportada (maxima %d).',
        [ver, SNAPSHOT_FORMAT_VERSION]);
    Result.Project.ProjectId := JInt(Root, 'projectId');

    Arr := Root.Values['nodes'] as TJSONArray;
    if Arr <> nil then
    begin
      SetLength(Result.Nodes, Arr.Count);
      for i := 0 to Arr.Count - 1 do
        Result.Nodes[i] := JsonToNode(Arr.Items[i] as TJSONObject);
    end;

    Arr := Root.Values['nodeData'] as TJSONArray;
    if Arr <> nil then
    begin
      SetLength(Result.NodeDataList, Arr.Count);
      for i := 0 to Arr.Count - 1 do
        Result.NodeDataList[i] := JsonToNodeData(Arr.Items[i] as TJSONObject);
    end;

    Arr := Root.Values['links'] as TJSONArray;
    if Arr <> nil then
    begin
      SetLength(Result.Links, Arr.Count);
      for i := 0 to Arr.Count - 1 do
        Result.Links[i] := JsonToLink(Arr.Items[i] as TJSONObject);
    end;

    Arr := Root.Values['asignaciones'] as TJSONArray;
    if Arr <> nil then
    begin
      SetLength(Result.Asignaciones, Arr.Count);
      for i := 0 to Arr.Count - 1 do
        Result.Asignaciones[i] := JsonToAsig(Arr.Items[i] as TJSONObject);
    end;

    Arr := Root.Values['markers'] as TJSONArray;
    if Arr <> nil then
    begin
      SetLength(Result.Markers, Arr.Count);
      for i := 0 to Arr.Count - 1 do
        Result.Markers[i] := JsonToMarker(Arr.Items[i] as TJSONObject);
    end;
  finally
    Root.Free;
  end;
end;

end.
