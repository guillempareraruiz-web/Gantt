unit uGanttHelpers;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Math,
  System.Classes,
  System.UITypes,
  System.Generics.Collections,
  System.Generics.Defaults,
  Winapi.Windows,
  Vcl.Graphics,
  uGanttTypes,
  uCentreCalendar,
  uGanttControl,
  System.Types,
  VCL.Forms,
  Vcl.Direct2D, Winapi.D2D1, Winapi.DXGIFormat;

type
  TWorkWindow = record
    A: TDateTime;
    B: TDateTime;
  end;

procedure AddNode(var Nodes: TArray<TNode>; const N: TNode);

function MakeNodeRespectingCalendar(
  const Cal: TCentreCalendar;
  const CentreId: Integer;
  const NodeId: Integer;
  const StartCandidate: TDateTime;
  const WorkDurationMin: Integer;
  const Caption: string;
  const Color: TColor): TNode;

// Calendar setup (3 centres diferents per veure shading diferent)
procedure ConfiguraCalendariCentre(const Gantt: TGanttControl; const CentreId: Integer);

// Work windows (per generar nodes dins hores laborables)
procedure GetWorkWindowsForDate(const Cal: TCentreCalendar; const Day: TDateTime; out Windows: TArray<TWorkWindow>);
function PickRandomWorkingStart(
  const Cal: TCentreCalendar;
  const FromDT, ToDT: TDateTime;
  const MinWorkDur: Integer): TDateTime;

// Generadors "realistes"
procedure GenerateSequentialRealistic(
  const Cal: TCentreCalendar;
  const CentreId: Integer;
  const RangeStart, RangeEnd: TDateTime;
  const MinDur, MaxDur: Integer;
  const GapMin, GapMax: Integer;
  var NextNodeId: Integer;
  var Nodes: TArray<TNode>);

procedure GenerateParallelRealistic(
  const Cal: TCentreCalendar;
  const CentreId: Integer;
  const RangeStart, RangeEnd: TDateTime;
  const Count: Integer;
  const MinDur, MaxDur: Integer;
  var NextNodeId: Integer;
  var Nodes: TArray<TNode>);

function AdjustColorBrightness(Color: TColor; Delta: Integer): TColor;
function TextColorForBackground(Color: TColor): TColor;

function LowerBoundNodeRight(const A: TArray<TNodeLayout>; L, R: Integer; X: Single): Integer;

function RandomSoftColor: TColor;

procedure DrawArrowHead(Canvas: TCanvas; const Tip, FromPt: TPoint; const Size: Integer);
procedure DrawElbowArrow(Canvas: TCanvas; const AFrom, ATo: TPoint; const MidX: Integer; const ArrowSize: Integer);

procedure DrawArrowHeadD2D(const RT: ID2D1RenderTarget; const Brush: ID2D1Brush;
  const Tip: TD2D1Point2F; const DirUnit: TPointF; const Size, Width: Single);

procedure DrawCurvedArrowD2D(
  const RT: ID2D1RenderTarget;
  const StrokeBrush: ID2D1Brush;
  const FillBrush: ID2D1Brush; // per la punta
  const FromPtS, ToPtS: TPointF; // screen coords
  const StrokeStyle: ID2D1StrokeStyle;
  const StrokeWidth: Single = 1.2;
  const ArrowSize: Single = 10;
  const ArrowWidth: Single = 8);

function CreateDottedStrokeStyle(const RT: ID2D1RenderTarget): ID2D1StrokeStyle;

function PtF(const X, Y: Single): TD2D1Point2F;

function VecLen(const dx, dy: Single): Single;

function NormalizeVec(const dx, dy: Single): TPointF;

procedure DrawTextEllipsisGDI(
  const ACanvas: TCanvas;
  const R: TRect;
  const S: string;
  const AColor: TColor;
  const ACenterVert: Boolean = True);



