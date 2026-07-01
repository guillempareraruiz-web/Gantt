unit uDashWidgets;

// ============================================================================
// Widgets visuales del Dashboard (render GDI+ con antialias, mismo estilo que
// TKPICard). Sustituyen bloques de texto plano por indicadores graficos:
//
//   TDonutWidget   : anillo de progreso con % (o "n/m") en el centro. Para
//                    "Nodos 21/21", "OFs 2/2", "Pedidos 1/1".
//   TGaugeWidget   : semicirculo tipo velocimetro 0..100 con aguja. Para
//                    "Saturacion media centros".
//   TTimelineWidget: barra horizontal Inicio -> Bloqueo -> Fin del proyecto.
//
// Todos:
//   - Fondo = BackColor (se funde con el contenedor, sin recuadro).
//   - Titulo (Caption) arriba, opcional.
//   - Colores por tono (reutiliza la idea de TKPICard).
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Types, System.Math, System.DateUtils,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics,
  cxGeometry, dxCoreGraphics, dxGDIPlusAPI, dxGDIPlusClasses;

type
  TDashTone = (dtAzul, dtVerde, dtAmbar, dtRojo, dtNeutro);

  // --- Base comun: panel GDI+ con fondo fundido y titulo ---
  TDashWidgetBase = class(TPanel)
  private
    FCaption: string;
    FBackColor: TColor;
    FTone: TDashTone;
    procedure SetBackColor(const V: TColor);
    procedure SetCaption(const V: string);
    procedure SetTone(const V: TDashTone);
  protected
    function Accent: TdxAlphaColor;
    procedure PaintContent(G: TdxGPGraphics; const R: TRect); virtual; abstract;
    procedure Paint; override;
    // Rect interior del contenido (bajo el titulo).
    function ContentRect: TRect;
    // Dibuja el titulo (si hay) y devuelve el alto consumido.
    procedure DrawTitle(G: TdxGPGraphics);
  public
    constructor Create(AOwner: TComponent); override;
    property Caption: string read FCaption write SetCaption;
    property BackColor: TColor read FBackColor write SetBackColor;
    property Tone: TDashTone read FTone write SetTone;
  end;

  // --- Donut de progreso (valor / total) ---
  TDonutWidget = class(TDashWidgetBase)
  private
    FValue: Integer;
    FTotal: Integer;
    procedure PaintContent(G: TdxGPGraphics; const R: TRect); override;
  public
    procedure SetData(AValue, ATotal: Integer);
  end;

  // --- Gauge semicircular 0..100 con aguja ---
  TGaugeWidget = class(TDashWidgetBase)
  private
    FValue: Double;     // 0..100
    FUnidad: string;
    procedure PaintContent(G: TdxGPGraphics; const R: TRect); override;
  public
    procedure SetData(AValue: Double; const AUnidad: string = '%');
  end;

  // --- Timeline Inicio -> Bloqueo -> Fin ---
  TTimelineWidget = class(TDashWidgetBase)
  private
    FInicio, FBloqueo, FFin: TDateTime;
    FTieneBloqueo: Boolean;
    procedure PaintContent(G: TdxGPGraphics; const R: TRect); override;
  public
    procedure SetData(const AInicio, AFin: TDateTime;
      ATieneBloqueo: Boolean; const ABloqueo: TDateTime);
  end;

  // --- Resumen de sincronizacion ERP (Total/Nuevos/Actualizados/... ) ---
  // Muestra una fila de contadores tipo "chip" con el resultado de la ultima
  // comprobacion contra el ERP.
  TErpSyncWidget = class(TDashWidgetBase)
  private
    FTotal, FNuevos, FActualizados, FSinCambios, FObsoletos: Integer;
    FEstado: string;     // texto de estado ("Nunca comprobado", "Comprobando...", fecha)
    FHayDatos: Boolean;
    procedure PaintContent(G: TdxGPGraphics; const R: TRect); override;
  public
    procedure SetResumen(ATotal, ANuevos, AActualizados, ASinCambios,
      AObsoletos: Integer; const AEstado: string);
    procedure SetEstado(const AEstado: string);
    // True si la ultima comprobacion detecto novedades (nuevos o actualizados).
    function HayNovedades: Boolean;
  end;

  // --- Handle de arrastre (icono de 6 puntos) para reordenar SECCIONES ---
  // Se coloca arriba-izquierda de cada seccion; el drag solo arranca desde aqui,
  // dejando el resto de la seccion interactiva. El form gestiona el arrastre via
  // OnMouseDown/Move/Up. Es TCustomControl (con ventana) para pintar SIEMPRE por
  // encima del panel de su seccion.
  TDragHandle = class(TCustomControl)
  private
    FBackColor: TColor;
    FHot: Boolean;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property BackColor: TColor read FBackColor write FBackColor;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

