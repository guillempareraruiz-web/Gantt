unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uGanttControl, uGanttTypes, DateUtils,
  Vcl.ExtCtrls, uCentreCalendar, Math, Vcl.StdCtrls, uGanttHelpers, uGanttTimeline,
  uGanttCentres, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, dxSkinsCore, dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint,
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
  dxSkinXmas2008Blue, cxTextEdit, cxMaskEdit, cxSpinEdit, Vcl.ComCtrls, dxCore,
  cxDateUtils, cxDropDownEdit, cxCalendar, Vcl.Menus, Vcl.WinXCtrls, uNodeDataRepo,
  System.Generics.Collections, uErpTypes, uColorPalette64LayeredPopup,
  System.Threading,  System.SyncObjs, System.Diagnostics, uNodeInspector, uMarkerEditor, uGestionMarkers,
  cxStyles, cxFilter, dxScrollbarAnnotations, cxInplaceContainer, cxVGrid,
  uOperariosTypes, uOperariosRepo, uAssignOperaris, uGestionOperaris,
  uMoldeTypes, uMoldeRepo, uGestionMoldes, uSampleDataGenerator, uGestionCalendarios,
  cxCheckComboBox, cxCheckBox, uOperarioFilterPopup, uLinkEditor, uHelpGuide, uCentreInspector,
  cxButtons, dxCoreGraphics, cxButtonEdit, cxScrollBox,
  uCustomFieldDefs, uCustomFieldEditor, uPlanningRules, uPlanningRulesEditor, uDashBoard, uVistaGantt;

