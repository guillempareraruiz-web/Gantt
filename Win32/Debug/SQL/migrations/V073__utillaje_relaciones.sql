-- ===========================================================================
-- V073 - Relaciones de Utillaje (recurso secundario)
--
-- Modelo: el utillaje es un RECURSO SECUNDARIO al estilo APS. Una operacion
-- no se planifica "sobre" el utillaje, pero lo REQUIERE; el utillaje tiene
-- capacidad propia (FS_PL_Utillaje.Cantidad, V072) y disponibilidad propia.
--
-- Tablas creadas (mismo patron que FS_PL_MoldCenter/Article/Operation):
--   FS_PL_UtillajeCenter     : donde puede montarse
--   FS_PL_UtillajeArticle    : que articulos lo requieren
--   FS_PL_UtillajeOperation  : que operaciones lo requieren
--
-- Ademas SANEA la deuda que dejo V034: FS_PL_MoldUtillaje.CodigoUtillaje era
-- texto libre sin FK al catalogo. Aqui se anyade UtillajeId, se rellena por
-- codigo, se dan de alta en el catalogo los codigos huerfanos (para no perder
-- ningun dato) y se pone la FK formal.
--
-- Idempotente.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------------
-- 1. Utillaje <-> Centro : donde puede montarse este utillaje
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_UtillajeCenter')
CREATE TABLE FS_PL_UtillajeCenter (
    CodigoEmpresa            SMALLINT      NOT NULL,
    UtillajeId               INT           NOT NULL,
    CenterId                 INT           NOT NULL,
    Preferente               BIT           NOT NULL CONSTRAINT DF_FS_PL_UtCenter_Pref DEFAULT 0,
    TiempoMontajeEspecifico  DECIMAL(8,2)  NOT NULL CONSTRAINT DF_FS_PL_UtCenter_TM DEFAULT 0,
    CONSTRAINT PK_FS_PL_UtillajeCenter PRIMARY KEY (CodigoEmpresa, UtillajeId, CenterId),
    CONSTRAINT FK_FS_PL_UtCenter_Utillaje FOREIGN KEY (CodigoEmpresa, UtillajeId)
        REFERENCES FS_PL_Utillaje (CodigoEmpresa, UtillajeId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_UtCenter_Center FOREIGN KEY (CodigoEmpresa, CenterId)
        REFERENCES FS_PL_Center (CodigoEmpresa, CenterId)
);
GO

-- ---------------------------------------------------------------------------
-- 2. Utillaje <-> Articulo : que articulos requieren este utillaje
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_UtillajeArticle')
CREATE TABLE FS_PL_UtillajeArticle (
    CodigoEmpresa     SMALLINT       NOT NULL,
    UtillajeId        INT            NOT NULL,
    CodigoArticulo    NVARCHAR(50)   NOT NULL,
    Obligatorio       BIT            NOT NULL CONSTRAINT DF_FS_PL_UtArt_Obl DEFAULT 1,
    Observaciones     NVARCHAR(500)  NULL,
    CONSTRAINT PK_FS_PL_UtillajeArticle PRIMARY KEY (CodigoEmpresa, UtillajeId, CodigoArticulo),
    CONSTRAINT FK_FS_PL_UtArt_Utillaje FOREIGN KEY (CodigoEmpresa, UtillajeId)
        REFERENCES FS_PL_Utillaje (CodigoEmpresa, UtillajeId) ON DELETE CASCADE
);
GO

-- ---------------------------------------------------------------------------
-- 3. Utillaje <-> Operacion : que operaciones requieren este utillaje
--    Este es el enlace que hace que una OF/OT/OP herede el requisito.
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_UtillajeOperation')
CREATE TABLE FS_PL_UtillajeOperation (
    CodigoEmpresa     SMALLINT       NOT NULL,
    UtillajeId        INT            NOT NULL,
    Operacion         NVARCHAR(100)  NOT NULL,
    Obligatorio       BIT            NOT NULL CONSTRAINT DF_FS_PL_UtOp_Obl DEFAULT 1,
    Observaciones     NVARCHAR(500)  NULL,
    CONSTRAINT PK_FS_PL_UtillajeOperation PRIMARY KEY (CodigoEmpresa, UtillajeId, Operacion),
    CONSTRAINT FK_FS_PL_UtOp_Utillaje FOREIGN KEY (CodigoEmpresa, UtillajeId)
        REFERENCES FS_PL_Utillaje (CodigoEmpresa, UtillajeId) ON DELETE CASCADE
);
GO

-- ---------------------------------------------------------------------------
-- 4. Saneamiento de FS_PL_MoldUtillaje: de codigo libre a FK real
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_MoldUtillaje', 'UtillajeId') IS NULL
    ALTER TABLE FS_PL_MoldUtillaje ADD UtillajeId INT NULL;
GO

-- 4a. Alta en el catalogo de los codigos referenciados por moldes que aun no
--     existen como utillaje. Sin esto, la FK del paso 4c fallaria y se
--     perderia la relacion molde-utillaje existente.
INSERT INTO FS_PL_Utillaje (CodigoEmpresa, Codigo, Descripcion, Activo, Orden)
SELECT DISTINCT mu.CodigoEmpresa, LTRIM(RTRIM(mu.CodigoUtillaje)),
       N'(Alta automatica desde moldes - revisar ficha)', 1, 0
FROM FS_PL_MoldUtillaje mu
WHERE LTRIM(RTRIM(ISNULL(mu.CodigoUtillaje, ''))) <> ''
  AND NOT EXISTS (
      SELECT 1 FROM FS_PL_Utillaje u
      WHERE u.CodigoEmpresa = mu.CodigoEmpresa
        AND u.Codigo = LTRIM(RTRIM(mu.CodigoUtillaje))
  );
GO

-- 4b. Rellenar el id a partir del codigo.
UPDATE mu
SET    UtillajeId = u.UtillajeId
FROM   FS_PL_MoldUtillaje mu
JOIN   FS_PL_Utillaje u
       ON  u.CodigoEmpresa = mu.CodigoEmpresa
       AND u.Codigo = LTRIM(RTRIM(mu.CodigoUtillaje))
WHERE  mu.UtillajeId IS NULL;
GO

-- 4c. FK formal. Solo se crea si ya no queda ninguna fila sin resolver
--     (defensivo: filas con codigo vacio quedarian con UtillajeId NULL).
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FS_PL_MoldUt_Utillaje')
   AND NOT EXISTS (SELECT 1 FROM FS_PL_MoldUtillaje
                   WHERE UtillajeId IS NULL
                     AND LTRIM(RTRIM(ISNULL(CodigoUtillaje, ''))) <> '')
    ALTER TABLE FS_PL_MoldUtillaje ADD CONSTRAINT FK_FS_PL_MoldUt_Utillaje
        FOREIGN KEY (CodigoEmpresa, UtillajeId)
        REFERENCES FS_PL_Utillaje (CodigoEmpresa, UtillajeId);
GO

-- NOTA: CodigoUtillaje se conserva de momento (forma parte de la PK y los
-- repos Delphi aun lo leen). Una migracion posterior puede rehacer la PK
-- sobre UtillajeId y eliminar la columna, una vez el codigo Delphi no la use.

-- ---------------------------------------------------------------------------
-- 5. Vista: requisitos de utillaje efectivos por nodo planificado.
--    Resuelve, para cada nodo, que utillajes necesita segun su operacion o
--    su articulo. Es la entrada del detector de conflictos (alerta R02).
-- ---------------------------------------------------------------------------
IF OBJECT_ID('FS_PL_V_NodeUtillaje', 'V') IS NOT NULL
    DROP VIEW FS_PL_V_NodeUtillaje;
GO

CREATE VIEW FS_PL_V_NodeUtillaje
AS
    -- Requisito que llega por la OPERACION del nodo
    SELECT n.CodigoEmpresa,
           n.NodeId,
           n.ProjectId,
           uo.UtillajeId,
           u.Codigo        AS CodigoUtillaje,
           u.Cantidad,
           uo.Obligatorio,
           N'OPERACION'    AS Origen
    FROM   FS_PL_Node n
    JOIN   FS_PL_NodeData nd
           ON  nd.CodigoEmpresa = n.CodigoEmpresa
           AND nd.NodeId = n.NodeId
    JOIN   FS_PL_UtillajeOperation uo
           ON  uo.CodigoEmpresa = n.CodigoEmpresa
           AND uo.Operacion = nd.Operacion
    JOIN   FS_PL_Utillaje u
           ON  u.CodigoEmpresa = uo.CodigoEmpresa
           AND u.UtillajeId = uo.UtillajeId
    WHERE  u.Activo = 1
      AND  NULLIF(LTRIM(RTRIM(nd.Operacion)), '') IS NOT NULL

    UNION

    -- Requisito que llega por el ARTICULO del nodo
    SELECT n.CodigoEmpresa,
           n.NodeId,
           n.ProjectId,
           ua.UtillajeId,
           u.Codigo        AS CodigoUtillaje,
           u.Cantidad,
           ua.Obligatorio,
           N'ARTICULO'     AS Origen
    FROM   FS_PL_Node n
    JOIN   FS_PL_NodeData nd
           ON  nd.CodigoEmpresa = n.CodigoEmpresa
           AND nd.NodeId = n.NodeId
    JOIN   FS_PL_UtillajeArticle ua
           ON  ua.CodigoEmpresa = n.CodigoEmpresa
           AND ua.CodigoArticulo = nd.CodigoArticulo
    JOIN   FS_PL_Utillaje u
           ON  u.CodigoEmpresa = ua.CodigoEmpresa
           AND u.UtillajeId = ua.UtillajeId
    WHERE  u.Activo = 1
      AND  NULLIF(LTRIM(RTRIM(nd.CodigoArticulo)), '') IS NOT NULL;
GO
