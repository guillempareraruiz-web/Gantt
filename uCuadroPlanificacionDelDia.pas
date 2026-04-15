unit uCuadroPlanificacionDelDia;

{
  TfrmCuadroPlanificacionDelDia - Cuadro de planificacion del dia.

  Muestra por cada centro de trabajo visible:
  - Listado de operaciones (cards) asignadas al dia actual.
  - KPIs comparativos: planificado vs real (unidades, horas, operarios).

  No hay tareas pendientes por planificar ni drag & drop.
  Solo lectura; fecha fija = hoy.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.Math, System.DateUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst,
  uGanttTypes, uNodeDataRepo, uCentreCalendar, uErpTypes, uGestionTurnos;

type
  // Tema de colores
  TThemeColors = record
    FormBg: TColor;
    HeaderBg: TColor;
    HeaderText: TColor;
    DateText: TColor;
    FilterBarBg: TColor;
    FilterBtnBg: TColor;
    FilterText: TColor;
    GlobalKPIBg: TColor;
    GlobalKPILabel: TColor;
    GlobalKPISep: TColor;
    GlobalKPILine: TColor;
    ContentBg: TColor;
    FooterBg: TColor;
    FooterText: TColor;
    // Centre panel
    PanelBg: TColor;
    KPIBg: TColor;
    KPIBorder: TColor;
    KPILabel: TColor;
    KPIPlanText: TColor;
    KPIRealText: TColor;
    BarTrack: TColor;
    // Cards
    CardBg: TColor;
    CardBgHover: TColor;
    CardBgFinished: TColor;
    CardBorderFinished: TColor;
    CardBorder: TColor;
    CardTitle: TColor;
    CardSubtext: TColor;
    CardDimText: TColor;
    CardSepLine: TColor;
    // Scrollbar
    SBTrack: TColor;
    SBThumb: TColor;
  end;

  // KPIs de un centro para el dia actual
  TCentreKPIDia = record
    CentreId: Integer;
    CentreName: string;
    TotalOperaciones: Integer;
    UnidadesPlanificadas: Double;
    UnidadesRealizadas: Double;
    HorasPlanificadas: Double;
    HorasRealizadas: Double;     // calculado a partir de unidades reales * tiempo unitario
    OperariosNecesarios: Integer;
    OperariosAsignados: Integer;
  end;

  // KPIs globales del dia
  TGlobalKPIDia = record
    TotalOps: Integer;
    OpsFinalizadas: Integer;
    OpsBloqueadas: Integer;
    OpsEnCurso: Integer;
    OpsPendientes: Integer;
    UnidadesPlan: Double;
    UnidadesReal: Double;
    HorasPlan: Double;
    HorasReal: Double;
    OperariosNecesarios: Integer;
    OperariosAsignados: Integer;
    EficienciaProductiva: Double;  // % uds reales / uds plan
    EficienciaTemporal: Double;    // % horas teoricas / horas reales
    CoberturaOperarios: Double;    // % asignados / necesarios
    AvanceGlobal: Double;          // % ponderado por duracion
    OEE: Double;                   // % OEE simplificado (Disponibilidad x Rendimiento, sin calidad)
  end;

  // Callback para obtener las fechas planificadas de un nodo
  TGetNodeTimesFunc = reference to function(const DataId: Integer;
    out AStart, AEnd: TDateTime): Boolean;

  { --------------------------------------------------------- }
  {  TCentrePanel - panel visual de un centro con KPIs y cards }
  { --------------------------------------------------------- }
  TCentrePanel = class(TCustomControl)
  private const
    HEADER_H  = 64;
    KPI_H     = 130;
    CARD_H    = 100;
    CARD_GAP  = 6;
    CARD_MARGIN = 8;
    SCROLLBAR_W = 10;
    NOW_LINE_H = 20;  // altura de la marca "AHORA"
  private
    FNodeRepo: TNodeDataRepo;
    FCentre: TCentreTreball;
    FKPI: TCentreKPIDia;
    FTheme: TThemeColors;
    FItems: TArray<Integer>;   // DataIds asignados hoy
    FItemTimes: TArray<TDateTime>;  // hora inicio de cada item (para linea "ahora")
    FNow: TDateTime;
    FScrollY: Integer;
    FHoverIdx: Integer;

    // Drag de columna
    FDragPending: Boolean;
    FDragStartPt: TPoint;
    FOnBeginColDrag: TNotifyEvent;

    // Scrollbar
    FDraggingSB: Boolean;
    FSBGrabY: Integer;
    FSBGrabScrollY: Integer;

    function IdxAtY(const Y: Integer): Integer;
    function MaxScrollY: Integer;
    function ContentTop: Integer;
    function IsOnScrollbar(const X: Integer): Boolean;
    procedure DrawHeader(const ACanvas: TCanvas);
    procedure DrawKPIs(const ACanvas: TCanvas);
    procedure DrawCard(const ACanvas: TCanvas; const Idx: Integer;
      const R: TRect; const IsHover: Boolean);
    procedure DrawScrollbar(const ACanvas: TCanvas);
    procedure DrawNowLine(const ACanvas: TCanvas);
    procedure DrawKPIBox(const ACanvas: TCanvas; const R: TRect;
      const ALabel: string; const APlanned, AReal: Double;
      const AFormat: string);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetData(ARepo: TNodeDataRepo; const ACentre: TCentreTreball;
      const AKPI: TCentreKPIDia; const AItems: TArray<Integer>;
      const AItemTimes: TArray<TDateTime>);
    property Theme: TThemeColors read FTheme write FTheme;
    property OnBeginColDrag: TNotifyEvent read FOnBeginColDrag write FOnBeginColDrag;
    property Centre: TCentreTreball read FCentre;
  end;

  { --------------------------------------------------------- }
  {  TGlobalKPIPanel - barra de KPIs globales del dia          }
  { --------------------------------------------------------- }
  THintZone = record
    R: TRect;
    HintText: string;
  end;

  TGlobalKPIPanel = class(TCustomControl)
  private
    FKPI: TGlobalKPIDia;
    FTheme: TThemeColors;
    FHintZones: TArray<THintZone>;
    FLastHintIdx: Integer;
    procedure AddHintZone(const ARect: TRect; const AHint: string);
    procedure DrawKPICell(const ACanvas: TCanvas; const X, Y: Integer;
      const ALabel, AValue: string; const AValueColor: TColor;
      const AHint: string = '');
    procedure DrawKPICellPct(const ACanvas: TCanvas; const X, Y: Integer;
      const ALabel: string; const APct: Double;
      const AHint: string = '');
    procedure DrawSeparator(const ACanvas: TCanvas; const X: Integer);
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetKPI(const AKPI: TGlobalKPIDia);
    property Theme: TThemeColors read FTheme write FTheme;
  end;

  { --------------------------------------------------------- }
  {  TTurnoKPIData - KPIs calculados para un turno             }
  { --------------------------------------------------------- }
  TTurnoKPIData = record
    TurnoNombre: string;
    TurnoFranja: string;  // ej. "06:00 - 14:00"
    TurnoColor: TColor;
    TotalOps: Integer;
    OpsFinalizadas: Integer;
    UnidadesPlan: Double;
    UnidadesReal: Double;
    HorasPlan: Double;
    HorasReal: Double;
    EficienciaProd: Double;   // %
    AvancePct: Double;        // %
    OEE: Double;              // % OEE simplificado (sin calidad)
    OperariosNec: Integer;
    OperariosAsig: Integer;
  end;

  { --------------------------------------------------------- }
  {  TTurnoComparePanel - panel comparativa entre turnos        }
  { --------------------------------------------------------- }
  TTurnoComparePanel = class(TCustomControl)
  private
    FTurnoKPIs: TArray<TTurnoKPIData>;
    FTheme: TThemeColors;
    FHintZones: TArray<THintZone>;
    FLastHintIdx: Integer;
    procedure AddHintZone(const ARect: TRect; const AHint: string);
    procedure DrawTurnoColumn(const ACanvas: TCanvas; const Idx, X, W: Integer);
    procedure DrawMetricRow(const ACanvas: TCanvas; const X, Y, W: Integer;
      const ALabel: string; const AValues: TArray<Double>;
      const AFormat: string; const ABest: Integer;
      const AIsPct: Boolean = False;
      const AHint: string = '');
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetData(const AData: TArray<TTurnoKPIData>);
    property Theme: TThemeColors read FTheme write FTheme;
  end;

  { --------------------------------------------------------- }
  {  TfrmCuadroPlanificacionDelDia - formulario principal       }
  { --------------------------------------------------------- }
  TfrmCuadroPlanificacionDelDia = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblFechaHoy: TLabel;
    pnlSeparator: TPanel;
    pnlFilterBar: TPanel;
    lblFilterCaption: TLabel;
    pnlFilterBtn: TPanel;
    lblFilterText: TLabel;
    lblFilterArrow: TLabel;
    pnlGlobalKPIs: TPanel;
    pnlTurnoCompare: TPanel;
    pnlContent: TPanel;
    pnlFooter: TPanel;
    lblFooterInfo: TLabel;
    pnlHeaderButtons: TPanel;
    btnCerrar: TButton;
    btnLoadDemo: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnLoadDemoClick(Sender: TObject);
  private
    FNodeRepo: TNodeDataRepo;
    FCentres: TArray<TCentreTreball>;
    FGetNodeTimes: TGetNodeTimesFunc;
    FGetCalendar: TGetCalendarFunc;
    FToday: TDateTime;

    // Tema
    FDarkMode: Boolean;
    FTheme: TThemeColors;
    FBtnDarkMode: TPanel;
    FLblDarkMode: TLabel;

    // Panel KPIs globales
    FGlobalKPIPanel: TGlobalKPIPanel;

    // Panel comparativa turnos
    FTurnoComparePanel: TTurnoComparePanel;
    FTurnoCompareVisible: Boolean;
    FBtnToggleCompare: TPanel;
    FLblToggleCompare: TLabel;

    // Paneles de centro
    FCentrePanels: TObjectList<TCentrePanel>;
    FScrollBox: TScrollBox;

    // Drag de columna
    FColDragging: Boolean;
    FColDragPanel: TCentrePanel;
    FColDragStartX: Integer;

    // Datos demo (propiedad del form cuando se usa standalone)
    FOwnedNodeRepo: TNodeDataRepo;
    FDemoTimes: TDictionary<Integer, TPair<TDateTime, TDateTime>>;

    // Filtro de centros
    FFilterCheckList: TCheckListBox;
    FFilterDropDown: TForm;
    FVisibleCentreIds: TList<Integer>;

    // Perfil de turnos (dropdown custom)
    FTurnos: TArray<TTurno>;
    FLblProfileCaption: TLabel;
    FPnlProfileBtn: TPanel;
    FLblProfileText: TLabel;
    FLblProfileArrow: TLabel;
    FProfileDropDown: TForm;
    FProfileListBox: TListBox;

    // Filtro de turno (dropdown custom)
    FLblTurnoCaption: TLabel;
    FPnlTurnoBtn: TPanel;
    FLblTurnoText: TLabel;
    FLblTurnoArrow: TLabel;
    FTurnoDropDown: TForm;
    FTurnoListBox: TListBox;
    FSelectedTurnoIdx: Integer;  // -1 = todos

    procedure BuildCentrePanels;
    procedure LayoutPanels;
    function IsNodeInCentre(const ND: TNodeData; const CentreId: Integer): Boolean;
    function CalcCentreKPI(const ACentre: TCentreTreball): TCentreKPIDia;
    function GetItemsForCentre(const CentreId: Integer): TArray<Integer>;
    procedure OnFilterBtnClick(Sender: TObject);
    procedure OnFilterCheckClick(Sender: TObject);
    procedure CloseFilterDropDown;
    procedure UpdateFilterText;
    procedure ApplyCentreFilter;
    procedure UpdateFooter;
    function CalcGlobalKPI: TGlobalKPIDia;
    procedure UpdateGlobalKPIs;
    procedure LoadDemoData;
    function IsNodeInTurno(const NStart: TDateTime): Boolean;
    procedure OnProfileBtnClick(Sender: TObject);
    procedure OnProfileSelect(Sender: TObject);
    procedure CloseProfileDropDown;
    procedure OnTurnoBtnClick(Sender: TObject);
    procedure OnTurnoSelect(Sender: TObject);
    procedure CloseTurnoDropDown;
    procedure BuildTurnoCombo;
    procedure UpdateProfileText;
    function CalcTurnoKPI(const ATurno: TTurno): TTurnoKPIData;
    procedure UpdateTurnoCompare;
    procedure OnToggleCompareClick(Sender: TObject);
    procedure OnColDragBegin(Sender: TObject);
    procedure DoColDragMove(const ScreenPt: TPoint);
    procedure DoColDragEnd;
    function GetLightTheme: TThemeColors;
    function GetDarkTheme: TThemeColors;
    procedure ApplyTheme;
    procedure OnDarkModeClick(Sender: TObject);
  protected
    procedure WndProc(var Message: TMessage); override;
  public
    class procedure Execute(
      ANodeRepo: TNodeDataRepo;
      const ACentres: TArray<TCentreTreball>;
      AGetNodeTimes: TGetNodeTimesFunc;
      AGetCalendar: TGetCalendarFunc;
      const ATurnos: TArray<TTurno>); overload;
    class procedure ExecuteDemo;
  end;

implementation

{$R *.dfm}

{ ========================================================= }
{                  Funciones auxiliares                       }
{ ========================================================= }

function EstadoText(const E: TNodoEstado): string;
begin
  case E of
    nePendiente:  Result := 'Pendiente';
    neEnCurso:    Result := 'En curso';
    neFinalizado: Result := 'Finalizado';
    neBloqueado:  Result := 'Bloqueado';
  else Result := '-';
  end;
end;

function EstadoColor(const E: TNodoEstado): TColor;
begin
  case E of
    nePendiente:  Result := $00B0B0B0;
    neEnCurso:    Result := $000080FF;
    neFinalizado: Result := $0000B050;
    neBloqueado:  Result := $004040FF;
  else Result := $00B0B0B0;
  end;
end;

function PctColor(const Pct: Double): TColor;
begin
  // Verde si real >= planificado, rojo si esta por debajo
  if Pct >= 100 then
    Result := $0000B050
  else if Pct >= 75 then
    Result := $000080FF
  else
    Result := $004040FF;
end;

{ ========================================================= }
{                   TGlobalKPIPanel                          }
{ ========================================================= }

constructor TGlobalKPIPanel.Create(AOwner: TComponent);
begin
  inherited;
  DoubleBuffered := True;
  ShowHint := True;
  FLastHintIdx := -1;
  FillChar(FKPI, SizeOf(FKPI), 0);
end;

procedure TGlobalKPIPanel.AddHintZone(const ARect: TRect; const AHint: string);
var
  N: Integer;
begin
  N := Length(FHintZones);
  SetLength(FHintZones, N + 1);
  FHintZones[N].R := ARect;
  FHintZones[N].HintText := AHint;
end;

procedure TGlobalKPIPanel.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  Pt: TPoint;
begin
  inherited;
  Pt := Point(X, Y);
  for I := 0 to High(FHintZones) do
  begin
    if PtInRect(FHintZones[I].R, Pt) then
    begin
      if I <> FLastHintIdx then
      begin
        FLastHintIdx := I;
        Hint := FHintZones[I].HintText;
        Application.CancelHint;
      end;
      Exit;
    end;
  end;
  if FLastHintIdx >= 0 then
  begin
    FLastHintIdx := -1;
    Hint := '';
    Application.CancelHint;
  end;
end;

procedure TGlobalKPIPanel.SetKPI(const AKPI: TGlobalKPIDia);
begin
  FKPI := AKPI;
  Invalidate;
end;

procedure TGlobalKPIPanel.DrawKPICell(const ACanvas: TCanvas;
  const X, Y: Integer; const ALabel, AValue: string; const AValueColor: TColor;
  const AHint: string);
begin
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 8;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := FTheme.GlobalKPILabel;
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextOut(X, Y, ALabel);

  ACanvas.Font.Size := 16;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := AValueColor;
  ACanvas.TextOut(X, Y + 16, AValue);

  if AHint <> '' then
    AddHintZone(Rect(X, Y, X + 120, Y + 50), AHint);
end;

procedure TGlobalKPIPanel.DrawKPICellPct(const ACanvas: TCanvas;
  const X, Y: Integer; const ALabel: string; const APct: Double;
  const AHint: string);
var
  BarR: TRect;
  BarW: Integer;
  PctStr: string;
begin
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 8;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := FTheme.GlobalKPILabel;
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextOut(X, Y, ALabel);

  // Valor
  PctStr := Format('%.0f%%', [APct]);
  ACanvas.Font.Size := 14;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := PctColor(APct);
  ACanvas.TextOut(X, Y + 16, PctStr);

  // Barra
  BarR := Rect(X, Y + 42, X + 110, Y + 52);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := FTheme.BarTrack;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(BarR.Left, BarR.Top, BarR.Right, BarR.Bottom, 4, 4);

  BarW := Min(Round(BarR.Width * Min(APct, 100.0) / 100.0), BarR.Width);
  if BarW > 0 then
  begin
    ACanvas.Brush.Color := PctColor(APct);
    ACanvas.RoundRect(BarR.Left, BarR.Top, BarR.Left + BarW, BarR.Bottom, 4, 4);
  end;

  ACanvas.Pen.Style := psSolid;
  ACanvas.Brush.Style := bsSolid;

  if AHint <> '' then
    AddHintZone(Rect(X, Y, X + 130, Y + 55), AHint);
end;

procedure TGlobalKPIPanel.DrawSeparator(const ACanvas: TCanvas; const X: Integer);
begin
  ACanvas.Pen.Color := FTheme.GlobalKPISep;
  ACanvas.Pen.Style := psSolid;
  ACanvas.MoveTo(X, 8);
  ACanvas.LineTo(X, Height - 8);
end;

procedure TGlobalKPIPanel.Paint;
const
  CELL_W = 130;
  PAD = 16;
var
  X, Y: Integer;
begin
  inherited;
  SetLength(FHintZones, 0);

  Canvas.Brush.Color := FTheme.GlobalKPIBg;
  Canvas.Pen.Style := psClear;
  Canvas.FillRect(ClientRect);
  // Linea inferior sutil
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := FTheme.GlobalKPILine;
  Canvas.MoveTo(0, Height - 1);
  Canvas.LineTo(Width, Height - 1);

  Y := 10;
  X := PAD;

  // Bloque 1: Estado operaciones
  DrawKPICell(Canvas, X, Y, 'Total Ops',
    IntToStr(FKPI.TotalOps), FTheme.KPIRealText,
    'Total de operaciones planificadas para hoy');
  X := X + CELL_W;

  DrawKPICell(Canvas, X, Y, 'Finalizadas',
    IntToStr(FKPI.OpsFinalizadas), $0000B050,
    'Operaciones completadas al 100%');
  X := X + CELL_W;

  DrawKPICell(Canvas, X, Y, 'En Curso',
    IntToStr(FKPI.OpsEnCurso), $000080FF,
    'Operaciones iniciadas pero no finalizadas');
  X := X + 100;

  DrawKPICell(Canvas, X, Y, 'Pendientes',
    IntToStr(FKPI.OpsPendientes), $00B0B0B0,
    'Operaciones programadas aun no iniciadas');
  X := X + 100;

  if FKPI.OpsBloqueadas > 0 then
    DrawKPICell(Canvas, X, Y, 'Bloqueadas',
      IntToStr(FKPI.OpsBloqueadas), $004040FF,
      'Operaciones detenidas por incidencia o dependencia')
  else
    DrawKPICell(Canvas, X, Y, 'Bloqueadas', '0', $00B0B0B0,
      'Operaciones detenidas por incidencia o dependencia');
  X := X + 110;

  DrawSeparator(Canvas, X - 10);

  // Bloque 2: Eficiencias
  DrawKPICellPct(Canvas, X, Y, 'Eficiencia Productiva',
    FKPI.EficienciaProductiva,
    'Porcentaje de unidades fabricadas respecto a las planificadas.'#13#10 +
    'Formula: (Uds. reales / Uds. planificadas) x 100');
  X := X + CELL_W;

  DrawKPICellPct(Canvas, X, Y, 'Eficiencia Temporal',
    FKPI.EficienciaTemporal,
    'Relacion entre el tiempo teorico y el tiempo real consumido.'#13#10 +
    'Formula: (Horas teoricas / Horas reales) x 100'#13#10 +
    'Valores > 100% indican que se ha producido mas rapido de lo previsto.');
  X := X + CELL_W;

  DrawKPICellPct(Canvas, X, Y, 'Cobertura Operarios',
    FKPI.CoberturaOperarios,
    'Porcentaje de operarios asignados respecto a los necesarios.'#13#10 +
    'Formula: (Operarios asignados / Operarios necesarios) x 100'#13#10 +
    'Valores < 100% indican falta de personal.');
  X := X + CELL_W;

  DrawSeparator(Canvas, X - 10);

  // Bloque 3: Avance global + OEE
  DrawKPICellPct(Canvas, X, Y, 'Avance Global',
    FKPI.AvanceGlobal,
    'Avance ponderado por duracion de cada operacion.'#13#10 +
    'Formula: SUM(Duracion x %Avance) / SUM(Duracion) x 100'#13#10 +
    'Refleja mejor el progreso real que un simple conteo de ops.');
  X := X + CELL_W;

  DrawKPICellPct(Canvas, X, Y, 'OEE (sin calidad)',
    FKPI.OEE,
    'Overall Equipment Effectiveness simplificado (sin factor calidad).'#13#10 +
    'Formula: Disponibilidad x Rendimiento x 100'#13#10 +
    'Disponibilidad = Horas reales / Horas planificadas'#13#10 +
    'Rendimiento = Uds. reales / Uds. planificadas'#13#10 +
    'OEE de clase mundial: > 85%');
end;

{ ========================================================= }
{                   TTurnoComparePanel                       }
{ ========================================================= }

constructor TTurnoComparePanel.Create(AOwner: TComponent);
begin
  inherited;
  DoubleBuffered := True;
  ShowHint := True;
  FLastHintIdx := -1;
end;

procedure TTurnoComparePanel.AddHintZone(const ARect: TRect; const AHint: string);
var
  N: Integer;
begin
  N := Length(FHintZones);
  SetLength(FHintZones, N + 1);
  FHintZones[N].R := ARect;
  FHintZones[N].HintText := AHint;
end;

procedure TTurnoComparePanel.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  Pt: TPoint;
begin
  inherited;
  Pt := Point(X, Y);
  for I := 0 to High(FHintZones) do
  begin
    if PtInRect(FHintZones[I].R, Pt) then
    begin
      if I <> FLastHintIdx then
      begin
        FLastHintIdx := I;
        Hint := FHintZones[I].HintText;
        Application.CancelHint;
      end;
      Exit;
    end;
  end;
  if FLastHintIdx >= 0 then
  begin
    FLastHintIdx := -1;
    Hint := '';
    Application.CancelHint;
  end;
end;

procedure TTurnoComparePanel.SetData(const AData: TArray<TTurnoKPIData>);
begin
  FTurnoKPIs := AData;
  Invalidate;
end;

procedure TTurnoComparePanel.DrawMetricRow(const ACanvas: TCanvas;
  const X, Y, W: Integer; const ALabel: string;
  const AValues: TArray<Double>; const AFormat: string; const ABest: Integer;
  const AIsPct: Boolean; const AHint: string);
var
  I, ColW, CX: Integer;
  S: string;
  BarR: TRect;
  BarW: Integer;
  Clr: TColor;
begin
  ColW := W div (Length(AValues) + 1);

  // Etiqueta
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 13;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := FTheme.KPILabel;
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextOut(X + 12, Y + 2, ALabel);

  // Valores
  for I := 0 to High(AValues) do
  begin
    CX := X + ColW * (I + 1);
    S := Format(AFormat, [AValues[I]]);

    if I = ABest then
      Clr := $0000B050
    else
      Clr := FTheme.KPIRealText;

    // Valor
    ACanvas.Font.Size := 16;
    if I = ABest then
      ACanvas.Font.Style := [fsBold]
    else
      ACanvas.Font.Style := [];
    ACanvas.Font.Color := Clr;
    ACanvas.Brush.Style := bsClear;
    ACanvas.TextOut(CX + 12, Y, S);

    // Barra de progreso para porcentajes
    if AIsPct then
    begin
      BarR := Rect(CX + 12, Y + 26, CX + ColW - 20, Y + 34);
      ACanvas.Brush.Style := bsSolid;
      ACanvas.Brush.Color := FTheme.BarTrack;
      ACanvas.Pen.Style := psClear;
      ACanvas.RoundRect(BarR.Left, BarR.Top, BarR.Right, BarR.Bottom, 4, 4);

      BarW := Min(Round(BarR.Width * Min(AValues[I], 100.0) / 100.0), BarR.Width);
      if BarW > 0 then
      begin
        ACanvas.Brush.Color := PctColor(AValues[I]);
        ACanvas.RoundRect(BarR.Left, BarR.Top, BarR.Left + BarW, BarR.Bottom, 4, 4);
      end;

      ACanvas.Pen.Style := psSolid;
    end;
  end;

  ACanvas.Brush.Style := bsSolid;

  // Hint zone en la columna de etiqueta
  if AHint <> '' then
    AddHintZone(Rect(X, Y, X + ColW, Y + 40), AHint);
end;

procedure TTurnoComparePanel.DrawTurnoColumn(const ACanvas: TCanvas;
  const Idx, X, W: Integer);
var
  R: TRect;
begin
  if Idx > High(FTurnoKPIs) then Exit;

  // Cabecera con color del turno
  R := Rect(X, 4, X + W - 6, 50);
  ACanvas.Brush.Color := FTurnoKPIs[Idx].TurnoColor;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);

  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Brush.Style := bsClear;

  // Nombre turno
  ACanvas.Font.Size := 14;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := clWhite;
  ACanvas.TextOut(X + 12, 6, FTurnoKPIs[Idx].TurnoNombre);

  // Franja horaria
  ACanvas.Font.Size := 11;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := $00E0E0E0;
  ACanvas.TextOut(X + 12, 28, FTurnoKPIs[Idx].TurnoFranja);

  // Ops count
  ACanvas.Font.Size := 11;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := clWhite;
  ACanvas.TextOut(X + W - 70, 16,
    Format('%d ops', [FTurnoKPIs[Idx].TotalOps]));

  ACanvas.Pen.Style := psSolid;
  ACanvas.Brush.Style := bsSolid;
