-- ===========================================================================
-- V058 - Lote: modo de calculo de duracion + setup compartido.
--
-- Un lote agrupa N operaciones que se procesan juntas en un centro. El motivo
-- real de agrupar suele ser AHORRAR tiempo de preparacion (setup): montar la
-- pistola de pintura, calentar el horno, etc. se hace UNA vez por lote en lugar
-- de una por operacion.
--
-- Modo de duracion BASE del lote (antes de aplicar el setup):
--   0 = SECUENCIAL: las OP se hacen una tras otra -> base = SUMA de duraciones
--       reales (DuracionMinOriginal) de los miembros.
--   1 = PARALELO:   las OP se procesan a la vez (hornada) -> base = MAXIMO de
--       las duraciones reales de los miembros.
--
-- Duracion efectiva del lote = base + SetupMin. Esa duracion se reparte como
-- ventana compartida de los miembros (ver uDMPlanner.ActualizarLote).
--
-- Modelo aditivo: columnas con DEFAULT, los lotes existentes quedan en modo
-- secuencial sin setup (comportamiento previo).
-- ===========================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH('FS_PL_Lote', 'Modo') IS NULL
    ALTER TABLE FS_PL_Lote ADD Modo TINYINT NOT NULL
        CONSTRAINT DF_FS_PL_Lote_Modo DEFAULT 0;   -- 0=secuencial, 1=paralelo
GO

IF COL_LENGTH('FS_PL_Lote', 'SetupMin') IS NULL
    ALTER TABLE FS_PL_Lote ADD SetupMin DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_FS_PL_Lote_SetupMin DEFAULT 0;  -- minutos de setup compartido
GO
