unit uPesosScoring;

{
  TfrmPesosScoring - Editor de los 7 pesos del scoring del motor de
  planificacion automatica. Muestra la formula visible para que el usuario
  entienda que cambia cada peso.

  Trabaja sobre una variable TPesosPlanificacion: Execute la edita in-place
  y devuelve True si el usuario ha aceptado.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uPlanProdTypes;

type
  TfrmPesosScoring = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlFormula: TPanel;
    lblFormula: TLabel;
    pnlBody: TPanel;
    lbl1: TLabel;
    edPrioridadOrden: TEdit;
    lbl2: TLabel;
    edCompromiso: TEdit;
    lbl3: TLabel;
    edNivelCompetencia: TEdit;
    lbl4: TLabel;
    edCargaOperario: TEdit;
    lbl5: TLabel;
    edContinuidad: TEdit;
    lbl6: TLabel;
    edEspera: TEdit;
    lbl7: TLabel;
    edCosteManoObra: TEdit;
    pnlBottom: TPanel;
    btnDefault: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnDefaultClick(Sender: TObject);
  private
    FPesos: TPesosPlanificacion;
    procedure LoadFromPesos;
    procedure SaveToPesos;
  public
    class function Execute(var APesos: TPesosPlanificacion): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmPesosScoring.Execute(var APesos: TPesosPlanificacion): Boolean;
var
  F: TfrmPesosScoring;
begin
  F := TfrmPesosScoring.Create(nil);
  try
    F.FPesos := APesos;
    F.LoadFromPesos;
    Result := F.ShowModal = mrOk;
    if Result then
    begin
      F.SaveToPesos;
      APesos := F.FPesos;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmPesosScoring.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
end;

procedure TfrmPesosScoring.LoadFromPesos;
begin
  edPrioridadOrden.Text := FormatFloat('0.####', FPesos.PesoPrioridadOrden);
  edCompromiso.Text := FormatFloat('0.####', FPesos.PesoCompromiso);
  edNivelCompetencia.Text := FormatFloat('0.####', FPesos.PesoNivelCompetencia);
  edCargaOperario.Text := FormatFloat('0.####', FPesos.PesoCargaOperario);
  edContinuidad.Text := FormatFloat('0.####', FPesos.PesoContinuidad);
  edEspera.Text := FormatFloat('0.####', FPesos.PesoEspera);
  edCosteManoObra.Text := FormatFloat('0.####', FPesos.PesoCosteManoObra);
end;

procedure TfrmPesosScoring.SaveToPesos;

  function ParseDouble(const S: string; ADefault: Double): Double;
  var
    T: string;
  begin
    T := StringReplace(Trim(S), ',', '.', [rfReplaceAll]);
    Result := StrToFloatDef(T, ADefault, TFormatSettings.Invariant);
  end;

begin
  FPesos.PesoPrioridadOrden := ParseDouble(edPrioridadOrden.Text, 10);
  FPesos.PesoCompromiso := ParseDouble(edCompromiso.Text, 8);
  FPesos.PesoNivelCompetencia := ParseDouble(edNivelCompetencia.Text, 3);
  FPesos.PesoCargaOperario := ParseDouble(edCargaOperario.Text, 0.5);
  FPesos.PesoContinuidad := ParseDouble(edContinuidad.Text, 4);
  FPesos.PesoEspera := ParseDouble(edEspera.Text, 0.05);
  FPesos.PesoCosteManoObra := ParseDouble(edCosteManoObra.Text, 2);
end;

procedure TfrmPesosScoring.btnDefaultClick(Sender: TObject);
begin
  FPesos := TPesosPlanificacion.Default;
  LoadFromPesos;
end;

procedure TfrmPesosScoring.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

end.
