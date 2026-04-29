-- ============================================================================
-- V016 - Modelo unificado de staging: FS_PL_Raw_Item (jerarquia 3 niveles)
--
--   Sustituye logicamente las 3 tablas FS_PL_Raw_OF/Raw_Comanda/Raw_Projecte
--   por una unica jerarquia con 3 familias y 3 niveles:
--
--     Familia       Nivel 1       Nivel 2    Nivel 3
--     ----------    ----------    --------   --------
--     Fabricacion   OF            OT         OP
--     Venta         PEDIDO        LINEA      OP
--     Cliente       PROJECTE      TAREA      OP
--
--   Principios del modelo:
--     - Los nodos del Gantt (FS_PL_Node) SOLO se lincan a items de Nivel=3 (OP).
--       Cuando el ERP no explosiona operaciones, los connectors crean una OP
--       sintetica con las horas agregadas del padre.
--     - Nivel 1 y 2 son contenedores puros para agrupacion visual en el Gantt.
--     - CodigoArticulo: vive en Nivel 2 (OT hereda de OF; linea tiene articulo
--       propio; tarea puede tenerlo o no). Nivel 3 (OP) NO tiene articulo.
--     - HorasEstimadas planificables: se usan SIEMPRE las del Nivel 3 (OP).
--
--   IMPORTANTE - desambiguacion "PROYECTO":
--     - TipoOrigen='PRJ' se refiere al PROYECTO ERP DEL CLIENTE, es decir una
--       entidad de negocio (un encargo complejo con tareas) que viene del ERP
--       al staging para ser planificada.
--     - NO confundir con FS_PL_Project (CurrentProjectId), que es el CONTENEDOR
--       DE PLANIFICACION del FSPlanner ("Plan MASTER") donde se pintan los
--       nodos del Gantt. Un FS_PL_Project puede contener nodos de OF, Pedido
--       y Projecte (ERP) mezclados.
--
--   Compatibilidad:
--     - Las 3 tablas antiguas NO se eliminan. Triggers AFTER INSERT/UPDATE/
--       DELETE sincronizan cabeceras (Nivel=1) de las tablas viejas hacia
--       Raw_Item, para que uDemoBacklog.pas y demas codigo que inserta en
--       Raw_OF/Raw_Comanda/Raw_Projecte siga funcionando.
--     - Fase 5 refactorizara el codigo Delphi para escribir directamente en
--       Raw_Item, y una futura V017 dropeara triggers + tablas viejas.
--
--   Nuevos campos en FS_PL_NodeData:
--     - RawItemClaveERP    link fuerte del nodo al item (Nivel 3) planificado.
--     - RawItemTipoOrigen  'OF '/'PED'/'PRJ' (char(3)).
--
--   Nuevas vistas:
--     - FS_PL_vw_Backlog          (pendientes, muestra OPs no planificadas)
--     - FS_PL_vw_BacklogPlanned   (planificados, OPs con nodo)
-- ============================================================================


