unit uFiniteCapacityOperaris;

{
  TfrmFiniteCapacityOperaris - Planificador de capacidad finita por OPERARIO.

  Layout estilo Kanban:
  - Panel izquierdo: OT/operaciones pendientes de asignar (cards arrastrables)
    con filtros por operacion / area / departamento / solo capacitados.
  - Panel derecho: una columna por operario, con barra de ocupacion %,
    bloques de ausencia, marca de solapamientos y soporte multi-operario
    (la misma OT puede asignarse a varios operarios; badge X/N).
  - Drag & drop desde pendientes hacia operarios y entre operarios.

  Decisiones de modelo (ver docs/design/FiniteCapacityOperaris.md):
  - Escenario C: paralelismo con MaxOperariosParalelos + FactorParalelismo.
  - Manera B: cada operario asignado consume la duracion entera del bloque.
  - Capacidad % sobre rango configurable (Hoy / Semana / 2 sem / Mes).
  - Capacitacion con Nivel (visual en v1, calculo en v1.1).
  - Lock IsLocked en asignacion.
  - Ausencias en tabla aparte FS_PL_OperatorAbsence.
  - Solapamientos detectados visualmente (no bloquean).
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.Generics.Defaults, System.Math,
  System.DateUtils, System.StrUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls,
  uGanttTypes, uNodeDataRepo, uCustomFieldDefs,
  uOperariosTypes, uOperariosRepo,
  uOperatorAbsencesRepo, uOperationTypesRepo;

type
  // Par (OpId, DataId) usado en multi-seleccion de columnas
  TOpCardRef = record
    OperarioId: Integer;
    DataId: Integer;
  end;

  // Rango temporal mostrado en cabecera
  TFCORange = (frHoy, frSemana, fr2Semanas, frMes);

  // Modo de orden de columnas
  TFCOSortMode = (smNombre, smOcupacion, smDepartamento, smNivel);

  // Resultado para el caller
  TFCOAssignment = record
    OperarioId: Integer;
    DataId: Integer;
    Horas: Double;
    IsLocked: Boolean;
  end;

  TGetNodeTimesFunc = reference to function(const DataId: Integer;
    out AStart, AEnd: TDateTime): Boolean;

  { ----------------------------------------------------------- }
  {  TPendingOpsListControl - lista vertical de OTs pendientes  }
  { ----------------------------------------------------------- }
  TPendingOpsListControl = class(TCustomControl)
  private const
    CARD_H = 78;
    CARD_GAP = 4;
    CARD_MARGIN = 8;
    SBAR_W = 12;
  private
    FNodeRepo: TNodeDataRepo;
    FOperariosRepo: TOperariosRepo;
    FItems: TArray<Integer>;          // DataIds visibles tras filtros
    FAllItems: TArray<Integer>;       // DataIds completos
    FFilterOperacion: string;
    FFilterArticulo: string;          // texto libre: codigo articulo, num OT, descripcion
    FFilterAreaId: Integer;           // -1 = todas
    FFilterDeptId: Integer;           // -1 = todos
    FFilterSoloCapacitados: Boolean;
    FScrollY: Integer;
    FHoverIdx: Integer;
    FDraggingSB: Boolean;
    FSBGrabY: Integer;
    FSBGrabScrollY: Integer;
    FDragIdx: Integer;
    FDragStartPt: TPoint;
    FDragPending: Boolean;
    FOnBeginDrag: TNotifyEvent;
    FDropActive: Boolean;
    FOnDblClickCard: TNotifyEvent;
    FDblClickDataId: Integer;
    FDragGhostBmp: TBitmap;
    FDragActive: Boolean;
    FSelectedSet: TDictionary<Integer, Boolean>;  // DataId -> True
    function IdxAtY(Y: Integer): Integer;
    function MaxScrollY: Integer;
    function IsOnSBar(X: Integer): Boolean;
    procedure DrawCard(const ACanvas: TCanvas; Idx: Integer;
      const R: TRect; IsHover: Boolean);
    procedure DrawSBar(const ACanvas: TCanvas);
    procedure ApplyFilters;
    function IsCardInActiveDrag(DataId: Integer): Boolean;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetData(ANodeRepo: TNodeDataRepo; AOpRepo: TOperariosRepo;
      const AIds: TArray<Integer>);
    procedure SetFilter(const AOperacion: string;
      AAreaId, ADeptId: Integer; ASoloCapacitados: Boolean;
      const AArticulo: string = '');
    function DragDataId: Integer;
    function DragDataIds: TArray<Integer>;
    procedure EndDrag;
    procedure ClearSelection;
    procedure SetDropActive(AActive: Boolean);
    procedure SetDragActive(AActive: Boolean; AGhost: TBitmap = nil);
    function PointIsInside(const ScreenPt: TPoint): Boolean;
    property Items: TArray<Integer> read FItems;
    property OnBeginDrag: TNotifyEvent read FOnBeginDrag write FOnBeginDrag;
    property OnDblClickCard: TNotifyEvent read FOnDblClickCard write FOnDblClickCard;
    property DblClickDataId: Integer read FDblClickDataId;
    property DropActive: Boolean read FDropActive;
  end;

  { ----------------------------------------------------------- }
  {  TOperariColumnsControl - columnas por operario              }
  { ----------------------------------------------------------- }
  TOperariColumnsControl = class(TCustomControl)
  private const
    COL_W = 220;
    COL_GAP = 8;
    HEADER_H = 72;
    CARD_H = 78;
    CARD_GAP = 5;
    CARD_MARGIN = 6;
    SBAR_W = 8;
    HSBAR_H = 12;
    ABS_H = 44;
  private
    FNodeRepo: TNodeDataRepo;
    FOpRepo: TOperariosRepo;
    FAbsRepo: TOperatorAbsencesRepo;
    FTypesRepo: TOperationTypesRepo;
    FOperarios: TArray<TOperario>;    // ordenados, ya filtrados por visibilidad
    FOperariosAll: TArray<TOperario>; // todos antes de filtro de visibilidad
    FVisibleIds: TArray<Integer>;     // si len=0 -> todos visibles
    FRange: TFCORange;
    FSortMode: TFCOSortMode;
    FRangeStart, FRangeEnd: TDateTime;
    FScrollX: Integer;
    FScrollYMap: TDictionary<Integer, Integer>;  // OperarioId -> scrollY
    FHoverOpId: Integer;
    FHoverCardIdx: Integer;
    FHoverOptionsOpId: Integer;
    FOnHeaderOptionsClick: TNotifyEvent;
    FHeaderOptionsClickedOpId: Integer;
    FDropTargetOpId: Integer;
    FDropActive: Boolean;
    FDragOpId: Integer;
    FDragCardIdx: Integer;
    FDragStartPt: TPoint;
    FDragPending: Boolean;
    FOnBeginDrag: TNotifyEvent;
    FRightClickOpId: Integer;
    FRightClickDataId: Integer;
    FRightClickAbsenceId: Integer;
    FOnLockToggle: TNotifyEvent;
    FOnUnassignClick: TNotifyEvent;
    FOnRightClickAbsence: TNotifyEvent;
    // Multi-seleccion: clave = (OpId, DataId) -> True
    FSelectedSet: TDictionary<string, Boolean>;
    // Ghost de la card arrastrada
    FDragGhostBmp: TBitmap;
    FDragGhostDataId: Integer;
    // HScrollbar drag
    FDraggingHSB: Boolean;
    FHSBGrabX: Integer;
    FHSBGrabScrollX: Integer;
    // VScrollbar por columna
    FDraggingVSB: Boolean;
    FVSBOpId: Integer;
    FVSBGrabY: Integer;
    FVSBGrabScrollY: Integer;
    // Doble clic
    FOnDblClickCard: TNotifyEvent;
    FDblClickDataId: Integer;
    function GetCardsForOperario(OpId: Integer): TArray<TAsignacionOperario>;
    function ColScrollY(OpId: Integer): Integer;
    procedure SetColScrollY(OpId, V: Integer);
    function MaxColScrollY(OpId: Integer): Integer;
    function MaxScrollX: Integer;
    function ContentWidth: Integer;
    function CalcOcupacionPct(OpId: Integer; out HrsAsig, HrsDisp: Double): Double;
    function HasOverlap(OpId: Integer): Boolean;
    function NodeIntersectsRange(DataId: Integer): Boolean;
    function ColIdxAtX(X: Integer): Integer;     // indice col vista
    function OperarioAtX(X: Integer): Integer;
    function CardIdxAtPoint(OpId, Y: Integer): Integer;
    function AbsenceOffset(OpId: Integer): Integer;
    function AbsenceIdxAtPoint(OpId, Y: Integer): Integer;
    procedure DrawHeader(const ACanvas: TCanvas; const R: TRect; OpId: Integer);
    procedure DrawCard(const ACanvas: TCanvas; OpId: Integer;
      const Asig: TAsignacionOperario; const R: TRect; IsHover, IsOverlap: Boolean);
    procedure DrawAbsenceBlock(const ACanvas: TCanvas; const R: TRect;
      const Aus: TAusencia);
    procedure DrawColumn(const ACanvas: TCanvas; ColIdx: Integer; CX: Integer);
    procedure SortOperarios;
    procedure ApplyVisibleFilter;
    procedure BuildDragGhost(DataId, OpId: Integer; ExtraCount: Integer = 0);
    procedure ClearDragGhost;
    procedure DrawDragGhost(const ACanvas: TCanvas);
    function SelKey(OpId, DataId: Integer): string;
    function IsSelected(OpId, DataId: Integer): Boolean;
    function IsCardInActiveDrag(OpId, DataId: Integer): Boolean;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
  private
    FOnRightClickCard: TNotifyEvent;
    function HSBThumbRect: TRect;
    function IsOnHSB(const X, Y: Integer): Boolean;
    function VSBThumbRect(OpId, CX: Integer): TRect;
    function IsOnVSB(const X, Y: Integer; out OpId: Integer): Boolean;
    function IsOnOptionsBtn(const X, Y: Integer; out OpId: Integer): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetData(AOpRepo: TOperariosRepo; ANodeRepo: TNodeDataRepo;
      AAbsRepo: TOperatorAbsencesRepo; ATypesRepo: TOperationTypesRepo;
      const AOperarios: TArray<TOperario>);
    procedure SetVisibleIds(const AIds: TArray<Integer>);
    function GetVisibleIds: TArray<Integer>;
    procedure ComputeSummary(out ATotal, AOver, AUnder: Integer; out AAvgPct: Double);
    procedure SetRange(ARange: TFCORange);
    procedure SetSortMode(AMode: TFCOSortMode);
    procedure UpdateDropTarget(const ScreenPt: TPoint);
    procedure ClearDropTarget;
    procedure BeginExternalDrag(DataId: Integer; Count: Integer = 1);
    function GhostBitmap: TBitmap;
    procedure RebuildOrder;
    function DragDataId: Integer;
    function DragOpId: Integer;
    function DragCardRefs: TArray<TOpCardRef>;
    procedure ClearSelection;
    function DropTargetOpId: Integer;
    procedure EndDrag;
    property HoverOpId: Integer read FHoverOpId;
    property RightClickOpId: Integer read FRightClickOpId;
    property RightClickDataId: Integer read FRightClickDataId;
    property RightClickAbsenceId: Integer read FRightClickAbsenceId;
    property OnBeginDrag: TNotifyEvent read FOnBeginDrag write FOnBeginDrag;
    property OnLockToggle: TNotifyEvent read FOnLockToggle write FOnLockToggle;
    property OnUnassignClick: TNotifyEvent read FOnUnassignClick write FOnUnassignClick;
    property OnRightClickCard: TNotifyEvent read FOnRightClickCard write FOnRightClickCard;
    property OnRightClickAbsence: TNotifyEvent read FOnRightClickAbsence write FOnRightClickAbsence;
    property OnDblClickCard: TNotifyEvent read FOnDblClickCard write FOnDblClickCard;
    property DblClickDataId: Integer read FDblClickDataId;
    property OnHeaderOptionsClick: TNotifyEvent read FOnHeaderOptionsClick write FOnHeaderOptionsClick;
    property HeaderOptionsClickedOpId: Integer read FHeaderOptionsClickedOpId;
  end;

  { ----------------------------------------------------------- }
  {  TfrmFiniteCapacityOperaris - form principal                 }
  { ----------------------------------------------------------- }
  TfrmFiniteCapacityOperaris = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    cbRango: TComboBox;
    cbOrden: TComboBox;
    cbFiltroOp: TComboBox;
    chkSoloCapacitados: TCheckBox;
    btnOperariosVisibles: TButton;
    pnlBottom: TPanel;
    lblResumen: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    pnlMain: TPanel;
    pnlPendientes: TPanel;
    pnlPendientesHeader: TPanel;
    lblPendientes: TLabel;
    edFiltroArticulo: TEdit;
    pnlOperarios: TPanel;
    splPanels: TSplitter;
    pmCard: TPopupMenu;
    miLock: TMenuItem;
    miUnassign: TMenuItem;
    pmOperario: TPopupMenu;
    miDesasignarTodo: TMenuItem;
    miOpSep1: TMenuItem;
    miBloquearTodo: TMenuItem;
    miDesbloquearTodo: TMenuItem;
    miOpSep2: TMenuItem;
    miGestionAusencias: TMenuItem;
    miGestionCalendario: TMenuItem;
    pmAbsence: TPopupMenu;
    miQuitarAusencia: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure cbRangoChange(Sender: TObject);
    procedure cbOrdenChange(Sender: TObject);
    procedure cbFiltroOpChange(Sender: TObject);
    procedure chkSoloCapacitadosClick(Sender: TObject);
    procedure miLockClick(Sender: TObject);
    procedure miUnassignClick(Sender: TObject);
    procedure edFiltroArticuloChange(Sender: TObject);
    procedure btnOperariosVisiblesClick(Sender: TObject);
    procedure miDesasignarTodoClick(Sender: TObject);
    procedure miBloquearTodoClick(Sender: TObject);
    procedure miDesbloquearTodoClick(Sender: TObject);
    procedure miGestionAusenciasClick(Sender: TObject);
    procedure miGestionCalendarioClick(Sender: TObject);
    procedure miQuitarAusenciaClick(Sender: TObject);
  private
    FNodeRepo: TNodeDataRepo;
    FOpRepo: TOperariosRepo;
    FAbsRepo: TOperatorAbsencesRepo;
    FTypesRepo: TOperationTypesRepo;
    FCustomFieldDefs: TCustomFieldDefs;
    FOwnsAbsRepo: Boolean;
    FOwnsTypesRepo: Boolean;
    FVisibleOperarioIds: TArray<Integer>;  // si len=0, todos visibles
    FPendingList: TPendingOpsListControl;
    FOperariColumns: TOperariColumnsControl;
    FResult: TArray<TFCOAssignment>;
    FAccepted: Boolean;
    procedure OnPendingBeginDrag(Sender: TObject);
    procedure OnColBeginDrag(Sender: TObject);
    procedure OnColLockToggle(Sender: TObject);
    procedure OnColUnassign(Sender: TObject);
    procedure OnColRightClick(Sender: TObject);
    procedure OnColRightClickAbsence(Sender: TObject);
    procedure OnPendingDblClick(Sender: TObject);
    procedure OnColDblClick(Sender: TObject);
    procedure ShowNodeInspectorById(DataId: Integer);
    procedure UpdatePendingCount;
    procedure UpdateResumen;
    procedure OnHeaderOptionsClick(Sender: TObject);
    procedure ApplicationOnIdle(Sender: TObject; var Done: Boolean);
    procedure FillFiltroOp;
    procedure RefreshAll;
    function CollectPendingDataIds: TArray<Integer>;
    procedure DoAssignFromPending(DataId, OpId: Integer);
    procedure DoMoveAssignment(DataId, FromOpId, ToOpId: Integer);
  public
    class function Execute(
      ANodeRepo: TNodeDataRepo;
      AOpRepo: TOperariosRepo;
      out AAssignments: TArray<TFCOAssignment>;
      AAbsRepo: TOperatorAbsencesRepo = nil;
      ATypesRepo: TOperationTypesRepo = nil;
      ACustomFieldDefs: TCustomFieldDefs = nil): Boolean;
  end;

implementation

uses
  uNodeInspector, uOperariosVisiblesDlg, uOperarioAusencias;

{$R *.dfm}

{ ===================== Helpers ===================== }

function ClampInt(V, Lo, Hi: Integer): Integer;
begin
  if V < Lo then Result := Lo
  else if V > Hi then Result := Hi
  else Result := V;
end;

function NivelLetra(N: TNivelSkill): string;
begin
  case N of
    nsAprendiz: Result := 'A';
    nsJunior:   Result := 'J';
    nsSenior:   Result := 'S';
    nsExperto:  Result := 'E';
  else Result := '?';
  end;
end;

function NivelColor(N: TNivelSkill): TColor;
begin
  case N of
    nsAprendiz: Result := $00808080;  // gris
    nsJunior:   Result := $00C08000;  // azul medio
    nsSenior:   Result := $0040A040;  // verde
    nsExperto:  Result := $004040E0;  // rojo brillante
  else Result := clGray;
  end;
end;

function OcupacionColor(Pct: Double): TColor;
begin
  if Pct < 70 then       Result := $0070C070
  else if Pct < 95 then  Result := $0040B0C0
  else if Pct <= 110 then Result := $000080FF
  else                   Result := $004040E0;  // rojo
end;

procedure DrawLockIcon(const ACanvas: TCanvas; X, Y: Integer; AColor: TColor);
var
  OldPen: TPen;
  OldBrush: TBrush;
begin
  // Cuerpo (rectangulo) + arco superior. Tama'no aprox 14x16.
  OldPen := TPen.Create;
  OldBrush := TBrush.Create;
  try
    OldPen.Assign(ACanvas.Pen);
    OldBrush.Assign(ACanvas.Brush);

    ACanvas.Pen.Color := AColor;
    ACanvas.Pen.Width := 2;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Brush.Style := bsClear;

    // Arco superior (asa)
    ACanvas.Arc(X + 2, Y, X + 12, Y + 10,
                X + 12, Y + 5,
                X + 2, Y + 5);

    // Cuerpo
    ACanvas.Pen.Width := 1;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := AColor;
    ACanvas.RoundRect(X, Y + 6, X + 14, Y + 16, 3, 3);

    // Punto en el centro (ojo de la cerradura)
    ACanvas.Brush.Color := clWhite;
    ACanvas.Pen.Color := clWhite;
    ACanvas.Ellipse(X + 6, Y + 9, X + 9, Y + 12);

    ACanvas.Pen.Assign(OldPen);
    ACanvas.Brush.Assign(OldBrush);
  finally
    OldPen.Free;
    OldBrush.Free;
  end;
end;

function GetRangeBounds(R: TFCORange; out AStart, AEnd: TDateTime): Boolean;
var
  Hoy: TDateTime;
begin
  Hoy := DateOf(Now);
  case R of
    frHoy:
      begin
        AStart := Hoy;
        AEnd := IncDay(Hoy, 1);
      end;
    frSemana:
      begin
        AStart := StartOfTheWeek(Hoy);
        AEnd := IncDay(AStart, 7);
      end;
    fr2Semanas:
      begin
        AStart := StartOfTheWeek(Hoy);
        AEnd := IncDay(AStart, 14);
      end;
    frMes:
      begin
        AStart := StartOfTheMonth(Hoy);
        AEnd := IncMonth(AStart, 1);
      end;
  else
    AStart := Hoy;
    AEnd := IncDay(Hoy, 7);
  end;
  Result := True;
end;

{ ================== TPendingOpsListControl ================== }

constructor TPendingOpsListControl.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  TabStop := True;
  Color := $00FAFAFA;
  FFilterAreaId := -1;
  FFilterDeptId := -1;
  FFilterSoloCapacitados := False;
  FHoverIdx := -1;
  FDragIdx := -1;
  FSelectedSet := TDictionary<Integer, Boolean>.Create;
end;

destructor TPendingOpsListControl.Destroy;
begin
  FSelectedSet.Free;
  inherited;
end;

procedure TPendingOpsListControl.SetData(ANodeRepo: TNodeDataRepo;
  AOpRepo: TOperariosRepo; const AIds: TArray<Integer>);
begin
  FNodeRepo := ANodeRepo;
  FOperariosRepo := AOpRepo;
  FAllItems := Copy(AIds, 0, Length(AIds));
  ApplyFilters;
  Invalidate;
end;

procedure TPendingOpsListControl.SetFilter(const AOperacion: string;
  AAreaId, ADeptId: Integer; ASoloCapacitados: Boolean;
  const AArticulo: string);
begin
  FFilterOperacion := AOperacion;
  FFilterArticulo := AArticulo;
  FFilterAreaId := AAreaId;
  FFilterDeptId := ADeptId;
  FFilterSoloCapacitados := ASoloCapacitados;
  ApplyFilters;
  Invalidate;
end;

procedure TPendingOpsListControl.ApplyFilters;
var
  L: TList<Integer>;
  I: Integer;
  D: TNodeData;
  Pasa: Boolean;
  Ops: TArray<TOperario>;
  J: Integer;
  AlguienCapacitado: Boolean;
begin
  L := TList<Integer>.Create;
  try
    if Assigned(FOperariosRepo) then
      Ops := FOperariosRepo.GetOperarios
    else
      SetLength(Ops, 0);

    for I := 0 to High(FAllItems) do
    begin
      if not Assigned(FNodeRepo) then Continue;
      if not FNodeRepo.TryGetById(FAllItems[I], D) then Continue;
      Pasa := True;

      if (FFilterOperacion <> '') and not SameText(FFilterOperacion, D.Operacion) then
        Pasa := False;

      // Filtro libre por articulo / OT / descripcion
      if Pasa and (FFilterArticulo <> '') then
      begin
        if (Pos(UpperCase(FFilterArticulo), UpperCase(D.CodigoArticulo)) = 0) and
           (Pos(UpperCase(FFilterArticulo), UpperCase(D.DescripcionArticulo)) = 0) and
           (Pos(UpperCase(FFilterArticulo), UpperCase(D.NumeroTrabajo)) = 0) and
           (Pos(UpperCase(FFilterArticulo), UpperCase(IntToStr(D.NumeroOrdenFabricacion))) = 0) then
          Pasa := False;
      end;

      // Filtro solo capacitados: alguien (operario activo del repo) puede hacer la operacion
      if Pasa and FFilterSoloCapacitados and Assigned(FOperariosRepo) then
      begin
        AlguienCapacitado := False;
        for J := 0 to High(Ops) do
          if FOperariosRepo.OperarioPotFerOperacio(Ops[J].Id, D.Operacion) then
          begin
            AlguienCapacitado := True;
            Break;
          end;
        if not AlguienCapacitado then Pasa := False;
      end;

      // Area / Dept: pendientes de implementar cuando exista lookup nodo->area/dept
      if Pasa then L.Add(FAllItems[I]);
    end;
    FItems := L.ToArray;
  finally
    L.Free;
  end;
  if FScrollY > MaxScrollY then FScrollY := MaxScrollY;
  if FScrollY < 0 then FScrollY := 0;
end;

function TPendingOpsListControl.IdxAtY(Y: Integer): Integer;
var
  RealY: Integer;
begin
  RealY := Y + FScrollY - CARD_MARGIN;
  if RealY < 0 then Exit(-1);
  Result := RealY div (CARD_H + CARD_GAP);
  if (Result < 0) or (Result >= Length(FItems)) then Result := -1;
end;

function TPendingOpsListControl.MaxScrollY: Integer;
var
  Total: Integer;
begin
  Total := Length(FItems) * (CARD_H + CARD_GAP) + CARD_MARGIN * 2;
  Result := Max(0, Total - ClientHeight);
end;

function TPendingOpsListControl.IsOnSBar(X: Integer): Boolean;
begin
  Result := (X >= ClientWidth - SBAR_W) and (MaxScrollY > 0);
end;

procedure TPendingOpsListControl.DrawCard(const ACanvas: TCanvas; Idx: Integer;
  const R: TRect; IsHover: Boolean);
var
  D: TNodeData;
  S: string;
  Asig: TArray<TAsignacionOperario>;
  N, Nec: Integer;
begin
  if not Assigned(FNodeRepo) or not FNodeRepo.TryGetById(FItems[Idx], D) then Exit;

  // Sombra Trello-style
  ACanvas.Pen.Style := psClear;
  ACanvas.Brush.Color := $00DCDCDC;
  ACanvas.RoundRect(R.Left + 1, R.Top + 2, R.Right + 1, R.Bottom + 2, 8, 8);
  ACanvas.Pen.Style := psSolid;

  // Card seleccionada (multi-select): borde naranja
  if FSelectedSet.ContainsKey(FItems[Idx]) then
  begin
    ACanvas.Brush.Color := $00E8F4FF;
    ACanvas.Pen.Color := $00E89040;
    ACanvas.Pen.Width := 2;
  end
  else if IsHover then
  begin
    ACanvas.Brush.Color := $00FFF8E8;
    ACanvas.Pen.Color := $00E89040;
    ACanvas.Pen.Width := 2;
  end
  else
  begin
    ACanvas.Brush.Color := clWhite;
    ACanvas.Pen.Color := $00E0E0E0;
    ACanvas.Pen.Width := 1;
  end;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
  ACanvas.Pen.Width := 1;

  // Barra de prioridad a la izquierda
  case D.Prioridad of
    1: ACanvas.Brush.Color := $004040FF;
    2: ACanvas.Brush.Color := $000080FF;
    3: ACanvas.Brush.Color := $00FF8000;
  else
    ACanvas.Brush.Color := $00B0B0B0;
  end;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(R.Left, R.Top + 2, R.Left + 5, R.Bottom - 2, 3, 3);
  ACanvas.Pen.Style := psSolid;

  // Caption
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Color := $00303030;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Size := 9;
  if D.NumeroTrabajo <> '' then
    S := D.NumeroTrabajo
  else if D.NumeroOrdenFabricacion > 0 then
    S := Format('OF-%d', [D.NumeroOrdenFabricacion])
  else
    S := Format('Nodo-%d', [FItems[Idx]]);
  ACanvas.TextOut(R.Left + 12, R.Top + 6, S);

  // Operacion
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := $00606060;
  ACanvas.Font.Size := 8;
  ACanvas.TextOut(R.Left + 12, R.Top + 24, D.Operacion);

  // Necesarios / asignados
  if Assigned(FOperariosRepo) then
  begin
    Asig := FOperariosRepo.GetAsignacionsByNode(FItems[Idx]);
    N := Length(Asig);
  end
  else N := 0;
  Nec := Max(D.OperariosNecesarios, 1);
  S := Format('%d/%d operarios', [N, Nec]);
  ACanvas.Font.Color := IfThen(N >= Nec, $0040A040, $004040E0);
  ACanvas.TextOut(R.Left + 12, R.Top + 40, S);

  // Duracion
  if D.DurationMin > 0 then
  begin
    ACanvas.Font.Color := $00808080;
    S := Format('%.1f h', [D.DurationMin / 60]);
    ACanvas.TextOut(R.Left + 12, R.Top + 56, S);
  end;

  ACanvas.Brush.Style := bsSolid;
end;

procedure TPendingOpsListControl.DrawSBar(const ACanvas: TCanvas);
var
  Total, ThumbH, ThumbY: Integer;
begin
  if MaxScrollY <= 0 then Exit;
  Total := MaxScrollY + ClientHeight;
  if Total <= 0 then Exit;
  ThumbH := Max(20, MulDiv(ClientHeight, ClientHeight, Total));
  ThumbY := MulDiv(ClientHeight - ThumbH, FScrollY, MaxScrollY);
  ACanvas.Brush.Color := $00E0E0E0;
  ACanvas.FillRect(Rect(ClientWidth - SBAR_W, 0, ClientWidth, ClientHeight));
  ACanvas.Brush.Color := $00A0A0A0;
  ACanvas.FillRect(Rect(ClientWidth - SBAR_W + 2, ThumbY,
    ClientWidth - 2, ThumbY + ThumbH));
end;

procedure TPendingOpsListControl.Paint;
var
  I, Y: Integer;
  R: TRect;
begin
  Canvas.Font.Quality := fqClearTypeNatural;
  if FDropActive then
    Canvas.Brush.Color := $00D8F0FF
  else
    Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  Y := CARD_MARGIN - FScrollY;
  for I := 0 to High(FItems) do
  begin
    if (Y + CARD_H >= 0) and (Y <= ClientHeight) then
    begin
      R := Rect(CARD_MARGIN, Y, ClientWidth - SBAR_W - CARD_MARGIN, Y + CARD_H);
      // Si esta card forma parte del drag activo, pintar placeholder vacio
      if FDragPending = False then  // ya hay drag confirmado (post threshold)
        if (FDragIdx >= 0) and IsCardInActiveDrag(FItems[I]) then
        begin
          Canvas.Brush.Color := $00F0F0F0;
          Canvas.Pen.Color := $00C0C0C0;
          Canvas.Pen.Style := psDot;
          Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
          Canvas.Pen.Style := psSolid;
          Inc(Y, CARD_H + CARD_GAP);
          Continue;
        end;
      DrawCard(Canvas, I, R, I = FHoverIdx);
    end;
    Inc(Y, CARD_H + CARD_GAP);
  end;
  if FDropActive then
  begin
    Canvas.Pen.Color := $004080FF;
    Canvas.Pen.Width := 2;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(0, 0, ClientWidth, ClientHeight);
    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsSolid;
  end;
  DrawSBar(Canvas);

  // Ghost del drag activo cuando el cursor sobrevuela este panel
  if FDragActive and Assigned(FDragGhostBmp) then
  begin
    var Pt := ScreenToClient(Mouse.CursorPos);
    if PtInRect(ClientRect, Pt) then
    begin
      var GhostW := FDragGhostBmp.Width;
      var GhostH := FDragGhostBmp.Height;
      var BF: TBlendFunction;
      BF.BlendOp := AC_SRC_OVER;
      BF.BlendFlags := 0;
      BF.SourceConstantAlpha := 200;
      BF.AlphaFormat := 0;
      Winapi.Windows.AlphaBlend(
        Canvas.Handle, Pt.X - GhostW div 2, Pt.Y - GhostH div 2,
        GhostW, GhostH,
        FDragGhostBmp.Canvas.Handle, 0, 0, GhostW, GhostH, BF);
    end;
  end;
end;

procedure TPendingOpsListControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft) and IsOnSBar(X) then
  begin
    FDraggingSB := True;
    FSBGrabY := Y;
    FSBGrabScrollY := FScrollY;
    Exit;
  end;
  if Button <> mbLeft then Exit;

  // No iniciar drag en doble clic
  if ssDouble in Shift then Exit;

  FDragIdx := IdxAtY(Y);
  if FDragIdx >= 0 then
  begin
    var ClickedId := FItems[FDragIdx];

    if ssCtrl in Shift then
    begin
      // Toggle seleccion
      if FSelectedSet.ContainsKey(ClickedId) then
        FSelectedSet.Remove(ClickedId)
      else
        FSelectedSet.Add(ClickedId, True);
      Invalidate;
    end
    else
    begin
      // Sin Ctrl: si no esta seleccionado, limpiar y seleccionar solo este
      if not FSelectedSet.ContainsKey(ClickedId) then
      begin
        FSelectedSet.Clear;
        FSelectedSet.Add(ClickedId, True);
        Invalidate;
      end;
    end;

    FDragStartPt := Point(X, Y);
    FDragPending := True;
    MouseCapture := True;
  end
  else
  begin
    // Click en zona vacia: limpiar seleccion (solo si no Ctrl)
    if not (ssCtrl in Shift) then
    begin
      if FSelectedSet.Count > 0 then
      begin
        FSelectedSet.Clear;
        Invalidate;
      end;
    end;
  end;
