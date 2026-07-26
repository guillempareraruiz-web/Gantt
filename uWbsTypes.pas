unit uWbsTypes;

// Tipos del Modulo de Proyectos (planificacion estilo MS Project, paradigma
// TAREAS). Una tarea de proyecto es un nodo de FS_PL_Node con atributos WBS
// (V078): ParentTaskId, TaskKind, etc. Aqui viven las formas ligeras que la
// Vista Proyectos consume; NO duplican TNodeData, solo lo que la vista WBS
// necesita.

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  // Tipo de tarea (persiste como TINYINT en FS_PL_Node.TaskKind).
  TWbsTaskKind = (
    wtkTarea    = 0,   // tarea normal (barra)
    wtkResumen  = 1,   // tarea resumen (abarca sus hijos)
    wtkHito     = 2    // hito / milestone (duracion 0, rombo)
  );

  // Que magnitud de la triada queda FIJA al recalcular las otras dos
  // (FS_PL_Node.TipoTarea, V082). La ecuacion es la de MS Project:
  //
  //     Trabajo = Duracion x Unidades      (Unidades = suma de dedicaciones)
  //
  // Con tres variables y una ecuacion, tocar una obliga a decidir cual de las
  // otras dos se despeja. Eso es justo lo que dice este tipo.
  TWbsTipoTarea = (
    wttDuracionFija = 0,   // cambiar operarios reparte el MISMO trabajo
    wttTrabajoFijo  = 1,   // cambiar operarios acorta o alarga la duracion
    wttUnidadesFijas = 2   // cambiar el trabajo alarga la duracion
  );

  // Restriccion de fecha de una tarea (FS_PL_Node.ConstraintKind, V078 + V082).
  //
  // Vive AQUI y no en uWbsScheduler porque no es un detalle del motor: es una
  // decision de planificacion que el usuario toma en la ficha de la tarea, y
  // esa ficha no tiene por que conocer el motor para ofrecerla.
  //
  // Tres familias, como en MS Project:
  //   FLEXIBLES     no atan a ninguna fecha; solo dicen hacia donde empujar.
  //   SEMIFLEXIBLES ponen un tope por un lado y dejan libre el otro.
  //   RIGIDAS       clavan la fecha; el motor no la mueve.
  //
  // Los valores 0/1/2 NO cambian de significado respecto a V078: los datos
  // existentes siguen siendo validos.
  TWbsConstraintKind = (
    wckASAP      = 0,   // flexible:     lo antes posible (default)
    wckSNET      = 1,   // semiflexible: no comenzar antes del  (Start >= C)
    wckMSO       = 2,   // rigida:       debe comenzar el       (Start  = C)
    wckALAP      = 3,   // flexible:     lo mas tarde posible
    wckSNLT      = 4,   // semiflexible: no comenzar despues del (Start <= C)
    wckFNET      = 5,   // semiflexible: no finalizar antes del  (Finish >= C)
    wckFNLT      = 6,   // semiflexible: no finalizar despues del(Finish <= C)
    wckMFO       = 7    // rigida:       debe finalizar el       (Finish = C)
  );

  // Tipo de enlace de dependencia (FS_PL_Dependency.TipoLink).
  TWbsLinkType = (
    wltFS = 0,   // Finish-to-Start (fin de A -> inicio de B) — el habitual
    wltSS = 1,   // Start-to-Start
    wltFF = 2,   // Finish-to-Finish
    wltSF = 3    // Start-to-Finish
  );

  // Una tarea del arbol WBS (fila del grid + barra del Gantt).
  TWbsTask = record
    NodeId: Integer;
    // Proyecto al que pertenece. La vista puede mostrar VARIOS proyectos a la
    // vez (cada uno como una rama de nivel 0), pero el CPM se calcula por
    // proyecto por separado: no hay dependencias entre proyectos.
    ProjectId: Integer;
    ParentTaskId: Integer;   // 0 = raiz (en BD NULL)
    Kind: TWbsTaskKind;
    OrdenWBS: Integer;
    Collapsed: Boolean;

    Caption: string;
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    DuracionMin: Double;      // en minutos; la UI convierte a dias
    // Tiempo REAL dedicado (V079), introducido a mano desde el NodeInspector.
    // El % de avance NO se guarda: es MinutosInvertidos / DuracionMin.
    MinutosInvertidos: Double;

    // --- Triada de esfuerzo (V082) ------------------------------------------
    // TRABAJO planificado en minutos: lo que cuesta hacer la tarea, distinto
    // de lo que dura en el calendario. Una tarea puede durar 5 dias y costar
    // 8 horas de trabajo (una persona al 20%), o durar 1 dia y costar 16 h
    // (dos personas a jornada completa).
    TrabajoMin: Double;
    // Que magnitud se mantiene fija al recalcular las otras dos.
    TipoTarea: TWbsTipoTarea;
    // Suma de dedicaciones de los operarios asignados, en TANTO POR UNO
    // (100% + 50% = 1.5). Se rellena al cargar desde FS_PL_TaskOperario; sin
    // operarios asignados vale 1.0 ("una persona a jornada completa"), que es
    // la unica lectura que no rompe la ecuacion.
    Unidades: Double;

    // Restriccion de fecha (V078). La consume el motor (uWbsScheduler):
    // 0 = ASAP (lo antes posible), 1 = No antes de, 2 = Fecha fija.
    ConstraintKind: Integer;
    ConstraintDate: TDateTime;   // 0 = sin fecha de restriccion

    // Rellenados al construir el arbol (no vienen de BD directamente):
    Nivel: Integer;           // profundidad (0 = raiz)
    HasChildren: Boolean;
  end;
  TWbsTaskArray = TArray<TWbsTask>;

  // Una dependencia entre tareas.
  TWbsLink = record
    DependencyId: Integer;
    ProjectId: Integer;      // para repartir los enlaces por proyecto
    FromNodeId: Integer;
    ToNodeId: Integer;
    LinkType: TWbsLinkType;
    LagMinutos: Integer;
  end;
  TWbsLinkArray = TArray<TWbsLink>;

  // Cabecera de un proyecto TAREAS. La vista puede mostrar varios a la vez:
  // cada uno cuelga de una fila de NIVEL 0 con su nombre.
  TWbsProyecto = record
    ProjectId: Integer;
    Codigo: string;
    Nombre: string;
    // Rellenados tras planificar (agregado de sus tareas).
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    TareasCriticas: Integer;
  end;
  TWbsProyectoArray = TArray<TWbsProyecto>;

  // Estado de una tarea (FS_PL_TaskDetail.Estado, V080).
  TWbsTaskEstado = (
    wtePendiente = 0,
    wteEnCurso   = 1,
    wteBloqueada = 2,
    wteHecha     = 3,
    wteCancelada = 4
  );

  // Prioridad (FS_PL_TaskDetail.Prioridad, V080).
  TWbsTaskPrioridad = (
    wtpBaja    = 0,
    wtpNormal  = 1,
    wtpAlta    = 2,
    wtpCritica = 3
  );

  // Ficha ampliada de una tarea de ingenieria (V080). Es OPCIONAL: una tarea
  // sin ficha es valida y se comporta como antes.
  TWbsTaskDetail = record
    NodeId: Integer;
    Notas: string;
    Estado: TWbsTaskEstado;
    Prioridad: TWbsTaskPrioridad;
    Etiqueta: string;
    ColorEtiqueta: Integer;
    ResponsableId: Integer;
    // Esfuerzo estimado en MINUTOS (la UI lo pide en horas). Distinto de
    // DuracionMin: una tarea puede durar 5 dias y costar 8 horas de trabajo.
    HorasEstimadas: Double;
  end;

  // Etiqueta del catalogo (FS_PL_TaskTag, V081). Estilo Trello: se define una
  // vez con su color y se asigna a las tareas que haga falta.
  TWbsTag = record
    TagId: Integer;
    Nombre: string;
    Color: Integer;     // BGR de TColor
    Orden: Integer;
    Asignada: Boolean;  // solo al presentarla para una tarea concreta
  end;
  TWbsTagArray = TArray<TWbsTag>;

  // Un operario asignado a una tarea (FS_PL_TaskOperario, V080).
  TWbsTaskOperario = record
    NodeId: Integer;
    OperatorId: Integer;
    Nombre: string;          // resuelto al leer, para no re-consultar
    Dedicacion: Double;      // % de jornada (100 = completa)
    MinutosImputados: Double;
  end;
  TWbsTaskOperarioArray = TArray<TWbsTaskOperario>;

  // Una asignacion vista desde el lado del OPERARIO, para el resumen de carga
  // que va bajo el Gantt (que hace cada persona y cuando).
  TWbsCarga = record
    OperatorId: Integer;
    Nombre: string;
    NodeId: Integer;
    Caption: string;         // tarea
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    Dedicacion: Double;      // % de jornada
  end;
  TWbsCargaArray = TArray<TWbsCarga>;

  // --- Linea base (V082) ----------------------------------------------------
  // Foto de UNA tarea en el momento de fijar la linea base.
  TWbsBaselineTask = record
    NodeId: Integer;
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    DuracionMin: Double;
    TrabajoMin: Double;
  end;
  TWbsBaselineTaskArray = TArray<TWbsBaselineTask>;

  // Cabecera de una linea base: sin esto es un monton de fechas sin contexto.
  TWbsBaseline = record
    ProjectId: Integer;
    BaselineId: Integer;
    Nombre: string;
    FijadaEn: TDateTime;
    NumTareas: Integer;
  end;
  TWbsBaselineArray = TArray<TWbsBaseline>;

  // Desviacion de una tarea contra su linea base. Criterio de signo:
  // POSITIVO = va PEOR que el plan (mas tarde, mas trabajo).
  TWbsDesvio = record
    NodeId: Integer;
    TieneBaseline: Boolean;
    BaseInicio: TDateTime;
    BaseFin: TDateTime;
    BaseDuracionMin: Double;
    BaseTrabajoMin: Double;
    DesvioInicioDias: Integer;
    DesvioFinDias: Integer;
    DesvioTrabajoMin: Double;
  end;

  // --- Sobreasignacion de operarios -----------------------------------------
  // Un tramo en el que una persona supera el 100% de su jornada sumando todas
  // las tareas que se le solapan. Es lo que convierte la dedicacion en algo
  // accionable: sin esto se puede asignar a alguien al 300% sin enterarse.
  TWbsSobrecarga = record
    OperatorId: Integer;
    Nombre: string;
    Desde: TDateTime;
    Hasta: TDateTime;
    PorcentajePico: Double;   // 100 = justo a tope; 250 = dos veces y media
    NodeIds: TArray<Integer>; // tareas que coinciden en ese tramo
  end;
  TWbsSobrecargaArray = TArray<TWbsSobrecarga>;

  // Que magnitud de la triada acaba de tocar el usuario (ver RecalcularTriada).
  TWbsCampoEditado = (
    wceDuracion,     // ha tecleado una duracion
    wceTrabajo,      // ha tecleado un trabajo (horas)
    wceUnidades      // ha anadido/quitado operarios o cambiado su dedicacion
  );