-- ---------------------------------------------------------------------------
-- 1. FS_PL_Raw_Item - tabla unificada jerarquica (3 familias x 3 niveles)
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Raw_Item')
CREATE TABLE FS_PL_Raw_Item (
    CodigoEmpresa       SMALLINT       NOT NULL,
    RawItemId           BIGINT IDENTITY(1,1) NOT NULL,
    TipoOrigen          CHAR(3)        NOT NULL,    -- 'OF ','PED','PRJ' (familia)
    Nivel               TINYINT        NOT NULL,    -- 1=cabecera 2=sub 3=operacion
    ParentRawItemId     BIGINT         NULL,        -- self-FK (NULL solo en Nivel=1)
    OrigenERP           NVARCHAR(30)   NOT NULL,    -- 'SAGE200','DEMO',...
    ClaveERP            NVARCHAR(100)  NOT NULL,    -- unica dentro de (CE, TipoOrigen)
    ClaveERPPadre       NVARCHAR(100)  NULL,        -- ClaveERP del padre (denormalizado)

    -- Identificadores ERP humanos (usados por vistas de compat y joins)
    NumeroDoc           INT            NULL,        -- NumeroOF / NumeroPedido
    SerieDoc            NVARCHAR(20)   NULL,        -- SerieOF / SeriePedido
    LineaDoc            INT            NULL,        -- LineaPedido / numero OT / numero tarea
    CodigoProyecto      NVARCHAR(50)   NULL,        -- codigo agrupador (si aplica)

    -- Descripcion del item
    Codigo              NVARCHAR(50)   NULL,        -- codigo interno (OT/Tarea/OP)
    Nombre              NVARCHAR(255)  NULL,
    Descripcion         NVARCHAR(MAX)  NULL,

    -- Articulo (Nivel 2 tipicamente; Nivel 1 para OF sin OTs; NULL para
    -- proyectos/tareas puras y para OPs de Nivel 3)
    CodigoArticulo      NVARCHAR(50)   NULL,
    DescripcionArticulo NVARCHAR(500)  NULL,
    Cantidad            DECIMAL(18,4)  NULL,
    UnidadMedida        NVARCHAR(20)   NULL,

    -- Cliente
    CodigoCliente       NVARCHAR(50)   NULL,
    NombreCliente       NVARCHAR(200)  NULL,

    -- Planning hints
    FechaCompromiso     DATETIME2      NULL,
    FechaNecesaria      DATETIME2      NULL,
    FechaInicioPrev     DATETIME2      NULL,
    FechaFinPrev        DATETIME2      NULL,
    FechaLanzamiento    DATETIME2      NULL,
    FechaPedido         DATETIME2      NULL,
    Prioridad           INT            NULL,
    Orden               INT            NULL,        -- orden dentro del padre
    CentroPreferente    NVARCHAR(30)   NULL,
    HorasEstimadas      DECIMAL(12,2)  NULL,        -- en Nivel 3 = horas planificables
    EstadoERP           NVARCHAR(30)   NULL,
    Observaciones       NVARCHAR(MAX)  NULL,

    FechaImportacion    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    Activo              BIT            NOT NULL DEFAULT 1,

    CONSTRAINT PK_FS_PL_Raw_Item PRIMARY KEY (CodigoEmpresa, RawItemId),
    CONSTRAINT UQ_FS_PL_Raw_Item_Clave UNIQUE (CodigoEmpresa, TipoOrigen, ClaveERP),
    CONSTRAINT CK_FS_PL_Raw_Item_TipoOrigen CHECK (TipoOrigen IN ('OF ','PED','PRJ')),
    CONSTRAINT CK_FS_PL_Raw_Item_Nivel CHECK (Nivel BETWEEN 1 AND 3),
    CONSTRAINT FK_FS_PL_Raw_Item_Parent FOREIGN KEY (CodigoEmpresa, ParentRawItemId)
        REFERENCES FS_PL_Raw_Item (CodigoEmpresa, RawItemId)
);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FS_PL_Raw_Item_Parent')
    CREATE INDEX IX_FS_PL_Raw_Item_Parent
        ON FS_PL_Raw_Item (CodigoEmpresa, ParentRawItemId)
        WHERE ParentRawItemId IS NOT NULL;
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FS_PL_Raw_Item_Tipo')
    CREATE INDEX IX_FS_PL_Raw_Item_Tipo
        ON FS_PL_Raw_Item (CodigoEmpresa, TipoOrigen, Nivel, Activo);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FS_PL_Raw_Item_NumSerie')
    CREATE INDEX IX_FS_PL_Raw_Item_NumSerie
        ON FS_PL_Raw_Item (CodigoEmpresa, TipoOrigen, NumeroDoc, SerieDoc);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FS_PL_Raw_Item_CodProyecto')
    CREATE INDEX IX_FS_PL_Raw_Item_CodProyecto
        ON FS_PL_Raw_Item (CodigoEmpresa, CodigoProyecto)
        WHERE CodigoProyecto IS NOT NULL;
GO


