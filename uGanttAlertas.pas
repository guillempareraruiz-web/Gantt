unit uGanttAlertas;
// Motor de deteccion de alertas del Gantt. Recorre los nodos visibles del
// control y produce una lista de TAlertaItem (categoria + severidad + contador
// + DataIds afectados). Separado de la UI para ser reutilizable/testeable.
//
// El detector NO conoce uVistaGantt: recibe el TGanttControl y el repositorio
// de NodeData via callback, para no acoplar capas.
interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults, System.DateUtils,
  uGanttTypes, uGanttControl, uCentreCalendar;

type
  // Severidad de la alerta (define color y orden de presentacion).
  TAlertaSeveridad = (asInfo, asAviso, asMedia, asAlta);

  // Clave estable de cada tipo de alerta (para iconos/orden/i18n). El codigo
  // legible (A01, R02...) se obtiene con CodigoDe(); es estable aunque cambie
  // el orden del enum.
  TAlertaTipo = (
    // --- IMPLEMENTADAS ---
    atActivoAntesHoy,        // nodo activo cuya fecha de inicio ya paso
    atFueraPlazoEntrega,     // termina despues de FechaEntrega
    atProximoEntrega,        // termina dentro del umbral de FechaEntrega
    atSinOperarios,          // necesita operarios y tiene 0 asignados
    atOperariosParciales,    // asignados < necesarios (y >0)
    atSinStock,              // stock < unidades a fabricar
    atCentroNoPermitido,     // colocado en un centro no permitido
    atSinFechaEntrega,       // sin FechaEntrega definida
    atZonaNoLaborable,       // cae integramente en zona no laborable
    atDuracionCero,          // duracion <=0 o sin unidades a fabricar
    atNoOptimizado,          // duracion actual peor que la original

    // --- PENDIENTES (roadmap): coherencia temporal y dependencias ---
    atSolapamientoSecuencial,// 2 nodos solapados en un centro secuencial
    atDependenciaViolada,    // predecesor termina despues de empezar el sucesor
    atSaltoExcesivoOF,       // demasiado tiempo muerto entre OT de la misma OF
    atMaterialNoDisponible,  // operacion antes de que llegue su materia prima

    // --- PENDIENTES: recursos (operarios / maquinas / utillaje) ---
    atOperarioSobrecargado,  // operario en 2 nodos solapados (doble booking)
    atOperarioSinCompetencia,// operario sin la competencia requerida
    atUtillajeEnConflicto,   // mismo molde/utillaje en 2 nodos a la vez
    atMaquinaNoOperativa,    // maquina en mantenimiento / no operativa
    atCuelloBotellaSobrecargado, // centro cuello de botella > umbral ocupacion

    // --- PENDIENTES: capacidad y plazos ---
    atDiaSobrecargado,       // carga del centro/dia supera su capacidad
    atMargenEntregaInsuf,    // slack negativo agregado de la cadena
    atOFEnRiesgo,            // alguna OT de la OF fuera de plazo

    // --- PENDIENTES: material y estado ---
    atStockParcial,          // cubre parte pero no todo
    atNodoBloqueado,         // nodo bloqueado aun planificado como activo
    atPrioridadTardia,       // prioridad alta planificada tras prioridad baja

    // --- PENDIENTES: integridad de datos / planificacion ---
    atSinCentro,             // sin centro asignado o centro inexistente
    atFueraPlanMaster,       // movido fuera de la ventana del plan MASTER
    atDuracionIncoherente,   // no cuadra unidades x tiempo/unidad
    atFueraHorizonte         // demasiado adelante/atras en el horizonte
  );

  // Tipos aun NO implementados: se listan en gris/desactivados para indicar que
  // estan en el roadmap. El detector no los evalua (Count siempre 0).
  TAlertaTiposPendientes = set of TAlertaTipo;

  TAlertaItem = record
    Tipo: TAlertaTipo;
    Codigo: string;          // codigo estable legible (A01, R02...)
    Severidad: TAlertaSeveridad;
    Titulo: string;          // texto a mostrar (sin el contador)
    DataIds: TArray<Integer>;// nodos afectados (para filtrar/resaltar)
    Implementada: Boolean;   // False = pendiente (se pinta desactivada)
    Peso: Integer;           // factor de importancia 1..100 (de FS_PL_AlertRule)
    function Count: Integer;
  end;

  // Devuelve el NodeData de un DataId. La implementa el caller (uVistaGantt
  // delega en DMPlanner.NodeDataRepo) para no acoplar el motor al data module.
  TNodeDataLookup = reference to function(const ADataId: Integer;
    out AData: TNodeData): Boolean;

  // Config de un tipo de alerta (de la tabla FS_PL_AlertRule). La implementa el
  // caller (delega en el repo) para no acoplar el motor a la BD.
  //   AActiva: si se evalua/muestra. APeso: 1..100. Result=False -> usar
  //   defaults (activa, peso por defecto del codigo).
  TAlertConfigLookup = reference to function(const ACodigo: string;
    out AActiva: Boolean; out APeso: Integer): Boolean;

