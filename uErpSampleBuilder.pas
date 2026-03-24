unit uErpSampleBuilder;

interface

uses
  System.SysUtils, System.DateUtils, System.Math,
   System.Generics.Collections,
  uGanttTypes, uNodeDataRepo,
  Winapi.Windows, Winapi.Messages,
  System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, uNodeHelpers,
  uGanttHelpers, uErpTypes, uCentreCalendar;



function BuildRawSample(
  const T0, T1: TDateTime;
  const CentreNames: TArray<string>;
  const NumOFs: Integer;
  const MaxOTPerOF: Integer;
  const MaxOPPerOT: Integer;
  const ProbSinCentro: Double;     // 0..1
  const ProbExtraLinks: Double;    // 0..1, links addicionals dins OT
  const MinDurMin, MaxDurMin: Integer; // durada operaci�
  const MinGapMin, MaxGapMin: Integer  // gap entre ops dins OT
): TErpRaw;


procedure BuildGanttFromRaw(
  const Raw: TErpRaw;
  NodeRepo: TNodeDataRepo;
  out Centres: TArray<TCentreTreball>;
  out Nodes: TArray<TNode>);


procedure BuildGanttFromRawNew(
  const Raw: TErpRaw;
  NodeRepo: TNodeDataRepo;
  const GetCalendar: TGetCalendarFunc;
  out Centres: TArray<TCentreTreball>;
  out Nodes: TArray<TNode>);

procedure BuildGanttFromRawNew2(
  const Raw: TErpRaw;
  NodeRepo: TNodeDataRepo;
  const GetCalendar: TGetCalendarFunc;
  out Centres: TArray<TCentreTreball>;
  out Nodes: TArray<TNode>);


      //per carrega inicial nodes RAW
    function TryGetNonWorkingIntervalMergedAt_Raw(
                  const Cal: TCentreCalendar;
                  const T: TDateTime;
                  const RadiusDays: Integer;
                  out AStart, AEnd: TDateTime
                ): Boolean;


    function AdjustToWorkingForwardMerged_Raw(
              const Cal: TCentreCalendar;
              const T: TDateTime;
              const RadiusDays: Integer
            ): TDateTime;

    function AdjustToWorkingBackwardMerged_Raw(
              const Cal: TCentreCalendar;
              const T: TDateTime;
              const RadiusDays: Integer
            ): TDateTime;



implementation

const
  OP_NAMES: array[0..11] of string = (
    'PINTAR', 'BRONCEAR', 'LACAR', 'PULIR', 'CORTAR', 'EMBALAR',
    'SOLDAR', 'FRESAR', 'TORNEAR', 'TALADRAR', 'RECTIFICAR', 'MONTAR'
  );

type
  TOpList = TArray<TErpOp>;
  TLinkList = TArray<TErpLink>;

function HashSerie16(const S: string): Cardinal;
var
  i: Integer;
  h: Cardinal;
begin
  h := 0;
  {$Q-}
  for i := 1 to Length(S) do
    h := (h * 131) + Cardinal(Ord(S[i]));
  {$Q+}
  Result := h and $FFFF; // 16 bits
end;
function MakeOFKey64(const NumeroOF: Integer; const SerieOF: string): UInt64;
begin
  Result := (UInt64(Cardinal(NumeroOF)) shl 16) or UInt64(HashSerie16(SerieOF));
end;


function FNV1a32(const S: string): Cardinal;
var
  i: Integer;
  h: Cardinal;
begin
  h := $811C9DC5;
  {$Q-}  // <<<<<< overflow checking OFF (aix� �s el que cal)
  for i := 1 to Length(S) do
  begin
    h := h xor Cardinal(Ord(S[i]));
    h := h * Cardinal(16777619);
  end;
  {$Q+}  // torna-ho a deixar com estava
  Result := h;
end;

function GetOFColorFromPalette(const NumeroOF: Integer; const SerieOF: string): TColor;
var
  key: string;
  idx: Integer;
begin
  key := MakeOFKey(NumeroOF, SerieOF); // ex: '2|A'
  idx := Integer(FNV1a32(key) mod Cardinal(Length(GanttColorPalette))); // 0..63
  Result := GanttColorPalette[idx];
end;

procedure AddOp(var A: TOpList; const Op: TErpOp);
var
  n: Integer;
begin
  n := Length(A);
  SetLength(A, n + 1);
  A[n] := Op;
end;

procedure AddLink(var A: TLinkList; const L: TErpLink);
var
  n: Integer;
begin
  n := Length(A);
  SetLength(A, n + 1);
  A[n] := L;
end;

function RandBetween(const AMin, AMax: Integer): Integer;
begin
  if AMax <= AMin then Exit(AMin);
  Result := AMin + Random(AMax - AMin + 1);
end;

function PickCentreName(const CentreNames: TArray<string>; const ProbSinCentro: Double): string;
begin
  if (Length(CentreNames) = 0) or (Random < ProbSinCentro) then
    Exit(''); // => Sin Centro

  Result := CentreNames[Random(Length(CentreNames))];
end;

// Retorna un array de centres permesos per a una operació de mostra.
// Amb probabilitat ProbSinCentro retorna [] (tots els centres permesos).
// Altrament escull 1 o 2 centres aleatoris de CentreNames.
function PickCentreNames(const CentreNames: TArray<string>; const ProbSinCentro: Double): TArray<string>;
var
  idx1, idx2: Integer;
begin
  if (Length(CentreNames) = 0) or (Random < ProbSinCentro) then
  begin
    Result := []; // buit = tots els centres permesos
    Exit;
  end;

  idx1 := Random(Length(CentreNames));
  // amb 30% de probabilitat assigna un segon centre diferent
  if (Length(CentreNames) > 1) and (Random < 0.30) then
  begin
    repeat idx2 := Random(Length(CentreNames)); until idx2 <> idx1;
    Result := [CentreNames[idx1], CentreNames[idx2]];
  end
  else
    Result := [CentreNames[idx1]];
