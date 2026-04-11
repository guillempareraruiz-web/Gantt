unit uCustomFieldEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  uGanttTypes, uCustomFieldDefs;

type
  TfrmCustomFieldEditor = class(TForm)
    pnlTop: TPanel;
    btnAdd: TButton;
    btnDelete: TButton;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    pnlCenter: TPanel;
    splitter: TSplitter;
    tvFields: TTreeView;
    pnlDetail: TPanel;
    lblFieldName: TLabel;
    lblCaption: TLabel;
    lblType: TLabel;
    lblDefault: TLabel;
    lblGrupo: TLabel;
    lblTooltip: TLabel;
    lblMinValue: TLabel;
    lblMaxValue: TLabel;
    lblFormatMask: TLabel;
    lblListValues: TLabel;
    edtFieldName: TEdit;
    edtCaption: TEdit;
    cmbType: TComboBox;
    edtDefault: TEdit;
    edtGrupo: TEdit;
    edtTooltip: TEdit;
    edtMinValue: TEdit;
    edtMaxValue: TEdit;
    edtFormatMask: TEdit;
    chkRequired: TCheckBox;
    chkReadOnly: TCheckBox;
    chkVisible: TCheckBox;
    mmoListValues: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure tvFieldsCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure tvFieldsChange(Sender: TObject; Node: TTreeNode);
    procedure tvFieldsDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure tvFieldsDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure edtFieldNameChange(Sender: TObject);
    procedure edtCaptionChange(Sender: TObject);
    procedure cmbTypeChange(Sender: TObject);
    procedure edtDefaultChange(Sender: TObject);
    procedure edtGrupoChange(Sender: TObject);
    procedure edtTooltipChange(Sender: TObject);
    procedure edtMinValueChange(Sender: TObject);
    procedure edtMaxValueChange(Sender: TObject);
    procedure edtFormatMaskChange(Sender: TObject);
    procedure chkRequiredClick(Sender: TObject);
    procedure chkReadOnlyClick(Sender: TObject);
    procedure chkVisibleClick(Sender: TObject);
    procedure mmoListValuesChange(Sender: TObject);
  private
    FDefs: TCustomFieldDefs;
    FUpdating: Boolean;
    procedure RefreshTree;
    procedure ShowDetail(AIndex: Integer);
    procedure SaveCurrentDetail;
    function SelectedDefIndex: Integer;
    function FindGroupNode(const AGroupName: string): TTreeNode;
    procedure SelectDefInTree(AIndex: Integer);
  public
    class function Execute(ADefs: TCustomFieldDefs): Boolean;
  end;

var
  frmCustomFieldEditor: TfrmCustomFieldEditor;

implementation

{$R *.dfm}

class function TfrmCustomFieldEditor.Execute(ADefs: TCustomFieldDefs): Boolean;
var
  F: TfrmCustomFieldEditor;
  I: Integer;
  Defs: TArray<TCustomFieldDef>;
begin
  F := TfrmCustomFieldEditor.Create(Application);
  try
    F.FDefs := TCustomFieldDefs.Create;
    Defs := ADefs.GetAllDefs;
    for I := 0 to High(Defs) do
      F.FDefs.Add(Defs[I]);

    F.RefreshTree;
    if F.FDefs.Count > 0 then
    begin
      F.SelectDefInTree(0);
      F.ShowDetail(0);
    end;

    Result := F.ShowModal = mrOk;
    if Result then
    begin
      ADefs.Clear;
      Defs := F.FDefs.GetAllDefs;
      for I := 0 to High(Defs) do
        ADefs.Add(Defs[I]);
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmCustomFieldEditor.FormCreate(Sender: TObject);
begin
  FUpdating := False;
end;

procedure TfrmCustomFieldEditor.FormDestroy(Sender: TObject);
begin
  FDefs.Free;
end;

procedure TfrmCustomFieldEditor.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

{ --- Tree --- }

function TfrmCustomFieldEditor.FindGroupNode(const AGroupName: string): TTreeNode;
var
  N: TTreeNode;
begin
  Result := nil;
  N := tvFields.Items.GetFirstNode;
  while N <> nil do
  begin
    // Nodes de grup tenen Data = nil i estan al nivell 0
    if (N.Level = 0) and (N.Data = nil) and SameText(N.Text, AGroupName) then
      Exit(N);
    N := N.GetNext;
  end;
