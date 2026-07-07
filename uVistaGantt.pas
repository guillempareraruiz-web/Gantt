unit uVistaGantt;
// Vista Gantt embebible.
// Fase 1: esqueleto vacío. En pasos siguientes se irán copiando aquí
// desde Main los componentes (toolbar, pnlCentros, pnlGanttContainer,
// panel inferior, popups) y sus handlers.
//
// Renombrado de convivencia durante la extracción:
//   Main.FGantt      -> VistaGantt.FGanttControl
//   Main.FTimeline   -> VistaGantt.FTimelineControl
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, DateUtils,
  uGanttHelpers, uCentreCalendar, uGanttAlertas,
  uNodeDataRepo, uOperariosRepo, uMoldeRepo,
  uCustomFieldDefs, uPlanningRules, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxSkinsCore, dxSkinBasic,
  dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee,
  dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019Colorful,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, Vcl.ComCtrls, dxCore,
  cxDateUtils, cxCheckBox, Vcl.Menus, dxCoreGraphics, cxButtonEdit, cxScrollBox,
  cxButtons, cxDropDownEdit, cxCheckComboBox, Vcl.StdCtrls, Vcl.WinXCtrls,
  cxCalendar, cxTextEdit, cxMaskEdit, cxSpinEdit,
  uGanttControl, uGanttControlGrupo, uGanttTimeline, uGanttSummary, uGanttCentres, uGanttTypes, uGanttHistory, uErpTypes,
  System.Generics.Collections, System.Generics.Defaults,
  System.Threading, System.Math, uHelpGuide,
  uOperariosTypes, System.Variants, uColorPalette64LayeredPopup,
  dxGDIPlusClasses, cxImage, System.ImageList, Vcl.ImgList, cxImageList,
  Vcl.Buttons, Winapi.GDIPOBJ, Winapi.GDIPAPI, uCrearNodoManual;
