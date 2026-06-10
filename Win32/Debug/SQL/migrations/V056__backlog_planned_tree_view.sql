-- ===========================================================================
-- V056 - Vista Planificados multinivel: FS_PL_vw_BacklogPlannedTree.
--
-- Analoga a FS_PL_vw_BacklogTree (V055) pero sobre OP YA PLANIFICADAS (con node).
-- Permite ver el tab "Planificados" del Backlog a Nivel 1 (OF/PED/PRJ), Nivel 2
-- (OT/LINEA/TAREA) o Nivel 3 (OP). El llamador filtra por la columna Nivel.
--
-- Expone TODOS los nodos del arbol que tengan al menos una OP descendiente
-- PLANIFICADA. Para cada fila agrega, sobre sus OP descendientes planificadas:
--   NodeInicioMin / NodeFinMax  rango de fechas del conjunto de nodos
--   NodeDuracionMin             suma de duracion planificada (minutos)
--   NumOpsPlan                  nº de OP descendientes ya planificadas
--   NumOpsTotal                 nº de OP descendientes (activas)
--   NumCentros                  nº de centros distintos usados
-- El indicador de progreso es NumOpsPlan / NumOpsTotal (una OF a medias).
--
-- A Nivel 3 (OP) la fila ya es un node concreto: trae sus campos Node* directos
-- (NodeId, NodeInicio, NodeFin, centro), igual que FS_PL_vw_BacklogPlanned, mas
-- los agregados (que a Nivel 3 valen lo de la propia OP).
--
-- Estructura jerarquica regular (OP -> OT -> OF). FS_PL_vw_BacklogPlanned (1 fila
-- por OP) se mantiene intacta para compatibilidad.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('FS_PL_vw_BacklogPlannedTree', 'V') IS NOT NULL
    DROP VIEW FS_PL_vw_BacklogPlannedTree;
GO

