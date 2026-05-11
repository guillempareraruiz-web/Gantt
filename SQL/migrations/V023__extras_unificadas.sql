-- ===========================================================================
-- V023 - Tablas _Extra unificadas (key/value + auditoria)
--
-- Patron: una tabla _Extra por entidad logica del planificador, todas con
-- el mismo esquema. Sustituye al modelo previo de tres taules separadas
-- (FS_PL_Raw_OF_Extra / FS_PL_Raw_Comanda_Extra / FS_PL_Raw_Projecte_Extra)
-- que estaban acopladas a las tablas Raw_OF/Comanda/Projecte (pre-V016).
--
-- Esta migracion SOLO crea las nuevas tablas. La migracion de datos y la
-- desconexion de las antiguas se hara en una migracion posterior, cuando
-- el codigo Delphi ya este leyendo/escribiendo de las nuevas.
--
--   FS_PL_RawItem_Extra   -> overrides/personalizaciones de FS_PL_Raw_Item
--                            (cualquier nivel: OF/OT/OP, PED/LINEA/OP, ...)
--   FS_PL_NodeData_Extra  -> overrides/personalizaciones de FS_PL_NodeData
--                            (campos custom del NodeInspector)
--
-- Politica Source: 'ERP' = puede sobrescribirlo el conector ERP en cada
-- importacion. 'MANUAL' = override del usuario, intocable por el ERP.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- --------- FS_PL_RawItem_Extra ---------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_RawItem_Extra')
CREATE TABLE FS_PL_RawItem_Extra (
    CodigoEmpresa  SMALLINT       NOT NULL,
    RawItemId      BIGINT         NOT NULL,
    FieldKey       VARCHAR(64)    NOT NULL,
    FieldValue     NVARCHAR(MAX)  NULL,
    Source         CHAR(6)        NOT NULL CONSTRAINT DF_FS_PL_RawItem_Extra_Source DEFAULT 'ERP',
    UpdatedBy      NVARCHAR(64)   NULL,
    UpdatedAt      DATETIME2      NULL,
    CONSTRAINT PK_FS_PL_RawItem_Extra PRIMARY KEY (CodigoEmpresa, RawItemId, FieldKey),
    CONSTRAINT FK_FS_PL_RawItem_Extra_Item FOREIGN KEY (CodigoEmpresa, RawItemId)
        REFERENCES FS_PL_Raw_Item (CodigoEmpresa, RawItemId) ON DELETE CASCADE,
    CONSTRAINT CK_FS_PL_RawItem_Extra_Source CHECK (Source IN ('ERP','MANUAL'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_RawItem_Extra_FieldKey'
                 AND object_id = OBJECT_ID('FS_PL_RawItem_Extra'))
CREATE NONCLUSTERED INDEX IX_FS_PL_RawItem_Extra_FieldKey
    ON FS_PL_RawItem_Extra (CodigoEmpresa, FieldKey)
    INCLUDE (RawItemId, FieldValue, Source);
GO

-- --------- FS_PL_NodeData_Extra --------------------------------------------
-- NodeData tiene PK (CodigoEmpresa, NodeId). La _Extra replica esa PK.
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_NodeData_Extra')
CREATE TABLE FS_PL_NodeData_Extra (
    CodigoEmpresa  SMALLINT       NOT NULL,
    NodeId         INT            NOT NULL,
    FieldKey       VARCHAR(64)    NOT NULL,
    FieldValue     NVARCHAR(MAX)  NULL,
    Source         CHAR(6)        NOT NULL CONSTRAINT DF_FS_PL_NodeData_Extra_Source DEFAULT 'MANUAL',
    UpdatedBy      NVARCHAR(64)   NULL,
    UpdatedAt      DATETIME2      NULL,
    CONSTRAINT PK_FS_PL_NodeData_Extra PRIMARY KEY (CodigoEmpresa, NodeId, FieldKey),
    CONSTRAINT FK_FS_PL_NodeData_Extra_Node FOREIGN KEY (CodigoEmpresa, NodeId)
        REFERENCES FS_PL_NodeData (CodigoEmpresa, NodeId) ON DELETE CASCADE,
    CONSTRAINT CK_FS_PL_NodeData_Extra_Source CHECK (Source IN ('ERP','MANUAL'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_NodeData_Extra_FieldKey'
                 AND object_id = OBJECT_ID('FS_PL_NodeData_Extra'))
CREATE NONCLUSTERED INDEX IX_FS_PL_NodeData_Extra_FieldKey
    ON FS_PL_NodeData_Extra (CodigoEmpresa, FieldKey)
    INCLUDE (NodeId, FieldValue, Source);
GO
