 unit uCardLayout;

{
  TCardLayout - Define la plantilla visual de un Card del planificador.

  Cada layout consta de filas (TCardRow), y cada fila de elementos (TCardElement).
  Los elementos pueden ser campos de texto con expresiones (Campo), badges con
  color de fondo, barras de progreso, o separadores.

  El renderer generico RenderCard pinta cualquier layout sobre un TCanvas.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.JSON, System.IOUtils, System.Variants,
  System.Math, System.DateUtils, System.StrUtils,
  Winapi.Windows,
  Vcl.Graphics,
  uGanttTypes;

type
  TCardElementKind = (ceText, ceBadge, ceProgressBar, ceSpacer);

  TCardHAlign = (chaLeft, chaCenter, chaRight);

  TCardElement = record
    Kind: TCardElementKind;
    FieldExpr: string;       // p.ej. 'OF {NumeroOrdenFabricacion} - {Operacion}'
    FontSize: Integer;
    FontBold: Boolean;
    FontItalic: Boolean;
    FontColor: TColor;
    BgColor: TColor;         // para badges; 0 = auto segun campo
    BgColorField: string;    // campo que determina color (ej: 'Prioridad', 'Estado')
    HAlign: TCardHAlign;
    WidthPct: Integer;       // 0=auto (reparte equitativo), 1-100=porcentaje fijo
    Visible: Boolean;
    ConditionField: string;  // campo > 0 para mostrar (ej: 'OperariosNecesarios')
    RoundRadius: Integer;
  end;

  TCardRow = record
    HeightPx: Integer;       // altura de la fila en pixeles
    Elements: TArray<TCardElement>;
    Spacing: Integer;        // espacio horizontal entre elementos
  end;

  TCardLayout = record
    Name: string;
    CardHeight: Integer;     // altura total del card
    PaddingH: Integer;       // padding horizontal interno
    PaddingV: Integer;       // padding vertical interno
    CornerRadius: Integer;
    Rows: TArray<TCardRow>;
  end;

  // --- Renderer ---

  TCardFieldResolver = reference to function(const FieldName: string): Variant;

  procedure RenderCard(const ACanvas: TCanvas; const R: TRect;
    const ALayout: TCardLayout; AResolver: TCardFieldResolver);

  function ResolveExpr(const Expr: string; AResolver: TCardFieldResolver): string;

  // --- Resolver de TNodeData ---

  function MakeNodeDataResolver(const D: TNodeData): TCardFieldResolver;

  // --- Color helpers para campos especiales ---

  function ResolveFieldBgColor(const FieldName: string;
    AResolver: TCardFieldResolver): TColor;

  // --- Layouts predefinidos ---

  function DefaultCardLayout: TCardLayout;
  function DefaultPendingCardLayout: TCardLayout;
  function LayoutCompacto: TCardLayout;
  function LayoutDetallado: TCardLayout;
  function LayoutLogistica: TCardLayout;
  function LayoutProduccion: TCardLayout;
  function LayoutCliente: TCardLayout;

  // Obtener todos los layouts predefinidos
  function GetAllTemplateLayouts: TArray<TCardLayout>;

  // --- Persistencia JSON ---

  function CardLayoutToJSON(const ALayout: TCardLayout): TJSONObject;
  function JSONToCardLayout(const AJson: TJSONObject): TCardLayout;
  procedure SaveCardLayoutToFile(const ALayout: TCardLayout; const AFileName: string);
  function LoadCardLayoutFromFile(const AFileName: string): TCardLayout;

implementation

{ ---- Resolver de expresiones ---- }

function ResolveExpr(const Expr: string; AResolver: TCardFieldResolver): string;
var
  I, J: Integer;
  FieldName, Val: string;
begin
  Result := Expr;
  I := Pos('{', Result);
  while I > 0 do
  begin
    J := PosEx('}', Result, I);
    if J = 0 then Break;
    FieldName := Copy(Result, I + 1, J - I - 1);
    Val := VarToStr(AResolver(FieldName));
    Result := Copy(Result, 1, I - 1) + Val + Copy(Result, J + 1, MaxInt);
    I := Pos('{', Result);
  end;
end;

{ ---- Resolver de TNodeData ---- }

function MakeNodeDataResolver(const D: TNodeData): TCardFieldResolver;
begin
  Result := function(const FieldName: string): Variant
    var
      I: Integer;
      FN: string;
    begin
      FN := LowerCase(FieldName);
      if FN = 'dataid' then Result := D.DataId
      else if FN = 'operacion' then Result := D.Operacion
      else if FN = 'numeropedido' then Result := D.NumeroPedido
      else if FN = 'seriepedido' then Result := D.SeriePedido
      else if FN = 'numeroordenfabricacion' then Result := D.NumeroOrdenFabricacion
      else if FN = 'seriefabricacion' then Result := D.SerieFabricacion
      else if FN = 'numerotrabajo' then Result := D.NumeroTrabajo
      else if FN = 'fechaentrega' then
      begin
        if D.FechaEntrega > 0 then
          Result := FormatDateTime('dd/mm/yy', D.FechaEntrega)
        else
          Result := '';
      end
      else if FN = 'fechanecesaria' then
      begin
        if D.FechaNecesaria > 0 then
          Result := FormatDateTime('dd/mm/yy', D.FechaNecesaria)
        else
          Result := '';
      end
      else if FN = 'codigocliente' then Result := D.CodigoCliente
      else if FN = 'codigocolor' then Result := D.CodigoColor
      else if FN = 'codigotalla' then Result := D.CodigoTalla
      else if FN = 'stock' then Result := D.Stock
      else if FN = 'codigoarticulo' then Result := D.CodigoArticulo
      else if FN = 'descripcionarticulo' then Result := D.DescripcionArticulo
      else if FN = 'porcentajedependencia' then Result := D.PorcentajeDependencia
      else if FN = 'unidadesfabricadas' then Result := D.UnidadesFabricadas
      else if FN = 'unidadesafabricar' then Result := D.UnidadesAFabricar
      else if FN = 'durationmin' then
      begin
        if D.DurationMin >= 60 then
          Result := Format('%.1fh', [D.DurationMin / 60])
        else if D.DurationMin > 0 then
          Result := Format('%.0f min', [D.DurationMin])
        else
          Result := '';
      end
      else if FN = 'operariosnecesarios' then Result := D.OperariosNecesarios
      else if FN = 'operariosasignados' then Result := D.OperariosAsignados
      else if FN = 'estado' then
      begin
        case D.Estado of
          nePendiente:  Result := 'PEND';
          neEnCurso:    Result := 'CURSO';
          neFinalizado: Result := 'FIN';
          neBloqueado:  Result := 'BLOQ';
        else Result := '-';
        end;
      end
      else if FN = 'prioridad' then
      begin
        case D.Prioridad of
          1: Result := 'ALTA';
          2: Result := 'MEDIA';
          3: Result := 'BAJA';
        else Result := '-';
        end;
      end
      else if FN = 'tipo' then
      begin
        case D.Tipo of
          ntOF:       Result := 'OF';
          ntPedido:   Result := 'PED';
          ntProyecto: Result := 'PROY';
          ntOferta:   Result := 'OFERTA';
        else Result := '-';
        end;
      end
      else begin
        // Buscar en CustomFields
        for I := 0 to High(D.CustomFields) do
          if SameText(D.CustomFields[I].FieldName, FieldName) then
            Exit(D.CustomFields[I].Value);
        Result := '';
      end;
    end;
end;

{ ---- Color de fondo segun campo ---- }

function ResolveFieldBgColor(const FieldName: string;
  AResolver: TCardFieldResolver): TColor;
var
  V: Variant;
  FN: string;
begin
  FN := LowerCase(FieldName);
  V := AResolver(FieldName);

  if FN = 'prioridad' then
  begin
    if VarToStr(V) = 'ALTA' then Result := $004040FF
    else if VarToStr(V) = 'MEDIA' then Result := $000080FF
    else if VarToStr(V) = 'BAJA' then Result := $00FF8000
    else Result := $00B0B0B0;
  end
  else if FN = 'estado' then
  begin
    if VarToStr(V) = 'PEND' then Result := $00B0B0B0
    else if VarToStr(V) = 'CURSO' then Result := $00E89040
    else if VarToStr(V) = 'FIN' then Result := $0040B040
    else if VarToStr(V) = 'BLOQ' then Result := $004040E0
    else Result := $00B0B0B0;
  end
  else
    Result := $00808080;
end;

{ ---- Renderer generico ---- }

procedure RenderCard(const ACanvas: TCanvas; const R: TRect;
  const ALayout: TCardLayout; AResolver: TCardFieldResolver);
var
  RowIdx, ElemIdx: Integer;
  Row: TCardRow;
  Elem: TCardElement;
  Y, X, ElemW, AvailW, AutoCount, FixedW, Spacing: Integer;
  TR, BadgeR: TRect;
  S: string;
  CondVal: Variant;
  FS: TFontStyles;
begin
  Y := R.Top + ALayout.PaddingV;
  AvailW := (R.Right - R.Left) - ALayout.PaddingH * 2;

  for RowIdx := 0 to High(ALayout.Rows) do
  begin
    Row := ALayout.Rows[RowIdx];
    if Row.HeightPx <= 0 then Continue;
    Spacing := Row.Spacing;
    if Spacing <= 0 then Spacing := 4;

    // Calcular anchos: primero los fijos, luego repartir el resto
    FixedW := 0;
    AutoCount := 0;
    for ElemIdx := 0 to High(Row.Elements) do
    begin
      Elem := Row.Elements[ElemIdx];
      if not Elem.Visible then Continue;
      // Evaluar condicion
      if Elem.ConditionField <> '' then
      begin
        CondVal := AResolver(Elem.ConditionField);
        if VarIsNull(CondVal) or (VarToStr(CondVal) = '') or (VarToStr(CondVal) = '0') then
          Continue;
      end;
      if Elem.WidthPct > 0 then
        FixedW := FixedW + MulDiv(AvailW, Elem.WidthPct, 100) + Spacing
      else
        Inc(AutoCount);
    end;

    X := R.Left + ALayout.PaddingH;

    for ElemIdx := 0 to High(Row.Elements) do
    begin
      Elem := Row.Elements[ElemIdx];
      if not Elem.Visible then Continue;

      // Evaluar condicion
      if Elem.ConditionField <> '' then
      begin
        CondVal := AResolver(Elem.ConditionField);
        if VarIsNull(CondVal) or (VarToStr(CondVal) = '') or (VarToStr(CondVal) = '0') then
          Continue;
      end;

      // Calcular ancho del elemento
      if Elem.WidthPct > 0 then
        ElemW := MulDiv(AvailW, Elem.WidthPct, 100)
      else if AutoCount > 0 then
        ElemW := Max(20, (AvailW - FixedW) div AutoCount)
      else
        ElemW := AvailW;

      TR := Rect(X, Y, X + ElemW, Y + Row.HeightPx);

      S := ResolveExpr(Elem.FieldExpr, AResolver);
      if S = '' then
      begin
        X := X + ElemW + Spacing;
        Continue;
      end;

      FS := [];
      if Elem.FontBold then Include(FS, fsBold);
      if Elem.FontItalic then Include(FS, fsItalic);

      case Elem.Kind of
        ceText:
        begin
          ACanvas.Font.Size := Elem.FontSize;
          ACanvas.Font.Style := FS;
          ACanvas.Font.Color := Elem.FontColor;
          ACanvas.Brush.Style := bsClear;
          var DTFlags: Cardinal := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX;
          case Elem.HAlign of
            chaLeft:   DTFlags := DTFlags or DT_LEFT;
            chaCenter: DTFlags := DTFlags or DT_CENTER;
            chaRight:  DTFlags := DTFlags or DT_RIGHT;
          end;
          DrawText(ACanvas.Handle, PChar(S), -1, TR, DTFlags);
        end;

        ceBadge:
        begin
          BadgeR := TR;
          // Fondo
          if Elem.BgColorField <> '' then
            ACanvas.Brush.Color := ResolveFieldBgColor(Elem.BgColorField, AResolver)
          else if Elem.BgColor <> 0 then
            ACanvas.Brush.Color := Elem.BgColor
          else
            ACanvas.Brush.Color := $00808080;
          ACanvas.Pen.Style := psClear;
          var RR: Integer := Elem.RoundRadius;
          if RR <= 0 then RR := 4;
          ACanvas.RoundRect(BadgeR.Left, BadgeR.Top, BadgeR.Right, BadgeR.Bottom, RR, RR);
          // Texto
          ACanvas.Font.Size := Elem.FontSize;
          ACanvas.Font.Style := FS;
          ACanvas.Font.Color := Elem.FontColor;
          ACanvas.Brush.Style := bsClear;
          DrawText(ACanvas.Handle, PChar(S), -1, BadgeR,
            DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);
          ACanvas.Pen.Style := psSolid;
        end;

        ceProgressBar:
        begin
          var Pct: Double := 0;
          try Pct := StrToFloatDef(S, 0); except end;
          if Pct > 100 then Pct := 100;
          // Fondo
          ACanvas.Brush.Color := $00E0E0E0;
          ACanvas.Pen.Style := psClear;
          ACanvas.RoundRect(TR.Left, TR.Top + 2, TR.Right, TR.Bottom - 2, 4, 4);
          // Barra
          if Pct > 0 then
          begin
            var BarW: Integer := MulDiv(TR.Right - TR.Left, Round(Pct), 100);
            if Elem.BgColor <> 0 then
              ACanvas.Brush.Color := Elem.BgColor
            else
              ACanvas.Brush.Color := $00FF8000;
            ACanvas.RoundRect(TR.Left, TR.Top + 2, TR.Left + BarW, TR.Bottom - 2, 4, 4);
          end;
          ACanvas.Pen.Style := psSolid;
        end;

        ceSpacer: ; // no pinta nada
      end;

      X := X + ElemW + Spacing;
    end;

    Y := Y + Row.HeightPx;
  end;
end;

{ ---- Layout por defecto (centre columns) ---- }

function MakeElement(AKind: TCardElementKind; const AExpr: string;
  AFontSize: Integer; ABold: Boolean; AFontColor: TColor;
  AHAlign: TCardHAlign; AWidthPct: Integer): TCardElement;
begin
  Result := Default(TCardElement);
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

function DefaultCardLayout: TCardLayout;
begin
  Result := Default(TCardLayout);
  Result.Name := 'Por defecto';
  Result.CardHeight := 88;
  Result.PaddingH := 6;
  Result.PaddingV := 6;
  Result.CornerRadius := 6;

  SetLength(Result.Rows, 4);

  // Fila 1: Badge prioridad + OF
  Result.Rows[0].HeightPx := 18;
  Result.Rows[0].Spacing := 4;
  SetLength(Result.Rows[0].Elements, 2);
  Result.Rows[0].Elements[0] := MakeElement(ceBadge, '{Prioridad}', 7, True, clWhite, chaCenter, 18);
  Result.Rows[0].Elements[0].BgColorField := 'Prioridad';
  Result.Rows[0].Elements[1] := MakeElement(ceText, 'OF {NumeroOrdenFabricacion} - {Operacion}', 9, True, $00333333, chaLeft, 0);

  // Fila 2: Articulo + operarios
  Result.Rows[1].HeightPx := 16;
  Result.Rows[1].Spacing := 4;
  SetLength(Result.Rows[1].Elements, 2);
  Result.Rows[1].Elements[0] := MakeElement(ceText, '{CodigoArticulo}', 8, False, $00777777, chaLeft, 0);
  Result.Rows[1].Elements[1] := MakeElement(ceBadge, '{OperariosAsignados}/{OperariosNecesarios}', 7, True, clWhite, chaCenter, 18);
  Result.Rows[1].Elements[1].BgColor := $0040B040;
  Result.Rows[1].Elements[1].ConditionField := 'OperariosNecesarios';

  // Fila 3: Duracion + fecha + estado
  Result.Rows[2].HeightPx := 16;
  Result.Rows[2].Spacing := 4;
  SetLength(Result.Rows[2].Elements, 2);
  Result.Rows[2].Elements[0] := MakeElement(ceText, '{DurationMin} | {FechaEntrega}', 7, False, $00AAAAAA, chaLeft, 0);
  Result.Rows[2].Elements[1] := MakeElement(ceBadge, '{Estado}', 6, True, clWhite, chaCenter, 18);
  Result.Rows[2].Elements[1].BgColorField := 'Estado';

  // Fila 4: Fechas inicio/fin planificadas
  Result.Rows[3].HeightPx := 14;
  Result.Rows[3].Spacing := 4;
  SetLength(Result.Rows[3].Elements, 1);
  Result.Rows[3].Elements[0] := MakeElement(ceText, '{FechaNecesaria}', 7, False, $00B09070, chaLeft, 0);
end;

function DefaultPendingCardLayout: TCardLayout;
begin
  Result := Default(TCardLayout);
  Result.Name := 'Pendientes';
  Result.CardHeight := 82;
  Result.PaddingH := 8;
  Result.PaddingV := 8;
  Result.CornerRadius := 8;

  SetLength(Result.Rows, 3);

  // Fila 1: Badge prioridad + OF
  Result.Rows[0].HeightPx := 18;
  Result.Rows[0].Spacing := 6;
  SetLength(Result.Rows[0].Elements, 2);
  Result.Rows[0].Elements[0] := MakeElement(ceBadge, '{Prioridad}', 7, True, clWhite, chaCenter, 20);
  Result.Rows[0].Elements[0].BgColorField := 'Prioridad';
  Result.Rows[0].Elements[1] := MakeElement(ceText, 'OF {NumeroOrdenFabricacion} - {Operacion}', 9, True, $00333333, chaLeft, 0);

  // Fila 2: Articulo + operarios
  Result.Rows[1].HeightPx := 16;
  Result.Rows[1].Spacing := 6;
  SetLength(Result.Rows[1].Elements, 2);
  Result.Rows[1].Elements[0] := MakeElement(ceText, '{CodigoArticulo} {DescripcionArticulo}', 8, False, $00777777, chaLeft, 0);
  Result.Rows[1].Elements[1] := MakeElement(ceBadge, '{OperariosAsignados}/{OperariosNecesarios}', 7, True, clWhite, chaCenter, 18);
  Result.Rows[1].Elements[1].BgColor := $0040B040;
  Result.Rows[1].Elements[1].ConditionField := 'OperariosNecesarios';

  // Fila 3: Duracion + fecha entrega
  Result.Rows[2].HeightPx := 16;
  Result.Rows[2].Spacing := 6;
  SetLength(Result.Rows[2].Elements, 1);
  Result.Rows[2].Elements[0] := MakeElement(ceText, '{DurationMin}  |  Entrega: {FechaEntrega}', 7, False, $00999999, chaLeft, 0);
end;

{ ---- Layout: Compacto (2 filas, minimo info) ---- }

function LayoutCompacto: TCardLayout;
begin
  Result := Default(TCardLayout);
  Result.Name := 'Compacto';
  Result.CardHeight := 48;
  Result.PaddingH := 6;
  Result.PaddingV := 4;
  Result.CornerRadius := 4;

  SetLength(Result.Rows, 2);

  // Fila 1: OF + Prioridad
  Result.Rows[0].HeightPx := 18;
  Result.Rows[0].Spacing := 4;
  SetLength(Result.Rows[0].Elements, 2);
  Result.Rows[0].Elements[0] := MakeElement(ceBadge, '{Prioridad}', 6, True, clWhite, chaCenter, 15);
  Result.Rows[0].Elements[0].BgColorField := 'Prioridad';
  Result.Rows[0].Elements[1] := MakeElement(ceText, 'OF {NumeroOrdenFabricacion}', 8, True, $00333333, chaLeft, 0);

  // Fila 2: Duracion + Entrega
  Result.Rows[1].HeightPx := 14;
  Result.Rows[1].Spacing := 4;
  SetLength(Result.Rows[1].Elements, 2);
  Result.Rows[1].Elements[0] := MakeElement(ceText, '{DurationMin}', 7, False, $00888888, chaLeft, 50);
  Result.Rows[1].Elements[1] := MakeElement(ceText, '{FechaEntrega}', 7, False, $00888888, chaRight, 50);
end;

{ ---- Layout: Detallado (5 filas, toda la info) ---- }

function LayoutDetallado: TCardLayout;
begin
  Result := Default(TCardLayout);
  Result.Name := 'Detallado';
  Result.CardHeight := 110;
  Result.PaddingH := 6;
  Result.PaddingV := 5;
  Result.CornerRadius := 6;

  SetLength(Result.Rows, 5);

  // Fila 1: Prioridad + OF + Operacion
  Result.Rows[0].HeightPx := 18;
  Result.Rows[0].Spacing := 4;
  SetLength(Result.Rows[0].Elements, 2);
  Result.Rows[0].Elements[0] := MakeElement(ceBadge, '{Prioridad}', 7, True, clWhite, chaCenter, 16);
  Result.Rows[0].Elements[0].BgColorField := 'Prioridad';
  Result.Rows[0].Elements[1] := MakeElement(ceText, 'OF {NumeroOrdenFabricacion} - {Operacion}', 9, True, $00333333, chaLeft, 0);

  // Fila 2: Articulo completo
  Result.Rows[1].HeightPx := 16;
  Result.Rows[1].Spacing := 4;
  SetLength(Result.Rows[1].Elements, 1);
  Result.Rows[1].Elements[0] := MakeElement(ceText, '{CodigoArticulo} - {DescripcionArticulo}', 8, False, $00666666, chaLeft, 0);

  // Fila 3: Cliente + Pedido
  Result.Rows[2].HeightPx := 16;
  Result.Rows[2].Spacing := 4;
  SetLength(Result.Rows[2].Elements, 2);
  Result.Rows[2].Elements[0] := MakeElement(ceText, 'Cli: {CodigoCliente}', 7, False, $00777777, chaLeft, 50);
  Result.Rows[2].Elements[1] := MakeElement(ceText, 'Ped: {NumeroPedido}{SeriePedido}', 7, False, $00777777, chaLeft, 50);

  // Fila 4: Duracion + Operarios + Estado
  Result.Rows[3].HeightPx := 16;
  Result.Rows[3].Spacing := 4;
  SetLength(Result.Rows[3].Elements, 3);
  Result.Rows[3].Elements[0] := MakeElement(ceText, '{DurationMin}', 7, False, $00999999, chaLeft, 30);
  Result.Rows[3].Elements[1] := MakeElement(ceBadge, '{OperariosAsignados}/{OperariosNecesarios}', 6, True, clWhite, chaCenter, 25);
  Result.Rows[3].Elements[1].BgColor := $0040B040;
  Result.Rows[3].Elements[1].ConditionField := 'OperariosNecesarios';
  Result.Rows[3].Elements[2] := MakeElement(ceBadge, '{Estado}', 6, True, clWhite, chaCenter, 20);
  Result.Rows[3].Elements[2].BgColorField := 'Estado';

  // Fila 5: Fechas entrega + necesaria
  Result.Rows[4].HeightPx := 14;
  Result.Rows[4].Spacing := 4;
  SetLength(Result.Rows[4].Elements, 2);
  Result.Rows[4].Elements[0] := MakeElement(ceText, 'Entrega: {FechaEntrega}', 7, False, $00B09070, chaLeft, 50);
  Result.Rows[4].Elements[1] := MakeElement(ceText, 'Necesaria: {FechaNecesaria}', 7, False, $00B09070, chaLeft, 50);
end;

{ ---- Layout: Logistica (enfocado en fechas y entregas) ---- }

function LayoutLogistica: TCardLayout;
begin
  Result := Default(TCardLayout);
  Result.Name := 'Log'#237'stica';
  Result.CardHeight := 78;
  Result.PaddingH := 6;
  Result.PaddingV := 5;
  Result.CornerRadius := 6;

  SetLength(Result.Rows, 3);

  // Fila 1: OF + Estado
  Result.Rows[0].HeightPx := 18;
  Result.Rows[0].Spacing := 4;
  SetLength(Result.Rows[0].Elements, 2);
  Result.Rows[0].Elements[0] := MakeElement(ceText, 'OF {NumeroOrdenFabricacion}', 9, True, $00333333, chaLeft, 0);
  Result.Rows[0].Elements[1] := MakeElement(ceBadge, '{Estado}', 6, True, clWhite, chaCenter, 20);
  Result.Rows[0].Elements[1].BgColorField := 'Estado';

  // Fila 2: Cliente + Articulo
  Result.Rows[1].HeightPx := 16;
  Result.Rows[1].Spacing := 4;
  SetLength(Result.Rows[1].Elements, 2);
  Result.Rows[1].Elements[0] := MakeElement(ceText, '{CodigoCliente}', 8, True, $00555555, chaLeft, 30);
  Result.Rows[1].Elements[1] := MakeElement(ceText, '{CodigoArticulo}', 8, False, $00777777, chaLeft, 0);

  // Fila 3: Fecha entrega + Fecha necesaria
  Result.Rows[2].HeightPx := 16;
  Result.Rows[2].Spacing := 4;
  SetLength(Result.Rows[2].Elements, 2);
  Result.Rows[2].Elements[0] := MakeElement(ceText, 'Entrega: {FechaEntrega}', 8, True, $000060C0, chaLeft, 50);
  Result.Rows[2].Elements[1] := MakeElement(ceText, 'Neces: {FechaNecesaria}', 7, False, $00999999, chaLeft, 50);
end;

{ ---- Layout: Produccion (enfocado en OF, operarios, unidades) ---- }

function LayoutProduccion: TCardLayout;
begin
  Result := Default(TCardLayout);
  Result.Name := 'Producci'#243'n';
  Result.CardHeight := 94;
  Result.PaddingH := 6;
  Result.PaddingV := 5;
  Result.CornerRadius := 6;

  SetLength(Result.Rows, 4);

  // Fila 1: Prioridad + OF + Operacion
  Result.Rows[0].HeightPx := 18;
  Result.Rows[0].Spacing := 4;
  SetLength(Result.Rows[0].Elements, 2);
  Result.Rows[0].Elements[0] := MakeElement(ceBadge, '{Prioridad}', 7, True, clWhite, chaCenter, 16);
  Result.Rows[0].Elements[0].BgColorField := 'Prioridad';
  Result.Rows[0].Elements[1] := MakeElement(ceText, 'OF {NumeroOrdenFabricacion} - {Operacion}', 9, True, $00333333, chaLeft, 0);

  // Fila 2: Articulo
  Result.Rows[1].HeightPx := 16;
  Result.Rows[1].Spacing := 4;
  SetLength(Result.Rows[1].Elements, 1);
  Result.Rows[1].Elements[0] := MakeElement(ceText, '{CodigoArticulo}', 8, False, $00777777, chaLeft, 0);

  // Fila 3: Unidades fabricadas/a fabricar + Operarios
  Result.Rows[2].HeightPx := 16;
  Result.Rows[2].Spacing := 4;
  SetLength(Result.Rows[2].Elements, 2);
  Result.Rows[2].Elements[0] := MakeElement(ceText, 'Uds: {UnidadesFabricadas}/{UnidadesAFabricar}', 7, False, $00666666, chaLeft, 0);
  Result.Rows[2].Elements[1] := MakeElement(ceBadge, '{OperariosAsignados}/{OperariosNecesarios}', 6, True, clWhite, chaCenter, 22);
  Result.Rows[2].Elements[1].BgColor := $0040B040;
  Result.Rows[2].Elements[1].ConditionField := 'OperariosNecesarios';

  // Fila 4: Duracion + Estado
  Result.Rows[3].HeightPx := 16;
  Result.Rows[3].Spacing := 4;
  SetLength(Result.Rows[3].Elements, 2);
  Result.Rows[3].Elements[0] := MakeElement(ceText, '{DurationMin}  |  {FechaEntrega}', 7, False, $00999999, chaLeft, 0);
  Result.Rows[3].Elements[1] := MakeElement(ceBadge, '{Estado}', 6, True, clWhite, chaCenter, 18);
  Result.Rows[3].Elements[1].BgColorField := 'Estado';
end;

{ ---- Layout: Cliente (enfocado en datos comerciales) ---- }

function LayoutCliente: TCardLayout;
begin
  Result := Default(TCardLayout);
  Result.Name := 'Comercial';
  Result.CardHeight := 78;
  Result.PaddingH := 6;
  Result.PaddingV := 5;
  Result.CornerRadius := 8;

  SetLength(Result.Rows, 3);

  // Fila 1: Cliente destacado + Pedido
  Result.Rows[0].HeightPx := 18;
  Result.Rows[0].Spacing := 4;
  SetLength(Result.Rows[0].Elements, 2);
  Result.Rows[0].Elements[0] := MakeElement(ceText, '{CodigoCliente}', 9, True, $00333333, chaLeft, 40);
  Result.Rows[0].Elements[1] := MakeElement(ceText, 'Ped {NumeroPedido}{SeriePedido}', 8, False, $00666666, chaRight, 0);

  // Fila 2: Articulo + Descripcion
  Result.Rows[1].HeightPx := 16;
  Result.Rows[1].Spacing := 4;
  SetLength(Result.Rows[1].Elements, 1);
  Result.Rows[1].Elements[0] := MakeElement(ceText, '{CodigoArticulo} - {DescripcionArticulo}', 8, False, $00777777, chaLeft, 0);

  // Fila 3: Entrega + Prioridad
  Result.Rows[2].HeightPx := 16;
  Result.Rows[2].Spacing := 4;
  SetLength(Result.Rows[2].Elements, 2);
  Result.Rows[2].Elements[0] := MakeElement(ceText, 'Entrega: {FechaEntrega}', 8, False, $000060C0, chaLeft, 0);
  Result.Rows[2].Elements[1] := MakeElement(ceBadge, '{Prioridad}', 6, True, clWhite, chaCenter, 18);
  Result.Rows[2].Elements[1].BgColorField := 'Prioridad';
end;

{ ---- Obtener todos los layouts predefinidos ---- }

function GetAllTemplateLayouts: TArray<TCardLayout>;
begin
  Result := TArray<TCardLayout>.Create(
    DefaultCardLayout,
    DefaultPendingCardLayout,
    LayoutCompacto,
    LayoutDetallado,
    LayoutLogistica,
    LayoutProduccion,
    LayoutCliente
  );
end;

{ ---- JSON serialization ---- }

function HAlignToStr(A: TCardHAlign): string;
begin
  case A of
    chaLeft: Result := 'left';
    chaCenter: Result := 'center';
    chaRight: Result := 'right';
  else Result := 'left';
  end;
end;

function StrToHAlign(const S: string): TCardHAlign;
begin
  if S = 'center' then Result := chaCenter
  else if S = 'right' then Result := chaRight
  else Result := chaLeft;
end;

function KindToStr(K: TCardElementKind): string;
begin
  case K of
    ceText: Result := 'text';
    ceBadge: Result := 'badge';
    ceProgressBar: Result := 'progress';
    ceSpacer: Result := 'spacer';
  else Result := 'text';
  end;
end;

function StrToKind(const S: string): TCardElementKind;
begin
  if S = 'badge' then Result := ceBadge
  else if S = 'progress' then Result := ceProgressBar
  else if S = 'spacer' then Result := ceSpacer
  else Result := ceText;
end;

function ElementToJSON(const E: TCardElement): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('kind', KindToStr(E.Kind));
  Result.AddPair('fieldExpr', E.FieldExpr);
  Result.AddPair('fontSize', TJSONNumber.Create(E.FontSize));
  Result.AddPair('fontBold', TJSONBool.Create(E.FontBold));
  Result.AddPair('fontItalic', TJSONBool.Create(E.FontItalic));
  Result.AddPair('fontColor', TJSONNumber.Create(Integer(E.FontColor)));
  Result.AddPair('bgColor', TJSONNumber.Create(Integer(E.BgColor)));
  Result.AddPair('bgColorField', E.BgColorField);
  Result.AddPair('hAlign', HAlignToStr(E.HAlign));
  Result.AddPair('widthPct', TJSONNumber.Create(E.WidthPct));
  Result.AddPair('visible', TJSONBool.Create(E.Visible));
  Result.AddPair('conditionField', E.ConditionField);
  Result.AddPair('roundRadius', TJSONNumber.Create(E.RoundRadius));
end;

function JSONToElement(const AJson: TJSONObject): TCardElement;
begin
  Result := Default(TCardElement);
  Result.Kind := StrToKind(AJson.GetValue<string>('kind', 'text'));
  Result.FieldExpr := AJson.GetValue<string>('fieldExpr', '');
  Result.FontSize := AJson.GetValue<Integer>('fontSize', 8);
  Result.FontBold := AJson.GetValue<Boolean>('fontBold', False);
  Result.FontItalic := AJson.GetValue<Boolean>('fontItalic', False);
  Result.FontColor := TColor(AJson.GetValue<Integer>('fontColor', Integer(clBlack)));
  Result.BgColor := TColor(AJson.GetValue<Integer>('bgColor', 0));
  Result.BgColorField := AJson.GetValue<string>('bgColorField', '');
  Result.HAlign := StrToHAlign(AJson.GetValue<string>('hAlign', 'left'));
  Result.WidthPct := AJson.GetValue<Integer>('widthPct', 0);
  Result.Visible := AJson.GetValue<Boolean>('visible', True);
  Result.ConditionField := AJson.GetValue<string>('conditionField', '');
  Result.RoundRadius := AJson.GetValue<Integer>('roundRadius', 4);
end;

function RowToJSON(const ARow: TCardRow): TJSONObject;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('heightPx', TJSONNumber.Create(ARow.HeightPx));
  Result.AddPair('spacing', TJSONNumber.Create(ARow.Spacing));
  Arr := TJSONArray.Create;
  for I := 0 to High(ARow.Elements) do
    Arr.Add(ElementToJSON(ARow.Elements[I]));
  Result.AddPair('elements', Arr);
end;

function JSONToRow(const AJson: TJSONObject): TCardRow;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := Default(TCardRow);
  Result.HeightPx := AJson.GetValue<Integer>('heightPx', 16);
  Result.Spacing := AJson.GetValue<Integer>('spacing', 4);
  Arr := AJson.GetValue<TJSONArray>('elements');
  if Arr <> nil then
  begin
    SetLength(Result.Elements, Arr.Count);
    for I := 0 to Arr.Count - 1 do
      Result.Elements[I] := JSONToElement(Arr.Items[I] as TJSONObject);
  end;
end;

function CardLayoutToJSON(const ALayout: TCardLayout): TJSONObject;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', ALayout.Name);
  Result.AddPair('cardHeight', TJSONNumber.Create(ALayout.CardHeight));
  Result.AddPair('paddingH', TJSONNumber.Create(ALayout.PaddingH));
  Result.AddPair('paddingV', TJSONNumber.Create(ALayout.PaddingV));
  Result.AddPair('cornerRadius', TJSONNumber.Create(ALayout.CornerRadius));
  Arr := TJSONArray.Create;
  for I := 0 to High(ALayout.Rows) do
    Arr.Add(RowToJSON(ALayout.Rows[I]));
  Result.AddPair('rows', Arr);
end;

function JSONToCardLayout(const AJson: TJSONObject): TCardLayout;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := Default(TCardLayout);
  Result.Name := AJson.GetValue<string>('name', '');
  Result.CardHeight := AJson.GetValue<Integer>('cardHeight', 88);
  Result.PaddingH := AJson.GetValue<Integer>('paddingH', 6);
  Result.PaddingV := AJson.GetValue<Integer>('paddingV', 6);
  Result.CornerRadius := AJson.GetValue<Integer>('cornerRadius', 6);
  Arr := AJson.GetValue<TJSONArray>('rows');
  if Arr <> nil then
  begin
    SetLength(Result.Rows, Arr.Count);
    for I := 0 to Arr.Count - 1 do
      Result.Rows[I] := JSONToRow(Arr.Items[I] as TJSONObject);
  end;
end;

procedure SaveCardLayoutToFile(const ALayout: TCardLayout; const AFileName: string);
var
  Obj: TJSONObject;
begin
  Obj := CardLayoutToJSON(ALayout);
  try
    TFile.WriteAllText(AFileName, Obj.Format(2), TEncoding.UTF8);
  finally
    Obj.Free;
  end;
end;

function LoadCardLayoutFromFile(const AFileName: string): TCardLayout;
var
  S: string;
  Obj: TJSONObject;
begin
  S := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  Obj := TJSONObject.ParseJSONValue(S) as TJSONObject;
  try
    Result := JSONToCardLayout(Obj);
  finally
    Obj.Free;
  end;
end;

end.