end;

procedure TfrmCustomFieldEditor.RefreshTree;
var
  I: Integer;
  D: TCustomFieldDef;
  GroupNode, FieldNode: TTreeNode;
  SelIdx: Integer;
begin
  SelIdx := SelectedDefIndex;

  tvFields.Items.BeginUpdate;
  try
    tvFields.Items.Clear;

    for I := 0 to FDefs.Count - 1 do
    begin
      D := FDefs.GetDef(I);

      if D.Grupo <> '' then
      begin
        // Buscar o crear node de grup
        GroupNode := FindGroupNode(D.Grupo);
        if GroupNode = nil then
        begin
          GroupNode := tvFields.Items.Add(nil, D.Grupo);
          GroupNode.Data := nil; // marca de grup
          GroupNode.ImageIndex := -1;
        end;
        FieldNode := tvFields.Items.AddChild(GroupNode,
          D.Caption + ' (' + CustomFieldTypeToStr(D.FieldType) + ')');
      end
      else
      begin
        FieldNode := tvFields.Items.Add(nil,
          D.Caption + ' (' + CustomFieldTypeToStr(D.FieldType) + ')');
      end;

      // Guardem l'index al Data del node
      FieldNode.Data := Pointer(I);
    end;

    tvFields.FullExpand;
  finally
    tvFields.Items.EndUpdate;
  end;

  // Restaurar selecció
  if (SelIdx >= 0) and (SelIdx < FDefs.Count) then
    SelectDefInTree(SelIdx);
end;

procedure TfrmCustomFieldEditor.SelectDefInTree(AIndex: Integer);
var
  N: TTreeNode;
begin
  N := tvFields.Items.GetFirstNode;
  while N <> nil do
  begin
    if (N.Data <> nil) and (Integer(N.Data) = AIndex) then
    begin
      tvFields.Selected := N;
      Exit;
    end;
    N := N.GetNext;
  end;
end;

procedure TfrmCustomFieldEditor.tvFieldsCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Idx: Integer;
  HasGroup: Boolean;
begin
  Sender.Canvas.Font.Style := [];
  Sender.Canvas.Font.Color := clWindowText;

  if Node.Data = nil then
    // Node de grup
    HasGroup := True
  else
  begin
    // Node de camp: mirar si té grup assignat
    Idx := Integer(Node.Data);
    if (Idx >= 0) and (Idx < FDefs.Count) then
      HasGroup := FDefs.GetDef(Idx).Grupo <> ''
    else
      HasGroup := False;
  end;

  if HasGroup then
  begin
    Sender.Canvas.Font.Style := [fsBold];
    Sender.Canvas.Font.Color := $00804000;
  end;

  DefaultDraw := True;
end;

procedure TfrmCustomFieldEditor.tvFieldsChange(Sender: TObject; Node: TTreeNode);
begin
  if FUpdating then Exit;
  ShowDetail(SelectedDefIndex);
end;

function TfrmCustomFieldEditor.SelectedDefIndex: Integer;
var
  N: TTreeNode;
begin
  Result := -1;
  N := tvFields.Selected;
  if N = nil then Exit;
  // Si és un node de grup (Data = nil), no hi ha camp seleccionat
  if N.Data = nil then Exit;
  Result := Integer(N.Data);
end;

{ --- Drag & Drop --- }

procedure TfrmCustomFieldEditor.tvFieldsDragOver(Sender, Source: TObject;
  X, Y: Integer; State: TDragState; var Accept: Boolean);
var
  TargetNode, SourceNode: TTreeNode;
begin
  Accept := False;
  if Source <> tvFields then Exit;

  SourceNode := tvFields.Selected;
  TargetNode := tvFields.GetNodeAt(X, Y);

  if (SourceNode = nil) or (TargetNode = nil) then Exit;
  if SourceNode = TargetNode then Exit;
  // Només permetre drag de camps (no grups)
  if SourceNode.Data = nil then Exit;
  // Permetre soltar sobre camps o grups
  Accept := True;
end;

