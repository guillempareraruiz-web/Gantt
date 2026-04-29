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
  uGanttControl, uGanttControlGrupo, uGanttTimeline, uGanttCentres, uGanttTypes, uErpTypes,
  System.Generics.Collections, System.Threading, System.Math;
type
  // Items agregados de nodos usados para calculo de KPIs por centro.
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

  TfrmVistaGantt = class(TForm)
    pnlRoot: TPanel;
    Panel1: TPanel;
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
    N3: TMenuItem;
    Indicadores1: TMenuItem;
    Label28: TLabel;
    Label29: TLabel;
    Panel12: TPanel;
    Label30: TLabel;
    Label31: TLabel;
    Panel13: TPanel;
    Label32: TLabel;
    Label33: TLabel;
    Panel14: TPanel;
    Label34: TLabel;
    Label35: TLabel;
    Panel15: TPanel;
    Label36: TLabel;
    Label37: TLabel;
    Label8: TLabel;
    cbVistas: TcxComboBox;
    btnFocus: TButton;
    btnGanttDates: TcxButton;
    cxButton9: TcxButton;
    Label38: TLabel;
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
    procedure GanttFechaBloqueoChanged(Sender: TObject);
    procedure GuardarFechaBloqueo(const ADate: TDateTime);
    procedure GanttNodeDblClick(Sender: TObject; const NodeIndex: Integer);
    procedure GanttMarkerDblClick(Sender: TObject; const MarkerId: Integer);
    procedure CentresScrollYChanged(Sender: TObject; const ScrollY: Single);
    procedure Button27Click(Sender: TObject);

    procedure Button14Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure Desactivarfechabloqueo1Click(Sender: TObject);
    procedure Calendario1Click(Sender: TObject);
    procedure Aadirmarcador1Click(Sender: TObject);
    procedure Gestionmarcadores1Click(Sender: TObject);
    procedure Marcadoresautomaticos1Click(Sender: TObject);
    procedure ShiftRow1Click(Sender: TObject);
    procedure ShiftRowallimpact1Click(Sender: TObject);
    procedure INFO3Click(Sender: TObject);
    procedure Button15Click(Sender: TObject);
    procedure chkShowKPIsClick(Sender: TObject);
    procedure Indicadores1Click(Sender: TObject);
    procedure Button20Click(Sender: TObject);
    procedure Button16Click(Sender: TObject);
    procedure Button17Click(Sender: TObject);
    procedure Button19Click(Sender: TObject);
    procedure Button18Click(Sender: TObject);
    procedure lblModifiedClick(Sender: TObject);
    procedure btnResaltarOFClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button23Click(Sender: TObject);
    procedure Button21Click(Sender: TObject);
    procedure Button22Click(Sender: TObject);
    procedure cbVistasPropertiesChange(Sender: TObject);
    procedure cxButton9Click(Sender: TObject);
    procedure btnGanttDatesClick(Sender: TObject);
  private

    FCustomFieldDefs: TCustomFieldDefs;
    FPlanningRuleEngine: TPlanningRuleEngine;

    FUpdatingViewport: Boolean;
    FCentreKPIs: TDictionary<Integer, TCentreKPI>;
    FCentreKPIRanges: TCentresKPIRanges;

    procedure UpdateKPIs;

    function BuildNodeKPIItemsFromGanttNodes: TArray<TNodeKPIItem>;
    function CalcCentreKPI_FastPrecomputed(
      const ANodes: TArray<TNodeKPIItem>;
      const ACalendar: TCentreCalendar;
      const AWindowStart, AWindowEnd: TDateTime): TCentreKPI;
    function BuildKPIRanges: TCentresKPIRanges;
    function GetCentreKPIValue(const CentreId: Integer): TCentreKPI;
  public
    FGanttControl: TGanttControl;
    FTimelineControl: TGanttTimelineControl;
    FCentrosControl: TGanttCentresControl;
    FNodeRepo: TNodeDataRepo;
    FOperariosRepo: TOperariosRepo;
    FMoldeRepo: TMoldeRepo;

    constructor CreateVista(AOwner: TComponent;
      ANodeRepo: TNodeDataRepo;
      AOperariosRepo: TOperariosRepo;
      AMoldeRepo: TMoldeRepo;
      ACustomFieldDefs: TCustomFieldDefs;
      APlanningRuleEngine: TPlanningRuleEngine);
    destructor Destroy; override;
    procedure RebuildCentreKPIs_Parallel(const bCalcAll: Boolean);
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
  uDMPlanner, Vcl.Dialogs, Data.Win.ADODB, Data.DB,
  uGestionMarkers, uCentreInspector, uSampleDataGenerator,
  uCentresKPI, uGestionCentres, uNodeInspector, uMarkerEditor,
  uGanttDatesDialog, Main;



