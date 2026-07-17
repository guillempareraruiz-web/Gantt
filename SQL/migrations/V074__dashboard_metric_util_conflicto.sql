-- ===========================================================================
-- V074 - Amplia FS_PL_DashboardMetric con el KPI "Utillajes en conflicto":
--   - UtilConflicto : nº de utillajes que en algun instante del plan estan
--                     asignados a mas nodos simultaneos que ejemplares tienen
--                     (Cantidad). Es la misma restriccion dura que respeta el
--                     motor (R02); si sale > 0, algo planifico saltandosela.
--
-- Migracion separada (no editando V069) para que aplique aunque V069 ya se
-- hubiera ejecutado. Guarda COL_LENGTH -> idempotente.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH('FS_PL_DashboardMetric', 'UtilConflicto') IS NULL
    ALTER TABLE FS_PL_DashboardMetric ADD UtilConflicto DECIMAL(9,2) NOT NULL
        CONSTRAINT DF_DashMetric_UtilConf DEFAULT 0;
GO
