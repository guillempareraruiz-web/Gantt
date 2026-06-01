unit uHistogramasOperarios;

{
  Form con 3 histogramas para vision de equipo:

    Tab 1 - Carga por operario (barras apiladas)
            Eje X: operarios (ordenados por carga total desc).
            Eje Y: horas en el periodo.
            Barras: segmento verde-gradient hasta 100% capacidad,
                    segmento rojo apilado para el exceso (>100%).
            Linea horizontal en la capacidad real del operario.

    Tab 2 - Distribucion de ocupacion
            Eje X: rangos de % ocupacion (0-25, 25-50, 50-75, 75-100, >100).
            Eje Y: numero de operarios en cada rango.
            Una barra por rango con color del rango.

    Tab 3 - Coste laboral por operario
            Eje X: operarios (ordenados por coste desc).
            Eje Y: coste en EUR (horas planificadas x SueldoEurHora).
            Calculo basico v1 (sin recargos turno/festivo).

  Filtros compartidos: rango de fechas + filtro de operarios. Datos
  recalculados una sola vez al cambiar filtros y reutilizados en los 3 tabs.

  Patron: TPaintBox custom (mismo estilo que los heatmaps).
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections, System.Generics.Defaults,
  System.DateUtils, System.Math, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  Data.Win.ADODB, Data.DB,
  cxCheckComboBox, cxCheckBox, cxEdit, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  uCentreCalendar,
  dxSkinsCore, dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue;

type
  TOpStat = record
    Id: Integer;
    Nombre: string;
    CalendarId: Integer;
    SueldoEurHora: Double;
    HorasAsignadas: Double;    // total en el periodo
    CapacidadHoras: Double;    // del calendario en el periodo
    PctOcupacion: Double;      // HorasAsignadas / CapacidadHoras * 100
    Coste: Double;             // HorasAsignadas * SueldoEurHora
  end;

  TfrmHistogramasOperarios = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlToolbar: TPanel;
    lblDesde: TLabel;
    dtDesde: TDateTimePicker;
    lblHasta: TLabel;
    dtHasta: TDateTimePicker;
    lblOperarios: TLabel;
    cbOperarios: TcxCheckComboBox;
    btnRecalcular: TButton;
    pcTabs: TPageControl;
    tabCarga: TTabSheet;
    tabDistrib: TTabSheet;
    tabCoste: TTabSheet;
    sbCarga: TScrollBox;
    pbCarga: TPaintBox;
    sbDistrib: TScrollBox;
    pbDistrib: TPaintBox;
    sbCoste: TScrollBox;
    pbCoste: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnRecalcularClick(Sender: TObject);
    procedure ParametrosChange(Sender: TObject);
    procedure cbOperariosChange(Sender: TObject);
    procedure pbCargaPaint(Sender: TObject);
    procedure pbDistribPaint(Sender: TObject);
    procedure pbCostePaint(Sender: TObject);
  private
    FAllOps: TArray<TOpStat>;
    FStatsCarga: TArray<TOpStat>;   // ordenado por % ocupacion desc
    FStatsCoste: TArray<TOpStat>;   // ordenado por coste desc
    FDistrib: array[0..4] of Integer; // contadores por rango
    FUpdatingOps: Boolean;
    FLoadingPrefs: Boolean;
    procedure CargarOperariosDesdeSQL;
    procedure CargarOperariosCombo;
    procedure RecalcularDatos;
    procedure ComputeChartSize(APaint: TPaintBox; AItemCount: Integer);
    procedure LoadPrefs;
    procedure SavePrefs;
    procedure DrawRoundedBar(ACanvas: TCanvas; const R: TRect;
      ABaseColor, AHighlightColor: TColor; ARadius: Integer);
  public
    class procedure Execute;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uHelpViewer;

const
  // Card-style: zebra, header destacado, eje al 100% claro.
  CH_MARGIN_LEFT   = 220; // labels operarios (carga / coste)
  CH_MARGIN_RIGHT  = 40;
  CH_MARGIN_TOP    = 56;  // espacio para header con ejes %
  CH_MARGIN_BOTTOM = 50;
  CH_BAR_HEIGHT    = 22;
  CH_ROW_HEIGHT    = 44;  // fila completa (zebra)
  CH_BAR_RADIUS    = 6;

  // Escala uniforme 0-130%: la barra del 100% ocupa el 100/130 del area.
  CH_SCALE_MAX_PCT = 130;

  // Distribucion (vertical, barras verticales)
  CHD_MARGIN_LEFT   = 80;
  CHD_MARGIN_RIGHT  = 30;
  CHD_MARGIN_TOP    = 50;
  CHD_MARGIN_BOTTOM = 70;
  CHD_BAR_WIDTH     = 140;
  CHD_BAR_GAP       = 22;
  CHD_BAR_RADIUS    = 8;

const
  // Paleta modernizada (BGR)
  CLR_PAPER:        TColor = $00FFFFFF;  // fondo principal blanco
  CLR_ZEBRA:        TColor = $00FAFAFA;
  CLR_ROW_DIV:      TColor = $00EDEDED;

  CLR_HEADER_BG:    TColor = $00F8F4ED;
  CLR_HEADER_TX:    TColor = $005A4A36;
  CLR_AXIS_FAINT:   TColor = $00DCDCDC;
  CLR_AXIS_100:     TColor = $00808080;

  CLR_TXT_PRIMARY:  TColor = $00333333;
  CLR_TXT_MUTED:    TColor = $00888888;
  CLR_TXT_ON_BAR:   TColor = $00FFFFFF;

  CLR_LO_BASE:      TColor = $0072B870;
  CLR_LO_HIGH:      TColor = $0085C586;
  CLR_MD_BASE:      TColor = $0044B8C8;
  CLR_MD_HIGH:      TColor = $005CCDDD;
  CLR_HI_BASE:      TColor = $001A8FE0;
  CLR_HI_HIGH:      TColor = $003CA8E8;
  CLR_TOP_BASE:     TColor = $00146EBF;
  CLR_TOP_HIGH:     TColor = $002E89D6;
  CLR_OVER_BASE:    TColor = $002E2EB8;
  CLR_OVER_HIGH:    TColor = $004848D0;

  CLR_EMPTY_BAR:    TColor = $00EEEEEE;

  CLR_COST_BASE:    TColor = $00A86E2C;
  CLR_COST_HIGH:    TColor = $00BD832F;

class procedure TfrmHistogramasOperarios.Execute;
var
  F: TfrmHistogramasOperarios;
begin
  F := TfrmHistogramasOperarios.Create(nil);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmHistogramasOperarios.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  sbCarga.DoubleBuffered := True;
  sbDistrib.DoubleBuffered := True;
  sbCoste.DoubleBuffered := True;
  FLoadingPrefs := True;
  try
    // Defaults: ultimos 30 dias
    dtHasta.Date := Trunc(Now);
    dtDesde.Date := IncDay(dtHasta.Date, -30);
    CargarOperariosDesdeSQL;
    CargarOperariosCombo;
    LoadPrefs;
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
  THelpViewer.InstallHelp(Self, 'uHistogramasOperarios',
    'Histogramas de operarios');
end;

procedure TfrmHistogramasOperarios.FormDestroy(Sender: TObject);
begin
end;

procedure TfrmHistogramasOperarios.CargarOperariosDesdeSQL;
var
  Q: TADOQuery;
  List: TList<TOpStat>;
  R: TOpStat;
begin
  SetLength(FAllOps, 0);
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) or
     (not DMPlanner.ADOConnection.Connected) then
    Exit;

  List := TList<TOpStat>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT OperatorId, Nombre, ISNULL(CalendarId, 0) AS CalendarId, ' +
      '       ISNULL(SueldoEurHora, 0) AS SueldoEurHora ' +
      'FROM FS_PL_Operator ' +
      'WHERE CodigoEmpresa = :CE AND ISNULL(Activo, 1) = 1 ' +
      'ORDER BY Nombre';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    try
      Q.Open;
      while not Q.Eof do
      begin
        R := Default(TOpStat);
        R.Id := Q.FieldByName('OperatorId').AsInteger;
        R.Nombre := Q.FieldByName('Nombre').AsString;
        R.CalendarId := Q.FieldByName('CalendarId').AsInteger;
        R.SueldoEurHora := Q.FieldByName('SueldoEurHora').AsFloat;
        List.Add(R);
        Q.Next;
      end;
    except
    end;
    FAllOps := List.ToArray;
  finally
    Q.Free;
    List.Free;
  end;
