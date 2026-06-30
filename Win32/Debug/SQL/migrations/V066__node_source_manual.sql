-- ===========================================================================
-- V066 - Origen del nodo: ERP vs MANUAL.
--
-- Hasta ahora todos los nodos del plan provenian del ERP (via Backlog /
-- Raw_Item). Algunos clientes (p.ej. ingenierias) quieren planificar carga de
-- trabajo que NO existe en el ERP: diseño grafico, tareas administrativas,
-- oficina tecnica... El usuario crea estos nodos a mano sobre el Gantt
-- (boton derecho -> "Crear nodo manual"), indicando descripcion, centro,
-- duracion y fecha de inicio.
--
-- Ambos mundos CONVIVEN en el mismo plan MASTER: el scheduler, los lotes, las
-- dependencias, las alertas, los snapshots y el undo tratan a todos los nodos
-- por igual. El campo Source solo cambia tres cosas:
--   1) como se crea el nodo (dialogo manual vs planificacion de Backlog),
--   2) como se pinta en el Gantt (distincion visual),
--   3) si se hace write-back al ERP (los 'MAN' NUNCA se escriben al ERP).
--
-- Modelo aditivo: Source NOT NULL DEFAULT 'ERP' -> todos los nodos existentes
-- quedan marcados como 'ERP' (comportamiento actual intacto). Los nodos
-- manuales nuevos se insertan con Source='MAN'.
--
--   'ERP' = nodo proveniente del ERP (Raw_Item vinculado).
--   'MAN' = nodo manual creado por el usuario (puede o no tener vinculo ERP).
-- ===========================================================================

SET NOCOUNT ON;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE object_id = OBJECT_ID('FS_PL_Node') AND name = 'Source'
)
BEGIN
    ALTER TABLE FS_PL_Node
        ADD Source CHAR(3) NOT NULL CONSTRAINT DF_FS_PL_Node_Source DEFAULT 'ERP';
END
GO
