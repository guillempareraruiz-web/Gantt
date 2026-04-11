unit uPlanningRules;

{
  Motor de regles de planificació configurable.

  Dos tipus de regles:
  - SortRules: criteris d'ordenació encadenats (multi-camp)
  - FilterRules: condicions de filtre/exclusió/forçar centre

  Les regles es poden guardar/carregar com a perfils JSON.
  Suporta camps obligatoris de TNodeData + camps personalitzats.
}

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Math,
  System.Generics.Collections, System.Generics.Defaults,
  System.JSON, System.IOUtils, System.DateUtils, System.StrUtils,
  uGanttTypes, uCustomFieldDefs;

type
  // ── Ordenació ──
  TSortDirection = (sdAsc, sdDesc);

  TSortRule = record
    FieldName: string;        // camp: 'Prioridad', 'FechaEntrega', o camp personalitzat
    Direction: TSortDirection;
    Weight: Integer;           // pes 1..10 (a més pes, més important el criteri)
    Enabled: Boolean;
  end;

  // ── Filtre ──
  TFilterOperator = (
    foEquals,        // =
    foNotEquals,     // <>
    foGreater,       // >
    foGreaterEqual,  // >=
    foLess,          // <
    foLessEqual,     // <=
    foContains,      // conté substring
    foIn             // dins una llista de valors
  );

  TFilterAction = (
    faInclude,       // només incloure si compleix
    faExclude,       // excloure si compleix
    faForceCenter    // forçar a un centre concret
  );

  TFilterRule = record
    FieldName: string;
    Operator: TFilterOperator;
    Value: Variant;
    Action: TFilterAction;
    TargetCentreId: Integer;   // només per faForceCenter
    Enabled: Boolean;
  end;

  // ── Agrupació (Batching) ──
  TGroupMode = (
    gmSameCenter,     // agrupar OTs amb mateix valor al MATEIX centre
    gmConsecutive     // posar-les consecutives (minimitzar canvis de sèrie)
  );

  TGroupRule = record
    FieldName: string;       // camp per agrupar (ex: 'CodigoColor', 'CodigoArticulo')
    Mode: TGroupMode;
    Weight: Integer;          // prioritat d'agrupació 1..10
    Enabled: Boolean;
  end;

  // ── Perfil de planificació ──
  TPlanningProfile = record
    Name: string;
    Description: string;
    SortRules: TArray<TSortRule>;
    FilterRules: TArray<TFilterRule>;
    GroupRules: TArray<TGroupRule>;
  end;

  // ── Resultat de filtre per un node ──
  TFilterResult = record
    Include: Boolean;
    ForcedCentreId: Integer;   // -1 = sense forçar
  end;

  // ── Motor ──
  TPlanningRuleEngine = class
  private
    FProfiles: TList<TPlanningProfile>;
    FActiveIndex: Integer;
    FCustomFieldDefs: TCustomFieldDefs;  // referència, no propietari
    FFileName: string;

    // Builtin field names
    class function GetBuiltinFieldNames: TArray<string>; static;
    class function GetBuiltinFieldValue(const ANode: TNodeData;
      const AFieldName: string): Variant; static;

    // JSON helpers
    function DirectionToStr(D: TSortDirection): string;
    function StrToDirection(const S: string): TSortDirection;
    function OperatorToStr(O: TFilterOperator): string;
    function StrToOperator(const S: string): TFilterOperator;
    function ActionToStr(A: TFilterAction): string;
    function StrToAction(const S: string): TFilterAction;
    function GroupModeToJSON(M: TGroupMode): string;
    function JSONToGroupMode(const S: string): TGroupMode;
  public
    constructor Create(ACustomFieldDefs: TCustomFieldDefs);
    destructor Destroy; override;

    // Obtenir valor d'un camp (builtin o custom)
    class function GetFieldValue(const ANode: TNodeData;
      const AFieldName: string): Variant; static;

    // Llista de tots els camps disponibles (builtin + custom)
    function GetAvailableFields: TArray<string>;

    // Perfils
    procedure AddProfile(const AProfile: TPlanningProfile);
    procedure UpdateProfile(AIndex: Integer; const AProfile: TPlanningProfile);
    procedure DeleteProfile(AIndex: Integer);
    function ProfileCount: Integer;
    function GetProfile(AIndex: Integer): TPlanningProfile;
    property ActiveIndex: Integer read FActiveIndex write FActiveIndex;
    function GetActiveProfile: TPlanningProfile;

    // Avaluació
    function EvaluateFilter(const ANode: TNodeData;
      const AFilterRules: TArray<TFilterRule>): TFilterResult;
    function CompareNodes(const A, B: TNodeData;
      const ASortRules: TArray<TSortRule>): Integer;

    // Ordenar una llista de nodes amb les regles actives
    procedure SortNodes(var ANodes: TArray<TNodeData>);
    // Filtrar nodes
    procedure FilterNodes(const ANodes: TArray<TNodeData>;
      out AIncluded: TArray<TNodeData>;
      out AForcedCentre: TDictionary<Integer, Integer>);  // DataId -> CentreId
    // Agrupar nodes: retorna llista ordenada per grups (OTs amb mateixos valors juntes)
    // AForceSameCenter: DataId -> GroupKey (OTs amb mateix GroupKey haurien d'anar al mateix centre)
    procedure GroupNodes(var ANodes: TArray<TNodeData>;
      out AForceSameCenter: TDictionary<string, TList<Integer>>);

    // Persistència
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string = '');

    property FileName: string read FFileName write FFileName;
    property CustomFieldDefs: TCustomFieldDefs read FCustomFieldDefs write FCustomFieldDefs;
  end;

  // Helpers d'operadors per UI
  function FilterOperatorToStr(O: TFilterOperator): string;
  function FilterActionToStr(A: TFilterAction): string;
  function SortDirectionToStr(D: TSortDirection): string;
  function GroupModeToStr(M: TGroupMode): string;

