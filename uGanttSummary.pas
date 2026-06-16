unit uGanttSummary;

{
  TGanttSummaryControl - Banda de RESUMEN/KPIs por dia, alineada con el Gantt.

  Es un control hermano del TGanttTimelineControl: comparte EXACTAMENTE el mismo
  sistema de coordenadas temporal (FStartTime + FPxPerMinute + FScrollX +
  FLeftWidth + FHideWeekends) para que las franjas verticales de cada dia queden
  alineadas pixel a pixel con el timeline y con el Gantt.

  Se sincroniza desde fuera via SetViewport(StartTime, PxPerMinute, ScrollX),
  igual que el timeline, asi sigue el scroll horizontal / paning / zoom wheel.

  Por ahora muestra un placeholder de KPI por dia (numero de dia). El calculo
  real de KPIs (carga, entregas, etc.) se conectara en una fase posterior via
  un proveedor de datos; el render ya deja un area por dia donde pintarlos.

  Render: Direct2D sobre un HwndRenderTarget propio (mismo patron que el
  timeline: CreateDeviceResources / Discard / Resize), con DirectWrite para texto.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.Classes, System.SysUtils, System.Types, System.DateUtils, System.Math,
  Vcl.Controls, Vcl.Graphics, Winapi.D2D1, Winapi.DxgiFormat,
  uGanttTypes, uGanttHelpers;

type
  // Vista de resumen seleccionada (botones btnS1..btnS4 en uVistaGantt).
  //  svNone      = sin vista (banda vacia, solo franjas).
  //  svNodeCount = numero de nodos visibles que tocan cada dia (btnS4).
  // (svS1/svS2/svS3 quedan reservadas para las otras vistas.)
  TSummaryView = (svNone, svNodeCount, svS1, svS2, svS3);

  // Color de fondo del badge (esquina superior derecha de cada dia).
  //  sbcNone  = no pintar badge.
  //  sbcRed   = ningun nodo del dia con operarios asignados.
  //  sbcYellow= algunos nodos con operarios asignados.
  //  sbcGreen = todos los nodos del dia con operarios asignados.
  TSummaryBadgeColor = (sbcNone, sbcRed, sbcYellow, sbcGreen);

  // Proveedor de KPIs por dia. El caller lo asigna; el control lo invoca por
  // cada dia visible SOLO si hay una vista activa. Devuelve las lineas de texto.
  //   ADate      = dia (a medianoche)
  //   ALine1/2/3 = textos KPI (vacio = no pintar). Si ALine3<>'' se pintan las
  //                3 lineas con letra NORMAL (no negrita) repartidas vertical;
  //                si ALine3='' -> modo 2 lineas: valor (negrita) + etiqueta.
  //   AHighlight = marca lateral (p.ej. hoy / dia critico).
  //   AIntensity = 0..1 para el heatmap del fondo (0 = sin/poco, 1 = maximo).
  //                <0 = no aplicar heatmap (fondo plano por defecto).
  //   ABadgeCount/ABadgeColor = badge esquina sup. derecha (numero + color de
  //                fondo). ABadgeColor=sbcNone -> no se pinta badge.
  TSummaryDayKPIEvent = procedure(Sender: TObject; const ADate: TDateTime;
    out ALine1, ALine2, ALine3: string; out AHighlight: Boolean;
    out AIntensity: Single; out ABadgeCount: Integer;
    out ABadgeColor: TSummaryBadgeColor) of object;

  // Mateixos contractes que el timeline, perque uVistaGantt els pugui cablejar igual.
  TSummaryViewportChangedEvent = procedure(Sender: TObject;
    const StartTime: TDateTime; const PxPerMinute, ScrollX: Single) of object;
  TSummaryInteractionEvent = procedure(Sender: TObject; const Interacting: Boolean) of object;

  TGanttSummaryControl = class(TCustomControl)
  private
    FD2DFactory: ID2D1Factory;
    FDWriteFactory: IDWriteFactory;
    FHwndRT: ID2D1HwndRenderTarget;

    FBrushBg: ID2D1SolidColorBrush;
    FBrushBandEven: ID2D1SolidColorBrush;
    FBrushBandOdd: ID2D1SolidColorBrush;
    FBrushWeekend: ID2D1SolidColorBrush;
    FBrushGrid: ID2D1SolidColorBrush;
    FBrushBorder: ID2D1SolidColorBrush;
    FBrushText: ID2D1SolidColorBrush;
    FBrushTextDim: ID2D1SolidColorBrush;
    FBrushHighlight: ID2D1SolidColorBrush;
    FBrushNoData: ID2D1SolidColorBrush;   // dia SENSE dades -> gris clar
    FBrushHasData: ID2D1SolidColorBrush;  // dia AMB dades   -> blau clar
    FBrushGreen: ID2D1SolidColorBrush;    // valor destacat (verd) en mode 3 linies
    FBrushBadgeRed: ID2D1SolidColorBrush;    // badge: cap node amb operaris
    FBrushBadgeYellow: ID2D1SolidColorBrush; // badge: alguns nodes amb operaris
    FBrushBadgeGreen: ID2D1SolidColorBrush;  // badge: tots els nodes amb operaris
    FBrushBadgeText: ID2D1SolidColorBrush;   // numero del badge (blanc)

    FFmtValue: IDWriteTextFormat;
    FFmtLabel: IDWriteTextFormat;
    FFmtValueSmall: IDWriteTextFormat;    // negreta mida petita (1a linia 3-linies)
    FFmtBadge: IDWriteTextFormat;         // numero del badge (negreta, petita)

    // --- Modelo de coordenadas (igual que el timeline) ---
    FLeftWidth: Integer;
    FStartTime: TDateTime;
    FPxPerMinute: Single;
    FScrollX: Single;
    FHideWeekends: Boolean;
    FRangeStart, FRangeEnd: TDateTime;   // limits per a MaxScrollX/clamp
    FView: TSummaryView;

    FOnDayKPI: TSummaryDayKPIEvent;
    FOnViewportChanged: TSummaryViewportChangedEvent;
    FOnInteraction: TSummaryInteractionEvent;

    // pan (igual que el timeline)
    FIsPanning: Boolean;
    FPanStart: TPoint;
    FScrollStartX: Single;
    FPendingScrollX: Single;
    FHasPendingScroll: Boolean;
    FPanTimerActive: Boolean;
    // settle
    FInteracting: Boolean;
    FSettleTimerActive: Boolean;

    procedure SetHideWeekends(const Value: Boolean);
    procedure SetLeftWidth(const Value: Integer);
    procedure SetView(const Value: TSummaryView);

    function ClampPxPerMinute(const Value: Single): Single;
    function MaxScrollX: Single;
    function ClampScrollX(const Value: Single): Single;
    procedure NotifyViewportChanged;
    procedure BeginInteraction;
    procedure ArmSettleTimer;
    procedure EndInteraction;
    procedure StartPanTimer;
    procedure StopPanTimer;

    // Coordenadas temporales (copiadas del timeline para mantener alineacion)
    function VisibleMinutesBetween(const AFrom, ATo: TDateTime): Double;
    function AddVisibleMinutes(const AStart: TDateTime; const AMinutes: Double): TDateTime;
    function TimeToX(const T: TDateTime): Single;
    function XToTime(const X: Single): TDateTime;
    function StartOfVisibleDay(const ADate: TDateTime): TDateTime;
    function NextVisibleDay(const ADate: TDateTime): TDateTime;

    function GetStartVisibleTime: TDateTime;
    function GetEndVisibleTime: TDateTime;

    // Direct2D
    procedure InitD2D;
    procedure InitDWrite;
    procedure CreateDeviceResources;
    procedure CreateBrushResources;
    procedure CreateTextResources;
    procedure DiscardDeviceResources;
    procedure ResizeRenderTarget;
    function D2DColor(const C: TColor; const A: Single = 1.0): TD2D1ColorF;
    // Color del heatmap segun intensidad 0..1: verde claro -> verde oscuro.
    function HeatColor(const AIntensity: Single): TD2D1ColorF;
    procedure DrawTextD(const S: string; const R: TRectF;
      const Fmt: IDWriteTextFormat; const Brush: ID2D1Brush);

    procedure PaintD2D;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Sincronizacion del viewport (mismo contrato que el timeline).
    procedure SetViewport(const AStartTime: TDateTime;
      const APxPerMinute, AScrollX: Single);
    // Rang temporal total (per limitar el scroll). Mateix contracte que timeline.
    procedure SetTimeRange(const AStart, AEnd: TDateTime);

    property StartVisibleTime: TDateTime read GetStartVisibleTime;
    property EndVisibleTime: TDateTime read GetEndVisibleTime;
    property StartTime: TDateTime read FStartTime;
    property PxPerMinute: Single read FPxPerMinute;
    property ScrollX: Single read FScrollX;
  published
    property Align;
    property PopupMenu;
    property Height default 41;
    property LeftWidth: Integer read FLeftWidth write SetLeftWidth default 0;
    property HideWeekends: Boolean read FHideWeekends write SetHideWeekends;
    property View: TSummaryView read FView write SetView default svNone;
    property OnDayKPI: TSummaryDayKPIEvent read FOnDayKPI write FOnDayKPI;
    property OnViewportChanged: TSummaryViewportChangedEvent
      read FOnViewportChanged write FOnViewportChanged;
    property OnInteraction: TSummaryInteractionEvent
      read FOnInteraction write FOnInteraction;
  end;

implementation

const
  MINS_PER_DAY = 24 * 60;

  IDT_SUM_PAN = 142;     // invalidacio durant el pan
  PAN_TIMER_MS = 20;
  IDT_SUM_SETTLE = 143;  // fi d'interaccio
  SETTLE_MS = 200;

{ ---- HELPER ---- }

procedure CheckHR(const Res: HRESULT; const Msg: string);
begin
  if Failed(Res) then
    raise EOSError.CreateFmt('%s. HRESULT=0x%.8x', [Msg, Cardinal(Res)]);
end;

{ TGanttSummaryControl }

constructor TGanttSummaryControl.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := False;
  Height := 41;
  FLeftWidth := 0;
  FPxPerMinute := 2.0;
  FStartTime := Now;
  FScrollX := 0;
  FHideWeekends := False;
end;

destructor TGanttSummaryControl.Destroy;
begin
  DiscardDeviceResources;
  FHwndRT := nil;
  FDWriteFactory := nil;
  FD2DFactory := nil;
  inherited;
end;

procedure TGanttSummaryControl.CreateWnd;
begin
  inherited;
  InitD2D;
end;

procedure TGanttSummaryControl.DestroyWnd;
begin
  DiscardDeviceResources;
  inherited;
end;

procedure TGanttSummaryControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;  // evitem flicker; pintem tot el client a Direct2D
end;

procedure TGanttSummaryControl.Resize;
begin
  inherited;
  ResizeRenderTarget;
  Invalidate;
end;

procedure TGanttSummaryControl.SetHideWeekends(const Value: Boolean);
begin
  if FHideWeekends = Value then Exit;
  FHideWeekends := Value;
  Invalidate;
end;

procedure TGanttSummaryControl.SetLeftWidth(const Value: Integer);
begin
  if FLeftWidth = Value then Exit;
  FLeftWidth := Value;
  Invalidate;
end;

procedure TGanttSummaryControl.SetView(const Value: TSummaryView);
begin
  if FView = Value then Exit;
  FView := Value;
  Invalidate;
end;

{ ---- Coordenadas temporales (identicas al timeline) ---- }

function TGanttSummaryControl.StartOfVisibleDay(const ADate: TDateTime): TDateTime;
begin
  Result := DateOf(ADate);
  if FHideWeekends then
    while IsWeekend(Result) do
      Result := IncDay(Result);
end;

function TGanttSummaryControl.NextVisibleDay(const ADate: TDateTime): TDateTime;
begin
  Result := IncDay(DateOf(ADate), 1);
  if FHideWeekends then
    while IsWeekend(Result) do
      Result := IncDay(Result);
end;

function TGanttSummaryControl.VisibleMinutesBetween(
  const AFrom, ATo: TDateTime): Double;
const
  MINS_PER_WEEK_VISIBLE = 5 * MINS_PER_DAY;
var
  S, E, SDate, EDate, SegStart, SegEnd: TDateTime;
  WholeDays, WholeWeeks: Integer;
begin
  Result := 0;
  if ATo <= AFrom then Exit;

  if not FHideWeekends then
    Exit((ATo - AFrom) * MINS_PER_DAY);

  S := AFrom; E := ATo;
  SDate := DateOf(S); EDate := DateOf(E);

  if SDate = EDate then
  begin
    if not IsWeekend(SDate) then
      Result := (E - S) * MINS_PER_DAY;
    Exit;
  end;

  if not IsWeekend(SDate) then
  begin
    SegStart := S; SegEnd := IncDay(SDate, 1);
    Result := Result + ((SegEnd - SegStart) * MINS_PER_DAY);
  end;

  if not IsWeekend(EDate) then
  begin
    SegStart := EDate; SegEnd := E;
    Result := Result + ((SegEnd - SegStart) * MINS_PER_DAY);
  end;

  SDate := IncDay(SDate, 1);
  EDate := IncDay(EDate, -1);
  if SDate > EDate then Exit;

  while (SDate <= EDate) and (DayOfTheWeek(SDate) <> 1) do
  begin
    if not IsWeekend(SDate) then
      Result := Result + MINS_PER_DAY;
    SDate := IncDay(SDate);
  end;

  WholeDays := DaysBetween(SDate, EDate) + 1;
  if WholeDays >= 7 then
  begin
    WholeWeeks := WholeDays div 7;
    Result := Result + (WholeWeeks * MINS_PER_WEEK_VISIBLE);
    SDate := IncDay(SDate, WholeWeeks * 7);
  end;

  while SDate <= EDate do
  begin
    if not IsWeekend(SDate) then
      Result := Result + MINS_PER_DAY;
    SDate := IncDay(SDate);
  end;
end;

function TGanttSummaryControl.AddVisibleMinutes(
  const AStart: TDateTime; const AMinutes: Double): TDateTime;
var
  Remaining, Avail: Double;
  D, DayStart, DayEnd: TDateTime;
begin
  if not FHideWeekends then
    Exit(AStart + (AMinutes / MINS_PER_DAY));

  Remaining := AMinutes;
  Result := AStart;
  D := DateOf(Result);

  while IsWeekend(D) do
  begin
    D := IncDay(D);
    Result := D;
  end;

  while Remaining > 0 do
  begin
    D := DateOf(Result);
    if IsWeekend(D) then
    begin
      D := NextVisibleDay(D);
      Result := D;
      Continue;
    end;
    DayStart := Result;
    DayEnd := IncDay(D, 1);
    Avail := (DayEnd - DayStart) * MINS_PER_DAY;
    if Remaining <= Avail then
      Exit(Result + (Remaining / MINS_PER_DAY));
    Remaining := Remaining - Avail;
    Result := NextVisibleDay(D);
  end;
end;

function TGanttSummaryControl.TimeToX(const T: TDateTime): Single;
begin
  Result := FLeftWidth + (VisibleMinutesBetween(FStartTime, T) * FPxPerMinute) - FScrollX;
end;

function TGanttSummaryControl.XToTime(const X: Single): TDateTime;
begin
  Result := AddVisibleMinutes(FStartTime, ((X + FScrollX) - FLeftWidth) / FPxPerMinute);
end;

function TGanttSummaryControl.GetStartVisibleTime: TDateTime;
begin
  Result := AddVisibleMinutes(FStartTime, FScrollX / FPxPerMinute);
end;

function TGanttSummaryControl.GetEndVisibleTime: TDateTime;
begin
  Result := AddVisibleMinutes(FStartTime, (FScrollX + ClientWidth) / FPxPerMinute);
end;

procedure TGanttSummaryControl.SetViewport(const AStartTime: TDateTime;
  const APxPerMinute, AScrollX: Single);
const
  EPS_PX = 0.01;
  EPS_TIME = 1 / 86400;
begin
  if SameValue(FStartTime, AStartTime, EPS_TIME) and
     SameValue(FPxPerMinute, APxPerMinute, 1E-6) and
     SameValue(FScrollX, Max(0, AScrollX), EPS_PX) then
    Exit;

  FStartTime := AStartTime;
  FPxPerMinute := APxPerMinute;
  FScrollX := Max(0, AScrollX);
  Invalidate;
end;

procedure TGanttSummaryControl.SetTimeRange(const AStart, AEnd: TDateTime);
begin
  FRangeStart := DateOf(AStart);
  FRangeEnd := DateOf(AEnd) + 1 - (1 / 86400);
  FStartTime := FRangeStart;
  FScrollX := ClampScrollX(FScrollX);
  Invalidate;
end;

{ ---- Interaccio: zoom + pan (igual que el timeline) ---- }

function TGanttSummaryControl.ClampPxPerMinute(const Value: Single): Single;
const
  MinDaysVisible = 0.1;
  MaxDaysVisible = 30;
var
  minPx, maxPx: Single;
begin
  if ClientWidth <= 1 then Exit(Value);
  minPx := ClientWidth / (MaxDaysVisible * 24 * 60);
  maxPx := ClientWidth / (MinDaysVisible * 24 * 60);
  Result := EnsureRange(Value, minPx, maxPx);
end;

function TGanttSummaryControl.MaxScrollX: Single;
var
  totalMinutes: Double;
  contentWidth: Single;
begin
  if (FRangeEnd <= FRangeStart) or (ClientWidth <= 1) then Exit(0);
  totalMinutes := VisibleMinutesBetween(FRangeStart, FRangeEnd);
  contentWidth := totalMinutes * FPxPerMinute;
  Result := Max(0, contentWidth - ClientWidth);
end;

function TGanttSummaryControl.ClampScrollX(const Value: Single): Single;
begin
  Result := EnsureRange(Value, 0, MaxScrollX);
end;

procedure TGanttSummaryControl.NotifyViewportChanged;
begin
  if Assigned(FOnViewportChanged) then
    FOnViewportChanged(Self, FStartTime, FPxPerMinute, FScrollX);
end;

procedure TGanttSummaryControl.BeginInteraction;
begin
  if FInteracting then Exit;
  FInteracting := True;
  if Assigned(FOnInteraction) then FOnInteraction(Self, True);
end;

procedure TGanttSummaryControl.ArmSettleTimer;
begin
  KillTimer(Handle, IDT_SUM_SETTLE);
  SetTimer(Handle, IDT_SUM_SETTLE, SETTLE_MS, nil);
  FSettleTimerActive := True;
end;

procedure TGanttSummaryControl.EndInteraction;
begin
  if not FInteracting then Exit;
  FInteracting := False;
  if Assigned(FOnInteraction) then FOnInteraction(Self, False);
end;

procedure TGanttSummaryControl.StartPanTimer;
begin
  if FPanTimerActive then Exit;
  SetTimer(Handle, IDT_SUM_PAN, PAN_TIMER_MS, nil);
  FPanTimerActive := True;
end;

procedure TGanttSummaryControl.StopPanTimer;
begin
  if not FPanTimerActive then Exit;
  KillTimer(Handle, IDT_SUM_PAN);
  FPanTimerActive := False;
end;

procedure TGanttSummaryControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft) and (X >= FLeftWidth) then
  begin
    FIsPanning := True;
    FPanStart := Point(X, Y);
    FScrollStartX := FScrollX;
    FPendingScrollX := FScrollX;
    FHasPendingScroll := False;
    BeginInteraction;
    ArmSettleTimer;
    SetCapture(Handle);
    StartPanTimer;
  end;
