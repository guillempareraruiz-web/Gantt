unit uGanttControlGrupo;

{
  TGanttControlGrupo - Control de Gantt con agrupación de filas por padre ERP.

  Hereda de TGanttControl (uGanttControl.pas) y solo sobreescribe RebuildLayout
  para que las filas sean los padres Nivel 1 (OF/PEDIDO/PROYECTO) o Nivel 2
  (OT/LINEA/TAREA) del modelo unificado FS_PL_Raw_Item, en lugar de centros
  de trabajo.

  Todo el resto (paint de barras, scroll, zoom, hit-test, drag, links, markers,
  FechaBloqueo, keyboard, clipboard...) lo aporta la clase base.

  NivelAgrupacion se fija al instanciar el control segun la configuracion del
  proyecto activo (FS_PL_Project.NivelAgrupacion, V017).
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.DateUtils,
  System.Math, System.Types,
  Vcl.Graphics, Vcl.Controls,
  uGanttControl, uGanttTypes;

type
  TGanttControlGrupo = class(TGanttControl)
  protected
    // Nivel de agrupacion: 1 (OF/PEDIDO/PROYECTO) o 2 (OT/LINEA/TAREA).
    FNivelAgrupacion: Integer;
    // Grupos detectados al construir el layout (paralelos a FRows).
    FGroupClaves: TArray<string>;
    FGroupCaptions: TArray<string>;

    // Resuelve clave y caption del grupo al que pertenece un nodo segun
    // FNivelAgrupacion. Devuelve False si no se pudo resolver.
    function ResolveNodeGroup(const ANodeIndex: Integer;
      out AClave, ACaption: string): Boolean;

    // Reordena un rango de FNodeLayouts por Rect.Left ascendente. Necesario
    // en modo GRUPO porque el packing con lanes dinamicas puede dejar Left
    // desordenado y el paint del padre asume orden creciente.
    procedure SortRowNodeLayoutsByLeft(AFirst, ALast: Integer);
  public
    constructor Create(AOwner: TComponent); override;

    // Sobreescribe el RebuildLayout del padre para agrupar por Nivel1/Nivel2
    // en lugar de por centro.
    procedure RebuildLayout; override;

    // En modo GRUPO el TRowLayout.CentreId es el indice del grupo, no un
    // centre real. El check por defecto del padre (IsCentreVisible) fallaria
    // y no se pintaria ninguna fila. Aqui lo forzamos a True si el indice
    // de fila es valido.
    function IsRowVisible(const ARowIndex: Integer): Boolean; override;

    function GetGroupClave(const ARowIndex: Integer): string;
    function GetGroupCaption(const ARowIndex: Integer): string;

    property NivelAgrupacion: Integer read FNivelAgrupacion write FNivelAgrupacion;
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

constructor TGanttControlGrupo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNivelAgrupacion := 1;
end;

function TGanttControlGrupo.ResolveNodeGroup(const ANodeIndex: Integer;
  out AClave, ACaption: string): Boolean;
var
  D: TNodeData;
begin
  AClave := '';
  ACaption := '';
  Result := False;

  if not TryGetNodeData(ANodeIndex, D) then
  begin
    AClave := '__NOGROUP__';
    ACaption := '(sin agrupar)';
    Exit(True);
  end;

  if FNivelAgrupacion = 2 then
  begin
    AClave := D.Nivel2ClaveERP;
    ACaption := D.Nivel2Caption;
  end
  else
  begin
    AClave := D.Nivel1ClaveERP;
    ACaption := D.Nivel1Caption;
  end;

  if AClave = '' then
  begin
    AClave := '__NOGROUP__';
    ACaption := '(sin agrupar)';
  end;
  Result := True;
end;

function TGanttControlGrupo.GetGroupClave(const ARowIndex: Integer): string;
begin
  if (ARowIndex >= 0) and (ARowIndex <= High(FGroupClaves)) then
    Result := FGroupClaves[ARowIndex]
  else
    Result := '';
end;

function TGanttControlGrupo.IsRowVisible(const ARowIndex: Integer): Boolean;
begin
  Result := (ARowIndex >= 0) and (ARowIndex <= High(FRows));
end;

procedure TGanttControlGrupo.SortRowNodeLayoutsByLeft(AFirst, ALast: Integer);
var
  Count, K: Integer;
  SubArr: TArray<TNodeLayout>;
begin
  // Nombre del metodo = por Left historicamente, pero ordenamos por Left
  // usando Right como desempate. El padre hace binary search sobre Right>=X,
  // por lo que necesitamos ambos monotonos; Left estara monotonous porque
  // los nodos se insertan por orden de StartTime, y con lanes dinamicas la
  // reordenacion final asegura invariantes del paint.
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

function TGanttControlGrupo.GetGroupCaption(const ARowIndex: Integer): string;
begin
  if (ARowIndex >= 0) and (ARowIndex <= High(FGroupCaptions)) then
    Result := FGroupCaptions[ARowIndex]
  else
    Result := '';
end;

procedure TGanttControlGrupo.RebuildLayout;
var
  i, gi: Integer;
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

  groupMap: TDictionary<string, Integer>;
  groupKeys, groupCaps: TArray<string>;
  groupNodes: TArray<TList<Integer>>;
  clave, caption: string;

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
  SetLength(FGroupClaves, 0);
  SetLength(FGroupCaptions, 0);

  y := RowTopMargin;
  maxEndTime := FStartTime;

  // ===== Paso 1: recolectar grupos a partir de los nodos =====
  groupMap := TDictionary<string, Integer>.Create;
  try
    SetLength(groupKeys, 0);
    SetLength(groupCaps, 0);
    SetLength(groupNodes, 0);

    for i := 0 to High(FNodes) do
    begin
      if not FNodes[i].Visible then Continue;
      if (FNodes[i].StartTime = 0) or (FNodes[i].EndTime = 0) then Continue;
      if not ResolveNodeGroup(i, clave, caption) then Continue;

      if not groupMap.TryGetValue(clave, gi) then
      begin
        gi := Length(groupKeys);
        SetLength(groupKeys, gi + 1);
        SetLength(groupCaps, gi + 1);
        SetLength(groupNodes, gi + 1);
        groupKeys[gi] := clave;
        groupCaps[gi] := caption;
        groupNodes[gi] := TList<Integer>.Create;
        groupMap.Add(clave, gi);
      end;
      groupNodes[gi].Add(i);
    end;

    FGroupClaves := groupKeys;
    FGroupCaptions := groupCaps;
  finally
    groupMap.Free;
  end;

  // ===== Paso 2: para cada grupo construir una fila con packing de lanes =====
  for gi := 0 to High(groupKeys) do
  begin
    idxs := groupNodes[gi].ToArray;
    groupNodes[gi].Free;

    if Length(idxs) > 1 then
      TArray.Sort<Integer>(idxs,
        TComparer<Integer>.Construct(
          function(const L, R: Integer): Integer
          begin
            Result := CompareDateTime(FNodes[L].StartTime, FNodes[R].StartTime);
            if Result = 0 then
              Result := CompareDateTime(FNodes[L].EndTime, FNodes[R].EndTime);
          end));

    // Lane count dinamico (decision 1b: sin limite, lanes segun necesidad)
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

    // Fila: CentreId se usa aqui como indice de grupo (el panel izquierdo
    // lo lee via GetGroupCaption).
    row.CentreId := gi;
    row.TopY := y;
    row.Height := rowH;
    row.LaneCount := laneCount;
    row.Order := gi;
    row.Visible := True;
    row.Enabled := True;
    row.bkColor := $00F5F5F5; // gris muy claro, no blanco puro (test visibilidad)
    row.NameRect := TRectF.Create(0, y, 0, y + rowH);
    row.GanttRect := TRectF.Create(0, y, 0, y + rowH);
    row.FirstNodeLayout := Length(FNodeLayouts);

    // Packing real de nodes con lanes dinamicas
    SetLength(laneRight, 0);
    for idx in idxs do
    begin
      node := FNodes[idx];
      if not node.Visible then Continue;

      laneIdx := TryFindLane(TimeToXWorld(node.StartTime));
      if laneIdx < 0 then
      begin
        laneIdx := Length(laneRight);
        SetLength(laneRight, laneIdx + 1);
        laneRight[laneIdx] := 0;
      end;

      nl.NodeIndex := idx;
      nl.CentreId := node.CentreId;  // preservamos el centre real del nodo
      nl.LaneIndex := laneIdx;
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
