unit Form.Pesos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Samples.Spin;

type
  TfrmPesos = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblDescripcion: TLabel;
    pnlBottom: TPanel;
    btnAceptar: TButton;
    btnCancelar: TButton;
    btnDefault: TButton;
    pnlClient: TPanel;
    lblPesoPrioridad: TLabel;
    edtPesoPrioridad: TEdit;
    lblPrioridadHelp: TLabel;
    lblPesoCompromiso: TLabel;
    edtPesoCompromiso: TEdit;
    lblCompromisoHelp: TLabel;
    lblPesoNivel: TLabel;
    edtPesoNivel: TEdit;
    lblNivelHelp: TLabel;
    lblPesoCarga: TLabel;
    edtPesoCarga: TEdit;
    lblCargaHelp: TLabel;
    lblPesoContinuidad: TLabel;
    edtPesoContinuidad: TEdit;
    lblContinuidadHelp: TLabel;
    lblPesoEspera: TLabel;
    edtPesoEspera: TEdit;
    lblEsperaHelp: TLabel;
    lblPesoCoste: TLabel;
    edtPesoCoste: TEdit;
    lblCosteHelp: TLabel;
    lblFormula: TLabel;
    memoFormula: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnDefaultClick(Sender: TObject);
  private
    procedure CargarPesos;
    function ParsearDouble(AEdit: TEdit; ADefault: Double): Double;
  end;

implementation

{$R *.dfm}

uses
  FS.PlanProd.Types,
  FS.PlanProd.SessionData;

procedure TfrmPesos.FormCreate(Sender: TObject);
begin
  CargarPesos;

  memoFormula.Lines.Clear;
  memoFormula.Lines.Add('score = w1·prioridad_orden');
  memoFormula.Lines.Add('      + w2·factor_compromiso  (10 si vencido, 8 si <1h, 5 si <4h, 3 si <24h, 1 resto)');
  memoFormula.Lines.Add('      + w3 / (1 + sobrenivel)  (penaliza usar senior para tarea trivial)');
  memoFormula.Lines.Add('      − w4·carga_jornada_h     (penaliza operarios cargados)');
  memoFormula.Lines.Add('      + w5·continuidad         (1.0 si ya estaba en esta orden)');
  memoFormula.Lines.Add('      + w6·minutos_espera      (anti-starvation)');
  memoFormula.Lines.Add('      − w7·(coste_eur_h / 10)  (penaliza operario caro)');
end;

procedure TfrmPesos.CargarPesos;
var
  LPesos: TPesosPlanificacion;
begin
  LPesos := Session.Pesos;
  edtPesoPrioridad.Text := FormatFloat('0.00', LPesos.PesoPrioridadOrden);
  edtPesoCompromiso.Text := FormatFloat('0.00', LPesos.PesoCompromiso);
  edtPesoNivel.Text := FormatFloat('0.00', LPesos.PesoNivelCompetencia);
  edtPesoCarga.Text := FormatFloat('0.00', LPesos.PesoCargaOperario);
  edtPesoContinuidad.Text := FormatFloat('0.00', LPesos.PesoContinuidad);
  edtPesoEspera.Text := FormatFloat('0.00', LPesos.PesoEspera);
  edtPesoCoste.Text := FormatFloat('0.00', LPesos.PesoCosteManoObra);
end;

function TfrmPesos.ParsearDouble(AEdit: TEdit; ADefault: Double): Double;
var
  LFmt: TFormatSettings;
begin
  LFmt := FormatSettings;
  LFmt.DecimalSeparator := '.';
  // Permitir tanto coma como punto
  if not TryStrToFloat(StringReplace(AEdit.Text, ',', '.', [rfReplaceAll]),
    Result, LFmt) then
    Result := ADefault;
end;

procedure TfrmPesos.btnAceptarClick(Sender: TObject);
var
  LPesos: TPesosPlanificacion;
begin
  LPesos.PesoPrioridadOrden := ParsearDouble(edtPesoPrioridad, 10.0);
  LPesos.PesoCompromiso := ParsearDouble(edtPesoCompromiso, 8.0);
  LPesos.PesoNivelCompetencia := ParsearDouble(edtPesoNivel, 3.0);
  LPesos.PesoCargaOperario := ParsearDouble(edtPesoCarga, 0.5);
  LPesos.PesoContinuidad := ParsearDouble(edtPesoContinuidad, 4.0);
  LPesos.PesoEspera := ParsearDouble(edtPesoEspera, 0.05);
  LPesos.PesoCosteManoObra := ParsearDouble(edtPesoCoste, 2.0);

  Session.Pesos := LPesos;
  Session.RecrearMotor;
  ModalResult := mrOk;
end;

procedure TfrmPesos.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmPesos.btnDefaultClick(Sender: TObject);
begin
  Session.Pesos := TPesosPlanificacion.Default;
  CargarPesos;
end;

end.
