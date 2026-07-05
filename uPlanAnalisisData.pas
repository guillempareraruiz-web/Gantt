unit uPlanAnalisisData;

// ============================================================================
//  Calculo de datos para la pantalla "Analisis del plan" (uPlanAnalisis).
//
//  Reutiliza la logica YA PROBADA de los heatmaps (uHeatmapCargaCentro y
//  uHeatmapEntregasVsCarga):
//    - Periodos del horizonte (dia/semana/mes).
//    - Carga por centro y periodo: prorrateo temporal de DuracionMin sobre el
//      solapamiento de cada nodo con cada periodo.
//    - Capacidad por centro y periodo: TCentreCalendar.WorkingMinutesBetween.
//    - On-Time Delivery: FechaFin del nodo vs FechaEntrega comprometida.
//
//  Este modulo NO pinta nada: devuelve estructuras limpias que la pantalla
//  vuelca a los graficos TeeChart. Asi el calculo es testeable y comun a los
//  4 graficos (3 de ellos salen de la misma agregacion carga/centro/periodo).
// ============================================================================

interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  System.Generics.Collections,
  uGanttTypes;

type
  TGranularidadPlan = (gpDias, gpSemanas, gpMeses);

  TPeriodoPlan = record
    Inicio: TDateTime;
    Fin: TDateTime;
    Etiqueta: string;
  end;

  // Carga (horas) y capacidad (horas) de un centro, periodo a periodo.
  TCargaCentro = record
    CenterId: Integer;
    Nombre: string;
    HorasCarga: TArray<Double>;     // por periodo
    HorasCapacidad: TArray<Double>; // por periodo (-1 si no hay calendario)
    function TotalCarga: Double;
    function TotalCapacidad: Double;
    function OcupacionPct: Double;   // total carga / total capacidad * 100
  end;

  // Carga (horas) y capacidad (horas) de un operario, periodo a periodo.
  // Analogo a TCargaCentro pero la carga sale de FS_PL_OperatorAssignment
  // (horas asignadas al operario) y la capacidad del calendario del operario.
  TCargaOperario = record
    OperatorId: Integer;
    Nombre: string;
    HorasCarga: TArray<Double>;     // por periodo
    HorasCapacidad: TArray<Double>; // por periodo (-1 si no hay calendario)
    function TotalCarga: Double;
    function TotalCapacidad: Double;
    function OcupacionPct: Double;
  end;

  TOtdResultado = record
    Total: Integer;
    ATiempo: Integer;
    EnRiesgo: Integer;       // termina <= 1 dia antes del compromiso
    Retrasadas: Integer;     // FechaFin > FechaEntrega
    SinCompromiso: Integer;  // sin FechaEntrega
    RetrasoMedioDias: Double;
    RetrasoMaxDias: Double;
    // Histograma de desviacion vs compromiso (dias): 7 buckets
    //   [0]<=-3  [1]-2  [2]-1  [3]0  [4]+1  [5]+2  [6]>=+3
    // Negativo = termina antes (adelantada); positivo = tarde.
    Buckets: array[0..6] of Integer;
  end;

  // Par generico clave/valor de horas (para mix por articulo/operacion, etc.)
  TItemHoras = record
    Clave: string;
    Horas: Double;
    Conteo: Integer;
  end;

  // Una OF con su retraso (para el ranking "Top OF mas retrasadas").
  TOfRetraso = record
    Etiqueta: string;
    RetrasoDias: Double;
  end;

  // Makespan (ventana inicio->fin) de un proyecto.
  TMakespanProyecto = record
    Nombre: string;
    Inicio: TDateTime;
    Fin: TDateTime;
    HorasSpan: Double;
  end;

  // Reparto productivo vs setup por centro.
  TProductivoSetup = record
    Nombre: string;
    HorasProductivo: Double;
    HorasSetup: Double;
  end;

  // --- Estructuras para los graficos PRO ---

  // Barra Gantt-resumen de un proyecto (ventana inicio->fin en el horizonte).
  TGanttResumen = record
    Nombre: string;
    Inicio: TDateTime;
    Fin: TDateTime;
  end;

  // Una cadena de dependencias (camino) con su duracion total y nº de eslabones.
  TCadenaDep = record
    Etiqueta: string;      // "OF 2501 -> ... (N ops)"
    HorasTotal: Double;    // suma de duraciones de la cadena
    NumOps: Integer;       // nº de operaciones encadenadas
  end;

  // Holgura de una OF: dias entre su fin planificado y su fecha de entrega.
  //   Margen > 0 = termina antes (colchon); < 0 = termina despues (retraso).
  TMargenOF = record
    Etiqueta: string;
    MargenDias: Double;
  end;

  // Punto (prioridad, retraso) para el scatter de urgencias.
  TPrioridadRetraso = record
    Etiqueta: string;
    Prioridad: Integer;
    RetrasoDias: Double;
  end;

  // Avance global del plan por unidades y por estado de las operaciones.
  TProgresoPlan = record
    UnidadesFabricadas: Double;
    UnidadesAFabricar: Double;
    // Reparto de nodos por Estado (0..N). Usamos los 4 primeros como
    // Pendiente / En curso / Hecho / Otro para el embudo WIP.
    NodosPorEstado: array[0..4] of Integer;
  end;

  // Cobertura de personal por centro: operarios necesarios vs asignados.
  TCoberturaCentro = record
    Nombre: string;
    Necesarios: Integer;
    Asignados: Integer;
  end;

  // Resultado completo del analisis.
  TPlanAnalisis = record
    Periodos: TArray<TPeriodoPlan>;
    Centros: TArray<TCargaCentro>;
    Operarios: TArray<TCargaOperario>;   // RECURSOS: carga/capacidad por operario
    Otd: TOtdResultado;
    CargaTotalPorPeriodo: TArray<Double>;
    CapacidadTotalPorPeriodo: TArray<Double>;
    // --- Datos para los graficos pendientes ---
    PorArticulo: TArray<TItemHoras>;     // MIX: carga (h) por articulo
    PorOperacion: TArray<TItemHoras>;    // MIX: carga (h) por operacion
    OpsPorCentro: TArray<TItemHoras>;    // MIX: nº operaciones por centro
    TopRetrasos: TArray<TOfRetraso>;     // ENTREGAS: top OF mas retrasadas
    Makespans: TArray<TMakespanProyecto>;// TIEMPOS: makespan por proyecto
    Duraciones: array[0..7] of Integer;  // TIEMPOS: histograma duracion op (min)
    ProductivoSetup: TArray<TProductivoSetup>; // EFICIENCIA: productivo vs setup
    UtilMediaGlobal: Double;             // EFICIENCIA: utilizacion media global %
    // --- PRO ---
    GanttResumen: TArray<TGanttResumen>;      // VISION: mini-Gantt por proyecto
    Cadenas: TArray<TCadenaDep>;              // DEPENDENCIAS: cadenas mas largas
    MargenEntrega: TArray<TMargenOF>;         // ENTREGAS: holgura hasta entrega
    PrioridadRetraso: TArray<TPrioridadRetraso>; // ENTREGAS: prioridad vs retraso
    CargaAcumulada: TArray<Double>;           // CAPACIDAD: carga acumulada (CRP)
    CapacidadAcumulada: TArray<Double>;       // CAPACIDAD: capacidad acumulada (CRP)
    Progreso: TProgresoPlan;                  // AVANCE: unidades y estados
    PorCliente: TArray<TItemHoras>;           // MIX: carga por cliente
    Cobertura: TArray<TCoberturaCentro>;      // RECURSOS: personal nec. vs asig.
  end;

// Construye los periodos del horizonte.
function BuildPeriodosPlan(ADesde: TDateTime; ANum: Integer;
  AGran: TGranularidadPlan): TArray<TPeriodoPlan>;

// Calcula todo el analisis del plan activo (DMPlanner.CurrentProjectId).
function CalcularPlanAnalisis(const APeriodos: TArray<TPeriodoPlan>): TPlanAnalisis;

implementation

uses
  System.Math, System.Generics.Defaults,
  Data.Win.ADODB,
  uDMPlanner, uCentreCalendar, uDemoMode;

{ TCargaCentro }

function TCargaCentro.TotalCarga: Double;
var V: Double;
begin
  Result := 0;
  for V in HorasCarga do Result := Result + V;
end;

