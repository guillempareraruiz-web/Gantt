-- ============================================================================
-- V076 - Amplia el CHECK de FS_PL_Project.RowMode para admitir 'CLIENTES'.
--
--   Nuevo RowMode CLIENTES (filas = clientes, vista de carga comercial, solo
--   lectura). Se anade al catalogo CENTROS/GRUPO/TREE/UTILLAJES (V017/V075).
--   Sin recrear el CHECK, editar un proyecto a CLIENTES en Gestion de
--   Proyectos falla con "conflicto con la restriccion CHECK".
--
--   VARCHAR(10) del campo ya da cabida a 'CLIENTES' (8 caracteres).
--   Idempotente: solo actua si el CHECK actual no admite ya 'CLIENTES'.
-- ============================================================================

SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints
           WHERE name = 'CK_FS_PL_Project_RowMode'
             AND definition NOT LIKE '%CLIENTES%')
BEGIN
    ALTER TABLE FS_PL_Project DROP CONSTRAINT CK_FS_PL_Project_RowMode;

    ALTER TABLE FS_PL_Project
        ADD CONSTRAINT CK_FS_PL_Project_RowMode
            CHECK (RowMode IN ('CENTROS','GRUPO','TREE','UTILLAJES','CLIENTES'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_FS_PL_Project_RowMode')
    ALTER TABLE FS_PL_Project
        ADD CONSTRAINT CK_FS_PL_Project_RowMode
            CHECK (RowMode IN ('CENTROS','GRUPO','TREE','UTILLAJES','CLIENTES'));
GO
