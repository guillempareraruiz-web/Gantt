unit uErpPrefsSage200;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.DateUtils,
  Winapi.Windows, Winapi.Messages,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Data.DB, Data.Win.ADODB,
  uAppConfig;

type
  TfrmErpPrefsSage200 = class(TForm)
    pnlConexion: TGroupBox;
    lblServer: TLabel;
    lblDatabase: TLabel;
    lblUserName: TLabel;
    lblPassword: TLabel;
    edServer: TEdit;
    edDatabase: TEdit;
    chkWindowsAuth: TCheckBox;
    edUserName: TEdit;
    edPassword: TEdit;
    pnlEmpresa: TGroupBox;
    lblGrupoEmpresa: TLabel;
    lblCodigoEmpresa: TLabel;
    lblEjercicio: TLabel;
    cmbGrupoEmpresa: TComboBox;
    btnCargarEmpresas: TButton;
    cmbCodigoEmpresa: TComboBox;
    edEjercicio: TEdit;
    pnlFiltros: TGroupBox;
    lblFechaDesde: TLabel;
    lblFechaHasta: TLabel;
    dtFechaDesde: TDateTimePicker;
    dtFechaHasta: TDateTimePicker;
    chkIncluirFinalizadas: TCheckBox;
    lblFiltrosNota: TLabel;
    pnlPruebas: TPanel;
    btnProbarConexion: TButton;
    btnProbarLectura: TButton;
    lblResultado: TLabel;
    pnlBotones: TPanel;
    btnGuardar: TButton;
    btnCancelar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure chkWindowsAuthClick(Sender: TObject);
    procedure btnCargarEmpresasClick(Sender: TObject);
    procedure btnProbarConexionClick(Sender: TObject);
    procedure btnProbarLecturaClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
  private
    procedure CargarEnControles(const ACfg: TErpSage200Config);
    function LeerDeControles: TErpSage200Config;
    procedure ActualizarHabilitacionAuth;
    function BuildConnectionString(const ACfg: TErpSage200Config): string;
    procedure SetResultado(const AMsg: string; AColor: TColor);
  public
    class function Execute: Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmErpPrefsSage200.Execute: Boolean;
var
  Frm: TfrmErpPrefsSage200;
begin
  Frm := TfrmErpPrefsSage200.Create(nil);
  try
    Result := Frm.ShowModal = mrOk;
  finally
    Frm.Free;
  end;
end;

procedure TfrmErpPrefsSage200.FormCreate(Sender: TObject);
begin
  CargarEnControles(LoadErpSage200Config);
  ActualizarHabilitacionAuth;
end;

procedure TfrmErpPrefsSage200.CargarEnControles(const ACfg: TErpSage200Config);
begin
  edServer.Text       := ACfg.Server;
  edDatabase.Text     := ACfg.Database;
  chkWindowsAuth.Checked := ACfg.WindowsAuth;
  edUserName.Text     := ACfg.UserName;
  edPassword.Text     := ACfg.Password;

  cmbGrupoEmpresa.Text  := ACfg.GrupoEmpresa;
  cmbCodigoEmpresa.Text := ACfg.CodigoEmpresa;
  if ACfg.Ejercicio > 0 then
    edEjercicio.Text := IntToStr(ACfg.Ejercicio)
  else
    edEjercicio.Text := IntToStr(YearOf(Now));

  if ACfg.FechaDesde = 0 then
    dtFechaDesde.Date := Date
  else
    dtFechaDesde.Date := ACfg.FechaDesde;
  if ACfg.FechaHasta = 0 then
    dtFechaHasta.Date := Date
  else
    dtFechaHasta.Date := ACfg.FechaHasta;

  chkIncluirFinalizadas.Checked := ACfg.IncluirFinalizadas;
end;

