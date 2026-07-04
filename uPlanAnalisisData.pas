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
  uDMPlanner, uCentreCalendar;

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

{ Orquestacion }

function CalcularPlanAnalisis(const APeriodos: TArray<TPeriodoPlan>): TPlanAnalisis;
var
  I, J: Integer;
begin
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
end;

end.
