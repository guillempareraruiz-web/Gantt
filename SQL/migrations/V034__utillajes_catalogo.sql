-- ===========================================================================
-- V034 - Catalogo de Utillajes (FS_PL_Utillaje)
--
-- Hasta ahora los utillajes se referenciaban solo como texto libre desde
-- FS_PL_MoldUtillaje. Esta migracion introduce el catalogo maestro, que el
-- CRUD y el Picker consumiran.
--
-- NOTA: La columna FS_PL_MoldUtillaje.CodigoUtillaje queda como NVARCHAR(50)
-- sin FK formal al catalogo, para no romper datos existentes. Una proxima
-- migracion puede a~nadir la FK cuando los codigos esten saneados.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Utillaje')
CREATE TABLE FS_PL_Utillaje (
    CodigoEmpresa     SMALLINT      NOT NULL,
    UtillajeId        INT IDENTITY(1,1) NOT NULL,
    Codigo            NVARCHAR(50)  NOT NULL,
    Descripcion       NVARCHAR(500) NULL,
    Tipo              NVARCHAR(50)  NULL,
    Ubicacion         NVARCHAR(200) NULL,
    Disponible        BIT           NOT NULL CONSTRAINT DF_FS_PL_Utillaje_Disp DEFAULT 1,
    Observaciones     NVARCHAR(MAX) NULL,
    Activo            BIT           NOT NULL CONSTRAINT DF_FS_PL_Utillaje_Activo DEFAULT 1,
    Orden             INT           NOT NULL CONSTRAINT DF_FS_PL_Utillaje_Orden DEFAULT 0,
    FechaCreacion     DATETIME2     NOT NULL CONSTRAINT DF_FS_PL_Utillaje_FCre DEFAULT SYSDATETIME(),
    FechaModificacion DATETIME2     NULL,
    CONSTRAINT PK_FS_PL_Utillaje PRIMARY KEY (CodigoEmpresa, UtillajeId),
    CONSTRAINT UQ_FS_PL_Utillaje_Codigo UNIQUE (CodigoEmpresa, Codigo)
);
GO
