unit uFiniteCapacityPlanner;

{
  TfrmFiniteCapacityPlanner - Planificador de capacidad finita por centro.

  Layout estilo Kanban:
  - Panel izquierdo: OT pendientes de asignar (cards arrastrables).
  - Panel derecho: columnas por centro de trabajo, cada una con capacidad
    finita (MaxLaneCount). Scroll horizontal si hay muchos centros.
  - Drag & drop desde pendientes hacia centros y entre centros.
  - Indicador visual de capacidad (barra ocupación / máximo).
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.Generics.Defaults, System.Math,
  System.DateUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Menus, Vcl.CheckLst, Vcl.ComCtrls,
  cxCheckComboBox, cxCheckBox, cxEdit, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  uGanttTypes, uNodeDataRepo, uNodeInspector, uErpTypes, uCentreCalendar,
  uOperariosTypes, uOperariosRepo, uAssignOperaris, uCentreInspector,
  uPlanningRules, uCustomFieldDefs, uPlanningPreview, uCardLayout,
  uFCPLayoutRepo, dxSkinsCore, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
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
  dxSkinXmas2008Blue, cxButtons;

type
  // Resultado de una asignación
  TFCPAssignment = record
    DataId: Integer;
    CentreId: Integer;
    SortIndex: Integer;
  end;

  TGetNodeTimesFunc = reference to function(const DataId: Integer;
    out AStart, AEnd: TDateTime): Boolean;

  TPendingSortMode = (smPrioridad, smFechaEntrega, smDuracion, smArticulo);

  TPlanningRange = (pr1Dia, pr2Dies, pr3Dies, pr5Dies, pr1Setmana, pr2Setmanes, pr1Mes);

  TFCPActionKind = (akAssign, akUnassign, akMove, akAutoLoad, akClearAll);

  TFCPAction = record
    Kind: TFCPActionKind;
    // Para assign/unassign/move: un solo item
    DataId: Integer;
    OldCentreId: Integer;   // -1 = pendiente
    NewCentreId: Integer;   // -1 = pendiente
    OldIdx: Integer;
    NewIdx: Integer;
    // Para autoload/clearall: snapshot completo
    Snapshot: TArray<TFCPAssignment>;
  end;

  { --------------------------------------------------------- }
  {  TPendingListControl - lista de OT pendientes (izquierda)  }
  { --------------------------------------------------------- }
  TPendingListControl = class(TCustomControl)
  private const
    CARD_H = 82;
    CARD_GAP = 4;
    CARD_MARGIN = 8;
    SCROLLBAR_W = 12;
  private
    FNodeRepo: TNodeDataRepo;
    FOperariosRepo: TOperariosRepo;
    FCustomFieldDefs: TCustomFieldDefs;
    FLinks: TArray<TErpLink>;
    FGetNodeTimes: TGetNodeTimesFunc;
    FCardLayout: TCardLayout;
    FItems: TArray<Integer>;  // DataIds pendientes
    FScrollY: Integer;
    FHoverIdx: Integer;

    // Scrollbar
    FDraggingSB: Boolean;
    FSBGrabY: Integer;
    FSBGrabScrollY: Integer;

    // Selección múltiple
    FSelectedIds: TList<Integer>;

    // Drag
    FDragIdx: Integer;        // index dins FItems
    FDragStartPt: TPoint;
    FDragPending: Boolean;    // mouse down, esperant threshold

    FOnBeginDrag: TNotifyEvent;

    function IdxAtY(const Y: Integer): Integer;
    function MaxScrollY: Integer;
    function IsOnScrollbar(const X: Integer): Boolean;
    function IsSelected(const DataId: Integer): Boolean;
    procedure DrawCard(const ACanvas: TCanvas; const Idx: Integer;
      const R: TRect; const IsHover: Boolean);
    procedure DrawScrollbar(const ACanvas: TCanvas);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure Resize; override;
    procedure DblClick; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetData(ARepo: TNodeDataRepo; const AIds: TArray<Integer>);
    destructor Destroy; override;
    procedure ScrollBy(Delta: Integer);
    function DragDataId: Integer;  // retorna el DataId (no l'index)
    function DragDataIds: TArray<Integer>;  // todos los seleccionados (o el arrastrado)
    property Items: TArray<Integer> read FItems;
    property SelectedIds: TList<Integer> read FSelectedIds;
    property OnBeginDrag: TNotifyEvent read FOnBeginDrag write FOnBeginDrag;
    property CardLayout: TCardLayout read FCardLayout write FCardLayout;
  end;

  { --------------------------------------------------------- }
  {  TCentreColumnControl - columnas de centros (derecha)       }
  { --------------------------------------------------------- }
  TCentreColumnControl = class(TCustomControl)
  private const
    COL_WIDTH = 260;
    COL_GAP = 10;
    HEADER_H = 58;
    CARD_H = 88;
    CARD_GAP = 5;
    CARD_MARGIN = 6;
    CAP_BAR_H = 6;
    VSCROLLBAR_W = 8;
    DAY_SEP_H = 28;
    DAY_SEP_BAND_H = 20;  // alçada del badge/franja; la resta (8px) és aire
    HSCROLLBAR_H = 14;
  private
    FNodeRepo: TNodeDataRepo;
    FOperariosRepo: TOperariosRepo;
    FCustomFieldDefs: TCustomFieldDefs;
    FCentres: TArray<TCentreTreball>;
    FLinks: TArray<TErpLink>;
    FGetNodeTimes: TGetNodeTimesFunc;
    FCardLayout: TCardLayout;
    FGetCalendar: TGetCalendarFunc;
    FPlanningStart: TDateTime;
    FPlanningEnd: TDateTime;
    FVisibleIds: TList<Integer>;  // nil = tots visibles

    // Asignaciones: CentreId -> lista ordenada de DataIds
    FAssignments: TDictionary<Integer, TList<Integer>>;

    FScrollX: Single;
    FScrollYMap: TDictionary<Integer, Integer>;  // CentreId -> scrollY

    // Hover
    FHoverCentreId: Integer;
    FHoverCardIdx: Integer;  // index dentro de la lista del centro

    // Selección múltiple
    FSelectedIds: TList<Integer>;

    // Drop target
    FDropTargetCentreId: Integer;
    FDropTargetIdx: Integer;
    FDropActive: Boolean;

    // Drag visual feedback: estat de cada centre durant drag
    FDragContextActive: Boolean;
    FDragDropStatus: TDictionary<Integer, Integer>;  // CentreId -> 0=neutre, 1=ok, 2=no

    // HScrollbar drag
    FDraggingHSB: Boolean;
    FHSBGrabX: Single;
    FHSBGrabScrollX: Single;

    // Drag desde columna
    FDragCentreId: Integer;
    FDragCardIdx: Integer;
    FDragStartPt: TPoint;
    FDragPending: Boolean;
    FOnBeginDrag: TNotifyEvent;

    // Right click
    FRightClickDataId: Integer;

    // Drag de reordenació de columnes
    FColDragPending: Boolean;
    FColDragging: Boolean;
    FColDragCentreId: Integer;
    FColDragStartPt: TPoint;
    FColDropTargetId: Integer;   // CentreId destí (-1 = cap)
    FColDropBefore: Boolean;     // inserir abans o després del destí

    FOnColDragBegin: TNotifyEvent;
    FOnColDragEnd: TNotifyEvent;

    // Botó opcions header
    FOptionsCentreId: Integer;  // CentreId del botó "..." clicat
    FOnHeaderOptionsClick: TNotifyEvent;

    // VScrollbar drag por columna
    FDraggingVSB: Boolean;
    FVSBCentreId: Integer;
    FVSBGrabY: Integer;
    FVSBGrabScrollY: Integer;

    function IsOnColVScrollbar(const CentreId, LocalX, Y: Integer): Boolean;
    function IsCentreVisible(const CentreId: Integer): Boolean;
    function ContentWidth: Single;
    function MaxScrollX: Single;
    function ColScrollY(const CentreId: Integer): Integer;
    procedure SetColScrollY(const CentreId: Integer; V: Integer);
    function MaxColScrollY(const CentreId: Integer): Integer;
    function DaySepCountBefore(const CentreId, Idx: Integer): Integer;
    function CardYOffset(const CentreId, Idx: Integer): Integer;
    function TotalContentHeight(const CentreId: Integer): Integer;
    procedure DrawDaySeparator(const ACanvas: TCanvas; const CX, Y: Integer;
      const ADate: TDateTime);
    function CardIdxAtPoint(const CentreId: Integer; const Y: Integer): Integer;
    function InsertIdxAtY(const CentreId: Integer; const Y: Integer): Integer;

    procedure DrawColumn(const ACanvas: TCanvas; const ColIdx: Integer;
      const CX: Integer);
    procedure DrawCard(const ACanvas: TCanvas; const CentreId, Idx: Integer;
      const R: TRect; const IsHover: Boolean);
    procedure DrawCapacityBar(const ACanvas: TCanvas; const CentreId: Integer;
      const R: TRect);
    procedure DrawDropIndicator(const ACanvas: TCanvas);
    procedure DrawColVScrollbar(const ACanvas: TCanvas; const CentreId, CX: Integer);
    procedure DrawHScrollbar(const ACanvas: TCanvas);

    function IsOnHScrollbar(const Y: Integer): Boolean;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure Resize; override;
    procedure DblClick; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetData(ARepo: TNodeDataRepo; const ACentres: TArray<TCentreTreball>);
    procedure AssignItem(const DataId, CentreId: Integer; InsertIdx: Integer = -1);
    procedure UnassignItem(const DataId: Integer);
    function IsAssigned(const DataId: Integer): Boolean;
    function GetAssignedCentre(const DataId: Integer): Integer;
    procedure UpdateDropTarget(const ScreenPt: TPoint);
    procedure ClearDropTarget;
    procedure BeginDragContext(const ADataIds: TArray<Integer>);
    procedure EndDragContext;
    procedure SetVisibleCentreIds(const AIds: TList<Integer>);
    property DropTargetCentreId: Integer read FDropTargetCentreId;
    property DropTargetIdx: Integer read FDropTargetIdx;
    property DropActive: Boolean read FDropActive;
    property Assignments: TDictionary<Integer, TList<Integer>> read FAssignments;
    function DragDataId: Integer;
    function DragDataIds: TArray<Integer>;
    function CentreIdAtX(const X: Integer): Integer;
    function CardsTop: Integer;
    procedure ScrollColByDelta(const CentreId: Integer; Delta: Integer);
    procedure ScrollHByDelta(Delta: Integer);
    function ColTotalMinutes(const CentreId: Integer): Double;
    function ColWorkingMinutes(const CentreId: Integer): Double;
    function ColCountForCentre(const CentreId: Integer): Integer;
    function ColCapacity(const CentreId: Integer): Integer;
    function IsSelectedItem(const DataId: Integer): Boolean;
    property SelectedIds: TList<Integer> read FSelectedIds;
    procedure SwapCentres(const IdA, IdB: Integer);
    property OnBeginDrag: TNotifyEvent read FOnBeginDrag write FOnBeginDrag;
    property RightClickDataId: Integer read FRightClickDataId;
    property OptionsCentreId: Integer read FOptionsCentreId;
    property Centres: TArray<TCentreTreball> read FCentres write FCentres;
    property OnHeaderOptionsClick: TNotifyEvent read FOnHeaderOptionsClick write FOnHeaderOptionsClick;
    property OnColDragBegin: TNotifyEvent read FOnColDragBegin write FOnColDragBegin;
    property OnColDragEnd: TNotifyEvent read FOnColDragEnd write FOnColDragEnd;
    property ColDragCentreId: Integer read FColDragCentreId;
    property ColDropTargetId: Integer read FColDropTargetId;
    property CardLayout: TCardLayout read FCardLayout write FCardLayout;
  end;

  { --------------------------------------------------------- }
  {  TfrmFiniteCapacityPlanner - formulario principal           }
  { --------------------------------------------------------- }
  TfrmFiniteCapacityPlanner = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlSeparator: TPanel;
    splitter: TSplitter;
    pnlPending: TPanel;
    lblPendingTitle: TLabel;
    pnlSearch: TPanel;
    edtSearch: TEdit;
    lblSearchClear: TLabel;
    pnlCentres: TPanel;
    pnlHeaderCentres: TPanel;
    lblCentresTitle: TLabel;
    lblFilterCaption: TLabel;
    cbCentros: TcxCheckComboBox;
    pnlHeaderButtons: TPanel;
    pnlFooter: TPanel;
    lblFooterPending: TLabel;
    lblFooterAssigned: TLabel;
    lblFooterHours: TLabel;
    lblFooterCapacity: TLabel;
    PnlUndo: TPanel;
    LblUndoIcon: TLabel;
    FBtnUndo: TLabel;
    SepUR: TPanel;
    PnlRedo: TPanel;
    LblRedoIcon: TLabel;
    FBtnRedo: TLabel;
    FBtnOptions: TPanel;
    LblDots: TLabel;
    btnLayoutNew: TcxButton;
    btnLayoutDelete: TcxButton;
    cmbLayout: TcxComboBox;
    lblLayout: TLabel;
    btnLayoutSave: TcxButton;
    btnAyuda: TButton;
    LblRango: TLabel;
    FDtpStart: TDateTimePicker;
    FCmbRange: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure lblSearchClearClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnBtnOptionsClick(Sender: TObject);
    procedure OnUndoClick(Sender: TObject);
    procedure OnRedoClick(Sender: TObject);
    procedure OnRangeChange(Sender: TObject);
    procedure OnStartDateChange(Sender: TObject);
    procedure cbCentrosChange(Sender: TObject);
    procedure cmbLayoutChange(Sender: TObject);
    procedure btnLayoutDeleteClick(Sender: TObject);
    procedure btnAyudaClick(Sender: TObject);
    procedure btnLayoutNewClick(Sender: TObject);
    procedure btnLayoutSaveClick(Sender: TObject);
  private
    FNodeRepo: TNodeDataRepo;
    FOperariosRepo: TOperariosRepo;
    FCentres: TArray<TCentreTreball>;
    FGetNodeTimes: TGetNodeTimesFunc;
    FGetCalendar: TGetCalendarFunc;
    FLinks: TArray<TErpLink>;
    FRuleEngine: TPlanningRuleEngine;  // referència, pot ser nil
    FCustomFieldDefs: TCustomFieldDefs; // referència, pot ser nil

    FPendingList: TPendingListControl;
    FCentreColumns: TCentreColumnControl;

    // Drag inter-control
    FInterDragging: Boolean;
    FInterDragDataId: Integer;
    FInterDragDataIds: TArray<Integer>;  // multi-selección
    FDragFromCentre: Boolean;  // True = drag originado en columna, False = desde pendientes

    // Ghost card durante drag (finestra overlay)
    FGhostBmp: TBitmap;
    FGhostForm: TForm;

    // Botón opciones pendientes (popup dinàmic; FBtnOptions ja és al DFM)
    FPendingPopup: TPopupMenu;

    // Menú contextual centros (cards)
    FCentrePopup: TPopupMenu;
    FPopupDataId: Integer;

    // Menú opcions header centre
    FCentreHeaderPopup: TPopupMenu;

    // Drag de columna
    FColDragging: Boolean;
    FColGhostForm: TForm;

    // Filtro de centros (multi-select via cbCentros: TcxCheckComboBox)
    FVisibleCentreIds: TList<Integer>;
    FUpdatingCentros: Boolean;  // anti-recursió a cbCentrosChange

    // Layouts d'usuari
    FLayoutRepo: TFCPLayoutRepo;
    FLayouts: TArray<TFCPLayout>;
    FCurrentLayoutId: Integer;  // -1 = "(por defecto)"; >=0 = ID a BD
    FUpdatingLayouts: Boolean;

    // Búsqueda y ordenación pendientes
    FSearchFilter: string;
    FSortMode: TPendingSortMode;
    FEstadoFilter: set of TNodoEstado;  // estats visibles
    FOperacionFilter: TStringList;      // operacions visibles (buit = totes)

    // Dialeg "Filtros" (Estados + Operacion) - modal centrat
    FFiltrosBtn: TPanel;
    FFiltrosBtnLbl: TLabel;
    FFiltrosEstadoChecks: array[TNodoEstado] of TCheckBox;
    FFiltrosOpList: TCheckListBox;

    // Undo / Redo (FBtnUndo/FBtnRedo ja s'on al DFM)
    FUndoStack: TList<TFCPAction>;
    FRedoStack: TList<TFCPAction>;

    // Auto-scroll durant drag
    FAutoScrollTimer: TTimer;

    // Rang de planificació (FCmbRange/FDtpStart ja són al DFM)
    FPlanningRange: TPlanningRange;
    FPlanningStart: TDateTime;

    // Dates calculades per capacitat finita: DataId -> (Start, End)
    FCalculatedTimes: TDictionary<Integer, TAbsInterval>;
    FGetNodeTimesCalc: TGetNodeTimesFunc;  // wrapper que consulta FCalculatedTimes

    // Cache dels Start/End originals de BD (omplerts a Inicializar; ara és
    // camp d'instància perquè la closure FGetNodeTimes el necessita viu).
    FNodeTimesCache: TDictionary<Integer, TAbsInterval>;

    // Backlog: DataIds sintètics (negatius) per Raw_Items encara no planificats.
    // Mapeja DataId(negatiu) -> RawItemId(positiu) per persistir-los a Aceptar.
    FBacklogRawItemIdByDataId: TDictionary<Integer, Integer>;
    // DataIds positius que ja tenien centre quan s'ha obert el form (per detectar
    // des-assignacions: si no apareixen al BuildAssignments final, cal posar
    // CenterId=NULL a FS_PL_Node).
    FInitiallyAssignedDataIds: TList<Integer>;

    procedure LoadBacklogPending;
    procedure PersistAssignments;

    procedure BuildPendingList;
    procedure UpdatePendingCount;
    procedure HandleDrop(const ScreenPt: TPoint);
    procedure DrawGhostCard(const DataId: Integer);
    procedure OnPendingBeginDrag(Sender: TObject);
    procedure OnCentreBeginDrag(Sender: TObject);
    procedure DoDragMove(const ScreenPt: TPoint);
    procedure DoDragEnd(const ScreenPt: TPoint);
    procedure BuildOptionsPopup;
    procedure BuildCentrePopup;
    procedure OnCentrePopupShow(Sender: TObject);
    procedure OnCentrePopupUnassign(Sender: TObject);
    procedure OnCentrePopupAssignOperaris(Sender: TObject);
    procedure BuildCentreHeaderPopup;
    procedure OnCentreHeaderViewFicha(Sender: TObject);
    procedure OnCentreHeaderOptionsClick(Sender: TObject);
    procedure OnColDragBegin(Sender: TObject);
    procedure DoColDragMove(const ScreenPt: TPoint);
    procedure DoColDragEnd(const ScreenPt: TPoint);
    procedure OnAutoLoadClick(Sender: TObject);
    procedure OnAutoLoadRulesClick(Sender: TObject);
    procedure DoAutoLoad(const ByFechaEntrega: Boolean);
    procedure DoAutoLoadWithRules;
    procedure OnClearAllClick(Sender: TObject);
    procedure OnSortClick(Sender: TObject);
    procedure OnEstadoFilterClick(Sender: TObject);
    procedure OnOperacionFilterClick(Sender: TObject);
    procedure OnOperacionMarkAllClick(Sender: TObject);
    procedure OnOperacionUnmarkAllClick(Sender: TObject);
    procedure LoadOperacionesFromDB(AList: TStringList);
    procedure RefreshOperacionMenuChecks(AMenu: TMenuItem);
    // Dropdown "Filtros" (Estados + Operacion)
    procedure BuildFiltrosBtn;
    procedure OnFiltrosBtnClick(Sender: TObject);
    procedure ShowFiltrosDropDown;
    procedure CloseFiltrosDropDown;
    procedure OnFiltrosDropDownDeactivate(Sender: TObject);
    procedure CloseAllDropDowns;
    procedure WMMove(var Msg: TMessage); message WM_MOVE;
    procedure WMSize(var Msg: TMessage); message WM_SIZE;
    procedure OnFiltrosEstadoChange(Sender: TObject);
    procedure OnFiltrosOpClick(Sender: TObject);
    procedure OnFiltrosOpMarkAllClick(Sender: TObject);
    procedure OnFiltrosOpUnmarkAllClick(Sender: TObject);
    procedure OnSelectAllClick(Sender: TObject);
    procedure OnDeselectAllClick(Sender: TObject);
    procedure UpdateFooter;
    procedure PushUndo(const AAction: TFCPAction);
    procedure DoUndo;
    procedure DoRedo;
    procedure UpdateUndoRedoButtons;
    function TakeSnapshot: TArray<TFCPAssignment>;
    procedure RestoreSnapshot(const ASnap: TArray<TFCPAssignment>);
    procedure OnAutoScrollTimer(Sender: TObject);
    procedure OnExportClick(Sender: TObject);
    procedure GetPlanningDates(out AStart, AEnd: TDateTime);
    procedure RecalcAllCentreTimes;
    procedure RecalcCentreTimes(const CentreId: Integer);
    procedure PopularCentrosCombo;
    procedure ApplyCentreFilter;
    procedure LoadLayouts;
    procedure PopularCmbLayout(ASelectedLayoutId: Integer = -2);
    procedure ApplyLayout(const ALayoutId: Integer);
    function CapturarLayoutActual: TArray<TFCPLayoutCentro>;
    procedure CentresOrdenAlfabetic;
    function BuildAssignments: TArray<TFCPAssignment>;
    procedure OnEditCardLayoutClick(Sender: TObject);
  protected
    procedure WndProc(var Message: TMessage); override;
  public
    procedure Inicializar(
      ANodeRepo: TNodeDataRepo;
      AOperariosRepo: TOperariosRepo;
      ARuleEngine: TPlanningRuleEngine = nil;
      ACustomFieldDefs: TCustomFieldDefs = nil);
    procedure SaveNow;
  end;

implementation

uses
  Data.Win.ADODB,
  uDMPlanner, uCentresRepo, uNodesRepo, uHelpViewer,
  uCardLayoutEditor;

{$R *.dfm}

{ ========================================================= }
{                   Funciones auxiliares                      }
{ ========================================================= }

function PrioridadColor(const P: Integer): TColor;
begin
  case P of
    1: Result := $004040FF;
    2: Result := $000080FF;
    3: Result := $00FF8000;
  else Result := $00B0B0B0;
  end;
end;

function PrioridadText(const P: Integer): string;
begin
  case P of
    1: Result := 'ALTA';
    2: Result := 'MEDIA';
    3: Result := 'BAJA';
  else Result := '-';
  end;
end;

function EstadoColor(const E: TNodoEstado): TColor;
begin
  case E of
    nePendiente:  Result := $00B0B0B0;
    neEnCurso:    Result := $00E89040;
    neFinalizado: Result := $0040B040;
    neBloqueado:  Result := $004040E0;
  else Result := $00B0B0B0;
  end;
end;

function EstadoAbrev(const E: TNodoEstado): string;
begin
  case E of
    nePendiente:  Result := 'PEND';
    neEnCurso:    Result := 'CURSO';
    neFinalizado: Result := 'FIN';
    neBloqueado:  Result := 'BLOQ';
  else Result := '-';
  end;
end;

function BlendColor(const C1, C2: TColor; const Alpha: Byte): TColor;
var
  R1, G1, B1, R2, G2, B2: Byte;
begin
  R1 := GetRValue(ColorToRGB(C1)); G1 := GetGValue(ColorToRGB(C1)); B1 := GetBValue(ColorToRGB(C1));
  R2 := GetRValue(ColorToRGB(C2)); G2 := GetGValue(ColorToRGB(C2)); B2 := GetBValue(ColorToRGB(C2));
  Result := RGB(
    R1 + MulDiv(R2 - R1, Alpha, 255),
    G1 + MulDiv(G2 - G1, Alpha, 255),
    B1 + MulDiv(B2 - B1, Alpha, 255));
end;

function GetOperariosAssignats(ARepo: TOperariosRepo; const DataId: Integer): Integer;
var
  Asigs: TArray<TAsignacionOperario>;
begin
  Result := 0;
  if ARepo = nil then Exit;
  Asigs := ARepo.GetAsignacionsByNode(DataId);
  Result := Length(Asigs);
end;

function HasPendingPredecessors(const DataId: Integer;
  const ALinks: TArray<TErpLink>; ARepo: TNodeDataRepo): Boolean;
var
  I: Integer;
  Pred: TNodeData;
begin
  Result := False;
  for I := 0 to High(ALinks) do
  begin
    if ALinks[I].ToNodeId = DataId then
    begin
      // Este DataId tiene un predecesor
      if ARepo.TryGetById(ALinks[I].FromNodeId, Pred) then
      begin
        if Pred.Estado <> neFinalizado then
          Exit(True);
      end;
    end;
  end;
end;

function BuildTooltipText(const D: TNodeData;
  AGetNodeTimes: TGetNodeTimesFunc): string;
var
  S: string;
  NStart, NEnd: TDateTime;
begin
  S := 'OF ' + IntToStr(D.NumeroOrdenFabricacion);
  if D.Operacion <> '' then
    S := S + ' - ' + D.Operacion;
  S := S + #13#10 + D.CodigoArticulo + ' ' + D.DescripcionArticulo;
  if D.CodigoCliente <> '' then
    S := S + #13#10 + 'Cliente: ' + D.CodigoCliente;
  if D.DurationMin >= 60 then
    S := S + #13#10 + 'Duraci' + #$00F3 + 'n: ' + Format('%.1f h', [D.DurationMin / 60])
  else if D.DurationMin > 0 then
    S := S + #13#10 + 'Duraci' + #$00F3 + 'n: ' + Format('%.0f min', [D.DurationMin]);
  if Assigned(AGetNodeTimes) and AGetNodeTimes(D.DataId, NStart, NEnd) and (NStart > 0) then
    S := S + #13#10 + 'Inicio: ' + FormatDateTime('dd/mm/yyyy hh:nn', NStart) +
             #13#10 + 'Fin: ' + FormatDateTime('dd/mm/yyyy hh:nn', NEnd);
  if D.FechaEntrega > 0 then
    S := S + #13#10 + 'Entrega: ' + FormatDateTime('dd/mm/yyyy', D.FechaEntrega);
  if D.UnidadesAFabricar > 0 then
    S := S + #13#10 + 'Uds: ' + Format('%.0f', [D.UnidadesAFabricar]);
  if D.OperariosNecesarios > 0 then
    S := S + #13#10 + 'Operarios: ' + IntToStr(D.OperariosAsignados) + '/' +
             IntToStr(D.OperariosNecesarios);
  S := S + #13#10 + 'Estado: ' + EstadoAbrev(D.Estado);
  S := S + '  |  Prioridad: ' + PrioridadText(D.Prioridad);
  if D.PorcentajeDependencia > 0 then
    S := S + #13#10 + 'Dependencia: ' + Format('%.0f%%', [D.PorcentajeDependencia]);
  Result := S;
end;

{ ========================================================= }
{                   TPendingListControl                      }
{ ========================================================= }

constructor TPendingListControl.Create(AOwner: TComponent);
begin
  inherited;
  DoubleBuffered := True;
  ShowHint := True;
  Color := $00F2F0EC;
  FScrollY := 0;
  FHoverIdx := -1;
  FDragIdx := -1;
  FDragPending := False;
  FDraggingSB := False;
  FSelectedIds := TList<Integer>.Create;
  FCardLayout := DefaultPendingCardLayout;
end;

destructor TPendingListControl.Destroy;
begin
  FSelectedIds.Free;
  inherited;
end;

procedure TPendingListControl.ScrollBy(Delta: Integer);
begin
  FScrollY := Max(0, Min(FScrollY + Delta, MaxScrollY));
  Invalidate;
end;

function TPendingListControl.IsSelected(const DataId: Integer): Boolean;
begin
  Result := FSelectedIds.Contains(DataId);
end;

function TPendingListControl.DragDataIds: TArray<Integer>;
var
  DId: Integer;
begin
  if FSelectedIds.Count > 0 then
    Result := FSelectedIds.ToArray
  else
  begin
    DId := DragDataId;
    if DId >= 0 then
      Result := TArray<Integer>.Create(DId)
    else
      Result := nil;
  end;
end;

procedure TPendingListControl.SetData(ARepo: TNodeDataRepo;
  const AIds: TArray<Integer>);
begin
  FNodeRepo := ARepo;
  FItems := AIds;
  FScrollY := 0;
  FHoverIdx := -1;
  Invalidate;
end;

function TPendingListControl.DragDataId: Integer;
begin
  if (FDragIdx >= 0) and (FDragIdx <= High(FItems)) then
    Result := FItems[FDragIdx]
  else
    Result := -1;
end;

function TPendingListControl.MaxScrollY: Integer;
begin
  Result := Max(0, Length(FItems) * (CARD_H + CARD_GAP) - ClientHeight + CARD_MARGIN * 2);
end;

function TPendingListControl.IsOnScrollbar(const X: Integer): Boolean;
begin
  Result := (X >= ClientWidth - SCROLLBAR_W) and (MaxScrollY > 0);
end;

function TPendingListControl.IdxAtY(const Y: Integer): Integer;
var
  Idx: Integer;
begin
  Idx := (Y + FScrollY - CARD_MARGIN) div (CARD_H + CARD_GAP);
  if (Idx >= 0) and (Idx <= High(FItems)) then
    Result := Idx
  else
    Result := -1;
end;

procedure TPendingListControl.DrawCard(const ACanvas: TCanvas;
  const Idx: Integer; const R: TRect; const IsHover: Boolean);
var
  D: TNodeData;
  BadgeR: TRect;
  DaysLeft: Integer;
  Vencida, Urgente: Boolean;
  Resolver: TCardFieldResolver;
begin
  if not FNodeRepo.TryGetById(FItems[Idx], D) then Exit;

  // Calcular urgencia
  Vencida := False;
  Urgente := False;
  if D.FechaEntrega > 0 then
  begin
    DaysLeft := Trunc(D.FechaEntrega - Date);
    Vencida := DaysLeft < 0;
    Urgente := (DaysLeft >= 0) and (DaysLeft <= 3);
  end;

  // Fondo y borde "naturals" — la selecció només engruixa el border, sense
  // alterar background ni color de border.
  if Vencida then
    ACanvas.Brush.Color := $00E8E0F0
  else if IsHover then
    ACanvas.Brush.Color := $00F0EDE8
  else
    ACanvas.Brush.Color := clWhite;
  if Vencida then
    ACanvas.Pen.Color := $004040FF
  else if Urgente then
    ACanvas.Pen.Color := $000080FF
  else
    ACanvas.Pen.Color := $00E0E0E0;
  if IsSelected(D.DataId) then
    ACanvas.Pen.Width := 3
  else
    ACanvas.Pen.Width := 1;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom,
    FCardLayout.CornerRadius, FCardLayout.CornerRadius);
  ACanvas.Pen.Width := 1;

  // Renderizar contenido con el layout configurable
  Resolver := MakeNodeDataResolver(D);
  RenderCard(ACanvas, R, FCardLayout, Resolver);

  // Indicador de dependencias pendientes (siempre visible)
  if HasPendingPredecessors(D.DataId, FLinks, FNodeRepo) then
  begin
    BadgeR := Rect(R.Right - 22, R.Top + 6, R.Right - 6, R.Top + 22);
    ACanvas.Brush.Color := $0000AAFF;
    ACanvas.Pen.Style := psClear;
    ACanvas.Ellipse(BadgeR.Left, BadgeR.Top, BadgeR.Right, BadgeR.Bottom);
    ACanvas.Font.Size := 8;
    ACanvas.Font.Style := [fsBold];
    ACanvas.Font.Color := clWhite;
    ACanvas.Brush.Style := bsClear;
    DrawText(ACanvas.Handle, '!', -1, BadgeR,
      DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);
    ACanvas.Pen.Style := psSolid;
  end;
