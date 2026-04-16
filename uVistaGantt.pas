unit uVistaGantt;

// Vista Gantt embebible.
// Fase 1: esqueleto vacío. En pasos siguientes se irán copiando aquí
// desde Main los componentes (toolbar, pnlCentros, pnlGanttContainer,
// panel inferior, popups) y sus handlers.
//
// Renombrado de convivencia durante la extracción:
//   Main.FGantt      -> VistaGantt.FGanttControl
//   Main.FTimeline   -> VistaGantt.FTimelineControl

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, DateUtils,
  uGanttHelpers, uCentreCalendar,
  uNodeDataRepo, uOperariosRepo, uMoldeRepo,
  uCustomFieldDefs, uPlanningRules, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxSkinsCore, dxSkinBasic,
  dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee,
  dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019Colorful,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, Vcl.ComCtrls, dxCore,
  cxDateUtils, cxCheckBox, Vcl.Menus, dxCoreGraphics, cxButtonEdit, cxScrollBox,
  cxButtons, cxDropDownEdit, cxCheckComboBox, Vcl.StdCtrls, Vcl.WinXCtrls,
  cxCalendar, cxTextEdit, cxMaskEdit, cxSpinEdit,
  uGanttControl, uGanttTimeline, uGanttCentres, uGanttTypes, uErpTypes;

