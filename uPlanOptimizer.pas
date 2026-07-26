unit uPlanOptimizer;

{
  Optimizador de planificacion NATIVO (sin dependencias externas / OR-Tools).

  Primera aproximacion "PRO" a la optimizacion real (RCPSP/JSSP): en vez de fijar
  el orden con una dispatching rule, BUSCA un orden mejor con una metaheuristica.

  Motor: Simulated Annealing (SA).
    - Solucion = una permutacion de la cola de operaciones (TArray<TSchedInput>).
    - Evaluacion = se planifica esa cola con RunAutoScheduling (soPreordenado, que
      respeta el orden dado) y se miden los KPIs con ComputeKpis. Reutiliza el
      motor existente -> el resultado es directamente comparable con las reglas.
    - Vecindario = swap de dos operaciones o mover una a otra posicion.
    - Objetivo = combinado: w_tard * tardiness_norm + w_mk * makespan_norm (0..1).
    - Acepta empeoramientos con probabilidad exp(-delta/T) para escapar de optimos
      locales; T baja geometricamente (enfriamiento).

  Determinista: usa un PRNG propio con semilla fija (no System.Random global), asi
  el mismo input da el mismo resultado (reproducible para el usuario).

  Presupuesto: limitado por numero de iteraciones Y por tiempo (ms), lo que llegue
  antes. Con 1194 OP cada evaluacion cuesta, asi que el tope de tiempo manda.

  Solo lectura: NO toca el plan; devuelve el mejor TSchedResult encontrado.
}

interface

uses
  System.SysUtils, System.Math, System.Diagnostics, System.Classes,
  System.DateUtils, System.Generics.Collections,
  System.Threading, System.SyncObjs,
  uBacklogScheduler, uPlanLog, uDMPlanner, uCentresRepo, uCentreCalendar,
  uGanttTypes, uUtillajeTypes;

type
  // Parametros del optimizador (con defaults razonables).
  TOptimizerParams = record
    MaxIteraciones: Integer;   // tope de iteraciones (def. 4000)
    MaxMillis: Integer;        // tope de tiempo en ms (def. 4000)
    TempInicial: Double;       // temperatura inicial SA (def. 1.0, objetivo 0..1)
    TempFinal: Double;         // temperatura final (def. 0.001)
    PesoTardiness: Double;     // peso del retraso en el objetivo (def. 0.7)
    PesoMakespan: Double;      // peso del makespan en el objetivo (def. 0.3)
    Semilla: Cardinal;         // semilla PRNG (def. 12345, reproducible)
    class function Default: TOptimizerParams; static;
  end;

  // Traza de progreso (para log/UI).
  TOptimizerProgress = record
    Iteraciones: Integer;      // suma de iteraciones de todas las cadenas
    Mejoras: Integer;          // veces que se mejoro (cadena ganadora)
    ObjInicial: Double;        // objetivo de la solucion de partida
    ObjFinal: Double;          // objetivo de la mejor solucion global
    MillisUsados: Integer;
    Hilos: Integer;            // cadenas SA lanzadas en paralelo
  end;

  TPlanOptimizer = class
  public
    // Optimiza a partir de AInicial (p.ej. la mejor dispatching rule) con
    // MULTI-START SA PARALELO: N cadenas SA independientes (una por hilo), cada
    // una con su semilla; se queda con la mejor. Cada cadena evalua con
    // RunAutoScheduling + cache de ocupacion (sin BD -> thread-safe).
    // ASchedParams se fuerza a Order=soPreordenado. NO toca el plan.
    function Optimizar(const AInicial: TArray<TSchedInput>;
      const ASchedParams: TSchedParams; const AOptParams: TOptimizerParams;
      out AProgress: TOptimizerProgress): TSchedResult;
  end;

implementation

{ TOptimizerParams }

