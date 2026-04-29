-- ============================================================================
-- V014 - Anadir SerieOF / SeriePedido a las vistas del Backlog para que
--        el commit de nodos pueda escribir esos campos a FS_PL_NodeData y
--        la vista 'Planificado' matchee correctamente.
-- ============================================================================

IF OBJECT_ID('FS_PL_vw_Backlog', 'V') IS NOT NULL
    DROP VIEW FS_PL_vw_Backlog;
GO

CREATE VIEW FS_PL_vw_Backlog AS
SELECT
    CAST('OF' AS VARCHAR(10))            AS Origen,
    r.CodigoEmpresa,
    CAST(r.RawOFId AS BIGINT)            AS RawId,
    r.OrigenERP,
    r.ClaveERP,
    CONCAT(ISNULL(r.SerieOF,''), '-', ISNULL(CAST(r.NumeroOF AS NVARCHAR(20)),'')) AS CodigoDocumento,
    r.NumeroOF                           AS NumeroDoc,
    r.SerieOF                            AS SerieDoc,
    r.CodigoArticulo,
    r.DescripcionArticulo,
    r.Cantidad,
    r.UnidadMedida,
    r.CodigoCliente,
    r.NombreCliente,
    r.CodigoProyecto,
    r.FechaCompromiso,
    r.FechaNecesaria,
    r.Prioridad,
    r.CentroPreferente,
    r.HorasEstimadas,
    r.EstadoERP,
    r.Observaciones,
    r.FechaImportacion
FROM FS_PL_Raw_OF r
WHERE r.Activo = 1
  AND NOT EXISTS (
        SELECT 1
        FROM FS_PL_NodeData nd
        WHERE nd.CodigoEmpresa = r.CodigoEmpresa
          AND nd.NumeroOF      = r.NumeroOF
          AND ISNULL(nd.SerieOF,'') = ISNULL(r.SerieOF,'')
      )
UNION ALL
SELECT
    CAST('PEDIDO' AS VARCHAR(10))        AS Origen,
    c.CodigoEmpresa,
    CAST(c.RawComandaId AS BIGINT)       AS RawId,
    c.OrigenERP,
    c.ClaveERP,
    CONCAT(ISNULL(c.SeriePedido,''), '-', ISNULL(CAST(c.NumeroPedido AS NVARCHAR(20)),''),
           CASE WHEN c.LineaPedido IS NOT NULL THEN CONCAT('/', c.LineaPedido) ELSE '' END) AS CodigoDocumento,
    c.NumeroPedido                       AS NumeroDoc,
    c.SeriePedido                        AS SerieDoc,
    c.CodigoArticulo,
    c.DescripcionArticulo,
    c.Cantidad,
    c.UnidadMedida,
    c.CodigoCliente,
    c.NombreCliente,
    c.CodigoProyecto,
    c.FechaCompromiso,
    c.FechaNecesaria,
    c.Prioridad,
    c.CentroPreferente,
    c.HorasEstimadas,
    c.EstadoERP,
    c.Observaciones,
    c.FechaImportacion
FROM FS_PL_Raw_Comanda c
WHERE c.Activo = 1
  AND NOT EXISTS (
        SELECT 1
        FROM FS_PL_NodeData nd
        WHERE nd.CodigoEmpresa  = c.CodigoEmpresa
          AND nd.NumeroPedido   = c.NumeroPedido
          AND ISNULL(nd.SeriePedido,'') = ISNULL(c.SeriePedido,'')
      )
UNION ALL
SELECT
    CAST('PROYECTO' AS VARCHAR(10))      AS Origen,
    p.CodigoEmpresa,
    CAST(p.RawProjecteId AS BIGINT)      AS RawId,
    p.OrigenERP,
    p.ClaveERP,
    ISNULL(p.CodigoProyecto, p.Nombre)   AS CodigoDocumento,
    NULL                                 AS NumeroDoc,
    NULL                                 AS SerieDoc,
    NULL                                 AS CodigoArticulo,
    p.Nombre                             AS DescripcionArticulo,
    NULL                                 AS Cantidad,
    NULL                                 AS UnidadMedida,
    p.CodigoCliente,
    p.NombreCliente,
    p.CodigoProyecto,
    p.FechaCompromiso,
    p.FechaNecesaria,
    p.Prioridad,
    p.CentroPreferente,
    p.HorasEstimadas,
    p.EstadoERP,
    p.Observaciones,
    p.FechaImportacion
FROM FS_PL_Raw_Projecte p
WHERE p.Activo = 1;
GO


