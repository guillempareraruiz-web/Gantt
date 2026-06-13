unit uNodeCardLayout;

{
  TNodeCardLayout - Define el contenido visual de un Nodo del Gantt, editable por
  el usuario y por Vista (TGanttViewMode).

  Filosofia identica al Card Layout del backlog (uCardLayout), pero adaptada al
  Nodo del Gantt:
    - El TAMANO del nodo NO es editable (lo impone el Gantt: ancho = duracion,
      alto = lane). Por eso este modelo NO tiene CardHeight ni PaddingV/CornerRadius
      como propiedades "de tamano": solo describe COLORES, BORDE, FUENTE, CAMPOS
      y REGLAS de estilo condicional.
    - Hay un layout por Vista (gvmNormal, gvmFabricacio, ...). El conjunto
      (TNodeLayoutSet) es lo que se persiste y edita, uno por usuario.

  Para no duplicar el motor de pintado, este modelo se CONVIERTE a TCardLayout
  (uCardLayout) via ToCardLayout y se pinta con el RenderCard existente. Asi la
  previsualizacion reutiliza exactamente la misma tecnica que el Card del backlog.
  El render real sobre el Gantt (Direct2D) es una fase posterior y NO depende de
  esta unidad.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.JSON, System.IOUtils,
  Vcl.Graphics,
  uGanttTypes,
  // Reutilizamos tipos y motor del Card Layout: TCardElementKind, TCardHAlign,
  // TStyleRule, TCardLayout, RenderCard, MakeNodeDataResolver, etc.
  uCardLayout;

type
  // Un elemento del nodo: mismo abanico de tipos que el Card (texto, badge,
  // barra de progreso, separador), pero SIN propiedades de tamano vertical.
  TNodeCardElement = record
    Kind: TCardElementKind;
    FieldExpr: string;        // p.ej. 'OF {NumeroOrdenFabricacion} - {Operacion}'
    FontSize: Integer;
    FontBold: Boolean;
    FontItalic: Boolean;
    FontColor: TColor;
    BgColor: TColor;          // para badges; 0 = auto segun BgColorField
    BgColorField: string;     // campo que determina color (ej: 'Prioridad', 'Estado')
    HAlign: TCardHAlign;
    WidthPct: Integer;        // 0=auto, 1-100=porcentaje fijo del ancho
    Visible: Boolean;
    ConditionField: string;   // campo > 0 / no vacio para mostrar
    RoundRadius: Integer;
    StyleRules: TArray<TStyleRule>;  // regles condicionals; la primera que matchi guanya
  end;

  // Una fila del nodo. HeightPx aqui es solo una PISTA de reparto vertical para
  // la previsualizacion; en el Gantt real la altura la marca el lane.
  TNodeCardRow = record
    HeightPx: Integer;
    Spacing: Integer;
    Elements: TArray<TNodeCardElement>;
  end;

  // Layout de UN nodo para UNA vista. Solo describe apariencia y contenido; el
  // tamano lo impone el Gantt.
  TNodeCardLayout = record
    Name: string;
    PaddingH: Integer;        // padding horizontal interno (px)
    PaddingV: Integer;        // padding vertical interno (px) - solo para preview
    CornerRadius: Integer;    // radio de esquina del nodo (px)
    BgColor: TColor;          // 0 = usar el color propio del nodo (OF/estado/etc.)
    BorderColor: TColor;      // 0 = usar el border por defecto del nodo
    BorderWidth: Integer;     // 0 = sin border custom
    // Fuente POR DEFECTO del nodo. Cada elemento puede sobreescribir tamano,
    // color, negrita y cursiva; estos valores se aplican a los elementos que no
    // los fijen (FontSize<=0, FontColor=0). FontName='' = fuente del Gantt.
    FontName: string;
    FontSize: Integer;        // 0 = tamano por defecto del Gantt
    FontColor: TColor;        // 0 = color por defecto (negro)
    FontBold: Boolean;
    FontItalic: Boolean;
    Rows: TArray<TNodeCardRow>;
  end;

  // Conjunto de layouts: uno por Vista. Es lo que se persiste y edita.
  TNodeLayoutSet = record
    Layouts: array[TGanttViewMode] of TNodeCardLayout;
  end;

  // --- Conversion al motor de pintado existente (uCardLayout) ---

  // Convierte un TNodeCardLayout a TCardLayout para poder pintarlo con RenderCard.
  // AHeightPx fija la altura total del card de preview (en el Gantt real la marca
  // el lane). Si AHeightPx <= 0 se reparte por las filas.
  function NodeLayoutToCardLayout(const ANode: TNodeCardLayout;
    AHeightPx: Integer = 0): TCardLayout;

  // --- Vistas ---

  function GanttViewModeToStr(V: TGanttViewMode): string;
  function StrToGanttViewMode(const S: string): TGanttViewMode;
  function GanttViewModeCaption(V: TGanttViewMode): string;

  // --- Layouts por defecto ---

  function DefaultNodeLayoutNormal: TNodeCardLayout;
  function DefaultNodeLayoutFabricacion: TNodeCardLayout;
  // Default generico para las vistas aun no especializadas (fase 1 cubre
  // gvmNormal y gvmFabricacio; el resto arranca con este).
  function DefaultNodeLayoutGeneric(const AName: string): TNodeCardLayout;
  function DefaultNodeLayoutFor(V: TGanttViewMode): TNodeCardLayout;
  function DefaultNodeLayoutSet: TNodeLayoutSet;

  // --- Persistencia JSON ---

  function NodeCardLayoutToJSON(const ALayout: TNodeCardLayout): TJSONObject;
  function JSONToNodeCardLayout(const AJson: TJSONObject): TNodeCardLayout;
  function NodeLayoutSetToJSON(const ASet: TNodeLayoutSet): TJSONObject;
  function JSONToNodeLayoutSet(const AJson: TJSONObject): TNodeLayoutSet;

implementation

uses
  System.Math;

{ ---- Conversion a TCardLayout (reusa el renderer) ---- }

// Convierte un elemento aplicando la fuente POR DEFECTO del layout (ADef*) a los
// atributos que el elemento no fije: FontSize<=0 -> tamano por defecto;
// FontColor=0 -> color por defecto; Bold/Italic por defecto se OR-ean (si el
// layout es negrita, todos lo son salvo que el elemento ya lo tenga).
function NodeElemToCardElem(const E: TNodeCardElement;
  ADefFontSize: Integer; ADefFontColor: TColor;
  ADefBold, ADefItalic: Boolean): TCardElement;
begin
  Result := Default(TCardElement);
  Result.Kind := E.Kind;
  Result.FieldExpr := E.FieldExpr;
  if E.FontSize > 0 then
    Result.FontSize := E.FontSize
  else if ADefFontSize > 0 then
    Result.FontSize := ADefFontSize
  else
    Result.FontSize := 8;
  Result.FontBold := E.FontBold or ADefBold;
  Result.FontItalic := E.FontItalic or ADefItalic;
  if E.FontColor <> 0 then
    Result.FontColor := E.FontColor
  else
    Result.FontColor := ADefFontColor;  // 0 = el renderer usa negro
  Result.BgColor := E.BgColor;
  Result.BgColorField := E.BgColorField;
  Result.HAlign := E.HAlign;
  Result.WidthPct := E.WidthPct;
  Result.Visible := E.Visible;
  Result.ConditionField := E.ConditionField;
  Result.RoundRadius := E.RoundRadius;
  Result.StyleRules := Copy(E.StyleRules);
end;

function NodeLayoutToCardLayout(const ANode: TNodeCardLayout;
  AHeightPx: Integer): TCardLayout;
var
  R, E, TotalRows: Integer;
begin
  Result := Default(TCardLayout);
  Result.Name := ANode.Name;
  Result.PaddingH := ANode.PaddingH;
  Result.PaddingV := ANode.PaddingV;
  Result.CornerRadius := ANode.CornerRadius;
  Result.BgColor := ANode.BgColor;
  Result.BorderColor := ANode.BorderColor;
  Result.BorderWidth := ANode.BorderWidth;

  TotalRows := 0;
  for R := 0 to High(ANode.Rows) do
    TotalRows := TotalRows + Max(0, ANode.Rows[R].HeightPx);
  Result.CardHeight := AHeightPx;
  if Result.CardHeight <= 0 then
    Result.CardHeight := TotalRows + ANode.PaddingV * 2;

  SetLength(Result.Rows, Length(ANode.Rows));
  for R := 0 to High(ANode.Rows) do
  begin
    Result.Rows[R].HeightPx := ANode.Rows[R].HeightPx;
    Result.Rows[R].Spacing := ANode.Rows[R].Spacing;
    SetLength(Result.Rows[R].Elements, Length(ANode.Rows[R].Elements));
    for E := 0 to High(ANode.Rows[R].Elements) do
      Result.Rows[R].Elements[E] := NodeElemToCardElem(
        ANode.Rows[R].Elements[E],
        ANode.FontSize, ANode.FontColor, ANode.FontBold, ANode.FontItalic);
  end;
end;

{ ---- Vistas ---- }

function GanttViewModeToStr(V: TGanttViewMode): string;
begin
  case V of
    gvmNormal:        Result := 'normal';
    gvmOptimitzacio:  Result := 'optimizacion';
    gvmFabricacio:    Result := 'fabricacion';
    gvmFechaEntrega:  Result := 'fechaentrega';
    gvmStock:         Result := 'stock';
    gvmOperarios:     Result := 'operarios';
    gvmCarga:         Result := 'carga';
    gvmEstado:        Result := 'estado';
    gvmPrioridad:     Result := 'prioridad';
    gvmRendimiento:   Result := 'rendimiento';
    gvmColores:       Result := 'colores';
    gvmModificaciones:Result := 'modificaciones';
  else
    Result := 'normal';
  end;
end;

function StrToGanttViewMode(const S: string): TGanttViewMode;
var
  L: string;
begin
  L := LowerCase(Trim(S));
  if L = 'optimizacion' then Result := gvmOptimitzacio
  else if L = 'fabricacion' then Result := gvmFabricacio
  else if L = 'fechaentrega' then Result := gvmFechaEntrega
  else if L = 'stock' then Result := gvmStock
  else if L = 'operarios' then Result := gvmOperarios
  else if L = 'carga' then Result := gvmCarga
  else if L = 'estado' then Result := gvmEstado
  else if L = 'prioridad' then Result := gvmPrioridad
  else if L = 'rendimiento' then Result := gvmRendimiento
  else if L = 'colores' then Result := gvmColores
  else if L = 'modificaciones' then Result := gvmModificaciones
  else Result := gvmNormal;
end;

function GanttViewModeCaption(V: TGanttViewMode): string;
begin
  case V of
    gvmNormal:        Result := 'Normal';
    gvmOptimitzacio:  Result := 'Optimizaci'#243'n';
    gvmFabricacio:    Result := 'Fabricaci'#243'n';
    gvmFechaEntrega:  Result := 'Fecha de entrega';
    gvmStock:         Result := 'Stock';
    gvmOperarios:     Result := 'Operarios';
    gvmCarga:         Result := 'Carga';
    gvmEstado:        Result := 'Estado';
    gvmPrioridad:     Result := 'Prioridad';
    gvmRendimiento:   Result := 'Rendimiento';
    gvmColores:       Result := 'Colores';
    gvmModificaciones:Result := 'Modificaciones';
  else
    Result := 'Normal';
  end;
end;

{ ---- Helpers de construccion ---- }

function MakeNodeElem(AKind: TCardElementKind; const AExpr: string;
  AFontSize: Integer; ABold: Boolean; AFontColor: TColor;
  AHAlign: TCardHAlign; AWidthPct: Integer): TNodeCardElement;
begin
  Result := Default(TNodeCardElement);
  Result.Kind := AKind;
  Result.FieldExpr := AExpr;
  Result.FontSize := AFontSize;
  Result.FontBold := ABold;
  Result.FontColor := AFontColor;
  Result.HAlign := AHAlign;
  Result.WidthPct := AWidthPct;
  Result.Visible := True;
  Result.RoundRadius := 4;
end;

{ ---- Layouts por defecto ---- }

function DefaultNodeLayoutNormal: TNodeCardLayout;
begin
  Result := Default(TNodeCardLayout);
  Result.Name := 'Normal';
  Result.PaddingH := 4;
  Result.PaddingV := 2;
  Result.CornerRadius := 4;
  Result.BgColor := 0;       // mantener color propio del nodo (OF/estado)
  Result.BorderColor := 0;
  Result.BorderWidth := 0;
  Result.FontName := '';

  SetLength(Result.Rows, 2);

  // Fila 1: identificacion principal (OF + operacion)
  Result.Rows[0].HeightPx := 14;
  Result.Rows[0].Spacing := 4;
  SetLength(Result.Rows[0].Elements, 1);
  Result.Rows[0].Elements[0] := MakeNodeElem(ceText,
    'OF {NumeroOrdenFabricacion} - {Operacion}', 8, True, clBlack, chaLeft, 0);

  // Fila 2: articulo
  Result.Rows[1].HeightPx := 12;
  Result.Rows[1].Spacing := 4;
  SetLength(Result.Rows[1].Elements, 1);
  Result.Rows[1].Elements[0] := MakeNodeElem(ceText,
    '{CodigoArticulo}', 7, False, $00555555, chaLeft, 0);
end;

function DefaultNodeLayoutFabricacion: TNodeCardLayout;
begin
  Result := Default(TNodeCardLayout);
  Result.Name := 'Fabricaci'#243'n';
  Result.PaddingH := 4;
  Result.PaddingV := 2;
  Result.CornerRadius := 4;
  Result.BgColor := 0;
  Result.BorderColor := 0;
  Result.BorderWidth := 0;
  Result.FontName := '';

  SetLength(Result.Rows, 2);

  // Fila 1: OF + badge estado
  Result.Rows[0].HeightPx := 14;
  Result.Rows[0].Spacing := 4;
  SetLength(Result.Rows[0].Elements, 2);
  Result.Rows[0].Elements[0] := MakeNodeElem(ceText,
    'OF {NumeroOrdenFabricacion}', 8, True, clBlack, chaLeft, 0);
  Result.Rows[0].Elements[1] := MakeNodeElem(ceBadge,
    '{Estado}', 6, True, clWhite, chaCenter, 22);
  Result.Rows[0].Elements[1].BgColorField := 'Estado';

  // Fila 2: unidades + operarios
  Result.Rows[1].HeightPx := 12;
  Result.Rows[1].Spacing := 4;
  SetLength(Result.Rows[1].Elements, 2);
  Result.Rows[1].Elements[0] := MakeNodeElem(ceText,
    'Uds {UnidadesFabricadas}/{UnidadesAFabricar}', 7, False, $00555555, chaLeft, 0);
  Result.Rows[1].Elements[1] := MakeNodeElem(ceBadge,
    '{OperariosAsignados}/{OperariosNecesarios}', 6, True, clWhite, chaCenter, 22);
  Result.Rows[1].Elements[1].BgColor := $0040B040;
  Result.Rows[1].Elements[1].ConditionField := 'OperariosNecesarios';
end;

function DefaultNodeLayoutGeneric(const AName: string): TNodeCardLayout;
begin
  Result := Default(TNodeCardLayout);
  Result.Name := AName;
  Result.PaddingH := 4;
  Result.PaddingV := 2;
  Result.CornerRadius := 4;
  Result.BgColor := 0;
  Result.BorderColor := 0;
  Result.BorderWidth := 0;
  Result.FontName := '';

  SetLength(Result.Rows, 1);
  Result.Rows[0].HeightPx := 14;
  Result.Rows[0].Spacing := 4;
  SetLength(Result.Rows[0].Elements, 1);
  Result.Rows[0].Elements[0] := MakeNodeElem(ceText,
    'OF {NumeroOrdenFabricacion} - {Operacion}', 8, True, clBlack, chaLeft, 0);
end;

function DefaultNodeLayoutFor(V: TGanttViewMode): TNodeCardLayout;
begin
  case V of
    gvmNormal:     Result := DefaultNodeLayoutNormal;
    gvmFabricacio: Result := DefaultNodeLayoutFabricacion;
  else
    Result := DefaultNodeLayoutGeneric(GanttViewModeCaption(V));
  end;
end;

function DefaultNodeLayoutSet: TNodeLayoutSet;
var
  V: TGanttViewMode;
begin
  Result := Default(TNodeLayoutSet);
  for V := Low(TGanttViewMode) to High(TGanttViewMode) do
    Result.Layouts[V] := DefaultNodeLayoutFor(V);
end;

{ ---- JSON (reusa StyleRuleToJSON/HAlign/Kind via strings propios) ---- }

function NCHAlignToStr(A: TCardHAlign): string;
begin
  case A of
    chaCenter: Result := 'center';
    chaRight:  Result := 'right';
  else Result := 'left';
  end;
end;

function NCStrToHAlign(const S: string): TCardHAlign;
begin
  if S = 'center' then Result := chaCenter
  else if S = 'right' then Result := chaRight
  else Result := chaLeft;
end;

function NCKindToStr(K: TCardElementKind): string;
begin
  case K of
    ceBadge:       Result := 'badge';
    ceProgressBar: Result := 'progress';
    ceSpacer:      Result := 'spacer';
  else Result := 'text';
  end;
end;

function NCStrToKind(const S: string): TCardElementKind;
begin
  if S = 'badge' then Result := ceBadge
  else if S = 'progress' then Result := ceProgressBar
  else if S = 'spacer' then Result := ceSpacer
  else Result := ceText;
end;

function NCStyleRuleToJSON(const R: TStyleRule): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('field', R.Field);
  Result.AddPair('op', StyleRuleOpToStr(R.Op));
  Result.AddPair('value', R.Value);
  Result.AddPair('fontColor', TJSONNumber.Create(Integer(R.FontColor)));
  Result.AddPair('bgColor', TJSONNumber.Create(Integer(R.BgColor)));
  Result.AddPair('setBold', TJSONBool.Create(R.SetBold));
  Result.AddPair('setItalic', TJSONBool.Create(R.SetItalic));
end;

function NCJSONToStyleRule(const AJson: TJSONObject): TStyleRule;
begin
  Result := Default(TStyleRule);
  Result.Field := AJson.GetValue<string>('field', '');
  Result.Op := StrToStyleRuleOp(AJson.GetValue<string>('op', '='));
  Result.Value := AJson.GetValue<string>('value', '');
  Result.FontColor := TColor(AJson.GetValue<Integer>('fontColor', 0));
  Result.BgColor := TColor(AJson.GetValue<Integer>('bgColor', 0));
  Result.SetBold := AJson.GetValue<Boolean>('setBold', False);
  Result.SetItalic := AJson.GetValue<Boolean>('setItalic', False);
end;

function NCElementToJSON(const E: TNodeCardElement): TJSONObject;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('kind', NCKindToStr(E.Kind));
  Result.AddPair('fieldExpr', E.FieldExpr);
  Result.AddPair('fontSize', TJSONNumber.Create(E.FontSize));
  Result.AddPair('fontBold', TJSONBool.Create(E.FontBold));
  Result.AddPair('fontItalic', TJSONBool.Create(E.FontItalic));
  Result.AddPair('fontColor', TJSONNumber.Create(Integer(E.FontColor)));
  Result.AddPair('bgColor', TJSONNumber.Create(Integer(E.BgColor)));
  Result.AddPair('bgColorField', E.BgColorField);
  Result.AddPair('hAlign', NCHAlignToStr(E.HAlign));
  Result.AddPair('widthPct', TJSONNumber.Create(E.WidthPct));
  Result.AddPair('visible', TJSONBool.Create(E.Visible));
  Result.AddPair('conditionField', E.ConditionField);
  Result.AddPair('roundRadius', TJSONNumber.Create(E.RoundRadius));
  if Length(E.StyleRules) > 0 then
  begin
    Arr := TJSONArray.Create;
    for I := 0 to High(E.StyleRules) do
      Arr.Add(NCStyleRuleToJSON(E.StyleRules[I]));
    Result.AddPair('styleRules', Arr);
  end;
end;

function NCJSONToElement(const AJson: TJSONObject): TNodeCardElement;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := Default(TNodeCardElement);
  Result.Kind := NCStrToKind(AJson.GetValue<string>('kind', 'text'));
  Result.FieldExpr := AJson.GetValue<string>('fieldExpr', '');
  Result.FontSize := AJson.GetValue<Integer>('fontSize', 8);
  Result.FontBold := AJson.GetValue<Boolean>('fontBold', False);
  Result.FontItalic := AJson.GetValue<Boolean>('fontItalic', False);
  Result.FontColor := TColor(AJson.GetValue<Integer>('fontColor', Integer(clBlack)));
  Result.BgColor := TColor(AJson.GetValue<Integer>('bgColor', 0));
  Result.BgColorField := AJson.GetValue<string>('bgColorField', '');
  Result.HAlign := NCStrToHAlign(AJson.GetValue<string>('hAlign', 'left'));
  Result.WidthPct := AJson.GetValue<Integer>('widthPct', 0);
  Result.Visible := AJson.GetValue<Boolean>('visible', True);
  Result.ConditionField := AJson.GetValue<string>('conditionField', '');
  Result.RoundRadius := AJson.GetValue<Integer>('roundRadius', 4);
  if AJson.GetValue('styleRules') <> nil then
  begin
    Arr := AJson.GetValue('styleRules') as TJSONArray;
    if Arr <> nil then
    begin
      SetLength(Result.StyleRules, Arr.Count);
      for I := 0 to Arr.Count - 1 do
        Result.StyleRules[I] := NCJSONToStyleRule(Arr.Items[I] as TJSONObject);
    end;
  end;
end;

function NCRowToJSON(const ARow: TNodeCardRow): TJSONObject;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('heightPx', TJSONNumber.Create(ARow.HeightPx));
  Result.AddPair('spacing', TJSONNumber.Create(ARow.Spacing));
  Arr := TJSONArray.Create;
  for I := 0 to High(ARow.Elements) do
    Arr.Add(NCElementToJSON(ARow.Elements[I]));
  Result.AddPair('elements', Arr);
end;

function NCJSONToRow(const AJson: TJSONObject): TNodeCardRow;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := Default(TNodeCardRow);
  Result.HeightPx := AJson.GetValue<Integer>('heightPx', 14);
  Result.Spacing := AJson.GetValue<Integer>('spacing', 4);
  Arr := AJson.GetValue<TJSONArray>('elements');
  if Arr <> nil then
  begin
    SetLength(Result.Elements, Arr.Count);
    for I := 0 to Arr.Count - 1 do
      Result.Elements[I] := NCJSONToElement(Arr.Items[I] as TJSONObject);
  end;
end;

function NodeCardLayoutToJSON(const ALayout: TNodeCardLayout): TJSONObject;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', ALayout.Name);
  Result.AddPair('paddingH', TJSONNumber.Create(ALayout.PaddingH));
  Result.AddPair('paddingV', TJSONNumber.Create(ALayout.PaddingV));
  Result.AddPair('cornerRadius', TJSONNumber.Create(ALayout.CornerRadius));
  Result.AddPair('bgColor', TJSONNumber.Create(Integer(ALayout.BgColor)));
  Result.AddPair('borderColor', TJSONNumber.Create(Integer(ALayout.BorderColor)));
  Result.AddPair('borderWidth', TJSONNumber.Create(ALayout.BorderWidth));
  Result.AddPair('fontName', ALayout.FontName);
  Result.AddPair('fontSize', TJSONNumber.Create(ALayout.FontSize));
  Result.AddPair('fontColor', TJSONNumber.Create(Integer(ALayout.FontColor)));
  Result.AddPair('fontBold', TJSONBool.Create(ALayout.FontBold));
  Result.AddPair('fontItalic', TJSONBool.Create(ALayout.FontItalic));
  Arr := TJSONArray.Create;
  for I := 0 to High(ALayout.Rows) do
    Arr.Add(NCRowToJSON(ALayout.Rows[I]));
  Result.AddPair('rows', Arr);
end;

function JSONToNodeCardLayout(const AJson: TJSONObject): TNodeCardLayout;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := Default(TNodeCardLayout);
  Result.Name := AJson.GetValue<string>('name', '');
  Result.PaddingH := AJson.GetValue<Integer>('paddingH', 4);
  Result.PaddingV := AJson.GetValue<Integer>('paddingV', 2);
  Result.CornerRadius := AJson.GetValue<Integer>('cornerRadius', 4);
  Result.BgColor := TColor(AJson.GetValue<Integer>('bgColor', 0));
  Result.BorderColor := TColor(AJson.GetValue<Integer>('borderColor', 0));
  Result.BorderWidth := AJson.GetValue<Integer>('borderWidth', 0);
  Result.FontName := AJson.GetValue<string>('fontName', '');
  Result.FontSize := AJson.GetValue<Integer>('fontSize', 0);
  Result.FontColor := TColor(AJson.GetValue<Integer>('fontColor', 0));
  Result.FontBold := AJson.GetValue<Boolean>('fontBold', False);
  Result.FontItalic := AJson.GetValue<Boolean>('fontItalic', False);
  Arr := AJson.GetValue<TJSONArray>('rows');
  if Arr <> nil then
  begin
    SetLength(Result.Rows, Arr.Count);
    for I := 0 to Arr.Count - 1 do
      Result.Rows[I] := NCJSONToRow(Arr.Items[I] as TJSONObject);
  end;
end;

function NodeLayoutSetToJSON(const ASet: TNodeLayoutSet): TJSONObject;
var
  V: TGanttViewMode;
  Layouts: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('version', TJSONNumber.Create(1));
  Layouts := TJSONObject.Create;
  for V := Low(TGanttViewMode) to High(TGanttViewMode) do
    Layouts.AddPair(GanttViewModeToStr(V), NodeCardLayoutToJSON(ASet.Layouts[V]));
  Result.AddPair('layouts', Layouts);
end;

function JSONToNodeLayoutSet(const AJson: TJSONObject): TNodeLayoutSet;
var
  V: TGanttViewMode;
  Layouts: TJSONObject;
  Val: TJSONValue;
begin
  Result := DefaultNodeLayoutSet;  // baseline para vistas sin entrada
  if AJson = nil then Exit;
  Layouts := AJson.GetValue<TJSONObject>('layouts');
  if Layouts = nil then Exit;
  for V := Low(TGanttViewMode) to High(TGanttViewMode) do
  begin
    Val := Layouts.GetValue(GanttViewModeToStr(V));
    if (Val <> nil) and (Val is TJSONObject) then
      Result.Layouts[V] := JSONToNodeCardLayout(TJSONObject(Val));
  end;
end;

end.