-- ---------------------------------------------------------------------------
-- 2. FS_PL_Raw_Item_Extra - campos custom key/value unificados
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Raw_Item_Extra')
CREATE TABLE FS_PL_Raw_Item_Extra (
    CodigoEmpresa   SMALLINT       NOT NULL,
    RawItemId       BIGINT         NOT NULL,
    FieldKey        VARCHAR(64)    NOT NULL,
    FieldValue      NVARCHAR(1000) NULL,
    FieldType       CHAR(1)        NOT NULL,        -- 'S','N','D','B'
    CONSTRAINT PK_FS_PL_Raw_Item_Extra PRIMARY KEY (CodigoEmpresa, RawItemId, FieldKey),
    CONSTRAINT FK_FS_PL_Raw_Item_Extra_Item FOREIGN KEY (CodigoEmpresa, RawItemId)
        REFERENCES FS_PL_Raw_Item (CodigoEmpresa, RawItemId) ON DELETE CASCADE
);
GO


-- ---------------------------------------------------------------------------
-- 3. FS_PL_Raw_Item_Dep - dependencias entre items hermanos (tipicamente entre
--    OPs del mismo OT/linea/tarea). Descriptivas (vienen del ERP o del
--    escandallo). Independientes de FS_PL_Dependency, que opera entre nodos
--    planificados del Plan.
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Raw_Item_Dep')
CREATE TABLE FS_PL_Raw_Item_Dep (
    CodigoEmpresa    SMALLINT       NOT NULL,
    RawItemDepId     BIGINT IDENTITY(1,1) NOT NULL,
    FromRawItemId    BIGINT         NOT NULL,
    ToRawItemId      BIGINT         NOT NULL,
    TipoLink         TINYINT        NOT NULL DEFAULT 0,  -- 0=FS 1=SS 2=FF 3=SF
    PorcentajeDependencia INT       NOT NULL DEFAULT 100,
    Activo           BIT            NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Raw_Item_Dep PRIMARY KEY (CodigoEmpresa, RawItemDepId),
    CONSTRAINT UQ_FS_PL_Raw_Item_Dep UNIQUE (CodigoEmpresa, FromRawItemId, ToRawItemId),
    CONSTRAINT FK_FS_PL_Raw_Item_Dep_From FOREIGN KEY (CodigoEmpresa, FromRawItemId)
        REFERENCES FS_PL_Raw_Item (CodigoEmpresa, RawItemId),
    CONSTRAINT FK_FS_PL_Raw_Item_Dep_To FOREIGN KEY (CodigoEmpresa, ToRawItemId)
        REFERENCES FS_PL_Raw_Item (CodigoEmpresa, RawItemId)
);
GO


-- ---------------------------------------------------------------------------
-- 4. FS_PL_NodeData - nuevos campos para lincar nodo -> Raw_Item (Nivel 3)
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.columns
               WHERE object_id = OBJECT_ID('FS_PL_NodeData')
                 AND name = 'RawItemClaveERP')
    ALTER TABLE FS_PL_NodeData ADD RawItemClaveERP NVARCHAR(100) NULL;
GO

IF NOT EXISTS (SELECT * FROM sys.columns
               WHERE object_id = OBJECT_ID('FS_PL_NodeData')
                 AND name = 'RawItemTipoOrigen')
    ALTER TABLE FS_PL_NodeData ADD RawItemTipoOrigen CHAR(3) NULL;
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FS_PL_NodeData_RawItem')
    CREATE INDEX IX_FS_PL_NodeData_RawItem
        ON FS_PL_NodeData (CodigoEmpresa, RawItemTipoOrigen, RawItemClaveERP)
        WHERE RawItemClaveERP IS NOT NULL;
GO