// Helpers de presentacion.
function WbsTaskKindToStr(AKind: TWbsTaskKind): string;
function WbsTipoTareaToStr(ATipo: TWbsTipoTarea): string;
function WbsLinkTypeToStr(ALink: TWbsLinkType): string;

function WbsEstadoToStr(AEstado: TWbsTaskEstado): string;
function WbsPrioridadToStr(APrioridad: TWbsTaskPrioridad): string;

// Avance de una tarea: minutos invertidos sobre duracion estimada, en 0..1.
// Puede pasar de 1 si se ha invertido mas tiempo del previsto (desviacion);
// el llamante decide si lo recorta al pintar. Duracion 0 (hito): 0 o 1.
function AvanceTarea(const AMinutosInvertidos, ADuracionMin: Double): Double;

// --- Triada de esfuerzo (V082) ----------------------------------------------
//
//     Trabajo = Duracion x Unidades
//
// Que magnitud cambia el usuario y cual se despeja. Se pasa la tarea entera (con
// su TipoTarea) y que campo se acaba de tocar, y devuelve la tarea con las otras
// dos magnitudes ya cuadradas. Es la UNICA implementacion de la ecuacion: ni la
// vista ni la ficha deben rehacerla por su cuenta.
function RecalcularTriada(const ATarea: TWbsTask;
  ACampo: TWbsCampoEditado): TWbsTask;

