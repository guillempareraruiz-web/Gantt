unit uGanttControlTareas;

{
  TGanttControlTareas - Control de Gantt del Modulo de Proyectos (estilo MS
  Project). FILAS = tareas de la WBS, en orden de arbol (padre antes que hijos,
  respetando el plegado del acordeon). Una fila por tarea visible.

  Hereda de TGanttControl (mismo patron que Utillajes/Operarios): las tareas son
  nodos de FS_PL_Node, asi que se cargan como TNode normales; lo que cambia es
  el ORDEN de las filas (WBS, no por centro) y el pintado de resumen/hito.

  El orden y los metadatos de cada tarea (nivel, tipo, plegado, criticidad,
  holgura, avance) se INYECTAN desde uVistaProyectos via SetOrden antes de
  SetData: el control NO toca la BD ni calcula fechas. Las barras se pintan tal
  cual vienen; quien las recalcula es el motor (uWbsScheduler), y la vista
  vuelve a inyectar el resultado.

  El drag esta abierto: mover/redimensionar una barra y crear dependencias con
  Ctrl+handle se notifican a la vista por eventos (TWbsBarraModificadaEvent,
  TWbsDependenciaCreadaEvent), que persiste y replanifica.
}

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.DateUtils,
  System.Math, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  uGanttControl, uGanttTypes, uGanttHelpers, uCentreCalendar, uErpTypes,
  uWbsTypes;

const
  // A partir de que avance se considera DESVIACION digna de aviso (ambar en el
  // Gantt, simbolo en el grid). No es 1.0: pasarse un 2% del tiempo estimado es
  // ruido, no un problema, y pintarlo de ambar hacia que un proyecto sano
  // pareciera en llamas.
  UMBRAL_DESVIACION = 1.10;   // +10%

  // --- Linea base y sobreasignacion (V082) -----------------------------------
  // La barra fantasma es una REFERENCIA: fina y apagada, para que se compare
  // con la real sin competir con ella.
  ALTO_BASE = 3;              // grosor en px de la barra de linea base
  COL_BASE          = $00B0B0B0;   // gris medio: en plazo o adelantada
  COL_BASE_RETRASO  = $000090FF;   // ambar: el fin real se ha ido mas tarde
  // Cuanto se puede pasar del fin aprobado sin considerarlo retraso. Medio dia
  // laborable: sin margen, un recalculo que mueve la tarea unos minutos ya
  // pintaba de ambar medio proyecto.
  MINUTOS_TOLERANCIA_BASE = 240;
  // Distintivo de operario sobreasignado (azul de aviso, no rojo de error: las
  // fechas son validas, lo que falta es gente).
  COL_SOBRECARGA    = $00CC5A10;