-- ---------------------------------------------------------------------------
-- 5. Carga inicial desde las 3 tablas antiguas a Raw_Item (idempotente)
--    - Cabeceras como Nivel=1 (OF/PEDIDO/PROJECTE).
--    - No se crean Nivel 2 ni 3 aqui: el esquema anterior no tenia esas
--      entidades. Seran los generadores demo / connectors ERP quienes las
--      crearan. El codigo existente que solo ve el Nivel 1 sigue funcionando.
-- ---------------------------------------------------------------------------
MERGE FS_PL_Raw_Item AS T
USING (
    SELECT
        r.CodigoEmpresa,
        'OF ' AS TipoOrigen, 1 AS Nivel,
        r.OrigenERP, r.ClaveERP,
        r.NumeroOF AS NumeroDoc, r.SerieOF AS SerieDoc, NULL AS LineaDoc,
        r.CodigoProyecto,
        NULL AS Codigo,
        r.DescripcionArticulo AS Nombre,
        NULL AS Descripcion,
        r.CodigoArticulo, r.DescripcionArticulo, r.Cantidad, r.UnidadMedida,
        r.CodigoCliente, r.NombreCliente,
        r.FechaCompromiso, r.FechaNecesaria, NULL AS FechaInicioPrev, NULL AS FechaFinPrev,
        r.FechaLanzamiento, NULL AS FechaPedido,
        r.Prioridad, NULL AS Orden,
        r.CentroPreferente, r.HorasEstimadas, r.EstadoERP, r.Observaciones,
        r.FechaImportacion, r.Activo
    FROM FS_PL_Raw_OF r
    UNION ALL
    SELECT
        c.CodigoEmpresa,
        'PED', 1,
        c.OrigenERP, c.ClaveERP,
        c.NumeroPedido, c.SeriePedido, c.LineaPedido,
        c.CodigoProyecto,
        NULL, c.DescripcionArticulo, NULL,
        c.CodigoArticulo, c.DescripcionArticulo, c.Cantidad, c.UnidadMedida,
        c.CodigoCliente, c.NombreCliente,
        c.FechaCompromiso, c.FechaNecesaria, NULL, NULL,
        NULL, c.FechaPedido,
        c.Prioridad, NULL,
        c.CentroPreferente, c.HorasEstimadas, c.EstadoERP, c.Observaciones,
        c.FechaImportacion, c.Activo
    FROM FS_PL_Raw_Comanda c
    UNION ALL
    SELECT
        p.CodigoEmpresa,
        'PRJ', 1,
        p.OrigenERP, p.ClaveERP,
        NULL, NULL, NULL,
        p.CodigoProyecto,
        p.CodigoProyecto, p.Nombre, p.Descripcion,
        NULL, NULL, NULL, NULL,
        p.CodigoCliente, p.NombreCliente,
        p.FechaCompromiso, p.FechaNecesaria, p.FechaInicio, NULL,
        NULL, NULL,
        p.Prioridad, NULL,
        p.CentroPreferente, p.HorasEstimadas, p.EstadoERP, p.Observaciones,
        p.FechaImportacion, p.Activo
    FROM FS_PL_Raw_Projecte p
) AS S
ON  T.CodigoEmpresa = S.CodigoEmpresa
AND T.TipoOrigen    = S.TipoOrigen
AND T.ClaveERP      = S.ClaveERP
WHEN NOT MATCHED THEN
    INSERT (CodigoEmpresa, TipoOrigen, Nivel, OrigenERP, ClaveERP,
            NumeroDoc, SerieDoc, LineaDoc, CodigoProyecto,
            Codigo, Nombre, Descripcion,
            CodigoArticulo, DescripcionArticulo, Cantidad, UnidadMedida,
            CodigoCliente, NombreCliente,
            FechaCompromiso, FechaNecesaria, FechaInicioPrev, FechaFinPrev,
            FechaLanzamiento, FechaPedido,
            Prioridad, Orden, CentroPreferente, HorasEstimadas,
            EstadoERP, Observaciones, FechaImportacion, Activo)
    VALUES (S.CodigoEmpresa, S.TipoOrigen, S.Nivel, S.OrigenERP, S.ClaveERP,
            S.NumeroDoc, S.SerieDoc, S.LineaDoc, S.CodigoProyecto,
            S.Codigo, S.Nombre, S.Descripcion,
            S.CodigoArticulo, S.DescripcionArticulo, S.Cantidad, S.UnidadMedida,
            S.CodigoCliente, S.NombreCliente,
            S.FechaCompromiso, S.FechaNecesaria, S.FechaInicioPrev, S.FechaFinPrev,
            S.FechaLanzamiento, S.FechaPedido,
            S.Prioridad, S.Orden, S.CentroPreferente, S.HorasEstimadas,
            S.EstadoERP, S.Observaciones, S.FechaImportacion, S.Activo);
GO


