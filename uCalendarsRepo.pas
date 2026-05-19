unit uCalendarsRepo;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Variants, System.Generics.Collections,
  Data.Win.ADODB, Data.DB,
  uCentreCalendar;

type
  // Linea de modelo horario LABORABLE para un dia de semana (1=Lu..7=Do)
  TShiftModelLineRec = record
    DiaSemana: Integer;
    HoraInicio: TTime;
    HoraFin: TTime;
  end;

  // Modelo horario (plantilla) asociado a un calendario
  TShiftModelRec = record
    ShiftModelId: Integer;
    CalendarId: Integer;
    Nombre: string;
    Descripcion: string;
    EsDefault: Boolean;
    Activo: Boolean;
  end;

  // Excepcion per data concreta (festiu, pont, dia especial)
  TCalendarExceptionRec = record
    ExceptionId: Integer;
    CalendarId: Integer;
    Fecha: TDate;
    EsLaborable: Boolean;  // True = laborable parcial (usa HoraInicio/HoraFin); False = festiu
    HoraInicio: TTime;
    HoraFin: TTime;
    Descripcion: string;
  end;

  TCalendarsRepo = class
  private
    FConnection: TADOConnection;
    FCalendars: TObjectDictionary<Integer, TCentreCalendar>;
    procedure LoadDayRules(ACodigoEmpresa: SmallInt);
    procedure LoadAllExceptions(ACodigoEmpresa: SmallInt);
  public
    constructor Create(AConnection: TADOConnection);
    destructor Destroy; override;

    procedure LoadFromDB(ACodigoEmpresa: SmallInt);
    procedure Clear;

    function TryGetById(ACalendarId: Integer;
      out ACalendar: TCentreCalendar): Boolean;
    function GetById(ACalendarId: Integer): TCentreCalendar;
    function GetDefault: TCentreCalendar;
    function Count: Integer;

    // ----- Shift Models (V030) ----------------------------------------------
    function LoadShiftModels(ACodigoEmpresa: SmallInt;
      ACalendarId: Integer): TArray<TShiftModelRec>;
    function LoadShiftModelLines(ACodigoEmpresa: SmallInt;
      AShiftModelId: Integer): TArray<TShiftModelLineRec>;

    function AddShiftModel(ACodigoEmpresa: SmallInt; ACalendarId: Integer;
      const ANombre, ADescripcion: string): Integer;
    procedure UpdateShiftModel(ACodigoEmpresa: SmallInt; AShiftModelId: Integer;
      const ANombre, ADescripcion: string);
    procedure DeleteShiftModel(ACodigoEmpresa: SmallInt; AShiftModelId: Integer);

    // Reemplaza ATOMICAMENTE todas las lineas del modelo y reproyecta las
    // reglas no-laborables (FS_PL_CalendarDayRule) del calendario.
    procedure SaveShiftModelLines(ACodigoEmpresa: SmallInt;
      AShiftModelId: Integer; ACalendarId: Integer;
      const ALines: TArray<TShiftModelLineRec>);

    // Reproyecta SOLO las reglas no-laborables del calendario a partir de
    // sus modelos activos (union de lineas laborables --> complementario).
    procedure RebuildCalendarDayRules(ACodigoEmpresa: SmallInt;
      ACalendarId: Integer);

    // ----- Calendar Exceptions ----------------------------------------------
    function LoadExceptions(ACodigoEmpresa: SmallInt;
      ACalendarId: Integer): TArray<TCalendarExceptionRec>;
    function AddException(ACodigoEmpresa: SmallInt; ACalendarId: Integer;
      AFecha: TDate; AEsLaborable: Boolean; AHoraInicio, AHoraFin: TTime;
      const ADescripcion: string): Integer;
    procedure UpdateException(ACodigoEmpresa: SmallInt; AExceptionId: Integer;
      AFecha: TDate; AEsLaborable: Boolean; AHoraInicio, AHoraFin: TTime;
      const ADescripcion: string);
    procedure DeleteException(ACodigoEmpresa: SmallInt; AExceptionId: Integer);
  end;

implementation