end;

procedure TTurnoComparePanel.Paint;
var
  I, ColW, X, Y, N: Integer;
  Vals: TArray<Double>;
  BestIdx: Integer;
  BestVal: Double;

  function FindBestIdx(const Arr: TArray<Double>; const HigherIsBetter: Boolean): Integer;
  var
    K: Integer;
    BV: Double;
  begin
    Result := 0;
    if Length(Arr) = 0 then Exit;
    BV := Arr[0];
    for K := 1 to High(Arr) do
    begin
      if HigherIsBetter then
      begin
        if Arr[K] > BV then begin BV := Arr[K]; Result := K; end;
      end
      else
      begin
        if Arr[K] < BV then begin BV := Arr[K]; Result := K; end;
      end;
    end;
  end;

begin
  inherited;
  SetLength(FHintZones, 0);

  Canvas.Brush.Color := FTheme.GlobalKPIBg;
  Canvas.FillRect(ClientRect);

  // Lineas superior e inferior
  Canvas.Pen.Color := FTheme.GlobalKPILine;
  Canvas.MoveTo(0, 0);
  Canvas.LineTo(Width, 0);
  Canvas.MoveTo(0, Height - 1);
  Canvas.LineTo(Width, Height - 1);

  N := Length(FTurnoKPIs);
  if N = 0 then
  begin
    Canvas.Font.Name := 'Segoe UI';
    Canvas.Font.Size := 10;
    Canvas.Font.Color := FTheme.KPILabel;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(16, 20, 'No hay turnos definidos para comparar.');
    Exit;
  end;

  // Columnas: etiqueta + N turnos
  ColW := Width div (N + 1);

  // Titulo primera columna
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 14;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := FTheme.KPIRealText;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(12, 8, 'Estadisticas por turnos');
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [];
  Canvas.Font.Color := FTheme.KPILabel;
  Canvas.TextOut(12, 32, 'Comparativa del dia actual');

  // Cabeceras turno
  for I := 0 to N - 1 do
    DrawTurnoColumn(Canvas, I, ColW * (I + 1), ColW);

  // Metricas
  Y := 58;
  SetLength(Vals, N);

  // Ops finalizadas
  for I := 0 to N - 1 do Vals[I] := FTurnoKPIs[I].OpsFinalizadas;
  DrawMetricRow(Canvas, 0, Y, Width, 'Ops finalizadas', Vals, '%.0f', FindBestIdx(Vals, True), False,
    'Numero de operaciones completadas al 100% en este turno.');
  Y := Y + 34;

  // Unidades planificadas
  for I := 0 to N - 1 do Vals[I] := FTurnoKPIs[I].UnidadesPlan;
  DrawMetricRow(Canvas, 0, Y, Width, 'Uds planificadas', Vals, '%.0f', FindBestIdx(Vals, True), False,
    'Total de unidades previstas a fabricar en este turno.');
  Y := Y + 34;

  // Unidades realizadas
  for I := 0 to N - 1 do Vals[I] := FTurnoKPIs[I].UnidadesReal;
  DrawMetricRow(Canvas, 0, Y, Width, 'Uds realizadas', Vals, '%.0f', FindBestIdx(Vals, True), False,
    'Total de unidades efectivamente fabricadas en este turno.');
  Y := Y + 34;

  // Eficiencia productiva (con barra)
  for I := 0 to N - 1 do Vals[I] := FTurnoKPIs[I].EficienciaProd;
  DrawMetricRow(Canvas, 0, Y, Width, 'Eficiencia prod.', Vals, '%.1f%%', FindBestIdx(Vals, True), True,
    'Porcentaje de unidades fabricadas respecto a las planificadas.'#13#10 +
    'Formula: (Uds. reales / Uds. planificadas) x 100');
  Y := Y + 46;

  // Horas planificadas
  for I := 0 to N - 1 do Vals[I] := FTurnoKPIs[I].HorasPlan;
  DrawMetricRow(Canvas, 0, Y, Width, 'Horas plan.', Vals, '%.1f h', FindBestIdx(Vals, True), False,
    'Suma de horas teoricas de todas las operaciones del turno.'#13#10 +
    'Formula: SUM(DuracionMin / 60)');
  Y := Y + 34;

  // Horas reales
  for I := 0 to N - 1 do Vals[I] := FTurnoKPIs[I].HorasReal;
  DrawMetricRow(Canvas, 0, Y, Width, 'Horas reales', Vals, '%.1f h', -1, False,
    'Suma de horas reales consumidas, estimadas a partir de'#13#10 +
    'unidades fabricadas x tiempo unitario de fabricacion.');
  Y := Y + 34;

  // Avance global (con barra)
  for I := 0 to N - 1 do Vals[I] := FTurnoKPIs[I].AvancePct;
  DrawMetricRow(Canvas, 0, Y, Width, 'Avance', Vals, '%.1f%%', FindBestIdx(Vals, True), True,
    'Avance ponderado por duracion de cada operacion.'#13#10 +
    'Formula: SUM(Duracion x %Avance) / SUM(Duracion) x 100');
  Y := Y + 46;

  // Operarios
  for I := 0 to N - 1 do Vals[I] := FTurnoKPIs[I].OperariosAsig;
  DrawMetricRow(Canvas, 0, Y, Width, 'Operarios asig.', Vals, '%.0f', -1, False,
    'Total de operarios asignados a las operaciones del turno.');
  Y := Y + 34;

  // OEE simplificado (con barra)
  for I := 0 to N - 1 do Vals[I] := FTurnoKPIs[I].OEE;
  DrawMetricRow(Canvas, 0, Y, Width, 'OEE (sin calidad)', Vals, '%.1f%%', FindBestIdx(Vals, True), True,
    'Overall Equipment Effectiveness simplificado (sin factor calidad).'#13#10 +
    'Formula: Disponibilidad x Rendimiento x 100'#13#10 +
    'Disponibilidad = Horas reales / Horas planificadas'#13#10 +
    'Rendimiento = Uds. reales / Uds. planificadas'#13#10 +
    'OEE de clase mundial: > 85%');