end;

procedure TPendingListControl.DrawScrollbar(const ACanvas: TCanvas);
var
  TrackR, ThumbR: TRect;
  ContentH, Ratio, ThumbH, ThumbY: Single;
  MxSY: Integer;
begin
  MxSY := MaxScrollY;
  if MxSY <= 0 then Exit;

  TrackR := Rect(ClientWidth - SCROLLBAR_W, 0, ClientWidth, ClientHeight);
  ACanvas.Brush.Color := $00F0EEEA;
  ACanvas.Pen.Style := psClear;
  ACanvas.FillRect(TrackR);

  ContentH := Length(FItems) * (CARD_H + CARD_GAP) + CARD_MARGIN * 2;
  Ratio := ClientHeight / ContentH;
  ThumbH := Max(24, TrackR.Height * Ratio);
  if MxSY > 0 then
    ThumbY := (FScrollY / MxSY) * (TrackR.Height - ThumbH)
  else
    ThumbY := 0;

  ThumbR := Rect(TrackR.Left + 2, Round(ThumbY) + 2,
                 TrackR.Right - 2, Round(ThumbY + ThumbH) - 2);
  ACanvas.Brush.Color := $00C0BEB8;
  ACanvas.RoundRect(ThumbR.Left, ThumbR.Top, ThumbR.Right, ThumbR.Bottom, 6, 6);
  ACanvas.Pen.Style := psSolid;
end;

procedure TPendingListControl.Paint;
var
  I, Y, First, Last: Integer;
  R: TRect;