function TCargaCentro.TotalCapacidad: Double;
var V: Double;
begin
  Result := 0;
  for V in HorasCapacidad do
    if V > 0 then Result := Result + V;
end;

function TCargaCentro.OcupacionPct: Double;
var Cap: Double;
begin
  Cap := TotalCapacidad;
  if Cap <= 0 then Exit(0);
  Result := TotalCarga / Cap * 100.0;
end;

{ TCargaOperario }

function TCargaOperario.TotalCarga: Double;
var V: Double;
begin
  Result := 0;
  for V in HorasCarga do Result := Result + V;
end;

function TCargaOperario.TotalCapacidad: Double;
var V: Double;
begin
  Result := 0;
  for V in HorasCapacidad do
    if V > 0 then Result := Result + V;
end;

function TCargaOperario.OcupacionPct: Double;
var Cap: Double;
begin
  Cap := TotalCapacidad;
  if Cap <= 0 then Exit(0);
  Result := TotalCarga / Cap * 100.0;
end;

{ Periodos }

function BuildPeriodosPlan(ADesde: TDateTime; ANum: Integer;
  AGran: TGranularidadPlan): TArray<TPeriodoPlan>;
var
  I: Integer;
  Cursor: TDateTime;
  P: TPeriodoPlan;
  YYYY, MM, DD: Word;
begin
  if ANum < 1 then ANum := 1;
  SetLength(Result, ANum);
  Cursor := Trunc(ADesde);

  if AGran = gpSemanas then
    Cursor := Cursor - ((DayOfTheWeek(Cursor) + 6) mod 7); // snap a lunes
  if AGran = gpMeses then
  begin
    DecodeDate(Cursor, YYYY, MM, DD);
    Cursor := EncodeDate(YYYY, MM, 1);
  end;

  for I := 0 to ANum - 1 do
  begin
    P.Inicio := Cursor;
    case AGran of
      gpDias:
        begin P.Fin := IncDay(Cursor, 1);   P.Etiqueta := FormatDateTime('dd/mm', Cursor); end;
      gpSemanas:
        begin P.Fin := IncDay(Cursor, 7);   P.Etiqueta := 'S' + IntToStr(WeekOf(Cursor)); end;
      gpMeses:
        begin P.Fin := IncMonth(Cursor, 1); P.Etiqueta := FormatDateTime('mmm yy', Cursor); end;
    end;
    Result[I] := P;
    Cursor := P.Fin;
  end;
end;

{ Carga por centro (prorrateo) + capacidad }

procedure CalcularCarga(const APeriodos: TArray<TPeriodoPlan>;
  var ACentros: TArray<TCargaCentro>);
var
  Todos: TArray<TCentreTreball>;
  IdxById: TDictionary<Integer, Integer>;
  Q: TADOQuery;
  I, J, CIdx, ProjectId, CenterId: Integer;
  HIni, HFin, NodeIni, NodeFin: TDateTime;
  DurMin, NodeDur, OvStart, OvEnd, OverlapMin, MinNode: Double;
  Cal: TCentreCalendar;
  CapMin: Integer;
begin
  if DMPlanner.CentresRepo <> nil then
    Todos := DMPlanner.CentresRepo.GetAll
  else
    SetLength(Todos, 0);

  SetLength(ACentros, Length(Todos));
  IdxById := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to High(Todos) do
    begin
      ACentros[I].CenterId := Todos[I].Id;
      if Trim(Todos[I].Titulo) <> '' then ACentros[I].Nombre := Todos[I].Titulo
      else ACentros[I].Nombre := Todos[I].CodiCentre;
      SetLength(ACentros[I].HorasCarga, Length(APeriodos));
      SetLength(ACentros[I].HorasCapacidad, Length(APeriodos));
      IdxById.AddOrSetValue(Todos[I].Id, I);
    end;
    if (Length(ACentros) = 0) or (Length(APeriodos) = 0) then Exit;

    HIni := APeriodos[0].Inicio;
    HFin := APeriodos[High(APeriodos)].Fin;
    ProjectId := DMPlanner.CurrentProjectId;

    if ProjectId > 0 then
    begin
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := DMPlanner.ADOConnection;
        Q.SQL.Text :=
          'SELECT CenterId, FechaInicio, FechaFin, DuracionMin ' +
          'FROM FS_PL_Node ' +
          'WHERE CodigoEmpresa = :CE AND ProjectId = :PID ' +
          '  AND CenterId IS NOT NULL ' +
          '  AND FechaInicio IS NOT NULL AND FechaFin IS NOT NULL ' +
          '  AND FechaFin >= :HInicio AND FechaInicio < :HFin';
        Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
        Q.Parameters.ParamByName('PID').Value := ProjectId;
        Q.Parameters.ParamByName('HInicio').Value := HIni;
        Q.Parameters.ParamByName('HFin').Value := HFin;
        Q.Open;
        while not Q.Eof do
        begin
          CenterId := Q.FieldByName('CenterId').AsInteger;
          if IdxById.TryGetValue(CenterId, CIdx) then
          begin
            NodeIni := Q.FieldByName('FechaInicio').AsDateTime;
            NodeFin := Q.FieldByName('FechaFin').AsDateTime;
            DurMin  := Q.FieldByName('DuracionMin').AsFloat;
            if DurMin <= 0 then DurMin := MinutesBetween(NodeFin, NodeIni);
            NodeDur := MinutesBetween(NodeFin, NodeIni);
            if NodeDur <= 0 then begin Q.Next; Continue; end;

            for J := 0 to High(APeriodos) do
            begin
              OvStart := APeriodos[J].Inicio;
              if NodeIni > OvStart then OvStart := NodeIni;
              OvEnd := APeriodos[J].Fin;
              if NodeFin < OvEnd then OvEnd := NodeFin;
              if OvEnd <= OvStart then Continue;
              OverlapMin := MinutesBetween(OvEnd, OvStart);
              MinNode := DurMin * (OverlapMin / NodeDur);
              ACentros[CIdx].HorasCarga[J] := ACentros[CIdx].HorasCarga[J] + (MinNode / 60.0);
            end;
          end;
          Q.Next;
        end;
      finally
        Q.Free;
      end;
    end;

    // Capacidad por centro/periodo via calendario.
    for I := 0 to High(ACentros) do
    begin
      Cal := nil;
      if DMPlanner.CentresRepo <> nil then
        Cal := DMPlanner.CentresRepo.GetCalendarFor(ACentros[I].CenterId);
      for J := 0 to High(APeriodos) do
      begin
        if Cal = nil then
        begin
          ACentros[I].HorasCapacidad[J] := -1;
          Continue;
        end;
        CapMin := Cal.WorkingMinutesBetween(APeriodos[J].Inicio, APeriodos[J].Fin);
        if CapMin <= 0 then ACentros[I].HorasCapacidad[J] := -1
        else ACentros[I].HorasCapacidad[J] := CapMin / 60.0;
      end;
    end;
  finally
    IdxById.Free;
  end;
end;

{ Carga por operario (prorrateo) + capacidad }
// Misma logica que CalcularCarga (centros) pero la carga sale de las horas
// asignadas al operario en FS_PL_OperatorAssignment (prorrateadas por el
// solapamiento temporal del nodo con cada periodo) y la capacidad del
// calendario del operario (FS_PL_Operator.CalendarId). Mismo patron que
// uHeatmapCargaOperario.

procedure CalcularCargaOperario(const APeriodos: TArray<TPeriodoPlan>;
  var AOperarios: TArray<TCargaOperario>);
var
  Q: TADOQuery;
  IdxById: TDictionary<Integer, Integer>;
  CalIds: TDictionary<Integer, Integer>;   // OperatorId -> CalendarId
  List: TList<TCargaOperario>;
  Op: TCargaOperario;
  I, J, OIdx, ProjectId, OperatorId, CalId: Integer;
  HIni, HFin, NodeIni, NodeFin: TDateTime;
  Horas, NodeDur, OvStart, OvEnd, OverlapMin, HorasParte: Double;
  Cal: TCentreCalendar;
  CapMin: Integer;
