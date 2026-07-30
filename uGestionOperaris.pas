unit uGestionOperaris;
interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxCalc, cxCalendar, cxDropDownEdit, cxButtons,
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
    pnlToolbar: TPanel;
    btnAdd: TcxButton;
    btnDel: TcxButton;
    btnSave: TcxButton;
    btnDepartamentos: TcxButton;
    btnPolivalencia: TcxButton;
    btnMatriz: TcxButton;
    btnConfigurarColumnas: TcxButton;
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
    procedure FormShow(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDepartamentosClick(Sender: TObject);
    procedure btnPolivalenciaClick(Sender: TObject);
    procedure btnMatrizClick(Sender: TObject);
    procedure btnConfigurarColumnasClick(Sender: TObject);
    procedure tvOperarisGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
  private
    type
      TOperarioCustomCol = record
        ColumnKey: string;
        Caption: string;
        DataType: Char;
        OrderDefault: Integer;
        WidthDefault: Integer;
      end;
  private
    FOperatorIds: TArray<Integer>;
    FCalendarIds: TArray<Integer>;
    FCalendarNames: TArray<string>;
    FCustomCols: TArray<TOperarioCustomCol>;
    FCustomColumns: TArray<TcxGridColumn>;
    FStyleInactivo: TcxStyle;   // fons vermell clar per operaris no actius
    FLoaded: Boolean;           // la carga pesada solo se hace una vez, en OnShow
    procedure LoadCalendars;
    procedure SetupCombos;
    procedure LoadCustomColumnDefs;
    procedure BuildCustomColumns;
    procedure LoadOperarios;
    function GetSelectedIdx: Integer;
    function SelectedOperatorId: Integer;
    function SelectedOperatorName: string;
    function CalendarIdFromName(const AName: string): Integer;
    function CalendarNameFromId(ACalendarId: Integer): string;
    function GetDeptsCSV(AOperatorId: Integer): string;
    function GetSkillsCount(AOperatorId: Integer): Integer;
    // Precarga en bloque (1 consulta cada una) para evitar N+1 al abrir el form.
    function LoadAllDeptsCSV: TDictionary<Integer, string>;
    function LoadAllSkillsCount: TDictionary<Integer, Integer>;
    function OperatorIdOfRow(ARecIdx: Integer): Integer;
    procedure RefreshDeptsCell(ARecIdx: Integer);
    procedure RefreshSkillsCell(ARecIdx: Integer);
    function Exec(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
    function QStrNullable(AId: Integer): string;
    function UserLogin: string;
    function EncodeFieldValue(ADataType: Char; const V: Variant): string;
    function DecodeFieldValue(ADataType: Char; const S: string): Variant;
    procedure SaveCustomFieldValue(AOperatorId: Integer; const FieldKey: string;
      ADataType: Char; const Value: Variant);
    procedure SaveCustomFieldsForRow(AOperatorId: Integer; ARecIdx: Integer);
  end;
implementation
{$R *.dfm}
uses
  uDMPlanner, uAsignarDepartamentos,
  uOperarioPolivalencia, uMatrizPolivalencia, uOperariosCustomCols, uLogin,
  uHelpViewer, uBusyDialog, Main;

const
  OPERARIOS_GRID_ID = 'OPERARIOS';
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
  btnConfigurarColumnas.Visible := uLogin.IsAdmin;

  // Estilo de fila para operarios NO activos: fondo rojo claro (BGR). El resto
  // queda blanco. IMPRESCINDIBLE NativeStyle=False (el skin nativo ignora Color).
  tvOperaris.LookAndFeel.NativeStyle := False;
  FStyleInactivo := TcxStyle.Create(Self);
  FStyleInactivo.Color := $00CACAFF;          // rojo claro
  FStyleInactivo.TextColor := clWindowText;
  tvOperaris.Styles.OnGetContentStyle := tvOperarisGetContentStyle;

  // Boton '?' en el caption (requiere BorderStyle=bsDialog) + F1 = ayuda.
  THelpViewer.InstallHelp(Self, 'uGestionOperaris', 'Gesti'#243'n de Operarios');
end;

procedure TfrmGestionOperaris.FormShow(Sender: TObject);
begin
  // La carga toca varias tablas: hacerla en OnShow (con el form ya visible y
  // un aviso de espera) en vez de en OnCreate, que dejaba la pantalla bloqueada
  // y sin repintar hasta terminar.
  if FLoaded then Exit;
  FLoaded := True;
  RunBusy(Self, 'Cargando operarios...',
    procedure
    begin
      LoadCalendars;
      SetupCombos;
      LoadCustomColumnDefs;
      BuildCustomColumns;
      LoadOperarios;
    end);
end;

procedure TfrmGestionOperaris.tvOperarisGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  V: Variant;
begin
  if ARecord = nil then Exit;
  V := ARecord.Values[colOpActivo.Index];
  // Activo = False (y no nulo) -> fila roja. Cualquier otro caso: blanco.
  if (not VarIsNull(V)) and (not VarIsEmpty(V)) and (not Boolean(V)) then
    AStyle := FStyleInactivo;
end;

function TfrmGestionOperaris.UserLogin: string;
begin
  Result := uLogin.CurrentSession.Login;
  if Result = '' then Result := '(anon)';
end;

procedure TfrmGestionOperaris.LoadCustomColumnDefs;
var
  Q: TADOQuery;
  L: TList<TOperarioCustomCol>;
  Def: TOperarioCustomCol;
  DT: string;
begin
  L := TList<TOperarioCustomCol>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ColumnKey, Caption, DataType, OrderDefault, WidthDefault ' +
      'FROM FS_PL_Cfg_GridColumns ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      '  AND GridId = ''' + OPERARIOS_GRID_ID + '''' +
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

procedure TfrmGestionOperaris.BuildCustomColumns;
var
  I, W: Integer;
  Col: TcxGridColumn;
  Cols: TList<TcxGridColumn>;
begin
  for I := High(FCustomColumns) downto 0 do
    if FCustomColumns[I] <> nil then
      FCustomColumns[I].Free;
  SetLength(FCustomColumns, 0);

  Cols := TList<TcxGridColumn>.Create;
  tvOperaris.BeginUpdate;
  try
    for I := 0 to High(FCustomCols) do
    begin
      Col := tvOperaris.CreateColumn;
      Col.Caption := FCustomCols[I].Caption + '  '#9998;
      Col.HeaderHint := 'Campo personalizado editable. Se guarda al pulsar "Guardar cambios".';
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
      Cols.Add(Col);
    end;
    FCustomColumns := Cols.ToArray;

    if Length(FCustomCols) > 0 then
    begin
      tvOperaris.OptionsData.Editing := True;
      tvOperaris.OptionsSelection.CellSelect := True;
      tvOperaris.OptionsBehavior.CellHints := True;
      tvOperaris.OptionsBehavior.ColumnHeaderHints := True;
    end;
  finally
    tvOperaris.EndUpdate;
    Cols.Free;
  end;
end;

function TfrmGestionOperaris.EncodeFieldValue(ADataType: Char;
  const V: Variant): string;
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

function TfrmGestionOperaris.DecodeFieldValue(ADataType: Char;
  const S: string): Variant;
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

procedure TfrmGestionOperaris.SaveCustomFieldValue(AOperatorId: Integer;
  const FieldKey: string; ADataType: Char; const Value: Variant);
var
  Cmd: TADOCommand;
  IsEmpty: Boolean;
  StrVal: string;
begin
  if AOperatorId <= 0 then Exit;
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
        'DELETE FROM FS_PL_Operario_Extra ' +
        'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
        '  AND OperatorId = ' + IntToStr(AOperatorId) +
        '  AND FieldKey = ' + QStr(FieldKey) +
        '  AND Source = ''MANUAL''';
      Cmd.Execute;
    end
    else
    begin
      Cmd.CommandText :=
        'MERGE FS_PL_Operario_Extra AS T ' +
        'USING (SELECT ' + IntToStr(DMPlanner.CodigoEmpresa) + ' AS CodigoEmpresa, ' +
        IntToStr(AOperatorId) + ' AS OperatorId, ' +
        QStr(FieldKey) + ' AS FieldKey, :V AS FieldValue, :U AS UpdatedBy) AS S ' +
        '  ON T.CodigoEmpresa = S.CodigoEmpresa AND T.OperatorId = S.OperatorId AND T.FieldKey = S.FieldKey ' +
        'WHEN MATCHED THEN UPDATE SET ' +
        '  FieldValue = S.FieldValue, Source = ''MANUAL'', ' +
        '  UpdatedBy = S.UpdatedBy, UpdatedAt = SYSUTCDATETIME() ' +
        'WHEN NOT MATCHED THEN INSERT (CodigoEmpresa, OperatorId, FieldKey, FieldValue, Source, UpdatedBy, UpdatedAt) ' +
        '  VALUES (S.CodigoEmpresa, S.OperatorId, S.FieldKey, S.FieldValue, ''MANUAL'', S.UpdatedBy, SYSUTCDATETIME());';
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

procedure TfrmGestionOperaris.SaveCustomFieldsForRow(AOperatorId: Integer;
  ARecIdx: Integer);
var
  J: Integer;
  V: Variant;
begin
  if AOperatorId <= 0 then Exit;
  for J := 0 to High(FCustomCols) do
  begin
    if J > High(FCustomColumns) then Continue;
    V := tvOperaris.DataController.Values[ARecIdx, FCustomColumns[J].Index];
    SaveCustomFieldValue(AOperatorId, FCustomCols[J].ColumnKey,
                         FCustomCols[J].DataType, V);
  end;
end;

procedure TfrmGestionOperaris.btnConfigurarColumnasClick(Sender: TObject);
begin
  if uOperariosCustomCols.TfrmOperariosCustomCols.Execute then
  begin
    LoadCustomColumnDefs;
    BuildCustomColumns;
    LoadOperarios;
  end;
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
  // Modelo nuevo: contar habilidades en FS_PL_OperarioHabilidad
  Q := OpenQuery('SELECT COUNT(*) AS N FROM FS_PL_OperarioHabilidad WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) + ' AND OperatorId = ' + IntToStr(AOperatorId));
  try
    if not Q.Eof then Result := Q.FieldByName('N').AsInteger;
  finally
    Q.Free;
  end;
end;
function TfrmGestionOperaris.LoadAllDeptsCSV: TDictionary<Integer, string>;
var
  Q: TADOQuery;
  OpId: Integer;
  S, Prev: string;
begin
  Result := TDictionary<Integer, string>.Create;
  try
    // Una sola consulta para todos los operarios; se agrupa en Pascal por orden.
    Q := OpenQuery(
      'SELECT od.OperatorId, d.Nombre FROM FS_PL_OperatorDepartment od ' +
      'INNER JOIN FS_PL_Department d ON d.CodigoEmpresa = od.CodigoEmpresa ' +
      '  AND d.DepartmentId = od.DepartmentId ' +
      'WHERE od.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY od.OperatorId, d.Nombre');
    try
      while not Q.Eof do
      begin
        OpId := Q.FieldByName('OperatorId').AsInteger;
        S := Q.FieldByName('Nombre').AsString;
        if Result.TryGetValue(OpId, Prev) and (Prev <> '') then
          Result.AddOrSetValue(OpId, Prev + ', ' + S)
        else
          Result.AddOrSetValue(OpId, S);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TfrmGestionOperaris.LoadAllSkillsCount: TDictionary<Integer, Integer>;
var
  Q: TADOQuery;
begin
  Result := TDictionary<Integer, Integer>.Create;
  try
    Q := OpenQuery(
      'SELECT OperatorId, COUNT(*) AS N FROM FS_PL_OperarioHabilidad ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' GROUP BY OperatorId');
    try
      while not Q.Eof do
      begin
        Result.AddOrSetValue(Q.FieldByName('OperatorId').AsInteger,
                             Q.FieldByName('N').AsInteger);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TfrmGestionOperaris.LoadOperarios;
var
  Q: TADOQuery;
  I, J, OpId, CalId, N: Integer;
  Sel, Joins, Alias, FldName, S: string;
  V: Variant;
  Depts: TDictionary<Integer, string>;
  Skills: TDictionary<Integer, Integer>;
begin
  // JOIN dinamico para columnas custom: cada una como X_<key>.
  Sel := '';
  Joins := '';
  for I := 0 to High(FCustomCols) do
  begin
    Alias := 'x' + IntToStr(I);
    Sel := Sel + ', ' + Alias + '.FieldValue AS [X_' + FCustomCols[I].ColumnKey + ']';
    Joins := Joins +
      ' LEFT JOIN FS_PL_Operario_Extra ' + Alias +
      '   ON ' + Alias + '.CodigoEmpresa = o.CodigoEmpresa' +
      '  AND ' + Alias + '.OperatorId = o.OperatorId' +
      '  AND ' + Alias + '.FieldKey = ' + QStr(FCustomCols[I].ColumnKey);
  end;

  Depts := LoadAllDeptsCSV;
  Skills := nil;
  tvOperaris.BeginUpdate;
  try
    Skills := LoadAllSkillsCount;
    tvOperaris.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT o.OperatorId, o.Nombre, ISNULL(o.CalendarId, 0) AS CalendarId, o.Activo' + Sel +
      ' FROM FS_PL_Operator o' + Joins +
      ' WHERE o.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      ' ORDER BY o.Nombre');
    try
      SetLength(FOperatorIds, Q.RecordCount);
      // Dimensionar una sola vez: asignar RecordCount fila a fila es O(n^2).
      tvOperaris.DataController.RecordCount := Q.RecordCount;
      I := 0;
      while not Q.Eof do
      begin
        OpId := Q.FieldByName('OperatorId').AsInteger;
        CalId := Q.FieldByName('CalendarId').AsInteger;
        if I >= tvOperaris.DataController.RecordCount then
          tvOperaris.DataController.RecordCount := I + 1;
        tvOperaris.DataController.Values[I, colOpId.Index] := OpId;
        tvOperaris.DataController.Values[I, colOpNombre.Index] := Q.FieldByName('Nombre').AsString;
        tvOperaris.DataController.Values[I, colOpCalendario.Index] := CalendarNameFromId(CalId);
        tvOperaris.DataController.Values[I, colOpActivo.Index] := Q.FieldByName('Activo').AsBoolean;
        if not Depts.TryGetValue(OpId, S) then S := '';
        tvOperaris.DataController.Values[I, colOpDepartamentos.Index] := S;
        if not Skills.TryGetValue(OpId, N) then N := 0;
        tvOperaris.DataController.Values[I, colOpCapacitaciones.Index] := N;
        FOperatorIds[I] := OpId;

        for J := 0 to High(FCustomCols) do
        begin
          FldName := 'X_' + FCustomCols[J].ColumnKey;
          if Q.FindField(FldName) <> nil then
          begin
            if Q.FieldByName(FldName).IsNull then
              tvOperaris.DataController.Values[I, FCustomColumns[J].Index] := Null
            else
            begin
              V := DecodeFieldValue(FCustomCols[J].DataType,
                                    Q.FieldByName(FldName).AsString);
              tvOperaris.DataController.Values[I, FCustomColumns[J].Index] := V;
            end;
          end;
        end;

        Inc(I);
        Q.Next;
      end;
      // RecordCount de ADO puede sobrestimar; ajustar al total real leido.
      if tvOperaris.DataController.RecordCount <> I then
        tvOperaris.DataController.RecordCount := I;
      SetLength(FOperatorIds, I);
    finally
      Q.Free;
    end;
  finally
    tvOperaris.EndUpdate;
    Skills.Free;
    Depts.Free;
  end;
end;
function TfrmGestionOperaris.GetSelectedIdx: Integer;
begin
  Result := tvOperaris.Controller.FocusedRecordIndex;
end;
// OperatorId de la PROPIA celda del grid, NO de FOperatorIds[Idx]: el indice de
// fila es el de la fila VISIBLE (cambia si el usuario ordena por una columna)
// mientras que FOperatorIds va en orden de carga (ORDER BY o.Nombre). Con el
// grid ordenado el indice apunta a OTRO operario: los dialogos de departamentos
// y polivalencia escribian sobre el operario equivocado (y mostraban el nombre
// correcto con el id de otro).
function TfrmGestionOperaris.SelectedOperatorId: Integer;
var
  Idx: Integer;
  V: Variant;
begin
  Result := -1;
  Idx := GetSelectedIdx;
  if Idx < 0 then Exit;
  V := tvOperaris.DataController.Values[Idx, colOpId.Index];
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  Result := V;
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
// Id de la PROPIA fila (ver SelectedOperatorId): si no, con el grid ordenado la
// celda mostraba los departamentos / capacitaciones de OTRO operario.
function TfrmGestionOperaris.OperatorIdOfRow(ARecIdx: Integer): Integer;
var
  V: Variant;
begin
  Result := 0;
  if ARecIdx < 0 then Exit;
  V := tvOperaris.DataController.Values[ARecIdx, colOpId.Index];
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  Result := V;
end;
procedure TfrmGestionOperaris.RefreshDeptsCell(ARecIdx: Integer);
var
  OpId: Integer;
begin
  OpId := OperatorIdOfRow(ARecIdx);
  if OpId <= 0 then Exit;
  tvOperaris.DataController.Values[ARecIdx, colOpDepartamentos.Index] :=
    GetDeptsCSV(OpId);
end;
procedure TfrmGestionOperaris.RefreshSkillsCell(ARecIdx: Integer);
var
  OpId: Integer;
begin
  OpId := OperatorIdOfRow(ARecIdx);
  if OpId <= 0 then Exit;
  tvOperaris.DataController.Values[ARecIdx, colOpCapacitaciones.Index] :=
    GetSkillsCount(OpId);
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
  // SCOPE_IDENTITY(): el id generado por ESTA sesion (misma conexion que Exec).
  // NO usar MAX(): con dos altas simultaneas devuelve la fila del OTRO usuario.
  Q := OpenQuery('SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewId');
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
    // OpId de la PROPIA fila, no de FOperatorIds[I]: con el grid ordenado se
    // guardaban los datos de un operario ENCIMA de otro, incluidos todos los
    // campos custom (SaveCustomFieldsForRow mas abajo).
    V := tvOperaris.DataController.Values[I, colOpId.Index];
    if VarIsNull(V) or VarIsEmpty(V) then Continue;
    OpId := V;
    if OpId <= 0 then Continue;
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
    SaveCustomFieldsForRow(OpId, I);
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
procedure TfrmGestionOperaris.btnPolivalenciaClick(Sender: TObject);
var
  OpId: Integer;
  Nombre: string;
begin
  OpId := SelectedOperatorId;
  if OpId <= 0 then
  begin
    ShowMessage('Seleccione un operario.');
    Exit;
  end;
  Nombre := SelectedOperatorName;
  if not Assigned(Form1) then Exit;
  TfrmOperarioPolivalencia.Execute(Form1.GetOperariosRepo,
    Form1.GetHabilidadRepo, OpId, Nombre);
end;

procedure TfrmGestionOperaris.btnMatrizClick(Sender: TObject);
begin
  if not Assigned(Form1) then Exit;
  TfrmMatrizPolivalencia.Execute(Form1.GetOperariosRepo,
    Form1.GetHabilidadRepo);
end;
end.
