unit uOperatorAbsencesRepo;

{
  TOperatorAbsencesRepo - repositorio en memoria de ausencias de operarios.

  Las ausencias bloquean horas disponibles del calendario del operario y
  se pintan como bloques en el form uFiniteCapacityOperaris.
}

interface

uses
  System.SysUtils, System.Variants, System.DateUtils, System.Generics.Collections,
  Data.Win.ADODB,
  uOperariosTypes;

type
  TOperatorAbsencesRepo = class
  private
    FItems: TList<TAusencia>;
    FNextId: Integer;
    FConn: TADOConnection;
    FCodigoEmpresa: SmallInt;
    function HasDB: Boolean;
    function QStr(const S: string): string;
    function FmtDT(const T: TDateTime): string;
    procedure ExecSQL(const ASQL: string);
    function DBInsert(const A: TAusencia): Integer;
    procedure DBUpdate(const A: TAusencia);
    procedure DBDelete(Id: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetConnection(AConn: TADOConnection; ACodigoEmpresa: SmallInt);
    procedure LoadFromDB;

    function Add(const A: TAusencia): Integer;
    procedure Update(const A: TAusencia);
    procedure Remove(Id: Integer);
    procedure ClearByOperario(OperarioId: Integer);

    function GetAll: TArray<TAusencia>;
    function GetByOperario(OperarioId: Integer): TArray<TAusencia>;
    function GetByOperarioInRange(OperarioId: Integer;
      const RangeStart, RangeEnd: TDateTime): TArray<TAusencia>;

    function HoursOverlapping(OperarioId: Integer;
      const RangeStart, RangeEnd: TDateTime): Double;
    function IsAbsentAt(OperarioId: Integer; const ADate: TDateTime): Boolean;

    procedure LoadSampleData(const AOperarioIds: TArray<Integer>);
  end;

implementation

constructor TOperatorAbsencesRepo.Create;
begin
  inherited;
  FItems := TList<TAusencia>.Create;
  FNextId := 1;
  FConn := nil;
  FCodigoEmpresa := 0;
end;

procedure TOperatorAbsencesRepo.SetConnection(AConn: TADOConnection;
  ACodigoEmpresa: SmallInt);
begin
  FConn := AConn;
  FCodigoEmpresa := ACodigoEmpresa;
end;

function TOperatorAbsencesRepo.HasDB: Boolean;
begin
  Result := Assigned(FConn) and FConn.Connected;
end;

function TOperatorAbsencesRepo.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TOperatorAbsencesRepo.FmtDT(const T: TDateTime): string;
begin
  Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', T) + '''';
end;

procedure TOperatorAbsencesRepo.ExecSQL(const ASQL: string);
var
  Cmd: TADOCommand;
  Affected: Integer;
begin
  if not HasDB then Exit;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConn;
    Cmd.CommandText := ASQL;
    Cmd.Execute(Affected, EmptyParam);
  finally
    Cmd.Free;
  end;
end;

function TOperatorAbsencesRepo.DBInsert(const A: TAusencia): Integer;
var
  Q: TADOQuery;
  CE: string;
  EsHorariaSQL: string;
begin
  Result := 0;
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  if A.EsHoraria then EsHorariaSQL := '1' else EsHorariaSQL := '0';
  ExecSQL(Format(
    'INSERT INTO FS_PL_OperatorAbsence (CodigoEmpresa, OperatorId, ' +
    '  FechaInicio, FechaFin, Tipo, Descripcion, EsHoraria) VALUES ' +
    '(%s, %d, %s, %s, %d, %s, %s)',
    [CE, A.OperarioId, FmtDT(A.FechaInicio), FmtDT(A.FechaFin),
     TipoAusenciaToTinyInt(A.Tipo), QStr(A.Descripcion), EsHorariaSQL]));

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewId';
    Q.Open;
    Result := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TOperatorAbsencesRepo.DBUpdate(const A: TAusencia);
var
  CE: string;
  EsHorariaSQL: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  if A.EsHoraria then EsHorariaSQL := '1' else EsHorariaSQL := '0';
  ExecSQL(Format(
    'UPDATE FS_PL_OperatorAbsence SET OperatorId = %d, FechaInicio = %s, ' +
    'FechaFin = %s, Tipo = %d, Descripcion = %s, EsHoraria = %s ' +
    'WHERE CodigoEmpresa = %s AND AbsenceId = %d',
    [A.OperarioId, FmtDT(A.FechaInicio), FmtDT(A.FechaFin),
     TipoAusenciaToTinyInt(A.Tipo), QStr(A.Descripcion), EsHorariaSQL,
     CE, A.Id]));
end;

procedure TOperatorAbsencesRepo.DBDelete(Id: Integer);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  ExecSQL(Format(
    'DELETE FROM FS_PL_OperatorAbsence WHERE CodigoEmpresa = %s AND AbsenceId = %d',
    [CE, Id]));
end;

procedure TOperatorAbsencesRepo.LoadFromDB;
var
  Q: TADOQuery;
  A: TAusencia;
  CE: string;
begin
  if not HasDB then Exit;
  FItems.Clear;
  FNextId := 1;
  CE := IntToStr(FCodigoEmpresa);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT AbsenceId, OperatorId, FechaInicio, FechaFin, Tipo, ' +
      '       ISNULL(Descripcion, '''') AS Descripcion, ' +
      '       ISNULL(EsHoraria, 0) AS EsHoraria ' +
      'FROM FS_PL_OperatorAbsence WHERE CodigoEmpresa = ' + CE +
      ' ORDER BY OperatorId, FechaInicio';
    Q.Open;
    while not Q.Eof do
    begin
      A.Id := Q.FieldByName('AbsenceId').AsInteger;
      A.OperarioId := Q.FieldByName('OperatorId').AsInteger;
      A.FechaInicio := Q.FieldByName('FechaInicio').AsDateTime;
      A.FechaFin := Q.FieldByName('FechaFin').AsDateTime;
      A.Tipo := TinyIntToTipoAusencia(Byte(Q.FieldByName('Tipo').AsInteger));
      A.Descripcion := Q.FieldByName('Descripcion').AsString;
      A.EsHoraria := Q.FieldByName('EsHoraria').AsBoolean;
      FItems.Add(A);
      if A.Id >= FNextId then FNextId := A.Id + 1;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

destructor TOperatorAbsencesRepo.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TOperatorAbsencesRepo.Add(const A: TAusencia): Integer;
var
  Item: TAusencia;
  NewId: Integer;
begin
  Item := A;
  if HasDB and (Item.Id = 0) then
  begin
    NewId := DBInsert(Item);
    if NewId > 0 then
      Item.Id := NewId
    else
      Item.Id := FNextId;
  end
  else
  begin
    if Item.Id = 0 then
      Item.Id := FNextId;
  end;
  if Item.Id >= FNextId then
    FNextId := Item.Id + 1;
  FItems.Add(Item);
  Result := Item.Id;
end;

procedure TOperatorAbsencesRepo.Update(const A: TAusencia);
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Id = A.Id then
    begin
      FItems[I] := A;
      DBUpdate(A);
      Exit;
    end;
end;

procedure TOperatorAbsencesRepo.Remove(Id: Integer);
var
  I: Integer;
begin
  for I := FItems.Count - 1 downto 0 do
    if FItems[I].Id = Id then
    begin
      FItems.Delete(I);
      DBDelete(Id);
      Exit;
    end;
end;

procedure TOperatorAbsencesRepo.ClearByOperario(OperarioId: Integer);
var
  I: Integer;
  IdsToDelete: TList<Integer>;
begin
  IdsToDelete := TList<Integer>.Create;
  try
    for I := FItems.Count - 1 downto 0 do
      if FItems[I].OperarioId = OperarioId then
      begin
        IdsToDelete.Add(FItems[I].Id);
        FItems.Delete(I);
      end;
    if HasDB then
      ExecSQL(Format(
        'DELETE FROM FS_PL_OperatorAbsence WHERE CodigoEmpresa = %d AND OperatorId = %d',
        [FCodigoEmpresa, OperarioId]));
  finally
    IdsToDelete.Free;
  end;
end;

function TOperatorAbsencesRepo.GetAll: TArray<TAusencia>;
begin
  Result := FItems.ToArray;
end;

function TOperatorAbsencesRepo.GetByOperario(OperarioId: Integer): TArray<TAusencia>;
var
  I: Integer;
  L: TList<TAusencia>;
begin
  L := TList<TAusencia>.Create;
  try
    for I := 0 to FItems.Count - 1 do
      if FItems[I].OperarioId = OperarioId then
        L.Add(FItems[I]);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TOperatorAbsencesRepo.GetByOperarioInRange(OperarioId: Integer;
  const RangeStart, RangeEnd: TDateTime): TArray<TAusencia>;
var
  I: Integer;
  L: TList<TAusencia>;
begin
  L := TList<TAusencia>.Create;
  try
    for I := 0 to FItems.Count - 1 do
      if (FItems[I].OperarioId = OperarioId) and
         (FItems[I].FechaInicio < RangeEnd) and
         (FItems[I].FechaFin > RangeStart) then
        L.Add(FItems[I]);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TOperatorAbsencesRepo.HoursOverlapping(OperarioId: Integer;
  const RangeStart, RangeEnd: TDateTime): Double;
var
  I: Integer;
  OvStart, OvEnd: TDateTime;
begin
  Result := 0;
  for I := 0 to FItems.Count - 1 do
    if (FItems[I].OperarioId = OperarioId) and
       (FItems[I].FechaInicio < RangeEnd) and
       (FItems[I].FechaFin > RangeStart) then
    begin
      OvStart := FItems[I].FechaInicio;
      if OvStart < RangeStart then OvStart := RangeStart;
      OvEnd := FItems[I].FechaFin;
      if OvEnd > RangeEnd then OvEnd := RangeEnd;
      if OvEnd > OvStart then
        Result := Result + (OvEnd - OvStart) * 24;  // dias -> horas
    end;
end;

function TOperatorAbsencesRepo.IsAbsentAt(OperarioId: Integer;
  const ADate: TDateTime): Boolean;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    if (FItems[I].OperarioId = OperarioId) and
       (ADate >= FItems[I].FechaInicio) and
       (ADate < FItems[I].FechaFin) then
      Exit(True);
  Result := False;
end;

procedure TOperatorAbsencesRepo.LoadSampleData(const AOperarioIds: TArray<Integer>);
var
  I, K: Integer;
  A: TAusencia;
  Hoy: TDateTime;
  Tipos: array[0..4] of TTipoAusencia;
begin
  Hoy := DateOf(Now);
  Tipos[0] := taVacaciones;
  Tipos[1] := taBaja;
  Tipos[2] := taFormacion;
  Tipos[3] := taPermiso;
  Tipos[4] := taOtros;

  // Aproximadamente 1 de cada 5 operarios tendra ausencia en proximas 4 semanas
  for I := 0 to High(AOperarioIds) do
    if Random(5) = 0 then
    begin
      A.Id := 0;
      A.OperarioId := AOperarioIds[I];
      K := Random(28);  // dia inicio dentro de 4 semanas
      A.FechaInicio := Hoy + K;
      A.FechaFin := A.FechaInicio + 1 + Random(7);  // 1..7 dias
      A.Tipo := Tipos[Random(5)];
      A.Descripcion := TipoAusenciaToStr(A.Tipo);
      Add(A);
    end;
end;

end.
