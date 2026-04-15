unit uDemoDataGenerator;

interface

uses
  System.SysUtils, System.Classes, System.Hash, System.StrUtils,
  Data.Win.ADODB;

type
  TSectorDemo = (
    sdMetalurgico,
    sdQuimico,
    sdAlimentacion,
    sdFarmaceutico,
    sdPlasticoInyeccion,
    sdTextil
  );

  TSectorInfo = record
    Codigo: SmallInt;
    Sector: TSectorDemo;
    Nombre: string;
    SectorNombre: string;
    class function ForSector(ASector: TSectorDemo): TSectorInfo; static;
  end;

  TDemoGeneratorResult = record
    Success: Boolean;
    ErrorMessage: string;
    class function OK: TDemoGeneratorResult; static;
    class function Fail(const AMsg: string): TDemoGeneratorResult; static;
  end;

  TDemoDataGenerator = class
  private
    FConnection: TADOConnection;
    FOnLog: TProc<string>;
    procedure Log(const AMsg: string);
    procedure Exec(const ASQL: string);
    function QStr(const S: string): string;
    function HashPassword(const APassword: string): string;

    // Creación común
    procedure CrearEmpresa(const AInfo: TSectorInfo);
    procedure CrearRolesYPermisos(ACodigoEmpresa: SmallInt);
    procedure CrearUsuariosDefecto(ACodigoEmpresa: SmallInt);
    procedure CrearCalendariosDefecto(ACodigoEmpresa: SmallInt);
    procedure AsignarCalendariosACentros(ACodigoEmpresa: SmallInt);

    // Específico por sector
    procedure PoblarSectorMetalurgico(ACodigoEmpresa: SmallInt);
    procedure PoblarSectorQuimico(ACodigoEmpresa: SmallInt);
    procedure PoblarSectorAlimentacion(ACodigoEmpresa: SmallInt);
    procedure PoblarSectorFarmaceutico(ACodigoEmpresa: SmallInt);
    procedure PoblarSectorPlastico(ACodigoEmpresa: SmallInt);
    procedure PoblarSectorTextil(ACodigoEmpresa: SmallInt);

    // Helpers genéricos
    procedure InsertarAreas(ACodigoEmpresa: SmallInt; const AAreas: TArray<string>);
    procedure InsertarDepartamentos(ACodigoEmpresa: SmallInt;
      const ADepts: TArray<TArray<string>>);
    procedure InsertarCentros(ACodigoEmpresa: SmallInt;
      const ACentros: TArray<TArray<string>>);
    procedure InsertarOperarios(ACodigoEmpresa: SmallInt;
      const ANombres: TArray<string>);
    procedure InsertarSkills(ACodigoEmpresa: SmallInt;
      const ASkillsPorOperario: TArray<string>);
  public
    constructor Create(AConnection: TADOConnection);

    function GenerarDemo(ASector: TSectorDemo): TDemoGeneratorResult;
    function EliminarDemo(ACodigoEmpresa: SmallInt): TDemoGeneratorResult;
    function ExisteDemo(ACodigoEmpresa: SmallInt): Boolean;

    property OnLog: TProc<string> read FOnLog write FOnLog;
  end;

function SectoresDisponibles: TArray<TSectorInfo>;

implementation

function SectoresDisponibles: TArray<TSectorInfo>;
begin
  Result := [
    TSectorInfo.ForSector(sdMetalurgico),
    TSectorInfo.ForSector(sdQuimico),
    TSectorInfo.ForSector(sdAlimentacion),
    TSectorInfo.ForSector(sdFarmaceutico),
    TSectorInfo.ForSector(sdPlasticoInyeccion),
    TSectorInfo.ForSector(sdTextil)
  ];
end;

{ TSectorInfo }

