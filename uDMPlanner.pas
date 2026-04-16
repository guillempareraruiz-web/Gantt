unit uDMPlanner;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Data.DB, Data.Win.ADODB,
  uDataConnector, uSQLServerConnector, uDBMigrations,
  uCalendarsRepo, uCentresRepo, uNodesRepo, uNodeDataRepo;

function UserCanAccessProject(AUserId, AProjectId: Integer): Boolean;

type
  TEstructuraNodos = (enSimple, enCompleja);
    // enSimple   : 1 OF = 1 OT = 1 OP
    // enCompleja : 1 OF = N OT = N OP

  TDMPlanner = class(TDataModule)
    ADOConnection: TADOConnection;
  private
    FConnector: IGanttDataConnector;
    FServer: string;
    FDatabase: string;
    FUserName: string;
    FPassword: string;
    FUseWindowsAuth: Boolean;
    FCurrentProjectId: Integer;
    FCurrentProjectName: string;
    FCurrentProjectIsMaster: Boolean;
    FCurrentProjectFechaBloqueo: TDateTime;
    FCurrentProjectTieneBloqueo: Boolean;
    FCodigoEmpresa: SmallInt;
    FCurrentEmpresaNombre: string;
    FPlanificaOperarios: Boolean;
    FPlanificaMoldes: Boolean;
    FEstructuraNodos: TEstructuraNodos;
    FCalendarsRepo: TCalendarsRepo;
    FCentresRepo: TCentresRepo;
    FNodesRepo: TNodesRepo;
    procedure BuildConnectionString;
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;

    // Conexión
    function Connect: TConnectorResult;
    function ConnectWith(const AServer, ADatabase: string;
      AWindowsAuth: Boolean; const AUser: string = ''; const APassword: string = ''): TConnectorResult;
    procedure Disconnect;
    function IsConnected: Boolean;

    // Gestión de proyecto activo
    procedure LoadMasterProject;
    procedure LoadUserActiveProject(AUserId: Integer);
    procedure SetCurrentProject(AProjectId: Integer);
    procedure LoadEmpresaInfo;
    procedure LoadCalendars;
    procedure LoadCentres;
    procedure LoadNodes(ANodeDataRepo: TNodeDataRepo = nil);
    function CountTable(const ATableName: string): Integer;

    property CalendarsRepo: TCalendarsRepo read FCalendarsRepo;
    property CentresRepo: TCentresRepo read FCentresRepo;
    property NodesRepo: TNodesRepo read FNodesRepo;

    // Acceso al conector
    property Connector: IGanttDataConnector read FConnector;
    property CurrentProjectId: Integer read FCurrentProjectId write FCurrentProjectId;
    property CurrentProjectName: string read FCurrentProjectName;
    property CurrentProjectIsMaster: Boolean read FCurrentProjectIsMaster;
    property CurrentProjectFechaBloqueo: TDateTime read FCurrentProjectFechaBloqueo;
    property CurrentProjectTieneBloqueo: Boolean read FCurrentProjectTieneBloqueo;
    property CurrentEmpresaNombre: string read FCurrentEmpresaNombre;
    property CodigoEmpresa: SmallInt read FCodigoEmpresa write FCodigoEmpresa;
    property PlanificaOperarios: Boolean read FPlanificaOperarios;
    property PlanificaMoldes: Boolean read FPlanificaMoldes;
    property EstructuraNodos: TEstructuraNodos read FEstructuraNodos;
    procedure SaveEmpresaPreferencias(APlanificaOperarios, APlanificaMoldes: Boolean;
      AEstructuraNodos: TEstructuraNodos);

    // Configuración
    property Server: string read FServer write FServer;
    property Database: string read FDatabase write FDatabase;
    property UserName: string read FUserName write FUserName;
    property Password: string read FPassword write FPassword;
    property UseWindowsAuth: Boolean read FUseWindowsAuth write FUseWindowsAuth;
  end;

var
  DMPlanner: TDMPlanner;

implementation

{$R *.dfm}

uses
  uLogin;

function UserCanAccessProject(AUserId, AProjectId: Integer): Boolean;
var
  Q: TADOQuery;
begin
  if IsAdmin then Exit(True);
  if (AUserId <= 0) or (AProjectId <= 0) then Exit(False);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT 1 FROM FS_PL_ProjectUser WHERE CodigoEmpresa = ' +
      IntToStr(DMPlanner.CodigoEmpresa) +
      ' AND UserId = ' + IntToStr(AUserId) +
      ' AND ProjectId = ' + IntToStr(AProjectId);
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

procedure TDMPlanner.AfterConstruction;
begin
  inherited;
  FCurrentProjectId := -1;
  FCodigoEmpresa := 9999;
  FUseWindowsAuth := True;
  FCalendarsRepo := TCalendarsRepo.Create(ADOConnection);
  FCentresRepo := TCentresRepo.Create(ADOConnection, FCalendarsRepo);
  FNodesRepo := TNodesRepo.Create(ADOConnection);
