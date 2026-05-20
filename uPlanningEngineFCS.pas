unit uPlanningEngineFCS;

{
  Motores FCS (Finite Capacity Scheduling) push:
    - TForwardSchedulerEngine: apila desde FechaBase hacia adelante.
    - TBackwardSchedulerEngine: apila desde FechaCompromiso hacia atras.

  Hoy comparten implementacion (RunAutoScheduling de uBacklogScheduler), que
  ya soporta los dos modos via TSchedParams.Mode. Estas clases envuelven esa
  funcion para encajar bajo IPlanningEngine.

  Cuando aparezca una variante (p. ej. bottleneck-based) o sea necesario
  diferenciarlas, se romperan en dos implementaciones distintas sin tocar
  los consumidores.
}

interface

uses
  System.SysUtils, System.Classes,
  uBacklogScheduler, uPlanningEngineTypes;

type
  TForwardSchedulerEngine = class(TInterfacedObject, IPlanningEngine)
  private
    function GetKind: TPlanningEngineKind;
    function GetName: string;
    function GetDescription: string;
  public
    function Schedule(const AInputs: TArray<TSchedInput>;
      const AParams: TSchedParams): TSchedResult;
  end;

  TBackwardSchedulerEngine = class(TInterfacedObject, IPlanningEngine)
  private
    function GetKind: TPlanningEngineKind;
    function GetName: string;
    function GetDescription: string;
  public
    function Schedule(const AInputs: TArray<TSchedInput>;
      const AParams: TSchedParams): TSchedResult;
  end;

implementation

{ TForwardSchedulerEngine }

function TForwardSchedulerEngine.GetKind: TPlanningEngineKind;
begin
  Result := pekForward;
end;

function TForwardSchedulerEngine.GetName: string;
begin
  Result := 'Forward (FCS)';
end;

function TForwardSchedulerEngine.GetDescription: string;
begin
  Result := 'Apila desde FechaBase hacia adelante respetando capacidad y calendario del centro.';
end;

function TForwardSchedulerEngine.Schedule(const AInputs: TArray<TSchedInput>;
  const AParams: TSchedParams): TSchedResult;
var
  P: TSchedParams;
begin
  P := AParams;
  P.Mode := smForward;
  Result := RunAutoScheduling(AInputs, P);
end;

{ TBackwardSchedulerEngine }

function TBackwardSchedulerEngine.GetKind: TPlanningEngineKind;
begin
  Result := pekBackward;
end;

function TBackwardSchedulerEngine.GetName: string;
begin
  Result := 'Backward (FCS)';
end;

function TBackwardSchedulerEngine.GetDescription: string;
begin
  Result := 'Apila desde FechaCompromiso hacia atras. Marca como saturados los que no caben antes de FechaBase.';
end;

function TBackwardSchedulerEngine.Schedule(const AInputs: TArray<TSchedInput>;
  const AParams: TSchedParams): TSchedResult;
var
  P: TSchedParams;
begin
  P := AParams;
  P.Mode := smBackward;
  Result := RunAutoScheduling(AInputs, P);
end;

end.
