unit uNesting2DEngine;

{ ============================================================================
  Motor de NESTING 2D para poligonos irregulares.

  Estrategia (v1, robusta y determinista):
    - Se expanden las piezas segun su Cantidad y se ordenan por area
      descendente (colocar primero lo grande = mejor aprovechamiento).
    - Para cada pieza, se prueban los angulos permitidos por su modo de veta y,
      para cada angulo, posiciones sobre una REJILLA fina (paso configurable)
      recorriendo de abajo-izquierda a arriba-derecha (bottom-left-fill).
    - Una posicion es valida si el contorno rotado+trasladado (a) cabe dentro de
      la planxa y (b) no solapa con ninguna pieza ya colocada. El solapamiento
      se comprueba con pre-filtro de bounding box + test SAT poligono-poligono.
    - El KERF (separacion de corte) se aplica como margen: dos piezas no pueden
      quedar a menos de Kerf mm; se implementa exigiendo separacion en el test.
    - Si una pieza no cabe en la planxa actual, se abre una planxa nueva
      (multi-planxa). Si no cabe ni en una planxa vacia, queda "sin colocar".

  No usa No-Fit-Polygon explicito: el escaneo por rejilla es mas lento pero
  mucho mas simple de validar y suficiente para cantidades moderadas. El paso
  de rejilla equilibra calidad vs tiempo.

  Sin dependencias de UI ni BD.
  ============================================================================ }

interface

uses
  System.SysUtils, System.Math, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.Threading, System.SyncObjs,
  uNesting2DTypes;

type
  { Estrategia de ordenacion de las piezas antes de colocarlas. Cada una da un
    resultado distinto; el modo paralelo prueba varias y se queda con la mejor. }
  TNestStrategy = (
    nsGridOrder,    // respeta el orden de entrada (el del grid), sin reordenar
    nsAreaDesc,     // area descendente (grande primero) - la mas habitual
    nsHeightDesc,   // alto del bbox descendente
    nsWidthDesc,    // ancho del bbox descendente
    nsPerimDesc,    // perimetro del bbox descendente
    nsAreaAsc,      // area ascendente (pequeño primero)
    nsShuffle1,     // orden pseudoaleatorio A
    nsShuffle2,     // orden pseudoaleatorio B
    nsShuffle3      // orden pseudoaleatorio C
  );

  { Direccion hacia la que "caen" las piezas (donde se acumulan). }
  TGravityDir = (gdDown, gdUp, gdLeft, gdRight);

  { Parametros de una ejecucion de nesting. }
  TNestParams = record
    Kerf: Double;         // separacion minima entre piezas (mm)
    GridStep: Double;     // paso de la rejilla de escaneo (mm); menor = mejor y mas lento
    RotStepDeg: Double;   // paso de angulos en modo veta LIBRE (grados)
    MaxSheets: Integer;   // limite de planxas (0 = sin limite razonable)
    Strategy: TNestStrategy;  // orden usado por Run (RunParallel prueba varios)
    Gravity: TGravityDir;     // direccion de acumulacion de las piezas
    class function Default: TNestParams; static;
  end;

  { Callback de progreso (0..1). Devolver False para cancelar. }
  TNestProgress = reference to function(AFraction: Double): Boolean;

  INesting2DEngine = interface
    ['{3F1B9C22-6A44-4E7D-9B2E-77A1C0D5E101}']
    { Ejecucion simple: usa AParams.Strategy. }
    function Run(const ASheet: TSheet; const APieces: TArray<TNestPiece>;
      const AParams: TNestParams;
      const AProgress: TNestProgress = nil): TNestResult;
    { Ejecucion PARALELA multi-start: lanza varias estrategias a la vez (una por
      thread) y devuelve la mejor (mas piezas colocadas; a igualdad, mejor
      aprovechamiento). Aprovecha todos los nucleos y mejora la calidad. }
    function RunParallel(const ASheet: TSheet; const APieces: TArray<TNestPiece>;
      const AParams: TNestParams;
      const AProgress: TNestProgress = nil): TNestResult;
  end;

  TNesting2DEngine = class(TInterfacedObject, INesting2DEngine)
  private
    type
      { Instancia expandida (una unidad concreta de una pieza). }
      TInst = record
        PieceId: Integer;
        Nombre: string;
        Color: Cardinal;
        Base: TPolygon2D;       // normalizada: bbox con esquina en (0,0)
        Angles: TArray<Double>; // angulos a probar segun veta
        AreaVal: Double;
      end;
      { Pieza colocada durante el proceso (con su bbox cacheada). }
      TPlaced = record
        Poly: TPolygon2D;
        Box: TBBox;
      end;
  private
    function BuildAngles(AVeta: TVetaMode; ARotStep: Double): TArray<Double>;
    function NormalizeToOrigin(const APoly: TPolygon2D): TPolygon2D;
    function PolysSeparated(const A, B: TPolygon2D; const ABoxA, ABoxB: TBBox;
      AKerf: Double): Boolean;
    function PolysOverlap(const A, B: TPolygon2D): Boolean;
    function SegmentsIntersect(const P1, P2, P3, P4: TPt2D): Boolean;
    function FitsInSheet(const APoly: TPolygon2D; const ASheet: TSheet): Boolean;
    function CollidesWithPlaced(const APoly: TPolygon2D; const ABox: TBBox;
      const APlaced: TList<TPlaced>; AKerf: Double): Boolean;
    function CollidesDir(const APoly: TPolygon2D; const ABox: TBBox;
      const APlaced: TList<TPlaced>; AKerf: Double; AVertical: Boolean;
      APosSign: Double; var AJump: Double): Boolean;
    function TryPlaceOnSheet(const AInst: TInst; const ASheet: TSheet;
      const APlaced: TList<TPlaced>; const AParams: TNestParams;
      out APlacement: TPolygon2D; out AAngle: Double): Boolean;
    function SortKey(const AInst: TInst; AStrategy: TNestStrategy): Double;
    procedure SortInstances(const AInsts: TList<TInst>; AStrategy: TNestStrategy);
  public
    function Run(const ASheet: TSheet; const APieces: TArray<TNestPiece>;
      const AParams: TNestParams;
      const AProgress: TNestProgress): TNestResult;
    function RunParallel(const ASheet: TSheet; const APieces: TArray<TNestPiece>;
      const AParams: TNestParams;
      const AProgress: TNestProgress): TNestResult;
  end;