end;

destructor TDMPlanner.Destroy;
begin
  FNodesRepo.Free;
  FCentresRepo.Free;
  FCalendarsRepo.Free;
  inherited;
end;

procedure TDMPlanner.LoadCalendars;
begin
  if (FCalendarsRepo <> nil) and IsConnected then
    FCalendarsRepo.LoadFromDB(FCodigoEmpresa);
end;

procedure TDMPlanner.LoadCentres;
begin
  if (FCentresRepo <> nil) and IsConnected then
    FCentresRepo.LoadFromDB(FCodigoEmpresa);
end;

procedure TDMPlanner.LoadNodes(ANodeDataRepo: TNodeDataRepo);
begin
  if (FNodesRepo <> nil) and IsConnected and (FCurrentProjectId > 0) then
    FNodesRepo.LoadFromDB(FCodigoEmpresa, FCurrentProjectId, ANodeDataRepo);
end;

function TDMPlanner.CountTable(const ATableName: string): Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  if not IsConnected then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT COUNT(*) AS N FROM ' + ATableName +
      ' WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa);
    Q.Open;
    if not Q.Eof then
      Result := Q.FieldByName('N').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TDMPlanner.BuildConnectionString;
var
  CS: string;
begin
  CS := 'Provider=MSOLEDBSQL.1;Data Source=' + FServer +
        ';Initial Catalog=' + FDatabase;
  if FUseWindowsAuth then
    CS := CS + ';Integrated Security=SSPI'
  else
    CS := CS + ';User ID=' + FUserName + ';Password=' + FPassword;
  ADOConnection.ConnectionString := CS;
end;

function TDMPlanner.Connect: TConnectorResult;
var
  Migrator: TDBMigrator;
  MigResult: TMigrationResult;
  MigrationsPath: string;
begin
  try
    //BuildConnectionString;
    ADOConnection.Connected := True;
    FConnector := TSQLServerConnector.Create(ADOConnection);

    // Aplicar migraciones pendientes automáticamente
    MigrationsPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'SQL\migrations');
    if not TDirectory.Exists(MigrationsPath) then
      MigrationsPath := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\SQL\migrations');

    if TDirectory.Exists(MigrationsPath) then
    begin
      Migrator := TDBMigrator.Create(ADOConnection, MigrationsPath);
      try
        MigResult := Migrator.RunPendingMigrations;
        if not MigResult.Success then
          Exit(TConnectorResult.Fail('Error aplicando migraciones: ' + MigResult.ErrorMessage));
      finally
        Migrator.Free;
      end;
    end;

    Result := TConnectorResult.OK;
  except
    on E: Exception do
      Result := TConnectorResult.Fail('Error de conexión: ' + E.Message);
  end;
end;

function TDMPlanner.ConnectWith(const AServer, ADatabase: string;
  AWindowsAuth: Boolean; const AUser, APassword: string): TConnectorResult;
begin
  FServer := AServer;
  FDatabase := ADatabase;
  FUseWindowsAuth := AWindowsAuth;
  FUserName := AUser;
  FPassword := APassword;
  Result := Connect;
end;

procedure TDMPlanner.Disconnect;
begin
  FConnector := nil;
  if ADOConnection.Connected then
    ADOConnection.Connected := False;
end;

function TDMPlanner.IsConnected: Boolean;
begin
  Result := ADOConnection.Connected;
end;

procedure TDMPlanner.LoadEmpresaInfo;
var
  Q: TADOQuery;
begin
  FCurrentEmpresaNombre := '';
  FPlanificaOperarios := True;
  FPlanificaMoldes := False;
  FEstructuraNodos := enCompleja;

  if not IsConnected then Exit;

  // Primera consulta: solo Nombre (funciona aunque V008 no se haya aplicado).
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT Nombre FROM FS_PL_Empresa WHERE CodigoEmpresa = ' +
      IntToStr(FCodigoEmpresa);
    Q.Open;
    if not Q.Eof then
      FCurrentEmpresaNombre := Q.FieldByName('Nombre').AsString;
  finally
    Q.Free;
  end;

  // Segunda consulta: columnas de V008. Si no existen, quedarán los defaults.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text :=
      'SELECT PlanificaOperarios, PlanificaMoldes, EstructuraNodos ' +
      'FROM FS_PL_Empresa WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa);
    try
      Q.Open;
      if not Q.Eof then
      begin
        FPlanificaOperarios := Q.FieldByName('PlanificaOperarios').AsBoolean;
        FPlanificaMoldes := Q.FieldByName('PlanificaMoldes').AsBoolean;
        if Q.FieldByName('EstructuraNodos').AsInteger = 0 then
          FEstructuraNodos := enSimple
        else
          FEstructuraNodos := enCompleja;
      end;
    except
      // Columnas V008 aún no creadas: seguimos con los defaults en memoria.
    end;
  finally
    Q.Free;
  end;

  LoadCalendars;
  LoadCentres;
