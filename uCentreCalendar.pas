unit uCentreCalendar;

interface

uses
  System.SysUtils, System.DateUtils, System.Generics.Collections,
  System.Generics.Defaults, System.Math;

type
  TAbsInterval = record
    S, E: TDateTime; // [S, E)
  end;

  TNonWorkingPeriod = record
    StartTimeOfDay: TTime; // dins el dia
    EndTimeOfDay: TTime;
  end;

  TDayRule = record
    WeekDay: Integer; // 1=Mon..7=Sun (ISO)
    Periods: TArray<TNonWorkingPeriod>;
  end;

  TCentreCalendar = class
  private
    FName: string;
    FRules: TDictionary<Integer, TArray<TNonWorkingPeriod>>;   // WeekDayISO -> periods
    FDayIntervalsCache: TDictionary<Integer, TArray<TAbsInterval>>;      // Trunc(Date) -> intervals absoluts del dia
    FMergedAroundCache: TDictionary<Integer, TArray<TAbsInterval>>;      // Trunc(Date) -> intervals mergejats de [D-2 .. D+2]

    function IsoWeekDay(const ADate: TDateTime): Integer;
    function GetPeriodsForDate(const ADate: TDateTime): TArray<TNonWorkingPeriod>;

    function BuildNonWorkingIntervalsForDate(const ADate: TDateTime): TArray<TAbsInterval>;
    function BuildNonWorkingIntervalsForDateCached(const ADate: TDateTime): TArray<TAbsInterval>;

    function BuildNonWorkingIntervalsForRange(const ADateFrom, ADateTo: TDateTime): TArray<TAbsInterval>;
    function GetMergedIntervalsAround(const T: TDateTime): TArray<TAbsInterval>;

    function MergeIntervals(const A: TArray<TAbsInterval>): TArray<TAbsInterval>;
    function IsInInterval(const T: TDateTime; const I: TAbsInterval): Boolean;
    function MinuteSpan(const A, B: TDateTime): Integer;

    procedure InvalidateCaches;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetDayNonWorkingPeriods(const WeekDayISO: Integer; const Periods: TArray<TNonWorkingPeriod>);

    function IsNonWorkingTime(const T: TDateTime): Boolean;
    function IsWorkingTime(const T: TDateTime): Boolean;

    function NextWorkingTime(const T: TDateTime): TDateTime;
    function PrevWorkingTime(const T: TDateTime): TDateTime;

    function WorkingMinutesBetween(const AStart, AEnd: TDateTime): Integer;
    function AddWorkingMinutes(const Start: TDateTime; Minutes: Integer): TDateTime;
    function SubtractWorkingMinutes(const FromEnd: TDateTime; Minutes: Integer): TDateTime;

    function NonWorkingPeriodsForDate(const ADate: TDateTime): TArray<TNonWorkingPeriod>;

    function BuildMergedNonWorkingIntervalsForWindow(
             const AStart, AEnd: TDateTime): TArray<TAbsInterval>;
    function WorkingMinutesBetweenPrecomputed(
              const AStart, AEnd: TDateTime;
              const AMergedNonWorking: TArray<TAbsInterval>
            ): Integer;

  published
    property Name: string read FName write FName;
  end;

procedure NormalizeByDuration(
  const Cal: TCentreCalendar;
  var AStart, AEnd: TDateTime;
  const DurationMin: Double;
  const MinMinutes: Integer = 1);

procedure NormalizePlannedInterval(
  const Cal: TCentreCalendar;
  var AStart, AEnd: TDateTime;
  const DurationMin: Double;
  const MinMinutes: Integer = 1);


function IsAlmostEndOfDay(const T: TDateTime): Boolean;

function NormalizeTimeBoundary(const T: TDateTime): TDateTime;
implementation

const
  COneMinute = 1 / 1440;
  COneMs     = 1 / MSecsPerDay;

function IsAlmostEndOfDay(const T: TDateTime): Boolean;
const
  OneSecond = 1 / SecsPerDay;
begin
  Result := Frac(T) >= (1 - OneSecond);
end;
function NormalizeTimeBoundary(const T: TDateTime): TDateTime;
begin
  // Si �s 23:59:59 o molt proper, tracta-ho com 00:00
  if IsAlmostEndOfDay(T) then
    Result := 0
  else
    Result := Frac(T);
end;

