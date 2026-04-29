unit uCentresKPI;

// Formulario modal con KPIs detallados del centro seleccionado.
// Tres bloques temporales:
//   A = ventana visible del Gantt   (StartVisibleTime .. EndVisibleTime)
//   B = desde ahora hasta fin Gantt (Now .. EndTime)
//   C = todo el Gantt               (StartTime .. EndTime)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections, System.Math, System.Types, DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls,
  cxCheckComboBox, cxCheckBox, cxEdit, cxLookAndFeelPainters,
  uGanttTypes, uGanttControl, uCentreCalendar,
  uNodeDataRepo, uOperariosRepo, uOperariosTypes, cxGraphics, cxControls,
  cxLookAndFeels, cxContainer, dxSkinsCore, dxSkinBasic, dxSkinBlack,
  dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
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
  dxSkinXmas2008Blue, cxTextEdit, cxMaskEdit, cxDropDownEdit;

type
  TKPIKind = (kkInt, kkFloat, kkHours, kkPercent, kkText);
  TKPIColoring = (kcNeutral, kcCarga, kcDisponibilidad, kcOriginal,
                  kcOptimizado, kcNoOptimizado, kcMuted);

  TKPICard = class
  private
    FParent: TWinControl;
    FCaption: string;
    FValue: string;
    FValueF: Double;   // para la barra (0..100 si aplica)
    FShowBar: Boolean;
    FKind: TKPIKind;
    FColoring: TKPIColoring;
    procedure DoPaint(Sender: TObject);
    function GetValueColor: TColor;
    function GetBarColorFill: TColor;
  public
    FPaintBox: TPaintBox;  // publico: usado por el panel info para ocultar/mostrar
    constructor Create(AParent: TWinControl; const ALeft, ATop, AWidth: Integer;
      const ACaption: string; AKind: TKPIKind; AColoring: TKPIColoring;
      AShowBar: Boolean);
    procedure SetValueText(const AText: string); overload;
    procedure SetValueText(const AText: string; AValue: Double); overload;
    procedure SetMuted;
    procedure Refresh;
  end;

  TBlockCards = record
    // Carga
    PercCarga, PercDisponibilidad: TKPICard;
    HorasOcupadas, HorasLaborables, HorasNoLaborables: TKPICard;
    // Actividad
    NumNodes, DuracionMedia, NodoMasLargo, NodoMasCorto: TKPICard;
    PrimerNodo, UltimoNodo: TKPICard;
    NodosOriginales, NodosOptimizados, NodosNoOptimizados: TKPICard;
    // Recursos
    OperariosTotal, OperariosDistinct: TKPICard;
    MoldesTotal, MoldesDistinct: TKPICard;
    UtilajesTotal, UtilajesDistinct: TKPICard;
  end;

  TfrmCentresKPI = class(TForm)
    pnlLeft: TPanel;
    pnlCentroSel: TPanel;
    lblCentroCap: TLabel;
    cbCentros: TcxCheckComboBox;
    btnToggleAll: TButton;
    pnlInfo: TPanel;
    lblTituloInfo: TLabel;
    PageControl1: TPageControl;
    tsBloqueA: TTabSheet;
    tsBloqueB: TTabSheet;
    tsBloqueC: TTabSheet;
    pnlBottom: TPanel;
    btnCerrar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cbCentrosChange(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnToggleAllClick(Sender: TObject);
  private
    FCentres: TArray<TCentreTreball>;
    FGanttControl: TGanttControl;
    FNodeRepo: TNodeDataRepo;
    FOperariosRepo: TOperariosRepo;
    FBlockA, FBlockB, FBlockC: TBlockCards;
    FCards: TList<TKPICard>;
    FInfoCards: TList<TKPICard>;
    FInfoCentroCards: array[0..4] of TKPICard;   // Id, Codigo, Titulo, Subtitulo, Area
    FInfoCalCards:    array[0..2] of TKPICard;   // Nombre, Horario LV, Fin semana
    FInfoResumenCard: TKPICard;                  // "Agregado de N centros"
    procedure BuildInfoPanel;
    procedure BuildBlockTab(ATab: TTabSheet; const AWindowCaption: string;
      var ABlock: TBlockCards);
    function GetSelectedCentres: TArray<TCentreTreball>;
    procedure FillInfo(const ASelected: TArray<TCentreTreball>);
    procedure FillBlock(const ASelected: TArray<TCentreTreball>;
      const AWindowStart, AWindowEnd: TDateTime;
      var ABlock: TBlockCards);
    procedure RecalcularTodo;
  public
    destructor Destroy; override;
    class procedure Execute(AOwner: TComponent;
      const ACentres: TArray<TCentreTreball>;
      AGanttControl: TGanttControl;
      ANodeRepo: TNodeDataRepo;
      AOperariosRepo: TOperariosRepo;
      AInitialCentreIdx: Integer = -1);
  end;

implementation

{$R *.dfm}

// =====================================================================
//  Helpers
// =====================================================================

function MinuteSpan(const A, B: TDateTime): Double; inline;
begin
  Result := (B - A) * 24 * 60;
  if Result < 0 then Result := 0;
end;

// Lerp entre dos colores RGB segun t en [0..1].
function LerpColor(C1, C2: TColor; T: Double): TColor;
var
  R1, G1, B1, R2, G2, B2: Byte;
  R, G, B: Byte;
begin
  if T < 0 then T := 0 else if T > 1 then T := 1;
  R1 := GetRValue(ColorToRGB(C1)); G1 := GetGValue(ColorToRGB(C1)); B1 := GetBValue(ColorToRGB(C1));
  R2 := GetRValue(ColorToRGB(C2)); G2 := GetGValue(ColorToRGB(C2)); B2 := GetBValue(ColorToRGB(C2));
  R := Round(R1 + (R2 - R1) * T);
  G := Round(G1 + (G2 - G1) * T);
  B := Round(B1 + (B2 - B1) * T);
  Result := RGB(R, G, B);
end;

// Color de semaforo segun valor [0..100]: verde -> ambar -> rojo -> violeta (>100).
function ColorForLoad(APercent: Double): TColor;
const
  clVerde   = TColor($0070B050);  // BGR
  clAmbar   = TColor($0020A5DA);
  clRojo    = TColor($004040D0);
  clViolet  = TColor($00A040A0);
var
  T: Double;
begin
  if APercent <= 60 then
  begin
    T := APercent / 60;
    Result := LerpColor(clVerde, clAmbar, T * 0.5);
  end
  else if APercent <= 85 then
  begin
    T := (APercent - 60) / 25;
    Result := LerpColor(clAmbar, clRojo, T);
  end
  else if APercent <= 100 then
  begin
    T := (APercent - 85) / 15;
    Result := LerpColor(clRojo, clViolet, T * 0.4);
  end
  else
    Result := clViolet;
end;

// Inverso para disponibilidad: rojo (0%) -> verde (100%).
function ColorForAvailability(APercent: Double): TColor;
const
  clVerde = TColor($0070B050);
  clAmbar = TColor($0020A5DA);
  clRojo  = TColor($004040D0);
begin
  if APercent <= 15 then
    Result := clRojo
  else if APercent <= 40 then
    Result := LerpColor(clRojo, clAmbar, (APercent - 15) / 25)
  else
    Result := LerpColor(clAmbar, clVerde, Min(1.0, (APercent - 40) / 60));
end;

// Pinta un rectangulo con esquinas redondeadas (soft).
procedure DrawRoundBar(ACanvas: TCanvas; const R: TRect; AFill: TColor;
  ARadius: Integer = 4);
begin
  ACanvas.Brush.Color := AFill;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, ARadius, ARadius);
  ACanvas.Pen.Style := psSolid;
