unit uMaquinasRepo;

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  Data.Win.ADODB, Data.DB;

const
  // EstadoOperativo
  MAQ_ESTADO_DISPONIBLE   = 0;
  MAQ_ESTADO_MANTENIMENT  = 1;
  MAQ_ESTADO_AVERIADA     = 2;
  MAQ_ESTADO_BAJA         = 3;

type
  TMaquina = record
    Id: Integer;
    Codigo: string;
    Nombre: string;
    Activo: Boolean;
    Orden: Integer;

    // Fitxa tecnica
    Descripcion: string;
    Modelo: string;
    NumeroSerie: string;
    Fabricante: string;
    TipoMaquina: string;
    FechaPuestaEnMarcha: TDateTime;   // 0 = sin valor
    FechaPuestaEnMarchaNull: Boolean;

    // Capacitat i rendiment
    EfficiencyFactor: Double;
    MaxLoadPercent: Integer;
    CostPerHour: Double;

    // Planificacio
    EsPlanificable: Boolean;
    EsCuelloBotella: Boolean;
    PrioridadAsignacion: Integer;
    EstadoOperativo: Integer;

    // Manteniment
    HorasFuncionamiento: Double;
    FechaProxRevision: TDateTime;
    FechaProxRevisionNull: Boolean;
  end;

  TCentroMaquinaLink = record
    MaquinaId: Integer;
    EsPrincipal: Boolean;
    Prioridad: Integer;
  end;

  TMaquinasRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    FMaquinas: TArray<TMaquina>;
    function QStr(const S: string): string;
    function QStrNullable(const S: string): string;
    function QDecimal(D: Double): string;
    function QDateNullable(D: TDateTime; IsNull: Boolean): string;
    procedure Exec(const ASQL: string);
    procedure ReadMaquinaFromQuery(Q: TADOQuery; out M: TMaquina);
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

    // Nueva: relacion con atributos
    function GetLinksForCentro(ACenterId: Integer): TArray<TCentroMaquinaLink>;
    procedure SetMaquinaLink(ACenterId, AMaquinaId: Integer;
      AEsPrincipal: Boolean; APrioridad: Integer);
  end;

function EstadoOperativoText(AEstado: Integer): string;
function TextToEstadoOperativo(const S: string): Integer;

implementation

function EstadoOperativoText(AEstado: Integer): string;
begin
  case AEstado of
    MAQ_ESTADO_DISPONIBLE:  Result := 'Disponible';
    MAQ_ESTADO_MANTENIMENT: Result := 'Mantenimiento';
    MAQ_ESTADO_AVERIADA:    Result := 'Averiada';
    MAQ_ESTADO_BAJA:        Result := 'Baja';
  else
    Result := 'Disponible';
  end;
end;

function TextToEstadoOperativo(const S: string): Integer;
begin
  if SameText(S, 'Mantenimiento') then Result := MAQ_ESTADO_MANTENIMENT
  else if SameText(S, 'Averiada')    then Result := MAQ_ESTADO_AVERIADA
  else if SameText(S, 'Baja')        then Result := MAQ_ESTADO_BAJA
  else Result := MAQ_ESTADO_DISPONIBLE;
end;

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

function TMaquinasRepo.QStrNullable(const S: string): string;
begin
  if Trim(S) = '' then
    Result := 'NULL'
  else
    Result := QStr(S);
end;

function TMaquinasRepo.QDecimal(D: Double): string;
begin
  Result := FloatToStr(D, TFormatSettings.Invariant);
end;

function TMaquinasRepo.QDateNullable(D: TDateTime; IsNull: Boolean): string;
begin
  if IsNull or (D = 0) then
    Result := 'NULL'
  else
    Result := '''' + FormatDateTime('yyyy-mm-dd', D) + '''';
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

procedure TMaquinasRepo.ReadMaquinaFromQuery(Q: TADOQuery; out M: TMaquina);
var
  F: TField;
