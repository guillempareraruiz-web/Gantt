-- ===========================================================================
-- V059 - FS_PL_NodeLayoutSet: persistencia dels Node Layout Sets del Gantt.
--
-- Mismo patron que FS_PL_CardLayoutSet (V046/V047) pero para el CONTENIDO VISUAL
-- de los NODOS del Gantt. Cada fila es un set completo (un layout por Vista del
-- Gantt: Normal, Fabricacion, Fecha de entrega, Stock, ...) serializado a JSON.
--
-- Puede ser:
--   - privado  (UserId = id_usuario)
--   - comun    (UserId = 0)
--   - sistema  (IsSystem = 1): el "Por defecto (sistema)", no editable/borrable.
--
-- El set activo del usuario se persiste en FS_PL_UserPreference
-- (ScreenKey = 'ActiveNodeLayoutSetId'). Regla de carga (la decide el repo):
-- privado mas reciente -> comun mas reciente -> default hardcoded.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.FS_PL_NodeLayoutSet', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FS_PL_NodeLayoutSet (
        CodigoEmpresa     SMALLINT       NOT NULL,
        SetId             INT IDENTITY(1,1) NOT NULL,
        UserId            INT            NOT NULL,   -- 0 = comun para todos
        Nombre            NVARCHAR(80)   NOT NULL,
        IsCommon          AS CAST(CASE WHEN UserId = 0 THEN 1 ELSE 0 END AS BIT) PERSISTED,
        IsSystem          BIT            NOT NULL CONSTRAINT DF_NodeLayoutSet_IsSystem DEFAULT 0,
        SetJson           NVARCHAR(MAX)  NOT NULL,
        FechaCreacion     DATETIME       NOT NULL CONSTRAINT DF_NodeLayoutSet_FCre DEFAULT GETDATE(),
        FechaModificacion DATETIME       NOT NULL CONSTRAINT DF_NodeLayoutSet_FMod DEFAULT GETDATE(),
        CONSTRAINT PK_FS_PL_NodeLayoutSet PRIMARY KEY (CodigoEmpresa, SetId)
    );

    CREATE INDEX IX_NodeLayoutSet_UserId
        ON dbo.FS_PL_NodeLayoutSet (CodigoEmpresa, UserId);
END;
GO
