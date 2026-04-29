unit uDBMigrations;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.Types,
  System.Generics.Defaults, System.Generics.Collections, Data.Win.ADODB;

type
  TMigrationResult = record
    Success: Boolean;
    ErrorMessage: string;
    MigrationsApplied: Integer;
    class function OK(ACount: Integer): TMigrationResult; static;
    class function Fail(const AMsg: string): TMigrationResult; static;
  end;

  TMigrationInfo = record
    Version: Integer;
    FileName: string;
    Description: string;
    FullPath: string;
  end;

  TDBMigrator = class
  private
    FConnection: TADOConnection;
    FMigrationsFolder: string;
    FOnLog: TProc<string>;

    procedure Log(const AMsg: string);
    procedure EnsureSchemaVersionTable;
    function GetCurrentVersion: Integer;
    function DiscoverMigrations: TArray<TMigrationInfo>;
    function ParseMigrationFileName(const AFileName: string;
      out AVersion: Integer; out ADescription: string): Boolean;
    procedure RegisterMigration(AVersion: Integer;
      const ADescription, AFileName: string);
    procedure ExecuteSQLBatch(const ASQL: string);
  public
    constructor Create(AConnection: TADOConnection; const AMigrationsFolder: string);

    function RunPendingMigrations: TMigrationResult;
    function GetMigrationStatus: TArray<TMigrationInfo>;

    property OnLog: TProc<string> read FOnLog write FOnLog;
  end;

implementation

{ TMigrationResult }

class function TMigrationResult.OK(ACount: Integer): TMigrationResult;
begin
  Result.Success := True;
  Result.ErrorMessage := '';
  Result.MigrationsApplied := ACount;
end;

class function TMigrationResult.Fail(const AMsg: string): TMigrationResult;
begin
  Result.Success := False;
  Result.ErrorMessage := AMsg;
  Result.MigrationsApplied := 0;
end;

{ TDBMigrator }

constructor TDBMigrator.Create(AConnection: TADOConnection;
  const AMigrationsFolder: string);
begin
  inherited Create;
  FConnection := AConnection;
  FMigrationsFolder := AMigrationsFolder;
end;

procedure TDBMigrator.Log(const AMsg: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AMsg);
end;

procedure TDBMigrator.EnsureSchemaVersionTable;
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''FS_PL_SchemaVersion'') ' +
      'CREATE TABLE FS_PL_SchemaVersion (' +
      '  Version INT NOT NULL PRIMARY KEY, ' +
      '  Descripcion NVARCHAR(500) NULL, ' +
      '  FileName NVARCHAR(200) NULL, ' +
      '  FechaAplicada DATETIME2 NOT NULL DEFAULT GETDATE())';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

function TDBMigrator.GetCurrentVersion: Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT ISNULL(MAX(Version), 0) AS MaxVer FROM FS_PL_SchemaVersion';
    Q.Open;
    if not Q.Eof then
      Result := Q.FieldByName('MaxVer').AsInteger;
  finally
    Q.Free;
  end;
end;

function TDBMigrator.ParseMigrationFileName(const AFileName: string;
  out AVersion: Integer; out ADescription: string): Boolean;
var
  Name: string;
  PosUnderscore: Integer;
  VersionStr: string;
begin
  Result := False;
  Name := TPath.GetFileNameWithoutExtension(AFileName);

  // Formato esperado: V001__descripcion
  if not Name.StartsWith('V', True) then Exit;

  PosUnderscore := Pos('__', Name);
  if PosUnderscore < 2 then Exit;

  VersionStr := Copy(Name, 2, PosUnderscore - 2);
  if not TryStrToInt(VersionStr, AVersion) then Exit;

  ADescription := Copy(Name, PosUnderscore + 2, MaxInt);
  ADescription := StringReplace(ADescription, '_', ' ', [rfReplaceAll]);
  Result := True;
end;

