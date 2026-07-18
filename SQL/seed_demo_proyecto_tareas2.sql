-- =============================================================================
-- Seed demo 2 - Segundo proyecto TAREAS, para probar la vista MULTI-PROYECTO
-- =============================================================================
-- Crea 'DEMO-PRJ2' (Instalacion linea de montaje): un proyecto mas corto que
-- DEMO-PRJ y que ARRANCA MAS TARDE, para que en la vista multi-proyecto se vea
-- claramente que cada uno tiene su propio rango y su propio camino critico
-- (el CPM se calcula por proyecto, no hay dependencias entre ellos).
--
-- Idempotente: si ya existe, lo borra y lo recrea.
-- Ejecutar con:  sqlcmd -S <server> -d FS -E -C -I -i <este fichero>
-- =============================================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;

DECLARE @CE SMALLINT = 9998;          -- la empresa de trabajo de la app
DECLARE @Jornada INT = 480;           -- 8 h/dia en minutos
-- Formato ISO sin separadores: es el unico que SQL Server interpreta igual
-- sea cual sea el idioma/regional de la sesion ('2026-08-17' falla en sesiones
-- con formato dmy).
DECLARE @Ini DATETIME = '20260817'; -- arranca 2 semanas despues que DEMO-PRJ

-- ---- 1. Limpiar la version anterior ----------------------------------------
DECLARE @Old INT;
SELECT @Old = ProjectId FROM FS_PL_Project
 WHERE CodigoEmpresa = @CE AND Codigo = 'DEMO-PRJ2';

IF @Old IS NOT NULL
BEGIN
    DELETE FROM FS_PL_Dependency
     WHERE CodigoEmpresa = @CE AND ProjectId = @Old;
    DELETE FROM FS_PL_NodeData
     WHERE CodigoEmpresa = @CE
       AND NodeId IN (SELECT NodeId FROM FS_PL_Node
                       WHERE CodigoEmpresa = @CE AND ProjectId = @Old);
    DELETE FROM FS_PL_Node
     WHERE CodigoEmpresa = @CE AND ProjectId = @Old;
    DELETE FROM FS_PL_Project
     WHERE CodigoEmpresa = @CE AND ProjectId = @Old;
    PRINT 'Demo 2 anterior eliminado.';
END

-- ---- 2. Proyecto ------------------------------------------------------------
INSERT INTO FS_PL_Project (CodigoEmpresa, Codigo, Nombre, PlanningParadigm)
VALUES (@CE, 'DEMO-PRJ2',
        N'Instalaci' + NCHAR(243) + N'n l' + NCHAR(237) + N'nea de montaje'
        + N' (demo proyectos)', 'TAREAS');

DECLARE @PID INT = SCOPE_IDENTITY();
PRINT 'Demo 2 creado con ProjectId = ' + CAST(@PID AS VARCHAR(10));

-- ---- 3. WBS ------------------------------------------------------------------
-- 9 nodos, 3 resumenes, 1 hito. Mas plano que DEMO-PRJ (2 niveles) a proposito.
DECLARE @T TABLE (
  n INT PRIMARY KEY, parent INT, kind TINYINT, orden INT, cap NVARCHAR(120),
  diaIni INT, durDias DECIMAL(6,2), avanceP DECIMAL(5,3), NodeId INT NULL
);
INSERT INTO @T (n, parent, kind, orden, cap, diaIni, durDias, avanceP) VALUES
 (1, NULL, 1, 1, N'A' + NCHAR(183) + N' Obra civil',                    0,  10, 0),
 (2, 1,    0, 1, N'A.1' + NCHAR(183) + N' Preparaci' + NCHAR(243) + N'n del suelo', 0, 5, 1.000),
 (3, 1,    0, 2, N'A.2' + NCHAR(183) + N' Acometidas el' + NCHAR(233) + N'ctricas', 5, 5, 0.400),
 (4, NULL, 1, 2, N'B' + NCHAR(183) + N' Montaje mec' + NCHAR(225) + N'nico', 10, 12, 0),
 (5, 4,    0, 1, N'B.1' + NCHAR(183) + N' Recepci' + NCHAR(243) + N'n de equipos', 10, 3, 0),
 (6, 4,    0, 2, N'B.2' + NCHAR(183) + N' Anclaje y nivelaci' + NCHAR(243) + N'n', 13, 6, 0),
 (7, 4,    0, 3, N'B.3' + NCHAR(183) + N' Conexionado',                 19,  3, 0),
 (8, NULL, 0, 3, N'C' + NCHAR(183) + N' Puesta en marcha',              22,  5, 0),
 (9, NULL, 2, 4, N'Aceptaci' + NCHAR(243) + N'n del cliente',           27,  0, 0);

