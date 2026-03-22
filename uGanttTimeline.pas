unit uGanttTimeline;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.Classes, System.SysUtils, System.Types, System.DateUtils, System.Math,
  Vcl.Controls, Vcl.Graphics, uGanttTypes, Winapi.D2D1, Winapi.DxgiFormat, uGanttHelpers;

const
  IDT_PAN_INVALIDATE = 42;   // qualsevol id > 0
  PAN_TIMER_MS = 20;         // 16ms ~ 60fps (prova 20/33 si vols menys CPU)

  IDT_SETTLE = 43;
  SETTLE_MS = 200;

  ROW_MONTH_H = 16;
  ROW_WEEK_H  = 16;
  ROW_TICK_H  = 16;
  ROW_TOTAL_H = ROW_MONTH_H + ROW_WEEK_H + ROW_TICK_H;

type
  DXGI_FORMAT = type Integer;

  TTimelineBand = (tbNone, tbMonth, tbWeek, tbDayOrHour);

  TTimelineView = (tvHours, tvDay, tvWeek, tvMonth);

  TGanttViewportChangedEvent = procedure(Sender: TObject; const StartTime: TDateTime;
    const PxPerMinute, ScrollX: Single) of object;

  TGanttTimelineInteractionEvent = procedure(Sender: TObject; const Interacting: Boolean) of object;
  TGanttTimelineNeedRepaintEvent = procedure(Sender: TObject) of object;

  TGanttTimelineControl = class(TCustomControl)
  private
    FD2DFactory: ID2D1Factory;
    FDWriteFactory: IDWriteFactory;
    FHwndRT: ID2D1HwndRenderTarget;
    FBrushBg: ID2D1SolidColorBrush;
    FBrushLeftBg: ID2D1SolidColorBrush;
    FBrushMonthBg1: ID2D1SolidColorBrush;
    FBrushMonthBg2: ID2D1SolidColorBrush;
    FBrushWeekBg: ID2D1SolidColorBrush;
    FBrushWeekendBg: ID2D1SolidColorBrush;
    FBrushGridMajor: ID2D1SolidColorBrush;
    FBrushGridMinor: ID2D1SolidColorBrush;
    FBrushBorder: ID2D1SolidColorBrush;
    FBrushTextMain: ID2D1SolidColorBrush;
    FBrushTextSecondary: ID2D1SolidColorBrush;
    FTextFmtMonth: IDWriteTextFormat;
    FTextFmtWeek: IDWriteTextFormat;
    FTextFmtTick: IDWriteTextFormat;

    FHideWeekends: Boolean;

    FLeftWidth: Integer;
    FStartTime, FEndTime: TDateTime;
    FStartVisibleTime, FEndVisibleTime: TDateTime;
    FPxPerMinute: Single;
    FScrollX: Single;

    FOnViewportChanged: TGanttViewportChangedEvent;

    // pan
    FPanTimerActive: Boolean;
    FIsPanning: Boolean;
    FPanStart: TPoint;
    FScrollStartX: Single;
    FRangeStart: TDateTime;
    FRangeEnd: TDateTime;
    // “target” calculat al MouseMove, aplicat al timer
    FPendingScrollX: Single;
    FHasPendingScroll: Boolean;

    // settle
    FInteracting: Boolean;
    FSettleTimerActive: Boolean;
    FOnInteraction: TGanttTimelineInteractionEvent;
    FOnNeedRepaint: TGanttTimelineNeedRepaintEvent;


    procedure SetHideWeekends(const Value: Boolean);

    procedure BeginInteraction;
    procedure ArmSettleTimer;
    procedure EndInteraction;
    function VisibleSpanDays: Double;
    function ScaleOverOneWeek: Boolean;

    function D2DColor(const C: TColor; const A: Single = 1.0): TD2D1ColorF;
    procedure FillRectD(const R: TRectF; const Brush: ID2D1Brush);
    procedure DrawLineD(const X1, Y1, X2, Y2: Single; const Brush: ID2D1Brush; const Stroke: Single = 1.0);
    procedure DrawTextD(const S: string; const R: TRectF; const Fmt: IDWriteTextFormat;
      const Brush: ID2D1Brush; const CenterHoriz: Boolean = True);
    function HitTestBand(const Y: Integer): TTimelineBand;
    procedure ZoomToRange(const AStart, AEnd: TDateTime);
    procedure ZoomToBandAt(const AX, AY: Integer);
    function MonthNameES(const M: Integer): string;
    function WeekdayNameES(const D: TDateTime): string;
    procedure CreateBrushResources;
    procedure CreateTextResources;
    function StartOfMonthEx(const T: TDateTime): TDateTime;
    function StartOfWeekMonday(const T: TDateTime): TDateTime;
    function CeilToHourStep(const T: TDateTime; const StepHours: Integer): TDateTime;
    function CeilToDayStep(const T: TDateTime; const StepDays: Integer): TDateTime;
    function ChooseHourStep: Integer;
    function ChooseDayStep: Integer;
    function FormatMonthLabelES(const D: TDateTime): string;
    function FormatWeekLabelLong(const D: TDateTime): string;
    function FormatWeekLabelShort(const D: TDateTime): string;

    function VisibleMinutesBetween(const AFromTime,  AToTime: TDateTime): Double;
    function AddVisibleMinutes(const AStart: TDateTime; const AVisibleMinutes: Double): TDateTime;

    function GetStartVisibleTime: TDateTime;
    function GetEndVisibleTime: TDateTime;
    procedure StartScrollInvalidateTimer;
    procedure StopScrollInvalidateTimer;
    function MaxScrollX: Single;
    function ClampScrollX(const Value: Single): Single;

    procedure SetLeftWidth(const Value: Integer);
    procedure SetPxPerMinute(const Value: Single);
    procedure SetScrollX(const Value: Single);
    procedure SetStartTime(const Value: TDateTime);

    function XToTime(const X: Single): TDateTime;
    function TimeToX(const T: TDateTime): Single;
    function ClampPxPerMinute(const Value: Single): Single;
    procedure NotifyViewportChanged;

    procedure InitD2D;
    procedure InitDWrite;

    procedure CreateDeviceResources;
    procedure DiscardDeviceResources;
    procedure ResizeRenderTarget;

    procedure DrawRectD(const R: TRectF; const Brush: ID2D1Brush;  const Stroke: Single = 1.0);

    procedure DrawMonthRow(const VisibleStart, VisibleEnd: TDateTime);
    procedure DrawWeekRow(const VisibleStart, VisibleEnd: TDateTime;
      const ZoomShort: Boolean);
    procedure DrawBottomRowDays(const VisibleStart, VisibleEnd: TDateTime);
    procedure DrawBottomRowHours(const VisibleStart, VisibleEnd: TDateTime);
    procedure DrawBottomRowDaysLabeled(const VisibleStart, VisibleEnd: TDateTime);
    procedure DrawDayHeaderRow(const VisibleStart, VisibleEnd: TDateTime);
    procedure DrawWeekRowGrouped(const VisibleStart, VisibleEnd: TDateTime);
    procedure FillMiddleBandBackground;

    procedure NormalizeStartTime;
    function StartOfVisibleDay(const ADate: TDateTime): TDateTime;
    function NextVisibleDay(const ADate: TDateTime): TDateTime;
    function WeekdayShortES(const D: TDateTime): string;

    procedure PaintD2D;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;

    procedure WMLButtonDblClk(var Message: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetViewportStartTime: TDateTime;
    function GetViewportEndTime: TDateTime;


    property HideWeekends: Boolean read FHideWeekends write SetHideWeekends;

    property StartVisibleTime: TDateTime read GetStartVisibleTime;
    property EndVisibleTime: TDateTime read GetEndVisibleTime;

    procedure SetViewAt(const AView: TTimelineView; const ARefTime: TDateTime; const AHours: Single = 8);
    procedure SetView(const AView: TTimelineView; const AHours: Single = 8);

    // Assignar-ho des de fora sense disparar event múltiple (opcional)
    procedure SetViewport(const AStartTime: TDateTime; const APxPerMinute, AScrollX: Single);
    procedure SetTimeRange(const AStart, AEnd: TDateTime);
    property StartTime: TDateTime read FStartTime write SetStartTime;
    property EndTime: TDateTime read FEndTime;
    property PxPerMinute: Single read FPxPerMinute write SetPxPerMinute;
    property ScrollX: Single read FScrollX write SetScrollX;

    procedure CenterOnDate(const ADate: TDateTime);
    function CalcScrollXToCenterDate(const ADate: TDateTime): Single;
  published
    property PopupMenu;
    property Align;
    property Height default 48;
    property LeftWidth: Integer read FLeftWidth write SetLeftWidth default 0;

    property OnInteraction: TGanttTimelineInteractionEvent read FOnInteraction write FOnInteraction;
    property OnNeedRepaint: TGanttTimelineNeedRepaintEvent read FOnNeedRepaint write FOnNeedRepaint;
    property OnViewportChanged: TGanttViewportChangedEvent read FOnViewportChanged write FOnViewportChanged;
  end;

implementation

uses MAin;

//...HELPER
procedure CheckHR(const Res: HRESULT; const Msg: string);
begin
  if Failed(Res) then
    raise EOSError.CreateFmt('%s. HRESULT=0x%.8x', [Msg, Cardinal(Res)]);
end;

function TGanttTimelineControl.WeekdayShortES(const D: TDateTime): string;
const
  Names: array[1..7] of string = (
    'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'
  );
begin
  Result := Names[DayOfTheWeek(D)];
end;




constructor TGanttTimelineControl.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := False;

  Height := 48;
  FLeftWidth := 0;
  FPxPerMinute := 2.0;
  FStartTime := Now;
  FScrollX := 0;
  FHideWeekends := False;

end;


destructor TGanttTimelineControl.Destroy;
begin
  DiscardDeviceResources;
  FHwndRT := nil;
  FDWriteFactory := nil;
  FD2DFactory := nil;
  inherited;
end;


procedure TGanttTimelineControl.CreateWnd;
begin
  inherited;
  InitD2D;
end;


procedure TGanttTimelineControl.DestroyWnd;
begin
  DiscardDeviceResources;
  inherited;
end;
procedure TGanttTimelineControl.Resize;
begin
  inherited;
  ResizeRenderTarget;
  // Reajusta el zoom a límits 1 dia .. 1 mes segons l’amplada actual
  FPxPerMinute := ClampPxPerMinute(FPxPerMinute);

  Invalidate;
end;


procedure TGanttTimelineControl.SetHideWeekends(const Value: Boolean);
begin
  if FHideWeekends = Value then Exit;
  FHideWeekends := Value;
  NormalizeStartTime;
  NotifyViewportChanged;
  Invalidate;
end;


procedure TGanttTimelineControl.NormalizeStartTime;
begin
  if FHideWeekends then
    while IsWeekend(FStartTime) do
      FStartTime := IncDay(DateOf(FStartTime));
end;


function TGanttTimelineControl.StartOfVisibleDay(const ADate: TDateTime): TDateTime;
begin
  Result := DateOf(ADate);
  if FHideWeekends then
    while IsWeekend(Result) do
      Result := IncDay(Result);
end;
function TGanttTimelineControl.NextVisibleDay(const ADate: TDateTime): TDateTime;
begin
  Result := IncDay(DateOf(ADate), 1);
  if FHideWeekends then
    while IsWeekend(Result) do
      Result := IncDay(Result);
end;



procedure TGanttTimelineControl.InitDWrite;
var
  Unk: IUnknown;
  hr: HRESULT;
begin
  if Assigned(FDWriteFactory) then
    Exit;
  Unk := nil;
  hr := DWriteCreateFactory(
          DWRITE_FACTORY_TYPE_SHARED,
          IDWriteFactory,
          Unk
        );
  CheckHR(hr, 'DWriteCreateFactory');
  FDWriteFactory := Unk as IDWriteFactory;
end;


procedure TGanttTimelineControl.InitD2D;
var
  unk: IUnknown;
  hr: HRESULT;
begin
  if not Assigned(FD2DFactory) then
  begin
    hr := D2D1CreateFactory(
      D2D1_FACTORY_TYPE_SINGLE_THREADED,
      ID2D1Factory,
      nil,
      FD2DFactory
    );
    CheckHR(hr, 'D2D1CreateFactory');
  end;

end;



procedure TGanttTimelineControl.CreateTextResources;
begin
  InitDWrite;

  if not Assigned(FDWriteFactory) then
    Exit;

  if not Assigned(FTextFmtMonth) then
  begin
    CheckHR(
      FDWriteFactory.CreateTextFormat(
        'Segoe UI',
        nil,
        DWRITE_FONT_WEIGHT_SEMI_BOLD,
        DWRITE_FONT_STYLE_NORMAL,
        DWRITE_FONT_STRETCH_NORMAL,
        9.0,
        'es-ES',
        FTextFmtMonth
      ),
      'CreateTextFormat FTextFmtMonth'
    );

    FTextFmtMonth.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
    FTextFmtMonth.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
    FTextFmtMonth.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
  end;

  if not Assigned(FTextFmtWeek) then
  begin
    CheckHR(
      FDWriteFactory.CreateTextFormat(
        'Segoe UI',
        nil,
        DWRITE_FONT_WEIGHT_NORMAL,
        DWRITE_FONT_STYLE_NORMAL,
        DWRITE_FONT_STRETCH_NORMAL,
        8.5,
        'es-ES',
        FTextFmtWeek
      ),
      'CreateTextFormat FTextFmtWeek'
    );

    FTextFmtWeek.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
    FTextFmtWeek.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
    FTextFmtWeek.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
  end;

  if not Assigned(FTextFmtTick) then
  begin
    CheckHR(
      FDWriteFactory.CreateTextFormat(
        'Segoe UI',
        nil,
        DWRITE_FONT_WEIGHT_NORMAL,
        DWRITE_FONT_STYLE_NORMAL,
        DWRITE_FONT_STRETCH_NORMAL,
        8.0,
        'es-ES',
        FTextFmtTick
      ),
      'CreateTextFormat FTextFmtTick'
    );

    FTextFmtTick.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
    FTextFmtTick.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
    FTextFmtTick.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
  end;
end;


procedure TGanttTimelineControl.CreateBrushResources;
begin
  if not Assigned(FHwndRT) then
    Exit;

  if not Assigned(FBrushBg) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF(1, 1, 1, 1), nil, FBrushBg),
      'CreateSolidColorBrush FBrushBg'
    );

  if not Assigned(FBrushLeftBg) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF($F2 / 255, $F2 / 255, $F2 / 255, 1), nil, FBrushLeftBg),
      'CreateSolidColorBrush FBrushLeftBg'
    );

  if not Assigned(FBrushMonthBg1) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF($F5 / 255, $F5 / 255, $F5 / 255, 1), nil, FBrushMonthBg1),
      'CreateSolidColorBrush FBrushMonthBg1'
    );

  if not Assigned(FBrushMonthBg2) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF($EF / 255, $EF / 255, $EF / 255, 1), nil, FBrushMonthBg2),
      'CreateSolidColorBrush FBrushMonthBg2'
    );

  if not Assigned(FBrushWeekBg) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF($E9 / 255, $E9 / 255, $E9 / 255, 1), nil, FBrushWeekBg),
      'CreateSolidColorBrush FBrushWeekBg'
    );

  if not Assigned(FBrushWeekendBg) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF($E9 / 255, $E9 / 255, $E9 / 255, 1), nil, FBrushWeekendBg),
      //FHwndRT.CreateSolidColorBrush(D2D1ColorF($FA / 255, $FA / 255, $FA / 255, 1), nil, FBrushWeekendBg),
      'CreateSolidColorBrush FBrushWeekendBg'
    );

  if not Assigned(FBrushGridMajor) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF($BE / 255, $BE / 255, $BE / 255, 1), nil, FBrushGridMajor),
      'CreateSolidColorBrush FBrushGridMajor'
    );

  if not Assigned(FBrushGridMinor) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF($DD / 255, $DD / 255, $DD / 255, 1), nil, FBrushGridMinor),
      'CreateSolidColorBrush FBrushGridMinor'
    );

  if not Assigned(FBrushBorder) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF($C9 / 255, $C9 / 255, $C9 / 255, 1), nil, FBrushBorder),
      'CreateSolidColorBrush FBrushBorder'
    );

  if not Assigned(FBrushTextMain) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF($33 / 255, $33 / 255, $33 / 255, 1), nil, FBrushTextMain),
      'CreateSolidColorBrush FBrushTextMain'
    );

  if not Assigned(FBrushTextSecondary) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2D1ColorF($66 / 255, $66 / 255, $66 / 255, 1), nil, FBrushTextSecondary),
      'CreateSolidColorBrush FBrushTextSecondary'
    );