constructor TCalendarsRepo.Create(AConnection: TADOConnection);
begin
  inherited Create;
  FConnection := AConnection;
  FCalendars := TObjectDictionary<Integer, TCentreCalendar>.Create([doOwnsValues]);
end;

destructor TCalendarsRepo.Destroy;
begin
  FCalendars.Free;
  inherited;
end;

procedure TCalendarsRepo.Clear;
begin
  FCalendars.Clear;
end;

function TCalendarsRepo.Count: Integer;
begin
  Result := FCalendars.Count;
end;

procedure TCalendarsRepo.LoadFromDB(ACodigoEmpresa: SmallInt);
var
  Q: TADOQuery;
  Cal: TCentreCalendar;
  Id: Integer;
begin
  Clear;
  if FConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT CalendarId, Nombre FROM FS_PL_Calendar ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa AND Activo = 1 ' +
      'ORDER BY CalendarId';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := ACodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      Id := Q.FieldByName('CalendarId').AsInteger;
      Cal := TCentreCalendar.Create;
      Cal.Name := Q.FieldByName('Nombre').AsString;
      FCalendars.Add(Id, Cal);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  LoadDayRules(ACodigoEmpresa);
  LoadAllExceptions(ACodigoEmpresa);
end;

procedure TCalendarsRepo.LoadAllExceptions(ACodigoEmpresa: SmallInt);
var
  Q: TADOQuery;
  CalId: Integer;
  Cal: TCentreCalendar;
  Exc: TDayException;
begin
  if FConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT CalendarId, Fecha, EsLaborable, ' +
      '  CAST(HoraInicio AS DATETIME) AS HoraIni, ' +
      '  CAST(HoraFin AS DATETIME)    AS HoraFin ' +
      'FROM FS_PL_CalendarException ' +
      'WHERE CodigoEmpresa = :CE';
    Q.Parameters.ParamByName('CE').Value := ACodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      CalId := Q.FieldByName('CalendarId').AsInteger;
      if FCalendars.TryGetValue(CalId, Cal) then
      begin
        Exc.EsLaborable := Q.FieldByName('EsLaborable').AsBoolean;
        if (not Q.FieldByName('HoraIni').IsNull) and Exc.EsLaborable then
          Exc.HoraInicio := Frac(Q.FieldByName('HoraIni').AsDateTime)
        else
          Exc.HoraInicio := 0;
        if (not Q.FieldByName('HoraFin').IsNull) and Exc.EsLaborable then
          Exc.HoraFin := Frac(Q.FieldByName('HoraFin').AsDateTime)
        else
          Exc.HoraFin := 1;
        Cal.SetDayException(Q.FieldByName('Fecha').AsDateTime, Exc);
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TCalendarsRepo.LoadDayRules(ACodigoEmpresa: SmallInt);
var
  Q: TADOQuery;
  CurrentCalId, DiaSemana: Integer;
  Cal: TCentreCalendar;
  Periods: TArray<TNonWorkingPeriod>;
  P: TNonWorkingPeriod;

  procedure FlushPeriods;
  begin
    if (Cal <> nil) and (Length(Periods) > 0) then
      Cal.SetDayNonWorkingPeriods(DiaSemana, Periods);
    SetLength(Periods, 0);
  end;

begin
  if FConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT CalendarId, DiaSemana, ' +
      '  CAST(HoraInicioNoLab AS DATETIME) AS HoraIni, ' +
      '  CAST(HoraFinNoLab AS DATETIME) AS HoraFin ' +
      'FROM FS_PL_CalendarDayRule ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa ' +
      'ORDER BY CalendarId, DiaSemana, HoraInicioNoLab';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := ACodigoEmpresa;
    Q.Open;

    CurrentCalId := -1;
    DiaSemana := -1;
    Cal := nil;
    SetLength(Periods, 0);

    while not Q.Eof do
    begin
      // Al cambiar de calendario o día, volcar lo acumulado
      if (Q.FieldByName('CalendarId').AsInteger <> CurrentCalId) or
         (Q.FieldByName('DiaSemana').AsInteger <> DiaSemana) then
      begin
        FlushPeriods;
        CurrentCalId := Q.FieldByName('CalendarId').AsInteger;
        DiaSemana := Q.FieldByName('DiaSemana').AsInteger;
        if not FCalendars.TryGetValue(CurrentCalId, Cal) then
          Cal := nil;
      end;

      if Cal <> nil then
      begin
        P.StartTimeOfDay := Frac(Q.FieldByName('HoraIni').AsDateTime);
        P.EndTimeOfDay := Frac(Q.FieldByName('HoraFin').AsDateTime);
        SetLength(Periods, Length(Periods) + 1);
        Periods[High(Periods)] := P;
      end;

      Q.Next;
    end;

    // Último bloque
    FlushPeriods;
  finally
    Q.Free;
  end;
