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
  // Una fila del mini-Gantt: un centro de trabajo y su ocupacion (%) semana a
  // semana. -1 en una semana = sin actividad (celda vacia).
  TTimelineCentroRow = record
    Nombre: string;
    OcupPct: TArray<Double>;   // por semana; -1 = sin carga
  end;

  TTimelineWidget = class(TDashWidgetBase)
  private
    FInicio, FBloqueo, FFin: TDateTime;
    FTieneBloqueo: Boolean;
    // Mini-Gantt: filas por centro + banda de calor (saturacion global) por
    // semana. Mismas semanas para ambos (FNumSemanas columnas).
    FCentros: TArray<TTimelineCentroRow>;
    FSaturSemana: TArray<Double>;   // % ocupacion global por semana (-1 vacio)
    FNumSemanas: Integer;
    procedure PaintContent(G: TdxGPGraphics; const R: TRect); override;
    function ColorPorOcup(APct: Double; out AVacio: Boolean): TdxAlphaColor;
  public
    procedure SetData(const AInicio, AFin: TDateTime;
      ATieneBloqueo: Boolean; const ABloqueo: TDateTime);
    // Alimenta el mini-Gantt + banda de calor. ACentros ya viene ordenado
    // (mas ocupado primero); ASatur es la saturacion global por semana.
    procedure SetGantt(const ACentros: TArray<TTimelineCentroRow>;
      const ASatur: TArray<Double>);
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

procedure TTimelineWidget.SetGantt(const ACentros: TArray<TTimelineCentroRow>;
  const ASatur: TArray<Double>);
var
  I, MaxN: Integer;
begin
  FCentros := ACentros;
  FSaturSemana := ASatur;
  // Nº de semanas = maximo de columnas entre todas las series (deberian
  // coincidir, pero nos protegemos).
  MaxN := Length(ASatur);
  for I := 0 to High(ACentros) do
    if Length(ACentros[I].OcupPct) > MaxN then MaxN := Length(ACentros[I].OcupPct);
  FNumSemanas := MaxN;
  Invalidate;
end;

// Semaforo de ocupacion para las celdas del mini-Gantt y la banda de calor.
function TTimelineWidget.ColorPorOcup(APct: Double;
  out AVacio: Boolean): TdxAlphaColor;
begin
  AVacio := APct < 0;
  if AVacio then Exit(ARGB(0, 0, 0, 0));
  if APct <= 0 then       Result := ARGB(255, $EC, $EF, $F3)   // gris (0)
  else if APct < 60 then  Result := ARGB(255, $58, $C8, $8A)   // verde
  else if APct < 85 then  Result := ARGB(255, $7A, $D0, $6A)   // verde-claro
  else if APct < 100 then Result := ARGB(255, $F0, $B4, $3C)   // ambar
  else if APct < 120 then Result := ARGB(255, $EE, $8A, $34)   // naranja
  else                    Result := ARGB(255, $E0, $3B, $3B);  // rojo (sobrecarga)
end;

procedure TTimelineWidget.PaintContent(G: TdxGPGraphics; const R: TRect);
const
  LBL_W = 78;   // ancho columna de nombres (izquierda)
