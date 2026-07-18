-- =============================================================================
-- Seed demo 3 - Proyecto TAREAS con WBS PROFUNDA (7 niveles)
-- =============================================================================
-- Crea 'DEMO-PRJ3' (Diseno grafico de piezas). Su razon de ser es probar que la
-- jerarquia NO tiene limite de profundidad: el modelo es recursivo por
-- ParentTaskId y todo el codigo que lo recorre tambien lo es (AppendSubtree en
-- uWbsRepo, HojasDe y RangoSubarbol en uWbsScheduler).
--
-- Estructura: 7 niveles de anidamiento, 34 nodos, resumenes en cascada. Sirve
-- para verificar de un vistazo que:
--   - el roll-up de fechas sube correctamente por TODA la cadena de resumenes
--   - el avance ponderado agrega bien a traves de varios niveles
--   - el camino critico atraviesa resumenes anidados
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

DECLARE @CE SMALLINT = 9998;
DECLARE @Jornada INT = 480;
DECLARE @Ini DATETIME = '20260803';   -- formato ISO: independiente del regional

-- ---- 1. Limpiar la version anterior ----------------------------------------
DECLARE @Old INT;
SELECT @Old = ProjectId FROM FS_PL_Project
 WHERE CodigoEmpresa = @CE AND Codigo = 'DEMO-PRJ3';

IF @Old IS NOT NULL
BEGIN
    DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa = @CE AND ProjectId = @Old;
    DELETE FROM FS_PL_NodeData
     WHERE CodigoEmpresa = @CE
       AND NodeId IN (SELECT NodeId FROM FS_PL_Node
                       WHERE CodigoEmpresa = @CE AND ProjectId = @Old);
    DELETE FROM FS_PL_Node WHERE CodigoEmpresa = @CE AND ProjectId = @Old;
    DELETE FROM FS_PL_Project WHERE CodigoEmpresa = @CE AND ProjectId = @Old;
    PRINT 'Demo 3 anterior eliminado.';
END

-- ---- 2. Proyecto ------------------------------------------------------------
INSERT INTO FS_PL_Project (CodigoEmpresa, Codigo, Nombre, PlanningParadigm)
VALUES (@CE, 'DEMO-PRJ3',
        N'Dise' + NCHAR(241) + N'o gr' + NCHAR(225) + N'fico de piezas'
        + N' (WBS profunda)', 'TAREAS');

DECLARE @PID INT = SCOPE_IDENTITY();
PRINT 'Demo 3 creado con ProjectId = ' + CAST(@PID AS VARCHAR(10));