IF OBJECT_ID('FS_PL_vw_BacklogPlanned', 'V') IS NOT NULL
    DROP VIEW FS_PL_vw_BacklogPlanned;
GO

CREATE VIEW FS_PL_vw_BacklogPlanned AS
SELECT
    CAST('OF' AS VARCHAR(10))         AS Origen,
    r.CodigoEmpresa,
    CAST(r.RawOFId AS BIGINT)         AS RawId,
    r.OrigenERP,
    r.ClaveERP,
    CONCAT(ISNULL(r.SerieOF,''), '-', ISNULL(CAST(r.NumeroOF AS NVARCHAR(20)),'')) AS CodigoDocumento,
    r.NumeroOF                        AS NumeroDoc,
    r.SerieOF                         AS SerieDoc,
    r.CodigoArticulo,
    r.DescripcionArticulo,
    r.Cantidad,
    r.UnidadMedida,
    r.CodigoCliente,
    r.NombreCliente,
    r.CodigoProyecto,
    r.FechaCompromiso,
    r.FechaNecesaria,
    r.Prioridad,
    r.CentroPreferente,
    r.HorasEstimadas,
    r.EstadoERP,
    r.Observaciones,
    r.FechaImportacion,
    n.NodeId            AS NodeId,
    n.ProjectId         AS ProjectId,
    n.FechaInicio       AS NodeInicio,
    n.FechaFin          AS NodeFin,
    n.DuracionMin       AS NodeDuracionMin,
    n.CenterId          AS NodeCenterId,
    cn.CodigoCentro     AS NodeCodigoCentro,
    cn.Titulo           AS NodeCentroNombre
FROM FS_PL_Raw_OF r
INNER JOIN FS_PL_NodeData nd
        ON nd.CodigoEmpresa = r.CodigoEmpresa
       AND nd.NumeroOF      = r.NumeroOF
       AND ISNULL(nd.SerieOF,'') = ISNULL(r.SerieOF,'')
INNER JOIN FS_PL_Node n
        ON n.CodigoEmpresa = nd.CodigoEmpresa
       AND n.NodeId        = nd.NodeId
LEFT JOIN FS_PL_Center cn
       ON cn.CodigoEmpresa = n.CodigoEmpresa
      AND cn.CenterId      = n.CenterId
WHERE r.Activo = 1

UNION ALL

SELECT
    CAST('PEDIDO' AS VARCHAR(10))     AS Origen,
    c.CodigoEmpresa,
    CAST(c.RawComandaId AS BIGINT)    AS RawId,
    c.OrigenERP,
    c.ClaveERP,
    CONCAT(ISNULL(c.SeriePedido,''), '-', ISNULL(CAST(c.NumeroPedido AS NVARCHAR(20)),''),
           CASE WHEN c.LineaPedido IS NOT NULL THEN CONCAT('/', c.LineaPedido) ELSE '' END) AS CodigoDocumento,
    c.NumeroPedido                    AS NumeroDoc,
    c.SeriePedido                     AS SerieDoc,
    c.CodigoArticulo,
    c.DescripcionArticulo,
    c.Cantidad,
    c.UnidadMedida,
    c.CodigoCliente,
    c.NombreCliente,
    c.CodigoProyecto,
    c.FechaCompromiso,
    c.FechaNecesaria,
    c.Prioridad,
    c.CentroPreferente,
    c.HorasEstimadas,
    c.EstadoERP,
    c.Observaciones,
    c.FechaImportacion,
    n.NodeId            AS NodeId,
    n.ProjectId         AS ProjectId,
    n.FechaInicio       AS NodeInicio,
    n.FechaFin          AS NodeFin,
    n.DuracionMin       AS NodeDuracionMin,
    n.CenterId          AS NodeCenterId,
    cn.CodigoCentro     AS NodeCodigoCentro,
    cn.Titulo           AS NodeCentroNombre
FROM FS_PL_Raw_Comanda c
INNER JOIN FS_PL_NodeData nd
        ON nd.CodigoEmpresa  = c.CodigoEmpresa
       AND nd.NumeroPedido   = c.NumeroPedido
       AND ISNULL(nd.SeriePedido,'') = ISNULL(c.SeriePedido,'')
INNER JOIN FS_PL_Node n
        ON n.CodigoEmpresa = nd.CodigoEmpresa
       AND n.NodeId        = nd.NodeId
LEFT JOIN FS_PL_Center cn
       ON cn.CodigoEmpresa = n.CodigoEmpresa
      AND cn.CenterId      = n.CenterId
WHERE c.Activo = 1;
GO
