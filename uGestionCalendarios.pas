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
  uSampleDataGenerator, uCentreCalendar, uErpTypes, cxClasses,
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
    chkDarkMode: TCheckBox;
    pnlBottom: TPanel;
    btnCerrar: TButton;
    splMain: TSplitter;
    pnlLeft: TPanel;
    lblCalendarios: TLabel;
    lbCalendarios: TListBox;
    pnlCalToolbar: TPanel;
    btnCalAdd: TButton;
    btnCalEdit: TButton;
    btnCalDel: TButton;
    pnlDetalle: TPanel;
    lblDetalleTitulo: TLabel;
    memoDetalle: TMemo;
    pnlRight: TPanel;
    lblAnioCaption: TLabel;
    pnlLeyenda: TPanel;
    pbCalendar: TPaintBox;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCerrarClick(Sender: TObject);
    procedure chkDarkModeClick(Sender: TObject);
    procedure lbCalendariosClick(Sender: TObject);
    procedure pbCalendarPaint(Sender: TObject);
    procedure pbCalendarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure btnCalAddClick(Sender: TObject);
    procedure btnCalEditClick(Sender: TObject);
    procedure btnCalDelClick(Sender: TObject);
  private
    FSampleData: TSampleData;
    FGetCalendar: TGetCalendarFunc;
    FYear: Word;
    FDark: Boolean;
    FHoverDate: TDateTime;
    FHoverValid: Boolean;

    // Cache del calendario seleccionado
    FSelectedCalIdx: Integer;
    FDayTypes: array[1..12, 1..31] of TDayType;
    FWorkingMinutes: array[1..12, 1..31] of Integer;

    FCalendarIds: TArray<Integer>;  // CalendarId per cada entrada al ListBox

    procedure LoadCalendarioList;
    procedure LoadCalendarioListFromDB;
    procedure SelectCalendario(AIdx: Integer);
    procedure BuildDayCache;
    procedure BuildDetalleText;
    procedure BuildDetalleTextFromDB;
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
    class procedure Execute(
      const ASampleData: TSampleData;
      const AGetCalendar: TGetCalendarFunc;
      AYear: Word = 0
    );
  end;

var
  frmGestionCalendarios: TfrmGestionCalendarios;

implementation

uses
  uDMPlanner;

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

class procedure TfrmGestionCalendarios.Execute(
  const ASampleData: TSampleData;
  const AGetCalendar: TGetCalendarFunc;
  AYear: Word);
var
  F: TfrmGestionCalendarios;
begin
  F := TfrmGestionCalendarios.Create(Application);
  try
    F.FSampleData := ASampleData;
    F.FGetCalendar := AGetCalendar;
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
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure TfrmGestionCalendarios.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

{ ========== Lista calendarios ========== }

procedure TfrmGestionCalendarios.LoadCalendarioList;
begin
  if DMPlanner.IsConnected then
    LoadCalendarioListFromDB
  else
  begin
    // Fallback: cargar desde SampleData en memoria
    var I, J, CentroCount: Integer;
    var S: string;
    lbCalendarios.Items.Clear;
    SetLength(FCalendarIds, Length(FSampleData.Calendarios));
    for I := 0 to High(FSampleData.Calendarios) do
    begin
      CentroCount := 0;
      for J := 0 to High(FSampleData.CalendarioCentro) do
        if FSampleData.CalendarioCentro[J] = I then
          Inc(CentroCount);
      S := FSampleData.Calendarios[I].Nombre + '  (' + IntToStr(CentroCount) + ' centros)';
      lbCalendarios.Items.Add(S);
      FCalendarIds[I] := I; // usamos índice como ID en modo memoria
    end;
  end;

  if lbCalendarios.Items.Count > 0 then
  begin
    lbCalendarios.ItemIndex := 0;
    SelectCalendario(0);
  end;
end;

procedure TfrmGestionCalendarios.LoadCalendarioListFromDB;
var
  Q: TADOQuery;
  I: Integer;
  S: string;
  CentroCount: Integer;
