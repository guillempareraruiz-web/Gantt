unit uWbsRepo;

// Repositorio de lectura del arbol WBS (Modulo de Proyectos, paradigma TAREAS).
// Lee las tareas (FS_PL_Node con atributos WBS de V078) y las dependencias
// (FS_PL_Dependency) de un proyecto, y devuelve las tareas YA ORDENADAS en
// recorrido de arbol (padre antes que hijos, hermanos por OrdenWBS), con Nivel
// y HasChildren calculados. Esa lista plana ordenada es directamente la entrada
// del grid WBS y del control de Gantt de tareas.
//
// Escritura: Save* para los campos que el usuario edita a mano (tiempo
// invertido, duracion, fechas). Deliberadamente son updates de UNA columna: el
// resto del calculo (holguras, criticidad, avance de los resumenes) es VOLATIL
// y se recalcula, no se persiste.
//
// Edicion estructural de la WBS (F3): InsertTarea / DeleteTarea /
// MoverTarea / RenombrarTarea, mas ReordenarHermanos. Aqui viven las reglas
// que la vista NO debe conocer: como se numera OrdenWBS, que un padre pasa a
// ser RESUMEN al ganar su primer hijo (y deja de serlo al perder el ultimo), y
// que borrar arrastra el subarbol entero con sus dependencias.

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Math,
  System.Generics.Collections, System.Generics.Defaults,
  Data.Win.ADODB,
  uWbsTypes;

const
  // "Al final de sus hermanos", para InsertTarea / MoverTarea. Es un CENTINELA,
  // no una posicion: el repo lo traduce a MAX(OrdenWBS)+1 del grupo destino.
  // Guardarlo tal cual en OrdenWBS (como se hacia con MaxInt-1) reventaba a la
  // segunda insercion, porque el "hacer sitio" hace OrdenWBS + 1 sobre un INT.
  ORDEN_ULTIMO = -1;

type
  TWbsRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    // Ordena recursivamente: mete AParentId y sus descendientes en AOut.
    procedure AppendSubtree(const AByParent: TDictionary<Integer, TList<TWbsTask>>;
      AParentId, ANivel: Integer; var AOut: TList<TWbsTask>);
    // Traduce ORDEN_ULTIMO (y cualquier valor negativo) a la posicion siguiente
    // a la del ultimo hermano. Asi el llamante puede decir "al final" sin
    // conocer cuantos hermanos hay ni inventarse un numero grande.
    function ResolverOrden(AProjectId, AParentTaskId, AOrden: Integer): Integer;
  public
    constructor Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt);

    // Tareas del proyecto, en orden de arbol (raiz->hojas, hermanos por Orden).
    function LoadTareas(AProjectId: Integer): TWbsTaskArray;
    // Dependencias del proyecto.
    function LoadLinks(AProjectId: Integer): TWbsLinkArray;

    // Proyectos con paradigma TAREAS, para el selector multi-proyecto.
    function LoadProyectosTareas: TWbsProyectoArray;

    // --- ESCRITURA -----------------------------------------------------------
    // Tiempo real invertido en una tarea (V079). El % de avance NO se guarda:
    // es un derivado de MinutosInvertidos / DuracionMin.
    procedure SaveMinutosInvertidos(ANodeId: Integer; AMinutos: Double);
    // Fechas recalculadas por el motor. Se persisten solo cuando el usuario
    // acepta un cambio: el resto del calculo (holguras, criticidad) es volatil.
    procedure SaveFechas(ANodeId: Integer; const AInicio, AFin: TDateTime);
    // Duracion estimada en minutos.
    procedure SaveDuracion(ANodeId: Integer; AMinutos: Double);
    // Tipo de tarea (0 tarea / 1 resumen / 2 hito).
    procedure SaveTaskKind(ANodeId: Integer; AKind: Integer);

    // --- Ficha ampliada de la tarea (V080) -----------------------------------
    // Devuelve False si la tarea aun no tiene ficha (es opcional); en ese caso
    // ADetail queda con los valores por defecto.
    function LoadDetail(ANodeId: Integer; out ADetail: TWbsTaskDetail): Boolean;
    procedure SaveDetail(const ADetail: TWbsTaskDetail);

    // Operarios asignados a la tarea.
    function LoadOperarios(ANodeId: Integer): TWbsTaskOperarioArray;
    // ARecuadrarTriada: si el llamante YA ha resuelto la ecuacion de esfuerzo
    // (la ficha lo hace al aceptar, con las unidades finales), hay que pasar
    // False o este metodo recalcularia el trabajo a partir de la duracion y
    // SOBREESCRIBIRIA lo que el usuario acaba de teclear. True es para los
    // caminos que solo cambian la asignacion y esperan que el esfuerzo se
    // recuadre solo.
    procedure SaveOperarios(ANodeId: Integer;
      const AOperarios: TWbsTaskOperarioArray;
      ARecuadrarTriada: Boolean = True);

    // Fecha fija: editar Inicio a mano equivale a poner una restriccion, para
    // que el motor la respete en vez de recalcularla por dependencias.
    procedure SaveRestriccionFecha(ANodeId: Integer; AKind: Integer;
      const AFecha: TDateTime);

    // --- Triada de esfuerzo (V082) -------------------------------------------
    // Guarda las tres magnitudes de golpe: van juntas porque solo tienen
    // sentido cuadradas entre si (ver RecalcularTriada en uWbsTypes). Las
    // unidades NO se persisten aqui: salen de FS_PL_TaskOperario.
    procedure SaveEsfuerzo(ANodeId: Integer; ADuracionMin, ATrabajoMin: Double;
      ATipoTarea: Integer);
    procedure SaveTipoTarea(ANodeId: Integer; ATipoTarea: Integer);

    // --- Linea base (V082) ---------------------------------------------------
    // Congela el plan actual del proyecto. Reemplaza la linea base ABaselineId
    // si ya existia (fijarla otra vez es rehacer la foto, no acumular).
    // Devuelve cuantas tareas se han fotografiado.
    function FijarBaseline(AProjectId: Integer; const ANombre: string;
      AUserId: Integer; ABaselineId: Integer = 0): Integer;
    procedure BorrarBaseline(AProjectId: Integer; ABaselineId: Integer = 0);
    // Cabeceras de las lineas base del proyecto (para el selector).
    function LoadBaselines(AProjectId: Integer): TWbsBaselineArray;
    // Desviacion de cada tarea contra la linea base principal. Clave = NodeId.
    // El llamante libera el diccionario.
    function LoadDesvios(AProjectId: Integer): TDictionary<Integer, TWbsDesvio>;

    // --- Edicion estructural de la WBS (F3) ---------------------------------
    // Alta de una tarea. AParentTaskId = 0 la cuelga de la raiz del proyecto.
    // AOrdenWBS decide donde entra entre sus hermanos: los que van detras se
    // desplazan. Pasar ORDEN_ULTIMO la deja al final. Devuelve el NodeId nuevo
    // (0 si no se pudo crear).
    // Si el padre era una tarea normal, pasa automaticamente a RESUMEN.
    function InsertTarea(AProjectId, AParentTaskId, AOrdenWBS: Integer;
      const ACaption: string; AKind: Integer;
      ADuracionMin: Double): Integer;
    // Baja de una tarea Y DE TODO SU SUBARBOL, con sus dependencias, ficha,
    // operarios y etiquetas. Devuelve cuantas tareas se han borrado.
    function DeleteTarea(ANodeId: Integer): Integer;
    // Cambia el padre y/o la posicion de una tarea (indentar, desindentar,
    // subir, bajar). El subarbol la sigue. Devuelve False si el movimiento es
    // imposible (mover una tarea dentro de si misma o de un descendiente).
    function MoverTarea(ANodeId, ANuevoParentId, ANuevoOrden: Integer): Boolean;
    procedure RenombrarTarea(ANodeId: Integer; const ACaption: string);
    // Renumera 0..N-1 los hijos de AParentTaskId (0 = raices del proyecto),
    // respetando el orden actual. Deja hueco limpio para insertar.
    procedure ReordenarHermanos(AProjectId, AParentTaskId: Integer);

    // --- Dependencias -------------------------------------------------------
    // Alta de un vinculo entre dos tareas. No inserta si ya existe.
    procedure AddDependencia(AProjectId, AFromNodeId, AToNodeId,
      ATipoLink: Integer; ALagMinutos: Integer = 0);
    procedure DeleteDependencia(ADependencyId: Integer);

    // Carga de trabajo por operario y dia, para la banda de resumen inferior.
    // Devuelve una fila por (operario, tarea) con sus fechas y dedicacion; el
    // reparto por dias lo hace la vista, que ya tiene el calendario laborable.
    function LoadCargaOperarios(AProjectIds: TArray<Integer>): TWbsCargaArray;

    // --- Etiquetas estilo Trello (V081) --------------------------------------
    // Catalogo completo de la empresa. Si ANodeId > 0, marca en Asignada las
    // que lleve esa tarea (asi el dialogo pinta los chips en un solo viaje).
    function LoadTags(ANodeId: Integer = 0): TWbsTagArray;
    // Reemplaza las etiquetas de la tarea por las que vengan marcadas.
    procedure SaveTagsDeTarea(ANodeId: Integer; const ATags: TWbsTagArray);
    // TagIds por NodeId, para pintar los badges del Gantt sin una consulta
    // por tarea.
    function LoadTagsPorNodo(AProjectId: Integer):
      TDictionary<Integer, TArray<Integer>>;
    // Alta/edicion del catalogo. Devuelve el TagId (nuevo o el existente).
    function SaveTag(const ATag: TWbsTag): Integer;
    procedure DeleteTag(ATagId: Integer);
  end;

