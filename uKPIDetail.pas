unit uKPIDetail;

// ============================================================================
// Modal "Detalle del KPI" (drill-down al hacer doble clic en una KPI card).
//
// Muestra:
//   - Titulo + categoria (chip) + valor actual grande.
//   - Grafico ampliado y anotado de la serie (min / max / media, ultimo punto).
//   - Descripcion corta + descripcion ampliada ("que es y para que sirve").
//   - (Opcional) un boton de accion (p.ej. "Ver alertas en el Gantt").
//
// Todo el render del grafico es GDI+ (mismo estilo que TKPICard/uDashWidgets).
// Convenciones de la casa: borde de dialogo + boton de ayuda (?) en el caption.
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Types, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics, Vcl.Buttons,
  cxGeometry, dxCoreGraphics, dxGDIPlusAPI, dxGDIPlusClasses,
  uKPICard;

type
  // Tipo de grafico del detalle (sobre una serie temporal solo tienen sentido
  // estos 3; pastel/donut quedan fuera a proposito).
  TKPIChartKind = (ckLinea, ckArea, ckBarras);

  // Datos de un rango (los devuelve el dashboard al cambiar de periodo).
  TKPIRangoData = record
    Series: TArray<Double>;
    Fechas: TArray<TDateTime>;
    Subtitulo: string;
  end;

  TKPIDetailInfo = record
    Titulo: string;
    Categoria: string;
    Descripcion: string;
    DescAmpliada: string;
    Unidad: string;
    FormatStr: string;
    Value: Double;
    Series: TArray<Double>;
    Fechas: TArray<TDateTime>;   // fecha de cada punto (para el eje X); opcional
    Subtitulo: string;          // p.ej. "Evolucion - ultimos 30 dias"
    Tone: TKPIColorTone;
    // Selector de periodo dentro del modal. RangoActual: -1=semana, 7/30/90=dias.
    // OnCargarRango: el dashboard devuelve serie+fechas+subtitulo para ese rango.
    RangoActual: Integer;
    OnCargarRango: TFunc<Integer, TKPIRangoData>;
    // Accion opcional (boton). Si AccionCaption = '' no se muestra boton.
    AccionCaption: string;
    Accion: TProc;
  end;

  TfrmKPIDetail = class(TForm)
  private
    FInfo: TKPIDetailInfo;
    FChart: TPaintBox;    // area donde pintamos el grafico (GDI+)
    FMemo: TMemo;         // descripcion ampliada (texto multilinea)
    FBtnAccion: TButton;
    FKind: TKPIChartKind; // tipo de grafico seleccionado
    FBtnLinea, FBtnArea, FBtnBarras: TSpeedButton;
    FBtnSem, FBtnR7, FBtnR30, FBtnR90: TSpeedButton;  // selector de periodo
    FLblSub: TLabel;      // subtitulo (rango), se actualiza al cambiar periodo
    procedure BuildUI;
    procedure ChartPaint(Sender: TObject);
    procedure AccionClick(Sender: TObject);
    procedure KindClick(Sender: TObject);
    procedure RangoClick(Sender: TObject);
    procedure DrawLineaArea(G: TdxGPGraphics; const Pts: array of TdxPointF;
      Ac: TdxAlphaColor; AConArea: Boolean; PlotBottom: Integer);
    procedure DrawBarras(G: TdxGPGraphics; const Pts: array of TdxPointF;
      Ac: TdxAlphaColor; PlotBottom, PlotW, N: Integer);
    function Accent: TdxAlphaColor;
  public
    class procedure Mostrar(AOwner: TComponent; const AInfo: TKPIDetailInfo);
  end;

implementation

{$R *.dfm}

function ARGB(A, R, G, B: Byte): TdxAlphaColor; inline;
begin
  Result := (Cardinal(A) shl 24) or (Cardinal(R) shl 16) or
            (Cardinal(G) shl 8) or Cardinal(B);
end;

