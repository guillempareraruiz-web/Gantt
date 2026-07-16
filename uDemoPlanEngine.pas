unit uDemoPlanEngine;

{
  MOTOR DEMO PRO (Metodo 2) - generacion + planificacion de nodos demo TODO EN
  RAM, con persistencia masiva al final. Alternativa al flujo clasico de
  uGenerarNodosDemo (Metodo 1), que hace ~3.000 round-trips a BD.

  FILOSOFIA (APS de verdad):
    1. Una sola lectura de metadatos (centros + calendarios + operarios + rango
       de NodeIds). Cero consultas por nodo.
    2. Generar la carga (OF/OT/OP, duracion, centro, dependencias, fechas...) en
       arrays en memoria.
    3. Ordenar por Fecha Entrega (EDD).
    4. Planificar en RAM en UN SOLO paseo, en orden topologico (predecesores
       antes): cada OP se coloca en el primer hueco libre de su centro
       >= max(FechaBase, fin de sus predecesores), respetando calendario y lanes.
       Sin solapamientos POR CONSTRUCCION (no hay reencadenado posterior).
    5. Persistir masivamente: INSERT multifila (900 filas/sentencia) con
       IDENTITY_INSERT, en 1 transaccion. ~4-8 round-trips totales.

  THREADING: pensado para correr dentro de uBusyDialog.RunBusy (thread propio con
  COM inicializado). Por eso NO usa DMPlanner.ADOConnection (compartida, no
  thread-safe): abre su PROPIA conexion con DMPlanner.ConnectionStringForThreads.

  El calculo (paso 4) es intrinsecamente secuencial (estado compartido: la
  ocupacion de cada centro). Paralelizarlo daria races sin beneficio real para
  unos miles de nodos que en RAM tardan milisegundos. El unico thread es el de
  RunBusy, para no congelar la UI.
}

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Math,
  System.IOUtils,
  System.Generics.Collections, System.Generics.Defaults,
  Data.Win.ADODB,
  uCentreCalendar, uGanttTypes;

type
  // Metodo de persistencia (paso 5). El calculo (pasos 1-4) es identico.
  //   pmMultifila (M2): INSERT ... VALUES (f1),(f2),... por lotes de 900 filas.
  //   pmStaging   (M3): BULK a tablas #temp (sin FK/indices) + INSERT..SELECT
  //                     set-based a las tablas reales. Mucho mas rapido en el
  //                     lado servidor porque valida FK/indices en 1 operacion de
  //                     conjunto, no fila a fila. PERO el cuello de botella sigue
  //                     siendo enviar el TEXTO SQL gigante (~1500ms de 1800).
  //   pmBulkADO   (M4): rellena las #temp con un RECORDSET ADO en modo batch
  //                     (AddNew + UpdateBatch): ADO envia las filas en BINARIO
  //                     via OLE DB. PERO el overhead POR FILA del provider (aun
  //                     en local) sigue costando ~1.7s (DIAG: generar en servidor
  //                     246ms vs enviar del cliente 1690ms).
  //   pmBulkFile  (M5): escribe las filas a ficheros CSV en disco y hace
  //                     BULK INSERT: SQL Server lee el fichero en STREAMING, sin
  //                     overhead por fila. Unica via que baja de ~1.7s a ~300ms.
  //                     Requiere que la cuenta de servicio SQL pueda leer el path.
  TPersistMethod = (pmMultifila, pmStaging, pmBulkADO, pmBulkFile);

  // Parametros de generacion (los pone el form desde sus controles).
  TDemoGenParams = record
    CodigoEmpresa: Integer;
    ProjectId: Integer;         // proyecto demo destino
    NumOFs: Integer;
    OTsPorOF: Integer;
    OpsPorOT: Integer;
    PctPlanificados: Integer;   // % (de los NO sin-centro) que reciben centro real
    PctSinCentro: Integer;      // % del total al centro __SINCENTRO__
    FechaBase: TDateTime;       // inicio de planificacion
    IncluirOperarios: Boolean;
    GenerarDependencias: Boolean;
    OptimizadosRandom: Boolean; // 3 estados duracion real vs original
    FabricacionRandom: Boolean; // avance 0%/parcial/100%
    LimpiarAntes: Boolean;      // borrar nodos previos del proyecto
    PersistMethod: TPersistMethod;  // M2 (multifila) o M3 (staging)
  end;

  TDemoGenResult = record
    TotalNodos: Integer;
    TotalPlanificados: Integer;   // colocados por el motor (incluye __SINCENTRO__)
    TotalSinCentro: Integer;      // en el centro __SINCENTRO__
    TotalPendientes: Integer;     // sin centro (backlog no colocado)
    TotalDependencias: Integer;
    TotalSolapamientos: Integer;  // verificacion final (deberia ser 0)
    MillisTotal: Int64;
    MillisGenerar: Int64;
    MillisPlanificar: Int64;
    MillisPersistir: Int64;
  end;

// Ejecuta TODO el flujo (generar + planificar + persistir) en RAM + persistencia
// masiva. Pensado para llamarse DENTRO de RunBusy (abre su propia conexion).
// Devuelve estadisticas. Lanza excepcion en error (RunBusy la propaga).
function EjecutarDemoPlanEngine(const AParams: TDemoGenParams): TDemoGenResult;

implementation

uses
  System.StrUtils,
  uDMPlanner, uPlanLog, uDemoUtillajes;

