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
  uGanttTypes, uSetupRules, uUtillajeTypes;

type
  TSchedMode = (smForward, smBackward);
  // soPreordenado: la cola ya viene ordenada por el llamador (p.ej. el motor
  // de reglas de prioridad) y RunAutoScheduling NO debe reordenarla.
  TSchedOrder = (soFechaCompromiso, soPrioridad, soPreordenado);

  TSchedInput = record
    RawId: Int64;
    Origen: string;
    // Etiqueta legible del documento ('DEMO-PRJ-002 / MECANIZAR'). Es para
    // MOSTRAR (caption del nodo, preview): no sirve como clave de nada.
    CodigoDocumento: string;
    // Codigo de operacion pelado ('MECANIZAR'). Esta es la clave real: es lo
    // que se graba en NodeData.Operacion y contra lo que casan las reglas de
    // utillaje (FS_PL_V_NodeUtillaje) y las de setup.
    CodigoOP: string;
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
    // Atributos para el tiempo de cambio secuencia-dependiente (uSetupRules).
    // El caller (p.ej. BuildInputFromRow) los rellena desde builtin+CustomFields
    // del nodo: Color, Substrato, AnchoBobina, Molde... Vacio = sin setup rules.
    SetupAttrs: TSetupAttrList;
    // Utillajes que exige esta operacion (recurso secundario). Los rellena el
    // caller ANTES de planificar resolviendo las reglas del maestro sobre
    // (operacion, articulo): aqui dentro no se puede tocar BD porque el
    // optimizador corre esto en varios hilos. Vacio = sin restriccion.
    UtillajeReqs: TArray<TUtillajeRequisito>;

    // --- Precedencias de ruta -----------------------------------------------
    // Secuencia de la operacion dentro de su OT (1, 2, 3...), tal como la trae
    // el ERP. Es lo que define la RUTA, y por tanto la unica base fiable para
    // encadenar precedencias.
    //
    // OJO: NO se puede usar el orden del array para esto. Cuando llega aqui, la
    // cola ya ha pasado por SortInputsByRuleSet (EDD, SPT, CriticalRatio...),
    // que la ha reordenado por criterios de prioridad y ha destruido el orden de
    // ruta. Encadenar por posicion daria OP30 -> OP20 -> OP10 en cuanto los
    // RawId no fueran monotonos con la ruta.
    Orden: Integer;
    // RawIds de las operaciones que tienen que estar TERMINADAS antes de que
    // esta pueda empezar. Normalmente es la operacion anterior de la misma OT
    // (OP10 -> OP20 -> OP30), pero el modelo admite varias.
    //
    // Lo rellena el caller (ver BuildPrecedencesFromInputs): aqui dentro no se
    // puede tocar BD porque el optimizador ejecuta esto en varios hilos.
    // Vacio = la operacion no espera a nadie.
    PredecesorasRawIds: TArray<Int64>;
    // % de la predecesora que tiene que estar hecho para poder empezar (0..100).
    // MISMO criterio que FS_PL_Dependency.PorcentajeDependencia en el Gantt:
    //   100 = FS estricto, empieza cuando la anterior acaba (el caso normal)
    //    60 = puede empezar cuando la anterior lleva un 60% hecho
    //     0 = puede empezar a la vez que la anterior (equivale a SS)
    // 0 tambien es el valor "sin definir" del record: se trata como 100 (ver
    // MinInicioPorPrecedencia), que es el comportamiento seguro.
    PorcentajeSolape: Double;
  end;

  TSchedStatus = (ssOK, ssSaturado, ssFueraPlazo, ssSinCentro, ssSinCalendario,
                  ssSinUtillaje);

  TSchedOutput = record
    Input: TSchedInput;
    CenterId: Integer;
    CenterCode: string;
    // Maquina DENTRO del centro donde se ha colocado (V083). 0 = no se ha
    // podido determinar (BD sin migrar): el nodo se guarda solo con su centro,
    // igual que antes.
    MaquinaId: Integer;
    MaquinaCodigo: string;
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

  // Granularidad del resultado: como se agrupan las OP planificadas en nodos.
  //   agNinguna   1 nodo por OP (comportamiento clasico, sin agrupar).
  //   agPorCentro Agrupa en un lote las OP que caen en el MISMO centro
  //               (-> tantos nodos-lote como centros implicados).
  //   agTodo      Agrupa TODAS las OP en un solo nodo-lote. Si caen en varios
  //               centros, se usa CentroDestinoAgrupado (lo elige el usuario en
  //               el wizard) para reubicarlas antes de agrupar.
  // La agrupacion es POST-scheduling: primero se planifica 1 nodo por OP y luego
  // se fusionan via el motor de Lotes (V057). No la consume RunAutoScheduling.
  TSchedAgrupacion = (agNinguna, agPorCentro, agTodo);

  TSchedParams = record
    Mode: TSchedMode;
    Order: TSchedOrder;
    FechaBase: TDateTime;     // usada en Forward o como fallback en Backward
    Placement: TPlacementPolicy;
    HuecoMinimoMin: Integer;     // hueco minimo en minutos (def. 30)
    PorcentajeMinNodo: Integer;  // % minimo del nodo (def. 50)
    DistanciaMinNodos: Integer;  // separacion minima entre nodos consecutivos
                                 // en el mismo lane, en minutos (def. 0)
    // --- Agrupacion (wizard, post-scheduling) ------------------------------
    Agrupacion: TSchedAgrupacion;   // por defecto agNinguna (sin agrupar)
    CentroDestinoAgrupado: string;  // solo para agTodo multi-centro: codigo del
                                    // centro destino elegido por el usuario.
    // --- Tiempo de cambio secuencia-dependiente (uSetupRules) --------------
    // Si <> nil, entre dos nodos consecutivos del mismo lane se deja el hueco
    // real calculado por el motor (segun en que difieran sus SetupAttrs), en
    // lugar de la DistanciaMinNodos fija. El caller es el propietario del engine
    // (no lo libera el scheduler). nil = comportamiento clasico.
    SetupEngine: TSetupRuleEngine;
    // --- Utillajes como restriccion dura (recurso secundario) --------------
    // Si <> nil, un nodo no se coloca donde alguno de sus UtillajeReqs ya este
    // ocupado por encima de su Cantidad: se retrasa hasta que quede libre. El
    // caller es el duenyo del objeto (no lo libera el scheduler).
    // nil = comportamiento clasico (los utillajes solo generan alerta R02).
    // OJO: es CROSS-CENTRO, a diferencia de la ocupacion por lanes.
    //
    // NO THREAD-SAFE. TUtillajeOccupancy tiene estado (se va ocupando segun
    // avanza la pasada), asi que UNA instancia sirve para UNA pasada de
    // RunAutoScheduling. El optimizador (uPlanOptimizer) copia TSchedParams a
    // todos sus hilos SA: si le llegase con UtillajeOcc <> nil, todos los hilos
    // compartirian el mismo objeto y se corromperia. Por eso el optimizador lo
    // pone a nil explicitamente y optimiza SIN esta restriccion (ver
    // uPlanOptimizer). Consecuencia asumida: el plan optimizado puede violar
    // utillajes y la alerta R02 lo cantara. Pendiente: dar a cada hilo su
    // propia copia.
    UtillajeOcc: TUtillajeOccupancy;

    // --- Precedencias de ruta como RESTRICCION DURA -------------------------
    // True = una operacion no se coloca antes de que acaben sus predecesoras
    // (TSchedInput.PredecesorasRawIds); si el hueco encontrado es demasiado
    // pronto, se retrasa hasta que la ruta lo permita.
    //
    // False = comportamiento clasico: cada operacion se coloca donde quepa y la
    // violacion de la ruta solo se detecta DESPUES, con la alerta D01. Se
    // mantiene como opcion porque hay planes existentes hechos asi, pero para
    // una OF multi-operacion lo correcto es True.
    //
    // Requiere que la cola llegue en orden topologico (las predecesoras antes
    // que sus sucesoras). SortInputsByRuleSet lo garantiza cuando esto es True.
    RespetarPrecedencias: Boolean;
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
    FechaMin: TDateTime;      // inicio mas temprano de la tanda (0 si nada)
    FechaMax: TDateTime;      // fin mas tardio de la tanda (0 si nada)
    // Tiempo de PREPARACION acumulado del plan: la suma de los cambios entre
    // trabajos consecutivos de cada linea (ver uSetupRules). Es tiempo de
    // maquina parada, y en una planta de series largas suele ser el coste que
    // mas pesa, asi que se mide aparte del makespan aunque forme parte de el.
    //
    // 0 cuando no hay reglas de cambio definidas: no significa "no hay
    // cambios", significa "nadie ha dicho cuanto cuestan".
    SetupTotalMin: Double;
    SetupCambios: Integer;    // cuantos cambios de preparacion hay en el plan
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

  // Intervalo ocupado en un lane (existente o planificado). Publico para poder
  // CACHEAR la ocupacion existente y reutilizarla sin tocar BD (ver TOccupancyCache).
  TLaneSlotPub = record
    StartDT: TDateTime;
    EndDT: TDateTime;
    Bloqueado: Boolean;
  end;

  // Ocupacion existente por CenterId, precargada UNA vez desde BD. Permite:
  //   1) evitar N queries repetidas en optimizacion (cada evaluacion la reusa),
  //   2) ejecutar RunAutoScheduling en THREADS (sin tocar la conexion ADO, que
  //      no es thread-safe) -> multi-start SA paralelo.
  TOccupancyCache = TDictionary<Integer, TArray<TLaneSlotPub>>;

  // Una maquina planificable de un centro (V083). Publico para poder precargar
  // el mapa centro -> maquinas y no tocar BD dentro del motor.
  TMaquinaPub = record
    MaquinaId: Integer;
    Codigo: string;
    EsSistema: Boolean;
  end;

  // Maquinas por CenterId, ya ordenadas como el motor las prueba (las reales
  // primero, la de sistema al final). Misma razon de existir que
  // TOccupancyCache: leer BD una vez y poder correr en threads.
  TMaquinasCache = TDictionary<Integer, TArray<TMaquinaPub>>;