// Unidades a partir de las dedicaciones de los operarios asignados, en tanto
// por uno. Sin operarios devuelve 1.0: "una persona a jornada completa" es la
// unica lectura que no rompe la ecuacion (con 0 el trabajo seria siempre 0).
function UnidadesDeOperarios(const AOperarios: TWbsTaskOperarioArray): Double;

// Duracion: minutos <-> dias laborables (jornada configurable, default 480).
function MinutosADias(AMin: Double; AJornadaMin: Integer = 480): Double;
function DiasAMinutos(ADias: Double; AJornadaMin: Integer = 480): Double;
function FormatDias(AMin: Double; AJornadaMin: Integer = 480): string;

implementation

function WbsTaskKindToStr(AKind: TWbsTaskKind): string;
begin
  case AKind of
    wtkResumen: Result := 'Resumen';
    wtkHito:    Result := 'Hito';
  else
    Result := 'Tarea';
  end;
end;

function WbsLinkTypeToStr(ALink: TWbsLinkType): string;
begin
  case ALink of
    wltSS: Result := 'SS';
    wltFF: Result := 'FF';
    wltSF: Result := 'SF';
  else
    Result := 'FS';
  end;
end;

function WbsEstadoToStr(AEstado: TWbsTaskEstado): string;
begin
  case AEstado of
    wteEnCurso:   Result := 'En curso';
    wteBloqueada: Result := 'Bloqueada';
    wteHecha:     Result := 'Hecha';
    wteCancelada: Result := 'Cancelada';
  else
    Result := 'Pendiente';
  end;