function ARGB(A, R, G, B: Byte): TdxAlphaColor; inline;
begin
  Result := (Cardinal(A) shl 24) or (Cardinal(R) shl 16) or
            (Cardinal(G) shl 8) or Cardinal(B);
end;

function WithAlpha(AColor: TdxAlphaColor; AAlpha: Byte): TdxAlphaColor; inline;
begin
  Result := (AColor and $00FFFFFF) or (Cardinal(AAlpha) shl 24);
end;

// Dibuja texto GDI+ centrado en un rect.
procedure DrawGpText(G: TdxGPGraphics; const S, AFontName: string;
  AEmSize: Single; ABold: Boolean; AColor: TdxAlphaColor; const R: TdxRectF;
  AHAlign: TdxGpStringAlignment = StringAlignmentCenter);
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
    SF.Alignment := AHAlign;
    SF.LineAlignment := StringAlignmentCenter;
    G.DrawString(S, F, B, R, SF);
  finally
    SF.Free;
    B.Free;
    F.Free;
  end;
end;

{ TDashWidgetBase }

constructor TDashWidgetBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  ParentBackground := False;
  DoubleBuffered := True;
  FBackColor := clWhite;
  Color := FBackColor;
  FTone := dtAzul;
end;

procedure TDashWidgetBase.SetBackColor(const V: TColor);
begin
  if FBackColor = V then Exit;
  FBackColor := V;
  Color := V;
  Invalidate;
end;

procedure TDashWidgetBase.SetCaption(const V: string);
begin
  if FCaption = V then Exit;
  FCaption := V;
  Invalidate;
end;

procedure TDashWidgetBase.SetTone(const V: TDashTone);
begin
  if FTone = V then Exit;
  FTone := V;
  Invalidate;
end;

function TDashWidgetBase.Accent: TdxAlphaColor;
begin
  case FTone of
    dtVerde:  Result := ARGB(255, $2E, $A8, $54);
    dtAmbar:  Result := ARGB(255, $E6, $95, $00);
    dtRojo:   Result := ARGB(255, $E0, $3B, $3B);
    dtNeutro: Result := ARGB(255, $80, $88, $95);
  else
    Result := ARGB(255, $2D, $6C, $DF);   // azul
  end;
end;

function TDashWidgetBase.ContentRect: TRect;
begin
  Result := ClientRect;
  if FCaption <> '' then
    Inc(Result.Top, 22);   // reservar franja del titulo
end;

procedure TDashWidgetBase.DrawTitle(G: TdxGPGraphics);
var
  R: TdxRectF;
begin
  if FCaption = '' then Exit;
  R := dxRectF(6, 6, ClientWidth - 6, 22);
  DrawGpText(G, UpperCase(FCaption), 'Segoe UI', 8.5, True,
    ARGB(255, $8A, $92, $A6), R, StringAlignmentNear);
end;

procedure TDashWidgetBase.Paint;
var
  G: TdxGPGraphics;
begin
  G := TdxGPGraphics.Create(Canvas.Handle);
  try
    G.SmoothingMode := smAntiAlias;
    G.TextRenderingHint := TextRenderingHintClearTypeGridFit;
    // Fondo fundido con el contenedor.
    G.FillRectangle(Rect(0, 0, ClientWidth, ClientHeight),
      dxColorToAlphaColor(FBackColor, 255));
    DrawTitle(G);
    PaintContent(G, ContentRect);
  finally
    G.Free;
  end;
end;

{ TDonutWidget }

procedure TDonutWidget.SetData(AValue, ATotal: Integer);
begin
  FValue := AValue;
  FTotal := ATotal;
  Invalidate;
end;

procedure TDonutWidget.PaintContent(G: TdxGPGraphics; const R: TRect);
var
  D, CX, CY, Thick: Integer;
  Box: TRect;
  Pct: Double;
  SweepAng: Single;
  Path: TdxGPPath;
  Pen: TdxGPPen;
  Ac: TdxAlphaColor;
  CenterTxt: string;
  TR: TdxRectF;