function PriorityRuleToStr(R: TPriorityRule): string;
function DefaultRuleSet: TPriorityRuleSet;
// ASetupEngine es OPCIONAL: si se pasa, los KPIs incluyen ademas el tiempo de
// preparacion del plan. Se deja por defecto en nil para no obligar a tocar las
// llamadas que no lo necesitan.
function ComputeKpis(const AResult: TSchedResult;
  ASetupEngine: TSetupRuleEngine = nil): TSchedKpis;

// Tiempo de preparacion acumulado de un plan ya resuelto, en minutos.
//
// Se calcula A POSTERIORI recorriendo el resultado, en vez de acumularlo
// mientras se planifica: asi cualquier plan puede medirse (venga del motor
// automatico, de una regla o del optimizador) sin tocar el motor.
//
// Criterio: los trabajos se agrupan por CENTRO, se ordenan por fecha y se suma
// el cambio entre cada par consecutivo. Es exactamente lo que el usuario ve
// como huecos marcados entre barras de una misma linea del Gantt.
//
// Devuelve 0 si no hay motor de reglas o no hay ninguna regla activa: eso NO
// significa "este plan no tiene cambios", significa "nadie ha declarado cuanto
// cuestan", y quien lo presente debe distinguirlo.
function ComputeSetupKpi(const AResult: TSchedResult;
  ASetupEngine: TSetupRuleEngine; out ACambios: Integer): Double;

// Duracion de una OP en minutos. Replica de FS_PL_fn_DuracionOpMin (V054):
// unica fuente de verdad para "cuanto dura una operacion" antes de planificar.
function CalcDuracionOpMin(const AInput: TSchedInput): Double;

// Construye la cache de ocupacion existente leyendo BD UNA vez (llamar en el hilo
// principal). El llamante es dueno del diccionario y debe liberarlo.
function BuildOccupancyCache(const AFechaBloqueo: TDateTime): TOccupancyCache;

// Maquinas planificables de cada centro, leidas UNA vez desde BD (llamar en el
// hilo principal). Sale de la vista FS_PL_V_CentroMaquinaPlan (V083), con las
// maquinas reales primero y la de sistema al final. El llamante es dueno del
// diccionario y debe liberarlo.
function BuildMaquinasCache: TMaquinasCache;

// --- Precedencias de ruta ---------------------------------------------------

// Rellena PredecesorasRawIds de cada input encadenando las operaciones de una
// misma OT: cada OP espera a la anterior. El criterio de "anterior" es el orden
// de la operacion dentro de su OT, que es como viene la ruta del ERP.
//
// Agrupa por (NumeroOF, SerieOF, NumeroTrabajo): NumeroTrabajo identifica la OT
// dentro de la OF. Las operaciones sueltas (sin OT) no se encadenan entre si.
//
// ASolapePct se aplica a todas las cadenas por igual, con el criterio del Gantt:
// 100 = FS estricto (default), 60 = empieza con la anterior al 60%. Si en el
// futuro el solape viene por operacion desde el ERP, este parametro sobra.
//
// NO toca BD: trabaja sobre lo que ya hay en los inputs.
procedure BuildPrecedencesFromInputs(var AInputs: TArray<TSchedInput>;
  const ASolapePct: Double = 100);

// Reordena la cola en orden TOPOLOGICO respetando el orden previo dentro de lo
// posible: una operacion nunca aparece antes que sus predecesoras. Necesario
// porque el motor coloca en una sola pasada y consulta el fin de las
// predecesoras ya colocadas.
//
// Si hay un ciclo (ruta mal definida en el ERP), las operaciones implicadas se
// devuelven al final SIN encadenar, para no perderlas ni colgar el motor.
// Devuelve False si ha detectado algun ciclo.
function TopologicalSortInputs(var AInputs: TArray<TSchedInput>): Boolean;