end;

function MakeClienteCode(const I: Integer): string;
begin
  Result := 'CL' + FormatFloat('000', I);
end;

function ClampToRange(const T, T0, T1: TDateTime): TDateTime;
begin
  if T < T0 then Exit(T0);
  if T > T1 then Exit(T1);
  Result := T;
end;

function RandomTimeInRange(const T0, T1: TDateTime): TDateTime;
var
  spanMin: Integer;
  offMin: Integer;
begin
  spanMin := Max(1, MinutesBetween(T0, T1));
  offMin := Random(spanMin);
  Result := IncMinute(T0, offMin);
end;



//... _RAW per la c�rrega de nodes inicial
function TryGetNonWorkingIntervalMergedAt_Raw(
  const Cal: TCentreCalendar;
  const T: TDateTime;
  const RadiusDays: Integer;
  out AStart, AEnd: TDateTime
): Boolean;
var
  baseDay: TDateTime;

  function ExpandInterval(var S, E: TDateTime): Boolean;
  var
    changed: Boolean;
    d: Integer;
    day: TDateTime;
    periods: TArray<TNonWorkingPeriod>;
    p: TNonWorkingPeriod;
    s2, e2: TDateTime;
  begin
    Result := False;
    repeat
      changed := False;

      for d := -RadiusDays to RadiusDays do
      begin
        day := IncDay(DateOf(S), d);
        periods := Cal.NonWorkingPeriodsForDate(day);

        for p in periods do
        begin
          s2 := day + p.StartTimeOfDay;
          e2 := day + p.EndTimeOfDay;

          if p.EndTimeOfDay <= p.StartTimeOfDay then
            e2 := IncDay(day, 1) + p.EndTimeOfDay;

          if (e2 >= S) and (s2 <= E) then
          begin
            if s2 < S then begin S := s2; changed := True; end;
            if e2 > E then begin E := e2; changed := True; end;
          end
          else if SameValue(e2, S, 1/864000) then
          begin
            S := s2; changed := True;
          end
          else if SameValue(s2, E, 1/864000) then
          begin
            E := e2; changed := True;
          end;
        end;
      end;

      Result := Result or changed;
    until not changed;
  end;

var
  d: Integer;
  day: TDateTime;
  periods: TArray<TNonWorkingPeriod>;
  p: TNonWorkingPeriod;
  s, e: TDateTime;
begin
  Result := False;
  AStart := 0;
  AEnd := 0;

  baseDay := DateOf(T);

  for d := -RadiusDays to RadiusDays do
  begin
    day := IncDay(baseDay, d);
    periods := Cal.NonWorkingPeriodsForDate(day);

    for p in periods do
    begin
      s := day + p.StartTimeOfDay;
      e := day + p.EndTimeOfDay;

      if p.EndTimeOfDay <= p.StartTimeOfDay then
        e := IncDay(day, 1) + p.EndTimeOfDay;

      if (T >= s) and (T < e) then
      begin
        AStart := s;
        AEnd := e;
        ExpandInterval(AStart, AEnd);
        Exit(True);
      end;
    end;
  end;
end;


function AdjustToWorkingForwardMerged_Raw(
  const Cal: TCentreCalendar;
  const T: TDateTime;
  const RadiusDays: Integer
): TDateTime;
var
  sNW, eNW: TDateTime;
  i: Integer;
begin
  Result := T;
  for i := 0 to 128 do
  begin
    if not TryGetNonWorkingIntervalMergedAt_Raw(Cal, Result, RadiusDays, sNW, eNW) then
      Exit;
    Result := eNW;
  end;
end;


function AdjustToWorkingBackwardMerged_Raw(
  const Cal: TCentreCalendar;
  const T: TDateTime;
  const RadiusDays: Integer
): TDateTime;
var
  sNW, eNW: TDateTime;
  i: Integer;
begin
  Result := T;
  for i := 0 to 128 do
  begin
    if not TryGetNonWorkingIntervalMergedAt_Raw(Cal, Result, RadiusDays, sNW, eNW) then
      Exit;
    Result := sNW;
  end;
end;


function FloorToMinute(const T: TDateTime): TDateTime;
begin
  Result := RecodeMilliSecond(RecodeSecond(T, 0), 0);
end;




procedure NormalizeByDurationFast(
  const Cal: TCentreCalendar;
  var AStart, AEnd: TDateTime;
  const DurationMin: Double;
  const MinMinutes: Integer = 1);
var
  Mins: Integer;
begin
  if Cal = nil then Exit;
  Mins := Ceil(DurationMin);
  if Mins < MinMinutes then
    Mins := MinMinutes;
  AStart := FloorToMinute(AStart);
  // nom�s corregeix si realment comen�a en non-working
  if Cal.IsNonWorkingTime(AStart) then
    AStart := Cal.NextWorkingTime(AStart);
  // si l'end ja �s coherent, no el toquis
  if (AEnd <= AStart) then
    AEnd := Cal.AddWorkingMinutes(AStart, Mins)
  else
    AEnd := FloorToMinute(AEnd);
end;


function RandomQuarterPercent: Integer;
const
  Values: array[0..4] of Integer = (0, 25, 50, 75, 100);
begin
  Result := Values[Random(Length(Values))];
end;

