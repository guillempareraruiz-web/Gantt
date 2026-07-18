-- ============================================================================
-- SEED (idempotente, reejecutable) - Proyecto DEMO en paradigma TAREAS para el
-- Modulo de Proyectos (estilo MS Project). WBS de ingenieria "Diseno turbina X":
-- fases, subtareas, hitos y dependencias FS/SS con lag.
--
-- NO es una migracion de esquema: son DATOS de demostracion. Reejecutable:
-- primero borra el proyecto demo de proyectos y lo recrea.
--
-- IMPORTANTE: ProjectId, NodeId y DependencyId son IDENTITY. Los nodos del
-- modulo de Proyectos viven en la MISMA tabla FS_PL_Node que los de produccion
-- (una tarea de proyecto y una operacion de OF son el mismo nodo visto por dos
-- paradigmas). Por eso NO forzamos ids: dejamos que la BD los genere y mapeamos
-- el numero logico de WBS (1..13) -> NodeId real con una tabla temporal.
--
--   Duracion en MINUTOS (jornada 8h = 480). La UI la mostrara en dias.
--   TaskKind: 0 tarea'+NCHAR(183)+N' 1 resumen'+NCHAR(183)+N' 2 hito.  TipoLink: 0 FS'+NCHAR(183)+N' 1 SS'+NCHAR(183)+N' 2 FF'+NCHAR(183)+N' 3 SF.
-- ============================================================================

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- CodigoEmpresa de trabajo: 9998 (la que usa la app en Debug/Release).
DECLARE @CE SMALLINT = 9998;
DECLARE @Ini DATETIME2 = '2026-08-03 08:00:00';   -- lunes
DECLARE @Jornada INT = 480;

-- ---- 0. Limpieza previa (idempotente) por Codigo de proyecto ---------------
DECLARE @OldPid INT = (SELECT ProjectId FROM FS_PL_Project
                       WHERE CodigoEmpresa=@CE AND Codigo = N'DEMO-PRJ');
IF @OldPid IS NOT NULL
BEGIN
    DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa=@CE AND ProjectId=@OldPid;
    DELETE nd FROM FS_PL_NodeData nd
      JOIN FS_PL_Node n ON n.CodigoEmpresa=nd.CodigoEmpresa AND n.NodeId=nd.NodeId
      WHERE n.CodigoEmpresa=@CE AND n.ProjectId=@OldPid;
    DELETE FROM FS_PL_Node WHERE CodigoEmpresa=@CE AND ProjectId=@OldPid;
    DELETE FROM FS_PL_Project WHERE ProjectId=@OldPid;
END

-- ---- 1. Proyecto demo (paradigma TAREAS) -----------------------------------
INSERT INTO FS_PL_Project (CodigoEmpresa, Codigo, Nombre,
    FechaCreacion, FechaModificacion, Activo, EsMaster, EsEscenario, EsDemo,
    RowMode, NivelAgrupacion, PlanningParadigm)
VALUES (@CE, N'DEMO-PRJ',
    N'Dise'+NCHAR(241)+N'o turbina X (demo proyectos)',
    SYSDATETIME(), SYSDATETIME(), 1, 0, 0, 1,
    'CENTROS', 1, 'TAREAS');
DECLARE @PID INT = SCOPE_IDENTITY();

-- ---- 2. Definicion logica de la WBS ----------------------------------------
-- n = numero logico ; parent = numero logico del padre (NULL raiz)
-- avanceP = fraccion de la duracion ya invertida (V079). Solo en las HOJAS:
-- el avance de los resumenes lo agrega el motor ponderando por duracion.
-- El demo simula un proyecto a medio ejecutar: ingenieria acabada, calculo
-- estructural con una desviacion (1.15 = 15% mas de lo estimado), fabricacion
-- empezada y montaje/entrega aun sin tocar.
DECLARE @T TABLE (
  n INT PRIMARY KEY, parent INT, kind TINYINT, orden INT, cap NVARCHAR(120),
  diaIni INT, durDias DECIMAL(6,2), avanceP DECIMAL(5,3), NodeId INT NULL
);
INSERT INTO @T (n, parent, kind, orden, cap, diaIni, durDias, avanceP) VALUES
 (1,  NULL, 1, 1, N'1'+NCHAR(183)+N' Ingenier'+NCHAR(237)+N'a de detalle',    0,  18, 0),
 (2,  1,    1, 1, N'1.1'+NCHAR(183)+N' C'+NCHAR(225)+N'lculo estructural',    0,   6, 0),
 (3,  2,    0, 1, N'1.1.1'+NCHAR(183)+N' Modelo FEM',                          0,   4, 1.000),
 (4,  2,    0, 2, N'1.1.2'+NCHAR(183)+N' Validaci'+NCHAR(243)+N'n de cargas',  4,   2, 1.150),
 (5,  1,    0, 2, N'1.2'+NCHAR(183)+N' Dise'+NCHAR(241)+N'o mec'+NCHAR(225)+N'nico', 0, 8, 1.000),
 -- Los hitos no consumen tiempo: su avance se queda en 0 (se alcanzan o no,
 -- y eso lo dice la fecha, no las horas invertidas).
 (6,  1,    2, 3, N'Dise'+NCHAR(241)+N'o congelado',              8,   0, 0),
 (7,  NULL, 1, 2, N'2'+NCHAR(183)+N' Aprovisionamiento',                       8,  12, 0),
 (8,  7,    0, 1, N'2.1'+NCHAR(183)+N' Pedido material largo plazo',           8,   2, 1.000),
 (9,  7,    0, 2, N'2.2'+NCHAR(183)+N' Recepci'+NCHAR(243)+N'n de material',  18,   1, 1.000),
 (10, NULL, 1, 3, N'3'+NCHAR(183)+N' Fabricaci'+NCHAR(243)+N'n (genera OFs)',  19,  22, 0),
 (11, 10,   0, 1, N'3.1'+NCHAR(183)+N' Mecanizado',                           19,  12, 0.600),
 (12, 10,   0, 2, N'3.2'+NCHAR(183)+N' Montaje',                              31,  10, 0),
 (13, NULL, 2, 4, N'Entrega',                                    41,   0, 0);

