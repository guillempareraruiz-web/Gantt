unit uGanttCentres;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.Classes, System.SysUtils, System.Types, System.Math,
  Vcl.Controls, Vcl.Graphics, uGanttTypes, Winapi.D2D1, Winapi.DxgiFormat;

type
  TCentreNameFunc = reference to function(const CentreId: Integer): string;
  TScrollYChangedEvent = procedure(Sender: TObject; const ScrollY: Single) of object;
  TCentresReorderedEvent = procedure(Sender: TObject; const NewOrderCentreIds: TArray<Integer>) of object;

  TCentreKPI = record
    TotalNodes: Integer;
    HoresOcupades: Double;
    HoresDisponibles: Double;
    TotalOperaris: Integer;
    PercentOcupacio: Double;
  end;

  TKPIRange = record
    MinInt: Integer;
    MaxInt: Integer;
    MinFloat: Double;
    MaxFloat: Double;
  end;


  TCentresKPIRanges = record
    Nodes: TKPIRange;
    Ocupades: TKPIRange;
    Disponibles: TKPIRange;
    Operaris: TKPIRange;
    PercentOcupacio: TKPIRange;
  end;


  TBadgeVisual = record
    FillColor: TColor;
    BorderColor: TColor;
  end;

  TCentreKPIFunc  = reference to function(const CentreId: Integer): TCentreKPI;

  TGanttCentresControl = class(TCustomControl)
  private
    FRows: TArray<TRowLayout>;
    FCentres: TArray<TCentreTreball>;
    FScrollY: Single;
    FOnScrollYChanged: TScrollYChangedEvent;
    FGetCentreName: TCentreNameFunc;


    // pan (drag vertical)
    FIsPanning: Boolean;
    FPanStartY: Integer;
    FScrollStartY: Single;

    FSelectedCentreId: Integer;

        // Drag reorder
    FDragArmed: Boolean;
    FDragging: Boolean;
    FDragStartPt: TPoint;
    FDragFromIndex: Integer;
    FDragHoverIndex: Integer;
    FOnCentresReordered: TCentresReorderedEvent;

    // nou
    FVerIndicadores: Boolean;
    FBaseWidth: Integer;
    FIndicadoresWidth: Integer;
    FGetCentreKPI: TCentreKPIFunc;
    FCurrentKPIRanges: TCentresKPIRanges;


    // D2D / DWrite
    FD2DFactory: ID2D1Factory;
    FDWriteFactory: IDWriteFactory;
    FHwndRT: ID2D1HwndRenderTarget;
    FBrushBg: ID2D1SolidColorBrush;
    FBrushRowEven: ID2D1SolidColorBrush;
    FBrushRowOdd: ID2D1SolidColorBrush;
    FBrushText: ID2D1SolidColorBrush;
    FBrushTextDisabled: ID2D1SolidColorBrush;
    FBrushLine: ID2D1SolidColorBrush;
    FBrushDrop: ID2D1SolidColorBrush;
    FBrushIndicatorBg: ID2D1SolidColorBrush;
    FBrushIndicatorBorder: ID2D1SolidColorBrush;
    FTextFormat: IDWriteTextFormat;
    FTextFormatSmall: IDWriteTextFormat;
    FTextFormatBadgeTitle: IDWriteTextFormat;
    FTextFormatBadgeValue: IDWriteTextFormat;

    procedure SetVerIndicadores(const Value: Boolean);
    procedure UpdateControlWidth;
    procedure SetIndicadoresWidth(const Value: Integer);
    function BuildKPIRanges: TCentresKPIRanges;

    procedure SetWidth(const Value: Integer);

    function HitTestRowIndex(const Y: Integer): Integer;
    function CalcDropIndex(const Y: Integer): Integer;
    procedure MoveRow(const FromIndex, ToIndex: Integer);
    procedure RecalcRowTops;
    function BuildCentreIdOrder: TArray<Integer>;


    procedure SetScrollY(const Value: Single);
    procedure NotifyScrollYChanged;

    function FindCentreIndexById(const CentreId: Integer): Integer;


    // D2D
    procedure CreateDeviceResources;
    procedure DiscardDeviceResources;
    procedure ResizeRenderTarget;
    procedure CreateTextResources;
    procedure CreateBrushResources;
    function GetClientPixelSize: TD2D1SizeU;
    function D2DColor(const C: TColor; const A: Single = 1.0): TD2D1ColorF;
    procedure FillRectD(const R: TRectF; const Brush: ID2D1Brush);
    procedure DrawLineD(const X1, Y1, X2, Y2: Single; const Brush: ID2D1Brush; const StrokeWidth: Single = 1.0);
    procedure DrawTextD(const S: string; const R: TRectF; const Brush: ID2D1Brush;
      const AFormat: IDWriteTextFormat);
    procedure PaintRowD2D(const RowIndex: Integer; const Row: TRowLayout);
    procedure PaintIndicatorsD2D(const RowIndex: Integer; const Row: TRowLayout;
      const LeftTextWidth: Single);

    procedure DrawBadgeD(const R: TRectF; const ATitle, AValue: string; const FillColor, BorderColor: TColor);

    procedure InitDWrite;
    procedure InitD2D;

  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateWnd; override;


    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
    function HitTestCentreId(const Y: Integer): Integer;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetCentres(const ACentres: TArray<TCentreTreball>);
    procedure SetRows(const ARows: TArray<TRowLayout>);
    property ScrollY: Single read FScrollY write SetScrollY;

    property GetCentreKPI: TCentreKPIFunc read FGetCentreKPI write FGetCentreKPI;
    property CurrentKPIRanges: TCentresKPIRanges read FCurrentKPIRanges write FCurrentKPIRanges;

    // per resoldre el text sense acoblar-te al model
    property GetCentreName: TCentreNameFunc read FGetCentreName write FGetCentreName;
    property SelectedCentreId: Integer read FSelectedCentreId;
    property OnScrollYChanged: TScrollYChangedEvent read FOnScrollYChanged write FOnScrollYChanged;
  published
    property PopupMenu;
    property Align;
    property Width default 220;
    property BaseWidth: Integer read FBaseWidth write SetWidth default 220;
    property IndicadoresWidth: Integer read FIndicadoresWidth write SetIndicadoresWidth default 225;
    property VerIndicadores: Boolean read FVerIndicadores write SetVerIndicadores default False;
    property OnCentresReordered: TCentresReorderedEvent read FOnCentresReordered write FOnCentresReordered;
  end;



