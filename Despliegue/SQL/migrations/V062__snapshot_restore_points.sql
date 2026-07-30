-- ===========================================================================
-- V062 - Puntos de restauracion del plan (amplia FS_PL_Snapshot).
--
-- FS_PL_Snapshot ya existia (002_Create_Planner_Schema) con el plan serializado
-- en DatosJSON. Esta migracion la convierte en un sistema de PUNTOS DE
-- RESTAURACION con:
--   - Tipo: 'AUTO' (diario, al primer cambio del dia) o 'MANUAL' (etiquetado).
--   - FechaDia: dia (sin hora) del snapshot -> garantiza UN snapshot AUTO por
--     (empresa, proyecto, dia): el del estado al INICIO del dia, que no se
--     sobreescribe (asi cada dia es un punto limpio anterior a los cambios).
--   - NodeCount / SizeBytes: metadatos para el listado de restauracion.
--   - CreadoPorUserId: quien origino el snapshot (el plan es del proyecto, pero
--     registramos el usuario para auditoria).
--
-- Politica de retencion (la aplica el codigo): AUTO se purga; MANUAL nunca.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH('FS_PL_Snapshot', 'Tipo') IS NULL
    ALTER TABLE FS_PL_Snapshot ADD Tipo NVARCHAR(10) NOT NULL
        CONSTRAINT DF_FS_PL_Snapshot_Tipo DEFAULT 'MANUAL';
GO

IF COL_LENGTH('FS_PL_Snapshot', 'FechaDia') IS NULL
    ALTER TABLE FS_PL_Snapshot ADD FechaDia DATE NULL;
GO

IF COL_LENGTH('FS_PL_Snapshot', 'NodeCount') IS NULL
    ALTER TABLE FS_PL_Snapshot ADD NodeCount INT NOT NULL
        CONSTRAINT DF_FS_PL_Snapshot_NodeCount DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Snapshot', 'SizeBytes') IS NULL
    ALTER TABLE FS_PL_Snapshot ADD SizeBytes INT NOT NULL
        CONSTRAINT DF_FS_PL_Snapshot_SizeBytes DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Snapshot', 'CreadoPorUserId') IS NULL
    ALTER TABLE FS_PL_Snapshot ADD CreadoPorUserId INT NULL;
GO

-- Indice para listar/buscar por proyecto y fecha (listado de restauracion y
-- comprobacion "ya hay snapshot AUTO de hoy").
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Snapshot_Proj_Dia'
                 AND object_id = OBJECT_ID('FS_PL_Snapshot'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Snapshot_Proj_Dia
    ON FS_PL_Snapshot (CodigoEmpresa, ProjectId, Tipo, FechaDia);
GO

-- Unicidad del snapshot AUTO diario: como mucho uno por (empresa, proyecto, dia)
-- de tipo AUTO. Indice unico filtrado (solo aplica a Tipo='AUTO' y FechaDia no
-- nula); los MANUAL no se ven afectados.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'UX_FS_PL_Snapshot_AutoDia'
                 AND object_id = OBJECT_ID('FS_PL_Snapshot'))
CREATE UNIQUE NONCLUSTERED INDEX UX_FS_PL_Snapshot_AutoDia
    ON FS_PL_Snapshot (CodigoEmpresa, ProjectId, FechaDia)
    WHERE Tipo = 'AUTO' AND FechaDia IS NOT NULL;
GO
