-- ===========================================================================
-- V069 - Amplia FS_PL_DashboardMetric (V068) con KPIs avanzados del Dashboard:
--   - Otif          : % de OF que terminan dentro de su fecha de entrega.
--   - SatOperarios  : % de saturacion media de los operarios (horas asignadas
--                     sobre su jornada disponible).
--   - CuelloBotella : % de saturacion del centro mas cargado (el que limita el
--                     plan), frente a la "saturacion media" que diluye.
--
-- Se anyade como migracion separada (no editando V068) para que aplique aunque
-- V068 ya se hubiera ejecutado en la BD. Guardas COL_LENGTH -> idempotente.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH('FS_PL_DashboardMetric', 'Otif') IS NULL
    ALTER TABLE FS_PL_DashboardMetric ADD Otif DECIMAL(9,2) NOT NULL
        CONSTRAINT DF_DashMetric_Otif DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_DashboardMetric', 'SatOperarios') IS NULL
    ALTER TABLE FS_PL_DashboardMetric ADD SatOperarios DECIMAL(9,2) NOT NULL
        CONSTRAINT DF_DashMetric_SatOp DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_DashboardMetric', 'CuelloBotella') IS NULL
    ALTER TABLE FS_PL_DashboardMetric ADD CuelloBotella DECIMAL(9,2) NOT NULL
        CONSTRAINT DF_DashMetric_Cuello DEFAULT 0;
GO
