-- ============================================================================
-- V012 - Vista Backlog - valores de Origen en castellano
--   OF / COMANDA / PROJECTE  ->  OF / PEDIDO / PROYECTO
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
