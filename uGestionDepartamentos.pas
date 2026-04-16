unit uGestionDepartamentos;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB;

type
  TfrmGestionDepartamentos = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnDel: TButton;
    btnSave: TButton;
    gridDepts: TcxGrid;
    tvDepts: TcxGridTableView;
    colDeptId: TcxGridColumn;
    colDeptNombre: TcxGridColumn;
    colDeptDescripcion: TcxGridColumn;
    lvDepts: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    FIds: TArray<Integer>;
    procedure LoadDepts;
    function GetSelectedIdx: Integer;
    function Exec(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

function TfrmGestionDepartamentos.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmGestionDepartamentos.Exec(const ASQL: string): Integer;
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

function TfrmGestionDepartamentos.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

procedure TfrmGestionDepartamentos.FormCreate(Sender: TObject);
begin
  LoadDepts;
end;

procedure TfrmGestionDepartamentos.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmGestionDepartamentos.LoadDepts;
var
  Q: TADOQuery;
  I: Integer;
begin
  tvDepts.BeginUpdate;
  try
    tvDepts.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT DepartmentId, Nombre, Descripcion FROM FS_PL_Department ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY Nombre');
    try
      SetLength(FIds, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        tvDepts.DataController.RecordCount := I + 1;
        tvDepts.DataController.Values[I, colDeptId.Index] := Q.FieldByName('DepartmentId').AsInteger;
        tvDepts.DataController.Values[I, colDeptNombre.Index] := Q.FieldByName('Nombre').AsString;
        tvDepts.DataController.Values[I, colDeptDescripcion.Index] := Q.FieldByName('Descripcion').AsString;
        FIds[I] := Q.FieldByName('DepartmentId').AsInteger;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvDepts.EndUpdate;
  end;
end;

function TfrmGestionDepartamentos.GetSelectedIdx: Integer;
begin
  Result := -1;
  if tvDepts.Controller.FocusedRecord <> nil then
    Result := tvDepts.Controller.FocusedRecord.RecordIndex;
end;

procedure TfrmGestionDepartamentos.btnAddClick(Sender: TObject);
var
  Nombre: string;
  NewId, Cnt: Integer;
  Q: TADOQuery;
begin
  Nombre := InputBox('Nuevo Departamento', 'Nombre:', '');
  if Nombre = '' then Exit;

  Exec('INSERT INTO FS_PL_Department (CodigoEmpresa, Nombre) VALUES (' +
    IntToStr(DMPlanner.CodigoEmpresa) + ', ' + QStr(Nombre) + ')');

  Q := OpenQuery('SELECT MAX(DepartmentId) AS NewId FROM FS_PL_Department WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa));
  try
    NewId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;

  Cnt := tvDepts.DataController.RecordCount;
  tvDepts.DataController.RecordCount := Cnt + 1;
  tvDepts.DataController.Values[Cnt, colDeptId.Index] := NewId;
  tvDepts.DataController.Values[Cnt, colDeptNombre.Index] := Nombre;
  tvDepts.DataController.Values[Cnt, colDeptDescripcion.Index] := '';

  SetLength(FIds, Cnt + 1);
  FIds[Cnt] := NewId;
end;

procedure TfrmGestionDepartamentos.btnDelClick(Sender: TObject);
var
  Idx, DeptId: Integer;
begin
  Idx := GetSelectedIdx;
  if (Idx < 0) or (Idx > High(FIds)) then Exit;
  if MessageDlg('¿Eliminar este departamento?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  DeptId := FIds[Idx];
  Exec('DELETE FROM FS_PL_Department WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) + ' AND DepartmentId = ' + IntToStr(DeptId));
  LoadDepts;
end;

procedure TfrmGestionDepartamentos.btnSaveClick(Sender: TObject);
var
  I, DeptId: Integer;
  Nombre, Descripcion: string;
  CE: string;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  for I := 0 to tvDepts.DataController.RecordCount - 1 do
  begin
    if I > High(FIds) then Continue;
    DeptId := FIds[I];
    Nombre := VarToStr(tvDepts.DataController.Values[I, colDeptNombre.Index]);
    Descripcion := VarToStr(tvDepts.DataController.Values[I, colDeptDescripcion.Index]);

    if Nombre = '' then Continue;

    Exec('UPDATE FS_PL_Department SET ' +
      'Nombre = ' + QStr(Nombre) + ', ' +
      'Descripcion = ' + QStr(Descripcion) +
      ' WHERE CodigoEmpresa = ' + CE + ' AND DepartmentId = ' + IntToStr(DeptId));
  end;
  ShowMessage('Departamentos guardados correctamente.');
end;

end.
