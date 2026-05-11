unit uHabilidadRepo;

{
  THabilidadRepo - repositorio en memoria para el catalogo de habilidades
  y sus relaciones N:M con operarios y operaciones-maestro.

  Tres conjuntos:
    1. Catalogo de habilidades (THabilidad) -> tabla FS_PL_Habilidad.
    2. Operario tiene habilidades (TOperarioHabilidad) -> FS_PL_OperarioHabilidad.
    3. Operacion exige habilidades (TOperacionHabilidad) -> FS_PL_OperacionHabilidad.

  Migracion desde el modelo viejo (FS_PL_OperatorSkill 1-1):
    Cada FS_PL_OperatorSkill (Operario, Operacion, Nivel) se traduce a:
      - THabilidad nueva con Codigo = Operacion (auto-creada si no existe).
      - TOperacionHabilidad(Operacion, CodHabilidad=Operacion, NivelMin=0).
      - TOperarioHabilidad(OperarioId, CodHabilidad=Operacion, Nivel=Nivel).
    El metodo MigrarDesdeOperatorSkill realiza esta conversion automatica.

  Persistencia: en v1 in-memory. SQL en V020 (proxima migracion).
}

interface

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  Data.Win.ADODB,
  uOperariosTypes, uPlanProdTypes;

type
  THabilidadRepo = class
  private
    FHabilidades: TList<THabilidad>;
    FOperarioHab: TList<TOperarioHabilidad>;
    FOperacionHab: TList<TOperacionHabilidad>;
    FConn: TADOConnection;       // si <> nil, escribe tambien en BD
    FCodigoEmpresa: SmallInt;
    function HasDB: Boolean;
    function QStr(const S: string): string;
    procedure ExecSQL(const ASQL: string);
    procedure DBUpsertHabilidad(const H: THabilidad);
    procedure DBDeleteHabilidad(const Codigo: string);
    procedure DBUpsertOperarioHab(const Item: TOperarioHabilidad);
    procedure DBDeleteOperarioHab(OperarioId: Integer; const CodHabilidad: string);
    procedure DBClearOperarioHab(OperarioId: Integer);
    procedure DBUpsertOperacionHab(const Item: TOperacionHabilidad);
    procedure DBDeleteOperacionHab(const Operacion, CodHabilidad: string);
    procedure DBClearOperacionHab(const Operacion: string);
  public
    constructor Create;
    destructor Destroy; override;

    // === Configuracion BD ===
    procedure SetConnection(AConn: TADOConnection; ACodigoEmpresa: SmallInt);
    procedure LoadFromDB;
    procedure ClearAll;

    // === Catalogo habilidades ===
    procedure AddHabilidad(const H: THabilidad);
    procedure UpdateHabilidad(const H: THabilidad);
    procedure RemoveHabilidad(const Codigo: string);
    function GetHabilidades: TArray<THabilidad>;
    function GetHabilidad(const Codigo: string; out H: THabilidad): Boolean;
    function HabilidadExiste(const Codigo: string): Boolean;
    function EnsureHabilidad(const Codigo, Descripcion: string): Boolean;
      // True si se ha creado nueva, False si ya existia

    // === Habilidades del operario ===
    procedure SetOperarioHabilidad(OperarioId: Integer;
      const CodHabilidad: string; Nivel: TNivelSkill;
      FactorEficiencia: Double = 1.0);
    procedure RemoveOperarioHabilidad(OperarioId: Integer;
      const CodHabilidad: string);
    procedure ClearOperarioHabilidades(OperarioId: Integer);
    function GetHabilidadesOperario(OperarioId: Integer): TArray<TOperarioHabilidad>;
    function OperarioTieneHabilidad(OperarioId: Integer;
      const CodHabilidad: string; NivelMinimo: TNivelSkill): Boolean;
    function OperarioNivelEn(OperarioId: Integer;
      const CodHabilidad: string; out Nivel: TNivelSkill): Boolean;

    // === Habilidades exigidas por operacion-maestro ===
    procedure SetOperacionHabilidad(const Operacion, CodHabilidad: string;
      NivelMinimo: TNivelSkill);
    procedure RemoveOperacionHabilidad(const Operacion, CodHabilidad: string);
    procedure ClearOperacionHabilidades(const Operacion: string);
    function GetHabilidadesOperacion(const Operacion: string): TArray<TOperacionHabilidad>;

    // === Consultas combinadas ===
    function OperarioPuedeHacerOperacion(OperarioId: Integer;
      const Operacion: string; out MotivoFallo: string): Boolean;
    function GetOperariosCapacitadosPara(const Operacion: string): TArray<Integer>;
    function GetSobrenivel(OperarioId: Integer; const Operacion: string): Integer;
      // suma de (nivel_operario - nivel_minimo_exigido) en todas las habilidades
      // de la operacion. Util para penalizar usar un experto donde basta un junior.

    // FactorEficiencia efectivo del operario para una operacion dada.
    // Calcula el promedio de los factores de las habilidades exigidas por
    // la operacion. Si la operacion no exige habilidades, devuelve 1.0.
    // Si el operario no tiene una habilidad exigida, esa entra como 1.0
    // (no penalizamos aqui; eso lo hace OperarioPuedeHacerOperacion).
    function GetFactorEficienciaPara(OperarioId: Integer;
      const Operacion: string): Double;

    // === Migracion desde modelo viejo ===
    procedure MigrarDesdeOperatorSkill(const Capacitacions: TArray<TCapacitacion>);

    // === Sample data ===
    procedure LoadSampleData;
  end;