constructor TfrmVistaGantt.CreateVista(AOwner: TComponent;
  ANodeRepo: TNodeDataRepo;
  AOperariosRepo: TOperariosRepo;
  AMoldeRepo: TMoldeRepo;
  ACustomFieldDefs: TCustomFieldDefs;
  APlanningRuleEngine: TPlanningRuleEngine);
begin
  inherited Create(AOwner);
  FCentreKPIs := TDictionary<Integer, TCentreKPI>.Create;
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
  // Instanciar el control segun el RowMode del proyecto activo.
  // TGanttControlGrupo hereda de TGanttControl (fase 6.2 decision Z) asi que
  // el resto del uVistaGantt trabaja con FGanttControl: TGanttControl sin saber
  // que tipo concreto es.
  if SameText(Trim(DMPlanner.CurrentProjectRowMode), 'GRUPO') then
  begin
    FGanttControl := TGanttControlGrupo.Create(Self);
    TGanttControlGrupo(FGanttControl).NivelAgrupacion :=
      DMPlanner.CurrentProjectNivelAgrupacion;
  end
  else
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
  FGanttControl.OnFechaBloqueoChanged := GanttFechaBloqueoChanged;
  FCentrosControl.OnScrollYChanged := CentresScrollYChanged;
end;


procedure TfrmVistaGantt.cxButton9Click(Sender: TObject);
begin
  Form1.Proyectos1Click(Self);
end;

procedure TfrmVistaGantt.btnGanttDatesClick(Sender: TObject);
var
  FIni, FFin, T0, T1: TDateTime;
  I, NodosFuera: Integer;
  N: TNode;
begin
  FIni := dtFechaInicioGantt.Date;
  FFin := dtFechaFinGantt.Date;
  if not TfrmGanttDatesDialog.Execute(FIni, FFin) then Exit;

  T0 := DayStart(FIni - 2);
  T1 := DayEnd(FFin);
  NodosFuera := 0;
  if Assigned(FGanttControl) then
    for I := 0 to FGanttControl.NodeCount - 1 do
    begin
      N := FGanttControl.GetNodeAt(I);
      if (N.StartTime < T0) or (N.EndTime > T1) then
        Inc(NodosFuera);
    end;

  if NodosFuera > 0 then
    if MessageDlg(
         Format('Hay %d nodo(s) fuera del rango seleccionado.' + sLineBreak +
                '¿Desea continuar igualmente?', [NodosFuera]),
         mtWarning, [mbYes, mbNo], 0) <> mrYes then
      Exit;

  dtFechaInicioGantt.Date := FIni;
  dtFechaFinGantt.Date := FFin;
  Inicializar(FIni, FFin);
end;

procedure TfrmVistaGantt.Desactivarfechabloqueo1Click(Sender: TObject);
begin

  FGanttControl.FechaBloqueo := 0;

end;

procedure TfrmVistaGantt.FormCreate(Sender: TObject);
var
  Modo: string;
begin
  btnFocus.Left := -300;

  Panel1.Height := pnlTitulo.Height + pnlSubTitulo.Height;

  cbVistas.properties.onchange := nil;
  cbVistas.ItemIndex := 0;
  cbVistas.properties.onchange := cbVistasPropertiesChange;

  // Modo de agrupacion (RowMode) del proyecto activo. Solo 'CENTROS' esta
  // operativo. 'GRUPO' y 'TREE' requieren sus propios controles (fase 6.2 / 6.3)
  // y aqui simplemente avisamos al usuario para que lo cambie en Gestion de
  // Proyectos si lo habia configurado antes de tener las vistas implementadas.
  Modo := UpperCase(Trim(DMPlanner.CurrentProjectRowMode));
  if Modo = 'TREE' then
    ShowMessage(
      'El proyecto activo tiene modo de vista "TREE", que aun no ' +
      'esta disponible.' + sLineBreak +
      'Se mostrara la vista estandar por Centros.' + sLineBreak + sLineBreak +
      'Cambia el modo en Gestion de Proyectos cuando la vista TREE ' +
      'este operativa.');
end;


procedure TfrmVistaGantt.Indicadores1Click(Sender: TObject);
begin
  TfrmCentresKPI.Execute(Self,
  DMPlanner.CentresRepo.GetAll,
  FGanttControl, FNodeRepo, FOperariosRepo,
  FGanttControl.FindCentreIndexById(FCentrosControl.SelectedCentreId));
end;

