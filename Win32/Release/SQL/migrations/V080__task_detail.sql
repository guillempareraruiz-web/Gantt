-- =============================================================================
-- V080 - Ficha de TAREA de proyecto (modulo de Ingenieria, paradigma TAREAS)
-- =============================================================================
-- Crea dos tablas ANEXAS a FS_PL_Node con lo que caracteriza a una tarea de
-- ingenieria y que NO tiene equivalente en produccion:
--
--   FS_PL_TaskDetail    1:1 con el nodo. Notas, estado, prioridad, etiqueta,
--                       responsable y horas de esfuerzo estimadas.
--   FS_PL_TaskOperario  N:M. Operarios asignados a la tarea.
--
-- Por que tablas nuevas y no ampliar FS_PL_NodeData: NodeData describe una
-- operacion de produccion (OF, articulo, centro, cantidades, tiempos de ciclo).
-- Una tarea de ingenieria comparte el NODO (fechas, duracion, dependencias)
-- pero no esos atributos, y forzarlos en la misma tabla dejaria la mitad de
-- las columnas siempre a NULL en cada uno de los dos paradigmas.
--
-- Son 1:1 y 1:N OPCIONALES: una tarea sin ficha sigue siendo valida y se
-- comporta como hasta ahora (LEFT JOIN, no INNER).
--
-- ESFUERZO vs DURACION - la distincion importa:
--   DuracionMin (FS_PL_Node) = tiempo de CALENDARIO que ocupa la tarea.
--   HorasEstimadas (aqui)    = TRABAJO real que cuesta hacerla.
--   MinutosInvertidos (V079) = trabajo real ya dedicado.
-- Una tarea puede durar 5 dias de calendario y costar solo 8 horas de trabajo.
--
-- Aditivo e idempotente.
-- =============================================================================

-- ---- 1. Ficha de la tarea (1:1 con el nodo) ---------------------------------
IF OBJECT_ID('FS_PL_TaskDetail', 'U') IS NULL
BEGIN
    CREATE TABLE FS_PL_TaskDetail (
        CodigoEmpresa   SMALLINT       NOT NULL,
        NodeId          INT            NOT NULL,

        -- Texto libre: notas, criterios de aceptacion, incidencias...
        Notas           NVARCHAR(MAX)  NULL,

        -- 0=Pendiente, 1=En curso, 2=Bloqueada, 3=Hecha, 4=Cancelada
        Estado          TINYINT        NOT NULL
            CONSTRAINT DF_FS_PL_TaskDetail_Estado DEFAULT (0),

        -- 0=Baja, 1=Normal, 2=Alta, 3=Critica
        Prioridad       TINYINT        NOT NULL
            CONSTRAINT DF_FS_PL_TaskDetail_Prioridad DEFAULT (1),

        -- Etiqueta libre + color (BGR de TColor, como el resto del planner).
        Etiqueta        NVARCHAR(60)   NULL,
        ColorEtiqueta   INT            NULL,

        -- Responsable principal. Los demas implicados van en FS_PL_TaskOperario.
        ResponsableId   INT            NULL,

        -- Esfuerzo estimado en minutos (la UI lo pide en horas). Distinto de
        -- DuracionMin: ver la nota de cabecera.
        HorasEstimadas  DECIMAL(12,2)  NOT NULL
            CONSTRAINT DF_FS_PL_TaskDetail_HorasEst DEFAULT (0),

        UpdatedBy       NVARCHAR(64)   NULL,
        UpdatedAt       DATETIME2      NULL,

        CONSTRAINT PK_FS_PL_TaskDetail PRIMARY KEY (CodigoEmpresa, NodeId),
        -- La PK de FS_PL_Node es COMPUESTA (CodigoEmpresa, NodeId): la FK debe
        -- referenciar las dos columnas.
        CONSTRAINT FK_FS_PL_TaskDetail_Node
            FOREIGN KEY (CodigoEmpresa, NodeId)
            REFERENCES FS_PL_Node (CodigoEmpresa, NodeId) ON DELETE CASCADE,
        CONSTRAINT CK_FS_PL_TaskDetail_Estado CHECK (Estado BETWEEN 0 AND 4),
        CONSTRAINT CK_FS_PL_TaskDetail_Prioridad CHECK (Prioridad BETWEEN 0 AND 3),
        CONSTRAINT CK_FS_PL_TaskDetail_HorasEst CHECK (HorasEstimadas >= 0)
    );

    PRINT 'V080: FS_PL_TaskDetail creada.';
END
ELSE
    PRINT 'V080: FS_PL_TaskDetail ya existia.';
GO

-- ---- 2. Operarios asignados a la tarea (N:M) --------------------------------
IF OBJECT_ID('FS_PL_TaskOperario', 'U') IS NULL
BEGIN
    CREATE TABLE FS_PL_TaskOperario (
        CodigoEmpresa   SMALLINT      NOT NULL,
        NodeId          INT           NOT NULL,
        OperatorId      INT           NOT NULL,

        -- % de dedicacion del operario a esta tarea (100 = jornada completa).
        -- Es lo que permitira construir el mapa de carga por persona.
        Dedicacion      DECIMAL(5,2)  NOT NULL
            CONSTRAINT DF_FS_PL_TaskOperario_Dedic DEFAULT (100),

        -- Minutos realmente dedicados por ESTE operario. La suma no tiene por
        -- que cuadrar con FS_PL_Node.MinutosInvertidos: ese es el total de la
        -- tarea y puede imputarse sin desglosar por persona.
        MinutosImputados DECIMAL(12,2) NOT NULL
            CONSTRAINT DF_FS_PL_TaskOperario_MinImp DEFAULT (0),

        CONSTRAINT PK_FS_PL_TaskOperario
            PRIMARY KEY (CodigoEmpresa, NodeId, OperatorId),
        CONSTRAINT FK_FS_PL_TaskOperario_Node
            FOREIGN KEY (CodigoEmpresa, NodeId)
            REFERENCES FS_PL_Node (CodigoEmpresa, NodeId) ON DELETE CASCADE,
        CONSTRAINT FK_FS_PL_TaskOperario_Op FOREIGN KEY (CodigoEmpresa, OperatorId)
            REFERENCES FS_PL_Operator (CodigoEmpresa, OperatorId),
        CONSTRAINT CK_FS_PL_TaskOperario_Dedic
            CHECK (Dedicacion > 0 AND Dedicacion <= 100),
        CONSTRAINT CK_FS_PL_TaskOperario_MinImp CHECK (MinutosImputados >= 0)
    );

    -- Para el mapa de carga: "todas las tareas de este operario".
    CREATE INDEX IX_FS_PL_TaskOperario_Op
        ON FS_PL_TaskOperario (CodigoEmpresa, OperatorId);

    PRINT 'V080: FS_PL_TaskOperario creada.';
END
ELSE
    PRINT 'V080: FS_PL_TaskOperario ya existia.';
GO
