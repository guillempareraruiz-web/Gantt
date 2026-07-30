unit uGestionAreas;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB;

type
  TfrmGestionAreas = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnDel: TButton;
    btnSave: TButton;
    gridAreas: TcxGrid;
    tvAreas: TcxGridTableView;
    colAreaId: TcxGridColumn;
    colAreaCodigo: TcxGridColumn;
    colAreaNombre: TcxGridColumn;
    colAreaOrden: TcxGridColumn;
    colAreaActivo: TcxGridColumn;
    lvAreas: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    FIds: TArray<Integer>;
    procedure LoadAreas;
    function GetSelectedIdx: Integer;
    function Exec(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

function TfrmGestionAreas.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmGestionAreas.Exec(const ASQL: string): Integer;
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

function TfrmGestionAreas.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

procedure TfrmGestionAreas.FormCreate(Sender: TObject);
begin
  LoadAreas;
end;

procedure TfrmGestionAreas.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmGestionAreas.LoadAreas;
var
  Q: TADOQuery;
  I: Integer;
begin
  tvAreas.BeginUpdate;
  try
    tvAreas.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT AreaId, Codigo, Nombre, Orden, Activo FROM FS_PL_Area ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY Orden, Nombre');
    try
      SetLength(FIds, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        tvAreas.DataController.RecordCount := I + 1;
        tvAreas.DataController.Values[I, colAreaId.Index] := Q.FieldByName('AreaId').AsInteger;
        tvAreas.DataController.Values[I, colAreaCodigo.Index] := Q.FieldByName('Codigo').AsString;
        tvAreas.DataController.Values[I, colAreaNombre.Index] := Q.FieldByName('Nombre').AsString;
        tvAreas.DataController.Values[I, colAreaOrden.Index] := Q.FieldByName('Orden').AsInteger;
        tvAreas.DataController.Values[I, colAreaActivo.Index] := Q.FieldByName('Activo').AsBoolean;
        FIds[I] := Q.FieldByName('AreaId').AsInteger;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvAreas.EndUpdate;
  end;
end;

function TfrmGestionAreas.GetSelectedIdx: Integer;
begin
  Result := -1;
  if tvAreas.Controller.FocusedRecord <> nil then
    Result := tvAreas.Controller.FocusedRecord.RecordIndex;
end;

procedure TfrmGestionAreas.btnAddClick(Sender: TObject);
var
  Codigo, Nombre: string;
  NewId, Cnt: Integer;
  Q: TADOQuery;
begin
  Codigo := InputBox('Nueva Área', 'Código:', '');
  if Codigo = '' then Exit;
  Nombre := InputBox('Nueva Área', 'Nombre:', Codigo);
  if Nombre = '' then Exit;

  Exec('INSERT INTO FS_PL_Area (CodigoEmpresa, Codigo, Nombre) VALUES (' +
    IntToStr(DMPlanner.CodigoEmpresa) + ', ' + QStr(Codigo) + ', ' + QStr(Nombre) + ')');

  // SCOPE_IDENTITY(): el id generado por ESTA sesion (misma conexion que Exec).
  // NO usar MAX(): con dos altas simultaneas devuelve la fila del OTRO usuario.
  Q := OpenQuery('SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewId');
  try
    NewId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;

  Cnt := tvAreas.DataController.RecordCount;
  tvAreas.DataController.RecordCount := Cnt + 1;
  tvAreas.DataController.Values[Cnt, colAreaId.Index] := NewId;
  tvAreas.DataController.Values[Cnt, colAreaCodigo.Index] := Codigo;
  tvAreas.DataController.Values[Cnt, colAreaNombre.Index] := Nombre;
  tvAreas.DataController.Values[Cnt, colAreaOrden.Index] := 0;
  tvAreas.DataController.Values[Cnt, colAreaActivo.Index] := True;

  SetLength(FIds, Cnt + 1);
  FIds[Cnt] := NewId;
end;

procedure TfrmGestionAreas.btnDelClick(Sender: TObject);
var
  Idx, AreaId: Integer;
  V: Variant;
begin
  // AreaId de la PROPIA celda del grid, no de FIds[Idx]: el indice es el de la
  // fila VISIBLE (cambia al ordenar por una columna) y FIds va en orden de carga
  // (ORDER BY Orden, Nombre) -> apuntaba a OTRA area.
  Idx := GetSelectedIdx;
  if Idx < 0 then Exit;
  V := tvAreas.DataController.Values[Idx, colAreaId.Index];
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  AreaId := V;
  if AreaId <= 0 then Exit;
  if MessageDlg('¿Eliminar esta área?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Exec('DELETE FROM FS_PL_Area WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) + ' AND AreaId = ' + IntToStr(AreaId));
  LoadAreas;
end;

procedure TfrmGestionAreas.btnSaveClick(Sender: TObject);
var
  I, AreaId, Orden: Integer;
  Codigo, Nombre: string;
  Activo: Boolean;
  V: Variant;
  CE: string;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  for I := 0 to tvAreas.DataController.RecordCount - 1 do
  begin
    // AreaId de la PROPIA fila, no de FIds[I]: con el grid ordenado (y "Orden"
    // es justo una columna que invita a ordenar) se guardaban codigo y nombre
    // de un area ENCIMA de otra.
    V := tvAreas.DataController.Values[I, colAreaId.Index];
    if VarIsNull(V) or VarIsEmpty(V) then Continue;
    AreaId := V;
    if AreaId <= 0 then Continue;
    Codigo := VarToStr(tvAreas.DataController.Values[I, colAreaCodigo.Index]);
    Nombre := VarToStr(tvAreas.DataController.Values[I, colAreaNombre.Index]);
    V := tvAreas.DataController.Values[I, colAreaOrden.Index];
    if VarIsNull(V) or VarIsEmpty(V) then Orden := 0 else Orden := Integer(V);
    V := tvAreas.DataController.Values[I, colAreaActivo.Index];
    Activo := (not VarIsNull(V)) and (not VarIsEmpty(V)) and Boolean(V);

    if (Codigo = '') or (Nombre = '') then Continue;

    Exec('UPDATE FS_PL_Area SET ' +
      'Codigo = ' + QStr(Codigo) + ', ' +
      'Nombre = ' + QStr(Nombre) + ', ' +
      'Orden = ' + IntToStr(Orden) + ', ' +
      'Activo = ' + IntToStr(Ord(Activo)) +
      ' WHERE CodigoEmpresa = ' + CE + ' AND AreaId = ' + IntToStr(AreaId));
  end;
  ShowMessage('Áreas guardadas correctamente.');
end;

end.
