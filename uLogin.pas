unit uLogin;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Hash,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Vcl.Dialogs,
  Data.Win.ADODB, Data.DB;

type
  TUserSession = record
    CodigoEmpresa: SmallInt;
    UserId: Integer;
    Login: string;
    NombreCompleto: string;
    Email: string;
    RoleId: Integer;
    RoleCodigo: string;
    RoleNombre: string;
    Permissions: TArray<string>;  // códigos de permisos
  end;

  TfrmLogin = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBody: TPanel;
    lblEmpresa: TLabel;
    lblUsuario: TLabel;
    lblPassword: TLabel;
    cmbEmpresa: TComboBox;
    edtUsuario: TEdit;
    edtPassword: TEdit;
    btnLogin: TButton;
    btnCancelar: TButton;
    btnDevAdmin: TButton;
    Memo1: TMemo;
    lblConfigBD: TLabel;
    procedure btnLoginClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnDevAdminClick(Sender: TObject);
    procedure lblConfigBDClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    FSession: TUserSession;
    FLoginOK: Boolean;
    FEmpresaCodigos: TArray<SmallInt>;
    procedure LoadEmpresas;
    function GetSelectedEmpresa: SmallInt;
    function HashPassword(const APassword: string): string;
    function ValidateUser(const ALogin, APasswordHash: string): Boolean;
    function ValidateWindowsUser(const ALogin: string): Boolean;
    procedure LoadSessionFromQuery(Q: TADOQuery);
    procedure LoadPermissions;
    procedure LogAccess(const ALogin, AResultado: string; AUserId: Integer);
    procedure ShowError(const AMsg: string);
    procedure LogStep(const AMsg: string);
  public
    property Session: TUserSession read FSession;
    property LoginOK: Boolean read FLoginOK;
  end;

function DoLogin: Boolean;
function CurrentSession: TUserSession;
function HasPermission(const APermissionCode: string): Boolean;
function IsAdmin: Boolean;

implementation

{$R *.dfm}

uses
  uDMPlanner, uAppConfig, uDBConfig;

var
  GSession: TUserSession;

function DoLogin: Boolean;
var
  Frm: TfrmLogin;
begin
  Frm := TfrmLogin.Create(Application);
  try
    Frm.ShowModal;
    Result := Frm.LoginOK;
    if Result then
      GSession := Frm.Session;
  finally
    Frm.Free;
  end;
end;

function CurrentSession: TUserSession;
begin
  Result := GSession;
end;

function IsAdmin: Boolean;
begin
  Result := SameText(GSession.RoleCodigo, 'ADMIN');
end;

function HasPermission(const APermissionCode: string): Boolean;
var
  I: Integer;
begin
  // Admin siempre tiene todo
  if IsAdmin then
    Exit(True);
  for I := 0 to High(GSession.Permissions) do
    if SameText(GSession.Permissions[I], APermissionCode) then
      Exit(True);
  Result := False;
end;

{ TfrmLogin }

function TfrmLogin.HashPassword(const APassword: string): string;
begin
  Result := THashSHA2.GetHashString(APassword, SHA256).ToUpper;
end;

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  Memo1.Lines.Clear;
  Memo1.Visible := True;

  LogStep('Lanzando aplicación FSPlanner 2026...');
  LogStep('Configuración leída desde: ' + ExtractFilePath(ParamStr(0)) + 'FSPlanner2026.ini');

  if not DMPlanner.IsConnected then
  begin
    if DMPlanner.Server <> '' then
      LogStep('Conectando a base de datos: ' + DMPlanner.Server + ' / ' + DMPlanner.Database + '...')
    else
      LogStep('Conectando a base de datos (configuración por defecto)...');

    var R := DMPlanner.Connect;
    if not R.Success then
    begin
      ShowError('No se puede conectar: ' + R.ErrorMessage);
      LogStep('Pulse "Configurar Base de datos" para revisar la conexión.');
      Exit;
    end;
    LogStep('Conexión establecida correctamente.');
    LogStep('Migraciones aplicadas (si las había pendientes).');
  end
  else
    LogStep('Conexión a base de datos ya activa.');

  LogStep('Cargando lista de empresas...');
  LoadEmpresas;
  LogStep('Empresas cargadas: ' + IntToStr(cmbEmpresa.Items.Count) + '.');
  LogStep('Listo. Introduzca usuario y contraseña.');
end;

procedure TfrmLogin.LoadEmpresas;
var
  Q: TADOQuery;
  I: Integer;