end;

procedure TGanttSummaryControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  dx: Integer;
begin
  inherited;
  if not FIsPanning then Exit;
  dx := X - FPanStart.X;
  FPendingScrollX := ClampScrollX(FScrollStartX - dx);
  FHasPendingScroll := True;
end;

procedure TGanttSummaryControl.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FIsPanning and (Button = mbLeft) then
  begin
    FIsPanning := False;
    ReleaseCapture;
    if FHasPendingScroll then
    begin
      FScrollX := FPendingScrollX;
      FHasPendingScroll := False;
      NotifyViewportChanged;
      Invalidate;
    end;
    BeginInteraction;
    ArmSettleTimer;
    StopPanTimer;
  end;
end;

procedure TGanttSummaryControl.WMTimer(var Message: TWMTimer);
begin
  if Message.TimerID = IDT_SUM_SETTLE then
  begin
    KillTimer(Handle, IDT_SUM_SETTLE);
    FSettleTimerActive := False;
    EndInteraction;
    Message.Result := 0;
    Exit;
  end;

  if Message.TimerID <> IDT_SUM_PAN then
  begin
    inherited;
    Exit;
  end;

  if not FIsPanning then
  begin
    StopPanTimer;
    Exit;
  end;

  if not FHasPendingScroll then Exit;

  if Abs(FPendingScrollX - FScrollX) > 0.01 then
  begin
    FScrollX := FPendingScrollX;
    BeginInteraction;
    ArmSettleTimer;
    NotifyViewportChanged;
    Invalidate;
  end;

  FHasPendingScroll := False;
  Message.Result := 0;