function MakePointF(const X, Y: Single): D2D_POINT_2F; inline;
function MakeColorF(const R, G, B, A: Single): D2D_COLOR_F; inline;
procedure SetIdentityTransform(const RT: ID2D1RenderTarget);
function Pt(const X, Y: Single): TD2DPoint2f; inline;
procedure SetIdentityTransformAlternative(const RT: ID2D1RenderTarget; out OldM: D2D_MATRIX_3X2_F); inline;

procedure SetGanttCursor( cur: TCursor );

function RectsOverlapX(const ALeft, ARight, BLeft, BRight: Single): Boolean;

function MinutesToDays(const Mins: Double): Double;
function DurationToCalendarMinutes(const DurationMin: Double): Integer;


function Clamp01D(const v: Double): Single;
function SafeDiv(const A, B: Double): Double;

function IsWeekend(const ADate: TDateTime): Boolean;

function CompressTimeNoWeekend(const ADate: TDateTime): TDateTime;



implementation


function CompressTimeNoWeekend(const ADate: TDateTime): TDateTime;
var
  D: TDateTime;
  Days: Integer;
begin
  D := DateOf(ADate);
  Days := 0;
  while D < DateOf(ADate) do
  begin
    if not IsWeekend(D) then
      Inc(Days);
    D := IncDay(D);
  end;
  Result := Days + Frac(ADate);
end;


function IsWeekend(const ADate: TDateTime): Boolean;
var
  D: Integer;
begin
  D := DayOfTheWeek(ADate);
  Result := (D = 6) or (D = 7); // dissabte o diumenge
end;


function Clamp01D(const v: Double): Single;
begin
  if v < 0 then Result := 0
  else if v > 1 then Result := 1
  else Result := v;
end;
function SafeDiv(const A, B: Double): Double;
begin
  if Abs(B) < 1e-12 then Result := 0 else Result := A / B;
end;

function DurationToCalendarMinutes(const DurationMin: Double): Integer;
begin
  Result := Ceil(DurationMin);
  if Result < 1 then Result := 1;
end;


function MinutesToDays(const Mins: Double): Double;
begin
  Result := Mins / 1440.0;
end;


function RectsOverlapX(const ALeft, ARight, BLeft, BRight: Single): Boolean;
begin
  Result := (ARight > BLeft) and (ALeft < BRight);
end;

procedure SetGanttCursor( cur: TCursor );
begin
 if Screen.Cursor <> cur then
  Screen.Cursor := cur;
end;

function MakePointF(const X, Y: Single): D2D_POINT_2F; inline;
begin
  Result.x := X;
  Result.y := Y;
end;
function MakeColorF(const R, G, B, A: Single): D2D_COLOR_F; inline;
begin
  Result.r := R;
  Result.g := G;
  Result.b := B;
  Result.a := A;
end;

procedure SetIdentityTransform(const RT: ID2D1RenderTarget);
var
  M: D2D_MATRIX_3X2_F;
begin
  M._11 := 1; M._12 := 0;
  M._21 := 0; M._22 := 1;
  M._31 := 0; M._32 := 0;
  RT.SetTransform(M);
end;

function Pt(const X, Y: Single): TD2DPoint2f; inline;
begin
  Result.x := X;
  Result.y := Y;
end;
procedure SetIdentityTransformAlternative(const RT: ID2D1RenderTarget; out OldM: D2D_MATRIX_3X2_F); inline;
var
  I: D2D_MATRIX_3X2_F;
begin
  RT.GetTransform(OldM);
  I._11 := 1; I._12 := 0;
  I._21 := 0; I._22 := 1;
  I._31 := 0; I._32 := 0;
  RT.SetTransform(I);
end;

procedure DrawTextEllipsisGDI(
  const ACanvas: TCanvas;
  const R: TRect;
  const S: string;
  const AColor: TColor;
  const ACenterVert: Boolean = True);
var
  flags: UINT;
  rc: TRect;
  oldBkMode: Integer;
  oldColor: COLORREF;
