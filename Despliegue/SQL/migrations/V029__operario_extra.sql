-- ===========================================================================
-- V029 - FS_PL_Operario_Extra (camps personalitzats per operario)
--
-- Mateix patro que FS_PL_Center_Extra (V025) i FS_PL_Maquina_Extra (V028):
-- key/value + auditoria + Source ERP/MANUAL. La FK fa cascade per netejar
-- overrides en eliminar l'operario pare.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Operario_Extra')
CREATE TABLE FS_PL_Operario_Extra (
    CodigoEmpresa  SMALLINT       NOT NULL,
    OperatorId     INT            NOT NULL,
    FieldKey       VARCHAR(64)    NOT NULL,
    FieldValue     NVARCHAR(MAX)  NULL,
    Source         CHAR(6)        NOT NULL CONSTRAINT DF_FS_PL_Operario_Extra_Source DEFAULT 'MANUAL',
    UpdatedBy      NVARCHAR(64)   NULL,
    UpdatedAt      DATETIME2      NULL,
    CONSTRAINT PK_FS_PL_Operario_Extra PRIMARY KEY (CodigoEmpresa, OperatorId, FieldKey),
    CONSTRAINT FK_FS_PL_Operario_Extra_Op FOREIGN KEY (CodigoEmpresa, OperatorId)
        REFERENCES FS_PL_Operator (CodigoEmpresa, OperatorId) ON DELETE CASCADE,
    CONSTRAINT CK_FS_PL_Operario_Extra_Source CHECK (Source IN ('ERP','MANUAL'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Operario_Extra_FieldKey'
                 AND object_id = OBJECT_ID('FS_PL_Operario_Extra'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Operario_Extra_FieldKey
    ON FS_PL_Operario_Extra (CodigoEmpresa, FieldKey)
    INCLUDE (OperatorId, FieldValue, Source);
GO
