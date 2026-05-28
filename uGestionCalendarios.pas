unit uGestionCalendarios;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.DateUtils, System.Math, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  dxSkinsCore, dxSkinOffice2019Colorful, dxSkinOffice2019Black,
  dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue,
  // Project
  uCentreCalendar, cxClasses,
  Data.Win.ADODB, Data.DB;

type
  // Tipo de dia para el calendario visual
  TDayType = (
    dtLaborable,         // dia completamente laborable
    dtNoLaborable,       // dia completamente no laborable (fin de semana cerrado)
    dtParcial,           // dia con horario parcial (tiene periodos no laborables)
    dtSinCalendario      // no hay calendario asignado
  );

  TfrmGestionCalendarios = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    chkVerIndicadores: TCheckBox;
    splDetalle: TSplitter;
    splMain: TSplitter;
    pnlLeft: TPanel;
    lblCalendarios: TLabel;
    lbCalendarios: TListBox;
    pnlCalToolbar: TPanel;
    btnCalAdd: TButton;
    btnCalEdit: TButton;
    btnCalDel: TButton;
    btnCalClone: TButton;
    pnlDetalle: TPanel;
    lblDetalleTitulo: TLabel;
    sbDetalle: TScrollBox;
    pbDetalle: TPaintBox;
    pnlRight: TPanel;
    lblAnioCaption: TLabel;
    pnlLeyenda: TPanel;
    pbCalendar: TPaintBox;
    LookAndFeel: TcxLookAndFeelController;
    splModels: TSplitter;
    pnlModels: TPanel;
    lblModelos: TLabel;
    lblModelosHint: TLabel;
    lbModelos: TListBox;
    pnlModelosToolbar: TPanel;
    btnModeloAdd: TButton;
    btnModeloEdit: TButton;
    btnModeloDel: TButton;
    btnExcepciones: TButton;
    btnImportFestivos: TButton;
    btnExcRecurrente: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCerrarClick(Sender: TObject);
    procedure lbCalendariosClick(Sender: TObject);
    procedure pbCalendarPaint(Sender: TObject);
    procedure pbCalendarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbCalendarDblClick(Sender: TObject);
    procedure pbDetallePaint(Sender: TObject);
    procedure btnCalAddClick(Sender: TObject);
    procedure btnCalEditClick(Sender: TObject);
    procedure btnCalDelClick(Sender: TObject);
    procedure btnCalCloneClick(Sender: TObject);
    procedure lbModelosClick(Sender: TObject);
    procedure lbModelosDblClick(Sender: TObject);
    procedure btnModeloAddClick(Sender: TObject);
    procedure btnModeloEditClick(Sender: TObject);
    procedure btnModeloDelClick(Sender: TObject);
    procedure btnExcepcionesClick(Sender: TObject);
    procedure btnImportFestivosClick(Sender: TObject);
    procedure btnExcRecurrenteClick(Sender: TObject);
    procedure chkVerIndicadoresClick(Sender: TObject);
    procedure btnAyudaClick(Sender: TObject);
  private
    FYear: Word;
    FDark: Boolean;
    FHoverDate: TDateTime;
    FHoverValid: Boolean;

    // Cache del calendario seleccionado
    FSelectedCalIdx: Integer;
    FDayTypes: array[1..12, 1..31] of TDayType;
    FWorkingMinutes: array[1..12, 1..31] of Integer;

    FCalendarIds: TArray<Integer>;  // CalendarId per cada entrada al ListBox
    FModelIds: TArray<Integer>;     // ShiftModelId per cada entrada de lbModelos

    // Cache del Detalle (poblat a BuildDetalleText, pintat a pbDetallePaint)
    FDetCalName: string;
    FDetCalDesc: string;
    FDetWeekendClosed: Boolean;
    FDetCentros: TArray<string>;
    FDetModelos: TArray<string>;       // "Nombre (N lineas)[ *Default]"
    FDetExcepciones: TArray<string>;   // "dd/mm/yyyy - Tipo - desc"
    FDetExcTipos: TArray<Boolean>;     // True=parcial, False=festivo (per color)
    FDetTotalLab: Integer;
    FDetTotalParcial: Integer;
    FDetTotalNoLab: Integer;
    FDetHorasAnuales: Integer;     // minuts totals laborables / 60

    procedure LoadCalendarioList;
    procedure LoadModelosList;
    procedure SelectCalendario(AIdx: Integer);
    function SelectedCalendarId: Integer;
    function SelectedShiftModelId: Integer;
    procedure RefreshAfterModelChange;
    procedure BuildDayCache;
    procedure BuildDetalleText;
    procedure PaintLeyenda;

    function GetDayType(const ACal: TCentreCalendar; const ADate: TDateTime): TDayType;
    function GetDayWorkingMinutes(const ACal: TCentreCalendar; const ADate: TDateTime): Integer;

    // Colores
    function ColorLaborable: TColor;
    function ColorNoLaborable: TColor;
    function ColorParcial: TColor;
    function ColorSinCalendario: TColor;
    function ColorHoy: TColor;
    function ColorTexto: TColor;
    function ColorTextoSecundario: TColor;
    function ColorFondo: TColor;
    function ColorCeldaBorde: TColor;

    procedure ApplyDarkMode(ADark: Boolean);

    // Geometry
    function MonthRect(AMonth: Integer): TRect;
    function DayRect(AMonth, ADay: Integer): TRect;
    function HitTestDay(X, Y: Integer; out AMonth, ADay: Integer): Boolean;
  public
    class procedure Execute(AYear: Word = 0);
  end;

var
  frmGestionCalendarios: TfrmGestionCalendarios;

implementation

uses
  uDMPlanner, uCalendarsRepo, uShiftModelEdit, uCalendarExceptionsEdit,
  uCalendarExceptionEditDialog, uFestivosImportDialog, uExcepcionRecurrenteDialog,
  uHelpViewer;

{$R *.dfm}

const
  MONTH_COLS = 4;       // 4 columnas x 3 filas = 12 meses
  MONTH_ROWS = 3;
  DAY_COLS = 7;         // 7 dias por semana
  DAY_ROWS = 6;         // maximo 6 semanas por mes
  HEADER_H = 20;        // altura cabecera del mes
  DAY_NAMES: array[1..7] of string = ('Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do');
  MONTH_NAMES: array[1..12] of string = (
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  );

{ TfrmGestionCalendarios }

class procedure TfrmGestionCalendarios.Execute(AYear: Word);
var
  F: TfrmGestionCalendarios;
begin
  F := TfrmGestionCalendarios.Create(Application);
  try
    if AYear = 0 then
      F.FYear := YearOf(Now)
    else
      F.FYear := AYear;
    F.LoadCalendarioList;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmGestionCalendarios.FormCreate(Sender: TObject);
begin
  FSelectedCalIdx := -1;
  FHoverValid := False;
  FDark := False;
  DoubleBuffered := True;
  pbCalendar.ControlStyle := pbCalendar.ControlStyle + [csOpaque];
  PaintLeyenda;
end;

procedure TfrmGestionCalendarios.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_F1) and (Shift = []) then
  begin
    Key := 0;
    btnAyudaClick(nil);
    Exit;
  end;
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure TfrmGestionCalendarios.btnCerrarClick(Sender: TObject);
begin

