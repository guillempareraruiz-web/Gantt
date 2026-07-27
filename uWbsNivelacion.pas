unit uWbsNivelacion;

{
  NIVELACION DE RECURSOS del Modulo de Proyectos (paradigma TAREAS).

  El problema que resuelve: uWbsSobrecarga ya DETECTA que alguien esta al 250 %,
  pero resolverlo era manual (arrastrar tareas a mano hasta que el aviso ambar
  desaparecia). Esto lo hace el motor.

  Que es nivelar: retrasar tareas hasta que ninguna persona supere su jornada.
  NO se acortan tareas, NO se reasigna gente a otra tarea y NO se parten tareas
  en trozos (el "splitting" de MS Project): solo se MUEVEN en el tiempo. Es la
  transformacion mas conservadora que resuelve el problema, y la unica que no
  cambia el contenido del plan que el usuario ha construido.

  Algoritmo: SERIAL SCHEDULING con lista de prioridad, el estandar en RCPSP.
    1. Se ordenan las tareas por prioridad (ver ComparadorPrioridad).
    2. Se recorren en ese orden colocando cada una lo antes posible A PARTIR de
       su EarlyStart del CPM, buscando el primer instante donde TODAS las
       personas asignadas tengan hueco.
    3. Al colocarla, se reserva su consumo en el calendario de cada persona.
    4. Una tarea colocada NO se vuelve a mover: el orden de prioridad decide
       quien gana el recurso, y quien llega despues espera.

  Por que serial y no SA (como uPlanOptimizer en el paradigma RECURSOS): alli el
  objetivo es OPTIMIZAR (buscar el mejor plan entre millones). Aqui el objetivo
  es REPARAR de forma PREDECIBLE y EXPLICABLE: el usuario tiene que poder ver la
  lista de retrasos y entender por que cada tarea se ha movido. Un metaheuristico
  daria un plan quiza mejor pero imposible de justificar fila a fila, y ademas
  movería tareas que no estaban en conflicto.

  Dos modos (como MS Project):
    - SOLO DENTRO DE LA HOLGURA: no se retrasa la fecha de fin del proyecto. Las
      tareas criticas (holgura 0) no se tocan, y una tarea solo se mueve hasta
      donde su holgura se lo permita. Lo que no cabe queda SIN RESOLVER y se
      reporta: es informacion, no un fallo.
    - COMPLETA: se resuelve todo, aunque el proyecto acabe mas tarde.

  Restricciones RIGIDAS (MSO / MFO) y ALAP no se mueven NUNCA: el usuario ha
  clavado esa fecha a proposito. Si una de ellas causa sobrecarga, se reporta
  como conflicto irresoluble en vez de romper la restriccion en silencio.

  VOLATIL: esta unidad NO escribe en BD. Devuelve una PROPUESTA (que tarea, de
  cuando a cuando, por quien) y es la vista quien la enseña y, si el usuario
  acepta, la persiste.
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.DateUtils,
  System.Generics.Collections, System.Generics.Defaults,
  uWbsTypes, uWbsScheduler, uWbsSobrecarga, uCentreCalendar;

type
  // Un retraso propuesto para UNA tarea.
  TWbsRetraso = record
    NodeId: Integer;
    Caption: string;
    ProjectId: Integer;
    InicioActual: TDateTime;
    FinActual: TDateTime;
    InicioNuevo: TDateTime;
    FinNuevo: TDateTime;
    RetrasoMin: Double;        // minutos LABORABLES de desplazamiento
    HolguraMin: Double;        // la que tenia antes de mover (para el dialogo)
    // Persona(s) por las que ha tenido que esperar. Es la explicacion de la
    // fila: sin esto el usuario ve un retraso y no sabe a que se debe.
    MotivoNombres: string;
    // Se ha comido toda su holgura y ademas empuja el fin del proyecto.
    RetrasaProyecto: Boolean;
  end;
  TWbsRetrasoArray = TArray<TWbsRetraso>;

  // Una sobrecarga que la nivelacion NO ha podido resolver, y por que.
  TWbsConflicto = record
    NodeId: Integer;
    Caption: string;
    Nombre: string;            // persona afectada
    Motivo: string;
  end;
  TWbsConflictoArray = TArray<TWbsConflicto>;

  // Resultado completo de una pasada de nivelacion.
  TWbsNivelacionResult = record
    Retrasos: TWbsRetrasoArray;
    Conflictos: TWbsConflictoArray;
    // Cuanto se alarga el proyecto (minutos laborables). 0 = no se retrasa.
    RetrasoProyectoMin: Double;
    FinAntes: TDateTime;
    FinDespues: TDateTime;
    SobrecargasAntes: Integer;
    // Sobrecargas que seguirian existiendo tras aplicar la propuesta. En modo
    // "solo holgura" puede no ser 0, y eso es legitimo.
    SobrecargasDespues: Integer;
  end;

  // Opciones de la pasada.
  TWbsNivelacionOpciones = record
    // True = no retrasar la fecha de fin del proyecto (solo mover dentro de la
    // holgura). Default False, como MS Project.
    SoloDentroHolgura: Boolean;
    // % a partir del cual se considera sobrecarga. 100 = a tope.
    Umbral: Double;
    // Tope de busqueda hacia adelante al buscar hueco para una tarea, en dias
    // naturales. Sin esto, un plan imposible podria hacer buscar indefinidamente.
    HorizonteDias: Integer;
    // Si False, las tareas ya EN CURSO o HECHAS no se mueven (mover algo que ya
    // ha empezado es replanificar el pasado). Se decide por MinutosInvertidos.
    MoverIniciadas: Boolean;
  end;

function OpcionesNivelacionPorDefecto: TWbsNivelacionOpciones;

type
  TWbsNivelador = class
  private
    FCalendar: TCentreCalendar;
    FTareas: TWbsTaskArray;
    FCargas: TWbsCargaArray;
    FOpciones: TWbsNivelacionOpciones;

    FIdx: TDictionary<Integer, Integer>;            // NodeId -> indice FTareas
    FHolgura: TDictionary<Integer, Double>;         // NodeId -> holgura CPM
    FCriticas: TDictionary<Integer, Boolean>;
    // Asignaciones por tarea: NodeId -> lista de (OperatorId, Dedicacion).
    FAsignados: TObjectDictionary<Integer, TList<TWbsCarga>>;
    // Reservas ya colocadas por persona: OperatorId -> tramos ocupados.
    FReservas: TObjectDictionary<Integer, TList<TWbsCarga>>;
    // Nombre de cada persona, para explicar los motivos.
    FNombres: TDictionary<Integer, string>;

    FNuevoInicio: TDictionary<Integer, TDateTime>;
    FNuevoFin: TDictionary<Integer, TDateTime>;
    FConflictos: TList<TWbsConflicto>;

    procedure Preparar(const ASched: TWbsScheduler);
    // Orden en que se intenta colocar cada tarea. Devuelve indices de FTareas.
    function OrdenPrioridad: TArray<Integer>;
    // Carga total de una persona en el instante AT contando lo ya reservado.
    function CargaEn(const AOperatorId: Integer; const AT: TDateTime): Double;
    // Primer instante >= ADesde en el que la tarea cabe sin pasar del umbral.
    // Devuelve 0 si no cabe dentro del horizonte. AMotivo sale con los nombres
    // de las personas que han obligado a esperar.
    function BuscarHueco(const ATarea: TWbsTask; const ADesde: TDateTime;
      const ATope: TDateTime; out AMotivo: string): TDateTime;
    // Reserva el consumo de la tarea ya colocada en el calendario de su gente.
    procedure Reservar(const ATarea: TWbsTask;
      const AIni, AFin: TDateTime);
    function EsMovible(const ATarea: TWbsTask): Boolean;
    function TieneAsignados(const ANodeId: Integer): Boolean;
    function NombreDe(const AOperatorId: Integer): string;
  public
    // ACalendar NO se posee: lo presta el scheduler (mismo calendario laborable,
    // o las fechas propuestas no cuadrarian con las que calcula el motor).
    constructor Create(ACalendar: TCentreCalendar);
    destructor Destroy; override;

    // Calcula la propuesta. ASched debe venir YA recalculado: de el salen las
    // holguras y la criticidad que deciden que se puede mover y cuanto.
    function Nivelar(const ATareas: TWbsTaskArray; const ACargas: TWbsCargaArray;
      const ASched: TWbsScheduler;
      const AOpciones: TWbsNivelacionOpciones): TWbsNivelacionResult;
  end;

implementation

const
  // Paso de barrido al buscar hueco: media jornada. Mas fino no aporta (las
  // tareas de proyecto se miden en dias) y multiplica el coste; mas grueso se
  // saltaria huecos de medio dia que si son aprovechables.
  CPasoBusquedaMin = 240;

  // Margen sobre el umbral para absorber redondeos de dedicacion (99.9997 %).
  CEpsilonCarga = 0.01;

function OpcionesNivelacionPorDefecto: TWbsNivelacionOpciones;
begin
  Result := Default(TWbsNivelacionOpciones);
  Result.SoloDentroHolgura := False;   // como MS Project
  Result.Umbral := 100;
  Result.HorizonteDias := 365;
  Result.MoverIniciadas := False;      // no replanificar lo ya empezado
end;

{ TWbsNivelador }

constructor TWbsNivelador.Create(ACalendar: TCentreCalendar);
begin
  inherited Create;
  FCalendar := ACalendar;
  FIdx := TDictionary<Integer, Integer>.Create;
  FHolgura := TDictionary<Integer, Double>.Create;
  FCriticas := TDictionary<Integer, Boolean>.Create;
  FAsignados := TObjectDictionary<Integer, TList<TWbsCarga>>.Create([doOwnsValues]);
  FReservas := TObjectDictionary<Integer, TList<TWbsCarga>>.Create([doOwnsValues]);
  FNombres := TDictionary<Integer, string>.Create;
  FNuevoInicio := TDictionary<Integer, TDateTime>.Create;
  FNuevoFin := TDictionary<Integer, TDateTime>.Create;
  FConflictos := TList<TWbsConflicto>.Create;
end;

destructor TWbsNivelador.Destroy;
begin
  FConflictos.Free;
  FNuevoFin.Free;
  FNuevoInicio.Free;
  FNombres.Free;
  FReservas.Free;
  FAsignados.Free;
  FCriticas.Free;
  FHolgura.Free;
  FIdx.Free;
  inherited;
end;

function TWbsNivelador.NombreDe(const AOperatorId: Integer): string;
begin
  if not FNombres.TryGetValue(AOperatorId, Result) then
    Result := 'Operario ' + IntToStr(AOperatorId);
end;

function TWbsNivelador.TieneAsignados(const ANodeId: Integer): Boolean;
var
  L: TList<TWbsCarga>;
begin
  Result := FAsignados.TryGetValue(ANodeId, L) and (L.Count > 0);
end;

procedure TWbsNivelador.Preparar(const ASched: TWbsScheduler);
var
  I: Integer;
  S: TWbsSchedule;
  L: TList<TWbsCarga>;
begin
  FIdx.Clear;
  FHolgura.Clear;
  FCriticas.Clear;
  FAsignados.Clear;
  FReservas.Clear;
  FNombres.Clear;
  FNuevoInicio.Clear;
  FNuevoFin.Clear;
  FConflictos.Clear;

  for I := 0 to High(FTareas) do
  begin
    FIdx.AddOrSetValue(FTareas[I].NodeId, I);
    if ASched.TryGet(FTareas[I].NodeId, S) then
    begin
      FHolgura.AddOrSetValue(FTareas[I].NodeId, S.TotalSlackMin);
      FCriticas.AddOrSetValue(FTareas[I].NodeId, S.EsCritica);
      // Punto de partida: las fechas del CPM, no las de BD. Nivelar es la capa
      // que va DESPUES de calcular fechas, y debe partir de su resultado.
      if S.EarlyStart > 0 then
      begin
        FNuevoInicio.AddOrSetValue(FTareas[I].NodeId, S.EarlyStart);
        FNuevoFin.AddOrSetValue(FTareas[I].NodeId, S.EarlyFinish);
      end;
    end;
  end;

  // Agrupar las asignaciones por tarea y recordar los nombres.
  for I := 0 to High(FCargas) do
  begin
    if FCargas[I].OperatorId <= 0 then Continue;
    if FCargas[I].Dedicacion <= 0 then Continue;

    FNombres.AddOrSetValue(FCargas[I].OperatorId, FCargas[I].Nombre);

    if not FAsignados.TryGetValue(FCargas[I].NodeId, L) then
    begin
      L := TList<TWbsCarga>.Create;
      FAsignados.Add(FCargas[I].NodeId, L);
    end;
    L.Add(FCargas[I]);
  end;
end;

function TWbsNivelador.EsMovible(const ATarea: TWbsTask): Boolean;
var
  Restr: TWbsConstraintKind;
begin
  Result := False;

  // Los resumenes no se mueven: sus fechas son roll-up de las hojas. Mover un
  // resumen es mover a sus hijos, y de eso ya se encargan ellos.
  if (ATarea.Kind = wtkResumen) or ATarea.HasChildren then Exit;

  // Un hito no consume a nadie; ademas suele ser una fecha comprometida.
  if ATarea.Kind = wtkHito then Exit;

  // Restricciones rigidas: el usuario ha clavado la fecha a proposito. ALAP ya
  // esta pegada al final por definicion; moverla contradiria la restriccion.
  Restr := TWbsConstraintKind(ATarea.ConstraintKind);
  if Restr in [wckMSO, wckMFO, wckALAP] then Exit;

  // Tareas ya empezadas: mover algo que lleva horas imputadas es replanificar
  // el pasado. Solo si el usuario lo pide expresamente.
  if (not FOpciones.MoverIniciadas) and (ATarea.MinutosInvertidos > 0) then Exit;

  Result := True;
end;

function TWbsNivelador.OrdenPrioridad: TArray<Integer>;
var
  Lista: TList<Integer>;
  I: Integer;
begin
  Lista := TList<Integer>.Create;
  try
    for I := 0 to High(FTareas) do
      // Solo compiten por recursos las tareas que consumen a alguien. Las demas
      // conservan sus fechas del CPM tal cual.
      if TieneAsignados(FTareas[I].NodeId) and
         (FTareas[I].Kind <> wtkResumen) and (not FTareas[I].HasChildren) then
        Lista.Add(I);

    // Quien gana el recurso cuando dos tareas se lo disputan. El orden ES la
    // politica de nivelacion, y esta elegido para que el resultado sea el que
    // un planificador defenderia delante del cliente:
    //
    //   1. Las que NO se pueden mover van PRIMERO. No es una preferencia: si se
    //      colocaran despues, encontrarian el hueco ocupado y no habria donde
    //      ponerlas. Reservan su sitio y las demas se adaptan.
    //   2. Las CRITICAS antes que las que tienen holgura: retrasar una critica
    //      retrasa el proyecto entero; retrasar una con holgura no cuesta nada.
    //   3. A igual criticidad, MENOS HOLGURA primero (la mas apretada).
    //   4. Luego la que empieza antes (respeta el orden natural del plan).
    //   5. Y como desempate final el orden WBS, para que dos ejecuciones sobre
    //      los mismos datos den SIEMPRE el mismo resultado: una propuesta que
    //      cambia sola entre pasadas no es defendible.
    Lista.Sort(TComparer<Integer>.Construct(
      function(const A, B: Integer): Integer
      var
        MovA, MovB, CritA, CritB: Boolean;
        HolA, HolB: Double;
        IniA, IniB: TDateTime;
      begin
        MovA := EsMovible(FTareas[A]);
        MovB := EsMovible(FTareas[B]);
        if MovA <> MovB then
          Exit(IfThen(MovA, 1, -1));   // la inmovil, antes

        CritA := FCriticas.ContainsKey(FTareas[A].NodeId) and
                 FCriticas[FTareas[A].NodeId];
        CritB := FCriticas.ContainsKey(FTareas[B].NodeId) and
                 FCriticas[FTareas[B].NodeId];
        if CritA <> CritB then
          Exit(IfThen(CritA, -1, 1));  // la critica, antes

        HolA := 0; HolB := 0;
        FHolgura.TryGetValue(FTareas[A].NodeId, HolA);
        FHolgura.TryGetValue(FTareas[B].NodeId, HolB);
        Result := CompareValue(HolA, HolB);
        if Result <> 0 then Exit;

        IniA := 0; IniB := 0;
        FNuevoInicio.TryGetValue(FTareas[A].NodeId, IniA);
        FNuevoInicio.TryGetValue(FTareas[B].NodeId, IniB);
        Result := CompareDateTime(IniA, IniB);
        if Result <> 0 then Exit;

        Result := CompareValue(FTareas[A].OrdenWBS, FTareas[B].OrdenWBS);
        if Result = 0 then
          Result := CompareValue(FTareas[A].NodeId, FTareas[B].NodeId);
      end));

    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TWbsNivelador.CargaEn(const AOperatorId: Integer;
  const AT: TDateTime): Double;
var
  L: TList<TWbsCarga>;
  I: Integer;
begin
  Result := 0;
  if not FReservas.TryGetValue(AOperatorId, L) then Exit;
  for I := 0 to L.Count - 1 do
    // Intervalo semiabierto [Inicio, Fin): una tarea que acaba a las 17:00 no
    // solapa con otra que empieza a las 17:00.
    if (AT >= L[I].FechaInicio) and (AT < L[I].FechaFin) then
      Result := Result + L[I].Dedicacion;
end;

function TWbsNivelador.BuscarHueco(const ATarea: TWbsTask;
  const ADesde: TDateTime; const ATope: TDateTime;
  out AMotivo: string): TDateTime;
var
  Asig: TList<TWbsCarga>;
  Cand, Fin: TDateTime;
  T: TDateTime;
  I: Integer;
  Cabe: Boolean;
  Dur: Double;
  Culpables: TStringList;
  Nom: string;
  // Motivo del ULTIMO intento fallido. Es el que explica el retraso: cuando por
  // fin encuentra hueco, la lista de culpables de ESA posicion esta vacia (por
  // eso cabe), asi que hay que haber guardado la anterior.
  UltimoMotivo: string;

  function TextoCulpables: string;
  begin
    Result := StringReplace(Culpables.CommaText, ',', ', ', [rfReplaceAll]);
    Result := StringReplace(Result, '"', '', [rfReplaceAll]);
  end;

begin
  Result := 0;
  AMotivo := '';
  UltimoMotivo := '';
  if not FAsignados.TryGetValue(ATarea.NodeId, Asig) then Exit;

  Dur := Max(0, ATarea.DuracionMin);
  Cand := FCalendar.NextWorkingTime(ADesde);

  Culpables := TStringList.Create;
  try
    Culpables.Duplicates := dupIgnore;
    Culpables.Sorted := True;

    while Cand <= ATope do
    begin
      // Los culpables son los de ESTE candidato, no los acumulados desde el
      // principio: si la tarea empieza esperando a Ana y acaba colocandose
      // donde solo estorbaba Pedro, el motivo debe decir Pedro. Acumularlos
      // daba una lista de todo el que se cruzo por el camino, que no explica
      // nada.
      Culpables.Clear;

      if Dur <= 0 then
        Fin := Cand
      else
        Fin := FCalendar.AddWorkingMinutes(Cand, Round(Dur));

      // Cabe si NINGUNA persona asignada pasa del umbral en NINGUN instante del
      // tramo. Se muestrea a paso fijo en vez de intersecar intervalos: es mas
      // simple, y con un paso de media jornada no se escapa ningun solape real
      // (las tareas de proyecto duran dias, no minutos).
      Cabe := True;
      T := Cand;
      while T < Fin do
      begin
        for I := 0 to Asig.Count - 1 do
          if CargaEn(Asig[I].OperatorId, T) + Asig[I].Dedicacion >
             FOpciones.Umbral + CEpsilonCarga then
          begin
            Cabe := False;
            Nom := NombreDe(Asig[I].OperatorId);
            if Culpables.IndexOf(Nom) < 0 then Culpables.Add(Nom);
            Break;
          end;
        if not Cabe then Break;

        T := IncMinute(T, CPasoBusquedaMin);
        // El ultimo tramo puede ser mas corto que el paso: comprobar tambien el
        // instante final menos un minuto, o una tarea que acabe justo despues
        // de un muestreo colaria un solape en su cola.
        if (T >= Fin) and (Fin > Cand) then
        begin
          T := IncMinute(Fin, -1);
          if T <= Cand then Break;
          for I := 0 to Asig.Count - 1 do
            if CargaEn(Asig[I].OperatorId, T) + Asig[I].Dedicacion >
               FOpciones.Umbral + CEpsilonCarga then
            begin
              Cabe := False;
              Nom := NombreDe(Asig[I].OperatorId);
              if Culpables.IndexOf(Nom) < 0 then Culpables.Add(Nom);
              Break;
            end;
          Break;
        end;
      end;

      if Cabe then
      begin
        Result := Cand;
        // Aqui Culpables esta vacio (es justo lo que hace que quepa): el motivo
        // es el del ultimo sitio donde NO cupo.
        AMotivo := UltimoMotivo;
        Exit;
      end;

      UltimoMotivo := TextoCulpables;

      // No cabe: probar mas adelante. Se avanza medio dia laborable, no un
      // minuto: buscar minuto a minuto sobre un horizonte de un año seria
      // inviable y las tareas no empiezan a las 09:37.
      Cand := FCalendar.AddWorkingMinutes(Cand, CPasoBusquedaMin);
    end;

    // Agotado el horizonte sin hueco.
    AMotivo := UltimoMotivo;
  finally
    Culpables.Free;
  end;
end;

procedure TWbsNivelador.Reservar(const ATarea: TWbsTask;
  const AIni, AFin: TDateTime);
var
  Asig, Res: TList<TWbsCarga>;
  I: Integer;
  C: TWbsCarga;
begin
  if not FAsignados.TryGetValue(ATarea.NodeId, Asig) then Exit;

  for I := 0 to Asig.Count - 1 do
  begin
    if not FReservas.TryGetValue(Asig[I].OperatorId, Res) then
    begin
      Res := TList<TWbsCarga>.Create;
      FReservas.Add(Asig[I].OperatorId, Res);
    end;
    C := Asig[I];
    C.FechaInicio := AIni;
    C.FechaFin := AFin;
    Res.Add(C);
  end;
end;

function TWbsNivelador.Nivelar(const ATareas: TWbsTaskArray;
  const ACargas: TWbsCargaArray; const ASched: TWbsScheduler;
  const AOpciones: TWbsNivelacionOpciones): TWbsNivelacionResult;
var
  Orden: TArray<Integer>;
  K, I: Integer;
  T: TWbsTask;
  IniCPM, FinCPM, IniNuevo, FinNuevo, Tope, TopeHolgura: TDateTime;
  Motivo: string;
  Dur, Holg, Retraso: Double;
  Retrasos: TList<TWbsRetraso>;
  R: TWbsRetraso;
  Cnf: TWbsConflicto;
  CargasFinales: TList<TWbsCarga>;
  C: TWbsCarga;
  Asig: TList<TWbsCarga>;
  Sob: TWbsSobrecargaArray;
  J: Integer;
begin
  Result := Default(TWbsNivelacionResult);
  FTareas := ATareas;
  FCargas := ACargas;
  FOpciones := AOpciones;
  if FOpciones.Umbral <= 0 then FOpciones.Umbral := 100;
  if FOpciones.HorizonteDias <= 0 then FOpciones.HorizonteDias := 365;

  if (Length(FTareas) = 0) or (Length(FCargas) = 0) or (ASched = nil) then Exit;

  Preparar(ASched);

  // Situacion de partida, para poder decir cuanto mejora la propuesta.
  Sob := DetectarSobrecargas(FCargas, FOpciones.Umbral);
  Result.SobrecargasAntes := Length(Sob);

  Result.FinAntes := 0;
  for I := 0 to High(FTareas) do
    if FNuevoFin.ContainsKey(FTareas[I].NodeId) then
      if FNuevoFin[FTareas[I].NodeId] > Result.FinAntes then
        Result.FinAntes := FNuevoFin[FTareas[I].NodeId];

  Orden := OrdenPrioridad;
  Retrasos := TList<TWbsRetraso>.Create;
  try
    for K := 0 to High(Orden) do
    begin
      T := FTareas[Orden[K]];
      if not FNuevoInicio.TryGetValue(T.NodeId, IniCPM) then Continue;
      if not FNuevoFin.TryGetValue(T.NodeId, FinCPM) then Continue;

      Dur := Max(0, T.DuracionMin);

      // Las inmoviles reservan su sitio tal cual y no se tocan. Van primero en
      // el orden precisamente para poder hacer esto.
      if not EsMovible(T) then
      begin
        Reservar(T, IniCPM, FinCPM);
        Continue;
      end;

      // Hasta donde se puede retrasar. En modo "solo holgura" el tope es su
      // holgura total: pasarse de ahi retrasaria el fin del proyecto, que es
      // justo lo que ese modo prohibe.
      Tope := IncDay(IniCPM, FOpciones.HorizonteDias);
      if FOpciones.SoloDentroHolgura then
      begin
        Holg := 0;
        FHolgura.TryGetValue(T.NodeId, Holg);
        if Holg <= 0 then
        begin
          // Sin holgura y sin permiso para retrasar el proyecto: se queda donde
          // esta. Si eso deja una sobrecarga, se reportara al recontar.
          Reservar(T, IniCPM, FinCPM);
          Continue;
        end;
        TopeHolgura := FCalendar.AddWorkingMinutes(IniCPM, Round(Holg));
        if TopeHolgura < Tope then Tope := TopeHolgura;
      end;

      IniNuevo := BuscarHueco(T, IniCPM, Tope, Motivo);

      if IniNuevo <= 0 then
      begin
        // No cabe en el margen permitido. En modo "solo holgura" es el caso
        // esperado y no es un error: se deja donde estaba y se explica.
        Reservar(T, IniCPM, FinCPM);

        Cnf := Default(TWbsConflicto);
        Cnf.NodeId := T.NodeId;
        Cnf.Caption := T.Caption;
        Cnf.Nombre := Motivo;
        if FOpciones.SoloDentroHolgura then
          Cnf.Motivo := 'No cabe dentro de su holgura sin retrasar el proyecto.'
        else
          Cnf.Motivo := Format(
            'No se ha encontrado hueco en los pr'#243'ximos %d d'#237'as.',
            [FOpciones.HorizonteDias]);
        FConflictos.Add(Cnf);
        Continue;
      end;

      if Dur <= 0 then
        FinNuevo := IniNuevo
      else
        FinNuevo := FCalendar.AddWorkingMinutes(IniNuevo, Round(Dur));

      FNuevoInicio.AddOrSetValue(T.NodeId, IniNuevo);
      FNuevoFin.AddOrSetValue(T.NodeId, FinNuevo);
      Reservar(T, IniNuevo, FinNuevo);

      // Solo se reporta lo que realmente se mueve.
      if CompareDateTime(IniNuevo, IniCPM) <> 0 then
      begin
        Retraso := FCalendar.WorkingMinutesBetween(IniCPM, IniNuevo);
        if Retraso > 0 then
        begin
          R := Default(TWbsRetraso);
          R.NodeId := T.NodeId;
          R.Caption := T.Caption;
          R.ProjectId := T.ProjectId;
          R.InicioActual := IniCPM;
          R.FinActual := FinCPM;
          R.InicioNuevo := IniNuevo;
          R.FinNuevo := FinNuevo;
          R.RetrasoMin := Retraso;
          Holg := 0;
          FHolgura.TryGetValue(T.NodeId, Holg);
          R.HolguraMin := Holg;
          R.MotivoNombres := Motivo;
          R.RetrasaProyecto := Retraso > Holg;
          Retrasos.Add(R);
        end;
      end;
    end;

    // Ordenar la propuesta por fecha: el usuario la lee como un calendario, no
    // como el orden interno en que el algoritmo fue colocando.
    Retrasos.Sort(TComparer<TWbsRetraso>.Construct(
      function(const A, B: TWbsRetraso): Integer
      begin
        Result := CompareDateTime(A.InicioNuevo, B.InicioNuevo);
        if Result = 0 then Result := CompareValue(B.RetrasoMin, A.RetrasoMin);
      end));

    Result.Retrasos := Retrasos.ToArray;
  finally
    Retrasos.Free;
  end;

  Result.Conflictos := FConflictos.ToArray;

  // Fin del proyecto despues de nivelar.
  Result.FinDespues := 0;
  for I := 0 to High(FTareas) do
    if FNuevoFin.ContainsKey(FTareas[I].NodeId) then
      if FNuevoFin[FTareas[I].NodeId] > Result.FinDespues then
        Result.FinDespues := FNuevoFin[FTareas[I].NodeId];

  if (Result.FinDespues > Result.FinAntes) and (Result.FinAntes > 0) then
    Result.RetrasoProyectoMin :=
      FCalendar.WorkingMinutesBetween(Result.FinAntes, Result.FinDespues);

  // Recontar sobrecargas con las fechas propuestas: es la forma honesta de
  // decir si la nivelacion ha resuelto el problema o solo parte de el.
  CargasFinales := TList<TWbsCarga>.Create;
  try
    for I := 0 to High(FTareas) do
    begin
      if not FAsignados.TryGetValue(FTareas[I].NodeId, Asig) then Continue;
      if not FNuevoInicio.ContainsKey(FTareas[I].NodeId) then Continue;
      for J := 0 to Asig.Count - 1 do
      begin
        C := Asig[J];
        C.FechaInicio := FNuevoInicio[FTareas[I].NodeId];
        C.FechaFin := FNuevoFin[FTareas[I].NodeId];
        CargasFinales.Add(C);
      end;
    end;
    Sob := DetectarSobrecargas(CargasFinales.ToArray, FOpciones.Umbral);
    Result.SobrecargasDespues := Length(Sob);
  finally
    CargasFinales.Free;
  end;
end;

end.