end;

procedure TGanttTimelineControl.CreateDeviceResources;
var
  RTProps: TD2D1RenderTargetProperties;
  HwndProps: TD2D1HwndRenderTargetProperties;
begin
  if Assigned(FHwndRT) then
    Exit;
  InitD2D;
  RTProps := D2D1RenderTargetProperties(
    D2D1_RENDER_TARGET_TYPE_DEFAULT,
    D2D1PixelFormat(DXGI_FORMAT_UNKNOWN, D2D1_ALPHA_MODE_IGNORE),
    0,
    0,
    D2D1_RENDER_TARGET_USAGE_NONE,
    D2D1_FEATURE_LEVEL_DEFAULT
  );
  HwndProps := D2D1HwndRenderTargetProperties(
    Handle,
    D2D1SizeU(ClientWidth, ClientHeight),
    D2D1_PRESENT_OPTIONS_IMMEDIATELY
  );
  CheckHR(
    FD2DFactory.CreateHwndRenderTarget(RTProps, HwndProps, FHwndRT),
    'CreateHwndRenderTarget'
  );

end;

procedure TGanttTimelineControl.DiscardDeviceResources;
begin
  FBrushBg := nil;
  FBrushLeftBg := nil;
  FBrushMonthBg1 := nil;
  FBrushMonthBg2 := nil;
  FBrushWeekBg := nil;
  FBrushWeekendBg := nil;
  FBrushGridMajor := nil;
  FBrushGridMinor := nil;
  FBrushBorder := nil;
  FBrushTextMain := nil;
  FBrushTextSecondary := nil;

  FTextFmtMonth := nil;
  FTextFmtWeek := nil;
  FTextFmtTick := nil;

  FHwndRT := nil;
