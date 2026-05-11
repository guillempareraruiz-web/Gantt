-- ============================================================================
-- V019 - Finite Capacity Operaris
-- ============================================================================
-- Soporte para form uFiniteCapacityOperaris (planificador finito por operario):
--   1. FS_PL_OperationType: paralelismo por operacion tipo (modelo PRO C)
--   2. FS_PL_OperatorAbsence: ausencias del operario
--   3. FS_PL_OperatorSkill: nivel y factor de eficiencia
--   4. FS_PL_OperatorAssignment: bloqueo (lock) de asignacion
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Tipos de operacion: paralelismo y rendimientos decrecientes
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_OperationType')
CREATE TABLE FS_PL_OperationType (
    CodigoEmpresa         SMALLINT      NOT NULL,
    Operacion             NVARCHAR(100) NOT NULL,
    MaxOperariosParalelos INT           NOT NULL DEFAULT 1,
    FactorParalelismo     DECIMAL(5,4)  NOT NULL DEFAULT 1.0000,
    Descripcion           NVARCHAR(500) NULL,
    CONSTRAINT PK_FS_PL_OperationType PRIMARY KEY (CodigoEmpresa, Operacion)
);
GO

-- ----------------------------------------------------------------------------
-- 2. Ausencias del operario (vacaciones, baja, formacion, permiso, otros)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_OperatorAbsence')
CREATE TABLE FS_PL_OperatorAbsence (
    CodigoEmpresa   SMALLINT      NOT NULL,
    AbsenceId       INT IDENTITY(1,1) NOT NULL,
    OperatorId      INT           NOT NULL,
    FechaInicio     DATETIME2     NOT NULL,
    FechaFin        DATETIME2     NOT NULL,
    Tipo            TINYINT       NOT NULL DEFAULT 0,
        -- 0=Vacaciones, 1=Baja, 2=Formacion, 3=Permiso, 4=Otros
    Descripcion     NVARCHAR(200) NULL,
    CONSTRAINT PK_FS_PL_OperatorAbsence PRIMARY KEY (CodigoEmpresa, AbsenceId),
    CONSTRAINT FK_FS_PL_OpAbs_Op FOREIGN KEY (CodigoEmpresa, OperatorId)
        REFERENCES FS_PL_Operator(CodigoEmpresa, OperatorId) ON DELETE CASCADE
);
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_FS_PL_OperatorAbsence_Op_Fecha'
      AND object_id = OBJECT_ID('FS_PL_OperatorAbsence')
)
CREATE INDEX IX_FS_PL_OperatorAbsence_Op_Fecha
    ON FS_PL_OperatorAbsence(CodigoEmpresa, OperatorId, FechaInicio, FechaFin);
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE Name = 'EsHoraria' AND Object_ID = Object_ID('FS_PL_OperatorAbsence')
)
ALTER TABLE FS_PL_OperatorAbsence
    ADD EsHoraria BIT NOT NULL DEFAULT 0;
        -- 0 = ausencia de d'ia(s) completo(s)
        -- 1 = tramo horario en un solo d'ia (FechaInicio y FechaFin con HH:mm reales)
GO

-- ----------------------------------------------------------------------------
-- 3. Nivel y eficiencia en skills
-- ----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE Name = 'Nivel' AND Object_ID = Object_ID('FS_PL_OperatorSkill')
)
ALTER TABLE FS_PL_OperatorSkill
    ADD Nivel TINYINT NOT NULL DEFAULT 2;
        -- 0=Aprendiz, 1=Junior, 2=Senior (default), 3=Experto
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE Name = 'FactorEficiencia' AND Object_ID = Object_ID('FS_PL_OperatorSkill')
)
ALTER TABLE FS_PL_OperatorSkill
    ADD FactorEficiencia DECIMAL(5,4) NOT NULL DEFAULT 1.0000;
        -- 1.3 = aprendiz tarda mas; 0.85 = experto va mas rapido
        -- En v1 solo se persiste; el calculo de duracion lo aplicara v1.1
GO

-- ----------------------------------------------------------------------------
-- 4. Lock de asignacion
-- ----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE Name = 'IsLocked' AND Object_ID = Object_ID('FS_PL_OperatorAssignment')
)
ALTER TABLE FS_PL_OperatorAssignment
    ADD IsLocked BIT NOT NULL DEFAULT 0;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE Name = 'LockedBy' AND Object_ID = Object_ID('FS_PL_OperatorAssignment')
)
ALTER TABLE FS_PL_OperatorAssignment
    ADD LockedBy NVARCHAR(100) NULL;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE Name = 'LockedAt' AND Object_ID = Object_ID('FS_PL_OperatorAssignment')
)
ALTER TABLE FS_PL_OperatorAssignment
    ADD LockedAt DATETIME2 NULL;
GO
