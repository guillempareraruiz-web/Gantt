-- ============================================================================
-- V006 - Asignación de usuarios a proyectos
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_ProjectUser')
CREATE TABLE FS_PL_ProjectUser (
    CodigoEmpresa   SMALLINT  NOT NULL,
    ProjectId       INT       NOT NULL,
    UserId          INT       NOT NULL,
    FechaAsignacion DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_FS_PL_ProjectUser PRIMARY KEY (CodigoEmpresa, ProjectId, UserId)
);
GO
