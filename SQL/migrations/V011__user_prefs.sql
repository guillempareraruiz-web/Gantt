-- ============================================================================
-- V011 - Preferencias de usuario (clave/valor) para UI y parametros
--   - FS_PL_Cfg_UserPrefs   preferencias persistentes por usuario y modulo
--     (ultimo modo scheduling, toggles de paneles, etc.)
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Cfg_UserPrefs')
CREATE TABLE FS_PL_Cfg_UserPrefs (
    CodigoEmpresa     SMALLINT       NOT NULL,
    UserId            NVARCHAR(100)  NOT NULL,
    Module            VARCHAR(50)    NOT NULL,
    PrefKey           VARCHAR(100)   NOT NULL,
    PrefValue         NVARCHAR(MAX)  NULL,
    FechaModificacion DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_FS_PL_Cfg_UserPrefs PRIMARY KEY (CodigoEmpresa, UserId, Module, PrefKey)
);
GO
