-- ============================================================================
-- V018 - Vista FS_PL_vw_NodeGroupParent
--
--   Para cada FS_PL_Node (via FS_PL_NodeData.RawItemClaveERP/RawItemTipoOrigen)
--   devuelve la cadena de padres en el modelo unificado Raw_Item:
--     - Nivel1ClaveERP / Nivel1Nombre  -> cabecera (OF / PEDIDO / PROYECTO)
--     - Nivel2ClaveERP / Nivel2Nombre  -> sub-nivel (OT / LINEA / TAREA)
--     - Nivel3ClaveERP / Nivel3Nombre  -> hoja (OP), normalmente = item planificado
--
--   Usado por los controles de Gantt Mode GRUPO y TREE para agrupar/jerarquizar
--   nodos sin recalcular la cadena en codigo Delphi.
--
--   Si un nodo no esta lincado a Raw_Item (NodeData.RawItemClaveERP IS NULL),
--   la vista aun devuelve la fila con todos los niveles NULL, pero ese nodo
--   en los modos GRUPO/TREE cae en una fila especial "Sin agrupacion".
-- ============================================================================

IF OBJECT_ID('FS_PL_vw_NodeGroupParent', 'V') IS NOT NULL
    DROP VIEW FS_PL_vw_NodeGroupParent;
GO

CREATE VIEW FS_PL_vw_NodeGroupParent AS
SELECT
    nd.CodigoEmpresa,
    nd.NodeId,
    nd.RawItemClaveERP,
    nd.RawItemTipoOrigen,
    -- Item planificado (esperado Nivel 3 pero defensivo)
    ri3.RawItemId       AS Nivel3Id,
    ri3.ClaveERP        AS Nivel3ClaveERP,
    ri3.Nombre          AS Nivel3Nombre,
    ri3.Nivel           AS Nivel3Nivel,
    -- Padre (Nivel 2: OT / LINEA / TAREA)
    ri2.RawItemId       AS Nivel2Id,
    ri2.ClaveERP        AS Nivel2ClaveERP,
    ri2.Nombre          AS Nivel2Nombre,
    ri2.Codigo          AS Nivel2Codigo,
    ri2.LineaDoc        AS Nivel2LineaDoc,
    -- Abuelo (Nivel 1: OF / PEDIDO / PROYECTO)
    ri1.RawItemId       AS Nivel1Id,
    ri1.ClaveERP        AS Nivel1ClaveERP,
    ri1.Nombre          AS Nivel1Nombre,
    ri1.NumeroDoc       AS Nivel1NumeroDoc,
    ri1.SerieDoc        AS Nivel1SerieDoc,
    ri1.CodigoProyecto  AS Nivel1CodigoProyecto,
    -- Etiquetas sintéticas para mostrar en UI (caption de fila GRUPO)
    CASE
        WHEN ri1.TipoOrigen = 'OF '
            THEN CONCAT('OF ', ISNULL(ri1.SerieDoc,''), '-',
                        ISNULL(CAST(ri1.NumeroDoc AS NVARCHAR(20)),''))
        WHEN ri1.TipoOrigen = 'PED'
            THEN CONCAT('Pedido ', ISNULL(ri1.SerieDoc,''), '-',
                        ISNULL(CAST(ri1.NumeroDoc AS NVARCHAR(20)),''))
        WHEN ri1.TipoOrigen = 'PRJ'
            THEN CONCAT('Proyecto ',
                        ISNULL(ri1.CodigoProyecto, ri1.Nombre))
        ELSE ri1.ClaveERP
    END AS Nivel1Caption,
    CASE
        WHEN ri2.TipoOrigen = 'OF '
            THEN CONCAT('OT ', ISNULL(CAST(ri2.LineaDoc AS NVARCHAR(20)),''))
        WHEN ri2.TipoOrigen = 'PED'
            THEN CONCAT('Linea ', ISNULL(CAST(ri2.LineaDoc AS NVARCHAR(20)),''))
        WHEN ri2.TipoOrigen = 'PRJ'
            THEN CONCAT('Tarea ', COALESCE(ri2.Codigo, ri2.Nombre))
        ELSE ri2.ClaveERP
    END AS Nivel2Caption
FROM FS_PL_NodeData nd
LEFT JOIN FS_PL_Raw_Item ri3
    ON ri3.CodigoEmpresa     = nd.CodigoEmpresa
   AND ri3.TipoOrigen        = nd.RawItemTipoOrigen
   AND ri3.ClaveERP          = nd.RawItemClaveERP
LEFT JOIN FS_PL_Raw_Item ri2
    ON ri2.CodigoEmpresa     = ri3.CodigoEmpresa
   AND ri2.RawItemId         = ri3.ParentRawItemId
LEFT JOIN FS_PL_Raw_Item ri1
    ON ri1.CodigoEmpresa     = ri2.CodigoEmpresa
   AND ri1.RawItemId         = ri2.ParentRawItemId;
GO