type

  TProcRef = reference to procedure;


  TPhaseTimer = record
    Name: string;
    Ms: Double;
  end;

  TNodeKPIItem = record
    CentreId: Integer;
    StartTime: TDateTime;
    EndTime: TDateTime;
    OperariosAsignados: Integer;
    DurationMin: Double;
  end;

  TCentreKPIWork = record
    CentreId: Integer;
    Calendar: TCentreCalendar;
    Items: TArray<TNodeKPIItem>;
  end;
  TCentreKPIResult = record
    CentreId: Integer;
    KPI: TCentreKPI;
  end;

  TWorkInterval = record
    StartTime: TDateTime;
    EndTime: TDateTime;
  end;

  TForm1 = class(TForm)
    popNode: TPopupMenu;
    MenuItem3: TMenuItem;
    Info1: TMenuItem;
    Resetduracinoriginal1: TMenuItem;
    N1: TMenuItem;
    Color1: TMenuItem;
    Colordelnode1: TMenuItem;
    ColordelaOrdendetrabajo1: TMenuItem;
    ColordelaOrdendeFabricacin1: TMenuItem;
    ColordelPedido1: TMenuItem;
    ColordelProyecto1: TMenuItem;
    ShiftRow2: TMenuItem;
    LibreMovimiento1: TMenuItem;
    CompactarOFapartirdelNodo1: TMenuItem;
    CompactarOF1: TMenuItem;
    odalaOF1: TMenuItem;
    odalaOF2: TMenuItem;
    ApartirdelNodoconprioridad1: TMenuItem;
    CompactarOT1: TMenuItem;
    otalaOT1: TMenuItem;
    odalaOTconprioridad1: TMenuItem;
    ApartirdelNodo1: TMenuItem;
    ApartirdelNodoconprioridad2: TMenuItem;tmr1Sec: TTimer;
    ResaltarOF1: TMenuItem;
    MainMenu1: TMainMenu;
    Archivo1: TMenuItem;
    Dashboard1: TMenuItem;
    N4: TMenuItem;
    Proyectos1: TMenuItem;
    ConfigEmpresa1: TMenuItem;
    SelectorErp1: TMenuItem;
    AsistenteInstalacion1: TMenuItem;
    GenerarNodosDemo1: TMenuItem;
    Salir1: TMenuItem;
    N3: TMenuItem;
    Entidades1: TMenuItem;
    Operarios1: TMenuItem;
    Centros1: TMenuItem;
    Calendarios1: TMenuItem;
    Areas1: TMenuItem;
    Departamentos1: TMenuItem;
    Capacitaciones1: TMenuItem;
    Turnos1: TMenuItem;
    Moldes1: TMenuItem;
    Utillajes1: TMenuItem;
    Links1: TMenuItem;
    N10: TMenuItem;
    CamposPersonalizados1: TMenuItem;
    ReglasPlanificacion1: TMenuItem;
    Vistas1: TMenuItem;
    Kanban1: TMenuItem;
    DispatchList1: TMenuItem;
    Backlog1: TMenuItem;
    GenerarBacklogDemo1: TMenuItem;
    FiniteCapacity1: TMenuItem;
    CuadroPlanificacionDia1: TMenuItem;
    Configuracion1: TMenuItem;
    Roles1: TMenuItem;
    Usuarios1: TMenuItem;
    NDemo1: TMenuItem;
    InstalarDemos1: TMenuItem;
    Ayuda1: TMenuItem;
    Acercade1: TMenuItem;
    MnGantt: TMenuItem;
    pnlOldGantt: TPanel;
    pnlCentros: TPanel;
    Panel2: TPanel;
    Shape1: TShape;
    Shape2: TShape;
    pnlGanttContainer: TPanel;
    pnlToolbar: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
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
    btnUndo: TButton;
    btnRedo: TButton;
    Button12: TButton;
    Button13: TButton;
    FcxFilterOperarios: TcxCheckComboBox;
    FchkSoloFiltrados: TcxCheckBox;
    Button26: TButton;
    Button24: TButton;
    N2: TMenuItem;
    Indicadoresdecentros1: TMenuItem;

    procedure Roles1Click(Sender: TObject);
    procedure Usuarios1Click(Sender: TObject);
    procedure InstalarDemos1Click(Sender: TObject);
    procedure Proyectos1Click(Sender: TObject);
    procedure ConfigEmpresa1Click(Sender: TObject);
    procedure SelectorErp1Click(Sender: TObject);
    procedure AsistenteInstalacion1Click(Sender: TObject);
    procedure GenerarNodosDemo1Click(Sender: TObject);
    procedure Dashboard1Click(Sender: TObject);
    procedure Areas1Click(Sender: TObject);
    procedure Departamentos1Click(Sender: TObject);
    procedure Capacitaciones1Click(Sender: TObject);
    procedure MostrarDashboard;
    procedure OcultarDashboard;
    procedure DashboardAbrirGantt(Sender: TObject);
    procedure MostrarVistaGantt;
    procedure FormCreate(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure SearchBox1InvokeSearch(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Info1Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Resetduracinoriginal1Click(Sender: TObject);
    procedure Colordelnode1Click(Sender: TObject);
    procedure ShiftRow2Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnUndoClick(Sender: TObject);
    procedure btnRedoClick(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure LibreMovimiento1Click(Sender: TObject);
    procedure odalaOF1Click(Sender: TObject);
    procedure otalaOT1Click(Sender: TObject);
    procedure tmr1SecTimer(Sender: TObject);
    procedure FchkSoloFiltradosPropertiesChange(Sender: TObject);
    procedure FcxFilterOperariosPropertiesChange(Sender: TObject);
    procedure Button24Click(Sender: TObject);
    procedure ResaltarOF1Click(Sender: TObject);
    procedure Moldes1Click(Sender: TObject);
    procedure Calendarios1Click(Sender: TObject);
    procedure Turnos1Click(Sender: TObject);
    procedure Operarios1Click(Sender: TObject);
    procedure Centros1Click(Sender: TObject);
    procedure CamposPersonalizados1Click(Sender: TObject);
    procedure ReglasPlanificacion1Click(Sender: TObject);
    procedure Kanban1Click(Sender: TObject);
    procedure DispatchList1Click(Sender: TObject);
    procedure Backlog1Click(Sender: TObject);
    procedure GenerarBacklogDemo1Click(Sender: TObject);
    procedure FiniteCapacity1Click(Sender: TObject);
    procedure CuadroPlanificacionDia1Click(Sender: TObject);
    procedure Salir1Click(Sender: TObject);
    procedure Button26Click(Sender: TObject);
    procedure MnGanttClick(Sender: TObject);
    procedure Indicadoresdecentros1Click(Sender: TObject);
  private
    { Private declarations }

    FCustomFieldDefs: TCustomFieldDefs;
    FPlanningRuleEngine: TPlanningRuleEngine;
    FUpdatingViewport: Boolean;
    FFilterPopup: TfrmOperarioFilterPopup;
    FBtnFilterOperarios: TButton;

    FKPIDebounceTimer : TTimer;
    FTurnos: TArray<TTurno>;


    FCentreKPIs: TDictionary<Integer, TCentreKPI>;
    FCentreKPIRanges: TCentresKPIRanges;


    procedure KPIDebounceTimerFired(Sender: TObject);


    function WorkingMinutesBetweenFallback(
      const Cal: TCentreCalendar;
      const AStart, AEnd: TDateTime
    ): Double;

    function CalcCentreKPI(
      const ACentreId: Integer;
      const ANodes: TArray<TNodeKPIItem>;
      const ACalendar: TCentreCalendar;
      const AStartVisibleTime: TDateTime;
      const AEndVisibleTime: TDateTime;
      const AEndTimeGantt: TDateTime;
      const bCalcAll: Boolean
    ): TCentreKPI;

    function BuildKPIRanges: TCentresKPIRanges;
    function GetCentreKPIValue(const CentreId: Integer): TCentreKPI;

    procedure RebuildCentreKPIs(const bCalcAll: Boolean);
    procedure RebuildCentreKPIs_Parallel(const bCalcAll: Boolean);

    procedure LogPerf(const S: string);

    function CalcCentreKPI_FastPrecomputed(
                  const ANodes: TArray<TNodeKPIItem>;
                  const ACalendar: TCentreCalendar;
                  const AWindowStart: TDateTime;
                  const AWindowEnd: TDateTime
                ): TCentreKPI;

    procedure UpdateViewportInfo;

    procedure UpdateHistoryButtons;

    procedure TimelineViewportChanged(Sender: TObject; const StartTime: TDateTime;
      const PxPerMinute, ScrollX: Single);
    procedure TimelineInteraction(Sender: TObject; const Interacting: Boolean);

    procedure GanttViewportChanged(Sender: TObject;
      const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);

    procedure RebuildCentresRowsAndRefresh;
    procedure CentresReordered(Sender: TObject; const NewOrderCentreIds: TArray<Integer>);

    procedure AfterLayoutRebuilt;
    procedure GanttVerticalScrolled(const ScrollY: Single);
    procedure CentresScrollYChanged(Sender: TObject; const ScrollY: Single);
    procedure GanttScrollYChanged(Sender: TObject; const ScrollY: Single);
    procedure ConfiguraCalendariCentre(const Gantt: TGanttControl; const CentreId: Integer);

    function BuildNodeKPIItemsFromGanttNodes: TArray<TNodeKPIItem>;

    procedure AssignarOperarisClick(Sender: TObject);
    procedure GestionOperarisClick(Sender: TObject);
    procedure EditarLinksClick(Sender: TObject);

    // Filtro operarios
    procedure BtnFilterOperariosClick(Sender: TObject);
    procedure FilterPopupChanged(Sender: TObject; const SelectedIds: TArray<Integer>);
    procedure RefreshOperarioFilterItems;
    procedure ApplyOperarioFilter;

  public
    { Public declarations }
    procedure GoToDate(const ADate: TDateTime);

  end;

var
  Form1: TForm1;
  FGantt: TGanttControl;
  FTimeline: TGanttTimelineControl;
  FCentrosControl: TGanttCentresControl;
  FNodeRepo: TNodeDataRepo;
  FOperariosRepo: TOperariosRepo;
  FMoldeRepo: TMoldeRepo;
  FCentresRows: TArray<TCentreTreball>;
  FRaw: TErpRaw;
  FSampleData: TSampleData;
  FDashboard: TfrmDashboard;
  FVistaGantt: TfrmVistaGantt;

    Label19: TLabel;

implementation

uses uErpSampleBuilder, uGestionCentres, uKanbanBoard, uDispatchList, uBacklog,
  uDemoBacklog,
  uFiniteCapacityPlanner, uCuadroPlanificacionDelDia, uGestionTurnos,
  uDMPlanner, uGestionRoles, uGestionUsuarios, uLogin, uGestionDemos,
  uGestionProyectos, uGestionAreas, uGestionDepartamentos, uGestionCapacitaciones,
  uConfigEmpresa, uGenerarNodosDemo, uCentresKPI, uErpSelector, uInstallWizard;

{$R *.dfm}


function MinutesOverlapWithIntervals(
  const AStartTime, AEndTime: TDateTime;
  const AIntervals: TArray<TWorkInterval>
): Double;
var
  I: Integer;
  S, E: TDateTime;
begin
  Result := 0;

  if AEndTime <= AStartTime then
    Exit;

  for I := 0 to High(AIntervals) do
  begin
    if AIntervals[I].EndTime <= AStartTime then
      Continue;

    if AIntervals[I].StartTime >= AEndTime then
      Break;

    S := Max(AStartTime, AIntervals[I].StartTime);
    E := Min(AEndTime, AIntervals[I].EndTime);

    if E > S then
      Result := Result + ((E - S) * 24 * 60);
  end;
end;


function TotalMinutesOfIntervals(const AIntervals: TArray<TWorkInterval>): Double;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(AIntervals) do
    Result := Result + ((AIntervals[I].EndTime - AIntervals[I].StartTime) * 24 * 60);
end;



function MeasurePhaseMs(const AProc: TProc): Double;
var
  SW: TStopwatch;
begin
  SW := TStopwatch.StartNew;
  AProc();
  SW.Stop;
  Result := SW.Elapsed.TotalMilliseconds;
end;


procedure TForm1.LibreMovimiento1Click(Sender: TObject);
var
  idx: Integer;
  n: TNode;
  d: TNodeData;
begin
  idx := FGantt.SelectedNodeIndex;
  if idx < 0 then Exit;

  n := FGantt.SelectedNode;

  if FNodeRepo.TryGetById(n.DataId, D) then
  begin
    D.LibreMoviment := LibreMovimiento1.Checked;
    FNodeRepo.AddOrUpdate(D);
  end;

end;

procedure TForm1.LogPerf(const S: string);
begin
  OutputDebugString(PChar(S));
  //Memo1.Lines.Add(S);
end;


procedure TForm1.btnRedoClick(Sender: TObject);
begin
  if not Assigned(FGantt) then
   Exit;

  FGantt.RedoLastAction;
  UpdateHistoryButtons;
end;

procedure TForm1.btnRefreshClick(Sender: TObject);
begin
  if Assigned(FGantt) then
  begin
    FGantt.RebuildLayout;
    FGantt.Invalidate;
  end;
end;


procedure TForm1.btnUndoClick(Sender: TObject);
begin
  if not Assigned(FGantt) then
   Exit;

  FGantt.UndoLastAction;
  UpdateHistoryButtons;
end;

procedure TForm1.TimelineViewportChanged(Sender: TObject; const StartTime: TDateTime;
  const PxPerMinute, ScrollX: Single);
begin
  if FUpdatingViewport then Exit;
   FUpdatingViewport := True;

  try
    if Assigned(FGantt) then
     FGantt.SetViewport(StartTime, PxPerMinute, ScrollX);

    UpdateViewportInfo;

    if Assigned(FCentrosControl) and FCentrosControl.VerIndicadores then
    begin
      FKPIDebounceTimer.Enabled := False;
      FKPIDebounceTimer.Enabled := True;
    end;


  finally
    FUpdatingViewport := False;
  end;
end;

procedure TForm1.TimelineInteraction(Sender: TObject; const Interacting: Boolean);
begin
  if Assigned(FGantt) then
    FGantt.TimelineInteraction(Sender, Interacting);
end;

procedure TForm1.tmr1SecTimer(Sender: TObject);
begin
 //UpdateViewportInfo;
end;

procedure TForm1.UpdateViewportInfo;
var
  S: string;
begin
  {
  if Assigned(FTimeline) and Assigned(FGantt) then
  begin
    S :=
      DateTimeToStr(FTimeline.StartTime) + ' - ' + DateTimeToStr(FTimeline.EndTime) +
      ' (' + DateTimeToStr(FTimeline.StartVisibleTime) + ' - ' + DateTimeToStr(FTimeline.EndVisibleTime) + ')' +
      ' (' + DateTimeToStr(FGantt.StartVisibleTime) + ' - ' + DateTimeToStr(FGantt.EndVisibleTime) + ')';
    if LblTiempos.Caption <> S then
      LblTiempos.Caption := S;
  end;
  }
end;

procedure TForm1.Button12Click(Sender: TObject);
begin
  UpdateHistoryButtons;
end;

procedure TForm1.Button13Click(Sender: TObject);
begin

  if Assigned(FGantt) then
   FGantt.HideWeekends := not FGantt.HideWeekends;

  //if Assigned(FTimeline) then
  // FTimeline.HideWeekends := not FTimeline.HideWeekends;

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  GoToDate( Now );
end;

procedure TForm1.Button24Click(Sender: TObject);
var ms1, ms2: Int64; moved1, moved2: Integer;
begin
  if not Assigned(FGantt) then
   Exit;

  Screen.Cursor := crHourGlass;

  FGantt.ReplanAllFromDateV2(Now, 0, ms2, moved2);

  Button24.Caption := Format('%d ms', [moved2, ms2]);

  {
  FGantt.ReplanAllFromDate(Now, 0, ms1, moved1);
  Screen.Cursor := crHourGlass;

  FGantt.ReplanAllFromDateV2(Now, 0, ms2, moved2);

  Button24.Caption := Format('V1: %d mov %d ms | V2: %d mov %d ms',
    [moved1, ms1, moved2, ms2]);
    }
end;

procedure TForm1.Button26Click(Sender: TObject);
begin

  DMPlanner.ADOConnection.Close;
  try
    DMPlanner.ADOConnection.Open();

    // Carregar planning
    //DMPlanner.Connector.LoadPlanning(1, Data);

    // Guardar
    //DMPlanner.Connector.SavePlanning(Data);
  finally

  end;

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if Assigned(FGantt) then
   FGantt.ClearSearch;

end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if Assigned(FGantt) then
  begin
    FGantt.SearchPrev(True);

  end;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  if Assigned(FGantt) then
  begin
   FGantt.SearchNext(True);
  end;

end;

procedure TForm1.Button6Click(Sender: TObject);
var

  CTNames : TArray<string>;
  Nodes: TArray<TNode>;
  cal: TCentreCalendar;
  p: TArray<TNonWorkingPeriod>;
  T0, T1: TDateTime;
  NextId, i: Integer;
  iCentros: Integer;

begin

  if Assigned(FTimeline) then
  begin
    Freeandnil(FTimeline);
    Freeandnil(FGantt);
    Freeandnil(FCentrosControl);
  end;

  Screen.Cursor := crHourGlass;


  FTimeline := TGanttTimelineControl.Create(Self);
  FTimeline.Parent := pnlGanttContainer;
  FTimeline.Top := pnlToolbar.top+10;
  FTimeline.Align := alTop;
  FTimeline.LeftWidth := 0;


  // popTimeline;

  FGantt := TGanttControl.Create(Self);
  FGantt.Parent := pnlGanttContainer;
  FGantt.Top := FTimeline.top+10;
  FGantt.Align := alClient;
  FGantt.NodePopupMenu := popNode;
  FGantt.ShowHint := True;

  //Self.FGantt.PopupMenu := popGantt;
  //(TControl(FGantt)).PopupMenu := popGantt;
  //TCustomControl(FGantt)
  //FGantt.PopupMenu := pmGantt; // menú general del gantt (buit)

  FCentrosControl := TGanttCentresControl.Create(Self);
  FCentrosControl.Parent := pnlCentros;
  FCentrosControl.Top := 0;
  FCentrosControl.Align := alLeft;


  pnlCentros.Width := FCentrosControl.BaseWidth;
  FCentrosControl.VerIndicadores := False;

  // connexió robusta
  FTimeline.OnViewportChanged := TimelineViewportChanged;
  FTimeline.OnInteraction := TimelineInteraction;

  FGantt.OnViewportChanged := GanttViewportChanged;
  FGantt.OnScrollYChanged := GanttScrollYChanged;

  FCentrosControl.OnScrollYChanged := CentresScrollYChanged;

  FKPIDebounceTimer := TTimer.Create(Self);
  FKPIDebounceTimer.Enabled := False;
  FKPIDebounceTimer.Interval := 300;
  FKPIDebounceTimer.OnTimer := KPIDebounceTimerFired;


  // Rang
  //T0 := dtFechaInicioGantt.Date; //EncodeDateTime(2026, 2, 19, 0, 0, 0, 0);
  //T1 := dtFechaFinGantt.Date; //IncDay(T0, 2);
  //T1 := dtFechaFinGantt.Date + EncodeTime(23,59,59,999);

  T0 := DayStart(dtFechaInicioGantt.Date-2);
  T1 := DayEnd(dtFechaFinGantt.Date);
  if T1 < T0 then
   T1 := DayEnd(T0);

  FTimeline.SetTimeRange(T0, T1);

  // Generar datos de ejemplo (centros, operarios, moldes, calendarios, etc.)
  iCentros := spCentros.EditValue;

  // Limpiar repos para regenerar
  FOperariosRepo.Free;
  FMoldeRepo.Free;
  FOperariosRepo := TOperariosRepo.Create;
  FMoldeRepo := TMoldeRepo.Create;
  GenerateSampleData(FOperariosRepo, FMoldeRepo, iCentros, FSampleData);

  // Generar turnos de ejemplo
  GenerateSampleTurnos(FTurnos);

  // Copiar centros generados
  FCentresRows := Copy(FSampleData.Centros);
  SetLength(CTNames, iCentros);

  FCentrosControl.GetCentreName :=
  function(const CentreId: Integer): string
  var
    k: Integer;
  begin
    Result := '';
    for k := 0 to High(FCentresRows) do
      if FCentresRows[k].Id = CentreId then
        Exit(FCentresRows[k].Titulo);
  end;

  // Aplicar calendarios a cada centro
  ApplyCalendariosToGantt(FSampleData,
    function(const CentreId: Integer): TCentreCalendar
    begin
      Result := FGantt.GetCalendar(CentreId);
    end);

  SetLength(Nodes, 0);
  NextId := 1000;

  for i := 0 to iCentros-1 do
    CTNames[i] := FCentresRows[i].Titulo;


  FRaw := BuildRawSample(
    T0, T1,
    CTNames,
    cxSpinEdit2.EditValue,   // NumOFs
    3,    // MaxOTPerOF
    8,    // MaxOPPerOT
    0.15, // ProbSinCentro
    0.25, // ProbExtraLinks
    15, 480,  // durada min..max (minuts)
    5, 30     // gap min..max (minuts)
  );

  if FNodeRepo = nil then
   FNodeRepo := TNodeDataRepo.Create;


  BuildGanttFromRawNew2(FRaw, FNodeRepo,
  function(const CentreId: Integer): TCentreCalendar
  begin
    Result := FGantt.GetCalendar(CentreId);
  end,
  FCentresRows, Nodes);

  for i := 0 to iCentros-1 do
  begin
    FCentresRows[i].MaxLaneCount := 0;
    case i of
    0: FCentresRows[i].BkColor := TColor($005252FF);
    1: FCentresRows[i].BkColor := TColor($002828DC);
    2: FCentresRows[i].BkColor := TColor($00FFE6CC);
    else
      FCentresRows[i].BkColor := TColor($003366CC);
    end;
  end;


  FTimeline.SetTimeRange(T0, T1);

  FGantt.SetNodeRepo(FNodeRepo);
  FGantt.SetTimeRange(T0, T1);

  FGantt.SetData(FCentresRows, Nodes, T0);

  FGantt.RebuildOpIdIndex;
  FGantt.RebuildNodeLayoutIndex;
  FGantt.SetLinks(FRaw.Links);

  FCentrosControl.SetCentres(FCentresRows);
  FCentrosControl.SetRows(FGantt.GetRowsCopy);

  // Inicialitza timeline amb mateix viewport

  FTimeline.SetViewport(T0, 2.0, 0);
  FGantt.SetViewport(T0, 2.0, 0);


  if Assigned(FCentreKPIs) then
   FreeAndNil(FCentreKPIs);

  FCentreKPIs := TDictionary<Integer, TCentreKPI>.Create;
  FCentrosControl.GetCentreKPI := GetCentreKPIValue;
  FCentrosControl.CurrentKPIRanges := FCentreKPIRanges;


  GoToDate( Now );

  FGantt.RecalcCounters;
  UpdateHistoryButtons;

  RefreshOperarioFilterItems;

  Screen.Cursor := crDefault;

end;




procedure TForm1.RebuildCentresRowsAndRefresh;
var
  rows: TArray<TRowLayout>;
  i: Integer;
  y: Single;
begin
  SetLength(rows, Length(FCentresRows));
  y := 0;
  for i := 0 to High(FCentresRows) do
  begin
    rows[i].CentreId := FCentresRows[i].Id;
    rows[i].Visible  := FCentresRows[i].Visible;
    rows[i].Enabled  := FCentresRows[i].Enabled;
    rows[i].Height   := FCentresRows[i].BaseHeight;   // o la altura que toque
    rows[i].TopY     := y;
    if rows[i].Visible then
      y := y + rows[i].Height;
  end;
  FCentrosControl.SetRows(rows);
  // Si el Gantt usa este orden para dibujar/ordenar filas, refresca también:
  //FGantt.SetCentres(FCentres);  // si tienes algo así
  //FCentres.SetRows(FGantt.GetRowsCopy);
  FGantt.Invalidate;
end;


function TForm1.BuildNodeKPIItemsFromGanttNodes: TArray<TNodeKPIItem>;
var
  I: Integer;
  N: TNode;
  D: TNodeData;
begin
  SetLength(Result, FGantt.NodeCount);

  for I := 0 to FGantt.NodeCount - 1 do
  begin
    N := FGantt.GetNodeAt(I);

    Result[I].CentreId := N.CentreId;
    Result[I].StartTime := N.StartTime;
    Result[I].EndTime := N.EndTime;
    Result[I].DurationMin := N.DurationMin;

    if FNodeRepo.TryGetById(N.DataId, D) then
      Result[I].OperariosAsignados := D.OperariosAsignados
    else
      Result[I].OperariosAsignados := 0;
  end;
end;


function TForm1.WorkingMinutesBetweenFallback(
  const Cal: TCentreCalendar;
  const AStart, AEnd: TDateTime
): Double;
var
  T: TDateTime;
begin
  Result := 0;
  if (Cal = nil) or (AEnd <= AStart) then
    Exit;
  T := AStart;
  while T < AEnd do
  begin
    if not Cal.IsNonWorkingTime(T) then
      Result := Result + 1;
    T := IncMinute(T, 1);
  end;
end;


function TForm1.CalcCentreKPI_FastPrecomputed(
  const ANodes: TArray<TNodeKPIItem>;
  const ACalendar: TCentreCalendar;
  const AWindowStart: TDateTime;
  const AWindowEnd: TDateTime
): TCentreKPI;
var
  I: Integer;
  N: TNodeKPIItem;
  SegStart, SegEnd: TDateTime;
  MinsOcupats: Double;
  MinsDisponibles: Double;
  MinsTotals: Double;
  NonWorking: TArray<TAbsInterval>;
begin
  Result.TotalNodes := 0;
  Result.HoresOcupades := 0;
  Result.HoresDisponibles := 0;
  Result.TotalOperaris := 0;
  Result.PercentOcupacio := 0;

  if ACalendar = nil then
    Exit;

  if AWindowEnd <= AWindowStart then
    Exit;

  NonWorking := ACalendar.BuildMergedNonWorkingIntervalsForWindow(
    AWindowStart, AWindowEnd
  );

  MinsTotals := ACalendar.WorkingMinutesBetweenPrecomputed(
    AWindowStart, AWindowEnd, NonWorking
  );

  MinsOcupats := 0;

  for I := 0 to High(ANodes) do
  begin
    N := ANodes[I];

    if N.EndTime <= AWindowStart then
      Continue;

    if N.StartTime >= AWindowEnd then
     Continue;

    SegStart := Max(N.StartTime, AWindowStart);
    SegEnd   := Min(N.EndTime, AWindowEnd);

    if SegEnd <= SegStart then
      Continue;

    Inc(Result.TotalNodes);
    Inc(Result.TotalOperaris, N.OperariosAsignados);

    MinsOcupats := MinsOcupats +
      ACalendar.WorkingMinutesBetweenPrecomputed(
        SegStart,
        SegEnd,
        NonWorking
      );
  end;

  MinsDisponibles := MinsTotals - MinsOcupats;
  if MinsDisponibles < 0 then
    MinsDisponibles := 0;

  Result.HoresOcupades := MinsOcupats / 60.0;
  Result.HoresDisponibles := MinsDisponibles / 60.0;

  if MinsTotals > 0 then
    Result.PercentOcupacio := (MinsOcupats / MinsTotals) * 100.0
  else
    Result.PercentOcupacio := 0;
end;



function TForm1.CalcCentreKPI(
  const ACentreId: Integer;
  const ANodes: TArray<TNodeKPIItem>;
  const ACalendar: TCentreCalendar;
  const AStartVisibleTime: TDateTime;
  const AEndVisibleTime: TDateTime;
  const AEndTimeGantt: TDateTime;
  const bCalcAll: Boolean
): TCentreKPI;
var
  I: Integer;
  N: TNodeKPIItem;
  WindowStart, WindowEnd: TDateTime;
  SegStart, SegEnd: TDateTime;
  MinsOcupats: Double;
  MinsDisponibles: Double;
  MinsTotals: Double;
begin
  Result.TotalNodes := 0;
  Result.HoresOcupades := 0;
  Result.HoresDisponibles := 0;
  Result.TotalOperaris := 0;
  Result.PercentOcupacio := 0;

  if ACalendar = nil then
    Exit;

  if bCalcAll then
  begin
    WindowStart := Now;
    WindowEnd := AEndTimeGantt;
  end
  else
  begin
    WindowStart := AStartVisibleTime;
    WindowEnd := AEndVisibleTime;
  end;

  if WindowEnd <= WindowStart then
    Exit;

  MinsOcupats := 0;

  for I := 0 to High(ANodes) do
  begin
    N := ANodes[I];

    if N.CentreId <> ACentreId then
      Continue;

    if N.EndTime <= WindowStart then
      Continue;

    if N.StartTime >= WindowEnd then
      Continue;

    SegStart := Max(N.StartTime, WindowStart);
    SegEnd := Min(N.EndTime, WindowEnd);

    if SegEnd <= SegStart then
      Continue;

    Inc(Result.TotalNodes);
    Inc(Result.TotalOperaris, N.OperariosAsignados);

    MinsOcupats := MinsOcupats +
      WorkingMinutesBetweenFallback(ACalendar, SegStart, SegEnd);
  end;

  MinsTotals := WorkingMinutesBetweenFallback(ACalendar, WindowStart, WindowEnd);
  MinsDisponibles := MinsTotals - MinsOcupats;

  if MinsDisponibles < 0 then
    MinsDisponibles := 0;

  Result.HoresOcupades := MinsOcupats / 60.0;
  Result.HoresDisponibles := MinsDisponibles / 60.0;

  if MinsTotals > 0 then
    Result.PercentOcupacio := (MinsOcupats / MinsTotals) * 100.0
  else
    Result.PercentOcupacio := 0;
end;



function TForm1.BuildKPIRanges: TCentresKPIRanges;
var
  I: Integer;
  K: TCentreKPI;
begin
  Result.Nodes.MinInt := MaxInt;
  Result.Nodes.MaxInt := -MaxInt;
  Result.Nodes.MinFloat := 0;
  Result.Nodes.MaxFloat := 0;

  Result.Ocupades.MinInt := 0;
  Result.Ocupades.MaxInt := 0;
  Result.Ocupades.MinFloat := 1.0E100;
  Result.Ocupades.MaxFloat := -1.0E100;

  Result.Disponibles.MinInt := 0;
  Result.Disponibles.MaxInt := 0;
  Result.Disponibles.MinFloat := 1.0E100;
  Result.Disponibles.MaxFloat := -1.0E100;

  Result.Operaris.MinInt := MaxInt;
  Result.Operaris.MaxInt := -MaxInt;
  Result.Operaris.MinFloat := 0;
  Result.Operaris.MaxFloat := 0;

  Result.PercentOcupacio.MinInt := 0;
  Result.PercentOcupacio.MaxInt := 0;
  Result.PercentOcupacio.MinFloat := 1.0E100;
  Result.PercentOcupacio.MaxFloat := -1.0E100;

  if Length(FCentresRows) = 0 then
  begin
    Result.Nodes.MinInt := 0; Result.Nodes.MaxInt := 0;
    Result.Ocupades.MinFloat := 0; Result.Ocupades.MaxFloat := 0;
    Result.Disponibles.MinFloat := 0; Result.Disponibles.MaxFloat := 0;
    Result.Operaris.MinInt := 0; Result.Operaris.MaxInt := 0;
    Result.PercentOcupacio.MinFloat := 0; Result.PercentOcupacio.MaxFloat := 0;
    Exit;
  end;

  for I := 0 to High(FCentresRows) do
  begin
    if not FCentreKPIs.TryGetValue(FCentresRows[I].Id, K) then
      Continue;

    Result.Nodes.MinInt := Min(Result.Nodes.MinInt, K.TotalNodes);
    Result.Nodes.MaxInt := Max(Result.Nodes.MaxInt, K.TotalNodes);

    Result.Ocupades.MinFloat := Min(Result.Ocupades.MinFloat, K.HoresOcupades);
    Result.Ocupades.MaxFloat := Max(Result.Ocupades.MaxFloat, K.HoresOcupades);

    Result.Disponibles.MinFloat := Min(Result.Disponibles.MinFloat, K.HoresDisponibles);
    Result.Disponibles.MaxFloat := Max(Result.Disponibles.MaxFloat, K.HoresDisponibles);

    Result.Operaris.MinInt := Min(Result.Operaris.MinInt, K.TotalOperaris);
    Result.Operaris.MaxInt := Max(Result.Operaris.MaxInt, K.TotalOperaris);

    Result.PercentOcupacio.MinFloat := Min(Result.PercentOcupacio.MinFloat, K.PercentOcupacio);
    Result.PercentOcupacio.MaxFloat := Max(Result.PercentOcupacio.MaxFloat, K.PercentOcupacio);
  end;

  if Result.Nodes.MinInt = MaxInt then
  begin
    Result.Nodes.MinInt := 0; Result.Nodes.MaxInt := 0;
    Result.Ocupades.MinFloat := 0; Result.Ocupades.MaxFloat := 0;
    Result.Disponibles.MinFloat := 0; Result.Disponibles.MaxFloat := 0;
    Result.Operaris.MinInt := 0; Result.Operaris.MaxInt := 0;
    Result.PercentOcupacio.MinFloat := 0; Result.PercentOcupacio.MaxFloat := 0;
  end;
end;

function TForm1.GetCentreKPIValue(const CentreId: Integer): TCentreKPI;
begin
  if not FCentreKPIs.TryGetValue(CentreId, Result) then
  begin
    Result.TotalNodes := 0;
    Result.HoresOcupades := 0;
    Result.HoresDisponibles := 0;
    Result.TotalOperaris := 0;
    Result.PercentOcupacio := 0;
  end;
end;



procedure TForm1.RebuildCentreKPIs_Parallel(const bCalcAll: Boolean);
var
  KPIItems: TArray<TNodeKPIItem>;
  WorkItems: TArray<TCentreKPIWork>;
  Results: TArray<TCentreKPIResult>;
  TmpMap: TObjectDictionary<Integer, TList<TNodeKPIItem>>;
  Lst: TList<TNodeKPIItem>;
  I: Integer;
  CentreId: Integer;
  Item: TNodeKPIItem;
  KPIWindowStart, KPIWindowEnd: TDateTime;
  NowRef: TDateTime;
begin
  if not Assigned(FGantt) then
    Exit;

  if not FCentrosControl.VerIndicadores then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    KPIItems := BuildNodeKPIItemsFromGanttNodes;

    NowRef := Now;
    if bCalcAll then
    begin
      KPIWindowStart := NowRef;
      KPIWindowEnd   := FGantt.EndTime;
    end
    else
    begin
      KPIWindowStart := FGantt.StartVisibleTime;
      KPIWindowEnd   := FGantt.EndVisibleTime;
    end;

    TmpMap := TObjectDictionary<Integer, TList<TNodeKPIItem>>.Create([doOwnsValues]);
    try
      SetLength(WorkItems, Length(FCentresRows));

      for I := 0 to High(FCentresRows) do
      begin
        CentreId := FCentresRows[I].Id;

        WorkItems[I].CentreId := CentreId;
        WorkItems[I].Calendar := FGantt.GetCalendar(CentreId);
        SetLength(WorkItems[I].Items, 0);

        TmpMap.AddOrSetValue(CentreId, TList<TNodeKPIItem>.Create);
      end;

      for I := 0 to High(KPIItems) do
      begin
        Item := KPIItems[I];
        if TmpMap.TryGetValue(Item.CentreId, Lst) then
          Lst.Add(Item);
      end;

      for I := 0 to High(WorkItems) do
      begin
        if TmpMap.TryGetValue(WorkItems[I].CentreId, Lst) then
          WorkItems[I].Items := Lst.ToArray;
      end;

      SetLength(Results, Length(WorkItems));

      TParallel.For(0, High(WorkItems),
        procedure(Index: Integer)
        begin
          Results[Index].CentreId := WorkItems[Index].CentreId;
          Results[Index].KPI := CalcCentreKPI_FastPrecomputed(
            WorkItems[Index].Items,
            WorkItems[Index].Calendar,
            KPIWindowStart,
            KPIWindowEnd
          );
        end
      );

      FCentreKPIs.Clear;
      for I := 0 to High(Results) do
        FCentreKPIs.AddOrSetValue(Results[I].CentreId, Results[I].KPI);

    finally
      TmpMap.Free;
    end;

    FCentreKPIRanges := BuildKPIRanges;
    FCentrosControl.GetCentreKPI := GetCentreKPIValue;
    FCentrosControl.CurrentKPIRanges := FCentreKPIRanges;
    FCentrosControl.Invalidate;

  finally
    Screen.Cursor := crDefault;
  end;
end;



procedure TForm1.RebuildCentreKPIs(const bCalcAll: Boolean);
var
  KPIItems: TArray<TNodeKPIItem>;
  I: Integer;
  Cal: TCentreCalendar;
  K: TCentreKPI;
begin

  Screen.Cursor := crHourGlass;

  KPIItems := BuildNodeKPIItemsFromGanttNodes;

  FCentreKPIs.Clear;

  for I := 0 to High(FCentresRows) do
  begin
    Cal := FGantt.GetCalendar( FCentresRows[I].Id );

    K := CalcCentreKPI(
      FCentresRows[I].Id,
      KPIItems,
      Cal,
      FGantt.StartVisibleTime,
      FGantt.EndVisibleTime,
      FGantt.EndTime,
      bCalcAll
    );

    FCentreKPIs.AddOrSetValue(FCentresRows[I].Id, K);
  end;

  FCentreKPIRanges := BuildKPIRanges;

  FCentrosControl.GetCentreKPI := GetCentreKPIValue;
  FCentrosControl.CurrentKPIRanges := FCentreKPIRanges;
  FCentrosControl.Invalidate;

  Screen.Cursor := crDefault;

end;


procedure TForm1.ResaltarOF1Click(Sender: TObject);
var
  idx: Integer;
  node: TNode;
begin
  idx := FGantt.SelectedNodeIndex;
  if idx < 0 then Exit;
  FGantt.HighlightOF(idx);
end;

procedure TForm1.Resetduracinoriginal1Click(Sender: TObject);
begin
  FGantt.ResetNodeDuration(FGantt.SelectedNodeIndex);
end;

procedure TForm1.CentresReordered(Sender: TObject; const NewOrderCentreIds: TArray<Integer>);
var
  Old: TArray<TCentreTreball>;
  NewArr: TArray<TCentreTreball>;
  i, j: Integer;
begin
  Old := FCentresRows;
  SetLength(NewArr, Length(NewOrderCentreIds));
  // Reconstruimos Centres siguiendo el orden de IDs recibido
  for i := 0 to High(NewOrderCentreIds) do
  begin
    // buscar el centre con ese Id en Old
    for j := 0 to High(Old) do
      if Old[j].Id = NewOrderCentreIds[i] then
      begin
        NewArr[i] := Old[j];
        Break;
      end;
    // Nuevo Order (0..N-1)
    NewArr[i].Order := i;
  end;
  FCentresRows := NewArr;
  // Vuelve a construir filas y repinta
  RebuildCentresRowsAndRefresh;
  if Assigned(FGantt) then
  begin
    FGantt.RebuildLayout;
    FGantt.Invalidate;
  end;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  if cxDateEdit1.EditValue<>null then
   GoToDate( cxDateEdit1.Date );
end;

procedure TForm1.Button8Click(Sender: TObject);
var
 iTag: Integer;
begin


  if Assigned(FTimeline) then
  begin
   iTag := TButton(Sender).Tag;
   case iTag of
   1: FTimeline.SetView(tvHours, 3); // 3 hores visibles
   2: FTimeline.SetView(tvDay);
   3: FTimeline.SetView(tvWeek);
   4: FTimeline.SetView(tvMonth);
   end;
  end;
end;

procedure TForm1.GanttScrollYChanged(Sender: TObject; const ScrollY: Single);
begin
  FCentrosControl.ScrollY := ScrollY;
end;


procedure TForm1.AfterLayoutRebuilt;
begin
  if Assigned(FCentrosControl) then
   FCentrosControl.SetRows(FGantt.GetRowsCopy); // cal un getter al Gantt
end;
procedure TForm1.GanttVerticalScrolled(const ScrollY: Single);
begin
  if Assigned(FCentrosControl) then
   FCentrosControl.ScrollY := ScrollY;
end;
procedure TForm1.CentresScrollYChanged(Sender: TObject; const ScrollY: Single);
begin
  if Assigned(FGantt) then
   FGantt.ApplyScrollYFromCentres(ScrollY);
end;

procedure TForm1.Centros1Click(Sender: TObject);
var
  Frm: TfrmGestionCentres;
begin
  Frm := TfrmGestionCentres.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  DMPlanner.LoadCentres;
end;

procedure TForm1.Kanban1Click(Sender: TObject);
var
  Frm: TForm;
  Kanban: TKanbanBoard;
begin
  Frm := TForm.Create(nil);
  try
    Frm.Caption := 'Vista Kanban';
    Frm.Width := 1000;
    Frm.Height := 700;
    Frm.Position := poScreenCenter;
    Frm.Color := $00F5F5F5;

    Kanban := TKanbanBoard.Create(Frm);
    Kanban.Parent := Frm;
    Kanban.Align := alClient;
    Kanban.SetNodeRepo(FNodeRepo);

    // Callback para obtener tiempos teóricos del nodo Gantt
    Kanban.SetGetNodeTimes(
      function(const DataId: Integer; out AStart, AEnd: TDateTime): Boolean
      var
        Nodes: TArray<TNode>;
        J: Integer;
      begin
        Result := False;
        AStart := 0;
        AEnd := 0;
        if not Assigned(FGantt) then Exit;
        Nodes := FGantt.GetNodes;
        for J := 0 to High(Nodes) do
          if Nodes[J].DataId = DataId then
          begin
            AStart := Nodes[J].StartTime;
            AEnd := Nodes[J].EndTime;
            Exit(True);
          end;
      end
    );

    Frm.ShowModal;

    // Tras cerrar el Kanban, refrescar Gantt por si hubo cambios de estado
    if Assigned(FGantt) then
      FGantt.Invalidate;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.DispatchList1Click(Sender: TObject);
begin
  TDispatchListForm.Execute(
    FNodeRepo,
    FCentresRows,
    function(const DataId: Integer; out AStart, AEnd: TDateTime): Boolean
    var
      Nodes: TArray<TNode>;
      J: Integer;
    begin
      Result := False;
      AStart := 0;
      AEnd := 0;
      if not Assigned(FGantt) then Exit;
      Nodes := FGantt.GetNodes;
      for J := 0 to High(Nodes) do
        if Nodes[J].DataId = DataId then
        begin
          AStart := Nodes[J].StartTime;
          AEnd := Nodes[J].EndTime;
          Exit(True);
        end;
    end
  );
end;

procedure TForm1.Backlog1Click(Sender: TObject);
begin
  uBacklog.ShowBacklog;
  if FVistaGantt <> nil then
    FVistaGantt.Inicializar(dtFechaInicioGantt.Date, dtFechaFinGantt.Date);
end;

procedure TForm1.GenerarBacklogDemo1Click(Sender: TObject);
begin
  try
    uDemoBacklog.GenerarBacklogDemo;
  except
    on E: Exception do
      ShowMessage('Error generando Backlog demo: ' + E.Message);
  end;
end;

procedure TForm1.FiniteCapacity1Click(Sender: TObject);
var
  Assignments: TArray<TFCPAssignment>;
begin
  if not Assigned(FNodeRepo) then
  begin
    ShowMessage('Repositorio de nodos no inicializado.');
    Exit;
  end;
  if not Assigned(FOperariosRepo) then
  begin
    ShowMessage('Repositorio de operarios no inicializado.');
    Exit;
  end;
  if DMPlanner.CurrentProjectId <= 0 then
  begin
    ShowMessage('No hay ningún proyecto activo.');
    Exit;
  end;

  if TfrmFiniteCapacityPlanner.Execute(
    FNodeRepo,
    FOperariosRepo,
    Assignments,
    FPlanningRuleEngine,
    FCustomFieldDefs
  ) then
  begin
    // TODO: aplicar asignaciones al Gantt
  end;

  // Refrescar Gantt por si hubo cambios
  if Assigned(FGantt) then
    FGantt.Invalidate;
end;

procedure TForm1.CuadroPlanificacionDia1Click(Sender: TObject);
begin
  TfrmCuadroPlanificacionDelDia.Execute(
    FNodeRepo,
    FCentresRows,
    function(const DataId: Integer; out AStart, AEnd: TDateTime): Boolean
    var
      Nodes: TArray<TNode>;
      J: Integer;
    begin
      Result := False;
      AStart := 0;
      AEnd := 0;
      if not Assigned(FGantt) then Exit;
      Nodes := FGantt.GetNodes;
      for J := 0 to High(Nodes) do
        if Nodes[J].DataId = DataId then
        begin
          AStart := Nodes[J].StartTime;
          AEnd := Nodes[J].EndTime;
          Exit(True);
        end;
    end,
    function(const CentreId: Integer): TCentreCalendar
    begin
      Result := FGantt.GetCalendar(CentreId);
    end,
    FTurnos);
end;

procedure TForm1.KPIDebounceTimerFired(Sender: TObject);
begin
  FKPIDebounceTimer.Enabled := False;
  RebuildCentreKPIs_Parallel(False);
end;

procedure TForm1.GanttViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
begin




  if not Assigned(FTimeline) then
   Exit;

  if FUpdatingViewport then Exit;
   FUpdatingViewport := True;



  try
    FTimeline.SetViewport(StartTime, PxPerMinute, ScrollX);

    UpdateViewportInfo;

    if Assigned(FCentrosControl) and FCentrosControl.VerIndicadores then
    begin
      FKPIDebounceTimer.Enabled := False;
      FKPIDebounceTimer.Enabled := True;
    end;

  finally
    FUpdatingViewport := False;
  end;
end;



procedure TForm1.Indicadoresdecentros1Click(Sender: TObject);
begin

 TfrmCentresKPI.Execute(
    Self,
    DMPlanner.CentresRepo.GetAll,
    FVistaGantt.FGanttControl,
    FVistaGantt.FNodeRepo,
    FVistaGantt.FOperariosRepo,
    0);

end;

procedure TForm1.Info1Click(Sender: TObject);
var
  idx: Integer;
  node: TNode;
  AnodeData: TNodeData;
begin
  idx := FGantt.SelectedNodeIndex;
  if idx < 0 then Exit;

  node := FGantt.SelectedNode;

  if FNodeRepo.TryGetById(node.DataId, AnodeData) then
  begin
    ShowMessage( 'OF: ' + inttostr(AnodeData.NumeroOrdenFabricacion) + chr(13) + chr(10) +
                 'Articulo: ' + AnodeData.CodigoArticulo + chr(13) + chr(10) +
                 'FechaEntrega: ' + datetostr( AnodeData.FechaEntrega ) );
  end;

end;

procedure TForm1.MenuItem3Click(Sender: TObject);
var
  idx: Integer;
  node: TNode;
begin
  idx := FGantt.SelectedNodeIndex;
  if idx < 0 then Exit;
  node := FGantt.SelectedNode;
  node.Enabled := not node.Enabled;
  FGantt.UpdateNode(idx, node);

end;

procedure TForm1.MnGanttClick(Sender: TObject);
begin
  OcultarDashboard;
  MostrarVistaGantt;
end;

procedure TForm1.Moldes1Click(Sender: TObject);
var
  Frm: TfrmGestionMoldes;
begin
  Frm := TfrmGestionMoldes.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.CamposPersonalizados1Click(Sender: TObject);
begin
  if TfrmCustomFieldEditor.Execute(FCustomFieldDefs) then
    FCustomFieldDefs.SaveToFile;
end;

procedure TForm1.ReglasPlanificacion1Click(Sender: TObject);
begin
  if TfrmPlanningRulesEditor.Execute(FPlanningRuleEngine) then
    FPlanningRuleEngine.SaveToFile;
end;

procedure TForm1.Calendarios1Click(Sender: TObject);
begin
  TfrmGestionCalendarios.Execute(YearOf(Now));
  DMPlanner.LoadCalendars;
end;

procedure TForm1.Turnos1Click(Sender: TObject);
begin
  TfrmGestionTurnos.Execute;
end;

procedure TForm1.odalaOF1Click(Sender: TObject);
var
  idx: Integer;
  iAllOF, iPrioridad: Integer;
begin

  idx := FGantt.SelectedNodeIndex;
  if idx < 0 then Exit;

  iAllOF := TMenuItem(Sender).Tag;
  iPrioridad := TMenuItem(Sender).HelpContext;

  FGantt.CompactOFFromNode( idx, 0, (iAllOF=1) , (iPrioridad=1) );

end;

procedure TForm1.Operarios1Click(Sender: TObject);
var
  Frm: TfrmGestionOperaris;
begin
  Frm := TfrmGestionOperaris.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.Roles1Click(Sender: TObject);
var
  Frm: TfrmGestionRoles;
begin
  if not HasPermission('ADMIN_ROLES') then
  begin
    ShowMessage('No tiene permisos para gestionar roles.');
    Exit;
  end;
  Frm := TfrmGestionRoles.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.Usuarios1Click(Sender: TObject);
var
  Frm: TfrmGestionUsuarios;
begin
  if not HasPermission('ADMIN_USERS') then
  begin
    ShowMessage('No tiene permisos para gestionar usuarios.');
    Exit;
  end;
  Frm := TfrmGestionUsuarios.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.InstalarDemos1Click(Sender: TObject);
var
  Frm: TfrmGestionDemos;
begin
  Frm := TfrmGestionDemos.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.Proyectos1Click(Sender: TObject);
var
  Frm: TfrmGestionProyectos;
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede gestionar proyectos.');
    Exit;
  end;
  Frm := TfrmGestionProyectos.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;

end;

procedure TForm1.otalaOT1Click(Sender: TObject);
var
  idx: Integer;
  iAllOT, iPrioridad: Integer;
begin

  idx := FGantt.SelectedNodeIndex;
  if idx < 0 then Exit;

  iAllOT := TMenuItem(Sender).Tag;
  iPrioridad := TMenuItem(Sender).HelpContext;

  FGantt.CompactOTFromNode( idx, 0, (iAllOT=1) , (iPrioridad=1) );

end;


procedure TForm1.Salir1Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.SearchBox1InvokeSearch(Sender: TObject);
var
  nodes: TArray<Integer>;
  iVal: Integer;
begin
  if not Assigned(FGantt) then
   Exit;

  iVal := 20000 + strtointdef( SearchBox1.Text, 0);

  if radiobutton1.checked then
   nodes := FGantt.FindNodesByOF( iVal, 'A')
  else
   nodes := FGantt.FindNodesByTrabajo('TR-001');


  if Length(nodes) = 0 then
  begin
    FGantt.ClearSearch;
    Exit;
  end;

  FGantt.SetSearchResults(nodes, True);
  FGantt.SelectNodeByIndex(nodes[0], True);

end;

procedure TForm1.ShiftRow2Click(Sender: TObject);
begin
  FGantt.ShiftLeftSequentialCentresFromDate( FGantt.FClickDatetime, 0);
end;

procedure TForm1.Colordelnode1Click(Sender: TObject);
 var
  P: TPoint;
  F: TColorPalette64LayeredPopup;
  iTag: Integer;
  SelIndexes: TArray<Integer>;
begin

  iTag := TMenuItem(Sender).Tag;

  SelIndexes := FGantt.GetSelectedNodeIndexes;
  if Length(SelIndexes) = 0 then Exit;

  P := Mouse.CursorPos; // coordenades de pantalla

  F := TColorPalette64LayeredPopup.Create(Self);
  F.PopupAtScreen(P.X, P.Y,
    procedure(const C: TColor)
    var
      I: Integer;
      node: TNode;
      d: TNodeData;
      iOT, iOF: Integer;
      sOF, sOT: String;
    begin
        for I := 0 to High(SelIndexes) do
        begin
          node := FGantt.GetNodeAt(SelIndexes[I]);

          if (node.DataId = 0) or (not FNodeRepo.TryGetById(node.DataId, d)) then
            Continue;

          sOT := d.NumeroTrabajo;
          iOT := strtointdef(d.NumeroTrabajo,0);
          iOF := d.NumeroOrdenFabricacion;
          sOF := d.SerieFabricacion;

          case iTag of
          0: begin //...assignem color a node
               FGantt.ApplyOpColorsByNode(node.DataId, octOnlyNode, c, AdjustColorBrightness(c, -40));
             end;
          1: begin //...assignem color a node i OT
               FGantt.ApplyOpColorsByNode(node.DataId, octByTrabajo, c, AdjustColorBrightness(c, -40), sOT, sOF, iOF);
             end;
          2: begin //...assignem color a node i OF
               FGantt.ApplyOpColorsByNode(node.DataId, octByFabricacionSerie, c, AdjustColorBrightness(c, -40), '', sOF, iOF);
             end;
          end;
        end;

        FGantt.Invalidate;
    end,
    160, 160);

end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  if Assigned(FGantt) then
  begin
    case ComboBox1.itemindex of
    0:  FGantt.LinksVisible := lvAlways;
    1:  FGantt.LinksVisible := lvSelected;
    2:  FGantt.LinksVisible := lvNever;
    end;

    //FGantt.LinksAllVisible
    //FGantt.RebuildLayout;
    //FGantt.Invalidate;
  end;
end;

procedure TForm1.ConfiguraCalendariCentre(const Gantt: TGanttControl; const CentreId: Integer);
var
  cal: TCentreCalendar;
  p: TArray<TNonWorkingPeriod>;

  function NWP(const AStart, AEnd: TTime): TNonWorkingPeriod;
  begin
    Result.StartTimeOfDay := AStart;
    Result.EndTimeOfDay   := AEnd;
  end;

  procedure SetMonFri(const Arr: array of TNonWorkingPeriod);
  var
    tmp: TArray<TNonWorkingPeriod>;
    i: Integer;
  begin
    SetLength(tmp, Length(Arr));
    for i := 0 to High(Arr) do
      tmp[i] := Arr[i];

    cal.SetDayNonWorkingPeriods(1, tmp);
    cal.SetDayNonWorkingPeriods(2, tmp);
    cal.SetDayNonWorkingPeriods(3, tmp);
    cal.SetDayNonWorkingPeriods(4, tmp);
    cal.SetDayNonWorkingPeriods(5, tmp);
  end;

  procedure SetClosedWeekend;
  begin
    SetLength(p, 1);
    p[0] := NWP(EncodeTime(0,0,0,0), EncodeTime(23,59,59,999));
    cal.SetDayNonWorkingPeriods(6, p);
    cal.SetDayNonWorkingPeriods(7, p);
  end;

begin
  cal := Gantt.GetCalendar(CentreId);


  case CentreId of
    1,6:
      begin
        cal.Name := 'Calendario1';
        SetMonFri([
          NWP(EncodeTime(0,0,0,0),  EncodeTime(6,0,0,0)),
          NWP(EncodeTime(14,0,0,0), EncodeTime(15,0,0,0)),
          NWP(EncodeTime(22,0,0,0), EncodeTime(23,59,59,999))
        ]);
        SetClosedWeekend;
      end;

    2,4:
      begin
        cal.Name := 'Calendario2';
        SetMonFri([
          NWP(EncodeTime(0,0,0,0),  EncodeTime(7,0,0,0)),
          NWP(EncodeTime(15,0,0,0), EncodeTime(23,59,59,999))
        ]);
        SetClosedWeekend;
      end;

    3,5:
      begin
        cal.Name := 'Calendario3';
        SetMonFri([
          NWP(EncodeTime(0,0,0,0),  EncodeTime(15,0,0,0)),
          NWP(EncodeTime(18,30,0,0),EncodeTime(18,45,0,0)),
          NWP(EncodeTime(23,0,0,0), EncodeTime(23,59,59,999))
        ]);
        SetClosedWeekend;
      end;
    7,8:
      begin
        cal.Name := 'Calendario4';
        SetMonFri([
          NWP(EncodeTime(0,0,0,0),  EncodeTime(06,0,0,0)),
          NWP(EncodeTime(13,30,0,0),EncodeTime(15,45,0,0)),
          NWP(EncodeTime(22,0,0,0), EncodeTime(23,59,59,999))
        ]);
        SetClosedWeekend;
      end;
  else
    begin
      cal.Name := 'CalendarioX';
      SetLength(p, 0);
      cal.SetDayNonWorkingPeriods(1, p);
      cal.SetDayNonWorkingPeriods(2, p);
      cal.SetDayNonWorkingPeriods(3, p);
      cal.SetDayNonWorkingPeriods(4, p);
      cal.SetDayNonWorkingPeriods(5, p);
      SetClosedWeekend;
    end;
  end;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  Randomize;
  Width := 1900;
  pnlGanttContainer.Caption := '';
  pnlGanttContainer.Align := alClient;

    pnlCentros.Caption := '';
  cxDateEdit1.Date := Now;


  dtFechaInicioGantt.Date := Trunc( strtodatetime('01/01/2026') );
  dtFechaFinGantt.Date := Trunc( strtodatetime('31/12/2026') ); // IncDay(Now, 30);

  FNodeRepo := TNodeDataRepo.Create;
  FCustomFieldDefs := TCustomFieldDefs.Create;
  FCustomFieldDefs.LoadFromFile(ExtractFilePath(Application.ExeName) + 'custom_fields.json');

  FPlanningRuleEngine := TPlanningRuleEngine.Create(FCustomFieldDefs);
  FPlanningRuleEngine.LoadFromFile(ExtractFilePath(Application.ExeName) + 'planning_rules.json');

  FOperariosRepo := TOperariosRepo.Create;
  FMoldeRepo := TMoldeRepo.Create;

  pnlCentros.Width := 220;

  // Afegir opció "Assignar Operaris" al menú contextual del node
  begin
    var mi: TMenuItem;
    mi := TMenuItem.Create(popNode);
    mi.Caption := '-';
    popNode.Items.Add(mi);

    mi := TMenuItem.Create(popNode);
    mi.Caption := 'Asignar Operarios...';
    mi.OnClick := AssignarOperarisClick;
    popNode.Items.Add(mi);

    mi := TMenuItem.Create(popNode);
    mi.Caption := 'Gesti'#243'n Operarios y Departamentos...';
    mi.OnClick := GestionOperarisClick;
    popNode.Items.Add(mi);

    mi := TMenuItem.Create(popNode);
    mi.Caption := '-';
    popNode.Items.Add(mi);

    mi := TMenuItem.Create(popNode);
    mi.Caption := 'Editar Links (Dependencias)...';
    mi.OnClick := EditarLinksClick;
    popNode.Items.Add(mi);
  end;


  // Popup grid de filtro de operarios
  FFilterPopup := TfrmOperarioFilterPopup.CreatePopup(Self, FOperariosRepo);
  FFilterPopup.OnFilterChanged := FilterPopupChanged;

  // Botón para abrir el popup (al lado del cxCheckComboBox existente)
  FBtnFilterOperarios := TButton.Create(Self);
  FBtnFilterOperarios.Parent := pnlToolbar;
  FBtnFilterOperarios.SetBounds(FcxFilterOperarios.Left + FcxFilterOperarios.Width + 4,
    FcxFilterOperarios.Top, 26, FcxFilterOperarios.Height);
  FBtnFilterOperarios.Caption := '...';
  FBtnFilterOperarios.Font.Style := [fsBold];
  FBtnFilterOperarios.OnClick := BtnFilterOperariosClick;

  MostrarDashboard;
end;

procedure TForm1.MostrarDashboard;
begin
  if FDashboard = nil then
  begin
    FDashboard := TfrmDashboard.Create(Self);
    FDashboard.OnAbrirGantt := DashboardAbrirGantt;
    FDashboard.Parent := Self;
    FDashboard.Align := alClient;
  end;
  FDashboard.Refrescar;
  FDashboard.Visible := True;
  FDashboard.BringToFront;
end;

procedure TForm1.OcultarDashboard;
begin
  if Assigned(FDashboard) then
    FDashboard.Visible := False;
end;

procedure TForm1.DashboardAbrirGantt(Sender: TObject);
begin
  OcultarDashboard;
  MostrarVistaGantt;
end;

procedure TForm1.MostrarVistaGantt;
begin
  if FVistaGantt = nil then
  begin
    FVistaGantt := TfrmVistaGantt.CreateVista(Self,
      FNodeRepo, FOperariosRepo, FMoldeRepo,
      FCustomFieldDefs, FPlanningRuleEngine);
    FVistaGantt.Parent := Self;
    FVistaGantt.Align := alClient;
  end;
  FVistaGantt.Inicializar(dtFechaInicioGantt.Date, dtFechaFinGantt.Date);
  FVistaGantt.Visible := True;
  FVistaGantt.BringToFront;
end;

procedure TForm1.ConfigEmpresa1Click(Sender: TObject);
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede editar la configuración de empresa.');
    Exit;
  end;
  TfrmConfigEmpresa.Execute;
end;

procedure TForm1.SelectorErp1Click(Sender: TObject);
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede cambiar el ERP activo.');
    Exit;
  end;
  TfrmErpSelector.Execute;
end;

procedure TForm1.AsistenteInstalacion1Click(Sender: TObject);
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede ejecutar el asistente de instalaci'#243'n.');
    Exit;
  end;
  TfrmInstallWizard.Execute;
end;

procedure TForm1.GenerarNodosDemo1Click(Sender: TObject);
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede generar nodos demo.');
    Exit;
  end;
  if DMPlanner.CurrentProjectId <= 0 then
  begin
    ShowMessage('Primero active un proyecto.');
    Exit;
  end;
  TfrmGenerarNodosDemo.Execute;
end;

procedure TForm1.Dashboard1Click(Sender: TObject);
begin
  if FDashboard <> nil then
   if FDashboard.Visible then
   begin
    FDashboard.Visible := False;
    Exit;
   end;


  MostrarDashboard;
end;

procedure TForm1.Areas1Click(Sender: TObject);
var
  Frm: TfrmGestionAreas;
begin
  Frm := TfrmGestionAreas.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.Departamentos1Click(Sender: TObject);
var
  Frm: TfrmGestionDepartamentos;
begin
  Frm := TfrmGestionDepartamentos.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.Capacitaciones1Click(Sender: TObject);
var
  Frm: TfrmGestionCapacitaciones;
begin
  Frm := TfrmGestionCapacitaciones.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.EditarLinksClick(Sender: TObject);
var
  idx: Integer;
  node: TNode;
  D: TNodeData;
  AllLinks: TArray<TErpLink>;
  LinkIdxs: TArray<Integer>;
  Items: TArray<TLinkEditItem>;
  I, J: Integer;
  OtherNode: TNode;
  OtherData: TNodeData;
  LResult: TLinkEditorResult;
  OtherIdx: Integer;
begin
  idx := FGantt.SelectedNodeIndex;
  if idx < 0 then Exit;

  node := FGantt.SelectedNode;
  if not FNodeRepo.TryGetById(node.DataId, D) then Exit;

  AllLinks := FGantt.GetLinks;
  LinkIdxs := FGantt.GetLinksForNode(node.Id);

  // Construir items per l'editor
  SetLength(Items, Length(LinkIdxs));
  for I := 0 to High(LinkIdxs) do
  begin
    J := LinkIdxs[I];
    Items[I].LinkIndex := J;
    Items[I].FromNodeId := AllLinks[J].FromNodeId;
    Items[I].ToNodeId := AllLinks[J].ToNodeId;
    Items[I].LinkType := AllLinks[J].LinkType;
    Items[I].PorcentajeDependencia := AllLinks[J].PorcentajeDependencia;
    Items[I].Deleted := False;

    // Resolucionar noms
    if AllLinks[J].FromNodeId = node.Id then
    begin
      Items[I].FromCaption := D.Operacion;
      OtherIdx := FGantt.FindNodeIndexById(AllLinks[J].ToNodeId);
      if (OtherIdx >= 0) then
      begin
        OtherNode := FGantt.GetNodeAt(OtherIdx);
        if FNodeRepo.TryGetById(OtherNode.DataId, OtherData) then
          Items[I].ToCaption := OtherData.Operacion + ' (OF ' + IntToStr(OtherData.NumeroOrdenFabricacion) + ')'
        else
          Items[I].ToCaption := 'Node ' + IntToStr(AllLinks[J].ToNodeId);
      end
      else
        Items[I].ToCaption := 'Node ' + IntToStr(AllLinks[J].ToNodeId);
    end
    else
    begin
      Items[I].ToCaption := D.Operacion;
      OtherIdx := FGantt.FindNodeIndexById(AllLinks[J].FromNodeId);
      if (OtherIdx >= 0) then
      begin
        OtherNode := FGantt.GetNodeAt(OtherIdx);
        if FNodeRepo.TryGetById(OtherNode.DataId, OtherData) then
          Items[I].FromCaption := OtherData.Operacion + ' (OF ' + IntToStr(OtherData.NumeroOrdenFabricacion) + ')'
        else
          Items[I].FromCaption := 'Node ' + IntToStr(AllLinks[J].FromNodeId);
      end
      else
        Items[I].FromCaption := 'Node ' + IntToStr(AllLinks[J].FromNodeId);
    end;
  end;

  if TfrmLinkEditor.Execute(node.Id,
    D.Operacion + ' (OF ' + IntToStr(D.NumeroOrdenFabricacion) + ')',
    Items, LResult) then
  begin
    // Reconstruir array de links complet
    var NewLinks: TArray<TErpLink>;
    var EditedSet: TDictionary<Integer, Integer>; // LinkIndex -> index dins LResult.Items
    var DeletedSet: TDictionary<Integer, Boolean>;
    EditedSet := TDictionary<Integer, Integer>.Create;
    DeletedSet := TDictionary<Integer, Boolean>.Create;
    try
      for I := 0 to High(LResult.Items) do
      begin
        J := LResult.Items[I].LinkIndex;
        if J < 0 then Continue;
        if LResult.Items[I].Deleted then
          DeletedSet.AddOrSetValue(J, True)
        else
          EditedSet.AddOrSetValue(J, I);
      end;

      SetLength(NewLinks, 0);
      for I := 0 to High(AllLinks) do
      begin
        if DeletedSet.ContainsKey(I) then
          Continue; // eliminat

        var L: TErpLink;
        L := AllLinks[I];
        if EditedSet.ContainsKey(I) then
          L.PorcentajeDependencia := LResult.Items[EditedSet[I]].PorcentajeDependencia;

        SetLength(NewLinks, Length(NewLinks) + 1);
        NewLinks[High(NewLinks)] := L;
      end;

      FGantt.SetLinks(NewLinks);

      // Forçar recàlcul: per cada link editat, moure el successor
      // a la posició mínima que marca el nou percentatge
      var K: Integer;
      var MovedNodes: TIdxArray;
      for K := 0 to High(NewLinks) do
      begin
        // Links on aquest node és predecessor (sortida)
        if NewLinks[K].FromNodeId = node.Id then
        begin
          var SuccNodeIdx: Integer;
          SuccNodeIdx := FGantt.FindNodeIndexById(NewLinks[K].ToNodeId);
          if SuccNodeIdx >= 0 then
          begin
            var MinStart: TDateTime;
            MinStart := FGantt.GetDependencyMinStart(idx, NewLinks[K].PorcentajeDependencia);
            FGantt.MoveNodeKeepingDuration(SuccNodeIdx, MinStart);
            FGantt.ResolveDependenciesFromNode(SuccNodeIdx, MovedNodes);
          end;
        end;
        // Links on aquest node és successor (entrada)
        if NewLinks[K].ToNodeId = node.Id then
        begin
          var PredNodeIdx: Integer;
          PredNodeIdx := FGantt.FindNodeIndexById(NewLinks[K].FromNodeId);
          if PredNodeIdx >= 0 then
          begin
            var MinStart: TDateTime;
            MinStart := FGantt.GetDependencyMinStart(PredNodeIdx, NewLinks[K].PorcentajeDependencia);
            FGantt.MoveNodeKeepingDuration(idx, MinStart);
            FGantt.ResolveDependenciesFromNode(idx, MovedNodes);
          end;
        end;
      end;
      FGantt.RebuildLayout;
    finally
      EditedSet.Free;
      DeletedSet.Free;
    end;
  end;
end;

procedure TForm1.GestionOperarisClick(Sender: TObject);
var
  Frm: TfrmGestionOperaris;
begin
  Frm := TfrmGestionOperaris.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  RefreshOperarioFilterItems;
end;


procedure TForm1.RefreshOperarioFilterItems;
var
  Ops: TArray<TOperario>;
  I: Integer;
  SelIds: TArray<Integer>;
begin
  // Guardar selección del popup antes de recargar
  SelIds := FFilterPopup.GetSelectedIds;

  // Recargar cxCheckComboBox
  FcxFilterOperarios.Properties.Items.Clear;
  Ops := FOperariosRepo.GetOperarios;
  for I := 0 to High(Ops) do
    FcxFilterOperarios.Properties.Items.AddCheckItem(Ops[I].Nombre);

  // Recrear popup con datos actualizados
  FFilterPopup.Free;
  FFilterPopup := TfrmOperarioFilterPopup.CreatePopup(Self, FOperariosRepo);
  FFilterPopup.OnFilterChanged := FilterPopupChanged;
  FFilterPopup.SetSelectedIds(SelIds);
end;

procedure TForm1.BtnFilterOperariosClick(Sender: TObject);
var
  Pt: TPoint;
begin
  Pt := FBtnFilterOperarios.ClientToScreen(Point(0, FBtnFilterOperarios.Height));
  FFilterPopup.ShowAt(Pt.X, Pt.Y);
end;

procedure TForm1.FilterPopupChanged(Sender: TObject; const SelectedIds: TArray<Integer>);
begin
  ApplyOperarioFilter;
end;

procedure TForm1.FchkSoloFiltradosPropertiesChange(Sender: TObject);
begin
 ApplyOperarioFilter;
end;

procedure TForm1.FcxFilterOperariosPropertiesChange(Sender: TObject);
begin
  ApplyOperarioFilter;
end;


procedure TForm1.ApplyOperarioFilter;
var
  Ops: TArray<TOperario>;
  I, J: Integer;
  SelOperarioIds: TArray<Integer>;
  PopupIds: TArray<Integer>;
  Asigs: TArray<TAsignacionOperario>;
  DataIdSet: TDictionary<Integer, Byte>;
  IdSet: TDictionary<Integer, Byte>;
  DataIds: TArray<Integer>;
  AnyChecked: Boolean;
begin
  Ops := FOperariosRepo.GetOperarios;
  IdSet := TDictionary<Integer, Byte>.Create;
  try
    // Fuente 1: cxCheckComboBox
    for I := 0 to FcxFilterOperarios.Properties.Items.Count - 1 do
      if FcxFilterOperarios.States[I] = cbsChecked then
        if I <= High(Ops) then
          IdSet.AddOrSetValue(Ops[I].Id, 1);

    // Fuente 2: Popup grid
    PopupIds := FFilterPopup.GetSelectedIds;
    for I := 0 to High(PopupIds) do
      IdSet.AddOrSetValue(PopupIds[I], 1);

    AnyChecked := IdSet.Count > 0;
    if not AnyChecked then
    begin
      FGantt.ClearOperarioFilter;
      Exit;
    end;

    // IDs seleccionados
    SetLength(SelOperarioIds, IdSet.Count);
    I := 0;
    for J in IdSet.Keys do
    begin
      SelOperarioIds[I] := J;
      Inc(I);
    end;
  finally
    IdSet.Free;
  end;

  // Recoger DataIds de los nodos asignados a esos operarios
  DataIdSet := TDictionary<Integer, Byte>.Create;
  try
    for I := 0 to High(SelOperarioIds) do
    begin
      Asigs := FOperariosRepo.GetAsignacionsByOperario(SelOperarioIds[I]);
      for J := 0 to High(Asigs) do
        DataIdSet.AddOrSetValue(Asigs[J].DataId, 1);
    end;

    SetLength(DataIds, DataIdSet.Count);
    I := 0;
    for J in DataIdSet.Keys do
    begin
      DataIds[I] := J;
      Inc(I);
    end;
  finally
    DataIdSet.Free;
  end;

  FGantt.SetOperarioFilter(DataIds, FchkSoloFiltrados.Checked);
end;

procedure TForm1.AssignarOperarisClick(Sender: TObject);
var
  SelIndexes: TArray<Integer>;
  I: Integer;
  node: TNode;
  D: TNodeData;
  AssignCount: Integer;
  DataIds: TArray<Integer>;
  Operaciones: TArray<string>;
  TotalDur: Double;
  TotalNec: Integer;
begin
  SelIndexes := FGantt.GetSelectedNodeIndexes;
  if Length(SelIndexes) = 0 then Exit;

  // Modo single
  if Length(SelIndexes) = 1 then
  begin
    node := FGantt.GetNodeAt(SelIndexes[0]);
    if not FNodeRepo.TryGetById(node.DataId, D) then Exit;

    if TfrmAssignOperaris.Execute(
      FOperariosRepo, D.DataId, D.Operacion,
      D.DurationMin, D.OperariosNecesarios, AssignCount) then
    begin
      D.OperariosAsignados := AssignCount;
      FNodeRepo.AddOrUpdate(D);
      FGantt.Invalidate;
    end;
    Exit;
  end;

  // Modo multi: recoger DataIds, sumar duraciones y necesarios
  SetLength(DataIds, 0);
  SetLength(Operaciones, 0);
  TotalDur := 0;
  TotalNec := 0;
  for I := 0 to High(SelIndexes) do
  begin
    if (SelIndexes[I] < 0) or (SelIndexes[I] > FGantt.NodeCount - 1) then
      Continue;
    node := FGantt.GetNodeAt(SelIndexes[I]);
    if not FNodeRepo.TryGetById(node.DataId, D) then Continue;

    SetLength(DataIds, Length(DataIds) + 1);
    DataIds[High(DataIds)] := D.DataId;
    SetLength(Operaciones, Length(Operaciones) + 1);
    Operaciones[High(Operaciones)] := D.Operacion;
    TotalDur := TotalDur + D.DurationMin;
    TotalNec := TotalNec + D.OperariosNecesarios;
  end;

  if Length(DataIds) = 0 then Exit;

  if TfrmAssignOperaris.ExecuteMulti(
    FOperariosRepo, DataIds, Operaciones, TotalDur, TotalNec) then
  begin
    // Actualizar OperariosAsignados de cada nodo
    for I := 0 to High(DataIds) do
    begin
      if FNodeRepo.TryGetById(DataIds[I], D) then
      begin
        D.OperariosAsignados := FOperariosRepo.CountAssignatsAlNode(DataIds[I]);
        FNodeRepo.AddOrUpdate(D);
      end;
    end;
    FGantt.Invalidate;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FNodeRepo.Free;
  FPlanningRuleEngine.Free;
  FCustomFieldDefs.Free;
  FOperariosRepo.Free;
  FMoldeRepo.Free;

  if Assigned(FCentreKPIs) then
   FreeAndNil(FCentreKPIs);

end;


procedure TForm1.UpdateHistoryButtons;
begin
  btnUndo.Enabled := FGantt.CanUndo;
  btnRedo.Enabled := FGantt.CanRedo;
  lblUndoCount.Caption := IntToStr(FGantt.UndoCount);
  lblRedoCount.Caption := IntToStr(FGantt.RedoCount);
end;


procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

  if NOT assigned(FGantt) then
   Exit;

  if Key = VK_F1 then
  begin
    TfrmHelpGuide.Execute;
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = Ord('Z')) then
  begin
    FGantt.UndoLastAction;
    UpdateHistoryButtons;
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = Ord('Y')) then
  begin
    FGantt.RedoLastAction;
    UpdateHistoryButtons;
    Key := 0;
  end;
end;

procedure TForm1.GoToDate(const ADate: TDateTime);
var
  sx: Single;
begin
  if (not Assigned(FTimeline)) or (not assigned(FGantt)) then
   Exit;
  sx := FTimeline.CalcScrollXToCenterDate(ADate);
  FTimeline.ScrollX := sx; // via setter (recomanat)
  FGantt.ScrollX := sx;    // via setter (recomanat)
end;

end.
