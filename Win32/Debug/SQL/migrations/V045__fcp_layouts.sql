-- ===========================================================================
-- V045 - FS_PL_FCP_Layout: layouts personalizados del form Carga Finita.
--
-- Cada usuario puede definir N layouts. Un layout es una seleccion + orden
-- de centros para el panel de columnas del Planificador de Capacidad Finita.
--
-- CentrosJson formato: '[{"CentroId":12,"Orden":0},{"CentroId":5,"Orden":1},...]'
--   Orden = posicion (0-based) de izquierda a derecha. Solo se listan los
--   centros visibles en el layout; los no listados quedan ocultos.
--
-- El layout "(por defecto)" es virtual: si no hay filas para el usuario, el
-- form muestra todos los centros ordenados alfabeticamente. No se persiste.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.FS_PL_FCP_Layout', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FS_PL_FCP_Layout (
        CodigoEmpresa        SMALLINT       NOT NULL,
        LayoutId             INT IDENTITY(1,1) NOT NULL,
        UserId               INT            NOT NULL,
        Nombre               NVARCHAR(80)   NOT NULL,
        IsDefault            BIT            NOT NULL CONSTRAINT DF_FCPLayout_IsDefault DEFAULT 0,
        CentrosJson          NVARCHAR(MAX)  NOT NULL,
        FechaCreacion        DATETIME       NOT NULL CONSTRAINT DF_FCPLayout_FechaCreacion DEFAULT GETDATE(),
        FechaModificacion    DATETIME       NOT NULL CONSTRAINT DF_FCPLayout_FechaModificacion DEFAULT GETDATE(),
        CONSTRAINT PK_FS_PL_FCP_Layout PRIMARY KEY (CodigoEmpresa, LayoutId)
    );

    CREATE INDEX IX_FCPLayout_UserId
        ON dbo.FS_PL_FCP_Layout (CodigoEmpresa, UserId);
END;
GO
