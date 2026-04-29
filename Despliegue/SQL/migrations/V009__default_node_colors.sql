-- ============================================================================
-- V009 - Colores por defecto de nodos (azul cal)
--   Fill   = BGR $00E8B880 (RGB 128,184,232) = 15251072
--   Border = BGR $00AA6428 (RGB  40,100,170) = 11166760
-- ============================================================================

-- Añadir DEFAULT CONSTRAINT a ColorFondo de FS_PL_Node
IF NOT EXISTS (
    SELECT 1 FROM sys.default_constraints
    WHERE name = 'DF_FS_PL_Node_ColorFondo'
)
    ALTER TABLE FS_PL_Node
    ADD CONSTRAINT DF_FS_PL_Node_ColorFondo DEFAULT 15251072 FOR ColorFondo;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.default_constraints
    WHERE name = 'DF_FS_PL_Node_ColorBorde'
)
    ALTER TABLE FS_PL_Node
    ADD CONSTRAINT DF_FS_PL_Node_ColorBorde DEFAULT 11166760 FOR ColorBorde;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.default_constraints
    WHERE name = 'DF_FS_PL_NodeData_ColorFondoOp'
)
    ALTER TABLE FS_PL_NodeData
    ADD CONSTRAINT DF_FS_PL_NodeData_ColorFondoOp DEFAULT 15251072 FOR ColorFondoOp;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.default_constraints
    WHERE name = 'DF_FS_PL_NodeData_ColorBordeOp'
)
    ALTER TABLE FS_PL_NodeData
    ADD CONSTRAINT DF_FS_PL_NodeData_ColorBordeOp DEFAULT 11166760 FOR ColorBordeOp;
GO

-- Backfill -- nodos existentes con color NULL o negro (0)
UPDATE FS_PL_Node
SET ColorFondo = 15251072
WHERE ColorFondo IS NULL OR ColorFondo = 0;

UPDATE FS_PL_Node
SET ColorBorde = 11166760
WHERE ColorBorde IS NULL OR ColorBorde = 0;

UPDATE FS_PL_NodeData
SET ColorFondoOp = 15251072
WHERE ColorFondoOp IS NULL OR ColorFondoOp = 0;

UPDATE FS_PL_NodeData
SET ColorBordeOp = 11166760
WHERE ColorBordeOp IS NULL OR ColorBordeOp = 0;