begin
  SetLength(AOperarios, 0);
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) or
     (not DMPlanner.ADOConnection.Connected) then Exit;

  // 1. Operarios activos (id, nombre, calendario).
  List := TList<TCargaOperario>.Create;
  IdxById := TDictionary<Integer, Integer>.Create;
  CalIds := TDictionary<Integer, Integer>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT OperatorId, Nombre, ISNULL(CalendarId, 0) AS CalendarId ' +
        'FROM FS_PL_Operator ' +
        'WHERE CodigoEmpresa = :CE AND ISNULL(Activo, 1) = 1 ' +
        'ORDER BY Nombre';
      Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
      try
        Q.Open;
        while not Q.Eof do
        begin
          Op := Default(TCargaOperario);
          Op.OperatorId := Q.FieldByName('OperatorId').AsInteger;
          Op.Nombre := Q.FieldByName('Nombre').AsString;
          if Trim(Op.Nombre) = '' then
            Op.Nombre := 'Operario #' + IntToStr(Op.OperatorId);
          SetLength(Op.HorasCarga, Length(APeriodos));
          SetLength(Op.HorasCapacidad, Length(APeriodos));
          IdxById.AddOrSetValue(Op.OperatorId, List.Count);
          CalIds.AddOrSetValue(Op.OperatorId,
            Q.FieldByName('CalendarId').AsInteger);
          List.Add(Op);
          Q.Next;
        end;
      except
        // Si FS_PL_Operator no existe (instalacion sin V019), sin operarios.
      end;
    finally
      Q.Free;
    end;

    AOperarios := List.ToArray;
    if (Length(AOperarios) = 0) or (Length(APeriodos) = 0) then Exit;

    HIni := APeriodos[0].Inicio;
    HFin := APeriodos[High(APeriodos)].Fin;
    ProjectId := DMPlanner.CurrentProjectId;

    // 2. Prorrateo de las horas asignadas por periodo.
    if ProjectId > 0 then
    begin
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := DMPlanner.ADOConnection;
        Q.SQL.Text :=
          'SELECT oa.OperatorId, oa.Horas, n.FechaInicio, n.FechaFin ' +
          'FROM FS_PL_OperatorAssignment oa ' +
          'INNER JOIN FS_PL_Node n ON n.CodigoEmpresa = oa.CodigoEmpresa ' +
          '                       AND n.NodeId = oa.NodeId ' +
          'WHERE oa.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
          '  AND n.FechaInicio IS NOT NULL AND n.FechaFin IS NOT NULL ' +
          '  AND n.FechaFin >= :HInicio AND n.FechaInicio < :HFin';
        Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
        Q.Parameters.ParamByName('PID').Value := ProjectId;
        Q.Parameters.ParamByName('HInicio').Value := HIni;
        Q.Parameters.ParamByName('HFin').Value := HFin;
        try
          Q.Open;
          while not Q.Eof do
          begin
            OperatorId := Q.FieldByName('OperatorId').AsInteger;
            if IdxById.TryGetValue(OperatorId, OIdx) then
            begin
              NodeIni := Q.FieldByName('FechaInicio').AsDateTime;
              NodeFin := Q.FieldByName('FechaFin').AsDateTime;
              Horas   := Q.FieldByName('Horas').AsFloat;
              NodeDur := MinutesBetween(NodeFin, NodeIni);
              if (NodeDur > 0) and (Horas > 0) then
                for J := 0 to High(APeriodos) do
                begin
                  OvStart := APeriodos[J].Inicio;
                  if NodeIni > OvStart then OvStart := NodeIni;
                  OvEnd := APeriodos[J].Fin;
                  if NodeFin < OvEnd then OvEnd := NodeFin;
                  if OvEnd <= OvStart then Continue;
                  OverlapMin := MinutesBetween(OvEnd, OvStart);
                  HorasParte := Horas * (OverlapMin / NodeDur);
                  AOperarios[OIdx].HorasCarga[J] :=
                    AOperarios[OIdx].HorasCarga[J] + HorasParte;
                end;
            end;
            Q.Next;
          end;
        except
          // Si FS_PL_OperatorAssignment no existe, dejamos la carga a 0.
        end;
      finally
        Q.Free;
      end;
    end;

    // 3. Capacidad por operario/periodo via calendario.
    for I := 0 to High(AOperarios) do
    begin
      Cal := nil;
      CalId := 0;
      CalIds.TryGetValue(AOperarios[I].OperatorId, CalId);
      if (DMPlanner.CalendarsRepo <> nil) and (CalId > 0) then
        DMPlanner.CalendarsRepo.TryGetById(CalId, Cal);
      for J := 0 to High(APeriodos) do
      begin
        if Cal = nil then
        begin
          AOperarios[I].HorasCapacidad[J] := -1;
          Continue;
        end;
        CapMin := Cal.WorkingMinutesBetween(APeriodos[J].Inicio, APeriodos[J].Fin);
        if CapMin <= 0 then AOperarios[I].HorasCapacidad[J] := -1
        else AOperarios[I].HorasCapacidad[J] := CapMin / 60.0;
      end;
    end;
  finally
    IdxById.Free;
    CalIds.Free;
    List.Free;
  end;
end;

{ On-Time Delivery }

function CalcularOTD: TOtdResultado;
var
  Q: TADOQuery;
  ProjectId: Integer;
  FFin, FEnt: TDateTime;
  DiffDias, SumaRetraso: Double;
  N, DiasInt: Integer;
begin
  Result := Default(TOtdResultado);
  ProjectId := DMPlanner.CurrentProjectId;
  if ProjectId <= 0 then Exit;

  SumaRetraso := 0;
  N := 0;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT n.FechaFin, nd.FechaEntrega ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
      '  AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
      '  AND n.FechaFin IS NOT NULL';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := ProjectId;
    Q.Open;
    while not Q.Eof do
    begin
      Inc(Result.Total);
      if Q.FieldByName('FechaEntrega').IsNull then
      begin
        Inc(Result.SinCompromiso);
        Q.Next;
        Continue;
      end;
      FFin := Q.FieldByName('FechaFin').AsDateTime;
      FEnt := Q.FieldByName('FechaEntrega').AsDateTime;
      DiffDias := FFin - FEnt;   // >0 = termina despues del compromiso (tarde)

      if DiffDias > 0 then
      begin
        Inc(Result.Retrasadas);
        SumaRetraso := SumaRetraso + DiffDias;
        Inc(N);
        if DiffDias > Result.RetrasoMaxDias then Result.RetrasoMaxDias := DiffDias;
      end
      else if DiffDias > -1.0 then
        // termina dentro del ultimo dia antes del compromiso: en riesgo
        Inc(Result.EnRiesgo)
      else
        Inc(Result.ATiempo);

      // Histograma de desviacion (dias redondeados a entero, clamp [-3..+3]).
      DiasInt := Round(DiffDias);
      if DiasInt < -3 then DiasInt := -3;
      if DiasInt > 3 then DiasInt := 3;
      Inc(Result.Buckets[DiasInt + 3]);

      Q.Next;
    end;
  finally
    Q.Free;
  end;

  if N > 0 then Result.RetrasoMedioDias := SumaRetraso / N;
end;

{ MIX: carga por articulo, por operacion, y nº operaciones por centro }

procedure CalcularMix(out APorArticulo, APorOperacion, AOpsPorCentro: TArray<TItemHoras>;
  const ACentros: TArray<TCargaCentro>);
var
  Q: TADOQuery;
  PID: Integer;
  MapArt, MapOp: TDictionary<string, TItemHoras>;
  IdToNombre: TDictionary<Integer, string>;
  MapCentro: TDictionary<string, TItemHoras>;
  Clave, Nombre: string;
  Horas: Double;
  CId, I: Integer;
  It: TItemHoras;

  procedure Acum(M: TDictionary<string, TItemHoras>; const K: string; H: Double);
  var X: TItemHoras;
  begin
    if Trim(K) = '' then Exit;
    if not M.TryGetValue(K, X) then
    begin X := Default(TItemHoras); X.Clave := K; end;
    X.Horas := X.Horas + H;
    Inc(X.Conteo);
    M.AddOrSetValue(K, X);
  end;

  function Volcar(M: TDictionary<string, TItemHoras>): TArray<TItemHoras>;
  var V: TItemHoras; L: TList<TItemHoras>;
  begin
    L := TList<TItemHoras>.Create;
    try
      for V in M.Values do L.Add(V);
      L.Sort(TComparer<TItemHoras>.Construct(
        function(const A, B: TItemHoras): Integer
        begin Result := CompareValue(B.Horas, A.Horas); end));
      Result := L.ToArray;
    finally
      L.Free;
    end;
  end;

