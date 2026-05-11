unit uMaquinasCustomColEdit;

// ============================================================================
// Dialogo de alta/edicion de una definicion de columna custom de Maquinas.
// Escribe en FS_PL_Cfg_GridColumns con GridId='MAQUINAS' e IsCustomField=1.
//
// Los campos custom de Maquina se ligan SIEMPRE a la propia Maquina:
// no hay SourceEntity ni AppliesToNivel.
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs,
  Vcl.Samples.Spin;

type
  TMaquinasCustomColData = record
    ColumnKey: string;
    Caption: string;
    DataType: Char;          // 'S','N','D','B'
    OrderDefault: Integer;
    WidthDefault: Integer;
  end;

  TfrmMaquinasCustomColEdit = class(TForm)
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
    FData: TMaquinasCustomColData;
    function ValidColumnKey(const S: string): Boolean;
  public
    class function Execute(var AData: TMaquinasCustomColData; AIsNew: Boolean): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.Character;

class function TfrmMaquinasCustomColEdit.Execute(
  var AData: TMaquinasCustomColData; AIsNew: Boolean): Boolean;
var
  F: TfrmMaquinasCustomColEdit;
begin
  F := TfrmMaquinasCustomColEdit.Create(Application);
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

procedure TfrmMaquinasCustomColEdit.FormShow(Sender: TObject);
begin
  if FIsNew then
    Caption := 'Nueva columna personalizada (M'#225'quinas)'
  else
    Caption := 'Editar columna personalizada (M'#225'quinas)';

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

function TfrmMaquinasCustomColEdit.ValidColumnKey(const S: string): Boolean;
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

procedure TfrmMaquinasCustomColEdit.btnAceptarClick(Sender: TObject);
var
  Key, Cap: string;
begin
  Key := UpperCase(Trim(edtColumnKey.Text));
  Cap := Trim(edtCaption.Text);

  if not ValidColumnKey(Key) then
  begin
    ShowMessage('ColumnKey inv'#225'lido. S'#243'lo letras/n'#250'meros/gui'#243'n bajo, debe empezar por letra (2-64 caracteres).');
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
