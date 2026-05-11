-- ===========================================================================
-- V026 - FS_PL_Maquina + FS_PL_CentroMaquina
--
-- Nueva entidad MAQUINA con relacion N:M contra FS_PL_Center.
-- Una maquina puede pertenecer a varios centros (compartida segun turno
-- o configuracion). La eliminacion de un centro o maquina limpia en cascada
-- las asignaciones en FS_PL_CentroMaquina.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Maquina')
CREATE TABLE FS_PL_Maquina (
    CodigoEmpresa    SMALLINT       NOT NULL,
    MaquinaId        INT IDENTITY(1,1) NOT NULL,
    Codigo           NVARCHAR(50)   NOT NULL,
    Nombre           NVARCHAR(200)  NOT NULL,
    Activo           BIT            NOT NULL CONSTRAINT DF_FS_PL_Maquina_Activo DEFAULT 1,
    Orden            INT            NOT NULL CONSTRAINT DF_FS_PL_Maquina_Orden DEFAULT 0,
    FechaCreacion    DATETIME2      NOT NULL CONSTRAINT DF_FS_PL_Maquina_FCre DEFAULT SYSDATETIME(),
    FechaModificacion DATETIME2     NULL,
    CONSTRAINT PK_FS_PL_Maquina PRIMARY KEY (CodigoEmpresa, MaquinaId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'UX_FS_PL_Maquina_Codigo'
                 AND object_id = OBJECT_ID('FS_PL_Maquina'))
CREATE UNIQUE NONCLUSTERED INDEX UX_FS_PL_Maquina_Codigo
    ON FS_PL_Maquina (CodigoEmpresa, Codigo);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_CentroMaquina')
CREATE TABLE FS_PL_CentroMaquina (
    CodigoEmpresa    SMALLINT       NOT NULL,
    CenterId         INT            NOT NULL,
    MaquinaId        INT            NOT NULL,
    FechaAsignacion  DATETIME2      NOT NULL CONSTRAINT DF_FS_PL_CentroMaquina_FAsig DEFAULT SYSDATETIME(),
    CONSTRAINT PK_FS_PL_CentroMaquina PRIMARY KEY (CodigoEmpresa, CenterId, MaquinaId),
    CONSTRAINT FK_FS_PL_CentroMaquina_Center FOREIGN KEY (CodigoEmpresa, CenterId)
        REFERENCES FS_PL_Center (CodigoEmpresa, CenterId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_CentroMaquina_Maquina FOREIGN KEY (CodigoEmpresa, MaquinaId)
        REFERENCES FS_PL_Maquina (CodigoEmpresa, MaquinaId) ON DELETE CASCADE
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_CentroMaquina_Maquina'
                 AND object_id = OBJECT_ID('FS_PL_CentroMaquina'))
CREATE NONCLUSTERED INDEX IX_FS_PL_CentroMaquina_Maquina
    ON FS_PL_CentroMaquina (CodigoEmpresa, MaquinaId)
    INCLUDE (CenterId);
GO