end;

function TCalendarsRepo.TryGetById(ACalendarId: Integer;
  out ACalendar: TCentreCalendar): Boolean;
begin
  Result := FCalendars.TryGetValue(ACalendarId, ACalendar);
end;

function TCalendarsRepo.GetById(ACalendarId: Integer): TCentreCalendar;
begin
  if not FCalendars.TryGetValue(ACalendarId, Result) then
    Result := nil;
end;

function TCalendarsRepo.GetDefault: TCentreCalendar;
var
  Pair: TPair<Integer, TCentreCalendar>;
  MinId: Integer;
begin
  Result := nil;
  MinId := MaxInt;
  for Pair in FCalendars do
    if Pair.Key < MinId then
    begin
      MinId := Pair.Key;
      Result := Pair.Value;
    end;
end;

// ===========================================================================
// SHIFT MODELS (V030)
// ===========================================================================

function TCalendarsRepo.LoadShiftModels(ACodigoEmpresa: SmallInt;
  ACalendarId: Integer): TArray<TShiftModelRec>;
var
  Q: TADOQuery;
  M: TShiftModelRec;
  L: TList<TShiftModelRec>;
begin
  L := TList<TShiftModelRec>.Create;
  try
    if FConnection = nil then
      Exit(L.ToArray);

    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT ShiftModelId, CalendarId, Nombre, Descripcion, EsDefault, Activo ' +
        'FROM FS_PL_ShiftModel ' +
        'WHERE CodigoEmpresa = :CE AND CalendarId = :CalId AND Activo = 1 ' +
        'ORDER BY EsDefault DESC, Nombre';
      Q.Parameters.ParamByName('CE').Value := ACodigoEmpresa;
      Q.Parameters.ParamByName('CalId').Value := ACalendarId;
      Q.Open;
      while not Q.Eof do
      begin
        M.ShiftModelId := Q.FieldByName('ShiftModelId').AsInteger;
        M.CalendarId   := Q.FieldByName('CalendarId').AsInteger;
        M.Nombre       := Q.FieldByName('Nombre').AsString;
        M.Descripcion  := Q.FieldByName('Descripcion').AsString;
        M.EsDefault    := Q.FieldByName('EsDefault').AsBoolean;
        M.Activo       := Q.FieldByName('Activo').AsBoolean;
        L.Add(M);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TCalendarsRepo.LoadShiftModelLines(ACodigoEmpresa: SmallInt;
  AShiftModelId: Integer): TArray<TShiftModelLineRec>;
var
  Q: TADOQuery;
  L: TList<TShiftModelLineRec>;
  Ln: TShiftModelLineRec;
begin
  L := TList<TShiftModelLineRec>.Create;
  try
    if FConnection = nil then
      Exit(L.ToArray);

    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT DiaSemana, ' +
        '  CAST(HoraInicio AS DATETIME) AS HoraIni, ' +
        '  CAST(HoraFin AS DATETIME)    AS HoraFin ' +
        'FROM FS_PL_ShiftModelLine ' +
        'WHERE CodigoEmpresa = :CE AND ShiftModelId = :Mid ' +
        'ORDER BY DiaSemana, HoraInicio';
      Q.Parameters.ParamByName('CE').Value  := ACodigoEmpresa;
      Q.Parameters.ParamByName('Mid').Value := AShiftModelId;
      Q.Open;
      while not Q.Eof do
      begin
        Ln.DiaSemana  := Q.FieldByName('DiaSemana').AsInteger;
        Ln.HoraInicio := Frac(Q.FieldByName('HoraIni').AsDateTime);
        Ln.HoraFin    := Frac(Q.FieldByName('HoraFin').AsDateTime);
        L.Add(Ln);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TCalendarsRepo.AddShiftModel(ACodigoEmpresa: SmallInt;
  ACalendarId: Integer; const ANombre, ADescripcion: string): Integer;
