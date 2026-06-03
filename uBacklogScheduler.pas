unit uBacklogScheduler;

{
  Motor de auto-planificacion a partir de una seleccion del Backlog.

  ESTADO (2026-05-20):
  - Este unit alberga la implementacion FCS push (forward/backward) y los
    records de IO (TSchedInput/Output/Result/Params).
  - A partir de hoy existe ademas IPlanningEngine en uPlanningEngine, con dos
    implementaciones (TForward/TBackwardSchedulerEngine en uPlanningEngineFCS)
    que envuelven RunAutoScheduling.
  - Los consumidores nuevos deberian crear el engine via
    CreatePlanningEngine(...) y llamar Engine.Schedule(...). RunAutoScheduling
    permanece como API publica para no romper a uBacklog.btnPlanificarClick.
  - Cuando aparezca una variante real distinta (bottleneck-based, DBR, etc.)
    se promocionaran las clases del engine y RunAutoScheduling se reducira a
    una llamada al engine pekForward por defecto.

  Estrategia:
  - 1 fila de Backlog -> 1 nodo.
  - Siempre se usa el CentroPreferente. Si esta saturado, el nodo se apila
    igualmente (end se desplaza hasta que la capacidad en la ventana agota).
  - Si la fila no tiene CentroPreferente -> no se planifica, va a la lista
    de no planificadas.
  - Duracion = HorasEstimadas * 60 minutos. Si HorasEstimadas <= 0,
    se usa 60 min por defecto.
  - Calendarios de centro se respetan (AddWorkingMinutes / SubtractWorkingMinutes).
  - Modo Forward: el nodo arranca en el "cursor" del centro (>= FechaBase)
    y se extiende hacia adelante.
  - Modo Backward: el nodo termina en la FechaCompromiso y se extiende
    hacia atras. Si no tiene FechaCompromiso -> fallback a Forward desde
    FechaBase.
}

interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  System.Generics.Collections,
  uGanttTypes;

type
  TSchedMode = (smForward, smBackward);
  // soPreordenado: la cola ya viene ordenada por el llamador (p.ej. el motor
  // de reglas de prioridad) y RunAutoScheduling NO debe reordenarla.
  TSchedOrder = (soFechaCompromiso, soPrioridad, soPreordenado);

  TSchedInput = record
    RawId: Int64;
    Origen: string;
    CodigoDocumento: string;
    CentroPreferente: string;
    HorasEstimadas: Double;
    FechaCompromiso: TDateTime;
    Prioridad: Integer;
    NumeroOF: Integer;
    SerieOF: string;
    NumeroPedido: Integer;
    SeriePedido: string;
    CodigoCliente: string;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    UnidadesAFabricar: Double;
    NumeroTrabajo: string;
    FechaEntrega: TDateTime;
    FechaNecesaria: TDateTime;
    TiempoUnidadFabSecs: Double;
    // Link al modelo unificado FS_PL_Raw_Item (V016)
    RawItemClaveERP: string;     // ClaveERP del item planificado (Nivel 3 en el modelo PRO)
    RawItemTipoOrigen: string;   // 'OF ','PED','PRJ' (char(3) SQL)
  end;

  TSchedStatus = (ssOK, ssSaturado, ssFueraPlazo, ssSinCentro, ssSinCalendario);

  TSchedOutput = record
    Input: TSchedInput;
    CenterId: Integer;
    CenterCode: string;
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    DuracionMin: Double;
    Status: TSchedStatus;
    Observaciones: string;
  end;

  TSchedParams = record
    Mode: TSchedMode;
    Order: TSchedOrder;
    FechaBase: TDateTime;     // usada en Forward o como fallback en Backward
  end;

  TSchedResult = record
    Items: TArray<TSchedOutput>;
    TotalPlanificados: Integer;
    TotalNoPlanificados: Integer;
    TotalSaturados: Integer;
    TotalFueraPlazo: Integer;
  end;

  // Indicadores derivados de un TSchedResult (para preview y comparativa).
  TSchedKpis = record
    Total: Integer;
    Planificados: Integer;
    NoPlanificados: Integer;
    Saturados: Integer;
    FueraPlazo: Integer;
    Retrasos: Integer;        // ops con FechaFin > FechaCompromiso
    RetrasoTotalH: Double;    // suma de horas de retraso
    RetrasoMedioH: Double;    // RetrasoTotalH / Retrasos
    MakespanH: Double;        // (max fin - min inicio) en horas
  end;

  // ---------------------------------------------------------------------------
  // Reglas de prioridad (motor PRO de planificacion por reglas).
  // Cada regla es un criterio determinista de ordenacion de la cola de
  // operaciones. Se calculan sobre datos ya presentes en TSchedInput,
  // relativos a una fecha base.
  //
  //   prEDD          Earliest Due Date   -> FechaCompromiso ascendente.
  //   prSPT          Shortest Proc. Time -> HorasEstimadas ascendente.
  //   prLPT          Longest Proc. Time  -> HorasEstimadas descendente.
  //   prFIFO         First In First Out  -> orden de llegada (NumeroOF/RawId).
  //   prCriticalRatio Critical Ratio     -> (tiempo hasta vencer)/trabajo asc.
  //   prSlack        Holgura             -> (tiempo hasta vencer)-trabajo asc.
  //   prPrioridadErp Prioridad ERP       -> Prioridad descendente.
  // ---------------------------------------------------------------------------
  TPriorityRule = (
    prEDD, prSPT, prLPT, prFIFO, prCriticalRatio, prSlack, prPrioridadErp
  );

  // Conjunto de reglas con desempate multinivel: cuando la regla Principal
  // produce empate (dentro de tolerancia), se aplica Desempate1, y luego
  // Desempate2. Ultimo recurso siempre: RawId (estable y determinista).
  TPriorityRuleSet = record
    Principal: TPriorityRule;
    Desempate1: TPriorityRule;
    Desempate2: TPriorityRule;
  end;

