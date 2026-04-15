unit uDashboard;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmDashboard = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblFechaHora: TLabel;
    pnlCards: TPanel;
    pnlEmpresa: TPanel;
    lblEmpresaCap: TLabel;
    lblEmpresaNombre: TLabel;
    lblEmpresaCodigo: TLabel;
    pnlProyecto: TPanel;
    lblProyectoCap: TLabel;
    lblProyectoNombre: TLabel;
    lblProyectoTipo: TLabel;
    pnlUsuario: TPanel;
    lblUsuarioCap: TLabel;
    lblUsuarioNombre: TLabel;
    lblUsuarioRol: TLabel;
    pnlAcciones: TPanel;
    btnAbrirGantt: TButton;
    TimerReloj: TTimer;
    procedure FormShow(Sender: TObject);
    procedure TimerRelojTimer(Sender: TObject);
    procedure btnAbrirGanttClick(Sender: TObject);
  private
    FOnAbrirGantt: TNotifyEvent;
    procedure ActualizarReloj;
  public
    procedure Refrescar;
    property OnAbrirGantt: TNotifyEvent read FOnAbrirGantt write FOnAbrirGantt;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uLogin;

procedure TfrmDashboard.FormShow(Sender: TObject);
begin
  Refrescar;
  ActualizarReloj;
  TimerReloj.Enabled := True;
end;

procedure TfrmDashboard.TimerRelojTimer(Sender: TObject);
begin
  ActualizarReloj;
end;

procedure TfrmDashboard.ActualizarReloj;
begin
  lblFechaHora.Caption := FormatDateTime('dddd, d" de "mmmm" de "yyyy   hh:nn:ss', Now);
end;

procedure TfrmDashboard.Refrescar;
var
  S: TUserSession;
  Tipo: string;
begin
  // Empresa
  if DMPlanner.CurrentEmpresaNombre <> '' then
    lblEmpresaNombre.Caption := DMPlanner.CurrentEmpresaNombre
  else
    lblEmpresaNombre.Caption := '--';
  lblEmpresaCodigo.Caption := 'Código: ' + IntToStr(DMPlanner.CodigoEmpresa);

  // Proyecto
  if DMPlanner.CurrentProjectId > 0 then
  begin
    lblProyectoNombre.Caption := DMPlanner.CurrentProjectName;
    if DMPlanner.CurrentProjectIsMaster then
      Tipo := 'MASTER'
    else
      Tipo := 'Escenario';
    lblProyectoTipo.Caption := 'Tipo: ' + Tipo;
  end
  else
  begin
    lblProyectoNombre.Caption := 'Sin proyecto';
    lblProyectoTipo.Caption := 'Tipo: --';
  end;

  // Usuario
  S := CurrentSession;
  if S.UserId > 0 then
  begin
    if S.NombreCompleto <> '' then
      lblUsuarioNombre.Caption := S.NombreCompleto
    else
      lblUsuarioNombre.Caption := S.Login;
    lblUsuarioRol.Caption := 'Rol: ' + S.RoleNombre;
  end
  else
  begin
    lblUsuarioNombre.Caption := '--';
    lblUsuarioRol.Caption := 'Rol: --';
  end;
end;

procedure TfrmDashboard.btnAbrirGanttClick(Sender: TObject);
begin
  if Assigned(FOnAbrirGantt) then
    FOnAbrirGantt(Self);
end;

end.