type
  // Items agregados de nodos usados para calculo de KPIs por centro.
  TNodeKPIItem = record
    CentreId: Integer;
    StartTime: TDateTime;
    EndTime: TDateTime;
    OperariosAsignados: Integer;
    DurationMin: Double;
  end;

  TCentreKPIWork = record
    CentreId: Integer;
    Calendar: TCentreCalendar;
    Items: TArray<TNodeKPIItem>;
  end;

  TCentreKPIResult = record
    CentreId: Integer;
    KPI: TCentreKPI;
  end;

  TfrmVistaGantt = class(TForm)
    pnlRoot: TPanel;
    Panel1: TPanel;
    pnlToolbar: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    lblUndoCount: TLabel;
    lblRedoCount: TLabel;
    btnRefresh: TButton;
    spCentros: TcxSpinEdit;
    cxSpinEdit2: TcxSpinEdit;
    dtFechaInicioGantt: TcxDateEdit;
    dtFechaFinGantt: TcxDateEdit;
    SearchBox1: TSearchBox;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    btnUndo: TButton;
    btnRedo: TButton;
    Button12: TButton;
    Button25: TButton;
    Button26: TButton;
    Panel3: TPanel;
    Label18: TLabel;
    Panel6: TPanel;
    Label11: TLabel;
    lblModified: TLabel;
    Panel7: TPanel;
    Label13: TLabel;
    lblNormal: TLabel;
    Panel8: TPanel;
    Label14: TLabel;
    lblYellow: TLabel;
    Panel9: TPanel;
    Label15: TLabel;
    lblOrange: TLabel;
    Panel10: TPanel;
    Label16: TLabel;
    lblRed: TLabel;
    Panel11: TPanel;
    Label17: TLabel;
    lblGreen: TLabel;
    Button21: TButton;
    Button22: TButton;
    Button2: TButton;
    Button23: TButton;
    Button24: TButton;
    btnResaltarOF: TcxButton;
    btnResaltarOT: TcxButton;
    pnlCentros: TPanel;
    pnlGanttContainer: TPanel;
    Panel2: TPanel;
    Shape1: TShape;
    Shape2: TShape;
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblFechaHora: TLabel;
    pnlSubTitulo: TPanel;
    Button27: TButton;
    popCentros: TPopupMenu;
    INFO3: TMenuItem;
    popGantt: TPopupMenu;
    miSeleccion: TMenuItem;
    miSelDia: TMenuItem;
    miSelSemana: TMenuItem;
    miSelDeseleccionar: TMenuItem;
    N5: TMenuItem;
    MenuItem1: TMenuItem;
    Desactivarfechabloqueo1: TMenuItem;
    Calendario1: TMenuItem;
    ShiftRow1: TMenuItem;
    ShiftRowallimpact1: TMenuItem;
    N2: TMenuItem;
    Aadirmarcador1: TMenuItem;
    Gestionmarcadores1: TMenuItem;
    Marcadoresautomaticos1: TMenuItem;
    N4: TMenuItem;
    RestaurarVistaDefecto1: TMenuItem;
    popTimeline: TPopupMenu;
    MenuItem2: TMenuItem;
    popNode: TPopupMenu;
    MenuItem3: TMenuItem;
    NLote1: TMenuItem;
    AgruparEnLote1: TMenuItem;
    VerLote1: TMenuItem;
    DesagruparLote1: TMenuItem;
    LibreMovimiento1: TMenuItem;
    Resetduracinoriginal1: TMenuItem;
    CompactarOF1: TMenuItem;
    odalaOF1: TMenuItem;
    odalaOF2: TMenuItem;
    CompactarOFapartirdelNodo1: TMenuItem;
    ApartirdelNodoconprioridad1: TMenuItem;
    CompactarOT1: TMenuItem;
    otalaOT1: TMenuItem;
    odalaOTconprioridad1: TMenuItem;
    ApartirdelNodo1: TMenuItem;
    ApartirdelNodoconprioridad2: TMenuItem;
    SepCompactSel1: TMenuItem;
    miCompactarSeleccion: TMenuItem;
    miMoverTodoDesde: TMenuItem;
    ShiftRow2: TMenuItem;
    N1: TMenuItem;
    Color1: TMenuItem;
    Colordelnode1: TMenuItem;
    ColordelaOrdendetrabajo1: TMenuItem;
    ColordelaOrdendeFabricacin1: TMenuItem;
    ColordelPedido1: TMenuItem;
    ColordelProyecto1: TMenuItem;
    ResaltarOF1: TMenuItem;
    CentrarOF1: TMenuItem;
    Info1: TMenuItem;
    SepOperarios1: TMenuItem;
    miAsignarOperarios: TMenuItem;
    miGestionOperarios: TMenuItem;
    SepOperarios2: TMenuItem;
    miEditarLinks: TMenuItem;
    SepDesplanificar1: TMenuItem;
    miDesplanificar: TMenuItem;
    N3: TMenuItem;
    Indicadores1: TMenuItem;
    cbVistas: TcxComboBox;
    btnFocus: TButton;
    imgSection: TcxImage;
    cxImageList1: TcxImageList;
    cxDateEdit1: TcxDateEdit;
    btnIr: TcxButton;
    btnHoy: TcxButton;
    Panel5: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    btnNodeGoToLast: TcxButton;
    btnNodeGoToNext: TcxButton;
    btnNodeGoToFirst: TcxButton;
    btnNodeGoToPrev: TcxButton;
    Label20: TLabel;
    btnKPIVisible: TcxButton;
    btnKPIAll: TcxButton;
    btnShowCentrosKPI: TcxButton;
    Label12: TLabel;
    btnConfigCentros: TcxButton;
    LblIndicadores: TLabel;
    Label21: TLabel;
    Label6: TLabel;
    btnGanttDates: TcxButton;
    btnShowWeekends: TcxButton;
    pnlKPI3: TPanel;
    LblKPIValue3: TLabel;
    pnlKPI2: TPanel;
    LblKPIValue2: TLabel;
    pnlKPI1: TPanel;
    LblKPIValue1: TLabel;
    pnlKPI0: TPanel;
    LblKPITitle0: TLabel;
    LblKPIValue0: TLabel;
    pnlSummary: TPanel;
    pnlSummaryToolbar: TPanel;
    Shape4: TShape;
    Shape5: TShape;
    Label22: TLabel;
    btnS3: TcxButton;
    btnS4: TcxButton;
    btnS1: TcxButton;
    btnS2: TcxButton;
    LblKPITitle1: TLabel;
    LblKPITitle2: TLabel;
    LblKPITitle3: TLabel;
    Image1: TImage;
    Image2: TImage;
    Shape6: TShape;
    pnlKPIAlertas: TPanel;
    Label8: TLabel;
    Label9: TLabel;
    Image3: TImage;
    Label10: TLabel;
    cxButton1: TcxButton;
    btnCompactar: TcxButton;
    btnCompact: TcxButton;
    btnFoco: TcxButton;
    PopOpciones: TPopupMenu;
    Dependencias1: TMenuItem;
    Versumario1: TMenuItem;
    miVerOperarios: TMenuItem;
    aaa1: TMenuItem;
    ssss1: TMenuItem;
    Noverninguna1: TMenuItem;
    N6: TMenuItem;
    pnlOperarios: TPanel;
    Label23: TLabel;
    Shape3: TShape;
    Label19: TLabel;
    btnHighlightOperarios: TcxButton;
    btnFilterOperarios: TcxButton;
    FcxFilterOperarios: TcxCheckComboBox;
    cbDepartamentos: TcxCheckComboBox;
    btnClearOperarios: TcxButton;
    btnAutoPlanSel: TcxButton;
    btnDesasignarSel: TcxButton;
    btnAtajos: TcxButton;
    cxButton2: TcxButton;
    procedure btnAtajosClick(Sender: TObject);
    procedure Versumario1Click(Sender: TObject);
    procedure miVerOperariosClick(Sender: TObject);
    procedure btnFocoClick(Sender: TObject);
    procedure btnCompactarClick(Sender: TObject);
    procedure pnlKPIAlertasClick(Sender: TObject);
    procedure pnlGanttContainerResize(Sender: TObject);
    procedure TimelineViewportChanged(Sender: TObject;
      const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
    procedure TimelineInteraction(Sender: TObject; const Interacting: Boolean);
    procedure SummaryViewportChanged(Sender: TObject;
      const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
    // Resum/KPIs per dia
    procedure SummaryDayKPI(Sender: TObject; const ADate: TDateTime;
      out ALine1, ALine2, ALine3: string; out AHighlight: Boolean;
      out AIntensity: Single; out ABadgeCount: Integer;
      out ABadgeColor: TSummaryBadgeColor);
    procedure RebuildSummaryData;
    // True solo si la banda de Summary esta visible: cuando esta oculta NO se
    // computa nada (eficiencia). Es la guarda de todos los caminos de calculo.
    function SummaryActivo: Boolean;
    procedure SetSummaryView(const AView: TSummaryView);
    // Marca el boton toggle de la vista de Summary indicada y la aplica (para
    // restaurar el Summary guardado al reabrir el Gantt).
    procedure RestaurarSummaryView(const AView: TSummaryView);
    procedure btnS1Click(Sender: TObject);
    procedure btnS2Click(Sender: TObject);
    procedure btnS3Click(Sender: TObject);
    procedure btnS4Click(Sender: TObject);
    procedure GanttViewportChanged(Sender: TObject;
      const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
    procedure GanttScrollYChanged(Sender: TObject; const ScrollY: Single);
    procedure GanttStatsChanged(Sender: TObject);
    procedure GanttLayoutChanged(Sender: TObject);
    procedure GanttNodeSelected(Sender: TObject);
    procedure GanttVoidClick(Sender: TObject);
    procedure GanttFechaBloqueoChanged(Sender: TObject);
    procedure GuardarFechaBloqueo(const ADate: TDateTime);
    procedure GanttNodeDblClick(Sender: TObject; const NodeIndex: Integer);
    procedure GanttMarkerDblClick(Sender: TObject; const MarkerId: Integer);
    procedure GanttMarkerMoved(Sender: TObject; const MarkerId: Integer;
      const NewDateTime: TDateTime);
    procedure PersistMarcadores;
    procedure miAsignarOperariosClick(Sender: TObject);
    procedure miCompactarSeleccionClick(Sender: TObject);
    procedure miMoverTodoDesdeClick(Sender: TObject);
    procedure miGestionOperariosClick(Sender: TObject);
    procedure miEditarLinksClick(Sender: TObject);
    procedure miDesplanificarClick(Sender: TObject);
    procedure AgruparEnLote1Click(Sender: TObject);
    procedure VerLote1Click(Sender: TObject);
    procedure DesagruparLote1Click(Sender: TObject);
    procedure CentresScrollYChanged(Sender: TObject; const ScrollY: Single);
    procedure Button27Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure Desactivarfechabloqueo1Click(Sender: TObject);
    procedure Calendario1Click(Sender: TObject);
    procedure Aadirmarcador1Click(Sender: TObject);
    procedure Gestionmarcadores1Click(Sender: TObject);
    procedure Marcadoresautomaticos1Click(Sender: TObject);
    procedure RestaurarVistaDefecto1Click(Sender: TObject);
    procedure miSelDiaClick(Sender: TObject);
    procedure miSelSemanaClick(Sender: TObject);
    procedure miSelDeseleccionarClick(Sender: TObject);
    procedure ShiftRow1Click(Sender: TObject);
    procedure ShiftRowallimpact1Click(Sender: TObject);
    procedure INFO3Click(Sender: TObject);
    procedure Indicadores1Click(Sender: TObject);
    procedure lblModifiedClick(Sender: TObject);
    procedure btnResaltarOFClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button23Click(Sender: TObject);
    procedure Button21Click(Sender: TObject);
    procedure Button22Click(Sender: TObject);
    procedure cbVistasPropertiesChange(Sender: TObject);
    procedure btnGanttDatesClick(Sender: TObject);
    procedure btnUndoClick(Sender: TObject);
    procedure btnRedoClick(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Button24Click(Sender: TObject);
    procedure SearchBox1InvokeSearch(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure LibreMovimiento1Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure popNodePopup(Sender: TObject);
    procedure selPeriodoClick(Sender: TObject);
    procedure moverAFechaClick(Sender: TObject);
    procedure Resetduracinoriginal1Click(Sender: TObject);
    procedure ShiftRow2Click(Sender: TObject);
    procedure Colordelnode1Click(Sender: TObject);
    procedure odalaOF1Click(Sender: TObject);
    procedure otalaOT1Click(Sender: TObject);
    procedure ResaltarOF1Click(Sender: TObject);
    procedure CentrarOF1Click(Sender: TObject);
    procedure btnIrClick(Sender: TObject);
    procedure btnHoyClick(Sender: TObject);
    procedure btnNodeGoToLastClick(Sender: TObject);
    procedure btnNodeGoToNextClick(Sender: TObject);
    procedure btnNodeGoToPrevClick(Sender: TObject);
    procedure btnNodeGoToFirstClick(Sender: TObject);
    procedure btnShowCentrosKPIClick(Sender: TObject);
    procedure btnConfigCentrosClick(Sender: TObject);
    procedure btnKPIVisibleClick(Sender: TObject);
    procedure btnKPIAllClick(Sender: TObject);
    procedure btnShowWeekendsClick(Sender: TObject);
    procedure lblTituloClick(Sender: TObject);
    procedure btnClearOperariosClick(Sender: TObject);
    procedure cbDepartamentosPropertiesChange(Sender: TObject);
    procedure btnDesasignarSelClick(Sender: TObject);
    procedure btnAutoPlanSelClick(Sender: TObject);
    procedure cxButton1Click(Sender: TObject);
    procedure btnCompactClick(Sender: TObject);
    procedure aaa1Click(Sender: TObject);
  private

    FCustomFieldDefs: TCustomFieldDefs;
    FPlanningRuleEngine: TPlanningRuleEngine;



    FUpdatingViewport: Boolean;
    FLoadingPrefs: Boolean;
    FLoadingFechaBloqueo: Boolean;
    FPendingPxPerMin: Double;
    FPendingScrollX: Double;
    FPendingScrollY: Double;
    FHasPendingViewport: Boolean;
    FCentreKPIs: TDictionary<Integer, TCentreKPI>;
    FCentreKPIRanges: TCentresKPIRanges;

    // Crear nodo manual (V066): item del popup de zona vacia + su handler.
    // FPopGanttPos guarda la posicion (cliente del Gantt) del right-click,
    // capturada en popGantt.OnPopup ANTES de que el menu se muestre. Sin esto,
    // al pulsar el item el cursor ya esta sobre el menu y el centro resuelto
    // seria erroneo.
    FPopGanttPos: TPoint;
    procedure ConfigurarPopupCrearNodoManual;
    procedure popGanttPopup(Sender: TObject);
    procedure CrearNodoManualClick(Sender: TObject);
    // Ajusta el inicio/fin del nodo manual a calendario laboral + sin colision,
    // via RunAutoScheduling. Si no puede, devuelve las fechas crudas del dialogo.
    procedure ColocarNodoManual(const AData: TNodoManualData;
      out AFechaInicio, AFechaFin: TDateTime);

    procedure UpdateHistoryButtons;

    procedure UpdateKPIs;

    procedure GanttControlVerticalScrolled(const ScrollY: Single);

    function BuildNodeKPIItemsFromGanttNodes: TArray<TNodeKPIItem>;
    function CalcCentreKPI_FastPrecomputed(
      const ANodes: TArray<TNodeKPIItem>;
      const ACalendar: TCentreCalendar;
      const AWindowStart, AWindowEnd: TDateTime): TCentreKPI;
    function BuildKPIRanges: TCentresKPIRanges;
    function GetCentreKPIValue(const CentreId: Integer): TCentreKPI;
    // Resuelve el LoteId del nodo actualmente seleccionado en el Gantt (0 si no
    // hay seleccion o el nodo no pertenece a ningun lote). Compartido por las
    // acciones Ver lote / Desagrupar lote.
    function LoteIdDelNodoSel: Integer;

    // --- Atajos de teclado del Gantt (navegacion / zoom / seleccion) ---
    procedure ZoomGanttCentrado(const AFactor: Single);
    procedure LimpiarSeleccionYResaltado;
    // Selecciona los nodos que solapan el periodo natural (dia/semana/mes) que
    // contiene la fecha de referencia ARef (por defecto, hoy).
    procedure SeleccionarNodosDelDia(const ARef: TDateTime);
    procedure SeleccionarNodosDeLaSemana(const ARef: TDateTime);
    procedure SeleccionarNodosDelMes(const ARef: TDateTime);
    // Selecciona todo lo planificado desde ARef hacia delante / hacia atras.
    procedure SeleccionarNodosDesde(const ARef: TDateTime);
    procedure SeleccionarNodosHasta(const ARef: TDateTime);
    // Selecciona todos los nodos de la OF del nodo actualmente seleccionado.
    procedure SeleccionarOFDelNodoSel;
    // Resuelve la fecha de referencia para las selecciones por periodo: usa el
    // inicio del nodo seleccionado si lo hay; si no, el centro del viewport.
    function FechaReferenciaSeleccion: TDateTime;
  public
    FGanttControl: TGanttControl;
    FTimelineControl: TGanttTimelineControl;
    FSummaryControl: TGanttSummaryControl;
    FCentrosControl: TGanttCentresControl;
    FOperariosRepo: TOperariosRepo;
    FMoldeRepo: TMoldeRepo;

    // Cache de KPIs per dia per a la banda de resum (reconstruit en canviar
    // viewport/dades/vista). Clau = DateOf(dia).
    FSummaryNodeCountByDay: TDictionary<TDate, Integer>;
    // Ultimas alertas detectadas (cache para abrir el dialogo sin recalcular).
    FAlertas: TArray<TAlertaItem>;
    // Vista S1: para el badge (nodos del dia y cuantos con operarios asignados).
    FSummaryS1TotalByDay: TDictionary<TDate, Integer>;
    FSummaryS1WithOpsByDay: TDictionary<TDate, Integer>;
    // Maximo valor por dia (para normalizar el heatmap del Summary 0..1).
    FSummaryMaxValue: Integer;
    // Vista S3: minutos ocupados y disponibles (capacidad) por dia. CACHE
    // INCREMENTAL: no se recalcula al hacer zoom/scroll; solo se anyaden los
    // dias visibles que aun no estaban calculados. FSummaryDiasCalc marca que
    // dias ya estan hechos (incluso si dieron 0, para no recalcularlos).
    FSummaryOcupMinByDay: TDictionary<TDate, Double>;
    FSummaryDispMinByDay: TDictionary<TDate, Double>;
    FSummaryDiasCalc: TDictionary<TDate, Boolean>;
    FSummaryDiaFestiu: TDictionary<TDate, Boolean>;  // dia sin capacidad (no calcular)
    // Timer de debounce: al mover el viewport o cambiar el layout NO calculamos
    // el Summary; lo reprogramamos y calculamos cuando el usuario para (Gantt
    // fluido). Vale para CUALQUIER vista de Summary (solo hay una activa).
    FSummaryDebounceTimer: TTimer;
    // Si True, el proximo recalculo debe invalidar antes el cache de horas
    // (cuando el disparo viene de un cambio de datos/layout, no de scroll/zoom).
    FSummaryPendingInvalidate: Boolean;

    // Debounce del calculo de ALERTAS (mismo patron que el Summary): recorrer
    // todos los nodos + calendario es caro, asi que no se recalcula en caliente
    // sino cuando el usuario para (one-shot ~250ms).
    FAlertasDebounceTimer: TTimer;

    // Cache de rotulo de operario por nodo (vista gvmOperarios). Lo puebla
    // RebuildOperarioLabelCache; el callback de render solo hace lookup.
    FOperarioLabelCache: TDictionary<Integer, string>;
    // Categoria KPI por la que se esta filtrando (0 = ninguna). Para el toggle
    // al hacer click de nuevo en el mismo panel KPI.
    FKPIFilterCategoria: Integer;


    procedure SummaryDebounceTick(Sender: TObject);
    // AInvalidate=True cuando el recalculo viene de un cambio de datos (layout,
    // edicion, filtro) y hay que rehacer el cache; False para scroll/zoom.
    procedure ScheduleSummaryRecalc(const AInvalidate: Boolean = False);



    procedure InvalidarSummaryHorasCache;



    procedure BuildSummaryHorasByDay(const AFrom, ATo: TDateTime);
    // Recalcula el cache del Summary (solo de la VENTANA visible) al mover el
    // viewport. Con debounce: no recalcula durante el arrastre. Si la vista es
    // svNone no hace nada.
    procedure RecalcSummaryActiva;



    procedure GoToDate(const ADate: TDateTime);
    // Iguala l'amplada de la columna esquerra del resum (pnlSummaryToolbar) amb
    // pnlCentros, perque la banda de KPIs quedi alineada amb el Gantt tambe quan
    // s'amaga/mostra el KPI de Centres.
    procedure SyncSummaryToolbarWidth;
    // Carrega el Node Layout Set actiu i l'aplica al FGanttControl actual. Cal
    // cridar-lo cada cop que es (re)crea el control (Inicializar el recrea segons
    // RowMode), sino el control nou no te layout i cau al render per defecte.
    procedure AplicarNodeLayoutSet;
    // Llena los combos de filtro (operarios y departamentos) desde el repo.
    procedure CargarFiltros;
    // Rotulo del operario asignado a un nodo para la vista gvmOperarios:
    // nombre si hay 1, 'VARIOS...' si varios, '' si ninguno.
    // Lookup O(1) en cache; el render lo pide por nodo en cada frame.
    function GetOperarioLabelForNode(const ADataId: Integer): string;
    // (Re)construye la cache DataId -> rotulo de operario. Llamar al cargar
    // datos y tras (re)asignar operarios. Cache vacia => callback devuelve ''.
    procedure RebuildOperarioLabelCache;
    // Calcula los DataIds de nodos cuyos operarios asignados coinciden con la
    // seleccion de los combos (operarios y/o departamentos).
    function ComputeOperarioFilterDataIds: TArray<Integer>;
    // Aplica al Gantt el efecto de resaltar/filtrar segun el estado de los
    // botones y la seleccion de los combos. Si no hay seleccion o ningun boton
    // esta pulsado, limpia el efecto.
    procedure AplicarFiltroOperarios;
    procedure btnHighlightOperariosClick(Sender: TObject);
    procedure btnFilterOperariosClick(Sender: TObject);
    // Clasifica un nodo en la categoria KPI 1/2/3 segun la vista activa (0 = no
    // entra en ninguna). Compartido por UpdateKPIs y el filtro por KPI.
    function ClassifyNodeKPI(const N: TNode; const D: TNodeData): Integer;
    // Filtra el Gantt mostrando solo los nodos de la categoria KPI indicada
    // (1/2/3). Si ya estaba ese filtro, lo quita (toggle).
    procedure FiltrarPorKPI(ACategoria: Integer);
    // Click en el icono de un KPI (Sender = TPaintBox con Tag = nº de KPI).
    procedure IconoKPIClick(Sender: TObject);
    // Recalcula las alertas de planificacion y refresca el KPI de alertas
    // (contador + color del panel segun la severidad maxima presente).
    procedure RecalcAlertas;
    // Aplica el modo foco (cadena de dependencias del nodo seleccionado) si el
    // boton Foco esta activo; en otro caso limpia el efecto.
    procedure AplicarFoco;
    // Programa el recalculo de alertas con debounce (no calcula en caliente).
    procedure ScheduleRecalcAlertas;
    procedure AlertasDebounceTick(Sender: TObject);
    // Crea un TPaintBox con un icono en la esquina inferior izquierda del panel
    // KPI: embudo (filtrar) o "quitar filtro" (AClearIcon=True, para KPI0).
    procedure CrearIconoFiltroKPI(APanel: TPanel; ATag: Integer;
      AClearIcon: Boolean);
    procedure IconoFiltroPaint(Sender: TObject);

    constructor CreateVista(AOwner: TComponent;
      AOperariosRepo: TOperariosRepo;
      AMoldeRepo: TMoldeRepo;
      ACustomFieldDefs: TCustomFieldDefs;
      APlanningRuleEngine: TPlanningRuleEngine);
    destructor Destroy; override;
    procedure RebuildCentreKPIs_Parallel(const bCalcAll: Boolean);
    property GanttControl: TGanttControl read FGanttControl;
    property TimelineControl: TGanttTimelineControl read FTimelineControl;
    property CentrosControl: TGanttCentresControl read FCentrosControl;
    // Abre el dialogo "Alertas de planificacion" sobre el Gantt actual. Lo usa
    // tanto el KPI como el menu/boton del Main.
    procedure MostrarAlertas;
    procedure Inicializar(const AFechaInicio, AFechaFin: TDateTime); overload;
    procedure Inicializar; overload;
    procedure SaveViewportPrefs;
    procedure AplicarPanelOperarios(AVisible: Boolean);
    procedure RestoreViewportPrefs;
    procedure ApplyPendingViewport;
    procedure CargarCentros;
    procedure CargarDependencias;
    procedure CargarMarcadores;
    procedure AplicarCalendariosAGantt;
    procedure IrAFecha(const ADate: TDateTime);
    // Restablece la vista del Gantt a un estado seguro: borra las prefs de
    // viewport (rango/zoom/scroll) y reinicializa con valores por defecto. Es la
    // red de seguridad si un viewport guardado deja el Gantt inservible.
    procedure RestaurarVistaPorDefecto;
  end;
implementation
{$R *.dfm}
uses
  uDMPlanner, Vcl.Dialogs, Data.Win.ADODB, Data.DB, uLoteViewer,
  uGestionMarkers, uCentreInspector, uSampleDataGenerator,
  uCentresKPI, uGestionCentres, uNodeInspector, uMarkerEditor,
  uGanttDatesDialog, uUserPrefs, System.JSON,
  uNodeCardLayout, uNodeLayoutSetRepo,
  uAssignOperaris, uGestionOperaris, uLinkEditor,
  uAlertasViewer, uAlertConfig, uGanttHistoryTimeline, uGanttShortcuts,
  uMoverFecha, Main, uBacklogScheduler;

procedure TfrmVistaGantt.Colordelnode1Click(Sender: TObject);
 var
  P: TPoint;
  F: TColorPalette64LayeredPopup;
  iTag: Integer;
  SelIndexes: TArray<Integer>;
begin

  iTag := TMenuItem(Sender).Tag;

  SelIndexes := FGanttControl.GetSelectedNodeIndexes;
  if Length(SelIndexes) = 0 then Exit;

  P := Mouse.CursorPos; // coordenades de pantalla

  F := TColorPalette64LayeredPopup.Create(Self);
  F.PopupAtScreen(P.X, P.Y,
    procedure(const C: TColor)
    var
      I: Integer;
      node: TNode;
      d: TNodeData;
      iOT, iOF: Integer;
      sOF, sOT: String;
    begin
        for I := 0 to High(SelIndexes) do
        begin
          node := FGanttControl.GetNodeAt(SelIndexes[I]);

          if (node.DataId = 0) or (not DMPlanner.NodeDataRepo.TryGetById(node.DataId, d)) then
            Continue;

          sOT := d.NumeroTrabajo;
          iOT := strtointdef(d.NumeroTrabajo,0);
          iOF := d.NumeroOrdenFabricacion;
          sOF := d.SerieFabricacion;

          case iTag of
          0: begin //...assignem color a node
               FGanttControl.ApplyOpColorsByNode(node.DataId, octOnlyNode, c, AdjustColorBrightness(c, -40));
             end;
          1: begin //...assignem color a node i OT
               FGanttControl.ApplyOpColorsByNode(node.DataId, octByTrabajo, c, AdjustColorBrightness(c, -40), sOT, sOF, iOF);
             end;
          2: begin //...assignem color a node i OF
               FGanttControl.ApplyOpColorsByNode(node.DataId, octByFabricacionSerie, c, AdjustColorBrightness(c, -40), '', sOF, iOF);
             end;
          end;
        end;

        FGanttControl.Invalidate;
    end,
    160, 160);

end;

constructor TfrmVistaGantt.CreateVista(AOwner: TComponent;
  AOperariosRepo: TOperariosRepo;
  AMoldeRepo: TMoldeRepo;
  ACustomFieldDefs: TCustomFieldDefs;
  APlanningRuleEngine: TPlanningRuleEngine);
begin
  inherited Create(AOwner);
  FCentreKPIs := TDictionary<Integer, TCentreKPI>.Create;
  FOperarioLabelCache := TDictionary<Integer, string>.Create;
  // Timer de debounce del Summary (one-shot, ~150ms). Calcula quan l'usuari
  // para de moure el viewport, sense penalitzar la fluidesa del Gantt.
  FSummaryDebounceTimer := TTimer.Create(Self);
  FSummaryDebounceTimer.Enabled := False;
  FSummaryDebounceTimer.Interval := 150;
  FSummaryDebounceTimer.OnTimer := SummaryDebounceTick;
  // Timer de debounce de ALERTAS (one-shot, ~250ms).
  FAlertasDebounceTimer := TTimer.Create(Self);
  FAlertasDebounceTimer.Enabled := False;
  FAlertasDebounceTimer.Interval := 250;
  FAlertasDebounceTimer.OnTimer := AlertasDebounceTick;
  FOperariosRepo := AOperariosRepo;
  FMoldeRepo := AMoldeRepo;
  FCustomFieldDefs := ACustomFieldDefs;
  FPlanningRuleEngine := APlanningRuleEngine;
  // Crear controles Gantt (renombrados: FGanttControl / FTimelineControl)
  FTimelineControl := TGanttTimelineControl.Create(Self);
  FTimelineControl.Parent := pnlGanttContainer;
  FTimelineControl.Align := alTop;
  FTimelineControl.LeftWidth := 0;
  FTimelineControl.PopupMenu := popTimeline;

  // Banda de RESUMEN/KPIs por dia: alineada al client de pnlSummary (la columna
  // izquierda Panel21 hace de etiqueta). Comparte coordenadas con el timeline.
  FSummaryControl := TGanttSummaryControl.Create(Self);
  FSummaryControl.Parent := pnlSummary;
  FSummaryControl.Align := alClient;
  FSummaryControl.LeftWidth := 0;
  FSummaryControl.OnViewportChanged := SummaryViewportChanged;
  FSummaryControl.OnInteraction := TimelineInteraction;
  FSummaryControl.OnDayKPI := SummaryDayKPI;

  // Botons de vista de resum (toggle en grup). btnS4 = num. de nodos por dia.
  btnS1.OnClick := btnS1Click;
  btnS2.OnClick := btnS2Click;
  btnS3.OnClick := btnS3Click;
  btnS4.OnClick := btnS4Click;

  // Botones de resaltar/filtrar operarios (toggle en grupo con btnClear).
  btnHighlightOperarios.OnClick := btnHighlightOperariosClick;
  btnFilterOperarios.OnClick := btnFilterOperariosClick;

  // Solo el ICONO de cada KPI es clicable (no el panel ni los labels):
  //   - KPI0: icono "quitar filtro" -> elimina cualquier filtro.
  //   - KPI1/2/3: icono "embudo" -> filtra por esa categoria.
  // El Tag del PaintBox identifica el KPI destino.
  CrearIconoFiltroKPI(pnlKPI0, 0, True);   // True = icono de quitar filtro
  CrearIconoFiltroKPI(pnlKPI1, 1, False);
  CrearIconoFiltroKPI(pnlKPI2, 2, False);
  CrearIconoFiltroKPI(pnlKPI3, 3, False);
  // Instanciar el control segun el RowMode del proyecto activo.
  // TGanttControlGrupo hereda de TGanttControl (fase 6.2 decision Z) asi que
  // el resto del uVistaGantt trabaja con FGanttControl: TGanttControl sin saber
  // que tipo concreto es.
  if SameText(Trim(DMPlanner.CurrentProjectRowMode), 'GRUPO') then
  begin
    FGanttControl := TGanttControlGrupo.Create(Self);
    TGanttControlGrupo(FGanttControl).NivelAgrupacion :=
      DMPlanner.CurrentProjectNivelAgrupacion;
  end
  else
    FGanttControl := TGanttControl.Create(Self);
  FGanttControl.Parent := pnlGanttContainer;
  FGanttControl.Align := alClient;
  FGanttControl.ShowHint := True;
  FGanttControl.NodePopupMenu := popNode;
  FGanttControl.PopupMenu := popGantt;
  // Item "Crear nodo manual" en el popup de zona vacia del Gantt. Se crea en
  // codigo (no en el DFM) para no tocar el DFM grande de la vista. (V066)
  ConfigurarPopupCrearNodoManual;
  // Importante: el Gantt necesita el repo para resolver NodeData al pintar.
  // Sin esto, BuildDataIdIndex/RebuildLayout acceden a puntero nil.
  FGanttControl.SetNodeRepo(DMPlanner.NodeDataRepo);
  AplicarNodeLayoutSet;   // el render dels nodes per Vista necessita el set

  FCentrosControl := TGanttCentresControl.Create(Self);
  FCentrosControl.Parent := pnlCentros;
  FCentrosControl.Align := alLeft;
  FCentrosControl.PopupMenu := popCentros;
  pnlCentros.Width := FCentrosControl.BaseWidth;
  FCentrosControl.VerIndicadores := False;
  SyncSummaryToolbarWidth;
  // Cablear eventos (stubs por ahora — lógica real en pasos siguientes)
  FTimelineControl.OnViewportChanged := TimelineViewportChanged;
  FTimelineControl.OnInteraction := TimelineInteraction;

  FGanttControl.OnViewportChanged := GanttViewportChanged;
  FGanttControl.OnScrollYChanged := GanttScrollYChanged;
  FGanttControl.OnNodeDblClick := GanttNodeDblClick;
  FGanttControl.OnMarkerDblClick := GanttMarkerDblClick;
  FGanttControl.OnMarkerMoved := GanttMarkerMoved;
  FGanttControl.OnStatsChanged := GanttStatsChanged;
  FGanttControl.OnLayoutChanged := GanttLayoutChanged;
  FGanttControl.OnNodeSelected := GanttNodeSelected;
  FGanttControl.OnVoid := GanttVoidClick;
  FGanttControl.OnFechaBloqueoChanged := GanttFechaBloqueoChanged;
  FGanttControl.OnGetOperarioLabel :=
    function(const ADataId: Integer): string
    begin
      Result := GetOperarioLabelForNode(ADataId);
    end;
  // X del pill del overlay: limpiar efecto + combos (igual que el boton X).
  FGanttControl.OnOpFilterClear := btnClearOperariosClick;

  FCentrosControl.OnScrollYChanged := CentresScrollYChanged;
  // Centros clampa su scroll al MISMO maximo que el Gantt (evita desalineacion
  // al llegar al final por diferencia de ClientHeight entre ambos controles).
  FCentrosControl.GetMaxScrollYFunc :=
    function: Single
    begin
      Result := FGanttControl.GetMaxScrollY;
    end;

end;


procedure TfrmVistaGantt.cxButton1Click(Sender: TObject);
begin
 // El boton abre el timeline visual del historico (navegar adelante/atras con
  // contador). El undo directo de un paso sigue disponible con Ctrl+Z.
  TfrmGanttHistoryTimeline.Execute(Self, FGanttControl, btnUndo);
end;

procedure TfrmVistaGantt.btnCompactarClick(Sender: TObject);
begin
  if FGanttControl = nil then Exit;
  // Toggle: muestra solo los centros con nodos en el viewport actual. El boton
  // (GroupIndex=1, AllowAllUp) refleja el estado pulsado/no pulsado.
  FGanttControl.CompactToViewport := btnCompactar.Down;
  if btnCompactar.Down then
    btnCompactar.Hint := 'Mostrando solo centros con carga en la vista actual'
  else
    btnCompactar.Hint := 'Mostrar todos los centros';
end;

procedure TfrmVistaGantt.btnAtajosClick(Sender: TObject);
begin
  TfrmGanttShortcuts.Execute(Self);
end;

procedure TfrmVistaGantt.btnFocoClick(Sender: TObject);
begin
  // Toggle: al activar, atenua todo salvo el nodo seleccionado y su cadena de
  // dependencias. Se reaplica al cambiar de seleccion (ver AplicarFoco).
  AplicarFoco;
  if btnFoco.Down then
    btnFoco.Hint := 'Resaltando la cadena de dependencias del nodo seleccionado'
  else
    btnFoco.Hint := 'Modo foco desactivado';
end;

procedure TfrmVistaGantt.AplicarFoco;
var
  idx: Integer;
begin
  if FGanttControl = nil then Exit;
  if not btnFoco.Down then
  begin
    // Solo limpiar si el efecto activo es nuestro (no pisar un filtro de
    // operarios/alertas en curso).
    FGanttControl.ClearOperarioFilter;
    Exit;
  end;
  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then
  begin
    FGanttControl.ClearOperarioFilter;
    Exit;
  end;
  FGanttControl.FocusChain(idx, False);   // False = atenuar (no ocultar)
end;

procedure TfrmVistaGantt.btnCompactClick(Sender: TObject);
begin
 if FGanttControl = nil then Exit;
  // Toggle: muestra solo los centros con nodos en el viewport actual. El boton
  // (GroupIndex=1, AllowAllUp) refleja el estado pulsado/no pulsado.
  FGanttControl.CompactToViewport := btnCompact.Down;
  if btnCompact.Down then
    btnCompact.Hint := 'Mostrando solo centros con carga en la vista actual'
  else
    btnCompact.Hint := 'Mostrar todos los centros';
end;

procedure TfrmVistaGantt.btnClearOperariosClick(Sender: TObject);

  procedure ClearCheckCombo(ACombo: TcxCheckComboBox);
  var
    I: Integer;
  begin
    // En un TcxCheckComboBox la seleccion son los items marcados (States),
    // no ItemIndex. Hay que desmarcarlos todos para vaciar el combo.
    ACombo.Properties.BeginUpdate;
    try
      for I := 0 to ACombo.Properties.Items.Count - 1 do
        ACombo.States[I] := cbsUnchecked;
    finally
      ACombo.Properties.EndUpdate;
    end;
  end;

begin
  ClearCheckCombo(FcxFilterOperarios);
  ClearCheckCombo(cbDepartamentos);
  // Soltar los toggles de resaltar/filtrar y deshabilitarlos (sin seleccion no
  // tienen sentido). Se llama tambien desde la X del overlay (no via UI), por
  // eso bajamos .Down explicitamente ademas de .Enabled.
  btnHighlightOperarios.Down := False;
  btnFilterOperarios.Down := False;
  btnHighlightOperarios.Enabled := False;
  btnFilterOperarios.Enabled := False;
  // Tambien resetear el filtro por KPI (comparten el mismo efecto en el Gantt).
  FKPIFilterCategoria := 0;
  // Quitar cualquier efecto de resaltar/filtrar del Gantt.
  if FGanttControl <> nil then
  begin
    FGanttControl.ClearOperarioFilter;
    ScheduleSummaryRecalc(True);  // recuperar el conteo completo (con debounce)
  end;
end;

procedure TfrmVistaGantt.btnDesasignarSelClick(Sender: TObject);
var
  SelIndexes: TArray<Integer>;
  I: Integer;
  N: TNode;
  D: TNodeData;
  Ids: TArray<Integer>;
begin
  if FGanttControl = nil then Exit;
  SelIndexes := FGanttControl.GetSelectedNodeIndexes;
  if Length(SelIndexes) = 0 then
  begin
    ShowMessage('Selecciona al menos un nodo en el Gantt.');
    Exit;
  end;
  if MessageDlg(Format('?Quitar TODAS las asignaciones de operarios de %d nodo(s)?',
       [Length(SelIndexes)]),
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  if not Assigned(FOperariosRepo) or not Assigned(DMPlanner.NodeDataRepo) then
    Exit;

  SetLength(Ids, Length(SelIndexes));
  for I := 0 to High(SelIndexes) do
  begin
    N := FGanttControl.GetNodeAt(SelIndexes[I]);
    Ids[I] := N.DataId;
    FOperariosRepo.ClearAsignacionsByNode(N.DataId);
    if DMPlanner.NodeDataRepo.TryGetById(N.DataId, D) then
    begin
      D.OperariosAsignados := 0;
      D.Modified := True;
      DMPlanner.NodeDataRepo.AddOrUpdate(D);
    end;
  end;

  RebuildOperarioLabelCache;
  FGanttControl.RebuildLayout;
  FGanttControl.Invalidate;
  if Assigned(Form1) then
    Form1.NotifyPlanModified(Ids);

end;

procedure TfrmVistaGantt.btnShowWeekendsClick(Sender: TObject);
var
  bHide: Boolean;
begin
  bHide := not FGanttControl.HideWeekends;

  // El timeline debe conocer el MISMO flag que el Gantt: ambos mapean tiempo->X
  // con VisibleMinutesBetween, que depende de HideWeekends. Si solo lo cambia el
  // Gantt, el timeline sigue dibujando los dias con findes y queda desplazado.
  // Propagamos el flag al timeline PRIMERO (sin que dispare su propio viewport;
  // el guard FUpdatingViewport lo evita) y luego al Gantt, que al normalizar su
  // FStartTime/FScrollX emitira OnViewportChanged -> el timeline se re-sincroniza
  // ya con el flag correcto.
  FUpdatingViewport := True;
  try
    FTimelineControl.HideWeekends := bHide;
    if Assigned(FSummaryControl) then
      FSummaryControl.HideWeekends := bHide;
  finally
    FUpdatingViewport := False;
  end;

  FGanttControl.HideWeekends := bHide;
end;

procedure TfrmVistaGantt.btnShowCentrosKPIClick(Sender: TObject);
var
  bShow: Boolean;
begin

  bShow := not CentrosControl.VerIndicadores;

  CentrosControl.VerIndicadores := bShow;

  // Ajustar el panell al nou Width del control (BaseWidth + IndicadoresWidth o BaseWidth)
  pnlCentros.Width := FCentrosControl.Width;
  // La columna esquerra de la banda de resum segueix l'amplada de Centros.
  SyncSummaryToolbarWidth;

  FGanttControl.NotifyViewportChanged;

  btnKPIVisible.Visible := bShow;
  btnKPIAll.Visible := bShow;
  LblIndicadores.Visible := bShow;

  if FCentrosControl.VerIndicadores then
    RebuildCentreKPIs_Parallel( FALSE );

  FCentrosControl.Repaint;

  if bShow then
   btnKPIVisibleClick( btnKPIVisible );
end;

procedure TfrmVistaGantt.GoToDate(const ADate: TDateTime);
var
  sx: Single;
begin
  sx := FTimelineControl.CalcScrollXToCenterDate(ADate);
  FTimelineControl.ScrollX := sx; // via setter (recomanat)
  FGanttControl.ScrollX := sx;    // via setter (recomanat)
end;

procedure TfrmVistaGantt.btnGanttDatesClick(Sender: TObject);
var
  FIni, FFin, T0, T1: TDateTime;
  I, NodosFuera: Integer;
  N: TNode;
begin
  FIni := dtFechaInicioGantt.Date;
  FFin := dtFechaFinGantt.Date;
  if not TfrmGanttDatesDialog.Execute(FIni, FFin) then Exit;

  T0 := DayStart(FIni - 2);
  T1 := DayEnd(FFin);
  NodosFuera := 0;
  if Assigned(FGanttControl) then
    for I := 0 to FGanttControl.NodeCount - 1 do
    begin
      N := FGanttControl.GetNodeAt(I);
      if (N.StartTime < T0) or (N.EndTime > T1) then
        Inc(NodosFuera);
    end;

  if NodosFuera > 0 then
    if MessageDlg(
         Format('Hay %d nodo(s) fuera del rango seleccionado.' + sLineBreak +
                '¿Desea continuar igualmente?', [NodosFuera]),
         mtWarning, [mbYes, mbNo], 0) <> mrYes then
      Exit;

  dtFechaInicioGantt.Date := FIni;
  dtFechaFinGantt.Date := FFin;
  Inicializar(FIni, FFin);
  SaveViewportPrefs;

end;

procedure TfrmVistaGantt.btnHoyClick(Sender: TObject);
begin
   GoToDate( Now );
end;

procedure TfrmVistaGantt.btnIrClick(Sender: TObject);
begin
  if not varisnull(cxDateEdit1.EditValue) then
   GoToDate( cxDateEdit1.Date );
end;

procedure TfrmVistaGantt.btnNodeGoToFirstClick(Sender: TObject);
begin
  FGanttControl.GoToFirstNode;
end;

procedure TfrmVistaGantt.btnNodeGoToLastClick(Sender: TObject);
begin
 FGanttControl.GoToLastNode;
end;

procedure TfrmVistaGantt.btnNodeGoToNextClick(Sender: TObject);
begin
  FGanttControl.GoToNextNode;
end;

procedure TfrmVistaGantt.btnNodeGoToPrevClick(Sender: TObject);
begin
  FGanttControl.GoToPreviousNode;
end;

procedure TfrmVistaGantt.Desactivarfechabloqueo1Click(Sender: TObject);
begin

  FGanttControl.FechaBloqueo := 0;

end;

procedure TfrmVistaGantt.GanttControlVerticalScrolled(const ScrollY: Single);
begin
  if Assigned(FCentrosControl) then
   FCentrosControl.ScrollY := ScrollY;
end;

procedure TfrmVistaGantt.FormCreate(Sender: TObject);
var
  Modo: string;
begin
  // El form ve TODAS las teclas primero (atajos del Gantt). Sin esto, cuando el
  // foco esta en el control del Gantt, FormKeyDown no se dispara.
  KeyPreview := True;

  btnFocus.Left := -300;

  cxDateEdit1.Date := now;

  Panel1.Height := pnlTitulo.Height + pnlSubTitulo.Height;

  cbVistas.properties.onchange := nil;
  cbVistas.ItemIndex := 0;
  cbVistas.properties.onchange := cbVistasPropertiesChange;

  // Modo de agrupacion (RowMode) del proyecto activo. Solo 'CENTROS' esta
  // operativo. 'GRUPO' y 'TREE' requieren sus propios controles (fase 6.2 / 6.3)
  // y aqui simplemente avisamos al usuario para que lo cambie en Gestion de
  // Proyectos si lo habia configurado antes de tener las vistas implementadas.
  Modo := UpperCase(Trim(DMPlanner.CurrentProjectRowMode));
  if Modo = 'TREE' then
    ShowMessage(
      'El proyecto activo tiene modo de vista "TREE", que aun no ' +
      'esta disponible.' + sLineBreak +
      'Se mostrara la vista estandar por Centros.' + sLineBreak + sLineBreak +
      'Cambia el modo en Gestion de Proyectos cuando la vista TREE ' +
      'este operativa.');
end;


procedure TfrmVistaGantt.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

  // Maj+F1 o '?' -> panel de atajos. F1 solo -> ayuda contextual (MD).
  if (Key = VK_F1) and (ssShift in Shift) then
  begin
    TfrmGanttShortcuts.Execute(Self);
    Key := 0;
  end
  else if Key = VK_F1 then
  begin
    TfrmHelpGuide.Execute;
    Key := 0;
  end
  // A partir de aqui todos los atajos operan sobre el Gantt: si aun no existe
  // (form no inicializado del todo), no hacemos nada.
  else if FGanttControl = nil then
    // sin accion
  else if (ssCtrl in Shift) and (Key = Ord('Z')) then
  begin
    FGanttControl.UndoLastAction;
    UpdateHistoryButtons;
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = Ord('Y')) then
  begin
    FGanttControl.RedoLastAction;
    UpdateHistoryButtons;
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = Ord('H')) then
  begin
    cxButton1Click(nil);            // Historial (timeline visual)
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = Ord('K')) then
  begin
    btnCompactar.Down := not btnCompactar.Down;   // toggle Compactar
    btnCompactarClick(nil);
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = Ord('F')) then
  begin
    btnFoco.Down := not btnFoco.Down;             // toggle Foco
    btnFocoClick(nil);
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = Ord('E')) then
  begin
    CentrarOF1Click(nil);           // Centrar OF en pantalla
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = Ord('R')) then
  begin
    btnResaltarOF.SpeedButtonOptions.Down :=
      not btnResaltarOF.SpeedButtonOptions.Down;  // toggle Resaltar OF
    btnResaltarOFClick(btnResaltarOF);            // Sender real (usa Sender.Tag)
    Key := 0;
  end
  // ----- Navegacion: ir al primer / ultimo nodo del plan -----
  else if (ssCtrl in Shift) and (Key = VK_HOME) then
  begin
    FGanttControl.GoToFirstNode;
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = VK_END) then
  begin
    FGanttControl.GoToLastNode;
    Key := 0;
  end
  // ----- Hoy: centrar el dia actual en pantalla (Ctrl+J) -----
  else if (ssCtrl in Shift) and (Key = Ord('J')) then
  begin
    btnHoyClick(nil);
    Key := 0;
  end
  // ----- Zoom por teclado (centrado en pantalla). Ctrl + '+/-' y reset -----
  else if (ssCtrl in Shift) and
          ((Key = VK_ADD) or (Key = VK_OEM_PLUS)) then
  begin
    ZoomGanttCentrado(1.25);
    Key := 0;
  end
  else if (ssCtrl in Shift) and
          ((Key = VK_SUBTRACT) or (Key = VK_OEM_MINUS)) then
  begin
    ZoomGanttCentrado(0.8);
    Key := 0;
  end
  // ----- Seleccion: recorrer nodos con Tab / Mayus+Tab -----
  // Solo cuando el foco esta en el Gantt; si no, Tab navega entre controles.
  else if (Key = VK_TAB) and (ActiveControl = FGanttControl)
          and (ssShift in Shift) then
  begin
    FGanttControl.GoToPreviousNode;
    Key := 0;
  end
  else if (Key = VK_TAB) and (ActiveControl = FGanttControl) then
  begin
    FGanttControl.GoToNextNode;
    Key := 0;
  end
  // ----- Seleccion por periodo (referencia = nodo en foco o centro de vista) -----
  // Ctrl+1 dia, Ctrl+2 semana, Ctrl+3 mes.
  else if (ssCtrl in Shift) and not (ssShift in Shift) and (Key = Ord('1')) then
  begin
    SeleccionarNodosDelDia(FechaReferenciaSeleccion);
    Key := 0;
  end
  else if (ssCtrl in Shift) and not (ssShift in Shift) and (Key = Ord('2')) then
  begin
    SeleccionarNodosDeLaSemana(FechaReferenciaSeleccion);
    Key := 0;
  end
  else if (ssCtrl in Shift) and not (ssShift in Shift) and (Key = Ord('3')) then
  begin
    SeleccionarNodosDelMes(FechaReferenciaSeleccion);
    Key := 0;
  end
  // ----- Seleccion direccional: Ctrl+Mayus+Der (desde) / Izq (hasta) -----
  // Solo con foco en el Gantt para no pisar la seleccion de texto en edits.
  else if (ActiveControl = FGanttControl)
          and (ssCtrl in Shift) and (ssShift in Shift) and (Key = VK_RIGHT) then
  begin
    SeleccionarNodosDesde(FechaReferenciaSeleccion);
    Key := 0;
  end
  else if (ActiveControl = FGanttControl)
          and (ssCtrl in Shift) and (ssShift in Shift) and (Key = VK_LEFT) then
  begin
    SeleccionarNodosHasta(FechaReferenciaSeleccion);
    Key := 0;
  end
  // ----- Seleccionar toda la OF del nodo en foco (Ctrl+Mayus+O) -----
  else if (ssCtrl in Shift) and (ssShift in Shift) and (Key = Ord('O')) then
  begin
    SeleccionarOFDelNodoSel;
    Key := 0;
  end
  // ----- Seleccionar todos los nodos visibles (Ctrl+A) -----
  // Solo con foco en el Gantt; en un edit, Ctrl+A selecciona su texto.
  else if (ActiveControl = FGanttControl)
          and (ssCtrl in Shift) and (Key = Ord('A')) then
  begin
    FGanttControl.SelectNodesInDateRange(
      FGanttControl.StartTime, FGanttControl.EndTime, False);
    FGanttControl.Invalidate;
    Key := 0;
  end
  // ----- Esc: limpiar seleccion, foco y resaltado de un golpe -----
  // Solo con foco en el Gantt; si no, Esc cierra combos/edits.
  else if (ActiveControl = FGanttControl) and (Key = VK_ESCAPE) then
  begin
    LimpiarSeleccionYResaltado;
    Key := 0;
  end;
