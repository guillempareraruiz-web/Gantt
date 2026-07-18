unit uVistaProyectos;

{
  Modulo de PROYECTOS (planificacion estilo MS Project, paradigma TAREAS).

  Fase 1 (esqueleto, SOLO LECTURA): a la izquierda un grid WBS jerarquico
  (cxTreeList) con Nombre / Duracion / Inicio / Fin; a la derecha el Gantt de
  tareas (TGanttControlTareas), sincronizado fila a fila por scroll vertical.

  Muestra los datos existentes de un proyecto TAREAS (p.ej. el demo ProjectId 6)
  SIN edicion. La edicion (columnas in-place, indentar, dependencias) y el motor
  de fechas son fases posteriores.

  Se abre desde el Main (boton de toolbar) segun FS_PL_Project.PlanningParadigm.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxClasses, cxEdit, cxTL, cxTLData, cxTextEdit,
  cxInplaceContainer,
  dxSkinsCore, dxSkinsDefaultPainters,
  uGanttControl, uGanttControlTareas, uGanttTypes, uGanttTimeline, uNodeDataRepo,
  uCentreCalendar,
  uErpTypes, uWbsTypes, uWbsRepo, uWbsScheduler, uWbsTareaEdit, uWbsCargaBand,
  dxSkinBasic, dxSkinBlack,
  dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue, cxFilter, dxScrollbarAnnotations, cxTLdxBarBuiltInMenu,
  Vcl.Menus, cxButtons;

const
  // Paleta del Gantt de proyectos (BGR de TColor).
  //
  // Criterio: tonos CLAROS y DESATURADOS. Una barra es informacion, no una
  // alarma: con rojo y naranja puros toda la pantalla gritaba y no se
  // distinguia lo urgente de lo normal. El rojo saturado se reserva para la
  // unica senal que debe destacar de verdad (desviacion real).
  COL_PRJ_TAREA          = $00C9A46B;   // azul claro apagado
  COL_PRJ_TAREA_BORDE    = $00A87F44;
  COL_PRJ_CRITICA        = $008A8ADF;   // rojo suave (terracota), no rojo puro
  COL_PRJ_CRITICA_BORDE  = $006B6BC4;
  COL_PRJ_RESUMEN        = $00807366;   // gris azulado medio
  COL_PRJ_RESUMEN_BORDE  = $00665C50;

  // Metricas de fila, FIJAS e identicas en el grid y en el Gantt (enfoque
  // GanttPRO). Medir el alto real del cxTreeList no es viable de forma estable,
  // y un pixel de diferencia se acumula hasta desfasar una fila entera.
  ALTO_FILA     = 24;   // alto de cada fila, impuesto via OnGetNodeHeight
  // Alto de la banda superior = ROW_TOTAL_H de la regla (16 mes + 16 semana +
  // 16 dias = 48). Con menos, la tercera banda (la de los DIAS) queda cortada y
  // solo se ven mes y semana. La cabecera del grid se iguala a este valor para
  // que las filas arranquen a la misma altura a ambos lados.
  // ROW_TOTAL_H (48) es lo que necesita la regla para sus tres bandas, pero la
  // cabecera del grid mide algo mas: sin este pequeno extra las barras quedan
  // unos pixeles por encima de su fila.
  ALTO_CABECERA = ROW_TOTAL_H + 5;
  // Alto REAL de la cabecera de columnas del cxTreeList. No se puede imponer ni
  // consultar de forma fiable en esta version, asi que se toma como constante:
  // si la cabecera del grid y la regla no quedan a la misma altura, ESTE es el
  // valor a tocar.
  ALTO_CABECERA_GRID = 24;
  // Alto de la barra de scroll horizontal del grid. Ocupa sitio ABAJO, asi que
  // el area util del arbol es menor que la del Gantt y las ultimas filas no
  // acababan de cuadrar. El Gantt reserva el mismo hueco.
  ALTO_SCROLLBAR_H = 17;

  // Clave de la preferencia de usuario donde se guarda que proyectos se estan
  // mostrando (lista de ProjectId separados por comas).
  PREF_KEY_PROYECTOS = 'VistaProyectos.Seleccion';

type
  TfrmVistaProyectos = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlLeft: TPanel;
    // Banda superior del panel izquierdo: iguala la altura de la regla de
    // fechas para que las filas del grid y del Gantt arranquen a la par, y
    // sirve de contenedor para el titulo e iconos de la zona WBS.
    pnlCabeceraWbs: TPanel;
    lblCabeceraWbs: TLabel;
    tlWbs: TcxTreeList;
    colNombre: TcxTreeListColumn;
    colDuracion: TcxTreeListColumn;
    colInicio: TcxTreeListColumn;
    colFin: TcxTreeListColumn;
    colHolgura: TcxTreeListColumn;
    colAvance: TcxTreeListColumn;
    splMain: TSplitter;
    pnlRight: TPanel;
    btnConfigProyectos: TcxButton;
    btnTreeWide: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    // TcxTreeListGetContentStyleEvent: el orden es (Sender, AColumn, ANode).
    procedure tlWbsStylesGetContentStyle(Sender: TcxCustomTreeList;
      AColumn: TcxTreeListColumn; ANode: TcxTreeListNode;
      var AStyle: TcxStyle);
    // Impone ALTO_FILA a todas las filas, para que el grid y el Gantt cuadren.
    procedure tlWbsGetNodeHeight(Sender: TcxCustomTreeList;
      ANode: TcxTreeListNode; var AHeight: Integer);
    // Acordeon: plegar/desplegar una rama del grid oculta o muestra sus filas
    // en el Gantt, para que ambos lados sigan cuadrando fila a fila.
    procedure tlWbsCollapsed(Sender: TcxCustomTreeList; ANode: TcxTreeListNode);
    procedure tlWbsExpanded(Sender: TcxCustomTreeList; ANode: TcxTreeListNode);
    // Al cambiar la fila seleccionada del arbol, resaltar su barra en el Gantt.
    procedure tlWbsFocusedNodeChanged(Sender: TcxCustomTreeList;
      APrevFocusedNode, AFocusedNode: TcxTreeListNode);
    // Abre el selector multi-proyecto. Va en la zona publicada del form (no en
    // private) porque lo asigna el DFM.
    procedure btnConfigProyectosClick(Sender: TObject);
    // Doble clic sobre una fila: editar la tarea (duracion / horas invertidas).
    procedure tlWbsDblClick(Sender: TObject);
    procedure btnTreeWideClick(Sender: TObject);
  private
    FGantt: TGanttControlTareas;
    FTimeline: TGanttTimelineControl;   // regla de fechas sobre el Gantt
    FPieGantt: TPanel;                  // iguala la scrollbar horizontal del grid
    // Banda de carga por operario, bajo el Gantt (plegable).
    FCargaBand: TWbsCargaBand;
    FSplitCarga: TSplitter;
    FBtnCarga: TcxButton;
    FProjectId: Integer;            // proyecto de entrada (el que abre el Main)
    // Multi-proyecto: la vista puede mostrar VARIOS proyectos TAREAS a la vez,
    // cada uno como una rama de NIVEL 0 con su nombre. FTareas es la union de
    // todos, ya planificada; cada proyecto se calcula por separado.
    FProyectos: TWbsProyectoArray;      // los que se estan mostrando
    FTodosProyectos: TWbsProyectoArray; // todos los TAREAS (para el selector)
    FTareas: TWbsTaskArray;
    FLinks: TWbsLinkArray;
    FNodeToTLNode: TDictionary<Integer, TcxTreeListNode>;
    FNodeDataRepo: TNodeDataRepo;   // NodeData del proyecto (el Gantt lo necesita)
    // Un motor por proyecto: el CPM es independiente, no hay dependencias
    // entre proyectos. Clave = ProjectId.
    FSchedulers: TObjectDictionary<Integer, TWbsScheduler>;
    FResultado: TWbsSchedulerResult;
    FStyleCritica: TcxStyle;        // fila del camino critico (rojo)
    FStyleResumen: TcxStyle;        // fila de tarea resumen (negrita)
    FTLNodeToNodeId: TDictionary<TcxTreeListNode, Integer>;
    // Fila de nivel 0 de cada proyecto (ProjectId -> nodo del arbol). Hace
    // falta fuera de ConstruirArbol para poder restaurar su plegado.
    FRaicesProyecto: TDictionary<Integer, TcxTreeListNode>;
    // Etiquetas (V081) de todas las tareas cargadas, para pintar los badges
    // del Gantt sin una consulta por tarea.
    FTagsPorNodo: TDictionary<Integer, TArray<Integer>>;
    FColorPorTag: TDictionary<Integer, Integer>;


        // Regla y Gantt comparten viewport horizontal: cada uno sigue al otro.
    // FSincronizando corta la recursion (A mueve a B, B avisa y movería a A).
    FSincronizando: Boolean;
    // True mientras se reconstruye el arbol: silencia los OnExpanded/OnCollapsed
    // que dispara FullExpand.
    FConstruyendo: Boolean;
    // Corta la recursion al sincronizar el scroll vertical grid <-> Gantt
    // (mover uno mueve el otro, que volveria a avisar).
    FSincronizandoScroll: Boolean;
    // Sincronia grid -> Gantt. El cxTreeList de esta version NO expone ningun
    // evento de scroll (ni OnTopRecordIndexChanged ni equivalente), asi que se
    // vigila su fila superior con un timer corto: es la unica via que no
    // depende de API que no se puede verificar. El coste es ridiculo (una
    // comparacion de punteros cada 60 ms) y solo actua cuando cambia.
    FTimerScroll: TTimer;
    FUltimoTopNode: TcxTreeListNode;
    // Apertura diferida de la ficha de tarea (ver PedirEditarTarea).
    FTimerEditar: TTimer;
    FNodeIdPendiente: Integer;
    procedure TimerScrollTick(Sender: TObject);
    // True si el arbol ya no puede desplazarse mas hacia abajo.
    function GridEnElFinal: Boolean;
    // Ancho que necesita el arbol para verse entero (columnas + borde).
    // Sirve para dimensionar el panel y para deducir si esta saliendo la
    // barra de scroll horizontal.
    function AnchoNecesarioGrid: Integer;
    // Ajusta el hueco inferior del Gantt al alto real que ocupa la barra de
    // scroll horizontal del grid (aparece y desaparece segun el ancho).
    procedure AjustarPieGantt;
    // Banda de carga por operario: cargar datos, mostrar/ocultar y mantenerla
    // alineada con el arbol (ancho de nombres) y con el Gantt (eje de tiempo).
    procedure CargarBandaOperarios;
    procedure SincronizarBanda;
    procedure ToggleBandaOperarios;
    procedure BtnCargaClick(Sender: TObject);


    // Resultado del motor para un nodo, sea del proyecto que sea. Sustituye a
    // FScheduler.TryGet ahora que hay un motor por proyecto.
    function TryGetSched(const ANodeId: Integer; out ASched: TWbsSchedule): Boolean;
    // Calendario laborable comun (el del primer motor; todos usan el mismo).
    function CalendarioComun: TCentreCalendar;

    // Ficha de tarea (doble clic en el grid o en una barra del Gantt).
    procedure EditarTarea(ANodeId: Integer);
    // Difiere la apertura de la ficha al siguiente ciclo de mensajes, para no
    // abrir un modal en medio del procesado del doble clic.
    procedure PedirEditarTarea(ANodeId: Integer);
    procedure TimerEditarTick(Sender: TObject);
    procedure GanttDblClick(Sender: TObject);
    function CatalogoOperarios: TWbsOperarioItems;
    // Alta de una etiqueta desde el chip "+" de la ficha. Devuelve su TagId.
    function CrearTag(const ATag: TWbsTag): Integer;

    // Edicion directa sobre el Gantt: crear dependencias (Ctrl + arrastrar
    // desde el handle) y mover/redimensionar barras.
    procedure GanttDependenciaCreada(Sender: TObject;
      const AFromNodeId, AToNodeId, ATipoLink: Integer);
    procedure GanttBarraModificada(Sender: TObject; const ANodeId: Integer;
      const AInicio, AFin: TDateTime);
    function MinutosLaborablesEntre(const AIni, AFin: TDateTime): Double;

    procedure ElegirProyectos;           // selector multi-proyecto
    function CargarSeleccionGuardada: TArray<Integer>;
    procedure GuardarSeleccion;

    procedure CargarDatos;
    procedure RecalcularFechas;
    procedure SincronizarAlturaFilas;
    procedure SincronizarPlegado;   // acordeon grid -> Gantt
    // El plegado del arbol se pierde al reconstruirlo (FullExpand). Estas dos
    // lo capturan antes y lo devuelven despues, para que editar una tarea no
    // deje al usuario con todo el arbol desplegado otra vez.
    function CapturarPlegado: TArray<Integer>;
    procedure RestaurarPlegado(const APlegados: TArray<Integer>);
    // Recarga completa conservando el estado de la vista (plegado, zoom y
    // posicion del viewport). Sin esto, cualquier edicion devolvia al usuario
    // al zoom inicial y al principio del proyecto.
    procedure RecargarConservandoVista;
    // True si la fila se ve realmente en el grid (ningun ancestro plegado).
    function FilaDesplegada(ANode: TcxTreeListNode): Boolean;
    procedure ConstruirArbol;
    procedure ConstruirGantt;
    procedure AjustarZoomFit(const AIni, AFin: TDateTime);
    procedure GanttScrollYChanged(Sender: TObject; const AScrollY: Single);

    procedure TimelineViewportChanged(Sender: TObject;
      const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
    procedure GanttViewportChanged(Sender: TObject;
      const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
    function RangoFechas(out AIni, AFin: TDateTime): Boolean;
  public
    // Carga y muestra el proyecto (paradigma TAREAS). El form se usa EMBEBIDO
    // en el Main (Parent := Form1, Align := alClient), como uVistaGantt.
    procedure Inicializar(AProjectId: Integer);
  end;

implementation

{$R *.dfm}

uses
  System.DateUtils, System.Math, Vcl.Dialogs, Data.Win.ADODB,
  uDMPlanner, uNodesRepo, uRowFilterDialog, uUserPreferencesRepo;

procedure TfrmVistaProyectos.Inicializar(AProjectId: Integer);
begin
  FProjectId := AProjectId;
  try
    CargarDatos;
    RecalcularFechas;   // Fase 2: CPM sobre calendario laborable
    ConstruirArbol;
    ConstruirGantt;
  except
    on E: Exception do
      // Mostrar el error real (clase + mensaje) en vez de un Access Violation
      // ciego, para diagnosticar durante el desarrollo del modulo.
      Vcl.Dialogs.MessageDlg(
        'Error al construir la vista de proyectos:'#13#10#13#10 +
        E.ClassName + ': ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmVistaProyectos.FormCreate(Sender: TObject);
begin
  FNodeToTLNode := TDictionary<Integer, TcxTreeListNode>.Create;
  FNodeDataRepo := TNodeDataRepo.Create;

  // Boton para elegir que proyectos se ven a la vez (multi-proyecto).
  FTLNodeToNodeId := TDictionary<TcxTreeListNode, Integer>.Create;
  FRaicesProyecto := TDictionary<Integer, TcxTreeListNode>.Create;
  FTagsPorNodo := TDictionary<Integer, TArray<Integer>>.Create;
  FColorPorTag := TDictionary<Integer, Integer>.Create;
  // Un motor de fechas POR PROYECTO (CPM independiente). Se crean en
  // RecalcularFechas segun los proyectos que se esten mostrando.
  FSchedulers := TObjectDictionary<Integer, TWbsScheduler>.Create([doOwnsValues]);

  // Estilos de fila del grid WBS (mismo patron que el grid de Backlog):
  // camino critico en rojo, tareas resumen en negrita.
  FStyleCritica := TcxStyle.Create(Self);
  FStyleCritica.TextColor := $005B5BB8;   // terracota, a juego con la barra
  FStyleCritica.Color := $00F2F2FC;       // rosa apenas perceptible de fondo
  FStyleResumen := TcxStyle.Create(Self);
  FStyleResumen.Font.Style := [fsBold];
  tlWbs.Styles.OnGetContentStyle := tlWbsStylesGetContentStyle;
  // Alto de fila fijo: es la mitad del contrato de alineacion con el Gantt (la
  // otra mitad la pone SincronizarAlturaFilas).
  tlWbs.OnGetNodeHeight := tlWbsGetNodeHeight;
  // Acordeon: al plegar/desplegar una rama, ocultar/mostrar sus filas del Gantt.
  tlWbs.OnCollapsed := tlWbsCollapsed;
  tlWbs.OnExpanded := tlWbsExpanded;
  // Doble clic = editar la tarea (duracion / horas invertidas).
  tlWbs.OnDblClick := tlWbsDblClick;
  // Seleccionar una fila del arbol resalta su barra en el Gantt.
  tlWbs.OnFocusedNodeChanged := tlWbsFocusedNodeChanged;

  // Vigilancia del scroll del grid (ver comentario del campo FTimerScroll).
  FTimerScroll := TTimer.Create(Self);
  FTimerScroll.Interval := 60;
  FTimerScroll.OnTimer := TimerScrollTick;
  FTimerScroll.Enabled := True;

  // Apertura diferida de la ficha (ver PedirEditarTarea): arranca parado y se
  // dispara una sola vez por doble clic.
  FTimerEditar := TTimer.Create(Self);
  FTimerEditar.Interval := 1;
  FTimerEditar.OnTimer := TimerEditarTick;
  FTimerEditar.Enabled := False;
  // El alto de la cabecera del cxTreeList NO se puede imponer (esta version no
  // expone OptionsView.HeaderHeight) y es menor que el de la regla de fechas,
  // que necesita 48 px para sus tres bandas (mes/semana/dia). Para que las
  // filas arranquen a la misma altura a ambos lados se mete un espaciador
  // encima del grid con la diferencia: asi la cabecera del grid acaba justo
  // donde acaba la regla.
  // Rejilla: NINGUNA. Los recuadros de celda encajonan cada dato y ensucian la
  // lectura del arbol; sin ellos la jerarquia se sigue mucho mejor. Esta version
  // del cxTreeList solo admite tlglNone o tlglBoth (no hay solo-horizontales).
  // Se fija por codigo porque el IDE reescribe el .dfm al abrir el form en el
  // disenador y se pierden estas propiedades.
  tlWbs.OptionsView.GridLines := tlglNone;
  tlWbs.OptionsView.Indicator := False;



  // Boton para mostrar/ocultar la banda de carga por operario. Se crea por
  // codigo, junto a los otros dos de la cabecera del arbol.
  FBtnCarga := TcxButton.Create(Self);
  FBtnCarga.Parent := pnlCabeceraWbs;
  FBtnCarga.SetBounds(btnTreeWide.Left - 24, btnTreeWide.Top, 20, 19);
  FBtnCarga.Anchors := [akTop, akRight];
  FBtnCarga.Caption := #$25A4;   // simbolo de banda/tabla
  FBtnCarga.Hint := 'Mostrar la carga por operario';
  FBtnCarga.ShowHint := True;
  FBtnCarga.LookAndFeel.Kind := lfUltraFlat;
  FBtnCarga.LookAndFeel.NativeStyle := False;
  FBtnCarga.OnClick := BtnCargaClick;

  // El OnClick deberia venir del DFM; se asigna tambien aqui por si el
  // disenador lo pierde al reescribir el fichero.
  btnConfigProyectos.OnClick := btnConfigProyectosClick;
  btnConfigProyectos.Hint := 'Elegir que proyectos se muestran';
  btnConfigProyectos.ShowHint := True;


  // Control de Gantt de tareas a la derecha (creado en codigo, como en el resto
  // de vistas de Gantt del proyecto).
  // Regla de fechas: control propio anclado arriba (mismo patron que
  // uVistaGantt). Ocupa la banda que en el grid ocupa la cabecera de columnas,
  // por eso su alto es ALTO_CABECERA.
  FTimeline := TGanttTimelineControl.Create(Self);
  FTimeline.Parent := pnlRight;
  FTimeline.Align := alTop;
  FTimeline.Height := ALTO_CABECERA;   // 48 = su alto natural (mes/semana/dia)
  FTimeline.LeftWidth := 0;

  // Banda de carga por operario: ocupa TODO el ancho del form (no solo el lado
  // del Gantt) para que su columna de nombres quede exactamente bajo el arbol,
  // igual que las celdas de dia quedan bajo las barras.
  FCargaBand := TWbsCargaBand.Create(Self);
  FCargaBand.Parent := Self;
  FCargaBand.Align := alBottom;
  FCargaBand.Height := 0;          // arranca plegada
  FCargaBand.Visible := False;

  FSplitCarga := TSplitter.Create(Self);
  FSplitCarga.Parent := Self;
  FSplitCarga.Align := alBottom;
  FSplitCarga.Height := 4;
  FSplitCarga.Visible := False;

  // Franja inferior que iguala la barra de scroll horizontal del grid: sin
  // ella el Gantt tiene mas alto util que el arbol y las ultimas filas se
  // desalinean.
  FPieGantt := TPanel.Create(Self);
  FPieGantt.Parent := pnlRight;
  FPieGantt.Align := alBottom;
  FPieGantt.Height := ALTO_SCROLLBAR_H;
  FPieGantt.BevelOuter := bvNone;
  FPieGantt.Color := clWhite;
  FPieGantt.ParentBackground := False;

  FGantt := TGanttControlTareas.Create(Self);
  FGantt.Parent := pnlRight;
  FGantt.Align := alClient;
  FGantt.ShowHint := True;
  FGantt.OnScrollYChanged := GanttScrollYChanged;
  FGantt.OnDblClick := GanttDblClick;
  // Edicion directa sobre las barras (Fase 3).
  FGantt.OnDependenciaCreada := GanttDependenciaCreada;
  FGantt.OnBarraModificada := GanttBarraModificada;

  // Mantener la regla y el Gantt en el mismo viewport horizontal (en ambos
  // sentidos: se arrastra/hace zoom indistintamente sobre cualquiera de los dos).
  FTimeline.OnViewportChanged := TimelineViewportChanged;
  FGantt.OnViewportChanged := GanttViewportChanged;

  pnlLeft.Width := (colNombre.Width + 10);
end;

procedure TfrmVistaProyectos.TimerScrollTick(Sender: TObject);
var
  Top: TcxTreeListNode;
  Fila, I: Integer;
begin
  if FSincronizandoScroll or FConstruyendo then Exit;
  if (FGantt = nil) or (tlWbs.AbsoluteVisibleCount = 0) then Exit;

  // La barra horizontal del grid aparece/desaparece al cambiar el ancho del
  // panel, y eso altera el alto util del arbol: hay que reajustar el hueco
  // inferior del Gantt antes de comparar posiciones.
  AjustarPieGantt;

  Top := tlWbs.TopVisibleNode;
  if Top = FUltimoTopNode then Exit;   // no se ha movido: nada que hacer
  FUltimoTopNode := Top;
  if Top = nil then Exit;

  // La posicion se toma del INDICE de la fila dentro del arbol, no buscando su
  // NodeId en el Gantt: las cabeceras de proyecto no tienen NodeId y, cuando
  // una de ellas quedaba arriba (el caso de la fila 0), no se encontraba y el
  // Gantt no se movia.
  // Ambos lados pintan las mismas filas en el mismo orden, asi que el indice
  // es directamente la fila del Gantt.
  Fila := -1;
  for I := 0 to tlWbs.AbsoluteVisibleCount - 1 do
    if tlWbs.AbsoluteVisibleItems[I] = Top then
    begin
      Fila := I;
      Break;
    end;
  if Fila < 0 then Exit;

  FSincronizandoScroll := True;
  try
    // Si el grid ya no puede bajar mas, mandar el Gantt a su tope: los dos
    // controles no tienen el mismo alto visible, asi que "que fila queda
    // arriba" no basta para colocarlos bien en el extremo.
    if GridEnElFinal then
      FGantt.ScrollAlFinal
    else
      FGantt.ScrollVerticalA(Fila * ALTO_FILA);
  finally
    FSincronizandoScroll := False;
  end;
end;

function TfrmVistaProyectos.AnchoNecesarioGrid: Integer;
var
  I: Integer;
begin
  // Suma de columnas visibles + borde. El SANGRADO del arbol NO se suma
  // aparte: la columna del nombre ya lo lleva dentro de su Width (DevExpress
  // sangra el contenido, no ensancha la columna). Sumarlo hacia el panel mas
  // ancho de la cuenta.
  Result := 6;
  for I := 0 to tlWbs.ColumnCount - 1 do
    if tlWbs.Columns[I].Visible then
      Inc(Result, tlWbs.Columns[I].Width);
end;

procedure TfrmVistaProyectos.CargarBandaOperarios;
var
  Repo: TWbsRepo;
  Carga: TWbsCargaArray;
  Ids: TArray<Integer>;
  I: Integer;
  Ini, Fin: TDateTime;
begin
  if FCargaBand = nil then Exit;
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) then Exit;

  SetLength(Ids, Length(FProyectos));
  for I := 0 to High(FProyectos) do
    Ids[I] := FProyectos[I].ProjectId;

  Repo := TWbsRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    Carga := Repo.LoadCargaOperarios(Ids);
  finally
    Repo.Free;
  end;

  if not RangoFechas(Ini, Fin) then
  begin
    Ini := Date;
    Fin := Date + 30;
  end;
  FCargaBand.SetDatos(Carga, CalendarioComun, Ini, Fin);
  SincronizarBanda;
end;

procedure TfrmVistaProyectos.BtnCargaClick(Sender: TObject);
begin
  ToggleBandaOperarios;
end;

procedure TfrmVistaProyectos.ToggleBandaOperarios;
begin
  if FCargaBand = nil then Exit;

  if FCargaBand.Visible then
  begin
    FCargaBand.Visible := False;
    FSplitCarga.Visible := False;
  end
  else
  begin
    FCargaBand.Visible := True;
    FSplitCarga.Visible := True;
    FCargaBand.Height := FCargaBand.AltoDeseado;
    CargarBandaOperarios;
  end;
end;

procedure TfrmVistaProyectos.SincronizarBanda;
begin
  if (FCargaBand = nil) or (not FCargaBand.Visible) or (FGantt = nil) then Exit;

  // La columna de nombres tiene que medir lo mismo que el panel del arbol: es
  // lo que hace que cada celda de dia caiga bajo la barra que le toca.
  FCargaBand.AnchoNombres := pnlLeft.Width + splMain.Width;
  FCargaBand.SetViewport(FGantt.StartTime, FGantt.PxPerMinute, FGantt.ScrollX);
end;

procedure TfrmVistaProyectos.AjustarPieGantt;
var
  Alto: Integer;
begin
  if (FPieGantt = nil) or (FGantt = nil) then Exit;

  // La barra horizontal del grid aparece y desaparece segun el ancho del
  // panel: el hueco que el Gantt reserva abajo tiene que seguirla, o las
  // ultimas filas dejan de cuadrar en cuanto cambia.
  // Se DEDUCE comparando lo que ocupan las columnas con el ancho disponible:
  // TcxControl.HScrollBar es protected y no se puede consultar.
  // ClientWidth ya descuenta la barra vertical si esta visible, asi que la
  // comparacion es directa.
  if AnchoNecesarioGrid > tlWbs.ClientWidth then
    Alto := ALTO_SCROLLBAR_H
  else
    Alto := 0;

  if FPieGantt.Height = Alto then Exit;
  FPieGantt.Height := Alto;
  FGantt.RebuildLayout;
  FGantt.Invalidate;
end;

function TfrmVistaProyectos.GridEnElFinal: Boolean;
var
  Actual, Tope: TcxTreeListNode;
begin
  // Se pregunta al PROPIO control en vez de calcular cuantas filas caben: el
  // alto real de fila lo decide DevExpress (no es exactamente ALTO_FILA) y
  // cualquier estimacion se desviaba justo en el extremo.
  // El truco: pedirle que ponga arriba la ultima fila. El control recorta la
  // peticion a lo maximo que admite; si el resultado es la fila que ya estaba
  // arriba, es que no se puede bajar mas.
  Result := False;
  if tlWbs.AbsoluteVisibleCount = 0 then Exit;

  Actual := tlWbs.TopVisibleNode;
  Tope := tlWbs.AbsoluteVisibleItems[tlWbs.AbsoluteVisibleCount - 1];
  if Actual = Tope then Exit(True);

  tlWbs.TopVisibleNode := Tope;
  Result := tlWbs.TopVisibleNode = Actual;
  // Dejarlo como estaba: esto es una consulta, no un movimiento.
  if not Result then
    tlWbs.TopVisibleNode := Actual;
end;

procedure TfrmVistaProyectos.GanttScrollYChanged(Sender: TObject;
  const AScrollY: Single);
var
  FilaTop, NodeId, I: Integer;
  TLNode: TcxTreeListNode;
begin
  // Panning o scroll vertical en el Gantt -> arrastrar el grid a la misma fila.
  if FSincronizandoScroll then Exit;
  if (FGantt = nil) or (ALTO_FILA <= 0) then Exit;

  // Que fila del Gantt ha quedado arriba del todo. Se REDONDEA (no se trunca):
  // a media fila de scroll el usuario ya esta viendo mayoritariamente la
  // siguiente, y truncar dejaba el grid una fila por detras.
  FilaTop := Round(AScrollY / ALTO_FILA);
  if FilaTop < 0 then FilaTop := 0;

  FSincronizandoScroll := True;
  try
    // Los EXTREMOS se tratan aparte, porque el bucle de abajo (que salta las
    // cabeceras de proyecto) no llega ni al principio ni al final:
    //   - arriba: la fila 0 suele ser una cabecera y se la saltaba.
    //   - abajo: el Gantt topa con su limite de scroll antes que el grid, y
    //     este se quedaba con filas por ver.
    if FilaTop <= 0 then
    begin
      if tlWbs.AbsoluteVisibleCount > 0 then
      begin
        TLNode := tlWbs.AbsoluteVisibleItems[0];
        tlWbs.TopVisibleNode := TLNode;
        FUltimoTopNode := TLNode;
      end;
      Exit;
    end;

    if FGantt.EnElFinal then
    begin
      if tlWbs.AbsoluteVisibleCount > 0 then
      begin
        // Llevar el grid a SU final. En vez de calcular cuantas filas caben
        // (el alto real de fila lo decide DevExpress y no coincide con
        // ALTO_FILA), se empuja la ultima fila al tope: se asigna como fila
        // superior y el propio control se encarga de recortar hasta donde
        // puede llegar de verdad.
        TLNode := tlWbs.AbsoluteVisibleItems[tlWbs.AbsoluteVisibleCount - 1];
        tlWbs.TopVisibleNode := TLNode;
        FUltimoTopNode := tlWbs.TopVisibleNode;
      end;
      Exit;
    end;
  finally
    FSincronizandoScroll := False;
  end;

  // Las cabeceras de proyecto no tienen NodeId. En vez de rendirse (que dejaba
  // el grid parado justo al pasar por encima de una), se busca la primera fila
  // siguiente que si sea una tarea.
  NodeId := 0;
  while (FilaTop < FGantt.NumFilas) do
  begin
    NodeId := FGantt.GetRowNodeId(FilaTop);
    if NodeId > 0 then Break;
    Inc(FilaTop);
  end;
  if NodeId <= 0 then Exit;
  if not FNodeToTLNode.TryGetValue(NodeId, TLNode) then Exit;

  FSincronizandoScroll := True;
  try
    // TopVisibleNode desplaza el grid sin cambiar el foco ni la seleccion.
    tlWbs.TopVisibleNode := TLNode;
    // Anotar la posicion resultante: si no, el timer la leeria como un cambio
    // hecho por el usuario y devolveria el Gantt hacia atras (rebote).
    FUltimoTopNode := TLNode;
  finally
    FSincronizandoScroll := False;
  end;
end;

procedure TfrmVistaProyectos.FormDestroy(Sender: TObject);
begin
  FNodeToTLNode.Free;
  FTLNodeToNodeId.Free;
  FRaicesProyecto.Free;
  FTagsPorNodo.Free;
  FColorPorTag.Free;
  FNodeDataRepo.Free;
  FSchedulers.Free;
  // FStyleCritica / FStyleResumen son Owned por el form: no liberar aqui.
end;

procedure TfrmVistaProyectos.tlWbsStylesGetContentStyle(
  Sender: TcxCustomTreeList; AColumn: TcxTreeListColumn;
  ANode: TcxTreeListNode; var AStyle: TcxStyle);
var
  NodeId: Integer;
  Sched: TWbsSchedule;
begin
  if not FTLNodeToNodeId.TryGetValue(ANode, NodeId) then Exit;
  if not TryGetSched(NodeId, Sched) then Exit;

  if Sched.EsResumen then
    AStyle := FStyleResumen
  else if Sched.EsCritica then
    AStyle := FStyleCritica;
end;

procedure TfrmVistaProyectos.TimelineViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
begin
  // Arrastrar o hacer zoom sobre la regla mueve tambien las barras.
  if FSincronizando or (FGantt = nil) then Exit;
  FSincronizando := True;
  try
    FGantt.SetViewport(StartTime, PxPerMinute, ScrollX);
  finally
    FSincronizando := False;
  end;
end;

procedure TfrmVistaProyectos.GanttViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
begin
  // Y al reves: rueda del raton o scroll sobre las barras mueve la regla.
  if FSincronizando or (FTimeline = nil) then Exit;
  FSincronizando := True;
  try
    FTimeline.SetViewport(StartTime, PxPerMinute, ScrollX);
  finally
    FSincronizando := False;
  end;
  // La banda de carga comparte el eje de tiempo con el Gantt.
  SincronizarBanda;
end;

procedure TfrmVistaProyectos.tlWbsGetNodeHeight(Sender: TcxCustomTreeList;
  ANode: TcxTreeListNode; var AHeight: Integer);
begin
  AHeight := ALTO_FILA;
end;

procedure TfrmVistaProyectos.tlWbsFocusedNodeChanged(Sender: TcxCustomTreeList;
  APrevFocusedNode, AFocusedNode: TcxTreeListNode);
var
  NodeId: Integer;
begin
  if FGantt = nil then Exit;

  NodeId := 0;
  if (AFocusedNode <> nil) then
    FTLNodeToNodeId.TryGetValue(AFocusedNode, NodeId);

  FGantt.SetFilaResaltada(NodeId);
end;

procedure TfrmVistaProyectos.tlWbsCollapsed(Sender: TcxCustomTreeList;
  ANode: TcxTreeListNode);
begin
  SincronizarPlegado;
end;

procedure TfrmVistaProyectos.tlWbsExpanded(Sender: TcxCustomTreeList;
  ANode: TcxTreeListNode);
begin
  SincronizarPlegado;
end;

function TfrmVistaProyectos.FilaDesplegada(ANode: TcxTreeListNode): Boolean;
var
  P: TcxTreeListNode;
begin
  // OJO: TcxTreeListNode.Visible NO significa "se ve ahora mismo" (eso es lo
  // que se asumia y por eso el acordeon no ocultaba nada): un nodo bajo una
  // rama plegada sigue teniendo Visible = True. Una fila se ve solo si NINGUN
  // ancestro esta colapsado, asi que hay que subir el arbol comprobandolo.
  Result := False;
  if ANode = nil then Exit;
  if not ANode.Visible then Exit;

  P := ANode.Parent;
  while P <> nil do
  begin
    if not P.Expanded then Exit;   // hay un ancestro plegado
    P := P.Parent;
  end;
  Result := True;
end;

procedure TfrmVistaProyectos.RecargarConservandoVista;
var
  Plegados: TArray<Integer>;
  VStart: TDateTime;
  VPx, VScrollX, VScrollY: Single;
begin
  // Fotografiar el estado ANTES de reconstruir.
  Plegados := CapturarPlegado;
  VStart := FGantt.StartTime;
  VPx := FGantt.PxPerMinute;
  VScrollX := FGantt.ScrollX;
  VScrollY := FGantt.ScrollY;

  CargarDatos;
  RecalcularFechas;
  ConstruirArbol;
  RestaurarPlegado(Plegados);
  ConstruirGantt;

  // Y devolverlo: ConstruirGantt hace zoom-to-fit, que es lo correcto al abrir
  // la vista pero no despues de editar (el usuario perdia su zoom y su
  // posicion en cada cambio).
  if VPx > 0 then
  begin
    FSincronizando := True;
    try
      FGantt.SetViewport(VStart, VPx, VScrollX);
      if FTimeline <> nil then
        FTimeline.SetViewport(VStart, VPx, VScrollX);
    finally
      FSincronizando := False;
    end;
    FGantt.ScrollVerticalA(VScrollY);
  end;
end;

function TfrmVistaProyectos.CapturarPlegado: TArray<Integer>;
var
  Pair: TPair<TcxTreeListNode, Integer>;
  L: TList<Integer>;
  I: Integer;
begin
  L := TList<Integer>.Create;
  try
    // Se guardan los NodeId de las ramas COLAPSADAS (suelen ser menos que las
    // desplegadas, y asi el estado por defecto sigue siendo "abierto").
    for Pair in FTLNodeToNodeId do
      if (Pair.Key <> nil) and Pair.Key.HasChildren and
         (not Pair.Key.Expanded) then
        L.Add(Pair.Value);

    // Las filas de PROYECTO (nivel 0) no estan en FTLNodeToNodeId (no son
    // tareas), y son justo las que el usuario pliega mas a menudo. Se guardan
    // con el ProjectId en NEGATIVO para distinguirlo de un NodeId.
    for I := 0 to High(FProyectos) do
      if FRaicesProyecto.ContainsKey(FProyectos[I].ProjectId) then
        if not FRaicesProyecto[FProyectos[I].ProjectId].Expanded then
          L.Add(-FProyectos[I].ProjectId);

    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmVistaProyectos.RestaurarPlegado(const APlegados: TArray<Integer>);
var
  I: Integer;
  TLNode: TcxTreeListNode;
begin
  if Length(APlegados) = 0 then Exit;

  FConstruyendo := True;   // no resincronizar el Gantt en cada Collapse
  tlWbs.BeginUpdate;
  try
    for I := 0 to High(APlegados) do
      if APlegados[I] < 0 then
      begin
        // Negativo = fila de proyecto (ver CapturarPlegado).
        if FRaicesProyecto.TryGetValue(-APlegados[I], TLNode) then
          TLNode.Collapse(False);
      end
      else if FNodeToTLNode.TryGetValue(APlegados[I], TLNode) then
        TLNode.Collapse(False);
  finally
    tlWbs.EndUpdate;
    FConstruyendo := False;
  end;
end;

procedure TfrmVistaProyectos.SincronizarPlegado;
var
  I: Integer;
  TLNode: TcxTreeListNode;
  Orden: TWbsRowInfoArray;
begin
  if FGantt = nil then Exit;
  // Durante ConstruirArbol el FullExpand dispara OnExpanded nodo a nodo: no
  // tiene sentido resincronizar el Gantt en cada uno (y ademas el orden aun no
  // esta inyectado). ConstruirGantt lo llama una vez al final.
  if FConstruyendo then Exit;

  Orden := FGantt.GetOrden;
  for I := 0 to High(Orden) do
  begin
    if Orden[I].EsProyecto then
    begin
      // La cabecera de proyecto siempre se ve: es la raiz de su rama.
      Orden[I].Visible := True;
      Continue;
    end;
    if FNodeToTLNode.TryGetValue(Orden[I].NodeId, TLNode) then
      Orden[I].Visible := FilaDesplegada(TLNode)
    else
      Orden[I].Visible := False;
  end;

  FGantt.SetOrden(Orden);
  FGantt.RebuildLayout;
  FGantt.Invalidate;
end;

procedure TfrmVistaProyectos.SincronizarAlturaFilas;
begin
  // Alineacion grid <-> Gantt con alto de fila FIJO en ambos lados (mismo
  // enfoque que GanttPRO). Medir el alto real del cxTreeList no es viable de
  // forma estable, y una diferencia de un solo pixel se acumula fila tras fila
  // hasta desfasar el Gantt una fila entera abajo del todo.
  //   - el grid impone ALTO_FILA via OnGetNodeHeight (ver FormCreate)
  //   - el Gantt usa ese mismo alto
  // El desplazamiento vertical es 0: la banda superior ya la ocupa FISICAMENTE
  // el control de timeline (Align = alTop, alto ALTO_CABECERA), asi que las
  // filas del Gantt arrancan justo debajo, a la par que las del grid.
  // Si las barras quedan desplazadas EN BLOQUE, ajustar ALTO_CABECERA (debe
  // igualar la cabecera del grid); si el desfase CRECE hacia abajo, ALTO_FILA.
  FGantt.SetMetricasFila(ALTO_FILA, 0);
end;

function TfrmVistaProyectos.CargarSeleccionGuardada: TArray<Integer>;
var
  Prefs: TUserPreferencesRepo;
  Json, S: string;
  Partes: TArray<string>;
  I, Id: Integer;
begin
  SetLength(Result, 0);
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) then Exit;

  Prefs := TUserPreferencesRepo.Create(DMPlanner.ADOConnection,
    DMPlanner.CodigoEmpresa);
  try
    Json := Prefs.Load(PREF_KEY_PROYECTOS);
  finally
    Prefs.Free;
  end;
  if Trim(Json) = '' then Exit;

  // Formato deliberadamente simple: los ProjectId separados por comas.
  Partes := Json.Split([',']);
  for I := 0 to High(Partes) do
  begin
    S := Trim(Partes[I]);
    if TryStrToInt(S, Id) and (Id > 0) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Id;
    end;
  end;
end;

procedure TfrmVistaProyectos.GuardarSeleccion;
var
  Prefs: TUserPreferencesRepo;
  S: string;
  I: Integer;
begin
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) then Exit;

  S := '';
  for I := 0 to High(FProyectos) do
  begin
    if S <> '' then S := S + ',';
    S := S + IntToStr(FProyectos[I].ProjectId);
  end;

  Prefs := TUserPreferencesRepo.Create(DMPlanner.ADOConnection,
    DMPlanner.CodigoEmpresa);
  try
    Prefs.Save(PREF_KEY_PROYECTOS, S);
  finally
    Prefs.Free;
  end;
end;

procedure TfrmVistaProyectos.btnConfigProyectosClick(Sender: TObject);
begin
  ElegirProyectos;
end;

procedure TfrmVistaProyectos.btnTreeWideClick(Sender: TObject);
var
  Ancho: Integer;
begin
  // Alterna entre dos anchos: solo el nombre (deja casi todo el sitio al
  // Gantt) o el arbol completo con todas sus columnas visibles.
  if pnlLeft.Width <> (colNombre.Width + 10) then
    pnlLeft.Width := colNombre.Width + 10
  else
  begin
    // Ancho de las columnas + SIEMPRE el hueco de la barra vertical: en un
    // proyecto real casi nunca caben todas las filas, y reservarlo de mas solo
    // deja unos pixeles en blanco, mientras que quedarse corto saca la barra
    // horizontal, que es justo lo que se quiere evitar.
    Ancho := AnchoNecesarioGrid + GetSystemMetrics(SM_CXVSCROLL);

    // No dejar el Gantt sin sitio en pantallas estrechas.
    if Ancho > ClientWidth - 200 then Ancho := ClientWidth - 200;
    pnlLeft.Width := Ancho;
  end;
end;

procedure TfrmVistaProyectos.tlWbsDblClick(Sender: TObject);
var
  NodeId: Integer;
begin
  if tlWbs.FocusedNode = nil then Exit;
  if not FTLNodeToNodeId.TryGetValue(tlWbs.FocusedNode, NodeId) then Exit;
  PedirEditarTarea(NodeId);
end;

procedure TfrmVistaProyectos.GanttDblClick(Sender: TObject);
var
  NodeId: Integer;
begin
  // Doble clic sobre una barra: la misma ficha que desde el grid.
  NodeId := FGantt.NodeIdBajoCursor;
  if NodeId <= 0 then Exit;
  FGantt.SoltarRaton;
  PedirEditarTarea(NodeId);
end;

procedure TfrmVistaProyectos.PedirEditarTarea(ANodeId: Integer);
begin
  // La ficha NO se abre dentro del propio evento de doble clic: si se hace
  // asi, el modal aparece mientras Windows aun esta procesando la secuencia
  // de mensajes del raton, y al cerrarlo el control de origen se queda con el
  // boton "pulsado" (cursor de arrastre pegado, drag fantasma).
  // Se deja para el siguiente ciclo de mensajes, cuando la cola ya esta limpia.
  FNodeIdPendiente := ANodeId;
  FTimerEditar.Enabled := True;
end;

procedure TfrmVistaProyectos.TimerEditarTick(Sender: TObject);
var
  NodeId: Integer;
begin
  FTimerEditar.Enabled := False;
  NodeId := FNodeIdPendiente;
  FNodeIdPendiente := 0;
  if NodeId > 0 then
    EditarTarea(NodeId);
end;

function TfrmVistaProyectos.CatalogoOperarios: TWbsOperarioItems;
var
  Q: TADOQuery;
  L: TList<TWbsOperarioItem>;
  It: TWbsOperarioItem;
begin
  SetLength(Result, 0);
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) then Exit;

  L := TList<TWbsOperarioItem>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT OperatorId, ISNULL(Nombre, '''') AS Nombre ' +
        'FROM FS_PL_Operator WHERE CodigoEmpresa = :CE ORDER BY Nombre';
      Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        It.OperatorId := Q.FieldByName('OperatorId').AsInteger;
        It.Nombre := Q.FieldByName('Nombre').AsString;
        if Trim(It.Nombre) = '' then
          It.Nombre := 'Operario ' + IntToStr(It.OperatorId);
        L.Add(It);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmVistaProyectos.GanttDependenciaCreada(Sender: TObject;
  const AFromNodeId, AToNodeId, ATipoLink: Integer);
var
  Repo: TWbsRepo;
  I, ProjectIdFrom, ProjectIdTo: Integer;
begin
  // Los dos extremos deben ser del MISMO proyecto: el CPM se calcula por
  // proyecto y una dependencia cruzada no la respetaria nadie.
  ProjectIdFrom := 0;
  ProjectIdTo := 0;
  for I := 0 to High(FTareas) do
  begin
    if FTareas[I].NodeId = AFromNodeId then ProjectIdFrom := FTareas[I].ProjectId;
    if FTareas[I].NodeId = AToNodeId then ProjectIdTo := FTareas[I].ProjectId;
  end;

  if (ProjectIdFrom = 0) or (ProjectIdFrom <> ProjectIdTo) then
  begin
    Vcl.Dialogs.MessageDlg(
      'Solo se pueden enlazar tareas del mismo proyecto.',
      mtInformation, [mbOK], 0);
    ConstruirGantt;   // deshacer el enlace que la clase base metio en memoria
    Exit;
  end;

  Repo := TWbsRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    Repo.AddDependencia(ProjectIdFrom, AFromNodeId, AToNodeId, ATipoLink);
  finally
    Repo.Free;
  end;

  RecargarConservandoVista;
end;

procedure TfrmVistaProyectos.GanttBarraModificada(Sender: TObject;
  const ANodeId: Integer; const AInicio, AFin: TDateTime);
var
  Repo: TWbsRepo;
  I, Idx: Integer;
  NuevaDur: Double;
begin
  Idx := -1;
  for I := 0 to High(FTareas) do
    if FTareas[I].NodeId = ANodeId then
    begin
      Idx := I;
      Break;
    end;
  if Idx < 0 then Exit;

  Repo := TWbsRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    // Redimensionar = cambiar la duracion.
    NuevaDur := MinutosLaborablesEntre(AInicio, AFin);
    if (NuevaDur > 0) and (Abs(NuevaDur - FTareas[Idx].DuracionMin) > 1) then
      Repo.SaveDuracion(ANodeId, NuevaDur);

    // Mover = FIJAR la fecha (ConstraintKind = 2). Sin la restriccion, el
    // siguiente recalculo del CPM devolveria la barra a su sitio y el arrastre
    // pareceria no funcionar.
    Repo.SaveRestriccionFecha(ANodeId, 2, AInicio);
  finally
    Repo.Free;
  end;

  RecargarConservandoVista;
end;

function TfrmVistaProyectos.MinutosLaborablesEntre(const AIni,
  AFin: TDateTime): Double;
var
  Cal: TCentreCalendar;
begin
  Cal := CalendarioComun;
  if (Cal = nil) or (AFin <= AIni) then
    Result := 0
  else
    Result := Cal.WorkingMinutesBetween(AIni, AFin);
end;

function TfrmVistaProyectos.CrearTag(const ATag: TWbsTag): Integer;
var
  Repo: TWbsRepo;
begin
  Result := 0;
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) then Exit;

  Repo := TWbsRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    Result := Repo.SaveTag(ATag);
  finally
    Repo.Free;
  end;
end;

procedure TfrmVistaProyectos.EditarTarea(ANodeId: Integer);
var
  I, Idx: Integer;
  Datos: TWbsTareaEditData;
  Repo: TWbsRepo;
begin
  Idx := -1;
  for I := 0 to High(FTareas) do
    if FTareas[I].NodeId = ANodeId then
    begin
      Idx := I;
      Break;
    end;
  if Idx < 0 then Exit;

  // Los resumenes SI se abren (para editar notas, etiquetas, operarios o
  // incluso cambiarles el tipo); lo que el dialogo bloquea son los campos que
  // en un resumen no significan nada, porque se calculan a partir de sus hijos.
  Datos := Default(TWbsTareaEditData);
  Datos.NodeId := ANodeId;
  Datos.Caption := FTareas[Idx].Caption;
  Datos.Kind := FTareas[Idx].Kind;
  Datos.EsHito := FTareas[Idx].Kind = wtkHito;
  Datos.FechaInicio := FTareas[Idx].FechaInicio;
  Datos.FechaFin := FTareas[Idx].FechaFin;
  Datos.DuracionMin := FTareas[Idx].DuracionMin;
  Datos.MinutosInvertidos := FTareas[Idx].MinutosInvertidos;

  Repo := TWbsRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    Repo.LoadDetail(ANodeId, Datos.Detail);
    Datos.Operarios := Repo.LoadOperarios(ANodeId);
    // Catalogo de etiquetas con las de esta tarea ya marcadas.
    Datos.Tags := Repo.LoadTags(ANodeId);

    if not TfrmWbsTareaEdit.Execute(Datos, CatalogoOperarios, CrearTag) then Exit;

    // Persistir SOLO lo que el usuario introduce a mano. Las fechas las
    // recalcula el motor: son volatiles salvo la restriccion de fecha fija.
    if Datos.Kind <> FTareas[Idx].Kind then
      Repo.SaveTaskKind(ANodeId, Ord(Datos.Kind));
    if Datos.DuracionMin <> FTareas[Idx].DuracionMin then
      Repo.SaveDuracion(ANodeId, Datos.DuracionMin);
    if Datos.MinutosInvertidos <> FTareas[Idx].MinutosInvertidos then
      Repo.SaveMinutosInvertidos(ANodeId, Datos.MinutosInvertidos);

    Datos.Detail.NodeId := ANodeId;
    Repo.SaveDetail(Datos.Detail);
    Repo.SaveOperarios(ANodeId, Datos.Operarios);
    Repo.SaveTagsDeTarea(ANodeId, Datos.Tags);

    // Fijar la fecha de inicio a mano = restriccion "fecha fija" (V078). Sin
    // esto, el CPM recalcularia la fecha por dependencias y borraria de hecho
    // lo que el usuario acaba de decidir.
    if Datos.FechaInicioEditada then
      Repo.SaveRestriccionFecha(ANodeId, 2, Datos.FechaInicio);
  finally
    Repo.Free;
  end;

  // Recargar: cambiar una duracion o una fecha mueve toda la cadena que
  // depende de ella. Conservando el plegado que tenia el usuario: reconstruir
  // el arbol hace FullExpand y si no se restaura, editar una tarea deja todos
  // los proyectos abiertos de nuevo.
  RecargarConservandoVista;
end;

procedure TfrmVistaProyectos.ElegirProyectos;
var
  Items: TRowFilterItems;
  Claves: TArray<string>;
  HideMode: Boolean;
  I, P, Id: Integer;
begin
  if Length(FTodosProyectos) = 0 then
  begin
    Vcl.Dialogs.MessageDlg('No hay proyectos con planificacion por tareas.',
      mtInformation, [mbOK], 0);
    Exit;
  end;

  // Reutiliza el dialogo de filtro multiseleccion (el mismo de los RowModes).
  SetLength(Items, Length(FTodosProyectos));
  for P := 0 to High(FTodosProyectos) do
  begin
    Items[P].Clave := IntToStr(FTodosProyectos[P].ProjectId);
    Items[P].Caption := FTodosProyectos[P].Nombre;
    // Count = numero de tareas, informativo en la lista.
    Items[P].Count := 0;
    for I := 0 to High(FTareas) do
      if FTareas[I].ProjectId = FTodosProyectos[P].ProjectId then
        Inc(Items[P].Count);

    // Preseleccionar los que ya se estan viendo.
    Items[P].Marcado := False;
    for I := 0 to High(FProyectos) do
      if FProyectos[I].ProjectId = FTodosProyectos[P].ProjectId then
      begin
        Items[P].Marcado := True;
        Break;
      end;
  end;

  if not TfrmRowFilterDialog.Execute('Proyectos a mostrar', Items,
    Claves, HideMode) then Exit;

  // Sin nada marcado no se muestra nada util: dejarlo como estaba.
  if Length(Claves) = 0 then Exit;

  SetLength(FProyectos, 0);
  for I := 0 to High(Claves) do
    if TryStrToInt(Claves[I], Id) then
      for P := 0 to High(FTodosProyectos) do
        if FTodosProyectos[P].ProjectId = Id then
        begin
          SetLength(FProyectos, Length(FProyectos) + 1);
          FProyectos[High(FProyectos)] := FTodosProyectos[P];
          Break;
        end;

  GuardarSeleccion;

  // Recargar con la nueva seleccion.
  CargarDatos;
  RecalcularFechas;
  ConstruirArbol;
  ConstruirGantt;
end;

function TfrmVistaProyectos.TryGetSched(const ANodeId: Integer;
  out ASched: TWbsSchedule): Boolean;
var
  Sch: TWbsScheduler;
begin
  // Con varios proyectos a la vista hay un motor por proyecto, pero los NodeId
  // son unicos en toda la BD: basta con preguntar a todos hasta encontrarlo.
  Result := False;
  for Sch in FSchedulers.Values do
    if Sch.TryGet(ANodeId, ASched) then
      Exit(True);
end;

function TfrmVistaProyectos.CalendarioComun: TCentreCalendar;
var
  Sch: TWbsScheduler;
begin
  // Todos los motores usan el mismo calendario laborable del modulo; con el
  // primero basta para el sombreado de fondo del Gantt.
  Result := nil;
  for Sch in FSchedulers.Values do
    Exit(Sch.Calendar);
end;

procedure TfrmVistaProyectos.RecalcularFechas;
var
  I, J, P, CriticasTotal: Integer;
  Msg: string;
  TareasP: TWbsTaskArray;
  LinksP: TWbsLinkArray;
  Sch: TWbsScheduler;
  Res: TWbsSchedulerResult;
  IniGlobal, FinGlobal: TDateTime;
begin
  if Length(FTareas) = 0 then Exit;

  FSchedulers.Clear;
  Msg := '';
  IniGlobal := 0;
  FinGlobal := 0;
  CriticasTotal := 0;

  // UN MOTOR POR PROYECTO: el CPM es independiente para cada uno (no hay
  // dependencias entre proyectos), asi que cada uno tiene su propio camino
  // critico y su propia fecha de fin.
  for P := 0 to High(FProyectos) do
  begin
    // Repartir tareas y enlaces de este proyecto.
    SetLength(TareasP, 0);
    for I := 0 to High(FTareas) do
      if FTareas[I].ProjectId = FProyectos[P].ProjectId then
      begin
        SetLength(TareasP, Length(TareasP) + 1);
        TareasP[High(TareasP)] := FTareas[I];
      end;
    if Length(TareasP) = 0 then Continue;

    SetLength(LinksP, 0);
    for I := 0 to High(FLinks) do
      if FLinks[I].ProjectId = FProyectos[P].ProjectId then
      begin
        SetLength(LinksP, Length(LinksP) + 1);
        LinksP[High(LinksP)] := FLinks[I];
      end;

    Sch := TWbsScheduler.Create;
    FSchedulers.AddOrSetValue(FProyectos[P].ProjectId, Sch);

    Res := Sch.Recalcular(TareasP, LinksP);
    TareasP := Sch.TareasRecalculadas;

    // Devolver las fechas recalculadas al array global.
    for I := 0 to High(TareasP) do
      for J := 0 to High(FTareas) do
        if FTareas[J].NodeId = TareasP[I].NodeId then
        begin
          FTareas[J].FechaInicio := TareasP[I].FechaInicio;
          FTareas[J].FechaFin := TareasP[I].FechaFin;
          Break;
        end;

    // Cabecera de nivel 0 del proyecto: su rango y sus criticas.
    FProyectos[P].FechaInicio := Res.ProyectoInicio;
    FProyectos[P].FechaFin := Res.ProyectoFin;
    FProyectos[P].TareasCriticas := Res.TareasCriticas;

    if (Res.ProyectoInicio > 0) and
       ((IniGlobal = 0) or (Res.ProyectoInicio < IniGlobal)) then
      IniGlobal := Res.ProyectoInicio;
    if Res.ProyectoFin > FinGlobal then FinGlobal := Res.ProyectoFin;
    Inc(CriticasTotal, Res.TareasCriticas);

    if Res.HayCiclo then
      for I := 0 to High(Res.Errores) do
        Msg := Msg + FProyectos[P].Nombre + ': ' + Res.Errores[I] + #13#10;
  end;

  // Subtitulo: resumen global (rango de todos los proyectos mostrados).
  if Length(FProyectos) = 1 then
    lblSubtitulo.Caption := Format(
      '%s - %s  ' + #$2022 + '  %d tarea(s) en el camino critico',
      [FormatDateTime('dd/mm/yyyy', IniGlobal),
       FormatDateTime('dd/mm/yyyy', FinGlobal), CriticasTotal])
  else
    lblSubtitulo.Caption := Format(
      '%d proyectos  ' + #$2022 + '  %s - %s  ' + #$2022 +
      '  %d tarea(s) en camino critico',
      [Length(FProyectos), FormatDateTime('dd/mm/yyyy', IniGlobal),
       FormatDateTime('dd/mm/yyyy', FinGlobal), CriticasTotal]);

  // Dependencias circulares: avisar sin romper (el resto si se ha calculado).
  if Msg <> '' then
    Vcl.Dialogs.MessageDlg(
      'Hay dependencias circulares:'#13#10#13#10 + Msg +
      #13#10'Esas tareas conservan sus fechas anteriores.',
      mtWarning, [mbOK], 0);
end;

procedure TfrmVistaProyectos.CargarDatos;
var
  Repo: TWbsRepo;
  I, P: Integer;
  TareasP: TWbsTaskArray;
  LinksP: TWbsLinkArray;
  Seleccion: TArray<Integer>;
  Encontrado: Boolean;
  Tags: TWbsTagArray;
  TagsProy: TDictionary<Integer, TArray<Integer>>;
  Par: TPair<Integer, TArray<Integer>>;
begin
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) then Exit;

  Repo := TWbsRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    // Catalogo completo de proyectos TAREAS (lo necesita el selector).
    FTodosProyectos := Repo.LoadProyectosTareas;

    // Que proyectos mostrar: la ultima seleccion guardada del usuario o, si no
    // hay ninguna valida, el proyecto con el que se abrio la vista.
    Seleccion := CargarSeleccionGuardada;
    SetLength(FProyectos, 0);
    for P := 0 to High(FTodosProyectos) do
    begin
      Encontrado := False;
      for I := 0 to High(Seleccion) do
        if Seleccion[I] = FTodosProyectos[P].ProjectId then
        begin
          Encontrado := True;
          Break;
        end;
      if Encontrado then
      begin
        SetLength(FProyectos, Length(FProyectos) + 1);
        FProyectos[High(FProyectos)] := FTodosProyectos[P];
      end;
    end;

    if Length(FProyectos) = 0 then
      for P := 0 to High(FTodosProyectos) do
        if FTodosProyectos[P].ProjectId = FProjectId then
        begin
          SetLength(FProyectos, 1);
          FProyectos[0] := FTodosProyectos[P];
          Break;
        end;

    // Cargar tareas y enlaces de TODOS los proyectos mostrados, concatenados.
    SetLength(FTareas, 0);
    SetLength(FLinks, 0);
    for P := 0 to High(FProyectos) do
    begin
      TareasP := Repo.LoadTareas(FProyectos[P].ProjectId);
      for I := 0 to High(TareasP) do
      begin
        SetLength(FTareas, Length(FTareas) + 1);
        FTareas[High(FTareas)] := TareasP[I];
      end;

      LinksP := Repo.LoadLinks(FProyectos[P].ProjectId);
      for I := 0 to High(LinksP) do
      begin
        SetLength(FLinks, Length(FLinks) + 1);
        FLinks[High(FLinks)] := LinksP[I];
      end;
    end;

    // Etiquetas de todas las tareas, en DOS consultas (no una por tarea):
    // el catalogo de colores y el mapa NodeId -> TagIds.
    FColorPorTag.Clear;
    Tags := Repo.LoadTags;
    for I := 0 to High(Tags) do
      FColorPorTag.AddOrSetValue(Tags[I].TagId, Tags[I].Color);

    FTagsPorNodo.Clear;
    for P := 0 to High(FProyectos) do
    begin
      TagsProy := Repo.LoadTagsPorNodo(FProyectos[P].ProjectId);
      try
        for Par in TagsProy do
          FTagsPorNodo.AddOrSetValue(Par.Key, Par.Value);
      finally
        TagsProy.Free;
      end;
    end;
  finally
    Repo.Free;
  end;

  // Titulo: el nombre del proyecto cuando solo hay uno (es la informacion mas
  // util); con varios, el nombre del modulo, porque el recuento y el rango ya
  // los da el subtitulo y repetirlos aqui no aporta nada.
  if Length(FProyectos) = 1 then
    lblTitulo.Caption := FProyectos[0].Nombre
  else
    lblTitulo.Caption := 'Ingenier'#237'a';
end;

procedure TfrmVistaProyectos.ConstruirArbol;
var
  I, P: Integer;
  T: TWbsTask;
  TLNode, TLParent, TLProyecto: TcxTreeListNode;
  Sched: TWbsSchedule;
  // Fila de nivel 0 de cada proyecto: ProjectId -> nodo del arbol.

begin

  FConstruyendo := True;
  tlWbs.BeginUpdate;
  try
    tlWbs.Clear;
    FNodeToTLNode.Clear;
    FTLNodeToNodeId.Clear;
    FRaicesProyecto.Clear;

    // NIVEL 0 = una fila por PROYECTO. Asi se pueden ver varios proyectos a la
    // vez, cada uno con su rama. Con un solo proyecto sigue siendo util: da
    // contexto y permite plegarlo entero.
    for P := 0 to High(FProyectos) do
    begin
      TLProyecto := tlWbs.Add;
      TLProyecto.Texts[colNombre.ItemIndex] := FProyectos[P].Nombre;
      if FProyectos[P].FechaInicio > 0 then
        TLProyecto.Texts[colInicio.ItemIndex] :=
          FormatDateTime('dd/mm/yyyy', FProyectos[P].FechaInicio);
      if FProyectos[P].FechaFin > 0 then
        TLProyecto.Texts[colFin.ItemIndex] :=
          FormatDateTime('dd/mm/yyyy', FProyectos[P].FechaFin);
      if FProyectos[P].TareasCriticas > 0 then
        TLProyecto.Texts[colHolgura.ItemIndex] :=
          Format('%d criticas', [FProyectos[P].TareasCriticas]);
      FRaicesProyecto.AddOrSetValue(FProyectos[P].ProjectId, TLProyecto);
    end;

    // FTareas ya viene en orden de arbol (padre antes que hijo), asi que al
    // llegar a un hijo su padre ya existe en el mapa.
    for I := 0 to High(FTareas) do
    begin
      T := FTareas[I];
      if (T.ParentTaskId <> 0) and
         FNodeToTLNode.TryGetValue(T.ParentTaskId, TLParent) then
        TLNode := tlWbs.AddChild(TLParent)
      // Raiz de la WBS: cuelga de la fila de su PROYECTO, no del arbol.
      else if FRaicesProyecto.TryGetValue(T.ProjectId, TLProyecto) then
        TLNode := tlWbs.AddChild(TLProyecto)
      else
        TLNode := tlWbs.Add;

      TLNode.Texts[colNombre.ItemIndex]   := T.Caption;
      TLNode.Texts[colDuracion.ItemIndex] := FormatDias(T.DuracionMin);
      if T.FechaInicio > 0 then
        TLNode.Texts[colInicio.ItemIndex] := FormatDateTime('dd/mm/yyyy', T.FechaInicio);
      if T.FechaFin > 0 then
        TLNode.Texts[colFin.ItemIndex]    := FormatDateTime('dd/mm/yyyy', T.FechaFin);
      // Hito: marcar con rombo (#$25C6) en el nombre.
      if T.Kind = wtkHito then
        TLNode.Texts[colNombre.ItemIndex] := #$25C6' ' + T.Caption;

      if TryGetSched(T.NodeId, Sched) then
      begin
        // Holgura: en blanco para los resumenes, que no tienen holgura propia;
        // 'Critica' cuando es cero.
        if not Sched.EsResumen then
        begin
          if Sched.EsCritica then
            TLNode.Texts[colHolgura.ItemIndex] := 'Critica'
          else
            TLNode.Texts[colHolgura.ItemIndex] := FormatDias(Sched.TotalSlackMin);
        end;

        // Avance: en los resumenes viene agregado de sus hijos. Por encima del
        // 100% se marca como desviacion (mas tiempo del estimado).
        if Sched.Avance > 0 then
        begin
          TLNode.Texts[colAvance.ItemIndex] :=
            Format('%.0f%%', [Sched.Avance * 100]);
          // Desviacion relevante: marcarla para que no se lea igual que un
          // 100% limpio (el mismo umbral que usa el Gantt para el ambar).
          if Sched.Avance > UMBRAL_DESVIACION then
            TLNode.Texts[colAvance.ItemIndex] :=
              TLNode.Texts[colAvance.ItemIndex] + ' ' + #$26A0;
        end
        else
          TLNode.Texts[colAvance.ItemIndex] := '';
      end;

      FNodeToTLNode.AddOrSetValue(T.NodeId, TLNode);
      FTLNodeToNodeId.AddOrSetValue(TLNode, T.NodeId);
    end;

    tlWbs.FullExpand;
  finally
    tlWbs.EndUpdate;
    FConstruyendo := False;
    // FRaicesProyecto NO se libera aqui: es un campo del form (lo necesita
    // RestaurarPlegado despues de reconstruir el arbol) y se destruye en
    // FormDestroy. Liberarlo aqui dejaba un puntero colgando.
  end;
end;

function TfrmVistaProyectos.RangoFechas(out AIni, AFin: TDateTime): Boolean;
var
  I: Integer;
begin
  AIni := 0; AFin := 0;
  Result := False;
  for I := 0 to High(FTareas) do
  begin
    if FTareas[I].FechaInicio > 0 then
    begin
      if (AIni = 0) or (FTareas[I].FechaInicio < AIni) then AIni := FTareas[I].FechaInicio;
      Result := True;
    end;
    if FTareas[I].FechaFin > 0 then
      if (AFin = 0) or (FTareas[I].FechaFin > AFin) then AFin := FTareas[I].FechaFin;
  end;
  if Result and (AFin <= AIni) then AFin := AIni + 30;
end;

procedure TfrmVistaProyectos.ConstruirGantt;
var
  NodesRepo: TNodesRepo;
  Nodes, NodesP: TArray<TNode>;
  Orden: TWbsRowInfoArray;
  ErpLinks: TArray<TErpLink>;
  Sched: TWbsSchedule;
  I, J, P, K: Integer;
  TagIds: TArray<Integer>;
  Ini, Fin: TDateTime;
begin
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) then Exit;

  // Cargar las tareas como TNode (son nodos de FS_PL_Node) reutilizando el
  // repo de nodos existente. Se rellena FNodeDataRepo con los NodeData del
  // proyecto: el Gantt lo necesita para resolver datos al pintar (si es nil,
  // TryGetById peta con Access Violation).
  FNodeDataRepo.Clear;
  SetLength(Nodes, 0);
  // Un LoadFromDB por proyecto mostrado, concatenando los TNode de todos.
  for P := 0 to High(FProyectos) do
  begin
    NodesRepo := TNodesRepo.Create(DMPlanner.ADOConnection);
    try
      NodesRepo.LoadFromDB(DMPlanner.CodigoEmpresa, FProyectos[P].ProjectId,
        FNodeDataRepo);
      NodesP := NodesRepo.GetAll;
      for I := 0 to High(NodesP) do
      begin
        SetLength(Nodes, Length(Nodes) + 1);
        Nodes[High(Nodes)] := NodesP[I];
      end;
    finally
      NodesRepo.Free;
    end;
  end;

  // Imprescindible antes de SetData: sin repo de NodeData, el paint del Gantt
  // accede a un puntero nil.
  FGantt.SetNodeRepo(FNodeDataRepo);

  // Sombreado de fines de semana / horas no laborables: el Gantt lo resuelve
  // por centro, y las tareas de proyecto no tienen centro, asi que hay que
  // darle explicitamente el mismo calendario con el que calcula el motor.
  FGantt.AplicarCalendario(CalendarioComun);

  // Inyectar el orden de filas EXACTAMENTE como se construyo el arbol: por cada
  // proyecto, primero su fila de nivel 0 y despues sus tareas. Cualquier
  // divergencia con el grid descuadra la correspondencia fila a fila.
  SetLength(Orden, 0);
  for P := 0 to High(FProyectos) do
  begin
    // Fila de cabecera del proyecto.
    SetLength(Orden, Length(Orden) + 1);
    K := High(Orden);
    Orden[K] := Default(TWbsRowInfo);
    Orden[K].EsProyecto := True;
    Orden[K].Visible := True;
    Orden[K].Titulo := FProyectos[P].Nombre;
    Orden[K].ProyectoIni := FProyectos[P].FechaInicio;
    Orden[K].ProyectoFin := FProyectos[P].FechaFin;

    // Y a continuacion sus tareas, en orden de arbol.
    for I := 0 to High(FTareas) do
    begin
      if FTareas[I].ProjectId <> FProyectos[P].ProjectId then Continue;
      SetLength(Orden, Length(Orden) + 1);
      K := High(Orden);
      Orden[K] := Default(TWbsRowInfo);
      Orden[K].NodeId := FTareas[I].NodeId;
      Orden[K].Kind := FTareas[I].Kind;
      Orden[K].Nivel := FTareas[I].Nivel;
      Orden[K].Visible := True;   // acordeon en Fase 3
      Orden[K].Titulo := FTareas[I].Caption;  // lo pinta el overlay, a la derecha
      // Colores de sus etiquetas, para los badges de la barra.
      if FTagsPorNodo.TryGetValue(FTareas[I].NodeId, TagIds) then
      begin
        SetLength(Orden[K].ColoresTag, Length(TagIds));
        for J := 0 to High(TagIds) do
          if not FColorPorTag.TryGetValue(TagIds[J], Orden[K].ColoresTag[J]) then
            Orden[K].ColoresTag[J] := clGray;
      end;
      if TryGetSched(FTareas[I].NodeId, Sched) then
      begin
        Orden[K].EsCritica := Sched.EsCritica;
        Orden[K].HolguraMin := Sched.TotalSlackMin;
        Orden[K].Avance := Sched.Avance;
      end;
    end;
  end;
  FGantt.SetOrden(Orden);

  // Las fechas que pinta el Gantt son las del MOTOR, no las de BD: volcar el
  // recalculo sobre los TNode antes de SetData. Y colorear por tipo de tarea /
  // criticidad (en Vista Normal el control respeta Node.FillColor).
  for I := 0 to High(Nodes) do
  begin
    // El titulo lo pinta el overlay a la DERECHA de la barra: vaciarlo aqui
    // para que el render base no lo escriba tambien dentro y salga duplicado.
    Nodes[I].Caption := '';

    if not TryGetSched(Nodes[I].Id, Sched) then Continue;
    if Sched.EarlyStart > 0 then
    begin
      Nodes[I].StartTime := Sched.EarlyStart;
      Nodes[I].EndTime := Sched.EarlyFinish;
    end;

    if Sched.EsResumen then
    begin
      Nodes[I].FillColor := COL_PRJ_RESUMEN;
      Nodes[I].BorderColor := COL_PRJ_RESUMEN_BORDE;
    end
    else if Sched.EsCritica then
    begin
      Nodes[I].FillColor := COL_PRJ_CRITICA;
      Nodes[I].BorderColor := COL_PRJ_CRITICA_BORDE;
    end
    else
    begin
      Nodes[I].FillColor := COL_PRJ_TAREA;
      Nodes[I].BorderColor := COL_PRJ_TAREA_BORDE;
    end;
  end;

  // Fletxes de dependencia: el control base ya las pinta (DrawDependenciesD2D)
  // a partir de FLinks, resolviendo por Id de TNode -> que aqui es el NodeId.
  // Basta con traducir TWbsLink -> TErpLink. lvAlways: en un proyecto la red de
  // dependencias es el corazon de la vista, no un detalle de la seleccion.
  SetLength(ErpLinks, Length(FLinks));
  for I := 0 to High(FLinks) do
  begin
    ErpLinks[I].FromNodeId := FLinks[I].FromNodeId;
    ErpLinks[I].ToNodeId := FLinks[I].ToNodeId;
    ErpLinks[I].LinkType := TLinkType(Ord(FLinks[I].LinkType));
    ErpLinks[I].PorcentajeDependencia := 0;
  end;
  FGantt.SetLinks(ErpLinks);
  // lvNever: las flechas las pinta el propio control (PintarDependencias) con
  // trazado ortogonal. El render base las dibujaria ADEMAS como rectas
  // diagonales y se verian duplicadas.
  FGantt.LinksVisible := lvNever;

  // Rango temporal del Gantt. Fallback a hoy si el proyecto no tiene fechas.
  if not RangoFechas(Ini, Fin) then
  begin
    Ini := Date;
    Fin := Date + 30;
  end;
  FGantt.SetTimeRange(DateOf(Ini) - 2, DateOf(Fin) + 2);
  FTimeline.SetTimeRange(DateOf(Ini) - 2, DateOf(Fin) + 2);
  FGantt.SetData(nil, Nodes, DateOf(Ini) - 2);

  // Aplicar el plegado REAL del arbol (hay ramas que arrancan colapsadas): sin
  // esto el Gantt pinta tambien las filas de las ramas plegadas y todas las
  // barras quedan desplazadas respecto al grid.
  SincronizarPlegado;

  // ORDEN IMPORTANTE: primero el alto de fila, despues el zoom.
  // SetMetricasFila fuerza un RebuildLayout, que recalcula la X de cada barra a
  // partir del viewport; si se hace DESPUES del zoom, las barras se reconstruyen
  // con un viewport que ya no es el vigente y quedan descuadradas respecto a la
  // regla de fechas.
  SincronizarAlturaFilas;

  // Zoom-to-fit: sin esto el zoom por defecto (2 px/min) hace que el rango
  // completo del proyecto quede muy lejos a la derecha y no se vea ninguna
  // barra. Ajustamos px/min para que el rango [Ini-2, Fin+2] quepa en el ancho.
  AjustarZoomFit(DateOf(Ini) - 2, DateOf(Fin) + 2);

  // Banda de carga por operario: depende de las mismas fechas y del mismo
  // viewport, asi que se refresca al final, con todo ya colocado.
  CargarBandaOperarios;
end;

procedure TfrmVistaProyectos.AjustarZoomFit(const AIni, AFin: TDateTime);
var
  Minutos, Ancho: Double;
  Px: Single;
begin
  Ancho := pnlRight.ClientWidth - 24;
  if Ancho < 200 then Ancho := 900;   // el form aun no tiene tamano real
  Minutos := (AFin - AIni) * 24 * 60;
  if Minutos <= 0 then Exit;
  Px := Ancho / Minutos;
  // Clamp al rango que admite el control (0.2 seria demasiado; permitimos menos
  // para proyectos largos usando el setter directo del control).
  if Px < 0.02 then Px := 0.02;
  if Px > 2.0 then Px := 2.0;

  // Aplicar el MISMO viewport a los dos controles de una vez. Con el flag
  // puesto, el OnViewportChanged del Gantt no reenvia el cambio a la regla:
  // si no, la regla recibia dos asignaciones (la del evento y la de aqui) y
  // podia quedarse con un tramo distinto al de las barras.
  FSincronizando := True;
  try
    FGantt.SetViewport(AIni, Px, 0);
    if FTimeline <> nil then
      FTimeline.SetViewport(AIni, Px, 0);
  finally
    FSincronizando := False;
  end;
end;

end.