begin
  inherited;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  if (FNodeRepo = nil) or (Length(FItems) = 0) then
  begin
    Canvas.Font.Size := 10;
    Canvas.Font.Color := $00BBBBBB;
    Canvas.Font.Style := [];
    Canvas.Brush.Style := bsClear;
    var TR := ClientRect;
    DrawText(Canvas.Handle, 'Sin OT pendientes', -1, TR,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
    Exit;
  end;

  First := Max(0, (FScrollY - CARD_MARGIN) div (CARD_H + CARD_GAP));
  Last := Min(High(FItems), (FScrollY + ClientHeight) div (CARD_H + CARD_GAP) + 1);

  for I := First to Last do
  begin
    Y := CARD_MARGIN + I * (CARD_H + CARD_GAP) - FScrollY;
    if Y + CARD_H < 0 then Continue;
    if Y > ClientHeight then Break;
    R := Rect(CARD_MARGIN, Y, ClientWidth - SCROLLBAR_W - CARD_MARGIN, Y + CARD_H);
    DrawCard(Canvas, I, R, I = FHoverIdx);
  end;

  DrawScrollbar(Canvas);
end;

procedure TPendingListControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button <> mbLeft then Exit;

  // No iniciar drag en doble clic
  if ssDouble in Shift then Exit;

  if IsOnScrollbar(X) then
  begin
    FDraggingSB := True;
    FSBGrabY := Y;
    FSBGrabScrollY := FScrollY;
    MouseCapture := True;
    Exit;
  end;

  FDragIdx := IdxAtY(Y);
  if FDragIdx >= 0 then
  begin
    var ClickedId := FItems[FDragIdx];

    if ssCtrl in Shift then
    begin
      // Toggle selección
      if FSelectedIds.Contains(ClickedId) then
        FSelectedIds.Remove(ClickedId)
      else
        FSelectedIds.Add(ClickedId);
      Invalidate;
    end
    else
    begin
      // Sin Ctrl: si no está seleccionado, limpiar y seleccionar solo este
      if not FSelectedIds.Contains(ClickedId) then
      begin
        FSelectedIds.Clear;
        FSelectedIds.Add(ClickedId);
        Invalidate;
      end;
    end;

    FDragStartPt := Point(X, Y);
    FDragPending := True;
    MouseCapture := True;
  end
  else
  begin
    // Clic en zona vacía: limpiar selección
    if not (ssCtrl in Shift) then
    begin
      FSelectedIds.Clear;
      Invalidate;
    end;
  end;
end;

procedure TPendingListControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewHover, MxSY: Integer;
begin
  inherited;

  if FDraggingSB then
  begin
    MxSY := MaxScrollY;
    if MxSY > 0 then
    begin
      var ContentH: Single := Length(FItems) * (CARD_H + CARD_GAP) + CARD_MARGIN * 2;
      var Ratio: Single := ContentH / ClientHeight;
      FScrollY := Max(0, Min(Round(FSBGrabScrollY + (Y - FSBGrabY) * Ratio), MxSY));
      Invalidate;
    end;
    Exit;
  end;

  // Drag threshold — dispara event i allibera capture perque el form prengui el control
  if FDragPending and (FDragIdx >= 0) then
  begin
    if (Abs(X - FDragStartPt.X) > 5) or (Abs(Y - FDragStartPt.Y) > 5) then
    begin
      FDragPending := False;
      MouseCapture := False;  // alliberar capture
      if Assigned(FOnBeginDrag) then
        FOnBeginDrag(Self);
      Exit;  // el form gestiona a partir d'aquí
    end;
  end;

  if not FDragPending then
  begin
    NewHover := IdxAtY(Y);
    if NewHover <> FHoverIdx then
    begin
      FHoverIdx := NewHover;
      // Tooltip
      if (NewHover >= 0) and (FNodeRepo <> nil) then
      begin
        var D: TNodeData;
        if FNodeRepo.TryGetById(FItems[NewHover], D) then
          Hint := BuildTooltipText(D, FGetNodeTimes)
        else
          Hint := '';
      end
      else
        Hint := '';
      Application.CancelHint;
      Invalidate;
    end;
  end;
end;

procedure TPendingListControl.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FDraggingSB or FDragPending then
    MouseCapture := False;
  FDraggingSB := False;
  FDragPending := False;
  FDragIdx := -1;
  Invalidate;
end;

function TPendingListControl.DoMouseWheel(Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := True;
  FScrollY := Max(0, Min(FScrollY - WheelDelta div 2, MaxScrollY));
  Invalidate;
end;

procedure TPendingListControl.Resize;
begin
  inherited;
  FScrollY := Max(0, Min(FScrollY, MaxScrollY));
  Invalidate;
end;

procedure TPendingListControl.DblClick;
var
  Pt: TPoint;
  Idx: Integer;
  D: TNodeData;
begin
  inherited;
  // Cancelar drag pendiente
  if FDragPending then
  begin
    FDragPending := False;
    FDragIdx := -1;
    MouseCapture := False;
  end;
  Pt := ScreenToClient(Mouse.CursorPos);
  Idx := IdxAtY(Pt.Y);
  if (Idx >= 0) and (FNodeRepo <> nil) and FNodeRepo.TryGetById(FItems[Idx], D) then
    TfrmNodeInspector.Execute(D, True, FCustomFieldDefs);
end;

{ ========================================================= }
{                   TCentreColumnControl                     }
{ ========================================================= }

constructor TCentreColumnControl.Create(AOwner: TComponent);
begin
  inherited;
  DoubleBuffered := True;
  Color := $00F0F0EC;
  FAssignments := TDictionary<Integer, TList<Integer>>.Create;
  FScrollYMap := TDictionary<Integer, Integer>.Create;
  FSelectedIds := TList<Integer>.Create;
  FDragDropStatus := TDictionary<Integer, Integer>.Create;
  FDragContextActive := False;
  FPlanningStart := 0;
  FPlanningEnd := 0;
  FScrollX := 0;
  FHoverCentreId := -1;
  FHoverCardIdx := -1;
  FDropTargetCentreId := -1;
  FDropTargetIdx := -1;
  FDropActive := False;
  FDraggingHSB := False;
  FVisibleIds := nil;
  FDragCentreId := -1;
  FDragCardIdx := -1;
  FDragPending := False;
  FRightClickDataId := -1;
  FColDragPending := False;
  FColDragging := False;
  FColDragCentreId := -1;
  FColDropTargetId := -1;
  FOptionsCentreId := -1;
  FDraggingVSB := False;
  FCardLayout := DefaultCardLayout;
  FVSBCentreId := -1;
  ShowHint := True;
end;

destructor TCentreColumnControl.Destroy;
var
  Pair: TPair<Integer, TList<Integer>>;
begin
  for Pair in FAssignments do
    Pair.Value.Free;
  FAssignments.Free;
  FScrollYMap.Free;
  FSelectedIds.Free;
  FDragDropStatus.Free;
  inherited;
end;

procedure TCentreColumnControl.SetData(ARepo: TNodeDataRepo;
  const ACentres: TArray<TCentreTreball>);
var
  I: Integer;
begin
  FNodeRepo := ARepo;
  FCentres := ACentres;
  // Inicializar listas vacías para cada centro (incluyendo no visibles, por si cambia)
  for I := 0 to High(FCentres) do
  begin
    if FCentres[I].Id < 0 then Continue;
    if not FAssignments.ContainsKey(FCentres[I].Id) then
      FAssignments.Add(FCentres[I].Id, TList<Integer>.Create);
    if not FScrollYMap.ContainsKey(FCentres[I].Id) then
      FScrollYMap.Add(FCentres[I].Id, 0);
  end;
  Invalidate;
end;

function TCentreColumnControl.IsCentreVisible(const CentreId: Integer): Boolean;
begin
  if FVisibleIds = nil then
    Result := True  // sense filtre = tots visibles
  else
    Result := FVisibleIds.Contains(CentreId);
end;

procedure TCentreColumnControl.SetVisibleCentreIds(const AIds: TList<Integer>);
begin
  FVisibleIds := AIds;  // referència, no copia — la gestiona el form
  FScrollX := 0;
  Invalidate;
end;

function TCentreColumnControl.ContentWidth: Single;
var
  N, I: Integer;
begin
  N := 0;
  for I := 0 to High(FCentres) do
    if FCentres[I].Visible and (FCentres[I].Id >= 0) and IsCentreVisible(FCentres[I].Id) then
      Inc(N);
  Result := N * (COL_WIDTH + COL_GAP) + COL_GAP;
end;

function TCentreColumnControl.MaxScrollX: Single;
begin
  Result := Max(0, ContentWidth - ClientWidth);
end;

function TCentreColumnControl.ColScrollY(const CentreId: Integer): Integer;
var
  V: Integer;
begin
  if FScrollYMap.TryGetValue(CentreId, V) then
    Result := V
  else
    Result := 0;
end;

procedure TCentreColumnControl.SetColScrollY(const CentreId: Integer; V: Integer);
begin
  V := Max(0, Min(V, MaxColScrollY(CentreId)));
  FScrollYMap.AddOrSetValue(CentreId, V);
end;

function TCentreColumnControl.MaxColScrollY(const CentreId: Integer): Integer;
var
  VisibleH: Integer;
begin
  VisibleH := ClientHeight - HSCROLLBAR_H - CardsTop;
  Result := Max(0, TotalContentHeight(CentreId) - VisibleH);
end;

function TCentreColumnControl.ColCountForCentre(const CentreId: Integer): Integer;
var
  L: TList<Integer>;
begin
  if FAssignments.TryGetValue(CentreId, L) then
    Result := L.Count
  else
    Result := 0;
end;

function TCentreColumnControl.ColCapacity(const CentreId: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;  // 0 = sin límite
  for I := 0 to High(FCentres) do
    if FCentres[I].Id = CentreId then
    begin
      Result := FCentres[I].MaxLaneCount;
      Exit;
    end;
end;

function TCentreColumnControl.ColTotalMinutes(const CentreId: Integer): Double;
var
  L: TList<Integer>;
  I: Integer;
  D: TNodeData;
begin
  Result := 0;
  if not FAssignments.TryGetValue(CentreId, L) then Exit;
  for I := 0 to L.Count - 1 do
    if FNodeRepo.TryGetById(L[I], D) then
      Result := Result + D.DurationMin;
end;

function TCentreColumnControl.ColWorkingMinutes(const CentreId: Integer): Double;
var
  Cal: TCentreCalendar;
begin
  Result := 0;
  if not Assigned(FGetCalendar) then Exit;
  if FPlanningEnd <= FPlanningStart then Exit;
  Cal := FGetCalendar(CentreId);
  if Cal = nil then Exit;
  Result := Cal.WorkingMinutesBetween(FPlanningStart, FPlanningEnd);
end;

procedure TCentreColumnControl.AssignItem(const DataId, CentreId: Integer;
  InsertIdx: Integer);
var
  L: TList<Integer>;
begin
  // Primero desasignar de cualquier otro centro
  UnassignItem(DataId);

  if not FAssignments.TryGetValue(CentreId, L) then
  begin
    L := TList<Integer>.Create;
    FAssignments.Add(CentreId, L);
  end;

  if InsertIdx < 0 then InsertIdx := L.Count;
  if InsertIdx > L.Count then InsertIdx := L.Count;
  L.Insert(InsertIdx, DataId);
  Invalidate;
end;

procedure TCentreColumnControl.UnassignItem(const DataId: Integer);
var
  Pair: TPair<Integer, TList<Integer>>;
begin
  for Pair in FAssignments do
    if Pair.Value.Contains(DataId) then
    begin
      Pair.Value.Remove(DataId);
      Break;
    end;
  Invalidate;
end;

function TCentreColumnControl.IsAssigned(const DataId: Integer): Boolean;
var
  Pair: TPair<Integer, TList<Integer>>;
begin
  Result := False;
  for Pair in FAssignments do
    if Pair.Value.Contains(DataId) then
      Exit(True);
end;

function TCentreColumnControl.GetAssignedCentre(const DataId: Integer): Integer;
var
  Pair: TPair<Integer, TList<Integer>>;
begin
  Result := -1;
  for Pair in FAssignments do
    if Pair.Value.Contains(DataId) then
      Exit(Pair.Key);
end;

function TCentreColumnControl.CentreIdAtX(const X: Integer): Integer;
var
  I, ColIdx, CX: Integer;
begin
  Result := -1;
  ColIdx := 0;
  for I := 0 to High(FCentres) do
  begin
    if not FCentres[I].Visible then Continue;
    if FCentres[I].Id < 0 then Continue;
    if not IsCentreVisible(FCentres[I].Id) then Continue;
    CX := Round(COL_GAP + ColIdx * (COL_WIDTH + COL_GAP) - FScrollX);
    if (X >= CX) and (X < CX + COL_WIDTH) then
      Exit(FCentres[I].Id);
    Inc(ColIdx);
  end;
end;

function TCentreColumnControl.DaySepCountBefore(const CentreId, Idx: Integer): Integer;
var
  L: TList<Integer>;
  I: Integer;
  D: TNodeData;
  NStart, NEnd: TDateTime;
  PrevDay, CurDay: Integer;
begin
  Result := 0;
  if not Assigned(FGetNodeTimes) then Exit;
  if not FAssignments.TryGetValue(CentreId, L) then Exit;

  PrevDay := -1;
  for I := 0 to Min(Idx - 1, L.Count - 1) do
  begin
    if FNodeRepo.TryGetById(L[I], D) and FGetNodeTimes(D.DataId, NStart, NEnd) and (NStart > 0) then
      CurDay := Trunc(NStart)
    else
      CurDay := -1;

    if (CurDay > 0) and (PrevDay > 0) and (CurDay <> PrevDay) then
      Inc(Result);
    PrevDay := CurDay;
  end;
end;

function TCentreColumnControl.CardYOffset(const CentreId, Idx: Integer): Integer;
begin
  Result := Idx * (CARD_H + CARD_GAP) + DaySepCountBefore(CentreId, Idx) * DAY_SEP_H;
end;

function TCentreColumnControl.TotalContentHeight(const CentreId: Integer): Integer;
var
  N, Seps: Integer;
begin
  N := ColCountForCentre(CentreId);
  if N = 0 then Exit(0);
  Seps := DaySepCountBefore(CentreId, N);
  Result := N * (CARD_H + CARD_GAP) + Seps * DAY_SEP_H + CARD_GAP;
end;

procedure TCentreColumnControl.DrawDaySeparator(const ACanvas: TCanvas;
  const CX, Y: Integer; const ADate: TDateTime);
var
  R, BadgeR: TRect;
  S: string;
  TextW: Integer;
  LineY, X1, X2: Integer;
  BandTop, BandBot: Integer;
begin
  S := AnsiUpperCase(FormatDateTime('ddd dd/mm', ADate));
  // Centrar la banda de DAY_SEP_BAND_H dins DAY_SEP_H deixant aire dalt i baix.
  BandTop := Y + (DAY_SEP_H - DAY_SEP_BAND_H) div 2;
  BandBot := BandTop + DAY_SEP_BAND_H;
  LineY := (BandTop + BandBot) div 2;
  X1 := CX + 6;
  X2 := CX + COL_WIDTH - VSCROLLBAR_W - 6;

  // Fons del separador — franja subtil
  R := Rect(X1, BandTop + 2, X2, BandBot - 2);
  ACanvas.Brush.Color := $00F0ECE8;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 4, 4);
  ACanvas.Pen.Style := psSolid;

  // Badge del dia (fons color accent)
  ACanvas.Font.Size := 7;
  ACanvas.Font.Style := [fsBold];
  TextW := ACanvas.TextWidth(S);
  BadgeR := Rect(X1 + 4, BandTop + 3, X1 + TextW + 14, BandBot - 3);
  ACanvas.Brush.Color := $00D0C8C0;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(BadgeR.Left, BadgeR.Top, BadgeR.Right, BadgeR.Bottom, 6, 6);

  // Text
  ACanvas.Font.Color := clWhite;
  ACanvas.Brush.Style := bsClear;
  DrawText(ACanvas.Handle, PChar(S), -1, BadgeR,
    DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);
  ACanvas.Pen.Style := psSolid;

  // Línia horitzontal a la dreta del badge
  ACanvas.Pen.Color := $00D0C8C0;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := 1;
  ACanvas.MoveTo(BadgeR.Right + 6, LineY);
  ACanvas.LineTo(X2, LineY);
end;

function TCentreColumnControl.CardIdxAtPoint(const CentreId: Integer;
  const Y: Integer): Integer;
var
  L: TList<Integer>;
  I, CardY, SY: Integer;
begin
  Result := -1;
  if not FAssignments.TryGetValue(CentreId, L) then Exit;
  SY := ColScrollY(CentreId);
  for I := 0 to L.Count - 1 do
  begin
    CardY := CardsTop + CardYOffset(CentreId, I) - SY;
    if (Y >= CardY) and (Y < CardY + CARD_H) then
      Exit(I);
  end;
end;

function TCentreColumnControl.InsertIdxAtY(const CentreId: Integer;
  const Y: Integer): Integer;
var
  L: TList<Integer>;
  I, CardY, SY: Integer;
begin
  if not FAssignments.TryGetValue(CentreId, L) then
    Exit(0);
  SY := ColScrollY(CentreId);
  for I := 0 to L.Count - 1 do
  begin
    CardY := CardsTop + CardYOffset(CentreId, I) - SY + CARD_H div 2;
    if Y < CardY then
      Exit(I);
  end;
  Result := L.Count;
end;

procedure TCentreColumnControl.UpdateDropTarget(const ScreenPt: TPoint);
var
  LocalPt: TPoint;
  CId, Cap, Cnt: Integer;
begin
  LocalPt := ScreenToClient(ScreenPt);
  CId := CentreIdAtX(LocalPt.X);
  if CId < 0 then
  begin
    ClearDropTarget;
    Exit;
  end;

  // Comprobar capacidad por horas o por slots
  var WorkMin: Double := ColWorkingMinutes(CId);
  if WorkMin > 0 then
  begin
    // No bloquejar el drop per hores — l'usuari decideix (es mostra l'avís visual)
  end
  else
  begin
    Cap := ColCapacity(CId);
    Cnt := ColCountForCentre(CId);
    if (Cap > 0) and (Cnt >= Cap) then
    begin
      ClearDropTarget;
      Exit;
    end;
  end;

  FDropActive := True;
  FDropTargetCentreId := CId;
  FDropTargetIdx := InsertIdxAtY(CId, LocalPt.Y);
  Invalidate;
end;

procedure TCentreColumnControl.ClearDropTarget;
begin
  if FDropActive then
  begin
    FDropActive := False;
    FDropTargetCentreId := -1;
    FDropTargetIdx := -1;
    Invalidate;
  end;
end;

procedure TCentreColumnControl.BeginDragContext(const ADataIds: TArray<Integer>);
var
  I, J, K, CId, Cap, Cnt: Integer;
  D: TNodeData;
  Permitido: Boolean;
  WorkMin, UsedMin, TotalDurMin: Double;
  Status: Integer;
begin
  FDragDropStatus.Clear;
  FDragContextActive := True;

  // Calcular duració total dels items arrossegats
  TotalDurMin := 0;
  for K := 0 to High(ADataIds) do
    if FNodeRepo.TryGetById(ADataIds[K], D) then
      TotalDurMin := TotalDurMin + D.DurationMin;

  for I := 0 to High(FCentres) do
  begin
    if not FCentres[I].Visible then Continue;
    CId := FCentres[I].Id;
    if CId < 0 then Continue;

    // Per defecte: ok
    Status := 1;

    // Comprovar centres permesos (usem el primer DataId com a referència)
    if (Length(ADataIds) > 0) and FNodeRepo.TryGetById(ADataIds[0], D) then
    begin
      if (Length(D.CentresPermesos) > 0) and not D.LibreMoviment then
      begin
        Permitido := False;
        for J := 0 to High(D.CentresPermesos) do
          if D.CentresPermesos[J] = CId then
          begin
            Permitido := True;
            Break;
          end;
        if not Permitido then
          Status := 2;  // no permès
      end;
    end;

    // Comprovar capacitat (només si encara és ok)
    if Status = 1 then
    begin
      WorkMin := ColWorkingMinutes(CId);
      if WorkMin > 0 then
      begin
        UsedMin := ColTotalMinutes(CId);
        if (UsedMin + TotalDurMin) > WorkMin then
          Status := 2;  // sense capacitat
      end
      else
      begin
        Cap := ColCapacity(CId);
        Cnt := ColCountForCentre(CId);
        if (Cap > 0) and (Cnt + Length(ADataIds) > Cap) then
          Status := 2;
      end;
    end;

    FDragDropStatus.AddOrSetValue(CId, Status);
  end;

  Invalidate;
end;

procedure TCentreColumnControl.EndDragContext;
begin
  if FDragContextActive then
  begin
    FDragContextActive := False;
    FDragDropStatus.Clear;
    Invalidate;
  end;
end;

function TCentreColumnControl.IsOnHScrollbar(const Y: Integer): Boolean;
begin
  Result := (Y >= ClientHeight - HSCROLLBAR_H) and (MaxScrollX > 0);
end;

{ --- Drawing --- }

procedure TCentreColumnControl.DrawColumn(const ACanvas: TCanvas;
  const ColIdx: Integer; const CX: Integer);
var
  I, CentreId, Cap, Cnt, SY, CardY, VisIdx: Integer;
  ColR, HeaderR, R, ClipR: TRect;
  L: TList<Integer>;
  S: string;
  IsDropTarget: Boolean;
  SaveDC: Integer;
begin
  CentreId := -1;
  Cap := 0;
  Cnt := 0;
  L := nil;
  VisIdx := 0;
  for I := 0 to High(FCentres) do
  begin
    if not FCentres[I].Visible then Continue;
    if FCentres[I].Id < 0 then Continue;
    if not IsCentreVisible(FCentres[I].Id) then Continue;
    if VisIdx = ColIdx then
    begin
      CentreId := FCentres[I].Id;
      Break;
    end;
    Inc(VisIdx);
  end;
  if CentreId < 0 then Exit;

  IsDropTarget := FDropActive and (FDropTargetCentreId = CentreId);

  // Fondo columna amb feedback de drag
  ColR := Rect(CX, 0, CX + COL_WIDTH, ClientHeight - HSCROLLBAR_H);
  var DropStatus: Integer := 0;
  if FDragContextActive then
    FDragDropStatus.TryGetValue(CentreId, DropStatus);

  if IsDropTarget then
  begin
    ACanvas.Brush.Color := $00F0FFF0;  // verd suau quan és el target actiu
    ACanvas.Pen.Color := $0040B040;
    ACanvas.Pen.Width := 2;
  end
  else if DropStatus = 1 then
  begin
    ACanvas.Brush.Color := $00F4FFF4;  // verd molt suau
    ACanvas.Pen.Color := $0080D080;
  end
  else if DropStatus = 2 then
  begin
    ACanvas.Brush.Color := $00F0F0FA;  // vermell molt suau
    ACanvas.Pen.Color := $008080E0;
  end
  else
  begin
    ACanvas.Brush.Color := $00FAFAF8;
    ACanvas.Pen.Color := $00E0E0E0;
  end;
  ACanvas.RoundRect(ColR.Left, ColR.Top + 2, ColR.Right, ColR.Bottom - 2, 8, 8);
  ACanvas.Pen.Width := 1;

  // Indicador de drop de columna (línia vertical taronja a l'esquerra)
  if FColDragging and (FColDropTargetId = CentreId) then
  begin
    ACanvas.Pen.Color := $00E89040;
    ACanvas.Pen.Width := 3;
    ACanvas.Pen.Style := psSolid;
    ACanvas.MoveTo(CX - 3, 4);
    ACanvas.LineTo(CX - 3, ClientHeight - HSCROLLBAR_H - 4);
    ACanvas.Pen.Width := 1;
  end;

  // Header
  HeaderR := Rect(CX, 2, CX + COL_WIDTH, HEADER_H);
  ACanvas.Brush.Color := $00F0EEEA;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(HeaderR.Left + 1, HeaderR.Top, HeaderR.Right - 1, HeaderR.Bottom, 8, 8);
  ACanvas.Pen.Style := psSolid;

  // Nombre centro
  for I := 0 to High(FCentres) do
    if FCentres[I].Id = CentreId then
    begin
      ACanvas.Font.Size := 10;
      ACanvas.Font.Style := [fsBold];
      ACanvas.Font.Color := $00444444;
      ACanvas.Brush.Style := bsClear;
      R := Rect(CX + 10, 6, CX + COL_WIDTH - 60, 24);
      DrawText(ACanvas.Handle, PChar(FCentres[I].Titulo), -1, R,
        DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);

      // Subtítulo
      ACanvas.Font.Size := 8;
      ACanvas.Font.Style := [];
      ACanvas.Font.Color := $00888888;
      R := Rect(CX + 10, 24, CX + COL_WIDTH - 60, 38);
      DrawText(ACanvas.Handle, PChar(FCentres[I].Subtitulo), -1, R,
        DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
      Break;
    end;

  // Botó "..." opcions del centre (esquina superior derecha, sota el comptador)
  R := Rect(CX + COL_WIDTH - 24, 28, CX + COL_WIDTH - 6, 42);
  ACanvas.Brush.Color := $00E8E4E0;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 4, 4);
  ACanvas.Font.Size := 8;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := $00888888;
  ACanvas.Brush.Style := bsClear;
  DrawText(ACanvas.Handle, '...', -1, R,
    DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);
  ACanvas.Pen.Style := psSolid;

  // Contador / capacidad (esquina superior derecha)
  Cnt := ColCountForCentre(CentreId);
  Cap := ColCapacity(CentreId);
  if Cap > 0 then
    S := Format('%d / %d', [Cnt, Cap])
  else
    S := IntToStr(Cnt);
  ACanvas.Font.Size := 9;
  ACanvas.Font.Style := [fsBold];
  if (Cap > 0) and (Cnt >= Cap) then
    ACanvas.Font.Color := $004040FF  // rojo = lleno
  else
    ACanvas.Font.Color := $00888888;
  R := Rect(CX + COL_WIDTH - 58, 8, CX + COL_WIDTH - 6, 24);
  DrawText(ACanvas.Handle, PChar(S), -1, R,
    DT_SINGLELINE or DT_RIGHT or DT_NOPREFIX);

  // Resumen horas + capacitat + operaris (fila inferior del header)
  var TotalMin: Double := ColTotalMinutes(CentreId);
  var WorkMin: Double := ColWorkingMinutes(CentreId);
  ACanvas.Font.Size := 7;
  ACanvas.Font.Style := [];

  if (WorkMin > 0) then
  begin
    var PctLoad: Double := (TotalMin / WorkMin) * 100;
    S := Format('%.1f / %.1f h (%.0f%%)', [TotalMin / 60, WorkMin / 60, PctLoad]);
    if PctLoad >= 100 then
      ACanvas.Font.Color := $004040FF  // vermell: sobrecarregat
    else if PctLoad >= 80 then
      ACanvas.Font.Color := $000080FF  // taronja: quasi ple
    else
      ACanvas.Font.Color := $00999999;
  end
  else
  begin
    ACanvas.Font.Color := $00999999;
    if TotalMin >= 60 then
      S := Format('%.1f h', [TotalMin / 60])
    else if TotalMin > 0 then
      S := Format('%.0f min', [TotalMin])
    else
      S := 'Sin carga';
  end;

  // Operaris totals del centre
  if (FOperariosRepo <> nil) and FAssignments.TryGetValue(CentreId, L) then
  begin
    var TotalOpNec: Integer := 0;
    var TotalOpAssig: Integer := 0;
    var D2: TNodeData;
    var J: Integer;
    for J := 0 to L.Count - 1 do
    begin
      if FNodeRepo.TryGetById(L[J], D2) then
      begin
        TotalOpNec := TotalOpNec + D2.OperariosNecesarios;
        TotalOpAssig := TotalOpAssig + GetOperariosAssignats(FOperariosRepo, L[J]);
      end;
    end;
    if TotalOpNec > 0 then
      S := S + Format('  |  %d/%d op.', [TotalOpAssig, TotalOpNec]);
  end;

  R := Rect(CX + 10, 40, CX + COL_WIDTH - 6, 54);
  DrawText(ACanvas.Handle, PChar(S), -1, R,
    DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);

  // Barra de capacidad
  R := Rect(CX + 6, HEADER_H + 2, CX + COL_WIDTH - 6, HEADER_H + 2 + CAP_BAR_H);
  DrawCapacityBar(ACanvas, CentreId, R);

  // Cards — clip region para que no invadan el header
  if not FAssignments.TryGetValue(CentreId, L) then Exit;
  SY := ColScrollY(CentreId);

  ClipR := Rect(CX, CardsTop, CX + COL_WIDTH, ClientHeight - HSCROLLBAR_H);
  SaveDC := Winapi.Windows.SaveDC(ACanvas.Handle);
  try
    IntersectClipRect(ACanvas.Handle, ClipR.Left, ClipR.Top, ClipR.Right, ClipR.Bottom);

    var PrevDay: Integer := -1;
    var CurDay: Integer;
    var DNode: TNodeData;
    var NStart2, NEnd2: TDateTime;

    for I := 0 to L.Count - 1 do
    begin
      CardY := CardsTop + CardYOffset(CentreId, I) - SY;

      // Separador de dia
      if Assigned(FGetNodeTimes) and FNodeRepo.TryGetById(L[I], DNode) and
         FGetNodeTimes(DNode.DataId, NStart2, NEnd2) and (NStart2 > 0) then
        CurDay := Trunc(NStart2)
      else
        CurDay := -1;

      if (CurDay > 0) and (PrevDay > 0) and (CurDay <> PrevDay) then
      begin
        var SepY: Integer := CardY - DAY_SEP_H;
        if (SepY + DAY_SEP_H >= CardsTop) and (SepY < ClientHeight) then
          DrawDaySeparator(ACanvas, CX, SepY, NStart2);
      end;
      PrevDay := CurDay;

      if CardY + CARD_H < CardsTop then Continue;
      if CardY > ClientHeight then Break;

      R := Rect(CX + CARD_MARGIN, CardY, CX + COL_WIDTH - CARD_MARGIN - VSCROLLBAR_W, CardY + CARD_H);
      DrawCard(ACanvas, CentreId, I, R, (CentreId = FHoverCentreId) and (I = FHoverCardIdx));
    end;

    // Drop indicator line
    if IsDropTarget and (FDropTargetIdx >= 0) then
    begin
      var LineY: Integer;
      LineY := CardsTop + CardYOffset(CentreId, FDropTargetIdx) - SY - 2;
      ACanvas.Pen.Color := $00E89040;
      ACanvas.Pen.Width := 3;
      ACanvas.MoveTo(CX + 8, LineY);
      ACanvas.LineTo(CX + COL_WIDTH - 8, LineY);
      ACanvas.Pen.Width := 1;
    end;
  finally
    Winapi.Windows.RestoreDC(ACanvas.Handle, SaveDC);
  end;

  // Scrollbar vertical (fuera del clip)
  DrawColVScrollbar(ACanvas, CentreId, CX);
end;

procedure TCentreColumnControl.DrawCard(const ACanvas: TCanvas;
  const CentreId, Idx: Integer; const R: TRect; const IsHover: Boolean);
var
  D: TNodeData;
  L: TList<Integer>;
  BadgeR: TRect;
  DataId, DaysLeft, I: Integer;
  Vencida, Urgente: Boolean;
  CentreBkColor: TColor;
  BaseBg: TColor;
  Resolver: TCardFieldResolver;
begin
  if not FAssignments.TryGetValue(CentreId, L) then Exit;
  if (Idx < 0) or (Idx >= L.Count) then Exit;
  DataId := L[Idx];
  if not FNodeRepo.TryGetById(DataId, D) then Exit;

  // Obtenir BkColor del centre
  CentreBkColor := clWhite;
  for I := 0 to High(FCentres) do
    if FCentres[I].Id = CentreId then
    begin
      if FCentres[I].BkColor <> 0 then
        CentreBkColor := FCentres[I].BkColor;
      Break;
    end;

  // Color base: tint suau del centre (85% blanc + 15% color centre)
  if CentreBkColor <> clWhite then
    BaseBg := BlendColor(clWhite, CentreBkColor, 38)
  else
    BaseBg := clWhite;

  // Calcular urgencia
  Vencida := False;
  Urgente := False;
  if D.FechaEntrega > 0 then
  begin
    DaysLeft := Trunc(D.FechaEntrega - Date);
    Vencida := DaysLeft < 0;
    Urgente := (DaysLeft >= 0) and (DaysLeft <= 3);
  end;

  // Fondo y borde "naturals" — la selecció només engruixa el border,
  // sense alterar background ni color de border.
  if Vencida then
    ACanvas.Brush.Color := $00E8E0F0
  else if IsHover then
    ACanvas.Brush.Color := BlendColor(BaseBg, $00E0D8D0, 80)
  else
    ACanvas.Brush.Color := BaseBg;
  if Vencida then
    ACanvas.Pen.Color := $004040FF
  else if Urgente then
    ACanvas.Pen.Color := $000080FF
  else
    ACanvas.Pen.Color := $00E0E0E0;
  if IsSelectedItem(DataId) then
    ACanvas.Pen.Width := 3
  else
    ACanvas.Pen.Width := 1;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom,
    FCardLayout.CornerRadius, FCardLayout.CornerRadius);
  ACanvas.Pen.Width := 1;

  // Renderizar contenido con el layout configurable
  Resolver := MakeNodeDataResolver(D);
  RenderCard(ACanvas, R, FCardLayout, Resolver);

  // Indicador de dependencias pendientes (siempre visible)
  if HasPendingPredecessors(DataId, FLinks, FNodeRepo) then
  begin
    BadgeR := Rect(R.Right - 18, R.Top + 6, R.Right - 4, R.Top + 20);
    ACanvas.Brush.Color := $0000AAFF;
    ACanvas.Pen.Style := psClear;
    ACanvas.Ellipse(BadgeR.Left, BadgeR.Top, BadgeR.Right, BadgeR.Bottom);
    ACanvas.Font.Size := 7;
    ACanvas.Font.Style := [fsBold];
    ACanvas.Font.Color := clWhite;
    ACanvas.Brush.Style := bsClear;
    DrawText(ACanvas.Handle, '!', -1, BadgeR,
      DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);
    ACanvas.Pen.Style := psSolid;
  end;
end;

procedure TCentreColumnControl.DrawCapacityBar(const ACanvas: TCanvas;
  const CentreId: Integer; const R: TRect);
var
  Cap, Cnt: Integer;
  Pct: Single;
  FillR: TRect;
  WorkMin, TotalMin: Double;
begin
  // Track
  ACanvas.Brush.Color := $00E8E8E8;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 4, 4);

  // Prioritzar capacitat horària (calendari) sobre slots
  WorkMin := ColWorkingMinutes(CentreId);
  if WorkMin > 0 then
  begin
    TotalMin := ColTotalMinutes(CentreId);
    Pct := TotalMin / WorkMin;
    if Pct > 1 then Pct := 1;
  end
  else
  begin
    Cap := ColCapacity(CentreId);
    Cnt := ColCountForCentre(CentreId);
    if Cap <= 0 then
    begin
      ACanvas.Pen.Style := psSolid;
      Exit;
    end;
    Pct := Cnt / Cap;
    if Pct > 1 then Pct := 1;
  end;

  FillR := R;
  FillR.Right := FillR.Left + Max(4, Round((R.Right - R.Left) * Pct));

  if Pct >= 1 then
    ACanvas.Brush.Color := $004040FF  // ple = vermell
  else if Pct >= 0.75 then
    ACanvas.Brush.Color := $000080FF  // quasi ple = taronja
  else
    ACanvas.Brush.Color := $0040B040; // ok = verd
  ACanvas.RoundRect(FillR.Left, FillR.Top, FillR.Right, FillR.Bottom, 4, 4);
  ACanvas.Pen.Style := psSolid;
end;

procedure TCentreColumnControl.DrawDropIndicator(const ACanvas: TCanvas);
begin
  // Se dibuja dentro de DrawColumn
end;

function TCentreColumnControl.CardsTop: Integer;
begin
  Result := HEADER_H + CAP_BAR_H + 8;
end;

function TCentreColumnControl.IsOnColVScrollbar(const CentreId, LocalX, Y: Integer): Boolean;
begin
  // LocalX es la X relativa al inicio de la columna
  Result := (MaxColScrollY(CentreId) > 0) and
            (LocalX >= COL_WIDTH - VSCROLLBAR_W - 4) and
            (Y >= CardsTop);
end;

procedure TCentreColumnControl.DrawColVScrollbar(const ACanvas: TCanvas;
  const CentreId, CX: Integer);
var
  MxSY, SY: Integer;
  TrackTop, TrackBottom, TrackH: Integer;
  ContentH: Double;
  Ratio, ThumbH, ThumbY: Double;
  ThumbR: TRect;
begin
  MxSY := MaxColScrollY(CentreId);
  if MxSY <= 0 then Exit;

  SY := ColScrollY(CentreId);
  TrackTop := CardsTop;
  TrackBottom := ClientHeight - HSCROLLBAR_H - 4;
  TrackH := TrackBottom - TrackTop;
  if TrackH <= 0 then Exit;

  ContentH := TotalContentHeight(CentreId);
  if ContentH <= 0 then Exit;
  Ratio := TrackH / ContentH;
  ThumbH := Max(20, TrackH * Ratio);
  if MxSY > 0 then
    ThumbY := TrackTop + (SY / MxSY) * (TrackH - ThumbH)
  else
    ThumbY := TrackTop;

  // Thumb
  ThumbR := Rect(CX + COL_WIDTH - VSCROLLBAR_W - 2, Round(ThumbY),
                 CX + COL_WIDTH - 2, Round(ThumbY + ThumbH));
  ACanvas.Brush.Color := $00D0CEC8;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(ThumbR.Left, ThumbR.Top, ThumbR.Right, ThumbR.Bottom, 4, 4);
  ACanvas.Pen.Style := psSolid;
end;

procedure TCentreColumnControl.DrawHScrollbar(const ACanvas: TCanvas);
var
  TrackR, ThumbR: TRect;
  MxSX, Ratio, ThumbW, ThumbX: Single;
begin
  MxSX := MaxScrollX;
  if MxSX <= 0 then Exit;

  TrackR := Rect(0, ClientHeight - HSCROLLBAR_H, ClientWidth, ClientHeight);
  ACanvas.Brush.Color := $00F0EEEA;
  ACanvas.Pen.Style := psClear;
  ACanvas.FillRect(TrackR);

  Ratio := ClientWidth / ContentWidth;
  ThumbW := Max(40, TrackR.Width * Ratio);
  if MxSX > 0 then
    ThumbX := (FScrollX / MxSX) * (TrackR.Width - ThumbW)
  else
    ThumbX := 0;

  ThumbR := Rect(Round(ThumbX) + 2, TrackR.Top + 2,
                 Round(ThumbX + ThumbW) - 2, TrackR.Bottom - 2);
  ACanvas.Brush.Color := $00C0BEB8;
  ACanvas.RoundRect(ThumbR.Left, ThumbR.Top, ThumbR.Right, ThumbR.Bottom, 6, 6);
  ACanvas.Pen.Style := psSolid;
end;

procedure TCentreColumnControl.Paint;
var
  I, ColIdx, CX: Integer;