var
  Q: TADOQuery;
begin
  Result := -1;
  if FConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'INSERT INTO FS_PL_ShiftModel ' +
      '  (CodigoEmpresa, CalendarId, Nombre, Descripcion, EsDefault, Activo) ' +
      'VALUES (:CE, :CalId, :Nom, :Desc, 0, 1); ' +
      'SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewId;';
    Q.Parameters.ParamByName('CE').Value    := ACodigoEmpresa;
    Q.Parameters.ParamByName('CalId').Value := ACalendarId;
    Q.Parameters.ParamByName('Nom').Value   := ANombre;
    Q.Parameters.ParamByName('Desc').Value  := ADescripcion;
    Q.Open;
    if not Q.Eof then
      Result := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TCalendarsRepo.UpdateShiftModel(ACodigoEmpresa: SmallInt;
  AShiftModelId: Integer; const ANombre, ADescripcion: string);
var
  Cmd: TADOCommand;
begin
  if FConnection = nil then Exit;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_ShiftModel SET Nombre = :Nom, Descripcion = :Desc ' +
      'WHERE CodigoEmpresa = :CE AND ShiftModelId = :Mid';
    Cmd.Parameters.ParamByName('Nom').Value  := ANombre;
    Cmd.Parameters.ParamByName('Desc').Value := ADescripcion;
    Cmd.Parameters.ParamByName('CE').Value   := ACodigoEmpresa;
    Cmd.Parameters.ParamByName('Mid').Value  := AShiftModelId;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TCalendarsRepo.DeleteShiftModel(ACodigoEmpresa: SmallInt;
  AShiftModelId: Integer);
var
  Cmd: TADOCommand;
  CalId: Integer;
  Q: TADOQuery;
begin
  if FConnection = nil then Exit;

  CalId := -1;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT CalendarId FROM FS_PL_ShiftModel ' +
      'WHERE CodigoEmpresa = :CE AND ShiftModelId = :Mid';
    Q.Parameters.ParamByName('CE').Value  := ACodigoEmpresa;
    Q.Parameters.ParamByName('Mid').Value := AShiftModelId;
    Q.Open;
    if not Q.Eof then
      CalId := Q.FieldByName('CalendarId').AsInteger;
  finally
    Q.Free;
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_ShiftModel ' +
      'WHERE CodigoEmpresa = :CE AND ShiftModelId = :Mid AND EsDefault = 0';
    Cmd.Parameters.ParamByName('CE').Value  := ACodigoEmpresa;
    Cmd.Parameters.ParamByName('Mid').Value := AShiftModelId;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  if CalId > 0 then
    RebuildCalendarDayRules(ACodigoEmpresa, CalId);
end;

procedure TCalendarsRepo.SaveShiftModelLines(ACodigoEmpresa: SmallInt;
  AShiftModelId: Integer; ACalendarId: Integer;
  const ALines: TArray<TShiftModelLineRec>);
var
  Cmd: TADOCommand;
  i: Integer;
  Tr: Boolean;