function FloorToMinute(const T: TDateTime): TDateTime;
begin
  if IsAlmostEndOfDay(T) then
    Result := IncDay(DateOf(T), 1)
  else
    Result := RecodeMilliSecond(RecodeSecond(T, 0), 0);
end;

function MaxDT(const A, B: TDateTime): TDateTime; inline;
begin
  if A > B then Result := A else Result := B;
end;

function MinDT(const A, B: TDateTime): TDateTime; inline;
begin
  if A < B then Result := A else Result := B;
end;

{ TCentreCalendar }

constructor TCentreCalendar.Create;
begin
  inherited;
  FRules := TDictionary<Integer, TArray<TNonWorkingPeriod>>.Create;
  FDayIntervalsCache := TDictionary<Integer, TArray<TAbsInterval>>.Create;
  FMergedAroundCache := TDictionary<Integer, TArray<TAbsInterval>>.Create;
end;

destructor TCentreCalendar.Destroy;
begin
  FMergedAroundCache.Free;
  FDayIntervalsCache.Free;
  FRules.Free;
  inherited;
end;

procedure TCentreCalendar.InvalidateCaches;
begin
  FDayIntervalsCache.Clear;
  FMergedAroundCache.Clear;
end;

function TCentreCalendar.IsoWeekDay(const ADate: TDateTime): Integer;
begin
  // DayOfTheWeek: 1=Sun..7=Sat
  Result := DayOfTheWeek(ADate) - 1; // 0=Sun..6=Sat
  if Result = 0 then
    Result := 7; // Sunday -> 7
end;

function TCentreCalendar.NonWorkingPeriodsForDate(
  const ADate: TDateTime): TArray<TNonWorkingPeriod>;
begin
  Result := GetPeriodsForDate(ADate);
end;


function TCentreCalendar.BuildMergedNonWorkingIntervalsForWindow(
  const AStart, AEnd: TDateTime): TArray<TAbsInterval>;
var
  D: TDateTime;
  DayInts: TArray<TAbsInterval>;
  Tmp: TArray<TAbsInterval>;
  I, Base: Integer;
begin
  SetLength(Tmp, 0);

  if AEnd <= AStart then
    Exit(Tmp);

  D := DateOf(AStart);
  while D <= DateOf(AEnd) do
  begin
    // OJO: usa la versi�n NO cacheada, as� evitamos escrituras concurrentes
    DayInts := BuildNonWorkingIntervalsForDate(D);

    Base := Length(Tmp);
    SetLength(Tmp, Base + Length(DayInts));

    for I := 0 to High(DayInts) do
      Tmp[Base + I] := DayInts[I];

    D := IncDay(D, 1);
  end;

  Result := MergeIntervals(Tmp);
end;


function TCentreCalendar.WorkingMinutesBetweenPrecomputed(
  const AStart, AEnd: TDateTime;
  const AMergedNonWorking: TArray<TAbsInterval>
): Integer;
var
  S, E: TDateTime;
  I: Integer;
  NonWorkingMin: Double;
  OvStart, OvEnd: TDateTime;
begin
  Result := 0;

  if AEnd <= AStart then
    Exit;

  S := FloorToMinute(AStart);
  E := FloorToMinute(AEnd);

  if E <= S then
    Exit;

  NonWorkingMin := 0;

  for I := 0 to High(AMergedNonWorking) do
  begin
    if AMergedNonWorking[I].E <= S then
      Continue;

    if AMergedNonWorking[I].S >= E then
      Break;

    OvStart := MaxDT(S, AMergedNonWorking[I].S);
    OvEnd   := MinDT(E, AMergedNonWorking[I].E);

    if OvEnd > OvStart then
      NonWorkingMin := NonWorkingMin + ((OvEnd - OvStart) * 1440.0);
  end;

  Result := Trunc(((E - S) * 1440.0) - NonWorkingMin + 1e-9);
  if Result < 0 then
    Result := 0;
end;


procedure TCentreCalendar.SetDayNonWorkingPeriods(const WeekDayISO: Integer;
  const Periods: TArray<TNonWorkingPeriod>);
begin
  FRules.AddOrSetValue(WeekDayISO, Copy(Periods));
  InvalidateCaches;
end;

function TCentreCalendar.GetPeriodsForDate(
  const ADate: TDateTime): TArray<TNonWorkingPeriod>;