function TDBMigrator.DiscoverMigrations: TArray<TMigrationInfo>;
var
  Files: TStringDynArray;
  F: string;
  List: TList<TMigrationInfo>;
  Info: TMigrationInfo;
begin
  List := TList<TMigrationInfo>.Create;
  try
    if not TDirectory.Exists(FMigrationsFolder) then
      Exit(List.ToArray);

    Files := TDirectory.GetFiles(FMigrationsFolder, '*.sql');
    for F in Files do
    begin
      if ParseMigrationFileName(F, Info.Version, Info.Description) then
      begin
        Info.FileName := TPath.GetFileName(F);
        Info.FullPath := F;
        List.Add(Info);
      end;
    end;

    List.Sort(TComparer<TMigrationInfo>.Construct(
      function(const L, R: TMigrationInfo): Integer
      begin
        Result := L.Version - R.Version;
      end));

    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

procedure TDBMigrator.ExecuteSQLBatch(const ASQL: string);
var
  Batches: TArray<string>;
  I: Integer;
  Q: TADOQuery;
  Batch: string;
begin
  // Dividir por GO (batch separator de SQL Server)
  Batches := ASQL.Split([#13#10'GO'#13#10, #10'GO'#10, #13#10'GO', #10'GO', #13'GO'#13],
    TStringSplitOptions.None);

  for I := 0 to High(Batches) do
  begin
    Batch := Trim(Batches[I]);
    if Batch = '' then Continue;

    // Se usa TADOQuery con ParamCheck=False para que ADO no intente parsear
    // ':' ni '?' como parametros dentro del SQL (comentarios, literales TIME
    // '08:00', etc.). ExecSQL no devuelve recordset, ideal para DDL y DML.
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.ParamCheck := False;
      Q.SQL.Text := Batch;
      Q.ExecSQL;
    finally
      Q.Free;
    end;
  end;
end;

procedure TDBMigrator.RegisterMigration(AVersion: Integer;
  const ADescription, AFileName: string);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_SchemaVersion (Version, Descripcion, FileName) VALUES (' +
      IntToStr(AVersion) + ', ' +
      'N''' + StringReplace(ADescription, '''', '''''', [rfReplaceAll]) + ''', ' +
      'N''' + StringReplace(AFileName, '''', '''''', [rfReplaceAll]) + ''')';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

function TDBMigrator.RunPendingMigrations: TMigrationResult;
var
  CurrentVer: Integer;
  Migrations: TArray<TMigrationInfo>;
  M: TMigrationInfo;
  SQL: string;
  Applied: Integer;
begin
  Applied := 0;
  try
    EnsureSchemaVersionTable;
    CurrentVer := GetCurrentVersion;
    Log(Format('Versión actual de BBDD: %d', [CurrentVer]));

    Migrations := DiscoverMigrations;
    Log(Format('Migraciones encontradas: %d', [Length(Migrations)]));

    for M in Migrations do
    begin
      if M.Version <= CurrentVer then Continue;

      Log(Format('Aplicando V%.3d - %s...', [M.Version, M.Description]));
      SQL := TFile.ReadAllText(M.FullPath, TEncoding.UTF8);

      FConnection.BeginTrans;
      try
        ExecuteSQLBatch(SQL);
        RegisterMigration(M.Version, M.Description, M.FileName);
        FConnection.CommitTrans;
        Inc(Applied);
        Log(Format('  V%.3d aplicada correctamente', [M.Version]));
      except
        on E: Exception do
        begin
          FConnection.RollbackTrans;
          Exit(TMigrationResult.Fail(
            Format('Error en V%.3d (%s): %s', [M.Version, M.FileName, E.Message])));
        end;
      end;
    end;

    Log(Format('Migraciones aplicadas: %d', [Applied]));
    Result := TMigrationResult.OK(Applied);
  except
    on E: Exception do
      Result := TMigrationResult.Fail(E.Message);
  end;
end;

function TDBMigrator.GetMigrationStatus: TArray<TMigrationInfo>;
begin
  Result := DiscoverMigrations;
end;

end.