implementation

{ ═══════════════════════════════════════════════════ }
{  Helpers UI                                         }
{ ═══════════════════════════════════════════════════ }

function FilterOperatorToStr(O: TFilterOperator): string;
begin
  case O of
    foEquals:       Result := '=';
    foNotEquals:    Result := '<>';
    foGreater:      Result := '>';
    foGreaterEqual: Result := '>=';
    foLess:         Result := '<';
    foLessEqual:    Result := '<=';
    foContains:     Result := 'contiene';
    foIn:           Result := 'en lista';
  else
    Result := '=';
  end;
end;

function FilterActionToStr(A: TFilterAction): string;
begin
  case A of
    faInclude:     Result := 'Incluir';
    faExclude:     Result := 'Excluir';
    faForceCenter: Result := 'Forzar centro';
  else
    Result := 'Incluir';
  end;
end;

function SortDirectionToStr(D: TSortDirection): string;
begin
  case D of
    sdAsc:  Result := 'Ascendente';
    sdDesc: Result := 'Descendente';
  else
    Result := 'Ascendente';
  end;
end;

function GroupModeToStr(M: TGroupMode): string;
begin
  case M of
    gmSameCenter:  Result := 'Mismo centro';
    gmConsecutive: Result := 'Consecutivas';
  else
    Result := 'Mismo centro';
  end;
end;

{ ═══════════════════════════════════════════════════ }
{  Builtin fields                                     }
{ ═══════════════════════════════════════════════════ }

class function TPlanningRuleEngine.GetBuiltinFieldNames: TArray<string>;
begin
  Result := TArray<string>.Create(
    'Prioridad',
    'FechaEntrega',
    'FechaNecesaria',
    'DurationMin',
    'CodigoArticulo',
    'DescripcionArticulo',
    'CodigoCliente',
    'CodigoColor',
    'CodigoTalla',
    'UnidadesAFabricar',
    'UnidadesFabricadas',
    'Stock',
    'Estado',
    'NumeroOrdenFabricacion',
    'NumeroPedido',
    'NumeroTrabajo',
    'Operacion',
    'PorcentajeDependencia',
    'OperariosNecesarios'
  );
end;

class function TPlanningRuleEngine.GetBuiltinFieldValue(const ANode: TNodeData;
  const AFieldName: string): Variant;
