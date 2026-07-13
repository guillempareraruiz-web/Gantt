unit uNesting2DDxf;

{ ============================================================================
  Importador DXF minimo para el modulo de nesting 2D.

  Lee un fichero DXF (ASCII) y extrae los CONTORNOS cerrados como poligonos,
  uno por entidad. Soporta las entidades habituales en piezas de corte 2D:
    - LWPOLYLINE  (polilinea ligera; group 10/20 = vertices, 70 bit1 = cerrada)
    - POLYLINE / VERTEX  (polilinea clasica)
    - CIRCLE      (centro 10/20, radio 40) -> poligono de N lados
    - ARC         -> se ignora si no cierra contorno (no forma pieza por si solo)
    - LINE        -> se acumulan y, si forman un lazo cerrado, se unen en un contorno

  No interpreta bloques (INSERT), splines ni bulges (arcos en polilineas): los
  bulges se tratan como segmentos rectos (aproximacion). Suficiente para la
  mayoria de piezas planas exportadas de CAD/CAM.

  El DXF es un formato de pares (codigo de grupo / valor) en lineas alternas.
  ============================================================================ }

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,
  uNesting2DTypes;

type
  { Un contorno importado: poligono + un nombre orientativo. }
  TDxfContour = record
    Poly: TPolygon2D;
    Nombre: string;
  end;

{ Lee el fichero y devuelve los contornos cerrados encontrados. Lanza excepcion
  si el fichero no se puede leer; devuelve array vacio si no hay contornos. }
function ImportDxfContours(const AFileName: string;
  ACircleSegments: Integer = 32): TArray<TDxfContour>;

{ Exporta el resultado de un nesting a un fichero DXF: el contorno de cada
  planxa (rectangulo) y cada pieza colocada como LWPOLYLINE cerrada. Las planxas
  se separan en X para que no se solapen en el dibujo. Lanza excepcion si no se
  puede escribir. }
procedure ExportDxfResult(const AFileName: string; const AResult: TNestResult);

implementation

type
  { Par codigo/valor del DXF. }
  TDxfPair = record
    Code: Integer;
    Value: string;
  end;

function ParseFloat(const S: string): Double;
begin
  // Los DXF usan punto decimal (invariante).
  if not TryStrToFloat(Trim(S), Result, TFormatSettings.Invariant) then
    if not TryStrToFloat(Trim(S), Result) then
      Result := 0;
end;

// Carga todos los pares (codigo,valor) del fichero en orden.
procedure LoadPairs(const AFileName: string; APairs: TList<TDxfPair>);
var
  SL: TStringList;
  I: Integer;
  P: TDxfPair;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    I := 0;
    // Cada par ocupa 2 lineas: codigo y valor.
    while I + 1 < SL.Count do
    begin
      P.Code := StrToIntDef(Trim(SL[I]), -1);
      P.Value := SL[I + 1];
      APairs.Add(P);
      Inc(I, 2);
    end;
  finally
    SL.Free;
  end;
end;

// Construye un poligono-circulo de N lados.
function CirclePoly(cx, cy, r: Double; N: Integer): TPolygon2D;
var
  I: Integer;
  Ang: Double;
begin
  if N < 8 then N := 8;
  SetLength(Result.Pts, N);
  for I := 0 to N - 1 do
  begin
    Ang := 2 * Pi * I / N;
    Result.Pts[I] := TPt2D.Make(cx + r * Cos(Ang), cy + r * Sin(Ang));
  end;
end;

function ImportDxfContours(const AFileName: string;
  ACircleSegments: Integer): TArray<TDxfContour>;