const
  KPI_BLUE_FILL   = $00FFE6CC;
  KPI_BLUE_BORDER = $00CC9966;

  KPI_GREEN_FILL   = $00E3F3DF;
  KPI_GREEN_BORDER = $0078B569;
  KPI_RED_FILL     = $00E4E4FC;
  KPI_RED_BORDER   = $007A7AD0;

  KPI_TEXT = clBlack;


implementation

//...HELPER
procedure CheckHR(const Res: HRESULT; const Msg: string);
begin
  if Failed(Res) then
    raise EOSError.CreateFmt('%s. HRESULT=0x%.8x', [Msg, Cardinal(Res)]);
end;

function GetBadgeVisualInt(const Value, MinV, MaxV: Integer): TBadgeVisual;
begin
  if MinV = MaxV then
  begin
    Result.FillColor := KPI_BLUE_FILL;
    Result.BorderColor := KPI_BLUE_BORDER;
  end
  else if Value = MaxV then
  begin
    Result.FillColor := KPI_GREEN_FILL;
    Result.BorderColor := KPI_GREEN_BORDER;
  end
  else if Value = MinV then
  begin
    Result.FillColor := KPI_RED_FILL;
    Result.BorderColor := KPI_RED_BORDER;
  end
  else
  begin
    Result.FillColor := KPI_BLUE_FILL;
    Result.BorderColor := KPI_BLUE_BORDER;
  end;
end;

function GetBadgeVisualFloat(const Value, MinV, MaxV: Double): TBadgeVisual;
begin
  if SameValue(MinV, MaxV, 0.0001) then
  begin
    Result.FillColor := KPI_BLUE_FILL;
    Result.BorderColor := KPI_BLUE_BORDER;
  end
  else if SameValue(Value, MaxV, 0.0001) then
  begin
    Result.FillColor := KPI_GREEN_FILL;
    Result.BorderColor := KPI_GREEN_BORDER;
  end
  else if SameValue(Value, MinV, 0.0001) then
  begin
    Result.FillColor := KPI_RED_FILL;
    Result.BorderColor := KPI_RED_BORDER;
  end
  else
  begin
    Result.FillColor := KPI_BLUE_FILL;
    Result.BorderColor := KPI_BLUE_BORDER;
  end;
end;





constructor TGanttCentresControl.Create(AOwner: TComponent);
var
  Unk: IUnknown;
  hr: HRESULT;
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := False;

  FScrollY := 0;
  FSelectedCentreId := -1;

  FBaseWidth := 220;         // amplada normal
  FIndicadoresWidth := 225;  // extra per KPIs, ajustable
  FVerIndicadores := False;

  Width := FBaseWidth;

  FD2DFactory := nil;
  FDWriteFactory := nil;
  FHwndRT := nil;

end;


destructor TGanttCentresControl.Destroy;
begin
  DiscardDeviceResources;
  FTextFormat := nil;
  FTextFormatSmall := nil;
  FTextFormatBadgeTitle := nil;
  FTextFormatBadgeValue := nil;
  FDWriteFactory := nil;
  FD2DFactory := nil;
  inherited;
end;


procedure TGanttCentresControl.CreateWnd;
begin
  inherited;
  DiscardDeviceResources;
  Invalidate;
end;

procedure TGanttCentresControl.CreateDeviceResources;
var
  RTProps: TD2D1RenderTargetProperties;
  HwndProps: TD2D1HwndRenderTargetProperties;
  hr: HRESULT;
  Sz: TD2D1SizeU;