function WithAlpha(AColor: TdxAlphaColor; AAlpha: Byte): TdxAlphaColor; inline;
begin
  Result := (AColor and $00FFFFFF) or (Cardinal(AAlpha) shl 24);
end;

procedure DrawText(G: TdxGPGraphics; const S, AFont: string; ASize: Single;
  ABold: Boolean; AColor: TdxAlphaColor; const R: TdxRectF;
  AAlign: TdxGpStringAlignment = StringAlignmentNear);
var
  F: TdxGPFont;
  B: TdxGPBrush;
  SF: TdxGPStringFormat;
  Sty: TdxGPFontStyle;
begin
  if ABold then Sty := FontStyleBold else Sty := FontStyleRegular;
  F := TdxGPFont.Create(AFont, ASize, Sty);
  B := TdxGPBrush.Create;
  SF := TdxGPStringFormat.Create;
  try
    B.Color := AColor;
    SF.Alignment := AAlign;
    SF.LineAlignment := StringAlignmentNear;
    G.DrawString(S, F, B, R, SF);
  finally
    SF.Free; B.Free; F.Free;
  end;
end;

class procedure TfrmKPIDetail.Mostrar(AOwner: TComponent;
  const AInfo: TKPIDetailInfo);
var
  F: TfrmKPIDetail;
begin
  F := TfrmKPIDetail.Create(AOwner);
  try
    F.FInfo := AInfo;
    F.BuildUI;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

function TfrmKPIDetail.Accent: TdxAlphaColor;
begin
  case FInfo.Tone of
    kctVerde:  Result := ARGB(255, $2E, $A8, $54);
    kctAmbar:  Result := ARGB(255, $E6, $95, $00);
    kctRojo:   Result := ARGB(255, $E0, $3B, $3B);
    kctAzul:   Result := ARGB(255, $2D, $6C, $DF);
  else
    Result := ARGB(255, $80, $88, $95);
  end;
end;

procedure TfrmKPIDetail.BuildUI;
var
  lblTit, lblCat, lblVal: TLabel;
  FmtStr, ValStr: string;