begin
  SetLength(APorArticulo, 0); SetLength(APorOperacion, 0); SetLength(AOpsPorCentro, 0);
  PID := DMPlanner.CurrentProjectId;
  if PID <= 0 then Exit;

  IdToNombre := TDictionary<Integer, string>.Create;
  for I := 0 to High(ACentros) do
    IdToNombre.AddOrSetValue(ACentros[I].CenterId, ACentros[I].Nombre);

  MapArt := TDictionary<string, TItemHoras>.Create;
  MapOp := TDictionary<string, TItemHoras>.Create;
  MapCentro := TDictionary<string, TItemHoras>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT n.CenterId, nd.CodigoArticulo, nd.DescripcionArticulo, ' +
      '       nd.Operacion, nd.DuracionMin ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
      '  AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := PID;
    Q.Open;
    while not Q.Eof do
    begin
      Horas := Q.FieldByName('DuracionMin').AsFloat / 60.0;

      Clave := Trim(Q.FieldByName('CodigoArticulo').AsString);
      if Clave = '' then Clave := '(sin art'#237'culo)';
      Acum(MapArt, Clave, Horas);

      Clave := Trim(Q.FieldByName('Operacion').AsString);
      if Clave = '' then Clave := '(sin operaci'#243'n)';
      Acum(MapOp, Clave, Horas);

      CId := Q.FieldByName('CenterId').AsInteger;
      if IdToNombre.TryGetValue(CId, Nombre) then Clave := Nombre
      else Clave := '(centro ' + IntToStr(CId) + ')';
      Acum(MapCentro, Clave, Horas);  // Horas no se usa; Conteo = nº operaciones

      Q.Next;
    end;
  finally
    Q.Free;
  end;

  APorArticulo := Volcar(MapArt);
  APorOperacion := Volcar(MapOp);
  // Para ops por centro, ordenar por Conteo (nº operaciones), no por horas.
  AOpsPorCentro := Volcar(MapCentro);

  MapArt.Free; MapOp.Free; MapCentro.Free; IdToNombre.Free;
end;

{ ENTREGAS: top OF mas retrasadas }

function CalcularTopRetrasos(AMax: Integer): TArray<TOfRetraso>;
var
  Q: TADOQuery;
  PID: Integer;
  L: TList<TOfRetraso>;
  R: TOfRetraso;
  FFin, FEnt: TDateTime;
begin
  SetLength(Result, 0);
  PID := DMPlanner.CurrentProjectId;
  if PID <= 0 then Exit;

  L := TList<TOfRetraso>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT n.FechaFin, nd.FechaEntrega, nd.NumeroOF, nd.SerieOF, ' +
      '       nd.CodigoArticulo ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
      '  AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
      '  AND n.FechaFin IS NOT NULL AND nd.FechaEntrega IS NOT NULL';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := PID;
    Q.Open;
    while not Q.Eof do
    begin
      FFin := Q.FieldByName('FechaFin').AsDateTime;
      FEnt := Q.FieldByName('FechaEntrega').AsDateTime;
      if FFin > FEnt then
      begin
        R := Default(TOfRetraso);
        R.RetrasoDias := FFin - FEnt;
        R.Etiqueta := Trim(Q.FieldByName('SerieOF').AsString) + ' ' +
          IntToStr(Q.FieldByName('NumeroOF').AsInteger);
        if Trim(R.Etiqueta) = '' then
          R.Etiqueta := Trim(Q.FieldByName('CodigoArticulo').AsString);
        L.Add(R);
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  L.Sort(TComparer<TOfRetraso>.Construct(
    function(const A, B: TOfRetraso): Integer
    begin Result := CompareValue(B.RetrasoDias, A.RetrasoDias); end));
  while L.Count > AMax do L.Delete(L.Count - 1);
  Result := L.ToArray;
  L.Free;
end;

{ TIEMPOS: makespan por proyecto + histograma de duraciones }

procedure CalcularTiempos(out AMakespans: TArray<TMakespanProyecto>;
  var ADuraciones: array of Integer);
var
  Q: TADOQuery;
  PID, Bucket: Integer;
  Map: TDictionary<string, TMakespanProyecto>;
  Nom: string;
  Ini, Fin: TDateTime;
  Dur: Double;
  MS, MS2: TMakespanProyecto;
  L: TList<TMakespanProyecto>;
begin
  SetLength(AMakespans, 0);
  PID := DMPlanner.CurrentProjectId;
  if PID <= 0 then Exit;

  Map := TDictionary<string, TMakespanProyecto>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT p.Nombre, n.FechaInicio, n.FechaFin, n.DuracionMin ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_Project p ON p.ProjectId = n.ProjectId ' +
      'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
      '  AND n.FechaInicio IS NOT NULL AND n.FechaFin IS NOT NULL';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := PID;
    Q.Open;
    while not Q.Eof do
    begin
      Nom := Trim(Q.FieldByName('Nombre').AsString);
      if Nom = '' then Nom := 'Proyecto actual';
      Ini := Q.FieldByName('FechaInicio').AsDateTime;
      Fin := Q.FieldByName('FechaFin').AsDateTime;
      Dur := Q.FieldByName('DuracionMin').AsFloat;

      if not Map.TryGetValue(Nom, MS) then
      begin
        MS := Default(TMakespanProyecto); MS.Nombre := Nom;
        MS.Inicio := Ini; MS.Fin := Fin;
      end;
      if Ini < MS.Inicio then MS.Inicio := Ini;
      if Fin > MS.Fin then MS.Fin := Fin;
      Map.AddOrSetValue(Nom, MS);

      // Histograma de duraciones (minutos): buckets 0-7
      //  <15, 15-30, 30-60, 60-120, 120-240, 240-480, 480-960, >960
      if Dur < 15 then Bucket := 0
      else if Dur < 30 then Bucket := 1
      else if Dur < 60 then Bucket := 2
      else if Dur < 120 then Bucket := 3
      else if Dur < 240 then Bucket := 4
      else if Dur < 480 then Bucket := 5
      else if Dur < 960 then Bucket := 6
      else Bucket := 7;
      Inc(ADuraciones[Bucket]);

      Q.Next;
    end;
  finally
    Q.Free;
  end;

  L := TList<TMakespanProyecto>.Create;
  try
    for MS in Map.Values do
    begin
      MS2 := MS;  // no se puede asignar a la variable del for-in
      MS2.HorasSpan := (MS2.Fin - MS2.Inicio) * 24.0;
      L.Add(MS2);
    end;
    AMakespans := L.ToArray;
  finally
    L.Free;
    Map.Free;
  end;
end;

{ EFICIENCIA: productivo vs setup por centro }

procedure CalcularEficiencia(out AProductivoSetup: TArray<TProductivoSetup>;
  const ACentros: TArray<TCargaCentro>);
var
  Q: TADOQuery;
  PID, CId, I: Integer;
  Map: TDictionary<Integer, TProductivoSetup>;
  IdToNombre: TDictionary<Integer, string>;
  Nombre: string;
  Prod, Setup: Double;
  PS: TProductivoSetup;
  L: TList<TProductivoSetup>;
begin
  SetLength(AProductivoSetup, 0);
  PID := DMPlanner.CurrentProjectId;
  if PID <= 0 then Exit;

  IdToNombre := TDictionary<Integer, string>.Create;
  for I := 0 to High(ACentros) do
    IdToNombre.AddOrSetValue(ACentros[I].CenterId, ACentros[I].Nombre);

  Map := TDictionary<Integer, TProductivoSetup>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    // Productivo = DuracionMinOriginal (sin setup). Setup = diferencia entre la
    // duracion efectiva (DuracionMin, que incluye reparto de setup del lote) y
    // la original, acotado a >=0.
    Q.SQL.Text :=
      'SELECT n.CenterId, ' +
      '  ISNULL(nd.DuracionMinOriginal, nd.DuracionMin) AS Prod, ' +
      '  CASE WHEN nd.DuracionMin > ISNULL(nd.DuracionMinOriginal, nd.DuracionMin) ' +
      '    THEN nd.DuracionMin - ISNULL(nd.DuracionMinOriginal, nd.DuracionMin) ' +
      '    ELSE 0 END AS Setup ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
      '  AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID AND n.CenterId IS NOT NULL';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := PID;
    Q.Open;
    while not Q.Eof do
    begin
      CId := Q.FieldByName('CenterId').AsInteger;
      Prod := Q.FieldByName('Prod').AsFloat / 60.0;
      Setup := Q.FieldByName('Setup').AsFloat / 60.0;
      if not Map.TryGetValue(CId, PS) then
      begin
        PS := Default(TProductivoSetup);
        if IdToNombre.TryGetValue(CId, Nombre) then PS.Nombre := Nombre
        else PS.Nombre := '(centro ' + IntToStr(CId) + ')';
      end;
      PS.HorasProductivo := PS.HorasProductivo + Prod;
      PS.HorasSetup := PS.HorasSetup + Setup;
      Map.AddOrSetValue(CId, PS);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  L := TList<TProductivoSetup>.Create;
  try
    for PS in Map.Values do
      if PS.HorasProductivo + PS.HorasSetup > 0 then L.Add(PS);
    AProductivoSetup := L.ToArray;
  finally
    L.Free;
    Map.Free;
    IdToNombre.Free;
  end;
