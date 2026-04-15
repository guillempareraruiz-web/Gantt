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
  uGanttHelpers,
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
  uGanttControl, uGanttTimeline, uGanttCentres, uGanttTypes;

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
  private
    FNodeRepo: TNodeDataRepo;
    FOperariosRepo: TOperariosRepo;
    FMoldeRepo: TMoldeRepo;
    FCustomFieldDefs: TCustomFieldDefs;
    FPlanningRuleEngine: TPlanningRuleEngine;
    FGanttControl: TGanttControl;
    FTimelineControl: TGanttTimelineControl;
    FCentrosControl: TGanttCentresControl;
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
  end;

implementation

{$R *.dfm}

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

  FGanttControl := TGanttControl.Create(Self);
  FGanttControl.Parent := pnlGanttContainer;
  FGanttControl.Align := alClient;
  FGanttControl.ShowHint := True;

  FCentrosControl := TGanttCentresControl.Create(Self);
  FCentrosControl.Parent := pnlCentros;
  FCentrosControl.Align := alLeft;

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

procedure TfrmVistaGantt.Inicializar(const AFechaInicio, AFechaFin: TDateTime);
var
  T0, T1: TDateTime;
begin
  T0 := DayStart(AFechaInicio - 2);
  T1 := DayEnd(AFechaFin);
  if T1 < T0 then
    T1 := DayEnd(T0);

  FTimelineControl.SetTimeRange(T0, T1);
end;

procedure TfrmVistaGantt.pnlGanttContainerResize(Sender: TObject);
begin
  // TODO (paso siguiente): copiar lógica de Main.pnlGanttContainerResize
end;

procedure TfrmVistaGantt.TimelineViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
begin
  // TODO (paso siguiente)
end;

procedure TfrmVistaGantt.TimelineInteraction(Sender: TObject;
  const Interacting: Boolean);
begin
  // TODO (paso siguiente)
end;

procedure TfrmVistaGantt.GanttViewportChanged(Sender: TObject;
  const StartTime: TDateTime; const PxPerMinute, ScrollX: Single);
begin
  // TODO (paso siguiente)
end;

procedure TfrmVistaGantt.GanttScrollYChanged(Sender: TObject;
  const ScrollY: Single);
begin
  // TODO (paso siguiente)
end;

procedure TfrmVistaGantt.GanttStatsChanged(Sender: TObject);
begin
  // TODO (paso siguiente)
end;

procedure TfrmVistaGantt.GanttLayoutChanged(Sender: TObject);
begin
  // TODO (paso siguiente)
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
  // TODO (paso siguiente)
end;

end.
