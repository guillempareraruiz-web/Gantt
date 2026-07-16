unit uSetupRules;

{
  Motor de tiempo de cambio (setup) SECUENCIA-DEPENDIENTE, generico por
  atributos.

  Idea: el tiempo muerto entre dos trabajos consecutivos en la misma linea
  depende de EN QUE se diferencian. Cada cliente define reglas del tipo:

     "si cambia el atributo <X> de un trabajo al siguiente -> +N minutos"

  Los atributos pueden ser campos builtin (CodigoArticulo, CodigoColor...) o
  campos personalizados (Substrato, AnchoBobina, Molde, Herramienta...). Asi el
  mismo motor sirve para impresion (color/substrato), inyeccion (molde),
  mecanizado (herramienta), textil, etc. sin hardcodear nada.

  Las reglas son ADITIVAS: si un cambio dispara varias reglas, los minutos se
  suman (cambiar de color Y de substrato cuesta la suma de ambos).

  FASE 1 (este unit): calculo del tiempo de cambio. El scheduler lo usa para
  dejar el hueco REAL entre nodos consecutivos, de modo que el plan refleje el
  tiempo de cambio de verdad.

  FASE 2 (pendiente): que el optimizador (uPlanOptimizer, SA) MINIMICE la suma
  de setups, y editor visual + KPI de "tiempo de cambio". Ver memoria
  project_gantt_setup_secuencia_dependiente.

  Persistencia: perfil en JSON (a INI/BD via connector) y/o tabla
  FS_PL_SetupRule. El engine es agnostico del almacenamiento: se le cargan las
  reglas y calcula.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.JSON, System.StrUtils, System.Variants,
  uGanttTypes;

type
  // Conjunto de atributos de un trabajo, relevantes para el setup.
  // Clave = nombre del atributo (case-insensitive), Valor = su valor como texto.
  // El caller lo rellena desde TNodeData (builtin + CustomFields).
  TSetupAttrs = TDictionary<string, string>;

  // Version value-type (se copia con el record que la contiene, sin gestion de
  // vida): la usan TSchedInput/TLaneSlot para arrastrar los atributos del nodo.
  TSetupPair = record
    Name: string;
    Value: string;
  end;
  TSetupAttrList = TArray<TSetupPair>;

  // Una regla: "si cambia AttrName -> sumar SetupMin minutos".
  TSetupRule = record
    AttrName: string;      // nombre del atributo que dispara el cambio
    SetupMin: Integer;     // minutos de setup si ese atributo cambia
    CentreCode: string;    // '' = aplica a todas las lineas; si no, solo a esa
    Enabled: Boolean;
  end;

  TSetupProfile = record
    Name: string;
    Rules: TArray<TSetupRule>;
  end;

  { TSetupRuleEngine
    Se carga con un perfil de reglas y responde CalcSetupMin(prev, curr, centre).
    Es reutilizable en el scheduler y (fase 2) en el optimizador. }
  TSetupRuleEngine = class
  private
    FRules: TArray<TSetupRule>;
    FDefaultMin: Integer;   // suelo minimo entre nodos aunque nada cambie (>=0)
    // Compara el valor del atributo AAttr entre prev y curr. Ausente cuenta como
    // cadena vacia; la comparacion es case-insensitive y trim.
    class function ValuesDiffer(APrev, ACurr: TSetupAttrs;
      const AAttr: string): Boolean; static;
    // Busca el valor de un atributo en una lista value-type (case-insensitive).
    class function FindAttr(const AList: TSetupAttrList;
      const AAttr: string; out AValue: string): Boolean; static;
  public
    constructor Create;
    // Carga las reglas activas de un perfil.
    procedure LoadProfile(const AProfile: TSetupProfile);
    procedure SetRules(const ARules: TArray<TSetupRule>);
    property DefaultMin: Integer read FDefaultMin write FDefaultMin;
    function HasRules: Boolean;

    // NUCLEO: minutos de cambio al pasar de APrev a ACurr en la linea ACentreCode.
    // Suma SetupMin de cada regla activa cuyo atributo difiera. Si no hay prev
    // (primer nodo del lane) devuelve 0. Nunca por debajo de DefaultMin.
    function CalcSetupMin(APrev, ACurr: TSetupAttrs;
      const ACentreCode: string): Integer; overload;
    // Overload value-type: el que usa el scheduler. AHasPrev=False -> primer
    // nodo del lane (sin cambio). Evita crear diccionarios en el bucle interno.
    function CalcSetupMin(const APrev, ACurr: TSetupAttrList; AHasPrev: Boolean;
      const ACentreCode: string): Integer; overload;

    // Serializacion JSON del perfil (para persistir en INI/BD).
    class function ProfileToJson(const AProfile: TSetupProfile): string; static;
    class function ProfileFromJson(const AJson: string): TSetupProfile; static;
  end;

// Helper: construir un TSetupAttrs a partir de pares nombre/valor. El caller es
// responsable de liberarlo (Free).
function MakeSetupAttrs(const APairs: array of string): TSetupAttrs;

// Construye la lista de atributos de setup a partir de un TNodeData: builtin
// relevantes para secuenciacion + campos personalizados del nodo. Generico: el
// motor usa solo los atributos que sus reglas referencien. Centraliza el mapeo
// para que Backlog y Gantt lo hagan igual.
function BuildSetupAttrsFromNode(const ANode: TNodeData): TSetupAttrList;

implementation

uses
  uPlanningRules;   // para GetBuiltinFieldNames/GetFieldValue (mismos atributos
                    // que ofrece el editor de reglas). Sin ciclo: uPlanningRules
                    // no usa uSetupRules.

function MakeSetupAttrs(const APairs: array of string): TSetupAttrs;
var
  I: Integer;
begin
  Result := TSetupAttrs.Create(TIStringComparer.Ordinal);
  I := 0;
  while I + 1 <= High(APairs) do
  begin
    Result.AddOrSetValue(APairs[I], APairs[I + 1]);
    Inc(I, 2);
  end;
end;

// LIMITACION CONOCIDA: no emite el atributo 'Utillaje'. El requisito de
// utillaje no vive en el TNodeData: se deduce en BD de la operacion/articulo
// (FS_PL_V_NodeUtillaje, V073), y esta funcion no puede tocar BD (la llama
// tambien el Gantt al arrastrar). Consecuencia: una regla de tiempo de cambio
// sobre 'Utillaje' aplica al planificar desde el Backlog (que si carga las
// reglas, ver uBacklog.BuildSetupAttrs) pero NO al recolocar desde el Gantt.
// No rompe nada: si el atributo no esta, FindAttr devuelve '' en ambos lados y
// la regla simplemente no dispara.
function BuildSetupAttrsFromNode(const ANode: TNodeData): TSetupAttrList;
var
  L: TList<TSetupPair>;
  P: TSetupPair;
  I: Integer;
begin
  L := TList<TSetupPair>.Create;
  try
    // Builtin: TODOS los que ofrece el editor de reglas, resueltos con la MISMA
    // funcion (GetBuiltinFieldValue), para que cualquier campo listado en el
    // combo del editor detecte cambio. Si no, una regla sobre un campo no
    // expuesto aqui nunca detectaria diferencia (KPI/franja siempre 0).
    var Builtins := TPlanningRuleEngine.GetBuiltinFieldNames;
    for I := 0 to High(Builtins) do
    begin
      P.Name := Builtins[I];
      P.Value := VarToStr(TPlanningRuleEngine.GetFieldValue(ANode, Builtins[I]));
      L.Add(P);
    end;
    // Campos personalizados del nodo (Substrato, AnchoBobina, Molde...).
    for I := 0 to High(ANode.CustomFields) do
    begin
      P.Name := ANode.CustomFields[I].FieldName;
      P.Value := VarToStr(ANode.CustomFields[I].Value);
      L.Add(P);
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

{ TSetupRuleEngine }

constructor TSetupRuleEngine.Create;
begin
  inherited Create;
  SetLength(FRules, 0);
  FDefaultMin := 0;
end;

procedure TSetupRuleEngine.LoadProfile(const AProfile: TSetupProfile);
begin
  SetRules(AProfile.Rules);
end;

procedure TSetupRuleEngine.SetRules(const ARules: TArray<TSetupRule>);
begin
  FRules := Copy(ARules, 0, Length(ARules));
end;

function TSetupRuleEngine.HasRules: Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FRules) do
    if FRules[I].Enabled then Exit(True);
  Result := False;