class function TOptimizerParams.Default: TOptimizerParams;
begin
  // Cada iteracion re-planifica toda la cola (RunAutoScheduling), que con muchos
  // miles de OP cuesta cientos de ms. El tope de TIEMPO manda (no el de iters):
  // 20 s permite suficientes iteraciones para una primera aproximacion honesta.
  // Subir MaxMillis (o bajar el volumen) da mejores resultados.
  Result.MaxIteraciones := 100000;   // tope alto: en la practica corta el tiempo
  Result.MaxMillis      := 20000;    // 20 s
  Result.TempInicial    := 1.0;
  Result.TempFinal      := 0.001;
  Result.PesoTardiness  := 0.7;
  Result.PesoMakespan   := 0.3;
  Result.Semilla        := 12345;
end;

{ Contexto compartido (solo LECTURA) entre las cadenas SA paralelas. }
type
  TOptContext = record
    SchedParams: TSchedParams;
    OptParams: TOptimizerParams;
    Base: TArray<TSchedInput>;   // orden de partida (mejor regla)
    OccCache: TOccupancyCache;   // ocupacion existente precargada (sin BD)
    MaqCache: TMaquinasCache;    // maquinas por centro, precargadas (V083)
    TardRef, MkRef: Double;      // referencias de normalizacion
    // PLANTILLA de la ocupacion de utillajes (estado inicial, antes de esta
    // tanda). NO se usa directamente: cada evaluacion trabaja sobre un Clone.
    // Ver EvaluarCtx. nil = optimizar sin restriccion de utillaje.
    UtillajeBase: TUtillajeOccupancy;
  end;

  // Resultado de UNA cadena SA.
  TChainResult = record
    Orden: TArray<TSchedInput>;
    Obj: Double;
    Iteraciones: Integer;
    Mejoras: Integer;
  end;

{ Funciones libres SIN estado global: cada cadena lleva su propio Rng por parametro
  (por referencia), de modo que N cadenas corren en paralelo sin compartir nada
  mutable. }

// PRNG xorshift64* determinista (estado por referencia).
function RngNext(var S: UInt64): Double;
begin
  S := S xor (S shr 12);
  S := S xor (S shl 25);
  S := S xor (S shr 27);
  Result := (S * UInt64($2545F4914F6CDD1D) shr 11) / 9007199254740992.0;
end;

function RngInt(var S: UInt64; N: Integer): Integer;
begin
  if N <= 0 then Exit(0);
  Result := Trunc(RngNext(S) * N);
  if Result >= N then Result := N - 1;
end;

// Objetivo combinado normalizado (menor = mejor). Usa la cache de ocupacion ->
// NO toca BD -> seguro en cualquier hilo.
function EvaluarCtx(const ACtx: TOptContext; const AOrden: TArray<TSchedInput>;
  out AKpis: TSchedKpis): Double;
var
  Res: TSchedResult;
  TardN, MkN: Double;
  Params: TSchedParams;
  Occ: TUtillajeOccupancy;
begin
  Params := ACtx.SchedParams;   // copia local: no tocamos el contexto compartido

  // Utillajes: una copia LIMPIA por evaluacion, no por hilo.
  //
  // TUtillajeOccupancy se va ocupando conforme el motor coloca nodos, asi que
  // sirve para UNA pasada. Con una copia por hilo, la segunda iteracion de la
  // cadena encontraria el utillaje ya ocupado por la primera y la evaluacion
  // saldria peor de lo que es. Clonar aqui cuesta poco (dos diccionarios) y
  // deja cada evaluacion partiendo del MISMO estado inicial.
  //
  // Esto es lo que permite que el optimizador respete los utillajes. Antes se
  // ponia la restriccion a nil y el plan optimizado podia violarlos.
  Occ := nil;
  try
    if ACtx.UtillajeBase <> nil then
    begin
      Occ := ACtx.UtillajeBase.Clone;
      Params.UtillajeOcc := Occ;
    end;

    Res := RunAutoScheduling(AOrden, Params, ACtx.OccCache, ACtx.MaqCache);
  finally
    Occ.Free;
  end;

  AKpis := ComputeKpis(Res);
  if ACtx.TardRef > 0 then TardN := AKpis.RetrasoTotalH / ACtx.TardRef else TardN := 0;
  if ACtx.MkRef   > 0 then MkN   := AKpis.MakespanH / ACtx.MkRef       else MkN := 0;
  Result := ACtx.OptParams.PesoTardiness * TardN + ACtx.OptParams.PesoMakespan * MkN;
