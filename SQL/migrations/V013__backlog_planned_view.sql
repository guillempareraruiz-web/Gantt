-- ============================================================================
-- V013 - Vista Backlog planificado
--   Une FS_PL_Raw_* con FS_PL_Node/FS_PL_NodeData cuando existe un nodo
--   ligado por NumeroOF+SerieOF o NumeroPedido+SeriePedido.
--   Se utiliza en el tab 'Planificados' de la pantalla Backlog.
-- ============================================================================

IF OBJECT_ID('FS_PL_vw_BacklogPlanned', 'V') IS NOT NULL
    DROP VIEW FS_PL_vw_BacklogPlanned;
GO

CREATE VIEW FS_PL_vw_BacklogPlanned AS
-- OFs planificadas
SELECT
    CAST('OF' AS VARCHAR(10))         AS Origen,
    r.CodigoEmpresa,
    CAST(r.RawOFId AS BIGINT)         AS RawId,
    r.OrigenERP,
    r.ClaveERP,
    CONCAT(ISNULL(r.SerieOF,''), '-', ISNULL(CAST(r.NumeroOF AS NVARCHAR(20)),'')) AS CodigoDocumento,
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

-- Pedidos/Comandas planificadas
SELECT
    CAST('PEDIDO' AS VARCHAR(10))     AS Origen,
    c.CodigoEmpresa,
    CAST(c.RawComandaId AS BIGINT)    AS RawId,
    c.OrigenERP,
    c.ClaveERP,
    CONCAT(ISNULL(c.SeriePedido,''), '-', ISNULL(CAST(c.NumeroPedido AS NVARCHAR(20)),''),
           CASE WHEN c.LineaPedido IS NOT NULL THEN CONCAT('/', c.LineaPedido) ELSE '' END) AS CodigoDocumento,
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