end;

// Zoom por teclado manteniendo el punto central de la pantalla. Calculamos la
// fecha bajo el centro ANTES de cambiar el zoom y recentramos despues, para que
// el usuario no pierda el contexto. El factor >1 acerca, <1 aleja; el clamp lo
// aplica el propio setter de PxPerMinute (0.2..40).
procedure TfrmVistaGantt.ZoomGanttCentrado(const AFactor: Single);
var
  TCentro: TDateTime;
begin
  TCentro := FGanttControl.StartVisibleTime +
    (FGanttControl.EndVisibleTime - FGanttControl.StartVisibleTime) / 2;
  FGanttControl.PxPerMinute := FGanttControl.PxPerMinute * AFactor;
  FGanttControl.ScrollX := FGanttControl.CalcScrollXToCenterDate(TCentro);
  FGanttControl.Invalidate;
end;

// Esc: deja el Gantt "limpio". Quita la seleccion de nodos y, si estaban
// activos, desactiva los toggles de Foco y Resaltar OF (que ademas limpian su
// propio estado de resaltado via su Click).
procedure TfrmVistaGantt.LimpiarSeleccionYResaltado;
begin
  FGanttControl.ClearSelection;

  if btnFoco.Down then
  begin
    btnFoco.Down := False;
    btnFocoClick(nil);
  end;

  if btnResaltarOF.SpeedButtonOptions.Down then
  begin
    btnResaltarOF.SpeedButtonOptions.Down := False;
    btnResaltarOFClick(btnResaltarOF);
  end;

  FGanttControl.Invalidate;
end;

// Fecha de referencia para las selecciones por periodo: si hay un nodo
// seleccionado usamos su instante medio (asi "esta semana" es la del nodo en
// foco, no la de hoy); si no, el centro del viewport visible.
function TfrmVistaGantt.FechaReferenciaSeleccion: TDateTime;
var
  idx: Integer;
begin
  idx := FGanttControl.SelectedNodeIndex;
  if idx >= 0 then
    Exit(FGanttControl.GetNodeMidTime(idx));

  Result := FGanttControl.StartVisibleTime +
    (FGanttControl.EndVisibleTime - FGanttControl.StartVisibleTime) / 2;
end;

// Selecciona los nodos que tocan el dia natural de ARef.
procedure TfrmVistaGantt.SeleccionarNodosDelDia(const ARef: TDateTime);
var
  d0: TDateTime;
begin
  d0 := DateOf(ARef);
  FGanttControl.SelectNodesInDateRange(d0, d0 + 1, True);
  FGanttControl.Invalidate;
end;

// Selecciona los nodos que tocan la semana natural (Lun-Dom) de ARef.
procedure TfrmVistaGantt.SeleccionarNodosDeLaSemana(const ARef: TDateTime);
var
  d0, d1: TDateTime;
begin
  d0 := StartOfTheWeek(ARef);    // lunes 00:00 (ISO)
  d1 := d0 + 7;                  // lunes siguiente 00:00
  FGanttControl.SelectNodesInDateRange(d0, d1, True);
  FGanttControl.Invalidate;
end;

// Selecciona los nodos que tocan el mes natural de ARef.
procedure TfrmVistaGantt.SeleccionarNodosDelMes(const ARef: TDateTime);
var
  d0, d1: TDateTime;
begin
  d0 := StartOfTheMonth(ARef);
  d1 := IncMonth(d0, 1);
  FGanttControl.SelectNodesInDateRange(d0, d1, True);
  FGanttControl.Invalidate;
end;

// Todo lo planificado desde ARef (incluido) hacia delante.
procedure TfrmVistaGantt.SeleccionarNodosDesde(const ARef: TDateTime);
begin
  FGanttControl.SelectNodesInDateRange(ARef, FGanttControl.EndTime, True);
  FGanttControl.Invalidate;
end;

// Todo lo planificado hasta ARef (incluido) hacia atras.
procedure TfrmVistaGantt.SeleccionarNodosHasta(const ARef: TDateTime);
begin
  FGanttControl.SelectNodesInDateRange(FGanttControl.StartTime, ARef, True);
  FGanttControl.Invalidate;
end;

// Selecciona todos los nodos (OT/OP) que comparten la OF del nodo en foco.
procedure TfrmVistaGantt.SeleccionarOFDelNodoSel;
var
  idx, I: Integer;
  node: TNode;
  D: TNodeData;
  Indexes: TArray<Integer>;
begin
  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;

  node := FGanttControl.SelectedNode;
  if not DMPlanner.NodeDataRepo.TryGetById(node.DataId, D) then Exit;
  if D.NumeroOrdenFabricacion = 0 then Exit;

  Indexes := FGanttControl.FindNodesByOF(
    D.NumeroOrdenFabricacion, D.SerieFabricacion);
  if Length(Indexes) = 0 then Exit;

  FGanttControl.ClearSelection;
  for I := 0 to High(Indexes) do
    FGanttControl.SelectNodeIndex(Indexes[I], False);
  FGanttControl.Invalidate;
end;

procedure TfrmVistaGantt.Indicadores1Click(Sender: TObject);
begin
  TfrmCentresKPI.Execute(Self,
  DMPlanner.CentresRepo.GetAll,
  FGanttControl, DMPlanner.NodeDataRepo, FOperariosRepo,
  FGanttControl.FindCentreIndexById(FCentrosControl.SelectedCentreId));
end;

procedure TfrmVistaGantt.INFO3Click(Sender: TObject);
var
  centreId: Integer;
  cIdx, I: Integer;
  c: TCentreTreball;
  Centres: TArray<TCentreTreball>;
  Cal: TCentreCalendar;
  SampleCal: TSampleCalendario;
  PCal: PSampleCalendario;
  LunesPeriods, SabPeriods, DomPeriods: TArray<TNonWorkingPeriod>;
  FullSab, FullDom: Boolean;
begin
  centreId := FCentrosControl.SelectedCentreId;
  if centreId < 0 then Exit;
  cIdx := FGanttControl.FindCentreIndexById(centreId);
  if cIdx < 0 then Exit;

  c := FGanttControl.GetCentreByIndex(cIdx);

  // Construir TSampleCalendario a partir del TCentreCalendar asociado al centro.
  PCal := nil;
  if DMPlanner.CentresRepo <> nil then
  begin
    Cal := DMPlanner.CentresRepo.GetCalendarFor(c.Id);
    if Cal <> nil then
    begin
      SampleCal.Nombre := Cal.Name;

      // Periodos no laborables del lunes (ISO 1) como representativos de L-V.
      LunesPeriods := Cal.NonWorkingPeriodsForDate(EncodeDate(2024, 1, 1)); // lunes
      SetLength(SampleCal.PeriodosLV, Length(LunesPeriods));
      for I := 0 to High(LunesPeriods) do
      begin
        SampleCal.PeriodosLV[I].StartH := HourOf(LunesPeriods[I].StartTimeOfDay);
        SampleCal.PeriodosLV[I].StartM := MinuteOf(LunesPeriods[I].StartTimeOfDay);
        SampleCal.PeriodosLV[I].EndH   := HourOf(LunesPeriods[I].EndTimeOfDay);
        SampleCal.PeriodosLV[I].EndM   := MinuteOf(LunesPeriods[I].EndTimeOfDay);
      end;

      // Fin de semana completo si sabado (ISO 6) y domingo (ISO 7) tienen
      // un periodo que cubre 00:00..23:59.
      SabPeriods := Cal.NonWorkingPeriodsForDate(EncodeDate(2024, 1, 6)); // sabado
      DomPeriods := Cal.NonWorkingPeriodsForDate(EncodeDate(2024, 1, 7)); // domingo
      FullSab := (Length(SabPeriods) > 0) and
                 (SabPeriods[0].StartTimeOfDay <= EncodeTime(0, 1, 0, 0)) and
                 (SabPeriods[0].EndTimeOfDay   >= EncodeTime(23, 58, 0, 0));
      FullDom := (Length(DomPeriods) > 0) and
                 (DomPeriods[0].StartTimeOfDay <= EncodeTime(0, 1, 0, 0)) and
                 (DomPeriods[0].EndTimeOfDay   >= EncodeTime(23, 58, 0, 0));
      SampleCal.FinDeSemanaCompleto := FullSab and FullDom;

      PCal := @SampleCal;
    end;
  end;

  if TfrmCentreInspector.Execute(c, False, PCal) then
  begin
    // Persistir a BD y actualizar repo en memoria.
    if DMPlanner.CentresRepo <> nil then
      DMPlanner.CentresRepo.Update(DMPlanner.CodigoEmpresa, c);

    // Aplicar cambios al Gantt (hace RebuildLayout si procede).
    FGanttControl.UpdateCentre(c.Id, c);

    // Refrescar panel lateral de centros con lista actualizada.
    if DMPlanner.CentresRepo <> nil then
    begin
      Centres := DMPlanner.CentresRepo.GetAll;
      FCentrosControl.SetCentres(Centres);
    end;
    FCentrosControl.SetRows(FGanttControl.GetRowsCopy);
  end;
end;

procedure TfrmVistaGantt.Button12Click(Sender: TObject);
begin
  UpdateHistoryButtons;
end;

procedure TfrmVistaGantt.Inicializar(const AFechaInicio, AFechaFin: TDateTime);
var
  T0, T1: TDateTime;
  ModoActual: string;
  NecesitaGrupo, EsGrupoActual: Boolean;
begin
  // Asegurar que FGanttControl corresponde al RowMode del proyecto actual.
  // El form se crea una sola vez pero el usuario puede cambiar el mode del
  // proyecto entre aperturas, asi que recreamos el control si el tipo no
  // casa con el mode actual.
  ModoActual := UpperCase(Trim(DMPlanner.CurrentProjectRowMode));
  NecesitaGrupo := ModoActual = 'GRUPO';
  EsGrupoActual := FGanttControl is TGanttControlGrupo;
  if NecesitaGrupo <> EsGrupoActual then
  begin
    FreeAndNil(FGanttControl);
    if NecesitaGrupo then
    begin
      FGanttControl := TGanttControlGrupo.Create(Self);
      TGanttControlGrupo(FGanttControl).NivelAgrupacion :=
        DMPlanner.CurrentProjectNivelAgrupacion;
    end
    else
      FGanttControl := TGanttControl.Create(Self);
    FGanttControl.Parent := pnlGanttContainer;
    FGanttControl.Align := alClient;
    FGanttControl.ShowHint := True;
    FGanttControl.NodePopupMenu := popNode;
    FGanttControl.PopupMenu := popGantt;
    FGanttControl.SetNodeRepo(DMPlanner.NodeDataRepo);
    FGanttControl.OnViewportChanged := GanttViewportChanged;
    FGanttControl.OnScrollYChanged := GanttScrollYChanged;
    FGanttControl.OnNodeDblClick := GanttNodeDblClick;
    FGanttControl.OnMarkerDblClick := GanttMarkerDblClick;
    FGanttControl.OnMarkerMoved := GanttMarkerMoved;
    FGanttControl.OnStatsChanged := GanttStatsChanged;
    FGanttControl.OnLayoutChanged := GanttLayoutChanged;
    FGanttControl.OnNodeSelected := GanttNodeSelected;
    FGanttControl.OnVoid := GanttVoidClick;
    FGanttControl.OnFechaBloqueoChanged := GanttFechaBloqueoChanged;
    FGanttControl.OnGetOperarioLabel :=
      function(const ADataId: Integer): string
      begin
        Result := GetOperarioLabelForNode(ADataId);
      end;
    FGanttControl.OnOpFilterClear := btnClearOperariosClick;
    AplicarNodeLayoutSet;   // control recreat -> reaplicar el set de layout
  end
  else if NecesitaGrupo then
  begin
    // Mismo tipo pero puede haber cambiado NivelAgrupacion
    TGanttControlGrupo(FGanttControl).NivelAgrupacion :=
      DMPlanner.CurrentProjectNivelAgrupacion;
  end;

  dtFechaInicioGantt.Date := AFechaInicio;
  dtFechaFinGantt.Date := AFechaFin;
  T0 := DayStart(AFechaInicio - 2);
  T1 := DayEnd(AFechaFin);
  if T1 < T0 then
    T1 := DayEnd(T0);
  FTimelineControl.SetTimeRange(T0, T1);
  if Assigned(FSummaryControl) then
    FSummaryControl.SetTimeRange(T0, T1);
  // También el Gantt: sin esto, FContentWidth queda limitado a ClientWidth
  // y el panning del timeline no puede desplazar el Gantt (MaxScrollX = 0).
  FGanttControl.SetTimeRange(T0, T1);
  CargarCentros;
  // Centrar la vista en la fecha actual al abrir.
  IrAFecha(Now);
  // Sincronizar la banda de resumen con el viewport inicial del timeline y
  // forzar el repintado (SetViewport puede salir por valores iguales y dejar la
  // banda sin pintar hasta el primer scroll/zoom).
  if Assigned(FSummaryControl) then
  begin
    FSummaryControl.SetTimeRange(T0, T1);
    FSummaryControl.SetViewport(FTimelineControl.StartTime,
      FTimelineControl.PxPerMinute, FTimelineControl.ScrollX);
    // Carga de datos: el cache de horas (de un plan anterior) ya no vale.
    InvalidarSummaryHorasCache;
    RebuildSummaryData;
    FSummaryControl.Invalidate;
  end;
end;

const
  SCREEN_KEY_VISTA_GANTT = 'VistaGantt';
  PREFS_VERSION = 1;
  ISO_DATE = 'yyyy-mm-dd';

function IsoFormatSettings: TFormatSettings;
begin
  Result := TFormatSettings.Create;
  Result.DateSeparator := '-';
  Result.ShortDateFormat := ISO_DATE;
end;

function TfrmVistaGantt.GetOperarioLabelForNode(const ADataId: Integer): string;
begin
  // Lookup O(1). La cache se puebla en RebuildOperarioLabelCache; aqui NO se
  // recorre el repo (esto se llama por nodo en cada repintado).
  if not FOperarioLabelCache.TryGetValue(ADataId, Result) then
    Result := '';
end;

procedure TfrmVistaGantt.RebuildOperarioLabelCache;
var
  Asigs: TArray<TAsignacionOperario>;
  I: Integer;
  CountByNode: TDictionary<Integer, Integer>;
  FirstOpByNode: TDictionary<Integer, Integer>;
  Op: TOperario;
  Pair: TPair<Integer, Integer>;
  N, OpId: Integer;
begin
  FOperarioLabelCache.Clear;
  if not Assigned(FOperariosRepo) then Exit;

  // Una sola pasada sobre TODAS las asignaciones: contamos por nodo y
  // guardamos el primer operario de cada nodo. Asi evitamos O(N) por nodo.
  CountByNode := TDictionary<Integer, Integer>.Create;
  FirstOpByNode := TDictionary<Integer, Integer>.Create;
  try
    Asigs := FOperariosRepo.GetAllAsignacions;
    for I := 0 to High(Asigs) do
    begin
      if CountByNode.TryGetValue(Asigs[I].DataId, N) then
        CountByNode[Asigs[I].DataId] := N + 1
      else
      begin
        CountByNode.Add(Asigs[I].DataId, 1);
        FirstOpByNode.Add(Asigs[I].DataId, Asigs[I].OperarioId);
      end;
    end;

    for Pair in CountByNode do
    begin
      if Pair.Value > 1 then
        FOperarioLabelCache.Add(Pair.Key, 'VARIOS...')
      else
      begin
        FirstOpByNode.TryGetValue(Pair.Key, OpId);
        if FOperariosRepo.GetOperarioById(OpId, Op) then
          FOperarioLabelCache.Add(Pair.Key, Op.Nombre)
        else
          FOperarioLabelCache.Add(Pair.Key, IntToStr(OpId));
      end;
    end;
  finally
    CountByNode.Free;
    FirstOpByNode.Free;
  end;
end;

function TfrmVistaGantt.ComputeOperarioFilterDataIds: TArray<Integer>;
var
  I: Integer;
  OpIdsSel: TDictionary<Integer, Boolean>;   // operarios marcados directamente
  DeptIdsSel: TDictionary<Integer, Boolean>; // departamentos marcados
  OpValido: TDictionary<Integer, Boolean>;   // operarios que cuentan como match
  ResultIds: TDictionary<Integer, Boolean>;  // DataIds resultantes (dedup)
  AllOps: TArray<TOperario>;
  Depts: TArray<TDepartamento>;
  Asigs: TArray<TAsignacionOperario>;
  Tag, J: Integer;
  Matches: Boolean;
  List: TList<Integer>;
  Key: Integer;
begin
  SetLength(Result, 0);
  if not Assigned(FOperariosRepo) then Exit;

  OpIdsSel := TDictionary<Integer, Boolean>.Create;
  DeptIdsSel := TDictionary<Integer, Boolean>.Create;
  OpValido := TDictionary<Integer, Boolean>.Create;
  ResultIds := TDictionary<Integer, Boolean>.Create;
  List := TList<Integer>.Create;
  try
    // 1) Operarios marcados en el combo (Tag = OperarioId; -1 = '(Todos)').
    for I := 0 to FcxFilterOperarios.Properties.Items.Count - 1 do
      if FcxFilterOperarios.States[I] = cbsChecked then
      begin
        Tag := FcxFilterOperarios.Properties.Items[I].Tag;
        if Tag > 0 then OpIdsSel.AddOrSetValue(Tag, True);
      end;

    // 2) Departamentos marcados (Tag = DepartamentoId).
    for I := 0 to cbDepartamentos.Properties.Items.Count - 1 do
      if cbDepartamentos.States[I] = cbsChecked then
      begin
        Tag := cbDepartamentos.Properties.Items[I].Tag;
        if Tag > 0 then DeptIdsSel.AddOrSetValue(Tag, True);
      end;

    if (OpIdsSel.Count = 0) and (DeptIdsSel.Count = 0) then Exit;

    // 3) Operarios que cuentan como match: marcados directamente, o que
    //    pertenecen a algun departamento marcado.
    AllOps := FOperariosRepo.GetOperarios;
    for I := 0 to High(AllOps) do
    begin
      Matches := OpIdsSel.ContainsKey(AllOps[I].Id);
      if (not Matches) and (DeptIdsSel.Count > 0) then
      begin
        Depts := FOperariosRepo.GetDeptsByOperario(AllOps[I].Id);
        for J := 0 to High(Depts) do
          if DeptIdsSel.ContainsKey(Depts[J].Id) then
          begin
            Matches := True;
            Break;
          end;
      end;
      if Matches then OpValido.AddOrSetValue(AllOps[I].Id, True);
    end;

    if OpValido.Count = 0 then Exit;

    // 4) DataIds de nodos con alguna asignacion a un operario valido.
    Asigs := FOperariosRepo.GetAllAsignacions;
    for I := 0 to High(Asigs) do
      if OpValido.ContainsKey(Asigs[I].OperarioId) then
        ResultIds.AddOrSetValue(Asigs[I].DataId, True);

    for Key in ResultIds.Keys do
      List.Add(Key);
    Result := List.ToArray;
  finally
    OpIdsSel.Free;
    DeptIdsSel.Free;
    OpValido.Free;
    ResultIds.Free;
    List.Free;
  end;
end;

procedure TfrmVistaGantt.AplicarFiltroOperarios;
var
  Ids: TArray<Integer>;
  HideMode: Boolean;
begin
  if FGanttControl = nil then Exit;

  // El filtro por operarios y el filtro por KPI comparten un unico efecto en el
  // control: al actuar el de operarios, anular el de KPI.
  FKPIFilterCategoria := 0;

  // Solo aplica si hay seleccion en combos Y uno de los botones esta pulsado.
  if not (btnHighlightOperarios.Down or btnFilterOperarios.Down) then
  begin
    FGanttControl.ClearOperarioFilter;
    ScheduleSummaryRecalc(True);
    Exit;
  end;

  Ids := ComputeOperarioFilterDataIds;
  if Length(Ids) = 0 then
  begin
    FGanttControl.ClearOperarioFilter;
    ScheduleSummaryRecalc(True);
    Exit;
  end;

  // btnFilter = ocultar no coincidentes; btnHighlight = atenuar no coincidentes.
  HideMode := btnFilterOperarios.Down;
  // Texto del pill del overlay segun el modo y el nº de coincidencias.
  if HideMode then
    FGanttControl.OpFilterLabel := Format('Filtrado: %d', [Length(Ids)])
  else
    FGanttControl.OpFilterLabel := Format('Resaltado: %d', [Length(Ids)]);
  FGanttControl.SetOperarioFilter(Ids, HideMode);
  // El Summary cuenta solo nodos mostrados (en modo ocultar cambia el conteo).
  ScheduleSummaryRecalc(True);
end;

procedure TfrmVistaGantt.btnHighlightOperariosClick(Sender: TObject);
begin
  AplicarFiltroOperarios;
end;

procedure TfrmVistaGantt.btnFilterOperariosClick(Sender: TObject);
begin
  AplicarFiltroOperarios;
end;

procedure TfrmVistaGantt.CargarFiltros;
var
  Ops: TArray<TOperario>;
  Depts: TArray<TDepartamento>;
  I: Integer;
  Lbl: string;
  Item: TcxCheckComboBoxItem;
begin
  if FOperariosRepo = nil then Exit;

  // Por defecto el TcxCheckComboBox usa EditValueFormat = cvfInteger, que
  // codifica la seleccion como mascara de bits -> limite de 64 items. Con muchos
  // operarios eso revienta ("number of items cannot be greater than 64"). Con
  // cvfIndices la seleccion se guarda como lista de indices, sin ese limite.
  FcxFilterOperarios.Properties.EditValueFormat := cvfIndices;
  cbDepartamentos.Properties.EditValueFormat := cvfIndices;

  // --- Operarios ---
  Ops := FOperariosRepo.GetOperarios;
  TArray.Sort<TOperario>(Ops, TComparer<TOperario>.Construct(
    function(const A, B: TOperario): Integer
    begin
      Result := CompareText(A.Nombre, B.Nombre);
    end));

  FcxFilterOperarios.Properties.Items.Clear;
  Item := FcxFilterOperarios.Properties.Items.Add;
  Item.Description := '(Todos)';
  Item.Tag := -1;
  for I := 0 to High(Ops) do
  begin
    Lbl := Trim(Ops[I].Nombre);
    if Lbl = '' then Lbl := '#' + IntToStr(Ops[I].Id);
    Item := FcxFilterOperarios.Properties.Items.Add;
    Item.Description := Lbl;
    Item.Tag := Ops[I].Id;
  end;
  FcxFilterOperarios.Properties.EmptySelectionText := 'Todos los operarios';

  // --- Departamentos ---
  Depts := FOperariosRepo.GetDepartamentos;
  TArray.Sort<TDepartamento>(Depts, TComparer<TDepartamento>.Construct(
    function(const A, B: TDepartamento): Integer
    begin
      Result := CompareText(A.Nombre, B.Nombre);
    end));

  cbDepartamentos.Properties.Items.Clear;
  Item := cbDepartamentos.Properties.Items.Add;
  Item.Description := '(Todos)';
  Item.Tag := -1;
  for I := 0 to High(Depts) do
  begin
    Lbl := Trim(Depts[I].Nombre);
    if Lbl = '' then Lbl := '#' + IntToStr(Depts[I].Id);
    Item := cbDepartamentos.Properties.Items.Add;
    Item.Description := Lbl;
    Item.Tag := Depts[I].Id;
  end;
  cbDepartamentos.Properties.EmptySelectionText := 'Todos los departamentos';
end;

procedure TfrmVistaGantt.Inicializar;
var
  Js, S: string;
  Root: TJSONObject;
  GanttStart, GanttEnd: TDateTime;
  PxPerMin, ScrollX, ScrollY: Double;
  VistaIndex, SummaryViewInt: Integer;
  HideWeekends, OperariosVisible: Boolean;
  HasGanttRange, HasViewport, HasVista: Boolean;
