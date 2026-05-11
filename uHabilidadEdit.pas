unit uHabilidadEdit;

{
  TfrmHabilidadEdit - Mini dialogo modal para crear/editar una habilidad.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uPlanProdTypes;

type
  TfrmHabilidadEdit = class(TForm)
    pnlBody: TPanel;
    lblCodigo: TLabel;
    edCodigo: TEdit;
    lblDescripcion: TLabel;
    edDescripcion: TEdit;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure btnOKClick(Sender: TObject);
  public
    class function Execute(var H: THabilidad; ANuevo: Boolean): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmHabilidadEdit.Execute(var H: THabilidad;
  ANuevo: Boolean): Boolean;
var
  F: TfrmHabilidadEdit;
begin
  F := TfrmHabilidadEdit.Create(nil);
  try
    F.edCodigo.Text := H.Codigo;
    F.edDescripcion.Text := H.Descripcion;
    F.edCodigo.Enabled := ANuevo;
    if ANuevo then F.Caption := 'Nueva habilidad'
    else F.Caption := 'Editar habilidad';
    Result := F.ShowModal = mrOk;
    if Result then
    begin
      H.Codigo := UpperCase(Trim(F.edCodigo.Text));
      H.Descripcion := Trim(F.edDescripcion.Text);
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmHabilidadEdit.btnOKClick(Sender: TObject);
begin
  if Trim(edCodigo.Text) = '' then
  begin
    MessageDlg('El c'#243'digo es obligatorio.', mtWarning, [mbOK], 0);
    ModalResult := mrNone;
    Exit;
  end;
  ModalResult := mrOk;
end;

end.