begin
  if FConnection = nil then Exit;

  Tr := False;
  try
    FConnection.BeginTrans;
    Tr := True;

    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := FConnection;
      Cmd.CommandText :=
        'DELETE FROM FS_PL_ShiftModelLine ' +
        'WHERE CodigoEmpresa = :CE AND ShiftModelId = :Mid';
      Cmd.Parameters.ParamByName('CE').Value  := ACodigoEmpresa;
      Cmd.Parameters.ParamByName('Mid').Value := AShiftModelId;
      Cmd.Execute;
    finally
      Cmd.Free;
    end;

    for i := 0 to High(ALines) do
    begin
      Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := FConnection;
        Cmd.CommandText :=
          'INSERT INTO FS_PL_ShiftModelLine ' +
          '  (CodigoEmpresa, ShiftModelId, DiaSemana, HoraInicio, HoraFin) ' +
          'VALUES (:CE, :Mid, :Dia, :Ini, :Fin)';
        Cmd.Parameters.ParamByName('CE').Value  := ACodigoEmpresa;
        Cmd.Parameters.ParamByName('Mid').Value := AShiftModelId;
        Cmd.Parameters.ParamByName('Dia').Value := ALines[i].DiaSemana;
        Cmd.Parameters.ParamByName('Ini').Value := FormatDateTime('hh:nn:ss', ALines[i].HoraInicio);
        Cmd.Parameters.ParamByName('Fin').Value := FormatDateTime('hh:nn:ss', ALines[i].HoraFin);
        Cmd.Execute;
      finally
        Cmd.Free;
      end;
    end;

    FConnection.CommitTrans;
    Tr := False;
  except
    if Tr then FConnection.RollbackTrans;
    raise;
  end;

  RebuildCalendarDayRules(ACodigoEmpresa, ACalendarId);
end;

procedure TCalendarsRepo.RebuildCalendarDayRules(ACodigoEmpresa: SmallInt;
  ACalendarId: Integer);
// Reproyecta FS_PL_CalendarDayRule a partir de FS_PL_ShiftModel(Line) del calendario.
// Estrategia simple: union de los tramos laborables de TODOS los modelos activos
// por dia, calculo del complementario [00:00..23:59], escritura.
const
  N_DAYS = 7;
  MIN_PER_DAY = 24 * 60;
type
  TDayMask = array[0..MIN_PER_DAY - 1] of Boolean;  // True = laborable
var
  Mask: array[1..N_DAYS] of TDayMask;
  i, d, m, mStart, mEnd: Integer;
  Q: TADOQuery;
  Cmd: TADOCommand;
  Dia: Integer;
  HIni, HFin: TTime;
  Tr: Boolean;
  RunStart: Integer;
  InRun: Boolean;
