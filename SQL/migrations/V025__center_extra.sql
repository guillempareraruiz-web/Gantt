-- ===========================================================================
-- V025 - FS_PL_Center_Extra (camps personalitzats per centre)
--
-- Mateix patro que FS_PL_RawItem_Extra (V023): key/value + auditoria
-- + Source ERP/MANUAL. La FK fa cascade per netejar overrides en eliminar
-- el Center pare.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Center_Extra')
CREATE TABLE FS_PL_Center_Extra (
    CodigoEmpresa  SMALLINT       NOT NULL,
    CenterId       INT            NOT NULL,
    FieldKey       VARCHAR(64)    NOT NULL,
    FieldValue     NVARCHAR(MAX)  NULL,
    Source         CHAR(6)        NOT NULL CONSTRAINT DF_FS_PL_Center_Extra_Source DEFAULT 'MANUAL',
    UpdatedBy      NVARCHAR(64)   NULL,
    UpdatedAt      DATETIME2      NULL,
    CONSTRAINT PK_FS_PL_Center_Extra PRIMARY KEY (CodigoEmpresa, CenterId, FieldKey),
    CONSTRAINT FK_FS_PL_Center_Extra_Center FOREIGN KEY (CodigoEmpresa, CenterId)
        REFERENCES FS_PL_Center (CodigoEmpresa, CenterId) ON DELETE CASCADE,
    CONSTRAINT CK_FS_PL_Center_Extra_Source CHECK (Source IN ('ERP','MANUAL'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Center_Extra_FieldKey'
                 AND object_id = OBJECT_ID('FS_PL_Center_Extra'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Center_Extra_FieldKey
    ON FS_PL_Center_Extra (CodigoEmpresa, FieldKey)
    INCLUDE (CenterId, FieldValue, Source);
GO