begin
  M.Id := Q.FieldByName('MaquinaId').AsInteger;
  M.Codigo := Q.FieldByName('Codigo').AsString;
  M.Nombre := Q.FieldByName('Nombre').AsString;
  M.Activo := Q.FieldByName('Activo').AsBoolean;
  M.Orden := Q.FieldByName('Orden').AsInteger;

  M.Descripcion := Q.FieldByName('Descripcion').AsString;
  M.Modelo := Q.FieldByName('Modelo').AsString;
  M.NumeroSerie := Q.FieldByName('NumeroSerie').AsString;
  M.Fabricante := Q.FieldByName('Fabricante').AsString;
  M.TipoMaquina := Q.FieldByName('TipoMaquina').AsString;

  F := Q.FieldByName('FechaPuestaEnMarcha');
  M.FechaPuestaEnMarchaNull := F.IsNull;
  if F.IsNull then M.FechaPuestaEnMarcha := 0 else M.FechaPuestaEnMarcha := F.AsDateTime;

  M.EfficiencyFactor := Q.FieldByName('EfficiencyFactor').AsFloat;
  M.MaxLoadPercent := Q.FieldByName('MaxLoadPercent').AsInteger;
  M.CostPerHour := Q.FieldByName('CostPerHour').AsFloat;

  M.EsPlanificable := Q.FieldByName('EsPlanificable').AsBoolean;
  M.EsCuelloBotella := Q.FieldByName('EsCuelloBotella').AsBoolean;
  M.PrioridadAsignacion := Q.FieldByName('PrioridadAsignacion').AsInteger;
  M.EstadoOperativo := Q.FieldByName('EstadoOperativo').AsInteger;

  M.HorasFuncionamiento := Q.FieldByName('HorasFuncionamiento').AsFloat;
  F := Q.FieldByName('FechaProxRevision');
  M.FechaProxRevisionNull := F.IsNull;
  if F.IsNull then M.FechaProxRevision := 0 else M.FechaProxRevision := F.AsDateTime;
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
      'SELECT MaquinaId, Codigo, Nombre, Activo, Orden, ' +
      '  Descripcion, Modelo, NumeroSerie, Fabricante, TipoMaquina, ' +
      '  FechaPuestaEnMarcha, EfficiencyFactor, MaxLoadPercent, CostPerHour, ' +
      '  EsPlanificable, EsCuelloBotella, PrioridadAsignacion, EstadoOperativo, ' +
      '  HorasFuncionamiento, FechaProxRevision ' +
      'FROM FS_PL_Maquina ' +
      'WHERE CodigoEmpresa = :CodigoEmpresa ' +
      'ORDER BY Orden, Codigo';
    Q.Parameters.ParamByName('CodigoEmpresa').Value := FCodigoEmpresa;
    Q.Open;

    SetLength(FMaquinas, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      ReadMaquinaFromQuery(Q, M);
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
      'INSERT INTO FS_PL_Maquina (CodigoEmpresa, Codigo, Nombre, Activo, Orden, ' +
      '  Descripcion, Modelo, NumeroSerie, Fabricante, TipoMaquina, ' +
      '  FechaPuestaEnMarcha, EfficiencyFactor, MaxLoadPercent, CostPerHour, ' +
      '  EsPlanificable, EsCuelloBotella, PrioridadAsignacion, EstadoOperativo, ' +
      '  HorasFuncionamiento, FechaProxRevision) ' +
      'OUTPUT INSERTED.MaquinaId ' +
      'VALUES (' + IntToStr(FCodigoEmpresa) + ', ' +
      QStr(AMaq.Codigo) + ', ' + QStr(AMaq.Nombre) + ', ' +
      IntToStr(Ord(AMaq.Activo)) + ', ' + IntToStr(AMaq.Orden) + ', ' +
      QStrNullable(AMaq.Descripcion) + ', ' +
      QStrNullable(AMaq.Modelo) + ', ' +
      QStrNullable(AMaq.NumeroSerie) + ', ' +
      QStrNullable(AMaq.Fabricante) + ', ' +
      QStrNullable(AMaq.TipoMaquina) + ', ' +
      QDateNullable(AMaq.FechaPuestaEnMarcha, AMaq.FechaPuestaEnMarchaNull) + ', ' +
      QDecimal(AMaq.EfficiencyFactor) + ', ' +
      IntToStr(AMaq.MaxLoadPercent) + ', ' +
      QDecimal(AMaq.CostPerHour) + ', ' +
      IntToStr(Ord(AMaq.EsPlanificable)) + ', ' +
      IntToStr(Ord(AMaq.EsCuelloBotella)) + ', ' +
      IntToStr(AMaq.PrioridadAsignacion) + ', ' +
      IntToStr(AMaq.EstadoOperativo) + ', ' +
      QDecimal(AMaq.HorasFuncionamiento) + ', ' +
      QDateNullable(AMaq.FechaProxRevision, AMaq.FechaProxRevisionNull) + ')';
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
    '  Descripcion = ' + QStrNullable(AMaq.Descripcion) + ', ' +
    '  Modelo = ' + QStrNullable(AMaq.Modelo) + ', ' +
    '  NumeroSerie = ' + QStrNullable(AMaq.NumeroSerie) + ', ' +
    '  Fabricante = ' + QStrNullable(AMaq.Fabricante) + ', ' +
    '  TipoMaquina = ' + QStrNullable(AMaq.TipoMaquina) + ', ' +
    '  FechaPuestaEnMarcha = ' + QDateNullable(AMaq.FechaPuestaEnMarcha, AMaq.FechaPuestaEnMarchaNull) + ', ' +
    '  EfficiencyFactor = ' + QDecimal(AMaq.EfficiencyFactor) + ', ' +
    '  MaxLoadPercent = ' + IntToStr(AMaq.MaxLoadPercent) + ', ' +
    '  CostPerHour = ' + QDecimal(AMaq.CostPerHour) + ', ' +
    '  EsPlanificable = ' + IntToStr(Ord(AMaq.EsPlanificable)) + ', ' +
    '  EsCuelloBotella = ' + IntToStr(Ord(AMaq.EsCuelloBotella)) + ', ' +
    '  PrioridadAsignacion = ' + IntToStr(AMaq.PrioridadAsignacion) + ', ' +
    '  EstadoOperativo = ' + IntToStr(AMaq.EstadoOperativo) + ', ' +
    '  HorasFuncionamiento = ' + QDecimal(AMaq.HorasFuncionamiento) + ', ' +
    '  FechaProxRevision = ' + QDateNullable(AMaq.FechaProxRevision, AMaq.FechaProxRevisionNull) + ', ' +
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

function TMaquinasRepo.GetLinksForCentro(
  ACenterId: Integer): TArray<TCentroMaquinaLink>;
var
  Q: TADOQuery;
  L: TList<TCentroMaquinaLink>;
  Lnk: TCentroMaquinaLink;
begin
  L := TList<TCentroMaquinaLink>.Create;
  try
    if FConnection = nil then Exit(L.ToArray);
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT MaquinaId, EsPrincipal, Prioridad FROM FS_PL_CentroMaquina ' +
        'WHERE CodigoEmpresa = :CodigoEmpresa AND CenterId = :CenterId ' +
        'ORDER BY Prioridad, MaquinaId';
      Q.Parameters.ParamByName('CodigoEmpresa').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('CenterId').Value := ACenterId;
      Q.Open;
      while not Q.Eof do
      begin
        Lnk.MaquinaId := Q.FieldByName('MaquinaId').AsInteger;
        Lnk.EsPrincipal := Q.FieldByName('EsPrincipal').AsBoolean;
        Lnk.Prioridad := Q.FieldByName('Prioridad').AsInteger;
        L.Add(Lnk);
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

procedure TMaquinasRepo.SetMaquinaLink(ACenterId, AMaquinaId: Integer;
  AEsPrincipal: Boolean; APrioridad: Integer);
begin
  if FConnection = nil then Exit;
  Exec(
    'UPDATE FS_PL_CentroMaquina SET ' +
    '  EsPrincipal = ' + IntToStr(Ord(AEsPrincipal)) + ', ' +
    '  Prioridad = ' + IntToStr(APrioridad) + ' ' +
    'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
    '  AND CenterId = ' + IntToStr(ACenterId) +
    '  AND MaquinaId = ' + IntToStr(AMaquinaId));
end;

end.