end;

function WbsPrioridadToStr(APrioridad: TWbsTaskPrioridad): string;
begin
  case APrioridad of
    wtpBaja:    Result := 'Baja';
    wtpAlta:    Result := 'Alta';
    wtpCritica: Result := 'Cr'#237'tica';
  else
    Result := 'Normal';
  end;
end;

function AvanceTarea(const AMinutosInvertidos, ADuracionMin: Double): Double;
begin
  if AMinutosInvertidos <= 0 then
    Result := 0
  else if ADuracionMin <= 0 then
    // Hito o tarea sin duracion: cualquier tiempo invertido lo da por hecho.
    Result := 1
  else
    Result := AMinutosInvertidos / ADuracionMin;
end;

function WbsTipoTareaToStr(ATipo: TWbsTipoTarea): string;
begin
  case ATipo of
    wttTrabajoFijo:   Result := 'Trabajo fijo';
    wttUnidadesFijas: Result := 'Unidades fijas';
  else
    Result := 'Duraci'#243'n fija';
  end;
end;

function UnidadesDeOperarios(const AOperarios: TWbsTaskOperarioArray): Double;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(AOperarios) do
    if AOperarios[I].Dedicacion > 0 then
      Result := Result + AOperarios[I].Dedicacion / 100;

  // Sin nadie asignado la tarea sigue costando trabajo: se lee como "una
  // persona a jornada completa". Con 0 el trabajo saldria siempre 0 y la
  // ecuacion dejaria de decir nada.
  if Result <= 0 then Result := 1.0;