end;

procedure TGanttTimelineControl.ResizeRenderTarget;
var
  Sz: TD2D1SizeU;
begin
  if Assigned(FHwndRT) then
  begin
    Sz := D2D1SizeU(ClientWidth, ClientHeight);
    FHwndRT.Resize(Sz);
  end;
end;


procedure TGanttTimelineControl.SetViewAt(const AView: TTimelineView;
  const ARefTime: TDateTime; const AHours: Single = 8);
const
  SIDE_MARGIN_RATIO = 0.04; // 4% per banda
var
  xCenter: Integer;
  viewStart, viewEnd: TDateTime;
  viewCenter: TDateTime;
  minutesVisible: Double;
  px: Single;
  newScroll: Single;
  sideMarginPx: Integer;
  usableWidth: Integer;
begin
  if ClientWidth <= 1 then
    Exit;

  xCenter := ClientWidth div 2;

  case AView of
    tvHours:
      begin
        minutesVisible := EnsureRange(AHours * 60.0, 1.0, 30.0 * 24.0 * 60.0);
        viewStart := ARefTime - (minutesVisible / 2.0) / (24.0 * 60.0);
        viewEnd   := ARefTime + (minutesVisible / 2.0) / (24.0 * 60.0);
      end;

    tvDay:
      begin
        viewStart := DateOf(ARefTime);
        viewEnd   := IncDay(viewStart, 1);
      end;

    tvWeek:
      begin
        viewStart := StartOfTheWeek(ARefTime);
        viewEnd   := IncDay(viewStart, 7);
      end;

    tvMonth:
      begin
        viewStart := EncodeDate(YearOf(ARefTime), MonthOf(ARefTime), 1);
        viewEnd   := IncMonth(viewStart, 1);
      end;
  else
      begin
        viewStart := DateOf(ARefTime);
        viewEnd   := IncDay(viewStart, 1);
      end;
  end;

  viewCenter := viewStart + ((viewEnd - viewStart) / 2);

  minutesVisible := (viewEnd - viewStart) * 24.0 * 60.0;
  if minutesVisible <= 0 then
    Exit;

  sideMarginPx := Round(ClientWidth * SIDE_MARGIN_RATIO);
  usableWidth := ClientWidth - sideMarginPx * 2;
  if usableWidth < 20 then
    usableWidth := ClientWidth;

  px := usableWidth / minutesVisible;
  FPxPerMinute := ClampPxPerMinute(px);

  newScroll := (VisibleMinutesBetween(FStartTime, viewCenter) * FPxPerMinute) - xCenter;
  FScrollX := ClampScrollX(newScroll);

  NotifyViewportChanged;
  Invalidate;
end;


procedure TGanttTimelineControl.SetView(const AView: TTimelineView; const AHours: Single = 8);
var
  daysVisible: Single;
  px: Single;
  xCenter: Integer;
  tCenter: TDateTime;
  newScroll: Single;