end;

procedure TGanttSummaryControl.WMMouseWheel(var Message: TWMMouseWheel);
var
  pt: TPoint;
  xClient: Integer;
  tUnderCursor: TDateTime;
  newScroll, zoomFactor: Single;
begin
  pt := ScreenToClient(Message.Pos);
  xClient := pt.X;
  if xClient < FLeftWidth then
  begin
    Message.Result := 1;
    Exit;
  end;

  tUnderCursor := XToTime(xClient);

  if Message.WheelDelta > 0 then
    zoomFactor := 1.15
  else
    zoomFactor := 1 / 1.15;

  FPxPerMinute := ClampPxPerMinute(FPxPerMinute * zoomFactor);

  // mantenir el temps sota el cursor
  newScroll := (FLeftWidth + VisibleMinutesBetween(FStartTime, tUnderCursor) * FPxPerMinute) - xClient;
  FScrollX := ClampScrollX(newScroll);

  BeginInteraction;
  ArmSettleTimer;
  NotifyViewportChanged;
  Invalidate;
  Message.Result := 1;
end;

{ ---- Direct2D ---- }

procedure TGanttSummaryControl.InitD2D;
begin
  if not Assigned(FD2DFactory) then
    CheckHR(D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED,
      ID2D1Factory, nil, FD2DFactory), 'D2D1CreateFactory');