end;

{ ========== Lista calendarios ========== }

procedure TfrmGestionCalendarios.LoadCalendarioList;
var
  Q: TADOQuery;
  I: Integer;
  S: string;
  CentroCount: Integer;
begin
  lbCalendarios.Items.Clear;
  SetLength(FCalendarIds, 0);

  if not DMPlanner.IsConnected then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT c.CalendarId, c.Nombre, ' +
      '  (SELECT COUNT(*) FROM FS_PL_CenterCalendar cc ' +
      '   WHERE cc.CodigoEmpresa = c.CodigoEmpresa AND cc.CalendarId = c.CalendarId) AS CentroCount ' +
      'FROM FS_PL_Calendar c ' +
      'WHERE c.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) + ' AND c.Activo = 1 ' +
      'ORDER BY c.Nombre';
    Q.Open;
    SetLength(FCalendarIds, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      CentroCount := Q.FieldByName('CentroCount').AsInteger;
      S := Q.FieldByName('Nombre').AsString + '  (' + IntToStr(CentroCount) + ' centros)';
      lbCalendarios.Items.Add(S);
      FCalendarIds[I] := Q.FieldByName('CalendarId').AsInteger;
      Inc(I);
      Q.Next;
    end;
    SetLength(FCalendarIds, I);
  finally
    Q.Free;
  end;

  if lbCalendarios.Items.Count > 0 then
  begin
    lbCalendarios.ItemIndex := 0;
    SelectCalendario(0);
  end;
end;

procedure TfrmGestionCalendarios.lbCalendariosClick(Sender: TObject);
begin
  if lbCalendarios.ItemIndex >= 0 then
    SelectCalendario(lbCalendarios.ItemIndex);
end;

procedure TfrmGestionCalendarios.SelectCalendario(AIdx: Integer);
begin
  FSelectedCalIdx := AIdx;
  BuildDayCache;
  BuildDetalleText;
  pbCalendar.Invalidate;
  LoadModelosList;
end;

function TfrmGestionCalendarios.SelectedCalendarId: Integer;
begin
  if (FSelectedCalIdx < 0) or (FSelectedCalIdx > High(FCalendarIds)) then
    Result := -1
  else
    Result := FCalendarIds[FSelectedCalIdx];
end;

function TfrmGestionCalendarios.SelectedShiftModelId: Integer;
var
  Idx: Integer;
begin
  Result := -1;
  Idx := lbModelos.ItemIndex;
  if (Idx < 0) or (Idx > High(FModelIds)) then Exit;
  Result := FModelIds[Idx];
end;

procedure TfrmGestionCalendarios.LoadModelosList;
var
  CalId: Integer;
  Models: TArray<TShiftModelRec>;
  i: Integer;
  S: string;
begin
  lbModelos.Items.Clear;
  SetLength(FModelIds, 0);

  CalId := SelectedCalendarId;
  if CalId < 0 then Exit;
  if DMPlanner.CalendarsRepo = nil then Exit;

  Models := DMPlanner.CalendarsRepo.LoadShiftModels(
    DMPlanner.CodigoEmpresa, CalId);

  SetLength(FModelIds, Length(Models));
  for i := 0 to High(Models) do
  begin
    S := Models[i].Nombre;
    if Models[i].EsDefault then S := S + '  (Default)';
    lbModelos.Items.Add(S);
    FModelIds[i] := Models[i].ShiftModelId;
  end;
  if lbModelos.Items.Count > 0 then
    lbModelos.ItemIndex := 0;
end;

procedure TfrmGestionCalendarios.RefreshAfterModelChange;
var
  CalId: Integer;
begin
  // Reload del repo de calendars (regles han canviat) i del cache visual
  CalId := SelectedCalendarId;
  if DMPlanner.CalendarsRepo <> nil then
    DMPlanner.CalendarsRepo.LoadFromDB(DMPlanner.CodigoEmpresa);
  LoadModelosList;
  BuildDayCache;
  BuildDetalleText;
  pbCalendar.Invalidate;
  // No cal usar CalId; restem al mateix calendari seleccionat
  if CalId = 0 then ;  // suppress hint
end;

procedure TfrmGestionCalendarios.lbModelosClick(Sender: TObject);
begin
  // Selecció informativa; sense efecte secundari ara mateix
end;

procedure TfrmGestionCalendarios.lbModelosDblClick(Sender: TObject);
begin
  btnModeloEditClick(Sender);
end;

procedure TfrmGestionCalendarios.btnModeloAddClick(Sender: TObject);
var
  CalId: Integer;
begin
  CalId := SelectedCalendarId;
  if CalId < 0 then
  begin
    ShowMessage('Selecciona un calendario primero.');
    Exit;
  end;
  if DMPlanner.CalendarsRepo = nil then Exit;

  if TfrmShiftModelEdit.Execute(DMPlanner.CalendarsRepo,
       DMPlanner.CodigoEmpresa, CalId, -1) then
    RefreshAfterModelChange;
end;

procedure TfrmGestionCalendarios.btnModeloEditClick(Sender: TObject);
var
  CalId, Mid: Integer;
begin
  CalId := SelectedCalendarId;
  Mid := SelectedShiftModelId;
  if (CalId < 0) or (Mid < 0) then
  begin
    ShowMessage('Selecciona un modelo primero.');
    Exit;
  end;
  if DMPlanner.CalendarsRepo = nil then Exit;

  if TfrmShiftModelEdit.Execute(DMPlanner.CalendarsRepo,
       DMPlanner.CodigoEmpresa, CalId, Mid) then
    RefreshAfterModelChange;
end;

procedure TfrmGestionCalendarios.btnModeloDelClick(Sender: TObject);
var
  Mid, Idx: Integer;
  Nom: string;
begin
  Mid := SelectedShiftModelId;
  if Mid < 0 then Exit;
  if DMPlanner.CalendarsRepo = nil then Exit;

  Idx := lbModelos.ItemIndex;
  Nom := lbModelos.Items[Idx];

  if Pos('(Default)', Nom) > 0 then
  begin
    ShowMessage('No se puede eliminar el modelo Default del calendario.');
    Exit;
  end;

  if MessageDlg('Eliminar modelo "' + Nom + '"?',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  try
    DMPlanner.CalendarsRepo.DeleteShiftModel(DMPlanner.CodigoEmpresa, Mid);
    RefreshAfterModelChange;
  except
    on E: Exception do
      ShowMessage('Error al eliminar: ' + E.Message);
  end;
end;

procedure TfrmGestionCalendarios.btnExcepcionesClick(Sender: TObject);
var
  CalId: Integer;
  Nom: string;
begin
  CalId := SelectedCalendarId;
  if CalId < 0 then
  begin
    ShowMessage('Selecciona un calendario primero.');
    Exit;
  end;
  if DMPlanner.CalendarsRepo = nil then Exit;

  if (FSelectedCalIdx >= 0) and (FSelectedCalIdx < lbCalendarios.Items.Count) then
    Nom := lbCalendarios.Items[FSelectedCalIdx]
  else
    Nom := '';

  if TfrmCalendarExceptionsEdit.Execute(DMPlanner.CalendarsRepo,
       DMPlanner.CodigoEmpresa, CalId, Nom) then
    RefreshAfterModelChange;  // recarrega motor + vista anual
end;

procedure TfrmGestionCalendarios.btnImportFestivosClick(Sender: TObject);
var
  CalId: Integer;
  Nom: string;
begin
  CalId := SelectedCalendarId;
  if CalId < 0 then
  begin
    ShowMessage('Selecciona un calendario primero.');
    Exit;
  end;
  if DMPlanner.CalendarsRepo = nil then Exit;

  if (FSelectedCalIdx >= 0) and (FSelectedCalIdx < lbCalendarios.Items.Count) then
    Nom := lbCalendarios.Items[FSelectedCalIdx]
  else
    Nom := '';

  if TfrmFestivosImport.Execute(DMPlanner.CalendarsRepo,
       DMPlanner.CodigoEmpresa, CalId, Nom, FYear) then
    RefreshAfterModelChange;
end;

procedure TfrmGestionCalendarios.btnExcRecurrenteClick(Sender: TObject);
var
  CalId: Integer;
  Nom: string;
begin
  CalId := SelectedCalendarId;
  if CalId < 0 then
  begin
    ShowMessage('Selecciona un calendario primero.');
    Exit;
  end;
  if DMPlanner.CalendarsRepo = nil then Exit;

  if (FSelectedCalIdx >= 0) and (FSelectedCalIdx < lbCalendarios.Items.Count) then
    Nom := lbCalendarios.Items[FSelectedCalIdx]
  else
    Nom := '';

  if TfrmExcepcionRecurrente.Execute(DMPlanner.CalendarsRepo,
       DMPlanner.CodigoEmpresa, CalId, Nom, FYear) then
    RefreshAfterModelChange;
end;

procedure TfrmGestionCalendarios.chkVerIndicadoresClick(Sender: TObject);
begin
  pnlDetalle.Visible := chkVerIndicadores.Checked;
  splDetalle.Visible := chkVerIndicadores.Checked;
end;

procedure TfrmGestionCalendarios.btnAyudaClick(Sender: TObject);
begin

end;

{ ========== Build day cache ========== }

procedure TfrmGestionCalendarios.BuildDayCache;
var
  Mo, D, DaysInMo: Integer;
  ADate: TDateTime;
  Cal: TCentreCalendar;
begin
  // Limpiar
  FillChar(FDayTypes, SizeOf(FDayTypes), 0);
  FillChar(FWorkingMinutes, SizeOf(FWorkingMinutes), 0);

  if (FSelectedCalIdx < 0) or (FSelectedCalIdx > High(FCalendarIds)) then Exit;

  Cal := nil;
  if DMPlanner.CalendarsRepo <> nil then
    Cal := DMPlanner.CalendarsRepo.GetById(FCalendarIds[FSelectedCalIdx]);

  for Mo := 1 to 12 do
  begin
    DaysInMo := DaysInMonth(EncodeDate(FYear, Mo, 1));
    for D := 1 to DaysInMo do
    begin
      ADate := EncodeDate(FYear, Mo, D);
      if Cal = nil then
      begin
        FDayTypes[Mo, D] := dtSinCalendario;
        FWorkingMinutes[Mo, D] := 0;
      end
      else
      begin
        FDayTypes[Mo, D] := GetDayType(Cal, ADate);
        FWorkingMinutes[Mo, D] := GetDayWorkingMinutes(Cal, ADate);
      end;
    end;
  end;
end;

function TfrmGestionCalendarios.GetDayType(const ACal: TCentreCalendar;
  const ADate: TDateTime): TDayType;
var
  WorkMins: Integer;
begin
  // Usem WorkingMinutesBetween perque te en compte excepcions per data
  WorkMins := ACal.WorkingMinutesBetween(DateOf(ADate),
    DateOf(ADate) + EncodeTime(23, 59, 59, 999));

  if WorkMins >= (24 * 60 - 1) then Exit(dtLaborable);
  if WorkMins <= 30 then Exit(dtNoLaborable);
  Result := dtParcial;
end;

function TfrmGestionCalendarios.GetDayWorkingMinutes(const ACal: TCentreCalendar;
  const ADate: TDateTime): Integer;
var
  DayStart, DayEnd: TDateTime;
begin
  DayStart := DateOf(ADate);
  DayEnd := DayStart + EncodeTime(23, 59, 59, 999);
  Result := ACal.WorkingMinutesBetween(DayStart, DayEnd);
end;

{ ========== Detalle texto ========== }

procedure TfrmGestionCalendarios.BuildDetalleText;
var
  Q: TADOQuery;
  CalId: Integer;
  CalNombre: string;
  TotalLab, TotalNoLab, TotalParcial: Integer;
  Mo, D, DaysInMo: Integer;
  CE: string;
  TotMin: Integer;
  Cal: TCentreCalendar;
  ADate: TDateTime;
  S: string;
  NLineas: Integer;
  EsDef: Boolean;
  TipoTxt: string;
begin
  // Reset cache
  FDetCalName := '';
  FDetCalDesc := '';
  FDetWeekendClosed := False;
  SetLength(FDetCentros, 0);
  SetLength(FDetModelos, 0);
  SetLength(FDetExcepciones, 0);
  SetLength(FDetExcTipos, 0);
  FDetTotalLab := 0;
  FDetTotalParcial := 0;
  FDetTotalNoLab := 0;
  FDetHorasAnuales := 0;

  try
    if (FSelectedCalIdx < 0) or (FSelectedCalIdx > High(FCalendarIds)) then Exit;

    CalId := FCalendarIds[FSelectedCalIdx];
    CE := IntToStr(DMPlanner.CodigoEmpresa);

    // Nombre y descripcion
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text := 'SELECT Nombre, Descripcion FROM FS_PL_Calendar WHERE CodigoEmpresa = ' +
        CE + ' AND CalendarId = ' + IntToStr(CalId);
      Q.Open;
      if Q.Eof then Exit;
      FDetCalName := Q.FieldByName('Nombre').AsString;
      FDetCalDesc := Q.FieldByName('Descripcion').AsString;
    finally
      Q.Free;
    end;

    // Fin de semana cerrado
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text := 'SELECT COUNT(*) AS Cnt FROM FS_PL_CalendarDayRule ' +
        'WHERE CodigoEmpresa = ' + CE + ' AND CalendarId = ' + IntToStr(CalId) +
        ' AND DiaSemana IN (6,7)';
      Q.Open;
      FDetWeekendClosed := Q.FieldByName('Cnt').AsInteger > 0;
    finally
      Q.Free;
    end;

    // Centros asignados
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text := 'SELECT c.Titulo FROM FS_PL_CenterCalendar cc ' +
        'INNER JOIN FS_PL_Center c ON c.CodigoEmpresa = cc.CodigoEmpresa AND c.CenterId = cc.CenterId ' +
        'WHERE cc.CodigoEmpresa = ' + CE + ' AND cc.CalendarId = ' + IntToStr(CalId) +
        ' ORDER BY c.Titulo';
      Q.Open;
      while not Q.Eof do
      begin
        SetLength(FDetCentros, Length(FDetCentros) + 1);
        FDetCentros[High(FDetCentros)] := Q.FieldByName('Titulo').AsString;
        Q.Next;
      end;
    finally
      Q.Free;
    end;

    // Modelos horarios del calendario (catalogo + flag Default)
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT sm.ShiftModelId, sm.Nombre, sm.EsDefault, ' +
        '  (SELECT COUNT(*) FROM FS_PL_ShiftModelLine sl ' +
        '   WHERE sl.CodigoEmpresa = sm.CodigoEmpresa ' +
        '     AND sl.ShiftModelId = sm.ShiftModelId) AS NLineas ' +
        'FROM FS_PL_ShiftModel sm ' +
        'WHERE sm.CodigoEmpresa = ' + CE + ' AND sm.CalendarId = ' + IntToStr(CalId) +
        ' ORDER BY sm.EsDefault DESC, sm.Nombre';
      Q.Open;
      while not Q.Eof do
      begin
        NLineas := Q.FieldByName('NLineas').AsInteger;
        EsDef := Q.FieldByName('EsDefault').AsBoolean;
        S := Q.FieldByName('Nombre').AsString +
             Format('  (%d l'#237'neas)', [NLineas]);
        if EsDef then
          S := S + '   *Default';
        SetLength(FDetModelos, Length(FDetModelos) + 1);
        FDetModelos[High(FDetModelos)] := S;
        Q.Next;
      end;
    finally
      Q.Free;
    end;

    // Excepciones del año seleccionado, ordenadas
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT Fecha, EsLaborable, ' +
        '  CONVERT(VARCHAR(5), HoraInicio, 108) AS HIni, ' +
        '  CONVERT(VARCHAR(5), HoraFin, 108)    AS HFin, ' +
        '  Descripcion ' +
        'FROM FS_PL_CalendarException ' +
        'WHERE CodigoEmpresa = ' + CE + ' AND CalendarId = ' + IntToStr(CalId) +
        '  AND YEAR(Fecha) = ' + IntToStr(FYear) +
        ' ORDER BY Fecha';
      Q.Open;
      while not Q.Eof do
      begin
        ADate := Q.FieldByName('Fecha').AsDateTime;
        if Q.FieldByName('EsLaborable').AsBoolean then
        begin
          TipoTxt := 'Pausa ' + Q.FieldByName('HIni').AsString +
                     '-' + Q.FieldByName('HFin').AsString;
          SetLength(FDetExcTipos, Length(FDetExcTipos) + 1);
          FDetExcTipos[High(FDetExcTipos)] := True;
        end
        else
        begin
          TipoTxt := 'Festivo';
          SetLength(FDetExcTipos, Length(FDetExcTipos) + 1);
          FDetExcTipos[High(FDetExcTipos)] := False;
        end;
        S := FormatDateTime('dd/mm/yyyy', ADate) + '  ' + TipoTxt;
        if Q.FieldByName('Descripcion').AsString <> '' then
          S := S + '  - ' + Q.FieldByName('Descripcion').AsString;
        SetLength(FDetExcepciones, Length(FDetExcepciones) + 1);
        FDetExcepciones[High(FDetExcepciones)] := S;
        Q.Next;
      end;
    finally
      Q.Free;
    end;

    // KPIs anuales (dias)
    TotalLab := 0; TotalNoLab := 0; TotalParcial := 0;
    for Mo := 1 to 12 do
    begin
      DaysInMo := DaysInMonth(EncodeDate(FYear, Mo, 1));
      for D := 1 to DaysInMo do
        case FDayTypes[Mo, D] of
          dtLaborable:   Inc(TotalLab);
          dtNoLaborable: Inc(TotalNoLab);
          dtParcial:     Inc(TotalParcial);
        end;
    end;
    FDetTotalLab := TotalLab;
    FDetTotalParcial := TotalParcial;
    FDetTotalNoLab := TotalNoLab;

    // Horas laborables totales del año (suma FWorkingMinutes)
    TotMin := 0;
    for Mo := 1 to 12 do
    begin
      DaysInMo := DaysInMonth(EncodeDate(FYear, Mo, 1));
      for D := 1 to DaysInMo do
        Inc(TotMin, FWorkingMinutes[Mo, D]);
    end;
    FDetHorasAnuales := TotMin div 60;
  finally
    if pbDetalle <> nil then
      pbDetalle.Invalidate;
  end;
end;

{ ========== Geometry ========== }

function TfrmGestionCalendarios.MonthRect(AMonth: Integer): TRect;
var
  Col, Row: Integer;
  CellW, CellH: Integer;
  MX, MY: Integer;
begin
  Col := (AMonth - 1) mod MONTH_COLS;
  Row := (AMonth - 1) div MONTH_COLS;
  CellW := pbCalendar.Width div MONTH_COLS;
  CellH := pbCalendar.Height div MONTH_ROWS;
  MX := Col * CellW;
  MY := Row * CellH;
  Result := Rect(MX + 4, MY + 2, MX + CellW - 4, MY + CellH - 2);
end;

function TfrmGestionCalendarios.DayRect(AMonth, ADay: Integer): TRect;
var
  MR: TRect;
  DW, DH: Integer;
  FirstDOW: Integer;
  Pos, DCol, DRow: Integer;
  DayAreaTop: Integer;
  DayNamesH: Integer;
begin
  MR := MonthRect(AMonth);
  DayNamesH := 14;
  DayAreaTop := MR.Top + HEADER_H + DayNamesH;
  DW := (MR.Right - MR.Left) div DAY_COLS;
  DH := (MR.Bottom - DayAreaTop) div DAY_ROWS;

  // DayOfTheWeek: 1=Mon..7=Sun (ISO)
  FirstDOW := DayOfTheWeek(EncodeDate(FYear, AMonth, 1));
  Pos := (ADay - 1) + (FirstDOW - 1);
  DCol := Pos mod 7;
  DRow := Pos div 7;

  Result.Left := MR.Left + DCol * DW;
  Result.Top := DayAreaTop + DRow * DH;
  Result.Right := Result.Left + DW;
  Result.Bottom := Result.Top + DH;
end;

function TfrmGestionCalendarios.HitTestDay(X, Y: Integer;
  out AMonth, ADay: Integer): Boolean;
var
  Mo, D, DaysInMo: Integer;
  R: TRect;
begin
  Result := False;
  for Mo := 1 to 12 do
  begin
    DaysInMo := DaysInMonth(EncodeDate(FYear, Mo, 1));
    for D := 1 to DaysInMo do
    begin
      R := DayRect(Mo, D);
      if PtInRect(R, Point(X, Y)) then
      begin
        AMonth := Mo;
        ADay := D;
        Exit(True);
      end;
    end;
  end;
end;

{ ========== Colores ========== }

function TfrmGestionCalendarios.ColorLaborable: TColor;
begin
  if FDark then Result := TColor($00448844)
  else Result := TColor($0090EE90); // verde claro
end;

function TfrmGestionCalendarios.ColorNoLaborable: TColor;
begin
  if FDark then Result := TColor($002020AA)
  else Result := TColor($008080FF); // rojo/azul claro
end;

function TfrmGestionCalendarios.ColorParcial: TColor;
begin
  if FDark then Result := TColor($00448888)
  else Result := TColor($0080DDEE); // amarillo/turquesa claro
end;

function TfrmGestionCalendarios.ColorSinCalendario: TColor;
begin
  if FDark then Result := TColor($00404040)
  else Result := TColor($00D0D0D0);
end;

function TfrmGestionCalendarios.ColorHoy: TColor;
begin
  Result := TColor($000060FF); // naranja
end;

function TfrmGestionCalendarios.ColorTexto: TColor;
begin
  if FDark then Result := TColor($00F0F0F0)
  else Result := TColor($00202020);
end;

function TfrmGestionCalendarios.ColorTextoSecundario: TColor;
begin
  if FDark then Result := TColor($00909090)
  else Result := TColor($00808080);
end;

function TfrmGestionCalendarios.ColorFondo: TColor;
begin
  if FDark then Result := TColor($00302C28)
  else Result := TColor($00FFFFFF);
end;

function TfrmGestionCalendarios.ColorCeldaBorde: TColor;
begin
  if FDark then Result := TColor($00504840)
  else Result := TColor($00C8C8C8);
end;

{ ========== Paint ========== }

procedure TfrmGestionCalendarios.pbCalendarPaint(Sender: TObject);
var
  C: TCanvas;
  Mo, D, DaysInMo: Integer;
  MR, DR, TR: TRect;
  DT: TDayType;
  FillCol: TColor;
  FirstDOW, DCol: Integer;
  DW: Integer;
  DayNamesH, DayAreaTop: Integer;
  TodayDate: TDateTime;
  S: string;
  Flags: Cardinal;
  Cal: TCentreCalendar;
  Exc: TDayException;
  HasExc: Boolean;
  Tri: array[0..2] of TPoint;
begin
  C := pbCalendar.Canvas;

  // Fondo
  C.Brush.Color := ColorFondo;
  C.FillRect(pbCalendar.ClientRect);

  TodayDate := DateOf(Now);
  DayNamesH := 14;

  // Calendari actiu (per consultar excepcions per data)
  Cal := nil;
  if (FSelectedCalIdx >= 0) and (FSelectedCalIdx <= High(FCalendarIds))
     and (DMPlanner.CalendarsRepo <> nil) then
    Cal := DMPlanner.CalendarsRepo.GetById(FCalendarIds[FSelectedCalIdx]);

  for Mo := 1 to 12 do
  begin
    MR := MonthRect(Mo);
    DaysInMo := DaysInMonth(EncodeDate(FYear, Mo, 1));

    // Cabecera del mes
    C.Font.Name := 'Segoe UI Semibold';
    C.Font.Size := 9;
    C.Font.Color := ColorTexto;
    C.Font.Style := [fsBold];
    C.Brush.Style := bsClear;
    S := MONTH_NAMES[Mo] + ' ' + IntToStr(FYear);
    Flags := DT_CENTER or DT_SINGLELINE or DT_VCENTER;
    TR := Rect(MR.Left, MR.Top, MR.Right, MR.Top + HEADER_H);
    DrawText(C.Handle, PChar(S), Length(S), TR, Flags);

    // Nombres dias semana
    C.Font.Size := 7;
    C.Font.Style := [];
    C.Font.Color := ColorTextoSecundario;
    DW := (MR.Right - MR.Left) div DAY_COLS;
    DayAreaTop := MR.Top + HEADER_H;
    for DCol := 0 to 6 do
    begin
      TR := Rect(MR.Left + DCol * DW, DayAreaTop,
                 MR.Left + (DCol + 1) * DW, DayAreaTop + DayNamesH);
      DrawText(C.Handle, PChar(DAY_NAMES[DCol + 1]), Length(DAY_NAMES[DCol + 1]),
        TR, DT_CENTER or DT_SINGLELINE or DT_VCENTER);
    end;

    // Dias
    C.Font.Size := 7;
    C.Font.Style := [];
    for D := 1 to DaysInMo do
    begin
      DR := DayRect(Mo, D);
      DT := FDayTypes[Mo, D];

      case DT of
        dtLaborable:    FillCol := ColorLaborable;
        dtNoLaborable:  FillCol := ColorNoLaborable;
        dtParcial:      FillCol := ColorParcial;
      else
        FillCol := ColorSinCalendario;
      end;

      // Celda
      C.Brush.Color := FillCol;
      C.Brush.Style := bsSolid;
      C.Pen.Color := ColorCeldaBorde;
      C.Pen.Style := psSolid;
      C.Rectangle(DR);

      // Borde especial si es hoy
      if (YearOf(TodayDate) = FYear) and
         (MonthOf(TodayDate) = Mo) and
         (DayOf(TodayDate) = D) then
      begin
        C.Pen.Color := ColorHoy;
        C.Pen.Width := 2;
        C.Brush.Style := bsClear;
        C.Rectangle(DR.Left + 1, DR.Top + 1, DR.Right - 1, DR.Bottom - 1);
        C.Pen.Width := 1;
      end;

      // Numero del dia
      C.Brush.Style := bsClear;
      C.Font.Color := ColorTexto;
      S := IntToStr(D);
      DrawText(C.Handle, PChar(S), Length(S), DR,
        DT_CENTER or DT_SINGLELINE or DT_VCENTER);

      // Marca d'excepcio: triangle a la cantonada sup-dreta
      // Vermell = festiu sencer / Taronja = pausa parcial
      HasExc := False;
      if Cal <> nil then
        HasExc := Cal.TryGetException(EncodeDate(FYear, Mo, D), Exc);
      if HasExc then
      begin
        Tri[0] := Point(DR.Right - 8, DR.Top + 1);
        Tri[1] := Point(DR.Right - 1, DR.Top + 1);
        Tri[2] := Point(DR.Right - 1, DR.Top + 8);
        C.Brush.Color := $00B040D0; // fuchsia (BGR) RGB(208,64,176)
        C.Brush.Style := bsSolid;
        C.Pen.Color := C.Brush.Color;
        C.Polygon(Tri);
      end;
    end;
  end;
end;

procedure TfrmGestionCalendarios.pbCalendarMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  Mo, D: Integer;
  ADate: TDateTime;
  DT: TDayType;
  WM: Integer;
  S: string;
begin
  if HitTestDay(X, Y, Mo, D) then
  begin
    ADate := EncodeDate(FYear, Mo, D);
    FHoverDate := ADate;
    FHoverValid := True;
    DT := FDayTypes[Mo, D];
    WM := FWorkingMinutes[Mo, D];

    S := FormatDateTime('dddd dd/mm/yyyy', ADate);
    case DT of
      dtLaborable:   S := S + '  [LABORABLE 24h]';
      dtParcial:     S := S + Format('  [PARCIAL - %d min laborables = %.1fh]', [WM, WM / 60.0]);
      dtNoLaborable: S := S + '  [NO LABORABLE]';
    else
      S := S + '  [SIN CALENDARIO]';
    end;
    pbCalendar.Hint := S;
    pbCalendar.ShowHint := True;
  end
  else
  begin
    FHoverValid := False;
    pbCalendar.Hint := '';
    pbCalendar.ShowHint := False;
  end;
end;

procedure TfrmGestionCalendarios.pbCalendarDblClick(Sender: TObject);
var
  P: TPoint;
  Mo, D, CalId: Integer;
  ADate: TDateTime;
begin
  CalId := SelectedCalendarId;
  if CalId < 0 then Exit;
  if DMPlanner.CalendarsRepo = nil then Exit;

  P := pbCalendar.ScreenToClient(Mouse.CursorPos);
  if not HitTestDay(P.X, P.Y, Mo, D) then Exit;

  ADate := EncodeDate(FYear, Mo, D);
  if TfrmCalendarExceptionEditDialog.Execute(DMPlanner.CalendarsRepo,
       DMPlanner.CodigoEmpresa, CalId, -1, ADate) then
    RefreshAfterModelChange;
end;

{ ========== Leyenda ========== }

procedure TfrmGestionCalendarios.PaintLeyenda;

  procedure AddLeyendaItem(AParent: TWinControl; ALeft: Integer; AColor: TColor; const AText: string);
  var
    Shp: TShape;
    Lbl: TLabel;
  begin
    Shp := TShape.Create(AParent);
    Shp.Parent := AParent;
    Shp.Shape := stRectangle;
    Shp.SetBounds(ALeft, 8, 16, 16);
    Shp.Brush.Color := AColor;
    Shp.Pen.Color := clGray;

    Lbl := TLabel.Create(AParent);
    Lbl.Parent := AParent;
    Lbl.SetBounds(ALeft + 20, 8, 100, 16);
    Lbl.Caption := AText;
    Lbl.Font.Size := 8;
  end;

begin
  // Limpiar hijos previos
  while pnlLeyenda.ControlCount > 0 do
    pnlLeyenda.Controls[0].Free;

  AddLeyendaItem(pnlLeyenda, 8,   ColorLaborable,     'Laborable 24h');
  AddLeyendaItem(pnlLeyenda, 120, ColorParcial,       'Parcial');
  AddLeyendaItem(pnlLeyenda, 220, ColorNoLaborable,   'No laborable');
  AddLeyendaItem(pnlLeyenda, 340, ColorSinCalendario, 'Sin calendario');
  AddLeyendaItem(pnlLeyenda, 460, $00B040D0,          'Excepci'#243'n');
end;

{ ========== Calendarios CRUD (SQL) ========== }

procedure TfrmGestionCalendarios.btnCalAddClick(Sender: TObject);
var
  Nom: string;
  Cmd: TADOCommand;
  CE: string;
begin
  Nom := InputBox('Nuevo Calendario', 'Nombre:', '');
  if Nom = '' then Exit;

  if DMPlanner.IsConnected then
  begin
    CE := IntToStr(DMPlanner.CodigoEmpresa);
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;
      Cmd.CommandText := 'INSERT INTO FS_PL_Calendar (CodigoEmpresa, Nombre, Descripcion) VALUES (' +
        CE + ', N''' + StringReplace(Nom, '''', '''''', [rfReplaceAll]) + ''', N'''')';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;

    // Crear reglas por defecto: fines de semana cerrados
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;
      Cmd.CommandText :=
        'DECLARE @CalId INT = (SELECT MAX(CalendarId) FROM FS_PL_Calendar WHERE CodigoEmpresa = ' + CE + '); ' +
        'INSERT INTO FS_PL_CalendarDayRule (CodigoEmpresa, CalendarId, DiaSemana, HoraInicioNoLab, HoraFinNoLab) VALUES ' +
        '(' + CE + ', @CalId, 6, ''00:00:00'', ''23:59:00''), ' +
        '(' + CE + ', @CalId, 7, ''00:00:00'', ''23:59:00'')';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
  end;

  LoadCalendarioList;
end;

procedure TfrmGestionCalendarios.btnCalEditClick(Sender: TObject);
var
  CalId: Integer;
  Nom, Desc: string;
  Cmd: TADOCommand;
  Q: TADOQuery;
  CE: string;
begin
  if (FSelectedCalIdx < 0) or (FSelectedCalIdx > High(FCalendarIds)) then Exit;
  if not DMPlanner.IsConnected then Exit;

  CalId := FCalendarIds[FSelectedCalIdx];
  CE := IntToStr(DMPlanner.CodigoEmpresa);

  // Obtener datos actuales
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT Nombre, Descripcion FROM FS_PL_Calendar WHERE CodigoEmpresa = ' +
      CE + ' AND CalendarId = ' + IntToStr(CalId);
    Q.Open;
    if Q.Eof then Exit;
    Nom := Q.FieldByName('Nombre').AsString;
    Desc := Q.FieldByName('Descripcion').AsString;
  finally
    Q.Free;
  end;

  Nom := InputBox('Editar Calendario', 'Nombre:', Nom);
  if Nom = '' then Exit;
  Desc := InputBox('Editar Calendario', 'Descripci'#243'n:', Desc);

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText := 'UPDATE FS_PL_Calendar SET ' +
      'Nombre = N''' + StringReplace(Nom, '''', '''''', [rfReplaceAll]) + ''', ' +
      'Descripcion = N''' + StringReplace(Desc, '''', '''''', [rfReplaceAll]) + '''' +
      ' WHERE CodigoEmpresa = ' + CE + ' AND CalendarId = ' + IntToStr(CalId);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  LoadCalendarioList;
end;

procedure TfrmGestionCalendarios.btnCalDelClick(Sender: TObject);
var
  CalId: Integer;
  Cmd: TADOCommand;
  CE: string;
  CalNom: string;
begin
  if (FSelectedCalIdx < 0) or (FSelectedCalIdx > High(FCalendarIds)) then Exit;
  if not DMPlanner.IsConnected then Exit;

  CalId := FCalendarIds[FSelectedCalIdx];
  CE := IntToStr(DMPlanner.CodigoEmpresa);

  // Obtener nombre para confirmación
  CalNom := '';
  if FSelectedCalIdx < lbCalendarios.Items.Count then
    CalNom := lbCalendarios.Items[FSelectedCalIdx];

  if MessageDlg(#191'Eliminar calendario "' + CalNom + '"?' + sLineBreak +
    'Se eliminar'#225'n tambi'#233'n sus reglas y asignaciones a centros.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  // Desasignar de centros
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText := 'DELETE FROM FS_PL_CenterCalendar WHERE CodigoEmpresa = ' +
      CE + ' AND CalendarId = ' + IntToStr(CalId);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // Eliminar calendario (CASCADE elimina DayRules y Exceptions)
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText := 'DELETE FROM FS_PL_Calendar WHERE CodigoEmpresa = ' +
      CE + ' AND CalendarId = ' + IntToStr(CalId);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  FSelectedCalIdx := -1;
  LoadCalendarioList;
end;

procedure TfrmGestionCalendarios.btnCalCloneClick(Sender: TObject);
var
  SrcCalId: Integer;
  NewNombre, SrcNombre: string;
  CE: string;
  Cmd: TADOCommand;
  Q: TADOQuery;
  NewCalId: Integer;
begin
  if (FSelectedCalIdx < 0) or (FSelectedCalIdx > High(FCalendarIds)) then
  begin
    ShowMessage('Selecciona un calendario primero.');
    Exit;
  end;
  if not DMPlanner.IsConnected then Exit;

  SrcCalId := FCalendarIds[FSelectedCalIdx];
  SrcNombre := lbCalendarios.Items[FSelectedCalIdx];

  NewNombre := InputBox('Clonar calendario',
    'Nombre del nuevo calendario:', SrcNombre + ' (copia)');
  if Trim(NewNombre) = '' then Exit;

  CE := IntToStr(DMPlanner.CodigoEmpresa);

  // 1) Crear calendario destino copiando descripcion
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_Calendar (CodigoEmpresa, Nombre, Descripcion) ' +
      'SELECT CodigoEmpresa, N''' +
      StringReplace(NewNombre, '''', '''''', [rfReplaceAll]) +
      ''', Descripcion FROM FS_PL_Calendar ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND CalendarId = ' + IntToStr(SrcCalId);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // 2) Obtener NewCalId
  NewCalId := -1;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT MAX(CalendarId) AS NewId FROM FS_PL_Calendar ' +
      'WHERE CodigoEmpresa = ' + CE;
    Q.Open;
    if not Q.Eof then NewCalId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;
  if NewCalId <= 0 then
  begin
    ShowMessage('No se pudo obtener el ID del nuevo calendario.');
    Exit;
  end;

  // 3) Clonar CalendarDayRule (regles setmanals)
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_CalendarDayRule ' +
      '  (CodigoEmpresa, CalendarId, DiaSemana, HoraInicioNoLab, HoraFinNoLab) ' +
      'SELECT CodigoEmpresa, ' + IntToStr(NewCalId) +
      ', DiaSemana, HoraInicioNoLab, HoraFinNoLab ' +
      'FROM FS_PL_CalendarDayRule ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND CalendarId = ' + IntToStr(SrcCalId);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // 4) Clonar ShiftModel (+ ShiftModelLine via cursor)
  // SQL Server: necesitamos mapear nuevos ShiftModelId. Iteramos cada modelo.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ShiftModelId, Nombre, Descripcion, EsDefault, Activo ' +
      'FROM FS_PL_ShiftModel ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND CalendarId = ' + IntToStr(SrcCalId);
    Q.Open;
    while not Q.Eof do
    begin
      Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := DMPlanner.ADOConnection;
        Cmd.CommandText :=
          'DECLARE @NewModelId INT; ' +
          'INSERT INTO FS_PL_ShiftModel (CodigoEmpresa, CalendarId, Nombre, Descripcion, EsDefault, Activo) ' +
          'VALUES (' + CE + ', ' + IntToStr(NewCalId) + ', :Nom, :Desc, :Def, :Act); ' +
          'SET @NewModelId = SCOPE_IDENTITY(); ' +
          'INSERT INTO FS_PL_ShiftModelLine (CodigoEmpresa, ShiftModelId, DiaSemana, HoraInicio, HoraFin) ' +
          'SELECT CodigoEmpresa, @NewModelId, DiaSemana, HoraInicio, HoraFin ' +
          'FROM FS_PL_ShiftModelLine ' +
          'WHERE CodigoEmpresa = ' + CE +
          ' AND ShiftModelId = ' + IntToStr(Q.FieldByName('ShiftModelId').AsInteger);
        Cmd.Parameters.ParamByName('Nom').Value := Q.FieldByName('Nombre').AsString;
        Cmd.Parameters.ParamByName('Desc').Value := Q.FieldByName('Descripcion').AsString;
        Cmd.Parameters.ParamByName('Def').Value := Q.FieldByName('EsDefault').AsBoolean;
        Cmd.Parameters.ParamByName('Act').Value := Q.FieldByName('Activo').AsBoolean;
        Cmd.Execute;
      finally
        Cmd.Free;
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  // 5) Clonar excepciones
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_CalendarException ' +
      '  (CodigoEmpresa, CalendarId, Fecha, EsLaborable, HoraInicio, HoraFin, Descripcion) ' +
      'SELECT CodigoEmpresa, ' + IntToStr(NewCalId) +
      ', Fecha, EsLaborable, HoraInicio, HoraFin, Descripcion ' +
      'FROM FS_PL_CalendarException ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND CalendarId = ' + IntToStr(SrcCalId);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // Refresh
  LoadCalendarioList;
  // Selecciona el nou
  FSelectedCalIdx := lbCalendarios.Items.IndexOf(NewNombre);
  if FSelectedCalIdx >= 0 then
  begin
    lbCalendarios.ItemIndex := FSelectedCalIdx;
    SelectCalendario(FSelectedCalIdx);
  end;

  ShowMessage('Calendario clonado correctamente.');
end;

{ ========== Detalle calendario (paint) ========== }

procedure TfrmGestionCalendarios.pbDetallePaint(Sender: TObject);
const
  CardW = 110;
  CardH = 54;
  CardGap = 8;
  Margin = 8;
  ColFestivo  = $00B040D0;  // fuchsia
  ColParcial  = $000080FF;  // taronja
var
  C: TCanvas;
  W, Y: Integer;
  X1, X2: Integer;

  procedure DrawSectionTitle(const ATitle: string);
  begin
    C.Brush.Style := bsClear;
    C.Font.Name := 'Segoe UI Semibold';
    C.Font.Size := 9;
    C.Font.Color := 4474440;
    C.Font.Style := [fsBold];
    C.TextOut(Margin, Y, ATitle);
    Inc(Y, 18);
    // linia separadora
    C.Pen.Color := $00E0E0E0;
    C.MoveTo(Margin, Y);
    C.LineTo(W - Margin, Y);
    Inc(Y, 6);
  end;

  procedure DrawCard(const ALeft: Integer; const ANumber, ALabel: string;
    const AColor: TColor);
  var
    R: TRect;
    TR: TRect;
    NumStr: string;
  begin
    R := Rect(ALeft, Y, ALeft + CardW, Y + CardH);
    // fondo card
    C.Brush.Color := $00FAFAFA;
    C.Brush.Style := bsSolid;
    C.Pen.Color := $00E0E0E0;
    C.Rectangle(R);
    // barra de color a l'esquerra
    C.Brush.Color := AColor;
    C.Pen.Color := AColor;
    C.Rectangle(R.Left + 1, R.Top + 1, R.Left + 4, R.Bottom - 1);
    // numero
    C.Brush.Style := bsClear;
    C.Font.Name := 'Segoe UI Semibold';
    C.Font.Size := 14;
    C.Font.Color := 3355443;
    C.Font.Style := [fsBold];
    NumStr := ANumber;
    TR := Rect(R.Left + 8, R.Top + 4, R.Right - 4, R.Top + 28);
    DrawText(C.Handle, PChar(NumStr), Length(NumStr), TR,
      DT_LEFT or DT_SINGLELINE or DT_VCENTER);
    // label
    C.Font.Name := 'Segoe UI';
    C.Font.Size := 7;
    C.Font.Color := clGray;
    C.Font.Style := [];
    TR := Rect(R.Left + 8, R.Top + 28, R.Right - 4, R.Bottom - 4);
    DrawText(C.Handle, PChar(ALabel), Length(ALabel), TR,
      DT_LEFT or DT_WORDBREAK);
  end;

  procedure DrawLineItem(const ATxt: string; const ABulletColor: TColor);
  begin
    // bullet
    C.Brush.Color := ABulletColor;
    C.Pen.Color := ABulletColor;
    C.Ellipse(Margin + 2, Y + 5, Margin + 9, Y + 12);
    // text
    C.Brush.Style := bsClear;
    C.Font.Name := 'Segoe UI';
    C.Font.Size := 8;
    C.Font.Color := 3355443;
    C.Font.Style := [];
    C.TextOut(Margin + 16, Y + 2, ATxt);
    Inc(Y, 17);
  end;

  procedure DrawPlainLine(const ATxt: string);
  begin
    C.Brush.Style := bsClear;
    C.Font.Name := 'Segoe UI';
    C.Font.Size := 8;
    C.Font.Color := 3355443;
    C.Font.Style := [];
    C.TextOut(Margin + 4, Y, ATxt);
    Inc(Y, 16);
  end;

var
  I: Integer;
  CardColor: TColor;
begin
  C := pbDetalle.Canvas;
  W := pbDetalle.Width;

  // Fons
  C.Brush.Color := clWhite;
  C.Brush.Style := bsSolid;
  C.FillRect(pbDetalle.ClientRect);

  Y := Margin;

  if FDetCalName = '' then
  begin
    C.Brush.Style := bsClear;
    C.Font.Name := 'Segoe UI';
    C.Font.Size := 9;
    C.Font.Color := clGray;
    C.Font.Style := [fsItalic];
    C.TextOut(Margin, Y, 'Sin calendario seleccionado');
    Exit;
  end;

  // ===== Cabecera: nombre + descripcion =====
  C.Brush.Style := bsClear;
  C.Font.Name := 'Segoe UI Semibold';
  C.Font.Size := 11;
  C.Font.Color := 4474440;
  C.Font.Style := [fsBold];
  C.TextOut(Margin, Y, FDetCalName);
  Inc(Y, 22);

  if FDetCalDesc <> '' then
  begin
    C.Font.Name := 'Segoe UI';
    C.Font.Size := 8;
    C.Font.Color := clGray;
    C.Font.Style := [fsItalic];
    C.TextOut(Margin, Y, FDetCalDesc);
    Inc(Y, 16);
  end;

  // Fin de semana
  C.Font.Name := 'Segoe UI';
  C.Font.Size := 8;
  C.Font.Style := [];
  C.Font.Color := clGray;
  if FDetWeekendClosed then
    C.TextOut(Margin, Y, 'Fin de semana: CERRADO')
  else
    C.TextOut(Margin, Y, 'Fin de semana: ABIERTO');
  Inc(Y, 20);

  // ===== KPIs (2 columnes x 3 files) =====
  DrawSectionTitle('KPIs ' + IntToStr(FYear));

  X1 := Margin;
  X2 := Margin + CardW + CardGap;

  DrawCard(X1, IntToStr(FDetTotalLab + FDetTotalParcial),
    'D'#237'as laborables', $0028A745);
  DrawCard(X2, IntToStr(FDetHorasAnuales) + ' h',
    'Horas/a'#241'o', $00007BFF);
  Inc(Y, CardH + CardGap);

  DrawCard(X1, IntToStr(FDetTotalNoLab),
    'D'#237'as no laborables', $00666666);
  if (FDetTotalLab + FDetTotalParcial) > 0 then
    DrawCard(X2,
      Format('%.1f h', [FDetHorasAnuales / (FDetTotalLab + FDetTotalParcial)]),
      'Media h/d'#237'a', $00FF8800)
  else
    DrawCard(X2, '0 h', 'Media h/d'#237'a', $00FF8800);
  Inc(Y, CardH + CardGap);

  // Conteo excepciones
  X1 := 0;
  X2 := 0;
  for I := 0 to High(FDetExcTipos) do
    if FDetExcTipos[I] then Inc(X2) else Inc(X1);
  DrawCard(Margin, IntToStr(X1), 'Excepciones festivas', ColFestivo);
  DrawCard(Margin + CardW + CardGap, IntToStr(X2),
    'Excepciones parciales', ColParcial);
  Inc(Y, CardH + CardGap + 4);

  // ===== Modelos horarios =====
  DrawSectionTitle('Modelos horarios');
  if Length(FDetModelos) = 0 then
    DrawPlainLine('(ninguno)')
  else
    for I := 0 to High(FDetModelos) do
      DrawLineItem(FDetModelos[I], $00007BFF);
  Inc(Y, 6);

  // ===== Centros asignados =====
  DrawSectionTitle('Centros asignados (' + IntToStr(Length(FDetCentros)) + ')');
  if Length(FDetCentros) = 0 then
    DrawPlainLine('(ninguno)')
  else
    for I := 0 to High(FDetCentros) do
      DrawLineItem(FDetCentros[I], $0028A745);
  Inc(Y, 6);

  // ===== Excepciones =====
  DrawSectionTitle('Excepciones ' + IntToStr(FYear));
  if Length(FDetExcepciones) = 0 then
    DrawPlainLine('(ninguna)')
  else
    for I := 0 to High(FDetExcepciones) do
    begin
      if FDetExcTipos[I] then
        CardColor := ColParcial
      else
        CardColor := ColFestivo;
      DrawLineItem(FDetExcepciones[I], CardColor);
    end;
  Inc(Y, 8);

  // Ajustar altura del PaintBox al contingut (scroll). Nomes si difereix prou,
  // per evitar re-paints encadenats.
  if Abs(pbDetalle.Height - (Y + Margin)) > 2 then
    pbDetalle.Height := Y + Margin;
end;

procedure TfrmGestionCalendarios.ApplyDarkMode(ADark: Boolean);
const
  DARK_BG     = $00302C28;
  DARK_HEADER = $003C3836;
  DARK_TEXT   = $00F0F0F0;
  DARK_SUB    = $00A0A0A0;
  DARK_LINE   = $00504840;
begin
  if ADark then
  begin
    LookAndFeel.SkinName := 'Office2019Black';
    pnlHeader.Color := DARK_HEADER;
    lblTitle.Font.Color := DARK_TEXT;
    lblSubtitle.Font.Color := DARK_SUB;
    shpHeaderLine.Brush.Color := DARK_LINE;
    pnlLeft.Color := DARK_BG;
    pnlDetalle.Color := DARK_BG;
    pnlRight.Color := DARK_BG;
    pnlLeyenda.Color := DARK_BG;
    lblCalendarios.Font.Color := DARK_TEXT;
    lblDetalleTitulo.Font.Color := DARK_TEXT;
    lblAnioCaption.Font.Color := DARK_TEXT;
    lbCalendarios.Color := DARK_HEADER;
    lbCalendarios.Font.Color := DARK_TEXT;
    sbDetalle.Color := DARK_HEADER;
    Color := DARK_BG;
  end
  else
  begin
    LookAndFeel.SkinName := 'Office2019Colorful';
    pnlHeader.Color := clWhite;
    lblTitle.Font.Color := 4474440;
    lblSubtitle.Font.Color := clGray;
    shpHeaderLine.Brush.Color := 15061727;
    pnlLeft.Color := clBtnFace;
    pnlDetalle.Color := clBtnFace;
    pnlRight.Color := clBtnFace;
    pnlLeyenda.Color := clBtnFace;
    lblCalendarios.Font.Color := 4474440;
    lblDetalleTitulo.Font.Color := 4474440;
    lblAnioCaption.Font.Color := 4474440;
    lbCalendarios.Color := clWindow;
    lbCalendarios.Font.Color := clWindowText;
    sbDetalle.Color := clWindow;
    Color := clBtnFace;
  end;
end;

end.