end;

{ PRO: Gantt-resumen por proyecto (ventana inicio->fin) }

procedure CalcularGanttResumen(out AGantt: TArray<TGanttResumen>);
var
  Q: TADOQuery;
  PID: Integer;
  Map: TDictionary<string, TGanttResumen>;
  Nom: string;
  Ini, Fin: TDateTime;
  GR, GR2: TGanttResumen;
  L: TList<TGanttResumen>;
begin
  SetLength(AGantt, 0);
  PID := DMPlanner.CurrentProjectId;
  if PID <= 0 then Exit;

  Map := TDictionary<string, TGanttResumen>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT p.Nombre, n.FechaInicio, n.FechaFin ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_Project p ON p.ProjectId = n.ProjectId ' +
      'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
      '  AND n.FechaInicio IS NOT NULL AND n.FechaFin IS NOT NULL';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := PID;
    Q.Open;
    while not Q.Eof do
    begin
      Nom := Trim(Q.FieldByName('Nombre').AsString);
      if Nom = '' then Nom := 'Proyecto actual';
      Ini := Q.FieldByName('FechaInicio').AsDateTime;
      Fin := Q.FieldByName('FechaFin').AsDateTime;
      if not Map.TryGetValue(Nom, GR) then
      begin
        GR := Default(TGanttResumen); GR.Nombre := Nom;
        GR.Inicio := Ini; GR.Fin := Fin;
      end;
      if Ini < GR.Inicio then GR.Inicio := Ini;
      if Fin > GR.Fin then GR.Fin := Fin;
      Map.AddOrSetValue(Nom, GR);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  L := TList<TGanttResumen>.Create;
  try
    for GR in Map.Values do begin GR2 := GR; L.Add(GR2); end;
    // Ordenar por inicio (arriba los que empiezan antes).
    L.Sort(TComparer<TGanttResumen>.Construct(
      function(const A, B: TGanttResumen): Integer
      begin Result := CompareDateTime(A.Inicio, B.Inicio); end));
    AGantt := L.ToArray;
  finally
    L.Free;
    Map.Free;
  end;
end;

{ PRO: cadenas de dependencias mas largas (aproximacion al camino critico).
  Recorre FS_PL_Dependency como un grafo y, desde cada nodo raiz (sin
  predecesores), calcula la cadena de mayor duracion acumulada. Devuelve las
  top-N cadenas por horas. }

procedure CalcularCadenas(out ACadenas: TArray<TCadenaDep>);
var
  Q: TADOQuery;
  PID: Integer;
  Dur: TDictionary<Integer, Double>;        // NodeId -> DuracionMin
  Etq: TDictionary<Integer, string>;        // NodeId -> etiqueta corta
  Succ: TDictionary<Integer, TList<Integer>>; // NodeId -> sucesores
  TienePred: TDictionary<Integer, Boolean>;
  L: TList<TCadenaDep>;
  Nid, F, T: Integer;
  Lista: TList<Integer>;

  // DFS memoizado: mejor cadena (horas, nº ops, etiqueta ultimo) desde Nid.
  function Mejor(Nid: Integer; out ANum: Integer; out AFin: string): Double;
  var
    S, Num2: Integer;
    Fin2, EtqNid: string;
    H, Best, DurNid: Double;
    Sucesores: TList<Integer>;
  begin
    DurNid := 0; Dur.TryGetValue(Nid, DurNid);
    EtqNid := ''; Etq.TryGetValue(Nid, EtqNid);
    Best := 0; ANum := 0; AFin := EtqNid;
    if Succ.TryGetValue(Nid, Sucesores) then
      for S in Sucesores do
      begin
        H := Mejor(S, Num2, Fin2);
        if H > Best then begin Best := H; ANum := Num2; AFin := Fin2; end;
      end;
    Inc(ANum);
    Result := DurNid / 60.0 + Best;
  end;

var
  C: TCadenaDep;
  Num: Integer;
  FinEtq, IniEtq: string;
  Horas: Double;
begin
  SetLength(ACadenas, 0);
  PID := DMPlanner.CurrentProjectId;
  if PID <= 0 then Exit;

  Dur := TDictionary<Integer, Double>.Create;
  Etq := TDictionary<Integer, string>.Create;
  Succ := TDictionary<Integer, TList<Integer>>.Create;
  TienePred := TDictionary<Integer, Boolean>.Create;
  L := TList<TCadenaDep>.Create;
  try
    // 1. Duraciones + etiqueta de cada nodo del plan.
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT n.NodeId, n.DuracionMin, nd.Operacion, nd.NumeroOF ' +
        'FROM FS_PL_Node n ' +
        'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
        '  AND nd.NodeId = n.NodeId ' +
        'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID';
      Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
      Q.Parameters.ParamByName('PID').Value := PID;
      Q.Open;
      while not Q.Eof do
      begin
        Nid := Q.FieldByName('NodeId').AsInteger;
        Dur.AddOrSetValue(Nid, Q.FieldByName('DuracionMin').AsFloat);
        IniEtq := Trim(Q.FieldByName('Operacion').AsString);
        if IniEtq = '' then IniEtq := 'Op';
        if not Q.FieldByName('NumeroOF').IsNull then
          IniEtq := 'OF' + IntToStr(Q.FieldByName('NumeroOF').AsInteger) + ' ' + IniEtq;
        Etq.AddOrSetValue(Nid, IniEtq);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    if Dur.Count = 0 then Exit;

    // 2. Aristas de dependencia (From -> To).
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT FromNodeId, ToNodeId FROM FS_PL_Dependency ' +
        'WHERE CodigoEmpresa = :CE AND ProjectId = :PID';
      Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
      Q.Parameters.ParamByName('PID').Value := PID;
      try
        Q.Open;
        while not Q.Eof do
        begin
          F := Q.FieldByName('FromNodeId').AsInteger;
          T := Q.FieldByName('ToNodeId').AsInteger;
          if not Succ.TryGetValue(F, Lista) then
          begin Lista := TList<Integer>.Create; Succ.Add(F, Lista); end;
          Lista.Add(T);
          TienePred.AddOrSetValue(T, True);
          Q.Next;
        end;
      except
        // Sin dependencias (tabla vacia o inexistente): no hay cadenas.
      end;
    finally
      Q.Free;
    end;

    // 3. Desde cada raiz (sin predecesor), la mejor cadena.
    for Nid in Dur.Keys do
      if not TienePred.ContainsKey(Nid) then
      begin
        Horas := Mejor(Nid, Num, FinEtq);
        if (Num >= 2) and (Horas > 0) then  // solo cadenas reales (>=2 ops)
        begin
          C := Default(TCadenaDep);
          IniEtq := ''; Etq.TryGetValue(Nid, IniEtq);
          C.Etiqueta := IniEtq + ' -> ' + FinEtq;
          C.HorasTotal := Horas;
          C.NumOps := Num;
          L.Add(C);
        end;
      end;

    L.Sort(TComparer<TCadenaDep>.Construct(
      function(const A, B: TCadenaDep): Integer
      begin Result := CompareValue(B.HorasTotal, A.HorasTotal); end));
    while L.Count > 12 do L.Delete(L.Count - 1);
    ACadenas := L.ToArray;
  finally
    Dur.Free; Etq.Free; TienePred.Free; L.Free;
    for Lista in Succ.Values do Lista.Free;
    Succ.Free;
  end;
end;

{ PRO: margen (holgura) hasta la fecha de entrega, y prioridad vs retraso }

procedure CalcularMargenYPrioridad(out AMargen: TArray<TMargenOF>;
  out APrioRet: TArray<TPrioridadRetraso>);