end;

procedure TPendingOpsListControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewIdx, Range, Total: Integer;
begin
  inherited;
  if FDraggingSB then
  begin
    Range := MaxScrollY;
    Total := MaxScrollY + ClientHeight;
    if Total > 0 then
      FScrollY := ClampInt(FSBGrabScrollY +
        MulDiv(Y - FSBGrabY, Total, ClientHeight), 0, Range);
    Invalidate;
    Exit;
  end;

  if FDragPending and (Abs(X - FDragStartPt.X) + Abs(Y - FDragStartPt.Y) > 6) then
  begin
    FDragPending := False;
    if Assigned(FOnBeginDrag) then FOnBeginDrag(Self);
  end;

  NewIdx := IdxAtY(Y);
  if NewIdx <> FHoverIdx then
  begin
    FHoverIdx := NewIdx;
    Invalidate;
  end;
end;

procedure TPendingOpsListControl.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  MouseCapture := False;
  FDraggingSB := False;
  // Si el drag estaba pendiente y nunca paso del threshold, era click simple:
  // limpiamos para que OnIdle no procese un drop falso.
  if FDragPending then
  begin
    FDragPending := False;
    FDragIdx := -1;
  end;
  // El reset de FDragIdx tras drag real lo hace ApplicationOnIdle del form.
