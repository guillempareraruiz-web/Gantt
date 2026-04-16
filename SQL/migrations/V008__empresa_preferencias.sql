-- ============================================================================
-- V008 - Preferencias de planificación por empresa
-- ============================================================================

IF COL_LENGTH('FS_PL_Empresa', 'PlanificaOperarios') IS NULL
    ALTER TABLE FS_PL_Empresa ADD PlanificaOperarios BIT NULL;
GO

IF COL_LENGTH('FS_PL_Empresa', 'PlanificaMoldes') IS NULL
    ALTER TABLE FS_PL_Empresa ADD PlanificaMoldes BIT NULL;
GO

IF COL_LENGTH('FS_PL_Empresa', 'EstructuraNodos') IS NULL
    ALTER TABLE FS_PL_Empresa ADD EstructuraNodos TINYINT NULL;
GO

UPDATE FS_PL_Empresa SET PlanificaOperarios = 1 WHERE PlanificaOperarios IS NULL;
UPDATE FS_PL_Empresa SET PlanificaMoldes = 0 WHERE PlanificaMoldes IS NULL;
UPDATE FS_PL_Empresa SET EstructuraNodos = 1 WHERE EstructuraNodos IS NULL;
