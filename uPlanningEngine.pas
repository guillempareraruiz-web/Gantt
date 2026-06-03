unit uPlanningEngine;

{
  Punt d'entrada public del sistema de motors de planificacio.

  Estructura del package:
    uPlanningEngineTypes  - tipus base + IPlanningEngine (sense impl)
    uPlanningEngineFCS    - TForwardSchedulerEngine, TBackwardSchedulerEngine
    uPlanningEngine       - factory + reexport de la interface (aquest unit)

  Quan apareguin nous motors (DBR, CONWIP, CP-SAT) s'afegeixen a la factory
  sense tocar els consumidors.

  ARQUITECTURA PLUG-IN (segons docs/fs_planner_metodes_analisi.md):
  - 1 sol model de dades (FS_PL_*) i 1 mateix resultat normalitzat.
  - Motors intercanviables: Forward, Backward, Bottleneck, DBR, CONWIP, CP-SAT...
  - Cada motor implementa IPlanningEngine.Schedule(Inputs, Params): Result.
  - Els consumidors (uBacklog, autoplaner, etc.) parlen amb la interface;
    no saben quin motor concret s'executa.
}

interface

uses
  System.SysUtils, System.Classes,
  uBacklogScheduler,
  uPlanningEngineTypes;

// Reexport perque els consumidors nomes hagin de fer "uses uPlanningEngine".
type
  TSchedInput  = uPlanningEngineTypes.TSchedInput;
  TSchedOutput = uPlanningEngineTypes.TSchedOutput;
  TSchedResult = uPlanningEngineTypes.TSchedResult;
  TSchedParams = uPlanningEngineTypes.TSchedParams;
  TSchedMode   = uPlanningEngineTypes.TSchedMode;
  TSchedOrder  = uPlanningEngineTypes.TSchedOrder;
  TSchedStatus = uPlanningEngineTypes.TSchedStatus;

  TPlanningEngineKind = uPlanningEngineTypes.TPlanningEngineKind;
  IPlanningEngine     = uPlanningEngineTypes.IPlanningEngine;

function PlanningEngineKindToStr(K: TPlanningEngineKind): string;

function CreatePlanningEngine(AKind: TPlanningEngineKind): IPlanningEngine;
function CreatePlanningEngineForMode(AMode: TSchedMode): IPlanningEngine;

implementation

uses
  uPlanningEngineFCS, uPlanningEngineRules;

function PlanningEngineKindToStr(K: TPlanningEngineKind): string;
begin
  Result := uPlanningEngineTypes.PlanningEngineKindToStr(K);
end;

function CreatePlanningEngine(AKind: TPlanningEngineKind): IPlanningEngine;
begin
  case AKind of
    pekForward:  Result := TForwardSchedulerEngine.Create;
    pekBackward: Result := TBackwardSchedulerEngine.Create;
    pekRules:    Result := TPriorityRuleEngine.Create;  // config por defecto
  else
    raise Exception.CreateFmt(
      'Planning engine no implementado: %s', [PlanningEngineKindToStr(AKind)]);
  end;
end;

function CreatePlanningEngineForMode(AMode: TSchedMode): IPlanningEngine;
begin
  case AMode of
    smForward:  Result := TForwardSchedulerEngine.Create;
    smBackward: Result := TBackwardSchedulerEngine.Create;
  else
    raise Exception.Create('Modo de scheduling desconocido');
  end;
end;

end.
