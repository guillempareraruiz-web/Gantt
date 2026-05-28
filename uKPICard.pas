unit uKPICard;

// ============================================================================
// TKPICard - Panel pintado a mano que muestra un KPI tipo "tile" moderno:
//
//   +--------------------------------+
//   |  CAPTION                       |
//   |                                |
//   |   123.4                ▲ 12%   |
//   |   unidad opcional              |
//   |                                |
//   |   ~~~_/~^\_~  (sparkline)      |
//   +--------------------------------+
//
// Uso:
//   var Card := TKPICard.Create(Self);
//   Card.Parent := pnlPadre;
//   Card.SetBounds(Left, Top, 200, 100);
//   Card.Caption := 'OFs PLANIFICADAS';
//   Card.Unidad := '';
//   Card.SetValueAndSeries(47.0, [38,41,40,44,45,43,47]);
//   Card.ColorTone := kctVerde;
//
// Sin dependencias de DevExpress.
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Types, System.Math,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics;

type
  TKPIColorTone = (kctNeutro, kctVerde, kctAmbar, kctRojo, kctAzul);

  TKPICard = class(TPanel)
  private
    FCaption: string;
    FValue: Double;
    FUnidad: string;
    FSeries: TArray<Double>;
    FColorTone: TKPIColorTone;
    FFormatStr: string;
    FOnClickEx: TNotifyEvent;
    function DeltaPercent: Double;
    function AccentColor: TColor;
    function AccentColorSoft: TColor;
    procedure Paint; override;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure SetCaption(const V: string);
    procedure SetUnidad(const V: string);
    procedure SetColorTone(V: TKPIColorTone);
    procedure SetFormatStr(const V: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetValueAndSeries(const AValue: Double;
      const ASeries: array of Double);
    property Caption: string read FCaption write SetCaption;
    property Unidad: string read FUnidad write SetUnidad;
    property ColorTone: TKPIColorTone read FColorTone write SetColorTone;
    property FormatStr: string read FFormatStr write SetFormatStr;
    property OnClickEx: TNotifyEvent read FOnClickEx write FOnClickEx;
  end;

implementation

constructor TKPICard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  ParentBackground := False;
  Color := clWhite;
  Cursor := crHandPoint;
  DoubleBuffered := True;
  FFormatStr := '%.0f';
  FColorTone := kctAzul;
end;

procedure TKPICard.SetCaption(const V: string);
begin
  if FCaption = V then Exit;
  FCaption := V;
  Invalidate;
end;

procedure TKPICard.SetUnidad(const V: string);
begin
  if FUnidad = V then Exit;
  FUnidad := V;
  Invalidate;
end;

procedure TKPICard.SetColorTone(V: TKPIColorTone);
begin
  if FColorTone = V then Exit;
  FColorTone := V;
  Invalidate;
end;

procedure TKPICard.SetFormatStr(const V: string);
begin
  if FFormatStr = V then Exit;
  FFormatStr := V;
  Invalidate;
end;

procedure TKPICard.SetValueAndSeries(const AValue: Double;
  const ASeries: array of Double);
var
  I: Integer;
begin
  FValue := AValue;
  SetLength(FSeries, Length(ASeries));
  for I := 0 to High(ASeries) do
    FSeries[I] := ASeries[I];
  Invalidate;
end;

function TKPICard.DeltaPercent: Double;
var
  Prev: Double;
begin
  Result := 0;
  if Length(FSeries) < 2 then Exit;
  Prev := FSeries[High(FSeries) - 1];
  if Abs(Prev) < 0.0001 then Exit;
  Result := (FValue - Prev) / Prev * 100.0;
end;

function TKPICard.AccentColor: TColor;
begin
  case FColorTone of
    kctVerde:  Result := TColor($003BAA52);   // verde elegante
    kctAmbar:  Result := TColor($000099E6);   // ambar/naranja
    kctRojo:   Result := TColor($003B3BD9);   // rojo
    kctAzul:   Result := TColor($00995F1F);   // azul corporativo
  else
    Result := TColor($00808080);              // gris neutro
  end;
end;

function TKPICard.AccentColorSoft: TColor;
begin
  // Mezcla 15% accent + 85% blanco -> tono pastel para fondo sparkline
  case FColorTone of
    kctVerde:  Result := TColor($00E8F5EA);
    kctAmbar:  Result := TColor($00E8F0FA);
    kctRojo:   Result := TColor($00E8E8FA);
    kctAzul:   Result := TColor($00F5EEE8);
  else
    Result := TColor($00F0F0F0);
  end;
end;

procedure TKPICard.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
end;

procedure TKPICard.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
end;

procedure TKPICard.Paint;
var
  C: TCanvas;
  R, TR, SparkR, TmpR: TRect;
  S, ValueStr, DeltaStr: string;
  Delta: Double;
  I: Integer;
  ValW: Integer;
  MinV, MaxV, Range: Double;
  Pts: array of TPoint;
  ArrowH: Integer;
  ArrowPts: array[0..2] of TPoint;
const
  PadH = 14;
  PadV = 12;
begin
  C := Canvas;
  R := ClientRect;

  // Fondo blanco + borde fino
  C.Brush.Color := clWhite;
  C.Brush.Style := bsSolid;
  C.FillRect(R);

  // Borde inferior accent (3px) - efecto "tile" pro
  C.Brush.Color := AccentColor;
  C.FillRect(Rect(R.Left, R.Bottom - 3, R.Right, R.Bottom));

  // Borde general gris muy clarito
  C.Brush.Style := bsClear;
  C.Pen.Color := TColor($00E0E0E0);
  C.Pen.Width := 1;
  C.Pen.Style := psSolid;
  C.Rectangle(R.Left, R.Top, R.Right, R.Bottom);

  // ----- CAPTION (arriba) -----
  C.Font.Name := 'Segoe UI Semibold';
  C.Font.Height := -11;
  C.Font.Color := TColor($00808080);
  C.Font.Style := [];
  TR := Rect(R.Left + PadH, R.Top + PadV, R.Right - PadH, R.Top + PadV + 16);
  S := UpperCase(FCaption);
  DrawText(C.Handle, PChar(S), -1, TR,
    DT_SINGLELINE or DT_LEFT or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX);

  // ----- VALOR (gran, centrado vertical) -----
  C.Font.Name := 'Segoe UI Semibold';
  C.Font.Height := -28;
  C.Font.Color := TColor($002C3E50);
  ValueStr := Format(FFormatStr, [FValue]);
  if FUnidad <> '' then
    ValueStr := ValueStr;  // unidad se pinta aparte mas pequena
  TR := Rect(R.Left + PadH, R.Top + 32,
             R.Right - PadH, R.Top + 32 + 36);
  DrawText(C.Handle, PChar(ValueStr), -1, TR,
    DT_SINGLELINE or DT_LEFT or DT_VCENTER or DT_NOPREFIX);

  // Unidad pequena al lado del numero
  if FUnidad <> '' then
  begin
    // Calcular ancho del valor para colocar la unidad despues
    C.Font.Name := 'Segoe UI Semibold';
    C.Font.Height := -28;
    ValW := C.TextWidth(ValueStr);
    C.Font.Height := -12;
    C.Font.Name := 'Segoe UI';
    C.Font.Color := TColor($00808080);
    TmpR := Rect(R.Left + PadH + ValW + 4, R.Top + 32,
                 R.Right - PadH, R.Top + 32 + 36);
    DrawText(C.Handle, PChar(FUnidad), -1, TmpR,
      DT_SINGLELINE or DT_LEFT or DT_VCENTER or DT_NOPREFIX);
  end;

  // ----- DELTA % vs periodo anterior (arriba-derecha) -----
  Delta := DeltaPercent;
  if (Length(FSeries) >= 2) and (Abs(Delta) > 0.01) then
  begin
    if Delta >= 0 then
    begin
      C.Brush.Color := TColor($003BAA52);
      DeltaStr := Format('+%.1f%%', [Delta]);
    end
    else
    begin
      C.Brush.Color := TColor($003B3BD9);
      DeltaStr := Format('%.1f%%', [Delta]);
    end;
    C.Pen.Color := C.Brush.Color;

    // Triangulo (flecha) 7x8
    ArrowH := 8;
    if Delta >= 0 then
    begin
      ArrowPts[0] := Point(R.Right - PadH - 50, R.Top + PadV + 10);
      ArrowPts[1] := Point(R.Right - PadH - 50 + 7, R.Top + PadV + 10);
      ArrowPts[2] := Point(R.Right - PadH - 50 + 3, R.Top + PadV + 10 - ArrowH);
    end
    else
    begin
      ArrowPts[0] := Point(R.Right - PadH - 50, R.Top + PadV + 2);
      ArrowPts[1] := Point(R.Right - PadH - 50 + 7, R.Top + PadV + 2);
      ArrowPts[2] := Point(R.Right - PadH - 50 + 3, R.Top + PadV + 2 + ArrowH);
    end;
    Polygon(C.Handle, ArrowPts[0], 3);

    // Texto %
    C.Brush.Style := bsClear;
    C.Font.Name := 'Segoe UI Semibold';
    C.Font.Height := -11;
    C.Font.Color := C.Pen.Color;
    TmpR := Rect(R.Right - PadH - 40, R.Top + PadV,
                 R.Right - PadH, R.Top + PadV + 14);
    DrawText(C.Handle, PChar(DeltaStr), -1, TmpR,
      DT_SINGLELINE or DT_RIGHT or DT_VCENTER or DT_NOPREFIX);
  end;

  // ----- SPARKLINE (banda inferior) -----
  if Length(FSeries) >= 2 then
  begin
    SparkR := Rect(R.Left + PadH, R.Bottom - 28,
                   R.Right - PadH, R.Bottom - 6);

    // Fondo pastel
    C.Brush.Color := AccentColorSoft;
    C.Brush.Style := bsSolid;
    C.Pen.Style := psClear;
    C.RoundRect(SparkR.Left, SparkR.Top, SparkR.Right, SparkR.Bottom, 4, 4);

    // Calcular min/max
    MinV := FSeries[0];
    MaxV := FSeries[0];
    for I := 1 to High(FSeries) do
    begin
      if FSeries[I] < MinV then MinV := FSeries[I];
      if FSeries[I] > MaxV then MaxV := FSeries[I];
    end;
    Range := MaxV - MinV;
    if Range < 0.0001 then Range := 1;

    // Calcular puntos
    SetLength(Pts, Length(FSeries));
    for I := 0 to High(FSeries) do
    begin
      Pts[I].X := SparkR.Left + 4 +
                  Round(I * ((SparkR.Right - SparkR.Left - 8) / High(FSeries)));
      Pts[I].Y := SparkR.Bottom - 3 -
                  Round((FSeries[I] - MinV) / Range *
                        (SparkR.Bottom - SparkR.Top - 6));
    end;

    // Linea sparkline
    C.Pen.Color := AccentColor;
    C.Pen.Width := 2;
    C.Pen.Style := psSolid;
    Polyline(C.Handle, Pts[0], Length(Pts));

    // Punto final destacado
    C.Brush.Color := AccentColor;
    C.Brush.Style := bsSolid;
    C.Pen.Style := psClear;
    C.Ellipse(Pts[High(Pts)].X - 3, Pts[High(Pts)].Y - 3,
              Pts[High(Pts)].X + 3, Pts[High(Pts)].Y + 3);

    C.Pen.Width := 1;
  end;
end;

end.