// AOccCache opcional: si <> nil, la ocupacion existente se toma de la cache (sin
// BD, thread-safe). Si nil, comportamiento clasico (lee BD via LoadExistingOccupancy).
function RunAutoScheduling(const AInputs: TArray<TSchedInput>;
  const AParams: TSchedParams; AOccCache: TOccupancyCache = nil;
  AMaqCache: TMaquinasCache = nil): TSchedResult;

function StatusToStr(AStatus: TSchedStatus): string;
function PlacementToStr(P: TPlacementPolicy): string;

// Codigos de los utillajes que exige un nodo, separados por coma. Lo usan el
// motor (mensaje de "sin utillaje libre") y el preview (columna Utillaje).
function UtillajeReqsToStr(const AReqs: TArray<TUtillajeRequisito>): string;

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

function ComputeSetupKpi(const AResult: TSchedResult;
  ASetupEngine: TSetupRuleEngine; out ACambios: Integer): Double;
var
  PorCentro: TObjectDictionary<string, TList<TSchedOutput>>;
  Lst: TList<TSchedOutput>;
  Par: TPair<string, TList<TSchedOutput>>;
  I: Integer;
  Min: Integer;
begin
  Result := 0;
  ACambios := 0;
  if (ASetupEngine = nil) or (not ASetupEngine.HasRules) then Exit;
  if Length(AResult.Items) = 0 then Exit;

  PorCentro := TObjectDictionary<string, TList<TSchedOutput>>.Create([doOwnsValues]);
  try
    for I := 0 to High(AResult.Items) do
    begin
      // Solo lo que ha quedado colocado: lo no planificado no genera cambios.
      if AResult.Items[I].FechaInicio = 0 then Continue;
      if AResult.Items[I].CenterCode = '' then Continue;

      if not PorCentro.TryGetValue(AResult.Items[I].CenterCode, Lst) then
      begin
        Lst := TList<TSchedOutput>.Create;
        PorCentro.Add(AResult.Items[I].CenterCode, Lst);
      end;
      Lst.Add(AResult.Items[I]);
    end;

    for Par in PorCentro do
    begin
      Lst := Par.Value;
      if Lst.Count < 2 then Continue;

      Lst.Sort(TComparer<TSchedOutput>.Construct(
        function(const A, B: TSchedOutput): Integer
        begin
          Result := CompareDateTime(A.FechaInicio, B.FechaInicio);
        end));

      for I := 1 to Lst.Count - 1 do
      begin
        Min := ASetupEngine.CalcSetupMin(
          Lst[I - 1].Input.SetupAttrs, Lst[I].Input.SetupAttrs, True, Par.Key);
        if Min > 0 then
        begin
          Result := Result + Min;
          Inc(ACambios);
        end;
      end;
    end;
  finally
    PorCentro.Free;
  end;
end;

function ComputeKpis(const AResult: TSchedResult;
  ASetupEngine: TSetupRuleEngine): TSchedKpis;
var
  I: Integer;
  Item: TSchedOutput;
  MinIni, MaxFin: TDateTime;
  TieneRango: Boolean;
  Cambios: Integer;
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
  begin
    Result.MakespanH := (MaxFin - MinIni) * 24.0;
    Result.FechaMin := MinIni;
    Result.FechaMax := MaxFin;
  end;

  // Tiempo de preparacion: solo si el llamante ha pasado el motor de reglas.
  if ASetupEngine <> nil then
  begin
    Result.SetupTotalMin := ComputeSetupKpi(AResult, ASetupEngine, Cambios);
    Result.SetupCambios := Cambios;
  end;
end;

function StatusToStr(AStatus: TSchedStatus): string;
begin
  case AStatus of
    ssOK:            Result := 'OK';
    ssSaturado:      Result := 'SATURADO';
    ssFueraPlazo:    Result := 'FUERA DE PLAZO';
    ssSinCentro:     Result := 'SIN CENTRO';
    ssSinCalendario: Result := 'SIN CALENDARIO';
    ssSinUtillaje:   Result := 'SIN UTILLAJE LIBRE';
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
    // Atributos del nodo colocado, para calcular el setup con el SIGUIENTE nodo
    // que caiga tras el en este lane (uSetupRules). Vacio en slots ya existentes
    // (carga consolidada) cuyos atributos no conocemos.
    SetupAttrs: TSetupAttrList;
  end;

  TLaneOcc = TList<TLaneSlot>;  // ordenada por StartDT ascendente

  // Una maquina del centro, con su capacidad propia.
  //
  // El recurso finito real es la MAQUINA, no el centro (V083). Cada maquina
  // aporta MaxLanes carriles: normalmente 1 (una maquina hace un trabajo a la
  // vez), pero un horno o un bano pueden procesar varias piezas simultaneas y
  // eso es justo lo que expresa MaxLanes DENTRO de la maquina.
  //
  // Un centro sin maquinas reales tiene igualmente la suya de sistema
  // (__SINMAQUINA__<centro>, V083), asi que el motor nunca se queda sin recurso
  // y no hace falta un caso especial.
  TMaquinaCursor = record
    MaquinaId: Integer;
    Codigo: string;
    EsSistema: Boolean;     // maquina por defecto del centro (fallback)
    // Ocupacion por carril DE ESTA MAQUINA. Length = capacidad simultanea.
    LaneOcc: TArray<TLaneOcc>;
  end;

  TCenterCursor = record
    CenterId: Integer;
    Code: string;
    Cal: TCentreCalendar;
    IsSequencial: Boolean;
    Lanes: Integer;         // capacidad POR MAQUINA (MaxLanes del centro)
    // Maquinas del centro, en el orden en que el motor las prueba: primero las
    // reales (por Orden y codigo), la de sistema SIEMPRE la ultima.
    Maquinas: TArray<TMaquinaCursor>;
  end;

// Carriles POR MAQUINA (V083): cuantos trabajos simultaneos admite CADA maquina
// del centro, no cuantos admite el centro entero.
//
// Antes de V083 los carriles eran del centro y MaxLanes decia "cuantas cosas a
// la vez caben aqui". Ahora el recurso es la maquina, y MaxLanes pasa a
// describir la capacidad interna de cada una: normalmente 1, pero un horno o un
// bano procesan varias piezas a la vez y eso es lo que expresa.
//
// Consecuencia: un centro con 3 maquinas y MaxLanes=2 tiene 6 huecos
// simultaneos (3 x 2), no 2.
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
// Ocupacion del carril ALane de la maquina AMaq. Centraliza el doble indice
// para que el resto del motor no tenga que recordar el orden.
function OccDe(const Cursor: TCenterCursor; AMaq, ALane: Integer): TLaneOcc;
begin
  Result := nil;
  if (AMaq < 0) or (AMaq > High(Cursor.Maquinas)) then Exit;
  if (ALane < 0) or (ALane > High(Cursor.Maquinas[AMaq].LaneOcc)) then Exit;
  Result := Cursor.Maquinas[AMaq].LaneOcc[ALane];