end;

function TPendingOpsListControl.DoMouseWheel(Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  FScrollY := ClampInt(FScrollY - (WheelDelta div 4), 0, MaxScrollY);
  Invalidate;
  Result := True;
end;

function TPendingOpsListControl.DragDataId: Integer;
begin
  if (FDragIdx >= 0) and (FDragIdx < Length(FItems)) then
    Result := FItems[FDragIdx]
  else
    Result := 0;
end;

function TPendingOpsListControl.IsCardInActiveDrag(DataId: Integer): Boolean;
begin
  // No hay drag activo si no se ha pasado el threshold
  if FDragIdx < 0 then Exit(False);
  // Si es la card que se arrastra
  if (FDragIdx < Length(FItems)) and (FItems[FDragIdx] = DataId) then
    Exit(True);
  // O si forma parte de la seleccion multiple
  Result := FSelectedSet.ContainsKey(DataId) and
    (FDragIdx < Length(FItems)) and
    FSelectedSet.ContainsKey(FItems[FDragIdx]);
end;

function TPendingOpsListControl.DragDataIds: TArray<Integer>;
var
  L: TList<Integer>;
  Id, Curr: Integer;
begin
  L := TList<Integer>.Create;
  try
    Curr := DragDataId;
    if Curr <= 0 then Exit(nil);
    // Si la card arrastrada esta en seleccion, devolver toda la seleccion.
    // Si no, devolver solo la card arrastrada.
    if FSelectedSet.ContainsKey(Curr) then
    begin
      for Id in FSelectedSet.Keys do
        L.Add(Id);
    end
    else
      L.Add(Curr);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TPendingOpsListControl.EndDrag;
begin
  FDragIdx := -1;
  FDragPending := False;
  // NOTA: la seleccion no se limpia aqui. Solo se limpia tras un drop real
  // (lo hace ClearSelection desde el form cuando procesa el drop).
end;

procedure TPendingOpsListControl.ClearSelection;
begin
  if FSelectedSet.Count > 0 then
  begin
    FSelectedSet.Clear;
    Invalidate;
  end;
end;

procedure TPendingOpsListControl.SetDropActive(AActive: Boolean);
begin
  if FDropActive <> AActive then
  begin
    FDropActive := AActive;
    Invalidate;
  end;
end;

procedure TPendingOpsListControl.SetDragActive(AActive: Boolean; AGhost: TBitmap);
begin
  // Recibimos puntero al bitmap del control de columnas (sin owning).
  FDragActive := AActive;
  FDragGhostBmp := AGhost;
  Invalidate;
end;

function TPendingOpsListControl.PointIsInside(const ScreenPt: TPoint): Boolean;
var
  Pt: TPoint;
begin
  Pt := ScreenToClient(ScreenPt);
  Result := PtInRect(ClientRect, Pt);
end;

procedure TPendingOpsListControl.DblClick;
var
  Pt: TPoint;
  Idx: Integer;
begin
  inherited;
  Pt := ScreenToClient(Mouse.CursorPos);
  Idx := IdxAtY(Pt.Y);
  if (Idx >= 0) and (Idx < Length(FItems)) then
  begin
    FDblClickDataId := FItems[Idx];
    if Assigned(FOnDblClickCard) then FOnDblClickCard(Self);
  end;
end;

{ ================== TOperariColumnsControl ================== }

constructor TOperariColumnsControl.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  Color := $00F4F4F4;
  FRange := frSemana;
  FSortMode := smNombre;
  FScrollYMap := TDictionary<Integer, Integer>.Create;
  FSelectedSet := TDictionary<string, Boolean>.Create;
  FHoverOpId := -1;
  FHoverCardIdx := -1;
  FDropTargetOpId := -1;
  FDragOpId := -1;
  FDragCardIdx := -1;
  FRightClickOpId := -1;
  FRightClickDataId := 0;
  FRightClickAbsenceId := 0;
  GetRangeBounds(FRange, FRangeStart, FRangeEnd);
end;

destructor TOperariColumnsControl.Destroy;
begin
  ClearDragGhost;
  FSelectedSet.Free;
  FScrollYMap.Free;
  inherited;
end;

procedure TOperariColumnsControl.SetData(AOpRepo: TOperariosRepo;
  ANodeRepo: TNodeDataRepo; AAbsRepo: TOperatorAbsencesRepo;
  ATypesRepo: TOperationTypesRepo; const AOperarios: TArray<TOperario>);
begin
  FOpRepo := AOpRepo;
  FNodeRepo := ANodeRepo;
  FAbsRepo := AAbsRepo;
  FTypesRepo := ATypesRepo;
  FOperariosAll := Copy(AOperarios, 0, Length(AOperarios));
  ApplyVisibleFilter;
  SortOperarios;
  Invalidate;
end;

procedure TOperariColumnsControl.SetVisibleIds(const AIds: TArray<Integer>);
begin
  FVisibleIds := Copy(AIds, 0, Length(AIds));
  ApplyVisibleFilter;
  SortOperarios;
  Invalidate;
end;

procedure TOperariColumnsControl.ComputeSummary(
  out ATotal, AOver, AUnder: Integer; out AAvgPct: Double);
var
  I: Integer;
  Pct, HA, HD, Sum: Double;
begin
  ATotal := Length(FOperarios);
  AOver := 0;
  AUnder := 0;
  AAvgPct := 0;
  Sum := 0;
  for I := 0 to High(FOperarios) do
  begin
    Pct := CalcOcupacionPct(FOperarios[I].Id, HA, HD);
    Sum := Sum + Pct;
    if Pct > 100 then Inc(AOver)
    else if Pct < 70 then Inc(AUnder);
  end;
  if ATotal > 0 then AAvgPct := Sum / ATotal;
end;

function TOperariColumnsControl.GetVisibleIds: TArray<Integer>;
var
  L: TList<Integer>;
  I: Integer;
begin
  // Si no hay filtro, devuelve los IDs reales actuales
  L := TList<Integer>.Create;
  try
    for I := 0 to High(FOperarios) do
      L.Add(FOperarios[I].Id);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TOperariColumnsControl.SetRange(ARange: TFCORange);
begin
  FRange := ARange;
  GetRangeBounds(FRange, FRangeStart, FRangeEnd);
  Invalidate;
end;

procedure TOperariColumnsControl.SetSortMode(AMode: TFCOSortMode);
begin
  FSortMode := AMode;
  SortOperarios;
  Invalidate;
end;

procedure TOperariColumnsControl.RebuildOrder;
begin
  SortOperarios;
  Invalidate;
end;

procedure TOperariColumnsControl.ApplyVisibleFilter;
var
  L: TList<TOperario>;
  I, J: Integer;
  Visible: Boolean;
begin
  L := TList<TOperario>.Create;
  try
    for I := 0 to High(FOperariosAll) do
    begin
      if Length(FVisibleIds) = 0 then
        Visible := True
      else
      begin
        Visible := False;
        for J := 0 to High(FVisibleIds) do
          if FVisibleIds[J] = FOperariosAll[I].Id then
          begin
            Visible := True;
            Break;
          end;
      end;
      if Visible then L.Add(FOperariosAll[I]);
    end;
    FOperarios := L.ToArray;
  finally
    L.Free;
  end;
end;

function TOperariColumnsControl.SelKey(OpId, DataId: Integer): string;
begin
  Result := IntToStr(OpId) + '-' + IntToStr(DataId);
end;

function TOperariColumnsControl.IsSelected(OpId, DataId: Integer): Boolean;
begin
  Result := FSelectedSet.ContainsKey(SelKey(OpId, DataId));
end;

function TOperariColumnsControl.IsCardInActiveDrag(OpId, DataId: Integer): Boolean;
begin
  // Solo durante drag confirmado (post threshold)
  if FDragPending or (FDragOpId <= 0) then Exit(False);
  // Card origen del drag
  if (FDragOpId = OpId) and (DragDataId = DataId) then Exit(True);
  // O parte de la seleccion multiple cuando la card arrastrada tambien lo esta
  Result := IsSelected(OpId, DataId) and
    IsSelected(FDragOpId, DragDataId);
end;

procedure TOperariColumnsControl.BuildDragGhost(DataId, OpId: Integer; ExtraCount: Integer);
var
  D: TNodeData;
  GhostW, GhostH: Integer;
  R: TRect;
  Asig: TAsignacionOperario;
  Asigs: TArray<TAsignacionOperario>;
  I: Integer;
  BadgeStr: string;
  BW: Integer;
begin
  ClearDragGhost;
  if not Assigned(FNodeRepo) or not FNodeRepo.TryGetById(DataId, D) then Exit;

  // Reconstruir asignacion para pintar la card identica
  FillChar(Asig, SizeOf(Asig), 0);
  Asig.DataId := DataId;
  Asig.OperarioId := OpId;
  if Assigned(FOpRepo) then
  begin
    Asigs := FOpRepo.GetAsignacionsByNode(DataId);
    for I := 0 to High(Asigs) do
      if Asigs[I].OperarioId = OpId then
      begin
        Asig := Asigs[I];
        Break;
      end;
  end;
  if Asig.Horas <= 0 then
    Asig.Horas := D.DurationMin / 60;

  GhostW := COL_W - CARD_MARGIN * 2 - SBAR_W;
  GhostH := CARD_H;

  FDragGhostBmp := TBitmap.Create;
  FDragGhostBmp.PixelFormat := pf32bit;
  FDragGhostBmp.SetSize(GhostW + 4, GhostH + 4);
  FDragGhostBmp.Canvas.Font.Quality := fqClearTypeNatural;
  FDragGhostBmp.Canvas.Brush.Color := $00FFFFFF;
  FDragGhostBmp.Canvas.FillRect(Rect(0, 0, GhostW + 4, GhostH + 4));
  R := Rect(2, 2, GhostW + 2, GhostH + 2);
  DrawCard(FDragGhostBmp.Canvas, OpId, Asig, R, False, False);

  // Badge "+N" si hay multi-seleccion
  if ExtraCount > 1 then
  begin
    BadgeStr := IntToStr(ExtraCount);
    FDragGhostBmp.Canvas.Font.Size := 10;
    FDragGhostBmp.Canvas.Font.Style := [fsBold];
    BW := Max(28, FDragGhostBmp.Canvas.TextWidth(BadgeStr) + 16);
    FDragGhostBmp.Canvas.Pen.Style := psClear;
    FDragGhostBmp.Canvas.Brush.Color := $00404040;
    FDragGhostBmp.Canvas.RoundRect(
      R.Right - BW - 2, R.Top - 4,
      R.Right + 2, R.Top + 16, 8, 8);
    FDragGhostBmp.Canvas.Pen.Style := psSolid;
    FDragGhostBmp.Canvas.Brush.Style := bsClear;
    FDragGhostBmp.Canvas.Font.Color := clWhite;
    FDragGhostBmp.Canvas.TextOut(
      R.Right - BW - 2 + (BW - FDragGhostBmp.Canvas.TextWidth(BadgeStr)) div 2,
      R.Top - 2,
      BadgeStr);
  end;

  FDragGhostDataId := DataId;
end;

procedure TOperariColumnsControl.ClearDragGhost;
begin
  if Assigned(FDragGhostBmp) then
    FreeAndNil(FDragGhostBmp);
  FDragGhostDataId := 0;
end;

procedure TOperariColumnsControl.DrawDragGhost(const ACanvas: TCanvas);
var
  Pt: TPoint;
  GhostW, GhostH, DestX, DestY: Integer;
  BF: TBlendFunction;
begin
  if not Assigned(FDragGhostBmp) then Exit;
  Pt := ScreenToClient(Mouse.CursorPos);
  GhostW := FDragGhostBmp.Width;
  GhostH := FDragGhostBmp.Height;
  DestX := Pt.X - GhostW div 2;
  DestY := Pt.Y - GhostH div 2;
  BF.BlendOp := AC_SRC_OVER;
  BF.BlendFlags := 0;
  BF.SourceConstantAlpha := 200;  // ~78%
  BF.AlphaFormat := 0;
  Winapi.Windows.AlphaBlend(
    ACanvas.Handle, DestX, DestY, GhostW, GhostH,
    FDragGhostBmp.Canvas.Handle, 0, 0, GhostW, GhostH, BF);
end;

procedure TOperariColumnsControl.SortOperarios;
var
  Arr: TArray<TOperario>;
begin
  Arr := Copy(FOperarios, 0, Length(FOperarios));
  case FSortMode of
    smNombre:
      TArray.Sort<TOperario>(Arr, TComparer<TOperario>.Construct(
        function(const L, R: TOperario): Integer
        begin
          Result := CompareText(L.Nombre, R.Nombre);
        end));
    smOcupacion:
      TArray.Sort<TOperario>(Arr, TComparer<TOperario>.Construct(
        function(const L, R: TOperario): Integer
        var
          PL, PR, HA, HD: Double;
        begin
          PL := CalcOcupacionPct(L.Id, HA, HD);
          PR := CalcOcupacionPct(R.Id, HA, HD);
          if PL > PR then Result := -1
          else if PL < PR then Result := 1
          else Result := CompareText(L.Nombre, R.Nombre);
        end));
    smDepartamento:
      TArray.Sort<TOperario>(Arr, TComparer<TOperario>.Construct(
        function(const L, R: TOperario): Integer
        var
          DL, DR: TArray<TDepartamento>;
          NL, NR: string;
        begin
          DL := nil; DR := nil;
          if Assigned(FOpRepo) then
          begin
            DL := FOpRepo.GetDeptsByOperario(L.Id);
            DR := FOpRepo.GetDeptsByOperario(R.Id);
          end;
          if Length(DL) > 0 then NL := DL[0].Nombre else NL := '';
          if Length(DR) > 0 then NR := DR[0].Nombre else NR := '';
          Result := CompareText(NL, NR);
          if Result = 0 then Result := CompareText(L.Nombre, R.Nombre);
        end));
    smNivel:
      ;  // sin orden global por nivel; cada operario tiene varios skills
  end;
  FOperarios := Arr;
end;

function TOperariColumnsControl.GetCardsForOperario(
  OpId: Integer): TArray<TAsignacionOperario>;
begin
  if not Assigned(FOpRepo) then Exit(nil);
  Result := FOpRepo.GetAsignacionsByOperario(OpId);
end;

function TOperariColumnsControl.NodeIntersectsRange(DataId: Integer): Boolean;
begin
  // v1: TNodeData no contiene fechas (estan en FS_PL_Node tabla DB).
  // Asumimos que toda asignacion entra dentro del rango. Cuando se cargue
  // FechaInicio/FechaFin en TNodeData (o se consulte DB), refinar aqui.
  Result := True;
end;

function TOperariColumnsControl.CalcOcupacionPct(OpId: Integer;
  out HrsAsig, HrsDisp: Double): Double;
var
  Asigs: TArray<TAsignacionOperario>;
  I: Integer;
  HoursAbs: Double;
  RangeHrs: Double;
begin
  HrsAsig := 0;
  HrsDisp := 0;

  if not Assigned(FOpRepo) then Exit(0);

  // v1: sumamos las horas declaradas en cada asignacion (sin filtro temporal
  // del nodo). Ver project_finite_capacity_operaris_pending: anyadir filtro
  // por FechaInicio/FechaFin del nodo cuando esten disponibles en TNodeData.
  Asigs := FOpRepo.GetAsignacionsByOperario(OpId);
  for I := 0 to High(Asigs) do
    HrsAsig := HrsAsig + Asigs[I].Horas;

  // Horas disponibles: por simplicidad v1, calendario standard 8h/dia laboral
  // (en v1.1 leer FS_PL_Calendar real del operario)
  RangeHrs := (FRangeEnd - FRangeStart) * 8;  // 8h/dia
  if Assigned(FAbsRepo) then
    HoursAbs := FAbsRepo.HoursOverlapping(OpId, FRangeStart, FRangeEnd) * (8/24)
  else
    HoursAbs := 0;
  HrsDisp := Max(0, RangeHrs - HoursAbs);

  if HrsDisp > 0 then
    Result := (HrsAsig / HrsDisp) * 100
  else if HrsAsig > 0 then
    Result := 999
  else
    Result := 0;
end;

function TOperariColumnsControl.HasOverlap(OpId: Integer): Boolean;
begin
  // v1: sin fechas en TNodeData no podemos detectar solapamiento real.
  // Pendiente para v1.1 cuando carguemos FechaInicio/FechaFin del nodo.
  Result := False;
end;

function TOperariColumnsControl.ColScrollY(OpId: Integer): Integer;
begin
  if not FScrollYMap.TryGetValue(OpId, Result) then Result := 0;
end;

procedure TOperariColumnsControl.SetColScrollY(OpId, V: Integer);
begin
  FScrollYMap.AddOrSetValue(OpId, V);
end;

function TOperariColumnsControl.MaxColScrollY(OpId: Integer): Integer;
var
  N, Total: Integer;
begin
  N := Length(GetCardsForOperario(OpId));
  Total := AbsenceOffset(OpId) + N * (CARD_H + CARD_GAP) + CARD_MARGIN * 2;
  Result := Max(0, Total - (ClientHeight - HEADER_H - HSBAR_H));
end;

function TOperariColumnsControl.ContentWidth: Integer;
begin
  Result := Length(FOperarios) * (COL_W + COL_GAP) + COL_GAP;
end;

function TOperariColumnsControl.MaxScrollX: Integer;
begin
  Result := Max(0, ContentWidth - ClientWidth);
end;

function TOperariColumnsControl.ColIdxAtX(X: Integer): Integer;
var
  RealX: Integer;
begin
  RealX := X + FScrollX - COL_GAP;
  if RealX < 0 then Exit(-1);
  Result := RealX div (COL_W + COL_GAP);
  if (Result < 0) or (Result >= Length(FOperarios)) then Result := -1;
end;

function TOperariColumnsControl.OperarioAtX(X: Integer): Integer;
var
  Idx: Integer;
begin
  Idx := ColIdxAtX(X);
  if Idx < 0 then Result := -1
  else Result := FOperarios[Idx].Id;
end;

function TOperariColumnsControl.AbsenceOffset(OpId: Integer): Integer;
var
  Aus: TArray<TAusencia>;
begin
  Result := 0;
  if not Assigned(FAbsRepo) then Exit;
  Aus := FAbsRepo.GetByOperarioInRange(OpId, FRangeStart, IncDay(FRangeEnd, 60));
  if Length(Aus) > 0 then
    Result := Length(Aus) * (ABS_H + CARD_GAP);
end;

function TOperariColumnsControl.AbsenceIdxAtPoint(OpId, Y: Integer): Integer;
var
  RealY: Integer;
  Aus: TArray<TAusencia>;
begin
  Result := -1;
  if not Assigned(FAbsRepo) then Exit;
  Aus := FAbsRepo.GetByOperarioInRange(OpId, FRangeStart, IncDay(FRangeEnd, 60));
  if Length(Aus) = 0 then Exit;
  RealY := Y - HEADER_H - CARD_MARGIN + ColScrollY(OpId);
  if RealY < 0 then Exit;
  Result := RealY div (ABS_H + CARD_GAP);
  if (Result < 0) or (Result >= Length(Aus)) then Result := -1;
end;

function TOperariColumnsControl.CardIdxAtPoint(OpId, Y: Integer): Integer;
var
  RealY: Integer;
  Cards: TArray<TAsignacionOperario>;
begin
  Cards := GetCardsForOperario(OpId);
  // RealY = posicion en el flujo de cards descontando: header, margen,
  // bloques de ausencia y aplicando scroll vertical.
  RealY := Y - HEADER_H - CARD_MARGIN - AbsenceOffset(OpId) + ColScrollY(OpId);
  if RealY < 0 then Exit(-1);
  Result := RealY div (CARD_H + CARD_GAP);
  if (Result < 0) or (Result >= Length(Cards)) then Result := -1;
end;

procedure TOperariColumnsControl.DrawHeader(const ACanvas: TCanvas;
  const R: TRect; OpId: Integer);
var
  Op: TOperario;
  HrsA, HrsD, Pct: Double;
  S, BadgeStr: string;
  BarW, N, BadgeW: Integer;
  Caps: TArray<string>;
  HighestN: TNivelSkill;
  Cap: TCapacitacion;
  I: Integer;
begin
  if not Assigned(FOpRepo) or not FOpRepo.GetOperarioById(OpId, Op) then Exit;

  // El fondo redondeado lo pinta DrawColumn (que envuelve la columna entera).
  // Aqui solo dibujamos contenido de la cabecera dentro de R.

  ACanvas.Brush.Style := bsClear;

  // Nivel mas alto del operario (badge redondeado)
  HighestN := nsAprendiz;
  if Assigned(FOpRepo) then
  begin
    Caps := FOpRepo.GetCapacitacionsByOperario(OpId);
    for I := 0 to High(Caps) do
      if FOpRepo.GetCapacitacioInfo(OpId, Caps[I], Cap) then
        if Cap.Nivel > HighestN then HighestN := Cap.Nivel;
  end;
  ACanvas.Pen.Style := psClear;
  ACanvas.Brush.Color := NivelColor(HighestN);
  ACanvas.RoundRect(R.Left + 8, R.Top + 8, R.Left + 26, R.Top + 26, 4, 4);
  ACanvas.Pen.Style := psSolid;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Color := clWhite;
  ACanvas.Font.Size := 9;
  ACanvas.Font.Style := [fsBold];
  ACanvas.TextOut(R.Left + 13, R.Top + 9, NivelLetra(HighestN));

  // Nombre
  ACanvas.Font.Color := $00303030;
  ACanvas.Font.Size := 10;
  ACanvas.Font.Style := [fsBold];
  ACanvas.TextOut(R.Left + 32, R.Top + 10, Op.Nombre);

  // Badge "[N]" con numero de cards asignadas (mismo tama'no que el badge nivel: 18x18)
  N := Length(GetCardsForOperario(OpId));
  if N > 0 then
  begin
    BadgeStr := IntToStr(N);
    ACanvas.Font.Size := 9;
    ACanvas.Font.Style := [fsBold];
    BadgeW := Max(18, ACanvas.TextWidth(BadgeStr) + 10);
    ACanvas.Pen.Style := psClear;
    ACanvas.Brush.Color := $00B86848;  // azul corporativo
    ACanvas.RoundRect(
      R.Right - 32 - BadgeW, R.Top + 8,
      R.Right - 32, R.Top + 26, 4, 4);
    ACanvas.Pen.Style := psSolid;
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color := clWhite;
    ACanvas.TextOut(
      R.Right - 32 - BadgeW + (BadgeW - ACanvas.TextWidth(BadgeStr)) div 2,
      R.Top + 9,
      BadgeStr);
  end;

  // Boton "..." en esquina superior derecha
  ACanvas.Font.Size := 12;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := IfThen(FHoverOptionsOpId = OpId, $00404040, $00888888);
  ACanvas.TextOut(R.Right - 24, R.Top + 4, '...');

  // Solapamientos (icono !)
  if HasOverlap(OpId) then
  begin
    ACanvas.Font.Color := $004040E0;
    ACanvas.Font.Size := 11;
    ACanvas.TextOut(R.Right - 24, R.Top + 24, '!');
  end;

  // Ocupacion
  Pct := CalcOcupacionPct(OpId, HrsA, HrsD);
  S := Format('Ocup. %.0f%% (%.1f / %.1f h)', [Pct, HrsA, HrsD]);
  ACanvas.Font.Style := [];
  ACanvas.Font.Size := 8;
  ACanvas.Font.Color := $00606060;
  ACanvas.TextOut(R.Left + 8, R.Top + 32, S);

  // Barra de ocupacion redondeada
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := $00E8E8E8;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(R.Left + 8, R.Top + 50, R.Right - 8, R.Top + 62, 4, 4);
  if Pct > 0 then
  begin
    BarW := MulDiv(R.Right - R.Left - 16, Round(Min(Pct, 150)), 150);
    ACanvas.Brush.Color := OcupacionColor(Pct);
    if BarW >= 8 then
      ACanvas.RoundRect(R.Left + 8, R.Top + 50,
        R.Left + 8 + BarW, R.Top + 62, 4, 4);
  end;
  ACanvas.Pen.Style := psSolid;
end;

procedure TOperariColumnsControl.DrawCard(const ACanvas: TCanvas; OpId: Integer;
  const Asig: TAsignacionOperario; const R: TRect;
  IsHover, IsOverlap: Boolean);
var
  D: TNodeData;
  S: string;
  N, Nec: Integer;
  CapInfo: TCapacitacion;
  PrioColor: TColor;
begin
  if not Assigned(FNodeRepo) or not FNodeRepo.TryGetById(Asig.DataId, D) then Exit;

  // Sombra estilo Kanban/Trello (debajo y un pelin a la derecha)
  ACanvas.Pen.Style := psClear;
  ACanvas.Brush.Color := $00DCDCDC;
  ACanvas.RoundRect(R.Left + 1, R.Top + 2, R.Right + 1, R.Bottom + 2, 8, 8);
  ACanvas.Pen.Style := psSolid;

  // Fondo blanco (con tinte hover/overlap/seleccion)
  if IsSelected(OpId, Asig.DataId) then
    ACanvas.Brush.Color := $00E8F4FF
  else if IsHover then
    ACanvas.Brush.Color := $00FFF8E8
  else if IsOverlap then
    ACanvas.Brush.Color := $00E8ECFF
  else
    ACanvas.Brush.Color := clWhite;

  if IsSelected(OpId, Asig.DataId) then
  begin
    ACanvas.Pen.Color := $00E89040;
    ACanvas.Pen.Width := 2;
  end
  else if Asig.IsLocked then
  begin
    ACanvas.Pen.Color := $004080FF;
    ACanvas.Pen.Width := 2;
  end
  else if IsOverlap then
  begin
    ACanvas.Pen.Color := $004040E0;
    ACanvas.Pen.Width := 2;
  end
  else if IsHover then
  begin
    ACanvas.Pen.Color := $00E89040;
    ACanvas.Pen.Width := 2;
  end
  else
  begin
    ACanvas.Pen.Color := $00E0E0E0;
    ACanvas.Pen.Width := 1;
  end;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
  ACanvas.Pen.Width := 1;

  // Barra de prioridad a la izquierda (color por D.Prioridad)
  case D.Prioridad of
    1: PrioColor := $004040FF;  // alta
    2: PrioColor := $000080FF;  // media
    3: PrioColor := $00FF8000;  // baja
  else
    PrioColor := $00B0B0B0;
  end;
  ACanvas.Brush.Color := PrioColor;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(R.Left, R.Top + 2, R.Left + 5, R.Bottom - 2, 3, 3);
  ACanvas.Pen.Style := psSolid;

  // Caption
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Color := $00303030;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Size := 9;
  if D.NumeroTrabajo <> '' then
    S := D.NumeroTrabajo
  else if D.NumeroOrdenFabricacion > 0 then
    S := Format('OF-%d', [D.NumeroOrdenFabricacion])
  else
    S := Format('Nodo-%d', [Asig.DataId]);
  ACanvas.TextOut(R.Left + 12, R.Top + 6, S);

  // Operacion
  ACanvas.Font.Style := [];
  ACanvas.Font.Size := 8;
  ACanvas.Font.Color := $00606060;
  ACanvas.TextOut(R.Left + 12, R.Top + 24, D.Operacion);

  // Badge X/N
  if Assigned(FOpRepo) then
    N := FOpRepo.CountAssignatsAlNode(Asig.DataId)
  else
    N := 0;
  Nec := Max(D.OperariosNecesarios, 1);
  S := Format('%d/%d', [N, Nec]);
  ACanvas.Font.Style := [fsBold];
  if N >= Nec then
    ACanvas.Font.Color := $0040A040
  else
    ACanvas.Font.Color := $004040E0;
  ACanvas.TextOut(R.Right - 36, R.Top + 24, S);

  // Nivel del operario en esta operacion (mini badge redondeado)
  if Assigned(FOpRepo) and FOpRepo.GetCapacitacioInfo(OpId, D.Operacion, CapInfo) then
  begin
    ACanvas.Pen.Style := psClear;
    ACanvas.Brush.Color := NivelColor(CapInfo.Nivel);
    ACanvas.RoundRect(R.Left + 12, R.Top + 40, R.Left + 28, R.Top + 56, 4, 4);
    ACanvas.Pen.Style := psSolid;
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color := clWhite;
    ACanvas.TextOut(R.Left + 16, R.Top + 41, NivelLetra(CapInfo.Nivel));
  end
  else
  begin
    ACanvas.Pen.Style := psClear;
    ACanvas.Brush.Color := $000080FF;
    ACanvas.RoundRect(R.Left + 12, R.Top + 40, R.Left + 28, R.Top + 56, 4, 4);
    ACanvas.Pen.Style := psSolid;
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color := clWhite;
    ACanvas.TextOut(R.Left + 16, R.Top + 41, '?');
  end;

  // Lock indicator: candado dibujado con primitivas
  if Asig.IsLocked then
  begin
    DrawLockIcon(ACanvas, R.Right - 24, R.Top + 38, $004080FF);
  end;

  // Horas
  ACanvas.Font.Style := [];
  ACanvas.Font.Size := 8;
  ACanvas.Font.Color := $00808080;
  S := Format('%.1f h', [Asig.Horas]);
  ACanvas.TextOut(R.Left + 34, R.Top + 58, S);

  ACanvas.Brush.Style := bsSolid;
end;

procedure TOperariColumnsControl.DrawAbsenceBlock(const ACanvas: TCanvas;
  const R: TRect; const Aus: TAusencia);
var
  S: string;
begin
  ACanvas.Brush.Color := TipoAusenciaColor(Aus.Tipo);
  ACanvas.Pen.Color := $00808080;
  ACanvas.Rectangle(R);
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Color := $00303030;
  ACanvas.Font.Size := 8;
  ACanvas.Font.Style := [fsBold];
  if Aus.EsHoraria then
    S := Format('%s  %s  %s-%s (%.1fh)',
      [TipoAusenciaToStr(Aus.Tipo),
       FormatDateTime('dd/mm', Aus.FechaInicio),
       FormatDateTime('hh:nn', Aus.FechaInicio),
       FormatDateTime('hh:nn', Aus.FechaFin),
       (Aus.FechaFin - Aus.FechaInicio) * 24])
  else
    S := Format('%s  %s - %s',
      [TipoAusenciaToStr(Aus.Tipo),
       FormatDateTime('dd/mm', Aus.FechaInicio),
       FormatDateTime('dd/mm', Aus.FechaFin)]);
  ACanvas.TextOut(R.Left + 6, R.Top + 6, S);
  if Aus.Descripcion <> '' then
  begin
    ACanvas.Font.Style := [];
    ACanvas.Font.Color := $00505050;
    ACanvas.TextOut(R.Left + 6, R.Top + 22, Aus.Descripcion);
  end;
  ACanvas.Brush.Style := bsSolid;
end;

procedure TOperariColumnsControl.DrawColumn(const ACanvas: TCanvas;
  ColIdx: Integer; CX: Integer);
var
  Op: TOperario;
  HeaderR, R, ColR: TRect;
  Cards: TArray<TAsignacionOperario>;
  Aus: TArray<TAusencia>;
  I, Y: Integer;
  ScY: Integer;
begin
  Op := FOperarios[ColIdx];

  // Area completa de la columna (estilo Kanban con round corners)
  ColR := Rect(CX, 0, CX + COL_W, ClientHeight - HSBAR_H - 2);

  // Fondo redondeado de la columna entera
  if Op.Id = FDropTargetOpId then
    ACanvas.Brush.Color := $00FAE5D5
  else
    ACanvas.Brush.Color := $00F4F4F0;
  if Op.Id = FDropTargetOpId then
  begin
    ACanvas.Pen.Color := $00D08040;
    ACanvas.Pen.Width := 2;
  end
  else
  begin
    ACanvas.Pen.Color := $00DCDCDC;
    ACanvas.Pen.Width := 1;
  end;
  ACanvas.RoundRect(ColR.Left, ColR.Top, ColR.Right, ColR.Bottom, 12, 12);
  ACanvas.Pen.Width := 1;

  // Cabecera dentro de la columna
  HeaderR := Rect(CX, 0, CX + COL_W, HEADER_H);
  DrawHeader(ACanvas, HeaderR, Op.Id);

  // Linea separadora cabecera/area cards
  ACanvas.Pen.Color := $00E0E0E0;
  ACanvas.MoveTo(CX + 8, HEADER_H);
  ACanvas.LineTo(CX + COL_W - 8, HEADER_H);

  // Clip de la zona de cards/ausencias
  SaveDC(ACanvas.Handle);
  try
    IntersectClipRect(ACanvas.Handle,
      CX + 1, HEADER_H + 1,
      CX + COL_W - 1, ClientHeight - HSBAR_H - 3);

    ScY := ColScrollY(Op.Id);

    // Ausencias (al inicio del area, scrollables junto con cards)
    Y := HEADER_H + CARD_MARGIN - ScY;
    if Assigned(FAbsRepo) then
    begin
      Aus := FAbsRepo.GetByOperarioInRange(Op.Id, FRangeStart,
        IncDay(FRangeEnd, 60));
      for I := 0 to High(Aus) do
      begin
        R := Rect(CX + CARD_MARGIN, Y,
          CX + COL_W - CARD_MARGIN - SBAR_W, Y + ABS_H);
        DrawAbsenceBlock(ACanvas, R, Aus[I]);
        Inc(Y, ABS_H + CARD_GAP);
      end;
    end;

    // Cards asignadas
    Cards := GetCardsForOperario(Op.Id);
    for I := 0 to High(Cards) do
    begin
      if (Y + CARD_H >= HEADER_H) and (Y <= ClientHeight - HSBAR_H) then
      begin
        R := Rect(CX + CARD_MARGIN, Y,
          CX + COL_W - CARD_MARGIN - SBAR_W, Y + CARD_H);
        // Placeholder gris para cards en drag activo (origen + seleccion multiple)
        if IsCardInActiveDrag(Op.Id, Cards[I].DataId) then
        begin
          ACanvas.Brush.Color := $00F0F0F0;
          ACanvas.Pen.Color := $00D0D0D0;
          ACanvas.Pen.Style := psDot;
          ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
          ACanvas.Pen.Style := psSolid;
        end
        else
          DrawCard(ACanvas, Op.Id, Cards[I], R,
            (Op.Id = FHoverOpId) and (I = FHoverCardIdx),
            False);
      end;
      Inc(Y, CARD_H + CARD_GAP);
    end;
  finally
    RestoreDC(ACanvas.Handle, -1);
  end;

  // VScrollbar de la columna
  if MaxColScrollY(Op.Id) > 0 then
  begin
    R := VSBThumbRect(Op.Id, CX);
    ACanvas.Pen.Style := psClear;
    ACanvas.Brush.Color := $00E8E8E8;
    ACanvas.RoundRect(
      CX + COL_W - SBAR_W - 2, HEADER_H + 4,
      CX + COL_W - 2, ClientHeight - HSBAR_H - 6, 4, 4);
    ACanvas.Brush.Color := $00B0B0B0;
    ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 4, 4);
    ACanvas.Pen.Style := psSolid;
  end;