type
  // Metadatos de orden/jerarquia de una tarea, inyectados por la vista.
  TWbsRowInfo = record
    NodeId: Integer;
    Kind: TWbsTaskKind;
    Nivel: Integer;
    Visible: Boolean;   // False si esta bajo una rama plegada
    // Fase 2: resultado del motor de fechas (uWbsScheduler). Volatil.
    EsCritica: Boolean;
    HolguraMin: Double;
    // Avance 0..1 (o mas si hay desviacion). Lo pinta el overlay como linea
    // interior, estilo GanttPRO.
    Avance: Double;
    // Titulo que el overlay pinta a la derecha de la barra. Se inyecta aqui
    // (y NO se deja en TNode.Caption) para que el render base no lo escriba
    // tambien DENTRO de la barra y salga duplicado.
    Titulo: string;
    // Fila de NIVEL 0 = cabecera de un proyecto entero (la vista puede mostrar
    // varios a la vez). No es una tarea: no tiene TNode ni barra propia, solo
    // ocupa su fila para no descuadrar la correspondencia con el grid. Sus
    // fechas se pintan como una banda que abarca todo el proyecto.
    EsProyecto: Boolean;
    ProyectoIni: TDateTime;
    ProyectoFin: TDateTime;
    // Colores de las etiquetas (V081) de esta tarea. Se pintan como puntos a
    // la izquierda de la barra, estilo Trello.
    ColoresTag: TArray<Integer>;

    // --- Linea base (V082) ---------------------------------------------------
    // Fechas del plan congelado. Se pintan como una barra FANTASMA fina bajo la
    // barra real: comparar planificado contra aprobado de un vistazo es el
    // motivo de tener linea base. Ambas a 0 = esta tarea no la tiene (es
    // posterior a fijarla), y entonces no se pinta nada.
    BaseIni: TDateTime;
    BaseFin: TDateTime;
    // Operario sobreasignado en algun tramo de esta tarea: marca ambar.
    Sobrecargada: Boolean;
  end;
  TWbsRowInfoArray = TArray<TWbsRowInfo>;

  // El usuario ha creado una dependencia arrastrando (Ctrl + handle -> barra).
  TWbsDependenciaCreadaEvent = procedure(Sender: TObject;
    const AFromNodeId, AToNodeId, ATipoLink: Integer) of object;
  // El usuario ha movido o redimensionado una barra.
  TWbsBarraModificadaEvent = procedure(Sender: TObject; const ANodeId: Integer;
    const AInicio, AFin: TDateTime) of object;

  TGanttControlTareas = class(TGanttControl)
  protected
    FOrden: TWbsRowInfoArray;                 // orden WBS inyectado
    FKindPorNode: TDictionary<Integer, TWbsTaskKind>;
    FRowNodeId: TArray<Integer>;              // NodeId por fila (paralelo a FRows)
    FAltoFila: Integer;                       // 0 = usar el default del control
    FDesplazamientoY: Integer;                // offset inicial (cabecera del grid)
    FNodeIdToIdx: TDictionary<Integer, Integer>;  // NodeId -> indice en FNodes
                                                  // (reconstruido en RebuildLayout)
    FOnDependenciaCreada: TWbsDependenciaCreadaEvent;
    FOnBarraModificada: TWbsBarraModificadaEvent;
    FNodeIdResaltado: Integer;   // fila seleccionada en el grid WBS

    function BuildDataIdMap: TDictionary<Integer, Integer>;  // NodeId -> index en FNodes

    // Flechas de dependencia con trazado ORTOGONAL (solo tramos horizontales y
    // verticales), como MS Project. El render base las pinta como una recta
    // punto a punto, que cruza las barras en diagonal y se lee fatal.
    procedure PintarDependencias;
    // Rectangulo EN PANTALLA de la barra de un nodo. False si no esta pintada.
    function RectDeNodo(const ANodeId: Integer; out ARect: TRectF): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetOrden(const AOrden: TWbsRowInfoArray);
    // Copia del orden actual, para que la vista pueda recalcular la visibilidad
    // (acordeon) sin reconstruirlo entero desde cero.
    function GetOrden: TWbsRowInfoArray;

    procedure RebuildLayout; override;
    function IsRowVisible(const ARowIndex: Integer): Boolean; override;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    // Detecta que el usuario acaba de crear una dependencia (Ctrl + arrastrar
    // desde el handle de una barra a otra, el mismo gesto que en el Gantt de
    // produccion) o de mover/redimensionar una barra, y avisa a la vista para
    // que lo persista y replanifique.
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

    // Remate visual encima del render base (estilo MS Project / GanttPRO):
    // hitos como rombo y titulo de cada tarea a la DERECHA de su barra, para
    // que las tareas cortas no queden con el texto cortado.
    procedure Paint; override;

    function GetRowNodeId(const ARowIndex: Integer): Integer;
    // Numero de filas pintadas (tareas visibles + cabeceras de proyecto).
    function NumFilas: Integer;
    // True si el scroll vertical esta en su tope inferior. El Gantt y el grid
    // no tienen el mismo alto, asi que llegan al final en momentos distintos.
    function EnElFinal: Boolean;
    // Lleva el scroll vertical a su tope inferior.
    procedure ScrollAlFinal;

    // Fila resaltada (la seleccionada en el grid WBS). 0 = ninguna. Sirve para
    // que se vea de un vistazo que barra corresponde a la fila del arbol.
    procedure SetFilaResaltada(const ANodeId: Integer);

    // NodeId de la tarea que hay bajo el puntero, o 0 si el cursor no esta
    // sobre ninguna fila util. Lo usa el doble clic para abrir la ficha.
    function NodeIdBajoCursor: Integer;

    // Desplaza verticalmente el Gantt. La clase base expone ScrollY como solo
    // lectura; aqui hace falta escribirlo para seguir al grid de la izquierda.
    procedure ScrollVerticalA(const AY: Single);

    // Suelta la captura del raton y limpia el estado de arrastre. Hay que
    // llamarlo antes de abrir un dialogo modal desde un doble clic: si no, al
    // volver el control sigue creyendo que hay un boton pulsado.
    procedure SoltarRaton;
    property OnDependenciaCreada: TWbsDependenciaCreadaEvent
      read FOnDependenciaCreada write FOnDependenciaCreada;
    property OnBarraModificada: TWbsBarraModificadaEvent
      read FOnBarraModificada write FOnBarraModificada;
  published
    // TControl lo declara protected: se republica para que la vista pueda
    // engancharse al doble clic sobre una barra.
    property OnDblClick;

    // Alto de fila y desplazamiento vertical del area de barras, para cuadrar
    // fila a fila con el cxTreeList de la izquierda. La vista los mide del grid
    // real (DevExpress decide el alto segun fuente y skin) y los inyecta aqui.
    procedure SetMetricasFila(const AAltoFila, ADesplazamientoY: Integer);

    // Aplica el calendario laborable del modulo al sombreado de fondo. Las
    // tareas de proyecto no tienen centro (CentreId = 0), y GetCalendar(0)
    // devuelve un calendario VACIO = todo laborable, por eso no se pintaba
    // ningun fin de semana. Copia las reglas semanales de ACal al calendario
    // del centro 0, que es el que consulta DrawNonWorkingShadingRowD2D.
    procedure AplicarCalendario(const ACal: TCentreCalendar);
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
  COL_RESUMEN = $00807366;   // gris azulado (barra contenedora y capiteles)
  COL_HITO    = $00807366;   // rombo: mismo gris que el resumen
  COL_HITO_CRITICO = $006B6BC4;  // rombo en el camino critico: terracota

  // Colores del texto del overlay (titulo a la derecha de la barra). Grises
  // suaves: el texto acompana a la barra, no compite con ella.
  COL_TXT_NORMAL  = $00595959;
  COL_TXT_CRITICO = $005B5BB8;   // terracota, a juego con la barra critica
  COL_TXT_RESUMEN = $00463D34;   // gris azulado oscuro, en negrita

  // Cabecera de PROYECTO (nivel 0): banda fina y sobria que abarca todo el
  // proyecto. Es contexto, no una tarea: no debe competir con las barras.
  COL_PROYECTO     = $00998877;
  COL_TXT_PROYECTO = $00554C42;

  // Fila seleccionada en el grid WBS. Azul MUY claro: es un fondo que queda
  // detras de la barra y del texto, asi que tiene que senalar la fila sin
  // competir con su contenido.
  COL_FILA_SEL = $00F5E4D0;
  // Grosor de las franjas superior e inferior con las que se marca la fila
  // seleccionada (la banda central se deja libre para no tapar la barra).
  PAD_SEL = 4;
  // Diametro de los puntos de etiqueta que se pintan dentro de la barra.
  TAM_BADGE = 8;

  // Flechas de dependencia.
  COL_FLECHA  = $00909090;   // gris medio: guian la lectura sin robar foco
  GAP_FLECHA  = 10;          // tramo horizontal al salir/entrar de una barra
  ALTO_RODEO  = 12;          // cuanto se baja para rodear cuando no hay sitio

  // Tramo COMPLETADO de la barra: EL MISMO tono, mas saturado y oscuro (no un
  // color distinto), para que se lea como "esta parte de la barra ya esta
  // hecha" sin necesidad de leyenda.
  COL_AVANCE          = $00A87F44;   // azul, version oscura de COL_PRJ_TAREA
  COL_AVANCE_CRITICO  = $005B5BB8;   // terracota oscuro
  COL_AVANCE_RESUMEN  = $00564C42;   // gris azulado oscuro
  COL_AVANCE_EXCESO   = $003C8EE8;   // naranja tostado: desviacion real

