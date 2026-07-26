-- =============================================================================
-- V082 - Esfuerzo (triada duracion/trabajo/unidades), restricciones completas
--        y LINEA BASE del modulo de Ingenieria (paradigma TAREAS)
-- =============================================================================
-- Cierra tres huecos del modulo de Proyectos:
--
--   1. TRIADA DE ESFUERZO. Hasta ahora habia tres numeros que no se hablaban:
--        FS_PL_Node.DuracionMin        tiempo de CALENDARIO que ocupa la tarea
--        FS_PL_TaskDetail.HorasEstimadas  TRABAJO que cuesta hacerla
--        FS_PL_TaskOperario.Dedicacion    % de jornada de cada persona
--      El motor solo leia el primero, asi que el usuario rellenaba campos que
--      no hacian nada. La relacion que los liga es la de MS Project:
--
--            Trabajo = Duracion x SUM(Dedicacion de los operarios)
--
--      Con tres variables y una ecuacion hay que decidir cual se despeja al
--      tocar las otras: eso es TipoTarea (fija duracion / trabajo / unidades).
--
--   2. RESTRICCIONES COMPLETAS. ConstraintKind (V078) solo admitia 0/1/2
--      (ASAP, No antes de, Fecha fija). Se amplia al juego de MS Project.
--
--   3. LINEA BASE. Congelar el plan aprobado para poder medir la desviacion
--      contra el plan actual (que el motor recalcula de continuo).
--
-- Aditivo e idempotente. Los defaults dejan el comportamiento anterior intacto:
-- TipoTarea = 0 (duracion fija) es exactamente como se venia comportando.
-- =============================================================================

-- ---- 1. Triada de esfuerzo --------------------------------------------------

-- Que magnitud queda FIJA al recalcular las otras dos.
--   0 = Duracion fija  : cambiar operarios reparte el mismo trabajo (default)
--   1 = Trabajo fijo   : cambiar operarios acorta/alarga la duracion
--   2 = Unidades fijas : cambiar el trabajo alarga la duracion
IF COL_LENGTH('FS_PL_Node', 'TipoTarea') IS NULL
BEGIN
    ALTER TABLE FS_PL_Node ADD TipoTarea TINYINT NOT NULL
        CONSTRAINT DF_FS_PL_Node_TipoTarea DEFAULT (0);
END
GO

-- Trabajo planificado, en MINUTOS (la UI lo pide y lo muestra en horas).
--
-- Por que aqui y no reutilizar TaskDetail.HorasEstimadas: la ficha (V080) es
-- OPCIONAL y una tarea sin ficha es valida. El trabajo entra ahora en la
-- ecuacion del motor, asi que tiene que vivir junto a DuracionMin, en la misma
-- fila y con el mismo ciclo de vida. HorasEstimadas queda como la estimacion
-- inicial del responsable (lo que se creia que costaria); TrabajoMin es lo que
-- el plan dice que cuesta. Divergir es informacion, no un error.
IF COL_LENGTH('FS_PL_Node', 'TrabajoMin') IS NULL
BEGIN
    ALTER TABLE FS_PL_Node ADD TrabajoMin DECIMAL(12,2) NULL;
END
GO

-- Poblar el trabajo de las tareas que ya existen: sin operarios asignados la
-- unica lectura sensata es "una persona a jornada completa", es decir,
-- Trabajo = Duracion. Con operarios, se reparte segun su dedicacion.
-- NULL significa "nunca calculado"; despues de esto ya no queda ninguno.
UPDATE n
   SET TrabajoMin = ROUND(
        n.DuracionMin * ISNULL((
            SELECT SUM(o.Dedicacion) / 100.0
              FROM FS_PL_TaskOperario o
             WHERE o.CodigoEmpresa = n.CodigoEmpresa
               AND o.NodeId        = n.NodeId
        ), 1.0), 2)
  FROM FS_PL_Node n
 WHERE n.TrabajoMin IS NULL;
GO

-- ---- 2. Restricciones completas (MS Project) --------------------------------
--
-- V078 dejo ConstraintKind con 0/1/2. Se amplia:
--   0 = ASAP  Lo antes posible          (default, flexible)
--   1 = SNET  No comenzar antes del     (semiflexible)
--   2 = MSO   Debe comenzar el          (rigida; era "Fecha fija")
--   3 = ALAP  Lo mas tarde posible      (flexible, se calcula hacia atras)
--   4 = SNLT  No comenzar despues del   (semiflexible)
--   5 = FNET  No finalizar antes del    (semiflexible)
--   6 = FNLT  No finalizar despues del  (semiflexible)
--   7 = MFO   Debe finalizar el         (rigida)
--
-- Los valores 0/1/2 NO cambian de significado: los datos existentes siguen
-- siendo validos sin tocarlos.
IF EXISTS (SELECT 1 FROM sys.check_constraints
            WHERE name = 'CK_FS_PL_Node_ConstraintKind')
BEGIN
    ALTER TABLE FS_PL_Node DROP CONSTRAINT CK_FS_PL_Node_ConstraintKind;
END
GO

ALTER TABLE FS_PL_Node WITH NOCHECK ADD CONSTRAINT CK_FS_PL_Node_ConstraintKind
    CHECK (ConstraintKind IS NULL OR ConstraintKind BETWEEN 0 AND 7);
GO