-- ---------------------------------------------------------------------------
-- 6. Carga inicial de Extras (OF/Comanda/Projecte -> Raw_Item_Extra)
-- ---------------------------------------------------------------------------
INSERT INTO FS_PL_Raw_Item_Extra (CodigoEmpresa, RawItemId, FieldKey, FieldValue, FieldType)
SELECT ri.CodigoEmpresa, ri.RawItemId, e.FieldKey, e.FieldValue, e.FieldType
FROM FS_PL_Raw_OF_Extra e
INNER JOIN FS_PL_Raw_OF r
    ON r.CodigoEmpresa = e.CodigoEmpresa AND r.RawOFId = e.RawOFId
INNER JOIN FS_PL_Raw_Item ri
    ON ri.CodigoEmpresa = r.CodigoEmpresa
   AND ri.TipoOrigen    = 'OF '
   AND ri.ClaveERP      = r.ClaveERP
WHERE NOT EXISTS (
    SELECT 1 FROM FS_PL_Raw_Item_Extra ie
    WHERE ie.CodigoEmpresa = ri.CodigoEmpresa
      AND ie.RawItemId     = ri.RawItemId
      AND ie.FieldKey      = e.FieldKey);
GO

INSERT INTO FS_PL_Raw_Item_Extra (CodigoEmpresa, RawItemId, FieldKey, FieldValue, FieldType)
SELECT ri.CodigoEmpresa, ri.RawItemId, e.FieldKey, e.FieldValue, e.FieldType
FROM FS_PL_Raw_Comanda_Extra e
INNER JOIN FS_PL_Raw_Comanda c
    ON c.CodigoEmpresa = e.CodigoEmpresa AND c.RawComandaId = e.RawComandaId
INNER JOIN FS_PL_Raw_Item ri
    ON ri.CodigoEmpresa = c.CodigoEmpresa
   AND ri.TipoOrigen    = 'PED'
   AND ri.ClaveERP      = c.ClaveERP
WHERE NOT EXISTS (
    SELECT 1 FROM FS_PL_Raw_Item_Extra ie
    WHERE ie.CodigoEmpresa = ri.CodigoEmpresa
      AND ie.RawItemId     = ri.RawItemId
      AND ie.FieldKey      = e.FieldKey);
GO

INSERT INTO FS_PL_Raw_Item_Extra (CodigoEmpresa, RawItemId, FieldKey, FieldValue, FieldType)
SELECT ri.CodigoEmpresa, ri.RawItemId, e.FieldKey, e.FieldValue, e.FieldType
FROM FS_PL_Raw_Projecte_Extra e
INNER JOIN FS_PL_Raw_Projecte p
    ON p.CodigoEmpresa = e.CodigoEmpresa AND p.RawProjecteId = e.RawProjecteId
INNER JOIN FS_PL_Raw_Item ri
    ON ri.CodigoEmpresa = p.CodigoEmpresa
   AND ri.TipoOrigen    = 'PRJ'
   AND ri.ClaveERP      = p.ClaveERP
WHERE NOT EXISTS (
    SELECT 1 FROM FS_PL_Raw_Item_Extra ie
    WHERE ie.CodigoEmpresa = ri.CodigoEmpresa
      AND ie.RawItemId     = ri.RawItemId
      AND ie.FieldKey      = e.FieldKey);
GO


-- ---------------------------------------------------------------------------
-- 7. Triggers de sincronizacion Raw_OF/Raw_Comanda/Raw_Projecte -> Raw_Item
--    Mantiene actualizadas las cabeceras Nivel=1 cuando codigo Delphi legacy
--    inserta/actualiza/borra en las tablas antiguas.
-- ---------------------------------------------------------------------------
IF OBJECT_ID('trg_Raw_OF_sync_Item', 'TR') IS NOT NULL DROP TRIGGER trg_Raw_OF_sync_Item;
GO