begin
  if ClientWidth <= 1 then
    Exit;

  // 1) agafa el temps que ara mateix està al centre visible
  xCenter := ClientWidth div 2;
  tCenter := XToTime(xCenter);

  // 2) defineix quants dies vols visibles segons el preset
  case AView of
    tvHours:
      daysVisible := EnsureRange(AHours / 24.0, 0.01, 30.0);
    tvDay:
      daysVisible := 1.0;
    tvWeek:
      daysVisible := 7.0;
    tvMonth:
      daysVisible := 31.0;
  else
    daysVisible := 1.0;
  end;

  // 3) calcula escala perquè càpiga daysVisible a ClientWidth
  px := ClientWidth / (daysVisible * 24 * 60);
  FPxPerMinute := ClampPxPerMinute(px);

  // 4) recalcula scroll perquè tCenter quedi EXACTE al centre
  // screenX(t) = ((t - FStartTime)*minuts)*FPxPerMinute - FScrollX
  // volem screenX(tCenter)=xCenter => FScrollX = ... - xCenter
  newScroll := (VisibleMinutesBetween(FStartTime, tCenter) * FPxPerMinute) - xCenter;
  FScrollX := ClampScrollX(newScroll);

  NotifyViewportChanged;
  Invalidate;

end;


function TGanttTimelineControl.D2DColor(const C: TColor; const A: Single): TD2D1ColorF;
var
  RGB: COLORREF;
begin
  RGB := ColorToRGB(C);
  Result := D2D1ColorF(
    GetRValue(RGB) / 255,
    GetGValue(RGB) / 255,
    GetBValue(RGB) / 255,
    A
  );
end;


procedure TGanttTimelineControl.FillRectD(const R: TRectF; const Brush: ID2D1Brush);
begin
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;
  FHwndRT.FillRectangle(D2D1RectF(R.Left, R.Top, R.Right, R.Bottom), Brush);
end;
procedure TGanttTimelineControl.DrawLineD(const X1, Y1, X2, Y2: Single; const Brush: ID2D1Brush; const Stroke: Single);
begin
  FHwndRT.DrawLine(
    D2D1PointF(X1 + 0.5, Y1 + 0.5),
    D2D1PointF(X2 + 0.5, Y2 + 0.5),
    Brush,
    Stroke
  );
end;
procedure TGanttTimelineControl.DrawTextD(const S: string; const R: TRectF;
  const Fmt: IDWriteTextFormat; const Brush: ID2D1Brush; const CenterHoriz: Boolean);
var
  DR: TD2D1RectF;
begin
  if S = '' then Exit;
  if not Assigned(FHwndRT) then Exit;
  if not Assigned(Fmt) then Exit;
  if not Assigned(Brush) then Exit;
  if R.Right <= R.Left then Exit;
  if R.Bottom <= R.Top then Exit;
  if CenterHoriz then
    Fmt.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER)
  else
    Fmt.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_LEADING);
  DR.Left := R.Left;
  DR.Top := R.Top;
  DR.Right := R.Right;
  DR.Bottom := R.Bottom;
  FHwndRT.DrawText(
    PChar(S),
    Length(S),
    Fmt,
    DR,
    Brush,
    D2D1_DRAW_TEXT_OPTIONS_CLIP,
    DWRITE_MEASURING_MODE_NATURAL
  );
end;




function TGanttTimelineControl.HitTestBand(const Y: Integer): TTimelineBand;
begin
  if (Y >= 0) and (Y < ROW_MONTH_H) then
    Exit(tbMonth);
  if (Y >= ROW_MONTH_H) and (Y < ROW_MONTH_H + ROW_WEEK_H) then
    Exit(tbWeek);
  if (Y >= ROW_MONTH_H + ROW_WEEK_H) and (Y < ROW_TOTAL_H) then
    Exit(tbDayOrHour);
  Result := tbNone;
end;

procedure TGanttTimelineControl.ZoomToRange(const AStart, AEnd: TDateTime);
var
  MinutesVisible: Double;
  UsableWidth: Integer;
  NewPxPerMinute: Single;
  MarginMin: Double;
begin
  if AEnd <= AStart then
    Exit;

  UsableWidth := ClientWidth - FLeftWidth;
  if UsableWidth <= 10 then
    Exit;

  MinutesVisible := (AEnd - AStart) * 24 * 60;
  if MinutesVisible <= 0 then
    Exit;

  MarginMin := MinutesVisible * 0.02;

  NewPxPerMinute := UsableWidth / (MinutesVisible + MarginMin * 2);

  if NewPxPerMinute < 0.001 then
    NewPxPerMinute := 0.001;
  if NewPxPerMinute > 20 then
    NewPxPerMinute := 20;

  FStartTime := AStart - (MarginMin / (24 * 60));
  FPxPerMinute := NewPxPerMinute;

  if Assigned(FOnViewportChanged) then
    FOnViewportChanged(Self, FStartTime, FPxPerMinute, 0);

  Invalidate;
end;

procedure TGanttTimelineControl.ZoomToBandAt(const AX, AY: Integer);
var
  Band: TTimelineBand;
  T: TDateTime;
begin
  if AX < FLeftWidth then
    Exit;
  Band := HitTestBand(AY);
  if Band = tbNone then
    Exit;
  T := XToTime(AX);
  case Band of
    tbMonth:
      SetViewAt(tvMonth, T);
    tbWeek:
      SetViewAt(tvWeek, T);
    tbDayOrHour:
      SetViewAt(tvDay, T);
  end;
end;


function TGanttTimelineControl.MonthNameES(const M: Integer): string;
const
  Names: array[1..12] of string = (
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  );
begin
  Result := Names[M];
end;

function TGanttTimelineControl.WeekdayNameES(const D: TDateTime): string;
const
  Names: array[1..7] of string = (
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  );
begin
  Result := Names[DayOfTheWeek(D)];
end;

function TGanttTimelineControl.StartOfMonthEx(const T: TDateTime): TDateTime;
begin
  Result := EncodeDate(YearOf(T), MonthOf(T), 1);
end;

function TGanttTimelineControl.StartOfWeekMonday(const T: TDateTime): TDateTime;
begin
  Result := StartOfTheWeek(T);
end;

function TGanttTimelineControl.CeilToHourStep(const T: TDateTime; const StepHours: Integer): TDateTime;
var
  Base: TDateTime;
  H: Integer;
begin
  Base := EncodeDateTime(YearOf(T), MonthOf(T), DayOf(T), HourOf(T), 0, 0, 0);
  H := HourOf(Base);
  H := (H div StepHours) * StepHours;
  Result := EncodeDateTime(YearOf(Base), MonthOf(Base), DayOf(Base), H, 0, 0, 0);
  if Result < T then
    Result := IncHour(Result, StepHours);
end;

function TGanttTimelineControl.CeilToDayStep(const T: TDateTime; const StepDays: Integer): TDateTime;
var
  D: TDateTime;
  DayIndex: Integer;
begin
  D := DateOf(T);
  DayIndex := DayOfTheMonth(D) - 1;
  DayIndex := (DayIndex div StepDays) * StepDays;
  Result := EncodeDate(YearOf(D), MonthOf(D), 1);
  Result := IncDay(Result, DayIndex);
  if Result < D then
    Result := IncDay(Result, StepDays);
end;

function TGanttTimelineControl.ChooseHourStep: Integer;
var
  PxPerHour: Single;
begin
  PxPerHour := FPxPerMinute * 60;

  if PxPerHour >= 90 then Exit(1);
  if PxPerHour >= 55 then Exit(2);
  if PxPerHour >= 36 then Exit(3);
  if PxPerHour >= 26 then Exit(4);
  if PxPerHour >= 18 then Exit(6);
  if PxPerHour >= 12 then Exit(8);
  Result := 12;
end;

function TGanttTimelineControl.ChooseDayStep: Integer;
var
  PxPerDay: Single;
