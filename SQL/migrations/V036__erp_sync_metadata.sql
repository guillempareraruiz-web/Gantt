-- ===========================================================================
-- V036 - Metadata de sincronizacion ERP en FS_PL_Center y FS_PL_Maquina
--
-- Permite que el form "Sincronizar con ERP" detecte conflictos cuando una
-- entidad ha sido modificada manualmente despues de un import desde ERP.
--
-- Source        'MANUAL' | 'ERP' | 'MIXED'
-- ErpSistema    Identificador del conector ('Sage 200', 'SAP', etc.)
-- ErpCodigo     Codigo original del registro en el ERP (para matching estable
--               aunque el usuario edite el CodigoCentro local).
-- LastErpHash   Hash de los campos importados en el ultimo sync. Si el hash
--               nuevo del ERP difiere => ERP ha cambiado. Si los campos
--               locales no derivan del hash previo => usuario ha tocado.
-- LastErpSyncAt Fecha/hora del ultimo sync exitoso.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Center
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_Center', 'Source') IS NULL
    ALTER TABLE FS_PL_Center ADD Source NVARCHAR(20) NOT NULL
        CONSTRAINT DF_FS_PL_Center_Source DEFAULT 'MANUAL';
GO

IF COL_LENGTH('FS_PL_Center', 'ErpSistema') IS NULL
    ALTER TABLE FS_PL_Center ADD ErpSistema NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_Center', 'ErpCodigo') IS NULL
    ALTER TABLE FS_PL_Center ADD ErpCodigo NVARCHAR(50) NULL;
GO

IF COL_LENGTH('FS_PL_Center', 'LastErpHash') IS NULL
    ALTER TABLE FS_PL_Center ADD LastErpHash NVARCHAR(64) NULL;
GO

IF COL_LENGTH('FS_PL_Center', 'LastErpSyncAt') IS NULL
    ALTER TABLE FS_PL_Center ADD LastErpSyncAt DATETIME2 NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Center_ErpCodigo'
                 AND object_id = OBJECT_ID('FS_PL_Center'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Center_ErpCodigo
    ON FS_PL_Center (CodigoEmpresa, Source, ErpCodigo);
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Maquina
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_Maquina', 'Source') IS NULL
    ALTER TABLE FS_PL_Maquina ADD Source NVARCHAR(20) NOT NULL
        CONSTRAINT DF_FS_PL_Maquina_Source DEFAULT 'MANUAL';
GO

IF COL_LENGTH('FS_PL_Maquina', 'ErpSistema') IS NULL
    ALTER TABLE FS_PL_Maquina ADD ErpSistema NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_Maquina', 'ErpCodigo') IS NULL
    ALTER TABLE FS_PL_Maquina ADD ErpCodigo NVARCHAR(50) NULL;
GO

IF COL_LENGTH('FS_PL_Maquina', 'LastErpHash') IS NULL
    ALTER TABLE FS_PL_Maquina ADD LastErpHash NVARCHAR(64) NULL;
GO

IF COL_LENGTH('FS_PL_Maquina', 'LastErpSyncAt') IS NULL
    ALTER TABLE FS_PL_Maquina ADD LastErpSyncAt DATETIME2 NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Maquina_ErpCodigo'
                 AND object_id = OBJECT_ID('FS_PL_Maquina'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Maquina_ErpCodigo
    ON FS_PL_Maquina (CodigoEmpresa, Source, ErpCodigo);
GO