end;

// Vecino in-place: 50% swap, 50% mover (insercion). Rng por referencia.
procedure VecinoRng(var S: UInt64; var AOrden: TArray<TSchedInput>);
var
  N, I, J: Integer;
  Tmp: TSchedInput;
begin
  N := Length(AOrden);
  if N < 2 then Exit;
  I := RngInt(S, N);
  repeat J := RngInt(S, N) until J <> I;
  if RngNext(S) < 0.5 then
  begin
    Tmp := AOrden[I]; AOrden[I] := AOrden[J]; AOrden[J] := Tmp;
  end
  else
  begin
    Tmp := AOrden[I];
    if I < J then
      while I < J do begin AOrden[I] := AOrden[I + 1]; Inc(I); end
    else
      while I > J do begin AOrden[I] := AOrden[I - 1]; Dec(I); end;
    AOrden[J] := Tmp;
  end;
end;

// Una cadena SA completa, con su semilla. Sin estado compartido mutable ->
// se puede correr en un hilo. El presupuesto de tiempo es COMPARTIDO (mismo
// deadline para todas), asi todas paran a la vez.
function RunChain(const ACtx: TOptContext; ASeed: UInt64;
  const ASW: TStopwatch): TChainResult;
var
  S: UInt64;
  Actual, Cand: TArray<TSchedInput>;
  KActual, KCand: TSchedKpis;
  ObjActual, ObjCand, T, Delta: Double;
  MaxMs: Integer;
begin
  S := ASeed;
  if S = 0 then S := 1;
  MaxMs := ACtx.OptParams.MaxMillis;
  Result.Orden := nil; Result.Obj := 1e18; Result.Iteraciones := 0; Result.Mejoras := 0;

  Actual := Copy(ACtx.Base, 0, Length(ACtx.Base));
  ObjActual := EvaluarCtx(ACtx, Actual, KActual);

  Result.Orden := Copy(Actual, 0, Length(Actual));
  Result.Obj := ObjActual;
  Result.Iteraciones := 0;
  Result.Mejoras := 0;
  T := ACtx.OptParams.TempInicial;

  while (Result.Iteraciones < ACtx.OptParams.MaxIteraciones) and
        (ASW.ElapsedMilliseconds < MaxMs) do
  begin
    Cand := Copy(Actual, 0, Length(Actual));
    VecinoRng(S, Cand);
    ObjCand := EvaluarCtx(ACtx, Cand, KCand);
    Delta := ObjCand - ObjActual;

    if (Delta < 0) or ((T > 1e-9) and (RngNext(S) < Exp(-Delta / T))) then
    begin
      Actual := Cand; ObjActual := ObjCand;
      if ObjActual < Result.Obj then
      begin
        Result.Orden := Copy(Actual, 0, Length(Actual));
        Result.Obj := ObjActual;
        Inc(Result.Mejoras);
      end;
    end;

    if MaxMs > 0 then
      T := ACtx.OptParams.TempInicial *
           Power(ACtx.OptParams.TempFinal / ACtx.OptParams.TempInicial,
                 ASW.ElapsedMilliseconds / MaxMs);
    Inc(Result.Iteraciones);
  end;
end;