begin
  Ac := Accent;
  if FTotal > 0 then Pct := FValue / FTotal else Pct := 0;
  if Pct > 1 then Pct := 1;

  // Circulo centrado, con margen. Grosor del anillo proporcional.
  D := Min(R.Width, R.Height) - 12;
  if D < 24 then D := 24;
  Thick := Max(6, D div 8);
  CX := R.Left + R.Width div 2;
  CY := R.Top + R.Height div 2;
  Box := Rect(CX - D div 2, CY - D div 2, CX + D div 2, CY + D div 2);

  // Pista de fondo (anillo gris claro completo).
  G.Arc(Box, 0, 360, WithAlpha(ARGB(255, $C8, $CE, $D8), 90), Thick);

  // Arco de progreso (desde -90 grados = arriba, en sentido horario).
  SweepAng := Pct * 360;
  if SweepAng > 0 then
  begin
    Path := TdxGPPath.Create;
    Pen := TdxGPPen.Create(Ac, Thick);
    try
      Pen.LineStartCapStyle := gpcsRound;
      Pen.LineEndCapStyle := gpcsRound;
      Path.AddArc(Box.Left, Box.Top, Box.Width, Box.Height, -90, SweepAng);
      G.Path(Path, Pen, nil);
    finally
      Pen.Free;
      Path.Free;
    end;
  end;

  // Texto central: porcentaje grande + "n/m" debajo.
  CenterTxt := Format('%.0f%%', [Pct * 100]);
  TR := dxRectF(Box.Left, Box.Top + 2, Box.Right, CY + 4);
  DrawGpText(G, CenterTxt, 'Segoe UI', 15, True, ARGB(255, $2C, $3E, $50), TR);

  TR := dxRectF(Box.Left, CY + 2, Box.Right, Box.Bottom - 2);
  DrawGpText(G, Format('%d / %d', [FValue, FTotal]), 'Segoe UI', 8.5, False,
    ARGB(255, $8A, $92, $A6), TR);
end;

{ TGaugeWidget }

procedure TGaugeWidget.SetData(AValue: Double; const AUnidad: string);
begin
  FValue := Max(0, Min(100, AValue));
  FUnidad := AUnidad;
  Invalidate;
end;

procedure TGaugeWidget.PaintContent(G: TdxGPGraphics; const R: TRect);
var
  D, CX, CY, Thick: Integer;
  Box: TRect;
  Frac: Double;
  Path: TdxGPPath;
  Pen: TdxGPPen;
  Ac, ArcCol: TdxAlphaColor;
  TR: TdxRectF;
  AngDeg, Rad, NX, NY: Double;
begin
  Frac := FValue / 100.0;

  // El color del arco de valor cambia con la saturacion: verde/ambar/rojo.
  if FValue < 60 then ArcCol := ARGB(255, $2E, $A8, $54)
  else if FValue < 85 then ArcCol := ARGB(255, $E6, $95, $00)
  else ArcCol := ARGB(255, $E0, $3B, $3B);
  Ac := ArcCol;

  // Semicirculo (media luna hacia arriba). Reservamos ~26px inferiores para el
  // valor numerico. El diametro se acota tanto por ancho como por alto para que
  // el arco NUNCA se salga del widget.
  D := Min(R.Width - 24, (R.Height - 30) * 2);
  if D < 40 then D := 40;
  Thick := Max(7, D div 12);
  CX := R.Left + R.Width div 2;
  // Base del semicirculo: deja 26px de aire abajo para el texto del valor.
  CY := R.Bottom - 26;
  Box := Rect(CX - D div 2, CY - D div 2, CX + D div 2, CY + D div 2);

  // Pista de fondo (semicirculo 180..360, es decir la mitad superior).
  G.Arc(Box, 180, 180, WithAlpha(ARGB(255, $C8, $CE, $D8), 90), Thick);

  // Arco de valor (desde 180 grados, barriendo Frac*180).
  if Frac > 0 then
  begin
    Path := TdxGPPath.Create;
    Pen := TdxGPPen.Create(Ac, Thick);
    try
      Pen.LineStartCapStyle := gpcsRound;
      Pen.LineEndCapStyle := gpcsRound;
      Path.AddArc(Box.Left, Box.Top, Box.Width, Box.Height, 180, Frac * 180);
      G.Path(Path, Pen, nil);
    finally
      Pen.Free;
      Path.Free;
    end;
  end;

  // Aguja: desde el centro hacia el angulo del valor.
  AngDeg := 180 + Frac * 180;
  Rad := AngDeg * Pi / 180;
  NX := CX + Cos(Rad) * (D / 2 - Thick);
  NY := CY + Sin(Rad) * (D / 2 - Thick);
  G.Line(CX, CY, Round(NX), Round(NY), ARGB(255, $2C, $3E, $50), 2.5);
  G.Ellipse(dxRectF(CX - 4, CY - 4, CX + 4, CY + 4),
    ARGB(255, $2C, $3E, $50), ARGB(255, $2C, $3E, $50));

  // Valor numerico centrado bajo el semicirculo.
  TR := dxRectF(R.Left, CY + 4, R.Right, R.Bottom);
  DrawGpText(G, Format('%.1f%s', [FValue, FUnidad]), 'Segoe UI', 13, True,
    ARGB(255, $2C, $3E, $50), TR);