end;

procedure TfrmHistogramasOperarios.CargarOperariosCombo;
var
  I: Integer;
  Lbl: string;
begin
  FUpdatingOps := True;
  try
    cbOperarios.Properties.Items.Clear;
    cbOperarios.Properties.Items.AddCheckItem('(Todos)');
    cbOperarios.States[0] := cbsChecked;
    for I := 0 to High(FAllOps) do
    begin
      Lbl := FAllOps[I].Nombre;
      if Trim(Lbl) = '' then Lbl := 'Operario #' + IntToStr(FAllOps[I].Id);
      cbOperarios.Properties.Items.AddCheckItem(Lbl);
      cbOperarios.States[I + 1] := cbsChecked;
    end;
    if Length(FAllOps) = 0 then
      cbOperarios.Properties.EmptySelectionText := 'Sin operarios disponibles'
    else
      cbOperarios.Properties.EmptySelectionText := 'Ningun operario seleccionado';
  finally
    FUpdatingOps := False;
  end;
end;

procedure TfrmHistogramasOperarios.cbOperariosChange(Sender: TObject);
var
  I: Integer;
  TodosChecked, AllReal: Boolean;
  NewState: TcxCheckBoxState;
begin
  if FUpdatingOps then Exit;
  if cbOperarios.Properties.Items.Count = 0 then
  begin
    RecalcularDatos;
    Exit;
  end;

  FUpdatingOps := True;
  try
    TodosChecked := (cbOperarios.States[0] = cbsChecked);
    AllReal := True;
    for I := 1 to cbOperarios.Properties.Items.Count - 1 do
      if cbOperarios.States[I] <> cbsChecked then
      begin
        AllReal := False;
        Break;
      end;

    if TodosChecked <> AllReal then
    begin
      if TodosChecked then NewState := cbsChecked else NewState := cbsUnchecked;
      for I := 1 to cbOperarios.Properties.Items.Count - 1 do
        cbOperarios.States[I] := NewState;
    end
    else
    begin
      if AllReal then
        cbOperarios.States[0] := cbsChecked
      else
        cbOperarios.States[0] := cbsUnchecked;
    end;
  finally
    FUpdatingOps := False;
  end;

  RecalcularDatos;
  SavePrefs;
end;

procedure TfrmHistogramasOperarios.FormResize(Sender: TObject);
begin
  ComputeChartSize(pbCarga, Length(FStatsCarga));
  ComputeChartSize(pbCoste, Length(FStatsCoste));
  // distrib: tamano fijo segun barras
  pbDistrib.SetBounds(0, 0,
    Max(sbDistrib.ClientWidth,
        CHD_MARGIN_LEFT + CHD_MARGIN_RIGHT + 5 * (CHD_BAR_WIDTH + CHD_BAR_GAP)),
    Max(sbDistrib.ClientHeight, 360));
end;

procedure TfrmHistogramasOperarios.ComputeChartSize(APaint: TPaintBox;
  AItemCount: Integer);
