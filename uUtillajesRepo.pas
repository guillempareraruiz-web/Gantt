unit uUtillajesRepo;

// Repositorio SQL para FS_PL_Utillaje (catalogo maestro de utillajes).
// Consumido por uGestionUtillajes (CRUD) y uUtillajePicker (modal seleccion).

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  Data.Win.ADODB, Data.DB;

type
  TUtillaje = record
    Id: Integer;
    Codigo: string;
    Descripcion: string;
    Tipo: string;
    Ubicacion: string;
    Disponible: Boolean;
    Observaciones: string;
    Activo: Boolean;
    Orden: Integer;
  end;

  TUtillajesRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    function QStr(const S: string): string;
    function QStrNullable(const S: string): string;
    procedure Exec(const ASQL: string);
    procedure ReadFromQuery(Q: TADOQuery; out U: TUtillaje);
  public
    constructor Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt);

    function LoadAll: TArray<TUtillaje>;
    function LoadActive: TArray<TUtillaje>;
    function GetByCodigo(const ACodigo: string; out AUtil: TUtillaje): Boolean;

    function Insert(const AUtil: TUtillaje): Integer;
    procedure Update(const AUtil: TUtillaje);
    procedure Delete(AId: Integer);
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

procedure TUtillajesRepo.ReadFromQuery(Q: TADOQuery; out U: TUtillaje);
begin
  U.Id := Q.FieldByName('UtillajeId').AsInteger;
  U.Codigo := Q.FieldByName('Codigo').AsString;
  U.Descripcion := Q.FieldByName('Descripcion').AsString;
  U.Tipo := Q.FieldByName('Tipo').AsString;
  U.Ubicacion := Q.FieldByName('Ubicacion').AsString;
  U.Disponible := Q.FieldByName('Disponible').AsBoolean;
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
      Q.SQL.Text :=
        'SELECT UtillajeId, Codigo, ISNULL(Descripcion, '''') AS Descripcion, ' +
        '  ISNULL(Tipo, '''') AS Tipo, ISNULL(Ubicacion, '''') AS Ubicacion, ' +
        '  Disponible, ISNULL(Observaciones, '''') AS Observaciones, ' +
        '  Activo, Orden ' +
        'FROM FS_PL_Utillaje WHERE CodigoEmpresa = :CE ' +
        'ORDER BY Orden, Codigo';
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
      Q.SQL.Text :=
        'SELECT UtillajeId, Codigo, ISNULL(Descripcion, '''') AS Descripcion, ' +
        '  ISNULL(Tipo, '''') AS Tipo, ISNULL(Ubicacion, '''') AS Ubicacion, ' +
        '  Disponible, ISNULL(Observaciones, '''') AS Observaciones, ' +
        '  Activo, Orden ' +
        'FROM FS_PL_Utillaje WHERE CodigoEmpresa = :CE AND Activo = 1 ' +
        'ORDER BY Orden, Codigo';
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
    Q.SQL.Text :=
      'SELECT UtillajeId, Codigo, ISNULL(Descripcion, '''') AS Descripcion, ' +
      '  ISNULL(Tipo, '''') AS Tipo, ISNULL(Ubicacion, '''') AS Ubicacion, ' +
      '  Disponible, ISNULL(Observaciones, '''') AS Observaciones, ' +
      '  Activo, Orden ' +
      'FROM FS_PL_Utillaje WHERE CodigoEmpresa = :CE AND Codigo = :Cod';
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
      '  Ubicacion, Disponible, Observaciones, Activo, Orden) ' +
      'OUTPUT INSERTED.UtillajeId ' +
      'VALUES (' + IntToStr(FCodigoEmpresa) + ', ' +
      QStr(AUtil.Codigo) + ', ' +
      QStrNullable(AUtil.Descripcion) + ', ' +
      QStrNullable(AUtil.Tipo) + ', ' +
      QStrNullable(AUtil.Ubicacion) + ', ' +
      IntToStr(Ord(AUtil.Disponible)) + ', ' +
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
    '  Ubicacion = ' + QStrNullable(AUtil.Ubicacion) + ', ' +
    '  Disponible = ' + IntToStr(Ord(AUtil.Disponible)) + ', ' +
    '  Observaciones = ' + QStrNullable(AUtil.Observaciones) + ', ' +
    '  Activo = ' + IntToStr(Ord(AUtil.Activo)) + ', ' +
    '  Orden = ' + IntToStr(AUtil.Orden) + ', ' +
    '  FechaModificacion = SYSDATETIME() ' +
    'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
    '  AND UtillajeId = ' + IntToStr(AUtil.Id));
end;

procedure TUtillajesRepo.Delete(AId: Integer);
begin
  Exec('DELETE FROM FS_PL_Utillaje WHERE CodigoEmpresa = ' +
    IntToStr(FCodigoEmpresa) + ' AND UtillajeId = ' + IntToStr(AId));
end;

end.