implementation

constructor TWbsRepo.Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt);
begin
  inherited Create;
  FConnection := AConnection;
  FCodigoEmpresa := ACodigoEmpresa;
end;

procedure TWbsRepo.AppendSubtree(
  const AByParent: TDictionary<Integer, TList<TWbsTask>>;
  AParentId, ANivel: Integer; var AOut: TList<TWbsTask>);
var
  Hijos: TList<TWbsTask>;
  I: Integer;
  T: TWbsTask;
begin
  if not AByParent.TryGetValue(AParentId, Hijos) then Exit;
  for I := 0 to Hijos.Count - 1 do
  begin
    T := Hijos[I];
    T.Nivel := ANivel;
    T.HasChildren := AByParent.ContainsKey(T.NodeId);
    AOut.Add(T);
    // Descender: los hijos de esta tarea, un nivel mas.
    AppendSubtree(AByParent, T.NodeId, ANivel + 1, AOut);
  end;
end;

function TWbsRepo.LoadTareas(AProjectId: Integer): TWbsTaskArray;
var
  Q: TADOQuery;
  T: TWbsTask;
  // Agrupacion por padre (0 = raiz), cada lista ordenada por OrdenWBS.
  ByParent: TDictionary<Integer, TList<TWbsTask>>;
  Ordered: TList<TWbsTask>;
  Lst: TList<TWbsTask>;
  Pair: TPair<Integer, TList<TWbsTask>>;
  Cmp: IComparer<TWbsTask>;
