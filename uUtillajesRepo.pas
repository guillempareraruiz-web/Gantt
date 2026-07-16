unit uUtillajesRepo;

// Repositorio SQL para FS_PL_Utillaje (catalogo maestro de utillajes) y sus
// relaciones (FS_PL_UtillajeCenter / _Article / _Operation, V073).
//
// Consumido por uGestionUtillajes (listado), uUtillajeFicha (detalle),
// uUtillajePicker (modal seleccion) y uGanttAlertas (deteccion R02).
//
// El tipo TUtillaje vive en uUtillajeTypes.

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  Data.Win.ADODB, Data.DB,
  uUtillajeTypes;

type
  TUtillajesRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    function QStr(const S: string): string;
    function QStrNullable(const S: string): string;
    function QNum(const AValue: Double): string;
    function QDateNullable(AValue: TDateTime; AIsNull: Boolean): string;
    function QIntNullable(AValue: Integer): string;
    procedure Exec(const ASQL: string);
    procedure ReadFromQuery(Q: TADOQuery; out U: TUtillaje);
    function SelectList: string;
  public
    constructor Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt);

    function LoadAll: TArray<TUtillaje>;
    function LoadActive: TArray<TUtillaje>;
    function GetById(AId: Integer; out AUtil: TUtillaje): Boolean;
    function GetByCodigo(const ACodigo: string; out AUtil: TUtillaje): Boolean;

    function Insert(const AUtil: TUtillaje): Integer;
    procedure Update(const AUtil: TUtillaje);
    procedure Delete(AId: Integer);

    // True si el codigo ya existe en otro utillaje (AExcludeId = el que se edita).
    function CodigoExists(const ACodigo: string; AExcludeId: Integer): Boolean;

    // --- Relaciones (V073) ---
    function GetCentros(AUtillajeId: Integer): TArray<TUtillajeCentro>;
    procedure SaveCentros(AUtillajeId: Integer; const AItems: TArray<TUtillajeCentro>);

    function GetArticulos(AUtillajeId: Integer): TArray<TUtillajeArticulo>;
    procedure SaveArticulos(AUtillajeId: Integer; const AItems: TArray<TUtillajeArticulo>);

    function GetOperaciones(AUtillajeId: Integer): TArray<TUtillajeOperacion>;
    procedure SaveOperaciones(AUtillajeId: Integer; const AItems: TArray<TUtillajeOperacion>);

    // --- Requisitos por nodo (alerta R02) ---
    // Devuelve, para el proyecto dado, que utillajes requiere cada nodo (por
    // operacion o articulo) resolviendo la vista FS_PL_V_NodeUtillaje.
    // Una fila por (nodo, utillaje); NodeId = TNodeData.DataId.
    // Se carga de una vez: el detector de alertas lo consulta nodo a nodo y
    // una query por nodo seria inviable en planes grandes.
    function LoadRequisitosPorNodo(AProjectId: Integer)
      : TArray<TUtillajeRequisitoNodo>;

    // --- Reglas de requisito SIN nodo (planificacion) ---
    // Devuelve las reglas "operacion/articulo -> utillaje" del maestro, sin
    // pasar por los nodos. Necesario al PLANIFICAR: ahi los nodos aun no
    // existen, asi que LoadRequisitosPorNodo (que va por NodeId) no sirve.
    // Se carga UNA vez y se resuelve en memoria: RunAutoScheduling corre en
    // hilos del optimizador y no puede tocar la BD dentro del bucle.
    function LoadReglas: TArray<TUtillajeRegla>;

    // Carga en AOcc la capacidad de cada utillaje + la ocupacion que YA tiene
    // el proyecto (nodos planificados). Sin esto, una nueva tanda planificaria
    // encima de utillajes que ya estan comprometidos.
    procedure CargarOcupacion(AOcc: TUtillajeOccupancy; AProjectId: Integer);

    // --- Situacion calculada (listado) ---
    // Para cada utillaje del proyecto: si esta en uso AHORA, cuando queda
    // libre y que OFs dependen de el. Se CALCULA del plan, no se guarda en
    // BD: si se guardase, quedaria obsoleto en cuanto se mueve un nodo.
    // AAhora = instante de referencia (normalmente Now).
    function LoadSituaciones(AProjectId: Integer; AAhora: TDateTime)
      : TArray<TUtillajeSituacion>;
  end;

