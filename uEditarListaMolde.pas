unit uEditarListaMolde;

// Diálogo genérico para editar una lista de strings asociada a un molde.
// Usado para FS_PL_MoldArticle (artículos) y FS_PL_MoldOperation (operaciones).

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Data.Win.ADODB, Data.DB;

type
  TEditarListaMoldeKind = (elkArticulos, elkOperaciones);

  TfrmEditarListaMolde = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    pnlToolbar: TPanel;
    edtNuevo: TEdit;
    btnAdd: TButton;
    btnDel: TButton;
    lbItems: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    FMoldId: Integer;
    FMoldCodigo: string;
    FKind: TEditarListaMoldeKind;
    procedure LoadItems;
    procedure Guardar;
    function TableName: string;
    function ColumnName: string;
  public
    class function Execute(AMoldId: Integer; const AMoldCodigo: string;
      AKind: TEditarListaMoldeKind): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

class function TfrmEditarListaMolde.Execute(AMoldId: Integer;
  const AMoldCodigo: string; AKind: TEditarListaMoldeKind): Boolean;
var
  F: TfrmEditarListaMolde;
begin
  F := TfrmEditarListaMolde.Create(Application);
  try
    F.FMoldId := AMoldId;
    F.FMoldCodigo := AMoldCodigo;
    F.FKind := AKind;
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

function TfrmEditarListaMolde.TableName: string;
begin
  case FKind of
    elkArticulos:   Result := 'FS_PL_MoldArticle';
    elkOperaciones: Result := 'FS_PL_MoldOperation';
  end;
end;

function TfrmEditarListaMolde.ColumnName: string;
begin
  case FKind of
    elkArticulos:   Result := 'CodigoArticulo';
    elkOperaciones: Result := 'Operacion';
  end;
end;

procedure TfrmEditarListaMolde.FormCreate(Sender: TObject);
begin
  case FKind of
    elkArticulos:
      begin
        Caption := 'Artículos del molde';
        lblTitle.Caption := 'Artículos fabricables con este molde';
      end;
    elkOperaciones:
      begin
        Caption := 'Operaciones del molde';
        lblTitle.Caption := 'Operaciones compatibles con este molde';
      end;
  end;
  lblSubtitle.Caption := 'Molde: ' + FMoldCodigo;
  LoadItems;
end;

procedure TfrmEditarListaMolde.LoadItems;
var
  Q: TADOQuery;
begin
  lbItems.Items.Clear;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ' + ColumnName + ' FROM ' + TableName +
      ' WHERE CodigoEmpresa = :CodigoEmpresa AND MoldId = :MoldId ' +
      'ORDER BY ' + ColumnName;
    Q.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('MoldId').Value := FMoldId;
    Q.Open;
    while not Q.Eof do
    begin
      lbItems.Items.Add(Q.FieldByName(ColumnName).AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmEditarListaMolde.btnAddClick(Sender: TObject);
var
  S: string;
begin
  S := Trim(edtNuevo.Text);
  if S = '' then Exit;
  if lbItems.Items.IndexOf(S) >= 0 then
  begin
    ShowMessage('Ya está en la lista.');
    Exit;
  end;
  lbItems.Items.Add(S);
  edtNuevo.Text := '';
  edtNuevo.SetFocus;
end;

procedure TfrmEditarListaMolde.btnDelClick(Sender: TObject);
begin
  if lbItems.ItemIndex < 0 then Exit;
  lbItems.Items.Delete(lbItems.ItemIndex);
end;

procedure TfrmEditarListaMolde.Guardar;
var
  Cmd: TADOCommand;
  J: Integer;
  CE: string;

  function QStr(const S: string): string;
  begin
    Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
  end;

begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    DMPlanner.ADOConnection.BeginTrans;
    try
      Cmd.CommandText := 'DELETE FROM ' + TableName + ' WHERE CodigoEmpresa = ' +
        CE + ' AND MoldId = ' + IntToStr(FMoldId);
      Cmd.Execute;
      for J := 0 to lbItems.Items.Count - 1 do
      begin
        Cmd.CommandText := 'INSERT INTO ' + TableName + ' (CodigoEmpresa, MoldId, ' +
          ColumnName + ') VALUES (' + CE + ', ' + IntToStr(FMoldId) + ', ' +
          QStr(lbItems.Items[J]) + ')';
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

procedure TfrmEditarListaMolde.btnOKClick(Sender: TObject);
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
