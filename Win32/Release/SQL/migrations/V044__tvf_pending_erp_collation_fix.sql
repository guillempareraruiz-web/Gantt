-- ===========================================================================
-- V044 - Fix collation conflict en FS_PL_fn_PendingErpOFs / sp install.
--
-- La V043 comparaba ri.ClaveERP = '...' contra concatenaciones derivadas de
-- columnas Sage. Si la BD Planner y la BD Sage tienen collations distintas
-- (caso Latin1_General_CI_AI vs Modern_Spanish_CI_AS), el motor lanza:
--   "No se puede resolver el conflicto de intercalacion".
--
-- Solucion: forzar COLLATE DATABASE_DEFAULT en los dos lados de la comparacion.
-- Esta migration recrea tanto la TVF (body provisional) como el sp de
-- instalacion con el cuerpo corregido, y al final reaplica el sp con la BD
-- Sage configurada si la TVF anterior ya estaba "instalada" (heuristica:
-- existe el sp y la BD que apunta sigue presente).
--
-- IMPORTANTE: este script no conoce el nombre de la BD Sage (esta al INI de
-- FSPlanner). Por tanto, despues de aplicar V044, Delphi llamara igualmente
-- a InstallTvfPendingErp al arrancar para activar el body real. La TVF queda
-- con body provisional (retorna 0) hasta entonces.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.FS_PL_fn_PendingErpOFs', 'IF') IS NOT NULL
    DROP FUNCTION dbo.FS_PL_fn_PendingErpOFs;
GO

CREATE FUNCTION dbo.FS_PL_fn_PendingErpOFs(@CodigoEmpresa SMALLINT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        CAST(0 AS INT) AS NumOFsNuevas,
        CAST(0 AS INT) AS NumOTsNuevas,
        CAST(0 AS INT) AS NumOPsNuevas
);
GO

IF OBJECT_ID('dbo.FS_PL_sp_InstallTvfPendingErp', 'P') IS NOT NULL
    DROP PROCEDURE dbo.FS_PL_sp_InstallTvfPendingErp;
GO

CREATE PROCEDURE dbo.FS_PL_sp_InstallTvfPendingErp
    @SageDbName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

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
                     AND ri.ClaveERP COLLATE DATABASE_DEFAULT =
                         (''OF|'' +
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
                     AND ri.ClaveERP COLLATE DATABASE_DEFAULT =
                         (''OT|'' +
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
                     AND ri.ClaveERP COLLATE DATABASE_DEFAULT =
                         (''OP|'' +
                          CAST(sop.EjercicioTrabajo AS NVARCHAR(10)) + ''|'' +
                          CAST(sop.NumeroTrabajo AS NVARCHAR(20)) + ''|'' +
                          CAST(sop.Orden AS NVARCHAR(20))) COLLATE DATABASE_DEFAULT)
        ) AS NumOPsNuevas
);';

    EXEC sp_executesql @Sql;
END;
GO
