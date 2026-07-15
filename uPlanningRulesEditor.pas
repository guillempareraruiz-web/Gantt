unit uPlanningRulesEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections, System.Generics.Defaults,
  System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit, cxContainer,
  uGanttTypes, uPlanningRules, uCustomFieldDefs, uSetupRules;

type
  // ── Card base amb pintat Trello ──
  TTrelloCard = class(TCustomControl)
  private
    FIndex: Integer;
    FEnabled: Boolean;
    FAccentColor: TColor;
    FHover: Boolean;
    FDragStartY: Integer;
    FDragging: Boolean;
    FOnChanged: TNotifyEvent;
    FOnDelete: TNotifyEvent;
    FOnMoveUp: TNotifyEvent;
    FOnMoveDown: TNotifyEvent;
  protected
    procedure Paint; override;
    procedure MouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure MouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure PaintRoundCard(ACanvas: TCanvas; R: TRect; AAccent: TColor; AHover: Boolean);
  public
    property AccentColor: TColor read FAccentColor write FAccentColor;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnDelete: TNotifyEvent read FOnDelete write FOnDelete;
    property OnMoveUp: TNotifyEvent read FOnMoveUp write FOnMoveUp;
    property OnMoveDown: TNotifyEvent read FOnMoveDown write FOnMoveDown;
  end;

  // ── Sort Card ──
  TSortCard = class(TTrelloCard)
  private
    FRule: TSortRule;
    FFields: TArray<string>;
    cmbField: TComboBox;
    cmbDirection: TComboBox;
    lblWeight: TLabel;
    trkWeight: TTrackBar;
    lblWeightVal: TLabel;
    chkEnabled: TCheckBox;
    btnDelete: TButton;
    btnUp: TButton;
    btnDown: TButton;
    procedure DoFieldChange(Sender: TObject);
    procedure DoDirChange(Sender: TObject);
    procedure DoWeightChange(Sender: TObject);
    procedure DoEnabledClick(Sender: TObject);
    procedure DoDeleteClick(Sender: TObject);
    procedure DoUpClick(Sender: TObject);
    procedure DoDownClick(Sender: TObject);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent; AIdx: Integer;
      const ARule: TSortRule; const AFields: TArray<string>); reintroduce;
    procedure UpdateIndex(AIdx: Integer);
    function GetRule: TSortRule;
  end;

  // ── Filter Card ──
  TFilterCard = class(TTrelloCard)
  private
    FRule: TFilterRule;
    FFields: TArray<string>;
    cmbField: TComboBox;
    cmbOperator: TComboBox;
    edtValue: TEdit;
    cmbAction: TComboBox;
    edtCentreId: TEdit;
    lblCentreId: TLabel;
    chkEnabled: TCheckBox;
    btnDelete: TButton;
    procedure DoChange(Sender: TObject);
    procedure DoActionChange(Sender: TObject);
    procedure DoEnabledClick(Sender: TObject);
    procedure DoDeleteClick(Sender: TObject);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent; AIdx: Integer;
      const ARule: TFilterRule; const AFields: TArray<string>); reintroduce;
    procedure UpdateIndex(AIdx: Integer);
    function GetRule: TFilterRule;
  end;

  // ── Group Card ──
  TGroupCard = class(TTrelloCard)
  private
    FRule: TGroupRule;
    FFields: TArray<string>;
    cmbField: TComboBox;
    cmbMode: TComboBox;
    lblWeight: TLabel;
    trkWeight: TTrackBar;
    lblWeightVal: TLabel;
    chkEnabled: TCheckBox;
    btnDelete: TButton;
    procedure DoChange(Sender: TObject);
    procedure DoWeightChange(Sender: TObject);
    procedure DoEnabledClick(Sender: TObject);
    procedure DoDeleteClick(Sender: TObject);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent; AIdx: Integer;
      const ARule: TGroupRule; const AFields: TArray<string>); reintroduce;
    procedure UpdateIndex(AIdx: Integer);
    function GetRule: TGroupRule;
  end;

  // ── Setup Card (tiempo de cambio secuencia-dependiente) ──
  // Regla: "si cambia <Atributo> de un trabajo al siguiente -> +Minutos".
  TSetupCard = class(TTrelloCard)
  private
    FRule: TSetupRule;
    FFields: TArray<string>;
    FCentres: TArray<string>;
    cmbField: TComboBox;
    seMin: TcxSpinEdit;
    lblMin: TLabel;
    lblCentre2: TLabel;
    cmbCentre: TComboBox;
    lblCentre: TLabel;
    chkEnabled: TCheckBox;
    btnDelete: TButton;
    procedure DoChange(Sender: TObject);
    procedure DoEnabledClick(Sender: TObject);
    procedure DoDeleteClick(Sender: TObject);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent; AIdx: Integer;
      const ARule: TSetupRule; const AFields, ACentres: TArray<string>); reintroduce;
    procedure UpdateIndex(AIdx: Integer);
    function GetRule: TSetupRule;
  end;

  // ── Ilustracion dinamica (GDI+) ──
  // Dos modos segun FHasRules:
  //  - False (empty-state): mensaje guia + ejemplo + zona para el boton "crear".
  //  - True (mini-timeline): franja "antes" (sin agrupar, muchos cambios) vs
  //    "despues" (agrupando, pocos cambios), para ilustrar el ahorro.
  // Los datos del ejemplo se fijan con SetExample (atributo + minutos de la 1a
  // regla activa), asi la ilustracion "habla" del caso del usuario.
  TSetupIllustration = class(TCustomControl)
  private
    FHasRules: Boolean;
    FAttrName: string;      // atributo de ejemplo (p.ej. "Color")
    FSetupMin: Integer;     // minutos de la regla de ejemplo
    FOnCreateFirst: TNotifyEvent;  // click en la zona "crear primera regla"
    procedure DrawEmptyState(G: TGPGraphics; W, H: Single);
    procedure DrawTimeline(G: TGPGraphics; W, H: Single);
  protected
    procedure Paint; override;
    procedure Click; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetState(AHasRules: Boolean; const AAttr: string; AMin: Integer);
    property OnCreateFirst: TNotifyEvent read FOnCreateFirst write FOnCreateFirst;
  end;

  TfrmPlanningRulesEditor = class(TForm)
    pnlMain: TPanel;
    pnlProfiles: TPanel;
    lblProfile: TLabel;
    lblDescription: TLabel;
    cmbProfiles: TComboBox;
    btnAddProfile: TButton;
    btnDeleteProfile: TButton;
    btnRenameProfile: TButton;
    edtDescription: TEdit;
    btnGuardar: TButton;
    pnlRules: TPanel;
    pnlSortRules: TPanel;
    pnlSortColumn: TPanel;
    pnlSortHeader: TPanel;
    lblSortTitle: TLabel;
    lblSortSub: TLabel;
    lblSortCount: TLabel;
    btnAddSort: TButton;
    sbSort: TScrollBox;
    pnlFilterRules: TPanel;
    pnlFilterColumn: TPanel;
    pnlFilterHeader: TPanel;
    lblFilterTitle: TLabel;
    lblFilterSub: TLabel;
    lblFilterCount: TLabel;
    btnAddFilter: TButton;
    sbFilter: TScrollBox;
    pnlGroupRules: TPanel;
    pnlGroupColumn: TPanel;
    pnlGroupHeader: TPanel;
    lblGroupTitle: TLabel;
    lblGroupSub: TLabel;
    lblGroupCount: TLabel;
    btnAddGroup: TButton;
    sbGroup: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnGuardarReglasClick(Sender: TObject);
    procedure cmbProfilesChange(Sender: TObject);
    procedure btnAddProfileClick(Sender: TObject);
    procedure btnDeleteProfileClick(Sender: TObject);
    procedure btnRenameProfileClick(Sender: TObject);
    procedure edtDescriptionChange(Sender: TObject);
    procedure btnAddSortClick(Sender: TObject);
    procedure btnAddFilterClick(Sender: TObject);
    procedure btnAddGroupClick(Sender: TObject);
  private
    FEngine: TPlanningRuleEngine;
    FProfiles: TList<TPlanningProfile>;
    FActiveIdx: Integer;
    FFields: TArray<string>;
    FSortCards: TList<TSortCard>;
    FFilterCards: TList<TFilterCard>;
    FGroupCards: TList<TGroupCard>;

        // ── Tab "Tiempo de cambio" (setup secuencia-dependiente) ──
    // Creado por codigo en FormCreate (reparenta el contenido actual en la 1a
    // pagina y construye el tab de setup en la 2a), sin tocar el DFM existente.
    FPages: TPageControl;
    FTabRules: TTabSheet;
    FTabSetup: TTabSheet;
    FSetupCards: TList<TSetupCard>;
    FSetupRules: TArray<TSetupRule>;
    FCentres: TArray<string>;      // codigos de centro/linea (para el combo)
    FSbSetup: TScrollBox;
    FIllustration: TSetupIllustration;  // empty-state / mini-timeline
    FChkVerIlustr: TCheckBox;      // mostrar/ocultar la ilustracion
    FLblSetupCount: TLabel;        // "N reglas activas" en la cabecera
    FLblSetupKpi: TLabel;          // KPI: tiempo de cambio del plan actual
    FLblSetupKpiSub: TLabel;       // subtitulo comparativo con/sin agrupacion

    // Cambios sin guardar, POR PESTANA (independientes: Tab1 reglas -> engine,
    // Tab2 tiempos -> BD). Al cerrar con la X se pide confirmacion si alguno
    // tiene cambios. Cada boton guarda solo su pestana.
    FDirtyRules: Boolean;
    FDirtySetup: Boolean;
    FSavedAtLeastOnce: Boolean;  // el llamador lo lee para refrescar si guardo
    FBtnGuardarSetup: TButton;   // boton "Guardar tiempos" del Tab2 (por codigo)

    procedure RefreshProfileCombo;
    procedure LoadProfile(AIndex: Integer);
    procedure SaveCurrentProfile;
    procedure RebuildSortCards;
    procedure RebuildFilterCards;
    procedure RebuildGroupCards;
    procedure UpdateCounts;
    procedure OnSortChanged(Sender: TObject);
    procedure OnSortDelete(Sender: TObject);
    procedure OnSortMoveUp(Sender: TObject);
    procedure OnSortMoveDown(Sender: TObject);
    procedure OnFilterChanged(Sender: TObject);
    procedure OnFilterDelete(Sender: TObject);
    procedure OnGroupChanged(Sender: TObject);
    procedure OnGroupDelete(Sender: TObject);


    procedure MarkDirtyRules;
    procedure MarkDirtySetup;
    procedure DoSaveRules;
    procedure DoSaveSetup;
    procedure OnGuardarSetupClick(Sender: TObject);
    procedure BuildSetupTab;
    procedure PopulateSetupTab;
    procedure LoadSetupRulesFromDB;
    procedure SaveSetupRulesToDB;
    procedure RebuildSetupCards;
    procedure UpdateSetupCounts;
    procedure UpdateIllustration;
    procedure UpdateSetupHeader;   // contador de reglas activas + aviso duplicados
    procedure OnSetupChanged(Sender: TObject);
    procedure OnSetupDelete(Sender: TObject);
    procedure OnAddSetupClick(Sender: TObject);
    procedure OnVerIlustrClick(Sender: TObject);
    procedure RecalcSetupKpi;
    function CollectSetupRules: TArray<TSetupRule>;
  public
    class function Execute(AEngine: TPlanningRuleEngine): Boolean;
  end;

var
  frmPlanningRulesEditor: TfrmPlanningRulesEditor;