var
  wd, WdStd: Integer;
begin
  //wd := IsoWeekDay(ADate);
   wd := DayOfTheWeek(ADate);

  if not FRules.TryGetValue(wd, Result) then
    SetLength(Result, 0);
end;

function TCentreCalendar.BuildNonWorkingIntervalsForDate(
  const ADate: TDateTime): TArray<TAbsInterval>;
var
  P: TNonWorkingPeriod;
  Periods: TArray<TNonWorkingPeriod>;
  D0: TDateTime;
  A, B: TDateTime;
  StartTOD, EndTOD: TDateTime;
  Tmp: TArray<TAbsInterval>;
  C: Integer;

  procedure AddInt(const S, E: TDateTime);
  begin
    if E <= S then
      Exit;
    SetLength(Tmp, C + 1);
    Tmp[C].S := S;
    Tmp[C].E := E;
    Inc(C);
  end;

begin
  D0 := DateOf(ADate);
  Periods := GetPeriodsForDate(D0);

  C := 0;
  SetLength(Tmp, 0);

  for P in Periods do
  begin
    StartTOD := NormalizeTimeBoundary(P.StartTimeOfDay);
    EndTOD   := NormalizeTimeBoundary(P.EndTimeOfDay);

    A := D0 + StartTOD;
    B := D0 + EndTOD;

    // cas especial: acaba a "final de dia" => realment �s 00:00 del dia seg�ent
    if (EndTOD = 0) and (StartTOD > 0) then
      B := IncDay(D0, 1)
    else if B <= A then
      B := IncDay(B, 1);

    AddInt(A, B);
  end;

  Result := Tmp;
end;

function TCentreCalendar.BuildNonWorkingIntervalsForDateCached(
  const ADate: TDateTime): TArray<TAbsInterval>;
var
  Key: Integer;
begin
  Key := Trunc(DateOf(ADate));

  if not FDayIntervalsCache.TryGetValue(Key, Result) then
  begin
    Result := BuildNonWorkingIntervalsForDate(ADate);
    FDayIntervalsCache.Add(Key, Result);
  end;
end;

function TCentreCalendar.BuildNonWorkingIntervalsForRange(
  const ADateFrom, ADateTo: TDateTime): TArray<TAbsInterval>;
var
  D: TDateTime;
  DayInts: TArray<TAbsInterval>;
  I, Base: Integer;
begin
  SetLength(Result, 0);

  D := DateOf(ADateFrom);
  while D <= DateOf(ADateTo) do
  begin
    DayInts := BuildNonWorkingIntervalsForDateCached(D);

    Base := Length(Result);
    SetLength(Result, Base + Length(DayInts));

    for I := 0 to High(DayInts) do
      Result[Base + I] := DayInts[I];

    D := IncDay(D, 1);
  end;
end;

function TCentreCalendar.MergeIntervals(
  const A: TArray<TAbsInterval>): TArray<TAbsInterval>;
var
  Sorted: TArray<TAbsInterval>;
  I, C: Integer;
begin
  if Length(A) <= 1 then
    Exit(Copy(A));

  Sorted := Copy(A);

  TArray.Sort<TAbsInterval>(Sorted,
    TComparer<TAbsInterval>.Construct(
      function(const L, R: TAbsInterval): Integer
      begin
        if L.S < R.S then Exit(-1);
        if L.S > R.S then Exit(1);
        if L.E < R.E then Exit(-1);
        if L.E > R.E then Exit(1);
        Result := 0;
      end));

  SetLength(Result, 1);
  Result[0] := Sorted[0];
  C := 1;

  for I := 1 to High(Sorted) do
  begin
    // Fusiona si se solapen o toquen
    if Sorted[I].S <= Result[C - 1].E + COneMs then
    begin
      if Sorted[I].E > Result[C - 1].E then
        Result[C - 1].E := Sorted[I].E;
    end
    else
    begin
      SetLength(Result, C + 1);
      Result[C] := Sorted[I];
      Inc(C);
    end;
  end;
end;

function TCentreCalendar.GetMergedIntervalsAround(
  const T: TDateTime): TArray<TAbsInterval>;
var
  Key: Integer;