end;

function TOperariColumnsControl.VSBThumbRect(OpId, CX: Integer): TRect;
var
  TrackTop, TrackBottom, TrackH, ThumbH, ThumbY: Integer;
  M: Integer;
begin
  TrackTop := HEADER_H + 4;
  TrackBottom := ClientHeight - HSBAR_H - 6;
  TrackH := TrackBottom - TrackTop;
  M := MaxColScrollY(OpId);
  if (M <= 0) or (TrackH <= 20) then
    Exit(Rect(0, 0, 0, 0));
  ThumbH := Max(20, MulDiv(TrackH, ClientHeight - HEADER_H - HSBAR_H, M + ClientHeight - HEADER_H - HSBAR_H));
  if ThumbH > TrackH then ThumbH := TrackH;
  ThumbY := TrackTop + MulDiv(TrackH - ThumbH, ColScrollY(OpId), M);
  Result := Rect(CX + COL_W - SBAR_W - 2, ThumbY,
    CX + COL_W - 2, ThumbY + ThumbH);
end;

function TOperariColumnsControl.IsOnVSB(const X, Y: Integer; out OpId: Integer): Boolean;
var
  Idx, CX: Integer;
begin
  Result := False;
  OpId := -1;
  Idx := ColIdxAtX(X);
  if Idx < 0 then Exit;
  CX := COL_GAP - FScrollX + Idx * (COL_W + COL_GAP);
  if (X >= CX + COL_W - SBAR_W - 2) and (X <= CX + COL_W - 2) and
     (Y >= HEADER_H + 4) and (Y <= ClientHeight - HSBAR_H - 6) then
  begin
    OpId := FOperarios[Idx].Id;
    Result := MaxColScrollY(OpId) > 0;
  end;