end;

// =====================================================================
//  TKPICard — tarjeta individual con capcalera, valor y barra opcional
// =====================================================================

constructor TKPICard.Create(AParent: TWinControl;
  const ALeft, ATop, AWidth: Integer;
  const ACaption: string; AKind: TKPIKind; AColoring: TKPIColoring;
  AShowBar: Boolean);
begin
  inherited Create;
  FParent   := AParent;
  FCaption  := ACaption;
  FKind     := AKind;
  FColoring := AColoring;
  FShowBar  := AShowBar;
  FValue    := '-';
  FValueF   := 0;

  FPaintBox := TPaintBox.Create(AParent);
  FPaintBox.Parent := AParent;
  FPaintBox.Left   := ALeft;
  FPaintBox.Top    := ATop;
  FPaintBox.Width  := AWidth;
  if AShowBar then
    FPaintBox.Height := 62
  else
    FPaintBox.Height := 44;
  FPaintBox.OnPaint := DoPaint;
end;

function TKPICard.GetValueColor: TColor;
begin
  case FColoring of
    kcCarga:          Result := ColorForLoad(FValueF);
    kcDisponibilidad: Result := ColorForAvailability(FValueF);
    kcOriginal:       Result := TColor($00AA6428);   // azul cal oscuro
    kcOptimizado:     Result := TColor($0070B050);   // verde
    kcNoOptimizado:   Result := TColor($004040D0);   // rojo
    kcMuted:          Result := clGrayText;
  else
    Result := TColor($00404040);  // gris fosc
  end;
end;

function TKPICard.GetBarColorFill: TColor;
begin
  case FColoring of
    kcCarga:          Result := ColorForLoad(FValueF);
    kcDisponibilidad: Result := ColorForAvailability(FValueF);
  else
    Result := TColor($00808080);
  end;
end;

procedure TKPICard.DoPaint(Sender: TObject);
var
  R, BarBG, BarFill: TRect;
  W: Integer;
  ValueFont: TFont;
