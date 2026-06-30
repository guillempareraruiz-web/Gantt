-- ============================================================================
-- FIX puntual: la V067 se aplico con una version INCORRECTA de la vista
-- FS_PL_vw_BacklogPlanned (basada en V013, sin la columna ParentRawItemId que
-- el Backlog necesita). Esto provoca el error "El nombre de columna
-- 'ParentRawItemId' no es valido" al cargar el Backlog.
--
-- Como el runner de migraciones solo aplica versiones > MAX(Version), la V067
-- corregida NO se reaplicaria sola. Borramos su registro para que el runner la
-- vuelva a ejecutar (ya corregida) en la proxima conexion.
--
-- Ejecutar UNA VEZ sobre la BD del Planner. Despues, arrancar la app: el runner
-- reaplicara V067 con la vista correcta (rama ERP de V053 + rama MANUAL).
-- ============================================================================

DELETE FROM FS_PL_SchemaVersion WHERE Version = 67;
GO

-- (Opcional) Comprobar que ha quedado en MAX = 66:
-- SELECT MAX(Version) AS MaxVer FROM FS_PL_SchemaVersion;
