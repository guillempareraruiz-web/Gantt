unit uNesting2DTypes;

{ ============================================================================
  Tipos y geometria base para el modulo de NESTING 2D (encaje de piezas).

  Contiene la geometria vectorial minima necesaria para el motor de nesting de
  poligonos irregulares: punto, poligono (con area, bounding box, centroide,
  rotacion, traslacion, test punto-dentro y test de solapamiento), la pieza a
  encajar (poligono + cantidad + rotaciones permitidas por veta), la planxa y
  el resultado (colocaciones + metricas).

  Sin dependencias de UI ni de BD: es matematica pura y reutilizable.
  ============================================================================ }

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections;

type
  { Punto 2D en coordenadas de milimetros (double para precision de nesting). }
  TPt2D = record
    X, Y: Double;
    class function Make(AX, AY: Double): TPt2D; static; inline;
  end;

  TPt2DArray = TArray<TPt2D>;

  { Rectangulo delimitador (bounding box). }
  TBBox = record
    MinX, MinY, MaxX, MaxY: Double;
    function Width: Double; inline;
    function Height: Double; inline;
    function IsEmpty: Boolean; inline;
    class function Empty: TBBox; static; inline;
  end;

  { Poligono simple (contorno cerrado, sin agujeros en v1). Los vertices se
    guardan en orden; el ultimo NO repite el primero (se cierra implicito). }
  TPolygon2D = record
    Pts: TPt2DArray;
    function Count: Integer; inline;
    { Area con signo (formula del shoelace). Positiva = CCW, negativa = CW. }
    function SignedArea: Double;
    { Area absoluta. }
    function Area: Double; inline;
    function BBox: TBBox;
    function Centroid: TPt2D;
    { Devuelve una copia trasladada (dx,dy). }
    function Translated(dx, dy: Double): TPolygon2D;
    { Devuelve una copia rotada AAngleDeg grados alrededor de (cx,cy). }
    function Rotated(AAngleDeg, cx, cy: Double): TPolygon2D;
    { Test punto-dentro (ray casting). Incluye borde como dentro. }
    function ContainsPoint(const P: TPt2D): Boolean;
    { Asegura orientacion CCW (area positiva); invierte si hace falta. }
    procedure EnsureCCW;
    { Construye un poligono a partir de una lista de pares X,Y. }
    class function FromCoords(const ACoords: array of Double): TPolygon2D; static;
  end;

  { Rotaciones permitidas para una pieza (restriccion de veta / fibra). }
  TVetaMode = (
    vmLibre,        // cualquier rotacion (paso configurable en el motor)
    vm0y180,        // solo 0 y 180 grados (veta que admite volteo longitudinal)
    vmFija          // solo 0 grados (veta estricta, sin rotar)
  );

  { Pieza a encajar: poligono base + cuantas copias + restriccion de veta. }
  TNestPiece = record
    Id: Integer;              // identificador de usuario
    Nombre: string;
    Base: TPolygon2D;         // contorno en su orientacion 0
    Cantidad: Integer;        // cuantas unidades hay que colocar
    Veta: TVetaMode;
    Color: Cardinal;          // color de dibujo (ARGB)
  end;

  { Planxa / lamina donde se colocan las piezas. Rectangular en v1.
    Los margenes (mm) reservan una banda en cada lado donde NO se colocan piezas
    (zona de sujecion/pinzas o seguridad de borde). Por defecto 0. }
  TSheet = record
    Ancho: Double;
    Alto: Double;
    MargenIzq, MargenDer, MargenSup, MargenInf: Double;
    function Area: Double; inline;               // area total de la planxa
    function AsPolygon: TPolygon2D;              // contorno total
    // Area util (donde se pueden colocar piezas) en coordenadas mundo:
    function UtilMinX: Double; inline;
    function UtilMinY: Double; inline;
    function UtilMaxX: Double; inline;
    function UtilMaxY: Double; inline;
    function UtilAncho: Double; inline;
    function UtilAlto: Double; inline;
  end;

  { Una pieza ya colocada en una planxa concreta del resultado. }
  TPlacement = record
    PieceId: Integer;         // Id de la TNestPiece de origen
    SheetIndex: Integer;      // en que planxa (0..N-1) quedo colocada
    AngleDeg: Double;         // rotacion aplicada
    OffsetX, OffsetY: Double; // traslacion aplicada al contorno base rotado
    Placed: TPolygon2D;       // contorno final ya rotado+trasladado (para pintar)
    Color: Cardinal;
    Nombre: string;
  end;

  { Metricas de aprovechamiento del resultado global. }
  TNestMetrics = record
    NumSheets: Integer;       // planxas usadas
    TotalPiezas: Integer;     // piezas solicitadas
    PiezasColocadas: Integer;
    PiezasSinColocar: Integer;
    AreaPiezas: Double;       // suma de areas de piezas colocadas
    AreaPlanxas: Double;      // area total de las planxas usadas
    AreaRetal: Double;        // AreaPlanxas - AreaPiezas
    Aprovechamiento: Double;  // AreaPiezas / AreaPlanxas (0..1)
    // Banda libre reaprovechable en la ULTIMA planxa (la que se esta llenando):
    LibreAncho: Double;       // mm libres a la derecha (Ancho - Xmax ocupado)
    LibreAlto: Double;        // mm libres arriba   (Alto  - Ymax ocupado)
    LibreAnchoPct: Double;    // LibreAncho / Ancho (0..1)
    LibreAltoPct: Double;     // LibreAlto  / Alto  (0..1)
  end;

  { Resultado completo de un nesting. }
  TNestResult = record
    Sheet: TSheet;
    Placements: TArray<TPlacement>;
    Metrics: TNestMetrics;
  end;