end;

// Elige MAQUINA y carril dentro del centro: el que queda libre antes (forward)
// o el que empieza mas tarde (backward).
//
// Recorre las maquinas en su orden, que ya viene con las reales primero y la de
// sistema al final (ver LoadMaquinasDeCentro). Como el criterio es "el que
// acaba antes", una maquina real vacia siempre gana a la de sistema, que es lo
// que se quiere: la de por defecto solo recoge lo que no cabe en las otras.
procedure PickMaquinaLane(const Cursor: TCenterCursor; Forward: Boolean;
  out AMaq, ALane: Integer);
var
  M, L: Integer;
  Best, V: TDateTime;
  Primero: Boolean;
begin
  AMaq := 0;
  ALane := 0;
  Best := 0;
  Primero := True;

  for M := 0 to High(Cursor.Maquinas) do
    for L := 0 to High(Cursor.Maquinas[M].LaneOcc) do
    begin
      if Forward then
        V := LaneEnd(Cursor.Maquinas[M].LaneOcc[L])
      else
        V := LaneStart(Cursor.Maquinas[M].LaneOcc[L]);

      if Primero then
      begin
        Best := V; AMaq := M; ALane := L; Primero := False;
      end
      else if (Forward and (V < Best)) or ((not Forward) and (V > Best)) then
      begin
        Best := V; AMaq := M; ALane := L;
      end;
    end;
end;

// Gap (minutos) que hay que dejar ANTES de colocar el nodo ACurr en este lane:
// el maximo entre la DistanciaMinNodos fija y el tiempo de cambio secuencia-
// dependiente respecto al ULTIMO nodo del lane (uSetupRules). Si no hay engine
// o el lane esta vacio, devuelve la distancia fija (comportamiento clasico).
//
// NOTA (fase 1): el setup se calcula contra el ultimo nodo de la cola, que es el
// caso dominante en Forward (nodos encadenados). La insercion en hueco intermedio
// usa el setup respecto al ultimo nodo, no respecto al vecino exacto del hueco;
// afinar eso queda para fase 2 (ver memoria project_gantt_setup_secuencia_dependiente).
function EffectiveGapMin(AOcc: TLaneOcc; const ACurr: TSchedInput;
  const ACentreCode: string; ADistFija: Integer;
  ASetupEngine: TSetupRuleEngine): Integer;
var
  PrevAttrs: TSetupAttrList;
  HasPrev: Boolean;
  SetupMin: Integer;
begin
  Result := ADistFija;
  if (ASetupEngine = nil) or not ASetupEngine.HasRules then Exit;

  HasPrev := AOcc.Count > 0;
  if HasPrev then
    PrevAttrs := AOcc[AOcc.Count - 1].SetupAttrs
  else
    SetLength(PrevAttrs, 0);

  SetupMin := ASetupEngine.CalcSetupMin(PrevAttrs, ACurr.SetupAttrs, HasPrev,
    ACentreCode);
  if SetupMin > Result then Result := SetupMin;
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

  // Tope de reintentos al buscar hueco de utillaje para un nodo. Cada vuelta
  // avanza en el tiempo (se salta al fin de un uso que se solapaba), asi que
  // el bucle termina siempre; esto solo evita que un caso patologico (muchos
  // nodos peleandose por un utillaje con Cantidad alta) se coma la pasada.
  MAX_UTIL_RETRIES = 200;

function UtillajeReqsToStr(const AReqs: TArray<TUtillajeRequisito>): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(AReqs) do
    if Result = '' then Result := AReqs[I].Codigo
    else Result := Result + ', ' + AReqs[I].Codigo;
end;

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
        // Sin fecha -> al final. Trabajo 0 -> CR "infinito" (no critico): detras.
        // NO usamos Infinity en aritmetica FP (con excepciones FPU activas,
        // Inf-Inf=NaN al comparar rompe el sort): tratamos el caso trabajo<=0
        // de forma explicita por logica de comparacion.
        if ResolveMissingDue(Resolved) then Exit(Resolved);
        if (A.FechaCompromiso = 0) and (B.FechaCompromiso = 0) then Exit(0);
        RemA := WorkHours(A);
        RemB := WorkHours(B);
        // Casos degenerados (trabajo 0): el de trabajo 0 es "menos critico" (CR
        // infinito) y va detras. Si ambos son 0, empatan aqui.
        if (RemA <= 0) and (RemB <= 0) then Exit(0);
        if RemA <= 0 then Exit(1);    // A no critico -> detras
        if RemB <= 0 then Exit(-1);   // B no critico -> A delante
        CrA := ((A.FechaCompromiso - AFechaBase) * 24.0) / RemA;
        CrB := ((B.FechaCompromiso - AFechaBase) * 24.0) / RemB;
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
// Coloca un slot ocupado en el cursor por first-fit (primer lane sin colision).
procedure PlaceExistingSlot(var ACursor: TCenterCursor; const ASlot: TLaneSlot);
var
  M, L: Integer;
  MaqPuesto, LanePuesto: Integer;
begin
  MaqPuesto := -1;
  LanePuesto := 0;

  // First-fit sobre (maquina, carril). Es carga YA planificada: aqui solo se
  // reconstruye donde estaba para no pisarla, no se decide nada.
  //
  // Nota: esto reparte por hueco, no por la maquina real del nodo. Se podria
  // afinar leyendo Node.MaquinaId (V083), pero para el motor lo unico que
  // importa es que el sitio quede ocupado; quien mande el reparto fino es el
  // Gantt en modo MAQUINAS, que si lee MaquinaId.
  for M := 0 to High(ACursor.Maquinas) do
  begin
    for L := 0 to High(ACursor.Maquinas[M].LaneOcc) do
      if not LaneCollides(ACursor.Maquinas[M].LaneOcc[L],
                          ASlot.StartDT, ASlot.EndDT) then
      begin
        MaqPuesto := M;
        LanePuesto := L;
        Break;
      end;
    if MaqPuesto >= 0 then Break;
  end;

  // Todos chocan: apilar en el primer carril de la primera maquina. Se pierde
  // precision pero no se pierde la ocupacion, que es lo que importa.
  if MaqPuesto < 0 then
  begin
    if Length(ACursor.Maquinas) = 0 then Exit;
    if Length(ACursor.Maquinas[0].LaneOcc) = 0 then Exit;
    MaqPuesto := 0;
    LanePuesto := 0;
  end;

  InsertSlotOrdered(ACursor.Maquinas[MaqPuesto].LaneOcc[LanePuesto], ASlot);
end;

