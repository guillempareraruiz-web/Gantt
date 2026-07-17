unit uGanttControlOperarios;

{
  TGanttControlOperarios - Control de Gantt con las FILAS = operarios.

  Vista de CARGA DE PERSONAL: una fila por operario, las barras son las tareas
  (nodos) que tiene asignadas. Cierra el trio de recursos Centros/Maquinas/
  Operarios. Sirve para equilibrar la carga de las personas y ver de un vistazo
  quien esta sobrecargado.

  Mismo patron que TGanttControlUtillajes (relacion N:M: un nodo puede tener
  varios operarios asignados, por lo que aparece en varias filas). A diferencia
  de utillajes, la capacidad de un operario es SIEMPRE 1 (no puede hacer dos
  tareas a la vez): dos tareas solapadas en la misma fila = SOBRECARGA.

  Vista SOLO LECTURA (diagnostico): no se arrastran nodos. Reasignar operarios
  se hace en el panel/kanban de asignacion, no aqui.

  Los datos (que operario tiene cada nodo) se INYECTAN desde uVistaGantt via
  SetAsignaciones antes de SetData; el control no toca la BD.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.DateUtils,
  System.Math, System.Types,
  Vcl.Graphics, Vcl.Controls,
  uGanttControl, uGanttTypes;

type
  // Una asignacion plana: nodo (DataId) -> operario, con nombre para el rotulo.
  TAsignacionOperarioFila = record
    DataId: Integer;
    OperarioId: Integer;
    Nombre: string;
  end;

  TGanttControlOperarios = class(TGanttControl)
  protected
    FAsignaciones: TArray<TAsignacionOperarioFila>;

    // Metadatos por fila (paralelos a FRows).
    FRowOperarioId: TArray<Integer>;
    FRowNombre: TArray<string>;
    FRowSobrecarga: TArray<Boolean>;
    FRowNumNodos: TArray<Integer>;
    FRowMaxSolapes: TArray<Integer>;

    function BuildDataIdMap: TDictionary<Integer, TList<Integer>>;
    procedure SortRowNodeLayoutsByLeft(AFirst, ALast: Integer);
  public
    constructor Create(AOwner: TComponent); override;

    procedure SetAsignaciones(const AAsig: TArray<TAsignacionOperarioFila>);

    procedure RebuildLayout; override;
    function IsRowVisible(const ARowIndex: Integer): Boolean; override;

    // Solo lectura: corta el arranque de drag.
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;

    // Para el panel izquierdo.
    function GetRowCaption(const ARowIndex: Integer): string;   // nombre + (!) si sobrecarga
    function GetRowSubtitle(const ARowIndex: Integer): string;  // "N tareas"
    function GetRowCarga(const ARowIndex: Integer): string;     // "N tareas - pico M"
    function GetRowPanelColor(const ARowIndex: Integer): TColor;
    function RowTieneSobrecarga(const ARowIndex: Integer): Boolean;
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

  ROW_BK_NORMAL       = $00F5F5F5;
  ROW_BK_SOBRECARGA   = $00C0C0FF;  // rojo/rosa claro visible (BGR)

constructor TGanttControlOperarios.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

procedure TGanttControlOperarios.SetAsignaciones(
  const AAsig: TArray<TAsignacionOperarioFila>);
begin
  FAsignaciones := Copy(AAsig);
end;

function TGanttControlOperarios.IsRowVisible(const ARowIndex: Integer): Boolean;
begin
  Result := (ARowIndex >= 0) and (ARowIndex <= High(FRows));
end;

procedure TGanttControlOperarios.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if ssLeft in Shift then
  begin
    FMouseDownNodeIndex := -1;
    FMouseDownOnHandle := nhNone;
  end;
  inherited MouseMove(Shift, X, Y);
end;

function TGanttControlOperarios.RowTieneSobrecarga(const ARowIndex: Integer): Boolean;
begin
  Result := (ARowIndex >= 0) and (ARowIndex <= High(FRowSobrecarga))
    and FRowSobrecarga[ARowIndex];
end;

function TGanttControlOperarios.GetRowCaption(const ARowIndex: Integer): string;
begin
  Result := '';
  if (ARowIndex < 0) or (ARowIndex > High(FRowNombre)) then Exit;
  Result := FRowNombre[ARowIndex];
  if RowTieneSobrecarga(ARowIndex) then
    Result := Result + '  (!) SOBRECARGA';
end;

function TGanttControlOperarios.GetRowSubtitle(const ARowIndex: Integer): string;
begin
  // 2a linea: el propio nombre ya va en el caption; aqui la carga resumida.
  Result := GetRowCarga(ARowIndex);
end;

function TGanttControlOperarios.GetRowCarga(const ARowIndex: Integer): string;
var
  n, m: Integer;
begin
  Result := '';
  if (ARowIndex < 0) or (ARowIndex > High(FRowNumNodos)) then Exit;
  n := FRowNumNodos[ARowIndex];
  m := FRowMaxSolapes[ARowIndex];
  if m > 1 then
    Result := Format('%d tareas - hasta %d a la vez', [n, m])
  else
    Result := Format('%d tareas', [n]);
end;

function TGanttControlOperarios.GetRowPanelColor(const ARowIndex: Integer): TColor;
begin
  if RowTieneSobrecarga(ARowIndex) then
    Result := ROW_BK_SOBRECARGA
  else
    Result := clNone;
end;

function TGanttControlOperarios.BuildDataIdMap: TDictionary<Integer, TList<Integer>>;
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

procedure TGanttControlOperarios.SortRowNodeLayoutsByLeft(AFirst, ALast: Integer);
var
  Count, K: Integer;
  SubArr: TArray<TNodeLayout>;
begin
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

procedure TGanttControlOperarios.RebuildLayout;
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

  dataMap: TDictionary<Integer, TList<Integer>>;
  opMap: TDictionary<Integer, Integer>;     // OperarioId -> indice de fila
  opIds: TArray<Integer>;
  opNoms: TArray<string>;
  opNodes: TArray<TList<Integer>>;
  nodeList: TList<Integer>;
  sobrecarga: Boolean;
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
  SetLength(FRowOperarioId, 0);
  SetLength(FRowNombre, 0);
  SetLength(FRowSobrecarga, 0);
  SetLength(FRowNumNodos, 0);
  SetLength(FRowMaxSolapes, 0);

  y := RowTopMargin;

  // ===== Paso 1: mapa DataId -> node-index del control =====
  dataMap := BuildDataIdMap;
  opMap := TDictionary<Integer, Integer>.Create;
  try
    SetLength(opIds, 0);
    SetLength(opNoms, 0);
    SetLength(opNodes, 0);

    // ===== Paso 2: filas (operarios) y sus node-index desde las asignaciones =====
    for ri := 0 to High(FAsignaciones) do
    begin
      if not dataMap.TryGetValue(FAsignaciones[ri].DataId, nodeList) then Continue;

      if not opMap.TryGetValue(FAsignaciones[ri].OperarioId, gi) then
      begin
        gi := Length(opIds);
        SetLength(opIds, gi + 1);
        SetLength(opNoms, gi + 1);
        SetLength(opNodes, gi + 1);
        opIds[gi] := FAsignaciones[ri].OperarioId;
        if Trim(FAsignaciones[ri].Nombre) <> '' then
          opNoms[gi] := FAsignaciones[ri].Nombre
        else
          opNoms[gi] := 'Operario ' + IntToStr(FAsignaciones[ri].OperarioId);
        opNodes[gi] := TList<Integer>.Create;
        opMap.Add(FAsignaciones[ri].OperarioId, gi);
      end;

      for k := 0 to nodeList.Count - 1 do
      begin
        idx := nodeList[k];
        if not FNodes[idx].Visible then Continue;
        if (FNodes[idx].StartTime = 0) or (FNodes[idx].EndTime = 0) then Continue;
        opNodes[gi].Add(idx);
      end;
    end;
  finally
    for nodeList in dataMap.Values do
      nodeList.Free;
    dataMap.Free;
    opMap.Free;
  end;

  // ===== Paso 3: una fila por operario, con packing y deteccion de sobrecarga
  // (capacidad 1: cualquier solape = sobrecarga). =====
  for gi := 0 to High(opIds) do
  begin
    idxs := opNodes[gi].ToArray;
    opNodes[gi].Free;

    if Length(idxs) > 1 then
      TArray.Sort<Integer>(idxs,
        TComparer<Integer>.Construct(
          function(const L, R: Integer): Integer
          begin
            Result := CompareDateTime(FNodes[L].StartTime, FNodes[R].StartTime);
            if Result = 0 then
              Result := CompareDateTime(FNodes[L].EndTime, FNodes[R].EndTime);
          end));

    // Pico de solapes simultaneos. Capacidad de un operario = 1 -> pico > 1 es
    // sobrecarga (esta asignado a dos tareas a la vez).
    maxSolapes := 0;
    for ri := 0 to High(idxs) do
    begin
      k := 1;
      for idx := 0 to High(idxs) do
        if (idx <> ri)
           and (FNodes[idxs[idx]].StartTime < FNodes[idxs[ri]].EndTime)
           and (FNodes[idxs[idx]].EndTime > FNodes[idxs[ri]].StartTime) then
          Inc(k);
      if k > maxSolapes then maxSolapes := k;
    end;
    sobrecarga := maxSolapes > 1;

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

    SetLength(FRowOperarioId, gi + 1);
    SetLength(FRowNombre, gi + 1);
    SetLength(FRowSobrecarga, gi + 1);
    SetLength(FRowNumNodos, gi + 1);
    SetLength(FRowMaxSolapes, gi + 1);
    FRowOperarioId[gi] := opIds[gi];
    FRowNombre[gi] := opNoms[gi];
    FRowSobrecarga[gi] := sobrecarga;
    FRowNumNodos[gi] := Length(idxs);
    FRowMaxSolapes[gi] := maxSolapes;

    row.CentreId := gi;
    row.TopY := y;
    row.Height := rowH;
    row.LaneCount := laneCount;
    row.Order := gi;
    row.Visible := True;
    row.Enabled := True;
    if sobrecarga then row.bkColor := ROW_BK_SOBRECARGA
    else row.bkColor := ROW_BK_NORMAL;
    row.NameRect := TRectF.Create(0, y, 0, y + rowH);
    row.GanttRect := TRectF.Create(0, y, 0, y + rowH);
    row.FirstNodeLayout := Length(FNodeLayouts);

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
      nl.CentreId := node.CentreId;
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
    end;

    row.LastNodeLayout := Length(FNodeLayouts) - 1;
    SortRowNodeLayoutsByLeft(row.FirstNodeLayout, row.LastNodeLayout);
    AddRowLayout(row);

    y := y + rowH;
  end;

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
