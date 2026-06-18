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
  - Si el centro NO tiene calendario asignado, NO se descarta: se planifica
    como tiempo continuo 24x7 (los nodos se encadenan uno detras de otro,
    respetando lanes), y se anota en Observaciones.
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
    // Tiempos reales de la operacion (Nivel 3) para el calculo de duracion.
    // Misma cascada que FS_PL_fn_DuracionOpMin (V054). Ver CalcDuracionOpMin.
    OpTiempoFabricacion: Double;   // dias, total operacion
    OpUnidadesHora: Double;        // unidades/hora
    OpTiempoPreparacion: Double;   // dias
    Cantidad: Double;              // unidades de la OP
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

  // Politica de colocacion frente a los nodos YA EXISTENTES en el centro:
  //   ppFinCola      No buscar huecos: encolar siempre detras del ultimo nodo.
  //   ppHueco        Rellenar huecos: colocar en el primer hueco VALIDO a partir
  //                  de FechaBase (que cumpla los umbrales HuecoMinimoMin y
  //                  PorcentajeMinNodo); si ninguno vale, al final.
  //   ppHuecoShift   Rellenar huecos y desplazar: igual, pero si un hueco valido
  //                  no cabe entero, coloca igualmente y empuja los nodos
  //                  posteriores NO bloqueados para hacer sitio.
  //
  // Umbrales (alineados con APS PRO, evitan fragmentar el plan en microhuecos):
  //   HuecoMinimoMin   Un hueco mas corto que esto (minutos de reloj) nunca se
  //                    usa para insertar.
  //   PorcentajeMinNodo  El hueco debe ser >= este % de la duracion del nodo
  //                    para considerarse utilizable (0..100). Con 100 exige que
  //                    el nodo quepa entero; con 50, al menos la mitad.
  TPlacementPolicy = (ppFinCola, ppHueco, ppHuecoShift);

  TSchedParams = record
    Mode: TSchedMode;
    Order: TSchedOrder;
    FechaBase: TDateTime;     // usada en Forward o como fallback en Backward
    Placement: TPlacementPolicy;
    HuecoMinimoMin: Integer;     // hueco minimo en minutos (def. 30)
    PorcentajeMinNodo: Integer;  // % minimo del nodo (def. 50)
    DistanciaMinNodos: Integer;  // separacion minima entre nodos consecutivos
                                 // en el mismo lane, en minutos (def. 0)
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

// Duracion de una OP en minutos. Replica de FS_PL_fn_DuracionOpMin (V054):
// unica fuente de verdad para "cuanto dura una operacion" antes de planificar.
function CalcDuracionOpMin(const AInput: TSchedInput): Double;

function RunAutoScheduling(const AInputs: TArray<TSchedInput>;
  const AParams: TSchedParams): TSchedResult;

function StatusToStr(AStatus: TSchedStatus): string;
function PlacementToStr(P: TPlacementPolicy): string;

// Ordena la cola segun un conjunto de reglas con desempate multinivel.
// AFechaBase se usa como referencia para CriticalRatio y Slack.
// SortInputs (2 criterios, legacy) se mantiene para los consumidores actuales.
procedure SortInputsByRuleSet(var AInputs: TArray<TSchedInput>;
  const ARules: TPriorityRuleSet; const AFechaBase: TDateTime);

implementation

uses
  System.Generics.Defaults, System.Math, Data.Win.ADODB,
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

function CalcDuracionOpMin(const AInput: TSchedInput): Double;
var
  PrepMin, FabMin: Double;
begin
  // Misma cascada que FS_PL_fn_DuracionOpMin (V054), validada contra datos
  // reales del Sage (2026-06-07):
  //   OpTiempoFabricacion / OpTiempoPreparacion vienen en DIAS y son el tiempo
  //   TOTAL de la operacion (no por unidad) -> * 24 * 60 = minutos.
  if AInput.OpTiempoPreparacion > 0 then
    PrepMin := AInput.OpTiempoPreparacion * 24.0 * 60.0
  else
    PrepMin := 0;

  if AInput.OpTiempoFabricacion > 0 then
    FabMin := AInput.OpTiempoFabricacion * 24.0 * 60.0
  else if (AInput.OpUnidadesHora > 0) and (AInput.Cantidad > 0) then
    FabMin := (AInput.Cantidad / AInput.OpUnidadesHora) * 60.0
  else if AInput.HorasEstimadas > 0 then
    FabMin := AInput.HorasEstimadas * 60.0
  else
    FabMin := 60.0;

  Result := PrepMin + FabMin;
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

