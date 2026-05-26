-- ===========================================================================
-- V046 - FS_PL_CardLayoutSet: persistencia dels Card Layout Sets dels grids.
--
-- Cada fila es un set complet (6 categories OF/PED/PROY x Pend/Plan) serialitzat
-- a JSON. Pot ser privat (UserId = id_usuari) o comu (UserId = 0).
--
-- L'usuari pot tenir 1 set actiu (PreferredId al FS_PL_UserPreference o,
-- alternativament, sempre carrega el seu privat si existeix; si no, el primer
-- comu disponible).
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.FS_PL_CardLayoutSet', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FS_PL_CardLayoutSet (
        CodigoEmpresa     SMALLINT       NOT NULL,
        SetId             INT IDENTITY(1,1) NOT NULL,
        UserId            INT            NOT NULL,   -- 0 = comu per a tots
        Nombre            NVARCHAR(80)   NOT NULL,
        IsCommon          AS CAST(CASE WHEN UserId = 0 THEN 1 ELSE 0 END AS BIT) PERSISTED,
        SetJson           NVARCHAR(MAX)  NOT NULL,
        FechaCreacion     DATETIME       NOT NULL CONSTRAINT DF_CardLayoutSet_FCre DEFAULT GETDATE(),
        FechaModificacion DATETIME       NOT NULL CONSTRAINT DF_CardLayoutSet_FMod DEFAULT GETDATE(),
        CONSTRAINT PK_FS_PL_CardLayoutSet PRIMARY KEY (CodigoEmpresa, SetId)
    );

    CREATE INDEX IX_CardLayoutSet_UserId
        ON dbo.FS_PL_CardLayoutSet (CodigoEmpresa, UserId);
END;
GO