var
  CLR_GRIS, CLR_EJE, CLR_HOY: TdxAlphaColor;
  Hoy: TDateTime;
  RangoDias: Double;
  GridL, GridR, GridW: Integer;
  I, J, RowsTop, RowsBot, RowH, NumRows, MaxRows: Integer;
  RowY, CeldaL, CeldaR: Integer;
  Vacio: Boolean;
  Col: TdxAlphaColor;
  HeatTop, HeatBot, HoyX: Integer;
  Lbl: string;

  function FracToX(AFrac: Double): Integer;
  begin
    if AFrac < 0 then AFrac := 0;
    if AFrac > 1 then AFrac := 1;
    Result := GridL + Round(AFrac * GridW);
  end;

  // X de la columna semana ASem (borde izquierdo de la celda).
  function SemX(ASem: Integer): Integer;
  begin
    if FNumSemanas <= 0 then Exit(GridL);
    Result := GridL + Round(ASem / FNumSemanas * GridW);
  end;

  // Eje de meses de fondo: separadores verticales tenues sobre toda la rejilla.
  procedure PintarEjeMeses(ATop, ABottom: Integer);
  var
    Cursor: TDateTime;
    MX: Integer;
    YYYY, MM, DD: Word;
  begin
    if RangoDias <= 0 then Exit;
    DecodeDate(FInicio, YYYY, MM, DD);
    Cursor := EncodeDate(YYYY, MM, 1);
    Cursor := IncMonth(Cursor, 1);
    while Cursor < FFin do
    begin
      MX := FracToX((Cursor - FInicio) / RangoDias);
      G.Line(MX, ATop, MX, ABottom, WithAlpha(CLR_EJE, 70), 1);
      DrawGpText(G, FormatDateTime('mmm', Cursor), 'Segoe UI', 6.5, False,
        WithAlpha(CLR_GRIS, 180), dxRectF(MX - 20, ATop - 12, MX + 20, ATop));
      Cursor := IncMonth(Cursor, 1);
    end;
  end;

  // Pinta una celda redondeada de color (con margen interior).
  procedure Celda(AL, ATop, AR, ABot: Integer; AColor: TdxAlphaColor);
  var
    P: TdxGPPath;
  begin
    if AR <= AL + 1 then Exit;
    P := TdxGPPath.Create;
    try
      P.AddRoundRect(Rect(AL + 1, ATop + 1, AR - 1, ABot - 1), 3, 3);
      // Mismo patron probado que el Chip de TErpSyncWidget: fill + borde solidos.
      G.Path(P, AColor, AColor, 1);
    finally
      P.Free;
    end;
  end;

  // Segmento de barra sin margen horizontal (semanas contiguas se funden en una
  // sola barra Gantt). Relleno solido via FillRectangle (patron ya usado en la
  // base de widgets).
  procedure BarraSemana(AL, ATop, AR, ABot: Integer; AColor: TdxAlphaColor);
  begin
    if AR <= AL then Exit;
    G.FillRectangle(Rect(AL, ATop, AR, ABot), AColor);
  end;

  // Estado vacio "phantom": dibuja el esqueleto del mini-Gantt (filas con una
  // barra-etiqueta gris a la izquierda y segmentos tenues como celdas) + la
  // banda de calor en gris muy claro, para insinuar que hay que hay que aqui.
  // AColLabel/AColCell en gris clarito. No usa datos reales.
  procedure PintarPhantom(ATop, ARowsBot, AHeatTop, AHeatBot: Integer;
    const AMsg: string);
  const
    PH_SEMS = 12;   // columnas fantasma
  var
    NFil, RH, Y, I, J, X1, X2, Segs, S: Integer;
    ColLbl, ColCell: TdxAlphaColor;
    Ancho: Double;
  begin
    ColLbl  := ARGB(255, $E4, $E7, $EC);   // barra-etiqueta gris clara
    ColCell := ARGB(255, $EE, $F1, $F5);   // celda fantasma casi blanca

    // Filas fantasma.
    if ARowsBot > ATop + 8 then
    begin
      NFil := (ARowsBot - ATop) div 18;
      if NFil < 3 then NFil := 3;
      if NFil > 5 then NFil := 5;
      RH := (ARowsBot - ATop) div NFil;
      if RH > 22 then RH := 22;
      for I := 0 to NFil - 1 do
      begin
        Y := ATop + I * RH;
        // Barra-etiqueta izquierda (ancho decreciente, determinista).
        Celda(R.Left, Y + 2, R.Left + LBL_W - 10 - (I mod 3) * 12, Y + RH - 2,
          ColLbl);
        // Segmentos de celdas fantasma repartidos por la rejilla.
        Segs := 2 + (I mod 3);   // 2..4 bloques por fila
        for S := 0 to Segs - 1 do
        begin
          // Posicion y ancho pseudo-aleatorios pero estables por (I,S).
          J := (I * 5 + S * 3 + 1) mod PH_SEMS;
          Ancho := 1 + ((I + S) mod 3);   // 1..3 semanas de ancho
          X1 := GridL + Round(J / PH_SEMS * GridW);
          X2 := GridL + Round((J + Ancho) / PH_SEMS * GridW);
          if X2 > GridR then X2 := GridR;
          Celda(X1, Y + 2, X2, Y + RH - 2, ColCell);
        end;
      end;
    end;

    // Banda de calor fantasma (todas las celdas gris claro uniforme).
    if AHeatBot > AHeatTop then
    begin
      Celda(R.Left, AHeatTop, R.Left + LBL_W - 10, AHeatBot, ColLbl);
      for J := 0 to PH_SEMS - 1 do
      begin
        X1 := GridL + Round(J / PH_SEMS * GridW);
        X2 := GridL + Round((J + 1) / PH_SEMS * GridW);
        Celda(X1, AHeatTop, X2, AHeatBot, ColCell);
      end;
    end;

    // Mensaje discreto centrado sobre la rejilla.
    if AMsg <> '' then
      DrawGpText(G, AMsg, 'Segoe UI', 8.5, False, ARGB(255, $A8, $AE, $BA),
        dxRectF(GridL, ATop, GridR, ARowsBot), StringAlignmentCenter);
  end;