(* // antiga
function BuildRawSample(
  const T0, T1: TDateTime;
  const CentreNames: TArray<string>;
  const NumOFs: Integer;
  const MaxOTPerOF: Integer;
  const MaxOPPerOT: Integer;
  const ProbSinCentro: Double;
  const ProbExtraLinks: Double;
  const MinDurMin, MaxDurMin: Integer;
  const MinGapMin, MaxGapMin: Integer
): TErpRaw;
var
  ops: TOpList;
  links: TLinkList;

  NextOpId: Integer;

  ofIdx, otIdx, opIdx: Integer;
  numOT, numOP: Integer;

  NumeroOF: Integer;
  SerieOF: string;

  NumeroOT: Integer;

  baseStart: TDateTime;
  curStart: TDateTime;
  durMin, gapMin: Integer;

  createdOpIds: TArray<Integer>; // ids de les ops d'una OT (per crear links)
  opRec: TErpOp;

  function NewOpId: Integer;
  begin
    Inc(NextOpId);
    Result := NextOpId;
  end;

  procedure StartNewOTOpIds;
  begin
    SetLength(createdOpIds, 0);
  end;

  procedure PushOTOpId(const Id: Integer);
  var
    n: Integer;
  begin
    n := Length(createdOpIds);
    SetLength(createdOpIds, n + 1);
    createdOpIds[n] := Id;
  end;

  procedure AddChainLinksInOT;
  var
    k: Integer;
    lnk: TErpLink;
  begin
    // OP1 -> OP2 -> OP3 ...
    for k := 0 to High(createdOpIds) - 1 do
    begin
      lnk.FromNodeId := createdOpIds[k];
      lnk.ToNodeId := createdOpIds[k + 1];
      lnk.LinkType := ltFinishStart;
      lnk.PorcentajeDependencia := 100;
      AddLink(links, lnk);
    end;
  end;

  procedure AddExtraRandomLinksInOT;
  var
    tries, a, b: Integer;
    lnk: TErpLink;
  begin
    if Length(createdOpIds) < 3 then Exit;

    // uns quants intents, dep�n de ProbExtraLinks
    tries := Round(Length(createdOpIds) * 1.5);
    while tries > 0 do
    begin
      Dec(tries);
      if Random >= ProbExtraLinks then
        Continue;

      a := Random(Length(createdOpIds) - 1);
      b := a + 1 + Random(Length(createdOpIds) - a - 1);
      if (a < 0) or (b < 0) then Continue;

      lnk.FromNodeId := createdOpIds[a];
      lnk.ToNodeId := createdOpIds[b];
      lnk.LinkType := ltFinishStart;
      lnk.PorcentajeDependencia := 100;
      AddLink(links, lnk);
    end;
  end;

begin
  Randomize;

  SetLength(ops, 0);
  SetLength(links, 0);
  NextOpId := 1000;

  // Normalitza T0/T1 (per seguretat)
  // (assumim que ja venen com DayStart/DayEnd, per� no fa mal)
  // baseStart = un punt dins el rang per cada OF

  for ofIdx := 1 to Max(0, NumOFs) do
  begin
    NumeroOF := 20000 + ofIdx;
    SerieOF := 'A';

    numOT := RandBetween(1, Max(1, MaxOTPerOF));

    // comen�ament "base" per aquesta OF
    baseStart := RandomTimeInRange(T0, T1);

    for otIdx := 1 to numOT do
    begin
      NumeroOT := 5000 + (ofIdx * 10) + otIdx;

      numOP := RandBetween(1, Max(1, MaxOPPerOT));
      StartNewOTOpIds;

      // cada OT comen�a un p�l despla�ada respecte baseStart
      curStart := IncMinute(baseStart, (otIdx - 1) * RandBetween(10, 60));
      curStart := ClampToRange(curStart, T0, T1);

      for opIdx := 1 to numOP do
      begin
        durMin := RandBetween(MinDurMin, MaxDurMin);
        gapMin := RandBetween(MinGapMin, MaxGapMin);

        opRec.OpId := NewOpId;

        opRec.NumeroOF := NumeroOF;
        opRec.SerieOF := SerieOF;


        opRec.NumeroOT := NumeroOT;
        opRec.SerieOF := SerieOF;


        opRec.NumeroPedido := 0;
        opRec.SeriePedido        := '';

        opRec.Stock               := Random(1000);
        opRec.CodigoArticulo      := 'ARTICULO_' + inttostr(NumeroOF);
        opRec.DescripcionArticulo := 'DESC ARTICULO_' + inttostr(NumeroOF);

        opRec.UnidadesAFabricar  := 1 + RAndom(100);
        opRec.UnidadesFabricadas := opRec.UnidadesAFabricar * (Random(10) * 0.1);

        opRec.TiempoUnidadFabSecs := 60 + Random(30); //...tiempo en segundos para fabricar una unidad
        opRec.DurationMin  := (opRec.TiempoUnidadFabSecs * opRec.UnidadesAFabricar) / 60; //...minutos;
        opRec.DurationMinOriginal := opRec.DurationMin;

        opRec.Prioridad := Random(3);
        opRec.Estado := TEstadoOF(Random(Ord(High(TEstadoOF)) + 1));

        opRec.OperariosAsignados := 0;
        opRec.OperariosNecesarios := Random(3);
        if opRec.OperariosNecesarios>0 then
         opRec.OperariosAsignados  := Random(opRec.OperariosNecesarios+1);


        opRec.PorcentajeDependencia :=  RandomQuarterPercent;
        if opRec.PorcentajeDependencia>100 then
         opRec.PorcentajeDependencia := 100;

        opRec.NumeroTrabajo := Format('TR-%d-%d-%d', [ofIdx, otIdx, opIdx]);

        opRec.CodigoCliente := MakeClienteCode(1 + (ofIdx mod 12));
        opRec.CentresTrabajo := PickCentreNames(CentreNames, ProbSinCentro);

        opRec.Operacion := OP_NAMES[opIdx mod Length(OP_NAMES)];

        opRec.StartTime := curStart;
        //opRec.EndTime := IncMinute(opRec.StartTime, durMin);
        opRec.EndTime := opRec.StartTime + (opRec.DurationMin / 1440.0); //...sense calendari

        opRec.FechaEntrega := incDay(opRec.StartTime, RAndom(7) );
        opRec.FechaNecesaria := opRec.FechaEntrega;

        // clamp EndTime al rang
        if opRec.EndTime > T1 then
          opRec.EndTime := T1;

        // evita End <= Start (per seguretat)
        if opRec.EndTime <= opRec.StartTime then
          opRec.EndTime := IncMinute(opRec.StartTime, 5);

        AddOp(ops, opRec);
        PushOTOpId(opRec.OpId);

        opRec.bkColorOp := clSilver;
        opRec.borderColorOp := AdjustColorBrightness(opRec.bkColorOp, -40);


        // seg�ent op (seq��ncia b�sica)
        curStart := IncMinute(opRec.EndTime, gapMin);
        if curStart > T1 then
          curStart := T1;
      end;

      // links: cadena + extra
      AddChainLinksInOT;
     // AddExtraRandomLinksInOT;
    end;
  end;

  Result.Ops := ops;
  Result.Links := links;
end;
       *)