-- ---- 4. Insertar nodos capturando el NodeId real ----------------------------
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
        NULL, @kind, 0, 0, @orden,
        @durDias * @Jornada * @avanceP);

    UPDATE @T SET NodeId = SCOPE_IDENTITY() WHERE n=@n;
    SET @n += 1;
END

-- ---- 5. Resolver ParentTaskId ------------------------------------------------
UPDATE n
   SET n.ParentTaskId = p.NodeId
  FROM FS_PL_Node n
  JOIN @T tc ON tc.NodeId = n.NodeId
  JOIN @T tp ON tp.n = tc.parent
  JOIN FS_PL_Node p ON p.NodeId = tp.NodeId
 WHERE n.CodigoEmpresa=@CE AND n.ProjectId=@PID AND tc.parent IS NOT NULL;

-- ---- 6. NodeData minimo ------------------------------------------------------
INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Estado, Tipo, Prioridad,
    LibreMovimiento, Operacion)
SELECT @CE, tc.NodeId, 0, 0, 0, 1, tc.cap FROM @T tc;

-- ---- 7. Dependencias ---------------------------------------------------------
-- Incluye un FF (tipo 2) y un SS con lag negativo (-1d = solape), casos que
-- DEMO-PRJ no tiene, para ejercitar las cuatro semanticas del motor.
DECLARE @D TABLE (fromN INT, toN INT, tipo TINYINT, lagDias DECIMAL(6,2));
INSERT INTO @D (fromN, toN, tipo, lagDias) VALUES
 (2, 3, 0,  0),    -- Suelo -> Acometidas (FS)
 (3, 5, 0,  0),    -- Acometidas -> Recepcion equipos (FS)
 (5, 6, 0,  0),    -- Recepcion -> Anclaje (FS)
 (6, 7, 1, -1),    -- Anclaje -> Conexionado (SS -1d: empiezan casi a la vez)
 (7, 8, 0,  0),    -- Conexionado -> Puesta en marcha (FS)
 (8, 9, 0,  0);    -- Puesta en marcha -> Aceptacion (FS)

INSERT INTO FS_PL_Dependency (CodigoEmpresa, ProjectId, FromNodeId, ToNodeId,
    TipoLink, PorcentajeDependencia, LagMinutos)
SELECT @CE, @PID, tf.NodeId, tt.NodeId, d.tipo, 100,
       CAST(d.lagDias * @Jornada AS INT)
  FROM @D d
  JOIN @T tf ON tf.n = d.fromN
  JOIN @T tt ON tt.n = d.toN;

-- ---- 8. Comprobacion ---------------------------------------------------------
SELECT p.Codigo, p.Nombre,
       (SELECT COUNT(*) FROM FS_PL_Node n
         WHERE n.CodigoEmpresa=@CE AND n.ProjectId=p.ProjectId) AS Nodos,
       (SELECT COUNT(*) FROM FS_PL_Dependency d
         WHERE d.CodigoEmpresa=@CE AND d.ProjectId=p.ProjectId) AS Deps
  FROM FS_PL_Project p
 WHERE p.CodigoEmpresa=@CE AND p.PlanningParadigm='TAREAS'
 ORDER BY p.Codigo;