const
  // Conjunto de tipos pendientes de implementar (roadmap).
  ALERTAS_PENDIENTES: TAlertaTiposPendientes = [
    atSolapamientoSecuencial, atDependenciaViolada, atSaltoExcesivoOF,
    atMaterialNoDisponible,
    atOperarioSobrecargado, atOperarioSinCompetencia, atUtillajeEnConflicto,
    atMaquinaNoOperativa, atCuelloBotellaSobrecargado,
    atDiaSobrecargado, atMargenEntregaInsuf, atOFEnRiesgo,
    atStockParcial, atNodoBloqueado, atPrioridadTardia,
    atSinCentro, atFueraPlanMaster, atDuracionIncoherente, atFueraHorizonte
  ];

  // Indice de salud del plan (0..100; 100 = sin incidencias). Pondera cada
  // alerta IMPLEMENTADA con incidencias por su peso: penalizacion = SUMA(Count *
  // Peso). Se normaliza con una saturacion suave relativa al numero de nodos
  // (ATotalNodos) para que sea comparable entre planes de distinto tamanyo.
  // ATotalNodos = nodos visibles considerados (>0). Si 0 -> 100.
  function CalcularSalud(const AAlertas: TArray<TAlertaItem>;
    const ATotalNodos: Integer): Integer;

  // Etiqueta legible del indice de salud (Excelente / Bueno / Regular / Malo /
  // Critico) segun el valor 0..100.
  function EtiquetaSalud(const ASalud: Integer): string;

  // --- Catalogo (para el seed de FS_PL_AlertRule y el form de config) ---
  // Codigo estable (A01, R02...) de un tipo.
  function CodigoDe(const ATipo: TAlertaTipo): string;
  // Titulo legible de un tipo.
  function TituloDe(const ATipo: TAlertaTipo): string;
  // Severidad base (color) de un tipo.
  function SeveridadDe(const ATipo: TAlertaTipo): TAlertaSeveridad;
  // Peso por defecto (1..100) de un tipo, usado como seed inicial.
  function PesoDefectoDe(const ATipo: TAlertaTipo): Integer;
  // True si el tipo aun NO esta implementado (roadmap).
  function EsPendiente(const ATipo: TAlertaTipo): Boolean;

  // Detecta todas las alertas del control. AHoraActual permite inyectar la
  // fecha (tests); por defecto el caller pasa Now. AProximoDias = umbral para
  // "proximo a fecha entrega".
  //   AIncluirCumplidas = False (defecto): solo devuelve los tipos IMPLEMENTADOS
  //     con Count > 0 (las incidencias reales). Los pendientes se anyaden SIEMPRE
  //     (como roadmap, desactivados).
  //   AIncluirCumplidas = True: devuelve TODOS los tipos implementados aunque
  //     Count = 0 (las que se cumplen, en verde) + los pendientes.
  //   AConfig (opcional): config por codigo (activa/peso). Si un tipo esta
  //     INACTIVO se omite del resultado; el peso se asigna a TAlertaItem.Peso.
  //     Si AConfig=nil o no conoce el codigo, el tipo se considera activo con
  //     su peso por defecto.
  // Ordenado por: implementadas con incidencias (peso desc), cumplidas, pendientes.
  function DetectarAlertas(AGantt: TGanttControl;
    const ALookup: TNodeDataLookup; const AHoraActual: TDateTime;
    const AProximoDias: Integer = 3;
    const AIncluirCumplidas: Boolean = False;
    const AConfig: TAlertConfigLookup = nil): TArray<TAlertaItem>;

