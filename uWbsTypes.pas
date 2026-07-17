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
    ParentTaskId: Integer;   // 0 = raiz (en BD NULL)
    Kind: TWbsTaskKind;
    OrdenWBS: Integer;
    Collapsed: Boolean;

    Caption: string;
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    DuracionMin: Double;      // en minutos; la UI convierte a dias

    // Rellenados al construir el arbol (no vienen de BD directamente):
    Nivel: Integer;           // profundidad (0 = raiz)
    HasChildren: Boolean;
  end;
  TWbsTaskArray = TArray<TWbsTask>;

  // Una dependencia entre tareas.
  TWbsLink = record
    DependencyId: Integer;
    FromNodeId: Integer;
    ToNodeId: Integer;
    LinkType: TWbsLinkType;
    LagMinutos: Integer;
  end;
  TWbsLinkArray = TArray<TWbsLink>;

// Helpers de presentacion.
function WbsTaskKindToStr(AKind: TWbsTaskKind): string;
function WbsLinkTypeToStr(ALink: TWbsLinkType): string;

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