// Carga la ocupacion existente de un centro en el cursor. Si AOccCache <> nil,
// la toma de la CACHE (sin BD, thread-safe). Si nil, lee BD.
procedure LoadExistingOccupancy(ACenterId: Integer; const AFechaBloqueo: TDateTime;
  var ACursor: TCenterCursor; AOccCache: TOccupancyCache = nil);
var
  Q: TADOQuery;
  Slot: TLaneSlot;
  Slots: TArray<TLaneSlotPub>;
  K: Integer;
begin
  // --- Camino CACHE: sin tocar BD ---
  if AOccCache <> nil then
  begin
    if AOccCache.TryGetValue(ACenterId, Slots) then
      for K := 0 to High(Slots) do
      begin
        Slot.StartDT := Slots[K].StartDT;
        Slot.EndDT := Slots[K].EndDT;
        Slot.Bloqueado := Slots[K].Bloqueado;
        PlaceExistingSlot(ACursor, Slot);
      end;
    Exit;
  end;

  // --- Camino BD (clasico) ---
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
      PlaceExistingSlot(ACursor, Slot);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

// Lee TODA la ocupacion existente del proyecto (una query) y la agrupa por
// CenterId. El llamante es dueno del diccionario resultante.
procedure BuildPrecedencesFromInputs(var AInputs: TArray<TSchedInput>;
  const ASolapePct: Double);
var
  PorOT: TDictionary<string, TList<Integer>>;
  Clave: string;
  Lst: TList<Integer>;
  I, J: Integer;
  Par: TPair<string, TList<Integer>>;
  // Encadenado por grupos de secuencia (operaciones paralelas).
  GrupoPrev, GrupoAct: TList<Int64>;
  OrdenGrupo: Integer;
  // Claves de ordenacion (Orden, RawId) por indice. Existe porque una closure
  // NO puede capturar un parametro 'var' (E2555: Cannot capture symbol), y el
  // comparador del Sort necesita leer los datos de cada elemento. Copiar solo
  // los dos campos que hacen falta es ademas mas barato que copiar el array de
  // records entero.
  ClaveOrden: TArray<Integer>;
  ClaveRawId: TArray<Int64>;
begin
  if Length(AInputs) < 2 then Exit;

  SetLength(ClaveOrden, Length(AInputs));
  SetLength(ClaveRawId, Length(AInputs));
  for I := 0 to High(AInputs) do
  begin
    ClaveOrden[I] := AInputs[I].Orden;
    ClaveRawId[I] := AInputs[I].RawId;
  end;

  PorOT := TDictionary<string, TList<Integer>>.Create;
  try
    // Agrupar por OT. NumeroTrabajo identifica la OT dentro de la OF; sin el no
    // hay ruta que encadenar (son operaciones sueltas), asi que se saltan.
    for I := 0 to High(AInputs) do
    begin
      SetLength(AInputs[I].PredecesorasRawIds, 0);
      AInputs[I].PorcentajeSolape := ASolapePct;

      if Trim(AInputs[I].NumeroTrabajo) = '' then Continue;
      Clave := IntToStr(AInputs[I].NumeroOF) + '|' + AInputs[I].SerieOF + '|' +
               AInputs[I].NumeroTrabajo;
      if not PorOT.TryGetValue(Clave, Lst) then
      begin
        Lst := TList<Integer>.Create;
        PorOT.Add(Clave, Lst);
      end;
      Lst.Add(I);
    end;

    // Encadenar cada OT por SECUENCIA DE RUTA (campo Orden), no por la posicion
    // en el array: cuando esto se ejecuta, la cola ya viene reordenada por la
    // regla de prioridad (EDD, SPT...) y su orden no tiene nada que ver con la
    // ruta. Ordenar aqui es imprescindible; sin ello se encadenaria al reves.
    for Par in PorOT do
    begin
      Lst := Par.Value;

      // Se ordena sobre ClaveOrden/ClaveRawId, no sobre AInputs: la closure no
      // puede capturar un parametro 'var' (ver declaracion de las claves).
      Lst.Sort(TComparer<Integer>.Construct(
        function(const A, B: Integer): Integer
        begin
          Result := CompareValue(ClaveOrden[A], ClaveOrden[B]);
          // Sin Orden del ERP (vistas antiguas: vale 0 para todas) el desempate
          // por RawId es lo unico estable que queda. Es una aproximacion, pero
          // determinista: dos ejecuciones dan la misma cadena.
          if Result = 0 then
            Result := CompareValue(ClaveRawId[A], ClaveRawId[B]);
        end));

      // Encadenar por GRUPOS de secuencia, no de uno en uno. Las operaciones
      // con el mismo Orden van en PARALELO: no se encadenan entre si, pero el
      // grupo siguiente tiene que esperarlas a TODAS.
      //
      // Encadenar solo a la ultima del grupo seria un error sutil: como las
      // paralelas no dependen entre ellas, pueden acabar en cualquier orden
      // (tipicamente estan en centros distintos), asi que la sucesora podria
      // empezar antes de que acabase alguna de las otras.
      GrupoPrev := TList<Int64>.Create;
      GrupoAct := TList<Int64>.Create;
      try
        J := 0;
        while J < Lst.Count do
        begin
          // Recoger el grupo completo con el mismo Orden.
          GrupoAct.Clear;
          OrdenGrupo := AInputs[Lst[J]].Orden;
          while (J < Lst.Count) and (AInputs[Lst[J]].Orden = OrdenGrupo) do
          begin
            // Todo el grupo espera al grupo ANTERIOR completo.
            if GrupoPrev.Count > 0 then
              AInputs[Lst[J]].PredecesorasRawIds := GrupoPrev.ToArray;
            GrupoAct.Add(AInputs[Lst[J]].RawId);
            Inc(J);
          end;

          GrupoPrev.Clear;
          GrupoPrev.AddRange(GrupoAct);
        end;
      finally
        GrupoAct.Free;
        GrupoPrev.Free;
      end;
    end;
  finally
    for Par in PorOT do
      Par.Value.Free;
    PorOT.Free;
  end;
end;

function TopologicalSortInputs(var AInputs: TArray<TSchedInput>): Boolean;
var
  IdxPorRaw: TDictionary<Int64, Integer>;
  Colocado: TArray<Boolean>;
  Salida: TList<TSchedInput>;
  I, K, PredIdx, Restantes, ColocadosVuelta: Integer;
  Listo: Boolean;