end;

{ ========================================================= }
{                     TCentrePanel                           }
{ ========================================================= }

constructor TCentrePanel.Create(AOwner: TComponent);
begin
  inherited;
  FHoverIdx := -1;
  FScrollY := 0;
  DoubleBuffered := True;
end;

procedure TCentrePanel.SetData(ARepo: TNodeDataRepo;
  const ACentre: TCentreTreball; const AKPI: TCentreKPIDia;
  const AItems: TArray<Integer>; const AItemTimes: TArray<TDateTime>);
begin
  FNodeRepo := ARepo;
  FCentre := ACentre;
  FKPI := AKPI;
  FItems := AItems;
  FItemTimes := AItemTimes;
  FNow := Now;
  FScrollY := 0;
  Invalidate;
end;

function TCentrePanel.ContentTop: Integer;
begin
  Result := HEADER_H + KPI_H;
end;

function TCentrePanel.IdxAtY(const Y: Integer): Integer;
var
  LocalY: Integer;
begin
  LocalY := Y - ContentTop + FScrollY;
  if LocalY < 0 then Exit(-1);
  Result := LocalY div (CARD_H + CARD_GAP);
  if Result > High(FItems) then
    Result := -1;
end;

function TCentrePanel.MaxScrollY: Integer;
var
  TotalH: Integer;
begin
  TotalH := Length(FItems) * (CARD_H + CARD_GAP);
  Result := Max(0, TotalH - (Height - ContentTop));
end;

function TCentrePanel.IsOnScrollbar(const X: Integer): Boolean;
begin
  Result := X >= (Width - SCROLLBAR_W);
end;

procedure TCentrePanel.DrawHeader(const ACanvas: TCanvas);
var
  R: TRect;
begin
  R := Rect(0, 0, Width, HEADER_H);

  // Fondo cabecera con color del centro
  if FCentre.BkColor <> 0 then
    ACanvas.Brush.Color := FCentre.BkColor
  else
    ACanvas.Brush.Color := $00D08040;
  ACanvas.FillRect(R);

  // Titulo
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 16;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := clWhite;
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextOut(10, 6, FCentre.Titulo);

  // Subtitulo
  ACanvas.Font.Size := 11;
  ACanvas.Font.Style := [];
  ACanvas.TextOut(10, 34, FCentre.Subtitulo);

  // Cantidad de operaciones
  ACanvas.Font.Size := 12;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := clWhite;
  ACanvas.TextOut(Width - 80, 20,
    Format('%d ops', [FKPI.TotalOperaciones]));

  ACanvas.Brush.Style := bsSolid;
end;

procedure TCentrePanel.DrawKPIBox(const ACanvas: TCanvas; const R: TRect;
  const ALabel: string; const APlanned, AReal: Double;
  const AFormat: string);
var
  Pct: Double;
  PctStr: string;
  MidY, BoxW: Integer;
  BarR: TRect;
  BarW: Integer;
begin
  BoxW := R.Width;
  MidY := R.Top + 4;

  // Etiqueta
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 10;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := FTheme.KPILabel;
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextOut(R.Left + 6, MidY, ALabel);

  // Valor planificado
  MidY := MidY + 22;
  ACanvas.Font.Size := 11;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := FTheme.KPIPlanText;
  ACanvas.TextOut(R.Left + 6, MidY,
    'Plan: ' + Format(AFormat, [APlanned]));

  // Valor real
  MidY := MidY + 22;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := FTheme.KPIRealText;
  ACanvas.TextOut(R.Left + 6, MidY,
    'Real: ' + Format(AFormat, [AReal]));

  // Barra de progreso
  MidY := MidY + 26;
  BarR := Rect(R.Left + 6, MidY, R.Left + BoxW - 10, MidY + 12);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := FTheme.BarTrack;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(BarR.Left, BarR.Top, BarR.Right, BarR.Bottom, 4, 4);

  if APlanned > 0 then
    Pct := (AReal / APlanned) * 100.0
  else if AReal > 0 then
    Pct := 100.0
  else
    Pct := 0;

  BarW := Min(Round((BarR.Width) * Min(Pct, 100.0) / 100.0), BarR.Width);
  if BarW > 0 then
  begin
    ACanvas.Brush.Color := PctColor(Pct);
    ACanvas.RoundRect(BarR.Left, BarR.Top, BarR.Left + BarW, BarR.Bottom, 4, 4);
  end;

  // Porcentaje encima de la barra, alineado a la derecha
  if APlanned > 0 then
    PctStr := Format('%.0f%%', [Pct])
  else
    PctStr := '-';
  ACanvas.Font.Size := 10;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := PctColor(Pct);
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextOut(BarR.Right - ACanvas.TextWidth(PctStr), BarR.Top - ACanvas.TextHeight(PctStr) - 2, PctStr);

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Pen.Style := psSolid;
end;

procedure TCentrePanel.DrawKPIs(const ACanvas: TCanvas);
var
  R: TRect;
  ColW: Integer;
begin
  R := Rect(0, HEADER_H, Width, HEADER_H + KPI_H);

  // Fondo
  ACanvas.Brush.Color := FTheme.KPIBg;
  ACanvas.Pen.Color := FTheme.KPIBorder;
  ACanvas.Rectangle(R);

  ColW := Width div 3;

  // KPI 1: Unidades
  DrawKPIBox(ACanvas,
    Rect(R.Left, R.Top, R.Left + ColW, R.Bottom),
    'Unidades',
    FKPI.UnidadesPlanificadas, FKPI.UnidadesRealizadas, '%.0f');

  // KPI 2: Horas
  DrawKPIBox(ACanvas,
    Rect(R.Left + ColW, R.Top, R.Left + ColW * 2, R.Bottom),
    'Horas',
    FKPI.HorasPlanificadas, FKPI.HorasRealizadas, '%.1f');

  // KPI 3: Operarios
  DrawKPIBox(ACanvas,
    Rect(R.Left + ColW * 2, R.Top, R.Right, R.Bottom),
    'Operarios',
    FKPI.OperariosNecesarios, FKPI.OperariosAsignados, '%.0f');
end;

procedure TCentrePanel.DrawCard(const ACanvas: TCanvas; const Idx: Integer;
  const R: TRect; const IsHover: Boolean);
var
  ND: TNodeData;
  StatusClr, BgColor: TColor;
  RightX, PctUds, PctHrs, HrsReal: Double;
  PctUdsStr, PctHrsStr: string;
  MidR: Integer;
