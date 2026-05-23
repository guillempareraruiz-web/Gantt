-- ===========================================================================
-- V039 - Sincronizacion ERP para Almacenes y Familias
--
-- 1) FS_PL_Almacen: amplia con campos del ERP (GrupoAlmacen, Responsable,
--    direccion completa, telefono) + metadatos de sync.
--
-- 2) FS_PL_Familia: nueva tabla. PK compuesta (CodigoEmpresa, FamiliaId).
--    El ERP da una fila por (CodigoFamilia, CodigoSubfamilia) - tratamos
--    cada combinacion como una entidad propia (es la granularidad util
--    para clasificar articulos).
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Almacen - campos negocio ERP
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_Almacen', 'GrupoAlmacen') IS NULL
    ALTER TABLE FS_PL_Almacen ADD GrupoAlmacen NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_Almacen', 'Responsable') IS NULL
    ALTER TABLE FS_PL_Almacen ADD Responsable NVARCHAR(100) NULL;
GO

IF COL_LENGTH('FS_PL_Almacen', 'CodigoPostal') IS NULL
    ALTER TABLE FS_PL_Almacen ADD CodigoPostal NVARCHAR(20) NULL;
GO

IF COL_LENGTH('FS_PL_Almacen', 'Municipio') IS NULL
    ALTER TABLE FS_PL_Almacen ADD Municipio NVARCHAR(100) NULL;
GO

IF COL_LENGTH('FS_PL_Almacen', 'Provincia') IS NULL
    ALTER TABLE FS_PL_Almacen ADD Provincia NVARCHAR(100) NULL;
GO

IF COL_LENGTH('FS_PL_Almacen', 'Telefono') IS NULL
    ALTER TABLE FS_PL_Almacen ADD Telefono NVARCHAR(50) NULL;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Almacen - metadatos sync ERP
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_Almacen', 'Source') IS NULL
    ALTER TABLE FS_PL_Almacen ADD Source NVARCHAR(20) NOT NULL
        CONSTRAINT DF_FS_PL_Almacen_Source DEFAULT 'MANUAL';
GO

IF COL_LENGTH('FS_PL_Almacen', 'ErpSistema') IS NULL
    ALTER TABLE FS_PL_Almacen ADD ErpSistema NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_Almacen', 'ErpCodigo') IS NULL
    ALTER TABLE FS_PL_Almacen ADD ErpCodigo NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_Almacen', 'LastErpHash') IS NULL
    ALTER TABLE FS_PL_Almacen ADD LastErpHash NVARCHAR(64) NULL;
GO

IF COL_LENGTH('FS_PL_Almacen', 'LastErpSyncAt') IS NULL
    ALTER TABLE FS_PL_Almacen ADD LastErpSyncAt DATETIME2 NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Almacen_ErpCodigo'
                 AND object_id = OBJECT_ID('FS_PL_Almacen'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Almacen_ErpCodigo
    ON FS_PL_Almacen (CodigoEmpresa, Source, ErpCodigo);
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Familia (NUEVA)
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Familia')
CREATE TABLE FS_PL_Familia (
    CodigoEmpresa     SMALLINT      NOT NULL,
    FamiliaId         INT IDENTITY(1,1) NOT NULL,
    CodigoFamilia     NVARCHAR(30)  NOT NULL,
    CodigoSubfamilia  NVARCHAR(30)  NOT NULL CONSTRAINT DF_FS_PL_Familia_Sub DEFAULT '',
    Descripcion       NVARCHAR(200) NOT NULL,
    TipoF             NVARCHAR(10)  NULL,
    CodigoSeccion     NVARCHAR(30)  NULL,
    CodigoDepartamento NVARCHAR(30) NULL,
    Activo            BIT           NOT NULL CONSTRAINT DF_FS_PL_Familia_Act DEFAULT 1,
    Source            NVARCHAR(20)  NOT NULL CONSTRAINT DF_FS_PL_Familia_Source DEFAULT 'MANUAL',
    ErpSistema        NVARCHAR(30)  NULL,
    ErpCodigo         NVARCHAR(70)  NULL,    -- 'FAM|SUBFAM' clave compuesta
    LastErpHash       NVARCHAR(64)  NULL,
    LastErpSyncAt     DATETIME2     NULL,
    CONSTRAINT PK_FS_PL_Familia PRIMARY KEY (CodigoEmpresa, FamiliaId),
    CONSTRAINT UQ_FS_PL_Familia_Codigo UNIQUE (CodigoEmpresa, CodigoFamilia, CodigoSubfamilia)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Familia_ErpCodigo'
                 AND object_id = OBJECT_ID('FS_PL_Familia'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Familia_ErpCodigo
    ON FS_PL_Familia (CodigoEmpresa, Source, ErpCodigo);
GO
