unit uGanttControl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.DateUtils, System.Math,
  System.Classes, System.SysUtils, System.Types, System.UITypes,
  Vcl.Controls, Vcl.Graphics, System.Generics.Collections, System.Generics.Defaults,
  uGanttTypes, uCentreCalendar, Vcl.Menus, uNodeDataRepo, uGanttNodeHint,
  Vcl.Forms, Vcl.Direct2D, Winapi.D2D1, Winapi.DXGIFormat, uErpTypes, uGanttHistory,
  Vcl.ExtCtrls;

type
  TGanttViewportChangedEvent = procedure(Sender: TObject; const StartTime: TDateTime;
    const PxPerMinute, ScrollX: Single) of object;

  TGanttScrollYChangedEvent = procedure(Sender: TObject; const ScrollY: Single) of object;
  TNodeDblClickEvent = procedure(Sender: TObject; const NodeIndex: Integer) of object;
  TMarkerEvent = procedure(Sender: TObject; const MarkerId: Integer) of object;
  TMarkerMovedEvent = procedure(Sender: TObject; const MarkerId: Integer; const NewDateTime: TDateTime) of object;

  TGanttStatsChanged = procedure(Sender: TObject) of object;

  TGanttRenderMode = (grmNormalVCL, grmAdvancedD2D);

  TGetCalendarFunc = reference to function(const CentreId: Integer): TCentreCalendar;

  TIdxArray = TArray<Integer>;

  TResizeEdge = (reLeft, reRight, reMove);

  TDragMode = (dmNone, dmResize, dmMove);

  TLinksVisible = (lvNever, lvSelected, lvAlways);

  TNodeHandle = (nhNone, nhLeft, nhRight, nhMove);


  TGanttViewMode = (
    gvmNormal,
    gvmOptimitzacio,
    gvmFabricacio,
    gvmFechaEntrega,
    gvmStock,
    gvmOperarios,   // extra
    gvmCarga,          // extra (temps total segons unitats)
    gvmEstado,  //...estado OF (esPendiente, esEnCurso, esFinalizado, esBloqueado);
    gvmPrioridad,  //... Si tens prioritats A/B/C o 1..5:
    gvmRendimiento,
    gvmColores,
    gvmModificaciones
  );

  // 0=només el node, 1=per NumeroTrabajo, 2=per NumeroFabricacion+Serie
  TOpColorApplyType = (octOnlyNode, octByTrabajo, octByFabricacionSerie);

  TGanttNodeStyle = record
    Fill: TColor;
    Border: TColor;
    Alpha: Single;
    Text: TColor;
    BadgeText: string;
    BadgeFill: TColor;
    BadgeTextColor: TColor;
    Progress: Single;      // 0..1 ; <0 = no progress
    ProgressFill: TColor;
  end;

  TGanttControl = class(Vcl.Controls.TCustomControl)
  protected
    // Exposamos a descendientes (p.ej. TGanttControlGrupo) los campos y metodos
    // que el RebuildLayout override necesita. Mantener `protected` simplifica
    // la herencia en fase 6.2.
    FHistory: TGanttHistoryManager;

    FScrollX, FScrollY: Single;
    FPxPerMinute: Single;
    FStartTime: TDateTime;
    FEndTime: TDateTime;
    FLinksVisible: TLinksVisible;

    FSelectedNodeIndexes: TDictionary<Integer, Byte>;
    FFocusedNodeIndex: Integer;


    FCentres: TArray<TCentreTreball>;
    FNodes: TArray<TNode>;

    FNodeRepo: TNodeDataRepo;
    FDataIdToNodeIdxs: TDictionary<Integer, TList<Integer>>;

    FRows: TArray<TRowLayout>;
    FNodeLayouts: TArray<TNodeLayout>;

    FHoverNodeIndex: Integer;

    FStartVisibleTime, FEndVisibleTime : TDatetime;

    // pan
    FIsPanning: Boolean;
    FPanStart: TPoint;
    FScrollStartX, FScrollStartY: Single;

    FContentWidth: Integer;
    FContentHeight: Integer;

    FCalendars: TDictionary<Integer, TCentreCalendar>;

    FOnViewportChanged: TGanttViewportChangedEvent;
    FOnScrollYChanged: TGanttScrollYChangedEvent;
    FOnNodeDblClick: TNodeDblClickEvent;
    FOnFechaBloqueoChanged: TNotifyEvent;

    FCentreNodeIdx: TDictionary<Integer, TArray<Integer>>;

    FScrollInvalidateTimer: UINT_PTR;
    FPendingInvalidate: Boolean;
    FFastPaint: Boolean;
    FTimelineInteracting: Boolean;

    FDragMode: TDragMode;

    FLastMouseX: Integer;
    FLastMouseY: Integer;

    FMoving: Boolean;
    FMoveNodeIndex: Integer;
    FMoveOrigStart, FMoveOrigEnd: TDateTime;
    FMoveOrigCentreId: Integer;
    FMovePreviewStart, FMovePreviewEnd: TDateTime;
    FMovePreviewCentreId: Integer;
    FMoveGrabOffsetMins: Double; // offset en minuts visibles des del click fins l'inici del node
    FHasMoveNode: Boolean;
    FMoveRectS: TRectF;
    // si vols també per resize:

    FMinGapBetweenNodes: Integer; //...minuts de GAP entre nodes (0)

    FResizing: Boolean;
    FResizeEdge: TResizeEdge;
    FOrigStart, FOrigEnd: TDateTime;   // valors originals del node
    FPreviewStart, FPreviewEnd: TDateTime; // valors mentre arrossegues

    FResizeHandle: TNodeHandle;
    FResizeNodeIndex: Integer;     // NodeIndex (mateix que nl.NodeIndex)
    FResizeOrigStart: TDateTime;
    FResizeOrigEnd: TDateTime;
    FResizeMinMinutes: Integer;    // durada mínima en minuts
    FResizeSnapMinutes: Integer;   // snap (p.ex. 5)
    FHasResizeNode: Boolean;
    FResizeRectS: TRectF;

    FOnStatsChanged: TGanttStatsChanged;
    FOnLayoutChanged: TNotifyEvent;
    FOnNodeSelected: TNotifyEvent;
    FOnVoid: TNotifyEvent;

    FMouseDownPos: TPoint;
    FMouseDownNodeIndex: Integer;
    FMouseDownOnHandle: TNodeHandle;
    FDidDrag: Boolean;

    FNodePopupMenu: TPopupMenu;
    FGanttPopupMenu: TPopupMenu;

    FSearchResults: TArray<Integer>;
    FSearchPos: Integer;
    FHighlightSet: TDictionary<Integer, Byte>; // NodeIndex -> 1

    FOpFilterDataIds: TDictionary<Integer, Byte>; // DataId -> 1 (nodes a resaltar)
    FOpFilterActive: Boolean;
    FOpFilterHideMode: Boolean; // True = ocultar no filtrados; False = atenuar
    FOpFilterPulsePhase: Single; // 0..2*PI oscilación
    FOpFilterTimer: TTimer;

    // Link hover
    FHoverLinkIndex: Integer; // -1 = cap link hovered
    FLinkScreenPts: TArray<TPair<TPointF, TPointF>>; // from/to screen points per link

    // Link drag (Ctrl+drag des d'un handle per crear un link)
    FLinkDragging: Boolean;
    FLinkFromNodeIndex: Integer;
    FLinkFromEdge: TResizeEdge;   // reRight = FinishStart, reLeft = StartStart/StartFinish
    FLinkPreviewEnd: TPointF;     // posició actual del cursor (screen)

    FMarqueeSelecting: Boolean;
    FMarqueeStartPt: TPoint;
    FMarqueeCurrentPt: TPoint;
    FDashOffset: Single;


    FHintWnd: TGanttNodeHintWindow;
    FHintNodeIndex: Integer;
    FHintShown: Boolean;
    FRenderMode: TGanttRenderMode;

    FLinks: TArray<TErpLink>;
    FOpIdToNodeIndex: TDictionary<Integer, Integer>;
    FNodeIndexToLayoutIndex: TDictionary<Integer, Integer>;

    // --- índexos ràpids per resolució de constraints ---
    FNodeIdToIndex: TDictionary<Integer, Integer>;         // NodeId -> NodeIndex
    FSuccessors: TDictionary<Integer, TList<Integer>>;     // NodeId -> llista de link-index a FLinks (sortints)
    FPredecessors: TDictionary<Integer, TList<Integer>>;   // NodeId -> llista de link-index a FLinks (entrants)
    FCentreIdToIsSeq: TDictionary<Integer, Boolean>;       // CentreId -> IsSequencial
    FCentreIdToIdx: TDictionary<Integer, Integer>;         // CentreId -> index dins FCentres

    FFechaBloqueo: TDateTime;
    FDraggingBloqueo: Boolean;
    FDragOffsetX: Single;      // offset entre click i la línia
    FHoverBloqueo: Boolean;

    // Markers
    FMarkers: TArray<TGanttMarker>;
    FNextMarkerId: Integer;
    FDraggingMarkerId: Integer;   // -1 = cap
    FMarkerDragOffsetX: Single;
    FHoverMarkerId: Integer;      // -1 = cap
    FMouseDownMarkerId: Integer;  // -1 = cap (pendent de drag threshold)
    FAutoMarkersEnabled: Boolean;
    FOnMarkerClick: TMarkerEvent;
    FOnMarkerDblClick: TMarkerEvent;
    FOnMarkerMoved: TMarkerMovedEvent;

    FVista: TGanttViewMode;

    FCNT_TotalNodes: Integer;
    FCNT_TotalVisibleNodes: Integer;
    FCNT_TotalModifiedNodes: Integer;
    FCNT_TotalNodes_StateNormal: Integer;
    FCNT_TotalNodes_StateYellow: Integer;
    FCNT_TotalNodes_StateOrange: Integer;
    FCNT_TotalNodes_StateRed: Integer;
    FCNT_TotalNodes_StateGreen: Integer;

    FHideWeekends: Boolean;

    procedure NormalizeStartTime;
    procedure SetHideWeekends(const Value: Boolean);
    function VisibleMinutesBetween( const AFromTime, AToTime: TDateTime): Double;
    function AddVisibleMinutes( const AStart: TDateTime; const AVisibleMinutes: Double): TDateTime;

    function GetCanUndo: Boolean;
    function GetCanRedo: Boolean;
    function GetUndoCount: Integer;
    function GetRedoCount: Integer;


    function GetMarqueeRect: TRect;
    procedure SelectNodesInMarquee(const AddToSelection: Boolean);
    function IsMarqueeLargeEnough: Boolean;
    procedure DrawMarqueeD2D(const RT: ID2D1RenderTarget);
    function GetNodeRectPx(const NodeIndex: Integer; out R: TRect): Boolean;
    procedure SetVista(const Value: TGanttViewMode);

    function BloqueoX: Single;
    function HitTestBloqueo(const X, Y: Single): Boolean;
    procedure SetFechaBloqueoFromX(const X: Single);
    procedure SetFechaBloqueo(const Value: TDateTime);

    function IsValidNodeIndex(const AIndex: Integer): Boolean;
    function GetNodeMidTime(const AIndex: Integer): TDateTime;
    function GetReferenceTimeForNavigation: TDateTime;
    function FindFirstNodeIndex: Integer;
    function FindLastNodeIndex: Integer;
    function FindNextNodeIndex(const ARefTime: TDateTime): Integer;
    function FindPreviousNodeIndex(const ARefTime: TDateTime): Integer;
    function CalcScrollXToCenterDate(const ADate: TDateTime): Single;
    procedure CenterNodeByIndex(const AIndex: Integer; const ASelectNode: Boolean = True);


    procedure SetLinksVisible(const Value: TLinksVisible);

    procedure SetRenderMode(const Value: TGanttRenderMode);
    procedure HideNodeHint;
    procedure ShowNodeHint(const NodeIndex: Integer; const MouseScreen: TPoint);
    function BuildNodeHintText(const NodeIndex: Integer): string;

    procedure ClearDataIdIndex;
    procedure BuildDataIdIndex;

    procedure RebuildGraphIndex;

    procedure StartScrollInvalidateTimer;
    procedure StopScrollInvalidateTimer;
    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;

    procedure ScrollByPixels(const dx, dy: Integer; const ScrollRect: TRect);

    procedure BuildCentreNodeIndex;
    function GetNodeIndexesForCentre(const ACentreId: Integer): TArray<Integer>;
    function TryGetRowByCentreId(const ACentreId: Integer; out Row: TRowLayout): Boolean;
    function CalcLaneTop(const Row: TRowLayout; const Centre: TCentreTreball;
                const LaneIndex: Integer): Single;

    function ResolveSequentialCollisionsFromNode(
              const CentreId: Integer;
              const ChangedIdx: Integer;
              const MinGapMin: Integer;
              out MovedNodes: TIdxArray): Boolean;

    function ResolveNonSequentialCollisionsFromNode(
              const CentreId: Integer;
              const ChangedIdx: Integer;
              out MovedNodes: TIdxArray): Boolean;

    function ResolveAllConstraintsFromNode( const ChangedIdx: Integer; const MinGapMin: Integer): Boolean;

    function GetMinStartAllowedByPredecessors(const NodeIdx: Integer;  out HasConstraint: Boolean): TDateTime;

    function FindFreeLaneForMovePreview(
                const CentreId: Integer;
                const XLeftW, XRightW: Single;
                const LaneCount: Integer
              ): Integer;

    function ClampNodeToPredecessors( const NodeIdx: Integer): Boolean;
    procedure CommitNodeMoveOrResize(const NodeIdx: Integer);

    procedure DrawDependenciesD2D(
                const VisibleXLeft, VisibleXRight, VisibleYTop, VisibleYBottom: Single;
                const RT: ID2D1RenderTarget;
                const StrokeBrush: ID2D1SolidColorBrush;
                const FillBrush: ID2D1SolidColorBrush);

    function GetNodeRectWorldForLinks(const NodeIndex: Integer): TRectF;

    procedure AddRowLayout(const Row: TRowLayout);
    procedure AddNodeLayout(const NL: TNodeLayout);


    procedure TimelineViewportChanged(Sender: TObject;
                 const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);

    procedure SetPxPerMinute(const Value: Single);

    function ClientToWorld(const P: TPoint): TPointF;
    function TimeToXWorld(const T: TDateTime): Single;
    function TimeToX(const ATime: TDateTime): Single;
    procedure GetVisibleTimeRange(out T0, T1: TDateTime);

    function RowTopToScreenY(const AWorldY: Single): Single;
    function WorldYToScreenY(const AWorldY: Single): Single;



    function HitTestNodeIndex(const X, Y: Single): Integer;

    function TryGetNonWorkingIntervalAt(
                const CentreId: Integer;
                const T: TDateTime;
                out AStartNW, AEndNW: TDateTime
              ): Boolean;
    function AdjustToWorkingForward(const CentreId: Integer; const T: TDateTime): TDateTime;
    function AdjustToWorkingBackward(const CentreId: Integer; const T: TDateTime): TDateTime;

    procedure TimelineNeedRepaint(Sender: TObject);

    function ComputeFastPaint(const Interacting: Boolean;
                 const StartVis, EndVis: TDateTime): Boolean;

    function UpdateFastPaint(const Interacting: Boolean;
                 const StartVis, EndVis: TDateTime): Boolean;


    procedure DrawNonWorkingShading(const CentreId: Integer; const RowTop, RowBottom: Single);
    procedure DrawNonWorkingShadingRow(const CentreId: Integer; const GanttRectS: TRectF);
    procedure DrawNonWorkingShadingRowD2D(
              const CentreId: Integer;
              const GanttRectS: TRectF;
              const VisibleStart, VisibleEnd: TDateTime;
              const RT: ID2D1RenderTarget;
              const FillBrush: ID2D1SolidColorBrush;
              const DotBrush: ID2D1BitmapBrush);

    procedure DrawTimeGridRow(const GanttRectS: TRectF);

    function IsCentreEnabled(const CentreId: Integer): Boolean;
    function IsCentreSequecial(const CentreId: Integer): Boolean;

    procedure UpdateScrollBars;

    function TryGetNodeLayoutRectWorld(const NodeIndex: Integer; out R: TRectF): Boolean;

    function RowTopYByCentreId(const CentreId: Integer): Single;

    function LaneCollidesX(
                const CentreId: Integer; const LaneIdx: Integer;
                const XLeftW, XRightW: Single; const SkipNodeIndex: Integer): Boolean;

    function FindNearestFreeLane(
                const CentreId: Integer; const PreferredLane: Integer;
                const XLeftW, XRightW: Single; const LaneCount: Integer; const SkipNodeIndex: Integer): Integer;

    procedure DrawDayGridLinesD2D(
                const RT: ID2D1RenderTarget;
                const GridBrush: ID2D1SolidColorBrush;
                const ClientW, ClientH: Single);

    procedure DrawNowLineDashedD2D(
                const RT: ID2D1RenderTarget;
                const NowBrush: ID2D1SolidColorBrush;
                const ClientW, ClientH: Single);

    procedure DrawBloqueoLineD2D(
                const RT: ID2D1RenderTarget;
                const LineBrush, HandleBrush: ID2D1SolidColorBrush;
                const ClientW, ClientH: Single);

    procedure DrawBlockedAreaD2D(
                const RT: ID2D1RenderTarget;
                const FillBrush, HatchBrush: ID2D1SolidColorBrush;
                const ClientW, ClientH: Single);

    procedure DrawMarkersD2D(
                const D2D: TDirect2DCanvas;
                const RT: ID2D1RenderTarget;
                const LineBrush: ID2D1SolidColorBrush;
                const ClientW, ClientH: Single);
    function HitTestMarker(const ScreenX: Single; const Tolerance: Single = 5.0): Integer;
    procedure SetAutoMarkersEnabled(const Value: Boolean);
    procedure UpdateAutoMarkers;
    procedure ClearAutoMarkers;


    //...per RESIZE NODES
    function TryGetNonWorkingIntervalMergedAt(
                    const CentreId: Integer;
                    const T: TDateTime;
                    const ARadiusDays: Integer;
                    out AStart, AEnd: TDateTime
                  ): Boolean;

    function AdjustToWorkingForwardMerged(
                    const CentreId: Integer;
                    const T: TDateTime;
                    const ARadiusDays: Integer
                  ): TDateTime;

    function AdjustToWorkingBackwardMerged(
                    const CentreId: Integer;
                    const T: TDateTime;
                    const ARadiusDays: Integer
                  ): TDateTime;

    procedure SetNodeTimes(const NodeIndex: Integer; const NewStart, NewEnd: TDateTime);
    procedure GetNodeTimes(const NodeIndex: Integer; out AStart, AEnd: TDateTime);

    procedure StartResizeNode(const NodeId: Integer; const Edge: TResizeEdge);
    procedure UpdateResizePreview(const MouseX: Single);

    procedure StartMoveNode(const NodeIndex: Integer; const MouseX, MouseY: Integer);
    procedure UpdateMovePreview(const MouseX, MouseY: Integer);
    function CentreIdFromScreenY(const ScreenY: Integer): Integer;

    procedure ApplyResizeToModel(const NodeIdx: Integer;
                const AStart, AEnd: TDateTime; const ADurMin: Integer);

    procedure CommitResize;
    procedure CommitMove;

    function IsCentreVisible(const ACentreId: Integer): Boolean;
    function IsRowVisible(const ARowIndex: Integer): Boolean; virtual;

    procedure OpFilterTimerTick(Sender: TObject);
    function HitTestLink(const X, Y: Single; const Tolerance: Single = 6.0): Integer;
    procedure GetNodeStyle(
                    const Node: TNode; const D: TNodeData; const HasData: Boolean;
                    const IsSel, IsHover, IsHi: Boolean; out S: TGanttNodeStyle);

    function MakeNodeSnapshot(const ANodeIdx: Integer): TNodePlanSnapshot;
    procedure ApplyNodeSnapshot(const ASnap: TNodePlanSnapshot);

  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMHScroll(var Message: TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;

    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure WMMouseHWheel(var Message: TWMMouseWheel); message WM_MOUSEHWHEEL;
    procedure WMContextMenu(var Message: TWMContextMenu);
    procedure WMLButtonDblClk(var Message: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;

    procedure Paint; override;
    procedure PaintD2D; virtual;
    procedure Resize; override;

    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    function ClampPxPerMinute(const Value: Single): Single;
    function MaxScrollX: Single;
    function ClampScrollX(const Value: Single): Single;

    procedure SetScrollX(const Value: Single);

    procedure DrawSelectedNodeHandlesD2D(
                const RT: ID2D1RenderTarget;
                const FillBrush, StrokeBrush: ID2D1SolidColorBrush);

    function HitTestSelectedNodeHandle(const X, Y: Integer; out Edge: TResizeEdge): TNodeHandle;

    function IsCentreSequencial(const CentreId: Integer): Boolean;

    procedure DrawProgressBarD2D(const RT: ID2D1RenderTarget; const Brush: ID2D1SolidColorBrush;
      const R: TRectF; const P: Single);


    procedure DrawBadgeD2D(const D2D: TDirect2DCanvas; const RT: ID2D1RenderTarget;
      const FillBrush, TextBrush: ID2D1SolidColorBrush; const R: TRectF; const Text: string;
      const FillC, TextC: TColor);

    function SameOF(const ANode1, ANode2: Integer): Boolean;
    function TryGetNodeData(const ANodeIndex: Integer; out AData: TNodeData): Boolean;
    function NodeMatchesOF(
                const ANodeIndex: Integer;
                const ANumeroOF: Integer;
                const ASerieOF: string
              ): Boolean;

    function FindFirstNodeIndexOfOF( const ANumeroOF: Integer; const ASerieOF: string ): Integer;
    function FindFirstOFNodeIndex: Integer;
    function FindLastOFNodeIndex: Integer;

    //function FindFirstNodeIndexOfOF(const ANumeroOF: Integer; const ASerieOF: string): Integer;
    //function FindNextOFStartNodeIndex: Integer;

  public
    FClickPoint: TPoint;
    FClickDatetime: TDatetime;

    procedure TimelineInteraction(Sender: TObject; const Interacting: Boolean);
    procedure NotifyViewportChanged;

    procedure GoToNextNode;
    procedure GoToPreviousNode;
    procedure GoToFirstNode;
    procedure GoToLastNode;

    procedure GoToPrevOF;
    procedure GoToNextOF;

    property HideWeekends: Boolean read FHideWeekends write SetHideWeekends;

    procedure MarkAllNodesModified(const AValue: Boolean);

    function CalcEndTime(const CentreId: Integer; const StartTime: TDateTime; const DurationMin: Double): TDateTime;
    function CalcStartFromEnd(const CentreId: Integer; const EndTime: TDateTime; const DurationMin: Double): TDateTime;

    function ApplyOpColorsByNode(
      const ADataID: Integer;
      const AType: TOpColorApplyType;
      const ANewBkColorOp, ANewBorderColorOp: TColor;
      const AsOT: string = '';
      const AsOF: string = '';
      const AiOF: Integer = 0
    ): Integer;

    procedure RebuildOpIdIndex;
    procedure RebuildNodeLayoutIndex;
    procedure RebuildAfterModelChange(const RebuildNodeIndexMap: Boolean);
    procedure ResetNodeDuration(const ANodeIndex: Integer);

    //...SELECT functions
    procedure ClearSelection;
    procedure SelectNodeIndex( const AIndex: Integer;  const AClearPrevious: Boolean = True);
    procedure ToggleNodeIndexSelection(const AIndex: Integer);
    function IsNodeIndexSelected(const AIndex: Integer): Boolean;
    function IsNodeFocused(const AIndex: Integer): Boolean;

    procedure RecalcCounters;

    procedure SetLinks(const ALinks: TArray<TErpLink>);
    function GetLinks: TArray<TErpLink>;
    procedure UpdateLinkDependencia(const AToNodeId: Integer; const ANewPct: Double);
    procedure UpdateLinkAt(const AIndex: Integer; const ALink: TErpLink);
    procedure AddLink(const ALink: TErpLink);
    procedure RemoveLinkAt(const AIndex: Integer);
    function GetLinksForNode(const ANodeId: Integer): TArray<Integer>; // indices dins FLinks

    procedure UpdateNode(const NodeIndex: Integer; const ANode: TNode);
    function GetRowsCopy: TArray<TRowLayout>;
    function SelectedNodeIndex: Integer;
    function SelectedNode: TNode;
    function GetSelectedNodeIndexes: TArray<Integer>;

    function XToTime(const AX: Single): TDateTime;

    procedure SetNodeRepo(const ARepo: TNodeDataRepo);

    function FindNodesByOF(const NumeroOF: Integer; const Serie: string): TArray<Integer>;      // NodeIndex[]
    function FindNodesByTrabajo(const NumeroTrabajo: string): TArray<Integer>;                  // NodeIndex[]
    function FindNodeIndexById(const NodeId: Integer): Integer;
    function FindNodeLayoutIndexByNodeIndex(const NodeIndex: Integer): Integer;


    //...funcions per moure nodes dependents
    function ArrayContainsIdx(const A: TIdxArray; const Value: Integer): Boolean;
    procedure ArrayAddUnique(var A: TIdxArray; const Value: Integer);
    procedure ArrayClear(var A: TIdxArray);
    function GetDependencyMinStart(  const PredIdx: Integer;  const PercentDependency: Double): TDateTime;
    function ApplyNodeCalendarAndOverlay( const CentreId: Integer;  const T: TDateTime): TDateTime;
    function MoveNodeKeepingDuration(   const NodeIdx: Integer;   const NewStart: TDateTime): Boolean;
    function ResolveDependenciesFromNode( const ChangedIdx: Integer;  out MovedNodes: TIdxArray): Boolean;


     //...history UNDO function
    procedure CollectDependentNodeIndexes( const AStartIdx: Integer; var AResult: TIdxArray);
    procedure CollectCentreNodeIndexes( const ACentreId: Integer;  var AResult: TIdxArray);
    function CollectAffectedNodeIndexesFromNode(const AStartIdx: Integer): TIdxArray;
    function CaptureSnapshotsFromNodePropagation( const AStartIdx: Integer): TArray<TNodePlanSnapshot>;
    function BuildNodeHistoryChanges( const ABefore, AAfter: TArray<TNodePlanSnapshot>): TArray<TNodeHistoryChange>;
    function BuildHistoryEntry(  const AActionType: TGanttHistoryActionType;  const ACaption: string;
                  const ASourceNodeIndex: Integer;
                  const AChanges: TArray<TNodeHistoryChange>): TGanttHistoryEntry;
    procedure UndoLastAction;
    procedure RedoLastAction;


    function ShiftLeftSequentialCentresFromDate( const AFromTime: TDateTime; const MinGapMin: Integer): Boolean;
    function ShiftLeftAllImpactedSequentialFromDate( const AFromTime: TDateTime; const MinGapMin: Integer): Boolean;
    function ShiftLeftAllImpactedSequentialFromNode( const ANodeIdx: Integer;  const MinGapMin: Integer): Boolean;
    function CompactOFFromNode(const ANodeIdx: Integer; const MinGapMin: Integer; const AllOF: Boolean = False; const bForce: Boolean = False): Boolean;
    function BackwardScheduleOF(const ANodeIdx: Integer; const AEndDate: TDateTime; const MinGapMin: Integer; const bForce: Boolean = False): Boolean;

    function CompactOTFromNode(const ANodeIdx: Integer; const MinGapMin: Integer; const AllOT: Boolean = False; const bForce: Boolean = False): Boolean;
    function BackwardScheduleOT(const ANodeIdx: Integer; const AEndDate: TDateTime; const MinGapMin: Integer; const bForce: Boolean = False): Boolean;

    function ReplanAllFromDate(const AFromDate: TDateTime; const MinGapMin: Integer;
      out ElapsedMs: Int64; out MovedCount: Integer): Boolean;
    function ReplanAllFromDateV2(const AFromDate: TDateTime; const MinGapMin: Integer;
      out ElapsedMs: Int64; out MovedCount: Integer): Boolean;

    procedure SelectNodeByIndex(const NodeIndex: Integer; const EnsureVisible: Boolean = True);
    procedure ScrollNodeIntoView(const NodeIndex: Integer; const Center: Boolean = True);

    function GetDateTimeFromPoint(X, Y: Single): TDateTime;
    function GetCentreIdFromPoint(X, Y: Single): Integer;
    function GetNonWorkingIntervalFromPointMerged(
              X, Y: Single;
              out AStart, AEnd: TDateTime;
              out ACentreId: Integer;
              const ARadiusDays: Integer
            ): Boolean;

    function GetCentreByIndex(const Index: Integer): TCentreTreball;
    procedure GetPrevNextNodeInCentre(
                    const CentreId, NodeIndex: Integer;
                    out PrevIdx, NextIdx: Integer);


    function FindCentreIndexById(const CentreId: Integer): Integer;
    procedure UpdateCentre(const CentreId: Integer; const ACentre: TCentreTreball);

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ApplyScrollYFromCentres(const AScrollY: Single);

    procedure RebuildLayout; virtual; // sync, MVP

    function GetCalendar(const CentreId: Integer): TCentreCalendar;

    procedure SetViewport(const AStartTime: TDateTime; const APxPerMinute, AScrollX: Single);
    procedure SetTimeRange(const AStart, AEnd: TDateTime);

    procedure SetData(const ACentres: TArray<TCentreTreball>; const ANodes: TArray<TNode>; const AStartTime: TDateTime);


    function GetNodes: TArray<TNode>;
    function NodeCount: Integer;
    function GetNodeAt(const Index: Integer): TNode;

    property OnScrollYChanged: TGanttScrollYChangedEvent read FOnScrollYChanged write FOnScrollYChanged;
    property OnFechaBloqueoChanged: TNotifyEvent read FOnFechaBloqueoChanged write FOnFechaBloqueoChanged;
    property NodePopupMenu: TPopupMenu read FNodePopupMenu write FNodePopupMenu;
    property GanttPopupMenu: TPopupMenu read FGanttPopupMenu write FGanttPopupMenu;
    property ScrollX: Single read FScrollX write SetScrollX;
    property FechaBloqueo: TDateTime read FFechaBloqueo write SetFechaBloqueo;

    procedure ClearSearch;
    procedure SetSearchResults(const NodeIndexes: TArray<Integer>; const AutoSelectFirst: Boolean = True);
    function SearchResultCount: Integer;
    function SearchResultIndex: Integer; // posició actual (0..count-1) o -1
    function SearchCurrentNodeIndex: Integer; // NodeIndex actual o -1
    procedure SearchNext(const Wrap: Boolean = True);
    procedure SearchPrev(const Wrap: Boolean = True);
    function IsNodeHighlighted(const NodeIndex: Integer): Boolean;
    procedure HighlightOF(const ANodeIndex: Integer);
    procedure HighlightOT(const ANodeIndex: Integer);

    procedure SetOperarioFilter(const ADataIds: TArray<Integer>; AHideMode: Boolean);
    procedure ClearOperarioFilter;
    function IsNodeOperarioFiltered(const ADataId: Integer): Boolean;



    property CanUndo: Boolean read GetCanUndo;
    property CanRedo: Boolean read GetCanRedo;
    property UndoCount: Integer read GetUndoCount;
    property RedoCount: Integer read GetRedoCount;

    // Markers
    function AddMarker(const AMarker: TGanttMarker): Integer;
    procedure RemoveMarker(const AMarkerId: Integer);
    procedure ClearMarkers;
    function GetMarkers: TArray<TGanttMarker>;
    function MarkerCount: Integer;
    function FindMarkerAt(const ScreenX: Single; const Tolerance: Single = 5.0): Integer;

    property AutoMarkersEnabled: Boolean read FAutoMarkersEnabled write SetAutoMarkersEnabled;
    property OnMarkerClick: TMarkerEvent read FOnMarkerClick write FOnMarkerClick;
    property OnMarkerDblClick: TMarkerEvent read FOnMarkerDblClick write FOnMarkerDblClick;
    property OnMarkerMoved: TMarkerMovedEvent read FOnMarkerMoved write FOnMarkerMoved;

  published
    property PopupMenu;

    property CNT_TotalNodes: Integer read FCNT_TotalNodes;
    property CNT_TotalVisibleNodes: Integer read FCNT_TotalVisibleNodes;
    property CNT_TotalModifiedNodes: Integer read FCNT_TotalModifiedNodes;
    property CNT_TotalNodes_StateNormal: Integer read FCNT_TotalNodes_StateNormal;
    property CNT_TotalNodes_StateYellow: Integer read FCNT_TotalNodes_StateYellow;
    property CNT_TotalNodes_StateOrange: Integer read FCNT_TotalNodes_StateOrange;
    property CNT_TotalNodes_StateRed: Integer read FCNT_TotalNodes_StateRed;
    property CNT_TotalNodes_StateGreen: Integer read FCNT_TotalNodes_StateGreen;

    property StartVisibleTime: TDateTime read FStartVisibleTime;
    property EndVisibleTime: TDateTime read FEndVisibleTime;
    property StartTime: TDateTime read FStartTime;
    property EndTime: TDateTime read FEndTime;

    property Align;
    property Vista: TGanttViewMode read FVista write SetVista default gvmNormal;
    property LinksVisible: TLinksVisible    read FLinksVisible    write SetLinksVisible    default lvSelected;
    property RenderMode: TGanttRenderMode read FRenderMode write SetRenderMode default grmNormalVCL;
    property PxPerMinute: Single read FPxPerMinute write SetPxPerMinute;
    property OnViewportChanged: TGanttViewportChangedEvent read FOnViewportChanged write FOnViewportChanged;
    property OnNodeDblClick: TNodeDblClickEvent read FOnNodeDblClick write FOnNodeDblClick;
    property OnStatsChanged: TGanttStatsChanged read FOnStatsChanged write FOnStatsChanged;
    property OnLayoutChanged: TNotifyEvent read FOnLayoutChanged write FOnLayoutChanged;
    property OnNodeSelected: TNotifyEvent read FOnNodeSelected write FOnNodeSelected;
    property OnVoid: TNotifyEvent read FOnVoid write FOnVoid;
  end;




const
  HANDLE_R = 6.0;      // radi (pixels)
  HANDLE_PAD = 3.0;    // separació respecte el node
  NW_RADIUS_DAYS = 30;  // o 10 si només vacances curtes; 30 cobreix bastant

  NODE_INNER_PAD_TOP = 5;
  NODE_INNER_PAD_BOTTOM = 5;
  NODE_MIN_HEIGHT = 23;
  LANEGAP = 5;

  DRAG_THRESHOLD = 4;
  TAG_AUTO_MARKER = -999;  // Tag reservat per markers automàtics

  //...colors Nodes segons Vista
// Verd viu
  COL_OK_FILL        = TColor($0064D94C);
  COL_OK_BORDER      = TColor($0046B41E); // RGB( 30,180, 70)
  // Groc viu  RGB(255,204,  0)
  COL_WARN_FILL      = TColor($0000CCFF);
  COL_WARN_BORDER    = TColor($0000AAE6); // RGB(230,170,  0)
  // Vermell viu real RGB(255, 82, 82)
  COL_BAD_FILL       = TColor($005252FF);
  COL_BAD_BORDER     = TColor($002828DC); // RGB(220, 40, 40)
  // Gris
  COL_NEUTRAL_FILL   = TColor($00FFE6CC); // RGB(210,210,210)
  COL_NEUTRAL_BORDER = TColor($00CC9966); // RGB(160,160,160)
  // Gris
  COL_DISABLED_FILL   = TColor($00D2D2D2); // RGB(210,210,210)
  COL_DISABLED_BORDER = TColor($00A0A0A0); // RGB(160,160,160)
  // Blau viu RGB(  0,122,255)
  COL_INFO_FILL      = TColor($00FF7A00);
  COL_INFO_BORDER    = TColor($00C85A00); // RGB(0,90,200)

implementation

uses uGanttHelpers, uErpSampleBuilder, uGanttTimeline, Main, System.Diagnostics;

{ ── TLaneOccupancy: registre temporal d'ocupació per lanes (centres no-seqüencials) ── }

type
  TLaneSlot = record
    StartT, EndT: TDateTime;
  end;

  TLaneOccupancy = class
    Lanes: TDictionary<Integer, TList<TLaneSlot>>;
    MaxLanes: Integer;
    constructor Create(AMaxLanes: Integer);
    destructor Destroy; override;
    function Collides(ALane: Integer; AStart, AEnd: TDateTime): Boolean;
    procedure Add(ALane: Integer; AStart, AEnd: TDateTime);
    function FindFreeLaneOrShift(var AStart: TDateTime; ADurationMin: Double;
      ACentreId: Integer; AGantt: TGanttControl): Integer;
  end;

constructor TLaneOccupancy.Create(AMaxLanes: Integer);
begin
  inherited Create;
  Lanes := TDictionary<Integer, TList<TLaneSlot>>.Create;
  MaxLanes := AMaxLanes;
end;

destructor TLaneOccupancy.Destroy;
var L: TList<TLaneSlot>;
begin
  for L in Lanes.Values do
    L.Free;
  Lanes.Free;
  inherited;
end;

function TLaneOccupancy.Collides(ALane: Integer; AStart, AEnd: TDateTime): Boolean;
var
  Slots: TList<TLaneSlot>;
  S: TLaneSlot;
begin
  Result := False;
  if not Lanes.TryGetValue(ALane, Slots) then Exit;
  for S in Slots do
    if (AStart < S.EndT) and (AEnd > S.StartT) then
      Exit(True);
end;

procedure TLaneOccupancy.Add(ALane: Integer; AStart, AEnd: TDateTime);
var
  Slots: TList<TLaneSlot>;
  S: TLaneSlot;
begin
  if not Lanes.TryGetValue(ALane, Slots) then
  begin
    Slots := TList<TLaneSlot>.Create;
    Lanes.Add(ALane, Slots);
  end;
  S.StartT := AStart;
  S.EndT := AEnd;
  Slots.Add(S);
end;

function TLaneOccupancy.FindFreeLaneOrShift(var AStart: TDateTime;
  ADurationMin: Double; ACentreId: Integer; AGantt: TGanttControl): Integer;
var
  LaneIdx, NumLanes, Attempt: Integer;
  TestStart, TestEnd: TDateTime;
  EarliestEnd: TDateTime;
  Slots: TList<TLaneSlot>;
  S: TLaneSlot;
begin
  if MaxLanes > 0 then
    NumLanes := MaxLanes
  else
    NumLanes := Lanes.Count + 1;

  TestStart := AStart;

  for Attempt := 0 to 999 do
  begin
    TestEnd := AGantt.CalcEndTime(ACentreId, TestStart, ADurationMin);

    // Provar cada lane
    for LaneIdx := 0 to NumLanes - 1 do
    begin
      if not Collides(LaneIdx, TestStart, TestEnd) then
      begin
        AStart := TestStart;
        Result := LaneIdx;
        Exit;
      end;
    end;

    // Si MaxLanes = 0, crear lane nova
    if MaxLanes = 0 then
    begin
      AStart := TestStart;
      Result := NumLanes;
      Exit;
    end;

    // Totes les lanes ocupades: buscar el primer forat temporal
    EarliestEnd := TestStart + 365;
    for LaneIdx := 0 to NumLanes - 1 do
    begin
      if Lanes.TryGetValue(LaneIdx, Slots) then
        for S in Slots do
          if (TestStart < S.EndT) and (TestEnd > S.StartT) then
            if S.EndT < EarliestEnd then
              EarliestEnd := S.EndT;
    end;

    TestStart := AGantt.ApplyNodeCalendarAndOverlay(ACentreId, EarliestEnd);

    if TestStart <= AStart then
      TestStart := IncMinute(AStart, 1);

    AStart := TestStart;
  end;

  // Fallback
  Result := 0;
end;


{ TGanttControl Helpers}


  function D2DColorFromTColor(const AColor: TColor; const Alpha01: Single = 1.0): TD2D1ColorF;
  var
    c: TColor;
    r, g, b: Byte;
  begin
    c := ColorToRGB(AColor);
    r := GetRValue(c);
    g := GetGValue(c);
    b := GetBValue(c);

    Result.r := r / 255.0;
    Result.g := g / 255.0;
    Result.b := b / 255.0;
    Result.a := EnsureRange(Alpha01, 0.0, 1.0);
  end;

  procedure SetBrushColor(const B: ID2D1SolidColorBrush; const AColor: TColor; const Alpha01: Single = 1.0);
  var
    cf: TD2D1ColorF;
  begin
    cf := D2DColorFromTColor(AColor, Alpha01);
    B.SetColor(cf);
  end;

function CreateDotPatternBrush(const RT: ID2D1RenderTarget): ID2D1BitmapBrush;
const
  W = 8;
  H = 8;
var
  Pixels: array[0..W * H - 1] of Cardinal;
  bmp: ID2D1Bitmap;
  bmpProps: TD2D1BitmapProperties;
  brushProps: TD2D1BitmapBrushProperties;
  pixFmt: TD2D1PixelFormat;
  i: Integer;

  function PremulBGRA(const R, G, B, A: Byte): Cardinal;
  var
    pr, pg, pb: Integer;
  begin
    pr := (R * A + 127) div 255;
    pg := (G * A + 127) div 255;
    pb := (B * A + 127) div 255;
    Result := Cardinal(pb) or (Cardinal(pg) shl 8) or
              (Cardinal(pr) shl 16) or (Cardinal(A) shl 24);
  end;

  procedure PutDot(const X, Y: Integer; const A: Byte);
  begin
    Pixels[Y * W + X] := PremulBGRA(120, 120, 120, A);
  end;

begin
  for i := 0 to High(Pixels) do
    Pixels[i] := 0;

  //PutDot(1, 1, 90);
  //PutDot(5, 5, 90);
  {
  PutDot(1, 1, 90);
  PutDot(1, 3, 90);
  PutDot(1, 5, 90);
  PutDot(1, 7, 90);
  PutDot(3, 1, 90);
  PutDot(3, 3, 90);
  PutDot(3, 5, 90);
  PutDot(3, 7, 90);
  PutDot(5, 1, 90);
  PutDot(5, 3, 90);
  PutDot(5, 5, 90);
  PutDot(5, 7, 90);
  PutDot(7, 1, 90);
  PutDot(7, 3, 90);
  PutDot(7, 5, 90);
  PutDot(7, 7, 90);
  }
  PutDot(1, 1, 150);
  PutDot(1, 3, 150);
  PutDot(1, 5, 150);
  PutDot(1, 7, 150);
  PutDot(3, 1, 150);
  PutDot(3, 3, 150);
  PutDot(3, 5, 150);
  PutDot(3, 7, 150);
  PutDot(5, 1, 150);
  PutDot(5, 3, 150);
  PutDot(5, 5, 150);
  PutDot(5, 7, 150);
  PutDot(7, 1, 150);
  PutDot(7, 3, 150);
  PutDot(7, 5, 150);
  PutDot(7, 7, 150);

  pixFmt := D2D1PixelFormat(
    DXGI_FORMAT_B8G8R8A8_UNORM,
    D2D1_ALPHA_MODE_PREMULTIPLIED
  );

  bmpProps := D2D1BitmapProperties(pixFmt, 96, 96);

  if Failed(RT.CreateBitmap(
    D2D1SizeU(W, H),
    @Pixels[0],
    W * SizeOf(Cardinal),
    bmpProps,
    bmp)) then
    Exit(nil);

  brushProps.extendModeX := D2D1_EXTEND_MODE_WRAP;
  brushProps.extendModeY := D2D1_EXTEND_MODE_WRAP;
  brushProps.interpolationMode := D2D1_BITMAP_INTERPOLATION_MODE_NEAREST_NEIGHBOR;

  if Failed(RT.CreateBitmapBrush(
    bmp,
    @brushProps,
    nil,
    Result)) then
    Result := nil;
end;


// Crea un brush de bitmap 8x8 amb línies diagonals '\' del color especificat
function CreateDiagonalPatternBrush(const RT: ID2D1RenderTarget;
  const R, G, B: Byte; const Alpha: Byte): ID2D1BitmapBrush;
const
  W = 8;
  H = 8;
var
  Pixels: array[0..W * H - 1] of Cardinal;
  bmp: ID2D1Bitmap;
  bmpProps: TD2D1BitmapProperties;
  brushProps: TD2D1BitmapBrushProperties;
  pixFmt: TD2D1PixelFormat;
  i: Integer;

  function PremulBGRA(const PR, PG, PB, A: Byte): Cardinal;
  var
    pr2, pg2, pb2: Integer;
  begin
    pr2 := (PR * A + 127) div 255;
    pg2 := (PG * A + 127) div 255;
    pb2 := (PB * A + 127) div 255;
    Result := Cardinal(pb2) or (Cardinal(pg2) shl 8) or
              (Cardinal(pr2) shl 16) or (Cardinal(A) shl 24);
  end;

begin
  for i := 0 to High(Pixels) do
    Pixels[i] := 0;

  // Dues línies diagonals '\' per tile de 8x8 (espaiat de 4 pixels)
  Pixels[0*W+0] := PremulBGRA(R,G,B,Alpha);
  Pixels[1*W+1] := PremulBGRA(R,G,B,Alpha);
  Pixels[2*W+2] := PremulBGRA(R,G,B,Alpha);
  Pixels[3*W+3] := PremulBGRA(R,G,B,Alpha);
  Pixels[4*W+4] := PremulBGRA(R,G,B,Alpha);
  Pixels[5*W+5] := PremulBGRA(R,G,B,Alpha);
  Pixels[6*W+6] := PremulBGRA(R,G,B,Alpha);
  Pixels[7*W+7] := PremulBGRA(R,G,B,Alpha);
  Pixels[0*W+4] := PremulBGRA(R,G,B,Alpha);
  Pixels[1*W+5] := PremulBGRA(R,G,B,Alpha);
  Pixels[2*W+6] := PremulBGRA(R,G,B,Alpha);
  Pixels[3*W+7] := PremulBGRA(R,G,B,Alpha);
  Pixels[4*W+0] := PremulBGRA(R,G,B,Alpha);
  Pixels[5*W+1] := PremulBGRA(R,G,B,Alpha);
  Pixels[6*W+2] := PremulBGRA(R,G,B,Alpha);
  Pixels[7*W+3] := PremulBGRA(R,G,B,Alpha);

  pixFmt := D2D1PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED);
  bmpProps := D2D1BitmapProperties(pixFmt, 96, 96);

  if Failed(RT.CreateBitmap(D2D1SizeU(W, H), @Pixels[0], W * SizeOf(Cardinal), bmpProps, bmp)) then
    Exit(nil);

  brushProps.extendModeX := D2D1_EXTEND_MODE_WRAP;
  brushProps.extendModeY := D2D1_EXTEND_MODE_WRAP;
  brushProps.interpolationMode := D2D1_BITMAP_INTERPOLATION_MODE_NEAREST_NEIGHBOR;

  if Failed(RT.CreateBitmapBrush(bmp, @brushProps, nil, Result)) then
    Result := nil;
end;


procedure TGanttControl.DrawDependenciesD2D(
  const VisibleXLeft, VisibleXRight, VisibleYTop, VisibleYBottom: Single;
  const RT: ID2D1RenderTarget;
  const StrokeBrush: ID2D1SolidColorBrush;
  const FillBrush: ID2D1SolidColorBrush);
var
  L: TErpLink;

  fromNodeIdx, toNodeIdx: Integer;
  fromLayoutIdx, toLayoutIdx: Integer;
  rFromW, rToW, rFromS, rToS: TRectF;
  fromPt, toPt: TPointF;
  dotted: ID2D1StrokeStyle;

  Adj: TObjectDictionary<Integer, TList<Integer>>;
  Visited: TDictionary<Integer, Byte>;
  Q: TQueue<Integer>;

  function RectTouchesView(const R: TRectF): Boolean;
  begin
    Result := (R.Right >= VisibleXLeft) and (R.Left <= VisibleXRight) and
              (R.Bottom >= VisibleYTop) and (R.Top <= VisibleYBottom);
  end;

  procedure AddEdge(const A, B: Integer);
  var
    lst: TList<Integer>;
  begin
    if not Adj.TryGetValue(A, lst) then
    begin
      lst := TList<Integer>.Create;
      Adj.Add(A, lst);
    end;
    lst.Add(B);
  end;

  procedure BuildAdjacency;
  var
    i: Integer;
  begin
    // Graf NO dirigit per connectivitat: afegim A<->B
    for i := 0 to High(FLinks) do
    begin
      L := FLinks[i];
      if not FOpIdToNodeIndex.TryGetValue(L.FromNodeId, fromNodeIdx) then Continue;
      if not FOpIdToNodeIndex.TryGetValue(L.ToNodeId,   toNodeIdx)   then Continue;

      AddEdge(fromNodeIdx, toNodeIdx);
      AddEdge(toNodeIdx, fromNodeIdx);
    end;
  end;

  procedure BuildConnectedComponentFromSelected;
  var
    cur, nb: Integer;
    lst: TList<Integer>;
    i: Integer;
  begin
    Visited.Clear;
    Q.Clear;

    Visited.AddOrSetValue(FFocusedNodeIndex, 1);
    Q.Enqueue(FFocusedNodeIndex);

    while Q.Count > 0 do
    begin
      cur := Q.Dequeue;

      if not Adj.TryGetValue(cur, lst) then
        Continue;

      for i := 0 to lst.Count - 1 do
      begin
        nb := lst[i];
        if not Visited.ContainsKey(nb) then
        begin
          Visited.AddOrSetValue(nb, 1);
          Q.Enqueue(nb);
        end;
      end;
    end;
  end;

  procedure ApplyPreviewRectsForLink;
  begin
    // Si el node del link és el que s'està movent, agafa EXACTAMENT el rect preview que ja pintes (MoveRectS)
    // MoveRectS és SCREEN -> el passem a WORLD sumant scroll perquè el pipeline aquí treballa en WORLD
    if FMoving and FHasMoveNode then
    begin
      if fromNodeIdx = FMoveNodeIndex then
      begin
        rFromW := FMoveRectS;
        rFromW.Offset(FScrollX, FScrollY); // SCREEN -> WORLD
      end;

      if toNodeIdx = FMoveNodeIndex then
      begin
        rToW := FMoveRectS;
        rToW.Offset(FScrollX, FScrollY);   // SCREEN -> WORLD
      end;
    end;

    // Si vols també “enganxar” dependencies durant resize, i tens un rect preview en SCREEN (p.ex. ResizeRectS),
    // aplica el mateix patró aquí.
    // Si NO tens ResizeRectS, ho deixarà a GetNodeRectWorldForLinks (com ara).

    if FResizing and FHasResizeNode then
    begin
      if fromNodeIdx = FResizeNodeIndex then
      begin
        rFromW := FResizeRectS;
        rFromW.Offset(FScrollX, FScrollY);
      end;
      if toNodeIdx = FResizeNodeIndex then
      begin
        rToW := FResizeRectS;
        rToW.Offset(FScrollX, FScrollY);
      end;
    end;

  end;

begin
  SetLength(FLinkScreenPts, 0); // netejar punts hover del frame anterior

  if Length(FLinks) = 0 then Exit;
  if (FOpIdToNodeIndex = nil) then Exit;
  if (FNodeIndexToLayoutIndex = nil) then Exit;

  // ===== visibilitat =====
  if FLinksVisible = lvNever then
    Exit;

  if (FLinksVisible = lvSelected) and (FFocusedNodeIndex < 0) then
    Exit;

  dotted := CreateDottedStrokeStyle(RT);

  // color base (gris fosc suau)
  StrokeBrush.SetColor(D2D1ColorF(0.45, 0.45, 0.45, 0.85));
  FillBrush.SetColor(D2D1ColorF(0.45, 0.45, 0.45, 0.85));

  Adj := TObjectDictionary<Integer, TList<Integer>>.Create([doOwnsValues]);
  Visited := TDictionary<Integer, Byte>.Create;
  Q := TQueue<Integer>.Create;
  try
    if FLinksVisible = lvSelected then
    begin
      BuildAdjacency;
      BuildConnectedComponentFromSelected;
      // ara Visited = tots els nodes connectats (recursiu) al seleccionat
    end;

    for L in FLinks do
    begin
      if not FOpIdToNodeIndex.TryGetValue(L.FromNodeId, fromNodeIdx) then Continue;
      if not FOpIdToNodeIndex.TryGetValue(L.ToNodeId,   toNodeIdx)   then Continue;

      // ===== filtre recursiu =====
      if (FLinksVisible = lvSelected) then
      begin
        // pintem només links on AMBDÓS nodes són dins del component connectat
        if (not Visited.ContainsKey(fromNodeIdx)) or (not Visited.ContainsKey(toNodeIdx)) then
          Continue;
      end;

      if not FNodeIndexToLayoutIndex.TryGetValue(fromNodeIdx, fromLayoutIdx) then Continue;
      if not FNodeIndexToLayoutIndex.TryGetValue(toNodeIdx,   toLayoutIdx)   then Continue;

      // Rects base (WORLD)
      rFromW := GetNodeRectWorldForLinks(fromNodeIdx);
      rToW   := GetNodeRectWorldForLinks(toNodeIdx);

      // IMPORTANT: si estàs movent, substitueix pel preview real
      ApplyPreviewRectsForLink;

      if rFromW.IsEmpty or rToW.IsEmpty then
        Continue;

      if (not RectTouchesView(rFromW)) and (not RectTouchesView(rToW)) then
        Continue;

      // world->screen
      rFromS := rFromW; rFromS.Offset(-FScrollX, -FScrollY);
      rToS   := rToW;   rToS.Offset(-FScrollX, -FScrollY);

      fromPt := PointF(rFromS.Right, (rFromS.Top + rFromS.Bottom) * 0.5);
      toPt   := PointF(rToS.Left,    (rToS.Top + rToS.Bottom) * 0.5);

      // Guardar punts per hit-test hover
      SetLength(FLinkScreenPts, Length(FLinkScreenPts) + 1);
      FLinkScreenPts[High(FLinkScreenPts)] := TPair<TPointF, TPointF>.Create(fromPt, toPt);

      // Resaltar si hovered
      var linkDrawIdx: Integer := High(FLinkScreenPts);
      var sw: Single;
      var linkStyle: ID2D1StrokeStyle;
      if linkDrawIdx = FHoverLinkIndex then
      begin
        sw := 3.5;
        StrokeBrush.SetColor(D2D1ColorF(0.35, 0.60, 0.95, 1.0)); // blau clar
        FillBrush.SetColor(D2D1ColorF(0.35, 0.60, 0.95, 1.0));
        linkStyle := nil; // línia contínua
      end
      else
      begin
        sw := 1.2;
        StrokeBrush.SetColor(D2D1ColorF(0.45, 0.45, 0.45, 0.85));
        FillBrush.SetColor(D2D1ColorF(0.45, 0.45, 0.45, 0.85));
        linkStyle := dotted;
      end;

      DrawCurvedArrowD2D(
        RT,
        StrokeBrush,
        FillBrush,
        fromPt,
        toPt,
        linkStyle,
        sw,
        10,
        8
      );
    end;

  finally
    Q.Free;
    Visited.Free;
    Adj.Free;
  end;
end;




procedure TGanttControl.DrawSelectedNodeHandlesD2D(
  const RT: ID2D1RenderTarget;
  const FillBrush, StrokeBrush: ID2D1SolidColorBrush);
var
  idx, iCentreIdx: Integer;
  nl: TNodeLayout;
  r: TRectF;
  cy, cxL, cxR, rowTop: Single;
  ell: TD2D1Ellipse;
  activeL, activeR: Boolean;
  radL, radR: Single;
  M, oldM: TD2D1Matrix3x2F;
begin
  if FFocusedNodeIndex < 0 then Exit;

  // localitza layout del node seleccionat
  idx := FindNodeLayoutIndexByNodeIndex(FFocusedNodeIndex);
  if idx < 0 then Exit;

  nl := FNodeLayouts[idx];
  r := nl.Rect;

  // si estem redimensionant aquest node, fes servir preview per Left/Right
  if FResizing and (FResizeNodeIndex = nl.NodeIndex) then
  begin
    r.Left  := TimeToXWorld(FPreviewStart); // world
    r.Right := TimeToXWorld(FPreviewEnd); // world
    if r.Right < r.Left then
    begin
      var tmp := r.Left; r.Left := r.Right; r.Right := tmp;
    end;
  end;

   // MOVE preview: usa el rect preview ja calculat (SCREEN) si el tens
  if FMoving and (FMoveNodeIndex = nl.NodeIndex) and FHasMoveNode then
  begin
    r := FMoveRectS; // SCREEN
  end
  else
  begin
    // WORLD -> SCREEN
    r.Offset(-FScrollX, -FScrollY);
  end;
  {
  if FMoving and (FMoveNodeIndex = nl.NodeIndex) and FHasMoveNode then
  begin
    r.Left  := TimeToX(FMovePreviewStart) + FScrollX; // world
    r.Right := TimeToX(FMovePreviewEnd)   + FScrollX; // world
    if r.Right < r.Left then
    begin
      var tmp := r.Left; r.Left := r.Right; r.Right := tmp;
    end;

    // Y preview (WORLD) -> igual que al node preview
    iCentreIdx := FindCentreIndexById(FMovePreviewCentreId);
    if (iCentreIdx >= 0) and FCentres[iCentreIdx].IsSequencial then
      rowTop := RowTopYByCentreId(FMovePreviewCentreId)
    else
      rowTop := r.Top - NODE_INNER_PAD_TOP; // manté lane original (NOSEQUENCIAL)
    r.Offset(0, (rowTop + NODE_INNER_PAD_TOP) - r.Top);
  end;
  }
  // world -> screen
  //r.Offset(-FScrollX, -FScrollY);

  cy := (r.Top + r.Bottom) * 0.5;
  cxL := r.Left  - HANDLE_PAD - HANDLE_R;
  cxR := r.Right + HANDLE_PAD + HANDLE_R;

  activeL := FResizing and (FResizeEdge = reLeft);
  activeR := FResizing and (FResizeEdge = reRight);

  radL := HANDLE_R;
  radR := HANDLE_R;

  // identitat (segur)
  {
  RT.GetTransform(oldM);
  M._11 := 1; M._12 := 0;
  M._21 := 0; M._22 := 1;
  M._31 := 0; M._32 := 0;
  RT.SetTransform(M);

  }
  try
    // Left
    ell.point := D2D1PointF(cxL, cy);
    ell.radiusX := radL;
    ell.radiusY := radL;
    if activeL then
    begin
      SetBrushColor(FillBrush, clYellow, 1.0);   // ple
      SetBrushColor(StrokeBrush, clBlack, 1.0);
      RT.FillEllipse(ell, FillBrush);
      RT.DrawEllipse(ell, StrokeBrush, 2.0);     // stroke més gruixut
    end
    else
    begin
      SetBrushColor(FillBrush, clYellow, 0.85);
      SetBrushColor(StrokeBrush, clBlack, 0.9);
      RT.FillEllipse(ell, FillBrush);
      RT.DrawEllipse(ell, StrokeBrush, 1.0);
    end;

    // Right
    ell.point := D2D1PointF(cxR, cy);
    ell.radiusX := radR;
    ell.radiusY := radR;
    if activeR then
    begin
      SetBrushColor(FillBrush, clYellow, 1.0);
      SetBrushColor(StrokeBrush, clBlack, 1.0);
      RT.FillEllipse(ell, FillBrush);
      RT.DrawEllipse(ell, StrokeBrush, 2.0);
    end
    else
    begin
      SetBrushColor(FillBrush, clYellow, 0.85);
      SetBrushColor(StrokeBrush, clBlack, 0.9);
      RT.FillEllipse(ell, FillBrush);
      RT.DrawEllipse(ell, StrokeBrush, 1.0);
    end;
  finally
   // RT.SetTransform(oldM);
  end;
end;


{procedure TGanttControl.DrawSelectedNodeHandlesD2D(
  const RT: ID2D1RenderTarget;
  const FillBrush, StrokeBrush: ID2D1SolidColorBrush);
var
  idx: Integer;
  nl: TNodeLayout;
  r: TRectF;
  cy, cxL, cxR: Single;
  ellL, ellR: TD2D1Ellipse;

  function FindNodeLayoutIndexByNodeIndex(const NodeIndex: Integer): Integer;
  var
    j: Integer;
  begin
    Result := -1;
    for j := 0 to High(FNodeLayouts) do
      if FNodeLayouts[j].NodeIndex = NodeIndex then
        Exit(j);
  end;

begin
  if FSelectedNodeIndex < 0 then Exit;

  idx := FindNodeLayoutIndexByNodeIndex(FSelectedNodeIndex);
  if idx < 0 then Exit;

  nl := FNodeLayouts[idx];

  // world -> screen
  r := nl.Rect;
  r.Offset(-FScrollX, -FScrollY);

  // culling (si el node no es veu, no pintem handles)
  if (r.Right < 0) or (r.Left > ClientWidth) or (r.Bottom < 0) or (r.Top > ClientHeight) then
    Exit;

  cy := (r.Top + r.Bottom) * 0.5;

  // Centres X: FORA del node
  cxL := r.Left  - HANDLE_PAD - HANDLE_R;
  cxR := r.Right + HANDLE_PAD + HANDLE_R;

  // Si queda totalment fora de la pantalla, pots saltar (opcional)
  if (cxR < -HANDLE_R) or (cxL > ClientWidth + HANDLE_R) then
    Exit;

  ellL := D2D1Ellipse(D2D1PointF(cxL, cy), HANDLE_R, HANDLE_R);
  ellR := D2D1Ellipse(D2D1PointF(cxR, cy), HANDLE_R, HANDLE_R);

  // Pintar per sobre: fill blanc + stroke negre (ajusta colors si vols)
  SetBrushColor(FillBrush, clYellow, 1.0);
  RT.FillEllipse(ellL, FillBrush);
  RT.FillEllipse(ellR, FillBrush);

  SetBrushColor(StrokeBrush, clBlack, 1.0);
  RT.DrawEllipse(ellL, StrokeBrush, 2.0);
  RT.DrawEllipse(ellR, StrokeBrush, 2.0);
end;
}


function TGanttControl.IsCentreSequencial(const CentreId: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(FCentres) do
    if FCentres[i].Id = CentreId then
      Exit(FCentres[i].IsSequencial);
end;


function TGanttControl.HitTestSelectedNodeHandle(const X, Y: Integer; out Edge: TResizeEdge): TNodeHandle;
var
  idx: Integer;
  nl: TNodeLayout;
  r: TRectF;
  cy, cxL, cxR: Single;
  dx, dy: Single;



begin
  Result := nhNone;
  Edge := reRight; // valor per defecte (no s'usa si nhNone)

  if FFocusedNodeIndex < 0 then Exit;

  idx := FindNodeLayoutIndexByNodeIndex(FFocusedNodeIndex);
  if idx < 0 then Exit;

  nl := FNodeLayouts[idx];

  // world -> screen
  r := nl.Rect;
  r.Offset(-FScrollX, -FScrollY);

  cy := (r.Top + r.Bottom) * 0.5;

  cxL := r.Left  - HANDLE_PAD - HANDLE_R;
  cxR := r.Right + HANDLE_PAD + HANDLE_R;

  // left circle
  dx := X - cxL;
  dy := Y - cy;
  if (dx*dx + dy*dy) <= (HANDLE_R * HANDLE_R) then
  begin
    Edge := reLeft;
    Exit(nhLeft);
  end;

  // right circle
  dx := X - cxR;
  dy := Y - cy;
  if (dx*dx + dy*dy) <= (HANDLE_R * HANDLE_R) then
  begin
    Edge := reRight;
    Exit(nhRight);
  end;
end;


function MinutesToDays(const Mins: Integer): Double;
begin
  Result := Mins / (24 * 60);
end;
function SnapDateTimeToMinutes(const T: TDateTime; const SnapMins: Integer): TDateTime;
var
  base, fracVal: Double;
  mins: Double;
  snappedMins: Integer;
begin
  if SnapMins <= 1 then
    Exit(T);
  base := Int(T);        // dia
  fracVal := Frac(T);       // part horària
  mins := fracVal * 24 * 60;
  // arrodonim al múltiple més proper
  snappedMins := Round(mins / SnapMins) * SnapMins;
  // clamp 0..1440
  snappedMins := EnsureRange(snappedMins, 0, 24*60);
  Result := base + (snappedMins / (24 * 60));
end;
function ClampDateTime(const T, MinT, MaxT: TDateTime): TDateTime;
begin
  Result := T;
  if Result < MinT then Result := MinT;
  if Result > MaxT then Result := MaxT;
end;

//******** END HELPERS *********************************************************




constructor TGanttControl.Create(AOwner: TComponent);
var
  hr: HRESULT;
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque, csDoubleClicks];
  DoubleBuffered := True;

  FFechaBloqueo := 0;

  FVista := gvmNormal;

  FDashOffset := 0;
  FHideWeekends := False;

  FResizing := False;
  FResizeHandle := nhNone;
  FResizeNodeIndex := -1;
  FResizeMinMinutes := 5;   // mínim 5 minuts (canvia-ho)
  FResizeSnapMinutes := 5;  // snap a 5 minuts (canvia-ho)

  FMoving := False;
  FMoveNodeIndex := -1;

  FDragMode := dmNone;

  FMinGapBetweenNodes := 0;

  FMouseDownNodeIndex := -1;
  FMouseDownOnHandle := nhNone;
  FDidDrag := False;


  FLinksVisible := lvSelected; // valor per defecte
  FRenderMode := grmAdvancedD2D;

  FPxPerMinute := 2.0; // zoom inicial: 2 px/min
  FStartTime := Now;

  FHoverNodeIndex := -1;
  FHoverLinkIndex := -1;
  FLinkDragging := False;
  FLinkFromNodeIndex := -1;
  FSelectedNodeIndexes := TDictionary<Integer, Byte>.Create;
  FFocusedNodeIndex := -1;

  FCalendars := TDictionary<Integer, TCentreCalendar>.Create;
  FCentreNodeIdx := TDictionary<Integer, TArray<Integer>>.Create;
  FHighlightSet := TDictionary<Integer, Byte>.Create;
  FOpFilterDataIds := TDictionary<Integer, Byte>.Create;
  FOpFilterActive := False;
  FOpFilterHideMode := False;
  FOpFilterPulsePhase := 0;
  FOpFilterTimer := TTimer.Create(Self);
  FOpFilterTimer.Interval := 25; // ~40 fps
  FOpFilterTimer.Enabled := False;
  FOpFilterTimer.OnTimer := OpFilterTimerTick;
  FSearchPos := -1;

  FHintWnd := TGanttNodeHintWindow.Create(Self);
  FHintNodeIndex := -1;
  FHintShown := False;

  FDraggingBloqueo := False;

  // Markers
  FNextMarkerId := 1;
  FDraggingMarkerId := -1;
  FHoverMarkerId := -1;
  FMouseDownMarkerId := -1;
  FAutoMarkersEnabled := False;

  FHistory := TGanttHistoryManager.Create(200);
end;

destructor TGanttControl.Destroy;
var
  cal: TCentreCalendar;
begin
  for cal in FCalendars.Values do
    cal.Free;
  FCalendars.Free;
  FCentreNodeIdx.Free;
  FHighlightSet.Free;
  FOpFilterDataIds.Free;

  FSelectedNodeIndexes.Free;

  HideNodeHint;

  FHistory.Free;

  // Alliberar índexos de graf
  FNodeIdToIndex.Free;
  if FSuccessors <> nil then
  begin
    for var lst in FSuccessors.Values do lst.Free;
    FSuccessors.Free;
  end;
  if FPredecessors <> nil then
  begin
    for var lst in FPredecessors.Values do lst.Free;
    FPredecessors.Free;
  end;
  FCentreIdToIsSeq.Free;
  FCentreIdToIdx.Free;

  inherited;
end;



function TGanttControl.MakeNodeSnapshot(const ANodeIdx: Integer): TNodePlanSnapshot;
begin
  Result.NodeIndex := ANodeIdx;
  Result.StartTime := FNodes[ANodeIdx].StartTime;
  Result.EndTime := FNodes[ANodeIdx].EndTime;
  Result.Duration := FNodes[ANodeIdx].DurationMin;
end;


procedure TGanttControl.ApplyNodeSnapshot(const ASnap: TNodePlanSnapshot);
var
  idx: Integer;
begin
  idx := ASnap.NodeIndex;

  if (idx < 0) or (idx > High(FNodes)) then
    Exit;

  FNodes[idx].StartTime := ASnap.StartTime;
  FNodes[idx].EndTime := ASnap.EndTime;
  FNodes[idx].DurationMin := ASnap.Duration;
end;

procedure TGanttControl.SetLinksVisible(const Value: TLinksVisible);
begin
  if FLinksVisible <> Value then
  begin
    FLinksVisible := Value;
    Invalidate; // repinta perquè canviï la visibilitat dels links
  end;
end;

procedure TGanttControl.SetNodeTimes(const NodeIndex: Integer; const NewStart, NewEnd: TDateTime);
begin
  // Ajusta aquests noms al teu TNode real:
  FNodes[NodeIndex].StartTime := NewStart;
  FNodes[NodeIndex].EndTime := NewEnd;
end;

procedure TGanttControl.GetNodeTimes(const NodeIndex: Integer; out AStart, AEnd: TDateTime);
begin
  AStart := FNodes[NodeIndex].StartTime;
  AEnd := FNodes[NodeIndex].EndTime;
end;

procedure TGanttControl.SetTimeRange(const AStart, AEnd: TDateTime);
var
  newStart, newEnd: TDateTime;
begin
  newStart := DayStart(AStart);
  newEnd   := DayEnd(AEnd);
  if newEnd < newStart then
    newEnd := DayEnd(newStart);
  // si no canvia res → sortir
  if (FStartTime = newStart) and (FEndTime = newEnd) then
    Exit;
  FStartTime := newStart;
  FEndTime   := newEnd;
  // IMPORTANT: recalcular layout perquè depèn del temps
  RebuildLayout;
  // Ajust scroll per quedar dins rang
  if FScrollX > (FContentWidth - ClientWidth) then
    FScrollX := Max(0, FContentWidth - ClientWidth);
  UpdateScrollBars;
  Invalidate;
  NotifyViewportChanged;
end;

procedure TGanttControl.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  HideNodeHint;
end;

function TGanttControl.BuildNodeHintText(const NodeIndex: Integer): string;
var
  n: TNode;
  d: TNodeData;

  function CentresPermesosText: string;
  var
    i, k: Integer;
    parts: TArray<string>;
    nom: string;
  begin
    if Length(d.CentresPermesos) = 0 then
      Exit('(tots)');
    SetLength(parts, Length(d.CentresPermesos));
    for i := 0 to High(d.CentresPermesos) do
    begin
      nom := '#' + IntToStr(d.CentresPermesos[i]); // fallback si no trobat
      for k := 0 to High(FCentres) do
        if FCentres[k].Id = d.CentresPermesos[i] then
        begin
          nom := FCentres[k].Titulo;
          if FCentres[k].Subtitulo <> '' then
            nom := nom + ' / ' + FCentres[k].Subtitulo;
          Break;
        end;
      parts[i] := nom;
    end;
    Result := String.Join(', ', parts);
  end;

begin
  Result := '';
  if (NodeIndex < 0) or (NodeIndex > High(FNodes)) then Exit;
  if FNodeRepo = nil then Exit;

  n := FNodes[NodeIndex];

  if (n.DataId = 0) or (not FNodeRepo.TryGetById(n.DataId, d)) then
    Exit;

  // Maquetació (pots canviar ordre/camps)
  Result :=
    'Node Index: ' + inttostr(NodeIndex) + sLineBreak +
    'Node Id: ' + inttostr(n.Id) + sLineBreak +
    'Start time: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', n.StartTime) + sLineBreak +
    'End time: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', n.EndTime) + sLineBreak +
    'Centres treball: ' + String.Join(', ', d.CentresTrabajo) + sLineBreak +
    'Centres permesos: ' + CentresPermesosText + sLineBreak +
    'Operación: ' + d.Operacion + sLineBreak +
    'Orden Fabricación: ' + IntToStr(d.NumeroOrdenFabricacion) + ' ' + d.SerieFabricacion + sLineBreak +
    'Orden Trabajo: ' + d.NumeroTrabajo + sLineBreak +
    'Cliente: ' + d.CodigoCliente + sLineBreak +
    'Artículo: ' + d.CodigoArticulo + ' - ' + d.DescripcionArticulo + sLineBreak +
    'Stock: ' + FormatFloat('0.##', d.Stock) + sLineBreak +
    'Fecha Entrega: ' + FormatDateTime('dd/mm/yyyy', d.FechaEntrega) + sLineBreak +
    'Fecha Necesaria: ' + FormatDateTime('dd/mm/yyyy', d.FechaNecesaria) + sLineBreak +
    'Unidades A Fabricar: ' + FormatFloat('0.##', d.UnidadesAFabricar) + sLineBreak +
    'Unidades Fabricadas: ' + FormatFloat('0.##', d.UnidadesFAbricadas) + sLineBreak +
    'Porcentaje fabricado: ' + FormatFloat('0.##', (d.UnidadesFAbricadas / d.UnidadesAFabricar) * 100) +'%' + sLineBreak +
    'Tiempo Fabricacion Unidad (sec): ' + FormatFloat('0.##', d.TiempoUnidadFabSecs) + sLineBreak +
    'Duración (min): ' + FormatFloat('0.##', d.DurationMin) + sLineBreak +
    'DuraciónOriginal (min): ' + FormatFloat('0.##', d.DurationMinOriginal) + sLineBreak +
    'Operarios necesarios: ' + IntToStr(d.OperariosNecesarios) + sLineBreak +
    'Operarios asignados: ' + IntToStr(d.OperariosAsignados) + sLineBreak +
    'Dependencia: ' + FormatFloat('0.##', d.PorcentajeDependencia) + '%';
end;

procedure TGanttControl.HideNodeHint;
begin
  if FHintShown and Assigned(FHintWnd) then
  begin
    ShowWindow(FHintWnd.Handle, SW_HIDE);
    FHintWnd.Visible := False; // per si de cas
    FHintShown := False;
    FHintNodeIndex := -1;
  end;
end;

procedure TGanttControl.ShowNodeHint(const NodeIndex: Integer; const MouseScreen: TPoint);
var
  s: string;
  r: TRect;
  pt: TPoint;
begin
  s := BuildNodeHintText(NodeIndex);
  if s = '' then
  begin
    HideNodeHint;
    Exit;
  end;

  FHintWnd.Caption := s;

  // Calcula mida i posiciona a prop del cursor
  r := FHintWnd.CalcHintRect(480, s, nil);

  pt := MouseScreen;
  Inc(pt.X, 12);
  Inc(pt.Y, 18);

  OffsetRect(r, pt.X, pt.Y);

  // evita sortir fora de pantalla (simple)
  if r.Right > Screen.Width then OffsetRect(r, Screen.Width - r.Right - 8, 0);
  if r.Bottom > Screen.Height then OffsetRect(r, 0, Screen.Height - r.Bottom - 8);

  FHintWnd.ActivateHint(r, s);
  FHintShown := True;
  FHintNodeIndex := NodeIndex;
end;

procedure TGanttControl.SetNodeRepo(const ARepo: TNodeDataRepo);
begin
  FNodeRepo := ARepo;
  BuildDataIdIndex;
end;

procedure TGanttControl.SetLinks(const ALinks: TArray<TErpLink>);
begin
  FLinks := Copy(ALinks);
  RebuildGraphIndex;
  Invalidate;
end;

function TGanttControl.GetLinks: TArray<TErpLink>;
begin
  Result := Copy(FLinks);
end;

procedure TGanttControl.UpdateLinkDependencia(const AToNodeId: Integer; const ANewPct: Double);
var
  I: Integer;
begin
  for I := 0 to High(FLinks) do
    if FLinks[I].ToNodeId = AToNodeId then
      FLinks[I].PorcentajeDependencia := ANewPct;
end;

procedure TGanttControl.UpdateLinkAt(const AIndex: Integer; const ALink: TErpLink);
begin
  if (AIndex >= 0) and (AIndex <= High(FLinks)) then
  begin
    FLinks[AIndex] := ALink;
    RebuildGraphIndex;
    Invalidate;
  end;
end;

procedure TGanttControl.AddLink(const ALink: TErpLink);
begin
  SetLength(FLinks, Length(FLinks) + 1);
  FLinks[High(FLinks)] := ALink;
  RebuildGraphIndex;
  Invalidate;
end;

procedure TGanttControl.RemoveLinkAt(const AIndex: Integer);
var
  I: Integer;
begin
  if (AIndex < 0) or (AIndex > High(FLinks)) then Exit;
  for I := AIndex to High(FLinks) - 1 do
    FLinks[I] := FLinks[I + 1];
  SetLength(FLinks, Length(FLinks) - 1);
  Invalidate;
end;

function TGanttControl.GetLinksForNode(const ANodeId: Integer): TArray<Integer>;
var
  I: Integer;
  List: TList<Integer>;
begin
  List := TList<Integer>.Create;
  try
    for I := 0 to High(FLinks) do
      if (FLinks[I].FromNodeId = ANodeId) or (FLinks[I].ToNodeId = ANodeId) then
        List.Add(I);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;



procedure TGanttControl.RebuildOpIdIndex;
var
  i: Integer;
begin
  if FOpIdToNodeIndex = nil then
    FOpIdToNodeIndex := TDictionary<Integer, Integer>.Create
  else
    FOpIdToNodeIndex.Clear;
  for i := 0 to High(FNodes) do
    FOpIdToNodeIndex.AddOrSetValue(FNodes[i].Id, i);
end;

procedure TGanttControl.RebuildNodeLayoutIndex;
var
  i: Integer;
begin
  if FNodeIndexToLayoutIndex = nil then
    FNodeIndexToLayoutIndex := TDictionary<Integer, Integer>.Create
  else
    FNodeIndexToLayoutIndex.Clear;
  for i := 0 to High(FNodeLayouts) do
    FNodeIndexToLayoutIndex.AddOrSetValue(FNodeLayouts[i].NodeIndex, i);
end;

procedure TGanttControl.RebuildAfterModelChange(const RebuildNodeIndexMap: Boolean);
begin
  RebuildLayout;          // recrea FRows + FNodeLayouts
  RebuildNodeLayoutIndex; // OBLIGATORI sempre
  if RebuildNodeIndexMap then
    RebuildOpIdIndex;     // només si has canviat l’ordre de FNodes o has afegit/treu nodes
end;

procedure TGanttControl.ResetNodeDuration(const ANodeIndex: Integer);
var
  D: TNodeData;
  cal: TCentreCalendar;
  newStart, newEnd: TDateTime;
  newDurMin: Integer;
begin
  if not IsValidNodeIndex(ANodeIndex) then Exit;
  if not TryGetNodeData(ANodeIndex, D) then Exit;

  // Restaurar duració original
  newDurMin := Round(D.DurationMinOriginal);
  newStart := FNodes[ANodeIndex].StartTime;

  // Ajustar start a horari laboral
  cal := GetCalendar(FNodes[ANodeIndex].CentreId);
  if cal <> nil then
    newStart := cal.NextWorkingTime(newStart);

  // Calcular nou EndTime
  newEnd := CalcEndTime(FNodes[ANodeIndex].CentreId, newStart, newDurMin);

  // Aplicar al model
  ApplyResizeToModel(ANodeIndex, newStart, newEnd, newDurMin);
  CommitNodeMoveOrResize(ANodeIndex);

  RebuildAfterModelChange(False);
  Invalidate;
end;

procedure TGanttControl.ClearDataIdIndex;
var
  kv: TPair<Integer, TList<Integer>>;
begin
  if FDataIdToNodeIdxs = nil then Exit;

  for kv in FDataIdToNodeIdxs do
    kv.Value.Free;

  FDataIdToNodeIdxs.Clear;
end;

procedure TGanttControl.BuildDataIdIndex;
var
  i: Integer;
  list: TList<Integer>;
  dataId: Integer;
begin
  if FDataIdToNodeIdxs = nil then
    FDataIdToNodeIdxs := TDictionary<Integer, TList<Integer>>.Create;

  ClearDataIdIndex;

  // Indexa tots els nodes actuals
  for i := 0 to High(FNodes) do
  begin
    dataId := FNodes[i].DataId;
    if dataId = 0 then
      Continue;

    if not FDataIdToNodeIdxs.TryGetValue(dataId, list) then
    begin
      list := TList<Integer>.Create;
      FDataIdToNodeIdxs.Add(dataId, list);
    end;

    list.Add(i); // NodeIndex
  end;
end;


procedure TGanttControl.RebuildGraphIndex;
var
  i: Integer;
  lst: TList<Integer>;
begin
  // --- FNodeIdToIndex ---
  if FNodeIdToIndex = nil then
    FNodeIdToIndex := TDictionary<Integer, Integer>.Create(Length(FNodes))
  else
    FNodeIdToIndex.Clear;
  for i := 0 to High(FNodes) do
    FNodeIdToIndex.AddOrSetValue(FNodes[i].Id, i);

  // --- FSuccessors / FPredecessors  (emmagatzemen índex dins FLinks) ---
  if FSuccessors = nil then
    FSuccessors := TDictionary<Integer, TList<Integer>>.Create
  else
  begin
    for lst in FSuccessors.Values do lst.Free;
    FSuccessors.Clear;
  end;
  if FPredecessors = nil then
    FPredecessors := TDictionary<Integer, TList<Integer>>.Create
  else
  begin
    for lst in FPredecessors.Values do lst.Free;
    FPredecessors.Clear;
  end;
  for i := 0 to High(FLinks) do
  begin
    // Successors: FromNodeId -> llista de link-index
    if not FSuccessors.TryGetValue(FLinks[i].FromNodeId, lst) then
    begin
      lst := TList<Integer>.Create;
      FSuccessors.Add(FLinks[i].FromNodeId, lst);
    end;
    lst.Add(i);
    // Predecessors: ToNodeId -> llista de link-index
    if not FPredecessors.TryGetValue(FLinks[i].ToNodeId, lst) then
    begin
      lst := TList<Integer>.Create;
      FPredecessors.Add(FLinks[i].ToNodeId, lst);
    end;
    lst.Add(i);
  end;

  // --- FCentreIdToIsSeq / FCentreIdToIdx ---
  if FCentreIdToIsSeq = nil then
    FCentreIdToIsSeq := TDictionary<Integer, Boolean>.Create
  else
    FCentreIdToIsSeq.Clear;
  if FCentreIdToIdx = nil then
    FCentreIdToIdx := TDictionary<Integer, Integer>.Create
  else
    FCentreIdToIdx.Clear;
  for i := 0 to High(FCentres) do
  begin
    FCentreIdToIsSeq.AddOrSetValue(FCentres[i].Id, FCentres[i].IsSequencial);
    FCentreIdToIdx.AddOrSetValue(FCentres[i].Id, i);
  end;
end;

procedure TGanttControl.ScrollByPixels(const dx, dy: Integer; const ScrollRect: TRect);
var
  updateRgn: HRGN;
begin
  if (dx = 0) and (dy = 0) then
    Exit;
  updateRgn := CreateRectRgn(0, 0, 0, 0);
  try
    // Mou pixels i marca com a "invalid" només la zona nova exposada
    ScrollWindowEx(
      Handle,
      dx, dy,
      @ScrollRect,  // zona a moure
      nil,          // clip rect (nil = mateix)
      updateRgn,    // rep update region
      nil,
      SW_INVALIDATE or SW_ERASE
    );
    // Força repintat només de la zona invalida
    // (SW_INVALIDATE ja ho marca; això ajuda a assegurar el repaint parcial)
    InvalidateRgn(Handle, updateRgn, False);
  finally
    DeleteObject(updateRgn);
  end;
end;

procedure TGanttControl.AddRowLayout(const Row: TRowLayout);
begin
  SetLength(FRows, Length(FRows) + 1);
  FRows[High(FRows)] := Row;
end;

procedure TGanttControl.AddNodeLayout(const NL: TNodeLayout);
begin
  SetLength(FNodeLayouts, Length(FNodeLayouts) + 1);
  FNodeLayouts[High(FNodeLayouts)] := NL;
end;

procedure TGanttControl.StartScrollInvalidateTimer;
begin
  if FScrollInvalidateTimer = 0 then
    FScrollInvalidateTimer := SetTimer(Handle, 1, 20, nil); // 20ms
  FPendingInvalidate := True;
end;

procedure TGanttControl.StopScrollInvalidateTimer;
begin
  if FScrollInvalidateTimer <> 0 then
  begin
    KillTimer(Handle, FScrollInvalidateTimer);
    FScrollInvalidateTimer := 0;
  end;
  FPendingInvalidate := False;
end;

procedure TGanttControl.WMTimer(var Message: TWMTimer);
begin
  inherited;

  if (Message.TimerID = 1) then
  begin
    if FPendingInvalidate then
    begin
      FPendingInvalidate := False;
      Invalidate; // 1 repintat cada ~20ms màxim
    end;
  end;
end;


procedure TGanttControl.BuildCentreNodeIndex;
var
  i: Integer;
  arr: TArray<Integer>;
  centreId: Integer;
begin
  FCentreNodeIdx.Clear;

  for i := 0 to High(FNodes) do
  begin
    centreId := FNodes[i].CentreId;

    if not FCentreNodeIdx.TryGetValue(centreId, arr) then
      SetLength(arr, 0);

    SetLength(arr, Length(arr) + 1);
    arr[High(arr)] := i;

    FCentreNodeIdx.AddOrSetValue(centreId, arr);
  end;
end;


function TGanttControl.TryGetRowByCentreId(const ACentreId: Integer; out Row: TRowLayout): Boolean;
var
  i: Integer;
begin
  for i := 0 to High(FRows) do
    if FRows[i].CentreId = ACentreId then
    begin
      Row := FRows[i];
      Exit(True);
    end;
  Result := False;
end;

function TGanttControl.CalcLaneTop(const Row: TRowLayout; const Centre: TCentreTreball;
  const LaneIndex: Integer): Single;
var
  laneH: Single;
begin
  // mateix càlcul que a RebuildLayout:
  laneH := Max(NODE_MIN_HEIGHT, (Centre.BaseHeight - (Row.LaneCount - 1) * LANEGAP) / Row.LaneCount);
  Result := Row.TopY + NODE_INNER_PAD_TOP + LaneIndex * (laneH + LaneGap);
end;

function TGanttControl.GetNodeIndexesForCentre(const ACentreId: Integer): TArray<Integer>;
var
  i, c: Integer;
begin
  SetLength(Result, 0);
  c := 0;
  for i := 0 to High(FNodes) do
    if FNodes[i].Visible and (FNodes[i].CentreId = ACentreId) then
    begin
      SetLength(Result, c + 1);
      Result[c] := i;
      Inc(c);
    end;

end;

function TGanttControl.FindFreeLaneForMovePreview(
  const CentreId: Integer;
  const XLeftW, XRightW: Single;
  const LaneCount: Integer
): Integer;
var
  l, i: Integer;
  nl: TNodeLayout;
begin
  // prova lanes 0..LaneCount-1, retorna la primera sense solapament
  for l := 0 to LaneCount - 1 do
  begin
    Result := l;
    for i := 0 to High(FNodeLayouts) do
    begin
      nl := FNodeLayouts[i];
      // IMPORTANT: exclou el node que estàs movent
      if nl.NodeIndex = FMoveNodeIndex then
        Continue;
      if (nl.CentreId <> CentreId) then
        Continue;
      if nl.LaneIndex <> l then
        Continue;
      if RectsOverlapX(XLeftW, XRightW, nl.Rect.Left, nl.Rect.Right) then
      begin
        Result := -1;
        Break;
      end;
    end;
    if Result <> -1 then
      Exit; // lane lliure trobada
  end;
  // si totes ocupades, posa'l a la 0 (o a la lane amb menys conflicte)
  Result := 0;
end;


(*
procedure TGanttControl.DrawDependenciesD2D(
  const VisibleXLeft, VisibleXRight, VisibleYTop, VisibleYBottom: Single;
  const RT: ID2D1RenderTarget;
  const StrokeBrush: ID2D1SolidColorBrush;
  const FillBrush: ID2D1SolidColorBrush);
var
  L: TErpLink;
  fromNodeIdx, toNodeIdx: Integer;
  fromLayoutIdx, toLayoutIdx: Integer;
  rFromW, rToW, rFromS, rToS: TRectF;
  fromPt, toPt: TPointF;
  dotted: ID2D1StrokeStyle;

  function RectTouchesView(const R: TRectF): Boolean;
  begin
    Result := (R.Right >= VisibleXLeft) and (R.Left <= VisibleXRight) and
              (R.Bottom >= VisibleYTop) and (R.Top <= VisibleYBottom);
  end;

begin
  if Length(FLinks) = 0 then Exit;
  if (FOpIdToNodeIndex = nil) then Exit;
  if (FNodeIndexToLayoutIndex = nil) then Exit;

  if FLinksVisible = lvNever then Exit;

  if FLinksVisible = lvSelected then
  begin
    if FSelectedNodeId<0 then
     Exit
  end;


  dotted := CreateDottedStrokeStyle(RT);

  // color base (gris fosc suau)
  StrokeBrush.SetColor(D2D1ColorF(0.45, 0.45, 0.45, 0.85));
  FillBrush.SetColor(D2D1ColorF(0.45, 0.45, 0.45, 0.85));

  for L in FLinks do
  begin
    if not FOpIdToNodeIndex.TryGetValue(L.FromOpId, fromNodeIdx) then Continue;
    if not FOpIdToNodeIndex.TryGetValue(L.ToOpId,   toNodeIdx)   then Continue;

    if not FNodeIndexToLayoutIndex.TryGetValue(fromNodeIdx, fromLayoutIdx) then Continue;
    if not FNodeIndexToLayoutIndex.TryGetValue(toNodeIdx,   toLayoutIdx)   then Continue;

    rFromW := FNodeLayouts[fromLayoutIdx].Rect;
    rToW   := FNodeLayouts[toLayoutIdx].Rect;

    if (not RectTouchesView(rFromW)) and (not RectTouchesView(rToW)) then
      Continue;

    // world->screen
    rFromS := rFromW; rFromS.Offset(-FScrollX, -FScrollY);
    rToS   := rToW;   rToS.Offset(-FScrollX, -FScrollY);

    fromPt := PointF(rFromS.Right, (rFromS.Top + rFromS.Bottom) * 0.5);
    toPt   := PointF(rToS.Left,    (rToS.Top + rToS.Bottom) * 0.5);

    // (Opcional) estil segons LinkType:
    // - dotted per uns tipus, solid per altres
    // Ara mateix: dotted sempre.
    DrawCurvedArrowD2D(
      RT,
      StrokeBrush,
      FillBrush,
      fromPt,
      toPt,
      dotted,
      1.2,  // stroke width
      10,   // arrow size
      8     // arrow width
    );
  end;
end;
*)



{
function TGanttControl.GetNodeRectWorldForLinks(const NodeIndex: Integer): TRectF;
var
  layoutIdx: Integer;
begin
  // rect base del layout (WORLD)
  if not FNodeIndexToLayoutIndex.TryGetValue(NodeIndex, layoutIdx) then
    Exit(TRectF.Empty);
  Result := FNodeLayouts[layoutIdx].Rect;
  // si és el node que s'està redimensionant, aplica preview (WORLD)
  if FResizing and (NodeIndex = FResizeNodeIndex) then
  begin
    Result.Left  := TimeToX(FPreviewStart) + FScrollX; // screen->world
    Result.Right := TimeToX(FPreviewEnd)   + FScrollX; // screen->world
    if Result.Right < Result.Left then
    begin
      var tmp := Result.Left;
      Result.Left := Result.Right;
      Result.Right := tmp;
    end;
  end;
end;
}
function TGanttControl.GetNodeRectWorldForLinks(const NodeIndex: Integer): TRectF;
var
  layoutIdx: Integer;
  rowTop: Single;
  tmp: Single;
begin
  // rect base del layout (WORLD)
  if not FNodeIndexToLayoutIndex.TryGetValue(NodeIndex, layoutIdx) then
    Exit(TRectF.Empty);

  Result := FNodeLayouts[layoutIdx].Rect;
  if Result.IsEmpty then
    Exit;

  // ===== MOVING preview (WORLD) =====
  if FMoving and (NodeIndex = FMoveNodeIndex) then
  begin
    // X preview (WORLD) -> SENSE scroll
    Result.Left  := TimeToX(FMovePreviewStart);
    Result.Right := TimeToX(FMovePreviewEnd);

    // assegura ordre
    if Result.Right < Result.Left then
    begin
      tmp := Result.Left;
      Result.Left := Result.Right;
      Result.Right := tmp;
    end;

    // Y preview (WORLD)
    if IsCentreSequecial(FMovePreviewCentreId) then
      rowTop := RowTopYByCentreId(FMovePreviewCentreId)
    else
      // NOSEQUENCIAL: snap a la lane original (la del rect base)
      rowTop := Result.Top - NODE_INNER_PAD_TOP;

    Result.Offset(0, (rowTop + NODE_INNER_PAD_TOP) - Result.Top);
    Exit;
  end;

  // ===== RESIZING preview (WORLD) =====
  if FResizing and (NodeIndex = FResizeNodeIndex) then
  begin
    // X preview (WORLD) -> SENSE scroll
    Result.Left  := TimeToX(FPreviewStart);
    Result.Right := TimeToX(FPreviewEnd);

    if Result.Right < Result.Left then
    begin
      tmp := Result.Left;
      Result.Left := Result.Right;
      Result.Right := tmp;
    end;

    Exit;
  end;
end;


{
procedure TGanttControl.DrawDependenciesD2D(
  const VisibleXLeft, VisibleXRight, VisibleYTop, VisibleYBottom: Single;
  const RT: ID2D1RenderTarget;
  const StrokeBrush: ID2D1SolidColorBrush;
  const FillBrush: ID2D1SolidColorBrush);
var
  L: TErpLink;

  fromNodeIdx, toNodeIdx: Integer;
  fromLayoutIdx, toLayoutIdx: Integer;
  rFromW, rToW, rFromS, rToS: TRectF;
  fromPt, toPt: TPointF;
  dotted: ID2D1StrokeStyle;

  Adj: TObjectDictionary<Integer, TList<Integer>>;
  Visited: TDictionary<Integer, Byte>;
  Q: TQueue<Integer>;

  function RectTouchesView(const R: TRectF): Boolean;
  begin
    Result := (R.Right >= VisibleXLeft) and (R.Left <= VisibleXRight) and
              (R.Bottom >= VisibleYTop) and (R.Top <= VisibleYBottom);
  end;

  procedure AddEdge(const A, B: Integer);
  var
    lst: TList<Integer>;
  begin
    if not Adj.TryGetValue(A, lst) then
    begin
      lst := TList<Integer>.Create;
      Adj.Add(A, lst);
    end;
    lst.Add(B);
  end;

  procedure BuildAdjacency;
  var
    i: Integer;
  begin
    // Graf NO dirigit per connectivitat: afegim A<->B
    for i := 0 to High(FLinks) do
    begin
      L := FLinks[i];
      if not FOpIdToNodeIndex.TryGetValue(L.FromOpId, fromNodeIdx) then Continue;
      if not FOpIdToNodeIndex.TryGetValue(L.ToOpId,   toNodeIdx)   then Continue;

      AddEdge(fromNodeIdx, toNodeIdx);
      AddEdge(toNodeIdx, fromNodeIdx);
    end;
  end;

  procedure BuildConnectedComponentFromSelected;
  var
    cur, nb: Integer;
    lst: TList<Integer>;
    i: Integer;
  begin
    Visited.Clear;
    Q.Clear;

    Visited.AddOrSetValue(FSelectedNodeIndex, 1);
    Q.Enqueue(FSelectedNodeIndex);

    while Q.Count > 0 do
    begin
      cur := Q.Dequeue;

      if not Adj.TryGetValue(cur, lst) then
        Continue;

      for i := 0 to lst.Count - 1 do
      begin
        nb := lst[i];
        if not Visited.ContainsKey(nb) then
        begin
          Visited.AddOrSetValue(nb, 1);
          Q.Enqueue(nb);
        end;
      end;
    end;
  end;

begin
  SetLength(FLinkScreenPts, 0); // netejar punts hover del frame anterior

  if Length(FLinks) = 0 then Exit;
  if (FOpIdToNodeIndex = nil) then Exit;
  if (FNodeIndexToLayoutIndex = nil) then Exit;

  // ===== visibilitat =====
  if FLinksVisible = lvNever then
    Exit;

  if (FLinksVisible = lvSelected) and (FSelectedNodeIndex < 0) then
    Exit;

  dotted := CreateDottedStrokeStyle(RT);

  // color base (gris fosc suau)
  StrokeBrush.SetColor(D2D1ColorF(0.45, 0.45, 0.45, 0.85));
  FillBrush.SetColor(D2D1ColorF(0.45, 0.45, 0.45, 0.85));

  Adj := TObjectDictionary<Integer, TList<Integer>>.Create([doOwnsValues]);
  Visited := TDictionary<Integer, Byte>.Create;
  Q := TQueue<Integer>.Create;
  try
    if FLinksVisible = lvSelected then
    begin
      BuildAdjacency;
      BuildConnectedComponentFromSelected;
      // ara Visited = tots els nodes connectats (recursiu) al seleccionat
    end;

    for L in FLinks do
    begin
      if not FOpIdToNodeIndex.TryGetValue(L.FromOpId, fromNodeIdx) then Continue;
      if not FOpIdToNodeIndex.TryGetValue(L.ToOpId,   toNodeIdx)   then Continue;

      // ===== filtre recursiu =====
      if (FLinksVisible = lvSelected) then
      begin
        // pintem només links on AMBDÓS nodes són dins del component connectat
        if (not Visited.ContainsKey(fromNodeIdx)) or (not Visited.ContainsKey(toNodeIdx)) then
          Continue;
      end;

      if not FNodeIndexToLayoutIndex.TryGetValue(fromNodeIdx, fromLayoutIdx) then Continue;
      if not FNodeIndexToLayoutIndex.TryGetValue(toNodeIdx,   toLayoutIdx)   then Continue;

     // rFromW := FNodeLayouts[fromLayoutIdx].Rect;
     // rToW   := FNodeLayouts[toLayoutIdx].Rect;

      rFromW := GetNodeRectWorldForLinks(fromNodeIdx);
      rToW   := GetNodeRectWorldForLinks(toNodeIdx);

      if rFromW.IsEmpty or rToW.IsEmpty then
        Continue;

      if (not RectTouchesView(rFromW)) and (not RectTouchesView(rToW)) then
        Continue;

      // world->screen
      rFromS := rFromW; rFromS.Offset(-FScrollX, -FScrollY);
      rToS   := rToW;   rToS.Offset(-FScrollX, -FScrollY);

      fromPt := PointF(rFromS.Right, (rFromS.Top + rFromS.Bottom) * 0.5);
      toPt   := PointF(rToS.Left,    (rToS.Top + rToS.Bottom) * 0.5);

      // Guardar punts per hit-test hover
      SetLength(FLinkScreenPts, Length(FLinkScreenPts) + 1);
      FLinkScreenPts[High(FLinkScreenPts)] := TPair<TPointF, TPointF>.Create(fromPt, toPt);

      // Resaltar si hovered
      var linkDrawIdx: Integer := High(FLinkScreenPts);
      var sw: Single;
      var linkStyle: ID2D1StrokeStyle;
      if linkDrawIdx = FHoverLinkIndex then
      begin
        sw := 3.5;
        StrokeBrush.SetColor(D2D1ColorF(0.35, 0.60, 0.95, 1.0)); // blau clar
        FillBrush.SetColor(D2D1ColorF(0.35, 0.60, 0.95, 1.0));
        linkStyle := nil; // línia contínua
      end
      else
      begin
        sw := 1.2;
        StrokeBrush.SetColor(D2D1ColorF(0.45, 0.45, 0.45, 0.85));
        FillBrush.SetColor(D2D1ColorF(0.45, 0.45, 0.45, 0.85));
        linkStyle := dotted;
      end;

      DrawCurvedArrowD2D(
        RT,
        StrokeBrush,
        FillBrush,
        fromPt,
        toPt,
        linkStyle,
        sw,
        10,
        8
      );
    end;

  finally
    Q.Free;
    Visited.Free;
    Adj.Free;
  end;
end;

}


procedure TGanttControl.UpdateScrollBars;
var
  si: TScrollInfo;
  MaxX, MaxY: Integer;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then Exit;

  // offset màxim (scroll en píxels)
  MaxX := Max(0, FContentWidth - ClientWidth);
  MaxY := Max(0, FContentHeight - ClientHeight);

  // clamp del teu scroll
  FScrollX := EnsureRange(FScrollX, 0, MaxX);
  FScrollY := EnsureRange(FScrollY, 0, MaxY);

  // HORZ
  FillChar(si, SizeOf(si), 0);
  si.cbSize := SizeOf(si);
  si.fMask := SIF_RANGE or SIF_PAGE or SIF_POS;
  si.nMin := 0;
  si.nPage := ClientWidth;

  // nMax ha de ser "MaxX + page - 1" perquè el thumb pugui arribar a MaxX
  if MaxX = 0 then
    si.nMax := 0
  else
    si.nMax := MaxX + Integer(si.nPage) - 1;

  si.nPos := Round(FScrollX);
  SetScrollInfo(Handle, SB_HORZ, si, True);

  // VERT
  FillChar(si, SizeOf(si), 0);
  si.cbSize := SizeOf(si);
  si.fMask := SIF_RANGE or SIF_PAGE or SIF_POS;
  si.nMin := 0;
  si.nPage := ClientHeight;

  if MaxY = 0 then
    si.nMax := 0
  else
    si.nMax := MaxY + Integer(si.nPage) - 1;

  si.nPos := Round(FScrollY);
  SetScrollInfo(Handle, SB_VERT, si, True);

  NotifyViewportChanged;
end;



function TGanttControl.GetCalendar(const CentreId: Integer): TCentreCalendar;
begin
  if not FCalendars.TryGetValue(CentreId, Result) then
  begin
    Result := TCentreCalendar.Create;
    FCalendars.Add(CentreId, Result);
  end;
end;


function TGanttControl.GetMarqueeRect: TRect;
begin
  Result := Rect(
    Min(FMarqueeStartPt.X, FMarqueeCurrentPt.X),
    Min(FMarqueeStartPt.Y, FMarqueeCurrentPt.Y),
    Max(FMarqueeStartPt.X, FMarqueeCurrentPt.X),
    Max(FMarqueeStartPt.Y, FMarqueeCurrentPt.Y)
  );
end;


procedure TGanttControl.WMMouseWheel(var Message: TWMMouseWheel);
var
  pt: TPoint;
  xClient: Integer;
  tUnderCursor: TDateTime;
  newScroll: Single;
  zoomFactor: Single;
begin
 Exit;
 //Pendent;
  pt := ScreenToClient(Message.Pos);
  xClient := pt.X;

  // temps sota cursor abans del zoom
  tUnderCursor := XToTime(xClient);

  // zoom in/out
  if Message.WheelDelta > 0 then
    zoomFactor := 1.15
  else
    zoomFactor := 1 / 1.15;

  //FPxPerMinute := EnsureRange(FPxPerMinute * zoomFactor, 0.2, 40.0);
  FPxPerMinute := ClampPxPerMinute(FPxPerMinute * zoomFactor);

  // mantenir el temps sota el cursor
  newScroll := (VisibleMinutesBetween(FStartTime, tUnderCursor) * FPxPerMinute) - xClient;
  //FScrollX := Max(0, newScroll);
  FScrollX := ClampScrollX(newScroll);

  NotifyViewportChanged;
  Invalidate;

  // Marca com a gestionat
  Message.Result := 1;
end;


procedure TGanttControl.WMMouseHWheel(var Message: TWMMouseWheel);
begin
  // Si vols que el wheel horitzontal/touchpad també faci zoom (mateix comportament):
  WMMouseWheel(Message);
  Message.Result := 1;
end;

procedure TGanttControl.WMContextMenu(var Message: TWMContextMenu);
begin
  inherited;
end;


procedure TGanttControl.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
var
  nodeIdx: Integer;
  ptScreen: TPoint;
begin
  // MousePos ve en coords client. Quan és teclat (Shift+F10), pot venir (-1,-1)
  if (MousePos.X < 0) or (MousePos.Y < 0) then
    MousePos := Point(ClientWidth div 2, ClientHeight div 2);
  nodeIdx := HitTestNodeIndex(MousePos.X, MousePos.Y);
  if (nodeIdx >= 0) and Assigned(FNodePopupMenu) then
  begin
    FFocusedNodeIndex := nodeIdx;
    Invalidate;
    ptScreen := ClientToScreen(Point(MousePos.X, MousePos.Y));
    FNodePopupMenu.Popup(ptScreen.X, ptScreen.Y);
    Handled := True;  // IMPORTANT: evita que surti el PopupMenu general
    Exit;
  end;
  // si no hi ha node, que faci el comportament normal (PopupMenu)
  inherited;
end;


procedure TGanttControl.SetPxPerMinute(const Value: Single);
begin
  if Value <> FPxPerMinute then
  begin
    FPxPerMinute := EnsureRange(Value, 0.2, 40.0);
    RebuildLayout;
    Invalidate;
  end;
end;

function TGanttControl.SelectedNodeIndex: Integer;
begin
  Result := FFocusedNodeIndex;
end;

function TGanttControl.SelectedNode: TNode;
begin
  if (FFocusedNodeIndex >= 0) and (FFocusedNodeIndex <= High(FNodes)) then
    Result := FNodes[FFocusedNodeIndex]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function TGanttControl.GetSelectedNodeIndexes: TArray<Integer>;
var
  K: Integer;
  I: Integer;
begin
  SetLength(Result, FSelectedNodeIndexes.Count);
  I := 0;
  for K in FSelectedNodeIndexes.Keys do
  begin
    Result[I] := K;
    Inc(I);
  end;
end;


procedure TGanttControl.DrawProgressBarD2D(const RT: ID2D1RenderTarget; const Brush: ID2D1SolidColorBrush;
  const R: TRectF; const P: Single);
var
  barH: Single;
  pad: Single;
  bg, fg: TRectF;
begin
  if P < 0 then Exit;

  pad := 2;
  barH := 4;

  bg := TRectF.Create(R.Left + pad, R.Bottom - pad - barH, R.Right - pad, R.Bottom - pad);
  fg := bg;
  fg.Right := fg.Left + (bg.Width * P);

  // fons (molt suau)
  SetBrushColor(Brush, clBlack, 0.12);
  RT.FillRectangle(D2D1RectF(bg.Left, bg.Top, bg.Right, bg.Bottom), Brush);

  // progrés
  SetBrushColor(Brush, clNavy, 0.75); // o usa Style.ProgressFill+alpha
  RT.FillRectangle(D2D1RectF(fg.Left, fg.Top, fg.Right, fg.Bottom), Brush);
end;

procedure TGanttControl.DrawBadgeD2D(const D2D: TDirect2DCanvas; const RT: ID2D1RenderTarget;
  const FillBrush, TextBrush: ID2D1SolidColorBrush; const R: TRectF; const Text: string;
  const FillC, TextC: TColor);
var
  padX, padY: Single;
  bw, bh: Single;
  bx, by: Single;
  badgeR: TRectF;
  rr: TD2D1RoundedRect;
begin
  if Text = '' then Exit;

  padX := 4;
  padY := 2;

  // mida "aprox" (simple i ràpid). Si vols exacte: mesurar text.
  bw := Max(22, Length(Text) * 5.2 + padX*2);
  bh := 12;

  // No pintar badge si el node és massa estret
  if (R.Right - R.Left) < bw + 4 then Exit;

  bx := R.Right - bw + 2;
  by := R.Top + 1;

  badgeR := TRectF.Create(bx, by, bx + bw, by + bh);

  SetBrushColor(FillBrush, FillC, 0.85);

  rr.rect.left   := badgeR.Left;
  rr.rect.top    := badgeR.Top;
  rr.rect.right  := badgeR.Right;
  rr.rect.bottom := badgeR.Bottom;
  rr.radiusX := 3;
  rr.radiusY := 3;
  RT.FillRoundedRectangle(rr, FillBrush);

  SetBrushColor(TextBrush, TextC, 1.0);
  D2D.Font.Color := TextC;
  D2D.Brush.Style := bsClear;
  D2D.TextOut(Round(badgeR.Left + padX), Round(badgeR.Top + 1), Text);
  D2D.Brush.Style := bsSolid;
end;



procedure TGanttControl.SetData(const ACentres: TArray<TCentreTreball>; const ANodes: TArray<TNode>;
  const AStartTime: TDateTime);
begin
  FCentres := Copy(ACentres);
  FNodes := Copy(ANodes);
  FStartTime := AStartTime;

  FScrollX := 0;
  FScrollY := 0;

  BuildCentreNodeIndex;
  BuildDataIdIndex;
  RebuildGraphIndex;

  RebuildLayout;
  Invalidate;
end;


function TGanttControl.BloqueoX: Single;
begin
  Result := TimeToX(FFechaBloqueo); // screen coords (ja resta FScrollX)
end;

function TGanttControl.HitTestBloqueo(const X, Y: Single): Boolean;
const
  HIT_SLOP_X = 4.0;     // tolerància en pixels
  HANDLE_H  = 16.0;
  HANDLE_W  = 14.0;
var
  bx: Single;
begin
  bx := BloqueoX;

  // zona del "handle" (a dalt)
  if (Y >= 0) and (Y <= HANDLE_H) and (Abs(X - bx) <= HANDLE_W*0.5 + 3) then
    Exit(True);

  // zona de la línia (tot el vertical)
  Result := Abs(X - bx) <= HIT_SLOP_X;
end;

procedure TGanttControl.SetFechaBloqueoFromX(const X: Single);
var
  t: TDateTime;
begin
  // si el teu XToTime està ben definit amb FScrollX/FPxPerMinute:
  t := XToTime(X);

  // opcional: “snap” a minut / 5 minuts
  // t := Round(t * 24*60) / (24*60);          // a minut
  // t := Round(t * 24*12) / (24*12);          // a 5 minuts

  FFechaBloqueo := t;
end;


procedure TGanttControl.SetFechaBloqueo(const Value: TDateTime);
begin
  if SameValue(FFechaBloqueo, Value) then
    Exit;
  FFechaBloqueo := Value;
  Invalidate;   // <-- fa repaint automàtic
end;



procedure TGanttControl.DrawBloqueoLineD2D(
  const RT: ID2D1RenderTarget;
  const LineBrush, HandleBrush: ID2D1SolidColorBrush;
  const ClientW, ClientH: Single);
var
  oldM, M: TD2D1Matrix3x2F;
  x: Single;
  r: TD2D1RectF;
  penW: Single;
begin

  if FPxPerMinute <= 1e-6 then Exit;

  x := BloqueoX;
  if (x < -2) or (x > ClientW + 2) then Exit;

  RT.GetTransform(oldM);

  // identitat (com al teu grid)
  M._11 := 1; M._12 := 0;
  M._21 := 0; M._22 := 1;
  M._31 := 0; M._32 := 0;
  RT.SetTransform(M);

  RT.PushAxisAlignedClip(D2D1RectF(0, 0, ClientW, ClientH), D2D1_ANTIALIAS_MODE_ALIASED);
  try
    penW := 2.0;
    if FDraggingBloqueo or FHoverBloqueo then
      penW := 3.0;

    // línia vertical
    RT.DrawLine(D2D1PointF(x, 0), D2D1PointF(x, ClientH), LineBrush, penW);

  finally
    RT.PopAxisAlignedClip;
    RT.SetTransform(oldM);
  end;
end;


procedure TGanttControl.DrawBlockedAreaD2D(
  const RT: ID2D1RenderTarget;
  const FillBrush, HatchBrush: ID2D1SolidColorBrush;
  const ClientW, ClientH: Single);
var
  oldM, M: TD2D1Matrix3x2F;
  xb: Single;
  r: TD2D1RectF;
  step: Single;
  x: Single;
begin
  if (ClientW <= 1) or (ClientH <= 1) then Exit;
  if FPxPerMinute <= 1e-6 then Exit;

  xb := TimeToX(FFechaBloqueo);
  if xb <= 0 then Exit; // res bloquejat visible

  if xb > ClientW then xb := ClientW;

  RT.GetTransform(oldM);

  // identitat (pantalla)
  M._11 := 1; M._12 := 0;
  M._21 := 0; M._22 := 1;
  M._31 := 0; M._32 := 0;
  RT.SetTransform(M);

  // clip a la zona bloquejada
  r := D2D1RectF(0, 0, xb, ClientH);
  RT.PushAxisAlignedClip(r, D2D1_ANTIALIAS_MODE_ALIASED);
  try
    // capa semitransparent
    RT.FillRectangle(r, FillBrush);

    // patró: línies diagonals (/)
    // comencem des de fora per cobrir-ho tot
    step := 10; // separació de ratlles (px)
    x := -ClientH;

    while x < xb + ClientH do
    begin
      RT.DrawLine(
        D2D1PointF(x, ClientH),
        D2D1PointF(x + ClientH, 0),
        HatchBrush,
        1.0
      );
      x := x + step;
    end;
  finally
    RT.PopAxisAlignedClip;
    RT.SetTransform(oldM);
  end;
end;


{ ============================================= }
{              MARKERS                          }
{ ============================================= }

function TGanttControl.AddMarker(const AMarker: TGanttMarker): Integer;
var
  M: TGanttMarker;
begin
  M := AMarker;
  M.Id := FNextMarkerId;
  Inc(FNextMarkerId);
  if M.StrokeWidth <= 0 then
    M.StrokeWidth := 1.5;
  if M.FontName = '' then
    M.FontName := 'Segoe UI';
  if M.FontSize <= 0 then
    M.FontSize := 8;
  if M.FontColor = 0 then
    M.FontColor := M.Color;
  SetLength(FMarkers, Length(FMarkers) + 1);
  FMarkers[High(FMarkers)] := M;
  Result := M.Id;
  Invalidate;
end;

procedure TGanttControl.RemoveMarker(const AMarkerId: Integer);
var
  i, last: Integer;
begin
  for i := 0 to High(FMarkers) do
  begin
    if FMarkers[i].Id = AMarkerId then
    begin
      last := High(FMarkers);
      if i <> last then
        FMarkers[i] := FMarkers[last];
      SetLength(FMarkers, last);
      Invalidate;
      Exit;
    end;
  end;
end;

procedure TGanttControl.ClearMarkers;
begin
  SetLength(FMarkers, 0);
  FDraggingMarkerId := -1;
  FHoverMarkerId := -1;
  Invalidate;
end;

function TGanttControl.GetMarkers: TArray<TGanttMarker>;
var
  i, cnt: Integer;
begin
  cnt := 0;
  for i := 0 to High(FMarkers) do
    if FMarkers[i].Tag <> TAG_AUTO_MARKER then
      Inc(cnt);
  SetLength(Result, cnt);
  cnt := 0;
  for i := 0 to High(FMarkers) do
    if FMarkers[i].Tag <> TAG_AUTO_MARKER then
    begin
      Result[cnt] := FMarkers[i];
      Inc(cnt);
    end;
end;

function TGanttControl.MarkerCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(FMarkers) do
    if FMarkers[i].Tag <> TAG_AUTO_MARKER then
      Inc(Result);
end;

function TGanttControl.HitTestMarker(const ScreenX: Single; const Tolerance: Single): Integer;
var
  i: Integer;
  mx: Single;
begin
  Result := -1;
  for i := 0 to High(FMarkers) do
  begin
    if not FMarkers[i].Visible then Continue;
    mx := TimeToX(FMarkers[i].DateTime);
    if Abs(mx - ScreenX) <= Tolerance then
    begin
      Result := FMarkers[i].Id;
      Exit;
    end;
  end;
end;

function TGanttControl.FindMarkerAt(const ScreenX: Single; const Tolerance: Single): Integer;
begin
  Result := HitTestMarker(ScreenX, Tolerance);
end;

procedure TGanttControl.SetAutoMarkersEnabled(const Value: Boolean);
begin
  if FAutoMarkersEnabled = Value then Exit;
  FAutoMarkersEnabled := Value;
  if Value then
    UpdateAutoMarkers
  else
  begin
    ClearAutoMarkers;
    Invalidate;
  end;
end;

procedure TGanttControl.ClearAutoMarkers;
var
  i: Integer;
begin
  i := 0;
  while i <= High(FMarkers) do
  begin
    if FMarkers[i].Tag = TAG_AUTO_MARKER then
    begin
      if i < High(FMarkers) then
        FMarkers[i] := FMarkers[High(FMarkers)];
      SetLength(FMarkers, Length(FMarkers) - 1);
    end
    else
      Inc(i);
  end;
end;

procedure TGanttControl.UpdateAutoMarkers;
var
  D: TNodeData;
  M: TGanttMarker;
  hasData: Boolean;
begin
  // Eliminar markers automàtics anteriors
  ClearAutoMarkers;

  if not FAutoMarkersEnabled then Exit;
  if FFocusedNodeIndex < 0 then Exit;

  hasData := TryGetNodeData(FFocusedNodeIndex, D);
  if not hasData then Exit;

  // Marker: Fecha Entrega (vermell, dashed)
  if D.FechaEntrega > 1 then
  begin
    M := Default(TGanttMarker);
    M.DateTime := D.FechaEntrega;
    M.Caption := 'Entrega ' + FormatDateTime('dd/mm', D.FechaEntrega);
    M.Color := $002020FF; // vermell BGR
    M.Style := msDashed;
    M.StrokeWidth := 1.5;
    M.Moveable := False;
    M.Visible := True;
    M.Tag := TAG_AUTO_MARKER;
    M.FontName := 'Segoe UI';
    M.FontSize := 7;
    M.FontColor := $002020FF;
    M.FontStyle := [fsBold];
    M.TextOrientation := mtoHorizontal;
    M.TextAlign := mtaTop;
    AddMarker(M);
  end;

  // Marker: Fecha Necesaria (taronja, dashed)
  if D.FechaNecesaria > 1 then
  begin
    M := Default(TGanttMarker);
    M.DateTime := D.FechaNecesaria;
    M.Caption := 'Necesaria ' + FormatDateTime('dd/mm', D.FechaNecesaria);
    M.Color := $000080FF; // taronja BGR
    M.Style := msDashed;
    M.StrokeWidth := 1.5;
    M.Moveable := False;
    M.Visible := True;
    M.Tag := TAG_AUTO_MARKER;
    M.FontName := 'Segoe UI';
    M.FontSize := 7;
    M.FontColor := $000080FF;
    M.FontStyle := [fsBold];
    M.TextOrientation := mtoHorizontal;
    M.TextAlign := mtaTop;
    AddMarker(M);
  end;

  Invalidate;
end;

procedure TGanttControl.DrawMarkersD2D(
  const D2D: TDirect2DCanvas;
  const RT: ID2D1RenderTarget;
  const LineBrush: ID2D1SolidColorBrush;
  const ClientW, ClientH: Single);
var
  i: Integer;
  oldM, M2: TD2D1Matrix3x2F;
  x, y, penW: Single;
  DashLen, GapLen: Single;
  marker: TGanttMarker;
  isHover, isDragging: Boolean;
  captionW, captionH: Single;
  captionX, captionY: Single;
  txtSize: TSize;
begin
  if Length(FMarkers) = 0 then Exit;
  if (ClientW <= 1) or (ClientH <= 1) then Exit;
  if FPxPerMinute <= 1e-6 then Exit;

  RT.GetTransform(oldM);
  M2._11 := 1; M2._12 := 0;
  M2._21 := 0; M2._22 := 1;
  M2._31 := 0; M2._32 := 0;
  RT.SetTransform(M2);

  RT.PushAxisAlignedClip(D2D1RectF(0, 0, ClientW, ClientH), D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
  try
    for i := 0 to High(FMarkers) do
    begin
      marker := FMarkers[i];
      if not marker.Visible then Continue;

      x := TimeToX(marker.DateTime);
      if (x < -2) or (x > ClientW + 2) then Continue;

      isHover := (marker.Id = FHoverMarkerId);
      isDragging := (marker.Id = FDraggingMarkerId);

      penW := marker.StrokeWidth;
      if isHover or isDragging then
        penW := penW + 1.0;

      SetBrushColor(LineBrush, marker.Color, 1.0);

      case marker.Style of
        msLine:
          RT.DrawLine(D2D1PointF(x, 0), D2D1PointF(x, ClientH), LineBrush, penW);

        msDashed:
        begin
          DashLen := 10;
          GapLen := 6;
          y := 0;
          while y < ClientH do
          begin
            RT.DrawLine(
              D2D1PointF(x, y),
              D2D1PointF(x, Min(y + DashLen, ClientH)),
              LineBrush, penW);
            y := y + DashLen + GapLen;
          end;
        end;

        msDotted:
        begin
          DashLen := 3;
          GapLen := 4;
          y := 0;
          while y < ClientH do
          begin
            RT.DrawLine(
              D2D1PointF(x, y),
              D2D1PointF(x, Min(y + DashLen, ClientH)),
              LineBrush, penW);
            y := y + DashLen + GapLen;
          end;
        end;
      end;

      // petit triangle/diamant a dalt per indicar el marker
      RT.FillRectangle(
        D2D1RectF(x - 4, 0, x + 4, 6),
        LineBrush);

      // Caption (si n'hi ha)
      if marker.Caption <> '' then
      begin
        // Configurar font del marker
        D2D.Font.Name := marker.FontName;
        D2D.Font.Size := marker.FontSize;
        D2D.Font.Style := marker.FontStyle;
        D2D.Font.Color := marker.FontColor;

        txtSize := D2D.TextExtent(marker.Caption);
        captionW := txtSize.cx;
        captionH := txtSize.cy;

        if marker.TextOrientation = mtoHorizontal then
        begin
          // Posicio X: a la dreta de la linia, o a l'esquerra si no cap
          captionX := x + 5;
          if captionX + captionW > ClientW then
            captionX := x - captionW - 5;

          // Posicio Y segons alineacio
          case marker.TextAlign of
            mtaTop:    captionY := 8;
            mtaCenter: captionY := (ClientH - captionH) / 2;
            mtaBottom: captionY := ClientH - captionH - 8;
          else
            captionY := 8;
          end;

          // Fons semitransparent
          SetBrushColor(LineBrush, clWhite, 0.80);
          RT.FillRectangle(
            D2D1RectF(captionX - 2, captionY - 1,
                      captionX + captionW + 2, captionY + captionH + 1),
            LineBrush);

          // Text
          D2D.Font.Color := marker.FontColor;
          D2D.TextOut(Round(captionX), Round(captionY), marker.Caption);
        end
        else
        begin
          // TEXT VERTICAL (rotat -90 graus)
          // Posicio Y segons alineacio (el text rota, W i H s'intercanvien)
          case marker.TextAlign of
            mtaTop:    captionY := 8 + captionW;
            mtaCenter: captionY := (ClientH + captionW) / 2;
            mtaBottom: captionY := ClientH - 8;
          else
            captionY := 8 + captionW;
          end;

          captionX := x + 5;
          if captionX + captionH > ClientW then
            captionX := x - captionH - 5;

          // Fons semitransparent (rotated area)
          SetBrushColor(LineBrush, clWhite, 0.80);
          RT.FillRectangle(
            D2D1RectF(captionX - 1, captionY - captionW - 2,
                      captionX + captionH + 1, captionY + 2),
            LineBrush);

          // Rotar per pintar text vertical
          var rotM: TD2D1Matrix3x2F;
          // Rotacio -90 graus al voltant del punt (captionX, captionY)
          var cosA: Single := 0;   // cos(-90) = 0
          var sinA: Single := -1;  // sin(-90) = -1
          rotM._11 := cosA;  rotM._12 := sinA;
          rotM._21 := -sinA; rotM._22 := cosA;
          rotM._31 := captionX - cosA * captionX + sinA * captionY;
          rotM._32 := captionY - sinA * captionX - cosA * captionY;
          RT.SetTransform(rotM);

          D2D.Font.Color := marker.FontColor;
          D2D.TextOut(Round(captionX), Round(captionY), marker.Caption);

          // Restaurar transformacio identitat
          RT.SetTransform(M2);
        end;
      end;
    end;
  finally
    RT.PopAxisAlignedClip;
    RT.SetTransform(oldM);
  end;
end;


procedure TGanttControl.ClearSearch;
begin
  SetLength(FSearchResults, 0);
  FSearchPos := -1;
  FHighlightSet.Clear;
  Invalidate;
end;

procedure TGanttControl.SetScrollX(const Value: Single);
begin
  FScrollX := ClampScrollX(Value);
  NotifyViewportChanged;
  Invalidate;
end;

procedure TGanttControl.SetSearchResults(const NodeIndexes: TArray<Integer>; const AutoSelectFirst: Boolean);
var
  i, idx: Integer;
begin
  // guarda
  FSearchResults := Copy(NodeIndexes);

  // rebuild highlight set
  FHighlightSet.Clear;
  for i := 0 to High(FSearchResults) do
  begin
    idx := FSearchResults[i];
    if (idx >= 0) and (idx <= High(FNodes)) then
      FHighlightSet.AddOrSetValue(idx, 1);
  end;

  if Length(FSearchResults) > 0 then
    FSearchPos := 0
  else
    FSearchPos := -1;

  if AutoSelectFirst and (FSearchPos >= 0) then
    SelectNodeByIndex(FSearchResults[FSearchPos], True)
  else
    Invalidate;
end;

function TGanttControl.SearchResultCount: Integer;
begin
  Result := Length(FSearchResults);
end;

function TGanttControl.SearchResultIndex: Integer;
begin
  Result := FSearchPos;
end;

function TGanttControl.SearchCurrentNodeIndex: Integer;
begin
  if (FSearchPos >= 0) and (FSearchPos < Length(FSearchResults)) then
    Result := FSearchResults[FSearchPos]
  else
    Result := -1;
end;



procedure TGanttControl.SetVista(const Value: TGanttViewMode);
begin
  if FVista = Value then Exit;
  FVista := Value;
  Invalidate; // o RebuildAfterModelChange(False) si canvies layouts/textos
end;


procedure TGanttControl.SearchNext(const Wrap: Boolean);
begin
  if Length(FSearchResults) = 0 then Exit;

  Inc(FSearchPos);
  if FSearchPos >= Length(FSearchResults) then
  begin
    if Wrap then FSearchPos := 0 else FSearchPos := Length(FSearchResults) - 1;
  end;

  SelectNodeByIndex(FSearchResults[FSearchPos], True);
end;

procedure TGanttControl.SearchPrev(const Wrap: Boolean);
begin
  if Length(FSearchResults) = 0 then Exit;

  Dec(FSearchPos);
  if FSearchPos < 0 then
  begin
    if Wrap then FSearchPos := Length(FSearchResults) - 1 else FSearchPos := 0;
  end;

  SelectNodeByIndex(FSearchResults[FSearchPos], True);
end;

function TGanttControl.IsNodeHighlighted(const NodeIndex: Integer): Boolean;
var
  dummy: Byte;
begin
  Result := FHighlightSet.TryGetValue(NodeIndex, dummy);
end;

procedure TGanttControl.HighlightOF(const ANodeIndex: Integer);
var
  DStart, D: TNodeData;
  i: Integer;
begin
  FHighlightSet.Clear;
  if not TryGetNodeData(ANodeIndex, DStart) then
  begin
    Invalidate;
    Exit;
  end;
  for i := 0 to High(FNodes) do
  begin
    if TryGetNodeData(i, D) and
       (D.NumeroOrdenFabricacion = DStart.NumeroOrdenFabricacion) and
       SameText(D.SerieFabricacion, DStart.SerieFabricacion) then
      FHighlightSet.AddOrSetValue(i, 1);
  end;
  Invalidate;
end;

procedure TGanttControl.HighlightOT(const ANodeIndex: Integer);
var
  DStart, D: TNodeData;
  i: Integer;
begin
  FHighlightSet.Clear;
  if not TryGetNodeData(ANodeIndex, DStart) then
  begin
    Invalidate;
    Exit;
  end;
  for i := 0 to High(FNodes) do
  begin
    if TryGetNodeData(i, D) and
       SameText(D.NumeroTrabajo, DStart.NumeroTrabajo) and
       (D.NumeroOrdenFabricacion = DStart.NumeroOrdenFabricacion) and
       SameText(D.SerieFabricacion, DStart.SerieFabricacion) then
      FHighlightSet.AddOrSetValue(i, 1);
  end;
  Invalidate;
end;

procedure TGanttControl.OpFilterTimerTick(Sender: TObject);
begin
  FOpFilterPulsePhase := FOpFilterPulsePhase + 0.15; // ciclo rapido ~1s
  if FOpFilterPulsePhase > 2 * PI then
    FOpFilterPulsePhase := FOpFilterPulsePhase - 2 * PI;
  Invalidate;
end;

procedure TGanttControl.SetOperarioFilter(const ADataIds: TArray<Integer>; AHideMode: Boolean);
var
  I: Integer;
begin
  FOpFilterDataIds.Clear;
  for I := 0 to High(ADataIds) do
    FOpFilterDataIds.AddOrSetValue(ADataIds[I], 1);
  FOpFilterActive := Length(ADataIds) > 0;
  FOpFilterHideMode := AHideMode;
  FOpFilterPulsePhase := 0;
  FOpFilterTimer.Enabled := FOpFilterActive and (not FOpFilterHideMode);
  Invalidate;
end;

procedure TGanttControl.ClearOperarioFilter;
begin
  FOpFilterDataIds.Clear;
  FOpFilterActive := False;
  FOpFilterHideMode := False;
  FOpFilterTimer.Enabled := False;
  Invalidate;
end;

function TGanttControl.HitTestLink(const X, Y: Single; const Tolerance: Single): Integer;
const
  SAMPLES = 16;

  function BezierPt(const P0, C1, C2, P3: TPointF; t: Single): TPointF;
  var
    u: Single;
  begin
    u := 1 - t;
    Result.X := u*u*u*P0.X + 3*u*u*t*C1.X + 3*u*t*t*C2.X + t*t*t*P3.X;
    Result.Y := u*u*u*P0.Y + 3*u*u*t*C1.Y + 3*u*t*t*C2.Y + t*t*t*P3.Y;
  end;

var
  I, S: Integer;
  D, MinD: Single;
  Pt, Prev, Cur: TPointF;
  FromPt, ToPt, C1, C2: TPointF;
  dx, pullX: Single;
begin
  Result := -1;
  Pt := PointF(X, Y);
  for I := 0 to High(FLinkScreenPts) do
  begin
    FromPt := FLinkScreenPts[I].Key;
    ToPt := FLinkScreenPts[I].Value;

    // Reconstruir els control points (mateixa lògica que BuildNaturalBezier)
    dx := ToPt.X - FromPt.X;
    pullX := EnsureRange(Abs(dx) * 0.35, 30, 200);
    if dx >= 0 then
    begin
      C1 := PointF(FromPt.X + pullX, FromPt.Y);
      C2 := PointF(ToPt.X - pullX, ToPt.Y);
    end
    else
    begin
      C1 := PointF(FromPt.X + pullX, FromPt.Y);
      C2 := PointF(ToPt.X - pullX, ToPt.Y);
    end;

    // Samplear la bézier i trobar distància mínima
    MinD := 1e10;
    Prev := FromPt;
    for S := 1 to SAMPLES do
    begin
      Cur := BezierPt(FromPt, C1, C2, ToPt, S / SAMPLES);
      // Distància punt a segment Prev-Cur
      var sdx, sdy, st, spx, spy, lenSq: Single;
      sdx := Cur.X - Prev.X;
      sdy := Cur.Y - Prev.Y;
      lenSq := sdx*sdx + sdy*sdy;
      if lenSq < 0.001 then
        D := Sqrt(Sqr(Pt.X - Prev.X) + Sqr(Pt.Y - Prev.Y))
      else
      begin
        st := ((Pt.X - Prev.X)*sdx + (Pt.Y - Prev.Y)*sdy) / lenSq;
        if st < 0 then st := 0;
        if st > 1 then st := 1;
        spx := Prev.X + st*sdx;
        spy := Prev.Y + st*sdy;
        D := Sqrt(Sqr(Pt.X - spx) + Sqr(Pt.Y - spy));
      end;
      if D < MinD then MinD := D;
      if MinD <= Tolerance then Break;
      Prev := Cur;
    end;

    if MinD <= Tolerance then
      Exit(I);
  end;
end;

function TGanttControl.IsNodeOperarioFiltered(const ADataId: Integer): Boolean;
var
  dummy: Byte;
begin
  Result := FOpFilterDataIds.TryGetValue(ADataId, dummy);
end;


function TGanttControl.GetNodes: TArray<TNode>;
begin
  Result := FNodes;
end;

function TGanttControl.NodeCount: Integer;
begin
  Result := Length(FNodes);
end;

function TGanttControl.GetNodeAt(const Index: Integer): TNode;
begin
  if (Index > 0) and (Index <= High(FNodes)) then
   Result := FNodes[Index];
end;


function TGanttControl.GetCanUndo: Boolean;
begin
  Result := Assigned(FHistory) and FHistory.CanUndo;
end;

function TGanttControl.GetCanRedo: Boolean;
begin
  Result := Assigned(FHistory) and FHistory.CanRedo;
end;

function TGanttControl.GetUndoCount: Integer;
begin
  if Assigned(FHistory) then
    Result := FHistory.UndoCount
  else
    Result := 0;
end;

function TGanttControl.GetRedoCount: Integer;
begin
  if Assigned(FHistory) then
    Result := FHistory.RedoCount
  else
    Result := 0;
end;


procedure TGanttControl.RecalcCounters;
var
  i: Integer;
  n: TNode;
  d: TNodeData;
  T0, T1: TDateTime;
begin

  FCNT_TotalNodes := 0;
  FCNT_TotalVisibleNodes := 0;
  FCNT_TotalModifiedNodes := 0;

  FCNT_TotalNodes_StateNormal := 0;
  FCNT_TotalNodes_StateYellow := 0;
  FCNT_TotalNodes_StateOrange := 0;
  FCNT_TotalNodes_StateRed := 0;
  FCNT_TotalNodes_StateGreen := 0;

  GetVisibleTimeRange(T0, T1);

  try
      for i := 0 to High(FNodes) do
      begin
        n := FNodes[i];

        if (n.DataId = 0) or (not FNodeRepo.TryGetById(n.DataId, d)) then
         Continue;

        Inc(FCNT_TotalNodes);

        if (n.StartTime < T1) and (n.EndTime > T0) then
        Inc(FCNT_TotalVisibleNodes);
        if d.Modified then
         Inc(FCNT_TotalModifiedNodes);


        {
        case N.State of
          nsNormal: Inc(FCNT_TotalNodes_StateNormal);
          nsYellow: Inc(FCNT_TotalNodes_StateYellow);
          nsOrange: Inc(FCNT_TotalNodes_StateOrange);
          nsRed:    Inc(FCNT_TotalNodes_StateRed);
          nsGreen:  Inc(FCNT_TotalNodes_StateGreen);
        end;
        }
      end;
  finally
      if Assigned(FOnStatsChanged) then
       FOnStatsChanged(Self);
  end;
end;



function TGanttControl.FindNodesByOF(const NumeroOF: Integer; const Serie: string): TArray<Integer>;
var
  dataIds: TArray<Integer>;
  dataId: Integer;
  list: TList<Integer>;
  outList: TList<Integer>;
begin
  SetLength(Result, 0);

  if (FNodeRepo = nil) or (FDataIdToNodeIdxs = nil) then Exit;

  dataIds := FNodeRepo.FindByOF(NumeroOF, Serie);
  if Length(dataIds) = 0 then Exit;

  outList := TList<Integer>.Create;
  try
    for dataId in dataIds do
      if FDataIdToNodeIdxs.TryGetValue(dataId, list) then
        outList.AddRange(list);

    Result := outList.ToArray;
  finally
    outList.Free;
  end;
end;



function TGanttControl.ArrayContainsIdx(const A: TIdxArray; const Value: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(A) do
    if A[i] = Value then
      Exit(True);
end;
procedure TGanttControl.ArrayAddUnique(var A: TIdxArray; const Value: Integer);
var
  L: Integer;
begin
  if ArrayContainsIdx(A, Value) then Exit;
  L := Length(A);
  SetLength(A, L + 1);
  A[L] := Value;
end;
procedure TGanttControl.ArrayClear(var A: TIdxArray);
begin
  SetLength(A, 0);
end;



function TGanttControl.GetDependencyMinStart(
  const PredIdx: Integer;
  const PercentDependency: Double): TDateTime;
var
  DurDays: Double;
  Pct: Double;
begin
  Pct := PercentDependency;
  if Pct < 0 then Pct := 0;
  if Pct > 100 then Pct := 100;
  DurDays := FNodes[PredIdx].EndTime - FNodes[PredIdx].StartTime;
  Result := FNodes[PredIdx].StartTime + (DurDays * (Pct / 100.0));
end;


function TGanttControl.ApplyNodeCalendarAndOverlay(
  const CentreId: Integer;
  const T: TDateTime): TDateTime;
var
  cal: TCentreCalendar;
begin
  Result := T;
  if (FFechaBloqueo <> 0) and (Result < FFechaBloqueo) then
    Result := FFechaBloqueo;
  cal := GetCalendar(CentreId);
  if cal <> nil then
    Result := cal.NextWorkingTime(Result);
end;


function TGanttControl.MoveNodeKeepingDuration(
  const NodeIdx: Integer;
  const NewStart: TDateTime): Boolean;
var
  AdjStart: TDateTime;
  NewEnd: TDateTime;
begin
  Result := False;
  if (NodeIdx < 0) or (NodeIdx > High(FNodes)) then Exit;
  AdjStart := ApplyNodeCalendarAndOverlay(FNodes[NodeIdx].CentreId, NewStart);
  NewEnd   := CalcEndTime(FNodes[NodeIdx].CentreId, AdjStart, FNodes[NodeIdx].DurationMin);
  if (FNodes[NodeIdx].StartTime <> AdjStart) or (FNodes[NodeIdx].EndTime <> NewEnd) then
  begin
    FNodes[NodeIdx].StartTime := AdjStart;
    FNodes[NodeIdx].EndTime   := NewEnd;
    Result := True;
  end;
end;


function TGanttControl.ResolveDependenciesFromNode(
  const ChangedIdx: Integer;
  out MovedNodes: TIdxArray): Boolean;
var
  Queue: TArray<Integer>;
  qHead, qTail: Integer;
  IsProcessed, IsQueued: array of Boolean;
  PredIdx, SuccIdx, li: Integer;
  MinStart, NewStart: TDateTime;
  LinkPct: Double;
  SuccLinks: TList<Integer>;
  N: Integer;

  procedure Enqueue(const AIdx: Integer);
  begin
    if (AIdx < 0) or (AIdx > N) then Exit;
    if IsQueued[AIdx] then Exit;
    IsQueued[AIdx] := True;
    Queue[qTail] := AIdx;
    Inc(qTail);
  end;

begin
  Result := False;
  SetLength(MovedNodes, 0);
  N := High(FNodes);

  if (ChangedIdx < 0) or (ChangedIdx > N) then Exit;

  SetLength(Queue, Length(FNodes));
  SetLength(IsProcessed, Length(FNodes));
  SetLength(IsQueued, Length(FNodes));
  qHead := 0;
  qTail := 0;

  Enqueue(ChangedIdx);

  while qHead < qTail do
  begin
    PredIdx := Queue[qHead];
    Inc(qHead);

    if IsProcessed[PredIdx] then
      Continue;
    IsProcessed[PredIdx] := True;

    if (FSuccessors = nil) or not FSuccessors.TryGetValue(FNodes[PredIdx].Id, SuccLinks) then
      Continue;

    for li in SuccLinks do
    begin
      SuccIdx := FindNodeIndexById(FLinks[li].ToNodeId);
      if SuccIdx < 0 then
        Continue;

      LinkPct := FLinks[li].PorcentajeDependencia;

      MinStart := GetDependencyMinStart(PredIdx, LinkPct);
      NewStart := ApplyNodeCalendarAndOverlay(FNodes[SuccIdx].CentreId, MinStart);

      if FNodes[SuccIdx].StartTime < NewStart then
      begin
        if not FNodes[SuccIdx].Enabled then
        begin
          var PredDurDays: Double := FNodes[PredIdx].EndTime - FNodes[PredIdx].StartTime;
          var PredPct: Double := LinkPct;
          if PredPct < 0 then PredPct := 0;
          if PredPct > 100 then PredPct := 100;
          var PredMaxStart: TDateTime := FNodes[SuccIdx].StartTime - (PredDurDays * (PredPct / 100.0));
          if FNodes[PredIdx].StartTime > PredMaxStart then
          begin
            if MoveNodeKeepingDuration(PredIdx, PredMaxStart) then
            begin
              Result := True;
              SetLength(MovedNodes, Length(MovedNodes) + 1);
              MovedNodes[High(MovedNodes)] := PredIdx;
            end;
          end;
        end
        else
        begin
          if MoveNodeKeepingDuration(SuccIdx, NewStart) then
          begin
            Result := True;
            SetLength(MovedNodes, Length(MovedNodes) + 1);
            MovedNodes[High(MovedNodes)] := SuccIdx;
            Enqueue(SuccIdx);
          end;
        end;
      end;
    end;
  end;
end;



procedure TGanttControl.CollectDependentNodeIndexes(
  const AStartIdx: Integer;
  var AResult: TIdxArray);
var
  Queue: TArray<Integer>;
  Visited: array of Boolean;
  qHead, qTail, ResCount: Integer;
  CurrIdx, NextIdx, li: Integer;
  SuccLinks: TList<Integer>;
begin
  SetLength(AResult, 0);
  if (AStartIdx < 0) or (AStartIdx > High(FNodes)) then Exit;

  SetLength(Queue, Length(FNodes));
  SetLength(Visited, Length(FNodes));
  qHead := 0;
  qTail := 0;
  ResCount := 0;

  Visited[AStartIdx] := True;
  Queue[qTail] := AStartIdx;
  Inc(qTail);
  SetLength(AResult, Length(FNodes));
  AResult[ResCount] := AStartIdx;
  Inc(ResCount);

  while qHead < qTail do
  begin
    CurrIdx := Queue[qHead];
    Inc(qHead);

    if (FSuccessors <> nil) and FSuccessors.TryGetValue(FNodes[CurrIdx].Id, SuccLinks) then
    begin
      for li in SuccLinks do
      begin
        NextIdx := FindNodeIndexById(FLinks[li].ToNodeId);
        if (NextIdx >= 0) and not Visited[NextIdx] then
        begin
          Visited[NextIdx] := True;
          Queue[qTail] := NextIdx;
          Inc(qTail);
          AResult[ResCount] := NextIdx;
          Inc(ResCount);
        end;
      end;
    end;
  end;
  SetLength(AResult, ResCount);
end;


procedure TGanttControl.CollectCentreNodeIndexes(
  const ACentreId: Integer;
  var AResult: TIdxArray);
var
  cachedArr: TArray<Integer>;
  i, idx, L: Integer;
begin
  if ACentreId = 0 then
    Exit;

  if FCentreNodeIdx.TryGetValue(ACentreId, cachedArr) then
  begin
    for i := 0 to High(cachedArr) do
    begin
      idx := cachedArr[i];
      if not ArrayContainsIdx(AResult, idx) then
      begin
        L := Length(AResult);
        SetLength(AResult, L + 1);
        AResult[L] := idx;
      end;
    end;
  end;
end;


function TGanttControl.CollectAffectedNodeIndexesFromNode(
  const AStartIdx: Integer): TIdxArray;
var
  DepIdxs: TIdxArray;
  i: Integer;
begin
  ArrayClear(Result);
  ArrayClear(DepIdxs);
  if (AStartIdx < 0) or (AStartIdx > High(FNodes)) then
    Exit;
  CollectDependentNodeIndexes(AStartIdx, DepIdxs);
  for i := 0 to High(DepIdxs) do
    ArrayAddUnique(Result, DepIdxs[i]);
  for i := 0 to High(DepIdxs) do
    CollectCentreNodeIndexes(FNodes[DepIdxs[i]].CentreId, Result);
end;


function TGanttControl.CaptureSnapshotsFromNodePropagation(
  const AStartIdx: Integer): TArray<TNodePlanSnapshot>;
var
  Idxs: TIdxArray;
  i: Integer;
begin
  Idxs := CollectAffectedNodeIndexesFromNode(AStartIdx);
  SetLength(Result, Length(Idxs));
  for i := 0 to High(Idxs) do
    Result[i] := MakeNodeSnapshot(Idxs[i]);
end;

function TGanttControl.BuildHistoryEntry(
  const AActionType: TGanttHistoryActionType;
  const ACaption: string;
  const ASourceNodeIndex: Integer;
  const AChanges: TArray<TNodeHistoryChange>): TGanttHistoryEntry;
var
  Entry: TGanttHistoryEntry;
begin
  Result := nil;
  if Length(AChanges) = 0 then
    Exit;
  Entry := TGanttHistoryEntry.Create;
  try
    Entry.ActionType := AActionType;
    Entry.Caption := ACaption;
    Entry.TimeStamp := Now;
    Entry.SourceNodeIndex := ASourceNodeIndex;
    Entry.Changes := Copy(AChanges);
    Result := Entry;
  except
    Entry.Free;
    raise;
  end;
end;


function TGanttControl.BuildNodeHistoryChanges(
  const ABefore, AAfter: TArray<TNodePlanSnapshot>): TArray<TNodeHistoryChange>;
var
  i, k, Cnt, J: Integer;
begin
  SetLength(Result, 0);
  if Length(ABefore) = 0 then
    Exit;

  SetLength(Result, Length(ABefore));
  Cnt := 0;

  for i := 0 to High(ABefore) do
  begin
    J := -1;
    for k := 0 to High(AAfter) do
      if AAfter[k].NodeIndex = ABefore[i].NodeIndex then
      begin
        J := k;
        Break;
      end;

    if J < 0 then
      Continue;

    if not SameNodePlanSnapshot(ABefore[i], AAfter[J]) then
    begin
      Result[Cnt].BeforeValue := ABefore[i];
      Result[Cnt].AfterValue := AAfter[J];
      Inc(Cnt);
    end;
  end;

  SetLength(Result, Cnt);
end;



procedure TGanttControl.UndoLastAction;
var
  Entry: TGanttHistoryEntry;
  i: Integer;
begin
  if not FHistory.CanUndo then
    Exit;

  Entry := FHistory.PopUndo;
  try
    for i := 0 to High(Entry.Changes) do
      ApplyNodeSnapshot(Entry.Changes[i].BeforeValue);

    FHistory.PushRedo(Entry);
    RebuildLayout;   // o RefreshNodes / relayout
    RecalcCounters;
    Invalidate;
  except
    Entry.Free;
    raise;
  end;
end;


procedure TGanttControl.RedoLastAction;
var
  Entry: TGanttHistoryEntry;
  i: Integer;
begin
  if not FHistory.CanRedo then
    Exit;

  Entry := FHistory.PopRedo;
  try
    for i := 0 to High(Entry.Changes) do
      ApplyNodeSnapshot(Entry.Changes[i].AfterValue);

    FHistory.PushUndo(Entry);
    RebuildLayout;
    RecalcCounters;
    Invalidate;
  except
    Entry.Free;
    raise;
  end;
end;

function TGanttControl.FindNodeIndexById(const NodeId: Integer): Integer;
begin
  if (FNodeIdToIndex <> nil) and FNodeIdToIndex.TryGetValue(NodeId, Result) then
    Exit;
  Result := -1;
end;

function TGanttControl.FindNodeLayoutIndexByNodeIndex(const NodeIndex: Integer): Integer;
var
    j: Integer;
begin
    Result := -1;
    for j := 0 to High(FNodeLayouts) do
      if FNodeLayouts[j].NodeIndex = NodeIndex then
        Exit(j);
end;

function TGanttControl.FindNodesByTrabajo(const NumeroTrabajo: string): TArray<Integer>;
var
  dataIds: TArray<Integer>;
  dataId: Integer;
  list: TList<Integer>;
  outList: TList<Integer>;
begin
  SetLength(Result, 0);

  if (FNodeRepo = nil) or (FDataIdToNodeIdxs = nil) then Exit;

  dataIds := FNodeRepo.FindByTrabajo(NumeroTrabajo);
  if Length(dataIds) = 0 then Exit;

  outList := TList<Integer>.Create;
  try
    for dataId in dataIds do
      if FDataIdToNodeIdxs.TryGetValue(dataId, list) then
        outList.AddRange(list);

    Result := outList.ToArray;
  finally
    outList.Free;
  end;
end;


procedure TGanttControl.ScrollNodeIntoView(const NodeIndex: Integer; const Center: Boolean);
var
  rw: TRectF;
  maxX, maxY: Single;
  targetX, targetY: Single;
begin
  if not TryGetNodeLayoutRectWorld(NodeIndex, rw) then Exit;

  maxX := Max(0, FContentWidth - ClientWidth);
  maxY := Max(0, FContentHeight - ClientHeight);

  if Center then
  begin
    targetX := (rw.Left + rw.Right) * 0.5 - (ClientWidth * 0.5);
    targetY := (rw.Top + rw.Bottom) * 0.5 - (ClientHeight * 0.5);
  end
  else
  begin
    // mínim perquè quedi dins (no centrat)
    targetX := FScrollX;
    if rw.Left < FScrollX then targetX := rw.Left;
    if rw.Right > FScrollX + ClientWidth then targetX := rw.Right - ClientWidth;

    targetY := FScrollY;
    if rw.Top < FScrollY then targetY := rw.Top;
    if rw.Bottom > FScrollY + ClientHeight then targetY := rw.Bottom - ClientHeight;
  end;

  FScrollX := EnsureRange(targetX, 0, maxX);
  FScrollY := EnsureRange(targetY, 0, maxY);

  UpdateScrollBars;
  Invalidate;
  NotifyViewportChanged;

  // si tens event OnScrollYChanged:
  if Assigned(FOnScrollYChanged) then
    FOnScrollYChanged(Self, FScrollY);
end;

function TGanttControl.ReplanAllFromDate(const AFromDate: TDateTime;
  const MinGapMin: Integer; out ElapsedMs: Int64; out MovedCount: Integer): Boolean;
type
  TReplanRec = record
    NodeIdx: Integer;
    FechaEntrega: TDateTime;
    Prioridad: Integer;
    InDegree: Integer;
  end;
var
  SW: TStopwatch;
  I, J, K, N: Integer;
  D: TNodeData;
  Recs: TArray<TReplanRec>;
  NodeIdToRecIdx: TDictionary<Integer, Integer>;
  Successors: TDictionary<Integer, TList<Integer>>;
  Queue: TList<Integer>;
  RecIdx, SuccRecIdx: Integer;
  CentreId: Integer;
  NewStart, PrevEnd, DepMinStart: TDateTime;
  CentreLast: TDictionary<Integer, TDateTime>;  // per centres seqüencials
  CentreLaneOcc: TDictionary<Integer, TLaneOccupancy>; // per centres no-seqüencials
  SuccList: TList<Integer>;
  PredNodeIdx: Integer;
  Occ: TLaneOccupancy;
  Centre: TCentreTreball;
  CIdx: Integer;
begin
  Result := False;
  MovedCount := 0;

  SW := TStopwatch.StartNew;
  try
    if FNodeRepo = nil then Exit;

    // ─── 1) Construir Recs amb dades de prioritat ───
    N := 0;
    SetLength(Recs, Length(FNodes));
    NodeIdToRecIdx := TDictionary<Integer, Integer>.Create;
    try
      for I := 0 to High(FNodes) do
      begin
        if not FNodes[I].Visible then Continue;
        if FNodes[I].DataId = 0 then Continue;
        if not FNodeRepo.TryGetById(FNodes[I].DataId, D) then Continue;

        Recs[N].NodeIdx := I;
        Recs[N].FechaEntrega := D.FechaEntrega;
        Recs[N].Prioridad := D.Prioridad;
        Recs[N].InDegree := 0;
        NodeIdToRecIdx.AddOrSetValue(FNodes[I].Id, N);
        Inc(N);
      end;
      SetLength(Recs, N);
      if N = 0 then Exit;

      // ─── 2) Construir graf de dependències i calcular InDegree ───
      Successors := TDictionary<Integer, TList<Integer>>.Create;
      try
        for I := 0 to N - 1 do
          Successors.Add(FNodes[Recs[I].NodeIdx].Id, TList<Integer>.Create);

        for I := 0 to High(FLinks) do
        begin
          if not NodeIdToRecIdx.ContainsKey(FLinks[I].FromNodeId) then Continue;
          if not NodeIdToRecIdx.ContainsKey(FLinks[I].ToNodeId) then Continue;

          SuccRecIdx := NodeIdToRecIdx[FLinks[I].ToNodeId];

          if Successors.TryGetValue(FLinks[I].FromNodeId, SuccList) then
            SuccList.Add(SuccRecIdx);

          Inc(Recs[SuccRecIdx].InDegree);
        end;

        // ─── 3) Topological sort (Kahn) ───
        Queue := TList<Integer>.Create;
        CentreLast := TDictionary<Integer, TDateTime>.Create;
        CentreLaneOcc := TDictionary<Integer, TLaneOccupancy>.Create;
        try
          for I := 0 to N - 1 do
            if Recs[I].InDegree = 0 then
              Queue.Add(I);

          Queue.Sort(TComparer<Integer>.Construct(
            function(const A, B: Integer): Integer
            begin
              if Recs[A].FechaEntrega < Recs[B].FechaEntrega then Exit(-1);
              if Recs[A].FechaEntrega > Recs[B].FechaEntrega then Exit(1);
              if Recs[A].Prioridad < Recs[B].Prioridad then Exit(-1);
              if Recs[A].Prioridad > Recs[B].Prioridad then Exit(1);
              Result := 0;
            end));

          // ─── 4) Processar la cua ───
          J := 0;
          while J < Queue.Count do
          begin
            RecIdx := Queue[J];
            Inc(J);

            K := Recs[RecIdx].NodeIdx;
            CentreId := FNodes[K].CentreId;

            // a) Data mínima: AFromDate
            NewStart := AFromDate;

            // b) Dependències: el node no pot començar abans que els seus predecessors permetin
            for I := 0 to High(FLinks) do
            begin
              if FLinks[I].ToNodeId <> FNodes[K].Id then Continue;
              PredNodeIdx := FindNodeIndexById(FLinks[I].FromNodeId);
              if PredNodeIdx < 0 then Continue;
              DepMinStart := GetDependencyMinStart(PredNodeIdx, FLinks[I].PorcentajeDependencia);
              if DepMinStart > NewStart then
                NewStart := DepMinStart;
            end;

            // c) Aplicar calendari laboral i fecha de bloqueo
            NewStart := ApplyNodeCalendarAndOverlay(CentreId, NewStart);

            // d) Col·lisions segons tipus de centre
            if IsCentreSequecial(CentreId) then
            begin
              // Centre seqüencial: últim EndTime + gap
              if CentreLast.TryGetValue(CentreId, PrevEnd) then
              begin
                if PrevEnd > NewStart then
                  NewStart := PrevEnd;
                if MinGapMin > 0 then
                  NewStart := IncMinute(NewStart, MinGapMin);
              end;
              NewStart := ApplyNodeCalendarAndOverlay(CentreId, NewStart);
            end
            else
            begin
              // Centre NO seqüencial: buscar lane lliure o avançar en el temps
              if not CentreLaneOcc.TryGetValue(CentreId, Occ) then
              begin
                // Crear occupancy per aquest centre
                CIdx := FindCentreIndexById(CentreId);
                if CIdx >= 0 then
                  Occ := TLaneOccupancy.Create(FCentres[CIdx].MaxLaneCount)
                else
                  Occ := TLaneOccupancy.Create(0);
                CentreLaneOcc.Add(CentreId, Occ);
              end;

              // Buscar lane lliure; si totes plenes, avança NewStart
              Occ.FindFreeLaneOrShift(NewStart, FNodes[K].DurationMin, CentreId, Self);
              NewStart := ApplyNodeCalendarAndOverlay(CentreId, NewStart);
            end;

            // e) Moure el node
            if MoveNodeKeepingDuration(K, NewStart) then
              Inc(MovedCount);

            // f) Registrar ocupació
            if IsCentreSequecial(CentreId) then
            begin
              CentreLast.AddOrSetValue(CentreId, FNodes[K].EndTime);
            end
            else
            begin
              if CentreLaneOcc.TryGetValue(CentreId, Occ) then
              begin
                // Re-buscar la lane (FindFreeLaneOrShift ja ha ajustat NewStart)
                var FinalLane: Integer := 0;
                var FinalEnd: TDateTime := FNodes[K].EndTime;
                for var L := 0 to 999 do
                begin
                  if not Occ.Collides(L, FNodes[K].StartTime, FinalEnd) then
                  begin
                    FinalLane := L;
                    Break;
                  end;
                end;
                Occ.Add(FinalLane, FNodes[K].StartTime, FinalEnd);
              end;
            end;

            // g) Alliberar successors
            if Successors.TryGetValue(FNodes[K].Id, SuccList) then
            begin
              for I := 0 to SuccList.Count - 1 do
              begin
                SuccRecIdx := SuccList[I];
                Dec(Recs[SuccRecIdx].InDegree);
                if Recs[SuccRecIdx].InDegree <= 0 then
                begin
                  var InsPos: Integer := Queue.Count;
                  for var P := J to Queue.Count - 1 do
                  begin
                    var QRec: Integer := Queue[P];
                    if (Recs[SuccRecIdx].FechaEntrega < Recs[QRec].FechaEntrega) or
                       ((Recs[SuccRecIdx].FechaEntrega = Recs[QRec].FechaEntrega) and
                        (Recs[SuccRecIdx].Prioridad < Recs[QRec].Prioridad)) then
                    begin
                      InsPos := P;
                      Break;
                    end;
                  end;
                  Queue.Insert(InsPos, SuccRecIdx);
                end;
              end;
            end;
          end;

        finally
          CentreLast.Free;
          for Occ in CentreLaneOcc.Values do
            Occ.Free;
          CentreLaneOcc.Free;
          Queue.Free;
        end;

      finally
        for SuccList in Successors.Values do
          SuccList.Free;
        Successors.Free;
      end;

    finally
      NodeIdToRecIdx.Free;
    end;

    // ─── 5) Rebuild layout i repintar ───
    if MovedCount > 0 then
    begin
      RebuildLayout;
      Invalidate;
      Result := True;
    end;

  finally
    SW.Stop;
    ElapsedMs := SW.ElapsedMilliseconds;
  end;
end;

function TGanttControl.ReplanAllFromDateV2(const AFromDate: TDateTime;
  const MinGapMin: Integer; out ElapsedMs: Int64; out MovedCount: Integer): Boolean;
{  Versió optimitzada: elimina cerques lineals repetides usant diccionaris
   pre-construïts i substitueix Queue.Insert per un heap binari. }
type
  TReplanRec = record
    NodeIdx: Integer;
    FechaEntrega: TDateTime;
    Prioridad: Integer;
    InDegree: Integer;
    CentreId: Integer;
    DurationMin: Double;
  end;
  TCentreInfo = record
    IsSeq: Boolean;
    MaxLanes: Integer;
    CentreIdx: Integer;
  end;
  TPredLink = record
    PredRecIdx: Integer;
    PctDep: Double;
  end;
var
  SW: TStopwatch;
  I, N: Integer;
  D: TNodeData;
  Recs: TArray<TReplanRec>;
  NodeIdToRecIdx: TDictionary<Integer, Integer>;
  // Predecessors i successors indexats per RecIdx
  Preds: TArray<TArray<TPredLink>>;
  Succs: TArray<TArray<Integer>>;
  // Centre lookup
  CentreInfoMap: TDictionary<Integer, TCentreInfo>;
  CI: TCentreInfo;
  // Kahn amb heap
  Heap: TList<Integer>;
  HeapSize: Integer;
  RecIdx, SuccRecIdx: Integer;
  CentreId: Integer;
  NewStart, DepMinStart: TDateTime;
  CentreLast: TDictionary<Integer, TDateTime>;
  CentreLaneOcc: TDictionary<Integer, TLaneOccupancy>;
  PrevEnd: TDateTime;
  Occ: TLaneOccupancy;
  AdjStart, NewEnd: TDateTime;

  // ── Heap helpers (min-heap per FechaEntrega, després Prioridad) ──
  function HeapLess(A, B: Integer): Boolean;
  begin
    if Recs[A].FechaEntrega < Recs[B].FechaEntrega then Exit(True);
    if Recs[A].FechaEntrega > Recs[B].FechaEntrega then Exit(False);
    Result := Recs[A].Prioridad < Recs[B].Prioridad;
  end;

  procedure HeapPush(Idx: Integer);
  var P, C: Integer;
  begin
    if HeapSize >= Heap.Count then
      Heap.Add(Idx)
    else
      Heap[HeapSize] := Idx;
    C := HeapSize;
    Inc(HeapSize);
    while C > 0 do
    begin
      P := (C - 1) shr 1;
      if HeapLess(Heap[C], Heap[P]) then
      begin
        // swap
        Idx := Heap[P]; Heap[P] := Heap[C]; Heap[C] := Idx;
        C := P;
      end
      else
        Break;
    end;
  end;

  function HeapPop: Integer;
  var P, L, R, S, Tmp: Integer;
  begin
    Result := Heap[0];
    Dec(HeapSize);
    if HeapSize > 0 then
    begin
      Heap[0] := Heap[HeapSize];
      P := 0;
      while True do
      begin
        L := P * 2 + 1;
        R := L + 1;
        S := P;
        if (L < HeapSize) and HeapLess(Heap[L], Heap[S]) then S := L;
        if (R < HeapSize) and HeapLess(Heap[R], Heap[S]) then S := R;
        if S = P then Break;
        Tmp := Heap[P]; Heap[P] := Heap[S]; Heap[S] := Tmp;
        P := S;
      end;
    end;
  end;

begin
  Result := False;
  MovedCount := 0;
  SW := TStopwatch.StartNew;
  try
    if FNodeRepo = nil then Exit;

    // ─── 1) Pre-construir CentreInfoMap ───
    CentreInfoMap := TDictionary<Integer, TCentreInfo>.Create(Length(FCentres));
    try
      for I := 0 to High(FCentres) do
      begin
        CI.IsSeq := FCentres[I].IsSequencial;
        CI.MaxLanes := FCentres[I].MaxLaneCount;
        CI.CentreIdx := I;
        CentreInfoMap.AddOrSetValue(FCentres[I].Id, CI);
      end;

      // ─── 2) Construir Recs ───
      N := 0;
      SetLength(Recs, Length(FNodes));
      NodeIdToRecIdx := TDictionary<Integer, Integer>.Create(Length(FNodes));
      try
        for I := 0 to High(FNodes) do
        begin
          if not FNodes[I].Visible then Continue;
          if FNodes[I].DataId = 0 then Continue;
          if not FNodeRepo.TryGetById(FNodes[I].DataId, D) then Continue;

          Recs[N].NodeIdx := I;
          Recs[N].FechaEntrega := D.FechaEntrega;
          Recs[N].Prioridad := D.Prioridad;
          Recs[N].InDegree := 0;
          Recs[N].CentreId := FNodes[I].CentreId;
          Recs[N].DurationMin := FNodes[I].DurationMin;
          NodeIdToRecIdx.AddOrSetValue(FNodes[I].Id, N);
          Inc(N);
        end;
        SetLength(Recs, N);
        if N = 0 then Exit;

        // ─── 3) Construir Preds[] i Succs[] (arrays, no diccionaris) ───
        SetLength(Preds, N);
        SetLength(Succs, N);
        for I := 0 to High(FLinks) do
        begin
          var FromRec, ToRec: Integer;
          if not NodeIdToRecIdx.TryGetValue(FLinks[I].FromNodeId, FromRec) then Continue;
          if not NodeIdToRecIdx.TryGetValue(FLinks[I].ToNodeId, ToRec) then Continue;

          // Afegir successor
          var SLen := Length(Succs[FromRec]);
          SetLength(Succs[FromRec], SLen + 1);
          Succs[FromRec][SLen] := ToRec;

          // Afegir predecessor
          var PLen := Length(Preds[ToRec]);
          SetLength(Preds[ToRec], PLen + 1);
          Preds[ToRec][PLen].PredRecIdx := FromRec;
          Preds[ToRec][PLen].PctDep := FLinks[I].PorcentajeDependencia;

          Inc(Recs[ToRec].InDegree);
        end;

        // ─── 4) Kahn amb min-heap ───
        Heap := TList<Integer>.Create(N);
        CentreLast := TDictionary<Integer, TDateTime>.Create;
        CentreLaneOcc := TDictionary<Integer, TLaneOccupancy>.Create;
        try
          HeapSize := 0;
          for I := 0 to N - 1 do
            if Recs[I].InDegree = 0 then
              HeapPush(I);

          while HeapSize > 0 do
          begin
            RecIdx := HeapPop;
            CentreId := Recs[RecIdx].CentreId;

            // a) Data mínima
            NewStart := AFromDate;

            // b) Dependències (usant Preds[] pre-construït)
            for I := 0 to High(Preds[RecIdx]) do
            begin
              var PredRec := Preds[RecIdx][I].PredRecIdx;
              var PredNodeIdx := Recs[PredRec].NodeIdx;
              var Pct := Preds[RecIdx][I].PctDep;
              if Pct < 0 then Pct := 0;
              if Pct > 100 then Pct := 100;
              DepMinStart := FNodes[PredNodeIdx].StartTime +
                (FNodes[PredNodeIdx].EndTime - FNodes[PredNodeIdx].StartTime) * (Pct / 100.0);
              if DepMinStart > NewStart then
                NewStart := DepMinStart;
            end;

            // c) Calendari
            NewStart := ApplyNodeCalendarAndOverlay(CentreId, NewStart);

            // d) Col·lisions (usant CentreInfoMap pre-construït)
            if CentreInfoMap.TryGetValue(CentreId, CI) then
            begin
              if CI.IsSeq then
              begin
                if CentreLast.TryGetValue(CentreId, PrevEnd) then
                begin
                  if PrevEnd > NewStart then
                    NewStart := PrevEnd;
                  if MinGapMin > 0 then
                    NewStart := IncMinute(NewStart, MinGapMin);
                end;
                NewStart := ApplyNodeCalendarAndOverlay(CentreId, NewStart);
              end
              else
              begin
                if not CentreLaneOcc.TryGetValue(CentreId, Occ) then
                begin
                  Occ := TLaneOccupancy.Create(CI.MaxLanes);
                  CentreLaneOcc.Add(CentreId, Occ);
                end;
                Occ.FindFreeLaneOrShift(NewStart, Recs[RecIdx].DurationMin, CentreId, Self);
                NewStart := ApplyNodeCalendarAndOverlay(CentreId, NewStart);
              end;
            end;

            // e) Moure node INLINE (evita doble ApplyNodeCalendarAndOverlay)
            var K := Recs[RecIdx].NodeIdx;
            AdjStart := ApplyNodeCalendarAndOverlay(CentreId, NewStart);
            NewEnd := CalcEndTime(CentreId, AdjStart, FNodes[K].DurationMin);
            if (FNodes[K].StartTime <> AdjStart) or (FNodes[K].EndTime <> NewEnd) then
            begin
              FNodes[K].StartTime := AdjStart;
              FNodes[K].EndTime := NewEnd;
              Inc(MovedCount);
            end;

            // f) Registrar ocupació
            if CentreInfoMap.TryGetValue(CentreId, CI) and CI.IsSeq then
            begin
              CentreLast.AddOrSetValue(CentreId, FNodes[K].EndTime);
            end
            else
            begin
              if CentreLaneOcc.TryGetValue(CentreId, Occ) then
              begin
                var FinalLane: Integer := 0;
                var FinalEnd: TDateTime := FNodes[K].EndTime;
                for var L := 0 to 999 do
                begin
                  if not Occ.Collides(L, FNodes[K].StartTime, FinalEnd) then
                  begin
                    FinalLane := L;
                    Break;
                  end;
                end;
                Occ.Add(FinalLane, FNodes[K].StartTime, FinalEnd);
              end;
            end;

            // g) Alliberar successors
            for I := 0 to High(Succs[RecIdx]) do
            begin
              SuccRecIdx := Succs[RecIdx][I];
              Dec(Recs[SuccRecIdx].InDegree);
              if Recs[SuccRecIdx].InDegree <= 0 then
                HeapPush(SuccRecIdx);
            end;
          end;

        finally
          CentreLast.Free;
          for Occ in CentreLaneOcc.Values do
            Occ.Free;
          CentreLaneOcc.Free;
          Heap.Free;
        end;

      finally
        NodeIdToRecIdx.Free;
      end;

    finally
      CentreInfoMap.Free;
    end;

    // ─── 5) Rebuild ───
    if MovedCount > 0 then
    begin
      RebuildLayout;
      Invalidate;
      Result := True;
    end;

  finally
    SW.Stop;
    ElapsedMs := SW.ElapsedMilliseconds;
  end;
end;

procedure TGanttControl.SelectNodeByIndex(const NodeIndex: Integer; const EnsureVisible: Boolean);
begin
  if (NodeIndex < 0) or (NodeIndex > High(FNodes)) then Exit;

  // respecta Enabled/Visible (opcional)
  if not FNodes[NodeIndex].Visible then Exit;
  if not FNodes[NodeIndex].Enabled then Exit;
  if not IsCentreEnabled(FNodes[NodeIndex].CentreId) then Exit;


  FFocusedNodeIndex := NodeIndex;

  if EnsureVisible then
    ScrollNodeIntoView(NodeIndex, True)
  else
    Invalidate;
end;


function TGanttControl.TryGetNodeLayoutRectWorld(const NodeIndex: Integer; out R: TRectF): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(FNodeLayouts) do
    if FNodeLayouts[i].NodeIndex = NodeIndex then
    begin
      R := FNodeLayouts[i].Rect; // WORLD
      Exit(True);
    end;
end;

procedure TGanttControl.Resize;
begin
  inherited;
  UpdateScrollBars;
  NotifyViewportChanged;
  Invalidate;
end;

procedure TGanttControl.NotifyViewportChanged;
var
  T0, T1: TDateTime;
begin
  GetVisibleTimeRange(T0, T1);
  RecalcCounters;

  if Assigned(FOnViewportChanged) then
    FOnViewportChanged(Self, FStartTime, FPxPerMinute, FScrollX);
end;

procedure TGanttControl.TimelineViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
var
  TL: TGanttTimelineControl;
begin
  TL := TGanttTimelineControl(Sender);
  // actualitza fastpaint segons "no-interacting" o l'estat que tinguis guardat
  UpdateFastPaint(FTimelineInteracting, TL.StartVisibleTime, TL.EndVisibleTime);
  // ... actualitza viewport del gantt (scroll/scale)
  // això ja farà el teu Invalidate normal (un sol)
  Invalidate;
end;


procedure TGanttControl.WMLButtonDblClk(var Message: TWMLButtonDblClk);
var
  nodeIdx: Integer;
  mId: Integer;
begin
  inherited;

  // Doble clic a marker? Cancel·lar qualsevol drag en curs
  mId := HitTestMarker(Message.XPos);
  if (mId >= 0) then
  begin
    FDraggingMarkerId := -1;
    FMouseDownMarkerId := -1;
    MouseCapture := False;
    if Assigned(FOnMarkerDblClick) then
      FOnMarkerDblClick(Self, mId);
    Invalidate;
    Exit;
  end;

  // Doble clic a node?
  nodeIdx := HitTestNodeIndex(Message.XPos, Message.YPos);
  if (nodeIdx >= 0) and Assigned(FOnNodeDblClick) then
    FOnNodeDblClick(Self, nodeIdx);
end;

procedure TGanttControl.SetViewport(const AStartTime: TDateTime; const APxPerMinute, AScrollX: Single);
const
  EPS_PX = 0.01;
  EPS_TIME = 1 / 86400; // 1 segon
var
  NewScrollX: Single;
begin
  NewScrollX := Max(0, AScrollX);
  if SameValue(FStartTime, AStartTime, EPS_TIME) and
     SameValue(FPxPerMinute, APxPerMinute, 1E-6) and
     SameValue(FScrollX, NewScrollX, EPS_PX) then
    Exit;

  FStartTime := AStartTime;

  FPxPerMinute := APxPerMinute; //EnsureRange(APxPerMinute, 0.2, 40.0);

  FScrollX := NewScrollX;

  RebuildLayout;

  RecalcCounters;

  Invalidate;
end;



function TGanttControl.SameOF(const ANode1, ANode2: Integer): Boolean;
var
  D1, D2: TNodeData;
begin
  Result := False;
  if not IsValidNodeIndex(ANode1) or not IsValidNodeIndex(ANode2) then
    Exit;
  if not FNodeRepo.TryGetById(FNodes[ANode1].DataId, D1) then
    Exit;
  if not FNodeRepo.TryGetById(FNodes[ANode2].DataId, D2) then
    Exit;
  Result :=
    (D1.NumeroOrdenFabricacion = D2.NumeroOrdenFabricacion) and
    SameText(D1.SerieFabricacion, D2.SerieFabricacion);
end;


function TGanttControl.TryGetNodeData(const ANodeIndex: Integer; out AData: TNodeData): Boolean;
begin
  Result :=
    IsValidNodeIndex(ANodeIndex) and
    FNodeRepo.TryGetById(FNodes[ANodeIndex].DataId, AData);
end;

function TGanttControl.NodeMatchesOF(
  const ANodeIndex: Integer;
  const ANumeroOF: Integer;
  const ASerieOF: string
): Boolean;
var
  D: TNodeData;
begin
  Result := False;
  if not TryGetNodeData(ANodeIndex, D) then
    Exit;
  Result :=
    (D.NumeroOrdenFabricacion = ANumeroOF) and
    SameText(D.SerieFabricacion, ASerieOF);
end;


function TGanttControl.FindFirstNodeIndexOfOF(
  const ANumeroOF: Integer;
  const ASerieOF: string
): Integer;
var
  I: Integer;
  BestTime: TDateTime;
begin
  Result := -1;
  BestTime := 0;

  for I := 0 to High(FNodes) do
  begin
    if not NodeMatchesOF(I, ANumeroOF, ASerieOF) then
      Continue;

    if (Result = -1) or (FNodes[I].StartTime < BestTime) then
    begin
      Result := I;
      BestTime := FNodes[I].StartTime;
    end;
  end;
end;

function TGanttControl.FindFirstOFNodeIndex: Integer;
var
  I: Integer;
  D, BestD: TNodeData;
  BestTime: TDateTime;
begin
  Result := -1;
  BestTime := 0;

  for I := 0 to High(FNodes) do
  begin
    if not TryGetNodeData(I, D) then
      Continue;

    if (Result = -1) or (FNodes[I].StartTime < BestTime) then
    begin
      Result := I;
      BestTime := FNodes[I].StartTime;
      BestD := D;
    end;
  end;

  if Result <> -1 then
    Result := FindFirstNodeIndexOfOF(BestD.NumeroOrdenFabricacion, BestD.SerieFabricacion);
end;


procedure TGanttControl.GetVisibleTimeRange(out T0, T1: TDateTime);
var
  mins0, mins1: Double;
begin
  if FPxPerMinute <= 1e-6 then
  begin
    T0 := FStartTime;
    T1 := FStartTime;
    Exit;
  end;
  mins0 := (FScrollX / FPxPerMinute);
  mins1 := ((FScrollX + ClientWidth) / FPxPerMinute);
  T0 := AddVisibleMinutes(FStartTime, mins0);
  T1 := AddVisibleMinutes(FStartTime, mins1);

  FStartVisibleTime := T0;
  FEndVisibleTime := T1;

end;

function TGanttControl.TimeToX(const ATime: TDateTime): Single;
var
  mins: Double;
begin
  if FPxPerMinute <= 1e-6 then
    Exit(0); // fallback segur

  Mins := VisibleMinutesBetween(FStartTime, ATime);
  Result := (Mins * FPxPerMinute) - FScrollX;
end;

function TGanttControl.TimeToXWorld(const T: TDateTime): Single;
var
  Mins: Double;
begin
  if FPxPerMinute <= 1e-6 then
    Exit(0);
  Mins := VisibleMinutesBetween(FStartTime, T);
  Result := Mins * FPxPerMinute;
end;

function TGanttControl.XToTime(const AX: Single): TDateTime;
var
  mins: Double;
begin
  if FPxPerMinute <= 1e-6 then
    Exit(FStartTime); // fallback segur

  mins := (AX + FScrollX) / FPxPerMinute;
  Result := AddVisibleMinutes(FStartTime, mins);
end;

function TGanttControl.ClientToWorld(const P: TPoint): TPointF;
begin
  // world X: timeline sense scroll; world Y: coordenada de layout sense scroll
  Result.X := P.X + FScrollX;
  Result.Y := P.Y + FScrollY;
end;

function TGanttControl.WorldYToScreenY(const AWorldY: Single): Single;
begin
  Result := AWorldY - FScrollY;
end;

function TGanttControl.RowTopToScreenY(const AWorldY: Single): Single;
begin
  Result := AWorldY - FScrollY;
end;


procedure TGanttControl.WMHScroll(var Message: TWMHScroll);
var
  si: TScrollInfo;
  NewPos: Integer;
  MaxX: Integer;
  isTracking: Boolean;
begin
  if ClientWidth <= 0 then Exit;
  MaxX := Max(0, FContentWidth - ClientWidth);
  FillChar(si, SizeOf(si), 0);
  si.cbSize := SizeOf(si);
  si.fMask := SIF_ALL or SIF_TRACKPOS;
  GetScrollInfo(Handle, SB_HORZ, si);
  NewPos := si.nPos;
  case Message.ScrollCode of
    SB_LINELEFT:   Dec(NewPos, 40);
    SB_LINERIGHT:  Inc(NewPos, 40);
    SB_PAGELEFT:   Dec(NewPos, si.nPage);
    SB_PAGERIGHT:  Inc(NewPos, si.nPage);
    SB_THUMBTRACK,
    SB_THUMBPOSITION:
      NewPos := si.nTrackPos; // clau
  end;
  NewPos := EnsureRange(NewPos, 0, MaxX);
  if NewPos <> Round(FScrollX) then
  begin
    FScrollX := NewPos;
    NotifyViewportChanged;
  end;
  // reflecteix posició
  si.fMask := SIF_POS;
  si.nPos := NewPos;
  SetScrollInfo(Handle, SB_HORZ, si, True);
  isTracking := (Message.ScrollCode = SB_THUMBTRACK);
  FFastPaint := isTracking and (FCNT_TotalVisibleNodes > 50);

  if isTracking then
  begin
    StartScrollInvalidateTimer; // throttle
  end
  else
  begin
    StopScrollInvalidateTimer;
    Invalidate; // repintat immediat per passos/pàgina/final
  end;
end;



procedure TGanttControl.WMVScroll(var Message: TWMVScroll);
var
  si: TScrollInfo;
  NewPos: Integer;
  MaxY: Integer;
  isTracking: Boolean;
begin
  if ClientHeight <= 0 then Exit;

  FillChar(si, SizeOf(si), 0);
  si.cbSize := SizeOf(si);
  si.fMask := SIF_ALL;
  GetScrollInfo(Handle, SB_VERT, si);

  NewPos := si.nPos;

  case Message.ScrollCode of
    SB_LINEUP:     Dec(NewPos, 40);
    SB_LINEDOWN:   Inc(NewPos, 40);
    SB_PAGEUP:     Dec(NewPos, si.nPage);
    SB_PAGEDOWN:   Inc(NewPos, si.nPage);
    SB_THUMBTRACK,
    SB_THUMBPOSITION: NewPos := si.nTrackPos;
  end;

  MaxY := Max(0, FContentHeight - ClientHeight);
  FScrollY := EnsureRange(Single(NewPos), 0, Single(MaxY));

  if Assigned(FOnScrollYChanged) then
   FOnScrollYChanged(Self, FScrollY);

  si.fMask := SIF_POS;
  si.nPos := Round(FScrollY);
  SetScrollInfo(Handle, SB_VERT, si, True);

  isTracking := (Message.ScrollCode = SB_THUMBTRACK);

  FFastPaint := isTracking and (FCNT_TotalVisibleNodes > 50);

  if isTracking then
    StartScrollInvalidateTimer
  else
  begin
    StopScrollInvalidateTimer;
    Invalidate;
  end;
end;


procedure TGanttControl.UpdateNode(const NodeIndex: Integer; const ANode: TNode);
begin
  if (NodeIndex < 0) or (NodeIndex > High(FNodes)) then
    Exit;
  FNodes[NodeIndex] := ANode;
  Invalidate;
end;

function TGanttControl.GetRowsCopy: TArray<TRowLayout>;
var
  i: Integer;
begin
  SetLength(Result, Length(FRows));
  for i := 0 to High(FRows) do
  begin
    Result[i].CentreId := FRows[i].CentreId;
    Result[i].TopY     := FRows[i].TopY;
    Result[i].Height   := FRows[i].Height;
    Result[i].LaneCount:= FRows[i].LaneCount;
    Result[i].NameRect:= FRows[i].NameRect;
    Result[i].GanttRect:= FRows[i].GanttRect;
    Result[i].FirstNodeLayout:= FRows[i].FirstNodeLayout;
    Result[i].LastNodeLayout:= FRows[i].LastNodeLayout;
    Result[i].Order := FRows[i].Order;
    Result[i].Visible := FRows[i].Visible;
    Result[i].Enabled := FRows[i].Enabled;
    Result[i].bkColor := FRows[i].bkColor;
  end;
end;


procedure TGanttControl.ApplyScrollYFromCentres(const AScrollY: Single);
var
  MaxY: Integer;
  newY: Single;
  si: TScrollInfo;
begin
  if ClientHeight <= 0 then Exit;

  MaxY := Max(0, FContentHeight - ClientHeight);
  newY := EnsureRange(AScrollY, 0, MaxY);

  if Abs(newY - FScrollY) < 0.5 then
    Exit;

  FScrollY := newY;

  // actualitza posició del scrollbar vertical
  FillChar(si, SizeOf(si), 0);
  si.cbSize := SizeOf(si);
  si.fMask := SIF_POS;
  si.nPos := Round(FScrollY);
  SetScrollInfo(Handle, SB_VERT, si, True);

  // repintat (si tens timer throttle, crida'l aquí)
  Invalidate;
end;


procedure TGanttControl.RebuildLayout;
const
  RowGap = 6;
  RowTopMargin = 0; //10;
  RowBottomMargin = 0; //10;
  //InnerPadTop = 5;
  //InnerPadBottom = 5;
  LaneGap = 4;
  NodeMinHeight = 24;
  ExtraRightMarginPx = 300;
var
  i: Integer;
  centre: TCentreTreball;
  row: TRowLayout;

  idxs: TArray<Integer>;
  idx: Integer;

  y: Single;

  laneCount: Integer;
  laneH: Single;
  rowH: Single;

  laneRight: TArray<Single>; // world X (right edge occupied) per lane
  laneIdx: Integer;

  node: TNode;
  nl: TNodeLayout;

  maxEndTime: TDateTime;
  centreIdxs: TArray<Integer>;
  ci: Integer;

  function TimeToXWorld(const T: TDateTime): Single;
  begin
    // WORLD coords: no scroll, respecta HideWeekends
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

  y := RowTopMargin;
  maxEndTime := FStartTime;



  SetLength(centreIdxs, Length(FCentres));
  for ci := 0 to High(FCentres) do
   centreIdxs[ci] := ci;
  TArray.Sort<Integer>(centreIdxs,
    TComparer<Integer>.Construct(
      function(const L, R: Integer): Integer
      begin
        Result := FCentres[L].Order - FCentres[R].Order;
      end));

  for i := 0 to High(centreIdxs) do
  begin
    centre := FCentres[centreIdxs[i]];

    if not centre.Visible then
     Continue;

    // ===== Índexs de nodes d'aquest centre (sense copiar nodes) =====
    idxs := GetNodeIndexesForCentre(centre.Id);

    if Length(idxs) > 1 then
      TArray.Sort<Integer>(idxs,
        TComparer<Integer>.Construct(
          function(const L, R: Integer): Integer
          begin
            Result := CompareDateTime(FNodes[L].StartTime, FNodes[R].StartTime);
            if Result = 0 then
              Result := CompareDateTime(FNodes[L].EndTime, FNodes[R].EndTime);
          end));

    // ===== Lane count =====
    if centre.IsSequencial then
      laneCount := 1
    else
    begin
      // packing per calcular quantes lanes fan falta
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
      // Limitar si MaxLaneCount > 0
      if (centre.MaxLaneCount > 0) and (laneCount > centre.MaxLaneCount) then
        laneCount := centre.MaxLaneCount;
    end;

    // ===== Mides verticals =====
    // BaseHeight és "espai total de fila", per tant repartim per lanes
    laneH := Max(NodeMinHeight, (centre.BaseHeight - (laneCount - 1) * LaneGap) / laneCount);
    rowH := (laneCount * laneH) + ((laneCount - 1) * LaneGap) + NODE_INNER_PAD_TOP  + NODE_INNER_PAD_BOTTOM ;

    //...si és sequancial, forcem que la alçada sigui fix
    if laneCount<=1 then
     rowH := centre.BaseHeight + RowGap;

    // ===== Row layout (WORLD) =====
    row.CentreId := centre.Id;
    row.TopY := y;
    row.Height := rowH;
    row.LaneCount := laneCount;

    row.Order := centre.Order;
    row.Visible := centre.Visible;
    row.Enabled := centre.Enabled;

    row.bkColor  := centre.BkColor;

    row.NameRect := TRectF.Create(0, y, 0, y + rowH);
    //row.GanttRect := TRectF.Create(FLeftWidth, y, Max(FLeftWidth + 1, ClientWidth + FScrollX), y + rowH);
    row.GanttRect := TRectF.Create(0, y, 0, y + rowH);

    row.FirstNodeLayout := Length(FNodeLayouts);

    // Nota: GanttRect és només per pintar per fila; el right el fem "gran" en world.
    // L'àrea real visible la limita el screen + scroll.


    // ===== Node layouts =====
    if centre.IsSequencial then
    begin
      for idx in idxs do
      begin
        node := FNodes[idx];

        if not node.Visible then
          Continue;

        //nl.NodeId := node.Id;
        nl.NodeIndex := idx;
        nl.CentreId := node.CentreId;
        nl.LaneIndex := 0;

        nl.Rect := TRectF.Create(
          TimeToXWorld(node.StartTime),
          y + NODE_INNER_PAD_TOP ,
          TimeToXWorld(node.EndTime),
          y + NODE_INNER_PAD_TOP  + laneH
        );

        //...forcem sempre mateixa alçada de Node
        nl.Rect.Bottom := nl.Rect.Top + NodeMinHeight;

        AddNodeLayout(nl);

        if node.EndTime > maxEndTime then
          maxEndTime := node.EndTime;
      end;
    end
    else
    begin
      // packing guardant lane per node
      SetLength(laneRight, 0);

      for idx in idxs do
      begin
        node := FNodes[idx];

        laneIdx := TryFindLane(TimeToXWorld(node.StartTime));
        if laneIdx < 0 then
        begin
          // Si MaxLaneCount > 0 i ja hem arribat al límit, forçar última lane
          if (centre.MaxLaneCount > 0) and (Length(laneRight) >= centre.MaxLaneCount) then
            laneIdx := centre.MaxLaneCount - 1
          else
          begin
            laneIdx := Length(laneRight);
            SetLength(laneRight, laneIdx + 1);
            laneRight[laneIdx] := 0;
          end;
        end;

        //nl.NodeId := node.Id;
        nl.NodeIndex := idx;
        nl.CentreId := node.CentreId;
        nl.LaneIndex := laneIdx;

        nl.Rect := TRectF.Create(
          TimeToXWorld(node.StartTime),
          y + NODE_INNER_PAD_TOP  + laneIdx * (laneH + LaneGap),
          TimeToXWorld(node.EndTime),
          y + NODE_INNER_PAD_TOP  + laneIdx * (laneH + LaneGap) + laneH
        );

        nl.Rect.Bottom := nl.Rect.Top + NodeMinHeight;

        AddNodeLayout(nl);

        laneRight[laneIdx] := TimeToXWorld(node.EndTime);

        if node.EndTime > maxEndTime then
          maxEndTime := node.EndTime;
      end;
    end;

    row.LastNodeLayout := Length(FNodeLayouts) - 1;
    AddRowLayout(row);

    // avançar y
    //y := y + rowH + RowGap;
    y := y + rowH;

  end;

  if FEndTime > maxEndTime then
   maxEndTime := FEndTime;

  maxEndTime := FEndTime;

  // ===== Content size =====
  FContentHeight := Round(y + RowBottomMargin);

  // ample virtual segons maxEndTime
  {FContentWidth :=
    Round(
      FLeftWidth +
      ((maxEndTime - FStartTime) * 24 * 60) * FPxPerMinute +
      ExtraRightMarginPx
    );
  }
  FContentWidth :=
  Round(((FEndTime - FStartTime) * 24 * 60) * FPxPerMinute);
  if FContentWidth < ClientWidth then
   FContentWidth := ClientWidth;

  // clamp segur (mai negatiu)
  if FContentWidth < ClientWidth then
    FContentWidth := ClientWidth;

  if FContentHeight < ClientHeight then
    FContentHeight := ClientHeight;

  UpdateScrollBars;

  if Assigned(FOnLayoutChanged) then
    FOnLayoutChanged(Self);
end;




function TGanttControl.HitTestNodeIndex(const X, Y: Single): Integer;
var
  i: Integer;
  world: TPointF;
  r: TRectF;
  node: TNode;
begin
  Result := -1;
  world := ClientToWorld(Point(Round(X), Round(Y)));
  // Important: els rects de node estan en "world"
  for i := High(FNodeLayouts) downto 0 do
  begin
    r := FNodeLayouts[i].Rect;
    if not r.Contains(world) then
      Continue;
    node := FNodes[FNodeLayouts[i].NodeIndex];
    //  Filtrat per row enabled + node enabled/visible
    if not IsCentreEnabled(node.CentreId) then
      Continue;
    //if not node.Enabled then
    //  Continue;
    if not node.Visible then
      Continue;
    Exit(FNodeLayouts[i].NodeIndex);
  end;
end;


procedure TGanttControl.GetPrevNextNodeInCentre(
  const CentreId, NodeIndex: Integer;
  out PrevIdx, NextIdx: Integer);
var
  i: Integer;
  s, bestPrevEnd, bestNextStart: TDateTime;
begin
  PrevIdx := -1;
  NextIdx := -1;

  s := FNodes[NodeIndex].StartTime;

  bestPrevEnd := 0;
  bestNextStart := 0;

  for i := 0 to High(FNodes) do
  begin
    if i = NodeIndex then
      Continue;
    if FNodes[i].CentreId <> CentreId then
      Continue;

    // anterior: el que acaba més tard però abans (o igual) del nostre start
    if (FNodes[i].EndTime <= s) then
    begin
      if (PrevIdx < 0) or (FNodes[i].EndTime > bestPrevEnd) then
      begin
        PrevIdx := i;
        bestPrevEnd := FNodes[i].EndTime;
      end;
    end;

    // següent: el que comença més aviat però després (o igual) del nostre start
    if (FNodes[i].StartTime >= s) then
    begin
      if (NextIdx < 0) or (bestNextStart = 0) or (FNodes[i].StartTime < bestNextStart) then
      begin
        NextIdx := i;
        bestNextStart := FNodes[i].StartTime;
      end;
    end;
  end;

  // Si el següent detectat és ell mateix per "StartTime igual", ja hem exclòs NodeIndex.
end;

function TGanttControl.GetCentreByIndex(const Index: Integer): TCentreTreball;
begin
  if (Index >= 0) and (Index <= High(FCentres)) then
    Result := FCentres[Index]
  else
    FillChar(Result, SizeOf(Result), 0); // centre buit segur
end;

function TGanttControl.FindCentreIndexById(const CentreId: Integer): Integer;
begin
  if (FCentreIdToIdx <> nil) and FCentreIdToIdx.TryGetValue(CentreId, Result) then
    Exit;
  Result := -1;
end;

function TGanttControl.ClampPxPerMinute(const Value: Single): Single;
const
  MinDaysVisible = 1;
  MaxDaysVisible = 30; // "1 mes" (si vols 31, canvia-ho)
var
  minPx, maxPx: Single;
begin
  if ClientWidth <= 1 then
    Exit(Value);
  // 1 mes visible => px/min petit
  minPx := ClientWidth / (MaxDaysVisible * 24 * 60);
  // 1 dia visible => px/min gran
  maxPx := ClientWidth / (MinDaysVisible * 24 * 60);
  Result := EnsureRange(Value, minPx, maxPx);
end;

function TGanttControl.MaxScrollX: Single;
var
  totalMinutes: Double;
  contentWidth: Single;
begin

  if (FEndTime <= FStartTime) or (ClientWidth <= 1) then
    Exit(0);

  totalMinutes := VisibleMinutesBetween(FStartTime, FEndTime);
  contentWidth := totalMinutes * FPxPerMinute;   // world width (px)

  // max scroll perquè el final quedi dins pantalla
  Result := Max(0, contentWidth - ClientWidth);
end;

function TGanttControl.ClampScrollX(const Value: Single): Single;
begin
  Result := EnsureRange(Value, 0, MaxScrollX);
end;


procedure TGanttControl.UpdateCentre(const CentreId: Integer; const ACentre: TCentreTreball);
var
  idx: Integer;
  needLayout: Boolean;
begin
  idx := FindCentreIndexById(CentreId);
  if idx < 0 then Exit;

  // Si canvies coses que afecten layout -> RebuildLayout
  needLayout :=
    (FCentres[idx].Visible      <> ACentre.Visible) or
    (FCentres[idx].Order        <> ACentre.Order) or
    (FCentres[idx].BaseHeight   <> ACentre.BaseHeight) or
    (FCentres[idx].IsSequencial <> ACentre.IsSequencial);

  // Enabled no necessita layout, només repintat/hit-test
  FCentres[idx] := ACentre;

  if needLayout then
  begin
    RebuildGraphIndex;
    RebuildLayout;
  end;

  Invalidate;
end;



function TGanttControl.TryGetNonWorkingIntervalAt(
  const CentreId: Integer;
  const T: TDateTime;
  out AStartNW, AEndNW: TDateTime
): Boolean;
var
  cal: TCentreCalendar;
  day: TDateTime;
  periods: TArray<TNonWorkingPeriod>;
  p: TNonWorkingPeriod;
  a, b: TDateTime;
begin
  Result := False;
  AStartNW := 0;
  AEndNW := 0;

  cal := GetCalendar(CentreId);
  day := DateOf(T);

  periods := cal.NonWorkingPeriodsForDate(day);

  for p in periods do
  begin
    a := day + p.StartTimeOfDay;
    b := day + p.EndTimeOfDay;

    // si el teu calendari permet intervals que travessen mitjanit,
    // aquí caldria ajustar (però pel teu codi VCL sembla que són intra-dia).
    if (T >= a) and (T < b) then
    begin
      AStartNW := a;
      AEndNW := b;
      Exit(True);
    end;
  end;
end;


function TGanttControl.AdjustToWorkingForward(const CentreId: Integer; const T: TDateTime): TDateTime;
var
  sNW, eNW: TDateTime;
  i: Integer;
begin
  Result := T;

  // Evita bucles infinits (per si calendari mal definit)
  for i := 0 to 32 do
  begin
    if not TryGetNonWorkingIntervalAt(CentreId, Result, sNW, eNW) then
      Exit;
    // si estem dins NW, saltem al final
    Result := eNW;
  end;
end;

function TGanttControl.AdjustToWorkingBackward(const CentreId: Integer; const T: TDateTime): TDateTime;
var
  sNW, eNW: TDateTime;
  i: Integer;
begin
  Result := T;

  for i := 0 to 32 do
  begin
    if not TryGetNonWorkingIntervalAt(CentreId, Result, sNW, eNW) then
      Exit;
    // si estem dins NW, reculem a l’inici
    Result := sNW;
  end;
end;

procedure TGanttControl.DrawNonWorkingShading(const CentreId: Integer; const RowTop, RowBottom: Single);
var
  cal: TCentreCalendar;
  visibleStart, visibleEnd: TDateTime;
  day: TDateTime;
  periods: TArray<TNonWorkingPeriod>;
  p: TNonWorkingPeriod;
  a, b: TDateTime;
  x1, x2: Integer;
  r: TRect;
begin
  cal := GetCalendar(CentreId);

  visibleStart := XToTime(0);
  visibleEnd := XToTime(ClientWidth);

  day := DateOf(visibleStart);
  while day <= DateOf(visibleEnd) do
  begin
    periods := cal.NonWorkingPeriodsForDate(day);
    for p in periods do
    begin
      a := day + p.StartTimeOfDay;
      b := day + p.EndTimeOfDay;

      // retalla al rang visible
      if b <= visibleStart then Continue;
      if a >= visibleEnd then Continue;

      x1 := Round(TimeToX(a));
      x2 := Round(TimeToX(b));

      if x2 < 0 then Continue;
      if x1 > ClientWidth then Continue;

      r := Rect(
        Max(0, x1),
        Round(RowTop),
        Min(ClientWidth, x2),
        Round(RowBottom)
      );

      Canvas.Brush.Color := $00E6E6E6; // ombrejat suau
      Canvas.FillRect(r);
    end;

    day := IncDay(day, 1);
  end;
end;


procedure TGanttControl.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := Params.Style or WS_HSCROLL or WS_VSCROLL;
end;

function TGanttControl.IsCentreEnabled(const CentreId: Integer): Boolean;
var
  k: Integer;
begin
  for k := 0 to High(FCentres) do
    if FCentres[k].Id = CentreId then
      Exit(FCentres[k].Enabled);
  Result := True;
end;

function TGanttControl.IsCentreSequecial(const CentreId: Integer): Boolean;
begin
  if (FCentreIdToIsSeq <> nil) and FCentreIdToIsSeq.TryGetValue(CentreId, Result) then
    Exit;
  Result := True;
end;

procedure TGanttControl.SetRenderMode(const Value: TGanttRenderMode);
begin
  if FRenderMode <> Value then
  begin
    FRenderMode := Value;
    Invalidate;
  end;
end;



procedure TGanttControl.DrawDayGridLinesD2D(
  const RT: ID2D1RenderTarget;
  const GridBrush: ID2D1SolidColorBrush;
  const ClientW, ClientH: Single);
var
  OldM: TD2D1Matrix3x2F;
  M: TD2D1Matrix3x2F;
  T0, T1: TDateTime;
  D, FirstDay, LastDay: TDateTime;
  X, PenWidth: Single;
begin
  if (ClientW <= 1) or (ClientH <= 1) then Exit;
  if FPxPerMinute <= 1e-6 then Exit;

  // IMPORTANT: amb HideWeekends el rang visible s'ha de calcular amb XToTime
  T0 := XToTime(0);
  T1 := XToTime(ClientW);

  FirstDay := DateOf(T0) - 1;
  LastDay  := DateOf(T1) + 1;

  RT.GetTransform(OldM);

  M._11 := 1; M._12 := 0;
  M._21 := 0; M._22 := 1;
  M._31 := 0; M._32 := 0;

  RT.SetTransform(M);

  RT.PushAxisAlignedClip(
    D2D1RectF(0, 0, ClientW, ClientH),
    D2D1_ANTIALIAS_MODE_ALIASED
  );
  try
    D := FirstDay;
    while D <= LastDay do
    begin
      if FHideWeekends and IsWeekend(D) then
      begin
        D := IncDay(D);
        Continue;
      end;

      PenWidth := 1.0;
      X := TimeToX(D); // screen coords

      if DateOf(D) = DateOf(Now) then
        PenWidth := 3.0;

      if (X >= -1) and (X <= ClientW + 1) then
        RT.DrawLine(
          D2D1PointF(X, 0),
          D2D1PointF(X, ClientH),
          GridBrush,
          PenWidth
        );

      D := IncDay(D);
    end;
  finally
    RT.PopAxisAlignedClip;
    RT.SetTransform(OldM);
  end;
end;



procedure TGanttControl.DrawNowLineDashedD2D(
  const RT: ID2D1RenderTarget;
  const NowBrush: ID2D1SolidColorBrush;
  const ClientW, ClientH: Single);
var
  oldM: TD2D1Matrix3x2F;
  M: TD2D1Matrix3x2F;
  x: Single;
  y: Single;
  DashLen, GapLen: Single;
begin
  if (ClientW <= 1) or (ClientH <= 1) then Exit;
  if FPxPerMinute <= 1e-6 then Exit;
  if NowBrush = nil then Exit;

  x := TimeToX(Now);
  if (x < -1) or (x > ClientW + 1) then Exit;

  RT.GetTransform(oldM);

  // identitat
  M._11 := 1; M._12 := 0;
  M._21 := 0; M._22 := 1;
  M._31 := 0; M._32 := 0;
  RT.SetTransform(M);

  RT.PushAxisAlignedClip(D2D1RectF(0, 0, ClientW, ClientH), D2D1_ANTIALIAS_MODE_ALIASED);
  try
    DashLen := 8;  // llarg del traç
    GapLen  := 6;  // espai
    y := 0;

    while y < ClientH do
    begin
      RT.DrawLine(
        D2D1PointF(x, y),
        D2D1PointF(x, Min(y + DashLen, ClientH)),
        NowBrush,
        1.2
      );
      y := y + DashLen + GapLen;
    end;
  finally
    RT.PopAxisAlignedClip;
    RT.SetTransform(oldM);
  end;
end;

procedure TGanttControl.Paint;
begin
  // Decideix el pipeline de pintat
  if (FRenderMode = grmAdvancedD2D) and TDirect2DCanvas.Supported then
    PaintD2D

end;


function TGanttControl.RowTopYByCentreId(const CentreId: Integer): Single;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(FRows) do
    if FRows[i].CentreId = CentreId then
      Exit(FRows[i].TopY);
end;



function TGanttControl.LaneCollidesX(
  const CentreId: Integer; const LaneIdx: Integer;
  const XLeftW, XRightW: Single; const SkipNodeIndex: Integer): Boolean;
var
  i: Integer;
  nl: TNodeLayout;
begin
  for i := 0 to High(FNodeLayouts) do
  begin
    nl := FNodeLayouts[i];
    if nl.NodeIndex = SkipNodeIndex then Continue;
    if nl.CentreId <> CentreId then Continue;
    if nl.LaneIndex <> LaneIdx then Continue;

    if RectsOverlapX(XLeftW, XRightW, nl.Rect.Left, nl.Rect.Right) then
      Exit(True);
  end;
  Result := False;
end;

function TGanttControl.FindNearestFreeLane(
  const CentreId: Integer; const PreferredLane: Integer;
  const XLeftW, XRightW: Single; const LaneCount: Integer; const SkipNodeIndex: Integer): Integer;
var
  d, l: Integer;
begin
  // prova: preferida, després +/-1, +/-2...
  if not LaneCollidesX(CentreId, PreferredLane, XLeftW, XRightW, SkipNodeIndex) then
    Exit(PreferredLane);

  for d := 1 to LaneCount - 1 do
  begin
    l := PreferredLane - d;
    if (l >= 0) and not LaneCollidesX(CentreId, l, XLeftW, XRightW, SkipNodeIndex) then
      Exit(l);

    l := PreferredLane + d;
    if (l < LaneCount) and not LaneCollidesX(CentreId, l, XLeftW, XRightW, SkipNodeIndex) then
      Exit(l);
  end;

  Result := PreferredLane; // si totes col·lideixen, queda on volies
end;




/// Aplica bkColorOp/borderColorOp segons el criteri:
///  - Type 0: només el node amb DataID
///  - Type 1: tots els nodes amb NumeroTrabajo = iOT (agafat del node base si iOT=0)
///  - Type 2: tots els nodes amb NumeroFabricacion=iOF i SerieFabricacion=sOF (agafat del node base si buit/0)
/// Retorna quants nodes s'han modificat.
/// </summary>
function TGanttControl.ApplyOpColorsByNode(
  const ADataID: Integer;
  const AType: TOpColorApplyType;
  const ANewBkColorOp, ANewBorderColorOp: TColor;
  const AsOT: string = '';
  const AsOF: string = '';
  const AiOF: Integer = 0
): Integer;
var
  i: Integer;
  baseIdx: Integer;
  keyOT, keyOF: Integer;
  keySOF, keySOT: string;
  dataIds: TArray<Integer>;
  dataId: Integer;
  d: TNodeDAta;

  procedure PaintNode(var N: TNodeData);
  begin
    N.bkColorOp := ANewBkColorOp;
    N.borderColorOp := ANewBorderColorOp;
    FNodeRepo.AddOrUpdate(N);
    Inc(Result);
  end;

begin
  Result := 0;

  if (FNodeRepo = nil) or (FDataIdToNodeIdxs = nil) then Exit;


  // Type 0: només aquest node
  if AType = octOnlyNode then
  begin
    if FNodeRepo.TryGetById(AdataId, d) then
     PaintNode( d );
    Exit;
  end;

  // prepara claus segons Type, permetent que el caller les passi o que surtin del node base
  case AType of
    octByTrabajo:
      begin
        keyOF := AiOF;
        keySOT := AsOT;
        keySOF := AsOF;


        {
        nodes: TArray<Integer>;
  iVal: Integer;
begin
  if not Assigned(FGantt) then
   Exit;

  iVal := 20000 + strtointdef( SearchBox1.Text, 0);

  if radiobutton1.checked then
   nodes := FGantt.FindNodesByOF( iVal, 'A')
  else
   nodes := FGantt.FindNodesByTrabajo('TR-001');
   }
        dataIds := FNodeRepo.FindByTrabajo(keySOT);
        //dataIds := FNodeRepo.FindByTrabajo(inttostr(keyOT));
        if Length(dataIds) = 0 then Exit;

        try
          for dataId in dataIds do
            if FNodeRepo.TryGetById(dataId, d) then
             PaintNode(d);
        finally
        end;

      end;

    octByFabricacionSerie:
      begin
        keyOF := AiOF;
        keySOF := AsOF;

        dataIds := FNodeRepo.FindByOF(AiOF, AsOF);
        if Length(dataIds) = 0 then Exit;

        try
          for dataId in dataIds do
            if FNodeRepo.TryGetById(dataId, d) then
             PaintNode(d);
        finally
        end;

      end;
  end;
end;


procedure TGanttControl.GetNodeStyle(
  const Node: TNode; const D: TNodeData; const HasData: Boolean;
  const IsSel, IsHover, IsHi: Boolean; out S: TGanttNodeStyle);
var
  progress: Double;
  deltaMin: Integer;
  slackDays: Double;
  dep: Double;
  planSecs, estSecs: Double;
begin
  // ===== Defaults (Vista Normal) =====
  S.Fill := Node.FillColor;
  S.Border := Node.BorderColor;
  S.Alpha := 1.0;
  S.Text := clBlack;

  S.BadgeText := '';
  S.BadgeFill := clBlack;
  S.BadgeTextColor := clWhite;

  S.Progress := -1;
  S.ProgressFill := COL_INFO_BORDER;

  case FVista of

    // ============================================================
    gvmNormal:
      begin
        // Manté colors de la OF
      end;

    // ============================================================
    gvmOptimitzacio:
      begin
        if HasData and (D.DurationMinOriginal > 0) then
        begin
          deltaMin := Round(Node.DurationMin - D.DurationMinOriginal);

          if deltaMin < 0 then
          begin
            S.Fill := COL_OK_FILL;
            S.Border := COL_OK_BORDER;
          end
          else if deltaMin = 0 then
          begin
            S.Fill := COL_NEUTRAL_FILL;
            S.Border := COL_NEUTRAL_BORDER;
          end
          else
          begin
            S.Fill := COL_BAD_FILL;
            S.Border := COL_BAD_BORDER;
          end;

          if deltaMin <> 0 then
          begin
            S.BadgeText := Format('%+dm', [deltaMin]);
            S.BadgeFill := S.Border;
            S.BadgeTextColor := clWhite;
          end;
        end;
      end;

    // ============================================================
    gvmFabricacio:
      begin
        if HasData and (D.UnidadesAFabricar > 0) then
        begin
          progress := SafeDiv(D.UnidadesFAbricadas, D.UnidadesAFabricar);
          S.Progress := Clamp01D(progress);

          if progress < 0.33 then
          begin
            S.Fill := COL_BAD_FILL;
            S.Border := COL_BAD_BORDER;
          end
          else if progress < 0.85 then
          begin
            S.Fill := COL_WARN_FILL;
            S.Border := COL_WARN_BORDER;
          end
          else
          begin
            S.Fill := COL_OK_FILL;
            S.Border := COL_OK_BORDER;
          end;

          S.BadgeText := Format('%d%%', [Round(S.Progress * 100)]);
          S.BadgeFill := S.Border;
          S.BadgeTextColor := clWhite;

          S.ProgressFill := COL_INFO_BORDER;
        end;
      end;

    // ============================================================
    gvmFechaEntrega:
      begin
        if HasData and (D.FechaEntrega > 0) then
        begin
          slackDays := (Node.EndTime - D.FechaEntrega);
          var diffDays: Integer := Round(slackDays);

          if slackDays > 0 then
          begin
            // Tard: estem passats de la data d'entrega
            S.Fill := COL_BAD_FILL;
            S.Border := COL_BAD_BORDER;
            S.BadgeText := '+' + IntToStr(diffDays);
          end
          else if (-slackDays) <= 1 then
          begin
            // Just: queda 1 dia o menys
            S.Fill := COL_WARN_FILL;
            S.Border := COL_WARN_BORDER;
            S.BadgeText := IntToStr(diffDays);
          end
          else
          begin
            // OK: queden dies de marge
            S.Fill := COL_OK_FILL;
            S.Border := COL_OK_BORDER;
            S.BadgeText := IntToStr(diffDays);
          end;

          S.BadgeFill := S.Border;
          S.BadgeTextColor := clWhite;
        end;
      end;

    // ============================================================
    gvmStock:
      begin
        if HasData and (D.UnidadesAFabricar > 0) then
        begin
          if D.Stock >= D.UnidadesAFabricar then
          begin
            S.Fill := COL_OK_FILL;
            S.Border := COL_OK_BORDER;
            S.BadgeText := 'OK';
          end
          else if D.Stock >= (0.5 * D.UnidadesAFabricar) then
          begin
            S.Fill := COL_WARN_FILL;
            S.Border := COL_WARN_BORDER;
            S.BadgeText := 'Just';
          end
          else
          begin
            S.Fill := COL_BAD_FILL;
            S.Border := COL_BAD_BORDER;
            S.BadgeText := 'NO';
          end;

          S.BadgeFill := S.Border;
          S.BadgeTextColor := clWhite;
        end;
      end;

    // ============================================================
    gvmOperarios:
      begin
        if HasData then
        begin
          S.BadgeText := '';

          if D.OperariosNecesarios <= 0 then
          begin
            S.Fill := COL_NEUTRAL_FILL;
            S.Border := COL_NEUTRAL_BORDER;
          end
          else
          begin
            if D.OperariosAsignados <= 0 then
            begin
              S.Fill := COL_BAD_FILL;
              S.Border := COL_BAD_BORDER;
            end
            else if D.OperariosAsignados < D.OperariosNecesarios then
            begin
              // Amarillo: badge con cantidad
              S.Fill := COL_WARN_FILL;
              S.Border := COL_WARN_BORDER;
              S.BadgeText := Format('%d/%d', [D.OperariosAsignados, D.OperariosNecesarios]);
              S.BadgeFill := S.Border;
              S.BadgeTextColor := clWhite;
            end
            else
            begin
              S.Fill := COL_OK_FILL;
              S.Border := COL_OK_BORDER;
            end;
          end;
        end;
      end;

    // ============================================================
    gvmCarga:
      begin
        if HasData and (D.UnidadesAFabricar > 0) and (D.TiempoUnidadFabSecs > 0) then
        begin
          planSecs := D.UnidadesAFabricar * D.TiempoUnidadFabSecs;
          estSecs  := Node.DurationMin * 60; // si DurationMin és minuts

          progress := SafeDiv(estSecs, planSecs);

          if progress > 1.1 then
          begin
            S.Fill := COL_BAD_FILL;
            S.Border := COL_BAD_BORDER;
          end
          else if progress >= 0.9 then
          begin
            S.Fill := COL_WARN_FILL;
            S.Border := COL_WARN_BORDER;
          end
          else
          begin
            S.Fill := COL_OK_FILL;
            S.Border := COL_OK_BORDER;
          end;

          S.BadgeText := Format('x%.2f', [progress]);
          S.BadgeFill := S.Border;
          S.BadgeTextColor := clWhite;
        end;
      end;


      gvmEstado:
      begin
        if HasData then
        begin
          case D.Estado of

            nePendiente:
              begin
                S.Fill := COL_NEUTRAL_FILL;
                S.Border := COL_NEUTRAL_BORDER;
                S.BadgeText := 'Pend';
              end;

            neEnCurso:
              begin
                S.Fill := COL_INFO_FILL;
                S.Border := COL_INFO_BORDER;
                S.BadgeText := 'Curs';
              end;

            neFinalizado:
              begin
                S.Fill := COL_OK_FILL;
                S.Border := COL_OK_BORDER;
                S.BadgeText := 'OK';
              end;

            neBloqueado:
              begin
                S.Fill := COL_BAD_FILL;
                S.Border := COL_BAD_BORDER;
                S.BadgeText := 'BLK';
              end;

          end;

          S.BadgeFill := S.Border;
          S.BadgeTextColor := clWhite;
        end;
      end;


     gvmPrioridad:
      begin
        if HasData then
        begin
          case D.Prioridad of

            1: // Alta
              begin
                S.Fill := COL_BAD_FILL;
                S.Border := COL_BAD_BORDER;
                S.BadgeText := 'P1';
              end;

            2: // Mitja
              begin
                S.Fill := COL_WARN_FILL;
                S.Border := COL_WARN_BORDER;
                S.BadgeText := 'P2';
              end;

            3: // Baixa
              begin
                S.Fill := COL_OK_FILL;
                S.Border := COL_OK_BORDER;
                S.BadgeText := 'P3';
              end;

          else
              begin
                S.Fill := COL_NEUTRAL_FILL;
                S.Border := COL_NEUTRAL_BORDER;
                S.BadgeText := 'P?';
              end;
          end;

          S.BadgeFill := S.Border;
          S.BadgeTextColor := clWhite;
        end;
      end;

     gvmRendimiento:
      begin
        if HasData and
           (D.UnidadesFAbricadas > 0) and
           (D.TiempoUnidadFabSecs > 0) then
        begin
          // Temps estàndard segons unitats realment fabricades
          var tiempoEstandardSecs :=
              D.UnidadesFAbricadas * D.TiempoUnidadFabSecs;

          // Temps real assignat al node
          var tiempoRealSecs :=
              Node.DurationMin * 60;   // ← si DurationMin és minuts

          var ratio := SafeDiv(tiempoRealSecs, tiempoEstandardSecs);

          // Colors segons rendiment
          if ratio > 1.1 then
          begin
            S.Fill := COL_BAD_FILL;
            S.Border := COL_BAD_BORDER;
          end
          else if ratio >= 0.9 then
          begin
            S.Fill := COL_WARN_FILL;
            S.Border := COL_WARN_BORDER;
          end
          else
          begin
            S.Fill := COL_OK_FILL;
            S.Border := COL_OK_BORDER;
          end;

          // Badge amb factor
          S.BadgeText := Format('x%.2f', [ratio]);
          S.BadgeFill := S.Border;
          S.BadgeTextColor := clWhite;

          // Progress visual opcional (0.5 .. 1.5 normalitzat)
          S.Progress := Clamp01D(ratio / 1.5);
          S.ProgressFill := COL_INFO_BORDER;
        end;
      end;

      gvmColores:
      begin
        if HasData then
        begin
           S.Fill   := d.bkColorOp;
           S.Border := d.borderColorOp;
        end;
      end;


      gvmModificaciones:
      begin
        if HasData then
        begin
          S.BadgeText := '';

          if not D.Modified then
          begin
                S.Fill := COL_NEUTRAL_FILL;
                S.Border := COL_NEUTRAL_BORDER;
          end
          else
          begin
                S.Fill := COL_OK_FILL;
                S.Border := COL_OK_BORDER;
          end;
        end;
      end;

  end;

  // ===== Overlay UI =====
  if IsSel then
    S.Border := clBlack;

  if IsHi and (not IsSel) then
    S.Border := $0000CCFF; // groc daurat (BGR)

  // Filtro de operarios: atenuar nodos no filtrados (mantener colores de estado)
  if FOpFilterActive and (not FOpFilterHideMode) then
  begin
    if not IsNodeOperarioFiltered(Node.DataId) then
      S.Alpha := 0.45;
  end;
end;



function TGanttControl.IsCentreVisible(const ACentreId: Integer): Boolean;
var
  cIdx: Integer;
begin
  cIdx := FindCentreIndexById(ACentreId);
  Result := (cIdx >= 0) and FCentres[cIdx].Visible; // o Enabled/Collapsed, el que facis servir
end;

function TGanttControl.IsRowVisible(const ARowIndex: Integer): Boolean;
begin
  // Hook para descendientes que usen TRowLayout.CentreId como indice de grupo
  // (p.ej. TGanttControlGrupo). Por defecto delega en IsCentreVisible.
  if (ARowIndex >= 0) and (ARowIndex <= High(FRows)) then
    Result := IsCentreVisible(FRows[ARowIndex].CentreId)
  else
    Result := False;
end;

///*****************************************************************************
procedure TGanttControl.PaintD2D;
const
  PAD_X = 4;
  PAD_Y = 2;
var
  i, j, StartIdx: Integer;
  Row: TRowLayout;
  NL: TNodeLayout;
  Node: TNode;

  VisibleXLeft, VisibleXRight: Single;
  VisibleYTop, VisibleYBottom: Single;
  VisibleStartTime, VisibleEndTime: TDateTime;

  Y1, Y2: Integer;
  GanttRectS: TRectF;
  DrawRect: TRectF;

  ICentreIdx: Integer;
  LaneTop: Single;
  LaneIdx: Integer;
  LaneCount: Integer;
  Step: Single;
  LaneH: Single;
  XL, XR, YW, Tmp: Single;
  RowTop: Single;

  MoveRow: TRowLayout;

  IsSel, IsHover, IsHi: Boolean;
  D: TNodeData;
  Style: TGanttNodeStyle;
  HasData: Boolean;

  D2D: TDirect2DCanvas;
  RT: ID2D1RenderTarget;
  FillBrush, StrokeBrush: ID2D1SolidColorBrush;
  DotBrush: ID2D1BitmapBrush;
  TextBrush: ID2D1SolidColorBrush;
  GridBrush: ID2D1SolidColorBrush;
  NowBrush: ID2D1SolidColorBrush;
  LineBrush, HandleBrush: ID2D1SolidColorBrush;
  BlockFill: ID2D1SolidColorBrush;
  BlockHatch: ID2D1SolidColorBrush;

  ResizeNode: TNode;
  MoveNode: TNode;

  function RectFToD2D(const R: TRectF): TD2D1RectF;
  begin
    Result.Left   := R.Left;
    Result.Top    := R.Top;
    Result.Right  := R.Right;
    Result.Bottom := R.Bottom;
  end;

  function RoundedRectToD2D(const R: TRectF; const Radius: Single): TD2D1RoundedRect;
  begin
    Result.Rect := RectFToD2D(R);
    Result.RadiusX := Radius;
    Result.RadiusY := Radius;
  end;

  // Retorna el primer index k dins [L..R] tal que Rect.Right >= X.
  // Si no n’hi ha cap, retorna R+1.
  function LowerBoundNodeRight(const L, R: Integer; const X: Single): Integer;
  var
    Lo, Hi, Mid: Integer;
  begin
    Lo := L;
    Hi := R;
    Result := R + 1;

    while Lo <= Hi do
    begin
      Mid := (Lo + Hi) shr 1;
      if FNodeLayouts[Mid].Rect.Right >= X then
      begin
        Result := Mid;
        Hi := Mid - 1;
      end
      else
        Lo := Mid + 1;
    end;
  end;

  procedure DrawNodeText(const ARect: TRectF; const ANode: TNode; const AData: TNodeData);
  begin
    if FFastPaint then Exit;
    if (ARect.Right - ARect.Left) <= (PAD_X * 2 + 4) then Exit;

    D2D.Brush.Style := bsClear;
    if (not ANode.Enabled) or (not IsCentreEnabled(ANode.CentreId)) then
      D2D.Font.Color := $00555555
    else
      D2D.Font.Color := clBlack;

    RT.PushAxisAlignedClip(
      D2D1RectF(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom),
      D2D1_ANTIALIAS_MODE_PER_PRIMITIVE
    );
    try
      D2D.TextOut(
        Round(ARect.Left) + PAD_X,
        Round(ARect.Top) + PAD_Y,
        ANode.Caption
      );

      if AData.DataId > 0 then
      begin
        D2D.TextOut(
          Round(ARect.Left) + PAD_X,
          Round(ARect.Top) + PAD_Y + 9,
          AData.CodigoArticulo
        );
      end;
    finally
      RT.PopAxisAlignedClip;
      D2D.Brush.Style := bsSolid;
    end;
  end;

  procedure PaintNodeRect(const ANodeLayout: TNodeLayout; var ARectS: TRectF; const ANode: TNode);
  var
    inflate: Single;
  begin
    // Filtro operarios: ocultar nodos no filtrados
    if FOpFilterActive and FOpFilterHideMode and (ANode.DataId > 0) then
      if not IsNodeOperarioFiltered(ANode.DataId) then
        Exit;

    // Filtro operarios: inflate/pulse suave en nodos filtrados
    if FOpFilterActive and (not FOpFilterHideMode) and IsNodeOperarioFiltered(ANode.DataId) then
    begin
      inflate := 2.0 * (0.5 + 0.5 * Sin(FOpFilterPulsePhase)); // oscila suave entre 0 y 2 px
      ARectS.Inflate(inflate, inflate);
    end;

    D.DataId := -1;
    if ANode.DataId > 0 then
      FNodeRepo.TryGetById(ANode.DataId, D);

    IsSel := IsNodeIndexSelected(ANodeLayout.NodeIndex);
    IsHover := (ANodeLayout.NodeIndex = FHoverNodeIndex);
    IsHi := IsNodeHighlighted(ANodeLayout.NodeIndex);
    HasData := (D.DataId > 0);

    GetNodeStyle(ANode, D, HasData, IsSel, IsHover, IsHi, Style);

    if (not ANode.Enabled) or (not IsCentreEnabled(ANode.CentreId)) then
    begin
      Style.Fill   := $00CCCCFF;  // vermell molt clar (BGR)
      Style.Border := $002222AA;  // vermell fosc (BGR)
      Style.Alpha  := 0.85;
      Style.Text   := $00222288;
    end;

    SetBrushColor(FillBrush, Style.Fill, Style.Alpha);
    SetBrushColor(StrokeBrush, Style.Border, 1.0);

    RT.FillRectangle(RectFToD2D(ARectS), FillBrush);

    // Línies diagonals per a nodes disabled
    if (not ANode.Enabled) or (not IsCentreEnabled(ANode.CentreId)) then
    begin
      var DiagBrush: ID2D1BitmapBrush :=
        CreateDiagonalPatternBrush(RT, $AA, $22, $22, 120);
      if Assigned(DiagBrush) then
        RT.FillRectangle(RectFToD2D(ARectS), DiagBrush);
    end;

    // Borde: mas grueso para nodos filtrados
    var borderWidth: Single;
    if FOpFilterActive and (not FOpFilterHideMode) and IsNodeOperarioFiltered(ANode.DataId) then
    begin
      borderWidth := 3.0;
      SetBrushColor(StrokeBrush, clBlack, 1.0);
    end
    else if IsSel then
      borderWidth := 2.0
    else if IsHi then
      borderWidth := 2.2
    else
      borderWidth := 1.0;

    if FFastPaint then
      RT.DrawRectangle(RectFToD2D(ARectS), StrokeBrush, borderWidth)
    else
      RT.DrawRoundedRectangle(
        RoundedRectToD2D(ARectS, 3),
        StrokeBrush,
        borderWidth
      );

    if (Style.Progress >= 0) and (not FFastPaint) then
      DrawProgressBarD2D(RT, FillBrush, ARectS, Style.Progress);

    if (Style.BadgeText <> '') and (not FFastPaint) then
      DrawBadgeD2D(
        D2D, RT, FillBrush, TextBrush, ARectS,
        Style.BadgeText, Style.BadgeFill, Style.BadgeTextColor
      );

    DrawNodeText(ARectS, ANode, D);
  end;

begin
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 7;

  // viewport WORLD
  VisibleXLeft   := FScrollX;
  VisibleXRight  := FScrollX + ClientWidth;
  VisibleYTop    := FScrollY;
  VisibleYBottom := FScrollY + ClientHeight;

  // viewport temporal visible real
  VisibleStartTime := XToTime(0);
  VisibleEndTime   := XToTime(ClientWidth);


  D2D := TDirect2DCanvas.Create(Canvas, ClientRect);
  try
    D2D.BeginDraw;
    try
      RT := D2D.RenderTarget;

      RT.SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
      RT.SetTextAntialiasMode(D2D1_TEXT_ANTIALIAS_MODE_CLEARTYPE);

      RT.CreateSolidColorBrush(D2DColorFromTColor(clWhite, 1.0), nil, FillBrush);
      RT.CreateSolidColorBrush(D2DColorFromTColor(clBlack, 1.0), nil, StrokeBrush);
      RT.CreateSolidColorBrush(D2D1ColorF(0, 0, 0, 1), nil, TextBrush);
      RT.CreateSolidColorBrush(D2D1ColorF(0.88, 0.88, 0.88, 1), nil, GridBrush);
      RT.CreateSolidColorBrush(D2D1ColorF(0.10, 0.45, 0.95, 1.0), nil, NowBrush);

      DotBrush := CreateDotPatternBrush(RT);

      // fons
      SetBrushColor(FillBrush, clWhite, 1.0);
      RT.FillRectangle(RectFToD2D(TRectF.Create(0, 0, ClientWidth, ClientHeight)), FillBrush);

      // separador esquerre
      SetBrushColor(StrokeBrush, clSilver, 1.0);
      RT.DrawLine(D2D1PointF(0, 0), D2D1PointF(0, ClientHeight), StrokeBrush, 1.0);

      DrawNowLineDashedD2D(RT, NowBrush, ClientWidth, ClientHeight);
      DrawDayGridLinesD2D(RT, GridBrush, ClientWidth, ClientHeight);

      // Markers (entre grid lines i nodes)
      if Length(FMarkers) > 0 then
        DrawMarkersD2D(D2D, RT, FillBrush, ClientWidth, ClientHeight);

      FHasResizeNode := False;
      FHasMoveNode := False;

      // ===== Files visibles =====
      for i := 0 to High(FRows) do
      begin
        Row := FRows[i];

        if not IsRowVisible(i) then
          Continue;

        // culling vertical WORLD
        if (Row.TopY + Row.Height) < VisibleYTop then
          Continue;
        if Row.TopY > VisibleYBottom then
          Break;

        Y1 := Round(Row.TopY - FScrollY);
        Y2 := Round((Row.TopY + Row.Height) - FScrollY);

        GanttRectS := TRectF.Create(0, Y1, ClientWidth, Y2);

        if not FFastPaint then
        begin
          DrawNonWorkingShadingRowD2D(
            Row.CentreId,
            GanttRectS,
            VisibleStartTime,
            VisibleEndTime,
            RT,
            FillBrush,
            DotBrush
          );
        end;

        // ===== Nodes visibles de la fila =====
        if Row.FirstNodeLayout <= Row.LastNodeLayout then
        begin
          StartIdx := LowerBoundNodeRight(Row.FirstNodeLayout, Row.LastNodeLayout, VisibleXLeft);
          j := StartIdx;

          while j <= Row.LastNodeLayout do
          begin
            NL := FNodeLayouts[j];

            // ordenats per Left en WORLD
            if NL.Rect.Left > VisibleXRight then
              Break;

            Node := FNodes[NL.NodeIndex];
            DrawRect := NL.Rect;

            // ----- Preview resize -----
            if FResizing and (FResizeNodeIndex = NL.NodeIndex) then
            begin
              DrawRect.Left  := TimeToXWorld(FPreviewStart);
              DrawRect.Right := TimeToXWorld(FPreviewEnd);

              if DrawRect.Right < DrawRect.Left then
              begin
                Tmp := DrawRect.Left;
                DrawRect.Left := DrawRect.Right;
                DrawRect.Right := Tmp;
              end;

              if DrawRect.Right > DrawRect.Left then
              begin
                DrawRect.Offset(-FScrollX, -FScrollY);
                FResizeRectS := DrawRect;
                ResizeNode := Node;
                FHasResizeNode := True;
              end;

              Inc(j);
              Continue;
            end;

            // ----- Preview move -----
            if FMoving and (NL.NodeIndex = FMoveNodeIndex) then
            begin
              XL := TimeToXWorld(FMovePreviewStart);
              XR := TimeToXWorld(FMovePreviewEnd);

              if XR < XL then
              begin
                Tmp := XL;
                XL := XR;
                XR := Tmp;
              end;

              DrawRect.Left  := XL;
              DrawRect.Right := XR;

              if DrawRect.Right <= DrawRect.Left then
              begin
                Inc(j);
                Continue;
              end;

              ICentreIdx := FindCentreIndexById(FMovePreviewCentreId);

              if (ICentreIdx >= 0) and FCentres[ICentreIdx].IsSequencial then
              begin
                RowTop := RowTopYByCentreId(FMovePreviewCentreId);
                DrawRect.Offset(0, (RowTop + NODE_INNER_PAD_TOP) - DrawRect.Top);
              end
              else
              begin
                if TryGetRowByCentreId(FMovePreviewCentreId, MoveRow) and (ICentreIdx >= 0) then
                begin
                  YW := FLastMouseY + FScrollY;
                  LaneCount := MoveRow.LaneCount;
                  LaneH := Max(
                    NODE_MIN_HEIGHT,
                    (FCentres[ICentreIdx].BaseHeight - (LaneCount - 1) * LaneGap) / LaneCount
                  );
                  Step := LaneH + LaneGap;

                  LaneIdx := Trunc((YW - (MoveRow.TopY + NODE_INNER_PAD_TOP) + (Step * 0.5)) / Step);
                  if LaneIdx < 0 then LaneIdx := 0;
                  if LaneIdx > LaneCount - 1 then LaneIdx := LaneCount - 1;

                  LaneTop := MoveRow.TopY + NODE_INNER_PAD_TOP + LaneIdx * Step;
                  DrawRect.Offset(0, LaneTop - DrawRect.Top);
                end
                else
                begin
                  RowTop := DrawRect.Top - NODE_INNER_PAD_TOP;
                  DrawRect.Offset(0, (RowTop + NODE_INNER_PAD_TOP) - DrawRect.Top);
                end;
              end;

              DrawRect.Offset(-FScrollX, -FScrollY);
              FMoveRectS := DrawRect;
              MoveNode := Node;
              FHasMoveNode := True;

              Inc(j);
              Continue;
            end;

            // WORLD -> SCREEN
            DrawRect.Offset(-FScrollX, -FScrollY);

            if DrawRect.Right <= DrawRect.Left then
            begin
              Inc(j);
              Continue;
            end;

            if (DrawRect.Right >= 0) and (DrawRect.Left <= ClientWidth) and
               (DrawRect.Bottom >= 0) and (DrawRect.Top <= ClientHeight) then
            begin
              PaintNodeRect(NL, DrawRect, Node);
            end;

            Inc(j);
          end;
        end;

        // línia inferior de fila
        SetBrushColor(StrokeBrush, $00E0E0E0, 1.0);
        RT.DrawLine(D2D1PointF(0, Y2), D2D1PointF(ClientWidth, Y2), StrokeBrush, 1.0);
      end;

      DrawDependenciesD2D(VisibleXLeft, VisibleXRight, VisibleYTop, VisibleYBottom, RT, StrokeBrush, FillBrush);

      // Preview del link mentre s'arrossega (Ctrl+handle)
      if FLinkDragging and (FLinkFromNodeIndex >= 0) then
      begin
        var liLayoutIdx: Integer;
        if FNodeIndexToLayoutIndex.TryGetValue(FLinkFromNodeIndex, liLayoutIdx) then
        begin
          var liRect: TRectF := FNodeLayouts[liLayoutIdx].Rect;
          liRect.Offset(-FScrollX, -FScrollY);
          var liFromPt: TPointF;
          if FLinkFromEdge = reRight then
            liFromPt := PointF(liRect.Right, (liRect.Top + liRect.Bottom) * 0.5)
          else
            liFromPt := PointF(liRect.Left, (liRect.Top + liRect.Bottom) * 0.5);

          SetBrushColor(StrokeBrush, $0040CC40, 0.85);
          SetBrushColor(FillBrush, $0040CC40, 0.85);
          DrawCurvedArrowD2D(RT, StrokeBrush, FillBrush,
            liFromPt, FLinkPreviewEnd, nil, 2.5, 10, 8);
        end;
      end;

      // Passada overlay: glow groc per a nodes highlighted (OF)
      if (FHighlightSet.Count > 0) and (not FFastPaint) then
      begin
        var hlIdx: Integer;
        var hlLayoutIdx: Integer;
        var hlRect: TRectF;
        for hlIdx in FHighlightSet.Keys do
        begin
          if FNodeIndexToLayoutIndex.TryGetValue(hlIdx, hlLayoutIdx) then
          begin
            hlRect := FNodeLayouts[hlLayoutIdx].Rect;
            hlRect.Offset(-FScrollX, -FScrollY);
            // Glow difuminat: capes expandides amb opacitat decreixent
            // Capes de borde difuminat (només traç, sense fill)
            var gi: Integer;
            for gi := 3 downto 1 do
            begin
              var Expand: Single := gi * 2.0;
              var GlowAlpha: Single := 0.10 + (0.20 * (1.0 - gi / 3));
              var GlowR: TRectF := RectF(
                hlRect.Left - Expand, hlRect.Top - Expand,
                hlRect.Right + Expand, hlRect.Bottom + Expand);
              SetBrushColor(StrokeBrush, $0000D4FF, GlowAlpha); // groc daurat (BGR)
              RT.DrawRoundedRectangle(
                RoundedRectToD2D(GlowR, 3 + Expand), StrokeBrush, 1.5);
            end;
            // Borde groc sòlid per sobre
            SetBrushColor(StrokeBrush, $0000CCFF, 0.85);
            RT.DrawRoundedRectangle(
              RoundedRectToD2D(hlRect, 3), StrokeBrush, 1.5);
          end;
        end;
      end;

      if FFocusedNodeIndex >= 0 then
        DrawSelectedNodeHandlesD2D(RT, FillBrush, StrokeBrush);

      if FHasResizeNode then
      begin
        SetBrushColor(FillBrush, ResizeNode.FillColor, 0.55);
        SetBrushColor(StrokeBrush, ResizeNode.BorderColor, 1.0);
        RT.FillRectangle(RectFToD2D(FResizeRectS), FillBrush);
        RT.DrawRoundedRectangle(RoundedRectToD2D(FResizeRectS, 3), StrokeBrush, 2.0);
      end;

      if FHasMoveNode then
      begin
        SetBrushColor(FillBrush, MoveNode.FillColor, 0.55);
        SetBrushColor(StrokeBrush, MoveNode.BorderColor, 1.0);
        RT.FillRectangle(RectFToD2D(FMoveRectS), FillBrush);
        RT.DrawRoundedRectangle(RoundedRectToD2D(FMoveRectS, 3), StrokeBrush, 2.0);
      end;

      if FFechaBloqueo <> 0 then
      begin
        RT.CreateSolidColorBrush(D2D1ColorF(0.70, 0.80, 0.95, 0.18), nil, BlockFill);
        RT.CreateSolidColorBrush(D2D1ColorF(0.20, 0.35, 0.60, 0.25), nil, BlockHatch);
        DrawBlockedAreaD2D(RT, BlockFill, BlockHatch, ClientWidth, ClientHeight);

        RT.CreateSolidColorBrush(D2D1ColorF(0.10, 0.45, 0.95, 1.0), nil, LineBrush);
        DrawBloqueoLineD2D(RT, LineBrush, HandleBrush, ClientWidth, ClientHeight);
      end;

      DrawMarqueeD2D(RT);

    finally
      D2D.EndDraw;
    end;
  finally
    D2D.Free;
  end;
end;

(*
procedure TGanttControl.PaintD2D;
var
  i, j, startIdx: Integer;
  row: TRowLayout;
  rowMoving: TRowLayout;
  nl: TNodeLayout;
  node: TNode;

  VisibleXLeft, VisibleXRight: Single;
  VisibleYTop, VisibleYBottom: Single;
  VisibleStartTime, VisibleEndTime: TDateTime;

  y1, y2: Integer;
  ganttRectS: TRectF;
  drawRect: TRectF;

  iCentreIdx: Integer;

  laneTop: Single;
  laneIdx: Integer;
  laneCount: Integer;
  step: Single;
  laneH : Single;
  xL, xR, yW, tmp : Single;
  rowTop: Single;

  rText:TRect;
  sText: String;
  OldBkMode: Integer;

  isSel, isHover, isHi: Boolean;

  //...handlers
  cy, cxL, cxR: Single;
  ellL, ellR: TD2D1Ellipse;
  fillC, strokeC: TColor;
  fillalpha: Single;

  fromPt, toPt: TPointF;
  d: TNodeData;

  style: TGanttNodeStyle;

  hasData: Boolean;
  iLastCentreVisible: Integer;
  xPosDependencia: Single;

  D2D: TDirect2DCanvas;
  RT: ID2D1RenderTarget;
  FillBrush, StrokeBrush: ID2D1SolidColorBrush;
  DotBrush: ID2D1BitmapBrush;

  DottedStyle: ID2D1StrokeStyle;
  TextBrush: ID2D1SolidColorBrush;
  GridBrush: ID2D1SolidColorBrush;
  NowBrush: ID2D1SolidColorBrush;
  LineBrush, HandleBrush: ID2D1SolidColorBrush;
  BlockFill: ID2D1SolidColorBrush;
  BlockHatch: ID2D1SolidColorBrush;

  ResizeNode: TNode;
  ResizeIsSel, ResizeIsHover, ResizeIsHi: Boolean;

  MoveNode : TNode;

  // Helpers ------------------------------------------------------------

  // Marges interns del text
  const PAD_X = 4;
  const PAD_Y = 2;



  function RectFToD2D(const R: TRectF): TD2D1RectF;
  begin
    Result.left   := R.Left;
    Result.top    := R.Top;
    Result.right  := R.Right;
    Result.bottom := R.Bottom;
  end;

  function RoundedRectToD2D(const R: TRectF; const Radius: Single): TD2D1RoundedRect;
  begin
    Result.rect := RectFToD2D(R);
    Result.radiusX := Radius;
    Result.radiusY := Radius;
  end;

  function TextColorForBackground(Color: TColor): TColor;
  var
    c: TColor;
    r, g, b: Integer;
    lum: Double;
  begin
    c := ColorToRGB(Color);
    r := GetRValue(c);
    g := GetGValue(c);
    b := GetBValue(c);
    lum := 0.299 * r + 0.587 * g + 0.114 * b;
    if lum > 150 then Result := clBlack else Result := clWhite;
  end;

  // Retorna el primer index k dins [L..R] tal que Rect.Right >= X.
  // Si no n’hi ha cap, retorna R+1.
  function LowerBoundNodeRight(const L, R: Integer; const X: Single): Integer;
  var
    lo, hi, mid: Integer;
  begin
    lo := L;
    hi := R;
    Result := R + 1;

    while lo <= hi do
    begin
      mid := (lo + hi) shr 1;
      if FNodeLayouts[mid].Rect.Right >= X then
      begin
        Result := mid;
        hi := mid - 1;
      end
      else
        lo := mid + 1;
    end;
  end;

begin
  // Config bàsica de font (TextOut de D2D)
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 7;

  VisibleXLeft   := FScrollX;
  VisibleXRight  := FScrollX + ClientWidth;
  VisibleYTop    := FScrollY;
  VisibleYBottom := FScrollY + ClientHeight;
  VisibleStartTime := XToTime(0);
  VisibleEndTime   := XToTime(ClientWidth);


  // Create Direct2D canvas
  D2D := TDirect2DCanvas.Create(Canvas, ClientRect);
  try
    D2D.BeginDraw;
    try
      RT := D2D.RenderTarget;

      // Antialias
      RT.SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
      RT.SetTextAntialiasMode(D2D1_TEXT_ANTIALIAS_MODE_CLEARTYPE);

      // Brushes reutilitzables (molt important per rendiment)
      RT.CreateSolidColorBrush(D2DColorFromTColor(clWhite, 1.0), nil, FillBrush);
      RT.CreateSolidColorBrush(D2DColorFromTColor(clBlack, 1.0), nil, StrokeBrush);

      // Fons
      SetBrushColor(FillBrush, clWhite, 1.0);
      RT.FillRectangle(RectFToD2D(TRectF.Create(0, 0, ClientWidth, ClientHeight)), FillBrush);

      // separador vertical
      SetBrushColor(StrokeBrush, clSilver, 1.0);
      RT.DrawLine(D2D1PointF(0, 0), D2D1PointF(0, ClientHeight), StrokeBrush, 1.0);

      RT.CreateSolidColorBrush(
        D2D1ColorF(0,0,0,1), // negre per defecte
        nil,
        TextBrush
      );

      // IMPORTANT: patró de punts (1 cop per paint)
      DotBrush := CreateDotPatternBrush(RT);

      DottedStyle := CreateDottedStrokeStyle(RT);

      //...pintem linies verticals de dies

      RT.CreateSolidColorBrush(D2D1ColorF(0.10, 0.45, 0.95, 1.0), nil, NowBrush);
      DrawNowLineDashedD2D(RT, NowBrush, ClientWidth, ClientHeight);

      RT.CreateSolidColorBrush(D2D1ColorF(0.88, 0.88, 0.88, 1), nil, GridBrush);
      DrawDayGridLinesD2D(RT, GridBrush, ClientWidth, ClientHeight);

      FHasResizeNode := False;
      FHasMoveNode := False;



      // ===== Files visibles =====
      for i := 0 to High(FRows) do
      begin
        row := FRows[i];

        if not IsRowVisible(i) then Continue;

        // culling vertical en WORLD
        if (row.TopY + row.Height) < VisibleYTop then
          Continue;
        if row.TopY > VisibleYBottom then
          Break;


        // screen Y
        y1 := Round(row.TopY - FScrollY);
        y2 := Round((row.TopY + row.Height) - FScrollY);

        SetBrushColor(FillBrush, row.bkColor, 1.0);
        RT.FillRectangle(RectFToD2D(TRectF.Create(0, y1, ClientWidth, y2)), FillBrush);

        // rect dret visible (screen coords)
        ganttRectS := TRectF.Create(0, y1, ClientWidth, y2);



        if (not FFastPaint) then
        begin
          // Exemple: overlay molt suau (5%) per donar “depth”
          //SetBrushColor(FillBrush, clBlack, 0.03);
          //RT.FillRectangle(RectFToD2D(ganttRectS), FillBrush);

          DrawNonWorkingShadingRowD2D(row.CentreId,
                                      ganttRectS,
                                      VisibleStartTime,
                                      VisibleEndTime,
                                      RT,
                                      FillBrush,
                                      DotBrush);

        end;






        // ===== Nodes visibles d’aquest centre =====
        if (row.FirstNodeLayout <= row.LastNodeLayout) then
        begin
          // binary search del primer node que pot tocar la vista
          startIdx := LowerBoundNodeRight(row.FirstNodeLayout, row.LastNodeLayout, VisibleXLeft);
          j := startIdx;


          while j <= row.LastNodeLayout do
          begin
            nl := FNodeLayouts[j];


            // com estan ordenats per Left, podem parar
            if nl.Rect.Left > VisibleXRight then
              Break;

            node := FNodes[nl.NodeIndex];

            drawRect := nl.Rect;

            if FResizing and (FResizeNodeIndex = nl.NodeIndex) then
            begin
              // IMPORTANT: usa preview sense restriccions
              drawRect.Left  := TimeToX(FPreviewStart) + FScrollX; // world X
              drawRect.Right := TimeToX(FPreviewEnd)   + FScrollX; // world X
              // si estàs arrossegant left i t'ha quedat invertit, arregla visualment
              if drawRect.Right < drawRect.Left then
              begin
                tmp := drawRect.Left;
                drawRect.Left := drawRect.Right;
                drawRect.Right := tmp;
              end;
              drawRect.Offset(-FScrollX, -FScrollY); // SCREEN
              FResizeRectS := drawRect;
              ResizeNode := node;
              ResizeIsSel := (nl.NodeIndex = FFocusedNodeIndex);
              ResizeIsHover := (nl.NodeIndex = FHoverNodeIndex);
              ResizeIsHi := IsNodeHighlighted(nl.NodeIndex);
              FHasResizeNode := True;
              Inc(j);
              Continue; // IMPORTANT: no el pintis ara
            end;

            if FMoving and (nl.NodeIndex = FMoveNodeIndex) then
            begin
              drawRect := nl.Rect;
              // X preview (WORLD)

              // Y preview (WORLD) -> agafa Top de la row destí (mateixa lane index per ara)

              xL := TimeToX(FMovePreviewStart) + FScrollX;
              xR := TimeToX(FMovePreviewEnd)   + FScrollX;

              xL := TimeToXWorld(FMovePreviewStart); // WORLD (sense scroll)
              xR := TimeToXWorld(FMovePreviewEnd);   // WORLD
              if xR < xL then begin tmp := xL; xL := xR; xR := tmp; end;

              drawRect.Left  := xL;
              drawRect.Right := xR;

              iCentreIdx := FindCentreIndexById( FMovePreviewCentreId );

              if (iCentreIdx >= 0) and FCentres[iCentreIdx].IsSequencial then
              begin
               rowTop := RowTopYByCentreId(FMovePreviewCentreId);
               drawRect.Offset(0, (rowTop + NODE_INNER_PAD_TOP) - drawRect.Top);
              end
              else
              begin
                    if TryGetRowByCentreId(FMovePreviewCentreId, row) and (iCentreIdx >= 0) then
                    begin
                      // Mouse Y en WORLD
                      yW := FLastMouseY  + FScrollY;
                      // mateix càlcul que a RebuildLayout
                      laneCount := row.LaneCount;
                      laneH := Max(NODE_MIN_HEIGHT,
                        (FCentres[iCentreIdx].BaseHeight - (laneCount - 1) * LaneGap) / laneCount);
                      step := laneH + LANEGAP;
                      // lane segons Y (snap)
                      laneIdx := Trunc((yW - (row.TopY + NODE_INNER_PAD_TOP) + (step * 0.5)) / step); // arrodoneix a la més propera
                      if laneIdx < 0 then laneIdx := 0;
                      if laneIdx > laneCount - 1 then laneIdx := laneCount - 1;
                      laneTop := row.TopY + NODE_INNER_PAD_TOP + laneIdx * step;
                      drawRect.Offset(0, laneTop - drawRect.Top);
                    end
                    else
                    begin
                      // fallback
                      rowTop := drawRect.Top - NODE_INNER_PAD_TOP;
                      drawRect.Offset(0, (rowTop + NODE_INNER_PAD_TOP) - drawRect.Top);
                    end
              end;

              drawRect.Offset(-FScrollX, -FScrollY); // SCREEN
              FHasMoveNode := True;
              FMoveRectS := drawRect;
              MoveNode := node;
              Inc(j);
              Continue;
            end;
            // world->screen
            drawRect.Offset(-FScrollX, -FScrollY);

            iCentreIdx := FindCentreIndexById( nl.CentreId);
            {
            if iCentreIdx>=0 then
            if FCentres[iCentreIdx].IsSequencial then
            begin
              drawRect.Top := row.TopY + 4;
              drawRect.Bottom := drawRect.Top + 28;
            end;
            }

            // culling extra (screen)
            if (drawRect.Right >= 0) and (drawRect.Left <= ClientWidth) and
               (drawRect.Bottom >= 0) and (drawRect.Top <= ClientHeight) then
            begin

              //...aconseguim Data del node
              d.DataId :=-1;
              if (node.DataId > 0) then
               FNodeRepo.TryGetById(node.DataId, d);

              //if IsNodeFocused(i) then
              isSel := IsNodeIndexSelected( nl.NodeIndex );

              //isSel := (nl.NodeIndex = FFocusedNodeIndex);
              isHover := (nl.NodeIndex = FHoverNodeIndex);
              isHi := IsNodeHighlighted(nl.NodeIndex);

              hasData := (d.DataId > 0);

              GetNodeStyle(node, d, hasData, isSel, isHover, isHi, style);

              // disabled/centre disabled continua sent prioritari si vols:
              if (not node.Enabled) or (not IsCentreEnabled(node.CentreId)) then
              begin
                style.Fill := $00D0D0D0;
                style.Border := $00909090;
                style.Alpha := 0.3;
                style.Text := $00555555;
              end;

              // apply
              SetBrushColor(FillBrush, style.Fill, style.Alpha);
              SetBrushColor(StrokeBrush, style.Border, 1.0);

              // Fill + outline (igual que tens)
              RT.FillRectangle(RectFToD2D(drawRect), FillBrush);
              if FFastPaint then
                RT.DrawRectangle(RectFToD2D(drawRect), StrokeBrush, 1.0)
              else
                RT.DrawRoundedRectangle(RoundedRectToD2D(drawRect, 3), StrokeBrush, IfThen(isSel, 2.0, IfThen(isHi, 1.5, 1.0)));

              // progress (ex: Fabricació)
              if (style.Progress >= 0) and (not FFastPaint) then
              begin
                // usa el teu FillBrush com reutilitzable
                // (si vols el color del style: SetBrushColor(FillBrush, style.ProgressFill, 0.75))
                DrawProgressBarD2D(RT, FillBrush, drawRect, style.Progress);
              end;

              // badge
              if (style.BadgeText <> '') and (not FFastPaint) then
                DrawBadgeD2D(D2D, RT, FillBrush, TextBrush, drawRect, style.BadgeText, style.BadgeFill, style.BadgeTextColor);



              if (not FFastPaint) then
              begin

                // Si no hi ha espai mínim ni ho intentis
                if (drawRect.Right - drawRect.Left) > (PAD_X * 2 + 4) then
                begin
                  // Text sempre negre i sense fons
                  D2D.Brush.Style := bsClear;
                  if (not node.Enabled) or (not IsCentreEnabled(node.CentreId)) then
                   D2D.Font.Color :=  $00555555
                  else
                   D2D.Font.Color := clBlack;

                  // Clip perquè el text quedi tallat dins el node
                  try
                   RT.PushAxisAlignedClip(
                    D2D1RectF(drawRect.Left, drawRect.Top, drawRect.Right, drawRect.Bottom),
                    D2D1_ANTIALIAS_MODE_PER_PRIMITIVE
                  );
                    D2D.TextOut(
                      Round(drawRect.Left) + PAD_X,
                      Round(drawRect.Top) + PAD_Y,
                      node.Caption
                    );

                    //...si tenim vincle amb la DATA, aprofitem i pintem lo necessari
                    if d.DataId > 0 then
                    begin
                        //...pintem text codi article
                        D2D.TextOut(
                          Round(drawRect.Left) + PAD_X,
                          Round(drawRect.Top) + PAD_Y + 9,
                          d.CodigoArticulo
                        );

                        //...pintem linia dependencia
                        {
                        if (d.PorcentajeDependencia>0) and (d.PorcentajeDependencia<100) then
                        begin
                         xPosDependencia := drawRect.left + ((drawRect.Right -drawRect.left) * (d.PorcentajeDependencia/100));
                         RT.DrawLine(D2D1PointF(xPosDependencia, 0), D2D1PointF(xPosDependencia, drawRect.Bottom), StrokeBrush, 1.0);
                        end;
                        }
                    end;

                  finally
                    RT.PopAxisAlignedClip;
                  end;

                 D2D.Brush.Style := bsSolid;
                end;
              end;

            end;

            Inc(j);
          end;
        end;    //...despres de pintar tots els nodes del Row


        // línia inferior
        SetBrushColor(StrokeBrush, $00E0E0E0, 1.0);
        RT.DrawLine(D2D1PointF(0, y2), D2D1PointF(ClientWidth, y2), StrokeBrush, 1.0);

      end; //...despres de pintar tots els nodes


      DrawDependenciesD2D(VisibleXLeft, VisibleXRight, VisibleYTop, VisibleYBottom, RT, StrokeBrush, FillBrush);

      // Preview del link mentre s'arrossega (Ctrl+handle)
      if FLinkDragging and (FLinkFromNodeIndex >= 0) then
      begin
        var liLayoutIdx2: Integer;
        if FNodeIndexToLayoutIndex.TryGetValue(FLinkFromNodeIndex, liLayoutIdx2) then
        begin
          var liRect2: TRectF := FNodeLayouts[liLayoutIdx2].Rect;
          liRect2.Offset(-FScrollX, -FScrollY);
          var liFromPt2: TPointF;
          if FLinkFromEdge = reRight then
            liFromPt2 := PointF(liRect2.Right, (liRect2.Top + liRect2.Bottom) * 0.5)
          else
            liFromPt2 := PointF(liRect2.Left, (liRect2.Top + liRect2.Bottom) * 0.5);

          SetBrushColor(StrokeBrush, $0040CC40, 0.85);
          SetBrushColor(FillBrush, $0040CC40, 0.85);
          DrawCurvedArrowD2D(RT, StrokeBrush, FillBrush,
            liFromPt2, FLinkPreviewEnd, nil, 2.5, 10, 8);
        end;
      end;

      if FFocusedNodeIndex>=0 then
       DrawSelectedNodeHandlesD2D(RT, FillBrush, StrokeBrush);


      if FHasResizeNode then
      begin
          // Transparència mentre redimensiones
          SetBrushColor(FillBrush, ResizeNode.FillColor, 0.55);      // alpha (0.4..0.7 segons gust)
          SetBrushColor(StrokeBrush, ResizeNode.BorderColor, 1.0);
          RT.FillRectangle(RectFToD2D(FResizeRectS), FillBrush);
          RT.DrawRoundedRectangle(RoundedRectToD2D(FResizeRectS, 3), StrokeBrush, 2.0);
          //Si vols, afegeix un overlay suau per “ghost”
          //SetBrushColor(FillBrush, clWhite, 0.12);
          //RT.FillRectangle(RectFToD2D(ResizeRectS), FillBrush);
      end;

      if FHasMoveNode then
      begin
          // Transparència mentre mous
          SetBrushColor(FillBrush, MoveNode.FillColor, 0.55);      // alpha (0.4..0.7 segons gust)
          SetBrushColor(StrokeBrush, MoveNode.BorderColor, 1.0);
          RT.FillRectangle(RectFToD2D(FMoveRectS), FillBrush);
          RT.DrawRoundedRectangle(RoundedRectToD2D(FMoveRectS, 3), StrokeBrush, 2.0);
          //Si vols, afegeix un overlay suau per “ghost”
          //SetBrushColor(FillBrush, clWhite, 0.12);
          //RT.FillRectangle(RectFToD2D(FMoveRectS), FillBrush);
      end;

      // capa gris-blavosa transparent
      if FFechaBloqueo <> 0 then
      begin
            RT.CreateSolidColorBrush(D2D1ColorF(0.70, 0.80, 0.95, 0.18), nil, BlockFill);
            // ratlles una mica més fosques
            RT.CreateSolidColorBrush(D2D1ColorF(0.20, 0.35, 0.60, 0.25), nil, BlockHatch);
            DrawBlockedAreaD2D(RT, BlockFill, BlockHatch, ClientWidth, ClientHeight);

            RT.CreateSolidColorBrush(D2D1ColorF(0.10, 0.45, 0.95, 1.0), nil, LineBrush);
            DrawBloqueoLineD2D( RT, LineBrush, HandleBrush, ClientWidth, ClientHeight);
      end;

      DrawMarqueeD2D(RT);

    finally
      D2D.EndDraw;
    end;
  finally
    D2D.Free;
  end;
end;
*)


procedure TGanttControl.DrawNonWorkingShadingRowD2D(
  const CentreId: Integer;
  const GanttRectS: TRectF;
  const VisibleStart, VisibleEnd: TDateTime;
  const RT: ID2D1RenderTarget;
  const FillBrush: ID2D1SolidColorBrush;
  const DotBrush: ID2D1BitmapBrush);
var
  Cal: TCentreCalendar;
  Day, LastDay: TDateTime;
  Periods: TArray<TNonWorkingPeriod>;
  P: TNonWorkingPeriod;
  A, B: TDateTime;
  X1, X2: Single;
  RS: TRectF;

  function D2DRectF(const R: TRectF): TD2D1RectF;
  begin
    Result := D2D1RectF(R.Left, R.Top, R.Right, R.Bottom);
  end;

  function D2DColorFromTColor(const AColor: TColor; const Alpha01: Single): TD2D1ColorF;
  var
    C: TColor;
    RR, GG, BB: Byte;
  begin
    C := ColorToRGB(AColor);
    RR := GetRValue(C);
    GG := GetGValue(C);
    BB := GetBValue(C);
    Result.r := RR / 255.0;
    Result.g := GG / 255.0;
    Result.b := BB / 255.0;
    Result.a := EnsureRange(Alpha01, 0.0, 1.0);
  end;

  function NextPaintDay(const ADay: TDateTime): TDateTime;
  begin
    Result := IncDay(ADay);
    if FHideWeekends then
      while IsWeekend(Result) do
        Result := IncDay(Result);
  end;

begin
  if (GanttRectS.Right <= GanttRectS.Left) or
     (GanttRectS.Bottom <= GanttRectS.Top) then
    Exit;

  Cal := GetCalendar(CentreId);
  if Cal = nil then
    Exit;

  Day := DateOf(VisibleStart);
  LastDay := DateOf(VisibleEnd);

  if FHideWeekends then
    while IsWeekend(Day) do
      Day := IncDay(Day);


  RT.PushAxisAlignedClip(D2DRectF(GanttRectS), D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
  try
    while Day <= LastDay do
    begin
      Periods := Cal.NonWorkingPeriodsForDate(Day);

      for P in Periods do
      begin

        X1 := TimeToX(Day);
        RT.DrawLine(D2D1PointF(X1, GanttRectS.Top), D2D1PointF(X1, GanttRectS.Bottom), FillBrush, 1.0);

        A := Day + Frac(P.StartTimeOfDay);
        B := Day + Frac(P.EndTimeOfDay);



        if B <= A then
          Continue;

        if B <= VisibleStart then
          Continue;
        if A >= VisibleEnd then
          Continue;

        X1 := TimeToX(A);
        X2 := TimeToX(B);

        if X2 <= X1 then
          Continue;

        RS := TRectF.Create(
          Max(GanttRectS.Left, X1),
          GanttRectS.Top,
          Min(GanttRectS.Right, X2),
          GanttRectS.Bottom
        );

        if RS.Right > RS.Left then
        begin
          FillBrush.SetColor(D2DColorFromTColor($00DCDCDC, 0.18));
          RT.FillRectangle(D2DRectF(RS), FillBrush);

          DotBrush.SetOpacity(0.55);
          RT.FillRectangle(D2DRectF(RS), DotBrush);
        end;
      end;

      Day := NextPaintDay(Day);
    end;
  finally
    RT.PopAxisAlignedClip;
  end;
end;


function TGanttControl.ComputeFastPaint(const Interacting: Boolean;
  const StartVis, EndVis: TDateTime): Boolean;
begin
  if not Interacting then
    Exit(False);
  // FastPaint només si estem interactuant I hi ha més de 50 nodes visibles
  Result := (FCNT_TotalVisibleNodes > 50);
end;
function TGanttControl.UpdateFastPaint(const Interacting: Boolean;
  const StartVis, EndVis: TDateTime): Boolean;
var
  NewFast: Boolean;
begin
  NewFast := ComputeFastPaint(Interacting, StartVis, EndVis);
  Result := (NewFast <> FFastPaint);
  if Result then
    FFastPaint := NewFast;
end;

procedure TGanttControl.TimelineNeedRepaint(Sender: TObject);
begin
  Invalidate; // aquí sí, però només 1 cop quan s'atura
end;


procedure TGanttControl.TimelineInteraction(Sender: TObject; const Interacting: Boolean);
var
  TL: TGanttTimelineControl;
  NewFast: Boolean;
begin
  TL := TGanttTimelineControl(Sender);
  FTimelineInteracting  :=  Interacting;
  FFastPaint := Interacting and (FCNT_TotalVisibleNodes > 50);
  if not Interacting then
    Invalidate;
end;


procedure TGanttControl.DrawTimeGridRow(const GanttRectS: TRectF);
var
  visibleStart, visibleEnd: TDateTime;

  day: TDateTime;
  nextDay: TDateTime;

  h: TDateTime;
  stepMin: Integer;
  m: TDateTime;

  x: Integer;

  function ChooseMinuteStep: Integer;
  var
    pxPerHour: Single;
  begin
    pxPerHour := FPxPerMinute * 60;
    if pxPerHour >= 600 then Exit(5);
    if pxPerHour >= 360 then Exit(10);
    if pxPerHour >= 240 then Exit(15);
    Exit(0);
  end;

begin
  if (GanttRectS.Right <= GanttRectS.Left) then Exit;

  visibleStart := XToTime(Round(GanttRectS.Left));
  visibleEnd := XToTime(Round(GanttRectS.Right));

  // ===== Dies (marcat) =====
  day := DateOf(visibleStart);
  while day <= DateOf(visibleEnd) do
  begin
    x := Round(TimeToX(day));
    if (x >= Round(GanttRectS.Left)) and (x <= Round(GanttRectS.Right)) then
    begin
      Canvas.Pen.Color := $00BFBFBF; // més marcat
      Canvas.MoveTo(x, Round(GanttRectS.Top));
      Canvas.LineTo(x, Round(GanttRectS.Bottom));
    end;
    day := IncDay(day, 1);
  end;

  // ===== Hores (suau) =====
  // primer tick a la següent hora sencera
  h := DateOf(visibleStart);
  h := IncHour(h, HoursBetween(h, visibleStart));
  h := EncodeDateTime(YearOf(h), MonthOf(h), DayOf(h), HourOf(visibleStart), 0, 0, 0);
  if h < visibleStart then
    h := IncHour(h, 1);

  while h <= visibleEnd do
  begin
    x := Round(TimeToX(h));
    if (x >= Round(GanttRectS.Left)) and (x <= Round(GanttRectS.Right)) then
    begin
      Canvas.Pen.Color := $00DDDDDD;
      Canvas.MoveTo(x, Round(GanttRectS.Top));
      Canvas.LineTo(x, Round(GanttRectS.Bottom));
    end;
    h := IncHour(h, 1);
  end;

  // ===== Minuts (molt suau, depèn del zoom) =====
  stepMin := ChooseMinuteStep;
  if stepMin > 0 then
  begin
    m := EncodeDateTime(YearOf(visibleStart), MonthOf(visibleStart), DayOf(visibleStart),
                        HourOf(visibleStart), (MinuteOf(visibleStart) div stepMin) * stepMin, 0, 0);
    if m < visibleStart then
      m := IncMinute(m, stepMin);

    while m <= visibleEnd do
    begin
      x := Round(TimeToX(m));
      if (x >= Round(GanttRectS.Left)) and (x <= Round(GanttRectS.Right)) then
      begin
        Canvas.Pen.Color := $00F0F0F0;
        Canvas.MoveTo(x, Round(GanttRectS.Top));
        Canvas.LineTo(x, Round(GanttRectS.Bottom));
      end;
      m := IncMinute(m, stepMin);
    end;
  end;
end;


procedure TGanttControl.DrawNonWorkingShadingRow(const CentreId: Integer; const GanttRectS: TRectF);
var
  cal: TCentreCalendar;
  visibleStart, visibleEnd: TDateTime;
  day: TDateTime;
  periods: TArray<TNonWorkingPeriod>;
  p: TNonWorkingPeriod;
  a, b: TDateTime;
  x1, x2: Integer;
  r: TRect;
begin
  if (GanttRectS.Right <= GanttRectS.Left) then Exit;
  if (GanttRectS.Bottom <= GanttRectS.Top) then Exit;

  cal := GetCalendar(CentreId);

  // rang visible segons la part dreta (screen)
  visibleStart := XToTime(Round(GanttRectS.Left));
  visibleEnd := XToTime(Round(GanttRectS.Right));

  day := DateOf(visibleStart);
  while day <= DateOf(visibleEnd) do
  begin
    periods := cal.NonWorkingPeriodsForDate(day);

    for p in periods do
    begin
      a := day + p.StartTimeOfDay;
      b := day + p.EndTimeOfDay;

      if b <= visibleStart then Continue;
      if a >= visibleEnd then Continue;

      x1 := Round(TimeToX(a));
      x2 := Round(TimeToX(b));

      r := Rect(
        Max(Round(GanttRectS.Left), x1),
        Round(GanttRectS.Top),
        Min(Round(GanttRectS.Right), x2),
        Round(GanttRectS.Bottom)
      );

      if r.Right > r.Left then
      begin
        Canvas.Brush.Color := $00DCDCDC;
        Canvas.FillRect(r);
      end;
    end;

    day := IncDay(day, 1);
  end;
end;





function TGanttControl.TryGetNonWorkingIntervalMergedAt(
  const CentreId: Integer;
  const T: TDateTime;
  const ARadiusDays: Integer;
  out AStart, AEnd: TDateTime
): Boolean;
var
  cal: TCentreCalendar;
  baseDay: TDateTime;

  function ExpandInterval(var S, E: TDateTime): Boolean;
  var
    changed: Boolean;
    d: Integer;
    day: TDateTime;
    periods: TArray<TNonWorkingPeriod>;
    p: TNonWorkingPeriod;
    s2, e2: TDateTime;
  begin
    Result := False;
    repeat
      changed := False;

      // Busquem intervals que solapen/enganxin amb [S..E]
      for d := -ARadiusDays to ARadiusDays do
      begin
        day := IncDay(DateOf(S), d);
        periods := cal.NonWorkingPeriodsForDate(day);

        for p in periods do
        begin
          s2 := day + p.StartTimeOfDay;
          e2 := day + p.EndTimeOfDay;

          // travessa mitjanit
          if p.EndTimeOfDay <= p.StartTimeOfDay then
            e2 := IncDay(day, 1) + p.EndTimeOfDay;

          // solapament o contigüitat (tolerància petita)
          if (e2 >= S) and (s2 <= E) then
          begin
            if s2 < S then begin S := s2; changed := True; end;
            if e2 > E then begin E := e2; changed := True; end;
          end
          else if SameValue(e2, S, 1/864000) then // ~0.1s
          begin
            S := s2; changed := True;
          end
          else if SameValue(s2, E, 1/864000) then
          begin
            E := e2; changed := True;
          end;
        end;
      end;

      Result := Result or changed;
    until not changed;
  end;

var
  d: Integer;
  day: TDateTime;
  periods: TArray<TNonWorkingPeriod>;
  p: TNonWorkingPeriod;
  s, e: TDateTime;
begin
  Result := False;
  AStart := 0;
  AEnd := 0;

  cal := GetCalendar(CentreId);
  baseDay := DateOf(T);

  // 1) trobar un interval que contingui T (buscant +/- ARadiusDays)
  for d := -ARadiusDays to ARadiusDays do
  begin
    day := IncDay(baseDay, d);
    periods := cal.NonWorkingPeriodsForDate(day);

    for p in periods do
    begin
      s := day + p.StartTimeOfDay;
      e := day + p.EndTimeOfDay;
      if p.EndTimeOfDay <= p.StartTimeOfDay then
        e := IncDay(day, 1) + p.EndTimeOfDay;

      if (T >= s) and (T < e) then
      begin
        AStart := s;
        AEnd := e;

        // 2) expandir/fusionar
        ExpandInterval(AStart, AEnd);
        Exit(True);
      end;
    end;
  end;
end;


function TGanttControl.AdjustToWorkingForwardMerged(
  const CentreId: Integer;
  const T: TDateTime;
  const ARadiusDays: Integer
): TDateTime;
var
  sNW, eNW: TDateTime;
  i: Integer;
begin
  Result := T;

  // Evita bucle infinit si el calendari està “tancat” molt temps
  for i := 0 to 64 do
  begin
    if not TryGetNonWorkingIntervalMergedAt(CentreId, Result, ARadiusDays, sNW, eNW) then
      Exit; // ja és working
    Result := eNW; // salta al final del nonworking
  end;
end;

function TGanttControl.AdjustToWorkingBackwardMerged(
  const CentreId: Integer;
  const T: TDateTime;
  const ARadiusDays: Integer
): TDateTime;
var
  sNW, eNW: TDateTime;
  i: Integer;
begin
  Result := T;

  for i := 0 to 64 do
  begin
    if not TryGetNonWorkingIntervalMergedAt(CentreId, Result, ARadiusDays, sNW, eNW) then
      Exit;
    Result := sNW; // recula a l’inici del nonworking
  end;
end;


procedure TGanttControl.StartMoveNode(const NodeIndex: Integer; const MouseX, MouseY: Integer);
var
  node: TNode;
  tMouse: TDateTime;
begin
  if (NodeIndex < 0) or (NodeIndex > High(FNodes)) then Exit;

  if not FNodes[NodeIndex].enabled then Exit;


  FMoving := True;
  FDragMode := dmMove;
  FMoveNodeIndex := NodeIndex;

  node := FNodes[NodeIndex];

  FMoveOrigStart := node.StartTime;
  FMoveOrigEnd   := node.EndTime;
  FMoveOrigCentreId := node.CentreId;

  // preview inicial
  FMovePreviewStart := FMoveOrigStart;
  FMovePreviewEnd   := FMoveOrigEnd;
  FMovePreviewCentreId := FMoveOrigCentreId;

  // offset en minuts visibles: invariant a zoom i scroll
  // = minuts visibles entre l’inici del node i la posició del mouse
  FMoveGrabOffsetMins := VisibleMinutesBetween(FMoveOrigStart, XToTime(MouseX));
  if FMoveGrabOffsetMins < 0 then FMoveGrabOffsetMins := 0;

  MouseCapture := True;
  Invalidate;
end;


procedure TGanttControl.UpdateMovePreview(const MouseX, MouseY: Integer);
var
  newStart: TDateTime;
  durMins: Integer;
begin
  if not FMoving then Exit;

  FLastMouseX := MouseX;
  FLastMouseY := MouseY;

  durMins := Round((FMoveOrigEnd - FMoveOrigStart) * 24 * 60);
  if durMins < 1 then durMins := 1;

  // Calculem en minuts visibles world: evita problemes amb HideWeekends
  newStart := AddVisibleMinutes(FStartTime,
    ((MouseX + FScrollX) / FPxPerMinute) - FMoveGrabOffsetMins);

  FMovePreviewStart := newStart;
  FMovePreviewEnd   := newStart + (durMins / (24*60));

  // 3.2 Preview vertical (centre) segons Y
  FMovePreviewCentreId := CentreIdFromScreenY(MouseY); // funció de sota

  Invalidate;
end;


function TGanttControl.CentreIdFromScreenY(const ScreenY: Integer): Integer;
var
  yW: Single;
  i: Integer;
begin
  Result := FMoveOrigCentreId; // fallback
  yW := ScreenY + FScrollY;

  for i := 0 to High(FRows) do
    if (yW >= FRows[i].TopY) and (yW < (FRows[i].TopY + FRows[i].Height)) then
      Exit(FRows[i].CentreId);
end;


procedure TGanttControl.StartResizeNode(const NodeId: Integer; const Edge: TResizeEdge);
begin
  FResizing := True;
  FDragMode := dmResize;
  FResizeEdge := Edge;
  // agafa node actual
  GetNodeTimes(NodeId, FResizeOrigStart, FResizeOrigEnd);
  // preview comença igual
  FPreviewStart := FResizeOrigStart;
  FPreviewEnd   := FResizeOrigEnd;
  MouseCapture := True;
  Screen.Cursor := crSizeWE;
end;

procedure TGanttControl.UpdateResizePreview(const MouseX: Single);
var
  t: TDateTime;
begin
  if not FResizing then Exit;
  t := XToTime(MouseX); // sense clamp/overlay/calendar
  if FResizeEdge = reLeft then
    FPreviewStart := t
  else
    FPreviewEnd := t;
  // (opcional) evita invertir visualment
  if FPreviewEnd < FPreviewStart then
  begin
    // deixem que visualment s'inverteixi? normalment millor fixar:
    if FResizeEdge = reLeft then
      FPreviewStart := FPreviewEnd
    else
      FPreviewEnd := FPreviewStart;
  end;
  Invalidate;
end;



function TGanttControl.CalcEndTime(const CentreId: Integer; const StartTime: TDateTime; const DurationMin: Double): TDateTime;
var
  cal: TCentreCalendar;
  mins: Integer;
begin
  cal := GetCalendar(CentreId);
  mins := Ceil(DurationMin);
  if mins < 1 then mins := 1;
  if cal <> nil then
    Result := cal.AddWorkingMinutes(cal.NextWorkingTime(StartTime), mins)
  else
    Result := StartTime + (DurationMin / 1440.0);
end;

function TGanttControl.CalcStartFromEnd(const CentreId: Integer; const EndTime: TDateTime; const DurationMin: Double): TDateTime;
var
  cal: TCentreCalendar;
  mins: Integer;
begin
  cal := GetCalendar(CentreId);
  mins := Ceil(DurationMin);
  if mins < 1 then mins := 1;
  if cal <> nil then
    Result := cal.SubtractWorkingMinutes(cal.PrevWorkingTime(EndTime), mins)
  else
    Result := EndTime - (DurationMin / 1440.0);
end;


procedure TGanttControl.CommitResize;
const
  MIN_MINUTES = 1; // o 5 si vols snap
var
  idx: Integer;
  cal: TCentreCalendar;
  centreId: Integer;
  bAnyShift: Boolean;
  // finals
  newStart, newEnd: TDateTime;
  newDurMins: Integer;
  MovedNodes: TIdxArray;

  function ClampToOverlay(const T: TDateTime): TDateTime;
  begin
    Result := T;
    if (FFechaBloqueo <> 0) and (Result < FFechaBloqueo) then
      Result := FFechaBloqueo;
  end;

  function MinutesBetweenNatural(const S, E: TDateTime): Integer;
  var
    m: Double;
  begin
    m := (E - S) * 24 * 60;
    Result := Round(m);
  end;

  function ComputeDurationMins(const ACal: TCentreCalendar; const S, E: TDateTime): Integer;
  var
    m: Integer;
  begin
    if ACal <> nil then
      m := ACal.WorkingMinutesBetween(S, E)
    else
      m := MinutesBetweenNatural(S, E);

    if m < MIN_MINUTES then
      m := MIN_MINUTES;

    Result := m;
  end;

begin
  // node index vàlid?
  idx := FResizeNodeIndex;
  if (idx < 0) or (idx > High(FNodes)) then
  begin
    FResizing := False;
    FDragMode := dmNone;
    MouseCapture := False;
    Exit;
  end;

  centreId := FNodes[idx].CentreId;
  cal := GetCalendar(centreId);

  // ===== 1) Construir rang base segons edge =====
  if FResizeEdge = reLeft then
  begin
    newStart := FPreviewStart;      // costat que arrossegues
    newEnd   := FResizeOrigEnd;     // costat fix
  end
  else
  begin
    newStart := FResizeOrigStart;   // costat fix
    newEnd   := FPreviewEnd;        // costat que arrossegues
  end;

  // ordre
  if newEnd < newStart then
    newEnd := newStart;

  // ===== 2) Overlay/bloqueig (com a CommitMove) =====
  newStart := ClampToOverlay(newStart);
  if newEnd < newStart then
    newEnd := newStart;

  // ===== 3) Calendari: Start sempre en working (com a CommitMove) =====
  if cal <> nil then
    newStart := cal.NextWorkingTime(newStart);

  if newEnd < newStart then
    newEnd := newStart;

  // ===== 4) OPCIÓ B: si End cau en non-working, SALTA ENDAVANT =====
  if cal <> nil then
    newEnd := cal.NextWorkingTime(newEnd);

  if newEnd < newStart then
    newEnd := newStart;

  // ===== 5) DurationMin nou (coherent amb calendari si n'hi ha) =====
  newDurMins := ComputeDurationMins(cal, newStart, newEnd);

  // ===== 6) Deriva EndTime DES de DurationMin (mateixa línia que CommitMove) =====
  newEnd := CalcEndTime(centreId, newStart, newDurMins);

  // (seguretat extra) torna a garantir End en working
  if cal <> nil then
    newEnd := cal.NextWorkingTime(newEnd);

  // ===== 7) COMMIT =====
  //FNodes[idx].StartTime   := newStart;
  //FNodes[idx].DurationMin := newDurMins;
  //FNodes[idx].EndTime     := newEnd;

  //...actualitzem start, end, duration del Node i del TNodeData
  ApplyResizeToModel( idx, newStart, newEnd, newDurMins);


  // aquí: col·lisions (push-right) si el centre és seqüencial
  //bAnyShift := ResolveSequentialCollisionsFromNode(centreId, idx, FMinGapBetweenNodes, MovedNodes); //{gap minuts entre nodes});

  CommitNodeMoveOrResize( idx );

  // sortir de mode resize
  MouseCapture := False;
  FResizing := False;
  FDragMode := dmNone;
  FResizeHandle := nhNone;
  FResizeNodeIndex := -1;
  Screen.Cursor := crDefault;

  RebuildAfterModelChange(False);
  Invalidate;
end;



procedure TGanttControl.ApplyResizeToModel(const NodeIdx: Integer;
  const AStart, AEnd: TDateTime; const ADurMin: Integer);
var
  dataId: TGuid;
  D: TNodeData;
begin
  // 1) Node (view/cache)
  FNodes[NodeIdx].StartTime   := AStart;
  FNodes[NodeIdx].DurationMin := ADurMin;
  FNodes[NodeIdx].EndTime     := AEnd;

  if (FNodes[NodeIdx].DataId = 0) or (not FNodeRepo.TryGetById(FNodes[NodeIdx].DataId, d)) then
    Exit;

  D.DurationMin := ADurMin;
  FNodeRepo.AddOrUpdate(D);

end;




function TGanttControl.ResolveSequentialCollisionsFromNode(
  const CentreId: Integer;
  const ChangedIdx: Integer;
  const MinGapMin: Integer;
  out MovedNodes: TIdxArray): Boolean;
var
  list: TIdxArray;
  cachedArr: TArray<Integer>;
  i, posC, posB, MovedCount: Integer;
  prevEnd, desiredStart: TDateTime;
  cal: TCentreCalendar;
  Nodes: TArray<TNode>;

  function FindPos(const A: TIdxArray; const NodeIdx: Integer): Integer;
  var j: Integer;
  begin
    for j := 0 to High(A) do
      if A[j] = NodeIdx then Exit(j);
    Result := -1;
  end;

  procedure MoveElement(var A: TIdxArray; const FromPos, ToPos: Integer);
  var tmp, j: Integer;
  begin
    if (FromPos < 0) or (FromPos > High(A)) or
       (ToPos < 0)   or (ToPos > High(A))   or
       (FromPos = ToPos) then Exit;
    tmp := A[FromPos];
    if FromPos < ToPos then
      for j := FromPos to ToPos - 1 do A[j] := A[j + 1]
    else
      for j := FromPos downto ToPos + 1 do A[j] := A[j - 1];
    A[ToPos] := tmp;
  end;

  function ApplyOverlayAndCalendar(const T: TDateTime): TDateTime;
  begin
    Result := T;
    if (FFechaBloqueo <> 0) and (Result < FFechaBloqueo) then
      Result := FFechaBloqueo;
    if cal <> nil then
      Result := cal.NextWorkingTime(Result);
  end;

begin
  Result := False;
  SetLength(MovedNodes, 0);
  MovedCount := 0;
  if not IsCentreSequecial(CentreId) then Exit;
  if (ChangedIdx < 0) or (ChangedIdx > High(FNodes)) then Exit;
  if FNodes[ChangedIdx].CentreId <> CentreId then Exit;

  cal := GetCalendar(CentreId);
  Nodes := FNodes; // referència local per accés ràpid

  // Obtenir nodes del centre des del cache existent
  if not FCentreNodeIdx.TryGetValue(CentreId, cachedArr) then Exit;
  list := Copy(cachedArr);
  if Length(list) <= 1 then Exit;

  // Quicksort O(n log n) en lloc de bubble sort O(n²)
  TArray.Sort<Integer>(list, TComparer<Integer>.Construct(
    function(const L, R: Integer): Integer
    begin
      if Nodes[L].StartTime < Nodes[R].StartTime then Exit(-1);
      if Nodes[L].StartTime > Nodes[R].StartTime then Exit(1);
      if Nodes[L].Id < Nodes[R].Id then Exit(-1);
      if Nodes[L].Id > Nodes[R].Id then Exit(1);
      Result := 0;
    end));

  posC := FindPos(list, ChangedIdx);
  if posC < 0 then Exit;

  posB := -1;
  for i := 0 to High(list) do
  begin
    if list[i] = ChangedIdx then Continue;
    if (Nodes[ChangedIdx].StartTime >= Nodes[list[i]].StartTime) and
       (Nodes[ChangedIdx].StartTime <  Nodes[list[i]].EndTime) then
    begin
      if (posB < 0) or (Nodes[list[i]].EndTime > Nodes[list[posB]].EndTime) then
        posB := i;
    end;
  end;

  if posB >= 0 then
  begin
    desiredStart := IncMinute(Nodes[list[posB]].EndTime, MinGapMin);
    desiredStart := ApplyOverlayAndCalendar(desiredStart);
    if FNodes[ChangedIdx].StartTime < desiredStart then
    begin
      if MoveNodeKeepingDuration(ChangedIdx, desiredStart) then
      begin
        Result := True;
        SetLength(MovedNodes, MovedCount + 1);
        MovedNodes[MovedCount] := ChangedIdx;
        Inc(MovedCount);
      end;
    end;
    posC := FindPos(list, ChangedIdx);
    if posC >= 0 then
    begin
      if posC < posB then
        MoveElement(list, posC, posB)
      else
        MoveElement(list, posC, posB + 1);
      posC := FindPos(list, ChangedIdx);
      if posC < 0 then Exit;
    end;
  end;

  prevEnd := FNodes[list[posC]].EndTime;
  for i := posC + 1 to High(list) do
  begin
    desiredStart := IncMinute(prevEnd, MinGapMin);
    desiredStart := ApplyOverlayAndCalendar(desiredStart);
    if FNodes[list[i]].StartTime < desiredStart then
    begin
      if MoveNodeKeepingDuration(list[i], desiredStart) then
      begin
        Result := True;
        SetLength(MovedNodes, MovedCount + 1);
        MovedNodes[MovedCount] := list[i];
        Inc(MovedCount);
      end;
    end;
    prevEnd := FNodes[list[i]].EndTime;
  end;
end;


function TGanttControl.ClampNodeToPredecessors(
  const NodeIdx: Integer): Boolean;
var
  HasConstraint: Boolean;
  MinStart, NewStart: TDateTime;
begin
  Result := False;

  if (NodeIdx < 0) or (NodeIdx > High(FNodes)) then Exit;

  MinStart := GetMinStartAllowedByPredecessors(NodeIdx, HasConstraint);
  if not HasConstraint then Exit;

  NewStart := ApplyNodeCalendarAndOverlay(FNodes[NodeIdx].CentreId, MinStart);

  if FNodes[NodeIdx].StartTime < NewStart then
    Result := MoveNodeKeepingDuration(NodeIdx, NewStart);
end;


procedure TGanttControl.MarkAllNodesModified(const AValue: Boolean);
var
  i: Integer;
  d: TNodeData;
begin
  for i := 0 to High(FNodes) do
    if FNodes[i].DataId <> 0 then
    begin
      if FNodeRepo.TryGetById(FNodes[i].DataId, d) then
      begin
       d.Modified := AValue;
       FNodeRepo.AddOrUpdate(d);
      end;
    end;
  RecalcCounters;
end;



function TGanttControl.IsValidNodeIndex(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex <= High(FNodes));
end;

function TGanttControl.GetNodeMidTime(const AIndex: Integer): TDateTime;
begin
  Result := FNodes[AIndex].StartTime +
    ((FNodes[AIndex].EndTime - FNodes[AIndex].StartTime) / 2);
end;

function TGanttControl.GetReferenceTimeForNavigation: TDateTime;
begin
  if IsValidNodeIndex(FFocusedNodeIndex) then
    Result := FNodes[FFocusedNodeIndex].StartTime
  else
    Result := StartVisibleTime + ((EndVisibleTime - StartVisibleTime) / 2);
end;

function TGanttControl.FindFirstNodeIndex: Integer;
var
  I: Integer;
  BestTime: TDateTime;
begin
  Result := -1;
  BestTime := 0;

  for I := 0 to High(FNodes) do
  begin
    if (Result = -1) or (FNodes[I].StartTime < BestTime) then
    begin
      Result := I;
      BestTime := FNodes[I].StartTime;
    end;
  end;
end;

function TGanttControl.FindLastNodeIndex: Integer;
var
  I: Integer;
  BestTime: TDateTime;
begin
  Result := -1;
  BestTime := 0;

  for I := 0 to High(FNodes) do
  begin
    if (Result = -1) or (FNodes[I].StartTime > BestTime) then
    begin
      Result := I;
      BestTime := FNodes[I].StartTime;
    end;
  end;
end;

function TGanttControl.FindNextNodeIndex(const ARefTime: TDateTime): Integer;
var
  I: Integer;
  BestStart: TDateTime;
begin
  Result := -1;
  BestStart := 0;

  for I := 0 to High(FNodes) do
  begin
    if FNodes[I].StartTime <= ARefTime then
      Continue;

    if (Result = -1) or (FNodes[I].StartTime < BestStart) then
    begin
      Result := I;
      BestStart := FNodes[I].StartTime;
    end;
  end;
end;

function TGanttControl.FindPreviousNodeIndex(const ARefTime: TDateTime): Integer;
var
  I: Integer;
  BestStart: TDateTime;
begin
  Result := -1;
  BestStart := 0;

  for I := 0 to High(FNodes) do
  begin
    if FNodes[I].StartTime >= ARefTime then
      Continue;

    if (Result = -1) or (FNodes[I].StartTime > BestStart) then
    begin
      Result := I;
      BestStart := FNodes[I].StartTime;
    end;
  end;
end;

function TGanttControl.CalcScrollXToCenterDate(const ADate: TDateTime): Single;
var
  minutesFromStart: Double;
  xCenter: Single;
begin
  xCenter := ClientWidth * 0.5;
  minutesFromStart := VisibleMinutesBetween(FStartTime, ADate);
  Result := (minutesFromStart * FPxPerMinute) - xCenter;
  Result := ClampScrollX(Result);
end;

procedure TGanttControl.CenterNodeByIndex(const AIndex: Integer; const ASelectNode: Boolean = True);
var
  NodeMid: TDateTime;
begin
  if not IsValidNodeIndex(AIndex) then
    Exit;

  if ASelectNode then
  begin
     FFocusedNodeIndex := AIndex;
     if Assigned(FSelectedNodeIndexes) then
     begin
       FSelectedNodeIndexes.Clear;
       FSelectedNodeIndexes.AddOrSetValue(FFocusedNodeIndex, 1);
     end;
  end;

  NodeMid := GetNodeMidTime(AIndex);

  ScrollX := CalcScrollXToCenterDate(NodeMid);

  Invalidate;
end;

procedure TGanttControl.GoToFirstNode;
var
  Idx: Integer;
begin
  if Length(FNodes) = 0 then
    Exit;

  Idx := FindFirstNodeIndex;
  if Idx <> -1 then
    CenterNodeByIndex(Idx, True);
end;

procedure TGanttControl.GoToLastNode;
var
  Idx: Integer;
begin
  if Length(FNodes) = 0 then
    Exit;

  Idx := FindLastNodeIndex;
  if Idx <> -1 then
    CenterNodeByIndex(Idx, True);
end;

procedure TGanttControl.GoToNextNode;
var
  RefTime: TDateTime;
  Idx: Integer;
begin
  if Length(FNodes) = 0 then
    Exit;

  RefTime := GetReferenceTimeForNavigation;
  Idx := FindNextNodeIndex(RefTime);

  if Idx = -1 then
    Idx := FindFirstNodeIndex; // opcional: fer wrap

  if Idx <> -1 then
    CenterNodeByIndex(Idx, True);
end;

procedure TGanttControl.GoToPreviousNode;
var
  RefTime: TDateTime;
  Idx: Integer;
begin
  if Length(FNodes) = 0 then
    Exit;

  RefTime := GetReferenceTimeForNavigation;
  Idx := FindPreviousNodeIndex(RefTime);

  if Idx = -1 then
    Idx := FindLastNodeIndex; // opcional: fer wrap

  if Idx <> -1 then
    CenterNodeByIndex(Idx, True);
end;


procedure TGanttControl.GoToNextOF;
var
  I: Integer;
  CurrData, D: TNodeData;
  CurrOFStart: TDateTime;
  BestIdx: Integer;
  BestTime: TDateTime;
begin
  if Length(FNodes) = 0 then
    Exit;

  if not IsValidNodeIndex(FFocusedNodeIndex) then
  begin
    BestIdx := FindFirstOFNodeIndex;
    if BestIdx <> -1 then
      CenterNodeByIndex(BestIdx, True);
    Exit;
  end;

  if not TryGetNodeData(FFocusedNodeIndex, CurrData) then
    Exit;

  CurrOFStart := 0;
  for I := 0 to High(FNodes) do
  begin
    if not TryGetNodeData(I, D) then
      Continue;

    if (D.NumeroOrdenFabricacion <> CurrData.NumeroOrdenFabricacion) or
       (not SameText(D.SerieFabricacion, CurrData.SerieFabricacion)) then
      Continue;

    if (CurrOFStart = 0) or (FNodes[I].StartTime < CurrOFStart) then
      CurrOFStart := FNodes[I].StartTime;
  end;

  BestIdx := -1;
  BestTime := 0;

  for I := 0 to High(FNodes) do
  begin
    if not TryGetNodeData(I, D) then
      Continue;

    if (D.NumeroOrdenFabricacion = CurrData.NumeroOrdenFabricacion) and
       SameText(D.SerieFabricacion, CurrData.SerieFabricacion) then
      Continue;

    if FNodes[I].StartTime <= CurrOFStart then
      Continue;

    if (BestIdx = -1) or (FNodes[I].StartTime < BestTime) then
    begin
      BestIdx := I;
      BestTime := FNodes[I].StartTime;
    end;
  end;

  if BestIdx <> -1 then
  begin
    if TryGetNodeData(BestIdx, D) then
      BestIdx := FindFirstNodeIndexOfOF(D.NumeroOrdenFabricacion, D.SerieFabricacion);
  end
  else
  begin
    // wrap a la primera OF global
    BestIdx := FindFirstOFNodeIndex;
  end;

  if BestIdx <> -1 then
    CenterNodeByIndex(BestIdx, True);
end;



procedure TGanttControl.GoToPrevOF;
var
  I: Integer;
  CurrData, D: TNodeData;
  CurrOFStart: TDateTime;
  CandidateIdx: Integer;
  CandidateStart: TDateTime;
begin
  if Length(FNodes) = 0 then
    Exit;

  // si no hi ha selecció, ves a l'última OF
  if not IsValidNodeIndex(FFocusedNodeIndex) then
  begin
    CandidateIdx := FindLastOFNodeIndex;
    if CandidateIdx <> -1 then
      CenterNodeByIndex(CandidateIdx, True);
    Exit;
  end;

  if not TryGetNodeData(FFocusedNodeIndex, CurrData) then
    Exit;

  // 1) trobar l'inici real de la OF actual
  CurrOFStart := 0;
  for I := 0 to High(FNodes) do
  begin
    if not TryGetNodeData(I, D) then
      Continue;

    if (D.NumeroOrdenFabricacion <> CurrData.NumeroOrdenFabricacion) or
       (not SameText(D.SerieFabricacion, CurrData.SerieFabricacion)) then
      Continue;

    if (CurrOFStart = 0) or (FNodes[I].StartTime < CurrOFStart) then
      CurrOFStart := FNodes[I].StartTime;
  end;

  // 2) buscar la OF anterior (la de StartTime màxim però menor que l'actual)
  CandidateIdx := -1;
  CandidateStart := 0;

  for I := 0 to High(FNodes) do
  begin
    if not TryGetNodeData(I, D) then
      Continue;

    // ignorar nodes de la mateixa OF actual
    if (D.NumeroOrdenFabricacion = CurrData.NumeroOrdenFabricacion) and
       SameText(D.SerieFabricacion, CurrData.SerieFabricacion) then
      Continue;

    // només OF anteriors
    if FNodes[I].StartTime >= CurrOFStart then
      Continue;

    if (CandidateIdx = -1) or (FNodes[I].StartTime > CandidateStart) then
    begin
      CandidateIdx := I;
      CandidateStart := FNodes[I].StartTime;
    end;
  end;

  // 3) anar al primer node de la OF trobada
  if CandidateIdx <> -1 then
  begin
    if TryGetNodeData(CandidateIdx, D) then
      CandidateIdx := FindFirstNodeIndexOfOF(D.NumeroOrdenFabricacion, D.SerieFabricacion);
  end
  else
  begin
    // wrap a l'última OF
    CandidateIdx := FindLastOFNodeIndex;
  end;

  if CandidateIdx <> -1 then
    CenterNodeByIndex(CandidateIdx, True);
end;


function TGanttControl.FindLastOFNodeIndex: Integer;
var
  I: Integer;
  D, BestD: TNodeData;
  BestTime: TDateTime;
begin
  Result := -1;
  BestTime := 0;

  for I := 0 to High(FNodes) do
  begin
    if not TryGetNodeData(I, D) then
      Continue;

    if (Result = -1) or (FNodes[I].StartTime > BestTime) then
    begin
      Result := I;
      BestTime := FNodes[I].StartTime;
      BestD := D;
    end;
  end;

  if Result <> -1 then
    Result := FindFirstNodeIndexOfOF(BestD.NumeroOrdenFabricacion, BestD.SerieFabricacion);
end;


procedure TGanttControl.CommitNodeMoveOrResize(const NodeIdx: Integer);
var
  BeforeSnaps, AfterSnaps: TArray<TNodePlanSnapshot>;
  Changes: TArray<TNodeHistoryChange>;
  Entry: TGanttHistoryEntry;
begin
  if (NodeIdx < 0) or (NodeIdx > High(FNodes)) then Exit;
  // 1) estat abans
  BeforeSnaps := CaptureSnapshotsFromNodePropagation(NodeIdx);
  // IMPORTANT: si l'has mogut cap a l'esquerra, el corregeix segons predecessors
  ClampNodeToPredecessors(NodeIdx);

  ResolveAllConstraintsFromNode(NodeIdx, 0);

  // 3) estat després
  AfterSnaps := CaptureSnapshotsFromNodePropagation(NodeIdx);
  // 4) genera canvis reals
  Changes := BuildNodeHistoryChanges(BeforeSnaps, AfterSnaps);

    // 5) crear entrada històric
  Entry := BuildHistoryEntry(
    hatEdit,   // o hatMove / hatResize si ho saps
    'Move/Resize node',
    NodeIdx,
    Changes
  );
  // 6) push a undo
  if Entry <> nil then
  begin
    FHistory.PushUndo(Entry);
    //if Assigned(FOnHistoryChanged) then
    //  FOnHistoryChanged(Self);
  end;

  RecalcCounters;
  Invalidate;
  //if Assigned(FOnNodesChanged) then
  //  FOnNodesChanged(Self);
end;



function TGanttControl.GetMinStartAllowedByPredecessors(
  const NodeIdx: Integer;
  out HasConstraint: Boolean): TDateTime;
var
  PredIdx, li: Integer;
  T: TDateTime;
  PredLinks: TList<Integer>;
begin
  Result := 0;
  HasConstraint := False;

  if (NodeIdx < 0) or (NodeIdx > High(FNodes)) then Exit;

  if (FPredecessors = nil) or not FPredecessors.TryGetValue(FNodes[NodeIdx].Id, PredLinks) then
    Exit;

  for li in PredLinks do
  begin
    PredIdx := FindNodeIndexById(FLinks[li].FromNodeId);
    if PredIdx < 0 then
      Continue;

    T := GetDependencyMinStart(PredIdx, FLinks[li].PorcentajeDependencia);

    if not HasConstraint then
    begin
      Result := T;
      HasConstraint := True;
    end
    else if T > Result then
      Result := T;
  end;
end;

function TGanttControl.ResolveNonSequentialCollisionsFromNode(
  const CentreId: Integer;
  const ChangedIdx: Integer;
  out MovedNodes: TIdxArray): Boolean;
var
  CIdx, MaxLanes, I, Overlap: Integer;
  Idxs: TArray<Integer>;
  IdxCount: Integer;
  TestStart, TestEnd, OtherStart, OtherEnd: TDateTime;
  EarliestEnd, NewStart: TDateTime;
  DurMin: Double;
  Attempt: Integer;

  function CountOverlapsAt(AStart, AEnd: TDateTime): Integer;
  var J: Integer;
  begin
    Result := 0;
    for J := 0 to IdxCount - 1 do
    begin
      if Idxs[J] = ChangedIdx then Continue;
      if (AStart < FNodes[Idxs[J]].EndTime) and (AEnd > FNodes[Idxs[J]].StartTime) then
        Inc(Result);
    end;
  end;

  function FindEarliestEndAt(AStart, AEnd: TDateTime): TDateTime;
  var J: Integer;
  begin
    Result := AEnd + 365;
    for J := 0 to IdxCount - 1 do
    begin
      if Idxs[J] = ChangedIdx then Continue;
      if (AStart < FNodes[Idxs[J]].EndTime) and (AEnd > FNodes[Idxs[J]].StartTime) then
        if FNodes[Idxs[J]].EndTime < Result then
          Result := FNodes[Idxs[J]].EndTime;
    end;
  end;

begin
  Result := False;
  ArrayClear(MovedNodes);

  // Només centres NO seqüencials amb MaxLaneCount > 0
  if IsCentreSequecial(CentreId) then Exit;

  CIdx := FindCentreIndexById(CentreId);
  if CIdx < 0 then Exit;
  MaxLanes := FCentres[CIdx].MaxLaneCount;
  if MaxLanes <= 0 then Exit;

  // Recollir nodes del centre des del cache
  if FCentreNodeIdx.TryGetValue(CentreId, Idxs) then
  begin
    // Filtrar només visibles
    IdxCount := 0;
    for I := 0 to High(Idxs) do
      if FNodes[Idxs[I]].Visible then
      begin
        Idxs[IdxCount] := Idxs[I];
        Inc(IdxCount);
      end;
  end
  else
  begin
    IdxCount := 0;
  end;

  DurMin := FNodes[ChangedIdx].DurationMin;
  TestStart := FNodes[ChangedIdx].StartTime;
  TestEnd := FNodes[ChangedIdx].EndTime;

  // Buscar un slot temporal on el solapament sigui < MaxLanes
  for Attempt := 0 to 500 do
  begin
    Overlap := CountOverlapsAt(TestStart, TestEnd);

    // Si el nombre de solapaments (excloent el node canviat) < MaxLanes, hi cap
    if Overlap < MaxLanes then
    begin
      // Hem trobat un lloc vàlid
      if TestStart > FNodes[ChangedIdx].StartTime then
      begin
        if MoveNodeKeepingDuration(ChangedIdx, TestStart) then
        begin
          Result := True;
          ArrayAddUnique(MovedNodes, ChangedIdx);
        end;
      end;
      Exit;
    end;

    // Totes les lanes ocupades: avançar al primer forat
    EarliestEnd := FindEarliestEndAt(TestStart, TestEnd);
    NewStart := ApplyNodeCalendarAndOverlay(CentreId, EarliestEnd);

    if NewStart <= TestStart then
      NewStart := IncMinute(TestStart, 1); // safety

    TestStart := NewStart;
    TestEnd := CalcEndTime(CentreId, TestStart, DurMin);
  end;
end;

function TGanttControl.ResolveAllConstraintsFromNode(
  const ChangedIdx: Integer;
  const MinGapMin: Integer): Boolean;
var
  Queue: TArray<Integer>;
  ProcessedCount: array of Integer;
  IsQueued: array of Boolean;
  qHead, qTail: Integer;
  CurrIdx: Integer;
  i, N: Integer;
  MovedDeps, MovedSeq: TIdxArray;

  procedure Enqueue(const AIdx: Integer);
  begin
    if (AIdx < 0) or (AIdx > N) then Exit;
    if IsQueued[AIdx] then Exit;
    IsQueued[AIdx] := True;
    Queue[qTail] := AIdx;
    Inc(qTail);
  end;

  procedure MarkNodeModified(const AIdx: Integer);
  var
    D: TNodeData;
  begin
    if (AIdx < 0) or (AIdx > N) then
      Exit;

    if (FNodes[AIdx].DataId = 0) then
      Exit;

    if FNodeRepo.TryGetById(FNodes[AIdx].DataId, D) then
    begin
      D.Modified := True;
      FNodeRepo.AddOrUpdate(D);
    end;
  end;

begin
  Result := False;
  N := High(FNodes);
  SetLength(Queue, Length(FNodes));
  SetLength(ProcessedCount, Length(FNodes));
  SetLength(IsQueued, Length(FNodes));
  qHead := 0;
  qTail := 0;

  Enqueue(ChangedIdx);
  MarkNodeModified(ChangedIdx);

  while qHead < qTail do
  begin
    CurrIdx := Queue[qHead];
    Inc(qHead);

    if (CurrIdx < 0) or (CurrIdx > N) then
      Continue;

    Inc(ProcessedCount[CurrIdx]);
    if ProcessedCount[CurrIdx] > 20 then
      Continue;
    // Permetre re-enqueueing si torna a ser mogut
    IsQueued[CurrIdx] := False;

    // 0) El node actual ha de respectar els seus predecessors
    if ClampNodeToPredecessors(CurrIdx) then
    begin
      Result := True;
      MarkNodeModified(CurrIdx);
    end;

    // 1) Propaga dependències sortints
    if ResolveDependenciesFromNode(CurrIdx, MovedDeps) then
    begin
      Result := True;
      for i := 0 to High(MovedDeps) do
      begin
        MarkNodeModified(MovedDeps[i]);
        Enqueue(MovedDeps[i]);
      end;
    end;

    // 2) Resol seqüència del centre (centres seqüencials)
    if ResolveSequentialCollisionsFromNode(
         FNodes[CurrIdx].CentreId,
         CurrIdx,
         MinGapMin,
         MovedSeq) then
    begin
      Result := True;
      for i := 0 to High(MovedSeq) do
      begin
        MarkNodeModified(MovedSeq[i]);
        Enqueue(MovedSeq[i]);
      end;
    end;

    // 3) Resol solapaments a centres NO seqüencials amb MaxLaneCount
    if ResolveNonSequentialCollisionsFromNode(
         FNodes[CurrIdx].CentreId,
         CurrIdx,
         MovedSeq) then
    begin
      Result := True;
      for i := 0 to High(MovedSeq) do
      begin
        MarkNodeModified(MovedSeq[i]);
        Enqueue(MovedSeq[i]);
      end;
    end;
  end;
end;


procedure TGanttControl.NormalizeStartTime;
begin
  if FHideWeekends then
    while IsWeekend(FStartTime) do
      FStartTime := IncDay(DateOf(FStartTime));
end;


procedure TGanttControl.SetHideWeekends(const Value: Boolean);
var
  CenterTime: TDateTime;
  xCenter: Single;
begin
  if FHideWeekends = Value then Exit;

  // Guardem el temps que hi ha al centre de la pantalla ABANS de canviar
  xCenter := ClientWidth * 0.5;
  CenterTime := XToTime(xCenter);

  FHideWeekends := Value;

  // Recalculem FScrollX perquè CenterTime quedi al centre
  // screenX(t) = VisibleMinutesBetween(FStartTime, t) * FPxPerMinute - FScrollX
  // volem screenX(CenterTime) = xCenter =>
  // FScrollX = VisibleMinutesBetween(FStartTime, CenterTime) * FPxPerMinute - xCenter
  FScrollX := ClampScrollX(
    VisibleMinutesBetween(FStartTime, CenterTime) * FPxPerMinute - xCenter
  );

  RebuildLayout;

  // Nota: la sincronización HideWeekends con el timeline asociado
  // la gestiona ahora la vista (uVistaGantt / Main). El control Gantt
  // no debe conocer al timeline directamente.

  UpdateScrollBars;

 // NotifyViewportChanged;

  Invalidate;
end;


function TGanttControl.VisibleMinutesBetween( const AFromTime, AToTime: TDateTime): Double;
const
  MINS_PER_DAY = 1440;
var
  D, D0, D1: TDateTime;
  SegStart, SegEnd: TDateTime;
begin
  if AToTime <= AFromTime then
    Exit(0);

  if not FHideWeekends then
    Exit((AToTime - AFromTime) * MINS_PER_DAY);

  Result := 0;
  D0 := DateOf(AFromTime);
  D1 := DateOf(AToTime);
  D := D0;

  while D <= D1 do
  begin
    if not IsWeekend(D) then
    begin
      SegStart := D;
      SegEnd := IncDay(D);

      if D = D0 then
        SegStart := AFromTime;
      if D = D1 then
        SegEnd := AToTime;

      if SegEnd > SegStart then
        Result := Result + ((SegEnd - SegStart) * MINS_PER_DAY);
    end;

    D := IncDay(D);
  end;
end;


function TGanttControl.AddVisibleMinutes( const AStart: TDateTime; const AVisibleMinutes: Double): TDateTime;
const
  MINS_PER_DAY = 1440;
var
  Remaining: Double;
  D: TDateTime;
  Avail: Double;
begin
  if not FHideWeekends then
    Exit(AStart + (AVisibleMinutes / MINS_PER_DAY));

  Remaining := AVisibleMinutes;
  Result := AStart;

  while Remaining > 0 do
  begin
    D := DateOf(Result);

    while IsWeekend(D) do
    begin
      D := IncDay(D);
      Result := D;
    end;

    Avail := (IncDay(D) - Result) * MINS_PER_DAY;

    if Remaining <= Avail then
      Exit(Result + (Remaining / MINS_PER_DAY));

    Remaining := Remaining - Avail;
    Result := IncDay(D);

    while IsWeekend(Result) do
      Result := IncDay(Result);
  end;
end;


procedure TGanttControl.CommitMove;
var
  idx: Integer;
  newStart, newEnd: TDateTime;
  newCentreId: Integer;
  bRebuildMap: Boolean;
  cal: TCentreCalendar;
  bAnyShift: Boolean;
  MovedNodes: TIdxArray;
begin
  idx := FMoveNodeIndex;
  if (idx < 0) or (idx > High(FNodes)) then Exit;
  newStart := FMovePreviewStart;
  newCentreId := FMovePreviewCentreId;
  // restricció overlay
  if (FFechaBloqueo <> 0) and (newStart < FFechaBloqueo) then
    newStart := FFechaBloqueo;
  // calendari: començar en working time
  cal := GetCalendar(newCentreId);
  if cal <> nil then
    newStart := cal.NextWorkingTime(newStart);
  // EndTime derivat de DurationMin
  newEnd := CalcEndTime(newCentreId, newStart, FNodes[idx].DurationMin);

  // Restricció CentresPermesos: si el node no té LibreMoviment,
  // només es pot moure a centres de CentresPermesos.
  // Si newCentreId no és permès, revertim al centre original.
  if newCentreId <> FNodes[idx].CentreId then
  begin
    var D: TNodeData;
    if Assigned(FNodeRepo) and FNodeRepo.TryGetById(FNodes[idx].DataId, D) then
    begin
      if (not D.LibreMoviment) and (Length(D.CentresPermesos) > 0) then
      begin
        var allowed := False;
        for var permId in D.CentresPermesos do
          if permId = newCentreId then
          begin
            allowed := True;
            Break;
          end;
        if not allowed then
          newCentreId := FMoveOrigCentreId;
      end;
    end;
  end;

  // només si realment el teu mapa depèn del centre
  bRebuildMap := (FNodes[idx].CentreId <> newCentreId);

  FNodes[idx].CentreId := newCentreId;
  FNodes[idx].StartTime := newStart;
  FNodes[idx].EndTime   := newEnd; // cache (opcional però pràctic)

  // aquí: col·lisions (push-right) si el centre és seqüencial


  //ResolveSequentialCollisionsFromNode(newCentreId, idx, FMinGapBetweenNodes, MovedNodes); //{gap minuts entre nodes});
  try
      Screen.cursor := crHourGlass;

      CommitNodeMoveOrResize( idx );

      FMoving := False;
      FDragMode := dmNone;
      FMoveNodeIndex := -1;
      MouseCapture := False;

      RebuildAfterModelChange(bRebuildMap);

  finally
      Invalidate;
      Screen.cursor := crDefault;
  end;
end;




procedure TGanttControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  hit, centreId: Integer;
  newX: Single;
  hover: Boolean;
  ptScreen: TPoint;
  tme: TTrackMouseEvent;
  mouseT: TDateTime;
  newStart, newEnd: TDateTime;
  minDurDays: Double;
  isSeq: Boolean;
  prevIdx, nextIdx: Integer;
  minStartAllowed, maxEndAllowed: TDateTime;
  t: TDateTime;
  Edge: TResizeEdge;
  nh: TNodeHandle;
begin
  inherited;

  // Arma el tracking perquè SEMPRE arribi CM_MOUSELEAVE
  tme.cbSize := SizeOf(tme);
  tme.dwFlags := TME_LEAVE;
  tme.hwndTrack := Handle;
  tme.dwHoverTime := 0;
  TrackMouseEvent(tme);

  // Si estàs fent panning: amaga el hint i surt
  if FIsPanning then
  begin
    HideNodeHint;

    FScrollX := Max(0, FScrollStartX - (X - FPanStart.X));
    FScrollY := Max(0, FScrollStartY - (Y - FPanStart.Y));
    Invalidate;
    NotifyViewportChanged;
    Exit;
  end;

  // Link drag preview
  if FLinkDragging then
  begin
    FLinkPreviewEnd := PointF(X, Y);
    HideNodeHint;
    SetGanttCursor(crCross);
    Invalidate;
    Exit;
  end;

  if FMarqueeSelecting then
  begin
    FMarqueeCurrentPt := Point(X, Y);
    FDashOffset := FDashOffset + 0.5;
    if FDashOffset > 100 then
     FDashOffset := 0;
    Invalidate;
    Exit;
  end;

  if FDraggingBloqueo then
  begin
    newX := X + FDragOffsetX;
    SetFechaBloqueoFromX(newX);
    SetGanttCursor(crHSplit);
    Invalidate;
    Exit;
  end;

  // Marker: iniciar drag si supera threshold
  if (FMouseDownMarkerId >= 0) and (FDraggingMarkerId < 0) and (ssLeft in Shift) then
  begin
    if (Abs(X - FMouseDownPos.X) >= DRAG_THRESHOLD) or
       (Abs(Y - FMouseDownPos.Y) >= DRAG_THRESHOLD) then
    begin
      // Verificar que sigui moveable
      var mkStart: Integer;
      for mkStart := 0 to High(FMarkers) do
      begin
        if FMarkers[mkStart].Id = FMouseDownMarkerId then
        begin
          if FMarkers[mkStart].Moveable then
          begin
            FDraggingMarkerId := FMouseDownMarkerId;
            var mkXs: Single := TimeToX(FMarkers[mkStart].DateTime);
            FMarkerDragOffsetX := mkXs - FMouseDownPos.X;
            FDidDrag := True;
            MouseCapture := True;
          end;
          Break;
        end;
      end;
      FMouseDownMarkerId := -1;
    end;
  end;

  // Marker drag
  if FDraggingMarkerId >= 0 then
  begin
    var mkX: Single := X + FMarkerDragOffsetX;
    var mkT: TDateTime := XToTime(mkX);
    var mk: Integer;
    for mk := 0 to High(FMarkers) do
    begin
      if FMarkers[mk].Id = FDraggingMarkerId then
      begin
        FMarkers[mk].DateTime := mkT;
        Break;
      end;
    end;
    SetGanttCursor(crSizeWE);
    Invalidate;
    Exit;
  end;

  // si ja estàs arrossegant, segueix...
  if FDragMode <> dmNone then
  begin
    HideNodeHint;

    if FDragMode=dmMove then
    begin
     UpdateMovePreview(X, Y);
     SetGanttCursor(crSizeAll);
    end
    else
     if FDragMode=dmResize then
     begin
      UpdateResizePreview(X);
      SetGanttCursor(crSizeWE);
     end;

    Exit;
  end;

  if FDragMode = dmNone then
  begin
        hover := HitTestBloqueo(X, Y);
        FHoverBloqueo := hover;

        if FHoverBloqueo then
        begin
          SetGanttCursor(crHSplit);
          Exit;
        end;

        // Marker hover
        var hoverMk: Integer := HitTestMarker(X);
        if hoverMk <> FHoverMarkerId then
        begin
          FHoverMarkerId := hoverMk;
          Invalidate;
        end;
        if (FHoverMarkerId >= 0) then
        begin
          // Check si és moveable
          var mkm: Integer;
          for mkm := 0 to High(FMarkers) do
            if FMarkers[mkm].Id = FHoverMarkerId then
            begin
              if FMarkers[mkm].Moveable then
                SetGanttCursor(crSizeWE)
              else
                SetGanttCursor(crHandPoint);
              Break;
            end;
          Exit;
        end;

        SetGanttCursor(crDefault);
  end;

  // iniciar drag només si supera llindar
  if (ssLeft in Shift) and (FMouseDownNodeIndex >= 0) then
  begin
    HideNodeHint;

    if (Abs(X - FMouseDownPos.X) >= DRAG_THRESHOLD) or
       (Abs(Y - FMouseDownPos.Y) >= DRAG_THRESHOLD) then
    begin
      FDidDrag := True;
      // decideix resize o move
      if FMouseDownOnHandle in [nhLeft, nhRight] then
      begin
        if FMouseDownOnHandle=nhLeft then
         StartResizeNode(FMouseDownNodeIndex, reLeft)
        else
         StartResizeNode(FMouseDownNodeIndex, reRight);
      end
      else
        StartMoveNode(FMouseDownNodeIndex, X, Y);
      Exit;
    end;
  end;


  if FFocusedNodeIndex>0 then
  begin
      nh := HitTestSelectedNodeHandle(X, Y, Edge);

      case nh of
      nhLeft, nhRight: SetGanttCursor(crSizeWE);
      else
        SetGanttCursor(crDefault);
      end;
  end
  else
  begin
    SetGanttCursor(crDefault);
  end;


  hit := HitTestNodeIndex(X, Y);

  // Si no hi ha node sota el cursor, amaga i actualitza hover
  if hit < 0 then
  begin
    if FHoverNodeIndex <> -1 then
    begin
      FHoverNodeIndex := -1;
      Invalidate;
    end;

    HideNodeHint;

    // Hit-test de links quan no hi ha node sota el cursor
    var linkHit: Integer := HitTestLink(X, Y);
    if linkHit <> FHoverLinkIndex then
    begin
      FHoverLinkIndex := linkHit;
      if linkHit >= 0 then
        SetGanttCursor(crHandPoint)
      else
        SetGanttCursor(crDefault);
      Invalidate;
    end;

    Exit;
  end;

  // Si estem sobre un node, treure hover del link
  if FHoverLinkIndex <> -1 then
  begin
    FHoverLinkIndex := -1;
    Invalidate;
  end;

  // Aquí hit >= 0
  ptScreen := ClientToScreen(Point(X, Y));

  if hit <> FHoverNodeIndex then
  begin
    FHoverNodeIndex := hit;
    Invalidate;
    if (Shift=[]) then
     ShowNodeHint(hit, ptScreen);
  end;



end;




function TGanttControl.ShiftLeftAllImpactedSequentialFromNode(
  const ANodeIdx: Integer;
  const MinGapMin: Integer): Boolean;
type
  TCentreCache = record
    CentreId: Integer;
    NodeList: TIdxArray; // indices de FNodes ordenats per StartTime, Id
  end;

  TCentreCacheArray = array of TCentreCache;

var
  CentreCaches: TCentreCacheArray;
  Queue: TIdxArray;
  InQueue: array of Boolean;
  ProcessedCount: array of Integer;
  NodeToCentreSlot: array of Integer;
  NodePosInCentre: array of Integer;
  NextNodeInCentre: array of Integer;
  qHead: Integer;

  function MaxDate(const A, B: TDateTime): TDateTime;
  begin
    if A > B then Result := A else Result := B;
  end;

  procedure ClearIdxArray(var A: TIdxArray);
  begin
    SetLength(A, 0);
  end;

  procedure Enqueue(const AIdx: Integer);
  var
    L: Integer;
  begin
    if (AIdx < 0) or (AIdx > High(FNodes)) then Exit;
    if InQueue[AIdx] then Exit;

    L := Length(Queue);
    SetLength(Queue, L + 1);
    Queue[L] := AIdx;
    InQueue[AIdx] := True;
  end;

  function Dequeue(out AIdx: Integer): Boolean;
  begin
    Result := qHead < Length(Queue);
    if not Result then Exit;

    AIdx := Queue[qHead];
    InQueue[AIdx] := False;
    Inc(qHead);
  end;

  function ApplyOverlayAndCalendar(const ACentreId: Integer; const T: TDateTime): TDateTime;
  var
    cal: TCentreCalendar;
  begin
    Result := T;

    if (FFechaBloqueo <> 0) and (Result < FFechaBloqueo) then
      Result := FFechaBloqueo;

    cal := GetCalendar(ACentreId);
    if cal <> nil then
      Result := cal.NextWorkingTime(Result);
  end;

  function CompareNodeIdx(const L, R: Integer): Integer;
  var
    a, b: TDateTime;
  begin
    a := FNodes[L].StartTime;
    b := FNodes[R].StartTime;

    if a < b then Exit(-1);
    if a > b then Exit(1);

    if FNodes[L].Id < FNodes[R].Id then Exit(-1);
    if FNodes[L].Id > FNodes[R].Id then Exit(1);

    Result := 0;
  end;

  procedure QuickSortIdx(var A: TIdxArray; L, R: Integer);
  var
    I, J, P, T: Integer;
  begin
    I := L;
    J := R;
    P := A[(L + R) shr 1];

    repeat
      while CompareNodeIdx(A[I], P) < 0 do Inc(I);
      while CompareNodeIdx(A[J], P) > 0 do Dec(J);

      if I <= J then
      begin
        T := A[I];
        A[I] := A[J];
        A[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;

    if L < J then QuickSortIdx(A, L, J);
    if I < R then QuickSortIdx(A, I, R);
  end;

  procedure SortIdx(var A: TIdxArray);
  begin
    if Length(A) > 1 then
      QuickSortIdx(A, 0, High(A));
  end;

  function FindCentreSlot(const ACentreId: Integer): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    for i := 0 to High(CentreCaches) do
      if CentreCaches[i].CentreId = ACentreId then
        Exit(i);
  end;

  procedure AddNodeToCentreCache(const ACentreId, ANodeIdx: Integer);
  var
    slot, L: Integer;
  begin
    slot := FindCentreSlot(ACentreId);
    if slot < 0 then
    begin
      slot := Length(CentreCaches);
      SetLength(CentreCaches, slot + 1);
      CentreCaches[slot].CentreId := ACentreId;
      SetLength(CentreCaches[slot].NodeList, 0);
    end;

    L := Length(CentreCaches[slot].NodeList);
    SetLength(CentreCaches[slot].NodeList, L + 1);
    CentreCaches[slot].NodeList[L] := ANodeIdx;
  end;

  procedure BuildSequentialCentreCache;
  var
    i, slot, p, n: Integer;
  begin
    SetLength(CentreCaches, 0);

    SetLength(NodeToCentreSlot, Length(FNodes));
    SetLength(NodePosInCentre, Length(FNodes));
    SetLength(NextNodeInCentre, Length(FNodes));

    for i := 0 to High(FNodes) do
    begin
      NodeToCentreSlot[i] := -1;
      NodePosInCentre[i] := -1;
      NextNodeInCentre[i] := -1;
    end;

    for i := 0 to High(FNodes) do
      if IsCentreSequecial(FNodes[i].CentreId) then
        AddNodeToCentreCache(FNodes[i].CentreId, i);

    for slot := 0 to High(CentreCaches) do
    begin
      SortIdx(CentreCaches[slot].NodeList);

      n := Length(CentreCaches[slot].NodeList);
      for p := 0 to n - 1 do
      begin
        i := CentreCaches[slot].NodeList[p];
        NodeToCentreSlot[i] := slot;
        NodePosInCentre[i] := p;

        if p < n - 1 then
          NextNodeInCentre[i] := CentreCaches[slot].NodeList[p + 1]
        else
          NextNodeInCentre[i] := -1;
      end;
    end;
  end;

  function GetPreviousNodeInCentre(const ANodeIdx: Integer): Integer;
  var
    slot, pos: Integer;
  begin
    Result := -1;

    if (ANodeIdx < 0) or (ANodeIdx > High(FNodes)) then Exit;

    slot := NodeToCentreSlot[ANodeIdx];
    pos := NodePosInCentre[ANodeIdx];

    if (slot < 0) or (pos <= 0) then Exit;

    Result := CentreCaches[slot].NodeList[pos - 1];
  end;

  procedure EnqueueSequentialSuccessorsOfNode(const APredIdx: Integer);
  var
    i, SuccIdx: Integer;
  begin
    for i := 0 to High(FLinks) do
    begin
      if FLinks[i].FromNodeId <> FNodes[APredIdx].Id then
        Continue;

      SuccIdx := FindNodeIndexById(FLinks[i].ToNodeId);
      if (SuccIdx >= 0) and IsCentreSequecial(FNodes[SuccIdx].CentreId) then
        Enqueue(SuccIdx);
    end;
  end;

  function ShiftLeftSingleNode(const NodeIdx: Integer): Boolean;
  var
    prevIdx: Integer;
    desiredStart: TDateTime;
    predMinStart: TDateTime;
    hasPredConstraint: Boolean;
    centreId: Integer;
  begin
    Result := False;

    if (NodeIdx < 0) or (NodeIdx > High(FNodes)) then Exit;
    if NodeToCentreSlot[NodeIdx] < 0 then Exit; // centre no seqüencial

    centreId := FNodes[NodeIdx].CentreId;

    prevIdx := GetPreviousNodeInCentre(NodeIdx);
    if prevIdx >= 0 then
      desiredStart := IncMinute(FNodes[prevIdx].EndTime, MinGapMin)
    else
      desiredStart := FNodes[NodeIdx].StartTime;

    predMinStart := GetMinStartAllowedByPredecessors(NodeIdx, hasPredConstraint);
    if hasPredConstraint then
      desiredStart := MaxDate(desiredStart, predMinStart);

    desiredStart := ApplyOverlayAndCalendar(centreId, desiredStart);

    if FNodes[NodeIdx].StartTime > desiredStart then
      Result := MoveNodeKeepingDuration(NodeIdx, desiredStart);
  end;

var
  CurrIdx, NextIdx: Integer;
  Changed: Boolean;
begin
  Result := False;

  if (ANodeIdx < 0) or (ANodeIdx > High(FNodes)) then Exit;
  if Length(FNodes) = 0 then Exit;

  SetLength(InQueue, Length(FNodes));
  SetLength(ProcessedCount, Length(FNodes));
  ClearIdxArray(Queue);
  qHead := 0;

  BuildSequentialCentreCache;

  // només el node origen
  if IsCentreSequecial(FNodes[ANodeIdx].CentreId) then
    Enqueue(ANodeIdx)
  else
  begin
    // si el node origen no és seqüencial, no el compactem,
    // però sí podem provar successors seqüencials
    EnqueueSequentialSuccessorsOfNode(ANodeIdx);
  end;

  while Dequeue(CurrIdx) do
  begin
    if (CurrIdx < 0) or (CurrIdx > High(FNodes)) then
      Continue;

    Inc(ProcessedCount[CurrIdx]);
    if ProcessedCount[CurrIdx] > 20 then
      Continue;

    Changed := ShiftLeftSingleNode(CurrIdx);

    if Changed then
    begin
      Result := True;

      // següent node del mateix centre seqüencial
      NextIdx := NextNodeInCentre[CurrIdx];
      if NextIdx >= 0 then
        Enqueue(NextIdx);

      // successors lògics seqüencials
      EnqueueSequentialSuccessorsOfNode(CurrIdx);
    end;
  end;

  if Result then
  begin
    RebuildAfterModelChange(False);
    Invalidate;
  end;
end;


function TGanttControl.CompactOFFromNode(
  const ANodeIdx: Integer;
  const MinGapMin: Integer;
  const AllOF: Boolean = False;
  const bForce: Boolean = False): Boolean;
var
  DStart: TNodeData;
  NumOF: Integer;
  SerieOF: string;
  Visited: array of Boolean;
  IsAnchor: array of Boolean;   // nodes que NO s'han de moure (arrels o seleccionat)
  Queue: TIdxArray;
  qHead: Integer;
  i, CurrIdx, SuccIdx, PredIdx: Integer;
  desiredStart, predMinStart: TDateTime;
  hasPredConstraint: Boolean;
  centreId: Integer;
  prevIdxInCentre: Integer;

  // ---------- helpers locals ----------

  function MaxDate(const A, B: TDateTime): TDateTime;
  begin
    if A > B then Result := A else Result := B;
  end;

  procedure Enqueue(const Idx: Integer);
  var L: Integer;
  begin
    if (Idx < 0) or (Idx > High(FNodes)) then Exit;
    if Visited[Idx] then Exit;
    L := Length(Queue);
    SetLength(Queue, L + 1);
    Queue[L] := Idx;
    Visited[Idx] := True;
  end;

  function Dequeue(out Idx: Integer): Boolean;
  begin
    Result := qHead < Length(Queue);
    if not Result then Exit;
    Idx := Queue[qHead];
    Inc(qHead);
  end;

  function ApplyOverlayAndCalendar(const ACentreId: Integer; const T: TDateTime): TDateTime;
  var
    c: TCentreCalendar;
  begin
    Result := T;
    if (FFechaBloqueo <> 0) and (Result < FFechaBloqueo) then
      Result := FFechaBloqueo;
    c := GetCalendar(ACentreId);
    if c <> nil then
      Result := c.NextWorkingTime(Result);
  end;

  function IsOFNode(const Idx: Integer): Boolean;
  var D: TNodeData;
  begin
    Result := False;
    if not TryGetNodeData(Idx, D) then Exit;
    Result := (D.NumeroOrdenFabricacion = NumOF) and SameText(D.SerieFabricacion, SerieOF);
  end;

  // Troba el node anterior al mateix centre seqüencial dins dels nodes de la OF
  function FindPrevInCentreSeq(const Idx: Integer): Integer;
  var
    j: Integer;
    bestTime: TDateTime;
  begin
    Result := -1;
    if not IsCentreSequecial(FNodes[Idx].CentreId) then Exit;

    // Cerquem entre TOTS els nodes del centre (no només OF) el predecessor directe
    bestTime := 0;
    for j := 0 to High(FNodes) do
    begin
      if j = Idx then Continue;
      if FNodes[j].CentreId <> FNodes[Idx].CentreId then Continue;
      if FNodes[j].EndTime > FNodes[Idx].StartTime then Continue;
      if (Result = -1) or (FNodes[j].EndTime > bestTime) then
      begin
        Result := j;
        bestTime := FNodes[j].EndTime;
      end;
    end;
  end;

begin
  Result := False;

  if (ANodeIdx < 0) or (ANodeIdx > High(FNodes)) then Exit;
  if not TryGetNodeData(ANodeIdx, DStart) then Exit;

  NumOF := DStart.NumeroOrdenFabricacion;
  SerieOF := DStart.SerieFabricacion;

  // Inicialitzar
  SetLength(Visited, Length(FNodes));
  SetLength(IsAnchor, Length(FNodes));
  for i := 0 to High(Visited) do
  begin
    Visited[i] := False;
    IsAnchor[i] := False;
  end;

  SetLength(Queue, 0);
  qHead := 0;

  // Encuem: tota la OF (arrels) o només a partir del node seleccionat
  if AllOF then
  begin
    // Trobar nodes arrel de la OF (sense predecessors dins la OF)
    for i := 0 to High(FNodes) do
    begin
      if not IsOFNode(i) then Continue;

      // Comprovar si té algun predecessor dins la OF
      hasPredConstraint := False;
      for SuccIdx := 0 to High(FLinks) do
      begin
        if FLinks[SuccIdx].ToNodeId <> FNodes[i].Id then Continue;
        PredIdx := FindNodeIndexById(FLinks[SuccIdx].FromNodeId);
        if (PredIdx >= 0) and IsOFNode(PredIdx) then
        begin
          hasPredConstraint := True;
          Break;
        end;
      end;

      if not hasPredConstraint then
      begin
        IsAnchor[i] := True;  // arrel de la OF: no es mou
        Enqueue(i);
      end;
    end;
  end
  else
  begin
    IsAnchor[ANodeIdx] := True;  // node seleccionat: no es mou
    Enqueue(ANodeIdx);
  end;

  // BFS: recollir tots els nodes de la OF en ordre topològic (endavant)
  while Dequeue(CurrIdx) do
  begin
    for i := 0 to High(FLinks) do
    begin
      if FLinks[i].FromNodeId <> FNodes[CurrIdx].Id then Continue;
      SuccIdx := FindNodeIndexById(FLinks[i].ToNodeId);
      if (SuccIdx >= 0) and IsOFNode(SuccIdx) then
        Enqueue(SuccIdx);
    end;
  end;

  // Queue conté tots els nodes en ordre topològic.
  // Processar tots els nodes excepte els ancoratge (arrels o seleccionat) i els disabled.
  for i := 0 to High(Queue) do
  begin
    CurrIdx := Queue[i];

    // No moure nodes ancoratge (arrels de la OF o node seleccionat)
    if IsAnchor[CurrIdx] then
      Continue;

    // No moure nodes disabled
    if not FNodes[CurrIdx].Enabled then
      Continue;

    centreId := FNodes[CurrIdx].CentreId;
    desiredStart := 0;

    // 1) Constraint de predecessors lògics (links)
    predMinStart := GetMinStartAllowedByPredecessors(CurrIdx, hasPredConstraint);
    if hasPredConstraint then
      desiredStart := predMinStart;

    // 2) Constraint del centre seqüencial (node anterior al centre)
    //    En mode bForce, ignorem nodes d'altres OFs al centre — els empenyerem després
    if (not bForce) and IsCentreSequecial(centreId) then
    begin
      prevIdxInCentre := FindPrevInCentreSeq(CurrIdx);
      if prevIdxInCentre >= 0 then
      begin
        if hasPredConstraint then
          desiredStart := MaxDate(desiredStart, IncMinute(FNodes[prevIdxInCentre].EndTime, MinGapMin))
        else
        begin
          desiredStart := IncMinute(FNodes[prevIdxInCentre].EndTime, MinGapMin);
          hasPredConstraint := True;
        end;
      end;
    end;

    // Aplicar calendari i bloqueig
    if hasPredConstraint then
      desiredStart := ApplyOverlayAndCalendar(centreId, desiredStart);

    // Moure només si podem acostar-lo (shift left)
    if hasPredConstraint and (FNodes[CurrIdx].StartTime > desiredStart) then
    begin
      if MoveNodeKeepingDuration(CurrIdx, desiredStart) then
      begin
        Result := True;

        // En mode Force, empenyem els nodes d'altres OFs que col·lisionin
        if bForce then
          ResolveAllConstraintsFromNode(CurrIdx, MinGapMin);
      end;
    end;
  end;

  if Result then
  begin
    RebuildAfterModelChange(False);
    Invalidate;
  end;
end;


function TGanttControl.BackwardScheduleOF(
  const ANodeIdx: Integer;
  const AEndDate: TDateTime;
  const MinGapMin: Integer;
  const bForce: Boolean = False): Boolean;
var
  DStart: TNodeData;
  NumOF: Integer;
  SerieOF: string;
  Visited: array of Boolean;
  Queue: TIdxArray;
  qHead: Integer;
  i, j, CurrIdx, PredIdx: Integer;
  desiredEnd, desiredStart: TDateTime;
  succMaxEnd: TDateTime;
  hasSuccConstraint: Boolean;
  centreId: Integer;

  function MinDate(const A, B: TDateTime): TDateTime;
  begin
    if A < B then Result := A else Result := B;
  end;

  procedure Enqueue(const Idx: Integer);
  var L: Integer;
  begin
    if (Idx < 0) or (Idx > High(FNodes)) then Exit;
    if Visited[Idx] then Exit;
    L := Length(Queue);
    SetLength(Queue, L + 1);
    Queue[L] := Idx;
    Visited[Idx] := True;
  end;

  function Dequeue(out Idx: Integer): Boolean;
  begin
    Result := qHead < Length(Queue);
    if not Result then Exit;
    Idx := Queue[qHead];
    Inc(qHead);
  end;

  function IsOFNode(const Idx: Integer): Boolean;
  var D: TNodeData;
  begin
    Result := False;
    if not TryGetNodeData(Idx, D) then Exit;
    Result := (D.NumeroOrdenFabricacion = NumOF) and SameText(D.SerieFabricacion, SerieOF);
  end;

  // Troba el node posterior al mateix centre seqüencial (el que ve just després)
  function FindNextInCentreSeq(const Idx: Integer): Integer;
  var
    k: Integer;
    bestTime: TDateTime;
  begin
    Result := -1;
    if not IsCentreSequecial(FNodes[Idx].CentreId) then Exit;
    bestTime := 0;
    for k := 0 to High(FNodes) do
    begin
      if k = Idx then Continue;
      if FNodes[k].CentreId <> FNodes[Idx].CentreId then Continue;
      if FNodes[k].StartTime < FNodes[Idx].EndTime then Continue;
      if (Result = -1) or (FNodes[k].StartTime < bestTime) then
      begin
        Result := k;
        bestTime := FNodes[k].StartTime;
      end;
    end;
  end;

  function ApplyOverlayAndCalendarBackward(const ACentreId: Integer; const T: TDateTime): TDateTime;
  var
    cal: TCentreCalendar;
  begin
    Result := T;
    cal := GetCalendar(ACentreId);
    if cal <> nil then
      Result := cal.PrevWorkingTime(Result);
  end;

begin
  Result := False;

  if (ANodeIdx < 0) or (ANodeIdx > High(FNodes)) then Exit;
  if not TryGetNodeData(ANodeIdx, DStart) then Exit;

  NumOF := DStart.NumeroOrdenFabricacion;
  SerieOF := DStart.SerieFabricacion;

  // Inicialitzar
  SetLength(Visited, Length(FNodes));
  for i := 0 to High(Visited) do
    Visited[i] := False;

  SetLength(Queue, 0);
  qHead := 0;

  // Pas 1: Trobar nodes fulla de la OF (sense successors dins la OF) via BFS invers
  //         Encuem les fulles primer per processar-les com a punt de partida.
  for i := 0 to High(FNodes) do
  begin
    if not IsOFNode(i) then Continue;

    // Comprovar si té algun successor dins la OF
    hasSuccConstraint := False;
    for j := 0 to High(FLinks) do
    begin
      if FLinks[j].FromNodeId <> FNodes[i].Id then Continue;
      PredIdx := FindNodeIndexById(FLinks[j].ToNodeId);
      if (PredIdx >= 0) and IsOFNode(PredIdx) then
      begin
        hasSuccConstraint := True;
        Break;
      end;
    end;

    if not hasSuccConstraint then
      Enqueue(i);
  end;

  // Pas 2: BFS invers — des de les fulles cap a les arrels, recollir predecessors
  while Dequeue(CurrIdx) do
  begin
    for j := 0 to High(FLinks) do
    begin
      if FLinks[j].ToNodeId <> FNodes[CurrIdx].Id then Continue;
      PredIdx := FindNodeIndexById(FLinks[j].FromNodeId);
      if (PredIdx >= 0) and IsOFNode(PredIdx) then
        Enqueue(PredIdx);
    end;
  end;

  // Pas 3: Queue conté tots els nodes en ordre topològic invers (fulles primer, arrels al final).
  //         Processar en aquest ordre: cada node calcula el seu EndTime a partir dels successors.
  for i := 0 to High(Queue) do
  begin
    CurrIdx := Queue[i];

    // No moure nodes disabled
    if not FNodes[CurrIdx].Enabled then
      Continue;

    centreId := FNodes[CurrIdx].CentreId;

    // Calcular desiredEnd: el mínim entre AEndDate i el que permetin els successors
    desiredEnd := AEndDate;

    // 1) Constraint de successors lògics dins la OF (links sortints)
    for j := 0 to High(FLinks) do
    begin
      if FLinks[j].FromNodeId <> FNodes[CurrIdx].Id then Continue;
      PredIdx := FindNodeIndexById(FLinks[j].ToNodeId);
      if (PredIdx < 0) or (not IsOFNode(PredIdx)) then Continue;

      // El successor comença a StartTime; el nostre End ha de ser <= StartTime - MinGapMin
      succMaxEnd := IncMinute(FNodes[PredIdx].StartTime, -MinGapMin);
      desiredEnd := MinDate(desiredEnd, succMaxEnd);
    end;

    // 2) Constraint del centre seqüencial (node posterior al centre): no solapar-nos
    if (not bForce) and IsCentreSequecial(centreId) then
    begin
      j := FindNextInCentreSeq(CurrIdx);
      if j >= 0 then
        desiredEnd := MinDate(desiredEnd, IncMinute(FNodes[j].StartTime, -MinGapMin));
    end;

    // Aplicar calendari enrere
    desiredEnd := ApplyOverlayAndCalendarBackward(centreId, desiredEnd);

    // Calcular start a partir de end i duració
    desiredStart := CalcStartFromEnd(centreId, desiredEnd, FNodes[CurrIdx].DurationMin);

    // Respectar FechaBloqueo
    if (FFechaBloqueo <> 0) and (desiredStart < FFechaBloqueo) then
      Continue;  // no podem col·locar-lo: quedaria abans del bloqueig

    // Moure el node
    if MoveNodeKeepingDuration(CurrIdx, desiredStart) then
    begin
      Result := True;

      // En mode Force, empenyem els nodes d'altres OFs que col·lisionin
      if bForce then
        ResolveAllConstraintsFromNode(CurrIdx, MinGapMin);
    end;
  end;

  if Result then
  begin
    RebuildAfterModelChange(False);
    Invalidate;
  end;
end;


function TGanttControl.CompactOTFromNode(
  const ANodeIdx: Integer;
  const MinGapMin: Integer;
  const AllOT: Boolean = False;
  const bForce: Boolean = False): Boolean;
var
  DStart: TNodeData;
  NumOF: Integer;
  SerieOF: string;
  NumOT: string;
  Visited: array of Boolean;
  IsAnchor: array of Boolean;
  Queue: TIdxArray;
  qHead: Integer;
  i, CurrIdx, SuccIdx, PredIdx: Integer;
  desiredStart, predMinStart: TDateTime;
  hasPredConstraint: Boolean;
  centreId: Integer;
  prevIdxInCentre: Integer;

  function MaxDate(const A, B: TDateTime): TDateTime;
  begin
    if A > B then Result := A else Result := B;
  end;

  procedure Enqueue(const Idx: Integer);
  var L: Integer;
  begin
    if (Idx < 0) or (Idx > High(FNodes)) then Exit;
    if Visited[Idx] then Exit;
    L := Length(Queue);
    SetLength(Queue, L + 1);
    Queue[L] := Idx;
    Visited[Idx] := True;
  end;

  function Dequeue(out Idx: Integer): Boolean;
  begin
    Result := qHead < Length(Queue);
    if not Result then Exit;
    Idx := Queue[qHead];
    Inc(qHead);
  end;

  function ApplyOverlayAndCalendar(const ACentreId: Integer; const T: TDateTime): TDateTime;
  var
    c: TCentreCalendar;
  begin
    Result := T;
    if (FFechaBloqueo <> 0) and (Result < FFechaBloqueo) then
      Result := FFechaBloqueo;
    c := GetCalendar(ACentreId);
    if c <> nil then
      Result := c.NextWorkingTime(Result);
  end;

  function IsOTNode(const Idx: Integer): Boolean;
  var D: TNodeData;
  begin
    Result := False;
    if not TryGetNodeData(Idx, D) then Exit;
    Result := (D.NumeroOrdenFabricacion = NumOF) and
              SameText(D.SerieFabricacion, SerieOF) and
              SameText(D.NumeroTrabajo, NumOT);
  end;

  function FindPrevInCentreSeq(const Idx: Integer): Integer;
  var
    j: Integer;
    bestTime: TDateTime;
  begin
    Result := -1;
    if not IsCentreSequecial(FNodes[Idx].CentreId) then Exit;
    bestTime := 0;
    for j := 0 to High(FNodes) do
    begin
      if j = Idx then Continue;
      if FNodes[j].CentreId <> FNodes[Idx].CentreId then Continue;
      if FNodes[j].EndTime > FNodes[Idx].StartTime then Continue;
      if (Result = -1) or (FNodes[j].EndTime > bestTime) then
      begin
        Result := j;
        bestTime := FNodes[j].EndTime;
      end;
    end;
  end;

begin
  Result := False;

  if (ANodeIdx < 0) or (ANodeIdx > High(FNodes)) then Exit;
  if not TryGetNodeData(ANodeIdx, DStart) then Exit;

  NumOF := DStart.NumeroOrdenFabricacion;
  SerieOF := DStart.SerieFabricacion;
  NumOT := DStart.NumeroTrabajo;

  // Inicialitzar
  SetLength(Visited, Length(FNodes));
  SetLength(IsAnchor, Length(FNodes));
  for i := 0 to High(Visited) do
  begin
    Visited[i] := False;
    IsAnchor[i] := False;
  end;

  SetLength(Queue, 0);
  qHead := 0;

  // Encuem: tota la OT (arrels) o només a partir del node seleccionat
  if AllOT then
  begin
    // Trobar nodes arrel de la OT (sense predecessors dins la OT)
    for i := 0 to High(FNodes) do
    begin
      if not IsOTNode(i) then Continue;

      hasPredConstraint := False;
      for SuccIdx := 0 to High(FLinks) do
      begin
        if FLinks[SuccIdx].ToNodeId <> FNodes[i].Id then Continue;
        PredIdx := FindNodeIndexById(FLinks[SuccIdx].FromNodeId);
        if (PredIdx >= 0) and IsOTNode(PredIdx) then
        begin
          hasPredConstraint := True;
          Break;
        end;
      end;

      if not hasPredConstraint then
      begin
        IsAnchor[i] := True;
        Enqueue(i);
      end;
    end;
  end
  else
  begin
    IsAnchor[ANodeIdx] := True;
    Enqueue(ANodeIdx);
  end;

  // BFS: recollir tots els nodes de la OT en ordre topològic (endavant)
  while Dequeue(CurrIdx) do
  begin
    for i := 0 to High(FLinks) do
    begin
      if FLinks[i].FromNodeId <> FNodes[CurrIdx].Id then Continue;
      SuccIdx := FindNodeIndexById(FLinks[i].ToNodeId);
      if (SuccIdx >= 0) and IsOTNode(SuccIdx) then
        Enqueue(SuccIdx);
    end;
  end;

  // Processar tots els nodes excepte ancoratges i disabled
  for i := 0 to High(Queue) do
  begin
    CurrIdx := Queue[i];

    if IsAnchor[CurrIdx] then
      Continue;

    if not FNodes[CurrIdx].Enabled then
      Continue;

    centreId := FNodes[CurrIdx].CentreId;
    desiredStart := 0;

    // 1) Constraint de predecessors lògics (links)
    predMinStart := GetMinStartAllowedByPredecessors(CurrIdx, hasPredConstraint);
    if hasPredConstraint then
      desiredStart := predMinStart;

    // 2) Constraint del centre seqüencial
    if (not bForce) and IsCentreSequecial(centreId) then
    begin
      prevIdxInCentre := FindPrevInCentreSeq(CurrIdx);
      if prevIdxInCentre >= 0 then
      begin
        if hasPredConstraint then
          desiredStart := MaxDate(desiredStart, IncMinute(FNodes[prevIdxInCentre].EndTime, MinGapMin))
        else
        begin
          desiredStart := IncMinute(FNodes[prevIdxInCentre].EndTime, MinGapMin);
          hasPredConstraint := True;
        end;
      end;
    end;

    // Aplicar calendari i bloqueig
    if hasPredConstraint then
      desiredStart := ApplyOverlayAndCalendar(centreId, desiredStart);

    // Moure només si podem acostar-lo (shift left)
    if hasPredConstraint and (FNodes[CurrIdx].StartTime > desiredStart) then
    begin
      if MoveNodeKeepingDuration(CurrIdx, desiredStart) then
      begin
        Result := True;
        if bForce then
          ResolveAllConstraintsFromNode(CurrIdx, MinGapMin);
      end;
    end;
  end;

  if Result then
  begin
    RebuildAfterModelChange(False);
    Invalidate;
  end;
end;


function TGanttControl.BackwardScheduleOT(
  const ANodeIdx: Integer;
  const AEndDate: TDateTime;
  const MinGapMin: Integer;
  const bForce: Boolean = False): Boolean;
var
  DStart: TNodeData;
  NumOF: Integer;
  SerieOF: string;
  NumOT: string;
  Visited: array of Boolean;
  Queue: TIdxArray;
  qHead: Integer;
  i, j, CurrIdx, PredIdx: Integer;
  desiredEnd, desiredStart: TDateTime;
  succMaxEnd: TDateTime;
  hasSuccConstraint: Boolean;
  centreId: Integer;

  function MinDate(const A, B: TDateTime): TDateTime;
  begin
    if A < B then Result := A else Result := B;
  end;

  procedure Enqueue(const Idx: Integer);
  var L: Integer;
  begin
    if (Idx < 0) or (Idx > High(FNodes)) then Exit;
    if Visited[Idx] then Exit;
    L := Length(Queue);
    SetLength(Queue, L + 1);
    Queue[L] := Idx;
    Visited[Idx] := True;
  end;

  function Dequeue(out Idx: Integer): Boolean;
  begin
    Result := qHead < Length(Queue);
    if not Result then Exit;
    Idx := Queue[qHead];
    Inc(qHead);
  end;

  function IsOTNode(const Idx: Integer): Boolean;
  var D: TNodeData;
  begin
    Result := False;
    if not TryGetNodeData(Idx, D) then Exit;
    Result := (D.NumeroOrdenFabricacion = NumOF) and
              SameText(D.SerieFabricacion, SerieOF) and
              SameText(D.NumeroTrabajo, NumOT);
  end;

  function FindNextInCentreSeq(const Idx: Integer): Integer;
  var
    k: Integer;
    bestTime: TDateTime;
  begin
    Result := -1;
    if not IsCentreSequecial(FNodes[Idx].CentreId) then Exit;
    bestTime := 0;
    for k := 0 to High(FNodes) do
    begin
      if k = Idx then Continue;
      if FNodes[k].CentreId <> FNodes[Idx].CentreId then Continue;
      if FNodes[k].StartTime < FNodes[Idx].EndTime then Continue;
      if (Result = -1) or (FNodes[k].StartTime < bestTime) then
      begin
        Result := k;
        bestTime := FNodes[k].StartTime;
      end;
    end;
  end;

  function ApplyOverlayAndCalendarBackward(const ACentreId: Integer; const T: TDateTime): TDateTime;
  var
    cal: TCentreCalendar;
  begin
    Result := T;
    cal := GetCalendar(ACentreId);
    if cal <> nil then
      Result := cal.PrevWorkingTime(Result);
  end;

begin
  Result := False;

  if (ANodeIdx < 0) or (ANodeIdx > High(FNodes)) then Exit;
  if not TryGetNodeData(ANodeIdx, DStart) then Exit;

  NumOF := DStart.NumeroOrdenFabricacion;
  SerieOF := DStart.SerieFabricacion;
  NumOT := DStart.NumeroTrabajo;

  // Inicialitzar
  SetLength(Visited, Length(FNodes));
  for i := 0 to High(Visited) do
    Visited[i] := False;

  SetLength(Queue, 0);
  qHead := 0;

  // Pas 1: Trobar nodes fulla de la OT (sense successors dins la OT)
  for i := 0 to High(FNodes) do
  begin
    if not IsOTNode(i) then Continue;

    hasSuccConstraint := False;
    for j := 0 to High(FLinks) do
    begin
      if FLinks[j].FromNodeId <> FNodes[i].Id then Continue;
      PredIdx := FindNodeIndexById(FLinks[j].ToNodeId);
      if (PredIdx >= 0) and IsOTNode(PredIdx) then
      begin
        hasSuccConstraint := True;
        Break;
      end;
    end;

    if not hasSuccConstraint then
      Enqueue(i);
  end;

  // Pas 2: BFS invers — des de les fulles cap a les arrels
  while Dequeue(CurrIdx) do
  begin
    for j := 0 to High(FLinks) do
    begin
      if FLinks[j].ToNodeId <> FNodes[CurrIdx].Id then Continue;
      PredIdx := FindNodeIndexById(FLinks[j].FromNodeId);
      if (PredIdx >= 0) and IsOTNode(PredIdx) then
        Enqueue(PredIdx);
    end;
  end;

  // Pas 3: Processar en ordre topològic invers (fulles primer)
  for i := 0 to High(Queue) do
  begin
    CurrIdx := Queue[i];

    if not FNodes[CurrIdx].Enabled then
      Continue;

    centreId := FNodes[CurrIdx].CentreId;
    desiredEnd := AEndDate;

    // 1) Constraint de successors lògics dins la OT
    for j := 0 to High(FLinks) do
    begin
      if FLinks[j].FromNodeId <> FNodes[CurrIdx].Id then Continue;
      PredIdx := FindNodeIndexById(FLinks[j].ToNodeId);
      if (PredIdx < 0) or (not IsOTNode(PredIdx)) then Continue;

      succMaxEnd := IncMinute(FNodes[PredIdx].StartTime, -MinGapMin);
      desiredEnd := MinDate(desiredEnd, succMaxEnd);
    end;

    // 2) Constraint del centre seqüencial
    if (not bForce) and IsCentreSequecial(centreId) then
    begin
      j := FindNextInCentreSeq(CurrIdx);
      if j >= 0 then
        desiredEnd := MinDate(desiredEnd, IncMinute(FNodes[j].StartTime, -MinGapMin));
    end;

    // Aplicar calendari enrere
    desiredEnd := ApplyOverlayAndCalendarBackward(centreId, desiredEnd);

    // Calcular start a partir de end i duració
    desiredStart := CalcStartFromEnd(centreId, desiredEnd, FNodes[CurrIdx].DurationMin);

    // Respectar FechaBloqueo
    if (FFechaBloqueo <> 0) and (desiredStart < FFechaBloqueo) then
      Continue;

    // Moure el node
    if MoveNodeKeepingDuration(CurrIdx, desiredStart) then
    begin
      Result := True;
      if bForce then
        ResolveAllConstraintsFromNode(CurrIdx, MinGapMin);
    end;
  end;

  if Result then
  begin
    RebuildAfterModelChange(False);
    Invalidate;
  end;
end;


function TGanttControl.ShiftLeftAllImpactedSequentialFromDate(
  const AFromTime: TDateTime;
  const MinGapMin: Integer): Boolean;
type
  TCentreCache = record
    CentreId: Integer;
    NodeList: TIdxArray; // indices de FNodes ordenats per StartTime, Id
  end;

  TCentreCacheArray = array of TCentreCache;

var
  CentreCaches: TCentreCacheArray;
  Queue: TIdxArray;
  InQueue: array of Boolean;
  ProcessedCount: array of Integer;
  NodeToCentreSlot: array of Integer;
  NodePosInCentre: array of Integer;
  NextNodeInCentre: array of Integer;
  qHead: Integer;

  function MaxDate(const A, B: TDateTime): TDateTime;
  begin
    if A > B then Result := A else Result := B;
  end;

  procedure ClearIdxArray(var A: TIdxArray);
  begin
    SetLength(A, 0);
  end;

  procedure Enqueue(const AIdx: Integer);
  var
    L: Integer;
  begin
    if (AIdx < 0) or (AIdx > High(FNodes)) then Exit;
    if InQueue[AIdx] then Exit;

    L := Length(Queue);
    SetLength(Queue, L + 1);
    Queue[L] := AIdx;
    InQueue[AIdx] := True;
  end;

  function Dequeue(out AIdx: Integer): Boolean;
  begin
    Result := qHead < Length(Queue);
    if not Result then Exit;

    AIdx := Queue[qHead];
    InQueue[AIdx] := False;
    Inc(qHead);
  end;

  function ApplyOverlayAndCalendar(const ACentreId: Integer; const T: TDateTime): TDateTime;
  var
    cal: TCentreCalendar;
  begin
    Result := T;

    if (FFechaBloqueo <> 0) and (Result < FFechaBloqueo) then
      Result := FFechaBloqueo;

    cal := GetCalendar(ACentreId);
    if cal <> nil then
      Result := cal.NextWorkingTime(Result);
  end;

  function CompareNodeIdx(const L, R: Integer): Integer;
  var
    a, b: TDateTime;
  begin
    a := FNodes[L].StartTime;
    b := FNodes[R].StartTime;

    if a < b then Exit(-1);
    if a > b then Exit(1);

    if FNodes[L].Id < FNodes[R].Id then Exit(-1);
    if FNodes[L].Id > FNodes[R].Id then Exit(1);

    Result := 0;
  end;

  procedure QuickSortIdx(var A: TIdxArray; L, R: Integer);
  var
    I, J, P, T: Integer;
  begin
    I := L;
    J := R;
    P := A[(L + R) shr 1];

    repeat
      while CompareNodeIdx(A[I], P) < 0 do Inc(I);
      while CompareNodeIdx(A[J], P) > 0 do Dec(J);

      if I <= J then
      begin
        T := A[I];
        A[I] := A[J];
        A[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;

    if L < J then QuickSortIdx(A, L, J);
    if I < R then QuickSortIdx(A, I, R);
  end;

  procedure SortIdx(var A: TIdxArray);
  begin
    if Length(A) > 1 then
      QuickSortIdx(A, 0, High(A));
  end;

  function FindCentreSlot(const ACentreId: Integer): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    for i := 0 to High(CentreCaches) do
      if CentreCaches[i].CentreId = ACentreId then
        Exit(i);
  end;

  procedure AddNodeToCentreCache(const ACentreId, ANodeIdx: Integer);
  var
    slot, L: Integer;
  begin
    slot := FindCentreSlot(ACentreId);
    if slot < 0 then
    begin
      slot := Length(CentreCaches);
      SetLength(CentreCaches, slot + 1);
      CentreCaches[slot].CentreId := ACentreId;
      SetLength(CentreCaches[slot].NodeList, 0);
    end;

    L := Length(CentreCaches[slot].NodeList);
    SetLength(CentreCaches[slot].NodeList, L + 1);
    CentreCaches[slot].NodeList[L] := ANodeIdx;
  end;

  procedure BuildSequentialCentreCache;
  var
    i, slot, p, n: Integer;
  begin
    SetLength(CentreCaches, 0);

    SetLength(NodeToCentreSlot, Length(FNodes));
    SetLength(NodePosInCentre, Length(FNodes));
    SetLength(NextNodeInCentre, Length(FNodes));

    for i := 0 to High(FNodes) do
    begin
      NodeToCentreSlot[i] := -1;
      NodePosInCentre[i] := -1;
      NextNodeInCentre[i] := -1;
    end;

    // 1) Agrupa només nodes de centres seqüencials
    for i := 0 to High(FNodes) do
      if IsCentreSequecial(FNodes[i].CentreId) then
        AddNodeToCentreCache(FNodes[i].CentreId, i);

    // 2) Ordena cada centre i omple índexs inversos
    for slot := 0 to High(CentreCaches) do
    begin
      SortIdx(CentreCaches[slot].NodeList);

      n := Length(CentreCaches[slot].NodeList);
      for p := 0 to n - 1 do
      begin
        i := CentreCaches[slot].NodeList[p];
        NodeToCentreSlot[i] := slot;
        NodePosInCentre[i] := p;

        if p < n - 1 then
          NextNodeInCentre[i] := CentreCaches[slot].NodeList[p + 1]
        else
          NextNodeInCentre[i] := -1;
      end;
    end;
  end;

  function GetPreviousNodeInCentre(const ANodeIdx: Integer): Integer;
  var
    slot, pos: Integer;
  begin
    Result := -1;

    if (ANodeIdx < 0) or (ANodeIdx > High(FNodes)) then Exit;

    slot := NodeToCentreSlot[ANodeIdx];
    pos := NodePosInCentre[ANodeIdx];

    if (slot < 0) or (pos <= 0) then Exit;

    Result := CentreCaches[slot].NodeList[pos - 1];
  end;

  function GetFirstAffectedNodeInCentre(const ACentreSlot: Integer): Integer;
  var
    list: TIdxArray;
    lo, hi, mid, ans: Integer;
  begin
    Result := -1;
    list := CentreCaches[ACentreSlot].NodeList;
    if Length(list) = 0 then Exit;

    // cerca binària del primer StartTime >= AFromTime
    lo := 0;
    hi := High(list);
    ans := -1;

    while lo <= hi do
    begin
      mid := (lo + hi) shr 1;
      if FNodes[list[mid]].StartTime >= AFromTime then
      begin
        ans := mid;
        hi := mid - 1;
      end
      else
        lo := mid + 1;
    end;

    if ans >= 0 then
      Result := list[ans];
  end;

  procedure SeedInitialQueue;
  var
    slot, idx: Integer;
  begin
    for slot := 0 to High(CentreCaches) do
    begin
      idx := GetFirstAffectedNodeInCentre(slot);
      if idx >= 0 then
        Enqueue(idx);
    end;
  end;

  procedure EnqueueSequentialSuccessorsOfNode(const APredIdx: Integer);
  var
    i, SuccIdx: Integer;
  begin
    for i := 0 to High(FLinks) do
    begin
      if FLinks[i].FromNodeId <> FNodes[APredIdx].Id then
        Continue;

      SuccIdx := FindNodeIndexById(FLinks[i].ToNodeId);
      if (SuccIdx >= 0) and IsCentreSequecial(FNodes[SuccIdx].CentreId) then
        Enqueue(SuccIdx);
    end;
  end;

  function ShiftLeftSingleNode(const NodeIdx: Integer): Boolean;
  var
    prevIdx: Integer;
    desiredStart: TDateTime;
    predMinStart: TDateTime;
    hasPredConstraint: Boolean;
    centreId: Integer;
  begin
    Result := False;

    if (NodeIdx < 0) or (NodeIdx > High(FNodes)) then Exit;
    if NodeToCentreSlot[NodeIdx] < 0 then Exit; // no és centre seqüencial

    centreId := FNodes[NodeIdx].CentreId;

    // Restricció per node anterior del centre
    prevIdx := GetPreviousNodeInCentre(NodeIdx);
    if prevIdx >= 0 then
      desiredStart := IncMinute(FNodes[prevIdx].EndTime, MinGapMin)
    else
      desiredStart := AFromTime;

    // Restricció per predecessors lògics
    predMinStart := GetMinStartAllowedByPredecessors(NodeIdx, hasPredConstraint);
    if hasPredConstraint then
      desiredStart := MaxDate(desiredStart, predMinStart);

    desiredStart := ApplyOverlayAndCalendar(centreId, desiredStart);

    // Només compactem cap a l'esquerra
    if FNodes[NodeIdx].StartTime > desiredStart then
      Result := MoveNodeKeepingDuration(NodeIdx, desiredStart);
  end;

var
  CurrIdx, NextIdx: Integer;
  Changed: Boolean;
begin
  Result := False;

  if Length(FNodes) = 0 then Exit;

  SetLength(InQueue, Length(FNodes));
  SetLength(ProcessedCount, Length(FNodes));
  ClearIdxArray(Queue);
  qHead := 0;

  BuildSequentialCentreCache;
  SeedInitialQueue;

  while Dequeue(CurrIdx) do
  begin
    if (CurrIdx < 0) or (CurrIdx > High(FNodes)) then
      Continue;

    Inc(ProcessedCount[CurrIdx]);
    if ProcessedCount[CurrIdx] > 20 then
      Continue; // protecció davant cicles o oscil·lacions

    Changed := ShiftLeftSingleNode(CurrIdx);

    if Changed then
    begin
      Result := True;

      // Pot alliberar espai pel següent del mateix centre
      NextIdx := NextNodeInCentre[CurrIdx];
      if NextIdx >= 0 then
        Enqueue(NextIdx);

      // I pot permetre compactar successors lògics en altres centres seqüencials
      EnqueueSequentialSuccessorsOfNode(CurrIdx);
    end;
  end;

  if Result then
  begin
    RebuildAfterModelChange(False);
    Invalidate;
  end;
end;



function TGanttControl.ShiftLeftSequentialCentresFromDate(
  const AFromTime: TDateTime;
  const MinGapMin: Integer): Boolean;
type
  TIntArray = array of Integer;
var
  CentresDone: TIntArray;
  i: Integer;
  CentreId: Integer;

  function IntArrayContains(const A: TIntArray; const Value: Integer): Boolean;
  var
    j: Integer;
  begin
    Result := False;
    for j := 0 to High(A) do
      if A[j] = Value then
        Exit(True);
  end;

  procedure IntArrayAddUnique(var A: TIntArray; const Value: Integer);
  var
    L: Integer;
  begin
    if IntArrayContains(A, Value) then Exit;
    L := Length(A);
    SetLength(A, L + 1);
    A[L] := Value;
  end;

  function MaxDate(const A, B: TDateTime): TDateTime;
  begin
    if A > B then Result := A else Result := B;
  end;

  function ApplyOverlayAndCalendar(const ACentreId: Integer; const T: TDateTime): TDateTime;
  var
    cal: TCentreCalendar;
  begin
    Result := T;

    if (FFechaBloqueo <> 0) and (Result < FFechaBloqueo) then
      Result := FFechaBloqueo;

    cal := GetCalendar(ACentreId);
    if cal <> nil then
      Result := cal.NextWorkingTime(Result);
  end;

  function CmpIdx(const L, R: Integer): Integer;
  var
    a, b: TDateTime;
  begin
    a := FNodes[L].StartTime;
    b := FNodes[R].StartTime;

    if a < b then Exit(-1);
    if a > b then Exit( 1);

    if FNodes[L].Id < FNodes[R].Id then Exit(-1);
    if FNodes[L].Id > FNodes[R].Id then Exit( 1);
    Result := 0;
  end;

  procedure SortIdx(var A: TIdxArray);
  var
    swapped: Boolean;
    t, j: Integer;
  begin
    if Length(A) <= 1 then Exit;

    repeat
      swapped := False;
      for j := 0 to High(A) - 1 do
        if CmpIdx(A[j], A[j + 1]) > 0 then
        begin
          t := A[j];
          A[j] := A[j + 1];
          A[j + 1] := t;
          swapped := True;
        end;
    until not swapped;
  end;

  function BuildCentreNodeList(const ACentreId: Integer): TIdxArray;
  var
    j, k: Integer;
  begin
    SetLength(Result, 0);
    for j := 0 to High(FNodes) do
      if FNodes[j].CentreId = ACentreId then
      begin
        k := Length(Result);
        SetLength(Result, k + 1);
        Result[k] := j;
      end;
  end;

  function ShiftLeftOneCentre(const ACentreId: Integer): Boolean;
  var
    list: TIdxArray;
    i, startPos: Integer;
    prevIdx, nodeIdx: Integer;
    desiredStart, minPredStart: TDateTime;
    hasPredConstraint: Boolean;
    cursor: TDateTime;
  begin
    Result := False;

    if not IsCentreSequecial(ACentreId) then
      Exit;

    list := BuildCentreNodeList(ACentreId);
    if Length(list) <= 1 then
      Exit;

    SortIdx(list);

    // Primer node afectat: els que comencen a partir del datetime
    startPos := -1;
    for i := 0 to High(list) do
      if FNodes[list[i]].StartTime >= AFromTime then
      begin
        startPos := i;
        Break;
      end;

    if startPos < 0 then
      Exit;

    // Cursor inicial: si hi ha node previ, no podem trepitjar-lo
    if startPos > 0 then
    begin
      prevIdx := list[startPos - 1];
      cursor := IncMinute(FNodes[prevIdx].EndTime, MinGapMin);
    end
    else
      cursor := AFromTime;

    cursor := ApplyOverlayAndCalendar(ACentreId, cursor);

    for i := startPos to High(list) do
    begin
      nodeIdx := list[i];

      // earliest per seqüència del centre
      desiredStart := cursor;

      // earliest per dependències entrants
      minPredStart := GetMinStartAllowedByPredecessors(nodeIdx, hasPredConstraint);
      if hasPredConstraint then
        desiredStart := MaxDate(desiredStart, minPredStart);

      desiredStart := ApplyOverlayAndCalendar(ACentreId, desiredStart);

      // només movem a l'esquerra
      if FNodes[nodeIdx].StartTime > desiredStart then
      begin
        if MoveNodeKeepingDuration(nodeIdx, desiredStart) then
          Result := True;
      end;

      cursor := IncMinute(FNodes[nodeIdx].EndTime, MinGapMin);
      cursor := ApplyOverlayAndCalendar(ACentreId, cursor);
    end;
  end;

begin
  Result := False;
  SetLength(CentresDone, 0);

  for i := 0 to High(FNodes) do
  begin
    CentreId := FNodes[i].CentreId;

    if IntArrayContains(CentresDone, CentreId) then
      Continue;

    IntArrayAddUnique(CentresDone, CentreId);

    if IsCentreSequecial(CentreId) then
      if ShiftLeftOneCentre(CentreId) then
        Result := True;
  end;

  if Result then
  begin
    RebuildAfterModelChange(False);
    Invalidate;
  end;
end;

function TGanttControl.GetDateTimeFromPoint(X, Y: Single): TDateTime;
var
  worldX: Double;
  minutesFromStart: Double;
begin
  // Screen → World
  worldX := X + FScrollX;

  // píxels → minuts visibles → TDateTime (respecta HideWeekends)
  minutesFromStart := worldX / FPxPerMinute;
  Result := AddVisibleMinutes(FStartTime, minutesFromStart);
end;


function TGanttControl.GetCentreIdFromPoint(X, Y: Single): Integer;
var
  i: Integer;
  worldY: Double;
  row: TRowLayout;
begin
  Result := -1;

  // Screen → World
  worldY := Y + FScrollY;

  for i := 0 to High(FRows) do
  begin
    row := FRows[i];

    if not row.Visible then
      Continue;

    if (worldY >= row.TopY) and
       (worldY <= row.TopY + row.Height) then
      Exit(row.CentreId);
  end;
end;


function TGanttControl.GetNonWorkingIntervalFromPointMerged(
  X, Y: Single;
  out AStart, AEnd: TDateTime;
  out ACentreId: Integer;
  const ARadiusDays: Integer
): Boolean;
var
  cal: TCentreCalendar;
  t: TDateTime;
  baseDay: TDateTime;

  function FindOne(out S0, E0: TDateTime): Boolean;
  var
    d: Integer;
    day: TDateTime;
    periods: TArray<TNonWorkingPeriod>;
    p: TNonWorkingPeriod;
    s, e: TDateTime;
  begin
    Result := False;
    for d := -ARadiusDays to ARadiusDays do
    begin
      day := IncDay(baseDay, d);
      periods := cal.NonWorkingPeriodsForDate(day);
      for p in periods do
      begin
        s := day + p.StartTimeOfDay;
        e := day + p.EndTimeOfDay;
        if p.EndTimeOfDay <= p.StartTimeOfDay then
          e := IncDay(day, 1) + p.EndTimeOfDay;

        if (t >= s) and (t < e) then
        begin
          S0 := s;
          E0 := e;
          Exit(True);
        end;
      end;
    end;
  end;

  procedure Expand(var S, E: TDateTime);
  var
    changed: Boolean;
    d: Integer;
    day: TDateTime;
    periods: TArray<TNonWorkingPeriod>;
    p: TNonWorkingPeriod;
    s2, e2: TDateTime;
  begin
    // Itera fins que no pugui expandir més (solapes o contigüitat)
    repeat
      changed := False;

      // Recorrem dies en l’entorn actual [S..E] amb marge ARadiusDays
      for d := -ARadiusDays to ARadiusDays do
      begin
        day := IncDay(DateOf(S), d);

        periods := cal.NonWorkingPeriodsForDate(day);
        for p in periods do
        begin
          s2 := day + p.StartTimeOfDay;
          e2 := day + p.EndTimeOfDay;
          if p.EndTimeOfDay <= p.StartTimeOfDay then
            e2 := IncDay(day, 1) + p.EndTimeOfDay;

          // si solapa o és contigu (mateix instant)
          if (e2 >= S) and (s2 <= E) then
          begin
            if s2 < S then begin S := s2; changed := True; end;
            if e2 > E then begin E := e2; changed := True; end;
          end
          else if SameValue(e2, S, 1/864000) then // contigu ~0.1s
          begin
            S := s2; changed := True;
          end
          else if SameValue(s2, E, 1/864000) then
          begin
            E := e2; changed := True;
          end;
        end;
      end;

    until not changed;
  end;

begin
  Result := False;
  AStart := 0; AEnd := 0;

  ACentreId := GetCentreIdFromPoint(X, Y);
  if ACentreId < 0 then Exit;

  t := GetDateTimeFromPoint(X, Y);
  cal := GetCalendar(ACentreId);
  baseDay := DateOf(t);

  if not FindOne(AStart, AEnd) then
    Exit(False);

  Expand(AStart, AEnd);
  Result := True;
end;


procedure TGanttControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  hit: Integer;
  bx: Single;
  Edge: TResizeEdge;
begin
  inherited;

  FClickDatetime := GetDateTimeFromPoint(X, Y);
  FClickPoint := Point(X, Y);

  if Button = mbMiddle then
  begin
    FIsPanning := True;
    FPanStart := Point(X, Y);
    FScrollStartX := FScrollX;
    FScrollStartY := FScrollY;
    Exit;
  end;

  if Button <> mbLeft then
   Exit;

  if FClickDatetime < FFechaBloqueo then
   Abort;

  //...si marquem al fons del gantt a un lloc buit
  if (Length(FSearchResults)>0) OR (FHighlightSet.Count>0) then
   ClearSearch;


  //...si fem clic al Fecha Bloqueo
  if HitTestBloqueo(X, Y) then
  begin
    FDraggingBloqueo := True;
    bx := BloqueoX;
    FDragOffsetX := bx - X;     // per no “saltar” al click
    MouseCapture := True;
    Invalidate;
    Exit;
  end;

  //...si fem clic a un Marker (no iniciem drag aquí, esperem DRAG_THRESHOLD a MouseMove)
  begin
    var mId: Integer := HitTestMarker(X);
    if mId >= 0 then
    begin
      FMouseDownMarkerId := mId;
      FMouseDownPos := Point(X, Y);
      FDidDrag := False;
      Exit;
    end;
  end;

  FMouseDownPos := Point(X, Y);
  FDidDrag := False;
  FMouseDownNodeIndex := HitTestNodeIndex(X, Y);


   //fem recuadre de selecció
  if (FMouseDownNodeIndex < 0) and (ssShift in Shift) then
  begin
    FMarqueeSelecting := True;
    FMarqueeStartPt := Point(X, Y);
    FMarqueeCurrentPt := FMarqueeStartPt;
    Invalidate;
    Exit;
  end;

  // primer: handle?
  FMouseDownOnHandle := nhNone;
  if FFocusedNodeIndex >= 0 then
    FMouseDownOnHandle := HitTestSelectedNodeHandle(X, Y, edge);

  if (FMouseDownOnHandle = nhLeft) OR
     (FMouseDownOnHandle = nhRight) then
  begin
     if not FNodes[FFocusedNodeIndex].Enabled then Exit;

     // Ctrl+handle → iniciar link drag
     if ssCtrl in Shift then
     begin
       FLinkDragging := True;
       FLinkFromNodeIndex := FFocusedNodeIndex;
       if FMouseDownOnHandle = nhRight then
         FLinkFromEdge := reRight
       else
         FLinkFromEdge := reLeft;
       FLinkPreviewEnd := PointF(X, Y);
       FMouseDownNodeIndex := -1; // evitar que s'interpreti com a move/resize
       MouseCapture := True;
       Invalidate;
       Exit;
     end;

     FResizing := True;
     FMouseDownNodeIndex := FFocusedNodeIndex;
     FResizeNodeIndex := FFocusedNodeIndex;
     Exit;
  end;

  // feedback immediat (opcional però recomanat)
  if FMouseDownNodeIndex >= 0 then
  begin
    FFocusedNodeIndex := FMouseDownNodeIndex;
    Invalidate;
  end;

end;


function TGanttControl.IsMarqueeLargeEnough: Boolean;
var
  R: TRect;
begin
  R := GetMarqueeRect;
  Result := (Abs(R.Right - R.Left) >= 4) or
            (Abs(R.Bottom - R.Top) >= 4);
end;



function TGanttControl.GetNodeRectPx(const NodeIndex: Integer; out R: TRect): Boolean;
var
  RW: TRectF;
begin
  Result := False;
  R := Rect(0, 0, 0, 0);
  if not TryGetNodeLayoutRectWorld(NodeIndex, RW) then
    Exit;
  R.Left   := Floor(RW.Left   - FScrollX);
  R.Top    := Floor(RW.Top    - FScrollY);
  R.Right  := Ceil (RW.Right  - FScrollX);
  R.Bottom := Ceil (RW.Bottom - FScrollY);
  Result := True;
end;

procedure TGanttControl.SelectNodesInMarquee(const AddToSelection: Boolean);
var
  selRect, nodeRect, r: TRect;
  i: Integer;
begin
  selRect := GetMarqueeRect;

  if not AddToSelection then
    FSelectedNodeIndexes.Clear;

  for i := 0 to High(FNodes) do
  begin
    if not FNodes[i].Visible then
      Continue;

    if not GetNodeRectPx(i, nodeRect) then
      Continue;

    if IntersectRect(r, selRect, nodeRect) then
    begin
      FSelectedNodeIndexes.AddOrSetValue(i, 1);
      FFocusedNodeIndex := i;
    end;
  end;

  Invalidate;
end;





procedure TGanttControl.DrawMarqueeD2D(const RT: ID2D1RenderTarget);
var
  R: TRect;
  RF: TD2D1RectF;
  StrokeBrush, FillBrush: ID2D1SolidColorBrush;
begin
  if not FMarqueeSelecting then
    Exit;
  R := GetMarqueeRect;
  if IsRectEmpty(R) then
    Exit;
  RF.Left   := R.Left;
  RF.Top    := R.Top;
  RF.Right  := R.Right;
  RF.Bottom := R.Bottom;
  RT.CreateSolidColorBrush(D2D1ColorF(0.29, 0.56, 0.89, 0.10), nil, FillBrush);
  RT.CreateSolidColorBrush(D2D1ColorF(0.29, 0.56, 0.89, 1.00), nil, StrokeBrush);
  if FillBrush <> nil then
    RT.FillRectangle(RF, FillBrush);
  if StrokeBrush <> nil then
    RT.DrawRectangle(RF, StrokeBrush, 1.0);
end;


procedure TGanttControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  nodeIdx: Integer;
  pt: TPoint;
begin

  inherited;

  if Button = mbMiddle then
  begin
    FIsPanning := False;
    Exit;
  end;

  if Button <> mbLeft then
   Exit;

  // Finalitzar link drag
  if FLinkDragging then
  begin
    FLinkDragging := False;
    MouseCapture := False;
    SetGanttCursor(crDefault);

    // Hit-test: on hem deixat anar?
    var targetNodeIdx: Integer := HitTestNodeIndex(X, Y);
    if (targetNodeIdx >= 0) and (targetNodeIdx <> FLinkFromNodeIndex) then
    begin
      var fromId: Integer := FNodes[FLinkFromNodeIndex].Id;
      var toId: Integer := FNodes[targetNodeIdx].Id;

      // Comprovar que no existeixi ja un link entre aquests dos nodes
      var linkExists: Boolean := False;
      var li: Integer;
      for li := 0 to High(FLinks) do
        if (FLinks[li].FromNodeId = fromId) and (FLinks[li].ToNodeId = toId) then
        begin
          linkExists := True;
          Break;
        end;

      if not linkExists then
      begin
        var newLink: TErpLink;
        newLink.FromNodeId := fromId;
        newLink.ToNodeId := toId;
        newLink.PorcentajeDependencia := 0;

        if FLinkFromEdge = reRight then
          newLink.LinkType := ltFinishStart
        else
          newLink.LinkType := ltStartStart;

        AddLink(newLink);
      end;
    end;

    Invalidate;
    Exit;
  end;

  if FDraggingBloqueo then
  begin
      FDraggingBloqueo := False;
      MouseCapture := False;
      Invalidate;
      if Assigned(FOnFechaBloqueoChanged) then
        FOnFechaBloqueoChanged(Self);
      Exit;
  end;

  // Finalitzar marker drag
  if FDraggingMarkerId >= 0 then
  begin
    var mkId: Integer := FDraggingMarkerId;
    FDraggingMarkerId := -1;
    FMouseDownMarkerId := -1;
    MouseCapture := False;
    if Assigned(FOnMarkerMoved) then
    begin
      var mkk: Integer;
      for mkk := 0 to High(FMarkers) do
        if FMarkers[mkk].Id = mkId then
        begin
          FOnMarkerMoved(Self, mkId, FMarkers[mkk].DateTime);
          Break;
        end;
    end;
    Invalidate;
    Exit;
  end;

  // Clic simple a marker (sense drag): disparar OnMarkerClick
  if FMouseDownMarkerId >= 0 then
  begin
    var mkClickId: Integer := FMouseDownMarkerId;
    FMouseDownMarkerId := -1;
    if Assigned(FOnMarkerClick) then
      FOnMarkerClick(Self, mkClickId);
    Invalidate;
    Exit;
  end;

  if FMarqueeSelecting then
  begin
    FMarqueeCurrentPt := Point(X, Y);
    if IsMarqueeLargeEnough then
     SelectNodesInMarquee(True);
    FMarqueeSelecting := False;
    Invalidate;
    Exit;
  end;

  //...si fem click abans de fechabloque ignorem mouseup actions
  if FClickDatetime < FFechaBloqueo then
   Abort;

    // si estaves fent drag, commit i fora
  if FDragMode = dmResize then
  begin
      CommitResize;
      Exit;
  end;
  if FDragMode = dmMove then
  begin
      CommitMove;
      Exit;
  end;

  // si no hi ha drag: és un click -> selecciona
  if not FDidDrag then
  begin
    {
    nodeIdx := HitTestNodeIndex(X, Y);
    if nodeIdx >= 0 then
      FFocusedNodeIndex := nodeIdx
    else
      FFocusedNodeIndex := -1;
    Invalidate;
    }

    nodeIdx := HitTestNodeIndex(X, Y);
    if nodeIdx >= 0 then
    begin
      if ssCtrl in Shift then
       ToggleNodeIndexSelection(nodeIdx)
      else
       SelectNodeIndex(nodeIdx, True);

      UpdateAutoMarkers;

      if Assigned(FOnNodeSelected) then
        FOnNodeSelected(Self);
    end
    else
    begin
      ClearSelection;
      ClearAutoMarkers;
      Invalidate;

      if Assigned(FOnVoid) then
        FOnVoid(Self);
    end;

    Invalidate;
  end;

end;


// ***** FUNCIONS DE SELECT NODE *********

procedure TGanttControl.ClearSelection;
begin
  FSelectedNodeIndexes.Clear;
  FFocusedNodeIndex := -1;
  Invalidate;
end;


procedure TGanttControl.SelectNodeIndex(
  const AIndex: Integer;
  const AClearPrevious: Boolean = True);
begin
  if (AIndex < 0) or (AIndex >= Length(FNodes)) then
    Exit;

  if AClearPrevious then
    FSelectedNodeIndexes.Clear;

  FSelectedNodeIndexes.AddOrSetValue(AIndex, 1);

  FFocusedNodeIndex := AIndex;

  Invalidate;
end;


procedure TGanttControl.ToggleNodeIndexSelection(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= Length(FNodes)) then
    Exit;

  if FSelectedNodeIndexes.ContainsKey(AIndex) then
  begin
    FSelectedNodeIndexes.Remove(AIndex);

    if FFocusedNodeIndex = AIndex then
      FFocusedNodeIndex := -1;
  end
  else
  begin
    FSelectedNodeIndexes.Add(AIndex, 1);
    FFocusedNodeIndex := AIndex;
  end;

  Invalidate;
end;

function TGanttControl.IsNodeIndexSelected(const AIndex: Integer): Boolean;
begin
  Result := FSelectedNodeIndexes.ContainsKey(AIndex);
end;

function TGanttControl.IsNodeFocused(const AIndex: Integer): Boolean;
begin
  Result := AIndex = FFocusedNodeIndex;
end;

end.

