unit uColorPalette64LayeredPopup;

interface

uses
  System.Classes, System.Types, System.UITypes, System.SysUtils, System.Math,
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX,
  Winapi.D2D1, {Winapi.D2D1Helper,} Winapi.DxgiFormat, Winapi.Wincodec,
  Vcl.Forms, Vcl.Controls, VCL.Graphics;

type
  TPalette64 = array[0..63] of TColor;
  TOnColorPicked = reference to procedure(const Color: TColor);

  TColorPalette64LayeredPopup = class(TCustomForm)
  private
    FPalette: TPalette64;
    FSelectedIndex: Integer;
    FHoverIndex: Integer;

    FCols: Integer;
    FRows: Integer;
    FInnerPad: Integer;
    FCellGap: Integer;
    FCornerRadius: Single;

    // Styling
    FCardFill: TColor;
    FCardBorder: TColor;
    FGlowColor: TColor;
    FHoverBorder: TColor;
    FSelectBorder: TColor;

    FOnPicked: TOnColorPicked;

    // D2D/WIC
    FWICFactory: IWICImagingFactory;
    FD2DFactory: ID2D1Factory;

    procedure InitDefaults;
    procedure EnsureFactories;

    function GridRect: TRect;
    function CellRect(AIndex: Integer): TRect;
    function IndexAt(const P: TPoint): Integer;

    procedure RenderAndUpdateLayered(const GlobalAlpha: Byte = 255);
    procedure ClosePopup;

    function GetSelectedColor: TColor;

    // Input
    procedure WMActivate(var Msg: TWMActivate); message WM_ACTIVATE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;

    procedure Paint; override;
    procedure Resize; override;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure WMGetDlgCode(var Msg: TWMGetDlgCode); message WM_GETDLGCODE;
  public
    constructor Create(AOwner: TComponent); override;

    procedure PopupAtScreen(const X, Y: Integer; const AOnPicked: TOnColorPicked;
                            const W: Integer = 260; const H: Integer = 260);

    property SelectedIndex: Integer read FSelectedIndex;
    property SelectedColor: TColor read GetSelectedColor;
  end;

implementation

function ClampInt(const V, AMin, AMax: Integer): Integer;
begin
  Result := V;
  if Result < AMin then Result := AMin;
  if Result > AMax then Result := AMax;
end;

function D2DColorF(const C: TColor; const Alpha: Single = 1.0): TD2D1ColorF;
var
  rgb: COLORREF;
begin
  rgb := ColorToRGB(C);
  Result := D2D1ColorF(GetRValue(rgb)/255, GetGValue(rgb)/255, GetBValue(rgb)/255, Alpha);
end;

{ TColorPalette64LayeredPopup }

constructor TColorPalette64LayeredPopup.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);

  BorderStyle := bsNone;
  Position := poDesigned;
  KeyPreview := True;

  // important: layered windows shouldn’t use normal VCL painting
  // we’ll render via UpdateLayeredWindow, so keep it simple:
  Color := clBlack;
  Visible := False;

  FCols := 8;
  FRows := 8;
  FInnerPad := 22;
  FCellGap := 2;
  FCornerRadius := 8;

  FSelectedIndex := 0;
  FHoverIndex := -1;

  InitDefaults;
end;

