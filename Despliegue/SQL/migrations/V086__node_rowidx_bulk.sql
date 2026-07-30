-- ============================================================================
-- V086 - FS_PL_Node.RowIdx: clave de correlacion para el alta masiva de nodos
--
-- POR QUE
--   El camino de creacion masiva (uBulkNodePersist, planificacion desde el
--   Backlog) reservaba el rango de NodeIds con 'SELECT MAX(NodeId)+1' y los
--   asignaba a mano, insertando con IDENTITY_INSERT.
--
--   Eso NO es atomico: dos usuarios planificando a la vez reservaban el MISMO
--   rango -> clave duplicada, o peor, filas de un plan mezcladas con las de
--   otro. Es corrupcion silenciosa, no un error visible.
--
--   El arreglo es dejar que el IDENTITY genere los NodeId (fuente unica de
--   verdad, atomica por definicion) y recuperar con OUTPUT que id le ha tocado
--   a cada fila. Pero OUTPUT solo devuelve columnas de la tabla destino, y
--   ninguna columna de FS_PL_Node identifica la fila de entrada: Caption puede
--   repetirse dentro del mismo lote.
--
--   RowIdx es esa clave: el indice de la fila dentro del lote que se esta
--   insertando. Solo tiene sentido DURANTE el INSERT masivo; despues es
--   informativa (util para depurar de que lote salio un nodo).
--
--   Alternativas descartadas:
--     - Tabla de secuencia FS_PL_NodeIdSeq: convivir con el IDENTITY deja DOS
--       fuentes de ids que hay que mantener sincronizadas para siempre, y
--       obliga a reseeds cada vez que un camino inserta sin pasar por ella.
--     - MERGE ... OUTPUT S.RowIdx: funciona sin tocar el esquema, pero MERGE
--       arrastra bugs conocidos bajo concurrencia y 'MERGE ON 1=0' es un truco
--       ilegible. Se prioriza estabilidad.
--
-- NULL = fila que no viene del alta masiva (nodos manuales, demo, snapshots).
-- ============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('FS_PL_Node') AND name = 'RowIdx'
)
BEGIN
    ALTER TABLE FS_PL_Node ADD RowIdx INT NULL;
END
GO