-- ---- 3. WBS de 7 niveles -----------------------------------------------------
-- kind: 0 = tarea, 1 = resumen, 2 = hito
-- Solo las HOJAS llevan duracion y avance; los resumenes los agrega el motor.
DECLARE @T TABLE (
  n INT PRIMARY KEY, parent INT, kind TINYINT, orden INT, cap NVARCHAR(160),
  diaIni INT, durDias DECIMAL(6,2), avanceP DECIMAL(5,3), NodeId INT NULL
);
INSERT INTO @T (n, parent, kind, orden, cap, diaIni, durDias, avanceP) VALUES
 -- Nivel 1
 ( 1, NULL, 1, 1, N'1' + NCHAR(183) + N' Identidad visual',                      0,  0, 0),
 -- Nivel 2
 ( 2,  1,   1, 1, N'1.1' + NCHAR(183) + N' Investigaci' + NCHAR(243) + N'n',     0,  0, 0),
 ( 3,  2,   0, 1, N'1.1.1' + NCHAR(183) + N' An' + NCHAR(225) + N'lisis de referencias', 0, 3, 1.000),
 ( 4,  2,   0, 2, N'1.1.2' + NCHAR(183) + N' Moodboard',                          3,  2, 1.000),
 -- Nivel 3 y 4: rama de concepto, que se hunde hasta el nivel 7
 ( 5,  1,   1, 2, N'1.2' + NCHAR(183) + N' Concepto',                             5,  0, 0),
 ( 6,  5,   1, 1, N'1.2.1' + NCHAR(183) + N' Bocetos',                            5,  0, 0),
 ( 7,  6,   0, 1, N'1.2.1.1' + NCHAR(183) + N' Bocetos a mano',                   5,  3, 1.000),
 ( 8,  6,   1, 2, N'1.2.1.2' + NCHAR(183) + N' Digitalizaci' + NCHAR(243) + N'n', 8,  0, 0),
 -- Nivel 5
 ( 9,  8,   0, 1, N'1.2.1.2.1' + NCHAR(183) + N' Vectorizado',                    8,  4, 1.000),
 (10,  8,   1, 2, N'1.2.1.2.2' + NCHAR(183) + N' Refinado',                      12,  0, 0),
 -- Nivel 6
 (11, 10,   0, 1, N'1.2.1.2.2.1' + NCHAR(183) + N' Ajuste de curvas',            12,  3, 1.000),
 (12, 10,   1, 2, N'1.2.1.2.2.2' + NCHAR(183) + N' Detalle fino',                15,  0, 0),
 -- Nivel 7 (el mas profundo)
 (13, 12,   0, 1, N'...2.2.1' + NCHAR(183) + N' Filetes y radios',               15,  2, 1.000),
 (14, 12,   0, 2, N'...2.2.2' + NCHAR(183) + N' Revisi' + NCHAR(243) + N'n de nodos', 17, 2, 0.500),
 -- El rombo de hito lo pone la UI segun TaskKind: NO ponerlo en el Caption o
 -- sale duplicado en el arbol.
 (15, 12,   2, 3, N'...2.2.3 Vectores cerrados',                                19,  0, 0),
 -- Vuelta a niveles altos
 (16,  5,   0, 2, N'1.2.2' + NCHAR(183) + N' Propuesta de paleta',               19,  3, 0),
 (17,  1,   2, 3, N'Identidad aprobada',                                          22,  0, 0),

 -- Nivel 1: segunda gran rama
 (18, NULL, 1, 2, N'2' + NCHAR(183) + N' Modelado de piezas',                    22,  0, 0),
 (19, 18,   1, 1, N'2.1' + NCHAR(183) + N' Pieza A',                             22,  0, 0),
 (20, 19,   1, 1, N'2.1.1' + NCHAR(183) + N' Geometr' + NCHAR(237) + N'a',       22,  0, 0),
 (21, 20,   0, 1, N'2.1.1.1' + NCHAR(183) + N' Perfil base',                     22,  4, 0),
 (22, 20,   1, 2, N'2.1.1.2' + NCHAR(183) + N' Extrusiones',                     26,  0, 0),
 (23, 22,   0, 1, N'2.1.1.2.1' + NCHAR(183) + N' Extrusi' + NCHAR(243) + N'n principal', 26, 3, 0),
 (24, 22,   0, 2, N'2.1.1.2.2' + NCHAR(183) + N' Vaciados',                      29,  2, 0),
 (25, 19,   0, 2, N'2.1.2' + NCHAR(183) + N' Texturizado',                       31,  3, 0),
 (26, 18,   1, 2, N'2.2' + NCHAR(183) + N' Pieza B',                             34,  0, 0),
 (27, 26,   0, 1, N'2.2.1' + NCHAR(183) + N' Geometr' + NCHAR(237) + N'a',       34,  5, 0),
 (28, 26,   0, 2, N'2.2.2' + NCHAR(183) + N' Texturizado',                       39,  3, 0),

 -- Nivel 1: entregables
 (29, NULL, 1, 3, N'3' + NCHAR(183) + N' Entregables',                           42,  0, 0),
 (30, 29,   1, 1, N'3.1' + NCHAR(183) + N' Renders',                             42,  0, 0),
 (31, 30,   0, 1, N'3.1.1' + NCHAR(183) + N' Render de estudio',                 42,  3, 0),
 (32, 30,   0, 2, N'3.1.2' + NCHAR(183) + N' Render de ambiente',                45,  3, 0),
 (33, 29,   0, 2, N'3.2' + NCHAR(183) + N' Dossier final',                       48,  2, 0),
 (34, NULL, 2, 4, N'Entrega al cliente',                                          50,  0, 0);

