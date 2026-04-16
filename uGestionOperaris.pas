unit uGestionOperaris;
interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxDropDownEdit,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019DarkGray, dxSkinOffice2019White,
  dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus,
  dxSkinSilver, dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008,
  dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue;
type
  TfrmGestionOperaris = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnDel: TButton;
    btnSave: TButton;
    btnDepartamentos: TButton;
    btnCapacitaciones: TButton;
    gridOperaris: TcxGrid;
    tvOperaris: TcxGridTableView;
    colOpId: TcxGridColumn;
    colOpNombre: TcxGridColumn;
    colOpCalendario: TcxGridColumn;
    colOpActivo: TcxGridColumn;
    colOpDepartamentos: TcxGridColumn;
    colOpCapacitaciones: TcxGridColumn;
    lvOperaris: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDepartamentosClick(Sender: TObject);
    procedure btnCapacitacionesClick(Sender: TObject);
  private
    FOperatorIds: TArray<Integer>;
    FCalendarIds: TArray<Integer>;
    FCalendarNames: TArray<string>;
    procedure LoadCalendars;
    procedure SetupCombos;
    procedure LoadOperarios;
    function GetSelectedIdx: Integer;
    function SelectedOperatorId: Integer;
    function SelectedOperatorName: string;
    function CalendarIdFromName(const AName: string): Integer;
    function CalendarNameFromId(ACalendarId: Integer): string;
    function GetDeptsCSV(AOperatorId: Integer): string;
    function GetSkillsCount(AOperatorId: Integer): Integer;
    procedure RefreshDeptsCell(ARecIdx: Integer);
    procedure RefreshSkillsCell(ARecIdx: Integer);
    function Exec(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
    function QStrNullable(AId: Integer): string;
  end;
implementation
{$R *.dfm}
uses
  uDMPlanner, uAsignarDepartamentos, uGestionCapacitaciones;
function TfrmGestionOperaris.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;
function TfrmGestionOperaris.QStrNullable(AId: Integer): string;
begin
  if AId <= 0 then
    Result := 'NULL'
  else
    Result := IntToStr(AId);
end;
function TfrmGestionOperaris.Exec(const ASQL: string): Integer;
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
function TfrmGestionOperaris.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;
procedure TfrmGestionOperaris.FormCreate(Sender: TObject);
begin
  LoadCalendars;
  SetupCombos;
  LoadOperarios;
end;
procedure TfrmGestionOperaris.btnCloseClick(Sender: TObject);
begin
  Close;
end;
procedure TfrmGestionOperaris.LoadCalendars;
var
  Q: TADOQuery;
  I: Integer;
begin
  SetLength(FCalendarIds, 1);
  SetLength(FCalendarNames, 1);
  FCalendarIds[0] := 0;
  FCalendarNames[0] := '(sin calendario)';
  Q := OpenQuery('SELECT CalendarId, Nombre FROM FS_PL_Calendar WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) + ' AND Activo = 1 ORDER BY Nombre');
  try
    I := 1;
    while not Q.Eof do
    begin
      SetLength(FCalendarIds, I + 1);
      SetLength(FCalendarNames, I + 1);
      FCalendarIds[I] := Q.FieldByName('CalendarId').AsInteger;
      FCalendarNames[I] := Q.FieldByName('Nombre').AsString;
      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;
procedure TfrmGestionOperaris.SetupCombos;
var
  Props: TcxComboBoxProperties;
  I: Integer;
begin
  Props := colOpCalendario.Properties as TcxComboBoxProperties;
  Props.Items.Clear;
  Props.DropDownListStyle := lsFixedList;
  for I := 0 to High(FCalendarNames) do
    Props.Items.Add(FCalendarNames[I]);
end;
function TfrmGestionOperaris.CalendarIdFromName(const AName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FCalendarNames) do
    if SameText(FCalendarNames[I], AName) then
      Exit(FCalendarIds[I]);
  Result := 0;
end;
function TfrmGestionOperaris.CalendarNameFromId(ACalendarId: Integer): string;
var
  I: Integer;
begin
  for I := 0 to High(FCalendarIds) do
    if FCalendarIds[I] = ACalendarId then
      Exit(FCalendarNames[I]);
  Result := FCalendarNames[0];
end;
function TfrmGestionOperaris.GetDeptsCSV(AOperatorId: Integer): string;
var
  Q: TADOQuery;
  S: string;
begin
  Result := '';
  Q := OpenQuery(
    'SELECT d.Nombre FROM FS_PL_OperatorDepartment od ' +
    'INNER JOIN FS_PL_Department d ON d.CodigoEmpresa = od.CodigoEmpresa ' +
    '  AND d.DepartmentId = od.DepartmentId ' +
    'WHERE od.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
    '  AND od.OperatorId = ' + IntToStr(AOperatorId) +
    ' ORDER BY d.Nombre');
  try
    while not Q.Eof do
    begin
      S := Q.FieldByName('Nombre').AsString;
      if Result = '' then Result := S else Result := Result + ', ' + S;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;
function TfrmGestionOperaris.GetSkillsCount(AOperatorId: Integer): Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  Q := OpenQuery('SELECT COUNT(*) AS N FROM FS_PL_OperatorSkill WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) + ' AND OperatorId = ' + IntToStr(AOperatorId));
  try
    if not Q.Eof then Result := Q.FieldByName('N').AsInteger;
  finally
    Q.Free;
  end;
end;
procedure TfrmGestionOperaris.LoadOperarios;
var
  Q: TADOQuery;
  I, OpId, CalId: Integer;
begin
  tvOperaris.BeginUpdate;
  try
    tvOperaris.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT o.OperatorId, o.Nombre, ISNULL(o.CalendarId, 0) AS CalendarId, o.Activo ' +
      'FROM FS_PL_Operator o ' +
      'WHERE o.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY o.Nombre');
    try
      SetLength(FOperatorIds, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        OpId := Q.FieldByName('OperatorId').AsInteger;
        CalId := Q.FieldByName('CalendarId').AsInteger;
        tvOperaris.DataController.RecordCount := I + 1;
        tvOperaris.DataController.Values[I, colOpId.Index] := OpId;
        tvOperaris.DataController.Values[I, colOpNombre.Index] := Q.FieldByName('Nombre').AsString;
        tvOperaris.DataController.Values[I, colOpCalendario.Index] := CalendarNameFromId(CalId);
        tvOperaris.DataController.Values[I, colOpActivo.Index] := Q.FieldByName('Activo').AsBoolean;
        tvOperaris.DataController.Values[I, colOpDepartamentos.Index] := GetDeptsCSV(OpId);
        tvOperaris.DataController.Values[I, colOpCapacitaciones.Index] := GetSkillsCount(OpId);
        FOperatorIds[I] := OpId;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvOperaris.EndUpdate;
  end;
end;
function TfrmGestionOperaris.GetSelectedIdx: Integer;
begin
  Result := tvOperaris.Controller.FocusedRecordIndex;
end;
function TfrmGestionOperaris.SelectedOperatorId: Integer;
var
  Idx: Integer;
begin
  Result := -1;
  Idx := GetSelectedIdx;
  if (Idx >= 0) and (Idx <= High(FOperatorIds)) then
    Result := FOperatorIds[Idx];
end;
function TfrmGestionOperaris.SelectedOperatorName: string;
var
  Idx: Integer;
begin
  Result := '';
  Idx := GetSelectedIdx;
  if Idx >= 0 then
    Result := VarToStr(tvOperaris.DataController.Values[Idx, colOpNombre.Index]);
end;
procedure TfrmGestionOperaris.RefreshDeptsCell(ARecIdx: Integer);
begin
  if (ARecIdx < 0) or (ARecIdx > High(FOperatorIds)) then Exit;
  tvOperaris.DataController.Values[ARecIdx, colOpDepartamentos.Index] :=
    GetDeptsCSV(FOperatorIds[ARecIdx]);
end;
procedure TfrmGestionOperaris.RefreshSkillsCell(ARecIdx: Integer);
begin
  if (ARecIdx < 0) or (ARecIdx > High(FOperatorIds)) then Exit;
  tvOperaris.DataController.Values[ARecIdx, colOpCapacitaciones.Index] :=
    GetSkillsCount(FOperatorIds[ARecIdx]);
end;
procedure TfrmGestionOperaris.btnAddClick(Sender: TObject);
var
  Nombre: string;
  Q: TADOQuery;
  NewId, Cnt: Integer;
begin
  Nombre := InputBox('Nuevo Operario', 'Nombre:', '');
  if Nombre = '' then Exit;
  Exec('INSERT INTO FS_PL_Operator (CodigoEmpresa, Nombre, Activo) VALUES (' +
    IntToStr(DMPlanner.CodigoEmpresa) + ', ' + QStr(Nombre) + ', 1)');
  Q := OpenQuery('SELECT MAX(OperatorId) AS NewId FROM FS_PL_Operator WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa));
  try
    NewId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;
  Cnt := tvOperaris.DataController.RecordCount;
  tvOperaris.DataController.RecordCount := Cnt + 1;
  tvOperaris.DataController.Values[Cnt, colOpId.Index] := NewId;
  tvOperaris.DataController.Values[Cnt, colOpNombre.Index] := Nombre;
  tvOperaris.DataController.Values[Cnt, colOpCalendario.Index] := FCalendarNames[0];
  tvOperaris.DataController.Values[Cnt, colOpActivo.Index] := True;
  tvOperaris.DataController.Values[Cnt, colOpDepartamentos.Index] := '';
  tvOperaris.DataController.Values[Cnt, colOpCapacitaciones.Index] := 0;
  SetLength(FOperatorIds, Cnt + 1);
  FOperatorIds[Cnt] := NewId;
  tvOperaris.Controller.FocusedRecordIndex := Cnt;
end;
procedure TfrmGestionOperaris.btnDelClick(Sender: TObject);
var
  OpId: Integer;
  CE: string;
begin
  OpId := SelectedOperatorId;
  if OpId <= 0 then Exit;
  if MessageDlg('¿Eliminar este operario?' + sLineBreak +
    'Se eliminarán también sus departamentos y capacitaciones.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  // FKs con ON DELETE CASCADE borran department + skill, pero explícito va bien
  Exec('DELETE FROM FS_PL_OperatorSkill WHERE CodigoEmpresa = ' + CE +
    ' AND OperatorId = ' + IntToStr(OpId));
  Exec('DELETE FROM FS_PL_OperatorDepartment WHERE CodigoEmpresa = ' + CE +
    ' AND OperatorId = ' + IntToStr(OpId));
  Exec('DELETE FROM FS_PL_Operator WHERE CodigoEmpresa = ' + CE +
    ' AND OperatorId = ' + IntToStr(OpId));
  LoadOperarios;
end;
procedure TfrmGestionOperaris.btnSaveClick(Sender: TObject);
var
  I, OpId, CalId: Integer;
  Nombre, CalName: string;
  Activo: Boolean;
  V: Variant;
  CE: string;
  function AsBool(AV: Variant): Boolean;
  begin
    Result := (not VarIsNull(AV)) and (not VarIsEmpty(AV)) and Boolean(AV);
  end;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  for I := 0 to tvOperaris.DataController.RecordCount - 1 do
  begin
    if I > High(FOperatorIds) then Continue;
    OpId := FOperatorIds[I];
    Nombre := VarToStr(tvOperaris.DataController.Values[I, colOpNombre.Index]);
    CalName := VarToStr(tvOperaris.DataController.Values[I, colOpCalendario.Index]);
    V := tvOperaris.DataController.Values[I, colOpActivo.Index];
    Activo := AsBool(V);
    CalId := CalendarIdFromName(CalName);
    if Nombre = '' then Continue;
    Exec('UPDATE FS_PL_Operator SET ' +
      'Nombre = ' + QStr(Nombre) + ', ' +
      'CalendarId = ' + QStrNullable(CalId) + ', ' +
      'Activo = ' + IntToStr(Ord(Activo)) +
      ' WHERE CodigoEmpresa = ' + CE + ' AND OperatorId = ' + IntToStr(OpId));
  end;
  ShowMessage('Operarios guardados correctamente.');
  LoadOperarios;
end;
procedure TfrmGestionOperaris.btnDepartamentosClick(Sender: TObject);
var
  OpId, Idx: Integer;
begin
  OpId := SelectedOperatorId;
  if OpId <= 0 then
  begin
    ShowMessage('Seleccione un operario.');
    Exit;
  end;
  Idx := GetSelectedIdx;
  if TfrmAsignarDepartamentos.Execute(OpId, SelectedOperatorName) then
    RefreshDeptsCell(Idx);
end;
procedure TfrmGestionOperaris.btnCapacitacionesClick(Sender: TObject);
var
  Idx: Integer;
  Frm: TfrmGestionCapacitaciones;
begin
  if SelectedOperatorId <= 0 then
  begin
    ShowMessage('Seleccione un operario.');
    Exit;
  end;
  Idx := GetSelectedIdx;
  Frm := TfrmGestionCapacitaciones.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  RefreshSkillsCell(Idx);
end;
end.
