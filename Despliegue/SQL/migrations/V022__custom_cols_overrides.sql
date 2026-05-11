-- ===========================================================================
-- V022 - Soporte de overrides manuales en campos custom (taules _Extra)
--
-- Objetivo:
--   Las taules FS_PL_Raw_OF_Extra / FS_PL_Raw_Comanda_Extra / FS_PL_Raw_Projecte_Extra
--   guardan campos personalizados key/value. Hasta ahora solo las poblaba el
--   conector ERP. Esta migracion anade columnas de auditoria (Source, UpdatedBy,
--   UpdatedAt) para distinguir valores escritos por el ERP de overrides
--   manuales hechos por el usuario en la pantalla Backlog.
--
--   Politica:
--     - Source = 'ERP'    -> el conector ERP puede sobrescribirlo en cada import.
--     - Source = 'MANUAL' -> intocable por el ERP. Si el usuario quiere volver
--                            al valor del ERP, debe borrar la fila explicitamente.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- --------- FS_PL_Raw_OF_Extra ----------------------------------------------
IF COL_LENGTH('FS_PL_Raw_OF_Extra', 'Source') IS NULL
    ALTER TABLE FS_PL_Raw_OF_Extra ADD Source CHAR(6) NOT NULL
        CONSTRAINT DF_FS_PL_Raw_OF_Extra_Source DEFAULT 'ERP';
GO
IF COL_LENGTH('FS_PL_Raw_OF_Extra', 'UpdatedBy') IS NULL
    ALTER TABLE FS_PL_Raw_OF_Extra ADD UpdatedBy NVARCHAR(64) NULL;
GO
IF COL_LENGTH('FS_PL_Raw_OF_Extra', 'UpdatedAt') IS NULL
    ALTER TABLE FS_PL_Raw_OF_Extra ADD UpdatedAt DATETIME2 NULL;
GO

-- --------- FS_PL_Raw_Comanda_Extra -----------------------------------------
IF COL_LENGTH('FS_PL_Raw_Comanda_Extra', 'Source') IS NULL
    ALTER TABLE FS_PL_Raw_Comanda_Extra ADD Source CHAR(6) NOT NULL
        CONSTRAINT DF_FS_PL_Raw_Comanda_Extra_Source DEFAULT 'ERP';
GO
IF COL_LENGTH('FS_PL_Raw_Comanda_Extra', 'UpdatedBy') IS NULL
    ALTER TABLE FS_PL_Raw_Comanda_Extra ADD UpdatedBy NVARCHAR(64) NULL;
GO
IF COL_LENGTH('FS_PL_Raw_Comanda_Extra', 'UpdatedAt') IS NULL
    ALTER TABLE FS_PL_Raw_Comanda_Extra ADD UpdatedAt DATETIME2 NULL;
GO

-- --------- FS_PL_Raw_Projecte_Extra ----------------------------------------
IF COL_LENGTH('FS_PL_Raw_Projecte_Extra', 'Source') IS NULL
    ALTER TABLE FS_PL_Raw_Projecte_Extra ADD Source CHAR(6) NOT NULL
        CONSTRAINT DF_FS_PL_Raw_Projecte_Extra_Source DEFAULT 'ERP';
GO
IF COL_LENGTH('FS_PL_Raw_Projecte_Extra', 'UpdatedBy') IS NULL
    ALTER TABLE FS_PL_Raw_Projecte_Extra ADD UpdatedBy NVARCHAR(64) NULL;
GO
IF COL_LENGTH('FS_PL_Raw_Projecte_Extra', 'UpdatedAt') IS NULL
    ALTER TABLE FS_PL_Raw_Projecte_Extra ADD UpdatedAt DATETIME2 NULL;
GO
