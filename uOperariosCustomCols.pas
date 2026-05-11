unit uOperariosCustomCols;

// ============================================================================
// CRUD de definiciones de columnas custom del grid Operarios.
// Tabla destino: FS_PL_Cfg_GridColumns (GridId='OPERARIOS', IsCustomField=1).
// Eliminar = soft delete (Activo=0).
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Dialogs,
  Data.Win.ADODB, Data.DB,
  uOperariosCustomColEdit;

type
  TfrmOperariosCustomCols = class(TForm)
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
    FRows: TList<TOperariosCustomColData>;
    function EmpresaCode: SmallInt;
    function QStr(const S: string): string;
    procedure LoadRows;
    procedure RefreshList;
    function SelectedIndex: Integer;
    procedure InsertRow(const Data: TOperariosCustomColData);
    procedure UpdateRow(const Data: TOperariosCustomColData);
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
  OPERARIOS_GRID_ID = 'OPERARIOS';

class function TfrmOperariosCustomCols.Execute: Boolean;
var
  F: TfrmOperariosCustomCols;
begin
  F := TfrmOperariosCustomCols.Create(Application);
  try
    F.ShowModal;
    Result := F.FChanged;
  finally
    F.Free;
  end;
end;

function TfrmOperariosCustomCols.EmpresaCode: SmallInt;
begin
  Result := DMPlanner.CodigoEmpresa;
end;

function TfrmOperariosCustomCols.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmOperariosCustomCols.DataTypeLabel(D: Char): string;
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

procedure TfrmOperariosCustomCols.FormShow(Sender: TObject);
begin
  FRows := TList<TOperariosCustomColData>.Create;
  LoadRows;
  RefreshList;
end;

procedure TfrmOperariosCustomCols.LoadRows;
var
  Q: TADOQuery;
  Row: TOperariosCustomColData;
  DT: string;
begin
  FRows.Clear;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ColumnKey, Caption, DataType, OrderDefault, WidthDefault ' +
      'FROM FS_PL_Cfg_GridColumns ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + OPERARIOS_GRID_ID + '''' +
      '  AND IsCustomField = 1 AND Activo = 1 ' +
      'ORDER BY OrderDefault, ColumnKey';
    Q.Open;
    while not Q.Eof do
    begin
      Row.ColumnKey := Q.FieldByName('ColumnKey').AsString;
      Row.Caption   := Q.FieldByName('Caption').AsString;
      DT := Q.FieldByName('DataType').AsString;
      if DT = '' then Row.DataType := 'S' else Row.DataType := DT[1];
      Row.OrderDefault := Q.FieldByName('OrderDefault').AsInteger;
      Row.WidthDefault := Q.FieldByName('WidthDefault').AsInteger;
      FRows.Add(Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmOperariosCustomCols.RefreshList;
var
  I: Integer;
  Item: TListItem;
  Row: TOperariosCustomColData;
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
      Item.SubItems.Add(IntToStr(Row.OrderDefault));
      Item.SubItems.Add(IntToStr(Row.WidthDefault));
    end;
  finally
    lvCols.Items.EndUpdate;
  end;
end;

function TfrmOperariosCustomCols.SelectedIndex: Integer;
begin
  if lvCols.Selected = nil then
    Result := -1
  else
    Result := lvCols.Selected.Index;
end;

function TfrmOperariosCustomCols.ExistsColumnKey(const Key: string): Boolean;
var
  Q: TADOQuery;
begin
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT 1 FROM FS_PL_Cfg_GridColumns ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + OPERARIOS_GRID_ID + '''' +
      '  AND ColumnKey = ' + QStr(Key);
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

procedure TfrmOperariosCustomCols.InsertRow(const Data: TOperariosCustomColData);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_Cfg_GridColumns ' +
      '  (CodigoEmpresa, GridId, ColumnKey, Caption, DataType, ' +
      '   VisibleDefault, OrderDefault, WidthDefault, IsCustomField, Activo) VALUES (' +
      IntToStr(EmpresaCode) + ', ' +
      '''' + OPERARIOS_GRID_ID + ''', ' +
      QStr(Data.ColumnKey) + ', ' +
      QStr(Data.Caption) + ', ' +
      '''' + Data.DataType + ''', ' +
      '1, ' +
      IntToStr(Data.OrderDefault) + ', ' +
      IntToStr(Data.WidthDefault) + ', ' +
      '1, 1)';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmOperariosCustomCols.UpdateRow(const Data: TOperariosCustomColData);
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
      '  OrderDefault = ' + IntToStr(Data.OrderDefault) + ', ' +
      '  WidthDefault = ' + IntToStr(Data.WidthDefault) + ', ' +
      '  Activo = 1 ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + OPERARIOS_GRID_ID + '''' +
      '  AND ColumnKey = ' + QStr(Data.ColumnKey);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmOperariosCustomCols.DeactivateRow(const ColumnKey: string);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_Cfg_GridColumns SET Activo = 0 ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + OPERARIOS_GRID_ID + '''' +
      '  AND ColumnKey = ' + QStr(ColumnKey);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmOperariosCustomCols.btnNuevaClick(Sender: TObject);
var
  Data: TOperariosCustomColData;
begin
  Data := Default(TOperariosCustomColData);
  Data.DataType := 'S';
  Data.OrderDefault := 0;
  Data.WidthDefault := 120;

  if not TfrmOperariosCustomColEdit.Execute(Data, True) then Exit;

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

procedure TfrmOperariosCustomCols.btnEditarClick(Sender: TObject);
var
  Idx: Integer;
  Data: TOperariosCustomColData;
begin
  Idx := SelectedIndex;
  if Idx < 0 then
  begin
    ShowMessage('Selecciona una columna.');
    Exit;
  end;
  Data := FRows[Idx];
  if not TfrmOperariosCustomColEdit.Execute(Data, False) then Exit;

  UpdateRow(Data);
  FChanged := True;
  LoadRows;
  RefreshList;
end;

procedure TfrmOperariosCustomCols.lvColsDblClick(Sender: TObject);
begin
  btnEditarClick(Sender);
end;

procedure TfrmOperariosCustomCols.btnEliminarClick(Sender: TObject);
var
  Idx: Integer;
  Row: TOperariosCustomColData;
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
       'Los valores guardados en FS_PL_Operario_Extra se conservan; ' +
       'si vuelves a crear una columna con el mismo codigo, los recuperaras.',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  DeactivateRow(Row.ColumnKey);
  FChanged := True;
  LoadRows;
  RefreshList;
end;

end.