CREATE TRIGGER trg_Raw_OF_sync_Item
ON FS_PL_Raw_OF
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE ri
    FROM FS_PL_Raw_Item ri
    INNER JOIN deleted d
        ON d.CodigoEmpresa = ri.CodigoEmpresa
       AND ri.TipoOrigen   = 'OF '
       AND ri.ClaveERP     = d.ClaveERP
    WHERE NOT EXISTS (SELECT 1 FROM inserted i
                      WHERE i.CodigoEmpresa = d.CodigoEmpresa
                        AND i.ClaveERP      = d.ClaveERP);

    MERGE FS_PL_Raw_Item AS T
    USING inserted AS S
    ON  T.CodigoEmpresa = S.CodigoEmpresa
    AND T.TipoOrigen    = 'OF '
    AND T.ClaveERP      = S.ClaveERP
    WHEN MATCHED THEN UPDATE SET
        OrigenERP=S.OrigenERP, NumeroDoc=S.NumeroOF, SerieDoc=S.SerieOF,
        CodigoProyecto=S.CodigoProyecto, Nombre=S.DescripcionArticulo,
        CodigoArticulo=S.CodigoArticulo, DescripcionArticulo=S.DescripcionArticulo,
        Cantidad=S.Cantidad, UnidadMedida=S.UnidadMedida,
        CodigoCliente=S.CodigoCliente, NombreCliente=S.NombreCliente,
        FechaCompromiso=S.FechaCompromiso, FechaNecesaria=S.FechaNecesaria,
        FechaLanzamiento=S.FechaLanzamiento,
        Prioridad=S.Prioridad, CentroPreferente=S.CentroPreferente,
        HorasEstimadas=S.HorasEstimadas, EstadoERP=S.EstadoERP,
        Observaciones=S.Observaciones, Activo=S.Activo
    WHEN NOT MATCHED THEN
        INSERT (CodigoEmpresa, TipoOrigen, Nivel, OrigenERP, ClaveERP,
                NumeroDoc, SerieDoc, CodigoProyecto, Nombre,
                CodigoArticulo, DescripcionArticulo, Cantidad, UnidadMedida,
                CodigoCliente, NombreCliente,
                FechaCompromiso, FechaNecesaria, FechaLanzamiento,
                Prioridad, CentroPreferente, HorasEstimadas,
                EstadoERP, Observaciones, FechaImportacion, Activo)
        VALUES (S.CodigoEmpresa, 'OF ', 1, S.OrigenERP, S.ClaveERP,
                S.NumeroOF, S.SerieOF, S.CodigoProyecto, S.DescripcionArticulo,
                S.CodigoArticulo, S.DescripcionArticulo, S.Cantidad, S.UnidadMedida,
                S.CodigoCliente, S.NombreCliente,
                S.FechaCompromiso, S.FechaNecesaria, S.FechaLanzamiento,
                S.Prioridad, S.CentroPreferente, S.HorasEstimadas,
                S.EstadoERP, S.Observaciones, S.FechaImportacion, S.Activo);
END;
GO

IF OBJECT_ID('trg_Raw_Comanda_sync_Item', 'TR') IS NOT NULL DROP TRIGGER trg_Raw_Comanda_sync_Item;
GO

