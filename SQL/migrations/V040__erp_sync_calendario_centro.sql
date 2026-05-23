-- ===========================================================================
-- V040 - FS_PL_ShiftModelAssignment (storage de calendario por centro)
--
-- Esta tabla almacena la asignacion dinamica (centro x rango fechas) -> modelo
-- horario que retorna el ERP (Sage: CalendarioCentro - una fila por dia/centro).
-- Para evitar miles de filas, la sincronizacion comprime dias consecutivos con
-- el mismo modelo en rangos (FechaDesde, FechaHasta).
--
-- IMPORTANTE: storage only. El motor de planificacion (uCentreCalendar /
-- uBacklogScheduler / uFiniteCapacityPlanner) NO consulta esta tabla todavia
-- - sigue usando el calendario fijo por centro. Esta tabla queda como log
-- trazable y preparada para una eventual fase 2 donde el motor resolveria el
-- modelo aplicable por fecha.
--
-- PK: combinacion natural (Empresa, CenterId, FechaDesde). Permite tener
-- varios rangos por centro a lo largo del tiempo. No hay solapamiento por
-- diseno: la sincronizacion borra y reinserta los rangos del periodo
-- importado al volver a sincronizar.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_ShiftModelAssignment')
CREATE TABLE FS_PL_ShiftModelAssignment (
    CodigoEmpresa     SMALLINT      NOT NULL,
    CenterId          INT           NOT NULL,
    FechaDesde        DATE          NOT NULL,
    FechaHasta        DATE          NOT NULL,
    ShiftModelId      INT           NOT NULL,
    DuracionHoras     DECIMAL(6,2)  NOT NULL CONSTRAINT DF_FS_PL_SMA_Dur DEFAULT 0,
    DuracionDescanso  DECIMAL(6,2)  NOT NULL CONSTRAINT DF_FS_PL_SMA_Desc DEFAULT 0,
    Source            NVARCHAR(20)  NOT NULL CONSTRAINT DF_FS_PL_SMA_Source DEFAULT 'ERP',
    ErpSistema        NVARCHAR(30)  NULL,
    LastErpHash       NVARCHAR(64)  NULL,
    LastErpSyncAt     DATETIME2     NULL,
    CONSTRAINT PK_FS_PL_ShiftModelAssignment PRIMARY KEY (CodigoEmpresa, CenterId, FechaDesde),
    CONSTRAINT FK_FS_PL_SMA_Center FOREIGN KEY (CodigoEmpresa, CenterId)
        REFERENCES FS_PL_Center(CodigoEmpresa, CenterId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_SMA_Model FOREIGN KEY (CodigoEmpresa, ShiftModelId)
        REFERENCES FS_PL_ShiftModel(CodigoEmpresa, ShiftModelId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_SMA_CenterFechas'
                 AND object_id = OBJECT_ID('FS_PL_ShiftModelAssignment'))
CREATE NONCLUSTERED INDEX IX_FS_PL_SMA_CenterFechas
    ON FS_PL_ShiftModelAssignment (CodigoEmpresa, CenterId, FechaDesde, FechaHasta)
    INCLUDE (ShiftModelId);
GO
