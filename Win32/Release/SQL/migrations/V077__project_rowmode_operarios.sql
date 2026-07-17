-- ============================================================================
-- V077 - Amplia el CHECK de FS_PL_Project.RowMode para admitir 'OPERARIOS'.
--
--   Nuevo RowMode OPERARIOS (filas = operarios, vista de carga de personal,
--   solo lectura). Cierra el trio de recursos Centros/Maquinas/Operarios.
--   Se anade al catalogo CENTROS/GRUPO/TREE/UTILLAJES/CLIENTES (V017/V075/V076).
--
--   VARCHAR(10) del campo ya da cabida a 'OPERARIOS' (9 caracteres).
--   Idempotente: solo actua si el CHECK actual no admite ya 'OPERARIOS'.
-- ============================================================================

SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints
           WHERE name = 'CK_FS_PL_Project_RowMode'
             AND definition NOT LIKE '%OPERARIOS%')
BEGIN
    ALTER TABLE FS_PL_Project DROP CONSTRAINT CK_FS_PL_Project_RowMode;

    ALTER TABLE FS_PL_Project
        ADD CONSTRAINT CK_FS_PL_Project_RowMode
            CHECK (RowMode IN ('CENTROS','GRUPO','TREE','UTILLAJES','CLIENTES','OPERARIOS'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_FS_PL_Project_RowMode')
    ALTER TABLE FS_PL_Project
        ADD CONSTRAINT CK_FS_PL_Project_RowMode
            CHECK (RowMode IN ('CENTROS','GRUPO','TREE','UTILLAJES','CLIENTES','OPERARIOS'));
GO