implementation

uses
  uDMPlanner, uHelpViewer;

{$R *.dfm}

const
  CARD_H         = 90;
  CARD_FILTER_H  = 100;
  SETUP_CARD_H   = 46;   // setup cards en UNA fila (mas compactas)
  CARD_GAP       = 8;
  CARD_MARGIN    = 10;
  CARD_RADIUS    = 8;
  ACCENT_W       = 5;

  // Trello-inspired colors
  CLR_SORT_ACCENT   = $00D09030;   // taronja
  CLR_FILTER_ACCENT = $00409850;   // verd
  CLR_GROUP_ACCENT  = $00B05090;   // porpra
  CLR_SETUP_ACCENT  = $002D1EBE;   // granate/rojo (BGR de #BE1E2D) - tiempo cambio
  CLR_DISABLED      = $00B8B8B8;
  CLR_CARD_BG       = $00FFFFFF;
  CLR_CARD_HOVER    = $00FFF8F0;
  CLR_CARD_SHADOW   = $00E0D8D0;
  CLR_COLUMN_BG     = 15132390;    // $00E6E6E6
  CLR_BOARD_BG      = 15395562;    // $00EADAEA -> gris blavós

{ ═══════════════════════════════════════════════════════ }
{  TTrelloCard — base                                     }
{ ═══════════════════════════════════════════════════════ }

procedure TTrelloCard.Paint;
begin
  PaintRoundCard(Canvas, ClientRect, FAccentColor, FHover);
end;

procedure TTrelloCard.MouseEnter(var Msg: TMessage);
begin
  FHover := True;
  Invalidate;
end;

procedure TTrelloCard.MouseLeave(var Msg: TMessage);
begin
  FHover := False;
  Invalidate;
end;

procedure TTrelloCard.PaintRoundCard(ACanvas: TCanvas; R: TRect;
  AAccent: TColor; AHover: Boolean);
var
  ShadowR: TRect;
begin
  // Fons transparent
  ACanvas.Brush.Color := CLR_COLUMN_BG;
  ACanvas.FillRect(R);

  // Ombra
  ShadowR := Rect(R.Left + 2, R.Top + 2, R.Right, R.Bottom);
  ACanvas.Brush.Color := CLR_CARD_SHADOW;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(ShadowR.Left, ShadowR.Top, ShadowR.Right, ShadowR.Bottom,
    CARD_RADIUS, CARD_RADIUS);

  // Card
  if AHover then
    ACanvas.Brush.Color := CLR_CARD_HOVER
  else
    ACanvas.Brush.Color := CLR_CARD_BG;
  ACanvas.Pen.Color := $00E8E0D8;
  ACanvas.Pen.Style := psSolid;
  ACanvas.RoundRect(R.Left, R.Top, R.Right - 2, R.Bottom - 2,
    CARD_RADIUS, CARD_RADIUS);

  // Accent bar esquerra
  ACanvas.Brush.Color := AAccent;
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(R.Left, R.Top, R.Left + ACCENT_W + CARD_RADIUS, R.Bottom - 2,
    CARD_RADIUS, CARD_RADIUS);
  // Tapar la cantonada dreta de l'accent
  ACanvas.FillRect(Rect(R.Left + ACCENT_W, R.Top + 1, R.Left + ACCENT_W + CARD_RADIUS, R.Bottom - 3));
end;

{ ═══════════════════════════════════════════════════════ }
{  TSortCard                                              }
{ ═══════════════════════════════════════════════════════ }

constructor TSortCard.Create(AOwner: TComponent; AIdx: Integer;
  const ARule: TSortRule; const AFields: TArray<string>);
var
  I, SelIdx: Integer;
  LX: Integer;