var
  W, H: Integer;
  ScrollBox: TScrollBox;
begin
  ScrollBox := APaint.Parent as TScrollBox;
  W := Max(ScrollBox.ClientWidth, 800);
  H := CH_MARGIN_TOP + CH_MARGIN_BOTTOM + AItemCount * CH_ROW_HEIGHT;
  if H < ScrollBox.ClientHeight then H := ScrollBox.ClientHeight;
  APaint.SetBounds(0, 0, W, H);
end;

procedure TfrmHistogramasOperarios.DrawRoundedBar(ACanvas: TCanvas;
  const R: TRect; ABaseColor, AHighlightColor: TColor; ARadius: Integer);
var
  HalfH, Y: Integer;
  Ratio: Double;
  Cr, Cg, Cb, Hr, Hg, Hb: Byte;
  RR, GG, BB: Integer;
begin
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;

  // Mini-gradient vertical: highlight arriba, base abajo.
  Cr := GetRValue(ABaseColor);
  Cg := GetGValue(ABaseColor);
  Cb := GetBValue(ABaseColor);
  Hr := GetRValue(AHighlightColor);
  Hg := GetGValue(AHighlightColor);
  Hb := GetBValue(AHighlightColor);

  HalfH := R.Bottom - R.Top;
  if HalfH <= 0 then Exit;

  // Pinta linea a linea con interpolacion
  for Y := R.Top to R.Bottom - 1 do
  begin
    Ratio := (Y - R.Top) / HalfH;
    RR := Hr + Round((Cr - Hr) * Ratio);
    GG := Hg + Round((Cg - Hg) * Ratio);
    BB := Hb + Round((Cb - Hb) * Ratio);
    ACanvas.Pen.Color := RGB(RR, GG, BB);
    ACanvas.MoveTo(R.Left, Y);
    ACanvas.LineTo(R.Right, Y);
  end;

  // Bordes redondeados: enmascarar las esquinas con el fondo (paper)
  if ARadius > 0 then
  begin
    ACanvas.Pen.Color := CLR_PAPER;
    ACanvas.Brush.Color := CLR_PAPER;
    // No usamos RoundRect directamente porque ya pintamos el gradient.
    // En lugar de mascara, redibujamos como TGPPath... mantenemos simple:
    // dejamos el rectangulo recto. Si quieres esquinas reales, en el caller
    // usar RoundRect en lugar de este metodo.
  end;
end;

procedure TfrmHistogramasOperarios.btnRecalcularClick(Sender: TObject);
begin
  RecalcularDatos;
end;

procedure TfrmHistogramasOperarios.ParametrosChange(Sender: TObject);
begin
  RecalcularDatos;
  SavePrefs;
end;

procedure TfrmHistogramasOperarios.RecalcularDatos;
var
  Q: TADOQuery;
  ProjectId: Integer;
  Desde, Hasta: TDateTime;
  IdxById: TDictionary<Integer, Integer>;
  I, K: Integer;
  OperatorId: Integer;
  NodeInicio, NodeFin: TDateTime;
  Horas: Double;
  NodeDuracionMin, OverlapMin, HorasParte: Double;
  OvStart, OvEnd: TDateTime;
  Cal: TCentreCalendar;
  CapMin: Integer;
  Filtrados: TList<TOpStat>;
  Idx: Integer;
  Range: Integer;