procedure TfrmVistaGantt.INFO3Click(Sender: TObject);
var
  centreId: Integer;
  cIdx, I: Integer;
  c: TCentreTreball;
  Centres: TArray<TCentreTreball>;
  Cal: TCentreCalendar;
  SampleCal: TSampleCalendario;
  PCal: PSampleCalendario;
  LunesPeriods, SabPeriods, DomPeriods: TArray<TNonWorkingPeriod>;
  FullSab, FullDom: Boolean;
begin
  centreId := FCentrosControl.SelectedCentreId;
  if centreId < 0 then Exit;
  cIdx := FGanttControl.FindCentreIndexById(centreId);
  if cIdx < 0 then Exit;

  c := FGanttControl.GetCentreByIndex(cIdx);

  // Construir TSampleCalendario a partir del TCentreCalendar asociado al centro.
  PCal := nil;
  if DMPlanner.CentresRepo <> nil then
  begin
    Cal := DMPlanner.CentresRepo.GetCalendarFor(c.Id);
    if Cal <> nil then
    begin
      SampleCal.Nombre := Cal.Name;

      // Periodos no laborables del lunes (ISO 1) como representativos de L-V.
      LunesPeriods := Cal.NonWorkingPeriodsForDate(EncodeDate(2024, 1, 1)); // lunes
      SetLength(SampleCal.PeriodosLV, Length(LunesPeriods));
      for I := 0 to High(LunesPeriods) do
      begin
        SampleCal.PeriodosLV[I].StartH := HourOf(LunesPeriods[I].StartTimeOfDay);
        SampleCal.PeriodosLV[I].StartM := MinuteOf(LunesPeriods[I].StartTimeOfDay);
        SampleCal.PeriodosLV[I].EndH   := HourOf(LunesPeriods[I].EndTimeOfDay);
        SampleCal.PeriodosLV[I].EndM   := MinuteOf(LunesPeriods[I].EndTimeOfDay);
      end;

      // Fin de semana completo si sabado (ISO 6) y domingo (ISO 7) tienen
      // un periodo que cubre 00:00..23:59.
      SabPeriods := Cal.NonWorkingPeriodsForDate(EncodeDate(2024, 1, 6)); // sabado
      DomPeriods := Cal.NonWorkingPeriodsForDate(EncodeDate(2024, 1, 7)); // domingo
      FullSab := (Length(SabPeriods) > 0) and
                 (SabPeriods[0].StartTimeOfDay <= EncodeTime(0, 1, 0, 0)) and
                 (SabPeriods[0].EndTimeOfDay   >= EncodeTime(23, 58, 0, 0));
      FullDom := (Length(DomPeriods) > 0) and
                 (DomPeriods[0].StartTimeOfDay <= EncodeTime(0, 1, 0, 0)) and
                 (DomPeriods[0].EndTimeOfDay   >= EncodeTime(23, 58, 0, 0));
      SampleCal.FinDeSemanaCompleto := FullSab and FullDom;

      PCal := @SampleCal;
    end;
  end;

  if TfrmCentreInspector.Execute(c, False, PCal) then
  begin
    // Persistir a BD y actualizar repo en memoria.
    if DMPlanner.CentresRepo <> nil then
      DMPlanner.CentresRepo.Update(DMPlanner.CodigoEmpresa, c);

    // Aplicar cambios al Gantt (hace RebuildLayout si procede).
    FGanttControl.UpdateCentre(c.Id, c);

    // Refrescar panel lateral de centros con lista actualizada.
    if DMPlanner.CentresRepo <> nil then
    begin
      Centres := DMPlanner.CentresRepo.GetAll;
      FCentrosControl.SetCentres(Centres);
    end;
    FCentrosControl.SetRows(FGanttControl.GetRowsCopy);
  end;
end;

procedure TfrmVistaGantt.Button14Click(Sender: TObject);
begin
  if FCentrosControl.VerIndicadores then
    RebuildCentreKPIs_Parallel( FALSE );
end;


procedure TfrmVistaGantt.Button15Click(Sender: TObject);
begin
   if FCentrosControl.VerIndicadores then
    RebuildCentreKPIs_Parallel( TRUE );
end;

procedure TfrmVistaGantt.Button16Click(Sender: TObject);
begin
    FGanttControl.GoToFirstNode;
end;

procedure TfrmVistaGantt.Button17Click(Sender: TObject);
begin
    FGanttControl.GoToPreviousNode;
end;

procedure TfrmVistaGantt.Button18Click(Sender: TObject);
begin
    FGanttControl.GoToLastNode;
end;

