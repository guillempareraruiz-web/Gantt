-- ============================================================================
-- V067 - Vista Backlog planificado: incluir NODOS MANUALES (Source='MAN').
--
-- FS_PL_vw_BacklogPlanned (ultima version en V053) parte de FS_PL_Raw_Item y
-- une con FS_PL_Node via nd.RawItemTipoOrigen + nd.RawItemClaveERP (INNER JOIN).
-- Los nodos manuales sin vinculo ERP (RawItemClaveERP NULL) no casan con ningun
-- Raw_Item y los INNER JOIN los dejan fuera del tab 'Planificados' del Backlog.
--
-- Esta migracion RECREA la vista EXACTAMENTE como en V053 (rama ERP intacta) y
-- aniade una segunda rama UNION ALL con los nodos manuales (Source='MAN'),
-- leidos directamente de FS_PL_Node / FS_PL_NodeData sin pasar por Raw_Item.
-- Los campos propios del ERP que el nodo manual no tiene quedan NULL; la
-- descripcion sale del Caption del nodo.
--
-- IMPORTANTE: la rama ERP debe quedar identica a V053. Si en el futuro se vuelve
-- a tocar la vista, hay que reescribir AMBAS ramas a la vez.
-- ============================================================================

IF OBJECT_ID('FS_PL_vw_BacklogPlanned', 'V') IS NOT NULL DROP VIEW FS_PL_vw_BacklogPlanned;
GO

CREATE VIEW FS_PL_vw_BacklogPlanned AS
-- ===== Rama ERP (identica a V053) ==========================================
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
    n.NodeId            AS NodeId,
    n.ProjectId         AS ProjectId,
    n.FechaInicio       AS NodeInicio,
    n.FechaFin          AS NodeFin,
    n.DuracionMin       AS NodeDuracionMin,
    n.CenterId          AS NodeCenterId,
    cn.CodigoCentro     AS NodeCodigoCentro,
    cn.Titulo           AS NodeCentroNombre
FROM FS_PL_Raw_Item ri
LEFT JOIN FS_PL_Raw_Item p1
    ON p1.CodigoEmpresa = ri.CodigoEmpresa
   AND p1.RawItemId     = ri.ParentRawItemId
LEFT JOIN FS_PL_Raw_Item p2
    ON p2.CodigoEmpresa = p1.CodigoEmpresa
   AND p2.RawItemId     = p1.ParentRawItemId
INNER JOIN FS_PL_NodeData nd
    ON nd.CodigoEmpresa      = ri.CodigoEmpresa
   AND nd.RawItemTipoOrigen  = ri.TipoOrigen
   AND nd.RawItemClaveERP    = ri.ClaveERP
INNER JOIN FS_PL_Node n
    ON n.CodigoEmpresa = nd.CodigoEmpresa AND n.NodeId = nd.NodeId
LEFT JOIN FS_PL_Center cn
    ON cn.CodigoEmpresa = n.CodigoEmpresa AND cn.CenterId = n.CenterId
WHERE ri.Activo = 1

UNION ALL

