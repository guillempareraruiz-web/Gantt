unit uGanttControlTareas;

{
  TGanttControlTareas - Control de Gantt del Modulo de Proyectos (estilo MS
  Project). FILAS = tareas de la WBS, en orden de arbol (padre antes que hijos,
  respetando el plegado del acordeon). Una fila por tarea visible.

  Hereda de TGanttControl (mismo patron que Utillajes/Operarios): las tareas son
  nodos de FS_PL_Node, asi que se cargan como TNode normales; lo que cambia es
  el ORDEN de las filas (WBS, no por centro) y el pintado de resumen/hito.

  Fase 1: SOLO LECTURA (esqueleto). El orden y los metadatos de cada tarea
  (nivel, tipo, plegado) se INYECTAN desde uVistaProyectos via SetOrden antes de
  SetData; el control no toca la BD.

  El motor de fechas (mover tarea -> propagar por dependencias) es Fase 2; aqui
  las barras se pintan tal cual vienen.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.DateUtils,
  System.Math, System.Types,
  Vcl.Graphics, Vcl.Controls,
  uGanttControl, uGanttTypes, uWbsTypes;

type
  // Metadatos de orden/jerarquia de una tarea, inyectados por la vista.
  TWbsRowInfo = record
    NodeId: Integer;
    Kind: TWbsTaskKind;
    Nivel: Integer;
    Visible: Boolean;   // False si esta bajo una rama plegada
  end;
  TWbsRowInfoArray = TArray<TWbsRowInfo>;

  TGanttControlTareas = class(TGanttControl)
  protected
    FOrden: TWbsRowInfoArray;                 // orden WBS inyectado
    FKindPorNode: TDictionary<Integer, TWbsTaskKind>;
    FRowNodeId: TArray<Integer>;              // NodeId por fila (paralelo a FRows)

    function BuildDataIdMap: TDictionary<Integer, Integer>;  // NodeId -> index en FNodes
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetOrden(const AOrden: TWbsRowInfoArray);

    procedure RebuildLayout; override;
    function IsRowVisible(const ARowIndex: Integer): Boolean; override;

    // Solo lectura: sin drag (Fase 1).
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;

    function GetRowNodeId(const ARowIndex: Integer): Integer;
  end;

implementation

const
  RowGap = 4;
  RowTopMargin = 0;
  RowBottomMargin = 0;
  RowHeight = 26;
  NODE_INNER_PAD_TOP = 5;

  // Colores por tipo de barra (BGR de TColor).
  COL_TAREA   = $00E0873A;   // azul acero
  COL_RESUMEN = $00504636;   // gris oscuro (barra contenedora)
  COL_HITO    = $00D65F1F;   // acento

constructor TGanttControlTareas.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FKindPorNode := TDictionary<Integer, TWbsTaskKind>.Create;
end;

destructor TGanttControlTareas.Destroy;
begin
  FKindPorNode.Free;
  inherited;
end;

procedure TGanttControlTareas.SetOrden(const AOrden: TWbsRowInfoArray);
var
  I: Integer;
begin
  FOrden := Copy(AOrden);
  FKindPorNode.Clear;
  for I := 0 to High(AOrden) do
    FKindPorNode.AddOrSetValue(AOrden[I].NodeId, AOrden[I].Kind);
end;

function TGanttControlTareas.IsRowVisible(const ARowIndex: Integer): Boolean;
begin
  Result := (ARowIndex >= 0) and (ARowIndex <= High(FRows));
end;

procedure TGanttControlTareas.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  // Fase 1 read-only: cortar el arranque de drag.
  if ssLeft in Shift then
  begin
    FMouseDownNodeIndex := -1;
    FMouseDownOnHandle := nhNone;
  end;
  inherited MouseMove(Shift, X, Y);
end;

function TGanttControlTareas.GetRowNodeId(const ARowIndex: Integer): Integer;
begin
  if (ARowIndex >= 0) and (ARowIndex <= High(FRowNodeId)) then
    Result := FRowNodeId[ARowIndex]
  else
    Result := 0;
end;

function TGanttControlTareas.BuildDataIdMap: TDictionary<Integer, Integer>;
var
  i: Integer;
begin
  // NodeId del TNode -> su indice en FNodes. En este control cada tarea es un
  // TNode con Id = NodeId (lo carga la vista via SetData).
  Result := TDictionary<Integer, Integer>.Create;
  for i := 0 to High(FNodes) do
    Result.AddOrSetValue(FNodes[i].Id, i);
end;

procedure TGanttControlTareas.RebuildLayout;
var
  i, nodeIdx: Integer;
  row: TRowLayout;
  nl: TNodeLayout;
  y: Single;
  node: TNode;
  nodeById: TDictionary<Integer, Integer>;

  function TimeToXWorld(const T: TDateTime): Single;
  begin
    Result := VisibleMinutesBetween(FStartTime, T) * FPxPerMinute;
  end;

begin
  SetLength(FRows, 0);
  SetLength(FNodeLayouts, 0);
  SetLength(FRowNodeId, 0);

  y := RowTopMargin;
  nodeById := BuildDataIdMap;
  try
    // Una fila por tarea VISIBLE, en el orden WBS inyectado.
    for i := 0 to High(FOrden) do
    begin
      if not FOrden[i].Visible then Continue;
      if not nodeById.TryGetValue(FOrden[i].NodeId, nodeIdx) then Continue;
      node := FNodes[nodeIdx];

      SetLength(FRowNodeId, Length(FRowNodeId) + 1);
      FRowNodeId[High(FRowNodeId)] := FOrden[i].NodeId;

      row.CentreId := Length(FRows);       // indice de fila (no centre real)
      row.TopY := y;
      row.Height := RowHeight + RowGap;
      row.LaneCount := 1;
      row.Order := Length(FRows);
      row.Visible := True;
      row.Enabled := True;
      row.bkColor := $00F7F7F7;
      row.NameRect := TRectF.Create(0, y, 0, y + row.Height);
      row.GanttRect := TRectF.Create(0, y, 0, y + row.Height);
      row.FirstNodeLayout := Length(FNodeLayouts);

      // Barra de la tarea. Hito (duracion 0) = cuadradito centrado; resumen y
      // tarea = barra normal (el pintado especial de resumen/hito es Fase 1.b).
      if (node.StartTime <> 0) and (node.EndTime <> 0) then
      begin
        nl.NodeIndex := nodeIdx;
        nl.CentreId := node.CentreId;
        nl.LaneIndex := 0;
        nl.LoteId := 0;
        nl.LoteCount := 0;
        if FOrden[i].Kind = wtkHito then
          // Hito: un cuadradito de ~14px en el inicio.
          nl.Rect := TRectF.Create(
            TimeToXWorld(node.StartTime) - 7,
            y + NODE_INNER_PAD_TOP,
            TimeToXWorld(node.StartTime) + 7,
            y + NODE_INNER_PAD_TOP + 14)
        else
          nl.Rect := TRectF.Create(
            TimeToXWorld(node.StartTime),
            y + NODE_INNER_PAD_TOP,
            TimeToXWorld(node.EndTime),
            y + NODE_INNER_PAD_TOP + 16);
        AddNodeLayout(nl);
      end;

      row.LastNodeLayout := Length(FNodeLayouts) - 1;
      AddRowLayout(row);
      y := y + row.Height;
    end;
  finally
    nodeById.Free;
  end;

  FContentHeight := Round(y + RowBottomMargin);
  FContentWidth := Round(((FEndTime - FStartTime) * 24 * 60) * FPxPerMinute);
  if FContentWidth < ClientWidth then FContentWidth := ClientWidth;
  if FContentHeight < ClientHeight then FContentHeight := ClientHeight;

  UpdateScrollBars;
  if Assigned(FOnLayoutChanged) then FOnLayoutChanged(Self);
end;

end.
