unit uMaquinasCustomCols;

// ============================================================================
// CRUD de definiciones de columnas custom del grid Maquinas.
// Tabla destino: FS_PL_Cfg_GridColumns (GridId='MAQUINAS', IsCustomField=1).
// Eliminar = soft delete (Activo=0).
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Dialogs,
  Data.Win.ADODB, Data.DB,
  uMaquinasCustomColEdit;

type
  TfrmMaquinasCustomCols = class(TForm)
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
    FRows: TList<TMaquinasCustomColData>;
    function EmpresaCode: SmallInt;
    function QStr(const S: string): string;
    procedure LoadRows;
    procedure RefreshList;
    function SelectedIndex: Integer;
    procedure InsertRow(const Data: TMaquinasCustomColData);
    procedure UpdateRow(const Data: TMaquinasCustomColData);
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
  MAQUINAS_GRID_ID = 'MAQUINAS';

class function TfrmMaquinasCustomCols.Execute: Boolean;
var
  F: TfrmMaquinasCustomCols;
begin
  F := TfrmMaquinasCustomCols.Create(Application);
  try
    F.ShowModal;
    Result := F.FChanged;
  finally
    F.Free;
  end;
end;

function TfrmMaquinasCustomCols.EmpresaCode: SmallInt;
begin
  Result := DMPlanner.CodigoEmpresa;
end;

function TfrmMaquinasCustomCols.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmMaquinasCustomCols.DataTypeLabel(D: Char): string;
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

procedure TfrmMaquinasCustomCols.FormShow(Sender: TObject);
begin
  FRows := TList<TMaquinasCustomColData>.Create;
  LoadRows;
  RefreshList;
end;

procedure TfrmMaquinasCustomCols.LoadRows;
var
  Q: TADOQuery;
  Row: TMaquinasCustomColData;
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
      '  AND GridId = ''' + MAQUINAS_GRID_ID + '''' +
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

procedure TfrmMaquinasCustomCols.RefreshList;
var
  I: Integer;
  Item: TListItem;
  Row: TMaquinasCustomColData;
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

function TfrmMaquinasCustomCols.SelectedIndex: Integer;
begin
  if lvCols.Selected = nil then
    Result := -1
  else
    Result := lvCols.Selected.Index;
end;

function TfrmMaquinasCustomCols.ExistsColumnKey(const Key: string): Boolean;
var
  Q: TADOQuery;
begin
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT 1 FROM FS_PL_Cfg_GridColumns ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + MAQUINAS_GRID_ID + '''' +
      '  AND ColumnKey = ' + QStr(Key);
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

procedure TfrmMaquinasCustomCols.InsertRow(const Data: TMaquinasCustomColData);
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
      '''' + MAQUINAS_GRID_ID + ''', ' +
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

procedure TfrmMaquinasCustomCols.UpdateRow(const Data: TMaquinasCustomColData);
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
      '  AND GridId = ''' + MAQUINAS_GRID_ID + '''' +
      '  AND ColumnKey = ' + QStr(Data.ColumnKey);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmMaquinasCustomCols.DeactivateRow(const ColumnKey: string);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_Cfg_GridColumns SET Activo = 0 ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + MAQUINAS_GRID_ID + '''' +
      '  AND ColumnKey = ' + QStr(ColumnKey);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmMaquinasCustomCols.btnNuevaClick(Sender: TObject);
var
  Data: TMaquinasCustomColData;
begin
  Data := Default(TMaquinasCustomColData);
  Data.DataType := 'S';
  Data.OrderDefault := 0;
  Data.WidthDefault := 120;

  if not TfrmMaquinasCustomColEdit.Execute(Data, True) then Exit;

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

procedure TfrmMaquinasCustomCols.btnEditarClick(Sender: TObject);
var
  Idx: Integer;
  Data: TMaquinasCustomColData;
begin
  Idx := SelectedIndex;
  if Idx < 0 then
  begin
    ShowMessage('Selecciona una columna.');
    Exit;
  end;
  Data := FRows[Idx];
  if not TfrmMaquinasCustomColEdit.Execute(Data, False) then Exit;

  UpdateRow(Data);
  FChanged := True;
  LoadRows;
  RefreshList;
end;

procedure TfrmMaquinasCustomCols.lvColsDblClick(Sender: TObject);
begin
  btnEditarClick(Sender);
end;

procedure TfrmMaquinasCustomCols.btnEliminarClick(Sender: TObject);
var
  Idx: Integer;
  Row: TMaquinasCustomColData;
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
       'Los valores guardados en FS_PL_Maquina_Extra se conservan; ' +
       'si vuelves a crear una columna con el mismo codigo, los recuperaras.',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  DeactivateRow(Row.ColumnKey);
  FChanged := True;
  LoadRows;
  RefreshList;
end;

end.