function PriorityRuleToStr(R: TPriorityRule): string;
function DefaultRuleSet: TPriorityRuleSet;
function ComputeKpis(const AResult: TSchedResult): TSchedKpis;

function RunAutoScheduling(const AInputs: TArray<TSchedInput>;
  const AParams: TSchedParams): TSchedResult;

function StatusToStr(AStatus: TSchedStatus): string;

// Ordena la cola segun un conjunto de reglas con desempate multinivel.
// AFechaBase se usa como referencia para CriticalRatio y Slack.
// SortInputs (2 criterios, legacy) se mantiene para los consumidores actuales.
procedure SortInputsByRuleSet(var AInputs: TArray<TSchedInput>;
  const ARules: TPriorityRuleSet; const AFechaBase: TDateTime);

implementation

uses
  System.Generics.Defaults, System.Math,
  uDMPlanner, uCentresRepo, uCentreCalendar;

function PriorityRuleToStr(R: TPriorityRule): string;
begin
  case R of
    prEDD:           Result := 'EDD (vencimiento mas proximo)';
    prSPT:           Result := 'SPT (tarea mas corta)';
    prLPT:           Result := 'LPT (tarea mas larga)';
    prFIFO:          Result := 'FIFO (orden de llegada)';
    prCriticalRatio: Result := 'Critical Ratio (menos margen relativo)';
    prSlack:         Result := 'Slack (menos holgura)';
    prPrioridadErp:  Result := 'Prioridad ERP';
  else
    Result := '?';
  end;
end;

function DefaultRuleSet: TPriorityRuleSet;
begin
  Result.Principal  := prEDD;
  Result.Desempate1 := prFIFO;
  Result.Desempate2 := prFIFO;
end;

function ComputeKpis(const AResult: TSchedResult): TSchedKpis;
var
  I: Integer;
  Item: TSchedOutput;
  MinIni, MaxFin: TDateTime;
  TieneRango: Boolean;