begin
  Caption := 'Detalle del KPI';
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu, biHelp];
  Position := poOwnerFormCenter;
  ClientWidth := 720;
  ClientHeight := 580;
  Color := clWhite;

  // --- Cabecera: categoria (chip) + titulo + valor grande ---
  lblCat := TLabel.Create(Self);
  lblCat.Parent := Self;
  lblCat.SetBounds(18, 14, 200, 16);
  lblCat.Caption := UpperCase(FInfo.Categoria);
  lblCat.Font.Name := 'Segoe UI';
  lblCat.Font.Height := -11;
  lblCat.Font.Style := [fsBold];
  lblCat.Font.Color := $00A6928A;   // gris azulado

  lblTit := TLabel.Create(Self);
  lblTit.Parent := Self;
  lblTit.SetBounds(18, 32, 460, 34);
  lblTit.Caption := FInfo.Titulo;
  lblTit.Font.Name := 'Segoe UI Semibold';
  lblTit.Font.Height := -22;
  lblTit.Font.Color := $00503E2C;

  FLblSub := TLabel.Create(Self);
  FLblSub.Parent := Self;
  FLblSub.SetBounds(18, 66, 300, 16);
  FLblSub.Caption := FInfo.Subtitulo;
  FLblSub.Font.Name := 'Segoe UI';
  FLblSub.Font.Height := -12;
  FLblSub.Font.Color := $008A928A;

  if FInfo.FormatStr <> '' then FmtStr := FInfo.FormatStr else FmtStr := '%.0f';
  ValStr := Format(FmtStr, [FInfo.Value]);
  if FInfo.Unidad <> '' then ValStr := ValStr + ' ' + FInfo.Unidad;
  lblVal := TLabel.Create(Self);
  lblVal.Parent := Self;
  lblVal.SetBounds(ClientWidth - 200, 24, 180, 44);
  lblVal.Alignment := taRightJustify;
  lblVal.AutoSize := False;
  lblVal.Caption := ValStr;
  lblVal.Font.Name := 'Segoe UI';
  lblVal.Font.Height := -30;
  lblVal.Font.Style := [fsBold];
  lblVal.Font.Color := $00503E2C;

  // --- Selector de tipo de grafico (segmented) arriba a la derecha ---
  // Por defecto se muestra AREA.
  FKind := ckArea;

  FBtnLinea := TSpeedButton.Create(Self);
  FBtnLinea.Parent := Self;
  FBtnLinea.GroupIndex := 1;
  FBtnLinea.AllowAllUp := False;
  FBtnLinea.Caption := 'L'#237'nea';
  FBtnLinea.SetBounds(ClientWidth - 236, 72, 72, 24);
  FBtnLinea.Flat := True;
  FBtnLinea.OnClick := KindClick;

  FBtnArea := TSpeedButton.Create(Self);
  FBtnArea.Parent := Self;
  FBtnArea.GroupIndex := 1;
  FBtnArea.Down := True;
  FBtnArea.Caption := #193'rea';
  FBtnArea.SetBounds(ClientWidth - 162, 72, 72, 24);
  FBtnArea.Flat := True;
  FBtnArea.OnClick := KindClick;

  FBtnBarras := TSpeedButton.Create(Self);
  FBtnBarras.Parent := Self;
  FBtnBarras.GroupIndex := 1;
  FBtnBarras.Caption := 'Barras';
  FBtnBarras.SetBounds(ClientWidth - 88, 72, 72, 24);
  FBtnBarras.Flat := True;
  FBtnBarras.OnClick := KindClick;

  // --- Selector de periodo (izquierda, bajo el subtitulo) ---
  // Solo si el dashboard aporta el callback de recarga (datos reales).
  if Assigned(FInfo.OnCargarRango) then
  begin
    FBtnSem := TSpeedButton.Create(Self);
    FBtnSem.Parent := Self;
    FBtnSem.GroupIndex := 2;
    FBtnSem.AllowAllUp := False;
    FBtnSem.Caption := 'Semana';
    FBtnSem.Tag := -1;
    FBtnSem.SetBounds(18, 86, 56, 22);
    FBtnSem.Flat := True;
    FBtnSem.OnClick := RangoClick;

    FBtnR7 := TSpeedButton.Create(Self);
    FBtnR7.Parent := Self;
    FBtnR7.GroupIndex := 2;
    FBtnR7.Caption := '7d';
    FBtnR7.Tag := 7;
    FBtnR7.SetBounds(76, 86, 36, 22);
    FBtnR7.Flat := True;
    FBtnR7.OnClick := RangoClick;

    FBtnR30 := TSpeedButton.Create(Self);
    FBtnR30.Parent := Self;
    FBtnR30.GroupIndex := 2;
    FBtnR30.Caption := '30d';
    FBtnR30.Tag := 30;
    FBtnR30.SetBounds(114, 86, 36, 22);
    FBtnR30.Flat := True;
    FBtnR30.OnClick := RangoClick;

    FBtnR90 := TSpeedButton.Create(Self);
    FBtnR90.Parent := Self;
    FBtnR90.GroupIndex := 2;
    FBtnR90.Caption := '90d';
    FBtnR90.Tag := 90;
    FBtnR90.SetBounds(152, 86, 36, 22);
    FBtnR90.Flat := True;
    FBtnR90.OnClick := RangoClick;

    // Estado inicial segun RangoActual.
    case FInfo.RangoActual of
      -1: FBtnSem.Down := True;
       7: FBtnR7.Down := True;
      30: FBtnR30.Down := True;
      90: FBtnR90.Down := True;
    else FBtnR7.Down := True;
    end;
  end;

  // --- Grafico ---
  FChart := TPaintBox.Create(Self);
  FChart.Parent := Self;
  FChart.SetBounds(16, 116, ClientWidth - 32, 244);
  FChart.OnPaint := ChartPaint;

  // --- Cabecera de seccion de la descripcion ---
  var lblSec := TLabel.Create(Self);
  lblSec.Parent := Self;
  lblSec.SetBounds(18, 366, ClientWidth - 36, 18);
  lblSec.Caption := #191'QU'#201' MIDE Y PARA QU'#201' SIRVE?';
  lblSec.Font.Name := 'Segoe UI';
  lblSec.Font.Height := -11;
  lblSec.Font.Style := [fsBold];
  lblSec.Font.Color := $00A6928A;

  // linea separadora fina bajo la cabecera de seccion
  var pnlSep := TPanel.Create(Self);
  pnlSep.Parent := Self;
  pnlSep.SetBounds(18, 386, ClientWidth - 36, 1);
  pnlSep.BevelOuter := bvNone;
  pnlSep.Color := $00E4E7EC;

  // --- Descripcion ampliada (debajo del grafico) ---
  // Usamos un TMemo de solo lectura (sin borde) para mostrar de forma fiable el
  // bloque de texto con salto de linea y ajuste automatico.
  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.SetBounds(18, 396, ClientWidth - 36, 130);
  FMemo.BorderStyle := bsNone;
  FMemo.ReadOnly := True;
  FMemo.TabStop := False;
  FMemo.WordWrap := True;
  FMemo.ScrollBars := ssVertical;
  FMemo.Color := clWhite;
  FMemo.Font.Name := 'Segoe UI';
  FMemo.Font.Height := -13;
  FMemo.Font.Color := clGray;
  if FInfo.DescAmpliada <> '' then
    FMemo.Text := FInfo.DescAmpliada
  else
    FMemo.Text := FInfo.Descripcion;

  // --- Boton de accion opcional (abajo) ---
  if FInfo.AccionCaption <> '' then
  begin
    FBtnAccion := TButton.Create(Self);
    FBtnAccion.Parent := Self;
    FBtnAccion.Caption := FInfo.AccionCaption;
    FBtnAccion.SetBounds(ClientWidth - 220, ClientHeight - 44, 200, 30);
    FBtnAccion.OnClick := AccionClick;
  end;
