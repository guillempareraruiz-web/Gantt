-- ============================================================================
-- FSPlanner 2026 - Almacenes
-- Prefijo: FS_PL_
-- Motor: SQL Server 2016+
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Almacen')
CREATE TABLE FS_PL_Almacen (
    CodigoEmpresa   SMALLINT      NOT NULL,
    AlmacenId       INT IDENTITY(1,1) NOT NULL,
    Codigo          NVARCHAR(30)  NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    Direccion       NVARCHAR(500) NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Almacen PRIMARY KEY (CodigoEmpresa, AlmacenId),
    CONSTRAINT UQ_FS_PL_Almacen_Codigo UNIQUE (CodigoEmpresa, Codigo)
);

-- Datos demo (solo empresa 9999)
INSERT INTO FS_PL_Almacen (CodigoEmpresa, Codigo, Nombre)
SELECT 9999, v.Codigo, v.Nombre
FROM (VALUES
  ('ALM01', 'Almacén General'),
  ('ALM02', 'Almacén Materia Prima'),
  ('ALM03', 'Almacén Producto Acabado')
) AS v(Codigo, Nombre)
WHERE NOT EXISTS (SELECT 1 FROM FS_PL_Almacen a WHERE a.CodigoEmpresa = 9999 AND a.Codigo = v.Codigo);

PRINT '==========================================';
PRINT 'Tabla FS_PL_Almacen creada';
PRINT '==========================================';
GO