CREATE TRIGGER trg_Raw_Comanda_sync_Item
ON FS_PL_Raw_Comanda
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE ri
    FROM FS_PL_Raw_Item ri
    INNER JOIN deleted d
        ON d.CodigoEmpresa = ri.CodigoEmpresa
       AND ri.TipoOrigen   = 'PED'
       AND ri.ClaveERP     = d.ClaveERP
    WHERE NOT EXISTS (SELECT 1 FROM inserted i
                      WHERE i.CodigoEmpresa = d.CodigoEmpresa
                        AND i.ClaveERP      = d.ClaveERP);

    MERGE FS_PL_Raw_Item AS T
    USING inserted AS S
    ON  T.CodigoEmpresa = S.CodigoEmpresa
    AND T.TipoOrigen    = 'PED'
    AND T.ClaveERP      = S.ClaveERP
    WHEN MATCHED THEN UPDATE SET
        OrigenERP=S.OrigenERP, NumeroDoc=S.NumeroPedido, SerieDoc=S.SeriePedido,
        LineaDoc=S.LineaPedido, CodigoProyecto=S.CodigoProyecto,
        Nombre=S.DescripcionArticulo,
        CodigoArticulo=S.CodigoArticulo, DescripcionArticulo=S.DescripcionArticulo,
        Cantidad=S.Cantidad, UnidadMedida=S.UnidadMedida,
        CodigoCliente=S.CodigoCliente, NombreCliente=S.NombreCliente,
        FechaCompromiso=S.FechaCompromiso, FechaNecesaria=S.FechaNecesaria,
        FechaPedido=S.FechaPedido,
        Prioridad=S.Prioridad, CentroPreferente=S.CentroPreferente,
        HorasEstimadas=S.HorasEstimadas, EstadoERP=S.EstadoERP,
        Observaciones=S.Observaciones, Activo=S.Activo
    WHEN NOT MATCHED THEN
        INSERT (CodigoEmpresa, TipoOrigen, Nivel, OrigenERP, ClaveERP,
                NumeroDoc, SerieDoc, LineaDoc, CodigoProyecto, Nombre,
                CodigoArticulo, DescripcionArticulo, Cantidad, UnidadMedida,
                CodigoCliente, NombreCliente,
                FechaCompromiso, FechaNecesaria, FechaPedido,
                Prioridad, CentroPreferente, HorasEstimadas,
                EstadoERP, Observaciones, FechaImportacion, Activo)
        VALUES (S.CodigoEmpresa, 'PED', 1, S.OrigenERP, S.ClaveERP,
                S.NumeroPedido, S.SeriePedido, S.LineaPedido, S.CodigoProyecto,
                S.DescripcionArticulo,
                S.CodigoArticulo, S.DescripcionArticulo, S.Cantidad, S.UnidadMedida,
                S.CodigoCliente, S.NombreCliente,
                S.FechaCompromiso, S.FechaNecesaria, S.FechaPedido,
                S.Prioridad, S.CentroPreferente, S.HorasEstimadas,
                S.EstadoERP, S.Observaciones, S.FechaImportacion, S.Activo);
END;
GO

IF OBJECT_ID('trg_Raw_Projecte_sync_Item', 'TR') IS NOT NULL DROP TRIGGER trg_Raw_Projecte_sync_Item;
GO

CREATE TRIGGER trg_Raw_Projecte_sync_Item
ON FS_PL_Raw_Projecte
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE ri
    FROM FS_PL_Raw_Item ri
    INNER JOIN deleted d
        ON d.CodigoEmpresa = ri.CodigoEmpresa
       AND ri.TipoOrigen   = 'PRJ'
       AND ri.ClaveERP     = d.ClaveERP
    WHERE NOT EXISTS (SELECT 1 FROM inserted i
                      WHERE i.CodigoEmpresa = d.CodigoEmpresa
                        AND i.ClaveERP      = d.ClaveERP);

    MERGE FS_PL_Raw_Item AS T
    USING inserted AS S
    ON  T.CodigoEmpresa = S.CodigoEmpresa
    AND T.TipoOrigen    = 'PRJ'
    AND T.ClaveERP      = S.ClaveERP
    WHEN MATCHED THEN UPDATE SET
        OrigenERP=S.OrigenERP, CodigoProyecto=S.CodigoProyecto,
        Codigo=S.CodigoProyecto, Nombre=S.Nombre, Descripcion=S.Descripcion,
        CodigoCliente=S.CodigoCliente, NombreCliente=S.NombreCliente,
        FechaCompromiso=S.FechaCompromiso, FechaNecesaria=S.FechaNecesaria,
        FechaInicioPrev=S.FechaInicio,
        Prioridad=S.Prioridad, CentroPreferente=S.CentroPreferente,
        HorasEstimadas=S.HorasEstimadas, EstadoERP=S.EstadoERP,
        Observaciones=S.Observaciones, Activo=S.Activo
    WHEN NOT MATCHED THEN
        INSERT (CodigoEmpresa, TipoOrigen, Nivel, OrigenERP, ClaveERP,
                CodigoProyecto, Codigo, Nombre, Descripcion,
                CodigoCliente, NombreCliente,
                FechaCompromiso, FechaNecesaria, FechaInicioPrev,
                Prioridad, CentroPreferente, HorasEstimadas,
                EstadoERP, Observaciones, FechaImportacion, Activo)
        VALUES (S.CodigoEmpresa, 'PRJ', 1, S.OrigenERP, S.ClaveERP,
                S.CodigoProyecto, S.CodigoProyecto, S.Nombre, S.Descripcion,
                S.CodigoCliente, S.NombreCliente,
                S.FechaCompromiso, S.FechaNecesaria, S.FechaInicio,
                S.Prioridad, S.CentroPreferente, S.HorasEstimadas,
                S.EstadoERP, S.Observaciones, S.FechaImportacion, S.Activo);
