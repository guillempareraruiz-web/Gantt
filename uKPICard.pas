unit uKPICard;

// ============================================================================
// TKPICard - Panel pintado a mano (GDI+) que muestra un KPI tipo "tile"
// moderno con antialias real (sin lineas dentadas):
//
//   +--------------------------------+
//   |  CAPTION                       |
//   |                                |
//   |   123.4  h             ^ 12%   |
//   |                                |
//   |   ___/\__/^\___   (sparkline   |
//   |  ///////////////   con area)   |
//   +--------------------------------+
//
// Uso:
//   var Card := TKPICard.Create(Self);
//   Card.Parent := pnlPadre;
//   Card.SetBounds(Left, Top, 200, 120);
//   Card.Caption := 'OFs PLANIFICADAS';
//   Card.Unidad := '';
//   Card.SetValueAndSeries(47.0, [38,41,40,44,45,43,47]);
//   Card.ColorTone := kctVerde;
//
// Render: DevExpress GDI+ (dxGDIPlusClasses, wrapper OOP estable entre
// versiones). SmoothingMode antialias -> curvas y circulos suaves. Sparkline
// como curva suavizada (spline) + area con degradado vertical. Card con
// esquinas redondeadas reales + sombra suave. Estado hover eleva la sombra.
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Types, System.Math,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics,
  cxGeometry, dxCoreGraphics, dxGDIPlusAPI, dxGDIPlusClasses;

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
    FHot: Boolean;
    FKey: string;
    FBackColor: TColor;   // color del fondo alrededor de la card (= fondo dashboard)
    FDescripcion: string; // texto largo (para el dialogo de configuracion)
    FDescAmpliada: string;// descripcion larga (para el modal de detalle)
    FCategoria: string;   // categoria/familia (Nodos, OF, Operarios...)
    FOnDblClickEx: TNotifyEvent;
    function GetValue: Double;
    function GetSeries: TArray<Double>;
    function DeltaPercent: Double;
    function AccentColor: TdxAlphaColor;
    procedure PaintGdi(G: TdxGPGraphics);
    procedure Paint; override;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure DblClick; override;
    procedure SetCaption(const V: string);
    procedure SetUnidad(const V: string);
    procedure SetColorTone(V: TKPIColorTone);
    procedure SetFormatStr(const V: string);
    procedure SetBackColor(const V: TColor);
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetValueAndSeries(const AValue: Double;
      const ASeries: array of Double);
    property Caption: string read FCaption write SetCaption;
    property Unidad: string read FUnidad write SetUnidad;
    property ColorTone: TKPIColorTone read FColorTone write SetColorTone;
    property FormatStr: string read FFormatStr write SetFormatStr;
    // Color del fondo que rodea la card (el margen donde se difumina la sombra).
    // Debe coincidir con el fondo del contenedor para que no se vea un recuadro.
    property BackColor: TColor read FBackColor write SetBackColor;
    // Clave estable del KPI (Nodos, OFsPlan...). La usa el dashboard para
    // persistir el orden de las cards independientemente de su posicion.
    property Key: string read FKey write FKey;
    // Metadatos para el dialogo de configuracion (grid Visible|Titulo|Descripcion|Categoria).
    property Descripcion: string read FDescripcion write FDescripcion;
    // Descripcion larga ("que es y para que sirve") para el modal de detalle.
    property DescAmpliada: string read FDescAmpliada write FDescAmpliada;
    property Categoria: string read FCategoria write FCategoria;
    // Lectura del estado actual (para que el modal de detalle pinte lo mismo).
    property Value: Double read GetValue;
    property Series: TArray<Double> read GetSeries;
    property Tone: TKPIColorTone read FColorTone;
    property OnClickEx: TNotifyEvent read FOnClickEx write FOnClickEx;
    property OnDblClickEx: TNotifyEvent read FOnDblClickEx write FOnDblClickEx;
  end;

implementation

// ARGB -> TdxAlphaColor ($AARRGGBB).
function ARGB(A, R, G, B: Byte): TdxAlphaColor; inline;
begin
  Result := (Cardinal(A) shl 24) or (Cardinal(R) shl 16) or
            (Cardinal(G) shl 8) or Cardinal(B);
end;

// Aplica alpha a un TdxAlphaColor conservando el RGB.
function WithAlpha(AColor: TdxAlphaColor; AAlpha: Byte): TdxAlphaColor; inline;
begin
  Result := (AColor and $00FFFFFF) or (Cardinal(AAlpha) shl 24);
