unit uBacklogCustomCols;

// ============================================================================
// CRUD de definiciones de columnas custom del grid Backlog.
// Tabla destino: FS_PL_Cfg_GridColumns (GridId='BACKLOG', IsCustomField=1).
//
// Eliminar = soft delete (Activo=0). Asi no se pierden los valores ya
// guardados en las taules FS_PL_Raw_*_Extra para esa columna.
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Dialogs,
  Data.Win.ADODB, Data.DB,
  uBacklogCustomColEdit;

type
  TfrmBacklogCustomCols = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnNueva: TButton;
    btnEditar: TButton;
    btnEliminar: TButton;
    btnCerrar: TButton;
    lvCols: TListView;
    procedure FormShow(Sender: TObject);
    procedure btnNuevaClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure lvColsDblClick(Sender: TObject);
  private
    FChanged: Boolean;
    FRows: TList<TBacklogCustomColData>;
    function EmpresaCode: SmallInt;
    function QStr(const S: string): string;
    procedure LoadRows;
    procedure RefreshList;
    function SelectedIndex: Integer;
    procedure InsertRow(const Data: TBacklogCustomColData);
    procedure UpdateRow(const Data: TBacklogCustomColData);
    procedure DeactivateRow(const ColumnKey: string);
    function ExistsColumnKey(const Key: string): Boolean;
    function DataTypeLabel(D: Char): string;
  public
    class function Execute: Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

const
  BACKLOG_GRID_ID = 'BACKLOG';

class function TfrmBacklogCustomCols.Execute: Boolean;
var
  F: TfrmBacklogCustomCols;
begin
  F := TfrmBacklogCustomCols.Create(Application);
  try
    F.ShowModal;
    Result := F.FChanged;
  finally
    F.Free;
  end;
end;

function TfrmBacklogCustomCols.EmpresaCode: SmallInt;
begin
  Result := DMPlanner.CodigoEmpresa;
end;

function TfrmBacklogCustomCols.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmBacklogCustomCols.DataTypeLabel(D: Char): string;
begin
  case UpCase(D) of
    'S': Result := 'Texto';
    'N': Result := 'Numerico';
    'D': Result := 'Fecha';
    'B': Result := 'Booleano';
  else
    Result := D;
  end;
end;

procedure TfrmBacklogCustomCols.FormShow(Sender: TObject);
begin
  FRows := TList<TBacklogCustomColData>.Create;
  LoadRows;
  RefreshList;
end;

procedure TfrmBacklogCustomCols.LoadRows;
var
  Q: TADOQuery;
  Row: TBacklogCustomColData;
  DT: string;
begin
  FRows.Clear;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ColumnKey, Caption, DataType, SourceEntity, ' +
      '       AppliesToNivel, OrderDefault, WidthDefault ' +
      'FROM FS_PL_Cfg_GridColumns ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + BACKLOG_GRID_ID + '''' +
      '  AND IsCustomField = 1 AND Activo = 1 ' +
      'ORDER BY OrderDefault, ColumnKey';
    Q.Open;
    while not Q.Eof do
    begin
      Row.ColumnKey    := Q.FieldByName('ColumnKey').AsString;
      Row.Caption      := Q.FieldByName('Caption').AsString;
      DT := Q.FieldByName('DataType').AsString;
      if DT = '' then Row.DataType := 'S' else Row.DataType := DT[1];
      Row.SourceEntity := Q.FieldByName('SourceEntity').AsString;
      if Q.FieldByName('AppliesToNivel').IsNull then
        Row.AppliesToNivel := 1
      else
        Row.AppliesToNivel := Q.FieldByName('AppliesToNivel').AsInteger;
      Row.OrderDefault := Q.FieldByName('OrderDefault').AsInteger;
      Row.WidthDefault := Q.FieldByName('WidthDefault').AsInteger;
      FRows.Add(Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmBacklogCustomCols.RefreshList;
var
  I: Integer;
  Item: TListItem;
  Row: TBacklogCustomColData;
begin
  lvCols.Items.BeginUpdate;
  try
    lvCols.Items.Clear;
    for I := 0 to FRows.Count - 1 do
    begin
      Row := FRows[I];
      Item := lvCols.Items.Add;
      Item.Caption := Row.ColumnKey;
      Item.SubItems.Add(Row.Caption);
      Item.SubItems.Add(DataTypeLabel(Row.DataType));
      Item.SubItems.Add(Row.SourceEntity);
      Item.SubItems.Add(IntToStr(Row.OrderDefault));
      Item.SubItems.Add(IntToStr(Row.WidthDefault));
    end;
  finally
    lvCols.Items.EndUpdate;
  end;
end;

function TfrmBacklogCustomCols.SelectedIndex: Integer;
begin
  if lvCols.Selected = nil then
    Result := -1
  else
    Result := lvCols.Selected.Index;
end;

function TfrmBacklogCustomCols.ExistsColumnKey(const Key: string): Boolean;
var
  Q: TADOQuery;
begin
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT 1 FROM FS_PL_Cfg_GridColumns ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + BACKLOG_GRID_ID + '''' +
      '  AND ColumnKey = ' + QStr(Key);
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