begin
  rc := R;
  // Transparent background
  oldBkMode := SetBkMode(ACanvas.Handle, TRANSPARENT);
  // Set text color
  oldColor := SetTextColor(ACanvas.Handle, ColorToRGB(AColor));
  flags := DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX;
  if ACenterVert then
    flags := flags or DT_VCENTER;
  // Usa la font actual del canvas (Name/Size/Style)
  DrawTextW(ACanvas.Handle, PWideChar(S), Length(S), rc, flags);
  // Restore
  SetTextColor(ACanvas.Handle, oldColor);
  SetBkMode(ACanvas.Handle, oldBkMode);
end;


procedure BuildNaturalBezier(const FromPt, ToPt: TPointF;
  out C1, C2: TPointF);
var
  dx, dy: Single;
  pullX: Single;
begin
  dx := ToPt.X - FromPt.X;
  dy := ToPt.Y - FromPt.Y;

  // quant "estirem" horitzontalment els control points
  pullX := EnsureRange(Abs(dx) * 0.35, 30, 200);

  if dx >= 0 then
  begin
    // normal: From -> To cap a la dreta
    C1 := PointF(FromPt.X + pullX, FromPt.Y);
    C2 := PointF(ToPt.X   - pullX, ToPt.Y);
  end
  else
  begin
    // cap enrere: fem un loop cap a la dreta des del From
    C1 := PointF(FromPt.X + 80, FromPt.Y);
    C2 := PointF(ToPt.X   - 80, ToPt.Y); // entra al To des de l'esquerra amb suavitat
  end;

  // Opcional: afegir una mica de curvatura vertical (més “natural”)
  if Abs(dy) > 10 then
  begin
    C1.Y := C1.Y + dy * 0.15;
    C2.Y := C2.Y - dy * 0.15;
  end;
end;


procedure DrawCurvedArrowD2D(
  const RT: ID2D1RenderTarget;
  const StrokeBrush: ID2D1Brush;
  const FillBrush: ID2D1Brush;
  const FromPtS, ToPtS: TPointF;
  const StrokeStyle: ID2D1StrokeStyle;
  const StrokeWidth: Single;
  const ArrowSize: Single;
  const ArrowWidth: Single);
var
  C1, C2: TPointF;
  geom: ID2D1PathGeometry;
  sink: ID2D1GeometrySink;
  factory: ID2D1Factory;
  bez: TD2D1BezierSegment;
  dir: TPointF;
  tip: TD2D1Point2F;
begin
  BuildNaturalBezier(FromPtS, ToPtS, C1, C2);

  RT.GetFactory(factory);
  factory.CreatePathGeometry(geom);
  geom.Open(sink);

  sink.BeginFigure(D2D1PointF(FromPtS.X, FromPtS.Y), D2D1_FIGURE_BEGIN_HOLLOW);

  bez.point1 := D2D1PointF(C1.X, C1.Y);
  bez.point2 := D2D1PointF(C2.X, C2.Y);
  bez.point3 := D2D1PointF(ToPtS.X, ToPtS.Y);

  sink.AddBezier(bez);
  sink.EndFigure(D2D1_FIGURE_END_OPEN);
  sink.Close;

  RT.DrawGeometry(geom, StrokeBrush, StrokeWidth, StrokeStyle);

  // tangent final aproximada: C2 -> To
  dir := NormalizeVec(ToPtS.X - C2.X, ToPtS.Y - C2.Y);
  tip := D2D1PointF(ToPtS.X, ToPtS.Y);

  DrawArrowHeadD2D(RT, FillBrush, tip, dir, ArrowSize, ArrowWidth);
end;


function PtF(const X, Y: Single): TD2D1Point2F;
begin
  Result.x := X;
  Result.y := Y;
end;

function VecLen(const dx, dy: Single): Single;
begin
  Result := Sqrt(dx*dx + dy*dy);
end;

function NormalizeVec(const dx, dy: Single): TPointF;
var
  L: Single;
begin
  L := Sqrt(dx*dx + dy*dy);
  if L < 0.0001 then
    Result := PointF(1, 0)
  else
    Result := PointF(dx / L, dy / L);
end;