begin
  Key := Trunc(DateOf(T));

  if not FMergedAroundCache.TryGetValue(Key, Result) then
  begin
    // finestra suficient per capturar blocs que travessen mitjanit i adjacents
    Result := MergeIntervals(
      BuildNonWorkingIntervalsForRange(IncDay(DateOf(T), -2), IncDay(DateOf(T), 2))
    );
    FMergedAroundCache.Add(Key, Result);
  end;
end;

function TCentreCalendar.IsInInterval(const T: TDateTime;
  const I: TAbsInterval): Boolean;
begin
  Result := (T >= I.S) and (T < I.E);
end;

function TCentreCalendar.MinuteSpan(const A, B: TDateTime): Integer;
begin
  Result := Trunc((B - A) * 1440.0 + 1e-9);
end;

function TCentreCalendar.IsNonWorkingTime(const T: TDateTime): Boolean;
var
  Ints: TArray<TAbsInterval>;
  I: Integer;
  X: TDateTime;
begin
  X := FloorToMinute(T);
  Ints := GetMergedIntervalsAround(X);

  for I := 0 to High(Ints) do
    if IsInInterval(X, Ints[I]) then
      Exit(True);

  Result := False;
end;

function TCentreCalendar.IsWorkingTime(const T: TDateTime): Boolean;
begin
  Result := not IsNonWorkingTime(T);
end;

function TCentreCalendar.NextWorkingTime(const T: TDateTime): TDateTime;
var
  Cur: TDateTime;
  Ints: TArray<TAbsInterval>;
  I: Integer;
begin
  Cur := FloorToMinute(T);
  Ints := GetMergedIntervalsAround(Cur);

  for I := 0 to High(Ints) do
    if IsInInterval(Cur, Ints[I]) then
      Exit(FloorToMinute(Ints[I].E));

  Result := Cur;
end;

function TCentreCalendar.PrevWorkingTime(const T: TDateTime): TDateTime;
var
  Cur: TDateTime;
  Ints: TArray<TAbsInterval>;
  I: Integer;
begin
  Cur := FloorToMinute(T);
  Ints := GetMergedIntervalsAround(Cur);

  for I := 0 to High(Ints) do
  begin
    // dins del tram non-working o just al seu final
    if (Cur > Ints[I].S) and (Cur <= Ints[I].E) then
      Exit(FloorToMinute(Ints[I].S - COneMinute));
  end;

  Result := Cur;
end;

function TCentreCalendar.WorkingMinutesBetween(const AStart,
  AEnd: TDateTime): Integer;
var
  Cur, Limit: TDateTime;
  Ints: TArray<TAbsInterval>;
  I: Integer;
  NextStop: TDateTime;
begin
  Result := 0;
  if AEnd <= AStart then
    Exit;

  Cur := FloorToMinute(AStart);
  Limit := FloorToMinute(AEnd);

  while Cur < Limit do
  begin
    Cur := NextWorkingTime(Cur);
    if Cur >= Limit then
      Exit;

    Ints := GetMergedIntervalsAround(Cur);
    NextStop := Limit;

    for I := 0 to High(Ints) do
    begin
      if Ints[I].S > Cur then
      begin
        NextStop := MinDT(NextStop, Ints[I].S);
        Break;
      end;
    end;

    if NextStop > Cur then
    begin
      Inc(Result, MinuteSpan(Cur, NextStop));
      Cur := NextStop;
    end
    else
      Cur := Cur + COneMinute;
  end;
end;

function TCentreCalendar.AddWorkingMinutes(const Start: TDateTime;
  Minutes: Integer): TDateTime;
var
  Cur: TDateTime;
  Remaining: Integer;
  Ints: TArray<TAbsInterval>;
  I: Integer;
  NextBreak, AdvanceTo: TDateTime;
  SpanMin: Integer;
begin
  if Minutes <= 0 then
    Exit(FloorToMinute(Start));

  Remaining := Minutes;
  Cur := NextWorkingTime(Start);

  while Remaining > 0 do
  begin
    Cur := NextWorkingTime(Cur);
    Ints := GetMergedIntervalsAround(Cur);

    NextBreak := 0;
    for I := 0 to High(Ints) do
    begin
      if Ints[I].S > Cur then
      begin
        NextBreak := Ints[I].S;
        Break;
      end;
    end;

    // No hi ha cap tall non-working proper dins la finestra cachejada
    if NextBreak = 0 then
    begin
      AdvanceTo := Cur + (Remaining / 1440.0);
      Exit(FloorToMinute(AdvanceTo));
    end;

    SpanMin := MinuteSpan(Cur, NextBreak);

    if SpanMin <= 0 then
    begin
      Cur := NextWorkingTime(NextBreak);
      Continue;
    end;

    if Remaining < SpanMin then
      Exit(FloorToMinute(Cur + (Remaining / 1440.0)));

    Cur := NextBreak;
    Dec(Remaining, SpanMin);
  end;

  Result := Cur;