end;

class function TSetupRuleEngine.ValuesDiffer(APrev, ACurr: TSetupAttrs;
  const AAttr: string): Boolean;
var
  VP, VC: string;
begin
  if (APrev = nil) or not APrev.TryGetValue(AAttr, VP) then VP := '';
  if (ACurr = nil) or not ACurr.TryGetValue(AAttr, VC) then VC := '';
  Result := not SameText(Trim(VP), Trim(VC));
end;

function TSetupRuleEngine.CalcSetupMin(APrev, ACurr: TSetupAttrs;
  const ACentreCode: string): Integer;
var
  I: Integer;
  R: TSetupRule;
begin
  Result := 0;
  // Sin nodo anterior no hay cambio (primer trabajo del lane).
  if APrev = nil then
    Exit(FDefaultMin);

  for I := 0 to High(FRules) do
  begin
    R := FRules[I];
    if not R.Enabled then Continue;
    // Filtro por linea: '' aplica a todas; si no, solo si coincide el centro.
    if (R.CentreCode <> '') and not SameText(Trim(R.CentreCode), Trim(ACentreCode)) then
      Continue;
    if R.AttrName = '' then Continue;
    if ValuesDiffer(APrev, ACurr, R.AttrName) then
      Inc(Result, R.SetupMin);
  end;

  if Result < FDefaultMin then Result := FDefaultMin;