implementation

uses
  System.StrUtils, System.Math;

constructor THabilidadRepo.Create;
begin
  inherited;
  FHabilidades := TList<THabilidad>.Create;
  FOperarioHab := TList<TOperarioHabilidad>.Create;
  FOperacionHab := TList<TOperacionHabilidad>.Create;
  FConn := nil;
  FCodigoEmpresa := 0;
end;

destructor THabilidadRepo.Destroy;
begin
  FHabilidades.Free;
  FOperarioHab.Free;
  FOperacionHab.Free;
  inherited;
end;

// ---------------------------------------------------------------- DB plumbing

procedure THabilidadRepo.SetConnection(AConn: TADOConnection;
  ACodigoEmpresa: SmallInt);
begin
  FConn := AConn;
  FCodigoEmpresa := ACodigoEmpresa;
end;

function THabilidadRepo.HasDB: Boolean;
begin
  Result := Assigned(FConn) and FConn.Connected;
end;

function THabilidadRepo.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

procedure THabilidadRepo.ExecSQL(const ASQL: string);
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

procedure THabilidadRepo.ClearAll;
begin
  FHabilidades.Clear;
  FOperarioHab.Clear;
  FOperacionHab.Clear;
end;

procedure THabilidadRepo.LoadFromDB;
var
  Q: TADOQuery;
  H: THabilidad;
  OH: TOperarioHabilidad;
  OpH: TOperacionHabilidad;
  CE: string;