function CreateNesting2DEngine: INesting2DEngine;

implementation

const
  MAX_PROBES = 2000000;   // tope duro de posiciones probadas por pieza (anti-cuelgue)

function CreateNesting2DEngine: INesting2DEngine;
begin
  Result := TNesting2DEngine.Create;
end;

{ ------------------------------------------------------------ TNestParams --- }

class function TNestParams.Default: TNestParams;
begin
  Result.Kerf := 3.0;
  Result.GridStep := 5.0;
  Result.RotStepDeg := 90.0;
  Result.MaxSheets := 50;
  Result.Gravity := gdDown;
  Result.Strategy := nsAreaDesc;
end;

{ ------------------------------------------------------- TNesting2DEngine --- }

function TNesting2DEngine.BuildAngles(AVeta: TVetaMode;
  ARotStep: Double): TArray<Double>;
var
  L: TList<Double>;
  A: Double;
begin
  L := TList<Double>.Create;
  try
    case AVeta of
      vmFija:
        L.Add(0);
      vm0y180:
        begin
          L.Add(0);
          L.Add(180);
        end;
      vmLibre:
        begin
          if ARotStep <= 0 then ARotStep := 90;
          A := 0;
          while A < 360 - EPS do
          begin
            L.Add(A);
            A := A + ARotStep;
          end;
        end;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TNesting2DEngine.NormalizeToOrigin(const APoly: TPolygon2D): TPolygon2D;
var
  B: TBBox;
begin
  B := APoly.BBox;
  Result := APoly.Translated(-B.MinX, -B.MinY);
end;

function TNesting2DEngine.FitsInSheet(const APoly: TPolygon2D;
  const ASheet: TSheet): Boolean;
var
  B: TBBox;
begin
  B := APoly.BBox;
  Result := (B.MinX >= -EPS) and (B.MinY >= -EPS) and
            (B.MaxX <= ASheet.Ancho + EPS) and (B.MaxY <= ASheet.Alto + EPS);
