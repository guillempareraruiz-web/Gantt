-- ============================================================================
-- V005 - Tabla de proyecto activo por usuario
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_UserActiveProject')
CREATE TABLE FS_PL_UserActiveProject (
    CodigoEmpresa   SMALLINT  NOT NULL,
    UserId          INT       NOT NULL,
    ProjectId       INT       NOT NULL,
    FechaActualizacion DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_FS_PL_UserActiveProject PRIMARY KEY (CodigoEmpresa, UserId)
);
GO
