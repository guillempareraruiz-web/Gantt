-- ===========================================================================
-- V032 - Campos PRO para Centro, Maquina y CentroMaquina
--
-- Anyade los campos minimos que un APS profesional necesita para que el
-- motor de planificacion pueda hacer calculos realistas (capacidad, coste,
-- eficiencia, estado operativo, cuello de botella, prioridad asignacion).
--
-- Iteracion 1 (fitxa tecnica y rendimiento) +
-- Iteracion 2 (motor / DBR) +
-- Iteracion 3 (manteniment basic)
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Center - ampliacion
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_Center', 'TipoCentro') IS NULL
    ALTER TABLE FS_PL_Center ADD TipoCentro NVARCHAR(50) NULL;
GO

IF COL_LENGTH('FS_PL_Center', 'EfficiencyFactor') IS NULL
    ALTER TABLE FS_PL_Center ADD EfficiencyFactor DECIMAL(5,2) NOT NULL
        CONSTRAINT DF_FS_PL_Center_Efficiency DEFAULT 1.00;
GO

IF COL_LENGTH('FS_PL_Center', 'CostPerHour') IS NULL
    ALTER TABLE FS_PL_Center ADD CostPerHour DECIMAL(10,2) NOT NULL
        CONSTRAINT DF_FS_PL_Center_CostHour DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Center', 'SetupTimeDefault') IS NULL
    ALTER TABLE FS_PL_Center ADD SetupTimeDefault INT NOT NULL
        CONSTRAINT DF_FS_PL_Center_SetupTime DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Center', 'PlanningHorizonDays') IS NULL
    ALTER TABLE FS_PL_Center ADD PlanningHorizonDays INT NOT NULL
        CONSTRAINT DF_FS_PL_Center_Horizon DEFAULT 90;
GO

IF COL_LENGTH('FS_PL_Center', 'Ubicacion') IS NULL
    ALTER TABLE FS_PL_Center ADD Ubicacion NVARCHAR(100) NULL;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Maquina - ampliacion (fitxa tecnica + capacitat + planificacio + manteniment)
-- ---------------------------------------------------------------------------

-- Fitxa tecnica
IF COL_LENGTH('FS_PL_Maquina', 'Descripcion') IS NULL
    ALTER TABLE FS_PL_Maquina ADD Descripcion NVARCHAR(500) NULL;
GO

IF COL_LENGTH('FS_PL_Maquina', 'Modelo') IS NULL
    ALTER TABLE FS_PL_Maquina ADD Modelo NVARCHAR(100) NULL;
GO

IF COL_LENGTH('FS_PL_Maquina', 'NumeroSerie') IS NULL
    ALTER TABLE FS_PL_Maquina ADD NumeroSerie NVARCHAR(100) NULL;
GO

IF COL_LENGTH('FS_PL_Maquina', 'Fabricante') IS NULL
    ALTER TABLE FS_PL_Maquina ADD Fabricante NVARCHAR(100) NULL;
GO

IF COL_LENGTH('FS_PL_Maquina', 'TipoMaquina') IS NULL
    ALTER TABLE FS_PL_Maquina ADD TipoMaquina NVARCHAR(50) NULL;
GO

IF COL_LENGTH('FS_PL_Maquina', 'FechaPuestaEnMarcha') IS NULL
    ALTER TABLE FS_PL_Maquina ADD FechaPuestaEnMarcha DATE NULL;
GO

-- Capacitat i rendiment
IF COL_LENGTH('FS_PL_Maquina', 'EfficiencyFactor') IS NULL
    ALTER TABLE FS_PL_Maquina ADD EfficiencyFactor DECIMAL(5,2) NOT NULL
        CONSTRAINT DF_FS_PL_Maquina_Efficiency DEFAULT 1.00;
GO

IF COL_LENGTH('FS_PL_Maquina', 'MaxLoadPercent') IS NULL
    ALTER TABLE FS_PL_Maquina ADD MaxLoadPercent SMALLINT NOT NULL
        CONSTRAINT DF_FS_PL_Maquina_MaxLoad DEFAULT 100;
GO

IF COL_LENGTH('FS_PL_Maquina', 'CostPerHour') IS NULL
    ALTER TABLE FS_PL_Maquina ADD CostPerHour DECIMAL(10,2) NOT NULL
        CONSTRAINT DF_FS_PL_Maquina_CostHour DEFAULT 0;
GO

-- Planificacio
IF COL_LENGTH('FS_PL_Maquina', 'EsPlanificable') IS NULL
    ALTER TABLE FS_PL_Maquina ADD EsPlanificable BIT NOT NULL
        CONSTRAINT DF_FS_PL_Maquina_EsPlanif DEFAULT 1;
GO

IF COL_LENGTH('FS_PL_Maquina', 'EsCuelloBotella') IS NULL
    ALTER TABLE FS_PL_Maquina ADD EsCuelloBotella BIT NOT NULL
        CONSTRAINT DF_FS_PL_Maquina_Botella DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Maquina', 'PrioridadAsignacion') IS NULL
    ALTER TABLE FS_PL_Maquina ADD PrioridadAsignacion INT NOT NULL
        CONSTRAINT DF_FS_PL_Maquina_Prioridad DEFAULT 100;
GO

-- 0 = Disponible, 1 = Manteniment, 2 = Avariada, 3 = Baja
IF COL_LENGTH('FS_PL_Maquina', 'EstadoOperativo') IS NULL
    ALTER TABLE FS_PL_Maquina ADD EstadoOperativo SMALLINT NOT NULL
        CONSTRAINT DF_FS_PL_Maquina_Estado DEFAULT 0;
GO

-- Manteniment
IF COL_LENGTH('FS_PL_Maquina', 'HorasFuncionamiento') IS NULL
    ALTER TABLE FS_PL_Maquina ADD HorasFuncionamiento DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_FS_PL_Maquina_Horas DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Maquina', 'FechaProxRevision') IS NULL
    ALTER TABLE FS_PL_Maquina ADD FechaProxRevision DATE NULL;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_CentroMaquina - atributos de la relacion
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_CentroMaquina', 'EsPrincipal') IS NULL
    ALTER TABLE FS_PL_CentroMaquina ADD EsPrincipal BIT NOT NULL
        CONSTRAINT DF_FS_PL_CentroMaquina_Principal DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_CentroMaquina', 'Prioridad') IS NULL
    ALTER TABLE FS_PL_CentroMaquina ADD Prioridad INT NOT NULL
        CONSTRAINT DF_FS_PL_CentroMaquina_Prioridad DEFAULT 100;
GO
