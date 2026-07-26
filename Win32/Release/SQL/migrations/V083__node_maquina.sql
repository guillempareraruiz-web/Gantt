-- ===========================================================================
-- V083 - Planificacion a nivel de MAQUINA.
--
-- Hasta ahora el motor planificaba a CENTRO: las maquinas existian como maestro
-- (V026) y se asignaban a centros (FS_PL_CentroMaquina), pero un nodo no sabia
-- en que maquina se hacia. Esto es la diferencia con cualquier APS comercial,
-- donde el recurso finito real es la maquina, no el centro.
--
-- Modelo (el estandar del sector):
--   Un CENTRO tiene N maquinas.
--   Una OP se puede hacer en uno o varios centros, y en una o varias maquinas.
--   El motor elige DENTRO del centro la primera maquina donde quepa.
--
-- Maquina de sistema "SIN MAQUINA" por centro
-- -------------------------------------------
-- Un centro sin maquinas asignadas no puede quedar sin planificar. Se le crea
-- una maquina por defecto __SINMAQUINA__<CodigoCentro>, de modo que el motor
-- SIEMPRE tiene al menos un recurso donde colocar. Asi el codigo no necesita un
-- caso especial "centro sin maquinas": la regla es unica.
--
-- Mismo criterio que los centros de sistema de V065 (SIN CENTRO / EXTERNO):
-- codigo con dobles guiones bajos para no chocar con codigos del ERP.
--
-- Aditivo e idempotente. Los planes existentes NO se mueven: sus nodos quedan
-- apuntando a la maquina por defecto de su centro, con las mismas fechas.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ---- 1. El nodo pasa a saber en que maquina se hace -----------------------
--
-- NULL = sin asignar. Se admite a proposito: un nodo creado a mano o importado
-- antes de esta migracion sigue siendo valido, y el Gantt lo muestra en el
-- cajon de la maquina por defecto de su centro.
IF COL_LENGTH('FS_PL_Node', 'MaquinaId') IS NULL
BEGIN
    ALTER TABLE FS_PL_Node ADD MaquinaId INT NULL;
END
GO

-- FK sin CASCADE a proposito: borrar una maquina NO debe borrar los nodos
-- planificados en ella. Si algun dia se borra una maquina con carga, que falle
-- y obligue a reasignar es mejor que perder el plan en silencio.
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys
               WHERE name = 'FK_FS_PL_Node_Maquina')
BEGIN
    ALTER TABLE FS_PL_Node WITH NOCHECK
        ADD CONSTRAINT FK_FS_PL_Node_Maquina
        FOREIGN KEY (CodigoEmpresa, MaquinaId)
        REFERENCES FS_PL_Maquina (CodigoEmpresa, MaquinaId);
END
GO

-- El Gantt en modo MAQUINAS pide "los nodos de esta maquina en este rango":
-- sin indice eso es un scan de FS_PL_Node entero por cada refresco.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Node_Maquina'
                 AND object_id = OBJECT_ID('FS_PL_Node'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Node_Maquina
    ON FS_PL_Node (CodigoEmpresa, MaquinaId)
    INCLUDE (ProjectId, CenterId, FechaInicio, FechaFin);
GO

-- ---- 2. Marcar que maquinas son de sistema --------------------------------
--
-- Hace falta distinguirlas para no listarlas como maquinas reales en los
-- mantenimientos (nadie quiere ver "SIN MAQUINA de TORNOS" en el maestro de
-- maquinas) y para poder darles otro tratamiento visual en el Gantt.
IF COL_LENGTH('FS_PL_Maquina', 'EsSistema') IS NULL
BEGIN
    ALTER TABLE FS_PL_Maquina ADD EsSistema BIT NOT NULL
        CONSTRAINT DF_FS_PL_Maquina_EsSistema DEFAULT (0);
END
GO

-- ---- 3. Una maquina por defecto para CADA centro --------------------------
--
-- Se crea siempre, tenga o no maquinas reales: es la que recibe la carga que no
-- se ha asignado a una maquina concreta, tambien en centros que si las tienen.
-- El codigo lleva el del centro para que sea unico y legible.
;WITH Centros AS (
    SELECT CodigoEmpresa, CenterId, CodigoCentro, Titulo
    FROM dbo.FS_PL_Center
)
INSERT INTO dbo.FS_PL_Maquina
    (CodigoEmpresa, Codigo, Nombre, Activo, Orden, EsSistema)
SELECT c.CodigoEmpresa,
       LEFT('__SINMAQUINA__' + c.CodigoCentro, 50),
       LEFT('Sin maquina (' + c.Titulo + ')', 200),
       1,
       999,          -- al final de cualquier listado
       1
FROM Centros c
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.FS_PL_Maquina m
    WHERE m.CodigoEmpresa = c.CodigoEmpresa
      AND m.Codigo = LEFT('__SINMAQUINA__' + c.CodigoCentro, 50));
