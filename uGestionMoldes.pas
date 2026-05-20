unit uGestionMoldes;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxSpinEdit, cxCalendar, cxDropDownEdit,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB,
  uMoldeTypes, uMoldeRepoSQL;

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
    btnUtillajes: TButton;
    gridMoldes: TcxGrid;
    tvMoldes: TcxGridTableView;
    colId: TcxGridColumn;
    colCodigo: TcxGridColumn;
    colDescripcion: TcxGridColumn;
    colTipo: TcxGridColumn;
    colEstado: TcxGridColumn;
    colCentroActual: TcxGridColumn;
    colCavidades: TcxGridColumn;
    colTMontaje: TcxGridColumn;
    colTDesmontaje: TcxGridColumn;
    colTAjuste: TcxGridColumn;
    colCiclos: TcxGridColumn;
    colFechaProxMant: TcxGridColumn;
    colUbicacion: TcxGridColumn;
    colDisponible: TcxGridColumn;
    colObservaciones: TcxGridColumn;
    lvMoldes: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCentrosClick(Sender: TObject);
    procedure btnArticulosClick(Sender: TObject);
    procedure btnOperacionesClick(Sender: TObject);
    procedure btnUtillajesClick(Sender: TObject);
  private
    FRepo: TMoldeRepoSQL;
    FMoldIds: TArray<Integer>;
    FDeleted: TList<Integer>;
    FCenterIds: TArray<Integer>;
    FCenterNames: TArray<string>;
    procedure LoadCentros;
    procedure SetupCentroCombo;
    procedure LoadMoldes;
    function CenterNameFromId(ACenterId: Integer): string;
    function CenterIdFromName(const AName: string): Integer;
    function GetSelectedIdx: Integer;
    function SelectedMoldId: Integer;
    function SelectedMoldCodigo: string;
    procedure CollectRow(I: Integer; out ARow: TMoldeRow);
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uAsignarCentrosMolde, uEditarListaMolde;

procedure TfrmGestionMoldes.FormCreate(Sender: TObject);
begin
  FRepo := TMoldeRepoSQL.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  FDeleted := TList<Integer>.Create;
  tvMoldes.OptionsData.Editing := True;
  tvMoldes.OptionsSelection.CellSelect := True;
  LoadCentros;
  SetupCentroCombo;
  LoadMoldes;
end;

procedure TfrmGestionMoldes.FormDestroy(Sender: TObject);
begin
  FDeleted.Free;
  FRepo.Free;
end;

procedure TfrmGestionMoldes.btnCloseClick(Sender: TObject);
begin
  Close;
end;

// ---------------------------------------------------------------------------
// Centros (para combo)
// ---------------------------------------------------------------------------

procedure TfrmGestionMoldes.LoadCentros;
var
  Q: TADOQuery;
  I: Integer;
begin
  SetLength(FCenterIds, 1);
  SetLength(FCenterNames, 1);
  FCenterIds[0] := 0;
  FCenterNames[0] := '(sin centro)';

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT CenterId, Titulo FROM FS_PL_Center WHERE CodigoEmpresa = :CE ' +
      'AND Visible = 1 ORDER BY Orden, Titulo';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Open;
    I := 1;
    while not Q.Eof do
    begin
      SetLength(FCenterIds, I + 1);
      SetLength(FCenterNames, I + 1);
      FCenterIds[I] := Q.FieldByName('CenterId').AsInteger;
      FCenterNames[I] := Q.FieldByName('Titulo').AsString;
      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmGestionMoldes.SetupCentroCombo;
var
  Props: TcxComboBoxProperties;
  I: Integer;
begin
  Props := colCentroActual.Properties as TcxComboBoxProperties;
  Props.Items.Clear;
  for I := 0 to High(FCenterNames) do
    Props.Items.Add(FCenterNames[I]);
end;

function TfrmGestionMoldes.CenterNameFromId(ACenterId: Integer): string;
var
  I: Integer;
begin
  for I := 0 to High(FCenterIds) do
    if FCenterIds[I] = ACenterId then
      Exit(FCenterNames[I]);
  Result := FCenterNames[0];
end;

function TfrmGestionMoldes.CenterIdFromName(const AName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FCenterNames) do
    if SameText(FCenterNames[I], AName) then
      Exit(FCenterIds[I]);
  Result := 0;
end;

// ---------------------------------------------------------------------------
// Moldes
// ---------------------------------------------------------------------------

procedure TfrmGestionMoldes.LoadMoldes;
var
  Rows: TArray<TMoldeRow>;
  I: Integer;
  R: TMoldeRow;
