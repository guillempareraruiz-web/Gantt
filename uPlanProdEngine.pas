unit uPlanProdEngine;

{
  TPlanProdEngine - motor de planificacion automatica con scoring.

  Adaptado del prototipo FS_PlanProd al modelo del GANTT:
  - Iteracion por TNodeData (en lugar de TOperacionOrden).
  - Polivalencia via THabilidadRepo.
  - Coste laboral via campos del TOperario (SueldoEurHora + recargos).
  - Score combinado de 7 pesos configurables.

  Uso tipico:
    Engine := TPlanProdEngine.Create(NodeRepo, OpRepo, AbsRepo, HabRepo);
    try
      Engine.Pesos := PesosCustom;  // o usa default
      Resultado := Engine.PlanificarBatch(NodeIds, FechaInicio);
      // Resultado.Asignaciones - lista de (NodeId, OperarioId, Score, Coste)
      // Resultado.NodosNoAsignados - los que no han encontrado operario
    finally
      Engine.Free;
    end;

  El motor NO persiste nada: devuelve un plan candidato. La aplicacion debe
  decidir si lo aplica (TOperariosRepo.AddAsignacion) o lo descarta.
}

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Math,
  System.Generics.Collections,
  uGanttTypes, uNodeDataRepo, uOperariosTypes, uOperariosRepo,
  uOperatorAbsencesRepo, uHabilidadRepo, uOperationTypesRepo, uPlanProdTypes,
  uCentreCalendar;

type
  TFnEsFestivo = reference to function(const AFecha: TDateTime): Boolean;
  // Dado un DataId, devuelve los DataIds de sus predecesoras directas.
  // El motor lo usara para no asignar un nodo si alguna predecesora aun
  // no ha sido planificada en este batch.
  TFnGetPredecesores = reference to function(ADataId: Integer): TArray<Integer>;

  TPlanProdEngine = class
  private
    FNodeRepo: TNodeDataRepo;
    FOpRepo: TOperariosRepo;
    FAbsRepo: TOperatorAbsencesRepo;
    FHabRepo: THabilidadRepo;
    FOpTypesRepo: TOperationTypesRepo;  // opcional; si nil, max=1
    FPesos: TPesosPlanificacion;
    FEsFestivo: TFnEsFestivo;
    FGetPredecesores: TFnGetPredecesores;  // opcional
    FCalendarioFestivos: TCentreCalendar;  // opcional; si <> nil, sustituye
                                           // a la heuristica sabado/domingo

    // Carga jornada acumulada por operario en planificacion en curso
    FCargaSimulada: TDictionary<Integer, Double>;

    // Continuidad: por cada operario, lista de Nivel1ClaveERP a las que
    // ya ha sido asignado en el batch en curso. Sirve para bonificar
    // score si el siguiente nodo es del mismo grupo.
    FOpToOFs: TDictionary<Integer, TStringList>;

    function CargaOperario(OpId: Integer): Double;
    procedure SumarCarga(OpId: Integer; Horas: Double);
    function YaAsignadoAOF(OpId: Integer; const ClaveOF: string): Boolean;
    procedure RegistrarAsignacionOF(OpId: Integer; const ClaveOF: string);
    procedure ClearContinuidad;
    // Para H: bloquejar nodes amb predecessores no satisfets
    function PredecesorasSatisfechas(ADataId: Integer;
      ACountByNode: TDictionary<Integer, Integer>): Boolean;

    function CosteEfectivoEurHora(const Op: TOperario;
      const AFechaHora: TDateTime): Double;
    function CalcularCosteEstimado(const Op: TOperario;
      DurMin: Double; const AFechaHora: TDateTime): Double;
    function CalcularScore(const Op: TOperario; const Node: TNodeData;
      const AFechaHora: TDateTime): Double;
    function EsElegible(const Op: TOperario; const Node: TNodeData;
      const AFechaHora: TDateTime; out Motivo: string): Boolean;
  public
    constructor Create(ANodeRepo: TNodeDataRepo; AOpRepo: TOperariosRepo;
      AAbsRepo: TOperatorAbsencesRepo; AHabRepo: THabilidadRepo;
      AOpTypesRepo: TOperationTypesRepo = nil);
    destructor Destroy; override;

    // Planifica un nodo: devuelve mejor operario disponible (Elegible=False
    // si nadie cualifica)
    function MejorOperarioPara(const NodeData: TNodeData;
      const AFechaHora: TDateTime): TPlanProdAsignacion;

    // Variante que excluye operarios ya asignados al nodo (para multi-operario)
    function MejorOperarioParaExcluyendo(const NodeData: TNodeData;
      const AFechaHora: TDateTime;
      AExcluir: TList<Integer>): TPlanProdAsignacion;

    // Devuelve el desglose del score: cuanto aporta cada peso al total.
    // Util para que la UI explique "por que este operario obtiene X
    // puntos y no Y". Si Op no es elegible, devuelve un breakdown con
    // Total = 0 (no se calcula).
    function ExplicarScore(const Op: TOperario; const Node: TNodeData;
      const AFechaHora: TDateTime): TScoreBreakdown;

    // Planifica un batch de nodos. Asignacion greedy: en cada paso elige el
    // par (nodo, operario) con mayor score y lo asigna. Un operario puede
    // recibir varias asignaciones (suma carga); un nodo solo una asignacion
    // (de momento; el modelo multi-operario simultaneo es ampliacion futura).
    function PlanificarBatch(const NodeIds: TArray<Integer>;
      const AFechaHora: TDateTime): TPlanProdResultado;

    property Pesos: TPesosPlanificacion read FPesos write FPesos;
    property EsFestivo: TFnEsFestivo read FEsFestivo write FEsFestivo;
    property GetPredecesores: TFnGetPredecesores read FGetPredecesores
      write FGetPredecesores;
    property CalendarioFestivos: TCentreCalendar read FCalendarioFestivos
      write FCalendarioFestivos;
  end;