implementation

constructor TUtillajesRepo.Create(AConnection: TADOConnection;
  ACodigoEmpresa: SmallInt);
begin
  inherited Create;
  FConnection := AConnection;
  FCodigoEmpresa := ACodigoEmpresa;
end;

function TUtillajesRepo.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TUtillajesRepo.QStrNullable(const S: string): string;
begin
  if Trim(S) = '' then Result := 'NULL' else Result := QStr(S);
end;

function TUtillajesRepo.QNum(const AValue: Double): string;
var
  FS: TFormatSettings;
begin
  // Punto decimal siempre, independientemente del locale de la maquina.
  FS := TFormatSettings.Invariant;
  Result := FloatToStr(AValue, FS);
end;

function TUtillajesRepo.QDateNullable(AValue: TDateTime; AIsNull: Boolean): string;
begin
  if AIsNull or (AValue = 0) then
    Result := 'NULL'
  else
    Result := '''' + FormatDateTime('yyyy-mm-dd', AValue) + '''';
end;

function TUtillajesRepo.QIntNullable(AValue: Integer): string;
begin
  if AValue <= 0 then Result := 'NULL' else Result := IntToStr(AValue);
end;

procedure TUtillajesRepo.Exec(const ASQL: string);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText := ASQL;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

function TUtillajesRepo.SelectList: string;
begin
  Result :=
    'SELECT UtillajeId, Codigo, ISNULL(Descripcion, '''') AS Descripcion, ' +
    '  ISNULL(Tipo, '''') AS Tipo, ISNULL(Fabricante, '''') AS Fabricante, ' +
    '  ISNULL(NumeroSerie, '''') AS NumeroSerie, ' +
    '  ISNULL(AnyoFabricacion, 0) AS AnyoFabricacion, ' +
    '  ISNULL(Ubicacion, '''') AS Ubicacion, ' +
    '  ISNULL(CentroActualId, 0) AS CentroActualId, Estado, Cantidad, ' +
    '  TiempoMontaje, TiempoDesmontaje, TiempoAjuste, ' +
    '  UnidadVida, ContadorActual, VidaUtilTotal, FechaProxMantenimiento, ' +
    '  Disponible, DisponiblePlanificacion, ' +
    '  ISNULL(Observaciones, '''') AS Observaciones, Activo, Orden ' +
    'FROM FS_PL_Utillaje ';
end;

procedure TUtillajesRepo.ReadFromQuery(Q: TADOQuery; out U: TUtillaje);
begin
  U := Default(TUtillaje);
  U.Id := Q.FieldByName('UtillajeId').AsInteger;
  U.Codigo := Q.FieldByName('Codigo').AsString;
  U.Descripcion := Q.FieldByName('Descripcion').AsString;
  U.Tipo := Q.FieldByName('Tipo').AsString;

  U.Fabricante := Q.FieldByName('Fabricante').AsString;
  U.NumeroSerie := Q.FieldByName('NumeroSerie').AsString;
  U.AnyoFabricacion := Q.FieldByName('AnyoFabricacion').AsInteger;

  U.Ubicacion := Q.FieldByName('Ubicacion').AsString;
  U.CentroActualId := Q.FieldByName('CentroActualId').AsInteger;
  U.Estado := TEstadoUtillaje(Q.FieldByName('Estado').AsInteger);
  U.Cantidad := Q.FieldByName('Cantidad').AsInteger;

  U.TiempoMontaje := Q.FieldByName('TiempoMontaje').AsFloat;
  U.TiempoDesmontaje := Q.FieldByName('TiempoDesmontaje').AsFloat;
  U.TiempoAjuste := Q.FieldByName('TiempoAjuste').AsFloat;

  U.UnidadVida := TUnidadVida(Q.FieldByName('UnidadVida').AsInteger);
  U.ContadorActual := Q.FieldByName('ContadorActual').AsLargeInt;
  U.VidaUtilTotal := Q.FieldByName('VidaUtilTotal').AsLargeInt;

  U.FechaProxMantNull := Q.FieldByName('FechaProxMantenimiento').IsNull;
  if U.FechaProxMantNull then
    U.FechaProxMantenimiento := 0
  else
    U.FechaProxMantenimiento := Q.FieldByName('FechaProxMantenimiento').AsDateTime;

  U.Disponible := Q.FieldByName('Disponible').AsBoolean;
  U.DisponiblePlanificacion := Q.FieldByName('DisponiblePlanificacion').AsBoolean;
  U.Observaciones := Q.FieldByName('Observaciones').AsString;
  U.Activo := Q.FieldByName('Activo').AsBoolean;
  U.Orden := Q.FieldByName('Orden').AsInteger;