begin
  if SameText(AFieldName, 'Prioridad') then Result := ANode.Prioridad
  else if SameText(AFieldName, 'FechaEntrega') then Result := ANode.FechaEntrega
  else if SameText(AFieldName, 'FechaNecesaria') then Result := ANode.FechaNecesaria
  else if SameText(AFieldName, 'DurationMin') then Result := ANode.DurationMin
  else if SameText(AFieldName, 'CodigoArticulo') then Result := ANode.CodigoArticulo
  else if SameText(AFieldName, 'DescripcionArticulo') then Result := ANode.DescripcionArticulo
  else if SameText(AFieldName, 'CodigoCliente') then Result := ANode.CodigoCliente
  else if SameText(AFieldName, 'CodigoColor') then Result := ANode.CodigoColor
  else if SameText(AFieldName, 'CodigoTalla') then Result := ANode.CodigoTalla
  else if SameText(AFieldName, 'UnidadesAFabricar') then Result := ANode.UnidadesAFabricar
  else if SameText(AFieldName, 'UnidadesFabricadas') then Result := ANode.UnidadesFabricadas
  else if SameText(AFieldName, 'Stock') then Result := ANode.Stock
  else if SameText(AFieldName, 'Estado') then Result := Ord(ANode.Estado)
  else if SameText(AFieldName, 'NumeroOrdenFabricacion') then Result := ANode.NumeroOrdenFabricacion
  else if SameText(AFieldName, 'NumeroPedido') then Result := ANode.NumeroPedido
  else if SameText(AFieldName, 'NumeroTrabajo') then Result := ANode.NumeroTrabajo
  else if SameText(AFieldName, 'Operacion') then Result := ANode.Operacion
  else if SameText(AFieldName, 'PorcentajeDependencia') then Result := ANode.PorcentajeDependencia
  else if SameText(AFieldName, 'OperariosNecesarios') then Result := ANode.OperariosNecesarios
  else Result := Null;
end;

class function TPlanningRuleEngine.GetFieldValue(const ANode: TNodeData;
  const AFieldName: string): Variant;
begin
  Result := GetBuiltinFieldValue(ANode, AFieldName);
  if VarIsNull(Result) then
    Result := GetCustomFieldValue(ANode.CustomFields, AFieldName);
end;

{ ═══════════════════════════════════════════════════ }
{  Constructor / Destructor                           }
{ ═══════════════════════════════════════════════════ }

constructor TPlanningRuleEngine.Create(ACustomFieldDefs: TCustomFieldDefs);
begin
  inherited Create;
  FProfiles := TList<TPlanningProfile>.Create;
  FActiveIndex := -1;
  FCustomFieldDefs := ACustomFieldDefs;
end;

destructor TPlanningRuleEngine.Destroy;
begin
  FProfiles.Free;
  inherited;
end;

{ ═══════════════════════════════════════════════════ }
{  Available fields                                   }
{ ═══════════════════════════════════════════════════ }

function TPlanningRuleEngine.GetAvailableFields: TArray<string>;
var
  Builtin: TArray<string>;
  Defs: TArray<TCustomFieldDef>;
  I, N: Integer;
begin
  Builtin := GetBuiltinFieldNames;
  if FCustomFieldDefs <> nil then
    Defs := FCustomFieldDefs.GetAllDefs
  else
    SetLength(Defs, 0);

  SetLength(Result, Length(Builtin) + Length(Defs));
  for I := 0 to High(Builtin) do
    Result[I] := Builtin[I];
  N := Length(Builtin);
  for I := 0 to High(Defs) do
    Result[N + I] := Defs[I].FieldName;
end;

{ ═══════════════════════════════════════════════════ }
{  Profiles                                           }
{ ═══════════════════════════════════════════════════ }

procedure TPlanningRuleEngine.AddProfile(const AProfile: TPlanningProfile);
begin
  FProfiles.Add(AProfile);
  if FActiveIndex < 0 then
    FActiveIndex := 0;
end;

procedure TPlanningRuleEngine.UpdateProfile(AIndex: Integer; const AProfile: TPlanningProfile);
begin
  if (AIndex >= 0) and (AIndex < FProfiles.Count) then
    FProfiles[AIndex] := AProfile;
end;

