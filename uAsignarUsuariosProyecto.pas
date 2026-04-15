unit uAsignarUsuariosProyecto;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxCheckBox,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB;

type
  TfrmAsignarUsuariosProyecto = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnAceptar: TButton;
    btnCancelar: TButton;
    gridUsers: TcxGrid;
    tvUsers: TcxGridTableView;
    colAsignado: TcxGridColumn;
    colUserLogin: TcxGridColumn;
    colUserNombre: TcxGridColumn;
    colUserRol: TcxGridColumn;
    lvUsers: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
  private
    FProjectId: Integer;
    FProjectName: string;
    FUserIds: TArray<Integer>;
    procedure LoadUsers;
    procedure GuardarAsignaciones;
    function ExecSQL(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
  public
    procedure SetProject(AProjectId: Integer; const AProjectName: string);
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

procedure TfrmAsignarUsuariosProyecto.SetProject(AProjectId: Integer;
  const AProjectName: string);
begin
  FProjectId := AProjectId;
  FProjectName := AProjectName;
  if lblSubtitle <> nil then
    lblSubtitle.Caption := 'Proyecto: ' + AProjectName;
end;

function TfrmAsignarUsuariosProyecto.ExecSQL(const ASQL: string): Integer;
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

function TfrmAsignarUsuariosProyecto.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

procedure TfrmAsignarUsuariosProyecto.FormCreate(Sender: TObject);
begin
  FProjectId := -1;
  if FProjectName <> '' then
    lblSubtitle.Caption := 'Proyecto: ' + FProjectName;
  LoadUsers;
end;

procedure TfrmAsignarUsuariosProyecto.LoadUsers;
var
  Q: TADOQuery;
  I: Integer;
  CE, PID: string;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(FProjectId);

  tvUsers.BeginUpdate;
  try
    tvUsers.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT u.UserId, u.Login, u.NombreCompleto, r.Nombre AS RolNombre, ' +
      '  CASE WHEN pu.UserId IS NOT NULL THEN 1 ELSE 0 END AS Asignado ' +
      'FROM FS_PL_User u ' +
      'INNER JOIN FS_PL_Role r ON r.CodigoEmpresa = u.CodigoEmpresa AND r.RoleId = u.RoleId ' +
      'LEFT JOIN FS_PL_ProjectUser pu ON pu.CodigoEmpresa = u.CodigoEmpresa ' +
      '  AND pu.UserId = u.UserId AND pu.ProjectId = ' + PID + ' ' +
      'WHERE u.CodigoEmpresa = ' + CE + ' AND u.Activo = 1 ' +
      'ORDER BY u.Login');
    try
      SetLength(FUserIds, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        tvUsers.DataController.RecordCount := I + 1;
        tvUsers.DataController.Values[I, colAsignado.Index] :=
          Q.FieldByName('Asignado').AsInteger = 1;
        tvUsers.DataController.Values[I, colUserLogin.Index] :=
          Q.FieldByName('Login').AsString;
        tvUsers.DataController.Values[I, colUserNombre.Index] :=
          Q.FieldByName('NombreCompleto').AsString;
        tvUsers.DataController.Values[I, colUserRol.Index] :=
          Q.FieldByName('RolNombre').AsString;
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

procedure TfrmAsignarUsuariosProyecto.GuardarAsignaciones;
var
  I, UserId: Integer;
  V: Variant;
  Asignado: Boolean;
  CE, PID: string;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(FProjectId);

  DMPlanner.ADOConnection.BeginTrans;
  try
    ExecSQL('DELETE FROM FS_PL_ProjectUser WHERE CodigoEmpresa = ' + CE +
      ' AND ProjectId = ' + PID);

    for I := 0 to tvUsers.DataController.RecordCount - 1 do
    begin
      if I > High(FUserIds) then Continue;
      V := tvUsers.DataController.Values[I, colAsignado.Index];
      Asignado := (not VarIsNull(V)) and (not VarIsEmpty(V)) and Boolean(V);
      if not Asignado then Continue;

      UserId := FUserIds[I];
      ExecSQL('INSERT INTO FS_PL_ProjectUser (CodigoEmpresa, ProjectId, UserId) VALUES (' +
        CE + ', ' + PID + ', ' + IntToStr(UserId) + ')');
    end;

    DMPlanner.ADOConnection.CommitTrans;
  except
    DMPlanner.ADOConnection.RollbackTrans;
    raise;
  end;
end;

procedure TfrmAsignarUsuariosProyecto.btnAceptarClick(Sender: TObject);
begin
  if FProjectId < 0 then
  begin
    ShowMessage('Proyecto no válido.');
    ModalResult := mrNone;
    Exit;
  end;
  GuardarAsignaciones;
  ShowMessage('Asignaciones guardadas.');
end;

end.