end;

{ TTimelineWidget }

procedure TTimelineWidget.SetData(const AInicio, AFin: TDateTime;
  ATieneBloqueo: Boolean; const ABloqueo: TDateTime);
begin
  FInicio := AInicio;
  FFin := AFin;
  FTieneBloqueo := ATieneBloqueo;
  FBloqueo := ABloqueo;
  Invalidate;
end;

procedure TTimelineWidget.PaintContent(G: TdxGPGraphics; const R: TRect);
var
  BarY, BarL, BarR: Integer;
  Ac: TdxAlphaColor;
  Frac: Double;
  BX: Integer;
  TR: TdxRectF;

  // Hito: punto en la barra, etiqueta ARRIBA y fecha ABAJO.
  procedure Hito(AX: Integer; AColor: TdxAlphaColor; const ALabel, AFecha: string);
  begin
    G.Ellipse(dxRectF(AX - 5, BarY - 5, AX + 5, BarY + 5), AColor, AColor);
    if ALabel <> '' then
      DrawGpText(G, ALabel, 'Segoe UI', 7.5, True, AColor,
        dxRectF(AX - 55, BarY - 22, AX + 55, BarY - 8));
    if AFecha <> '' then
      DrawGpText(G, AFecha, 'Segoe UI', 7.5, False, ARGB(255, $8A, $92, $A6),
        dxRectF(AX - 55, BarY + 8, AX + 55, BarY + 22));
  end;

begin
  Ac := Accent;
  // Barra ligeramente por debajo del centro para dejar aire a la etiqueta
  // superior (que no debe tocar el titulo del widget).
  BarY := R.Top + R.Height div 2 + 4;
  BarL := R.Left + 55;
  BarR := R.Right - 55;
  if BarR <= BarL then Exit;

  // Linea base (gris) y tramo planificado (acento) encima.
  G.Line(BarL, BarY, BarR, BarY, WithAlpha(ARGB(255, $C8, $CE, $D8), 140), 4);

  if (FInicio > 0) and (FFin > FInicio) then
  begin
    G.Line(BarL, BarY, BarR, BarY, WithAlpha(Ac, 160), 4);

    // Hito inicio (izquierda) y fin (derecha).
    Hito(BarL, Ac, 'INICIO', FormatDateTime('dd/mm/yy', FInicio));
    Hito(BarR, Ac, 'FIN', FormatDateTime('dd/mm/yy', FFin));

    // Hito bloqueo (posicion proporcional dentro del rango).
    if FTieneBloqueo and (FBloqueo >= FInicio) and (FBloqueo <= FFin) then
    begin
      Frac := (FBloqueo - FInicio) / (FFin - FInicio);
      BX := BarL + Round(Frac * (BarR - BarL));
      Hito(BX, ARGB(255, $E0, $3B, $3B), 'BLOQUEO',
        FormatDateTime('dd/mm/yy', FBloqueo));
    end;
  end
  else
  begin
    TR := dxRectF(R.Left, R.Top, R.Right, R.Bottom);
    DrawGpText(G, 'Sin fechas de plan', 'Segoe UI', 9, False,
      ARGB(255, $8A, $92, $A6), TR);
  end;
end;

{ TErpSyncWidget }

procedure TErpSyncWidget.SetResumen(ATotal, ANuevos, AActualizados,
  ASinCambios, AObsoletos: Integer; const AEstado: string);
begin
  FTotal := ATotal;
  FNuevos := ANuevos;
  FActualizados := AActualizados;
  FSinCambios := ASinCambios;
  FObsoletos := AObsoletos;
  FEstado := AEstado;
  FHayDatos := True;
  Invalidate;