// Pre-calienta las caches de todos los calendarios de centro para [ADesde..AHasta]
// EN EL HILO PRINCIPAL, para que luego los hilos solo lean. Cada calendario se
// calienta una sola vez (varios centros pueden compartir el mismo objeto).
procedure WarmupCalendarios(const ADesde, AHasta: TDateTime);
var
  Centres: TArray<TCentreTreball>;
  C: TCentreTreball;
  Cal: TCentreCalendar;
  Hechos: TList<TCentreCalendar>;
  D0, D1: TDateTime;
begin
  if DMPlanner.CentresRepo = nil then Exit;
  // Rango efectivo: si el plan no dio fechas, un margen amplio desde hoy.
  if ADesde > 0 then D0 := ADesde else D0 := Now;
  if AHasta > ADesde then D1 := AHasta else D1 := IncMonth(D0, 12);

  Hechos := TList<TCentreCalendar>.Create;
  try
    Centres := DMPlanner.CentresRepo.GetAll;
    for C in Centres do
    begin
      Cal := DMPlanner.CentresRepo.GetCalendarFor(C.Id);
      if (Cal <> nil) and (Hechos.IndexOf(Cal) < 0) then
      begin
        Cal.WarmupCache(D0, D1);
        Hechos.Add(Cal);
      end;
    end;
    PlanLog.Linea('OPTIM: warmup de %d calendarios para [%s .. %s]',
      [Hechos.Count, FormatDateTime('dd/mm/yyyy', D0), FormatDateTime('dd/mm/yyyy', D1)]);
  finally
    Hechos.Free;
  end;
end;

{ TPlanOptimizer }

function TPlanOptimizer.Optimizar(const AInicial: TArray<TSchedInput>;
  const ASchedParams: TSchedParams; const AOptParams: TOptimizerParams;
  out AProgress: TOptimizerProgress): TSchedResult;
var
  Ctx: TOptContext;
  KIni: TSchedKpis;
  NHilos, I, IdxMejor: Integer;
  Chains: TArray<TChainResult>;
  Tasks: TArray<ITask>;
  SW: TStopwatch;
  FechaBloqueo: TDateTime;
  ParamsFinal: TSchedParams;         // params de la replanificacion final
  OccFinal: TUtillajeOccupancy;      // su copia limpia de utillajes

  // Crea la tarea de la cadena AIdx. AIdx es POR VALOR -> cada tarea captura su
  // propio indice (evita el bug de captura del for). Ctx/Chains/SW se capturan del
  // entorno (compartidos: Ctx solo-lectura, Chains[AIdx] exclusivo por tarea).
  function CrearTarea(AIdx: Integer): ITask;
  begin
    Result := TTask.Run(
      procedure
      begin
        try
          Chains[AIdx] := RunChain(Ctx,
            AOptParams.Semilla + UInt64(AIdx) * UInt64(2654435761), SW);
        except
          on E: Exception do
            PlanLog.Linea('OPTIM: hilo %d EXCEPCION: %s', [AIdx, E.Message]);
        end;
      end);
  end;