const
  OPERS: array[0..9] of string = (
    'CORTAR', 'PULIR', 'MONTAR', 'PINTAR', 'LACAR',
    'EMBALAR', 'BRONCEAR', 'TALADRAR', 'SOLDAR', 'MECANIZAR');
  ARTS: array[0..7] of string = (
    'ART-1001', 'ART-1002', 'ART-2050', 'ART-2051',
    'ART-3100', 'ART-3101', 'ART-4200', 'ART-4201');
  DESCS: array[0..7] of string = (
    'Pieza A grande', 'Pieza A peque'#241'a', 'Pieza B chasis', 'Pieza B soporte',
    'Caja electr'#243'nica', 'Caja sensores', 'Conjunto C ensamblado', 'Conjunto C revisi'#243'n');
  CLIS: array[0..4] of string = ('CLI-001', 'CLI-002', 'CLI-003', 'CLI-004', 'CLI-005');

  FILAS_POR_INSERT = 900;   // SQL Server admite hasta 1000 filas por INSERT VALUES

type
  // Una operacion (Nivel 3, OP) en RAM. Todo lo necesario para generar,
  // planificar y persistir sin volver a BD.
  TDemoOp = record
    NodeId: Integer;            // asignado desde el rango reservado
    NumOF, NumPedido: Integer;
    NumTrabajo: Integer;
    Operacion: string;
    CenterId: Integer;          // -1 = pendiente puro (sin centro)
    DurReal, DurOriginal: Double;
    UnidTotal, UnidHechas: Integer;
    Prioridad, NumOpsNec: Integer;
    FechaEntrega, FechaNecesaria: TDateTime;
    ArtIdx, CliIdx: Integer;
    OperatorId: Integer;        // -1 = sin operario
    NumOpsAsig: Integer;        // operarios efectivamente asignados (0 o 1 en Demo)
    PredIdx: Integer;           // indice de la OP predecesora en el array (-1 = ninguna)
    // Resultado de la planificacion (en RAM):
    Ini, Fin: TDateTime;
    Colocada: Boolean;
  end;

  // Ocupacion por lane de un centro (para colocacion colision-aware en RAM).
  TSlot = record Ini, Fin: TDateTime; end;
  TLaneList = TList<TSlot>;
  TCentroRT = class
    CenterId: Integer;
    Cal: TCentreCalendar;   // referencia compartida (de CentresRepo), NO liberar
    Lanes: TArray<TLaneList>;
    destructor Destroy; override;
  end;

destructor TCentroRT.Destroy;
var L: Integer;
begin
  for L := 0 to High(Lanes) do
    Lanes[L].Free;
  inherited;
end;

function EjecutarDemoPlanEngine(const AParams: TDemoGenParams): TDemoGenResult;
var
  Conn: TADOConnection;
  Cmd: TADOCommand;
  Q: TADOQuery;
  CE, PID: string;
  Ops: TArray<TDemoOp>;
  CentrosReales: TArray<Integer>;
  SinCentroId, BaseId: Integer;
  OperatorIds: TArray<Integer>;
  // Ocupacion e info de centro por CenterId (vivo solo aqui).
  OccByCenter: TObjectDictionary<Integer, TCentroRT>;
  CentroInfoById: TDictionary<Integer, TCentreTreball>;
  SW, SWPart: TDateTime;   // TStopwatch no: usamos Now-diff via MilliSecondsBetween

  function Inv: TFormatSettings;
  begin
    Result := TFormatSettings.Invariant;
  end;

  function DT(const V: TDateTime): string;
  begin
    // Formato ISO 8601 con 'T': SQL Server lo interpreta SIEMPRE igual, sea cual
    // sea el SET DATEFORMAT/idioma de la sesion (evita "fuera de intervalo" con
    // configuracion regional dd/mm). Invariant para no meter separadores locales.
    Result := QuotedStr(FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', V, TFormatSettings.Invariant));
  end;

  function NombreMetodo: string;
  begin
    case AParams.PersistMethod of
      pmStaging:  Result := 'M3 staging texto';
      pmBulkADO:  Result := 'M4 staging bulk ADO';
      pmBulkFile: Result := 'M5 bulk file';
    else          Result := 'M2 multifila';
    end;
  end;

  function QStr(const S: string): string;
  begin
    Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
  end;

  function LanesDe(const C: TCentreTreball): Integer;
  begin
    if C.IsSequencial then Exit(1);
    if C.MaxLaneCount <= 0 then Exit(1);
    Result := C.MaxLaneCount;
  end;

  // --- PASO 1: leer metadatos (una sola vez) -------------------------------
  procedure LeerMetadatos;
  var
    I: Integer;
    Cod: string;
  begin
    // Centros visibles/habilitados; separar __SINCENTRO__ del pool real.
    SetLength(CentrosReales, 0);
    SinCentroId := 0;
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := Conn;
      Q.SQL.Text := 'SELECT CenterId, CodigoCentro FROM FS_PL_Center ' +
        'WHERE CodigoEmpresa = ' + CE +
        ' AND ISNULL(Visible,1) = 1 AND ISNULL(Habilitado,1) = 1 ORDER BY CenterId';
      Q.Open;
      while not Q.Eof do
      begin
        Cod := Q.FieldByName('CodigoCentro').AsString;
        if SameText(Cod, CENTRO_SIN_CENTRO) then
          SinCentroId := Q.FieldByName('CenterId').AsInteger
        else
        begin
          SetLength(CentrosReales, Length(CentrosReales) + 1);
          CentrosReales[High(CentrosReales)] := Q.FieldByName('CenterId').AsInteger;
        end;
        Q.Next;
      end;
    finally
      Q.Free;
    end;

    // Operarios activos (si se piden asignaciones).
    SetLength(OperatorIds, 0);
    if AParams.IncluirOperarios then
    begin
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := Conn;
        Q.SQL.Text := 'SELECT OperatorId FROM FS_PL_Operator WHERE CodigoEmpresa = ' +
          CE + ' AND ISNULL(Activo,1) = 1 ORDER BY OperatorId';
        Q.Open;
        while not Q.Eof do
        begin
          SetLength(OperatorIds, Length(OperatorIds) + 1);
          OperatorIds[High(OperatorIds)] := Q.FieldByName('OperatorId').AsInteger;
          Q.Next;
        end;
      finally
        Q.Free;
      end;
    end;

    // Rango de NodeIds a reservar (los asignamos nosotros -> IDENTITY_INSERT).
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := Conn;
      Q.SQL.Text := 'SELECT ISNULL(MAX(NodeId),0) AS M FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE;
      Q.Open;
      BaseId := Q.FieldByName('M').AsInteger + 1;
    finally
      Q.Free;
    end;
  end;

  // Info de centro (lanes/calendario) cacheada por CenterId.
  function CentroInfo(ACenterId: Integer): TCentreTreball;
  var Cx: TCentreTreball;
  begin
    if CentroInfoById.TryGetValue(ACenterId, Result) then Exit;
    Result := Default(TCentreTreball);
    if Assigned(DMPlanner.CentresRepo) then
      for Cx in DMPlanner.CentresRepo.GetAll do
        if Cx.Id = ACenterId then begin Result := Cx; Break; end;
    CentroInfoById.AddOrSetValue(ACenterId, Result);
  end;

  function OccDe(ACenterId: Integer): TCentroRT;
  var C: TCentreTreball; L: Integer;
  begin
    if OccByCenter.TryGetValue(ACenterId, Result) then Exit;
    C := CentroInfo(ACenterId);
    Result := TCentroRT.Create;
    Result.CenterId := ACenterId;
    Result.Cal := nil;
    if (ACenterId > 0) and Assigned(DMPlanner.CentresRepo) then
      Result.Cal := DMPlanner.CentresRepo.GetCalendarFor(ACenterId);
    SetLength(Result.Lanes, Max(1, LanesDe(C)));
    for L := 0 to High(Result.Lanes) do
      Result.Lanes[L] := TLaneList.Create;
    OccByCenter.AddOrSetValue(ACenterId, Result);
  end;

  function LaneChoca(ALane: TLaneList; const AIni, AFin: TDateTime): Boolean;
  var S: TSlot;
  begin
    Result := False;
    for S in ALane do
      if (AFin > S.Ini) and (AIni < S.Fin) then Exit(True);
  end;

  // --- PASO 2: generar la carga en RAM -------------------------------------
  procedure GenerarEnRAM;
  var
    iOF, iOT, iOP, Idx, Dado: Integer;
    NumOF, NumPedido, NumTrabajo: Integer;
    FEntOT, FNecOT: TDateTime;   // fecha entrega COMPARTIDA por toda la OT
  begin
    SetLength(Ops, 0);
    Idx := 0;
    for iOF := 1 to AParams.NumOFs do
    begin
      NumOF := 10000 + iOF;
      NumPedido := 5000 + (iOF div 3);
      for iOT := 1 to AParams.OTsPorOF do
      begin
        NumTrabajo := iOF * 100 + iOT;

        // Fecha entrega decidida UNA VEZ por OT (todas sus OPs la comparten):
        // asi el orden EDD mantiene juntas las OPs de la cadena y el sucesor
        // nunca se procesa antes que su predecesor. 3 grupos (vencida/a punto/futura).
        Dado := Random(4);
        if Dado = 0 then      FEntOT := Trunc(Date) - (1 + Random(8))
        else if Dado = 1 then FEntOT := Trunc(Date) + Random(4)
        else                  FEntOT := Trunc(Date) + 5 + Random(30);
        FNecOT := FEntOT - 2 - Random(5);

        for iOP := 1 to AParams.OpsPorOT do
        begin
          SetLength(Ops, Idx + 1);
          Ops[Idx] := Default(TDemoOp);
          Ops[Idx].NodeId := BaseId + Idx;
          Ops[Idx].NumOF := NumOF;
          Ops[Idx].NumPedido := NumPedido;
          Ops[Idx].NumTrabajo := NumTrabajo;
          Ops[Idx].Operacion := OPERS[Random(Length(OPERS))];
          Ops[Idx].DurOriginal := 30 + Random(240);
          Ops[Idx].DurReal := Ops[Idx].DurOriginal;

          // Optimizacion (3 estados) si se pide.
          if AParams.OptimizadosRandom then
          begin
            Dado := Random(100);
            if Dado < 35 then
              Ops[Idx].DurReal := Ops[Idx].DurOriginal * (0.70 + Random(21) / 100.0)
            else if Dado < 70 then
              Ops[Idx].DurReal := Ops[Idx].DurOriginal
            else
              Ops[Idx].DurReal := Ops[Idx].DurOriginal * (1.15 + Random(26) / 100.0);
          end;

          // Centro: 3 grupos (sin centro / real / pendiente).
          Dado := Random(100);
          if (Dado < AParams.PctSinCentro) and (SinCentroId > 0) then
            Ops[Idx].CenterId := SinCentroId
          else if (Random(100) < AParams.PctPlanificados) and (Length(CentrosReales) > 0) then
            Ops[Idx].CenterId := CentrosReales[Random(Length(CentrosReales))]
          else
            Ops[Idx].CenterId := -1;

          // Unidades + avance.
          Ops[Idx].UnidTotal := 100 + Random(900);
          Ops[Idx].UnidHechas := 0;
          if AParams.FabricacionRandom then
          begin
            Dado := Random(10);
            if Dado < 4 then      Ops[Idx].UnidHechas := 0
            else if Dado < 9 then Ops[Idx].UnidHechas := Random(Ops[Idx].UnidTotal)
            else                  Ops[Idx].UnidHechas := Ops[Idx].UnidTotal;
          end;

          Ops[Idx].Prioridad := 1 + Random(5);
          Ops[Idx].NumOpsNec := 1 + Random(3);

          // Fecha entrega/necesaria: la de la OT (compartida por sus OPs).
          Ops[Idx].FechaEntrega := FEntOT;
          Ops[Idx].FechaNecesaria := FNecOT;

          Ops[Idx].ArtIdx := Random(Length(ARTS));
          Ops[Idx].CliIdx := Random(Length(CLIS));

          if AParams.IncluirOperarios and (Length(OperatorIds) > 0) and
             (Ops[Idx].CenterId > 0) and (Random(10) < 7) then
            Ops[Idx].OperatorId := OperatorIds[Random(Length(OperatorIds))]
          else
            Ops[Idx].OperatorId := -1;

          // OperariosAsignados: Demo asigna como mucho 1 operario por OP. Este
          // campo alimenta el color de la vista Operarios (rojo/amarillo/verde);
          // si no se persiste, todos los nodos saldrian rojos.
          if Ops[Idx].OperatorId > 0 then
            Ops[Idx].NumOpsAsig := 1
          else
            Ops[Idx].NumOpsAsig := 0;

          // Dependencia FS con la OP anterior de la misma OT.
          if AParams.GenerarDependencias and (iOP > 1) then
            Ops[Idx].PredIdx := Idx - 1
          else
            Ops[Idx].PredIdx := -1;

          Inc(Idx);
        end;
      end;
    end;
  end;

  // --- PASO 4: planificar en RAM (topologico + colision-aware) --------------
  // Coloca UNA op respetando su centro, calendario, lanes y el fin de su
  // predecesor. Devuelve Ini/Fin.
  procedure ColocarOp(var AOp: TDemoOp);
  var
    H: TCentroRT;
    Desde, Cand, CandFin, ProxLibre: TDateTime;
    L, Intentos: Integer;
    Cabe: Boolean;
    S: TSlot;
    Slot: TSlot;
  begin
    // Pendiente puro (sin centro): no se coloca.
    if AOp.CenterId <= 0 then Exit;

    H := OccDe(AOp.CenterId);

    // Punto de partida: FechaBase, y nunca antes del fin del predecesor (si el
    // predecesor se coloco; si quedo pendiente, arrancamos en FechaBase).
    Desde := AParams.FechaBase;
    if (AOp.PredIdx >= 0) and Ops[AOp.PredIdx].Colocada and
       (Ops[AOp.PredIdx].Fin > Desde) then
      Desde := Ops[AOp.PredIdx].Fin;

    if H.Cal <> nil then Cand := H.Cal.NextWorkingTime(Desde)
    else Cand := Desde;

    for Intentos := 0 to 20000 do
    begin
      if H.Cal <> nil then CandFin := H.Cal.AddWorkingMinutes(Cand, Round(AOp.DurReal))
      else CandFin := Cand + AOp.DurReal / (24 * 60);

      Cabe := False;
      for L := 0 to High(H.Lanes) do
        if not LaneChoca(H.Lanes[L], Cand, CandFin) then
        begin
          Cabe := True; Break;
        end;

      if Cabe then Break;

      // Avanzar al primer fin de slot solapante.
      ProxLibre := 0;
      for L := 0 to High(H.Lanes) do
        for S in H.Lanes[L] do
          if (CandFin > S.Ini) and (Cand < S.Fin) then
            if (ProxLibre = 0) or (S.Fin < ProxLibre) then
              ProxLibre := S.Fin;
      if ProxLibre <= Cand then ProxLibre := Cand + OneMinute;
      if H.Cal <> nil then Cand := H.Cal.NextWorkingTime(ProxLibre)
      else Cand := ProxLibre;
    end;

    AOp.Ini := Cand;
    AOp.Fin := CandFin;
    AOp.Colocada := True;

    // Registrar en el primer lane libre.
    Slot.Ini := Cand; Slot.Fin := CandFin;
    for L := 0 to High(H.Lanes) do
      if not LaneChoca(H.Lanes[L], Cand, CandFin) then
      begin
        H.Lanes[L].Add(Slot); Exit;
      end;
    H.Lanes[0].Add(Slot);   // no deberia (el bucle garantiza sitio)
  end;

  // Ordena las OPs por Fecha Entrega (EDD), PERO manteniendo cada cadena de
  // dependencias en orden (un predecesor siempre antes que su sucesor). Como las
  // OPs de una OT ya vienen consecutivas y encadenadas, ordenamos por una clave
  // (FechaEntrega de la primera OP de la OT) y dentro respetamos el orden de
  // generacion. Devuelve el orden de indices a procesar.
  function OrdenTopologicoEDD: TArray<Integer>;
  var
    I: Integer;
    Orden: TArray<Integer>;
  begin
    SetLength(Orden, Length(Ops));
    for I := 0 to High(Ops) do Orden[I] := I;
    // Sort estable por (FechaEntrega, NumOF, NumTrabajo, NodeId) -> las OPs de la
    // misma OT quedan juntas y en su orden natural (predecesor antes).
    TArray.Sort<Integer>(Orden, TComparer<Integer>.Construct(
      function(const A, B: Integer): Integer
      begin
        Result := CompareDateTime(Ops[A].FechaEntrega, Ops[B].FechaEntrega);
        if Result = 0 then Result := Ops[A].NumOF - Ops[B].NumOF;
        if Result = 0 then Result := Ops[A].NumTrabajo - Ops[B].NumTrabajo;
        if Result = 0 then Result := Ops[A].NodeId - Ops[B].NodeId;
      end));
    Result := Orden;
  end;

  procedure PlanificarEnRAM;
  var
    Orden: TArray<Integer>;
    K, Idx: Integer;
  begin
    Orden := OrdenTopologicoEDD;
    for K := 0 to High(Orden) do
    begin
      Idx := Orden[K];
      ColocarOp(Ops[Idx]);
    end;
  end;

  // --- PASO 5: persistir masivamente ---------------------------------------
  procedure EjecutarMultifila(const APrefix: string; const ASb: TStringBuilder;
    AWrapIdentity: Boolean);
  var Sql: string;
  begin
    if ASb.Length = 0 then Exit;
    Sql := APrefix + ASb.ToString.Substring(1);   // quitar coma inicial
    if AWrapIdentity then
      Sql := 'SET IDENTITY_INSERT FS_PL_Node ON; ' + Sql +
             '; SET IDENTITY_INSERT FS_PL_Node OFF;';
    Cmd.CommandText := Sql;
    Cmd.Execute;
    ASb.Clear;
  end;

  // Genera la fila ",(...)" de cada tabla para la op O y la anexa a los builders.
  // Comun a M2 (multifila) y M3 (staging): solo cambia el DESTINO, no las filas.
  procedure AppendFilas(const O: TDemoOp;
    const SbNode, SbData, SbAsig, SbDep: TStringBuilder;
    var NNode, NData, NAsig, NDep: Integer);
  var
    IniSQL, FinSQL, CenterSQL: string;
  begin
    if O.Colocada then
    begin
      IniSQL := DT(O.Ini); FinSQL := DT(O.Fin);
    end
    else
    begin
      IniSQL := 'NULL'; FinSQL := 'NULL';
    end;
    if O.CenterId <= 0 then CenterSQL := 'NULL'
    else CenterSQL := IntToStr(O.CenterId);

    SbNode.Append(',(' + CE + ', ' + IntToStr(O.NodeId) + ', ' + PID + ', ' +
      CenterSQL + ', ' + IniSQL + ', ' + FinSQL + ', ' +
      FloatToStr(O.DurReal, Inv) + ', ' + QStr(O.Operacion) + ', 15251072, 11166760)');
    Inc(NNode);

    SbData.Append(',(' + CE + ', ' + IntToStr(O.NodeId) + ', ' + QStr(O.Operacion) + ', ' +
      IntToStr(O.NumOF) + ', ' + IntToStr(O.NumPedido) + ', ' + QStr(IntToStr(O.NumTrabajo)) + ', ' +
      FloatToStr(O.DurReal, Inv) + ', ' + FloatToStr(O.DurOriginal, Inv) + ', ' +
      IntToStr(O.UnidTotal) + ', ' + IntToStr(O.UnidHechas) + ', ' + IntToStr(O.NumOpsNec) +
      ', ' + IntToStr(O.NumOpsAsig) +
      ', 15251072, 11166760, ' + IntToStr(O.Prioridad) + ', ' +
      DT(O.FechaEntrega) + ', ' + DT(O.FechaNecesaria) + ', ' +
      QStr(ARTS[O.ArtIdx]) + ', ' + QStr(DESCS[O.ArtIdx]) + ', ' + QStr(CLIS[O.CliIdx]) + ')');
    Inc(NData);

    if O.OperatorId > 0 then
    begin
      SbAsig.Append(',(' + CE + ', ' + IntToStr(O.OperatorId) + ', ' +
        IntToStr(O.NodeId) + ', ' + FloatToStr(O.DurReal / 60, Inv) + ')');
      Inc(NAsig);
    end;

    if O.PredIdx >= 0 then
    begin
      SbDep.Append(',(' + CE + ', ' + PID + ', ' +
        IntToStr(Ops[O.PredIdx].NodeId) + ', ' + IntToStr(O.NodeId) + ', 0, 100)');
      Inc(NDep);
    end;
  end;

  procedure PersistirMultifila;
  var
    SbNode, SbData, SbAsig, SbDep: TStringBuilder;
    NNode, NData, NAsig, NDep, I: Integer;
    O: TDemoOp;

    procedure FlushTodo;
    begin
      EjecutarMultifila('INSERT INTO FS_PL_Node (CodigoEmpresa, NodeId, ProjectId, ' +
        'CenterId, FechaInicio, FechaFin, DuracionMin, Caption, ColorFondo, ' +
        'ColorBorde) VALUES ', SbNode, True);
      NNode := 0;
      EjecutarMultifila('INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, ' +
        'NumeroOF, NumeroPedido, NumeroTrabajo, DuracionMin, DuracionMinOriginal, ' +
        'UnidadesAFabricar, UnidadesFabricadas, OperariosNecesarios, OperariosAsignados, ' +
        'ColorFondoOp, ColorBordeOp, Prioridad, FechaEntrega, FechaNecesaria, CodigoArticulo, ' +
        'DescripcionArticulo, CodigoCliente) VALUES ', SbData, False);
      NData := 0;
      EjecutarMultifila('INSERT INTO FS_PL_OperatorAssignment (CodigoEmpresa, ' +
        'OperatorId, NodeId, Horas) VALUES ', SbAsig, False);
      NAsig := 0;
      EjecutarMultifila('INSERT INTO FS_PL_Dependency (CodigoEmpresa, ProjectId, ' +
        'FromNodeId, ToNodeId, TipoLink, PorcentajeDependencia) VALUES ', SbDep, False);
      NDep := 0;
    end;

  begin
    SbNode := TStringBuilder.Create;
    SbData := TStringBuilder.Create;
    SbAsig := TStringBuilder.Create;
    SbDep := TStringBuilder.Create;
    NNode := 0; NData := 0; NAsig := 0; NDep := 0;
    try
      for I := 0 to High(Ops) do
      begin
        AppendFilas(Ops[I], SbNode, SbData, SbAsig, SbDep, NNode, NData, NAsig, NDep);
        if (NNode >= FILAS_POR_INSERT) or (NData >= FILAS_POR_INSERT) or
           (NAsig >= FILAS_POR_INSERT) or (NDep >= FILAS_POR_INSERT) then
          FlushTodo;
      end;
      FlushTodo;   // resto
    finally
      SbNode.Free; SbData.Free; SbAsig.Free; SbDep.Free;
    end;
  end;

  // M3 (STAGING): carga a tablas #temp (sin FK/indices) y luego INSERT..SELECT
  // set-based a las tablas reales. SQL Server valida FK/indices en 1 operacion
  // de conjunto por tabla, no fila a fila -> mucho mas rapido que M2.
  procedure PersistirStaging;
  var
    SbNode, SbData, SbAsig, SbDep: TStringBuilder;
    NNode, NData, NAsig, NDep, I: Integer;

    // Ejecuta una sentencia que NO devuelve filas. eoExecuteNoRecords evita que
    // OLE DB intente determinar metadatos del resultset -> imprescindible cuando
    // la sentencia toca tablas #temp (si no: "no se pudieron determinar los
    // metadatos ... usa una tabla temporal"). SET NOCOUNT ON refuerza lo mismo.
    procedure ExecNoRec(const ASql: string);
    begin
      Cmd.CommandText := 'SET NOCOUNT ON; ' + ASql;
      Cmd.ExecuteOptions := [eoExecuteNoRecords];
      Cmd.Execute;
    end;

    // Vuelca un builder a una tabla #temp y limpia. Las #temp no tienen IDENTITY
    // ni FK, asi que el INSERT es directo y rapido.
    procedure FlushTmp(const ATabla: string; const ASb: TStringBuilder; var N: Integer);
    begin
      if ASb.Length = 0 then Exit;
      ExecNoRec('INSERT INTO ' + ATabla + ' VALUES ' + ASb.ToString.Substring(1));
      ASb.Clear;
      N := 0;
    end;

    procedure FlushTodoTmp;
    begin
      FlushTmp('#tmpNode', SbNode, NNode);
      FlushTmp('#tmpData', SbData, NData);
      FlushTmp('#tmpAsig', SbAsig, NAsig);
      FlushTmp('#tmpDep',  SbDep,  NDep);
    end;

    // Forward: LlenarBulkFile degrada a M4 (LlenarBulkADO) si el BULK INSERT
    // falla, pero LlenarBulkADO se declara mas abajo. La forward permite la
    // llamada anticipada (el cuerpo real esta al final).
    procedure LlenarBulkADO; forward;

    // M5: escribe las filas a ficheros CSV en disco y hace BULK INSERT. SQL
    // Server lee el fichero en streaming (sin overhead por fila) -> la via mas
    // rapida. Campos separados por '|', filas por CRLF, NULLs como campo vacio
    // (+ KEEPNULLS). Fechas ISO. El path debe ser legible por la cuenta de
    // servicio de SQL Server (por eso usamos el TEMP del sistema).
    procedure LlenarBulkFile;
    var
      Dir, FNode, FData, FAsig, FDep: string;
      WNode, WData, WAsig, WDep: TStreamWriter;
      K: Integer;
      O: TDemoOp;
      Enc: TEncoding;

      function DTf(const V: TDateTime): string;
      begin
        Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', V, TFormatSettings.Invariant);
      end;

      procedure BulkInsert(const ATabla, AFich: string);
      begin
        ExecNoRec(Format(
          'BULK INSERT %s FROM %s WITH (FIELDTERMINATOR = ''|'', ' +
          'ROWTERMINATOR = ''0x0d0a'', KEEPNULLS, TABLOCK, CODEPAGE = ''65001'');',
          [ATabla, QuotedStr(AFich)]));
      end;

    begin
      Dir := TPath.GetTempPath;
      FNode := TPath.Combine(Dir, Format('fsdemo_node_%d.csv', [AParams.ProjectId]));
      FData := TPath.Combine(Dir, Format('fsdemo_data_%d.csv', [AParams.ProjectId]));
      FAsig := TPath.Combine(Dir, Format('fsdemo_asig_%d.csv', [AParams.ProjectId]));
      FDep  := TPath.Combine(Dir, Format('fsdemo_dep_%d.csv',  [AParams.ProjectId]));

      // UTF-8. El StreamWriter escribe BOM, pero el BULK INSERT lo salta con
      // CODEPAGE='65001' (SQL Server 2016+). Enc es referencia compartida de
      // TEncoding.UTF8: NO liberar (es singleton del RTL).
      Enc := TEncoding.UTF8;
      WNode := TStreamWriter.Create(FNode, False, Enc);
      WData := TStreamWriter.Create(FData, False, Enc);
      WAsig := TStreamWriter.Create(FAsig, False, Enc);
      WDep  := TStreamWriter.Create(FDep,  False, Enc);
      try
        WNode.NewLine := #13#10; WData.NewLine := #13#10;
        WAsig.NewLine := #13#10; WDep.NewLine := #13#10;

        for K := 0 to High(Ops) do
        begin
          O := Ops[K];

          // #tmpNode: CodigoEmpresa|NodeId|ProjectId|CenterId|FechaInicio|FechaFin|
          //           DuracionMin|Caption|ColorFondo|ColorBorde
          WNode.Write(IntToStr(AParams.CodigoEmpresa)); WNode.Write('|');
          WNode.Write(IntToStr(O.NodeId)); WNode.Write('|');
          WNode.Write(IntToStr(AParams.ProjectId)); WNode.Write('|');
          if O.CenterId > 0 then WNode.Write(IntToStr(O.CenterId));
          WNode.Write('|');
          if O.Colocada then WNode.Write(DTf(O.Ini));
          WNode.Write('|');
          if O.Colocada then WNode.Write(DTf(O.Fin));
          WNode.Write('|');
          WNode.Write(FloatToStr(O.DurReal, Inv)); WNode.Write('|');
          WNode.Write(O.Operacion); WNode.Write('|');
          WNode.Write('15251072|11166760');
          WNode.WriteLine;

          // #tmpData
          WData.Write(IntToStr(AParams.CodigoEmpresa)); WData.Write('|');
          WData.Write(IntToStr(O.NodeId)); WData.Write('|');
          WData.Write(O.Operacion); WData.Write('|');
          WData.Write(IntToStr(O.NumOF)); WData.Write('|');
          WData.Write(IntToStr(O.NumPedido)); WData.Write('|');
          WData.Write(IntToStr(O.NumTrabajo)); WData.Write('|');
          WData.Write(FloatToStr(O.DurReal, Inv)); WData.Write('|');
          WData.Write(FloatToStr(O.DurOriginal, Inv)); WData.Write('|');
          WData.Write(IntToStr(O.UnidTotal)); WData.Write('|');
          WData.Write(IntToStr(O.UnidHechas)); WData.Write('|');
          WData.Write(IntToStr(O.NumOpsNec)); WData.Write('|');
          WData.Write(IntToStr(O.NumOpsAsig)); WData.Write('|');
          WData.Write('15251072|11166760|');
          WData.Write(IntToStr(O.Prioridad)); WData.Write('|');
          WData.Write(DTf(O.FechaEntrega)); WData.Write('|');
          WData.Write(DTf(O.FechaNecesaria)); WData.Write('|');
          WData.Write(ARTS[O.ArtIdx]); WData.Write('|');
          WData.Write(DESCS[O.ArtIdx]); WData.Write('|');
          WData.Write(CLIS[O.CliIdx]);
          WData.WriteLine;

          if O.OperatorId > 0 then
          begin
            WAsig.Write(IntToStr(AParams.CodigoEmpresa)); WAsig.Write('|');
            WAsig.Write(IntToStr(O.OperatorId)); WAsig.Write('|');
            WAsig.Write(IntToStr(O.NodeId)); WAsig.Write('|');
            WAsig.Write(FloatToStr(O.DurReal / 60, Inv));
            WAsig.WriteLine;
          end;

          if O.PredIdx >= 0 then
          begin
            WDep.Write(IntToStr(AParams.CodigoEmpresa)); WDep.Write('|');
            WDep.Write(IntToStr(AParams.ProjectId)); WDep.Write('|');
            WDep.Write(IntToStr(Ops[O.PredIdx].NodeId)); WDep.Write('|');
            WDep.Write(IntToStr(O.NodeId)); WDep.Write('|');
            WDep.Write('0|100');
            WDep.WriteLine;
          end;
        end;
      finally
        WNode.Free; WData.Free; WAsig.Free; WDep.Free;
        // Enc = TEncoding.UTF8 (singleton RTL): NO liberar.
      end;

      // BULK INSERT de cada fichero (streaming en el servidor). Los ficheros
      // vacios (p.ej. sin asignaciones) se saltan para no fallar.
      // Si falla (tipicamente: la cuenta de servicio SQL no puede leer el path),
      // damos un mensaje claro y sugerimos usar el motor M4 (bulk ADO). La
      // limpieza de ficheros va en finally para no dejar basura aunque falle.
      try
        try
          BulkInsert('#tmpNode', FNode);
          BulkInsert('#tmpData', FData);
          if TFile.Exists(FAsig) and (TFile.GetSize(FAsig) > 0) then
            BulkInsert('#tmpAsig', FAsig);
          if TFile.Exists(FDep) and (TFile.GetSize(FDep) > 0) then
            BulkInsert('#tmpDep', FDep);
        except
          on E: Exception do
          begin
            // Tipicamente: la cuenta de servicio de SQL Server no puede leer el
            // path (TEMP del usuario, o SQL en otro equipo donde ese path ni
            // existe). En vez de fallar, DEGRADAMOS a M4 (bulk ADO), que llena
            // las #temp con recordsets binarios via OLE DB y NO toca disco, asi
            // que no depende de la cuenta de servicio. Seguimos dentro de la
            // transaccion y antes del volcado, por lo que reintentar el llenado
            // es seguro; las #temp pueden traer filas a medias del BULK fallido,
            // asi que las vaciamos antes. Mismo fallback que uBulkNodePersist.
            PlanLog.Linea('  M5 BULK INSERT fallo (%s) -> degradando a M4 bulk ADO',
              [E.Message]);
            ExecNoRec(
              'DELETE FROM #tmpNode; DELETE FROM #tmpData; ' +
              'DELETE FROM #tmpAsig; DELETE FROM #tmpDep;');
            LlenarBulkADO;
          end;
        end;
      finally
        if TFile.Exists(FNode) then TFile.Delete(FNode);
        if TFile.Exists(FData) then TFile.Delete(FData);
        if TFile.Exists(FAsig) then TFile.Delete(FAsig);
        if TFile.Exists(FDep)  then TFile.Delete(FDep);
      end;
    end;

    // M4: rellena las #temp con RECORDSETS ADO en modo batch (AddNew +
    // UpdateBatch). ADO envia las filas en BINARIO via OLE DB, sin construir ni
    // parsear texto SQL -> elimina el cuello de botella de M2/M3 (~1500ms de
    // texto). Un recordset por #temp, abierto TableDirect sobre ESTA conexion.
    procedure LlenarBulkADO;
    var
      RsNode, RsData, RsAsig, RsDep: TADODataSet;
      K: Integer;
      O: TDemoOp;

      function NuevoRs(const ATabla: string): TADODataSet;
      begin
        Result := TADODataSet.Create(nil);
        Result.Connection := Cmd.Connection;   // misma conexion que las #temp
        Result.CommandType := cmdTableDirect;
        Result.CommandText := ATabla;
        Result.CursorLocation := clUseServer;   // servidor: batch va por TDS binario
        Result.CursorType := ctKeyset;
        Result.LockType := ltBatchOptimistic;   // acumula AddNew y envia en UpdateBatch
        Result.Open;
      end;

    begin
      RsNode := NuevoRs('#tmpNode');
      RsData := NuevoRs('#tmpData');
      RsAsig := NuevoRs('#tmpAsig');
      RsDep  := NuevoRs('#tmpDep');
      try
        for K := 0 to High(Ops) do
        begin
          O := Ops[K];

          RsNode.Append;
          RsNode.FieldByName('CodigoEmpresa').AsInteger := AParams.CodigoEmpresa;
          RsNode.FieldByName('NodeId').AsInteger := O.NodeId;
          RsNode.FieldByName('ProjectId').AsInteger := AParams.ProjectId;
          if O.CenterId <= 0 then RsNode.FieldByName('CenterId').Clear
          else RsNode.FieldByName('CenterId').AsInteger := O.CenterId;
          if O.Colocada then
          begin
            RsNode.FieldByName('FechaInicio').AsDateTime := O.Ini;
            RsNode.FieldByName('FechaFin').AsDateTime := O.Fin;
          end
          else
          begin
            RsNode.FieldByName('FechaInicio').Clear;
            RsNode.FieldByName('FechaFin').Clear;
          end;
          RsNode.FieldByName('DuracionMin').AsFloat := O.DurReal;
          RsNode.FieldByName('Caption').AsString := O.Operacion;
          RsNode.FieldByName('ColorFondo').AsInteger := 15251072;
          RsNode.FieldByName('ColorBorde').AsInteger := 11166760;
          RsNode.Post;

          RsData.Append;
          RsData.FieldByName('CodigoEmpresa').AsInteger := AParams.CodigoEmpresa;
          RsData.FieldByName('NodeId').AsInteger := O.NodeId;
          RsData.FieldByName('Operacion').AsString := O.Operacion;
          RsData.FieldByName('NumeroOF').AsInteger := O.NumOF;
          RsData.FieldByName('NumeroPedido').AsInteger := O.NumPedido;
          RsData.FieldByName('NumeroTrabajo').AsString := IntToStr(O.NumTrabajo);
          RsData.FieldByName('DuracionMin').AsFloat := O.DurReal;
          RsData.FieldByName('DuracionMinOriginal').AsFloat := O.DurOriginal;
          RsData.FieldByName('UnidadesAFabricar').AsFloat := O.UnidTotal;
          RsData.FieldByName('UnidadesFabricadas').AsFloat := O.UnidHechas;
          RsData.FieldByName('OperariosNecesarios').AsInteger := O.NumOpsNec;
          RsData.FieldByName('OperariosAsignados').AsInteger := O.NumOpsAsig;
          RsData.FieldByName('ColorFondoOp').AsInteger := 15251072;
          RsData.FieldByName('ColorBordeOp').AsInteger := 11166760;
          RsData.FieldByName('Prioridad').AsInteger := O.Prioridad;
          RsData.FieldByName('FechaEntrega').AsDateTime := O.FechaEntrega;
          RsData.FieldByName('FechaNecesaria').AsDateTime := O.FechaNecesaria;
          RsData.FieldByName('CodigoArticulo').AsString := ARTS[O.ArtIdx];
          RsData.FieldByName('DescripcionArticulo').AsString := DESCS[O.ArtIdx];
          RsData.FieldByName('CodigoCliente').AsString := CLIS[O.CliIdx];
          RsData.Post;

          if O.OperatorId > 0 then
          begin
            RsAsig.Append;
            RsAsig.FieldByName('CodigoEmpresa').AsInteger := AParams.CodigoEmpresa;
            RsAsig.FieldByName('OperatorId').AsInteger := O.OperatorId;
            RsAsig.FieldByName('NodeId').AsInteger := O.NodeId;
            RsAsig.FieldByName('Horas').AsFloat := O.DurReal / 60;
            RsAsig.Post;
          end;

          if O.PredIdx >= 0 then
          begin
            RsDep.Append;
            RsDep.FieldByName('CodigoEmpresa').AsInteger := AParams.CodigoEmpresa;
            RsDep.FieldByName('ProjectId').AsInteger := AParams.ProjectId;
            RsDep.FieldByName('FromNodeId').AsInteger := Ops[O.PredIdx].NodeId;
            RsDep.FieldByName('ToNodeId').AsInteger := O.NodeId;
            RsDep.FieldByName('TipoLink').AsInteger := 0;
            RsDep.FieldByName('PorcentajeDependencia').AsInteger := 100;
            RsDep.Post;
          end;
        end;

        // Envio en lote (binario) de todas las filas acumuladas.
        RsNode.UpdateBatch;
        RsData.UpdateBatch;
        RsAsig.UpdateBatch;
        RsDep.UpdateBatch;
      finally
        RsNode.Free; RsData.Free; RsAsig.Free; RsDep.Free;
      end;
    end;

  var
    TCrear, TLlenar, TVolcar: TDateTime;
  begin
    TCrear := Now;
    // 1) Crear las tablas #temp (viven en la sesion de ESTA conexion). Mismas
    //    columnas y orden que AppendFilas genera.
    ExecNoRec(
      'CREATE TABLE #tmpNode (CodigoEmpresa INT, NodeId INT, ProjectId INT, ' +
      '  CenterId INT NULL, FechaInicio DATETIME NULL, FechaFin DATETIME NULL, ' +
      '  DuracionMin DECIMAL(12,2), Caption NVARCHAR(255), ColorFondo INT, ColorBorde INT); ' +
      'CREATE TABLE #tmpData (CodigoEmpresa INT, NodeId INT, Operacion NVARCHAR(255), ' +
      '  NumeroOF INT, NumeroPedido INT, NumeroTrabajo NVARCHAR(50), DuracionMin DECIMAL(12,2), ' +
      '  DuracionMinOriginal DECIMAL(12,2), UnidadesAFabricar DECIMAL(14,4), ' +
      '  UnidadesFabricadas DECIMAL(14,4), OperariosNecesarios INT, OperariosAsignados INT, ColorFondoOp INT, ' +
      '  ColorBordeOp INT, Prioridad INT, FechaEntrega DATETIME, FechaNecesaria DATETIME, ' +
      '  CodigoArticulo NVARCHAR(255), DescripcionArticulo NVARCHAR(255), CodigoCliente NVARCHAR(255)); ' +
      'CREATE TABLE #tmpAsig (CodigoEmpresa INT, OperatorId INT, NodeId INT, Horas DECIMAL(12,4)); ' +
      'CREATE TABLE #tmpDep (CodigoEmpresa INT, ProjectId INT, FromNodeId INT, ToNodeId INT, ' +
      '  TipoLink INT, PorcentajeDependencia INT);');

    PlanLog.Linea('  crear #temp: %d ms', [MilliSecondsBetween(Now, TCrear)]);

    // 2) Rellenar las #temp segun el metodo.
    TLlenar := Now;
    if AParams.PersistMethod = pmBulkFile then
      LlenarBulkFile
    else if AParams.PersistMethod = pmBulkADO then
      LlenarBulkADO
    else
    begin
      SbNode := TStringBuilder.Create;
      SbData := TStringBuilder.Create;
      SbAsig := TStringBuilder.Create;
      SbDep := TStringBuilder.Create;
      NNode := 0; NData := 0; NAsig := 0; NDep := 0;
      try
        for I := 0 to High(Ops) do
        begin
          AppendFilas(Ops[I], SbNode, SbData, SbAsig, SbDep, NNode, NData, NAsig, NDep);
          if NNode >= FILAS_POR_INSERT then FlushTmp('#tmpNode', SbNode, NNode);
          if NData >= FILAS_POR_INSERT then FlushTmp('#tmpData', SbData, NData);
          if NAsig >= FILAS_POR_INSERT then FlushTmp('#tmpAsig', SbAsig, NAsig);
          if NDep  >= FILAS_POR_INSERT then FlushTmp('#tmpDep',  SbDep,  NDep);
        end;
        FlushTodoTmp;   // resto
      finally
        SbNode.Free; SbData.Free; SbAsig.Free; SbDep.Free;
      end;
    end;

    PlanLog.Linea('  llenar #temp (%s): %d ms',
      [NombreMetodo, MilliSecondsBetween(Now, TLlenar)]);

    // 3) Volcado set-based a las tablas reales (1 INSERT..SELECT por tabla).
    //    ORDEN FK: Node primero. Node necesita IDENTITY_INSERT.
    TVolcar := Now;
    ExecNoRec(
      'SET IDENTITY_INSERT FS_PL_Node ON; ' +
      'INSERT INTO FS_PL_Node (CodigoEmpresa, NodeId, ProjectId, CenterId, FechaInicio, ' +
      '  FechaFin, DuracionMin, Caption, ColorFondo, ColorBorde) ' +
      'SELECT CodigoEmpresa, NodeId, ProjectId, CenterId, FechaInicio, FechaFin, ' +
      '  DuracionMin, Caption, ColorFondo, ColorBorde FROM #tmpNode; ' +
      'SET IDENTITY_INSERT FS_PL_Node OFF;');

    ExecNoRec(
      'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, NumeroOF, NumeroPedido, ' +
      '  NumeroTrabajo, DuracionMin, DuracionMinOriginal, UnidadesAFabricar, UnidadesFabricadas, ' +
      '  OperariosNecesarios, OperariosAsignados, ColorFondoOp, ColorBordeOp, Prioridad, FechaEntrega, FechaNecesaria, ' +
      '  CodigoArticulo, DescripcionArticulo, CodigoCliente) ' +
      'SELECT CodigoEmpresa, NodeId, Operacion, NumeroOF, NumeroPedido, NumeroTrabajo, DuracionMin, ' +
      '  DuracionMinOriginal, UnidadesAFabricar, UnidadesFabricadas, OperariosNecesarios, OperariosAsignados, ColorFondoOp, ' +
      '  ColorBordeOp, Prioridad, FechaEntrega, FechaNecesaria, CodigoArticulo, DescripcionArticulo, ' +
      '  CodigoCliente FROM #tmpData;');

    ExecNoRec(
      'INSERT INTO FS_PL_OperatorAssignment (CodigoEmpresa, OperatorId, NodeId, Horas) ' +
      'SELECT CodigoEmpresa, OperatorId, NodeId, Horas FROM #tmpAsig;');

    ExecNoRec(
      'INSERT INTO FS_PL_Dependency (CodigoEmpresa, ProjectId, FromNodeId, ToNodeId, TipoLink, ' +
      '  PorcentajeDependencia) ' +
      'SELECT CodigoEmpresa, ProjectId, FromNodeId, ToNodeId, TipoLink, PorcentajeDependencia FROM #tmpDep;');

    PlanLog.Linea('  M3 volcado set-based (servidor): %d ms', [MilliSecondsBetween(Now, TVolcar)]);

    // 4) Limpiar las #temp (la conexion se reutiliza; no dejar basura de sesion).
    ExecNoRec('DROP TABLE #tmpNode, #tmpData, #tmpAsig, #tmpDep;');
  end;

  // Verificacion final: solapamientos por centro/lane (deberia ser 0).
  function ContarSolapamientos: Integer;
  var
    Cid, L, A, B: Integer;
    H: TCentroRT;
    S1, S2: TSlot;
    N: Integer;
  begin
    N := 0;
    for Cid in OccByCenter.Keys do
    begin
      H := OccByCenter[Cid];
      for L := 0 to High(H.Lanes) do
        for A := 0 to H.Lanes[L].Count - 1 do
          for B := A + 1 to H.Lanes[L].Count - 1 do
          begin
            S1 := H.Lanes[L][A]; S2 := H.Lanes[L][B];
            if (S1.Fin > S2.Ini) and (S1.Ini < S2.Fin) then Inc(N);
          end;
    end;
    Result := N;
  end;

  procedure LimpiarProyecto;
  begin
    Cmd.CommandText := 'DELETE FROM FS_PL_OperatorAssignment WHERE CodigoEmpresa = ' + CE +
      ' AND NodeId IN (SELECT NodeId FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
      ' AND ProjectId = ' + PID + ')';
    Cmd.Execute;
    Cmd.CommandText := 'DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa = ' + CE +
      ' AND ProjectId = ' + PID; Cmd.Execute;
    Cmd.CommandText := 'DELETE FROM FS_PL_NodeData WHERE CodigoEmpresa = ' + CE +
      ' AND NodeId IN (SELECT NodeId FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
      ' AND ProjectId = ' + PID + ')'; Cmd.Execute;
    Cmd.CommandText := 'DELETE FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
      ' AND ProjectId = ' + PID; Cmd.Execute;
  end;

var
  I: Integer;
begin
  Result := Default(TDemoGenResult);
  SW := Now;
  CE := IntToStr(AParams.CodigoEmpresa);
  PID := IntToStr(AParams.ProjectId);

  PlanLog.Inicio(Format('DEMO ENGINE PRO (%s)  -  proyecto %s: %d OF x %d OT x %d OP',
    [NombreMetodo, PID, AParams.NumOFs, AParams.OTsPorOF, AParams.OpsPorOT]));

  Randomize;
  Conn := TADOConnection.Create(nil);
  OccByCenter := TObjectDictionary<Integer, TCentroRT>.Create([doOwnsValues]);
  CentroInfoById := TDictionary<Integer, TCentreTreball>.Create;
  Cmd := TADOCommand.Create(nil);
  try
    Conn.LoginPrompt := False;
    Conn.ConnectionString := DMPlanner.ConnectionStringForThreads;
    Conn.Open;
    Cmd.Connection := Conn;

    // PASO 1: metadatos.
    LeerMetadatos;
    PlanLog.Linea('metadatos: %d centros reales, SinCentroId=%d, %d operarios, BaseId=%d',
      [Length(CentrosReales), SinCentroId, Length(OperatorIds), BaseId]);
    if (Length(CentrosReales) = 0) and (SinCentroId = 0) then
      raise Exception.Create('No hay centros de trabajo disponibles.');

    // PASO 2: generar en RAM.
    SWPart := Now;
    GenerarEnRAM;
    Result.TotalNodos := Length(Ops);
    Result.MillisGenerar := MilliSecondsBetween(Now, SWPart);

    // PASO 3+4: planificar en RAM (orden EDD + topologico + colision-aware).
    SWPart := Now;
    PlanificarEnRAM;
    Result.MillisPlanificar := MilliSecondsBetween(Now, SWPart);

    // Estadisticas de colocacion + verificacion.
    for I := 0 to High(Ops) do
      if Ops[I].Colocada then
      begin
        Inc(Result.TotalPlanificados);
        if Ops[I].CenterId = SinCentroId then Inc(Result.TotalSinCentro);
      end
      else
        Inc(Result.TotalPendientes);
    if AParams.GenerarDependencias then
      for I := 0 to High(Ops) do
        if Ops[I].PredIdx >= 0 then Inc(Result.TotalDependencias);
    Result.TotalSolapamientos := ContarSolapamientos;

    PlanLog.Linea('planificado: %d colocados (%d sin-centro), %d pendientes, ' +
      '%d deps, %d solapamientos | gen=%dms plan=%dms',
      [Result.TotalPlanificados, Result.TotalSinCentro, Result.TotalPendientes,
       Result.TotalDependencias, Result.TotalSolapamientos,
       Result.MillisGenerar, Result.MillisPlanificar]);

    // PASO 5: persistir (1 transaccion). M2 multifila o M3 staging set-based.
    SWPart := Now;
    Conn.BeginTrans;
    try
      if AParams.LimpiarAntes then LimpiarProyecto;
      // M3 (staging texto) y M4 (staging bulk ADO) comparten PersistirStaging
      // (solo cambia como se llenan las #temp); M2 usa multifila directa.
      if AParams.PersistMethod in [pmStaging, pmBulkADO, pmBulkFile] then
        PersistirStaging
      else
        PersistirMultifila;
      Conn.CommitTrans;
    except
      Conn.RollbackTrans;
      raise;
    end;
    Result.MillisPersistir := MilliSecondsBetween(Now, SWPart);

    // Utillajes demo: se ligan a las operaciones de OPERS, de modo que los
    // nodos recien creados heredan el requisito y la alerta R02 tiene algo
    // que detectar. Fuera de la transaccion de nodos a proposito: es un
    // extra, y un fallo aqui no debe tumbar la generacion del plan.
    // La propia funcion se autolimita al proyecto demo (EsDemo=1).
    GenerarUtillajesDemo(Conn, DMPlanner.CodigoEmpresa, AParams.ProjectId);

    Result.MillisTotal := MilliSecondsBetween(Now, SW);
    PlanLog.Linea('PERSISTIDO. persist=%dms | TOTAL=%dms para %d nodos',
      [Result.MillisPersistir, Result.MillisTotal, Result.TotalNodos]);
    if Result.TotalSolapamientos = 0 then
      PlanLog.Linea('--- VERIFICACION: 0 solapamientos. Plan limpio. ---')
    else
      PlanLog.Linea('--- VERIFICACION: %d SOLAPAMIENTOS (revisar). ---',
        [Result.TotalSolapamientos]);
    PlanLog.Fin;
  finally
    Cmd.Free;
    CentroInfoById.Free;
    OccByCenter.Free;   // doOwnsValues libera cada TCentroRT
    if Conn.Connected then Conn.Close;
    Conn.Free;
  end;
end;

end.