begin
  FDeleted.Clear;
  Rows := FRepo.LoadAll;

  tvMoldes.BeginUpdate;
  try
    tvMoldes.DataController.RecordCount := 0;
    tvMoldes.DataController.RecordCount := Length(Rows);
    SetLength(FMoldIds, Length(Rows));
    for I := 0 to High(Rows) do
    begin
      R := Rows[I];
      FMoldIds[I] := R.Id;
      tvMoldes.DataController.Values[I, colId.Index]            := R.Id;
      tvMoldes.DataController.Values[I, colCodigo.Index]        := R.Codigo;
      tvMoldes.DataController.Values[I, colDescripcion.Index]   := R.Descripcion;
      tvMoldes.DataController.Values[I, colTipo.Index]          := TipoMoldeToStr(R.TipoMolde);
      tvMoldes.DataController.Values[I, colEstado.Index]        := EstadoMoldeToStr(R.Estado);
      tvMoldes.DataController.Values[I, colCentroActual.Index]  := CenterNameFromId(R.CentroActualId);
      tvMoldes.DataController.Values[I, colCavidades.Index]     := R.NumeroCavidades;
      tvMoldes.DataController.Values[I, colTMontaje.Index]      := R.TiempoMontaje;
      tvMoldes.DataController.Values[I, colTDesmontaje.Index]   := R.TiempoDesmontaje;
      tvMoldes.DataController.Values[I, colTAjuste.Index]       := R.TiempoAjuste;
      tvMoldes.DataController.Values[I, colCiclos.Index]        := R.CiclosAcumulados;
      if R.FechaProxMantNull then
        tvMoldes.DataController.Values[I, colFechaProxMant.Index] := Null
      else
        tvMoldes.DataController.Values[I, colFechaProxMant.Index] := R.FechaProxMantenimiento;
      tvMoldes.DataController.Values[I, colUbicacion.Index]     := R.UbicacionActual;
      tvMoldes.DataController.Values[I, colDisponible.Index]    := R.DisponiblePlanificacion;
      tvMoldes.DataController.Values[I, colObservaciones.Index] := R.Observaciones;
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

procedure TfrmGestionMoldes.CollectRow(I: Integer; out ARow: TMoldeRow);
var
  V: Variant;
  function AsStr(AV: Variant): string;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := '' else Result := VarToStr(AV);
  end;
  function AsInt(AV: Variant; ADef: Integer = 0): Integer;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADef else Result := Integer(AV);
  end;
  function AsFloat(AV: Variant): Double;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := 0 else Result := Double(AV);
  end;
  function AsBool(AV: Variant; ADef: Boolean = False): Boolean;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADef else Result := Boolean(AV);
  end;
begin
  ARow := Default(TMoldeRow);
  if I < Length(FMoldIds) then ARow.Id := FMoldIds[I] else ARow.Id := 0;

  ARow.Codigo := AsStr(tvMoldes.DataController.Values[I, colCodigo.Index]);
  ARow.Descripcion := AsStr(tvMoldes.DataController.Values[I, colDescripcion.Index]);
  ARow.TipoMolde := StrToTipoMolde(AsStr(tvMoldes.DataController.Values[I, colTipo.Index]));
  ARow.Estado := StrToEstadoMolde(AsStr(tvMoldes.DataController.Values[I, colEstado.Index]));
  ARow.CentroActualId := CenterIdFromName(AsStr(tvMoldes.DataController.Values[I, colCentroActual.Index]));
  ARow.NumeroCavidades := AsInt(tvMoldes.DataController.Values[I, colCavidades.Index], 1);
  if ARow.NumeroCavidades <= 0 then ARow.NumeroCavidades := 1;
  ARow.TiempoMontaje := AsFloat(tvMoldes.DataController.Values[I, colTMontaje.Index]);
  ARow.TiempoDesmontaje := AsFloat(tvMoldes.DataController.Values[I, colTDesmontaje.Index]);
  ARow.TiempoAjuste := AsFloat(tvMoldes.DataController.Values[I, colTAjuste.Index]);
  ARow.CiclosAcumulados := AsInt(tvMoldes.DataController.Values[I, colCiclos.Index]);

  V := tvMoldes.DataController.Values[I, colFechaProxMant.Index];
  if VarIsNull(V) or VarIsEmpty(V) then
  begin
    ARow.FechaProxMantenimiento := 0;
    ARow.FechaProxMantNull := True;
  end
  else
  begin
    ARow.FechaProxMantenimiento := VarToDateTime(V);
    ARow.FechaProxMantNull := (ARow.FechaProxMantenimiento = 0);
  end;

  ARow.UbicacionActual := AsStr(tvMoldes.DataController.Values[I, colUbicacion.Index]);
  ARow.DisponiblePlanificacion := AsBool(tvMoldes.DataController.Values[I, colDisponible.Index], True);
  ARow.Observaciones := AsStr(tvMoldes.DataController.Values[I, colObservaciones.Index]);
end;