class function TSectorInfo.ForSector(ASector: TSectorDemo): TSectorInfo;
begin
  Result.Sector := ASector;
  case ASector of
    sdMetalurgico:
      begin
        Result.Codigo := 9999;
        Result.Nombre := 'Demo - Metal'#250'rgica Garcia S.L.';
        Result.SectorNombre := 'Metal'#250'rgico';
      end;
    sdQuimico:
      begin
        Result.Codigo := 9998;
        Result.Nombre := 'Demo - Qu'#237'mica Catalana S.A.';
        Result.SectorNombre := 'Qu'#237'mico';
      end;
    sdAlimentacion:
      begin
        Result.Codigo := 9997;
        Result.Nombre := 'Demo - Alimentaria Mediterr'#225'nea S.L.';
        Result.SectorNombre := 'Alimentaci'#243'n y Bebidas';
      end;
    sdFarmaceutico:
      begin
        Result.Codigo := 9996;
        Result.Nombre := 'Demo - Farmac'#233'utica Ib'#233'rica S.A.';
        Result.SectorNombre := 'Farmac'#233'utico';
      end;
    sdPlasticoInyeccion:
      begin
        Result.Codigo := 9995;
        Result.Nombre := 'Demo - Pl'#225'sticos del Vall'#232's S.L.';
        Result.SectorNombre := 'Pl'#225'stico / Inyecci'#243'n';
      end;
    sdTextil:
      begin
        Result.Codigo := 9994;
        Result.Nombre := 'Demo - Textil Barcelona S.A.';
        Result.SectorNombre := 'Textil / Confecci'#243'n';
      end;
  end;
end;

{ TDemoGeneratorResult }

class function TDemoGeneratorResult.OK: TDemoGeneratorResult;
begin
  Result.Success := True;
  Result.ErrorMessage := '';
end;

class function TDemoGeneratorResult.Fail(const AMsg: string): TDemoGeneratorResult;
begin
  Result.Success := False;
  Result.ErrorMessage := AMsg;
end;

{ TDemoDataGenerator }

constructor TDemoDataGenerator.Create(AConnection: TADOConnection);
begin
  inherited Create;
  FConnection := AConnection;
end;

procedure TDemoDataGenerator.Log(const AMsg: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AMsg);
end;

function TDemoDataGenerator.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TDemoDataGenerator.HashPassword(const APassword: string): string;
begin
  Result := THashSHA2.GetHashString(APassword, SHA256).ToUpper;
end;

procedure TDemoDataGenerator.Exec(const ASQL: string);
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

function TDemoDataGenerator.ExisteDemo(ACodigoEmpresa: SmallInt): Boolean;
var
  Q: TADOQuery;
begin
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT COUNT(*) AS Cnt FROM FS_PL_Empresa WHERE CodigoEmpresa = ' +
      IntToStr(ACodigoEmpresa);
    Q.Open;
    Result := Q.FieldByName('Cnt').AsInteger > 0;
  finally
    Q.Free;
  end;
end;

function TDemoDataGenerator.EliminarDemo(ACodigoEmpresa: SmallInt): TDemoGeneratorResult;
var
  CE: string;
begin
  try
    CE := IntToStr(ACodigoEmpresa);
    FConnection.BeginTrans;
    try
      // Orden inverso por dependencias
      Exec('DELETE FROM FS_PL_AccessLog WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_RolePermission WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_User WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Permission WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Role WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_OperatorAssignment WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_OperatorSkill WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_OperatorDepartment WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Operator WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Department WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_NodeData WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_CenterCalendar WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_CalendarDayRule WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_CalendarException WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Calendar WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Shift WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Center WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Area WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Almacen WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Project WHERE CodigoEmpresa = ' + CE);
      Exec('DELETE FROM FS_PL_Empresa WHERE CodigoEmpresa = ' + CE);
      FConnection.CommitTrans;
      Result := TDemoGeneratorResult.OK;
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TDemoGeneratorResult.Fail(E.Message);
  end;
end;

function TDemoDataGenerator.GenerarDemo(ASector: TSectorDemo): TDemoGeneratorResult;
var
  Info: TSectorInfo;
begin
  Info := TSectorInfo.ForSector(ASector);

  try
    if ExisteDemo(Info.Codigo) then
    begin
      Log('La empresa demo ' + IntToStr(Info.Codigo) + ' ya existe. Eliminando primero...');
      EliminarDemo(Info.Codigo);
    end;

    FConnection.BeginTrans;
    try
      Log('Creando empresa ' + Info.Nombre + '...');
      CrearEmpresa(Info);
      CrearRolesYPermisos(Info.Codigo);
      CrearCalendariosDefecto(Info.Codigo);

      case ASector of
        sdMetalurgico:       PoblarSectorMetalurgico(Info.Codigo);
        sdQuimico:           PoblarSectorQuimico(Info.Codigo);
        sdAlimentacion:      PoblarSectorAlimentacion(Info.Codigo);
        sdFarmaceutico:      PoblarSectorFarmaceutico(Info.Codigo);
        sdPlasticoInyeccion: PoblarSectorPlastico(Info.Codigo);
        sdTextil:            PoblarSectorTextil(Info.Codigo);
      end;

      AsignarCalendariosACentros(Info.Codigo);
      CrearUsuariosDefecto(Info.Codigo);

      FConnection.CommitTrans;
      Log('Empresa ' + Info.Nombre + ' creada correctamente.');
      Result := TDemoGeneratorResult.OK;
    except
      FConnection.RollbackTrans;
      raise;
    end;
  except
    on E: Exception do
      Result := TDemoGeneratorResult.Fail(E.Message);
  end;