begin
  Result := True;
  if Length(AInputs) < 2 then Exit;

  IdxPorRaw := TDictionary<Int64, Integer>.Create;
  Salida := TList<TSchedInput>.Create;
  try
    for I := 0 to High(AInputs) do
      IdxPorRaw.AddOrSetValue(AInputs[I].RawId, I);

    SetLength(Colocado, Length(AInputs));
    Restantes := Length(AInputs);

    // Pasadas sucesivas: en cada una se coloca todo lo que ya tiene sus
    // predecesoras colocadas. Se conserva el orden de entrada dentro de cada
    // pasada, asi la regla de prioridad elegida por el usuario sigue mandando
    // entre operaciones que no dependen una de otra.
    while Restantes > 0 do
    begin
      ColocadosVuelta := 0;

      for I := 0 to High(AInputs) do
      begin
        if Colocado[I] then Continue;

        Listo := True;
        for K := 0 to High(AInputs[I].PredecesorasRawIds) do
          if IdxPorRaw.TryGetValue(AInputs[I].PredecesorasRawIds[K], PredIdx) then
            if not Colocado[PredIdx] then
            begin
              Listo := False;
              Break;
            end;
        // Una predecesora que NO esta en esta tanda no bloquea: puede estar ya
        // planificada de antes, y en ese caso su fecha la aporta el caller.

        if Listo then
        begin
          Salida.Add(AInputs[I]);
          Colocado[I] := True;
          Dec(Restantes);
          Inc(ColocadosVuelta);
        end;
      end;

      // Nadie ha podido colocarse: lo que queda esta en un ciclo. Se vuelca al
      // final sin encadenar, para no perder operaciones ni dejar el bucle
      // girando. La ruta del ERP esta mal definida y hay que avisar.
      if ColocadosVuelta = 0 then
      begin
        Result := False;
        for I := 0 to High(AInputs) do
          if not Colocado[I] then
          begin
            SetLength(AInputs[I].PredecesorasRawIds, 0);
            Salida.Add(AInputs[I]);
            Colocado[I] := True;
          end;
        Restantes := 0;
      end;
    end;

    AInputs := Salida.ToArray;
  finally
    Salida.Free;
    IdxPorRaw.Free;
  end;
end;

function BuildMaquinasCache: TMaquinasCache;
var
  Q: TADOQuery;
  CenterId, N: Integer;
  M: TMaquinaPub;
  Arr: TArray<TMaquinaPub>;
begin
  Result := TMaquinasCache.Create;
  if DMPlanner.ADOConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    // El ORDER BY define en que orden el motor prueba las maquinas: primero las
    // reales (EsFallback=0), la de sistema al final. Dentro de cada grupo, por
    // el Orden del maestro y luego por codigo, para que el reparto sea
    // determinista entre ejecuciones.
    Q.SQL.Text :=
      'SELECT CenterId, MaquinaId, CodigoMaquina, EsSistema ' +
      'FROM FS_PL_V_CentroMaquinaPlan ' +
      'WHERE CodigoEmpresa = :CE ' +
      'ORDER BY CenterId, EsFallback, OrdenMaquina, CodigoMaquina';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      CenterId := Q.FieldByName('CenterId').AsInteger;
      M.MaquinaId := Q.FieldByName('MaquinaId').AsInteger;
      M.Codigo := Q.FieldByName('CodigoMaquina').AsString;
      M.EsSistema := Q.FieldByName('EsSistema').AsBoolean;

      if not Result.TryGetValue(CenterId, Arr) then Arr := nil;
      N := Length(Arr);
      SetLength(Arr, N + 1);
      Arr[N] := M;
      Result.AddOrSetValue(CenterId, Arr);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function BuildOccupancyCache(const AFechaBloqueo: TDateTime): TOccupancyCache;
var
  Q: TADOQuery;
  CenterId, N: Integer;
  Slot: TLaneSlotPub;
  Arr: TArray<TLaneSlotPub>;
begin
  Result := TOccupancyCache.Create;
  if DMPlanner.ADOConnection = nil then Exit;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT CenterId, FechaInicio, FechaFin FROM FS_PL_Node ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID ' +
      '  AND ISNULL(Visible,1) = 1 AND CenterId IS NOT NULL ' +
      'ORDER BY CenterId, FechaInicio';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := DMPlanner.CurrentProjectId;
    Q.Open;
    while not Q.Eof do
    begin
      CenterId := Q.FieldByName('CenterId').AsInteger;
      Slot.StartDT := Q.FieldByName('FechaInicio').AsDateTime;
      Slot.EndDT := Q.FieldByName('FechaFin').AsDateTime;
      Slot.Bloqueado := (AFechaBloqueo > 0) and (Slot.EndDT <= AFechaBloqueo);
      if not Result.TryGetValue(CenterId, Arr) then Arr := nil;
      N := Length(Arr);
      SetLength(Arr, N + 1);
      Arr[N] := Slot;
      Result.AddOrSetValue(CenterId, Arr);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function RunAutoScheduling(const AInputs: TArray<TSchedInput>;
  const AParams: TSchedParams; AOccCache: TOccupancyCache;
  AMaqCache: TMaquinasCache): TSchedResult;
var
  Inputs: TArray<TSchedInput>;
  Params: TSchedParams;
  CentresMap: TDictionary<string, TCentreTreball>;
  Cursors: TDictionary<Integer, TCenterCursor>;
  Centres: TArray<TCentreTreball>;
  C: TCentreTreball;
  Cursor: TCenterCursor;
  I, Lane: Integer;
  Maq, K: Integer;                  // maquina elegida y su carril (V083)
  MaqsCentro: TArray<TMaquinaPub>;  // maquinas del centro, de la cache
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
  EffDist: Integer;
  // Utillajes (restriccion dura).
  UtilOK: Boolean;
  UtilBase, UtilLibre: TDateTime;
  UtilIter: Integer;
  // Precedencias de ruta (restriccion dura).
  FinPredecesoras: TDictionary<Int64, TDateTime>;   // RawId -> fin planificado
  IniPredecesoras: TDictionary<Int64, TDateTime>;   // RawId -> inicio (para el solape)
  MinPorPrecedencia: TDateTime;
  FinPred: TDateTime;

  // Instante mas temprano en que puede empezar AInput segun sus predecesoras ya
  // colocadas en esta tanda. 0 = sin restriccion.
  //
  // SEMANTICA DEL SOLAPE: identica a GetDependencyMinStart del Gantt, para que
  // autoplanificar y mover a mano den el MISMO resultado. El porcentaje se
  // aplica sobre la duracion de la PREDECESORA y se cuenta desde su INICIO:
  //
  //     inicio_minimo = inicio(pred) + duracion(pred) * Pct/100
  //
  //   Pct = 100 -> FS estricto: empieza cuando la anterior acaba (caso normal).
  //   Pct =  60 -> puede empezar cuando la anterior lleva un 60% hecho.
  //   Pct =   0 -> puede empezar a la vez que la anterior (equivale a SS).
  //
  // OJO al sentido: aqui 100 es "esperar a que acabe", no 0. Es al reves de lo
  // que sugiere la palabra "solape", pero es como lo guarda el Gantt en
  // FS_PL_Dependency.PorcentajeDependencia y no conviene tener dos criterios.
  function MinInicioPorPrecedencia(const AInput: TSchedInput): TDateTime;
  var
    Idx: Integer;
    Ini, Fin, Cand: TDateTime;
    Pct: Double;
  begin
    Result := 0;
    for Idx := 0 to High(AInput.PredecesorasRawIds) do
      if FinPredecesoras.TryGetValue(AInput.PredecesorasRawIds[Idx], Fin) then
      begin
        Pct := AInput.PorcentajeSolape;
        if Pct <= 0 then Pct := 100;   // sin valor explicito: FS estricto

        if (Pct >= 100) or
           (not IniPredecesoras.TryGetValue(AInput.PredecesorasRawIds[Idx], Ini)) then
          // FS estricto, o no sabemos cuando empezo: el fin es la referencia.
          Cand := Fin
        else
          Cand := Ini + (Fin - Ini) * (Pct / 100);

        if Cand > Result then Result := Cand;
      end;
  end;