end;

procedure TfrmKPIDetail.AccionClick(Sender: TObject);
begin
  ModalResult := mrOk;
  if Assigned(FInfo.Accion) then
    FInfo.Accion();
end;

procedure TfrmKPIDetail.KindClick(Sender: TObject);
begin
  if Sender = FBtnLinea then FKind := ckLinea
  else if Sender = FBtnArea then FKind := ckArea
  else if Sender = FBtnBarras then FKind := ckBarras;
  FChart.Invalidate;
end;

procedure TfrmKPIDetail.RangoClick(Sender: TObject);
var
  Data: TKPIRangoData;
begin
  if not Assigned(FInfo.OnCargarRango) then Exit;
  FInfo.RangoActual := TSpeedButton(Sender).Tag;
  // El dashboard devuelve la serie/fechas/subtitulo del nuevo rango.
  Data := FInfo.OnCargarRango(FInfo.RangoActual);
  FInfo.Series := Data.Series;
  FInfo.Fechas := Data.Fechas;
  FInfo.Subtitulo := Data.Subtitulo;
  if FLblSub <> nil then FLblSub.Caption := FInfo.Subtitulo;
  FChart.Invalidate;
end;

// Linea (curva suave), opcionalmente con area degradada bajo ella.
procedure TfrmKPIDetail.DrawLineaArea(G: TdxGPGraphics;
  const Pts: array of TdxPointF; Ac: TdxAlphaColor; AConArea: Boolean;
  PlotBottom: Integer);
var
  N: Integer;
  Path: TdxGPPath;
  Brush: TdxGPBrush;