begin
  R := FPaintBox.ClientRect;

  // Fondo card
  FPaintBox.Canvas.Brush.Color := TColor($00F8F8F8);
  FPaintBox.Canvas.Pen.Style := psClear;
  FPaintBox.Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 6, 6);
  FPaintBox.Canvas.Pen.Style := psSolid;

  // Caption (negrita, esq sup izq)
  FPaintBox.Canvas.Brush.Style := bsClear;
  FPaintBox.Canvas.Font.Name := 'Segoe UI';
  FPaintBox.Canvas.Font.Size := 9;
  FPaintBox.Canvas.Font.Style := [fsBold];
  FPaintBox.Canvas.Font.Color := TColor($00606060);
  FPaintBox.Canvas.TextOut(R.Left + 10, R.Top + 8, FCaption);

  // Value (a la derecha arriba, grande, color segun tipo)
  ValueFont := TFont.Create;
  try
    ValueFont.Assign(FPaintBox.Canvas.Font);
    ValueFont.Size := 13;
    ValueFont.Style := [fsBold];
    ValueFont.Color := GetValueColor;
    FPaintBox.Canvas.Font.Assign(ValueFont);
    W := FPaintBox.Canvas.TextWidth(FValue);
    FPaintBox.Canvas.TextOut(R.Right - W - 12, R.Top + 5, FValue);
  finally
    ValueFont.Free;
  end;

  // Barra (si aplica)
  if FShowBar then
  begin
    BarBG.Left   := R.Left + 10;
    BarBG.Right  := R.Right - 10;
    BarBG.Top    := R.Bottom - 18;
    BarBG.Bottom := R.Bottom - 8;

    // Fondo barra
    DrawRoundBar(FPaintBox.Canvas, BarBG, TColor($00E4E4E4), 4);

    // Relleno segun FValueF (0..100)
    BarFill := BarBG;
    BarFill.Right := BarBG.Left +
      Round((BarBG.Right - BarBG.Left) * Min(100.0, Max(0.0, FValueF)) / 100.0);
    if BarFill.Right > BarBG.Left + 2 then
      DrawRoundBar(FPaintBox.Canvas, BarFill, GetBarColorFill, 4);

    // Si FValueF > 100, aniade un borde violeta de "overload"
    if FValueF > 100 then
    begin
      FPaintBox.Canvas.Brush.Style := bsClear;
      FPaintBox.Canvas.Pen.Color := TColor($00A040A0);
      FPaintBox.Canvas.Pen.Width := 2;
      FPaintBox.Canvas.RoundRect(BarBG.Left, BarBG.Top, BarBG.Right, BarBG.Bottom, 4, 4);
      FPaintBox.Canvas.Pen.Width := 1;
    end;
  end;
end;

procedure TKPICard.SetValueText(const AText: string);
begin
  FValue  := AText;
  FValueF := 0;
  Refresh;
end;

procedure TKPICard.SetValueText(const AText: string; AValue: Double);
begin
  FValue  := AText;
  FValueF := AValue;
  Refresh;
end;

procedure TKPICard.SetMuted;
begin
  FValue    := '0  (no modelado)';
  FValueF   := 0;
  FColoring := kcMuted;
  Refresh;
end;

procedure TKPICard.Refresh;
begin
  FPaintBox.Invalidate;
end;

// =====================================================================
//  TfrmCentresKPI
// =====================================================================

class procedure TfrmCentresKPI.Execute(AOwner: TComponent;
  const ACentres: TArray<TCentreTreball>;
  AGanttControl: TGanttControl;
  ANodeRepo: TNodeDataRepo;
  AOperariosRepo: TOperariosRepo;
  AInitialCentreIdx: Integer);
var
  F: TfrmCentresKPI;
  I: Integer;
begin
  F := TfrmCentresKPI.Create(AOwner);
  try
    F.FCentres       := ACentres;
    F.FGanttControl  := AGanttControl;
    F.FNodeRepo      := ANodeRepo;
    F.FOperariosRepo := AOperariosRepo;

    F.cbCentros.Properties.Items.Clear;
    for I := 0 to High(ACentres) do
      F.cbCentros.Properties.Items.AddCheckItem(
        Format('[%d] %s', [ACentres[I].Id, ACentres[I].Titulo]));

    // Marcar el centro inicial (o el primero si no se especifica).
    if (AInitialCentreIdx >= 0) and (AInitialCentreIdx <= High(ACentres)) then
      F.cbCentros.States[AInitialCentreIdx] := cbsChecked
    else if Length(ACentres) > 0 then
      F.cbCentros.States[0] := cbsChecked;

    F.RecalcularTodo;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmCentresKPI.FormCreate(Sender: TObject);
begin
  KeyPreview := True;
  FCards := TList<TKPICard>.Create;
  FInfoCards := TList<TKPICard>.Create;
  BuildInfoPanel;
  BuildBlockTab(tsBloqueA, 'Ventana visible del Gantt', FBlockA);
  BuildBlockTab(tsBloqueB, 'Desde ahora hasta fin del Gantt', FBlockB);
  BuildBlockTab(tsBloqueC, 'Todo el Gantt (inicio a fin)', FBlockC);