begin
  PxPerDay := FPxPerMinute * 24 * 60;

  if PxPerDay >= 90 then Exit(1);
  if PxPerDay >= 50 then Exit(2);
  if PxPerDay >= 34 then Exit(3);
  if PxPerDay >= 22 then Exit(5);
  Result := 7;
end;

function TGanttTimelineControl.FormatMonthLabelES(const D: TDateTime): string;
begin
  Result := MonthNameES(MonthOf(D)) + ' ' + FormatDateTime('yy', D);
end;

function TGanttTimelineControl.FormatWeekLabelLong(const D: TDateTime): string;
begin
  Result := 'Setmana ' + IntToStr(WeekOfTheYear(D)) + ', ' +
            WeekdayNameES(D) + ' ' + IntToStr(DayOfTheMonth(D));
end;

function TGanttTimelineControl.FormatWeekLabelShort(const D: TDateTime): string;
begin
  Result := 'Setmana ' + IntToStr(WeekOfTheYear(D)) + ', M' +
            IntToStr(DayOfTheMonth(D));
end;


function TGanttTimelineControl.VisibleSpanDays: Double;
begin
  Result := GetEndVisibleTime - GetStartVisibleTime;
end;

function TGanttTimelineControl.ScaleOverOneWeek: Boolean;
begin
  Result := VisibleSpanDays > 7.0; // “més d’1 setmana visible”
end;

procedure TGanttTimelineControl.BeginInteraction;
begin
  if FInteracting then Exit;
  FInteracting := True;
  if Assigned(FOnInteraction) then
    FOnInteraction(Self, True);
end;

procedure TGanttTimelineControl.ArmSettleTimer;
begin
  // re-arm
  KillTimer(Handle, IDT_SETTLE);
  SetTimer(Handle, IDT_SETTLE, SETTLE_MS, nil);
  FSettleTimerActive := True;
end;

procedure TGanttTimelineControl.EndInteraction;
begin
  if not FInteracting then Exit;
  FInteracting := False;
  if Assigned(FOnInteraction) then
    FOnInteraction(Self, False);
  // força el repaint final (1 cop)
  if Assigned(FOnNeedRepaint) then
    FOnNeedRepaint(Self);
end;


procedure TGanttTimelineControl.Paint;
begin
  PaintD2D;
end;


procedure TGanttTimelineControl.PaintD2D;
var
  hr: HRESULT;
  VisibleStart, VisibleEnd: TDateTime;
  VisibleDays: Double;
  ZoomShort: Boolean;
begin
  if csDestroying in ComponentState then Exit;
  if not HandleAllocated then Exit;
  if (ClientWidth <= 0) or (ClientHeight <= 0) then Exit;
  if FPxPerMinute <= 0 then Exit;

  CreateDeviceResources;
  if not Assigned(FHwndRT) then Exit;

  CreateBrushResources;
  CreateTextResources;

  VisibleStart := XToTime(FLeftWidth);
  VisibleEnd   := XToTime(ClientWidth);
  VisibleDays  := VisibleEnd - VisibleStart;
  ZoomShort    := VisibleDays <= 3.0;

  OutputDebugString(PChar(
  Format('TIMELN Start=%s Scroll=%f Px=%f XToTime(0)=%s',
    [
      DateTimeToStr(FStartTime),
      FScrollX,
      FPxPerMinute,
      DateTimeToStr(XToTime(0))
    ])
));

  FHwndRT.BeginDraw;
  try
    FHwndRT.Clear(D2D1ColorF(1, 1, 1, 1));

    FillRectD(RectF(0, 0, FLeftWidth, ClientHeight), FBrushLeftBg);
    DrawLineD(FLeftWidth, 0, FLeftWidth, ClientHeight, FBrushBorder);
    DrawLineD(FLeftWidth, ROW_MONTH_H, ClientWidth, ROW_MONTH_H, FBrushBorder);
    DrawLineD(FLeftWidth, ROW_MONTH_H + ROW_WEEK_H, ClientWidth, ROW_MONTH_H + ROW_WEEK_H, FBrushBorder);
    DrawLineD(0, ROW_TOTAL_H - 1, ClientWidth, ROW_TOTAL_H - 1, FBrushBorder);

    DrawMonthRow(VisibleStart, VisibleEnd);

    if ZoomShort then
    begin
      DrawDayHeaderRow(VisibleStart, VisibleEnd);
      DrawBottomRowHours(VisibleStart, VisibleEnd);
    end
    else
    begin
      DrawWeekRowGrouped(VisibleStart, VisibleEnd);
      DrawBottomRowDaysLabeled(VisibleStart, VisibleEnd);
    end;

    hr := FHwndRT.EndDraw;
    if hr = D2DERR_RECREATE_TARGET then
      DiscardDeviceResources
    else
      CheckHR(hr, 'EndDraw');
  except
    FHwndRT.EndDraw;
    raise;
  end;
end;


procedure TGanttTimelineControl.FillMiddleBandBackground;
var
  R: TRectF;
begin
  if not Assigned(FHwndRT) then Exit;
  if not Assigned(FBrushWeekBg) then Exit;
  R.Left := FLeftWidth;
  R.Top := ROW_MONTH_H;
  R.Right := ClientWidth;
  R.Bottom := ROW_MONTH_H + ROW_WEEK_H;
  FillRectD(R, FBrushWeekBg);
end;

function TGanttTimelineControl.GetViewportStartTime: TDateTime;
begin
  Result := AddVisibleMinutes(FStartTime, FScrollX / FPxPerMinute);
end;
function TGanttTimelineControl.GetViewportEndTime: TDateTime;
var
  VisibleMins: Double;
begin
  VisibleMins := ClientWidth / FPxPerMinute;
  Result := AddVisibleMinutes(GetViewportStartTime, VisibleMins);
end;


procedure TGanttTimelineControl.DrawMonthRow(const VisibleStart, VisibleEnd: TDateTime);
var
  M, MNext: TDateTime;
  X1, X2: Single;
  R: TRectF;
  Txt: string;
  UseAlt: Boolean;
  MonthStartVisible: TDateTime;
begin
  if not Assigned(FHwndRT) then Exit;
  if not Assigned(FBrushMonthBg1) then Exit;
  if not Assigned(FBrushMonthBg2) then Exit;
  if not Assigned(FBrushGridMajor) then Exit;

  M := StartOfMonthEx(VisibleStart);
  UseAlt := False;

  while M <= VisibleEnd do
  begin
    MNext := IncMonth(M, 1);

    MonthStartVisible := M;
    if FHideWeekends then
      while IsWeekend(MonthStartVisible) and (MonthStartVisible < MNext) do
        MonthStartVisible := IncDay(MonthStartVisible);

    X1 := TimeToX(MonthStartVisible);
    X2 := TimeToX(MNext);

    R.Left := Max(FLeftWidth, X1);
    R.Top := 0;
    R.Right := Min(ClientWidth, X2);
    R.Bottom := ROW_MONTH_H;

    if R.Right > R.Left then
    begin
      if UseAlt then
        FillRectD(R, FBrushMonthBg1)
      else
        FillRectD(R, FBrushMonthBg2);

      Txt := FormatMonthLabelES(M);
      DrawTextD(Txt, R, FTextFmtMonth, FBrushTextMain, True);
    end;

    if (X1 >= FLeftWidth) and (X1 < ClientWidth) then
      DrawLineD(X1, 0, X1, ClientHeight, FBrushGridMajor);

    UseAlt := not UseAlt;
    M := MNext;
  end;
