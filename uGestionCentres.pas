unit uGestionCentres;
interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxDropDownEdit, cxSpinEdit, cxButtonEdit,
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
  TfrmGestionCentres = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnDel: TButton;
    btnSave: TButton;
    gridCentros: TcxGrid;
    tvCentros: TcxGridTableView;
    colCentroId: TcxGridColumn;
    colCentroCodigo: TcxGridColumn;
    colCentroTitulo: TcxGridColumn;
    colCentroSubtitulo: TcxGridColumn;
    colCentroArea: TcxGridColumn;
    colCentroCalendario: TcxGridColumn;
    colCentroSecuencial: TcxGridColumn;
    colCentroMaxLanes: TcxGridColumn;
    colCentroOrden: TcxGridColumn;
    colCentroVisible: TcxGridColumn;
    colCentroHabilitado: TcxGridColumn;
    colCentroColor: TcxGridColumn;
    lvCentros: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    ColorDialog: TColorDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure colCentroColorButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure colCentroColorCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  private
    FCenterIds: TArray<Integer>;
    FColors: TArray<Integer>;
    FAreaIds: TArray<Integer>;
    FAreaNames: TArray<string>;
    FCalendarIds: TArray<Integer>;
    FCalendarNames: TArray<string>;
    procedure LoadAreas;
    procedure LoadCalendars;
    procedure LoadCentros;
    procedure SetupCombos;
    function GetSelectedIdx: Integer;
    function AreaIdFromName(const AName: string): Integer;
    function AreaNameFromId(AAreaId: Integer): string;
    function CalendarIdFromName(const AName: string): Integer;
    function CalendarNameFromId(ACalendarId: Integer): string;
    function Exec(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
    function QStrNullable(AId: Integer): string;
    procedure RefreshColorCell(ARecIdx: Integer);
  end;
implementation
{$R *.dfm}
uses
  uDMPlanner;
function TfrmGestionCentres.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;
function TfrmGestionCentres.QStrNullable(AId: Integer): string;
begin
  if AId <= 0 then
    Result := 'NULL'
  else
    Result := IntToStr(AId);
end;
function TfrmGestionCentres.Exec(const ASQL: string): Integer;
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
function TfrmGestionCentres.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;
procedure TfrmGestionCentres.FormCreate(Sender: TObject);
begin
  LoadAreas;
  LoadCalendars;
  SetupCombos;
  LoadCentros;
end;
procedure TfrmGestionCentres.btnCloseClick(Sender: TObject);
begin
  Close;
end;
procedure TfrmGestionCentres.LoadAreas;
var
  Q: TADOQuery;
  I: Integer;
begin
  SetLength(FAreaIds, 1);
  SetLength(FAreaNames, 1);
  FAreaIds[0] := 0;
  FAreaNames[0] := '(sin área)';
  Q := OpenQuery('SELECT AreaId, Nombre FROM FS_PL_Area WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) + ' AND Activo = 1 ORDER BY Nombre');
  try
    I := 1;
    while not Q.Eof do
    begin
      SetLength(FAreaIds, I + 1);
      SetLength(FAreaNames, I + 1);
      FAreaIds[I] := Q.FieldByName('AreaId').AsInteger;
      FAreaNames[I] := Q.FieldByName('Nombre').AsString;
      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;
procedure TfrmGestionCentres.LoadCalendars;
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
procedure TfrmGestionCentres.SetupCombos;
var
  Props: TcxComboBoxProperties;
  I: Integer;
begin
  Props := colCentroArea.Properties as TcxComboBoxProperties;
  Props.Items.Clear;
  Props.DropDownListStyle := lsFixedList;
  for I := 0 to High(FAreaNames) do
    Props.Items.Add(FAreaNames[I]);
  Props := colCentroCalendario.Properties as TcxComboBoxProperties;
  Props.Items.Clear;
  Props.DropDownListStyle := lsFixedList;
  for I := 0 to High(FCalendarNames) do
    Props.Items.Add(FCalendarNames[I]);
end;
function TfrmGestionCentres.AreaIdFromName(const AName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FAreaNames) do
    if SameText(FAreaNames[I], AName) then
      Exit(FAreaIds[I]);
  Result := 0;
end;
function TfrmGestionCentres.AreaNameFromId(AAreaId: Integer): string;
var
  I: Integer;
begin
  for I := 0 to High(FAreaIds) do
    if FAreaIds[I] = AAreaId then
      Exit(FAreaNames[I]);
  Result := FAreaNames[0];
end;
function TfrmGestionCentres.CalendarIdFromName(const AName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FCalendarNames) do
    if SameText(FCalendarNames[I], AName) then
      Exit(FCalendarIds[I]);
  Result := 0;
end;
function TfrmGestionCentres.CalendarNameFromId(ACalendarId: Integer): string;
var
  I: Integer;
begin
  for I := 0 to High(FCalendarIds) do
    if FCalendarIds[I] = ACalendarId then
      Exit(FCalendarNames[I]);
  Result := FCalendarNames[0];
end;
procedure TfrmGestionCentres.LoadCentros;
var
  Q: TADOQuery;
  I, AreaId, CalId: Integer;
begin
  tvCentros.BeginUpdate;
  try
    tvCentros.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT c.CenterId, c.CodigoCentro, c.Titulo, c.Subtitulo, ' +
      '  ISNULL(c.AreaId, 0) AS AreaId, ' +
      '  c.EsSecuencial, c.MaxLanes, c.Orden, c.Visible, c.Habilitado, ' +
      '  ISNULL(c.ColorFondo, 0) AS ColorFondo, ' +
      '  ISNULL((SELECT MIN(cc.CalendarId) FROM FS_PL_CenterCalendar cc ' +
      '    WHERE cc.CodigoEmpresa = c.CodigoEmpresa AND cc.CenterId = c.CenterId), 0) AS CalendarId ' +
      'FROM FS_PL_Center c ' +
      'WHERE c.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY c.Orden, c.CenterId');
    try
      SetLength(FCenterIds, Q.RecordCount);
      SetLength(FColors, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        AreaId := Q.FieldByName('AreaId').AsInteger;
        CalId := Q.FieldByName('CalendarId').AsInteger;
        tvCentros.DataController.RecordCount := I + 1;
        tvCentros.DataController.Values[I, colCentroId.Index] := Q.FieldByName('CenterId').AsInteger;
        tvCentros.DataController.Values[I, colCentroCodigo.Index] := Q.FieldByName('CodigoCentro').AsString;
        tvCentros.DataController.Values[I, colCentroTitulo.Index] := Q.FieldByName('Titulo').AsString;
        tvCentros.DataController.Values[I, colCentroSubtitulo.Index] := Q.FieldByName('Subtitulo').AsString;
        tvCentros.DataController.Values[I, colCentroArea.Index] := AreaNameFromId(AreaId);
        tvCentros.DataController.Values[I, colCentroCalendario.Index] := CalendarNameFromId(CalId);
        tvCentros.DataController.Values[I, colCentroSecuencial.Index] := Q.FieldByName('EsSecuencial').AsBoolean;
        tvCentros.DataController.Values[I, colCentroMaxLanes.Index] := Q.FieldByName('MaxLanes').AsInteger;
        tvCentros.DataController.Values[I, colCentroOrden.Index] := Q.FieldByName('Orden').AsInteger;
        tvCentros.DataController.Values[I, colCentroVisible.Index] := Q.FieldByName('Visible').AsBoolean;
        tvCentros.DataController.Values[I, colCentroHabilitado.Index] := Q.FieldByName('Habilitado').AsBoolean;
        FCenterIds[I] := Q.FieldByName('CenterId').AsInteger;
        FColors[I] := Q.FieldByName('ColorFondo').AsInteger;
        RefreshColorCell(I);
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvCentros.EndUpdate;
  end;
end;
procedure TfrmGestionCentres.RefreshColorCell(ARecIdx: Integer);
begin
  if (ARecIdx < 0) or (ARecIdx > High(FColors)) then Exit;
  // La celda se pinta con OnCustomDrawCell; el valor de texto queda vacío.
  tvCentros.DataController.Values[ARecIdx, colCentroColor.Index] := '';
end;
function TfrmGestionCentres.GetSelectedIdx: Integer;
begin
  Result := tvCentros.Controller.FocusedRecordIndex;
end;
procedure TfrmGestionCentres.btnAddClick(Sender: TObject);
var
  Codigo, Titulo: string;
  Q: TADOQuery;
  NewId, Cnt: Integer;
begin
  Codigo := InputBox('Nuevo Centro', 'Código:', '');
  if Codigo = '' then Exit;
  Titulo := InputBox('Nuevo Centro', 'Título:', Codigo);
  if Titulo = '' then Exit;
  Exec('INSERT INTO FS_PL_Center (CodigoEmpresa, CodigoCentro, Titulo) VALUES (' +
    IntToStr(DMPlanner.CodigoEmpresa) + ', ' + QStr(Codigo) + ', ' + QStr(Titulo) + ')');
  Q := OpenQuery('SELECT MAX(CenterId) AS NewId FROM FS_PL_Center WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa));
  try
    NewId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;
  Cnt := tvCentros.DataController.RecordCount;
  tvCentros.DataController.RecordCount := Cnt + 1;
  tvCentros.DataController.Values[Cnt, colCentroId.Index] := NewId;
  tvCentros.DataController.Values[Cnt, colCentroCodigo.Index] := Codigo;
  tvCentros.DataController.Values[Cnt, colCentroTitulo.Index] := Titulo;
  tvCentros.DataController.Values[Cnt, colCentroSubtitulo.Index] := '';
  tvCentros.DataController.Values[Cnt, colCentroArea.Index] := FAreaNames[0];
  tvCentros.DataController.Values[Cnt, colCentroCalendario.Index] := FCalendarNames[0];
  tvCentros.DataController.Values[Cnt, colCentroSecuencial.Index] := False;
  tvCentros.DataController.Values[Cnt, colCentroMaxLanes.Index] := 0;
  tvCentros.DataController.Values[Cnt, colCentroOrden.Index] := 0;
  tvCentros.DataController.Values[Cnt, colCentroVisible.Index] := True;
  tvCentros.DataController.Values[Cnt, colCentroHabilitado.Index] := True;
  SetLength(FCenterIds, Cnt + 1);
  SetLength(FColors, Cnt + 1);
  FCenterIds[Cnt] := NewId;
  FColors[Cnt] := 0;
  RefreshColorCell(Cnt);
end;
procedure TfrmGestionCentres.btnDelClick(Sender: TObject);
var
  Idx, CenterId: Integer;
  CE: string;
begin
  Idx := GetSelectedIdx;
  if (Idx < 0) or (Idx > High(FCenterIds)) then Exit;
  if MessageDlg('¿Eliminar este centro?' + sLineBreak +
    'Se eliminará también su asignación de calendario.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  CenterId := FCenterIds[Idx];
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  Exec('DELETE FROM FS_PL_CenterCalendar WHERE CodigoEmpresa = ' + CE +
    ' AND CenterId = ' + IntToStr(CenterId));
  Exec('DELETE FROM FS_PL_Center WHERE CodigoEmpresa = ' + CE +
    ' AND CenterId = ' + IntToStr(CenterId));
  LoadCentros;
end;
procedure TfrmGestionCentres.btnSaveClick(Sender: TObject);
var
  I, CenterId, AreaId, CalId, MaxLanes, Orden: Integer;
  Codigo, Titulo, Subtitulo, AreaName, CalName: string;
  EsSeq, Visible, Habilitado: Boolean;
  CE: string;
  V: Variant;
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
  for I := 0 to tvCentros.DataController.RecordCount - 1 do
  begin
    if I > High(FCenterIds) then Continue;
    CenterId := FCenterIds[I];
    Codigo := VarToStr(tvCentros.DataController.Values[I, colCentroCodigo.Index]);
    Titulo := VarToStr(tvCentros.DataController.Values[I, colCentroTitulo.Index]);
    Subtitulo := VarToStr(tvCentros.DataController.Values[I, colCentroSubtitulo.Index]);
    AreaName := VarToStr(tvCentros.DataController.Values[I, colCentroArea.Index]);
    CalName := VarToStr(tvCentros.DataController.Values[I, colCentroCalendario.Index]);
    V := tvCentros.DataController.Values[I, colCentroSecuencial.Index];
    EsSeq := AsBool(V);
    MaxLanes := AsInt(tvCentros.DataController.Values[I, colCentroMaxLanes.Index]);
    Orden := AsInt(tvCentros.DataController.Values[I, colCentroOrden.Index]);
    Visible := AsBool(tvCentros.DataController.Values[I, colCentroVisible.Index]);
    Habilitado := AsBool(tvCentros.DataController.Values[I, colCentroHabilitado.Index]);
    AreaId := AreaIdFromName(AreaName);
    CalId := CalendarIdFromName(CalName);
    if (Codigo = '') or (Titulo = '') then Continue;
    Exec('UPDATE FS_PL_Center SET ' +
      'CodigoCentro = ' + QStr(Codigo) + ', ' +
      'Titulo = ' + QStr(Titulo) + ', ' +
      'Subtitulo = ' + QStr(Subtitulo) + ', ' +
      'AreaId = ' + QStrNullable(AreaId) + ', ' +
      'EsSecuencial = ' + IntToStr(Ord(EsSeq)) + ', ' +
      'MaxLanes = ' + IntToStr(MaxLanes) + ', ' +
      'Orden = ' + IntToStr(Orden) + ', ' +
      'Visible = ' + IntToStr(Ord(Visible)) + ', ' +
      'Habilitado = ' + IntToStr(Ord(Habilitado)) + ', ' +
      'ColorFondo = ' + IntToStr(FColors[I]) +
      ' WHERE CodigoEmpresa = ' + CE + ' AND CenterId = ' + IntToStr(CenterId));
    // Calendario: DELETE + INSERT (modelo 1:1 efectivo)
    Exec('DELETE FROM FS_PL_CenterCalendar WHERE CodigoEmpresa = ' + CE +
      ' AND CenterId = ' + IntToStr(CenterId));
    if CalId > 0 then
      Exec('INSERT INTO FS_PL_CenterCalendar (CodigoEmpresa, CenterId, CalendarId) VALUES (' +
        CE + ', ' + IntToStr(CenterId) + ', ' + IntToStr(CalId) + ')');
  end;
  ShowMessage('Centros guardados correctamente.');
  LoadCentros;
end;
procedure TfrmGestionCentres.colCentroColorButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  Idx: Integer;
begin
  Idx := GetSelectedIdx;
  if (Idx < 0) or (Idx > High(FColors)) then Exit;
  if FColors[Idx] <> 0 then
    ColorDialog.Color := TColor(FColors[Idx])
  else
    ColorDialog.Color := clWhite;
  if ColorDialog.Execute then
  begin
    FColors[Idx] := Integer(ColorDialog.Color);
    RefreshColorCell(Idx);
    tvCentros.DataController.Post(False);
    gridCentros.Invalidate;
  end;
end;
procedure TfrmGestionCentres.colCentroColorCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  RecIdx: Integer;
  C: TColor;
  R: TRect;
begin
  ADone := False;
  if AViewInfo.GridRecord = nil then Exit;
  RecIdx := AViewInfo.GridRecord.RecordIndex;
  if (RecIdx < 0) or (RecIdx > High(FColors)) then Exit;
  if FColors[RecIdx] = 0 then Exit;
  C := TColor(FColors[RecIdx]);
  R := AViewInfo.ContentBounds;
  // Dejar espacio para el botón ellipsis a la derecha (~20px)
  InflateRect(R, -2, -2);
  Dec(R.Right, 22);
  ACanvas.Brush.Color := C;
  ACanvas.FillRect(R);
  ADone := True;
end;
end.
