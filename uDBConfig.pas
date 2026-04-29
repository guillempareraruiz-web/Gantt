unit uDBConfig;

interface

uses
  Winapi.Windows, System.SysUtils, System.StrUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Vcl.Dialogs, Data.Win.ADODB,
  uAppConfig, uDMPlanner;

type
  TfrmDBConfig = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBody: TPanel;
    lblServer: TLabel;
    edtServer: TEdit;
    lblDatabase: TLabel;
    edtDatabase: TEdit;
    chkWindowsAuth: TCheckBox;
    lblUserName: TLabel;
    edtUserName: TEdit;
    lblPassword: TLabel;
    edtPassword: TEdit;
    btnTest: TButton;
    btnGuardar: TButton;
    btnCancelar: TButton;
    btnRestablecer: TButton;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure chkWindowsAuthClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnRestablecerClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    FSaved: Boolean;
    procedure UpdateAuthControls;
    function CollectConfig: TDBConfig;
    procedure ApplyConfig(const ACfg: TDBConfig);
    procedure ShowMsg(const AMsg: string; AColor: TColor);
    function BuildConfigFromADO: TDBConfig;
  public
    property Saved: Boolean read FSaved;
  end;

function ShowDBConfigDialog: Boolean;

implementation

{$R *.dfm}

function ShowDBConfigDialog: Boolean;
var
  Frm: TfrmDBConfig;
begin
  Frm := TfrmDBConfig.Create(nil);
  try
    Frm.ShowModal;
    Result := Frm.Saved;
  finally
    Frm.Free;
  end;
end;

{ TfrmDBConfig }

function ExtractConnStringValue(const CS, Key: string): string;
var
  P, P2: Integer;
  K: string;
  Upper: string;
begin
  Result := '';
  Upper := UpperCase(CS);
  K := UpperCase(Key) + '=';
  P := Pos(K, Upper);
  if P = 0 then Exit;
  Inc(P, Length(K));
  P2 := PosEx(';', CS, P);
  if P2 = 0 then P2 := Length(CS) + 1;
  Result := Trim(Copy(CS, P, P2 - P));
end;

function TfrmDBConfig.BuildConfigFromADO: TDBConfig;
var
  CS: string;
begin
  Result.Server      := '';
  Result.Database    := '';
  Result.WindowsAuth := True;
  Result.UserName    := '';
  Result.Password    := '';

  // Prioridad 1: lo que ya tenga DMPlanner en memoria (puesto desde el INI al iniciar)
  if (DMPlanner <> nil) and (Trim(DMPlanner.Server) <> '') then
  begin
    Result.Server      := DMPlanner.Server;
    Result.Database    := DMPlanner.Database;
    Result.WindowsAuth := DMPlanner.UseWindowsAuth;
    Result.UserName    := DMPlanner.UserName;
    Result.Password    := DMPlanner.Password;
    Exit;
  end;

  // Prioridad 2: parsear la ConnectionString del componente ADO (viene del .dfm)
  if (DMPlanner <> nil) and (DMPlanner.ADOConnection <> nil) and
     (Trim(DMPlanner.ADOConnection.ConnectionString) <> '') then
  begin
    CS := DMPlanner.ADOConnection.ConnectionString;
    Result.Server   := ExtractConnStringValue(CS, 'Data Source');
    Result.Database := ExtractConnStringValue(CS, 'Initial Catalog');
    Result.UserName := ExtractConnStringValue(CS, 'User ID');
    Result.WindowsAuth := Pos('INTEGRATED SECURITY=SSPI', UpperCase(CS)) > 0;
  end;
end;

procedure TfrmDBConfig.FormCreate(Sender: TObject);
var
  Cfg: TDBConfig;
begin
  Memo1.Lines.Text := '';
  Memo1.Visible := False;
  FSaved := False;

  // 1. Lo guardado en INI tiene prioridad
  Cfg := LoadDBConfig;

  // 2. Si el INI no aporta nada, usar la conexión actual (DMPlanner / .dfm)
  if Trim(Cfg.Server) = '' then
    Cfg := BuildConfigFromADO;

  // 3. Defaults razonables si todavía no hay nada
  if Trim(Cfg.Server) = '' then
    Cfg.Server := '(local)';
  if Trim(Cfg.Database) = '' then
    Cfg.Database := 'FSPlanner';
  if (Trim(Cfg.UserName) = '') and (not Cfg.WindowsAuth) then
    Cfg.UserName := 'sa';

  ApplyConfig(Cfg);
  UpdateAuthControls;