begin
  if not HasDB then Exit;
  ClearAll;
  CE := IntToStr(FCodigoEmpresa);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;

    // Catalogo
    Q.SQL.Text :=
      'SELECT Codigo, ISNULL(Descripcion, '''') AS Descripcion ' +
      'FROM FS_PL_Habilidad WHERE CodigoEmpresa = ' + CE + ' ORDER BY Codigo';
    Q.Open;
    while not Q.Eof do
    begin
      H.Codigo := Q.FieldByName('Codigo').AsString;
      H.Descripcion := Q.FieldByName('Descripcion').AsString;
      FHabilidades.Add(H);
      Q.Next;
    end;
    Q.Close;

    // Operario-Habilidad
    Q.SQL.Text :=
      'SELECT OperatorId, CodHabilidad, Nivel, ' +
      '       ISNULL(FactorEficiencia, 1.0) AS Factor ' +
      'FROM FS_PL_OperarioHabilidad WHERE CodigoEmpresa = ' + CE;
    Q.Open;
    while not Q.Eof do
    begin
      OH.OperarioId := Q.FieldByName('OperatorId').AsInteger;
      OH.CodHabilidad := Q.FieldByName('CodHabilidad').AsString;
      OH.Nivel := TinyIntToNivelSkill(Byte(Q.FieldByName('Nivel').AsInteger));
      OH.FactorEficiencia := Q.FieldByName('Factor').AsFloat;
      FOperarioHab.Add(OH);
      Q.Next;
    end;
    Q.Close;

    // Operacion-Habilidad
    Q.SQL.Text :=
      'SELECT Operacion, CodHabilidad, ISNULL(NivelMinimo, 0) AS NivelMin ' +
      'FROM FS_PL_OperacionHabilidad WHERE CodigoEmpresa = ' + CE;
    Q.Open;
    while not Q.Eof do
    begin
      OpH.Operacion := Q.FieldByName('Operacion').AsString;
      OpH.CodHabilidad := Q.FieldByName('CodHabilidad').AsString;
      OpH.NivelMinimo := TinyIntToNivelSkill(
        Byte(Q.FieldByName('NivelMin').AsInteger));
      FOperacionHab.Add(OpH);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

procedure THabilidadRepo.DBUpsertHabilidad(const H: THabilidad);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  ExecSQL(Format(
    'IF EXISTS (SELECT 1 FROM FS_PL_Habilidad WHERE CodigoEmpresa = %s AND Codigo = %s) ' +
    'UPDATE FS_PL_Habilidad SET Descripcion = %s WHERE CodigoEmpresa = %s AND Codigo = %s ' +
    'ELSE INSERT INTO FS_PL_Habilidad (CodigoEmpresa, Codigo, Descripcion) VALUES (%s, %s, %s)',
    [CE, QStr(H.Codigo), QStr(H.Descripcion), CE, QStr(H.Codigo),
     CE, QStr(H.Codigo), QStr(H.Descripcion)]));
end;

procedure THabilidadRepo.DBDeleteHabilidad(const Codigo: string);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  // Borrar dependencias primero (las FK no son ON DELETE CASCADE en este caso)
  ExecSQL(Format(
    'DELETE FROM FS_PL_OperarioHabilidad WHERE CodigoEmpresa = %s AND CodHabilidad = %s',
    [CE, QStr(Codigo)]));
  ExecSQL(Format(
    'DELETE FROM FS_PL_OperacionHabilidad WHERE CodigoEmpresa = %s AND CodHabilidad = %s',
    [CE, QStr(Codigo)]));
  ExecSQL(Format(
    'DELETE FROM FS_PL_Habilidad WHERE CodigoEmpresa = %s AND Codigo = %s',
    [CE, QStr(Codigo)]));
end;

procedure THabilidadRepo.DBUpsertOperarioHab(const Item: TOperarioHabilidad);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  ExecSQL(Format(
    'IF EXISTS (SELECT 1 FROM FS_PL_OperarioHabilidad WHERE CodigoEmpresa = %s AND OperatorId = %d AND CodHabilidad = %s) ' +
    'UPDATE FS_PL_OperarioHabilidad SET Nivel = %d, FactorEficiencia = %s ' +
    '  WHERE CodigoEmpresa = %s AND OperatorId = %d AND CodHabilidad = %s ' +
    'ELSE INSERT INTO FS_PL_OperarioHabilidad (CodigoEmpresa, OperatorId, CodHabilidad, Nivel, FactorEficiencia) ' +
    '  VALUES (%s, %d, %s, %d, %s)',
    [CE, Item.OperarioId, QStr(Item.CodHabilidad),
     Ord(Item.Nivel),
     FloatToStr(Item.FactorEficiencia, TFormatSettings.Invariant),
     CE, Item.OperarioId, QStr(Item.CodHabilidad),
     CE, Item.OperarioId, QStr(Item.CodHabilidad),
     Ord(Item.Nivel),
     FloatToStr(Item.FactorEficiencia, TFormatSettings.Invariant)]));
end;

procedure THabilidadRepo.DBDeleteOperarioHab(OperarioId: Integer;
  const CodHabilidad: string);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  ExecSQL(Format(
    'DELETE FROM FS_PL_OperarioHabilidad WHERE CodigoEmpresa = %s AND OperatorId = %d AND CodHabilidad = %s',
    [CE, OperarioId, QStr(CodHabilidad)]));
end;

procedure THabilidadRepo.DBClearOperarioHab(OperarioId: Integer);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  ExecSQL(Format(
    'DELETE FROM FS_PL_OperarioHabilidad WHERE CodigoEmpresa = %s AND OperatorId = %d',
    [CE, OperarioId]));
end;

procedure THabilidadRepo.DBUpsertOperacionHab(const Item: TOperacionHabilidad);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  ExecSQL(Format(
    'IF EXISTS (SELECT 1 FROM FS_PL_OperacionHabilidad WHERE CodigoEmpresa = %s AND Operacion = %s AND CodHabilidad = %s) ' +
    'UPDATE FS_PL_OperacionHabilidad SET NivelMinimo = %d ' +
    '  WHERE CodigoEmpresa = %s AND Operacion = %s AND CodHabilidad = %s ' +
    'ELSE INSERT INTO FS_PL_OperacionHabilidad (CodigoEmpresa, Operacion, CodHabilidad, NivelMinimo) ' +
    '  VALUES (%s, %s, %s, %d)',
    [CE, QStr(Item.Operacion), QStr(Item.CodHabilidad),
     Ord(Item.NivelMinimo),
     CE, QStr(Item.Operacion), QStr(Item.CodHabilidad),
     CE, QStr(Item.Operacion), QStr(Item.CodHabilidad), Ord(Item.NivelMinimo)]));
end;

procedure THabilidadRepo.DBDeleteOperacionHab(const Operacion,
  CodHabilidad: string);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  ExecSQL(Format(
    'DELETE FROM FS_PL_OperacionHabilidad WHERE CodigoEmpresa = %s AND Operacion = %s AND CodHabilidad = %s',
    [CE, QStr(Operacion), QStr(CodHabilidad)]));
end;

procedure THabilidadRepo.DBClearOperacionHab(const Operacion: string);
var
  CE: string;
begin
  if not HasDB then Exit;
  CE := IntToStr(FCodigoEmpresa);
  ExecSQL(Format(
    'DELETE FROM FS_PL_OperacionHabilidad WHERE CodigoEmpresa = %s AND Operacion = %s',
    [CE, QStr(Operacion)]));
end;

// ---------------------------------------------------------------- Catalogo

procedure THabilidadRepo.AddHabilidad(const H: THabilidad);
begin
  if not HabilidadExiste(H.Codigo) then
  begin
    FHabilidades.Add(H);
    DBUpsertHabilidad(H);
  end;
end;

procedure THabilidadRepo.UpdateHabilidad(const H: THabilidad);
var
  I: Integer;
begin
  for I := 0 to FHabilidades.Count - 1 do
    if SameText(FHabilidades[I].Codigo, H.Codigo) then
    begin
      FHabilidades[I] := H;
      DBUpsertHabilidad(H);
      Exit;
    end;
end;

procedure THabilidadRepo.RemoveHabilidad(const Codigo: string);
var
  I: Integer;
begin
  // Quitar referencias en relaciones
  for I := FOperarioHab.Count - 1 downto 0 do
    if SameText(FOperarioHab[I].CodHabilidad, Codigo) then
      FOperarioHab.Delete(I);
  for I := FOperacionHab.Count - 1 downto 0 do
    if SameText(FOperacionHab[I].CodHabilidad, Codigo) then
      FOperacionHab.Delete(I);
  // Quitar del catalogo
  for I := FHabilidades.Count - 1 downto 0 do
    if SameText(FHabilidades[I].Codigo, Codigo) then
      FHabilidades.Delete(I);
  DBDeleteHabilidad(Codigo);
end;

function THabilidadRepo.GetHabilidades: TArray<THabilidad>;
begin
  Result := FHabilidades.ToArray;
end;

function THabilidadRepo.GetHabilidad(const Codigo: string;
  out H: THabilidad): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FHabilidades.Count - 1 do
    if SameText(FHabilidades[I].Codigo, Codigo) then
    begin
      H := FHabilidades[I];
      Exit(True);
    end;
end;

function THabilidadRepo.HabilidadExiste(const Codigo: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to FHabilidades.Count - 1 do
    if SameText(FHabilidades[I].Codigo, Codigo) then
      Exit(True);
  Result := False;
end;

function THabilidadRepo.EnsureHabilidad(const Codigo,
  Descripcion: string): Boolean;
var
  H: THabilidad;
begin
  if HabilidadExiste(Codigo) then Exit(False);
  H.Codigo := Codigo;
  H.Descripcion := Descripcion;
  FHabilidades.Add(H);
  DBUpsertHabilidad(H);
  Result := True;
end;

// ---------------------------------------------------------- Operario-Habilidad

procedure THabilidadRepo.SetOperarioHabilidad(OperarioId: Integer;
  const CodHabilidad: string; Nivel: TNivelSkill; FactorEficiencia: Double);
var
  I: Integer;
  Item: TOperarioHabilidad;
begin
  for I := 0 to FOperarioHab.Count - 1 do
    if (FOperarioHab[I].OperarioId = OperarioId) and
       SameText(FOperarioHab[I].CodHabilidad, CodHabilidad) then
    begin
      Item := FOperarioHab[I];
      Item.Nivel := Nivel;
      Item.FactorEficiencia := FactorEficiencia;
      FOperarioHab[I] := Item;
      DBUpsertOperarioHab(Item);
      Exit;
    end;
  Item.OperarioId := OperarioId;
  Item.CodHabilidad := CodHabilidad;
  Item.Nivel := Nivel;
  Item.FactorEficiencia := FactorEficiencia;
  FOperarioHab.Add(Item);
  DBUpsertOperarioHab(Item);
end;

procedure THabilidadRepo.RemoveOperarioHabilidad(OperarioId: Integer;
  const CodHabilidad: string);
var
  I: Integer;
begin
  for I := FOperarioHab.Count - 1 downto 0 do
    if (FOperarioHab[I].OperarioId = OperarioId) and
       SameText(FOperarioHab[I].CodHabilidad, CodHabilidad) then
      FOperarioHab.Delete(I);
  DBDeleteOperarioHab(OperarioId, CodHabilidad);
end;

procedure THabilidadRepo.ClearOperarioHabilidades(OperarioId: Integer);
var
  I: Integer;
begin
  for I := FOperarioHab.Count - 1 downto 0 do
    if FOperarioHab[I].OperarioId = OperarioId then
      FOperarioHab.Delete(I);
  DBClearOperarioHab(OperarioId);
end;

function THabilidadRepo.GetHabilidadesOperario(
  OperarioId: Integer): TArray<TOperarioHabilidad>;
var
  L: TList<TOperarioHabilidad>;
  I: Integer;
begin
  L := TList<TOperarioHabilidad>.Create;
  try
    for I := 0 to FOperarioHab.Count - 1 do
      if FOperarioHab[I].OperarioId = OperarioId then
        L.Add(FOperarioHab[I]);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function THabilidadRepo.OperarioTieneHabilidad(OperarioId: Integer;
  const CodHabilidad: string; NivelMinimo: TNivelSkill): Boolean;
var
  N: TNivelSkill;
begin
  Result := OperarioNivelEn(OperarioId, CodHabilidad, N) and (N >= NivelMinimo);
end;

function THabilidadRepo.OperarioNivelEn(OperarioId: Integer;
  const CodHabilidad: string; out Nivel: TNivelSkill): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FOperarioHab.Count - 1 do
    if (FOperarioHab[I].OperarioId = OperarioId) and
       SameText(FOperarioHab[I].CodHabilidad, CodHabilidad) then
    begin
      Nivel := FOperarioHab[I].Nivel;
      Exit(True);
    end;
end;

// --------------------------------------------------------- Operacion-Habilidad

procedure THabilidadRepo.SetOperacionHabilidad(const Operacion,
  CodHabilidad: string; NivelMinimo: TNivelSkill);
var
  I: Integer;
  Item: TOperacionHabilidad;
begin
  for I := 0 to FOperacionHab.Count - 1 do
    if SameText(FOperacionHab[I].Operacion, Operacion) and
       SameText(FOperacionHab[I].CodHabilidad, CodHabilidad) then
    begin
      Item := FOperacionHab[I];
      Item.NivelMinimo := NivelMinimo;
      FOperacionHab[I] := Item;
      DBUpsertOperacionHab(Item);
      Exit;
    end;
  Item.Operacion := Operacion;
  Item.CodHabilidad := CodHabilidad;
  Item.NivelMinimo := NivelMinimo;
  FOperacionHab.Add(Item);
  DBUpsertOperacionHab(Item);
end;

procedure THabilidadRepo.RemoveOperacionHabilidad(const Operacion,
  CodHabilidad: string);
var
  I: Integer;
begin
  for I := FOperacionHab.Count - 1 downto 0 do
    if SameText(FOperacionHab[I].Operacion, Operacion) and
       SameText(FOperacionHab[I].CodHabilidad, CodHabilidad) then
      FOperacionHab.Delete(I);
  DBDeleteOperacionHab(Operacion, CodHabilidad);
end;

procedure THabilidadRepo.ClearOperacionHabilidades(const Operacion: string);
var
  I: Integer;
begin
  for I := FOperacionHab.Count - 1 downto 0 do
    if SameText(FOperacionHab[I].Operacion, Operacion) then
      FOperacionHab.Delete(I);
  DBClearOperacionHab(Operacion);
end;

function THabilidadRepo.GetHabilidadesOperacion(
  const Operacion: string): TArray<TOperacionHabilidad>;
var
  L: TList<TOperacionHabilidad>;
  I: Integer;
begin
  L := TList<TOperacionHabilidad>.Create;
  try
    for I := 0 to FOperacionHab.Count - 1 do
      if SameText(FOperacionHab[I].Operacion, Operacion) then
        L.Add(FOperacionHab[I]);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

// ----------------------------------------------------------- Consultas combinadas

function THabilidadRepo.OperarioPuedeHacerOperacion(OperarioId: Integer;
  const Operacion: string; out MotivoFallo: string): Boolean;
var
  Reqs: TArray<TOperacionHabilidad>;
  I: Integer;
  Nivel: TNivelSkill;
begin
  MotivoFallo := '';
  Reqs := GetHabilidadesOperacion(Operacion);
  // Si la operacion no exige habilidades, cualquiera puede hacerla
  if Length(Reqs) = 0 then Exit(True);
  for I := 0 to High(Reqs) do
  begin
    if not OperarioNivelEn(OperarioId, Reqs[I].CodHabilidad, Nivel) then
    begin
      MotivoFallo := Format('Carece habilidad %s', [Reqs[I].CodHabilidad]);
      Exit(False);
    end;
    if Nivel < Reqs[I].NivelMinimo then
    begin
      MotivoFallo := Format('Nivel insuficiente en %s (tiene %d, requiere %d)',
        [Reqs[I].CodHabilidad, Ord(Nivel), Ord(Reqs[I].NivelMinimo)]);
      Exit(False);
    end;
  end;
  Result := True;
end;

function THabilidadRepo.GetOperariosCapacitadosPara(
  const Operacion: string): TArray<Integer>;
var
  Result_: TList<Integer>;
  Seen: TDictionary<Integer, Boolean>;
  I: Integer;
  Motivo: string;
  OpId: Integer;
begin
  Result_ := TList<Integer>.Create;
  Seen := TDictionary<Integer, Boolean>.Create;
  try
    // Recorrer todos los operarios que tienen al menos una habilidad
    for I := 0 to FOperarioHab.Count - 1 do
    begin
      OpId := FOperarioHab[I].OperarioId;
      if Seen.ContainsKey(OpId) then Continue;
      Seen.Add(OpId, True);
      if OperarioPuedeHacerOperacion(OpId, Operacion, Motivo) then
        Result_.Add(OpId);
    end;
    Result := Result_.ToArray;
  finally
    Seen.Free;
    Result_.Free;
  end;
end;

function THabilidadRepo.GetSobrenivel(OperarioId: Integer;
  const Operacion: string): Integer;
var
  Reqs: TArray<TOperacionHabilidad>;
  I: Integer;
  N: TNivelSkill;
begin
  Result := 0;
  Reqs := GetHabilidadesOperacion(Operacion);
  for I := 0 to High(Reqs) do
    if OperarioNivelEn(OperarioId, Reqs[I].CodHabilidad, N) then
      Result := Result + Max(0, Ord(N) - Ord(Reqs[I].NivelMinimo));
end;

function THabilidadRepo.GetFactorEficienciaPara(OperarioId: Integer;
  const Operacion: string): Double;
var
  Reqs: TArray<TOperacionHabilidad>;
  I, J, Cnt: Integer;
  Suma, Factor: Double;
begin
  Reqs := GetHabilidadesOperacion(Operacion);
  if Length(Reqs) = 0 then Exit(1.0);

  Suma := 0;
  Cnt := 0;
  for I := 0 to High(Reqs) do
  begin
    Factor := 1.0;  // si el operario no tiene la habilidad, neutral
    for J := 0 to FOperarioHab.Count - 1 do
      if (FOperarioHab[J].OperarioId = OperarioId) and
         SameText(FOperarioHab[J].CodHabilidad, Reqs[I].CodHabilidad) then
      begin
        Factor := FOperarioHab[J].FactorEficiencia;
        if Factor <= 0 then Factor := 1.0;
        Break;
      end;
    Suma := Suma + Factor;
    Inc(Cnt);
  end;

  if Cnt = 0 then Exit(1.0);
  Result := Suma / Cnt;
end;

// ----------------------------------------------------------- Migracion

procedure THabilidadRepo.MigrarDesdeOperatorSkill(
  const Capacitacions: TArray<TCapacitacion>);
var
  I: Integer;
  Cap: TCapacitacion;
begin
  for I := 0 to High(Capacitacions) do
  begin
    Cap := Capacitacions[I];
    // Crear habilidad homonima si no existe
    EnsureHabilidad(Cap.Operacion, 'Migrada desde capacitacion');
    // La operacion exige esta habilidad con nivel 0 (cualquiera basta)
    SetOperacionHabilidad(Cap.Operacion, Cap.Operacion, nsAprendiz);
    // Operario tiene esa habilidad con su nivel original
    SetOperarioHabilidad(Cap.OperarioId, Cap.Operacion, Cap.Nivel,
      Cap.FactorEficiencia);
  end;
end;

// ----------------------------------------------------------- Sample data

procedure THabilidadRepo.LoadSampleData;
begin
  // ----- Cat'alogo de habilidades coherente con operaciones sample -----

  // Transversales
  EnsureHabilidad('SEGURIDAD', 'Formaci'#243'n general en seguridad laboral');
  EnsureHabilidad('LECT_PLANO', 'Lectura de planos t'#233'cnicos');
  EnsureHabilidad('CARRETILLA', 'Carnet de carretillero');

  // Familias de operaciones
  EnsureHabilidad('PINTURA', 'Pintura y lacado (PINTAR, LACAR)');
  EnsureHabilidad('MECANIZADO', 'Mecanizado (FRESAR, TORNEAR, TALADRAR, RECTIFICAR)');
  EnsureHabilidad('SOLDADURA', 'Soldadura (SOLDAR)');
  EnsureHabilidad('MONTAJE', 'Montaje y ensamblaje (MONTAR)');
  EnsureHabilidad('ACABADO', 'Pulido y bronceado (PULIR, BRONCEAR)');
  EnsureHabilidad('CORTE', 'Corte de material (CORTAR)');
  EnsureHabilidad('EMBALAJE', 'Embalaje final (EMBALAR)');

  // ----- Vinculo Operacion -> Habilidades requeridas -----
  // Cada operacion exige UNA habilidad familia con nivel m'inimo.
  // SEGURIDAD se exige a operaciones de riesgo.

  // Pintura (paralelizable)
  SetOperacionHabilidad('PINTAR', 'PINTURA', nsJunior);
  SetOperacionHabilidad('LACAR', 'PINTURA', nsJunior);

  // Acabado
  SetOperacionHabilidad('PULIR', 'ACABADO', nsAprendiz);
  SetOperacionHabilidad('BRONCEAR', 'ACABADO', nsJunior);

  // Embalaje y montaje
  SetOperacionHabilidad('EMBALAR', 'EMBALAJE', nsAprendiz);
  SetOperacionHabilidad('MONTAR', 'MONTAJE', nsJunior);
  SetOperacionHabilidad('MONTAR', 'LECT_PLANO', nsJunior);  // 2 habilidades

  // Corte
  SetOperacionHabilidad('CORTAR', 'CORTE', nsJunior);
  SetOperacionHabilidad('CORTAR', 'SEGURIDAD', nsAprendiz);

  // Mecanizado: SEGURIDAD + plano + skill especifica
  SetOperacionHabilidad('TALADRAR', 'MECANIZADO', nsAprendiz);
  SetOperacionHabilidad('TALADRAR', 'SEGURIDAD', nsAprendiz);

  SetOperacionHabilidad('FRESAR', 'MECANIZADO', nsSenior);  // requiere experiencia
  SetOperacionHabilidad('FRESAR', 'LECT_PLANO', nsJunior);
  SetOperacionHabilidad('FRESAR', 'SEGURIDAD', nsAprendiz);

  SetOperacionHabilidad('TORNEAR', 'MECANIZADO', nsSenior);
  SetOperacionHabilidad('TORNEAR', 'LECT_PLANO', nsJunior);
  SetOperacionHabilidad('TORNEAR', 'SEGURIDAD', nsAprendiz);

  SetOperacionHabilidad('RECTIFICAR', 'MECANIZADO', nsExperto);  // muy especializado
  SetOperacionHabilidad('RECTIFICAR', 'LECT_PLANO', nsSenior);
  SetOperacionHabilidad('RECTIFICAR', 'SEGURIDAD', nsAprendiz);

  // Soldadura: especializado + seguridad
  SetOperacionHabilidad('SOLDAR', 'SOLDADURA', nsJunior);
  SetOperacionHabilidad('SOLDAR', 'SEGURIDAD', nsJunior);
end;

end.
