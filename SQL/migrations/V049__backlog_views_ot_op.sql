-- ===========================================================================
-- V049 - FS_PL_vw_Backlog / FS_PL_vw_BacklogPlanned: exposar CodigoOT i CodigoOP
--        como columnas propias, para poder mostrarlas en el grid del Backlog.
--
-- Mapeo (familia OF: Nivel 1 = OF, Nivel 2 = OT, Nivel 3 = OP):
--   CodigoOP = Codigo del propio leaf cuando es Nivel 3 (la operacion).
--   CodigoOT = Codigo del padre (p1) cuando el leaf es Nivel 3; si el leaf ya
--              es Nivel 2, su propio Codigo.
--   FechaEntrega = FechaCompromiso (es donde el staging guarda la fecha de
--                  entrega del cliente). Se expone con alias explicito.
--
-- Reescribe ambas vistas a partir de V048 (sin otros cambios).
-- ===========================================================================

SET NOCOUNT ON;
GO

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
    -- Codigo de la OP (operacion): solo si el leaf es Nivel 3.
    CASE WHEN ri.Nivel = 3 THEN ri.Codigo ELSE NULL END                          AS CodigoOP,
    -- Codigo de la OT (nivel 2): del padre si el leaf es Nivel 3; del propio si
    -- el leaf ya es Nivel 2.
    CASE
        WHEN ri.Nivel = 3 THEN p1.Codigo
        WHEN ri.Nivel = 2 THEN ri.Codigo
        ELSE NULL
    END                                                                           AS CodigoOT,
    COALESCE(ri.NumeroDoc, p1.NumeroDoc, p2.NumeroDoc)                            AS NumeroDoc,
    COALESCE(ri.SerieDoc,  p1.SerieDoc,  p2.SerieDoc)                             AS SerieDoc,
    COALESCE(ri.LineaDoc,  p1.LineaDoc,  p2.LineaDoc)                             AS LineaDoc,
    COALESCE(ri.CodigoArticulo, p1.CodigoArticulo, p2.CodigoArticulo)             AS CodigoArticulo,
    COALESCE(ri.DescripcionArticulo, ri.Nombre, ri.Descripcion,
             p1.DescripcionArticulo, p2.DescripcionArticulo)                      AS DescripcionArticulo,
    COALESCE(ri.Cantidad, p1.Cantidad, p2.Cantidad)                               AS Cantidad,
    COALESCE(ri.UnidadMedida, p1.UnidadMedida, p2.UnidadMedida)                   AS UnidadMedida,
    COALESCE(ri.CodigoCliente, p1.CodigoCliente, p2.CodigoCliente)                AS CodigoCliente,
    COALESCE(ri.NombreCliente, p1.NombreCliente, p2.NombreCliente)                AS NombreCliente,
    COALESCE(ri.CodigoProyecto, p1.CodigoProyecto, p2.CodigoProyecto)             AS CodigoProyecto,
    COALESCE(ri.FechaCompromiso, p1.FechaCompromiso, p2.FechaCompromiso)          AS FechaCompromiso,
    COALESCE(ri.FechaNecesaria, p1.FechaNecesaria, p2.FechaNecesaria)             AS FechaNecesaria,
    -- Fecha de entrega = FechaCompromiso (alias explicito para la columna).
    COALESCE(ri.FechaCompromiso, p1.FechaCompromiso, p2.FechaCompromiso)          AS FechaEntrega,
    COALESCE(ri.Prioridad, p1.Prioridad, p2.Prioridad)                            AS Prioridad,
    COALESCE(ri.CentroPreferente, p1.CentroPreferente, p2.CentroPreferente)       AS CentroPreferente,
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
    CASE WHEN ri.Nivel = 3 THEN ri.Codigo ELSE NULL END                          AS CodigoOP,
    CASE
        WHEN ri.Nivel = 3 THEN p1.Codigo
        WHEN ri.Nivel = 2 THEN ri.Codigo
        ELSE NULL
    END                                                                           AS CodigoOT,
    COALESCE(ri.NumeroDoc, p1.NumeroDoc, p2.NumeroDoc)                            AS NumeroDoc,
    COALESCE(ri.SerieDoc,  p1.SerieDoc,  p2.SerieDoc)                             AS SerieDoc,
    COALESCE(ri.LineaDoc,  p1.LineaDoc,  p2.LineaDoc)                             AS LineaDoc,
    COALESCE(ri.CodigoArticulo, p1.CodigoArticulo, p2.CodigoArticulo)             AS CodigoArticulo,
    COALESCE(ri.DescripcionArticulo, ri.Nombre, ri.Descripcion,
             p1.DescripcionArticulo, p2.DescripcionArticulo)                      AS DescripcionArticulo,
    COALESCE(ri.Cantidad, p1.Cantidad, p2.Cantidad)                               AS Cantidad,
    COALESCE(ri.UnidadMedida, p1.UnidadMedida, p2.UnidadMedida)                   AS UnidadMedida,
    COALESCE(ri.CodigoCliente, p1.CodigoCliente, p2.CodigoCliente)                AS CodigoCliente,
    COALESCE(ri.NombreCliente, p1.NombreCliente, p2.NombreCliente)                AS NombreCliente,
    COALESCE(ri.CodigoProyecto, p1.CodigoProyecto, p2.CodigoProyecto)             AS CodigoProyecto,
    COALESCE(ri.FechaCompromiso, p1.FechaCompromiso, p2.FechaCompromiso)          AS FechaCompromiso,
    COALESCE(ri.FechaNecesaria, p1.FechaNecesaria, p2.FechaNecesaria)             AS FechaNecesaria,
    COALESCE(ri.FechaCompromiso, p1.FechaCompromiso, p2.FechaCompromiso)          AS FechaEntrega,
    COALESCE(ri.Prioridad, p1.Prioridad, p2.Prioridad)                            AS Prioridad,
    COALESCE(ri.CentroPreferente, p1.CentroPreferente, p2.CentroPreferente)       AS CentroPreferente,
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