begin
  if FHwndRT <> nil then
    Exit;
  if not HandleAllocated then
    Exit;
  Sz := GetClientPixelSize;
  if (Sz.width = 0) or (Sz.height = 0) then
    Exit;
  InitD2D;
  RTProps := D2D1RenderTargetProperties(
    D2D1_RENDER_TARGET_TYPE_DEFAULT,
    D2D1PixelFormat(DXGI_FORMAT_UNKNOWN, D2D1_ALPHA_MODE_IGNORE),
    0, 0,
    D2D1_RENDER_TARGET_USAGE_NONE,
    D2D1_FEATURE_LEVEL_DEFAULT
  );
  HwndProps := D2D1HwndRenderTargetProperties(
    Handle,
    Sz,
    D2D1_PRESENT_OPTIONS_NONE
  );
  hr := FD2DFactory.CreateHwndRenderTarget(RTProps, HwndProps, FHwndRT);
  CheckHR(hr, 'CreateHwndRenderTarget');
end;

procedure TGanttCentresControl.DiscardDeviceResources;
begin
  FBrushBg := nil;
  FBrushRowEven := nil;
  FBrushRowOdd := nil;
  FBrushText := nil;
  FBrushTextDisabled := nil;
  FBrushLine := nil;
  FBrushDrop := nil;
  FBrushIndicatorBg := nil;
  FBrushIndicatorBorder := nil;
  FHwndRT := nil;
end;


procedure TGanttCentresControl.ResizeRenderTarget;
var
  Sz: TD2D1SizeU;
begin
  if Assigned(FHwndRT) then
  begin
    Sz := D2D1SizeU(ClientWidth, ClientHeight);
    FHwndRT.Resize(Sz);
  end;
end;

procedure TGanttCentresControl.Resize;
begin
  inherited;
  DiscardDeviceResources;
  Invalidate;
  //ResizeRenderTarget;
end;


procedure TGanttCentresControl.InitDWrite;
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


procedure TGanttCentresControl.InitD2D;
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

procedure TGanttCentresControl.CreateTextResources;
begin
  InitDWrite;

  if not Assigned(FDWriteFactory) then
    Exit;

  if not Assigned(FTextFormat ) then
  begin
    CheckHR(
      FDWriteFactory.CreateTextFormat(
        'Segoe UI',
        nil,
        DWRITE_FONT_WEIGHT_SEMI_BOLD,
        DWRITE_FONT_STYLE_NORMAL,
        DWRITE_FONT_STRETCH_NORMAL,
        10.0,
        'es-ES',
        FTextFormat
      ),
      'CreateTextFormat FTextFormat'
    );

    FTextFormat.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
    FTextFormat.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
    FTextFormat.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
  end;

  if not Assigned(FTextFormatSmall) then
  begin
    CheckHR(
      FDWriteFactory.CreateTextFormat(
        'Segoe UI',
        nil,
        DWRITE_FONT_WEIGHT_NORMAL,
        DWRITE_FONT_STYLE_NORMAL,
        DWRITE_FONT_STRETCH_NORMAL,
        8,
        'es-ES',
        FTextFormatSmall
      ),
      'CreateTextFormat FTextFormatSmall'
    );

    FTextFormatSmall.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
    FTextFormatSmall.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
    FTextFormatSmall.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
  end;


  if not Assigned(FTextFormatBadgeTitle) then
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
        FTextFormatBadgeTitle
      ),
      'CreateTextFormat FTextFormatBadgeTitle'
    );

    FTextFormatBadgeTitle.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
    FTextFormatBadgeTitle.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_NEAR);
    FTextFormatBadgeTitle.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
  end;

  if not Assigned(FTextFormatBadgeValue) then
  begin
    CheckHR(
      FDWriteFactory.CreateTextFormat(
        'Segoe UI',
        nil,
        DWRITE_FONT_WEIGHT_BOLD,
        DWRITE_FONT_STYLE_NORMAL,
        DWRITE_FONT_STRETCH_NORMAL,
        8.0,
        'es-ES',
        FTextFormatBadgeValue
      ),
      'CreateTextFormat FTextFormatBadgeValue'
    );

    FTextFormatBadgeValue.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
    FTextFormatBadgeValue.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_NEAR);
    FTextFormatBadgeValue.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
  end;

end;


