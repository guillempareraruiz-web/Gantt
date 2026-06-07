-- ===========================================================================
-- V054 - Funcion canonica de duracion de una OP (Nivel 3) en minutos.
--
-- Unica fuente de verdad para "cuanto dura una operacion" antes de planificar.
-- La usan tanto las vistas agregadas del Backlog (prevision por OF/OT) como el
-- motor de planificacion (uBacklogScheduler), que hasta ahora solo hacia
-- HorasEstimadas * 60 (con default 60 min), ignorando los tiempos reales.
--
-- Cascada (validada contra datos reales del Sage, 2026-06-07):
--   1) Tiempo de fabricacion: OpTiempoFabricacion viene en DIAS y es el tiempo
--      TOTAL de la operacion (no por unidad) -> * 24 * 60 = minutos.
--   2) Fallback si no hay TFab: Cantidad / OpUnidadesHora (unidades/hora) * 60.
--   3) Fallback si tampoco hay UxH: HorasEstimadas * 60.
--   4) Default final: 60 min.
--   + Preparacion: OpTiempoPreparacion (tambien en DIAS) * 24 * 60. Hoy viene 0
--     en todas las OP, pero se suma para quedar preparado cuando se rellene.
--
-- Cobertura observada (1193 OP activas): 879 via TFab, 177 via HorasEstimadas,
-- 137 al default. tfab-sin-uxh = 0 (siempre vienen juntos).
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('FS_PL_fn_DuracionOpMin', 'FN') IS NOT NULL
    DROP FUNCTION FS_PL_fn_DuracionOpMin;
GO

CREATE FUNCTION FS_PL_fn_DuracionOpMin
(
    @Cantidad            DECIMAL(18,4),
    @OpTiempoFabricacion DECIMAL(18,4),   -- dias, total operacion
    @OpUnidadesHora      DECIMAL(18,4),   -- unidades/hora
    @OpTiempoPreparacion DECIMAL(18,4),   -- dias
    @HorasEstimadas      DECIMAL(12,2)
)
RETURNS DECIMAL(18,4)
AS
BEGIN
    DECLARE @PrepMin DECIMAL(18,4) =
        CASE WHEN @OpTiempoPreparacion > 0
             THEN @OpTiempoPreparacion * 24.0 * 60.0
             ELSE 0 END;

    DECLARE @FabMin DECIMAL(18,4) =
        CASE
            WHEN @OpTiempoFabricacion > 0
                THEN @OpTiempoFabricacion * 24.0 * 60.0
            WHEN @OpUnidadesHora > 0 AND @Cantidad > 0
                THEN (@Cantidad / @OpUnidadesHora) * 60.0
            WHEN @HorasEstimadas > 0
                THEN @HorasEstimadas * 60.0
            ELSE 60.0
        END;

    RETURN @PrepMin + @FabMin;
END;
GO