procedure DrawArrowHeadD2D(const RT: ID2D1RenderTarget; const Brush: ID2D1Brush;
  const Tip: TD2D1Point2F; const DirUnit: TPointF; const Size, Width: Single);
var
  n: TPointF;
  basePt: TD2D1Point2F;
  p1, p2: TD2D1Point2F;
  geom: ID2D1PathGeometry;
  sink: ID2D1GeometrySink;
  factory: ID2D1Factory;
begin
  // perpendicular
  n := PointF(-DirUnit.Y, DirUnit.X);
  basePt := D2D1PointF(Tip.x - DirUnit.X * Size, Tip.y - DirUnit.Y * Size);
  p1 := D2D1PointF(basePt.x + n.X * (Width * 0.5), basePt.y + n.Y * (Width * 0.5));
  p2 := D2D1PointF(basePt.x - n.X * (Width * 0.5), basePt.y - n.Y * (Width * 0.5));
  RT.GetFactory(factory);
  factory.CreatePathGeometry(geom);
  geom.Open(sink);
  sink.BeginFigure(Tip, D2D1_FIGURE_BEGIN_FILLED);
  sink.AddLine(p1);
  sink.AddLine(p2);
  sink.EndFigure(D2D1_FIGURE_END_CLOSED);
  sink.Close;
  RT.FillGeometry(geom, Brush, nil);
end;



function CreateDottedStrokeStyle(const RT: ID2D1RenderTarget): ID2D1StrokeStyle;
var
  Factory: ID2D1Factory;
  Props: TD2D1StrokeStyleProperties;
begin
  Result := nil;
  if RT = nil then Exit;
  RT.GetFactory(Factory);
  Props.startCap    := D2D1_CAP_STYLE_ROUND;
  Props.endCap      := D2D1_CAP_STYLE_ROUND;
  Props.dashCap     := D2D1_CAP_STYLE_ROUND;
  Props.lineJoin    := D2D1_LINE_JOIN_ROUND;
  Props.miterLimit  := 10.0;
  Props.dashStyle   := D2D1_DASH_STYLE_DOT;
  Props.dashOffset  := 0.0;
  Factory.CreateStrokeStyle(Props, nil, 0, Result);
end;

procedure DrawArrowHead(Canvas: TCanvas; const Tip, FromPt: TPoint; const Size: Integer);
var
  ang: Double;
  p1, p2: TPoint;
begin
  ang := ArcTan2(Tip.Y - FromPt.Y, Tip.X - FromPt.X);
  p1.X := Tip.X - Round(Size * Cos(ang - Pi / 6));
  p1.Y := Tip.Y - Round(Size * Sin(ang - Pi / 6));
  p2.X := Tip.X - Round(Size * Cos(ang + Pi / 6));
  p2.Y := Tip.Y - Round(Size * Sin(ang + Pi / 6));
  Canvas.Brush.Style := bsSolid;
  Canvas.Polygon([Tip, p1, p2]);
end;
procedure DrawElbowArrow(Canvas: TCanvas; const AFrom, ATo: TPoint; const MidX: Integer; const ArrowSize: Integer);
var
  pA, pB: TPoint;
begin
  pA := Point(MidX, AFrom.Y);
  pB := Point(MidX, ATo.Y);
  Canvas.Polyline([AFrom, pA, pB, ATo]);
  DrawArrowHead(Canvas, ATo, pB, ArrowSize);
end;

function LowerBoundNodeRight(const A: TArray<TNodeLayout>; L, R: Integer; X: Single): Integer;
var
  mid: Integer;
begin
  Result := R + 1;
  while L <= R do
  begin
    mid := (L + R) div 2;
    if A[mid].Rect.Right >= X then
    begin
      Result := mid;
      R := mid - 1;
    end
    else
      L := mid + 1;
  end;
end;

function ClampByte(Value: Integer): Byte;
begin
  if Value < 0 then Result := 0
  else if Value > 255 then Result := 255
  else Result := Value;
end;

function RandomPastelColor: TColor;
var
  r, g, b: Integer;
