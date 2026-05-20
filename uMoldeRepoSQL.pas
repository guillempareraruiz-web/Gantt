unit uMoldeRepoSQL;

// Repositorio SQL real para FS_PL_Mold y sus relaciones.
// Separado de uMoldeRepo (in-memory, usado por sample data generator).
// Lo consumen los CRUDs: uGestionMoldes, uAsignarCentrosMolde, uEditarListaMolde.

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  Data.Win.ADODB, Data.DB,
  uMoldeTypes;

type
  TMoldeRow = record
    Id: Integer;
    Codigo: string;
    Descripcion: string;
    TipoMolde: TTipoMolde;
    Estado: TEstadoMolde;
    UbicacionActual: string;
    CentroActualId: Integer;          // 0 = sin centro
    NumeroCavidades: Integer;
    TiempoMontaje: Double;
    TiempoDesmontaje: Double;
    TiempoAjuste: Double;
    CiclosAcumulados: Integer;
    FechaProxMantenimiento: TDateTime;
    FechaProxMantNull: Boolean;
    DisponiblePlanificacion: Boolean;
    Observaciones: string;
  end;

  TMoldeCenterRow = record
    CenterId: Integer;
    Preferente: Boolean;
    TiempoMontajeEspecifico: Double;
  end;

  TMoldeArticleRow = record
    CodigoArticulo: string;
    CavidadesActivas: Integer;
    Observaciones: string;
  end;

  TMoldeOperationRow = record
    Operacion: string;
    CiclosPorUnidad: Double;
    Observaciones: string;
  end;

  TMoldeUtillajeRow = record
    CodigoUtillaje: string;
    Obligatorio: Boolean;
    Observaciones: string;
  end;

  TMoldeRepoSQL = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    function QStr(const S: string): string;
    function QStrNullable(const S: string): string;
    function QDecimal(D: Double): string;
    function QDateNullable(D: TDateTime; IsNull: Boolean): string;
    procedure Exec(const ASQL: string);
  public
    constructor Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt);

    // Moldes
    function LoadAll: TArray<TMoldeRow>;
    function Insert(const ARow: TMoldeRow): Integer;
    procedure Update(const ARow: TMoldeRow);
    procedure Delete(AId: Integer);

    // Relaciones Molde-Centro
    function GetCentros(AMoldId: Integer): TArray<TMoldeCenterRow>;
    procedure SaveCentros(AMoldId: Integer; const ARows: TArray<TMoldeCenterRow>);

    // Relaciones Molde-Articulo
    function GetArticulos(AMoldId: Integer): TArray<TMoldeArticleRow>;
    procedure SaveArticulos(AMoldId: Integer; const ARows: TArray<TMoldeArticleRow>);

    // Relaciones Molde-Operacion
    function GetOperaciones(AMoldId: Integer): TArray<TMoldeOperationRow>;
    procedure SaveOperaciones(AMoldId: Integer; const ARows: TArray<TMoldeOperationRow>);

    // Relaciones Molde-Utillaje
    function GetUtillajes(AMoldId: Integer): TArray<TMoldeUtillajeRow>;
    procedure SaveUtillajes(AMoldId: Integer; const ARows: TArray<TMoldeUtillajeRow>);
  end;

implementation

constructor TMoldeRepoSQL.Create(AConnection: TADOConnection;
  ACodigoEmpresa: SmallInt);
begin
  inherited Create;
  FConnection := AConnection;
  FCodigoEmpresa := ACodigoEmpresa;
end;

function TMoldeRepoSQL.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TMoldeRepoSQL.QStrNullable(const S: string): string;
begin
  if Trim(S) = '' then Result := 'NULL' else Result := QStr(S);
end;

function TMoldeRepoSQL.QDecimal(D: Double): string;
begin
  Result := FloatToStr(D, TFormatSettings.Invariant);
end;

function TMoldeRepoSQL.QDateNullable(D: TDateTime; IsNull: Boolean): string;
begin
  if IsNull or (D = 0) then Result := 'NULL'
  else Result := '''' + FormatDateTime('yyyy-mm-dd', D) + '''';
end;

procedure TMoldeRepoSQL.Exec(const ASQL: string);
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

// ---------------------------------------------------------------------------
// Moldes
// ---------------------------------------------------------------------------

function TMoldeRepoSQL.LoadAll: TArray<TMoldeRow>;
var
  Q: TADOQuery;
  L: TList<TMoldeRow>;
  R: TMoldeRow;
  F: TField;