function PlacementToStr(P: TPlacementPolicy): string;
begin
  case P of
    ppFinCola:    Result := 'A'#241'adir al final de la cola';
    ppHueco:      Result := 'Rellenar huecos v'#225'lidos';
    ppHuecoShift: Result := 'Rellenar huecos y desplazar';
  else
    Result := '?';
  end;
end;

type
  // Un intervalo ocupado en un lane (nodo existente o ya planificado en esta
  // tanda). Bloqueado = anterior a FechaBloqueo del proyecto: no se desplaza.
  TLaneSlot = record
    StartDT: TDateTime;
    EndDT: TDateTime;
    Bloqueado: Boolean;
  end;

  TLaneOcc = TList<TLaneSlot>;  // ordenada por StartDT ascendente

  TCenterCursor = record
    CenterId: Integer;
    Code: string;
    Cal: TCentreCalendar;
    IsSequencial: Boolean;
    Lanes: Integer;
    // Ocupacion real por lane: intervalos ya ocupados (existentes + planificados).
    LaneOcc: TArray<TLaneOcc>;
  end;

function GetLanes(const C: TCentreTreball): Integer;
begin
  if C.IsSequencial then Exit(1);
  if C.MaxLaneCount <= 0 then Exit(1);
  Result := C.MaxLaneCount;
end;

// Inserta un slot en la lista del lane manteniendo orden por StartDT.
procedure InsertSlotOrdered(AOcc: TLaneOcc; const ASlot: TLaneSlot);
var
  I: Integer;
begin
  I := 0;
  while (I < AOcc.Count) and (AOcc[I].StartDT <= ASlot.StartDT) do
    Inc(I);
  AOcc.Insert(I, ASlot);
end;

// "Cursor" de un lane = fin del ultimo slot ocupado (Forward) o inicio del
// primero (Backward). Si el lane esta vacio devuelve 0.
function LaneEnd(AOcc: TLaneOcc): TDateTime;
begin
  if AOcc.Count = 0 then Result := 0
  else Result := AOcc[AOcc.Count - 1].EndDT;
end;

function LaneStart(AOcc: TLaneOcc): TDateTime;
begin
  if AOcc.Count = 0 then Result := 0
  else Result := AOcc[0].StartDT;
end;

// Wrappers de calendario: si el centro no tiene calendario (ACal=nil) se trata
// como tiempo continuo 24x7; si lo tiene, se delega en el.
function CalNext(ACal: TCentreCalendar; const T: TDateTime): TDateTime;
begin
  if ACal = nil then Result := T else Result := ACal.NextWorkingTime(T);
end;

function CalAdd(ACal: TCentreCalendar; const T: TDateTime; AMin: Integer): TDateTime;
begin
  if ACal = nil then Result := IncMinute(T, AMin)
  else Result := ACal.AddWorkingMinutes(T, AMin);
end;

function CalPrev(ACal: TCentreCalendar; const T: TDateTime): TDateTime;
begin
  if ACal = nil then Result := T else Result := ACal.PrevWorkingTime(T);
end;

function CalSub(ACal: TCentreCalendar; const T: TDateTime; AMin: Integer): TDateTime;
begin
  if ACal = nil then Result := IncMinute(T, -AMin)
  else Result := ACal.SubtractWorkingMinutes(T, AMin);
end;

// Comprueba si [AStart,AEnd) solapa algun slot ya ocupado del lane.
function LaneCollides(AOcc: TLaneOcc; const AStart, AEnd: TDateTime): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to AOcc.Count - 1 do
    if (AEnd > AOcc[I].StartDT) and (AStart < AOcc[I].EndDT) then
      Exit(True);
end;

// Minutos de RELOJ entre dos instantes (no laborables; sirve para medir el
// tamano bruto de un hueco contra el umbral HuecoMinimo).
function ClockMinutes(const A, B: TDateTime): Integer;
begin
  Result := Round((B - A) * 24 * 60);
