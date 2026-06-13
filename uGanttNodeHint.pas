unit uGanttNodeHint;

interface

uses
  Winapi.Windows, System.SysUtils, System.Types, Vcl.Graphics, Vcl.Controls,
  System.Classes, Math, System.StrUtils, Winapi.Messages;

type
  TGanttNodeHintWindow = class(THintWindow)
  private
    FMarginX: Integer;   // padding horizontal interior
    FMarginY: Integer;   // padding vertical interior
    FLineGap: Integer;   // espai extra entre linies
    FKeyW: Integer;      // ample reservat per a la columna "clau" (px)
    function MeasureLineHeight: Integer;
  protected
    procedure Paint; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
  public
    constructor Create(AOwner: TComponent); override;
    function CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect; override;
  end;

implementation

const
  // Paleta del hint (estil "card" net)
  clHintBack   = $00FAF9F7;   // fons gris molt clar (BGR)
  clHintBorder = $00D8D2CC;   // vora suau
  clHintKey    = $00806858;   // clau: gris-blau apagat
  clHintVal    = $00403830;   // valor: gairebe negre
  clHintShadow = $00C8C2BC;   // linia d'ombra inferior

constructor TGanttNodeHintWindow.Create(AOwner: TComponent);
begin
  inherited;
  Color := clHintBack;
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 8;
  FMarginX := 10;
  FMarginY := 8;
  FLineGap := 3;
  FKeyW := 0;
  DoubleBuffered := True;
end;

procedure TGanttNodeHintWindow.CreateParams(var Params: TCreateParams);
begin
  inherited;
  // Ombra nativa de Windows: dona profunditat sense pintar res.
  Params.WindowClass.Style := Params.WindowClass.Style or CS_DROPSHADOW;
end;

procedure TGanttNodeHintWindow.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Message.Result := HTTRANSPARENT; // no roba ratoli
end;

procedure TGanttNodeHintWindow.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE; // no agafa focus
end;

function TGanttNodeHintWindow.MeasureLineHeight: Integer;
begin
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [];
  Result := Canvas.TextHeight('Ag') + FLineGap;
end;

function TGanttNodeHintWindow.CalcHintRect(MaxWidth: Integer; const AHint: string;
  AData: Pointer): TRect;
var
  lines: TStringDynArray;
  i, p, lineH, maxKeyW, maxValW, kw, vw, totalW: Integer;
  keyPart, valPart: string;
begin
  lines := AHint.Split([sLineBreak]);
  lineH := MeasureLineHeight;

  // Mesura per separat la columna de claus i la de valors per alinear-les.
  maxKeyW := 0;
  maxValW := 0;
  for i := 0 to High(lines) do
  begin
    p := Pos(':', lines[i]);
    if p > 0 then
    begin
      keyPart := Copy(lines[i], 1, p);
      valPart := TrimLeft(Copy(lines[i], p + 1, MaxInt));
      Canvas.Font.Style := [fsBold];
      kw := Canvas.TextWidth(keyPart);
      Canvas.Font.Style := [];
      vw := Canvas.TextWidth(valPart);
    end
    else
    begin
      Canvas.Font.Style := [fsBold];
      kw := Canvas.TextWidth(lines[i]);
      Canvas.Font.Style := [];
      vw := 0;
    end;
    if kw > maxKeyW then maxKeyW := kw;
    if vw > maxValW then maxValW := vw;
  end;

  FKeyW := maxKeyW + 10; // gap entre clau i valor
  totalW := FMarginX * 2 + FKeyW + maxValW;

  Result := Rect(0, 0,
    Min(MaxWidth, totalW),
    Length(lines) * lineH + FMarginY * 2);
end;

procedure TGanttNodeHintWindow.Paint;
var
  r: TRect;
  lines: TStringDynArray;
  i, y, p, lineH, valX: Integer;
  keyPart, valPart, cap: string;
begin
  r := ClientRect;

  // Fons + vora suau
  Canvas.Brush.Color := Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(r);

  Canvas.Pen.Color := clHintBorder;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(r);

  Canvas.Brush.Style := bsClear;
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 8;
  SetBkMode(Canvas.Handle, TRANSPARENT);

  cap := Caption;
  lines := cap.Split([sLineBreak]);
  lineH := MeasureLineHeight;
  if FKeyW <= 0 then FKeyW := 90;
  valX := r.Left + FMarginX + FKeyW;

  y := r.Top + FMarginY;
  for i := 0 to High(lines) do
  begin
    p := Pos(':', lines[i]);
    if p > 0 then
    begin
      keyPart := Copy(lines[i], 1, p);
      valPart := TrimLeft(Copy(lines[i], p + 1, MaxInt));

      // Clau en negreta, color apagat
      Canvas.Font.Style := [fsBold];
      Canvas.Font.Color := clHintKey;
      Canvas.TextOut(r.Left + FMarginX, y, keyPart);

      // Valor normal, color fosc
      Canvas.Font.Style := [];
      Canvas.Font.Color := clHintVal;
      Canvas.TextOut(valX, y, valPart);
    end
    else
    begin
      // Linia sense ":" -> titol en negreta
      Canvas.Font.Style := [fsBold];
      Canvas.Font.Color := clHintVal;
      Canvas.TextOut(r.Left + FMarginX, y, lines[i]);
      Canvas.Font.Style := [];
    end;

    Inc(y, lineH);
  end;
end;

end.
