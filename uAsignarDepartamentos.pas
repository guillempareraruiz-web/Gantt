unit uAsignarDepartamentos;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst,
  Data.Win.ADODB, Data.DB;

type
  TfrmAsignarDepartamentos = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    clbDepts: TCheckListBox;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    FOperatorId: Integer;
    FOperatorName: string;
    FDeptIds: TArray<Integer>;
    procedure LoadDepts;
    procedure GuardarAsignaciones;
  public
    class function Execute(AOperatorId: Integer; const AOperatorName: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

class function TfrmAsignarDepartamentos.Execute(AOperatorId: Integer;
  const AOperatorName: string): Boolean;
var
  F: TfrmAsignarDepartamentos;
begin
  F := TfrmAsignarDepartamentos.Create(Application);
  try
    F.FOperatorId := AOperatorId;
    F.FOperatorName := AOperatorName;
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmAsignarDepartamentos.FormCreate(Sender: TObject);
begin
  lblSubtitle.Caption := FOperatorName;
  LoadDepts;
end;

procedure TfrmAsignarDepartamentos.LoadDepts;
var
  Q: TADOQuery;
  I: Integer;
begin
  clbDepts.Items.Clear;
  SetLength(FDeptIds, 0);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT d.DepartmentId, d.Nombre, ' +
      '  CASE WHEN od.OperatorId IS NOT NULL THEN 1 ELSE 0 END AS Asignado ' +
      'FROM FS_PL_Department d ' +
      'LEFT JOIN FS_PL_OperatorDepartment od ON od.CodigoEmpresa = d.CodigoEmpresa ' +
      '  AND od.DepartmentId = d.DepartmentId ' +
      '  AND od.OperatorId = :OperatorId ' +
      'WHERE d.CodigoEmpresa = :CodigoEmpresa ' +
      'ORDER BY d.Nombre';
    Q.Parameters.ParamByName('OperatorId').Value := FOperatorId;
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      I := clbDepts.Items.Add(Q.FieldByName('Nombre').AsString);
      SetLength(FDeptIds, Length(FDeptIds) + 1);
      FDeptIds[High(FDeptIds)] := Q.FieldByName('DepartmentId').AsInteger;
      clbDepts.Checked[I] := Q.FieldByName('Asignado').AsInteger = 1;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmAsignarDepartamentos.GuardarAsignaciones;
var
  Cmd: TADOCommand;
  J: Integer;
  CE: string;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    DMPlanner.ADOConnection.BeginTrans;
    try
      Cmd.CommandText := 'DELETE FROM FS_PL_OperatorDepartment WHERE CodigoEmpresa = ' +
        CE + ' AND OperatorId = ' + IntToStr(FOperatorId);
      Cmd.Execute;
      for J := 0 to clbDepts.Items.Count - 1 do
        if clbDepts.Checked[J] then
        begin
          Cmd.CommandText := 'INSERT INTO FS_PL_OperatorDepartment (CodigoEmpresa, OperatorId, DepartmentId) VALUES (' +
            CE + ', ' + IntToStr(FOperatorId) + ', ' + IntToStr(FDeptIds[J]) + ')';
          Cmd.Execute;
        end;
      DMPlanner.ADOConnection.CommitTrans;
    except
      DMPlanner.ADOConnection.RollbackTrans;
      raise;
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmAsignarDepartamentos.btnOKClick(Sender: TObject);
begin
  try
    GuardarAsignaciones;
    ModalResult := mrOk;
  except
    on E: Exception do
    begin
      ShowMessage('Error guardando asignaciones: ' + E.Message);
      ModalResult := mrNone;
    end;
  end;
end;

end.