end;

procedure TDMPlanner.SaveEmpresaPreferencias(APlanificaOperarios,
  APlanificaMoldes: Boolean; AEstructuraNodos: TEstructuraNodos);
var
  Cmd: TADOCommand;
begin
  if not IsConnected then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := ADOConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_Empresa SET ' +
      '  PlanificaOperarios = ' + IntToStr(Ord(APlanificaOperarios)) + ', ' +
      '  PlanificaMoldes    = ' + IntToStr(Ord(APlanificaMoldes)) + ', ' +
      '  EstructuraNodos    = ' + IntToStr(Ord(AEstructuraNodos)) + ' ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  FPlanificaOperarios := APlanificaOperarios;
  FPlanificaMoldes := APlanificaMoldes;
  FEstructuraNodos := AEstructuraNodos;
end;

procedure TDMPlanner.LoadMasterProject;
var
  Q: TADOQuery;
begin
  FCurrentProjectId := -1;
  FCurrentProjectName := '';
  FCurrentProjectIsMaster := False;
  FCurrentProjectFechaBloqueo := 0;
  FCurrentProjectTieneBloqueo := False;

  if not IsConnected then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT ProjectId, Nombre, EsMaster, FechaBloqueo FROM FS_PL_Project ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      ' AND EsMaster = 1 AND Activo = 1';
    Q.Open;
    if not Q.Eof then
    begin
      FCurrentProjectId := Q.FieldByName('ProjectId').AsInteger;
      FCurrentProjectName := Q.FieldByName('Nombre').AsString;
      FCurrentProjectIsMaster := True;
      FCurrentProjectTieneBloqueo := not Q.FieldByName('FechaBloqueo').IsNull;
      if FCurrentProjectTieneBloqueo then
        FCurrentProjectFechaBloqueo := Q.FieldByName('FechaBloqueo').AsDateTime;
    end;
  finally
    Q.Free;
  end;
end;

procedure TDMPlanner.LoadUserActiveProject(AUserId: Integer);
var
  Q: TADOQuery;
  ProjId: Integer;
begin
  if (not IsConnected) or (AUserId <= 0) then
  begin
    LoadMasterProject;
    Exit;
  end;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT ProjectId FROM FS_PL_UserActiveProject ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      ' AND UserId = ' + IntToStr(AUserId);
    Q.Open;
    if not Q.Eof then
    begin
      ProjId := Q.FieldByName('ProjectId').AsInteger;
      if UserCanAccessProject(AUserId, ProjId) then
      begin
        SetCurrentProject(ProjId);
        if FCurrentProjectId > 0 then Exit;
      end;
    end;
  finally
    Q.Free;
  end;

  // Fallback: admin -> MASTER; resto -> primer proyecto asignado
  if IsAdmin then
    LoadMasterProject
  else
  begin
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := ADOConnection;
      Q.SQL.Text :=
        'SELECT TOP 1 pu.ProjectId FROM FS_PL_ProjectUser pu ' +
        'INNER JOIN FS_PL_Project p ON p.CodigoEmpresa = pu.CodigoEmpresa ' +
        '  AND p.ProjectId = pu.ProjectId ' +
        'WHERE pu.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
        ' AND pu.UserId = ' + IntToStr(AUserId) +
        ' AND p.Activo = 1 ' +
        'ORDER BY p.EsMaster DESC, p.FechaCreacion DESC';
      Q.Open;
      if not Q.Eof then
        SetCurrentProject(Q.FieldByName('ProjectId').AsInteger);
    finally
      Q.Free;
    end;
  end;
end;

procedure TDMPlanner.SetCurrentProject(AProjectId: Integer);
var
  Q: TADOQuery;
begin
  if not IsConnected then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := ADOConnection;
    Q.SQL.Text := 'SELECT ProjectId, Nombre, EsMaster, FechaBloqueo FROM FS_PL_Project ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      ' AND ProjectId = ' + IntToStr(AProjectId);
    Q.Open;
    if not Q.Eof then
    begin
      FCurrentProjectId := Q.FieldByName('ProjectId').AsInteger;
      FCurrentProjectName := Q.FieldByName('Nombre').AsString;
      FCurrentProjectIsMaster := Q.FieldByName('EsMaster').AsBoolean;
      FCurrentProjectTieneBloqueo := not Q.FieldByName('FechaBloqueo').IsNull;
      if FCurrentProjectTieneBloqueo then
        FCurrentProjectFechaBloqueo := Q.FieldByName('FechaBloqueo').AsDateTime
      else
        FCurrentProjectFechaBloqueo := 0;
    end;
  finally
    Q.Free;
  end;
end;

end.