implementation

{ TAlertaItem }

function TAlertaItem.Count: Integer;
begin
  Result := Length(DataIds);
end;

function CalcularSalud(const AAlertas: TArray<TAlertaItem>;
  const ATotalNodos: Integer): Integer;
var
  A: TAlertaItem;
  penal, baseMax: Double;
begin
  if ATotalNodos <= 0 then Exit(100);

  // Penalizacion = SUMA(nodos_afectados * peso) de las alertas con incidencias.
  penal := 0;
  for A in AAlertas do
    if A.Implementada and (A.Count > 0) then
      penal := penal + (A.Count * A.Peso);

  if penal <= 0 then Exit(100);

  // Saturacion suave: la referencia es "todos los nodos con una alerta de peso
  // medio (50)". A esa penalizacion le corresponde ~50 de salud; mas penalizacion
  // baja asintoticamente hacia 0, sin volverse negativa.
  baseMax := ATotalNodos * 50.0;
  Result := Round(100.0 * baseMax / (baseMax + penal));
  if Result < 0 then Result := 0;
  if Result > 100 then Result := 100;
end;

function EtiquetaSalud(const ASalud: Integer): string;
begin
  if ASalud >= 90 then Result := 'Excelente'
  else if ASalud >= 75 then Result := 'Bueno'
  else if ASalud >= 50 then Result := 'Regular'
  else if ASalud >= 25 then Result := 'Malo'
  else Result := 'Cr'#237'tico';
end;

// Codigo estable legible por tipo. Prefijo por familia: A=plazos/tiempo,
// O=operarios, M=material/stock, R=recursos, C=capacidad, D=datos.
function CodigoDe(const ATipo: TAlertaTipo): string;
begin
  case ATipo of
    atActivoAntesHoy:            Result := 'A01';
    atFueraPlazoEntrega:         Result := 'A02';
    atProximoEntrega:            Result := 'A03';
    atSinFechaEntrega:           Result := 'A04';
    atMargenEntregaInsuf:        Result := 'A05';
    atOFEnRiesgo:                Result := 'A06';
    atSinOperarios:              Result := 'O01';
    atOperariosParciales:        Result := 'O02';
    atOperarioSobrecargado:      Result := 'O03';
    atOperarioSinCompetencia:    Result := 'O04';
    atSinStock:                  Result := 'M01';
    atStockParcial:              Result := 'M02';
    atMaterialNoDisponible:      Result := 'M03';
    atCentroNoPermitido:         Result := 'R01';
    atUtillajeEnConflicto:       Result := 'R02';
    atMaquinaNoOperativa:        Result := 'R03';
    atSolapamientoSecuencial:    Result := 'R04';
    atZonaNoLaborable:           Result := 'C01';
    atDiaSobrecargado:           Result := 'C02';
    atCuelloBotellaSobrecargado: Result := 'C03';
    atDependenciaViolada:        Result := 'D01';
    atSaltoExcesivoOF:           Result := 'D02';
    atDuracionCero:              Result := 'D03';
    atDuracionIncoherente:       Result := 'D04';
    atNoOptimizado:              Result := 'D05';
    atNodoBloqueado:             Result := 'D06';
    atPrioridadTardia:           Result := 'D07';
    atSinCentro:                 Result := 'D08';
    atFueraPlanMaster:           Result := 'D09';
    atFueraHorizonte:            Result := 'D10';
  else
    Result := '';
  end;
end;