-- ---- 3. Linea base ----------------------------------------------------------
--
-- Una linea base es una FOTO del plan en un instante, para medir contra ella.
-- Se guarda por tarea y no como un blob del proyecto entero para poder
-- comparar tarea a tarea sin deserializar nada, y para que sobreviva a que se
-- anadan o borren tareas despues de fijarla (las nuevas simplemente no tienen
-- linea base, que es la lectura correcta: no estaban en el plan aprobado).
--
-- BaselineId permite varias lineas base por proyecto (MS Project admite 11).
-- La 0 es la principal, que es la que compara la vista por defecto.
IF OBJECT_ID('FS_PL_TaskBaseline', 'U') IS NULL
BEGIN
    CREATE TABLE FS_PL_TaskBaseline (
        CodigoEmpresa   SMALLINT      NOT NULL,
        ProjectId       INT           NOT NULL,
        BaselineId      TINYINT       NOT NULL
            CONSTRAINT DF_FS_PL_TaskBaseline_BaselineId DEFAULT (0),
        NodeId          INT           NOT NULL,

        -- La foto: fechas, duracion y trabajo tal como estaban al fijarla.
        FechaInicio     DATETIME2     NULL,
        FechaFin        DATETIME2     NULL,
        DuracionMin     DECIMAL(12,2) NULL,
        TrabajoMin      DECIMAL(12,2) NULL,

        CONSTRAINT PK_FS_PL_TaskBaseline
            PRIMARY KEY (CodigoEmpresa, ProjectId, BaselineId, NodeId),
        -- Si se borra la tarea, su linea base se va con ella: comparar contra
        -- la foto de algo que ya no existe no significa nada.
        CONSTRAINT FK_FS_PL_TaskBaseline_Node
            FOREIGN KEY (CodigoEmpresa, NodeId)
            REFERENCES FS_PL_Node(CodigoEmpresa, NodeId) ON DELETE CASCADE
    );
END
GO

-- Cabecera: cuando se fijo, quien y con que nombre. Sin esto una linea base es
-- un monton de fechas sin contexto y nadie se atreve a borrarla ni a fiarse.
IF OBJECT_ID('FS_PL_Baseline', 'U') IS NULL
BEGIN
    CREATE TABLE FS_PL_Baseline (
        CodigoEmpresa   SMALLINT      NOT NULL,
        ProjectId       INT           NOT NULL,
        BaselineId      TINYINT       NOT NULL,

        Nombre          NVARCHAR(100) NULL,
        FijadaEn        DATETIME2     NOT NULL
            CONSTRAINT DF_FS_PL_Baseline_FijadaEn DEFAULT (SYSDATETIME()),
        FijadaPor       INT           NULL,
        NumTareas       INT           NOT NULL
            CONSTRAINT DF_FS_PL_Baseline_NumTareas DEFAULT (0),

        CONSTRAINT PK_FS_PL_Baseline
            PRIMARY KEY (CodigoEmpresa, ProjectId, BaselineId),
        CONSTRAINT FK_FS_PL_Baseline_Project
            FOREIGN KEY (CodigoEmpresa, ProjectId)
            REFERENCES FS_PL_Project(CodigoEmpresa, ProjectId)
    );
END
GO

-- ---- 4. Vista de desviacion contra la linea base principal ------------------
--
-- Encapsula el LEFT JOIN y el signo de las desviaciones para que ni la vista ni
-- los informes tengan que repetir el criterio: POSITIVO = va peor que el plan
-- (mas tarde, mas trabajo). Solo la linea base 0 (la principal).
IF OBJECT_ID('FS_PL_V_TaskBaselineDesvio', 'V') IS NOT NULL
    DROP VIEW FS_PL_V_TaskBaselineDesvio;
GO

CREATE VIEW FS_PL_V_TaskBaselineDesvio
AS
SELECT
    n.CodigoEmpresa,
    n.ProjectId,
    n.NodeId,
    n.Caption,
    n.FechaInicio,
    n.FechaFin,
    n.DuracionMin,
    n.TrabajoMin,
    b.FechaInicio  AS BaseInicio,
    b.FechaFin     AS BaseFin,
    b.DuracionMin  AS BaseDuracionMin,
    b.TrabajoMin   AS BaseTrabajoMin,
    -- En DIAS de calendario: es lo que el usuario lee en el grid. El desvio en
    -- minutos laborables lo calcula el motor, que si tiene el calendario.
    CASE WHEN b.FechaInicio IS NULL OR n.FechaInicio IS NULL THEN NULL
         ELSE DATEDIFF(DAY, b.FechaInicio, n.FechaInicio) END AS DesvioInicioDias,
    CASE WHEN b.FechaFin IS NULL OR n.FechaFin IS NULL THEN NULL
         ELSE DATEDIFF(DAY, b.FechaFin, n.FechaFin) END       AS DesvioFinDias,
    CASE WHEN b.TrabajoMin IS NULL OR n.TrabajoMin IS NULL THEN NULL
         ELSE n.TrabajoMin - b.TrabajoMin END                 AS DesvioTrabajoMin,
    CASE WHEN b.NodeId IS NULL THEN 0 ELSE 1 END              AS TieneBaseline
FROM FS_PL_Node n
LEFT JOIN FS_PL_TaskBaseline b
       ON b.CodigoEmpresa = n.CodigoEmpresa
      AND b.ProjectId     = n.ProjectId
      AND b.NodeId        = n.NodeId
      AND b.BaselineId    = 0;
GO