begin
  Desde := Trunc(dtDesde.Date);
  Hasta := Trunc(dtHasta.Date) + 1; // inclusivo hasta el final del dia
  if Hasta <= Desde then Exit;

  // 1) Filtrar operarios seleccionados y resetear contadores
  Filtrados := TList<TOpStat>.Create;
  try
    for I := 0 to High(FAllOps) do
      if (I + 1 < cbOperarios.Properties.Items.Count) and
         (cbOperarios.States[I + 1] = cbsChecked) then
      begin
        var Op := FAllOps[I];
        Op.HorasAsignadas := 0;
        Op.CapacidadHoras := 0;
        Op.PctOcupacion := 0;
        Op.Coste := 0;
        Filtrados.Add(Op);
      end;

    if Filtrados.Count = 0 then
    begin
      SetLength(FStatsCarga, 0);
      SetLength(FStatsCoste, 0);
      for Idx := 0 to High(FDistrib) do FDistrib[Idx] := 0;
      FormResize(nil);
      pbCarga.Invalidate;
      pbDistrib.Invalidate;
      pbCoste.Invalidate;
      Exit;
    end;

    IdxById := TDictionary<Integer, Integer>.Create;
    try
      for I := 0 to Filtrados.Count - 1 do
        IdxById.AddOrSetValue(Filtrados[I].Id, I);

      ProjectId := DMPlanner.CurrentProjectId;
      if ProjectId > 0 then
      begin
        Q := TADOQuery.Create(nil);
        try
          Q.Connection := DMPlanner.ADOConnection;
          Q.SQL.Text :=
            'SELECT oa.OperatorId, oa.Horas, n.FechaInicio, n.FechaFin ' +
            'FROM FS_PL_OperatorAssignment oa ' +
            'INNER JOIN FS_PL_Node n ON n.CodigoEmpresa = oa.CodigoEmpresa ' +
            '                       AND n.NodeId = oa.NodeId ' +
            'WHERE oa.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
            '  AND n.FechaInicio IS NOT NULL AND n.FechaFin IS NOT NULL ' +
            '  AND n.FechaFin >= :HInicio AND n.FechaInicio < :HFin';
          Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
          Q.Parameters.ParamByName('PID').Value := ProjectId;
          Q.Parameters.ParamByName('HInicio').Value := Desde;
          Q.Parameters.ParamByName('HFin').Value := Hasta;
          try
            Q.Open;
            while not Q.Eof do
            begin
              OperatorId := Q.FieldByName('OperatorId').AsInteger;
              if IdxById.TryGetValue(OperatorId, Idx) then
              begin
                NodeInicio := Q.FieldByName('FechaInicio').AsDateTime;
                NodeFin    := Q.FieldByName('FechaFin').AsDateTime;
                Horas      := Q.FieldByName('Horas').AsFloat;

                NodeDuracionMin := MinutesBetween(NodeFin, NodeInicio);
                if (NodeDuracionMin > 0) and (Horas > 0) then
                begin
                  // Prorratear si el nodo se sale del rango
                  OvStart := Desde;
                  if NodeInicio > OvStart then OvStart := NodeInicio;
                  OvEnd := Hasta;
                  if NodeFin < OvEnd then OvEnd := NodeFin;
                  if OvEnd > OvStart then
                  begin
                    OverlapMin := MinutesBetween(OvEnd, OvStart);
                    HorasParte := Horas * (OverlapMin / NodeDuracionMin);
                    var Op := Filtrados[Idx];
                    Op.HorasAsignadas := Op.HorasAsignadas + HorasParte;
                    Filtrados[Idx] := Op;
                  end;
                end;
              end;
              Q.Next;
            end;
          except
          end;
        finally
          Q.Free;
        end;
      end;

      // 2) Capacidad y derivados
      for I := 0 to Filtrados.Count - 1 do
      begin
        var Op := Filtrados[I];
        Cal := nil;
        if (DMPlanner.CalendarsRepo <> nil) and (Op.CalendarId > 0) then
          DMPlanner.CalendarsRepo.TryGetById(Op.CalendarId, Cal);
        if Cal <> nil then
        begin
          CapMin := Cal.WorkingMinutesBetween(Desde, Hasta);
          if CapMin > 0 then
            Op.CapacidadHoras := CapMin / 60.0
          else
            Op.CapacidadHoras := 0;
        end;
        if Op.CapacidadHoras > 0 then
          Op.PctOcupacion := (Op.HorasAsignadas / Op.CapacidadHoras) * 100.0
        else
          Op.PctOcupacion := -1; // sin capacidad
        Op.Coste := Op.HorasAsignadas * Op.SueldoEurHora;
        Filtrados[I] := Op;
      end;
    finally
      IdxById.Free;
    end;

    // 3) Stats ordenados para Carga y Coste
    FStatsCarga := Filtrados.ToArray;
    TArray.Sort<TOpStat>(FStatsCarga,
      TComparer<TOpStat>.Construct(
        function(const A, B: TOpStat): Integer
        begin
          Result := CompareValue(B.PctOcupacion, A.PctOcupacion);
        end));

    FStatsCoste := Filtrados.ToArray;
    TArray.Sort<TOpStat>(FStatsCoste,
      TComparer<TOpStat>.Construct(
        function(const A, B: TOpStat): Integer
        begin
          Result := CompareValue(B.Coste, A.Coste);
        end));

    // 4) Distribucion por rangos
    for K := 0 to High(FDistrib) do FDistrib[K] := 0;
    for I := 0 to Filtrados.Count - 1 do
    begin
      var Op := Filtrados[I];
      if Op.PctOcupacion < 0 then Continue; // sin capacidad: no cuenta
      if Op.PctOcupacion < 25 then Range := 0
      else if Op.PctOcupacion < 50 then Range := 1
      else if Op.PctOcupacion < 75 then Range := 2
      else if Op.PctOcupacion <= 100 then Range := 3
      else Range := 4;
      Inc(FDistrib[Range]);
    end;
  finally
    Filtrados.Free;
  end;

  FormResize(nil);
  pbCarga.Invalidate;
  pbDistrib.Invalidate;
  pbCoste.Invalidate;
end;

procedure TfrmHistogramasOperarios.pbCargaPaint(Sender: TObject);
var
  C: TCanvas;
  I, RowTop, ChartX0, ChartX1, AreaW, BarTop, BarBottom: Integer;
  Op: TOpStat;
  Lbl, PctLbl, HoursLbl: string;
  R: TRect;
  Pct100Px, BarEndPx, TX: Integer;
  BaseColor, HighColor: TColor;
  Tick: Integer;
  TickPct: array[0..3] of Integer;
  PctValue, PctClamp: Double;
