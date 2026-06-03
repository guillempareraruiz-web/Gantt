-- ===========================================================================
-- V053 - Campos de OperacionesOT (Sage) en FS_PL_Raw_Item + vistas Backlog.
--
-- Bloque de alto valor para planificar/ordenar/clasificar/filtrar a Nivel 3 (OP).
-- Solo se rellenan en filas OP (Nivel 3); en OF/OT quedan NULL (no aplican).
-- Prefijo 'Op' para no colisionar con campos genericos (Observaciones, etc.).
--
-- Se exponen tal cual en las 2 vistas (FS_PL_vw_Backlog / _Planned), SIN herencia
-- de padre (son propios de la operacion).
-- ===========================================================================

SET NOCOUNT ON;
GO

-- --------- 1) Columnas nuevas en FS_PL_Raw_Item ----------------------------
IF COL_LENGTH('FS_PL_Raw_Item', 'OpTiempoPreparacion') IS NULL
    ALTER TABLE FS_PL_Raw_Item ADD
        OpTiempoPreparacion     DECIMAL(18,4)  NULL,
        OpTiempoFabricacion     DECIMAL(18,4)  NULL,
        OpUnidadesHora          DECIMAL(18,4)  NULL,
        OpCosteHoraMaquina      DECIMAL(18,4)  NULL,
        OpCosteHoraManoObra     DECIMAL(18,4)  NULL,
        OpUnidadesFabricadas    DECIMAL(18,4)  NULL,
        OpFechaInicioReal       DATETIME2      NULL,
        OpFechaFinalReal        DATETIME2      NULL,
        OpOperacionExterna      BIT            NULL,
        OpCodigoProveedor       NVARCHAR(15)   NULL,
        OpSeccionFabrica        NVARCHAR(10)   NULL,
        OpStatusPlanificado     BIT            NULL,
        OpObservaciones         NVARCHAR(MAX)  NULL,
        OpPctParaSigOperacion   DECIMAL(9,4)   NULL,
        OpPctDedicacionOperario DECIMAL(9,4)   NULL;
GO

-- --------- 2) Reescribir FS_PL_vw_Backlog (V052 + bloque OP) ----------------
IF OBJECT_ID('FS_PL_vw_Backlog', 'V') IS NOT NULL DROP VIEW FS_PL_vw_Backlog;
GO

CREATE VIEW FS_PL_vw_Backlog AS
WITH Leafs AS (
    SELECT ri.*
    FROM FS_PL_Raw_Item ri
    WHERE ri.Activo = 1
      AND NOT EXISTS (
            SELECT 1 FROM FS_PL_Raw_Item c
            WHERE c.CodigoEmpresa   = ri.CodigoEmpresa
              AND c.ParentRawItemId = ri.RawItemId
              AND c.Activo          = 1)
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
    -- Orden de la operacion dentro de la OT (secuencia de planificacion).
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
    ri.FechaImportacion
FROM Leafs ri
LEFT JOIN FS_PL_Raw_Item p1
    ON p1.CodigoEmpresa = ri.CodigoEmpresa
   AND p1.RawItemId     = ri.ParentRawItemId
LEFT JOIN FS_PL_Raw_Item p2
    ON p2.CodigoEmpresa = p1.CodigoEmpresa
   AND p2.RawItemId     = p1.ParentRawItemId
WHERE NOT EXISTS (
    SELECT 1 FROM FS_PL_NodeData nd
    WHERE nd.CodigoEmpresa      = ri.CodigoEmpresa
      AND nd.RawItemTipoOrigen  = ri.TipoOrigen
      AND nd.RawItemClaveERP    = ri.ClaveERP);
GO


-- --------- 3) Reescribir FS_PL_vw_BacklogPlanned (V052 + bloque OP) ---------
IF OBJECT_ID('FS_PL_vw_BacklogPlanned', 'V') IS NOT NULL DROP VIEW FS_PL_vw_BacklogPlanned;
GO

CREATE VIEW FS_PL_vw_BacklogPlanned AS
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
WHERE ri.Activo = 1;
GO