end;

destructor TfrmCentresKPI.Destroy;
var
  I: Integer;
begin
  if FInfoCards <> nil then
  begin
    for I := 0 to FInfoCards.Count - 1 do
      FInfoCards[I].Free;
    FInfoCards.Free;
  end;
  if FCards <> nil then
  begin
    for I := 0 to FCards.Count - 1 do
      FCards[I].Free;
    FCards.Free;
  end;
  inherited;
end;

procedure TfrmCentresKPI.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

procedure TfrmCentresKPI.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmCentresKPI.btnToggleAllClick(Sender: TObject);
var
  I: Integer;
  AllChecked: Boolean;
  NewState: TcxCheckBoxState;
begin
  // Si todos ya estan marcados -> desmarcar todos. Sino -> marcar todos.
  AllChecked := cbCentros.Properties.Items.Count > 0;
  for I := 0 to cbCentros.Properties.Items.Count - 1 do
    if cbCentros.States[I] <> cbsChecked then
    begin
      AllChecked := False;
      Break;
    end;

  if AllChecked then
    NewState := cbsUnchecked
  else
    NewState := cbsChecked;

  for I := 0 to cbCentros.Properties.Items.Count - 1 do
    cbCentros.States[I] := NewState;

  if AllChecked then
    btnToggleAll.Caption := 'Todos'
  else
    btnToggleAll.Caption := 'Ninguno';

  RecalcularTodo;
end;

procedure TfrmCentresKPI.cbCentrosChange(Sender: TObject);
begin
  RecalcularTodo;
end;

procedure TfrmCentresKPI.BuildBlockTab(ATab: TTabSheet;
  const AWindowCaption: string; var ABlock: TBlockCards);

  function NewCard(AParent: TWinControl; ALeft, ATop, AWidth: Integer;
    const ACap: string; AKind: TKPIKind; AColoring: TKPIColoring;
    ABar: Boolean): TKPICard;
  begin
    Result := TKPICard.Create(AParent, ALeft, ATop, AWidth, ACap, AKind,
      AColoring, ABar);
    FCards.Add(Result);
  end;

const
  COL_W   = 340;
  GAP     = 14;
  MARGIN  = 14;
  GB_W    = 2 * COL_W + GAP + 2 * MARGIN;   // ancho interno GroupBox
  DY_CARD = 54;   // altura card sin barra + separacion
  DY_BAR  = 72;   // altura card con barra + separacion
var
  gbCarga, gbActividad, gbRecursos: TGroupBox;
  Hdr: TLabel;
  Y1, Y2: Integer;
  LeftCol, RightCol: Integer;