begin
  inherited;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  ColIdx := 0;
  for I := 0 to High(FCentres) do
  begin
    if not FCentres[I].Visible then Continue;
    if FCentres[I].Id < 0 then Continue;
    if not IsCentreVisible(FCentres[I].Id) then Continue;
    CX := Round(COL_GAP + ColIdx * (COL_WIDTH + COL_GAP) - FScrollX);
    if CX + COL_WIDTH >= 0 then
      if CX < ClientWidth then
        DrawColumn(Canvas, ColIdx, CX);
    Inc(ColIdx);
  end;

  DrawHScrollbar(Canvas);
end;

procedure TCentreColumnControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  CId, CardIdx, ColIdx, I, LX: Integer;
  L: TList<Integer>;
begin
  inherited;

  // No iniciar drag en doble clic
  if ssDouble in Shift then Exit;

  if Button = mbLeft then
  begin
    if IsOnHScrollbar(Y) then
    begin
      FDraggingHSB := True;
      FHSBGrabX := X;
      FHSBGrabScrollX := FScrollX;
      Exit;
    end;

    CId := CentreIdAtX(X);
    if CId >= 0 then
    begin
      // Calcular X local dentro de la columna
      ColIdx := 0;
      for I := 0 to High(FCentres) do
      begin
        if not FCentres[I].Visible then Continue;
        if FCentres[I].Id < 0 then Continue;
        if not IsCentreVisible(FCentres[I].Id) then Continue;
        if FCentres[I].Id = CId then Break;
        Inc(ColIdx);
      end;
      LX := X - Round(COL_GAP + ColIdx * (COL_WIDTH + COL_GAP) - FScrollX);

      // Scrollbar vertical tiene prioridad sobre drag
      if IsOnColVScrollbar(CId, LX, Y) then
      begin
        FDraggingVSB := True;
        FVSBCentreId := CId;
        FVSBGrabY := Y;
        FVSBGrabScrollY := ColScrollY(CId);
        MouseCapture := True;
        Exit;
      end;

      // Botó "..." del header
      if (Y >= 28) and (Y <= 42) and (LX >= COL_WIDTH - 24) and (LX <= COL_WIDTH - 6) then
      begin
        FOptionsCentreId := CId;
        if Assigned(FOnHeaderOptionsClick) then
          FOnHeaderOptionsClick(Self);
        Exit;
      end;

      // Drag del header per reordenar columnes
      if Y < HEADER_H then
      begin
        FColDragPending := True;
        FColDragCentreId := CId;
        FColDragStartPt := Point(X, Y);
        MouseCapture := True;
        Exit;
      end;

      // Iniciar drag desde card asignada
      CardIdx := CardIdxAtPoint(CId, Y);
      if CardIdx >= 0 then
      begin
        // Selección
        if FAssignments.TryGetValue(CId, L) and (CardIdx < L.Count) then
        begin
          var ClickedId := L[CardIdx];
          if ssCtrl in Shift then
          begin
            if FSelectedIds.Contains(ClickedId) then
              FSelectedIds.Remove(ClickedId)
            else
              FSelectedIds.Add(ClickedId);
            Invalidate;
          end
          else
          begin
            if not FSelectedIds.Contains(ClickedId) then
            begin
              FSelectedIds.Clear;
              FSelectedIds.Add(ClickedId);
              Invalidate;
            end;
          end;
        end;

        FDragCentreId := CId;
        FDragCardIdx := CardIdx;
        FDragStartPt := Point(X, Y);
        FDragPending := True;
        MouseCapture := True;
      end
      else
      begin
        // Clic en zona vacía de columna: limpiar selección
        if not (ssCtrl in Shift) then
        begin
          FSelectedIds.Clear;
          Invalidate;
        end;
      end;
    end;
  end
  else if Button = mbRight then
  begin
    FRightClickDataId := -1;
    CId := CentreIdAtX(X);
    if CId >= 0 then
    begin
      CardIdx := CardIdxAtPoint(CId, Y);
      if (CardIdx >= 0) and FAssignments.TryGetValue(CId, L) and
         (CardIdx < L.Count) then
        FRightClickDataId := L[CardIdx];
    end;
  end;
end;

procedure TCentreColumnControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  MxSX: Single;
  CId, NewIdx, MxSY, ColIdx, I, LX: Integer;
  TargetCId: Integer;
begin
  inherited;

  // Drag reordenació de columnes — pending threshold
  if FColDragPending and (FColDragCentreId >= 0) then
  begin
    if (Abs(X - FColDragStartPt.X) > 5) or (Abs(Y - FColDragStartPt.Y) > 5) then
    begin
      FColDragPending := False;
      FColDragging := True;
      MouseCapture := False;
      if Assigned(FOnColDragBegin) then
        FOnColDragBegin(Self);
      Exit;
    end;
  end;

  // Drag reordenació de columnes — actualitzar drop target
  if FColDragging then
    Exit;

  // VScrollbar drag
  if FDraggingVSB then
  begin
    MxSY := MaxColScrollY(FVSBCentreId);
    if MxSY > 0 then
    begin
      var VisibleH: Integer := ClientHeight - HSCROLLBAR_H - CardsTop;
      var ContentH: Double := TotalContentHeight(FVSBCentreId);
      var Ratio: Double := ContentH / VisibleH;
      SetColScrollY(FVSBCentreId, Round(FVSBGrabScrollY + (Y - FVSBGrabY) * Ratio));
      Invalidate;
    end;
    Exit;
  end;

  if FDraggingHSB then
  begin
    MxSX := MaxScrollX;
    if MxSX > 0 then
    begin
      var Ratio: Single := ContentWidth / ClientWidth;
      FScrollX := Max(0, Min(FHSBGrabScrollX + (X - FHSBGrabX) * Ratio, MxSX));
      Invalidate;
    end;
    Exit;
  end;

  // Drag threshold
  if FDragPending and (FDragCentreId >= 0) then
  begin
    if (Abs(X - FDragStartPt.X) > 5) or (Abs(Y - FDragStartPt.Y) > 5) then
    begin
      FDragPending := False;
      MouseCapture := False;
      if Assigned(FOnBeginDrag) then
        FOnBeginDrag(Self);
      Exit;
    end;
  end;

  if not FDragPending then
  begin
    // Hover + cursor
    CId := CentreIdAtX(X);
    if CId <> FHoverCentreId then
    begin
      FHoverCentreId := CId;
      FHoverCardIdx := -1;
      Invalidate;
    end;
    if CId >= 0 then
    begin
      NewIdx := CardIdxAtPoint(CId, Y);
      if NewIdx <> FHoverCardIdx then
      begin
        FHoverCardIdx := NewIdx;
        // Tooltip
        if (NewIdx >= 0) and (FNodeRepo <> nil) then
        begin
          var L2: TList<Integer>;
          var D2: TNodeData;
          if FAssignments.TryGetValue(CId, L2) and (NewIdx < L2.Count) and
             FNodeRepo.TryGetById(L2[NewIdx], D2) then
            Hint := BuildTooltipText(D2, FGetNodeTimes)
          else
            Hint := '';
        end
        else
          Hint := '';
        Application.CancelHint;
        Invalidate;
      end;
      // Cursor: default sobre scrollbar, hand sobre cards
      if NewIdx >= 0 then
      begin
        // Calcular X local en la columna
        ColIdx := 0;
        for I := 0 to High(FCentres) do
        begin
          if not FCentres[I].Visible then Continue;
          if FCentres[I].Id < 0 then Continue;
          if not IsCentreVisible(FCentres[I].Id) then Continue;
          if FCentres[I].Id = CId then Break;
          Inc(ColIdx);
        end;
        LX := X - Round(COL_GAP + ColIdx * (COL_WIDTH + COL_GAP) - FScrollX);
        if IsOnColVScrollbar(CId, LX, Y) then
          Cursor := crDefault
        else
          Cursor := crHandPoint;
      end
      else
        Cursor := crDefault;
    end
    else
      Cursor := crDefault;
  end;
end;

procedure TCentreColumnControl.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  FDraggingHSB := False;
  if FColDragPending then
  begin
    FColDragPending := False;
    MouseCapture := False;
  end;
  if FColDragging then
  begin
    // No fer res aquí — el form gestiona el drop via WndProc
  end;
  if FDraggingVSB then
  begin
    FDraggingVSB := False;
    FVSBCentreId := -1;
    MouseCapture := False;
  end;
  if FDragPending then
    MouseCapture := False;
  FDragPending := False;
  FDragCentreId := -1;
  FDragCardIdx := -1;
end;

function TCentreColumnControl.DoMouseWheel(Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint): Boolean;
var
  Pt: TPoint;
  CId: Integer;
begin
  Result := True;
  Pt := ScreenToClient(MousePos);

  if ssShift in Shift then
  begin
    // Scroll horizontal
    FScrollX := Max(0, Min(FScrollX - WheelDelta div 2, MaxScrollX));
    Invalidate;
    Exit;
  end;

  CId := CentreIdAtX(Pt.X);
  if CId >= 0 then
  begin
    SetColScrollY(CId, ColScrollY(CId) - WheelDelta div 2);
    Invalidate;
  end;
end;

procedure TCentreColumnControl.Resize;
begin
  inherited;
  FScrollX := Max(0, Min(FScrollX, MaxScrollX));
  Invalidate;
end;

procedure TCentreColumnControl.DblClick;
var
  Pt: TPoint;
  CId, CardIdx, DataId: Integer;
  L: TList<Integer>;
  D: TNodeData;
begin
  inherited;
  // Cancelar drag pendiente
  if FDragPending then
  begin
    FDragPending := False;
    FDragCentreId := -1;
    FDragCardIdx := -1;
    MouseCapture := False;
  end;
  Pt := ScreenToClient(Mouse.CursorPos);
  CId := CentreIdAtX(Pt.X);
  if CId < 0 then Exit;
  CardIdx := CardIdxAtPoint(CId, Pt.Y);
  if CardIdx < 0 then Exit;
  if not FAssignments.TryGetValue(CId, L) then Exit;
  if CardIdx >= L.Count then Exit;
  DataId := L[CardIdx];
  if (FNodeRepo <> nil) and FNodeRepo.TryGetById(DataId, D) then
    TfrmNodeInspector.Execute(D, True, FCustomFieldDefs);
end;

function TCentreColumnControl.DragDataId: Integer;
var
  L: TList<Integer>;
begin
  Result := -1;
  if (FDragCentreId < 0) or (FDragCardIdx < 0) then Exit;
  if not FAssignments.TryGetValue(FDragCentreId, L) then Exit;
  if (FDragCardIdx >= 0) and (FDragCardIdx < L.Count) then
    Result := L[FDragCardIdx];
end;

function TCentreColumnControl.DragDataIds: TArray<Integer>;
var
  DId: Integer;
begin
  if FSelectedIds.Count > 0 then
    Result := FSelectedIds.ToArray
  else
  begin
    DId := DragDataId;
    if DId >= 0 then
      Result := TArray<Integer>.Create(DId)
    else
      Result := nil;
  end;
end;

procedure TCentreColumnControl.SwapCentres(const IdA, IdB: Integer);
var
  I, IdxA, IdxB: Integer;
  Tmp: TCentreTreball;
begin
  IdxA := -1;
  IdxB := -1;
  for I := 0 to High(FCentres) do
  begin
    if FCentres[I].Id = IdA then IdxA := I;
    if FCentres[I].Id = IdB then IdxB := I;
  end;
  if (IdxA < 0) or (IdxB < 0) or (IdxA = IdxB) then Exit;
  Tmp := FCentres[IdxA];
  FCentres[IdxA] := FCentres[IdxB];
  FCentres[IdxB] := Tmp;
  Invalidate;
end;

function TCentreColumnControl.IsSelectedItem(const DataId: Integer): Boolean;
begin
  Result := FSelectedIds.Contains(DataId);
end;

procedure TCentreColumnControl.ScrollColByDelta(const CentreId: Integer; Delta: Integer);
begin
  SetColScrollY(CentreId, ColScrollY(CentreId) + Delta);
  Invalidate;
end;

procedure TCentreColumnControl.ScrollHByDelta(Delta: Integer);
begin
  FScrollX := Max(0, Min(FScrollX + Delta, MaxScrollX));
  Invalidate;
end;

{ ========================================================= }
{               TfrmFiniteCapacityPlanner                    }
{ ========================================================= }

procedure TfrmFiniteCapacityPlanner.Inicializar(
  ANodeRepo: TNodeDataRepo;
  AOperariosRepo: TOperariosRepo;
  ARuleEngine: TPlanningRuleEngine;
  ACustomFieldDefs: TCustomFieldDefs);
var
  Frm: TfrmFiniteCapacityPlanner;
  Links: TArray<TErpLink>;
  Centres: TArray<TCentreTreball>;
  Q: TADOQuery;
  L: TErpLink;
  LI: Integer;
  Iv: TAbsInterval;
begin
  Frm := Self;

  // Idempotencia: si ja s'ha inicialitzat, no fer res. Per refrescar s'ha
  // d'usar el bot\303\263 expl\303\adcit o gestionar des del Main.
  if FCentreColumns <> nil then Exit;

  // NodeTimes \303\251s un cache per al callback FGetNodeTimes; el guardem com
  // a camp perqu\303\251 viu mentre viu el form.
  if FNodeTimesCache = nil then
    FNodeTimesCache := TDictionary<Integer, TAbsInterval>.Create
  else
    FNodeTimesCache.Clear;
  // Omplir el repo de NodeData amb el projecte actiu
  if DMPlanner <> nil then
    DMPlanner.LoadNodes;

  // Obtenir centres del repo central
  if (DMPlanner <> nil) and (DMPlanner.CentresRepo <> nil) then
    Centres := DMPlanner.CentresRepo.GetAll
  else
    Centres := nil;

  // Carregar Start/End dels nodes des de BD per al projecte actiu
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT NodeId, FechaInicio, FechaFin FROM FS_PL_Node ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa AND ProjectId = :ProjectId';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('ProjectId').Value := DMPlanner.CurrentProjectId;
    Q.Open;
    while not Q.Eof do
    begin
      if Q.FieldByName('FechaInicio').IsNull then
        Iv.S := 0
      else
        Iv.S := Q.FieldByName('FechaInicio').AsDateTime;
      if Q.FieldByName('FechaFin').IsNull then
        Iv.E := 0
      else
        Iv.E := Q.FieldByName('FechaFin').AsDateTime;
      FNodeTimesCache.AddOrSetValue(Q.FieldByName('NodeId').AsInteger, Iv);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  // Carregar Links del projecte des de BD
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT FromNodeId, ToNodeId, TipoLink, ' +
      '  ISNULL(PorcentajeDependencia, 100) AS PorcentajeDependencia ' +
      'FROM FS_PL_Dependency ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa AND ProjectId = :ProjectId';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('ProjectId').Value := DMPlanner.CurrentProjectId;
    Q.Open;
    SetLength(Links, Q.RecordCount);
    LI := 0;
    while not Q.Eof do
    begin
      L.FromNodeId := Q.FieldByName('FromNodeId').AsInteger;
      L.ToNodeId := Q.FieldByName('ToNodeId').AsInteger;
      if Q.FieldByName('TipoLink').IsNull then
        L.LinkType := TLinkType(0)
      else
        L.LinkType := TLinkType(Q.FieldByName('TipoLink').AsInteger);
      L.PorcentajeDependencia := Q.FieldByName('PorcentajeDependencia').AsFloat;
      Links[LI] := L;
      Inc(LI);
      Q.Next;
    end;
    SetLength(Links, LI);
  finally
    Q.Free;
  end;

    Frm.FNodeRepo := ANodeRepo;
    Frm.FOperariosRepo := AOperariosRepo;
    Frm.FCentres := Centres;
    Frm.FLinks := Links;
    Frm.FGetNodeTimes :=
      function(const DataId: Integer; out AStart, AEnd: TDateTime): Boolean
      var
        It: TAbsInterval;
      begin
        if FNodeTimesCache.TryGetValue(DataId, It) then
        begin
          AStart := It.S;
          AEnd := It.E;
          Result := True;
        end
        else
        begin
          AStart := 0;
          AEnd := 0;
          Result := False;
        end;
      end;
    Frm.FGetCalendar :=
      function(const CentreId: Integer): TCentreCalendar
      begin
        if (DMPlanner <> nil) and (DMPlanner.CentresRepo <> nil) then
          Result := DMPlanner.CentresRepo.GetCalendarFor(CentreId)
        else
          Result := nil;
      end;
    Frm.FRuleEngine := ARuleEngine;
    Frm.FCustomFieldDefs := ACustomFieldDefs;

    // Tag per als labels d'undo/redo (referència a l'icon per canviar color
    // al UpdateUndoRedoButtons).
    FBtnUndo.Tag := NativeInt(LblUndoIcon);
    FBtnRedo.Tag := NativeInt(LblRedoIcon);

    // Data inicial del selector de rang.
    FDtpStart.Date := Date;

    BuildOptionsPopup;
    BuildFiltrosBtn;
    BuildCentrePopup;
    BuildCentreHeaderPopup;

    // Inicializar todos los centros como visibles
    for var CI := 0 to High(Centres) do
      if Centres[CI].Visible and (Centres[CI].Id >= 0) then
        Frm.FVisibleCentreIds.Add(Centres[CI].Id);

    // Poblar el TcxCheckComboBox de filtro de centros
    Frm.PopularCentrosCombo;

    // Layouts d'usuari
    Frm.FLayoutRepo := TFCPLayoutRepo.Create(
      DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
    Frm.LoadLayouts;

    // Pending list
    Frm.FPendingList := TPendingListControl.Create(Frm);
    Frm.FPendingList.Parent := Frm.pnlPending;
    Frm.FPendingList.Align := alClient;
    Frm.FPendingList.OnBeginDrag := Frm.OnPendingBeginDrag;
    Frm.FPendingList.FLinks := Links;
    // FGetNodeTimes s'assigna més avall via wrapper
    Frm.FPendingList.FOperariosRepo := AOperariosRepo;
    Frm.FPendingList.FCustomFieldDefs := ACustomFieldDefs;

    // Centre columns
    Frm.FCentreColumns := TCentreColumnControl.Create(Frm);
    Frm.FCentreColumns.Parent := Frm.pnlCentres;
    Frm.FCentreColumns.Align := alClient;
    Frm.FCentreColumns.SetData(ANodeRepo, Centres);
    Frm.FCentreColumns.OnBeginDrag := Frm.OnCentreBeginDrag;
    Frm.FCentreColumns.FLinks := Links;
    // FGetNodeTimes s'assigna més avall via wrapper
    Frm.FCentreColumns.FGetCalendar := Frm.FGetCalendar;
    Frm.FCentreColumns.FOperariosRepo := AOperariosRepo;
    Frm.FCentreColumns.FCustomFieldDefs := ACustomFieldDefs;
    Frm.FCentreColumns.PopupMenu := Frm.FCentrePopup;
    Frm.FCentreColumns.OnHeaderOptionsClick := Frm.OnCentreHeaderOptionsClick;
    Frm.FCentreColumns.OnColDragBegin := Frm.OnColDragBegin;

    // Inicialitzar rang de planificació al control
    var PS, PE: TDateTime;
    Frm.GetPlanningDates(PS, PE);
    Frm.FCentreColumns.FPlanningStart := PS;
    Frm.FCentreColumns.FPlanningEnd := PE;

    // Wrapper GetNodeTimes que consulta dates calculades primer
    Frm.FGetNodeTimesCalc :=
      function(const DataId: Integer; out AStart, AEnd: TDateTime): Boolean
      var
        Iv: TAbsInterval;
      begin
        if Frm.FCalculatedTimes.TryGetValue(DataId, Iv) then
        begin
          AStart := Iv.S;
          AEnd := Iv.E;
          Result := True;
        end
        else if Assigned(Frm.FGetNodeTimes) then
          Result := Frm.FGetNodeTimes(DataId, AStart, AEnd)
        else
        begin
          AStart := 0;
          AEnd := 0;
          Result := False;
        end;
      end;
    Frm.FPendingList.FGetNodeTimes := Frm.FGetNodeTimesCalc;
    Frm.FCentreColumns.FGetNodeTimes := Frm.FGetNodeTimesCalc;

    // Pre-poblar asignaciones con los nodos ya planificados del proyecto.
    // Sin esto, todos los nodos aparecen como pendientes aunque ya tengan
    // CenterId asignado en FS_PL_Node.
    if (DMPlanner <> nil) and (DMPlanner.NodesRepo <> nil) then
    begin
      var ExistingNodes := DMPlanner.NodesRepo.GetAll;
      for var NI := 0 to High(ExistingNodes) do
        if (ExistingNodes[NI].CentreId >= 0) and (ExistingNodes[NI].DataId > 0) then
        begin
          Frm.FCentreColumns.AssignItem(
            ExistingNodes[NI].DataId, ExistingNodes[NI].CentreId);
          Frm.FInitiallyAssignedDataIds.Add(ExistingNodes[NI].DataId);
        end;
    end;

    // Cargar Backlog (Raw_Item OPs sin nodo) como pendientes sintéticos.
    Frm.LoadBacklogPending;

    Frm.BuildPendingList;
    Frm.UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.FormCreate(Sender: TObject);
begin
  FInterDragging := False;
  FColDragging := False;
  FColGhostForm := nil;
  FInterDragDataId := -1;
  FInterDragDataIds := nil;
  FDragFromCentre := False;
  FPopupDataId := -1;
  FSearchFilter := '';
  FSortMode := smPrioridad;
  FEstadoFilter := [nePendiente, neEnCurso, neBloqueado];
  FOperacionFilter := TStringList.Create;
  FOperacionFilter.CaseSensitive := False;
  FOperacionFilter.Sorted := True;
  FOperacionFilter.Duplicates := dupIgnore;
  FUndoStack := TList<TFCPAction>.Create;
  FRedoStack := TList<TFCPAction>.Create;
  FPlanningRange := pr1Setmana;
  FPlanningStart := Date;
  FCalculatedTimes := TDictionary<Integer, TAbsInterval>.Create;
  FBacklogRawItemIdByDataId := TDictionary<Integer, Integer>.Create;
  FInitiallyAssignedDataIds := TList<Integer>.Create;
  FAutoScrollTimer := TTimer.Create(Self);
  FAutoScrollTimer.Interval := 50;
  FAutoScrollTimer.Enabled := False;
  FAutoScrollTimer.OnTimer := OnAutoScrollTimer;
  FGhostBmp := TBitmap.Create;
  FGhostBmp.SetSize(240, 60);
  FGhostForm := nil;
  FVisibleCentreIds := TList<Integer>.Create;
  FUpdatingCentros := False;
  FCurrentLayoutId := -1;
  FUpdatingLayouts := False;
  FLayoutRepo := nil;
end;

procedure TfrmFiniteCapacityPlanner.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FColGhostForm);
  FreeAndNil(FGhostForm);
  FGhostBmp.Free;
  FVisibleCentreIds.Free;
  FUndoStack.Free;
  FRedoStack.Free;
  FCalculatedTimes.Free;
  FBacklogRawItemIdByDataId.Free;
  FInitiallyAssignedDataIds.Free;
  FNodeTimesCache.Free;
  FOperacionFilter.Free;
  FreeAndNil(FLayoutRepo);
end;

procedure TfrmFiniteCapacityPlanner.FormResize(Sender: TObject);
begin
  Invalidate;
end;

{ --- Drag cross-control --- }

procedure TfrmFiniteCapacityPlanner.OnPendingBeginDrag(Sender: TObject);
var
  DataId: Integer;
  Pt: TPoint;
begin
  DataId := FPendingList.DragDataId;
  if DataId < 0 then Exit;

  FInterDragging := True;
  FInterDragDataId := DataId;
  FInterDragDataIds := FPendingList.DragDataIds;
  FDragFromCentre := False;
  FCentreColumns.BeginDragContext(FInterDragDataIds);
  DrawGhostCard(DataId);

  // Crear finestra overlay transparent per mostrar el ghost card per sobre de tot
  FGhostForm := TForm.CreateNew(Self);
  FGhostForm.BorderStyle := bsNone;
  FGhostForm.FormStyle := fsStayOnTop;
  FGhostForm.AlphaBlend := True;
  FGhostForm.AlphaBlendValue := 180;
  FGhostForm.Color := clWhite;
  FGhostForm.Width := FGhostBmp.Width;
  FGhostForm.Height := FGhostBmp.Height;
  FGhostForm.Visible := False;

  // Posicionar al cursor
  GetCursorPos(Pt);
  FGhostForm.Left := Pt.X - FGhostBmp.Width div 2;
  FGhostForm.Top := Pt.Y - 10;

  // Pintar el bitmap al form
  var Img := TImage.Create(FGhostForm);
  Img.Parent := FGhostForm;
  Img.Align := alClient;
  Img.Picture.Bitmap.Assign(FGhostBmp);
  Img.Stretch := False;

  ShowWindow(FGhostForm.Handle, SW_SHOWNOACTIVATE);
  FGhostForm.Visible := True;

  // Capturar el mouse a nivell de form per rebre TOTS els missatges
  SetCapture(Handle);
  FAutoScrollTimer.Enabled := True;
