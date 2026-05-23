-- ===========================================================================
-- V038 - Sincronizacion ERP para Modelos Horarios
--
-- Anade metadatos de sync (Source/ErpSistema/ErpCodigo/LastErpHash/LastErpSyncAt)
-- a FS_PL_ShiftModel para identificar modelos importados desde el ERP y
-- detectar conflictos en sincronizaciones posteriores.
--
-- Las lineas (FS_PL_ShiftModelLine) NO llevan metadatos propios: son
-- "hijas" del modelo y se reemplazan completamente cuando el modelo se
-- actualiza desde el ERP (las lineas locales editadas a mano se pierden
-- si el conflicto se resuelve con "Aplicar ERP"). Esta decision evita
-- N x sync metadata en una tabla de detalle.
--
-- Se asegura un calendario contenedor "ERP" donde colgar los modelos
-- importados (los usuarios pueden moverlos a otros calendarios despues).
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_ShiftModel - metadatos sync
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_ShiftModel', 'Source') IS NULL
    ALTER TABLE FS_PL_ShiftModel ADD Source NVARCHAR(20) NOT NULL
        CONSTRAINT DF_FS_PL_ShiftModel_Source DEFAULT 'MANUAL';
GO

IF COL_LENGTH('FS_PL_ShiftModel', 'ErpSistema') IS NULL
    ALTER TABLE FS_PL_ShiftModel ADD ErpSistema NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_ShiftModel', 'ErpCodigo') IS NULL
    ALTER TABLE FS_PL_ShiftModel ADD ErpCodigo NVARCHAR(20) NULL;
GO

IF COL_LENGTH('FS_PL_ShiftModel', 'LastErpHash') IS NULL
    ALTER TABLE FS_PL_ShiftModel ADD LastErpHash NVARCHAR(64) NULL;
GO

IF COL_LENGTH('FS_PL_ShiftModel', 'LastErpSyncAt') IS NULL
    ALTER TABLE FS_PL_ShiftModel ADD LastErpSyncAt DATETIME2 NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_ShiftModel_ErpCodigo'
                 AND object_id = OBJECT_ID('FS_PL_ShiftModel'))
CREATE NONCLUSTERED INDEX IX_FS_PL_ShiftModel_ErpCodigo
    ON FS_PL_ShiftModel (CodigoEmpresa, Source, ErpCodigo);
GO

-- ---------------------------------------------------------------------------
-- Calendario contenedor "ERP" por empresa (uno por empresa con datos)
-- ---------------------------------------------------------------------------
INSERT INTO FS_PL_Calendar (CodigoEmpresa, Nombre, Descripcion, Activo)
SELECT e.CodigoEmpresa, N'ERP', N'Modelos horarios importados del ERP', 1
FROM FS_PL_Empresa e
WHERE NOT EXISTS (
    SELECT 1 FROM FS_PL_Calendar c
    WHERE c.CodigoEmpresa = e.CodigoEmpresa
      AND c.Nombre = N'ERP'
);
GO