end;

constructor TKPICard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  ParentBackground := False;
  Cursor := crHandPoint;
  DoubleBuffered := True;
  FFormatStr := '%.0f';
  FColorTone := kctAzul;
  FBackColor := clBtnFace;   // el dashboard lo ajusta al fondo real
  Color := FBackColor;       // el Color del panel = fondo (evita erase blanco)
end;

procedure TKPICard.SetBackColor(const V: TColor);
begin
  if FBackColor = V then Exit;
  FBackColor := V;
  // El TPanel base rellena con Color en el borrado del fondo; igualarlo evita
  // que se vea un recuadro cuadrado blanco (Color por defecto) alrededor de la
  // card antes/alrededor de nuestro pintado GDI+.
  Color := V;
  Invalidate;
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

function TKPICard.GetValue: Double;
begin
  Result := FValue;
end;

function TKPICard.GetSeries: TArray<Double>;
begin
  Result := Copy(FSeries);
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

function TKPICard.AccentColor: TdxAlphaColor;
begin
  case FColorTone of
    kctVerde:  Result := ARGB(255, $2E, $A8, $54);   // verde
    kctAmbar:  Result := ARGB(255, $E6, $95, $00);   // ambar/naranja
    kctRojo:   Result := ARGB(255, $E0, $3B, $3B);   // rojo
    kctAzul:   Result := ARGB(255, $2D, $6C, $DF);   // azul corporativo
  else
    Result := ARGB(255, $80, $80, $80);              // gris neutro
  end;
end;

procedure TKPICard.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  FHot := True;
  Invalidate;
end;

procedure TKPICard.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  FHot := False;
  Invalidate;
end;

procedure TKPICard.DblClick;
begin
  inherited;
  if Assigned(FOnDblClickEx) then
    FOnDblClickEx(Self);
end;

procedure TKPICard.Paint;
var
  G: TdxGPGraphics;
begin
  G := TdxGPGraphics.Create(Canvas.Handle);
  try
    G.SmoothingMode := smAntiAlias;
    G.TextRenderingHint := TextRenderingHintClearTypeGridFit;
    PaintGdi(G);
  finally
    G.Free;
  end;
end;

procedure TKPICard.PaintGdi(G: TdxGPGraphics);
const
  PadH = 16;
  PadV = 14;
  Radius = 10;
  Shadow = 6;      // margen reservado para la sombra
var
  W, H: Integer;
  CardX, CardY, CardW, CardH: Integer;
  CardR: TRect;
  Path: TdxGPPath;
  Brush: TdxGPBrush;
  Accent, BgColor, CaptionColor, ValueColor, ParentColor: TdxAlphaColor;
  ValueStr, DeltaStr, CapStr: string;
  Delta: Double;
  I, Layer: Integer;
  MinV, MaxV, Range: Double;
  SparkL, SparkT, SparkB, SparkW, SparkH: Single;
  Pts: array of TdxPointF;
  DeltaColor: TdxAlphaColor;
  DeltaUp: Boolean;
  ArrX, ArrY: Single;
  ArrPts: array[0..2] of TdxPointF;
  BaseAlpha, LayerAlpha: Integer;
  ValW: Integer;
  SparkRect: TdxRectF;

  procedure DrawText(const S: string; const AFontName: string; AEmSize: Single;
    ABold: Boolean; AColor: TdxAlphaColor; const R: TdxRectF; ARight: Boolean);
  var
    F: TdxGPFont;
    B: TdxGPBrush;
    SF: TdxGPStringFormat;
    Sty: TdxGPFontStyle;
  begin
    if ABold then Sty := FontStyleBold else Sty := FontStyleRegular;
    F := TdxGPFont.Create(AFontName, AEmSize, Sty);
    B := TdxGPBrush.Create;
    SF := TdxGPStringFormat.Create;
    try
      B.Color := AColor;
      if ARight then SF.Alignment := StringAlignmentFar
      else SF.Alignment := StringAlignmentNear;
      SF.LineAlignment := StringAlignmentCenter;
      G.DrawString(S, F, B, R, SF);
    finally
      SF.Free;
      B.Free;
      F.Free;
    end;
  end;