end;

// Coloca un nodo de AMin minutos en el lane, en modo Forward, segun la politica
// y los umbrales de hueco. Devuelve el StartDT propuesto (alineado a calendario).
// No modifica la ocupacion: el llamador inserta el slot resultante.
//
// Un hueco [GapStart, GapEnd) se considera VALIDO para insertar si:
//   - dura >= AHuecoMinMin minutos de reloj, Y
//   - dura >= (APctMinNodo% de AMin) minutos de reloj.
// ppHueco: usa el primer hueco valido donde el nodo quepa entero; si no, final.
// ppHuecoShift: usa el primer hueco valido aunque el nodo no quepa entero
//   (marca shift para empujar lo posterior no bloqueado); si no hay valido, final.
function PlaceForward(AOcc: TLaneOcc; ACal: TCentreCalendar;
  const AFechaBase: TDateTime; AMin: Integer;
  APolicy: TPlacementPolicy; AHuecoMinMin, APctMinNodo, ADistMin: Integer;
  out ANeedsShift: Boolean): TDateTime;
var
  I, GapClock, MinPorPct: Integer;
  Cursor, GapStart, GapEnd, S, E, LimiteFin: TDateTime;
  HuecoValido: Boolean;

  // Avanza T la distancia minima entre nodos (en minutos de reloj), respetando
  // calendario. Si ADistMin<=0 no hace nada.
  function AplicarDistancia(const T: TDateTime): TDateTime;
  begin
    if ADistMin > 0 then Result := CalAdd(ACal, T, ADistMin)
    else Result := T;
  end;

begin
  ANeedsShift := False;

  // ppFinCola: detras del ultimo slot (+ distancia minima) o FechaBase si vacio.
  if APolicy = ppFinCola then
  begin
    Cursor := LaneEnd(AOcc);
    if Cursor > 0 then Cursor := AplicarDistancia(Cursor);
    if Cursor < AFechaBase then Cursor := AFechaBase;
    Exit(CalNext(ACal, Cursor));
  end;

  // Umbral por porcentaje del nodo (en minutos de reloj).
  MinPorPct := Round(AMin * (APctMinNodo / 100.0));

  // Politicas con busqueda de hueco. Recorremos los huecos entre slots a
  // partir de FechaBase. El primer slot ya empieza ordenado por StartDT.
  Cursor := AFechaBase;
  for I := 0 to AOcc.Count - 1 do
  begin
    if AOcc[I].EndDT <= Cursor then Continue;  // slot ya pasado
    GapStart := Cursor;
    GapEnd := AOcc[I].StartDT;
    if GapEnd > GapStart then
    begin
      GapClock := ClockMinutes(GapStart, GapEnd);
      // El hueco es VALIDO si supera ambos umbrales.
      HuecoValido := (GapClock >= AHuecoMinMin) and (GapClock >= MinPorPct);
      if HuecoValido then
      begin
        S := CalNext(ACal, GapStart);
        E := CalAdd(ACal, S, AMin);
        // El nodo debe terminar dejando ADistMin de margen antes del slot
        // siguiente (distancia minima entre nodos).
        LimiteFin := AplicarDistancia(E);
        if LimiteFin <= AOcc[I].StartDT then
          Exit(S);  // cabe el nodo + distancia en este hueco valido

        // No cabe entero pero el hueco es valido: en modo shift colocamos aqui
        // y empujamos lo posterior (solo si el slot siguiente no esta bloqueado).
        if (APolicy = ppHuecoShift) and (not AOcc[I].Bloqueado) then
        begin
          ANeedsShift := True;
          Exit(S);
        end;
      end;
    end;
    // Hueco no valido / no cabe: avanzar el cursor tras este slot + distancia.
    if AOcc[I].EndDT > Cursor then
      Cursor := AplicarDistancia(AOcc[I].EndDT);
  end;

  // Sin hueco util: tras el ultimo slot (== al final de la cola).
  Result := CalNext(ACal, Cursor);
end;

// Busca el lane con la cola mas temprana (Forward) o el inicio mas tardio
// (Backward), para repartir la carga entre lanes paralelos.
function PickLane(const Cursor: TCenterCursor; Forward: Boolean): Integer;
var
  I: Integer;
  Best, V: TDateTime;