begin
  if not FNodeRepo.TryGetById(FItems[Idx], ND) then Exit;

  // Fondo segun estado
  if ND.Estado = neFinalizado then
    BgColor := FTheme.CardBgFinished
  else if IsHover then
    BgColor := FTheme.CardBgHover
  else
    BgColor := FTheme.CardBg;

  ACanvas.Brush.Color := BgColor;
  if ND.Estado = neFinalizado then
    ACanvas.Pen.Color := FTheme.CardBorderFinished
  else
    ACanvas.Pen.Color := FTheme.CardBorder;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);

  // Barra lateral estado
  StatusClr := EstadoColor(ND.Estado);
  ACanvas.Brush.Color := StatusClr;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(R.Left, R.Top + 2, R.Left + 6, R.Bottom - 2, 3, 3);
  ACanvas.Pen.Style := psSolid;

  // --- Zona izquierda: info de la operacion ---
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Brush.Style := bsClear;

  // Linea 1: OF + Articulo
  ACanvas.Font.Size := 12;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := FTheme.CardTitle;
  ACanvas.TextOut(R.Left + 12, R.Top + 6,
    Format('OF %d - %s', [ND.NumeroOrdenFabricacion, ND.CodigoArticulo]));

  // Linea 2: Operacion + Estado
  ACanvas.Font.Size := 10;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := FTheme.CardSubtext;
  ACanvas.TextOut(R.Left + 12, R.Top + 30,
    Format('%s  |  %s', [ND.Operacion, EstadoText(ND.Estado)]));

  // Linea 3: Descripcion articulo
  ACanvas.Font.Size := 9;
  ACanvas.Font.Color := FTheme.CardDimText;
  ACanvas.TextOut(R.Left + 12, R.Top + 52,
    ND.DescripcionArticulo);

  // Badge finalizado
  if ND.Estado = neFinalizado then
  begin
    ACanvas.Font.Size := 8;
    ACanvas.Font.Style := [fsBold];
    ACanvas.Font.Color := $0000A040;
    ACanvas.TextOut(R.Left + 12, R.Top + 74, 'FINALIZADO');
  end;

  // --- Zona derecha: KPIs compactos ---
  RightX := R.Right - 170;
  MidR := R.Top + 4;

  // Separador vertical
  ACanvas.Pen.Color := FTheme.CardSepLine;
  ACanvas.MoveTo(Round(RightX) - 6, R.Top + 6);
  ACanvas.LineTo(Round(RightX) - 6, R.Bottom - 6);

  // Unidades: Plan / Real / %
  if ND.UnidadesAFabricar > 0 then
    PctUds := (ND.UnidadesFabricadas / ND.UnidadesAFabricar) * 100.0
  else
    PctUds := 0;
  if PctUds > 0 then
    PctUdsStr := Format('%.0f%%', [PctUds])
  else
    PctUdsStr := '-';

  ACanvas.Font.Size := 8;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := FTheme.CardDimText;
  ACanvas.TextOut(Round(RightX), MidR, 'Unidades');

  MidR := MidR + 16;
  ACanvas.Font.Size := 10;
  ACanvas.Font.Color := FTheme.CardSubtext;
  ACanvas.TextOut(Round(RightX), MidR,
    Format('%.0f / %.0f', [ND.UnidadesFabricadas, ND.UnidadesAFabricar]));
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := PctColor(PctUds);
  ACanvas.TextOut(R.Right - 46, MidR, PctUdsStr);

  // Tiempo: Plan / Real / %
  MidR := MidR + 20;
  HrsReal := 0;
  if ND.TiempoUnidadFabSecs > 0 then
    HrsReal := (ND.UnidadesFabricadas * ND.TiempoUnidadFabSecs / 3600.0)
  else if (ND.UnidadesAFabricar > 0) and (ND.DurationMin > 0) then
    HrsReal := (ND.UnidadesFabricadas * (ND.DurationMin / ND.UnidadesAFabricar) / 60.0);

  if ND.DurationMin > 0 then
    PctHrs := (HrsReal / (ND.DurationMin / 60.0)) * 100.0
  else
    PctHrs := 0;
  if PctHrs > 0 then
    PctHrsStr := Format('%.0f%%', [PctHrs])
  else
    PctHrsStr := '-';

  ACanvas.Font.Size := 8;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := FTheme.CardDimText;
  ACanvas.TextOut(Round(RightX), MidR, 'Tiempo (h)');

  MidR := MidR + 16;
  ACanvas.Font.Size := 10;
  ACanvas.Font.Color := FTheme.CardSubtext;
  ACanvas.TextOut(Round(RightX), MidR,
    Format('%.1f / %.1f', [HrsReal, ND.DurationMin / 60.0]));
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := PctColor(PctHrs);
  ACanvas.TextOut(R.Right - 46, MidR, PctHrsStr);

  ACanvas.Brush.Style := bsSolid;
end;

procedure TCentrePanel.DrawScrollbar(const ACanvas: TCanvas);
var
  VisH, TotalH, ThumbH, ThumbY: Integer;
  R: TRect;
begin
  VisH := Height - ContentTop;
  TotalH := Length(FItems) * (CARD_H + CARD_GAP);
  if TotalH <= VisH then Exit;

  // Track
  R := Rect(Width - SCROLLBAR_W, ContentTop, Width, Height);
  ACanvas.Brush.Color := FTheme.SBTrack;
  ACanvas.Pen.Style := psClear;
  ACanvas.FillRect(R);

  // Thumb
  ThumbH := Max(20, MulDiv(VisH, VisH, TotalH));
  ThumbY := ContentTop + MulDiv(FScrollY, VisH - ThumbH, MaxScrollY);
  ACanvas.Brush.Color := FTheme.SBThumb;
  ACanvas.RoundRect(R.Left + 1, ThumbY, R.Right - 1, ThumbY + ThumbH, 4, 4);
  ACanvas.Pen.Style := psSolid;
end;

procedure TCentrePanel.DrawNowLine(const ACanvas: TCanvas);
var
  I, Y, Top, NowIdx: Integer;
  NowTime: TDateTime;
  S: string;
  TW: Integer;
begin
  if Length(FItemTimes) = 0 then Exit;

  NowTime := FNow;
  Top := ContentTop;

  // Encontrar la posicion: entre que cards cae "ahora"
  NowIdx := Length(FItemTimes); // por defecto al final
  for I := 0 to High(FItemTimes) do
  begin
    if FItemTimes[I] > NowTime then
    begin
      NowIdx := I;
      Break;
    end;
  end;

  // Calcular Y
  Y := Top + NowIdx * (CARD_H + CARD_GAP) - FScrollY - (CARD_GAP div 2);

  if (Y < Top) or (Y > Height) then Exit;

  // Linea discontinua roja
  ACanvas.Pen.Color := $002020FF;
  ACanvas.Pen.Width := 2;
  ACanvas.Pen.Style := psDash;
  ACanvas.MoveTo(CARD_MARGIN, Y);
  ACanvas.LineTo(Width - CARD_MARGIN - SCROLLBAR_W, Y);
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := 1;

  // Etiqueta "AHORA hh:mm"
  S := 'AHORA ' + FormatDateTime('hh:nn', NowTime);
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 8;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := $002020FF;
  ACanvas.Brush.Style := bsClear;
  TW := ACanvas.TextWidth(S);
  ACanvas.TextOut(Width - CARD_MARGIN - SCROLLBAR_W - TW - 4, Y - 14, S);
  ACanvas.Brush.Style := bsSolid;
end;

procedure TCentrePanel.Paint;
var
  I, Y, Top: Integer;
  R: TRect;
begin
  inherited;
  Canvas.Brush.Color := FTheme.PanelBg;
  Canvas.FillRect(ClientRect);

  DrawHeader(Canvas);
  DrawKPIs(Canvas);

  // Clip region para las cards
  Top := ContentTop;
  IntersectClipRect(Canvas.Handle, 0, Top, Width, Height);

  for I := 0 to High(FItems) do
  begin
    Y := Top + I * (CARD_H + CARD_GAP) - FScrollY;
    if (Y + CARD_H < Top) then Continue;
    if (Y > Height) then Break;

    R := Rect(CARD_MARGIN, Y, Width - CARD_MARGIN - SCROLLBAR_W, Y + CARD_H);
    DrawCard(Canvas, I, R, I = FHoverIdx);
  end;

  // Linea de hora actual
  DrawNowLine(Canvas);

  SelectClipRgn(Canvas.Handle, 0);
  DrawScrollbar(Canvas);
end;

procedure TCentrePanel.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft) and IsOnScrollbar(X) and (MaxScrollY > 0) then
  begin
    FDraggingSB := True;
    FSBGrabY := Y;
    FSBGrabScrollY := FScrollY;
  end
  else if (Button = mbLeft) and (Y < HEADER_H) then
  begin
    // Inicio de drag de columna desde el header
    FDragPending := True;
    FDragStartPt := Point(X, Y);
  end;
end;

procedure TCentrePanel.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  VisH, Delta: Integer;
  NewIdx: Integer;
begin
  inherited;
  if FDragPending then
  begin
    if (Abs(X - FDragStartPt.X) > 8) or (Abs(Y - FDragStartPt.Y) > 8) then
    begin
      FDragPending := False;
      if Assigned(FOnBeginColDrag) then
        FOnBeginColDrag(Self);
    end;
    Exit;
  end;
  if FDraggingSB then
  begin
    VisH := Height - ContentTop;
    if VisH <= 0 then Exit;
    Delta := Y - FSBGrabY;
    FScrollY := EnsureRange(
      FSBGrabScrollY + MulDiv(Delta, MaxScrollY, VisH),
      0, MaxScrollY);
    Invalidate;
    Exit;
  end;

  // Cursor mano en header (para drag)
  if Y < HEADER_H then
    Cursor := crHandPoint
  else
    Cursor := crDefault;

  NewIdx := IdxAtY(Y);
  if NewIdx <> FHoverIdx then
  begin
    FHoverIdx := NewIdx;
    Invalidate;
  end;
end;

procedure TCentrePanel.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  FDraggingSB := False;
  FDragPending := False;
end;

function TCentrePanel.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  Result := True;
  FScrollY := EnsureRange(FScrollY - WheelDelta, 0, MaxScrollY);
  Invalidate;
end;

{ ========================================================= }
{             TfrmCuadroPlanificacionDelDia                  }
{ ========================================================= }