begin
  CLR_GRIS := ARGB(255, $8A, $92, $A6);
  CLR_EJE  := ARGB(255, $C8, $CE, $D8);
  CLR_HOY  := ARGB(255, $2D, $6C, $DF);

  GridL := R.Left + LBL_W;
  GridR := R.Right - 8;
  GridW := GridR - GridL;
  if GridW <= 0 then Exit;

  // Zonas verticales (validas tambien para el estado phantom).
  RowsTop := R.Top + 26;
  HeatBot := R.Bottom - 4;
  HeatTop := HeatBot - 16;
  RowsBot := HeatTop - 16;

  // ---- Estado phantom: sin fechas de plan -> esqueleto en gris claro ----
  if (FInicio <= 0) or (FFin <= FInicio) then
  begin
    PintarPhantom(RowsTop, RowsBot, HeatTop, HeatBot,
      'A'#250'n no hay plan que mostrar');
    Exit;
  end;

  RangoDias := FFin - FInicio;
  Hoy := Trunc(Date);

  // ================= Cabecera: rango de fechas junto al titulo =================
  // El titulo lo dibuja DrawTitle a la izquierda, en la franja superior (sobre
  // R.Top, que ya viene descontado). Ponemos el rango a la DERECHA de esa misma
  // franja, en negro.
  DrawGpText(G, FormatDateTime('dd/mm/yy', FInicio) + '  -  ' +
    FormatDateTime('dd/mm/yy', FFin), 'Segoe UI Semibold', 8, False,
    ARGB(255, $20, $24, $2C),
    dxRectF(R.Left, R.Top - 18, R.Right - 4, R.Top - 4), StringAlignmentFar);

  // ================= Mini-Gantt por centro =================
  PintarEjeMeses(RowsTop, HeatBot);

  NumRows := Length(FCentros);
  if (NumRows > 0) and (RowsBot > RowsTop + 8) then
  begin
    // Limite de filas visibles segun el alto disponible (min 14px/fila).
    MaxRows := (RowsBot - RowsTop) div 14;
    if MaxRows < 1 then MaxRows := 1;
    if NumRows > MaxRows then NumRows := MaxRows;
    RowH := (RowsBot - RowsTop) div NumRows;
    if RowH > 22 then RowH := 22;

    for I := 0 to NumRows - 1 do
    begin
      RowY := RowsTop + I * RowH;

      // Fondo de fila alternado muy sutil (ayuda a seguir la fila).
      if Odd(I) then
        Celda(GridL, RowY, GridR, RowY + RowH, ARGB(255, $F7, $F8, $FA));

      // Nombre del centro (izquierda), elipsis si no cabe.
      Lbl := FCentros[I].Nombre;
      DrawGpText(G, Lbl, 'Segoe UI', 8, False, ARGB(255, $40, $48, $58),
        dxRectF(R.Left + 2, RowY, R.Left + LBL_W - 6, RowY + RowH),
        StringAlignmentNear);

      // Barras: tramos consecutivos con actividad = una barra continua,
      // coloreada por la ocupacion de cada semana. Sin margen horizontal para
      // que las semanas contiguas se fundan (aspecto Gantt, no rejilla).
      for J := 0 to High(FCentros[I].OcupPct) do
      begin
        Col := ColorPorOcup(FCentros[I].OcupPct[J], Vacio);
        if Vacio then Continue;
        CeldaL := SemX(J);
        CeldaR := SemX(J + 1);
        BarraSemana(CeldaL, RowY + 2, CeldaR, RowY + RowH - 2, Col);
      end;
    end;
  end
  else
  begin
    // Con fechas pero sin centros planificados: esqueleto phantom + mensaje,
    // y salimos (no hay banda de calor que pintar).
    PintarPhantom(RowsTop, RowsBot, HeatTop, HeatBot,
      'Plan sin operaciones asignadas a centros');
    // La linea HOY si tiene sentido (hay fechas): la pintamos igualmente.
    if (Hoy > FInicio) and (Hoy < FFin) then
    begin
      HoyX := FracToX((Hoy - FInicio) / RangoDias);
      G.Line(HoyX, RowsTop - 2, HoyX, HeatBot, WithAlpha(CLR_HOY, 120), 1);
      DrawGpText(G, 'HOY', 'Segoe UI', 6.5, True, WithAlpha(CLR_HOY, 160),
        dxRectF(HoyX - 20, R.Top + 13, HoyX + 20, R.Top + 25));
    end;
    Exit;
  end;

  // ================= Banda de calor (saturacion global/semana) =================
  DrawGpText(G, 'Saturaci'#243'n', 'Segoe UI', 7, False, CLR_GRIS,
    dxRectF(R.Left, HeatTop, R.Left + LBL_W - 6, HeatBot), StringAlignmentNear);
  for J := 0 to High(FSaturSemana) do
  begin
    Col := ColorPorOcup(FSaturSemana[J], Vacio);
    CeldaL := SemX(J);
    CeldaR := SemX(J + 1);
    if Vacio then
      BarraSemana(CeldaL, HeatTop, CeldaR, HeatBot, ARGB(255, $EC, $EF, $F3))
    else
      BarraSemana(CeldaL, HeatTop, CeldaR, HeatBot, Col);
  end;

  // ================= Linea vertical HOY (atraviesa todo) =================
  if (Hoy > FInicio) and (Hoy < FFin) then
  begin
    HoyX := FracToX((Hoy - FInicio) / RangoDias);
    G.Line(HoyX, RowsTop - 2, HoyX, HeatBot, CLR_HOY, 1);
    DrawGpText(G, 'HOY', 'Segoe UI', 6.5, True, CLR_HOY,
      dxRectF(HoyX - 20, R.Top + 13, HoyX + 20, R.Top + 25));
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
const
  PHANTOM_LBLS: array[0..4] of string =
    ('Total', 'Nuevos', 'Actualizados', 'Sin cambios', 'Obsoletos');
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
  Gap := 10;
  ChipH := 56;
  // 5 chips repartidos por el ancho disponible.
  ChipW := (R.Width - Gap * 4) div 5;
  if ChipW < 70 then ChipW := 70;

  if not FHayDatos then
  begin
    // Estado phantom: 5 chips con el MISMO gris de fondo que el cronograma vacio
    // ($EEF1F5, las celdas fantasma del mini-Gantt), para coherencia visual del
    // "vacio" en todo el Dashboard. Etiqueta y '--' en gris un punto mas oscuro.
    X := R.Left;
    Y := R.Top + 2;
    for var Ci := 0 to 4 do
    begin
      var Pp := TdxGPPath.Create;
      try
        Pp.AddRoundRect(Rect(X, Y, X + ChipW, Y + ChipH), 8, 8);
        G.Path(Pp, ARGB(255, $EE, $F1, $F5), ARGB(255, $E4, $E7, $EC), 1);
      finally
        Pp.Free;
      end;
      DrawGpText(G, '--', 'Segoe UI', 17, True, ARGB(255, $C2, $C8, $D2),
        dxRectF(X, Y + 8, X + ChipW, Y + 34));
      DrawGpText(G, PHANTOM_LBLS[Ci], 'Segoe UI', 8, False,
        ARGB(255, $A8, $AE, $BA), dxRectF(X, Y + 36, X + ChipW, Y + 52));
      Inc(X, ChipW + Gap);
    end;
    DrawGpText(G, FEstado, 'Segoe UI', 8, False, ARGB(255, $9A, $A2, $B0),
      dxRectF(R.Left, Y + ChipH + 4, R.Right, Y + ChipH + 20), StringAlignmentNear);
    Exit;
  end;

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