procedure TfrmBacklogCustomCols.InsertRow(const Data: TBacklogCustomColData);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_Cfg_GridColumns ' +
      '  (CodigoEmpresa, GridId, ColumnKey, Caption, DataType, ' +
      '   VisibleDefault, OrderDefault, WidthDefault, IsCustomField, ' +
      '   SourceEntity, AppliesToNivel, Activo) VALUES (' +
      IntToStr(EmpresaCode) + ', ' +
      '''' + BACKLOG_GRID_ID + ''', ' +
      QStr(Data.ColumnKey) + ', ' +
      QStr(Data.Caption) + ', ' +
      '''' + Data.DataType + ''', ' +
      '1, ' +
      IntToStr(Data.OrderDefault) + ', ' +
      IntToStr(Data.WidthDefault) + ', ' +
      '1, ' +
      QStr(Data.SourceEntity) + ', ' +
      IntToStr(Data.AppliesToNivel) + ', ' +
      '1)';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmBacklogCustomCols.UpdateRow(const Data: TBacklogCustomColData);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_Cfg_GridColumns SET ' +
      '  Caption = ' + QStr(Data.Caption) + ', ' +
      '  DataType = ''' + Data.DataType + ''', ' +
      '  SourceEntity = ' + QStr(Data.SourceEntity) + ', ' +
      '  AppliesToNivel = ' + IntToStr(Data.AppliesToNivel) + ', ' +
      '  OrderDefault = ' + IntToStr(Data.OrderDefault) + ', ' +
      '  WidthDefault = ' + IntToStr(Data.WidthDefault) + ', ' +
      '  Activo = 1 ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + BACKLOG_GRID_ID + '''' +
      '  AND ColumnKey = ' + QStr(Data.ColumnKey);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmBacklogCustomCols.DeactivateRow(const ColumnKey: string);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_Cfg_GridColumns SET Activo = 0 ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + BACKLOG_GRID_ID + '''' +
      '  AND ColumnKey = ' + QStr(ColumnKey);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmBacklogCustomCols.btnNuevaClick(Sender: TObject);
var
  Data: TBacklogCustomColData;
begin
  Data := Default(TBacklogCustomColData);
  Data.DataType := 'S';
  Data.SourceEntity := 'OF';
  Data.AppliesToNivel := 1;
  Data.OrderDefault := 0;
  Data.WidthDefault := 120;

  if not TfrmBacklogCustomColEdit.Execute(Data, True) then Exit;

  // Si ya existia con Activo=0, lo reactivamos en lugar de duplicar.
  if ExistsColumnKey(Data.ColumnKey) then
  begin
    if MessageDlg(
         'Ya existe una columna con codigo "' + Data.ColumnKey + '" ' +
         '(quiza desactivada). Quieres reutilizarla con los nuevos valores?',
         mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    UpdateRow(Data);
  end
  else
    InsertRow(Data);

  FChanged := True;
  LoadRows;
  RefreshList;
end;

procedure TfrmBacklogCustomCols.btnEditarClick(Sender: TObject);
var
  Idx: Integer;
  Data: TBacklogCustomColData;
begin
  Idx := SelectedIndex;
  if Idx < 0 then
  begin
    ShowMessage('Selecciona una columna.');
    Exit;
  end;
  Data := FRows[Idx];
  if not TfrmBacklogCustomColEdit.Execute(Data, False) then Exit;

  UpdateRow(Data);
  FChanged := True;
  LoadRows;
  RefreshList;
end;

procedure TfrmBacklogCustomCols.lvColsDblClick(Sender: TObject);
begin
  btnEditarClick(Sender);
end;

procedure TfrmBacklogCustomCols.btnEliminarClick(Sender: TObject);
var
  Idx: Integer;
  Row: TBacklogCustomColData;
begin
  Idx := SelectedIndex;
  if Idx < 0 then
  begin
    ShowMessage('Selecciona una columna.');
    Exit;
  end;
  Row := FRows[Idx];
  if MessageDlg(
       'Desactivar la columna "' + Row.ColumnKey + '"?' + sLineBreak + sLineBreak +
       'Los valores guardados en las taules _Extra se conservan; ' +
       'si vuelves a crear una columna con el mismo codigo, los recuperaras.',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  DeactivateRow(Row.ColumnKey);
  FChanged := True;
  LoadRows;
  RefreshList;
end;

end.