begin
  N := Length(Pts);
  if N < 2 then Exit;

  if AConArea then
  begin
    Path := TdxGPPath.Create;
    Brush := TdxGPBrush.Create;
    try
      Path.AddPolyline(Pts);
      Path.AddLine(Pts[N-1].X, Pts[N-1].Y, Pts[N-1].X, PlotBottom);
      Path.AddLine(Pts[N-1].X, PlotBottom, Pts[0].X, PlotBottom);
      Path.FigureFinish;
      Brush.Style := gpbsGradient;
      Brush.GradientMode := gpbgmVertical;
      Brush.GradientPoints.Add(0.0, WithAlpha(Ac, 90));
      Brush.GradientPoints.Add(1.0, WithAlpha(Ac, 0));
      Brush.SetTargetRect(Rect(Round(Pts[0].X), Round(Pts[0].Y) - 4,
        Round(Pts[N-1].X), PlotBottom + 2));
      G.Path(Path, nil, Brush);
    finally
      Brush.Free; Path.Free;
    end;
  end;

  G.Curve(Pts, dxAlphaColorToColor(Ac), 2.5, psSolid, 255);

  var I: Integer;
  for I := 0 to N - 1 do
    G.Ellipse(dxRectF(Pts[I].X - 2.5, Pts[I].Y - 2.5, Pts[I].X + 2.5, Pts[I].Y + 2.5),
      Ac, ARGB(255, 255, 255, 255));
  G.Ellipse(dxRectF(Pts[N-1].X - 6, Pts[N-1].Y - 6, Pts[N-1].X + 6, Pts[N-1].Y + 6),
    WithAlpha(Ac, 60), WithAlpha(Ac, 60));
  G.Ellipse(dxRectF(Pts[N-1].X - 4, Pts[N-1].Y - 4, Pts[N-1].X + 4, Pts[N-1].Y + 4),
    Ac, Ac);
end;

// Barras verticales redondeadas, la ultima destacada.
procedure TfrmKPIDetail.DrawBarras(G: TdxGPGraphics;
  const Pts: array of TdxPointF; Ac: TdxAlphaColor;
  PlotBottom, PlotW, N: Integer);
var
  I, BarW: Integer;
  X, Y: Single;
  Path: TdxGPPath;
  Col: TdxAlphaColor;
begin
  if N < 1 then Exit;
  BarW := Max(4, Round(PlotW / N * 0.6));
  for I := 0 to N - 1 do
  begin
    X := Pts[I].X - BarW / 2;
    Y := Pts[I].Y;
    if I = N - 1 then Col := Ac else Col := WithAlpha(Ac, 150);
    Path := TdxGPPath.Create;
    try
      // Rect redondeado solo por arriba (aproximado con AddRoundRect).
      Path.AddRoundRect(Rect(Round(X), Round(Y),
        Round(X) + BarW, PlotBottom), 3, 3);
      G.Path(Path, WithAlpha(Col, 0), Col, 0);
    finally
      Path.Free;
    end;
  end;
end;

procedure TfrmKPIDetail.ChartPaint(Sender: TObject);
var
  G: TdxGPGraphics;
  W, H: Integer;
  PadL, PadR, PadT, PadB, PlotW, PlotH: Integer;
  I, N: Integer;
  MinV, MaxV, Range, AvgV, S: Double;
  Pts: array of TdxPointF;
  Pen: TdxGPPen;
  Ac: TdxAlphaColor;
  GridY: Integer;
  FmtStr: string;