end;

procedure TGanttSummaryControl.InitDWrite;
var
  Unk: IUnknown;
begin
  if Assigned(FDWriteFactory) then Exit;
  Unk := nil;
  CheckHR(DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, IDWriteFactory, Unk),
    'DWriteCreateFactory');
  FDWriteFactory := Unk as IDWriteFactory;
end;

procedure TGanttSummaryControl.CreateDeviceResources;
var
  RTProps: TD2D1RenderTargetProperties;
  HwndProps: TD2D1HwndRenderTargetProperties;
begin
  if Assigned(FHwndRT) then Exit;
  InitD2D;
  RTProps := D2D1RenderTargetProperties(
    D2D1_RENDER_TARGET_TYPE_DEFAULT,
    D2D1PixelFormat(DXGI_FORMAT_UNKNOWN, D2D1_ALPHA_MODE_IGNORE),
    0, 0,
    D2D1_RENDER_TARGET_USAGE_NONE,
    D2D1_FEATURE_LEVEL_DEFAULT);
  HwndProps := D2D1HwndRenderTargetProperties(
    Handle,
    D2D1SizeU(Max(1, ClientWidth), Max(1, ClientHeight)),
    D2D1_PRESENT_OPTIONS_IMMEDIATELY);
  CheckHR(FD2DFactory.CreateHwndRenderTarget(RTProps, HwndProps, FHwndRT),
    'CreateHwndRenderTarget');

  CreateBrushResources;
  CreateTextResources;
