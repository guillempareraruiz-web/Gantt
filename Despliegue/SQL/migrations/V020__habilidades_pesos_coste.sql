-- ============================================================================
-- V020 - Habilidades, Pesos de Scoring y Coste laboral
-- ============================================================================
-- Soporte para motor de planificacion automatica con scoring (uPlanProdEngine):
--   1. FS_PL_Habilidad: catalogo de habilidades (polivalencia)
--   2. FS_PL_OperarioHabilidad: N:M operario-habilidad con nivel
--   3. FS_PL_OperacionHabilidad: N:M operacion-maestro -> habilidades requeridas
--   4. FS_PL_PesosScoring: perfiles de pesos del scoring (1+ filas)
--   5. Campos coste laboral en FS_PL_Operator: SueldoEurHora + recargos
--
-- El modelo viejo FS_PL_OperatorSkill se mantiene compatible: el codigo
-- delphi (THabilidadRepo.MigrarDesdeOperatorSkill) puede convertirlo
-- en habilidades 1-1 al cargar.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Catalogo de habilidades
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Habilidad')
CREATE TABLE FS_PL_Habilidad (
    CodigoEmpresa SMALLINT      NOT NULL,
    Codigo        NVARCHAR(50)  NOT NULL,
    Descripcion   NVARCHAR(200) NULL,
    CONSTRAINT PK_FS_PL_Habilidad PRIMARY KEY (CodigoEmpresa, Codigo)
);
GO

-- ----------------------------------------------------------------------------
-- 2. Operario tiene habilidades (N:M con nivel)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_OperarioHabilidad')
CREATE TABLE FS_PL_OperarioHabilidad (
    CodigoEmpresa    SMALLINT     NOT NULL,
    OperatorId       INT          NOT NULL,
    CodHabilidad     NVARCHAR(50) NOT NULL,
    Nivel            TINYINT      NOT NULL DEFAULT 2,
        -- 0=Aprendiz, 1=Junior, 2=Senior, 3=Experto
    FactorEficiencia DECIMAL(5,4) NOT NULL DEFAULT 1.0000,
    CONSTRAINT PK_FS_PL_OperarioHabilidad
        PRIMARY KEY (CodigoEmpresa, OperatorId, CodHabilidad),
    CONSTRAINT FK_FS_PL_OpHab_Op FOREIGN KEY (CodigoEmpresa, OperatorId)
        REFERENCES FS_PL_Operator(CodigoEmpresa, OperatorId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_OpHab_Hab FOREIGN KEY (CodigoEmpresa, CodHabilidad)
        REFERENCES FS_PL_Habilidad(CodigoEmpresa, Codigo)
);
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_FS_PL_OperarioHabilidad_Hab'
      AND object_id = OBJECT_ID('FS_PL_OperarioHabilidad')
)
CREATE INDEX IX_FS_PL_OperarioHabilidad_Hab
    ON FS_PL_OperarioHabilidad(CodigoEmpresa, CodHabilidad, Nivel);
GO

-- ----------------------------------------------------------------------------
-- 3. Operacion-maestro exige habilidades (N:M con nivel minimo)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_OperacionHabilidad')
CREATE TABLE FS_PL_OperacionHabilidad (
    CodigoEmpresa SMALLINT      NOT NULL,
    Operacion     NVARCHAR(100) NOT NULL,
    CodHabilidad  NVARCHAR(50)  NOT NULL,
    NivelMinimo   TINYINT       NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_OperacionHabilidad
        PRIMARY KEY (CodigoEmpresa, Operacion, CodHabilidad),
    CONSTRAINT FK_FS_PL_OpcHab_Hab FOREIGN KEY (CodigoEmpresa, CodHabilidad)
        REFERENCES FS_PL_Habilidad(CodigoEmpresa, Codigo)
);
GO

-- ----------------------------------------------------------------------------
-- 4. Pesos de scoring (perfiles guardables)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_PesosScoring')
CREATE TABLE FS_PL_PesosScoring (
    CodigoEmpresa         SMALLINT      NOT NULL,
    PerfilId              INT IDENTITY(1,1) NOT NULL,
    Nombre                NVARCHAR(100) NOT NULL,
    EsActivo              BIT           NOT NULL DEFAULT 0,
        -- 1 = perfil por defecto al lanzar planificacion
    PesoPrioridadOrden    DECIMAL(10,4) NOT NULL DEFAULT 10.0000,
    PesoCompromiso        DECIMAL(10,4) NOT NULL DEFAULT 8.0000,
    PesoNivelCompetencia  DECIMAL(10,4) NOT NULL DEFAULT 3.0000,
    PesoCargaOperario     DECIMAL(10,4) NOT NULL DEFAULT 0.5000,
    PesoContinuidad       DECIMAL(10,4) NOT NULL DEFAULT 4.0000,
    PesoEspera            DECIMAL(10,4) NOT NULL DEFAULT 0.0500,
    PesoCosteManoObra     DECIMAL(10,4) NOT NULL DEFAULT 2.0000,
    Descripcion           NVARCHAR(500) NULL,
    CONSTRAINT PK_FS_PL_PesosScoring PRIMARY KEY (CodigoEmpresa, PerfilId)
);
GO