end;

function TNesting2DEngine.SegmentsIntersect(const P1, P2, P3, P4: TPt2D): Boolean;
var
  d1, d2, d3, d4: Double;
begin
  d1 := Cross(P3, P4, P1);
  d2 := Cross(P3, P4, P2);
  d3 := Cross(P1, P2, P3);
  d4 := Cross(P1, P2, P4);
  Result :=
    (((d1 > EPS) and (d2 < -EPS)) or ((d1 < -EPS) and (d2 > EPS))) and
    (((d3 > EPS) and (d4 < -EPS)) or ((d3 < -EPS) and (d4 > EPS)));
end;

// Infla un poligono empujando cada vertice AKerf/2 hacia afuera desde su
// centroide. Aproximacion sencilla del "offset" para exigir separacion de corte;
// suficiente para el test de separacion (dos piezas infladas media kerf cada una
// no deben solaparse -> quedan al menos kerf de distancia).
function InflatePolygon(const P: TPolygon2D; AKerf: Double): TPolygon2D;
var
  C: TPt2D;
  I: Integer;
  dx, dy, len, off: Double;
begin
  C := P.Centroid;
  off := AKerf / 2;
  SetLength(Result.Pts, P.Count);
  for I := 0 to High(P.Pts) do
  begin
    dx := P.Pts[I].X - C.X;
    dy := P.Pts[I].Y - C.Y;
    len := Sqrt(dx * dx + dy * dy);
    if len < EPS then
      Result.Pts[I] := P.Pts[I]
    else
      Result.Pts[I] := TPt2D.Make(
        P.Pts[I].X + dx / len * off,
        P.Pts[I].Y + dy / len * off);
  end;
end;

// Proyeccion de un poligono sobre un eje (nx,ny): min y max del producto escalar.
procedure ProjectPoly(const P: TPolygon2D; nx, ny: Double; out AMin, AMax: Double);
var
  I: Integer;
  D: Double;
begin
  AMin := 1e300; AMax := -1e300;
  for I := 0 to High(P.Pts) do
  begin
    D := P.Pts[I].X * nx + P.Pts[I].Y * ny;
    if D < AMin then AMin := D;
    if D > AMax then AMax := D;
  end;
end;

function TNesting2DEngine.PolysOverlap(const A, B: TPolygon2D): Boolean;
// Test SAT (Separating Axis Theorem). Para cada arista de A y de B se prueba su
// normal como eje separador: si las proyecciones de A y B NO se solapan en algun
// eje, los poligonos estan separados. Es infalible para convexos (rectangulos,
// triangulos) y conservador (nunca infra-detecta) para el resto. Sustituye al
// test anterior de interseccion de segmentos, que fallaba con lados colineales
// (rectangulos identicos en la misma rejilla se colaban solapados).
  function SeparatedByEdges(const P, Q: TPolygon2D): Boolean;
  var
    I, N: Integer;
    ex, ey, nx, ny, len: Double;
    minP, maxP, minQ, maxQ: Double;
  begin
    N := P.Count;
    for I := 0 to N - 1 do
    begin
      // arista I -> I+1 ; normal = (-ey, ex)
      ex := P.Pts[(I + 1) mod N].X - P.Pts[I].X;
      ey := P.Pts[(I + 1) mod N].Y - P.Pts[I].Y;
      nx := -ey; ny := ex;
      len := Sqrt(nx * nx + ny * ny);
      if len < EPS then Continue;
      nx := nx / len; ny := ny / len;
      ProjectPoly(P, nx, ny, minP, maxP);
      ProjectPoly(Q, nx, ny, minQ, maxQ);
      // Si hay hueco en este eje -> separados (no solapan).
      if (maxP <= minQ + EPS) or (maxQ <= minP + EPS) then Exit(True);
    end;
    Result := False;
  end;
begin
  if (A.Count < 3) or (B.Count < 3) then Exit(False);
  // Solapan si NINGUN eje (de A ni de B) los separa.
  Result := not (SeparatedByEdges(A, B) or SeparatedByEdges(B, A));
end;

function TNesting2DEngine.PolysSeparated(const A, B: TPolygon2D;
  const ABoxA, ABoxB: TBBox; AKerf: Double): Boolean;
