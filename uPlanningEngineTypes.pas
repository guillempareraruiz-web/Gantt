unit uPlanningEngineTypes;

{
  Tipus base + interface IPlanningEngine. Sense impl ni factory.
  Aquesta unit la importen tots els motors (uPlanningEngineFCS, futurs DBR,
  CONWIP, CP-SAT) i tots els consumidors que parlin amb la interface.

  Els records de IO viuen a uBacklogScheduler per compatibilitat historica.
  Aqui els reexporto per centralitzar.
}

interface

uses
  uBacklogScheduler;

type
  // Reexport per simplificar imports a consumidors.
  TSchedInput  = uBacklogScheduler.TSchedInput;
  TSchedOutput = uBacklogScheduler.TSchedOutput;
  TSchedResult = uBacklogScheduler.TSchedResult;
  TSchedParams = uBacklogScheduler.TSchedParams;
  TSchedMode   = uBacklogScheduler.TSchedMode;
  TSchedOrder  = uBacklogScheduler.TSchedOrder;
  TSchedStatus = uBacklogScheduler.TSchedStatus;

  TPlanningEngineKind = (
    pekForward,        // FCS forward
    pekBackward,       // FCS backward
    pekBottleneck,     // futur: bottleneck-based
    pekDBR,            // futur: drum-buffer-rope
    pekKanbanPull,     // futur: pull amb WIP limits per estacio
    pekCONWIP,         // futur: WIP global constant
    pekOptimization    // futur: CP-SAT / metaheuristiques
  );

  IPlanningEngine = interface
    ['{A2B3C4D5-E6F7-4F8A-9B0C-1D2E3F4A5B6C}']
    function GetKind: TPlanningEngineKind;
    function GetName: string;
    function GetDescription: string;

    function Schedule(const AInputs: TArray<TSchedInput>;
      const AParams: TSchedParams): TSchedResult;

    property Kind: TPlanningEngineKind read GetKind;
    property Name: string read GetName;
    property Description: string read GetDescription;
  end;

function PlanningEngineKindToStr(K: TPlanningEngineKind): string;

implementation

function PlanningEngineKindToStr(K: TPlanningEngineKind): string;
begin
  case K of
    pekForward:      Result := 'Forward (FCS)';
    pekBackward:     Result := 'Backward (FCS)';
    pekBottleneck:   Result := 'Bottleneck-based';
    pekDBR:          Result := 'Drum-Buffer-Rope';
    pekKanbanPull:   Result := 'Kanban pull';
    pekCONWIP:       Result := 'CONWIP';
    pekOptimization: Result := 'Optimization (CP-SAT)';
  else
    Result := '?';
  end;
end;

end.