// Titulo legible por tipo (en castellano).
function TituloDe(const ATipo: TAlertaTipo): string;
begin
  case ATipo of
    atActivoAntesHoy:    Result := 'nodos activos antes de la fecha actual';
    atFueraPlazoEntrega: Result := 'nodos fuera de plazo de entrega';
    atProximoEntrega:    Result := 'nodos pr'#243'ximos a la fecha de entrega';
    atSinOperarios:      Result := 'nodos sin operarios asignados';
    atOperariosParciales:Result := 'nodos con operarios parciales';
    atSinStock:          Result := 'nodos sin stock suficiente';
    atCentroNoPermitido: Result := 'nodos en un centro no permitido';
    atSinFechaEntrega:   Result := 'nodos sin fecha de entrega definida';
    atZonaNoLaborable:   Result := 'nodos en zona no laborable';
    atDuracionCero:      Result := 'nodos con duraci'#243'n o cantidad nula';
    atNoOptimizado:      Result := 'nodos no optimizados (m'#225's largos de lo previsto)';
    // --- Pendientes ---
    atSolapamientoSecuencial:
                         Result := 'nodos solapados en centro secuencial';
    atDependenciaViolada:Result := 'dependencias entre nodos no respetadas';
    atSaltoExcesivoOF:   Result := 'saltos de tiempo excesivos entre operaciones de una OF';
    atMaterialNoDisponible:
                         Result := 'nodos planificados antes de tener material';
    atOperarioSobrecargado:
                         Result := 'operarios asignados a nodos solapados';
    atOperarioSinCompetencia:
                         Result := 'operarios sin la competencia requerida';
    atUtillajeEnConflicto:
                         Result := 'mismo utillaje/molde usado a la vez';
    atMaquinaNoOperativa:Result := 'nodos en m'#225'quina en mantenimiento o no operativa';
    atCuelloBotellaSobrecargado:
                         Result := 'centros cuello de botella sobrecargados';
    atDiaSobrecargado:   Result := 'd'#237'as con carga por encima de la capacidad';
    atMargenEntregaInsuf:Result := 'cadenas con margen de entrega insuficiente';
    atOFEnRiesgo:        Result := #211'rdenes de fabricaci'#243'n en riesgo de plazo';
    atStockParcial:      Result := 'nodos con stock parcial';
    atNodoBloqueado:     Result := 'nodos bloqueados a'#250'n planificados';
    atPrioridadTardia:   Result := 'nodos de prioridad alta planificados tarde';
    atSinCentro:         Result := 'nodos sin centro asignado o centro inv'#225'lido';
    atFueraPlanMaster:   Result := 'nodos fuera de la ventana del plan maestro';
    atDuracionIncoherente:
                         Result := 'nodos con duraci'#243'n incoherente';
    atFueraHorizonte:    Result := 'nodos fuera del horizonte de planificaci'#243'n';
  else
    Result := '';
  end;
end;

function SeveridadDe(const ATipo: TAlertaTipo): TAlertaSeveridad;
begin
  case ATipo of
    // Alta
    atActivoAntesHoy, atFueraPlazoEntrega, atCentroNoPermitido,
    atSolapamientoSecuencial, atDependenciaViolada, atOperarioSobrecargado,
    atUtillajeEnConflicto, atMaquinaNoOperativa, atMaterialNoDisponible,
    atOFEnRiesgo, atSinCentro, atMargenEntregaInsuf:
      Result := asAlta;
    // Media
    atSinOperarios, atSinStock, atZonaNoLaborable, atDiaSobrecargado,
    atCuelloBotellaSobrecargado, atNodoBloqueado, atOperarioSinCompetencia,
    atFueraPlanMaster, atDuracionIncoherente:
      Result := asMedia;
    // Aviso
    atOperariosParciales, atProximoEntrega, atDuracionCero, atNoOptimizado,
    atSaltoExcesivoOF, atStockParcial, atPrioridadTardia, atFueraHorizonte:
      Result := asAviso;
    // Info
    atSinFechaEntrega:
      Result := asInfo;
  else
    Result := asInfo;
  end;
end;

function EsPendiente(const ATipo: TAlertaTipo): Boolean;
begin
  Result := ATipo in ALERTAS_PENDIENTES;
end;

