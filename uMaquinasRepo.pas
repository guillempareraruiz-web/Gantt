unit uMaquinasRepo;

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  Data.Win.ADODB, Data.DB;

type
  TMaquina = record
    Id: Integer;
    Codigo: string;
    Nombre: string;
    Activo: Boolean;
    Orden: Integer;
  end;

  TMaquinasRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    FMaquinas: TArray<TMaquina>;
    function QStr(const S: string): string;
    procedure Exec(const ASQL: string);
  public
    constructor Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt);

    procedure LoadFromDB;
    function GetAll: TArray<TMaquina>;
    function Count: Integer;
    function GetById(AId: Integer; out AMaq: TMaquina): Boolean;

    function Insert(const AMaq: TMaquina): Integer;
    procedure Update(const AMaq: TMaquina);
    procedure Delete(AId: Integer);

    // Relacion N:M con FS_PL_Center
    function GetMaquinaIdsForCentro(ACenterId: Integer): TArray<Integer>;
    function GetCenterIdsForMaquina(AMaquinaId: Integer): TArray<Integer>;
    procedure SetMaquinasForCentro(ACenterId: Integer;
      const AMaquinaIds: TArray<Integer>);
  end;

implementation

constructor TMaquinasRepo.Create(AConnection: TADOConnection;
  ACodigoEmpresa: SmallInt);
begin
  inherited Create;
  FConnection := AConnection;
  FCodigoEmpresa := ACodigoEmpresa;
  SetLength(FMaquinas, 0);
end;

function TMaquinasRepo.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

procedure TMaquinasRepo.Exec(const ASQL: string);
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

procedure TMaquinasRepo.LoadFromDB;
var
  Q: TADOQuery;
  M: TMaquina;
  I: Integer;
begin
  SetLength(FMaquinas, 0);
  if FConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT MaquinaId, Codigo, Nombre, Activo, Orden ' +
      'FROM FS_PL_Maquina ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa ' +
      'ORDER BY Orden, Codigo';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := FCodigoEmpresa;
    Q.Open;

    SetLength(FMaquinas, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      M.Id := Q.FieldByName('MaquinaId').AsInteger;
      M.Codigo := Q.FieldByName('Codigo').AsString;
      M.Nombre := Q.FieldByName('Nombre').AsString;
      M.Activo := Q.FieldByName('Activo').AsBoolean;
      M.Orden := Q.FieldByName('Orden').AsInteger;
      FMaquinas[I] := M;
      Inc(I);
      Q.Next;
    end;
    SetLength(FMaquinas, I);
  finally
    Q.Free;
  end;
end;

function TMaquinasRepo.GetAll: TArray<TMaquina>;
begin
  Result := FMaquinas;
end;

function TMaquinasRepo.Count: Integer;
begin
  Result := Length(FMaquinas);
end;

function TMaquinasRepo.GetById(AId: Integer; out AMaq: TMaquina): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FMaquinas) do
    if FMaquinas[I].Id = AId then
    begin
      AMaq := FMaquinas[I];
      Exit(True);
    end;
  Result := False;
end;

function TMaquinasRepo.Insert(const AMaq: TMaquina): Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  if FConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'INSERT INTO FS_PL_Maquina (CodigoEmpresa, Codigo, Nombre, Activo, Orden) ' +
      'OUTPUT INSERTED.MaquinaId ' +
      'VALUES (' + IntToStr(FCodigoEmpresa) + ', ' +
      QStr(AMaq.Codigo) + ', ' + QStr(AMaq.Nombre) + ', ' +
      IntToStr(Ord(AMaq.Activo)) + ', ' + IntToStr(AMaq.Orden) + ')';
    Q.Open;
    if not Q.Eof then
      Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TMaquinasRepo.Update(const AMaq: TMaquina);
begin
  if FConnection = nil then Exit;
  Exec(
    'UPDATE FS_PL_Maquina SET ' +
    '  Codigo = ' + QStr(AMaq.Codigo) + ', ' +
    '  Nombre = ' + QStr(AMaq.Nombre) + ', ' +
    '  Activo = ' + IntToStr(Ord(AMaq.Activo)) + ', ' +
    '  Orden  = ' + IntToStr(AMaq.Orden) + ', ' +
    '  FechaModificacion = SYSDATETIME() ' +
    'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
    '  AND MaquinaId = ' + IntToStr(AMaq.Id));
end;

procedure TMaquinasRepo.Delete(AId: Integer);
begin
  if FConnection = nil then Exit;
  Exec(
    'DELETE FROM FS_PL_Maquina ' +
    'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
    '  AND MaquinaId = ' + IntToStr(AId));
end;

function TMaquinasRepo.GetMaquinaIdsForCentro(
  ACenterId: Integer): TArray<Integer>;
var
  Q: TADOQuery;
  L: TList<Integer>;
begin
  L := TList<Integer>.Create;
  try
    if FConnection = nil then Exit(L.ToArray);
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT MaquinaId FROM FS_PL_CentroMaquina ' +
        'WHERE CodigoEmpresa = :CodigoEmpresa AND CenterId = :CenterId ' +
        'ORDER BY MaquinaId';
      Q.Parameters.ParamByName('CodigoEmpresa').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('CenterId').Value := ACenterId;
      Q.Open;
      while not Q.Eof do
      begin
        L.Add(Q.FieldByName('MaquinaId').AsInteger);
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

function TMaquinasRepo.GetCenterIdsForMaquina(
  AMaquinaId: Integer): TArray<Integer>;
var
  Q: TADOQuery;
  L: TList<Integer>;
begin
  L := TList<Integer>.Create;
  try
    if FConnection = nil then Exit(L.ToArray);
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT CenterId FROM FS_PL_CentroMaquina ' +
        'WHERE CodigoEmpresa = :CodigoEmpresa AND MaquinaId = :MaquinaId ' +
        'ORDER BY CenterId';
      Q.Parameters.ParamByName('CodigoEmpresa').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('MaquinaId').Value := AMaquinaId;
      Q.Open;
      while not Q.Eof do
      begin
        L.Add(Q.FieldByName('CenterId').AsInteger);
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

procedure TMaquinasRepo.SetMaquinasForCentro(ACenterId: Integer;
  const AMaquinaIds: TArray<Integer>);
var
  I: Integer;
  Values: string;
begin
  if FConnection = nil then Exit;

  Exec(
    'DELETE FROM FS_PL_CentroMaquina ' +
    'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
    '  AND CenterId = ' + IntToStr(ACenterId));

  if Length(AMaquinaIds) = 0 then Exit;

  Values := '';
  for I := 0 to High(AMaquinaIds) do
  begin
    if I > 0 then Values := Values + ', ';
    Values := Values + '(' +
      IntToStr(FCodigoEmpresa) + ', ' +
      IntToStr(ACenterId) + ', ' +
      IntToStr(AMaquinaIds[I]) + ')';
  end;

  Exec(
    'INSERT INTO FS_PL_CentroMaquina (CodigoEmpresa, CenterId, MaquinaId) ' +
    'VALUES ' + Values);
end;

end.