end;

class function TSetupRuleEngine.FindAttr(const AList: TSetupAttrList;
  const AAttr: string; out AValue: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(AList) do
    if SameText(AList[I].Name, AAttr) then
    begin
      AValue := AList[I].Value;
      Exit(True);
    end;
  AValue := '';
  Result := False;
end;

function TSetupRuleEngine.CalcSetupMin(const APrev, ACurr: TSetupAttrList;
  AHasPrev: Boolean; const ACentreCode: string): Integer;
var
  I: Integer;
  R: TSetupRule;
  VP, VC: string;
begin
  Result := 0;
  // Sin nodo anterior no hay cambio (primer trabajo del lane).
  if not AHasPrev then
    Exit(FDefaultMin);

  for I := 0 to High(FRules) do
  begin
    R := FRules[I];
    if not R.Enabled then Continue;
    if (R.CentreCode <> '') and not SameText(Trim(R.CentreCode), Trim(ACentreCode)) then
      Continue;
    if R.AttrName = '' then Continue;
    FindAttr(APrev, R.AttrName, VP);
    FindAttr(ACurr, R.AttrName, VC);
    if not SameText(Trim(VP), Trim(VC)) then
      Inc(Result, R.SetupMin);
  end;

  if Result < FDefaultMin then Result := FDefaultMin;
end;

class function TSetupRuleEngine.ProfileToJson(
  const AProfile: TSetupProfile): string;
var
  Root, RuleObj: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('name', AProfile.Name);
    Arr := TJSONArray.Create;
    for I := 0 to High(AProfile.Rules) do
    begin
      RuleObj := TJSONObject.Create;
      RuleObj.AddPair('attr', AProfile.Rules[I].AttrName);
      RuleObj.AddPair('min', TJSONNumber.Create(AProfile.Rules[I].SetupMin));
      RuleObj.AddPair('centre', AProfile.Rules[I].CentreCode);
      RuleObj.AddPair('enabled', TJSONBool.Create(AProfile.Rules[I].Enabled));
      Arr.AddElement(RuleObj);
    end;
    Root.AddPair('rules', Arr);
    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

class function TSetupRuleEngine.ProfileFromJson(
  const AJson: string): TSetupProfile;
var
  Root: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
  RuleVal: TJSONValue;
  RuleObj: TJSONObject;
  L: TList<TSetupRule>;
  R: TSetupRule;
begin
  Result.Name := '';
  SetLength(Result.Rules, 0);
  if Trim(AJson) = '' then Exit;

  Root := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  if Root = nil then Exit;
  L := TList<TSetupRule>.Create;
  try
    Result.Name := Root.GetValue<string>('name', '');
    if Root.TryGetValue<TJSONArray>('rules', Arr) then
      for I := 0 to Arr.Count - 1 do
      begin
        RuleVal := Arr.Items[I];
        if not (RuleVal is TJSONObject) then Continue;
        RuleObj := TJSONObject(RuleVal);
        R.AttrName := RuleObj.GetValue<string>('attr', '');
        R.SetupMin := StrToIntDef(RuleObj.GetValue<string>('min', '0'), 0);
        R.CentreCode := RuleObj.GetValue<string>('centre', '');
        R.Enabled := RuleObj.GetValue<Boolean>('enabled', True);
        L.Add(R);
      end;
    Result.Rules := L.ToArray;
  finally
    L.Free;
    Root.Free;
  end;
end;

end.
