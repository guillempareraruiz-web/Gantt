-- ===========================================================================
-- V047 - Afegeix columna IsSystem al FS_PL_CardLayoutSet.
--
-- IsSystem = 1 indica que es el set "Por defecto (sistema)" que NO es pot
-- editar, eliminar, renombrar ni canviar de scope. Sempre n'hi ha un i nomes
-- un (el seeded a la inicialitzacio).
-- ===========================================================================

SET NOCOUNT ON;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FS_PL_CardLayoutSet')
      AND name = 'IsSystem'
)
BEGIN
    ALTER TABLE dbo.FS_PL_CardLayoutSet
        ADD IsSystem BIT NOT NULL CONSTRAINT DF_CardLayoutSet_IsSystem DEFAULT 0;
END;
GO

-- Marcar el set comu existent amb nom "Por defecto" com a sistema (si en queda
-- algun de la versio anterior). Es renombra a "Por defecto (sistema)".
UPDATE dbo.FS_PL_CardLayoutSet
SET IsSystem = 1,
    Nombre = N'Por defecto (sistema)'
WHERE IsSystem = 0
  AND UserId = 0
  AND Nombre = N'Por defecto';
GO
