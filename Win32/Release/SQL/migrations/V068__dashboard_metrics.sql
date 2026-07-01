-- ===========================================================================
-- V068 - FS_PL_DashboardMetric: historico diario de los KPIs del Dashboard.
--
-- El panel de control (uDashboard) muestra tarjetas KPI con una sparkline de
-- tendencia. Hasta ahora la serie era SINTETICA (inventada a partir del valor
-- actual). Esta tabla guarda el valor REAL de cada KPI una vez al dia por
-- (empresa, proyecto), para que la sparkline sea historico verdadero.
--
-- Diseno:
--   - Una fila por (CodigoEmpresa, ProjectId, FechaDia).
--   - Columnas = los 7 KPIs del dashboard. Si se anyaden KPIs, se amplia la
--     tabla (patron simple; el volumen es 1 fila/proyecto/dia, trivial).
--   - El dashboard hace UPSERT del dia al abrirse (idempotente): si ya hay fila
--     de hoy, la actualiza con el valor mas reciente; si no, la inserta. Asi el
--     historico se va poblando solo con el uso normal, sin proceso batch.
--   - Lectura: los ultimos N dias (ORDER BY FechaDia) alimentan la sparkline.
--
-- No se toca FS_PL_Snapshot (que solo guarda NodeCount y esta ligada a los
-- puntos de restauracion del plan); este historico es independiente y cubre los
-- 7 KPIs sin deserializar el JSON del plan.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.FS_PL_DashboardMetric', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FS_PL_DashboardMetric (
        CodigoEmpresa     SMALLINT      NOT NULL,
        ProjectId         INT           NOT NULL,
        FechaDia          DATE          NOT NULL,

        -- Los 7 KPIs del dashboard (mismo orden que las tarjetas).
        NodosPlanificados INT           NOT NULL CONSTRAINT DF_DashMetric_Nodos   DEFAULT 0,
        OFsEnPlan         INT           NOT NULL CONSTRAINT DF_DashMetric_OFsPlan  DEFAULT 0,
        OFsPendientes     INT           NOT NULL CONSTRAINT DF_DashMetric_OFsPend  DEFAULT 0,
        OperariosAsignados INT          NOT NULL CONSTRAINT DF_DashMetric_OpAsig   DEFAULT 0,
        CargaPlanificadaH DECIMAL(18,2) NOT NULL CONSTRAINT DF_DashMetric_CargaH   DEFAULT 0,
        SaturacionMedia   DECIMAL(9,2)  NOT NULL CONSTRAINT DF_DashMetric_Satur    DEFAULT 0,
        OFsEnRiesgo       INT           NOT NULL CONSTRAINT DF_DashMetric_Riesgo   DEFAULT 0,
        Salud             INT           NOT NULL CONSTRAINT DF_DashMetric_Salud    DEFAULT 100,

        FechaActualizacion DATETIME     NOT NULL CONSTRAINT DF_DashMetric_FAct     DEFAULT GETDATE(),

        CONSTRAINT PK_FS_PL_DashboardMetric
            PRIMARY KEY (CodigoEmpresa, ProjectId, FechaDia)
    );
END;
GO
