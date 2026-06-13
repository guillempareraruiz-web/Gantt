unit uGanttHintConfig;

{
  Configuracion del HINT (informacion emergente) de los nodos del Gantt.

  Define QUE campos ve el usuario al pasar el raton sobre un nodo y EN QUE ORDEN,
  con un layout POR VISTA (TGanttViewMode), igual que el Node Layout
  (uNodeCardLayout). A diferencia del Node Layout, aqui NO hay maquetacion 2D
  (filas, ancho %, alineacion): el hint es una simple LISTA lineal de campos
  "Etiqueta: valor", asi que el modelo solo guarda, por vista, una lista
  ordenada de campos con un flag de visibilidad.

  El conjunto (THintConfigSet) es lo que se persiste y edita, uno por usuario
  (ver uGanttHintConfigRepo, tabla FS_PL_HintConfigSet, V060).

  Los nombres de campo son los mismos que GetAvailableFields del Card/Node
  (vocabulario unico). La etiqueta legible se obtiene de HintFieldCaption, y el
  valor formateado mediante un TCardFieldResolver (uCardLayout), de modo que el
  texto del hint se genera con BuildHintText sin tocar el render del Gantt.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  uGanttTypes, uCardLayout;

type
  // Un campo del hint: nombre tecnico + si se muestra. El ORDEN en el array es
  // el orden de aparicion en el hint.
  THintField = record
    FieldName: string;
    Visible: Boolean;
  end;

  // Layout del hint para UNA vista: lista ordenada de campos.
  THintLayout = record
    Fields: TArray<THintField>;
  end;

  // Conjunto de layouts: uno por Vista. Es lo que se persiste y edita.
  THintConfigSet = record
    Layouts: array[TGanttViewMode] of THintLayout;
  end;

// --- Vistas (re-export para no depender de uNodeCardLayout en la UI) ---

function HintGanttViewModeCaption(V: TGanttViewMode): string;

// --- Catalogo de campos disponibles + etiquetas legibles ---

// Lista canonica de campos que se pueden mostrar en el hint. Es el mismo
// vocabulario que GetAvailableFields del Card/Node, replicado aqui para no
// crear dependencia con uCardLayoutEditor (que es de UI).
function HintAvailableFields: TArray<string>;

// Etiqueta legible (castellano) para un nombre de campo tecnico.
function HintFieldCaption(const AFieldName: string): string;

// --- Generacion del texto del hint ---

// Construye el texto "Etiqueta: valor" (una linea por campo visible, en orden)
// resolviendo cada valor con AResolver. Si el layout no tiene campos, devuelve ''.
function BuildHintText(const ALayout: THintLayout;
  AResolver: TCardFieldResolver): string;

// --- Defaults ---

function DefaultHintLayoutFor(V: TGanttViewMode): THintLayout;
function DefaultHintConfigSet: THintConfigSet;

// --- Persistencia JSON ---

function HintConfigSetToJSON(const ASet: THintConfigSet): TJSONObject;
function JSONToHintConfigSet(const AJson: TJSONObject): THintConfigSet;

implementation

uses
  System.Variants, System.StrUtils,
  uNodeCardLayout;   // reutiliza GanttViewModeToStr / StrToGanttViewMode

{ ---- Vistas ---- }

function HintGanttViewModeCaption(V: TGanttViewMode): string;
begin
  Result := GanttViewModeCaption(V);
end;

{ ---- Catalogo de campos ---- }

function HintAvailableFields: TArray<string>;
begin
  // Mismo set base que GetAvailableFields (uCardLayoutEditor). Si en el futuro
  // se quieren campos personalizados aqui, se ampliaria igual que alla.
  Result := TArray<string>.Create(
    'DataId',
    'Operacion',
    'NumeroPedido',
    'SeriePedido',
    'NumeroOrdenFabricacion',
    'SerieFabricacion',
    'NumeroTrabajo',
    'FechaEntrega',
    'FechaNecesaria',
    'CodigoCliente',
    'CodigoColor',
    'CodigoTalla',
    'Stock',
    'CodigoArticulo',
    'DescripcionArticulo',
    'PorcentajeDependencia',
    'UnidadesFabricadas',
    'UnidadesAFabricar',
    'DurationMin',
    'OperariosNecesarios',
    'OperariosAsignados',
    'Estado',
    'Prioridad',
    'Tipo'
  );
end;

function HintFieldCaption(const AFieldName: string): string;
begin
  // Etiqueta en castellano para cada campo. Si no esta mapeado, se usa el propio
  // nombre tecnico como fallback.
  if AFieldName = 'DataId' then Result := 'Id'
  else if AFieldName = 'Operacion' then Result := 'Operaci'#243'n'
  else if AFieldName = 'NumeroPedido' then Result := 'N'#250'mero pedido'
  else if AFieldName = 'SeriePedido' then Result := 'Serie pedido'
  else if AFieldName = 'NumeroOrdenFabricacion' then Result := 'Orden fabricaci'#243'n'
  else if AFieldName = 'SerieFabricacion' then Result := 'Serie fabricaci'#243'n'
  else if AFieldName = 'NumeroTrabajo' then Result := 'Orden trabajo'
  else if AFieldName = 'FechaEntrega' then Result := 'Fecha entrega'
  else if AFieldName = 'FechaNecesaria' then Result := 'Fecha necesaria'
  else if AFieldName = 'CodigoCliente' then Result := 'Cliente'
  else if AFieldName = 'CodigoColor' then Result := 'Color'
  else if AFieldName = 'CodigoTalla' then Result := 'Talla'
  else if AFieldName = 'Stock' then Result := 'Stock'
  else if AFieldName = 'CodigoArticulo' then Result := 'Art'#237'culo'
  else if AFieldName = 'DescripcionArticulo' then Result := 'Descripci'#243'n art'#237'culo'
  else if AFieldName = 'PorcentajeDependencia' then Result := 'Dependencia'
  else if AFieldName = 'UnidadesFabricadas' then Result := 'Unidades fabricadas'
  else if AFieldName = 'UnidadesAFabricar' then Result := 'Unidades a fabricar'
  else if AFieldName = 'DurationMin' then Result := 'Duraci'#243'n (min)'
  else if AFieldName = 'OperariosNecesarios' then Result := 'Operarios necesarios'
  else if AFieldName = 'OperariosAsignados' then Result := 'Operarios asignados'
  else if AFieldName = 'Estado' then Result := 'Estado'
  else if AFieldName = 'Prioridad' then Result := 'Prioridad'
  else if AFieldName = 'Tipo' then Result := 'Tipo'
  else Result := AFieldName;
end;

{ ---- Generacion del texto ---- }

function BuildHintText(const ALayout: THintLayout;
  AResolver: TCardFieldResolver): string;
var
  sb: TStringBuilder;
  i: Integer;
  v: Variant;
  valStr: string;
begin
  Result := '';
  if not Assigned(AResolver) then Exit;

  sb := TStringBuilder.Create;
  try
    for i := 0 to High(ALayout.Fields) do
    begin
      if not ALayout.Fields[i].Visible then Continue;

      // El resolver formatea fechas/numeros/enums segun el campo (uCardLayout).
      v := AResolver(ALayout.Fields[i].FieldName);
      if VarIsNull(v) or VarIsEmpty(v) then
        valStr := ''
      else
        valStr := VarToStr(v);

      if sb.Length > 0 then
        sb.Append(sLineBreak);
      sb.Append(HintFieldCaption(ALayout.Fields[i].FieldName));
      sb.Append(': ');
      sb.Append(valStr);
    end;
    Result := sb.ToString;
  finally
    sb.Free;
  end;
end;

{ ---- Defaults ---- }

// Construye un THintLayout a partir de una lista de nombres (todos visibles).
function MakeLayout(const ANames: array of string): THintLayout;
var
  i: Integer;
begin
  SetLength(Result.Fields, Length(ANames));
  for i := 0 to High(ANames) do
  begin
    Result.Fields[i].FieldName := ANames[i];
    Result.Fields[i].Visible := True;
  end;
end;

function DefaultHintLayoutFor(V: TGanttViewMode): THintLayout;
begin
  // Conjunto sensato por vista (basado en lo que el hint mostraba hardcoded).
  case V of
    gvmFabricacio:
      Result := MakeLayout(['NumeroOrdenFabricacion', 'Operacion', 'Estado',
        'UnidadesFabricadas', 'UnidadesAFabricar', 'OperariosAsignados',
        'OperariosNecesarios', 'DurationMin']);
    gvmFechaEntrega:
      Result := MakeLayout(['NumeroOrdenFabricacion', 'CodigoCliente',
        'FechaEntrega', 'FechaNecesaria', 'CodigoArticulo', 'DescripcionArticulo']);
    gvmStock:
      Result := MakeLayout(['CodigoArticulo', 'DescripcionArticulo', 'Stock',
        'UnidadesAFabricar', 'FechaEntrega']);
    gvmOperarios:
      Result := MakeLayout(['NumeroOrdenFabricacion', 'Operacion',
        'OperariosAsignados', 'OperariosNecesarios', 'DurationMin']);
    gvmEstado:
      Result := MakeLayout(['NumeroOrdenFabricacion', 'Operacion', 'Estado',
        'Prioridad', 'UnidadesFabricadas', 'UnidadesAFabricar']);
    gvmPrioridad:
      Result := MakeLayout(['NumeroOrdenFabricacion', 'Prioridad',
        'FechaEntrega', 'CodigoCliente', 'Operacion']);
  else
    // Normal y resto: ficha completa razonable.
    Result := MakeLayout(['NumeroOrdenFabricacion', 'Operacion', 'CodigoCliente',
      'CodigoArticulo', 'DescripcionArticulo', 'FechaEntrega', 'FechaNecesaria',
      'UnidadesFabricadas', 'UnidadesAFabricar', 'OperariosAsignados',
      'OperariosNecesarios', 'DurationMin', 'Estado']);
  end;
end;

function DefaultHintConfigSet: THintConfigSet;
var
  V: TGanttViewMode;
begin
  Result := Default(THintConfigSet);
  for V := Low(TGanttViewMode) to High(TGanttViewMode) do
    Result.Layouts[V] := DefaultHintLayoutFor(V);
end;

{ ---- JSON ---- }

function HintLayoutToJSON(const ALayout: THintLayout): TJSONArray;
var
  i: Integer;
  o: TJSONObject;
begin
  Result := TJSONArray.Create;
  for i := 0 to High(ALayout.Fields) do
  begin
    o := TJSONObject.Create;
    o.AddPair('field', ALayout.Fields[i].FieldName);
    o.AddPair('visible', TJSONBool.Create(ALayout.Fields[i].Visible));
    Result.Add(o);
  end;
end;

function JSONToHintLayout(const AArr: TJSONArray): THintLayout;
var
  i: Integer;
  o: TJSONObject;
begin
  Result := Default(THintLayout);
  if AArr = nil then Exit;
  SetLength(Result.Fields, AArr.Count);
  for i := 0 to AArr.Count - 1 do
  begin
    o := AArr.Items[i] as TJSONObject;
    Result.Fields[i].FieldName := o.GetValue<string>('field', '');
    Result.Fields[i].Visible := o.GetValue<Boolean>('visible', True);
  end;
end;

function HintConfigSetToJSON(const ASet: THintConfigSet): TJSONObject;
var
  V: TGanttViewMode;
  Layouts: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('version', TJSONNumber.Create(1));
  Layouts := TJSONObject.Create;
  for V := Low(TGanttViewMode) to High(TGanttViewMode) do
    Layouts.AddPair(GanttViewModeToStr(V), HintLayoutToJSON(ASet.Layouts[V]));
  Result.AddPair('layouts', Layouts);
end;

function JSONToHintConfigSet(const AJson: TJSONObject): THintConfigSet;
var
  V: TGanttViewMode;
  Layouts: TJSONObject;
  Val: TJSONValue;
begin
  Result := DefaultHintConfigSet;  // baseline para vistas sin entrada
  if AJson = nil then Exit;
  Layouts := AJson.GetValue<TJSONObject>('layouts');
  if Layouts = nil then Exit;
  for V := Low(TGanttViewMode) to High(TGanttViewMode) do
  begin
    Val := Layouts.GetValue(GanttViewModeToStr(V));
    if (Val <> nil) and (Val is TJSONArray) then
      Result.Layouts[V] := JSONToHintLayout(TJSONArray(Val));
  end;
end;

end.