begin
  // base alta (pastel)
  r := 150 + Random(106); // 150..255
  g := 150 + Random(106);
  b := 150 + Random(106);

  Result := RGB(r, g, b);
end;

function RandomSoftColor: TColor;
var
  r, g, b: Integer;
begin
  // gamma equilibrada (millor contrast)
  r := 80 + Random(140);  // 80..220
  g := 80 + Random(140);
  b := 80 + Random(140);

  Result := RGB(r, g, b);
end;

function AdjustColorBrightness(Color: TColor; Delta: Integer): TColor;
var
  r, g, b: Integer;
begin
  Color := ColorToRGB(Color);

  r := ClampByte(GetRValue(Color) + Delta);
  g := ClampByte(GetGValue(Color) + Delta);
  b := ClampByte(GetBValue(Color) + Delta);

  Result := RGB(r, g, b);
end;


function TextColorForBackground(Color: TColor): TColor;
var
  r, g, b: Integer;
  luminance: Double;
begin
  Color := ColorToRGB(Color);

  r := GetRValue(Color);
  g := GetGValue(Color);
  b := GetBValue(Color);

  luminance := 0.299*r + 0.587*g + 0.114*b;

  if luminance > 150 then
    Result := clBlack
  else
    Result := clWhite;
end;


procedure AddNode(var Nodes: TArray<TNode>; const N: TNode);
begin
  SetLength(Nodes, Length(Nodes) + 1);
  Nodes[High(Nodes)] := N;
end;

function MakeNodeRespectingCalendar(
  const Cal: TCentreCalendar;
  const CentreId: Integer;
  const NodeId: Integer;
  const StartCandidate: TDateTime;
  const WorkDurationMin: Integer;
  const Caption: string;
  const Color: TColor): TNode;
var
  s: TDateTime;
  baseColor: TColor;
begin
  // Start no pot caure dins non-working
  s := Cal.NextWorkingTime(StartCandidate);

  baseColor := RandomSoftColor;

  Result.Id := NodeId;
  Result.CentreId := CentreId;
  Result.StartTime := s;

  // Durada en minuts laborables -> End real s’allarga si hi ha non-working al mig
  Result.EndTime := Cal.AddWorkingMinutes(s, WorkDurationMin);

  Result.Caption := Caption;

  Result.FillColor   := baseColor;
  Result.BorderColor := AdjustColorBrightness(baseColor, -40);
  Result.HoverColor  := AdjustColorBrightness(baseColor, +30);

end;

function MinutesBetweenDT(const A, B: TDateTime): Integer;
begin
  Result := Round((B - A) * 24 * 60);
end;

procedure GetWorkWindowsForDate(const Cal: TCentreCalendar; const Day: TDateTime; out Windows: TArray<TWorkWindow>);
var
  periods: TArray<TNonWorkingPeriod>;
  nw: TArray<TWorkWindow>;
  dayStart, cur: TDateTime;
  i: Integer;
  a, b: TDateTime;
begin
  dayStart := DateOf(Day);
  periods := Cal.NonWorkingPeriodsForDate(dayStart);

  // Sense non-working: tot el dia laborable
  if Length(periods) = 0 then
  begin
    SetLength(Windows, 1);
    Windows[0].A := dayStart;
    Windows[0].B := IncDay(dayStart, 1);
    Exit;
  end;

  // Non-working windows en DateTime
  SetLength(nw, Length(periods));
  for i := 0 to High(periods) do
  begin
    nw[i].A := dayStart + periods[i].StartTimeOfDay;
    nw[i].B := dayStart + periods[i].EndTimeOfDay;
  end;

  // Ordenar per inici
  TArray.Sort<TWorkWindow>(nw,
    TComparer<TWorkWindow>.Construct(
      function(const L, R: TWorkWindow): Integer
      begin
        Result := CompareDateTime(L.A, R.A);
      end));

  // Invertim: working = forats entre non-working
  SetLength(Windows, 0);
  cur := dayStart;

  for i := 0 to High(nw) do
  begin
    a := nw[i].A;
    b := nw[i].B;

    if a > cur then
    begin
      SetLength(Windows, Length(Windows) + 1);
      Windows[High(Windows)].A := cur;
      Windows[High(Windows)].B := a;
    end;

    if b > cur then
      cur := b;
  end;

  if cur < IncDay(dayStart, 1) then
  begin
    SetLength(Windows, Length(Windows) + 1);
    Windows[High(Windows)].A := cur;
    Windows[High(Windows)].B := IncDay(dayStart, 1);
  end;