begin
  Result := 0;
  if Length(Cursor.LaneOcc) = 0 then Exit;
  if Forward then Best := LaneEnd(Cursor.LaneOcc[0])
  else Best := LaneStart(Cursor.LaneOcc[0]);
  for I := 1 to High(Cursor.LaneOcc) do
  begin
    if Forward then
    begin
      V := LaneEnd(Cursor.LaneOcc[I]);
      if V < Best then begin Best := V; Result := I; end;
    end
    else
    begin
      V := LaneStart(Cursor.LaneOcc[I]);
      if V > Best then begin Best := V; Result := I; end;
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

// Inicio mas temprano de un slot que aun solapa [AStart,AEnd) (para Backward).
function EarliestCollidingStart(AOcc: TLaneOcc; const AStart, AEnd: TDateTime): TDateTime;
var
  I: Integer;
begin
  Result := AEnd;
  for I := 0 to AOcc.Count - 1 do
    if (AEnd > AOcc[I].StartDT) and (AStart < AOcc[I].EndDT) then
      if AOcc[I].StartDT < Result then
        Result := AOcc[I].StartDT;
end;

// Carga los nodos existentes del centro (FS_PL_Node del proyecto activo) como
// ocupacion en los lanes. Reparte por lanes con first-fit para no superponer.
// Marca como Bloqueado los que terminan antes de AFechaBloqueo.
procedure LoadExistingOccupancy(ACenterId: Integer; const AFechaBloqueo: TDateTime;
  var ACursor: TCenterCursor);
var
  Q: TADOQuery;
  Slot: TLaneSlot;
  L, Placed: Integer;
