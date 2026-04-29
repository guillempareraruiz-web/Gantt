-- ============================================================================
-- FSPlanner 2026 - Tabla de Empresas
-- EJECUTAR ANTES de 002 y 003 (es tabla padre de todas)
-- Empresa 9999 = Demo/Test (datos de ejemplo)
-- Empresas reales se crean via importación desde ERP
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Empresa')
CREATE TABLE FS_PL_Empresa (
    CodigoEmpresa   SMALLINT      NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    CIF             NVARCHAR(20)  NULL,
    Direccion       NVARCHAR(500) NULL,
    Telefono        NVARCHAR(50)  NULL,
    Email           NVARCHAR(200) NULL,
    EsDemo          BIT           NOT NULL DEFAULT 0,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Empresa PRIMARY KEY (CodigoEmpresa)
);

-- Empresa demo
IF NOT EXISTS (SELECT 1 FROM FS_PL_Empresa WHERE CodigoEmpresa = 9999)
INSERT INTO FS_PL_Empresa (CodigoEmpresa, Nombre, CIF, EsDemo) VALUES
  (9999, 'Empresa Demo - FSPlanner', 'B00000000', 1);

PRINT '==========================================';
PRINT 'Tabla FS_PL_Empresa creada (demo = 9999)';
PRINT '==========================================';
GO