procedure TGanttCentresControl.CreateBrushResources;
begin
  if not Assigned(FHwndRT) then
    Exit;

    {
    FHwndRT.CreateSolidColorBrush(D2DColor($00EEEEEE), nil, FBrushBg);
  FHwndRT.CreateSolidColorBrush(D2DColor($00F2F2F2), nil, FBrushRowEven);
  FHwndRT.CreateSolidColorBrush(D2DColor($00EAEAEA), nil, FBrushRowOdd);
  FHwndRT.CreateSolidColorBrush(D2DColor(clBlack), nil, FBrushText);
  FHwndRT.CreateSolidColorBrush(D2DColor(clSilver), nil, FBrushTextDisabled);
  FHwndRT.CreateSolidColorBrush(D2DColor(clSilver), nil, FBrushLine);
  FHwndRT.CreateSolidColorBrush(D2DColor(clRed), nil, FBrushDrop);
  FHwndRT.CreateSolidColorBrush(D2DColor($00F8F8F8), nil, FBrushIndicatorBg);
  FHwndRT.CreateSolidColorBrush(D2DColor($00D8D8D8), nil, FBrushIndicatorBorder);

    }
  if not Assigned(FBrushBg) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2DColor($00EEEEEE), nil, FBrushBg),
      'CreateSolidColorBrush FBrushBg'
    );

  if not Assigned(FBrushRowEven) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2DColor($00F2F2F2), nil, FBrushRowEven),
      'CreateSolidColorBrush FBrushLeftBg'
    );

  if not Assigned(FBrushRowOdd) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2DColor($00EAEAEA), nil, FBrushRowOdd),
      'CreateSolidColorBrush FBrushMonthBg1'
    );

  if not Assigned(FBrushText) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2DColor(clBlack), nil, FBrushText),
      'CreateSolidColorBrush FBrushMonthBg2'
    );

  if not Assigned(FBrushTextDisabled) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2DColor(clSilver), nil, FBrushTextDisabled),
      'CreateSolidColorBrush FBrushWeekBg'
    );

  if not Assigned(FBrushLine) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2DColor(clSilver), nil, FBrushLine),
      //FHwndRT.CreateSolidColorBrush(D2D1ColorF($FA / 255, $FA / 255, $FA / 255, 1), nil, FBrushWeekendBg),
      'CreateSolidColorBrush FBrushWeekendBg'
    );

  if not Assigned(FBrushDrop) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2DColor(clRed), nil, FBrushDrop),
      'CreateSolidColorBrush FBrushGridMajor'
    );

  if not Assigned(FBrushIndicatorBg) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2DColor($00F8F8F8), nil, FBrushIndicatorBg),
      'CreateSolidColorBrush FBrushGridMinor'
    );

  if not Assigned(FBrushIndicatorBorder) then
    CheckHR(
      FHwndRT.CreateSolidColorBrush(D2DColor($00D8D8D8), nil, FBrushIndicatorBorder),
      'CreateSolidColorBrush FBrushBorder'
    );

end;


function TGanttCentresControl.D2DColor(const C: TColor; const A: Single): TD2D1ColorF;
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

procedure TGanttCentresControl.FillRectD(const R: TRectF; const Brush: ID2D1Brush);
begin
  FHwndRT.FillRectangle(D2D1RectF(R.Left, R.Top, R.Right, R.Bottom), Brush);
end;
procedure TGanttCentresControl.DrawLineD(const X1, Y1, X2, Y2: Single;
  const Brush: ID2D1Brush; const StrokeWidth: Single);
begin
  FHwndRT.DrawLine(D2D1PointF(X1, Y1), D2D1PointF(X2, Y2), Brush, StrokeWidth);
end;
procedure TGanttCentresControl.DrawTextD(const S: string; const R: TRectF;
  const Brush: ID2D1Brush; const AFormat: IDWriteTextFormat);
begin
  if S = '' then
    Exit;
  FHwndRT.DrawText(
    PChar(S),
    Length(S),
    AFormat,
    D2D1RectF(R.Left, R.Top, R.Right, R.Bottom),
    Brush,
    D2D1_DRAW_TEXT_OPTIONS_CLIP,
    DWRITE_MEASURING_MODE_NATURAL
  );
end;


procedure TGanttCentresControl.PaintRowD2D(const RowIndex: Integer; const Row: TRowLayout);
var
  iCentreId, iCentreIdx: Integer;
  y1, y2: Single;
  LeftTextWidth: Single;
  TextBrush: ID2D1Brush;
  NomCentre, NomMaquina: string;
  RLabel1, RValue1: TRectF;
  RLabel2, RValue2: TRectF;
  RCircle: TRectF;
  CircleBrush: ID2D1SolidColorBrush;
  CircleStroke: ID2D1SolidColorBrush;
  CircleColor: TColor;
  DXColor: TD2D1ColorF;
  LabelW: Single;
  CircleSize: Single;
  PadX, PadY: Single;