end;

procedure TGanttSummaryControl.CreateBrushResources;
  function B(const C: TColor; const A: Single = 1.0): ID2D1SolidColorBrush;
  begin
    FHwndRT.CreateSolidColorBrush(D2DColor(C, A), nil, Result);
  end;
begin
  FBrushBg        := B($00F7F4F1);            // fons general
  FBrushBandEven  := B($00FFFFFF);            // dia parell
  FBrushBandOdd   := B($00F0ECE7);            // dia senar (alternat)
  FBrushWeekend   := B($00E8E2DB);            // cap de setmana
  FBrushGrid      := B($00C8C0B8);            // linies verticals de dia
  FBrushBorder    := B($00B0A99F);
  FBrushText      := B($00303030);            // valor KPI
  FBrushTextDim   := B($00808080);            // etiqueta inferior
  FBrushHighlight := B($002850D0);            // dia destacat
  FBrushNoData    := B($00EBEBEB);            // dia SENSE dades -> gris clar
  FBrushHasData   := B($00FAE4D0);            // dia AMB dades   -> blau clar (BGR)
  FBrushGreen     := B($00308828);            // valor destacat verd (BGR)
  // Badges (color en BGR): vermell / groc / verd; text blanc.
  FBrushBadgeRed    := B($003B3BD0);          // vermell
  FBrushBadgeYellow := B($0020B0E0);          // groc/ambre
  FBrushBadgeGreen  := B($00308828);          // verd
  FBrushBadgeText   := B($00FFFFFF);          // blanc