function BuildRawSample(
  const T0, T1: TDateTime;
  const CentreNames: TArray<string>;
  const NumOFs: Integer;
  const MaxOTPerOF: Integer;
  const MaxOPPerOT: Integer;
  const ProbSinCentro: Double;
  const ProbExtraLinks: Double;
  const MinDurMin, MaxDurMin: Integer;
  const MinGapMin, MaxGapMin: Integer
): TErpRaw;
type
  TOfKind = (okA, okB, okC, okD);

  TOTOpInfo = record
    OpId: Integer;
    PorcentajeDependencia: Double;
  end;

  TOTOpInfoArray = array of TOTOpInfo;
var
  ops: TOpList;
  links: TLinkList;

  NextOpId: Integer;

  ofIdx, otIdx, opIdx: Integer;
  numOT, numOP: Integer;

  NumeroOF: Integer;
  SerieOF: string;
  NumeroOT: Integer;

  baseStart: TDateTime;
  curStart: TDateTime;
  gapMin: Integer;

  createdOps: TOTOpInfoArray;
  opRec: TErpOp;
  OfKind: TOfKind;
  CreateLinksForThisOT: Boolean;

  function NewOpId: Integer;
  begin
    Inc(NextOpId);
    Result := NextOpId;
  end;

  function PickOfKind: TOfKind;
  begin
    Result := TOfKind(Random(4)); // A,B,C,D
  end;

  procedure StartNewOTOps;
  begin
    SetLength(createdOps, 0);
  end;

  procedure PushOTOp(const AOpId: Integer; const APorcentajeDependencia: Double);
  var
    n: Integer;
  begin
    n := Length(createdOps);
    SetLength(createdOps, n + 1);
    createdOps[n].OpId := AOpId;
    createdOps[n].PorcentajeDependencia := APorcentajeDependencia;
  end;

  procedure AddChainLinksInOT(const AAllowTwoOpLinks: Boolean);
  var
    k, opCount: Integer;
    lnk: TErpLink;
  begin
    opCount := Length(createdOps);

    if opCount <= 1 then
      Exit;

    // si hi ha exactament 2 operacions, nom�s crear link si est� perm�s
    if (opCount = 2) and (not AAllowTwoOpLinks) then
      Exit;

    // si hi ha 3 o m�s operacions, crear tota la cadena
    for k := 0 to opCount - 2 do
    begin
      lnk.FromNodeId := createdOps[k].OpId;
      lnk.ToNodeId := createdOps[k + 1].OpId;
      lnk.LinkType := ltFinishStart;
      lnk.PorcentajeDependencia := createdOps[k].PorcentajeDependencia;
      AddLink(links, lnk);
    end;
  end;

  procedure AddExtraRandomLinksInOT;
  var
    tries, a, b: Integer;
    lnk: TErpLink;
  begin
    if Length(createdOps) < 3 then Exit;

    tries := Round(Length(createdOps) * 1.5);
    while tries > 0 do
    begin
      Dec(tries);
      if Random >= ProbExtraLinks then
        Continue;

      a := Random(Length(createdOps) - 1);
      b := a + 1 + Random(Length(createdOps) - a - 1);

      lnk.FromNodeId := createdOps[a].OpId;
      lnk.ToNodeId := createdOps[b].OpId;
      lnk.LinkType := ltFinishStart;
      lnk.PorcentajeDependencia := createdOps[a].PorcentajeDependencia;
      AddLink(links, lnk);
    end;
  end;

  procedure DecideStructureForOF(
    const AKind: TOfKind;
    out ANumOT: Integer;
    out ACreateLinks: Boolean);
  begin
    case AKind of
      okA:
        begin
          ANumOT := 1;
          ACreateLinks := False;
        end;

      okB:
        begin
          ANumOT := 1;
          ACreateLinks := True;
        end;

      okC:
        begin
          ANumOT := 1;
          ACreateLinks := True;
        end;

      okD:
        begin
          ANumOT := RandBetween(2, Max(2, MaxOTPerOF));
          ACreateLinks := True;
        end;
    else
      begin
        ANumOT := 1;
        ACreateLinks := False;
      end;
    end;
  end;

  function DecideNumOpsForOT(const AKind: TOfKind): Integer;
  begin
    case AKind of
      okA:
        Result := RandBetween(1, 2);

      okB:
        Result := RandBetween(1, 2);

      okC:
        Result := RandBetween(3, Max(3, MaxOPPerOT));

      okD:
        Result := RandBetween(3, Max(3, MaxOPPerOT));
    else
      Result := 1;
    end;
  end;