-- ===== Rama MANUAL (V067): nodos Source='MAN', sin Raw_Item ==================
-- Mismas columnas y tipos que la rama ERP, en el mismo orden. Los campos que el
-- nodo manual no tiene quedan NULL; la descripcion sale del Caption del nodo.
SELECT
    CAST('MANUAL' AS VARCHAR(10))            AS Origen,
    n.CodigoEmpresa,
    CAST(NULL AS BIGINT)                     AS RawId,
    CAST(NULL AS CHAR(3))                     AS TipoOrigen,
    CAST(3 AS TINYINT)                        AS Nivel,            -- se lista a Nivel OP
    CAST(NULL AS BIGINT)                      AS ParentRawItemId,
    CAST(NULL AS NVARCHAR(30))                AS OrigenERP,
    CAST(NULL AS NVARCHAR(100))               AS ClaveERP,
    ISNULL(NULLIF(n.Caption,''), nd.Operacion) AS CodigoDocumento,
    CAST(NULL AS INT)                         AS NumeroOF,
    CAST(NULL AS NVARCHAR(20))                AS SerieOF,
    CAST(NULL AS NVARCHAR(50))                AS CodigoOP,
    CAST(NULL AS NVARCHAR(50))                AS CodigoOT,
    CAST(NULL AS INT)                         AS NumeroDoc,
    CAST(NULL AS NVARCHAR(20))                AS SerieDoc,
    CAST(NULL AS INT)                         AS LineaDoc,
    nd.CodigoArticulo                         AS CodigoArticulo,
    nd.DescripcionArticulo                    AS DescripcionArticulo,
    CAST(NULL AS DECIMAL(18,4))               AS Cantidad,
    CAST(NULL AS NVARCHAR(20))                AS UnidadMedida,
    nd.CodigoCliente                          AS CodigoCliente,
    CAST(NULL AS NVARCHAR(200))               AS NombreCliente,
    CAST(NULL AS NVARCHAR(50))                AS CodigoProyecto,
    nd.FechaEntrega                           AS FechaCompromiso,
    nd.FechaNecesaria                         AS FechaNecesaria,
    nd.FechaEntrega                           AS FechaEntrega,
    nd.Prioridad                              AS Prioridad,
    CAST(NULL AS NVARCHAR(30))                AS CentroPreferente,
    CAST(n.DuracionMin / 60.0 AS DECIMAL(12,2)) AS HorasEstimadas,
    CAST(NULL AS DECIMAL(14,4))               AS TiempoUnidadFabSecs,
    CAST(NULL AS NVARCHAR(30))                AS EstadoERP,
    CAST(NULL AS NVARCHAR(MAX))               AS Observaciones,
    CAST(NULL AS INT)                         AS Orden,
    CAST(NULL AS DECIMAL(18,4))               AS OpTiempoPreparacion,
    CAST(NULL AS DECIMAL(18,4))               AS OpTiempoFabricacion,
    CAST(NULL AS DECIMAL(18,4))               AS OpUnidadesHora,
    CAST(NULL AS DECIMAL(18,4))               AS OpCosteHoraMaquina,
    CAST(NULL AS DECIMAL(18,4))               AS OpCosteHoraManoObra,
    CAST(NULL AS DECIMAL(18,4))               AS OpUnidadesFabricadas,
    CAST(NULL AS DATETIME2)                   AS OpFechaInicioReal,
    CAST(NULL AS DATETIME2)                   AS OpFechaFinalReal,
    CAST(NULL AS BIT)                         AS OpOperacionExterna,
    CAST(NULL AS NVARCHAR(15))                AS OpCodigoProveedor,
    CAST(NULL AS NVARCHAR(10))                AS OpSeccionFabrica,
    CAST(NULL AS BIT)                         AS OpStatusPlanificado,
    CAST(NULL AS NVARCHAR(MAX))               AS OpObservaciones,
    CAST(NULL AS DECIMAL(9,4))                AS OpPctParaSigOperacion,
    CAST(NULL AS DECIMAL(9,4))                AS OpPctDedicacionOperario,
    CAST(NULL AS DATETIME2)                   AS FechaImportacion,
    n.NodeId            AS NodeId,
    n.ProjectId         AS ProjectId,
    n.FechaInicio       AS NodeInicio,
    n.FechaFin          AS NodeFin,
    n.DuracionMin       AS NodeDuracionMin,
    n.CenterId          AS NodeCenterId,
    cn.CodigoCentro     AS NodeCodigoCentro,
    cn.Titulo           AS NodeCentroNombre
FROM FS_PL_Node n
INNER JOIN FS_PL_NodeData nd
    ON nd.CodigoEmpresa = n.CodigoEmpresa AND nd.NodeId = n.NodeId
LEFT JOIN FS_PL_Center cn
    ON cn.CodigoEmpresa = n.CodigoEmpresa AND cn.CenterId = n.CenterId
WHERE n.Source = 'MAN';
GO