end;

procedure TGanttSummaryControl.CreateTextResources;
begin
  InitDWrite;
  // Valor KPI (linea superior, mas gran y negrita)
  CheckHR(FDWriteFactory.CreateTextFormat('Segoe UI', nil,
    DWRITE_FONT_WEIGHT_BOLD, DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL,
    12.0, '', FFmtValue), 'CreateTextFormat value');
  FFmtValue.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
  FFmtValue.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
  FFmtValue.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);

  // Etiqueta (linea inferior, mas pequena)
  CheckHR(FDWriteFactory.CreateTextFormat('Segoe UI', nil,
    DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL,
    9.0, '', FFmtLabel), 'CreateTextFormat label');
  FFmtLabel.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
  FFmtLabel.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
  FFmtLabel.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);

  // Valor destacado pequenyo (negrita, mida 9) para la 1a linia del mode 3 linies.
  CheckHR(FDWriteFactory.CreateTextFormat('Segoe UI', nil,
    DWRITE_FONT_WEIGHT_BOLD, DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL,
    9.0, '', FFmtValueSmall), 'CreateTextFormat valueSmall');
  FFmtValueSmall.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
  FFmtValueSmall.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
  FFmtValueSmall.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);

  // Numero del badge (negrita, mida petita, centrat).
  CheckHR(FDWriteFactory.CreateTextFormat('Segoe UI', nil,
    DWRITE_FONT_WEIGHT_BOLD, DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL,
    8.5, '', FFmtBadge), 'CreateTextFormat badge');
  FFmtBadge.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
  FFmtBadge.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
  FFmtBadge.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
end;

procedure TGanttSummaryControl.DiscardDeviceResources;
begin
  FBrushBg := nil; FBrushBandEven := nil; FBrushBandOdd := nil;
  FBrushWeekend := nil; FBrushGrid := nil; FBrushBorder := nil;
  FBrushText := nil; FBrushTextDim := nil; FBrushHighlight := nil;
  FBrushNoData := nil; FBrushHasData := nil; FBrushGreen := nil;
  FBrushBadgeRed := nil; FBrushBadgeYellow := nil; FBrushBadgeGreen := nil;
  FBrushBadgeText := nil;
  FFmtValue := nil; FFmtLabel := nil; FFmtValueSmall := nil; FFmtBadge := nil;
  FHwndRT := nil;
end;

procedure TGanttSummaryControl.ResizeRenderTarget;
var
  Sz: TD2D1SizeU;
begin
  if Assigned(FHwndRT) then
  begin
    Sz := D2D1SizeU(Max(1, ClientWidth), Max(1, ClientHeight));
    FHwndRT.Resize(Sz);
  end;
end;

function TGanttSummaryControl.D2DColor(const C: TColor; const A: Single): TD2D1ColorF;
var
  rgb: Cardinal;