procedure TfrmCuadroPlanificacionDelDia.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  FToday := Date;
  lblFechaHoy.Caption := '  ' + FormatDateTime('dddd, d "de" mmmm "de" yyyy', FToday);

  FVisibleCentreIds := TList<Integer>.Create;
  FCentrePanels := TObjectList<TCentrePanel>.Create(True);

  // ScrollBox para contener los paneles de centro
  FScrollBox := TScrollBox.Create(Self);
  FScrollBox.Parent := pnlContent;
  FScrollBox.Align := alClient;
  FScrollBox.BorderStyle := bsNone;
  FScrollBox.Color := pnlContent.Color;
  FScrollBox.HorzScrollBar.Tracking := True;
  FScrollBox.VertScrollBar.Visible := False;

  // Panel KPIs globales
  FGlobalKPIPanel := TGlobalKPIPanel.Create(Self);
  FGlobalKPIPanel.Parent := pnlGlobalKPIs;
  FGlobalKPIPanel.Align := alClient;

  // Panel comparativa turnos
  FTurnoCompareVisible := False;
  FTurnoComparePanel := TTurnoComparePanel.Create(Self);
  FTurnoComparePanel.Parent := pnlTurnoCompare;
  FTurnoComparePanel.Align := alClient;

  // Toggle comparativa turnos (en la barra de filtro)
  FBtnToggleCompare := TPanel.Create(Self);
  FBtnToggleCompare.Parent := pnlFilterBar;
  FBtnToggleCompare.Width := 130;
  FBtnToggleCompare.Height := 26;
  FBtnToggleCompare.Left := pnlFilterBar.Width - 260;
  FBtnToggleCompare.Top := 5;
  FBtnToggleCompare.Anchors := [akTop, akRight];
  FBtnToggleCompare.BevelOuter := bvNone;
  FBtnToggleCompare.Cursor := crHandPoint;
  FBtnToggleCompare.ParentBackground := False;
  FBtnToggleCompare.Color := $00D0D0D0;
  FBtnToggleCompare.OnClick := OnToggleCompareClick;

  FLblToggleCompare := TLabel.Create(FBtnToggleCompare);
  FLblToggleCompare.Parent := FBtnToggleCompare;
  FLblToggleCompare.Align := alClient;
  FLblToggleCompare.Alignment := taCenter;
  FLblToggleCompare.Layout := tlCenter;
  FLblToggleCompare.Font.Name := 'Segoe UI';
  FLblToggleCompare.Font.Size := 9;
  FLblToggleCompare.Font.Color := $00444444;
  FLblToggleCompare.Caption := 'Comparar turnos';
  FLblToggleCompare.Cursor := crHandPoint;
  FLblToggleCompare.OnClick := OnToggleCompareClick;

  // Click handlers para filtro
  pnlFilterBtn.OnClick := OnFilterBtnClick;
  lblFilterText.OnClick := OnFilterBtnClick;
  lblFilterArrow.OnClick := OnFilterBtnClick;

  // Dropdown perfil de turnos (estil idèntic a centres)
  FLblProfileCaption := TLabel.Create(Self);
  FLblProfileCaption.Parent := pnlFilterBar;
  FLblProfileCaption.SetBounds(340, 0, 40, 36);
  FLblProfileCaption.AutoSize := False;
  FLblProfileCaption.Caption := 'Perfil:';
  FLblProfileCaption.Font.Name := 'Segoe UI';
  FLblProfileCaption.Font.Size := 9;
  FLblProfileCaption.Font.Style := [fsBold];
  FLblProfileCaption.Font.Color := clGray;
  FLblProfileCaption.Layout := tlCenter;

  FPnlProfileBtn := TPanel.Create(Self);
  FPnlProfileBtn.Parent := pnlFilterBar;
  FPnlProfileBtn.SetBounds(382, 4, 210, 28);
  FPnlProfileBtn.BevelOuter := bvNone;
  FPnlProfileBtn.Color := clWhite;
  FPnlProfileBtn.ParentBackground := False;
  FPnlProfileBtn.Cursor := crHandPoint;
  FPnlProfileBtn.OnClick := OnProfileBtnClick;

  FLblProfileText := TLabel.Create(FPnlProfileBtn);
  FLblProfileText.Parent := FPnlProfileBtn;
  FLblProfileText.SetBounds(8, 0, 170, 28);
  FLblProfileText.AutoSize := False;
  FLblProfileText.Caption := 'Perfil actual';
  FLblProfileText.Font.Name := 'Segoe UI';
  FLblProfileText.Font.Size := 9;
  FLblProfileText.Font.Color := $00555555;
  FLblProfileText.Layout := tlCenter;
  FLblProfileText.Cursor := crHandPoint;
  FLblProfileText.OnClick := OnProfileBtnClick;

  FLblProfileArrow := TLabel.Create(FPnlProfileBtn);
  FLblProfileArrow.Parent := FPnlProfileBtn;
  FLblProfileArrow.SetBounds(186, 0, 20, 28);
  FLblProfileArrow.AutoSize := False;
  FLblProfileArrow.Alignment := taCenter;
  FLblProfileArrow.Caption := #9660;
  FLblProfileArrow.Font.Name := 'Segoe UI';
  FLblProfileArrow.Font.Size := 8;
  FLblProfileArrow.Font.Color := $00888888;
  FLblProfileArrow.Layout := tlCenter;
  FLblProfileArrow.Cursor := crHandPoint;
  FLblProfileArrow.OnClick := OnProfileBtnClick;

  // Dropdown filtro de turno (estil idèntic a centres)
  FSelectedTurnoIdx := -1;

  FLblTurnoCaption := TLabel.Create(Self);
  FLblTurnoCaption.Parent := pnlFilterBar;
  FLblTurnoCaption.SetBounds(600, 0, 50, 36);
  FLblTurnoCaption.AutoSize := False;
  FLblTurnoCaption.Caption := 'Turno:';
  FLblTurnoCaption.Font.Name := 'Segoe UI';
  FLblTurnoCaption.Font.Size := 9;
  FLblTurnoCaption.Font.Style := [fsBold];
  FLblTurnoCaption.Font.Color := clGray;
  FLblTurnoCaption.Layout := tlCenter;

  FPnlTurnoBtn := TPanel.Create(Self);
  FPnlTurnoBtn.Parent := pnlFilterBar;
  FPnlTurnoBtn.SetBounds(652, 4, 180, 28);
  FPnlTurnoBtn.BevelOuter := bvNone;
  FPnlTurnoBtn.Color := clWhite;
  FPnlTurnoBtn.ParentBackground := False;
  FPnlTurnoBtn.Cursor := crHandPoint;
  FPnlTurnoBtn.OnClick := OnTurnoBtnClick;

  FLblTurnoText := TLabel.Create(FPnlTurnoBtn);
  FLblTurnoText.Parent := FPnlTurnoBtn;
  FLblTurnoText.SetBounds(8, 0, 140, 28);
  FLblTurnoText.AutoSize := False;
  FLblTurnoText.Caption := 'Todos los turnos';
  FLblTurnoText.Font.Name := 'Segoe UI';
  FLblTurnoText.Font.Size := 9;
  FLblTurnoText.Font.Color := $00555555;
  FLblTurnoText.Layout := tlCenter;
  FLblTurnoText.Cursor := crHandPoint;
  FLblTurnoText.OnClick := OnTurnoBtnClick;

  FLblTurnoArrow := TLabel.Create(FPnlTurnoBtn);
  FLblTurnoArrow.Parent := FPnlTurnoBtn;
  FLblTurnoArrow.SetBounds(156, 0, 20, 28);
  FLblTurnoArrow.AutoSize := False;
  FLblTurnoArrow.Alignment := taCenter;
  FLblTurnoArrow.Caption := #9660;
  FLblTurnoArrow.Font.Name := 'Segoe UI';
  FLblTurnoArrow.Font.Size := 8;
  FLblTurnoArrow.Font.Color := $00888888;
  FLblTurnoArrow.Layout := tlCenter;
  FLblTurnoArrow.Cursor := crHandPoint;
  FLblTurnoArrow.OnClick := OnTurnoBtnClick;

  // Toggle modo oscuro en la barra de filtro
  FBtnDarkMode := TPanel.Create(Self);
  FBtnDarkMode.Parent := pnlFilterBar;
  FBtnDarkMode.Width := 100;
  FBtnDarkMode.Height := 26;
  FBtnDarkMode.Left := pnlFilterBar.Width - 114;
  FBtnDarkMode.Top := 5;
  FBtnDarkMode.Anchors := [akTop, akRight];
  FBtnDarkMode.BevelOuter := bvNone;
  FBtnDarkMode.Cursor := crHandPoint;
  FBtnDarkMode.ParentBackground := False;
  FBtnDarkMode.OnClick := OnDarkModeClick;

  FLblDarkMode := TLabel.Create(FBtnDarkMode);
  FLblDarkMode.Parent := FBtnDarkMode;
  FLblDarkMode.Align := alClient;
  FLblDarkMode.Alignment := taCenter;
  FLblDarkMode.Layout := tlCenter;
  FLblDarkMode.Font.Name := 'Segoe UI';
  FLblDarkMode.Font.Size := 10;
  FLblDarkMode.Cursor := crHandPoint;
  FLblDarkMode.OnClick := OnDarkModeClick;

  // Tema inicial claro
  FDarkMode := False;
  ApplyTheme;
end;

procedure TfrmCuadroPlanificacionDelDia.FormDestroy(Sender: TObject);
begin
  FVisibleCentreIds.Free;
  FCentrePanels.Free;
  FFilterDropDown.Free;
  FProfileDropDown.Free;
  FTurnoDropDown.Free;
  FDemoTimes.Free;
  FOwnedNodeRepo.Free;
end;

procedure TfrmCuadroPlanificacionDelDia.FormResize(Sender: TObject);
begin
  LayoutPanels;
end;

procedure TfrmCuadroPlanificacionDelDia.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

{ --- Filtro de centros (copiado de uFiniteCapacityPlanner) --- }

procedure TfrmCuadroPlanificacionDelDia.OnFilterBtnClick(Sender: TObject);
var
  Pt: TPoint;
  I: Integer;
  ItemH, TotalH: Integer;
begin
  if (FFilterDropDown <> nil) and FFilterDropDown.Visible then
  begin
    CloseFilterDropDown;
    Exit;
  end;

  if FFilterDropDown = nil then
  begin
    FFilterDropDown := TForm.CreateNew(Self);
    FFilterDropDown.BorderStyle := bsNone;
    FFilterDropDown.FormStyle := fsStayOnTop;
    FFilterDropDown.Color := clWhite;

    FFilterCheckList := TCheckListBox.Create(FFilterDropDown);
    FFilterCheckList.Parent := FFilterDropDown;
    FFilterCheckList.Align := alClient;
    FFilterCheckList.BorderStyle := bsNone;
    FFilterCheckList.Font.Name := 'Segoe UI';
    FFilterCheckList.Font.Size := 10;
    FFilterCheckList.Font.Color := $00444444;
    FFilterCheckList.Color := clWhite;
    FFilterCheckList.OnClickCheck := OnFilterCheckClick;
  end;

  FFilterCheckList.Items.Clear;
  for I := 0 to High(FCentres) do
  begin
    if not FCentres[I].Visible then Continue;
    if FCentres[I].Id < 0 then Continue;
    FFilterCheckList.Items.AddObject(FCentres[I].Titulo, TObject(FCentres[I].Id));
    FFilterCheckList.Checked[FFilterCheckList.Items.Count - 1] :=
      FVisibleCentreIds.Contains(FCentres[I].Id);
  end;

  Pt := pnlFilterBtn.ClientToScreen(Point(0, pnlFilterBtn.Height));
  ItemH := FFilterCheckList.ItemHeight;
  if ItemH < 20 then ItemH := 22;
  TotalH := Min(FFilterCheckList.Items.Count * ItemH + 4, 400);
  FFilterDropDown.SetBounds(Pt.X, Pt.Y, pnlFilterBtn.Width, TotalH);
  ShowWindow(FFilterDropDown.Handle, SW_SHOWNOACTIVATE);
  FFilterDropDown.Visible := True;
end;

procedure TfrmCuadroPlanificacionDelDia.OnFilterCheckClick(Sender: TObject);
var
  I, CId: Integer;
begin
  FVisibleCentreIds.Clear;
  for I := 0 to FFilterCheckList.Items.Count - 1 do
  begin
    if FFilterCheckList.Checked[I] then
    begin
      CId := Integer(FFilterCheckList.Items.Objects[I]);
      FVisibleCentreIds.Add(CId);
    end;
  end;

  UpdateFilterText;
  ApplyCentreFilter;
end;

procedure TfrmCuadroPlanificacionDelDia.CloseFilterDropDown;
begin
  if (FFilterDropDown <> nil) and FFilterDropDown.Visible then
    FFilterDropDown.Hide;
end;

procedure TfrmCuadroPlanificacionDelDia.UpdateFilterText;
var
  N, Total, I: Integer;
begin
  Total := 0;
  for I := 0 to High(FCentres) do
    if FCentres[I].Visible and (FCentres[I].Id >= 0) then
      Inc(Total);

  N := FVisibleCentreIds.Count;
  if (N = 0) or (N = Total) then
    lblFilterText.Caption := 'Todos los centros'
  else if N = 1 then
  begin
    for I := 0 to High(FCentres) do
      if FCentres[I].Id = FVisibleCentreIds[0] then
      begin
        lblFilterText.Caption := FCentres[I].Titulo;
        Exit;
      end;
  end
  else
    lblFilterText.Caption := Format('%d centros seleccionados', [N]);
end;

procedure TfrmCuadroPlanificacionDelDia.ApplyCentreFilter;
begin
  BuildCentrePanels;
end;

{ --- WndProc: cerrar dropdown al clicar fuera --- }

procedure TfrmCuadroPlanificacionDelDia.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_ACTIVATE then
  begin
    if (Message.WParam and $FFFF) = WA_INACTIVE then
      // no cerrar aqui
    else
    begin
      CloseFilterDropDown;
      CloseProfileDropDown;
      CloseTurnoDropDown;
    end;
  end;

  // Drag de columnas
  if FColDragging then
  begin
    case Message.Msg of
      WM_MOUSEMOVE:
        DoColDragMove(Mouse.CursorPos);
      WM_LBUTTONUP:
        DoColDragEnd;
    end;
  end;

  inherited;
end;

{ --- KPIs globales --- }

function TfrmCuadroPlanificacionDelDia.CalcGlobalKPI: TGlobalKPIDia;
var
  AllData: TArray<TNodeData>;
  I: Integer;
  NStart, NEnd: TDateTime;
  DayStart, DayEnd: TDateTime;
  HrsReal, TotalDurPlan, TotalDurAvance: Double;
begin
  FillChar(Result, SizeOf(Result), 0);
  if FNodeRepo = nil then Exit;

  DayStart := Trunc(FToday);
  DayEnd := DayStart + 1;
  AllData := FNodeRepo.GetAllData;
  TotalDurPlan := 0;
  TotalDurAvance := 0;

  for I := 0 to High(AllData) do
  begin
    if not FGetNodeTimes(AllData[I].DataId, NStart, NEnd) then Continue;
    if (NEnd <= DayStart) or (NStart >= DayEnd) then Continue;
    if not IsNodeInTurno(NStart) then Continue;

    // Comprobar que pertenece a algun centro visible
    // (contar todos para el global)

    Inc(Result.TotalOps);
    case AllData[I].Estado of
      neFinalizado: Inc(Result.OpsFinalizadas);
      neEnCurso:    Inc(Result.OpsEnCurso);
      nePendiente:  Inc(Result.OpsPendientes);
      neBloqueado:  Inc(Result.OpsBloqueadas);
    end;

    Result.UnidadesPlan := Result.UnidadesPlan + AllData[I].UnidadesAFabricar;
    Result.UnidadesReal := Result.UnidadesReal + AllData[I].UnidadesFabricadas;
    Result.HorasPlan := Result.HorasPlan + (AllData[I].DurationMin / 60.0);

    // Horas reales
    HrsReal := 0;
    if AllData[I].TiempoUnidadFabSecs > 0 then
      HrsReal := AllData[I].UnidadesFabricadas * AllData[I].TiempoUnidadFabSecs / 3600.0
    else if (AllData[I].UnidadesAFabricar > 0) and (AllData[I].DurationMin > 0) then
      HrsReal := AllData[I].UnidadesFabricadas *
        (AllData[I].DurationMin / AllData[I].UnidadesAFabricar) / 60.0;
    Result.HorasReal := Result.HorasReal + HrsReal;

    Result.OperariosNecesarios := Result.OperariosNecesarios + AllData[I].OperariosNecesarios;
    Result.OperariosAsignados := Result.OperariosAsignados + AllData[I].OperariosAsignados;

    // Avance ponderado por duracion
    TotalDurPlan := TotalDurPlan + AllData[I].DurationMin;
    if AllData[I].UnidadesAFabricar > 0 then
      TotalDurAvance := TotalDurAvance +
        AllData[I].DurationMin * (AllData[I].UnidadesFabricadas / AllData[I].UnidadesAFabricar);
  end;

  // Calcular porcentajes
  if Result.UnidadesPlan > 0 then
    Result.EficienciaProductiva := (Result.UnidadesReal / Result.UnidadesPlan) * 100.0;

  if Result.HorasReal > 0 then
    Result.EficienciaTemporal := (Result.HorasPlan / Result.HorasReal) * 100.0
  else if Result.HorasPlan > 0 then
    Result.EficienciaTemporal := 0
  else
    Result.EficienciaTemporal := 100.0;

  if Result.OperariosNecesarios > 0 then
    Result.CoberturaOperarios := (Result.OperariosAsignados / Result.OperariosNecesarios) * 100.0;

  if TotalDurPlan > 0 then
    Result.AvanceGlobal := (TotalDurAvance / TotalDurPlan) * 100.0;

  // OEE simplificado = Disponibilidad x Rendimiento (sin calidad)
  // Disponibilidad = HorasReal / HorasPlan
  // Rendimiento = UnidadesReal / UnidadesPlan
  if (Result.HorasPlan > 0) and (Result.UnidadesPlan > 0) then
    Result.OEE := (Result.HorasReal / Result.HorasPlan) *
                  (Result.UnidadesReal / Result.UnidadesPlan) * 100.0;