implementation

constructor TPlanProdEngine.Create(ANodeRepo: TNodeDataRepo;
  AOpRepo: TOperariosRepo; AAbsRepo: TOperatorAbsencesRepo;
  AHabRepo: THabilidadRepo; AOpTypesRepo: TOperationTypesRepo);
begin
  inherited Create;
  FNodeRepo := ANodeRepo;
  FOpRepo := AOpRepo;
  FAbsRepo := AAbsRepo;
  FHabRepo := AHabRepo;
  FOpTypesRepo := AOpTypesRepo;
  FPesos := TPesosPlanificacion.Default;
  FCargaSimulada := TDictionary<Integer, Double>.Create;
  FOpToOFs := TObjectDictionary<Integer, TStringList>.Create([doOwnsValues]);
  FEsFestivo :=
    function(const AFecha: TDateTime): Boolean
    begin
      // Si hay calendario configurado, usarlo (no laborable = festivo).
      // Si no, fallback heuristico: sabado/domingo.
      if Assigned(FCalendarioFestivos) then
        Result := FCalendarioFestivos.IsNonWorkingTime(AFecha)
      else
        Result := DayOfTheWeek(AFecha) in [6, 7];
    end;
end;

destructor TPlanProdEngine.Destroy;
begin
  FCargaSimulada.Free;
  FOpToOFs.Free;
  inherited;
end;

function TPlanProdEngine.CargaOperario(OpId: Integer): Double;
begin
  if not FCargaSimulada.TryGetValue(OpId, Result) then
    Result := 0;
end;

procedure TPlanProdEngine.SumarCarga(OpId: Integer; Horas: Double);
var
  Actual: Double;
begin
  Actual := CargaOperario(OpId);
  FCargaSimulada.AddOrSetValue(OpId, Actual + Horas);
end;