begin
  rgb := ColorToRGB(C);
  Result.r := (rgb and $FF) / 255;
  Result.g := ((rgb shr 8) and $FF) / 255;
  Result.b := ((rgb shr 16) and $FF) / 255;
  Result.a := A;
end;

function TGanttSummaryControl.HeatColor(const AIntensity: Single): TD2D1ColorF;
var
  t: Single;
begin
  // Color de la barra de progreso: gradiente ROJO (0%) -> VERDE (100%) pasando
  // por amarillo. Tonos PASTEL muy claros para que el texto negro encima sea
  // siempre legible.
  t := AIntensity;
  if t < 0 then t := 0 else if t > 1 then t := 1;
  if t < 0.5 then
  begin
    // Rojo pastel (245,200,200) -> Amarillo pastel (248,240,190)
    Result.r := (245 + (248 - 245) * (t / 0.5)) / 255;
    Result.g := (200 + (240 - 200) * (t / 0.5)) / 255;
    Result.b := (200 + (190 - 200) * (t / 0.5)) / 255;
  end
  else
  begin
    // Amarillo pastel (248,240,190) -> Verde pastel (200,235,205)
    Result.r := (248 + (200 - 248) * ((t - 0.5) / 0.5)) / 255;
    Result.g := (240 + (235 - 240) * ((t - 0.5) / 0.5)) / 255;
    Result.b := (190 + (205 - 190) * ((t - 0.5) / 0.5)) / 255;
  end;
  Result.a := 1.0;
end;

procedure TGanttSummaryControl.DrawTextD(const S: string; const R: TRectF;
  const Fmt: IDWriteTextFormat; const Brush: ID2D1Brush);
var
  lr: D2D1_RECT_F;
begin
  if S = '' then Exit;
  lr.left := R.Left; lr.top := R.Top; lr.right := R.Right; lr.bottom := R.Bottom;
  FHwndRT.DrawText(PWideChar(S), Length(S), Fmt, lr, Brush);
end;

procedure TGanttSummaryControl.PaintD2D;
var
  visStart, visEnd: TDateTime;
  d, dNext: TDateTime;
  x1, x2: Single;
  bandR: TRectF;
  dayIdx: Integer;
  v1, v2, v3: string;
  hi: Boolean;
  intensity: Single;
  H: Single;
  badgeCount: Integer;
  badgeColor: TSummaryBadgeColor;
  badgeBrush: ID2D1SolidColorBrush;
  badgeTxt: string;
  bw, bh, bx, by: Single;
  bRR: TD2D1RoundedRect;