begin
  W := ClientWidth;
  H := ClientHeight;

  Accent := AccentColor;
  BgColor := ARGB(255, 255, 255, 255);
  CaptionColor := ARGB(255, $8A, $92, $A6);
  ValueColor := ARGB(255, $2C, $3E, $50);
  // Fondo alrededor de la card = BackColor (fijado por el dashboard al color
  // del contenedor). Asi el margen donde se difumina la sombra se funde con el
  // fondo y no se ve ningun recuadro claro.
  ParentColor := dxColorToAlphaColor(FBackColor, 255);

  // 1) Fondo del margen (para difuminar la sombra sin recuadro).
  G.FillRectangle(Rect(0, 0, W, H), ParentColor);

  CardX := Shadow;
  CardY := Shadow;
  CardW := W - Shadow * 2;
  CardH := H - Shadow * 2;
  CardR := Rect(CardX, CardY, CardX + CardW, CardY + CardH);

  // 2) Sombra suave: varias capas concentricas de rect redondeado, cada una un
  //    pixel mas grande y con alpha DECRECIENTE hacia fuera. Al usar el MISMO
  //    radio + margen uniforme, se lee como un halo difuminado (no un recuadro).
  //    Ligero desplazamiento hacia abajo (offset Y) para sensacion de elevacion.
  if FHot then BaseAlpha := 22 else BaseAlpha := 12;
  for Layer := Shadow downto 1 do
  begin
    // Capa interior (Layer=1) mas opaca; exterior mas transparente.
    LayerAlpha := Max(1, BaseAlpha - (Layer - 1) * (BaseAlpha div Shadow));
    Path := TdxGPPath.Create;
    try
      Path.AddRoundRect(
        Rect(CardX - Layer, CardY - Layer + 2,
             CardX + CardW + Layer, CardY + CardH + Layer + 2),
        Radius + Layer, Radius + Layer);
      // Solo relleno (pen transparente) para no dibujar contornos duros.
      G.Path(Path, WithAlpha(ARGB(255, 40, 50, 70), 0),
        WithAlpha(ARGB(255, 40, 50, 70), LayerAlpha), 0);
    finally
      Path.Free;
    end;
  end;

  // 3) Cuerpo de la card (blanco, esquinas redondeadas). SIN borde visible: la
  //    separacion la da la sombra suave. Un borde claro (casi blanco) sobre el
  //    fondo claro se veia como un fino recuadro; se elimina (pen transparente).
  Path := TdxGPPath.Create;
  try
    Path.AddRoundRect(CardR, Radius, Radius);
    G.Path(Path, WithAlpha(BgColor, 0), BgColor, 0);
  finally
    Path.Free;
  end;

  // 4) Franja de acento a la izquierda (barra vertical) - toque "tile".
  //    Se deja un margen vertical (AccInset) para que no toque las esquinas
  //    redondeadas de la card: queda como una pastilla flotante, mas elegante.
  Path := TdxGPPath.Create;
  try
    Path.AddRoundRect(
      Rect(CardX + 3, CardY + Radius, CardX + 7, CardY + CardH - Radius), 2, 2);
    G.Path(Path, Accent, Accent, 1);
  finally
    Path.Free;
  end;

  // ----- CAPTION -----
  CapStr := UpperCase(FCaption);
  SparkRect := dxRectF(CardX + PadH, CardY + PadV, CardX + CardW - PadH, CardY + PadV + 16);
  DrawText(CapStr, 'Segoe UI', 8.5, True, CaptionColor, SparkRect, False);

  // ----- VALOR (grande) -----
  ValueStr := Format(FFormatStr, [FValue]);
  SparkRect := dxRectF(CardX + PadH, CardY + 30, CardX + CardW - PadH, CardY + 70);
  DrawText(ValueStr, 'Segoe UI', 22, True, ValueColor, SparkRect, False);

  // Unidad pequenya a la derecha del numero (medimos con el canvas clasico).
  if FUnidad <> '' then
  begin
    Canvas.Font.Name := 'Segoe UI';
    Canvas.Font.Height := -30;
    Canvas.Font.Style := [fsBold];
    ValW := Canvas.TextWidth(ValueStr);
    SparkRect := dxRectF(CardX + PadH + ValW + 6, CardY + 42,
      CardX + CardW - PadH, CardY + 66);
    DrawText(FUnidad, 'Segoe UI', 10, False, CaptionColor, SparkRect, False);
  end;

  // ----- DELTA % (arriba-derecha, con flecha triangular) -----
  Delta := DeltaPercent;
  if (Length(FSeries) >= 2) and (Abs(Delta) > 0.01) then
  begin
    DeltaUp := Delta >= 0;
    if DeltaUp then
    begin
      DeltaColor := ARGB(255, $2E, $A8, $54);
      DeltaStr := Format('+%.1f%%', [Delta]);
    end
    else
    begin
      DeltaColor := ARGB(255, $E0, $3B, $3B);
      DeltaStr := Format('%.1f%%', [Delta]);
    end;

    // Situado a la DERECHA, a la altura del valor grande (no en la fila del
    // caption, para no colisionar con titulos largos). Tamanyo mayor y legible.
    ArrX := CardX + CardW - PadH - 62;
    ArrY := CardY + 44;
    if DeltaUp then
    begin
      ArrPts[0] := dxPointF(ArrX,      ArrY + 10);
      ArrPts[1] := dxPointF(ArrX + 10, ArrY + 10);
      ArrPts[2] := dxPointF(ArrX + 5,  ArrY);
    end
    else
    begin
      ArrPts[0] := dxPointF(ArrX,      ArrY);
      ArrPts[1] := dxPointF(ArrX + 10, ArrY);
      ArrPts[2] := dxPointF(ArrX + 5,  ArrY + 10);
    end;
    G.Polygon(ArrPts, DeltaColor, DeltaColor, 1, gppsSolid);

    SparkRect := dxRectF(CardX + CardW - PadH - 50, CardY + 40,
      CardX + CardW - PadH, CardY + 58);
    DrawText(DeltaStr, 'Segoe UI', 10.5, True, DeltaColor, SparkRect, True);
  end;

  // ----- SPARKLINE (banda inferior): area degradada + curva suave -----
  if Length(FSeries) >= 2 then
  begin
    SparkL := CardX + PadH;
    SparkB := CardY + CardH - 14;
    SparkT := SparkB - 26;
    SparkW := CardW - PadH * 2;
    SparkH := SparkB - SparkT;

    MinV := FSeries[0];
    MaxV := FSeries[0];
    for I := 1 to High(FSeries) do
    begin
      if FSeries[I] < MinV then MinV := FSeries[I];
      if FSeries[I] > MaxV then MaxV := FSeries[I];
    end;
    Range := MaxV - MinV;
    if Range < 0.0001 then Range := 1;

    SetLength(Pts, Length(FSeries));
    for I := 0 to High(FSeries) do
    begin
      Pts[I].X := SparkL + I * (SparkW / High(FSeries));
      Pts[I].Y := SparkB - (FSeries[I] - MinV) / Range * (SparkH - 3);
    end;

    // Area bajo la curva con degradado vertical (acento translucido -> transp).
    // El brush de degradado se aplica al path cerrado (curva superior + base).
    Path := TdxGPPath.Create;
    Brush := TdxGPBrush.Create;
    try
      // Borde superior: polilinea de puntos + bajada a la base y cierre.
      Path.AddPolyline(Pts);
      Path.AddLine(Pts[High(Pts)].X, Pts[High(Pts)].Y, Pts[High(Pts)].X, SparkB);
      Path.AddLine(Pts[High(Pts)].X, SparkB, Pts[0].X, SparkB);
      Path.FigureFinish;

      Brush.Style := gpbsGradient;
      Brush.GradientMode := gpbgmVertical;
      Brush.GradientPoints.Add(0.0, WithAlpha(Accent, 70));
      Brush.GradientPoints.Add(1.0, WithAlpha(Accent, 0));
      Brush.SetTargetRect(Rect(Round(SparkL), Round(SparkT),
        Round(SparkL + SparkW), Round(SparkB) + 2));

      G.Path(Path, nil, Brush);   // relleno con degradado, sin borde
    finally
      Brush.Free;
      Path.Free;
    end;

    // Linea (curva suave) por encima del area. El overload de Curve para
    // TdxPointF usa TColor + alpha (no hay version TdxAlphaColor directa).
    G.Curve(Pts, dxAlphaColorToColor(Accent), 2, psSolid, 255);

    // Punto final destacado (halo + nucleo).
    G.Ellipse(dxRectF(Pts[High(Pts)].X - 6, Pts[High(Pts)].Y - 6,
      Pts[High(Pts)].X + 6, Pts[High(Pts)].Y + 6),
      WithAlpha(Accent, 0), WithAlpha(Accent, 60));
    G.Ellipse(dxRectF(Pts[High(Pts)].X - 3, Pts[High(Pts)].Y - 3,
      Pts[High(Pts)].X + 3, Pts[High(Pts)].Y + 3), Accent, Accent);
  end;
end;

end.