begin
  Randomize;

  SetLength(ops, 0);
  SetLength(links, 0);
  NextOpId := 1000;

  for ofIdx := 1 to Max(0, NumOFs) do
  begin
    NumeroOF := 20000 + ofIdx;
    SerieOF := 'A';

    OfKind := PickOfKind;
    DecideStructureForOF(OfKind, numOT, CreateLinksForThisOT);

    baseStart := RandomTimeInRange(T0, T1);

    for otIdx := 1 to numOT do
    begin
      NumeroOT := 5000 + (ofIdx * 10) + otIdx;
      numOP := DecideNumOpsForOT(OfKind);

      StartNewOTOps;

      curStart := IncMinute(baseStart, (otIdx - 1) * RandBetween(10, 60));
      curStart := ClampToRange(curStart, T0, T1);

      for opIdx := 1 to numOP do
      begin
        gapMin := RandBetween(MinGapMin, MaxGapMin);

        opRec.OpId := NewOpId;

        opRec.NumeroOF := NumeroOF;
        opRec.SerieOF := SerieOF;

        opRec.NumeroOT := NumeroOT;
        // si existeix aquest camp, millor:
        // opRec.SerieOT := SerieOF;

        opRec.NumeroPedido := 0;
        opRec.SeriePedido := '';

        opRec.Stock := Random(1000);
        opRec.CodigoArticulo := 'ARTICULO_' + IntToStr(NumeroOF);
        opRec.DescripcionArticulo := 'DESC ARTICULO_' + IntToStr(NumeroOF);

        opRec.UnidadesAFabricar := 1 + Random(100);
        opRec.UnidadesFabricadas := opRec.UnidadesAFabricar * (Random(10) * 0.1);

        opRec.TiempoUnidadFabSecs := 60 + Random(30);
        opRec.DurationMin := (opRec.TiempoUnidadFabSecs * opRec.UnidadesAFabricar) / 60;
        opRec.DurationMinOriginal := opRec.DurationMin;

        // si vols for�ar una mica la duraci� dins del rang passat per par�metre:
        if opRec.DurationMin < MinDurMin then
          opRec.DurationMin := MinDurMin;
        if opRec.DurationMin > MaxDurMin then
          opRec.DurationMin := MaxDurMin;

        opRec.Prioridad := Random(3);
        opRec.Estado := TEstadoOF(Random(Ord(High(TEstadoOF)) + 1));

        opRec.OperariosAsignados := 0;
        opRec.OperariosNecesarios := Random(3);
        //if opRec.OperariosNecesarios > 0 then
        //  opRec.OperariosAsignados := Random(opRec.OperariosNecesarios + 1);

        opRec.PorcentajeDependencia := RandomQuarterPercent;
        if opRec.PorcentajeDependencia > 100 then
          opRec.PorcentajeDependencia := 100;

        //opRec.NumeroTrabajo := Format('TR-%d-%d', [ofIdx, otIdx]);

        opRec.NumeroTrabajo := 'TR' + inttostr(ofIdx) + SerieOF + '.' + inttostr(otIdx);

        opRec.CodigoCliente := MakeClienteCode(1 + (ofIdx mod 12));
        opRec.CentresTrabajo := PickCentreNames(CentreNames, ProbSinCentro);

        opRec.Operacion := OP_NAMES[opIdx mod Length(OP_NAMES)];

        opRec.StartTime := curStart;
        opRec.EndTime := opRec.StartTime + (opRec.DurationMin / 1440.0);

        opRec.FechaEntrega := IncDay(opRec.StartTime, Random(7));
        opRec.FechaNecesaria := opRec.FechaEntrega;

        if opRec.EndTime > T1 then
          opRec.EndTime := T1;

        if opRec.EndTime <= opRec.StartTime then
          opRec.EndTime := IncMinute(opRec.StartTime, 5);

        opRec.bkColorOp := clSilver;
        opRec.borderColorOp := AdjustColorBrightness(opRec.bkColorOp, -40);

        AddOp(ops, opRec);
        PushOTOp(opRec.OpId, opRec.PorcentajeDependencia);

        curStart := IncMinute(opRec.EndTime, gapMin);
        if curStart > T1 then
          curStart := T1;
      end;

      case OfKind of
        okA:
          begin
            // 1 o 2 operacions, sense links
          end;

        okB:
          begin
            // 1 o 2 operacions; si n'hi ha 2, amb link
            AddChainLinksInOT(True);
          end;

        okC, okD:
          begin
            // 3 o m�s operacions amb links
            AddChainLinksInOT(False); // amb 3+ crea igualment tots els links
            // si vols enlla�os extra:
            // AddExtraRandomLinksInOT;
          end;
      end;
    end;
  end;

  Result.Ops := ops;
  Result.Links := links;
end;


procedure BuildGanttFromRaw(
  const Raw: TErpRaw;
  NodeRepo: TNodeDataRepo;
  out Centres: TArray<TCentreTreball>;
  out Nodes: TArray<TNode>);
var
  centreIdByName: TDictionary<string, Integer>;
  centresTmp: TList<TCentreTreball>;
  nodesTmp: TList<TNode>;

  ofColor: TDictionary<string, TColor>;

  function GetOrCreateCentreId(const CentreName: string): Integer;
  var
    key: string;
    c: TCentreTreball;
    id: Integer;
  begin
    key := Trim(CentreName);
    if key = '' then
      key := 'Sin Centro';

    if centreIdByName.TryGetValue(key, id) then
      Exit(id);

    id := centreIdByName.Count + 1;

    c.Id := id;
    c.Titulo := key;
    c.IsSequencial := False;   // ho pots decidir per CT o per configuraci�
    c.BaseHeight := 60;        // default
    c.Order := id;
    c.Visible := True;
    c.Enabled := True;

    centreIdByName.Add(key, id);
    centresTmp.Add(c);
    Result := id;
  end;

  function GetOFColor(const NumeroOF: Integer; const SerieOF: string): TColor;
  var
    key: string;
  begin
    key := MakeOFKey(NumeroOF, SerieOF);
    if not ofColor.TryGetValue(key, Result) then
    begin
      // RandomSoftColor ja el tens
      Result := RandomSoftColor;
      ofColor.Add(key, Result);
    end;
  end;

var
  op: TErpOp;
  n: TNode;
  d: TNodeData;
  ctId: Integer;
  fill: TColor;
