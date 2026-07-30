-- ============================================================================
-- V075 - Amplia el CHECK de FS_PL_Project.RowMode para admitir 'UTILLAJES'.
--
--   El RowMode UTILLAJES (filas = utillajes, vista de diagnostico read-only)
--   se anade a los ya existentes CENTROS/GRUPO/TREE (V017). Hay que recrear el
--   CHECK CK_FS_PL_Project_RowMode: si no, editar un proyecto a UTILLAJES en
--   Gestion de Proyectos falla con "conflicto con la restriccion CHECK".
--
--   VARCHAR(10) del campo ya da cabida a 'UTILLAJES' (9 caracteres), no hace
--   falta ampliar la columna.
--
--   Idempotente: solo actua si el CHECK actual no admite ya 'UTILLAJES'.
-- ============================================================================

SET NOCOUNT ON;
GO

-- Solo recrear si el constraint existe y su definicion aun no menciona
-- 'UTILLAJES' (evita trabajo en BBDD ya migradas).
IF EXISTS (SELECT 1 FROM sys.check_constraints
           WHERE name = 'CK_FS_PL_Project_RowMode'
             AND definition NOT LIKE '%UTILLAJES%')
BEGIN
    ALTER TABLE FS_PL_Project DROP CONSTRAINT CK_FS_PL_Project_RowMode;

    ALTER TABLE FS_PL_Project
        ADD CONSTRAINT CK_FS_PL_Project_RowMode
            CHECK (RowMode IN ('CENTROS','GRUPO','TREE','UTILLAJES'));
END
GO

-- Si por lo que fuera el constraint no existiese (BD anterior a V017 sin el
-- check), crearlo ya con el catalogo completo.
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_FS_PL_Project_RowMode')
    ALTER TABLE FS_PL_Project
        ADD CONSTRAINT CK_FS_PL_Project_RowMode
            CHECK (RowMode IN ('CENTROS','GRUPO','TREE','UTILLAJES'));
GO
