unit uWbsScheduler;

{
  Motor de fechas del Modulo de Proyectos (paradigma TAREAS, estilo MS Project).
  Fase 2.

  Que hace: dado el arbol WBS (TWbsTaskArray) y sus dependencias (TWbsLinkArray),
  calcula por CPM (Critical Path Method) las fechas de cada tarea:

    - Forward pass  -> EarlyStart / EarlyFinish (lo antes que puede empezar)
    - Backward pass -> LateStart / LateFinish   (lo mas tarde sin retrasar el fin)
    - Holgura total (TotalSlack) = LateStart - EarlyStart, en minutos LABORABLES
    - Camino critico = holgura <= tolerancia

  Toda la aritmetica de fechas va sobre TCentreCalendar (uCentreCalendar), el
  mismo calendario laborable que usa el paradigma RECURSOS: asi una tarea de
  proyecto respeta festivos y turnos reales igual que una operacion de OF, y los
  dos paradigmas no divergen.

  VOLATIL: el resultado NO se persiste. Se recalcula al cargar la vista y tras
  cada edicion. En BD solo viven FechaInicio/FechaFin (que este motor produce);
  holguras y criticidad son derivados y se recalculan siempre.

  Semantica de los 4 tipos de enlace (con Lag en minutos laborables, +/-):
    FS: Start(B)  >= Finish(A) + Lag     (el habitual)
    SS: Start(B)  >= Start(A)  + Lag
    FF: Finish(B) >= Finish(A) + Lag
    SF: Finish(B) >= Start(A)  + Lag

  Restricciones (TWbsTask.ConstraintKind, V078): 0=ASAP, 1=No antes de,
  2=Fecha fija. Las tareas RESUMEN no se calculan: se derivan (roll-up) del
  minimo inicio y maximo fin de sus descendientes.

  Ciclos: se detectan en la ordenacion topologica. El motor NO lanza excepcion;
  marca las tareas implicadas y las devuelve en Errores, para que la vista pueda
  avisar sin romperse.
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.DateUtils,
  System.Generics.Collections, System.Generics.Defaults,
  uWbsTypes, uCentreCalendar;

type
  // Restricciones soportadas (V078: FS_PL_Node.ConstraintKind).
  TWbsConstraintKind = (
    wckASAP      = 0,   // lo antes posible (default)
    wckNoAntesDe = 1,   // Start >= ConstraintDate
    wckFechaFija = 2    // Start  = ConstraintDate
  );

  // Resultado del motor para UNA tarea. Volatil, indexado por NodeId.
  TWbsSchedule = record
    NodeId: Integer;
    EarlyStart: TDateTime;
    EarlyFinish: TDateTime;
    LateStart: TDateTime;
    LateFinish: TDateTime;
    TotalSlackMin: Double;    // minutos laborables de holgura
    EsCritica: Boolean;
    EsResumen: Boolean;       // calculada por roll-up, no por CPM

    // Avance (V079). En las hojas sale de MinutosInvertidos/DuracionMin; en los
    // resumenes es la media de sus descendientes PONDERADA POR DURACION (una
    // tarea de 10 dias pesa 10 veces mas que una de 1), como en MS Project.
    // Puede superar 1.0 si se ha invertido mas tiempo del estimado.
    Avance: Double;           // 0..1 (o mas, si hay desviacion)
    MinutosInvertidos: Double;
    DuracionMin: Double;
  end;

  TWbsScheduleDict = TDictionary<Integer, TWbsSchedule>;

  // Resultado global del recalculo.
  TWbsSchedulerResult = record
    ProyectoInicio: TDateTime;
    ProyectoFin: TDateTime;
    TareasCriticas: Integer;
    HayCiclo: Boolean;
    Errores: TArray<string>;
  end;

  TWbsScheduler = class
  private
    FCalendar: TCentreCalendar;
    FOwnsCalendar: Boolean;
    FTareas: TWbsTaskArray;
    FLinks: TWbsLinkArray;

    FSched: TWbsScheduleDict;
    FIdx: TDictionary<Integer, Integer>;          // NodeId -> indice en FTareas
    FSucesores: TObjectDictionary<Integer, TList<Integer>>;   // NodeId -> indices de FLinks salientes
    FPredecesores: TObjectDictionary<Integer, TList<Integer>>;// NodeId -> indices de FLinks entrantes
    FOrden: TArray<Integer>;                      // NodeIds en orden topologico
    FErrores: TList<string>;
    FHayCiclo: Boolean;

    // Anclas del calculo, fijadas en Recalcular y leidas por los dos pases.
    FInicioAncla: TDateTime;    // instante laborable mas temprano permitido
    FFinProyecto: TDateTime;    // max EarlyFinish tras el forward pass

    procedure Preparar;
    procedure ConstruirGrafo;
    // Traduce enlaces que tocan tareas RESUMEN a enlaces entre sus hojas.
    function ExpandirEnlacesDeResumen(const ALinks: TWbsLinkArray): TWbsLinkArray;
    // NodeIds de todas las hojas del subarbol de ANodeId (el propio si ya lo es).
    function HojasDe(const ANodeId: Integer): TArray<Integer>;
    function OrdenTopologico: Boolean;            // False si hay ciclo
    procedure ForwardPass;
    procedure BackwardPass;
    procedure RollUpResumenes;
    procedure MarcarCriticas(const AToleranciaMin: Double);

    // Helpers de calendario.
    function SumarLaborables(const AT: TDateTime; const AMin: Double): TDateTime;
    function RestarLaborables(const AT: TDateTime; const AMin: Double): TDateTime;
    function MinutosLaborables(const AIni, AFin: TDateTime): Double;

    function EsHoja(const ATarea: TWbsTask): Boolean;
    function DuracionDe(const ATarea: TWbsTask): Double;
  public
    // Si ACalendar es nil, el motor crea uno por defecto (L-V, 8h) y lo posee.
    constructor Create(ACalendar: TCentreCalendar = nil);
    destructor Destroy; override;

    // Recalcula todo. AInicioProyecto es la fecha mas temprana permitida
    // (ancla del forward pass); si es 0 se toma el minimo FechaInicio existente.
    function Recalcular(const ATareas: TWbsTaskArray; const ALinks: TWbsLinkArray;
      const AInicioProyecto: TDateTime = 0): TWbsSchedulerResult;

    // Devuelve las tareas con FechaInicio/FechaFin ya actualizadas por el motor.
    function TareasRecalculadas: TWbsTaskArray;

    function TryGet(const ANodeId: Integer; out ASched: TWbsSchedule): Boolean;
    function EsCritica(const ANodeId: Integer): Boolean;
    function HolguraMin(const ANodeId: Integer): Double;

    property Calendar: TCentreCalendar read FCalendar;
  end;

// Calendario laborable por defecto del modulo: L-V, 08:00-13:00 y 14:00-17:00
// (8 h/dia), sabado y domingo completos no laborables. Se usa cuando la vista
// no inyecta el calendario real del centro.
function CrearCalendarioProyectoDefault: TCentreCalendar;

implementation

const
  // Tolerancia de holgura para considerar una tarea critica (1 minuto).
  CToleranciaCriticaMin = 1.0;

function CrearCalendarioProyectoDefault: TCentreCalendar;
var
  Cal: TCentreCalendar;
  LabDia: TArray<TNonWorkingPeriod>;
  DiaSencero: TArray<TNonWorkingPeriod>;
  D: Integer;
begin
  Cal := TCentreCalendar.Create;
  Cal.Name := 'Proyecto (por defecto)';

  // Dia laborable: no laborable de 00:00-08:00, 13:00-14:00 y 17:00-24:00.
  SetLength(LabDia, 3);
  LabDia[0].StartTimeOfDay := EncodeTime(0, 0, 0, 0);
  LabDia[0].EndTimeOfDay   := EncodeTime(8, 0, 0, 0);
  LabDia[1].StartTimeOfDay := EncodeTime(13, 0, 0, 0);
  LabDia[1].EndTimeOfDay   := EncodeTime(14, 0, 0, 0);
  LabDia[2].StartTimeOfDay := EncodeTime(17, 0, 0, 0);
  LabDia[2].EndTimeOfDay   := EncodeTime(23, 59, 59, 999);

  // Fin de semana: dia completo no laborable.
  SetLength(DiaSencero, 1);
  DiaSencero[0].StartTimeOfDay := EncodeTime(0, 0, 0, 0);
  DiaSencero[0].EndTimeOfDay   := EncodeTime(23, 59, 59, 999);

  for D := 1 to 5 do                      // ISO: 1=lunes .. 5=viernes
    Cal.SetDayNonWorkingPeriods(D, LabDia);
  Cal.SetDayNonWorkingPeriods(6, DiaSencero);   // sabado
  Cal.SetDayNonWorkingPeriods(7, DiaSencero);   // domingo

  Result := Cal;
end;

{ TWbsScheduler }

constructor TWbsScheduler.Create(ACalendar: TCentreCalendar);
begin
  inherited Create;
  FOwnsCalendar := (ACalendar = nil);
  if FOwnsCalendar then
    FCalendar := CrearCalendarioProyectoDefault
  else
    FCalendar := ACalendar;

  FSched := TWbsScheduleDict.Create;
  FIdx := TDictionary<Integer, Integer>.Create;
  FSucesores := TObjectDictionary<Integer, TList<Integer>>.Create([doOwnsValues]);
  FPredecesores := TObjectDictionary<Integer, TList<Integer>>.Create([doOwnsValues]);
  FErrores := TList<string>.Create;
end;

destructor TWbsScheduler.Destroy;
begin
  FErrores.Free;
  FPredecesores.Free;
  FSucesores.Free;
  FIdx.Free;
  FSched.Free;
  if FOwnsCalendar then
    FCalendar.Free;
  inherited;
end;

function TWbsScheduler.EsHoja(const ATarea: TWbsTask): Boolean;
begin
  // Solo las hojas (tareas e hitos) entran en el CPM. Los resumenes se derivan.
  Result := (ATarea.Kind <> wtkResumen) and (not ATarea.HasChildren);
end;

function TWbsScheduler.DuracionDe(const ATarea: TWbsTask): Double;
begin
  if ATarea.Kind = wtkHito then
    Result := 0
  else
    Result := Max(0, ATarea.DuracionMin);
end;

function TWbsScheduler.SumarLaborables(const AT: TDateTime; const AMin: Double): TDateTime;
begin
  // Duracion 0 (hito): solo normalizar al siguiente instante laborable.
  if AMin <= 0 then
    Result := FCalendar.NextWorkingTime(AT)
  else
    Result := FCalendar.AddWorkingMinutes(AT, Round(AMin));
end;

function TWbsScheduler.RestarLaborables(const AT: TDateTime; const AMin: Double): TDateTime;
begin
  if AMin <= 0 then
    Result := FCalendar.PrevWorkingTime(AT)
  else
    Result := FCalendar.SubtractWorkingMinutes(AT, Round(AMin));
end;

function TWbsScheduler.MinutosLaborables(const AIni, AFin: TDateTime): Double;
begin
  if AFin <= AIni then
    Result := 0
  else
    Result := FCalendar.WorkingMinutesBetween(AIni, AFin);
end;

procedure TWbsScheduler.Preparar;
var
  I: Integer;
  S: TWbsSchedule;
begin
  FSched.Clear;
  FIdx.Clear;
  FErrores.Clear;
  FHayCiclo := False;
  SetLength(FOrden, 0);

  for I := 0 to High(FTareas) do
  begin
    FIdx.AddOrSetValue(FTareas[I].NodeId, I);

    S := Default(TWbsSchedule);
    S.NodeId := FTareas[I].NodeId;
    S.EsResumen := not EsHoja(FTareas[I]);
    S.TotalSlackMin := 0;
    S.EsCritica := False;
    // Avance de las hojas: derivado del tiempo invertido. Los resumenes lo
    // reciben despues, agregado, en RollUpResumenes.
    S.MinutosInvertidos := FTareas[I].MinutosInvertidos;
    S.DuracionMin := DuracionDe(FTareas[I]);
    if not S.EsResumen then
      S.Avance := AvanceTarea(S.MinutosInvertidos, S.DuracionMin);
    FSched.AddOrSetValue(S.NodeId, S);
  end;
end;

function TWbsScheduler.HojasDe(const ANodeId: Integer): TArray<Integer>;
var
  Res: TList<Integer>;
  Idx: Integer;

  procedure Descender(const APadreId: Integer);
  var
    K: Integer;
  begin
    for K := 0 to High(FTareas) do
      if FTareas[K].ParentTaskId = APadreId then
      begin
        if EsHoja(FTareas[K]) then
          Res.Add(FTareas[K].NodeId)
        else
          Descender(FTareas[K].NodeId);
      end;
  end;

begin
  Res := TList<Integer>.Create;
  try
    if FIdx.TryGetValue(ANodeId, Idx) and EsHoja(FTareas[Idx]) then
      Res.Add(ANodeId)
    else
      Descender(ANodeId);
    Result := Res.ToArray;
  finally
    Res.Free;
  end;
end;

function TWbsScheduler.ExpandirEnlacesDeResumen(
  const ALinks: TWbsLinkArray): TWbsLinkArray;
var
  I, A, B: Integer;
  Desde, Hasta: TArray<Integer>;
  Res: TList<TWbsLink>;
  L: TWbsLink;
begin
  // MS Project permite enlazar tareas RESUMEN, pero el CPM solo opera sobre
  // hojas. Un enlace que toca un resumen se traduce al producto de las hojas de
  // ambos extremos: asi la cadena no se rompe y el camino critico atraviesa los
  // resumenes en vez de partirse en trozos inconexos.
  Res := TList<TWbsLink>.Create;
  try
    for I := 0 to High(ALinks) do
    begin
      Desde := HojasDe(ALinks[I].FromNodeId);
      Hasta := HojasDe(ALinks[I].ToNodeId);
      if (Length(Desde) = 0) or (Length(Hasta) = 0) then Continue;

      for A := 0 to High(Desde) do
        for B := 0 to High(Hasta) do
        begin
          if Desde[A] = Hasta[B] then Continue;
          L := ALinks[I];
          L.FromNodeId := Desde[A];
          L.ToNodeId := Hasta[B];
          Res.Add(L);
        end;
    end;
    Result := Res.ToArray;
  finally
    Res.Free;
  end;
end;

procedure TWbsScheduler.ConstruirGrafo;
var
  I: Integer;

  procedure Anadir(const ADict: TObjectDictionary<Integer, TList<Integer>>;
    const AKey, AValue: Integer);
  var
    L: TList<Integer>;
  begin
    if not ADict.TryGetValue(AKey, L) then
    begin
      L := TList<Integer>.Create;
      ADict.Add(AKey, L);
    end;
    L.Add(AValue);
  end;

begin
  FSucesores.Clear;
  FPredecesores.Clear;

  for I := 0 to High(FLinks) do
  begin
    // Ignorar enlaces que apunten a tareas ausentes del proyecto cargado.
    if not FIdx.ContainsKey(FLinks[I].FromNodeId) then Continue;
    if not FIdx.ContainsKey(FLinks[I].ToNodeId) then Continue;
    // Un enlace de una tarea consigo misma es un ciclo trivial: descartarlo.
    if FLinks[I].FromNodeId = FLinks[I].ToNodeId then
    begin
      FErrores.Add(Format('Enlace ignorado: la tarea %d depende de si misma.',
        [FLinks[I].FromNodeId]));
      Continue;
    end;

    Anadir(FSucesores, FLinks[I].FromNodeId, I);
    Anadir(FPredecesores, FLinks[I].ToNodeId, I);
  end;
end;

function TWbsScheduler.OrdenTopologico: Boolean;
var
  GradoEntrada: TDictionary<Integer, Integer>;
  Cola: TQueue<Integer>;
  I, Cur, NodeId, Procesados, NumPreds: Integer;
  Lst: TList<Integer>;
  Pendientes: TStringList;
begin
  GradoEntrada := TDictionary<Integer, Integer>.Create;
  Cola := TQueue<Integer>.Create;
  try
    // Solo las hojas participan en el CPM.
    for I := 0 to High(FTareas) do
      if EsHoja(FTareas[I]) then
        GradoEntrada.AddOrSetValue(FTareas[I].NodeId, 0);

    // Grado de entrada = numero de predecesores (entre hojas).
    for NodeId in GradoEntrada.Keys.ToArray do
      if FPredecesores.TryGetValue(NodeId, Lst) then
      begin
        NumPreds := 0;
        for I := 0 to Lst.Count - 1 do
          if GradoEntrada.ContainsKey(FLinks[Lst[I]].FromNodeId) then
            Inc(NumPreds);
        GradoEntrada[NodeId] := NumPreds;
      end;

    // Kahn: arrancar por los de grado 0, EN EL ORDEN WBS para que el resultado
    // sea estable entre ejecuciones (no depende del hash del diccionario).
    for I := 0 to High(FTareas) do
      if EsHoja(FTareas[I]) and (GradoEntrada[FTareas[I].NodeId] = 0) then
        Cola.Enqueue(FTareas[I].NodeId);

    SetLength(FOrden, 0);
    Procesados := 0;
    while Cola.Count > 0 do
    begin
      Cur := Cola.Dequeue;
      SetLength(FOrden, Length(FOrden) + 1);
      FOrden[High(FOrden)] := Cur;
      Inc(Procesados);

      if FSucesores.TryGetValue(Cur, Lst) then
        for I := 0 to Lst.Count - 1 do
        begin
          NodeId := FLinks[Lst[I]].ToNodeId;
          if not GradoEntrada.ContainsKey(NodeId) then Continue;
          GradoEntrada[NodeId] := GradoEntrada[NodeId] - 1;
          if GradoEntrada[NodeId] = 0 then
            Cola.Enqueue(NodeId);
        end;
    end;

    Result := (Procesados = GradoEntrada.Count);
    if not Result then
    begin
      // Las que quedan con grado > 0 estan en un ciclo (o cuelgan de uno).
      FHayCiclo := True;
      Pendientes := TStringList.Create;
      try
        for I := 0 to High(FTareas) do
          if EsHoja(FTareas[I]) and (GradoEntrada[FTareas[I].NodeId] > 0) then
            Pendientes.Add(FTareas[I].Caption);
        FErrores.Add(
          'Dependencias circulares: no se pueden calcular las fechas de ' +
          IntToStr(Pendientes.Count) + ' tarea(s): ' +
          StringReplace(Pendientes.CommaText, ',', ', ', [rfReplaceAll]));
      finally
        Pendientes.Free;
      end;

      // Aun asi, dejamos en FOrden lo que si se pudo ordenar: esas tareas se
      // calculan bien y las del ciclo conservan sus fechas actuales.
    end;
  finally
    Cola.Free;
    GradoEntrada.Free;
  end;
end;

procedure TWbsScheduler.ForwardPass;
var
  K, I, TareaIdx: Integer;
  NodeId: Integer;
  Lst: TList<Integer>;
  S, SPred: TWbsSchedule;
  T: TWbsTask;
  Cand, Inicio: TDateTime;
  Dur: Double;
  Restriccion: TWbsConstraintKind;
begin
  for K := 0 to High(FOrden) do
  begin
    NodeId := FOrden[K];
    if not FIdx.TryGetValue(NodeId, TareaIdx) then Continue;
    T := FTareas[TareaIdx];
    if not FSched.TryGetValue(NodeId, S) then Continue;

    Dur := DuracionDe(T);

    // Punto de partida: el ancla del proyecto (ya normalizada en Recalcular).
    Inicio := FInicioAncla;

    // Aplicar cada predecesor segun el tipo de enlace.
    if FPredecesores.TryGetValue(NodeId, Lst) then
      for I := 0 to Lst.Count - 1 do
      begin
        if not FSched.TryGetValue(FLinks[Lst[I]].FromNodeId, SPred) then Continue;
        // Un predecesor dentro de un ciclo no calculado no restringe.
        if SPred.EarlyFinish = 0 then Continue;

        case FLinks[Lst[I]].LinkType of
          wltSS:  // Start(B) >= Start(A) + Lag
            Cand := SumarLaborables(SPred.EarlyStart, FLinks[Lst[I]].LagMinutos);
          wltFF:  // Finish(B) >= Finish(A) + Lag  ->  Start = eso - Duracion
            Cand := RestarLaborables(
                      SumarLaborables(SPred.EarlyFinish, FLinks[Lst[I]].LagMinutos), Dur);
          wltSF:  // Finish(B) >= Start(A) + Lag   ->  Start = eso - Duracion
            Cand := RestarLaborables(
                      SumarLaborables(SPred.EarlyStart, FLinks[Lst[I]].LagMinutos), Dur);
        else      // wltFS: Start(B) >= Finish(A) + Lag
            Cand := SumarLaborables(SPred.EarlyFinish, FLinks[Lst[I]].LagMinutos);
        end;

        if Cand > Inicio then Inicio := Cand;
      end;

    // Restricciones de la tarea (V078).
    Restriccion := TWbsConstraintKind(T.ConstraintKind);
    if (Restriccion = wckNoAntesDe) and (T.ConstraintDate > 0) then
    begin
      if T.ConstraintDate > Inicio then Inicio := T.ConstraintDate;
    end
    else if (Restriccion = wckFechaFija) and (T.ConstraintDate > 0) then
      Inicio := T.ConstraintDate;

    // Normalizar a instante laborable y calcular el fin.
    S.EarlyStart := FCalendar.NextWorkingTime(Inicio);
    S.EarlyFinish := SumarLaborables(S.EarlyStart, Dur);
    FSched.AddOrSetValue(NodeId, S);
  end;
end;

procedure TWbsScheduler.BackwardPass;
var
  K, I, TareaIdx: Integer;
  NodeId: Integer;
  Lst: TList<Integer>;
  S, SSuc: TWbsSchedule;
  T: TWbsTask;
  Cand, Fin: TDateTime;
  Dur: Double;
begin
  // Recorrer el orden topologico AL REVES.
  for K := High(FOrden) downto 0 do
  begin
    NodeId := FOrden[K];
    if not FIdx.TryGetValue(NodeId, TareaIdx) then Continue;
    T := FTareas[TareaIdx];
    if not FSched.TryGetValue(NodeId, S) then Continue;

    Dur := DuracionDe(T);

    // Sin sucesores: la tarea puede acabar, como muy tarde, al final del
    // proyecto (FFinProyecto, calculado tras el forward pass).
    Fin := FFinProyecto;

    if FSucesores.TryGetValue(NodeId, Lst) then
      for I := 0 to Lst.Count - 1 do
      begin
        if not FSched.TryGetValue(FLinks[Lst[I]].ToNodeId, SSuc) then Continue;
        if SSuc.LateStart = 0 then Continue;   // sucesor no calculado (ciclo)

        case FLinks[Lst[I]].LinkType of
          wltSS:  // Start(B) >= Start(A) + Lag -> Start(A) <= Start(B) - Lag
            Cand := SumarLaborables(
                      RestarLaborables(SSuc.LateStart, FLinks[Lst[I]].LagMinutos), Dur);
          wltFF:  // Finish(A) <= Finish(B) - Lag
            Cand := RestarLaborables(SSuc.LateFinish, FLinks[Lst[I]].LagMinutos);
          wltSF:  // Finish(B) >= Start(A) + Lag -> Start(A) <= Finish(B) - Lag
            Cand := SumarLaborables(
                      RestarLaborables(SSuc.LateFinish, FLinks[Lst[I]].LagMinutos), Dur);
        else      // wltFS: Finish(A) <= Start(B) - Lag
            Cand := RestarLaborables(SSuc.LateStart, FLinks[Lst[I]].LagMinutos);
        end;

        if Cand < Fin then Fin := Cand;
      end;

    S.LateFinish := FCalendar.PrevWorkingTime(Fin);
    S.LateStart := RestarLaborables(S.LateFinish, Dur);
    FSched.AddOrSetValue(NodeId, S);
  end;
end;

procedure TWbsScheduler.RollUpResumenes;
var
  I, J, PadreIdx: Integer;
  Hijos: TDictionary<Integer, TList<Integer>>;
  Lst: TList<Integer>;
  Pair: TPair<Integer, TList<Integer>>;
  Ini, Fin: TDateTime;
  Invertidos, Estimados: Double;
  S, SPadre: TWbsSchedule;

  // Acumula el rango de fechas Y el avance de TODO el subarbol de ANodeId.
  // Solo las hojas aportan; los resumenes anidados se atraviesan. El avance se
  // acumula como suma de minutos (invertidos y estimados) para que la media
  // resultante quede ponderada por duracion.
  procedure RangoSubarbol(const ANodeId: Integer; var AIni, AFin: TDateTime;
    var AInvertidos, AEstimados: Double);
  var
    L: TList<Integer>;
    K, ChildIdx: Integer;
    SHijo: TWbsSchedule;
  begin
    if not Hijos.TryGetValue(ANodeId, L) then Exit;
    for K := 0 to L.Count - 1 do
    begin
      ChildIdx := L[K];
      if FSched.TryGetValue(FTareas[ChildIdx].NodeId, SHijo) then
        if not SHijo.EsResumen then
        begin
          if (SHijo.EarlyStart > 0) and ((AIni = 0) or (SHijo.EarlyStart < AIni)) then
            AIni := SHijo.EarlyStart;
          if SHijo.EarlyFinish > AFin then AFin := SHijo.EarlyFinish;
          AInvertidos := AInvertidos + SHijo.MinutosInvertidos;
          AEstimados := AEstimados + SHijo.DuracionMin;
        end;
      // Descender: los resumenes anidados aportan via sus propias hojas.
      RangoSubarbol(FTareas[ChildIdx].NodeId, AIni, AFin, AInvertidos, AEstimados);
    end;
  end;

begin
  Hijos := TDictionary<Integer, TList<Integer>>.Create;
  try
    for I := 0 to High(FTareas) do
    begin
      if not Hijos.TryGetValue(FTareas[I].ParentTaskId, Lst) then
      begin
        Lst := TList<Integer>.Create;
        Hijos.Add(FTareas[I].ParentTaskId, Lst);
      end;
      Lst.Add(I);
    end;

    // Recorrer al reves (hojas antes que raices) no es necesario porque
    // RangoSubarbol desciende recursivamente hasta las hojas.
    for I := 0 to High(FTareas) do
    begin
      if EsHoja(FTareas[I]) then Continue;
      if not FSched.TryGetValue(FTareas[I].NodeId, S) then Continue;

      Ini := 0; Fin := 0;
      Invertidos := 0; Estimados := 0;
      RangoSubarbol(FTareas[I].NodeId, Ini, Fin, Invertidos, Estimados);

      S.EarlyStart := Ini;
      S.EarlyFinish := Fin;
      S.LateStart := Ini;
      S.LateFinish := Fin;
      // Avance del resumen: ponderado por duracion (suma de minutos de todo el
      // subarbol), no media simple de porcentajes.
      S.MinutosInvertidos := Invertidos;
      S.DuracionMin := Estimados;
      S.Avance := AvanceTarea(Invertidos, Estimados);
      // Un resumen es critico si contiene alguna tarea critica.
      S.EsCritica := False;
      S.TotalSlackMin := 0;
      FSched.AddOrSetValue(FTareas[I].NodeId, S);
    end;

    // Propagar criticidad hacia arriba: si un descendiente es critico, el
    // resumen tambien lo es.
    for I := 0 to High(FTareas) do
    begin
      if not EsHoja(FTareas[I]) then Continue;
      if not FSched.TryGetValue(FTareas[I].NodeId, S) then Continue;
      if not S.EsCritica then Continue;

      J := FTareas[I].ParentTaskId;
      while J <> 0 do
      begin
        if FSched.TryGetValue(J, SPadre) then
        begin
          SPadre.EsCritica := True;
          FSched.AddOrSetValue(J, SPadre);
        end;
        if not FIdx.TryGetValue(J, PadreIdx) then Break;
        J := FTareas[PadreIdx].ParentTaskId;
      end;
    end;
  finally
    for Pair in Hijos do
      Pair.Value.Free;
    Hijos.Free;
  end;
end;

procedure TWbsScheduler.MarcarCriticas(const AToleranciaMin: Double);
var
  I: Integer;
  S: TWbsSchedule;
begin
  for I := 0 to High(FTareas) do
  begin
    if not EsHoja(FTareas[I]) then Continue;
    if not FSched.TryGetValue(FTareas[I].NodeId, S) then Continue;
    if (S.EarlyStart = 0) or (S.LateStart = 0) then Continue;  // no calculada

    S.TotalSlackMin := MinutosLaborables(S.EarlyStart, S.LateStart);
    S.EsCritica := S.TotalSlackMin <= AToleranciaMin;
    FSched.AddOrSetValue(FTareas[I].NodeId, S);
  end;
end;

function TWbsScheduler.Recalcular(const ATareas: TWbsTaskArray;
  const ALinks: TWbsLinkArray; const AInicioProyecto: TDateTime): TWbsSchedulerResult;
var
  I: Integer;
  S: TWbsSchedule;
  Ancla: TDateTime;
begin
  Result := Default(TWbsSchedulerResult);
  FTareas := ATareas;

  Preparar;   // llena FIdx, que ExpandirEnlacesDeResumen necesita
  if Length(FTareas) = 0 then Exit;

  // Los enlaces que tocan resumenes se bajan a sus hojas antes de construir el
  // grafo: el CPM solo opera sobre hojas.
  FLinks := ExpandirEnlacesDeResumen(ALinks);
  ConstruirGrafo;

  // Ancla del proyecto: la fecha dada, o el minimo FechaInicio existente, o hoy.
  Ancla := AInicioProyecto;
  if Ancla <= 0 then
    for I := 0 to High(FTareas) do
      if (FTareas[I].FechaInicio > 0) and
         ((Ancla = 0) or (FTareas[I].FechaInicio < Ancla)) then
        Ancla := FTareas[I].FechaInicio;
  if Ancla <= 0 then Ancla := Date;
  FInicioAncla := FCalendar.NextWorkingTime(Ancla);

  // Precalentar la cache del calendario en el hilo principal (horizonte amplio:
  // el forward pass puede empujar tareas bastante mas alla del rango actual).
  FCalendar.WarmupCache(FInicioAncla - 7, FInicioAncla + 750);

  OrdenTopologico;   // si hay ciclo, calcula lo que puede y lo reporta

  ForwardPass;

  // Fin del proyecto = maximo EarlyFinish de las hojas. Es el ancla del
  // backward pass.
  FFinProyecto := 0;
  for I := 0 to High(FTareas) do
    if EsHoja(FTareas[I]) and FSched.TryGetValue(FTareas[I].NodeId, S) then
      if S.EarlyFinish > FFinProyecto then FFinProyecto := S.EarlyFinish;
  if FFinProyecto <= 0 then FFinProyecto := FInicioAncla;

  BackwardPass;
  MarcarCriticas(CToleranciaCriticaMin);
  RollUpResumenes;

  // Resumen del resultado.
  Result.ProyectoInicio := 0;
  Result.ProyectoFin := FFinProyecto;
  Result.TareasCriticas := 0;
  for I := 0 to High(FTareas) do
    if FSched.TryGetValue(FTareas[I].NodeId, S) then
    begin
      if (S.EarlyStart > 0) and
         ((Result.ProyectoInicio = 0) or (S.EarlyStart < Result.ProyectoInicio)) then
        Result.ProyectoInicio := S.EarlyStart;
      if EsHoja(FTareas[I]) and S.EsCritica then
        Inc(Result.TareasCriticas);
    end;
  if Result.ProyectoInicio = 0 then Result.ProyectoInicio := FInicioAncla;

  Result.HayCiclo := FHayCiclo;
  Result.Errores := FErrores.ToArray;
end;

function TWbsScheduler.TareasRecalculadas: TWbsTaskArray;
var
  I: Integer;
  S: TWbsSchedule;
begin
  Result := Copy(FTareas);
  for I := 0 to High(Result) do
    if FSched.TryGetValue(Result[I].NodeId, S) then
      if S.EarlyStart > 0 then
      begin
        Result[I].FechaInicio := S.EarlyStart;
        Result[I].FechaFin := S.EarlyFinish;
      end;
end;

function TWbsScheduler.TryGet(const ANodeId: Integer; out ASched: TWbsSchedule): Boolean;
begin
  Result := FSched.TryGetValue(ANodeId, ASched);
end;

function TWbsScheduler.EsCritica(const ANodeId: Integer): Boolean;
var
  S: TWbsSchedule;
begin
  Result := FSched.TryGetValue(ANodeId, S) and S.EsCritica;
end;

function TWbsScheduler.HolguraMin(const ANodeId: Integer): Double;
var
  S: TWbsSchedule;
begin
  if FSched.TryGetValue(ANodeId, S) then
    Result := S.TotalSlackMin
  else
    Result := 0;
end;

end.