begin
  Result := Default(TSchedKpis);
  Result.Total          := Length(AResult.Items);
  Result.Planificados   := AResult.TotalPlanificados;
  Result.NoPlanificados := AResult.TotalNoPlanificados;
  Result.Saturados      := AResult.TotalSaturados;
  Result.FueraPlazo     := AResult.TotalFueraPlazo;

  MinIni := 0;
  MaxFin := 0;
  TieneRango := False;

  for I := 0 to High(AResult.Items) do
  begin
    Item := AResult.Items[I];

    if (Item.FechaFin <> 0) and (Item.Input.FechaCompromiso <> 0) and
       (Item.FechaFin > Item.Input.FechaCompromiso) then
    begin
      Inc(Result.Retrasos);
      Result.RetrasoTotalH := Result.RetrasoTotalH +
        (Item.FechaFin - Item.Input.FechaCompromiso) * 24.0;
    end;

    if Item.FechaInicio <> 0 then
    begin
      if not TieneRango then
      begin
        MinIni := Item.FechaInicio;
        MaxFin := Item.FechaFin;
        TieneRango := True;
      end
      else
      begin
        if Item.FechaInicio < MinIni then MinIni := Item.FechaInicio;
        if Item.FechaFin > MaxFin then MaxFin := Item.FechaFin;
      end;
    end;
  end;

  if Result.Retrasos > 0 then
    Result.RetrasoMedioH := Result.RetrasoTotalH / Result.Retrasos;
  if TieneRango then
    Result.MakespanH := (MaxFin - MinIni) * 24.0;
end;

function StatusToStr(AStatus: TSchedStatus): string;
begin
  case AStatus of
    ssOK:            Result := 'OK';
    ssSaturado:      Result := 'SATURADO';
    ssFueraPlazo:    Result := 'FUERA DE PLAZO';
    ssSinCentro:     Result := 'SIN CENTRO';
    ssSinCalendario: Result := 'SIN CALENDARIO';
  else
    Result := '?';
  end;
end;

type
  TCenterCursor = record
    CenterId: Integer;
    Code: string;
    Cal: TCentreCalendar;
    IsSequencial: Boolean;
    Lanes: Integer;
    // Para apilar: por cada lane, fin actual en Forward o inicio actual en Backward
    LaneCursors: TArray<TDateTime>;
  end;

function GetLanes(const C: TCentreTreball): Integer;
begin
  if C.IsSequencial then Exit(1);
  if C.MaxLaneCount <= 0 then Exit(1);
  Result := C.MaxLaneCount;
end;

// Busca el lane con el cursor mas temprano (Forward) o mas tardio (Backward)
function PickLane(const Cursor: TCenterCursor; Forward: Boolean): Integer;
var
  I: Integer;
  Best: TDateTime;
begin
  Result := 0;
  if Length(Cursor.LaneCursors) = 0 then Exit;
  Best := Cursor.LaneCursors[0];
  for I := 1 to High(Cursor.LaneCursors) do
  begin
    if Forward then
    begin
      if Cursor.LaneCursors[I] < Best then
      begin
        Best := Cursor.LaneCursors[I];
        Result := I;
      end;
    end
    else
    begin
      if Cursor.LaneCursors[I] > Best then
      begin
        Best := Cursor.LaneCursors[I];
        Result := I;
      end;
    end;
  end;
end;

procedure SortInputs(var AInputs: TArray<TSchedInput>; AOrder: TSchedOrder);
var
  I, J: Integer;
  Tmp: TSchedInput;
  Swap: Boolean;
begin
  // La cola ya viene ordenada por el llamador: respetar el orden recibido.
  if AOrder = soPreordenado then Exit;
  // Bubble sort simple (muestras pequenas, N < 200)
  for I := 0 to High(AInputs) - 1 do
    for J := 0 to High(AInputs) - 1 - I do
    begin
      Swap := False;
      case AOrder of
        soFechaCompromiso:
          begin
            if (AInputs[J].FechaCompromiso = 0) and (AInputs[J + 1].FechaCompromiso <> 0) then
              Swap := True
            else if (AInputs[J].FechaCompromiso <> 0) and (AInputs[J + 1].FechaCompromiso <> 0) then
              Swap := AInputs[J].FechaCompromiso > AInputs[J + 1].FechaCompromiso;
          end;
        soPrioridad:
          Swap := AInputs[J].Prioridad < AInputs[J + 1].Prioridad;
      end;
      if Swap then
      begin
        Tmp := AInputs[J];
        AInputs[J] := AInputs[J + 1];
        AInputs[J + 1] := Tmp;
      end;
    end;
end;