begin
  ByParent := TDictionary<Integer, TList<TWbsTask>>.Create;
  Ordered := TList<TWbsTask>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        // Las UNIDADES (suma de dedicaciones) se traen en la misma consulta con
        // un subselect: son parte de la triada de esfuerzo y sin ellas el
        // trabajo no se puede recalcular. Sin operarios asignados el subselect
        // da NULL y se resuelve a 1.0 ("una persona a jornada completa").
        'SELECT n.NodeId, ISNULL(n.ParentTaskId, 0) AS ParentTaskId, ' +
        '  n.TaskKind, n.OrdenWBS, n.Collapsed, ISNULL(n.Caption, '''') AS Caption, ' +
        '  n.FechaInicio, n.FechaFin, n.DuracionMin, ' +
        '  ISNULL(n.ConstraintKind, 0) AS ConstraintKind, n.ConstraintDate, ' +
        '  ISNULL(n.MinutosInvertidos, 0) AS MinutosInvertidos, ' +
        '  ISNULL(n.TipoTarea, 0) AS TipoTarea, ' +
        '  ISNULL(n.TrabajoMin, n.DuracionMin) AS TrabajoMin, ' +
        '  ISNULL((SELECT SUM(o.Dedicacion) / 100.0 FROM FS_PL_TaskOperario o ' +
        '          WHERE o.CodigoEmpresa = n.CodigoEmpresa ' +
        '            AND o.NodeId = n.NodeId), 1.0) AS Unidades ' +
        'FROM FS_PL_Node n ' +
        'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('PID').Value := AProjectId;
      Q.Open;
      while not Q.Eof do
      begin
        T := Default(TWbsTask);
        T.NodeId := Q.FieldByName('NodeId').AsInteger;
        T.ProjectId := AProjectId;
        T.ParentTaskId := Q.FieldByName('ParentTaskId').AsInteger;
        T.Kind := TWbsTaskKind(Q.FieldByName('TaskKind').AsInteger);
        T.OrdenWBS := Q.FieldByName('OrdenWBS').AsInteger;
        T.Collapsed := Q.FieldByName('Collapsed').AsBoolean;
        T.Caption := Q.FieldByName('Caption').AsString;
        if not Q.FieldByName('FechaInicio').IsNull then
          T.FechaInicio := Q.FieldByName('FechaInicio').AsDateTime;
        if not Q.FieldByName('FechaFin').IsNull then
          T.FechaFin := Q.FieldByName('FechaFin').AsDateTime;
        T.DuracionMin := Q.FieldByName('DuracionMin').AsFloat;
        T.MinutosInvertidos := Q.FieldByName('MinutosInvertidos').AsFloat;
        T.ConstraintKind := Q.FieldByName('ConstraintKind').AsInteger;
        if not Q.FieldByName('ConstraintDate').IsNull then
          T.ConstraintDate := Q.FieldByName('ConstraintDate').AsDateTime;

        // Triada de esfuerzo (V082).
        T.TipoTarea := TWbsTipoTarea(Q.FieldByName('TipoTarea').AsInteger);
        T.TrabajoMin := Q.FieldByName('TrabajoMin').AsFloat;
        T.Unidades := Q.FieldByName('Unidades').AsFloat;
        if T.Unidades <= 0 then T.Unidades := 1.0;

        if not ByParent.TryGetValue(T.ParentTaskId, Lst) then
        begin
          Lst := TList<TWbsTask>.Create;
          ByParent.Add(T.ParentTaskId, Lst);
        end;
        Lst.Add(T);
        Q.Next;
      end;
    finally
      Q.Free;
    end;

    // Ordenar cada grupo de hermanos por OrdenWBS (y NodeId como desempate).
    Cmp := TComparer<TWbsTask>.Construct(
      function(const A, B: TWbsTask): Integer
      begin
        Result := A.OrdenWBS - B.OrdenWBS;
        if Result = 0 then Result := A.NodeId - B.NodeId;
      end);
    for Pair in ByParent do
      Pair.Value.Sort(Cmp);

    // Recorrido de arbol desde las raices (padre 0).
    AppendSubtree(ByParent, 0, 0, Ordered);

    Result := Ordered.ToArray;
  finally
    for Pair in ByParent do
      Pair.Value.Free;
    ByParent.Free;
    Ordered.Free;
  end;
end;

procedure TWbsRepo.SaveMinutosInvertidos(ANodeId: Integer; AMinutos: Double);
var
  Q: TADOQuery;
begin
  if ANodeId <= 0 then Exit;
  if AMinutos < 0 then AMinutos := 0;   // el CHECK de BD tampoco lo admite

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'UPDATE FS_PL_Node SET MinutosInvertidos = :MI ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('MI').Value := AMinutos;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.SaveFechas(ANodeId: Integer; const AInicio, AFin: TDateTime);
var
  Q: TADOQuery;
begin
  if ANodeId <= 0 then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'UPDATE FS_PL_Node SET FechaInicio = :FI, FechaFin = :FF ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    if AInicio > 0 then
      Q.Parameters.ParamByName('FI').Value := AInicio
    else
      Q.Parameters.ParamByName('FI').Value := Null;
    if AFin > 0 then
      Q.Parameters.ParamByName('FF').Value := AFin
    else
      Q.Parameters.ParamByName('FF').Value := Null;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.SaveDuracion(ANodeId: Integer; AMinutos: Double);
var
  Q: TADOQuery;
begin
  if ANodeId <= 0 then Exit;
  if AMinutos < 0 then AMinutos := 0;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'UPDATE FS_PL_Node SET DuracionMin = :DM ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('DM').Value := AMinutos;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TWbsRepo.LoadDetail(ANodeId: Integer;
  out ADetail: TWbsTaskDetail): Boolean;
var
  Q: TADOQuery;
begin
  ADetail := Default(TWbsTaskDetail);
  ADetail.NodeId := ANodeId;
  ADetail.Estado := wtePendiente;
  ADetail.Prioridad := wtpNormal;
  Result := False;
  if ANodeId <= 0 then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT ISNULL(Notas, '''') AS Notas, Estado, Prioridad, ' +
      '  ISNULL(Etiqueta, '''') AS Etiqueta, ISNULL(ColorEtiqueta, 0) AS ColorEtiqueta, ' +
      '  ISNULL(ResponsableId, 0) AS ResponsableId, ' +
      '  ISNULL(HorasEstimadas, 0) AS HorasEstimadas ' +
      'FROM FS_PL_TaskDetail ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.Open;
    if Q.Eof then Exit;   // sin ficha: se queda con los valores por defecto

    ADetail.Notas := Q.FieldByName('Notas').AsString;
    ADetail.Estado := TWbsTaskEstado(Q.FieldByName('Estado').AsInteger);
    ADetail.Prioridad := TWbsTaskPrioridad(Q.FieldByName('Prioridad').AsInteger);
    ADetail.Etiqueta := Q.FieldByName('Etiqueta').AsString;
    ADetail.ColorEtiqueta := Q.FieldByName('ColorEtiqueta').AsInteger;
    ADetail.ResponsableId := Q.FieldByName('ResponsableId').AsInteger;
    ADetail.HorasEstimadas := Q.FieldByName('HorasEstimadas').AsFloat;
    Result := True;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.SaveDetail(const ADetail: TWbsTaskDetail);
var
  Q: TADOQuery;
begin
  if ADetail.NodeId <= 0 then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    // UPSERT: la ficha es opcional, asi que puede no existir todavia.
    Q.SQL.Text :=
      'MERGE FS_PL_TaskDetail AS T ' +
      'USING (SELECT :CE AS CodigoEmpresa, :NID AS NodeId) AS S ' +
      '  ON T.CodigoEmpresa = S.CodigoEmpresa AND T.NodeId = S.NodeId ' +
      'WHEN MATCHED THEN UPDATE SET ' +
      '  Notas = :Notas, Estado = :Estado, Prioridad = :Prioridad, ' +
      '  Etiqueta = :Etiqueta, ColorEtiqueta = :ColorEtiqueta, ' +
      '  ResponsableId = :ResponsableId, HorasEstimadas = :HorasEst, ' +
      '  UpdatedAt = SYSDATETIME() ' +
      'WHEN NOT MATCHED THEN INSERT ' +
      '  (CodigoEmpresa, NodeId, Notas, Estado, Prioridad, Etiqueta, ' +
      '   ColorEtiqueta, ResponsableId, HorasEstimadas, UpdatedAt) ' +
      '  VALUES (:CE2, :NID2, :Notas2, :Estado2, :Prioridad2, :Etiqueta2, ' +
      '   :ColorEtiqueta2, :ResponsableId2, :HorasEst2, SYSDATETIME());';

    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ADetail.NodeId;
    Q.Parameters.ParamByName('Notas').Value := ADetail.Notas;
    Q.Parameters.ParamByName('Estado').Value := Ord(ADetail.Estado);
    Q.Parameters.ParamByName('Prioridad').Value := Ord(ADetail.Prioridad);
    Q.Parameters.ParamByName('Etiqueta').Value := ADetail.Etiqueta;
    Q.Parameters.ParamByName('ColorEtiqueta').Value := ADetail.ColorEtiqueta;
    if ADetail.ResponsableId > 0 then
      Q.Parameters.ParamByName('ResponsableId').Value := ADetail.ResponsableId
    else
      Q.Parameters.ParamByName('ResponsableId').Value := Null;
    Q.Parameters.ParamByName('HorasEst').Value := ADetail.HorasEstimadas;

    // ADO no reutiliza parametros con el mismo nombre: duplicados para el INSERT.
    Q.Parameters.ParamByName('CE2').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID2').Value := ADetail.NodeId;
    Q.Parameters.ParamByName('Notas2').Value := ADetail.Notas;
    Q.Parameters.ParamByName('Estado2').Value := Ord(ADetail.Estado);
    Q.Parameters.ParamByName('Prioridad2').Value := Ord(ADetail.Prioridad);
    Q.Parameters.ParamByName('Etiqueta2').Value := ADetail.Etiqueta;
    Q.Parameters.ParamByName('ColorEtiqueta2').Value := ADetail.ColorEtiqueta;
    if ADetail.ResponsableId > 0 then
      Q.Parameters.ParamByName('ResponsableId2').Value := ADetail.ResponsableId
    else
      Q.Parameters.ParamByName('ResponsableId2').Value := Null;
    Q.Parameters.ParamByName('HorasEst2').Value := ADetail.HorasEstimadas;

    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TWbsRepo.LoadOperarios(ANodeId: Integer): TWbsTaskOperarioArray;
var
  Q: TADOQuery;
  L: TList<TWbsTaskOperario>;
  O: TWbsTaskOperario;
begin
  L := TList<TWbsTaskOperario>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT t.OperatorId, ISNULL(o.Nombre, '''') AS Nombre, ' +
        '  t.Dedicacion, t.MinutosImputados ' +
        'FROM FS_PL_TaskOperario t ' +
        'LEFT JOIN FS_PL_Operator o ' +
        '  ON o.CodigoEmpresa = t.CodigoEmpresa AND o.OperatorId = t.OperatorId ' +
        'WHERE t.CodigoEmpresa = :CE AND t.NodeId = :NID ' +
        'ORDER BY o.Nombre, t.OperatorId';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('NID').Value := ANodeId;
      Q.Open;
      while not Q.Eof do
      begin
        O := Default(TWbsTaskOperario);
        O.NodeId := ANodeId;
        O.OperatorId := Q.FieldByName('OperatorId').AsInteger;
        O.Nombre := Q.FieldByName('Nombre').AsString;
        if Trim(O.Nombre) = '' then
          O.Nombre := 'Operario ' + IntToStr(O.OperatorId);
        O.Dedicacion := Q.FieldByName('Dedicacion').AsFloat;
        O.MinutosImputados := Q.FieldByName('MinutosImputados').AsFloat;
        L.Add(O);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TWbsRepo.SaveOperarios(ANodeId: Integer;
  const AOperarios: TWbsTaskOperarioArray; ARecuadrarTriada: Boolean);
var
  Q: TADOQuery;
  I: Integer;
