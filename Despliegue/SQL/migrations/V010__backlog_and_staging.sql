-- ============================================================================
-- V010 - Staging en crudo de entidades ERP + configuración de grids + Backlog
--   - FS_PL_Raw_OF / Raw_Comanda / Raw_Projecte    (datos crudos del ERP)
--   - FS_PL_Raw_*_Extra                            (campos personalizados k/v)
--   - FS_PL_Cfg_GridColumns / FS_PL_Cfg_UserGridLayout (personalización grids)
--   - FS_PL_vw_Backlog                             (vista para pantalla Backlog)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Staging - OFs en crudo desde ERP
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Raw_OF')
CREATE TABLE FS_PL_Raw_OF (
    CodigoEmpresa     SMALLINT       NOT NULL,
    RawOFId           BIGINT IDENTITY(1,1) NOT NULL,
    OrigenERP         NVARCHAR(30)   NOT NULL,   -- 'SAGE200','DEMO',...
    ClaveERP          NVARCHAR(100)  NOT NULL,   -- id original en el ERP
    NumeroOF          INT            NULL,
    SerieOF           NVARCHAR(20)   NULL,
    CodigoArticulo    NVARCHAR(50)   NULL,
    DescripcionArticulo NVARCHAR(500) NULL,
    Cantidad          DECIMAL(18,4)  NULL,
    UnidadMedida      NVARCHAR(20)   NULL,
    CodigoCliente     NVARCHAR(50)   NULL,
    NombreCliente     NVARCHAR(200)  NULL,
    CodigoProyecto    NVARCHAR(50)   NULL,
    FechaCompromiso   DATETIME2      NULL,
    FechaNecesaria    DATETIME2      NULL,
    FechaLanzamiento  DATETIME2      NULL,
    Prioridad         INT            NULL,
    CentroPreferente  NVARCHAR(30)   NULL,        -- CodigoCentro preferido (si lo sugiere el ERP)
    HorasEstimadas    DECIMAL(12,2)  NULL,
    EstadoERP         NVARCHAR(30)   NULL,
    Observaciones     NVARCHAR(MAX)  NULL,
    FechaImportacion  DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    Activo            BIT            NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Raw_OF PRIMARY KEY (CodigoEmpresa, RawOFId),
    CONSTRAINT UQ_FS_PL_Raw_OF_Clave UNIQUE (CodigoEmpresa, OrigenERP, ClaveERP)
);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FS_PL_Raw_OF_NumSerie')
    CREATE INDEX IX_FS_PL_Raw_OF_NumSerie
        ON FS_PL_Raw_OF (CodigoEmpresa, NumeroOF, SerieOF);
GO

-- ---------------------------------------------------------------------------
-- Staging - Pedidos/Comandas en crudo
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Raw_Comanda')
CREATE TABLE FS_PL_Raw_Comanda (
    CodigoEmpresa     SMALLINT       NOT NULL,
    RawComandaId      BIGINT IDENTITY(1,1) NOT NULL,
    OrigenERP         NVARCHAR(30)   NOT NULL,
    ClaveERP          NVARCHAR(100)  NOT NULL,
    NumeroPedido      INT            NULL,
    SeriePedido       NVARCHAR(20)   NULL,
    LineaPedido       INT            NULL,
    CodigoArticulo    NVARCHAR(50)   NULL,
    DescripcionArticulo NVARCHAR(500) NULL,
    Cantidad          DECIMAL(18,4)  NULL,
    UnidadMedida      NVARCHAR(20)   NULL,
    CodigoCliente     NVARCHAR(50)   NULL,
    NombreCliente     NVARCHAR(200)  NULL,
    CodigoProyecto    NVARCHAR(50)   NULL,
    FechaCompromiso   DATETIME2      NULL,
    FechaNecesaria    DATETIME2      NULL,
    FechaPedido       DATETIME2      NULL,
    Prioridad         INT            NULL,
    CentroPreferente  NVARCHAR(30)   NULL,
    HorasEstimadas    DECIMAL(12,2)  NULL,
    EstadoERP         NVARCHAR(30)   NULL,
    Observaciones     NVARCHAR(MAX)  NULL,
    FechaImportacion  DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    Activo            BIT            NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Raw_Comanda PRIMARY KEY (CodigoEmpresa, RawComandaId),
    CONSTRAINT UQ_FS_PL_Raw_Comanda_Clave UNIQUE (CodigoEmpresa, OrigenERP, ClaveERP)
);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FS_PL_Raw_Comanda_NumSerie')
    CREATE INDEX IX_FS_PL_Raw_Comanda_NumSerie
        ON FS_PL_Raw_Comanda (CodigoEmpresa, NumeroPedido, SeriePedido);