-- ---- 3. Insertar nodos capturando el NodeId real de cada uno ---------------
-- Se insertan de uno en uno (WHILE) para poder mapear n -> NodeId con
-- SCOPE_IDENTITY. Son 13 filas: el coste es irrelevante y evita OUTPUT+MERGE.
DECLARE @n INT = 1, @maxN INT = (SELECT MAX(n) FROM @T);
WHILE @n <= @maxN
BEGIN
    DECLARE @kind TINYINT, @orden INT, @cap NVARCHAR(120), @diaIni INT,
            @durDias DECIMAL(6,2), @avanceP DECIMAL(5,3);
    SELECT @kind=kind, @orden=orden, @cap=cap, @diaIni=diaIni, @durDias=durDias,
           @avanceP=avanceP
      FROM @T WHERE n=@n;

    INSERT INTO FS_PL_Node (CodigoEmpresa, ProjectId, CenterId,
        FechaInicio, FechaFin, DuracionMin, Caption, Visible, Habilitado,
        Source, ParentTaskId, TaskKind, Collapsed, ConstraintKind, OrdenWBS,
        MinutosInvertidos)
    VALUES (@CE, @PID, NULL,
        DATEADD(MINUTE, @diaIni * @Jornada, @Ini),
        DATEADD(MINUTE, CAST((@diaIni + @durDias) * @Jornada AS INT), @Ini),
        @durDias * @Jornada, @cap, 1, 1, 'MAN',
        NULL,               -- ParentTaskId se rellena en el paso 4 (ya con ids)
        @kind, 0, 0, @orden,
        -- Tiempo invertido = fraccion de avance sobre la duracion estimada.
        -- Un hito (durDias=0) con avance 1 se queda en 0 minutos, que es
        -- correcto: un hito se alcanza, no se trabaja.
        @durDias * @Jornada * @avanceP);

    UPDATE @T SET NodeId = SCOPE_IDENTITY() WHERE n=@n;
    SET @n += 1;
END

-- ---- 4. Resolver ParentTaskId ahora que todos tienen NodeId ----------------
UPDATE n
   SET n.ParentTaskId = p.NodeId
  FROM FS_PL_Node n
  JOIN @T tc ON tc.NodeId = n.NodeId
  JOIN @T tp ON tp.n = tc.parent
  JOIN FS_PL_Node p ON p.NodeId = tp.NodeId
 WHERE n.CodigoEmpresa=@CE AND n.ProjectId=@PID AND tc.parent IS NOT NULL;

-- ---- 5. NodeData minimo por nodo (el Gantt lo necesita) --------------------
INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Estado, Tipo, Prioridad,
    LibreMovimiento, Operacion)
SELECT @CE, tc.NodeId, 0, 0, 0, 1, tc.cap FROM @T tc;

-- ---- 6. Dependencias (mapeando n logico -> NodeId real) --------------------
DECLARE @D TABLE (fromN INT, toN INT, tipo TINYINT, lagDias DECIMAL(6,2));
INSERT INTO @D (fromN, toN, tipo, lagDias) VALUES
 (3,  4,  0, 0),    -- FEM -> Validacion
 (4,  6,  0, 0),    -- Validacion -> Diseno congelado
 (5,  6,  0, 0),    -- Diseno mecanico -> Diseno congelado
 (6,  7,  0, 0),    -- Diseno congelado -> Aprovisionamiento
 (8,  9,  0, 3),    -- Pedido -> Recepcion (FS +3d)
 (9,  10, 0, 0),    -- Recepcion -> Fabricacion
 (11, 12, 1, 2),    -- Mecanizado -> Montaje (SS +2d)
 (12, 13, 0, 0);    -- Montaje -> Entrega

INSERT INTO FS_PL_Dependency (CodigoEmpresa, ProjectId, FromNodeId, ToNodeId,
    TipoLink, PorcentajeDependencia, LagMinutos)
SELECT @CE, @PID, tf.NodeId, tt.NodeId, d.tipo, 100,
       CAST(d.lagDias * @Jornada AS INT)
  FROM @D d
  JOIN @T tf ON tf.n = d.fromN
  JOIN @T tt ON tt.n = d.toN;

-- ---- 7. Resumen ------------------------------------------------------------
SELECT 'Proyecto demo TAREAS creado' AS info, @PID AS ProjectId,
       (SELECT COUNT(*) FROM FS_PL_Node WHERE CodigoEmpresa=@CE AND ProjectId=@PID) AS nodos,
       (SELECT COUNT(*) FROM FS_PL_Node WHERE CodigoEmpresa=@CE AND ProjectId=@PID AND TaskKind=1) AS resumenes,
       (SELECT COUNT(*) FROM FS_PL_Node WHERE CodigoEmpresa=@CE AND ProjectId=@PID AND TaskKind=2) AS hitos,
       (SELECT COUNT(*) FROM FS_PL_Node WHERE CodigoEmpresa=@CE AND ProjectId=@PID AND ParentTaskId IS NOT NULL) AS conPadre,
       (SELECT COUNT(*) FROM FS_PL_Dependency WHERE CodigoEmpresa=@CE AND ProjectId=@PID) AS dependencias;
GO