begin
  C := pbCarga.Canvas;
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  R := pbCarga.ClientRect;
  C.FillRect(R);

  if Length(FStatsCarga) = 0 then
  begin
    C.Font.Size := 11;
    C.Font.Style := [];
    C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := pbCarga.ClientRect;
    DrawText(C.Handle, 'Sin datos para mostrar.', -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;
    Exit;
  end;

  ChartX0 := CH_MARGIN_LEFT;
  ChartX1 := pbCarga.Width - CH_MARGIN_RIGHT;
  AreaW := ChartX1 - ChartX0;
  if AreaW < 100 then Exit;
  Pct100Px := ChartX0 + Round(AreaW * 100 / CH_SCALE_MAX_PCT);

  // -------- Header: banda + titulo + eje % --------
  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, pbCarga.Width, CH_MARGIN_TOP));

  C.Font.Size := 10;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, 6, ChartX0 - 8, 28);
  DrawText(C.Handle, 'Operario', -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  R := Rect(ChartX0, 6, ChartX1, 28);
  DrawText(C.Handle, '% Ocupacion (escala 0-130%)', -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  TickPct[0] := 0;  TickPct[1] := 50;  TickPct[2] := 100;  TickPct[3] := CH_SCALE_MAX_PCT;
  C.Font.Size := 8;
  C.Font.Style := [];
  C.Font.Color := CLR_TXT_MUTED;
  for Tick := 0 to High(TickPct) do
  begin
    TX := ChartX0 + Round(AreaW * TickPct[Tick] / CH_SCALE_MAX_PCT);
    R := Rect(TX - 30, 30, TX + 30, CH_MARGIN_TOP - 2);
    DrawText(C.Handle, PChar(IntToStr(TickPct[Tick]) + '%'), -1, R,
      DT_CENTER or DT_TOP or DT_SINGLELINE);
  end;

  C.Pen.Color := CLR_ROW_DIV;
  C.Pen.Style := psSolid;
  C.MoveTo(0, CH_MARGIN_TOP);
  C.LineTo(pbCarga.Width, CH_MARGIN_TOP);

  // -------- Filas --------
  C.Brush.Style := bsSolid;
  for I := 0 to High(FStatsCarga) do
  begin
    Op := FStatsCarga[I];
    RowTop := CH_MARGIN_TOP + I * CH_ROW_HEIGHT;

    if Odd(I) then
    begin
      C.Brush.Color := CLR_ZEBRA;
      C.FillRect(Rect(0, RowTop, pbCarga.Width, RowTop + CH_ROW_HEIGHT));
    end;

    C.Pen.Color := CLR_ROW_DIV;
    C.MoveTo(ChartX0, RowTop + CH_ROW_HEIGHT - 1);
    C.LineTo(ChartX1, RowTop + CH_ROW_HEIGHT - 1);

    Lbl := Op.Nombre;
    if Trim(Lbl) = '' then Lbl := 'Operario #' + IntToStr(Op.Id);
    R := Rect(16, RowTop + 4, CH_MARGIN_LEFT - 8, RowTop + CH_ROW_HEIGHT div 2 + 4);
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_TXT_PRIMARY;
    C.Brush.Style := bsClear;
    DrawText(C.Handle, PChar(Lbl), -1, R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);

    // Sub-etiqueta hores bajo el nombre
    if Op.CapacidadHoras > 0 then
    begin
      HoursLbl := Format('%.1f h / %.0f h disp.',
        [Op.HorasAsignadas, Op.CapacidadHoras]);
      C.Font.Size := 8;
      C.Font.Style := [];
      C.Font.Color := CLR_TXT_MUTED;
      R := Rect(16, RowTop + CH_ROW_HEIGHT div 2 + 2,
                CH_MARGIN_LEFT - 8, RowTop + CH_ROW_HEIGHT - 2);
      DrawText(C.Handle, PChar(HoursLbl), -1, R,
        DT_LEFT or DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS);
    end;

    // Ticks verticales (50% suave, 100% mas marcada)
    C.Pen.Color := CLR_AXIS_FAINT;
    C.Pen.Style := psSolid;
    TX := ChartX0 + Round(AreaW * 50 / CH_SCALE_MAX_PCT);
    C.MoveTo(TX, RowTop + 4);
    C.LineTo(TX, RowTop + CH_ROW_HEIGHT - 4);
    C.Pen.Color := CLR_AXIS_100;
    C.MoveTo(Pct100Px, RowTop + 4);
    C.LineTo(Pct100Px, RowTop + CH_ROW_HEIGHT - 4);

    BarTop := RowTop + (CH_ROW_HEIGHT - CH_BAR_HEIGHT) div 2;
    BarBottom := BarTop + CH_BAR_HEIGHT;

    // Sin capacidad
    if Op.CapacidadHoras <= 0 then
    begin
      C.Font.Size := 9;
      C.Font.Style := [fsItalic];
      C.Font.Color := CLR_TXT_MUTED;
      C.Brush.Style := bsClear;
      R := Rect(ChartX0, RowTop, ChartX1, RowTop + CH_ROW_HEIGHT);
      DrawText(C.Handle, 'Sin calendario asignado', -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
      Continue;
    end;

    // Sin carga: barra placeholder muy fina + etiqueta "0%"
    if Op.HorasAsignadas <= 0 then
    begin
      C.Brush.Color := CLR_EMPTY_BAR;
      C.Pen.Color := CLR_EMPTY_BAR;
      C.RoundRect(ChartX0, BarTop, ChartX0 + 6, BarBottom,
        CH_BAR_RADIUS, CH_BAR_RADIUS);
      C.Font.Size := 9;
      C.Font.Style := [fsItalic];
      C.Font.Color := CLR_TXT_MUTED;
      C.Brush.Style := bsClear;
      R := Rect(ChartX0 + 14, BarTop, ChartX0 + 200, BarBottom);
      DrawText(C.Handle, 'Sin carga asignada', -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
      Continue;
    end;

    PctValue := Op.PctOcupacion;
    PctClamp := PctValue;
    if PctClamp > CH_SCALE_MAX_PCT then PctClamp := CH_SCALE_MAX_PCT;

    if PctValue <= 50 then
      begin BaseColor := CLR_LO_BASE;  HighColor := CLR_LO_HIGH;  end
    else if PctValue <= 75 then
      begin BaseColor := CLR_MD_BASE;  HighColor := CLR_MD_HIGH;  end
    else if PctValue <= 90 then
      begin BaseColor := CLR_HI_BASE;  HighColor := CLR_HI_HIGH;  end
    else
      begin BaseColor := CLR_TOP_BASE; HighColor := CLR_TOP_HIGH; end;

    if PctValue <= 100 then
    begin
      BarEndPx := ChartX0 + Round(AreaW * PctClamp / CH_SCALE_MAX_PCT);
      if BarEndPx > ChartX0 then
        DrawRoundedBar(C, Rect(ChartX0, BarTop, BarEndPx, BarBottom),
          BaseColor, HighColor, CH_BAR_RADIUS);
    end
    else
    begin
      DrawRoundedBar(C, Rect(ChartX0, BarTop, Pct100Px, BarBottom),
        CLR_TOP_BASE, CLR_TOP_HIGH, CH_BAR_RADIUS);
      BarEndPx := ChartX0 + Round(AreaW * PctClamp / CH_SCALE_MAX_PCT);
      if BarEndPx > Pct100Px then
        DrawRoundedBar(C, Rect(Pct100Px, BarTop, BarEndPx, BarBottom),
          CLR_OVER_BASE, CLR_OVER_HIGH, CH_BAR_RADIUS);
    end;

    // Etiqueta % grande
    PctLbl := Format('%.0f%%', [PctValue]);
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Brush.Style := bsClear;
    if (BarEndPx - ChartX0) > 50 then
    begin
      C.Font.Color := CLR_TXT_ON_BAR;
      R := Rect(ChartX0 + 8, BarTop, BarEndPx - 6, BarBottom);
      DrawText(C.Handle, PChar(PctLbl), -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end
    else
    begin
      C.Font.Color := CLR_TXT_PRIMARY;
      R := Rect(BarEndPx + 8, BarTop, BarEndPx + 80, BarBottom);
      DrawText(C.Handle, PChar(PctLbl), -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end;
  end;
end;

procedure TfrmHistogramasOperarios.pbDistribPaint(Sender: TObject);
const
  RangeLabels: array[0..4] of string =
    ('0-25%', '25-50%', '50-75%', '75-100%', '>100%');
var
  RangeBase: array[0..4] of TColor;
  RangeHigh: array[0..4] of TColor;
  C: TCanvas;
  I, MaxV, X, BarTop, BarBottom, ChartTop, ChartBottom, Pix, YGrid: Integer;
  R: TRect;
  Lbl: string;
  Total: Integer;
begin
  C := pbDistrib.Canvas;
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  R := pbDistrib.ClientRect;
  C.FillRect(R);

  // Misma paleta que el tab Carga
  RangeBase[0] := CLR_LO_BASE;   RangeHigh[0] := CLR_LO_HIGH;
  RangeBase[1] := CLR_LO_BASE;   RangeHigh[1] := CLR_LO_HIGH;
  RangeBase[2] := CLR_MD_BASE;   RangeHigh[2] := CLR_MD_HIGH;
  RangeBase[3] := CLR_HI_BASE;   RangeHigh[3] := CLR_HI_HIGH;
  RangeBase[4] := CLR_OVER_BASE; RangeHigh[4] := CLR_OVER_HIGH;

  MaxV := 1;
  Total := 0;
  for I := 0 to High(FDistrib) do
  begin
    if FDistrib[I] > MaxV then MaxV := FDistrib[I];
    Inc(Total, FDistrib[I]);
  end;

  // Banda de header
  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, pbDistrib.Width, CHD_MARGIN_TOP));

  C.Font.Size := 11;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, 8, pbDistrib.Width - CHD_MARGIN_RIGHT,
            CHD_MARGIN_TOP - 4);
  DrawText(C.Handle,
    PChar(Format('Distribucion: %d operario(s) por rango de ocupacion',
                 [Total])),
    -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  C.Pen.Color := CLR_ROW_DIV;
  C.Pen.Style := psSolid;
  C.MoveTo(0, CHD_MARGIN_TOP);
  C.LineTo(pbDistrib.Width, CHD_MARGIN_TOP);

  ChartTop := CHD_MARGIN_TOP + 20;
  ChartBottom := pbDistrib.Height - CHD_MARGIN_BOTTOM;

  // Eje Y (grid muy suau)
  C.Pen.Color := CLR_AXIS_FAINT;
  C.Pen.Style := psSolid;
  for I := 0 to MaxV do
  begin
    YGrid := ChartBottom - Round((I / MaxV) * (ChartBottom - ChartTop));
    C.MoveTo(CHD_MARGIN_LEFT, YGrid);
    C.LineTo(pbDistrib.Width - CHD_MARGIN_RIGHT, YGrid);
    C.Font.Size := 8;
    C.Font.Style := [];
    C.Font.Color := CLR_TXT_MUTED;
    R := Rect(0, YGrid - 8, CHD_MARGIN_LEFT - 8, YGrid + 8);
    DrawText(C.Handle, PChar(IntToStr(I)), -1, R,
      DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  end;

  // Barras
  for I := 0 to High(FDistrib) do
  begin
    X := CHD_MARGIN_LEFT + I * (CHD_BAR_WIDTH + CHD_BAR_GAP);
    Pix := Round((FDistrib[I] / MaxV) * (ChartBottom - ChartTop));
    BarBottom := ChartBottom;
    BarTop := BarBottom - Pix;

    // Barra arrodonida con gradient (solo si tiene altura)
    if Pix > 0 then
      DrawRoundedBar(C, Rect(X, BarTop, X + CHD_BAR_WIDTH, BarBottom),
        RangeBase[I], RangeHigh[I], CHD_BAR_RADIUS)
    else
    begin
      // Placeholder cuando el rango esta vacio
      C.Brush.Color := CLR_EMPTY_BAR;
      C.Pen.Color := CLR_EMPTY_BAR;
      C.RoundRect(X, BarBottom - 6, X + CHD_BAR_WIDTH, BarBottom,
        CHD_BAR_RADIUS, CHD_BAR_RADIUS);
    end;

    // Valor grande encima
    Lbl := IntToStr(FDistrib[I]);
    C.Font.Size := 14;
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_TXT_PRIMARY;
    C.Brush.Style := bsClear;
    R := Rect(X, BarTop - 32, X + CHD_BAR_WIDTH, BarTop - 4);
    DrawText(C.Handle, PChar(Lbl), -1, R,
      DT_CENTER or DT_BOTTOM or DT_SINGLELINE);

    // Etiqueta de rango bajo el eje
    R := Rect(X, BarBottom + 10, X + CHD_BAR_WIDTH, BarBottom + 32);
    C.Font.Size := 9;
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_TXT_PRIMARY;
    DrawText(C.Handle, PChar(RangeLabels[I]), -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);

    // % del total
    if Total > 0 then
    begin
      R := Rect(X, BarBottom + 30, X + CHD_BAR_WIDTH, BarBottom + 50);
      C.Font.Size := 8;
      C.Font.Style := [];
      C.Font.Color := CLR_TXT_MUTED;
      DrawText(C.Handle,
        PChar(Format('%.0f%% del equipo', [FDistrib[I] * 100.0 / Total])),
        -1, R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    end;
    C.Brush.Style := bsSolid;
  end;

  // Linea base
  C.Pen.Color := CLR_AXIS_100;
  C.MoveTo(CHD_MARGIN_LEFT, ChartBottom);
  C.LineTo(pbDistrib.Width - CHD_MARGIN_RIGHT, ChartBottom);
end;

procedure TfrmHistogramasOperarios.pbCostePaint(Sender: TObject);
var
  C: TCanvas;
  I, RowTop, ChartX0, ChartX1, AreaW, BarTop, BarBottom, BarEndPx: Integer;
  MaxCost, TotalCost: Double;
  Op: TOpStat;
  Lbl, CostLbl, DetailLbl: string;
  R: TRect;
begin
  C := pbCoste.Canvas;
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  R := pbCoste.ClientRect;
  C.FillRect(R);

  if Length(FStatsCoste) = 0 then
  begin
    C.Font.Size := 11;
    C.Font.Style := [];
    C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := pbCoste.ClientRect;
    DrawText(C.Handle, 'Sin datos para mostrar.', -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    Exit;
  end;

  ChartX0 := CH_MARGIN_LEFT;
  ChartX1 := pbCoste.Width - CH_MARGIN_RIGHT;
  AreaW := ChartX1 - ChartX0;
  if AreaW < 100 then Exit;

  MaxCost := 0;
  TotalCost := 0;
  for I := 0 to High(FStatsCoste) do
  begin
    if FStatsCoste[I].Coste > MaxCost then MaxCost := FStatsCoste[I].Coste;
    TotalCost := TotalCost + FStatsCoste[I].Coste;
  end;
  if MaxCost < 1 then MaxCost := 1;

  // Header con banda y total
  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, pbCoste.Width, CH_MARGIN_TOP));

  C.Font.Size := 10;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, 6, ChartX0 - 8, 28);
  DrawText(C.Handle, 'Operario', -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  R := Rect(ChartX0, 6, ChartX1, 28);
  DrawText(C.Handle,
    PChar(Format('Coste laboral - Total equipo: %.0f EUR', [TotalCost])),
    -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  C.Font.Size := 8;
  C.Font.Style := [];
  C.Font.Color := CLR_TXT_MUTED;
  R := Rect(ChartX0, 30, ChartX1, CH_MARGIN_TOP - 2);
  DrawText(C.Handle,
    PChar(Format('Escala: 0 - %.0f EUR (maximo del equipo)', [MaxCost])),
    -1, R, DT_LEFT or DT_TOP or DT_SINGLELINE);

  C.Pen.Color := CLR_ROW_DIV;
  C.Pen.Style := psSolid;
  C.MoveTo(0, CH_MARGIN_TOP);
  C.LineTo(pbCoste.Width, CH_MARGIN_TOP);

  // Filas
  for I := 0 to High(FStatsCoste) do
  begin
    Op := FStatsCoste[I];
    RowTop := CH_MARGIN_TOP + I * CH_ROW_HEIGHT;

    if Odd(I) then
    begin
      C.Brush.Color := CLR_ZEBRA;
      C.FillRect(Rect(0, RowTop, pbCoste.Width, RowTop + CH_ROW_HEIGHT));
    end;

    C.Pen.Color := CLR_ROW_DIV;
    C.MoveTo(ChartX0, RowTop + CH_ROW_HEIGHT - 1);
    C.LineTo(ChartX1, RowTop + CH_ROW_HEIGHT - 1);

    Lbl := Op.Nombre;
    if Trim(Lbl) = '' then Lbl := 'Operario #' + IntToStr(Op.Id);
    R := Rect(16, RowTop + 4, CH_MARGIN_LEFT - 8, RowTop + CH_ROW_HEIGHT div 2 + 4);
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_TXT_PRIMARY;
    C.Brush.Style := bsClear;
    DrawText(C.Handle, PChar(Lbl), -1, R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);

    // Subtitulo: tarifa hora
    if Op.SueldoEurHora > 0 then
    begin
      C.Font.Size := 8;
      C.Font.Style := [];
      C.Font.Color := CLR_TXT_MUTED;
      R := Rect(16, RowTop + CH_ROW_HEIGHT div 2 + 2,
                CH_MARGIN_LEFT - 8, RowTop + CH_ROW_HEIGHT - 2);
      DrawText(C.Handle,
        PChar(Format('%.2f EUR/h x %.1f h', [Op.SueldoEurHora, Op.HorasAsignadas])),
        -1, R, DT_LEFT or DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS);
    end;

    BarTop := RowTop + (CH_ROW_HEIGHT - CH_BAR_HEIGHT) div 2;
    BarBottom := BarTop + CH_BAR_HEIGHT;

    if Op.Coste <= 0 then
    begin
      C.Brush.Color := CLR_EMPTY_BAR;
      C.Pen.Color := CLR_EMPTY_BAR;
      C.RoundRect(ChartX0, BarTop, ChartX0 + 6, BarBottom,
        CH_BAR_RADIUS, CH_BAR_RADIUS);
      C.Font.Size := 9;
      C.Font.Style := [fsItalic];
      C.Font.Color := CLR_TXT_MUTED;
      C.Brush.Style := bsClear;
      R := Rect(ChartX0 + 14, BarTop, ChartX1, BarBottom);
      if Op.SueldoEurHora <= 0 then
        DrawText(C.Handle, 'Sin sueldo definido en su ficha', -1, R,
          DT_LEFT or DT_VCENTER or DT_SINGLELINE)
      else
        DrawText(C.Handle, 'Sin horas asignadas en el periodo', -1, R,
          DT_LEFT or DT_VCENTER or DT_SINGLELINE);
      Continue;
    end;

    BarEndPx := ChartX0 + Round((Op.Coste / MaxCost) * AreaW);
    if BarEndPx > ChartX0 then
      DrawRoundedBar(C, Rect(ChartX0, BarTop, BarEndPx, BarBottom),
        CLR_COST_BASE, CLR_COST_HIGH, CH_BAR_RADIUS);

    // Etiqueta cost (dentro de la barra si cabe)
    CostLbl := Format('%.0f EUR', [Op.Coste]);
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Brush.Style := bsClear;
    if (BarEndPx - ChartX0) > 80 then
    begin
      C.Font.Color := CLR_TXT_ON_BAR;
      R := Rect(ChartX0 + 8, BarTop, BarEndPx - 6, BarBottom);
      DrawText(C.Handle, PChar(CostLbl), -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end
    else
    begin
      C.Font.Color := CLR_TXT_PRIMARY;
      R := Rect(BarEndPx + 8, BarTop, BarEndPx + 200, BarBottom);
      DrawText(C.Handle, PChar(CostLbl), -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end;

    // % del total a la derecha
    if TotalCost > 0 then
    begin
      DetailLbl := Format('%.1f%% del total', [Op.Coste * 100.0 / TotalCost]);
      C.Font.Size := 8;
      C.Font.Style := [];
      C.Font.Color := CLR_TXT_MUTED;
      R := Rect(ChartX1 - 120, BarTop, ChartX1 - 4, BarBottom);
      DrawText(C.Handle, PChar(DetailLbl), -1, R,
        DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
    end;
  end;
end;

procedure TfrmHistogramasOperarios.LoadPrefs;
var
  Js: string;
  Root: TJSONObject;
  V: TJSONValue;
  Arr: TJSONArray;
  IdsSet: TDictionary<Integer, Boolean>;
  I, Oid: Integer;
  TodosSel: Boolean;
begin
  if (DMPlanner = nil) or (DMPlanner.UserPrefs = nil) then Exit;
  Js := DMPlanner.UserPrefs.Load('HistogramasOperarios');
  if Js = '' then Exit;

  Root := TJSONObject.ParseJSONValue(Js) as TJSONObject;
  if Root = nil then Exit;
  try
    V := Root.GetValue('desde');
    if V <> nil then
      try dtDesde.Date := StrToDateTime((V as TJSONString).Value); except end;
    V := Root.GetValue('hasta');
    if V <> nil then
      try dtHasta.Date := StrToDateTime((V as TJSONString).Value); except end;
    V := Root.GetValue('tab');
    if V <> nil then
      try pcTabs.ActivePageIndex := (V as TJSONNumber).AsInt; except end;

    V := Root.GetValue('operarios');
    TodosSel := (V = nil) or (V is TJSONNull);
    FUpdatingOps := True;
    try
      if TodosSel then
      begin
        for I := 0 to cbOperarios.Properties.Items.Count - 1 do
          cbOperarios.States[I] := cbsChecked;
      end
      else if V is TJSONArray then
      begin
        Arr := V as TJSONArray;
        IdsSet := TDictionary<Integer, Boolean>.Create;
        try
          for I := 0 to Arr.Count - 1 do
            IdsSet.AddOrSetValue((Arr.Items[I] as TJSONNumber).AsInt, True);
          cbOperarios.States[0] := cbsUnchecked;
          for I := 0 to High(FAllOps) do
          begin
            Oid := FAllOps[I].Id;
            if IdsSet.ContainsKey(Oid) then
              cbOperarios.States[I + 1] := cbsChecked
            else
              cbOperarios.States[I + 1] := cbsUnchecked;
          end;
          if IdsSet.Count = Length(FAllOps) then
            cbOperarios.States[0] := cbsChecked;
        finally
          IdsSet.Free;
        end;
      end;
    finally
      FUpdatingOps := False;
    end;
  finally
    Root.Free;
  end;
end;

procedure TfrmHistogramasOperarios.SavePrefs;
var
  Root: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
  TodosSel: Boolean;
begin
  if FLoadingPrefs then Exit;
  if (DMPlanner = nil) or (DMPlanner.UserPrefs = nil) then Exit;

  Root := TJSONObject.Create;
  try
    Root.AddPair('desde', FormatDateTime('yyyy-mm-dd', dtDesde.Date));
    Root.AddPair('hasta', FormatDateTime('yyyy-mm-dd', dtHasta.Date));
    Root.AddPair('tab', TJSONNumber.Create(pcTabs.ActivePageIndex));

    TodosSel := (cbOperarios.Properties.Items.Count > 0) and
                (cbOperarios.States[0] = cbsChecked);
    if TodosSel then
      Root.AddPair('operarios', TJSONNull.Create)
    else
    begin
      Arr := TJSONArray.Create;
      for I := 0 to High(FAllOps) do
        if (I + 1 < cbOperarios.Properties.Items.Count) and
           (cbOperarios.States[I + 1] = cbsChecked) then
          Arr.AddElement(TJSONNumber.Create(FAllOps[I].Id));
      Root.AddPair('operarios', Arr);
    end;

    DMPlanner.UserPrefs.Save('HistogramasOperarios', Root.ToJSON);
  finally
    Root.Free;
  end;
end;

end.