begin
  if DMPlanner.ADOConnection = nil then Exit;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT FechaInicio, FechaFin FROM FS_PL_Node ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID AND CenterId = :CID ' +
      '  AND ISNULL(Visible,1) = 1 ' +
      'ORDER BY FechaInicio';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := DMPlanner.CurrentProjectId;
    Q.Parameters.ParamByName('CID').Value := ACenterId;
    Q.Open;
    while not Q.Eof do
    begin
      Slot.StartDT := Q.FieldByName('FechaInicio').AsDateTime;
      Slot.EndDT := Q.FieldByName('FechaFin').AsDateTime;
      Slot.Bloqueado := (AFechaBloqueo > 0) and (Slot.EndDT <= AFechaBloqueo);
      // first-fit: primer lane donde no choque
      Placed := -1;
      for L := 0 to High(ACursor.LaneOcc) do
        if not LaneCollides(ACursor.LaneOcc[L], Slot.StartDT, Slot.EndDT) then
        begin
          Placed := L;
          Break;
        end;
      if Placed < 0 then Placed := 0;  // todos chocan: apilar en lane 0
      InsertSlotOrdered(ACursor.LaneOcc[Placed], Slot);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
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
  SinCalendario: Boolean;
  NeedsShift: Boolean;
  NewSlot: TLaneSlot;
  FechaBloqueo: TDateTime;
  J, DurSlotMin: Integer;
  ShiftTo: TDateTime;

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

  // Defaults defensivos de los umbrales de hueco (por si el caller no los puso).
  if Params.HuecoMinimoMin <= 0 then Params.HuecoMinimoMin := 30;
  if (Params.PorcentajeMinNodo < 0) or (Params.PorcentajeMinNodo > 100) then
    Params.PorcentajeMinNodo := 50;
  if Params.DistanciaMinNodos < 0 then Params.DistanciaMinNodos := 0;

  if DMPlanner.CurrentProjectTieneBloqueo then
    FechaBloqueo := DMPlanner.CurrentProjectFechaBloqueo
  else
    FechaBloqueo := 0;

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

      // Resolucion de centro con fallback al centro de sistema "SIN CENTRO":
      // toda carga sin centro valido aterriza alli (en vez de quedarse fuera del
      // plan), y el planificador la arrastra manualmente al centro real.
      if Trim(Input.CentroPreferente) = '' then
        Key := UpperCase(CENTRO_SIN_CENTRO)
      else
        Key := UpperCase(Trim(Input.CentroPreferente));

      if not CentresMap.TryGetValue(Key, C) then
      begin
        // El centro indicado no existe -> probar el cajon de sastre SIN CENTRO.
        if not CentresMap.TryGetValue(UpperCase(CENTRO_SIN_CENTRO), C) then
        begin
          // Ni siquiera existe SIN CENTRO (BD sin V065): no se puede planificar.
          Output.Status := ssSinCentro;
          Output.Observaciones := 'Sin centro (falta centro de sistema SIN CENTRO)';
          OutList.Add(Output);
          Inc(Result.TotalNoPlanificados);
          Continue;
        end;
        if Trim(Input.CentroPreferente) <> '' then
          Output.Observaciones := 'Centro ' + Input.CentroPreferente +
            ' no existe; asignado a Sin centro';
      end;

      // Inicializar cursor del centro si es la primera vez. Carga la ocupacion
      // de los nodos YA EXISTENTES en el centro para no superponerse a ellos.
      if not Cursors.TryGetValue(C.Id, Cursor) then
      begin
        Cursor := Default(TCenterCursor);
        Cursor.CenterId := C.Id;
        Cursor.Code := C.CodiCentre;
        Cursor.Cal := DMPlanner.CentresRepo.GetCalendarFor(C.Id);
        Cursor.IsSequencial := C.IsSequencial;
        Cursor.Lanes := GetLanes(C);
        SetLength(Cursor.LaneOcc, Cursor.Lanes);
        for J := 0 to Cursor.Lanes - 1 do
          Cursor.LaneOcc[J] := TLaneOcc.Create;
        // Registrar ANTES de cargar (las listas son por referencia): asi, si
        // LoadExistingOccupancy lanza, el finally igualmente liberara las listas.
        Cursors.Add(C.Id, Cursor);
        LoadExistingOccupancy(C.Id, FechaBloqueo, Cursor);
      end;

      Output.CenterId := C.Id;

      // Sin calendario ya no se descarta: se planifica como tiempo continuo
      // 24x7, encadenando los nodos uno detras de otro (respetando lanes).
      SinCalendario := Cursor.Cal = nil;

      // Duracion via cascada canonica (V054): tiempos reales de la operacion
      // con fallback a HorasEstimadas y default 60 min.
      DurMin := Round(CalcDuracionOpMin(Input));
      if DurMin <= 0 then
        DurMin := 60;
      Output.DuracionMin := DurMin;

      NeedsShift := False;
      case Params.Mode of
        smBackward:
          begin
            if Input.FechaCompromiso = 0 then
            begin
              // Fallback a Forward desde FechaBase, con la politica elegida.
              Lane := PickLane(Cursor, True);
              StartDT := PlaceForward(Cursor.LaneOcc[Lane], Cursor.Cal,
                Params.FechaBase, DurMin, Params.Placement,
                Params.HuecoMinimoMin, Params.PorcentajeMinNodo,
                Params.DistanciaMinNodos, NeedsShift);
              EndDT := CalAdd(Cursor.Cal, StartDT, DurMin);
              Output.FechaInicio := StartDT;
              Output.FechaFin := EndDT;
              Output.Status := ssFueraPlazo;
              Output.Observaciones := 'Sin FechaCompromiso; planificado forward';
              Inc(Result.TotalFueraPlazo);
            end
            else
            begin
              // Backward: terminar lo mas tarde posible <= FechaCompromiso, sin
              // pisar lo ya ocupado. Partimos del compromiso y retrocedemos
              // mientras choque con algun slot del lane.
              Lane := PickLane(Cursor, False);
              EndDT := CalPrev(Cursor.Cal, Input.FechaCompromiso);
              StartDT := CalSub(Cursor.Cal, EndDT, DurMin);
              while LaneCollides(Cursor.LaneOcc[Lane], StartDT, EndDT) do
              begin
                // retroceder detras del slot que choca (el de inicio mas
                // temprano que aun solapa): situamos el fin en su inicio.
                EndDT := CalPrev(Cursor.Cal,
                  EarliestCollidingStart(Cursor.LaneOcc[Lane], StartDT, EndDT));
                StartDT := CalSub(Cursor.Cal, EndDT, DurMin);
                if StartDT < Params.FechaBase then Break;
              end;

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
            StartDT := PlaceForward(Cursor.LaneOcc[Lane], Cursor.Cal,
              Params.FechaBase, DurMin, Params.Placement,
              Params.HuecoMinimoMin, Params.PorcentajeMinNodo,
              Params.DistanciaMinNodos, NeedsShift);
            EndDT := CalAdd(Cursor.Cal, StartDT, DurMin);

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

      // Registrar el nuevo nodo como ocupacion para que los siguientes de esta
      // tanda no lo pisen.
      if (Output.Status <> ssSaturado) and (Lane >= 0) and (Lane <= High(Cursor.LaneOcc)) then
      begin
        NewSlot.StartDT := StartDT;
        NewSlot.EndDT := EndDT;
        NewSlot.Bloqueado := False;
        InsertSlotOrdered(Cursor.LaneOcc[Lane], NewSlot);

        // Shift (solo politica ppHuecoShift): tras insertar el nuevo nodo,
        // empujar en cascada los slots posteriores que solapen, en orden por
        // inicio. ShiftTo arranca en el fin del nuevo nodo y va avanzando.
        // Un slot bloqueado no se puede mover: si solapa, NO se toca (queda el
        // solapamiento, pero respetamos lo consolidado) y el cursor salta tras el.
        if NeedsShift then
        begin
          ShiftTo := EndDT;
          for J := 0 to Cursor.LaneOcc[Lane].Count - 1 do
          begin
            NewSlot := Cursor.LaneOcc[Lane][J];
            // Saltar los slots que terminan antes del cursor de shift (no
            // solapan) y el propio nodo recien insertado.
            if NewSlot.EndDT <= ShiftTo then Continue;
            if NewSlot.StartDT >= ShiftTo then
            begin
              // Ya empieza despues del cursor: no hay solapamiento que resolver,
              // y como la lista esta ordenada, los siguientes tampoco. Fin.
              Break;
            end;
            if NewSlot.Bloqueado then
            begin
              // No se puede empujar (carga consolidada): respetamos su posicion,
              // avisamos del solapamiento y avanzamos tras el.
              if Output.Observaciones <> '' then
                Output.Observaciones := Output.Observaciones + '. ';
              Output.Observaciones := Output.Observaciones +
                'Shift topo con nodo bloqueado (posible solape)';
              ShiftTo := NewSlot.EndDT;
              Continue;
            end;
            // Empujar este slot detras del cursor (+ distancia minima entre
            // nodos), conservando su duracion.
            DurSlotMin := Round((NewSlot.EndDT - NewSlot.StartDT) * 24 * 60);
            if Params.DistanciaMinNodos > 0 then
              NewSlot.StartDT := CalNext(Cursor.Cal,
                CalAdd(Cursor.Cal, ShiftTo, Params.DistanciaMinNodos))
            else
              NewSlot.StartDT := CalNext(Cursor.Cal, ShiftTo);
            NewSlot.EndDT := CalAdd(Cursor.Cal, NewSlot.StartDT, DurSlotMin);
            Cursor.LaneOcc[Lane][J] := NewSlot;
            ShiftTo := NewSlot.EndDT;
          end;

          // Tras los empujes la lista puede haber quedado desordenada: re-ordenar.
          Cursor.LaneOcc[Lane].Sort(TComparer<TLaneSlot>.Construct(
            function(const A, B: TLaneSlot): Integer
            begin
              Result := CompareDateTime(A.StartDT, B.StartDT);
            end));
        end;
      end;

      // Avisar en el preview de que se ha planificado sin calendario (24x7).
      if SinCalendario then
      begin
        if Output.Observaciones <> '' then
          Output.Observaciones := Output.Observaciones + '. ';
        Output.Observaciones := Output.Observaciones +
          'Centro sin calendario: planificado en continuo (24x7)';
      end;

      // Guardar el cursor actualizado
      Cursors.AddOrSetValue(C.Id, Cursor);

      OutList.Add(Output);
    end;

    Result.Items := OutList.ToArray;
  finally
    // Liberar las listas de ocupacion de cada cursor.
    for Cursor in Cursors.Values do
      for J := 0 to High(Cursor.LaneOcc) do
        Cursor.LaneOcc[J].Free;
    CentresMap.Free;
    Cursors.Free;
    OutList.Free;
  end;
end;

end.
