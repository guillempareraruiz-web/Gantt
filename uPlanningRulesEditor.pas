unit uPlanningRulesEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.ComCtrls,
  uGanttTypes, uPlanningRules, uCustomFieldDefs;

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

  TfrmPlanningRulesEditor = class(TForm)
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    pnlMain: TPanel;
    pnlProfiles: TPanel;
    lblProfile: TLabel;
    lblDescription: TLabel;
    cmbProfiles: TComboBox;
    btnAddProfile: TButton;
    btnDeleteProfile: TButton;
    btnRenameProfile: TButton;
    edtDescription: TEdit;
    pnlRules: TPanel;
    pnlSortRules: TPanel;
    pnlSortColumn: TPanel;
    pnlSortHeader: TPanel;
    lblSortTitle: TLabel;
    lblSortCount: TLabel;
    btnAddSort: TButton;
    sbSort: TScrollBox;
    pnlFilterRules: TPanel;
    pnlFilterColumn: TPanel;
    pnlFilterHeader: TPanel;
    lblFilterTitle: TLabel;
    lblFilterCount: TLabel;
    btnAddFilter: TButton;
    sbFilter: TScrollBox;
    pnlGroupRules: TPanel;
    pnlGroupColumn: TPanel;
    pnlGroupHeader: TPanel;
    lblGroupTitle: TLabel;
    lblGroupCount: TLabel;
    btnAddGroup: TButton;
    sbGroup: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
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
  public
    class function Execute(AEngine: TPlanningRuleEngine): Boolean;
  end;

var
  frmPlanningRulesEditor: TfrmPlanningRulesEditor;

implementation

{$R *.dfm}

const
  CARD_H         = 90;
  CARD_FILTER_H  = 100;
  CARD_GAP       = 8;
  CARD_MARGIN    = 10;
  CARD_RADIUS    = 8;
  ACCENT_W       = 5;

  // Trello-inspired colors
  CLR_SORT_ACCENT   = $00D09030;   // taronja
  CLR_FILTER_ACCENT = $00409850;   // verd
  CLR_GROUP_ACCENT  = $00B05090;   // porpra
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

    Result := F.ShowModal = mrOk;
    if Result then
    begin
      while AEngine.ProfileCount > 0 do
        AEngine.DeleteProfile(0);
      for I := 0 to F.FProfiles.Count - 1 do
        AEngine.AddProfile(F.FProfiles[I]);
      AEngine.ActiveIndex := F.FActiveIdx;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmPlanningRulesEditor.FormCreate(Sender: TObject);
begin
  FSortCards := TList<TSortCard>.Create;
  FFilterCards := TList<TFilterCard>.Create;
  FGroupCards := TList<TGroupCard>.Create;
end;

procedure TfrmPlanningRulesEditor.FormDestroy(Sender: TObject);
begin
  FSortCards.Free;
  FFilterCards.Free;
  FGroupCards.Free;
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

{ --- OK / Cancel --- }

procedure TfrmPlanningRulesEditor.btnOKClick(Sender: TObject);
begin
  SaveCurrentProfile;
  ModalResult := mrOk;
end;

procedure TfrmPlanningRulesEditor.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
