unit uCentresCustomColEdit;

// ============================================================================
// Dialogo de alta/edicion de una definicion de columna custom de Centros.
// Escribe en FS_PL_Cfg_GridColumns con GridId='CENTROS' e IsCustomField=1.
//
// A diferencia del de Backlog, aqui no hay SourceEntity ni AppliesToNivel:
// los campos custom de Centro se ligan SIEMPRE al propio Centro.
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs,
  Vcl.Samples.Spin;

type
  TCentresCustomColData = record
    ColumnKey: string;
    Caption: string;
    DataType: Char;          // 'S','N','D','B'
    OrderDefault: Integer;
    WidthDefault: Integer;
  end;

  TfrmCentresCustomColEdit = class(TForm)
    lblColumnKey: TLabel;
    lblCaption: TLabel;
    lblDataType: TLabel;
    lblOrderDefault: TLabel;
    lblWidthDefault: TLabel;
    lblHelp: TLabel;
    edtColumnKey: TEdit;
    edtCaption: TEdit;
    cmbDataType: TComboBox;
    edtOrderDefault: TSpinEdit;
    edtWidthDefault: TSpinEdit;
    btnAceptar: TButton;
    btnCancelar: TButton;
    procedure btnAceptarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FIsNew: Boolean;
    FData: TCentresCustomColData;
    function ValidColumnKey(const S: string): Boolean;
  public
    class function Execute(var AData: TCentresCustomColData; AIsNew: Boolean): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.Character;

class function TfrmCentresCustomColEdit.Execute(
  var AData: TCentresCustomColData; AIsNew: Boolean): Boolean;
var
  F: TfrmCentresCustomColEdit;
begin
  F := TfrmCentresCustomColEdit.Create(Application);
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

procedure TfrmCentresCustomColEdit.FormShow(Sender: TObject);
begin
  if FIsNew then
    Caption := 'Nueva columna personalizada (Centros)'
  else
    Caption := 'Editar columna personalizada (Centros)';

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

  edtOrderDefault.Value := FData.OrderDefault;
  if FData.WidthDefault < edtWidthDefault.MinValue then
    edtWidthDefault.Value := 120
  else
    edtWidthDefault.Value := FData.WidthDefault;

  if FIsNew then edtColumnKey.SetFocus else edtCaption.SetFocus;
end;

function TfrmCentresCustomColEdit.ValidColumnKey(const S: string): Boolean;
var
  I: Integer;
  Ch: Char;
begin
  Result := False;
  if (Length(S) < 2) or (Length(S) > 64) then Exit;
  if not TCharacter.IsLetter(S[1]) then Exit;
  for I := 1 to Length(S) do
  begin
    Ch := S[I];
    if not (TCharacter.IsLetterOrDigit(Ch) or (Ch = '_')) then Exit;
  end;
  Result := True;
end;

procedure TfrmCentresCustomColEdit.btnAceptarClick(Sender: TObject);
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

  FData.ColumnKey := Key;
  FData.Caption   := Cap;
  case cmbDataType.ItemIndex of
    0: FData.DataType := 'S';
    1: FData.DataType := 'N';
    2: FData.DataType := 'D';
    3: FData.DataType := 'B';
  end;
  FData.OrderDefault := edtOrderDefault.Value;
  FData.WidthDefault := edtWidthDefault.Value;
end;

end.