end;

function PickRandomWorkingStart(
  const Cal: TCentreCalendar;
  const FromDT, ToDT: TDateTime;
  const MinWorkDur: Integer): TDateTime;
var
  day: TDateTime;
  windows: TArray<TWorkWindow>;
  candidates: TArray<TWorkWindow>;
  w: TWorkWindow;
  i: Integer;
  spanMin, offMin: Integer;
  a, b: TDateTime;
begin
  SetLength(candidates, 0);

  day := DateOf(FromDT);
  while day <= DateOf(ToDT) do
  begin
    GetWorkWindowsForDate(Cal, day, windows);

    for w in windows do
    begin
      a := Max(w.A, FromDT);
      b := Min(w.B, ToDT);
      spanMin := MinutesBetweenDT(a, b);

      if spanMin >= MinWorkDur then
      begin
        SetLength(candidates, Length(candidates) + 1);
        candidates[High(candidates)].A := a;
        candidates[High(candidates)].B := b;
      end;
    end;

    day := IncDay(day, 1);
  end;

  if Length(candidates) = 0 then
    Exit(Cal.NextWorkingTime(FromDT));

  i := Random(Length(candidates));
  a := candidates[i].A;
  b := candidates[i].B;

  spanMin := MinutesBetweenDT(a, b) - MinWorkDur;
  if spanMin < 0 then spanMin := 0;

  offMin := Random(spanMin + 1);
  Result := Cal.NextWorkingTime(IncMinute(a, offMin));
end;

procedure GenerateSequentialRealistic(
  const Cal: TCentreCalendar;
  const CentreId: Integer;
  const RangeStart, RangeEnd: TDateTime;
  const MinDur, MaxDur: Integer;
  const GapMin, GapMax: Integer;
  var NextNodeId: Integer;
  var Nodes: TArray<TNode>);
var
  t: TDateTime;
  dur, gap: Integer;
  n: TNode;
begin
  t := Cal.NextWorkingTime(RangeStart);

  while t < RangeEnd do
  begin
    dur := MinDur + Random(MaxDur - MinDur + 1);
    gap := GapMin + Random(GapMax - GapMin + 1);

    if t >= RangeEnd then Break;

    n := MakeNodeRespectingCalendar(
      Cal, CentreId, NextNodeId, t, dur,
      Format('CT%d-%d', [CentreId, NextNodeId]),
      RandomSoftColor
      //RGB(Random(180)+40, Random(180)+40, Random(180)+40)
    );

    n.Caption := Format('CT%d-%d', [CentreId, NextNodeId]) + chr(13)+chr(10)+datetimetostr(n.EndTime);
    n.Visible := True;
    n.Enabled := True;

    Inc(NextNodeId);

    if n.StartTime < RangeEnd then
      AddNode(Nodes, n)
    else
      Break;

    // següent start: gap en minuts laborables
    t := Cal.AddWorkingMinutes(n.EndTime, gap);
    t := Cal.NextWorkingTime(t);
  end;
end;

procedure GenerateParallelRealistic(
  const Cal: TCentreCalendar;
  const CentreId: Integer;
  const RangeStart, RangeEnd: TDateTime;
  const Count: Integer;
  const MinDur, MaxDur: Integer;
  var NextNodeId: Integer;
  var Nodes: TArray<TNode>);
var
  i, dur: Integer;
  startDT: TDateTime;
  n: TNode;