END;
GO


-- ---------------------------------------------------------------------------
-- 8. FS_PL_vw_Backlog (v3) - pendientes contra Raw_Item
--    Muestra el item planificable "mas profundo" que existe en cada rama:
--      - Si hay Nivel 3 (OPs): muestra las OPs no planificadas.
--      - Si no hay Nivel 3 para un Nivel 2: muestra el Nivel 2.
--      - Si no hay ni Nivel 2 ni Nivel 3: muestra el Nivel 1.
--    Origen castellano: OF/OT/OP, PEDIDO/LINEA/OP, PROYECTO/TAREA/OP.
-- ---------------------------------------------------------------------------
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
    ri.CodigoArticulo,
    COALESCE(ri.DescripcionArticulo, ri.Nombre, ri.Descripcion) AS DescripcionArticulo,
    ri.Cantidad,
    ri.UnidadMedida,
    ri.CodigoCliente,
    ri.NombreCliente,
    ri.CodigoProyecto,
    ri.FechaCompromiso,
    ri.FechaNecesaria,
    ri.Prioridad,
    ri.CentroPreferente,
    ri.HorasEstimadas,
    ri.EstadoERP,
    ri.Observaciones,
    ri.FechaImportacion
FROM Leafs ri
WHERE NOT EXISTS (
    SELECT 1 FROM FS_PL_NodeData nd
    WHERE nd.CodigoEmpresa      = ri.CodigoEmpresa
      AND nd.RawItemTipoOrigen  = ri.TipoOrigen
      AND nd.RawItemClaveERP    = ri.ClaveERP);
GO


-- ---------------------------------------------------------------------------
-- 9. FS_PL_vw_BacklogPlanned (v2) - planificados contra Raw_Item
--    Incluye las tres familias unificadas; join por RawItemClaveERP.
-- ---------------------------------------------------------------------------
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
    ri.CodigoArticulo,
    COALESCE(ri.DescripcionArticulo, ri.Nombre, ri.Descripcion) AS DescripcionArticulo,
    ri.Cantidad,
    ri.UnidadMedida,
    ri.CodigoCliente,
    ri.NombreCliente,
    ri.CodigoProyecto,
    ri.FechaCompromiso,
    ri.FechaNecesaria,
    ri.Prioridad,
    ri.CentroPreferente,
    ri.HorasEstimadas,
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


-- ---------------------------------------------------------------------------
-- 10. Backfill retroactivo: nodos ya planificados de OF/Pedido anteriores a
--     V016 no tienen RawItemClaveERP/RawItemTipoOrigen. Los rellenamos por
--     join NumeroOF+SerieOF / NumeroPedido+SeriePedido con las tablas viejas.
--     (Los proyectos anteriores no tenian forma de estar lincados, asi que
--     no hay nada que reconectar por esa via.)
-- ---------------------------------------------------------------------------
UPDATE nd
SET nd.RawItemTipoOrigen = 'OF ',
    nd.RawItemClaveERP   = r.ClaveERP
FROM FS_PL_NodeData nd
INNER JOIN FS_PL_Raw_OF r
    ON r.CodigoEmpresa = nd.CodigoEmpresa
   AND r.NumeroOF      = nd.NumeroOF
   AND ISNULL(r.SerieOF,'') = ISNULL(nd.SerieOF,'')
WHERE nd.RawItemClaveERP IS NULL
  AND nd.NumeroOF IS NOT NULL;
GO

UPDATE nd
SET nd.RawItemTipoOrigen = 'PED',
    nd.RawItemClaveERP   = c.ClaveERP
FROM FS_PL_NodeData nd
INNER JOIN FS_PL_Raw_Comanda c
    ON c.CodigoEmpresa = nd.CodigoEmpresa
   AND c.NumeroPedido  = nd.NumeroPedido
   AND ISNULL(c.SeriePedido,'') = ISNULL(nd.SeriePedido,'')
WHERE nd.RawItemClaveERP IS NULL
  AND nd.NumeroPedido IS NOT NULL;
GO