begin
  iCentreId := Row.CentreId;
  iCentreIdx := FindCentreIndexById(iCentreId);

  y1 := Row.TopY - FScrollY;
  y2 := (Row.TopY + Row.Height) - FScrollY;

  if (RowIndex and 1) = 0 then
    FillRectD(RectF(0, y1, ClientWidth, y2), FBrushRowEven)
  else
    FillRectD(RectF(0, y1, ClientWidth, y2), FBrushRowOdd);

  if not Row.Enabled then
    TextBrush := FBrushTextDisabled
  else
    TextBrush := FBrushText;

  if FVerIndicadores then
    LeftTextWidth := ClientWidth - FIndicadoresWidth
  else
    LeftTextWidth := ClientWidth;

  if iCentreIdx >= 0 then
  begin
    NomCentre := FCentres[iCentreIdx].Nom;
    NomMaquina := FCentres[iCentreIdx].Maquina;
    CircleColor := FCentres[iCentreIdx].BkColor;
  end
  else
  begin
    if Assigned(FGetCentreName) then
      NomCentre := FGetCentreName(iCentreId)
    else
      NomCentre := Format('Centre %d', [iCentreId]);

    NomMaquina := '';
    CircleColor := clGray;
  end;

  if Trim(NomMaquina) = '' then
    NomMaquina := '-';

  PadX := 8;
  PadY := 5;
  LabelW := 68;
  CircleSize := 10;

  RCircle := RectF(
    LeftTextWidth - PadX - CircleSize,
    y1 + PadY,
    LeftTextWidth - PadX,
    y1 + PadY + CircleSize
  );

  DXColor := D2D1ColorF(
    GetRValue(ColorToRGB(CircleColor)) / 255,
    GetGValue(ColorToRGB(CircleColor)) / 255,
    GetBValue(ColorToRGB(CircleColor)) / 255,
    1.0
  );

  FHwndRT.CreateSolidColorBrush(DXColor, nil, CircleBrush);
  FHwndRT.CreateSolidColorBrush(D2D1ColorF(0.45, 0.45, 0.45, 1.0), nil, CircleStroke);

  FHwndRT.FillEllipse(
    D2D1Ellipse(
      D2D1PointF((RCircle.Left + RCircle.Right) * 0.5, (RCircle.Top + RCircle.Bottom) * 0.5),
      (RCircle.Right - RCircle.Left) * 0.5,
      (RCircle.Bottom - RCircle.Top) * 0.5
    ),
    CircleBrush
  );

  FHwndRT.DrawEllipse(
    D2D1Ellipse(
      D2D1PointF((RCircle.Left + RCircle.Right) * 0.5, (RCircle.Top + RCircle.Bottom) * 0.5),
      (RCircle.Right - RCircle.Left) * 0.5,
      (RCircle.Bottom - RCircle.Top) * 0.5
    ),
    CircleStroke,
    1.0
  );

  RLabel1 := RectF(PadX, y1 + 3, PadX + LabelW, y1 + 18);
  RValue1 := RectF(PadX + LabelW, y1 + 3, RCircle.Left - 6, y1 + 18);

  RLabel2 := RectF(PadX, y1 + 19, PadX + LabelW, y2 - 3);
  RValue2 := RectF(PadX + LabelW, y1 + 19, LeftTextWidth - PadX, y2 - 3);

  DrawTextD('CENTRO:', RLabel1, TextBrush, FTextFormat);
  DrawTextD(NomCentre, RValue1, TextBrush, FTextFormat);

  DrawTextD('MAQUINA:', RLabel2, TextBrush, FTextFormat);
  DrawTextD(NomMaquina, RValue2, TextBrush, FTextFormat);

  if FVerIndicadores then
    PaintIndicatorsD2D(RowIndex, Row, LeftTextWidth);

  DrawLineD(0, y2 - 1, ClientWidth, y2 - 1, FBrushLine, 1.0);
end;


procedure TGanttCentresControl.PaintIndicatorsD2D(
  const RowIndex: Integer; const Row: TRowLayout; const LeftTextWidth: Single);
const
  BW = 40.0;
  BH = 28.0;
  GAP = 4.0;
var
  y1, y2: Single;
  RX: Single;
  RPanel: TRectF;
  StartX, StartY: Single;
  B1, B2, B3, B4, B5: TRectF;
  K: TCentreKPI;
  V1, V2, V3, V4, V5: TBadgeVisual;
begin
  y1 := Row.TopY - FScrollY;
  y2 := (Row.TopY + Row.Height) - FScrollY;
  RX := LeftTextWidth;

  DrawLineD(RX, y1, RX, y2, FBrushIndicatorBorder, 1.0);

  RPanel := RectF(RX + 2, y1 + 2, ClientWidth - 2, y2 - 2);

 // if Assigned(FBrushIndicatorBg) then
 //   FillRectD(RPanel, FBrushIndicatorBg);

  if Assigned(FGetCentreKPI) then
    K := FGetCentreKPI(Row.CentreId)
  else
  begin
    K.TotalNodes := Row.LaneCount;
    K.HoresOcupades := 12.5;
    K.HoresDisponibles := 20.0;
    K.TotalOperaris := 3;
    K.PercentOcupacio := 38.5;
  end;

  V1 := GetBadgeVisualInt(K.TotalNodes, FCurrentKPIRanges.Nodes.MinInt, FCurrentKPIRanges.Nodes.MaxInt);
  V2 := GetBadgeVisualFloat(K.HoresOcupades, FCurrentKPIRanges.Ocupades.MinFloat, FCurrentKPIRanges.Ocupades.MaxFloat);
  V3 := GetBadgeVisualFloat(K.HoresDisponibles, FCurrentKPIRanges.Disponibles.MinFloat, FCurrentKPIRanges.Disponibles.MaxFloat);
  V4 := GetBadgeVisualInt(K.TotalOperaris, FCurrentKPIRanges.Operaris.MinInt, FCurrentKPIRanges.Operaris.MaxInt);
  V5 := GetBadgeVisualFloat( K.PercentOcupacio, FCurrentKPIRanges.PercentOcupacio.MinFloat, FCurrentKPIRanges.PercentOcupacio.MaxFloat );

  StartX := Round(RPanel.Left + 4);
  StartY := Round(RPanel.Top + ((RPanel.Bottom - RPanel.Top - BH) * 0.5));

  B1 := RectF(StartX,                    StartY, StartX + BW,                    StartY + BH);
  B2 := RectF(B1.Right + GAP,           StartY, B1.Right + GAP + BW,           StartY + BH);
  B3 := RectF(B2.Right + GAP,           StartY, B2.Right + GAP + BW,           StartY + BH);
  B4 := RectF(B3.Right + GAP,           StartY, B3.Right + GAP + BW,           StartY + BH);
  B5 := RectF(B4.Right + GAP,           StartY, B4.Right + GAP + BW,           StartY + BH);

  DrawBadgeD(B1, 'Nodes', IntToStr(K.TotalNodes), V1.FillColor, V1.BorderColor);
  DrawBadgeD(B2, 'Ocup', FormatFloat('0.0h', K.HoresOcupades), V2.FillColor, V2.BorderColor);
  DrawBadgeD(B3, 'Disp', FormatFloat('0.0h', K.HoresDisponibles), V3.FillColor, V3.BorderColor);
  DrawBadgeD(B4, 'Ops',  IntToStr(K.TotalOperaris), V4.FillColor, V4.BorderColor);
  DrawBadgeD(B5, '%', FormatFloat('0.0', K.PercentOcupacio) + '%', V5.FillColor, V5.BorderColor);