end;

procedure TGanttTimelineControl.DrawWeekRow(const VisibleStart, VisibleEnd: TDateTime;
  const ZoomShort: Boolean);
var
  W, WNext: TDateTime;
  X1, X2: Single;
  R: TRectF;
  Txt: string;
begin
  if not Assigned(FHwndRT) then Exit;
  if not Assigned(FBrushWeekBg) then Exit;
  if not Assigned(FBrushGridMajor) then Exit;

  W := StartOfWeekMonday(VisibleStart);

  while W <= VisibleEnd do
  begin
    WNext := IncWeek(W, 1);

    X1 := TimeToX(W);
    X2 := TimeToX(WNext);

    R.Left := Max(FLeftWidth, X1);
    R.Top := ROW_MONTH_H;
    R.Right := Min(ClientWidth, X2);
    R.Bottom := ROW_MONTH_H + ROW_WEEK_H;

    if R.Right > R.Left then
    begin
      FillRectD(R, FBrushWeekBg);

      if ZoomShort then
        Txt := FormatWeekLabelLong(W)
      else
        Txt := FormatWeekLabelShort(W);

      DrawTextD(Txt, R, FTextFmtWeek, FBrushTextMain, True);
    end;

    if (X1 >= FLeftWidth) and (X1 <= ClientWidth) then
      DrawLineD(X1, ROW_MONTH_H, X1, ClientHeight, FBrushGridMajor);

    W := WNext;
  end;
end;



procedure TGanttTimelineControl.DrawWeekRowGrouped(const VisibleStart, VisibleEnd: TDateTime);
var
  W, WNext: TDateTime;
  X1, X2: Single;
  R: TRectF;
  Txt: string;
begin
  if not Assigned(FHwndRT) then Exit;
  if not Assigned(FBrushWeekBg) then Exit;
  if not Assigned(FBrushGridMajor) then Exit;

  W := StartOfWeekMonday(VisibleStart);

  while W <= VisibleEnd do
  begin
    WNext := IncWeek(W, 1);

    X1 := TimeToX(W);
    X2 := TimeToX(WNext);

    R.Left := Max(FLeftWidth, X1);
    R.Top := ROW_MONTH_H;
    R.Right := Min(ClientWidth, X2);
    R.Bottom := ROW_MONTH_H + ROW_WEEK_H;

    if R.Right > R.Left then
    begin
      FillRectD(R, FBrushWeekBg);

      Txt := 'Setmana ' + IntToStr(WeekOfTheYear(W));
      DrawTextD(Txt, R, FTextFmtWeek, FBrushTextMain, True);
    end;

    if (X1 >= FLeftWidth) and (X1 < ClientWidth) then
      DrawLineD(X1, ROW_MONTH_H, X1, ClientHeight, FBrushGridMajor);

    W := WNext;
  end;
end;


procedure TGanttTimelineControl.DrawRectD(const R: TRectF; const Brush: ID2D1Brush;
  const Stroke: Single = 1.0);
var
  DR: TD2D1RectF;
begin
  if not Assigned(FHwndRT) then Exit;
  if not Assigned(Brush) then Exit;
  if R.Right <= R.Left then Exit;
  if R.Bottom <= R.Top then Exit;
  DR.Left := R.Left + 0.5;
  DR.Top := R.Top + 0.5;
  DR.Right := R.Right - 0.5;
  DR.Bottom := R.Bottom - 0.5;
  FHwndRT.DrawRectangle(DR, Brush, Stroke);
end;

procedure TGanttTimelineControl.DrawDayHeaderRow(const VisibleStart, VisibleEnd: TDateTime);
var
  D, DNext: TDateTime;
  X1, X2: Single;
  R: TRectF;
  Txt: string;
  Dow: Integer;
begin
  if not Assigned(FHwndRT) then Exit;
  if not Assigned(FBrushWeekBg) then Exit;
  if not Assigned(FBrushGridMajor) then Exit;
  if not Assigned(FBrushBorder) then Exit;

  D := DateOf(VisibleStart);

  while D <= VisibleEnd do
  begin
    DNext := IncDay(D, 1);

    if HideWeekends and IsWeekend(D) then
    begin
      D := DNext;
      Continue;
    end;

    X1 := TimeToX(D);
    X2 := TimeToX(DNext);

    R.Left := Max(FLeftWidth, X1);
    R.Top := ROW_MONTH_H;
    R.Right := Min(ClientWidth, X2);
    R.Bottom := ROW_MONTH_H + ROW_WEEK_H;

    if R.Right > R.Left then
    begin
      FillRectD(R, FBrushWeekBg);

      Dow := DayOfTheWeek(D);
      if Assigned(FBrushWeekendBg) and (not HideWeekends) and ((Dow = 6) or (Dow = 7)) then
        FillRectD(R, FBrushWeekendBg);

      Txt := WeekdayNameES(D) + ' ' + IntToStr(DayOfTheMonth(D));
      DrawTextD(Txt, R, FTextFmtWeek, FBrushTextMain, True);

      DrawRectD(R, FBrushBorder, 1.0);
    end;

    if (X1 >= FLeftWidth) and (X1 < ClientWidth) then
      DrawLineD(X1, ROW_MONTH_H, X1, ClientHeight, FBrushGridMajor);

    D := DNext;
  end;
end;

procedure TGanttTimelineControl.DrawBottomRowDaysLabeled(const VisibleStart, VisibleEnd: TDateTime);
var
  D, DNext: TDateTime;
  X1, X2: Single;
  R: TRectF;
  Txt: string;
  Dow: Integer;
begin
  if not Assigned(FHwndRT) then Exit;
  if not Assigned(FBrushGridMinor) then Exit;
  if not Assigned(FBrushBorder) then Exit;

  D := DateOf(VisibleStart);

  while D <= VisibleEnd do
  begin
    DNext := IncDay(D, 1);

    if HideWeekends and IsWeekend(D) then
    begin
      D := DNext;
      Continue;
    end;

    X1 := TimeToX(D);
    X2 := TimeToX(DNext);

    R.Left := Max(FLeftWidth, X1);
    R.Top := ROW_MONTH_H + ROW_WEEK_H;
    R.Right := Min(ClientWidth, X2);
    R.Bottom := ROW_TOTAL_H;

    if R.Right > R.Left then
    begin
      Dow := DayOfTheWeek(D);

      if Assigned(FBrushWeekendBg) and (not HideWeekends) and ((Dow = 6) or (Dow = 7)) then
        FillRectD(R, FBrushWeekendBg);

      Txt := WeekdayShortES(D) + ' ' + IntToStr(DayOfTheMonth(D));
      DrawTextD(Txt, R, FTextFmtTick, FBrushTextSecondary, True);

      DrawRectD(R, FBrushBorder, 1.0);
    end;

    if (X1 >= FLeftWidth) and (X1 < ClientWidth) then
      DrawLineD(X1, ROW_MONTH_H + ROW_WEEK_H, X1, ClientHeight, FBrushGridMinor);

    D := DNext;
  end;
end;


procedure TGanttTimelineControl.DrawBottomRowDays(const VisibleStart, VisibleEnd: TDateTime);
var
  D, DNext: TDateTime;
  X1, X2: Single;
  R: TRectF;
  Txt: string;
  Dow: Integer;