begin
  NodeRepo.Clear;

  centreIdByName := TDictionary<string, Integer>.Create;
  centresTmp := TList<TCentreTreball>.Create;
  nodesTmp := TList<TNode>.Create;
  ofColor := TDictionary<string, TColor>.Create;
  try
    // crea �Sin Centro� al principi (opcional)
    GetOrCreateCentreId('Sin Centro');

    for op in Raw.Ops do
    begin
      if Length(op.CentresTrabajo) > 0 then
        ctId := GetOrCreateCentreId(op.CentresTrabajo[0])
      else
        ctId := GetOrCreateCentreId('Sin Centro');

      // NodeData (domini)
      d.DataId := op.OpId; // clau estable
      d.NumeroOrdenFabricacion := op.NumeroOF;
      d.SerieFabricacion := op.SerieOF;
      d.NumeroTrabajo := op.NumeroTrabajo;

      d.CodigoArticulo := ''; // si el tens
      d.DescripcionArticulo := '';

      d.FechaEntrega := 0; // si aplica
      d.FechaNecesaria := 0;
      d.Modified := False;
      d.LibreMoviment := False;

      // Camps que has afegit:
      // (si els has posat dins TNodeData, assigna�ls aqu�)
      // d.Operacion := op.Operacion;
      // d.CentroTrabajo := op.CentroTrabajo;
      // d.CodigoCliente := op.CodigoCliente;

      NodeRepo.AddOrUpdate(d);

      // Node (visual)
      fill := GetOFColor(op.NumeroOF, op.SerieOF);

      n.Id := op.OpId;
      n.CentreId := ctId;

      n.StartTime := op.StartTime;
      n.EndTime := op.EndTime;
      n.Caption := op.Operacion;

      n.Visible := True;
      n.Enabled := True;

      n.FillColor := fill;
      n.BorderColor := AdjustColorBrightness(fill, -40);
      n.HoverColor := AdjustColorBrightness(fill, +30);

      n.DataId := op.OpId; // apunta al NodeDataRepo

      nodesTmp.Add(n);
    end;

    Centres := centresTmp.ToArray;
    Nodes := nodesTmp.ToArray;
  finally
    ofColor.Free;
    nodesTmp.Free;
    centresTmp.Free;
    centreIdByName.Free;
  end;
end;


procedure BuildGanttFromRawNew(
  const Raw: TErpRaw;
  NodeRepo: TNodeDataRepo;
  const GetCalendar: TGetCalendarFunc;
  out Centres: TArray<TCentreTreball>;
  out Nodes: TArray<TNode>);
var
  centreIdByName: TDictionary<string, Integer>;
  centresTmp: TList<TCentreTreball>;
  nodesTmp: TList<TNode>;
  ofColor64: TDictionary<UInt64, TColor>;

  ofColor: TDictionary<string, TColor>;
  cal: TCentreCalendar;
const
  NW_RADIUS_DAYS = 45; // ajusta segons durades habituals (vacances setmanes -> 30..60)

  function Mix32(x: Cardinal): Cardinal; inline;
  begin
    x := x xor (x shr 16);
    x := x * $7FEB352D;
    x := x xor (x shr 15);
    x := x * $846CA68B;
    x := x xor (x shr 16);
    Result := x;
  end;

  function GetOrCreateCentreId(const CentreName: string): Integer;
  var
    key: string;
    c: TCentreTreball;
    id: Integer;
  begin
    key := Trim(CentreName);
    if key = '' then
      key := 'Sin Centro';

    if centreIdByName.TryGetValue(key, id) then
      Exit(id);

    id := centreIdByName.Count + 1;

    c.Id := id;
    c.Titulo := key;
    c.IsSequencial :=  ((Random(999) Mod  2)=0);   // ho pots decidir per CT o per configuraci�
    c.BaseHeight := 32;
    c.Order := id;
    c.Visible := True;
    c.Enabled := True;

    c.BkColor := $00EEEEEE; //$00EAEAEA;//RGB(Random(255), 0, Random(255));

    centreIdByName.Add(key, id);
    centresTmp.Add(c);
    Result := id;
  end;

  // Retorna array d'ids per un array de noms de centres.
  // Si l'array és buit, retorna [] (= tots els centres permesos).
  function GetOrCreateCentreIds(const CentreNames: TArray<string>): TArray<Integer>;
  var
    i: Integer;
  begin
    SetLength(Result, Length(CentreNames));
    for i := 0 to High(CentreNames) do
      Result[i] := GetOrCreateCentreId(CentreNames[i]);
  end;

  function GetOFColor64(const NumeroOF: Integer; const SerieOF: string): TColor;
  var
    k: Cardinal;
    idx: Integer;
  begin
    // combinem NumeroOF i Serie (16 bits) en un sol Cardinal i el "mixejar"
    k := Cardinal(NumeroOF) xor (HashSerie16(SerieOF) shl 16) xor HashSerie16(SerieOF);
    {$Q-}
    k := Mix32(k);
    {$Q+}
    idx := Integer(k mod Cardinal(Length(GanttColorPalette)));
    Result := GanttColorPalette[idx];
  end;

  function GetOFColor(const NumeroOF: Integer; const SerieOF: string): TColor;
  var
    key: string;
  begin
    key := MakeOFKey(NumeroOF, SerieOF);
    if not ofColor.TryGetValue(key, Result) then
    begin
      // RandomSoftColor ja el tens
      Result := RandomSoftColor;
      ofColor.Add(key, Result);
    end;
  end;

  function GetOFColor64_Simple(const NumeroOF: Integer; const SerieOF: string): TColor;
  var
    k: Cardinal;
    idx: Integer;
  begin
    k := Cardinal(NumeroOF) * 2654435761; // Knuth
    k := k xor Cardinal(HashSerie16(SerieOF));
    idx := Integer(k mod Cardinal(Length(GanttColorPalette)));
    Result := GanttColorPalette[idx];
  end;