// Peso por defecto (1..100) usado como seed. Refleja el impacto tipico en el
// plan: plazos/colisiones de recurso pesan mas que avisos informativos.
function PesoDefectoDe(const ATipo: TAlertaTipo): Integer;
begin
  case ATipo of
    atFueraPlazoEntrega:         Result := 95;
    atActivoAntesHoy:            Result := 90;
    atDependenciaViolada:        Result := 88;
    atSolapamientoSecuencial:    Result := 85;
    atOperarioSobrecargado:      Result := 82;
    atOFEnRiesgo:                Result := 80;
    atMaterialNoDisponible:      Result := 78;
    atMaquinaNoOperativa:        Result := 75;
    atSinCentro:                 Result := 72;
    atMargenEntregaInsuf:        Result := 70;
    atUtillajeEnConflicto:       Result := 65;
    atCentroNoPermitido:         Result := 62;
    atSinOperarios:              Result := 60;
    atDiaSobrecargado:           Result := 58;
    atCuelloBotellaSobrecargado: Result := 55;
    atZonaNoLaborable:           Result := 52;
    atNodoBloqueado:             Result := 50;
    atSinStock:                  Result := 48;
    atOperarioSinCompetencia:    Result := 45;
    atPrioridadTardia:           Result := 42;
    atOperariosParciales:        Result := 40;
    atStockParcial:              Result := 38;
    atProximoEntrega:            Result := 35;
    atDuracionIncoherente:       Result := 32;
    atSaltoExcesivoOF:           Result := 30;
    atFueraPlanMaster:           Result := 28;
    atNoOptimizado:              Result := 25;
    atDuracionCero:              Result := 22;
    atFueraHorizonte:            Result := 18;
    atSinFechaEntrega:           Result := 15;
  else
    Result := 50;
  end;
end;

// True si el nodo esta colocado en un centro que NO le esta permitido.
function EnCentroNoPermitido(const N: TNode; const D: TNodeData): Boolean;
var
  Permitido: Boolean;
  Id: Integer;
begin
  // LibreMoviment = puede ir a cualquier centro; sin restriccion -> nunca alerta.
  if D.LibreMoviment then Exit(False);
  // Sin lista de permitidos = sin restriccion conocida -> no alertamos.
  if Length(D.CentresPermesos) = 0 then Exit(False);
  Permitido := False;
  for Id in D.CentresPermesos do
    if Id = N.CentreId then begin Permitido := True; Break; end;
  Result := not Permitido;
end;

function DetectarAlertas(AGantt: TGanttControl;
  const ALookup: TNodeDataLookup; const AHoraActual: TDateTime;
  const AProximoDias: Integer; const AIncluirCumplidas: Boolean;
  const AConfig: TAlertConfigLookup): TArray<TAlertaItem>;
var
  Listas: array[TAlertaTipo] of TList<Integer>;
  T: TAlertaTipo;
  I: Integer;
  N: TNode;
  D: TNodeData;
  Cal: TCentreCalendar;
  prog: Double;
  Res: TList<TAlertaItem>;
  It: TAlertaItem;

  // Config de un tipo: activa + peso (default si AConfig no lo conoce).
  function ConfigDe(const ATipo: TAlertaTipo; out APeso: Integer): Boolean;
  var
    activa: Boolean;
    peso: Integer;
  begin
    Result := True;                 // activa por defecto
    APeso := PesoDefectoDe(ATipo);
    if Assigned(AConfig) and AConfig(CodigoDe(ATipo), activa, peso) then
    begin
      Result := activa;
      if peso > 0 then APeso := peso;
    end;
  end;

  procedure Add(const ATipo: TAlertaTipo; const ADataId: Integer);
  begin
    Listas[ATipo].Add(ADataId);
  end;

