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
  uGanttHelpers, uCentreCalendar,
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
  uGanttControl, uGanttControlGrupo, uGanttTimeline, uGanttSummary, uGanttCentres, uGanttTypes, uErpTypes,
  System.Generics.Collections, System.Generics.Defaults,
  System.Threading, System.Math, uHelpGuide,
  uOperariosTypes, System.Variants, uColorPalette64LayeredPopup,
  dxGDIPlusClasses, cxImage, System.ImageList, Vcl.ImgList, cxImageList,
  Vcl.Buttons;
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
    btnAutoPlanSel: TButton;
    btnAutoPlanAll: TButton;
    btnDesasignarSel: TButton;
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
    ComboBox1: TComboBox;
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
    ShiftRow2: TMenuItem;
    N1: TMenuItem;
    Color1: TMenuItem;
    Colordelnode1: TMenuItem;
    ColordelaOrdendetrabajo1: TMenuItem;
    ColordelaOrdendeFabricacin1: TMenuItem;
    ColordelPedido1: TMenuItem;
    ColordelProyecto1: TMenuItem;
    ResaltarOF1: TMenuItem;
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
    Panel12: TPanel;
    Label30: TLabel;
    Label31: TLabel;
    Panel4: TPanel;
    Label9: TLabel;
    Label10: TLabel;
    Panel15: TPanel;
    Label36: TLabel;
    Label37: TLabel;
    Panel14: TPanel;
    Label34: TLabel;
    lblVisible: TLabel;
    Panel13: TPanel;
    Label32: TLabel;
    lblNodes: TLabel;
    pnlOperarios: TPanel;
    Label23: TLabel;
    Shape3: TShape;
    Label19: TLabel;
    cxButton2: TcxButton;
    cxButton3: TcxButton;
    FcxFilterOperarios: TcxCheckComboBox;
    cbDepartamentos: TcxCheckComboBox;
    cxButton4: TcxButton;
    pnlSummary: TPanel;
    pnlSummaryToolbar: TPanel;
    Shape4: TShape;
    Shape5: TShape;
    Label22: TLabel;
    btnS3: TcxButton;
    btnS4: TcxButton;
    btnS1: TcxButton;
    btnS2: TcxButton;
    procedure pnlGanttContainerResize(Sender: TObject);
    procedure TimelineViewportChanged(Sender: TObject;
      const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
    procedure TimelineInteraction(Sender: TObject; const Interacting: Boolean);
    procedure SummaryViewportChanged(Sender: TObject;
      const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
    // Resum/KPIs per dia
    procedure SummaryDayKPI(Sender: TObject; const ADate: TDateTime;
      out ALine1, ALine2: string; out AHighlight: Boolean);
    procedure RebuildSummaryData;
    procedure SetSummaryView(const AView: TSummaryView);
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
    procedure btnAutoPlanSelClick(Sender: TObject);
    procedure btnAutoPlanAllClick(Sender: TObject);
    procedure btnDesasignarSelClick(Sender: TObject);
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
    procedure ComboBox1Change(Sender: TObject);
    procedure SearchBox1InvokeSearch(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure LibreMovimiento1Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure popNodePopup(Sender: TObject);
    procedure Resetduracinoriginal1Click(Sender: TObject);
    procedure ShiftRow2Click(Sender: TObject);
    procedure Colordelnode1Click(Sender: TObject);
    procedure odalaOF1Click(Sender: TObject);
    procedure otalaOT1Click(Sender: TObject);
    procedure ResaltarOF1Click(Sender: TObject);
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
    procedure Inicializar(const AFechaInicio, AFechaFin: TDateTime); overload;
    procedure Inicializar; overload;
    procedure SaveViewportPrefs;
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
  uAssignOperaris, uGestionOperaris, uLinkEditor,  Main;



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

procedure TfrmVistaGantt.ComboBox1Change(Sender: TObject);
begin
    case ComboBox1.itemindex of
    0:  FGanttControl.LinksVisible := lvAlways;
    1:  FGanttControl.LinksVisible := lvSelected;
    2:  FGanttControl.LinksVisible := lvNever;
    end;
end;

constructor TfrmVistaGantt.CreateVista(AOwner: TComponent;
  AOperariosRepo: TOperariosRepo;
  AMoldeRepo: TMoldeRepo;
  ACustomFieldDefs: TCustomFieldDefs;
  APlanningRuleEngine: TPlanningRuleEngine);
begin
  inherited Create(AOwner);
  FCentreKPIs := TDictionary<Integer, TCentreKPI>.Create;
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

  FCentrosControl.OnScrollYChanged := CentresScrollYChanged;
  // Centros clampa su scroll al MISMO maximo que el Gantt (evita desalineacion
  // al llegar al final por diferencia de ClientHeight entre ambos controles).
  FCentrosControl.GetMaxScrollYFunc :=
    function: Single
    begin
      Result := FGanttControl.GetMaxScrollY;
    end;

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

  if Key = VK_F1 then
  begin
    TfrmHelpGuide.Execute;
    Key := 0;
  end
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
  end;
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
  VistaIndex: Integer;
  HideWeekends: Boolean;
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
    GanttStart := 0;
    GanttEnd := 0;
    PxPerMin := 0;
    ScrollX := 0;
    ScrollY := 0;
    VistaIndex := 0;
    HideWeekends := False;

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

  FGanttControl.BackwardScheduleOT( idx, cxDateEdit1.Date, 0, TRUE  );

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

  FGanttControl.BackwardScheduleOF( idx, cxDateEdit1.Date, 0, TRUE  );

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
  // Recalcular la banda de resum amb les noves dades (si hi ha vista activa).
  RebuildSummaryData;
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

    FGanttControl.Vista := vm;
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
procedure TfrmVistaGantt.lblModifiedClick(Sender: TObject);
begin
    FGanttControl.MarkAllNodesModified( False );
    FGanttControl.RebuildLayout;
    FGanttControl.Invalidate;
end;

procedure TfrmVistaGantt.lblTituloClick(Sender: TObject);
begin
  pnlOperarios.Visible := true;
  pnlOperarios.BringTofront;

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
    FGanttControl.ClearSearch;

end;

procedure TfrmVistaGantt.btnUndoClick(Sender: TObject);
begin
  FGanttControl.UndoLastAction;
  UpdateHistoryButtons;
end;

procedure TfrmVistaGantt.pnlGanttContainerResize(Sender: TObject);
begin
  // TODO (paso siguiente): copiar lógica de Main.pnlGanttContainerResize
end;
procedure TfrmVistaGantt.ShiftRow1Click(Sender: TObject);
begin
  FGanttControl.ShiftLeftSequentialCentresFromDate( FGanttControl.FClickDatetime, 0);
end;

procedure TfrmVistaGantt.ShiftRow2Click(Sender: TObject);
begin
  FGanttControl.ShiftLeftSequentialCentresFromDate( FGanttControl.FClickDatetime, 0);
end;

procedure TfrmVistaGantt.ShiftRowallimpact1Click(Sender: TObject);
begin
  FGanttControl.ShiftLeftAllImpactedSequentialFromDate( FGanttControl.FClickDatetime, 0);
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
  SaveViewportPrefs;
end;
procedure TfrmVistaGantt.TimelineInteraction(Sender: TObject;
  const Interacting: Boolean);
begin
  if Assigned(FGanttControl) then
    FGanttControl.TimelineInteraction(Sender, Interacting);
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
  SaveViewportPrefs;
end;

procedure TfrmVistaGantt.RebuildSummaryData;
var
  vStart, vEnd: TDateTime;
begin
  if not Assigned(FSummaryControl) then Exit;

  FreeAndNil(FSummaryNodeCountByDay);

  if (FSummaryControl.View = svNone) or (not Assigned(FGanttControl)) then
  begin
    FSummaryControl.Invalidate;
    Exit;
  end;

  // Calculem sobre TOT el rang del pla (no nomes el visible): el compte per dia
  // no depen de l'scroll horitzontal, aixi el pan/zoom NO necessita recalcular
  // (lookup O(1) per dia). Marge ampli per cobrir nodes fora del rang nominal.
  vStart := FGanttControl.StartTime - 2;
  vEnd := FGanttControl.EndTime + 2;

  case FSummaryControl.View of
    svNodeCount:
      FSummaryNodeCountByDay := FGanttControl.GetVisibleNodeCountByDay(vStart, vEnd);
  end;

  FSummaryControl.Invalidate;
end;

procedure TfrmVistaGantt.SummaryDayKPI(Sender: TObject; const ADate: TDateTime;
  out ALine1, ALine2: string; out AHighlight: Boolean);
var
  n: Integer;
begin
  ALine1 := '';
  ALine2 := '';
  AHighlight := False;

  case FSummaryControl.View of
    svNodeCount:
      begin
        n := 0;
        if Assigned(FSummaryNodeCountByDay) then
          FSummaryNodeCountByDay.TryGetValue(DateOf(ADate), n);
        if n > 0 then
        begin
          ALine1 := IntToStr(n);
          ALine2 := 'nodos';
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
  // El compte per dia no depen de l'scroll/zoom (map complet del pla) -> no cal
  // recalcular aqui. Repaint IMMEDIAT de timeline i summary perque segueixin el
  // pan/zoom del Gantt sense moviment "a blocs".
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

procedure TfrmVistaGantt.UpdateKPIs;
begin
  lblNodes.Caption := IntToStr(FGanttControl.CNT_TotalNodes);
  lblVisible.Caption := IntToStr(FGanttControl.CNT_TotalVisibleNodes);
  lblModified.Caption := IntToStr(FGanttControl.CNT_TotalModifiedNodes);
  lblNormal.Caption := IntToStr(FGanttControl.CNT_TotalNodes_StateNormal);
  lblYellow.Caption := IntToStr(FGanttControl.CNT_TotalNodes_StateYellow);
  lblOrange.Caption := IntToStr(FGanttControl.CNT_TotalNodes_StateOrange);
  lblRed.Caption := IntToStr(FGanttControl.CNT_TotalNodes_StateRed);
  lblGreen.Caption := IntToStr(FGanttControl.CNT_TotalNodes_StateGreen);
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
    RebuildSummaryData;
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
end;

procedure TfrmVistaGantt.GanttVoidClick(Sender: TObject);
begin
    // Al hacer clic en el fondo, limpiar el resaltado
  FGanttControl.ClearSearch;
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

  if TfrmNodeInspector.Execute(ANodeData, False, FCustomFieldDefs) then
  begin
    ANodeData.Modified := True;
    DMPlanner.NodeDataRepo.AddOrUpdate(ANodeData);
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

  FGanttControl.CompactOFFromNode( idx, 0, (iAllOF=1) , (iPrioridad=1) );
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

  FGanttControl.CompactOTFromNode( idx, 0, (iAllOT=1) , (iPrioridad=1) );

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

procedure TfrmVistaGantt.btnAutoPlanSelClick(Sender: TObject);
var
  SelIndexes: TArray<Integer>;
  I: Integer;
  Ids: TArray<Integer>;
  N: TNode;
begin
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

procedure TfrmVistaGantt.btnAutoPlanAllClick(Sender: TObject);
begin
  if Assigned(Form1) then
    Form1.LaunchAutoPlanificacion([]);  // [] = todo el plan
  if Assigned(FGanttControl) then
    FGanttControl.Invalidate;
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

  FGanttControl.RebuildLayout;
  FGanttControl.Invalidate;
  if Assigned(Form1) then
    Form1.NotifyPlanModified(Ids);
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
