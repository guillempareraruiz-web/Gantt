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

// Helpers de presentacion.
function WbsTaskKindToStr(AKind: TWbsTaskKind): string;
function WbsLinkTypeToStr(ALink: TWbsLinkType): string;

function WbsEstadoToStr(AEstado: TWbsTaskEstado): string;
function WbsPrioridadToStr(APrioridad: TWbsTaskPrioridad): string;

// Avance de una tarea: minutos invertidos sobre duracion estimada, en 0..1.
// Puede pasar de 1 si se ha invertido mas tiempo del previsto (desviacion);
// el llamante decide si lo recorta al pintar. Duracion 0 (hito): 0 o 1.
function AvanceTarea(const AMinutosInvertidos, ADuracionMin: Double): Double;

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
