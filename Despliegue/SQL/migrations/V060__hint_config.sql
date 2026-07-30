-- ===========================================================================
-- V060 - FS_PL_HintConfigSet: persistencia de la configuracion del HINT
--        (informacion emergente) de los nodos del Gantt.
--
-- Mismo patron que FS_PL_NodeLayoutSet (V059): cada fila es un set completo (un
-- layout por Vista del Gantt) serializado a JSON. El layout del hint es una lista
-- ordenada de campos con un flag de visibilidad (que campos ve el usuario al
-- hacer hover sobre un nodo, y en que orden).
--
-- Puede ser:
--   - privado  (UserId = id_usuario)
--   - comun    (UserId = 0)
--   - sistema  (IsSystem = 1): el "Por defecto (sistema)", no editable/borrable.
--
-- El set activo del usuario se persiste en FS_PL_UserPreference
-- (ScreenKey = 'ActiveHintConfigSetId'). Regla de carga (la decide el repo):
-- privado mas reciente -> comun mas reciente -> default hardcoded.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.FS_PL_HintConfigSet', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FS_PL_HintConfigSet (
        CodigoEmpresa     SMALLINT       NOT NULL,
        SetId             INT IDENTITY(1,1) NOT NULL,
        UserId            INT            NOT NULL,   -- 0 = comun para todos
        Nombre            NVARCHAR(80)   NOT NULL,
        IsCommon          AS CAST(CASE WHEN UserId = 0 THEN 1 ELSE 0 END AS BIT) PERSISTED,
        IsSystem          BIT            NOT NULL CONSTRAINT DF_HintConfigSet_IsSystem DEFAULT 0,
        SetJson           NVARCHAR(MAX)  NOT NULL,
        FechaCreacion     DATETIME       NOT NULL CONSTRAINT DF_HintConfigSet_FCre DEFAULT GETDATE(),
        FechaModificacion DATETIME       NOT NULL CONSTRAINT DF_HintConfigSet_FMod DEFAULT GETDATE(),
        CONSTRAINT PK_FS_PL_HintConfigSet PRIMARY KEY (CodigoEmpresa, SetId)
    );

    CREATE INDEX IX_HintConfigSet_UserId
        ON dbo.FS_PL_HintConfigSet (CodigoEmpresa, UserId);
END;
GO