procedure TColorPalette64LayeredPopup.InitDefaults;
const
  P: TPalette64 = (
    clBlack, clMaroon, clGreen, clOlive, clNavy, clPurple, clTeal, clGray,
    clSilver, clRed, clLime, clYellow, clBlue, clFuchsia, clAqua, clWhite,

    TColor($00FFE6CC), TColor($00FFD9B3), TColor($00FFCC99), TColor($00FFBF80), TColor($00FFB266), TColor($00FFA64D), TColor($00FF9933), TColor($00FF8C1A),
    TColor($00E6FFCC), TColor($00D9FFB3), TColor($00CCFF99), TColor($00BFFF80), TColor($00B2FF66), TColor($00A6FF4D), TColor($0099FF33), TColor($008CFF1A),
    TColor($00CCFFFF), TColor($00B3FFFF), TColor($0099FFFF), TColor($0080FFFF), TColor($0066FFFF), TColor($004DFFFF), TColor($0033FFFF), TColor($001AFFFF),
    TColor($00CCE6FF), TColor($00B3D9FF), TColor($0099CCFF), TColor($0080BFFF), TColor($0066B2FF), TColor($004DA6FF), TColor($003399FF), TColor($001A8CFF),

    TColor($00CCCCFF), TColor($00B3B3FF), TColor($009999FF), TColor($008080FF), TColor($006666FF), TColor($004D4DFF), TColor($003333FF), TColor($001A1AFF),
    TColor($00FFCCFF), TColor($00FFB3FF), TColor($00FF99FF), TColor($00FF80FF), TColor($00FF66FF), TColor($00FF4DFF), TColor($00FF33FF), TColor($00FF1AFF)
  );
begin
  FPalette := P;

  FCardFill := TColor($00FFFFFF);
  FCardBorder := TColor($00D0D0D0);

  // Glow blau clar (BGR)
  FGlowColor := TColor($00FFE6CC);     // RGB(204,230,255)
  FHoverBorder := TColor($00CC9966);   // RGB(102,153,204)
  FSelectBorder := TColor($00B36B2E);  // més fort
end;

procedure TColorPalette64LayeredPopup.EnsureFactories;
begin
  if (FWICFactory = nil) then
    if Failed( CoCreateInstance(CLSID_WICImagingFactory, nil, CLSCTX_INPROC_SERVER,
                              IID_IWICImagingFactory, FWICFactory)) then
      raise Exception.Create('CoCreateInstance failed');

  if (FD2DFactory = nil) then
    if Failed( D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, IID_ID2D1Factory, nil, FD2DFactory)) then
      raise Exception.Create('D2D1CreateFactory failed');
end;

procedure TColorPalette64LayeredPopup.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := (Params.Style or WS_POPUP);
  Params.ExStyle := (Params.ExStyle or WS_EX_TOOLWINDOW or WS_EX_TOPMOST or WS_EX_LAYERED);
end;

procedure TColorPalette64LayeredPopup.CreateWnd;
var
  ex: NativeInt;
begin
  inherited;
  ex := GetWindowLongPtr(Handle, GWL_EXSTYLE);
  if (ex and WS_EX_LAYERED) = 0 then
    SetWindowLongPtr(Handle, GWL_EXSTYLE, ex or WS_EX_LAYERED);
  EnsureFactories;
end;

procedure TColorPalette64LayeredPopup.PopupAtScreen(const X, Y: Integer;
  const AOnPicked: TOnColorPicked; const W, H: Integer);
var
  r: TRect;
  nx, ny: Integer;
  a: Integer;
begin
  FOnPicked := AOnPicked;

  nx := X;
  ny := Y;

  r := Screen.MonitorFromPoint(Point(nx, ny)).WorkareaRect;
  if nx + W > r.Right then nx := r.Right - W;
  if ny + H > r.Bottom then ny := r.Bottom - H;
  if nx < r.Left then nx := r.Left;
  if ny < r.Top then ny := r.Top;

  SetBounds(nx, ny, W, H);

  // IMPORTANT: assegura Handle i WS_EX_LAYERED abans de renderitzar
  HandleNeeded;

  Show;
  BringToFront;
  SetFocus;

  // Fade-in: MAI alpha=0
  for a := 1 to 10 do
  begin
    RenderAndUpdateLayered(Byte(a * 25)); // 25..250
    Sleep(5);
  end;

  RenderAndUpdateLayered(255);
end;

procedure TColorPalette64LayeredPopup.Resize;
begin
  inherited;
  if HandleAllocated and Visible then
    RenderAndUpdateLayered;
end;

