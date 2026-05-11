unit uHabilidadPicker;

{
  TfrmHabilidadPicker - mini di'alogo modal para elegir una habilidad del
  cat'alogo + un nivel m'inimo. Reutilizable desde:
    - uGestionOperacionHabilidades (a'nadir habilidad requerida a operacion)
    - tab Polivalencia operario (a'nadir skill al operario)
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uOperariosTypes, uPlanProdTypes, uHabilidadRepo;

type
  TfrmHabilidadPicker = class(TForm)
    pnlBody: TPanel;
    lblHab: TLabel;
    cbHabilidad: TComboBox;
    lblNivel: TLabel;
    cbNivel: TComboBox;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
  public
    class function Execute(ARepo: THabilidadRepo;
      ATitulo: string;
      out ACodHabilidad: string; out ANivel: TNivelSkill;
      const AExcluir: TArray<string> = nil): Boolean;
  end;

implementation

{$R *.dfm}

procedure TfrmHabilidadPicker.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
  cbNivel.Items.Clear;
  cbNivel.Items.Add('0 - Aprendiz');
  cbNivel.Items.Add('1 - Junior');
  cbNivel.Items.Add('2 - Senior');
  cbNivel.Items.Add('3 - Experto');
  cbNivel.ItemIndex := 0;
end;

class function TfrmHabilidadPicker.Execute(ARepo: THabilidadRepo;
  ATitulo: string;
  out ACodHabilidad: string; out ANivel: TNivelSkill;
  const AExcluir: TArray<string>): Boolean;
var
  F: TfrmHabilidadPicker;
  Habs: TArray<THabilidad>;
  I, J: Integer;
  Excluir: Boolean;
  Caption: string;
begin
  ACodHabilidad := '';
  ANivel := nsAprendiz;
  F := TfrmHabilidadPicker.Create(nil);
  try
    if ATitulo <> '' then F.Caption := ATitulo;
    Habs := ARepo.GetHabilidades;
    F.cbHabilidad.Items.BeginUpdate;
    try
      F.cbHabilidad.Items.Clear;
      for I := 0 to High(Habs) do
      begin
        Excluir := False;
        for J := 0 to High(AExcluir) do
          if SameText(Habs[I].Codigo, AExcluir[J]) then
          begin
            Excluir := True;
            Break;
          end;
        if Excluir then Continue;
        Caption := Habs[I].Codigo;
        if Habs[I].Descripcion <> '' then
          Caption := Caption + ' - ' + Habs[I].Descripcion;
        F.cbHabilidad.Items.AddObject(Caption, TObject(Pointer(I)));
      end;
    finally
      F.cbHabilidad.Items.EndUpdate;
    end;
    if F.cbHabilidad.Items.Count = 0 then
    begin
      MessageDlg('No hay habilidades disponibles para a'#241'adir.',
        mtInformation, [mbOK], 0);
      Exit(False);
    end;
    F.cbHabilidad.ItemIndex := 0;
    Result := F.ShowModal = mrOk;
    if Result and (F.cbHabilidad.ItemIndex >= 0) then
    begin
      I := Integer(F.cbHabilidad.Items.Objects[F.cbHabilidad.ItemIndex]);
      ACodHabilidad := Habs[I].Codigo;
      if F.cbNivel.ItemIndex >= 0 then
        ANivel := TNivelSkill(F.cbNivel.ItemIndex);
    end;
  finally
    F.Free;
  end;
end;

end.