end;


procedure TGanttCentresControl.SetRows(const ARows: TArray<TRowLayout>);
begin
  FRows := Copy(ARows);
  Invalidate;
end;

procedure TGanttCentresControl.SetVerIndicadores(const Value: Boolean);
begin
  if FVerIndicadores = Value then
    Exit;
  FVerIndicadores := Value;
  UpdateControlWidth;
  Invalidate;
end;
procedure TGanttCentresControl.UpdateControlWidth;
begin
  if FVerIndicadores then
    Width := FBaseWidth + FIndicadoresWidth
  else
    Width := FBaseWidth;
end;

procedure TGanttCentresControl.SetIndicadoresWidth(const Value: Integer);
begin
  if FIndicadoresWidth = Value then
    Exit;
  FIndicadoresWidth := Max(0, Value);
  UpdateControlWidth;
  Invalidate;
end;


procedure TGanttCentresControl.SetWidth(const Value: Integer);
begin
  if FBaseWidth = Value then
    Exit;
  FBaseWidth := Max(0, Value);
  UpdateControlWidth;
  Invalidate;
end;


function TGanttCentresControl.BuildKPIRanges: TCentresKPIRanges;
var
  i: Integer;
  K: TCentreKPI;
begin
  Result.Nodes.MinInt := MaxInt;
  Result.Nodes.MaxInt := -MaxInt;

  Result.Ocupades.MinFloat := 1.0E100;
  Result.Ocupades.MaxFloat := -1.0E100;

  Result.Disponibles.MinFloat := 1.0E100;
  Result.Disponibles.MaxFloat := -1.0E100;

  Result.Operaris.MinInt := MaxInt;
  Result.Operaris.MaxInt := -MaxInt;

  if not Assigned(FGetCentreKPI) then
    Exit;

  for i := 0 to High(FRows) do
  begin
    if not FRows[i].Visible then
      Continue;

    K := FGetCentreKPI(FRows[i].CentreId);

    Result.Nodes.MinInt := Min(Result.Nodes.MinInt, K.TotalNodes);
    Result.Nodes.MaxInt := Max(Result.Nodes.MaxInt, K.TotalNodes);

    Result.Ocupades.MinFloat := Min(Result.Ocupades.MinFloat, K.HoresOcupades);
    Result.Ocupades.MaxFloat := Max(Result.Ocupades.MaxFloat, K.HoresOcupades);

    Result.Disponibles.MinFloat := Min(Result.Disponibles.MinFloat, K.HoresDisponibles);
    Result.Disponibles.MaxFloat := Max(Result.Disponibles.MaxFloat, K.HoresDisponibles);

    Result.Operaris.MinInt := Min(Result.Operaris.MinInt, K.TotalOperaris);
    Result.Operaris.MaxInt := Max(Result.Operaris.MaxInt, K.TotalOperaris);
  end;
end;



procedure TGanttCentresControl.SetCentres(const ACentres: TArray<TCentreTreball>);
begin
  FCentres := Copy(ACentres);   // o sense Copy si vols referència directa
  Invalidate;
end;

function TGanttCentresControl.HitTestRowIndex(const Y: Integer): Integer;
var
  i: Integer;
  yWorld: Single;
begin
  Result := -1;
  yWorld := Y + FScrollY;

  for i := 0 to High(FRows) do
  begin
    if not FRows[i].Visible then
      Continue;

    if (yWorld >= FRows[i].TopY) and (yWorld <= FRows[i].TopY + FRows[i].Height) then
      Exit(i);
  end;
end;

function TGanttCentresControl.CalcDropIndex(const Y: Integer): Integer;
var
  i: Integer;
  yWorld: Single;
  midY: Single;
begin
  // devuelve el índice donde insertar (0..Length(FRows))
  yWorld := Y + FScrollY;

  // Por defecto: al final
  Result := Length(FRows);

  for i := 0 to High(FRows) do
  begin
    if not FRows[i].Visible then
      Continue;

    midY := FRows[i].TopY + (FRows[i].Height * 0.5);
    if yWorld < midY then
      Exit(i);
  end;