end;

procedure TfrmCuadroPlanificacionDelDia.UpdateGlobalKPIs;
begin
  FGlobalKPIPanel.SetKPI(CalcGlobalKPI);
end;

{ --- Construccion de paneles de centro --- }

function TfrmCuadroPlanificacionDelDia.IsNodeInCentre(
  const ND: TNodeData; const CentreId: Integer): Boolean;
var
  K: Integer;
begin
  // Si CentresPermesos esta vacio, el nodo pertenece a todos los centros
  if Length(ND.CentresPermesos) = 0 then
    Exit(True);
  for K := 0 to High(ND.CentresPermesos) do
    if ND.CentresPermesos[K] = CentreId then
      Exit(True);
  Result := False;
end;

function TfrmCuadroPlanificacionDelDia.GetItemsForCentre(
  const CentreId: Integer): TArray<Integer>;
var
  Ids: TList<Integer>;
  AllData: TArray<TNodeData>;
  I: Integer;
  NStart, NEnd: TDateTime;
  DayStart, DayEnd: TDateTime;
begin
  Ids := TList<Integer>.Create;
  try
    DayStart := Trunc(FToday);
    DayEnd := DayStart + 1;
    AllData := FNodeRepo.GetAllData;

    for I := 0 to High(AllData) do
    begin
      if not IsNodeInCentre(AllData[I], CentreId) then Continue;
      if not FGetNodeTimes(AllData[I].DataId, NStart, NEnd) then Continue;
      if (NEnd <= DayStart) or (NStart >= DayEnd) then Continue;
      if not IsNodeInTurno(NStart) then Continue;
      Ids.Add(AllData[I].DataId);
    end;

    Result := Ids.ToArray;
  finally
    Ids.Free;
  end;
end;

function TfrmCuadroPlanificacionDelDia.CalcCentreKPI(
  const ACentre: TCentreTreball): TCentreKPIDia;
var
  AllData: TArray<TNodeData>;
  I: Integer;
  NStart, NEnd: TDateTime;
  DayStart, DayEnd: TDateTime;
begin
  Result.CentreId := ACentre.Id;
  Result.CentreName := ACentre.Titulo;
  Result.TotalOperaciones := 0;
  Result.UnidadesPlanificadas := 0;
  Result.UnidadesRealizadas := 0;
  Result.HorasPlanificadas := 0;
  Result.HorasRealizadas := 0;
  Result.OperariosNecesarios := 0;
  Result.OperariosAsignados := 0;

  DayStart := Trunc(FToday);
  DayEnd := DayStart + 1;
  AllData := FNodeRepo.GetAllData;

  for I := 0 to High(AllData) do
  begin
    if not IsNodeInCentre(AllData[I], ACentre.Id) then Continue;
    if not FGetNodeTimes(AllData[I].DataId, NStart, NEnd) then Continue;
    if (NEnd <= DayStart) or (NStart >= DayEnd) then Continue;
    if not IsNodeInTurno(NStart) then Continue;

    Inc(Result.TotalOperaciones);
    Result.UnidadesPlanificadas := Result.UnidadesPlanificadas + AllData[I].UnidadesAFabricar;
    Result.UnidadesRealizadas := Result.UnidadesRealizadas + AllData[I].UnidadesFabricadas;
    Result.HorasPlanificadas := Result.HorasPlanificadas + (AllData[I].DurationMin / 60.0);

    if AllData[I].TiempoUnidadFabSecs > 0 then
      Result.HorasRealizadas := Result.HorasRealizadas +
        (AllData[I].UnidadesFabricadas * AllData[I].TiempoUnidadFabSecs / 3600.0)
    else if (AllData[I].UnidadesAFabricar > 0) and (AllData[I].DurationMin > 0) then
      Result.HorasRealizadas := Result.HorasRealizadas +
        (AllData[I].UnidadesFabricadas * (AllData[I].DurationMin / AllData[I].UnidadesAFabricar) / 60.0);

    Result.OperariosNecesarios := Result.OperariosNecesarios + AllData[I].OperariosNecesarios;
    Result.OperariosAsignados := Result.OperariosAsignados + AllData[I].OperariosAsignados;
  end;
end;

procedure TfrmCuadroPlanificacionDelDia.BuildCentrePanels;
var
  I, J: Integer;
  KPI: TCentreKPIDia;
  Items: TArray<Integer>;
  ItemTimes: TArray<TDateTime>;
  NStart, NEnd: TDateTime;
  Pnl: TCentrePanel;
  Total, N: Integer;
  IsVisible: Boolean;
begin
  FCentrePanels.Clear;

  Total := 0;
  for I := 0 to High(FCentres) do
    if FCentres[I].Visible and (FCentres[I].Id >= 0) then
      Inc(Total);

  N := FVisibleCentreIds.Count;

  for I := 0 to High(FCentres) do
  begin
    if not FCentres[I].Visible then Continue;
    if FCentres[I].Id < 0 then Continue;

    // Filtro
    if (N > 0) and (N < Total) then
    begin
      if not FVisibleCentreIds.Contains(FCentres[I].Id) then
        Continue;
    end;

    KPI := CalcCentreKPI(FCentres[I]);
    Items := GetItemsForCentre(FCentres[I].Id);

    // Recoger tiempos de inicio de cada item
    SetLength(ItemTimes, Length(Items));
    for J := 0 to High(Items) do
    begin
      if FGetNodeTimes(Items[J], NStart, NEnd) then
        ItemTimes[J] := NStart
      else
        ItemTimes[J] := 0;
    end;

    Pnl := TCentrePanel.Create(FScrollBox);
    Pnl.Parent := FScrollBox;
    Pnl.FTheme := FTheme;
    Pnl.OnBeginColDrag := OnColDragBegin;
    Pnl.SetData(FNodeRepo, FCentres[I], KPI, Items, ItemTimes);
    FCentrePanels.Add(Pnl);
  end;

  LayoutPanels;
  UpdateFooter;
  UpdateGlobalKPIs;
  if FTurnoCompareVisible then
    UpdateTurnoCompare;
end;

procedure TfrmCuadroPlanificacionDelDia.LayoutPanels;
const
  PANEL_MIN_WIDTH = 500;
  PANEL_GAP = 10;
var
  I, X, PanelW, PanelH: Integer;
begin
  if FCentrePanels.Count = 0 then Exit;

  // Altura = todo el alto disponible del scrollbox
  PanelH := FScrollBox.ClientHeight - PANEL_GAP * 2;
  if PanelH < 300 then PanelH := 300;

  // Ancho: repartir equitativamente si caben, sino minimo 500
  PanelW := (FScrollBox.ClientWidth - PANEL_GAP * (FCentrePanels.Count + 1))
    div FCentrePanels.Count;
  if PanelW < PANEL_MIN_WIDTH then
    PanelW := PANEL_MIN_WIDTH;

  // Siempre en horizontal, una sola fila con scroll
  X := PANEL_GAP;
  for I := 0 to FCentrePanels.Count - 1 do
  begin
    FCentrePanels[I].SetBounds(X, PANEL_GAP, PanelW, PanelH);
    X := X + PanelW + PANEL_GAP;
  end;
end;

procedure TfrmCuadroPlanificacionDelDia.UpdateFooter;
var
  I: Integer;
  TotalOps: Integer;
  TotalUdsPlan, TotalUdsReal: Double;
begin
  TotalOps := 0;
  TotalUdsPlan := 0;
  TotalUdsReal := 0;

  for I := 0 to FCentrePanels.Count - 1 do
  begin
    // Acceder via el KPI que ya calculamos
    // Como TCentrePanel es privado, sumamos de los KPIs
    // Simplificacion: recalcular desde centros visibles
  end;

  lblFooterInfo.Caption := Format(
    'Centros visibles: %d  |  Fecha: %s',
    [FCentrePanels.Count, FormatDateTime('dd/mm/yyyy', FToday)]);
end;

{ --- Perfil de turnos (dropdown custom) --- }

procedure TfrmCuadroPlanificacionDelDia.OnProfileBtnClick(Sender: TObject);
var
  Pt: TPoint;
  I, ItemH, TotalH: Integer;
begin
  if (FProfileDropDown <> nil) and FProfileDropDown.Visible then
  begin
    CloseProfileDropDown;
    Exit;
  end;

  if FProfileDropDown = nil then
  begin
    FProfileDropDown := TForm.CreateNew(Self);
    FProfileDropDown.BorderStyle := bsNone;
    FProfileDropDown.FormStyle := fsStayOnTop;
    FProfileDropDown.Color := clWhite;

    FProfileListBox := TListBox.Create(FProfileDropDown);
    FProfileListBox.Parent := FProfileDropDown;
    FProfileListBox.Align := alClient;
    FProfileListBox.BorderStyle := bsNone;
    FProfileListBox.Font.Name := 'Segoe UI';
    FProfileListBox.Font.Size := 10;
    FProfileListBox.Font.Color := $00444444;
    FProfileListBox.Color := clWhite;
    FProfileListBox.OnClick := OnProfileSelect;
  end;

  FProfileListBox.Items.Clear;
  for I := 0 to NUM_TURNO_PROFILES - 1 do
    FProfileListBox.Items.Add(TURNO_PROFILES[I].ProfileName);

  Pt := FPnlProfileBtn.ClientToScreen(Point(0, FPnlProfileBtn.Height));
  ItemH := FProfileListBox.ItemHeight;
  if ItemH < 20 then ItemH := 22;
  TotalH := Min(FProfileListBox.Items.Count * ItemH + 4, 300);
  FProfileDropDown.SetBounds(Pt.X, Pt.Y, FPnlProfileBtn.Width, TotalH);
  ShowWindow(FProfileDropDown.Handle, SW_SHOWNOACTIVATE);
  FProfileDropDown.Visible := True;
end;