function TPlanProdEngine.YaAsignadoAOF(OpId: Integer;
  const ClaveOF: string): Boolean;
var
  Lst: TStringList;
begin
  Result := False;
  if ClaveOF = '' then Exit;
  if FOpToOFs.TryGetValue(OpId, Lst) then
    Result := Lst.IndexOf(ClaveOF) >= 0;
end;

procedure TPlanProdEngine.RegistrarAsignacionOF(OpId: Integer;
  const ClaveOF: string);
var
  Lst: TStringList;
begin
  if ClaveOF = '' then Exit;
  if not FOpToOFs.TryGetValue(OpId, Lst) then
  begin
    Lst := TStringList.Create;
    Lst.Sorted := True;
    Lst.Duplicates := dupIgnore;
    FOpToOFs.Add(OpId, Lst);
  end;
  Lst.Add(ClaveOF);
end;

procedure TPlanProdEngine.ClearContinuidad;
begin
  FOpToOFs.Clear;
end;

function TPlanProdEngine.PredecesorasSatisfechas(ADataId: Integer;
  ACountByNode: TDictionary<Integer, Integer>): Boolean;
var
  Preds: TArray<Integer>;
  I: Integer;
  PredCount: Integer;
  PredAsigs: TArray<TAsignacionOperario>;
begin
  Result := True;
  if not Assigned(FGetPredecesores) then Exit;
  Preds := FGetPredecesores(ADataId);
  for I := 0 to High(Preds) do
  begin
    // Una predecesora se considera "satisfecha" si:
    //   a) Ya tiene asignaciones en el repo (de batches anteriores), o
    //   b) Ha recibido al menos un operario en este batch.
    if ACountByNode.TryGetValue(Preds[I], PredCount) and (PredCount > 0) then
      Continue;
    if Assigned(FOpRepo) then
    begin
      PredAsigs := FOpRepo.GetAsignacionsByNode(Preds[I]);
      if Length(PredAsigs) > 0 then Continue;
    end;
    // No satisfecha
    Exit(False);
  end;
end;

function TPlanProdEngine.CosteEfectivoEurHora(const Op: TOperario;
  const AFechaHora: TDateTime): Double;
var
  Festivo: Boolean;
  Mult: Double;
begin
  Result := Op.SueldoEurHora;
  if Result <= 0 then Exit;  // sin sueldo definido: 0 (no penaliza)
  Festivo := FEsFestivo(AFechaHora);
  if Festivo then
  begin
    Mult := Op.RecargoFestivo;
    if Mult > 1 then Result := Result * Mult;
  end;
  // Recargo de noche: lo aplicariamos si TOperario tuviese turno.
  // Como el GANTT no liga turno al operario directamente (lo hereda del
  // centro), de momento no aplicamos nocturno. Hook futuro.
end;

function TPlanProdEngine.CalcularCosteEstimado(const Op: TOperario;
  DurMin: Double; const AFechaHora: TDateTime): Double;
var
  CosteHora: Double;
begin
  CosteHora := CosteEfectivoEurHora(Op, AFechaHora);
  Result := CosteHora * (DurMin / 60.0);
end;

function TPlanProdEngine.EsElegible(const Op: TOperario;
  const Node: TNodeData; const AFechaHora: TDateTime;
  out Motivo: string): Boolean;
var
  Motivo2: string;
begin
  Motivo := '';

  // Ausencia
  if Assigned(FAbsRepo) and FAbsRepo.IsAbsentAt(Op.Id, AFechaHora) then
  begin
    Motivo := Format('%s ausente', [Op.Nombre]);
    Exit(False);
  end;

  // Polivalencia: el operario debe tener todas las habilidades que exige la
  // operacion-maestro asociada al nodo.
  if (Node.Operacion <> '') and Assigned(FHabRepo) then
  begin
    if not FHabRepo.OperarioPuedeHacerOperacion(Op.Id, Node.Operacion, Motivo2)
    then
    begin
      Motivo := Format('%s: %s', [Op.Nombre, Motivo2]);
      Exit(False);
    end;
  end;

  Result := True;