begin
  L := TList<TMoldeRow>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT MoldId, Codigo, ISNULL(Descripcion, '''') AS Descripcion, ' +
        '  TipoMolde, Estado, ISNULL(UbicacionActual, '''') AS UbicacionActual, ' +
        '  CentroActualId, NumeroCavidades, ' +
        '  ISNULL(TiempoMontaje, 0) AS TiempoMontaje, ' +
        '  ISNULL(TiempoDesmontaje, 0) AS TiempoDesmontaje, ' +
        '  ISNULL(TiempoAjuste, 0) AS TiempoAjuste, ' +
        '  CiclosAcumulados, FechaProxMantenimiento, ' +
        '  DisponiblePlanificacion, ISNULL(Observaciones, '''') AS Observaciones ' +
        'FROM FS_PL_Mold ' +
        'WHERE CodigoEmpresa = :CE ' +
        'ORDER BY Codigo';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        R.Id := Q.FieldByName('MoldId').AsInteger;
        R.Codigo := Q.FieldByName('Codigo').AsString;
        R.Descripcion := Q.FieldByName('Descripcion').AsString;
        R.TipoMolde := TTipoMolde(Q.FieldByName('TipoMolde').AsInteger);
        R.Estado := TEstadoMolde(Q.FieldByName('Estado').AsInteger);
        R.UbicacionActual := Q.FieldByName('UbicacionActual').AsString;
        F := Q.FieldByName('CentroActualId');
        if F.IsNull then R.CentroActualId := 0 else R.CentroActualId := F.AsInteger;
        R.NumeroCavidades := Q.FieldByName('NumeroCavidades').AsInteger;
        R.TiempoMontaje := Q.FieldByName('TiempoMontaje').AsFloat;
        R.TiempoDesmontaje := Q.FieldByName('TiempoDesmontaje').AsFloat;
        R.TiempoAjuste := Q.FieldByName('TiempoAjuste').AsFloat;
        R.CiclosAcumulados := Q.FieldByName('CiclosAcumulados').AsInteger;
        F := Q.FieldByName('FechaProxMantenimiento');
        R.FechaProxMantNull := F.IsNull;
        if F.IsNull then R.FechaProxMantenimiento := 0
        else R.FechaProxMantenimiento := F.AsDateTime;
        R.DisponiblePlanificacion := Q.FieldByName('DisponiblePlanificacion').AsBoolean;
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

function TMoldeRepoSQL.Insert(const ARow: TMoldeRow): Integer;
var
  Q: TADOQuery;
  CentroSql: string;
begin
  Result := 0;
  if ARow.CentroActualId <= 0 then CentroSql := 'NULL'
  else CentroSql := IntToStr(ARow.CentroActualId);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'INSERT INTO FS_PL_Mold (CodigoEmpresa, Codigo, Descripcion, TipoMolde, Estado, ' +
      '  UbicacionActual, CentroActualId, NumeroCavidades, TiempoMontaje, TiempoDesmontaje, ' +
      '  TiempoAjuste, CiclosAcumulados, FechaProxMantenimiento, DisponiblePlanificacion, Observaciones) ' +
      'OUTPUT INSERTED.MoldId ' +
      'VALUES (' + IntToStr(FCodigoEmpresa) + ', ' +
      QStr(ARow.Codigo) + ', ' +
      QStrNullable(ARow.Descripcion) + ', ' +
      IntToStr(Ord(ARow.TipoMolde)) + ', ' +
      IntToStr(Ord(ARow.Estado)) + ', ' +
      QStrNullable(ARow.UbicacionActual) + ', ' +
      CentroSql + ', ' +
      IntToStr(ARow.NumeroCavidades) + ', ' +
      QDecimal(ARow.TiempoMontaje) + ', ' +
      QDecimal(ARow.TiempoDesmontaje) + ', ' +
      QDecimal(ARow.TiempoAjuste) + ', ' +
      IntToStr(ARow.CiclosAcumulados) + ', ' +
      QDateNullable(ARow.FechaProxMantenimiento, ARow.FechaProxMantNull) + ', ' +
      IntToStr(Ord(ARow.DisponiblePlanificacion)) + ', ' +
      QStrNullable(ARow.Observaciones) + ')';
    Q.Open;
    if not Q.Eof then Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TMoldeRepoSQL.Update(const ARow: TMoldeRow);
var
  CentroSql: string;
begin
  if ARow.CentroActualId <= 0 then CentroSql := 'NULL'
  else CentroSql := IntToStr(ARow.CentroActualId);

  Exec(
    'UPDATE FS_PL_Mold SET ' +
    '  Codigo = ' + QStr(ARow.Codigo) + ', ' +
    '  Descripcion = ' + QStrNullable(ARow.Descripcion) + ', ' +
    '  TipoMolde = ' + IntToStr(Ord(ARow.TipoMolde)) + ', ' +
    '  Estado = ' + IntToStr(Ord(ARow.Estado)) + ', ' +
    '  UbicacionActual = ' + QStrNullable(ARow.UbicacionActual) + ', ' +
    '  CentroActualId = ' + CentroSql + ', ' +
    '  NumeroCavidades = ' + IntToStr(ARow.NumeroCavidades) + ', ' +
    '  TiempoMontaje = ' + QDecimal(ARow.TiempoMontaje) + ', ' +
    '  TiempoDesmontaje = ' + QDecimal(ARow.TiempoDesmontaje) + ', ' +
    '  TiempoAjuste = ' + QDecimal(ARow.TiempoAjuste) + ', ' +
    '  CiclosAcumulados = ' + IntToStr(ARow.CiclosAcumulados) + ', ' +
    '  FechaProxMantenimiento = ' + QDateNullable(ARow.FechaProxMantenimiento, ARow.FechaProxMantNull) + ', ' +
    '  DisponiblePlanificacion = ' + IntToStr(Ord(ARow.DisponiblePlanificacion)) + ', ' +
    '  Observaciones = ' + QStrNullable(ARow.Observaciones) + ' ' +
    'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
    '  AND MoldId = ' + IntToStr(ARow.Id));
end;

procedure TMoldeRepoSQL.Delete(AId: Integer);
begin
  Exec('DELETE FROM FS_PL_Mold WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
    ' AND MoldId = ' + IntToStr(AId));
end;

// ---------------------------------------------------------------------------
// Relacion Molde-Centro
// ---------------------------------------------------------------------------

function TMoldeRepoSQL.GetCentros(AMoldId: Integer): TArray<TMoldeCenterRow>;
var
  Q: TADOQuery;
  L: TList<TMoldeCenterRow>;
  R: TMoldeCenterRow;
begin
  L := TList<TMoldeCenterRow>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT CenterId, Preferente, TiempoMontajeEspecifico ' +
        'FROM FS_PL_MoldCenter ' +
        'WHERE CodigoEmpresa = :CE AND MoldId = :MoldId ' +
        'ORDER BY CenterId';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('MoldId').Value := AMoldId;
      Q.Open;
      while not Q.Eof do
      begin
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

procedure TMoldeRepoSQL.SaveCentros(AMoldId: Integer;
  const ARows: TArray<TMoldeCenterRow>);
var
  I: Integer;
begin
  FConnection.BeginTrans;
  try
    Exec('DELETE FROM FS_PL_MoldCenter WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa) + ' AND MoldId = ' + IntToStr(AMoldId));
    for I := 0 to High(ARows) do
      Exec('INSERT INTO FS_PL_MoldCenter (CodigoEmpresa, MoldId, CenterId, Preferente, TiempoMontajeEspecifico) VALUES (' +
        IntToStr(FCodigoEmpresa) + ', ' +
        IntToStr(AMoldId) + ', ' +
        IntToStr(ARows[I].CenterId) + ', ' +
        IntToStr(Ord(ARows[I].Preferente)) + ', ' +
        QDecimal(ARows[I].TiempoMontajeEspecifico) + ')');
    FConnection.CommitTrans;
  except
    FConnection.RollbackTrans;
    raise;
  end;
end;

// ---------------------------------------------------------------------------
// Relacion Molde-Articulo
// ---------------------------------------------------------------------------

function TMoldeRepoSQL.GetArticulos(AMoldId: Integer): TArray<TMoldeArticleRow>;
var
  Q: TADOQuery;
  L: TList<TMoldeArticleRow>;
  R: TMoldeArticleRow;
begin
  L := TList<TMoldeArticleRow>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT CodigoArticulo, CavidadesActivas, ISNULL(Observaciones, '''') AS Observaciones ' +
        'FROM FS_PL_MoldArticle ' +
        'WHERE CodigoEmpresa = :CE AND MoldId = :MoldId ' +
        'ORDER BY CodigoArticulo';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('MoldId').Value := AMoldId;
      Q.Open;
      while not Q.Eof do
      begin
        R.CodigoArticulo := Q.FieldByName('CodigoArticulo').AsString;
        R.CavidadesActivas := Q.FieldByName('CavidadesActivas').AsInteger;
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

procedure TMoldeRepoSQL.SaveArticulos(AMoldId: Integer;
  const ARows: TArray<TMoldeArticleRow>);
var
  I: Integer;
begin
  FConnection.BeginTrans;
  try
    Exec('DELETE FROM FS_PL_MoldArticle WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa) + ' AND MoldId = ' + IntToStr(AMoldId));
    for I := 0 to High(ARows) do
      Exec('INSERT INTO FS_PL_MoldArticle (CodigoEmpresa, MoldId, CodigoArticulo, CavidadesActivas, Observaciones) VALUES (' +
        IntToStr(FCodigoEmpresa) + ', ' +
        IntToStr(AMoldId) + ', ' +
        QStr(ARows[I].CodigoArticulo) + ', ' +
        IntToStr(ARows[I].CavidadesActivas) + ', ' +
        QStrNullable(ARows[I].Observaciones) + ')');
    FConnection.CommitTrans;
  except
    FConnection.RollbackTrans;
    raise;
  end;
end;

// ---------------------------------------------------------------------------
// Relacion Molde-Operacion
// ---------------------------------------------------------------------------

function TMoldeRepoSQL.GetOperaciones(AMoldId: Integer): TArray<TMoldeOperationRow>;
var
  Q: TADOQuery;
  L: TList<TMoldeOperationRow>;
  R: TMoldeOperationRow;
begin
  L := TList<TMoldeOperationRow>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT Operacion, CiclosPorUnidad, ISNULL(Observaciones, '''') AS Observaciones ' +
        'FROM FS_PL_MoldOperation ' +
        'WHERE CodigoEmpresa = :CE AND MoldId = :MoldId ' +
        'ORDER BY Operacion';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('MoldId').Value := AMoldId;
      Q.Open;
      while not Q.Eof do
      begin
        R.Operacion := Q.FieldByName('Operacion').AsString;
        R.CiclosPorUnidad := Q.FieldByName('CiclosPorUnidad').AsFloat;
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

procedure TMoldeRepoSQL.SaveOperaciones(AMoldId: Integer;
  const ARows: TArray<TMoldeOperationRow>);
var
  I: Integer;
begin
  FConnection.BeginTrans;
  try
    Exec('DELETE FROM FS_PL_MoldOperation WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa) + ' AND MoldId = ' + IntToStr(AMoldId));
    for I := 0 to High(ARows) do
      Exec('INSERT INTO FS_PL_MoldOperation (CodigoEmpresa, MoldId, Operacion, CiclosPorUnidad, Observaciones) VALUES (' +
        IntToStr(FCodigoEmpresa) + ', ' +
        IntToStr(AMoldId) + ', ' +
        QStr(ARows[I].Operacion) + ', ' +
        QDecimal(ARows[I].CiclosPorUnidad) + ', ' +
        QStrNullable(ARows[I].Observaciones) + ')');
    FConnection.CommitTrans;
  except
    FConnection.RollbackTrans;
    raise;
  end;
end;

// ---------------------------------------------------------------------------
// Relacion Molde-Utillaje
// ---------------------------------------------------------------------------

function TMoldeRepoSQL.GetUtillajes(AMoldId: Integer): TArray<TMoldeUtillajeRow>;
var
  Q: TADOQuery;
  L: TList<TMoldeUtillajeRow>;
  R: TMoldeUtillajeRow;
begin
  L := TList<TMoldeUtillajeRow>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT CodigoUtillaje, Obligatorio, ISNULL(Observaciones, '''') AS Observaciones ' +
        'FROM FS_PL_MoldUtillaje ' +
        'WHERE CodigoEmpresa = :CE AND MoldId = :MoldId ' +
        'ORDER BY CodigoUtillaje';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('MoldId').Value := AMoldId;
      Q.Open;
      while not Q.Eof do
      begin
        R.CodigoUtillaje := Q.FieldByName('CodigoUtillaje').AsString;
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

procedure TMoldeRepoSQL.SaveUtillajes(AMoldId: Integer;
  const ARows: TArray<TMoldeUtillajeRow>);
var
  I: Integer;
begin
  FConnection.BeginTrans;
  try
    Exec('DELETE FROM FS_PL_MoldUtillaje WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa) + ' AND MoldId = ' + IntToStr(AMoldId));
    for I := 0 to High(ARows) do
      Exec('INSERT INTO FS_PL_MoldUtillaje (CodigoEmpresa, MoldId, CodigoUtillaje, Obligatorio, Observaciones) VALUES (' +
        IntToStr(FCodigoEmpresa) + ', ' +
        IntToStr(AMoldId) + ', ' +
        QStr(ARows[I].CodigoUtillaje) + ', ' +
        IntToStr(Ord(ARows[I].Obligatorio)) + ', ' +
        QStrNullable(ARows[I].Observaciones) + ')');
    FConnection.CommitTrans;
  except
    FConnection.RollbackTrans;
    raise;
  end;
end;

end.
