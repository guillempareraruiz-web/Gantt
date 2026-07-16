-- ===========================================================================
-- V072 - Ficha PRO de Utillajes
--
-- Amplia FS_PL_Utillaje (catalogo minimo creado en V034) con los campos que
-- una ficha de utillaje necesita para ser explotable por el planificador:
--
--   * Identificacion    : Fabricante, NumeroSerie, AnyoFabricacion
--   * Estado ciclo vida : Estado (TINYINT, enum TEstadoUtillaje)
--   * Capacidad         : Cantidad (n. de ejemplares intercambiables)
--   * Ubicacion         : CentroActualId (FK a FS_PL_Center)
--   * Tiempos           : TiempoMontaje / TiempoDesmontaje / TiempoAjuste
--   * Vida util         : UnidadVida, ContadorActual, VidaUtilTotal,
--                         FechaProxMantenimiento
--   * Planificacion     : DisponiblePlanificacion
--
-- NOTA IMPORTANTE - Disponible vs DisponiblePlanificacion:
--   'Disponible' (V034) es el flag manual que ya usa el usuario hoy.
--   'DisponiblePlanificacion' es el flag que leera el motor. Se inicializa
--   con el valor de Disponible para no cambiar el significado de los datos
--   existentes. Ver V073 para el uso como recurso secundario.
--
-- Entidad 100% Planner: Sage200 no modela moldes ni utillajes, por lo que
-- NO hay columnas de sincronizacion ERP (ni hash, ni CodigoErp) a proposito.
--
-- Idempotente: se puede reejecutar sin efecto.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- --- Identificacion --------------------------------------------------------
IF COL_LENGTH('FS_PL_Utillaje', 'Fabricante') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD Fabricante NVARCHAR(200) NULL;
GO

IF COL_LENGTH('FS_PL_Utillaje', 'NumeroSerie') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD NumeroSerie NVARCHAR(100) NULL;
GO

IF COL_LENGTH('FS_PL_Utillaje', 'AnyoFabricacion') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD AnyoFabricacion INT NULL;
GO

-- --- Estado del ciclo de vida ----------------------------------------------
-- 0=Disponible 1=Montado 2=Reservado 3=Mantenimiento 4=Averiado 5=Bloqueado 6=Baja
IF COL_LENGTH('FS_PL_Utillaje', 'Estado') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD Estado TINYINT NOT NULL
        CONSTRAINT DF_FS_PL_Utillaje_Estado_P DEFAULT 0;
GO

-- --- Capacidad: numero de ejemplares intercambiables ------------------------
-- Cantidad = 1 -> uso exclusivo (2 nodos a la vez = conflicto).
-- Cantidad = N -> hasta N operaciones simultaneas.
IF COL_LENGTH('FS_PL_Utillaje', 'Cantidad') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD Cantidad INT NOT NULL
        CONSTRAINT DF_FS_PL_Utillaje_Cant_P DEFAULT 1;
GO

-- --- Ubicacion: centro donde esta montado/ubicado ahora ---------------------
IF COL_LENGTH('FS_PL_Utillaje', 'CentroActualId') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD CentroActualId INT NULL;
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FS_PL_Utillaje_Center')
    ALTER TABLE FS_PL_Utillaje ADD CONSTRAINT FK_FS_PL_Utillaje_Center
        FOREIGN KEY (CodigoEmpresa, CentroActualId)
        REFERENCES FS_PL_Center (CodigoEmpresa, CenterId);
GO

-- --- Tiempos de cambio (minutos) -------------------------------------------
IF COL_LENGTH('FS_PL_Utillaje', 'TiempoMontaje') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD TiempoMontaje DECIMAL(8,2) NOT NULL
        CONSTRAINT DF_FS_PL_Utillaje_TM_P DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Utillaje', 'TiempoDesmontaje') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD TiempoDesmontaje DECIMAL(8,2) NOT NULL
        CONSTRAINT DF_FS_PL_Utillaje_TD_P DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Utillaje', 'TiempoAjuste') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD TiempoAjuste DECIMAL(8,2) NOT NULL
        CONSTRAINT DF_FS_PL_Utillaje_TA_P DEFAULT 0;
GO

-- --- Vida util y mantenimiento ---------------------------------------------
-- 0=Ciclos 1=Horas 2=Golpes 3=Piezas  (enum TUnidadVida)
IF COL_LENGTH('FS_PL_Utillaje', 'UnidadVida') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD UnidadVida TINYINT NOT NULL
        CONSTRAINT DF_FS_PL_Utillaje_UV_P DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Utillaje', 'ContadorActual') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD ContadorActual BIGINT NOT NULL
        CONSTRAINT DF_FS_PL_Utillaje_CA_P DEFAULT 0;
GO

-- VidaUtilTotal = 0 -> sin control de vida util.
IF COL_LENGTH('FS_PL_Utillaje', 'VidaUtilTotal') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD VidaUtilTotal BIGINT NOT NULL
        CONSTRAINT DF_FS_PL_Utillaje_VU_P DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Utillaje', 'FechaProxMantenimiento') IS NULL
    ALTER TABLE FS_PL_Utillaje ADD FechaProxMantenimiento DATE NULL;
GO

-- --- Flag que leera el motor de planificacion ------------------------------
IF COL_LENGTH('FS_PL_Utillaje', 'DisponiblePlanificacion') IS NULL
BEGIN
    ALTER TABLE FS_PL_Utillaje ADD DisponiblePlanificacion BIT NOT NULL
        CONSTRAINT DF_FS_PL_Utillaje_DP_P DEFAULT 1;

    -- Arrancar con el mismo criterio que el usuario ya habia fijado a mano.
    EXEC sp_executesql N'UPDATE FS_PL_Utillaje SET DisponiblePlanificacion = Disponible';
END
GO

-- --- Indice para el listado y los desplegables ------------------------------
IF NOT EXISTS (SELECT * FROM sys.indexes
               WHERE name = 'IX_FS_PL_Utillaje_Activo' AND object_id = OBJECT_ID('FS_PL_Utillaje'))
    CREATE INDEX IX_FS_PL_Utillaje_Activo
        ON FS_PL_Utillaje (CodigoEmpresa, Activo, Orden, Codigo);
GO
