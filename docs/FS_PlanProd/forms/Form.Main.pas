unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Menus, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls;

type
  TfrmMain = class(TForm)
    MainMenu1: TMainMenu;
    miArchivo: TMenuItem;
    miSalir: TMenuItem;
    miMaestros: TMenuItem;
    miOperarios: TMenuItem;
    miOrdenes: TMenuItem;
    miPlanificacion: TMenuItem;
    miPesos: TMenuItem;
    miEjecutarBatch: TMenuItem;
    miVerAsignaciones: TMenuItem;
    StatusBar1: TStatusBar;
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlBotones: TPanel;
    btnOperarios: TButton;
    btnOrdenes: TButton;
    btnPesos: TButton;
    btnEjecutar: TButton;
    btnAsignaciones: TButton;
    lblFecha: TLabel;
    edtFecha: TDateTimePicker;
    edtHora: TDateTimePicker;
    btnAplicarFecha: TButton;
    procedure FormCreate(Sender: TObject);
    procedure miSalirClick(Sender: TObject);
    procedure btnOperariosClick(Sender: TObject);
    procedure btnOrdenesClick(Sender: TObject);
    procedure btnPesosClick(Sender: TObject);
    procedure btnEjecutarClick(Sender: TObject);
    procedure btnAsignacionesClick(Sender: TObject);
    procedure btnAplicarFechaClick(Sender: TObject);
  private
    procedure ActualizarStatusBar;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  System.DateUtils,
  FS.PlanProd.SessionData,
  Form.Operarios,
  Form.Ordenes,
  Form.Pesos,
  Form.Asignaciones;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  edtFecha.Date := DateOf(Session.FechaSimulada);
  edtHora.Time := TimeOf(Session.FechaSimulada);
  ActualizarStatusBar;
end;

procedure TfrmMain.ActualizarStatusBar;
begin
  StatusBar1.Panels[0].Text := Format('Operarios: %d',
    [Session.Operarios.Count]);
  StatusBar1.Panels[1].Text := Format('Órdenes: %d', [Session.Ordenes.Count]);
  StatusBar1.Panels[2].Text := Format('Asignaciones: %d',
    [Session.UltimasAsignaciones.Count]);
  StatusBar1.Panels[3].Text := 'Fecha sim: ' +
    FormatDateTime('dd/mm/yyyy hh:nn', Session.FechaSimulada);
end;

procedure TfrmMain.btnAplicarFechaClick(Sender: TObject);
begin
  Session.FechaSimulada := DateOf(edtFecha.Date) + TimeOf(edtHora.Time);
  Session.RecrearMotor;
  ActualizarStatusBar;
  ShowMessage('Fecha simulada actualizada a: ' + FormatDateTime('dd/mm/yyyy hh:nn',
    Session.FechaSimulada));
end;

procedure TfrmMain.miSalirClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnOperariosClick(Sender: TObject);
var
  LForm: TfrmOperarios;
begin
  LForm := TfrmOperarios.Create(Self);
  try
    LForm.ShowModal;
    ActualizarStatusBar;
  finally
    LForm.Free;
  end;
end;

procedure TfrmMain.btnOrdenesClick(Sender: TObject);
var
  LForm: TfrmOrdenes;
begin
  LForm := TfrmOrdenes.Create(Self);
  try
    LForm.ShowModal;
    ActualizarStatusBar;
  finally
    LForm.Free;
  end;
end;

procedure TfrmMain.btnPesosClick(Sender: TObject);
var
  LForm: TfrmPesos;
begin
  LForm := TfrmPesos.Create(Self);
  try
    LForm.ShowModal;
    ActualizarStatusBar;
  finally
    LForm.Free;
  end;
end;

procedure TfrmMain.btnEjecutarClick(Sender: TObject);
var
  LNum: Integer;
begin
  LNum := Session.EjecutarPlanificacionBatch;
  ActualizarStatusBar;
  ShowMessage(Format('Planificación ejecutada. %d asignaciones realizadas.' +
    sLineBreak + 'Pulse "Asignaciones" para ver el detalle.', [LNum]));
end;

procedure TfrmMain.btnAsignacionesClick(Sender: TObject);
var
  LForm: TfrmAsignaciones;
begin
  LForm := TfrmAsignaciones.Create(Self);
  try
    LForm.ShowModal;
  finally
    LForm.Free;
  end;
end;

end.