end;

function TOperariColumnsControl.IsOnOptionsBtn(const X, Y: Integer;
  out OpId: Integer): Boolean;
var
  Idx, CX: Integer;
begin
  Result := False;
  OpId := -1;
  Idx := ColIdxAtX(X);
  if Idx < 0 then Exit;
  CX := COL_GAP - FScrollX + Idx * (COL_W + COL_GAP);
  if (X >= CX + COL_W - 28) and (X <= CX + COL_W - 4) and
     (Y >= 4) and (Y <= 24) then
  begin
    OpId := FOperarios[Idx].Id;
    Result := True;
  end;
end;

function TOperariColumnsControl.HSBThumbRect: TRect;
var
  Total, ThumbW, ThumbX: Integer;
begin
  Total := ContentWidth;
  if (Total <= 0) or (MaxScrollX <= 0) then
  begin
    Result := Rect(0, 0, 0, 0);
    Exit;
  end;
  ThumbW := Max(30, MulDiv(ClientWidth, ClientWidth, Total));
  ThumbX := MulDiv(ClientWidth - ThumbW, FScrollX, MaxScrollX);
  Result := Rect(ThumbX, ClientHeight - HSBAR_H + 2,
    ThumbX + ThumbW, ClientHeight - 2);
end;

function TOperariColumnsControl.IsOnHSB(const X, Y: Integer): Boolean;
begin
  Result := (MaxScrollX > 0) and (Y >= ClientHeight - HSBAR_H);
