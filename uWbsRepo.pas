unit uWbsRepo;

// Repositorio de lectura del arbol WBS (Modulo de Proyectos, paradigma TAREAS).
// Lee las tareas (FS_PL_Node con atributos WBS de V078) y las dependencias
// (FS_PL_Dependency) de un proyecto, y devuelve las tareas YA ORDENADAS en
// recorrido de arbol (padre antes que hijos, hermanos por OrdenWBS), con Nivel
// y HasChildren calculados. Esa lista plana ordenada es directamente la entrada
// del grid WBS y del control de Gantt de tareas.
//
// Escritura (Fase 3): Save* para los campos que el usuario edita a mano
// (tiempo invertido, duracion, fechas). Deliberadamente son updates de UNA
// columna: el resto del calculo (holguras, criticidad, avance de los
// resumenes) es VOLATIL y se recalcula, no se persiste.

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Math,
  System.Generics.Collections, System.Generics.Defaults,
  Data.Win.ADODB,
  uWbsTypes;

type
  TWbsRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    // Ordena recursivamente: mete AParentId y sus descendientes en AOut.
    procedure AppendSubtree(const AByParent: TDictionary<Integer, TList<TWbsTask>>;
      AParentId, ANivel: Integer; var AOut: TList<TWbsTask>);
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
    procedure SaveOperarios(ANodeId: Integer;
      const AOperarios: TWbsTaskOperarioArray);

    // Fecha fija: editar Inicio a mano equivale a poner una restriccion, para
    // que el motor la respete en vez de recalcularla por dependencias.
    procedure SaveRestriccionFecha(ANodeId: Integer; AKind: Integer;
      const AFecha: TDateTime);

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
        'SELECT NodeId, ISNULL(ParentTaskId, 0) AS ParentTaskId, ' +
        '  TaskKind, OrdenWBS, Collapsed, ISNULL(Caption, '''') AS Caption, ' +
        '  FechaInicio, FechaFin, DuracionMin, ' +
        '  ISNULL(ConstraintKind, 0) AS ConstraintKind, ConstraintDate, ' +
        '  ISNULL(MinutosInvertidos, 0) AS MinutosInvertidos ' +
        'FROM FS_PL_Node ' +
        'WHERE CodigoEmpresa = :CE AND ProjectId = :PID';
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
  const AOperarios: TWbsTaskOperarioArray);
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