procedure TPlanningRuleEngine.DeleteProfile(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FProfiles.Count) then
  begin
    FProfiles.Delete(AIndex);
    if FActiveIndex >= FProfiles.Count then
      FActiveIndex := FProfiles.Count - 1;
  end;
end;

function TPlanningRuleEngine.ProfileCount: Integer;
begin
  Result := FProfiles.Count;
end;

function TPlanningRuleEngine.GetProfile(AIndex: Integer): TPlanningProfile;
begin
  Result := FProfiles[AIndex];
end;

function TPlanningRuleEngine.GetActiveProfile: TPlanningProfile;
begin
  if (FActiveIndex >= 0) and (FActiveIndex < FProfiles.Count) then
    Result := FProfiles[FActiveIndex]
  else
  begin
    Result.Name := '';
    SetLength(Result.SortRules, 0);
    SetLength(Result.FilterRules, 0);
  end;
end;

{ ═══════════════════════════════════════════════════ }
{  Evaluation — Filter                                }
{ ═══════════════════════════════════════════════════ }

function TPlanningRuleEngine.EvaluateFilter(const ANode: TNodeData;
  const AFilterRules: TArray<TFilterRule>): TFilterResult;
var
  I: Integer;
  R: TFilterRule;
  FVal, RVal: Variant;
  Match: Boolean;
  SField, SValue: string;
begin
  Result.Include := True;
  Result.ForcedCentreId := -1;

  for I := 0 to High(AFilterRules) do
  begin
    R := AFilterRules[I];
    if not R.Enabled then Continue;

    FVal := GetFieldValue(ANode, R.FieldName);
    RVal := R.Value;

    // Comparar
    Match := False;
    try
      case R.Operator of
        foEquals:
          Match := (VarCompareValue(FVal, RVal) = vrEqual);
        foNotEquals:
          Match := (VarCompareValue(FVal, RVal) <> vrEqual);
        foGreater:
          Match := (VarCompareValue(FVal, RVal) = vrGreaterThan);
        foGreaterEqual:
          Match := (VarCompareValue(FVal, RVal) in [vrEqual, vrGreaterThan]);
        foLess:
          Match := (VarCompareValue(FVal, RVal) = vrLessThan);
        foLessEqual:
          Match := (VarCompareValue(FVal, RVal) in [vrEqual, vrLessThan]);
        foContains:
        begin
          SField := VarToStr(FVal);
          SValue := VarToStr(RVal);
          Match := ContainsText(SField, SValue);
        end;
        foIn:
        begin
          SField := VarToStr(FVal);
          SValue := VarToStr(RVal);
          Match := ContainsText(',' + SValue + ',', ',' + SField + ',');
        end;
      end;
    except
      Match := False;
    end;

    // Aplicar acció
    if Match then
    begin
      case R.Action of
        faExclude:
        begin
          Result.Include := False;
          Exit;
        end;
        faForceCenter:
          Result.ForcedCentreId := R.TargetCentreId;
        faInclude:
          ; // simplement passa
      end;
    end
    else
    begin
      // Si l'acció és Include i no compleix -> excloure
      if R.Action = faInclude then
      begin
        Result.Include := False;
        Exit;
      end;
    end;
  end;
end;

{ ═══════════════════════════════════════════════════ }
{  Evaluation — Sort compare                          }
{ ═══════════════════════════════════════════════════ }

function TPlanningRuleEngine.CompareNodes(const A, B: TNodeData;
  const ASortRules: TArray<TSortRule>): Integer;
var
  I: Integer;
  R: TSortRule;
  VA, VB: Variant;
  CmpResult: TVariantRelationship;
  Sorted: TArray<TSortRule>;