constructor TGanttControlTareas.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FKindPorNode := TDictionary<Integer, TWbsTaskKind>.Create;
end;

destructor TGanttControlTareas.Destroy;
begin
  FNodeIdToIdx.Free;
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

function TGanttControlTareas.GetOrden: TWbsRowInfoArray;
begin
  Result := Copy(FOrden);
end;

function TGanttControlTareas.IsRowVisible(const ARowIndex: Integer): Boolean;
begin
  Result := (ARowIndex >= 0) and (ARowIndex <= High(FRows));
end;

procedure TGanttControlTareas.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  // Fase 3: el drag esta ABIERTO (antes se cortaba aqui). Mover una barra fija
  // su fecha y redimensionarla cambia la duracion; de eso se encarga la vista
  // al recibir OnBarraModificada.
  inherited MouseMove(Shift, X, Y);
end;

procedure TGanttControlTareas.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  EraLinkDrag: Boolean;
  NodeIdx, NumLinks, NuevoLink, I: Integer;
  NodeId: Integer;
  Ini, Fin: TDateTime;
begin
  // Guardar el estado ANTES de llamar al inherited, que es quien lo limpia.
  EraLinkDrag := FLinkDragging;
  NumLinks := Length(FLinks);
  NodeIdx := FMouseDownNodeIndex;

  NodeId := 0;
  Ini := 0;
  Fin := 0;
  if (NodeIdx >= 0) and (NodeIdx <= High(FNodes)) then
  begin
    NodeId := FNodes[NodeIdx].Id;
    Ini := FNodes[NodeIdx].StartTime;
    Fin := FNodes[NodeIdx].EndTime;
  end;

  inherited MouseUp(Button, Shift, X, Y);

  // A partir de aqui NO se puede indexar FNodes/FLinks con los indices de
  // antes: el inherited puede haber reconstruido los arrays (era la causa del
  // GPF al arrastrar). Se buscan los datos por Id, que si es estable.

  // --- Dependencia creada ---
  if EraLinkDrag and (Length(FLinks) > NumLinks) and
     Assigned(FOnDependenciaCreada) then
  begin
    NuevoLink := High(FLinks);
    if NuevoLink >= 0 then
      FOnDependenciaCreada(Self, FLinks[NuevoLink].FromNodeId,
        FLinks[NuevoLink].ToNodeId, Ord(FLinks[NuevoLink].LinkType));
    Exit;
  end;

  // --- Barra movida o redimensionada ---
  if (NodeId <= 0) or (not Assigned(FOnBarraModificada)) then Exit;

  // Localizar el nodo POR ID en el array actual.
  NodeIdx := -1;
  for I := 0 to High(FNodes) do
    if FNodes[I].Id = NodeId then
    begin
      NodeIdx := I;
      Break;
    end;
  if NodeIdx < 0 then Exit;

  if (FNodes[NodeIdx].StartTime <> Ini) or (FNodes[NodeIdx].EndTime <> Fin) then
    FOnBarraModificada(Self, NodeId,
      FNodes[NodeIdx].StartTime, FNodes[NodeIdx].EndTime);
end;

procedure TGanttControlTareas.Paint;
var
  i, layoutIdx, nodeIdx: Integer;
  r: TRectF;
  cx, cy, semi: Integer;
  Pts: array[0..3] of TPoint;
  Txt: string;
  TxtX, TxtY: Integer;
  AvanceW: Single;
  filaVisible, altoF: Integer;
  yFila, xIni, xFin: Single;
  xTag, k: Integer;
    Kind: TWbsTaskKind;
  EsCritica: Boolean;
  ColBarra: TColor;

  // Instante -> X en pantalla, con el mismo criterio que RebuildLayout.
  function TiempoAX(const T: TDateTime): Single;
  begin
    Result := VisibleMinutesBetween(FStartTime, T) * FPxPerMinute - FScrollX;
  end;