end;

procedure TfrmDBConfig.btnRestablecerClick(Sender: TObject);
var
  Cfg: TDBConfig;
begin
  Cfg := BuildConfigFromADO;
  if Trim(Cfg.Server) = '' then
    Cfg.Server := '(local)';
  if Trim(Cfg.Database) = '' then
    Cfg.Database := 'FSPlanner';
  ApplyConfig(Cfg);
  UpdateAuthControls;
  ShowMsg('Valores restablecidos desde la conexión actual de la aplicación.', clNavy);
end;

procedure TfrmDBConfig.ApplyConfig(const ACfg: TDBConfig);
begin
  edtServer.Text     := ACfg.Server;
  edtDatabase.Text   := ACfg.Database;
  chkWindowsAuth.Checked := ACfg.WindowsAuth;
  edtUserName.Text   := ACfg.UserName;
  edtPassword.Text   := ACfg.Password;
end;

function TfrmDBConfig.CollectConfig: TDBConfig;
begin
  Result.Server      := Trim(edtServer.Text);
  Result.Database    := Trim(edtDatabase.Text);
  Result.WindowsAuth := chkWindowsAuth.Checked;
  Result.UserName    := Trim(edtUserName.Text);
  Result.Password    := edtPassword.Text;
end;

procedure TfrmDBConfig.UpdateAuthControls;
var
  Enab: Boolean;
begin
  Enab := not chkWindowsAuth.Checked;
  edtUserName.Enabled := Enab;
  edtPassword.Enabled := Enab;
  lblUserName.Enabled := Enab;
  lblPassword.Enabled := Enab;
end;

procedure TfrmDBConfig.chkWindowsAuthClick(Sender: TObject);
begin
  UpdateAuthControls;
end;

procedure TfrmDBConfig.ShowMsg(const AMsg: string; AColor: TColor);
begin
  Memo1.Font.Color := AColor;
  Memo1.Lines.Text := AMsg;
  Memo1.Visible := True;
end;

procedure TfrmDBConfig.btnTestClick(Sender: TObject);
var
  Cfg: TDBConfig;
  Conn: TADOConnection;
  CS: string;
begin
  Cfg := CollectConfig;
  if not Cfg.IsValid then
  begin
    ShowMsg('Faltan datos: rellene servidor, base de datos y usuario (si no usa autenticación de Windows).', clRed);
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    CS := 'Provider=MSOLEDBSQL.1;Data Source=' + Cfg.Server +
          ';Initial Catalog=' + Cfg.Database;
    if Cfg.WindowsAuth then
      CS := CS + ';Integrated Security=SSPI'
    else
      CS := CS + ';User ID=' + Cfg.UserName + ';Password=' + Cfg.Password;

    Conn := TADOConnection.Create(nil);
    try
      Conn.LoginPrompt := False;
      Conn.ConnectionTimeout := 10;
      Conn.ConnectionString := CS;
      try
        Conn.Connected := True;
        ShowMsg('Conexión correcta.', clGreen);
        Conn.Connected := False;
      except
        on E: Exception do
          ShowMsg('Error de conexión: ' + E.Message, clRed);
      end;
    finally
      Conn.Free;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmDBConfig.btnGuardarClick(Sender: TObject);
var
  Cfg: TDBConfig;
begin
  Cfg := CollectConfig;
  if not Cfg.IsValid then
  begin
    ShowMsg('Faltan datos: rellene servidor, base de datos y usuario (si no usa autenticación de Windows).', clRed);
    Exit;
  end;
  try
    SaveDBConfig(Cfg);
    FSaved := True;
    Close;
  except
    on E: Exception do
      ShowMsg('No se pudo guardar la configuración: ' + E.Message, clRed);
  end;
end;

procedure TfrmDBConfig.btnCancelarClick(Sender: TObject);
begin
  FSaved := False;
  Close;
end;

procedure TfrmDBConfig.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
  begin
    FSaved := False;
    Close;
  end;
end;

end.
