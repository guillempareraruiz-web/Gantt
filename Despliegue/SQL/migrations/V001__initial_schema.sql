-- ============================================================================
-- V001 - Esquema inicial FSPlanner 2026
-- ============================================================================

-- FS_PL_Empresa
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Empresa')
CREATE TABLE FS_PL_Empresa (
    CodigoEmpresa   SMALLINT      NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    CIF             NVARCHAR(20)  NULL,
    Direccion       NVARCHAR(500) NULL,
    Telefono        NVARCHAR(50)  NULL,
    Email           NVARCHAR(200) NULL,
    EsDemo          BIT           NOT NULL DEFAULT 0,
    Sector          NVARCHAR(50)  NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Empresa PRIMARY KEY (CodigoEmpresa)
);

-- FS_PL_Project
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Project')
CREATE TABLE FS_PL_Project (
    CodigoEmpresa   SMALLINT      NOT NULL,
    ProjectId       INT IDENTITY(1,1) NOT NULL,
    Codigo          NVARCHAR(30)  NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Descripcion     NVARCHAR(MAX) NULL,
    FechaCreacion   DATETIME2     NOT NULL DEFAULT GETDATE(),
    FechaModificacion DATETIME2   NOT NULL DEFAULT GETDATE(),
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Project PRIMARY KEY (CodigoEmpresa, ProjectId),
    CONSTRAINT UQ_FS_PL_Project_Codigo UNIQUE (CodigoEmpresa, Codigo)
);

-- FS_PL_Area
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Area')
CREATE TABLE FS_PL_Area (
    CodigoEmpresa   SMALLINT      NOT NULL,
    AreaId          INT IDENTITY(1,1) NOT NULL,
    Codigo          NVARCHAR(30)  NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Orden           INT           NOT NULL DEFAULT 0,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Area PRIMARY KEY (CodigoEmpresa, AreaId),
    CONSTRAINT UQ_FS_PL_Area_Codigo UNIQUE (CodigoEmpresa, Codigo)
);

-- FS_PL_Center
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Center')
CREATE TABLE FS_PL_Center (
    CodigoEmpresa   SMALLINT      NOT NULL,
    CenterId        INT IDENTITY(1,1) NOT NULL,
    CodigoCentro    NVARCHAR(30)  NOT NULL,
    Titulo          NVARCHAR(200) NOT NULL,
    Subtitulo       NVARCHAR(200) NULL,
    AreaId          INT           NULL,
    EsSecuencial    BIT           NOT NULL DEFAULT 0,
    MaxLanes        INT           NOT NULL DEFAULT 0,
    AlturaBase      DECIMAL(8,2)  NOT NULL DEFAULT 40,
    Orden           INT           NOT NULL DEFAULT 0,
    Visible         BIT           NOT NULL DEFAULT 1,
    Habilitado      BIT           NOT NULL DEFAULT 1,
    ColorFondo      INT           NULL,
    CONSTRAINT PK_FS_PL_Center PRIMARY KEY (CodigoEmpresa, CenterId),
    CONSTRAINT UQ_FS_PL_Center_Codigo UNIQUE (CodigoEmpresa, CodigoCentro),
    CONSTRAINT FK_FS_PL_Center_Area FOREIGN KEY (CodigoEmpresa, AreaId) REFERENCES FS_PL_Area(CodigoEmpresa, AreaId)
);

