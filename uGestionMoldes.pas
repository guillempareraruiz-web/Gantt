unit uGestionMoldes;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxSpinEdit,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB;

type
  TfrmGestionMoldes = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnDel: TButton;
    btnSave: TButton;
    btnCentros: TButton;
    btnArticulos: TButton;
    btnOperaciones: TButton;
    gridMoldes: TcxGrid;
    tvMoldes: TcxGridTableView;
    colId: TcxGridColumn;
    colCodigo: TcxGridColumn;
    colDescripcion: TcxGridColumn;
    colCavidades: TcxGridColumn;
    colTMontaje: TcxGridColumn;
    colTDesmontaje: TcxGridColumn;
    colTAjuste: TcxGridColumn;
    colCiclos: TcxGridColumn;
    colUbicacion: TcxGridColumn;
    colDisponible: TcxGridColumn;
    lvMoldes: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCentrosClick(Sender: TObject);
    procedure btnArticulosClick(Sender: TObject);
    procedure btnOperacionesClick(Sender: TObject);
  private
    FMoldIds: TArray<Integer>;
    procedure LoadMoldes;
    function GetSelectedIdx: Integer;
    function SelectedMoldId: Integer;
    function SelectedMoldCodigo: string;
    function Exec(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uAsignarCentrosMolde, uEditarListaMolde;

function TfrmGestionMoldes.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmGestionMoldes.Exec(const ASQL: string): Integer;
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

function TfrmGestionMoldes.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

procedure TfrmGestionMoldes.FormCreate(Sender: TObject);
begin
  LoadMoldes;
end;

procedure TfrmGestionMoldes.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmGestionMoldes.LoadMoldes;
var
  Q: TADOQuery;
  I: Integer;
begin
  tvMoldes.BeginUpdate;
  try
    tvMoldes.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT MoldId, Codigo, ISNULL(Descripcion, '''') AS Descripcion, ' +
      '  NumeroCavidades, ISNULL(TiempoMontaje, 0) AS TMontaje, ' +
      '  ISNULL(TiempoDesmontaje, 0) AS TDesmontaje, ' +
      '  ISNULL(TiempoAjuste, 0) AS TAjuste, ' +
      '  CiclosAcumulados, ISNULL(UbicacionActual, '''') AS Ubicacion, ' +
      '  DisponiblePlanificacion ' +
      'FROM FS_PL_Mold WHERE CodigoEmpresa = ' +
      IntToStr(DMPlanner.CodigoEmpresa) + ' ORDER BY Codigo');
    try
      SetLength(FMoldIds, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        tvMoldes.DataController.RecordCount := I + 1;
        tvMoldes.DataController.Values[I, colId.Index] := Q.FieldByName('MoldId').AsInteger;
        tvMoldes.DataController.Values[I, colCodigo.Index] := Q.FieldByName('Codigo').AsString;
        tvMoldes.DataController.Values[I, colDescripcion.Index] := Q.FieldByName('Descripcion').AsString;
        tvMoldes.DataController.Values[I, colCavidades.Index] := Q.FieldByName('NumeroCavidades').AsInteger;
        tvMoldes.DataController.Values[I, colTMontaje.Index] := Q.FieldByName('TMontaje').AsInteger;
        tvMoldes.DataController.Values[I, colTDesmontaje.Index] := Q.FieldByName('TDesmontaje').AsInteger;
        tvMoldes.DataController.Values[I, colTAjuste.Index] := Q.FieldByName('TAjuste').AsInteger;
        tvMoldes.DataController.Values[I, colCiclos.Index] := Q.FieldByName('CiclosAcumulados').AsInteger;
        tvMoldes.DataController.Values[I, colUbicacion.Index] := Q.FieldByName('Ubicacion').AsString;
        tvMoldes.DataController.Values[I, colDisponible.Index] := Q.FieldByName('DisponiblePlanificacion').AsBoolean;
        FMoldIds[I] := Q.FieldByName('MoldId').AsInteger;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvMoldes.EndUpdate;
  end;
end;

function TfrmGestionMoldes.GetSelectedIdx: Integer;
begin
  Result := tvMoldes.Controller.FocusedRecordIndex;
end;

function TfrmGestionMoldes.SelectedMoldId: Integer;
var
  Idx: Integer;
begin
  Result := -1;
  Idx := GetSelectedIdx;
  if (Idx >= 0) and (Idx <= High(FMoldIds)) then
    Result := FMoldIds[Idx];
end;

function TfrmGestionMoldes.SelectedMoldCodigo: string;
var
  Idx: Integer;
begin
  Result := '';
  Idx := GetSelectedIdx;
  if Idx >= 0 then
    Result := VarToStr(tvMoldes.DataController.Values[Idx, colCodigo.Index]);
end;

procedure TfrmGestionMoldes.btnAddClick(Sender: TObject);
var
  Codigo: string;
  Q: TADOQuery;
  NewId, Cnt: Integer;
begin
  Codigo := InputBox('Nuevo Molde', 'Código:', '');
  if Codigo = '' then Exit;

  Exec('INSERT INTO FS_PL_Mold (CodigoEmpresa, Codigo) VALUES (' +
    IntToStr(DMPlanner.CodigoEmpresa) + ', ' + QStr(Codigo) + ')');

  Q := OpenQuery('SELECT MAX(MoldId) AS NewId FROM FS_PL_Mold WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa));
  try
    NewId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;

  Cnt := tvMoldes.DataController.RecordCount;
  tvMoldes.DataController.RecordCount := Cnt + 1;
  tvMoldes.DataController.Values[Cnt, colId.Index] := NewId;
  tvMoldes.DataController.Values[Cnt, colCodigo.Index] := Codigo;
  tvMoldes.DataController.Values[Cnt, colDescripcion.Index] := '';
  tvMoldes.DataController.Values[Cnt, colCavidades.Index] := 1;
  tvMoldes.DataController.Values[Cnt, colTMontaje.Index] := 0;
  tvMoldes.DataController.Values[Cnt, colTDesmontaje.Index] := 0;
  tvMoldes.DataController.Values[Cnt, colTAjuste.Index] := 0;
  tvMoldes.DataController.Values[Cnt, colCiclos.Index] := 0;
  tvMoldes.DataController.Values[Cnt, colUbicacion.Index] := '';
  tvMoldes.DataController.Values[Cnt, colDisponible.Index] := True;

  SetLength(FMoldIds, Cnt + 1);
  FMoldIds[Cnt] := NewId;
  tvMoldes.Controller.FocusedRecordIndex := Cnt;
end;

procedure TfrmGestionMoldes.btnDelClick(Sender: TObject);
var
  MoldId: Integer;
  CE: string;
begin
  MoldId := SelectedMoldId;
  if MoldId <= 0 then Exit;
  if MessageDlg('¿Eliminar este molde?' + sLineBreak +
    'Se eliminarán también sus centros, artículos y operaciones asociados.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  Exec('DELETE FROM FS_PL_Mold WHERE CodigoEmpresa = ' + CE +
    ' AND MoldId = ' + IntToStr(MoldId));
  LoadMoldes;
end;

procedure TfrmGestionMoldes.btnSaveClick(Sender: TObject);
var
  I, MoldId, Cavidades, TMont, TDesm, TAjus, Ciclos: Integer;
  Codigo, Descripcion, Ubicacion: string;
  Disponible: Boolean;
  V: Variant;
  CE: string;

  function AsBool(AV: Variant): Boolean;
  begin
    Result := (not VarIsNull(AV)) and (not VarIsEmpty(AV)) and Boolean(AV);
  end;

  function AsInt(AV: Variant): Integer;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := 0 else Result := Integer(AV);
  end;

begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  for I := 0 to tvMoldes.DataController.RecordCount - 1 do
  begin
    if I > High(FMoldIds) then Continue;
    MoldId := FMoldIds[I];
    Codigo := VarToStr(tvMoldes.DataController.Values[I, colCodigo.Index]);
    Descripcion := VarToStr(tvMoldes.DataController.Values[I, colDescripcion.Index]);
    Cavidades := AsInt(tvMoldes.DataController.Values[I, colCavidades.Index]);
    if Cavidades <= 0 then Cavidades := 1;
    TMont := AsInt(tvMoldes.DataController.Values[I, colTMontaje.Index]);
    TDesm := AsInt(tvMoldes.DataController.Values[I, colTDesmontaje.Index]);
    TAjus := AsInt(tvMoldes.DataController.Values[I, colTAjuste.Index]);
    Ciclos := AsInt(tvMoldes.DataController.Values[I, colCiclos.Index]);
    Ubicacion := VarToStr(tvMoldes.DataController.Values[I, colUbicacion.Index]);
    V := tvMoldes.DataController.Values[I, colDisponible.Index];
    Disponible := AsBool(V);

    if Codigo = '' then Continue;

    Exec('UPDATE FS_PL_Mold SET ' +
      'Codigo = ' + QStr(Codigo) + ', ' +
      'Descripcion = ' + QStr(Descripcion) + ', ' +
      'NumeroCavidades = ' + IntToStr(Cavidades) + ', ' +
      'TiempoMontaje = ' + IntToStr(TMont) + ', ' +
      'TiempoDesmontaje = ' + IntToStr(TDesm) + ', ' +
      'TiempoAjuste = ' + IntToStr(TAjus) + ', ' +
      'CiclosAcumulados = ' + IntToStr(Ciclos) + ', ' +
      'UbicacionActual = ' + QStr(Ubicacion) + ', ' +
      'DisponiblePlanificacion = ' + IntToStr(Ord(Disponible)) +
      ' WHERE CodigoEmpresa = ' + CE + ' AND MoldId = ' + IntToStr(MoldId));
  end;
  ShowMessage('Moldes guardados correctamente.');
  LoadMoldes;
end;

procedure TfrmGestionMoldes.btnCentrosClick(Sender: TObject);
var
  MoldId: Integer;
begin
  MoldId := SelectedMoldId;
  if MoldId <= 0 then
  begin
    ShowMessage('Seleccione un molde.');
    Exit;
  end;
  TfrmAsignarCentrosMolde.Execute(MoldId, SelectedMoldCodigo);
end;

procedure TfrmGestionMoldes.btnArticulosClick(Sender: TObject);
var
  MoldId: Integer;
begin
  MoldId := SelectedMoldId;
  if MoldId <= 0 then
  begin
    ShowMessage('Seleccione un molde.');
    Exit;
  end;
  TfrmEditarListaMolde.Execute(MoldId, SelectedMoldCodigo, elkArticulos);
end;

procedure TfrmGestionMoldes.btnOperacionesClick(Sender: TObject);
var
  MoldId: Integer;
begin
  MoldId := SelectedMoldId;
  if MoldId <= 0 then
  begin
    ShowMessage('Seleccione un molde.');
    Exit;
  end;
  TfrmEditarListaMolde.Execute(MoldId, SelectedMoldCodigo, elkOperaciones);
end;

end.