begin
  lbCalendarios.Items.Clear;
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

      // Sincronizar también con FSampleData si hay espacio
      if I <= High(FSampleData.Calendarios) then
        FSampleData.Calendarios[I].Nombre := Q.FieldByName('Nombre').AsString;

      Inc(I);
      Q.Next;
    end;
    SetLength(FCalendarIds, I);
  finally
    Q.Free;
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
end;

{ ========== Build day cache ========== }

procedure TfrmGestionCalendarios.BuildDayCache;
var
  Mo, D, DaysInMo: Integer;
  ADate: TDateTime;
  Cal: TCentreCalendar;
  CentreIdx: Integer;
begin
  // Limpiar
  FillChar(FDayTypes, SizeOf(FDayTypes), 0);
  FillChar(FWorkingMinutes, SizeOf(FWorkingMinutes), 0);

  if FSelectedCalIdx < 0 then Exit;

  // Buscar primer centro que use este calendario para obtener el TCentreCalendar
  Cal := nil;
  for CentreIdx := 0 to High(FSampleData.CalendarioCentro) do
    if FSampleData.CalendarioCentro[CentreIdx] = FSelectedCalIdx then
    begin
      Cal := FGetCalendar(FSampleData.Centros[CentreIdx].Id);
      Break;
    end;

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
  Periods: TArray<TNonWorkingPeriod>;
  TotalNW: Double;
  P: TNonWorkingPeriod;
begin
  Periods := ACal.NonWorkingPeriodsForDate(ADate);

  if Length(Periods) = 0 then
    Exit(dtLaborable);

  // Calcular tiempo total no laborable
  TotalNW := 0;
  for P in Periods do
    TotalNW := TotalNW + (P.EndTimeOfDay - P.StartTimeOfDay);

  // Si cubre ~24h es no laborable completo
  if TotalNW >= (23.5 / 24.0) then
    Result := dtNoLaborable
  else
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
begin
  if DMPlanner.IsConnected then
    BuildDetalleTextFromDB
  else
  begin
    // Fallback: usar SampleData en memoria
    var Cal: TSampleCalendario;
    var I, J: Integer;
    var S: string;
    var TotalLab, TotalNoLab, TotalParcial: Integer;
    var Mo, D, DaysInMo: Integer;

    memoDetalle.Lines.Clear;
    if (FSelectedCalIdx < 0) or (FSelectedCalIdx > High(FSampleData.Calendarios)) then
      Exit;

    Cal := FSampleData.Calendarios[FSelectedCalIdx];
    memoDetalle.Lines.Add('CALENDARIO: ' + Cal.Nombre);
    memoDetalle.Lines.Add('');

    if Length(Cal.PeriodosLV) = 0 then
      memoDetalle.Lines.Add('L-V: 24h laborable')
    else
    begin
      memoDetalle.Lines.Add('L-V periodos NO laborables:');
      for I := 0 to High(Cal.PeriodosLV) do
      begin
        S := Format('  %02d:%02d - %02d:%02d', [
          Cal.PeriodosLV[I].StartH, Cal.PeriodosLV[I].StartM,
          Cal.PeriodosLV[I].EndH, Cal.PeriodosLV[I].EndM]);
        memoDetalle.Lines.Add(S);
      end;
    end;

    memoDetalle.Lines.Add('');
    if Cal.FinDeSemanaCompleto then
      memoDetalle.Lines.Add('Fin de semana: CERRADO')
    else
      memoDetalle.Lines.Add('Fin de semana: ABIERTO');

    memoDetalle.Lines.Add('');
    memoDetalle.Lines.Add('Centros asignados:');
    for J := 0 to High(FSampleData.CalendarioCentro) do
      if FSampleData.CalendarioCentro[J] = FSelectedCalIdx then
        memoDetalle.Lines.Add('  ' + FSampleData.Centros[J].Titulo);

    TotalLab := 0; TotalNoLab := 0; TotalParcial := 0;
    for Mo := 1 to 12 do
    begin
      DaysInMo := DaysInMonth(EncodeDate(FYear, Mo, 1));
      for D := 1 to DaysInMo do
        case FDayTypes[Mo, D] of
          dtLaborable: Inc(TotalLab);
          dtNoLaborable: Inc(TotalNoLab);
          dtParcial: Inc(TotalParcial);
        end;
    end;
    memoDetalle.Lines.Add('');
    memoDetalle.Lines.Add(Format('--- Resumen %d ---', [FYear]));
    memoDetalle.Lines.Add(Format('Laborables 24h:  %d', [TotalLab]));
    memoDetalle.Lines.Add(Format('Parciales:       %d', [TotalParcial]));
    memoDetalle.Lines.Add(Format('No laborables:   %d', [TotalNoLab]));
    memoDetalle.Lines.Add(Format('Total dias:      %d', [TotalLab + TotalParcial + TotalNoLab]));
  end;