var
  Pairs: TList<TDxfPair>;
  Res: TList<TDxfContour>;
  I, J: Integer;
  Ent: string;
  C: TDxfContour;

  // Cierra la lectura de una LWPOLYLINE: recorre desde J los pares 10/20 hasta
  // el fin de la entidad (codigo 0). Devuelve el poligono y avanza J.
  procedure ReadLwPolyline(var K: Integer);
  var
    Pts: TList<TPt2D>;
    X, Y: Double;
    HasX: Boolean;
    Closed: Boolean;
    Poly: TPolygon2D;
  begin
    Pts := TList<TPt2D>.Create;
    try
      X := 0; Y := 0; HasX := False; Closed := False;
      Inc(K);
      while (K < Pairs.Count) and (Pairs[K].Code <> 0) do
      begin
        case Pairs[K].Code of
          70: Closed := (StrToIntDef(Trim(Pairs[K].Value), 0) and 1) = 1;
          10:
            begin
              if HasX then begin Pts.Add(TPt2D.Make(X, Y)); end;
              X := ParseFloat(Pairs[K].Value); HasX := True;
            end;
          20: Y := ParseFloat(Pairs[K].Value);
        end;
        Inc(K);
      end;
      if HasX then Pts.Add(TPt2D.Make(X, Y));   // ultimo vertice
      if Pts.Count >= 3 then
      begin
        Poly.Pts := Pts.ToArray;
        if Poly.Area > 0 then   // solo contornos con area (cerrados de facto)
        begin
          C.Poly := Poly;
          C.Nombre := 'DXF ' + IntToStr(Res.Count + 1);
          Res.Add(C);
        end;
      end;
    finally
      Pts.Free;
    end;
    Dec(K);   // el bucle externo hara Inc; dejamos K en el 0 de la sig. entidad-1
  end;

  // Lee una POLYLINE clasica: sus vertices vienen en entidades VERTEX (codigo
  // 0 = 'VERTEX') hasta SEQEND. Cada VERTEX trae 10/20.
  procedure ReadPolyline(var K: Integer);
  var
    Pts: TList<TPt2D>;
    X, Y: Double;
    Poly: TPolygon2D;
  begin
    Pts := TList<TPt2D>.Create;
    try
      Inc(K);
      while K < Pairs.Count do
      begin
        if Pairs[K].Code = 0 then
        begin
          if SameText(Trim(Pairs[K].Value), 'VERTEX') then
          begin
            X := 0; Y := 0;
            Inc(K);
            while (K < Pairs.Count) and (Pairs[K].Code <> 0) do
            begin
              case Pairs[K].Code of
                10: X := ParseFloat(Pairs[K].Value);
                20: Y := ParseFloat(Pairs[K].Value);
              end;
              Inc(K);
            end;
            Pts.Add(TPt2D.Make(X, Y));
            Dec(K);   // compensa el Inc del while externo
          end
          else
            Break;   // SEQEND u otra entidad: fin de la polilinea
        end;
        Inc(K);
      end;
      if Pts.Count >= 3 then
      begin
        Poly.Pts := Pts.ToArray;
        if Poly.Area > 0 then
        begin
          C.Poly := Poly;
          C.Nombre := 'DXF ' + IntToStr(Res.Count + 1);
          Res.Add(C);
        end;
      end;
    finally
      Pts.Free;
    end;
    Dec(K);
  end;

  // Lee un CIRCLE: centro (10/20) y radio (40).
  procedure ReadCircle(var K: Integer);
  var
    cx, cy, r: Double;
  begin
    cx := 0; cy := 0; r := 0;
    Inc(K);
    while (K < Pairs.Count) and (Pairs[K].Code <> 0) do
    begin
      case Pairs[K].Code of
        10: cx := ParseFloat(Pairs[K].Value);
        20: cy := ParseFloat(Pairs[K].Value);
        40: r := ParseFloat(Pairs[K].Value);
      end;
      Inc(K);
    end;
    if r > 0 then
    begin
      C.Poly := CirclePoly(cx, cy, r, ACircleSegments);
      C.Nombre := 'DXF ' + IntToStr(Res.Count + 1);
      Res.Add(C);
    end;
    Dec(K);
  end;

  // Lee una SPLINE: sus puntos de control (codigos 10/20) se toman como vertices
  // del contorno (aproximacion poligonal de la curva). Los puntos leidos se
  // ANADEN a APolyPts (acumulador), porque una figura suele dibujarse con varias
  // splines encadenadas que juntas forman UN contorno cerrado.
  procedure ReadSpline(var K: Integer; APolyPts: TList<TPt2D>);
  var
    X, Y: Double;
    HasX: Boolean;
  begin
    X := 0; Y := 0; HasX := False;
    Inc(K);
    while (K < Pairs.Count) and (Pairs[K].Code <> 0) do
    begin
      case Pairs[K].Code of
        10:
          begin
            if HasX then APolyPts.Add(TPt2D.Make(X, Y));
            X := ParseFloat(Pairs[K].Value); HasX := True;
          end;
        20: Y := ParseFloat(Pairs[K].Value);
      end;
      Inc(K);
    end;
    if HasX then APolyPts.Add(TPt2D.Make(X, Y));
    Dec(K);
  end;

var
  SplinePts: TList<TPt2D>;
  SplinePoly: TPolygon2D;