begin
  CreateDeviceResources;
  if not Assigned(FHwndRT) then Exit;

  H := ClientHeight;

  FHwndRT.BeginDraw;
  try
    FHwndRT.Clear(D2DColor($00F7F4F1));

    visStart := GetStartVisibleTime;
    visEnd := GetEndVisibleTime;

    // Iterem dia a dia visible i pintem una franja per cada un, alineada amb
    // TimeToX (mateixa formula que timeline i Gantt -> mateixes franges).
    d := StartOfVisibleDay(visStart);
    dayIdx := 0;
    while d < visEnd do
    begin
      dNext := NextVisibleDay(d);
      x1 := TimeToX(d);
      x2 := TimeToX(dNext);

      if x2 > FLeftWidth then
      begin
        if x1 < FLeftWidth then x1 := FLeftWidth;

        bandR := TRectF.Create(x1, 0, x2, H);

        // PRIMER resolem les dades del dia (via OnDayKPI) per decidir el fons.
        v1 := ''; v2 := ''; v3 := ''; hi := False; intensity := -1;
        badgeCount := 0; badgeColor := sbcNone;
        if (FView <> svNone) and Assigned(FOnDayKPI) then
          FOnDayKPI(Self, d, v1, v2, v3, hi, intensity, badgeCount, badgeColor);

        var HasData: Boolean := (v1 <> '') or (v2 <> '') or (v3 <> '') or hi;

        if HasData then
        begin
          if intensity >= 0 then
          begin
            // Fondo GRIS claro de base...
            FBrushHasData.SetColor(D2DColor($00ECECEC));
            FHwndRT.FillRectangle(D2D1RectF(bandR.Left, bandR.Top, bandR.Right, bandR.Bottom), FBrushHasData);
            // ...y encima una BARRA DE PROGRESO vertical de abajo hacia arriba,
            // proporcional al % de ocupacion (clamp a 1). El COLOR va de ROJO
            // (0%) a VERDE (100%) segun ese mismo %.
            var prog: Single := intensity;
            if prog > 1 then prog := 1;
            if prog > 0 then
            begin
              FBrushHasData.SetColor(HeatColor(prog));
              FHwndRT.FillRectangle(
                D2D1RectF(bandR.Left, H * (1 - prog), bandR.Right, H),
                FBrushHasData);
            end;
          end
          else
          begin
            // intensity < 0 con datos: fondo GRIS (dia con capacidad pero sin
            // ocupacion). Sin barra de progreso.
            FBrushHasData.SetColor(D2DColor($00DCDCDC));  // gris
            FHwndRT.FillRectangle(D2D1RectF(bandR.Left, bandR.Top, bandR.Right, bandR.Bottom), FBrushHasData);
          end;
        end
        else
          FHwndRT.FillRectangle(D2D1RectF(bandR.Left, bandR.Top, bandR.Right, bandR.Bottom), FBrushNoData);

        if hi then
          FHwndRT.FillRectangle(
            D2D1RectF(bandR.Left, 0, bandR.Left + 3, H), FBrushHighlight);

        if v3 <> '' then
        begin
          // Mode 3 linies (p.ej. S3 amb dades): la 1a linia (valor principal)
          // en NEGRITA; totes les lletres NEGRES (sobre fons pastel clar).
          DrawTextD(v1, TRectF.Create(x1 + 1, 1, x2 - 1, H * 0.34),
            FFmtValueSmall, FBrushText);
          DrawTextD(v2, TRectF.Create(x1 + 1, H * 0.34, x2 - 1, H * 0.67),
            FFmtLabel, FBrushText);
          DrawTextD(v3, TRectF.Create(x1 + 1, H * 0.67, x2 - 1, H - 1),
            FFmtLabel, FBrushTextDim);
        end
        else
        begin
          // Mode 2 linies: valor (negrita, gran) a dalt + etiqueta a baix.
          DrawTextD(v1, TRectF.Create(x1 + 1, 2, x2 - 1, H * 0.58),
            FFmtValue, FBrushText);
          DrawTextD(v2, TRectF.Create(x1 + 1, H * 0.55, x2 - 1, H - 1),
            FFmtLabel, FBrushTextDim);
        end;

        // Badge a la cantonada superior dreta: numero de nodes del dia, amb fons
        // segons cobertura d'operaris (vermell/groc/verd) i numero en blanc. Nomes
        // si hi cap (la franja del dia ha de ser prou ampla).
        if (badgeColor <> sbcNone) and ((x2 - x1) >= 22) then
        begin
          case badgeColor of
            sbcRed:    badgeBrush := FBrushBadgeRed;
            sbcYellow: badgeBrush := FBrushBadgeYellow;
            sbcGreen:  badgeBrush := FBrushBadgeGreen;
          else
            badgeBrush := nil;
          end;
          if badgeBrush <> nil then
          begin
            badgeTxt := IntToStr(badgeCount);
            // Amplada proporcional als digits; alçada fixa. Marge de 2px a la vora.
            bw := 14 + 6 * (Length(badgeTxt) - 1);
            bh := 13;
            bx := x2 - bw - 2;
            if bx < x1 + 1 then bx := x1 + 1;
            by := 2;
            bRR := D2D1RoundedRect(D2D1RectF(bx, by, bx + bw, by + bh), 6, 6);
            FHwndRT.FillRoundedRectangle(bRR, badgeBrush);
            DrawTextD(badgeTxt, TRectF.Create(bx, by, bx + bw, by + bh),
              FFmtBadge, FBrushBadgeText);
          end;
        end;
      end;

      // Linia vertical de separacio de dia (alineada amb el Gantt/timeline)
      if (x2 >= FLeftWidth) and (x2 <= ClientWidth) then
        FHwndRT.DrawLine(D2D1PointF(x2, 0), D2D1PointF(x2, H), FBrushGrid, 1.0);

      d := dNext;
      Inc(dayIdx);
      if dayIdx > 5000 then Break;  // guarda anti-bucle
    end;

    // Separador esquerre (limit amb la columna d'etiquetes) i vora inferior
    if FLeftWidth > 0 then
      FHwndRT.DrawLine(D2D1PointF(FLeftWidth, 0), D2D1PointF(FLeftWidth, H),
        FBrushBorder, 1.0);
    FHwndRT.DrawLine(D2D1PointF(0, 0.5), D2D1PointF(ClientWidth, 0.5),
      FBrushBorder, 1.0);
    FHwndRT.DrawLine(D2D1PointF(0, H - 0.5), D2D1PointF(ClientWidth, H - 0.5),
      FBrushBorder, 1.0);

    if FHwndRT.EndDraw = D2DERR_RECREATE_TARGET then
      DiscardDeviceResources;  // device-lost -> recrear al proxim frame
  except
    FHwndRT.EndDraw;
    DiscardDeviceResources;
    raise;
  end;
end;

procedure TGanttSummaryControl.Paint;
begin
  PaintD2D;
end;

end.
