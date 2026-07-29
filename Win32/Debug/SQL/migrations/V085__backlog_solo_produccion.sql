-- ===========================================================================
-- V085 - El Backlog pasa a ser SOLO PRODUCCION: fuera la familia 'PRJ'.
--
-- DECISION (2026-07-29): el Backlog es la bandeja de entrada de PRODUCCION
-- (OF y PEDIDOS). Los proyectos se planifican EXCLUSIVAMENTE en el modulo de
-- Ingenieria (paradigma TAREAS, WBS sobre FS_PL_Node), donde hoy las tareas se
-- crean manualmente.
--
-- MOTIVO: 'PRJ' en el Backlog NO es un WBS. Es un arbol documental de 3 niveles
-- (PROYECTO > TAREA > OP) con la misma forma que una OF, que acaba obligatoria-
-- mente en OPs planificables a maquina. No tiene ParentTaskId, ni profundidad
-- arbitraria, ni dependencias (FS_PL_Dependency), ni esfuerzo, ni CPM. Mantener
-- las dos cosas llamandolas igual hacia que la palabra TAREA significase dos
-- cosas distintas segun la pantalla. Tras esta migracion, TAREA = tarea WBS de
-- Ingenieria en todo el producto.
--
-- QUE SE CONSERVA (ingesta intacta, para el futuro puente ERP -> WBS):
--   - FS_PL_Raw_Item.TipoOrigen sigue admitiendo 'PRJ' (CHECK de V016 intacto).
--   - El lector de Sage (Proyectos / LcProyectoTareas) y el staging siguen
--     importando proyectos: los datos siguen entrando en FS_PL_Raw_Item.
--   - El MERGE de staging -> Raw_Item de V016 queda como esta.
-- Lo unico que cambia es que las 4 vistas del Backlog dejan de EXPONERLOS.
--
-- QUE CAMBIA: las 4 vistas se reemiten identicas a su ultima version, con 2
-- unicas diferencias:
--   1) Se eliminan los brazos 'PRJ' de los CASE Origen y CodigoDocumento.
--   2) Se aniade el predicado de familia: TipoOrigen IN ('OF ','PED').
--
-- Cuerpos copiados literalmente de: V053 (vw_Backlog), V067 (vw_BacklogPlanned,
-- que sustituyo a la de V053 aniadiendo la rama MANUAL), V055 (vw_BacklogTree),
-- V056 (vw_BacklogPlannedTree). La rama MANUAL (Source='MAN') de V067 no toca
-- Raw_Item y queda intacta.
--
-- Jerarquia regular verificada en V055 (N3 -> N2 -> N1, ninguna OP cuelga
-- directa de una OF) y agregados por joins directos por nivel, NO recursivos:
-- por eso basta con filtrar la familia en el origen de cada CTE y en el SELECT
-- final; no quedan hijos huerfanos de un padre excluido.
--
-- ADEMAS, esta migracion cierra dos agujeros de las ramas MANUAL (Source='MAN'):
--
--   a) Nodos manuales invisibles a Nivel 1/2. V067 aniadio la rama MANUAL a
--      FS_PL_vw_BacklogPlanned pero NO a FS_PL_vw_BacklogPlannedTree, que se
--      construye solo desde Raw_Item. Un nodo manual se veia en el tab
--      Planificados a Nivel 3 y desaparecia al pasar a Nivel 1 o 2. Ahora la
--      vista de arbol tiene su propia rama MANUAL, visible en los 3 niveles.
--
--   b) Tareas de Ingenieria coladas en el Backlog. Una tarea WBS tambien es un
--      nodo Source='MAN'; sin filtrar por paradigma, el Backlog mostraba el WBS
--      de un plan TAREAS como si fuese carga de produccion. Las dos ramas
--      MANUAL exigen ahora FS_PL_Project.PlanningParadigm = 'RECURSOS'.
--      (Verificado en la BD de desarrollo: 56 de los 57 nodos manuales eran
--      tareas WBS de planes TAREAS.)
--
-- NOTA: no hay datos que migrar. Ningun cliente tiene el Planner en produccion,
-- luego no existen filas PRJ reales ni nodos planificados a partir de ellas.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ===========================================================================
-- 1) FS_PL_vw_Backlog  (base: V053, solo leafs sin node)
-- ===========================================================================
IF OBJECT_ID('FS_PL_vw_Backlog', 'V') IS NOT NULL DROP VIEW FS_PL_vw_Backlog;
GO

