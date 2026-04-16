unit uCalendarsRepo;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.Win.ADODB, Data.DB,
  uCentreCalendar;

type
  TCalendarsRepo = class
  private
    FConnection: TADOConnection;
    FCalendars: TObjectDictionary<Integer, TCentreCalendar>;
    procedure LoadDayRules(ACodigoEmpresa: SmallInt);
  public
    constructor Create(AConnection: TADOConnection);
    destructor Destroy; override;

    procedure LoadFromDB(ACodigoEmpresa: SmallInt);
    procedure Clear;

    function TryGetById(ACalendarId: Integer;
      out ACalendar: TCentreCalendar): Boolean;
    function GetById(ACalendarId: Integer): TCentreCalendar;
    function Count: Integer;
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

end.