var
  BoxAExp: TBBox;
  BInf: TPolygon2D;
begin
  // Pre-filtro bbox con margen kerf: si los bbox (inflados el kerf) no se tocan,
  // estan separados seguro y nos ahorramos el SAT.
  BoxAExp := ABoxA;
  BoxAExp.MinX := BoxAExp.MinX - AKerf;
  BoxAExp.MinY := BoxAExp.MinY - AKerf;
  BoxAExp.MaxX := BoxAExp.MaxX + AKerf;
  BoxAExp.MaxY := BoxAExp.MaxY + AKerf;
  if not BBoxOverlap(BoxAExp, ABoxB) then Exit(True);

  // Test real: se exige separacion >= kerf. Se aproxima inflando B su centroide
  // hacia afuera el kerf (escalado ligero) y comprobando que A no solape con B
  // inflado. Para el caso comun (piezas axis-aligned) el pre-filtro bbox ya
  // garantiza el kerf; aqui el SAT asegura que no haya solapamiento real.
  if AKerf > 0 then
    BInf := InflatePolygon(B, AKerf)
  else
    BInf := B;
  Result := not PolysOverlap(A, BInf);
end;

// Colision del poligono APoly contra las piezas colocadas, con separacion kerf.
// True = colisiona. En AJump devuelve el "borde frontal" del obstaculo en la
// direccion de caida, para saltar justo mas alla en vez de avanzar de 1 en 1:
//   AVertical=True  -> eje Y (PosSign>0: MaxY del obstaculo; <0: MinY)
//   AVertical=False -> eje X (PosSign>0: MaxX; <0: MinX)
function TNesting2DEngine.CollidesDir(const APoly: TPolygon2D; const ABox: TBBox;
  const APlaced: TList<TPlaced>; AKerf: Double; AVertical: Boolean;
  APosSign: Double; var AJump: Double): Boolean;
var
  K: Integer;
  Edge: Double;
  First: Boolean;
begin
  Result := False;
  First := True;
  AJump := 0;
  for K := 0 to APlaced.Count - 1 do
  begin
    if (ABox.MaxX + AKerf < APlaced[K].Box.MinX) or
       (ABox.MinX - AKerf > APlaced[K].Box.MaxX) or
       (ABox.MaxY + AKerf < APlaced[K].Box.MinY) or
       (ABox.MinY - AKerf > APlaced[K].Box.MaxY) then
      Continue;
    if not PolysSeparated(APoly, APlaced[K].Poly, ABox, APlaced[K].Box, AKerf) then
    begin
      Result := True;
      if AVertical then
        if APosSign > 0 then Edge := APlaced[K].Box.MaxY else Edge := APlaced[K].Box.MinY
      else
        if APosSign > 0 then Edge := APlaced[K].Box.MaxX else Edge := APlaced[K].Box.MinX;
      // Guardar el borde "mas lejano" en la direccion de avance (para saltar todos).
      if First then begin AJump := Edge; First := False; end
      else if APosSign > 0 then
        begin if Edge > AJump then AJump := Edge; end
      else
        begin if Edge < AJump then AJump := Edge; end;
    end;
  end;
end;

// Version simple (solo colision).
function TNesting2DEngine.CollidesWithPlaced(const APoly: TPolygon2D;
  const ABox: TBBox; const APlaced: TList<TPlaced>; AKerf: Double): Boolean;
var
  Dummy: Double;
begin
  Result := CollidesDir(APoly, ABox, APlaced, AKerf, True, 1, Dummy);
end;

function TNesting2DEngine.TryPlaceOnSheet(const AInst: TInst;
  const ASheet: TSheet; const APlaced: TList<TPlaced>;
  const AParams: TNestParams; out APlacement: TPolygon2D;
  out AAngle: Double): Boolean;
