unit uBacklogSchedPreview;

{
  Preview modal de los resultados de auto-planificacion antes de crear nodos.
  Devuelve:
    mrOk     -> confirmar (crear nodos)
    mrRetry  -> volver al dialogo de parametros
    mrCancel -> cancelar
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Winapi.GDIPOBJ, Winapi.GDIPAPI,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  uBacklogScheduler, uUtillajeTypes,
  dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019DarkGray, dxSkinOffice2019White,
  dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus,
  dxSkinSilver, dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008,
  dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue;

type
  TfrmBacklogSchedPreview = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pbKpis: TPaintBox;
    pnlBottom: TPanel;
    btnConfirmar: TButton;
    btnVolver: TButton;
    btnCancel: TButton;
    grdPreview: TcxGrid;
    tvPreview: TcxGridTableView;
    lvPreview: TcxGridLevel;
    colOF: TcxGridColumn;
    colOT: TcxGridColumn;
    colDoc: TcxGridColumn;
    colOrigen: TcxGridColumn;
    colCentro: TcxGridColumn;
    colUtillaje: TcxGridColumn;
    colIni: TcxGridColumn;
    colFin: TcxGridColumn;
    colDurMin: TcxGridColumn;
    colCompromiso: TcxGridColumn;
    colEstado: TcxGridColumn;
    colObs: TcxGridColumn;
    colStatusVal: TcxGridColumn;
    procedure btnVolverClick(Sender: TObject);
    procedure pbKpisPaint(Sender: TObject);
    procedure tvPreviewCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  private
    FKpis: TSchedKpis;
    procedure PopulateGrid(const AResult: TSchedResult);
    procedure UpdateKPIs(const AResult: TSchedResult);
    procedure ConfigurarModoConsulta;
  public
    // ASoloConsulta=True: vista informativa (un solo boton "Cerrar"); el motor
    // ya se ejecuto fuera y aqui solo se muestran tiempos. Devuelve mrCancel.
    class function Execute(const AResult: TSchedResult;
      ASoloConsulta: Boolean = False): TModalResult;
  end;

const
  mrReturnToParams = mrRetry;

implementation

{$R *.dfm}

uses
  System.DateUtils, System.Variants;

class function TfrmBacklogSchedPreview.Execute(
  const AResult: TSchedResult; ASoloConsulta: Boolean): TModalResult;
var
  F: TfrmBacklogSchedPreview;
begin
  F := TfrmBacklogSchedPreview.Create(Application);
  try
    F.UpdateKPIs(AResult);
    F.PopulateGrid(AResult);
    if ASoloConsulta then F.ConfigurarModoConsulta;
    Result := F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmBacklogSchedPreview.ConfigurarModoConsulta;
begin
  // Vista informativa: el motor ya corrio fuera; aqui solo se consultan tiempos.
  // Sin botones de accion: se cierra con la X de la ventana. La ayuda va en el
  // caption. Filtra/agrupa con el GroupBy box y los filtros de columna.
  Caption := 'Tiempos calculados  —  cierra con la X  ·  '
    + 'arrastra columnas al '#225'rea de agrupaci'#243'n o filtra por columna';
  lblTitle.Caption := 'Tiempos calculados';
  btnConfirmar.Visible := False;
  btnVolver.Visible := False;
  btnCancel.Visible := False;
  // Sin botones visibles, el panel inferior puede recogerse para dar mas grid.
  pnlBottom.Visible := False;
end;

procedure TfrmBacklogSchedPreview.btnVolverClick(Sender: TObject);
begin
  ModalResult := mrReturnToParams;
end;

procedure TfrmBacklogSchedPreview.tvPreviewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  V: Variant;
  St: Integer;
  Fondo: TColor;
  R: TRect;
  Txt: string;
begin
  // Pintamos a mano el fondo de la celda segun el estado (columna oculta
  // colStatusVal) y luego el texto encima. ADone=True para que cxGrid no
  // repinte por encima.
  ADone := False;
  V := AViewInfo.GridRecord.Values[colStatusVal.Index];
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  St := V;

  case TSchedStatus(St) of
    ssOK:          Fondo := $00DFF5DF;  // verde claro (BGR)
    ssSaturado:    Fondo := $0080C0FF;  // naranja
    ssFueraPlazo:  Fondo := $00C5C5FF;  // rojo claro
    // No se planifica: no hay utillaje libre. Se tinta como rechazo real
    // (mas fuerte que FueraPlazo, que si se crea) para que se vea que esa
    // fila NO va a generar nodo.
    ssSinUtillaje: Fondo := $009999FF;  // rojo
  else
    Exit;  // resto: sin tinte (fondo por defecto)
  end;

  R := AViewInfo.Bounds;
  // Pintamos sobre el TCanvas VCL subyacente (mas estable que mezclar APIs).
  ACanvas.Canvas.Brush.Style := bsSolid;
  ACanvas.Canvas.Brush.Color := Fondo;
  ACanvas.Canvas.FillRect(R);
  ACanvas.Canvas.Pen.Color := $00E0E0E0;  // rejilla suave
  ACanvas.Canvas.MoveTo(R.Left, R.Bottom - 1);
  ACanvas.Canvas.LineTo(R.Right, R.Bottom - 1);

  Txt := AViewInfo.GridRecord.DisplayTexts[AViewInfo.Item.Index];
  if Txt <> '' then
  begin
    ACanvas.Canvas.Brush.Style := bsClear;
    ACanvas.Canvas.Font.Color := clBlack;
    R.Left := R.Left + 4;
    R.Right := R.Right - 4;
    DrawText(ACanvas.Canvas.Handle, PChar(Txt), Length(Txt), R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
  end;
  ADone := True;
end;

procedure TfrmBacklogSchedPreview.UpdateKPIs(const AResult: TSchedResult);
begin
  // Guardamos los KPIs y los pintamos como "chips" en la cabecera (pbKpis).
  FKpis := ComputeKpis(AResult);
  pbKpis.Invalidate;
end;

procedure TfrmBacklogSchedPreview.PopulateGrid(const AResult: TSchedResult);
var
  I: Integer;
  Item: TSchedOutput;
begin
  tvPreview.BeginUpdate;
  try
    tvPreview.DataController.RecordCount := Length(AResult.Items);
    for I := 0 to High(AResult.Items) do
    begin
      Item := AResult.Items[I];

      // OF: numero + serie (si la hay). OT: NumeroTrabajo.
      if Item.Input.NumeroOF > 0 then
        tvPreview.DataController.Values[I, colOF.Index] :=
          Trim(Item.Input.SerieOF + ' ' + IntToStr(Item.Input.NumeroOF))
      else
        tvPreview.DataController.Values[I, colOF.Index] := '';
      tvPreview.DataController.Values[I, colOT.Index] := Item.Input.NumeroTrabajo;

      tvPreview.DataController.Values[I, colDoc.Index] := Item.Input.CodigoDocumento;
      tvPreview.DataController.Values[I, colOrigen.Index] := Item.Input.Origen;
      tvPreview.DataController.Values[I, colCentro.Index] := Item.CenterCode;
      tvPreview.DataController.Values[I, colStatusVal.Index] := Ord(Item.Status);

      // Utillajes que exige la operacion. Se muestra tambien en las filas que
      // SI se colocan: es la forma de ver de un vistazo que operaciones mueven
      // utillaje y, sobre todo, de entender por que una va tarde (a menudo es
      // porque esperaba al utillaje, no por capacidad de la maquina).
      tvPreview.DataController.Values[I, colUtillaje.Index] :=
        UtillajeReqsToStr(Item.Input.UtillajeReqs);

      if Item.FechaInicio <> 0 then
        tvPreview.DataController.Values[I, colIni.Index] :=
          FormatDateTime('dd/mm/yyyy hh:nn', Item.FechaInicio)
      else
        tvPreview.DataController.Values[I, colIni.Index] := '';

      if Item.FechaFin <> 0 then
        tvPreview.DataController.Values[I, colFin.Index] :=
          FormatDateTime('dd/mm/yyyy hh:nn', Item.FechaFin)
      else
        tvPreview.DataController.Values[I, colFin.Index] := '';

      tvPreview.DataController.Values[I, colDurMin.Index] := Item.DuracionMin;

      if Item.Input.FechaCompromiso <> 0 then
        tvPreview.DataController.Values[I, colCompromiso.Index] :=
          FormatDateTime('dd/mm/yyyy', Item.Input.FechaCompromiso)
      else
        tvPreview.DataController.Values[I, colCompromiso.Index] := '';

      tvPreview.DataController.Values[I, colEstado.Index] :=
        StatusToStr(Item.Status);
      tvPreview.DataController.Values[I, colObs.Index] := Item.Observaciones;
    end;
  finally
    tvPreview.EndUpdate;
  end;
end;

// ---------------------------------------------------------------------------
// Cabecera de KPIs dibujada como "chips": cada indicador en su recuadro con
// numero grande + etiqueta. Sobre el panel oscuro de la cabecera.
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedPreview.pbKpisPaint(Sender: TObject);
const
  ChipW = 96; ChipH = 40; Gap = 8;
var
  G: TGPGraphics;
  X: Single;

  function GPc(C: TColor; A: Byte = 255): TGPColor;
  begin
    C := ColorToRGB(C);
    Result := MakeColor(A, GetRValue(C), GetGValue(C), GetBValue(C));
  end;

  procedure Chip(const AValor, AEtiq: string; ACol: TColor);
  var
    Path: TGPGraphicsPath;
    B: TGPSolidBrush;
    F1, F2: TGPFont;
    Fmt: TGPStringFormat;
    D: Single;
  begin
    // recuadro semitransparente
    Path := TGPGraphicsPath.Create;
    D := 12;
    Path.AddArc(X, 0, D, D, 180, 90);
    Path.AddArc(X + ChipW - D, 0, D, D, 270, 90);
    Path.AddArc(X + ChipW - D, ChipH - D, D, D, 0, 90);
    Path.AddArc(X, ChipH - D, D, D, 90, 90);
    Path.CloseFigure;
    B := TGPSolidBrush.Create(GPc(clWhite, 22));
    G.FillPath(B, Path);
    B.Free; Path.Free;

    Fmt := TGPStringFormat.Create;
    Fmt.SetAlignment(StringAlignmentCenter);
    // valor (grande)
    F1 := TGPFont.Create('Segoe UI', 15, 1, UnitPoint);
    B := TGPSolidBrush.Create(GPc(ACol));
    G.DrawString(AValor, -1, F1, MakeRect(X, Single(2.0), Single(ChipW), Single(24.0)), Fmt, B);
    B.Free; F1.Free;
    // etiqueta (pequena)
    F2 := TGPFont.Create('Segoe UI', 7.5, 0, UnitPoint);
    B := TGPSolidBrush.Create(GPc($00D8D8D8));
    G.DrawString(AEtiq, -1, F2, MakeRect(X, Single(24.0), Single(ChipW), Single(16.0)), Fmt, B);
    B.Free; F2.Free; Fmt.Free;

    X := X + ChipW + Gap;
  end;

  // Texto en una sola linea (sin wrap), ancho amplio.
  procedure Linea(const S: string; AX, AY, ASize: Single; ABold: Boolean; ACol: TColor);
  var
    F: TGPFont; B: TGPSolidBrush; Fmt: TGPStringFormat; St: Integer;
  begin
    if ABold then St := 1 else St := 0;
    F := TGPFont.Create('Segoe UI', ASize, St, UnitPoint);
    B := TGPSolidBrush.Create(GPc(ACol));
    Fmt := TGPStringFormat.Create;
    Fmt.SetFormatFlags(StringFormatFlagsNoWrap);
    G.DrawString(S, -1, F, MakeRect(AX, AY, Single(520.0), Single(20.0)), Fmt, B);
    Fmt.Free; B.Free; F.Free;
  end;

  // Panel-chip ancho para la ventana temporal (dos lineas internas).
  procedure ChipVentana;
  var
    Path: TGPGraphicsPath; B: TGPSolidBrush; D, WW: Single;
  begin
    WW := 360;
    Path := TGPGraphicsPath.Create;
    D := 12;
    Path.AddArc(X, 0, D, D, 180, 90);
    Path.AddArc(X + WW - D, 0, D, D, 270, 90);
    Path.AddArc(X + WW - D, ChipH - D, D, D, 0, 90);
    Path.AddArc(X, ChipH - D, D, D, 90, 90);
    Path.CloseFigure;
    B := TGPSolidBrush.Create(GPc(clWhite, 22));
    G.FillPath(B, Path); B.Free; Path.Free;

    Linea(Format('Inicio  %s      Fin  %s',
      [FormatDateTime('dd/mm/yyyy hh:nn', FKpis.FechaMin),
       FormatDateTime('dd/mm/yyyy hh:nn', FKpis.FechaMax)]),
      X + 12, 4, 9, False, $00E8E8E8);
    Linea(Format('Ventana total  %.1f h', [FKpis.MakespanH]),
      X + 12, 22, 8.5, True, $00B0D8FF);
  end;

begin
  G := TGPGraphics.Create(pbKpis.Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);

    X := 0;
    Chip(IntToStr(FKpis.Total),          'TOTAL',          clWhite);
    Chip(IntToStr(FKpis.Planificados),   'OK',             $0070C070);
    Chip(IntToStr(FKpis.Saturados),      'SATURADOS',      $005A8CF0);
    Chip(IntToStr(FKpis.FueraPlazo),     'FUERA PLAZO',    $0040A0F0);
    Chip(IntToStr(FKpis.NoPlanificados), 'NO PLANIF.',     $008080A0);

    // Ventana temporal a la derecha de los chips (chip propio, dos lineas).
    if (FKpis.FechaMin <> 0) and (FKpis.FechaMax <> 0) then
    begin
      X := X + 8;
      ChipVentana;
    end;
  finally
    G.Free;
  end;
end;

end.
