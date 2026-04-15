-- ============================================================================
-- FSPlanner 2026 - Usuarios, Roles y Permisos
-- Prefijo: FS_PL_
-- Motor: SQL Server 2016+
-- NOTA: Todas las tablas incluyen CodigoEmpresa (SMALLINT) como parte de la PK
-- ============================================================================

-- ============================================================================
-- 1. ROLES
-- ============================================================================
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

-- ============================================================================
-- 2. USUARIOS
-- ============================================================================
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

-- ============================================================================
-- 3. PERMISOS (catálogo)
-- ============================================================================
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

-- ============================================================================
-- 4. RELACIÓN ROL ↔ PERMISO
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_RolePermission')
CREATE TABLE FS_PL_RolePermission (
    CodigoEmpresa   SMALLINT      NOT NULL,
    RoleId          INT           NOT NULL,
    PermissionId    INT           NOT NULL,
    CONSTRAINT PK_FS_PL_RolePermission PRIMARY KEY (CodigoEmpresa, RoleId, PermissionId),
    CONSTRAINT FK_FS_PL_RolePerm_Role FOREIGN KEY (CodigoEmpresa, RoleId) REFERENCES FS_PL_Role(CodigoEmpresa, RoleId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_RolePerm_Perm FOREIGN KEY (CodigoEmpresa, PermissionId) REFERENCES FS_PL_Permission(CodigoEmpresa, PermissionId) ON DELETE CASCADE
);

-- ============================================================================
-- 5. LOG DE ACCESOS
-- ============================================================================
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

-- ============================================================================
-- ÍNDICES
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_User_Role')
CREATE NONCLUSTERED INDEX IX_FS_PL_User_Role ON FS_PL_User(CodigoEmpresa, RoleId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_AccessLog_User')
CREATE NONCLUSTERED INDEX IX_FS_PL_AccessLog_User ON FS_PL_AccessLog(CodigoEmpresa, UserId, FechaHora);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_AccessLog_Fecha')
CREATE NONCLUSTERED INDEX IX_FS_PL_AccessLog_Fecha ON FS_PL_AccessLog(CodigoEmpresa, FechaHora);

-- ============================================================================
-- DATOS DEMO (solo empresa 9999)
-- ============================================================================

-- Roles demo
INSERT INTO FS_PL_Role (CodigoEmpresa, Codigo, Nombre, Descripcion)
SELECT 9999, v.Codigo, v.Nombre, v.Descripcion
FROM (VALUES
  ('ADMIN',        'Administrador',  'Control total del sistema'),
  ('PLANIFICADOR', 'Planificador',   'Puede ver y modificar la planificación'),
  ('SUPERVISOR',   'Supervisor',     'Puede ver la planificación y reportes, sin modificar'),
  ('OPERARIO',     'Operario',       'Solo consulta de su cuadro de trabajo')
) AS v(Codigo, Nombre, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM FS_PL_Role r WHERE r.CodigoEmpresa = 9999 AND r.Codigo = v.Codigo);

-- Permisos demo
INSERT INTO FS_PL_Permission (CodigoEmpresa, Codigo, Nombre, Modulo)
SELECT 9999, v.Codigo, v.Nombre, v.Modulo
FROM (VALUES
  ('PLAN_VIEW',      'Ver planificación',             'PLANIFICACION'),
  ('PLAN_EDIT',      'Modificar planificación',       'PLANIFICACION'),
  ('PLAN_DELETE',    'Eliminar operaciones',          'PLANIFICACION'),
  ('PLAN_REPLAN',    'Replanificar automáticamente',  'PLANIFICACION'),
  ('PLAN_EXPORT',    'Exportar planificación',        'PLANIFICACION'),
  ('CENTER_VIEW',    'Ver centros de trabajo',        'CENTROS'),
  ('CENTER_EDIT',    'Modificar centros de trabajo',  'CENTROS'),
  ('OPERATOR_VIEW',  'Ver operarios',                 'OPERARIOS'),
  ('OPERATOR_EDIT',  'Modificar operarios',           'OPERARIOS'),
  ('MOLD_VIEW',      'Ver moldes',                    'MOLDES'),
  ('MOLD_EDIT',      'Modificar moldes',              'MOLDES'),
  ('CALENDAR_VIEW',  'Ver calendarios',               'CALENDARIOS'),
  ('CALENDAR_EDIT',  'Modificar calendarios',         'CALENDARIOS'),
  ('SHIFT_VIEW',     'Ver turnos',                    'TURNOS'),
  ('SHIFT_EDIT',     'Modificar turnos',              'TURNOS'),
  ('REPORT_VIEW',    'Ver reportes y KPIs',           'REPORTES'),
  ('ADMIN_USERS',    'Gestionar usuarios',            'ADMIN'),
  ('ADMIN_ROLES',    'Gestionar roles y permisos',    'ADMIN'),
  ('ADMIN_CONFIG',   'Configuración del sistema',     'ADMIN'),
  ('ADMIN_AUDIT',    'Ver log de auditoría',          'ADMIN')
) AS v(Codigo, Nombre, Modulo)
WHERE NOT EXISTS (SELECT 1 FROM FS_PL_Permission p WHERE p.CodigoEmpresa = 9999 AND p.Codigo = v.Codigo);

-- ADMIN: todos los permisos
INSERT INTO FS_PL_RolePermission (CodigoEmpresa, RoleId, PermissionId)
SELECT r.CodigoEmpresa, r.RoleId, p.PermissionId
FROM FS_PL_Role r
INNER JOIN FS_PL_Permission p ON p.CodigoEmpresa = 9999
WHERE r.CodigoEmpresa = 9999 AND r.Codigo = 'ADMIN'
  AND NOT EXISTS (SELECT 1 FROM FS_PL_RolePermission rp
    WHERE rp.CodigoEmpresa = 9999 AND rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId);

-- PLANIFICADOR
INSERT INTO FS_PL_RolePermission (CodigoEmpresa, RoleId, PermissionId)
SELECT r.CodigoEmpresa, r.RoleId, p.PermissionId
FROM FS_PL_Role r
INNER JOIN FS_PL_Permission p ON p.CodigoEmpresa = 9999
WHERE r.CodigoEmpresa = 9999 AND r.Codigo = 'PLANIFICADOR'
  AND p.Codigo IN ('PLAN_VIEW','PLAN_EDIT','PLAN_REPLAN','PLAN_EXPORT',
                   'CENTER_VIEW','OPERATOR_VIEW','OPERATOR_EDIT',
                   'MOLD_VIEW','MOLD_EDIT','CALENDAR_VIEW','SHIFT_VIEW','REPORT_VIEW')
  AND NOT EXISTS (SELECT 1 FROM FS_PL_RolePermission rp
    WHERE rp.CodigoEmpresa = 9999 AND rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId);

-- SUPERVISOR
INSERT INTO FS_PL_RolePermission (CodigoEmpresa, RoleId, PermissionId)
SELECT r.CodigoEmpresa, r.RoleId, p.PermissionId
FROM FS_PL_Role r
INNER JOIN FS_PL_Permission p ON p.CodigoEmpresa = 9999
WHERE r.CodigoEmpresa = 9999 AND r.Codigo = 'SUPERVISOR'
  AND p.Codigo IN ('PLAN_VIEW','PLAN_EXPORT','CENTER_VIEW','OPERATOR_VIEW',
                   'MOLD_VIEW','CALENDAR_VIEW','SHIFT_VIEW','REPORT_VIEW')
  AND NOT EXISTS (SELECT 1 FROM FS_PL_RolePermission rp
    WHERE rp.CodigoEmpresa = 9999 AND rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId);

-- OPERARIO
INSERT INTO FS_PL_RolePermission (CodigoEmpresa, RoleId, PermissionId)
SELECT r.CodigoEmpresa, r.RoleId, p.PermissionId
FROM FS_PL_Role r
INNER JOIN FS_PL_Permission p ON p.CodigoEmpresa = 9999
WHERE r.CodigoEmpresa = 9999 AND r.Codigo = 'OPERARIO'
  AND p.Codigo IN ('PLAN_VIEW','REPORT_VIEW')
  AND NOT EXISTS (SELECT 1 FROM FS_PL_RolePermission rp
    WHERE rp.CodigoEmpresa = 9999 AND rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId);

-- Usuarios demo (password = login)
INSERT INTO FS_PL_User (CodigoEmpresa, Login, PasswordHash, NombreCompleto, Email, RoleId)
SELECT 9999, v.Login, v.PasswordHash, v.NombreCompleto, v.Email, r.RoleId
FROM (VALUES
  ('admin',        '8C6976E5B5410415BDE908BD4DEE15DFB167A9C873FC4BB8A81F6F2AB448A918', 'Administrador',  'admin@demo.com',        'ADMIN'),
  ('planificador', '654C0C0FE86BD0AF4DACB9997B90A1B28155EFD1B279578C1F67334BEF8BC19B', 'Planificador',   'planificador@demo.com', 'PLANIFICADOR'),
  ('supervisor',   '0834C2D60725AC5902257B3B78DD161AD26D1C0290DBF1E47CC14ADD5B8C8142', 'Supervisor',     'supervisor@demo.com',   'SUPERVISOR'),
  ('operario',     'A39BA034A2E1E73308A0291A1541AEEE1290FFA697BCA8342799EF19A7FA8C99', 'Operario',       'operario@demo.com',     'OPERARIO')
) AS v(Login, PasswordHash, NombreCompleto, Email, RoleCodigo)
INNER JOIN FS_PL_Role r ON r.CodigoEmpresa = 9999 AND r.Codigo = v.RoleCodigo
WHERE NOT EXISTS (SELECT 1 FROM FS_PL_User u WHERE u.CodigoEmpresa = 9999 AND u.Login = v.Login);

PRINT '==========================================';
PRINT 'Usuarios, Roles y Permisos creados con éxito';
PRINT '==========================================';
GO