var
  Ai, Gs: Integer;
  Ang, Sc, Dr, RestDr, Jump, StepS, StepD, MaxDr, MaxSc, ScoreDr, BestScore: Double;
  Vertical: Boolean;   // eje de caida = Y (down/up) o X (left/right)
  PosSign: Double;     // +1 = acumula en 0 y avanza; -1 = acumula en Max y retrocede
  RotBase, Cand, RestPoly: TPolygon2D;
  RotBox, CandBox: TBBox;
  Probes: Integer;
  Found, Landed: Boolean;
  BestSc: Double;

  // Coloca la base con coord. de caida = ADr, coord. de escaneo = ASc. Se suma
  // el origen del area util (margenes) para que las piezas nunca invadan la
  // banda de margen.
  function Place(ADr, ASc: Double): TPolygon2D;
  begin
    if Vertical then
      Result := RotBase.Translated(ASheet.UtilMinX + ASc, ASheet.UtilMinY + ADr)
    else
      Result := RotBase.Translated(ASheet.UtilMinX + ADr, ASheet.UtilMinY + ASc);
  end;

begin
  Result := False;
  Found := False;
  Probes := 0;
  StepS := AParams.GridStep; if StepS <= 0 then StepS := 5;
  StepD := StepS;

  // Direccion de gravedad -> eje de caida (Dr) y de escaneo (Sc):
  //   gdDown : Dr=Y acumula en 0 ; gdUp : Dr=Y acumula en Max
  //   gdLeft : Dr=X acumula en 0 ; gdRight: Dr=X acumula en Max
  Vertical := AParams.Gravity in [gdDown, gdUp];
  if AParams.Gravity in [gdDown, gdLeft] then PosSign := 1 else PosSign := -1;

  BestScore := 1e300;   // menor = mas acumulado en la direccion de gravedad
  BestSc := 1e300;

  for Ai := 0 to High(AInst.Angles) do
  begin
    Ang := AInst.Angles[Ai];
    if Ang = 0 then
      RotBase := AInst.Base
    else
      RotBase := NormalizeToOrigin(AInst.Base.Rotated(Ang, 0, 0));
    RotBox := RotBase.BBox;

    // La pieza debe caber en el AREA UTIL (planxa menos margenes).
    if (RotBox.Width > ASheet.UtilAncho + EPS) or
       (RotBox.Height > ASheet.UtilAlto + EPS) then
      Continue;

    if Vertical then
    begin
      MaxDr := ASheet.UtilAlto - RotBox.Height;
      MaxSc := ASheet.UtilAncho - RotBox.Width;
    end
    else
    begin
      MaxDr := ASheet.UtilAncho - RotBox.Width;
      MaxSc := ASheet.UtilAlto - RotBox.Height;
    end;
    if (MaxDr < -EPS) or (MaxSc < -EPS) then Continue;

    Gs := 0;
    Sc := 0;
    while Sc <= MaxSc + EPS do
    begin
      Inc(Probes);
      if Probes > MAX_PROBES then begin Result := Found; Exit; end;

      // CAIDA: partir del borde de acumulacion y avanzar hasta el primer hueco.
      Landed := False;
      RestDr := 0;
      if PosSign > 0 then Dr := 0 else Dr := MaxDr;
      while (Dr >= -EPS) and (Dr <= MaxDr + EPS) do
      begin
        Cand := Place(Dr, Sc);
        CandBox := Cand.BBox;
        Jump := 0;
        if not CollidesDir(Cand, CandBox, APlaced, AParams.Kerf,
                           Vertical, PosSign, Jump) then
        begin
          RestDr := Dr; RestPoly := Cand;
          Landed := True;
          Break;
        end;
        // Saltar mas alla del obstaculo (borde frontal Jump) en la direccion.
        if PosSign > 0 then
        begin
          if Jump > Dr + StepD then Dr := Jump + AParams.Kerf else Dr := Dr + StepD;
        end
        else
        begin
          if Jump < Dr - StepD then Dr := Jump - AParams.Kerf else Dr := Dr - StepD;
        end;
      end;

      if Landed then
      begin
        // Puntuacion: distancia al borde de acumulacion (menor = mas acumulado).
        if PosSign > 0 then ScoreDr := RestDr else ScoreDr := MaxDr - RestDr;
        if (ScoreDr < BestScore - EPS) or
           ((Abs(ScoreDr - BestScore) <= EPS) and (Sc < BestSc)) then
        begin
          BestScore := ScoreDr; BestSc := Sc;
          APlacement := RestPoly;
          AAngle := Ang;
          Found := True;
        end;
      end;

      Inc(Gs);
      Sc := Gs * StepS;
    end;
  end;

  Result := Found;
