unit uPlanningEngineRules;

{
  Motor de planificacion por REGLAS DE PRIORIDAD (PRO).

  No es un algoritmo de apilado nuevo: ordena la cola de operaciones aplicando
  reglas de prioridad industriales (EDD, SPT, LPT, FIFO, Critical Ratio, Slack,
  Prioridad ERP) con desempate multinivel, y luego delega el apilado en el FCS
  existente (RunAutoScheduling) respetando capacidad, calendarios y direccion
  forward/backward.

  Caracteristicas PRO:
    - Regla global con hasta 3 niveles de desempate (TPriorityRuleSet).
    - Overrides por centro: un centro (p.ej. el cuello de botella) puede usar
      una regla distinta de la global.
    - La cola se ordena por centro segun su regla efectiva; el resultado se
      pasa a RunAutoScheduling con Order = soPreordenado (no reordena).

  Los parametros de reglas se inyectan por property ANTES de llamar Schedule,
  para no modificar la firma de IPlanningEngine.Schedule.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  uBacklogScheduler, uPlanningEngineTypes;

type
  // Override de reglas para un centro concreto (PRO).
  TCenterRuleOverride = record
    CentroCode: string;        // coincide con CentroPreferente del TSchedInput
    Rules: TPriorityRuleSet;
  end;

  TPriorityRuleEngine = class(TInterfacedObject, IPlanningEngine)
  private
    FGlobal: TPriorityRuleSet;
    FOverrides: TArray<TCenterRuleOverride>;
    function GetKind: TPlanningEngineKind;
    function GetName: string;
    function GetDescription: string;
    // Devuelve el conjunto de reglas efectivo para un centro (override o global).
    function EffectiveRules(const ACentroCode: string): TPriorityRuleSet;
  public
    constructor Create;
    // Configuracion (inyectar antes de Schedule).
    property Global: TPriorityRuleSet read FGlobal write FGlobal;
    procedure SetOverrides(const AOverrides: TArray<TCenterRuleOverride>);

    function Schedule(const AInputs: TArray<TSchedInput>;
      const AParams: TSchedParams): TSchedResult;
  end;

implementation

{ TPriorityRuleEngine }

constructor TPriorityRuleEngine.Create;
begin
  inherited Create;
  FGlobal := DefaultRuleSet;
  SetLength(FOverrides, 0);
end;

function TPriorityRuleEngine.GetKind: TPlanningEngineKind;
begin
  Result := pekRules;
end;

function TPriorityRuleEngine.GetName: string;
begin
  Result := 'Reglas de prioridad';
end;

function TPriorityRuleEngine.GetDescription: string;
begin
  Result := 'Ordena la cola por reglas de prioridad (EDD, SPT, Critical Ratio, ' +
            'Slack...) con desempate multinivel y overrides por centro, y apila ' +
            'con capacidad finita.';
end;

procedure TPriorityRuleEngine.SetOverrides(
  const AOverrides: TArray<TCenterRuleOverride>);
begin
  FOverrides := Copy(AOverrides);
end;

function TPriorityRuleEngine.EffectiveRules(
  const ACentroCode: string): TPriorityRuleSet;
var
  Key: string;
  I: Integer;
begin
  Result := FGlobal;
  Key := UpperCase(Trim(ACentroCode));
  for I := 0 to High(FOverrides) do
    if UpperCase(Trim(FOverrides[I].CentroCode)) = Key then
      Exit(FOverrides[I].Rules);
end;

function TPriorityRuleEngine.Schedule(const AInputs: TArray<TSchedInput>;
  const AParams: TSchedParams): TSchedResult;
var
  Buckets: TDictionary<string, TList<TSchedInput>>;
  Ordered: TList<TSchedInput>;
  Lst: TList<TSchedInput>;
  Arr: TArray<TSchedInput>;
  Input: TSchedInput;
  Key: string;
  P: TSchedParams;
  CentroKey: string;
begin
  // 1) Particionar por centro preferente.
  Buckets := TDictionary<string, TList<TSchedInput>>.Create;
  Ordered := TList<TSchedInput>.Create;
  try
    for Input in AInputs do
    begin
      Key := UpperCase(Trim(Input.CentroPreferente));
      if not Buckets.TryGetValue(Key, Lst) then
      begin
        Lst := TList<TSchedInput>.Create;
        Buckets.Add(Key, Lst);
      end;
      Lst.Add(Input);
    end;

    // 2) Ordenar cada bucket por su regla efectiva y reensamblar.
    for CentroKey in Buckets.Keys do
    begin
      Lst := Buckets[CentroKey];
      Arr := Lst.ToArray;
      SortInputsByRuleSet(Arr, EffectiveRules(CentroKey), AParams.FechaBase);
      Ordered.AddRange(Arr);
    end;

    // 3) Apilar con FCS, sin reordenar (la cola ya viene ordenada).
    P := AParams;
    P.Order := soPreordenado;
    Result := RunAutoScheduling(Ordered.ToArray, P);
  finally
    for Lst in Buckets.Values do
      Lst.Free;
    Buckets.Free;
    Ordered.Free;
  end;
end;

end.