var
  Q: TADOQuery;
  PID: Integer;
  LM: TList<TMargenOF>;
  LP: TList<TPrioridadRetraso>;
  M: TMargenOF;
  P: TPrioridadRetraso;
  FFin, FEnt: TDateTime;
  Etq: string;
begin
  SetLength(AMargen, 0); SetLength(APrioRet, 0);
  PID := DMPlanner.CurrentProjectId;
  if PID <= 0 then Exit;

  LM := TList<TMargenOF>.Create;
  LP := TList<TPrioridadRetraso>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT n.FechaFin, nd.FechaEntrega, nd.NumeroOF, nd.SerieOF, ' +
      '       nd.CodigoArticulo, ISNULL(nd.Prioridad, 0) AS Prioridad ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
      '  AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
      '  AND n.FechaFin IS NOT NULL AND nd.FechaEntrega IS NOT NULL';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := PID;
    Q.Open;
    while not Q.Eof do
    begin
      FFin := Q.FieldByName('FechaFin').AsDateTime;
      FEnt := Q.FieldByName('FechaEntrega').AsDateTime;
      Etq := Trim(Q.FieldByName('SerieOF').AsString) + ' ' +
        IntToStr(Q.FieldByName('NumeroOF').AsInteger);
      if Trim(Etq) = '' then Etq := Trim(Q.FieldByName('CodigoArticulo').AsString);

      M := Default(TMargenOF);
      M.Etiqueta := Etq;
      M.MargenDias := FEnt - FFin;   // >0 = colchon; <0 = retraso
      LM.Add(M);

      P := Default(TPrioridadRetraso);
      P.Etiqueta := Etq;
      P.Prioridad := Q.FieldByName('Prioridad').AsInteger;
      P.RetrasoDias := FFin - FEnt;  // >0 = tarde
      LP.Add(P);

      Q.Next;
    end;
  finally
    Q.Free;
  end;

  // Margen: ordenar de menor (mas critico) a mayor, y quedarnos con los 15
  // mas ajustados (los que menos colchon tienen o mas retraso).
  LM.Sort(TComparer<TMargenOF>.Construct(
    function(const A, B: TMargenOF): Integer
    begin Result := CompareValue(A.MargenDias, B.MargenDias); end));
  while LM.Count > 15 do LM.Delete(LM.Count - 1);
  AMargen := LM.ToArray;
  LM.Free;

  APrioRet := LP.ToArray;
  LP.Free;
end;

{ PRO: avance del plan (unidades + estados) }

procedure CalcularProgreso(out AProg: TProgresoPlan);
var
  Q: TADOQuery;
  PID, Est: Integer;
begin
  AProg := Default(TProgresoPlan);
  PID := DMPlanner.CurrentProjectId;
  if PID <= 0 then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ISNULL(nd.UnidadesFabricadas, 0) AS UF, ' +
      '       ISNULL(nd.UnidadesAFabricar, 0) AS UA, ' +
      '       ISNULL(nd.Estado, 0) AS Estado ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
      '  AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := PID;
    Q.Open;
    while not Q.Eof do
    begin
      AProg.UnidadesFabricadas := AProg.UnidadesFabricadas + Q.FieldByName('UF').AsFloat;
      AProg.UnidadesAFabricar := AProg.UnidadesAFabricar + Q.FieldByName('UA').AsFloat;
      Est := Q.FieldByName('Estado').AsInteger;
      if (Est < 0) or (Est > 4) then Est := 4;
      Inc(AProg.NodosPorEstado[Est]);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

{ PRO: mix por cliente + cobertura de personal por centro }

procedure CalcularClienteYCobertura(out APorCliente: TArray<TItemHoras>;
  out ACobertura: TArray<TCoberturaCentro>; const ACentros: TArray<TCargaCentro>);
var
  Q: TADOQuery;
  PID, CId, I: Integer;
  MapCli: TDictionary<string, TItemHoras>;
  MapCob: TDictionary<Integer, TCoberturaCentro>;
  IdToNombre: TDictionary<Integer, string>;
  Cli, Nombre: string;
  Horas: Double;
  X: TItemHoras;
  Cob: TCoberturaCentro;
  L: TList<TItemHoras>;
  LC: TList<TCoberturaCentro>;
begin
  SetLength(APorCliente, 0); SetLength(ACobertura, 0);
  PID := DMPlanner.CurrentProjectId;
  if PID <= 0 then Exit;

  IdToNombre := TDictionary<Integer, string>.Create;
  for I := 0 to High(ACentros) do
    IdToNombre.AddOrSetValue(ACentros[I].CenterId, ACentros[I].Nombre);

  MapCli := TDictionary<string, TItemHoras>.Create;
  MapCob := TDictionary<Integer, TCoberturaCentro>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT n.CenterId, nd.CodigoCliente, nd.DuracionMin, ' +
      '       ISNULL(nd.OperariosNecesarios, 0) AS Nec, ' +
      '       ISNULL(nd.OperariosAsignados, 0) AS Asig ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
      '  AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := PID;
    Q.Open;
    while not Q.Eof do
    begin
      Horas := Q.FieldByName('DuracionMin').AsFloat / 60.0;
      Cli := Trim(Q.FieldByName('CodigoCliente').AsString);
      if Cli = '' then Cli := '(sin cliente)';
      if not MapCli.TryGetValue(Cli, X) then
      begin X := Default(TItemHoras); X.Clave := Cli; end;
      X.Horas := X.Horas + Horas; Inc(X.Conteo);
      MapCli.AddOrSetValue(Cli, X);

      CId := Q.FieldByName('CenterId').AsInteger;
      if not MapCob.TryGetValue(CId, Cob) then
      begin
        Cob := Default(TCoberturaCentro);
        if IdToNombre.TryGetValue(CId, Nombre) then Cob.Nombre := Nombre
        else Cob.Nombre := '(centro ' + IntToStr(CId) + ')';
      end;
      Cob.Necesarios := Cob.Necesarios + Q.FieldByName('Nec').AsInteger;
      Cob.Asignados := Cob.Asignados + Q.FieldByName('Asig').AsInteger;
      MapCob.AddOrSetValue(CId, Cob);

      Q.Next;
    end;
  finally
    Q.Free;
  end;

  L := TList<TItemHoras>.Create;
  try
    for X in MapCli.Values do L.Add(X);
    L.Sort(TComparer<TItemHoras>.Construct(
      function(const A, B: TItemHoras): Integer
      begin Result := CompareValue(B.Horas, A.Horas); end));
    while L.Count > 15 do L.Delete(L.Count - 1);
    APorCliente := L.ToArray;
  finally
    L.Free;
  end;

  LC := TList<TCoberturaCentro>.Create;
  try
    for Cob in MapCob.Values do
      if Cob.Necesarios + Cob.Asignados > 0 then LC.Add(Cob);
    ACobertura := LC.ToArray;
  finally
    LC.Free;
  end;

  MapCli.Free; MapCob.Free; IdToNombre.Free;
end;

{ ---------------------------------------------------------------------------
  MODO DEMO: genera un TPlanAnalisis ficticio, creible y DETERMINISTA (sin
  Random, para no parpadear entre refrescos) que rellena TODAS las estructuras
  que consumen los 20 pintores. No toca la base de datos; se activa cuando
  DemoMode.Active. Al desactivar el modo, todo vuelve a los datos reales.
  --------------------------------------------------------------------------- }

function CalcularPlanAnalisisDemo(const APeriodos: TArray<TPeriodoPlan>): TPlanAnalisis;
const
  CENTROS: array[0..9] of string = (
    'Torno CNC 1', 'Torno CNC 2', 'Fresadora 2', 'Centro Mecanizado',
    'Rectificadora', 'Soldadura', 'Corte L'#225'ser', 'Plegadora',
    'Pintura', 'Montaje');
  OPERARIOS: array[0..7] of string = (
    'Juan P'#233'rez', 'Marta Ruiz', 'Luis G'#243'mez', 'Ana Torres',
    'Pedro Sanz', 'Elena Vidal', 'Carlos Mora', 'Rosa Gil');
  ARTICULOS: array[0..11] of string = (
    'ART-1001 Eje motor', 'ART-1002 Brida', 'ART-1003 Tapa', 'ART-1004 Soporte',
    'ART-1005 Carcasa', 'ART-1006 Pi'#241#243'n', 'ART-1007 Biela', 'ART-1008 Rodillo',
    'ART-1009 Casquillo', 'ART-1010 Placa', 'ART-1011 Anillo', 'ART-1012 Buje');
  OPERACIONES: array[0..7] of string = (
    'Torneado', 'Fresado', 'Rectificado', 'Soldadura',
    'Corte', 'Plegado', 'Pintura', 'Montaje');
  PROYECTOS: array[0..4] of string = (
    'Serie A-100', 'Pedido Cliente Norte', 'Recambios Q3', 'Prototipo X', 'Mantenimiento');