end;

procedure TGanttCentresControl.MoveRow(const FromIndex, ToIndex: Integer);
var
  tmp: TRowLayout;
  i, dst: Integer;
begin
  if (FromIndex < 0) or (FromIndex > High(FRows)) then Exit;
  if (ToIndex < 0) then Exit;
  if (ToIndex > Length(FRows)) then Exit;

  // si insertas “después” y quitas antes, el destino se desplaza
  dst := ToIndex;
  if dst > FromIndex then
    Dec(dst);

  if dst = FromIndex then Exit;

  tmp := FRows[FromIndex];

  if FromIndex < dst then
    for i := FromIndex to dst - 1 do
      FRows[i] := FRows[i + 1]
  else
    for i := FromIndex downto dst + 1 do
      FRows[i] := FRows[i - 1];

  FRows[dst] := tmp;

  RecalcRowTops;
end;

procedure TGanttCentresControl.RecalcRowTops;
var
  i: Integer;
  y: Single;
begin
  y := 0;
  for i := 0 to High(FRows) do
  begin
    FRows[i].TopY := y;
    if FRows[i].Visible then
      y := y + FRows[i].Height;
  end;
end;

function TGanttCentresControl.BuildCentreIdOrder: TArray<Integer>;
var
  i: Integer;
begin
  SetLength(Result, Length(FRows));
  for i := 0 to High(FRows) do
    Result[i] := FRows[i].CentreId;
end;

function TGanttCentresControl.HitTestCentreId(const Y: Integer): Integer;
var
  i: Integer;
  yWorld: Single;
begin
  Result := -1;
  // convertir coordenada pantalla a world
  yWorld := Y + FScrollY;
  for i := 0 to High(FRows) do
  begin
    if not FRows[i].Visible then
      Continue;
    if (yWorld >= FRows[i].TopY) and
       (yWorld <= FRows[i].TopY + FRows[i].Height) then
      Exit(FRows[i].CentreId);
  end;
end;



procedure TGanttCentresControl.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  if (MousePos.X < 0) or (MousePos.Y < 0) then
    MousePos := Point(ClientWidth div 2, ClientHeight div 2);
  FSelectedCentreId := HitTestCentreId(MousePos.Y);
  // deixa que el PopupMenu normal del control surti (republished PopupMenu)
  inherited;
end;

procedure TGanttCentresControl.SetScrollY(const Value: Single);
begin
  if Abs(Value - FScrollY) > 0.5 then
  begin
    FScrollY := Max(0, Value);
    Invalidate;
  end;
end;

function TGanttCentresControl.FindCentreIndexById(const CentreId: Integer): Integer;
var
  i: Integer;
begin
  for i := 0 to High(FCentres) do
    if FCentres[i].Id = CentreId then
      Exit(i);
  Result := -1;
end;

procedure TGanttCentresControl.NotifyScrollYChanged;
begin
  if Assigned(FOnScrollYChanged) then
    FOnScrollYChanged(Self, FScrollY);
end;

function TGanttCentresControl.GetClientPixelSize: TD2D1SizeU;
var
  R: TRect;
begin
  R := GetClientRect;
  Result := D2D1SizeU(R.Right - R.Left, R.Bottom - R.Top);
end;

procedure TGanttCentresControl.DrawBadgeD(const R: TRectF; const ATitle, AValue: string;
  const FillColor, BorderColor: TColor);
var
  FillBrush, BorderBrush: ID2D1SolidColorBrush;
  RR: TD2D1RoundedRect;
  RTitle, RValue: TRectF;
begin
  if FHwndRT = nil then
    Exit;

  CheckHR(
    FHwndRT.CreateSolidColorBrush(D2DColor(FillColor), nil, FillBrush),
    'CreateSolidColorBrush Badge Fill'
  );

  CheckHR(
    FHwndRT.CreateSolidColorBrush(D2DColor(BorderColor), nil, BorderBrush),
    'CreateSolidColorBrush Badge Border'
  );

  RR := D2D1RoundedRect(D2D1RectF(R.Left, R.Top, R.Right, R.Bottom), 5, 5);

  FHwndRT.FillRoundedRectangle(RR, FillBrush);
  FHwndRT.DrawRoundedRectangle(RR, BorderBrush, 1.0);

  RTitle := RectF(
    Round(R.Left + 2),
    Round(R.Top + 2),
    Round(R.Right - 2),
    Round(R.Top + 12)
  );

  RValue := RectF(
    Round(R.Left + 2),
    Round(R.Top + 12),
    Round(R.Right - 2),
    Round(R.Bottom - 2)
  );

  DrawTextD(ATitle, RTitle, FBrushText, FTextFormatBadgeTitle);
  DrawTextD(AValue, RValue, FBrushText, FTextFormatBadgeValue);
end;



procedure TGanttCentresControl.Paint;
var
  i: Integer;
  y1: Single;
  M: TD2DMatrix3x2F;
  hr: HRESULT;