procedure TfrmCustomFieldEditor.tvFieldsDragDrop(Sender, Source: TObject;
  X, Y: Integer);
var
  SourceNode, TargetNode: TTreeNode;
  SrcIdx, TgtIdx: Integer;
begin
  if Source <> tvFields then Exit;

  SourceNode := tvFields.Selected;
  TargetNode := tvFields.GetNodeAt(X, Y);
  if (SourceNode = nil) or (TargetNode = nil) then Exit;
  if SourceNode.Data = nil then Exit; // no moure grups

  SaveCurrentDetail;
  SrcIdx := Integer(SourceNode.Data);

  if TargetNode.Data <> nil then
  begin
    // Soltat sobre un altre camp -> moure abans d'ell
    TgtIdx := Integer(TargetNode.Data);
  end
  else
  begin
    // Soltat sobre un node de grup -> moure al final del grup
    // Buscar l'últim fill del grup
    if TargetNode.Count > 0 then
      TgtIdx := Integer(TargetNode.Item[TargetNode.Count - 1].Data) + 1
    else
      TgtIdx := SrcIdx; // no moure
  end;

  if SrcIdx = TgtIdx then Exit;

  // Ajustar index si movem cap avall
  if SrcIdx < TgtIdx then
    Dec(TgtIdx);

  if TgtIdx < 0 then TgtIdx := 0;
  if TgtIdx >= FDefs.Count then TgtIdx := FDefs.Count - 1;

  FDefs.Move(SrcIdx, TgtIdx);
  RefreshTree;

  // Seleccionar el camp mogut
  SelectDefInTree(TgtIdx);
  ShowDetail(TgtIdx);
end;

{ --- Detail --- }

procedure TfrmCustomFieldEditor.ShowDetail(AIndex: Integer);
var
  D: TCustomFieldDef;
  I: Integer;
begin
  FUpdating := True;
  try
    pnlDetail.Enabled := (AIndex >= 0) and (AIndex < FDefs.Count);
    if not pnlDetail.Enabled then
    begin
      edtFieldName.Text := '';
      edtCaption.Text := '';
      cmbType.ItemIndex := 0;
      edtDefault.Text := '';
      edtGrupo.Text := '';
      edtTooltip.Text := '';
      edtMinValue.Text := '';
      edtMaxValue.Text := '';
      edtFormatMask.Text := '';
      chkRequired.Checked := False;
      chkReadOnly.Checked := False;
      chkVisible.Checked := True;
      mmoListValues.Lines.Clear;
      Exit;
    end;

    D := FDefs.GetDef(AIndex);
    edtFieldName.Text := D.FieldName;
    edtCaption.Text := D.Caption;

    case D.FieldType of
      cftString:  cmbType.ItemIndex := 0;
      cftInteger: cmbType.ItemIndex := 1;
      cftFloat:   cmbType.ItemIndex := 2;
      cftDate:    cmbType.ItemIndex := 3;
      cftBoolean: cmbType.ItemIndex := 4;
      cftList:    cmbType.ItemIndex := 5;
    end;

    if not VarIsNull(D.DefaultValue) and not VarIsEmpty(D.DefaultValue) then
      edtDefault.Text := VarToStr(D.DefaultValue)
    else
      edtDefault.Text := '';

    edtGrupo.Text := D.Grupo;
    edtTooltip.Text := D.Tooltip;
    if (D.MinValue <> 0) or (D.MaxValue <> 0) then
    begin
      edtMinValue.Text := FloatToStr(D.MinValue);
      edtMaxValue.Text := FloatToStr(D.MaxValue);
    end
    else
    begin
      edtMinValue.Text := '';
      edtMaxValue.Text := '';
    end;
    edtFormatMask.Text := D.FormatMask;

    chkRequired.Checked := D.Required;
    chkReadOnly.Checked := D.ReadOnly;
    chkVisible.Checked := D.Visible;

    mmoListValues.Lines.Clear;
    for I := 0 to High(D.ListValues) do
      mmoListValues.Lines.Add(D.ListValues[I]);

    // Mostrar/ocultar segun tipo
    lblListValues.Visible := D.FieldType = cftList;
    mmoListValues.Visible := D.FieldType = cftList;
    lblMinValue.Visible := D.FieldType in [cftInteger, cftFloat];
    edtMinValue.Visible := D.FieldType in [cftInteger, cftFloat];
    lblMaxValue.Visible := D.FieldType in [cftInteger, cftFloat];
    edtMaxValue.Visible := D.FieldType in [cftInteger, cftFloat];
    lblFormatMask.Visible := D.FieldType in [cftInteger, cftFloat, cftDate];
    edtFormatMask.Visible := D.FieldType in [cftInteger, cftFloat, cftDate];
  finally
    FUpdating := False;
  end;
