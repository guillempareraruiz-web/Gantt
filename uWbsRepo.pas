unit uWbsRepo;

// Repositorio de lectura del arbol WBS (Modulo de Proyectos, paradigma TAREAS).
// Lee las tareas (FS_PL_Node con atributos WBS de V078) y las dependencias
// (FS_PL_Dependency) de un proyecto, y devuelve las tareas YA ORDENADAS en
// recorrido de arbol (padre antes que hijos, hermanos por OrdenWBS), con Nivel
// y HasChildren calculados. Esa lista plana ordenada es directamente la entrada
// del grid WBS y del control de Gantt de tareas.
//
// Fase 1: solo lectura. La edicion (Fase 3) ira en un repo de escritura o se
// ampliara este.

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  System.Generics.Defaults,
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
        '  FechaInicio, FechaFin, DuracionMin ' +
        'FROM FS_PL_Node ' +
        'WHERE CodigoEmpresa = :CE AND ProjectId = :PID';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('PID').Value := AProjectId;
      Q.Open;
      while not Q.Eof do
      begin
        T := Default(TWbsTask);
        T.NodeId := Q.FieldByName('NodeId').AsInteger;
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