procedure TfrmGestionMoldes.btnAddClick(Sender: TObject);
var
  Codigo: string;
  Cnt: Integer;
begin
  Codigo := InputBox('Nuevo Molde', 'C'#243'digo:', '');
  if Trim(Codigo) = '' then Exit;

  Cnt := tvMoldes.DataController.RecordCount;
  tvMoldes.DataController.RecordCount := Cnt + 1;
  SetLength(FMoldIds, Cnt + 1);
  FMoldIds[Cnt] := 0; // 0 = nuevo

  tvMoldes.DataController.Values[Cnt, colId.Index]            := 0;
  tvMoldes.DataController.Values[Cnt, colCodigo.Index]        := Codigo;
  tvMoldes.DataController.Values[Cnt, colDescripcion.Index]   := '';
  tvMoldes.DataController.Values[Cnt, colTipo.Index]          := TipoMoldeToStr(tmOtro);
  tvMoldes.DataController.Values[Cnt, colEstado.Index]        := EstadoMoldeToStr(emDisponible);
  tvMoldes.DataController.Values[Cnt, colCentroActual.Index]  := FCenterNames[0];
  tvMoldes.DataController.Values[Cnt, colCavidades.Index]     := 1;
  tvMoldes.DataController.Values[Cnt, colTMontaje.Index]      := 0;
  tvMoldes.DataController.Values[Cnt, colTDesmontaje.Index]   := 0;
  tvMoldes.DataController.Values[Cnt, colTAjuste.Index]       := 0;
  tvMoldes.DataController.Values[Cnt, colCiclos.Index]        := 0;
  tvMoldes.DataController.Values[Cnt, colFechaProxMant.Index] := Null;
  tvMoldes.DataController.Values[Cnt, colUbicacion.Index]     := '';
  tvMoldes.DataController.Values[Cnt, colDisponible.Index]    := True;
  tvMoldes.DataController.Values[Cnt, colObservaciones.Index] := '';

  tvMoldes.Controller.FocusedRecordIndex := Cnt;
end;

procedure TfrmGestionMoldes.btnDelClick(Sender: TObject);
var
  Idx, MoldId, I: Integer;
  NewIds: TArray<Integer>;
begin
  Idx := GetSelectedIdx;
  if Idx < 0 then Exit;
  if MessageDlg(#191'Eliminar este molde?' + sLineBreak +
    'Se eliminar'#225'n tambi'#233'n sus centros, art'#237'culos, operaciones y utillajes asociados.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  if Idx < Length(FMoldIds) then
  begin
    MoldId := FMoldIds[Idx];
    if MoldId > 0 then
      FDeleted.Add(MoldId);
  end;

  SetLength(NewIds, Length(FMoldIds) - 1);
  for I := 0 to High(FMoldIds) do
    if I < Idx then NewIds[I] := FMoldIds[I]
    else if I > Idx then NewIds[I - 1] := FMoldIds[I];
  FMoldIds := NewIds;

  tvMoldes.DataController.DeleteRecord(Idx);
end;

procedure TfrmGestionMoldes.btnSaveClick(Sender: TObject);
var
  I, NewId: Integer;
  R: TMoldeRow;
begin
  for I := 0 to FDeleted.Count - 1 do
    FRepo.Delete(FDeleted[I]);
  FDeleted.Clear;

  for I := 0 to tvMoldes.DataController.RecordCount - 1 do
  begin
    CollectRow(I, R);
    if Trim(R.Codigo) = '' then Continue;

    if R.Id <= 0 then
    begin
      NewId := FRepo.Insert(R);
      if I < Length(FMoldIds) then FMoldIds[I] := NewId;
      tvMoldes.DataController.Values[I, colId.Index] := NewId;
    end
    else
      FRepo.Update(R);
  end;

  LoadMoldes;
  ShowMessage('Moldes guardados correctamente.');
end;

procedure TfrmGestionMoldes.btnCentrosClick(Sender: TObject);
var
  MoldId: Integer;
begin
  MoldId := SelectedMoldId;
  if MoldId <= 0 then
  begin
    ShowMessage('Seleccione un molde guardado.');
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
    ShowMessage('Seleccione un molde guardado.');
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
    ShowMessage('Seleccione un molde guardado.');
    Exit;
  end;
  TfrmEditarListaMolde.Execute(MoldId, SelectedMoldCodigo, elkOperaciones);
end;

procedure TfrmGestionMoldes.btnUtillajesClick(Sender: TObject);
var
  MoldId: Integer;
begin
  MoldId := SelectedMoldId;
  if MoldId <= 0 then
  begin
    ShowMessage('Seleccione un molde guardado.');
    Exit;
  end;
  TfrmEditarListaMolde.Execute(MoldId, SelectedMoldCodigo, elkUtillajes);
end;

end.