var
  op: TErpOp;
  n: TNode;
  d: TNodeData;
  ctId: Integer;
  fill: TColor;
begin
  NodeRepo.Clear;

  centreIdByName := TDictionary<string, Integer>.Create;
  centresTmp := TList<TCentreTreball>.Create;

  nodesTmp := TList<TNode>.Create;
  ofColor := TDictionary<string, TColor>.Create;
  ofColor64 := TDictionary<UInt64, TColor>.Create;

  try
    // crea �Sin Centro� al principi (opcional)
    GetOrCreateCentreId('Sin Centro');

    for op in Raw.Ops do
    begin
      // centre actual: el primer de la llista, o 'Sin Centro' si buida
      if Length(op.CentresTrabajo) > 0 then
        ctId := GetOrCreateCentreId(op.CentresTrabajo[0])
      else
        ctId := GetOrCreateCentreId('Sin Centro');

      // NodeData (domini)
      d.DataId := op.OpId; // clau estable
      d.NumeroOrdenFabricacion := op.NumeroOF;
      d.SerieFabricacion := op.SerieOF;
      d.NumeroTrabajo := op.NumeroTrabajo;

      d.Operacion := op.Operacion;
      d.CentresTrabajo := op.CentresTrabajo;
      d.CentresPermesos := GetOrCreateCentreIds(op.CentresTrabajo);
      d.LibreMoviment := False;

      d.CodigoArticulo := op.CodigoArticulo;
      d.DescripcionArticulo := op.DescripcionArticulo;
      d.CodigoColor := op.CodigoColor;
      d.CodigoTalla := op.CodigoTalla;

      d.FechaEntrega := op.FechaEntrega; // si aplica
      d.FechaNecesaria := op.FechaNecesaria;

      d.Stock := op.Stock;
      d.PorcentajeDependencia := op.PorcentajeDependencia;

      d.UnidadesAFabricar    := op.UnidadesAFabricar;
      d.UnidadesFAbricadas   := op.UnidadesFAbricadas;
      d.TiempoUnidadFabSecs  := op.TiempoUnidadFabSecs;
      d.DurationMin          := op.DurationMin;
      d.DurationMinOriginal  := op.DurationMinOriginal;
      d.OperariosNecesarios  := op.OperariosNecesarios;
      d.OperariosAsignados   := op.OperariosAsignados;

      d.bkColorOp            := op.bkColorOp;
      d.borderColorOp        := op.borderColorOp;

      d.Prioridad := op.Prioridad;
      d.Estado := op.Estado;
      // Camps que has afegit:
      // (si els has posat dins TNodeData, assigna�ls aqu�)
      // d.Operacion := op.Operacion;
      // d.CentroTrabajo := op.CentroTrabajo;
      // d.CodigoCliente := op.CodigoCliente;

      NodeRepo.AddOrUpdate(d);

      // Node (visual)
      //fill := clYellow; //GetOFColor(op.NumeroOF, op.SerieOF);
      fill := GetOFColorFromPalette(op.NumeroOF, op.SerieOF);
      //fill := GetOFColor64(op.NumeroOF, op.SerieOF);

      n.Id := op.OpId;
      n.CentreId := ctId;

      n.StartTime := op.StartTime;
      n.DurationMin := op.DurationMin;
      n.EndTime := op.EndTime;
      n.Caption := op.Operacion;

      n.Visible := True;
      n.Enabled := True;

      n.FillColor := fill;
      n.BorderColor := AdjustColorBrightness(fill, -40);
      n.HoverColor := AdjustColorBrightness(fill, +30);

      n.DataId := op.OpId; // apunta al NodeDataRepo

      // >>> NORMALITZACI� CALENDARI <<<
      if Assigned(GetCalendar) then
      begin
        cal := GetCalendar(ctId);

        NormalizeByDuration( cal, n.StartTime, n.EndTime, d.DurationMin, 1);

      end;

      nodesTmp.Add(n);
    end;

    Centres := centresTmp.ToArray;
    Nodes := nodesTmp.ToArray;
  finally
    ofColor.Free;
    ofColor64.Free;
    nodesTmp.Free;
    centresTmp.Free;
    centreIdByName.Free;
  end;
end;


procedure BuildGanttFromRawNew2(
  const Raw: TErpRaw;
  NodeRepo: TNodeDataRepo;
  const GetCalendar: TGetCalendarFunc;
  out Centres: TArray<TCentreTreball>;
  out Nodes: TArray<TNode>);
type
  TOFVisualColors = record
    Fill: TColor;
    Border: TColor;
    Hover: TColor;
  end;
var
  centreIdByName: TDictionary<string, Integer>;
  centresTmp: TList<TCentreTreball>;
  nodesTmp: TList<TNode>;
  ofVisualCache: TDictionary<UInt64, TOFVisualColors>;
  calendarByCentre: TDictionary<Integer, TCentreCalendar>;

  function MakeOFKey64(const NumeroOF: Integer; const SerieOF: string): UInt64;
  begin
    Result := (UInt64(Cardinal(NumeroOF)) shl 32) or UInt64(Cardinal(HashSerie16(SerieOF)));
  end;

  function Mix32(X: Cardinal): Cardinal; inline;
  begin
    X := X xor (X shr 16);
    X := X xor (X shl 5);
    X := X xor (X shr 13);
    X := X xor (X shl 9);
    X := X xor (X shr 7);
    Result := X;
  end;


  function GetOrCreateCentreId(const CentreName: string): Integer;
  var
    Key: string;
    C: TCentreTreball;
    Id: Integer;
  begin
    Key := CentreName;
    if Key = '' then
      Key := 'Sin Centro';

    if centreIdByName.TryGetValue(Key, Id) then
      Exit(Id);

    Id := centreIdByName.Count + 1;

    C.Id := Id;
    C.Titulo := Key;
    C.IsSequencial := ((Random(999) mod 2) = 0);
    C.BaseHeight := 32;
    C.Order := Id;
    C.Visible := True;
    C.Enabled := True;
    C.BkColor := $00EEEEEE;
    C.Subtitulo := 'Maquina' + inttostr(Id);

    centreIdByName.Add(Key, Id);
    centresTmp.Add(C);
    Result := Id;
  end;

  function GetOrCreateCentreIds(const CentreNames: TArray<string>): TArray<Integer>;
  var
    i: Integer;
  begin
    SetLength(Result, Length(CentreNames));
    for i := 0 to High(CentreNames) do
      Result[i] := GetOrCreateCentreId(CentreNames[i]);
  end;

  function GetCalendarCached(const ACentreId: Integer): TCentreCalendar;
  begin
    if not calendarByCentre.TryGetValue(ACentreId, Result) then
    begin
      if Assigned(GetCalendar) then
        Result := GetCalendar(ACentreId)
      else
        Result := nil;
      calendarByCentre.Add(ACentreId, Result);
    end;
  end;