begin
  inherited Create(AOwner);
  FIndex := AIdx;
  FRule := ARule;
  FFields := AFields;

  Parent := TWinControl(AOwner);
  Width := Parent.ClientWidth - CARD_MARGIN * 2;
  Height := CARD_H;
  Left := CARD_MARGIN;
  Top := CARD_MARGIN + AIdx * (CARD_H + CARD_GAP);

  if ARule.Enabled then
    FAccentColor := CLR_SORT_ACCENT
  else
    FAccentColor := CLR_DISABLED;

  LX := ACCENT_W + 14;

  // Camp
  cmbField := TComboBox.Create(Self);
  cmbField.Parent := Self;
  cmbField.Style := csDropDownList;
  cmbField.SetBounds(LX, 8, 155, 23);
  SelIdx := 0;
  for I := 0 to High(AFields) do
  begin
    cmbField.Items.Add(AFields[I]);
    if SameText(AFields[I], ARule.FieldName) then
      SelIdx := I;
  end;
  cmbField.ItemIndex := SelIdx;
  cmbField.OnChange := DoFieldChange;

  // Direcció
  cmbDirection := TComboBox.Create(Self);
  cmbDirection.Parent := Self;
  cmbDirection.Style := csDropDownList;
  cmbDirection.SetBounds(LX + 163, 8, 110, 23);
  cmbDirection.Items.Add(#$25B2' Ascendente');
  cmbDirection.Items.Add(#$25BC' Descendente');
  if ARule.Direction = sdDesc then
    cmbDirection.ItemIndex := 1
  else
    cmbDirection.ItemIndex := 0;
  cmbDirection.OnChange := DoDirChange;

  // Enabled
  chkEnabled := TCheckBox.Create(Self);
  chkEnabled.Parent := Self;
  chkEnabled.SetBounds(LX, 40, 75, 17);
  chkEnabled.Caption := 'Activa';
  chkEnabled.Checked := ARule.Enabled;
  chkEnabled.OnClick := DoEnabledClick;

  // Pes (Weight)
  lblWeight := TLabel.Create(Self);
  lblWeight.Parent := Self;
  lblWeight.SetBounds(LX, 64, 30, 15);
  lblWeight.Caption := 'Peso:';
  lblWeight.Font.Size := 8;

  trkWeight := TTrackBar.Create(Self);
  trkWeight.Parent := Self;
  trkWeight.SetBounds(LX + 36, 60, 150, 22);
  trkWeight.Min := 1;
  trkWeight.Max := 10;
  trkWeight.Position := ARule.Weight;
  if trkWeight.Position = 0 then trkWeight.Position := 5;
  trkWeight.TickStyle := tsNone;
  trkWeight.OnChange := DoWeightChange;

  lblWeightVal := TLabel.Create(Self);
  lblWeightVal.Parent := Self;
  lblWeightVal.SetBounds(LX + 190, 64, 30, 15);
  lblWeightVal.Caption := IntToStr(trkWeight.Position);
  lblWeightVal.Font.Style := [fsBold];
  lblWeightVal.Font.Color := FAccentColor;

  // Botons move
  btnUp := TButton.Create(Self);
  btnUp.Parent := Self;
  btnUp.SetBounds(LX + 163, 36, 30, 24);
  btnUp.Caption := #$25B2;
  btnUp.Font.Size := 8;
  btnUp.OnClick := DoUpClick;

  btnDown := TButton.Create(Self);
  btnDown.Parent := Self;
  btnDown.SetBounds(LX + 197, 36, 30, 24);
  btnDown.Caption := #$25BC;
  btnDown.Font.Size := 8;
  btnDown.OnClick := DoDownClick;

  // Delete
  btnDelete := TButton.Create(Self);
  btnDelete.Parent := Self;
  btnDelete.SetBounds(LX + 290, 8, 60, 24);
  btnDelete.Caption := #$2716' Borrar';
  btnDelete.Font.Size := 8;
  btnDelete.OnClick := DoDeleteClick;
end;

procedure TSortCard.Paint;
begin
  inherited;
  // Dibuixar número d'ordre
  Canvas.Font.Name := 'Segoe UI Semibold';
  Canvas.Font.Size := 14;
  Canvas.Font.Color := FAccentColor;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(ACCENT_W + 14, 36, IntToStr(FIndex + 1));
end;

procedure TSortCard.UpdateIndex(AIdx: Integer);
begin
  FIndex := AIdx;
  Top := CARD_MARGIN + AIdx * (CARD_H + CARD_GAP);
  Invalidate;
end;

function TSortCard.GetRule: TSortRule;
begin
  Result.FieldName := cmbField.Text;
  if cmbDirection.ItemIndex = 1 then
    Result.Direction := sdDesc
  else
    Result.Direction := sdAsc;
  Result.Weight := trkWeight.Position;
  Result.Enabled := chkEnabled.Checked;
end;

procedure TSortCard.DoFieldChange(Sender: TObject);
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TSortCard.DoDirChange(Sender: TObject);
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TSortCard.DoEnabledClick(Sender: TObject);
begin
  if chkEnabled.Checked then
    FAccentColor := CLR_SORT_ACCENT
  else
    FAccentColor := CLR_DISABLED;
  Invalidate;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TSortCard.DoWeightChange(Sender: TObject);
begin
  lblWeightVal.Caption := IntToStr(trkWeight.Position);
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TSortCard.DoDeleteClick(Sender: TObject);
begin
  if Assigned(FOnDelete) then FOnDelete(Self);
end;

procedure TSortCard.DoUpClick(Sender: TObject);
begin
  if Assigned(FOnMoveUp) then FOnMoveUp(Self);
end;

procedure TSortCard.DoDownClick(Sender: TObject);
begin
  if Assigned(FOnMoveDown) then FOnMoveDown(Self);
end;

{ ═══════════════════════════════════════════════════════ }
{  TFilterCard                                            }
{ ═══════════════════════════════════════════════════════ }

constructor TFilterCard.Create(AOwner: TComponent; AIdx: Integer;
  const ARule: TFilterRule; const AFields: TArray<string>);
var
  I, SelIdx: Integer;
  LX: Integer;
begin
  inherited Create(AOwner);
  FIndex := AIdx;
  FRule := ARule;
  FFields := AFields;

  Parent := TWinControl(AOwner);
  Width := Parent.ClientWidth - CARD_MARGIN * 2;
  Height := CARD_FILTER_H;
  Left := CARD_MARGIN;
  Top := CARD_MARGIN + AIdx * (CARD_FILTER_H + CARD_GAP);

  if ARule.Enabled then
    FAccentColor := CLR_FILTER_ACCENT
  else
    FAccentColor := CLR_DISABLED;

  LX := ACCENT_W + 14;

  // Fila 1: Camp + Operador + Valor
  cmbField := TComboBox.Create(Self);
  cmbField.Parent := Self;
  cmbField.Style := csDropDownList;
  cmbField.SetBounds(LX, 8, 140, 23);
  SelIdx := 0;
  for I := 0 to High(AFields) do
  begin
    cmbField.Items.Add(AFields[I]);
    if SameText(AFields[I], ARule.FieldName) then
      SelIdx := I;
  end;
  cmbField.ItemIndex := SelIdx;
  cmbField.OnChange := DoChange;

  cmbOperator := TComboBox.Create(Self);
  cmbOperator.Parent := Self;
  cmbOperator.Style := csDropDownList;
  cmbOperator.SetBounds(LX + 148, 8, 85, 23);
  cmbOperator.Items.Add('=');
  cmbOperator.Items.Add('<>');
  cmbOperator.Items.Add('>');
  cmbOperator.Items.Add('>=');
  cmbOperator.Items.Add('<');
  cmbOperator.Items.Add('<=');
  cmbOperator.Items.Add('contiene');
  cmbOperator.Items.Add('en lista');
  cmbOperator.ItemIndex := Ord(ARule.Operator);
  cmbOperator.OnChange := DoChange;

  edtValue := TEdit.Create(Self);
  edtValue.Parent := Self;
  edtValue.SetBounds(LX + 241, 8, 100, 23);
  edtValue.Text := VarToStr(ARule.Value);
  edtValue.OnChange := DoChange;

  // Fila 2: Acció + Centre
  cmbAction := TComboBox.Create(Self);
  cmbAction.Parent := Self;
  cmbAction.Style := csDropDownList;
  cmbAction.SetBounds(LX, 40, 130, 23);
  cmbAction.Items.Add(#$2705' Incluir');
  cmbAction.Items.Add(#$274C' Excluir');
  cmbAction.Items.Add(#$27A1' Forzar centro');
  cmbAction.ItemIndex := Ord(ARule.Action);
  cmbAction.OnChange := DoActionChange;

  lblCentreId := TLabel.Create(Self);
  lblCentreId.Parent := Self;
  lblCentreId.SetBounds(LX + 140, 44, 55, 15);
  lblCentreId.Caption := 'Centro:';
  lblCentreId.Visible := ARule.Action = faForceCenter;

  edtCentreId := TEdit.Create(Self);
  edtCentreId.Parent := Self;
  edtCentreId.SetBounds(LX + 198, 40, 60, 23);
  if ARule.TargetCentreId >= 0 then
    edtCentreId.Text := IntToStr(ARule.TargetCentreId)
  else
    edtCentreId.Text := '';
  edtCentreId.Visible := ARule.Action = faForceCenter;
  edtCentreId.OnChange := DoChange;

  // Fila 3: Enabled + Delete
  chkEnabled := TCheckBox.Create(Self);
  chkEnabled.Parent := Self;
  chkEnabled.SetBounds(LX, 72, 75, 17);
  chkEnabled.Caption := 'Activa';
  chkEnabled.Checked := ARule.Enabled;
  chkEnabled.OnClick := DoEnabledClick;

  btnDelete := TButton.Create(Self);
  btnDelete.Parent := Self;
  btnDelete.SetBounds(LX + 290, 8, 60, 24);
  btnDelete.Caption := #$2716' Borrar';
  btnDelete.Font.Size := 8;
  btnDelete.OnClick := DoDeleteClick;
end;

procedure TFilterCard.Paint;
begin
  inherited;
end;

procedure TFilterCard.UpdateIndex(AIdx: Integer);
begin
  FIndex := AIdx;
  Top := CARD_MARGIN + AIdx * (CARD_FILTER_H + CARD_GAP);
  Invalidate;
end;

function TFilterCard.GetRule: TFilterRule;
begin
  Result.FieldName := cmbField.Text;
  Result.Operator := TFilterOperator(cmbOperator.ItemIndex);
  Result.Value := edtValue.Text;
  Result.Action := TFilterAction(cmbAction.ItemIndex);
  Result.TargetCentreId := StrToIntDef(edtCentreId.Text, -1);
  Result.Enabled := chkEnabled.Checked;
end;

procedure TFilterCard.DoChange(Sender: TObject);
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TFilterCard.DoActionChange(Sender: TObject);
begin
  lblCentreId.Visible := cmbAction.ItemIndex = 2;
  edtCentreId.Visible := cmbAction.ItemIndex = 2;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TFilterCard.DoEnabledClick(Sender: TObject);
begin
  if chkEnabled.Checked then
    FAccentColor := CLR_FILTER_ACCENT
  else
    FAccentColor := CLR_DISABLED;
  Invalidate;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TFilterCard.DoDeleteClick(Sender: TObject);
begin
  if Assigned(FOnDelete) then FOnDelete(Self);
end;

{ ═══════════════════════════════════════════════════════ }
{  TGroupCard                                             }
{ ═══════════════════════════════════════════════════════ }

constructor TGroupCard.Create(AOwner: TComponent; AIdx: Integer;
  const ARule: TGroupRule; const AFields: TArray<string>);
var
  I, SelIdx: Integer;
  LX: Integer;
begin
  inherited Create(AOwner);
  FIndex := AIdx;
  FRule := ARule;
  FFields := AFields;

  Parent := TWinControl(AOwner);
  Width := Parent.ClientWidth - CARD_MARGIN * 2;
  Height := CARD_H;
  Left := CARD_MARGIN;
  Top := CARD_MARGIN + AIdx * (CARD_H + CARD_GAP);

  if ARule.Enabled then
    FAccentColor := CLR_GROUP_ACCENT
  else
    FAccentColor := CLR_DISABLED;

  LX := ACCENT_W + 14;

  // Camp
  cmbField := TComboBox.Create(Self);
  cmbField.Parent := Self;
  cmbField.Style := csDropDownList;
  cmbField.SetBounds(LX, 8, 150, 23);
  SelIdx := 0;
  for I := 0 to High(AFields) do
  begin
    cmbField.Items.Add(AFields[I]);
    if SameText(AFields[I], ARule.FieldName) then
      SelIdx := I;
  end;
  cmbField.ItemIndex := SelIdx;
  cmbField.OnChange := DoChange;

  // Mode
  cmbMode := TComboBox.Create(Self);
  cmbMode.Parent := Self;
  cmbMode.Style := csDropDownList;
  cmbMode.SetBounds(LX + 158, 8, 120, 23);
  cmbMode.Items.Add('Mismo centro');
  cmbMode.Items.Add('Consecutivas');
  cmbMode.ItemIndex := Ord(ARule.Mode);
  cmbMode.OnChange := DoChange;

  // Enabled
  chkEnabled := TCheckBox.Create(Self);
  chkEnabled.Parent := Self;
  chkEnabled.SetBounds(LX, 40, 75, 17);
  chkEnabled.Caption := 'Activa';
  chkEnabled.Checked := ARule.Enabled;
  chkEnabled.OnClick := DoEnabledClick;

  // Pes
  lblWeight := TLabel.Create(Self);
  lblWeight.Parent := Self;
  lblWeight.SetBounds(LX, 64, 30, 15);
  lblWeight.Caption := 'Peso:';
  lblWeight.Font.Size := 8;

  trkWeight := TTrackBar.Create(Self);
  trkWeight.Parent := Self;
  trkWeight.SetBounds(LX + 36, 60, 150, 22);
  trkWeight.Min := 1;
  trkWeight.Max := 10;
  trkWeight.Position := ARule.Weight;
  if trkWeight.Position = 0 then trkWeight.Position := 5;
  trkWeight.TickStyle := tsNone;
  trkWeight.OnChange := DoWeightChange;

  lblWeightVal := TLabel.Create(Self);
  lblWeightVal.Parent := Self;
  lblWeightVal.SetBounds(LX + 190, 64, 30, 15);
  lblWeightVal.Caption := IntToStr(trkWeight.Position);
  lblWeightVal.Font.Style := [fsBold];
  lblWeightVal.Font.Color := FAccentColor;

  // Delete
  btnDelete := TButton.Create(Self);
  btnDelete.Parent := Self;
  btnDelete.SetBounds(LX + 290, 8, 60, 24);
  btnDelete.Caption := #$2716' Borrar';
  btnDelete.Font.Size := 8;
  btnDelete.OnClick := DoDeleteClick;
end;

procedure TGroupCard.Paint;
begin
  inherited;
end;

procedure TGroupCard.UpdateIndex(AIdx: Integer);
begin
  FIndex := AIdx;
  Top := CARD_MARGIN + AIdx * (CARD_H + CARD_GAP);
  Invalidate;
end;

function TGroupCard.GetRule: TGroupRule;
begin
  Result.FieldName := cmbField.Text;
  Result.Mode := TGroupMode(cmbMode.ItemIndex);
  Result.Weight := trkWeight.Position;
  Result.Enabled := chkEnabled.Checked;
end;

procedure TGroupCard.DoChange(Sender: TObject);
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TGroupCard.DoWeightChange(Sender: TObject);
begin
  lblWeightVal.Caption := IntToStr(trkWeight.Position);
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TGroupCard.DoEnabledClick(Sender: TObject);
begin
  if chkEnabled.Checked then
    FAccentColor := CLR_GROUP_ACCENT
  else
    FAccentColor := CLR_DISABLED;
  Invalidate;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TGroupCard.DoDeleteClick(Sender: TObject);
begin
  if Assigned(FOnDelete) then FOnDelete(Self);
end;

{ ═══════════════════════════════════════════════════════ }
{  TSetupCard                                             }
{ ═══════════════════════════════════════════════════════ }

constructor TSetupCard.Create(AOwner: TComponent; AIdx: Integer;
  const ARule: TSetupRule; const AFields, ACentres: TArray<string>);
var
  I, SelIdx: Integer;
  LX: Integer;
begin
  inherited Create(AOwner);
  FIndex := AIdx;
  FRule := ARule;
  FFields := AFields;
  FCentres := ACentres;

  Parent := TWinControl(AOwner);
  Width := Parent.ClientWidth - CARD_MARGIN * 2;
  Height := SETUP_CARD_H;
  Left := CARD_MARGIN;
  Top := CARD_MARGIN + AIdx * (SETUP_CARD_H + CARD_GAP);

  if ARule.Enabled then
    FAccentColor := CLR_SETUP_ACCENT
  else
    FAccentColor := CLR_DISABLED;

  // Layout en UNA fila: Linea | Atributo | + min | Activa | Borrar.
  LX := ACCENT_W + 12;

  // Linea/centro (vacio = todas).
  lblCentre := TLabel.Create(Self);
  lblCentre.Parent := Self;
  lblCentre.SetBounds(LX, 15, 40, 15);
  lblCentre.Caption := 'L'#237'nea:';
  lblCentre.Font.Size := 8;

  cmbCentre := TComboBox.Create(Self);
  cmbCentre.Parent := Self;
  cmbCentre.Style := csDropDownList;
  cmbCentre.SetBounds(LX + 42, 11, 150, 23);
  cmbCentre.Items.Add('(Todas)');
  SelIdx := 0;
  for I := 0 to High(ACentres) do
  begin
    cmbCentre.Items.Add(ACentres[I]);
    if SameText(ACentres[I], ARule.CentreCode) then
      SelIdx := I + 1;
  end;
  cmbCentre.ItemIndex := SelIdx;
  cmbCentre.OnChange := DoChange;

  // Atributo que dispara el cambio (builtin o custom).
  lblMin := TLabel.Create(Self);   // reutilizamos como etiqueta "cambia:"
  lblMin.Parent := Self;
  lblMin.SetBounds(LX + 202, 15, 50, 15);
  lblMin.Caption := 'cambia:';
  lblMin.Font.Size := 8;

  cmbField := TComboBox.Create(Self);
  cmbField.Parent := Self;
  cmbField.Style := csDropDownList;
  cmbField.SetBounds(LX + 250, 11, 160, 23);
  SelIdx := 0;
  for I := 0 to High(AFields) do
  begin
    cmbField.Items.Add(AFields[I]);
    if SameText(AFields[I], ARule.AttrName) then
      SelIdx := I;
  end;
  cmbField.ItemIndex := SelIdx;
  cmbField.OnChange := DoChange;

  // Minutos de cambio.
  lblCentre2 := TLabel.Create(Self);
  lblCentre2.Parent := Self;
  lblCentre2.SetBounds(LX + 420, 15, 40, 15);
  lblCentre2.Caption := '+ min:';
  lblCentre2.Font.Size := 8;

  // TcxSpinEdit (DevExpress): respeta los skins de la app; TSpinEdit VCL nativo
  // no pintaba los botones up/down bajo el skin activo.
  // Orden importante: configurar Properties ANTES de asignar el valor, y usar
  // EditValue (no .Value directo antes de estar completo) para que el texto se
  // pinte sin necesidad de foco. AutoSize=False + Style.Font por defecto para
  // que el skin dimensione bien la caja.
  seMin := TcxSpinEdit.Create(Self);
  seMin.Parent := Self;
  seMin.Properties.MinValue := 0;
  seMin.Properties.MaxValue := 100000;
  seMin.Properties.AssignedValues.MinValue := True;
  seMin.Properties.AssignedValues.MaxValue := True;
  seMin.Properties.OnChange := DoChange;
  seMin.EditValue := ARule.SetupMin;
  seMin.Left := LX + 462;
  seMin.Top := 10;
  seMin.Width := 74;

  // Enabled.
  chkEnabled := TCheckBox.Create(Self);
  chkEnabled.Parent := Self;
  chkEnabled.SetBounds(LX + 546, 14, 72, 17);
  chkEnabled.Caption := 'Activa';
  chkEnabled.Checked := ARule.Enabled;
  chkEnabled.OnClick := DoEnabledClick;

  // Delete.
  btnDelete := TButton.Create(Self);
  btnDelete.Parent := Self;
  btnDelete.SetBounds(LX + 624, 11, 64, 24);
  btnDelete.Caption := #$2716' Borrar';
  btnDelete.Font.Size := 8;
  btnDelete.OnClick := DoDeleteClick;
end;

procedure TSetupCard.Paint;
begin
  inherited;
end;

procedure TSetupCard.UpdateIndex(AIdx: Integer);
begin
  FIndex := AIdx;
  Top := CARD_MARGIN + AIdx * (SETUP_CARD_H + CARD_GAP);
  Invalidate;
end;

function TSetupCard.GetRule: TSetupRule;
begin
  Result.AttrName := cmbField.Text;
  // seMin.Value es Variant en TcxSpinEdit; convertir con default seguro.
  Result.SetupMin := StrToIntDef(VarToStr(seMin.Value), 0);
  // ItemIndex 0 = "(Todas las lineas)" -> CentreCode vacio.
  if cmbCentre.ItemIndex <= 0 then
    Result.CentreCode := ''
  else
    Result.CentreCode := cmbCentre.Text;
  Result.Enabled := chkEnabled.Checked;
end;

procedure TSetupCard.DoChange(Sender: TObject);
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TSetupCard.DoEnabledClick(Sender: TObject);
begin
  if chkEnabled.Checked then
    FAccentColor := CLR_SETUP_ACCENT
  else
    FAccentColor := CLR_DISABLED;
  Invalidate;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TSetupCard.DoDeleteClick(Sender: TObject);
begin
  if Assigned(FOnDelete) then FOnDelete(Self);
end;

{ ═══════════════════════════════════════════════════════ }
{  TSetupIllustration (GDI+)                              }
{ ═══════════════════════════════════════════════════════ }

// Helpers GDI+ locales (mismos que en uReglasPlanComparativa).
function GPc(C: TColor; A: Byte = 255): TGPColor;
begin
  C := ColorToRGB(C);
  Result := MakeColor(A, GetRValue(C), GetGValue(C), GetBValue(C));
end;

procedure IllRoundRect(APath: TGPGraphicsPath; X, Y, W, H, R: Single);
begin
  if R * 2 > H then R := H / 2;
  if R * 2 > W then R := W / 2;
  APath.AddArc(X, Y, R * 2, R * 2, 180, 90);
  APath.AddArc(X + W - R * 2, Y, R * 2, R * 2, 270, 90);
  APath.AddArc(X + W - R * 2, Y + H - R * 2, R * 2, R * 2, 0, 90);
  APath.AddArc(X, Y + H - R * 2, R * 2, R * 2, 90, 90);
  APath.CloseFigure;
end;

// TGPRectF garantizado: MakeRect tiene overloads Integer/Single y con args
// enteros elige el que devuelve TGPRect -> incompatible con TGPRectF. Este
// wrapper fuerza Single siempre.
function RF(X, Y, W, H: Single): TGPRectF;
begin
  Result := MakeRect(X, Y, W, H);
end;

// Rellena un rectangulo redondeado de color solido.
procedure FillRound(G: TGPGraphics; X, Y, W, H, R: Single; C: TColor; A: Byte = 255);
var
  P: TGPGraphicsPath;
  B: TGPSolidBrush;
begin
  P := TGPGraphicsPath.Create;
  B := TGPSolidBrush.Create(GPc(C, A));
  try
    IllRoundRect(P, X, Y, W, H, R);
    G.FillPath(B, P);
  finally
    B.Free;
    P.Free;
  end;
end;

constructor TSetupIllustration.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHasRules := False;
  FAttrName := '';
  FSetupMin := 0;
end;

procedure TSetupIllustration.SetState(AHasRules: Boolean; const AAttr: string;
  AMin: Integer);
begin
  FHasRules := AHasRules;
  FAttrName := AAttr;
  FSetupMin := AMin;
  Invalidate;
end;

procedure TSetupIllustration.Click;
begin
  inherited;
  // En modo empty-state, todo el area actua como "crear primera regla".
  if (not FHasRules) and Assigned(FOnCreateFirst) then
    FOnCreateFirst(Self);
end;

procedure TSetupIllustration.Paint;
var
  G: TGPGraphics;
begin
  G := TGPGraphics.Create(Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);
    // Fondo.
    G.Clear(GPc(ColorToRGB(Color)));
    if FHasRules then
      DrawTimeline(G, ClientWidth, ClientHeight)
    else
      DrawEmptyState(G, ClientWidth, ClientHeight);
  finally
    G.Free;
  end;
end;

procedure TSetupIllustration.DrawEmptyState(G: TGPGraphics; W, H: Single);
var
  Fam: TGPFontFamily;
  FTitle, FBody, FBtn: TGPFont;
  BrDark, BrSoft, BrWhite, BrAccent: TGPSolidBrush;
  Fmt: TGPStringFormat;
  R: TGPRectF;
  CardX, CardY, CardW, CardH: Single;
  Ej: string;
  BtnX, BtnY, BtnW, BtnH: Single;
begin
  Fam := TGPFontFamily.Create('Segoe UI');
  FTitle := TGPFont.Create(Fam, 15, FontStyleBold, UnitPixel);
  FBody := TGPFont.Create(Fam, 11, FontStyleRegular, UnitPixel);
  FBtn := TGPFont.Create(Fam, 12, FontStyleBold, UnitPixel);
  BrDark := TGPSolidBrush.Create(GPc($003C3C3C));
  BrSoft := TGPSolidBrush.Create(GPc($00808080));
  BrWhite := TGPSolidBrush.Create(GPc($00FFFFFF));
  BrAccent := TGPSolidBrush.Create(GPc(CLR_SETUP_ACCENT));
  Fmt := TGPStringFormat.Create;
  try
    Fmt.SetAlignment(StringAlignmentCenter);

    // Tarjeta central redondeada tipo "panel vacio".
    CardW := 560; if CardW > W - 40 then CardW := W - 40;
    CardH := 210;
    CardX := (W - CardW) / 2;
    CardY := (H - CardH) / 2 - 10;
    FillRound(G, CardX, CardY, CardW, CardH, 14, $00FFFFFF);

    // Titulo.
    R := RF(CardX, CardY + 22, CardW, 26);
    G.DrawString('Define cu'#225'nto cuesta cada cambio de trabajo',
      -1, FTitle, R, Fmt, BrDark);

    // Cuerpo explicativo.
    R := RF(CardX + 30, CardY + 56, CardW - 60, 44);
    G.DrawString(
      'Cuando dos trabajos seguidos en una l'#237'nea se diferencian (color, '
      + 'substrato...), la m'#225'quina pierde tiempo prepar'#225'ndose. '
      + 'A'#241'ade reglas para que el plan lo tenga en cuenta.',
      -1, FBody, R, Fmt, BrSoft);

    // Ejemplo concreto.
    Ej := 'Ejemplo:  al cambiar de color  '#8594'  +15 min';
    R := RF(CardX, CardY + 108, CardW, 22);
    G.DrawString(Ej, -1, FBody, R, Fmt, BrAccent);

    // Boton "Crear primera regla" (dibujado; el Click del control lo dispara).
    BtnW := 210; BtnH := 40;
    BtnX := CardX + (CardW - BtnW) / 2;
    BtnY := CardY + CardH - 58;
    FillRound(G, BtnX, BtnY, BtnW, BtnH, 8, CLR_SETUP_ACCENT);
    R := RF(BtnX, BtnY + 11, BtnW, 20);
    G.DrawString('+  Crear primera regla', -1, FBtn, R, Fmt, BrWhite);
  finally
    Fmt.Free; BrAccent.Free; BrWhite.Free; BrSoft.Free; BrDark.Free;
    FBtn.Free; FBody.Free; FTitle.Free; Fam.Free;
  end;
end;

procedure TSetupIllustration.DrawTimeline(G: TGPGraphics; W, H: Single);
const
  COLORS: array[0..2] of TColor =
    ($00C0803A, $005AA84E, $008E5AB0);  // 3 valores del atributo (BGR: azul/verde/morado)
  VAL_LBL: array[0..2] of string = ('A', 'B', 'C');
  // Fila CONCEPTUAL: gap SOLO al cambiar el valor. Anchos distintos = trabajos
  // distintos; el gap NO depende de que el trabajo sea distinto, sino del valor.
  SEQ_CONC:  array[0..6] of Integer = (0, 0, 0, 1, 1, 0, 2);
  WID_CONC:  array[0..6] of Single  = (1.0, 0.7, 1.3, 0.9, 1.2, 1.0, 0.8);
  // Fila "Mezclado" (muchos cambios) y "Agrupando" (pocos): la comparativa.
  SEQ_MIX:   array[0..7] of Integer = (0, 1, 0, 2, 1, 0, 2, 1);
  SEQ_GRP:   array[0..7] of Integer = (0, 0, 0, 1, 1, 1, 2, 2);
  LBL_W = 116;              // ancho columna de etiqueta izquierda
  TOT_W = 128;              // ancho columna de total derecha (reservada)
var
  Fam: TGPFontFamily;
  FLbl, FSmall, FTiny, FTitle, FBadge: TGPFont;
  BrDark, BrSoft, BrRed, BrGreen: TGPSolidBrush;
  PenSep: TGPPen;
  FmtL, FmtR, FmtC: TGPStringFormat;
  R: TGPRectF;
  RowY, BlockH, ChgW, TrackX, TrackW, ChipX: Single;
  ChangesMix, ChangesGrp, ChangesConc, Mins, K: Integer;
  AttrLbl: string;

  // Dibuja una fila de bloques (anchos variables opcionales) en [TrackX..+TrackW].
  // Intercala hueco rojo con badge "+N" SOLO cuando el valor (color) cambia.
  // ADrawBadge: si True, pone el "+min" encima de cada cambio.
  procedure DrawRow(const ASeq: array of Integer; const AWidths: array of Single;
    ATop: Single; ADrawBadge: Boolean; out AChanges: Integer);
  var
    KK, Changes, Cnt: Integer;
    X, Avail, WSum, Unit_, BW: Single;
    HasW: Boolean;
    Rb: TGPRectF;
  begin
    Cnt := Length(ASeq);
    HasW := Length(AWidths) = Cnt;
    Changes := 0;
    for KK := 1 to High(ASeq) do
      if ASeq[KK] <> ASeq[KK - 1] then Inc(Changes);
    AChanges := Changes;

    Avail := TrackW - Changes * ChgW - (Cnt - 1 - Changes) * 4;
    if Avail < Cnt * 12 then Avail := Cnt * 12;
    if HasW then
    begin
      WSum := 0;
      for KK := 0 to Cnt - 1 do WSum := WSum + AWidths[KK];
    end
    else
      WSum := Cnt;
    Unit_ := Avail / WSum;

    X := TrackX;
    for KK := 0 to High(ASeq) do
    begin
      if KK > 0 then
      begin
        if ASeq[KK] <> ASeq[KK - 1] then
        begin
          // Hueco de cambio (rojo) = tiempo de preparacion.
          FillRound(G, X + 1, ATop + BlockH / 2 - 3, ChgW - 2, 6, 3, $003A3AC0);
          // Badge "+min" encima del cambio.
          if ADrawBadge then
          begin
            Rb := RF(X - 14, ATop - 15, ChgW + 26, 13);
            G.DrawString(Format('+%d', [Mins]), -1, FBadge, Rb, FmtC, BrRed);
          end;
          X := X + ChgW;
        end
        else
          X := X + 4;  // gap fino entre bloques del mismo valor (sin cambio)
      end;
      if HasW then BW := AWidths[KK] * Unit_ else BW := Unit_;
      FillRound(G, X, ATop, BW, BlockH, 4, COLORS[ASeq[KK]]);
      X := X + BW;
    end;
  end;

  procedure NoWidths(out A: TArray<Single>);
  begin
    SetLength(A, 0);
  end;

var
  Dummy: TArray<Single>;
begin
  Fam := TGPFontFamily.Create('Segoe UI');
  FTitle := TGPFont.Create(Fam, 12, FontStyleBold, UnitPixel);
  FLbl := TGPFont.Create(Fam, 11, FontStyleBold, UnitPixel);
  FSmall := TGPFont.Create(Fam, 10, FontStyleRegular, UnitPixel);
  FTiny := TGPFont.Create(Fam, 9, FontStyleRegular, UnitPixel);
  FBadge := TGPFont.Create(Fam, 9, FontStyleBold, UnitPixel);
  BrDark := TGPSolidBrush.Create(GPc($003C3C3C));
  BrSoft := TGPSolidBrush.Create(GPc($00808080));
  BrRed := TGPSolidBrush.Create(GPc($002020C0));
  BrGreen := TGPSolidBrush.Create(GPc($00389848));
  PenSep := TGPPen.Create(GPc($00E0E0E0), 1);
  FmtL := TGPStringFormat.Create;
  FmtR := TGPStringFormat.Create;
  FmtC := TGPStringFormat.Create;
  NoWidths(Dummy);
  try
    FmtL.SetAlignment(StringAlignmentNear);
    FmtR.SetAlignment(StringAlignmentFar);
    FmtC.SetAlignment(StringAlignmentCenter);
    FmtL.SetLineAlignment(StringAlignmentCenter);
    FmtR.SetLineAlignment(StringAlignmentCenter);
    FmtC.SetLineAlignment(StringAlignmentCenter);

    BlockH := 26; ChgW := 16;
    if FSetupMin > 0 then Mins := FSetupMin else Mins := 15;
    if Trim(FAttrName) <> '' then AttrLbl := FAttrName else AttrLbl := 'atributo';

    TrackX := LBL_W;
    TrackW := W - LBL_W - TOT_W - 16;
    if TrackW < 140 then TrackW := 140;

    // ── Titulo + leyenda de valores (chips de color) ──
    R := RF(14, 6, 360, 18);
    G.DrawString(Format('C'#243'mo se genera el tiempo de cambio ("%s")', [AttrLbl]),
      -1, FTitle, R, FmtL, BrDark);

    // Chips: cada color = un valor del atributo (A/B/C).
    ChipX := 380;
    R := RF(ChipX, 8, 70, 14);
    G.DrawString('Valores:', -1, FSmall, R, FmtL, BrSoft);
    ChipX := ChipX + 60;
    for K := 0 to 2 do
    begin
      FillRound(G, ChipX, 8, 16, 14, 3, COLORS[K]);
      R := RF(ChipX + 20, 7, 60, 16);
      G.DrawString(VAL_LBL[K], -1, FSmall, R, FmtL, BrDark);
      ChipX := ChipX + 44;
    end;

    // ── Fila 1 CONCEPTUAL: el gap aparece SOLO al cambiar de valor ──
    RowY := 40;
    R := RF(14, RowY - 2, LBL_W - 8, BlockH + 4);
    G.DrawString('El cambio', -1, FLbl, R, FmtL, BrDark);
    DrawRow(SEQ_CONC, WID_CONC, RowY, True, ChangesConc);
    R := RF(W - TOT_W - 8, RowY, TOT_W, BlockH);
    G.DrawString(Format('%d cambios', [ChangesConc]), -1, FSmall, R, FmtR, BrRed);

    // Nota explicativa bajo la fila conceptual.
    R := RF(LBL_W, RowY + BlockH + 3, W - LBL_W - 16, 14);
    G.DrawString(
      'Trabajos distintos (distinto tama'#241'o) con el MISMO valor van pegados '
      + '(sin cambio). El hueco rojo aparece solo donde cambia el valor.',
      -1, FTiny, R, FmtL, BrSoft);

    // Separador.
    G.DrawLine(PenSep, 14, RowY + BlockH + 24, W - 14, RowY + BlockH + 24);

    // ── Fila 2: MEZCLADO vs AGRUPANDO (la comparativa) ──
    RowY := 96;
    R := RF(14, RowY - 2, LBL_W - 8, BlockH);
    G.DrawString('Mezclado', -1, FLbl, R, FmtL, BrDark);
    DrawRow(SEQ_MIX, Dummy, RowY, False, ChangesMix);
    R := RF(W - TOT_W - 8, RowY, TOT_W, BlockH);
    G.DrawString(Format('%d cambios = %d min', [ChangesMix, ChangesMix * Mins]),
      -1, FSmall, R, FmtR, BrRed);

    RowY := 130;
    R := RF(14, RowY - 2, LBL_W - 8, BlockH);
    G.DrawString('Agrupando', -1, FLbl, R, FmtL, BrDark);
    DrawRow(SEQ_GRP, Dummy, RowY, False, ChangesGrp);
    R := RF(W - TOT_W - 8, RowY, TOT_W, BlockH);
    G.DrawString(Format('%d cambios = %d min', [ChangesGrp, ChangesGrp * Mins]),
      -1, FSmall, R, FmtR, BrGreen);

    // ── Callout de conclusion (fondo verde suave) ──
    FillRound(G, 14, 168, W - 28, 30, 8, $00E6F4E9);
    R := RF(28, 168, W - 56, 30);
    G.DrawString(
      Format('  '#8594'  Agrupar por "%s" pasa de %d a %d cambios: ahorras %d min '
        + 'de preparaci'#243'n en este ejemplo.',
        [AttrLbl, ChangesMix, ChangesGrp, (ChangesMix - ChangesGrp) * Mins]),
      -1, FTitle, R, FmtL, BrGreen);
  finally
    FmtC.Free; FmtR.Free; FmtL.Free; PenSep.Free;
    BrGreen.Free; BrRed.Free; BrSoft.Free; BrDark.Free;
    FBadge.Free; FTiny.Free; FSmall.Free; FLbl.Free; FTitle.Free; Fam.Free;
  end;
end;

{ ═══════════════════════════════════════════════════════ }
{  TfrmPlanningRulesEditor                                }
{ ═══════════════════════════════════════════════════════ }

class function TfrmPlanningRulesEditor.Execute(AEngine: TPlanningRuleEngine): Boolean;
var
  F: TfrmPlanningRulesEditor;
  I: Integer;
begin
  F := TfrmPlanningRulesEditor.Create(Application);
  try
    F.FEngine := AEngine;
    F.FFields := AEngine.GetAvailableFields;
    // Ahora que FFields esta cargado, poblar el tab "Tiempo de cambio" (sus
    // combos de Atributo dependen de FFields). La estructura del tab ya se creo
    // en FormCreate; aqui solo se cargan reglas y cards.
    F.PopulateSetupTab;

    F.FProfiles := TList<TPlanningProfile>.Create;
    for I := 0 to AEngine.ProfileCount - 1 do
      F.FProfiles.Add(AEngine.GetProfile(I));
    F.FActiveIdx := AEngine.ActiveIndex;

    F.RefreshProfileCombo;

    if F.FProfiles.Count > 0 then
    begin
      if F.FActiveIdx < 0 then F.FActiveIdx := 0;
      F.cmbProfiles.ItemIndex := F.FActiveIdx;
      F.LoadProfile(F.FActiveIdx);
    end;

    // La carga inicial (LoadProfile/PopulateSetupTab) puede haber disparado
    // eventos de cambio en los controles: limpiar los flags para que solo
    // cuenten los cambios REALES del usuario tras abrir.
    F.FDirtyRules := False;
    F.FDirtySetup := False;

    // Guardado in-place por pestana: "Guardar reglas" (Tab1 -> engine) y
    // "Guardar tiempos" (Tab2 -> BD). Cerrar con la X descarta lo no guardado.
    // Result indica si se guardo algo, para que el llamador refresque.
    F.ShowModal;
    Result := F.FSavedAtLeastOnce;
  finally
    F.Free;
  end;
end;

procedure TfrmPlanningRulesEditor.FormCreate(Sender: TObject);
begin
  FSortCards := TList<TSortCard>.Create;
  FFilterCards := TList<TFilterCard>.Create;
  FGroupCards := TList<TGroupCard>.Create;
  FSetupCards := TList<TSetupCard>.Create;

  // Envolver el contenido existente (pnlMain) en un PageControl con 2 pestanas,
  // sin tocar el DFM: Tab1 reparenta pnlMain (Ordenacion/Filtro/Agrupacion) y
  // Tab2 se construye por codigo (Tiempo de cambio).
  FPages := TPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.Align := alClient;

  FTabRules := TTabSheet.Create(FPages);
  FTabRules.PageControl := FPages;
  FTabRules.Caption := 'Ordenaci'#243'n y agrupaci'#243'n';

  FTabSetup := TTabSheet.Create(FPages);
  FTabSetup.PageControl := FPages;
  FTabSetup.Caption := 'Tiempo de cambio';

  // Mover el panel principal (con las 3 columnas) dentro de la 1a pestana.
  // El PageControl (alClient) ocupa todo; ya no hay panel inferior (el guardado
  // vive en la barra de perfiles de pnlMain).
  pnlMain.Parent := FTabRules;
  pnlMain.Align := alClient;

  BuildSetupTab;

  // Ayuda contextual: boton '?' en el caption + F1 (patron MD a disco).
  THelpViewer.InstallHelp(Self, 'uPlanningRulesEditor', 'Reglas de Planificaci'#243'n');
end;

procedure TfrmPlanningRulesEditor.FormDestroy(Sender: TObject);
begin
  FSortCards.Free;
  FFilterCards.Free;
  FGroupCards.Free;
  FSetupCards.Free;
  FProfiles.Free;
end;

procedure TfrmPlanningRulesEditor.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

{ --- Profiles --- }

procedure TfrmPlanningRulesEditor.RefreshProfileCombo;
var
  I: Integer;
begin
  cmbProfiles.Items.BeginUpdate;
  try
    cmbProfiles.Items.Clear;
    for I := 0 to FProfiles.Count - 1 do
      cmbProfiles.Items.Add(FProfiles[I].Name);
  finally
    cmbProfiles.Items.EndUpdate;
  end;
end;

procedure TfrmPlanningRulesEditor.cmbProfilesChange(Sender: TObject);
begin
  SaveCurrentProfile;
  FActiveIdx := cmbProfiles.ItemIndex;
  LoadProfile(FActiveIdx);
end;

procedure TfrmPlanningRulesEditor.btnAddProfileClick(Sender: TObject);
var
  S: string;
  P: TPlanningProfile;
begin
  S := '';
  if not InputQuery('Nuevo perfil', 'Nombre del perfil:', S) then Exit;
  if Trim(S) = '' then Exit;

  SaveCurrentProfile;

  P.Name := Trim(S);
  P.Description := '';
  SetLength(P.SortRules, 0);
  SetLength(P.FilterRules, 0);

  FProfiles.Add(P);
  RefreshProfileCombo;
  FActiveIdx := FProfiles.Count - 1;
  cmbProfiles.ItemIndex := FActiveIdx;
  LoadProfile(FActiveIdx);
end;

procedure TfrmPlanningRulesEditor.btnDeleteProfileClick(Sender: TObject);
begin
  if (FActiveIdx < 0) or (FActiveIdx >= FProfiles.Count) then Exit;
  if MessageDlg('Eliminar perfil "' + FProfiles[FActiveIdx].Name + '"?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  FProfiles.Delete(FActiveIdx);
  if FActiveIdx >= FProfiles.Count then
    FActiveIdx := FProfiles.Count - 1;

  RefreshProfileCombo;
  if FActiveIdx >= 0 then
  begin
    cmbProfiles.ItemIndex := FActiveIdx;
    LoadProfile(FActiveIdx);
  end
  else
  begin
    RebuildSortCards;
    RebuildFilterCards;
    RebuildGroupCards;
    UpdateCounts;
  end;
end;

procedure TfrmPlanningRulesEditor.btnRenameProfileClick(Sender: TObject);
var
  S: string;
  P: TPlanningProfile;
begin
  if (FActiveIdx < 0) or (FActiveIdx >= FProfiles.Count) then Exit;
  S := FProfiles[FActiveIdx].Name;
  if not InputQuery('Renombrar perfil', 'Nuevo nombre:', S) then Exit;
  if Trim(S) = '' then Exit;

  P := FProfiles[FActiveIdx];
  P.Name := Trim(S);
  FProfiles[FActiveIdx] := P;
  RefreshProfileCombo;
  cmbProfiles.ItemIndex := FActiveIdx;
end;

procedure TfrmPlanningRulesEditor.edtDescriptionChange(Sender: TObject);
var
  P: TPlanningProfile;
begin
  if (FActiveIdx < 0) or (FActiveIdx >= FProfiles.Count) then Exit;
  P := FProfiles[FActiveIdx];
  P.Description := edtDescription.Text;
  FProfiles[FActiveIdx] := P;
end;

{ --- Load / Save --- }

procedure TfrmPlanningRulesEditor.LoadProfile(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FProfiles.Count) then
  begin
    edtDescription.Text := '';
    edtDescription.Enabled := False;
    RebuildSortCards;
    RebuildFilterCards;
    RebuildGroupCards;
    UpdateCounts;
    Exit;
  end;

  edtDescription.Enabled := True;
  edtDescription.Text := FProfiles[AIndex].Description;
  RebuildSortCards;
  RebuildFilterCards;
  RebuildGroupCards;
  UpdateCounts;
end;

procedure TfrmPlanningRulesEditor.SaveCurrentProfile;
var
  P: TPlanningProfile;
  I: Integer;
begin
  if (FActiveIdx < 0) or (FActiveIdx >= FProfiles.Count) then Exit;
  // Consolidar el perfil en memoria implica cambios en Tab1. DoSaveRules llama a
  // esto y luego limpia FDirtyRules, asi que no interfiere.
  MarkDirtyRules;

  P := FProfiles[FActiveIdx];

  SetLength(P.SortRules, FSortCards.Count);
  for I := 0 to FSortCards.Count - 1 do
    P.SortRules[I] := FSortCards[I].GetRule;

  SetLength(P.FilterRules, FFilterCards.Count);
  for I := 0 to FFilterCards.Count - 1 do
    P.FilterRules[I] := FFilterCards[I].GetRule;

  SetLength(P.GroupRules, FGroupCards.Count);
  for I := 0 to FGroupCards.Count - 1 do
    P.GroupRules[I] := FGroupCards[I].GetRule;

  FProfiles[FActiveIdx] := P;
end;

procedure TfrmPlanningRulesEditor.UpdateCounts;
begin
  lblSortCount.Caption := IntToStr(FSortCards.Count);
  lblFilterCount.Caption := IntToStr(FFilterCards.Count);
  lblGroupCount.Caption := IntToStr(FGroupCards.Count);
end;

{ --- Rebuild cards --- }

procedure TfrmPlanningRulesEditor.RebuildSortCards;
var
  I: Integer;
  P: TPlanningProfile;
  Card: TSortCard;
begin
  for I := FSortCards.Count - 1 downto 0 do
    FSortCards[I].Free;
  FSortCards.Clear;

  if (FActiveIdx < 0) or (FActiveIdx >= FProfiles.Count) then Exit;
  P := FProfiles[FActiveIdx];

  for I := 0 to High(P.SortRules) do
  begin
    Card := TSortCard.Create(sbSort, I, P.SortRules[I], FFields);
    Card.OnChanged := OnSortChanged;
    Card.OnDelete := OnSortDelete;
    Card.OnMoveUp := OnSortMoveUp;
    Card.OnMoveDown := OnSortMoveDown;
    FSortCards.Add(Card);
  end;

  UpdateCounts;
end;

procedure TfrmPlanningRulesEditor.RebuildFilterCards;
var
  I: Integer;
  P: TPlanningProfile;
  Card: TFilterCard;
begin
  for I := FFilterCards.Count - 1 downto 0 do
    FFilterCards[I].Free;
  FFilterCards.Clear;

  if (FActiveIdx < 0) or (FActiveIdx >= FProfiles.Count) then Exit;
  P := FProfiles[FActiveIdx];

  for I := 0 to High(P.FilterRules) do
  begin
    Card := TFilterCard.Create(sbFilter, I, P.FilterRules[I], FFields);
    Card.OnChanged := OnFilterChanged;
    Card.OnDelete := OnFilterDelete;
    FFilterCards.Add(Card);
  end;

  UpdateCounts;
end;

{ --- Card events --- }

procedure TfrmPlanningRulesEditor.OnSortChanged(Sender: TObject);
begin
  SaveCurrentProfile;
end;

procedure TfrmPlanningRulesEditor.OnSortDelete(Sender: TObject);
var
  Idx, I: Integer;
begin
  Idx := (Sender as TSortCard).FIndex;
  SaveCurrentProfile;

  var P := FProfiles[FActiveIdx];
  var NewRules: TArray<TSortRule>;
  SetLength(NewRules, Length(P.SortRules) - 1);
  var N := 0;
  for I := 0 to High(P.SortRules) do
    if I <> Idx then
    begin
      NewRules[N] := P.SortRules[I];
      Inc(N);
    end;
  P.SortRules := NewRules;
  FProfiles[FActiveIdx] := P;
  RebuildSortCards;
end;

procedure TfrmPlanningRulesEditor.OnSortMoveUp(Sender: TObject);
var
  Idx: Integer;
  Tmp: TSortRule;
begin
  Idx := (Sender as TSortCard).FIndex;
  if Idx <= 0 then Exit;
  SaveCurrentProfile;

  var P := FProfiles[FActiveIdx];
  Tmp := P.SortRules[Idx];
  P.SortRules[Idx] := P.SortRules[Idx - 1];
  P.SortRules[Idx - 1] := Tmp;
  FProfiles[FActiveIdx] := P;
  RebuildSortCards;
end;

procedure TfrmPlanningRulesEditor.OnSortMoveDown(Sender: TObject);
var
  Idx: Integer;
  Tmp: TSortRule;
begin
  Idx := (Sender as TSortCard).FIndex;
  SaveCurrentProfile;

  var P := FProfiles[FActiveIdx];
  if Idx >= High(P.SortRules) then Exit;
  Tmp := P.SortRules[Idx];
  P.SortRules[Idx] := P.SortRules[Idx + 1];
  P.SortRules[Idx + 1] := Tmp;
  FProfiles[FActiveIdx] := P;
  RebuildSortCards;
end;

procedure TfrmPlanningRulesEditor.OnFilterChanged(Sender: TObject);
begin
  SaveCurrentProfile;
end;

procedure TfrmPlanningRulesEditor.OnFilterDelete(Sender: TObject);
var
  Idx, I: Integer;
begin
  Idx := (Sender as TFilterCard).FIndex;
  SaveCurrentProfile;

  var P := FProfiles[FActiveIdx];
  var NewRules: TArray<TFilterRule>;
  SetLength(NewRules, Length(P.FilterRules) - 1);
  var N := 0;
  for I := 0 to High(P.FilterRules) do
    if I <> Idx then
    begin
      NewRules[N] := P.FilterRules[I];
      Inc(N);
    end;
  P.FilterRules := NewRules;
  FProfiles[FActiveIdx] := P;
  RebuildFilterCards;
end;

{ --- Group cards --- }

procedure TfrmPlanningRulesEditor.RebuildGroupCards;
var
  I: Integer;
  P: TPlanningProfile;
  Card: TGroupCard;
begin
  for I := FGroupCards.Count - 1 downto 0 do
    FGroupCards[I].Free;
  FGroupCards.Clear;

  if (FActiveIdx < 0) or (FActiveIdx >= FProfiles.Count) then Exit;
  P := FProfiles[FActiveIdx];

  for I := 0 to High(P.GroupRules) do
  begin
    Card := TGroupCard.Create(sbGroup, I, P.GroupRules[I], FFields);
    Card.OnChanged := OnGroupChanged;
    Card.OnDelete := OnGroupDelete;
    FGroupCards.Add(Card);
  end;

  UpdateCounts;
end;

procedure TfrmPlanningRulesEditor.OnGroupChanged(Sender: TObject);
begin
  SaveCurrentProfile;
end;

procedure TfrmPlanningRulesEditor.OnGroupDelete(Sender: TObject);
var
  Idx, I: Integer;
begin
  Idx := (Sender as TGroupCard).FIndex;
  SaveCurrentProfile;

  var P := FProfiles[FActiveIdx];
  var NewRules: TArray<TGroupRule>;
  SetLength(NewRules, Length(P.GroupRules) - 1);
  var N := 0;
  for I := 0 to High(P.GroupRules) do
    if I <> Idx then
    begin
      NewRules[N] := P.GroupRules[I];
      Inc(N);
    end;
  P.GroupRules := NewRules;
  FProfiles[FActiveIdx] := P;
  RebuildGroupCards;
end;

{ --- Add rules --- }

procedure TfrmPlanningRulesEditor.btnAddGroupClick(Sender: TObject);
var
  GR: TGroupRule;
begin
  if (FActiveIdx < 0) or (FActiveIdx >= FProfiles.Count) then
  begin
    ShowMessage('Primero cree un perfil.');
    Exit;
  end;
  SaveCurrentProfile;

  GR.FieldName := 'CodigoColor';
  GR.Mode := gmSameCenter;
  GR.Weight := 5;
  GR.Enabled := True;

  var P := FProfiles[FActiveIdx];
  SetLength(P.GroupRules, Length(P.GroupRules) + 1);
  P.GroupRules[High(P.GroupRules)] := GR;
  FProfiles[FActiveIdx] := P;
  RebuildGroupCards;
end;

procedure TfrmPlanningRulesEditor.btnAddSortClick(Sender: TObject);
var
  SR: TSortRule;
begin
  if (FActiveIdx < 0) or (FActiveIdx >= FProfiles.Count) then
  begin
    ShowMessage('Primero cree un perfil.');
    Exit;
  end;
  SaveCurrentProfile;

  SR.FieldName := 'Prioridad';
  SR.Direction := sdAsc;
  SR.Weight := 5;
  SR.Enabled := True;

  var P := FProfiles[FActiveIdx];
  SetLength(P.SortRules, Length(P.SortRules) + 1);
  P.SortRules[High(P.SortRules)] := SR;
  FProfiles[FActiveIdx] := P;
  RebuildSortCards;
end;

procedure TfrmPlanningRulesEditor.btnAddFilterClick(Sender: TObject);
var
  FR: TFilterRule;
begin
  if (FActiveIdx < 0) or (FActiveIdx >= FProfiles.Count) then
  begin
    ShowMessage('Primero cree un perfil.');
    Exit;
  end;
  SaveCurrentProfile;

  FR.FieldName := 'Prioridad';
  FR.Operator := foEquals;
  FR.Value := '';
  FR.Action := faInclude;
  FR.TargetCentreId := -1;
  FR.Enabled := True;

  var P := FProfiles[FActiveIdx];
  SetLength(P.FilterRules, Length(P.FilterRules) + 1);
  P.FilterRules[High(P.FilterRules)] := FR;
  FProfiles[FActiveIdx] := P;
  RebuildFilterCards;
end;

{ --- Tab "Tiempo de cambio" (setup secuencia-dependiente) --- }

procedure TfrmPlanningRulesEditor.BuildSetupTab;
var
  pnlHdr, pnlKpi: TPanel;
  lblTitle, lblHelp: TLabel;
  btnAdd: TButton;
  Centres: TArray<TCentreTreball>;
  I: Integer;
begin
  // Cargar codigos de centro/linea para el combo de las cards.
  SetLength(FCentres, 0);
  if Assigned(DMPlanner) and Assigned(DMPlanner.CentresRepo) then
  begin
    Centres := DMPlanner.CentresRepo.GetAll;
    SetLength(FCentres, Length(Centres));
    for I := 0 to High(Centres) do
      FCentres[I] := Centres[I].CodiCentre;
  end;

  // Cabecera con titulo, ayuda breve y boton anadir.
  pnlHdr := TPanel.Create(FTabSetup);
  pnlHdr.Parent := FTabSetup;
  pnlHdr.Align := alTop;
  pnlHdr.Height := 96;
  pnlHdr.BevelOuter := bvNone;
  pnlHdr.Color := CLR_BOARD_BG;
  pnlHdr.ParentBackground := False;

  lblTitle := TLabel.Create(pnlHdr);
  lblTitle.Parent := pnlHdr;
  lblTitle.SetBounds(14, 12, 400, 18);
  lblTitle.Caption := #$23F1' Tiempo de cambio entre trabajos';
  lblTitle.Font.Name := 'Segoe UI Semibold';
  lblTitle.Font.Height := -14;
  lblTitle.Font.Color := $003C3C3C;

  // Texto de ayuda: ancho limitado para que NO llegue a los botones de la
  // derecha (word-wrap antes de solaparse). Deja ~300px de margen derecho.
  lblHelp := TLabel.Create(pnlHdr);
  lblHelp.Parent := pnlHdr;
  lblHelp.SetBounds(14, 34, 660, 34);
  lblHelp.Anchors := [akLeft, akTop];
  lblHelp.Caption :=
    'Cuando dos trabajos seguidos en una l'#237'nea se diferencian en algo (color, '
    + 'substrato...), la m'#225'quina pierde tiempo preparando el cambio.' + sLineBreak
    + 'Aqu'#237' defines cu'#225'ntos minutos cuesta cada tipo de cambio. Si un cambio '
    + 'dispara varias reglas, los minutos se suman.';
  lblHelp.Font.Height := -11;
  lblHelp.Font.Color := $00707070;
  lblHelp.WordWrap := True;

  // Botones "+ Anadir regla" y "Guardar tiempos": misma altura (30px), fila
  // superior derecha. Guardar es independiente del "Guardar reglas" del Tab1.
  FBtnGuardarSetup := TButton.Create(pnlHdr);
  FBtnGuardarSetup.Parent := pnlHdr;
  FBtnGuardarSetup.SetBounds(pnlHdr.Width - 148, 9, 134, 30);
  FBtnGuardarSetup.Anchors := [akTop, akRight];
  FBtnGuardarSetup.Caption := 'Guardar tiempos';
  FBtnGuardarSetup.Font.Name := 'Segoe UI Semibold';
  FBtnGuardarSetup.Font.Color := $003C3C3C;
  FBtnGuardarSetup.Font.Height := -12;
  FBtnGuardarSetup.ParentFont := False;
  FBtnGuardarSetup.OnClick := OnGuardarSetupClick;

  btnAdd := TButton.Create(pnlHdr);
  btnAdd.Parent := pnlHdr;
  btnAdd.SetBounds(pnlHdr.Width - 288, 9, 130, 30);
  btnAdd.Anchors := [akTop, akRight];
  btnAdd.Caption := '+ A'#241'adir regla';
  btnAdd.OnClick := OnAddSetupClick;

  // Checkbox "Ver ilustracion": muestra u oculta el panel ilustrativo inferior.
  FChkVerIlustr := TCheckBox.Create(pnlHdr);
  FChkVerIlustr.Parent := pnlHdr;
  FChkVerIlustr.SetBounds(pnlHdr.Width - 288, 46, 130, 18);
  FChkVerIlustr.Anchors := [akTop, akRight];
  FChkVerIlustr.Caption := 'Ver ilustraci'#243'n';
  FChkVerIlustr.Checked := True;
  FChkVerIlustr.OnClick := OnVerIlustrClick;

  // Contador de reglas activas: bajo los botones, alineado a la derecha, con
  // ancho amplio para que no se corte el aviso de duplicados.
  FLblSetupCount := TLabel.Create(pnlHdr);
  FLblSetupCount.Parent := pnlHdr;
  FLblSetupCount.SetBounds(14, 66, pnlHdr.Width - 28, 16);
  FLblSetupCount.Anchors := [akLeft, akTop, akRight];
  FLblSetupCount.Alignment := taRightJustify;
  FLblSetupCount.AutoSize := False;
  FLblSetupCount.Layout := tlCenter;
  FLblSetupCount.Caption := '';
  FLblSetupCount.Font.Height := -12;
  FLblSetupCount.Font.Color := CLR_SETUP_ACCENT;
  FLblSetupCount.Font.Style := [fsBold];

  // Panel KPI (abajo): tiempo de cambio del plan actual con/sin agrupacion.
  pnlKpi := TPanel.Create(FTabSetup);
  pnlKpi.Parent := FTabSetup;
  pnlKpi.Align := alBottom;
  pnlKpi.Height := 84;
  pnlKpi.BevelOuter := bvNone;
  pnlKpi.Color := $00201917;   // oscuro, estilo panel de impacto
  pnlKpi.ParentBackground := False;

  FLblSetupKpi := TLabel.Create(pnlKpi);
  FLblSetupKpi.Parent := pnlKpi;
  FLblSetupKpi.SetBounds(18, 14, 800, 30);
  FLblSetupKpi.Caption := 'Tiempo de cambio del plan actual: --';
  FLblSetupKpi.Font.Name := 'Segoe UI Semibold';
  FLblSetupKpi.Font.Height := -18;
  FLblSetupKpi.Font.Color := clWhite;

  FLblSetupKpiSub := TLabel.Create(pnlKpi);
  FLblSetupKpiSub.Parent := pnlKpi;
  FLblSetupKpiSub.SetBounds(18, 48, 800, 24);
  FLblSetupKpiSub.Caption :=
    'Se calcula sobre el plan ya colocado, sumando los cambios entre trabajos '
    + 'consecutivos de cada l'#237'nea.';
  FLblSetupKpiSub.Font.Height := -11;
  FLblSetupKpiSub.Font.Color := $00B0A8A0;

  // Ilustracion dinamica (empty-state / mini-timeline), sobre el KPI.
  FIllustration := TSetupIllustration.Create(FTabSetup);
  FIllustration.Parent := FTabSetup;
  FIllustration.Align := alBottom;
  FIllustration.Height := 214;
  FIllustration.Color := CLR_BOARD_BG;
  FIllustration.OnCreateFirst := OnAddSetupClick;

  // Scrollbox central con las cards.
  FSbSetup := TScrollBox.Create(FTabSetup);
  FSbSetup.Parent := FTabSetup;
  FSbSetup.Align := alClient;
  FSbSetup.BorderStyle := bsNone;
  FSbSetup.Color := CLR_COLUMN_BG;
  FSbSetup.ParentColor := False;
  FSbSetup.ParentBackground := False;
  // NOTA: la carga de reglas/cards NO se hace aqui. BuildSetupTab corre en
  // FormCreate, ANTES de que Execute asigne FFields (los atributos disponibles).
  // El contenido se puebla en PopulateSetupTab, llamado desde Execute con
  // FFields ya cargado (si no, el combo Atributo saldria vacio).
end;

procedure TfrmPlanningRulesEditor.PopulateSetupTab;
begin
  LoadSetupRulesFromDB;
  RebuildSetupCards;
  RecalcSetupKpi;
end;

procedure TfrmPlanningRulesEditor.LoadSetupRulesFromDB;
var
  Profile: TSetupProfile;
begin
  SetLength(FSetupRules, 0);
  if Assigned(DMPlanner) then
  begin
    Profile := DMPlanner.GetActiveSetupProfile;
    FSetupRules := Profile.Rules;
  end;
end;

function TfrmPlanningRulesEditor.CollectSetupRules: TArray<TSetupRule>;
var
  I: Integer;
begin
  SetLength(Result, FSetupCards.Count);
  for I := 0 to FSetupCards.Count - 1 do
    Result[I] := FSetupCards[I].GetRule;
end;

procedure TfrmPlanningRulesEditor.SaveSetupRulesToDB;
begin
  if Assigned(DMPlanner) then
    DMPlanner.SaveSetupRules(CollectSetupRules);
end;

procedure TfrmPlanningRulesEditor.RebuildSetupCards;
var
  I: Integer;
  Card: TSetupCard;
begin
  for I := FSetupCards.Count - 1 downto 0 do
    FSetupCards[I].Free;
  FSetupCards.Clear;

  for I := 0 to High(FSetupRules) do
  begin
    Card := TSetupCard.Create(FSbSetup, I, FSetupRules[I], FFields, FCentres);
    Card.OnChanged := OnSetupChanged;
    Card.OnDelete := OnSetupDelete;
    FSetupCards.Add(Card);
  end;
  UpdateSetupCounts;
  UpdateIllustration;
  UpdateSetupHeader;
end;

procedure TfrmPlanningRulesEditor.UpdateIllustration;
var
  I: Integer;
  HasActive: Boolean;
  Attr: string;
  Mins: Integer;
begin
  if not Assigned(FIllustration) then Exit;

  // Buscar la primera regla ACTIVA para usarla como ejemplo en la ilustracion.
  HasActive := False;
  Attr := 'color';
  Mins := 15;
  for I := 0 to High(FSetupRules) do
    if FSetupRules[I].Enabled and (Trim(FSetupRules[I].AttrName) <> '') then
    begin
      HasActive := True;
      Attr := FSetupRules[I].AttrName;
      if FSetupRules[I].SetupMin > 0 then Mins := FSetupRules[I].SetupMin;
      Break;
    end;

  // Sin reglas -> empty-state grande y central. Con reglas -> timeline PRO
  // (leyenda + fila conceptual + comparativa + callout) que necesita mas alto.
  if HasActive then
    FIllustration.Height := 214
  else
    FIllustration.Height := 300;
  FIllustration.SetState(HasActive, Attr, Mins);
end;

procedure TfrmPlanningRulesEditor.UpdateSetupHeader;
var
  I, J, Activas, Dups: Integer;
  KeyI, KeyJ: string;
begin
  if not Assigned(FLblSetupCount) then Exit;

  Activas := 0;
  for I := 0 to High(FSetupRules) do
    if FSetupRules[I].Enabled and (Trim(FSetupRules[I].AttrName) <> '') then
      Inc(Activas);

  // Detectar duplicados: misma Linea + mismo Atributo en dos reglas activas.
  Dups := 0;
  for I := 0 to High(FSetupRules) do
  begin
    if not FSetupRules[I].Enabled then Continue;
    KeyI := UpperCase(Trim(FSetupRules[I].CentreCode) + '|' + Trim(FSetupRules[I].AttrName));
    for J := I + 1 to High(FSetupRules) do
    begin
      if not FSetupRules[J].Enabled then Continue;
      KeyJ := UpperCase(Trim(FSetupRules[J].CentreCode) + '|' + Trim(FSetupRules[J].AttrName));
      if KeyI = KeyJ then Inc(Dups);
    end;
  end;

  if Dups > 0 then
  begin
    FLblSetupCount.Font.Color := $003A3AC0;   // rojo: aviso de duplicados
    FLblSetupCount.Caption := Format(
      '%d activas  '#8226'  '#9888' %d duplicadas (misma l'#237'nea y atributo)',
      [Activas, Dups]);
  end
  else
  begin
    FLblSetupCount.Font.Color := CLR_SETUP_ACCENT;
    if Activas = 1 then
      FLblSetupCount.Caption := '1 regla activa'
    else
      FLblSetupCount.Caption := Format('%d reglas activas', [Activas]);
  end;
end;

procedure TfrmPlanningRulesEditor.UpdateSetupCounts;
var
  I: Integer;
begin
  // Reposicionar las cards por si alguna se borro.
  for I := 0 to FSetupCards.Count - 1 do
    FSetupCards[I].UpdateIndex(I);
end;

procedure TfrmPlanningRulesEditor.OnAddSetupClick(Sender: TObject);
var
  R: TSetupRule;
begin
  R.AttrName := '';
  if Length(FFields) > 0 then R.AttrName := FFields[0];
  R.SetupMin := 15;
  R.CentreCode := '';
  R.Enabled := True;
  SetLength(FSetupRules, Length(FSetupRules) + 1);
  FSetupRules[High(FSetupRules)] := R;
  RebuildSetupCards;
  RecalcSetupKpi;
  MarkDirtySetup;
end;

procedure TfrmPlanningRulesEditor.OnVerIlustrClick(Sender: TObject);
begin
  if Assigned(FIllustration) then
    FIllustration.Visible := FChkVerIlustr.Checked;
end;

procedure TfrmPlanningRulesEditor.OnSetupChanged(Sender: TObject);
begin
  // Sincronizar el array con las cards vivas para que la ilustracion (y el KPI)
  // reflejen el atributo/minutos/estado actuales.
  FSetupRules := CollectSetupRules;
  RecalcSetupKpi;
  UpdateIllustration;
  UpdateSetupHeader;
  MarkDirtySetup;
end;

procedure TfrmPlanningRulesEditor.OnSetupDelete(Sender: TObject);
var
  Card: TSetupCard;
  Idx, I: Integer;
begin
  Card := Sender as TSetupCard;
  Idx := FSetupCards.IndexOf(Card);
  if Idx < 0 then Exit;
  // Sincronizar el array de reglas con las cards vivas ANTES de reconstruir.
  FSetupRules := CollectSetupRules;
  if (Idx >= 0) and (Idx <= High(FSetupRules)) then
  begin
    for I := Idx to High(FSetupRules) - 1 do
      FSetupRules[I] := FSetupRules[I + 1];
    SetLength(FSetupRules, Length(FSetupRules) - 1);
  end;
  RebuildSetupCards;
  RecalcSetupKpi;
  MarkDirtySetup;
end;

procedure TfrmPlanningRulesEditor.RecalcSetupKpi;
var
  Engine: TSetupRuleEngine;
  Nodes: TArray<TNode>;
  DataById: TDictionary<Integer, TNodeData>;
  ByCentre: TDictionary<Integer, TList<TNode>>;
  CodeById: TDictionary<Integer, string>;
  D: TNodeData;
  N: TNode;
  Lst: TList<TNode>;
  Pair: TPair<Integer, TList<TNode>>;
  I, TotalMin, LineMin, M: Integer;
  PrevAttrs, CurrAttrs: TSetupAttrList;
  HasPrev: Boolean;
  CentreCode, Desglose: string;
begin
  TotalMin := 0;
  Desglose := '';
  if not Assigned(DMPlanner) or not Assigned(DMPlanner.NodesRepo)
     or not Assigned(DMPlanner.NodeDataRepo) then
  begin
    FLblSetupKpi.Caption := 'Tiempo de cambio del plan actual: (sin plan cargado)';
    Exit;
  end;

  Engine := TSetupRuleEngine.Create;
  DataById := TDictionary<Integer, TNodeData>.Create;
  ByCentre := TDictionary<Integer, TList<TNode>>.Create;
  CodeById := TDictionary<Integer, string>.Create;
  try
    Engine.SetRules(CollectSetupRules);
    if not Engine.HasRules then
    begin
      FLblSetupKpi.Caption := 'Tiempo de cambio del plan actual: 0 min (sin reglas activas)';
      FLblSetupKpiSub.Caption :=
        'A'#241'ade reglas arriba para cuantificar los cambios del plan.';
      Exit;
    end;

    // Mapa CentreId -> CodiCentre, para pasar al motor el codigo de linea real
    // (las reglas filtran por CentreCode; con '' nunca casaban -> KPI siempre 0).
    if Assigned(DMPlanner.CentresRepo) then
      for var C in DMPlanner.CentresRepo.GetAll do
        CodeById.AddOrSetValue(C.Id, C.CodiCentre);

    // Indexar datos por DataId.
    for D in DMPlanner.NodeDataRepo.GetAllData do
      DataById.AddOrSetValue(D.DataId, D);

    // Agrupar nodos planificados (con fecha) por centro.
    Nodes := DMPlanner.NodesRepo.GetAll;
    for N in Nodes do
    begin
      if N.StartTime <= 0 then Continue;
      if not ByCentre.TryGetValue(N.CentreId, Lst) then
      begin
        Lst := TList<TNode>.Create;
        ByCentre.Add(N.CentreId, Lst);
      end;
      Lst.Add(N);
    end;

    // Por cada centro, ordenar por inicio y sumar el setup entre consecutivos.
    for Pair in ByCentre do
    begin
      Lst := Pair.Value;
      Lst.Sort(TComparer<TNode>.Construct(
        function(const A, B: TNode): Integer
        begin
          Result := CompareDateTime(A.StartTime, B.StartTime);
        end));
      HasPrev := False;
      SetLength(PrevAttrs, 0);
      LineMin := 0;
      // Codigo de la linea de este grupo (para el filtro CentreCode de las reglas).
      if not CodeById.TryGetValue(Pair.Key, CentreCode) then
        CentreCode := '';
      for I := 0 to Lst.Count - 1 do
      begin
        if DataById.TryGetValue(Lst[I].DataId, D) then
          CurrAttrs := BuildSetupAttrsFromNode(D)
        else
          SetLength(CurrAttrs, 0);
        if HasPrev then
        begin
          M := Engine.CalcSetupMin(PrevAttrs, CurrAttrs, True, CentreCode);
          Inc(TotalMin, M);
          Inc(LineMin, M);
        end;
        PrevAttrs := CurrAttrs;
        HasPrev := True;
      end;
      // Desglose por linea (solo las que aportan tiempo).
      if LineMin > 0 then
      begin
        if CentreCode = '' then CentreCode := '(sin l'#237'nea)';
        if Desglose <> '' then Desglose := Desglose + '    ';
        Desglose := Desglose + Format('%s: %d min', [CentreCode, LineMin]);
      end;
    end;

    FLblSetupKpi.Caption := Format(
      'Tiempo de cambio del plan actual: %d min  (%.1f h)',
      [TotalMin, TotalMin / 60.0]);
    if TotalMin = 0 then
      FLblSetupKpiSub.Caption :=
        'No se detectan cambios con las reglas actuales (revisa que la l'#237'nea y el '
        + 'atributo de las reglas coincidan con trabajos ya planificados).'
    else
      FLblSetupKpiSub.Caption := 'Por l'#237'nea:   ' + Desglose;
  finally
    for Pair in ByCentre do
      Pair.Value.Free;
    ByCentre.Free;
    DataById.Free;
    CodeById.Free;
    Engine.Free;
  end;
end;

{ --- Guardar / cerrar (independiente por pestana) --- }

procedure TfrmPlanningRulesEditor.MarkDirtyRules;
begin
  FDirtyRules := True;
  if Assigned(btnGuardar) and (btnGuardar.Caption <> 'Guardar reglas') then
    btnGuardar.Caption := 'Guardar reglas';
end;

procedure TfrmPlanningRulesEditor.MarkDirtySetup;
begin
  FDirtySetup := True;
  if Assigned(FBtnGuardarSetup) and (FBtnGuardarSetup.Caption <> 'Guardar tiempos') then
    FBtnGuardarSetup.Caption := 'Guardar tiempos';
end;

// Tab 1: guarda SOLO las reglas de ordenacion/filtro/agrupacion (perfiles ->
// motor de reglas). No toca el setup.
procedure TfrmPlanningRulesEditor.DoSaveRules;
begin
  SaveCurrentProfile;
  if Assigned(FEngine) then
  begin
    while FEngine.ProfileCount > 0 do
      FEngine.DeleteProfile(0);
    for var I := 0 to FProfiles.Count - 1 do
      FEngine.AddProfile(FProfiles[I]);
    FEngine.ActiveIndex := FActiveIdx;
  end;
  FDirtyRules := False;
  FSavedAtLeastOnce := True;
end;

// Tab 2: guarda SOLO las reglas de tiempo de cambio (setup) en BD.
procedure TfrmPlanningRulesEditor.DoSaveSetup;
begin
  SaveSetupRulesToDB;
  FDirtySetup := False;
  FSavedAtLeastOnce := True;
end;

procedure TfrmPlanningRulesEditor.btnGuardarReglasClick(Sender: TObject);
begin
  DoSaveRules;
  // Feedback: guardar != salir. El dialogo sigue abierto.
  btnGuardar.Caption := 'Guardado '#$2713;
end;

procedure TfrmPlanningRulesEditor.OnGuardarSetupClick(Sender: TObject);
begin
  DoSaveSetup;
  if Assigned(FBtnGuardarSetup) then
    FBtnGuardarSetup.Caption := 'Guardado '#$2713;
end;

procedure TfrmPlanningRulesEditor.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  Msg: string;
begin
  CanClose := True;
  if not (FDirtyRules or FDirtySetup) then Exit;

  if FDirtyRules and FDirtySetup then
    Msg := 'Hay cambios sin guardar en ambas pesta'#241'as.'
  else if FDirtyRules then
    Msg := 'Hay cambios sin guardar en "Ordenaci'#243'n y agrupaci'#243'n".'
  else
    Msg := 'Hay cambios sin guardar en "Tiempo de cambio".';

  CanClose := MessageDlg(
    Msg + ' '#191'Cerrar y descartarlos?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

end.
