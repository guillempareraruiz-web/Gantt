-- ===========================================================================
-- V070 - Proyecto de demostracion aislado (columna EsDemo).
--
-- Para poder poblar el Gantt con muchos nodos ficticios en "modo demo" SIN
-- tocar ni mezclar los datos reales del cliente, los nodos demo viven en un
-- PROYECTO propio marcado con EsDemo = 1. Como todo el codigo del planificador
-- (carga, drag, undo, lotes, dependencias, alertas...) ya filtra por ProjectId,
-- basta con cambiar el proyecto activo a este proyecto demo cuando se activa el
-- modo demo, y volver al real al desactivarlo. Nada de los datos reales se toca.
--
-- El proyecto demo:
--   - Se identifica por EsDemo = 1 (no por su nombre, que el usuario podria
--     cambiar).
--   - Se crea una sola vez por empresa, bajo demanda, la primera vez que se
--     abre el Gantt en modo demo.
--   - Se puede regenerar (DELETE de sus nodos + INSERT) cuantas veces se quiera;
--     al filtrar por su ProjectId, nunca afecta a otros proyectos.
--
-- Modelo aditivo: EsDemo BIT NOT NULL DEFAULT 0 -> todos los proyectos
-- existentes quedan como NO demo (comportamiento actual intacto).
-- ===========================================================================

SET NOCOUNT ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID('FS_PL_Project') AND name = 'EsDemo'
)
BEGIN
    ALTER TABLE FS_PL_Project
        ADD EsDemo BIT NOT NULL CONSTRAINT DF_FS_PL_Project_EsDemo DEFAULT 0;
END
GO