function GetOFVisualColors(const NumeroOF: Integer; const SerieOF: string): TOFVisualColors;
const
  PaletteCount = Length(GanttColorPalette);
var
  Key: UInt64;
  H: Cardinal;
  Idx: Integer;
begin
  Key := MakeOFKey64(NumeroOF, SerieOF);
  if ofVisualCache.TryGetValue(Key, Result) then
    Exit;
  H := Cardinal(UInt32(NumeroOF));
  H := H xor Cardinal(HashSerie16(SerieOF));
  H := Mix32(H);
  Idx := Integer(H mod PaletteCount);
  Result.Fill := GanttColorPalette[Idx];
  Result.Border := AdjustColorBrightness(Result.Fill, -40);
  Result.Hover := AdjustColorBrightness(Result.Fill, +30);
  ofVisualCache.Add(Key, Result);
end;

var
  Op: TErpOp;
  N: TNode;
  D: TNodeData;
  CtId: Integer;
  Cal: TCentreCalendar;
  VC: TOFVisualColors;
begin
  NodeRepo.Clear;

  centreIdByName := TDictionary<string, Integer>.Create(128);
  centresTmp := TList<TCentreTreball>.Create;
  centresTmp.Capacity := 128;

  nodesTmp := TList<TNode>.Create;
  nodesTmp.Capacity := Length(Raw.Ops);

  ofVisualCache := TDictionary<UInt64, TOFVisualColors>.Create(512);
  calendarByCentre := TDictionary<Integer, TCentreCalendar>.Create(128);

  try
    GetOrCreateCentreId('Sin Centro');

    for Op in Raw.Ops do
    begin
      // centre actual: el primer de la llista, o 'Sin Centro' si buida
      if Length(Op.CentresTrabajo) > 0 then
        CtId := GetOrCreateCentreId(Op.CentresTrabajo[0])
      else
        CtId := GetOrCreateCentreId('Sin Centro');

      D.DataId := Op.OpId;
      D.NumeroOrdenFabricacion := Op.NumeroOF;
      D.SerieFabricacion := Op.SerieOF;
      D.NumeroTrabajo := Op.NumeroTrabajo;
      D.Operacion := Op.Operacion;
      D.CentresTrabajo := Op.CentresTrabajo;
      D.CentresPermesos := GetOrCreateCentreIds(Op.CentresTrabajo);
      D.LibreMoviment := False;
      D.CodigoArticulo := Op.CodigoArticulo;
      D.DescripcionArticulo := Op.DescripcionArticulo;
      D.CodigoColor := Op.CodigoColor;
      D.CodigoTalla := Op.CodigoTalla;
      D.FechaEntrega := Op.FechaEntrega;
      D.FechaNecesaria := Op.FechaNecesaria;
      D.Stock := Op.Stock;
      D.PorcentajeDependencia := Op.PorcentajeDependencia;
      D.UnidadesAFabricar := Op.UnidadesAFabricar;
      D.UnidadesFAbricadas := Op.UnidadesFAbricadas;
      D.TiempoUnidadFabSecs := Op.TiempoUnidadFabSecs;
      D.DurationMin := Op.DurationMin;
      D.DurationMinOriginal := Op.DurationMinOriginal;
      D.OperariosNecesarios := Op.OperariosNecesarios;
      D.OperariosAsignados := Op.OperariosAsignados;
      D.bkColorOp := Op.bkColorOp;
      D.borderColorOp := Op.borderColorOp;
      D.Prioridad := Op.Prioridad;
      D.Estado := Op.Estado;

      NodeRepo.AddOrUpdate(D);

      VC := GetOFVisualColors(Op.NumeroOF, Op.SerieOF);

      N.Id := Op.OpId;
      N.CentreId := CtId;
      N.StartTime := Op.StartTime;
      N.DurationMin := Op.DurationMin;
      N.EndTime := Op.EndTime;
      N.Caption := Op.Operacion;
      N.Visible := True;
      N.Enabled := True;
      N.FillColor := VC.Fill;
      N.BorderColor := VC.Border;
      N.HoverColor := VC.Hover;
      N.DataId := Op.OpId;

      N.StartTime := FloorToMinute(N.StartTime);
      N.EndTime   := FloorToMinute(N.EndTime);

      Cal := GetCalendarCached(CtId);
      if Cal <> nil then
        NormalizePlannedInterval(Cal, N.StartTime, N.EndTime, D.DurationMin, 1)
      else
      begin
        N.StartTime := FloorToMinute(N.StartTime);
        N.EndTime   := FloorToMinute(N.EndTime);
      end;

      nodesTmp.Add(N);
    end;

    Centres := centresTmp.ToArray;
    Nodes := nodesTmp.ToArray;
  finally
    calendarByCentre.Free;
    ofVisualCache.Free;
    nodesTmp.Free;
    centresTmp.Free;
    centreIdByName.Free;
  end;
end;


end.