end;

procedure TfrmGestionCalendarios.BuildDetalleTextFromDB;
var
  Q: TADOQuery;
  CalId: Integer;
  CalNombre: string;
  TotalLab, TotalNoLab, TotalParcial: Integer;
  Mo, D, DaysInMo: Integer;
  CE: string;
begin
  memoDetalle.Lines.Clear;
  if (FSelectedCalIdx < 0) or (FSelectedCalIdx > High(FCalendarIds)) then Exit;

  CalId := FCalendarIds[FSelectedCalIdx];
  CE := IntToStr(DMPlanner.CodigoEmpresa);

  // Nombre del calendario
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT Nombre, Descripcion FROM FS_PL_Calendar WHERE CodigoEmpresa = ' +
      CE + ' AND CalendarId = ' + IntToStr(CalId);
    Q.Open;
    if Q.Eof then Exit;
    CalNombre := Q.FieldByName('Nombre').AsString;
    memoDetalle.Lines.Add('CALENDARIO: ' + CalNombre);
    if Q.FieldByName('Descripcion').AsString <> '' then
      memoDetalle.Lines.Add(Q.FieldByName('Descripcion').AsString);
    memoDetalle.Lines.Add('');
  finally
    Q.Free;
  end;

  // Períodos no laborables L-V (día 1 como ejemplo)
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT DiaSemana, ' +
      'CONVERT(VARCHAR(5), HoraInicioNoLab, 108) AS HoraInicio, ' +
      'CONVERT(VARCHAR(5), HoraFinNoLab, 108) AS HoraFin ' +
      'FROM FS_PL_CalendarDayRule ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND CalendarId = ' + IntToStr(CalId) +
      ' AND DiaSemana = 1 ORDER BY HoraInicioNoLab';
    Q.Open;
    if Q.Eof then
      memoDetalle.Lines.Add('L-V: 24h laborable')
    else
    begin
      memoDetalle.Lines.Add('L-V periodos NO laborables:');
      while not Q.Eof do
      begin
        memoDetalle.Lines.Add('  ' +
          Q.FieldByName('HoraInicio').AsString + ' - ' +
          Q.FieldByName('HoraFin').AsString);
        Q.Next;
      end;
    end;
  finally
    Q.Free;
  end;

  // Fin de semana
  memoDetalle.Lines.Add('');
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT COUNT(*) AS Cnt FROM FS_PL_CalendarDayRule ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND CalendarId = ' + IntToStr(CalId) +
      ' AND DiaSemana IN (6,7)';
    Q.Open;
    if Q.FieldByName('Cnt').AsInteger > 0 then
      memoDetalle.Lines.Add('Fin de semana: CERRADO')
    else
      memoDetalle.Lines.Add('Fin de semana: ABIERTO');
  finally
    Q.Free;
  end;

  // Centros asignados
  memoDetalle.Lines.Add('');
  memoDetalle.Lines.Add('Centros asignados:');
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
      memoDetalle.Lines.Add('  ' + Q.FieldByName('Titulo').AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  // Estadísticas anuales
  TotalLab := 0; TotalNoLab := 0; TotalParcial := 0;
  for Mo := 1 to 12 do
  begin
    DaysInMo := DaysInMonth(EncodeDate(FYear, Mo, 1));
    for D := 1 to DaysInMo do
      case FDayTypes[Mo, D] of
        dtLaborable: Inc(TotalLab);
        dtNoLaborable: Inc(TotalNoLab);
        dtParcial: Inc(TotalParcial);
      end;
  end;
  memoDetalle.Lines.Add('');
  memoDetalle.Lines.Add(Format('--- Resumen %d ---', [FYear]));
  memoDetalle.Lines.Add(Format('Laborables 24h:  %d', [TotalLab]));
  memoDetalle.Lines.Add(Format('Parciales:       %d', [TotalParcial]));
  memoDetalle.Lines.Add(Format('No laborables:   %d', [TotalNoLab]));
  memoDetalle.Lines.Add(Format('Total dias:      %d', [TotalLab + TotalParcial + TotalNoLab]));
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
begin
  C := pbCalendar.Canvas;

  // Fondo
  C.Brush.Color := ColorFondo;
  C.FillRect(pbCalendar.ClientRect);

  TodayDate := DateOf(Now);
  DayNamesH := 14;

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

  AddLeyendaItem(pnlLeyenda, 8, ColorLaborable, 'Laborable 24h');
  AddLeyendaItem(pnlLeyenda, 148, ColorParcial, 'Parcial');
  AddLeyendaItem(pnlLeyenda, 260, ColorNoLaborable, 'No laborable');
  AddLeyendaItem(pnlLeyenda, 400, ColorSinCalendario, 'Sin calendario');
end;

{ ========== Dark Mode ========== }

procedure TfrmGestionCalendarios.chkDarkModeClick(Sender: TObject);
begin
  FDark := chkDarkMode.Checked;
  ApplyDarkMode(FDark);
  PaintLeyenda;
  pbCalendar.Invalidate;
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
  Desc := InputBox('Editar Calendario', 'Descripción:', Desc);

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

  if MessageDlg('¿Eliminar calendario "' + CalNom + '"?' + sLineBreak +
    'Se eliminarán también sus reglas y asignaciones a centros.',
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
    chkDarkMode.Font.Color := DARK_TEXT;
    pnlBottom.Color := DARK_HEADER;
    pnlLeft.Color := DARK_BG;
    pnlDetalle.Color := DARK_BG;
    pnlRight.Color := DARK_BG;
    pnlLeyenda.Color := DARK_BG;
    lblCalendarios.Font.Color := DARK_TEXT;
    lblDetalleTitulo.Font.Color := DARK_TEXT;
    lblAnioCaption.Font.Color := DARK_TEXT;
    lbCalendarios.Color := DARK_HEADER;
    lbCalendarios.Font.Color := DARK_TEXT;
    memoDetalle.Color := DARK_HEADER;
    memoDetalle.Font.Color := DARK_TEXT;
    Color := DARK_BG;
  end
  else
  begin
    LookAndFeel.SkinName := 'Office2019Colorful';
    pnlHeader.Color := clWhite;
    lblTitle.Font.Color := 4474440;
    lblSubtitle.Font.Color := clGray;
    shpHeaderLine.Brush.Color := 15061727;
    chkDarkMode.Font.Color := clWindowText;
    pnlBottom.Color := clBtnFace;
    pnlLeft.Color := clBtnFace;
    pnlDetalle.Color := clBtnFace;
    pnlRight.Color := clBtnFace;
    pnlLeyenda.Color := clBtnFace;
    lblCalendarios.Font.Color := 4474440;
    lblDetalleTitulo.Font.Color := 4474440;
    lblAnioCaption.Font.Color := 4474440;
    lbCalendarios.Color := clWindow;
    lbCalendarios.Font.Color := clWindowText;
    memoDetalle.Color := clWindow;
    memoDetalle.Font.Color := clWindowText;
    Color := clBtnFace;
  end;
end;

end.