end;

procedure TErpSyncWidget.SetEstado(const AEstado: string);
begin
  FEstado := AEstado;
  Invalidate;
end;

function TErpSyncWidget.HayNovedades: Boolean;
begin
  Result := FHayDatos and ((FNuevos > 0) or (FActualizados > 0));
end;

procedure TErpSyncWidget.PaintContent(G: TdxGPGraphics; const R: TRect);
var
  X, Y, ChipW, ChipH, Gap: Integer;

  // Dibuja un chip: numero grande + etiqueta debajo, con color de acento.
  procedure Chip(var AX: Integer; const ANum: string; const ALbl: string;
    ACol: TdxAlphaColor);
  var
    Path: TdxGPPath;
  begin
    Path := TdxGPPath.Create;
    try
      Path.AddRoundRect(Rect(AX, Y, AX + ChipW, Y + ChipH), 8, 8);
      G.Path(Path, WithAlpha(ACol, 40), WithAlpha(ACol, 22), 1);
    finally
      Path.Free;
    end;
    DrawGpText(G, ANum, 'Segoe UI', 17, True, ACol,
      dxRectF(AX, Y + 8, AX + ChipW, Y + 34));
    DrawGpText(G, ALbl, 'Segoe UI', 8, False, ARGB(255, $8A, $92, $A6),
      dxRectF(AX, Y + 36, AX + ChipW, Y + 52));
    Inc(AX, ChipW + Gap);
  end;

begin
  if not FHayDatos then
  begin
    DrawGpText(G, FEstado, 'Segoe UI', 9.5, False, ARGB(255, $8A, $92, $A6),
      dxRectF(R.Left, R.Top, R.Right, R.Top + 40), StringAlignmentNear);
    Exit;
  end;

  Gap := 10;
  ChipH := 56;
  // 5 chips repartidos por el ancho disponible.
  ChipW := (R.Width - Gap * 4) div 5;
  if ChipW < 70 then ChipW := 70;
  X := R.Left;
  Y := R.Top + 2;

  Chip(X, IntToStr(FTotal),        'Total',       ARGB(255, $2D, $6C, $DF));
  Chip(X, IntToStr(FNuevos),       'Nuevos',      ARGB(255, $2E, $A8, $54));
  Chip(X, IntToStr(FActualizados), 'Actualizados',ARGB(255, $E6, $95, $00));
  Chip(X, IntToStr(FSinCambios),   'Sin cambios', ARGB(255, $80, $88, $95));
  Chip(X, IntToStr(FObsoletos),    'Obsoletos',   ARGB(255, $E0, $3B, $3B));

  // Estado (fecha ultima comprobacion) debajo.
  DrawGpText(G, FEstado, 'Segoe UI', 8, False, ARGB(255, $9A, $A2, $B0),
    dxRectF(R.Left, Y + ChipH + 4, R.Right, Y + ChipH + 20), StringAlignmentNear);
end;

{ TDragHandle }

constructor TDragHandle.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 12;
  Height := 14;
  Cursor := crSizeAll;
  FBackColor := clWhite;
  ShowHint := True;
  Hint := 'Arrastra para reordenar la secci'#243'n';
end;

procedure TDragHandle.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  FHot := True;
  Invalidate;
end;

procedure TDragHandle.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  FHot := False;
  Invalidate;
end;

procedure TDragHandle.Paint;
var
  G: TdxGPGraphics;
  Col: TdxAlphaColor;
  Row, ColI, CX, CY: Integer;
  DotR: Single;
begin
  G := TdxGPGraphics.Create(Canvas.Handle);
  try
    G.SmoothingMode := smAntiAlias;
    G.FillRectangle(Rect(0, 0, Width, Height), dxColorToAlphaColor(FBackColor, 255));
    if FHot then Col := ARGB(255, $2D, $6C, $DF) else Col := ARGB(255, $B0, $B8, $C4);
    DotR := 1.3;
    // Rejilla 2x3 de puntos (icono clasico de "arrastrar"), compacta.
    for ColI := 0 to 1 do
      for Row := 0 to 2 do
      begin
        CX := 4 + ColI * 5;
        CY := 3 + Row * 5;
        G.Ellipse(dxRectF(CX - DotR, CY - DotR, CX + DotR, CY + DotR), Col, Col);
      end;
  finally
    G.Free;
  end;
end;

end.