procedure TfrmVistaGantt.Button19Click(Sender: TObject);
begin
    FGanttControl.GoToNextNode;
end;

procedure TfrmVistaGantt.Inicializar(const AFechaInicio, AFechaFin: TDateTime);
var
  T0, T1: TDateTime;
  ModoActual: string;
  NecesitaGrupo, EsGrupoActual: Boolean;
begin
  // Asegurar que FGanttControl corresponde al RowMode del proyecto actual.
  // El form se crea una sola vez pero el usuario puede cambiar el mode del
  // proyecto entre aperturas, asi que recreamos el control si el tipo no
  // casa con el mode actual.
  ModoActual := UpperCase(Trim(DMPlanner.CurrentProjectRowMode));
  NecesitaGrupo := ModoActual = 'GRUPO';
  EsGrupoActual := FGanttControl is TGanttControlGrupo;
  if NecesitaGrupo <> EsGrupoActual then
  begin
    FreeAndNil(FGanttControl);
    if NecesitaGrupo then
    begin
      FGanttControl := TGanttControlGrupo.Create(Self);
      TGanttControlGrupo(FGanttControl).NivelAgrupacion :=
        DMPlanner.CurrentProjectNivelAgrupacion;
    end
    else
      FGanttControl := TGanttControl.Create(Self);
    FGanttControl.Parent := pnlGanttContainer;
    FGanttControl.Align := alClient;
    FGanttControl.ShowHint := True;
    FGanttControl.NodePopupMenu := popNode;
    FGanttControl.PopupMenu := popGantt;
    FGanttControl.SetNodeRepo(FNodeRepo);
    FGanttControl.OnViewportChanged := GanttViewportChanged;
    FGanttControl.OnScrollYChanged := GanttScrollYChanged;
    FGanttControl.OnNodeDblClick := GanttNodeDblClick;
    FGanttControl.OnMarkerDblClick := GanttMarkerDblClick;
    FGanttControl.OnStatsChanged := GanttStatsChanged;
    FGanttControl.OnLayoutChanged := GanttLayoutChanged;
    FGanttControl.OnNodeSelected := GanttNodeSelected;
    FGanttControl.OnVoid := GanttVoidClick;
    FGanttControl.OnFechaBloqueoChanged := GanttFechaBloqueoChanged;
  end
  else if NecesitaGrupo then
  begin
    // Mismo tipo pero puede haber cambiado NivelAgrupacion
    TGanttControlGrupo(FGanttControl).NivelAgrupacion :=
      DMPlanner.CurrentProjectNivelAgrupacion;
  end;

  dtFechaInicioGantt.Date := AFechaInicio;
  dtFechaFinGantt.Date := AFechaFin;
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
procedure TfrmVistaGantt.Button20Click(Sender: TObject);
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

procedure TfrmVistaGantt.Button21Click(Sender: TObject);
begin
    FGanttControl.GoToPrevOF;
end;

procedure TfrmVistaGantt.Button22Click(Sender: TObject);
begin
  FGanttControl.GoToNextOF;
end;

procedure TfrmVistaGantt.Button23Click(Sender: TObject);
var
  idx: Integer;
  iAllOF, iPrioridad: Integer;
begin

  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;

  FGanttControl.BackwardScheduleOT( idx, cxDateEdit1.Date, 0, TRUE  );

end;

procedure TfrmVistaGantt.Button27Click(Sender: TObject);
begin
  pnlToolbar.Visible := not pnlToolbar.Visible;
  Panel3.Visible := not Panel3.Visible;
  if pnlToolbar.Visible then
   Panel1.Height := pnlTitulo.Height + pnlSubTitulo.Height + pnlToolbar.Height + Panel3.Height
  else
   Panel1.Height := pnlTitulo.Height + pnlSubTitulo.Height;
end;
procedure TfrmVistaGantt.Button2Click(Sender: TObject);
var
  idx: Integer;
  iAllOF, iPrioridad: Integer;
begin

  idx := FGanttControl.SelectedNodeIndex;
  if idx < 0 then Exit;

  FGanttControl.BackwardScheduleOF( idx, cxDateEdit1.Date, 0, TRUE  );

end;

procedure TfrmVistaGantt.Calendario1Click(Sender: TObject);
var
  idx, CentreId, centreIDX: Integer;
  node: TNode;
  dt: TDatetime;
  cal: TCentreCalendar;
  X, Y: Integer;
  bInNonWorking: Boolean;
  sFranjahoraria, sMsg: String;
  AStart, AEnd: TDateTime;
  centre: TCentreTreball;