begin
  if not Assigned(FHwndRT) then Exit;
  if not Assigned(FBrushGridMinor) then Exit;

  D := DateOf(VisibleStart);
  if D < VisibleStart then
    D := IncDay(D, 1);

  while D <= VisibleEnd do
  begin
    DNext := IncDay(D, 1);

    X1 := TimeToX(D);
    X2 := TimeToX(DNext);

    R.Left := Max(FLeftWidth, X1);
    R.Top := ROW_MONTH_H + ROW_WEEK_H;
    R.Right := Min(ClientWidth, X2);
    R.Bottom := ROW_TOTAL_H;

    Dow := DayOfTheWeek(D);
    if Assigned(FBrushWeekendBg) and ((Dow = 6) or (Dow = 7)) and (R.Right > R.Left) then
      FillRectD(R, FBrushWeekendBg);

    Txt := FormatDateTime('dd', D);
    DrawTextD(Txt, R, FTextFmtTick, FBrushTextSecondary, True);

    if (X1 >= FLeftWidth) and (X1 <= ClientWidth) then
      DrawLineD(X1, ROW_MONTH_H + ROW_WEEK_H, X1, ClientHeight, FBrushGridMinor);

    D := DNext;
  end;
end;


procedure TGanttTimelineControl.DrawBottomRowHours(const VisibleStart, VisibleEnd: TDateTime);
var
  H, HNext: TDateTime;
  X1, X2: Single;
  R: TRectF;
  Txt: string;
  Midnight: Boolean;
begin
  if not Assigned(FHwndRT) then Exit;
  if not Assigned(FBrushGridMinor) then Exit;
  if not Assigned(FBrushGridMajor) then Exit;

  H := EncodeDateTime(
         YearOf(VisibleStart), MonthOf(VisibleStart), DayOf(VisibleStart),
         HourOf(VisibleStart), 0, 0, 0
       );
  if H < VisibleStart then
    H := IncHour(H, 1);

  while H <= VisibleEnd do
  begin
    HNext := IncHour(H, 1);

    if HideWeekends and IsWeekend(H) then
    begin
      H := HNext;
      Continue;
    end;

    X1 := TimeToX(H);
    X2 := TimeToX(HNext);

    R.Left := Max(FLeftWidth, X1);
    R.Top := ROW_MONTH_H + ROW_WEEK_H;
    R.Right := Min(ClientWidth, X2);
    R.Bottom := ROW_TOTAL_H;

    Midnight := HourOf(H) = 0;

    if R.Right > R.Left then
    begin
      if Midnight then
        Txt := FormatDateTime('dd hh:nn', H)
      else
        Txt := FormatDateTime('hh:nn', H);

      DrawTextD(Txt, R, FTextFmtTick, FBrushTextSecondary, True);
    end;

    if (X1 >= FLeftWidth) and (X1 < ClientWidth) then
    begin
      if Midnight then
        DrawLineD(X1, 0, X1, ClientHeight, FBrushGridMajor)
      else
        DrawLineD(X1, ROW_MONTH_H + ROW_WEEK_H, X1, ClientHeight, FBrushGridMinor);
    end;

    H := HNext;
  end;
end;


procedure TGanttTimelineControl.SetViewport(const AStartTime: TDateTime; const APxPerMinute, AScrollX: Single);
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
  //FPxPerMinute := APxPerMinute;
  FPxPerMinute := ClampPxPerMinute(APxPerMinute);
 // FScrollX := Max(0, AScrollX);
  FScrollX := ClampScrollX(AScrollX);

  BeginInteraction;
  ArmSettleTimer;

  Invalidate;
end;

function TGanttTimelineControl.GetStartVisibleTime: TDateTime;
var
  minutesFromStart: Double;
begin
  minutesFromStart := FScrollX / FPxPerMinute;
  Result := AddVisibleMinutes(FStartTime, minutesFromStart);
end;

function TGanttTimelineControl.GetEndVisibleTime: TDateTime;
var
  minutesFromStart: Double;
begin
  minutesFromStart := (FScrollX + ClientWidth) / FPxPerMinute;
  Result := AddVisibleMinutes(FStartTime, minutesFromStart);
end;

function TGanttTimelineControl.CalcScrollXToCenterDate(const ADate: TDateTime): Single;
var
  minutesFromStart: Double;
  xCenter: Single;
begin
  xCenter := ClientWidth * 0.5;
  minutesFromStart := VisibleMinutesBetween(FStartTime, ADate);
  Result := (minutesFromStart * FPxPerMinute) - xCenter;
  Result := ClampScrollX(Result);
end;

procedure TGanttTimelineControl.CenterOnDate(const ADate: TDateTime);
begin
  FScrollX := CalcScrollXToCenterDate(ADate);
  NotifyViewportChanged;
  Invalidate;
end;

procedure TGanttTimelineControl.StartScrollInvalidateTimer;
begin
  if FPanTimerActive then Exit;
  SetTimer(Handle, IDT_PAN_INVALIDATE, PAN_TIMER_MS, nil);
  FPanTimerActive := True;
end;
procedure TGanttTimelineControl.StopScrollInvalidateTimer;
begin
  if not FPanTimerActive then Exit;
  KillTimer(Handle, IDT_PAN_INVALIDATE);
  FPanTimerActive := False;
end;

function TGanttTimelineControl.ClampPxPerMinute(const Value: Single): Single;
const
  MinDaysVisible = 0.1;
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

procedure TGanttTimelineControl.SetLeftWidth(const Value: Integer);
begin
  if Value <> FLeftWidth then
  begin
    FLeftWidth := Value;
    Invalidate;
  end;
end;

procedure TGanttTimelineControl.SetTimeRange(const AStart, AEnd: TDateTime);
begin
  FRangeStart := DayStart(AStart);
  FRangeEnd   := DayEnd(AEnd);
  // Coherent: el "world 0" del timeline és el rang start
  FStartTime := FRangeStart;
  FEndTime := FRangeEnd;
  FScrollX := ClampScrollX(FScrollX);
  Invalidate;
end;

function TGanttTimelineControl.MaxScrollX: Single;
var
  totalMinutes: Double;
  contentWidth: Single;
begin
  if (FRangeEnd <= FRangeStart) or (ClientWidth <= 1) then
    Exit(0);

  totalMinutes := VisibleMinutesBetween(FRangeStart, FRangeEnd);
  contentWidth := totalMinutes * FPxPerMinute;   // world width (px)

  // max scroll perquè el final quedi dins pantalla
  Result := Max(0, contentWidth - ClientWidth);
end;

function TGanttTimelineControl.ClampScrollX(const Value: Single): Single;
begin
  Result := EnsureRange(Value, 0, MaxScrollX);
end;


procedure TGanttTimelineControl.SetStartTime(const Value: TDateTime);
begin
  if Value <> FStartTime then
  begin
    FStartTime := Value;
    NormalizeStartTime;
    NotifyViewportChanged;
    Invalidate;
  end;
end;

procedure TGanttTimelineControl.SetPxPerMinute(const Value: Single);
begin
  if Value <> FPxPerMinute then
  begin
    //FPxPerMinute := Value;
    FPxPerMinute := ClampPxPerMinute(Value);
    NotifyViewportChanged;
    Invalidate;
  end;
end;

procedure TGanttTimelineControl.SetScrollX(const Value: Single);
begin
  if Value <> FScrollX then
  begin
    //FScrollX := Max(0, Value);
    FScrollX := ClampScrollX(Value);
    NotifyViewportChanged;
    Invalidate;
  end;