const
  EPS = 1e-9;

{ Utilidades geometricas sueltas usadas por el motor. }
function PtEqual(const A, B: TPt2D; ATol: Double = 1e-6): Boolean; inline;
function Cross(const O, A, B: TPt2D): Double; inline;   // producto cruzado (OA x OB)
function BBoxOverlap(const A, B: TBBox): Boolean; inline;

implementation

{ ---------------------------------------------------------------- TPt2D --- }

class function TPt2D.Make(AX, AY: Double): TPt2D;
begin
  Result.X := AX;
  Result.Y := AY;
end;

{ ---------------------------------------------------------------- TBBox --- }

function TBBox.Width: Double;
begin
  Result := MaxX - MinX;
end;

function TBBox.Height: Double;
begin
  Result := MaxY - MinY;
end;

function TBBox.IsEmpty: Boolean;
begin
  Result := (MaxX < MinX) or (MaxY < MinY);
end;

class function TBBox.Empty: TBBox;
begin
  Result.MinX := Infinity;
  Result.MinY := Infinity;
  Result.MaxX := NegInfinity;
  Result.MaxY := NegInfinity;
end;

{ ------------------------------------------------------------ TPolygon2D --- }

function TPolygon2D.Count: Integer;
begin
  Result := Length(Pts);
end;

function TPolygon2D.SignedArea: Double;
var
  I, J, N: Integer;
  S: Double;
begin
  N := Length(Pts);
  S := 0;
  if N < 3 then Exit(0);
  J := N - 1;
  for I := 0 to N - 1 do
  begin
    S := S + (Pts[J].X + Pts[I].X) * (Pts[J].Y - Pts[I].Y);
    J := I;
  end;
  Result := -S / 2.0;   // signo: positivo = CCW en ejes con Y hacia arriba
end;

function TPolygon2D.Area: Double;
begin
  Result := Abs(SignedArea);
end;

function TPolygon2D.BBox: TBBox;
var
  I: Integer;
begin
  Result := TBBox.Empty;
  for I := 0 to High(Pts) do
  begin
    if Pts[I].X < Result.MinX then Result.MinX := Pts[I].X;
    if Pts[I].Y < Result.MinY then Result.MinY := Pts[I].Y;
    if Pts[I].X > Result.MaxX then Result.MaxX := Pts[I].X;
    if Pts[I].Y > Result.MaxY then Result.MaxY := Pts[I].Y;
  end;
end;

function TPolygon2D.Centroid: TPt2D;
var
  I, J, N: Integer;
  A, F, Cx, Cy: Double;
begin
  N := Length(Pts);
  if N = 0 then Exit(TPt2D.Make(0, 0));
  if N < 3 then
  begin
    // media simple para degenerados
    Cx := 0; Cy := 0;
    for I := 0 to N - 1 do begin Cx := Cx + Pts[I].X; Cy := Cy + Pts[I].Y; end;
    Exit(TPt2D.Make(Cx / N, Cy / N));
  end;
  A := 0; Cx := 0; Cy := 0;
  J := N - 1;
  for I := 0 to N - 1 do
  begin
    F := Pts[J].X * Pts[I].Y - Pts[I].X * Pts[J].Y;
    A := A + F;
    Cx := Cx + (Pts[J].X + Pts[I].X) * F;
    Cy := Cy + (Pts[J].Y + Pts[I].Y) * F;
    J := I;
  end;
  A := A * 0.5;
  if Abs(A) < EPS then
  begin
    // Poligono degenerado (area ~0): caer al centro del bounding box.
    Exit(TPt2D.Make(BBox.MinX + BBox.Width / 2, BBox.MinY + BBox.Height / 2));
  end;
  Result := TPt2D.Make(Cx / (6 * A), Cy / (6 * A));