begin
  for i := 1 to Count do
  begin
    dur := MinDur + Random(MaxDur - MinDur + 1);
    startDT := PickRandomWorkingStart(Cal, RangeStart, RangeEnd, Max(1, MinDur));

    n := MakeNodeRespectingCalendar(
      Cal, CentreId, NextNodeId, startDT, dur,
      Format('CT%d-%d', [CentreId, NextNodeId]),
      RandomSoftColor//RGB(Random(180)+40, Random(180)+40, Random(180)+40)
    );

    n.Caption := Format('CT%d-%d', [CentreId, NextNodeId]) + chr(13)+chr(10)+datetimetostr(n.EndTime);
    n.Visible := True;
    n.Enabled := True;

    Inc(NextNodeId);

    AddNode(Nodes, n);
  end;
end;

procedure ConfiguraCalendariCentre(const Gantt: TGanttControl; const CentreId: Integer);
var
  cal: TCentreCalendar;
  p: TArray<TNonWorkingPeriod>;

  function NWP(const AStart, AEnd: TTime): TNonWorkingPeriod;
  begin
    Result.StartTimeOfDay := AStart;
    Result.EndTimeOfDay   := AEnd;
  end;

  procedure SetMonFri(const Arr: array of TNonWorkingPeriod);
  var
    tmp: TArray<TNonWorkingPeriod>;
    i: Integer;
  begin
    SetLength(tmp, Length(Arr));
    for i := 0 to High(Arr) do
      tmp[i] := Arr[i];

    cal.SetDayNonWorkingPeriods(1, tmp);
    cal.SetDayNonWorkingPeriods(2, tmp);
    cal.SetDayNonWorkingPeriods(3, tmp);
    cal.SetDayNonWorkingPeriods(4, tmp);
    cal.SetDayNonWorkingPeriods(5, tmp);
  end;

  procedure SetClosedWeekend;
  begin
    SetLength(p, 1);
    p[0] := NWP(EncodeTime(0,0,0,0), EncodeTime(23,59,59,999));
    cal.SetDayNonWorkingPeriods(6, p);
    cal.SetDayNonWorkingPeriods(7, p);
  end;

begin
  cal := Gantt.GetCalendar(CentreId);

  case CentreId of
    // CT1: "clàssic" + pausa
    // non-working: 00:00-06:00, 14:00-15:00, 22:00-24:00
    1:
      begin
        SetMonFri([
          NWP(EncodeTime(0,0,0,0),  EncodeTime(6,0,0,0)),
          NWP(EncodeTime(14,0,0,0), EncodeTime(15,0,0,0)),
          NWP(EncodeTime(22,0,0,0), EncodeTime(23,59,59,999))
        ]);
        SetClosedWeekend;
      end;

    // CT2: torn intensiu 07:00-15:00 (sense pausa)
    // non-working: 00:00-07:00, 15:00-24:00
    2:
      begin
        SetMonFri([
          NWP(EncodeTime(0,0,0,0),  EncodeTime(7,0,0,0)),
          NWP(EncodeTime(15,0,0,0), EncodeTime(23,59,59,999))
        ]);
        SetClosedWeekend;
      end;

    // CT3: torn tarda 15:00-23:00 + pausa curta
    // non-working: 00:00-15:00, 18:30-18:45, 23:00-24:00
    3:
      begin
        SetMonFri([
          NWP(EncodeTime(0,0,0,0),   EncodeTime(15,0,0,0)),
          NWP(EncodeTime(18,30,0,0), EncodeTime(18,45,0,0)),
          NWP(EncodeTime(23,0,0,0),  EncodeTime(23,59,59,999))
        ]);
        SetClosedWeekend;
      end;

  else
    // Defecte: cap non-working entre setmana + cap de setmana tancat
    begin
      SetLength(p, 0);
      cal.SetDayNonWorkingPeriods(1, p);
      cal.SetDayNonWorkingPeriods(2, p);
      cal.SetDayNonWorkingPeriods(3, p);
      cal.SetDayNonWorkingPeriods(4, p);
      cal.SetDayNonWorkingPeriods(5, p);
      SetClosedWeekend;
    end;
  end;
end;

end.