end;


function TGanttTimelineControl.VisibleMinutesBetween(
  const AFromTime, AToTime: TDateTime): Double;
const
  MINS_PER_DAY = 24 * 60;
  MINS_PER_WEEK_VISIBLE = 5 * MINS_PER_DAY;
var
  S, E: TDateTime;
  SDate, EDate: TDateTime;
  SegStart, SegEnd: TDateTime;
  WholeDays: Integer;
  WholeWeeks: Integer;
begin
  Result := 0;

  if AToTime <= AFromTime then
    Exit;

  if not FHideWeekends then
    Exit((AToTime - AFromTime) * MINS_PER_DAY);

  S := AFromTime;
  E := AToTime;

  SDate := DateOf(S);
  EDate := DateOf(E);

  // mateix dia
  if SDate = EDate then
  begin
    if not IsWeekend(SDate) then
      Result := (E - S) * MINS_PER_DAY;
    Exit;
  end;

  // primer dia parcial
  if not IsWeekend(SDate) then
  begin
    SegStart := S;
    SegEnd := IncDay(SDate, 1);
    Result := Result + ((SegEnd - SegStart) * MINS_PER_DAY);
  end;

  // últim dia parcial
  if not IsWeekend(EDate) then
  begin
    SegStart := EDate;
    SegEnd := E;
    Result := Result + ((SegEnd - SegStart) * MINS_PER_DAY);
  end;

  // dies complets intermedis
  SDate := IncDay(SDate, 1);
  EDate := IncDay(EDate, -1);

  if SDate > EDate then
    Exit;

  // avancem fins dilluns, comptant els dies visibles solts
  while (SDate <= EDate) and (DayOfTheWeek(SDate) <> 1) do
  begin
    if not IsWeekend(SDate) then
      Result := Result + MINS_PER_DAY;
    SDate := IncDay(SDate);
  end;

  // ara fem setmanes completes de cop
  WholeDays := DaysBetween(SDate, EDate) + 1;
  if WholeDays >= 7 then
  begin
    WholeWeeks := WholeDays div 7;
    Result := Result + (WholeWeeks * MINS_PER_WEEK_VISIBLE);
    SDate := IncDay(SDate, WholeWeeks * 7);
  end;

  // dies restants
  while SDate <= EDate do
  begin
    if not IsWeekend(SDate) then
      Result := Result + MINS_PER_DAY;
    SDate := IncDay(SDate);
  end;
end;


function TGanttTimelineControl.AddVisibleMinutes(
  const AStart: TDateTime; const AVisibleMinutes: Double): TDateTime;
const
  MINS_PER_DAY = 24 * 60;
var
  Remaining: Double;
  D: TDateTime;
  DayStart, DayEnd: TDateTime;
  Avail: Double;
begin
  if not FHideWeekends then
    Exit(AStart + (AVisibleMinutes / MINS_PER_DAY));

  Remaining := AVisibleMinutes;
  Result := AStart;

  D := DateOf(Result);

  // si comença en cap de setmana, saltem al següent dia visible
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

function TGanttTimelineControl.XToTime(const X: Single): TDateTime;
var
  VisibleMins: Double;
begin
  VisibleMins := ((X + FScrollX) - FLeftWidth) / FPxPerMinute;
  Result := AddVisibleMinutes(FStartTime, VisibleMins);
end;


procedure TGanttTimelineControl.NotifyViewportChanged;
begin
  if Assigned(FOnViewportChanged) then
    FOnViewportChanged(Self, FStartTime, FPxPerMinute, FScrollX);
end;

function TGanttTimelineControl.TimeToX(const T: TDateTime): Single;
var
  Mins: Double;
begin
  Mins := VisibleMinutesBetween(FStartTime, T);
  Result := FLeftWidth + (Mins * FPxPerMinute) - FScrollX;
end;




procedure TGanttTimelineControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  if Button = mbLeft then
  begin
    FIsPanning := True;
    FPanStart := Point(X, Y);
    FScrollStartX := FScrollX;
    FPendingScrollX := FScrollX;
    FHasPendingScroll := False;

    BeginInteraction;
    ArmSettleTimer;

    SetCapture(Handle);                 // importantíssim per suavitat
    StartScrollInvalidateTimer;
  end;

end;



procedure TGanttTimelineControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  dx, dy: Integer;
  newX, newY: Single;
begin
  inherited;
  if not FIsPanning then Exit;
  dx := X - FPanStart.X;
  dy := Y - FPanStart.Y;
  newX := ClampScrollX(FScrollStartX - dx);
  // només guardem el target (no NotifyViewportChanged ni Invalidate aquí)
  FPendingScrollX := newX;
  FHasPendingScroll := True;

  {if FIsPanning then
  begin
    //FScrollX := Max(0, FScrollStartX - (X - FPanStartX));
    FScrollX := ClampScrollX(FScrollStartX - (X - FPanStartX));
    NotifyViewportChanged;
    Invalidate;
  end;
  }
end;

procedure TGanttTimelineControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  if FIsPanning and (Button = mbLeft) then
  begin
    FIsPanning := False;
    ReleaseCapture;
    // aplica l’últim pending immediatament
    if FHasPendingScroll then
    begin
      FScrollX := FPendingScrollX;
      FHasPendingScroll := False;
      NotifyViewportChanged;
      Invalidate;
    end;

    BeginInteraction;
    ArmSettleTimer;

    StopScrollInvalidateTimer;
  end;
end;

procedure TGanttTimelineControl.WMTimer(var Message: TWMTimer);
begin

  if Message.TimerID = IDT_SETTLE then
  begin
    KillTimer(Handle, IDT_SETTLE);
    FSettleTimerActive := False;
    EndInteraction; // aquí és quan “s’ha aturat”
    Message.Result := 0;
    Exit;
  end;

  if Message.TimerID <> IDT_PAN_INVALIDATE then
  begin
    inherited;
    Exit;
  end;

  if not FIsPanning then
  begin

    StopScrollInvalidateTimer;
    Exit;
  end;

  if not FHasPendingScroll then Exit;

  // aplica només si hi ha canvi real (evita repintar de més)


  if (Abs(FPendingScrollX - FScrollX) > 0.01) then
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


procedure TGanttTimelineControl.WMLButtonDblClk(var Message: TWMLButtonDblClk);
var
  P: TPoint;
begin
  inherited;
  ZoomToBandAt(Message.XPos, Message.YPos);
end;

procedure TGanttTimelineControl.WMMouseWheel(var Message: TWMMouseWheel);
var
  pt: TPoint;
  xClient: Integer;
  tUnderCursor: TDateTime;
  newScroll: Single;
  zoomFactor: Single;
begin
  pt := ScreenToClient(Message.Pos);
  xClient := pt.X;

  // Si el wheel cau a la zona esquerra (noms centres), ignorem
  if xClient < FLeftWidth then
  begin
    Message.Result := 1;
    Exit;
  end;

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
  newScroll := (FLeftWidth + VisibleMinutesBetween(FStartTime, tUnderCursor) * FPxPerMinute) - xClient;
  //FScrollX := Max(0, newScroll);
  FScrollX := ClampScrollX(newScroll);

  BeginInteraction;
  ArmSettleTimer;
  NotifyViewportChanged;
  Invalidate;
  Message.Result := 1;

end;


end.