begin
  // Llenar los combos de filtro (operarios / departamentos). Va FUERA del flujo
  // de prefs/viewport y protegido: si fallara, no debe impedir que el Gantt
  // aplique su scroll/zoom.
  try
    CargarFiltros;
  except
    // no critico para la vista
  end;

  FLoadingPrefs := True;
  try
    HasGanttRange := False;
    HasViewport := False;
    HasVista := False;
    SummaryViewInt := -1;
    GanttStart := 0;
    GanttEnd := 0;
    PxPerMin := 0;
    ScrollX := 0;
    ScrollY := 0;
    VistaIndex := 0;
    HideWeekends := False;
    OperariosVisible := False;   // por defecto el panel Operarios esta oculto

    Js := DMPlanner.UserPrefs.Load(SCREEN_KEY_VISTA_GANTT);
    if Js <> '' then
    begin
      Root := TJSONObject.ParseJSONValue(Js) as TJSONObject;
      if Assigned(Root) then
      try
        if Root.TryGetValue<string>('ganttStart', S) then
          TryStrToDate(S, GanttStart, IsoFormatSettings);
        if Root.TryGetValue<string>('ganttEnd', S) then
          TryStrToDate(S, GanttEnd, IsoFormatSettings);
        // Rango valido = fechas reales y separacion sensata (>=1 dia, <= ~10
        // anos). Un rango degenerado (guardado durante un crash) colapsaria el
        // ancho de contenido y haria desaparecer el scrollbar horizontal.
        HasGanttRange := (GanttStart > 0) and (GanttEnd > GanttStart) and
          ((GanttEnd - GanttStart) >= 1) and ((GanttEnd - GanttStart) <= 3700);

        // pxPerMinute: solo se restaura si cae en un rango razonable.
        if Root.TryGetValue<Double>('pxPerMinute', PxPerMin) and
           (PxPerMin > 0) and (PxPerMin <= 100) then
        begin
          if not Root.TryGetValue<Double>('scrollX', ScrollX) then
            ScrollX := 0;
          if not Root.TryGetValue<Double>('scrollY', ScrollY) then
            ScrollY := 0;
          // Descartar valores no finitos / negativos.
          if (ScrollX < 0) or (ScrollX <> ScrollX) then ScrollX := 0;
          if (ScrollY < 0) or (ScrollY <> ScrollY) then ScrollY := 0;
          HasViewport := True;
        end;

        if Root.TryGetValue<Integer>('vistaIndex', VistaIndex) and
           (VistaIndex >= 0) and (VistaIndex < cbVistas.Properties.Items.Count) then
          HasVista := True;

        Root.TryGetValue<Boolean>('hideWeekends', HideWeekends);
        Root.TryGetValue<Boolean>('operariosPanel', OperariosVisible);
        Root.TryGetValue<Integer>('summaryView', SummaryViewInt);
      finally
        Root.Free;
      end;
    end;

    if HasGanttRange then
      Inicializar(GanttStart, GanttEnd)
    else
      Inicializar(Now - 4, Now + 4);

    // Restaurar HideWeekends ANTES de aplicar el viewport: cambiar el flag
    // renormaliza FStartTime/FScrollX en ambos controles, asi que debe quedar
    // fijado antes de que ApplyPendingViewport restaure zoom+scroll. Propagamos
    // a timeline y Gantt igual que btnShowWeekendsClick (FUpdatingViewport evita
    // que el timeline dispare su propio viewport; FLoadingPrefs evita re-guardar).
    if HideWeekends and Assigned(FGanttControl) then
    begin
      FUpdatingViewport := True;
      try
        if Assigned(FTimelineControl) then
          FTimelineControl.HideWeekends := True;
      finally
        FUpdatingViewport := False;
      end;
      FGanttControl.HideWeekends := True;
    end;

    // Inicializar(...) deja IrAFecha(Now) como default. Si tenemos viewport
    // guardado (zoom + scroll), lo aplicamos diferido vía TThread.ForceQueue
    // porque en este punto el form aún no es visible y los controles no tienen
    // ClientWidth definitivo (ClampScrollX recortaría el scroll a 0).
    if HasViewport and Assigned(FGanttControl) then
    begin
      FPendingPxPerMin := PxPerMin;
      FPendingScrollX := Max(0, ScrollX);
      FPendingScrollY := Max(0, ScrollY);
      FHasPendingViewport := True;
      TThread.ForceQueue(nil, ApplyPendingViewport);
    end;

    // Restaurar Vista activa (gvmNormal por defecto = índice 0).
    if HasVista then
    begin
      cbVistas.Properties.OnChange := nil;
      try
        cbVistas.ItemIndex := VistaIndex;
      finally
        cbVistas.Properties.OnChange := cbVistasPropertiesChange;
      end;
      cbVistasPropertiesChange(cbVistas);
    end;

    // Restaurar visibilidad del panel Operarios (eleccion del usuario) y
    // sincronizar el check del item de menu Opciones. AplicarPanelOperarios
    // ajusta tambien la altura del contenedor (si no, el panel no se veria).
    AplicarPanelOperarios(OperariosVisible);
    if Assigned(miVerOperarios) then
      miVerOperarios.Checked := OperariosVisible;

    // Restaurar la vista del Summary (banda KPIs): pulsar el boton toggle
    // correspondiente para que quede marcado y SetSummaryView recalcule.
    if SummaryViewInt > Ord(svNone) then
      RestaurarSummaryView(TSummaryView(SummaryViewInt));
  finally
    // Si hay viewport pendiente, mantener FLoadingPrefs = True hasta que
    // ApplyPendingViewport lo libere. Si no, liberar ahora.
    if not FHasPendingViewport then
      FLoadingPrefs := False;
  end;
end;

procedure TfrmVistaGantt.RestoreViewportPrefs;
begin
  // Mantenido por compatibilidad; la restauración real se hace dentro de
  // Inicializar (sin parámetros) para aplicarse tras la creación del control.
end;

procedure TfrmVistaGantt.ApplyPendingViewport;
begin
  if not FHasPendingViewport then Exit;
  if FGanttControl = nil then Exit;
  FHasPendingViewport := False;

  FUpdatingViewport := True;
  FLoadingPrefs := True;
  try
    // Guardia del bug "sin scrollbar horizontal en maximizado": aqui el form ya
    // es visible y FGanttControl.ClientWidth es el definitivo. Si el zoom
    // guardado (FPendingPxPerMin) es tan alejado que TODO el rango del Gantt cabe
    // en el ancho visible, no habria nada que scrollar y el scrollbar no
    // aparece. Eso pasaba al guardar el viewport con la ventana pequena y luego
    // abrir maximizado. Si el contenido no llena el ancho, subimos px para que el
    // rango ocupe ~1.2x el ancho actual (siempre habra scroll). El zoom-out
    // legitimo sobre rangos largos no se ve afectado (ahi ya llena de sobra).
    var DaysRange: Double := FGanttControl.EndTime - FGanttControl.StartTime;
    if (DaysRange > 0) and (FGanttControl.ClientWidth > 0) then
    begin
      var ContentPx: Double := DaysRange * 24 * 60 * FPendingPxPerMin;
      if ContentPx < FGanttControl.ClientWidth then
        FPendingPxPerMin := (FGanttControl.ClientWidth * 1.2) /
                            (DaysRange * 24 * 60);
    end;

    // Usamos SetViewport (no el setter PxPerMinute) porque SetPxPerMinute
    // tiene un EnsureRange(0.2, 40.0) hard-coded que descartaría valores
    // legítimos (ej. 0.04 px/min cuando el usuario zoomea a mes completo).
    // SetViewport asigna directamente sin ese clamp.
    FGanttControl.SetViewport(FGanttControl.StartTime, FPendingPxPerMin, FPendingScrollX);
    if Assigned(FTimelineControl) then
      FTimelineControl.SetViewport(FTimelineControl.StartTime, FPendingPxPerMin, FPendingScrollX);
    // La banda de resumen comparte coordenadas temporales: hay que aplicarle el
    // MISMO viewport, si no queda desalineada con el timeline hasta el primer
    // scroll/zoom (que ya la sincroniza via TimelineViewportChanged).
    if Assigned(FSummaryControl) then
      FSummaryControl.SetViewport(FSummaryControl.StartTime, FPendingPxPerMin, FPendingScrollX);

    // Scroll vertical: aplicar al Gantt (clampa contra GetMaxScrollY, que ya es
    // valido porque el form es visible y FContentHeight esta calculado) y
    // sincronizar la columna de Centros para que ambos arranquen a la misma altura.
    if FPendingScrollY > 0 then
    begin
      FGanttControl.ApplyScrollYFromCentres(FPendingScrollY);
      if Assigned(FCentrosControl) then
        FCentrosControl.ScrollY := FGanttControl.ScrollY;
    end;
  finally
    FLoadingPrefs := False;
    FUpdatingViewport := False;
  end;
end;

procedure TfrmVistaGantt.SaveViewportPrefs;
var
  Root: TJSONObject;
  GanttIni, GanttFin: TDateTime;
  Px: Double;
begin
  if FLoadingPrefs then Exit;
  if FGanttControl = nil then Exit;

  GanttIni := dtFechaInicioGantt.Date;
  GanttFin := dtFechaFinGantt.Date;

  // No persistir un rango/zoom claramente corrupto: dejaria la vista inservible
  // en la proxima apertura. Si algo no cuadra, no guardamos (se conserva lo
  // anterior valido o, en su defecto, se usaran los defaults al cargar).
  if (GanttIni <= 0) or (GanttFin <= GanttIni) then Exit;
  Px := FGanttControl.PxPerMinute;
  if (Px <> Px) or (Px <= 0) or (Px > 100) then Exit;  // NaN / fuera de rango

  Root := TJSONObject.Create;
  try
    Root.AddPair('version', TJSONNumber.Create(PREFS_VERSION));
    Root.AddPair('ganttStart', FormatDateTime(ISO_DATE, GanttIni));
    Root.AddPair('ganttEnd', FormatDateTime(ISO_DATE, GanttFin));
    Root.AddPair('pxPerMinute', TJSONNumber.Create(Px));
    Root.AddPair('scrollX', TJSONNumber.Create(FGanttControl.ScrollX));
    Root.AddPair('scrollY', TJSONNumber.Create(FGanttControl.ScrollY));
    Root.AddPair('vistaIndex', TJSONNumber.Create(cbVistas.ItemIndex));
    Root.AddPair('hideWeekends', TJSONBool.Create(FGanttControl.HideWeekends));
    // Panel Operarios: visible u oculto (eleccion del usuario en Opciones).
    if Assigned(pnlOperarios) then
      Root.AddPair('operariosPanel', TJSONBool.Create(pnlOperarios.Visible));
    // Vista del Summary (banda KPIs por dia) para restaurarla al reabrir.
    if Assigned(FSummaryControl) then
      Root.AddPair('summaryView', TJSONNumber.Create(Ord(FSummaryControl.View)));
    DMPlanner.UserPrefs.Save(SCREEN_KEY_VISTA_GANTT, Root.ToJSON);
  finally
    Root.Free;
  end;
end;

procedure TfrmVistaGantt.SearchBox1InvokeSearch(Sender: TObject);
var
  nodes: TArray<Integer>;
  iVal: Integer;
begin

  iVal := 20000 + strtointdef( SearchBox1.Text, 0);

  if radiobutton1.checked then
   nodes := FGanttControl.FindNodesByOF( iVal, 'A')
  else
   nodes := FGanttControl.FindNodesByTrabajo('TR-001');


  if Length(nodes) = 0 then
  begin
    FGanttControl.ClearSearch;
    Exit;
  end;

  FGanttControl.SetSearchResults(nodes, True);
  FGanttControl.SelectNodeByIndex(nodes[0], True);
end;

procedure TfrmVistaGantt.Button21Click(Sender: TObject);
begin
    FGanttControl.GoToPrevOF;
end;

procedure TfrmVistaGantt.Button22Click(Sender: TObject);
begin
  FGanttControl.GoToNextOF;
end;

procedure TfrmVistaGantt.Button23Click(Sender: TObject);
var
  idx: Integer;
  iAllOF, iPrioridad: Integer;
begin

  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;

  FGanttControl.BeginUndoBatch('Planificar hacia atras (OT)', hatBackwardOT);
  try
    FGanttControl.BackwardScheduleOT( idx, cxDateEdit1.Date, 0, TRUE  );
  finally
    FGanttControl.EndUndoBatch;
  end;
  UpdateHistoryButtons;
end;

procedure TfrmVistaGantt.Button24Click(Sender: TObject);
var ms1, ms2: Int64; moved1, moved2: Integer;
begin

  Screen.Cursor := crHourGlass;

  FGanttControl.ReplanAllFromDateV2(Now, 0, ms2, moved2);

  Button24.Caption := Format('%d ms', [moved2, ms2]);
end;

procedure TfrmVistaGantt.Button27Click(Sender: TObject);
begin
  pnlToolbar.Visible := not pnlToolbar.Visible;
  Panel3.Visible := not Panel3.Visible;
  if pnlToolbar.Visible then
   Panel1.Height := pnlTitulo.Height + pnlSubTitulo.Height + pnlToolbar.Height + Panel3.Height
  else
   Panel1.Height := pnlTitulo.Height + pnlSubTitulo.Height;
end;
procedure TfrmVistaGantt.Button2Click(Sender: TObject);
var
  idx: Integer;
  iAllOF, iPrioridad: Integer;
begin

  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;

  FGanttControl.BeginUndoBatch('Planificar hacia atras (OF)', hatBackwardOF);
  try
    FGanttControl.BackwardScheduleOF( idx, cxDateEdit1.Date, 0, TRUE  );
  finally
    FGanttControl.EndUndoBatch;
  end;
  UpdateHistoryButtons;
end;

procedure TfrmVistaGantt.Button3Click(Sender: TObject);
begin
   FGanttControl.ClearSearch;
end;

procedure TfrmVistaGantt.Button4Click(Sender: TObject);
begin
  FGanttControl.SearchPrev(True);
end;

procedure TfrmVistaGantt.Button5Click(Sender: TObject);
begin
  FGanttControl.SearchNext(True);
end;

procedure TfrmVistaGantt.Button8Click(Sender: TObject);
var
 iTag: Integer;
begin


   iTag := TButton(Sender).Tag;
   case iTag of
   1: FTimelineControl.SetView(tvHours, 3); // 3 hores visibles
   2: FTimelineControl.SetView(tvDay);
   3: FTimelineControl.SetView(tvWeek);
   4: FTimelineControl.SetView(tvMonth);
   end;
end;

procedure TfrmVistaGantt.Calendario1Click(Sender: TObject);
var
  idx, CentreId, centreIDX: Integer;
  node: TNode;
  dt: TDatetime;
  cal: TCentreCalendar;
  X, Y: Integer;
  bInNonWorking: Boolean;
  sFranjahoraria, sMsg: String;
  AStart, AEnd: TDateTime;
  centre: TCentreTreball;
begin

  X := FGanttControl.FClickPoint.X;
  Y := FGanttControl.FClickPoint.Y;

  dt := FGanttControl.GetDateTimeFromPoint( X, 0);
  //CentreId := FGantt.GetCentreIdFromPoint(X, 0);

  bInNonWorking := FGanttControl.GetNonWorkingIntervalFromPointMerged( FGanttControl.FClickPoint.X,
                                                FGanttControl.FClickPoint.Y,
                                                AStart, AEnd,
                                                CentreId,
                                                40 );

  if bInNonWorking then
   sFranjahoraria := 'NO'
  else
   sFranjahoraria := 'SI';


  centreIDX := FGanttControl.FindCentreIndexById(CentreId);
  centre := FGanttControl.GetCentreByIndex(centreIDX);

  cal := FGanttControl.GetCalendar( CentreId );

  sMsg := 'Fecha hora: ' + DAtetimetostr( dt ) + chr(13) + chr(10) +
          'Centro: (' + inttostr(CentreId) + ') ' + centre.Titulo + chr(13) + chr(10) +
          'Nombre Calendario: ' + cal.Name + chr(13) + chr(10) +
          'Franja horaria: ' + sFranjahoraria + chr(13) + chr(10) +
          'Periodo NoLaborable Inicio:  ' + DAtetimetostr( AStart )+ chr(13) + chr(10) +
          'Periodo NoLaborable Fin:  ' + DAtetimetostr( AEnd );

  ShowMessage( sMsg );
end;

procedure TfrmVistaGantt.CargarCentros;
var
  Centres: TArray<TCentreTreball>;
  CentresLocal: TArray<TCentreTreball>;
  Rows: TArray<TRowLayout>;
  Nodes: TArray<TNode>;
  I: Integer;
  Y: Single;
begin
  if DMPlanner.CentresRepo = nil then Exit;
  Centres := DMPlanner.CentresRepo.GetAll;
  CentresLocal := Centres;

  // Callback que resuelve el nombre a pintar en el panel izquierdo a partir
  // del CentreId del TRowLayout. En modo CENTROS es el titulo del centro;
  // en modo GRUPO el "CentreId" del row en realidad es el indice del grupo
  // y delegamos en TGanttControlGrupo.GetGroupCaption.
  if FGanttControl is TGanttControlGrupo then
  begin
    FCentrosControl.GetCentreName :=
      function(const CentreId: Integer): string
      begin
        // En modo GRUPO el "CentreId" del row es el indice del grupo.
        Result := TGanttControlGrupo(FGanttControl).GetGroupCaption(CentreId);
      end;
    // NO pasar la lista de centros al panel izquierdo en modo GRUPO — asi
    // FindCentreIndexById siempre retorna -1 y PaintRowD2D cae al callback
    // GetCentreName (que ya resuelve la etiqueta del grupo).
    FCentrosControl.SetCentres(nil);
  end
  else
  begin
    FCentrosControl.GetCentreName :=
      function(const CentreId: Integer): string
      var
        J: Integer;
      begin
        Result := '';
        for J := 0 to High(CentresLocal) do
          if CentresLocal[J].Id = CentreId then
            Exit(CentresLocal[J].Titulo);
      end;
    FCentrosControl.SetCentres(Centres);
  end;
  // Cargar nodos reales del proyecto activo desde BD.
  // LoadNodes limpia y rellena el DMPlanner.NodeDataRepo con los NodeData correspondientes.
  DMPlanner.LoadNodes;
  if DMPlanner.NodesRepo <> nil then
    Nodes := DMPlanner.NodesRepo.GetAll
  else
    SetLength(Nodes, 0);

  FGanttControl.SetData(Centres, Nodes, FTimelineControl.StartTime);
  FGanttControl.RebuildOpIdIndex;
  FGanttControl.RebuildNodeLayoutIndex;
  // Copiar reglas de cada calendario al calendario interno del Gantt por centro.
  AplicarCalendariosAGantt;
  // Dependencias entre nodos (flechas)
  CargarDependencias;
  // Marcadores verticales del proyecto
  CargarMarcadores;
  // Fecha de bloqueo del proyecto (si el proyecto la tiene configurada)
  FLoadingFechaBloqueo := True;
  try
    if DMPlanner.CurrentProjectTieneBloqueo then
      FGanttControl.FechaBloqueo := DMPlanner.CurrentProjectFechaBloqueo
    else
      FGanttControl.FechaBloqueo := 0;
  finally
    FLoadingFechaBloqueo := False;
  end;
  // Usar el layout calculado por el Gantt y publicarlo a la columna de centros.
  // Así ambos controles comparten las mismas filas y el scroll/zoom las mantiene.
  FCentrosControl.SetRows(FGanttControl.GetRowsCopy);
  FCentrosControl.Invalidate;
  // Carrega de dades: invalidar el cache d'hores i recalcular el Summary.
  InvalidarSummaryHorasCache;
  RebuildSummaryData;
  // Si la vista activa es operarios, repoblar la cache de rotulos con los
  // datos recien cargados (si no, se poblara al entrar en esa vista).
  if FGanttControl.Vista = gvmOperarios then
    RebuildOperarioLabelCache;
end;
procedure TfrmVistaGantt.CargarDependencias;
var
  Q: TADOQuery;
  Links: TArray<TErpLink>;
  I: Integer;