var
  NP, I, J, Seed: Integer;
  Objetivo, CapBase: Double;
  SerieArr: TArray<Double>;
  L: TList<TItemHoras>;
  It: TItemHoras;
  R: TOfRetraso;
  MS: TMakespanProyecto;
  PS: TProductivoSetup;
  SumaOcup: Double;
  NConCap: Integer;
begin
  Result := Default(TPlanAnalisis);
  Result.Periodos := APeriodos;
  NP := Length(APeriodos);
  if NP = 0 then Exit;

  // --- Centros: carga/capacidad por periodo ---
  SetLength(Result.Centros, Length(CENTROS));
  for I := 0 to High(CENTROS) do
  begin
    Result.Centros[I].CenterId := 9000 + I;
    Result.Centros[I].Nombre := CENTROS[I];
    SetLength(Result.Centros[I].HorasCarga, NP);
    SetLength(Result.Centros[I].HorasCapacidad, NP);
    // Capacidad base por periodo (horas): ~40h/semana escaladas por granularidad.
    CapBase := 8 + (I mod 3) * 2;           // 8..12 h/periodo base
    Seed := 9000 + I;
    // Objetivo de ocupacion por centro: 55..119% (algunos en sobrecarga).
    Objetivo := 55 + ((Seed * 37) mod 65);
    SerieArr := DemoSerieHaciaValor(Objetivo, NP, 0.30, Seed);
    for J := 0 to NP - 1 do
    begin
      Result.Centros[I].HorasCapacidad[J] := CapBase;
      Result.Centros[I].HorasCarga[J] := CapBase * SerieArr[J] / 100.0;
    end;
  end;

  // --- Operarios: carga/capacidad por periodo ---
  SetLength(Result.Operarios, Length(OPERARIOS));
  for I := 0 to High(OPERARIOS) do
  begin
    Result.Operarios[I].OperatorId := 8000 + I;
    Result.Operarios[I].Nombre := OPERARIOS[I];
    SetLength(Result.Operarios[I].HorasCarga, NP);
    SetLength(Result.Operarios[I].HorasCapacidad, NP);
    CapBase := 7 + (I mod 2) * 1;           // 7..8 h/periodo base
    Seed := 8000 + I * 13;
    Objetivo := 60 + ((Seed * 29) mod 55);  // 60..114%
    SerieArr := DemoSerieHaciaValor(Objetivo, NP, 0.28, Seed);
    for J := 0 to NP - 1 do
    begin
      Result.Operarios[I].HorasCapacidad[J] := CapBase;
      Result.Operarios[I].HorasCarga[J] := CapBase * SerieArr[J] / 100.0;
    end;
  end;

  // --- Totales por periodo (curva temporal) ---
  SetLength(Result.CargaTotalPorPeriodo, NP);
  SetLength(Result.CapacidadTotalPorPeriodo, NP);
  for J := 0 to NP - 1 do
    for I := 0 to High(Result.Centros) do
    begin
      Result.CargaTotalPorPeriodo[J] := Result.CargaTotalPorPeriodo[J] +
        Result.Centros[I].HorasCarga[J];
      Result.CapacidadTotalPorPeriodo[J] := Result.CapacidadTotalPorPeriodo[J] +
        Result.Centros[I].HorasCapacidad[J];
    end;

  // --- OTD: cumplimiento de entregas ---
  Result.Otd.Total := 120;
  Result.Otd.ATiempo := 78;
  Result.Otd.EnRiesgo := 14;
  Result.Otd.Retrasadas := 19;
  Result.Otd.SinCompromiso := 9;
  Result.Otd.RetrasoMedioDias := 2.3;
  Result.Otd.RetrasoMaxDias := 8;
  // Histograma desviacion: [<=-3 -2 -1 0 +1 +2 >=+3]
  Result.Otd.Buckets[0] := 22; Result.Otd.Buckets[1] := 18; Result.Otd.Buckets[2] := 26;
  Result.Otd.Buckets[3] := 12; Result.Otd.Buckets[4] := 9;  Result.Otd.Buckets[5] := 6;
  Result.Otd.Buckets[6] := 4;

  // --- MIX: carga por articulo ---
  L := TList<TItemHoras>.Create;
  try
    for I := 0 to High(ARTICULOS) do
    begin
      It := Default(TItemHoras);
      It.Clave := ARTICULOS[I];
      Seed := 1000 + I * 7;
      It.Horas := 12 + ((Seed * 31) mod 90);     // 12..101 h
      It.Conteo := 2 + (I mod 6);
      L.Add(It);
    end;
    L.Sort(TComparer<TItemHoras>.Construct(
      function(const A, B: TItemHoras): Integer
      begin Result := CompareValue(B.Horas, A.Horas); end));
    Result.PorArticulo := L.ToArray;
  finally
    L.Free;
  end;

  // --- MIX: carga por tipo de operacion ---
  L := TList<TItemHoras>.Create;
  try
    for I := 0 to High(OPERACIONES) do
    begin
      It := Default(TItemHoras);
      It.Clave := OPERACIONES[I];
      Seed := 2000 + I * 11;
      It.Horas := 20 + ((Seed * 23) mod 120);    // 20..139 h
      It.Conteo := 3 + (I mod 8);
      L.Add(It);
    end;
    L.Sort(TComparer<TItemHoras>.Construct(
      function(const A, B: TItemHoras): Integer
      begin Result := CompareValue(B.Horas, A.Horas); end));
    Result.PorOperacion := L.ToArray;
  finally
    L.Free;
  end;

  // --- MIX: nº operaciones por centro ---
  L := TList<TItemHoras>.Create;
  try
    for I := 0 to High(CENTROS) do
    begin
      It := Default(TItemHoras);
      It.Clave := CENTROS[I];
      It.Conteo := 8 + ((9000 + I) * 17) mod 40;  // 8..47 ops
      It.Horas := It.Conteo * 1.5;
      L.Add(It);
    end;
    L.Sort(TComparer<TItemHoras>.Construct(
      function(const A, B: TItemHoras): Integer
      begin Result := CompareValue(B.Conteo, A.Conteo); end));
    Result.OpsPorCentro := L.ToArray;
  finally
    L.Free;
  end;

  // --- ENTREGAS: top OF mas retrasadas ---
  SetLength(Result.TopRetrasos, 10);
  for I := 0 to 9 do
  begin
    R := Default(TOfRetraso);
    R.Etiqueta := 'OF ' + Format('%.4d', [2500 + I * 7]);
    R.RetrasoDias := 8.5 - I * 0.7;     // 8.5 -> 2.2 dias, descendente
    Result.TopRetrasos[I] := R;
  end;

  // --- TIEMPOS: makespan por proyecto ---
  SetLength(Result.Makespans, Length(PROYECTOS));
  for I := 0 to High(PROYECTOS) do
  begin
    MS := Default(TMakespanProyecto);
    MS.Nombre := PROYECTOS[I];
    Seed := 3000 + I * 19;
    MS.HorasSpan := 40 + ((Seed * 13) mod 200);   // 40..239 h
    Result.Makespans[I] := MS;
  end;

  // --- TIEMPOS: histograma de duraciones (8 buckets) ---
  Result.Duraciones[0] := 14; Result.Duraciones[1] := 28; Result.Duraciones[2] := 41;
  Result.Duraciones[3] := 37; Result.Duraciones[4] := 25; Result.Duraciones[5] := 16;
  Result.Duraciones[6] := 8;  Result.Duraciones[7] := 3;

  // --- EFICIENCIA: productivo vs setup por centro ---
  SetLength(Result.ProductivoSetup, Length(CENTROS));
  for I := 0 to High(CENTROS) do
  begin
    PS := Default(TProductivoSetup);
    PS.Nombre := CENTROS[I];
    Seed := 4000 + I * 5;
    PS.HorasProductivo := 30 + ((Seed * 17) mod 70);  // 30..99 h
    PS.HorasSetup := 4 + ((Seed * 7) mod 18);         // 4..21 h
    Result.ProductivoSetup[I] := PS;
  end;

  // --- EFICIENCIA: utilizacion media global (media de ocupacion de centros) ---
  SumaOcup := 0; NConCap := 0;
  for I := 0 to High(Result.Centros) do
    if Result.Centros[I].TotalCapacidad > 0 then
    begin
      SumaOcup := SumaOcup + Result.Centros[I].OcupacionPct;
      Inc(NConCap);
    end;
  if NConCap > 0 then Result.UtilMediaGlobal := SumaOcup / NConCap;

  // --- PRO: Gantt-resumen por proyecto ---
  SetLength(Result.GanttResumen, Length(PROYECTOS));
  for I := 0 to High(PROYECTOS) do
  begin
    Result.GanttResumen[I].Nombre := PROYECTOS[I];
    Result.GanttResumen[I].Inicio := APeriodos[0].Inicio + I * 2;
    Result.GanttResumen[I].Fin := APeriodos[0].Inicio + I * 2 +
      (5 + ((3000 + I * 19) * 13) mod 20);   // 5..24 dias de span
  end;

  // --- PRO: cadenas de dependencias ---
  SetLength(Result.Cadenas, 8);
  for I := 0 to 7 do
  begin
    Result.Cadenas[I].Etiqueta :=
      'OF' + IntToStr(2500 + I * 7) + ' Torneado -> Montaje';
    Seed := 5000 + I * 23;
    Result.Cadenas[I].HorasTotal := 60 - I * 5 + (Seed mod 12);  // desc
    Result.Cadenas[I].NumOps := 6 - (I mod 4);                   // 3..6
  end;

  // --- PRO: margen hasta entrega (los 15 mas ajustados) ---
  SetLength(Result.MargenEntrega, 15);
  for I := 0 to 14 do
  begin
    Result.MargenEntrega[I].Etiqueta := 'OF ' + Format('%.4d', [2600 + I * 5]);
    Result.MargenEntrega[I].MargenDias := -6.0 + I * 1.1;  // -6 .. +9.4 dias
  end;

  // --- PRO: prioridad vs retraso ---
  SetLength(Result.PrioridadRetraso, 30);
  for I := 0 to 29 do
  begin
    Result.PrioridadRetraso[I].Etiqueta := 'OF ' + IntToStr(2700 + I);
    Seed := 6000 + I * 17;
    Result.PrioridadRetraso[I].Prioridad := 1 + (Seed mod 5);        // 1..5
    Result.PrioridadRetraso[I].RetrasoDias := -3.0 + (Seed mod 90) / 9.0; // -3..+7
  end;

  // --- PRO: CRP acumulada ---
  SetLength(Result.CargaAcumulada, NP);
  SetLength(Result.CapacidadAcumulada, NP);
  for J := 0 to NP - 1 do
  begin
    Result.CargaAcumulada[J] := Result.CargaTotalPorPeriodo[J];
    Result.CapacidadAcumulada[J] := Result.CapacidadTotalPorPeriodo[J];
    if J > 0 then
    begin
      Result.CargaAcumulada[J] := Result.CargaAcumulada[J] + Result.CargaAcumulada[J - 1];
      Result.CapacidadAcumulada[J] := Result.CapacidadAcumulada[J] + Result.CapacidadAcumulada[J - 1];
    end;
  end;

  // --- PRO: avance del plan (unidades + estados) ---
  Result.Progreso.UnidadesFabricadas := 640;
  Result.Progreso.UnidadesAFabricar := 1000;
  Result.Progreso.NodosPorEstado[0] := 34;   // Pendiente
  Result.Progreso.NodosPorEstado[1] := 21;   // En curso
  Result.Progreso.NodosPorEstado[2] := 58;   // Hecho
  Result.Progreso.NodosPorEstado[3] := 5;    // Otro
  Result.Progreso.NodosPorEstado[4] := 2;

  // --- PRO: mix por cliente ---
  SetLength(Result.PorCliente, 6);
  for I := 0 to 5 do
  begin
    Result.PorCliente[I].Clave := 'Cliente ' + Chr(Ord('A') + I);
    Seed := 7000 + I * 29;
    Result.PorCliente[I].Horas := 40 + ((Seed * 19) mod 160);   // 40..199
    Result.PorCliente[I].Conteo := 3 + (I mod 7);
  end;

  // --- PRO: cobertura de personal por centro ---
  SetLength(Result.Cobertura, Length(CENTROS));
  for I := 0 to High(CENTROS) do
  begin
    Result.Cobertura[I].Nombre := CENTROS[I];
    Seed := 4500 + I * 11;
    Result.Cobertura[I].Necesarios := 2 + (Seed mod 5);   // 2..6
    Result.Cobertura[I].Asignados := 1 + ((Seed div 3) mod 6); // 1..6 (a veces falta)
  end;