begin
  AProgress := Default(TOptimizerProgress);

  Ctx.SchedParams := ASchedParams;
  Ctx.SchedParams.Order := soPreordenado;   // respetar el orden que damos

  // Utillajes: el objeto que llega NO se puede compartir entre los hilos SA
  // (tiene estado y no es thread-safe). Se guarda como PLANTILLA y se anula en
  // los params compartidos; cada evaluacion se hace un Clone limpio a partir de
  // ella (ver EvaluarCtx). Asi el optimizador SI respeta la restriccion, que
  // antes se perdia: se ponia a nil y el plan optimizado podia violar utillajes.
  Ctx.UtillajeBase := ASchedParams.UtillajeOcc;
  Ctx.SchedParams.UtillajeOcc := nil;
  Ctx.OptParams := AOptParams;
  Ctx.Base := AInicial;

  // Precargar la ocupacion existente UNA vez (en el hilo principal, con BD). A
  // partir de aqui las cadenas evaluan sin tocar BD -> seguras en paralelo.
  FechaBloqueo := 0;   // la comparativa no aplica bloqueo (preview)
  Ctx.OccCache := BuildOccupancyCache(FechaBloqueo);
  // Maquinas por centro: igual que la ocupacion, se lee UNA vez en el hilo
  // principal para que las cadenas SA no toquen BD.
  Ctx.MaqCache := BuildMaquinasCache;
  try
    // Referencias de normalizacion desde la solucion inicial (usando ya la cache).
    KIni := ComputeKpis(RunAutoScheduling(AInicial, Ctx.SchedParams, Ctx.OccCache, Ctx.MaqCache));
    Ctx.TardRef := Max(1.0, KIni.RetrasoTotalH);
    Ctx.MkRef   := Max(1.0, KIni.MakespanH);
    AProgress.ObjInicial :=
      AOptParams.PesoTardiness * 1.0 + AOptParams.PesoMakespan * 1.0;  // inicial ~= 1

    // PRE-CALENTAR las caches de TODOS los calendarios para el rango del plan,
    // EN EL HILO PRINCIPAL. Sin esto, NextWorkingTime/AddWorkingMinutes llenan
    // FMergedAroundCache de forma lazy, y 8 hilos escribiendo el mismo diccionario
    // -> corrupcion -> los TTask mueren en silencio (era el bug: 7 de 8 cadenas
    // con iter=0). Tras el warmup solo hay LECTURAS -> thread-safe.
    WarmupCalendarios(KIni.FechaMin, KIni.FechaMax);

    // Numero de cadenas = nucleos disponibles (min 1). Cada una con su semilla.
    NHilos := TThread.ProcessorCount;
    if NHilos < 1 then NHilos := 1;
    if NHilos > 16 then NHilos := 16;
    AProgress.Hilos := NHilos;

    SetLength(Chains, NHilos);
    SetLength(Tasks, NHilos);
    SW := TStopwatch.StartNew;

    // Lanzar N cadenas SA en paralelo (multi-start). La captura del indice se
    // hace via CrearTarea (funcion): el parametro AIdx es POR VALOR, garantizando
    // que cada tarea escriba en SU Chains[AIdx]. (Un 'var Idx := I' inline dentro
    // del for NO capturaba bien: todas las closures compartian el ultimo I -> todas
    // escribian en Chains[7] y 0..6 quedaban vacias.)
    for I := 0 to NHilos - 1 do
      Tasks[I] := CrearTarea(I);
    TTask.WaitForAll(Tasks);
    SW.Stop;

    // Quedarse con la mejor cadena.
    IdxMejor := 0;
    for I := 1 to NHilos - 1 do
      if Chains[I].Obj < Chains[IdxMejor].Obj then IdxMejor := I;

    AProgress.ObjFinal := Chains[IdxMejor].Obj;
    AProgress.Mejoras := Chains[IdxMejor].Mejoras;
    AProgress.MillisUsados := Integer(SW.ElapsedMilliseconds);
    for I := 0 to NHilos - 1 do
      Inc(AProgress.Iteraciones, Chains[I].Iteraciones);

    // Resultado final = planificar la mejor permutacion encontrada. Con su
    // propia copia de utillajes: es el plan que se devuelve y tiene que salir
    // con la restriccion aplicada, igual que las evaluaciones.
    ParamsFinal := Ctx.SchedParams;
    OccFinal := nil;
    try
      if Ctx.UtillajeBase <> nil then
      begin
        OccFinal := Ctx.UtillajeBase.Clone;
        ParamsFinal.UtillajeOcc := OccFinal;
      end;
      Result := RunAutoScheduling(Chains[IdxMejor].Orden, ParamsFinal, Ctx.OccCache, Ctx.MaqCache);
    finally
      OccFinal.Free;
    end;
  finally
    Ctx.OccCache.Free;
    Ctx.MaqCache.Free;
  end;
end;

end.