begin

  X := FGanttControl.FClickPoint.X;
  Y := FGanttControl.FClickPoint.Y;

  dt := FGanttControl.GetDateTimeFromPoint( X, 0);
  //CentreId := FGantt.GetCentreIdFromPoint(X, 0);

  bInNonWorking := FGanttControl.GetNonWorkingIntervalFromPointMerged( FGanttControl.FClickPoint.X,
                                                FGanttControl.FClickPoint.Y,
                                                AStart, AEnd,
                                                CentreId,
                                                40 );

  if bInNonWorking then
   sFranjahoraria := 'NO'
  else
   sFranjahoraria := 'SI';


  centreIDX := FGanttControl.FindCentreIndexById(CentreId);
  centre := FGanttControl.GetCentreByIndex(centreIDX);

  cal := FGanttControl.GetCalendar( CentreId );

  sMsg := 'Fecha hora: ' + DAtetimetostr( dt ) + chr(13) + chr(10) +
          'Centro: (' + inttostr(CentreId) + ') ' + centre.Titulo + chr(13) + chr(10) +
          'Nombre Calendario: ' + cal.Name + chr(13) + chr(10) +
          'Franja horaria: ' + sFranjahoraria + chr(13) + chr(10) +
          'Periodo NoLaborable Inicio:  ' + DAtetimetostr( AStart )+ chr(13) + chr(10) +
          'Periodo NoLaborable Fin:  ' + DAtetimetostr( AEnd );

  ShowMessage( sMsg );
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

  // Callback que resuelve el nombre a pintar en el panel izquierdo a partir
  // del CentreId del TRowLayout. En modo CENTROS es el titulo del centro;
  // en modo GRUPO el "CentreId" del row en realidad es el indice del grupo
  // y delegamos en TGanttControlGrupo.GetGroupCaption.
  if FGanttControl is TGanttControlGrupo then
  begin
    FCentrosControl.GetCentreName :=
      function(const CentreId: Integer): string
      begin
        // En modo GRUPO el "CentreId" del row es el indice del grupo.
        Result := TGanttControlGrupo(FGanttControl).GetGroupCaption(CentreId);
      end;
    // NO pasar la lista de centros al panel izquierdo en modo GRUPO — asi
    // FindCentreIndexById siempre retorna -1 y PaintRowD2D cae al callback
    // GetCentreName (que ya resuelve la etiqueta del grupo).
    FCentrosControl.SetCentres(nil);
  end
  else
  begin
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
  end;
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
procedure TfrmVistaGantt.cbVistasPropertiesChange(Sender: TObject);
var
  idx: Integer;
  vm: TGanttViewMode;
begin

    idx := cbVistas.ItemIndex;
    case idx of
    0: vm := gvmNormal;
    1: vm := gvmOptimitzacio;
    2: vm := gvmFabricacio;
    3: vm := gvmFechaEntrega;
    4: vm := gvmStock;
    5: vm := gvmOperarios;
    6: vm := gvmCarga;
    7: vm := gvmEstado;  //...estado OF (esPendiente, esEnCurso, esFinalizado, esBloqueado);
    8: vm := gvmPrioridad;
    9: vm := gvmRendimiento;
    10: vm := gvmColores;
    11: vm := gvmModificaciones;
    else
      vm := gvmNormal;
    end;

    FGanttControl.Vista := vm;
    btnFocus.SetFocus;
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
procedure TfrmVistaGantt.lblModifiedClick(Sender: TObject);
begin
    FGanttControl.MarkAllNodesModified( False );
    FGanttControl.RebuildLayout;
    FGanttControl.Invalidate;
end;

procedure TfrmVistaGantt.Marcadoresautomaticos1Click(Sender: TObject);
begin
  FGanttControl.AutoMarkersEnabled := Marcadoresautomaticos1.Checked;
  FGanttControl.Invalidate;
end;

procedure TfrmVistaGantt.MenuItem1Click(Sender: TObject);
var
 dt: TDateTime;
begin
  dt := FGanttControl.GetDateTimeFromPoint( FGanttControl.FClickPoint.X, 0);
  FGanttControl.FechaBloqueo := dt;
  GuardarFechaBloqueo(dt);
end;

procedure TfrmVistaGantt.GanttFechaBloqueoChanged(Sender: TObject);
begin
  GuardarFechaBloqueo(FGanttControl.FechaBloqueo);
end;

procedure TfrmVistaGantt.GuardarFechaBloqueo(const ADate: TDateTime);
var
  Cmd: TADOCommand;
  BloqueoSQL: string;