-- Perfil "Default" semilla (solo si no existe ninguno)
IF NOT EXISTS (
    SELECT * FROM FS_PL_PesosScoring WHERE CodigoEmpresa = 9999
)
INSERT INTO FS_PL_PesosScoring
    (CodigoEmpresa, Nombre, EsActivo, Descripcion)
VALUES
    (9999, 'Default', 1, 'Pesos por defecto del motor de planificacion');
GO

-- ----------------------------------------------------------------------------
-- 5. Coste laboral en FS_PL_Operator
-- ----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE Name = 'SueldoEurHora' AND Object_ID = Object_ID('FS_PL_Operator')
)
ALTER TABLE FS_PL_Operator
    ADD SueldoEurHora DECIMAL(10,2) NOT NULL DEFAULT 0;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE Name = 'RecargoTurnoNoche' AND Object_ID = Object_ID('FS_PL_Operator')
)
ALTER TABLE FS_PL_Operator
    ADD RecargoTurnoNoche DECIMAL(5,4) NOT NULL DEFAULT 1.0000;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns
    WHERE Name = 'RecargoFestivo' AND Object_ID = Object_ID('FS_PL_Operator')
)
ALTER TABLE FS_PL_Operator
    ADD RecargoFestivo DECIMAL(5,4) NOT NULL DEFAULT 1.0000;
GO

-- ----------------------------------------------------------------------------
-- 6. Semilla del catalogo de habilidades coherente con operaciones tipicas
--    (PINTAR, LACAR, FRESAR, TORNEAR, SOLDAR, etc).
-- ----------------------------------------------------------------------------
DECLARE @CE SMALLINT = 9999;

INSERT INTO FS_PL_Habilidad (CodigoEmpresa, Codigo, Descripcion)
SELECT @CE, v.Codigo, v.Descripcion
FROM (VALUES
    ('SEGURIDAD',  'Formacion general en seguridad laboral'),
    ('LECT_PLANO', 'Lectura de planos tecnicos'),
    ('CARRETILLA', 'Carnet de carretillero'),
    ('PINTURA',    'Pintura y lacado (PINTAR, LACAR)'),
    ('MECANIZADO', 'Mecanizado (FRESAR, TORNEAR, TALADRAR, RECTIFICAR)'),
    ('SOLDADURA',  'Soldadura (SOLDAR)'),
    ('MONTAJE',    'Montaje y ensamblaje (MONTAR)'),
    ('ACABADO',    'Pulido y bronceado (PULIR, BRONCEAR)'),
    ('CORTE',      'Corte de material (CORTAR)'),
    ('EMBALAJE',   'Embalaje final (EMBALAR)')
) AS v(Codigo, Descripcion)
WHERE NOT EXISTS (
    SELECT 1 FROM FS_PL_Habilidad h
    WHERE h.CodigoEmpresa = @CE AND h.Codigo = v.Codigo
);
GO

-- Vinculo Operacion -> Habilidades requeridas (idempotente)
DECLARE @CE SMALLINT = 9999;

INSERT INTO FS_PL_OperacionHabilidad (CodigoEmpresa, Operacion, CodHabilidad, NivelMinimo)
SELECT @CE, v.Operacion, v.CodHabilidad, v.NivelMinimo
FROM (VALUES
    -- 0=Aprendiz, 1=Junior, 2=Senior, 3=Experto
    ('PINTAR',     'PINTURA',    1),
    ('LACAR',      'PINTURA',    1),
    ('PULIR',      'ACABADO',    0),
    ('BRONCEAR',   'ACABADO',    1),
    ('EMBALAR',    'EMBALAJE',   0),
    ('MONTAR',     'MONTAJE',    1),
    ('MONTAR',     'LECT_PLANO', 1),
    ('CORTAR',     'CORTE',      1),
    ('CORTAR',     'SEGURIDAD',  0),
    ('TALADRAR',   'MECANIZADO', 0),
    ('TALADRAR',   'SEGURIDAD',  0),
    ('FRESAR',     'MECANIZADO', 2),
    ('FRESAR',     'LECT_PLANO', 1),
    ('FRESAR',     'SEGURIDAD',  0),
    ('TORNEAR',    'MECANIZADO', 2),
    ('TORNEAR',    'LECT_PLANO', 1),
    ('TORNEAR',    'SEGURIDAD',  0),
    ('RECTIFICAR', 'MECANIZADO', 3),
    ('RECTIFICAR', 'LECT_PLANO', 2),
    ('RECTIFICAR', 'SEGURIDAD',  0),
    ('SOLDAR',     'SOLDADURA',  1),
    ('SOLDAR',     'SEGURIDAD',  1)
) AS v(Operacion, CodHabilidad, NivelMinimo)
WHERE NOT EXISTS (
    SELECT 1 FROM FS_PL_OperacionHabilidad oh
    WHERE oh.CodigoEmpresa = @CE
      AND oh.Operacion = v.Operacion
      AND oh.CodHabilidad = v.CodHabilidad
);
GO
