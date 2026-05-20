-- ===========================================================================
-- V033 - Moldes y utillajes (esquema completo)
--
-- Crea las tablas FS_PL_Mold y sus relaciones si no existen, y a~nade los
-- campos que pueda faltarles en BBDD existentes (compatibilidad con
-- instalaciones que ya tuvieran FS_PL_Mold creada manualmente desde el
-- script viejo SQL\002_Create_Planner_Schema.sql).
--
-- Cambios respecto al script viejo:
--   * FS_PL_MoldCenter ahora lleva Preferente + TiempoMontajeEspecifico.
--   * FS_PL_MoldArticle lleva CavidadesActivas + Observaciones.
--   * FS_PL_MoldOperation lleva CiclosPorUnidad + Observaciones.
--   * FS_PL_MoldUtillaje (NUEVA): utillajes asociados al molde.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Mold (tabla principal)
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Mold')
CREATE TABLE FS_PL_Mold (
    CodigoEmpresa            SMALLINT       NOT NULL,
    MoldId                   INT IDENTITY(1,1) NOT NULL,
    Codigo                   NVARCHAR(30)   NOT NULL,
    Descripcion              NVARCHAR(500)  NULL,
    TipoMolde                TINYINT        NOT NULL CONSTRAINT DF_FS_PL_Mold_Tipo DEFAULT 4,
    Estado                   TINYINT        NOT NULL CONSTRAINT DF_FS_PL_Mold_Estado DEFAULT 0,
    UbicacionActual          NVARCHAR(200)  NULL,
    CentroActualId           INT            NULL,
    NumeroCavidades          INT            NOT NULL CONSTRAINT DF_FS_PL_Mold_Cav DEFAULT 1,
    TiempoMontaje            DECIMAL(8,2)   NULL CONSTRAINT DF_FS_PL_Mold_TM DEFAULT 0,
    TiempoDesmontaje         DECIMAL(8,2)   NULL CONSTRAINT DF_FS_PL_Mold_TD DEFAULT 0,
    TiempoAjuste             DECIMAL(8,2)   NULL CONSTRAINT DF_FS_PL_Mold_TA DEFAULT 0,
    CiclosAcumulados         INT            NOT NULL CONSTRAINT DF_FS_PL_Mold_Ciclos DEFAULT 0,
    FechaProxMantenimiento   DATE           NULL,
    DisponiblePlanificacion  BIT            NOT NULL CONSTRAINT DF_FS_PL_Mold_Disp DEFAULT 1,
    Observaciones            NVARCHAR(MAX)  NULL,
    CONSTRAINT PK_FS_PL_Mold PRIMARY KEY (CodigoEmpresa, MoldId),
    CONSTRAINT UQ_FS_PL_Mold_Codigo UNIQUE (CodigoEmpresa, Codigo)
);
GO

-- Patches para BBDD existentes (campos que pueden faltar)
IF COL_LENGTH('FS_PL_Mold', 'TipoMolde') IS NULL
    ALTER TABLE FS_PL_Mold ADD TipoMolde TINYINT NOT NULL
        CONSTRAINT DF_FS_PL_Mold_Tipo_P DEFAULT 4;
GO
IF COL_LENGTH('FS_PL_Mold', 'Estado') IS NULL
    ALTER TABLE FS_PL_Mold ADD Estado TINYINT NOT NULL
        CONSTRAINT DF_FS_PL_Mold_Estado_P DEFAULT 0;
GO
IF COL_LENGTH('FS_PL_Mold', 'CentroActualId') IS NULL
    ALTER TABLE FS_PL_Mold ADD CentroActualId INT NULL;
GO
IF COL_LENGTH('FS_PL_Mold', 'FechaProxMantenimiento') IS NULL
    ALTER TABLE FS_PL_Mold ADD FechaProxMantenimiento DATE NULL;
GO
IF COL_LENGTH('FS_PL_Mold', 'Observaciones') IS NULL
    ALTER TABLE FS_PL_Mold ADD Observaciones NVARCHAR(MAX) NULL;
GO

-- FK CentroActualId -> FS_PL_Center (si no existe ya)
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_FS_PL_Mold_Center'
)
ALTER TABLE FS_PL_Mold WITH NOCHECK ADD CONSTRAINT FK_FS_PL_Mold_Center
    FOREIGN KEY (CodigoEmpresa, CentroActualId)
    REFERENCES FS_PL_Center (CodigoEmpresa, CenterId);
GO