begin
  inherited Paint;   // render base (barras, rejilla, dependencias)

  // ---- Remate propio del modulo de proyectos ------------------------------
  // Se pinta ENCIMA con el Canvas de VCL: el render base es Direct2D y no
  // expone puntos de extension por tipo de tarea, asi que en vez de duplicar
  // PaintD2D entero (~1000 lineas) se retoca aqui lo especifico de WBS.
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 8;
  Canvas.Brush.Style := bsClear;

  // Contador de filas visibles: las cabeceras de proyecto no tienen layout, asi
  // que su Y se calcula por posicion de fila.
  filaVisible := 0;
  altoF := FAltoFila;
  if altoF <= 0 then altoF := RowHeight + RowGap;

  // ---- Fila seleccionada en el grid ----
  // OJO: NO sirve asignar row.bkColor. En uGanttControl hay DOS PaintD2D y la
  // que lo pinta (~9356) esta COMENTADA; la viva (~8173) rellena el fondo de
  // una vez y nunca lee bkColor. Asi que se marca aqui, encima, con un relleno
  // suave a los lados de la barra: cubre la fila entera sin tapar la barra ni
  // su texto.
  if FNodeIdResaltado > 0 then
    for i := 0 to High(FRowNodeId) do
      if FRowNodeId[i] = FNodeIdResaltado then
      begin
        yFila := RowTopMargin + FDesplazamientoY + i * altoF - FScrollY;
        if (yFila + altoF >= 0) and (yFila <= ClientHeight) then
        begin
          Canvas.Brush.Style := bsSolid;
          Canvas.Brush.Color := COL_FILA_SEL;
          Canvas.Pen.Style := psClear;
          // Franja superior e inferior de la fila: la banda central se deja
          // libre para no cubrir la barra.
          Canvas.FillRect(Rect(0, Round(yFila), ClientWidth,
            Round(yFila) + PAD_SEL));
          Canvas.FillRect(Rect(0, Round(yFila) + altoF - PAD_SEL, ClientWidth,
            Round(yFila) + altoF));
          Canvas.Pen.Style := psSolid;
          Canvas.Brush.Style := bsClear;
        end;
        Break;
      end;

  for i := 0 to High(FOrden) do
  begin
    if not FOrden[i].Visible then Continue;

    // ---- Cabecera de PROYECTO (nivel 0): banda que abarca todo el proyecto --
    // No tiene TNode, asi que se dibuja aqui a partir de sus fechas.
    if FOrden[i].EsProyecto then
    begin
      Inc(filaVisible);
      if (FOrden[i].ProyectoIni > 0) and (FOrden[i].ProyectoFin > 0) then
      begin
        yFila := RowTopMargin + FDesplazamientoY + (filaVisible - 1) * altoF - FScrollY;
        if (yFila + altoF >= 0) and (yFila <= ClientHeight) then
        begin
          xIni := TiempoAX(FOrden[i].ProyectoIni);
          xFin := TiempoAX(FOrden[i].ProyectoFin);
          Canvas.Brush.Style := bsSolid;
          Canvas.Brush.Color := COL_PROYECTO;
          Canvas.Pen.Style := psClear;
          Canvas.FillRect(Rect(Round(xIni), Round(yFila) + 6,
                               Round(xFin), Round(yFila) + 12));
          Canvas.Pen.Style := psSolid;
          Canvas.Brush.Style := bsClear;

          // Nombre del proyecto, a la derecha de su banda.
          if FOrden[i].Titulo <> '' then
          begin
            Canvas.Font.Style := [fsBold];
            Canvas.Font.Color := COL_TXT_PROYECTO;
            Canvas.TextOut(Round(xFin) + 6,
              Round(yFila) + 3, FOrden[i].Titulo);
            Canvas.Font.Style := [];
          end;
        end;
      end;
      Continue;
    end;

    if (FNodeIdToIdx = nil) or
       (not FNodeIdToIdx.TryGetValue(FOrden[i].NodeId, nodeIdx)) then Continue;
    Inc(filaVisible);
    if FNodeIndexToLayoutIndex = nil then Continue;
    if not FNodeIndexToLayoutIndex.TryGetValue(nodeIdx, layoutIdx) then Continue;

    // world -> screen
    r := FNodeLayouts[layoutIdx].Rect;
    r.Offset(-FScrollX, -FScrollY);
    if (r.Bottom < 0) or (r.Top > ClientHeight) then Continue;

    Kind := FOrden[i].Kind;
    EsCritica := FOrden[i].EsCritica;

    // ---- Linea base: barra FANTASMA bajo la real (V082) ----
    // Va lo PRIMERO de la fila para que quede por debajo de todo lo demas: es
    // una referencia, no el dato. Se pinta fina y gris, pegada al borde
    // inferior, para que la comparacion sea inmediata sin robar protagonismo a
    // la barra del plan vigente.
    if (FOrden[i].BaseIni > 0) and (FOrden[i].BaseFin > FOrden[i].BaseIni) then
    begin
      xIni := TiempoAX(FOrden[i].BaseIni);
      xFin := TiempoAX(FOrden[i].BaseFin);
      if xFin - xIni < 2 then xFin := xIni + 2;   // que siempre se vea algo

      Canvas.Brush.Style := bsSolid;
      Canvas.Pen.Style := psClear;
      // Gris si va en plazo o adelantada; ambar si el fin real se ha ido mas
      // tarde que el aprobado (es lo que hay que mirar de un vistazo).
      if FNodeLayouts[layoutIdx].Rect.Right - FScrollX >
         xFin + FPxPerMinute * MINUTOS_TOLERANCIA_BASE then
        Canvas.Brush.Color := COL_BASE_RETRASO
      else
        Canvas.Brush.Color := COL_BASE;

      Canvas.FillRect(Rect(Round(xIni), Round(r.Bottom) + 1,
                           Round(xFin), Round(r.Bottom) + 1 + ALTO_BASE));
      Canvas.Pen.Style := psSolid;
      Canvas.Brush.Style := bsClear;
    end;

    // ---- Operario sobreasignado: marca ambar al inicio de la barra ----
    // No se tine la barra entera: las FECHAS son validas, lo que falla es que
    // no hay gente para cumplirlas. Un distintivo pequeno lo dice sin hacer
    // que la fila parezca un error de planificacion.
    if FOrden[i].Sobrecargada and (Kind <> wtkHito) then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := COL_SOBRECARGA;
      Canvas.Pen.Style := psClear;
      Canvas.FillRect(Rect(Round(r.Left) - 4, Round(r.Top),
                           Round(r.Left) - 1, Round(r.Bottom)));
      Canvas.Pen.Style := psSolid;
      Canvas.Brush.Style := bsClear;
    end;

    // ---- Hito: rombo (girado 45) sobre el cuadrado del layout ----
    if Kind = wtkHito then
    begin
      cx := Round((r.Left + r.Right) / 2);
      cy := Round((r.Top + r.Bottom) / 2);
      semi := Round((r.Bottom - r.Top) / 2);
      if EsCritica then ColBarra := COL_HITO_CRITICO else ColBarra := COL_HITO;

      Pts[0] := Point(cx, cy - semi);
      Pts[1] := Point(cx + semi, cy);
      Pts[2] := Point(cx, cy + semi);
      Pts[3] := Point(cx - semi, cy);

      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := ColBarra;
      Canvas.Pen.Color := AdjustColorBrightness(ColBarra, -50);
      Canvas.Pen.Width := 1;
      Canvas.Polygon(Pts);
      Canvas.Brush.Style := bsClear;
    end;

    // ---- Avance: el tramo hecho, en un tono MAS OSCURO ----
    // Dos tonos del mismo color (oscuro = hecho, claro = pendiente) en vez de
    // una franja: se entiende sin leyenda. La barra clara ya la pinto el
    // render base; aqui solo se oscurece la parte completada.
    if FOrden[i].Avance > 0 then
    begin
      AvanceW := (r.Right - r.Left) * Min(1.0, FOrden[i].Avance);
      if AvanceW >= 1 then
      begin
        Canvas.Brush.Style := bsSolid;
        Canvas.Pen.Style := psClear;
        if FOrden[i].Avance > UMBRAL_DESVIACION then
          // Desviacion relevante: se ha invertido bastante mas tiempo del
          // estimado. Con un umbral justo en 1.0 cualquier exceso minimo
          // tenia toda la barra de ambar y parecia que el proyecto ardia.
          Canvas.Brush.Color := COL_AVANCE_EXCESO
        else if Kind = wtkResumen then
          Canvas.Brush.Color := COL_AVANCE_RESUMEN
        else if EsCritica then
          Canvas.Brush.Color := COL_AVANCE_CRITICO
        else
          Canvas.Brush.Color := COL_AVANCE;

        Canvas.FillRect(Rect(
          Round(r.Left), Round(r.Top),
          Round(r.Left + AvanceW), Round(r.Bottom)));
        Canvas.Pen.Style := psSolid;
        Canvas.Brush.Style := bsClear;
      end;
    end;

    // ---- Resumen: capiteles en los extremos (estilo MS Project) ----
    // Se pintan DESPUES del avance: son el remate que identifica la barra como
    // contenedora y no deben quedar tapados por el tramo completado.
    if Kind = wtkResumen then
    begin
      semi := Round(r.Bottom - r.Top);   // alto del capitel
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := COL_RESUMEN;
      Canvas.Pen.Style := psClear;

      // Capitel izquierdo: triangulo con la punta hacia abajo.
      Pts[0] := Point(Round(r.Left), Round(r.Top));
      Pts[1] := Point(Round(r.Left) + semi, Round(r.Top));
      Pts[2] := Point(Round(r.Left), Round(r.Bottom) + semi);
      Pts[3] := Pts[0];
      Canvas.Polygon(Pts);

      // Capitel derecho: simetrico.
      Pts[0] := Point(Round(r.Right), Round(r.Top));
      Pts[1] := Point(Round(r.Right) - semi, Round(r.Top));
      Pts[2] := Point(Round(r.Right), Round(r.Bottom) + semi);
      Pts[3] := Pts[0];
      Canvas.Polygon(Pts);

      Canvas.Pen.Style := psSolid;
      Canvas.Brush.Style := bsClear;
    end;

    // ---- Badges de etiquetas: puntos de color al inicio de la barra ----
    // Estilo Trello. Van DENTRO de la barra, pegados a su borde izquierdo, que
    // es donde no estorban al texto (que se pinta a la derecha).
    if Length(FOrden[i].ColoresTag) > 0 then
    begin
      xTag := Round(r.Left) + 3;
      cy := Round((r.Top + r.Bottom) / 2);
      Canvas.Pen.Style := psClear;
      Canvas.Brush.Style := bsSolid;
      for k := 0 to High(FOrden[i].ColoresTag) do
      begin
        // No desbordar la barra: si no caben todos, se cortan.
        if xTag + TAM_BADGE > r.Right - 2 then Break;
        Canvas.Brush.Color := FOrden[i].ColoresTag[k];
        Canvas.Ellipse(xTag, cy - TAM_BADGE div 2,
                       xTag + TAM_BADGE, cy + TAM_BADGE div 2);
        Inc(xTag, TAM_BADGE + 2);
      end;
      Canvas.Pen.Style := psSolid;
      Canvas.Brush.Style := bsClear;
    end;

    // ---- Titulo a la DERECHA de la barra ----
    // Dentro de la barra el texto se corta en tareas cortas (una barra de 2
    // dias no admite "1.1.2 Validacion de cargas"); fuera siempre se lee.
    Txt := FOrden[i].Titulo;
    if Txt = '' then Continue;

    TxtX := Round(r.Right) + 6;
    TxtY := Round(r.Top + (r.Bottom - r.Top) / 2) - (Canvas.TextHeight('Ag') div 2);
    if TxtX > ClientWidth then Continue;

    if Kind = wtkResumen then
    begin
      Canvas.Font.Style := [fsBold];
      Canvas.Font.Color := COL_TXT_RESUMEN;
      // El resumen es una banda fina: centrar su texto en la FILA, no en ella.
      TxtY := Round(r.Top) - 2;
    end
    else
    begin
      Canvas.Font.Style := [];
      if EsCritica then
        Canvas.Font.Color := COL_TXT_CRITICO
      else
        Canvas.Font.Color := COL_TXT_NORMAL;
    end;

    Canvas.TextOut(TxtX, TxtY, Txt);
  end;

  Canvas.Font.Style := [];

  PintarDependencias;
