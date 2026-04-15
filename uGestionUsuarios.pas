unit uGestionUsuarios;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Hash, System.StrUtils, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxDropDownEdit,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB;

type
  TfrmGestionUsuarios = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnDel: TButton;
    btnSave: TButton;
    btnResetPwd: TButton;
    btnUnblock: TButton;
    gridUsers: TcxGrid;
    tvUsers: TcxGridTableView;
    colUserId: TcxGridColumn;
    colUserLogin: TcxGridColumn;
    colUserNombre: TcxGridColumn;
    colUserEmail: TcxGridColumn;
    colUserRol: TcxGridColumn;
    colUserActivo: TcxGridColumn;
    colUserBloqueado: TcxGridColumn;
    colUserUltimoAcceso: TcxGridColumn;
    lvUsers: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnResetPwdClick(Sender: TObject);
    procedure btnUnblockClick(Sender: TObject);
  private
    FUserIds: TArray<Integer>;
    FRoleIds: TArray<Integer>;
    FRoleNames: TArray<string>;
    procedure LoadRoles;
    procedure SetupRolColumn;
    procedure LoadUsers;
    function GetSelectedUserId: Integer;
    function GetSelectedRecIdx: Integer;
    function RoleNameToId(const AName: string): Integer;
    function ExecSQL(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
    function HashPassword(const APassword: string): string;
  end;

var
  frmGestionUsuarios: TfrmGestionUsuarios;

implementation

{$R *.dfm}

uses
  uDMPlanner, uLogin;

function TfrmGestionUsuarios.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmGestionUsuarios.HashPassword(const APassword: string): string;
begin
  Result := THashSHA2.GetHashString(APassword, SHA256).ToUpper;
end;

function TfrmGestionUsuarios.ExecSQL(const ASQL: string): Integer;
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText := ASQL;
    Cmd.Execute(Result, EmptyParam);
  finally
    Cmd.Free;
  end;
end;

function TfrmGestionUsuarios.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

// ════════════════════════════════════════════════════════════════════
//  INICIALIZACIÓN
// ════════════════════════════════════════════════════════════════════

procedure TfrmGestionUsuarios.FormCreate(Sender: TObject);
begin
  LoadRoles;
  SetupRolColumn;
  LoadUsers;
end;

procedure TfrmGestionUsuarios.FormDestroy(Sender: TObject);
begin
  // nada
end;

procedure TfrmGestionUsuarios.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmGestionUsuarios.LoadRoles;
var
  Q: TADOQuery;
  I: Integer;
begin
  Q := OpenQuery('SELECT RoleId, Nombre FROM FS_PL_Role WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) + ' AND Activo = 1 ORDER BY Nombre');
  try
    SetLength(FRoleIds, Q.RecordCount);
    SetLength(FRoleNames, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FRoleIds[I] := Q.FieldByName('RoleId').AsInteger;
      FRoleNames[I] := Q.FieldByName('Nombre').AsString;
      Inc(I);
      Q.Next;
    end;
    SetLength(FRoleIds, I);
    SetLength(FRoleNames, I);
  finally
    Q.Free;
  end;
end;

procedure TfrmGestionUsuarios.SetupRolColumn;
var
  Props: TcxComboBoxProperties;
  I: Integer;
begin
  Props := colUserRol.Properties as TcxComboBoxProperties;
  Props.Items.Clear;
  Props.DropDownListStyle := lsFixedList;
  for I := 0 to High(FRoleNames) do
    Props.Items.Add(FRoleNames[I]);
end;

function TfrmGestionUsuarios.RoleNameToId(const AName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FRoleNames) do
    if SameText(FRoleNames[I], AName) then
      Exit(FRoleIds[I]);
  Result := -1;
end;

// ════════════════════════════════════════════════════════════════════
//  CARGA DE USUARIOS
// ════════════════════════════════════════════════════════════════════

procedure TfrmGestionUsuarios.LoadUsers;
var
  Q: TADOQuery;
  I: Integer;
begin
  tvUsers.BeginUpdate;
  try
    tvUsers.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT u.UserId, u.Login, u.NombreCompleto, u.Email, r.Nombre AS RolNombre, ' +
      '  u.Activo, u.Bloqueado, u.UltimoAcceso ' +
      'FROM FS_PL_User u ' +
      'INNER JOIN FS_PL_Role r ON r.CodigoEmpresa = u.CodigoEmpresa AND r.RoleId = u.RoleId ' +
      'WHERE u.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY u.Login');
    try
      SetLength(FUserIds, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        tvUsers.DataController.RecordCount := I + 1;
        tvUsers.DataController.Values[I, colUserId.Index] := Q.FieldByName('UserId').AsInteger;
        tvUsers.DataController.Values[I, colUserLogin.Index] := Q.FieldByName('Login').AsString;
        tvUsers.DataController.Values[I, colUserNombre.Index] := Q.FieldByName('NombreCompleto').AsString;
        tvUsers.DataController.Values[I, colUserEmail.Index] := Q.FieldByName('Email').AsString;
        tvUsers.DataController.Values[I, colUserRol.Index] := Q.FieldByName('RolNombre').AsString;
        tvUsers.DataController.Values[I, colUserActivo.Index] := Q.FieldByName('Activo').AsBoolean;
        tvUsers.DataController.Values[I, colUserBloqueado.Index] := Q.FieldByName('Bloqueado').AsBoolean;
        if not Q.FieldByName('UltimoAcceso').IsNull then
          tvUsers.DataController.Values[I, colUserUltimoAcceso.Index] :=
            FormatDateTime('dd/mm/yyyy hh:nn', Q.FieldByName('UltimoAcceso').AsDateTime)
        else
          tvUsers.DataController.Values[I, colUserUltimoAcceso.Index] := '';
        FUserIds[I] := Q.FieldByName('UserId').AsInteger;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvUsers.EndUpdate;
  end;
end;

function TfrmGestionUsuarios.GetSelectedRecIdx: Integer;
begin
  Result := -1;
  if tvUsers.Controller.FocusedRecord <> nil then
    Result := tvUsers.Controller.FocusedRecord.RecordIndex;
end;

function TfrmGestionUsuarios.GetSelectedUserId: Integer;
var
  Idx: Integer;
begin
  Result := -1;
  Idx := GetSelectedRecIdx;
  if (Idx >= 0) and (Idx <= High(FUserIds)) then
    Result := FUserIds[Idx];
end;

// ════════════════════════════════════════════════════════════════════
//  ACCIONES
// ════════════════════════════════════════════════════════════════════

procedure TfrmGestionUsuarios.btnAddClick(Sender: TObject);
var
  Login, Pwd: string;
  Q: TADOQuery;
  NewId, Cnt, RoleId: Integer;
begin
  Login := InputBox('Nuevo Usuario', 'Login:', '');
  if Login = '' then Exit;
  Pwd := InputBox('Nuevo Usuario', 'Contraseña:', '');
  if Pwd = '' then Exit;

  // Usar el primer rol disponible
  if Length(FRoleIds) = 0 then
  begin
    ShowMessage('No hay roles definidos.');
    Exit;
  end;
  RoleId := FRoleIds[0];

  ExecSQL('INSERT INTO FS_PL_User (CodigoEmpresa, Login, PasswordHash, NombreCompleto, Email, RoleId) VALUES (' +
    IntToStr(DMPlanner.CodigoEmpresa) + ', ' +
    QStr(Login) + ', ' +
    QStr(HashPassword(Pwd)) + ', ' +
    QStr(Login) + ', ' +
    QStr('') + ', ' +
    IntToStr(RoleId) + ')');

  Q := OpenQuery('SELECT MAX(UserId) AS NewId FROM FS_PL_User WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa));
  try
    NewId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;

  Cnt := tvUsers.DataController.RecordCount;
  tvUsers.DataController.RecordCount := Cnt + 1;
  tvUsers.DataController.Values[Cnt, colUserId.Index] := NewId;
  tvUsers.DataController.Values[Cnt, colUserLogin.Index] := Login;
  tvUsers.DataController.Values[Cnt, colUserNombre.Index] := Login;
  tvUsers.DataController.Values[Cnt, colUserEmail.Index] := '';
  tvUsers.DataController.Values[Cnt, colUserRol.Index] := FRoleNames[0];
  tvUsers.DataController.Values[Cnt, colUserActivo.Index] := True;
  tvUsers.DataController.Values[Cnt, colUserBloqueado.Index] := False;
  tvUsers.DataController.Values[Cnt, colUserUltimoAcceso.Index] := '';

  SetLength(FUserIds, Cnt + 1);
  FUserIds[Cnt] := NewId;

  tvUsers.Controller.FocusedRecordIndex := Cnt;
  tvUsers.Controller.FocusedColumn := colUserNombre;
end;

procedure TfrmGestionUsuarios.btnDelClick(Sender: TObject);
var
  UserId: Integer;
begin
  UserId := GetSelectedUserId;
  if UserId < 0 then Exit;
  if MessageDlg('¿Eliminar este usuario?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  ExecSQL('DELETE FROM FS_PL_User WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) + ' AND UserId = ' + IntToStr(UserId));
  LoadUsers;
end;

procedure TfrmGestionUsuarios.btnSaveClick(Sender: TObject);
var
  I, UserId, RoleId: Integer;
  Login, Nombre, Email, RolName: string;
  Activo: Boolean;
  CE: string;
  V: Variant;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  for I := 0 to tvUsers.DataController.RecordCount - 1 do
  begin
    if I > High(FUserIds) then Continue;
    UserId := FUserIds[I];
    Login := VarToStr(tvUsers.DataController.Values[I, colUserLogin.Index]);
    Nombre := VarToStr(tvUsers.DataController.Values[I, colUserNombre.Index]);
    Email := VarToStr(tvUsers.DataController.Values[I, colUserEmail.Index]);
    RolName := VarToStr(tvUsers.DataController.Values[I, colUserRol.Index]);
    V := tvUsers.DataController.Values[I, colUserActivo.Index];
    Activo := (not VarIsNull(V)) and (not VarIsEmpty(V)) and Boolean(V);

    RoleId := RoleNameToId(RolName);
    if RoleId < 0 then Continue;

    ExecSQL('UPDATE FS_PL_User SET ' +
      'Login = ' + QStr(Login) + ', ' +
      'NombreCompleto = ' + QStr(Nombre) + ', ' +
      'Email = ' + QStr(Email) + ', ' +
      'RoleId = ' + IntToStr(RoleId) + ', ' +
      'Activo = ' + IfThen(Activo, '1', '0') +
      ' WHERE CodigoEmpresa = ' + CE +
      ' AND UserId = ' + IntToStr(UserId));
  end;

  ShowMessage('Usuarios guardados correctamente.');
end;

procedure TfrmGestionUsuarios.btnResetPwdClick(Sender: TObject);
var
  UserId: Integer;
  NewPwd: string;
begin
  UserId := GetSelectedUserId;
  if UserId < 0 then Exit;

  NewPwd := InputBox('Reset Contraseña', 'Nueva contraseña:', '');
  if NewPwd = '' then Exit;

  ExecSQL('UPDATE FS_PL_User SET PasswordHash = ' + QStr(HashPassword(NewPwd)) +
    ', Intentos = 0, Bloqueado = 0' +
    ' WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
    ' AND UserId = ' + IntToStr(UserId));
  ShowMessage('Contraseña actualizada.');
  LoadUsers;
end;

procedure TfrmGestionUsuarios.btnUnblockClick(Sender: TObject);
var
  UserId: Integer;
begin
  UserId := GetSelectedUserId;
  if UserId < 0 then Exit;

  ExecSQL('UPDATE FS_PL_User SET Intentos = 0, Bloqueado = 0' +
    ' WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
    ' AND UserId = ' + IntToStr(UserId));
  ShowMessage('Usuario desbloqueado.');
  LoadUsers;
end;

end.