begin
  // Header ventana
  Hdr := TLabel.Create(ATab);
  Hdr.Parent := ATab;
  Hdr.Caption := 'Ventana: ' + AWindowCaption;
  Hdr.Font.Style := [fsBold];
  Hdr.Font.Size := 10;
  Hdr.Font.Color := TColor($00404040);
  Hdr.Left := 14;
  Hdr.Top  := 8;

  LeftCol  := MARGIN;
  RightCol := MARGIN + COL_W + GAP;

  // --- Grupo Carga ---
  gbCarga := TGroupBox.Create(ATab);
  gbCarga.Parent := ATab;
  gbCarga.Caption := ' Carga del centro ';
  gbCarga.Font.Style := [fsBold];
  gbCarga.Left := 10;
  gbCarga.Top  := 34;
  gbCarga.Width := GB_W + 4;
  gbCarga.Height := 180;

  Y1 := 26;
  ABlock.PercCarga := NewCard(gbCarga, LeftCol, Y1, COL_W,
    '% Carga', kkPercent, kcCarga, True);
  ABlock.PercDisponibilidad := NewCard(gbCarga, RightCol, Y1, COL_W,
    '% Disponibilidad de carga', kkPercent, kcDisponibilidad, True);

  Y1 := Y1 + DY_BAR;
  ABlock.HorasOcupadas := NewCard(gbCarga, LeftCol, Y1, COL_W,
    'Horas ocupadas', kkHours, kcNeutral, False);
  ABlock.HorasLaborables := NewCard(gbCarga, RightCol, Y1, COL_W,
    'Horas laborables', kkHours, kcNeutral, False);

  // --- Grupo Actividad ---
  gbActividad := TGroupBox.Create(ATab);
  gbActividad.Parent := ATab;
  gbActividad.Caption := ' Actividad ';
  gbActividad.Font.Style := [fsBold];
  gbActividad.Left := 10;
  gbActividad.Top  := gbCarga.Top + gbCarga.Height + 10;
  gbActividad.Width := GB_W + 4;
  gbActividad.Height := 290;

  Y2 := 26;
  ABlock.NumNodes := NewCard(gbActividad, LeftCol, Y2, COL_W,
    'Num. de nodos', kkInt, kcNeutral, False);
  ABlock.DuracionMedia := NewCard(gbActividad, RightCol, Y2, COL_W,
    'Duracion media (min)', kkFloat, kcNeutral, False);

  Y2 := Y2 + DY_CARD;
  ABlock.NodoMasLargo := NewCard(gbActividad, LeftCol, Y2, COL_W,
    'Nodo mas largo (min)', kkFloat, kcNeutral, False);
  ABlock.NodoMasCorto := NewCard(gbActividad, RightCol, Y2, COL_W,
    'Nodo mas corto (min)', kkFloat, kcNeutral, False);

  Y2 := Y2 + DY_CARD;
  ABlock.NodosOriginales := NewCard(gbActividad, LeftCol, Y2, COL_W,
    'Nodos originales', kkInt, kcOriginal, False);
  ABlock.NodosOptimizados := NewCard(gbActividad, RightCol, Y2, COL_W,
    'Nodos optimizados', kkInt, kcOptimizado, False);

  Y2 := Y2 + DY_CARD;
  ABlock.NodosNoOptimizados := NewCard(gbActividad, LeftCol, Y2, COL_W,
    'Nodos no optimizados', kkInt, kcNoOptimizado, False);
  ABlock.HorasNoLaborables := NewCard(gbActividad, RightCol, Y2, COL_W,
    'Horas no laborables', kkHours, kcMuted, False);

  Y2 := Y2 + DY_CARD;
  ABlock.PrimerNodo := NewCard(gbActividad, LeftCol, Y2, COL_W,
    'Primer nodo', kkText, kcNeutral, False);
  ABlock.UltimoNodo := NewCard(gbActividad, RightCol, Y2, COL_W,
    'Ultimo nodo', kkText, kcNeutral, False);

  // --- Grupo Recursos ---
  gbRecursos := TGroupBox.Create(ATab);
  gbRecursos.Parent := ATab;
  gbRecursos.Caption := ' Recursos ';
  gbRecursos.Font.Style := [fsBold];
  gbRecursos.Left := 10;
  gbRecursos.Top  := gbActividad.Top + gbActividad.Height + 10;
  gbRecursos.Width := GB_W + 4;
  gbRecursos.Height := 190;

  Y2 := 26;
  ABlock.OperariosTotal := NewCard(gbRecursos, LeftCol, Y2, COL_W,
    'Operarios asignados (total)', kkInt, kcNeutral, False);
  ABlock.OperariosDistinct := NewCard(gbRecursos, RightCol, Y2, COL_W,
    'Operarios distinct', kkInt, kcNeutral, False);

  Y2 := Y2 + DY_CARD;
  ABlock.MoldesTotal := NewCard(gbRecursos, LeftCol, Y2, COL_W,
    'Moldes asignados (total)', kkInt, kcMuted, False);
  ABlock.MoldesDistinct := NewCard(gbRecursos, RightCol, Y2, COL_W,
    'Moldes distinct', kkInt, kcMuted, False);

  Y2 := Y2 + DY_CARD;
  ABlock.UtilajesTotal := NewCard(gbRecursos, LeftCol, Y2, COL_W,
    'Utilajes asignados (total)', kkInt, kcMuted, False);
  ABlock.UtilajesDistinct := NewCard(gbRecursos, RightCol, Y2, COL_W,
    'Utilajes distinct', kkInt, kcMuted, False);
end;

procedure TfrmCentresKPI.BuildInfoPanel;

  function AddCard(const ACap: string; ATop: Integer;
    AColoring: TKPIColoring): TKPICard;
  begin
    Result := TKPICard.Create(pnlInfo, 8, ATop, 290, ACap, kkText, AColoring, False);
    FInfoCards.Add(Result);
  end;

var
  Hdr2: TLabel;
  Y: Integer;
begin
  // Cards del centro
  Y := 36;
  FInfoCentroCards[0] := AddCard('Id',         Y, kcNeutral);  Inc(Y, 50);
  FInfoCentroCards[1] := AddCard('Codigo',     Y, kcNeutral);  Inc(Y, 50);
  FInfoCentroCards[2] := AddCard('Titulo',     Y, kcNeutral);  Inc(Y, 50);
  FInfoCentroCards[3] := AddCard('Subtitulo',  Y, kcNeutral);  Inc(Y, 50);
  FInfoCentroCards[4] := AddCard('Area',       Y, kcNeutral);  Inc(Y, 54);

  // Separador "Calendario asociado"
  Hdr2 := TLabel.Create(pnlInfo);
  Hdr2.Parent := pnlInfo;
  Hdr2.Caption := 'Calendario asociado';
  Hdr2.Font.Style := [fsBold];
  Hdr2.Font.Size := 10;
  Hdr2.Font.Color := 4210752;
  Hdr2.Left := 8;
  Hdr2.Top  := Y;
  Inc(Y, 26);

  FInfoCalCards[0] := AddCard('Nombre',        Y, kcNeutral);  Inc(Y, 50);
  FInfoCalCards[1] := AddCard('Horario L-V',   Y, kcNeutral);  Inc(Y, 50);
  FInfoCalCards[2] := AddCard('Fin de semana', Y, kcNeutral);

  // Card de resumen multi-centro (inicialmente oculta)
  FInfoResumenCard := TKPICard.Create(pnlInfo, 8, 36, 290,
    'Centros seleccionados', kkText, kcOriginal, False);
  FInfoCards.Add(FInfoResumenCard);
  FInfoResumenCard.FPaintBox.Visible := False;
