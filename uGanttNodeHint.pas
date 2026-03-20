unit uGanttNodeHint;

interface

uses
  Winapi.Windows, System.SysUtils, System.Types, Vcl.Graphics, Vcl.Controls,
  System.Classes, Math, System.StrUtils, Winapi.Messages;

type
  TGanttNodeHintWindow = class(THintWindow)
  private
    FMargin: Integer;
    FLineH: Integer;
  protected
    procedure Paint; override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
  public
    constructor Create(AOwner: TComponent); override;
    function CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect; override;
  end;

implementation

constructor TGanttNodeHintWindow.Create(AOwner: TComponent);
begin
  inherited;
  Color := $00FFFFE1; // clInfoBk (però així controlem)
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 9;
  FMargin := 8;
  FLineH := 16;
end;

procedure TGanttNodeHintWindow.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Message.Result := HTTRANSPARENT; // no roba ratolí
end;
procedure TGanttNodeHintWindow.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE; // no agafa focus
end;

function TGanttNodeHintWindow.CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect;
var
  lines: TStringDynArray;
  i: Integer;
  w, maxW, h, th: Integer;
begin
  lines := AHint.Split([sLineBreak]);

  maxW := 0;
  for i := 0 to High(lines) do
  begin
    w := Canvas.TextWidth(lines[i]);
    if w > maxW then maxW := w;
  end;

  th := Canvas.TextHeight('A');
  //h := (Length(lines) * FLineH) + (FMargin * 2);
  h := (Length(lines) * th) + (FMargin * 2);
  Result := Rect(0, 0, Min(MaxWidth, maxW + FMargin * 2), h);
end;


procedure TGanttNodeHintWindow.Paint;
var
  r: TRect;
  sl: TStringList;
  i, y: Integer;
  s: string;
  p: Integer;
  keyPart: string;
begin
  r := ClientRect;

  Canvas.Brush.Color := Color;
  Canvas.FillRect(r);

  Canvas.Pen.Color := clGray;
  Canvas.Rectangle(r);

  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 7;

  r.Top := r.Top + FMargin;
  r.Left := r.Left + FMargin;

  drawtext( canvas.Handle,  PWideChar( CAption ), length(CAption), r, DT_TOP or DT_WORDBREAK);

  // Canvas.TextOut(FMargin , FMargin, Caption );

   Exit;

  sl := TStringList.Create;
  try
    sl.Text := Caption; // <-- aquí es fa el "split" per salts de línia

    y := FMargin;
    for i := 0 to sl.Count - 1 do
    begin
      s := sl[i];

      // mini “format”: si ve "Key: Value", fem Key en negreta
      p := Pos(':', s);
      if p > 0 then
      begin
        keyPart := Copy(s, 1, p); // inclou ":"

        Canvas.Font.Style := [fsBold];
        Canvas.TextOut(FMargin, y, keyPart);

        Canvas.Font.Style := [];
        Canvas.TextOut(
          FMargin + Canvas.TextWidth(keyPart) + 4,
          y,
          TrimLeft(Copy(s, p + 1, MaxInt))
        );
      end
      else
      begin
        Canvas.Font.Style := [fsBold];
        Canvas.TextOut(FMargin, y, s);
        Canvas.Font.Style := [];
      end;

      Inc(y, FLineH);
    end;
  finally
    sl.Free;
  end;
end;

end.