begin
  if ANodeId <= 0 then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;

    // Reemplazo completo: la lista que llega ES la asignacion de la tarea.
    // Son pocas filas por tarea, asi que borrar e insertar es mas simple (y
    // mas facil de razonar) que diferenciar altas, bajas y modificaciones.
    Q.SQL.Text := 'DELETE FROM FS_PL_TaskOperario ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;

    for I := 0 to High(AOperarios) do
    begin
      if AOperarios[I].OperatorId <= 0 then Continue;
      Q.SQL.Text :=
        'INSERT INTO FS_PL_TaskOperario ' +
        '  (CodigoEmpresa, NodeId, OperatorId, Dedicacion, MinutosImputados) ' +
        'VALUES (:CE, :NID, :OID, :Ded, :Min)';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('NID').Value := ANodeId;
      Q.Parameters.ParamByName('OID').Value := AOperarios[I].OperatorId;
      // El CHECK exige 0 < Dedicacion <= 100.
      if (AOperarios[I].Dedicacion <= 0) or (AOperarios[I].Dedicacion > 100) then
        Q.Parameters.ParamByName('Ded').Value := 100
      else
        Q.Parameters.ParamByName('Ded').Value := AOperarios[I].Dedicacion;
      Q.Parameters.ParamByName('Min').Value :=
        Max(0, AOperarios[I].MinutosImputados);
      Q.ExecSQL;
    end;

    // Cambiar quien trabaja en la tarea cambia las UNIDADES, y con ellas la
    // ecuacion de esfuerzo (V082):
    //   - Duracion fija  -> el trabajo se reparte entre los nuevos operarios.
    //   - Trabajo fijo   -> mas gente acorta la tarea, menos la alarga.
    //   - Unidades fijas -> el equipo lo marca el usuario, no la asignacion;
    //                       no se toca nada (igual que RecalcularTriada).
    //
    // Solo cuando el llamante NO ha resuelto ya la ecuacion: la ficha la
    // resuelve al aceptar, con las unidades finales, y volver a calcularla
    // aqui pisaria el trabajo que el usuario acaba de teclear.
    if not ARecuadrarTriada then Exit;

    Q.SQL.Text :=
      'UPDATE n SET ' +
      '  TrabajoMin = CASE WHEN n.TipoTarea = 0 ' +
      '                    THEN ROUND(n.DuracionMin * u.Unidades, 2) ' +
      '                    ELSE n.TrabajoMin END, ' +
      '  DuracionMin = CASE WHEN n.TipoTarea = 1 AND u.Unidades > 0 ' +
      '                     THEN ROUND(ISNULL(n.TrabajoMin, n.DuracionMin) ' +
      '                                / u.Unidades, 2) ' +
      '                     ELSE n.DuracionMin END ' +
      'FROM FS_PL_Node n ' +
      'CROSS APPLY (SELECT ISNULL((SELECT SUM(o.Dedicacion) / 100.0 ' +
      '                              FROM FS_PL_TaskOperario o ' +
      '                             WHERE o.CodigoEmpresa = n.CodigoEmpresa ' +
      '                               AND o.NodeId = n.NodeId), 1.0) ' +
      '                    AS Unidades) u ' +
      'WHERE n.CodigoEmpresa = :CE AND n.NodeId = :NID ' +
      // Solo tareas normales: un hito no dura ni cuesta, y la duracion de un
      // resumen es un roll-up de sus hijos que el motor recalcula (escribirla
      // aqui seria ruido en BD).
      '  AND n.TaskKind = 0';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.SaveRestriccionFecha(ANodeId: Integer; AKind: Integer;
  const AFecha: TDateTime);
var
  Q: TADOQuery;
begin
  if ANodeId <= 0 then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'UPDATE FS_PL_Node SET ConstraintKind = :CK, ConstraintDate = :CD ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('CK').Value := AKind;
    if (AKind > 0) and (AFecha > 0) then
      Q.Parameters.ParamByName('CD').Value := AFecha
    else
      Q.Parameters.ParamByName('CD').Value := Null;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.SaveTaskKind(ANodeId: Integer; AKind: Integer);
var
  Q: TADOQuery;
begin
  if ANodeId <= 0 then Exit;
  if (AKind < 0) or (AKind > 2) then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'UPDATE FS_PL_Node SET TaskKind = :TK ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('TK').Value := AKind;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.SaveEsfuerzo(ANodeId: Integer;
  ADuracionMin, ATrabajoMin: Double; ATipoTarea: Integer);
var
  Q: TADOQuery;
begin
  if ANodeId <= 0 then Exit;
  if ADuracionMin < 0 then ADuracionMin := 0;
  if ATrabajoMin < 0 then ATrabajoMin := 0;
  if (ATipoTarea < 0) or (ATipoTarea > 2) then ATipoTarea := 0;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    // Las tres en un solo UPDATE: guardar la duracion sin el trabajo (o al
    // reves) dejaria la ecuacion descuadrada en BD hasta el siguiente guardado.
    Q.SQL.Text :=
      'UPDATE FS_PL_Node ' +
      '   SET DuracionMin = :DM, TrabajoMin = :TM, TipoTarea = :TT ' +
      ' WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('DM').Value := ADuracionMin;
    Q.Parameters.ParamByName('TM').Value := ATrabajoMin;
    Q.Parameters.ParamByName('TT').Value := ATipoTarea;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.SaveTipoTarea(ANodeId: Integer; ATipoTarea: Integer);
var
  Q: TADOQuery;
begin
  if ANodeId <= 0 then Exit;
  if (ATipoTarea < 0) or (ATipoTarea > 2) then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'UPDATE FS_PL_Node SET TipoTarea = :TT ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('TT').Value := ATipoTarea;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TWbsRepo.FijarBaseline(AProjectId: Integer; const ANombre: string;
  AUserId: Integer; ABaselineId: Integer): Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  if AProjectId <= 0 then Exit;
  if (ABaselineId < 0) or (ABaselineId > 10) then ABaselineId := 0;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;

    // Fijar otra vez la misma linea base REHACE la foto, no la acumula.
    Q.SQL.Text :=
      'DELETE FROM FS_PL_TaskBaseline ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID AND BaselineId = :BID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Parameters.ParamByName('BID').Value := ABaselineId;
    Q.ExecSQL;

    // La foto, en una sola sentencia: es lo que hay en FS_PL_Node ahora mismo.
    Q.SQL.Text :=
      'INSERT INTO FS_PL_TaskBaseline ' +
      '  (CodigoEmpresa, ProjectId, BaselineId, NodeId, ' +
      '   FechaInicio, FechaFin, DuracionMin, TrabajoMin) ' +
      'SELECT n.CodigoEmpresa, n.ProjectId, :BID, n.NodeId, ' +
      '       n.FechaInicio, n.FechaFin, n.DuracionMin, ' +
      '       ISNULL(n.TrabajoMin, n.DuracionMin) ' +
      '  FROM FS_PL_Node n ' +
      ' WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID';
    Q.Parameters.ParamByName('BID').Value := ABaselineId;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.ExecSQL;

    Q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM FS_PL_TaskBaseline ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID AND BaselineId = :BID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Parameters.ParamByName('BID').Value := ABaselineId;
    Q.Open;
    if not Q.Eof then Result := Q.Fields[0].AsInteger;
    Q.Close;

    // Cabecera: cuando, quien y con que nombre.
    Q.SQL.Text :=
      'MERGE FS_PL_Baseline AS T ' +
      'USING (SELECT :CE AS CodigoEmpresa, :PID AS ProjectId, ' +
      '              :BID AS BaselineId) AS S ' +
      '  ON T.CodigoEmpresa = S.CodigoEmpresa AND T.ProjectId = S.ProjectId ' +
      ' AND T.BaselineId = S.BaselineId ' +
      'WHEN MATCHED THEN UPDATE SET ' +
      '  Nombre = :NOM, FijadaEn = SYSDATETIME(), FijadaPor = :UID, ' +
      '  NumTareas = :NT ' +
      'WHEN NOT MATCHED THEN INSERT ' +
      '  (CodigoEmpresa, ProjectId, BaselineId, Nombre, FijadaEn, FijadaPor, ' +
      '   NumTareas) ' +
      '  VALUES (:CE2, :PID2, :BID2, :NOM2, SYSDATETIME(), :UID2, :NT2);';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Parameters.ParamByName('BID').Value := ABaselineId;
    Q.Parameters.ParamByName('NOM').Value := ANombre;
    if AUserId > 0 then
      Q.Parameters.ParamByName('UID').Value := AUserId
    else
      Q.Parameters.ParamByName('UID').Value := Null;
    Q.Parameters.ParamByName('NT').Value := Result;
    // ADO no reutiliza parametros con el mismo nombre: duplicados del INSERT.
    Q.Parameters.ParamByName('CE2').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID2').Value := AProjectId;
    Q.Parameters.ParamByName('BID2').Value := ABaselineId;
    Q.Parameters.ParamByName('NOM2').Value := ANombre;
    if AUserId > 0 then
      Q.Parameters.ParamByName('UID2').Value := AUserId
    else
      Q.Parameters.ParamByName('UID2').Value := Null;
    Q.Parameters.ParamByName('NT2').Value := Result;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.BorrarBaseline(AProjectId: Integer; ABaselineId: Integer);