end;

function TPolygon2D.Translated(dx, dy: Double): TPolygon2D;
var
  I: Integer;
begin
  SetLength(Result.Pts, Length(Pts));
  for I := 0 to High(Pts) do
    Result.Pts[I] := TPt2D.Make(Pts[I].X + dx, Pts[I].Y + dy);
end;

function TPolygon2D.Rotated(AAngleDeg, cx, cy: Double): TPolygon2D;
var
  I: Integer;
  R, C, S, X, Y: Double;
begin
  R := DegToRad(AAngleDeg);
  C := Cos(R);
  S := Sin(R);
  SetLength(Result.Pts, Length(Pts));
  for I := 0 to High(Pts) do
  begin
    X := Pts[I].X - cx;
    Y := Pts[I].Y - cy;
    Result.Pts[I] := TPt2D.Make(cx + X * C - Y * S, cy + X * S + Y * C);
  end;
end;

function TPolygon2D.ContainsPoint(const P: TPt2D): Boolean;
var
  I, J, N: Integer;
  Inside: Boolean;
  Xi, Yi, Xj, Yj: Double;
begin
  N := Length(Pts);
  Inside := False;
  if N < 3 then Exit(False);
  J := N - 1;
  for I := 0 to N - 1 do
  begin
    Xi := Pts[I].X; Yi := Pts[I].Y;
    Xj := Pts[J].X; Yj := Pts[J].Y;
    if ((Yi > P.Y) <> (Yj > P.Y)) and
       (P.X < (Xj - Xi) * (P.Y - Yi) / (Yj - Yi + EPS) + Xi) then
      Inside := not Inside;
    J := I;
  end;
  Result := Inside;
end;

procedure TPolygon2D.EnsureCCW;
var
  I, N: Integer;
  Tmp: TPt2DArray;
begin
  if SignedArea < 0 then
  begin
    N := Length(Pts);
    SetLength(Tmp, N);
    for I := 0 to N - 1 do
      Tmp[I] := Pts[N - 1 - I];
    Pts := Tmp;
  end;
end;

class function TPolygon2D.FromCoords(const ACoords: array of Double): TPolygon2D;
var
  I, N: Integer;
begin
  N := Length(ACoords) div 2;
  SetLength(Result.Pts, N);
  for I := 0 to N - 1 do
    Result.Pts[I] := TPt2D.Make(ACoords[I * 2], ACoords[I * 2 + 1]);
end;

{ ---------------------------------------------------------------- TSheet --- }

function TSheet.Area: Double;
begin
  Result := Ancho * Alto;
end;

function TSheet.AsPolygon: TPolygon2D;
begin
  Result := TPolygon2D.FromCoords([0, 0, Ancho, 0, Ancho, Alto, 0, Alto]);
end;

function TSheet.UtilMinX: Double; begin Result := MargenIzq; end;
function TSheet.UtilMinY: Double; begin Result := MargenInf; end;
function TSheet.UtilMaxX: Double; begin Result := Ancho - MargenDer; end;
function TSheet.UtilMaxY: Double; begin Result := Alto - MargenSup; end;
function TSheet.UtilAncho: Double; begin Result := Ancho - MargenIzq - MargenDer; end;
function TSheet.UtilAlto: Double; begin Result := Alto - MargenSup - MargenInf; end;

{ -------------------------------------------------------------- utilidades --- }

function PtEqual(const A, B: TPt2D; ATol: Double): Boolean;
begin
  Result := (Abs(A.X - B.X) <= ATol) and (Abs(A.Y - B.Y) <= ATol);
end;

function Cross(const O, A, B: TPt2D): Double;
begin
  Result := (A.X - O.X) * (B.Y - O.Y) - (A.Y - O.Y) * (B.X - O.X);
end;

function BBoxOverlap(const A, B: TBBox): Boolean;
begin
  Result := (A.MinX <= B.MaxX) and (A.MaxX >= B.MinX) and
            (A.MinY <= B.MaxY) and (A.MaxY >= B.MinY);
end;

end.
