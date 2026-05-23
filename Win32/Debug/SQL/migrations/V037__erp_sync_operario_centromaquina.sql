-- ===========================================================================
-- V037 - Sincronizacion ERP para Operarios y CentroMaquina
--
-- 1) FS_PL_Operator: ampliacion para acoger los campos que devuelve el ERP
--    (cargo, costes, grupo horario, contacto, fechas) + metadatos de sync.
--
-- 2) FS_PL_CentroMaquina: metadatos de sync + atributos especificos de la
--    relacion que vienen del ERP (orden, coste/hora, %correcciones).
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Operator - campos negocio (los que devuelve TOperarioErp)
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_Operator', 'Cargo') IS NULL
    ALTER TABLE FS_PL_Operator ADD Cargo NVARCHAR(100) NULL;
GO

IF COL_LENGTH('FS_PL_Operator', 'CosteHoraNormal') IS NULL
    ALTER TABLE FS_PL_Operator ADD CosteHoraNormal DECIMAL(10,2) NOT NULL
        CONSTRAINT DF_FS_PL_Operator_CostNorm DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Operator', 'CosteHoraExtra') IS NULL
    ALTER TABLE FS_PL_Operator ADD CosteHoraExtra DECIMAL(10,2) NOT NULL
        CONSTRAINT DF_FS_PL_Operator_CostExtra DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Operator', 'GrupoHorarioCodigo') IS NULL
    ALTER TABLE FS_PL_Operator ADD GrupoHorarioCodigo NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_Operator', 'Telefono') IS NULL
    ALTER TABLE FS_PL_Operator ADD Telefono NVARCHAR(50) NULL;
GO

IF COL_LENGTH('FS_PL_Operator', 'Email') IS NULL
    ALTER TABLE FS_PL_Operator ADD Email NVARCHAR(200) NULL;
GO

IF COL_LENGTH('FS_PL_Operator', 'FechaAlta') IS NULL
    ALTER TABLE FS_PL_Operator ADD FechaAlta DATE NULL;
GO

IF COL_LENGTH('FS_PL_Operator', 'FechaBaja') IS NULL
    ALTER TABLE FS_PL_Operator ADD FechaBaja DATE NULL;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Operator - metadatos sync ERP
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_Operator', 'Source') IS NULL
    ALTER TABLE FS_PL_Operator ADD Source NVARCHAR(20) NOT NULL
        CONSTRAINT DF_FS_PL_Operator_Source DEFAULT 'MANUAL';
GO

IF COL_LENGTH('FS_PL_Operator', 'ErpSistema') IS NULL
    ALTER TABLE FS_PL_Operator ADD ErpSistema NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_Operator', 'ErpCodigo') IS NULL
    ALTER TABLE FS_PL_Operator ADD ErpCodigo NVARCHAR(20) NULL;
GO

IF COL_LENGTH('FS_PL_Operator', 'LastErpHash') IS NULL
    ALTER TABLE FS_PL_Operator ADD LastErpHash NVARCHAR(64) NULL;
GO

IF COL_LENGTH('FS_PL_Operator', 'LastErpSyncAt') IS NULL
    ALTER TABLE FS_PL_Operator ADD LastErpSyncAt DATETIME2 NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Operator_ErpCodigo'
                 AND object_id = OBJECT_ID('FS_PL_Operator'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Operator_ErpCodigo
    ON FS_PL_Operator (CodigoEmpresa, Source, ErpCodigo);
GO

-- ---------------------------------------------------------------------------
-- FS_PL_CentroMaquina - atributos del ERP + metadatos sync
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_CentroMaquina', 'OrdenErp') IS NULL
    ALTER TABLE FS_PL_CentroMaquina ADD OrdenErp INT NULL;
GO

IF COL_LENGTH('FS_PL_CentroMaquina', 'CostPerHour') IS NULL
    ALTER TABLE FS_PL_CentroMaquina ADD CostPerHour DECIMAL(10,2) NOT NULL
        CONSTRAINT DF_FS_PL_CentroMaquina_CostHour DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_CentroMaquina', 'PorcentajeCorreccionPrep') IS NULL
    ALTER TABLE FS_PL_CentroMaquina ADD PorcentajeCorreccionPrep DECIMAL(7,2) NOT NULL
        CONSTRAINT DF_FS_PL_CentroMaquina_CorrPrep DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_CentroMaquina', 'PorcentajeCorreccionFab') IS NULL
    ALTER TABLE FS_PL_CentroMaquina ADD PorcentajeCorreccionFab DECIMAL(7,2) NOT NULL
        CONSTRAINT DF_FS_PL_CentroMaquina_CorrFab DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_CentroMaquina', 'Source') IS NULL
    ALTER TABLE FS_PL_CentroMaquina ADD Source NVARCHAR(20) NOT NULL
        CONSTRAINT DF_FS_PL_CentroMaquina_Source DEFAULT 'MANUAL';
GO

IF COL_LENGTH('FS_PL_CentroMaquina', 'ErpSistema') IS NULL
    ALTER TABLE FS_PL_CentroMaquina ADD ErpSistema NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_CentroMaquina', 'LastErpHash') IS NULL
    ALTER TABLE FS_PL_CentroMaquina ADD LastErpHash NVARCHAR(64) NULL;
GO

IF COL_LENGTH('FS_PL_CentroMaquina', 'LastErpSyncAt') IS NULL
    ALTER TABLE FS_PL_CentroMaquina ADD LastErpSyncAt DATETIME2 NULL;
GO
