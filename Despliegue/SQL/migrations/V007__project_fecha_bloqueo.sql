-- ============================================================================
-- V007 - Fecha de bloqueo de replanificación por proyecto
-- ============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('FS_PL_Project')
      AND name = 'FechaBloqueo'
)
ALTER TABLE FS_PL_Project ADD FechaBloqueo DATETIME2 NULL;
GO
