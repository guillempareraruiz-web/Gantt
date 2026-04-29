-- ============================================================================
-- V004 - Añadir concepto de Proyecto MASTER y Escenarios
-- ============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FS_PL_Project') AND name = 'EsMaster')
    EXEC('ALTER TABLE FS_PL_Project ADD EsMaster BIT NOT NULL CONSTRAINT DF_FS_PL_Project_EsMaster DEFAULT 0');
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FS_PL_Project') AND name = 'EsEscenario')
    EXEC('ALTER TABLE FS_PL_Project ADD EsEscenario BIT NOT NULL CONSTRAINT DF_FS_PL_Project_EsEscenario DEFAULT 0');
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FS_PL_Project') AND name = 'BasedOnProjectId')
    EXEC('ALTER TABLE FS_PL_Project ADD BasedOnProjectId INT NULL');
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('FS_PL_Project') AND name = 'FechaPromocionMaster')
    EXEC('ALTER TABLE FS_PL_Project ADD FechaPromocionMaster DATETIME2 NULL');
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_Project_Master')
    EXEC('CREATE NONCLUSTERED INDEX IX_FS_PL_Project_Master ON FS_PL_Project(CodigoEmpresa, EsMaster) WHERE EsMaster = 1');
GO

-- Crear un proyecto MASTER por defecto para cada empresa existente (si no lo tiene)
INSERT INTO FS_PL_Project (CodigoEmpresa, Codigo, Nombre, Descripcion, EsMaster, Activo)
SELECT e.CodigoEmpresa, 'MASTER', 'Planificación MASTER', 'Planificación productiva vigente', 1, 1
FROM FS_PL_Empresa e
WHERE e.Activo = 1
  AND NOT EXISTS (SELECT 1 FROM FS_PL_Project p WHERE p.CodigoEmpresa = e.CodigoEmpresa AND p.EsMaster = 1);
GO