end;

procedure TGanttControlTareas.PintarDependencias;
var
  I, iFrom, iTo: Integer;
  rF, rT: TRectF;
  x1, y1, x2, y2, xCodo: Integer;
  Sale: Boolean;
begin
  if Length(FLinks) = 0 then Exit;
  if (FNodeIdToIdx = nil) or (FNodeIndexToLayoutIndex = nil) then Exit;

  Canvas.Pen.Color := COL_FLECHA;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
  Canvas.Brush.Color := COL_FLECHA;
  Canvas.Brush.Style := bsSolid;

  for I := 0 to High(FLinks) do
  begin
    if not RectDeNodo(FLinks[I].FromNodeId, rF) then Continue;
    if not RectDeNodo(FLinks[I].ToNodeId, rT) then Continue;

    // Culling: si las dos barras estan fuera de la vista, no hay nada que
    // pintar (con proyectos grandes esto ahorra la mayor parte del trabajo).
    if ((rF.Bottom < 0) and (rT.Bottom < 0)) or
       ((rF.Top > ClientHeight) and (rT.Top > ClientHeight)) then Continue;

    y1 := Round((rF.Top + rF.Bottom) / 2);
    y2 := Round((rT.Top + rT.Bottom) / 2);

    // FS (lo habitual): sale por la DERECHA del predecesor y entra por la
    // IZQUIERDA del sucesor. SS: sale por la izquierda de ambos.
    Sale := FLinks[I].LinkType in [ltFinishStart, ltFinishFinish];
    if Sale then x1 := Round(rF.Right) else x1 := Round(rF.Left);
    if FLinks[I].LinkType in [ltFinishFinish, ltStartFinish] then
      x2 := Round(rT.Right)
    else
      x2 := Round(rT.Left);

    // --- Trazado ORTOGONAL (solo tramos rectos, como MS Project) ---
    // Con una linea recta punto a punto las flechas cruzaban las barras en
    // diagonal y el grafico se volvia ilegible.
    if x2 >= x1 + GAP_FLECHA * 2 then
    begin
      // Hay sitio: salir un poco, bajar/subir, y entrar en horizontal.
      xCodo := x1 + GAP_FLECHA;
      Canvas.MoveTo(x1, y1);
      Canvas.LineTo(xCodo, y1);
      Canvas.LineTo(xCodo, y2);
      Canvas.LineTo(x2 - 6, y2);
    end
    else
    begin
      // El sucesor empieza ANTES: hay que rodear por debajo de la fila del
      // predecesor para no atravesar su barra.
      Canvas.MoveTo(x1, y1);
      Canvas.LineTo(x1 + GAP_FLECHA, y1);
      if y2 > y1 then
        Canvas.LineTo(x1 + GAP_FLECHA, y1 + ALTO_RODEO)
      else
        Canvas.LineTo(x1 + GAP_FLECHA, y1 - ALTO_RODEO);
      if y2 > y1 then
      begin
        Canvas.LineTo(x2 - GAP_FLECHA, y1 + ALTO_RODEO);
        Canvas.LineTo(x2 - GAP_FLECHA, y2);
      end
      else
      begin
        Canvas.LineTo(x2 - GAP_FLECHA, y1 - ALTO_RODEO);
        Canvas.LineTo(x2 - GAP_FLECHA, y2);
      end;
      Canvas.LineTo(x2 - 6, y2);
    end;

    // Punta de flecha, siempre apuntando a la derecha (hacia la barra).
    Canvas.Polygon([
      Point(x2, y2),
      Point(x2 - 6, y2 - 4),
      Point(x2 - 6, y2 + 4)]);
  end;

  Canvas.Brush.Style := bsClear;