begin
  Pairs := TList<TDxfPair>.Create;
  Res := TList<TDxfContour>.Create;
  SplinePts := TList<TPt2D>.Create;
  try
    LoadPairs(AFileName, Pairs);

    I := 0;
    while I < Pairs.Count do
    begin
      if Pairs[I].Code = 0 then
      begin
        Ent := UpperCase(Trim(Pairs[I].Value));
        if Ent = 'LWPOLYLINE' then
          ReadLwPolyline(I)
        else if Ent = 'POLYLINE' then
          ReadPolyline(I)
        else if Ent = 'CIRCLE' then
          ReadCircle(I)
        else if Ent = 'SPLINE' then
          // Todas las splines se encadenan en UN mismo contorno (una figura
          // suele dibujarse con varias splines seguidas). Sus puntos de control
          // aproximan la curva.
          ReadSpline(I, SplinePts);
      end;
      Inc(I);
    end;

    // Si hubo splines, formar UNA pieza con todos sus puntos de control (quitando
    // duplicados consecutivos, que aparecen donde una spline acaba y empieza la
    // siguiente).
    if SplinePts.Count >= 3 then
    begin
      SetLength(SplinePoly.Pts, 0);
      for I := 0 to SplinePts.Count - 1 do
        if (I = 0) or (not PtEqual(SplinePts[I], SplinePts[I - 1], 1e-4)) then
        begin
          SetLength(SplinePoly.Pts, Length(SplinePoly.Pts) + 1);
          SplinePoly.Pts[High(SplinePoly.Pts)] := SplinePts[I];
        end;
      // Quitar el ultimo si coincide con el primero (contorno cerrado explicito).
      if (SplinePoly.Count >= 2) and
         PtEqual(SplinePoly.Pts[0], SplinePoly.Pts[High(SplinePoly.Pts)], 1e-4) then
        SetLength(SplinePoly.Pts, Length(SplinePoly.Pts) - 1);
      if (SplinePoly.Count >= 3) and (SplinePoly.Area > 0) then
      begin
        C.Poly := SplinePoly;
        C.Nombre := 'DXF spline';
        Res.Add(C);
      end;
    end;

    Result := Res.ToArray;
  finally
    SplinePts.Free;
    Pairs.Free;
    Res.Free;
  end;
end;

{ --------------------------------------------------------------- exportar --- }

procedure ExportDxfResult(const AFileName: string; const AResult: TNestResult);
var
  SL: TStringList;
  Inv: TFormatSettings;

  procedure Pair(ACode: Integer; const AValue: string);
  begin
    SL.Add(IntToStr(ACode));
    SL.Add(AValue);
  end;

  function F(V: Double): string;
  begin
    Result := FloatToStr(V, Inv);
  end;

  // Escribe una LWPOLYLINE cerrada en la capa ALayer, con los vertices ya
  // desplazados en (AOffX, AOffY).
  procedure WritePoly(const P: TPolygon2D; const ALayer: string;
    AOffX, AOffY: Double);
  var
    I: Integer;
  begin
    if P.Count < 2 then Exit;
    Pair(0, 'LWPOLYLINE');
    Pair(8, ALayer);              // capa
    Pair(90, IntToStr(P.Count));  // numero de vertices
    Pair(70, '1');                // 1 = polilinea cerrada
    for I := 0 to High(P.Pts) do
    begin
      Pair(10, F(P.Pts[I].X + AOffX));
      Pair(20, F(P.Pts[I].Y + AOffY));
    end;
  end;

var
  I, S: Integer;
  SheetGap, OffX: Double;
  Rect: TPolygon2D;
begin
  Inv := TFormatSettings.Invariant;
  SheetGap := AResult.Sheet.Ancho * 0.1 + 50;   // separacion entre planxas en el dibujo

  SL := TStringList.Create;
  try
    // Cabecera minima: seccion ENTITIES.
    Pair(0, 'SECTION');
    Pair(2, 'ENTITIES');

    for S := 0 to AResult.Metrics.NumSheets - 1 do
    begin
      OffX := S * (AResult.Sheet.Ancho + SheetGap);

      // Contorno de la planxa (rectangulo) en la capa PLANXA.
      Rect := AResult.Sheet.AsPolygon;
      WritePoly(Rect, 'PLANXA', OffX, 0);

      // Piezas colocadas en esta planxa, en la capa PIEZAS.
      for I := 0 to High(AResult.Placements) do
        if AResult.Placements[I].SheetIndex = S then
          WritePoly(AResult.Placements[I].Placed, 'PIEZAS', OffX, 0);
    end;

    Pair(0, 'ENDSEC');
    Pair(0, 'EOF');

    SL.SaveToFile(AFileName, TEncoding.ANSI);
  finally
    SL.Free;
  end;
end;

end.