procedure TColorPalette64LayeredPopup.Paint;
begin
  // No GDI paint: layered uses UpdateLayeredWindow.
  // Still, keep it safe.
  if HandleAllocated and Visible then
    RenderAndUpdateLayered;
end;

function TColorPalette64LayeredPopup.GridRect: TRect;
begin
  Result := Rect(FInnerPad, FInnerPad, ClientWidth - FInnerPad, ClientHeight - FInnerPad);
end;

function TColorPalette64LayeredPopup.CellRect(AIndex: Integer): TRect;
var
  gr: TRect;
  cellW, cellH: Integer;
  col, row: Integer;
  x0, y0: Integer;
begin
  gr := GridRect;

  col := AIndex mod FCols;
  row := AIndex div FCols;

  cellW := (gr.Width - (FCols-1)*FCellGap) div FCols;
  cellH := (gr.Height - (FRows-1)*FCellGap) div FRows;

  x0 := gr.Left + col * (cellW + FCellGap);
  y0 := gr.Top + row * (cellH + FCellGap);

  Result := Rect(x0, y0, x0 + cellW, y0 + cellH);
end;

function TColorPalette64LayeredPopup.IndexAt(const P: TPoint): Integer;
var
  gr: TRect;
  cellW, cellH, stepW, stepH: Integer;
  relX, relY: Integer;
  col, row: Integer;
begin
  Result := -1;
  gr := GridRect;
  if not PtInRect(gr, P) then Exit;

  cellW := (gr.Width - (FCols-1)*FCellGap) div FCols;
  cellH := (gr.Height - (FRows-1)*FCellGap) div FRows;
  if (cellW <= 0) or (cellH <= 0) then Exit;

  stepW := cellW + FCellGap;
  stepH := cellH + FCellGap;

  relX := P.X - gr.Left;
  relY := P.Y - gr.Top;

  col := relX div stepW;
  row := relY div stepH;

  if (col < 0) or (col >= FCols) or (row < 0) or (row >= FRows) then Exit;
  if (relX mod stepW) >= cellW then Exit;
  if (relY mod stepH) >= cellH then Exit;

  Result := row * FCols + col;
  if (Result < 0) or (Result > 63) then Result := -1;
end;

procedure TColorPalette64LayeredPopup.RenderAndUpdateLayered(const GlobalAlpha: Byte = 255);
var
  W, H: Cardinal;
  wicBitmap: IWICBitmap;
  props: TD2D1RenderTargetProperties;
  rt: ID2D1RenderTarget;

  // DIB for UpdateLayeredWindow
  bmi: BITMAPINFO;
  dibBits: Pointer;
  hbmp: HBITMAP;
  hdcMem, hdcScreen: HDC;
  oldBmp: HGDIOBJ;

  // copy from WIC
  rc: WICRect;
  stride: UINT;
  bufSize: UINT;

  // layered params
  sz: TSize;
  srcPt: TPoint;
  dstPt: TPoint;
  blend: TBlendFunction;

  // drawing
  bFill, bBorder, bHover, bSel, bGlow, bShadow, bCell: ID2D1SolidColorBrush;
  rCard: TD2D1RectF;
  rr, rrGlow, rrShadow: TD2D1RoundedRect;
  i, g: Integer;
  inset: Single;
  hrEnd: HRESULT;
  A: Byte;

  function RectF(const R: TRect): TD2D1RectF;
  begin
    Result := D2D1RectF(R.Left, R.Top, R.Right, R.Bottom);
  end;