end;

function TNesting2DEngine.Run(const ASheet: TSheet;
  const APieces: TArray<TNestPiece>; const AParams: TNestParams;
  const AProgress: TNestProgress): TNestResult;
var
  Insts: TList<TInst>;
  Inst: TInst;
  I, C, SheetIdx, TotalReq, Done: Integer;
  Sheets: TList<TList<TPlaced>>;
  Placements: TList<TPlacement>;
  Norm: TPolygon2D;
  PlacedPoly: TPolygon2D;
  Ang: Double;
  Pl: TPlacement;
  Placed: TPlaced;
  DstSheet: TList<TPlaced>;
  Colocada: Boolean;
  M: TNestMetrics;
  MaxXOcup, MaxYOcup: Double;
  UltSheet: Integer;
  HayEnUltima: Boolean;
  B: TBBox;
begin
  Insts := TList<TInst>.Create;
  Sheets := TObjectList<TList<TPlaced>>.Create(True);
  Placements := TList<TPlacement>.Create;
  try
    // 1) Expandir instancias (una por unidad) y precalcular base normalizada,
    //    angulos y area. Ordenar por area descendente.
    TotalReq := 0;
    for I := 0 to High(APieces) do
    begin
      Norm := NormalizeToOrigin(APieces[I].Base);
      Norm.EnsureCCW;
      for C := 1 to Max(1, APieces[I].Cantidad) do
      begin
        Inst.PieceId := APieces[I].Id;
        Inst.Nombre := APieces[I].Nombre;
        Inst.Color := APieces[I].Color;
        Inst.Base := Norm;
        Inst.Angles := BuildAngles(APieces[I].Veta, AParams.RotStepDeg);
        Inst.AreaVal := Norm.Area;
        Insts.Add(Inst);
        Inc(TotalReq);
      end;
    end;

    SortInstances(Insts, AParams.Strategy);

    // 2) Colocar cada instancia: probar planxas existentes; si no cabe, abrir
    //    una nueva (hasta MaxSheets).
    Done := 0;
    for I := 0 to Insts.Count - 1 do
    begin
      Inst := Insts[I];
      Colocada := False;

      for SheetIdx := 0 to Sheets.Count - 1 do
      begin
        if TryPlaceOnSheet(Inst, ASheet, Sheets[SheetIdx], AParams,
                           PlacedPoly, Ang) then
        begin
          DstSheet := Sheets[SheetIdx];
          Colocada := True;
          Break;
        end;
      end;

      if not Colocada then
      begin
        if (AParams.MaxSheets <= 0) or (Sheets.Count < AParams.MaxSheets) then
        begin
          DstSheet := TList<TPlaced>.Create;
          Sheets.Add(DstSheet);
          SheetIdx := Sheets.Count - 1;
          if TryPlaceOnSheet(Inst, ASheet, DstSheet, AParams,
                             PlacedPoly, Ang) then
            Colocada := True
          else
          begin
            // No cabe ni en una planxa vacia: no cabra nunca -> quitar la planxa
            // vacia que acabamos de crear.
            Sheets.Delete(Sheets.Count - 1);
          end;
        end
        else
        begin
          // Limite de planxas alcanzado y esta pieza no cabe en las existentes.
          // Solo cortamos si el orden es por area DESCENDENTE: entonces las que
          // quedan son >= y tampoco cabran (evita escanear en balde en "Maximo").
          // Con nsGridOrder NO se corta: piezas mas pequeñas despues aun podrian
          // caber.
          if (AParams.MaxSheets > 0) and (AParams.Strategy = nsAreaDesc) then Break;
        end;
      end;

      if Colocada then
      begin
        Placed.Poly := PlacedPoly;
        Placed.Box := PlacedPoly.BBox;
        DstSheet.Add(Placed);

        Pl.PieceId := Inst.PieceId;
        Pl.SheetIndex := SheetIdx;
        Pl.AngleDeg := Ang;
        Pl.OffsetX := PlacedPoly.BBox.MinX;
        Pl.OffsetY := PlacedPoly.BBox.MinY;
        Pl.Placed := PlacedPoly;
        Pl.Color := Inst.Color;
        Pl.Nombre := Inst.Nombre;
        Placements.Add(Pl);
      end;

      Inc(Done);
      if Assigned(AProgress) then
        if not AProgress(Done / Max(1, Insts.Count)) then Break;
    end;

    // 3) Metricas.
    M.NumSheets := Sheets.Count;
    M.TotalPiezas := TotalReq;
    M.PiezasColocadas := Placements.Count;
    M.PiezasSinColocar := TotalReq - Placements.Count;
    M.AreaPiezas := 0;
    for I := 0 to Placements.Count - 1 do
      M.AreaPiezas := M.AreaPiezas + Placements[I].Placed.Area;
    M.AreaPlanxas := Sheets.Count * ASheet.Area;
    M.AreaRetal := M.AreaPlanxas - M.AreaPiezas;
    if M.AreaPlanxas > 0 then
      M.Aprovechamiento := M.AreaPiezas / M.AreaPlanxas
    else
      M.Aprovechamiento := 0;

    // Banda libre reaprovechable en la ULTIMA planxa: buscar el X y el Y maximos
    // ocupados por las piezas de esa planxa; lo que queda a la derecha/arriba es
    // tira aprovechable. (Coord. mundo: bbox de cada pieza colocada.)
    M.LibreAncho := ASheet.Ancho;
    M.LibreAlto := ASheet.Alto;
    if (Sheets.Count > 0) and (Placements.Count > 0) then
    begin
      MaxXOcup := 0; MaxYOcup := 0; HayEnUltima := False;
      UltSheet := Sheets.Count - 1;
      for I := 0 to Placements.Count - 1 do
        if Placements[I].SheetIndex = UltSheet then
        begin
          B := Placements[I].Placed.BBox;
          if B.MaxX > MaxXOcup then MaxXOcup := B.MaxX;
          if B.MaxY > MaxYOcup then MaxYOcup := B.MaxY;
          HayEnUltima := True;
        end;
      if HayEnUltima then
      begin
        M.LibreAncho := ASheet.Ancho - MaxXOcup;
        M.LibreAlto := ASheet.Alto - MaxYOcup;
      end;
    end;
    if M.LibreAncho < 0 then M.LibreAncho := 0;
    if M.LibreAlto < 0 then M.LibreAlto := 0;
    if ASheet.Ancho > 0 then M.LibreAnchoPct := M.LibreAncho / ASheet.Ancho else M.LibreAnchoPct := 0;
    if ASheet.Alto > 0 then M.LibreAltoPct := M.LibreAlto / ASheet.Alto else M.LibreAltoPct := 0;

    Result.Sheet := ASheet;
    Result.Placements := Placements.ToArray;
    Result.Metrics := M;
  finally
    Placements.Free;
    Sheets.Free;
    Insts.Free;
  end;
