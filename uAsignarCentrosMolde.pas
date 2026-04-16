unit uAsignarCentrosMolde;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst,
  Data.Win.ADODB, Data.DB;

type
  TfrmAsignarCentrosMolde = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    clbItems: TCheckListBox;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    FMoldId: Integer;
    FMoldCodigo: string;
    FCenterIds: TArray<Integer>;
    procedure LoadCentros;
    procedure Guardar;
  public
    class function Execute(AMoldId: Integer; const AMoldCodigo: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

class function TfrmAsignarCentrosMolde.Execute(AMoldId: Integer;
  const AMoldCodigo: string): Boolean;
var
  F: TfrmAsignarCentrosMolde;
begin
  F := TfrmAsignarCentrosMolde.Create(Application);
  try
    F.FMoldId := AMoldId;
    F.FMoldCodigo := AMoldCodigo;
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmAsignarCentrosMolde.FormCreate(Sender: TObject);
begin
  lblSubtitle.Caption := 'Molde: ' + FMoldCodigo;
  LoadCentros;
end;

procedure TfrmAsignarCentrosMolde.LoadCentros;
var
  Q: TADOQuery;
  I: Integer;
begin
  clbItems.Items.Clear;
  SetLength(FCenterIds, 0);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT c.CenterId, c.Titulo, ' +
      '  CASE WHEN mc.MoldId IS NOT NULL THEN 1 ELSE 0 END AS Asignado ' +
      'FROM FS_PL_Center c ' +
      'LEFT JOIN FS_PL_MoldCenter mc ON mc.CodigoEmpresa = c.CodigoEmpresa ' +
      '  AND mc.CenterId = c.CenterId AND mc.MoldId = :MoldId ' +
      'WHERE c.CodigoEmpresa = :CodigoEmpresa ' +
      'ORDER BY c.Titulo';
    Q.Parameters.ParamByName('MoldId').Value := FMoldId;
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      I := clbItems.Items.Add(Q.FieldByName('Titulo').AsString);
      SetLength(FCenterIds, Length(FCenterIds) + 1);
      FCenterIds[High(FCenterIds)] := Q.FieldByName('CenterId').AsInteger;
      clbItems.Checked[I] := Q.FieldByName('Asignado').AsInteger = 1;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmAsignarCentrosMolde.Guardar;
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
      Cmd.CommandText := 'DELETE FROM FS_PL_MoldCenter WHERE CodigoEmpresa = ' +
        CE + ' AND MoldId = ' + IntToStr(FMoldId);
      Cmd.Execute;
      for J := 0 to clbItems.Items.Count - 1 do
        if clbItems.Checked[J] then
        begin
          Cmd.CommandText := 'INSERT INTO FS_PL_MoldCenter (CodigoEmpresa, MoldId, CenterId) VALUES (' +
            CE + ', ' + IntToStr(FMoldId) + ', ' + IntToStr(FCenterIds[J]) + ')';
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

procedure TfrmAsignarCentrosMolde.btnOKClick(Sender: TObject);
begin
  try
    Guardar;
    ModalResult := mrOk;
  except
    on E: Exception do
    begin
      ShowMessage('Error: ' + E.Message);
      ModalResult := mrNone;
    end;
  end;
end;

end.