function TfrmErpPrefsSage200.LeerDeControles: TErpSage200Config;
begin
  Result.Server             := Trim(edServer.Text);
  Result.Database           := Trim(edDatabase.Text);
  Result.WindowsAuth        := chkWindowsAuth.Checked;
  Result.UserName           := Trim(edUserName.Text);
  Result.Password           := edPassword.Text;
  Result.GrupoEmpresa       := Trim(cmbGrupoEmpresa.Text);
  Result.CodigoEmpresa      := Trim(cmbCodigoEmpresa.Text);
  Result.Ejercicio          := StrToIntDef(edEjercicio.Text, YearOf(Now));
  Result.FechaDesde         := dtFechaDesde.Date;
  Result.FechaHasta         := dtFechaHasta.Date;
  Result.IncluirFinalizadas := chkIncluirFinalizadas.Checked;
end;

procedure TfrmErpPrefsSage200.ActualizarHabilitacionAuth;
begin
  edUserName.Enabled := not chkWindowsAuth.Checked;
  edPassword.Enabled := not chkWindowsAuth.Checked;
end;

procedure TfrmErpPrefsSage200.chkWindowsAuthClick(Sender: TObject);
begin
  ActualizarHabilitacionAuth;
end;

function TfrmErpPrefsSage200.BuildConnectionString(
  const ACfg: TErpSage200Config): string;
begin
  if ACfg.WindowsAuth then
    Result := Format(
      'Provider=SQLOLEDB.1;Data Source=%s;Initial Catalog=%s;' +
      'Integrated Security=SSPI;',
      [ACfg.Server, ACfg.Database])
  else
    Result := Format(
      'Provider=SQLOLEDB.1;Data Source=%s;Initial Catalog=%s;' +
      'User ID=%s;Password=%s;',
      [ACfg.Server, ACfg.Database, ACfg.UserName, ACfg.Password]);
end;

procedure TfrmErpPrefsSage200.SetResultado(const AMsg: string; AColor: TColor);
begin
  lblResultado.Font.Color := AColor;
  lblResultado.Caption := AMsg;
  Application.ProcessMessages;
end;

procedure TfrmErpPrefsSage200.btnProbarConexionClick(Sender: TObject);
var
  Cfg: TErpSage200Config;
  Conn: TADOConnection;
begin
  Cfg := LeerDeControles;
  if not Cfg.IsValid then
  begin
    SetResultado('Faltan datos de conexi'#243'n.', clRed);
    Exit;
  end;

  SetResultado('Probando conexi'#243'n...', clBlue);
  Conn := TADOConnection.Create(nil);
  try
    Conn.LoginPrompt := False;
    Conn.ConnectionString := BuildConnectionString(Cfg);
    try
      Conn.Connected := True;
      SetResultado('Conexi'#243'n SQL correcta.', clGreen);
    except
      on E: Exception do
        SetResultado('Error: ' + E.Message, clRed);
    end;
  finally
    Conn.Free;
  end;
end;

procedure TfrmErpPrefsSage200.btnCargarEmpresasClick(Sender: TObject);
begin
  // TODO: cuando tengamos acceso a una BBDD Sage200 real,
  // ejecutar SELECT contra la tabla GrupoEmpresa/Empresas y poblar combos.
  SetResultado('Carga de empresas a'#250'n no implementada.', clOlive);
end;

procedure TfrmErpPrefsSage200.btnProbarLecturaClick(Sender: TObject);
begin
  // TODO: cuando tengamos acceso a una BBDD Sage200 real,
  // hacer SELECT TOP 1 de una tabla conocida (p.ej. GrupoEmpresa)
  // y reportar OK + n'#250'mero de filas.
  SetResultado('Test de lectura ERP a'#250'n no implementado.', clOlive);
end;

procedure TfrmErpPrefsSage200.btnGuardarClick(Sender: TObject);
var
  Cfg: TErpSage200Config;
begin
  Cfg := LeerDeControles;
  if not Cfg.IsValid then
  begin
    ShowMessage('Faltan datos de conexi'#243'n SQL (servidor, base de datos y, ' +
      'si no es autenticaci'#243'n Windows, el usuario).');
    ModalResult := mrNone;
    Exit;
  end;
  SaveErpSage200Config(Cfg);
end;

end.