end;

function RecalcularTriada(const ATarea: TWbsTask;
  ACampo: TWbsCampoEditado): TWbsTask;
var
  U: Double;
begin
  Result := ATarea;

  // Un hito no dura ni cuesta: la ecuacion no le aplica.
  if Result.Kind = wtkHito then
  begin
    Result.DuracionMin := 0;
    Result.TrabajoMin := 0;
    Exit;
  end;

  U := Result.Unidades;
  if U <= 0 then U := 1.0;
  Result.Unidades := U;

  case Result.TipoTarea of

    // DURACION FIJA: la duracion manda. Poner mas gente no acorta la tarea,
    // reparte el mismo calendario entre mas manos -> cambia el TRABAJO.
    // (El caso "una reunion de 2 h con 5 personas": dura 2 h vengan los que
    // vengan, pero cuesta 10 h de trabajo.)
    wttDuracionFija:
      case ACampo of
        wceTrabajo:
          // Han tecleado el trabajo, pero la duracion es intocable: lo que se
          // despeja son las unidades (hace falta mas o menos gente).
          if Result.DuracionMin > 0 then
            Result.Unidades := Result.TrabajoMin / Result.DuracionMin;
      else
        // Duracion o unidades -> el trabajo es el que sale.
        Result.TrabajoMin := Result.DuracionMin * Result.Unidades;
      end;

    // TRABAJO FIJO: el esfuerzo esta cerrado (lo dice el presupuesto). Poner
    // mas gente ACORTA la tarea; quitarla la alarga.
    wttTrabajoFijo:
      case ACampo of
        wceDuracion:
          // Han tecleado la duracion con el trabajo cerrado: se despeja
          // cuanta gente hace falta.
          if Result.DuracionMin > 0 then
            Result.Unidades := Result.TrabajoMin / Result.DuracionMin;
      else
        // Trabajo o unidades -> la duracion es la que sale.
        Result.DuracionMin := Result.TrabajoMin / Result.Unidades;
      end;

    // UNIDADES FIJAS: el equipo esta cerrado (son estos y no hay mas). Mas
    // trabajo = mas dias; mas dias = mas trabajo.
    wttUnidadesFijas:
      case ACampo of
        wceTrabajo:
          Result.DuracionMin := Result.TrabajoMin / Result.Unidades;
        wceDuracion:
          Result.TrabajoMin := Result.DuracionMin * Result.Unidades;
        // wceUnidades: NO se toca nada. Con las unidades declaradas fijas, que
        // cambiar la asignacion mueva la duracion o el trabajo contradiria el
        // tipo elegido. (Es lo mismo que hace el UPDATE de SaveOperarios en
        // uWbsRepo, que para TipoTarea = 2 deja ambas columnas como estaban:
        // los dos caminos tienen que dar el MISMO resultado.)
      end;
  end;

  if Result.DuracionMin < 0 then Result.DuracionMin := 0;
  if Result.TrabajoMin < 0 then Result.TrabajoMin := 0;
  if Result.Unidades <= 0 then Result.Unidades := 1.0;
end;

function MinutosADias(AMin: Double; AJornadaMin: Integer): Double;
begin
  if AJornadaMin <= 0 then AJornadaMin := 480;
  Result := AMin / AJornadaMin;
end;

function DiasAMinutos(ADias: Double; AJornadaMin: Integer): Double;
begin
  if AJornadaMin <= 0 then AJornadaMin := 480;
  Result := ADias * AJornadaMin;
end;

function FormatDias(AMin: Double; AJornadaMin: Integer): string;
var
  D: Double;
begin
  D := MinutosADias(AMin, AJornadaMin);
  // "0 d" para hitos; sin decimales si es entero; un decimal si no.
  if D = 0 then
    Result := '0 d'
  else if Frac(D) = 0 then
    Result := Format('%.0f d', [D])
  else
    Result := Format('%.1f d', [D]);
end;

end.