procedure TfrmCuadroPlanificacionDelDia.OnProfileSelect(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := FProfileListBox.ItemIndex;
  if Idx < 0 then Exit;

  CloseProfileDropDown;
  FTurnos := ProfileToTurnos(Idx);
  FSelectedTurnoIdx := -1;
  UpdateProfileText;
  BuildTurnoCombo;
  BuildCentrePanels;
end;

procedure TfrmCuadroPlanificacionDelDia.CloseProfileDropDown;
begin
  if (FProfileDropDown <> nil) and FProfileDropDown.Visible then
    FProfileDropDown.Hide;
end;

procedure TfrmCuadroPlanificacionDelDia.UpdateProfileText;
var
  I: Integer;
  Found: Boolean;
begin
  // Intentar detectar cual perfil coincide con los turnos actuales
  Found := False;
  if Length(FTurnos) = MAX_TURNOS then
  begin
    for I := 0 to NUM_TURNO_PROFILES - 1 do
    begin
      if (FTurnos[0].Nombre = TURNO_PROFILES[I].Slots[0].Nombre) and
         (FTurnos[1].Nombre = TURNO_PROFILES[I].Slots[1].Nombre) and
         (FTurnos[2].Nombre = TURNO_PROFILES[I].Slots[2].Nombre) then
      begin
        FLblProfileText.Caption := TURNO_PROFILES[I].ProfileName;
        Found := True;
        Break;
      end;
    end;
  end;
  if not Found then
    FLblProfileText.Caption := 'Personalizado';
end;

{ --- Filtro de turnos (dropdown custom) --- }

procedure TfrmCuadroPlanificacionDelDia.OnTurnoBtnClick(Sender: TObject);
var
  Pt: TPoint;
  I, ItemH, TotalH: Integer;
begin
  if (FTurnoDropDown <> nil) and FTurnoDropDown.Visible then
  begin
    CloseTurnoDropDown;
    Exit;
  end;

  if FTurnoDropDown = nil then
  begin
    FTurnoDropDown := TForm.CreateNew(Self);
    FTurnoDropDown.BorderStyle := bsNone;
    FTurnoDropDown.FormStyle := fsStayOnTop;
    FTurnoDropDown.Color := clWhite;

    FTurnoListBox := TListBox.Create(FTurnoDropDown);
    FTurnoListBox.Parent := FTurnoDropDown;
    FTurnoListBox.Align := alClient;
    FTurnoListBox.BorderStyle := bsNone;
    FTurnoListBox.Font.Name := 'Segoe UI';
    FTurnoListBox.Font.Size := 10;
    FTurnoListBox.Font.Color := $00444444;
    FTurnoListBox.Color := clWhite;
    FTurnoListBox.OnClick := OnTurnoSelect;
  end;

  FTurnoListBox.Items.Clear;
  FTurnoListBox.Items.AddObject('Todos los turnos', TObject(-1));
  for I := 0 to High(FTurnos) do
  begin
    if not FTurnos[I].Activo then Continue;
    FTurnoListBox.Items.AddObject(
      Format('%s (%s - %s)', [
        FTurnos[I].Nombre,
        FormatDateTime('hh:nn', FTurnos[I].HoraInicio),
        FormatDateTime('hh:nn', FTurnos[I].HoraFin)]),
      TObject(I));
  end;

  Pt := FPnlTurnoBtn.ClientToScreen(Point(0, FPnlTurnoBtn.Height));
  ItemH := FTurnoListBox.ItemHeight;
  if ItemH < 20 then ItemH := 22;
  TotalH := Min(FTurnoListBox.Items.Count * ItemH + 4, 300);
  FTurnoDropDown.SetBounds(Pt.X, Pt.Y, FPnlTurnoBtn.Width, TotalH);
  ShowWindow(FTurnoDropDown.Handle, SW_SHOWNOACTIVATE);
  FTurnoDropDown.Visible := True;
end;

procedure TfrmCuadroPlanificacionDelDia.OnTurnoSelect(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := FTurnoListBox.ItemIndex;
  if Idx < 0 then Exit;

  FSelectedTurnoIdx := Integer(FTurnoListBox.Items.Objects[Idx]);
  CloseTurnoDropDown;

  // Actualizar text
  if FSelectedTurnoIdx < 0 then
    FLblTurnoText.Caption := 'Todos los turnos'
  else if FSelectedTurnoIdx <= High(FTurnos) then
    FLblTurnoText.Caption := FTurnos[FSelectedTurnoIdx].Nombre;

  BuildCentrePanels;
end;

procedure TfrmCuadroPlanificacionDelDia.CloseTurnoDropDown;
begin
  if (FTurnoDropDown <> nil) and FTurnoDropDown.Visible then
    FTurnoDropDown.Hide;
end;

procedure TfrmCuadroPlanificacionDelDia.BuildTurnoCombo;
begin
  FSelectedTurnoIdx := -1;
  FLblTurnoText.Caption := 'Todos los turnos';
  FPnlTurnoBtn.Visible := Length(FTurnos) > 0;
  FLblTurnoCaption.Visible := FPnlTurnoBtn.Visible;
end;

function TfrmCuadroPlanificacionDelDia.IsNodeInTurno(
  const NStart: TDateTime): Boolean;
var
  NodeMinute, TurnoIni, TurnoFin: Integer;
  T: TTurno;
begin
  if FSelectedTurnoIdx < 0 then
    Exit(True);
  if FSelectedTurnoIdx > High(FTurnos) then
    Exit(True);

  T := FTurnos[FSelectedTurnoIdx];
  NodeMinute := HourOf(NStart) * 60 + MinuteOf(NStart);
  TurnoIni := HourOf(T.HoraInicio) * 60 + MinuteOf(T.HoraInicio);
  TurnoFin := HourOf(T.HoraFin) * 60 + MinuteOf(T.HoraFin);

  if TurnoFin > TurnoIni then
    Result := (NodeMinute >= TurnoIni) and (NodeMinute < TurnoFin)
  else
    Result := (NodeMinute >= TurnoIni) or (NodeMinute < TurnoFin);
end;

{ --- Drag de columnas --- }

procedure TfrmCuadroPlanificacionDelDia.OnColDragBegin(Sender: TObject);
begin
  FColDragging := True;
  FColDragPanel := Sender as TCentrePanel;
  FColDragStartX := FColDragPanel.Left;
  FColDragPanel.BringToFront;
  Screen.Cursor := crSizeWE;
  MouseCapture := True;
end;

procedure TfrmCuadroPlanificacionDelDia.DoColDragMove(const ScreenPt: TPoint);
var
  LocalPt: TPoint;
  I, DragIdx, TargetIdx: Integer;
  Tmp: TCentrePanel;
begin
  if not FColDragging then Exit;

  LocalPt := FScrollBox.ScreenToClient(ScreenPt);
  FColDragPanel.Left := LocalPt.X - FColDragPanel.Width div 2;

  // Determinar indice actual y destino
  DragIdx := FCentrePanels.IndexOf(FColDragPanel);
  TargetIdx := DragIdx;

  for I := 0 to FCentrePanels.Count - 1 do
  begin
    if I = DragIdx then Continue;
    if (LocalPt.X > FCentrePanels[I].Left) and
       (LocalPt.X < FCentrePanels[I].Left + FCentrePanels[I].Width) then
    begin
      TargetIdx := I;
      Break;
    end;
  end;

  // Swap si cambio de posicion
  if TargetIdx <> DragIdx then
  begin
    FCentrePanels.Exchange(DragIdx, TargetIdx);
    LayoutPanels;
    FColDragPanel.BringToFront;
  end;
end;

procedure TfrmCuadroPlanificacionDelDia.DoColDragEnd;
begin
  if not FColDragging then Exit;
  FColDragging := False;
  FColDragPanel := nil;
  Screen.Cursor := crDefault;
  MouseCapture := False;
  LayoutPanels;
end;

{ --- Comparativa turnos --- }

function TfrmCuadroPlanificacionDelDia.CalcTurnoKPI(
  const ATurno: TTurno): TTurnoKPIData;
var
  AllData: TArray<TNodeData>;
  I: Integer;
  NStart, NEnd: TDateTime;
  DayStart, DayEnd: TDateTime;
  NodeMin, TI, TF: Integer;
  InTurno: Boolean;
  HrsReal, TotalDurPlan, TotalDurAvance: Double;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.TurnoNombre := ATurno.Nombre;
  Result.TurnoFranja := FormatDateTime('hh:nn', ATurno.HoraInicio) + ' - ' +
    FormatDateTime('hh:nn', ATurno.HoraFin);
  Result.TurnoColor := ATurno.Color;
  if FNodeRepo = nil then Exit;

  DayStart := Trunc(FToday);
  DayEnd := DayStart + 1;
  AllData := FNodeRepo.GetAllData;
  TI := HourOf(ATurno.HoraInicio) * 60 + MinuteOf(ATurno.HoraInicio);
  TF := HourOf(ATurno.HoraFin) * 60 + MinuteOf(ATurno.HoraFin);
  TotalDurPlan := 0;
  TotalDurAvance := 0;

  for I := 0 to High(AllData) do
  begin
    if not FGetNodeTimes(AllData[I].DataId, NStart, NEnd) then Continue;
    if (NEnd <= DayStart) or (NStart >= DayEnd) then Continue;

    NodeMin := HourOf(NStart) * 60 + MinuteOf(NStart);
    if TF > TI then
      InTurno := (NodeMin >= TI) and (NodeMin < TF)
    else
      InTurno := (NodeMin >= TI) or (NodeMin < TF);
    if not InTurno then Continue;

    Inc(Result.TotalOps);
    if AllData[I].Estado = neFinalizado then
      Inc(Result.OpsFinalizadas);

    Result.UnidadesPlan := Result.UnidadesPlan + AllData[I].UnidadesAFabricar;
    Result.UnidadesReal := Result.UnidadesReal + AllData[I].UnidadesFabricadas;
    Result.HorasPlan := Result.HorasPlan + (AllData[I].DurationMin / 60.0);

    HrsReal := 0;
    if AllData[I].TiempoUnidadFabSecs > 0 then
      HrsReal := AllData[I].UnidadesFabricadas * AllData[I].TiempoUnidadFabSecs / 3600.0
    else if (AllData[I].UnidadesAFabricar > 0) and (AllData[I].DurationMin > 0) then
      HrsReal := AllData[I].UnidadesFabricadas *
        (AllData[I].DurationMin / AllData[I].UnidadesAFabricar) / 60.0;
    Result.HorasReal := Result.HorasReal + HrsReal;

    Result.OperariosNec := Result.OperariosNec + AllData[I].OperariosNecesarios;
    Result.OperariosAsig := Result.OperariosAsig + AllData[I].OperariosAsignados;

    TotalDurPlan := TotalDurPlan + AllData[I].DurationMin;
    if AllData[I].UnidadesAFabricar > 0 then
      TotalDurAvance := TotalDurAvance +
        AllData[I].DurationMin * (AllData[I].UnidadesFabricadas / AllData[I].UnidadesAFabricar);
  end;

  if Result.UnidadesPlan > 0 then
    Result.EficienciaProd := (Result.UnidadesReal / Result.UnidadesPlan) * 100.0;
  if TotalDurPlan > 0 then
    Result.AvancePct := (TotalDurAvance / TotalDurPlan) * 100.0;

  // OEE simplificado = Disponibilidad x Rendimiento (sin calidad)
  if (Result.HorasPlan > 0) and (Result.UnidadesPlan > 0) then
    Result.OEE := (Result.HorasReal / Result.HorasPlan) *
                  (Result.UnidadesReal / Result.UnidadesPlan) * 100.0;
end;

procedure TfrmCuadroPlanificacionDelDia.UpdateTurnoCompare;
var
  I, N: Integer;
  Data: TArray<TTurnoKPIData>;
begin
  N := 0;
  for I := 0 to High(FTurnos) do
    if FTurnos[I].Activo then Inc(N);

  SetLength(Data, N);
  N := 0;
  for I := 0 to High(FTurnos) do
  begin
    if not FTurnos[I].Activo then Continue;
    Data[N] := CalcTurnoKPI(FTurnos[I]);
    Inc(N);
  end;

  FTurnoComparePanel.FTheme := FTheme;
  FTurnoComparePanel.SetData(Data);
end;

procedure TfrmCuadroPlanificacionDelDia.OnToggleCompareClick(Sender: TObject);
begin
  FTurnoCompareVisible := not FTurnoCompareVisible;
  if FTurnoCompareVisible then
  begin
    pnlTurnoCompare.Height := 420;
    pnlTurnoCompare.Visible := True;
    FLblToggleCompare.Caption := 'Ocultar comparativa';
    UpdateTurnoCompare;
  end
  else
  begin
    pnlTurnoCompare.Visible := False;
    pnlTurnoCompare.Height := 0;
    FLblToggleCompare.Caption := 'Comparar turnos';
  end;
end;

{ --- Tema oscuro/claro --- }

function TfrmCuadroPlanificacionDelDia.GetLightTheme: TThemeColors;
begin
  Result.FormBg         := $00F0F0F0;
  Result.HeaderBg       := clWhite;
  Result.HeaderText     := $00333333;
  Result.DateText       := $00FF6040;  // azul vivo
  Result.FilterBarBg    := $00F0F0F0;
  Result.FilterBtnBg    := clWhite;
  Result.FilterText     := $00555555;
  Result.GlobalKPIBg    := clWhite;
  Result.GlobalKPILabel := $00888888;
  Result.GlobalKPISep   := $00DDDDDD;
  Result.GlobalKPILine  := $00E0E0E0;
  Result.ContentBg      := $00F0F0F0;
  Result.FooterBg       := $00E2EDE8;
  Result.FooterText     := $00888888;
  Result.PanelBg        := $00F4F4F4;
  Result.KPIBg          := $00FAFAFA;
  Result.KPIBorder      := $00E0E0E0;
  Result.KPILabel       := $00888888;
  Result.KPIPlanText    := $00555555;
  Result.KPIRealText    := $00333333;
  Result.BarTrack       := $00E8E8E8;
  Result.CardBg         := clWhite;
  Result.CardBgHover    := $00F0F0F0;
  Result.CardBgFinished := $00E8F5E0;
  Result.CardBorderFinished := $0080C880;
  Result.CardBorder     := $00E0E0E0;
  Result.CardTitle      := $00333333;
  Result.CardSubtext    := $00666666;
  Result.CardDimText    := $00999999;
  Result.CardSepLine    := $00E0E0E0;
  Result.SBTrack        := $00F0F0F0;
  Result.SBThumb        := $00C8C8C8;
end;

function TfrmCuadroPlanificacionDelDia.GetDarkTheme: TThemeColors;
begin
  Result.FormBg         := $00282828;
  Result.HeaderBg       := $00202020;
  Result.HeaderText     := $00E0E0E0;
  Result.DateText       := $0060B0FF;
  Result.FilterBarBg    := $00282828;
  Result.FilterBtnBg    := $00383838;
  Result.FilterText     := $00C0C0C0;
  Result.GlobalKPIBg    := $00252525;
  Result.GlobalKPILabel := $00909090;
  Result.GlobalKPISep   := $00404040;
  Result.GlobalKPILine  := $00383838;
  Result.ContentBg      := $00282828;
  Result.FooterBg       := $00202020;
  Result.FooterText     := $00909090;
  Result.PanelBg        := $00303030;
  Result.KPIBg          := $00282828;
  Result.KPIBorder      := $00404040;
  Result.KPILabel       := $00909090;
  Result.KPIPlanText    := $00B0B0B0;
  Result.KPIRealText    := $00E0E0E0;
  Result.BarTrack       := $00404040;
  Result.CardBg         := $00353535;
  Result.CardBgHover    := $00404040;
  Result.CardBgFinished := $00283828;
  Result.CardBorderFinished := $00408040;
  Result.CardBorder     := $00484848;
  Result.CardTitle      := $00E0E0E0;
  Result.CardSubtext    := $00B0B0B0;
  Result.CardDimText    := $00808080;
  Result.CardSepLine    := $00484848;
  Result.SBTrack        := $00383838;
  Result.SBThumb        := $00606060;
end;

procedure TfrmCuadroPlanificacionDelDia.ApplyTheme;
var
  I: Integer;
begin
  if FDarkMode then
    FTheme := GetDarkTheme
  else
    FTheme := GetLightTheme;

  // Form
  Color := FTheme.FormBg;

  // Header
  pnlHeader.Color := FTheme.HeaderBg;
  lblTitle.Font.Color := FTheme.HeaderText;
  lblFechaHoy.Font.Color := FTheme.DateText;
  pnlHeaderButtons.Color := FTheme.HeaderBg;

  // Separator
  pnlSeparator.Color := FTheme.GlobalKPILine;

  // Filter bar
  pnlFilterBar.Color := FTheme.FilterBarBg;
  lblFilterCaption.Font.Color := FTheme.KPILabel;
  pnlFilterBtn.Color := FTheme.FilterBtnBg;
  lblFilterText.Font.Color := FTheme.FilterText;
  lblFilterArrow.Font.Color := FTheme.KPILabel;
  FLblProfileCaption.Font.Color := FTheme.KPILabel;
  FPnlProfileBtn.Color := FTheme.FilterBtnBg;
  FLblProfileText.Font.Color := FTheme.FilterText;
  FLblProfileArrow.Font.Color := FTheme.KPILabel;
  FLblTurnoCaption.Font.Color := FTheme.KPILabel;
  FPnlTurnoBtn.Color := FTheme.FilterBtnBg;
  FLblTurnoText.Font.Color := FTheme.FilterText;
  FLblTurnoArrow.Font.Color := FTheme.KPILabel;

  // Toggle comparativa
  if FDarkMode then
  begin
    FBtnToggleCompare.Color := $00404040;
    FLblToggleCompare.Font.Color := $00C0C0C0;
  end
  else
  begin
    FBtnToggleCompare.Color := $00D0D0D0;
    FLblToggleCompare.Font.Color := $00444444;
  end;

  // Panel comparativa turnos
  pnlTurnoCompare.Color := FTheme.GlobalKPIBg;
  FTurnoComparePanel.FTheme := FTheme;
  if FTurnoCompareVisible then
    UpdateTurnoCompare;

  // Global KPIs
  pnlGlobalKPIs.Color := FTheme.GlobalKPIBg;
  FGlobalKPIPanel.FTheme := FTheme;
  FGlobalKPIPanel.Invalidate;

  // Content
  pnlContent.Color := FTheme.ContentBg;
  FScrollBox.Color := FTheme.ContentBg;

  // Footer
  pnlFooter.Color := FTheme.FooterBg;
  lblFooterInfo.Font.Color := FTheme.FooterText;

  // Dark mode toggle visual
  if FDarkMode then
  begin
    FBtnDarkMode.Color := $00404040;
    FLblDarkMode.Caption := Char($2600) + ' Claro';
    FLblDarkMode.Font.Color := $00FFD060;
    FLblDarkMode.Font.Size := 10;
  end
  else
  begin
    FBtnDarkMode.Color := $00D0D0D0;
    FLblDarkMode.Caption := Char($263D) + ' Oscuro';
    FLblDarkMode.Font.Color := $00444444;
    FLblDarkMode.Font.Size := 10;
  end;

  // Centre panels
  for I := 0 to FCentrePanels.Count - 1 do
  begin
    FCentrePanels[I].FTheme := FTheme;
    FCentrePanels[I].Invalidate;
  end;
end;

procedure TfrmCuadroPlanificacionDelDia.OnDarkModeClick(Sender: TObject);
begin
  FDarkMode := not FDarkMode;
  ApplyTheme;
end;

{ --- Datos demo --- }

procedure TfrmCuadroPlanificacionDelDia.btnLoadDemoClick(Sender: TObject);
begin
  LoadDemoData;
end;

procedure TfrmCuadroPlanificacionDelDia.LoadDemoData;
const
  NUM_CENTRES = 5;
  CENTRE_NAMES: array[0..NUM_CENTRES-1] of string = (
    'Corte', 'Soldadura', 'Pintura', 'Montaje', 'Embalaje');
  CENTRE_SUBTITLES: array[0..NUM_CENTRES-1] of string = (
    'Laser CNC L-200', 'Robot MIG R-450', 'Cabina Pintura CP-1',
    'Linea Montaje LM-3', 'Zona Embalaje ZE-2');
  CENTRE_COLORS: array[0..NUM_CENTRES-1] of TColor = (
    $00D08040, $004080D0, $0040A040, $008040D0, $00D04080);

  // Operaciones distintas por centro
  OPS_CORTE: array[0..3] of string = (
    'Corte laser chapa', 'Corte tubo', 'Troquelado', 'Desbarbado');
  OPS_SOLDADURA: array[0..3] of string = (
    'Soldadura MIG', 'Soldadura TIG', 'Soldadura por puntos', 'Repaso cordones');
  OPS_PINTURA: array[0..3] of string = (
    'Imprimacion', 'Pintura base', 'Lacado final', 'Secado horno');
  OPS_MONTAJE: array[0..3] of string = (
    'Premontaje sub-conj.', 'Montaje final', 'Ajuste mecanico', 'Cableado electrico');
  OPS_EMBALAJE: array[0..3] of string = (
    'Inspeccion visual', 'Embalaje carton', 'Flejado palet', 'Etiquetado envio');

  ARTS: array[0..7] of string = (
    'CHAPA-3MM', 'TUBO-50X30', 'PERF-L40', 'PLACA-BASE',
    'CONJ-A12', 'MOTOR-B7', 'BAST-220', 'CAJA-EXT');
  ART_DESC: array[0..7] of string = (
    'Chapa acero 3mm', 'Tubo rectangular 50x30', 'Perfil L 40mm',
    'Placa base mecanizada', 'Conjunto soldado A12', 'Motor electrico B7',
    'Bastidor 220cm', 'Caja exterior pintada');
var
  I, J, DataId, NPerCentre, ArtIdx, R: Integer;
  ND: TNodeData;
  DayStart: TDateTime;
  StartMin, DurMin: Double;
  UdsAPlan, UdsFab: Double;
  CentreId: Integer;
  OpName: string;
begin
  FreeAndNil(FDemoTimes);
  FreeAndNil(FOwnedNodeRepo);

  FOwnedNodeRepo := TNodeDataRepo.Create;
  FDemoTimes := TDictionary<Integer, TPair<TDateTime, TDateTime>>.Create;
  FNodeRepo := FOwnedNodeRepo;

  // Crear centros demo
  SetLength(FCentres, NUM_CENTRES);
  for I := 0 to NUM_CENTRES - 1 do
  begin
    FCentres[I].Id := I + 1;
    FCentres[I].CodiCentre := Format('CT%d', [I + 1]);
    FCentres[I].Titulo := CENTRE_NAMES[I];
    FCentres[I].Subtitulo := CENTRE_SUBTITLES[I];
    FCentres[I].Visible := True;
    FCentres[I].Enabled := True;
    FCentres[I].BkColor := CENTRE_COLORS[I];
    FCentres[I].Order := I;
    FCentres[I].IsSequencial := True;
    FCentres[I].MaxLaneCount := 1;
    FCentres[I].BaseHeight := 40;
    FCentres[I].Area := 'Produccion';
  end;

  DayStart := Trunc(FToday);
  DataId := 1;
  Randomize;

  for I := 0 to High(FCentres) do
  begin
    CentreId := FCentres[I].Id;
    NPerCentre := 4 + Random(5); // 4..8 operaciones por centro
    StartMin := 420 + Random(60); // entre 07:00 y 08:00

    for J := 0 to NPerCentre - 1 do
    begin
      FillChar(ND, SizeOf(ND), 0);
      ND.DataId := DataId;
      ND.NumeroOrdenFabricacion := 1000 + DataId;
      ND.SerieFabricacion := 'A';

      // Operacion especifica del centro
      case I of
        0: OpName := OPS_CORTE[Random(Length(OPS_CORTE))];
        1: OpName := OPS_SOLDADURA[Random(Length(OPS_SOLDADURA))];
        2: OpName := OPS_PINTURA[Random(Length(OPS_PINTURA))];
        3: OpName := OPS_MONTAJE[Random(Length(OPS_MONTAJE))];
        4: OpName := OPS_EMBALAJE[Random(Length(OPS_EMBALAJE))];
      else
        OpName := 'Operacion';
      end;
      ND.Operacion := OpName;

      ArtIdx := Random(Length(ARTS));
      ND.CodigoArticulo := ARTS[ArtIdx];
      ND.DescripcionArticulo := ART_DESC[ArtIdx];
      ND.CodigoCliente := Format('CLI-%d', [Random(10) + 1]);

      // Asignar exclusivamente a este centro
      SetLength(ND.CentresPermesos, 1);
      ND.CentresPermesos[0] := CentreId;

      DurMin := 25 + Random(95);  // 25..120 min
      ND.DurationMin := DurMin;
      ND.DurationMinOriginal := DurMin;

      UdsAPlan := 40 + Random(260);  // 40..300 uds
      ND.UnidadesAFabricar := UdsAPlan;
      ND.TiempoUnidadFabSecs := (DurMin * 60) / UdsAPlan;
      ND.OperariosNecesarios := 1 + Random(3);

      // Estado: las primeras operaciones del dia ya finalizadas,
      // las del medio en curso, las ultimas pendientes
      R := Random(10);
      if J < (NPerCentre div 3) then
      begin
        // Primeras: finalizadas (100% fabricado)
        ND.Estado := neFinalizado;
        ND.UnidadesFabricadas := UdsAPlan;
        ND.OperariosAsignados := ND.OperariosNecesarios;
      end
      else if J < (NPerCentre * 2 div 3) then
      begin
        // Medio: en curso (progreso parcial 40-90%)
        ND.Estado := neEnCurso;
        UdsFab := UdsAPlan * (0.4 + Random * 0.5);
        ND.UnidadesFabricadas := Round(UdsFab);
        ND.OperariosAsignados := Max(1, ND.OperariosNecesarios - Random(2));
      end
      else
      begin
        // Ultimas: pendientes o bloqueadas (0-15% avance)
        if R < 2 then
        begin
          ND.Estado := neBloqueado;
          UdsFab := UdsAPlan * Random * 0.10;
          ND.UnidadesFabricadas := Round(UdsFab);
          ND.OperariosAsignados := Random(2);
        end
        else
        begin
          ND.Estado := nePendiente;
          ND.UnidadesFabricadas := 0;
          ND.OperariosAsignados := 0;
        end;
      end;

      ND.Prioridad := 1 + Random(3);
      ND.FechaEntrega := DayStart + 1 + Random(5);
      ND.Tipo := ntOF;

      FOwnedNodeRepo.AddOrUpdate(ND);

      FDemoTimes.Add(DataId, TPair<TDateTime, TDateTime>.Create(
        DayStart + StartMin / 1440.0,
        DayStart + (StartMin + DurMin) / 1440.0));

      StartMin := StartMin + DurMin + 5 + Random(15);
      Inc(DataId);
    end;
  end;

  // Callback de tiempos
  FGetNodeTimes := function(const ADataId: Integer;
    out AStart, AEnd: TDateTime): Boolean
  begin
    Result := FDemoTimes.ContainsKey(ADataId);
    if Result then
    begin
      AStart := FDemoTimes[ADataId].Key;
      AEnd := FDemoTimes[ADataId].Value;
    end;
  end;

  // Reinicializar filtro
  FVisibleCentreIds.Clear;
  for I := 0 to High(FCentres) do
    if FCentres[I].Visible and (FCentres[I].Id >= 0) then
      FVisibleCentreIds.Add(FCentres[I].Id);

  // Turnos demo
  SetLength(FTurnos, 3);
  FTurnos[0].Id := 1;  FTurnos[0].Nombre := 'Mañana';
  FTurnos[0].HoraInicio := EncodeTime(6, 0, 0, 0);
  FTurnos[0].HoraFin := EncodeTime(14, 0, 0, 0);
  FTurnos[0].Color := $0058B0FF;  FTurnos[0].Activo := True;  FTurnos[0].Order := 0;
  FTurnos[1].Id := 2;  FTurnos[1].Nombre := 'Tarde';
  FTurnos[1].HoraInicio := EncodeTime(14, 0, 0, 0);
  FTurnos[1].HoraFin := EncodeTime(22, 0, 0, 0);
  FTurnos[1].Color := $00FFA858;  FTurnos[1].Activo := True;  FTurnos[1].Order := 1;
  FTurnos[2].Id := 3;  FTurnos[2].Nombre := 'Noche';
  FTurnos[2].HoraInicio := EncodeTime(22, 0, 0, 0);
  FTurnos[2].HoraFin := EncodeTime(6, 0, 0, 0);
  FTurnos[2].Color := $00886644;  FTurnos[2].Activo := True;  FTurnos[2].Order := 2;

  UpdateFilterText;
  BuildTurnoCombo;
  BuildCentrePanels;
end;

{ --- Punto de entrada --- }

class procedure TfrmCuadroPlanificacionDelDia.Execute(
  ANodeRepo: TNodeDataRepo;
  const ACentres: TArray<TCentreTreball>;
  AGetNodeTimes: TGetNodeTimesFunc;
  AGetCalendar: TGetCalendarFunc;
  const ATurnos: TArray<TTurno>);
var
  F: TfrmCuadroPlanificacionDelDia;
  I: Integer;
begin
  F := TfrmCuadroPlanificacionDelDia.Create(nil);
  try
    F.FNodeRepo := ANodeRepo;
    F.FCentres := ACentres;
    F.FGetNodeTimes := AGetNodeTimes;
    F.FGetCalendar := AGetCalendar;
    F.FTurnos := Copy(ATurnos);

    // Inicializar todos los centros como visibles
    for I := 0 to High(ACentres) do
      if ACentres[I].Visible and (ACentres[I].Id >= 0) then
        F.FVisibleCentreIds.Add(ACentres[I].Id);

    F.UpdateFilterText;
    F.BuildTurnoCombo;
    F.BuildCentrePanels;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

class procedure TfrmCuadroPlanificacionDelDia.ExecuteDemo;
var
  F: TfrmCuadroPlanificacionDelDia;
begin
  F := TfrmCuadroPlanificacionDelDia.Create(nil);
  try
    F.FNodeRepo := nil;
    F.LoadDemoData;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

end.
