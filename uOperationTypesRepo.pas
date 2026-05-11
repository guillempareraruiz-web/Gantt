unit uOperationTypesRepo;

{
  TOperationTypesRepo - repositorio de tipos de operacion con paralelismo.

  Modela la decision PRO (Escenario C): cuantos operarios pueden trabajar
  en paralelo en una operacion y con que factor de eficiencia decreciente.

  Si una operacion no esta registrada, se asume:
    MaxOperariosParalelos = 1
    FactorParalelismo     = 1.0
  (comportamiento equivalente a no paralelizar).
}

interface

uses
  System.SysUtils, System.Variants, System.Math, System.Generics.Collections,
  Data.Win.ADODB,
  uOperariosTypes;

type
  TOperationTypesRepo = class
  private
    FItems: TDictionary<string, TTipoOperacion>;
    FConn: TADOConnection;
    FCodigoEmpresa: SmallInt;
    function NormalizeKey(const Operacion: string): string;
    function HasDB: Boolean;
    function QStr(const S: string): string;
    procedure ExecSQL(const ASQL: string);
    procedure DBUpsert(const Op: TTipoOperacion);
    procedure DBDelete(const Operacion: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetConnection(AConn: TADOConnection; ACodigoEmpresa: SmallInt);
    procedure LoadFromDB;

    procedure AddOrUpdate(const Op: TTipoOperacion);
    procedure Remove(const Operacion: string);
    procedure Clear;

    function GetOrDefault(const Operacion: string): TTipoOperacion;
    function GetAll: TArray<TTipoOperacion>;
    function Exists(const Operacion: string): Boolean;

    // Calculo de la eficacia de paralelismo segun N operarios (todos
    // con FactorEficiencia=1.0 implicito).
    function EficaciaParalelismo(const Operacion: string;
      NOperarios: Integer): Double; overload;

    // Calculo hibrido con FactorEficiencia por operario:
    //   Neq = sum(1/e_i)        (operarios equivalentes)
    //   Eficacia = 1 + (Neq-1) * Factor  (con clamp inferior a 0.5)
    function EficaciaParalelismo(const Operacion: string;
      const FactoresEficiencia: TArray<Double>): Double; overload;

    // Duracion efectiva (horas) dado horas-hombre base y N operarios
    function DuracionEfectivaHoras(const Operacion: string;
      const HorasHombreBase: Double; NOperarios: Integer): Double; overload;

    // Duracion efectiva con FactorEficiencia por operario.
    function DuracionEfectivaHoras(const Operacion: string;
      const HorasHombreBase: Double;
      const FactoresEficiencia: TArray<Double>): Double; overload;

    procedure LoadSampleData;
  end;

implementation

constructor TOperationTypesRepo.Create;
begin
  inherited;
  FItems := TDictionary<string, TTipoOperacion>.Create;
  FConn := nil;
  FCodigoEmpresa := 0;
end;

destructor TOperationTypesRepo.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TOperationTypesRepo.SetConnection(AConn: TADOConnection;
  ACodigoEmpresa: SmallInt);
begin
  FConn := AConn;
  FCodigoEmpresa := ACodigoEmpresa;
end;

function TOperationTypesRepo.HasDB: Boolean;
begin
  Result := Assigned(FConn) and FConn.Connected;
end;

function TOperationTypesRepo.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

procedure TOperationTypesRepo.ExecSQL(const ASQL: string);
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

procedure TOperationTypesRepo.DBUpsert(const Op: TTipoOperacion);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  ExecSQL(Format(
    'IF EXISTS (SELECT 1 FROM FS_PL_OperationType WHERE CodigoEmpresa = %s AND Operacion = %s) ' +
    'UPDATE FS_PL_OperationType SET MaxOperariosParalelos = %d, FactorParalelismo = %s, Descripcion = %s ' +
    '  WHERE CodigoEmpresa = %s AND Operacion = %s ' +
    'ELSE INSERT INTO FS_PL_OperationType (CodigoEmpresa, Operacion, MaxOperariosParalelos, FactorParalelismo, Descripcion) ' +
    '  VALUES (%s, %s, %d, %s, %s)',
    [CE, QStr(Op.Operacion),
     Op.MaxOperariosParalelos,
     FloatToStr(Op.FactorParalelismo, TFormatSettings.Invariant),
     QStr(Op.Descripcion),
     CE, QStr(Op.Operacion),
     CE, QStr(Op.Operacion),
     Op.MaxOperariosParalelos,
     FloatToStr(Op.FactorParalelismo, TFormatSettings.Invariant),
     QStr(Op.Descripcion)]));
end;

procedure TOperationTypesRepo.DBDelete(const Operacion: string);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  ExecSQL(Format(
    'DELETE FROM FS_PL_OperationType WHERE CodigoEmpresa = %s AND Operacion = %s',
    [CE, QStr(Operacion)]));
end;

procedure TOperationTypesRepo.LoadFromDB;
var
  Q: TADOQuery;
  Op: TTipoOperacion;
  CE: string;
begin
  if not HasDB then Exit;
  FItems.Clear;
  CE := IntToStr(FCodigoEmpresa);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT Operacion, MaxOperariosParalelos, FactorParalelismo, ' +
      '       ISNULL(Descripcion, '''') AS Descripcion ' +
      'FROM FS_PL_OperationType WHERE CodigoEmpresa = ' + CE +
      ' ORDER BY Operacion';
    Q.Open;
    while not Q.Eof do
    begin
      Op.Operacion := Q.FieldByName('Operacion').AsString;
      Op.MaxOperariosParalelos := Q.FieldByName('MaxOperariosParalelos').AsInteger;
      Op.FactorParalelismo := Q.FieldByName('FactorParalelismo').AsFloat;
      Op.Descripcion := Q.FieldByName('Descripcion').AsString;
      FItems.AddOrSetValue(NormalizeKey(Op.Operacion), Op);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TOperationTypesRepo.NormalizeKey(const Operacion: string): string;
begin
  Result := UpperCase(Trim(Operacion));
end;

procedure TOperationTypesRepo.AddOrUpdate(const Op: TTipoOperacion);
begin
  FItems.AddOrSetValue(NormalizeKey(Op.Operacion), Op);
  DBUpsert(Op);
end;

procedure TOperationTypesRepo.Remove(const Operacion: string);
begin
  FItems.Remove(NormalizeKey(Operacion));
  DBDelete(Operacion);
end;

procedure TOperationTypesRepo.Clear;
begin
  FItems.Clear;
end;

function TOperationTypesRepo.Exists(const Operacion: string): Boolean;
begin
  Result := FItems.ContainsKey(NormalizeKey(Operacion));
end;

function TOperationTypesRepo.GetOrDefault(const Operacion: string): TTipoOperacion;
begin
  if not FItems.TryGetValue(NormalizeKey(Operacion), Result) then
  begin
    Result.Operacion := Operacion;
    Result.MaxOperariosParalelos := 1;
    Result.FactorParalelismo := 1.0;
    Result.Descripcion := '';
  end;
end;

function TOperationTypesRepo.GetAll: TArray<TTipoOperacion>;
var
  L: TList<TTipoOperacion>;
  V: TTipoOperacion;
begin
  L := TList<TTipoOperacion>.Create;
  try
    for V in FItems.Values do
      L.Add(V);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TOperationTypesRepo.EficaciaParalelismo(const Operacion: string;
  NOperarios: Integer): Double;
var
  T: TTipoOperacion;
  Nef: Integer;
begin
  if NOperarios <= 1 then
    Exit(1.0);
  T := GetOrDefault(Operacion);
  Nef := NOperarios;
  if (T.MaxOperariosParalelos > 0) and (Nef > T.MaxOperariosParalelos) then
    Nef := T.MaxOperariosParalelos;
  // Modelo lineal con rendimiento decreciente: 1 + (N-1) * Factor
  Result := 1.0 + (Nef - 1) * Max(0.0, Min(1.0, T.FactorParalelismo));
  if Result < 1.0 then Result := 1.0;
end;

function TOperationTypesRepo.DuracionEfectivaHoras(const Operacion: string;
  const HorasHombreBase: Double; NOperarios: Integer): Double;
var
  Eficacia: Double;
begin
  if HorasHombreBase <= 0 then Exit(0);
  Eficacia := EficaciaParalelismo(Operacion, NOperarios);
  if Eficacia <= 0 then Eficacia := 1.0;
  Result := HorasHombreBase / Eficacia;
end;

function TOperationTypesRepo.EficaciaParalelismo(const Operacion: string;
  const FactoresEficiencia: TArray<Double>): Double;
var
  T: TTipoOperacion;
  I: Integer;
  Neq, Factor, e: Double;
begin
  if Length(FactoresEficiencia) = 0 then Exit(1.0);

  // Neq = suma de operarios equivalentes (1/e cada uno)
  Neq := 0;
  for I := 0 to High(FactoresEficiencia) do
  begin
    e := FactoresEficiencia[I];
    if e <= 0 then e := 1.0;  // proteccion: factor invalido = normal
    Neq := Neq + (1.0 / e);
  end;

  // Si solo hay 1 operario equivalente o menos, sin paralelismo
  if Neq <= 1.0 then
  begin
    // Pero respetar el efecto de FactorEficiencia: 1 op lento (e=1.5)
    // da Neq=0.667, y queremos Eficacia<1.
    Result := Neq;
    if Result < 0.5 then Result := 0.5;  // clamp inferior de seguridad
    Exit;
  end;

  // Limitar Neq por MaxOperariosParalelos del tipo de operacion
  T := GetOrDefault(Operacion);
  if (T.MaxOperariosParalelos > 0) and (Neq > T.MaxOperariosParalelos) then
    Neq := T.MaxOperariosParalelos;

  Factor := Max(0.0, Min(1.0, T.FactorParalelismo));
  Result := 1.0 + (Neq - 1.0) * Factor;
  if Result < 0.5 then Result := 0.5;  // clamp inferior de seguridad
end;

function TOperationTypesRepo.DuracionEfectivaHoras(const Operacion: string;
  const HorasHombreBase: Double;
  const FactoresEficiencia: TArray<Double>): Double;
var
  Eficacia: Double;
begin
  if HorasHombreBase <= 0 then Exit(0);
  Eficacia := EficaciaParalelismo(Operacion, FactoresEficiencia);
  if Eficacia <= 0 then Eficacia := 1.0;
  Result := HorasHombreBase / Eficacia;
end;

procedure TOperationTypesRepo.LoadSampleData;
var
  T: TTipoOperacion;

  procedure AddOp(const AOp: string; AMax: Integer; AFactor: Double; const ADesc: string);
  begin
    T.Operacion := AOp;
    T.MaxOperariosParalelos := AMax;
    T.FactorParalelismo := AFactor;
    T.Descripcion := ADesc;
    AddOrUpdate(T);
  end;
begin
  // Operaciones que escalan bien (paralelismo alto)
  AddOp('PINTAR',     3, 0.85, 'Pintura: paralelizable hasta 3');
  AddOp('LACAR',      3, 0.85, 'Lacado: paralelizable hasta 3');
  AddOp('PULIR',      4, 0.90, 'Pulido manual: muy paralelizable');
  AddOp('EMBALAR',    4, 0.95, 'Embalaje: muy paralelizable');
  AddOp('MONTAR',     3, 0.80, 'Montaje: paralelizable con coordinacion');

  // Operaciones que escalan moderado
  AddOp('BRONCEAR',   2, 0.70, 'Bronceado');
  AddOp('TALADRAR',   2, 0.65, 'Taladrado');
  AddOp('CORTAR',     2, 0.60, 'Corte');

  // Operaciones poco paralelizables (1 maquina, 1 operario)
  AddOp('SOLDAR',     1, 1.00, 'Soldadura: no paralelizable');
  AddOp('FRESAR',     1, 1.00, 'Fresado: 1 maquina');
  AddOp('TORNEAR',    1, 1.00, 'Torneado: 1 maquina');
  AddOp('RECTIFICAR', 1, 1.00, 'Rectificado: 1 maquina');
end;

end.