end;

procedure TOperariColumnsControl.Paint;
var
  I, CX: Integer;
  R: TRect;
begin
  // ClearType para texto + smoothing por defecto en GDI
  Canvas.Font.Quality := fqClearTypeNatural;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  CX := COL_GAP - FScrollX;
  for I := 0 to High(FOperarios) do
  begin
    if (CX + COL_W >= 0) and (CX <= ClientWidth) then
      DrawColumn(Canvas, I, CX);
    Inc(CX, COL_W + COL_GAP);
  end;

  // HScrollbar
  if MaxScrollX > 0 then
  begin
    Canvas.Brush.Color := $00E0E0E0;
    Canvas.FillRect(Rect(0, ClientHeight - HSBAR_H, ClientWidth, ClientHeight));
    R := HSBThumbRect;
    Canvas.Brush.Color := $00A0A0A0;
    Canvas.FillRect(R);
  end;

  // Ghost de drag (encima de todo)
  DrawDragGhost(Canvas);
end;

procedure TOperariColumnsControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  OpId, Idx, VSBOp, ColIdx, CX: Integer;
  Cards: TArray<TAsignacionOperario>;
  AusList: TArray<TAusencia>;
  ThumbR: TRect;
  AbsIdx: Integer;
begin
  inherited;

  // Click sobre HScrollbar
  if (Button = mbLeft) and IsOnHSB(X, Y) then
  begin
    if PtInRect(HSBThumbRect, Point(X, Y)) then
    begin
      FDraggingHSB := True;
      FHSBGrabX := X;
      FHSBGrabScrollX := FScrollX;
    end
    else
    begin
      if X < HSBThumbRect.Left then
        FScrollX := Max(0, FScrollX - ClientWidth div 2)
      else
        FScrollX := Min(MaxScrollX, FScrollX + ClientWidth div 2);
      Invalidate;
    end;
    Exit;
  end;

  // Click sobre VScrollbar de columna
  if (Button = mbLeft) and IsOnVSB(X, Y, VSBOp) then
  begin
    ColIdx := ColIdxAtX(X);
    if ColIdx >= 0 then
    begin
      CX := COL_GAP - FScrollX + ColIdx * (COL_W + COL_GAP);
      ThumbR := VSBThumbRect(VSBOp, CX);
      if PtInRect(ThumbR, Point(X, Y)) then
      begin
        FDraggingVSB := True;
        FVSBOpId := VSBOp;
        FVSBGrabY := Y;
        FVSBGrabScrollY := ColScrollY(VSBOp);
      end
      else
      begin
        // page jump
        if Y < ThumbR.Top then
          SetColScrollY(VSBOp, Max(0, ColScrollY(VSBOp) - (ClientHeight - HEADER_H) div 2))
        else
          SetColScrollY(VSBOp, Min(MaxColScrollY(VSBOp),
            ColScrollY(VSBOp) + (ClientHeight - HEADER_H) div 2));
        Invalidate;
      end;
      Exit;
    end;
  end;

  // Click sobre boton "..." de la cabecera
  if (Button = mbLeft) and IsOnOptionsBtn(X, Y, OpId) then
  begin
    FHeaderOptionsClickedOpId := OpId;
    if Assigned(FOnHeaderOptionsClick) then FOnHeaderOptionsClick(Self);
    Exit;
  end;

  OpId := OperarioAtX(X);
  if (Button = mbLeft) and (OpId > 0) and (Y > HEADER_H) then
  begin
    Idx := CardIdxAtPoint(OpId, Y);
    if Idx >= 0 then
    begin
      Cards := GetCardsForOperario(OpId);
      var ClickedDataId := Cards[Idx].DataId;

      if ssCtrl in Shift then
      begin
        // Ctrl+click: alternar seleccion (no inicia drag)
        if IsSelected(OpId, ClickedDataId) then
          FSelectedSet.Remove(SelKey(OpId, ClickedDataId))
        else
          FSelectedSet.Add(SelKey(OpId, ClickedDataId), True);
        Invalidate;
      end
      else
      begin
        // Click sin Ctrl: si la card no esta seleccionada, limpiar y dejar solo esta
        if not IsSelected(OpId, ClickedDataId) then
        begin
          FSelectedSet.Clear;
          FSelectedSet.Add(SelKey(OpId, ClickedDataId), True);
          Invalidate;
        end;
        FDragOpId := OpId;
        FDragCardIdx := Idx;
        FDragStartPt := Point(X, Y);
        FDragPending := True;
      end;
    end
    else
    begin
      // Click en zona vacia de columna: limpiar seleccion (si no Ctrl)
      if not (ssCtrl in Shift) and (FSelectedSet.Count > 0) then
      begin
        FSelectedSet.Clear;
        Invalidate;
      end;
    end;
  end
  else if Button = mbRight then
  begin
    FRightClickOpId := OpId;
    FRightClickDataId := 0;
    FRightClickAbsenceId := 0;
    if (OpId > 0) and (Y > HEADER_H) then
    begin
      // Probar primero ausencias (van al inicio, antes que cards)
      AbsIdx := AbsenceIdxAtPoint(OpId, Y);
      if (AbsIdx >= 0) and Assigned(FAbsRepo) then
      begin
        AusList := FAbsRepo.GetByOperarioInRange(OpId, FRangeStart,
          IncDay(FRangeEnd, 60));
        FRightClickAbsenceId := AusList[AbsIdx].Id;
        Exit;  // popup se dispara en MouseUp
      end;

      Idx := CardIdxAtPoint(OpId, Y);
      if Idx >= 0 then
      begin
        Cards := GetCardsForOperario(OpId);
        FRightClickDataId := Cards[Idx].DataId;
      end;
    end;
  end;
end;

procedure TOperariColumnsControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewOp, NewIdx, NewOptOp, ThumbW, M: Integer;
  TrackTop, TrackBottom, TrackH, ThumbH: Integer;
begin
  inherited;

  if FDraggingHSB and (MaxScrollX > 0) then
  begin
    ThumbW := HSBThumbRect.Width;
    if ClientWidth - ThumbW > 0 then
      FScrollX := ClampInt(FHSBGrabScrollX +
        MulDiv(X - FHSBGrabX, MaxScrollX, ClientWidth - ThumbW),
        0, MaxScrollX);
    Invalidate;
    Exit;
  end;

  if FDraggingVSB and (FVSBOpId > 0) then
  begin
    M := MaxColScrollY(FVSBOpId);
    if M > 0 then
    begin
      TrackTop := HEADER_H + 4;
      TrackBottom := ClientHeight - HSBAR_H - 6;
      TrackH := TrackBottom - TrackTop;
      ThumbH := Max(20, MulDiv(TrackH,
        ClientHeight - HEADER_H - HSBAR_H,
        M + ClientHeight - HEADER_H - HSBAR_H));
      if ThumbH > TrackH then ThumbH := TrackH;
      if TrackH - ThumbH > 0 then
        SetColScrollY(FVSBOpId,
          ClampInt(FVSBGrabScrollY +
            MulDiv(Y - FVSBGrabY, M, TrackH - ThumbH), 0, M));
    end;
    Invalidate;
    Exit;
  end;

  if FDragPending and (Abs(X - FDragStartPt.X) + Abs(Y - FDragStartPt.Y) > 6) then
  begin
    FDragPending := False;
    BuildDragGhost(DragDataId, FDragOpId, Length(DragCardRefs));
    if Assigned(FOnBeginDrag) then FOnBeginDrag(Self);
  end;

  // Hover sobre boton "..." (cambio visual)
  if IsOnOptionsBtn(X, Y, NewOptOp) then
  begin
    if NewOptOp <> FHoverOptionsOpId then
    begin
      FHoverOptionsOpId := NewOptOp;
      Invalidate;
    end;
  end
  else if FHoverOptionsOpId <> -1 then
  begin
    FHoverOptionsOpId := -1;
    Invalidate;
  end;

  NewOp := OperarioAtX(X);
  if Y > HEADER_H then
    NewIdx := CardIdxAtPoint(NewOp, Y)
  else
    NewIdx := -1;
  if (NewOp <> FHoverOpId) or (NewIdx <> FHoverCardIdx) then
  begin
    FHoverOpId := NewOp;
    FHoverCardIdx := NewIdx;
    Invalidate;
  end;

  // Forzar repaint mientras hay drag pegado: para que el ghost siga al cursor
  if (FDragOpId > 0) and not FDragPending then
    Invalidate;
end;

procedure TOperariColumnsControl.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  FDraggingHSB := False;
  FDraggingVSB := False;
  // Si el drag estaba pendiente y nunca paso del threshold, era click simple:
  // limpiamos para que OnIdle no procese un drop falso.
  if FDragPending then
  begin
    FDragPending := False;
    FDragOpId := -1;
    FDragCardIdx := -1;
  end;
  // El reseteo de FDragOpId/FDragCardIdx tras un drag real lo hace
  // ApplicationOnIdle del form, despues de procesar el drop.
  if (Button = mbRight) and (FRightClickDataId > 0) and Assigned(FOnRightClickCard) then
    FOnRightClickCard(Self)
  else if (Button = mbRight) and (FRightClickAbsenceId > 0) and Assigned(FOnRightClickAbsence) then
    FOnRightClickAbsence(Self);
end;

procedure TOperariColumnsControl.DblClick;
var
  Pt: TPoint;
  OpId, Idx: Integer;
  Cards: TArray<TAsignacionOperario>;
