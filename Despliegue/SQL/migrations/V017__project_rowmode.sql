-- ============================================================================
-- V017 - Modo de visualizacion de filas (RowMode) por Proyecto
--
--   Anade a FS_PL_Project dos campos que definen el tipo de Gantt que se
--   instanciara al abrir el proyecto:
--     RowMode         'CENTROS'  agrupacion por centro de trabajo (por defecto)
--                     'GRUPO'    agrupacion por padre ERP (OF/OT, PED/LIN, PRJ/TAR)
--                     'TREE'     arbol expandible jerarquico
--     NivelAgrupacion 1 o 2      solo aplica si RowMode='GRUPO'
--                                 1 = agrupa por Nivel 1 (OF, PEDIDO, PROYECTO)
--                                 2 = agrupa por Nivel 2 (OT, LINEA, TAREA)
--
--   El mode se decide por proyecto, no por usuario ni en runtime. Cambiarlo
--   requiere editar el proyecto en la pantalla de Gestion de Proyectos y
--   reabrir el Gantt.
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.columns
               WHERE object_id = OBJECT_ID('FS_PL_Project')
                 AND name = 'RowMode')
    ALTER TABLE FS_PL_Project
        ADD RowMode VARCHAR(10) NOT NULL CONSTRAINT DF_FS_PL_Project_RowMode DEFAULT 'CENTROS';
GO

IF NOT EXISTS (SELECT * FROM sys.columns
               WHERE object_id = OBJECT_ID('FS_PL_Project')
                 AND name = 'NivelAgrupacion')
    ALTER TABLE FS_PL_Project
        ADD NivelAgrupacion TINYINT NOT NULL CONSTRAINT DF_FS_PL_Project_NivelAgrupacion DEFAULT 1;
GO

-- Check constraints (anadidos como separados para no bloquear filas existentes)
IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_FS_PL_Project_RowMode')
    ALTER TABLE FS_PL_Project
        ADD CONSTRAINT CK_FS_PL_Project_RowMode
            CHECK (RowMode IN ('CENTROS','GRUPO','TREE'));
GO

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_FS_PL_Project_NivelAgrupacion')
    ALTER TABLE FS_PL_Project
        ADD CONSTRAINT CK_FS_PL_Project_NivelAgrupacion
            CHECK (NivelAgrupacion IN (1, 2));
GO