end;

function TCentreCalendar.SubtractWorkingMinutes(const FromEnd: TDateTime;
  Minutes: Integer): TDateTime;
var
  Cur: TDateTime;
  Remaining: Integer;
  Ints: TArray<TAbsInterval>;
  I: Integer;
  PrevBreakEnd: TDateTime;
  SpanMin: Integer;
begin
  if Minutes <= 0 then
    Exit(FloorToMinute(FromEnd));

  Remaining := Minutes;
  Cur := PrevWorkingTime(FromEnd);

  while Remaining > 0 do
  begin
    Cur := PrevWorkingTime(Cur);
    Ints := GetMergedIntervalsAround(Cur);

    // Cercar el tram non-working que acaba just abans (o al) de Cur
    PrevBreakEnd := 0;
    for I := High(Ints) downto 0 do
    begin
      if Ints[I].E <= Cur then
      begin
        PrevBreakEnd := Ints[I].E;
        Break;
      end;
    end;

    // No hi ha cap tall non-working anterior dins la finestra cachejada
    if PrevBreakEnd = 0 then
    begin
      Result := FloorToMinute(Cur - (Remaining / 1440.0));
      Exit;
    end;

    SpanMin := MinuteSpan(PrevBreakEnd, Cur);

    if SpanMin <= 0 then
    begin
      Cur := PrevWorkingTime(PrevBreakEnd);
      Continue;
    end;

    if Remaining <= SpanMin then
      Exit(FloorToMinute(Cur - (Remaining / 1440.0)));

    Cur := PrevBreakEnd;
    Dec(Remaining, SpanMin);
  end;

  Result := Cur;
end;


procedure NormalizeByDuration(
  const Cal: TCentreCalendar;
  var AStart, AEnd: TDateTime;
  const DurationMin: Double;
  const MinMinutes: Integer = 1);
var
  Mins: Integer;
  S: TDateTime;
begin
  if Cal = nil then
  begin
    AStart := FloorToMinute(AStart);
    AEnd := FloorToMinute(AEnd);
    Exit;
  end;

  Mins := Ceil(DurationMin);
  if Mins < MinMinutes then
    Mins := MinMinutes;

  S := FloorToMinute(AStart);

  if Cal.IsNonWorkingTime(S) then
    S := Cal.NextWorkingTime(S);

  S := FloorToMinute(S);

  AStart := S;
  AEnd := FloorToMinute(Cal.AddWorkingMinutes(AStart, Mins));

  if AEnd <= AStart then
    AEnd := FloorToMinute(Cal.AddWorkingMinutes(AStart, MinMinutes));
end;

procedure NormalizePlannedInterval(
  const Cal: TCentreCalendar;
  var AStart, AEnd: TDateTime;
  const DurationMin: Double;
  const MinMinutes: Integer = 1);
var
  Mins: Integer;
  S: TDateTime;
begin
  AStart := FloorToMinute(AStart);
  AEnd   := FloorToMinute(AEnd);

  if Cal = nil then
  begin
    if AEnd <= AStart then
      AEnd := AStart + (Max(MinMinutes, Ceil(DurationMin)) / 1440.0);
    Exit;
  end;

  Mins := Ceil(DurationMin);
  if Mins < MinMinutes then
    Mins := MinMinutes;

  S := AStart;

  // Si l'inici cau dins non-working, el saltem al seg�ent working merged
  if Cal.IsNonWorkingTime(S) then
    S := Cal.NextWorkingTime(S);

  S := FloorToMinute(S);

  // Recalcular SEMPRE el final a partir de l'inici sanejat i la durada working
  AStart := S;
  AEnd   := FloorToMinute(Cal.AddWorkingMinutes(AStart, Mins));

  // Fallback de seguretat
  if AEnd <= AStart then
    AEnd := FloorToMinute(Cal.AddWorkingMinutes(AStart, MinMinutes));
end;


end.