end;

function TfrmCentresKPI.GetSelectedCentres: TArray<TCentreTreball>;
var
  I, N: Integer;
begin
  SetLength(Result, cbCentros.Properties.Items.Count);
  N := 0;
  for I := 0 to cbCentros.Properties.Items.Count - 1 do
    if cbCentros.States[I] = cbsChecked then
    begin
      if I <= High(FCentres) then
      begin
        Result[N] := FCentres[I];
        Inc(N);
      end;
    end;
  SetLength(Result, N);
end;

procedure TfrmCentresKPI.FillInfo(const ASelected: TArray<TCentreTreball>);

  procedure ShowCards(AVisible: Boolean);
  var
    I: Integer;
  begin
    for I := 0 to High(FInfoCentroCards) do
      FInfoCentroCards[I].FPaintBox.Visible := AVisible;
    for I := 0 to High(FInfoCalCards) do
      FInfoCalCards[I].FPaintBox.Visible := AVisible;
  end;

var
  C: TCentreTreball;
  Cal: TCentreCalendar;
  LunesPeriods, SabP, DomP: TArray<TNonWorkingPeriod>;
  S: string;
  I: Integer;
  FullSab, FullDom: Boolean;
  Names: string;
begin
  // Sin seleccion
  if Length(ASelected) = 0 then
  begin
    ShowCards(False);
    FInfoResumenCard.FPaintBox.Visible := True;
    FInfoResumenCard.SetValueText('(ninguno)');
    Exit;
  end;

  // Multi-seleccion: resumen
  if Length(ASelected) > 1 then
  begin
    ShowCards(False);
    FInfoResumenCard.FPaintBox.Visible := True;

    Names := '';
    for I := 0 to High(ASelected) do
    begin
      if I > 0 then Names := Names + ', ';
      Names := Names + ASelected[I].Titulo;
    end;
    FInfoResumenCard.SetValueText(
      Format('%d centros: %s', [Length(ASelected), Names]));
    Exit;
  end;

  // Un solo centro: mostrar detalle
  FInfoResumenCard.FPaintBox.Visible := False;
  ShowCards(True);

  C := ASelected[0];
  FInfoCentroCards[0].SetValueText(IntToStr(C.Id));
  FInfoCentroCards[1].SetValueText(C.CodiCentre);
  FInfoCentroCards[2].SetValueText(C.Titulo);
  FInfoCentroCards[3].SetValueText(C.Subtitulo);
  FInfoCentroCards[4].SetValueText(C.Area);

  if FGanttControl = nil then
  begin
    FInfoCalCards[0].SetValueText('(sin Gantt)');
    FInfoCalCards[1].SetValueText('-');
    FInfoCalCards[2].SetValueText('-');
    Exit;
  end;

  Cal := FGanttControl.GetCalendar(C.Id);
  if Cal = nil then
  begin
    FInfoCalCards[0].SetValueText('(no asociado)');
    FInfoCalCards[1].SetValueText('-');
    FInfoCalCards[2].SetValueText('-');
    Exit;
  end;

  FInfoCalCards[0].SetValueText(Cal.Name);

  LunesPeriods := Cal.NonWorkingPeriodsForDate(EncodeDate(2024, 1, 1));
  if Length(LunesPeriods) = 0 then
    S := '24h laborable'
  else
  begin
    S := '';
    for I := 0 to High(LunesPeriods) do
    begin
      if I > 0 then S := S + ' | ';
      S := S + Format('%s-%s', [
        FormatDateTime('hh:nn', LunesPeriods[I].StartTimeOfDay),
        FormatDateTime('hh:nn', LunesPeriods[I].EndTimeOfDay)]);
    end;
    S := 'No lab: ' + S;
  end;
  FInfoCalCards[1].SetValueText(S);

  SabP := Cal.NonWorkingPeriodsForDate(EncodeDate(2024, 1, 6));
  DomP := Cal.NonWorkingPeriodsForDate(EncodeDate(2024, 1, 7));
  FullSab := (Length(SabP) > 0) and
             (SabP[0].EndTimeOfDay >= EncodeTime(23, 58, 0, 0));
  FullDom := (Length(DomP) > 0) and
             (DomP[0].EndTimeOfDay >= EncodeTime(23, 58, 0, 0));
  if FullSab and FullDom then
    FInfoCalCards[2].SetValueText('Cerrado (S+D)')
  else if FullSab then
    FInfoCalCards[2].SetValueText('Solo sabado')
  else if FullDom then
    FInfoCalCards[2].SetValueText('Solo domingo')
  else
    FInfoCalCards[2].SetValueText('Abierto');
