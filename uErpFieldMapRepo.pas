unit uErpFieldMapRepo;

// ============================================================================
// CRUD de FS_PL_Cfg_ErpFieldMap: mapeo de columnas custom (FieldKey) a una
// expresion SQL libre contra el ERP (Sage) + JOINs opcionales.
//
// Lo configura el integrador, por cliente. El valor leido del ERP se escribe
// luego en FS_PL_RawItem_Extra con Source='ERP' durante la sincronizacion.
// ============================================================================

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.Win.ADODB, uErpTypes;

type
  // TErpFieldMap se define ahora en uErpTypes (tipo de datos puro, compartido
  // con la interface IErpReader). Aqui solo el repositorio CRUD.
  TErpFieldMapRepo = class
  private
    FConn: TADOConnection;
    FEmpresa: SmallInt;
    function QStr(const S: string): string;
  public
    constructor Create(AConn: TADOConnection; AEmpresa: SmallInt);

    // Devuelve todos los mapeos (activos e inactivos) de un GridId.
    function LoadAll(const AGridId: string): TArray<TErpFieldMap>;
    // Solo activos (los que aplica el reader/sync).
    function LoadActive(const AGridId: string): TArray<TErpFieldMap>;
    // UPSERT por (GridId, FieldKey).
    procedure Save(const AMap: TErpFieldMap; const AUser: string);
    // Borra fisicamente el mapeo de un FieldKey.
    procedure Delete(const AGridId, AFieldKey: string);
  end;

implementation

constructor TErpFieldMapRepo.Create(AConn: TADOConnection; AEmpresa: SmallInt);
begin
  inherited Create;
  FConn := AConn;
  FEmpresa := AEmpresa;
end;

function TErpFieldMapRepo.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function BitStr(B: Boolean): string;
begin
  if B then Result := '1' else Result := '0';
end;

function TErpFieldMapRepo.LoadAll(const AGridId: string): TArray<TErpFieldMap>;
var
  Q: TADOQuery;
  L: TList<TErpFieldMap>;
  M: TErpFieldMap;
begin
  L := TList<TErpFieldMap>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT GridId, FieldKey, ErpSource, SqlExpression, SqlJoins, ' +
      '       AppliesToNivel, Activo ' +
      'FROM FS_PL_Cfg_ErpFieldMap ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FEmpresa) +
      '  AND GridId = ' + QStr(AGridId) +
      'ORDER BY FieldKey';
    Q.Open;
    while not Q.Eof do
    begin
      M.GridId        := Q.FieldByName('GridId').AsString;
      M.FieldKey      := Q.FieldByName('FieldKey').AsString;
      M.ErpSource     := Q.FieldByName('ErpSource').AsString;
      M.SqlExpression := Q.FieldByName('SqlExpression').AsString;
      if Q.FieldByName('SqlJoins').IsNull then
        M.SqlJoins := ''
      else
        M.SqlJoins := Q.FieldByName('SqlJoins').AsString;
      if Q.FieldByName('AppliesToNivel').IsNull then
        M.AppliesToNivel := 0
      else
        M.AppliesToNivel := Q.FieldByName('AppliesToNivel').AsInteger;
      M.Activo := Q.FieldByName('Activo').AsBoolean;
      L.Add(M);
      Q.Next;
    end;
    Result := L.ToArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

function TErpFieldMapRepo.LoadActive(const AGridId: string): TArray<TErpFieldMap>;
var
  All: TArray<TErpFieldMap>;
  L: TList<TErpFieldMap>;
  M: TErpFieldMap;
begin
  All := LoadAll(AGridId);
  L := TList<TErpFieldMap>.Create;
  try
    for M in All do
      if M.Activo and (Trim(M.SqlExpression) <> '') then
        L.Add(M);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TErpFieldMapRepo.Save(const AMap: TErpFieldMap; const AUser: string);
var
  Cmd: TADOCommand;
  NivelSql, JoinsSql: string;
begin
  if AMap.AppliesToNivel <= 0 then
    NivelSql := 'NULL'
  else
    NivelSql := IntToStr(AMap.AppliesToNivel);
  if Trim(AMap.SqlJoins) = '' then
    JoinsSql := 'NULL'
  else
    JoinsSql := QStr(AMap.SqlJoins);

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConn;
    Cmd.CommandText :=
      'MERGE FS_PL_Cfg_ErpFieldMap AS T ' +
      'USING (SELECT ' + IntToStr(FEmpresa) + ' AS CodigoEmpresa, ' +
      '              ' + QStr(AMap.GridId) + ' AS GridId, ' +
      '              ' + QStr(AMap.FieldKey) + ' AS FieldKey) AS S ' +
      '  ON (T.CodigoEmpresa = S.CodigoEmpresa AND T.GridId = S.GridId ' +
      '      AND T.FieldKey = S.FieldKey) ' +
      'WHEN MATCHED THEN UPDATE SET ' +
      '  ErpSource = ' + QStr(AMap.ErpSource) + ', ' +
      '  SqlExpression = ' + QStr(AMap.SqlExpression) + ', ' +
      '  SqlJoins = ' + JoinsSql + ', ' +
      '  AppliesToNivel = ' + NivelSql + ', ' +
      '  Activo = ' + BitStr(AMap.Activo) + ', ' +
      '  UpdatedBy = ' + QStr(AUser) + ', UpdatedAt = SYSUTCDATETIME() ' +
      'WHEN NOT MATCHED THEN INSERT ' +
      '  (CodigoEmpresa, GridId, FieldKey, ErpSource, SqlExpression, SqlJoins, ' +
      '   AppliesToNivel, Activo, UpdatedBy, UpdatedAt) ' +
      '  VALUES (' + IntToStr(FEmpresa) + ', ' + QStr(AMap.GridId) + ', ' +
      QStr(AMap.FieldKey) + ', ' + QStr(AMap.ErpSource) + ', ' +
      QStr(AMap.SqlExpression) + ', ' + JoinsSql + ', ' + NivelSql + ', ' +
      BitStr(AMap.Activo) + ', ' + QStr(AUser) + ', SYSUTCDATETIME());';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TErpFieldMapRepo.Delete(const AGridId, AFieldKey: string);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConn;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_Cfg_ErpFieldMap ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FEmpresa) +
      '  AND GridId = ' + QStr(AGridId) +
      '  AND FieldKey = ' + QStr(AFieldKey);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

end.