GO

-- ---------------------------------------------------------------------------
-- Staging - Proyectos en crudo
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Raw_Projecte')
CREATE TABLE FS_PL_Raw_Projecte (
    CodigoEmpresa     SMALLINT       NOT NULL,
    RawProjecteId     BIGINT IDENTITY(1,1) NOT NULL,
    OrigenERP         NVARCHAR(30)   NOT NULL,
    ClaveERP          NVARCHAR(100)  NOT NULL,
    CodigoProyecto    NVARCHAR(50)   NULL,
    Nombre            NVARCHAR(200)  NULL,
    Descripcion       NVARCHAR(MAX)  NULL,
    CodigoCliente     NVARCHAR(50)   NULL,
    NombreCliente     NVARCHAR(200)  NULL,
    FechaInicio       DATETIME2      NULL,
    FechaCompromiso   DATETIME2      NULL,
    FechaNecesaria    DATETIME2      NULL,
    Prioridad         INT            NULL,
    CentroPreferente  NVARCHAR(30)   NULL,
    HorasEstimadas    DECIMAL(12,2)  NULL,
    EstadoERP         NVARCHAR(30)   NULL,
    Observaciones     NVARCHAR(MAX)  NULL,
    FechaImportacion  DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    Activo            BIT            NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Raw_Projecte PRIMARY KEY (CodigoEmpresa, RawProjecteId),
    CONSTRAINT UQ_FS_PL_Raw_Projecte_Clave UNIQUE (CodigoEmpresa, OrigenERP, ClaveERP)
);
GO