end;

function TUtillajesRepo.LoadAll: TArray<TUtillaje>;
var
  Q: TADOQuery;
  L: TList<TUtillaje>;
  U: TUtillaje;
begin
  L := TList<TUtillaje>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text := SelectList + 'WHERE CodigoEmpresa = :CE ORDER BY Orden, Codigo';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        ReadFromQuery(Q, U);
        L.Add(U);
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

function TUtillajesRepo.LoadActive: TArray<TUtillaje>;
var
  Q: TADOQuery;
  L: TList<TUtillaje>;
  U: TUtillaje;
begin
  L := TList<TUtillaje>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text := SelectList +
        'WHERE CodigoEmpresa = :CE AND Activo = 1 ORDER BY Orden, Codigo';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        ReadFromQuery(Q, U);
        L.Add(U);
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

function TUtillajesRepo.GetById(AId: Integer; out AUtil: TUtillaje): Boolean;
var
  Q: TADOQuery;
begin
  Result := False;
  AUtil := Default(TUtillaje);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := SelectList + 'WHERE CodigoEmpresa = :CE AND UtillajeId = :Id';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Id').Value := AId;
    Q.Open;
    if not Q.Eof then
    begin
      ReadFromQuery(Q, AUtil);
      Result := True;
    end;
  finally
    Q.Free;
  end;
end;

function TUtillajesRepo.GetByCodigo(const ACodigo: string;
  out AUtil: TUtillaje): Boolean;
var
  Q: TADOQuery;
begin
  Result := False;
  AUtil := Default(TUtillaje);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := SelectList + 'WHERE CodigoEmpresa = :CE AND Codigo = :Cod';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Cod').Value := ACodigo;
    Q.Open;
    if not Q.Eof then
    begin
      ReadFromQuery(Q, AUtil);
      Result := True;
    end;
  finally
    Q.Free;
  end;
end;

function TUtillajesRepo.CodigoExists(const ACodigo: string;
  AExcludeId: Integer): Boolean;
var
  Q: TADOQuery;
begin
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT TOP 1 UtillajeId FROM FS_PL_Utillaje ' +
      'WHERE CodigoEmpresa = :CE AND Codigo = :Cod AND UtillajeId <> :Id';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Cod').Value := ACodigo;
    Q.Parameters.ParamByName('Id').Value := AExcludeId;
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

function TUtillajesRepo.Insert(const AUtil: TUtillaje): Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'INSERT INTO FS_PL_Utillaje (CodigoEmpresa, Codigo, Descripcion, Tipo, ' +
      '  Fabricante, NumeroSerie, AnyoFabricacion, Ubicacion, CentroActualId, ' +
      '  Estado, Cantidad, TiempoMontaje, TiempoDesmontaje, TiempoAjuste, ' +
      '  UnidadVida, ContadorActual, VidaUtilTotal, FechaProxMantenimiento, ' +
      '  Disponible, DisponiblePlanificacion, Observaciones, Activo, Orden) ' +
      'OUTPUT INSERTED.UtillajeId ' +
      'VALUES (' + IntToStr(FCodigoEmpresa) + ', ' +
      QStr(AUtil.Codigo) + ', ' +
      QStrNullable(AUtil.Descripcion) + ', ' +
      QStrNullable(AUtil.Tipo) + ', ' +
      QStrNullable(AUtil.Fabricante) + ', ' +
      QStrNullable(AUtil.NumeroSerie) + ', ' +
      QIntNullable(AUtil.AnyoFabricacion) + ', ' +
      QStrNullable(AUtil.Ubicacion) + ', ' +
      QIntNullable(AUtil.CentroActualId) + ', ' +
      IntToStr(Ord(AUtil.Estado)) + ', ' +
      IntToStr(AUtil.Cantidad) + ', ' +
      QNum(AUtil.TiempoMontaje) + ', ' +
      QNum(AUtil.TiempoDesmontaje) + ', ' +
      QNum(AUtil.TiempoAjuste) + ', ' +
      IntToStr(Ord(AUtil.UnidadVida)) + ', ' +
      IntToStr(AUtil.ContadorActual) + ', ' +
      IntToStr(AUtil.VidaUtilTotal) + ', ' +
      QDateNullable(AUtil.FechaProxMantenimiento, AUtil.FechaProxMantNull) + ', ' +
      IntToStr(Ord(AUtil.Disponible)) + ', ' +
      IntToStr(Ord(AUtil.DisponiblePlanificacion)) + ', ' +
      QStrNullable(AUtil.Observaciones) + ', ' +
      IntToStr(Ord(AUtil.Activo)) + ', ' +
      IntToStr(AUtil.Orden) + ')';
    Q.Open;
    if not Q.Eof then Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TUtillajesRepo.Update(const AUtil: TUtillaje);
