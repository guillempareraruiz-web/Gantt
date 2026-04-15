unit uGestionRoles;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants, System.StrUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxContainer, cxClasses, cxFilter, cxPC,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB;

type
  TfrmGestionRoles = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    pnlBottom: TPanel;
    btnClose: TButton;
    pc: TcxPageControl;
    LookAndFeel: TcxLookAndFeelController;
    // Tab Roles
    tabRoles: TcxTabSheet;
    pnlRolesToolbar: TPanel;
    btnRoleAdd: TButton;
    btnRoleDel: TButton;
    btnRoleSave: TButton;
    gridRoles: TcxGrid;
    tvRoles: TcxGridTableView;
    colRoleCodigo: TcxGridColumn;
    colRoleNombre: TcxGridColumn;
    colRoleDescripcion: TcxGridColumn;
    colRoleActivo: TcxGridColumn;
    lvRoles: TcxGridLevel;
    // Tab Permisos
    tabPermisos: TcxTabSheet;
    splPermisos: TSplitter;
    pnlPermRoles: TPanel;
    lblPermRol: TLabel;
    gridPermRoles: TcxGrid;
    tvPermRoles: TcxGridTableView;
    colPermRolNombre: TcxGridColumn;
    lvPermRoles: TcxGridLevel;
    pnlPermRight: TPanel;
    pnlPermToolbar: TPanel;
    btnPermSave: TButton;
    gridPermisos: TcxGrid;
    tvPermisos: TcxGridTableView;
    colPermModulo: TcxGridColumn;
    colPermCodigo: TcxGridColumn;
    colPermNombre: TcxGridColumn;
    colPermAsignado: TcxGridColumn;
    lvPermisos: TcxGridLevel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnRoleAddClick(Sender: TObject);
    procedure btnRoleDelClick(Sender: TObject);
    procedure btnRoleSaveClick(Sender: TObject);
    procedure tvPermRolesFocusedRecordChanged(
      Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure btnPermSaveClick(Sender: TObject);
  private
    FRoleIds: TArray<Integer>;
    FPermIds: TArray<Integer>;
    FSelectedRoleId: Integer;
    procedure LoadRoles;
    procedure LoadPermRoles;
    procedure LoadPermisosForRole(ARoleId: Integer);
    function GetSelectedRoleId: Integer;
    function ExecSQL(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
  end;

var
  frmGestionRoles: TfrmGestionRoles;

implementation

{$R *.dfm}

uses
  uDMPlanner, uLogin;

function TfrmGestionRoles.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmGestionRoles.ExecSQL(const ASQL: string): Integer;
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

function TfrmGestionRoles.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

procedure TfrmGestionRoles.FormCreate(Sender: TObject);
begin
  FSelectedRoleId := -1;
  LoadRoles;
  LoadPermRoles;
end;

procedure TfrmGestionRoles.FormDestroy(Sender: TObject);
begin
  // nada
end;

procedure TfrmGestionRoles.btnCloseClick(Sender: TObject);
begin
  Close;
end;

// ════════════════════════════════════════════════════════════════════
//  TAB ROLES
// ════════════════════════════════════════════════════════════════════

procedure TfrmGestionRoles.LoadRoles;
var
  Q: TADOQuery;
  I: Integer;
begin
  tvRoles.BeginUpdate;
  try
    tvRoles.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT RoleId, Codigo, Nombre, Descripcion, Activo FROM FS_PL_Role ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY RoleId');
    try
      SetLength(FRoleIds, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        tvRoles.DataController.RecordCount := I + 1;
        tvRoles.DataController.Values[I, colRoleCodigo.Index] := Q.FieldByName('Codigo').AsString;
        tvRoles.DataController.Values[I, colRoleNombre.Index] := Q.FieldByName('Nombre').AsString;
        tvRoles.DataController.Values[I, colRoleDescripcion.Index] := Q.FieldByName('Descripcion').AsString;
        tvRoles.DataController.Values[I, colRoleActivo.Index] := Q.FieldByName('Activo').AsBoolean;
        FRoleIds[I] := Q.FieldByName('RoleId').AsInteger;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvRoles.EndUpdate;
  end;
end;

function TfrmGestionRoles.GetSelectedRoleId: Integer;
var
  Idx: Integer;
begin
  Result := -1;
  if tvRoles.Controller.FocusedRecord = nil then Exit;
  Idx := tvRoles.Controller.FocusedRecord.RecordIndex;
  if (Idx >= 0) and (Idx <= High(FRoleIds)) then
    Result := FRoleIds[Idx];
end;

procedure TfrmGestionRoles.btnRoleAddClick(Sender: TObject);
var
  Codigo: string;
  Q: TADOQuery;
  NewId, Cnt: Integer;
begin
  Codigo := InputBox('Nuevo Rol', 'Código:', '');
  if Codigo = '' then Exit;

  ExecSQL('INSERT INTO FS_PL_Role (CodigoEmpresa, Codigo, Nombre, Descripcion) VALUES (' +
    IntToStr(DMPlanner.CodigoEmpresa) + ', ' +
    QStr(Codigo) + ', ' + QStr(Codigo) + ', ' + QStr('') + ')');

  // Obtenir el nou ID
  Q := OpenQuery('SELECT MAX(RoleId) AS NewId FROM FS_PL_Role WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa));
  try
    NewId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;

  // Afegir fila al grid
  Cnt := tvRoles.DataController.RecordCount;
  tvRoles.DataController.RecordCount := Cnt + 1;
  tvRoles.DataController.Values[Cnt, colRoleCodigo.Index] := Codigo;
  tvRoles.DataController.Values[Cnt, colRoleNombre.Index] := Codigo;
  tvRoles.DataController.Values[Cnt, colRoleDescripcion.Index] := '';
  tvRoles.DataController.Values[Cnt, colRoleActivo.Index] := True;

  SetLength(FRoleIds, Cnt + 1);
  FRoleIds[Cnt] := NewId;

  // Enfocar la nova fila per editar directament
  tvRoles.Controller.FocusedRecordIndex := Cnt;
  tvRoles.Controller.FocusedColumn := colRoleNombre;

  LoadPermRoles;
end;

procedure TfrmGestionRoles.btnRoleDelClick(Sender: TObject);
var
  RoleId: Integer;
begin
  RoleId := GetSelectedRoleId;
  if RoleId < 0 then Exit;
  if MessageDlg('¿Eliminar este rol? Se eliminarán también sus permisos asignados.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  ExecSQL('DELETE FROM FS_PL_Role WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) + ' AND RoleId = ' + IntToStr(RoleId));
  LoadRoles;
  LoadPermRoles;
end;

procedure TfrmGestionRoles.btnRoleSaveClick(Sender: TObject);
var
  I, RoleId: Integer;
  Codigo, Nombre, Desc: string;
  Activo: Boolean;
  CE: string;
  V: Variant;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  for I := 0 to tvRoles.DataController.RecordCount - 1 do
  begin
    if I > High(FRoleIds) then Continue;
    RoleId := FRoleIds[I];
    Codigo := VarToStr(tvRoles.DataController.Values[I, colRoleCodigo.Index]);
    Nombre := VarToStr(tvRoles.DataController.Values[I, colRoleNombre.Index]);
    Desc := VarToStr(tvRoles.DataController.Values[I, colRoleDescripcion.Index]);
    V := tvRoles.DataController.Values[I, colRoleActivo.Index];
    Activo := (not VarIsNull(V)) and (not VarIsEmpty(V)) and Boolean(V);

    ExecSQL('UPDATE FS_PL_Role SET ' +
      'Codigo = ' + QStr(Codigo) + ', ' +
      'Nombre = ' + QStr(Nombre) + ', ' +
      'Descripcion = ' + QStr(Desc) + ', ' +
      'Activo = ' + IfThen(Activo, '1', '0') +
      ' WHERE CodigoEmpresa = ' + CE +
      ' AND RoleId = ' + IntToStr(RoleId));
  end;

  ShowMessage('Roles guardados correctamente.');
  LoadPermRoles;
end;

// ════════════════════════════════════════════════════════════════════
//  TAB PERMISOS POR ROL
// ════════════════════════════════════════════════════════════════════

procedure TfrmGestionRoles.LoadPermRoles;
var
  Q: TADOQuery;
  I: Integer;
begin
  tvPermRoles.BeginUpdate;
  try
    tvPermRoles.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT RoleId, Nombre FROM FS_PL_Role ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY RoleId');
    try
      I := 0;
      while not Q.Eof do
      begin
        tvPermRoles.DataController.RecordCount := I + 1;
        tvPermRoles.DataController.Values[I, colPermRolNombre.Index] := Q.FieldByName('Nombre').AsString;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvPermRoles.EndUpdate;
  end;
end;

procedure TfrmGestionRoles.tvPermRolesFocusedRecordChanged(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
var
  Idx, RoleId: Integer;
  Q: TADOQuery;
begin
  if AFocusedRecord = nil then Exit;
  Idx := AFocusedRecord.RecordIndex;
  // Buscar RoleId
  Q := OpenQuery(
    'SELECT RoleId FROM FS_PL_Role ' +
    'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
    ' ORDER BY RoleId OFFSET ' + IntToStr(Idx) + ' ROWS FETCH NEXT 1 ROWS ONLY');
  try
    if not Q.Eof then
    begin
      RoleId := Q.FieldByName('RoleId').AsInteger;
      FSelectedRoleId := RoleId;
      LoadPermisosForRole(RoleId);
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmGestionRoles.LoadPermisosForRole(ARoleId: Integer);
var
  Q: TADOQuery;
  I: Integer;
begin
  tvPermisos.BeginUpdate;
  try
    tvPermisos.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT p.PermissionId, p.Modulo, p.Codigo, p.Nombre, ' +
      '  CASE WHEN rp.PermissionId IS NOT NULL THEN 1 ELSE 0 END AS Asignado ' +
      'FROM FS_PL_Permission p ' +
      'LEFT JOIN FS_PL_RolePermission rp ON rp.CodigoEmpresa = p.CodigoEmpresa ' +
      '  AND rp.PermissionId = p.PermissionId AND rp.RoleId = ' + IntToStr(ARoleId) + ' ' +
      'WHERE p.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY p.Modulo, p.Codigo');
    try
      SetLength(FPermIds, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        tvPermisos.DataController.RecordCount := I + 1;
        tvPermisos.DataController.Values[I, colPermModulo.Index] := Q.FieldByName('Modulo').AsString;
        tvPermisos.DataController.Values[I, colPermCodigo.Index] := Q.FieldByName('Codigo').AsString;
        tvPermisos.DataController.Values[I, colPermNombre.Index] := Q.FieldByName('Nombre').AsString;
        tvPermisos.DataController.Values[I, colPermAsignado.Index] := (Q.FieldByName('Asignado').AsInteger = 1);
        FPermIds[I] := Q.FieldByName('PermissionId').AsInteger;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvPermisos.EndUpdate;
  end;
end;

procedure TfrmGestionRoles.btnPermSaveClick(Sender: TObject);
var
  I: Integer;
  Checked: Boolean;
  CE: string;
  V: Variant;
begin
  if FSelectedRoleId < 0 then Exit;
  CE := IntToStr(DMPlanner.CodigoEmpresa);

  // Borrar asignaciones actuales del rol
  ExecSQL('DELETE FROM FS_PL_RolePermission WHERE CodigoEmpresa = ' + CE +
    ' AND RoleId = ' + IntToStr(FSelectedRoleId));

  // Insertar las marcadas
  for I := 0 to tvPermisos.DataController.RecordCount - 1 do
  begin
    V := tvPermisos.DataController.Values[I, colPermAsignado.Index];
    Checked := (not VarIsNull(V)) and (not VarIsEmpty(V)) and Boolean(V);
    if Checked then
      ExecSQL('INSERT INTO FS_PL_RolePermission (CodigoEmpresa, RoleId, PermissionId) VALUES (' +
        CE + ', ' + IntToStr(FSelectedRoleId) + ', ' + IntToStr(FPermIds[I]) + ')');
  end;

  ShowMessage('Permisos guardados correctamente.');
end;

end.
