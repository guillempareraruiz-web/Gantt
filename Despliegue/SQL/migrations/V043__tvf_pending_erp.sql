-- ===========================================================================
-- V043 - Funcion de tabla FS_PL_fn_PendingErpOFs + sp de instalacion.
--
-- Objetivo:
--   Detectar de un vistazo cuantas OFs y OTs vivas (EstadoOF/OT IN 0,1) hay
--   en el ERP Sage 200 que aun NO estan en FS_PL_Raw_Item local.
--
-- Patron de cross-database:
--   La TVF necesita leer de [<SageDB>].dbo.OrdenesFabricacion y .OrdenesTrabajo,
--   pero el nombre de la BD Sage es configurable por cliente (esta en el INI
--   del FSPlanner). No podemos hardcodearlo.
--
--   Solucion: la TVF se crea aqui con un body PROVISIONAL que retorna 0 filas
--   (para que el objeto exista y los SELECT del Dashboard no fallen). Luego,
--   el sp FS_PL_sp_InstallTvfPendingErp recompila la funcion via ALTER
--   sustituyendo el placeholder {{SAGE_DB}} por el nombre real que pasa
--   Delphi al arrancar (DMPlanner lee el INI y lo invoca).
--
--   Asi:
--     - El cliente puede editar la funcion al SQL Management Studio si quiere
--       personalizar el filtro (p.ej. anadir centros/operarios excluidos).
--     - No hay dynamic SQL en tiempo de ejecucion: la TVF queda compilada con
--       el nombre real de la BD Sage.
--     - Es idempotente: Delphi puede llamar al sp cada arranque.
--
-- Contrato de la TVF:
--   SELECT NumOFsNuevas, NumOTsNuevas, NumOPsNuevas
--   FROM FS_PL_fn_PendingErpOFs(@CodigoEmpresa)
--
--   Devuelve siempre 1 fila. Si el sp de instalacion no se ha ejecutado
--   todavia (placeholder), las 3 columnas devuelven 0.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------------
-- 1. FS_PL_fn_PendingErpOFs  (cuerpo provisional - retorna 0)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('dbo.FS_PL_fn_PendingErpOFs', 'IF') IS NOT NULL
    DROP FUNCTION dbo.FS_PL_fn_PendingErpOFs;
GO

CREATE FUNCTION dbo.FS_PL_fn_PendingErpOFs(@CodigoEmpresa SMALLINT)
RETURNS TABLE
AS
RETURN
(
    -- Body provisional: retorna 0 hasta que FS_PL_sp_InstallTvfPendingErp
    -- lo reemplace por el body real apuntando a la BD Sage configurada.
    SELECT
        CAST(0 AS INT) AS NumOFsNuevas,
        CAST(0 AS INT) AS NumOTsNuevas,
        CAST(0 AS INT) AS NumOPsNuevas
);
GO

-- ---------------------------------------------------------------------------
-- 2. FS_PL_sp_InstallTvfPendingErp - recompila la TVF con el nombre real
-- ---------------------------------------------------------------------------
IF OBJECT_ID('dbo.FS_PL_sp_InstallTvfPendingErp', 'P') IS NOT NULL
    DROP PROCEDURE dbo.FS_PL_sp_InstallTvfPendingErp;
GO

CREATE PROCEDURE dbo.FS_PL_sp_InstallTvfPendingErp
    @SageDbName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validacion basica del nombre de BD (evita injection trivial).
    IF @SageDbName IS NULL OR LEN(@SageDbName) = 0
    BEGIN
        RAISERROR('SageDbName vacio.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @SageDbName)
    BEGIN
        RAISERROR('La BD "%s" no existe en este servidor.', 16, 1, @SageDbName);
        RETURN;
    END;

    -- Quote del nombre para incluirlo en el ALTER FUNCTION.
    DECLARE @QSage NVARCHAR(258) = QUOTENAME(@SageDbName);

    DECLARE @Sql NVARCHAR(MAX) = N'
ALTER FUNCTION dbo.FS_PL_fn_PendingErpOFs(@CodigoEmpresa SMALLINT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        (SELECT COUNT(*)
           FROM ' + @QSage + N'.dbo.OrdenesFabricacion sof
          WHERE sof.CodigoEmpresa = @CodigoEmpresa
            AND sof.EstadoOF IN (0, 1)
            AND NOT EXISTS (
                  SELECT 1 FROM dbo.FS_PL_Raw_Item ri
                   WHERE ri.CodigoEmpresa = @CodigoEmpresa
                     AND ri.TipoOrigen = ''OF ''
                     AND ri.Nivel = 1
                     AND ri.Activo = 1
                     AND ri.ClaveERP COLLATE DATABASE_DEFAULT = (''OF|'' +
                         CAST(sof.EjercicioFabricacion AS NVARCHAR(10)) + ''|'' +
                         LTRIM(RTRIM(ISNULL(sof.SerieFabricacion, ''''))) + ''|'' +
                         CAST(sof.NumeroFabricacion AS NVARCHAR(20))) COLLATE DATABASE_DEFAULT)
        ) AS NumOFsNuevas,

        (SELECT COUNT(*)
           FROM ' + @QSage + N'.dbo.OrdenesTrabajo sot
          WHERE sot.CodigoEmpresa = @CodigoEmpresa
            AND sot.EstadoOT IN (0, 1)
            AND NOT EXISTS (
                  SELECT 1 FROM dbo.FS_PL_Raw_Item ri
                   WHERE ri.CodigoEmpresa = @CodigoEmpresa
                     AND ri.TipoOrigen = ''OF ''
                     AND ri.Nivel = 2
                     AND ri.Activo = 1
                     AND ri.ClaveERP COLLATE DATABASE_DEFAULT = (''OT|'' +
                         CAST(sot.EjercicioTrabajo AS NVARCHAR(10)) + ''|'' +
                         CAST(sot.NumeroTrabajo AS NVARCHAR(20))) COLLATE DATABASE_DEFAULT)
        ) AS NumOTsNuevas,

        (SELECT COUNT(*)
           FROM ' + @QSage + N'.dbo.OperacionesOT sop
           INNER JOIN ' + @QSage + N'.dbo.OrdenesTrabajo sot
              ON sot.CodigoEmpresa = sop.CodigoEmpresa
             AND sot.EjercicioTrabajo = sop.EjercicioTrabajo
             AND sot.NumeroTrabajo = sop.NumeroTrabajo
          WHERE sop.CodigoEmpresa = @CodigoEmpresa
            AND sop.EstadoOperacion IN (0, 1)
            AND sot.EstadoOT IN (0, 1)
            AND NOT EXISTS (
                  SELECT 1 FROM dbo.FS_PL_Raw_Item ri
                   WHERE ri.CodigoEmpresa = @CodigoEmpresa
                     AND ri.TipoOrigen = ''OF ''
                     AND ri.Nivel = 3
                     AND ri.Activo = 1
                     AND ri.ClaveERP COLLATE DATABASE_DEFAULT = (''OP|'' +
                         CAST(sop.EjercicioTrabajo AS NVARCHAR(10)) + ''|'' +
                         CAST(sop.NumeroTrabajo AS NVARCHAR(20)) + ''|'' +
                         CAST(sop.Orden AS NVARCHAR(20))) COLLATE DATABASE_DEFAULT)
        ) AS NumOPsNuevas
);';

    EXEC sp_executesql @Sql;
END;
GO