begin
  // Ordenar regles per pes descendent (més pes = s'avalua primer)
  Sorted := Copy(ASortRules, 0, Length(ASortRules));
  for I := 0 to High(Sorted) - 1 do
  begin
    var J: Integer;
    for J := I + 1 to High(Sorted) do
      if Sorted[J].Weight > Sorted[I].Weight then
      begin
        R := Sorted[I];
        Sorted[I] := Sorted[J];
        Sorted[J] := R;
      end;
  end;

  Result := 0;
  for I := 0 to High(Sorted) do
  begin
    R := Sorted[I];
    if not R.Enabled then Continue;

    VA := GetFieldValue(A, R.FieldName);
    VB := GetFieldValue(B, R.FieldName);

    // Nulls al final
    if VarIsNull(VA) and VarIsNull(VB) then Continue;
    if VarIsNull(VA) then begin Result := 1; Exit; end;
    if VarIsNull(VB) then begin Result := -1; Exit; end;

    // Comparar strings case-insensitive
    if VarIsStr(VA) and VarIsStr(VB) then
    begin
      Result := CompareText(VarToStr(VA), VarToStr(VB));
    end
    else
    begin
      try
        CmpResult := VarCompareValue(VA, VB);
        case CmpResult of
          vrEqual:       Result := 0;
          vrLessThan:    Result := -1;
          vrGreaterThan: Result := 1;
        else
          Result := 0;
        end;
      except
        Result := 0;
      end;
    end;

    if R.Direction = sdDesc then
      Result := -Result;

    if Result <> 0 then
      Exit;
  end;
end;

{ ═══════════════════════════════════════════════════ }
{  High-level: Sort + Filter                          }
{ ═══════════════════════════════════════════════════ }

procedure TPlanningRuleEngine.SortNodes(var ANodes: TArray<TNodeData>);
var
  Profile: TPlanningProfile;
  List: TList<TNodeData>;
begin
  Profile := GetActiveProfile;
  if Length(Profile.SortRules) = 0 then Exit;

  List := TList<TNodeData>.Create;
  try
    List.AddRange(ANodes);
    List.Sort(TComparer<TNodeData>.Construct(
      function(const A, B: TNodeData): Integer
      begin
        Result := CompareNodes(A, B, Profile.SortRules);
      end));
    ANodes := List.ToArray;
  finally
    List.Free;
  end;
end;

procedure TPlanningRuleEngine.FilterNodes(const ANodes: TArray<TNodeData>;
  out AIncluded: TArray<TNodeData>;
  out AForcedCentre: TDictionary<Integer, Integer>);
var
  Profile: TPlanningProfile;
  I: Integer;
  FR: TFilterResult;
  Included: TList<TNodeData>;
begin
  Profile := GetActiveProfile;
  AForcedCentre := TDictionary<Integer, Integer>.Create;
  Included := TList<TNodeData>.Create;
  try
    for I := 0 to High(ANodes) do
    begin
      if Length(Profile.FilterRules) > 0 then
        FR := EvaluateFilter(ANodes[I], Profile.FilterRules)
      else
      begin
        FR.Include := True;
        FR.ForcedCentreId := -1;
      end;

      if FR.Include then
      begin
        Included.Add(ANodes[I]);
        if FR.ForcedCentreId >= 0 then
          AForcedCentre.AddOrSetValue(ANodes[I].DataId, FR.ForcedCentreId);
      end;
    end;
    AIncluded := Included.ToArray;
  finally
    Included.Free;
  end;
end;

{ ═══════════════════════════════════════════════════ }
{  Grouping                                           }
{ ═══════════════════════════════════════════════════ }

procedure TPlanningRuleEngine.GroupNodes(var ANodes: TArray<TNodeData>;
  out AForceSameCenter: TDictionary<string, TList<Integer>>);
var
  Profile: TPlanningProfile;
  Rules: TArray<TGroupRule>;
  I, J, K: Integer;
  GR: TGroupRule;
  GroupKey: string;
  V: Variant;
  Groups: TDictionary<string, TList<Integer>>; // GroupKey -> list of indices
  KeyList: TList<string>;
  Ordered: TList<TNodeData>;
  Tmp: TGroupRule;