GO

-- Y asignarla a su centro (N:M ya existente).
INSERT INTO dbo.FS_PL_CentroMaquina (CodigoEmpresa, CenterId, MaquinaId)
SELECT c.CodigoEmpresa, c.CenterId, m.MaquinaId
FROM dbo.FS_PL_Center c
JOIN dbo.FS_PL_Maquina m
  ON m.CodigoEmpresa = c.CodigoEmpresa
 AND m.Codigo = LEFT('__SINMAQUINA__' + c.CodigoCentro, 50)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.FS_PL_CentroMaquina cm
    WHERE cm.CodigoEmpresa = c.CodigoEmpresa
      AND cm.CenterId = c.CenterId
      AND cm.MaquinaId = m.MaquinaId);
GO

-- ---- 4. Los nodos ya planificados van a la maquina por defecto ------------
--
-- No se reparten entre las maquinas reales del centro: eso seria replanificar,
-- y esta migracion no debe mover ni una fecha. Quedan todos en la maquina por
-- defecto y el planificador los reparte cuando quiera (a mano o replanificando).
UPDATE n
   SET MaquinaId = m.MaquinaId
  FROM dbo.FS_PL_Node n
  JOIN dbo.FS_PL_Center c
    ON c.CodigoEmpresa = n.CodigoEmpresa AND c.CenterId = n.CenterId
  JOIN dbo.FS_PL_Maquina m
    ON m.CodigoEmpresa = n.CodigoEmpresa
   AND m.Codigo = LEFT('__SINMAQUINA__' + c.CodigoCentro, 50)
 WHERE n.MaquinaId IS NULL
   AND n.CenterId IS NOT NULL;
GO

-- ---- 5. Vista de maquinas planificables por centro ------------------------
--
-- Encapsula "que maquinas puede usar el motor en este centro, y en que orden".
-- Las de sistema van SIEMPRE al final (OrdenEfectivo): asi el motor prueba
-- primero las maquinas reales y solo cae en la de por defecto si no queda otra.
IF OBJECT_ID('FS_PL_V_CentroMaquinaPlan', 'V') IS NOT NULL
    DROP VIEW FS_PL_V_CentroMaquinaPlan;
GO

CREATE VIEW FS_PL_V_CentroMaquinaPlan
AS
SELECT
    cm.CodigoEmpresa,
    cm.CenterId,
    c.CodigoCentro,
    m.MaquinaId,
    m.Codigo        AS CodigoMaquina,
    m.Nombre        AS NombreMaquina,
    m.Activo,
    m.EsSistema,
    -- Las de sistema al final; entre iguales, por el Orden del maestro y luego
    -- por codigo (determinista: dos ejecuciones dan el mismo reparto).
    CASE WHEN m.EsSistema = 1 THEN 1 ELSE 0 END AS EsFallback,
    m.Orden         AS OrdenMaquina
FROM dbo.FS_PL_CentroMaquina cm
JOIN dbo.FS_PL_Maquina m
  ON m.CodigoEmpresa = cm.CodigoEmpresa AND m.MaquinaId = cm.MaquinaId
JOIN dbo.FS_PL_Center c
  ON c.CodigoEmpresa = cm.CodigoEmpresa AND c.CenterId = cm.CenterId
WHERE m.Activo = 1;
GO