begin
  if DMPlanner.CurrentProjectId <= 0 then Exit;

  if ADate = 0 then
    BloqueoSQL := 'NULL'
  else
    BloqueoSQL := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', ADate) + '''';

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_Project SET FechaBloqueo = ' + BloqueoSQL + ', ' +
      '  FechaModificacion = GETDATE() ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      '  AND ProjectId = ' + IntToStr(DMPlanner.CurrentProjectId);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // Refrescar cache del proyecto activo en DMPlanner (para que CurrentProjectFechaBloqueo
  // y CurrentProjectTieneBloqueo reflejen el cambio sin necesidad de reabrir).
  DMPlanner.SetCurrentProject(DMPlanner.CurrentProjectId);
end;

procedure TfrmVistaGantt.Aadirmarcador1Click(Sender: TObject);
var
  dt: TDateTime;
  M: TGanttMarker;
begin
  if not Assigned(FGanttControl) then
    Exit;

  dt := FGanttControl.GetDateTimeFromPoint(FGanttControl.FClickPoint.X, 0);

  M := Default(TGanttMarker);
  M.DateTime := dt;
  M.Caption := FormatDateTime('dd/mm hh:nn', dt);
  M.Color := clRed;
  M.Style := msLine;
  M.StrokeWidth := 1.5;
  M.Moveable := True;
  M.Visible := True;
  M.Tag := 0;
  M.FontName := 'Segoe UI';
  M.FontSize := 8;
  M.FontColor := clRed;
  M.FontStyle := [];
  M.TextOrientation := mtoHorizontal;
  M.TextAlign := mtaTop;

  FGanttControl.AddMarker(M);

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
procedure TfrmVistaGantt.btnResaltarOFClick(Sender: TObject);
var
   iTag: Integer;
   bOF, bOT: Boolean;
begin

   iTag := TcxButton(Sender).Tag;

   bOF  := btnResaltarOF.SpeedButtonOptions.Down;
   bOT  := btnResaltarOT.SpeedButtonOptions.Down;

   if bOF or bOT then
    GanttNodeSelected( Self )
   else
    FGanttControl.ClearSearch;

end;

procedure TfrmVistaGantt.pnlGanttContainerResize(Sender: TObject);
begin
  // TODO (paso siguiente): copiar lógica de Main.pnlGanttContainerResize
end;
procedure TfrmVistaGantt.ShiftRow1Click(Sender: TObject);
begin
  FGanttControl.ShiftLeftSequentialCentresFromDate( FGanttControl.FClickDatetime, 0);
end;

procedure TfrmVistaGantt.ShiftRowallimpact1Click(Sender: TObject);
begin
  FGanttControl.ShiftLeftAllImpactedSequentialFromDate( FGanttControl.FClickDatetime, 0);
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
  UpdateKPIs;
end;

procedure TfrmVistaGantt.UpdateKPIs;
begin
  lblNodes.Caption := IntToStr(FGanttControl.CNT_TotalNodes);
  lblVisible.Caption := IntToStr(FGanttControl.CNT_TotalVisibleNodes);
  lblModified.Caption := IntToStr(FGanttControl.CNT_TotalModifiedNodes);
  lblNormal.Caption := IntToStr(FGanttControl.CNT_TotalNodes_StateNormal);
  lblYellow.Caption := IntToStr(FGanttControl.CNT_TotalNodes_StateYellow);
  lblOrange.Caption := IntToStr(FGanttControl.CNT_TotalNodes_StateOrange);
  lblRed.Caption := IntToStr(FGanttControl.CNT_TotalNodes_StateRed);
  lblGreen.Caption := IntToStr(FGanttControl.CNT_TotalNodes_StateGreen);
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
    // Si el botón ResaltarOF está activo, resaltar toda la OF del nodo seleccionado
  if btnResaltarOF.SpeedButtonOptions.Down then
    FGanttControl.HighlightOF(FGanttControl.SelectedNodeIndex);

  if btnResaltarOT.SpeedButtonOptions.Down then
    FGanttControl.HighlightOT(FGanttControl.SelectedNodeIndex);
end;

procedure TfrmVistaGantt.GanttVoidClick(Sender: TObject);
begin
    // Al hacer clic en el fondo, limpiar el resaltado
  FGanttControl.ClearSearch;
end;
procedure TfrmVistaGantt.Gestionmarcadores1Click(Sender: TObject);
var
  Frm: TfrmGestionMarkers;
begin
  Frm := TfrmGestionMarkers.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;

end;

procedure TfrmVistaGantt.GanttNodeDblClick(Sender: TObject;
  const NodeIndex: Integer);
var
  node: TNode;
  ANodeData: TNodeData;
begin
  if NodeIndex < 0 then Exit;
  node := FGanttControl.SelectedNode;
  if not FNodeRepo.TryGetById(node.DataId, ANodeData) then Exit;

  if TfrmNodeInspector.Execute(ANodeData, False, FCustomFieldDefs) then
  begin
    FNodeRepo.AddOrUpdate(ANodeData);
    FGanttControl.Invalidate;
  end;

end;

procedure TfrmVistaGantt.GanttMarkerDblClick(Sender: TObject;
  const MarkerId: Integer);
var
  markers: TArray<TGanttMarker>;
  M: TGanttMarker;
  i: Integer;
  res: TMarkerEditorResult;
begin
  markers := FGanttControl.GetMarkers;
  for i := 0 to High(markers) do
  begin
    if markers[i].Id = MarkerId then
    begin
      M := markers[i];
      res := TfrmMarkerEditor.Execute(M);
      case res of
        merOK:
        begin
          FGanttControl.RemoveMarker(MarkerId);
          FGanttControl.AddMarker(M);
        end;
        merDelete:
          FGanttControl.RemoveMarker(MarkerId);
      end;
      Exit;
    end;
  end;
end;

procedure TfrmVistaGantt.CentresScrollYChanged(Sender: TObject;
  const ScrollY: Single);
begin
  if Assigned(FGanttControl) then
    FGanttControl.ApplyScrollYFromCentres(ScrollY);
end;

procedure TfrmVistaGantt.chkShowKPIsClick(Sender: TObject);
begin
  FCentrosControl.VerIndicadores := chkShowKPIs.Checked;

  // Ajustar el panell al nou Width del control (BaseWidth + IndicadoresWidth o BaseWidth)
  pnlCentros.Width := FCentrosControl.Width;

  FGanttControl.NotifyViewportChanged;

  if FCentrosControl.VerIndicadores then
    RebuildCentreKPIs_Parallel( FALSE );

  FCentrosControl.Repaint;
end;

destructor TfrmVistaGantt.Destroy;
begin
  FreeAndNil(FCentreKPIs);
  inherited;
end;

function TfrmVistaGantt.BuildNodeKPIItemsFromGanttNodes: TArray<TNodeKPIItem>;
var
  I: Integer;
  N: TNode;
  D: TNodeData;
begin
  SetLength(Result, FGanttControl.NodeCount);
  for I := 0 to FGanttControl.NodeCount - 1 do
  begin
    N := FGanttControl.GetNodeAt(I);
    Result[I].CentreId   := N.CentreId;
    Result[I].StartTime  := N.StartTime;
    Result[I].EndTime    := N.EndTime;
    Result[I].DurationMin := N.DurationMin;
    if (FNodeRepo <> nil) and FNodeRepo.TryGetById(N.DataId, D) then
      Result[I].OperariosAsignados := D.OperariosAsignados
    else
      Result[I].OperariosAsignados := 0;
  end;
end;

function TfrmVistaGantt.CalcCentreKPI_FastPrecomputed(
  const ANodes: TArray<TNodeKPIItem>;
  const ACalendar: TCentreCalendar;
  const AWindowStart, AWindowEnd: TDateTime): TCentreKPI;
var
  I: Integer;
  N: TNodeKPIItem;
  SegStart, SegEnd: TDateTime;
  MinsOcupats, MinsDisponibles, MinsTotals: Double;
  NonWorking: TArray<TAbsInterval>;
begin
  Result.TotalNodes := 0;
  Result.HoresOcupades := 0;
  Result.HoresDisponibles := 0;
  Result.TotalOperaris := 0;
  Result.PercentOcupacio := 0;

  if ACalendar = nil then Exit;
  if AWindowEnd <= AWindowStart then Exit;

  NonWorking := ACalendar.BuildMergedNonWorkingIntervalsForWindow(
    AWindowStart, AWindowEnd);

  MinsTotals := ACalendar.WorkingMinutesBetweenPrecomputed(
    AWindowStart, AWindowEnd, NonWorking);

  MinsOcupats := 0;
  for I := 0 to High(ANodes) do
  begin
    N := ANodes[I];
    if N.EndTime <= AWindowStart then Continue;
    if N.StartTime >= AWindowEnd then Continue;

    SegStart := Max(N.StartTime, AWindowStart);
    SegEnd   := Min(N.EndTime, AWindowEnd);
    if SegEnd <= SegStart then Continue;

    Inc(Result.TotalNodes);
    Inc(Result.TotalOperaris, N.OperariosAsignados);

    MinsOcupats := MinsOcupats +
      ACalendar.WorkingMinutesBetweenPrecomputed(SegStart, SegEnd, NonWorking);
  end;

  MinsDisponibles := MinsTotals - MinsOcupats;
  if MinsDisponibles < 0 then MinsDisponibles := 0;

  Result.HoresOcupades := MinsOcupats / 60.0;
  Result.HoresDisponibles := MinsDisponibles / 60.0;

  if MinsTotals > 0 then
    Result.PercentOcupacio := (MinsOcupats / MinsTotals) * 100.0
  else
    Result.PercentOcupacio := 0;
end;

function TfrmVistaGantt.BuildKPIRanges: TCentresKPIRanges;
var
  I: Integer;
  K: TCentreKPI;
  Centres: TArray<TCentreTreball>;
begin
  Result.Nodes.MinInt := MaxInt;          Result.Nodes.MaxInt := -MaxInt;
  Result.Nodes.MinFloat := 0;             Result.Nodes.MaxFloat := 0;

  Result.Ocupades.MinInt := 0;            Result.Ocupades.MaxInt := 0;
  Result.Ocupades.MinFloat := 1.0E100;    Result.Ocupades.MaxFloat := -1.0E100;

  Result.Disponibles.MinInt := 0;         Result.Disponibles.MaxInt := 0;
  Result.Disponibles.MinFloat := 1.0E100; Result.Disponibles.MaxFloat := -1.0E100;

  Result.Operaris.MinInt := MaxInt;       Result.Operaris.MaxInt := -MaxInt;
  Result.Operaris.MinFloat := 0;          Result.Operaris.MaxFloat := 0;

  Result.PercentOcupacio.MinInt := 0;     Result.PercentOcupacio.MaxInt := 0;
  Result.PercentOcupacio.MinFloat := 1.0E100;
  Result.PercentOcupacio.MaxFloat := -1.0E100;

  if DMPlanner.CentresRepo <> nil then
    Centres := DMPlanner.CentresRepo.GetAll
  else
    SetLength(Centres, 0);

  if Length(Centres) = 0 then
  begin
    Result.Nodes.MinInt := 0; Result.Nodes.MaxInt := 0;
    Result.Ocupades.MinFloat := 0; Result.Ocupades.MaxFloat := 0;
    Result.Disponibles.MinFloat := 0; Result.Disponibles.MaxFloat := 0;
    Result.Operaris.MinInt := 0; Result.Operaris.MaxInt := 0;
    Result.PercentOcupacio.MinFloat := 0; Result.PercentOcupacio.MaxFloat := 0;
    Exit;
  end;

  for I := 0 to High(Centres) do
  begin
    if not FCentreKPIs.TryGetValue(Centres[I].Id, K) then Continue;

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

function TfrmVistaGantt.GetCentreKPIValue(const CentreId: Integer): TCentreKPI;
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

procedure TfrmVistaGantt.RebuildCentreKPIs_Parallel(const bCalcAll: Boolean);
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
  Centres: TArray<TCentreTreball>;
begin
  if not Assigned(FGanttControl) then Exit;
  if not FCentrosControl.VerIndicadores then Exit;

  Screen.Cursor := crHourGlass;
  try
    if DMPlanner.CentresRepo <> nil then
      Centres := DMPlanner.CentresRepo.GetAll
    else
      SetLength(Centres, 0);

    KPIItems := BuildNodeKPIItemsFromGanttNodes;

    NowRef := Now;
    if bCalcAll then
    begin
      KPIWindowStart := NowRef;
      KPIWindowEnd   := FGanttControl.EndTime;
    end
    else
    begin
      KPIWindowStart := FGanttControl.StartVisibleTime;
      KPIWindowEnd   := FGanttControl.EndVisibleTime;
    end;

    TmpMap := TObjectDictionary<Integer, TList<TNodeKPIItem>>.Create([doOwnsValues]);
    try
      SetLength(WorkItems, Length(Centres));
      for I := 0 to High(Centres) do
      begin
        CentreId := Centres[I].Id;
        WorkItems[I].CentreId := CentreId;
        WorkItems[I].Calendar := FGanttControl.GetCalendar(CentreId);
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
        if TmpMap.TryGetValue(WorkItems[I].CentreId, Lst) then
          WorkItems[I].Items := Lst.ToArray;

      SetLength(Results, Length(WorkItems));

      TParallel.For(0, High(WorkItems),
        procedure(Index: Integer)
        begin
          Results[Index].CentreId := WorkItems[Index].CentreId;
          Results[Index].KPI := CalcCentreKPI_FastPrecomputed(
            WorkItems[Index].Items,
            WorkItems[Index].Calendar,
            KPIWindowStart,
            KPIWindowEnd);
        end);

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

end.
