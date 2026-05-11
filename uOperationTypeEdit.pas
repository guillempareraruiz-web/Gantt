unit uOperationTypeEdit;

{
  TfrmOperationTypeEdit - mini dialog modal para crear/editar un tipo de
  operacion con parametros de paralelismo:
    - Operacion (codigo, no editable al modificar)
    - MaxOperariosParalelos (1 = no paralelizable)
    - FactorParalelismo (0..1; 1 = sin perdida; 0.85 = 15% perdida por op.
      adicional)
    - Descripcion
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uOperariosTypes;

type
  TfrmOperationTypeEdit = class(TForm)
    pnlBody: TPanel;
    lblOperacion: TLabel;
    edOperacion: TEdit;
    lblMax: TLabel;
    edMax: TEdit;
    lblFactor: TLabel;
    edFactor: TEdit;
    lblDesc: TLabel;
    edDesc: TEdit;
    lblHelp: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure btnOKClick(Sender: TObject);
  public
    class function Execute(var Op: TTipoOperacion; ANuevo: Boolean): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmOperationTypeEdit.Execute(var Op: TTipoOperacion;
  ANuevo: Boolean): Boolean;
var
  F: TfrmOperationTypeEdit;
begin
  F := TfrmOperationTypeEdit.Create(nil);
  try
    F.edOperacion.Text := Op.Operacion;
    F.edOperacion.Enabled := ANuevo;
    F.edMax.Text := IntToStr(Op.MaxOperariosParalelos);
    F.edFactor.Text := FormatFloat('0.0000', Op.FactorParalelismo);
    F.edDesc.Text := Op.Descripcion;
    if ANuevo then F.Caption := 'Nueva operaci'#243'n'
    else F.Caption := 'Editar operaci'#243'n';
    Result := F.ShowModal = mrOk;
    if Result then
    begin
      Op.Operacion := UpperCase(Trim(F.edOperacion.Text));
      Op.MaxOperariosParalelos := StrToIntDef(F.edMax.Text, 1);
      if Op.MaxOperariosParalelos < 1 then Op.MaxOperariosParalelos := 1;
      var FactorStr := StringReplace(Trim(F.edFactor.Text), ',', '.',
        [rfReplaceAll]);
      Op.FactorParalelismo := StrToFloatDef(FactorStr, 1.0,
        TFormatSettings.Invariant);
      if Op.FactorParalelismo <= 0 then Op.FactorParalelismo := 1.0
      else if Op.FactorParalelismo > 1 then Op.FactorParalelismo := 1.0;
      Op.Descripcion := Trim(F.edDesc.Text);
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmOperationTypeEdit.btnOKClick(Sender: TObject);
begin
  if Trim(edOperacion.Text) = '' then
  begin
    MessageDlg('El c'#243'digo de operaci'#243'n es obligatorio.',
      mtWarning, [mbOK], 0);
    ModalResult := mrNone;
    Exit;
  end;
  ModalResult := mrOk;
end;

end.