type
  TfrmVistaGantt = class(TForm)
    pnlRoot: TPanel;
    Panel1: TPanel;
    pnlToolbar: TPanel;
    lblCurrentEmpresa: TLabel;
    lblCurrentProyecto: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    lblUndoCount: TLabel;
    lblRedoCount: TLabel;
    Label19: TLabel;
    btnRefresh: TButton;
    spCentros: TcxSpinEdit;
    cxSpinEdit2: TcxSpinEdit;
    dtFechaInicioGantt: TcxDateEdit;
    dtFechaFinGantt: TcxDateEdit;
    SearchBox1: TSearchBox;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    cxDateEdit1: TcxDateEdit;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    ComboBox1: TComboBox;
    Button1: TButton;
    ComboBox2: TComboBox;
    btnUndo: TButton;
    btnRedo: TButton;
    Button12: TButton;
    Button13: TButton;
    FcxFilterOperarios: TcxCheckComboBox;
    FchkSoloFiltrados: TcxCheckBox;
    Button25: TButton;
    Button26: TButton;
    Panel3: TPanel;
    Label12: TLabel;
    Label18: TLabel;
    Panel4: TPanel;
    Label9: TLabel;
    lblNodes: TLabel;
    Panel5: TPanel;
    Label10: TLabel;
    lblVisible: TLabel;
    Panel6: TPanel;
    Label11: TLabel;
    lblModified: TLabel;
    Panel7: TPanel;
    Label13: TLabel;
    lblNormal: TLabel;
    Panel8: TPanel;
    Label14: TLabel;
    lblYellow: TLabel;
    Panel9: TPanel;
    Label15: TLabel;
    lblOrange: TLabel;
    Panel10: TPanel;
    Label16: TLabel;
    lblRed: TLabel;
    Panel11: TPanel;
    Label17: TLabel;
    lblGreen: TLabel;
    Button16: TButton;
    Button17: TButton;
    Button19: TButton;
    Button18: TButton;
    Button21: TButton;
    Button22: TButton;
    Button2: TButton;
    Button23: TButton;
    Button24: TButton;
    btnResaltarOF: TcxButton;
    btnResaltarOT: TcxButton;
    pnlBuscar: TPanel;
    cxScrollBox1: TcxScrollBox;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    cxButtonEdit1: TcxButtonEdit;
    cxButtonEdit2: TcxButtonEdit;
    cxButtonEdit3: TcxButtonEdit;
    cxButtonEdit4: TcxButtonEdit;
    cxButtonEdit5: TcxButtonEdit;
    cxButtonEdit6: TcxButtonEdit;
    cxButtonEdit7: TcxButtonEdit;
    cxButtonEdit8: TcxButtonEdit;
    cxButton1: TcxButton;
    cxButton2: TcxButton;
    cxButton3: TcxButton;
    cxButton4: TcxButton;
    cxButton5: TcxButton;
    pnlCentros: TPanel;
    pnlGanttContainer: TPanel;
    Panel2: TPanel;
    Shape1: TShape;
    Shape2: TShape;
    Button14: TButton;
    Button15: TButton;
    chkShowKPIs: TCheckBox;
    Button20: TButton;
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblFechaHora: TLabel;
    pnlSubTitulo: TPanel;
    Button27: TButton;
    popCentros: TPopupMenu;
    INFO3: TMenuItem;
    popGantt: TPopupMenu;
    MenuItem1: TMenuItem;
    Desactivarfechabloqueo1: TMenuItem;
    Calendario1: TMenuItem;
    Fechayhora1: TMenuItem;
    CentroAAA1: TMenuItem;
    NombreAAA1: TMenuItem;
    FranjalaborableSi1: TMenuItem;
    PeriodoNoLaborableInicio1: TMenuItem;
    PeriodoNoLaborableFin1: TMenuItem;
    ShiftRow1: TMenuItem;
    ShiftRowallimpact1: TMenuItem;
    N2: TMenuItem;
    Aadirmarcador1: TMenuItem;
    Gestionmarcadores1: TMenuItem;
    Marcadoresautomaticos1: TMenuItem;
    popTimeline: TPopupMenu;
    MenuItem2: TMenuItem;
    popNode: TPopupMenu;
    MenuItem3: TMenuItem;
    LibreMovimiento1: TMenuItem;
    Resetduracinoriginal1: TMenuItem;
    CompactarOF1: TMenuItem;
    odalaOF1: TMenuItem;
    odalaOF2: TMenuItem;
    CompactarOFapartirdelNodo1: TMenuItem;
    ApartirdelNodoconprioridad1: TMenuItem;
    CompactarOT1: TMenuItem;
    otalaOT1: TMenuItem;
    odalaOTconprioridad1: TMenuItem;
    ApartirdelNodo1: TMenuItem;
    ApartirdelNodoconprioridad2: TMenuItem;
    ShiftRow2: TMenuItem;
    N1: TMenuItem;
    Color1: TMenuItem;
    Colordelnode1: TMenuItem;
    ColordelaOrdendetrabajo1: TMenuItem;
    ColordelaOrdendeFabricacin1: TMenuItem;
    ColordelPedido1: TMenuItem;
    ColordelProyecto1: TMenuItem;
    ResaltarOF1: TMenuItem;
    Info1: TMenuItem;
    procedure pnlGanttContainerResize(Sender: TObject);
    procedure TimelineViewportChanged(Sender: TObject;
      const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
    procedure TimelineInteraction(Sender: TObject; const Interacting: Boolean);
    procedure GanttViewportChanged(Sender: TObject;
      const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
    procedure GanttScrollYChanged(Sender: TObject; const ScrollY: Single);
    procedure GanttStatsChanged(Sender: TObject);
    procedure GanttLayoutChanged(Sender: TObject);
    procedure GanttNodeSelected(Sender: TObject);
    procedure GanttVoidClick(Sender: TObject);
    procedure GanttNodeDblClick(Sender: TObject; const NodeIndex: Integer);
    procedure GanttMarkerDblClick(Sender: TObject; const MarkerId: Integer);
    procedure CentresScrollYChanged(Sender: TObject; const ScrollY: Single);
    procedure Button27Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FNodeRepo: TNodeDataRepo;
    FOperariosRepo: TOperariosRepo;
    FMoldeRepo: TMoldeRepo;
    FCustomFieldDefs: TCustomFieldDefs;
    FPlanningRuleEngine: TPlanningRuleEngine;
    FGanttControl: TGanttControl;
    FTimelineControl: TGanttTimelineControl;
    FCentrosControl: TGanttCentresControl;
    FUpdatingViewport: Boolean;
  public
    constructor CreateVista(AOwner: TComponent;
      ANodeRepo: TNodeDataRepo;
      AOperariosRepo: TOperariosRepo;
      AMoldeRepo: TMoldeRepo;
      ACustomFieldDefs: TCustomFieldDefs;
      APlanningRuleEngine: TPlanningRuleEngine);
    property GanttControl: TGanttControl read FGanttControl;
    property TimelineControl: TGanttTimelineControl read FTimelineControl;
    property CentrosControl: TGanttCentresControl read FCentrosControl;
    procedure Inicializar(const AFechaInicio, AFechaFin: TDateTime);
    procedure CargarCentros;
    procedure CargarDependencias;
    procedure CargarMarcadores;
    procedure AplicarCalendariosAGantt;
    procedure IrAFecha(const ADate: TDateTime);
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, Vcl.Dialogs, Data.Win.ADODB, Data.DB;

constructor TfrmVistaGantt.CreateVista(AOwner: TComponent;
  ANodeRepo: TNodeDataRepo;
  AOperariosRepo: TOperariosRepo;
  AMoldeRepo: TMoldeRepo;
  ACustomFieldDefs: TCustomFieldDefs;
  APlanningRuleEngine: TPlanningRuleEngine);
begin
  inherited Create(AOwner);
  FNodeRepo := ANodeRepo;
  FOperariosRepo := AOperariosRepo;
  FMoldeRepo := AMoldeRepo;
  FCustomFieldDefs := ACustomFieldDefs;
  FPlanningRuleEngine := APlanningRuleEngine;

  // Crear controles Gantt (renombrados: FGanttControl / FTimelineControl)
  FTimelineControl := TGanttTimelineControl.Create(Self);
  FTimelineControl.Parent := pnlGanttContainer;
  FTimelineControl.Align := alTop;
  FTimelineControl.LeftWidth := 0;
  FTimelineControl.PopupMenu := popTimeline;

  FGanttControl := TGanttControl.Create(Self);
  FGanttControl.Parent := pnlGanttContainer;
  FGanttControl.Align := alClient;
  FGanttControl.ShowHint := True;
  FGanttControl.NodePopupMenu := popNode;
  FGanttControl.PopupMenu := popGantt;
  // Importante: el Gantt necesita el repo para resolver NodeData al pintar.
  // Sin esto, BuildDataIdIndex/RebuildLayout acceden a puntero nil.
  FGanttControl.SetNodeRepo(FNodeRepo);

  FCentrosControl := TGanttCentresControl.Create(Self);
  FCentrosControl.Parent := pnlCentros;
  FCentrosControl.Align := alLeft;
  FCentrosControl.PopupMenu := popCentros;

  pnlCentros.Width := FCentrosControl.BaseWidth;
  FCentrosControl.VerIndicadores := False;

  // Cablear eventos (stubs por ahora — lógica real en pasos siguientes)
  FTimelineControl.OnViewportChanged := TimelineViewportChanged;
  FTimelineControl.OnInteraction := TimelineInteraction;

  FGanttControl.OnViewportChanged := GanttViewportChanged;
  FGanttControl.OnScrollYChanged := GanttScrollYChanged;
  FGanttControl.OnNodeDblClick := GanttNodeDblClick;
  FGanttControl.OnMarkerDblClick := GanttMarkerDblClick;
  FGanttControl.OnStatsChanged := GanttStatsChanged;
  FGanttControl.OnLayoutChanged := GanttLayoutChanged;
  FGanttControl.OnNodeSelected := GanttNodeSelected;
  FGanttControl.OnVoid := GanttVoidClick;

  FCentrosControl.OnScrollYChanged := CentresScrollYChanged;
end;

procedure TfrmVistaGantt.FormCreate(Sender: TObject);
begin
  Panel1.Height := pnlTitulo.Height + pnlSubTitulo.Height;
end;

procedure TfrmVistaGantt.Inicializar(const AFechaInicio, AFechaFin: TDateTime);
var
  T0, T1: TDateTime;
begin
  T0 := DayStart(AFechaInicio - 2);
  T1 := DayEnd(AFechaFin);
  if T1 < T0 then
    T1 := DayEnd(T0);

  FTimelineControl.SetTimeRange(T0, T1);
  // También el Gantt: sin esto, FContentWidth queda limitado a ClientWidth
  // y el panning del timeline no puede desplazar el Gantt (MaxScrollX = 0).
  FGanttControl.SetTimeRange(T0, T1);

  CargarCentros;

  // Centrar la vista en la fecha actual al abrir.
  IrAFecha(Now);
end;

procedure TfrmVistaGantt.Button27Click(Sender: TObject);
begin
  pnlToolbar.Visible := not pnlToolbar.Visible;
  Panel3.Visible := not Panel3.Visible;

  if pnlToolbar.Visible then
   Panel1.Height := pnlToolbar.Height + Panel3.Height
  else
   Panel1.Height := pnlTitulo.Height + pnlSubTitulo.Height;

end;

procedure TfrmVistaGantt.CargarCentros;
var
  Centres: TArray<TCentreTreball>;
  CentresLocal: TArray<TCentreTreball>;
  Rows: TArray<TRowLayout>;
  Nodes: TArray<TNode>;
  I: Integer;
  Y: Single;
begin
  if DMPlanner.CentresRepo = nil then Exit;

  Centres := DMPlanner.CentresRepo.GetAll;
  CentresLocal := Centres;

  FCentrosControl.GetCentreName :=
    function(const CentreId: Integer): string
    var
      J: Integer;
    begin
      Result := '';
      for J := 0 to High(CentresLocal) do
        if CentresLocal[J].Id = CentreId then
          Exit(CentresLocal[J].Titulo);
    end;

  FCentrosControl.SetCentres(Centres);

  // Cargar nodos reales del proyecto activo desde BD.
  // LoadNodes limpia y rellena el FNodeRepo con los NodeData correspondientes.
  DMPlanner.LoadNodes(FNodeRepo);
  if DMPlanner.NodesRepo <> nil then
    Nodes := DMPlanner.NodesRepo.GetAll
  else
    SetLength(Nodes, 0);

  FGanttControl.SetData(Centres, Nodes, FTimelineControl.StartTime);
  FGanttControl.RebuildOpIdIndex;
  FGanttControl.RebuildNodeLayoutIndex;

  // Copiar reglas de cada calendario al calendario interno del Gantt por centro.
  AplicarCalendariosAGantt;

  // Dependencias entre nodos (flechas)
  CargarDependencias;

  // Marcadores verticales del proyecto
  CargarMarcadores;

  // Fecha de bloqueo del proyecto (si el proyecto la tiene configurada)
  if DMPlanner.CurrentProjectTieneBloqueo then
    FGanttControl.FechaBloqueo := DMPlanner.CurrentProjectFechaBloqueo
  else
    FGanttControl.FechaBloqueo := 0;

  // Usar el layout calculado por el Gantt y publicarlo a la columna de centros.
  // Así ambos controles comparten las mismas filas y el scroll/zoom las mantiene.
  FCentrosControl.SetRows(FGanttControl.GetRowsCopy);
  FCentrosControl.Invalidate;
end;

procedure TfrmVistaGantt.CargarDependencias;
var
  Q: TADOQuery;
  Links: TArray<TErpLink>;
  I: Integer;
begin
  if (FGanttControl = nil) or (not DMPlanner.IsConnected) or
     (DMPlanner.CurrentProjectId <= 0) then
  begin
    if FGanttControl <> nil then
      FGanttControl.SetLinks(nil);
    Exit;
  end;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT FromNodeId, ToNodeId, TipoLink, PorcentajeDependencia ' +
      'FROM FS_PL_Dependency ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa AND ProjectId = :ProjectId';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('ProjectId').Value := DMPlanner.CurrentProjectId;
    Q.Open;
    SetLength(Links, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      Links[I].FromNodeId := Q.FieldByName('FromNodeId').AsInteger;
      Links[I].ToNodeId := Q.FieldByName('ToNodeId').AsInteger;
      Links[I].LinkType := TLinkType(Q.FieldByName('TipoLink').AsInteger);
      Links[I].PorcentajeDependencia := Q.FieldByName('PorcentajeDependencia').AsFloat;
      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  FGanttControl.SetLinks(Links);
end;

procedure TfrmVistaGantt.CargarMarcadores;
var
  Q: TADOQuery;
  M: TGanttMarker;
begin
  if (FGanttControl = nil) or (not DMPlanner.IsConnected) or
     (DMPlanner.CurrentProjectId <= 0) then
  begin
    if FGanttControl <> nil then
      FGanttControl.ClearMarkers;
    Exit;
  end;

  FGanttControl.ClearMarkers;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT MarkerId, FechaHora, ISNULL(Caption, '''') AS Caption, ' +
      '  ISNULL(Color, 0) AS Color, Estilo, GrosorLinea, ' +
      '  Movible, Visible, Tag, ' +
      '  ISNULL(FontName, '''') AS FontName, ISNULL(FontSize, 0) AS FontSize, ' +
      '  ISNULL(FontColor, 0) AS FontColor, FontStyle, ' +
      '  OrientacionTexto, AlineacionTexto ' +
      'FROM FS_PL_Marker ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa AND ProjectId = :ProjectId ' +
      '  AND Visible = 1 ' +
      'ORDER BY FechaHora';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('ProjectId').Value := DMPlanner.CurrentProjectId;
    Q.Open;
    while not Q.Eof do
    begin
      FillChar(M, SizeOf(M), 0);
      M.Id := Q.FieldByName('MarkerId').AsInteger;
      M.DateTime := Q.FieldByName('FechaHora').AsDateTime;
      M.Caption := Q.FieldByName('Caption').AsString;
      M.Color := TColor(Q.FieldByName('Color').AsInteger);
      M.Style := TMarkerStyle(Q.FieldByName('Estilo').AsInteger);
      M.StrokeWidth := Q.FieldByName('GrosorLinea').AsFloat;
      if M.StrokeWidth <= 0 then M.StrokeWidth := 1;
      M.Moveable := Q.FieldByName('Movible').AsBoolean;
      M.Visible := Q.FieldByName('Visible').AsBoolean;
      M.Tag := Q.FieldByName('Tag').AsInteger;
      M.FontName := Q.FieldByName('FontName').AsString;
      M.FontSize := Q.FieldByName('FontSize').AsInteger;
      M.FontColor := TColor(Q.FieldByName('FontColor').AsInteger);
      M.TextOrientation := TMarkerTextOrientation(Q.FieldByName('OrientacionTexto').AsInteger);
      M.TextAlign := TMarkerTextAlign(Q.FieldByName('AlineacionTexto').AsInteger);
      FGanttControl.AddMarker(M);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmVistaGantt.IrAFecha(const ADate: TDateTime);
var
  SX: Single;
begin
  if (FTimelineControl = nil) or (FGanttControl = nil) then Exit;
  SX := FTimelineControl.CalcScrollXToCenterDate(ADate);
  FTimelineControl.ScrollX := SX;
  FGanttControl.ScrollX := SX;
end;

procedure TfrmVistaGantt.AplicarCalendariosAGantt;
var
  Centres: TArray<TCentreTreball>;
  I, Dia: Integer;
  SrcCal, DstCal: TCentreCalendar;
  RefDate: TDateTime;
  Periods: TArray<TNonWorkingPeriod>;
begin
  if (DMPlanner.CentresRepo = nil) or (FGanttControl = nil) then Exit;

  Centres := DMPlanner.CentresRepo.GetAll;

  // Tomamos una semana de referencia (lunes=1..domingo=7) y pedimos al
  // calendario de cada centro las franjas de cada día. Esas franjas se copian
  // al calendario interno del Gantt para ese centro.
  // Usamos DayOfTheWeek (Delphi: 1=Dom..7=Sáb) — aquí iteramos valores brutos 1..7
  // tal como los expone uCentreCalendar, que usa DayOfTheWeek internamente.
  for I := 0 to High(Centres) do
  begin
    SrcCal := DMPlanner.CentresRepo.GetCalendarFor(Centres[I].Id);
    if SrcCal = nil then Continue;

    DstCal := FGanttControl.GetCalendar(Centres[I].Id);
    if DstCal = nil then Continue;

    DstCal.Name := SrcCal.Name;

    // Recorremos 7 días consecutivos a partir de un lunes conocido
    // (01/01/2024 fue lunes). Así cubrimos los 7 posibles valores del día.
    RefDate := EncodeDate(2024, 1, 1);
    for Dia := 0 to 6 do
    begin
      Periods := SrcCal.NonWorkingPeriodsForDate(RefDate + Dia);
      // SetDayNonWorkingPeriods espera el mismo índice que DayOfTheWeek
      DstCal.SetDayNonWorkingPeriods(
        DayOfTheWeek(RefDate + Dia), Periods);
    end;
  end;

  FGanttControl.Invalidate;
end;

procedure TfrmVistaGantt.pnlGanttContainerResize(Sender: TObject);
begin
  // TODO (paso siguiente): copiar lógica de Main.pnlGanttContainerResize
end;

procedure TfrmVistaGantt.TimelineViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
begin
  if FUpdatingViewport then Exit;
  FUpdatingViewport := True;
  try
    if Assigned(FGanttControl) then
      FGanttControl.SetViewport(StartTime, PxPerMinute, ScrollX);
  finally
    FUpdatingViewport := False;
  end;
end;

procedure TfrmVistaGantt.TimelineInteraction(Sender: TObject;
  const Interacting: Boolean);
begin
  if Assigned(FGanttControl) then
    FGanttControl.TimelineInteraction(Sender, Interacting);
end;

procedure TfrmVistaGantt.GanttViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
begin
  if FUpdatingViewport then Exit;
  if not Assigned(FTimelineControl) then Exit;
  FUpdatingViewport := True;
  try
    FTimelineControl.SetViewport(StartTime, PxPerMinute, ScrollX);
  finally
    FUpdatingViewport := False;
  end;
end;

procedure TfrmVistaGantt.GanttScrollYChanged(Sender: TObject;
  const ScrollY: Single);
begin
  if Assigned(FCentrosControl) then
    FCentrosControl.ScrollY := ScrollY;
end;

procedure TfrmVistaGantt.GanttStatsChanged(Sender: TObject);
begin
  // KPIs: pendiente cuando migremos el cálculo
end;

procedure TfrmVistaGantt.GanttLayoutChanged(Sender: TObject);
begin
  if Assigned(FCentrosControl) and Assigned(FGanttControl) then
  begin
    FCentrosControl.SetRows(FGanttControl.GetRowsCopy);
    FCentrosControl.Invalidate;
  end;
end;

procedure TfrmVistaGantt.GanttNodeSelected(Sender: TObject);
begin
  // TODO (paso siguiente)
end;

procedure TfrmVistaGantt.GanttVoidClick(Sender: TObject);
begin
  // TODO (paso siguiente)
end;

procedure TfrmVistaGantt.GanttNodeDblClick(Sender: TObject;
  const NodeIndex: Integer);
begin
  // TODO (paso siguiente)
end;

procedure TfrmVistaGantt.GanttMarkerDblClick(Sender: TObject;
  const MarkerId: Integer);
begin
  // TODO (paso siguiente)
end;

procedure TfrmVistaGantt.CentresScrollYChanged(Sender: TObject;
  const ScrollY: Single);
begin
  if Assigned(FGanttControl) then
    FGanttControl.ApplyScrollYFromCentres(ScrollY);
end;

end.
