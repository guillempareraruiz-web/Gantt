unit uGestionCentres;
interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxCalc, cxCalendar,
  cxDropDownEdit, cxSpinEdit, cxButtonEdit,
  System.NetEncoding, System.Generics.Collections,
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
    btnConfigurarColumnas: TButton;
    btnAsignarMaquinas: TButton;
    gridCentros: TcxGrid;
    tvCentros: TcxGridTableView;
    colCentroId: TcxGridColumn;
    colCentroCodigo: TcxGridColumn;
    colCentroTitulo: TcxGridColumn;
    colCentroSubtitulo: TcxGridColumn;
    colCentroTipo: TcxGridColumn;
    colCentroUbicacion: TcxGridColumn;
    colCentroArea: TcxGridColumn;
    colCentroCalendario: TcxGridColumn;
    colCentroSecuencial: TcxGridColumn;
    colCentroMaxLanes: TcxGridColumn;
    colCentroEfficiency: TcxGridColumn;
    colCentroCoste: TcxGridColumn;
    colCentroSetup: TcxGridColumn;
    colCentroHorizon: TcxGridColumn;
    colCentroOrden: TcxGridColumn;
    colCentroVisible: TcxGridColumn;
    colCentroHabilitado: TcxGridColumn;
    colCentroColor: TcxGridColumn;
    lvCentros: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    ColorDialog: TColorDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnConfigurarColumnasClick(Sender: TObject);
    procedure btnAsignarMaquinasClick(Sender: TObject);
    procedure colCentroColorButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure colCentroColorCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure tvCentrosCustomEditValueChanged(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
  private
    type
      TCenterCustomCol = record
        ColumnKey: string;
        Caption: string;
        DataType: Char;
        OrderDefault: Integer;
        WidthDefault: Integer;
      end;
  private
    FCenterIds: TArray<Integer>;
    FColors: TArray<Integer>;
    FAreaIds: TArray<Integer>;
    FAreaNames: TArray<string>;
    FCalendarIds: TArray<Integer>;
    FCalendarNames: TArray<string>;
    FCustomCols: TArray<TCenterCustomCol>;
    FCustomColumns: TArray<TcxGridColumn>;
    FColKeyByTag: TDictionary<Integer, string>;
    procedure LoadAreas;
    procedure LoadCalendars;
    procedure LoadCustomColumnDefs;
    procedure BuildCustomColumns;
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
    function UserLogin: string;
    procedure RefreshColorCell(ARecIdx: Integer);
    function EncodeFieldValue(ADataType: Char; const V: Variant): string;
    function DecodeFieldValue(ADataType: Char; const S: string): Variant;
    procedure SaveCustomFieldValue(ACenterId: Integer; const FieldKey: string;
      ADataType: Char; const Value: Variant);
  end;
implementation
{$R *.dfm}
uses
  uDMPlanner, uLogin, uCentresCustomCols, uAsignarMaquinasCentro;

const
  CENTROS_GRID_ID = 'CENTROS';
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
procedure TfrmGestionCentres.FormDestroy(Sender: TObject);
begin
  FColKeyByTag.Free;
end;

procedure TfrmGestionCentres.FormCreate(Sender: TObject);
begin
  FColKeyByTag := TDictionary<Integer, string>.Create;
  btnConfigurarColumnas.Visible := uLogin.IsAdmin;

  LoadAreas;
  LoadCalendars;
  SetupCombos;
  LoadCustomColumnDefs;
  BuildCustomColumns;
  tvCentros.OnEditValueChanged := tvCentrosCustomEditValueChanged;
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
  I, J, AreaId, CalId: Integer;
  Sel, Joins, Alias, FldName, Key: string;
  Col: TcxGridColumn;
  V: Variant;
begin
  tvCentros.BeginUpdate;
  try
    tvCentros.DataController.RecordCount := 0;

    // JOIN dinamico para columnas custom: cada una se trae como X_<key>.
    Sel := '';
    Joins := '';
    for I := 0 to High(FCustomCols) do
    begin
      Alias := 'x' + IntToStr(I);
      Sel := Sel + ', ' + Alias + '.FieldValue AS [X_' + FCustomCols[I].ColumnKey + ']';
      Joins := Joins +
        ' LEFT JOIN FS_PL_Center_Extra ' + Alias +
        '   ON ' + Alias + '.CodigoEmpresa = c.CodigoEmpresa' +
        '  AND ' + Alias + '.CenterId = c.CenterId' +
        '  AND ' + Alias + '.FieldKey = ' + QStr(FCustomCols[I].ColumnKey);
    end;

    Q := OpenQuery(
      'SELECT c.CenterId, c.CodigoCentro, c.Titulo, c.Subtitulo, ' +
      '  ISNULL(c.AreaId, 0) AS AreaId, ' +
      '  c.EsSecuencial, c.MaxLanes, c.Orden, c.Visible, c.Habilitado, ' +
      '  ISNULL(c.ColorFondo, 0) AS ColorFondo, ' +
      '  c.TipoCentro, c.Ubicacion, c.EfficiencyFactor, c.CostPerHour, ' +
      '  c.SetupTimeDefault, c.PlanningHorizonDays, ' +
      '  ISNULL((SELECT MIN(cc.CalendarId) FROM FS_PL_CenterCalendar cc ' +
      '    WHERE cc.CodigoEmpresa = c.CodigoEmpresa AND cc.CenterId = c.CenterId), 0) AS CalendarId' +
      Sel + ' ' +
      'FROM FS_PL_Center c ' + Joins +
      ' WHERE c.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
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
        tvCentros.DataController.Values[I, colCentroTipo.Index] := Q.FieldByName('TipoCentro').AsString;
        tvCentros.DataController.Values[I, colCentroUbicacion.Index] := Q.FieldByName('Ubicacion').AsString;
        tvCentros.DataController.Values[I, colCentroEfficiency.Index] := Q.FieldByName('EfficiencyFactor').AsFloat;
        tvCentros.DataController.Values[I, colCentroCoste.Index] := Q.FieldByName('CostPerHour').AsFloat;
        tvCentros.DataController.Values[I, colCentroSetup.Index] := Q.FieldByName('SetupTimeDefault').AsInteger;
        tvCentros.DataController.Values[I, colCentroHorizon.Index] := Q.FieldByName('PlanningHorizonDays').AsInteger;
        tvCentros.DataController.Values[I, colCentroOrden.Index] := Q.FieldByName('Orden').AsInteger;
        tvCentros.DataController.Values[I, colCentroVisible.Index] := Q.FieldByName('Visible').AsBoolean;
        tvCentros.DataController.Values[I, colCentroHabilitado.Index] := Q.FieldByName('Habilitado').AsBoolean;
        FCenterIds[I] := Q.FieldByName('CenterId').AsInteger;
        FColors[I] := Q.FieldByName('ColorFondo').AsInteger;
        RefreshColorCell(I);

        // Volcar valores de columnas custom al grid
        for J := 0 to High(FCustomCols) do
        begin
          FldName := 'X_' + FCustomCols[J].ColumnKey;
          if Q.FindField(FldName) <> nil then
          begin
            // Localizar la columna del grid por su key
            Col := nil;
            if FColKeyByTag.TryGetValue(FCustomColumns[J].Tag, Key) then
              Col := FCustomColumns[J];
            if Col = nil then Continue;

            if Q.FieldByName(FldName).IsNull then
              tvCentros.DataController.Values[I, Col.Index] := Null
            else
            begin
              V := DecodeFieldValue(FCustomCols[J].DataType,
                                    Q.FieldByName(FldName).AsString);
              tvCentros.DataController.Values[I, Col.Index] := V;
            end;
          end;
        end;

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
  tvCentros.DataController.Values[Cnt, colCentroTipo.Index] := '';
  tvCentros.DataController.Values[Cnt, colCentroUbicacion.Index] := '';
  tvCentros.DataController.Values[Cnt, colCentroEfficiency.Index] := 1.0;
  tvCentros.DataController.Values[Cnt, colCentroCoste.Index] := 0.0;
  tvCentros.DataController.Values[Cnt, colCentroSetup.Index] := 0;
  tvCentros.DataController.Values[Cnt, colCentroHorizon.Index] := 90;
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
  I, CenterId, AreaId, CalId, MaxLanes, Orden, SetupDef, Horizon: Integer;
  Codigo, Titulo, Subtitulo, AreaName, CalName, Tipo, Ubicacion: string;
  EsSeq, Visible, Habilitado: Boolean;
  Eff, Coste: Double;
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
  function AsFloat(AV: Variant; ADef: Double): Double;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADef else Result := Double(AV);
  end;
  function AsStr(AV: Variant): string;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := '' else Result := VarToStr(AV);
  end;
  function QStrNullableStr(const S: string): string;
  begin
    if Trim(S) = '' then Result := 'NULL'
    else Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
  end;
  function QDecimal(D: Double): string;
  begin
    Result := FloatToStr(D, TFormatSettings.Invariant);
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
    Tipo := AsStr(tvCentros.DataController.Values[I, colCentroTipo.Index]);
    Ubicacion := AsStr(tvCentros.DataController.Values[I, colCentroUbicacion.Index]);
    Eff := AsFloat(tvCentros.DataController.Values[I, colCentroEfficiency.Index], 1.0);
    Coste := AsFloat(tvCentros.DataController.Values[I, colCentroCoste.Index], 0);
    SetupDef := AsInt(tvCentros.DataController.Values[I, colCentroSetup.Index]);
    Horizon := AsInt(tvCentros.DataController.Values[I, colCentroHorizon.Index]);
    if Horizon <= 0 then Horizon := 90;
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
      'TipoCentro = ' + QStrNullableStr(Tipo) + ', ' +
      'Ubicacion = ' + QStrNullableStr(Ubicacion) + ', ' +
      'EfficiencyFactor = ' + QDecimal(Eff) + ', ' +
      'CostPerHour = ' + QDecimal(Coste) + ', ' +
      'SetupTimeDefault = ' + IntToStr(SetupDef) + ', ' +
      'PlanningHorizonDays = ' + IntToStr(Horizon) + ', ' +
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

// ===========================================================================
// CAMPS CUSTOM
// ===========================================================================

function TfrmGestionCentres.UserLogin: string;
begin
  Result := uLogin.CurrentSession.Login;
  if Result = '' then Result := '(anon)';
end;

procedure TfrmGestionCentres.LoadCustomColumnDefs;
var
  Q: TADOQuery;
  L: TList<TCenterCustomCol>;
  Def: TCenterCustomCol;
  DT: string;
begin
  L := TList<TCenterCustomCol>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ColumnKey, Caption, DataType, OrderDefault, WidthDefault ' +
      'FROM FS_PL_Cfg_GridColumns ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      '  AND GridId = ''' + CENTROS_GRID_ID + '''' +
      '  AND IsCustomField = 1 AND Activo = 1 ' +
      'ORDER BY OrderDefault, ColumnKey';
    Q.Open;
    while not Q.Eof do
    begin
      Def.ColumnKey := Q.FieldByName('ColumnKey').AsString;
      Def.Caption   := Q.FieldByName('Caption').AsString;
      DT := Q.FieldByName('DataType').AsString;
      if DT = '' then Def.DataType := 'S' else Def.DataType := DT[1];
      Def.OrderDefault := Q.FieldByName('OrderDefault').AsInteger;
      Def.WidthDefault := Q.FieldByName('WidthDefault').AsInteger;
      L.Add(Def);
      Q.Next;
    end;
    FCustomCols := L.ToArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

procedure TfrmGestionCentres.BuildCustomColumns;
var
  I: Integer;
  Col: TcxGridColumn;
  Cols: TList<TcxGridColumn>;
  W: Integer;
begin
  // Eliminar columnas custom previas (en caso de recarga tras gestionar)
  for I := High(FCustomColumns) downto 0 do
    if FCustomColumns[I] <> nil then
      FCustomColumns[I].Free;
  SetLength(FCustomColumns, 0);
  FColKeyByTag.Clear;

  Cols := TList<TcxGridColumn>.Create;
  tvCentros.BeginUpdate;
  try
    for I := 0 to High(FCustomCols) do
    begin
      Col := tvCentros.CreateColumn;
      Col.Caption := FCustomCols[I].Caption + '  '#9998;
      Col.HeaderHint := 'Campo personalizado editable. Doble clic para modificar el valor.';
      Col.Name := 'colx_' + FCustomCols[I].ColumnKey;
      W := FCustomCols[I].WidthDefault;
      if W < 30 then W := 120;
      Col.Width := W;
      case UpCase(FCustomCols[I].DataType) of
        'N': Col.PropertiesClass := TcxCalcEditProperties;
        'D': Col.PropertiesClass := TcxDateEditProperties;
        'B': Col.PropertiesClass := TcxCheckBoxProperties;
      else
        Col.PropertiesClass := TcxTextEditProperties;
      end;
      Col.Options.Editing := True;
      Col.Tag := tvCentros.ColumnCount - 1;
      FColKeyByTag.Add(Col.Tag, 'X:' + FCustomCols[I].ColumnKey);
      Cols.Add(Col);
    end;
    FCustomColumns := Cols.ToArray;

    if Length(FCustomCols) > 0 then
    begin
      tvCentros.OptionsData.Editing := True;
      tvCentros.OptionsSelection.CellSelect := True;
      tvCentros.OptionsBehavior.CellHints := True;
      tvCentros.OptionsBehavior.ColumnHeaderHints := True;
    end;
  finally
    tvCentros.EndUpdate;
    Cols.Free;
  end;
end;

function TfrmGestionCentres.EncodeFieldValue(ADataType: Char; const V: Variant): string;
var
  D: Double;
  Dt: TDateTime;
begin
  Result := '';
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  case UpCase(ADataType) of
    'N':
      begin
        D := V;
        Result := FloatToStr(D, TFormatSettings.Invariant);
      end;
    'D':
      begin
        Dt := V;
        Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', Dt);
      end;
    'B':
      begin
        if Boolean(V) then Result := '1' else Result := '0';
      end;
  else
    Result := VarToStr(V);
  end;
end;

function TfrmGestionCentres.DecodeFieldValue(ADataType: Char; const S: string): Variant;
var
  D: Double;
  Dt: TDateTime;
begin
  Result := Null;
  if S = '' then Exit;
  case UpCase(ADataType) of
    'N':
      begin
        if TryStrToFloat(S, D, TFormatSettings.Invariant) then Result := D
        else if TryStrToFloat(S, D) then Result := D
        else Result := Null;
      end;
    'D':
      begin
        if TryStrToDateTime(S, Dt, TFormatSettings.Invariant) then Result := Dt
        else if TryStrToDateTime(S, Dt) then Result := Dt
        else Result := Null;
      end;
    'B':
      Result := (S = '1') or SameText(S, 'true');
  else
    Result := S;
  end;
end;

procedure TfrmGestionCentres.SaveCustomFieldValue(ACenterId: Integer;
  const FieldKey: string; ADataType: Char; const Value: Variant);
var
  Cmd: TADOCommand;
  IsEmpty: Boolean;
  StrVal: string;
begin
  if ACenterId <= 0 then Exit;

  IsEmpty := VarIsNull(Value) or VarIsEmpty(Value);
  if not IsEmpty then
  begin
    StrVal := EncodeFieldValue(ADataType, Value);
    if Trim(StrVal) = '' then IsEmpty := True;
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    if IsEmpty then
    begin
      Cmd.CommandText :=
        'DELETE FROM FS_PL_Center_Extra ' +
        'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
        '  AND CenterId = ' + IntToStr(ACenterId) +
        '  AND FieldKey = ' + QStr(FieldKey) +
        '  AND Source = ''MANUAL''';
      Cmd.Execute;
    end
    else
    begin
      Cmd.CommandText :=
        'MERGE FS_PL_Center_Extra AS T ' +
        'USING (SELECT ' + IntToStr(DMPlanner.CodigoEmpresa) + ' AS CodigoEmpresa, ' +
        IntToStr(ACenterId) + ' AS CenterId, ' +
        QStr(FieldKey) + ' AS FieldKey, :V AS FieldValue, :U AS UpdatedBy) AS S ' +
        '  ON T.CodigoEmpresa = S.CodigoEmpresa AND T.CenterId = S.CenterId AND T.FieldKey = S.FieldKey ' +
        'WHEN MATCHED THEN UPDATE SET ' +
        '  FieldValue = S.FieldValue, Source = ''MANUAL'', ' +
        '  UpdatedBy = S.UpdatedBy, UpdatedAt = SYSUTCDATETIME() ' +
        'WHEN NOT MATCHED THEN INSERT (CodigoEmpresa, CenterId, FieldKey, FieldValue, Source, UpdatedBy, UpdatedAt) ' +
        '  VALUES (S.CodigoEmpresa, S.CenterId, S.FieldKey, S.FieldValue, ''MANUAL'', S.UpdatedBy, SYSUTCDATETIME());';
      Cmd.Parameters.Clear;
      with Cmd.Parameters.AddParameter do
      begin
        Name := 'V';
        DataType := ftWideMemo;
        Direction := pdInput;
        Value := StrVal;
      end;
      with Cmd.Parameters.AddParameter do
      begin
        Name := 'U';
        DataType := ftWideString;
        Direction := pdInput;
        Value := UserLogin;
      end;
      Cmd.Execute;
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmGestionCentres.tvCentrosCustomEditValueChanged(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem);
var
  Key, ColumnKey: string;
  RecIdx, I: Integer;
  CenterId: Integer;
  ColDef: TCenterCustomCol;
  Found: Boolean;
  NewVal: Variant;
begin
  if AItem = nil then Exit;
  if not FColKeyByTag.TryGetValue(AItem.Tag, Key) then Exit;
  if Copy(Key, 1, 2) <> 'X:' then Exit;

  ColumnKey := Copy(Key, 3, MaxInt);
  Found := False;
  ColDef := Default(TCenterCustomCol);
  for I := 0 to High(FCustomCols) do
    if SameText(FCustomCols[I].ColumnKey, ColumnKey) then
    begin
      ColDef := FCustomCols[I];
      Found := True;
      Break;
    end;
  if not Found then Exit;

  RecIdx := Sender.Controller.FocusedRecordIndex;
  if (RecIdx < 0) or (RecIdx > High(FCenterIds)) then Exit;
  CenterId := FCenterIds[RecIdx];
  if CenterId <= 0 then Exit;

  // Capturar valor del editor en vivo
  NewVal := Null;
  if (Sender.Controller <> nil) and
     (Sender.Controller.EditingController <> nil) and
     (Sender.Controller.EditingController.Edit <> nil) then
    NewVal := Sender.Controller.EditingController.Edit.EditingValue;
  if VarIsNull(NewVal) or VarIsEmpty(NewVal) then
    NewVal := AItem.EditValue;

  try
    SaveCustomFieldValue(CenterId, ColDef.ColumnKey, ColDef.DataType, NewVal);
  except
    on E: Exception do
      ShowMessage('No se pudo guardar el valor: ' + E.Message);
  end;
end;

procedure TfrmGestionCentres.btnConfigurarColumnasClick(Sender: TObject);
begin
  if uCentresCustomCols.TfrmCentresCustomCols.Execute then
  begin
    LoadCustomColumnDefs;
    BuildCustomColumns;
    LoadCentros;
  end;
end;

procedure TfrmGestionCentres.btnAsignarMaquinasClick(Sender: TObject);
var
  Idx, CenterId: Integer;
  Caption: string;
begin
  Idx := GetSelectedIdx;
  if (Idx < 0) or (Idx > High(FCenterIds)) then
  begin
    ShowMessage('Selecciona primero un centro.');
    Exit;
  end;
  CenterId := FCenterIds[Idx];
  Caption := VarToStr(tvCentros.DataController.Values[Idx, colCentroCodigo.Index]) +
             ' - ' + VarToStr(tvCentros.DataController.Values[Idx, colCentroTitulo.Index]);
  TfrmAsignarMaquinasCentro.Execute(CenterId, Caption);
end;

end.
