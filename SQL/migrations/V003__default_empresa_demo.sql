-- ============================================================================
-- V003 - Crear empresa demo 9999 por defecto para tener login funcional
-- ============================================================================

IF NOT EXISTS (SELECT 1 FROM FS_PL_Empresa WHERE CodigoEmpresa = 9999)
INSERT INTO FS_PL_Empresa (CodigoEmpresa, Nombre, EsDemo, Sector, Activo)
VALUES (9999, 'Demo - Empresa por defecto', 1, 'Demo', 1);

-- Crear rol ADMIN y usuario admin/admin para poder entrar y usar la pantalla de instalar demos
IF NOT EXISTS (SELECT 1 FROM FS_PL_Role WHERE CodigoEmpresa = 9999 AND Codigo = 'ADMIN')
INSERT INTO FS_PL_Role (CodigoEmpresa, Codigo, Nombre, Descripcion)
VALUES (9999, 'ADMIN', 'Administrador', 'Control total del sistema');

IF NOT EXISTS (SELECT 1 FROM FS_PL_User WHERE CodigoEmpresa = 9999 AND Login = 'admin')
INSERT INTO FS_PL_User (CodigoEmpresa, Login, PasswordHash, NombreCompleto, RoleId)
SELECT 9999, 'admin',
       '8C6976E5B5410415BDE908BD4DEE15DFB167A9C873FC4BB8A81F6F2AB448A918',
       'Administrador', RoleId
FROM FS_PL_Role WHERE CodigoEmpresa = 9999 AND Codigo = 'ADMIN';