end;

procedure TfrmCentresKPI.FillBlock(const ASelected: TArray<TCentreTreball>;
  const AWindowStart, AWindowEnd: TDateTime;
  var ABlock: TBlockCards);
var
  I, J, K: Integer;
  N: TNode;
  D: TNodeData;
  Cal: TCentreCalendar;
  NonWorking: TArray<TAbsInterval>;
  SegStart, SegEnd: TDateTime;
  MinsOcupats, MinsLaborables, MinsNoLaborables: Double;
  WindowTotalMin: Double;
  NumNodes: Integer;
  MaxDur, MinDur, SumDur: Double;
  FirstNode, LastNode: TDateTime;
  OperariosTotal: Integer;
  OperariosDistinct: TDictionary<Integer, Byte>;
  CentreIdSet: TDictionary<Integer, Byte>;
  Asign: TArray<TOperario>;
  PercCarga, PercDisp: Double;
  NodosOriginales, NodosOptimizados, NodosNoOptimizados: Integer;
  HasData: Boolean;
begin
  // Defaults — estado "sin datos" con barras a 0 y texto '-'
  ABlock.PercCarga.SetValueText('0.00 %', 0);
  ABlock.PercDisponibilidad.SetValueText('0.00 %', 0);
  ABlock.HorasOcupadas.SetValueText('0.00 h');
  ABlock.HorasLaborables.SetValueText('0.00 h');
  ABlock.HorasNoLaborables.SetValueText('0.00 h');
  ABlock.NumNodes.SetValueText('0');
  ABlock.DuracionMedia.SetValueText('0.00');
  ABlock.NodoMasLargo.SetValueText('0.00');
  ABlock.NodoMasCorto.SetValueText('0.00');
  ABlock.NodosOriginales.SetValueText('0');
  ABlock.NodosOptimizados.SetValueText('0');
  ABlock.NodosNoOptimizados.SetValueText('0');
  ABlock.PrimerNodo.SetValueText('-');
  ABlock.UltimoNodo.SetValueText('-');
  ABlock.OperariosTotal.SetValueText('0');
  ABlock.OperariosDistinct.SetValueText('0');
  ABlock.MoldesTotal.SetMuted;
  ABlock.MoldesDistinct.SetMuted;
  ABlock.UtilajesTotal.SetMuted;
  ABlock.UtilajesDistinct.SetMuted;

  if (FGanttControl = nil) or (AWindowEnd <= AWindowStart) or
     (Length(ASelected) = 0) then Exit;

  MinsLaborables := 0;
  MinsOcupats := 0;
  WindowTotalMin := MinuteSpan(AWindowStart, AWindowEnd);
  NumNodes := 0;
  MaxDur := 0; MinDur := 0; SumDur := 0;
  FirstNode := 0; LastNode := 0;
  OperariosTotal := 0;
  NodosOriginales := 0;
  NodosOptimizados := 0;
  NodosNoOptimizados := 0;

  OperariosDistinct := TDictionary<Integer, Byte>.Create;
  CentreIdSet := TDictionary<Integer, Byte>.Create;
  try
    for K := 0 to High(ASelected) do
      CentreIdSet.AddOrSetValue(ASelected[K].Id, 1);

    // Suma de capacidad laborable de cada centro seleccionado.
    // (Nota: si varios centros comparten calendario se suma igualmente —
    //  representa la capacidad combinada de los recursos.)
    for K := 0 to High(ASelected) do
    begin
      Cal := FGanttControl.GetCalendar(ASelected[K].Id);
      if Cal <> nil then
      begin
        NonWorking := Cal.BuildMergedNonWorkingIntervalsForWindow(
          AWindowStart, AWindowEnd);
        MinsLaborables := MinsLaborables +
          Cal.WorkingMinutesBetweenPrecomputed(
            AWindowStart, AWindowEnd, NonWorking);
      end;
    end;

    // Horas no laborables: capacidad total teorica (N centros * ventana) - laborables
    MinsNoLaborables := (WindowTotalMin * Length(ASelected)) - MinsLaborables;
    if MinsNoLaborables < 0 then MinsNoLaborables := 0;

    // Recorrer nodos: acumular ocupacion, distincts, etc.
    for I := 0 to FGanttControl.NodeCount - 1 do
    begin
      N := FGanttControl.GetNodeAt(I);
      if not CentreIdSet.ContainsKey(N.CentreId) then Continue;
      if N.EndTime   <= AWindowStart then Continue;
      if N.StartTime >= AWindowEnd   then Continue;

      SegStart := Max(N.StartTime, AWindowStart);
      SegEnd   := Min(N.EndTime,   AWindowEnd);
      if SegEnd <= SegStart then Continue;

      Inc(NumNodes);
      SumDur := SumDur + N.DurationMin;
      if (NumNodes = 1) or (N.DurationMin > MaxDur) then MaxDur := N.DurationMin;
      if (NumNodes = 1) or (N.DurationMin < MinDur) then MinDur := N.DurationMin;

      if (FirstNode = 0) or (N.StartTime < FirstNode) then FirstNode := N.StartTime;
      if (LastNode  = 0) or (N.EndTime   > LastNode)  then LastNode  := N.EndTime;

      Cal := FGanttControl.GetCalendar(N.CentreId);
      if Cal <> nil then
      begin
        NonWorking := Cal.BuildMergedNonWorkingIntervalsForWindow(
          AWindowStart, AWindowEnd);
        MinsOcupats := MinsOcupats +
          Cal.WorkingMinutesBetweenPrecomputed(SegStart, SegEnd, NonWorking);
      end
      else
        MinsOcupats := MinsOcupats + MinuteSpan(SegStart, SegEnd);

      HasData := (FNodeRepo <> nil) and FNodeRepo.TryGetById(N.DataId, D);
      if HasData then
        Inc(OperariosTotal, D.OperariosAsignados);

      // Clasificacion optimizado/original/no optimizado (solo por duracion)
      if HasData and (D.DurationMinOriginal > 0) then
      begin
        if SameValue(D.DurationMin, D.DurationMinOriginal, 0.001) then
          Inc(NodosOriginales)
        else if D.DurationMin < D.DurationMinOriginal then
          Inc(NodosOptimizados)
        else
          Inc(NodosNoOptimizados);
      end
      else
        Inc(NodosOriginales);

      if FOperariosRepo <> nil then
      begin
        Asign := FOperariosRepo.GetOperarisAssignatsAlNode(N.DataId);
        for J := 0 to High(Asign) do
          OperariosDistinct.AddOrSetValue(Asign[J].Id, 1);
      end;
    end;

    if MinsLaborables > 0 then
      PercCarga := (MinsOcupats / MinsLaborables) * 100.0
    else
      PercCarga := 0;
    PercDisp := 100.0 - PercCarga;
    if PercDisp < 0 then PercDisp := 0;

    ABlock.PercCarga.SetValueText(FormatFloat('0.00', PercCarga) + ' %', PercCarga);
    ABlock.PercDisponibilidad.SetValueText(FormatFloat('0.00', PercDisp) + ' %', PercDisp);
    ABlock.HorasOcupadas.SetValueText(FormatFloat('0.00', MinsOcupats / 60.0) + ' h');
    ABlock.HorasLaborables.SetValueText(FormatFloat('0.00', MinsLaborables / 60.0) + ' h');
    ABlock.HorasNoLaborables.SetValueText(FormatFloat('0.00', MinsNoLaborables / 60.0) + ' h');
    ABlock.NumNodes.SetValueText(IntToStr(NumNodes));
    ABlock.OperariosTotal.SetValueText(IntToStr(OperariosTotal));
    ABlock.OperariosDistinct.SetValueText(IntToStr(OperariosDistinct.Count));
    ABlock.NodosOriginales.SetValueText(IntToStr(NodosOriginales));
    ABlock.NodosOptimizados.SetValueText(IntToStr(NodosOptimizados));
    ABlock.NodosNoOptimizados.SetValueText(IntToStr(NodosNoOptimizados));

    if NumNodes > 0 then
    begin
      ABlock.DuracionMedia.SetValueText(FormatFloat('0.00', SumDur / NumNodes));
      ABlock.NodoMasLargo.SetValueText(FormatFloat('0.00', MaxDur));
      ABlock.NodoMasCorto.SetValueText(FormatFloat('0.00', MinDur));
      ABlock.PrimerNodo.SetValueText(FormatDateTime('dd/mm/yy hh:nn', FirstNode));
      ABlock.UltimoNodo.SetValueText(FormatDateTime('dd/mm/yy hh:nn', LastNode));
    end;
  finally
    OperariosDistinct.Free;
    CentreIdSet.Free;
  end;
end;

procedure TfrmCentresKPI.RecalcularTodo;
var
  Selected: TArray<TCentreTreball>;
begin
  if FGanttControl = nil then Exit;
  Selected := GetSelectedCentres;

  FillInfo(Selected);
  FillBlock(Selected, FGanttControl.StartVisibleTime, FGanttControl.EndVisibleTime, FBlockA);
  FillBlock(Selected, Now, FGanttControl.EndTime, FBlockB);
  FillBlock(Selected, FGanttControl.StartTime, FGanttControl.EndTime, FBlockC);
end;

end.