var
  Q: TADOQuery;
begin
  if AProjectId <= 0 then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'DELETE FROM FS_PL_TaskBaseline ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID AND BaselineId = :BID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Parameters.ParamByName('BID').Value := ABaselineId;
    Q.ExecSQL;

    Q.SQL.Text :=
      'DELETE FROM FS_PL_Baseline ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID AND BaselineId = :BID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Parameters.ParamByName('BID').Value := ABaselineId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TWbsRepo.LoadBaselines(AProjectId: Integer): TWbsBaselineArray;
var
  Q: TADOQuery;
  L: TList<TWbsBaseline>;
  B: TWbsBaseline;
begin
  SetLength(Result, 0);
  if AProjectId <= 0 then Exit;

  L := TList<TWbsBaseline>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT BaselineId, ISNULL(Nombre, '''') AS Nombre, ' +
        '  FijadaEn, ISNULL(NumTareas, 0) AS NumTareas ' +
        'FROM FS_PL_Baseline ' +
        'WHERE CodigoEmpresa = :CE AND ProjectId = :PID ' +
        'ORDER BY BaselineId';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('PID').Value := AProjectId;
      Q.Open;
      while not Q.Eof do
      begin
        B := Default(TWbsBaseline);
        B.ProjectId := AProjectId;
        B.BaselineId := Q.FieldByName('BaselineId').AsInteger;
        B.Nombre := Q.FieldByName('Nombre').AsString;
        if not Q.FieldByName('FijadaEn').IsNull then
          B.FijadaEn := Q.FieldByName('FijadaEn').AsDateTime;
        B.NumTareas := Q.FieldByName('NumTareas').AsInteger;
        if Trim(B.Nombre) = '' then
          B.Nombre := 'L'#237'nea base ' + IntToStr(B.BaselineId);
        L.Add(B);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TWbsRepo.LoadDesvios(
  AProjectId: Integer): TDictionary<Integer, TWbsDesvio>;
var
  Q: TADOQuery;
  D: TWbsDesvio;
begin
  Result := TDictionary<Integer, TWbsDesvio>.Create;
  if AProjectId <= 0 then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    // La vista FS_PL_V_TaskBaselineDesvio (V082) encapsula el LEFT JOIN y el
    // criterio de signo: POSITIVO = va peor que el plan.
    Q.SQL.Text :=
      'SELECT NodeId, TieneBaseline, BaseInicio, BaseFin, ' +
      '  BaseDuracionMin, BaseTrabajoMin, ' +
      '  DesvioInicioDias, DesvioFinDias, DesvioTrabajoMin ' +
      'FROM FS_PL_V_TaskBaselineDesvio ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Open;
    while not Q.Eof do
    begin
      D := Default(TWbsDesvio);
      D.NodeId := Q.FieldByName('NodeId').AsInteger;
      D.TieneBaseline := Q.FieldByName('TieneBaseline').AsInteger = 1;
      if not Q.FieldByName('BaseInicio').IsNull then
        D.BaseInicio := Q.FieldByName('BaseInicio').AsDateTime;
      if not Q.FieldByName('BaseFin').IsNull then
        D.BaseFin := Q.FieldByName('BaseFin').AsDateTime;
      if not Q.FieldByName('BaseDuracionMin').IsNull then
        D.BaseDuracionMin := Q.FieldByName('BaseDuracionMin').AsFloat;
      if not Q.FieldByName('BaseTrabajoMin').IsNull then
        D.BaseTrabajoMin := Q.FieldByName('BaseTrabajoMin').AsFloat;
      if not Q.FieldByName('DesvioInicioDias').IsNull then
        D.DesvioInicioDias := Q.FieldByName('DesvioInicioDias').AsInteger;
      if not Q.FieldByName('DesvioFinDias').IsNull then
        D.DesvioFinDias := Q.FieldByName('DesvioFinDias').AsInteger;
      if not Q.FieldByName('DesvioTrabajoMin').IsNull then
        D.DesvioTrabajoMin := Q.FieldByName('DesvioTrabajoMin').AsFloat;
      Result.AddOrSetValue(D.NodeId, D);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TWbsRepo.ResolverOrden(AProjectId, AParentTaskId,
  AOrden: Integer): Integer;
var
  Q: TADOQuery;
begin
  Result := AOrden;
  if AOrden >= 0 then Exit;

  Result := 0;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT ISNULL(MAX(OrdenWBS), -1) + 1 AS Siguiente ' +
      'FROM FS_PL_Node ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID ' +
      '  AND ISNULL(ParentTaskId, 0) = :PARENT';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Parameters.ParamByName('PARENT').Value := AParentTaskId;
    Q.Open;
    if not Q.Eof then Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

function TWbsRepo.InsertTarea(AProjectId, AParentTaskId, AOrdenWBS: Integer;
  const ACaption: string; AKind: Integer; ADuracionMin: Double): Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  if AProjectId <= 0 then Exit;
  if (AKind < 0) or (AKind > 2) then AKind := 0;
  if ADuracionMin < 0 then ADuracionMin := 0;
  AOrdenWBS := ResolverOrden(AProjectId, AParentTaskId, AOrdenWBS);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;

    // Hacer sitio: los hermanos que van en AOrdenWBS o mas atras se corren uno.
    // Sin esto, insertar en medio deja dos tareas con el mismo OrdenWBS y el
    // orden entre ellas lo acaba decidiendo el NodeId (es decir, el azar).
    Q.SQL.Text :=
      'UPDATE FS_PL_Node SET OrdenWBS = OrdenWBS + 1 ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID ' +
      '  AND ISNULL(ParentTaskId, 0) = :PARENT AND OrdenWBS >= :ORD';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Parameters.ParamByName('PARENT').Value := AParentTaskId;
    Q.Parameters.ParamByName('ORD').Value := AOrdenWBS;
    Q.ExecSQL;

    // Un hito no dura: la duracion que llegue se ignora, para que no se cuele
    // una barra donde el usuario ha pedido un rombo.
    if AKind = 2 then ADuracionMin := 0;

    // TrabajoMin nace igualado a la duracion: sin operarios asignados las
    // unidades valen 1, y Trabajo = Duracion x 1. Dejarlo NULL haria nacer la
    // tarea con la ecuacion de esfuerzo descuadrada.
    Q.SQL.Text :=
      'INSERT INTO FS_PL_Node ' +
      '  (CodigoEmpresa, ProjectId, ParentTaskId, TaskKind, OrdenWBS, ' +
      '   Collapsed, Caption, DuracionMin, TrabajoMin, TipoTarea, ' +
      '   ConstraintKind, Visible, Habilitado) ' +
      'VALUES (:CE, :PID, :PARENT, :TK, :ORD, 0, :CAP, :DUR, :DUR2, 0, ' +
      '        0, 1, 1); ' +
      'SELECT SCOPE_IDENTITY() AS NuevoId;';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    if AParentTaskId > 0 then
      Q.Parameters.ParamByName('PARENT').Value := AParentTaskId
    else
      Q.Parameters.ParamByName('PARENT').Value := Null;   // raiz = NULL en BD
    Q.Parameters.ParamByName('TK').Value := AKind;
    Q.Parameters.ParamByName('ORD').Value := AOrdenWBS;
    Q.Parameters.ParamByName('CAP').Value := ACaption;
    Q.Parameters.ParamByName('DUR').Value := ADuracionMin;
    Q.Parameters.ParamByName('DUR2').Value := ADuracionMin;
    Q.Open;
    if not Q.Eof then Result := Q.Fields[0].AsInteger;
    Q.Close;

    // El padre acaba de ganar un hijo: si era una tarea normal (o un hito),
    // ahora es un RESUMEN. Sus fechas y su avance pasan a ser un agregado que
    // calcula el motor, no datos propios.
    if (Result > 0) and (AParentTaskId > 0) then
    begin
      Q.SQL.Text :=
        'UPDATE FS_PL_Node SET TaskKind = 1 ' +
        'WHERE CodigoEmpresa = :CE AND NodeId = :NID AND TaskKind <> 1';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('NID').Value := AParentTaskId;
      Q.ExecSQL;
    end;
  finally
    Q.Free;
  end;

  // Dejar el grupo denso (0..N-1). El "hacer sitio" de arriba abre un hueco
  // que, si no se cierra, va separando la numeracion insercion tras insercion.
  if Result > 0 then
    ReordenarHermanos(AProjectId, AParentTaskId);
end;

function TWbsRepo.DeleteTarea(ANodeId: Integer): Integer;
var
  Q: TADOQuery;
  Ids: TList<Integer>;
  Frontera, Siguiente: TList<Integer>;
  Lista: string;
  I: Integer;
  PadreId, ProjectId: Integer;
begin
  Result := 0;
  if ANodeId <= 0 then Exit;
  // Se inicializan aqui porque el Exit de "la tarea ya no existe" salta antes
  // de leerlas de BD, y el compilador no puede ver que tampoco se usan.
  PadreId := 0;
  ProjectId := 0;

  Ids := TList<Integer>.Create;
  Frontera := TList<Integer>.Create;
  Siguiente := TList<Integer>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;

      // Padre y proyecto ANTES de borrar: hacen falta despues para renumerar y
      // para degradar al padre si se queda sin hijos.
      Q.SQL.Text :=
        'SELECT ISNULL(ParentTaskId, 0) AS ParentTaskId, ProjectId ' +
        'FROM FS_PL_Node WHERE CodigoEmpresa = :CE AND NodeId = :NID';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('NID').Value := ANodeId;
      Q.Open;
      if Q.Eof then Exit;   // ya no existe
      PadreId := Q.FieldByName('ParentTaskId').AsInteger;
      ProjectId := Q.FieldByName('ProjectId').AsInteger;
      Q.Close;

      // Recolectar el subarbol por niveles. Se hace en Pascal y no con un CTE
      // recursivo porque asi la lista de ids sirve tambien para borrar las
      // tablas satelite, y no depende de la version de SQL Server.
      Ids.Add(ANodeId);
      Frontera.Add(ANodeId);
      while Frontera.Count > 0 do
      begin
        Lista := '';
        for I := 0 to Frontera.Count - 1 do
        begin
          if Lista <> '' then Lista := Lista + ',';
          Lista := Lista + IntToStr(Frontera[I]);
        end;

        Siguiente.Clear;
        Q.SQL.Text :=
          'SELECT NodeId FROM FS_PL_Node ' +
          'WHERE CodigoEmpresa = :CE AND ParentTaskId IN (' + Lista + ')';
        Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
        Q.Open;
        while not Q.Eof do
        begin
          Siguiente.Add(Q.FieldByName('NodeId').AsInteger);
          Q.Next;
        end;
        Q.Close;

        Ids.AddRange(Siguiente);
        Frontera.Clear;
        Frontera.AddRange(Siguiente);
      end;

      Lista := '';
      for I := 0 to Ids.Count - 1 do
      begin
        if Lista <> '' then Lista := Lista + ',';
        Lista := Lista + IntToStr(Ids[I]);
      end;

      // Orden de borrado: primero lo que apunta al nodo, el nodo al final. Las
      // dependencias se borran por AMBOS lados (una tarea puede ser origen o
      // destino) o la FK impide borrar el nodo.
      Q.SQL.Text :=
        'DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa = :CE ' +
        '  AND (FromNodeId IN (' + Lista + ') OR ToNodeId IN (' + Lista + '))';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.ExecSQL;

      Q.SQL.Text := 'DELETE FROM FS_PL_TaskTagLink WHERE CodigoEmpresa = :CE ' +
        'AND NodeId IN (' + Lista + ')';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.ExecSQL;

      Q.SQL.Text := 'DELETE FROM FS_PL_TaskOperario WHERE CodigoEmpresa = :CE ' +
        'AND NodeId IN (' + Lista + ')';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.ExecSQL;

      Q.SQL.Text := 'DELETE FROM FS_PL_TaskDetail WHERE CodigoEmpresa = :CE ' +
        'AND NodeId IN (' + Lista + ')';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.ExecSQL;

      // FS_PL_NodeData cae por CASCADE desde FS_PL_Node.
      Q.SQL.Text := 'DELETE FROM FS_PL_Node WHERE CodigoEmpresa = :CE ' +
        'AND NodeId IN (' + Lista + ')';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.ExecSQL;

      Result := Ids.Count;

      // Si el padre se ha quedado sin hijos, deja de ser resumen: vuelve a ser
      // una tarea normal con duracion propia.
      if PadreId > 0 then
      begin
        Q.SQL.Text :=
          'UPDATE FS_PL_Node SET TaskKind = 0 ' +
          'WHERE CodigoEmpresa = :CE AND NodeId = :NID AND TaskKind = 1 ' +
          '  AND NOT EXISTS (SELECT 1 FROM FS_PL_Node h ' +
          '    WHERE h.CodigoEmpresa = :CE2 AND h.ParentTaskId = :NID2)';
        Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
        Q.Parameters.ParamByName('NID').Value := PadreId;
        Q.Parameters.ParamByName('CE2').Value := FCodigoEmpresa;
        Q.Parameters.ParamByName('NID2').Value := PadreId;
        Q.ExecSQL;
      end;
    finally
      Q.Free;
    end;

    // Cerrar el hueco que ha dejado en la numeracion de sus hermanos.
    if ProjectId > 0 then
      ReordenarHermanos(ProjectId, PadreId);
  finally
    Ids.Free;
    Frontera.Free;
    Siguiente.Free;
  end;
end;

function TWbsRepo.MoverTarea(ANodeId, ANuevoParentId,
  ANuevoOrden: Integer): Boolean;
var
  Q: TADOQuery;
  ProjectId, PadreViejo, Cursor: Integer;
  Vueltas: Integer;
begin
  Result := False;
  if ANodeId <= 0 then Exit;
  if ANodeId = ANuevoParentId then Exit;   // no puede ser su propio padre

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;

    Q.SQL.Text :=
      'SELECT ProjectId, ISNULL(ParentTaskId, 0) AS ParentTaskId ' +
      'FROM FS_PL_Node WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.Open;
    if Q.Eof then Exit;
    ProjectId := Q.FieldByName('ProjectId').AsInteger;
    PadreViejo := Q.FieldByName('ParentTaskId').AsInteger;
    Q.Close;

    // Un nodo no puede colgar de un descendiente suyo: seria un ciclo, y el
    // arbol dejaria de poder recorrerse (la rama se perderia entera). Se sube
    // desde el destino hasta la raiz buscando el nodo movido.
    Cursor := ANuevoParentId;
    Vueltas := 0;
    while Cursor > 0 do
    begin
      if Cursor = ANodeId then Exit;   // destino dentro del propio subarbol
      // Tope de seguridad: si el arbol ya estuviera corrupto (un ciclo previo),
      // subir no acabaria nunca. Se ABANDONA el movimiento, no se sigue: dar el
      // visto bueno sin haber podido comprobarlo es justo lo que crearia el
      // ciclo que se intenta evitar.
      Inc(Vueltas);
      if Vueltas > 1000 then Exit;

      Q.SQL.Text :=
        'SELECT ISNULL(ParentTaskId, 0) AS ParentTaskId ' +
        'FROM FS_PL_Node WHERE CodigoEmpresa = :CE AND NodeId = :NID';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('NID').Value := Cursor;
      Q.Open;
      if Q.Eof then
      begin
        Q.Close;
        Break;                          // el padre ya no existe: sin ciclo
      end;
      Cursor := Q.FieldByName('ParentTaskId').AsInteger;
      Q.Close;
    end;

    ANuevoOrden := ResolverOrden(ProjectId, ANuevoParentId, ANuevoOrden);

    // Hacer sitio entre los nuevos hermanos.
    Q.SQL.Text :=
      'UPDATE FS_PL_Node SET OrdenWBS = OrdenWBS + 1 ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID ' +
      '  AND ISNULL(ParentTaskId, 0) = :PARENT AND OrdenWBS >= :ORD ' +
      '  AND NodeId <> :NID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := ProjectId;
    Q.Parameters.ParamByName('PARENT').Value := ANuevoParentId;
    Q.Parameters.ParamByName('ORD').Value := ANuevoOrden;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;

    Q.SQL.Text :=
      'UPDATE FS_PL_Node SET ParentTaskId = :PARENT, OrdenWBS = :ORD ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    if ANuevoParentId > 0 then
      Q.Parameters.ParamByName('PARENT').Value := ANuevoParentId
    else
      Q.Parameters.ParamByName('PARENT').Value := Null;
    Q.Parameters.ParamByName('ORD').Value := ANuevoOrden;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;

    // El nuevo padre gana un hijo -> resumen.
    if ANuevoParentId > 0 then
    begin
      Q.SQL.Text :=
        'UPDATE FS_PL_Node SET TaskKind = 1 ' +
        'WHERE CodigoEmpresa = :CE AND NodeId = :NID AND TaskKind <> 1';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('NID').Value := ANuevoParentId;
      Q.ExecSQL;
    end;

    // El antiguo puede haberse quedado vacio -> vuelve a ser tarea normal.
    if (PadreViejo > 0) and (PadreViejo <> ANuevoParentId) then
    begin
      Q.SQL.Text :=
        'UPDATE FS_PL_Node SET TaskKind = 0 ' +
        'WHERE CodigoEmpresa = :CE AND NodeId = :NID AND TaskKind = 1 ' +
        '  AND NOT EXISTS (SELECT 1 FROM FS_PL_Node h ' +
        '    WHERE h.CodigoEmpresa = :CE2 AND h.ParentTaskId = :NID2)';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('NID').Value := PadreViejo;
      Q.Parameters.ParamByName('CE2').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('NID2').Value := PadreViejo;
      Q.ExecSQL;
    end;

    Result := True;
  finally
    Q.Free;
  end;

  if Result then
  begin
    // Renumerar los dos grupos afectados para que no queden huecos ni empates.
    ReordenarHermanos(ProjectId, ANuevoParentId);
    if PadreViejo <> ANuevoParentId then
      ReordenarHermanos(ProjectId, PadreViejo);
  end;
end;

procedure TWbsRepo.RenombrarTarea(ANodeId: Integer; const ACaption: string);
var
  Q: TADOQuery;
begin
  if ANodeId <= 0 then Exit;
  if Trim(ACaption) = '' then Exit;   // una tarea sin nombre no es utilizable

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'UPDATE FS_PL_Node SET Caption = :CAP ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('CAP').Value := ACaption;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.ReordenarHermanos(AProjectId, AParentTaskId: Integer);
var
  Q: TADOQuery;
  Ids: TList<Integer>;
  I: Integer;
begin
  if AProjectId <= 0 then Exit;

  Ids := TList<Integer>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT NodeId FROM FS_PL_Node ' +
        'WHERE CodigoEmpresa = :CE AND ProjectId = :PID ' +
        '  AND ISNULL(ParentTaskId, 0) = :PARENT ' +
        'ORDER BY OrdenWBS, NodeId';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('PID').Value := AProjectId;
      Q.Parameters.ParamByName('PARENT').Value := AParentTaskId;
      Q.Open;
      while not Q.Eof do
      begin
        Ids.Add(Q.FieldByName('NodeId').AsInteger);
        Q.Next;
      end;
      Q.Close;

      for I := 0 to Ids.Count - 1 do
      begin
        Q.SQL.Text := 'UPDATE FS_PL_Node SET OrdenWBS = :ORD ' +
          'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
        Q.Parameters.ParamByName('ORD').Value := I;
        Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
        Q.Parameters.ParamByName('NID').Value := Ids[I];
        Q.ExecSQL;
      end;
    finally
      Q.Free;
    end;
  finally
    Ids.Free;
  end;
end;

procedure TWbsRepo.AddDependencia(AProjectId, AFromNodeId, AToNodeId,
  ATipoLink: Integer; ALagMinutos: Integer);
var
  Q: TADOQuery;
begin
  if (AFromNodeId <= 0) or (AToNodeId <= 0) or
     (AFromNodeId = AToNodeId) then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    // El NOT EXISTS evita duplicar el vinculo si el usuario repite el gesto.
    Q.SQL.Text :=
      'INSERT INTO FS_PL_Dependency ' +
      '  (CodigoEmpresa, ProjectId, FromNodeId, ToNodeId, TipoLink, ' +
      '   PorcentajeDependencia, LagMinutos) ' +
      'SELECT :CE, :PID, :FID, :TID, :TL, 100, :LAG ' +
      'WHERE NOT EXISTS (SELECT 1 FROM FS_PL_Dependency ' +
      '  WHERE CodigoEmpresa = :CE2 AND FromNodeId = :FID2 ' +
      '    AND ToNodeId = :TID2)';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Parameters.ParamByName('FID').Value := AFromNodeId;
    Q.Parameters.ParamByName('TID').Value := AToNodeId;
    Q.Parameters.ParamByName('TL').Value := ATipoLink;
    Q.Parameters.ParamByName('LAG').Value := ALagMinutos;
    Q.Parameters.ParamByName('CE2').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('FID2').Value := AFromNodeId;
    Q.Parameters.ParamByName('TID2').Value := AToNodeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.DeleteDependencia(ADependencyId: Integer);
var
  Q: TADOQuery;
begin
  if ADependencyId <= 0 then Exit;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'DELETE FROM FS_PL_Dependency ' +
      'WHERE CodigoEmpresa = :CE AND DependencyId = :DID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('DID').Value := ADependencyId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TWbsRepo.LoadCargaOperarios(
  AProjectIds: TArray<Integer>): TWbsCargaArray;
var
  Q: TADOQuery;
  L: TList<TWbsCarga>;
  C: TWbsCarga;
  Lista: string;
  I: Integer;
begin
  SetLength(Result, 0);
  if Length(AProjectIds) = 0 then Exit;

  // Lista de ProjectIds en el IN. Son enteros validados por el llamante (no
  // vienen del usuario), asi que no hay riesgo de inyeccion.
  Lista := '';
  for I := 0 to High(AProjectIds) do
  begin
    if Lista <> '' then Lista := Lista + ',';
    Lista := Lista + IntToStr(AProjectIds[I]);
  end;

  L := TList<TWbsCarga>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT t.OperatorId, ISNULL(o.Nombre, '''') AS Nombre, ' +
        '  t.NodeId, ISNULL(n.Caption, '''') AS Caption, ' +
        '  n.FechaInicio, n.FechaFin, t.Dedicacion ' +
        'FROM FS_PL_TaskOperario t ' +
        'JOIN FS_PL_Node n ' +
        '  ON n.CodigoEmpresa = t.CodigoEmpresa AND n.NodeId = t.NodeId ' +
        'LEFT JOIN FS_PL_Operator o ' +
        '  ON o.CodigoEmpresa = t.CodigoEmpresa AND o.OperatorId = t.OperatorId ' +
        'WHERE t.CodigoEmpresa = :CE AND n.ProjectId IN (' + Lista + ') ' +
        '  AND n.FechaInicio IS NOT NULL ' +
        'ORDER BY o.Nombre, n.FechaInicio';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        C := Default(TWbsCarga);
        C.OperatorId := Q.FieldByName('OperatorId').AsInteger;
        C.Nombre := Q.FieldByName('Nombre').AsString;
        if Trim(C.Nombre) = '' then
          C.Nombre := 'Operario ' + IntToStr(C.OperatorId);
        C.NodeId := Q.FieldByName('NodeId').AsInteger;
        C.Caption := Q.FieldByName('Caption').AsString;
        C.FechaInicio := Q.FieldByName('FechaInicio').AsDateTime;
        if not Q.FieldByName('FechaFin').IsNull then
          C.FechaFin := Q.FieldByName('FechaFin').AsDateTime;
        C.Dedicacion := Q.FieldByName('Dedicacion').AsFloat;
        L.Add(C);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TWbsRepo.LoadTags(ANodeId: Integer): TWbsTagArray;
var
  Q: TADOQuery;
  L: TList<TWbsTag>;
  T: TWbsTag;
begin
  L := TList<TWbsTag>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      // El LEFT JOIN resuelve en una sola consulta el catalogo Y cuales lleva
      // ya la tarea (Asignada), en vez de dos viajes a BD.
      Q.SQL.Text :=
        'SELECT t.TagId, t.Nombre, t.Color, t.Orden, ' +
        '  CASE WHEN l.TagId IS NULL THEN 0 ELSE 1 END AS Asignada ' +
        'FROM FS_PL_TaskTag t ' +
        'LEFT JOIN FS_PL_TaskTagLink l ' +
        '  ON l.CodigoEmpresa = t.CodigoEmpresa AND l.TagId = t.TagId ' +
        '  AND l.NodeId = :NID ' +
        'WHERE t.CodigoEmpresa = :CE ' +
        'ORDER BY t.Orden, t.Nombre';
      Q.Parameters.ParamByName('NID').Value := ANodeId;
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        T := Default(TWbsTag);
        T.TagId := Q.FieldByName('TagId').AsInteger;
        T.Nombre := Q.FieldByName('Nombre').AsString;
        T.Color := Q.FieldByName('Color').AsInteger;
        T.Orden := Q.FieldByName('Orden').AsInteger;
        T.Asignada := Q.FieldByName('Asignada').AsInteger = 1;
        L.Add(T);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TWbsRepo.SaveTagsDeTarea(ANodeId: Integer; const ATags: TWbsTagArray);
var
  Q: TADOQuery;
  I: Integer;
begin
  if ANodeId <= 0 then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    // Reemplazo completo: son pocas filas y evita distinguir altas de bajas.
    Q.SQL.Text := 'DELETE FROM FS_PL_TaskTagLink ' +
      'WHERE CodigoEmpresa = :CE AND NodeId = :NID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('NID').Value := ANodeId;
    Q.ExecSQL;

    for I := 0 to High(ATags) do
    begin
      if not ATags[I].Asignada then Continue;
      Q.SQL.Text :=
        'INSERT INTO FS_PL_TaskTagLink (CodigoEmpresa, NodeId, TagId) ' +
        'VALUES (:CE, :NID, :TID)';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('NID').Value := ANodeId;
      Q.Parameters.ParamByName('TID').Value := ATags[I].TagId;
      Q.ExecSQL;
    end;
  finally
    Q.Free;
  end;
end;

function TWbsRepo.LoadTagsPorNodo(AProjectId: Integer):
  TDictionary<Integer, TArray<Integer>>;
var
  Q: TADOQuery;
  NodeId: Integer;
  Lst: TArray<Integer>;
begin
  Result := TDictionary<Integer, TArray<Integer>>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT l.NodeId, l.TagId ' +
      'FROM FS_PL_TaskTagLink l ' +
      'JOIN FS_PL_Node n ' +
      '  ON n.CodigoEmpresa = l.CodigoEmpresa AND n.NodeId = l.NodeId ' +
      'WHERE l.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
      'ORDER BY l.NodeId';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Open;
    while not Q.Eof do
    begin
      NodeId := Q.FieldByName('NodeId').AsInteger;
      if not Result.TryGetValue(NodeId, Lst) then
        SetLength(Lst, 0);
      SetLength(Lst, Length(Lst) + 1);
      Lst[High(Lst)] := Q.FieldByName('TagId').AsInteger;
      Result.AddOrSetValue(NodeId, Lst);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TWbsRepo.SaveTag(const ATag: TWbsTag): Integer;
var
  Q: TADOQuery;
begin
  Result := ATag.TagId;
  if Trim(ATag.Nombre) = '' then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    if ATag.TagId > 0 then
    begin
      Q.SQL.Text :=
        'UPDATE FS_PL_TaskTag SET Nombre = :N, Color = :C, Orden = :O ' +
        'WHERE CodigoEmpresa = :CE AND TagId = :TID';
      Q.Parameters.ParamByName('N').Value := ATag.Nombre;
      Q.Parameters.ParamByName('C').Value := ATag.Color;
      Q.Parameters.ParamByName('O').Value := ATag.Orden;
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('TID').Value := ATag.TagId;
      Q.ExecSQL;
    end
    else
    begin
      Q.SQL.Text :=
        'INSERT INTO FS_PL_TaskTag (CodigoEmpresa, Nombre, Color, Orden) ' +
        'VALUES (:CE, :N, :C, :O); SELECT SCOPE_IDENTITY() AS NuevoId;';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('N').Value := ATag.Nombre;
      Q.Parameters.ParamByName('C').Value := ATag.Color;
      Q.Parameters.ParamByName('O').Value := ATag.Orden;
      Q.Open;
      if not Q.Eof then Result := Q.Fields[0].AsInteger;
    end;
  finally
    Q.Free;
  end;
end;

procedure TWbsRepo.DeleteTag(ATagId: Integer);
var
  Q: TADOQuery;
begin
  if ATagId <= 0 then Exit;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    // Primero los enlaces: la FK de TaskTagLink no tiene CASCADE hacia el
    // catalogo (borrar una etiqueta es raro y conviene que sea explicito).
    Q.SQL.Text := 'DELETE FROM FS_PL_TaskTagLink ' +
      'WHERE CodigoEmpresa = :CE AND TagId = :TID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('TID').Value := ATagId;
    Q.ExecSQL;

    Q.SQL.Text := 'DELETE FROM FS_PL_TaskTag ' +
      'WHERE CodigoEmpresa = :CE AND TagId = :TID';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('TID').Value := ATagId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TWbsRepo.LoadProyectosTareas: TWbsProyectoArray;
var
  Q: TADOQuery;
  L: TList<TWbsProyecto>;
  P: TWbsProyecto;
begin
  L := TList<TWbsProyecto>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      // Solo proyectos del paradigma TAREAS: los de RECURSOS se ven en la
      // Vista Gantt de produccion, no aqui.
      Q.SQL.Text :=
        'SELECT ProjectId, ISNULL(Codigo, '''') AS Codigo, ' +
        '  ISNULL(Nombre, '''') AS Nombre ' +
        'FROM FS_PL_Project ' +
        'WHERE CodigoEmpresa = :CE AND PlanningParadigm = ''TAREAS'' ' +
        'ORDER BY Nombre, ProjectId';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        P := Default(TWbsProyecto);
        P.ProjectId := Q.FieldByName('ProjectId').AsInteger;
        P.Codigo := Q.FieldByName('Codigo').AsString;
        P.Nombre := Q.FieldByName('Nombre').AsString;
        if Trim(P.Nombre) = '' then
          P.Nombre := 'Proyecto ' + IntToStr(P.ProjectId);
        L.Add(P);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TWbsRepo.LoadLinks(AProjectId: Integer): TWbsLinkArray;
var
  Q: TADOQuery;
  L: TList<TWbsLink>;
  Lk: TWbsLink;
begin
  L := TList<TWbsLink>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT DependencyId, FromNodeId, ToNodeId, TipoLink, ' +
        '  ISNULL(LagMinutos, 0) AS LagMinutos ' +
        'FROM FS_PL_Dependency ' +
        'WHERE CodigoEmpresa = :CE AND ProjectId = :PID';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('PID').Value := AProjectId;
      Q.Open;
      while not Q.Eof do
      begin
        Lk.DependencyId := Q.FieldByName('DependencyId').AsInteger;
        Lk.ProjectId := AProjectId;
        Lk.FromNodeId := Q.FieldByName('FromNodeId').AsInteger;
        Lk.ToNodeId := Q.FieldByName('ToNodeId').AsInteger;
        Lk.LinkType := TWbsLinkType(Q.FieldByName('TipoLink').AsInteger);
        Lk.LagMinutos := Q.FieldByName('LagMinutos').AsInteger;
        L.Add(Lk);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

end.