begin
  if FConnection = nil then Exit;

  for d := 1 to N_DAYS do
    for i := 0 to MIN_PER_DAY - 1 do
      Mask[d][i] := False;

  // Union de lineas laborables de modelos activos del calendario
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT l.DiaSemana, ' +
      '  CAST(l.HoraInicio AS DATETIME) AS HoraIni, ' +
      '  CAST(l.HoraFin AS DATETIME)    AS HoraFin ' +
      'FROM FS_PL_ShiftModelLine l ' +
      'INNER JOIN FS_PL_ShiftModel m ' +
      '  ON m.CodigoEmpresa = l.CodigoEmpresa AND m.ShiftModelId = l.ShiftModelId ' +
      'WHERE l.CodigoEmpresa = :CE AND m.CalendarId = :CalId AND m.Activo = 1';
    Q.Parameters.ParamByName('CE').Value    := ACodigoEmpresa;
    Q.Parameters.ParamByName('CalId').Value := ACalendarId;
    Q.Open;
    while not Q.Eof do
    begin
      Dia  := Q.FieldByName('DiaSemana').AsInteger;
      HIni := Frac(Q.FieldByName('HoraIni').AsDateTime);
      HFin := Frac(Q.FieldByName('HoraFin').AsDateTime);
      if (Dia >= 1) and (Dia <= N_DAYS) then
      begin
        mStart := Round(HIni * MIN_PER_DAY);
        mEnd   := Round(HFin * MIN_PER_DAY);
        if mStart < 0 then mStart := 0;
        if mEnd > MIN_PER_DAY then mEnd := MIN_PER_DAY;
        for m := mStart to mEnd - 1 do
          Mask[Dia][m] := True;
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  // Reescribir FS_PL_CalendarDayRule (no-laborables = huecos en la mascara)
  Tr := False;
  try
    FConnection.BeginTrans;
    Tr := True;

    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := FConnection;
      Cmd.CommandText :=
        'DELETE FROM FS_PL_CalendarDayRule ' +
        'WHERE CodigoEmpresa = :CE AND CalendarId = :CalId';
      Cmd.Parameters.ParamByName('CE').Value    := ACodigoEmpresa;
      Cmd.Parameters.ParamByName('CalId').Value := ACalendarId;
      Cmd.Execute;
    finally
      Cmd.Free;
    end;

    for d := 1 to N_DAYS do
    begin
      InRun := False;
      RunStart := 0;
      for m := 0 to MIN_PER_DAY - 1 do
      begin
        if (not Mask[d][m]) and (not InRun) then
        begin
          InRun := True;
          RunStart := m;
        end
        else if Mask[d][m] and InRun then
        begin
          // cerrar run [RunStart .. m)
          Cmd := TADOCommand.Create(nil);
          try
            Cmd.Connection := FConnection;
            Cmd.CommandText :=
              'INSERT INTO FS_PL_CalendarDayRule ' +
              '  (CodigoEmpresa, CalendarId, DiaSemana, HoraInicioNoLab, HoraFinNoLab) ' +
              'VALUES (:CE, :CalId, :Dia, :Ini, :Fin)';
            Cmd.Parameters.ParamByName('CE').Value    := ACodigoEmpresa;
            Cmd.Parameters.ParamByName('CalId').Value := ACalendarId;
            Cmd.Parameters.ParamByName('Dia').Value   := d;
            Cmd.Parameters.ParamByName('Ini').Value   := FormatDateTime('hh:nn:ss', RunStart / MIN_PER_DAY);
            Cmd.Parameters.ParamByName('Fin').Value   := FormatDateTime('hh:nn:ss', m / MIN_PER_DAY);
            Cmd.Execute;
          finally
            Cmd.Free;
          end;
          InRun := False;
        end;
      end;
      // run abierto al final del dia
      if InRun then
      begin
        Cmd := TADOCommand.Create(nil);
        try
          Cmd.Connection := FConnection;
          Cmd.CommandText :=
            'INSERT INTO FS_PL_CalendarDayRule ' +
            '  (CodigoEmpresa, CalendarId, DiaSemana, HoraInicioNoLab, HoraFinNoLab) ' +
            'VALUES (:CE, :CalId, :Dia, :Ini, :Fin)';
          Cmd.Parameters.ParamByName('CE').Value    := ACodigoEmpresa;
          Cmd.Parameters.ParamByName('CalId').Value := ACalendarId;
          Cmd.Parameters.ParamByName('Dia').Value   := d;
          Cmd.Parameters.ParamByName('Ini').Value   := FormatDateTime('hh:nn:ss', RunStart / MIN_PER_DAY);
          Cmd.Parameters.ParamByName('Fin').Value   := FormatDateTime('hh:nn:ss', (MIN_PER_DAY - 1) / MIN_PER_DAY);
          Cmd.Execute;
        finally
          Cmd.Free;
        end;
      end;
    end;

    FConnection.CommitTrans;
    Tr := False;
  except
    if Tr then FConnection.RollbackTrans;
    raise;
  end;
end;

// ===========================================================================
// CALENDAR EXCEPTIONS
// ===========================================================================

function TCalendarsRepo.LoadExceptions(ACodigoEmpresa: SmallInt;
  ACalendarId: Integer): TArray<TCalendarExceptionRec>;
var
  Q: TADOQuery;
  L: TList<TCalendarExceptionRec>;
  R: TCalendarExceptionRec;
begin
  L := TList<TCalendarExceptionRec>.Create;
  try
    if FConnection = nil then Exit(L.ToArray);

    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT ExceptionId, CalendarId, Fecha, EsLaborable, ' +
        '  CAST(HoraInicio AS DATETIME) AS HoraIni, ' +
        '  CAST(HoraFin AS DATETIME)    AS HoraFin, ' +
        '  Descripcion ' +
        'FROM FS_PL_CalendarException ' +
        'WHERE CodigoEmpresa = :CE AND CalendarId = :CalId ' +
        'ORDER BY Fecha';
      Q.Parameters.ParamByName('CE').Value    := ACodigoEmpresa;
      Q.Parameters.ParamByName('CalId').Value := ACalendarId;
      Q.Open;
      while not Q.Eof do
      begin
        R.ExceptionId  := Q.FieldByName('ExceptionId').AsInteger;
        R.CalendarId   := Q.FieldByName('CalendarId').AsInteger;
        R.Fecha        := Q.FieldByName('Fecha').AsDateTime;
        R.EsLaborable  := Q.FieldByName('EsLaborable').AsBoolean;
        if not Q.FieldByName('HoraIni').IsNull then
          R.HoraInicio := Frac(Q.FieldByName('HoraIni').AsDateTime)
        else
          R.HoraInicio := 0;
        if not Q.FieldByName('HoraFin').IsNull then
          R.HoraFin := Frac(Q.FieldByName('HoraFin').AsDateTime)
        else
          R.HoraFin := 0;
        R.Descripcion  := Q.FieldByName('Descripcion').AsString;
        L.Add(R);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TCalendarsRepo.AddException(ACodigoEmpresa: SmallInt;
  ACalendarId: Integer; AFecha: TDate; AEsLaborable: Boolean;
  AHoraInicio, AHoraFin: TTime; const ADescripcion: string): Integer;
