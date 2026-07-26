unit uGanttControlMaquinas;

{
  TGanttControlMaquinas - RowMode MAQUINAS (V083).

  FILAS = maquinas. Cada nodo aparece en la fila de la maquina donde esta
  planificado (FS_PL_Node.MaquinaId). Es la vista natural del plan una vez el
  motor planifica a maquina y no a centro: responde a "que hace cada maquina y
  cuando", que es lo que mira el jefe de taller.

  A diferencia de UTILLAJES (N:M, un nodo puede estar en varias filas), aqui la
  relacion es 1:N -- un nodo esta en UNA maquina -- asi que el reparto es
  directo y no hace falta indice DataId -> filas.

  Las maquinas se agrupan POR CENTRO en la ordenacion: primero todas las de un
  centro, luego las del siguiente. Asi la vista sigue leyendose como el taller
  esta organizado, en vez de mezclar tornos con prensas.

  Los nodos sin maquina asignada (planes anteriores a V083, o creados a mano)
  caen en la fila de la maquina por defecto de su centro; si tampoco se puede
  resolver, en una fila "Sin asignar" al final. Nunca se pierden.

  VISTA EDITABLE, como CENTROS -- y a diferencia de UTILLAJES/GRUPO/CLIENTES.
  El motivo es que aqui una FILA ES UN RECURSO FINITO REAL y la relacion es 1:N:
  cada nodo esta en UNA sola fila, asi que arrastrarlo tiene un significado
  unico y sin ambiguedad (moverlo en el tiempo, o cambiarlo de maquina).

  En las vistas de agrupacion no pasa eso: en UTILLAJES un nodo aparece en
  VARIAS filas (N:M) y moverlo en una desincronizaria las demas; en GRUPO o
  CLIENTES la fila no es un recurso, es una etiqueta, y "mover a otra fila" no
  significaria nada planificable.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.DateUtils,
  System.Math, System.Types,
  Vcl.Graphics, Vcl.Controls,
  uGanttControl, uGanttTypes;

type
  // Una maquina, tal como la inyecta la vista antes de SetData.
  TMaquinaFila = record
    MaquinaId: Integer;
    Codigo: string;
    Nombre: string;
    CentroCodigo: string;    // para agrupar y para el subtitulo
    CentroId: Integer;
    EsSistema: Boolean;      // maquina por defecto del centro (__SINMAQUINA__)
  end;
  TMaquinaFilaArray = TArray<TMaquinaFila>;

  // Nodo -> maquina donde esta planificado. Una entrada por nodo.
  TNodoMaquina = record
    DataId: Integer;
    MaquinaId: Integer;
  end;
  TNodoMaquinaArray = TArray<TNodoMaquina>;

  TGanttControlMaquinas = class(TGanttControl)
  protected
    FMaquinas: TMaquinaFilaArray;
    FNodoMaquina: TNodoMaquinaArray;

    // Metadatos por fila (paralelos a FRows).
    FRowMaquinaId: TArray<Integer>;
    FRowCodigo: TArray<string>;
    FRowNombre: TArray<string>;
    FRowCentro: TArray<string>;
    FRowEsSistema: TArray<Boolean>;
    FRowNumNodos: TArray<Integer>;
    FRowMinutos: TArray<Double>;      // carga total planificada, en minutos
    FRowSolapes: TArray<Integer>;     // pico de nodos simultaneos en la maquina

    procedure SortRowNodeLayoutsByLeft(AFirst, ALast: Integer);
    // Indice de la fila que hay bajo ScreenY (-1 si ninguna).
    function FilaBajoY(const ScreenY: Integer): Integer;
    // Anota (o actualiza) en que maquina esta un nodo, en el mapa que usa
    // RebuildLayout para repartir las filas.
    procedure ApuntarEnMapa(ADataId, AMaquinaId: Integer);
    // Indice de la fila que muestra una maquina (-1 si no se muestra).
    function FilaDeMaquina(AMaquinaId: Integer): Integer;
  public
    constructor Create(AOwner: TComponent); override;

    // Inyeccion de datos (llamar ANTES de SetData). El control no toca BD.
    procedure SetMaquinas(const AMaquinas: TMaquinaFilaArray);
    procedure SetNodoMaquina(const AMapa: TNodoMaquinaArray);

    procedure RebuildLayout; override;

    // TRowLayout.CentreId es aqui el INDICE DE FILA (maquina), no un centre
    // real: el chequeo del padre rechazaria todas las filas y no se pintaria
    // nada. Mismo truco que GRUPO/UTILLAJES.
    function IsRowVisible(const ARowIndex: Integer): Boolean; override;

    // NO se sobreescribe MouseMove: a diferencia de UTILLAJES/GRUPO/CLIENTES,
    // aqui el drag SI vale (ver cabecera de la unidad), asi que se deja el del
    // padre tal cual.

    // OBLIGATORIO al ser editable: en este control TRowLayout.CentreId guarda
    // el INDICE DE FILA (maquina), no un centre. El padre usa esa funcion para
    // saber a que centre va el nodo al soltarlo; sin traducir, se escribiria un
    // CentreId que no existe y el nodo desapareceria del plan.
    function CentreIdFromScreenY(const ScreenY: Integer): Integer; override;

    // Maquina de la fila que hay bajo ScreenY (0 si no se puede resolver).
    function MaquinaIdFromScreenY(const ScreenY: Integer): Integer;

    // El fantasma del drag pregunta "a que altura esta la fila de este centre".
    // Aqui la fila no es un centre sino una MAQUINA, asi que hay que resolverla
    // por la maquina que hay bajo el raton; si no, no encuentra fila y el nodo
    // en movimiento no se pinta hasta soltarlo.
    function RowTopYByCentreId(const CentreId: Integer): Single; override;

    // Soltar el nodo en otra fila = cambiarlo de maquina. Se escribe en el
    // modelo aqui; el auto-save lo persiste con las fechas (SaveNodePositions).
    function AjustarNodoTrasMover(const ANodeIdx, AScreenY: Integer): Boolean; override;
    // Miembro de lote que ha seguido al nodo arrastrado: sincronizar tambien su
    // fila, o el lote se veria partido entre dos maquinas.
    procedure NodoSeguidoAOtro(const ANodeIdx, AOrigenIdx: Integer); override;

    // Panel izquierdo: 3 lineas.
    function GetRowCaption(const ARowIndex: Integer): string;    // codigo
    function GetRowSubtitle(const ARowIndex: Integer): string;   // nombre
    function GetRowCarga(const ARowIndex: Integer): string;      // carga
    function GetRowMaquinaId(const ARowIndex: Integer): Integer;
    // Capacidad de la maquina: cuantos trabajos admite a la vez (MaxLanes del
    // centre, V083). El panel izquierdo lo pinta como circulo indicador.
    function GetRowCapacidad(const ARowIndex: Integer): Integer;
    function GetRowHint(const ARowIndex: Integer): string;
  end;

implementation

const
  // Metricas de layout. Se declaran AQUI, como hacen todos los controles
  // hermanos (uGanttControlGrupo, Operarios, Utillajes): en TGanttControl son
  // constantes LOCALES de su RebuildLayout, no miembros de la clase, asi que no
  // se heredan.
  RowGap = 6;
  RowTopMargin = 0;
  RowBottomMargin = 0;
  LaneGap = 4;
  NodeMinHeight = 24;
  GroupBaseHeight = 40;

  // Fila de una maquina de sistema (__SINMAQUINA__): gris muy suave. No es un
  // error tener carga aqui -- es carga que nadie ha asignado a una maquina
  // concreta -- pero conviene distinguirla de un torno de verdad.
  ROW_BK_SISTEMA = $00F4F4F4;
  ROW_BK_NORMAL  = $00FFFFFF;

  // Id sintetico de la fila "Sin asignar" (nodos cuya maquina no se ha podido
  // resolver). Negativo para no chocar con ningun MaquinaId real.
  MAQ_SIN_ASIGNAR = -1;

constructor TGanttControlMaquinas.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetLength(FMaquinas, 0);
  SetLength(FNodoMaquina, 0);
end;

procedure TGanttControlMaquinas.SetMaquinas(const AMaquinas: TMaquinaFilaArray);
begin
  FMaquinas := AMaquinas;
end;

procedure TGanttControlMaquinas.SetNodoMaquina(const AMapa: TNodoMaquinaArray);
begin
  FNodoMaquina := AMapa;
end;

procedure TGanttControlMaquinas.SortRowNodeLayoutsByLeft(AFirst, ALast: Integer);
var
  Sub: TArray<TNodeLayout>;
  I: Integer;
begin
  // El hit-test del padre asume Rect.Left creciente dentro de la fila.
  if ALast <= AFirst then Exit;
  SetLength(Sub, ALast - AFirst + 1);
  for I := 0 to High(Sub) do
    Sub[I] := FNodeLayouts[AFirst + I];

  TArray.Sort<TNodeLayout>(Sub,
    TComparer<TNodeLayout>.Construct(
      function(const L, R: TNodeLayout): Integer
      begin
        if L.Rect.Left < R.Rect.Left then Result := -1
        else if L.Rect.Left > R.Rect.Left then Result := 1
        else Result := 0;
      end));

  for I := 0 to High(Sub) do
    FNodeLayouts[AFirst + I] := Sub[I];
end;

function TGanttControlMaquinas.IsRowVisible(const ARowIndex: Integer): Boolean;
begin
  Result := True;
end;

// Indice de la fila (no del centre) que hay bajo ScreenY. -1 si ninguna.
function TGanttControlMaquinas.FilaBajoY(const ScreenY: Integer): Integer;
var
  I: Integer;
  worldY: Single;
begin
  Result := -1;
  worldY := ScreenY + FScrollY;
  for I := 0 to High(FRows) do
    if FRows[I].Visible and
       (worldY >= FRows[I].TopY) and
       (worldY <= FRows[I].TopY + FRows[I].Height) then
      Exit(I);
end;

function TGanttControlMaquinas.CentreIdFromScreenY(
  const ScreenY: Integer): Integer;
var
  Fila, MaqId, I: Integer;
begin
  // El padre devolveria FRows[i].CentreId, que aqui es el INDICE DE FILA. Hay
  // que traducirlo al centre real de esa maquina, o al soltar un nodo se le
  // escribiria un CentreId inventado.
  //
  // OJO al valor por defecto: NO puede ser 0. Un 0 acaba en
  // "CenterId = NULL" en FS_PL_Node (ver SaveNodePositions) y el nodo se queda
  // huerfano de centre, fuera del plan. Se devuelve el centre de ORIGEN, que es
  // lo mismo que hace el control base cuando no encuentra fila.
  Result := FMoveOrigCentreId;

  Fila := FilaBajoY(ScreenY);
  if Fila < 0 then Exit;                      // fuera de toda fila
  if (Fila > High(FRowMaquinaId)) then Exit;

  MaqId := FRowMaquinaId[Fila];
  // Fila "Sin asignar": no tiene centre propio, se queda con el suyo.
  if MaqId = MAQ_SIN_ASIGNAR then Exit;

  for I := 0 to High(FMaquinas) do
    if FMaquinas[I].MaquinaId = MaqId then
      Exit(FMaquinas[I].CentroId);
end;

function TGanttControlMaquinas.RowTopYByCentreId(
  const CentreId: Integer): Single;
var
  Fila, I: Integer;
begin
  Result := 0;

  // Durante un drag, la fila destino la marca EL RATON, no el CentreId: un
  // centre puede tener varias maquinas (varias filas) y el CentreId por si solo
  // no distingue cual. Se usa la fila que hay bajo el cursor.
  Fila := FilaBajoY(FLastMouseY);
  if (Fila >= 0) and (Fila <= High(FRows)) then
    Exit(FRows[Fila].TopY);

  // Fuera de un drag (o cursor fuera de toda fila): la primera fila de una
  // maquina de ese centre. Es la respuesta razonable a "donde esta el centre X".
  for I := 0 to High(FMaquinas) do
    if FMaquinas[I].CentroId = CentreId then
    begin
      Fila := FilaDeMaquina(FMaquinas[I].MaquinaId);
      if (Fila >= 0) and (Fila <= High(FRows)) then
        Exit(FRows[Fila].TopY);
    end;
end;

// Indice de la fila que muestra una maquina (-1 si no se muestra).
function TGanttControlMaquinas.FilaDeMaquina(AMaquinaId: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FRowMaquinaId) do
    if FRowMaquinaId[I] = AMaquinaId then
      Exit(I);
end;

function TGanttControlMaquinas.MaquinaIdFromScreenY(
  const ScreenY: Integer): Integer;
var
  Fila: Integer;
begin
  Result := 0;
  Fila := FilaBajoY(ScreenY);
  if (Fila < 0) or (Fila > High(FRowMaquinaId)) then Exit;
  if FRowMaquinaId[Fila] = MAQ_SIN_ASIGNAR then Exit;
  Result := FRowMaquinaId[Fila];
end;

function TGanttControlMaquinas.AjustarNodoTrasMover(
  const ANodeIdx, AScreenY: Integer): Boolean;
var
  MaqId: Integer;
begin
  Result := False;
  if (ANodeIdx < 0) or (ANodeIdx > High(FNodes)) then Exit;

  MaqId := MaquinaIdFromScreenY(AScreenY);
  // 0 = no se ha podido resolver (fila "Sin asignar", o fuera de toda fila):
  // se deja la maquina que tuviera. Mejor no tocarla que ponerle una mala.
  if MaqId <= 0 then Exit;

  // Sin cambio de maquina no hay nada que rehacer (arrastre horizontal dentro
  // de la misma fila: solo cambian las fechas).
  if FNodes[ANodeIdx].MaquinaId = MaqId then Exit;
  Result := True;   // ha cambiado de fila -> el layout se tiene que rehacer

  // 1) El modelo: es lo que persiste el auto-save con las fechas.
  FNodes[ANodeIdx].MaquinaId := MaqId;

  // 2) Y el mapa que usa RebuildLayout para repartir los nodos por fila. Sin
  // esto el nodo se seguiria pintando en su fila ANTERIOR hasta recargar la
  // vista entera, aunque en BD ya estuviera en la nueva.
  ApuntarEnMapa(FNodes[ANodeIdx].Id, MaqId);
end;

procedure TGanttControlMaquinas.ApuntarEnMapa(ADataId, AMaquinaId: Integer);
var
  I, N: Integer;
begin
  for I := 0 to High(FNodoMaquina) do
    if FNodoMaquina[I].DataId = ADataId then
    begin
      FNodoMaquina[I].MaquinaId := AMaquinaId;
      Exit;
    end;

  // Nodo que aun no estaba en el mapa (venia de la fila "Sin asignar"): se
  // anade, para que a partir de ahora caiga en la fila de su maquina.
  N := Length(FNodoMaquina);
  SetLength(FNodoMaquina, N + 1);
  FNodoMaquina[N].DataId := ADataId;
  FNodoMaquina[N].MaquinaId := AMaquinaId;
end;

procedure TGanttControlMaquinas.NodoSeguidoAOtro(
  const ANodeIdx, AOrigenIdx: Integer);
begin
  if (ANodeIdx < 0) or (ANodeIdx > High(FNodes)) then Exit;
  // El nodo ya trae la maquina copiada del arrastrado (lo hace el control
  // base); aqui solo falta que el MAPA lo sepa, o se pintaria en su fila vieja
  // y el lote se veria partido entre dos maquinas.
  if FNodes[ANodeIdx].MaquinaId > 0 then
    ApuntarEnMapa(FNodes[ANodeIdx].Id, FNodes[ANodeIdx].MaquinaId);
end;

procedure TGanttControlMaquinas.RebuildLayout;
var
  ri, gi, k, idx: Integer;
  row: TRowLayout;
  idxs: TArray<Integer>;
  y: Single;
  laneCount, laneIdx: Integer;
  laneH, rowH: Single;
  laneRight: TArray<Single>;
  node: TNode;
  nl: TNodeLayout;
  maxEndTime: TDateTime;

  maqPorId: TDictionary<Integer, Integer>;    // MaquinaId -> indice de fila
  nodoAMaq: TDictionary<Integer, Integer>;    // DataId -> MaquinaId
  filaNodes: TArray<TList<Integer>>;          // por fila: node-index
  MaqId, FilaIdx: Integer;
  Minutos: Double;
  Solapes: Integer;
  Orden: TArray<Integer>;                     // orden de presentacion de filas

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
  SetLength(FRowMaquinaId, 0);
  SetLength(FRowCodigo, 0);
  SetLength(FRowNombre, 0);
  SetLength(FRowCentro, 0);
  SetLength(FRowEsSistema, 0);
  SetLength(FRowNumNodos, 0);
  SetLength(FRowMinutos, 0);
  SetLength(FRowSolapes, 0);

  y := RowTopMargin;
  maxEndTime := FStartTime;

  maqPorId := TDictionary<Integer, Integer>.Create;
  nodoAMaq := TDictionary<Integer, Integer>.Create;
  try
    // ===== Paso 1: una fila por maquina inyectada =====
    // Se crean TODAS, tengan carga o no: una maquina vacia es informacion
    // (esta libre), no algo que haya que esconder.
    SetLength(filaNodes, Length(FMaquinas) + 1);   // +1 = fila "Sin asignar"
    for gi := 0 to High(FMaquinas) do
    begin
      maqPorId.AddOrSetValue(FMaquinas[gi].MaquinaId, gi);
      filaNodes[gi] := TList<Integer>.Create;
    end;
    // Ultima fila: nodos cuya maquina no se ha podido resolver.
    filaNodes[High(filaNodes)] := TList<Integer>.Create;

    // ===== Paso 2: repartir los nodos por fila =====
    for ri := 0 to High(FNodoMaquina) do
      nodoAMaq.AddOrSetValue(FNodoMaquina[ri].DataId, FNodoMaquina[ri].MaquinaId);

    for idx := 0 to High(FNodes) do
    begin
      if not FNodes[idx].Visible then Continue;
      if (FNodes[idx].StartTime = 0) or (FNodes[idx].EndTime = 0) then Continue;

      if nodoAMaq.TryGetValue(FNodes[idx].Id, MaqId) and
         maqPorId.TryGetValue(MaqId, FilaIdx) then
        filaNodes[FilaIdx].Add(idx)
      else
        // Sin maquina conocida: a la fila del final. No se descarta.
        filaNodes[High(filaNodes)].Add(idx);
    end;

    // ===== Paso 3: orden de presentacion =====
    // Las maquinas ya vienen agrupadas por centro desde la vista; se respeta
    // ese orden. La fila "Sin asignar" solo se muestra si tiene carga (una fila
    // vacia titulada "Sin asignar" solo genera dudas).
    SetLength(Orden, 0);
    for gi := 0 to High(FMaquinas) do
    begin
      SetLength(Orden, Length(Orden) + 1);
      Orden[High(Orden)] := gi;
    end;
    if filaNodes[High(filaNodes)].Count > 0 then
    begin
      SetLength(Orden, Length(Orden) + 1);
      Orden[High(Orden)] := High(filaNodes);
    end;

    // ===== Paso 4: construir cada fila =====
    for ri := 0 to High(Orden) do
    begin
      gi := Orden[ri];
      idxs := filaNodes[gi].ToArray;

      if Length(idxs) > 1 then
        TArray.Sort<Integer>(idxs,
          TComparer<Integer>.Construct(
            function(const L, R: Integer): Integer
            begin
              Result := CompareDateTime(FNodes[L].StartTime, FNodes[R].StartTime);
              if Result = 0 then
                Result := CompareDateTime(FNodes[L].EndTime, FNodes[R].EndTime);
            end));

      // Carga total y pico de simultaneidad. En una maquina el pico deberia ser
      // 1 salvo que su centro admita trabajos en paralelo (MaxLanes > 1); si
      // sale mas alto sin que toque, es que algo se ha solapado a mano.
      Minutos := 0;
      Solapes := 0;
      for k := 0 to High(idxs) do
      begin
        Minutos := Minutos +
          (FNodes[idxs[k]].EndTime - FNodes[idxs[k]].StartTime) * 24 * 60;
        idx := 1;   // el propio nodo
        for laneIdx := 0 to High(idxs) do
          if (laneIdx <> k)
             and (FNodes[idxs[laneIdx]].StartTime < FNodes[idxs[k]].EndTime)
             and (FNodes[idxs[laneIdx]].EndTime > FNodes[idxs[k]].StartTime) then
            Inc(idx);
        if idx > Solapes then Solapes := idx;
      end;

      // Lanes por packing (igual que GRUPO): tantos como haga falta para que
      // los nodos no se pisen visualmente.
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

      laneH := Max(NodeMinHeight,
        (GroupBaseHeight - (laneCount - 1) * LaneGap) / laneCount);
      rowH := (laneCount * laneH) + ((laneCount - 1) * LaneGap) +
              NODE_INNER_PAD_TOP + NODE_INNER_PAD_BOTTOM;
      if laneCount <= 1 then
        rowH := GroupBaseHeight + RowGap;

      // Metadatos de la fila (paralelos a FRows, indexados por ri).
      SetLength(FRowMaquinaId, ri + 1);
      SetLength(FRowCodigo, ri + 1);
      SetLength(FRowNombre, ri + 1);
      SetLength(FRowCentro, ri + 1);
      SetLength(FRowEsSistema, ri + 1);
      SetLength(FRowNumNodos, ri + 1);
      SetLength(FRowMinutos, ri + 1);
      SetLength(FRowSolapes, ri + 1);

      if gi <= High(FMaquinas) then
      begin
        FRowMaquinaId[ri] := FMaquinas[gi].MaquinaId;
        FRowCodigo[ri]    := FMaquinas[gi].Codigo;
        FRowNombre[ri]    := FMaquinas[gi].Nombre;
        FRowCentro[ri]    := FMaquinas[gi].CentroCodigo;
        FRowEsSistema[ri] := FMaquinas[gi].EsSistema;
      end
      else
      begin
        FRowMaquinaId[ri] := MAQ_SIN_ASIGNAR;
        FRowCodigo[ri]    := 'Sin asignar';
        FRowNombre[ri]    := 'Nodos sin m'#225'quina asignada';
        FRowCentro[ri]    := '';
        FRowEsSistema[ri] := True;
      end;
      FRowNumNodos[ri] := Length(idxs);
      FRowMinutos[ri]  := Minutos;
      FRowSolapes[ri]  := Solapes;

      // CentreId = indice de FILA (lo lee el panel izquierdo), no un centre real.
      row.CentreId := ri;
      row.TopY := y;
      row.Height := rowH;
      row.LaneCount := laneCount;
      row.Order := ri;
      row.Visible := True;
      row.Enabled := True;
      if FRowEsSistema[ri] then row.bkColor := ROW_BK_SISTEMA
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
        nl.CentreId := node.CentreId;   // centre real del nodo (hit-test)
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
  finally
    for k := 0 to High(filaNodes) do
      if filaNodes[k] <> nil then filaNodes[k].Free;
    nodoAMaq.Free;
    maqPorId.Free;
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

function TGanttControlMaquinas.GetRowCaption(const ARowIndex: Integer): string;
begin
  Result := '';
  if (ARowIndex < 0) or (ARowIndex > High(FRowCodigo)) then Exit;
  Result := FRowCodigo[ARowIndex];
  // Las de sistema llevan el prefijo tecnico __SINMAQUINA__<centro>: aqui se
  // muestra algo legible.
  if FRowEsSistema[ARowIndex] and
     (Pos('__SINMAQUINA__', Result) = 1) then
    Result := 'Sin m'#225'quina';
end;

function TGanttControlMaquinas.GetRowSubtitle(const ARowIndex: Integer): string;
begin
  Result := '';
  if (ARowIndex < 0) or (ARowIndex > High(FRowNombre)) then Exit;

  // En las maquinas de sistema, el Nombre es "Sin maquina (CENTRO)": repetirlo
  // aqui es ruido, porque la 1a linea ya dice "Sin maquina". Basta el centre,
  // que es lo unico que distingue una fila de otra.
  if FRowEsSistema[ARowIndex] then
    Exit(FRowCentro[ARowIndex]);

  if FRowCentro[ARowIndex] <> '' then
    Result := FRowCentro[ARowIndex] + ' - ' + FRowNombre[ARowIndex]
  else
    Result := FRowNombre[ARowIndex];
end;

function TGanttControlMaquinas.GetRowCarga(const ARowIndex: Integer): string;
var
  Horas: Double;
begin
  Result := '';
  if (ARowIndex < 0) or (ARowIndex > High(FRowNumNodos)) then Exit;

  if FRowNumNodos[ARowIndex] = 0 then
    Exit('Sin carga');

  Horas := FRowMinutos[ARowIndex] / 60;
  Result := Format('%d nodos - %.1f h', [FRowNumNodos[ARowIndex], Horas]);
  // Solapes > 1 en una maquina merece mencion: o el centro admite paralelo, o
  // alguien ha solapado a mano.
  if FRowSolapes[ARowIndex] > 1 then
    Result := Result + Format(' - pico %d', [FRowSolapes[ARowIndex]]);
end;

function TGanttControlMaquinas.GetRowMaquinaId(const ARowIndex: Integer): Integer;
begin
  Result := 0;
  if (ARowIndex < 0) or (ARowIndex > High(FRowMaquinaId)) then Exit;
  Result := FRowMaquinaId[ARowIndex];
end;

function TGanttControlMaquinas.GetRowCapacidad(const ARowIndex: Integer): Integer;
var
  I, CentroId: Integer;
begin
  // Capacidad = MaxLanes del centre al que pertenece la maquina (V083: MaxLanes
  // pasa a ser "trabajos simultaneos que admite CADA maquina"). Se lee de
  // FCentres, que el control base recibe en SetData.
  Result := 1;
  if (ARowIndex < 0) or (ARowIndex > High(FRowMaquinaId)) then Exit;

  CentroId := 0;
  for I := 0 to High(FMaquinas) do
    if FMaquinas[I].MaquinaId = FRowMaquinaId[ARowIndex] then
    begin
      CentroId := FMaquinas[I].CentroId;
      Break;
    end;
  if CentroId = 0 then Exit;   // fila "Sin asignar": sin capacidad propia

  for I := 0 to High(FCentres) do
    if FCentres[I].Id = CentroId then
    begin
      if FCentres[I].IsSequencial then Exit(1);
      Exit(FCentres[I].MaxLaneCount);   // 0 = sin limite (circulo infinito)
    end;
end;

function TGanttControlMaquinas.GetRowHint(const ARowIndex: Integer): string;
var
  Lines: TStringList;
begin
  Result := '';
  if (ARowIndex < 0) or (ARowIndex > High(FRowCodigo)) then Exit;

  Lines := TStringList.Create;
  try
    Lines.Add(GetRowCaption(ARowIndex));
    if FRowNombre[ARowIndex] <> '' then
      Lines.Add(FRowNombre[ARowIndex]);
    if FRowCentro[ARowIndex] <> '' then
      Lines.Add('Centro: ' + FRowCentro[ARowIndex]);
    Lines.Add('');
    Lines.Add('En el plan: ' + GetRowCarga(ARowIndex));

    if FRowMaquinaId[ARowIndex] = MAQ_SIN_ASIGNAR then
      Lines.Add('Nodos anteriores a la planificaci'#243'n por m'#225'quina, ' +
        'o creados a mano.')
    else if FRowEsSistema[ARowIndex] then
      Lines.Add('M'#225'quina por defecto del centro: recoge la carga que no ' +
        'se ha asignado a una m'#225'quina concreta.');

    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