begin
  inherited;
  Pt := ScreenToClient(Mouse.CursorPos);
  OpId := OperarioAtX(Pt.X);
  if (OpId <= 0) or (Pt.Y <= HEADER_H) then Exit;
  Idx := CardIdxAtPoint(OpId, Pt.Y);
  if Idx < 0 then Exit;
  Cards := GetCardsForOperario(OpId);
  if Idx >= Length(Cards) then Exit;
  FDblClickDataId := Cards[Idx].DataId;
  if Assigned(FOnDblClickCard) then FOnDblClickCard(Self);
end;

function TOperariColumnsControl.DoMouseWheel(Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint): Boolean;
var
  Pt: TPoint;
  OpId: Integer;
begin
  Pt := ScreenToClient(MousePos);
  // Shift+wheel o wheel sobre cabecera/HSB -> scroll horizontal
  if (ssShift in Shift) or (Pt.Y < HEADER_H) or (Pt.Y >= ClientHeight - HSBAR_H) then
  begin
    FScrollX := ClampInt(FScrollX - (WheelDelta div 2), 0, MaxScrollX);
  end
  else
  begin
    OpId := OperarioAtX(Pt.X);
    if OpId > 0 then
      SetColScrollY(OpId,
        ClampInt(ColScrollY(OpId) - (WheelDelta div 4), 0, MaxColScrollY(OpId)))
    else
      // Sin operario sota cursor (gap entre columnes): scroll horizontal
      FScrollX := ClampInt(FScrollX - (WheelDelta div 2), 0, MaxScrollX);
  end;
  Invalidate;
  Result := True;
end;

procedure TOperariColumnsControl.UpdateDropTarget(const ScreenPt: TPoint);
var
  Pt: TPoint;
  OpId: Integer;
begin
  Pt := ScreenToClient(ScreenPt);
  if PtInRect(ClientRect, Pt) then
  begin
    OpId := OperarioAtX(Pt.X);
    if OpId <> FDropTargetOpId then
    begin
      FDropTargetOpId := OpId;
      FDropActive := OpId > 0;
      Invalidate;
    end;
  end
  else
  begin
    if FDropTargetOpId <> -1 then
    begin
      FDropTargetOpId := -1;
      FDropActive := False;
      Invalidate;
    end;
  end;
end;

procedure TOperariColumnsControl.ClearDropTarget;
begin
  FDropTargetOpId := -1;
  FDropActive := False;
  Invalidate;
end;

procedure TOperariColumnsControl.BeginExternalDrag(DataId: Integer; Count: Integer);
begin
  BuildDragGhost(DataId, 0, Count);
end;

function TOperariColumnsControl.GhostBitmap: TBitmap;
begin
  Result := FDragGhostBmp;
end;

function TOperariColumnsControl.DragDataId: Integer;
var
  Cards: TArray<TAsignacionOperario>;
begin
  Result := 0;
  if (FDragOpId > 0) and (FDragCardIdx >= 0) then
  begin
    Cards := GetCardsForOperario(FDragOpId);
    if FDragCardIdx < Length(Cards) then
      Result := Cards[FDragCardIdx].DataId;
  end;
end;

function TOperariColumnsControl.DragOpId: Integer;
begin
  Result := FDragOpId;
end;

function TOperariColumnsControl.DragCardRefs: TArray<TOpCardRef>;
var
  L: TList<TOpCardRef>;
  Key: string;
  Parts: TArray<string>;
  Ref: TOpCardRef;
  Curr: TOpCardRef;
begin
  L := TList<TOpCardRef>.Create;
  try
    if FDragOpId <= 0 then Exit(nil);
    Curr.OperarioId := FDragOpId;
    Curr.DataId := DragDataId;
    if Curr.DataId <= 0 then Exit(nil);

    // Si la card arrastrada esta en seleccion, devolver toda la seleccion.
    // Si no, solo la card arrastrada.
    if IsSelected(Curr.OperarioId, Curr.DataId) then
    begin
      for Key in FSelectedSet.Keys do
      begin
        Parts := Key.Split(['-']);
        if Length(Parts) = 2 then
        begin
          Ref.OperarioId := StrToIntDef(Parts[0], 0);
          Ref.DataId := StrToIntDef(Parts[1], 0);
          if (Ref.OperarioId > 0) and (Ref.DataId > 0) then
            L.Add(Ref);
        end;
      end;
    end
    else
      L.Add(Curr);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TOperariColumnsControl.ClearSelection;
begin
  if FSelectedSet.Count > 0 then
  begin
    FSelectedSet.Clear;
    Invalidate;
  end;
end;

function TOperariColumnsControl.DropTargetOpId: Integer;
begin
  Result := FDropTargetOpId;
end;

procedure TOperariColumnsControl.EndDrag;
begin
  FDragOpId := -1;
  FDragCardIdx := -1;
  FDragPending := False;
  ClearDragGhost;
  Invalidate;
end;

{ ================== TfrmFiniteCapacityOperaris ================== }