end;

procedure TDemoDataGenerator.CrearEmpresa(const AInfo: TSectorInfo);
begin
  Exec('INSERT INTO FS_PL_Empresa (CodigoEmpresa, Nombre, EsDemo, Sector, Activo) VALUES (' +
    IntToStr(AInfo.Codigo) + ', ' + QStr(AInfo.Nombre) + ', 1, ' +
    QStr(AInfo.SectorNombre) + ', 1)');

  // Crear proyecto MASTER por defecto
  Exec('INSERT INTO FS_PL_Project (CodigoEmpresa, Codigo, Nombre, Descripcion, EsMaster, Activo) VALUES (' +
    IntToStr(AInfo.Codigo) + ', ''MASTER'', ' +
    QStr('Planificaci'#243'n MASTER') + ', ' +
    QStr('Planificaci'#243'n productiva vigente') + ', 1, 1)');
end;

procedure TDemoDataGenerator.CrearRolesYPermisos(ACodigoEmpresa: SmallInt);
var
  CE: string;
begin
  CE := IntToStr(ACodigoEmpresa);

  Exec('INSERT INTO FS_PL_Role (CodigoEmpresa, Codigo, Nombre, Descripcion) VALUES ' +
    '(' + CE + ', ''ADMIN'', ''Administrador'', ''Control total del sistema''), ' +
    '(' + CE + ', ''PLANIFICADOR'', ''Planificador'', ''Puede ver y modificar la planificaci'#243'n''), ' +
    '(' + CE + ', ''SUPERVISOR'', ''Supervisor'', ''Ver planificaci'#243'n y reportes''), ' +
    '(' + CE + ', ''OPERARIO'', ''Operario'', ''Solo consulta'')');

  Exec('INSERT INTO FS_PL_Permission (CodigoEmpresa, Codigo, Nombre, Modulo) VALUES ' +
    '(' + CE + ', ''PLAN_VIEW'',      ''Ver planificaci'#243'n'',             ''PLANIFICACION''), ' +
    '(' + CE + ', ''PLAN_EDIT'',      ''Modificar planificaci'#243'n'',       ''PLANIFICACION''), ' +
    '(' + CE + ', ''PLAN_DELETE'',    ''Eliminar operaciones'',          ''PLANIFICACION''), ' +
    '(' + CE + ', ''PLAN_REPLAN'',    ''Replanificar'',                  ''PLANIFICACION''), ' +
    '(' + CE + ', ''PLAN_EXPORT'',    ''Exportar'',                      ''PLANIFICACION''), ' +
    '(' + CE + ', ''CENTER_VIEW'',    ''Ver centros'',                   ''CENTROS''), ' +
    '(' + CE + ', ''CENTER_EDIT'',    ''Modificar centros'',             ''CENTROS''), ' +
    '(' + CE + ', ''OPERATOR_VIEW'',  ''Ver operarios'',                 ''OPERARIOS''), ' +
    '(' + CE + ', ''OPERATOR_EDIT'',  ''Modificar operarios'',           ''OPERARIOS''), ' +
    '(' + CE + ', ''REPORT_VIEW'',    ''Ver reportes'',                  ''REPORTES''), ' +
    '(' + CE + ', ''ADMIN_USERS'',    ''Gestionar usuarios'',            ''ADMIN''), ' +
    '(' + CE + ', ''ADMIN_ROLES'',    ''Gestionar roles'',               ''ADMIN'')');

  // ADMIN: todos los permisos
  Exec('INSERT INTO FS_PL_RolePermission (CodigoEmpresa, RoleId, PermissionId) ' +
    'SELECT ' + CE + ', r.RoleId, p.PermissionId ' +
    'FROM FS_PL_Role r INNER JOIN FS_PL_Permission p ON p.CodigoEmpresa = r.CodigoEmpresa ' +
    'WHERE r.CodigoEmpresa = ' + CE + ' AND r.Codigo = ''ADMIN''');
end;

procedure TDemoDataGenerator.CrearUsuariosDefecto(ACodigoEmpresa: SmallInt);
var
  CE: string;
begin
  CE := IntToStr(ACodigoEmpresa);
  Exec('INSERT INTO FS_PL_User (CodigoEmpresa, Login, PasswordHash, NombreCompleto, RoleId) ' +
    'SELECT ' + CE + ', ''admin'', ' + QStr(HashPassword('admin')) + ', ''Administrador'', RoleId ' +
    'FROM FS_PL_Role WHERE CodigoEmpresa = ' + CE + ' AND Codigo = ''ADMIN''');

  Exec('INSERT INTO FS_PL_User (CodigoEmpresa, Login, PasswordHash, NombreCompleto, RoleId) ' +
    'SELECT ' + CE + ', ''usuario1'', ' + QStr(HashPassword('usuario1')) + ', ''Usuario 1'', RoleId ' +
    'FROM FS_PL_Role WHERE CodigoEmpresa = ' + CE + ' AND Codigo = ''PLANIFICADOR''');

  Exec('INSERT INTO FS_PL_User (CodigoEmpresa, Login, PasswordHash, NombreCompleto, RoleId) ' +
    'SELECT ' + CE + ', ''usuario2'', ' + QStr(HashPassword('usuario2')) + ', ''Usuario 2'', RoleId ' +
    'FROM FS_PL_Role WHERE CodigoEmpresa = ' + CE + ' AND Codigo = ''PLANIFICADOR''');
end;

procedure TDemoDataGenerator.CrearCalendariosDefecto(ACodigoEmpresa: SmallInt);
var
  CE: string;
begin
  CE := IntToStr(ACodigoEmpresa);
  Exec('INSERT INTO FS_PL_Calendar (CodigoEmpresa, Nombre, Descripcion) VALUES ' +
    '(' + CE + ', ''CAL-MANANA'',     ''Turno ma'#241'ana 07:00-15:00''), ' +
    '(' + CE + ', ''CAL-TARDE'',      ''Turno tarde 15:00-23:00''), ' +
    '(' + CE + ', ''CAL-PARTIDO'',    ''Turno partido''), ' +
    '(' + CE + ', ''CAL-24H'',        ''24 horas''), ' +
    '(' + CE + ', ''CAL-INTENSIVO'',  ''Intensivo 06:00-14:00'')');

  // Fin de semana cerrado para todos
  Exec('INSERT INTO FS_PL_CalendarDayRule (CodigoEmpresa, CalendarId, DiaSemana, HoraInicioNoLab, HoraFinNoLab) ' +
    'SELECT c.CodigoEmpresa, c.CalendarId, d.DiaSemana, ''00:00:00'', ''23:59:00'' ' +
    'FROM FS_PL_Calendar c CROSS APPLY (VALUES (6),(7)) AS d(DiaSemana) ' +
    'WHERE c.CodigoEmpresa = ' + CE);
end;

procedure TDemoDataGenerator.AsignarCalendariosACentros(ACodigoEmpresa: SmallInt);
var
  CE: string;
begin
  CE := IntToStr(ACodigoEmpresa);
  Exec('INSERT INTO FS_PL_CenterCalendar (CodigoEmpresa, CenterId, CalendarId) ' +
    'SELECT c.CodigoEmpresa, c.CenterId, cal.CalendarId FROM FS_PL_Center c ' +
    'INNER JOIN (SELECT CalendarId, ROW_NUMBER() OVER (ORDER BY CalendarId) - 1 AS CalIdx ' +
    '            FROM FS_PL_Calendar WHERE CodigoEmpresa = ' + CE + ') cal ' +
    'ON cal.CalIdx = (c.Orden % (SELECT COUNT(*) FROM FS_PL_Calendar WHERE CodigoEmpresa = ' + CE + ')) ' +
    'WHERE c.CodigoEmpresa = ' + CE);
end;

procedure TDemoDataGenerator.InsertarAreas(ACodigoEmpresa: SmallInt;
  const AAreas: TArray<string>);
var
  I: Integer;
  CE: string;
  Codigo: string;
begin
  CE := IntToStr(ACodigoEmpresa);
  for I := 0 to High(AAreas) do
  begin
    Codigo := 'AREA' + IntToStr(I + 1);
    Exec('INSERT INTO FS_PL_Area (CodigoEmpresa, Codigo, Nombre, Orden) VALUES (' +
      CE + ', ' + QStr(Codigo) + ', ' + QStr(AAreas[I]) + ', ' + IntToStr(I) + ')');
  end;
end;

procedure TDemoDataGenerator.InsertarDepartamentos(ACodigoEmpresa: SmallInt;
  const ADepts: TArray<TArray<string>>);
var
  I: Integer;
  CE: string;
begin
  CE := IntToStr(ACodigoEmpresa);
  for I := 0 to High(ADepts) do
    Exec('INSERT INTO FS_PL_Department (CodigoEmpresa, Nombre, Descripcion) VALUES (' +
      CE + ', ' + QStr(ADepts[I][0]) + ', ' + QStr(ADepts[I][1]) + ')');
end;

procedure TDemoDataGenerator.InsertarCentros(ACodigoEmpresa: SmallInt;
  const ACentros: TArray<TArray<string>>);
var
  I: Integer;
  CE: string;
  EsSeq: string;
  MaxLanes: Integer;
begin
  CE := IntToStr(ACodigoEmpresa);
  // ACentros[i] = [CodigoCentro, Titulo, Subtitulo, AreaCodigo, EsSequencial(0/1)]
  for I := 0 to High(ACentros) do
  begin
    EsSeq := ACentros[I][4];
    if EsSeq = '1' then MaxLanes := 0 else MaxLanes := 3;
    Exec('INSERT INTO FS_PL_Center (CodigoEmpresa, CodigoCentro, Titulo, Subtitulo, ' +
      'AreaId, EsSecuencial, MaxLanes, Orden, Visible, Habilitado) ' +
      'SELECT ' + CE + ', ' + QStr(ACentros[I][0]) + ', ' + QStr(ACentros[I][1]) + ', ' +
      QStr(ACentros[I][2]) + ', a.AreaId, ' + EsSeq + ', ' + IntToStr(MaxLanes) + ', ' +
      IntToStr(I) + ', 1, 1 ' +
      'FROM FS_PL_Area a WHERE a.CodigoEmpresa = ' + CE +
      ' AND a.Codigo = ' + QStr(ACentros[I][3]));
  end;
end;

procedure TDemoDataGenerator.InsertarOperarios(ACodigoEmpresa: SmallInt;
  const ANombres: TArray<string>);
var
  I: Integer;
  CE: string;
begin
  CE := IntToStr(ACodigoEmpresa);
  for I := 0 to High(ANombres) do
    Exec('INSERT INTO FS_PL_Operator (CodigoEmpresa, Nombre, Activo) VALUES (' +
      CE + ', ' + QStr(ANombres[I]) + ', 1)');
end;

procedure TDemoDataGenerator.InsertarSkills(ACodigoEmpresa: SmallInt;
  const ASkillsPorOperario: TArray<string>);
var
  CE: string;
  I: Integer;
begin
  CE := IntToStr(ACodigoEmpresa);
  for I := 0 to High(ASkillsPorOperario) do
    Exec('INSERT INTO FS_PL_OperatorSkill (CodigoEmpresa, OperatorId, Operacion) ' +
      'SELECT ' + CE + ', OperatorId, ' + QStr(ASkillsPorOperario[I]) + ' ' +
      'FROM FS_PL_Operator WHERE CodigoEmpresa = ' + CE +
      ' AND (OperatorId - 1) % ' + IntToStr(Length(ASkillsPorOperario)) + ' = ' + IntToStr(I));
end;

// ════════════════════════════════════════════════════════════════════
//  POBLACIÓN POR SECTOR
// ════════════════════════════════════════════════════════════════════

procedure TDemoDataGenerator.PoblarSectorMetalurgico(ACodigoEmpresa: SmallInt);
begin
  InsertarAreas(ACodigoEmpresa, ['Mecanizado', 'Soldadura', 'Acabados', 'Calidad', 'Expediciones']);
  InsertarDepartamentos(ACodigoEmpresa, [
    ['Tornos',           'Torneado de piezas'],
    ['Fresas',           'Fresado y mecanizado'],
    ['Soldadura MIG',    'Soldadura al arco'],
    ['Rectificado',      'Acabado superficial'],
    ['Control Calidad',  'Verificaci'#243'n piezas']
  ]);
  InsertarCentros(ACodigoEmpresa, [
    ['TORNO-1',    'Torno CNC 1',     'Haas ST-20',    'AREA1', '1'],
    ['TORNO-2',    'Torno CNC 2',     'Mazak QTN-200', 'AREA1', '1'],
    ['FRESA-1',    'Fresadora CNC 1', 'DMG MORI',      'AREA1', '1'],
    ['FRESA-2',    'Fresadora CNC 2', 'Haas VF-2',     'AREA1', '1'],
    ['SOLD-1',     'Soldadura MIG 1', 'Cabina 1',      'AREA2', '0'],
    ['SOLD-2',     'Soldadura TIG 1', 'Cabina 2',      'AREA2', '0'],
    ['RECT-1',     'Rectificadora',   'Jotes 200',     'AREA3', '1'],
    ['PULIDO',     'Pulido / Acabado','Manual',        'AREA3', '0'],
    ['QA-1',       'Control Calidad', 'CMM Zeiss',     'AREA4', '1'],
    ['EXPED',      'Expediciones',    'Embalaje',      'AREA5', '0']
  ]);
  InsertarOperarios(ACodigoEmpresa, [
    'Joan Garcia', 'Marc Puig', 'Pere Martinez', 'David Serra', 'Jordi Vila',
    'Anna Ferrer', 'Laura Roca', 'Marta Soler', 'Carla Font', 'Maria Lopez',
    'Xavi Torres', 'Pol Roig', 'Albert Mas', 'Oriol Vidal'
  ]);
  InsertarSkills(ACodigoEmpresa, ['TORNEAR', 'FRESAR', 'SOLDAR', 'RECTIFICAR', 'PULIR', 'VERIFICAR']);
end;

procedure TDemoDataGenerator.PoblarSectorQuimico(ACodigoEmpresa: SmallInt);
begin
  InsertarAreas(ACodigoEmpresa, ['Reactores', 'Envasado', 'Laboratorio', 'Almac'#233'n', 'Expediciones']);
  InsertarDepartamentos(ACodigoEmpresa, [
    ['Producci'#243'n Reactor',  'Operaci'#243'n de reactores qu'#237'micos'],
    ['Formulaci'#243'n',         'Mezcla y dosificaci'#243'n'],
    ['Envasado Bidones',    'Envasado en bidones industriales'],
    ['Laboratorio QA',      'An'#225'lisis qu'#237'mico'],
    ['Almac'#233'n Peligrosos',  'Gesti'#243'n ATEX']
  ]);
  InsertarCentros(ACodigoEmpresa, [
    ['REAC-1',  'Reactor 1',          '5000L acero inox', 'AREA1', '1'],
    ['REAC-2',  'Reactor 2',          '3000L vidriado',   'AREA1', '1'],
    ['REAC-3',  'Reactor 3',          '8000L',            'AREA1', '1'],
    ['MIX-1',   'Mezcladora 1',       'Rotativo',         'AREA1', '1'],
    ['ENV-1',   'Envasadora bidones', '200L IBC',         'AREA2', '0'],
    ['ENV-2',   'Envasadora garrafas','25L',              'AREA2', '0'],
    ['ENV-3',   'Envasadora botellas','1L',               'AREA2', '0'],
    ['LAB-1',   'Laboratorio QC',     'Anal'#237'tica',        'AREA3', '0'],
    ['ALM-1',   'Almac'#233'n ATEX',       'Materia prima',    'AREA4', '0']
  ]);
  InsertarOperarios(ACodigoEmpresa, [
    'Ramon Soler', 'Gerard Puig', 'Albert Vila', 'Mart'#237' Roca', 'Nuria Mas',
    'Cristina Ferrer', 'Elisabet Font', 'Marina Torres', 'Xavi Pons', 'Oriol Costa',
    'Helena Vidal', 'Josep Marin'
  ]);
  InsertarSkills(ACodigoEmpresa, ['REACTOR', 'MEZCLAR', 'ENVASAR', 'ANALIZAR', 'DOSIFICAR', 'CERTIFICAR']);
end;

procedure TDemoDataGenerator.PoblarSectorAlimentacion(ACodigoEmpresa: SmallInt);
begin
  InsertarAreas(ACodigoEmpresa, ['Preparaci'#243'n', 'Cocci'#243'n', 'Envasado', 'Paletizaci'#243'n', 'Calidad']);
  InsertarDepartamentos(ACodigoEmpresa, [
    ['Preparaci'#243'n Ingredientes', 'Pesado y dosificado'],
    ['Cocci'#243'n',                  'Hornos y marmitas'],
    ['Envasado Primario',        'Botes, botellas'],
    ['Envasado Secundario',      'Cajas y packaging'],
    ['Paletizaci'#243'n',             'Paletizado autom'#225'tico'],
    ['QA Alimentario',           'An'#225'lisis microbiol'#243'gico']
  ]);
  InsertarCentros(ACodigoEmpresa, [
    ['PREP-1',  'Dosificadora 1',    'B'#225'scula 5kg',   'AREA1', '0'],
    ['HORNO-1', 'Horno continuo',    '180'#186'C',         'AREA2', '1'],
    ['MARM-1',  'Marmita 1',         '500L',          'AREA2', '1'],
    ['ENV-BOT', 'L'#237'nea botellas',   '10000 u/h',     'AREA3', '1'],
    ['ENV-LAT', 'L'#237'nea latas',      '8000 u/h',      'AREA3', '1'],
    ['ENV-TAR', 'L'#237'nea tarros',     '5000 u/h',      'AREA3', '1'],
    ['EMB-1',   'Embalaje cajas',    'Autom'#225'tico',    'AREA4', '1'],
    ['PAL-1',   'Paletizadora',      'Robot',         'AREA4', '1'],
    ['LAB-1',   'Lab microbiolog'#237'a','An'#225'lisis',      'AREA5', '0']
  ]);
  InsertarOperarios(ACodigoEmpresa, [
    'M'#243'nica Vila', 'Sergi Font', 'Rosa Roca', 'Teresa Puig', 'Josep Mas',
    'N'#250'ria Ferrer', 'Pau Soler', 'Roger Vidal', 'Anna Torres', 'Clara Pons',
    'Ivan Marin', 'Laia Costa', 'Raul Lopez', 'Eva Garcia'
  ]);
  InsertarSkills(ACodigoEmpresa, ['COCER', 'ENVASAR', 'PALETIZAR', 'DOSIFICAR', 'EMBALAR', 'ANALIZAR']);
end;

procedure TDemoDataGenerator.PoblarSectorFarmaceutico(ACodigoEmpresa: SmallInt);
begin
  InsertarAreas(ACodigoEmpresa, ['Granulaci'#243'n', 'Compresi'#243'n', 'Recubrimiento', 'Blisteado', 'QC/QA', 'Almac'#233'n GMP']);
  InsertarDepartamentos(ACodigoEmpresa, [
    ['Granulaci'#243'n',       'Granulado h'#250'medo y seco'],
    ['Compresi'#243'n',        'Comprimidos'],
    ['Recubrimiento',     'Coating de comprimidos'],
    ['Inyectables',       'Viales y ampollas'],
    ['Blisteado',         'Blisteado y estuchado'],
    ['QC',                'Control calidad'],
    ['QA',                'Aseguramiento calidad GMP']
  ]);
  InsertarCentros(ACodigoEmpresa, [
    ['GRAN-1',   'Granulador 1',     'Glatt GPCG',    'AREA1', '1'],
    ['COMP-1',   'Compresora 1',     'Fette 1200',    'AREA2', '1'],
    ['COMP-2',   'Compresora 2',     'Korsch XL800',  'AREA2', '1'],
    ['COAT-1',   'Bombo coating',    'O''Hara',       'AREA3', '1'],
    ['INY-1',    'L'#237'nea inyectables','Vial 10ml',     'AREA1', '1'],
    ['BLIS-1',   'Blisteadora 1',    'Uhlmann B1440', 'AREA4', '1'],
    ['BLIS-2',   'Blisteadora 2',    'Marchesini',    'AREA4', '1'],
    ['QC-HPLC',  'HPLC',             'Laboratorio',   'AREA5', '0'],
    ['QA-LIBER', 'Liberaci'#243'n lotes', 'QA',            'AREA5', '0']
  ]);
  InsertarOperarios(ACodigoEmpresa, [
    'Dr. Garcia', 'Dra. Lopez', 'Marc Farre', 'Anna Vila', 'Laura Puig',
    'Jordi Ferrer', 'Marta Roca', 'Carla Mas', 'Pere Soler', 'David Vidal',
    'Cristina Torres', 'Nuria Pons', 'Oriol Marin'
  ]);
  InsertarSkills(ACodigoEmpresa, ['GRANULAR', 'COMPRIMIR', 'RECUBRIR', 'BLISTEAR', 'ANALIZAR HPLC', 'LIBERAR LOTE']);
end;

procedure TDemoDataGenerator.PoblarSectorPlastico(ACodigoEmpresa: SmallInt);
begin
  InsertarAreas(ACodigoEmpresa, ['Inyecci'#243'n', 'Soplado', 'Montaje', 'Almac'#233'n Moldes', 'Calidad']);
  InsertarDepartamentos(ACodigoEmpresa, [
    ['Inyecci'#243'n',     'Operaci'#243'n m'#225'quinas inyecci'#243'n'],
    ['Soplado',       'Soplado de piezas huecas'],
    ['Cambio Molde',  'Set-up de moldes'],
    ['Ensamblaje',    'Montaje piezas pl'#225'sticas'],
    ['Mantenimiento Moldes', 'Reparaci'#243'n preventiva']
  ]);
  InsertarCentros(ACodigoEmpresa, [
    ['INY-100',  'Inyectora 100T',  'Arburg 370',   'AREA1', '1'],
    ['INY-250',  'Inyectora 250T',  'Engel Victory','AREA1', '1'],
    ['INY-450',  'Inyectora 450T',  'Krauss Maffei','AREA1', '1'],
    ['INY-650',  'Inyectora 650T',  'Battenfeld',   'AREA1', '1'],
    ['INY-1000', 'Inyectora 1000T', 'Netstal',      'AREA1', '1'],
    ['SOPL-1',   'Sopladora 1',     'Sidel',        'AREA2', '1'],
    ['MONT-1',   'L'#237'nea montaje',   'Manual',       'AREA3', '0'],
    ['MONT-2',   'L'#237'nea montaje 2', 'Automatizada', 'AREA3', '0'],
    ['QA-1',     'Control Dimensional', 'CMM',      'AREA5', '0']
  ]);
  InsertarOperarios(ACodigoEmpresa, [
    'Toni Garcia', 'Manu Lopez', 'Raul Martinez', 'Pepe Ferrer', 'Jaume Puig',
    'Sandra Roca', 'Laura Serra', 'Maria Font', 'Jordi Vila', 'Marc Soler',
    'David Mas', 'Anna Torres', 'Marta Vidal'
  ]);
  InsertarSkills(ACodigoEmpresa, ['INYECTAR', 'SOPLAR', 'CAMBIO MOLDE', 'MONTAR', 'VERIFICAR']);
end;

procedure TDemoDataGenerator.PoblarSectorTextil(ACodigoEmpresa: SmallInt);
begin
  InsertarAreas(ACodigoEmpresa, ['Corte', 'Confecci'#243'n', 'Acabados', 'Planchado', 'Empaquetado']);
  InsertarDepartamentos(ACodigoEmpresa, [
    ['Patronaje',     'Dise'#241'o y patrones'],
    ['Corte',         'Corte de tejidos'],
    ['Confecci'#243'n',    'Costura'],
    ['Acabados',      'Remates, bordados'],
    ['Planchado',     'Planchado final'],
    ['Empaquetado',   'Preparaci'#243'n pedidos']
  ]);
  InsertarCentros(ACodigoEmpresa, [
    ['CORTE-1',  'Mesa corte manual', '5m',            'AREA1', '1'],
    ['CORTE-2',  'Cortadora Gerber',  'Autom'#225'tica',    'AREA1', '1'],
    ['CONF-1',   'L'#237'nea costura 1',   '10 m'#225'quinas',  'AREA2', '0'],
    ['CONF-2',   'L'#237'nea costura 2',   '12 m'#225'quinas',  'AREA2', '0'],
    ['CONF-3',   'Overlock',          '5 m'#225'quinas',   'AREA2', '0'],
    ['BORD-1',   'Bordadora',         'Tajima',        'AREA3', '1'],
    ['PLAN-1',   'Plancha vapor',     'Industrial',    'AREA4', '0'],
    ['EMB-1',    'Embolsado',         'Manual',        'AREA5', '0']
  ]);
  InsertarOperarios(ACodigoEmpresa, [
    'Rosa Garcia', 'Carmen Lopez', 'Pilar Martinez', 'Montse Ferrer', 'Dolors Puig',
    'Aurora Roca', 'Marta Serra', 'Nuria Font', 'Anna Vila', 'Laura Soler',
    'Clara Mas', 'Judit Torres', 'Marina Vidal', 'Ariadna Pons'
  ]);
  InsertarSkills(ACodigoEmpresa, ['CORTAR', 'COSER', 'OVERLOCK', 'BORDAR', 'PLANCHAR', 'EMPAQUETAR']);
end;

end.