end;

function TGanttControlTareas.RectDeNodo(const ANodeId: Integer;
  out ARect: TRectF): Boolean;
var
  NodeIdx, LayoutIdx: Integer;
begin
  Result := False;
  if not FNodeIdToIdx.TryGetValue(ANodeId, NodeIdx) then Exit;
  if not FNodeIndexToLayoutIndex.TryGetValue(NodeIdx, LayoutIdx) then Exit;
  if (LayoutIdx < 0) or (LayoutIdx > High(FNodeLayouts)) then Exit;

  ARect := FNodeLayouts[LayoutIdx].Rect;
  ARect.Offset(-FScrollX, -FScrollY);   // world -> pantalla
  Result := True;
end;

procedure TGanttControlTareas.AplicarCalendario(const ACal: TCentreCalendar);
var
  Destino: TCentreCalendar;
  D: Integer;
begin
  if ACal = nil then Exit;
  // GetCalendar crea el calendario si no existe, asi que esto siempre devuelve
  // uno valido para el centro 0 (el que usan las tareas de proyecto).
  Destino := GetCalendar(0);
  if Destino = nil then Exit;

  Destino.Name := ACal.Name;
  for D := 1 to 7 do
    Destino.SetDayNonWorkingPeriods(D, ACal.WeeklyRulePeriodsForDate(
      // Una fecha cualquiera cuyo dia ISO de la semana sea D: el 2024-01-01 fue
      // lunes (ISO 1), asi que sumando D-1 dias se recorren los siete.
      EncodeDate(2024, 1, 1) + (D - 1)));

  Invalidate;