end;

function TNesting2DEngine.SortKey(const AInst: TInst;
  AStrategy: TNestStrategy): Double;
var
  B: TBBox;
begin
  B := AInst.Base.BBox;
  case AStrategy of
    nsHeightDesc: Result := B.Height;
    nsWidthDesc:  Result := B.Width;
    nsPerimDesc:  Result := B.Width + B.Height;
  else
    Result := AInst.AreaVal;
  end;
end;

procedure TNesting2DEngine.SortInstances(const AInsts: TList<TInst>;
  AStrategy: TNestStrategy);
var
  Seed: Integer;
begin
  case AStrategy of
    nsGridOrder:
      ;   // no reordenar: se respeta el orden de entrada (el del grid)
    nsShuffle1, nsShuffle2, nsShuffle3:
      begin
        // Barajado determinista (sin Random, que romperia la reproducibilidad):
        // se ordena por una clave hash estable dependiente de la estrategia.
        case AStrategy of
          nsShuffle1: Seed := 1103515245;
          nsShuffle2: Seed := 214013;
        else          Seed := 2654435761;
        end;
        AInsts.Sort(TComparer<TInst>.Construct(
          function(const L, R: TInst): Integer
          var
            HL, HR: Cardinal;
          begin
            HL := Cardinal((L.PieceId + 7) * Seed);
            HR := Cardinal((R.PieceId + 7) * Seed);
            // mezcla con el area para variar el orden entre instancias iguales
            HL := HL xor Cardinal(Round(L.AreaVal * 13.7));
            HR := HR xor Cardinal(Round(R.AreaVal * 13.7));
            if HL < HR then Result := -1
            else if HL > HR then Result := 1
            else Result := 0;
          end));
      end;
    nsAreaAsc:
      AInsts.Sort(TComparer<TInst>.Construct(
        function(const L, R: TInst): Integer
        begin
          if L.AreaVal < R.AreaVal then Result := -1
          else if L.AreaVal > R.AreaVal then Result := 1
          else Result := 0;
        end));
  else
    // Descendente por la clave correspondiente (area/alto/ancho/perimetro).
    AInsts.Sort(TComparer<TInst>.Construct(
      function(const L, R: TInst): Integer
      var
        KL, KR: Double;
      begin
        KL := SortKey(L, AStrategy); KR := SortKey(R, AStrategy);
        if KL > KR then Result := -1
        else if KL < KR then Result := 1
        else Result := 0;
      end));
  end;
