unit uGanttControlUtillajes;

{
  TGanttControlUtillajes - Control de Gantt con las FILAS = utillajes.

  Hereda de TGanttControl (uGanttControl.pas), mismo patron que
  TGanttControlGrupo (fase 6.2, decision Z): solo sobreescribe RebuildLayout
  para que cada fila sea un UTILLAJE y las barras la ocupacion que ese utillaje
  recibe de los nodos que lo requieren, e IsRowVisible para pintar siempre.

  A diferencia de CENTROS/GRUPO, la relacion nodo->fila es N:M: un mismo nodo
  puede requerir varios utillajes, y por tanto aparece en varias filas (una
  barra por fila). El pipeline del padre lo admite porque los node-layouts se
  agregan por instancia, no por nodo unico; cada fila tiene su propio rango
  contiguo [FirstNodeLayout..LastNodeLayout].

  Vista de DIAGNOSTICO, READ-ONLY: sin drag ni edicion. Sirve para VER los
  conflictos de utillaje (que de otro modo solo se cuentan en la alerta R02).

  La entrada (que utillaje pide cada nodo, y la capacidad de cada utillaje) NO
  la lee este control de la BD: se la INYECTA uVistaGantt via SetRequisitos /
  SetCantidades antes de SetData, igual que el NivelAgrupacion del modo GRUPO.
  Asi el control queda sin dependencia de repos ni conexion.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.DateUtils,
  System.Math, System.Types,
  Vcl.Graphics, Vcl.Controls,
  uGanttControl, uGanttTypes, uUtillajeTypes;

type
  TGanttControlUtillajes = class(TGanttControl)
  protected
    // Requisitos inyectados: una fila por (NodeId=DataId, UtillajeId).
    FRequisitos: TArray<TUtillajeRequisitoNodo>;
    // Capacidad (ejemplares) de cada utillaje. UtillajeId -> Cantidad.
    FCantidades: TDictionary<Integer, Integer>;
    // Ficha maestra de cada utillaje (para el tooltip). UtillajeId -> TUtillaje.
    FFichas: TDictionary<Integer, TUtillaje>;

    // Metadatos de cada fila construida (paralelos a FRows).
    FRowUtillajeId: TArray<Integer>;
    FRowCodigo: TArray<string>;
    FRowConflicto: TArray<Boolean>;
    FRowCantidad: TArray<Integer>;   // capacidad (ejemplares) del utillaje
    FRowNumNodos: TArray<Integer>;   // nodos que usan el utillaje en esta fila
    FRowMaxSolapes: TArray<Integer>; // pico de solapes simultaneos

    // Indice DataId -> lista de node-index del control (varios node-index por
    // DataId si un nodo esta duplicado; en la practica 1:1). Se construye al
    // vuelo en RebuildLayout a partir de FNodes.
    function BuildDataIdMap: TDictionary<Integer, TList<Integer>>;

    function CantidadDe(AUtillajeId: Integer): Integer;

    procedure SortRowNodeLayoutsByLeft(AFirst, ALast: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Inyeccion de datos (llamar antes de SetData).
    procedure SetRequisitos(const AReqs: TArray<TUtillajeRequisitoNodo>);
    procedure SetCantidades(const AUtillajes: TArray<TUtillaje>);

    procedure RebuildLayout; override;

    // El TRowLayout.CentreId es aqui el indice de fila (utillaje), no un centre
    // real. El check por defecto del padre (IsCentreVisible) rechazaria todas
    // las filas y no se pintaria nada.
    function IsRowVisible(const ARowIndex: Integer): Boolean; override;

    // Vista SOLO LECTURA: se puede hacer scroll, panning, hover, seleccionar y
    // doble-clic (abrir ficha), pero NO arrastrar ni redimensionar nodos. Como
    // un nodo aparece en varias filas (N:M), moverlo aqui desincronizaria las
    // demas filas. Cortamos el drag anulando el nodo "pulsado" antes de que el
    // MouseMove del padre decida iniciar move/resize.
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;

    // Etiqueta del panel izquierdo: codigo del utillaje (+ marca de conflicto).
    function GetRowCaption(const ARowIndex: Integer): string;
    // 2a linea del panel: descripcion del utillaje (nombre legible).
    function GetRowSubtitle(const ARowIndex: Integer): string;
    // 3a linea del panel: carga "N nodos - pico M / C ejempl.".
    function GetRowCarga(const ARowIndex: Integer): string;
    function GetRowUtillajeId(const ARowIndex: Integer): Integer;
    function RowTieneConflicto(const ARowIndex: Integer): Boolean;
    // Color de fondo para el panel izquierdo (clNone = por defecto).
    function GetRowPanelColor(const ARowIndex: Integer): TColor;
    // Tooltip con la ficha del utillaje de la fila (datos maestros + situacion).
    function GetRowHint(const ARowIndex: Integer): string;
  end;

implementation

const
  RowGap = 6;
  RowTopMargin = 0;
  RowBottomMargin = 0;
  LaneGap = 4;
  NodeMinHeight = 24;
  GroupBaseHeight = 40;
  NODE_INNER_PAD_TOP = 5;
  NODE_INNER_PAD_BOTTOM = 5;

  // Fondo de fila: gris muy claro normal, rojo claro (pero visible) si la fila
  // tiene algun solape que supera la Cantidad del utillaje (conflicto real).
  // Color en formato BGR de TColor ($00BBGGRR).
  ROW_BK_NORMAL    = $00F5F5F5;
  ROW_BK_CONFLICTO = $00C0C0FF;  // rojo/rosa claro bien visible (R=255,G=192,B=192)

constructor TGanttControlUtillajes.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCantidades := TDictionary<Integer, Integer>.Create;
  FFichas := TDictionary<Integer, TUtillaje>.Create;
end;

destructor TGanttControlUtillajes.Destroy;
begin
  FFichas.Free;
  FCantidades.Free;
  inherited;
end;

procedure TGanttControlUtillajes.SetRequisitos(
  const AReqs: TArray<TUtillajeRequisitoNodo>);
begin
  FRequisitos := Copy(AReqs);
end;

procedure TGanttControlUtillajes.SetCantidades(
  const AUtillajes: TArray<TUtillaje>);
var
  I: Integer;
begin
  FCantidades.Clear;
  FFichas.Clear;
  for I := 0 to High(AUtillajes) do
  begin
    FCantidades.AddOrSetValue(AUtillajes[I].Id, Max(1, AUtillajes[I].Cantidad));
    FFichas.AddOrSetValue(AUtillajes[I].Id, AUtillajes[I]);
  end;
end;

function TGanttControlUtillajes.CantidadDe(AUtillajeId: Integer): Integer;
begin
  if not FCantidades.TryGetValue(AUtillajeId, Result) then Result := 1;
  if Result < 1 then Result := 1;
end;

function TGanttControlUtillajes.IsRowVisible(const ARowIndex: Integer): Boolean;
begin
  Result := (ARowIndex >= 0) and (ARowIndex <= High(FRows));
end;

procedure TGanttControlUtillajes.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  // Antes de que el padre pueda arrancar un move/resize (lo hace cuando el
  // boton izquierdo esta pulsado y hay un nodo "pulsado"), anulamos el nodo
  // pulsado y su handle. Asi el drag nunca empieza; el resto (hover, cursor,
  // panning con boton central) sigue funcionando via inherited.
  if ssLeft in Shift then
  begin
    FMouseDownNodeIndex := -1;
    FMouseDownOnHandle := nhNone;
  end;
  inherited MouseMove(Shift, X, Y);
end;

function TGanttControlUtillajes.GetRowCaption(const ARowIndex: Integer): string;
begin
  if (ARowIndex >= 0) and (ARowIndex <= High(FRowCodigo)) then
  begin
    Result := FRowCodigo[ARowIndex];
    // Capacidad entre parentesis: "DEMO-MOR-80 (x1)". Ayuda a leer el conflicto
    // (1 ejemplar = uso exclusivo; N = hasta N a la vez).
    if (ARowIndex <= High(FRowCantidad)) and (FRowCantidad[ARowIndex] > 0) then
      Result := Result + ' (x' + IntToStr(FRowCantidad[ARowIndex]) + ')';
    if (ARowIndex <= High(FRowConflicto)) and FRowConflicto[ARowIndex] then
      Result := Result + '  (!) CONFLICTO';
  end
  else
    Result := '';
end;

function TGanttControlUtillajes.GetRowSubtitle(const ARowIndex: Integer): string;
var
  U: TUtillaje;
begin
  // 2a linea: descripcion del utillaje (nombre legible). Si no hay ficha o
  // descripcion, cae a la carga para no dejar la linea vacia.
  Result := '';
  if (ARowIndex < 0) or (ARowIndex > High(FRowUtillajeId)) then Exit;
  if FFichas.TryGetValue(FRowUtillajeId[ARowIndex], U) and (Trim(U.Descripcion) <> '') then
    Result := U.Descripcion
  else
    Result := GetRowCarga(ARowIndex);
end;

function TGanttControlUtillajes.GetRowCarga(const ARowIndex: Integer): string;
var
  n, m, c: Integer;
begin
  Result := '';
  if (ARowIndex < 0) or (ARowIndex > High(FRowNumNodos)) then Exit;
  n := FRowNumNodos[ARowIndex];
  m := FRowMaxSolapes[ARowIndex];
  c := FRowCantidad[ARowIndex];
  // "12 nodos - pico 3 / 1 ejempl." -> lectura directa del conflicto.
  Result := IntToStr(n) + ' nodos - pico ' + IntToStr(m) + ' / ' +
    IntToStr(c) + ' ejempl.';
end;

function TGanttControlUtillajes.GetRowPanelColor(const ARowIndex: Integer): TColor;
begin
  if (ARowIndex >= 0) and (ARowIndex <= High(FRowConflicto))
     and FRowConflicto[ARowIndex] then
    Result := ROW_BK_CONFLICTO
  else
    Result := clNone;
end;

function TGanttControlUtillajes.GetRowHint(const ARowIndex: Integer): string;
var
  U: TUtillaje;
  Lines: TStringList;
begin
  Result := '';
  if (ARowIndex < 0) or (ARowIndex > High(FRowUtillajeId)) then Exit;
  if not FFichas.TryGetValue(FRowUtillajeId[ARowIndex], U) then
  begin
    // Sin ficha maestra: al menos el codigo y la carga.
    Result := FRowCodigo[ARowIndex] + sLineBreak + GetRowCarga(ARowIndex);
    Exit;
  end;

  Lines := TStringList.Create;
  try
    Lines.Add(U.Codigo + '  -  ' + U.Descripcion);
    Lines.Add('');
    if Trim(U.Tipo) <> '' then
      Lines.Add('Tipo: ' + U.Tipo);
    Lines.Add('Estado: ' + EstadoUtillajeToStr(U.Estado));
    Lines.Add('Ejemplares (capacidad): ' + IntToStr(U.Cantidad));
    if Trim(U.Fabricante) <> '' then
      Lines.Add('Fabricante: ' + U.Fabricante);
    if Trim(U.NumeroSerie) <> '' then
      Lines.Add('N'#186' serie: ' + U.NumeroSerie);
    if Trim(U.Ubicacion) <> '' then
      Lines.Add('Ubicaci'#243'n: ' + U.Ubicacion);

    // Vida util (solo si esta controlada).
    if U.VidaUtilTotal > 0 then
      Lines.Add(Format('Vida '#250'til: %d / %d %s (%.0f%%)',
        [U.ContadorActual, U.VidaUtilTotal, UnidadVidaToStr(U.UnidadVida),
         PorcentajeVidaConsumida(U)]));

    // Tiempos de cambio (si alguno esta informado).
    if (U.TiempoMontaje > 0) or (U.TiempoDesmontaje > 0) or (U.TiempoAjuste > 0) then
      Lines.Add(Format('Cambio: montaje %.0f / desmontaje %.0f / ajuste %.0f min',
        [U.TiempoMontaje, U.TiempoDesmontaje, U.TiempoAjuste]));

    if not U.DisponiblePlanificacion then
      Lines.Add('(!) No disponible para planificar');

    Lines.Add('');
    // Carga en el plan actual + marca de conflicto.
    Lines.Add('En el plan: ' + GetRowCarga(ARowIndex));
    if (ARowIndex <= High(FRowConflicto)) and FRowConflicto[ARowIndex] then
      Lines.Add('(!) CONFLICTO: mas trabajos solapados que ejemplares.');

    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function TGanttControlUtillajes.GetRowUtillajeId(const ARowIndex: Integer): Integer;
begin
  if (ARowIndex >= 0) and (ARowIndex <= High(FRowUtillajeId)) then
    Result := FRowUtillajeId[ARowIndex]
  else
    Result := 0;
end;

function TGanttControlUtillajes.RowTieneConflicto(const ARowIndex: Integer): Boolean;
begin
  Result := (ARowIndex >= 0) and (ARowIndex <= High(FRowConflicto))
    and FRowConflicto[ARowIndex];
end;

function TGanttControlUtillajes.BuildDataIdMap: TDictionary<Integer, TList<Integer>>;
var
  i, dataId: Integer;
  list: TList<Integer>;
begin
  Result := TDictionary<Integer, TList<Integer>>.Create;
  for i := 0 to High(FNodes) do
  begin
    dataId := FNodes[i].DataId;
    if dataId = 0 then Continue;
    if not Result.TryGetValue(dataId, list) then
    begin
      list := TList<Integer>.Create;
      Result.Add(dataId, list);
    end;
    list.Add(i);
  end;
end;

procedure TGanttControlUtillajes.SortRowNodeLayoutsByLeft(AFirst, ALast: Integer);
var
  Count, K: Integer;
  SubArr: TArray<TNodeLayout>;
begin
  // El hit-test y el paint del padre asumen Rect.Left monotono creciente dentro
  // de la fila (mismo requisito que en TGanttControlGrupo).
  if ALast <= AFirst then Exit;
  Count := ALast - AFirst + 1;
  SetLength(SubArr, Count);
  for K := 0 to Count - 1 do
    SubArr[K] := FNodeLayouts[AFirst + K];
  TArray.Sort<TNodeLayout>(SubArr,
    TComparer<TNodeLayout>.Construct(
      function(const L, R: TNodeLayout): Integer
      begin
        if L.Rect.Left < R.Rect.Left then Result := -1
        else if L.Rect.Left > R.Rect.Left then Result := 1
        else if L.Rect.Right < R.Rect.Right then Result := -1
        else if L.Rect.Right > R.Rect.Right then Result := 1
        else Result := 0;
      end));
  for K := 0 to Count - 1 do
    FNodeLayouts[AFirst + K] := SubArr[K];
end;

procedure TGanttControlUtillajes.RebuildLayout;
var
  ri, gi, k: Integer;
  row: TRowLayout;
  idxs: TArray<Integer>;
  idx: Integer;
  y: Single;
  laneCount, laneIdx: Integer;
  laneH, rowH: Single;
  laneRight: TArray<Single>;
  node: TNode;
  nl: TNodeLayout;
  maxEndTime: TDateTime;

  dataMap: TDictionary<Integer, TList<Integer>>;
  utilMap: TDictionary<Integer, Integer>;     // UtillajeId -> indice de fila
  utilIds: TArray<Integer>;
  utilCods: TArray<string>;
  utilNodes: TArray<TList<Integer>>;           // por fila: node-index del control
  nodeList: TList<Integer>;
  cap: Integer;
  conflicto: Boolean;
  maxSolapes: Integer;

  function TimeToXWorld(const T: TDateTime): Single;
  begin
    Result := VisibleMinutesBetween(FStartTime, T) * FPxPerMinute;
  end;

  function TryFindLane(const xLeft: Single): Integer;
  var
    l: Integer;
  begin
    for l := 0 to High(laneRight) do
      if laneRight[l] <= xLeft then
        Exit(l);
    Result := -1;
  end;

begin
  SetLength(FRows, 0);
  SetLength(FNodeLayouts, 0);
  SetLength(FRowUtillajeId, 0);
  SetLength(FRowCodigo, 0);
  SetLength(FRowConflicto, 0);
  SetLength(FRowCantidad, 0);
  SetLength(FRowNumNodos, 0);
  SetLength(FRowMaxSolapes, 0);

  y := RowTopMargin;
  maxEndTime := FStartTime;

  // ===== Paso 1: mapear DataId -> node-index del control =====
  dataMap := BuildDataIdMap;
  utilMap := TDictionary<Integer, Integer>.Create;
  try
    SetLength(utilIds, 0);
    SetLength(utilCods, 0);
    SetLength(utilNodes, 0);

    // ===== Paso 2: recolectar filas (utillajes) y sus node-index a partir de
    // los requisitos inyectados. Un requisito = (DataId de nodo, UtillajeId). =====
    for ri := 0 to High(FRequisitos) do
    begin
      if not dataMap.TryGetValue(FRequisitos[ri].NodeId, nodeList) then Continue;

      if not utilMap.TryGetValue(FRequisitos[ri].Req.UtillajeId, gi) then
      begin
        gi := Length(utilIds);
        SetLength(utilIds, gi + 1);
        SetLength(utilCods, gi + 1);
        SetLength(utilNodes, gi + 1);
        utilIds[gi] := FRequisitos[ri].Req.UtillajeId;
        utilCods[gi] := FRequisitos[ri].Req.Codigo;
        utilNodes[gi] := TList<Integer>.Create;
        utilMap.Add(FRequisitos[ri].Req.UtillajeId, gi);
      end;

      // Cada node-index (normalmente 1 por DataId) que use este utillaje.
      for k := 0 to nodeList.Count - 1 do
      begin
        idx := nodeList[k];
        if not FNodes[idx].Visible then Continue;
        if (FNodes[idx].StartTime = 0) or (FNodes[idx].EndTime = 0) then Continue;
        utilNodes[gi].Add(idx);
      end;
    end;
  finally
    // dataMap: liberar sus listas.
    for nodeList in dataMap.Values do
      nodeList.Free;
    dataMap.Free;
    utilMap.Free;
  end;

  // ===== Paso 3: una fila por utillaje, con packing de lanes y deteccion de
  // conflicto (solapes simultaneos > Cantidad). =====
  for gi := 0 to High(utilIds) do
  begin
    idxs := utilNodes[gi].ToArray;
    utilNodes[gi].Free;
    cap := CantidadDe(utilIds[gi]);

    if Length(idxs) > 1 then
      TArray.Sort<Integer>(idxs,
        TComparer<Integer>.Construct(
          function(const L, R: Integer): Integer
          begin
            Result := CompareDateTime(FNodes[L].StartTime, FNodes[R].StartTime);
            if Result = 0 then
              Result := CompareDateTime(FNodes[L].EndTime, FNodes[R].EndTime);
          end));

    // Pico de solapes simultaneos: para cada nodo, cuantos otros lo solapan
    // (contando el propio). El maximo es el pico. Conflicto si pico > Cantidad.
    maxSolapes := 0;
    for ri := 0 to High(idxs) do
    begin
      k := 1;  // el propio nodo
      for idx := 0 to High(idxs) do
        if (idx <> ri)
           and (FNodes[idxs[idx]].StartTime < FNodes[idxs[ri]].EndTime)
           and (FNodes[idxs[idx]].EndTime > FNodes[idxs[ri]].StartTime) then
          Inc(k);
      if k > maxSolapes then maxSolapes := k;
    end;
    conflicto := maxSolapes > cap;

    // Lane count dinamico (igual que GRUPO): lanes segun necesidad de packing.
    SetLength(laneRight, 0);
    for idx in idxs do
    begin
      node := FNodes[idx];
      laneIdx := TryFindLane(TimeToXWorld(node.StartTime));
      if laneIdx < 0 then
      begin
        laneIdx := Length(laneRight);
        SetLength(laneRight, laneIdx + 1);
        laneRight[laneIdx] := 0;
      end;
      laneRight[laneIdx] := TimeToXWorld(node.EndTime);
    end;
    laneCount := Max(1, Length(laneRight));

    laneH := Max(NodeMinHeight, (GroupBaseHeight - (laneCount - 1) * LaneGap) / laneCount);
    rowH := (laneCount * laneH) + ((laneCount - 1) * LaneGap) + NODE_INNER_PAD_TOP + NODE_INNER_PAD_BOTTOM;
    if laneCount <= 1 then
      rowH := GroupBaseHeight + RowGap;

    // Metadatos de la fila (paralelos a FRows).
    SetLength(FRowUtillajeId, gi + 1);
    SetLength(FRowCodigo, gi + 1);
    SetLength(FRowConflicto, gi + 1);
    SetLength(FRowCantidad, gi + 1);
    SetLength(FRowNumNodos, gi + 1);
    SetLength(FRowMaxSolapes, gi + 1);
    FRowUtillajeId[gi] := utilIds[gi];
    FRowCodigo[gi] := utilCods[gi];
    FRowConflicto[gi] := conflicto;
    FRowCantidad[gi] := cap;
    FRowNumNodos[gi] := Length(idxs);
    FRowMaxSolapes[gi] := maxSolapes;

    // CentreId = indice de fila (el panel izquierdo lo lee via GetRowCaption).
    row.CentreId := gi;
    row.TopY := y;
    row.Height := rowH;
    row.LaneCount := laneCount;
    row.Order := gi;
    row.Visible := True;
    row.Enabled := True;
    if conflicto then row.bkColor := ROW_BK_CONFLICTO
    else row.bkColor := ROW_BK_NORMAL;
    row.NameRect := TRectF.Create(0, y, 0, y + rowH);
    row.GanttRect := TRectF.Create(0, y, 0, y + rowH);
    row.FirstNodeLayout := Length(FNodeLayouts);

    // Packing real de node-layouts.
    SetLength(laneRight, 0);
    for idx in idxs do
    begin
      node := FNodes[idx];

      laneIdx := TryFindLane(TimeToXWorld(node.StartTime));
      if laneIdx < 0 then
      begin
        laneIdx := Length(laneRight);
        SetLength(laneRight, laneIdx + 1);
        laneRight[laneIdx] := 0;
      end;

      nl.NodeIndex := idx;
      nl.CentreId := node.CentreId;   // centre real del nodo (para hit-test)
      nl.LaneIndex := laneIdx;
      nl.LoteId := 0;
      nl.LoteCount := 0;
      nl.Rect := TRectF.Create(
        TimeToXWorld(node.StartTime),
        y + NODE_INNER_PAD_TOP + laneIdx * (laneH + LaneGap),
        TimeToXWorld(node.EndTime),
        y + NODE_INNER_PAD_TOP + laneIdx * (laneH + LaneGap) + laneH
      );
      nl.Rect.Bottom := nl.Rect.Top + NodeMinHeight;

      AddNodeLayout(nl);
      laneRight[laneIdx] := TimeToXWorld(node.EndTime);

      if node.EndTime > maxEndTime then
        maxEndTime := node.EndTime;
    end;

    row.LastNodeLayout := Length(FNodeLayouts) - 1;
    SortRowNodeLayoutsByLeft(row.FirstNodeLayout, row.LastNodeLayout);
    AddRowLayout(row);

    y := y + rowH;
  end;

  // ===== Content size (igual al padre) =====
  FContentHeight := Round(y + RowBottomMargin);
  FContentWidth := Round(((FEndTime - FStartTime) * 24 * 60) * FPxPerMinute);
  if FContentWidth < ClientWidth then
    FContentWidth := ClientWidth;
  if FContentHeight < ClientHeight then
    FContentHeight := ClientHeight;

  UpdateScrollBars;

  if Assigned(FOnLayoutChanged) then
    FOnLayoutChanged(Self);
end;

end.
