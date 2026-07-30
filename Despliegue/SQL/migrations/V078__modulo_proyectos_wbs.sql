-- ============================================================================
-- V078 - Cimientos del MODULO DE PROYECTOS (planificacion estilo MS Project).
--
--   Segundo paradigma de planificacion (TAREAS) que convive con el de
--   produccion (RECURSOS). Ver memoria project_gantt_modulo_proyectos.
--
--   Todo ADITIVO con DEFAULT: los planes existentes (produccion) no cambian.
--   Una "tarea de proyecto" y una "operacion de OF" son EL MISMO nodo visto por
--   dos paradigmas, por eso los atributos de tarea van sobre FS_PL_Node y no en
--   una tabla paralela. La duracion se guarda en minutos (DuracionMin, ya
--   existe); la UI del grid WBS la muestra/edita en dias.
--
--   Idempotente: guardas COL_LENGTH / sys.check_constraints.
-- ============================================================================

SET NOCOUNT ON;
GO

-- ---- 1. Atributos de tarea WBS sobre el nodo -------------------------------

-- Arbol WBS de profundidad arbitraria. NULL = tarea raiz del proyecto.
IF COL_LENGTH('FS_PL_Node', 'ParentTaskId') IS NULL
    ALTER TABLE FS_PL_Node ADD ParentTaskId INT NULL;
GO

-- 0 = tarea normal ; 1 = tarea resumen (barra abarca hijos) ; 2 = hito (dur 0).
IF COL_LENGTH('FS_PL_Node', 'TaskKind') IS NULL
    ALTER TABLE FS_PL_Node ADD TaskKind TINYINT NOT NULL
        CONSTRAINT DF_FS_PL_Node_TaskKind DEFAULT 0;
GO

-- Estado del acordeon (rama plegada) por nodo. Persiste el collapse/expand.
IF COL_LENGTH('FS_PL_Node', 'Collapsed') IS NULL
    ALTER TABLE FS_PL_Node ADD Collapsed BIT NOT NULL
        CONSTRAINT DF_FS_PL_Node_Collapsed DEFAULT 0;
GO

-- Tipo de constraint del motor de fechas.
-- 0 = ASAP (lo antes posible) ; 1 = No antes de ConstraintDate ; 2 = Fecha fija.
IF COL_LENGTH('FS_PL_Node', 'ConstraintKind') IS NULL
    ALTER TABLE FS_PL_Node ADD ConstraintKind TINYINT NOT NULL
        CONSTRAINT DF_FS_PL_Node_ConstraintKind DEFAULT 0;
GO

IF COL_LENGTH('FS_PL_Node', 'ConstraintDate') IS NULL
    ALTER TABLE FS_PL_Node ADD ConstraintDate DATETIME2 NULL;
GO

-- Orden entre hermanos dentro de una misma rama del arbol.
IF COL_LENGTH('FS_PL_Node', 'OrdenWBS') IS NULL
    ALTER TABLE FS_PL_Node ADD OrdenWBS INT NOT NULL
        CONSTRAINT DF_FS_PL_Node_OrdenWBS DEFAULT 0;
GO

-- Indice para recorrer el arbol (hijos de un padre) sin escanear la tabla.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Node_ParentTask'
                 AND object_id = OBJECT_ID('FS_PL_Node'))
    CREATE INDEX IX_FS_PL_Node_ParentTask
        ON FS_PL_Node (CodigoEmpresa, ProjectId, ParentTaskId);
GO

-- ---- 2. Lag (adelanto/retardo) en las dependencias -------------------------
-- FS_PL_Dependency ya tiene FromNodeId, ToNodeId, TipoLink (0FS/1SS/2FF/3SF) y
-- PorcentajeDependencia. Falta el lag: +minutos = retardo, -minutos = adelanto.
IF COL_LENGTH('FS_PL_Dependency', 'LagMinutos') IS NULL
    ALTER TABLE FS_PL_Dependency ADD LagMinutos INT NOT NULL
        CONSTRAINT DF_FS_PL_Dependency_Lag DEFAULT 0;
GO

-- ---- 3. Paradigma de planificacion por proyecto ---------------------------
-- RECURSOS = abre en Vista Gantt (produccion, capacidad finita). Por defecto,
-- para no cambiar el comportamiento de los proyectos existentes.
-- TAREAS   = abre en el nuevo modulo de Proyectos (WBS + fechas + dependencias).
IF COL_LENGTH('FS_PL_Project', 'PlanningParadigm') IS NULL
    ALTER TABLE FS_PL_Project ADD PlanningParadigm VARCHAR(10) NOT NULL
        CONSTRAINT DF_FS_PL_Project_Paradigm DEFAULT 'RECURSOS';
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_FS_PL_Project_Paradigm')
    ALTER TABLE FS_PL_Project
        ADD CONSTRAINT CK_FS_PL_Project_Paradigm
            CHECK (PlanningParadigm IN ('RECURSOS','TAREAS'));
GO
