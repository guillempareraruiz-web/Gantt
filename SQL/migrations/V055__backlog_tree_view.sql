-- ===========================================================================
-- V055 - Vista Backlog multinivel con prevision agregada: FS_PL_vw_BacklogTree.
--
-- Permite ver/planificar el Backlog a Nivel 1 (OF/PED/PRJ), Nivel 2 (OT/LINEA/
-- TAREA) o Nivel 3 (OP), no solo el leaf como FS_PL_vw_Backlog. El llamador
-- filtra por la columna Nivel.
--
-- A diferencia de FS_PL_vw_Backlog (solo leafs sin node), esta expone TODOS los
-- nodos del arbol que tengan al menos una OP descendiente PENDIENTE (sin node).
-- Para cada fila agrega, sobre sus OP descendientes pendientes:
--   DuracionPrevistaMin  SUM(FS_PL_fn_DuracionOpMin(...))   (cascada V054)
--   NumOpsTotal          nº de OP descendientes (Nivel 3, activas)
--   NumOpsPendientes     nº de esas OP aun sin planificar
--   FechaCompromisoMin   menor FechaCompromiso de las OP pendientes
--
-- Estructura jerarquica regular (verificado 2026-06-07): Nivel 3 -> 2 -> 1
-- siempre; ninguna OP cuelga directa de una OF. Por eso los agregados usan
-- joins directos por nivel y no recursion.
--
-- FS_PL_vw_Backlog (solo leafs) se mantiene intacta para compatibilidad.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('FS_PL_vw_BacklogTree', 'V') IS NOT NULL DROP VIEW FS_PL_vw_BacklogTree;
GO

CREATE VIEW FS_PL_vw_BacklogTree AS
WITH
-- Todas las OP (Nivel 3) activas PENDIENTES (sin node planificado), con su
-- duracion calculada y su cadena de ancestros (Nivel 2 = padre, Nivel 1 = abuelo).
OpsPend AS (
    SELECT
        op.CodigoEmpresa,
        op.RawItemId        AS OpId,
        op.ParentRawItemId  AS Nivel2Id,
        p1.ParentRawItemId  AS Nivel1Id,
        op.FechaCompromiso,
        CAST(dbo.FS_PL_fn_DuracionOpMin(
                op.Cantidad, op.OpTiempoFabricacion, op.OpUnidadesHora,
                op.OpTiempoPreparacion, op.HorasEstimadas) AS DECIMAL(18,4)) AS DurMin
    FROM FS_PL_Raw_Item op
    LEFT JOIN FS_PL_Raw_Item p1
        ON p1.CodigoEmpresa = op.CodigoEmpresa
       AND p1.RawItemId     = op.ParentRawItemId
    WHERE op.Nivel = 3
      AND op.Activo = 1
      AND NOT EXISTS (
            SELECT 1 FROM FS_PL_NodeData nd
            WHERE nd.CodigoEmpresa     = op.CodigoEmpresa
              AND nd.RawItemTipoOrigen = op.TipoOrigen
              AND nd.RawItemClaveERP   = op.ClaveERP)
),
-- Todas las OP (Nivel 3) activas, pendientes o no, para contar el total.
OpsAll AS (
    SELECT
        op.CodigoEmpresa,
        op.RawItemId        AS OpId,
        op.ParentRawItemId  AS Nivel2Id,
        p1.ParentRawItemId  AS Nivel1Id
    FROM FS_PL_Raw_Item op
    LEFT JOIN FS_PL_Raw_Item p1
        ON p1.CodigoEmpresa = op.CodigoEmpresa
       AND p1.RawItemId     = op.ParentRawItemId
    WHERE op.Nivel = 3
      AND op.Activo = 1
),
-- Agregados por cada nodo del arbol segun su nivel: para Nivel 3 el agregado es
-- la propia OP; para Nivel 2 las OP cuyo padre es ese nodo; para Nivel 1 las OP
-- cuyo abuelo es ese nodo.
Agg AS (
    SELECT
        n.CodigoEmpresa,
        n.RawItemId,
        SUM(CASE WHEN pend.OpId IS NOT NULL THEN pend.DurMin ELSE 0 END) AS DuracionPrevistaMin,
        SUM(CASE WHEN allp.OpId IS NOT NULL THEN 1 ELSE 0 END)           AS NumOpsTotal,
        SUM(CASE WHEN pend.OpId IS NOT NULL THEN 1 ELSE 0 END)           AS NumOpsPendientes,
        MIN(pend.FechaCompromiso)                                        AS FechaCompromisoMin
    FROM FS_PL_Raw_Item n
    LEFT JOIN OpsAll allp
        ON allp.CodigoEmpresa = n.CodigoEmpresa
       AND ( (n.Nivel = 3 AND allp.OpId     = n.RawItemId)
          OR (n.Nivel = 2 AND allp.Nivel2Id = n.RawItemId)
          OR (n.Nivel = 1 AND allp.Nivel1Id = n.RawItemId) )
    LEFT JOIN OpsPend pend
        ON pend.CodigoEmpresa = n.CodigoEmpresa
       AND pend.OpId          = allp.OpId
    WHERE n.Activo = 1
    GROUP BY n.CodigoEmpresa, n.RawItemId
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
    -- Bloque OP (Nivel 3): propios de la operacion, sin herencia.
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
    -- Agregados de prevision (V055).
    CAST(ag.DuracionPrevistaMin AS DECIMAL(18,4))                                 AS DuracionPrevistaMin,
    ag.NumOpsTotal,
    ag.NumOpsPendientes,
    ag.FechaCompromisoMin
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
WHERE ri.Activo = 1
  -- Solo nodos con al menos una OP descendiente pendiente (algo que planificar).
  AND ag.NumOpsPendientes > 0;
GO
