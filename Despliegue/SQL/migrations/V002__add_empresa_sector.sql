-- ============================================================================
-- V002 - Añadir campo Sector a FS_PL_Empresa (si no existe)
-- ============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('FS_PL_Empresa') AND name = 'Sector'
)
ALTER TABLE FS_PL_Empresa ADD Sector NVARCHAR(50) NULL;

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('FS_PL_Empresa') AND name = 'EsDemo'
)
ALTER TABLE FS_PL_Empresa ADD EsDemo BIT NOT NULL DEFAULT 0;