end;

procedure TfrmFiniteCapacityPlanner.OnCentreBeginDrag(Sender: TObject);
var
  DataId: Integer;
  Pt: TPoint;
begin
  DataId := FCentreColumns.DragDataId;
  if DataId < 0 then Exit;

  FInterDragging := True;
  FInterDragDataId := DataId;
  FInterDragDataIds := FCentreColumns.DragDataIds;
  FDragFromCentre := True;
  FCentreColumns.BeginDragContext(FInterDragDataIds);
  DrawGhostCard(DataId);

  FGhostForm := TForm.CreateNew(Self);
  FGhostForm.BorderStyle := bsNone;
  FGhostForm.FormStyle := fsStayOnTop;
  FGhostForm.AlphaBlend := True;
  FGhostForm.AlphaBlendValue := 180;
  FGhostForm.Color := clWhite;
  FGhostForm.Width := FGhostBmp.Width;
  FGhostForm.Height := FGhostBmp.Height;
  FGhostForm.Visible := False;

  GetCursorPos(Pt);
  FGhostForm.Left := Pt.X - FGhostBmp.Width div 2;
  FGhostForm.Top := Pt.Y - 10;

  var Img := TImage.Create(FGhostForm);
  Img.Parent := FGhostForm;
  Img.Align := alClient;
  Img.Picture.Bitmap.Assign(FGhostBmp);
  Img.Stretch := False;

  ShowWindow(FGhostForm.Handle, SW_SHOWNOACTIVATE);
  FGhostForm.Visible := True;

  SetCapture(Handle);
  FAutoScrollTimer.Enabled := True;
end;

procedure TfrmFiniteCapacityPlanner.WndProc(var Message: TMessage);
var
  Pt: TPoint;
begin
  case Message.Msg of
    WM_MOUSEMOVE:
    begin
      if FColDragging then
      begin
        GetCursorPos(Pt);
        DoColDragMove(Pt);
        Message.Result := 0;
        Exit;
      end;
      if FInterDragging then
      begin
        GetCursorPos(Pt);
        DoDragMove(Pt);
        Message.Result := 0;
        Exit;
      end;
    end;

    WM_LBUTTONUP:
    begin
      if FColDragging then
      begin
        GetCursorPos(Pt);
        DoColDragEnd(Pt);
        Message.Result := 0;
        Exit;
      end;
      if FInterDragging then
      begin
        GetCursorPos(Pt);
        ReleaseCapture;
        DoDragEnd(Pt);
        Message.Result := 0;
        Exit;
      end;
    end;
  end;

  inherited;
end;

procedure TfrmFiniteCapacityPlanner.DoDragMove(const ScreenPt: TPoint);
begin
  // Actualitzar drop target a les columnes
  FCentreColumns.UpdateDropTarget(ScreenPt);

  // Moure la finestra ghost
  if FGhostForm <> nil then
  begin
    FGhostForm.Left := ScreenPt.X - FGhostBmp.Width div 2;
    FGhostForm.Top := ScreenPt.Y - 10;
  end;
end;

procedure TfrmFiniteCapacityPlanner.DoDragEnd(const ScreenPt: TPoint);
begin
  FAutoScrollTimer.Enabled := False;

  // Destruir ghost form
  if FGhostForm <> nil then
  begin
    FGhostForm.Free;
    FGhostForm := nil;
  end;

  HandleDrop(ScreenPt);
  FInterDragging := False;
  FInterDragDataId := -1;
  FInterDragDataIds := nil;
  FCentreColumns.ClearDropTarget;
  FCentreColumns.EndDragContext;
  FPendingList.Invalidate;
  FCentreColumns.Invalidate;
end;

procedure TfrmFiniteCapacityPlanner.DrawGhostCard(const DataId: Integer);
var
  D: TNodeData;
  R, BadgeR, TR: TRect;
  S: string;
  C: TCanvas;
begin
  if not FNodeRepo.TryGetById(DataId, D) then Exit;

  C := FGhostBmp.Canvas;
  R := Rect(0, 0, FGhostBmp.Width, FGhostBmp.Height);

  C.Brush.Color := clWhite;
  C.Pen.Color := $00E89040;
  C.Pen.Width := 2;
  C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
  C.Pen.Width := 1;

  // Prioridad badge
  BadgeR := Rect(6, 6, 46, 22);
  C.Brush.Color := PrioridadColor(D.Prioridad);
  C.Pen.Style := psClear;
  C.RoundRect(BadgeR.Left, BadgeR.Top, BadgeR.Right, BadgeR.Bottom, 4, 4);
  C.Font.Size := 7;
  C.Font.Style := [fsBold];
  C.Font.Color := clWhite;
  C.Brush.Style := bsClear;
  DrawText(C.Handle, PChar(PrioridadText(D.Prioridad)), -1, BadgeR,
    DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);
  C.Pen.Style := psSolid;

  // OF
  C.Font.Size := 9;
  C.Font.Style := [fsBold];
  C.Font.Color := $00333333;
  S := 'OF ' + IntToStr(D.NumeroOrdenFabricacion);
  if D.Operacion <> '' then S := S + ' - ' + D.Operacion;
  TR := Rect(52, 4, FGhostBmp.Width - 6, 22);
  DrawText(C.Handle, PChar(S), -1, TR,
    DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);

  // Artículo
  C.Font.Size := 8;
  C.Font.Style := [];
  C.Font.Color := $00777777;
  TR := Rect(6, 28, FGhostBmp.Width - 6, 44);
  DrawText(C.Handle, PChar(D.CodigoArticulo + ' ' + D.DescripcionArticulo), -1, TR,
    DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);

  // Badge de cantidad si multi-selección
  if Length(FInterDragDataIds) > 1 then
  begin
    BadgeR := Rect(FGhostBmp.Width - 28, 0, FGhostBmp.Width, 22);
    C.Brush.Color := $00E89040;
    C.Pen.Style := psClear;
    C.Ellipse(BadgeR.Left, BadgeR.Top, BadgeR.Right, BadgeR.Bottom);
    C.Font.Size := 8;
    C.Font.Style := [fsBold];
    C.Font.Color := clWhite;
    C.Brush.Style := bsClear;
    DrawText(C.Handle, PChar(IntToStr(Length(FInterDragDataIds))), -1, BadgeR,
      DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);
    C.Pen.Style := psSolid;
  end;
end;

function MatchesSearch(const D: TNodeData; const Filter: string): Boolean;
var
  UF: string;
begin
  if Filter = '' then Exit(True);
  UF := AnsiUpperCase(Filter);
  Result :=
    (Pos(UF, AnsiUpperCase(IntToStr(D.NumeroOrdenFabricacion))) > 0) or
    (Pos(UF, AnsiUpperCase(D.CodigoArticulo)) > 0) or
    (Pos(UF, AnsiUpperCase(D.DescripcionArticulo)) > 0) or
    (Pos(UF, AnsiUpperCase(D.Operacion)) > 0) or
    (Pos(UF, AnsiUpperCase(D.CodigoCliente)) > 0) or
    (Pos(UF, AnsiUpperCase(D.NumeroTrabajo)) > 0);
end;

procedure TfrmFiniteCapacityPlanner.BuildPendingList;
var
  AllData: TArray<TNodeData>;
  Ids: TList<Integer>;
  I: Integer;
  D: TNodeData;
begin
  if FNodeRepo = nil then Exit;

  Ids := TList<Integer>.Create;
  try
    AllData := FNodeRepo.GetAllData;
    for I := 0 to High(AllData) do
    begin
      D := AllData[I];
      if not (D.Estado in FEstadoFilter) then Continue;
      // Items sense Operacion (cadena buida) no es filtren per Operacion.
      if (FOperacionFilter.Count > 0) and (D.Operacion <> '') and
         (FOperacionFilter.IndexOf(D.Operacion) < 0) then Continue;
      if (FCentreColumns <> nil) and FCentreColumns.IsAssigned(D.DataId) then
        Continue;
      if not MatchesSearch(D, FSearchFilter) then
        Continue;
      Ids.Add(D.DataId);
    end;


    Ids.Sort(TComparer<Integer>.Construct(
      function(const A, B: Integer): Integer
      var DA, DB: TNodeData;
      begin
        if not FNodeRepo.TryGetById(A, DA) then DA.Prioridad := 99;
        if not FNodeRepo.TryGetById(B, DB) then DB.Prioridad := 99;
        case FSortMode of
          smFechaEntrega:
          begin
            if DA.FechaEntrega < DB.FechaEntrega then Result := -1
            else if DA.FechaEntrega > DB.FechaEntrega then Result := 1
            else Result := DA.Prioridad - DB.Prioridad;
          end;
          smDuracion:
          begin
            if DA.DurationMin < DB.DurationMin then Result := -1
            else if DA.DurationMin > DB.DurationMin then Result := 1
            else Result := DA.Prioridad - DB.Prioridad;
          end;
          smArticulo:
          begin
            Result := CompareText(DA.CodigoArticulo, DB.CodigoArticulo);
            if Result = 0 then
              Result := DA.Prioridad - DB.Prioridad;
          end;
        else // smPrioridad
          Result := DA.Prioridad - DB.Prioridad;
          if Result = 0 then
          begin
            if DA.FechaEntrega < DB.FechaEntrega then Result := -1
            else if DA.FechaEntrega > DB.FechaEntrega then Result := 1;
          end;
        end;
      end));

    FPendingList.SetData(FNodeRepo, Ids.ToArray);
  finally
    Ids.Free;
  end;
end;

procedure TfrmFiniteCapacityPlanner.UpdatePendingCount;
begin
  RecalcAllCentreTimes;
  UpdateFooter;
end;

procedure TfrmFiniteCapacityPlanner.UpdateFooter;
var
  AllData: TArray<TNodeData>;
  I, TotalOTs, PendingOTs, AssignedOTs: Integer;
  TotalMinPending, TotalMinAssigned: Double;
  D: TNodeData;
  Pair: TPair<Integer, TList<Integer>>;
  TotalCap, TotalUsed: Integer;
  PctCap: Double;
begin
  if FNodeRepo = nil then Exit;

  TotalOTs := 0;
  PendingOTs := 0;
  AssignedOTs := 0;
  TotalMinPending := 0;
  TotalMinAssigned := 0;

  AllData := FNodeRepo.GetAllData;
  for I := 0 to High(AllData) do
  begin
    D := AllData[I];
    if D.Estado = neFinalizado then Continue;
    Inc(TotalOTs);
    if (FCentreColumns <> nil) and FCentreColumns.IsAssigned(D.DataId) then
    begin
      Inc(AssignedOTs);
      TotalMinAssigned := TotalMinAssigned + D.DurationMin;
    end
    else
    begin
      Inc(PendingOTs);
      TotalMinPending := TotalMinPending + D.DurationMin;
    end;
  end;

  lblFooterPending.Caption := Format('Pendientes: %d  (%.1f h)', [PendingOTs, TotalMinPending / 60]);
  lblFooterAssigned.Caption := Format('Asignadas: %d  (%.1f h)', [AssignedOTs, TotalMinAssigned / 60]);
  lblFooterHours.Caption := Format('Total: %d OTs  (%.1f h)', [TotalOTs, (TotalMinPending + TotalMinAssigned) / 60]);

  // Capacitat horària global
  var TotalWorkMin: Double := 0;
  if (FCentreColumns <> nil) and Assigned(FGetCalendar) then
  begin
    for I := 0 to High(FCentres) do
    begin
      if not FCentres[I].Visible then Continue;
      if FCentres[I].Id < 0 then Continue;
      TotalWorkMin := TotalWorkMin + FCentreColumns.ColWorkingMinutes(FCentres[I].Id);
    end;
  end;

  if TotalWorkMin > 0 then
  begin
    PctCap := (TotalMinAssigned / TotalWorkMin) * 100;
    lblFooterCapacity.Caption := Format('Capacidad: %.1f / %.1f h (%.0f%%)',
      [TotalMinAssigned / 60, TotalWorkMin / 60, PctCap]);
  end
  else
  begin
    TotalCap := 0;
    TotalUsed := 0;
    if FCentreColumns <> nil then
      for I := 0 to High(FCentres) do
      begin
        if not FCentres[I].Visible then Continue;
        if FCentres[I].Id < 0 then Continue;
        TotalUsed := TotalUsed + FCentreColumns.ColCountForCentre(FCentres[I].Id);
        if FCentres[I].MaxLaneCount > 0 then
          TotalCap := TotalCap + FCentres[I].MaxLaneCount;
      end;
    if TotalCap > 0 then
      lblFooterCapacity.Caption := Format('Capacidad: %d/%d (%.0f%%)',
        [TotalUsed, TotalCap, (TotalUsed / TotalCap) * 100])
    else
      lblFooterCapacity.Caption := Format('Slots ocupados: %d', [TotalUsed]);
  end;
end;

function IsCentrePermitido(const D: TNodeData; const CentreId: Integer): Boolean;
var
  I: Integer;
begin
  // Sin restricciones o libre movimiento = siempre permitido
  if D.LibreMoviment or (Length(D.CentresPermesos) = 0) then
    Exit(True);
  for I := 0 to High(D.CentresPermesos) do
    if D.CentresPermesos[I] = CentreId then
      Exit(True);
  Result := False;
end;

function CentreNombre(const ACentres: TArray<TCentreTreball>; const CentreId: Integer): string;
var
  I: Integer;
begin
  Result := IntToStr(CentreId);
  for I := 0 to High(ACentres) do
    if ACentres[I].Id = CentreId then
    begin
      Result := ACentres[I].Titulo;
      Exit;
    end;
end;

procedure TfrmFiniteCapacityPlanner.HandleDrop(const ScreenPt: TPoint);
var
  LocalPt: TPoint;
  DroppedOnPending: Boolean;
  D: TNodeData;
  TargetCentreId: Integer;
  Act: TFCPAction;