-- ---------------------------------------------------------------------------
-- FS_PL_MoldCenter (centros donde se puede usar)
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_MoldCenter')
CREATE TABLE FS_PL_MoldCenter (
    CodigoEmpresa            SMALLINT       NOT NULL,
    MoldId                   INT            NOT NULL,
    CenterId                 INT            NOT NULL,
    Preferente               BIT            NOT NULL CONSTRAINT DF_FS_PL_MoldCenter_Pref DEFAULT 0,
    TiempoMontajeEspecifico  DECIMAL(8,2)   NOT NULL CONSTRAINT DF_FS_PL_MoldCenter_TM DEFAULT 0,
    CONSTRAINT PK_FS_PL_MoldCenter PRIMARY KEY (CodigoEmpresa, MoldId, CenterId),
    CONSTRAINT FK_FS_PL_MoldCenter_Mold FOREIGN KEY (CodigoEmpresa, MoldId)
        REFERENCES FS_PL_Mold (CodigoEmpresa, MoldId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_MoldCenter_Center FOREIGN KEY (CodigoEmpresa, CenterId)
        REFERENCES FS_PL_Center (CodigoEmpresa, CenterId)
);
GO
IF COL_LENGTH('FS_PL_MoldCenter', 'Preferente') IS NULL
    ALTER TABLE FS_PL_MoldCenter ADD Preferente BIT NOT NULL
        CONSTRAINT DF_FS_PL_MoldCenter_Pref_P DEFAULT 0;
GO
IF COL_LENGTH('FS_PL_MoldCenter', 'TiempoMontajeEspecifico') IS NULL
    ALTER TABLE FS_PL_MoldCenter ADD TiempoMontajeEspecifico DECIMAL(8,2) NOT NULL
        CONSTRAINT DF_FS_PL_MoldCenter_TM_P DEFAULT 0;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_MoldArticle (articulos que se pueden fabricar)
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_MoldArticle')
CREATE TABLE FS_PL_MoldArticle (
    CodigoEmpresa     SMALLINT       NOT NULL,
    MoldId            INT            NOT NULL,
    CodigoArticulo    NVARCHAR(50)   NOT NULL,
    CavidadesActivas  INT            NOT NULL CONSTRAINT DF_FS_PL_MoldArticle_Cav DEFAULT 0,
    Observaciones     NVARCHAR(500)  NULL,
    CONSTRAINT PK_FS_PL_MoldArticle PRIMARY KEY (CodigoEmpresa, MoldId, CodigoArticulo),
    CONSTRAINT FK_FS_PL_MoldArticle_Mold FOREIGN KEY (CodigoEmpresa, MoldId)
        REFERENCES FS_PL_Mold (CodigoEmpresa, MoldId) ON DELETE CASCADE
);
GO
IF COL_LENGTH('FS_PL_MoldArticle', 'CavidadesActivas') IS NULL
    ALTER TABLE FS_PL_MoldArticle ADD CavidadesActivas INT NOT NULL
        CONSTRAINT DF_FS_PL_MoldArticle_Cav_P DEFAULT 0;
GO
IF COL_LENGTH('FS_PL_MoldArticle', 'Observaciones') IS NULL
    ALTER TABLE FS_PL_MoldArticle ADD Observaciones NVARCHAR(500) NULL;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_MoldOperation (operaciones compatibles)
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_MoldOperation')
CREATE TABLE FS_PL_MoldOperation (
    CodigoEmpresa     SMALLINT       NOT NULL,
    MoldId            INT            NOT NULL,
    Operacion         NVARCHAR(100)  NOT NULL,
    CiclosPorUnidad   DECIMAL(10,3)  NOT NULL CONSTRAINT DF_FS_PL_MoldOp_Ciclos DEFAULT 1,
    Observaciones     NVARCHAR(500)  NULL,
    CONSTRAINT PK_FS_PL_MoldOperation PRIMARY KEY (CodigoEmpresa, MoldId, Operacion),
    CONSTRAINT FK_FS_PL_MoldOp_Mold FOREIGN KEY (CodigoEmpresa, MoldId)
        REFERENCES FS_PL_Mold (CodigoEmpresa, MoldId) ON DELETE CASCADE
);
GO
IF COL_LENGTH('FS_PL_MoldOperation', 'CiclosPorUnidad') IS NULL
    ALTER TABLE FS_PL_MoldOperation ADD CiclosPorUnidad DECIMAL(10,3) NOT NULL
        CONSTRAINT DF_FS_PL_MoldOp_Ciclos_P DEFAULT 1;
GO
IF COL_LENGTH('FS_PL_MoldOperation', 'Observaciones') IS NULL
    ALTER TABLE FS_PL_MoldOperation ADD Observaciones NVARCHAR(500) NULL;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_MoldUtillaje (NUEVA: utillajes asociados al molde)
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_MoldUtillaje')
CREATE TABLE FS_PL_MoldUtillaje (
    CodigoEmpresa     SMALLINT       NOT NULL,
    MoldId            INT            NOT NULL,
    CodigoUtillaje    NVARCHAR(50)   NOT NULL,
    Obligatorio       BIT            NOT NULL CONSTRAINT DF_FS_PL_MoldUt_Obl DEFAULT 1,
    Observaciones     NVARCHAR(500)  NULL,
    CONSTRAINT PK_FS_PL_MoldUtillaje PRIMARY KEY (CodigoEmpresa, MoldId, CodigoUtillaje),
    CONSTRAINT FK_FS_PL_MoldUt_Mold FOREIGN KEY (CodigoEmpresa, MoldId)
        REFERENCES FS_PL_Mold (CodigoEmpresa, MoldId) ON DELETE CASCADE
);
GO