begin
  G := TdxGPGraphics.Create(TPaintBox(Sender).Canvas.Handle);
  try
    G.SmoothingMode := smAntiAlias;
    G.TextRenderingHint := TextRenderingHintClearTypeGridFit;
    W := FChart.Width;
    H := FChart.Height;
    Ac := Accent;

    G.FillRectangle(Rect(0, 0, W, H), ARGB(255, 255, 255, 255));

    N := Length(FInfo.Series);
    PadL := 44; PadR := 16; PadT := 12; PadB := 26;
    PlotW := W - PadL - PadR;
    PlotH := H - PadT - PadB;

    if N < 2 then
    begin
      DrawText(G, 'Sin historico suficiente para el grafico.',
        'Segoe UI', 10, False, ARGB(255, $8A, $92, $A6),
        dxRectF(PadL, H div 2 - 8, W - PadR, H div 2 + 12));
      Exit;
    end;

    // Min / max / media.
    MinV := FInfo.Series[0]; MaxV := FInfo.Series[0]; AvgV := 0;
    for I := 0 to N - 1 do
    begin
      S := FInfo.Series[I];
      if S < MinV then MinV := S;
      if S > MaxV then MaxV := S;
      AvgV := AvgV + S;
    end;
    AvgV := AvgV / N;
    // Margen visual: 8% arriba/abajo.
    Range := MaxV - MinV;
    if Range < 0.0001 then Range := 1;
    MinV := MinV - Range * 0.08;
    MaxV := MaxV + Range * 0.08;
    Range := MaxV - MinV;

    // --- Rejilla horizontal + etiquetas de eje Y (4 lineas) ---
    if FInfo.FormatStr <> '' then FmtStr := FInfo.FormatStr else FmtStr := '%.0f';
    for I := 0 to 4 do
    begin
      GridY := PadT + Round(PlotH * I / 4);
      G.Line(PadL, GridY, W - PadR, GridY, ARGB(255, $EE, $F0, $F3), 1);
      var YVal: Double := MaxV - Range * I / 4;
      DrawText(G, Format(FmtStr, [YVal]) + FInfo.Unidad, 'Segoe UI', 7.5, False,
        ARGB(255, $9A, $A2, $B0), dxRectF(2, GridY - 7, PadL - 4, GridY + 8),
        StringAlignmentFar);
    end;

    // --- Linea de la media (discontinua) ---
    var AvgY: Integer := PadT + Round((MaxV - AvgV) / Range * PlotH);
    Pen := TdxGPPen.Create(WithAlpha(Ac, 120), 1);
    try
      Pen.Style := gppsDash;
      G.Line(PadL, AvgY, W - PadR, AvgY, Pen);
    finally
      Pen.Free;
    end;
    DrawText(G, 'media ' + Format(FmtStr, [AvgV]) + FInfo.Unidad, 'Segoe UI',
      7.5, True, WithAlpha(Ac, 200),
      dxRectF(W - PadR - 120, AvgY - 14, W - PadR, AvgY - 2), StringAlignmentFar);

    // Puntos (para linea/area) o centros de barra.
    SetLength(Pts, N);
    for I := 0 to N - 1 do
    begin
      if N > 1 then Pts[I].X := PadL + I * (PlotW / (N - 1))
      else Pts[I].X := PadL + PlotW / 2;
      Pts[I].Y := PadT + (MaxV - FInfo.Series[I]) / Range * PlotH;
    end;

    // --- Dibujar segun el tipo elegido ---
    case FKind of
      ckArea:   DrawLineaArea(G, Pts, Ac, True,  PadT + PlotH);
      ckBarras: DrawBarras(G, Pts, Ac, PadT + PlotH, PlotW, N);
    else
      DrawLineaArea(G, Pts, Ac, False, PadT + PlotH);   // ckLinea
    end;

    // --- Eje X: etiquetas de fecha (si hay), repartidas para no solaparse ---
    if Length(FInfo.Fechas) = N then
    begin
      var Paso: Integer := Max(1, N div 6);   // ~6 etiquetas maximo
      for I := 0 to N - 1 do
        if (I mod Paso = 0) or (I = N - 1) then
          DrawText(G, FormatDateTime('dd/mm', FInfo.Fechas[I]), 'Segoe UI',
            7.5, False, ARGB(255, $9A, $A2, $B0),
            dxRectF(Pts[I].X - 24, PadT + PlotH + 5, Pts[I].X + 24, PadT + PlotH + 20),
            StringAlignmentCenter);
    end;
  finally
    G.Free;
  end;
end;

end.
