unit uBacklogCustomColEdit;

// ============================================================================
// Dialogo de alta/edicion de una definicion de columna custom del Backlog.
// Escribe en FS_PL_Cfg_GridColumns con GridId='BACKLOG' e IsCustomField=1.
// El ColumnKey es identificador estable: solo se puede definir al crear.
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs,
  Vcl.Samples.Spin;

type
  TBacklogCustomColData = record
    ColumnKey: string;
    Caption: string;
    DataType: Char;          // 'S','N','D','B'
    SourceEntity: string;    // 'OF','PEDIDO','PROYECTO'
    AppliesToNivel: Integer; // 1=OF/PED/PRJ, 2=OT/LINEA/TAREA, 3=OP, 0=auto(leaf)
    OrderDefault: Integer;
    WidthDefault: Integer;
  end;

  TfrmBacklogCustomColEdit = class(TForm)
    lblColumnKey: TLabel;
    lblCaption: TLabel;
    lblDataType: TLabel;
    lblSourceEntity: TLabel;
    lblNivel: TLabel;
    lblOrderDefault: TLabel;
    lblWidthDefault: TLabel;
    lblHelp: TLabel;
    edtColumnKey: TEdit;
    edtCaption: TEdit;
    cmbDataType: TComboBox;
    cmbSourceEntity: TComboBox;
    cmbNivel: TComboBox;
    edtOrderDefault: TSpinEdit;
    edtWidthDefault: TSpinEdit;
    btnAceptar: TButton;
    btnCancelar: TButton;
    procedure btnAceptarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FIsNew: Boolean;
    FData: TBacklogCustomColData;
    function ValidColumnKey(const S: string): Boolean;
  public
    class function Execute(var AData: TBacklogCustomColData; AIsNew: Boolean): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.Character;

class function TfrmBacklogCustomColEdit.Execute(
  var AData: TBacklogCustomColData; AIsNew: Boolean): Boolean;
var
  F: TfrmBacklogCustomColEdit;
begin
  F := TfrmBacklogCustomColEdit.Create(Application);
  try
    F.FIsNew := AIsNew;
    F.FData := AData;
    Result := F.ShowModal = mrOk;
    if Result then
      AData := F.FData;
  finally
    F.Free;
  end;
end;

procedure TfrmBacklogCustomColEdit.FormShow(Sender: TObject);
begin
  if FIsNew then
    Caption := 'Nueva columna personalizada'
  else
    Caption := 'Editar columna personalizada';

  edtColumnKey.Text := FData.ColumnKey;
  edtColumnKey.Enabled := FIsNew;
  edtCaption.Text := FData.Caption;

  case UpCase(FData.DataType) of
    'S': cmbDataType.ItemIndex := 0;
    'N': cmbDataType.ItemIndex := 1;
    'D': cmbDataType.ItemIndex := 2;
    'B': cmbDataType.ItemIndex := 3;
  else
    cmbDataType.ItemIndex := 0;
  end;

  if SameText(FData.SourceEntity, 'OF') then       cmbSourceEntity.ItemIndex := 0
  else if SameText(FData.SourceEntity, 'PEDIDO')   then cmbSourceEntity.ItemIndex := 1
  else if SameText(FData.SourceEntity, 'PROYECTO') then cmbSourceEntity.ItemIndex := 2
  else cmbSourceEntity.ItemIndex := 0;

  // Mapeo Nivel: 1->idx0 (cabecera), 2->idx1 (intermedio), 3->idx2 (OP).
  case FData.AppliesToNivel of
    1: cmbNivel.ItemIndex := 0;
    2: cmbNivel.ItemIndex := 1;
    3: cmbNivel.ItemIndex := 2;
  else
    cmbNivel.ItemIndex := 0;
  end;

  edtOrderDefault.Value := FData.OrderDefault;
  if FData.WidthDefault < edtWidthDefault.MinValue then
    edtWidthDefault.Value := 120
  else
    edtWidthDefault.Value := FData.WidthDefault;

  if FIsNew then
    edtColumnKey.SetFocus
  else
    edtCaption.SetFocus;
end;

function TfrmBacklogCustomColEdit.ValidColumnKey(const S: string): Boolean;
var
  I: Integer;
  Ch: Char;
begin
  Result := False;
  if (Length(S) < 2) or (Length(S) > 64) then Exit;
  // Empieza por letra
  if not TCharacter.IsLetter(S[1]) then Exit;
  for I := 1 to Length(S) do
  begin
    Ch := S[I];
    if not (TCharacter.IsLetterOrDigit(Ch) or (Ch = '_')) then Exit;
  end;
  Result := True;
end;

procedure TfrmBacklogCustomColEdit.btnAceptarClick(Sender: TObject);
var
  Key, Cap: string;
begin
  Key := UpperCase(Trim(edtColumnKey.Text));
  Cap := Trim(edtCaption.Text);

  if not ValidColumnKey(Key) then
  begin
    ShowMessage('ColumnKey invalido. Solo letras/numeros/guion bajo, debe empezar por letra (2-64 caracteres).');
    edtColumnKey.SetFocus;
    ModalResult := mrNone;
    Exit;
  end;
  if Cap = '' then
  begin
    ShowMessage('Indica una etiqueta para la columna.');
    edtCaption.SetFocus;
    ModalResult := mrNone;
    Exit;
  end;
  if cmbDataType.ItemIndex < 0 then
  begin
    ShowMessage('Selecciona un tipo de dato.');
    ModalResult := mrNone;
    Exit;
  end;
  if cmbSourceEntity.ItemIndex < 0 then
  begin
    ShowMessage('Selecciona una entidad origen.');
    ModalResult := mrNone;
    Exit;
  end;
  if cmbNivel.ItemIndex < 0 then
  begin
    ShowMessage('Selecciona un nivel.');
    ModalResult := mrNone;
    Exit;
  end;

  FData.ColumnKey := Key;
  FData.Caption   := Cap;
  case cmbDataType.ItemIndex of
    0: FData.DataType := 'S';
    1: FData.DataType := 'N';
    2: FData.DataType := 'D';
    3: FData.DataType := 'B';
  end;
  case cmbSourceEntity.ItemIndex of
    0: FData.SourceEntity := 'OF';
    1: FData.SourceEntity := 'PEDIDO';
    2: FData.SourceEntity := 'PROYECTO';
  end;
  case cmbNivel.ItemIndex of
    0: FData.AppliesToNivel := 1;
    1: FData.AppliesToNivel := 2;
    2: FData.AppliesToNivel := 3;
  end;
  FData.OrderDefault := edtOrderDefault.Value;
  FData.WidthDefault := edtWidthDefault.Value;
end;

end.