end;

procedure TfrmCustomFieldEditor.SaveCurrentDetail;
var
  Idx: Integer;
  D: TCustomFieldDef;
  I, N: Integer;
begin
  Idx := SelectedDefIndex;
  if (Idx < 0) or (Idx >= FDefs.Count) then Exit;

  D := FDefs.GetDef(Idx);
  D.FieldName := Trim(edtFieldName.Text);
  D.Caption := Trim(edtCaption.Text);

  case cmbType.ItemIndex of
    0: D.FieldType := cftString;
    1: D.FieldType := cftInteger;
    2: D.FieldType := cftFloat;
    3: D.FieldType := cftDate;
    4: D.FieldType := cftBoolean;
    5: D.FieldType := cftList;
  end;

  if edtDefault.Text = '' then
    D.DefaultValue := Null
  else
  begin
    case D.FieldType of
      cftString, cftList, cftDate: D.DefaultValue := edtDefault.Text;
      cftInteger: D.DefaultValue := StrToIntDef(edtDefault.Text, 0);
      cftFloat:   D.DefaultValue := StrToFloatDef(edtDefault.Text, 0);
      cftBoolean: D.DefaultValue := SameText(edtDefault.Text, 'True') or
                                     SameText(edtDefault.Text, '1') or
                                     SameText(edtDefault.Text, 'S'#237);
    end;
  end;

  D.Grupo := Trim(edtGrupo.Text);
  D.Tooltip := Trim(edtTooltip.Text);
  D.MinValue := StrToFloatDef(edtMinValue.Text, 0);
  D.MaxValue := StrToFloatDef(edtMaxValue.Text, 0);
  D.FormatMask := Trim(edtFormatMask.Text);

  D.Required := chkRequired.Checked;
  D.ReadOnly := chkReadOnly.Checked;
  D.Visible := chkVisible.Checked;

  N := 0;
  SetLength(D.ListValues, mmoListValues.Lines.Count);
  for I := 0 to mmoListValues.Lines.Count - 1 do
    if Trim(mmoListValues.Lines[I]) <> '' then
    begin
      D.ListValues[N] := Trim(mmoListValues.Lines[I]);
      Inc(N);
    end;
  SetLength(D.ListValues, N);

  FDefs.Update(Idx, D);
end;

{ --- Add / Delete --- }

procedure TfrmCustomFieldEditor.btnAddClick(Sender: TObject);
var
  D: TCustomFieldDef;
begin
  FillChar(D, SizeOf(D), 0);
  D.FieldName := 'campo' + IntToStr(FDefs.Count + 1);
  D.Caption := 'Campo ' + IntToStr(FDefs.Count + 1);
  D.FieldType := cftString;
  D.DefaultValue := '';
  D.Required := False;
  D.Order := FDefs.Count;
  D.Visible := True;

  FDefs.Add(D);
  RefreshTree;
  SelectDefInTree(FDefs.Count - 1);
  ShowDetail(FDefs.Count - 1);
end;

procedure TfrmCustomFieldEditor.btnDeleteClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := SelectedDefIndex;
  if Idx < 0 then Exit;

  if MessageDlg('Eliminar el campo "' + FDefs.GetDef(Idx).Caption + '"?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  FDefs.Delete(Idx);
  RefreshTree;
  if FDefs.Count > 0 then
  begin
    if Idx >= FDefs.Count then
      Idx := FDefs.Count - 1;
    SelectDefInTree(Idx);
    ShowDetail(Idx);
  end
  else
    ShowDetail(-1);
end;

{ --- Change events --- }

procedure TfrmCustomFieldEditor.edtFieldNameChange(Sender: TObject);
begin
  if not FUpdating then SaveCurrentDetail;
end;

procedure TfrmCustomFieldEditor.edtCaptionChange(Sender: TObject);
var
  N: TTreeNode;
  Idx: Integer;
begin
  if FUpdating then Exit;
  SaveCurrentDetail;
  // Actualitzar text al tree
  Idx := SelectedDefIndex;
  if Idx < 0 then Exit;
  N := tvFields.Selected;
  if (N <> nil) and (N.Data <> nil) then
    N.Text := edtCaption.Text + ' (' +
      CustomFieldTypeToStr(FDefs.GetDef(Idx).FieldType) + ')';
end;

procedure TfrmCustomFieldEditor.cmbTypeChange(Sender: TObject);
var
  IsNumeric, IsNumOrDate: Boolean;
  N: TTreeNode;
  Idx: Integer;
begin
  if FUpdating then Exit;
  SaveCurrentDetail;

  IsNumeric := cmbType.ItemIndex in [1, 2];
  IsNumOrDate := cmbType.ItemIndex in [1, 2, 3];

  lblListValues.Visible := cmbType.ItemIndex = 5;
  mmoListValues.Visible := cmbType.ItemIndex = 5;
  lblMinValue.Visible := IsNumeric;
  edtMinValue.Visible := IsNumeric;
  lblMaxValue.Visible := IsNumeric;
  edtMaxValue.Visible := IsNumeric;
  lblFormatMask.Visible := IsNumOrDate;
  edtFormatMask.Visible := IsNumOrDate;

  // Actualitzar text al tree
  Idx := SelectedDefIndex;
  if Idx < 0 then Exit;
  N := tvFields.Selected;
  if (N <> nil) and (N.Data <> nil) then
    N.Text := edtCaption.Text + ' (' + cmbType.Items[cmbType.ItemIndex] + ')';
end;

procedure TfrmCustomFieldEditor.edtDefaultChange(Sender: TObject);
begin
  if not FUpdating then SaveCurrentDetail;
end;

procedure TfrmCustomFieldEditor.edtGrupoChange(Sender: TObject);
begin
  if FUpdating then Exit;
  SaveCurrentDetail;
  // Reconstruir arbre per reflectir el canvi de grup
  RefreshTree;
end;

procedure TfrmCustomFieldEditor.edtTooltipChange(Sender: TObject);
begin
  if not FUpdating then SaveCurrentDetail;
end;

procedure TfrmCustomFieldEditor.edtMinValueChange(Sender: TObject);
begin
  if not FUpdating then SaveCurrentDetail;
end;

procedure TfrmCustomFieldEditor.edtMaxValueChange(Sender: TObject);
begin
  if not FUpdating then SaveCurrentDetail;
end;

procedure TfrmCustomFieldEditor.edtFormatMaskChange(Sender: TObject);
begin
  if not FUpdating then SaveCurrentDetail;
end;

procedure TfrmCustomFieldEditor.chkRequiredClick(Sender: TObject);
begin
  if not FUpdating then SaveCurrentDetail;
end;

procedure TfrmCustomFieldEditor.chkReadOnlyClick(Sender: TObject);
begin
  if not FUpdating then SaveCurrentDetail;
end;

procedure TfrmCustomFieldEditor.chkVisibleClick(Sender: TObject);
begin
  if not FUpdating then SaveCurrentDetail;
end;

procedure TfrmCustomFieldEditor.mmoListValuesChange(Sender: TObject);
begin
  if not FUpdating then SaveCurrentDetail;
end;

{ --- OK / Cancel --- }

procedure TfrmCustomFieldEditor.btnOKClick(Sender: TObject);
var
  I: Integer;
  D: TCustomFieldDef;
begin
  SaveCurrentDetail;

  for I := 0 to FDefs.Count - 1 do
  begin
    D := FDefs.GetDef(I);
    if Trim(D.FieldName) = '' then
    begin
      MessageDlg('El campo #' + IntToStr(I + 1) + ' no tiene nombre.',
        mtError, [mbOK], 0);
      SelectDefInTree(I);
      ShowDetail(I);
      edtFieldName.SetFocus;
      Exit;
    end;
  end;

  ModalResult := mrOk;
end;

procedure TfrmCustomFieldEditor.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