end;

function TPlanProdEngine.CalcularScore(const Op: TOperario;
  const Node: TNodeData; const AFechaHora: TDateTime): Double;
var
  Sobrenivel, MinComp, MinEspera: Integer;
  FactorComp, Coste, Continuidad: Double;
begin
  // 1. Prioridad
  Result := FPesos.PesoPrioridadOrden * Node.Prioridad;

  // 2. Compromiso (deadline) - usa FechaEntrega del nodo
  if Node.FechaEntrega > 0 then
  begin
    MinComp := MinutesBetween(Node.FechaEntrega, AFechaHora);
    if Node.FechaEntrega < AFechaHora then FactorComp := 10
    else if MinComp < 60 then FactorComp := 8
    else if MinComp < 240 then FactorComp := 5
    else if MinComp < 1440 then FactorComp := 3
    else FactorComp := 1;
    Result := Result + FPesos.PesoCompromiso * FactorComp;
  end;

  // 3. Sobrequalificacion
  if Assigned(FHabRepo) and (Node.Operacion <> '') then
    Sobrenivel := FHabRepo.GetSobrenivel(Op.Id, Node.Operacion)
  else
    Sobrenivel := 0;
  Result := Result + FPesos.PesoNivelCompetencia / (1 + Sobrenivel);

  // 4. Carga operario (penaliza acumular)
  Result := Result - FPesos.PesoCargaOperario * CargaOperario(Op.Id);

  // 5. Continuidad: si ya tiene una asignacion al mismo grupo de la OF,
  // bonifica (mismo Nivel1ClaveERP). Tambien fallback con OrdenFabricacion
  // si Nivel1ClaveERP no esta poblado.
  Continuidad := 0;
  if YaAsignadoAOF(Op.Id, Node.Nivel1ClaveERP) then
    Continuidad := 1.0
  else if (Node.Nivel1ClaveERP = '') and (Node.NumeroOrdenFabricacion > 0) and
     YaAsignadoAOF(Op.Id, 'OF#' + IntToStr(Node.NumeroOrdenFabricacion)) then
    Continuidad := 1.0;
  Result := Result + FPesos.PesoContinuidad * Continuidad;

  // 6. Espera: cuanto mas viejo el nodo, mas urgente. Usamos FechaNecesaria
  // como proxy de fecha creacion si esta presente.
  if Node.FechaNecesaria > 0 then
  begin
    MinEspera := MinutesBetween(AFechaHora, Node.FechaNecesaria);
    if MinEspera < 0 then MinEspera := 0;
    Result := Result + FPesos.PesoEspera * MinEspera;
  end;

  // 7. Coste mano de obra
  Coste := CosteEfectivoEurHora(Op, AFechaHora);
  Result := Result - FPesos.PesoCosteManoObra * (Coste / 10.0);
end;

function TPlanProdEngine.MejorOperarioPara(const NodeData: TNodeData;
  const AFechaHora: TDateTime): TPlanProdAsignacion;
begin
  Result := MejorOperarioParaExcluyendo(NodeData, AFechaHora, nil);
end;

function TPlanProdEngine.ExplicarScore(const Op: TOperario;
  const Node: TNodeData; const AFechaHora: TDateTime): TScoreBreakdown;
