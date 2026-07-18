-- =============================================================================
-- V081 - Etiquetas (tags) de tareas, estilo Trello
-- =============================================================================
-- Dos tablas:
--   FS_PL_TaskTag      Catalogo de etiquetas de la empresa (nombre + color).
--                      Se define 'Urgente' en rojo UNA vez y se reutiliza.
--   FS_PL_TaskTagLink  N:M entre tareas y etiquetas.
--
-- Por que un catalogo y no texto libre en la tarea: con texto libre acaban
-- conviviendo 'urgente', 'Urgente' y 'URGENTE' como tres etiquetas distintas,
-- y no se puede filtrar de forma fiable ni dar un color estable a cada una.
--
-- Sustituye a FS_PL_TaskDetail.Etiqueta/ColorEtiqueta (V080), que soportaba
-- UNA sola etiqueta por tarea. Esas columnas se dejan por compatibilidad pero
-- ya no se usan: migrar su contenido no hace falta porque V080 acaba de
-- salir y no hay datos reales.
--
-- Aditivo e idempotente.
-- =============================================================================

-- ---- 1. Catalogo de etiquetas ------------------------------------------------
IF OBJECT_ID('FS_PL_TaskTag', 'U') IS NULL
BEGIN
    CREATE TABLE FS_PL_TaskTag (
        CodigoEmpresa  SMALLINT      NOT NULL,
        TagId          INT           IDENTITY(1,1) NOT NULL,
        Nombre         NVARCHAR(40)  NOT NULL,
        -- Color del badge, en BGR de TColor (como el resto del planner).
        Color          INT           NOT NULL
            CONSTRAINT DF_FS_PL_TaskTag_Color DEFAULT (13463006),
        Orden          INT           NOT NULL
            CONSTRAINT DF_FS_PL_TaskTag_Orden DEFAULT (0),

        CONSTRAINT PK_FS_PL_TaskTag PRIMARY KEY (CodigoEmpresa, TagId),
        -- El nombre identifica la etiqueta de cara al usuario: no puede haber
        -- dos iguales en la misma empresa.
        CONSTRAINT UQ_FS_PL_TaskTag_Nombre UNIQUE (CodigoEmpresa, Nombre)
    );

    PRINT 'V081: FS_PL_TaskTag creada.';
END
ELSE
    PRINT 'V081: FS_PL_TaskTag ya existia.';
GO

-- ---- 2. Etiquetas asignadas a cada tarea (N:M) -------------------------------
IF OBJECT_ID('FS_PL_TaskTagLink', 'U') IS NULL
BEGIN
    CREATE TABLE FS_PL_TaskTagLink (
        CodigoEmpresa  SMALLINT  NOT NULL,
        NodeId         INT       NOT NULL,
        TagId          INT       NOT NULL,

        CONSTRAINT PK_FS_PL_TaskTagLink
            PRIMARY KEY (CodigoEmpresa, NodeId, TagId),
        CONSTRAINT FK_FS_PL_TaskTagLink_Node
            FOREIGN KEY (CodigoEmpresa, NodeId)
            REFERENCES FS_PL_Node (CodigoEmpresa, NodeId) ON DELETE CASCADE,
        CONSTRAINT FK_FS_PL_TaskTagLink_Tag
            FOREIGN KEY (CodigoEmpresa, TagId)
            REFERENCES FS_PL_TaskTag (CodigoEmpresa, TagId)
    );

    -- Para el filtro por etiqueta: "todas las tareas con este tag".
    CREATE INDEX IX_FS_PL_TaskTagLink_Tag
        ON FS_PL_TaskTagLink (CodigoEmpresa, TagId);

    PRINT 'V081: FS_PL_TaskTagLink creada.';
END
ELSE
    PRINT 'V081: FS_PL_TaskTagLink ya existia.';
GO

-- ---- 3. Etiquetas por defecto ------------------------------------------------
-- Un juego inicial por empresa, para que la funcion se entienda sin tener que
-- crear nada a mano. Solo se insertan en las empresas que aun no tengan
-- ninguna etiqueta, asi que reejecutar la migracion no duplica.
-- Colores en BGR (bytes al reves que en RGB).
INSERT INTO FS_PL_TaskTag (CodigoEmpresa, Nombre, Color, Orden)
SELECT e.CodigoEmpresa, t.Nombre, t.Color, t.Orden
  FROM (SELECT DISTINCT CodigoEmpresa FROM FS_PL_Project) e
 CROSS JOIN (VALUES
        (N'Urgente',                          4342015, 1),   -- rojo suave
        (N'Bloqueado',                        3243695, 2),   -- naranja
        (N'Revisi' + NCHAR(243) + N'n',      15771000, 3),   -- azul claro
        (N'Cliente',                          7053374, 4),   -- verde
        (N'Interno',                         10066329, 5)    -- gris
      ) AS t(Nombre, Color, Orden)
 WHERE NOT EXISTS (SELECT 1 FROM FS_PL_TaskTag x
                    WHERE x.CodigoEmpresa = e.CodigoEmpresa);
GO