begin
  cmbEmpresa.Items.Clear;
  SetLength(FEmpresaCodigos, 0);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT CodigoEmpresa, Nombre FROM FS_PL_Empresa WHERE Activo = 1 ORDER BY CodigoEmpresa';
    Q.Open;
    SetLength(FEmpresaCodigos, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FEmpresaCodigos[I] := Q.FieldByName('CodigoEmpresa').AsInteger;
      cmbEmpresa.Items.Add(Q.FieldByName('Nombre').AsString);
      Inc(I);
      Q.Next;
    end;
    SetLength(FEmpresaCodigos, I);
    if cmbEmpresa.Items.Count > 0 then
      cmbEmpresa.ItemIndex := 0;
  finally
    Q.Free;
  end;
end;

function TfrmLogin.GetSelectedEmpresa: SmallInt;
begin
  if (cmbEmpresa.ItemIndex >= 0) and (cmbEmpresa.ItemIndex <= High(FEmpresaCodigos)) then
    Result := FEmpresaCodigos[cmbEmpresa.ItemIndex]
  else
    Result := 1;
end;

procedure TfrmLogin.ShowError(const AMsg: string);
begin
  Memo1.Font.Color := clRed;
  Memo1.Lines.Add('[' + FormatDateTime('hh:nn:ss', Now) + '] ERROR: ' + AMsg);
  Memo1.Visible := True;
  Application.ProcessMessages;
end;

procedure TfrmLogin.LogStep(const AMsg: string);
begin
  Memo1.Font.Color := clBlack;
  Memo1.Lines.Add('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
  Memo1.Visible := True;
  // Forzar refresco visual durante el arranque
  SendMessage(Memo1.Handle, EM_LINESCROLL, 0, Memo1.Lines.Count);
  Application.ProcessMessages;
end;

procedure TfrmLogin.btnLoginClick(Sender: TObject);
var
  UserLogin, PwdHash: string;
  bValidated: Boolean;
begin
  Memo1.Visible := False;
  FLoginOK := False;
  bValidated := False;

  if cmbEmpresa.ItemIndex < 0 then
  begin
    ShowError('Seleccione una empresa.');
    Exit;
  end;

  // Asignar empresa seleccionada
  DMPlanner.CodigoEmpresa := GetSelectedEmpresa;

  Screen.Cursor := crHourGlass;

  // Verificar conexión a BBDD
  if not DMPlanner.IsConnected then
  begin
    try
    // DMPlanner.ADOConnection.Open;
    finally

    end;

    var R := DMPlanner.Connect;

    if not R.Success then
    begin
      Screen.Cursor := crDefault;
      ShowError('No se puede conectar: ' + R.ErrorMessage);
      Exit;
    end;
  end;


    UserLogin := Trim(edtUsuario.Text);
    if UserLogin = '' then
    begin
      Screen.Cursor := crDefault;
      ShowError('Introduzca el usuario.');
      edtUsuario.SetFocus;
      Exit;
    end;

    if Trim(edtPassword.Text) = '' then
    begin
      Screen.Cursor := crDefault;
      ShowError('Introduzca la contraseña.');
      edtPassword.SetFocus;
      Exit;
    end;

    try
      PwdHash := HashPassword(Trim(edtPassword.Text));
      bValidated := ValidateUser(UserLogin, PwdHash);
    finally

    end;

  if not bValidated then
  begin
        Screen.Cursor := crDefault;
        Exit;
  end;

  LoadPermissions;
  DMPlanner.LoadEmpresaInfo;
  DMPlanner.LoadUserActiveProject(FSession.UserId);
  Screen.Cursor := crDefault;

  if (not IsAdmin) and (DMPlanner.CurrentProjectId <= 0) then
    Vcl.Dialogs.MessageDlg(
      'No tiene ningún proyecto asignado.' + sLineBreak +
      'Contacte con el administrador para que le asigne acceso a un proyecto.',
      mtWarning, [mbOK], 0);

  FLoginOK := True;
  Close;
end;

function TfrmLogin.ValidateUser(const ALogin, APasswordHash: string): Boolean;
var
  Q: TADOQuery;
begin
  Result := False;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT u.CodigoEmpresa, u.UserId, u.Login, u.NombreCompleto, u.Email, u.PasswordHash, ' +
      '       u.Activo, u.Bloqueado, u.Intentos, ' +
      '       r.RoleId, r.Codigo AS RoleCodigo, r.Nombre AS RoleNombre ' +
      'FROM FS_PL_User u ' +
      'INNER JOIN FS_PL_Role r ON r.CodigoEmpresa = u.CodigoEmpresa AND r.RoleId = u.RoleId ' +
      'WHERE u.CodigoEmpresa = :CodigoEmpresa AND u.Login = :Login';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('Login').Value := ALogin;
    Q.Open;

    if Q.Eof then
    begin
      LogAccess(ALogin, 'USER_NOT_FOUND', 0);
      ShowError('Usuario no encontrado.');
      Exit;
    end;

    if not Q.FieldByName('Activo').AsBoolean then
    begin
      LogAccess(ALogin, 'USER_INACTIVE', Q.FieldByName('UserId').AsInteger);
      ShowError('Usuario desactivado. Contacte con el administrador.');
      Exit;
    end;

    if Q.FieldByName('Bloqueado').AsBoolean then
    begin
      LogAccess(ALogin, 'USER_BLOCKED', Q.FieldByName('UserId').AsInteger);
      ShowError('Usuario bloqueado por exceso de intentos.');
      Exit;
    end;

    if not SameText(Q.FieldByName('PasswordHash').AsString, APasswordHash) then
    begin
      // Incrementar intentos
      var UserId := Q.FieldByName('UserId').AsInteger;
      var Intentos := Q.FieldByName('Intentos').AsInteger + 1;
      var CmdSQL := 'UPDATE FS_PL_User SET Intentos = ' + IntToStr(Intentos);
      if Intentos >= 5 then
        CmdSQL := CmdSQL + ', Bloqueado = 1';
      CmdSQL := CmdSQL + ' WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
        ' AND UserId = ' + IntToStr(UserId);

      var Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := DMPlanner.ADOConnection;
        Cmd.CommandText := CmdSQL;
        Cmd.Execute;
      finally
        Cmd.Free;
      end;

      LogAccess(ALogin, 'WRONG_PASSWORD', UserId);
      if Intentos >= 5 then
        ShowError('Contraseña incorrecta. Usuario bloqueado.')
      else
        ShowError('Contraseña incorrecta. Intento ' + IntToStr(Intentos) + ' de 5.');
      Exit;
    end;

    // Login correcto: resetear intentos y actualizar último acceso
    LoadSessionFromQuery(Q);

    var Cmd2 := TADOCommand.Create(nil);
    try
      Cmd2.Connection := DMPlanner.ADOConnection;
      Cmd2.CommandText := 'UPDATE FS_PL_User SET Intentos = 0, UltimoAcceso = GETDATE() ' +
        'WHERE CodigoEmpresa = ' + IntToStr(FSession.CodigoEmpresa) +
        ' AND UserId = ' + IntToStr(FSession.UserId);
      Cmd2.Execute;
    finally
      Cmd2.Free;
    end;

    LogAccess(ALogin, 'OK', FSession.UserId);
    Result := True;
  finally
    Q.Free;
  end;
end;

function TfrmLogin.ValidateWindowsUser(const ALogin: string): Boolean;
var
  Q: TADOQuery;
begin
  Result := False;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT u.CodigoEmpresa, u.UserId, u.Login, u.NombreCompleto, u.Email, u.Activo, ' +
      '       r.RoleId, r.Codigo AS RoleCodigo, r.Nombre AS RoleNombre ' +
      'FROM FS_PL_User u ' +
      'INNER JOIN FS_PL_Role r ON r.CodigoEmpresa = u.CodigoEmpresa AND r.RoleId = u.RoleId ' +
      'WHERE u.CodigoEmpresa = :CodigoEmpresa AND u.Login = :Login AND u.Activo = 1';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('Login').Value := ALogin;
    Q.Open;
    if Q.Eof then
      Exit;

    LoadSessionFromQuery(Q);
    LogAccess(ALogin, 'OK', FSession.UserId);
    Result := True;
  finally
    Q.Free;
  end;
end;

procedure TfrmLogin.LoadSessionFromQuery(Q: TADOQuery);
begin
  FSession.CodigoEmpresa := Q.FieldByName('CodigoEmpresa').AsInteger;
  FSession.UserId := Q.FieldByName('UserId').AsInteger;
  FSession.Login := Q.FieldByName('Login').AsString;
  FSession.NombreCompleto := Q.FieldByName('NombreCompleto').AsString;
  FSession.Email := Q.FieldByName('Email').AsString;
  FSession.RoleId := Q.FieldByName('RoleId').AsInteger;
  FSession.RoleCodigo := Q.FieldByName('RoleCodigo').AsString;
  FSession.RoleNombre := Q.FieldByName('RoleNombre').AsString;
end;

procedure TfrmLogin.LoadPermissions;
var
  Q: TADOQuery;
  Lst: TArray<string>;
  Cnt: Integer;
begin
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT p.Codigo FROM FS_PL_Permission p ' +
      'INNER JOIN FS_PL_RolePermission rp ON rp.CodigoEmpresa = p.CodigoEmpresa AND rp.PermissionId = p.PermissionId ' +
      'WHERE rp.CodigoEmpresa = :CodigoEmpresa AND rp.RoleId = :RoleId';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := FSession.CodigoEmpresa;
    Q.Parameters.ParamByName('RoleId').Value := FSession.RoleId;
    Q.Open;
    SetLength(Lst, Q.RecordCount);
    Cnt := 0;
    while not Q.Eof do
    begin
      Lst[Cnt] := Q.FieldByName('Codigo').AsString;
      Inc(Cnt);
      Q.Next;
    end;
    SetLength(Lst, Cnt);
    FSession.Permissions := Lst;
  finally
    Q.Free;
  end;
end;

procedure TfrmLogin.LogAccess(const ALogin, AResultado: string; AUserId: Integer);
var
  Cmd: TADOCommand;
  UserIdStr, Machine: string;
begin
  try
    if AUserId > 0 then
      UserIdStr := IntToStr(AUserId)
    else
      UserIdStr := 'NULL';
    Machine := GetEnvironmentVariable('COMPUTERNAME');

    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;
      Cmd.CommandText :=
        'INSERT INTO FS_PL_AccessLog (CodigoEmpresa, UserId, Login, Resultado, MachineName) VALUES (' +
        IntToStr(DMPlanner.CodigoEmpresa) + ', ' +
        UserIdStr + ', ' +
        '''' + StringReplace(ALogin, '''', '''''', [rfReplaceAll]) + ''', ' +
        '''' + AResultado + ''', ' +
        '''' + StringReplace(Machine, '''', '''''', [rfReplaceAll]) + ''')';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
  except
    // No fallar por log
  end;
end;

procedure TfrmLogin.btnDevAdminClick(Sender: TObject);
begin
  Memo1.Visible := False;

  if cmbEmpresa.ItemIndex < 0 then
  begin
    if cmbEmpresa.Items.Count > 0 then
      cmbEmpresa.ItemIndex := 0
    else
    begin
      ShowError('No hay empresas disponibles.');
      Exit;
    end;
  end;

  DMPlanner.CodigoEmpresa := GetSelectedEmpresa;

  if not DMPlanner.IsConnected then
  begin
    var R := DMPlanner.Connect;
    if not R.Success then
    begin
      ShowError('No se puede conectar: ' + R.ErrorMessage);
      Exit;
    end;
  end;

  edtUsuario.Text := 'admin';
  edtPassword.Text := 'admin';

  if ValidateUser('admin', HashPassword('admin')) then
  begin
    LoadPermissions;
    DMPlanner.LoadEmpresaInfo;
    DMPlanner.LoadMasterProject;
    FLoginOK := True;
    Close;
  end;
end;

procedure TfrmLogin.btnCancelarClick(Sender: TObject);
begin
  FLoginOK := False;
  Close;
end;

procedure TfrmLogin.lblConfigBDClick(Sender: TObject);
var
  Cfg: TDBConfig;
begin
  if not ShowDBConfigDialog then Exit;

  LogStep('Nueva configuración guardada. Reconectando...');

  if DMPlanner.IsConnected then
    DMPlanner.Disconnect;

  Cfg := LoadDBConfig;
  DMPlanner.Server         := Cfg.Server;
  DMPlanner.Database       := Cfg.Database;
  DMPlanner.UseWindowsAuth := Cfg.WindowsAuth;
  DMPlanner.UserName       := Cfg.UserName;
  DMPlanner.Password       := Cfg.Password;

  LogStep('Conectando a base de datos: ' + DMPlanner.Server + ' / ' + DMPlanner.Database + '...');
  var R := DMPlanner.Connect;
  if not R.Success then
  begin
    ShowError('No se puede conectar: ' + R.ErrorMessage);
    Exit;
  end;
  LogStep('Conexión establecida correctamente.');

  LogStep('Cargando lista de empresas...');
  LoadEmpresas;
  LogStep('Empresas cargadas: ' + IntToStr(cmbEmpresa.Items.Count) + '.');
end;

procedure TfrmLogin.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
  begin
    FLoginOK := False;
    Close;
  end;
end;

end.