var
  Q: TADOQuery;
  HIniLit, HFinLit: string;
begin
  Result := -1;
  if FConnection = nil then Exit;

  if AEsLaborable then
  begin
    HIniLit := '''' + FormatDateTime('hh:nn:ss', AHoraInicio) + '''';
    HFinLit := '''' + FormatDateTime('hh:nn:ss', AHoraFin) + '''';
  end
  else
  begin
    HIniLit := 'NULL';
    HFinLit := 'NULL';
  end;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'INSERT INTO FS_PL_CalendarException ' +
      '  (CodigoEmpresa, CalendarId, Fecha, EsLaborable, HoraInicio, HoraFin, Descripcion) ' +
      'VALUES (:CE, :CalId, :Fec, :Lab, ' + HIniLit + ', ' + HFinLit + ', :Desc); ' +
      'SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewId;';
    Q.Parameters.ParamByName('CE').Value    := ACodigoEmpresa;
    Q.Parameters.ParamByName('CalId').Value := ACalendarId;
    Q.Parameters.ParamByName('Fec').Value   := DateOf(AFecha);
    Q.Parameters.ParamByName('Lab').Value   := AEsLaborable;
    Q.Parameters.ParamByName('Desc').Value  := ADescripcion;
    Q.Open;
    if not Q.Eof then
      Result := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TCalendarsRepo.UpdateException(ACodigoEmpresa: SmallInt;
  AExceptionId: Integer; AFecha: TDate; AEsLaborable: Boolean;
  AHoraInicio, AHoraFin: TTime; const ADescripcion: string);
var
  Cmd: TADOCommand;
  HIniLit, HFinLit: string;
begin
  if FConnection = nil then Exit;

  if AEsLaborable then
  begin
    HIniLit := '''' + FormatDateTime('hh:nn:ss', AHoraInicio) + '''';
    HFinLit := '''' + FormatDateTime('hh:nn:ss', AHoraFin) + '''';
  end
  else
  begin
    HIniLit := 'NULL';
    HFinLit := 'NULL';
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_CalendarException SET ' +
      '  Fecha = :Fec, EsLaborable = :Lab, ' +
      '  HoraInicio = ' + HIniLit + ', HoraFin = ' + HFinLit + ', ' +
      '  Descripcion = :Desc ' +
      'WHERE CodigoEmpresa = :CE AND ExceptionId = :Eid';
    Cmd.Parameters.ParamByName('Fec').Value  := DateOf(AFecha);
    Cmd.Parameters.ParamByName('Lab').Value  := AEsLaborable;
    Cmd.Parameters.ParamByName('Desc').Value := ADescripcion;
    Cmd.Parameters.ParamByName('CE').Value   := ACodigoEmpresa;
    Cmd.Parameters.ParamByName('Eid').Value  := AExceptionId;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TCalendarsRepo.DeleteException(ACodigoEmpresa: SmallInt;
  AExceptionId: Integer);
var
  Cmd: TADOCommand;
begin
  if FConnection = nil then Exit;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_CalendarException ' +
      'WHERE CodigoEmpresa = :CE AND ExceptionId = :Eid';
    Cmd.Parameters.ParamByName('CE').Value  := ACodigoEmpresa;
    Cmd.Parameters.ParamByName('Eid').Value := AExceptionId;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

end.