begin
  Profile := GetActiveProfile;
  AForceSameCenter := TDictionary<string, TList<Integer>>.Create;

  if Length(Profile.GroupRules) = 0 then Exit;

  // Filtrar regles actives i ordenar per pes descendent
  Rules := Copy(Profile.GroupRules, 0, Length(Profile.GroupRules));
  for I := 0 to High(Rules) - 1 do
    for J := I + 1 to High(Rules) do
      if Rules[J].Weight > Rules[I].Weight then
      begin
        Tmp := Rules[I];
        Rules[I] := Rules[J];
        Rules[J] := Tmp;
      end;

  // Construir clau de grup composta per cada node
  Groups := TDictionary<string, TList<Integer>>.Create;
  KeyList := TList<string>.Create;
  try
    for I := 0 to High(ANodes) do
    begin
      GroupKey := '';
      for J := 0 to High(Rules) do
      begin
        GR := Rules[J];
        if not GR.Enabled then Continue;
        V := GetFieldValue(ANodes[I], GR.FieldName);
        if GroupKey <> '' then GroupKey := GroupKey + '|';
        GroupKey := GroupKey + GR.FieldName + '=' + VarToStr(V);
      end;

      if GroupKey = '' then Continue;

      if not Groups.ContainsKey(GroupKey) then
      begin
        Groups.Add(GroupKey, TList<Integer>.Create);
        KeyList.Add(GroupKey);
      end;
      Groups[GroupKey].Add(I);
    end;

    // Reordenar: primer els nodes agrupats (en ordre de grup), després els sense grup
    Ordered := TList<TNodeData>.Create;
    try
      var Assigned: TDictionary<Integer, Boolean>;
      Assigned := TDictionary<Integer, Boolean>.Create;
      try
        for I := 0 to KeyList.Count - 1 do
        begin
          var Indices: TList<Integer>;
          Indices := Groups[KeyList[I]];

          // Registrar per gmSameCenter
          for J := 0 to High(Rules) do
          begin
            if not Rules[J].Enabled then Continue;
            if Rules[J].Mode = gmSameCenter then
            begin
              // Crear entrada a AForceSameCenter
              var SCKey: string := KeyList[I];
              if not AForceSameCenter.ContainsKey(SCKey) then
                AForceSameCenter.Add(SCKey, TList<Integer>.Create);
              for K := 0 to Indices.Count - 1 do
                AForceSameCenter[SCKey].Add(ANodes[Indices[K]].DataId);
              Break; // una sola regla gmSameCenter ja agrupa
            end;
          end;

          // Afegir nodes del grup consecutivament
          for K := 0 to Indices.Count - 1 do
          begin
            Ordered.Add(ANodes[Indices[K]]);
            Assigned.AddOrSetValue(Indices[K], True);
          end;
        end;

        // Afegir nodes sense grup al final
        for I := 0 to High(ANodes) do
          if not Assigned.ContainsKey(I) then
            Ordered.Add(ANodes[I]);

        ANodes := Ordered.ToArray;
      finally
        Assigned.Free;
      end;
    finally
      Ordered.Free;
    end;
  finally
    for var Pair in Groups do
      Pair.Value.Free;
    Groups.Free;
    KeyList.Free;
  end;
end;

{ ═══════════════════════════════════════════════════ }
{  JSON helpers                                       }
{ ═══════════════════════════════════════════════════ }

function TPlanningRuleEngine.DirectionToStr(D: TSortDirection): string;
begin
  if D = sdDesc then Result := 'desc' else Result := 'asc';
end;

function TPlanningRuleEngine.StrToDirection(const S: string): TSortDirection;
begin
  if SameText(S, 'desc') then Result := sdDesc else Result := sdAsc;
end;

function TPlanningRuleEngine.OperatorToStr(O: TFilterOperator): string;
begin
  case O of
    foEquals:       Result := 'eq';
    foNotEquals:    Result := 'neq';
    foGreater:      Result := 'gt';
    foGreaterEqual: Result := 'gte';
    foLess:         Result := 'lt';
    foLessEqual:    Result := 'lte';
    foContains:     Result := 'contains';
    foIn:           Result := 'in';
  else
    Result := 'eq';
  end;
end;

function TPlanningRuleEngine.StrToOperator(const S: string): TFilterOperator;
begin
  if SameText(S, 'neq') then Result := foNotEquals
  else if SameText(S, 'gt') then Result := foGreater
  else if SameText(S, 'gte') then Result := foGreaterEqual
  else if SameText(S, 'lt') then Result := foLess
  else if SameText(S, 'lte') then Result := foLessEqual
  else if SameText(S, 'contains') then Result := foContains
  else if SameText(S, 'in') then Result := foIn
  else Result := foEquals;