var
  MinComp, MinEspera: Integer;
  FactorComp, Coste: Double;
  Continuidad: Double;
  HasCont: Boolean;
  ClaveOF: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.OperarioId := Op.Id;
  Result.OperarioNombre := Op.Nombre;
  Result.NodeDataId := Node.DataId;
  Result.Operacion := Node.Operacion;
  Result.PrioridadNode := Node.Prioridad;

  // 1. Prioridad
  Result.AportPrioridad := FPesos.PesoPrioridadOrden * Node.Prioridad;

  // 2. Compromiso
  if Node.FechaEntrega > 0 then
  begin
    MinComp := MinutesBetween(Node.FechaEntrega, AFechaHora);
    Result.DiasACompromiso := MinComp / (60 * 24);
    if Node.FechaEntrega < AFechaHora then FactorComp := 10
    else if MinComp < 60 then FactorComp := 8
    else if MinComp < 240 then FactorComp := 5
    else if MinComp < 1440 then FactorComp := 3
    else FactorComp := 1;
    Result.AportCompromiso := FPesos.PesoCompromiso * FactorComp;
  end;

  // 3. Sobrequalificacion
  if Assigned(FHabRepo) and (Node.Operacion <> '') then
    Result.Sobrenivel := FHabRepo.GetSobrenivel(Op.Id, Node.Operacion)
  else
    Result.Sobrenivel := 0;
  Result.AportNivelCompetencia := FPesos.PesoNivelCompetencia /
    (1 + Result.Sobrenivel);

  // 4. Carga
  Result.CargaActualOp := CargaOperario(Op.Id);
  Result.AportCarga := -FPesos.PesoCargaOperario * Result.CargaActualOp;

  // 5. Continuidad
  Continuidad := 0;
  HasCont := False;
  ClaveOF := Node.Nivel1ClaveERP;
  if (ClaveOF = '') and (Node.NumeroOrdenFabricacion > 0) then
    ClaveOF := 'OF#' + IntToStr(Node.NumeroOrdenFabricacion);
  if (ClaveOF <> '') and YaAsignadoAOF(Op.Id, ClaveOF) then
  begin
    Continuidad := 1.0;
    HasCont := True;
  end;
  Result.HasContinuidadOF := HasCont;
  Result.AportContinuidad := FPesos.PesoContinuidad * Continuidad;

  // 6. Espera
  if Node.FechaNecesaria > 0 then
  begin
    MinEspera := MinutesBetween(AFechaHora, Node.FechaNecesaria);
    if MinEspera < 0 then MinEspera := 0;
    Result.DiasEspera := MinEspera / (60 * 24);
    Result.AportEspera := FPesos.PesoEspera * MinEspera;
  end;

  // 7. Coste mano de obra
  Coste := CosteEfectivoEurHora(Op, AFechaHora);
  Result.CosteEurHora := Coste;
  Result.AportCoste := -FPesos.PesoCosteManoObra * (Coste / 10.0);

  Result.Total := Result.AportPrioridad + Result.AportCompromiso +
    Result.AportNivelCompetencia + Result.AportCarga +
    Result.AportContinuidad + Result.AportEspera + Result.AportCoste;
end;

function TPlanProdEngine.MejorOperarioParaExcluyendo(const NodeData: TNodeData;
  const AFechaHora: TDateTime; AExcluir: TList<Integer>): TPlanProdAsignacion;
var
  Operarios: TArray<TOperario>;
  I: Integer;
  Op: TOperario;
  Score, MejorScore: Double;
  Motivo: string;
  Encontrado: Boolean;
  DurMin: Double;