begin
  Exec(
    'UPDATE FS_PL_Utillaje SET ' +
    '  Codigo = ' + QStr(AUtil.Codigo) + ', ' +
    '  Descripcion = ' + QStrNullable(AUtil.Descripcion) + ', ' +
    '  Tipo = ' + QStrNullable(AUtil.Tipo) + ', ' +
    '  Fabricante = ' + QStrNullable(AUtil.Fabricante) + ', ' +
    '  NumeroSerie = ' + QStrNullable(AUtil.NumeroSerie) + ', ' +
    '  AnyoFabricacion = ' + QIntNullable(AUtil.AnyoFabricacion) + ', ' +
    '  Ubicacion = ' + QStrNullable(AUtil.Ubicacion) + ', ' +
    '  CentroActualId = ' + QIntNullable(AUtil.CentroActualId) + ', ' +
    '  Estado = ' + IntToStr(Ord(AUtil.Estado)) + ', ' +
    '  Cantidad = ' + IntToStr(AUtil.Cantidad) + ', ' +
    '  TiempoMontaje = ' + QNum(AUtil.TiempoMontaje) + ', ' +
    '  TiempoDesmontaje = ' + QNum(AUtil.TiempoDesmontaje) + ', ' +
    '  TiempoAjuste = ' + QNum(AUtil.TiempoAjuste) + ', ' +
    '  UnidadVida = ' + IntToStr(Ord(AUtil.UnidadVida)) + ', ' +
    '  ContadorActual = ' + IntToStr(AUtil.ContadorActual) + ', ' +
    '  VidaUtilTotal = ' + IntToStr(AUtil.VidaUtilTotal) + ', ' +
    '  FechaProxMantenimiento = ' +
        QDateNullable(AUtil.FechaProxMantenimiento, AUtil.FechaProxMantNull) + ', ' +
    '  Disponible = ' + IntToStr(Ord(AUtil.Disponible)) + ', ' +
    '  DisponiblePlanificacion = ' + IntToStr(Ord(AUtil.DisponiblePlanificacion)) + ', ' +
    '  Observaciones = ' + QStrNullable(AUtil.Observaciones) + ', ' +
    '  Activo = ' + IntToStr(Ord(AUtil.Activo)) + ', ' +
    '  Orden = ' + IntToStr(AUtil.Orden) + ', ' +
    '  FechaModificacion = SYSDATETIME() ' +
    'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
    '  AND UtillajeId = ' + IntToStr(AUtil.Id));
end;

procedure TUtillajesRepo.Delete(AId: Integer);
begin
  // Las relaciones (Center/Article/Operation) caen por ON DELETE CASCADE.
  Exec('DELETE FROM FS_PL_Utillaje WHERE CodigoEmpresa = ' +
    IntToStr(FCodigoEmpresa) + ' AND UtillajeId = ' + IntToStr(AId));
end;

// ---------------------------------------------------------------------------
// Relaciones. Patron: borrar todo e reinsertar dentro de una transaccion,
// igual que uMoldeRepoSQL.
// ---------------------------------------------------------------------------

function TUtillajesRepo.GetCentros(AUtillajeId: Integer): TArray<TUtillajeCentro>;
var
  Q: TADOQuery;
  L: TList<TUtillajeCentro>;
  R: TUtillajeCentro;