end;

function TPlanningRuleEngine.ActionToStr(A: TFilterAction): string;
begin
  case A of
    faExclude:     Result := 'exclude';
    faForceCenter: Result := 'forceCenter';
  else
    Result := 'include';
  end;
end;

function TPlanningRuleEngine.StrToAction(const S: string): TFilterAction;
begin
  if SameText(S, 'exclude') then Result := faExclude
  else if SameText(S, 'forceCenter') then Result := faForceCenter
  else Result := faInclude;
end;

function TPlanningRuleEngine.GroupModeToJSON(M: TGroupMode): string;
begin
  if M = gmConsecutive then Result := 'consecutive'
  else Result := 'sameCenter';
end;

function TPlanningRuleEngine.JSONToGroupMode(const S: string): TGroupMode;
begin
  if SameText(S, 'consecutive') then Result := gmConsecutive
  else Result := gmSameCenter;
end;

{ ═══════════════════════════════════════════════════ }
{  Persistència JSON                                  }
{ ═══════════════════════════════════════════════════ }

procedure TPlanningRuleEngine.LoadFromFile(const AFileName: string);
var
  JSON: string;
  JRoot, JProfile, JSortObj, JFilterObj: TJSONObject;
  JProfiles, JSorts, JFilters: TJSONArray;
  I, J: Integer;
  P: TPlanningProfile;
  SR: TSortRule;
  FR: TFilterRule;
begin
  FFileName := AFileName;
  FProfiles.Clear;
  FActiveIndex := -1;

  if not TFile.Exists(AFileName) then Exit;

  JSON := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  JRoot := TJSONObject.ParseJSONValue(JSON) as TJSONObject;
  if JRoot = nil then Exit;
  try
    FActiveIndex := JRoot.GetValue<Integer>('activeIndex', 0);

    if not JRoot.TryGetValue<TJSONArray>('profiles', JProfiles) then Exit;

    for I := 0 to JProfiles.Count - 1 do
    begin
      JProfile := JProfiles.Items[I] as TJSONObject;
      P.Name := JProfile.GetValue<string>('name', '');
      P.Description := JProfile.GetValue<string>('description', '');

      // Sort rules
      SetLength(P.SortRules, 0);
      if JProfile.TryGetValue<TJSONArray>('sortRules', JSorts) then
      begin
        SetLength(P.SortRules, JSorts.Count);
        for J := 0 to JSorts.Count - 1 do
        begin
          JSortObj := JSorts.Items[J] as TJSONObject;
          SR.FieldName := JSortObj.GetValue<string>('field', '');
          SR.Direction := StrToDirection(JSortObj.GetValue<string>('direction', 'asc'));
          SR.Weight := JSortObj.GetValue<Integer>('weight', 5);
          SR.Enabled := JSortObj.GetValue<Boolean>('enabled', True);
          P.SortRules[J] := SR;
        end;
      end;

      // Filter rules
      SetLength(P.FilterRules, 0);
      if JProfile.TryGetValue<TJSONArray>('filterRules', JFilters) then
      begin
        SetLength(P.FilterRules, JFilters.Count);
        for J := 0 to JFilters.Count - 1 do
        begin
          JFilterObj := JFilters.Items[J] as TJSONObject;
          FR.FieldName := JFilterObj.GetValue<string>('field', '');
          FR.Operator := StrToOperator(JFilterObj.GetValue<string>('operator', 'eq'));
          FR.Value := JFilterObj.GetValue<string>('value', '');
          FR.Action := StrToAction(JFilterObj.GetValue<string>('action', 'include'));
          FR.TargetCentreId := JFilterObj.GetValue<Integer>('targetCentreId', -1);
          FR.Enabled := JFilterObj.GetValue<Boolean>('enabled', True);
          P.FilterRules[J] := FR;
        end;
      end;

      // Group rules
      SetLength(P.GroupRules, 0);
      var JGroups: TJSONArray;
      if JProfile.TryGetValue<TJSONArray>('groupRules', JGroups) then
      begin
        SetLength(P.GroupRules, JGroups.Count);
        for J := 0 to JGroups.Count - 1 do
        begin
          var JGrpObj: TJSONObject;
          JGrpObj := JGroups.Items[J] as TJSONObject;
          var GRl: TGroupRule;
          GRl.FieldName := JGrpObj.GetValue<string>('field', '');
          GRl.Mode := JSONToGroupMode(JGrpObj.GetValue<string>('mode', 'sameCenter'));
          GRl.Weight := JGrpObj.GetValue<Integer>('weight', 5);
          GRl.Enabled := JGrpObj.GetValue<Boolean>('enabled', True);
          P.GroupRules[J] := GRl;
        end;
      end;

      FProfiles.Add(P);
    end;

    if FActiveIndex >= FProfiles.Count then
      FActiveIndex := FProfiles.Count - 1;
  finally
    JRoot.Free;
  end;