begin
  Result := TPlanProdAsignacion.Vacio;
  Result.NodeDataId := NodeData.DataId;
  Result.Operacion := NodeData.Operacion;

  if not Assigned(FOpRepo) then
  begin
    Result.MotivoNoElegible := 'Sin repositorio de operarios';
    Exit;
  end;

  Operarios := FOpRepo.GetOperarios;
  MejorScore := -MaxDouble;
  Encontrado := False;

  for I := 0 to High(Operarios) do
  begin
    Op := Operarios[I];

    // Excluir operarios ya asignados al nodo
    if Assigned(AExcluir) and (AExcluir.IndexOf(Op.Id) >= 0) then Continue;

    if not EsElegible(Op, NodeData, AFechaHora, Motivo) then Continue;

    Score := CalcularScore(Op, NodeData, AFechaHora);
    if Score > MejorScore then
    begin
      MejorScore := Score;
      Result.OperarioId := Op.Id;
      Result.Score := Score;
      Result.HoraInicioPrevista := AFechaHora;
      // Duracion estimada (sin paralelismo aplicado aqui; el batch lo
      // recalculara una vez sepa cuantos operarios totales son).
      DurMin := NodeData.DurationMin;
      Result.HoraFinPrevista := IncMinute(AFechaHora, Round(DurMin));
      Result.CosteEstimado := CalcularCosteEstimado(Op, DurMin, AFechaHora);
      Result.Elegible := True;
      Encontrado := True;
    end;
  end;

  if not Encontrado then
    Result.MotivoNoElegible := 'Ningun operario cualifica para ' +
      NodeData.Operacion;
end;

function TPlanProdEngine.PlanificarBatch(const NodeIds: TArray<Integer>;
  const AFechaHora: TDateTime): TPlanProdResultado;
var
  Pendientes: TList<Integer>;
  Asigs: TList<TPlanProdAsignacion>;
  NoAsig: TList<Integer>;
  // Operarios ya asignados a cada nodo (DataId -> set de OperarioIds)
  OpsAsignadosPorNode: TDictionary<Integer, TList<Integer>>;
  CountOpsByNode: TDictionary<Integer, Integer>;
  I, K, IdxMejor: Integer;
  Node: TNodeData;
  Cand, Mejor: TPlanProdAsignacion;
  MejorScore: Double;
  CosteAcc, ScoreAcc: Double;
  DurHoras: Double;
  TipoOp: TTipoOperacion;
  MaxOpsNode, AsigsActuales: Integer;
  OpsLista: TList<Integer>;
  AlMenosUno: Boolean;