-- ---- 4. Insertar nodos capturando el NodeId real ----------------------------
DECLARE @n INT = 1, @maxN INT = (SELECT MAX(n) FROM @T);
WHILE @n <= @maxN
BEGIN
    DECLARE @kind TINYINT, @orden INT, @cap NVARCHAR(160), @diaIni INT,
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
-- Encadena las HOJAS de la rama profunda para que el camino critico tenga que
-- atravesar 6 niveles de resumenes anidados.
DECLARE @D TABLE (fromN INT, toN INT, tipo TINYINT, lagDias DECIMAL(6,2));
INSERT INTO @D (fromN, toN, tipo, lagDias) VALUES
 ( 3,  4, 0, 0),    -- Referencias -> Moodboard
 ( 4,  7, 0, 0),    -- Moodboard -> Bocetos a mano
 ( 7,  9, 0, 0),    -- Bocetos -> Vectorizado
 ( 9, 11, 0, 0),    -- Vectorizado -> Ajuste de curvas
 (11, 13, 0, 0),    -- Ajuste -> Filetes (nivel 7)
 (13, 14, 0, 0),    -- Filetes -> Revision de nodos
 (14, 15, 0, 0),    -- Revision -> hito Vectores cerrados
 (15, 16, 0, 0),    -- hito -> Paleta
 (16, 17, 0, 0),    -- Paleta -> hito Identidad aprobada
 (17, 21, 0, 0),    -- Identidad aprobada -> Perfil base (arranca modelado)
 (21, 23, 0, 0),    -- Perfil -> Extrusion principal
 (23, 24, 0, 0),    -- Extrusion -> Vaciados
 (24, 25, 0, 0),    -- Vaciados -> Texturizado A
 (25, 27, 0, 0),    -- Texturizado A -> Geometria B
 (27, 28, 0, 0),    -- Geometria B -> Texturizado B
 (28, 31, 0, 0),    -- Texturizado B -> Render estudio
 (31, 32, 1, 1),    -- Render estudio -> Render ambiente (SS +1d, solapan)
 (32, 33, 0, 0),    -- Render ambiente -> Dossier
 (33, 34, 0, 0);    -- Dossier -> Entrega

INSERT INTO FS_PL_Dependency (CodigoEmpresa, ProjectId, FromNodeId, ToNodeId,
    TipoLink, PorcentajeDependencia, LagMinutos)
SELECT @CE, @PID, tf.NodeId, tt.NodeId, d.tipo, 100,
       CAST(d.lagDias * @Jornada AS INT)
  FROM @D d
  JOIN @T tf ON tf.n = d.fromN
  JOIN @T tt ON tt.n = d.toN;

-- ---- 8. Comprobacion: profundidad real del arbol -----------------------------
WITH Arbol AS (
    SELECT NodeId, ParentTaskId, 1 AS Nivel
      FROM FS_PL_Node
     WHERE CodigoEmpresa=@CE AND ProjectId=@PID AND ParentTaskId IS NULL
    UNION ALL
    SELECT n.NodeId, n.ParentTaskId, a.Nivel + 1
      FROM FS_PL_Node n
      JOIN Arbol a ON n.ParentTaskId = a.NodeId
     WHERE n.CodigoEmpresa=@CE AND n.ProjectId=@PID
)
SELECT MAX(Nivel) AS NivelesDeWBS, COUNT(*) AS Nodos FROM Arbol;

SELECT p.Codigo, p.Nombre,
       (SELECT COUNT(*) FROM FS_PL_Node n
         WHERE n.CodigoEmpresa=@CE AND n.ProjectId=p.ProjectId) AS Nodos,
       (SELECT COUNT(*) FROM FS_PL_Dependency d
         WHERE d.CodigoEmpresa=@CE AND d.ProjectId=p.ProjectId) AS Deps
  FROM FS_PL_Project p
 WHERE p.CodigoEmpresa=@CE AND p.PlanningParadigm='TAREAS'
 ORDER BY p.Codigo;