begin
  L := TList<TUtillajeCentro>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT UtillajeId, CenterId, Preferente, TiempoMontajeEspecifico ' +
        'FROM FS_PL_UtillajeCenter ' +
        'WHERE CodigoEmpresa = :CE AND UtillajeId = :Id';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('Id').Value := AUtillajeId;
      Q.Open;
      while not Q.Eof do
      begin
        R.UtillajeId := Q.FieldByName('UtillajeId').AsInteger;
        R.CenterId := Q.FieldByName('CenterId').AsInteger;
        R.Preferente := Q.FieldByName('Preferente').AsBoolean;
        R.TiempoMontajeEspecifico := Q.FieldByName('TiempoMontajeEspecifico').AsFloat;
        L.Add(R);
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

procedure TUtillajesRepo.SaveCentros(AUtillajeId: Integer;
  const AItems: TArray<TUtillajeCentro>);
var
  I: Integer;
begin
  FConnection.BeginTrans;
  try
    Exec('DELETE FROM FS_PL_UtillajeCenter WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa) + ' AND UtillajeId = ' + IntToStr(AUtillajeId));

    for I := 0 to High(AItems) do
      Exec('INSERT INTO FS_PL_UtillajeCenter (CodigoEmpresa, UtillajeId, ' +
        'CenterId, Preferente, TiempoMontajeEspecifico) VALUES (' +
        IntToStr(FCodigoEmpresa) + ', ' +
        IntToStr(AUtillajeId) + ', ' +
        IntToStr(AItems[I].CenterId) + ', ' +
        IntToStr(Ord(AItems[I].Preferente)) + ', ' +
        QNum(AItems[I].TiempoMontajeEspecifico) + ')');

    FConnection.CommitTrans;
  except
    FConnection.RollbackTrans;
    raise;
  end;
end;

function TUtillajesRepo.GetArticulos(AUtillajeId: Integer): TArray<TUtillajeArticulo>;
var
  Q: TADOQuery;
  L: TList<TUtillajeArticulo>;
  R: TUtillajeArticulo;
begin
  L := TList<TUtillajeArticulo>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT UtillajeId, CodigoArticulo, Obligatorio, ' +
        '  ISNULL(Observaciones, '''') AS Observaciones ' +
        'FROM FS_PL_UtillajeArticle ' +
        'WHERE CodigoEmpresa = :CE AND UtillajeId = :Id ORDER BY CodigoArticulo';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('Id').Value := AUtillajeId;
      Q.Open;
      while not Q.Eof do
      begin
        R.UtillajeId := Q.FieldByName('UtillajeId').AsInteger;
        R.CodigoArticulo := Q.FieldByName('CodigoArticulo').AsString;
        R.Obligatorio := Q.FieldByName('Obligatorio').AsBoolean;
        R.Observaciones := Q.FieldByName('Observaciones').AsString;
        L.Add(R);
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

procedure TUtillajesRepo.SaveArticulos(AUtillajeId: Integer;
  const AItems: TArray<TUtillajeArticulo>);
var
  I: Integer;
begin
  FConnection.BeginTrans;
  try
    Exec('DELETE FROM FS_PL_UtillajeArticle WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa) + ' AND UtillajeId = ' + IntToStr(AUtillajeId));

    for I := 0 to High(AItems) do
    begin
      if Trim(AItems[I].CodigoArticulo) = '' then Continue;
      Exec('INSERT INTO FS_PL_UtillajeArticle (CodigoEmpresa, UtillajeId, ' +
        'CodigoArticulo, Obligatorio, Observaciones) VALUES (' +
        IntToStr(FCodigoEmpresa) + ', ' +
        IntToStr(AUtillajeId) + ', ' +
        QStr(Trim(AItems[I].CodigoArticulo)) + ', ' +
        IntToStr(Ord(AItems[I].Obligatorio)) + ', ' +
        QStrNullable(AItems[I].Observaciones) + ')');
    end;

    FConnection.CommitTrans;
  except
    FConnection.RollbackTrans;
    raise;
  end;
end;

function TUtillajesRepo.GetOperaciones(AUtillajeId: Integer): TArray<TUtillajeOperacion>;
var
  Q: TADOQuery;
  L: TList<TUtillajeOperacion>;
  R: TUtillajeOperacion;
begin
  L := TList<TUtillajeOperacion>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT UtillajeId, Operacion, Obligatorio, ' +
        '  ISNULL(Observaciones, '''') AS Observaciones ' +
        'FROM FS_PL_UtillajeOperation ' +
        'WHERE CodigoEmpresa = :CE AND UtillajeId = :Id ORDER BY Operacion';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('Id').Value := AUtillajeId;
      Q.Open;
      while not Q.Eof do
      begin
        R.UtillajeId := Q.FieldByName('UtillajeId').AsInteger;
        R.Operacion := Q.FieldByName('Operacion').AsString;
        R.Obligatorio := Q.FieldByName('Obligatorio').AsBoolean;
        R.Observaciones := Q.FieldByName('Observaciones').AsString;
        L.Add(R);
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

procedure TUtillajesRepo.SaveOperaciones(AUtillajeId: Integer;
  const AItems: TArray<TUtillajeOperacion>);
var
  I: Integer;
begin
  FConnection.BeginTrans;
  try
    Exec('DELETE FROM FS_PL_UtillajeOperation WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa) + ' AND UtillajeId = ' + IntToStr(AUtillajeId));

    for I := 0 to High(AItems) do
    begin
      if Trim(AItems[I].Operacion) = '' then Continue;
      Exec('INSERT INTO FS_PL_UtillajeOperation (CodigoEmpresa, UtillajeId, ' +
        'Operacion, Obligatorio, Observaciones) VALUES (' +
        IntToStr(FCodigoEmpresa) + ', ' +
        IntToStr(AUtillajeId) + ', ' +
        QStr(Trim(AItems[I].Operacion)) + ', ' +
        IntToStr(Ord(AItems[I].Obligatorio)) + ', ' +
        QStrNullable(AItems[I].Observaciones) + ')');
    end;

    FConnection.CommitTrans;
  except
    FConnection.RollbackTrans;
    raise;
  end;
end;

function TUtillajesRepo.LoadRequisitosPorNodo(AProjectId: Integer)
  : TArray<TUtillajeRequisitoNodo>;
var
  Q: TADOQuery;
  L: TList<TUtillajeRequisitoNodo>;
  RN: TUtillajeRequisitoNodo;
begin
  L := TList<TUtillajeRequisitoNodo>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      // Solo utillajes que el motor debe respetar: obligatorios y disponibles
      // para planificar. Un utillaje en mantenimiento/averiado no genera
      // conflicto porque directamente no deberia estar en uso.
      Q.SQL.Text :=
        'SELECT v.NodeId, v.UtillajeId, v.CodigoUtillaje, v.Cantidad ' +
        'FROM FS_PL_V_NodeUtillaje v ' +
        'JOIN FS_PL_Utillaje u ' +
        '  ON u.CodigoEmpresa = v.CodigoEmpresa AND u.UtillajeId = v.UtillajeId ' +
        'WHERE v.CodigoEmpresa = :CE AND v.ProjectId = :PID ' +
        '  AND v.Obligatorio = 1 AND u.DisponiblePlanificacion = 1 ' +
        'ORDER BY v.NodeId';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('PID').Value := AProjectId;
      Q.Open;

      while not Q.Eof do
      begin
        RN.NodeId := Q.FieldByName('NodeId').AsInteger;
        RN.Req.UtillajeId := Q.FieldByName('UtillajeId').AsInteger;
        RN.Req.Codigo := Q.FieldByName('CodigoUtillaje').AsString;
        RN.Req.Cantidad := Q.FieldByName('Cantidad').AsInteger;
        L.Add(RN);
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

function TUtillajesRepo.LoadReglas: TArray<TUtillajeRegla>;
var
  Q: TADOQuery;
  L: TList<TUtillajeRegla>;
  R: TUtillajeRegla;
begin
  L := TList<TUtillajeRegla>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      // Solo lo que el motor debe respetar: obligatorio, utillaje activo y
      // disponible para planificar. Un utillaje en mantenimiento/averiado no
      // restringe porque directamente no deberia estar en uso.
      Q.SQL.Text :=
        'SELECT uo.Operacion AS Clave, 1 AS PorOperacion, ' +
        '       u.UtillajeId, u.Codigo, u.Cantidad ' +
        'FROM FS_PL_UtillajeOperation uo ' +
        'JOIN FS_PL_Utillaje u ON u.CodigoEmpresa = uo.CodigoEmpresa ' +
        '     AND u.UtillajeId = uo.UtillajeId ' +
        'WHERE uo.CodigoEmpresa = :CE AND uo.Obligatorio = 1 ' +
        '  AND u.Activo = 1 AND u.DisponiblePlanificacion = 1 ' +
        'UNION ALL ' +
        'SELECT ua.CodigoArticulo AS Clave, 0 AS PorOperacion, ' +
        '       u.UtillajeId, u.Codigo, u.Cantidad ' +
        'FROM FS_PL_UtillajeArticle ua ' +
        'JOIN FS_PL_Utillaje u ON u.CodigoEmpresa = ua.CodigoEmpresa ' +
        '     AND u.UtillajeId = ua.UtillajeId ' +
        'WHERE ua.CodigoEmpresa = :CE2 AND ua.Obligatorio = 1 ' +
        '  AND u.Activo = 1 AND u.DisponiblePlanificacion = 1';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('CE2').Value := FCodigoEmpresa;
      Q.Open;

      while not Q.Eof do
      begin
        R.Clave := Trim(Q.FieldByName('Clave').AsString);
        R.PorOperacion := Q.FieldByName('PorOperacion').AsInteger = 1;
        R.Req.UtillajeId := Q.FieldByName('UtillajeId').AsInteger;
        R.Req.Codigo := Q.FieldByName('Codigo').AsString;
        R.Req.Cantidad := Q.FieldByName('Cantidad').AsInteger;
        if R.Clave <> '' then L.Add(R);
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

procedure TUtillajesRepo.CargarOcupacion(AOcc: TUtillajeOccupancy;
  AProjectId: Integer);
var
  Q: TADOQuery;
begin
  if AOcc = nil then Exit;

  // 1. Capacidades del maestro (ejemplares por utillaje).
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT UtillajeId, Cantidad FROM FS_PL_Utillaje ' +
      'WHERE CodigoEmpresa = :CE AND Activo = 1 AND DisponiblePlanificacion = 1';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      AOcc.SetCantidad(Q.FieldByName('UtillajeId').AsInteger,
        Q.FieldByName('Cantidad').AsInteger);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  // 2. Ocupacion ya comprometida por los nodos planificados del proyecto.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT v.UtillajeId, n.FechaInicio, n.FechaFin ' +
      'FROM FS_PL_V_NodeUtillaje v ' +
      'JOIN FS_PL_Node n ON n.CodigoEmpresa = v.CodigoEmpresa ' +
      '     AND n.NodeId = v.NodeId ' +
      'WHERE v.CodigoEmpresa = :CE AND v.ProjectId = :PID ' +
      '  AND v.Obligatorio = 1 ' +
      '  AND n.FechaInicio IS NOT NULL AND n.FechaFin > n.FechaInicio';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Open;
    while not Q.Eof do
    begin
      AOcc.Ocupar(Q.FieldByName('UtillajeId').AsInteger,
        Q.FieldByName('FechaInicio').AsDateTime,
        Q.FieldByName('FechaFin').AsDateTime);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TUtillajesRepo.LoadSituaciones(AProjectId: Integer; AAhora: TDateTime)
  : TArray<TUtillajeSituacion>;
var
  Q: TADOQuery;
  L: TList<TUtillajeSituacion>;
  S: TUtillajeSituacion;
  OFs: string;
  SL: TStringList;
  K: Integer;
begin
  L := TList<TUtillajeSituacion>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      // Un solo agregado por utillaje:
      //   NodosAhora   = nodos que lo ocupan en el instante :AHORA
      //   NodosFuturos = nodos que empiezan despues
      //   LibreDesde   = fin del ultimo nodo en curso (NULL si no hay ninguno)
      //   OFs          = lista de OFs implicadas (las 10 primeras)
      // El instante se declara UNA vez como variable T-SQL en vez de repetir un
      // parametro 5 veces: ADO usa parametros posicionales y repetir :AHORA
      // obligaria a asignarlo por indice. Asi la consulta es literal y solo
      // quedan 3 parametros reales.
      // SET NOCOUNT ON: sin el, el DECLARE emite un mensaje de conteo que OLE DB
      // puede presentar como un primer recordset vacio, y Q.Open se quedaria
      // enganchado a el en vez de al SELECT (mismo patron que ExecNoRec en
      // uDemoPlanEngine / uBulkNodePersist).
      Q.SQL.Text :=
        'SET NOCOUNT ON; ' +
        'DECLARE @AHORA DATETIME2 = :AHORA; ' +
        'WITH Uso AS ( ' +
        '  SELECT v.UtillajeId, n.NodeId, n.FechaInicio, n.FechaFin, ' +
        '         nd.NumeroOF, nd.SerieOF ' +
        '  FROM FS_PL_V_NodeUtillaje v ' +
        '  JOIN FS_PL_Node n ON n.CodigoEmpresa = v.CodigoEmpresa ' +
        '       AND n.NodeId = v.NodeId ' +
        '  LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
        '       AND nd.NodeId = n.NodeId ' +
        '  WHERE v.CodigoEmpresa = :CE AND v.ProjectId = :PID ' +
        '    AND n.FechaInicio IS NOT NULL AND n.FechaFin > n.FechaInicio ' +
        ') ' +
        'SELECT u.UtillajeId, ' +
        '  ISNULL(SUM(CASE WHEN x.FechaInicio <= @AHORA ' +
        '                   AND x.FechaFin > @AHORA THEN 1 ELSE 0 END), 0) AS NodosAhora, ' +
        '  ISNULL(SUM(CASE WHEN x.FechaInicio > @AHORA THEN 1 ELSE 0 END), 0) AS NodosFuturos, ' +
        '  MAX(CASE WHEN x.FechaInicio <= @AHORA AND x.FechaFin > @AHORA ' +
        '           THEN x.FechaFin END) AS LibreDesde, ' +
        // Concatenacion de OFs. Se usa FOR XML PATH (no STRING_AGG) para no
        // exigir SQL Server 2017+, y se cierra con .value() para DESHACER el
        // escapado XML: sin el, una serie con '&' saldria como '&amp;'.
        // ORDER BY explicito: sin el, el TOP 10 elige filas arbitrarias.
        '  STUFF(( SELECT DISTINCT TOP 10 '', '' + ' +
        '            CAST(y.NumeroOF AS NVARCHAR(20)) + ' +
        '            CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(y.SerieOF, ''''))), '''') IS NULL ' +
        '                 THEN '''' ELSE ''/'' + y.SerieOF END ' +
        '          FROM Uso y ' +
        '          WHERE y.UtillajeId = u.UtillajeId ' +
        '            AND y.NumeroOF IS NOT NULL AND y.NumeroOF > 0 ' +
        '          ORDER BY 1 ' +
        '          FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), ' +
        '        1, 2, '''') AS OFs ' +
        'FROM FS_PL_Utillaje u ' +
        'LEFT JOIN Uso x ON x.UtillajeId = u.UtillajeId ' +
        'WHERE u.CodigoEmpresa = :CE2 ' +
        'GROUP BY u.UtillajeId';

      Q.Parameters.ParamByName('AHORA').Value := AAhora;
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('PID').Value := AProjectId;
      Q.Parameters.ParamByName('CE2').Value := FCodigoEmpresa;
      Q.Open;

      while not Q.Eof do
      begin
        S := Default(TUtillajeSituacion);
        S.UtillajeId := Q.FieldByName('UtillajeId').AsInteger;
        S.NodosAhora := Q.FieldByName('NodosAhora').AsInteger;
        S.NodosFuturos := Q.FieldByName('NodosFuturos').AsInteger;

        if Q.FieldByName('LibreDesde').IsNull then
          S.LibreDesde := 0
        else
          S.LibreDesde := Q.FieldByName('LibreDesde').AsDateTime;

        if S.NodosAhora > 0 then
          S.Situacion := suEnUso
        else if S.NodosFuturos > 0 then
          S.Situacion := suReservado
        else
          S.Situacion := suLibre;

        // La consulta devuelve las OFs ya formateadas y separadas por ", ".
        // Se trocean con TStringList (CommaText no sirve: los codigos pueden
        // llevar '/'), evitando depender del overload de TStringHelper.Split
        // con separadores de mas de un caracter.
        OFs := Q.FieldByName('OFs').AsString;
        if Trim(OFs) <> '' then
        begin
          SL := TStringList.Create;
          try
            SL.StrictDelimiter := True;
            SL.Delimiter := ',';
            SL.DelimitedText := OFs;
            SetLength(S.OFsAfectadas, SL.Count);
            for K := 0 to SL.Count - 1 do
              S.OFsAfectadas[K] := Trim(SL[K]);
          finally
            SL.Free;
          end;
        end;

        L.Add(S);
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