begin
  FCargaSimulada.Clear;
  ClearContinuidad;

  // Sembrar continuidad con asignaciones existentes en el repo (de planificaciones
  // anteriores). Asi un operario que ya tiene trabajo en una OF se prefiere para
  // mas operaciones de la misma OF.
  if Assigned(FOpRepo) then
  begin
    var AllOps := FOpRepo.GetOperarios;
    for var P := 0 to High(AllOps) do
    begin
      var Asigs0 := FOpRepo.GetAsignacionsByOperario(AllOps[P].Id);
      for var Q := 0 to High(Asigs0) do
      begin
        var ND: TNodeData;
        if FNodeRepo.TryGetById(Asigs0[Q].DataId, ND) then
        begin
          if ND.Nivel1ClaveERP <> '' then
            RegistrarAsignacionOF(AllOps[P].Id, ND.Nivel1ClaveERP)
          else if ND.NumeroOrdenFabricacion > 0 then
            RegistrarAsignacionOF(AllOps[P].Id,
              'OF#' + IntToStr(ND.NumeroOrdenFabricacion));
        end;
      end;
    end;
  end;

  Pendientes := TList<Integer>.Create;
  Asigs := TList<TPlanProdAsignacion>.Create;
  NoAsig := TList<Integer>.Create;
  OpsAsignadosPorNode := TObjectDictionary<Integer, TList<Integer>>.Create([doOwnsValues]);
  CountOpsByNode := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to High(NodeIds) do
      Pendientes.Add(NodeIds[I]);

    // Greedy multi-operario:
    //   - Cada nodo puede recibir hasta MaxOperariosParalelos operarios.
    //   - En cada paso encuentra (nodo, operario) con mejor score.
    //   - Cuando un nodo llega al max, se elimina de pendientes.
    //   - Un mismo operario no se asigna 2x al mismo nodo.
    while Pendientes.Count > 0 do
    begin
      MejorScore := -MaxDouble;
      IdxMejor := -1;
      Mejor := TPlanProdAsignacion.Vacio;

      for K := 0 to Pendientes.Count - 1 do
      begin
        if not FNodeRepo.TryGetById(Pendientes[K], Node) then Continue;

        // Bloquear nodos cuyas predecesoras aun no estan planificadas
        if not PredecesorasSatisfechas(Pendientes[K], CountOpsByNode) then
          Continue;

        // Operarios ya asignados a este nodo (excluir del candidato)
        if not OpsAsignadosPorNode.TryGetValue(Pendientes[K], OpsLista) then
          OpsLista := nil;

        Cand := MejorOperarioParaExcluyendo(Node, AFechaHora, OpsLista);
        if Cand.Elegible and (Cand.Score > MejorScore) then
        begin
          MejorScore := Cand.Score;
          IdxMejor := K;
          Mejor := Cand;
        end;
      end;

      if IdxMejor < 0 then
      begin
        // No hay mas candidatos validos para nodos pendientes.
        // Los que NO han recibido NINGUN operario van a "no asignados".
        for K := 0 to Pendientes.Count - 1 do
        begin
          AlMenosUno := CountOpsByNode.ContainsKey(Pendientes[K]) and
            (CountOpsByNode[Pendientes[K]] > 0);
          if not AlMenosUno then
            NoAsig.Add(Pendientes[K]);
        end;
        Break;
      end;

      // Aceptar la mejor y actualizar carga
      Asigs.Add(Mejor);
      DurHoras := 0;
      if FNodeRepo.TryGetById(Mejor.NodeDataId, Node) then
        DurHoras := Node.DurationMin / 60.0;
      SumarCarga(Mejor.OperarioId, DurHoras);

      // Registrar continuidad (operario -> grupo OF)
      if Node.Nivel1ClaveERP <> '' then
        RegistrarAsignacionOF(Mejor.OperarioId, Node.Nivel1ClaveERP)
      else if Node.NumeroOrdenFabricacion > 0 then
        RegistrarAsignacionOF(Mejor.OperarioId,
          'OF#' + IntToStr(Node.NumeroOrdenFabricacion));

      // Registrar operario asignado a este nodo
      if not OpsAsignadosPorNode.TryGetValue(Mejor.NodeDataId, OpsLista) then
      begin
        OpsLista := TList<Integer>.Create;
        OpsAsignadosPorNode.Add(Mejor.NodeDataId, OpsLista);
      end;
      OpsLista.Add(Mejor.OperarioId);
      if CountOpsByNode.ContainsKey(Mejor.NodeDataId) then
        CountOpsByNode[Mejor.NodeDataId] := CountOpsByNode[Mejor.NodeDataId] + 1
      else
        CountOpsByNode.Add(Mejor.NodeDataId, 1);

      // Determinar cuantos operarios asignar al nodo.
      // Prioridad: OperariosNecesarios del nodo (requisito concreto de la OP,
      // viene del ERP). Si no esta definido (<=0), caer al MaxOperariosParalelos
      // del tipo de operacion (politica generica) o 1.
      // El MaxOperariosParalelos del tipo actua ademas como techo tecnico:
      // si el tipo declara un maximo explicito menor que el objetivo, limita
      // (ej: una operacion de 1 sola maquina no admite 2 operarios en paralelo).
      // OJO: el techo del tipo solo se aplica si el tipo esta REGISTRADO en
      // FS_PL_OperationType. Un tipo no configurado devuelve Max=1 por defecto,
      // pero ese 1 significa "sin configurar", no "techo real de 1"; aplicarlo
      // anularia el requisito del nodo (volveria a 1 operario).
      MaxOpsNode := Max(1, Node.OperariosNecesarios);
      if Assigned(FOpTypesRepo) and (Node.Operacion <> '')
         and FOpTypesRepo.Exists(Node.Operacion) then
      begin
        TipoOp := FOpTypesRepo.GetOrDefault(Node.Operacion);
        if Node.OperariosNecesarios <= 0 then
          MaxOpsNode := Max(1, TipoOp.MaxOperariosParalelos)
        else if (TipoOp.MaxOperariosParalelos > 0) and
                (TipoOp.MaxOperariosParalelos < MaxOpsNode) then
          MaxOpsNode := TipoOp.MaxOperariosParalelos;
      end;
      AsigsActuales := CountOpsByNode[Mejor.NodeDataId];

      // Si el nodo ya llego a max, quitarlo de pendientes
      if AsigsActuales >= MaxOpsNode then
        Pendientes.Delete(IdxMejor);
      // Si no, lo dejamos para recibir mas operarios.
    end;

    // Post-procesado: ajustar duracion y coste segun paralelismo.
    // Si un nodo tiene N operarios y el tipo de operacion lo permite, la
    // duracion efectiva baja (1 + (N-1)*Factor). El coste de cada operario
    // se recalcula con la duracion efectiva.
    if Assigned(FOpTypesRepo) then
    begin
      for I := 0 to Asigs.Count - 1 do
      begin
        var A := Asigs[I];
        if not FNodeRepo.TryGetById(A.NodeDataId, Node) then Continue;
        if Node.Operacion = '' then Continue;
        var NumOps: Integer;
        if not CountOpsByNode.TryGetValue(A.NodeDataId, NumOps) then NumOps := 1;

        // Construir array de FactorEficiencia para todos los operarios
        // asignados a este nodo (incluido A.OperarioId).
        var Factores: TArray<Double>;
        if (NumOps > 1) or Assigned(FHabRepo) then
        begin
          var OpsListaAux: TList<Integer>;
          if OpsAsignadosPorNode.TryGetValue(A.NodeDataId, OpsListaAux) then
          begin
            SetLength(Factores, OpsListaAux.Count);
            for var KK := 0 to OpsListaAux.Count - 1 do
            begin
              if Assigned(FHabRepo) then
                Factores[KK] := FHabRepo.GetFactorEficienciaPara(
                  OpsListaAux[KK], Node.Operacion)
              else
                Factores[KK] := 1.0;
            end;
          end;
        end;

        // Si solo hay 1 operario y su factor es 1.0, no toca nada
        if (NumOps <= 1) and
           ((Length(Factores) = 0) or (Abs(Factores[0] - 1.0) < 0.001)) then
          Continue;

        var DurEfectivaH: Double;
        if Length(Factores) > 0 then
          DurEfectivaH := FOpTypesRepo.DuracionEfectivaHoras(Node.Operacion,
            Node.DurationMin / 60.0, Factores)
        else
          DurEfectivaH := FOpTypesRepo.DuracionEfectivaHoras(Node.Operacion,
            Node.DurationMin / 60.0, NumOps);

        var DurEfectivaMin := DurEfectivaH * 60;
        A.HoraFinPrevista := IncMinute(A.HoraInicioPrevista,
          Round(DurEfectivaMin));
        var Op: TOperario;
        if FOpRepo.GetOperarioById(A.OperarioId, Op) then
          A.CosteEstimado := CalcularCosteEstimado(Op, DurEfectivaMin,
            A.HoraInicioPrevista);
        Asigs[I] := A;
      end;
    end;

    // Totales
    CosteAcc := 0;
    ScoreAcc := 0;
    for I := 0 to Asigs.Count - 1 do
    begin
      CosteAcc := CosteAcc + Asigs[I].CosteEstimado;
      ScoreAcc := ScoreAcc + Asigs[I].Score;
    end;

    Result.Asignaciones := Asigs.ToArray;
    Result.NodosNoAsignados := NoAsig.ToArray;
    Result.CosteTotal := CosteAcc;
    Result.ScoreTotal := ScoreAcc;
  finally
    OpsAsignadosPorNode.Free;
    CountOpsByNode.Free;
    Pendientes.Free;
    Asigs.Free;
    NoAsig.Free;
  end;
end;

end.