begin
  for T := Low(TAlertaTipo) to High(TAlertaTipo) do
    Listas[T] := TList<Integer>.Create;
  try
    if (AGantt <> nil) and Assigned(ALookup) then
      for I := 0 to AGantt.NodeCount - 1 do
      begin
        N := AGantt.GetNodeAt(I);
        if not N.Visible then Continue;
        if (N.DataId = 0) or (not ALookup(N.DataId, D)) then Continue;

        // 1. Activo antes de hoy: empieza en el pasado y aun no finalizado.
        if (N.StartTime < AHoraActual) and (D.Estado <> neFinalizado) then
          Add(atActivoAntesHoy, N.DataId);

        // 2/3/8. Fecha de entrega.
        if D.FechaEntrega > 0 then
        begin
          if N.EndTime > D.FechaEntrega then
            Add(atFueraPlazoEntrega, N.DataId)
          else if (D.FechaEntrega - N.EndTime) <= AProximoDias then
            Add(atProximoEntrega, N.DataId);
        end
        else
          Add(atSinFechaEntrega, N.DataId);

        // 4/5. Operarios.
        if D.OperariosNecesarios > 0 then
        begin
          if D.OperariosAsignados <= 0 then
            Add(atSinOperarios, N.DataId)
          else if D.OperariosAsignados < D.OperariosNecesarios then
            Add(atOperariosParciales, N.DataId);
        end;

        // 6. Stock.
        if (D.UnidadesAFabricar > 0) and (D.Stock < D.UnidadesAFabricar) then
          Add(atSinStock, N.DataId);

        // 7. Centro no permitido.
        if EnCentroNoPermitido(N, D) then
          Add(atCentroNoPermitido, N.DataId);

        // 10. Zona no laborable: el nodo cae integramente en horario no
        //     laborable (festivo, fin de semana, fuera de turno).
        Cal := AGantt.GetCalendar(N.CentreId);
        if (Cal <> nil) and (N.EndTime > N.StartTime) then
          if Cal.WorkingMinutesBetween(N.StartTime, N.EndTime) < 1 then
            Add(atZonaNoLaborable, N.DataId);

        // 11. Duracion 0 / sin cantidad.
        prog := D.UnidadesAFabricar;
        if (N.DurationMin <= 0) or (prog <= 0) then
          Add(atDuracionCero, N.DataId);

        // 12. No optimizado: la duracion actual es PEOR (mayor) que la original.
        //     Tolerancia de 1 min para no marcar diferencias de redondeo.
        if (D.DurationMinOriginal > 0) and
           (N.DurationMin > D.DurationMinOriginal + 1) then
          Add(atNoOptimizado, N.DataId);
      end;

    // Construir el resultado.
    Res := TList<TAlertaItem>.Create;
    try
      for T := Low(TAlertaTipo) to High(TAlertaTipo) do
      begin
        // Tipos DESACTIVADOS por configuracion: no se listan (ni roadmap ni
        // cumplidas). ConfigDe ademas devuelve el peso a aplicar.
        var pesoT: Integer;
        if not ConfigDe(T, pesoT) then Continue;

        if T in ALERTAS_PENDIENTES then
        begin
          // Pendiente de implementar: siempre se lista (roadmap), desactivada.
          It := Default(TAlertaItem);
          It.Tipo := T;
          It.Codigo := CodigoDe(T);
          It.Severidad := SeveridadDe(T);
          It.Titulo := TituloDe(T);
          It.DataIds := nil;
          It.Implementada := False;
          It.Peso := pesoT;
          Res.Add(It);
        end
        else if (Listas[T].Count > 0) or AIncluirCumplidas then
        begin
          // Implementada: con incidencias siempre; sin incidencias solo si se
          // piden tambien las cumplidas ("Ver todas").
          It := Default(TAlertaItem);
          It.Tipo := T;
          It.Codigo := CodigoDe(T);
          It.Severidad := SeveridadDe(T);
          It.Titulo := TituloDe(T);
          It.DataIds := Listas[T].ToArray;
          It.Implementada := True;
          It.Peso := pesoT;
          Res.Add(It);
        end;
      end;
      // Orden: 1) implementadas con incidencias (por PESO desc), 2) implementadas
      // cumplidas (Count=0), 3) pendientes. Desempata por severidad y codigo.
      Res.Sort(TComparer<TAlertaItem>.Construct(
        function(const L, R: TAlertaItem): Integer
          function Grupo(const X: TAlertaItem): Integer;
          begin
            if not X.Implementada then Result := 2
            else if X.Count > 0 then Result := 0
            else Result := 1;
          end;
        begin
          Result := Grupo(L) - Grupo(R);
          if Result = 0 then
            Result := R.Peso - L.Peso;          // peso descendente
          if Result = 0 then
            Result := Ord(R.Severidad) - Ord(L.Severidad);
          if Result = 0 then
            Result := CompareStr(L.Codigo, R.Codigo);
        end));
      Result := Res.ToArray;
    finally
      Res.Free;
    end;
  finally
    for T := Low(TAlertaTipo) to High(TAlertaTipo) do
      Listas[T].Free;
  end;
end;

end.