begin
  if csDestroying in ComponentState then Exit;
  if not HandleAllocated then Exit;
  if (ClientWidth <= 0) or (ClientHeight <= 0) then Exit;

  CreateDeviceResources;
  if not Assigned(FHwndRT) then Exit;

  CreateBrushResources;
  CreateTextResources;

  FHwndRT.BeginDraw;
  try
    //M := TD2DMatrix3x2F.Identity;

    M._11 := 1; M._12 := 0;
    M._21 := 0; M._22 := 1;
    M._31 := 0; M._32 := 0;

    FHwndRT.SetTransform(M);
    FHwndRT.SetTextAntialiasMode(D2D1_TEXT_ANTIALIAS_MODE_CLEARTYPE);
    FHwndRT.SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);

    FillRectD(RectF(0, 0, ClientWidth, ClientHeight), FBrushBg);


    //if Assigned(FGetCentreKPI) then
    // FCurrentKPIRanges := BuildKPIRanges;

    if Length(FRows) > 0 then
    begin
      for i := 0 to High(FRows) do
      begin
        y1 := FRows[i].TopY - FScrollY;

        if (y1 + FRows[i].Height) < 0 then
          Continue;
        if y1 > ClientHeight then
          Break;

        PaintRowD2D(i, FRows[i]);
      end;
    end;

    // indicador de drop
    if FDragging and (FDragHoverIndex >= 0) then
    begin
      if FDragHoverIndex <= High(FRows) then
        y1 := FRows[FDragHoverIndex].TopY - FScrollY
      else if High(FRows) >= 0 then
        y1 := (FRows[High(FRows)].TopY + FRows[High(FRows)].Height) - FScrollY
      else
        y1 := 0;

      DrawLineD(2, y1, ClientWidth - 3, y1, FBrushDrop, 2.0);
    end;

    // vora dreta
    DrawLineD(ClientWidth - 1, 0, ClientWidth - 1, ClientHeight, FBrushLine, 1.0);

    hr := FHwndRT.EndDraw;
    if hr = D2DERR_RECREATE_TARGET then
      DiscardDeviceResources
    else
      CheckHR(hr, 'EndDraw');
  except
    FHwndRT.EndDraw;
    DiscardDeviceResources;
    raise;
  end;

end;

procedure TGanttCentresControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  idx: Integer;
begin
  inherited;
  if Button <> mbLeft then Exit;
  idx := HitTestRowIndex(Y);
  FDragFromIndex := idx;
  FDragHoverIndex := -1;
  FDragging := False;
  FDragArmed := (idx >= 0);
  FDragStartPt := Point(X, Y);
  // Si no has clicado una fila, pan como antes
  if not FDragArmed then
  begin
    FIsPanning := True;
    FPanStartY := Y;
    FScrollStartY := FScrollY;
  end;
  MouseCapture := True;
end;

procedure TGanttCentresControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  dx, dy: Integer;
  dropIdx: Integer;
begin
  inherited;

  dx := Abs(X - FDragStartPt.X);
  dy := Abs(Y - FDragStartPt.Y);

  // Si estamos armados para drag y movemos más que el umbral -> empezamos a arrastrar
  if FDragArmed and not FDragging then
  begin
    if (dx >= GetSystemMetrics(SM_CXDRAG)) or (dy >= GetSystemMetrics(SM_CYDRAG)) then
    begin
      FDragging := True;
      FIsPanning := False; // si entramos en drag, cancelamos pan
    end;
  end;

  if FDragging then
  begin
    dropIdx := CalcDropIndex(Y);
    if dropIdx <> FDragHoverIndex then
    begin
      FDragHoverIndex := dropIdx;
      Invalidate;
    end;
    Exit;
  end;

  // Si no estamos draggeando, pan vertical como antes (si se activó)
  if FIsPanning then
  begin
    FScrollY := Max(0, FScrollStartY - (Y - FPanStartY));
    NotifyScrollYChanged;
    Invalidate;
  end;
end;

procedure TGanttCentresControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  newOrder: TArray<Integer>;
begin
  inherited;

  if Button <> mbLeft then Exit;

  if FDragging then
  begin
    // aplica reorder
    if (FDragFromIndex >= 0) and (FDragHoverIndex >= 0) then
    begin
      MoveRow(FDragFromIndex, FDragHoverIndex);

      // Notifica el nuevo orden al exterior (modelo)
      if Assigned(FOnCentresReordered) then
      begin
        newOrder := BuildCentreIdOrder;
        FOnCentresReordered(Self, newOrder);
      end;

      Invalidate;
    end;
  end;

  FDragging := False;
  FDragArmed := False;
  FDragFromIndex := -1;
  FDragHoverIndex := -1;

  FIsPanning := False;
  MouseCapture := False;
end;

procedure TGanttCentresControl.WMMouseWheel(var Message: TWMMouseWheel);
var
  f: Single;
begin
  // wheel vertical (igual que un scroll)

  FScrollY := Max(0, FScrollY + (-Message.WheelDelta / 120) * 60);
  if FScrollY<0 then
   FScrollY :=0;

  NotifyScrollYChanged;
  Invalidate;

  Message.Result := 1;
end;

procedure TGanttCentresControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1; // evitem flicker
end;

end.