end;

procedure TGanttControlTareas.SetMetricasFila(
  const AAltoFila, ADesplazamientoY: Integer);
begin
  FAltoFila := AAltoFila;
  FDesplazamientoY := ADesplazamientoY;
  RebuildLayout;
  Invalidate;
end;

procedure TGanttControlTareas.SoltarRaton;
begin
  if GetCapture = Handle then
    ReleaseCapture;

  // Limpiar tambien el estado de arrastre de la clase base: sin esto el
  // siguiente MouseMove reanudaria un drag que el usuario nunca empezo.
  FMouseDownNodeIndex := -1;
  FMouseDownOnHandle := nhNone;
  Screen.Cursor := crDefault;
end;

procedure TGanttControlTareas.ScrollVerticalA(const AY: Single);
var
  Y, MaxY: Single;
begin
  Y := AY;
  if Y < 0 then Y := 0;
  // No pasar del final del contenido, o quedaria area vacia bajo la ultima
  // fila y el grid y el Gantt dejarian de coincidir.
  MaxY := FContentHeight - ClientHeight;
  if MaxY < 0 then MaxY := 0;
  if Y > MaxY then Y := MaxY;

  if SameValue(Y, FScrollY, 0.5) then Exit;
  FScrollY := Y;
  UpdateScrollBars;
  Invalidate;
end;

function TGanttControlTareas.NodeIdBajoCursor: Integer;
var
  P: TPoint;
  Fila, Alto: Integer;
begin
  Result := 0;
  P := ScreenToClient(Mouse.CursorPos);
  if (P.Y < 0) or (P.Y > ClientHeight) then Exit;

  Alto := FAltoFila;
  if Alto <= 0 then Alto := RowHeight + RowGap;

  // Que fila hay en esa Y, en coordenadas de mundo (sumando el scroll).
  Fila := Trunc((P.Y + FScrollY - RowTopMargin - FDesplazamientoY) / Alto);
  Result := GetRowNodeId(Fila);
end;

function TGanttControlTareas.NumFilas: Integer;
begin
  Result := Length(FRowNodeId);
end;

procedure TGanttControlTareas.ScrollAlFinal;
begin
  // ScrollVerticalA ya recorta al maximo permitido.
  ScrollVerticalA(FContentHeight);
end;

function TGanttControlTareas.EnElFinal: Boolean;
var
  MaxY: Single;
begin
  MaxY := FContentHeight - ClientHeight;
  if MaxY <= 0 then
    Result := True    // cabe todo: no hay scroll, siempre se ve el final
  else
    Result := FScrollY >= MaxY - 1;
end;

procedure TGanttControlTareas.SetFilaResaltada(const ANodeId: Integer);
var
  I: Integer;