end;

function TNesting2DEngine.RunParallel(const ASheet: TSheet;
  const APieces: TArray<TNestPiece>; const AParams: TNestParams;
  const AProgress: TNestProgress): TNestResult;
const
  ESTRATEGIAS: array[0..7] of TNestStrategy = (
    nsAreaDesc, nsHeightDesc, nsWidthDesc, nsPerimDesc,
    nsAreaAsc, nsShuffle1, nsShuffle2, nsShuffle3);
var
  Results: array[0..7] of TNestResult;
  Cancelled: Boolean;
  Lock: TCriticalSection;
  BestIdx, I: Integer;
  Best, Cur: TNestResult;
begin
  // Multi-start paralelo: cada estrategia corre en su propia tarea (thread del
  // pool). El nesting es independiente entre estrategias, asi que escala con los
  // nucleos. Al final se elige el mejor resultado. Un solo callback de progreso
  // (protegido) permite cancelar todas las tareas.
  Cancelled := False;
  Lock := TCriticalSection.Create;
  try
    TParallel.For(0, High(ESTRATEGIAS),
      procedure(Idx: Integer)
      var
        LParams: TNestParams;
        LEngine: TNesting2DEngine;
      begin
        if Cancelled then Exit;
        LParams := AParams;
        LParams.Strategy := ESTRATEGIAS[Idx];
        // Instancia propia por tarea: los metodos no guardan estado, pero asi
        // se evita cualquier comparticion accidental.
        LEngine := TNesting2DEngine.Create;
        try
          Results[Idx] := LEngine.Run(ASheet, APieces, LParams,
            function(AFraction: Double): Boolean
            begin
              // Progreso agregado aproximado; el callback externo puede cancelar.
              if Assigned(AProgress) then
              begin
                Lock.Enter;
                try
                  if not AProgress(AFraction) then Cancelled := True;
                finally
                  Lock.Leave;
                end;
              end;
              Result := not Cancelled;
            end);
        finally
          LEngine.Free;
        end;
      end);
  finally
    Lock.Free;
  end;

  // Elegir el mejor: mas piezas colocadas; a igualdad, mayor aprovechamiento;
  // a igualdad, menos planxas.
  BestIdx := 0;
  Best := Results[0];
  for I := 1 to High(ESTRATEGIAS) do
  begin
    Cur := Results[I];
    if (Cur.Metrics.PiezasColocadas > Best.Metrics.PiezasColocadas) or
       ((Cur.Metrics.PiezasColocadas = Best.Metrics.PiezasColocadas) and
        (Cur.Metrics.NumSheets < Best.Metrics.NumSheets)) or
       ((Cur.Metrics.PiezasColocadas = Best.Metrics.PiezasColocadas) and
        (Cur.Metrics.NumSheets = Best.Metrics.NumSheets) and
        (Cur.Metrics.Aprovechamiento > Best.Metrics.Aprovechamiento)) then
    begin
      Best := Cur;
      BestIdx := I;
    end;
  end;
  Result := Best;
end;

end.