begin
  if not FInterDragging then Exit;
  if FInterDragDataId < 0 then Exit;

  // Comprobar si se soltó sobre el panel de pendientes
  LocalPt := pnlPending.ScreenToClient(ScreenPt);
  DroppedOnPending := PtInRect(pnlPending.ClientRect, LocalPt);

  if DroppedOnPending then
  begin
    Act.Kind := akUnassign;
    Act.Snapshot := TakeSnapshot;
    if Length(FInterDragDataIds) > 1 then
    begin
      var K: Integer;
      for K := 0 to High(FInterDragDataIds) do
        FCentreColumns.UnassignItem(FInterDragDataIds[K]);
    end
    else
      FCentreColumns.UnassignItem(FInterDragDataId);
    FCentreColumns.SelectedIds.Clear;
    FCentreColumns.ClearDropTarget;
    BuildPendingList;
    UpdatePendingCount;
    PushUndo(Act);
    Exit;
  end;

  // Actualitzar drop target final
  FCentreColumns.UpdateDropTarget(ScreenPt);

  if FCentreColumns.DropActive then
  begin
    TargetCentreId := FCentreColumns.DropTargetCentreId;

    // Validar centro permitido
    if FNodeRepo.TryGetById(FInterDragDataId, D) and
       not IsCentrePermitido(D, TargetCentreId) then
    begin
      if MessageDlg(
        Format('La OT %d no tiene "%s" como centro permitido.'#13#10 +
               #13#10'Desea asignarla igualmente?',
               [D.NumeroOrdenFabricacion,
                CentreNombre(FCentres, TargetCentreId)]),
        mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      begin
        FCentreColumns.ClearDropTarget;
        Exit;
      end;
    end;

    Act.Kind := akAssign;
    Act.Snapshot := TakeSnapshot;

    // Multi-selección o individual
    if Length(FInterDragDataIds) > 1 then
    begin
      var InsIdx := FCentreColumns.DropTargetIdx;
      var K: Integer;
      for K := 0 to High(FInterDragDataIds) do
      begin
        FCentreColumns.AssignItem(FInterDragDataIds[K], TargetCentreId, InsIdx);
        Inc(InsIdx);
      end;
    end
    else
      FCentreColumns.AssignItem(FInterDragDataId, TargetCentreId,
        FCentreColumns.DropTargetIdx);

    FCentreColumns.ClearDropTarget;
    FPendingList.SelectedIds.Clear;
    FCentreColumns.SelectedIds.Clear;

    BuildPendingList;
    UpdatePendingCount;
    PushUndo(Act);
  end;
end;

{ --- Botón opciones pendientes --- }

procedure TfrmFiniteCapacityPlanner.BuildOptionsPopup;
var
  Mi, Sub, Parent: TMenuItem;
begin
  FPendingPopup := TPopupMenu.Create(Self);

  // --- Carga automática (submenú) ---
  Parent := TMenuItem.Create(FPendingPopup);
  Parent.Caption := 'Carga autom'#$00E1'tica';
  FPendingPopup.Items.Add(Parent);

  Sub := TMenuItem.Create(Parent);
  Sub.Caption := 'Por prioridad';
  Sub.Tag := 1;
  Sub.OnClick := OnAutoLoadClick;
  Parent.Add(Sub);

  Sub := TMenuItem.Create(Parent);
  Sub.Caption := 'Por fecha entrega';
  Sub.Tag := 2;
  Sub.OnClick := OnAutoLoadClick;
  Parent.Add(Sub);

  if Assigned(FRuleEngine) and (FRuleEngine.ProfileCount > 0) then
  begin
    Sub := TMenuItem.Create(Parent);
    Sub.Caption := '-';
    Parent.Add(Sub);

    var I: Integer;
    for I := 0 to FRuleEngine.ProfileCount - 1 do
    begin
      Sub := TMenuItem.Create(Parent);
      Sub.Caption := FRuleEngine.GetProfile(I).Name;
      Sub.Tag := I;
      Sub.OnClick := OnAutoLoadRulesClick;
      if I = FRuleEngine.ActiveIndex then
        Sub.Default := True;
      Parent.Add(Sub);
    end;
  end;

  // --- Ordenar lista (submenú) ---
  Parent := TMenuItem.Create(FPendingPopup);
  Parent.Caption := 'Ordenar lista';
  FPendingPopup.Items.Add(Parent);

  Sub := TMenuItem.Create(Parent);
  Sub.Caption := 'Por prioridad';
  Sub.Tag := 20;
  Sub.OnClick := OnSortClick;
  Sub.Checked := True;
  Parent.Add(Sub);

  Sub := TMenuItem.Create(Parent);
  Sub.Caption := 'Por fecha entrega';
  Sub.Tag := 21;
  Sub.OnClick := OnSortClick;
  Parent.Add(Sub);

  Sub := TMenuItem.Create(Parent);
  Sub.Caption := 'Por duraci'#$00F3'n';
  Sub.Tag := 22;
  Sub.OnClick := OnSortClick;
  Parent.Add(Sub);

  Sub := TMenuItem.Create(Parent);
  Sub.Caption := 'Por art'#$00ED'culo';
  Sub.Tag := 23;
  Sub.OnClick := OnSortClick;
  Parent.Add(Sub);

  // El filtre 'Estados' i 'Operacion' es gestiona des d'un dropdown ancorat al
  // boto Filtros del toolbar (TfrmFCPFiltrosDropDown). No es posa al popup
  // perque clicar un menuitem el tancaria i el multi-select no seria operatiu.

  // --- Separador + Vaciar ---
  Mi := TMenuItem.Create(FPendingPopup);
  Mi.Caption := '-';
  FPendingPopup.Items.Add(Mi);

  Mi := TMenuItem.Create(FPendingPopup);
  Mi.Caption := 'Vaciar todos los centros';
  Mi.Tag := 10;
  Mi.OnClick := OnClearAllClick;
  FPendingPopup.Items.Add(Mi);

  Mi := TMenuItem.Create(FPendingPopup);
  Mi.Caption := '-';
  FPendingPopup.Items.Add(Mi);

  Mi := TMenuItem.Create(FPendingPopup);
  Mi.Caption := 'Exportar planificaci'#$00F3'n a CSV...';
  Mi.OnClick := OnExportClick;
  FPendingPopup.Items.Add(Mi);

  Mi := TMenuItem.Create(FPendingPopup);
  Mi.Caption := '-';
  FPendingPopup.Items.Add(Mi);

  Mi := TMenuItem.Create(FPendingPopup);
  Mi.Caption := 'Seleccionar todos';
  Mi.OnClick := OnSelectAllClick;
  FPendingPopup.Items.Add(Mi);

  Mi := TMenuItem.Create(FPendingPopup);
  Mi.Caption := 'Deseleccionar todos';
  Mi.OnClick := OnDeselectAllClick;
  FPendingPopup.Items.Add(Mi);

  // --- Separador + Card Layout ---
  Mi := TMenuItem.Create(FPendingPopup);
  Mi.Caption := '-';
  FPendingPopup.Items.Add(Mi);

  Mi := TMenuItem.Create(FPendingPopup);
  Mi.Caption := 'Editar layout de cards...';
  Mi.OnClick := OnEditCardLayoutClick;
  FPendingPopup.Items.Add(Mi);
end;

procedure TfrmFiniteCapacityPlanner.OnBtnOptionsClick(Sender: TObject);
var
  Pt: TPoint;
begin
  Pt := FBtnOptions.ClientToScreen(Point(0, FBtnOptions.Height));
  FPendingPopup.Popup(Pt.X, Pt.Y);
end;

{ --- Filtro de centros (TcxCheckComboBox) --- }

procedure TfrmFiniteCapacityPlanner.PopularCentrosCombo;
var
  I: Integer;
  Lbl: string;
  Sorted: TArray<TCentreTreball>;
  AllChecked: Boolean;
  Item: TcxCheckComboBoxItem;
begin
  FUpdatingCentros := True;
  try
    cbCentros.Properties.Items.Clear;

    // Llista del combo: sempre alfab\303\250tica per T\303\255tulo (independent de
    // l'ordre del layout al panel de columnes). Filtrem nom\303\251s Id v\303\240lid.
    Sorted := nil;
    for I := 0 to High(FCentres) do
      if FCentres[I].Id >= 0 then
      begin
        SetLength(Sorted, Length(Sorted) + 1);
        Sorted[High(Sorted)] := FCentres[I];
      end;
    TArray.Sort<TCentreTreball>(Sorted, TComparer<TCentreTreball>.Construct(
      function(const A, B: TCentreTreball): Integer
      begin
        Result := CompareText(A.Titulo, B.Titulo);
      end));

    // Item 0: pseudo "(Todos)" — marca/desmarca la resta
    Item := cbCentros.Properties.Items.Add;
    Item.Description := '(Todos)';
    Item.Tag := -1;

    AllChecked := True;
    for I := 0 to High(Sorted) do
    begin
      Lbl := Sorted[I].Titulo;
      if Trim(Lbl) = '' then Lbl := Sorted[I].CodiCentre;
      Item := cbCentros.Properties.Items.Add;
      Item.Description := Lbl;
      Item.Tag := Sorted[I].Id;
      if FVisibleCentreIds.Contains(Sorted[I].Id) then
        cbCentros.States[cbCentros.Properties.Items.Count - 1] := cbsChecked
      else
      begin
        cbCentros.States[cbCentros.Properties.Items.Count - 1] := cbsUnchecked;
        AllChecked := False;
      end;
    end;
    if AllChecked then
      cbCentros.States[0] := cbsChecked
    else
      cbCentros.States[0] := cbsUnchecked;

    cbCentros.Properties.EmptySelectionText := 'Todos los centros';
  finally
    FUpdatingCentros := False;
  end;
end;

procedure TfrmFiniteCapacityPlanner.cbCentrosChange(Sender: TObject);
var
  I: Integer;
  TodosChecked, AllReal: Boolean;
  NewState: TcxCheckBoxState;
  CId: Integer;
begin
  if FUpdatingCentros then Exit;
  if cbCentros.Properties.Items.Count = 0 then Exit;

  FUpdatingCentros := True;
  try
    TodosChecked := (cbCentros.States[0] = cbsChecked);
    AllReal := True;
    for I := 1 to cbCentros.Properties.Items.Count - 1 do
      if cbCentros.States[I] <> cbsChecked then
      begin
        AllReal := False;
        Break;
      end;

    if TodosChecked <> AllReal then
    begin
      // L'usuari ha clicat "(Todos)": propagar a la resta
      if TodosChecked then NewState := cbsChecked else NewState := cbsUnchecked;
      for I := 1 to cbCentros.Properties.Items.Count - 1 do
        cbCentros.States[I] := NewState;
    end
    else
    begin
      // L'usuari ha clicat un centre: sincronitzar "(Todos)" segons estat real
      if AllReal then
        cbCentros.States[0] := cbsChecked
      else
        cbCentros.States[0] := cbsUnchecked;
    end;

    // Reconstruir FVisibleCentreIds segons l'estat del combo (per Tag=CentroId)
    FVisibleCentreIds.Clear;
    for I := 1 to cbCentros.Properties.Items.Count - 1 do
      if cbCentros.States[I] = cbsChecked then
      begin
        CId := cbCentros.Properties.Items[I].Tag;
        if CId >= 0 then
          FVisibleCentreIds.Add(CId);
      end;
  finally
    FUpdatingCentros := False;
  end;

  ApplyCentreFilter;
end;

procedure TfrmFiniteCapacityPlanner.ApplyCentreFilter;
var
  Total, I: Integer;
begin
  Total := 0;
  for I := 0 to High(FCentres) do
    if FCentres[I].Visible and (FCentres[I].Id >= 0) then
      Inc(Total);

  // Si tots seleccionats, mostrar tots (nil = sense filtre). Si cap o
  // parcial, passar la llista (pot ser buida = cap centre visible).
  if FVisibleCentreIds.Count = Total then
    FCentreColumns.SetVisibleCentreIds(nil)
  else
    FCentreColumns.SetVisibleCentreIds(FVisibleCentreIds);
end;

{ --- Layouts d'usuari --- }

procedure TfrmFiniteCapacityPlanner.CentresOrdenAlfabetic;
var
  Tmp: TArray<TCentreTreball>;
  I: Integer;
begin
  Tmp := Copy(FCentres);
  TArray.Sort<TCentreTreball>(Tmp, TComparer<TCentreTreball>.Construct(
    function(const A, B: TCentreTreball): Integer
    begin
      Result := CompareText(A.Titulo, B.Titulo);
    end));
  for I := 0 to High(Tmp) do
    FCentres[I] := Tmp[I];
  if FCentreColumns <> nil then
    FCentreColumns.Centres := FCentres;
end;

procedure TfrmFiniteCapacityPlanner.LoadLayouts;
begin
  if FLayoutRepo = nil then Exit;
  FLayouts := FLayoutRepo.GetAll;

  // Selecció inicial: si hi ha un IsDefault, aplicar; si no, "(por defecto)"
  FCurrentLayoutId := -1;
  for var I := 0 to High(FLayouts) do
    if FLayouts[I].IsDefault then
    begin
      FCurrentLayoutId := FLayouts[I].LayoutId;
      Break;
    end;
  PopularCmbLayout(FCurrentLayoutId);
  ApplyLayout(FCurrentLayoutId);
end;

procedure TfrmFiniteCapacityPlanner.PopularCmbLayout(ASelectedLayoutId: Integer);
var
  I, IdxSel: Integer;
  Nom: string;
begin
  FUpdatingLayouts := True;
  try
    cmbLayout.Properties.Items.BeginUpdate;
    try
      cmbLayout.Properties.Items.Clear;
      // Index 0 = "(por defecto)" virtual
      cmbLayout.Properties.Items.AddObject('(por defecto)', TObject(-1));
      IdxSel := 0;
      for I := 0 to High(FLayouts) do
      begin
        Nom := FLayouts[I].Nombre;
        if FLayouts[I].IsDefault then Nom := Nom + ' *';
        cmbLayout.Properties.Items.AddObject(Nom, TObject(FLayouts[I].LayoutId));
        if (ASelectedLayoutId >= 0) and
           (FLayouts[I].LayoutId = ASelectedLayoutId) then
          IdxSel := cmbLayout.Properties.Items.Count - 1;
      end;
      cmbLayout.ItemIndex := IdxSel;
    finally
      cmbLayout.Properties.Items.EndUpdate;
    end;
  finally
    FUpdatingLayouts := False;
  end;
end;

procedure TfrmFiniteCapacityPlanner.ApplyLayout(const ALayoutId: Integer);
var
  I, J, K: Integer;
  Found: TFCPLayout;
  HasFound: Boolean;
  NewCentres: TArray<TCentreTreball>;
  VisibleIds: TList<Integer>;
begin
  if FCentreColumns = nil then Exit;

  if ALayoutId < 0 then
  begin
    // "(por defecto)": tots els centres, ordre alfabètic, tots visibles
    CentresOrdenAlfabetic;
    FVisibleCentreIds.Clear;
    for I := 0 to High(FCentres) do
      if FCentres[I].Visible and (FCentres[I].Id >= 0) then
        FVisibleCentreIds.Add(FCentres[I].Id);
    PopularCentrosCombo;
    FCentreColumns.SetVisibleCentreIds(nil);
    FCentreColumns.Invalidate;
    Exit;
  end;

  // Layout amb ID: buscar a FLayouts
  HasFound := False;
  for I := 0 to High(FLayouts) do
    if FLayouts[I].LayoutId = ALayoutId then
    begin
      Found := FLayouts[I];
      HasFound := True;
      Break;
    end;
  if not HasFound then Exit;

  // Reordenar FCentres segons Found.Centros (els no llistats van al final)
  SetLength(NewCentres, Length(FCentres));
  K := 0;
  // Primer els llistats al layout, en ordre
  for I := 0 to High(Found.Centros) do
    for J := 0 to High(FCentres) do
      if FCentres[J].Id = Found.Centros[I].CentroId then
      begin
        NewCentres[K] := FCentres[J];
        Inc(K);
        Break;
      end;
  // Després els que no estan al layout (queden ocults)
  for J := 0 to High(FCentres) do
  begin
    var AlLayout: Boolean := False;
    for I := 0 to High(Found.Centros) do
      if Found.Centros[I].CentroId = FCentres[J].Id then
      begin
        AlLayout := True;
        Break;
      end;
    if not AlLayout then
    begin
      NewCentres[K] := FCentres[J];
      Inc(K);
    end;
  end;
  FCentres := NewCentres;
  FCentreColumns.Centres := FCentres;

  // Marcar visibles segons layout
  VisibleIds := TList<Integer>.Create;
  try
    for I := 0 to High(Found.Centros) do
      VisibleIds.Add(Found.Centros[I].CentroId);
    FVisibleCentreIds.Clear;
    for I := 0 to VisibleIds.Count - 1 do
      FVisibleCentreIds.Add(VisibleIds[I]);
  finally
    VisibleIds.Free;
  end;
  PopularCentrosCombo;
  ApplyCentreFilter;
  FCentreColumns.Invalidate;
end;

function TfrmFiniteCapacityPlanner.CapturarLayoutActual: TArray<TFCPLayoutCentro>;
var
  Lst: TList<TFCPLayoutCentro>;
  I, Orden: Integer;
  C: TFCPLayoutCentro;
begin
  Lst := TList<TFCPLayoutCentro>.Create;
  try
    Orden := 0;
    for I := 0 to High(FCentres) do
    begin
      if FCentres[I].Id < 0 then Continue;
      if not FVisibleCentreIds.Contains(FCentres[I].Id) then Continue;
      C.CentroId := FCentres[I].Id;
      C.Orden := Orden;
      Inc(Orden);
      Lst.Add(C);
    end;
    Result := Lst.ToArray;
  finally
    Lst.Free;
  end;
end;

procedure TfrmFiniteCapacityPlanner.cmbLayoutChange(Sender: TObject);
var
  Lid: Integer;
begin
  if FUpdatingLayouts then Exit;
  if cmbLayout.ItemIndex < 0 then Exit;
  Lid := Integer(cmbLayout.Properties.Items.Objects[cmbLayout.ItemIndex]);
  FCurrentLayoutId := Lid;
  ApplyLayout(Lid);
end;

procedure TfrmFiniteCapacityPlanner.btnLayoutDeleteClick(Sender: TObject);
begin
 if FLayoutRepo = nil then Exit;
  if FCurrentLayoutId < 0 then Exit;  // no es pot eliminar "(por defecto)"

  if MessageDlg('¿Eliminar el layout seleccionado?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  FLayoutRepo.Delete(FCurrentLayoutId);
  FCurrentLayoutId := -1;
  LoadLayouts;

end;

procedure TfrmFiniteCapacityPlanner.btnAyudaClick(Sender: TObject);
begin
  THelpViewer.Show('uFiniteCapacityPlanner',
    'Planificador de Capacidad Finita');
end;

procedure TfrmFiniteCapacityPlanner.btnLayoutNewClick(Sender: TObject);
var
  Nom: string;
  L: TFCPLayout;
  NewId: Integer;
begin
  if FLayoutRepo = nil then Exit;
  Nom := '';
  if not InputQuery('Nuevo layout', 'Nombre del layout:', Nom) then Exit;
  Nom := Trim(Nom);
  if Nom = '' then Exit;

  L.LayoutId := -1;
  L.Nombre := Nom;
  L.IsDefault := False;
  L.Centros := CapturarLayoutActual;

  NewId := FLayoutRepo.Insert(L);
  if NewId < 0 then
  begin
    ShowMessage('No se ha podido crear el layout.');
    Exit;
  end;

  // Refrescar la llista en mem\303\262ria + repintar combo, per\303\262 sense
  // re-aplicar cap layout: l'estat actual del panel ja \303\251s el correcte.
  FCurrentLayoutId := NewId;
  FLayouts := FLayoutRepo.GetAll;
  PopularCmbLayout(NewId);
end;

procedure TfrmFiniteCapacityPlanner.btnLayoutSaveClick(Sender: TObject);
var
  I: Integer;
  L: TFCPLayout;
begin
  if FLayoutRepo = nil then Exit;
  if FCurrentLayoutId < 0 then
  begin
    // "(por defecto)" no es persisteix: tractar com a Nou
    btnLayoutNewClick(Sender);
    Exit;
  end;

  // Trobar el layout actual i actualitzar-lo amb l'estat actual
  for I := 0 to High(FLayouts) do
    if FLayouts[I].LayoutId = FCurrentLayoutId then
    begin
      L := FLayouts[I];
      L.Centros := CapturarLayoutActual;
      FLayoutRepo.Update(L);
      // Refrescar la llista en mem\303\262ria + repintar combo, mantenint el
      // mateix layout actiu (no re-aplicar).
      FLayouts := FLayoutRepo.GetAll;
      PopularCmbLayout(FCurrentLayoutId);
      Exit;
    end;
end;

procedure TfrmFiniteCapacityPlanner.BuildCentreHeaderPopup;
var
  Mi: TMenuItem;
begin
  FCentreHeaderPopup := TPopupMenu.Create(Self);

  Mi := TMenuItem.Create(FCentreHeaderPopup);
  Mi.Caption := 'Ver ficha del centro...';
  Mi.OnClick := OnCentreHeaderViewFicha;
  FCentreHeaderPopup.Items.Add(Mi);
end;

procedure TfrmFiniteCapacityPlanner.OnCentreHeaderOptionsClick(Sender: TObject);
var
  Pt: TPoint;
begin
  GetCursorPos(Pt);
  FCentreHeaderPopup.Popup(Pt.X, Pt.Y);
end;

procedure TfrmFiniteCapacityPlanner.OnColDragBegin(Sender: TObject);
var
  Pt: TPoint;
  CId, I: Integer;
  Bmp: TBitmap;
  R: TRect;
begin
  CId := FCentreColumns.ColDragCentreId;
  if CId < 0 then Exit;

  FColDragging := True;

  // Crear ghost amb nom del centre
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(200, 40);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.Pen.Color := $00E89040;
    Bmp.Canvas.Pen.Width := 2;
    Bmp.Canvas.RoundRect(0, 0, 200, 40, 8, 8);
    Bmp.Canvas.Pen.Width := 1;

    for I := 0 to High(FCentres) do
      if FCentres[I].Id = CId then
      begin
        Bmp.Canvas.Font.Size := 10;
        Bmp.Canvas.Font.Style := [fsBold];
        Bmp.Canvas.Font.Color := $00444444;
        Bmp.Canvas.Brush.Style := bsClear;
        R := Rect(10, 4, 190, 24);
        DrawText(Bmp.Canvas.Handle, PChar(FCentres[I].Titulo), -1, R,
          DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
        Bmp.Canvas.Font.Size := 8;
        Bmp.Canvas.Font.Style := [];
        Bmp.Canvas.Font.Color := $00888888;
        R := Rect(10, 22, 190, 38);
        DrawText(Bmp.Canvas.Handle, PChar(FCentres[I].Subtitulo), -1, R,
          DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
        Break;
      end;

    FColGhostForm := TForm.CreateNew(Self);
    FColGhostForm.BorderStyle := bsNone;
    FColGhostForm.FormStyle := fsStayOnTop;
    FColGhostForm.AlphaBlend := True;
    FColGhostForm.AlphaBlendValue := 180;
    FColGhostForm.Color := clWhite;
    FColGhostForm.Width := Bmp.Width;
    FColGhostForm.Height := Bmp.Height;
    FColGhostForm.Visible := False;

    GetCursorPos(Pt);
    FColGhostForm.Left := Pt.X - 100;
    FColGhostForm.Top := Pt.Y - 10;

    var Img := TImage.Create(FColGhostForm);
    Img.Parent := FColGhostForm;
    Img.Align := alClient;
    Img.Picture.Bitmap.Assign(Bmp);
    Img.Stretch := False;

    ShowWindow(FColGhostForm.Handle, SW_SHOWNOACTIVATE);
    FColGhostForm.Visible := True;
  finally
    Bmp.Free;
  end;

  SetCapture(Handle);
end;

procedure TfrmFiniteCapacityPlanner.DoColDragMove(const ScreenPt: TPoint);
var
  LocalPt: TPoint;
  TargetCId: Integer;
begin
  // Moure ghost
  if FColGhostForm <> nil then
  begin
    FColGhostForm.Left := ScreenPt.X - 100;
    FColGhostForm.Top := ScreenPt.Y - 10;
  end;

  // Actualitzar drop target
  LocalPt := FCentreColumns.ScreenToClient(ScreenPt);
  TargetCId := FCentreColumns.CentreIdAtX(LocalPt.X);
  if (TargetCId >= 0) and (TargetCId <> FCentreColumns.ColDragCentreId) then
    FCentreColumns.FColDropTargetId := TargetCId
  else
    FCentreColumns.FColDropTargetId := -1;
  FCentreColumns.Invalidate;
end;

procedure TfrmFiniteCapacityPlanner.DoColDragEnd(const ScreenPt: TPoint);
var
  TargetCId: Integer;
begin
  ReleaseCapture;

  // Destruir ghost
  if FColGhostForm <> nil then
  begin
    FColGhostForm.Free;
    FColGhostForm := nil;
  end;

  // Executar swap si hi ha target
  TargetCId := FCentreColumns.FColDropTargetId;
  if (TargetCId >= 0) and (TargetCId <> FCentreColumns.ColDragCentreId) then
  begin
    FCentreColumns.SwapCentres(FCentreColumns.ColDragCentreId, TargetCId);
    // Actualitzar FCentres del form
    FCentres := FCentreColumns.Centres;
  end;

  FCentreColumns.FColDragging := False;
  FCentreColumns.FColDragCentreId := -1;
  FCentreColumns.FColDropTargetId := -1;
  FColDragging := False;
  FCentreColumns.Invalidate;
end;

procedure TfrmFiniteCapacityPlanner.OnCentreHeaderViewFicha(Sender: TObject);
var
  CId, I: Integer;
  C: TCentreTreball;
begin
  CId := FCentreColumns.OptionsCentreId;
  if CId < 0 then Exit;

  for I := 0 to High(FCentres) do
    if FCentres[I].Id = CId then
    begin
      C := FCentres[I];
      if TfrmCentreInspector.Execute(C, True) then
      begin
        FCentres[I] := C;
        FCentreColumns.Centres := FCentres;
        FCentreColumns.Invalidate;
      end;
      Exit;
    end;
end;

procedure TfrmFiniteCapacityPlanner.BuildCentrePopup;
var
  Mi: TMenuItem;
begin
  FCentrePopup := TPopupMenu.Create(Self);
  FCentrePopup.OnPopup := OnCentrePopupShow;

  Mi := TMenuItem.Create(FCentrePopup);
  Mi.Caption := 'Devolver a pendientes';
  Mi.OnClick := OnCentrePopupUnassign;
  FCentrePopup.Items.Add(Mi);

  Mi := TMenuItem.Create(FCentrePopup);
  Mi.Caption := '-';
  FCentrePopup.Items.Add(Mi);

  Mi := TMenuItem.Create(FCentrePopup);
  Mi.Caption := 'Asignar operarios...';
  Mi.OnClick := OnCentrePopupAssignOperaris;
  FCentrePopup.Items.Add(Mi);
end;

procedure TfrmFiniteCapacityPlanner.OnCentrePopupShow(Sender: TObject);
var
  D: TNodeData;
  HasCard: Boolean;
begin
  FPopupDataId := FCentreColumns.RightClickDataId;
  HasCard := FPopupDataId >= 0;
  FCentrePopup.Items[0].Visible := HasCard;  // Devolver a pendientes
  FCentrePopup.Items[1].Visible := HasCard;  // Separador
  // Asignar operarios: solo si tiene operarios necesarios
  if HasCard and FNodeRepo.TryGetById(FPopupDataId, D) then
    FCentrePopup.Items[2].Visible := D.OperariosNecesarios > 0
  else
    FCentrePopup.Items[2].Visible := False;
end;

procedure TfrmFiniteCapacityPlanner.OnCentrePopupUnassign(Sender: TObject);
var
  Act: TFCPAction;
begin
  if FPopupDataId < 0 then Exit;
  Act.Kind := akUnassign;
  Act.Snapshot := TakeSnapshot;
  FCentreColumns.UnassignItem(FPopupDataId);
  FPopupDataId := -1;
  BuildPendingList;
  UpdatePendingCount;
  FCentreColumns.Invalidate;
  PushUndo(Act);
end;

procedure TfrmFiniteCapacityPlanner.OnCentrePopupAssignOperaris(Sender: TObject);
var
  D: TNodeData;
  OpAssig: Integer;
begin
  if FPopupDataId < 0 then Exit;
  if FOperariosRepo = nil then Exit;
  if not FNodeRepo.TryGetById(FPopupDataId, D) then Exit;

  TfrmAssignOperaris.Execute(
    FOperariosRepo,
    D.DataId,
    D.Operacion,
    D.DurationMin,
    D.OperariosNecesarios,
    OpAssig);

  // Actualizar el campo de operarios asignados en el NodeData
  D.OperariosAsignados := OpAssig;
  FNodeRepo.AddOrUpdate(D);

  FCentreColumns.Invalidate;
  FPendingList.Invalidate;
end;

procedure TfrmFiniteCapacityPlanner.OnAutoLoadClick(Sender: TObject);
begin
  if not (Sender is TMenuItem) then Exit;
  DoAutoLoad(TMenuItem(Sender).Tag = 2);
end;

procedure TfrmFiniteCapacityPlanner.OnAutoLoadRulesClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    FRuleEngine.ActiveIndex := TMenuItem(Sender).Tag;
  DoAutoLoadWithRules;
end;

procedure TfrmFiniteCapacityPlanner.DoAutoLoadWithRules;
var
  AllData, PendArr, Filtered: TArray<TNodeData>;
  ForcedCentres: TDictionary<Integer, Integer>;
  GroupSameCenter: TDictionary<string, TList<Integer>>;
  GroupCentreMap: TDictionary<string, Integer>;
  SimAssign: TDictionary<Integer, Integer>;  // DataId -> CentreId (simulació)
  SimCentreMin: TDictionary<Integer, Double>; // CentreId -> minuts usats
  SimCentreCnt: TDictionary<Integer, Integer>; // CentreId -> count
  I, J, K, CId, Cap, Cnt, ForcedId, TotalPending: Integer;
  D: TNodeData;
  NodeAssigned, Permitido: Boolean;
  GrpKey: string;
  GrpCentreId: Integer;
  WorkMin, UsedMin: Double;
  Preview: TPreviewResult;
  Pair: TPair<Integer, TList<Integer>>;
  Act: TFCPAction;
begin
  if (FRuleEngine = nil) or (FRuleEngine.ProfileCount = 0) then
  begin
    DoAutoLoad(False);
    Exit;
  end;

  // ══════════════════════════════════════
  //  FASE 1: SIMULACIÓ EN MEMÒRIA
  // ══════════════════════════════════════

  AllData := FNodeRepo.GetAllData;
  TotalPending := 0;

  // Recollir pendents (sense comptar assignats actuals — simulem des de zero)
  var PendList: TList<TNodeData>;
  PendList := TList<TNodeData>.Create;
  try
    for I := 0 to High(AllData) do
    begin
      D := AllData[I];
      if D.Estado = neFinalizado then Continue;
      PendList.Add(D);
    end;
    TotalPending := PendList.Count;
    PendArr := PendList.ToArray;
  finally
    PendList.Free;
  end;

  // Filtrar
  FRuleEngine.FilterNodes(PendArr, Filtered, ForcedCentres);

  // Agrupar
  FRuleEngine.GroupNodes(Filtered, GroupSameCenter);
  GroupCentreMap := TDictionary<string, Integer>.Create;

  // Ordenar
  FRuleEngine.SortNodes(Filtered);

  // Simular distribució
  SimAssign := TDictionary<Integer, Integer>.Create;
  SimCentreMin := TDictionary<Integer, Double>.Create;
  SimCentreCnt := TDictionary<Integer, Integer>.Create;
  try
    // Inicialitzar comptadors de centres
    for J := 0 to High(FCentres) do
    begin
      SimCentreMin.Add(FCentres[J].Id, 0);
      SimCentreCnt.Add(FCentres[J].Id, 0);
    end;

    for I := 0 to High(Filtered) do
    begin
      D := Filtered[I];
      NodeAssigned := False;

      // Grup gmSameCenter
      GrpKey := '';
      GrpCentreId := -1;
      for var GrpPair in GroupSameCenter do
        if GrpPair.Value.Contains(D.DataId) then
        begin
          GrpKey := GrpPair.Key;
          GroupCentreMap.TryGetValue(GrpKey, GrpCentreId);
          Break;
        end;

      if GrpCentreId >= 0 then
      begin
        SimAssign.Add(D.DataId, GrpCentreId);
        SimCentreMin[GrpCentreId] := SimCentreMin[GrpCentreId] + D.DurationMin;
        SimCentreCnt[GrpCentreId] := SimCentreCnt[GrpCentreId] + 1;
        Continue;
      end;

      // Centre forçat per filtre
      if ForcedCentres.TryGetValue(D.DataId, ForcedId) then
      begin
        WorkMin := FCentreColumns.ColWorkingMinutes(ForcedId);
        if WorkMin > 0 then
        begin
          UsedMin := SimCentreMin.Items[ForcedId];
          if (UsedMin + D.DurationMin) <= WorkMin then
            NodeAssigned := True;
        end
        else
        begin
          if SimCentreCnt.ContainsKey(ForcedId) then
            Cnt := SimCentreCnt[ForcedId]
          else
            Cnt := 0;
          Cap := FCentreColumns.ColCapacity(ForcedId);
          if (Cap = 0) or (Cnt < Cap) then
            NodeAssigned := True;
        end;
        if NodeAssigned then
        begin
          SimAssign.Add(D.DataId, ForcedId);
          SimCentreMin[ForcedId] := SimCentreMin[ForcedId] + D.DurationMin;
          SimCentreCnt[ForcedId] := SimCentreCnt[ForcedId] + 1;
          if GrpKey <> '' then GroupCentreMap.AddOrSetValue(GrpKey, ForcedId);
          Continue;
        end;
      end;

      // Distribució normal
      for J := 0 to High(FCentres) do
      begin
        if not FCentres[J].Visible then Continue;
        if FCentres[J].Id < 0 then Continue;
        CId := FCentres[J].Id;

        if Length(D.CentresPermesos) > 0 then
        begin
          Permitido := False;
          for K := 0 to High(D.CentresPermesos) do
            if D.CentresPermesos[K] = CId then begin Permitido := True; Break; end;
          if not Permitido and not D.LibreMoviment then Continue;
        end;

        WorkMin := FCentreColumns.ColWorkingMinutes(CId);
        if WorkMin > 0 then
        begin
          UsedMin := SimCentreMin[CId];
          if (UsedMin + D.DurationMin) > WorkMin then Continue;
        end
        else
        begin
          Cap := FCentreColumns.ColCapacity(CId);
          Cnt := SimCentreCnt[CId];
          if (Cap > 0) and (Cnt >= Cap) then Continue;
        end;

        SimAssign.Add(D.DataId, CId);
        SimCentreMin[CId] := SimCentreMin[CId] + D.DurationMin;
        SimCentreCnt[CId] := SimCentreCnt[CId] + 1;
        NodeAssigned := True;
        if GrpKey <> '' then GroupCentreMap.AddOrSetValue(GrpKey, CId);
        Break;
      end;
    end;

    // ══════════════════════════════════════
    //  FASE 2: GENERAR PREVIEW
    // ══════════════════════════════════════

    Preview.ProfileName := FRuleEngine.GetActiveProfile.Name;
    Preview.TotalOTs := TotalPending;
    Preview.AssignedOTs := SimAssign.Count;
    Preview.UnassignedOTs := Length(Filtered) - SimAssign.Count;
    Preview.FilteredOTs := TotalPending - Length(Filtered);
    Preview.GroupCount := GroupSameCenter.Count;

    // Stats per centre
    var CStats: TList<TPreviewCentreStat>;
    CStats := TList<TPreviewCentreStat>.Create;
    try
      var TotalOcc: Double;
      var CentreCount: Integer;
      TotalOcc := 0;
      CentreCount := 0;
      for J := 0 to High(FCentres) do
      begin
        if FCentres[J].Id < 0 then Continue;
        if not FCentres[J].Visible then Continue;
        CId := FCentres[J].Id;
        var CS: TPreviewCentreStat;
        CS.CentreId := CId;
        CS.CentreName := FCentres[J].Titulo;
        CS.AssignedCount := SimCentreCnt[CId];
        CS.TotalMinutes := SimCentreMin[CId];
        CS.CapacityMinutes := FCentreColumns.ColWorkingMinutes(CId);
        if CS.CapacityMinutes > 0 then
          CS.OccupationPct := (CS.TotalMinutes / CS.CapacityMinutes) * 100
        else if CS.AssignedCount > 0 then
          CS.OccupationPct := 100
        else
          CS.OccupationPct := 0;
        CStats.Add(CS);
        TotalOcc := TotalOcc + CS.OccupationPct;
        Inc(CentreCount);
      end;
      Preview.CentreStats := CStats.ToArray;
      if CentreCount > 0 then
        Preview.AvgOccupation := TotalOcc / CentreCount
      else
        Preview.AvgOccupation := 0;
    finally
      CStats.Free;
    end;

    // Llista de no assignats
    var Unassigned: TList<string>;
    Unassigned := TList<string>.Create;
    try
      for I := 0 to High(Filtered) do
        if not SimAssign.ContainsKey(Filtered[I].DataId) then
          Unassigned.Add(Format('OF %d - %s (%s)', [
            Filtered[I].NumeroOrdenFabricacion,
            Filtered[I].Operacion,
            Filtered[I].CodigoArticulo]));
      Preview.UnassignedList := Unassigned.ToArray;
    finally
      Unassigned.Free;
    end;

    // ══════════════════════════════════════
    //  FASE 3: MOSTRAR PREVIEW
    // ══════════════════════════════════════

    if not TfrmPlanningPreview.Execute(Preview) then
      Exit;  // L'usuari ha cancel·lat

    // ══════════════════════════════════════
    //  FASE 4: APLICAR REALMENT
    // ══════════════════════════════════════

    Act.Kind := akAutoLoad;
    Act.Snapshot := TakeSnapshot;

    // Netejar centres
    for Pair in FCentreColumns.Assignments do
      Pair.Value.Clear;

    // Aplicar assignacions simulades
    for var SimPair in SimAssign do
      FCentreColumns.AssignItem(SimPair.Key, SimPair.Value);

    BuildPendingList;
    UpdatePendingCount;
    FCentreColumns.Invalidate;
    PushUndo(Act);

  finally
    SimAssign.Free;
    SimCentreMin.Free;
    SimCentreCnt.Free;
    GroupCentreMap.Free;
    for var GrpPair2 in GroupSameCenter do
      GrpPair2.Value.Free;
    GroupSameCenter.Free;
    ForcedCentres.Free;
  end;
end;

procedure TfrmFiniteCapacityPlanner.DoAutoLoad(const ByFechaEntrega: Boolean);
var
  AllData: TArray<TNodeData>;
  Sorted: TList<TNodeData>;
  I, J, K, CId, Cap, Cnt: Integer;
  D: TNodeData;
  Assigned, Permitido: Boolean;
  Act: TFCPAction;
begin
  Act.Kind := akAutoLoad;
  Act.Snapshot := TakeSnapshot;
  // Recoger todas las OT pendientes (no finalizadas, no asignadas)
  Sorted := TList<TNodeData>.Create;
  try
    AllData := FNodeRepo.GetAllData;
    for I := 0 to High(AllData) do
    begin
      D := AllData[I];
      if D.Estado = neFinalizado then Continue;
      if FCentreColumns.IsAssigned(D.DataId) then Continue;
      Sorted.Add(D);
    end;

    // Ordenar
    if ByFechaEntrega then
      Sorted.Sort(TComparer<TNodeData>.Construct(
        function(const A, B: TNodeData): Integer
        begin
          if A.FechaEntrega < B.FechaEntrega then Result := -1
          else if A.FechaEntrega > B.FechaEntrega then Result := 1
          else Result := A.Prioridad - B.Prioridad;
        end))
    else
      Sorted.Sort(TComparer<TNodeData>.Construct(
        function(const A, B: TNodeData): Integer
        begin
          Result := A.Prioridad - B.Prioridad;
          if Result = 0 then
          begin
            if A.FechaEntrega < B.FechaEntrega then Result := -1
            else if A.FechaEntrega > B.FechaEntrega then Result := 1;
          end;
        end));

    // Distribuir respetando capacidad y centros permitidos
    for I := 0 to Sorted.Count - 1 do
    begin
      D := Sorted[I];
      Assigned := False;

      // Buscar primer centro con capacidad disponible
      for J := 0 to High(FCentres) do
      begin
        if not FCentres[J].Visible then Continue;
        if FCentres[J].Id < 0 then Continue;
        CId := FCentres[J].Id;

        // Comprobar si este centro está permitido para la OT
        if Length(D.CentresPermesos) > 0 then
        begin
          Permitido := False;
          for K := 0 to High(D.CentresPermesos) do
            if D.CentresPermesos[K] = CId then
            begin
              Permitido := True;
              Break;
            end;
          if not Permitido and not D.LibreMoviment then
            Continue;
        end;

        // Comprobar capacidad por horas (calendari) o por slots
        var WorkMin: Double := FCentreColumns.ColWorkingMinutes(CId);
        if WorkMin > 0 then
        begin
          // Capacitat horària: comprovar si hi cap
          var UsedMin: Double := FCentreColumns.ColTotalMinutes(CId);
          if (UsedMin + D.DurationMin) > WorkMin then
            Continue;
        end
        else
        begin
          // Fallback a slots
          Cap := FCentreColumns.ColCapacity(CId);
          Cnt := FCentreColumns.ColCountForCentre(CId);
          if (Cap > 0) and (Cnt >= Cap) then
            Continue;
        end;

        // Asignar
        FCentreColumns.AssignItem(D.DataId, CId);
        Assigned := True;
        Break;
      end;
      // Si no se pudo asignar, queda en pendientes
    end;
  finally
    Sorted.Free;
  end;

  BuildPendingList;
  UpdatePendingCount;
  FCentreColumns.Invalidate;
  PushUndo(Act);
end;

procedure TfrmFiniteCapacityPlanner.OnClearAllClick(Sender: TObject);
var
  Pair: TPair<Integer, TList<Integer>>;
  Act: TFCPAction;
begin
  Act.Kind := akClearAll;
  Act.Snapshot := TakeSnapshot;

  for Pair in FCentreColumns.Assignments do
    Pair.Value.Clear;

  BuildPendingList;
  UpdatePendingCount;
  FCentreColumns.Invalidate;
  PushUndo(Act);
end;

procedure TfrmFiniteCapacityPlanner.OnSortClick(Sender: TObject);
var
  I: Integer;
  SortParent: TMenuItem;
  NewMode: TPendingSortMode;
begin
  if not (Sender is TMenuItem) then Exit;
  case TMenuItem(Sender).Tag of
    20: NewMode := smPrioridad;
    21: NewMode := smFechaEntrega;
    22: NewMode := smDuracion;
    23: NewMode := smArticulo;
  else Exit;
  end;
  FSortMode := NewMode;

  // Actualizar checks en el submenú "Ordenar lista"
  SortParent := TMenuItem(Sender).Parent;
  if SortParent <> nil then
    for I := 0 to SortParent.Count - 1 do
      SortParent.Items[I].Checked := SortParent.Items[I].Tag = TMenuItem(Sender).Tag;

  BuildPendingList;
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.OnEstadoFilterClick(Sender: TObject);
var
  Mi: TMenuItem;
  E: TNodoEstado;
begin
  if not (Sender is TMenuItem) then Exit;
  Mi := TMenuItem(Sender);
  E := TNodoEstado(Mi.Tag);

  // Toggle
  if E in FEstadoFilter then
    Exclude(FEstadoFilter, E)
  else
    Include(FEstadoFilter, E);
  Mi.Checked := E in FEstadoFilter;

  BuildPendingList;
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.LoadOperacionesFromDB(AList: TStringList);
var
  Q: TADOQuery;
begin
  AList.Clear;
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) then Exit;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT Operacion FROM FS_PL_OperationType ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa ' +
      'ORDER BY Operacion';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      AList.Add(Q.FieldByName('Operacion').AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmFiniteCapacityPlanner.OnOperacionFilterClick(Sender: TObject);
var
  Mi: TMenuItem;
  Op: string;
  Idx: Integer;
begin
  if not (Sender is TMenuItem) then Exit;
  Mi := TMenuItem(Sender);
  Op := StringReplace(Mi.Caption, '&', '', [rfReplaceAll]);

  // Toggle: si esta a la llista, l'extreu; si no, l'afegeix.
  Idx := FOperacionFilter.IndexOf(Op);
  if Idx >= 0 then
    FOperacionFilter.Delete(Idx)
  else
    FOperacionFilter.Add(Op);

  Mi.Checked := FOperacionFilter.IndexOf(Op) >= 0;

  BuildPendingList;
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.RefreshOperacionMenuChecks(AMenu: TMenuItem);
var
  I: Integer;
  Child: TMenuItem;
  Op: string;
begin
  if AMenu = nil then Exit;
  for I := 0 to AMenu.Count - 1 do
  begin
    Child := AMenu.Items[I];
    if Child.Tag <> 0 then Continue; // saltar separadors/accions r\303\240pides
    Op := StringReplace(Child.Caption, '&', '', [rfReplaceAll]);
    Child.Checked := FOperacionFilter.IndexOf(Op) >= 0;
  end;
end;

procedure TfrmFiniteCapacityPlanner.OnOperacionMarkAllClick(Sender: TObject);
var
  Mi, Parent: TMenuItem;
  Ops: TStringList;
  K: Integer;
begin
  if not (Sender is TMenuItem) then Exit;
  Mi := TMenuItem(Sender);
  Parent := Mi.Parent;

  Ops := TStringList.Create;
  try
    LoadOperacionesFromDB(Ops);
    FOperacionFilter.Clear;
    for K := 0 to Ops.Count - 1 do
      FOperacionFilter.Add(Ops[K]);
  finally
    Ops.Free;
  end;

  RefreshOperacionMenuChecks(Parent);
  BuildPendingList;
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.OnOperacionUnmarkAllClick(Sender: TObject);
var
  Mi, Parent: TMenuItem;
begin
  if not (Sender is TMenuItem) then Exit;
  Mi := TMenuItem(Sender);
  Parent := Mi.Parent;

  FOperacionFilter.Clear;
  // Marquem una operacio "sentinel" perqu\303\250 el filtre s'apliqui amb llista
  // no-buida i tots els items amb Operaci\303\263 quedin fora. Items amb Operaci\303\263
  // buida segueixen passant (decisi\303\263 ja documentada a BuildPendingList).
  FOperacionFilter.Add(#1);

  RefreshOperacionMenuChecks(Parent);
  BuildPendingList;
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.OnSelectAllClick(Sender: TObject);
var
  I: Integer;
begin
  FPendingList.SelectedIds.Clear;
  for I := 0 to High(FPendingList.Items) do
    FPendingList.SelectedIds.Add(FPendingList.Items[I]);
  FPendingList.Invalidate;
end;

procedure TfrmFiniteCapacityPlanner.OnDeselectAllClick(Sender: TObject);
begin
  FPendingList.SelectedIds.Clear;
  FPendingList.Invalidate;
end;

function TfrmFiniteCapacityPlanner.TakeSnapshot: TArray<TFCPAssignment>;
begin
  Result := BuildAssignments;
end;

procedure TfrmFiniteCapacityPlanner.RestoreSnapshot(const ASnap: TArray<TFCPAssignment>);
var
  Pair: TPair<Integer, TList<Integer>>;
  I: Integer;
begin
  // Vaciar todo
  for Pair in FCentreColumns.Assignments do
    Pair.Value.Clear;
  // Restaurar
  for I := 0 to High(ASnap) do
    FCentreColumns.AssignItem(ASnap[I].DataId, ASnap[I].CentreId, ASnap[I].SortIndex);
  BuildPendingList;
  UpdatePendingCount;
  FCentreColumns.Invalidate;
end;

procedure TfrmFiniteCapacityPlanner.PushUndo(const AAction: TFCPAction);
begin
  FUndoStack.Add(AAction);
  FRedoStack.Clear;
  UpdateUndoRedoButtons;
end;

procedure TfrmFiniteCapacityPlanner.DoUndo;
var
  Act, RedoAct: TFCPAction;
begin
  if FUndoStack.Count = 0 then Exit;
  Act := FUndoStack[FUndoStack.Count - 1];
  FUndoStack.Delete(FUndoStack.Count - 1);

  // Guardar estado actual para redo
  RedoAct.Kind := Act.Kind;
  RedoAct.Snapshot := TakeSnapshot;
  FRedoStack.Add(RedoAct);

  // Restaurar estado anterior
  RestoreSnapshot(Act.Snapshot);
  UpdateUndoRedoButtons;
end;

procedure TfrmFiniteCapacityPlanner.DoRedo;
var
  Act, UndoAct: TFCPAction;
begin
  if FRedoStack.Count = 0 then Exit;
  Act := FRedoStack[FRedoStack.Count - 1];
  FRedoStack.Delete(FRedoStack.Count - 1);

  // Guardar estado actual para undo
  UndoAct.Kind := Act.Kind;
  UndoAct.Snapshot := TakeSnapshot;
  FUndoStack.Add(UndoAct);

  // Restaurar estado
  RestoreSnapshot(Act.Snapshot);
  UpdateUndoRedoButtons;
end;

procedure TfrmFiniteCapacityPlanner.UpdateUndoRedoButtons;
var
  C: TColor;
begin
  if FBtnUndo <> nil then
  begin
    if FUndoStack.Count > 0 then C := $00666666
    else C := $00CCCCCC;
    FBtnUndo.Font.Color := C;
    if FBtnUndo.Tag <> 0 then
      TLabel(FBtnUndo.Tag).Font.Color := C;
  end;
  if FBtnRedo <> nil then
  begin
    if FRedoStack.Count > 0 then C := $00666666
    else C := $00CCCCCC;
    FBtnRedo.Font.Color := C;
    if FBtnRedo.Tag <> 0 then
      TLabel(FBtnRedo.Tag).Font.Color := C;
  end;
end;

procedure TfrmFiniteCapacityPlanner.OnUndoClick(Sender: TObject);
begin
  DoUndo;
end;

procedure TfrmFiniteCapacityPlanner.OnRedoClick(Sender: TObject);
begin
  DoRedo;
end;

procedure TfrmFiniteCapacityPlanner.OnAutoScrollTimer(Sender: TObject);
const
  EDGE = 40;     // zona de detecció en píxels
  SPEED = 15;    // píxels per tick
var
  Pt, LocalPt: TPoint;
  CId: Integer;
begin
  if not FInterDragging then
  begin
    FAutoScrollTimer.Enabled := False;
    Exit;
  end;

  GetCursorPos(Pt);

  // Auto-scroll panel pendents (vertical)
  LocalPt := FPendingList.ScreenToClient(Pt);
  if PtInRect(FPendingList.ClientRect, LocalPt) or
     ((LocalPt.X >= 0) and (LocalPt.X < FPendingList.ClientWidth)) then
  begin
    if LocalPt.Y < EDGE then
      FPendingList.ScrollBy(-SPEED)
    else if LocalPt.Y > FPendingList.ClientHeight - EDGE then
      FPendingList.ScrollBy(SPEED);
  end;

  // Auto-scroll columnes
  LocalPt := FCentreColumns.ScreenToClient(Pt);
  if (LocalPt.X >= 0) and (LocalPt.X < FCentreColumns.ClientWidth) and
     (LocalPt.Y >= 0) and (LocalPt.Y < FCentreColumns.ClientHeight) then
  begin
    // Scroll horitzontal: marges esquerra/dreta
    if LocalPt.X < EDGE then
      FCentreColumns.ScrollHByDelta(-SPEED)
    else if LocalPt.X > FCentreColumns.ClientWidth - EDGE then
      FCentreColumns.ScrollHByDelta(SPEED);

    // Scroll vertical per columna: marges superior/inferior de la zona de cards
    CId := FCentreColumns.CentreIdAtX(LocalPt.X);
    if CId >= 0 then
    begin
      if LocalPt.Y < FCentreColumns.CardsTop + EDGE then
        FCentreColumns.ScrollColByDelta(CId, -SPEED)
      else if LocalPt.Y > FCentreColumns.ClientHeight - EDGE then
        FCentreColumns.ScrollColByDelta(CId, SPEED);
    end;
  end;

  // Actualitzar drop target
  FCentreColumns.UpdateDropTarget(Pt);
end;

procedure TfrmFiniteCapacityPlanner.GetPlanningDates(out AStart, AEnd: TDateTime);
begin
  AStart := FPlanningStart;
  case FPlanningRange of
    pr1Dia:      AEnd := AStart + 1;
    pr2Dies:     AEnd := AStart + 2;
    pr3Dies:     AEnd := AStart + 3;
    pr5Dies:     AEnd := AStart + 5;
    pr1Setmana:  AEnd := AStart + 7;
    pr2Setmanes: AEnd := AStart + 14;
    pr1Mes:      AEnd := IncMonth(AStart, 1);
  else
    AEnd := AStart + 7;
  end;
end;

procedure TfrmFiniteCapacityPlanner.RecalcCentreTimes(const CentreId: Integer);
var
  Cal: TCentreCalendar;
  L: TList<Integer>;
  I: Integer;
  D: TNodeData;
  Cursor: TDateTime;
  EndTime: TDateTime;
  Interval: TAbsInterval;
  DurMin: Integer;
begin
  if not Assigned(FGetCalendar) then Exit;
  if FCentreColumns = nil then Exit;
  if not FCentreColumns.Assignments.TryGetValue(CentreId, L) then Exit;
  Cal := FGetCalendar(CentreId);

  // Punt de partida: data d'inici de planificació
  Cursor := FPlanningStart;

  // Si hi ha calendari, avancem al primer moment laborable
  if Cal <> nil then
    Cursor := Cal.NextWorkingTime(Cursor);

  for I := 0 to L.Count - 1 do
  begin
    if not FNodeRepo.TryGetById(L[I], D) then Continue;

    DurMin := Max(1, Ceil(D.DurationMin));

    if Cal <> nil then
    begin
      // Assegurar que comencem en temps laborable
      Cursor := Cal.NextWorkingTime(Cursor);
      EndTime := Cal.AddWorkingMinutes(Cursor, DurMin);
    end
    else
    begin
      EndTime := Cursor + (DurMin / 1440.0);
    end;

    Interval.S := Cursor;
    Interval.E := EndTime;
    FCalculatedTimes.AddOrSetValue(L[I], Interval);

    Cursor := EndTime;
  end;
end;

procedure TfrmFiniteCapacityPlanner.RecalcAllCentreTimes;
var
  I: Integer;
begin
  FCalculatedTimes.Clear;
  for I := 0 to High(FCentres) do
  begin
    if not FCentres[I].Visible then Continue;
    if FCentres[I].Id < 0 then Continue;
    RecalcCentreTimes(FCentres[I].Id);
  end;
  FCentreColumns.Invalidate;
end;

procedure TfrmFiniteCapacityPlanner.OnRangeChange(Sender: TObject);
var
  S, E: TDateTime;
begin
  case FCmbRange.ItemIndex of
    0: FPlanningRange := pr1Dia;
    1: FPlanningRange := pr2Dies;
    2: FPlanningRange := pr3Dies;
    3: FPlanningRange := pr5Dies;
    4: FPlanningRange := pr1Setmana;
    5: FPlanningRange := pr2Setmanes;
    6: FPlanningRange := pr1Mes;
  end;
  GetPlanningDates(S, E);
  FCentreColumns.FPlanningStart := S;
  FCentreColumns.FPlanningEnd := E;
  RecalcAllCentreTimes;
  UpdateFooter;
end;

procedure TfrmFiniteCapacityPlanner.OnStartDateChange(Sender: TObject);
var
  S, E: TDateTime;
begin
  FPlanningStart := FDtpStart.Date;
  GetPlanningDates(S, E);
  FCentreColumns.FPlanningStart := S;
  FCentreColumns.FPlanningEnd := E;
  RecalcAllCentreTimes;
  UpdateFooter;
end;

procedure TfrmFiniteCapacityPlanner.OnExportClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  SL: TStringList;
  L: TList<Integer>;
  I, J, CentreId, OpAssig: Integer;

  D: TNodeData;
  CentreNom: string;
  NStart, NEnd: TDateTime;
begin
  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Title := 'Exportar planificaci' + #$00F3 + 'n';
    Dlg.Filter := 'CSV (*.csv)|*.csv';
    Dlg.DefaultExt := 'csv';
    Dlg.FileName := 'planificacion_' + FormatDateTime('yyyymmdd', Date) + '.csv';
    if not Dlg.Execute then Exit;

    SL := TStringList.Create;
    try
      // Cabecera
      SL.Add('Centro;OF;Operacion;Articulo;Descripcion;Cliente;Duracion_min;' +
             'Fecha_entrega;Fecha_inicio;Fecha_fin;Estado;Prioridad;' +
             'Operarios_nec;Operarios_asig;Orden');

      // Recorrer tots els centres amb assignacions
      for I := 0 to High(FCentres) do
      begin
        if not FCentres[I].Visible then Continue;
        CentreId := FCentres[I].Id;
        if CentreId < 0 then Continue;
        CentreNom := FCentres[I].Titulo;

        if not FCentreColumns.Assignments.TryGetValue(CentreId, L) then Continue;

        for J := 0 to L.Count - 1 do
        begin
          if not FNodeRepo.TryGetById(L[J], D) then Continue;

          OpAssig := 0;
          if FOperariosRepo <> nil then
            OpAssig := GetOperariosAssignats(FOperariosRepo, D.DataId);

          NStart := 0; NEnd := 0;
          if Assigned(FGetNodeTimes) then
            FGetNodeTimes(D.DataId, NStart, NEnd);

          SL.Add(Format('%s;%d;%s;%s;%s;%s;%.1f;%s;%s;%s;%s;%s;%d;%d;%d', [
            CentreNom,
            D.NumeroOrdenFabricacion,
            D.Operacion,
            D.CodigoArticulo,
            D.DescripcionArticulo,
            D.CodigoCliente,
            D.DurationMin,
            FormatDateTime('dd/mm/yyyy', D.FechaEntrega),
            FormatDateTime('dd/mm/yyyy hh:nn', NStart),
            FormatDateTime('dd/mm/yyyy hh:nn', NEnd),
            EstadoAbrev(D.Estado),
            PrioridadText(D.Prioridad),
            D.OperariosNecesarios,
            OpAssig,
            J
          ]));
        end;
      end;

      // Pendents
      for I := 0 to High(FPendingList.Items) do
      begin
        if not FNodeRepo.TryGetById(FPendingList.Items[I], D) then Continue;

        OpAssig := 0;
        if FOperariosRepo <> nil then
          OpAssig := GetOperariosAssignats(FOperariosRepo, D.DataId);

        NStart := 0; NEnd := 0;
        if Assigned(FGetNodeTimes) then
          FGetNodeTimes(D.DataId, NStart, NEnd);

        SL.Add(Format('%s;%d;%s;%s;%s;%s;%.1f;%s;%s;%s;%s;%s;%d;%d;%d', [
          '(Pendiente)',
          D.NumeroOrdenFabricacion,
          D.Operacion,
          D.CodigoArticulo,
          D.DescripcionArticulo,
          D.CodigoCliente,
          D.DurationMin,
          FormatDateTime('dd/mm/yyyy', D.FechaEntrega),
          FormatDateTime('dd/mm/yyyy hh:nn', NStart),
          FormatDateTime('dd/mm/yyyy hh:nn', NEnd),
          EstadoAbrev(D.Estado),
          PrioridadText(D.Prioridad),
          D.OperariosNecesarios,
          OpAssig,
          I
        ]));
      end;

      SL.SaveToFile(Dlg.FileName, TEncoding.UTF8);
      MessageDlg(Format('Exportadas %d l' + #$00ED + 'neas a:' + #13#10 + '%s',
        [SL.Count - 1, Dlg.FileName]),
        mtInformation, [mbOK], 0);
    finally
      SL.Free;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmFiniteCapacityPlanner.FormKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('Z')) then
  begin
    DoUndo;
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = Ord('Y')) then
  begin
    DoRedo;
    Key := 0;
  end;
end;

procedure TfrmFiniteCapacityPlanner.LoadBacklogPending;
var
  Q: TADOQuery;
  D: TNodeData;
  RawId, NextDataId, MinExistingId: Integer;
  Op: string;
begin
  if (FNodeRepo = nil) or (DMPlanner = nil) or not DMPlanner.IsConnected then Exit;

  // DataId sintetic: usem enters negatius per no xocar amb els reals (positius).
  // Comencem a -1 i decrementem; si el repo ja en tenia algun (rar), partim per
  // sota del minim.
  NextDataId := -1;
  MinExistingId := 0;
  for var ND in FNodeRepo.GetAllData do
    if ND.DataId < MinExistingId then
      MinExistingId := ND.DataId;
  if MinExistingId < 0 then
    NextDataId := MinExistingId - 1;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT RawId, TipoOrigen, ClaveERP, CodigoDocumento, ' +
      '       CodigoArticulo, DescripcionArticulo, ' +
      '       Cantidad, CodigoCliente, NombreCliente, ' +
      '       FechaCompromiso, FechaNecesaria, ' +
      '       Prioridad, CentroPreferente, HorasEstimadas ' +
      'FROM FS_PL_vw_Backlog ' +
      'WHERE CodigoEmpresa = :Emp AND Nivel = 3';
    Q.Parameters.ParamByName('Emp').Value := DMPlanner.CodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      RawId := Q.FieldByName('RawId').AsInteger;

      D := Default(TNodeData);
      D.DataId := NextDataId;
      Dec(NextDataId);

      Op := Trim(Q.FieldByName('CodigoDocumento').AsString);
      D.Operacion := Op;
      D.CodigoArticulo := Q.FieldByName('CodigoArticulo').AsString;
      D.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      D.CodigoCliente := Q.FieldByName('CodigoCliente').AsString;

      if not Q.FieldByName('FechaCompromiso').IsNull then
        D.FechaEntrega := Q.FieldByName('FechaCompromiso').AsDateTime;
      if not Q.FieldByName('FechaNecesaria').IsNull then
        D.FechaNecesaria := Q.FieldByName('FechaNecesaria').AsDateTime;

      if not Q.FieldByName('Cantidad').IsNull then
        D.UnidadesAFabricar := Q.FieldByName('Cantidad').AsFloat;
      if not Q.FieldByName('HorasEstimadas').IsNull then
        D.DurationMin := Q.FieldByName('HorasEstimadas').AsFloat * 60.0;
      D.DurationMinOriginal := D.DurationMin;

      if not Q.FieldByName('Prioridad').IsNull then
        D.Prioridad := Q.FieldByName('Prioridad').AsInteger
      else
        D.Prioridad := 99;

      D.Estado := nePendiente;
      D.Tipo := ntOF;
      D.OperariosNecesarios := 1;
      D.LibreMoviment := True;

      D.RawItemTipoOrigen := Q.FieldByName('TipoOrigen').AsString;
      D.RawItemClaveERP := Q.FieldByName('ClaveERP').AsString;

      FNodeRepo.AddOrUpdate(D);
      FBacklogRawItemIdByDataId.AddOrSetValue(D.DataId, RawId);

      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmFiniteCapacityPlanner.PersistAssignments;
var
  Asgs: TArray<TFCPAssignment>;
  Cmd: TADOCommand;
  Q: TADOQuery;
  AssignedNow: TList<Integer>;
  RawId, NodeId, CenterId, OrigDataId: Integer;
  D: TNodeData;
  CE, PID: string;
  Calc: TAbsInterval;
  FIniStr, FFinStr, DurStr, UdsStr, FNecStr: string;
  HasCalc: Boolean;

  function QS(const S: string): string;
  begin
    Result := '''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
  end;

  function QSOrNull(const S: string): string;
  begin
    if S = '' then Result := 'NULL' else Result := QS(S);
  end;

  function FmtDT(const DT: TDateTime): string;
  begin
    if DT <= 0 then Result := 'NULL'
    else Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', DT) + '''';
  end;

begin
  if (DMPlanner = nil) or not DMPlanner.IsConnected then Exit;
  if DMPlanner.CurrentProjectId <= 0 then Exit;

  Asgs := BuildAssignments;
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(DMPlanner.CurrentProjectId);

  AssignedNow := TList<Integer>.Create;
  DMPlanner.ADOConnection.BeginTrans;
  try
    for var I := 0 to High(Asgs) do
    begin
      OrigDataId := Asgs[I].DataId;
      CenterId := Asgs[I].CentreId;

      if OrigDataId > 0 then
      begin
        // Node existent: update CenterId (i dates si tenim càlcul).
        AssignedNow.Add(OrigDataId);
        HasCalc := FCalculatedTimes.TryGetValue(OrigDataId, Calc);

        Cmd := TADOCommand.Create(nil);
        try
          Cmd.Connection := DMPlanner.ADOConnection;
          if HasCalc then
            Cmd.CommandText :=
              'UPDATE FS_PL_Node SET CenterId = ' + IntToStr(CenterId) +
              ', FechaInicio = ' + FmtDT(Calc.S) +
              ', FechaFin = ' + FmtDT(Calc.E) +
              ' WHERE CodigoEmpresa = ' + CE +
              ' AND ProjectId = ' + PID +
              ' AND NodeId = ' + IntToStr(OrigDataId)
          else
            Cmd.CommandText :=
              'UPDATE FS_PL_Node SET CenterId = ' + IntToStr(CenterId) +
              ' WHERE CodigoEmpresa = ' + CE +
              ' AND ProjectId = ' + PID +
              ' AND NodeId = ' + IntToStr(OrigDataId);
          Cmd.Execute;
        finally
          Cmd.Free;
        end;
      end
      else
      begin
        // Backlog: crear Node + NodeData lligat al Raw_Item.
        if not FBacklogRawItemIdByDataId.TryGetValue(OrigDataId, RawId) then
          Continue;
        if not FNodeRepo.TryGetById(OrigDataId, D) then
          Continue;

        HasCalc := FCalculatedTimes.TryGetValue(OrigDataId, Calc);
        if HasCalc then
        begin
          FIniStr := FmtDT(Calc.S);
          FFinStr := FmtDT(Calc.E);
        end
        else
        begin
          FIniStr := 'NULL';
          FFinStr := 'NULL';
        end;
        if D.DurationMin > 0 then
          DurStr := FloatToStr(D.DurationMin, TFormatSettings.Invariant)
        else
          DurStr := '0';

        Cmd := TADOCommand.Create(nil);
        try
          Cmd.Connection := DMPlanner.ADOConnection;
          Cmd.CommandText :=
            'INSERT INTO FS_PL_Node (CodigoEmpresa, ProjectId, CenterId, ' +
            '  FechaInicio, FechaFin, DuracionMin, Caption, ColorFondo, ColorBorde) VALUES (' +
            CE + ', ' + PID + ', ' + IntToStr(CenterId) + ', ' +
            FIniStr + ', ' + FFinStr + ', ' + DurStr + ', ' +
            QS(D.Operacion) + ', 15251072, 11166760)';
          Cmd.Execute;
        finally
          Cmd.Free;
        end;

        Q := TADOQuery.Create(nil);
        try
          Q.Connection := DMPlanner.ADOConnection;
          Q.SQL.Text :=
            'SELECT MAX(NodeId) AS NewId FROM FS_PL_Node ' +
            'WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID;
          Q.Open;
          NodeId := Q.FieldByName('NewId').AsInteger;
        finally
          Q.Free;
        end;

        if D.UnidadesAFabricar > 0 then
          UdsStr := FloatToStr(D.UnidadesAFabricar, TFormatSettings.Invariant)
        else
          UdsStr := '1';
        FNecStr := FmtDT(D.FechaEntrega);

        Cmd := TADOCommand.Create(nil);
        try
          Cmd.Connection := DMPlanner.ADOConnection;
          Cmd.CommandText :=
            'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, ' +
            '  FechaEntrega, FechaNecesaria, CodigoCliente, ' +
            '  CodigoArticulo, DescripcionArticulo, ' +
            '  DuracionMin, DuracionMinOriginal, ' +
            '  UnidadesAFabricar, OperariosNecesarios, Prioridad, ' +
            '  RawItemClaveERP, RawItemTipoOrigen, ' +
            '  ColorFondoOp, ColorBordeOp) VALUES (' +
            CE + ', ' + IntToStr(NodeId) + ', ' + QS(D.Operacion) + ', ' +
            FNecStr + ', ' + FNecStr + ', ' + QS(D.CodigoCliente) + ', ' +
            QS(D.CodigoArticulo) + ', ' + QS(D.DescripcionArticulo) + ', ' +
            DurStr + ', ' + DurStr + ', ' +
            UdsStr + ', 1, ' + IntToStr(D.Prioridad) + ', ' +
            QSOrNull(D.RawItemClaveERP) + ', ' +
            QSOrNull(D.RawItemTipoOrigen) + ', ' +
            '15251072, 11166760)';
          Cmd.Execute;
        finally
          Cmd.Free;
        end;
      end;
    end;

    // Des-assignacions: DataIds inicialment al centre que ja no apareixen.
    for var J := 0 to FInitiallyAssignedDataIds.Count - 1 do
      if not AssignedNow.Contains(FInitiallyAssignedDataIds[J]) then
      begin
        Cmd := TADOCommand.Create(nil);
        try
          Cmd.Connection := DMPlanner.ADOConnection;
          Cmd.CommandText :=
            'UPDATE FS_PL_Node SET CenterId = NULL ' +
            'WHERE CodigoEmpresa = ' + CE +
            ' AND ProjectId = ' + PID +
            ' AND NodeId = ' + IntToStr(FInitiallyAssignedDataIds[J]);
          Cmd.Execute;
        finally
          Cmd.Free;
        end;
      end;

    DMPlanner.ADOConnection.CommitTrans;
  except
    on E: Exception do
    begin
      DMPlanner.ADOConnection.RollbackTrans;
      AssignedNow.Free;
      raise;
    end;
  end;
  AssignedNow.Free;

  // Refresc del repo central de nodes per al Gantt.
  DMPlanner.LoadNodes;
end;

procedure TfrmFiniteCapacityPlanner.FormHide(Sender: TObject);
begin
  // Auto-save quan es canvia de vista (Dashboard/Gantt). Si no s'ha
  // inicialitzat encara (FCentreColumns=nil), no fa res.
  if FCentreColumns <> nil then
    SaveNow;
end;

procedure TfrmFiniteCapacityPlanner.SaveNow;
begin
  try
    PersistAssignments;
  except
    on E: Exception do
      MessageDlg('Error al guardar asignaciones:' + sLineBreak + E.Message,
        mtError, [mbOK], 0);
  end;
end;

procedure TfrmFiniteCapacityPlanner.edtSearchChange(Sender: TObject);
begin
  FSearchFilter := Trim(edtSearch.Text);
  lblSearchClear.Visible := FSearchFilter <> '';
  BuildPendingList;
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.lblSearchClearClick(Sender: TObject);
begin
  edtSearch.Text := '';
  edtSearch.SetFocus;
end;

function TfrmFiniteCapacityPlanner.BuildAssignments: TArray<TFCPAssignment>;
var
  List: TList<TFCPAssignment>;
  Pair: TPair<Integer, TList<Integer>>;
  I: Integer;
  A: TFCPAssignment;
begin
  List := TList<TFCPAssignment>.Create;
  try
    for Pair in FCentreColumns.Assignments do
      for I := 0 to Pair.Value.Count - 1 do
      begin
        A.DataId := Pair.Value[I];
        A.CentreId := Pair.Key;
        A.SortIndex := I;
        List.Add(A);
      end;
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

procedure TfrmFiniteCapacityPlanner.OnEditCardLayoutClick(Sender: TObject);
var
  F: TfrmCardLayoutEditor;
begin
  F := TfrmCardLayoutEditor.Create(Self);
  try
    F.CustomFieldDefs := FCustomFieldDefs;
    F.Layout := FCentreColumns.CardLayout;
    F.LayoutToUI;
    if F.ShowModal = mrOk then
    begin
      FCentreColumns.CardLayout := F.Layout;
      FPendingList.CardLayout := F.Layout;
      FCentreColumns.Invalidate;
      FPendingList.Invalidate;
    end;
  finally
    F.Free;
  end;
end;

// ===========================================================================
// DROPDOWN "Filtros" (Estados + Operacion) - ancorat al boto del toolbar
// ===========================================================================

procedure TfrmFiniteCapacityPlanner.BuildFiltrosBtn;
var
  Lbl: TLabel;
begin
  FFiltrosBtn := TPanel.Create(Self);
  FFiltrosBtn.Parent := lblPendingTitle.Parent; // pnlPending
  FFiltrosBtn.SetBounds(pnlPending.Width - 120, 4, 76, 28);
  FFiltrosBtn.Anchors := [akTop, akRight];
  FFiltrosBtn.BevelOuter := bvNone;
  FFiltrosBtn.Color := pnlPending.Color;
  FFiltrosBtn.ParentBackground := False;
  FFiltrosBtn.Cursor := crHandPoint;
  FFiltrosBtn.OnClick := OnFiltrosBtnClick;

  Lbl := TLabel.Create(FFiltrosBtn);
  Lbl.Parent := FFiltrosBtn;
  Lbl.Align := alClient;
  Lbl.Alignment := taCenter;
  Lbl.Layout := tlCenter;
  Lbl.Caption := 'Filtros';
  Lbl.Font.Size := 9;
  Lbl.Font.Color := $00666666;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := OnFiltrosBtnClick;
  FFiltrosBtnLbl := Lbl;
  FFiltrosBtn.BringToFront;
end;

procedure TfrmFiniteCapacityPlanner.OnFiltrosBtnClick(Sender: TObject);
begin
  ShowFiltrosDropDown;
end;

procedure TfrmFiniteCapacityPlanner.ShowFiltrosDropDown;
var
  Dlg: TForm;
  pnlEstados, pnlOps, pnlBottom: TPanel;
  lblEstadosTitle, lblOpsTitle: TLabel;
  cb: TCheckBox;
  btnAll, btnNone, btnClose: TButton;
  Ops: TStringList;
  K, TopY: Integer;
  E: TNodoEstado;
  EstadoNames: array[TNodoEstado] of string;
const
  DD_W = 480;
  DD_H = 400;
  COL_W = 220;
  BOTTOM_H = 44;
begin
  EstadoNames[nePendiente]  := 'Pendiente';
  EstadoNames[neEnCurso]    := 'En curso';
  EstadoNames[neBloqueado]  := 'Bloqueado';
  EstadoNames[neFinalizado] := 'Finalizado';

  Dlg := TForm.CreateNew(Self);
  try
    Dlg.Caption := 'Filtros';
    Dlg.BorderStyle := bsDialog;
    Dlg.Position := poScreenCenter;
    Dlg.Color := clWhite;
    Dlg.ClientWidth := DD_W;
    Dlg.ClientHeight := DD_H;
    Dlg.Font.Name := 'Segoe UI';
    Dlg.Font.Size := 9;

    // Columna Estados (esquerra)
    pnlEstados := TPanel.Create(Dlg);
    pnlEstados.Parent := Dlg;
    pnlEstados.SetBounds(0, 0, COL_W, DD_H - BOTTOM_H);
    pnlEstados.BevelOuter := bvNone;
    pnlEstados.Color := clWhite;

    lblEstadosTitle := TLabel.Create(pnlEstados);
    lblEstadosTitle.Parent := pnlEstados;
    lblEstadosTitle.SetBounds(16, 12, 200, 18);
    lblEstadosTitle.Caption := 'Estados';
    lblEstadosTitle.Font.Style := [fsBold];
    lblEstadosTitle.Font.Color := $00444444;

    TopY := 40;
    for E := Low(TNodoEstado) to High(TNodoEstado) do
    begin
      cb := TCheckBox.Create(pnlEstados);
      cb.Parent := pnlEstados;
      cb.SetBounds(20, TopY, COL_W - 28, 22);
      cb.Caption := EstadoNames[E];
      cb.Checked := E in FEstadoFilter;
      cb.Tag := Ord(E);
      cb.OnClick := OnFiltrosEstadoChange;
      FFiltrosEstadoChecks[E] := cb;
      Inc(TopY, 28);
    end;

    // Columna Operacion (dreta)
    pnlOps := TPanel.Create(Dlg);
    pnlOps.Parent := Dlg;
    pnlOps.SetBounds(COL_W, 0, DD_W - COL_W, DD_H - BOTTOM_H);
    pnlOps.BevelOuter := bvNone;
    pnlOps.Color := clWhite;

    lblOpsTitle := TLabel.Create(pnlOps);
    lblOpsTitle.Parent := pnlOps;
    lblOpsTitle.SetBounds(12, 12, 200, 18);
    lblOpsTitle.Caption := 'Operaci'#243'n';
    lblOpsTitle.Font.Style := [fsBold];
    lblOpsTitle.Font.Color := $00444444;

    btnAll := TButton.Create(pnlOps);
    btnAll.Parent := pnlOps;
    btnAll.SetBounds(12, 36, 110, 26);
    btnAll.Caption := 'Marcar todas';
    btnAll.OnClick := OnFiltrosOpMarkAllClick;

    btnNone := TButton.Create(pnlOps);
    btnNone.Parent := pnlOps;
    btnNone.SetBounds(128, 36, 110, 26);
    btnNone.Caption := 'Desmarcar';
    btnNone.OnClick := OnFiltrosOpUnmarkAllClick;

    FFiltrosOpList := TCheckListBox.Create(pnlOps);
    FFiltrosOpList.Parent := pnlOps;
    FFiltrosOpList.SetBounds(12, 68, DD_W - COL_W - 24, DD_H - BOTTOM_H - 68 - 8);
    FFiltrosOpList.BorderStyle := bsSingle;
    FFiltrosOpList.Color := clWhite;
    FFiltrosOpList.Font.Name := 'Segoe UI';
    FFiltrosOpList.Font.Size := 9;
    FFiltrosOpList.OnClickCheck := OnFiltrosOpClick;

    Ops := TStringList.Create;
    try
      LoadOperacionesFromDB(Ops);
      if FOperacionFilter.Count = 0 then
        for K := 0 to Ops.Count - 1 do
          FOperacionFilter.Add(Ops[K]);
      for K := 0 to Ops.Count - 1 do
      begin
        FFiltrosOpList.Items.Add(Ops[K]);
        FFiltrosOpList.Checked[K] := FOperacionFilter.IndexOf(Ops[K]) >= 0;
      end;
    finally
      Ops.Free;
    end;

    // Panel inferior amb boto Cerrar
    pnlBottom := TPanel.Create(Dlg);
    pnlBottom.Parent := Dlg;
    pnlBottom.SetBounds(0, DD_H - BOTTOM_H, DD_W, BOTTOM_H);
    pnlBottom.BevelOuter := bvNone;
    pnlBottom.Color := $00F5F5F5;
    pnlBottom.Align := alBottom;

    btnClose := TButton.Create(pnlBottom);
    btnClose.Parent := pnlBottom;
    btnClose.SetBounds(DD_W - 110, 8, 96, 28);
    btnClose.Caption := 'Cerrar';
    btnClose.Default := True;
    btnClose.Cancel := True;
    btnClose.ModalResult := mrOk;

    Dlg.ShowModal;
  finally
    FFiltrosOpList := nil; // s'ha alliberat dins de Dlg.Free
    Dlg.Free;
  end;
end;

procedure TfrmFiniteCapacityPlanner.CloseFiltrosDropDown;
begin
  // Ja no aplica: el dialeg es modal i es tanca per si sol.
end;

procedure TfrmFiniteCapacityPlanner.OnFiltrosDropDownDeactivate(Sender: TObject);
begin
  // Ja no aplica al ser modal.
end;

procedure TfrmFiniteCapacityPlanner.OnFiltrosEstadoChange(Sender: TObject);
var
  cb: TCheckBox;
  E: TNodoEstado;
begin
  if not (Sender is TCheckBox) then Exit;
  cb := TCheckBox(Sender);
  E := TNodoEstado(cb.Tag);
  if cb.Checked then Include(FEstadoFilter, E)
                else Exclude(FEstadoFilter, E);
  BuildPendingList;
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.OnFiltrosOpClick(Sender: TObject);
var
  I, Idx: Integer;
  Op: string;
begin
  // Reconstruir FOperacionFilter des de l'estat checked actual
  FOperacionFilter.Clear;
  for I := 0 to FFiltrosOpList.Items.Count - 1 do
    if FFiltrosOpList.Checked[I] then
      FOperacionFilter.Add(FFiltrosOpList.Items[I]);

  // Si l'usuari ho ha desmarcat tot, posem una sentinel perque el filtre
  // s'apliqui (set buit = "totes les operacions visibles" segons la logica
  // de BuildPendingList).
  if FOperacionFilter.Count = 0 then
    FOperacionFilter.Add(#1);

  BuildPendingList;
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.OnFiltrosOpMarkAllClick(Sender: TObject);
var
  I: Integer;
begin
  if FFiltrosOpList = nil then Exit;
  FOperacionFilter.Clear;
  for I := 0 to FFiltrosOpList.Items.Count - 1 do
  begin
    FFiltrosOpList.Checked[I] := True;
    FOperacionFilter.Add(FFiltrosOpList.Items[I]);
  end;
  BuildPendingList;
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.OnFiltrosOpUnmarkAllClick(Sender: TObject);
var
  I: Integer;
begin
  if FFiltrosOpList = nil then Exit;
  for I := 0 to FFiltrosOpList.Items.Count - 1 do
    FFiltrosOpList.Checked[I] := False;
  FOperacionFilter.Clear;
  FOperacionFilter.Add(#1); // sentinel "tot exclos"
  BuildPendingList;
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityPlanner.CloseAllDropDowns;
begin
  // El TcxCheckComboBox de centres es tanca sol; el di\303\240leg "Filtros"
  // (Estados+Operacion) ja es modal centrat. No hi ha res a tancar manualment.
end;

procedure TfrmFiniteCapacityPlanner.WMMove(var Msg: TMessage);
begin
  inherited;
  CloseAllDropDowns;
end;

procedure TfrmFiniteCapacityPlanner.WMSize(var Msg: TMessage);
begin
  inherited;
  CloseAllDropDowns;
end;

end.