// ---------------------------------------------------------------------------
// Ordenacion por conjunto de reglas con desempate multinivel.
// ---------------------------------------------------------------------------

const
  // Tolerancia (en dias) para considerar dos fechas "iguales" a efectos de
  // desempate: mismo dia natural cuenta como empate y pasa al siguiente nivel.
  RULE_DATE_TOL = 0.5;

// Trabajo restante (en horas) usado por CriticalRatio y Slack. Hoy se usa
// HorasEstimadas como proxy (no hay horas-hechas en el input). Minimo 0.
function WorkHours(const A: TSchedInput): Double;
begin
  Result := A.HorasEstimadas;
  if Result < 0 then Result := 0;
end;

// Compara A vs B segun UNA regla. Devuelve <0 si A va antes, >0 si despues,
// 0 si empatan (a resolver por el siguiente nivel de desempate).
// Las operaciones sin FechaCompromiso (=0) se consideran "sin urgencia" y
// van detras de las que si la tienen, replicando el criterio de SortInputs.
function CompareByRule(const A, B: TSchedInput; ARule: TPriorityRule;
  const AFechaBase: TDateTime): Integer;

  // Coloca los "sin fecha" al final. Devuelve True si ya ha resuelto el orden
  // (uno tiene fecha y el otro no) y deja el resultado en AOut.
  function ResolveMissingDue(out AOut: Integer): Boolean;
  begin
    Result := True;
    if (A.FechaCompromiso = 0) and (B.FechaCompromiso <> 0) then
      AOut := 1                       // A sin fecha -> detras
    else if (A.FechaCompromiso <> 0) and (B.FechaCompromiso = 0) then
      AOut := -1                      // B sin fecha -> A delante
    else
      Result := False;                // ambos con o sin fecha: no resuelto aqui
  end;

var
  Resolved: Integer;
  CrA, CrB, SlA, SlB, RemA, RemB: Double;
begin
  Result := 0;
  case ARule of
    prEDD:
      begin
        if ResolveMissingDue(Resolved) then Exit(Resolved);
        if (A.FechaCompromiso = 0) and (B.FechaCompromiso = 0) then Exit(0);
        Result := CompareValue(A.FechaCompromiso, B.FechaCompromiso, RULE_DATE_TOL);
      end;

    prSPT:
      Result := CompareValue(WorkHours(A), WorkHours(B));

    prLPT:
      Result := CompareValue(WorkHours(B), WorkHours(A));

    prFIFO:
      begin
        // Orden de llegada: NumeroOF como proxy principal, RawId como respaldo.
        Result := CompareValue(A.NumeroOF, B.NumeroOF);
        if Result = 0 then
          Result := CompareValue(A.RawId, B.RawId);
      end;

    prCriticalRatio:
      begin
        // CR = (tiempo hasta vencer) / trabajo restante. Menor = mas critico.
        // Sin fecha -> al final. Trabajo 0 -> CR infinito (no critico): detras.
        if ResolveMissingDue(Resolved) then Exit(Resolved);
        if (A.FechaCompromiso = 0) and (B.FechaCompromiso = 0) then Exit(0);
        RemA := WorkHours(A);
        RemB := WorkHours(B);
        if RemA <= 0 then CrA := Infinity
        else CrA := ((A.FechaCompromiso - AFechaBase) * 24.0) / RemA;
        if RemB <= 0 then CrB := Infinity
        else CrB := ((B.FechaCompromiso - AFechaBase) * 24.0) / RemB;
        Result := CompareValue(CrA, CrB);
      end;

    prSlack:
      begin
        // Slack = (tiempo hasta vencer en horas) - trabajo restante. Menor = mas critico.
        if ResolveMissingDue(Resolved) then Exit(Resolved);
        if (A.FechaCompromiso = 0) and (B.FechaCompromiso = 0) then Exit(0);
        SlA := (A.FechaCompromiso - AFechaBase) * 24.0 - WorkHours(A);
        SlB := (B.FechaCompromiso - AFechaBase) * 24.0 - WorkHours(B);
        Result := CompareValue(SlA, SlB);
      end;

    prPrioridadErp:
      // Prioridad mas alta primero (descendente).
      Result := CompareValue(B.Prioridad, A.Prioridad);
  end;