procedure TfrmFiniteCapacityOperaris.FormCreate(Sender: TObject);
begin
  // El Caption ya viene del DFM
  Position := poScreenCenter;

  cbRango.Items.Clear;
  cbRango.Items.Add('Hoy');
  cbRango.Items.Add('Esta semana');
  cbRango.Items.Add('Pr'#243'ximas 2 semanas');
  cbRango.Items.Add('Este mes');
  cbRango.ItemIndex := 1;

  cbOrden.Items.Clear;
  cbOrden.Items.Add('Ordenar por: Nombre');
  cbOrden.Items.Add('Ordenar por: Ocupaci'#243'n %');
  cbOrden.Items.Add('Ordenar por: Departamento');
  cbOrden.ItemIndex := 0;

  // Crear controles custom
  FPendingList := TPendingOpsListControl.Create(Self);
  FPendingList.Parent := pnlPendientes;
  FPendingList.Align := alClient;
  FPendingList.OnBeginDrag := OnPendingBeginDrag;
  FPendingList.OnDblClickCard := OnPendingDblClick;

  FOperariColumns := TOperariColumnsControl.Create(Self);
  FOperariColumns.Parent := pnlOperarios;
  FOperariColumns.Align := alClient;
  FOperariColumns.OnBeginDrag := OnColBeginDrag;
  FOperariColumns.OnLockToggle := OnColLockToggle;
  FOperariColumns.OnUnassignClick := OnColUnassign;
  FOperariColumns.OnRightClickCard := OnColRightClick;
  FOperariColumns.OnRightClickAbsence := OnColRightClickAbsence;
  FOperariColumns.OnDblClickCard := OnColDblClick;
  FOperariColumns.OnHeaderOptionsClick := OnHeaderOptionsClick;

  Application.OnIdle := ApplicationOnIdle;
end;

procedure TfrmFiniteCapacityOperaris.FormDestroy(Sender: TObject);
begin
  Application.OnIdle := nil;
  if FOwnsAbsRepo and Assigned(FAbsRepo) then FAbsRepo.Free;
  if FOwnsTypesRepo and Assigned(FTypesRepo) then FTypesRepo.Free;
end;

procedure TfrmFiniteCapacityOperaris.FillFiltroOp;
var
  Ops: TArray<string>;
  I: Integer;
begin
  cbFiltroOp.Items.Clear;
  cbFiltroOp.Items.Add('(Todas las operaciones)');
  if Assigned(FOpRepo) then
  begin
    Ops := FOpRepo.GetAllOperacions;
    for I := 0 to High(Ops) do
      cbFiltroOp.Items.Add(Ops[I]);
  end;
  cbFiltroOp.ItemIndex := 0;
end;

function TfrmFiniteCapacityOperaris.CollectPendingDataIds: TArray<Integer>;
var
  All: TArray<TNodeData>;
  L: TList<Integer>;
  I, NAsig: Integer;
begin
  L := TList<Integer>.Create;
  try
    if Assigned(FNodeRepo) then
    begin
      All := FNodeRepo.GetAllData;
      for I := 0 to High(All) do
      begin
        // Pendiente: no esta finalizado y faltan operarios por asignar
        if All[I].Estado = neFinalizado then Continue;
        if Assigned(FOpRepo) then
          NAsig := FOpRepo.CountAssignatsAlNode(All[I].DataId)
        else
          NAsig := 0;
        if NAsig < Max(All[I].OperariosNecesarios, 1) then
          L.Add(All[I].DataId);
      end;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmFiniteCapacityOperaris.RefreshAll;
var
  Pending: TArray<Integer>;
  Operarios: TArray<TOperario>;
begin
  Pending := CollectPendingDataIds;
  if Assigned(FOpRepo) then
    Operarios := FOpRepo.GetOperarios
  else
    SetLength(Operarios, 0);

  FPendingList.SetData(FNodeRepo, FOpRepo, Pending);
  FOperariColumns.SetData(FOpRepo, FNodeRepo, FAbsRepo, FTypesRepo, Operarios);
  FOperariColumns.SetVisibleIds(FVisibleOperarioIds);

  case cbRango.ItemIndex of
    0: FOperariColumns.SetRange(frHoy);
    1: FOperariColumns.SetRange(frSemana);
    2: FOperariColumns.SetRange(fr2Semanas);
    3: FOperariColumns.SetRange(frMes);
  end;

  case cbOrden.ItemIndex of
    0: FOperariColumns.SetSortMode(smNombre);
    1: FOperariColumns.SetSortMode(smOcupacion);
    2: FOperariColumns.SetSortMode(smDepartamento);
  end;

  // Reaplicar filtros para que mantengan el efecto despues de SetData
  cbFiltroOpChange(nil);

  UpdateResumen;

  FPendingList.Invalidate;
  FOperariColumns.Invalidate;
end;

procedure TfrmFiniteCapacityOperaris.UpdateResumen;
var
  Tot, Over, Under: Integer;
  Avg: Double;
begin
  FOperariColumns.ComputeSummary(Tot, Over, Under, Avg);
  lblResumen.Caption := Format(
    'Operarios visibles: %d  |  Ocupaci'#243'n media: %.0f%%  |  ' +
    'Sobrecargados (>100%%): %d  |  Subocupados (<70%%): %d',
    [Tot, Avg, Over, Under]);
end;

procedure TfrmFiniteCapacityOperaris.cbRangoChange(Sender: TObject);
begin
  RefreshAll;
end;

procedure TfrmFiniteCapacityOperaris.cbOrdenChange(Sender: TObject);
begin
  RefreshAll;
end;

procedure TfrmFiniteCapacityOperaris.cbFiltroOpChange(Sender: TObject);
var
  Op: string;
begin
  if cbFiltroOp.ItemIndex <= 0 then
    Op := ''
  else
    Op := cbFiltroOp.Items[cbFiltroOp.ItemIndex];
  FPendingList.SetFilter(Op, -1, -1, chkSoloCapacitados.Checked,
    edFiltroArticulo.Text);
  UpdatePendingCount;
end;

procedure TfrmFiniteCapacityOperaris.chkSoloCapacitadosClick(Sender: TObject);
begin
  cbFiltroOpChange(nil);
end;

procedure TfrmFiniteCapacityOperaris.edFiltroArticuloChange(Sender: TObject);
begin
  cbFiltroOpChange(nil);
end;

procedure TfrmFiniteCapacityOperaris.btnOperariosVisiblesClick(Sender: TObject);
var
  NewIds: TArray<Integer>;
begin
  if TfrmOperariosVisibles.Execute(FOpRepo, FVisibleOperarioIds, NewIds) then
  begin
    FVisibleOperarioIds := NewIds;
    RefreshAll;
  end;
end;

procedure TfrmFiniteCapacityOperaris.OnPendingBeginDrag(Sender: TObject);
var
  Ids: TArray<Integer>;
begin
  Ids := FPendingList.DragDataIds;
  FOperariColumns.BeginExternalDrag(FPendingList.DragDataId, Length(Ids));
end;

procedure TfrmFiniteCapacityOperaris.OnColBeginDrag(Sender: TObject);
begin
  // Drag interno entre columnas
end;

procedure TfrmFiniteCapacityOperaris.OnColLockToggle(Sender: TObject);
begin
  miLockClick(nil);
end;

procedure TfrmFiniteCapacityOperaris.OnColUnassign(Sender: TObject);
begin
  miUnassignClick(nil);
end;

procedure TfrmFiniteCapacityOperaris.OnColRightClick(Sender: TObject);
var
  P: TPoint;
begin
  GetCursorPos(P);
  pmCard.Popup(P.X, P.Y);
end;

procedure TfrmFiniteCapacityOperaris.OnColRightClickAbsence(Sender: TObject);
var
  P: TPoint;
begin
  GetCursorPos(P);
  pmAbsence.Popup(P.X, P.Y);
end;

procedure TfrmFiniteCapacityOperaris.OnPendingDblClick(Sender: TObject);
begin
  ShowNodeInspectorById(FPendingList.DblClickDataId);
end;

procedure TfrmFiniteCapacityOperaris.OnColDblClick(Sender: TObject);
begin
  ShowNodeInspectorById(FOperariColumns.DblClickDataId);
end;

procedure TfrmFiniteCapacityOperaris.ShowNodeInspectorById(DataId: Integer);
var
  D: TNodeData;
begin
  if DataId <= 0 then Exit;
  if not Assigned(FNodeRepo) then Exit;
  if not FNodeRepo.TryGetById(DataId, D) then Exit;
  TfrmNodeInspector.Execute(D, True, FCustomFieldDefs);
  RefreshAll;
end;

procedure TfrmFiniteCapacityOperaris.UpdatePendingCount;
begin
  lblPendientes.Caption := Format('OTs pendientes (%d)',
    [Length(FPendingList.Items)]);
end;

procedure TfrmFiniteCapacityOperaris.OnHeaderOptionsClick(Sender: TObject);
var
  P: TPoint;
begin
  GetCursorPos(P);
  pmOperario.Popup(P.X, P.Y);
end;

procedure TfrmFiniteCapacityOperaris.miDesasignarTodoClick(Sender: TObject);
var
  OpId, I, Removed, Skipped: Integer;
  Asigs: TArray<TAsignacionOperario>;
begin
  OpId := FOperariColumns.HeaderOptionsClickedOpId;
  if (OpId <= 0) or not Assigned(FOpRepo) then Exit;
  if MessageDlg('?Quitar todas las asignaciones de este operario?'#13#10 +
       '(Las asignaciones bloqueadas se mantendr'#225'n)',
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Asigs := FOpRepo.GetAsignacionsByOperario(OpId);
  Removed := 0;
  Skipped := 0;
  for I := 0 to High(Asigs) do
    if Asigs[I].IsLocked then
      Inc(Skipped)
    else
    begin
      FOpRepo.RemoveAsignacion(OpId, Asigs[I].DataId);
      Inc(Removed);
    end;
  RefreshAll;
  if Skipped > 0 then
    ShowMessage(Format('Quitadas %d asignaciones. %d bloqueadas se han mantenido.',
      [Removed, Skipped]));
end;

procedure TfrmFiniteCapacityOperaris.miBloquearTodoClick(Sender: TObject);
var
  OpId, I: Integer;
  Asigs: TArray<TAsignacionOperario>;
begin
  OpId := FOperariColumns.HeaderOptionsClickedOpId;
  if (OpId <= 0) or not Assigned(FOpRepo) then Exit;
  Asigs := FOpRepo.GetAsignacionsByOperario(OpId);
  for I := 0 to High(Asigs) do
    if not Asigs[I].IsLocked then
      FOpRepo.SetAsignacionLock(OpId, Asigs[I].DataId, True, '');
  RefreshAll;
end;

procedure TfrmFiniteCapacityOperaris.miDesbloquearTodoClick(Sender: TObject);
var
  OpId, I: Integer;
  Asigs: TArray<TAsignacionOperario>;
begin
  OpId := FOperariColumns.HeaderOptionsClickedOpId;
  if (OpId <= 0) or not Assigned(FOpRepo) then Exit;
  Asigs := FOpRepo.GetAsignacionsByOperario(OpId);
  for I := 0 to High(Asigs) do
    if Asigs[I].IsLocked then
      FOpRepo.SetAsignacionLock(OpId, Asigs[I].DataId, False, '');
  RefreshAll;
end;

procedure TfrmFiniteCapacityOperaris.miQuitarAusenciaClick(Sender: TObject);
var
  AusId: Integer;
begin
  AusId := FOperariColumns.RightClickAbsenceId;
  if (AusId <= 0) or not Assigned(FAbsRepo) then Exit;
  if MessageDlg('?Quitar esta ausencia?', mtConfirmation,
       [mbYes, mbNo], 0) <> mrYes then Exit;
  FAbsRepo.Remove(AusId);
  RefreshAll;
end;

procedure TfrmFiniteCapacityOperaris.miGestionAusenciasClick(Sender: TObject);
var
  OpId: Integer;
begin
  OpId := FOperariColumns.HeaderOptionsClickedOpId;
  if OpId <= 0 then Exit;
  TfrmOperarioAusencias.Execute(FOpRepo, FAbsRepo, OpId);
  RefreshAll;
end;

procedure TfrmFiniteCapacityOperaris.miGestionCalendarioClick(Sender: TObject);
var
  OpId: Integer;
begin
  OpId := FOperariColumns.HeaderOptionsClickedOpId;
  if OpId <= 0 then Exit;
  // TODO v1.1: abrir TfrmOperarioCalendario (calendario propio del operario)
  ShowMessage('Pr'#243'ximamente: gesti'#243'n de calendario del operario.');
end;

procedure TfrmFiniteCapacityOperaris.ApplicationOnIdle(Sender: TObject;
  var Done: Boolean);
var
  ScreenPt: TPoint;
  PendingId, ColId, ColFromOp, DropOp: Integer;
  DropOnPending: Boolean;
begin
  Done := True;
  GetCursorPos(ScreenPt);

  PendingId := FPendingList.DragDataId;
  ColId := FOperariColumns.DragDataId;
  ColFromOp := FOperariColumns.DragOpId;

  if (GetKeyState(VK_LBUTTON) and $8000) <> 0 then
  begin
    if (PendingId > 0) or (ColId > 0) then
    begin
      FOperariColumns.UpdateDropTarget(ScreenPt);
      FOperariColumns.Invalidate;  // refrescar ghost en zona columnas
      // Activar ghost en panel pendientes tambien (para que se vea en ambos lados)
      FPendingList.SetDragActive(True, FOperariColumns.GhostBitmap);
      // Solo el drag desde columna puede caer en pendientes (unassign)
      FPendingList.SetDropActive(
        (ColId > 0) and FPendingList.PointIsInside(ScreenPt));
    end;
  end
  else
  begin
    // Boton soltado: procesar drop
    DropOp := FOperariColumns.DropTargetOpId;
    DropOnPending := (ColId > 0) and FPendingList.PointIsInside(ScreenPt);

    if (PendingId > 0) and (DropOp > 0) then
    begin
      var Ids := FPendingList.DragDataIds;
      for var Id in Ids do
        DoAssignFromPending(Id, DropOp);
      FPendingList.ClearSelection;
      RefreshAll;
    end
    else if (ColId > 0) and DropOnPending and (ColFromOp > 0) then
    begin
      // Drop desde columna a pendientes -> desasignar todas las seleccionadas
      var Refs := FOperariColumns.DragCardRefs;
      var Skipped := 0;
      for var Ref in Refs do
      begin
        if FOpRepo.IsAsignacionLocked(Ref.OperarioId, Ref.DataId) then
          Inc(Skipped)
        else
          FOpRepo.RemoveAsignacion(Ref.OperarioId, Ref.DataId);
      end;
      if Skipped > 0 then
        ShowMessage(Format('%d asignaciones bloqueadas se han mantenido.', [Skipped]));
      FOperariColumns.ClearSelection;
      RefreshAll;
    end
    else if (ColId > 0) and (DropOp > 0) and (ColFromOp > 0) and (ColFromOp <> DropOp) then
    begin
      // Move: aplicar a todas las seleccionadas (excepto las que ya esten en destino)
      var Refs := FOperariColumns.DragCardRefs;
      for var Ref in Refs do
        DoMoveAssignment(Ref.DataId, Ref.OperarioId, DropOp);
      FOperariColumns.ClearSelection;
      RefreshAll;
    end;

    FOperariColumns.ClearDropTarget;
    FPendingList.SetDropActive(False);
    FPendingList.SetDragActive(False, nil);
    FOperariColumns.EndDrag;
    FPendingList.EndDrag;
  end;
end;

procedure TfrmFiniteCapacityOperaris.DoAssignFromPending(DataId, OpId: Integer);
var
  D: TNodeData;
  A: TAsignacionOperario;
  Existing: TArray<TAsignacionOperario>;
  I: Integer;
  AlreadyAssigned: Boolean;
  Horas: Double;
begin
  if not Assigned(FOpRepo) or not Assigned(FNodeRepo) then Exit;
  if not FNodeRepo.TryGetById(DataId, D) then Exit;

  // No duplicar si ya esta asignado a este operario
  Existing := FOpRepo.GetAsignacionsByNode(DataId);
  AlreadyAssigned := False;
  for I := 0 to High(Existing) do
    if Existing[I].OperarioId = OpId then
    begin
      AlreadyAssigned := True;
      Break;
    end;
  if AlreadyAssigned then Exit;

  Horas := D.DurationMin / 60;
  if Horas <= 0 then Horas := 1;

  A.OperarioId := OpId;
  A.DataId := DataId;
  A.Horas := Horas;
  A.IsLocked := False;
  A.LockedBy := '';
  A.LockedAt := 0;
  FOpRepo.AddAsignacion(A);
end;

procedure TfrmFiniteCapacityOperaris.DoMoveAssignment(DataId, FromOpId,
  ToOpId: Integer);
var
  Existing: TArray<TAsignacionOperario>;
  I: Integer;
  AlreadyTarget: Boolean;
begin
  if not Assigned(FOpRepo) then Exit;
  if (FromOpId <= 0) or (ToOpId <= 0) or (FromOpId = ToOpId) then Exit;

  // Si el destino ya tiene esta asignacion, no duplicamos pero quitamos del origen
  Existing := FOpRepo.GetAsignacionsByNode(DataId);
  AlreadyTarget := False;
  for I := 0 to High(Existing) do
    if Existing[I].OperarioId = ToOpId then
    begin
      AlreadyTarget := True;
      Break;
    end;

  // No se mueve una asignacion bloqueada
  if FOpRepo.IsAsignacionLocked(FromOpId, DataId) then
  begin
    ShowMessage('La asignaci'#243'n de origen est'#225' bloqueada. ' +
      'Desbloqu'#233'ela antes de moverla.');
    Exit;
  end;

  // Quitar del origen
  FOpRepo.RemoveAsignacion(FromOpId, DataId);

  // Anyadir al destino si no estaba ya
  if not AlreadyTarget then
    DoAssignFromPending(DataId, ToOpId);
end;

procedure TfrmFiniteCapacityOperaris.miLockClick(Sender: TObject);
var
  OpId, DataId: Integer;
  WasLocked: Boolean;
begin
  OpId := FOperariColumns.RightClickOpId;
  DataId := FOperariColumns.RightClickDataId;
  if (OpId <= 0) or (DataId <= 0) then Exit;
  WasLocked := FOpRepo.IsAsignacionLocked(OpId, DataId);
  FOpRepo.SetAsignacionLock(OpId, DataId, not WasLocked, '');
  RefreshAll;
end;

procedure TfrmFiniteCapacityOperaris.miUnassignClick(Sender: TObject);
var
  OpId, DataId: Integer;
begin
  OpId := FOperariColumns.RightClickOpId;
  DataId := FOperariColumns.RightClickDataId;
  if (OpId <= 0) or (DataId <= 0) then Exit;
  if FOpRepo.IsAsignacionLocked(OpId, DataId) then
  begin
    ShowMessage('La asignaci'#243'n est'#225' bloqueada. Desbloqu'#233'ela primero.');
    Exit;
  end;
  FOpRepo.RemoveAsignacion(OpId, DataId);
  RefreshAll;
end;

procedure TfrmFiniteCapacityOperaris.btnOKClick(Sender: TObject);
var
  L: TList<TFCOAssignment>;
  Ops: TArray<TOperario>;
  Asigs: TArray<TAsignacionOperario>;
  I, J: Integer;
  R: TFCOAssignment;
begin
  L := TList<TFCOAssignment>.Create;
  try
    if Assigned(FOpRepo) then
    begin
      Ops := FOpRepo.GetOperarios;
      for I := 0 to High(Ops) do
      begin
        Asigs := FOpRepo.GetAsignacionsByOperario(Ops[I].Id);
        for J := 0 to High(Asigs) do
        begin
          R.OperarioId := Asigs[J].OperarioId;
          R.DataId := Asigs[J].DataId;
          R.Horas := Asigs[J].Horas;
          R.IsLocked := Asigs[J].IsLocked;
          L.Add(R);
        end;
      end;
    end;
    FResult := L.ToArray;
  finally
    L.Free;
  end;
  FAccepted := True;
  ModalResult := mrOk;
end;

procedure TfrmFiniteCapacityOperaris.btnCancelClick(Sender: TObject);
begin
  FAccepted := False;
  ModalResult := mrCancel;
end;

class function TfrmFiniteCapacityOperaris.Execute(
  ANodeRepo: TNodeDataRepo;
  AOpRepo: TOperariosRepo;
  out AAssignments: TArray<TFCOAssignment>;
  AAbsRepo: TOperatorAbsencesRepo;
  ATypesRepo: TOperationTypesRepo;
  ACustomFieldDefs: TCustomFieldDefs): Boolean;
var
  F: TfrmFiniteCapacityOperaris;
  OperarioIds: TArray<Integer>;
  Ops: TArray<TOperario>;
  I: Integer;
begin
  Result := False;
  SetLength(AAssignments, 0);
  F := TfrmFiniteCapacityOperaris.Create(nil);
  try
    F.FNodeRepo := ANodeRepo;
    F.FOpRepo := AOpRepo;
    F.FCustomFieldDefs := ACustomFieldDefs;

    if Assigned(AAbsRepo) then
    begin
      F.FAbsRepo := AAbsRepo;
      F.FOwnsAbsRepo := False;
    end
    else
    begin
      F.FAbsRepo := TOperatorAbsencesRepo.Create;
      F.FOwnsAbsRepo := True;
      // Sample data si tenemos operarios
      if Assigned(AOpRepo) then
      begin
        Ops := AOpRepo.GetOperarios;
        SetLength(OperarioIds, Length(Ops));
        for I := 0 to High(Ops) do OperarioIds[I] := Ops[I].Id;
        F.FAbsRepo.LoadSampleData(OperarioIds);
      end;
    end;

    if Assigned(ATypesRepo) then
    begin
      F.FTypesRepo := ATypesRepo;
      F.FOwnsTypesRepo := False;
    end
    else
    begin
      F.FTypesRepo := TOperationTypesRepo.Create;
      F.FOwnsTypesRepo := True;
      F.FTypesRepo.LoadSampleData;
    end;

    F.FillFiltroOp;
    F.RefreshAll;
    F.ShowModal;

    if F.FAccepted then
    begin
      AAssignments := F.FResult;
      Result := True;
    end;
  finally
    F.Free;
  end;
end;

end.