begin
  if FNodeIdResaltado = ANodeId then Exit;
  FNodeIdResaltado := ANodeId;

  // Repintar el fondo SIN rehacer el layout: RebuildLayout recalcula todas las
  // barras (caro y, sobre todo, propenso a que otra llamada posterior pise el
  // color). Basta con reasignar el bkColor de las filas ya construidas.
  for I := 0 to High(FRows) do
  begin
    if (I <= High(FRowNodeId)) and (FRowNodeId[I] > 0) and
       (FRowNodeId[I] = ANodeId) then
      FRows[I].bkColor := COL_FILA_SEL
    else
      FRows[I].bkColor := $00F7F7F7;
  end;

  Invalidate;   // invalida tambien el frame cache (override de la clase base)
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
  altoFila, altoBarra, padTop: Integer;
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

  // Alto de fila: el que inyecta la vista (medido del cxTreeList real) o, si no
  // se ha inyectado, el default del control.
  altoFila := FAltoFila;
  if altoFila <= 0 then altoFila := RowHeight + RowGap;
  // Alto de la barra: la fila menos un margen, con un minimo legible.
  altoBarra := Max(8, altoFila - 10);
  padTop := Max(1, (altoFila - altoBarra) div 2);

  y := RowTopMargin + FDesplazamientoY;
  nodeById := BuildDataIdMap;
  // Guardar una copia para Paint (el overlay lo necesita en cada frame y no
  // debe reconstruirlo).
  FreeAndNil(FNodeIdToIdx);
  FNodeIdToIdx := TDictionary<Integer, Integer>.Create(nodeById);
  try
    // Una fila por tarea VISIBLE, en el orden WBS inyectado.
    for i := 0 to High(FOrden) do
    begin
      if not FOrden[i].Visible then Continue;
      // OJO: aunque la tarea no tenga TNode asociado, la FILA se crea igual.
      // Saltarsela desplazaria hacia arriba todas las barras siguientes y el
      // Gantt dejaria de cuadrar fila a fila con el grid WBS de la izquierda.
      // Lo mismo vale para las cabeceras de PROYECTO (nivel 0), que nunca
      // tienen TNode.
      if FOrden[i].EsProyecto or
         (not nodeById.TryGetValue(FOrden[i].NodeId, nodeIdx)) then
        nodeIdx := -1;
      if nodeIdx >= 0 then
        node := FNodes[nodeIdx]
      else
        node := Default(TNode);

      SetLength(FRowNodeId, Length(FRowNodeId) + 1);
      FRowNodeId[High(FRowNodeId)] := FOrden[i].NodeId;

      // CentreId = 0 en TODAS las filas, no el indice de fila: es la clave con
      // la que el render base busca el calendario laborable para sombrear los
      // fines de semana (GetCalendar(Row.CentreId)). Con el indice de fila,
      // solo la fila 0 encontraba calendario y el resto salia sin sombrear.
      row.CentreId := 0;
      row.TopY := y;
      row.Height := altoFila;
      row.LaneCount := 1;
      row.Order := Length(FRows);
      row.Visible := True;
      row.Enabled := True;
      // Fondo de la fila. El render base lo pinta antes que las barras
      // (SetBrushColor(FillBrush, row.bkColor)), asi que la fila seleccionada
      // se marca aqui y NO hace falta tocar uGanttControl.
      if (FNodeIdResaltado > 0) and (FOrden[i].NodeId = FNodeIdResaltado) and
         (not FOrden[i].EsProyecto) then
        row.bkColor := COL_FILA_SEL
      else
        row.bkColor := $00F7F7F7;
      row.NameRect := TRectF.Create(0, y, 0, y + row.Height);
      row.GanttRect := TRectF.Create(0, y, 0, y + row.Height);
      row.FirstNodeLayout := Length(FNodeLayouts);

      // Barra de la tarea. Hito (duracion 0) = cuadradito centrado; resumen y
      // tarea = barra normal (el pintado especial de resumen/hito es Fase 1.b).
      if (nodeIdx >= 0) and (node.StartTime <> 0) and (node.EndTime <> 0) then
      begin
        nl.NodeIndex := nodeIdx;
        nl.CentreId := node.CentreId;
        nl.LaneIndex := 0;
        nl.LoteId := 0;
        nl.LoteCount := 0;
        // Geometria por tipo de tarea (estilo MS Project / GanttPRO):
        case FOrden[i].Kind of
          wtkHito:
            // Hito: cuadrado centrado en el instante; PaintOverlay lo remata
            // como rombo (girado 45) tapando las esquinas.
            nl.Rect := TRectF.Create(
              TimeToXWorld(node.StartTime) - altoBarra * 0.6,
              y + padTop,
              TimeToXWorld(node.StartTime) + altoBarra * 0.6,
              y + padTop + altoBarra);

          wtkResumen:
            // Resumen: barra gruesa pegada arriba (no una banda fina: se
            // confundia con una tarea estrecha). Los capiteles en los extremos,
            // que pinta el overlay, la identifican como contenedora.
            nl.Rect := TRectF.Create(
              TimeToXWorld(node.StartTime),
              y + padTop,
              TimeToXWorld(node.EndTime),
              y + padTop + Max(6, Round(altoBarra * 0.55)));
        else
          nl.Rect := TRectF.Create(
            TimeToXWorld(node.StartTime),
            y + padTop,
            TimeToXWorld(node.EndTime),
            y + padTop + altoBarra);
        end;
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

  // OBLIGATORIO tras reconstruir FNodeLayouts: DrawDependenciesD2D resuelve las
  // flechas via FNodeIndexToLayoutIndex y, si no se reindexa aqui, se queda
  // vacio y NO se pinta ninguna dependencia. La clase base lo hace en
  // RebuildAfterModelChange, pero a RebuildLayout se llega tambien por otros
  // caminos (SetData, zoom, resize).
  RebuildNodeLayoutIndex;

  UpdateScrollBars;
  if Assigned(FOnLayoutChanged) then FOnLayoutChanged(Self);
end;

end.