begin
  if (FGanttControl = nil) or (not DMPlanner.IsConnected) or
     (DMPlanner.CurrentProjectId <= 0) then
  begin
    if FGanttControl <> nil then
      FGanttControl.SetLinks(nil);
    Exit;
  end;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT FromNodeId, ToNodeId, TipoLink, PorcentajeDependencia ' +
      'FROM FS_PL_Dependency ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa AND ProjectId = :ProjectId';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('ProjectId').Value := DMPlanner.CurrentProjectId;
    Q.Open;
    SetLength(Links, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      Links[I].FromNodeId := Q.FieldByName('FromNodeId').AsInteger;
      Links[I].ToNodeId := Q.FieldByName('ToNodeId').AsInteger;
      Links[I].LinkType := TLinkType(Q.FieldByName('TipoLink').AsInteger);
      Links[I].PorcentajeDependencia := Q.FieldByName('PorcentajeDependencia').AsFloat;
      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  FGanttControl.SetLinks(Links);
end;
procedure TfrmVistaGantt.PersistMarcadores;
begin
  // Persistencia atomica de TODOS los marcadores del proyecto activo: el
  // connector hace DELETE+INSERT por ProjectId, asi que tras cualquier cambio
  // (alta/edicion/borrado/movimiento) basta con volcar el estado actual del
  // control. Como el INSERT regenera los IDENTITY, recargamos despues desde BD
  // para que los marcadores en memoria queden con su MarkerId real (necesario
  // para que un segundo doble-clic o arrastre los identifique correctamente).
  if (FGanttControl = nil) or (not DMPlanner.IsConnected) or
     (DMPlanner.CurrentProjectId <= 0) or (DMPlanner.Connector = nil) then
    Exit;

  DMPlanner.Connector.SaveMarkers(
    DMPlanner.CurrentProjectId, FGanttControl.GetMarkers);

  // Recargar para re-sincronizar IDs (CargarMarcadores filtra Visible=1, igual
  // que el alta normal; un marcador con Visible=False no se vuelve a pintar).
  CargarMarcadores;
end;

procedure TfrmVistaGantt.GanttMarkerMoved(Sender: TObject;
  const MarkerId: Integer; const NewDateTime: TDateTime);
begin
  // El control ya actualizo la fecha del marcador en memoria al soltar el drag;
  // solo hay que persistir el nuevo estado completo.
  PersistMarcadores;
end;

procedure TfrmVistaGantt.CargarMarcadores;
var
  Q: TADOQuery;
  M: TGanttMarker;
begin
  if (FGanttControl = nil) or (not DMPlanner.IsConnected) or
     (DMPlanner.CurrentProjectId <= 0) then
  begin
    if FGanttControl <> nil then
      FGanttControl.ClearMarkers;
    Exit;
  end;
  FGanttControl.ClearMarkers;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT MarkerId, FechaHora, ISNULL(Caption, '''') AS Caption, ' +
      '  ISNULL(Color, 0) AS Color, Estilo, GrosorLinea, ' +
      '  Movible, Visible, Tag, ' +
      '  ISNULL(FontName, '''') AS FontName, ISNULL(FontSize, 0) AS FontSize, ' +
      '  ISNULL(FontColor, 0) AS FontColor, FontStyle, ' +
      '  OrientacionTexto, AlineacionTexto ' +
      'FROM FS_PL_Marker ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa AND ProjectId = :ProjectId ' +
      '  AND Visible = 1 ' +
      'ORDER BY FechaHora';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('ProjectId').Value := DMPlanner.CurrentProjectId;
    Q.Open;
    while not Q.Eof do
    begin
      FillChar(M, SizeOf(M), 0);
      M.Id := Q.FieldByName('MarkerId').AsInteger;
      M.DateTime := Q.FieldByName('FechaHora').AsDateTime;
      M.Caption := Q.FieldByName('Caption').AsString;
      M.Color := TColor(Q.FieldByName('Color').AsInteger);
      M.Style := TMarkerStyle(Q.FieldByName('Estilo').AsInteger);
      M.StrokeWidth := Q.FieldByName('GrosorLinea').AsFloat;
      if M.StrokeWidth <= 0 then M.StrokeWidth := 1;
      M.Moveable := Q.FieldByName('Movible').AsBoolean;
      M.Visible := Q.FieldByName('Visible').AsBoolean;
      M.Tag := Q.FieldByName('Tag').AsInteger;
      M.FontName := Q.FieldByName('FontName').AsString;
      M.FontSize := Q.FieldByName('FontSize').AsInteger;
      M.FontColor := TColor(Q.FieldByName('FontColor').AsInteger);
      M.TextOrientation := TMarkerTextOrientation(Q.FieldByName('OrientacionTexto').AsInteger);
      M.TextAlign := TMarkerTextAlign(Q.FieldByName('AlineacionTexto').AsInteger);
      FGanttControl.AddMarker(M);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function CheckComboHasChecked(ACombo: TcxCheckComboBox): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to ACombo.Properties.Items.Count - 1 do
    if ACombo.States[i] = cbsChecked then
    begin
      Result := True;
      Break;
    end;
end;

procedure TfrmVistaGantt.cbDepartamentosPropertiesChange(Sender: TObject);
var
  bEnabled: Boolean;
begin
  bEnabled := CheckComboHasChecked(FcxFilterOperarios) or
              CheckComboHasChecked(cbDepartamentos);

  btnHighlightOperarios.Enabled := bEnabled;
  btnFilterOperarios.Enabled := bEnabled;

  // Si ya no queda nada seleccionado, soltar los botones (no tiene sentido
  // mantenerlos pulsados sin filtro) y limpiar el efecto del Gantt.
  if not bEnabled then
  begin
    btnHighlightOperarios.Down := False;
    btnFilterOperarios.Down := False;
  end;

  // Si hay un boton de efecto pulsado, reaplicar con la nueva seleccion.
  AplicarFiltroOperarios;
end;

procedure TfrmVistaGantt.cbVistasPropertiesChange(Sender: TObject);
var
  idx: Integer;
  vm: TGanttViewMode;
begin

    idx := cbVistas.ItemIndex;
    case idx of
    0: vm := gvmNormal;
    1: vm := gvmOptimitzacio;
    2: vm := gvmFabricacio;
    3: vm := gvmFechaEntrega;
    4: vm := gvmStock;
    5: vm := gvmOperarios;
    6: vm := gvmCarga;
    7: vm := gvmEstado;  //...estado OF (esPendiente, esEnCurso, esFinalizado, esBloqueado);
    8: vm := gvmPrioridad;
    9: vm := gvmRendimiento;
    10: vm := gvmColores;
    11: vm := gvmModificaciones;
    else
      vm := gvmNormal;
    end;

    // La vista de operarios pinta bajo el caption el operario asignado por
    // nodo (lookup en cache). Repoblar la cache al entrar en la vista.
    if vm = gvmOperarios then
      RebuildOperarioLabelCache;

    // Al cambiar de vista, un filtro por KPI activo ya no tiene sentido (las
    // categorias cambian): quitarlo.
    if FKPIFilterCategoria <> 0 then
    begin
      FKPIFilterCategoria := 0;
      FGanttControl.ClearOperarioFilter;
    end;

    FGanttControl.Vista := vm;
    // Los KPIs (titulos/colores/contadores por categoria) dependen de la vista:
    // refrescarlos al cambiarla.
    UpdateKPIs;
    if btnFocus.CanFocus then
      btnFocus.SetFocus;
    SaveViewportPrefs;
end;

procedure TfrmVistaGantt.IrAFecha(const ADate: TDateTime);
var
  SX: Single;
begin
  if (FTimelineControl = nil) or (FGanttControl = nil) then Exit;
  SX := FTimelineControl.CalcScrollXToCenterDate(ADate);
  FTimelineControl.ScrollX := SX;
  FGanttControl.ScrollX := SX;
end;

procedure TfrmVistaGantt.RestaurarVistaPorDefecto;
begin
  if FGanttControl = nil then Exit;

  // 1) Borrar la pref de viewport para que no se vuelva a restaurar el estado
  //    malo en la proxima apertura.
  try
    DMPlanner.UserPrefs.Delete(SCREEN_KEY_VISTA_GANTT);
  except
    // si falla el borrado no es critico; igualmente reseteamos en memoria
  end;

  // 2) Cancelar cualquier viewport pendiente y resetear estado en memoria.
  FHasPendingViewport := False;
  FLoadingPrefs := False;
  FUpdatingViewport := False;

  // 3) Rango por defecto (Now +/- 4 dias) y zoom seguro. Usamos el setter
  //    PxPerMinute (que clampa a 0.2..40) en vez de SetViewport para garantizar
  //    un zoom util: con 2 px/min y ~10 dias hay contenido de sobra y el
  //    scrollbar aparece siempre.
  FLoadingPrefs := True;   // evita que el reset se vuelva a guardar a medias
  try
    Inicializar(Now - 4, Now + 4);
    FGanttControl.PxPerMinute := 2.0;
    if Assigned(FTimelineControl) then
      FTimelineControl.PxPerMinute := 2.0;
    IrAFecha(Now);
    FGanttControl.RebuildLayout;
    FGanttControl.Invalidate;
  finally
    FLoadingPrefs := False;
  end;

  // 4) Guardar ya el estado limpio para dejar la BD coherente.
  SaveViewportPrefs;
end;

procedure TfrmVistaGantt.RestaurarVistaDefecto1Click(Sender: TObject);
begin
  RestaurarVistaPorDefecto;
end;

procedure TfrmVistaGantt.miSelDiaClick(Sender: TObject);
var
  D0, D1: TDateTime;
  n: Integer;
begin
  if FGanttControl = nil then Exit;
  // Dia bajo el clic (FClickDatetime se fija en el MouseDown del control).
  D0 := DateOf(FGanttControl.FClickDatetime);
  D1 := D0 + 1;  // [inicio dia, inicio dia siguiente)
  n := FGanttControl.SelectNodesInDateRange(D0, D1, True);
  if n = 0 then
    ShowMessage('No hay nodos en ese d'#237'a.');
end;

procedure TfrmVistaGantt.miSelSemanaClick(Sender: TObject);
var
  D0, D1: TDateTime;
  dow, n: Integer;
begin
  if FGanttControl = nil then Exit;
  // Inicio de semana (lunes) que contiene el dia del clic.
  D0 := DateOf(FGanttControl.FClickDatetime);
  dow := DayOfTheWeek(D0);   // 1=lunes .. 7=domingo
  D0 := D0 - (dow - 1);      // retroceder al lunes
  D1 := D0 + 7;              // [lunes, lunes siguiente)
  n := FGanttControl.SelectNodesInDateRange(D0, D1, True);
  if n = 0 then
    ShowMessage('No hay nodos en esa semana.');
end;

procedure TfrmVistaGantt.miSelDeseleccionarClick(Sender: TObject);
begin
  if FGanttControl <> nil then
    FGanttControl.ClearSelection;
end;
procedure TfrmVistaGantt.lblModifiedClick(Sender: TObject);
begin
    FGanttControl.MarkAllNodesModified( False );
    FGanttControl.RebuildLayout;
    FGanttControl.Invalidate;
end;

procedure TfrmVistaGantt.lblTituloClick(Sender: TObject);
begin
  // Atajo: clic en el titulo muestra el panel Operarios. Mantener coherente el
  // check del menu Opciones y persistir la eleccion (mismo estado que miVerOperarios).
  AplicarPanelOperarios(True);
  if Assigned(miVerOperarios) then miVerOperarios.Checked := True;
  SaveViewportPrefs;
end;

// Anade el item "Crear nodo manual..." al popup de la zona vacia del Gantt.
// Se construye en codigo para no tocar el DFM grande de la vista. (V066)
procedure TfrmVistaGantt.ConfigurarPopupCrearNodoManual;
var
  mi: TMenuItem;
begin
  if popGantt = nil then Exit;

  mi := TMenuItem.Create(popGantt);
  mi.Caption := 'Crear nodo manual...';
  mi.OnClick := CrearNodoManualClick;
  popGantt.Items.Add(mi);

  // Capturar la posicion del right-click ANTES de mostrar el menu, cuando el
  // cursor todavia esta sobre el Gantt (no sobre el item del menu).
  popGantt.OnPopup := popGanttPopup;
end;

// Se dispara justo antes de mostrar popGantt: el cursor aun esta en el punto del
// right-click. Guardamos su posicion en coords cliente del Gantt para que
// CrearNodoManualClick resuelva el centro y la fecha correctos. (V066)
procedure TfrmVistaGantt.popGanttPopup(Sender: TObject);
begin
  FPopGanttPos := FGanttControl.ScreenToClient(Mouse.CursorPos);
end;

// Ajusta el inicio/fin del nodo manual respetando el calendario laboral del
// centro y las colisiones con los nodos existentes, usando el mismo motor que
// la planificacion del Backlog (RunAutoScheduling, Forward + rellenar huecos).
// Si el motor no logra colocarlo, devuelve las fechas crudas del dialogo. (V066)
procedure TfrmVistaGantt.ColocarNodoManual(const AData: TNodoManualData;
  out AFechaInicio, AFechaFin: TDateTime);
var
  Centros: TArray<TCentreTreball>;
  C: TCentreTreball;
  CodiCentre: string;
  Inp: TSchedInput;
  Params: TSchedParams;
  Res: TSchedResult;
begin
  // Fechas crudas como fallback (inicio del dialogo + duracion de reloj).
  AFechaInicio := AData.FechaInicio;
  AFechaFin := AData.FechaInicio + (AData.DuracionMin / (24 * 60));

  // Resolver el codigo del centro a partir del CenterId elegido.
  CodiCentre := '';
  Centros := DMPlanner.CentresRepo.GetAll;
  for C in Centros do
    if C.Id = AData.CenterId then
    begin
      CodiCentre := C.CodiCentre;
      Break;
    end;

  // Input para el motor: la duracion sale de HorasEstimadas (cascada V054 cae
  // ahi cuando no hay tiempos de operacion ERP). El resto de campos, vacios.
  Inp := Default(TSchedInput);
  Inp.Origen := 'MANUAL';
  Inp.CodigoDocumento := AData.Caption;
  Inp.CentroPreferente := CodiCentre;
  Inp.HorasEstimadas := AData.DuracionMin / 60.0;
  Inp.FechaCompromiso := AData.FechaCompromiso;

  Params := Default(TSchedParams);
  Params.Mode := smForward;
  Params.Order := soPreordenado;        // un solo input, sin reordenar
  Params.FechaBase := AData.FechaInicio; // arrancar en el punto del click
  Params.Placement := ppHueco;          // respetar calendario + primer hueco valido
  Params.HuecoMinimoMin := 1;           // permitir cualquier hueco (nodo manual)
  Params.PorcentajeMinNodo := 100;      // el nodo debe caber entero
  Params.DistanciaMinNodos := 0;

  Res := RunAutoScheduling([Inp], Params);
  if (Length(Res.Items) > 0) and
     (Res.Items[0].Status = ssOK) and
     (Res.Items[0].FechaInicio > 1) and
     (Res.Items[0].FechaFin > Res.Items[0].FechaInicio) then
  begin
    AFechaInicio := Res.Items[0].FechaInicio;
    AFechaFin := Res.Items[0].FechaFin;
  end;
  // Si Status <> ssOK (sin centro/calendario, saturado): nos quedamos con las
  // fechas crudas ya asignadas arriba.
end;

// Abre el dialogo de creacion de nodo manual, persiste el nodo (Source='MAN')
// con su NodeData y recarga el plan. El nodo nace LIBRE (LibreMovimiento=1), por
// lo que el recalculo automatico puede moverlo como a cualquier nodo ERP. (V066)
procedure TfrmVistaGantt.CrearNodoManualClick(Sender: TObject);
var
  Data: TNodoManualData;
  FIni, FFin, FechaClick: TDateTime;
  CentreIdClick: Integer;
  ptClient: TPoint;
begin
  // Posicion del right-click capturada en popGanttPopup (cuando el cursor aun
  // estaba sobre el Gantt). Resolvemos (a) el CenterId de esa fila y (b) la
  // fecha/hora bajo el cursor, para preseleccionar centro e inicio en el dialogo.
  ptClient := FPopGanttPos;
  CentreIdClick := FGanttControl.GetCentreIdFromPoint(ptClient.X, ptClient.Y);
  FechaClick := FGanttControl.GetDateTimeFromPoint(ptClient.X, ptClient.Y);
  if FechaClick < 1 then
    FechaClick := FechaReferenciaSeleccion;  // fallback: centro de la vista

  if not TfrmCrearNodoManual.Execute(DMPlanner.CentresRepo.GetAll,
       FechaClick, CentreIdClick, Data) then
    Exit;

  // Colocar el nodo respetando calendario laboral del centro y colisiones con
  // los nodos existentes (mismo motor que la planificacion del Backlog). Si el
  // motor no puede colocarlo, caemos a las fechas crudas del dialogo. (V066)
  ColocarNodoManual(Data, FIni, FFin);

  // Persistencia compartida con el Kanban de capacidad finita (DMPlanner).
  try
    DMPlanner.CrearNodoManual(Data.Caption, Data.Operacion, Data.CenterId,
      Data.DuracionMin, FIni, FFin, Data.FechaCompromiso,
      Data.RawItemTipoOrigen, Data.RawItemClaveERP);
  except
    on E: Exception do
    begin
      ShowMessage('Error al crear el nodo manual: ' + E.Message);
      Exit;
    end;
  end;

  // Recargar el plan completo para que el nuevo nodo aparezca en el Gantt.
  if Assigned(Form1) then
    Form1.LoadActivePlan;
end;

procedure TfrmVistaGantt.popNodePopup(Sender: TObject);
var
  idx: Integer;
  n: TNode;
  d: TNodeData;
begin
  // Sincronizar los checks del menu con el estado REAL del nodo seleccionado
  // ANTES de mostrarlo. Sin esto, AutoCheck arranca del valor de la vez anterior
  // y el toggle parte de un estado erroneo (por eso "Libre Movimiento" no
  // persistia bien). "Bloqueado" = NOT Enabled (Enabled True = activo, no bloqueado).
  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;
  n := FGanttControl.SelectedNode;

  MenuItem3.Checked := not n.Enabled;   // marcado = bloqueado

  if DMPlanner.NodeDataRepo.TryGetById(n.DataId, D) then
    LibreMovimiento1.Checked := D.LibreMoviment;
end;

// Despacha el submenu "Seleccionar" del clic derecho. El Tag identifica el
// criterio (mismo conjunto que los atajos Ctrl+1/2/3, Ctrl+Mayus+Der/Izq y
// Ctrl+Mayus+O). La referencia temporal es el nodo en foco o el centro de vista.
procedure TfrmVistaGantt.selPeriodoClick(Sender: TObject);
var
  ARef: TDateTime;
begin
  ARef := FechaReferenciaSeleccion;
  case TMenuItem(Sender).Tag of
    1: SeleccionarNodosDelDia(ARef);
    2: SeleccionarNodosDeLaSemana(ARef);
    3: SeleccionarNodosDelMes(ARef);
    4: SeleccionarNodosDesde(ARef);
    5: SeleccionarNodosHasta(ARef);
    6: SeleccionarOFDelNodoSel;
  end;
end;

// Submenu "Mover" del clic derecho. El Tag codifica nivel y direccion:
//   11/12 = OF adelante/atras, 21/22 = OT, 31/32 = OP.
// Abre el dialogo de fecha destino y aplica la replanificacion (con undo).
procedure TfrmVistaGantt.moverAFechaClick(Sender: TObject);
var
  tag, idx: Integer;
  n: TNode;
  D: TNodeData;
  esForward: Boolean;
  nivel: string;
  titulo, subtitulo: string;
  fechaEntrega, fechaDefecto, fechaDestino: TDateTime;
  hatTipo: TGanttHistoryActionType;
  ok: Boolean;
begin
  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;

  tag := TMenuItem(Sender).Tag;
  esForward := (tag mod 10) = 1;   // ...1 = adelante (forward), ...2 = atras

  case tag div 10 of
    1: nivel := 'OF';
    2: nivel := 'OT';
    3: nivel := 'OP';
  else
    Exit;
  end;

  n := FGanttControl.SelectedNode;
  fechaEntrega := 0;
  if DMPlanner.NodeDataRepo.TryGetById(n.DataId, D) then
    fechaEntrega := D.FechaEntrega;

  // Valor por defecto del selector: la entrega si existe; si no, el inicio del
  // propio nodo (para forward) o su fin (para backward).
  if fechaEntrega > 1 then
    fechaDefecto := fechaEntrega
  else if esForward then
    fechaDefecto := n.StartTime
  else
    fechaDefecto := n.EndTime;

  titulo := 'Mover ' + nivel;
  if esForward then
    subtitulo := 'La ' + nivel + ' empezar'#225' en la fecha indicada'
  else
    subtitulo := 'La ' + nivel + ' acabar'#225' en la fecha indicada';

  if not TfrmMoverFecha.Execute(titulo, subtitulo,
       fechaEntrega, fechaDefecto, fechaDestino) then
    Exit;

  // Tipo de accion para el historico.
  case tag div 10 of
    1: if esForward then hatTipo := hatCompactOF else hatTipo := hatBackwardOF;
    2: if esForward then hatTipo := hatCompactOT else hatTipo := hatBackwardOT;
  else
    hatTipo := hatMove;
  end;

  ok := False;
  FGanttControl.BeginUndoBatch('Mover ' + nivel + ' a fecha', hatTipo);
  try
    case tag div 10 of
      1: ok := FGanttControl.MoverOFAFecha(idx, fechaDestino, esForward, 0);
      2: ok := FGanttControl.MoverOTAFecha(idx, fechaDestino, esForward, 0);
      3: ok := FGanttControl.MoverOPAFecha(idx, fechaDestino, esForward);
    end;
  finally
    FGanttControl.EndUndoBatch;
  end;

  UpdateHistoryButtons;

  // El motor marca los nodos movidos como Modified; el autosaver los persiste
  // (mismo patron que Compactar OF/OT). Si nada cambio, avisamos.
  if not ok then
    ShowMessage('No se ha podido mover la ' + nivel +
      ' a esa fecha (restricciones de calendario, dependencias o bloqueo).');
end;

procedure TfrmVistaGantt.LibreMovimiento1Click(Sender: TObject);
var
  idx: Integer;
  n: TNode;
  d: TNodeData;
begin
  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;

  n := FGanttControl.SelectedNode;

  if DMPlanner.NodeDataRepo.TryGetById(n.DataId, D) then
  begin
    // AutoCheck ya togleo LibreMovimiento1.Checked antes de este OnClick.
    D.LibreMoviment := LibreMovimiento1.Checked;
    D.Modified := True;   // marcar dirty para que el AutoSaver lo persista
    DMPlanner.NodeDataRepo.AddOrUpdate(D);
    if Assigned(Form1) then
      Form1.NotifyPlanModified([n.DataId]);
  end;
end;

procedure TfrmVistaGantt.Marcadoresautomaticos1Click(Sender: TObject);
begin
  FGanttControl.AutoMarkersEnabled := Marcadoresautomaticos1.Checked;
  FGanttControl.Invalidate;
end;

procedure TfrmVistaGantt.MenuItem1Click(Sender: TObject);
var
 dt: TDateTime;
begin
  dt := FGanttControl.GetDateTimeFromPoint( FGanttControl.FClickPoint.X, 0);
  FGanttControl.FechaBloqueo := dt;
end;

procedure TfrmVistaGantt.MenuItem3Click(Sender: TObject);
var
  idx: Integer;
  node: TNode;
begin
  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;
  node := FGanttControl.SelectedNode;
  node.Enabled := not node.Enabled;
  FGanttControl.UpdateNode(idx, node);
  FGanttControl.PersistNodeChange(idx);  // persistir el cambio de bloqueo
end;

procedure TfrmVistaGantt.GanttFechaBloqueoChanged(Sender: TObject);
begin
  if FLoadingFechaBloqueo then Exit;
  GuardarFechaBloqueo(FGanttControl.FechaBloqueo);
end;

procedure TfrmVistaGantt.GuardarFechaBloqueo(const ADate: TDateTime);
var
  Cmd: TADOCommand;
  BloqueoSQL: string;
begin
  if DMPlanner.CurrentProjectId <= 0 then Exit;

  if ADate = 0 then
    BloqueoSQL := 'NULL'
  else
    BloqueoSQL := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', ADate) + '''';

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_Project SET FechaBloqueo = ' + BloqueoSQL + ', ' +
      '  FechaModificacion = GETDATE() ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      '  AND ProjectId = ' + IntToStr(DMPlanner.CurrentProjectId);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // Refrescar cache del proyecto activo en DMPlanner (para que CurrentProjectFechaBloqueo
  // y CurrentProjectTieneBloqueo reflejen el cambio sin necesidad de reabrir).
  DMPlanner.SetCurrentProject(DMPlanner.CurrentProjectId);
end;

procedure TfrmVistaGantt.aaa1Click(Sender: TObject);
begin
    case TMenuItem(sender).Tag of
    0:  FGanttControl.LinksVisible := lvSelected;
    1:  FGanttControl.LinksVisible := lvAlways;
    2:  FGanttControl.LinksVisible := lvNever;
    end;
end;

procedure TfrmVistaGantt.Aadirmarcador1Click(Sender: TObject);
var
  dt: TDateTime;
  M: TGanttMarker;
begin
  if not Assigned(FGanttControl) then
    Exit;

  dt := FGanttControl.GetDateTimeFromPoint(FGanttControl.FClickPoint.X, 0);

  M := Default(TGanttMarker);
  M.DateTime := dt;
  M.Caption := FormatDateTime('dd/mm hh:nn', dt);
  M.Color := clRed;
  M.Style := msLine;
  M.StrokeWidth := 1.5;
  M.Moveable := True;
  M.Visible := True;
  M.Tag := 0;
  M.FontName := 'Segoe UI';
  M.FontSize := 8;
  M.FontColor := clRed;
  M.FontStyle := [];
  M.TextOrientation := mtoHorizontal;
  M.TextAlign := mtaTop;

  FGanttControl.AddMarker(M);

  // Persistir de inmediato: el alta debe quedar guardada en BD y reasignarse
  // su MarkerId real (PersistMarcadores recarga tras el INSERT).
  PersistMarcadores;
end;

procedure TfrmVistaGantt.AplicarCalendariosAGantt;
var
  Centres: TArray<TCentreTreball>;
  I, Dia: Integer;
  SrcCal, DstCal: TCentreCalendar;
  RefDate: TDateTime;
  Periods: TArray<TNonWorkingPeriod>;
  ExcDates: TArray<TDateTime>;
  D: TDateTime;
  Exc: TDayException;
begin
  if (DMPlanner.CentresRepo = nil) or (FGanttControl = nil) then Exit;
  Centres := DMPlanner.CentresRepo.GetAll;
  for I := 0 to High(Centres) do
  begin
    SrcCal := DMPlanner.CentresRepo.GetCalendarFor(Centres[I].Id);
    if SrcCal = nil then Continue;
    DstCal := FGanttControl.GetCalendar(Centres[I].Id);
    if DstCal = nil then Continue;
    DstCal.Name := SrcCal.Name;
    // 01/01/2024 fue lunes — cubrimos los 7 días con las reglas semanales.
    // Hay que pedirlas SIN que la excepción intercepte: usamos una fecha
    // de referencia que asumimos sin excepciones en SrcCal.
    RefDate := EncodeDate(2024, 1, 1);
    for Dia := 0 to 6 do
    begin
      Periods := SrcCal.NonWorkingPeriodsForDate(RefDate + Dia);
      // Defensa: si el SrcCal NO te franges no-laborables explicites pero el dia
      // sencer es no laborable (cap minut de treball), forcem un periode complet
      // 00:00-24:00. Aixi un diumenge sense regla explicita no queda 'tot
      // laborable' al DstCal (bug: comptava nodes en diumenge al Summary S4).
      if (Length(Periods) = 0) and
         (SrcCal.WorkingMinutesBetween(RefDate + Dia, RefDate + Dia + 1) = 0) then
      begin
        SetLength(Periods, 1);
        Periods[0].StartTimeOfDay := 0;
        Periods[0].EndTimeOfDay := 1 - (1.0 / SecsPerDay);  // 23:59:59
      end;
      DstCal.SetDayNonWorkingPeriods(
        DayOfTheWeek(RefDate + Dia), Periods);
    end;
    // Propagar excepciones por fecha (festivos, laborables parciales)
    DstCal.ClearExceptions;
    ExcDates := SrcCal.GetExceptionDates;
    for D in ExcDates do
      if SrcCal.TryGetException(D, Exc) then
        DstCal.SetDayException(D, Exc);
  end;
  FGanttControl.Invalidate;
end;
procedure TfrmVistaGantt.btnRedoClick(Sender: TObject);
begin
  FGanttControl.RedoLastAction;
  UpdateHistoryButtons;
end;

procedure TfrmVistaGantt.btnRefreshClick(Sender: TObject);
begin
   FGanttControl.RebuildLayout;
   FGanttControl.Invalidate;
end;

procedure TfrmVistaGantt.btnResaltarOFClick(Sender: TObject);
var
   iTag: Integer;
   bOF, bOT: Boolean;
begin

   iTag := TcxButton(Sender).Tag;

   bOF  := btnResaltarOF.SpeedButtonOptions.Down;
   bOT  := btnResaltarOT.SpeedButtonOptions.Down;

   if bOF or bOT then
    GanttNodeSelected( Self )
   else
   begin
    FGanttControl.ClearSearch;
    FGanttControl.ClearOperarioFilter;   // quitar la atenuacion del resto
   end;

end;

procedure TfrmVistaGantt.btnUndoClick(Sender: TObject);
begin
  // El boton abre el timeline visual del historico (navegar adelante/atras con
  // contador). El undo directo de un paso sigue disponible con Ctrl+Z.
  TfrmGanttHistoryTimeline.Execute(Self, FGanttControl, btnUndo);
  UpdateHistoryButtons;
end;

procedure TfrmVistaGantt.pnlGanttContainerResize(Sender: TObject);
begin
  // TODO (paso siguiente): copiar lógica de Main.pnlGanttContainerResize
end;

procedure TfrmVistaGantt.ShiftRow1Click(Sender: TObject);
begin
  FGanttControl.BeginUndoBatch('Desplazar a la izquierda', hatShiftLeft);
  try
    FGanttControl.ShiftLeftSequentialCentresFromDate( FGanttControl.FClickDatetime, 0);
  finally
    FGanttControl.EndUndoBatch;
  end;
  UpdateHistoryButtons;
end;

procedure TfrmVistaGantt.ShiftRow2Click(Sender: TObject);
begin
  FGanttControl.BeginUndoBatch('Desplazar a la izquierda', hatShiftLeft);
  try
    FGanttControl.ShiftLeftSequentialCentresFromDate( FGanttControl.FClickDatetime, 0);
  finally
    FGanttControl.EndUndoBatch;
  end;
  UpdateHistoryButtons;
end;

procedure TfrmVistaGantt.ShiftRowallimpact1Click(Sender: TObject);
begin
  FGanttControl.BeginUndoBatch('Desplazar a la izquierda (cascada)', hatShiftLeft);
  try
    FGanttControl.ShiftLeftAllImpactedSequentialFromDate( FGanttControl.FClickDatetime, 0);
  finally
    FGanttControl.EndUndoBatch;
  end;
  UpdateHistoryButtons;
end;

procedure TfrmVistaGantt.UpdateHistoryButtons;
begin
  btnUndo.Enabled := FGanttControl.CanUndo;
  btnRedo.Enabled := FGanttControl.CanRedo;
  lblUndoCount.Caption := IntToStr(FGanttControl.UndoCount);
  lblRedoCount.Caption := IntToStr(FGanttControl.RedoCount);
end;


procedure TfrmVistaGantt.TimelineViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
begin
  if FUpdatingViewport then Exit;
  FUpdatingViewport := True;
  try
    if Assigned(FGanttControl) then
      FGanttControl.SetViewport(StartTime, PxPerMinute, ScrollX);
    if Assigned(FSummaryControl) then
      FSummaryControl.SetViewport(StartTime, PxPerMinute, ScrollX);
  finally
    FUpdatingViewport := False;
  end;
  ScheduleSummaryRecalc;  // debounce: calcula quan l'usuari para
  SaveViewportPrefs;
end;
procedure TfrmVistaGantt.TimelineInteraction(Sender: TObject;
  const Interacting: Boolean);
begin
  if Assigned(FGanttControl) then
    FGanttControl.TimelineInteraction(Sender, Interacting);
  // Al soltar el arrastre, programar el recalculo (debounce via timer).
  if not Interacting then
    ScheduleSummaryRecalc;
end;
procedure TfrmVistaGantt.SyncSummaryToolbarWidth;
begin
  if Assigned(pnlSummaryToolbar) and Assigned(pnlCentros) then
    pnlSummaryToolbar.Width := pnlCentros.Width;
end;

procedure TfrmVistaGantt.AplicarNodeLayoutSet;
var
  Repo: TNodeLayoutSetRepo;
  ASet: TNodeLayoutSet;
begin
  if not Assigned(FGanttControl) then Exit;
  if (DMPlanner = nil) or (not DMPlanner.IsConnected) then Exit;

  Repo := TNodeLayoutSetRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    Repo.LoadActive(ASet);
    FGanttControl.SetNodeLayoutSet(ASet);
  finally
    Repo.Free;
  end;
end;

procedure TfrmVistaGantt.SummaryViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
begin
  if FUpdatingViewport then Exit;
  FUpdatingViewport := True;
  try
    if Assigned(FGanttControl) then
      FGanttControl.SetViewport(StartTime, PxPerMinute, ScrollX);
    if Assigned(FTimelineControl) then
      FTimelineControl.SetViewport(StartTime, PxPerMinute, ScrollX);
  finally
    FUpdatingViewport := False;
  end;
  ScheduleSummaryRecalc;  // debounce: calcula quan l'usuari para
  SaveViewportPrefs;
end;

function TfrmVistaGantt.SummaryActivo: Boolean;
begin
  Result := Assigned(pnlSummary) and pnlSummary.Visible;
end;

// Toggle de la banda de Summary. Al ocultarla NO se calcula nada (el debounce
// timer se para y las guardas SummaryActivo cortan cualquier recalculo). Al
// mostrarla se recalcula la ventana visible con la vista que estuviera activa.
procedure TfrmVistaGantt.Versumario1Click(Sender: TObject);
var
  Mostrar: Boolean;
begin
  // AutoCheck ya togleo Versumario1.Checked antes de este OnClick.
  Mostrar := Versumario1.Checked;

  if Assigned(pnlSummary) then
    pnlSummary.Visible := Mostrar;

  if Mostrar then
    // Recalcular solo si hay una vista activa; RebuildSummaryData ya lo hace.
    ScheduleSummaryRecalc(True)
  else if Assigned(FSummaryDebounceTimer) then
    FSummaryDebounceTimer.Enabled := False;  // cancelar calculo pendiente
end;

// Muestra u oculta el panel Operarios. Como pnlOperarios es alTop DENTRO de
// Panel1 (contenedor de altura FIJA), no basta con Visible: hay que ampliar/
// reducir la altura de Panel1 en la altura del panel, o quedaria fuera del area
// visible del contenedor (por eso "no se veia").
procedure TfrmVistaGantt.AplicarPanelOperarios(AVisible: Boolean);
var
  Cont: TWinControl;
  I: Integer;
  C: TControl;
  AlturaFijos: Integer;
begin
  if not Assigned(pnlOperarios) then Exit;
  Cont := pnlOperarios.Parent;   // = Panel1
  if Cont = nil then
  begin
    pnlOperarios.Visible := AVisible;
    Exit;
  end;

  // Altura base = suma de las alturas de TODOS los hijos alTop del contenedor
  // que NO son el panel Operarios (titulo, subtitulo, toolbar...). Se calcula
  // en cada llamada leyendo el estado real, para no depender de un valor inicial
  // fragil ni ocultar por error otros paneles (p.ej. pnlSubTitulo).
  AlturaFijos := 0;
  for I := 0 to Cont.ControlCount - 1 do
  begin
    C := Cont.Controls[I];
    // Solo los hijos alTop VISIBLES y distintos del panel Operarios (algunos,
    // como Panel3, estan ocultos en el DFM y no ocupan altura).
    if (C <> pnlOperarios) and (C.Align = alTop) and C.Visible then
      Inc(AlturaFijos, C.Height);
  end;

  // El contenedor debe medir siempre lo suficiente para los paneles fijos, y
  // sumar el de Operarios solo cuando esta visible. Asi pnlSubTitulo (y el
  // resto) quedan SIEMPRE dentro del area visible.
  pnlOperarios.Visible := AVisible;
  if AVisible then
  begin
    Cont.Height := AlturaFijos + pnlOperarios.Height;
    pnlOperarios.BringToFront;
  end
  else
    Cont.Height := AlturaFijos;
end;

procedure TfrmVistaGantt.miVerOperariosClick(Sender: TObject);
begin
  // AutoCheck ya togleo miVerOperarios.Checked antes de este OnClick.
  AplicarPanelOperarios(miVerOperarios.Checked);
  SaveViewportPrefs;   // persistir la eleccion (save-on-change)
end;

procedure TfrmVistaGantt.RebuildSummaryData;
var
  vStart, vEnd: TDateTime;
begin
  if not Assigned(FSummaryControl) then Exit;
  if not SummaryActivo then Exit;   // banda oculta: no computar

  // El compte de nodes SI es barat: el recreem cada cop sobre la finestra visible.
  // El cache d'HORES (S3) NO es destrueix aqui: es INCREMENTAL (nomes hi afegim
  // els dies nous). Nomes es buida quan canvien dades (InvalidarSummaryHorasCache).
  FreeAndNil(FSummaryNodeCountByDay);
  FreeAndNil(FSummaryS1TotalByDay);
  FreeAndNil(FSummaryS1WithOpsByDay);

  if (FSummaryControl.View = svNone) or (not Assigned(FGanttControl)) then
  begin
    FSummaryControl.Invalidate;
    Exit;
  end;

  // SIEMPRE calculamos solo la VENTANA DE DIAS VISIBLE (nunca todo el plan/anyo),
  // por rendimiento. Y solo la dato de la vista activa (el case salta lo demas).
  vStart := FGanttControl.StartVisibleTime - 1;
  vEnd := FGanttControl.EndVisibleTime + 1;

  case FSummaryControl.View of
    svNodeCount:
      FSummaryNodeCountByDay := FGanttControl.GetVisibleNodeCountByDay(vStart, vEnd);
    svS1:
      begin
        // S1 = operarios asignados por dia (texto central) + badge de cobertura:
        // nodos del dia y cuantos tienen operarios asignados.
        FSummaryNodeCountByDay := FGanttControl.GetOperariosAsignadosByDay(vStart, vEnd);
        FGanttControl.GetNodeOperatorCoverByDay(vStart, vEnd,
          FSummaryS1TotalByDay, FSummaryS1WithOpsByDay);
      end;
    svS3:
      BuildSummaryHorasByDay(vStart, vEnd);  // incremental: solo dias nuevos
  end;

  // Maximo por dia, para normalizar el heatmap (verde claro->oscuro).
  FSummaryMaxValue := 0;
  if Assigned(FSummaryNodeCountByDay) then
    for var V in FSummaryNodeCountByDay.Values do
      if V > FSummaryMaxValue then FSummaryMaxValue := V;

  FSummaryControl.Invalidate;
end;

procedure TfrmVistaGantt.InvalidarSummaryHorasCache;
begin
  // Vaciar el cache incremental de horas: se vuelve a poblar bajo demanda al
  // pintar/mover el viewport. Llamar SOLO al cambiar datos (nodos, calendarios,
  // filtro), NO al hacer zoom/scroll.
  if Assigned(FSummaryOcupMinByDay) then FSummaryOcupMinByDay.Clear;
  if Assigned(FSummaryDispMinByDay) then FSummaryDispMinByDay.Clear;
  if Assigned(FSummaryDiasCalc) then FSummaryDiasCalc.Clear;
  if Assigned(FSummaryDiaFestiu) then FSummaryDiaFestiu.Clear;
end;

procedure TfrmVistaGantt.BuildSummaryHorasByDay(const AFrom, ATo: TDateTime);
var
  Centres: TArray<TCentreTreball>;
  Cal, NodeCal: TCentreCalendar;
  I: Integer;
  Dia, DiaIni, DiaFi, dNodeIni, dNodeFi: TDate;
  N: TNode;
  ns, ne: TDateTime;
  ov, cur: Double;
  mins: Integer;
  hayNuevos: Boolean;

  function EsNou(const ADia: TDate): Boolean;
  begin
    Result := not FSummaryDiasCalc.ContainsKey(ADia);
  end;

begin
  if FGanttControl = nil then Exit;

  // CACHE INCREMENTAL: crear los diccionarios solo la primera vez; despues solo
  // anyadimos los dias que faltan. NUNCA los recreamos al hacer zoom/scroll.
  if FSummaryOcupMinByDay = nil then
    FSummaryOcupMinByDay := TDictionary<TDate, Double>.Create;
  if FSummaryDispMinByDay = nil then
    FSummaryDispMinByDay := TDictionary<TDate, Double>.Create;
  if FSummaryDiasCalc = nil then
    FSummaryDiasCalc := TDictionary<TDate, Boolean>.Create;
  if FSummaryDiaFestiu = nil then
    FSummaryDiaFestiu := TDictionary<TDate, Boolean>.Create;

  DiaIni := DateOf(AFrom);
  DiaFi := DateOf(ATo);

  // ¿Hay algun dia nuevo en la ventana? Si no, salimos sin recorrer nada.
  hayNuevos := False;
  Dia := DiaIni;
  while Dia <= DiaFi do
  begin
    if EsNou(Dia) then begin hayNuevos := True; Break; end;
    Dia := Dia + 1;
  end;
  if not hayNuevos then Exit;

  // 1) Disponibles/dia = suma de minutos laborables de cada centro (calendario).
  //    SOLO para los dias que aun NO estaban calculados.
  //    IMPORTANTE: usamos el MISMO calendario que la ocupacion (el del control,
  //    GetCalendar), no el de CentresRepo: si difieren, un dia no laborable
  //    podria dar capacidad 0 pero ocupacion residual (bug '0h 0h 5%').
  if Assigned(DMPlanner.CentresRepo) then
  begin
    Centres := DMPlanner.CentresRepo.GetAll;
    for I := 0 to High(Centres) do
    begin
      Cal := FGanttControl.GetCalendar(Centres[I].Id);
      if Cal = nil then Continue;
      Dia := DiaIni;
      while Dia <= DiaFi do
      begin
        if EsNou(Dia) then
        begin
          mins := Cal.WorkingMinutesBetween(Dia, Dia + 1);
          if mins > 0 then
          begin
            if FSummaryDispMinByDay.TryGetValue(Dia, cur) then
              FSummaryDispMinByDay[Dia] := cur + mins
            else
              FSummaryDispMinByDay.Add(Dia, mins);
          end;
        end;
        Dia := Dia + 1;
      end;
    end;
  end;

  // Marcar como FESTIVO todo dia nuevo SIN capacidad (0 min laborables en todos
  // los centros). En esos dias no calculamos ocupacion y el Summary los deja en
  // blanco. Esto ademas abarata el bucle de nodos (los salta).
  Dia := DiaIni;
  while Dia <= DiaFi do
  begin
    if EsNou(Dia) and (not FSummaryDispMinByDay.ContainsKey(Dia)) then
      FSummaryDiaFestiu.AddOrSetValue(Dia, True);
    Dia := Dia + 1;
  end;

  // 2) Ocupadas/dia = minutos de cada nodo que solapan con cada dia NUEVO y
  //    LABORABLE (los festivos se saltan: casilla en blanco).
  for I := 0 to FGanttControl.NodeCount - 1 do
  begin
    N := FGanttControl.GetNodeAt(I);
    if N.DataId = 0 then Continue;
    // Respetar el filtro: los nodos ocultos (modo ocultar) NO cuentan horas,
    // igual que en el contador de nodos (S4). Asi al filtrar/desfiltrar las
    // horas ocupadas tambien cambian.
    if FGanttControl.IsNodeHiddenByFilter(N.DataId) then Continue;
    dNodeIni := DateOf(N.StartTime);
    dNodeFi := DateOf(N.EndTime);
    // Descartar nodos que no tocan la ventana.
    if (dNodeFi < DiaIni) or (dNodeIni > DiaFi) then Continue;
    // Calendario del centro del nodo: para imputar SOLO minutos laborables (las
    // horas que caen en tiempo no laborable -fines de semana, festivos, fuera de
    // turno- NO cuentan como ocupacion).
    NodeCal := FGanttControl.GetCalendar(N.CentreId);
    Dia := dNodeIni;
    if Dia < DiaIni then Dia := DiaIni;
    while (Dia <= DiaFi) and (Dia <= dNodeFi) do
    begin
      if EsNou(Dia) and (not FSummaryDiaFestiu.ContainsKey(Dia)) then
      begin
        // Solapamiento del nodo con el dia [Dia, Dia+1).
        ns := N.StartTime; if ns < Dia then ns := Dia;
        ne := N.EndTime;   if ne > (Dia + 1) then ne := Dia + 1;
        if ne > ns then
        begin
          // Solo minutos LABORABLES del solapamiento (descuenta no laborable).
          if NodeCal <> nil then
            ov := NodeCal.WorkingMinutesBetween(ns, ne)
          else
            ov := (ne - ns) * 24 * 60;  // sin calendario: minutos de reloj
          if ov > 0 then
          begin
            if FSummaryOcupMinByDay.TryGetValue(Dia, cur) then
              FSummaryOcupMinByDay[Dia] := cur + ov
            else
              FSummaryOcupMinByDay.Add(Dia, ov);
          end;
        end;
      end;
      Dia := Dia + 1;
    end;
  end;

  // Marcar como calculados TODOS los dias del rango (incluso los que dieron 0,
  // para no reintentarlos). Hacerlo AL FINAL para que EsNou() funcione arriba.
  Dia := DiaIni;
  while Dia <= DiaFi do
  begin
    FSummaryDiasCalc.AddOrSetValue(Dia, True);
    Dia := Dia + 1;
  end;
end;

procedure TfrmVistaGantt.ScheduleSummaryRecalc(const AInvalidate: Boolean);
begin
  // DEBOUNCE: en vez de recalcular ahora (mientras el usuario mueve el viewport
  // o arrastra nodos, lo que penalizaria el Gantt), reprogramamos un timer
  // corto. Cada evento lo reinicia; solo se calcula cuando el usuario PARA.
  if not Assigned(FSummaryControl) then Exit;
  if not SummaryActivo then Exit;   // banda oculta: no programar calculo
  if FSummaryControl.View = svNone then Exit;
  if not Assigned(FSummaryDebounceTimer) then Exit;
  // Si algun disparador pide invalidar (cambio de datos), se queda pendiente
  // hasta el proximo tick (no se pierde aunque luego lleguen disparos de scroll).
  if AInvalidate then FSummaryPendingInvalidate := True;
  FSummaryDebounceTimer.Enabled := False;  // reinicia la cuenta
  FSummaryDebounceTimer.Enabled := True;
end;

procedure TfrmVistaGantt.SummaryDebounceTick(Sender: TObject);
begin
  FSummaryDebounceTimer.Enabled := False;  // one-shot
  if FSummaryPendingInvalidate then
  begin
    FSummaryPendingInvalidate := False;
    InvalidarSummaryHorasCache;  // datos cambiados -> rehacer cache
  end;
  RecalcSummaryActiva;
end;

procedure TfrmVistaGantt.RecalcSummaryActiva;
begin
  if not Assigned(FSummaryControl) then Exit;
  if not SummaryActivo then Exit;             // banda oculta: no recalcular
  if FSummaryControl.View = svNone then Exit; // nada que recalcular
  // RebuildSummaryData ya calcula SOLO la ventana visible y SOLO la vista
  // activa, y para S3 es INCREMENTAL (solo dias nuevos).
  RebuildSummaryData;
end;

procedure TfrmVistaGantt.SummaryDayKPI(Sender: TObject; const ADate: TDateTime;
  out ALine1, ALine2, ALine3: string; out AHighlight: Boolean;
  out AIntensity: Single; out ABadgeCount: Integer;
  out ABadgeColor: TSummaryBadgeColor);
var
  n, total, withOps: Integer;
  dia: TDate;
  ocup, disp, pct: Double;
begin
  ALine1 := '';
  ALine2 := '';
  ALine3 := '';
  AHighlight := False;
  AIntensity := -1;  // por defecto sin heatmap
  ABadgeCount := 0;
  ABadgeColor := sbcNone;

  dia := DateOf(ADate);

  case FSummaryControl.View of
    svNodeCount:
      begin
        n := 0;
        if Assigned(FSummaryNodeCountByDay) then
          FSummaryNodeCountByDay.TryGetValue(dia, n);
        if n > 0 then
        begin
          ALine1 := IntToStr(n);
          ALine2 := 'nodos';
          // Heatmap: intensidad relativa al maximo por dia (verde claro->oscuro).
          if FSummaryMaxValue > 0 then
            AIntensity := n / FSummaryMaxValue
          else
            AIntensity := 0;
        end;
      end;

    svS1:
      begin
        // Operarios asignados por dia (mismo dict que el contador de nodos).
        n := 0;
        if Assigned(FSummaryNodeCountByDay) then
          FSummaryNodeCountByDay.TryGetValue(dia, n);
        if n > 0 then
        begin
          ALine1 := IntToStr(n);
          ALine2 := 'operarios';
          if FSummaryMaxValue > 0 then
            AIntensity := n / FSummaryMaxValue
          else
            AIntensity := 0;
        end;

        // Badge: numero de nodos del dia + color segun cobertura de operarios.
        //   rojo  = ningun nodo con operarios; amarillo = algunos; verde = todos.
        total := 0; withOps := 0;
        if Assigned(FSummaryS1TotalByDay) then
          FSummaryS1TotalByDay.TryGetValue(dia, total);
        if Assigned(FSummaryS1WithOpsByDay) then
          FSummaryS1WithOpsByDay.TryGetValue(dia, withOps);
        if total > 0 then
        begin
          ABadgeCount := total;
          if withOps = 0 then
            ABadgeColor := sbcRed
          else if withOps >= total then
            ABadgeColor := sbcGreen
          else
            ABadgeColor := sbcYellow;
        end;
      end;

    svS3:
      begin
        // Dia festivo (sin capacidad): casilla en blanco, sin heatmap.
        if Assigned(FSummaryDiaFestiu) and FSummaryDiaFestiu.ContainsKey(dia) then
          Exit;

        // Horas ocupadas vs disponibles (capacidad de centros segun calendario).
        disp := 0; ocup := 0;
        if Assigned(FSummaryDispMinByDay) then
          FSummaryDispMinByDay.TryGetValue(dia, disp);
        if Assigned(FSummaryOcupMinByDay) then
          FSummaryOcupMinByDay.TryGetValue(dia, ocup);

        // SIN capacidad real ese dia (no laborable): casilla en blanco. Aunque
        // hubiera ocupacion residual, sin capacidad no tiene sentido mostrarla
        // (evita el caso '0h 0h X%' de dias no laborables).
        if disp < 1 then Exit;

        if ocup <= 0 then
        begin
          // Con capacidad pero sin nodos: horas disponibles + 'libre', TODO sin
          // negrita. Forzamos modo 3-lineas (L1 vacia) para que no salga negrita.
          ALine1 := '';
          ALine2 := Format('%.0f h.', [disp / 60]);
          ALine3 := 'libre';
          AIntensity := -1;  // fondo gris (sin heatmap)
        end
        else
        begin
          // 3 lineas (letra normal): ocupadas / disponibles / % ocupacion.
          ALine1 := Format('%.0f h.', [ocup / 60]);   // ocupadas
          ALine2 := Format('%.0f h.', [disp / 60]);   // disponibles
          pct := ocup / disp;
          ALine3 := Format('%.0f%%', [pct * 100]);
          AIntensity := pct;  // HeatColor ya clampa a 0..1
        end;
      end;
  end;
end;

procedure TfrmVistaGantt.SetSummaryView(const AView: TSummaryView);
begin
  if not Assigned(FSummaryControl) then Exit;
  FSummaryControl.View := AView;
  RebuildSummaryData;  // recalcula el cache i repinta
end;

procedure TfrmVistaGantt.RestaurarSummaryView(const AView: TSummaryView);
begin
  // Marcar el toggle correspondiente (down) y aplicar la vista. Los botones van
  // en grupo (GroupIndex), asi que marcar uno levanta los demas.
  btnS1.Down := AView = svS1;
  btnS2.Down := AView = svS2;
  btnS3.Down := AView = svS3;
  btnS4.Down := AView = svNodeCount;
  SetSummaryView(AView);
end;

procedure TfrmVistaGantt.btnS1Click(Sender: TObject);
begin
  if btnS1.Down then SetSummaryView(svS1) else SetSummaryView(svNone);
end;

procedure TfrmVistaGantt.btnS2Click(Sender: TObject);
begin
  if btnS2.Down then SetSummaryView(svS2) else SetSummaryView(svNone);
end;

procedure TfrmVistaGantt.btnS3Click(Sender: TObject);
begin
  if btnS3.Down then SetSummaryView(svS3) else SetSummaryView(svNone);
end;

procedure TfrmVistaGantt.btnS4Click(Sender: TObject);
begin
  // btnS4 = vista 'Nodos': numero de nodos visibles que tocan cada dia.
  if btnS4.Down then SetSummaryView(svNodeCount) else SetSummaryView(svNone);
end;

procedure TfrmVistaGantt.GanttViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
begin
  if FUpdatingViewport then Exit;
  if not Assigned(FTimelineControl) then Exit;
  FUpdatingViewport := True;
  try
    FTimelineControl.SetViewport(StartTime, PxPerMinute, ScrollX);
    if Assigned(FSummaryControl) then
      FSummaryControl.SetViewport(StartTime, PxPerMinute, ScrollX);
  finally
    FUpdatingViewport := False;
  end;
  // El Summary es calcula NOMES sobre els dies visibles. Per no penalitzar el
  // pan/zoom del Gantt, el recalcul va amb DEBOUNCE (timer): es fa quan l'usuari
  // para de moure's, no a cada frame.
  ScheduleSummaryRecalc;
  // Repaint IMMEDIAT de timeline i summary perque segueixin el pan/zoom del
  // Gantt sense moviment "a blocs".
  FTimelineControl.Update;
  if Assigned(FSummaryControl) then
    FSummaryControl.Update;
  SaveViewportPrefs;
end;
procedure TfrmVistaGantt.GanttScrollYChanged(Sender: TObject;
  const ScrollY: Single);
begin
  if Assigned(FCentrosControl) then
  begin
    FCentrosControl.ScrollY := ScrollY;
    // Repintar Centros YA, no diferido: el Gantt fuerza su WM_PAINT con Update
    // durante el arrastre del thumb; si Centros solo hace Invalidate, se queda un
    // frame por detras y se ve un desfase feo entre ambas columnas.
    FCentrosControl.Update;
  end;
  // Persistir el scroll vertical igual que el horizontal/zoom (GanttViewportChanged):
  // asi el Gantt reabre exactamente a la misma altura. FLoadingPrefs evita
  // re-guardar mientras restauramos el viewport al arrancar.
  SaveViewportPrefs;
end;

procedure TfrmVistaGantt.GanttStatsChanged(Sender: TObject);
begin
  UpdateKPIs;
end;

function TfrmVistaGantt.ClassifyNodeKPI(const N: TNode;
  const D: TNodeData): Integer;
var
  deltaMin: Integer;
  prog, slackDays: Double;
begin
  Result := 0;  // por defecto: no entra en ninguna categoria
  case FGanttControl.Vista of
    gvmOperarios:
      begin
        if D.OperariosNecesarios > 0 then
        begin
          if D.OperariosAsignados <= 0 then Result := 1
          else if D.OperariosAsignados < D.OperariosNecesarios then Result := 2
          else Result := 3;
        end;
      end;

    gvmOptimitzacio:
      begin
        if D.DurationMinOriginal > 0 then
        begin
          deltaMin := Round(N.DurationMin - D.DurationMinOriginal);
          if deltaMin > 0 then Result := 1
          else if deltaMin = 0 then Result := 2
          else Result := 3;
        end
        else
          Result := 2;
      end;

    gvmFabricacio:
      begin
        if D.UnidadesAFabricar > 0 then
        begin
          prog := D.UnidadesFabricadas / D.UnidadesAFabricar;
          if prog < 0.33 then Result := 1
          else if prog < 0.85 then Result := 2
          else Result := 3;
        end
        else
          Result := 1;
      end;

    gvmFechaEntrega:
      begin
        if D.FechaEntrega > 0 then
        begin
          slackDays := (N.EndTime - D.FechaEntrega);
          if slackDays > 0 then Result := 1
          else if (-slackDays) <= 1 then Result := 2
          else Result := 3;
        end;
      end;

    gvmStock:
      begin
        if D.UnidadesAFabricar > 0 then
        begin
          if D.Stock >= D.UnidadesAFabricar then Result := 3
          else if D.Stock >= (0.5 * D.UnidadesAFabricar) then Result := 2
          else Result := 1;
        end;
      end;

    gvmEstado:
      begin
        case D.Estado of
          nePendiente:  Result := 1;
          neEnCurso:    Result := 2;
          neFinalizado: Result := 3;
          // neBloqueado no entra en estas 3 categorias
        end;
      end;
  end;
end;

procedure TfrmVistaGantt.UpdateKPIs;
const
  COL_DEF    = $007D6F62;  // por defecto (gris/marron)
  COL_RED    = $004949D1;  // rojo
  COL_ORANGE = $00559BE1;  // naranja
  COL_GREEN  = $007EC770;  // verde
  COL_BLUE   = $00E4D08B;  // azul (otros)

  // Asigna titulo + color de fondo a un panel KPI (1..3). Title vacio = sin uso.
  procedure SetKPI(APanel: TPanel; ATitle: TLabel; const ACaption: string;
    AColor: TColor);
  begin
    ATitle.Caption := ACaption;
    APanel.Color := AColor;
  end;

var
  I: Integer;
  N: TNode;
  D: TNodeData;
  T0, T1: TDateTime;
  TotalNodes, VisibleNodes: Integer;
  C1, C2, C3: Integer;  // categorias rojo/naranja/verde (o segun vista)
begin
  if FGanttControl = nil then Exit;

  // GetVisibleTimeRange es protected; usamos las propiedades publicas que el
  // control puebla al recalcular contadores (justo antes de OnStatsChanged).
  T0 := FGanttControl.StartVisibleTime;
  T1 := FGanttControl.EndVisibleTime;

  TotalNodes := 0;
  VisibleNodes := 0;
  C1 := 0; C2 := 0; C3 := 0;

  for I := 0 to FGanttControl.NodeCount - 1 do
  begin
    N := FGanttControl.GetNodeAt(I);
    if (N.DataId = 0) or (DMPlanner.NodeDataRepo = nil) or
       (not DMPlanner.NodeDataRepo.TryGetById(N.DataId, D)) then
      Continue;

    Inc(TotalNodes);

    // Solo cuentan para C1/C2/C3 los nodos VISIBLES en el viewport actual.
    if not ((N.StartTime < T1) and (N.EndTime > T0)) then Continue;
    Inc(VisibleNodes);

    // Clasificacion por vista (compartida con el filtro por KPI).
    case ClassifyNodeKPI(N, D) of
      1: Inc(C1);
      2: Inc(C2);
      3: Inc(C3);
    end;
  end;

  // KPI0: siempre visibles / total, color por defecto.
  pnlKPI0.Color := COL_DEF;
  LblKPIValue0.Caption := Format('%d / %d', [VisibleNodes, TotalNodes]);

  // KPI1..3: titulo, color de fondo y valor (categoria / visibles) por vista.
  case FGanttControl.Vista of
    gvmOperarios:
      begin
        SetKPI(pnlKPI1, LblKPITitle1, 'Nodos sin operarios', COL_RED);
        SetKPI(pnlKPI2, LblKPITitle2, 'Nodos con operarios parciales', COL_ORANGE);
        SetKPI(pnlKPI3, LblKPITitle3, 'Nodos con operarios', COL_GREEN);
      end;

    gvmOptimitzacio:
      begin
        SetKPI(pnlKPI1, LblKPITitle1, 'Nodos no optimizados', COL_RED);
        SetKPI(pnlKPI2, LblKPITitle2, 'Nodos sin cambios', COL_BLUE);
        SetKPI(pnlKPI3, LblKPITitle3, 'Nodos optimizados', COL_GREEN);
      end;

    gvmFabricacio:
      begin
        SetKPI(pnlKPI1, LblKPITitle1, 'No fabricado', COL_RED);
        SetKPI(pnlKPI2, LblKPITitle2, 'Parcialmente fabricado', COL_ORANGE);
        SetKPI(pnlKPI3, LblKPITitle3, 'Todo fabricado', COL_GREEN);
      end;

    gvmFechaEntrega:
      begin
        SetKPI(pnlKPI1, LblKPITitle1, 'Fuera de plazo entrega', COL_RED);
        SetKPI(pnlKPI2, LblKPITitle2, 'Pr'#243'ximo a fecha entrega', COL_ORANGE);
        SetKPI(pnlKPI3, LblKPITitle3, 'Dentro plazo entrega', COL_GREEN);
      end;

    gvmStock:
      begin
        SetKPI(pnlKPI1, LblKPITitle1, 'Sin Stock', COL_RED);
        SetKPI(pnlKPI2, LblKPITitle2, 'Stock parcial', COL_ORANGE);
        SetKPI(pnlKPI3, LblKPITitle3, 'Con Stock', COL_GREEN);
      end;

    gvmEstado:
      begin
        SetKPI(pnlKPI1, LblKPITitle1, 'Pendiente', COL_BLUE);
        SetKPI(pnlKPI2, LblKPITitle2, 'En curso', COL_ORANGE);
        SetKPI(pnlKPI3, LblKPITitle3, 'Finalizado', COL_GREEN);
      end;

  else
    // gvmNormal y demas: KPIs 1..3 sin uso (titulo vacio, color por defecto).
    SetKPI(pnlKPI1, LblKPITitle1, '', COL_DEF);
    SetKPI(pnlKPI2, LblKPITitle2, '', COL_DEF);
    SetKPI(pnlKPI3, LblKPITitle3, '', COL_DEF);
  end;

  // Valores categoria / visibles. En las vistas sin uso quedan vacios.
  if FGanttControl.Vista in [gvmOperarios, gvmOptimitzacio, gvmFabricacio,
       gvmFechaEntrega, gvmStock, gvmEstado] then
  begin
    LblKPIValue1.Caption := Format('%d / %d', [C1, VisibleNodes]);
    LblKPIValue2.Caption := Format('%d / %d', [C2, VisibleNodes]);
    LblKPIValue3.Caption := Format('%d / %d', [C3, VisibleNodes]);
  end
  else
  begin
    LblKPIValue1.Caption := '';
    LblKPIValue2.Caption := '';
    LblKPIValue3.Caption := '';
  end;

  // Alertas de planificacion (independiente de la vista activa). Con debounce
  // para no penalizar el Gantt: UpdateKPIs se dispara muy a menudo.
  ScheduleRecalcAlertas;
end;

procedure TfrmVistaGantt.FiltrarPorKPI(ACategoria: Integer);
var
  I: Integer;
  N: TNode;
  D: TNodeData;
  List: TList<Integer>;
  Ids: TArray<Integer>;
  Titulo: string;
begin
  if FGanttControl = nil then Exit;

  // Solo tiene sentido en las vistas con categorias KPI 1/2/3.
  if not (FGanttControl.Vista in [gvmOperarios, gvmOptimitzacio, gvmFabricacio,
       gvmFechaEntrega, gvmStock, gvmEstado]) then Exit;

  // Toggle: si ya estaba filtrando por esta misma categoria, quitar el filtro.
  if FKPIFilterCategoria = ACategoria then
  begin
    FKPIFilterCategoria := 0;
    FGanttControl.ClearOperarioFilter;
    ScheduleSummaryRecalc(True);  // el filtro cambia los nodos contados
    Exit;
  end;

  List := TList<Integer>.Create;
  try
    for I := 0 to FGanttControl.NodeCount - 1 do
    begin
      N := FGanttControl.GetNodeAt(I);
      if (N.DataId = 0) or (DMPlanner.NodeDataRepo = nil) or
         (not DMPlanner.NodeDataRepo.TryGetById(N.DataId, D)) then
        Continue;
      if ClassifyNodeKPI(N, D) = ACategoria then
        List.Add(N.DataId);
    end;
    Ids := List.ToArray;
  finally
    List.Free;
  end;

  if Length(Ids) = 0 then
  begin
    FKPIFilterCategoria := 0;
    FGanttControl.ClearOperarioFilter;
    ScheduleSummaryRecalc(True);
    Exit;
  end;

  // Texto del pill: el titulo de la categoria clicada + el nº de coincidencias.
  case ACategoria of
    1: Titulo := LblKPITitle1.Caption;
    2: Titulo := LblKPITitle2.Caption;
    3: Titulo := LblKPITitle3.Caption;
  end;
  FKPIFilterCategoria := ACategoria;
  FGanttControl.OpFilterLabel := Format('%s: %d', [Titulo, Length(Ids)]);
  // Modo ocultar (hideMode=True): mostrar SOLO los de la categoria.
  FGanttControl.SetOperarioFilter(Ids, True);
  // El Summary debe reflejar el filtro (cuenta solo los nodos mostrados).
  ScheduleSummaryRecalc(True);
end;

procedure TfrmVistaGantt.IconoKPIClick(Sender: TObject);
begin
  if not (Sender is TPaintBox) then Exit;
  case TPaintBox(Sender).Tag of
    0: begin
         // KPI0: quitar cualquier filtro/resaltado y combos.
         FKPIFilterCategoria := 0;
         btnClearOperariosClick(nil);
       end;
    1, 2, 3: FiltrarPorKPI(TPaintBox(Sender).Tag);
  end;
end;

procedure TfrmVistaGantt.ScheduleRecalcAlertas;
begin
  // DEBOUNCE: recorrer todos los nodos + calendario es caro; no lo hacemos en
  // caliente (mientras se mueve/arrastra) sino cuando el usuario para. Cada
  // disparo reinicia la cuenta del timer one-shot.
  if not Assigned(FAlertasDebounceTimer) then Exit;
  FAlertasDebounceTimer.Enabled := False;
  FAlertasDebounceTimer.Enabled := True;
end;

procedure TfrmVistaGantt.AlertasDebounceTick(Sender: TObject);
begin
  FAlertasDebounceTimer.Enabled := False;  // one-shot
  RecalcAlertas;
end;

procedure TfrmVistaGantt.RecalcAlertas;
const
  COL_ALERT_NONE = $00C8C8C8;  // gris: sin alertas
  COL_ALERT_INFO = $00B08020;  // azul/info
  COL_ALERT_AVISO= $0020B0E0;  // amarillo
  COL_ALERT_MEDIA= $002090E8;  // naranja
  COL_ALERT_ALTA = $004949D1;  // rojo
var
  Lookup: TNodeDataLookup;
  Config: TAlertConfigLookup;
  Alertas: TArray<TAlertaItem>;
  A: TAlertaItem;
  total, salud: Integer;
  col: TColor;
begin
  if (FGanttControl = nil) then Exit;

  // El lookup delega en el repo de NodeData (sin acoplar el motor al data module).
  Lookup :=
    function(const ADataId: Integer; out AData: TNodeData): Boolean
    begin
      Result := (DMPlanner.NodeDataRepo <> nil) and
                DMPlanner.NodeDataRepo.TryGetById(ADataId, AData);
    end;

  // Config (activa/peso) desde FS_PL_AlertRule.
  if Assigned(DMPlanner.AlertRulesRepo) then
    Config := DMPlanner.AlertRulesRepo.ConfigLookup()
  else
    Config := nil;

  // Para el KPI solo cuentan las alertas IMPLEMENTADAS con incidencias reales
  // (las pendientes/roadmap y las cumplidas no inflan el contador).
  Alertas := DetectarAlertas(FGanttControl, Lookup, Now, 3, False, Config);
  FAlertas := Alertas;

  total := 0;
  for A in Alertas do
    if A.Implementada and (A.Count > 0) then
      Inc(total, A.Count);

  // Indice de salud del plan (0..100), ponderado por los pesos de las alertas.
  salud := CalcularSalud(Alertas, FGanttControl.NodeCount);

  // El KPI muestra la SALUD como valor principal (semaforo). El detalle (etiqueta
  // + nº de incidencias) va al hint del panel.
  Label8.Caption := 'Salud del plan';
  Label9.Caption := IntToStr(salud);
  if total = 0 then
    pnlKPIAlertas.Hint := Format('Salud %d/100 (%s) - sin incidencias',
      [salud, EtiquetaSalud(salud)])
  else
    pnlKPIAlertas.Hint := Format('Salud %d/100 (%s) - %d incidencias',
      [salud, EtiquetaSalud(salud), total]);
  pnlKPIAlertas.ShowHint := True;

  // Color del panel segun el grado de salud (verde -> rojo).
  if salud >= 90 then col := COL_ALERT_NONE        // gris/ok
  else if salud >= 75 then col := COL_ALERT_AVISO  // amarillo
  else if salud >= 50 then col := COL_ALERT_MEDIA  // naranja
  else col := COL_ALERT_ALTA;                       // rojo

  pnlKPIAlertas.Color := col;
  // Texto blanco salvo cuando el plan esta sano (fondo claro).
  if salud >= 90 then
  begin
    Label8.Font.Color := clBlack;
    Label9.Font.Color := clBlack;
  end
  else
  begin
    Label8.Font.Color := clWhite;
    Label9.Font.Color := clWhite;
  end;

  // Reflejar la salud tambien en el boton de alertas de la toolbar del Main.
  if Assigned(Form1) then
    Form1.ActualizarBotonAlertas(salud, total);
end;

procedure TfrmVistaGantt.pnlKPIAlertasClick(Sender: TObject);
begin
  MostrarAlertas;
end;

procedure TfrmVistaGantt.MostrarAlertas;
var
  Ids: TArray<Integer>;
  Provider: TAlertasProvider;
begin
  if FGanttControl = nil then Exit;

  // Proveedor: el dialogo lo invoca para (re)detectar; el flag "Ver todas"
  // decide si incluye tambien los tipos cumplidos (Count=0).
  Provider :=
    function(const AIncluirCumplidas: Boolean): TArray<TAlertaItem>
    var
      Lookup: TNodeDataLookup;
      Config: TAlertConfigLookup;
    begin
      Lookup :=
        function(const ADataId: Integer; out AData: TNodeData): Boolean
        begin
          Result := (DMPlanner.NodeDataRepo <> nil) and
                    DMPlanner.NodeDataRepo.TryGetById(ADataId, AData);
        end;
      if Assigned(DMPlanner.AlertRulesRepo) then
        Config := DMPlanner.AlertRulesRepo.ConfigLookup()
      else
        Config := nil;
      Result := DetectarAlertas(FGanttControl, Lookup, Now, 3,
        AIncluirCumplidas, Config);
    end;

  if TfrmAlertasViewer.Ejecutar(Self, Provider, Ids,
       procedure
       begin
         // Abre la config CRUD; al guardar, el repo queda actualizado y el
         // dialogo de alertas se refresca solo (RefrescarDesdeProveedor).
         if Assigned(DMPlanner.AlertRulesRepo) then
           TfrmAlertConfig.Ejecutar(Self, DMPlanner.AlertRulesRepo);
       end,
       FGanttControl.NodeCount)
     and (Length(Ids) > 0) then
  begin
    // Filtrar el Gantt: mostrar SOLO los nodos afectados por la alerta elegida.
    FKPIFilterCategoria := 0;  // no es un filtro por categoria KPI
    FGanttControl.OpFilterLabel := Format('Alerta: %d', [Length(Ids)]);
    FGanttControl.SetOperarioFilter(Ids, True);
    ScheduleSummaryRecalc(True);
  end;

  // El KPI puede haber cambiado si se replanifico entre tanto.
  RecalcAlertas;
end;

procedure TfrmVistaGantt.CrearIconoFiltroKPI(APanel: TPanel; ATag: Integer;
  AClearIcon: Boolean);
var
  PB: TPaintBox;
begin
  PB := TPaintBox.Create(APanel);
  PB.Parent := APanel;
  PB.SetBounds(4, APanel.Height - 13, 8, 10);
  PB.Anchors := [akLeft, akBottom];
  PB.Tag := ATag;   // 0 = KPI0 (icono quitar filtro); 1/2/3 = embudo
  if AClearIcon then
    PB.Hint := 'Quitar filtro'
  else
    PB.Hint := 'Filtrar por esta categor'#237'a';
  PB.ShowHint := True;
  PB.Cursor := crHandPoint;
  PB.OnPaint := IconoFiltroPaint;
  PB.OnClick := IconoKPIClick;
end;

procedure TfrmVistaGantt.IconoFiltroPaint(Sender: TObject);
var
  PB: TPaintBox;
  G: TGPGraphics;
  Brush: TGPSolidBrush;
  Pen: TGPPen;
  W, H, cx: Single;
  pts: array[0..5] of TGPPointF;
  IsClear: Boolean;
begin
  PB := Sender as TPaintBox;
  W := PB.Width;
  H := PB.Height;
  cx := W / 2;
  IsClear := (PB.Tag = 0);

  G := TGPGraphics.Create(PB.Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);

    // Embudo: boca ancha arriba, cuello estrecho, tallo. Relleno blanco con
    // borde ligeramente mas opaco. Antialiasing -> aspecto limpio "PRO".
    pts[0] := MakePoint(0.8, 1.5);
    pts[1] := MakePoint(W - 0.8, 1.5);
    pts[2] := MakePoint(cx + 0.7, H * 0.42);  // cuello/tallo mas estrecho
    pts[3] := MakePoint(cx + 0.7, H - 1.0);
    pts[4] := MakePoint(cx - 0.7, H - 1.0);
    pts[5] := MakePoint(cx - 0.7, H * 0.42);

    Brush := TGPSolidBrush.Create(MakeColor(235, 255, 255, 255)); // blanco
    try
      G.FillPolygon(Brush, PGPPointF(@pts[0]), 6);
    finally
      Brush.Free;
    end;

    Pen := TGPPen.Create(MakeColor(255, 255, 255, 255), 1.2);
    try
      G.DrawPolygon(Pen, PGPPointF(@pts[0]), 6);
    finally
      Pen.Free;
    end;

    if IsClear then
    begin
      // "Quitar filtro": X roja en la esquina superior derecha del embudo.
      Pen := TGPPen.Create(MakeColor(255, 224, 48, 48), 1.5);  // rojo ARGB
      try
        G.DrawLine(Pen, W - 5.0, 0.5, W - 0.5, 5.0);
        G.DrawLine(Pen, W - 0.5, 0.5, W - 5.0, 5.0);
      finally
        Pen.Free;
      end;
    end;
  finally
    G.Free;
  end;
end;


procedure TfrmVistaGantt.GanttLayoutChanged(Sender: TObject);
begin
  if Assigned(FCentrosControl) and Assigned(FGanttControl) then
  begin
    FCentrosControl.SetRows(FGanttControl.GetRowsCopy);
    FCentrosControl.Invalidate;
  end;
  // El Gantt ja te layout (mida/dades correctes): refresquem la banda de resum,
  // que pot haver-se pintat abans de tenir la mida final.
  if Assigned(FSummaryControl) then
  begin
    // Resincronitzar el viewport del Summary amb el del Timeline: en obrir el
    // form, el Summary podia haver-se pintat abans que el viewport (zoom/scroll)
    // quedes definitiu, quedant desalineat amb les dates fins al primer scroll.
    if Assigned(FTimelineControl) and (not FUpdatingViewport) then
      FSummaryControl.SetViewport(FTimelineControl.StartTime,
        FTimelineControl.PxPerMinute, FTimelineControl.ScrollX);
    // El layout ha canviat (nodes moguts/replanificats): les dades del Summary
    // poden haver canviat. Recalcul amb DEBOUNCE + invalidacio: durant un drag
    // de node el layout canvia molts cops; recalculem una sola vegada al final.
    ScheduleSummaryRecalc(True);
    FSummaryControl.Invalidate;
  end;
end;

procedure TfrmVistaGantt.GanttNodeSelected(Sender: TObject);
begin
    // Si el botón ResaltarOF está activo, resaltar toda la OF del nodo seleccionado
  if btnResaltarOF.SpeedButtonOptions.Down then
    FGanttControl.HighlightOF(FGanttControl.SelectedNodeIndex);

  if btnResaltarOT.SpeedButtonOptions.Down then
    FGanttControl.HighlightOT(FGanttControl.SelectedNodeIndex);

  // Modo foco: reaplica la cadena de dependencias al nuevo nodo seleccionado.
  if btnFoco.Down then
    AplicarFoco;
end;

procedure TfrmVistaGantt.GanttVoidClick(Sender: TObject);
begin
    // Al hacer clic en el fondo, limpiar el resaltado
  FGanttControl.ClearSearch;
  // Al deseleccionar, mostrar todo de nuevo (los botones de foco/resaltado
  // siguen pulsados: la proxima seleccion volvera a aplicar el efecto).
  if btnFoco.Down or btnResaltarOF.SpeedButtonOptions.Down or
     btnResaltarOT.SpeedButtonOptions.Down then
    FGanttControl.ClearOperarioFilter;
end;
procedure TfrmVistaGantt.Gestionmarcadores1Click(Sender: TObject);
var
  Frm: TfrmGestionMarkers;
begin
  Frm := TfrmGestionMarkers.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;

  // Refrescar el Gantt: el gestor escribe directamente en BD (altas, ediciones,
  // borrados), asi que recargamos los marcadores del control para que reflejen
  // los cambios sin reabrir la vista.
  CargarMarcadores;
  if Assigned(FGanttControl) then
    FGanttControl.Invalidate;
end;

procedure TfrmVistaGantt.GanttNodeDblClick(Sender: TObject;
  const NodeIndex: Integer);
var
  node: TNode;
  ANodeData: TNodeData;
  FechaIni, FechaFin: TDateTime;
begin
  if NodeIndex < 0 then Exit;
  node := FGanttControl.SelectedNode;

  // Si el nodo pertenece a un lote, el doble-clic abre el visor de lote (su
  // contenido) en vez del inspector de un solo nodo. Si el visor hizo cambios
  // (quitar/desplanificar OP, recalcular setup...), recargar el plan.
  if node.LoteId > 0 then
  begin
    if TfrmLoteViewer.Execute(node.LoteId) and Assigned(Form1) then
      Form1.LoadActivePlan;
    Exit;
  end;

  if not DMPlanner.NodeDataRepo.TryGetById(node.DataId, ANodeData) then Exit;

  // Fechas de PLANIFICACION (Gantt): viven en el TNode, no en TNodeData. Se pasan
  // al inspector y, si el usuario las edita, se aplican al Gantt con registro de
  // undo.
  FechaIni := node.StartTime;
  FechaFin := node.EndTime;

  // Nodo manual (Source='MAN'): el inspector lo marca visualmente y habilita
  // TODOS los campos para edicion (no hay ERP detras que proteger). (V066)
  if TfrmNodeInspector.Execute(ANodeData, FechaIni, FechaFin, False,
       FCustomFieldDefs, SameText(node.Source, 'MAN')) then
  begin
    ANodeData.Modified := True;
    DMPlanner.NodeDataRepo.AddOrUpdate(ANodeData);

    // Si las fechas de planificacion han cambiado, mover el nodo en el Gantt
    // (con undo). NodeIndex es la seleccion actual (el doble-clic la fijo).
    if (FechaIni <> node.StartTime) or (FechaFin <> node.EndTime) then
    begin
      FGanttControl.BeginUndoBatch('Editar fechas de nodo', hatEditNode);
      try
        FGanttControl.SetNodeTimesByIndex(NodeIndex, FechaIni, FechaFin);
      finally
        FGanttControl.EndUndoBatch;
      end;
      UpdateHistoryButtons;
    end;

    FGanttControl.Invalidate;
    // Notificar al Main para que el AutoSaver persista el cambio en BD.
    if Assigned(Form1) then
      Form1.NotifyPlanModified([ANodeData.DataId]);
  end;

end;

procedure TfrmVistaGantt.GanttMarkerDblClick(Sender: TObject;
  const MarkerId: Integer);
var
  markers: TArray<TGanttMarker>;
  M: TGanttMarker;
  i: Integer;
  res: TMarkerEditorResult;
begin
  markers := FGanttControl.GetMarkers;
  for i := 0 to High(markers) do
  begin
    if markers[i].Id = MarkerId then
    begin
      M := markers[i];
      res := TfrmMarkerEditor.Execute(M);
      case res of
        merOK:
        begin
          FGanttControl.RemoveMarker(MarkerId);
          FGanttControl.AddMarker(M);
          PersistMarcadores;   // guardar edicion
        end;
        merDelete:
        begin
          FGanttControl.RemoveMarker(MarkerId);
          PersistMarcadores;   // guardar borrado
        end;
      end;
      Exit;
    end;
  end;
end;

procedure TfrmVistaGantt.CentresScrollYChanged(Sender: TObject;
  const ScrollY: Single);
begin
  if Assigned(FGanttControl) then
    FGanttControl.ApplyScrollYFromCentres(ScrollY);
end;

destructor TfrmVistaGantt.Destroy;
begin
  FreeAndNil(FCentreKPIs);
  FreeAndNil(FSummaryNodeCountByDay);
  FreeAndNil(FSummaryS1TotalByDay);
  FreeAndNil(FSummaryS1WithOpsByDay);
  FreeAndNil(FSummaryOcupMinByDay);
  FreeAndNil(FSummaryDispMinByDay);
  FreeAndNil(FSummaryDiasCalc);
  FreeAndNil(FSummaryDiaFestiu);
  FreeAndNil(FOperarioLabelCache);
  inherited;
end;

function TfrmVistaGantt.BuildNodeKPIItemsFromGanttNodes: TArray<TNodeKPIItem>;
var
  I: Integer;
  N: TNode;
  D: TNodeData;
begin
  SetLength(Result, FGanttControl.NodeCount);
  for I := 0 to FGanttControl.NodeCount - 1 do
  begin
    N := FGanttControl.GetNodeAt(I);
    Result[I].CentreId   := N.CentreId;
    Result[I].StartTime  := N.StartTime;
    Result[I].EndTime    := N.EndTime;
    Result[I].DurationMin := N.DurationMin;
    if (DMPlanner.NodeDataRepo <> nil) and DMPlanner.NodeDataRepo.TryGetById(N.DataId, D) then
      Result[I].OperariosAsignados := D.OperariosAsignados
    else
      Result[I].OperariosAsignados := 0;
  end;
end;

function TfrmVistaGantt.CalcCentreKPI_FastPrecomputed(
  const ANodes: TArray<TNodeKPIItem>;
  const ACalendar: TCentreCalendar;
  const AWindowStart, AWindowEnd: TDateTime): TCentreKPI;
var
  I: Integer;
  N: TNodeKPIItem;
  SegStart, SegEnd: TDateTime;
  MinsOcupats, MinsDisponibles, MinsTotals: Double;
  NonWorking: TArray<TAbsInterval>;
begin
  Result.TotalNodes := 0;
  Result.HoresOcupades := 0;
  Result.HoresDisponibles := 0;
  Result.TotalOperaris := 0;
  Result.PercentOcupacio := 0;

  if ACalendar = nil then Exit;
  if AWindowEnd <= AWindowStart then Exit;

  NonWorking := ACalendar.BuildMergedNonWorkingIntervalsForWindow(
    AWindowStart, AWindowEnd);

  MinsTotals := ACalendar.WorkingMinutesBetweenPrecomputed(
    AWindowStart, AWindowEnd, NonWorking);

  MinsOcupats := 0;
  for I := 0 to High(ANodes) do
  begin
    N := ANodes[I];
    if N.EndTime <= AWindowStart then Continue;
    if N.StartTime >= AWindowEnd then Continue;

    SegStart := Max(N.StartTime, AWindowStart);
    SegEnd   := Min(N.EndTime, AWindowEnd);
    if SegEnd <= SegStart then Continue;

    Inc(Result.TotalNodes);
    Inc(Result.TotalOperaris, N.OperariosAsignados);

    MinsOcupats := MinsOcupats +
      ACalendar.WorkingMinutesBetweenPrecomputed(SegStart, SegEnd, NonWorking);
  end;

  MinsDisponibles := MinsTotals - MinsOcupats;
  if MinsDisponibles < 0 then MinsDisponibles := 0;

  Result.HoresOcupades := MinsOcupats / 60.0;
  Result.HoresDisponibles := MinsDisponibles / 60.0;

  if MinsTotals > 0 then
    Result.PercentOcupacio := (MinsOcupats / MinsTotals) * 100.0
  else
    Result.PercentOcupacio := 0;
end;

function TfrmVistaGantt.BuildKPIRanges: TCentresKPIRanges;
var
  I: Integer;
  K: TCentreKPI;
  Centres: TArray<TCentreTreball>;
begin
  Result.Nodes.MinInt := MaxInt;          Result.Nodes.MaxInt := -MaxInt;
  Result.Nodes.MinFloat := 0;             Result.Nodes.MaxFloat := 0;

  Result.Ocupades.MinInt := 0;            Result.Ocupades.MaxInt := 0;
  Result.Ocupades.MinFloat := 1.0E100;    Result.Ocupades.MaxFloat := -1.0E100;

  Result.Disponibles.MinInt := 0;         Result.Disponibles.MaxInt := 0;
  Result.Disponibles.MinFloat := 1.0E100; Result.Disponibles.MaxFloat := -1.0E100;

  Result.Operaris.MinInt := MaxInt;       Result.Operaris.MaxInt := -MaxInt;
  Result.Operaris.MinFloat := 0;          Result.Operaris.MaxFloat := 0;

  Result.PercentOcupacio.MinInt := 0;     Result.PercentOcupacio.MaxInt := 0;
  Result.PercentOcupacio.MinFloat := 1.0E100;
  Result.PercentOcupacio.MaxFloat := -1.0E100;

  if DMPlanner.CentresRepo <> nil then
    Centres := DMPlanner.CentresRepo.GetAll
  else
    SetLength(Centres, 0);

  if Length(Centres) = 0 then
  begin
    Result.Nodes.MinInt := 0; Result.Nodes.MaxInt := 0;
    Result.Ocupades.MinFloat := 0; Result.Ocupades.MaxFloat := 0;
    Result.Disponibles.MinFloat := 0; Result.Disponibles.MaxFloat := 0;
    Result.Operaris.MinInt := 0; Result.Operaris.MaxInt := 0;
    Result.PercentOcupacio.MinFloat := 0; Result.PercentOcupacio.MaxFloat := 0;
    Exit;
  end;

  for I := 0 to High(Centres) do
  begin
    if not FCentreKPIs.TryGetValue(Centres[I].Id, K) then Continue;

    Result.Nodes.MinInt := Min(Result.Nodes.MinInt, K.TotalNodes);
    Result.Nodes.MaxInt := Max(Result.Nodes.MaxInt, K.TotalNodes);

    Result.Ocupades.MinFloat := Min(Result.Ocupades.MinFloat, K.HoresOcupades);
    Result.Ocupades.MaxFloat := Max(Result.Ocupades.MaxFloat, K.HoresOcupades);

    Result.Disponibles.MinFloat := Min(Result.Disponibles.MinFloat, K.HoresDisponibles);
    Result.Disponibles.MaxFloat := Max(Result.Disponibles.MaxFloat, K.HoresDisponibles);

    Result.Operaris.MinInt := Min(Result.Operaris.MinInt, K.TotalOperaris);
    Result.Operaris.MaxInt := Max(Result.Operaris.MaxInt, K.TotalOperaris);

    Result.PercentOcupacio.MinFloat := Min(Result.PercentOcupacio.MinFloat, K.PercentOcupacio);
    Result.PercentOcupacio.MaxFloat := Max(Result.PercentOcupacio.MaxFloat, K.PercentOcupacio);
  end;

  if Result.Nodes.MinInt = MaxInt then
  begin
    Result.Nodes.MinInt := 0; Result.Nodes.MaxInt := 0;
    Result.Ocupades.MinFloat := 0; Result.Ocupades.MaxFloat := 0;
    Result.Disponibles.MinFloat := 0; Result.Disponibles.MaxFloat := 0;
    Result.Operaris.MinInt := 0; Result.Operaris.MaxInt := 0;
    Result.PercentOcupacio.MinFloat := 0; Result.PercentOcupacio.MaxFloat := 0;
  end;
end;

function TfrmVistaGantt.GetCentreKPIValue(const CentreId: Integer): TCentreKPI;
begin
  if not FCentreKPIs.TryGetValue(CentreId, Result) then
  begin
    Result.TotalNodes := 0;
    Result.HoresOcupades := 0;
    Result.HoresDisponibles := 0;
    Result.TotalOperaris := 0;
    Result.PercentOcupacio := 0;
  end;
end;

procedure TfrmVistaGantt.RebuildCentreKPIs_Parallel(const bCalcAll: Boolean);
var
  KPIItems: TArray<TNodeKPIItem>;
  WorkItems: TArray<TCentreKPIWork>;
  Results: TArray<TCentreKPIResult>;
  TmpMap: TObjectDictionary<Integer, TList<TNodeKPIItem>>;
  Lst: TList<TNodeKPIItem>;
  I: Integer;
  CentreId: Integer;
  Item: TNodeKPIItem;
  KPIWindowStart, KPIWindowEnd: TDateTime;
  NowRef: TDateTime;
  Centres: TArray<TCentreTreball>;
begin
  if not Assigned(FGanttControl) then Exit;
  if not FCentrosControl.VerIndicadores then Exit;

  Screen.Cursor := crHourGlass;
  try
    if DMPlanner.CentresRepo <> nil then
      Centres := DMPlanner.CentresRepo.GetAll
    else
      SetLength(Centres, 0);

    KPIItems := BuildNodeKPIItemsFromGanttNodes;

    NowRef := Now;
    if bCalcAll then
    begin
      KPIWindowStart := NowRef;
      KPIWindowEnd   := FGanttControl.EndTime;
    end
    else
    begin
      KPIWindowStart := FGanttControl.StartVisibleTime;
      KPIWindowEnd   := FGanttControl.EndVisibleTime;
    end;

    TmpMap := TObjectDictionary<Integer, TList<TNodeKPIItem>>.Create([doOwnsValues]);
    try
      SetLength(WorkItems, Length(Centres));
      for I := 0 to High(Centres) do
      begin
        CentreId := Centres[I].Id;
        WorkItems[I].CentreId := CentreId;
        WorkItems[I].Calendar := FGanttControl.GetCalendar(CentreId);
        SetLength(WorkItems[I].Items, 0);
        TmpMap.AddOrSetValue(CentreId, TList<TNodeKPIItem>.Create);
      end;

      for I := 0 to High(KPIItems) do
      begin
        Item := KPIItems[I];
        if TmpMap.TryGetValue(Item.CentreId, Lst) then
          Lst.Add(Item);
      end;

      for I := 0 to High(WorkItems) do
        if TmpMap.TryGetValue(WorkItems[I].CentreId, Lst) then
          WorkItems[I].Items := Lst.ToArray;

      SetLength(Results, Length(WorkItems));

      TParallel.For(0, High(WorkItems),
        procedure(Index: Integer)
        begin
          Results[Index].CentreId := WorkItems[Index].CentreId;
          Results[Index].KPI := CalcCentreKPI_FastPrecomputed(
            WorkItems[Index].Items,
            WorkItems[Index].Calendar,
            KPIWindowStart,
            KPIWindowEnd);
        end);

      FCentreKPIs.Clear;
      for I := 0 to High(Results) do
        FCentreKPIs.AddOrSetValue(Results[I].CentreId, Results[I].KPI);
    finally
      TmpMap.Free;
    end;

    FCentreKPIRanges := BuildKPIRanges;
    FCentrosControl.GetCentreKPI := GetCentreKPIValue;
    FCentrosControl.CurrentKPIRanges := FCentreKPIRanges;
    FCentrosControl.Invalidate;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmVistaGantt.ResaltarOF1Click(Sender: TObject);
var
  idx: Integer;
  node: TNode;
begin
  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;
  FGanttControl.HighlightOF(idx);
end;

procedure TfrmVistaGantt.CentrarOF1Click(Sender: TObject);
var
  idx: Integer;
begin
  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;
  // Ajusta zoom + scroll para ver toda la OF del nodo en pantalla.
  FGanttControl.CenterOFOnScreen(idx);
end;

procedure TfrmVistaGantt.Resetduracinoriginal1Click(Sender: TObject);
begin
  FGanttControl.ResetNodeDuration(FGanttControl.SelectedNodeIndex);
end;

{ ========================================================= }
{      Handlers del menu contextual del nodo (popNode)       }
{ ========================================================= }

procedure TfrmVistaGantt.miGestionOperariosClick(Sender: TObject);
var
  Frm: TfrmGestionOperaris;
begin
  Frm := TfrmGestionOperaris.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TfrmVistaGantt.odalaOF1Click(Sender: TObject);
var
  idx: Integer;
  iAllOF, iPrioridad: Integer;
begin

  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;

  iAllOF := TMenuItem(Sender).Tag;
  iPrioridad := TMenuItem(Sender).HelpContext;

  FGanttControl.BeginUndoBatch('Compactar OF', hatCompactOF);
  try
    FGanttControl.CompactOFFromNode( idx, 0, (iAllOF=1) , (iPrioridad=1) );
  finally
    FGanttControl.EndUndoBatch;
  end;
  UpdateHistoryButtons;
end;

procedure TfrmVistaGantt.otalaOT1Click(Sender: TObject);
var
  idx: Integer;
  iAllOT, iPrioridad: Integer;
begin

  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;

  iAllOT := TMenuItem(Sender).Tag;
  iPrioridad := TMenuItem(Sender).HelpContext;

  FGanttControl.BeginUndoBatch('Compactar OT', hatCompactOT);
  try
    FGanttControl.CompactOTFromNode( idx, 0, (iAllOT=1) , (iPrioridad=1) );
  finally
    FGanttControl.EndUndoBatch;
  end;
  UpdateHistoryButtons;
end;

// Compacta (left-shift) los nodos seleccionados dejando fijos los demas: cada
// seleccionado se acerca a la izquierda hasta topar con un nodo NO seleccionado,
// un predecesor logico, el calendario o el bloqueo. Nunca solapa; si un nodo no
// cabe mas a la izquierda, se queda donde estaba. Mismo patron que asignar
// operarios: actua sobre GetSelectedNodeIndexes. Un solo Undo.
procedure TfrmVistaGantt.miCompactarSeleccionClick(Sender: TObject);
var
  SelIndexes: TArray<Integer>;
  Movidos: Integer;
begin
  if FGanttControl = nil then Exit;
  SelIndexes := FGanttControl.GetSelectedNodeIndexes;
  if Length(SelIndexes) = 0 then
  begin
    ShowMessage('Selecciona al menos un nodo en el Gantt para compactar.');
    Exit;
  end;

  FGanttControl.BeginUndoBatch('Compactar seleccion', hatCompactSel);
  try
    Movidos := FGanttControl.CompactSelection(SelIndexes, 0);
  finally
    FGanttControl.EndUndoBatch;
  end;
  UpdateHistoryButtons;

  if Movidos = 0 then
    ShowMessage('Los nodos seleccionados ya estan compactados: ninguno se ha ' +
      'podido acercar mas a la izquierda sin solapar.')
  else
    ShowMessage(Format('%d nodo(s) compactados.', [Movidos]));
end;

// "Mover todo a partir de este punto hasta [fecha]": replanifica en bloque todos
// los nodos que empiezan a partir del punto clicado (FClickDatetime), arrancando en
// la fecha destino que anota el usuario. Los nodos anteriores al punto quedan fijos.
// No preserva las distancias: recalcula cada nodo con el calendario vigente en las
// nuevas fechas (puede haber calendarios distintos ahi), dependencias y colisiones.
procedure TfrmVistaGantt.miMoverTodoDesdeClick(Sender: TObject);
var
  Cutoff, Destino: TDateTime;
  Movidos: Integer;
  ok: Boolean;
begin
  if FGanttControl = nil then Exit;

  // Punto de corte = instante bajo el clic derecho (lo fija el MouseDown del control).
  Cutoff := FGanttControl.FClickDatetime;
  if Cutoff <= 1 then
  begin
    ShowMessage('Haz clic derecho sobre un punto del cronograma para indicar ' +
      'desde donde mover.');
    Exit;
  end;

  // Selector de fecha destino (por defecto, el propio punto de corte).
  if not TfrmMoverFecha.Execute(
       'Mover todo a partir de este punto',
       'Todo lo que empieza a partir de aqu'#237' se replanificar'#225' arrancando en ' +
       'la fecha indicada (recalculando calendarios y dependencias).',
       0, Cutoff, Destino) then
    Exit;

  ok := False;
  FGanttControl.BeginUndoBatch('Mover todo a partir de fecha', hatReplanAll);
  try
    ok := FGanttControl.MoverTodoDesde(Cutoff, Destino, 0, Movidos);
  finally
    FGanttControl.EndUndoBatch;
  end;
  UpdateHistoryButtons;

  if not ok or (Movidos = 0) then
    ShowMessage('No se ha movido ning'#250'n nodo (no hay nodos a partir de ese ' +
      'punto, o las restricciones de calendario/dependencias/bloqueo lo impiden).')
  else
    ShowMessage(Format('%d nodo(s) replanificados desde %s.',
      [Movidos, FormatDateTime('dd/mm/yyyy hh:nn', Destino)]));
end;

procedure TfrmVistaGantt.miAsignarOperariosClick(Sender: TObject);
var
  SelIndexes: TArray<Integer>;
  I: Integer;
  node: TNode;
  D: TNodeData;
  AssignCount: Integer;
  DataIds: TArray<Integer>;
  Operaciones: TArray<string>;
  TotalDur: Double;
  TotalNec: Integer;
begin
  if FGanttControl = nil then Exit;
  SelIndexes := FGanttControl.GetSelectedNodeIndexes;
  if Length(SelIndexes) = 0 then Exit;

  // Modo single
  if Length(SelIndexes) = 1 then
  begin
    node := FGanttControl.GetNodeAt(SelIndexes[0]);
    if not DMPlanner.NodeDataRepo.TryGetById(node.DataId, D) then Exit;

    if TfrmAssignOperaris.Execute(
      FOperariosRepo, D.DataId, D.Operacion,
      D.DurationMin, D.OperariosNecesarios, AssignCount) then
    begin
      D.OperariosAsignados := AssignCount;
      DMPlanner.NodeDataRepo.AddOrUpdate(D);
      RebuildOperarioLabelCache;
      FGanttControl.Invalidate;
    end;
    Exit;
  end;

  // Modo multi
  SetLength(DataIds, 0);
  SetLength(Operaciones, 0);
  TotalDur := 0;
  TotalNec := 0;
  for I := 0 to High(SelIndexes) do
  begin
    if (SelIndexes[I] < 0) or (SelIndexes[I] > FGanttControl.NodeCount - 1) then
      Continue;
    node := FGanttControl.GetNodeAt(SelIndexes[I]);
    if not DMPlanner.NodeDataRepo.TryGetById(node.DataId, D) then Continue;

    SetLength(DataIds, Length(DataIds) + 1);
    DataIds[High(DataIds)] := D.DataId;
    SetLength(Operaciones, Length(Operaciones) + 1);
    Operaciones[High(Operaciones)] := D.Operacion;
    TotalDur := TotalDur + D.DurationMin;
    TotalNec := TotalNec + D.OperariosNecesarios;
  end;

  if Length(DataIds) = 0 then Exit;

  if TfrmAssignOperaris.ExecuteMulti(
    FOperariosRepo, DataIds, Operaciones, TotalDur, TotalNec) then
  begin
    for I := 0 to High(DataIds) do
    begin
      if DMPlanner.NodeDataRepo.TryGetById(DataIds[I], D) then
      begin
        D.OperariosAsignados := FOperariosRepo.CountAssignatsAlNode(DataIds[I]);
        DMPlanner.NodeDataRepo.AddOrUpdate(D);
      end;
    end;
    RebuildOperarioLabelCache;
    FGanttControl.Invalidate;
  end;
end;

procedure TfrmVistaGantt.miEditarLinksClick(Sender: TObject);
var
  idx: Integer;
  node: TNode;
  D: TNodeData;
  AllLinks: TArray<TErpLink>;
  LinkIdxs: TArray<Integer>;
  Items: TArray<TLinkEditItem>;
  I, J: Integer;
  OtherNode: TNode;
  OtherData: TNodeData;
  LResult: TLinkEditorResult;
  OtherIdx: Integer;
begin
  if FGanttControl = nil then Exit;
  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;

  node := FGanttControl.SelectedNode;
  if not DMPlanner.NodeDataRepo.TryGetById(node.DataId, D) then Exit;

  AllLinks := FGanttControl.GetLinks;
  LinkIdxs := FGanttControl.GetLinksForNode(node.Id);

  SetLength(Items, Length(LinkIdxs));
  for I := 0 to High(LinkIdxs) do
  begin
    J := LinkIdxs[I];
    Items[I].LinkIndex := J;
    Items[I].FromNodeId := AllLinks[J].FromNodeId;
    Items[I].ToNodeId := AllLinks[J].ToNodeId;
    Items[I].LinkType := AllLinks[J].LinkType;
    Items[I].PorcentajeDependencia := AllLinks[J].PorcentajeDependencia;
    Items[I].Deleted := False;

    if AllLinks[J].FromNodeId = node.Id then
    begin
      Items[I].FromCaption := D.Operacion;
      OtherIdx := FGanttControl.FindNodeIndexById(AllLinks[J].ToNodeId);
      if (OtherIdx >= 0) then
      begin
        OtherNode := FGanttControl.GetNodeAt(OtherIdx);
        if DMPlanner.NodeDataRepo.TryGetById(OtherNode.DataId, OtherData) then
          Items[I].ToCaption := OtherData.Operacion + ' (OF ' + IntToStr(OtherData.NumeroOrdenFabricacion) + ')'
        else
          Items[I].ToCaption := 'Node ' + IntToStr(AllLinks[J].ToNodeId);
      end
      else
        Items[I].ToCaption := 'Node ' + IntToStr(AllLinks[J].ToNodeId);
    end
    else
    begin
      Items[I].ToCaption := D.Operacion;
      OtherIdx := FGanttControl.FindNodeIndexById(AllLinks[J].FromNodeId);
      if (OtherIdx >= 0) then
      begin
        OtherNode := FGanttControl.GetNodeAt(OtherIdx);
        if DMPlanner.NodeDataRepo.TryGetById(OtherNode.DataId, OtherData) then
          Items[I].FromCaption := OtherData.Operacion + ' (OF ' + IntToStr(OtherData.NumeroOrdenFabricacion) + ')'
        else
          Items[I].FromCaption := 'Node ' + IntToStr(AllLinks[J].FromNodeId);
      end
      else
        Items[I].FromCaption := 'Node ' + IntToStr(AllLinks[J].FromNodeId);
    end;
  end;

  if TfrmLinkEditor.Execute(node.Id,
    D.Operacion + ' (OF ' + IntToStr(D.NumeroOrdenFabricacion) + ')',
    Items, LResult) then
  begin
    var NewLinks: TArray<TErpLink>;
    var EditedSet: TDictionary<Integer, Integer>;
    var DeletedSet: TDictionary<Integer, Boolean>;
    EditedSet := TDictionary<Integer, Integer>.Create;
    DeletedSet := TDictionary<Integer, Boolean>.Create;
    try
      for I := 0 to High(LResult.Items) do
      begin
        J := LResult.Items[I].LinkIndex;
        if J < 0 then Continue;
        if LResult.Items[I].Deleted then
          DeletedSet.AddOrSetValue(J, True)
        else
          EditedSet.AddOrSetValue(J, I);
      end;

      SetLength(NewLinks, 0);
      for I := 0 to High(AllLinks) do
      begin
        if DeletedSet.ContainsKey(I) then Continue;

        var L: TErpLink;
        L := AllLinks[I];
        if EditedSet.ContainsKey(I) then
          L.PorcentajeDependencia := LResult.Items[EditedSet[I]].PorcentajeDependencia;

        SetLength(NewLinks, Length(NewLinks) + 1);
        NewLinks[High(NewLinks)] := L;
      end;

      FGanttControl.SetLinks(NewLinks);

      // Forzar recalculo: por cada link editado, mover el sucesor
      var K: Integer;
      var MovedNodes: TIdxArray;
      for K := 0 to High(NewLinks) do
      begin
        if NewLinks[K].FromNodeId = node.Id then
        begin
          var SuccNodeIdx: Integer;
          SuccNodeIdx := FGanttControl.FindNodeIndexById(NewLinks[K].ToNodeId);
          if SuccNodeIdx >= 0 then
          begin
            var MinStart: TDateTime;
            MinStart := FGanttControl.GetDependencyMinStart(idx, NewLinks[K].PorcentajeDependencia);
            FGanttControl.MoveNodeKeepingDuration(SuccNodeIdx, MinStart);
            FGanttControl.ResolveDependenciesFromNode(SuccNodeIdx, MovedNodes);
          end;
        end;
        if NewLinks[K].ToNodeId = node.Id then
        begin
          var PredNodeIdx: Integer;
          PredNodeIdx := FGanttControl.FindNodeIndexById(NewLinks[K].FromNodeId);
          if PredNodeIdx >= 0 then
          begin
            var MinStart: TDateTime;
            MinStart := FGanttControl.GetDependencyMinStart(PredNodeIdx, NewLinks[K].PorcentajeDependencia);
            FGanttControl.MoveNodeKeepingDuration(idx, MinStart);
            FGanttControl.ResolveDependenciesFromNode(idx, MovedNodes);
          end;
        end;
      end;
      FGanttControl.RebuildLayout;
    finally
      EditedSet.Free;
      DeletedSet.Free;
    end;
  end;
end;

procedure TfrmVistaGantt.btnConfigCentrosClick(Sender: TObject);
var
  Frm: TfrmGestionCentres;
begin
  Frm := TfrmGestionCentres.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  DMPlanner.LoadCentres;

end;

procedure TfrmVistaGantt.btnKPIAllClick(Sender: TObject);
begin
   if FCentrosControl.VerIndicadores then
    RebuildCentreKPIs_Parallel( TRUE );
end;

procedure TfrmVistaGantt.btnKPIVisibleClick(Sender: TObject);
begin
 if FCentrosControl.VerIndicadores then
    RebuildCentreKPIs_Parallel( FALSE );
end;

procedure TfrmVistaGantt.btnAutoPlanSelClick(Sender: TObject);
var
  SelIndexes: TArray<Integer>;
  I: Integer;
  Ids: TArray<Integer>;
  N: TNode;
begin

{
if Assigned(Form1) then
    Form1.LaunchAutoPlanificacion([]);  // [] = todo el plan
  if Assigned(FGanttControl) then
    FGanttControl.Invalidate;

}
  if FGanttControl = nil then Exit;
  SelIndexes := FGanttControl.GetSelectedNodeIndexes;
  if Length(SelIndexes) = 0 then
  begin
    ShowMessage('Selecciona al menos un nodo en el Gantt para planificar.');
    Exit;
  end;
  SetLength(Ids, Length(SelIndexes));
  for I := 0 to High(SelIndexes) do
  begin
    N := FGanttControl.GetNodeAt(SelIndexes[I]);
    Ids[I] := N.DataId;
  end;
  if Assigned(Form1) then
    Form1.LaunchAutoPlanificacion(Ids);
  FGanttControl.Invalidate;

end;

procedure TfrmVistaGantt.miDesplanificarClick(Sender: TObject);
var
  SelIndexes: TArray<Integer>;
  Ids: TArray<Integer>;
  I, NBloqueados, Borrados: Integer;
  N: TNode;
  Bloqueo: TDateTime;
  TieneBloqueo: Boolean;
  L: TList<Integer>;
  Msg: string;
begin
  if FGanttControl = nil then Exit;
  SelIndexes := FGanttControl.GetSelectedNodeIndexes;
  if Length(SelIndexes) = 0 then
  begin
    ShowMessage('Selecciona al menos un nodo en el Gantt para desplanificar.');
    Exit;
  end;

  TieneBloqueo := DMPlanner.CurrentProjectTieneBloqueo;
  Bloqueo := DMPlanner.CurrentProjectFechaBloqueo;

  // Filtrar los nodos bloqueados (anteriores a la fecha de bloqueo): no se
  // pueden desplanificar porque su carga ya esta consolidada.
  NBloqueados := 0;
  L := TList<Integer>.Create;
  try
    for I := 0 to High(SelIndexes) do
    begin
      N := FGanttControl.GetNodeAt(SelIndexes[I]);
      if TieneBloqueo and (N.StartTime < Bloqueo) then
        Inc(NBloqueados)
      else
        L.Add(N.DataId);
    end;
    Ids := L.ToArray;
  finally
    L.Free;
  end;

  if Length(Ids) = 0 then
  begin
    ShowMessage(Format(
      'Los %d nodo(s) seleccionados son anteriores a la fecha de bloqueo (%s) ' +
      'y no se pueden desplanificar.',
      [NBloqueados, FormatDateTime('dd/mm/yyyy', Bloqueo)]));
    Exit;
  end;

  Msg := Format('Se desplanificaran %d nodo(s): se borraran del plan y volveran ' +
    'al Backlog como pendientes.' + sLineBreak, [Length(Ids)]);
  if NBloqueados > 0 then
    Msg := Msg + Format('(%d nodo(s) bloqueados se omitiran.)' + sLineBreak, [NBloqueados]);
  Msg := Msg + sLineBreak + 'Continuar?';
  if MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  try
    Borrados := DMPlanner.DesplanificarNodes(Ids);
  except
    on E: Exception do
    begin
      ShowMessage('Error al desplanificar: ' + E.Message);
      Exit;
    end;
  end;

  // Recargar el plan completo (los nodos borrados desaparecen del Gantt).
  if Assigned(Form1) then
    Form1.LoadActivePlan;

  ShowMessage(Format('%d nodo(s) desplanificados.', [Borrados]));
end;

// Agrupa los nodos seleccionados en un lote (batch). Validacion de mismo centro
// la hace DMPlanner.CrearLote; aqui solo recogemos los NodeId de la seleccion.
procedure TfrmVistaGantt.AgruparEnLote1Click(Sender: TObject);
var
  SelIndexes, Ids: TArray<Integer>;
  I, LoteId: Integer;
  L: TList<Integer>;
begin
  if FGanttControl = nil then Exit;
  SelIndexes := FGanttControl.GetSelectedNodeIndexes;
  if Length(SelIndexes) < 2 then
  begin
    ShowMessage('Selecciona al menos dos nodos del mismo centro para agruparlos '
      + 'en un lote.');
    Exit;
  end;

  L := TList<Integer>.Create;
  try
    for I := 0 to High(SelIndexes) do
      L.Add(FGanttControl.GetNodeAt(SelIndexes[I]).DataId);
    Ids := L.ToArray;
  finally
    L.Free;
  end;

  try
    LoteId := DMPlanner.CrearLote(Ids);
  except
    on E: Exception do
    begin
      ShowMessage('Error al crear el lote: ' + E.Message);
      Exit;
    end;
  end;

  if LoteId <= 0 then
  begin
    ShowMessage('No se pudo crear el lote. Los nodos deben ser del mismo centro '
      + 'y tener fechas asignadas.');
    Exit;
  end;

  if Assigned(Form1) then
    Form1.LoadActivePlan;
end;

// Desagrupa el lote al que pertenece el nodo seleccionado (libera sus miembros
// y borra el lote). Resuelve el LoteId del nodo consultando la BD por DataId.
function TfrmVistaGantt.LoteIdDelNodoSel: Integer;
var
  Idx, NodeId: Integer;
  Q: TADOQuery;
begin
  Result := 0;
  if FGanttControl = nil then Exit;
  Idx := FGanttControl.SelectedNodeIndex;
  if Idx < 0 then Exit;
  NodeId := FGanttControl.GetNodeAt(Idx).DataId;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT LoteId FROM FS_PL_Node WHERE CodigoEmpresa = ' +
      IntToStr(DMPlanner.CodigoEmpresa) + ' AND NodeId = ' + IntToStr(NodeId);
    Q.Open;
    if not Q.Eof and not Q.FieldByName('LoteId').IsNull then
      Result := Q.FieldByName('LoteId').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TfrmVistaGantt.VerLote1Click(Sender: TObject);
var
  LoteId: Integer;
begin
  LoteId := LoteIdDelNodoSel;
  if LoteId <= 0 then
  begin
    ShowMessage('Selecciona un nodo que pertenezca a un lote.');
    Exit;
  end;
  if TfrmLoteViewer.Execute(LoteId) and Assigned(Form1) then
    Form1.LoadActivePlan;
end;

procedure TfrmVistaGantt.DesagruparLote1Click(Sender: TObject);
var
  LoteId: Integer;
begin
  LoteId := LoteIdDelNodoSel;
  if LoteId <= 0 then
  begin
    ShowMessage('Selecciona un nodo que pertenezca a un lote.');
    Exit;
  end;

  try
    DMPlanner.DesagruparLote(LoteId);
  except
    on E: Exception do
    begin
      ShowMessage('Error al desagrupar el lote: ' + E.Message);
      Exit;
    end;
  end;

  if Assigned(Form1) then
    Form1.LoadActivePlan;
end;

end.