-- ---------------------------------------------------------------------------
-- Campos personalizados (clave/valor) por entidad de staging
--   FieldType    'S' string, 'N' numeric, 'D' datetime, 'B' bool
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Raw_OF_Extra')
CREATE TABLE FS_PL_Raw_OF_Extra (
    CodigoEmpresa   SMALLINT       NOT NULL,
    RawOFId         BIGINT         NOT NULL,
    FieldKey        VARCHAR(64)    NOT NULL,
    FieldValue      NVARCHAR(1000) NULL,
    FieldType       CHAR(1)        NOT NULL,
    CONSTRAINT PK_FS_PL_Raw_OF_Extra PRIMARY KEY (CodigoEmpresa, RawOFId, FieldKey),
    CONSTRAINT FK_FS_PL_Raw_OF_Extra_OF FOREIGN KEY (CodigoEmpresa, RawOFId)
        REFERENCES FS_PL_Raw_OF (CodigoEmpresa, RawOFId) ON DELETE CASCADE
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Raw_Comanda_Extra')
CREATE TABLE FS_PL_Raw_Comanda_Extra (
    CodigoEmpresa   SMALLINT       NOT NULL,
    RawComandaId    BIGINT         NOT NULL,
    FieldKey        VARCHAR(64)    NOT NULL,
    FieldValue      NVARCHAR(1000) NULL,
    FieldType       CHAR(1)        NOT NULL,
    CONSTRAINT PK_FS_PL_Raw_Comanda_Extra PRIMARY KEY (CodigoEmpresa, RawComandaId, FieldKey),
    CONSTRAINT FK_FS_PL_Raw_Comanda_Extra_Com FOREIGN KEY (CodigoEmpresa, RawComandaId)
        REFERENCES FS_PL_Raw_Comanda (CodigoEmpresa, RawComandaId) ON DELETE CASCADE
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Raw_Projecte_Extra')
CREATE TABLE FS_PL_Raw_Projecte_Extra (
    CodigoEmpresa   SMALLINT       NOT NULL,
    RawProjecteId   BIGINT         NOT NULL,
    FieldKey        VARCHAR(64)    NOT NULL,
    FieldValue      NVARCHAR(1000) NULL,
    FieldType       CHAR(1)        NOT NULL,
    CONSTRAINT PK_FS_PL_Raw_Projecte_Extra PRIMARY KEY (CodigoEmpresa, RawProjecteId, FieldKey),
    CONSTRAINT FK_FS_PL_Raw_Projecte_Extra_Pr FOREIGN KEY (CodigoEmpresa, RawProjecteId)
        REFERENCES FS_PL_Raw_Projecte (CodigoEmpresa, RawProjecteId) ON DELETE CASCADE
);
GO

-- ---------------------------------------------------------------------------
-- Configuracion de grids
--   - FS_PL_Cfg_GridColumns    catalogo de columnas disponibles por grid
--                              (incluye campos custom del cliente)
--   - FS_PL_Cfg_UserGridLayout layout persistido por usuario (ancho, orden,
--                              visibilidad, filtros, sort)
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Cfg_GridColumns')
CREATE TABLE FS_PL_Cfg_GridColumns (
    CodigoEmpresa     SMALLINT       NOT NULL,
    GridId            VARCHAR(50)    NOT NULL,   -- 'BACKLOG','CENTROS','OPERARIOS',...
    ColumnKey         VARCHAR(64)    NOT NULL,   -- identificador lógico de la columna
    Caption           NVARCHAR(200)  NOT NULL,
    DataType          CHAR(1)        NOT NULL,   -- 'S','N','D','B'
    VisibleDefault    BIT            NOT NULL DEFAULT 1,
    OrderDefault      INT            NOT NULL DEFAULT 0,
    WidthDefault      INT            NOT NULL DEFAULT 100,
    IsCustomField     BIT            NOT NULL DEFAULT 0,  -- 1 = viene de *_Extra
    SourceEntity      VARCHAR(30)    NULL,        -- 'OF','COMANDA','PROJECTE' (para custom)
    SourceExpression  NVARCHAR(500)  NULL,        -- FieldKey (si custom) o expresión SQL
    Formato           NVARCHAR(50)   NULL,
    Activo            BIT            NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Cfg_GridColumns PRIMARY KEY (CodigoEmpresa, GridId, ColumnKey)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Cfg_UserGridLayout')
CREATE TABLE FS_PL_Cfg_UserGridLayout (
    CodigoEmpresa     SMALLINT       NOT NULL,
    UserId            NVARCHAR(100)  NOT NULL,
    GridId            VARCHAR(50)    NOT NULL,
    LayoutData        NVARCHAR(MAX)  NOT NULL,    -- storage nativo cxGrid (string)
    FechaModificacion DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_FS_PL_Cfg_UserGridLayout PRIMARY KEY (CodigoEmpresa, UserId, GridId)
);
GO

-- ---------------------------------------------------------------------------
-- Vista Backlog - unifica OF + Comanda + Projecte y excluye lo que ya esta en
-- el Plan MASTER (FS_PL_NodeData relaciona nodos con NumeroOF/NumeroPedido).
-- Los campos custom se añaden en runtime con LEFT JOIN a *_Extra según la
-- configuración de FS_PL_Cfg_GridColumns (resolución en la capa Delphi).
-- ---------------------------------------------------------------------------
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
    CAST('COMANDA' AS VARCHAR(10))       AS Origen,
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
    CAST('PROJECTE' AS VARCHAR(10))      AS Origen,
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
