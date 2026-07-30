-- ============================================================================
-- V035 - User Preferences (preferencias UI por usuario y pantalla)
-- ============================================================================
-- Tabla generica clave-valor JSON para que cualquier pantalla persista la
-- configuracion del usuario (filtros, granularidad, layout, etc.).
--
-- Patron: 1 fila por (Empresa, Usuario, ScreenKey). El campo PreferenceJson
-- guarda la config en formato JSON; la pantalla decide su esquema interno.
-- Si el esquema cambia, se versiona dentro del propio JSON (campo "version").
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_UserPreference')
CREATE TABLE FS_PL_UserPreference (
    CodigoEmpresa   SMALLINT       NOT NULL,
    UserId          INT            NOT NULL,
    ScreenKey       NVARCHAR(100)  NOT NULL,
    PreferenceJson  NVARCHAR(MAX)  NOT NULL,
    UpdatedAt       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_FS_PL_UserPreference
        PRIMARY KEY (CodigoEmpresa, UserId, ScreenKey)
);
GO