CREATE VIEW FS_PL_vw_BacklogPlannedTree AS
WITH
-- Todas las OP (Nivel 3) activas con su estado de planificacion y, si esta
-- planificada, los datos de su node (fechas, duracion, centro).
OpNode AS (
    SELECT
        op.CodigoEmpresa,
        op.RawItemId        AS OpId,
        op.ParentRawItemId  AS Nivel2Id,
        p1.ParentRawItemId  AS Nivel1Id,
        n.NodeId,
        n.ProjectId,
        n.FechaInicio       AS NodeInicio,
        n.FechaFin          AS NodeFin,
        n.DuracionMin       AS NodeDuracionMin,
        n.CenterId          AS NodeCenterId
    FROM FS_PL_Raw_Item op
    LEFT JOIN FS_PL_Raw_Item p1
        ON p1.CodigoEmpresa = op.CodigoEmpresa
       AND p1.RawItemId     = op.ParentRawItemId
    LEFT JOIN FS_PL_NodeData nd
        ON nd.CodigoEmpresa     = op.CodigoEmpresa
       AND nd.RawItemTipoOrigen = op.TipoOrigen
       AND nd.RawItemClaveERP   = op.ClaveERP
    LEFT JOIN FS_PL_Node n
        ON n.CodigoEmpresa = nd.CodigoEmpresa AND n.NodeId = nd.NodeId
    WHERE op.Nivel = 3 AND op.Activo = 1
),
-- Agregados por cada nodo del arbol segun su nivel.
Agg AS (
    SELECT
        node.CodigoEmpresa,
        node.RawItemId,
        MIN(CASE WHEN o.NodeId IS NOT NULL THEN o.NodeInicio END) AS NodeInicioMin,
        MAX(CASE WHEN o.NodeId IS NOT NULL THEN o.NodeFin    END) AS NodeFinMax,
        SUM(CASE WHEN o.NodeId IS NOT NULL THEN o.NodeDuracionMin ELSE 0 END) AS NodeDuracionMin,
        SUM(CASE WHEN o.NodeId IS NOT NULL THEN 1 ELSE 0 END)     AS NumOpsPlan,
        COUNT(*)                                                  AS NumOpsTotal,
        COUNT(DISTINCT CASE WHEN o.NodeId IS NOT NULL THEN o.NodeCenterId END) AS NumCentros,
        MIN(CASE WHEN o.NodeId IS NOT NULL THEN o.ProjectId END)  AS AnyProjectId
    FROM FS_PL_Raw_Item node
    JOIN OpNode o
        ON o.CodigoEmpresa = node.CodigoEmpresa
       AND ( (node.Nivel = 3 AND o.OpId     = node.RawItemId)
          OR (node.Nivel = 2 AND o.Nivel2Id = node.RawItemId)
          OR (node.Nivel = 1 AND o.Nivel1Id = node.RawItemId) )
    WHERE node.Activo = 1
    GROUP BY node.CodigoEmpresa, node.RawItemId
)
SELECT
    CAST(
        CASE
            WHEN ri.Nivel = 3 THEN 'OP'
            WHEN ri.Nivel = 2 AND ri.TipoOrigen = 'OF ' THEN 'OT'
            WHEN ri.Nivel = 2 AND ri.TipoOrigen = 'PED' THEN 'LINEA'
            WHEN ri.Nivel = 2 AND ri.TipoOrigen = 'PRJ' THEN 'TAREA'
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'OF ' THEN 'OF'
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'PED' THEN 'PEDIDO'
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'PRJ' THEN 'PROYECTO'
            ELSE RTRIM(ri.TipoOrigen)
        END AS VARCHAR(10))                  AS Origen,
    ri.CodigoEmpresa,
    ri.RawItemId                             AS RawId,
    ri.TipoOrigen,
    ri.Nivel,
    ri.ParentRawItemId,
    ri.OrigenERP,
    ri.ClaveERP,
    CASE
        WHEN ri.TipoOrigen = 'OF '
            THEN CONCAT(ISNULL(ri.SerieDoc,''), '-', ISNULL(CAST(ri.NumeroDoc AS NVARCHAR(20)),''),
                        CASE WHEN ri.Nivel >= 2 AND ri.LineaDoc IS NOT NULL
                             THEN CONCAT('/', ri.LineaDoc) ELSE '' END,
                        CASE WHEN ri.Nivel = 3 AND ri.Codigo IS NOT NULL
                             THEN CONCAT(' ', ri.Codigo) ELSE '' END)
        WHEN ri.TipoOrigen = 'PED'
            THEN CONCAT(ISNULL(ri.SerieDoc,''), '-', ISNULL(CAST(ri.NumeroDoc AS NVARCHAR(20)),''),
                        CASE WHEN ri.LineaDoc IS NOT NULL THEN CONCAT('/', ri.LineaDoc) ELSE '' END,
                        CASE WHEN ri.Nivel = 3 AND ri.Codigo IS NOT NULL
                             THEN CONCAT(' ', ri.Codigo) ELSE '' END)
        WHEN ri.TipoOrigen = 'PRJ'
            THEN CONCAT(ISNULL(ri.CodigoProyecto, ri.Nombre),
                        CASE WHEN ri.Nivel >= 2 AND ri.Codigo IS NOT NULL
                             THEN CONCAT(' / ', ri.Codigo) ELSE '' END)
        ELSE ri.ClaveERP
    END                                       AS CodigoDocumento,
    CASE WHEN ri.TipoOrigen = 'OF ' THEN
        CASE ri.Nivel WHEN 1 THEN ri.NumeroDoc WHEN 2 THEN p1.NumeroDoc
                      WHEN 3 THEN p2.NumeroDoc ELSE NULL END
    END                                                                           AS NumeroOF,
    CASE WHEN ri.TipoOrigen = 'OF ' THEN
        CASE ri.Nivel WHEN 1 THEN NULLIF(ri.SerieDoc,'') WHEN 2 THEN NULLIF(p1.SerieDoc,'')
                      WHEN 3 THEN NULLIF(p2.SerieDoc,'') ELSE NULL END
    END                                                                           AS SerieOF,
    CASE WHEN ri.Nivel = 3 THEN ri.Codigo ELSE NULL END                          AS CodigoOP,
    CASE
        WHEN ri.Nivel = 3 THEN p1.Codigo
        WHEN ri.Nivel = 2 THEN ri.Codigo
        ELSE NULL
    END                                                                           AS CodigoOT,
    COALESCE(ri.NumeroDoc, p1.NumeroDoc, p2.NumeroDoc)                            AS NumeroDoc,
    COALESCE(NULLIF(ri.SerieDoc,''), NULLIF(p1.SerieDoc,''), NULLIF(p2.SerieDoc,'')) AS SerieDoc,
    COALESCE(ri.LineaDoc,  p1.LineaDoc,  p2.LineaDoc)                             AS LineaDoc,
    COALESCE(NULLIF(ri.CodigoArticulo,''), NULLIF(p1.CodigoArticulo,''),
             NULLIF(p2.CodigoArticulo,''))                                        AS CodigoArticulo,
    COALESCE(NULLIF(ri.DescripcionArticulo,''), NULLIF(ri.Nombre,''),
             NULLIF(ri.Descripcion,''), NULLIF(p1.DescripcionArticulo,''),
             NULLIF(p2.DescripcionArticulo,''))                                   AS DescripcionArticulo,
    COALESCE(ri.Cantidad, p1.Cantidad, p2.Cantidad)                               AS Cantidad,
    COALESCE(NULLIF(ri.UnidadMedida,''), NULLIF(p1.UnidadMedida,''),
             NULLIF(p2.UnidadMedida,''))                                          AS UnidadMedida,
    COALESCE(NULLIF(ri.CodigoCliente,''), NULLIF(p1.CodigoCliente,''),
             NULLIF(p2.CodigoCliente,''))                                         AS CodigoCliente,
    COALESCE(NULLIF(ri.NombreCliente,''), NULLIF(p1.NombreCliente,''),
             NULLIF(p2.NombreCliente,''))                                         AS NombreCliente,
    COALESCE(NULLIF(ri.CodigoProyecto,''), NULLIF(p1.CodigoProyecto,''),
             NULLIF(p2.CodigoProyecto,''))                                        AS CodigoProyecto,
    COALESCE(ri.FechaCompromiso, p1.FechaCompromiso, p2.FechaCompromiso)          AS FechaCompromiso,
    COALESCE(ri.FechaNecesaria, p1.FechaNecesaria, p2.FechaNecesaria)             AS FechaNecesaria,
    COALESCE(ri.FechaCompromiso, p1.FechaCompromiso, p2.FechaCompromiso)          AS FechaEntrega,
    COALESCE(ri.Prioridad, p1.Prioridad, p2.Prioridad)                            AS Prioridad,
    COALESCE(NULLIF(ri.CentroPreferente,''), NULLIF(p1.CentroPreferente,''),
             NULLIF(p2.CentroPreferente,''))                                      AS CentroPreferente,
    ri.HorasEstimadas,
    CASE
        WHEN ri.HorasEstimadas IS NOT NULL
         AND COALESCE(ri.Cantidad, p1.Cantidad, p2.Cantidad) > 0
        THEN CAST(ri.HorasEstimadas * 3600.0
                  / COALESCE(ri.Cantidad, p1.Cantidad, p2.Cantidad) AS DECIMAL(14,4))
        ELSE NULL
    END                                                                           AS TiempoUnidadFabSecs,
    ri.EstadoERP,
    ri.Observaciones,
    ri.Orden                                                                      AS Orden,
    ri.OpTiempoPreparacion,
    ri.OpTiempoFabricacion,
    ri.OpUnidadesHora,
    ri.OpCosteHoraMaquina,
    ri.OpCosteHoraManoObra,
    ri.OpUnidadesFabricadas,
    ri.OpFechaInicioReal,
    ri.OpFechaFinalReal,
    ri.OpOperacionExterna,
    ri.OpCodigoProveedor,
    ri.OpSeccionFabrica,
    ri.OpStatusPlanificado,
    ri.OpObservaciones,
    ri.OpPctParaSigOperacion,
    ri.OpPctDedicacionOperario,
    ri.FechaImportacion,
    -- Datos del node directos SOLO a Nivel 3 (la fila ya es un node concreto).
    CASE WHEN ri.Nivel = 3 THEN n3.NodeId      END AS NodeId,
    ag.AnyProjectId                                AS ProjectId,
    -- A Nivel 1/2, NodeInicio/Fin son el rango agregado; a Nivel 3, los del node.
    ag.NodeInicioMin                               AS NodeInicio,
    ag.NodeFinMax                                  AS NodeFin,
    CAST(ag.NodeDuracionMin AS FLOAT)              AS NodeDuracionMin,
    CASE WHEN ri.Nivel = 3 THEN n3.CenterId    END AS NodeCenterId,
    CASE WHEN ri.Nivel = 3 THEN cn3.CodigoCentro END AS NodeCodigoCentro,
    CASE WHEN ri.Nivel = 3 THEN cn3.Titulo     END AS NodeCentroNombre,
    -- Agregados de progreso (V056). El rango ya se expone como NodeInicio/NodeFin.
    ag.NumOpsPlan,
    ag.NumOpsTotal,
    ag.NumCentros