CREATE VIEW FS_PL_vw_Backlog AS
WITH Leafs AS (
    SELECT ri.*
    FROM FS_PL_Raw_Item ri
    WHERE ri.Activo = 1
      AND ri.TipoOrigen IN ('OF ', 'PED')      -- V085: Backlog = solo produccion
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
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'OF ' THEN 'OF'
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'PED' THEN 'PEDIDO'
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


-- ===========================================================================
-- 2) FS_PL_vw_BacklogPlanned  (base: V067 = rama ERP de V053 + rama MANUAL)
-- ===========================================================================
IF OBJECT_ID('FS_PL_vw_BacklogPlanned', 'V') IS NOT NULL DROP VIEW FS_PL_vw_BacklogPlanned;
GO

CREATE VIEW FS_PL_vw_BacklogPlanned AS
-- ===== Rama ERP ============================================================
SELECT
    CAST(
        CASE
            WHEN ri.Nivel = 3 THEN 'OP'
            WHEN ri.Nivel = 2 AND ri.TipoOrigen = 'OF ' THEN 'OT'
            WHEN ri.Nivel = 2 AND ri.TipoOrigen = 'PED' THEN 'LINEA'
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'OF ' THEN 'OF'
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'PED' THEN 'PEDIDO'
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
  AND ri.TipoOrigen IN ('OF ', 'PED')          -- V085: Backlog = solo produccion

UNION ALL

-- ===== Rama MANUAL (V067): nodos Source='MAN', sin Raw_Item ==================
-- Intacta: no pasa por Raw_Item, luego no le afecta el filtro de familia.
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
-- V085: solo nodos de planes de PRODUCCION. Una tarea WBS del modulo de
-- Ingenieria tambien es un nodo Source='MAN', y sin este filtro el Backlog
-- mostraba el WBS de un proyecto TAREAS como si fuese carga de produccion.
INNER JOIN FS_PL_Project pr
    ON pr.CodigoEmpresa = n.CodigoEmpresa AND pr.ProjectId = n.ProjectId
   AND pr.PlanningParadigm = 'RECURSOS'
WHERE n.Source = 'MAN';
GO


-- ===========================================================================
-- 3) FS_PL_vw_BacklogTree  (base: V055, multinivel con prevision agregada)
--
-- El filtro de familia se aplica en los 3 sitios que leen Raw_Item: OpsPend,
-- OpsAll y Agg. Al ser joins directos por nivel (no recursion), excluir la
-- familia en el origen basta: una OP de PRJ no entra en OpsAll/OpsPend, y su
-- OT/PRJ padre no entra en Agg, luego no puede quedar ningun huerfano.
-- ===========================================================================
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
      AND op.TipoOrigen IN ('OF ', 'PED')      -- V085: Backlog = solo produccion
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
      AND op.TipoOrigen IN ('OF ', 'PED')      -- V085: Backlog = solo produccion
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
      AND n.TipoOrigen IN ('OF ', 'PED')       -- V085: Backlog = solo produccion
    GROUP BY n.CodigoEmpresa, n.RawItemId
)
SELECT
    CAST(
        CASE
            WHEN ri.Nivel = 3 THEN 'OP'
            WHEN ri.Nivel = 2 AND ri.TipoOrigen = 'OF ' THEN 'OT'
            WHEN ri.Nivel = 2 AND ri.TipoOrigen = 'PED' THEN 'LINEA'
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'OF ' THEN 'OF'
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'PED' THEN 'PEDIDO'
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
  AND ri.TipoOrigen IN ('OF ', 'PED')          -- V085: Backlog = solo produccion
  -- Solo nodos con al menos una OP descendiente pendiente (algo que planificar).
  AND ag.NumOpsPendientes > 0;
GO


-- ===========================================================================
-- 4) FS_PL_vw_BacklogPlannedTree  (base: V056, multinivel de planificados)
-- ===========================================================================
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
      AND op.TipoOrigen IN ('OF ', 'PED')      -- V085: Backlog = solo produccion
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
      AND node.TipoOrigen IN ('OF ', 'PED')    -- V085: Backlog = solo produccion
    GROUP BY node.CodigoEmpresa, node.RawItemId
)
SELECT
    CAST(
        CASE
            WHEN ri.Nivel = 3 THEN 'OP'
            WHEN ri.Nivel = 2 AND ri.TipoOrigen = 'OF ' THEN 'OT'
            WHEN ri.Nivel = 2 AND ri.TipoOrigen = 'PED' THEN 'LINEA'
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'OF ' THEN 'OF'
            WHEN ri.Nivel = 1 AND ri.TipoOrigen = 'PED' THEN 'PEDIDO'
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
  AND ri.TipoOrigen IN ('OF ', 'PED')          -- V085: Backlog = solo produccion

UNION ALL

-- ===== Rama MANUAL (V085): nodos Source='MAN', sin Raw_Item =================
-- V067 aniadio los nodos manuales a FS_PL_vw_BacklogPlanned (plana) pero NO a
-- esta vista de arbol, que se construye solo desde FS_PL_Raw_Item. Resultado: un
-- nodo manual se veia en el tab Planificados a Nivel 3 (OP) y desaparecia al
-- pasar a Nivel 1 o 2, sin motivo visible para el usuario.
--
-- Un nodo manual no tiene documento padre: no cuelga de ninguna OF/OT. Por eso
-- se expone como fila raiz en CUALQUIER nivel de vista. El llamador filtra por
-- 'b.Nivel = <NivelVista>' (uBacklog.pas), asi que la fila se emite tres veces,
-- una por nivel, y solo aparece la del nivel pedido. Los agregados de progreso
-- valen 1/1 en un solo centro: el nodo ES la unidad de trabajo completa.
SELECT
    CAST('MANUAL' AS VARCHAR(10))            AS Origen,
    n.CodigoEmpresa,
    CAST(NULL AS BIGINT)                     AS RawId,
    CAST(NULL AS CHAR(3))                     AS TipoOrigen,
    CAST(lv.Nivel AS TINYINT)                 AS Nivel,   -- 1, 2 y 3: siempre visible
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
    n.NodeId                                  AS NodeId,
    n.ProjectId                               AS ProjectId,
    n.FechaInicio                             AS NodeInicio,
    n.FechaFin                                AS NodeFin,
    CAST(n.DuracionMin AS FLOAT)              AS NodeDuracionMin,
    n.CenterId                                AS NodeCenterId,
    cn.CodigoCentro                           AS NodeCodigoCentro,
    cn.Titulo                                 AS NodeCentroNombre,
    -- Agregados de progreso: el nodo manual es 1 unidad ya planificada.
    CAST(1 AS INT)                            AS NumOpsPlan,
    CAST(1 AS INT)                            AS NumOpsTotal,
    CAST(CASE WHEN n.CenterId IS NULL THEN 0 ELSE 1 END AS INT) AS NumCentros
FROM FS_PL_Node n
INNER JOIN FS_PL_NodeData nd
    ON nd.CodigoEmpresa = n.CodigoEmpresa AND nd.NodeId = n.NodeId
LEFT JOIN FS_PL_Center cn
    ON cn.CodigoEmpresa = n.CodigoEmpresa AND cn.CenterId = n.CenterId
-- V085: solo planes de PRODUCCION (ver nota en la rama MANUAL de la vista plana).
INNER JOIN FS_PL_Project pr
    ON pr.CodigoEmpresa = n.CodigoEmpresa AND pr.ProjectId = n.ProjectId
   AND pr.PlanningParadigm = 'RECURSOS'
CROSS JOIN (VALUES (1), (2), (3)) AS lv(Nivel)
WHERE n.Source = 'MAN';
GO