end;

procedure SortInputsByRuleSet(var AInputs: TArray<TSchedInput>;
  const ARules: TPriorityRuleSet; const AFechaBase: TDateTime);
var
  Comparer: IComparer<TSchedInput>;
  Base: TDateTime;
  Rules: TPriorityRuleSet;
begin
  if Length(AInputs) < 2 then Exit;
  Base := AFechaBase;
  Rules := ARules;
  Comparer := TComparer<TSchedInput>.Construct(
    function(const A, B: TSchedInput): Integer
    begin
      Result := CompareByRule(A, B, Rules.Principal, Base);
      if Result = 0 then
        Result := CompareByRule(A, B, Rules.Desempate1, Base);
      if Result = 0 then
        Result := CompareByRule(A, B, Rules.Desempate2, Base);
      if Result = 0 then
        // Desempate final estable y determinista.
        Result := CompareValue(A.RawId, B.RawId);
    end);
  TArray.Sort<TSchedInput>(AInputs, Comparer);
end;

function RunAutoScheduling(const AInputs: TArray<TSchedInput>;
  const AParams: TSchedParams): TSchedResult;
var
  Inputs: TArray<TSchedInput>;
  Params: TSchedParams;
  CentresMap: TDictionary<string, TCentreTreball>;
  Cursors: TDictionary<Integer, TCenterCursor>;
  Centres: TArray<TCentreTreball>;
  C: TCentreTreball;
  Cursor: TCenterCursor;
  I, Lane: Integer;
  Input: TSchedInput;
  Output: TSchedOutput;
  DurMin: Integer;
  StartDT, EndDT: TDateTime;
  OutList: TList<TSchedOutput>;
  Key: string;
  NowDT: TDateTime;