begin
  Result := Default(TSchedResult);
  Inputs := Copy(AInputs);
  SortInputs(Inputs, AParams.Order);

  // Con precedencias activas la cola tiene que llegar en orden topologico: el
  // motor coloca en UNA pasada y consulta el fin de las predecesoras ya
  // colocadas, asi que una sucesora que llegue antes que su predecesora no
  // encontraria fecha y se colocaria demasiado pronto.
  //
  // Va DESPUES de SortInputs a proposito: la regla de prioridad elegida por el
  // usuario sigue mandando entre operaciones independientes, y el orden
  // topologico solo corrige lo que la ruta obliga.
  if AParams.RespetarPrecedencias then
    TopologicalSortInputs(Inputs);

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
  // Fin planificado de cada operacion de esta tanda, para que sus sucesoras de
  // ruta sepan cuando pueden empezar. Se crea siempre (es barato) aunque las
  // precedencias esten desactivadas, para no llenar el codigo de guardas.
  FinPredecesoras := TDictionary<Int64, TDateTime>.Create;
  IniPredecesoras := TDictionary<Int64, TDateTime>.Create;
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
          // No queda fecha de fin, asi que esta operacion NO entra en
          // FinPredecesoras: sus sucesoras de ruta no la esperaran. Es lo unico
          // que se puede hacer (no hay fecha que propagar) y no se disimula:
          // la operacion sale como no planificada y se ve en el resultado.
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
        // Capacidad POR MAQUINA: MaxLanes deja de ser "carriles del centro" y
        // pasa a ser "trabajos simultaneos que admite cada maquina". Lo normal
        // es 1 (una maquina, un trabajo); >1 es para hornos o banos que
        // procesan varias piezas a la vez.
        Cursor.Lanes := GetLanes(C);

        // Maquinas del centro (V083). Si el centro no tiene ninguna en la cache
        // (BD sin migrar, o cache no precargada) se usa UNA maquina ficticia
        // con MaquinaId 0: el motor se comporta entonces igual que antes de
        // V083, planificando a centro. Nunca se queda sin recurso.
        if (AMaqCache <> nil) and AMaqCache.TryGetValue(C.Id, MaqsCentro) and
           (Length(MaqsCentro) > 0) then
        begin
          SetLength(Cursor.Maquinas, Length(MaqsCentro));
          for J := 0 to High(MaqsCentro) do
          begin
            Cursor.Maquinas[J].MaquinaId := MaqsCentro[J].MaquinaId;
            Cursor.Maquinas[J].Codigo := MaqsCentro[J].Codigo;
            Cursor.Maquinas[J].EsSistema := MaqsCentro[J].EsSistema;
            SetLength(Cursor.Maquinas[J].LaneOcc, Cursor.Lanes);
            for K := 0 to Cursor.Lanes - 1 do
              Cursor.Maquinas[J].LaneOcc[K] := TLaneOcc.Create;
          end;
        end
        else
        begin
          SetLength(Cursor.Maquinas, 1);
          Cursor.Maquinas[0].MaquinaId := 0;   // 0 = sin maquina conocida
          Cursor.Maquinas[0].Codigo := '';
          Cursor.Maquinas[0].EsSistema := True;
          SetLength(Cursor.Maquinas[0].LaneOcc, Cursor.Lanes);
          for K := 0 to Cursor.Lanes - 1 do
            Cursor.Maquinas[0].LaneOcc[K] := TLaneOcc.Create;
        end;

        // Registrar ANTES de cargar (las listas son por referencia): asi, si
        // LoadExistingOccupancy lanza, el finally igualmente liberara las listas.
        Cursors.Add(C.Id, Cursor);
        // Con AOccCache <> nil lee de cache (sin BD, thread-safe).
        LoadExistingOccupancy(C.Id, FechaBloqueo, Cursor, AOccCache);
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
      // Maquina y carril se asignan dentro del case, pero el registro de
      // ocupacion de mas abajo los comprueba SIEMPRE: sin resetear aqui, un
      // camino que no pase por PickMaquinaLane arrastraria los de la fila
      // anterior, que ademas pueden ser de OTRO centro (Cursor tambien cambia
      // por fila). Los dos a -1 para que OccDe devuelva nil y no se escriba
      // ocupacion en un sitio que nadie ha elegido.
      Maq := -1;
      Lane := -1;
      case Params.Mode of
        smBackward:
          begin
            if Input.FechaCompromiso = 0 then
            begin
              // Fallback a Forward desde FechaBase, con la politica elegida.
              PickMaquinaLane(Cursor, True, Maq, Lane);
              EffDist := EffectiveGapMin(OccDe(Cursor, Maq, Lane), Input, Cursor.Code,
                Params.DistanciaMinNodos, Params.SetupEngine);
              StartDT := PlaceForward(OccDe(Cursor, Maq, Lane), Cursor.Cal,
                Params.FechaBase, DurMin, Params.Placement,
                Params.HuecoMinimoMin, Params.PorcentajeMinNodo,
                EffDist, NeedsShift);
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
              PickMaquinaLane(Cursor, False, Maq, Lane);
              EndDT := CalPrev(Cursor.Cal, Input.FechaCompromiso);
              StartDT := CalSub(Cursor.Cal, EndDT, DurMin);
              while LaneCollides(OccDe(Cursor, Maq, Lane), StartDT, EndDT) do
              begin
                // retroceder detras del slot que choca (el de inicio mas
                // temprano que aun solapa): situamos el fin en su inicio.
                EndDT := CalPrev(Cursor.Cal,
                  EarliestCollidingStart(OccDe(Cursor, Maq, Lane), StartDT, EndDT));
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
            PickMaquinaLane(Cursor, True, Maq, Lane);
            // Gap efectivo = max(distancia fija, tiempo de cambio secuencia-
            // dependiente respecto al ultimo nodo del lane).
            EffDist := EffectiveGapMin(OccDe(Cursor, Maq, Lane), Input, Cursor.Code,
              Params.DistanciaMinNodos, Params.SetupEngine);

            // --- Precedencias de ruta: restriccion dura ---------------------
            // La operacion no puede empezar antes de que acaben las suyas. Se
            // traduce a un suelo para la busqueda de hueco: en lugar de partir
            // de FechaBase, se parte del fin de la predecesora. Como la cola
            // viene en orden topologico, esas fechas ya estan calculadas.
            MinPorPrecedencia := Params.FechaBase;
            if Params.RespetarPrecedencias and
               (Length(Input.PredecesorasRawIds) > 0) then
            begin
              FinPred := MinInicioPorPrecedencia(Input);
              if FinPred > MinPorPrecedencia then
                MinPorPrecedencia := CalNext(Cursor.Cal, FinPred);
            end;

            StartDT := PlaceForward(OccDe(Cursor, Maq, Lane), Cursor.Cal,
              MinPorPrecedencia, DurMin, Params.Placement,
              Params.HuecoMinimoMin, Params.PorcentajeMinNodo,
              EffDist, NeedsShift);
            EndDT := CalAdd(Cursor.Cal, StartDT, DurMin);

            // --- Utillajes: restriccion dura (recurso secundario) -----------
            // El hueco puede ser bueno para el CENTRO y aun asi no servir: el
            // utillaje que exige la operacion puede estar en uso (incluso en
            // OTRO centro). Se reintenta desde que se libera, en vez de
            // rechazar sin mas, para que el nodo se MUEVA a un sitio valido.
            UtilOK := True;
            if (Params.UtillajeOcc <> nil) and (Length(Input.UtillajeReqs) > 0) then
            begin
              // Se arranca del suelo de la precedencia, no de FechaBase: si no,
              // recolocar por utillaje podria devolver el nodo a antes de que
              // acabe su predecesora y se perderia la restriccion de ruta.
              UtilBase := MinPorPrecedencia;
              UtilIter := 0;
              while not Params.UtillajeOcc.CabenTodos(Input.UtillajeReqs,
                      StartDT, EndDT) do
              begin
                Inc(UtilIter);
                // Tope de seguridad: el bucle avanza siempre (UtilLibre es un
                // fin de slot que se solapa, luego > StartDT), pero con muchos
                // nodos y ejemplares no conviene dejarlo abierto.
                if UtilIter > MAX_UTIL_RETRIES then
                begin
                  UtilOK := False;
                  Break;
                end;

                UtilLibre := Params.UtillajeOcc.ProximoHuecoTodos(
                  Input.UtillajeReqs, StartDT, EndDT);
                if UtilLibre <= UtilBase then
                begin
                  UtilOK := False;
                  Break;
                end;

                // Recolocar a partir de que el utillaje queda libre: se vuelve
                // a pasar por PlaceForward para no pisar el centro ni salirse
                // del calendario.
                UtilBase := UtilLibre;
                StartDT := PlaceForward(OccDe(Cursor, Maq, Lane), Cursor.Cal,
                  UtilBase, DurMin, Params.Placement,
                  Params.HuecoMinimoMin, Params.PorcentajeMinNodo,
                  EffDist, NeedsShift);
                EndDT := CalAdd(Cursor.Cal, StartDT, DurMin);
              end;
            end;

            Output.FechaInicio := StartDT;
            Output.FechaFin := EndDT;

            if not UtilOK then
            begin
              Output.Status := ssSinUtillaje;
              Output.Observaciones := 'Sin utillaje libre: ' +
                UtillajeReqsToStr(Input.UtillajeReqs);
              Inc(Result.TotalNoPlanificados);
            end
            else if (Input.FechaCompromiso <> 0) and (EndDT > Input.FechaCompromiso) then
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

      // Fin de esta operacion para sus SUCESORAS de ruta. Se anota SIEMPRE que
      // haya una fecha calculada, aunque el estado sea malo (saturada, fuera de
      // plazo o sin utillaje): si no, la sucesora no encontraria referencia y
      // caeria en FechaBase, es decir, se planificaria ANTES que su propia
      // predecesora y sin que nada avisara. Mas vale encadenar sobre una fecha
      // imperfecta que romper la ruta en silencio.
      if Params.RespetarPrecedencias and (EndDT > 0) then
      begin
        FinPredecesoras.AddOrSetValue(Input.RawId, EndDT);
        IniPredecesoras.AddOrSetValue(Input.RawId, StartDT);
      end;

      // Registrar el nuevo nodo como ocupacion para que los siguientes de esta
      // tanda no lo pisen.
      if (Output.Status <> ssSaturado) and (Output.Status <> ssSinUtillaje) and
         (OccDe(Cursor, Maq, Lane) <> nil) then
      begin
        NewSlot.StartDT := StartDT;
        NewSlot.EndDT := EndDT;
        NewSlot.Bloqueado := False;
        // Arrastrar los atributos del nodo para que el SIGUIENTE que caiga tras
        // el en este lane pueda calcular su tiempo de cambio (uSetupRules).
        NewSlot.SetupAttrs := Input.SetupAttrs;
        InsertSlotOrdered(OccDe(Cursor, Maq, Lane), NewSlot);

        // Dejar constancia de EN QUE MAQUINA ha caido, para persistirla.
        if (Maq >= 0) and (Maq <= High(Cursor.Maquinas)) then
        begin
          Output.MaquinaId := Cursor.Maquinas[Maq].MaquinaId;
          Output.MaquinaCodigo := Cursor.Maquinas[Maq].Codigo;
        end;

        // Y ocupar sus utillajes, para que los siguientes nodos de esta tanda
        // (de este centro o de cualquier otro) los vean cogidos.
        if (Params.UtillajeOcc <> nil) and (Length(Input.UtillajeReqs) > 0) then
          Params.UtillajeOcc.OcuparTodos(Input.UtillajeReqs, StartDT, EndDT);


        // Shift (solo politica ppHuecoShift): tras insertar el nuevo nodo,
        // empujar en cascada los slots posteriores que solapen, en orden por
        // inicio. ShiftTo arranca en el fin del nuevo nodo y va avanzando.
        // Un slot bloqueado no se puede mover: si solapa, NO se toca (queda el
        // solapamiento, pero respetamos lo consolidado) y el cursor salta tras el.
        if NeedsShift then
        begin
          ShiftTo := EndDT;
          for J := 0 to OccDe(Cursor, Maq, Lane).Count - 1 do
          begin
            NewSlot := OccDe(Cursor, Maq, Lane)[J];
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
            OccDe(Cursor, Maq, Lane)[J] := NewSlot;
            ShiftTo := NewSlot.EndDT;
          end;

          // Tras los empujes la lista puede haber quedado desordenada: re-ordenar.
          OccDe(Cursor, Maq, Lane).Sort(TComparer<TLaneSlot>.Construct(
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
      for J := 0 to High(Cursor.Maquinas) do
        for K := 0 to High(Cursor.Maquinas[J].LaneOcc) do
          Cursor.Maquinas[J].LaneOcc[K].Free;
    CentresMap.Free;
    Cursors.Free;
    OutList.Free;
    FinPredecesoras.Free;
    IniPredecesoras.Free;
  end;
end;

end.