end;

procedure TPlanningRuleEngine.SaveToFile(const AFileName: string);
var
  JRoot: TJSONObject;
  JProfiles, JSorts, JFilters: TJSONArray;
  JProfile, JSortObj, JFilterObj: TJSONObject;
  I, J: Integer;
  P: TPlanningProfile;
  FN: string;
begin
  if AFileName <> '' then FN := AFileName else FN := FFileName;
  if FN = '' then Exit;
  FFileName := FN;

  JRoot := TJSONObject.Create;
  try
    JRoot.AddPair('activeIndex', TJSONNumber.Create(FActiveIndex));

    JProfiles := TJSONArray.Create;
    for I := 0 to FProfiles.Count - 1 do
    begin
      P := FProfiles[I];
      JProfile := TJSONObject.Create;
      JProfile.AddPair('name', P.Name);
      JProfile.AddPair('description', P.Description);

      // Sort rules
      JSorts := TJSONArray.Create;
      for J := 0 to High(P.SortRules) do
      begin
        JSortObj := TJSONObject.Create;
        JSortObj.AddPair('field', P.SortRules[J].FieldName);
        JSortObj.AddPair('direction', DirectionToStr(P.SortRules[J].Direction));
        JSortObj.AddPair('weight', TJSONNumber.Create(P.SortRules[J].Weight));
        JSortObj.AddPair('enabled', TJSONBool.Create(P.SortRules[J].Enabled));
        JSorts.Add(JSortObj);
      end;
      JProfile.AddPair('sortRules', JSorts);

      // Filter rules
      JFilters := TJSONArray.Create;
      for J := 0 to High(P.FilterRules) do
      begin
        JFilterObj := TJSONObject.Create;
        JFilterObj.AddPair('field', P.FilterRules[J].FieldName);
        JFilterObj.AddPair('operator', OperatorToStr(P.FilterRules[J].Operator));
        JFilterObj.AddPair('value', VarToStr(P.FilterRules[J].Value));
        JFilterObj.AddPair('action', ActionToStr(P.FilterRules[J].Action));
        JFilterObj.AddPair('targetCentreId', TJSONNumber.Create(P.FilterRules[J].TargetCentreId));
        JFilterObj.AddPair('enabled', TJSONBool.Create(P.FilterRules[J].Enabled));
        JFilters.Add(JFilterObj);
      end;
      JProfile.AddPair('filterRules', JFilters);

      // Group rules
      var JGroupsOut: TJSONArray;
      JGroupsOut := TJSONArray.Create;
      for J := 0 to High(P.GroupRules) do
      begin
        var JGrpOut: TJSONObject;
        JGrpOut := TJSONObject.Create;
        JGrpOut.AddPair('field', P.GroupRules[J].FieldName);
        JGrpOut.AddPair('mode', GroupModeToJSON(P.GroupRules[J].Mode));
        JGrpOut.AddPair('weight', TJSONNumber.Create(P.GroupRules[J].Weight));
        JGrpOut.AddPair('enabled', TJSONBool.Create(P.GroupRules[J].Enabled));
        JGroupsOut.Add(JGrpOut);
      end;
      JProfile.AddPair('groupRules', JGroupsOut);

      JProfiles.Add(JProfile);
    end;

    JRoot.AddPair('profiles', JProfiles);

    TFile.WriteAllText(FN, JRoot.Format(2), TEncoding.UTF8);
  finally
    JRoot.Free;
  end;
end;

end.