FROM FS_PL_Raw_Item ri
JOIN Agg ag
    ON ag.CodigoEmpresa = ri.CodigoEmpresa
   AND ag.RawItemId     = ri.RawItemId
LEFT JOIN FS_PL_Raw_Item p1
    ON p1.CodigoEmpresa = ri.CodigoEmpresa
   AND p1.RawItemId     = ri.ParentRawItemId
LEFT JOIN FS_PL_Raw_Item p2
    ON p2.CodigoEmpresa = p1.CodigoEmpresa
   AND p2.RawItemId     = p1.ParentRawItemId
-- Solo para Nivel 3: el node concreto de esta OP (para columnas Node* directas).
OUTER APPLY (
    SELECT TOP 1 n.NodeId, n.CenterId
    FROM FS_PL_NodeData nd
    JOIN FS_PL_Node n
        ON n.CodigoEmpresa = nd.CodigoEmpresa AND n.NodeId = nd.NodeId
    WHERE ri.Nivel = 3
      AND nd.CodigoEmpresa     = ri.CodigoEmpresa
      AND nd.RawItemTipoOrigen = ri.TipoOrigen
      AND nd.RawItemClaveERP   = ri.ClaveERP
) n3
LEFT JOIN FS_PL_Center cn3
    ON cn3.CodigoEmpresa = ri.CodigoEmpresa AND cn3.CenterId = n3.CenterId
WHERE ri.Activo = 1
  AND ag.NumOpsPlan > 0;   -- solo nodos con alguna OP ya planificada
GO
