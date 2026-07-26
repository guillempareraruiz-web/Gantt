unit uWbsSobrecarga;

{
  Deteccion de SOBREASIGNACION de operarios (Modulo de Proyectos, paradigma
  TAREAS).

  El problema que resuelve: la ficha de tarea deja asignar operarios con un % de
  dedicacion, pero nadie comprobaba que esa persona no estuviera ya al 100% en
  otra tarea a la vez. Se podia asignar a alguien al 300% sin que nada avisara,
  y el plan salia "verde" siendo imposible.

  Como funciona: barrido de eventos (sweep line) sobre los intervalos de cada
  persona. Se ordenan los instantes de entrada y salida de cada tarea, se
  recorren acumulando dedicacion, y cada tramo donde el acumulado pasa de 100 %
  es una sobrecarga. Es O(n log n) por operario, no O(n^2).

  Solo mira el SOLAPE EN EL TIEMPO, no el calendario laborable: si dos tareas se
  pisan en fechas, la persona esta sobreasignada aunque el solape caiga en fin
  de semana. Afinar eso exigiria intersecar turnos por persona (que el modelo no
  tiene) y no cambiaria la conclusion.
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.DateUtils,
  System.Generics.Collections, System.Generics.Defaults,
  uWbsTypes;

// Tramos en los que alguien supera el 100% de su jornada. AUmbral es el % a
// partir del cual se considera sobrecarga (100 = a tope; 105 daria margen a los
// redondeos). Devuelve un tramo por cada periodo continuo de exceso, con su
// pico y las tareas implicadas.
function DetectarSobrecargas(const ACargas: TWbsCargaArray;
  AUmbral: Double = 100): TWbsSobrecargaArray;

// NodeIds implicados en alguna sobrecarga, para que la vista pueda marcarlos
// sin recorrer los tramos ella misma. El llamante libera.
function NodosSobrecargados(
  const ASobrecargas: TWbsSobrecargaArray): TDictionary<Integer, Boolean>;

implementation

type
  // Un instante en el que la carga de una persona cambia: entra (+Delta) o
  // sale (-Delta) una tarea.
  TEvento = record
    Instante: TDateTime;
    Delta: Double;      // + al entrar, - al salir
    NodeId: Integer;
    Entra: Boolean;
  end;

function DetectarSobrecargas(const ACargas: TWbsCargaArray;
  AUmbral: Double): TWbsSobrecargaArray;
var
  PorOperario: TObjectDictionary<Integer, TList<TWbsCarga>>;
  Lst: TList<TWbsCarga>;
  Eventos: TList<TEvento>;
  Ev: TEvento;
  Res: TList<TWbsSobrecarga>;
  Sob: TWbsSobrecarga;
  Activas: TDictionary<Integer, Boolean>;
  Par: TPair<Integer, TList<TWbsCarga>>;
  I, J: Integer;
  Acum, Pico: Double;
  EnSobrecarga: Boolean;
  Desde: TDateTime;
  NodeIdsTramo: TList<Integer>;
  Clave: Integer;
begin
  SetLength(Result, 0);
  if Length(ACargas) = 0 then Exit;
  if AUmbral <= 0 then AUmbral := 100;

  PorOperario := TObjectDictionary<Integer, TList<TWbsCarga>>.Create([doOwnsValues]);
  Res := TList<TWbsSobrecarga>.Create;
  try
    // Agrupar por persona: la sobrecarga es de alguien, no del proyecto.
    for I := 0 to High(ACargas) do
    begin
      if ACargas[I].OperatorId <= 0 then Continue;
      // Sin fecha de fin no hay intervalo que solapar.
      if (ACargas[I].FechaInicio <= 0) or
         (ACargas[I].FechaFin <= ACargas[I].FechaInicio) then Continue;
      // Dedicacion 0 no carga a nadie: incluirla la listaria como implicada en
      // un exceso que no ha causado.
      if ACargas[I].Dedicacion <= 0 then Continue;

      if not PorOperario.TryGetValue(ACargas[I].OperatorId, Lst) then
      begin
        Lst := TList<TWbsCarga>.Create;
        PorOperario.Add(ACargas[I].OperatorId, Lst);
      end;
      Lst.Add(ACargas[I]);
    end;

    for Par in PorOperario do
    begin
      Lst := Par.Value;
      if Lst.Count < 1 then Continue;

      Eventos := TList<TEvento>.Create;
      Activas := TDictionary<Integer, Boolean>.Create;
      NodeIdsTramo := TList<Integer>.Create;
      try
        for I := 0 to Lst.Count - 1 do
        begin
          Ev.Instante := Lst[I].FechaInicio;
          Ev.Delta := Lst[I].Dedicacion;
          Ev.NodeId := Lst[I].NodeId;
          Ev.Entra := True;
          Eventos.Add(Ev);

          Ev.Instante := Lst[I].FechaFin;
          Ev.Delta := -Lst[I].Dedicacion;
          Ev.NodeId := Lst[I].NodeId;
          Ev.Entra := False;
          Eventos.Add(Ev);
        end;

        // Orden temporal. A igualdad de instante, las SALIDAS van primero: si
        // una tarea acaba justo cuando empieza la siguiente NO hay solape, y
        // procesar antes la entrada daria un pico fantasma.
        Eventos.Sort(TComparer<TEvento>.Construct(
          function(const A, B: TEvento): Integer
          begin
            Result := CompareDateTime(A.Instante, B.Instante);
            if Result = 0 then
            begin
              if A.Entra = B.Entra then
                Result := 0
              else if A.Entra then
                Result := 1      // la que entra, despues
              else
                Result := -1;    // la que sale, antes
            end;
          end));

        Acum := 0;
        Pico := 0;
        EnSobrecarga := False;
        Desde := 0;

        for I := 0 to Eventos.Count - 1 do
        begin
          if Eventos[I].Entra then
            Activas.AddOrSetValue(Eventos[I].NodeId, True)
          else
            Activas.Remove(Eventos[I].NodeId);

          Acum := Acum + Eventos[I].Delta;
          if Acum < 0 then Acum := 0;   // defensa contra datos incoherentes

          if (not EnSobrecarga) and (Acum > AUmbral) then
          begin
            // Arranca un tramo de sobrecarga.
            EnSobrecarga := True;
            Desde := Eventos[I].Instante;
            Pico := Acum;
            NodeIdsTramo.Clear;
            for Clave in Activas.Keys do
              NodeIdsTramo.Add(Clave);
          end
          else if EnSobrecarga then
          begin
            if Acum > Pico then Pico := Acum;
            // Toda tarea que este activa mientras dura el exceso cuenta como
            // implicada, tanto si ya estaba al arrancar el tramo como si entra
            // despues. NO se quitan las que salen: han contribuido al exceso
            // mientras estaban, y sacarlas de la lista esconderia justamente a
            // la tarea que hay que mover para resolverlo.
            if Eventos[I].Entra and
               (NodeIdsTramo.IndexOf(Eventos[I].NodeId) < 0) then
              NodeIdsTramo.Add(Eventos[I].NodeId);

            if Acum <= AUmbral then
            begin
              // Se acaba el tramo: emitirlo.
              Sob := Default(TWbsSobrecarga);
              Sob.OperatorId := Par.Key;
              Sob.Nombre := Lst[0].Nombre;
              Sob.Desde := Desde;
              Sob.Hasta := Eventos[I].Instante;
              Sob.PorcentajePico := Pico;
              SetLength(Sob.NodeIds, NodeIdsTramo.Count);
              for J := 0 to NodeIdsTramo.Count - 1 do
                Sob.NodeIds[J] := NodeIdsTramo[J];
              Res.Add(Sob);

              EnSobrecarga := False;
              Pico := 0;
            end;
          end;
        end;

        // Un tramo abierto al agotar los eventos no deberia existir (toda tarea
        // que entra acaba saliendo), pero si los datos vienen incoherentes es
        // mejor emitirlo que perderlo en silencio.
        if EnSobrecarga and (Eventos.Count > 0) then
        begin
          Sob := Default(TWbsSobrecarga);
          Sob.OperatorId := Par.Key;
          Sob.Nombre := Lst[0].Nombre;
          Sob.Desde := Desde;
          Sob.Hasta := Eventos[Eventos.Count - 1].Instante;
          Sob.PorcentajePico := Pico;
          SetLength(Sob.NodeIds, NodeIdsTramo.Count);
          for J := 0 to NodeIdsTramo.Count - 1 do
            Sob.NodeIds[J] := NodeIdsTramo[J];
          Res.Add(Sob);
        end;
      finally
        NodeIdsTramo.Free;
        Activas.Free;
        Eventos.Free;
      end;
    end;

    // Orden de presentacion: primero el pico mas alto (lo mas grave arriba).
    Res.Sort(TComparer<TWbsSobrecarga>.Construct(
      function(const A, B: TWbsSobrecarga): Integer
      begin
        Result := CompareValue(B.PorcentajePico, A.PorcentajePico);
        if Result = 0 then Result := CompareDateTime(A.Desde, B.Desde);
      end));

    Result := Res.ToArray;
  finally
    Res.Free;
    PorOperario.Free;
  end;
end;

function NodosSobrecargados(
  const ASobrecargas: TWbsSobrecargaArray): TDictionary<Integer, Boolean>;
var
  I, J: Integer;
begin
  Result := TDictionary<Integer, Boolean>.Create;
  for I := 0 to High(ASobrecargas) do
    for J := 0 to High(ASobrecargas[I].NodeIds) do
      Result.AddOrSetValue(ASobrecargas[I].NodeIds[J], True);
end;

end.
