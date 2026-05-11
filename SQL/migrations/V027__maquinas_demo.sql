-- ===========================================================================
-- V027 - Datos demo para FS_PL_Maquina + FS_PL_CentroMaquina (Empresa 9999)
--
-- Crea un set de maquinas de ejemplo y las asigna a los centros DEMO creados
-- por 002_Create_Planner_Schema.sql / V001. Cada maquina puede estar en mas
-- de un centro (modelo N:M). Idempotente.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- Maquinas demo
INSERT INTO FS_PL_Maquina (CodigoEmpresa, Codigo, Nombre, Activo, Orden)
SELECT 9999, v.Codigo, v.Nombre, 1, v.Orden
FROM (VALUES
  ('MAQ-001', 'Torno CNC TC-200',        0),
  ('MAQ-002', 'Fresadora vertical FV-3', 1),
  ('MAQ-003', 'Inyectora 150T',          2),
  ('MAQ-004', 'Prensa hidraulica PH-50', 3),
  ('MAQ-005', 'Soldadora MIG-300',       4),
  ('MAQ-006', 'Rectificadora R-15',      5)
) AS v(Codigo, Nombre, Orden)
WHERE NOT EXISTS (
  SELECT 1 FROM FS_PL_Maquina m
  WHERE m.CodigoEmpresa = 9999 AND m.Codigo = v.Codigo
);
GO

-- Asignaciones demo N:M (algunas maquinas en varios centros)
;WITH Asignaciones AS (
  SELECT * FROM (VALUES
    ('CENTRO-1', 'MAQ-001'),
    ('CENTRO-1', 'MAQ-002'),
    ('CENTRO-2', 'MAQ-003'),
    ('CENTRO-3', 'MAQ-002'),  -- MAQ-002 compartida con CENTRO-1
    ('CENTRO-4', 'MAQ-004'),
    ('CENTRO-5', 'MAQ-005'),
    ('CENTRO-7', 'MAQ-001'),  -- MAQ-001 compartida con CENTRO-1
    ('CENTRO-7', 'MAQ-006'),
    ('CENTRO-9', 'MAQ-006')   -- MAQ-006 compartida con CENTRO-7
  ) AS a(CodigoCentro, CodigoMaquina)
)
INSERT INTO FS_PL_CentroMaquina (CodigoEmpresa, CenterId, MaquinaId)
SELECT 9999, c.CenterId, m.MaquinaId
FROM Asignaciones a
JOIN FS_PL_Center  c ON c.CodigoEmpresa = 9999 AND c.CodigoCentro = a.CodigoCentro
JOIN FS_PL_Maquina m ON m.CodigoEmpresa = 9999 AND m.Codigo       = a.CodigoMaquina
WHERE NOT EXISTS (
  SELECT 1 FROM FS_PL_CentroMaquina cm
  WHERE cm.CodigoEmpresa = 9999
    AND cm.CenterId = c.CenterId
    AND cm.MaquinaId = m.MaquinaId
);
GO