end;

{ Orquestacion }

function CalcularPlanAnalisis(const APeriodos: TArray<TPeriodoPlan>): TPlanAnalisis;
var
  I, J: Integer;
begin
  // Modo demo: datos ficticios generados al vuelo, sin tocar la BD.
  if DemoMode.Active then
    Exit(CalcularPlanAnalisisDemo(APeriodos));

  Result := Default(TPlanAnalisis);
  Result.Periodos := APeriodos;
  CalcularCarga(APeriodos, Result.Centros);
  CalcularCargaOperario(APeriodos, Result.Operarios);
  Result.Otd := CalcularOTD;

  // Totales por periodo (curva temporal).
  SetLength(Result.CargaTotalPorPeriodo, Length(APeriodos));
  SetLength(Result.CapacidadTotalPorPeriodo, Length(APeriodos));
  for J := 0 to High(APeriodos) do
  begin
    Result.CargaTotalPorPeriodo[J] := 0;
    Result.CapacidadTotalPorPeriodo[J] := 0;
    for I := 0 to High(Result.Centros) do
    begin
      Result.CargaTotalPorPeriodo[J] := Result.CargaTotalPorPeriodo[J] +
        Result.Centros[I].HorasCarga[J];
      if Result.Centros[I].HorasCapacidad[J] > 0 then
        Result.CapacidadTotalPorPeriodo[J] := Result.CapacidadTotalPorPeriodo[J] +
          Result.Centros[I].HorasCapacidad[J];
    end;
  end;

  // Datos de los graficos adicionales.
  CalcularMix(Result.PorArticulo, Result.PorOperacion, Result.OpsPorCentro,
    Result.Centros);
  Result.TopRetrasos := CalcularTopRetrasos(10);
  CalcularTiempos(Result.Makespans, Result.Duraciones);
  CalcularEficiencia(Result.ProductivoSetup, Result.Centros);

  // Utilizacion media global (% sobre centros con capacidad).
  Result.UtilMediaGlobal := 0;
  J := 0;
  for I := 0 to High(Result.Centros) do
    if Result.Centros[I].TotalCapacidad > 0 then
    begin
      Result.UtilMediaGlobal := Result.UtilMediaGlobal + Result.Centros[I].OcupacionPct;
      Inc(J);
    end;
  if J > 0 then Result.UtilMediaGlobal := Result.UtilMediaGlobal / J;

  // --- Graficos PRO ---
  CalcularGanttResumen(Result.GanttResumen);
  CalcularCadenas(Result.Cadenas);
  CalcularMargenYPrioridad(Result.MargenEntrega, Result.PrioridadRetraso);
  CalcularProgreso(Result.Progreso);
  CalcularClienteYCobertura(Result.PorCliente, Result.Cobertura, Result.Centros);

  // CRP: carga y capacidad acumuladas periodo a periodo.
  SetLength(Result.CargaAcumulada, Length(APeriodos));
  SetLength(Result.CapacidadAcumulada, Length(APeriodos));
  for J := 0 to High(APeriodos) do
  begin
    Result.CargaAcumulada[J] := Result.CargaTotalPorPeriodo[J];
    Result.CapacidadAcumulada[J] := Result.CapacidadTotalPorPeriodo[J];
    if J > 0 then
    begin
      Result.CargaAcumulada[J] := Result.CargaAcumulada[J] + Result.CargaAcumulada[J - 1];
      Result.CapacidadAcumulada[J] := Result.CapacidadAcumulada[J] + Result.CapacidadAcumulada[J - 1];
    end;
  end;
end;

end.