begin
  if not HandleAllocated then Exit;

  EnsureFactories;

  W := ClientWidth;
  H := ClientHeight;
  if (W = 0) or (H = 0) then Exit;

  A := GlobalAlpha;
  if A = 0 then A := 1;

  // 1) Create WIC bitmap (32bpp premultiplied BGRA)
  if Failed(FWICFactory.CreateBitmap(
      W, H,
      @GUID_WICPixelFormat32bppPBGRA,
      WICBitmapCacheOnLoad,
      wicBitmap)) then
    raise Exception.Create('CreateBitmap failed');

  // 2) Create D2D render target on WIC bitmap
  props := D2D1RenderTargetProperties(
    D2D1_RENDER_TARGET_TYPE_SOFTWARE, // safest for WIC; can be HARDWARE too, but software is stable
    D2D1PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED),
    96, 96, D2D1_RENDER_TARGET_USAGE_NONE, D2D1_FEATURE_LEVEL_DEFAULT
  );

  if Failed(FD2DFactory.CreateWicBitmapRenderTarget(wicBitmap, props, rt))then
    raise Exception.Create('CreateWicBitmapRenderTarget failed');

  // Brushes
  rt.CreateSolidColorBrush(D2DColorF(FCardFill, 1.0), nil, bFill);
  rt.CreateSolidColorBrush(D2DColorF(FCardBorder, 1.0), nil, bBorder);
  rt.CreateSolidColorBrush(D2DColorF(FHoverBorder, 1.0), nil, bHover);
  rt.CreateSolidColorBrush(D2DColorF(FSelectBorder, 1.0), nil, bSel);

  // 3) Draw
  rt.BeginDraw;
  try
    // clear fully transparent
    rt.Clear(D2D1ColorF(0, 0, 0, 0));

    // Leave margin so glow/shadow fit
    rCard := D2D1RectF(10, 10, W - 10, H - 10);
    rr := D2D1RoundedRect(rCard, FCornerRadius, FCornerRadius);

    // Glow rings (outside)
    for g := 1 to 6 do
    begin
      inset := -g * 2.4;
      rt.CreateSolidColorBrush(D2DColorF(FGlowColor, 0.16 / g), nil, bGlow);

      rrGlow := D2D1RoundedRect(
        D2D1RectF(rCard.left + inset, rCard.top + inset, rCard.right - inset, rCard.bottom - inset),
        FCornerRadius + (g * 1.7),
        FCornerRadius + (g * 1.7)
      );

      rt.DrawRoundedRectangle(rrGlow, bGlow, 2.0);
    end;

    // Shadow (soft fake)
    rt.CreateSolidColorBrush(D2D1ColorF(0, 0, 0, 0.10), nil, bShadow);
    rrShadow := D2D1RoundedRect(D2D1RectF(rCard.left+4, rCard.top+6, rCard.right+4, rCard.bottom+6),
                                FCornerRadius, FCornerRadius);
    rt.FillRoundedRectangle(rrShadow, bShadow);

    rt.CreateSolidColorBrush(D2D1ColorF(0, 0, 0, 0.06), nil, bShadow);
    rrShadow := D2D1RoundedRect(D2D1RectF(rCard.left+8, rCard.top+12, rCard.right+8, rCard.bottom+12),
                                FCornerRadius, FCornerRadius);
    rt.FillRoundedRectangle(rrShadow, bShadow);

    // Card
    rt.FillRoundedRectangle(rr, bFill);
    rt.DrawRoundedRectangle(rr, bBorder, 1.0);

    // Cells
    for i := 0 to 63 do
    begin
      var R := CellRect(i);
      var RF := RectF(R);

      rt.CreateSolidColorBrush(D2DColorF(FPalette[i], 1.0), nil, bCell);
      //rt.FillRectangle(RF, bCell);

      RT.FillRoundedRectangle(D2D1RoundedRect(RF, 2, 2), bCell);

      if i = FHoverIndex then
        rt.DrawRectangle(RF, bHover, 2.0);

      if i = FSelectedIndex then
        rt.DrawRectangle(RF, bSel, 2.0);
    end;

  finally
    hrEnd := rt.EndDraw(nil, nil);
  end;

  if Failed(hrEnd) then
  begin
    // Això és el típic que et deixa el bitmap negre
    // D2DERR_RECREATE_TARGET = $8899000C
    raise Exception.CreateFmt('D2D EndDraw failed: 0x%.8x', [Cardinal(hrEnd)]);
  end;

  // 4) Create DIB32 (top-down) for UpdateLayeredWindow
  ZeroMemory(@bmi, SizeOf(bmi));
  bmi.bmiHeader.biSize := SizeOf(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth := Integer(W);
  bmi.bmiHeader.biHeight := -Integer(H); // top-down
  bmi.bmiHeader.biPlanes := 1;
  bmi.bmiHeader.biBitCount := 32;
  bmi.bmiHeader.biCompression := BI_RGB;

  hbmp := CreateDIBSection(0, bmi, DIB_RGB_COLORS, dibBits, 0, 0);
  if hbmp = 0 then Exit;

  try
    // 5) Copy pixels from WIC bitmap into DIB
    rc.X := 0; rc.Y := 0; rc.Width := Integer(W); rc.Height := Integer(H);
    stride := W * 4;
    bufSize := stride * H;
    if Failed( wicBitmap.CopyPixels(@rc, stride, bufSize, dibBits))then
     raise Exception.Create('CopyPixels failed');

    // 6) UpdateLayeredWindow
    hdcScreen := GetDC(0);
    hdcMem := CreateCompatibleDC(hdcScreen);
    try
      oldBmp := SelectObject(hdcMem, hbmp);

      sz.cx := Integer(W);
      sz.cy := Integer(H);
      srcPt := Point(0, 0);
      dstPt := Point(Left, Top);

      blend.BlendOp := AC_SRC_OVER;
      blend.BlendFlags := 0;
      blend.SourceConstantAlpha := GlobalAlpha;
      blend.AlphaFormat := AC_SRC_ALPHA;

      if not UpdateLayeredWindow(Handle, hdcScreen, @dstPt, @sz, hdcMem, @srcPt, 0, @blend, ULW_ALPHA) then
        raise Exception.CreateFmt('UpdateLayeredWindow failed. GetLastError=%d', [GetLastError]);

      SelectObject(hdcMem, oldBmp);
    finally
      DeleteDC(hdcMem);
      ReleaseDC(0, hdcScreen);
    end;

  finally
    DeleteObject(hbmp);
  end;
end;

function TColorPalette64LayeredPopup.GetSelectedColor: TColor;
begin
  if (FSelectedIndex >= 0) and (FSelectedIndex <= High(FPalette)) then
    Result := FPalette[FSelectedIndex]
  else
    Result := clNone;
end;

procedure TColorPalette64LayeredPopup.ClosePopup;
begin
  Close;
end;

procedure TColorPalette64LayeredPopup.WMActivate(var Msg: TWMActivate);
begin
  inherited;
  if Msg.Active = WA_INACTIVE then
    ClosePopup; // clic fora / perdre focus
end;

procedure TColorPalette64LayeredPopup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  idx: Integer;
begin
  inherited;
  idx := IndexAt(Point(X, Y));
  if idx <> FHoverIndex then
  begin
    FHoverIndex := idx;
    RenderAndUpdateLayered;
  end;
end;

procedure TColorPalette64LayeredPopup.MouseLeave(var Message: TMessage);
begin
  inherited;
  if FHoverIndex <> -1 then
  begin
    FHoverIndex := -1;
    RenderAndUpdateLayered;
  end;
end;

procedure TColorPalette64LayeredPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  idx: Integer;
begin
  inherited;
  SetFocus;

  if Button = mbLeft then
  begin
    idx := IndexAt(Point(X, Y));
    if idx >= 0 then
    begin
      FSelectedIndex := idx;
      if Assigned(FOnPicked) then
        FOnPicked(FPalette[FSelectedIndex]);
      ClosePopup; // selecciona i tanca
    end;
  end;
end;

procedure TColorPalette64LayeredPopup.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    ClosePopup; // ESC tanca
  end;
end;

procedure TColorPalette64LayeredPopup.WMGetDlgCode(var Msg: TWMGetDlgCode);
begin
  inherited;
  Msg.Result := Msg.Result or DLGC_WANTARROWS;
end;

end.