-- FS_PL_Calendar
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Calendar')
CREATE TABLE FS_PL_Calendar (
    CodigoEmpresa   SMALLINT      NOT NULL,
    CalendarId      INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(100) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Calendar PRIMARY KEY (CodigoEmpresa, CalendarId),
    CONSTRAINT UQ_FS_PL_Calendar_Nombre UNIQUE (CodigoEmpresa, Nombre)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_CalendarDayRule')
CREATE TABLE FS_PL_CalendarDayRule (
    CodigoEmpresa   SMALLINT      NOT NULL,
    DayRuleId       INT IDENTITY(1,1) NOT NULL,
    CalendarId      INT           NOT NULL,
    DiaSemana       INT           NOT NULL,
    HoraInicioNoLab TIME          NOT NULL,
    HoraFinNoLab    TIME          NOT NULL,
    CONSTRAINT PK_FS_PL_CalendarDayRule PRIMARY KEY (CodigoEmpresa, DayRuleId),
    CONSTRAINT FK_FS_PL_CalDayRule_Cal FOREIGN KEY (CodigoEmpresa, CalendarId) REFERENCES FS_PL_Calendar(CodigoEmpresa, CalendarId) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_CalendarException')
CREATE TABLE FS_PL_CalendarException (
    CodigoEmpresa   SMALLINT      NOT NULL,
    ExceptionId     INT IDENTITY(1,1) NOT NULL,
    CalendarId      INT           NOT NULL,
    Fecha           DATE          NOT NULL,
    EsLaborable     BIT           NOT NULL DEFAULT 0,
    HoraInicio      TIME          NULL,
    HoraFin         TIME          NULL,
    Descripcion     NVARCHAR(200) NULL,
    CONSTRAINT PK_FS_PL_CalendarException PRIMARY KEY (CodigoEmpresa, ExceptionId),
    CONSTRAINT FK_FS_PL_CalException_Cal FOREIGN KEY (CodigoEmpresa, CalendarId) REFERENCES FS_PL_Calendar(CodigoEmpresa, CalendarId) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_CenterCalendar')
CREATE TABLE FS_PL_CenterCalendar (
    CodigoEmpresa   SMALLINT      NOT NULL,
    CenterId        INT           NOT NULL,
    CalendarId      INT           NOT NULL,
    CONSTRAINT PK_FS_PL_CenterCalendar PRIMARY KEY (CodigoEmpresa, CenterId, CalendarId),
    CONSTRAINT FK_FS_PL_CenterCal_Center FOREIGN KEY (CodigoEmpresa, CenterId) REFERENCES FS_PL_Center(CodigoEmpresa, CenterId),
    CONSTRAINT FK_FS_PL_CenterCal_Cal FOREIGN KEY (CodigoEmpresa, CalendarId) REFERENCES FS_PL_Calendar(CodigoEmpresa, CalendarId)
);

-- FS_PL_Shift
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Shift')
CREATE TABLE FS_PL_Shift (
    CodigoEmpresa   SMALLINT      NOT NULL,
    ShiftId         INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(100) NOT NULL,
    HoraInicio      TIME          NOT NULL,
    HoraFin         TIME          NOT NULL,
    Color           INT           NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    Orden           INT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_Shift PRIMARY KEY (CodigoEmpresa, ShiftId)
);

-- FS_PL_Department
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Department')
CREATE TABLE FS_PL_Department (
    CodigoEmpresa   SMALLINT      NOT NULL,
    DepartmentId    INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    CONSTRAINT PK_FS_PL_Department PRIMARY KEY (CodigoEmpresa, DepartmentId)
);

-- FS_PL_Operator
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Operator')
CREATE TABLE FS_PL_Operator (
    CodigoEmpresa   SMALLINT      NOT NULL,
    OperatorId      INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    CalendarId      INT           NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Operator PRIMARY KEY (CodigoEmpresa, OperatorId),
    CONSTRAINT FK_FS_PL_Operator_Cal FOREIGN KEY (CodigoEmpresa, CalendarId) REFERENCES FS_PL_Calendar(CodigoEmpresa, CalendarId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_OperatorDepartment')
CREATE TABLE FS_PL_OperatorDepartment (
    CodigoEmpresa   SMALLINT      NOT NULL,
    OperatorId      INT           NOT NULL,
    DepartmentId    INT           NOT NULL,
    CONSTRAINT PK_FS_PL_OperatorDept PRIMARY KEY (CodigoEmpresa, OperatorId, DepartmentId),
    CONSTRAINT FK_FS_PL_OpDept_Op FOREIGN KEY (CodigoEmpresa, OperatorId) REFERENCES FS_PL_Operator(CodigoEmpresa, OperatorId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_OpDept_Dept FOREIGN KEY (CodigoEmpresa, DepartmentId) REFERENCES FS_PL_Department(CodigoEmpresa, DepartmentId) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_OperatorSkill')
CREATE TABLE FS_PL_OperatorSkill (
    CodigoEmpresa   SMALLINT      NOT NULL,
    OperatorId      INT           NOT NULL,
    Operacion       NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_FS_PL_OperatorSkill PRIMARY KEY (CodigoEmpresa, OperatorId, Operacion),
    CONSTRAINT FK_FS_PL_OpSkill_Op FOREIGN KEY (CodigoEmpresa, OperatorId) REFERENCES FS_PL_Operator(CodigoEmpresa, OperatorId) ON DELETE CASCADE
);

-- FS_PL_Node + NodeData + NodeCenterAllowed
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Node')
CREATE TABLE FS_PL_Node (
    CodigoEmpresa   SMALLINT      NOT NULL,
    NodeId          INT IDENTITY(1,1) NOT NULL,
    ProjectId       INT           NOT NULL,
    CenterId        INT           NULL,
    FechaInicio     DATETIME2     NULL,
    FechaFin        DATETIME2     NULL,
    DuracionMin     DECIMAL(12,2) NOT NULL DEFAULT 0,
    Caption         NVARCHAR(500) NULL,
    ColorFondo      INT           NULL DEFAULT 15251072,  -- BGR $00E8B880 (RGB 128,184,232) azul cal
    ColorBorde      INT           NULL DEFAULT 11166760,  -- BGR $00AA6428 (RGB 40,100,170)  azul cal oscuro
    Visible         BIT           NOT NULL DEFAULT 1,
    Habilitado      BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Node PRIMARY KEY (CodigoEmpresa, NodeId),
    CONSTRAINT FK_FS_PL_Node_Project FOREIGN KEY (CodigoEmpresa, ProjectId) REFERENCES FS_PL_Project(CodigoEmpresa, ProjectId),
    CONSTRAINT FK_FS_PL_Node_Center FOREIGN KEY (CodigoEmpresa, CenterId) REFERENCES FS_PL_Center(CodigoEmpresa, CenterId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_NodeData')
CREATE TABLE FS_PL_NodeData (
    CodigoEmpresa       SMALLINT      NOT NULL,
    NodeId              INT           NOT NULL,
    Operacion           NVARCHAR(100) NULL,
    NumeroPedido        INT           NULL,
    SeriePedido         NVARCHAR(20)  NULL,
    NumeroOF            INT           NULL,
    SerieOF             NVARCHAR(20)  NULL,
    NumeroTrabajo       NVARCHAR(50)  NULL,
    FechaEntrega        DATETIME2     NULL,
    FechaNecesaria      DATETIME2     NULL,
    CodigoCliente       NVARCHAR(50)  NULL,
    CodigoColor         NVARCHAR(50)  NULL,
    CodigoTalla         NVARCHAR(50)  NULL,
    Stock               DECIMAL(14,4) NULL DEFAULT 0,
    CodigoArticulo      NVARCHAR(50)  NULL,
    DescripcionArticulo NVARCHAR(500) NULL,
    PorcentajeDependencia DECIMAL(8,4) NULL DEFAULT 0,
    UnidadesFabricadas  DECIMAL(14,4) NULL DEFAULT 0,
    UnidadesAFabricar   DECIMAL(14,4) NULL DEFAULT 0,
    TiempoUnidadFabSecs DECIMAL(14,4) NULL DEFAULT 0,
    DuracionMin         DECIMAL(12,2) NULL DEFAULT 0,
    DuracionMinOriginal DECIMAL(12,2) NULL DEFAULT 0,
    OperariosNecesarios INT           NULL DEFAULT 0,
    OperariosAsignados  INT           NULL DEFAULT 0,
    Estado              TINYINT       NOT NULL DEFAULT 0,
    Tipo                TINYINT       NOT NULL DEFAULT 0,
    Prioridad           INT           NOT NULL DEFAULT 0,
    ColorFondoOp        INT           NULL DEFAULT 15251072,  -- azul cal
    ColorBordeOp        INT           NULL DEFAULT 11166760,  -- azul cal oscuro
    LibreMovimiento     BIT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_NodeData PRIMARY KEY (CodigoEmpresa, NodeId),
    CONSTRAINT FK_FS_PL_NodeData_Node FOREIGN KEY (CodigoEmpresa, NodeId) REFERENCES FS_PL_Node(CodigoEmpresa, NodeId) ON DELETE CASCADE
);

-- Otras tablas (Dependency, OperatorAssignment, CustomField, Mold, PlanningProfile, Snapshot, Marker, ErpMapping, AuditLog, Almacen, Role, User, Permission, RolePermission, AccessLog)
-- Se añaden a continuación en el mismo bloque para simplificar V001

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Dependency')
CREATE TABLE FS_PL_Dependency (
    CodigoEmpresa   SMALLINT      NOT NULL,
    DependencyId    INT IDENTITY(1,1) NOT NULL,
    ProjectId       INT           NOT NULL,
    FromNodeId      INT           NOT NULL,
    ToNodeId        INT           NOT NULL,
    TipoLink        TINYINT       NOT NULL DEFAULT 0,
    PorcentajeDependencia DECIMAL(8,4) NOT NULL DEFAULT 100,
    CONSTRAINT PK_FS_PL_Dependency PRIMARY KEY (CodigoEmpresa, DependencyId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_OperatorAssignment')
CREATE TABLE FS_PL_OperatorAssignment (
    CodigoEmpresa   SMALLINT      NOT NULL,
    AssignmentId    INT IDENTITY(1,1) NOT NULL,
    OperatorId      INT           NOT NULL,
    NodeId          INT           NOT NULL,
    Horas           DECIMAL(8,2)  NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_OpAssignment PRIMARY KEY (CodigoEmpresa, AssignmentId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Almacen')
CREATE TABLE FS_PL_Almacen (
    CodigoEmpresa   SMALLINT      NOT NULL,
    AlmacenId       INT IDENTITY(1,1) NOT NULL,
    Codigo          NVARCHAR(30)  NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    Direccion       NVARCHAR(500) NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Almacen PRIMARY KEY (CodigoEmpresa, AlmacenId),
    CONSTRAINT UQ_FS_PL_Almacen_Codigo UNIQUE (CodigoEmpresa, Codigo)
);

-- Roles y usuarios
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Role')
CREATE TABLE FS_PL_Role (
    CodigoEmpresa   SMALLINT      NOT NULL,
    RoleId          INT IDENTITY(1,1) NOT NULL,
    Codigo          NVARCHAR(30)  NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Role PRIMARY KEY (CodigoEmpresa, RoleId),
    CONSTRAINT UQ_FS_PL_Role_Codigo UNIQUE (CodigoEmpresa, Codigo)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_User')
CREATE TABLE FS_PL_User (
    CodigoEmpresa   SMALLINT      NOT NULL,
    UserId          INT IDENTITY(1,1) NOT NULL,
    Login           NVARCHAR(50)  NOT NULL,
    PasswordHash    NVARCHAR(256) NOT NULL,
    NombreCompleto  NVARCHAR(200) NOT NULL,
    Email           NVARCHAR(200) NULL,
    RoleId          INT           NOT NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    UltimoAcceso    DATETIME2     NULL,
    FechaCreacion   DATETIME2     NOT NULL DEFAULT GETDATE(),
    Intentos        INT           NOT NULL DEFAULT 0,
    Bloqueado       BIT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_User PRIMARY KEY (CodigoEmpresa, UserId),
    CONSTRAINT UQ_FS_PL_User_Login UNIQUE (CodigoEmpresa, Login),
    CONSTRAINT FK_FS_PL_User_Role FOREIGN KEY (CodigoEmpresa, RoleId) REFERENCES FS_PL_Role(CodigoEmpresa, RoleId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Permission')
CREATE TABLE FS_PL_Permission (
    CodigoEmpresa   SMALLINT      NOT NULL,
    PermissionId    INT IDENTITY(1,1) NOT NULL,
    Codigo          NVARCHAR(50)  NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    Modulo          NVARCHAR(50)  NULL,
    CONSTRAINT PK_FS_PL_Permission PRIMARY KEY (CodigoEmpresa, PermissionId),
    CONSTRAINT UQ_FS_PL_Permission_Codigo UNIQUE (CodigoEmpresa, Codigo)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_RolePermission')
CREATE TABLE FS_PL_RolePermission (
    CodigoEmpresa   SMALLINT      NOT NULL,
    RoleId          INT           NOT NULL,
    PermissionId    INT           NOT NULL,
    CONSTRAINT PK_FS_PL_RolePermission PRIMARY KEY (CodigoEmpresa, RoleId, PermissionId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_AccessLog')
CREATE TABLE FS_PL_AccessLog (
    CodigoEmpresa   SMALLINT      NOT NULL,
    LogId           BIGINT IDENTITY(1,1) NOT NULL,
    UserId          INT           NULL,
    Login           NVARCHAR(50)  NOT NULL,
    FechaHora       DATETIME2     NOT NULL DEFAULT GETDATE(),
    Resultado       NVARCHAR(20)  NOT NULL,
    IPAddress       NVARCHAR(50)  NULL,
    MachineName     NVARCHAR(100) NULL,
    CONSTRAINT PK_FS_PL_AccessLog PRIMARY KEY (CodigoEmpresa, LogId)
);