begin
  Result := Default(TSchedResult);
  Inputs := Copy(AInputs);
  SortInputs(Inputs, AParams.Order);

  // Normalizar FechaBase: si es hoy (o anterior) usar Now(), para no planificar
  // en horas ya pasadas. Si es una fecha futura, se respeta tal cual (el usuario
  // quiere arrancar a las 00:00 de ese dia). La validacion contra FechaBloqueo
  // se hace ya en el caller (btnPlanificarClick), aqui solo nos ocupamos de
  // la hora.
  Params := AParams;
  NowDT := Now;
  if Trunc(Params.FechaBase) <= Trunc(NowDT) then
    Params.FechaBase := NowDT;

  CentresMap := TDictionary<string, TCentreTreball>.Create;
  Cursors := TDictionary<Integer, TCenterCursor>.Create;
  OutList := TList<TSchedOutput>.Create;
  try
    if DMPlanner.CentresRepo <> nil then
    begin
      Centres := DMPlanner.CentresRepo.GetAll;
      for C in Centres do
        CentresMap.AddOrSetValue(UpperCase(Trim(C.CodiCentre)), C);
    end;

    for I := 0 to High(Inputs) do
    begin
      Input := Inputs[I];
      Output := Default(TSchedOutput);
      Output.Input := Input;
      Output.CenterCode := Input.CentroPreferente;

      if Trim(Input.CentroPreferente) = '' then
      begin
        Output.Status := ssSinCentro;
        Output.Observaciones := 'Sin centro preferente';
        OutList.Add(Output);
        Inc(Result.TotalNoPlanificados);
        Continue;
      end;

      Key := UpperCase(Trim(Input.CentroPreferente));
      if not CentresMap.TryGetValue(Key, C) then
      begin
        Output.Status := ssSinCentro;
        Output.Observaciones := 'Centro ' + Input.CentroPreferente + ' no existe';
        OutList.Add(Output);
        Inc(Result.TotalNoPlanificados);
        Continue;
      end;

      // Inicializar cursor del centro si es la primera vez
      if not Cursors.TryGetValue(C.Id, Cursor) then
      begin
        Cursor := Default(TCenterCursor);
        Cursor.CenterId := C.Id;
        Cursor.Code := C.CodiCentre;
        Cursor.Cal := DMPlanner.CentresRepo.GetCalendarFor(C.Id);
        Cursor.IsSequencial := C.IsSequencial;
        Cursor.Lanes := GetLanes(C);
        SetLength(Cursor.LaneCursors, Cursor.Lanes);
        Cursors.Add(C.Id, Cursor);
      end;

      Output.CenterId := C.Id;

      if Cursor.Cal = nil then
      begin
        Output.Status := ssSinCalendario;
        Output.Observaciones := 'Centro sin calendario asignado';
        OutList.Add(Output);
        Inc(Result.TotalNoPlanificados);
        Continue;
      end;

      if Input.HorasEstimadas > 0 then
        DurMin := Round(Input.HorasEstimadas * 60)
      else
        DurMin := 60;
      Output.DuracionMin := DurMin;

      case AParams.Mode of
        smBackward:
          begin
            if Input.FechaCompromiso = 0 then
            begin
              // Fallback a Forward desde FechaBase
              Lane := PickLane(Cursor, True);
              if Cursor.LaneCursors[Lane] = 0 then
                Cursor.LaneCursors[Lane] := Params.FechaBase;
              if Cursor.LaneCursors[Lane] < Params.FechaBase then
                Cursor.LaneCursors[Lane] := Params.FechaBase;
              StartDT := Cursor.Cal.NextWorkingTime(Cursor.LaneCursors[Lane]);
              EndDT := Cursor.Cal.AddWorkingMinutes(StartDT, DurMin);
              Cursor.LaneCursors[Lane] := EndDT;
              Output.FechaInicio := StartDT;
              Output.FechaFin := EndDT;
              Output.Status := ssFueraPlazo;
              Output.Observaciones := 'Sin FechaCompromiso; planificado forward';
              Inc(Result.TotalFueraPlazo);
            end
            else
            begin
              Lane := PickLane(Cursor, False);  // lane con cursor mas tardio
              if Cursor.LaneCursors[Lane] = 0 then
                Cursor.LaneCursors[Lane] := Input.FechaCompromiso
              else if Cursor.LaneCursors[Lane] > Input.FechaCompromiso then
                Cursor.LaneCursors[Lane] := Input.FechaCompromiso;

              EndDT := Cursor.Cal.PrevWorkingTime(Cursor.LaneCursors[Lane]);
              StartDT := Cursor.Cal.SubtractWorkingMinutes(EndDT, DurMin);
              Cursor.LaneCursors[Lane] := StartDT;

              Output.FechaInicio := StartDT;
              Output.FechaFin := EndDT;
              if StartDT < Params.FechaBase then
              begin
                Output.Status := ssSaturado;
                Output.Observaciones := 'No cabe antes de FechaCompromiso';
                Inc(Result.TotalSaturados);
              end
              else
              begin
                Output.Status := ssOK;
                Inc(Result.TotalPlanificados);
              end;
            end;
          end;

        smForward:
          begin
            Lane := PickLane(Cursor, True);
            if Cursor.LaneCursors[Lane] = 0 then
              Cursor.LaneCursors[Lane] := Params.FechaBase;
            if Cursor.LaneCursors[Lane] < Params.FechaBase then
              Cursor.LaneCursors[Lane] := Params.FechaBase;

            StartDT := Cursor.Cal.NextWorkingTime(Cursor.LaneCursors[Lane]);
            EndDT := Cursor.Cal.AddWorkingMinutes(StartDT, DurMin);
            Cursor.LaneCursors[Lane] := EndDT;

            Output.FechaInicio := StartDT;
            Output.FechaFin := EndDT;

            if (Input.FechaCompromiso <> 0) and (EndDT > Input.FechaCompromiso) then
            begin
              Output.Status := ssFueraPlazo;
              Output.Observaciones := 'Supera FechaCompromiso';
              Inc(Result.TotalFueraPlazo);
            end
            else
            begin
              Output.Status := ssOK;
              Inc(Result.TotalPlanificados);
            end;
          end;
      end;

      // Guardar el cursor actualizado
      Cursors.AddOrSetValue(C.Id, Cursor);

      OutList.Add(Output);
    end;

    Result.Items := OutList.ToArray;
  finally
    CentresMap.Free;
    Cursors.Free;
    OutList.Free;
  end;
end;

end.
