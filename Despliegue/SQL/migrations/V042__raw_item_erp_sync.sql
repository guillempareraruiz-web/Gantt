-- ===========================================================================
-- V042 - Soporte para sincronizacion ERP -> FS_PL_Raw_Item
--
-- Anade en FS_PL_Raw_Item:
--   - LastErpHash:    hash de los campos planificables (para detectar cambios
--                     entre sincronizaciones sin tener que comparar columna a
--                     columna).
--   - LastErpSyncAt:  timestamp ultima sync que toco la fila.
--
-- Politica de "obsoleto": se reutiliza la columna Activo (ya existente).
--   Activo = 1 -> visible en FS_PL_vw_Backlog (filtro existente)
--   Activo = 0 -> oculto en Backlog pero conservado para historico y para
--                 no romper FK con FS_PL_NodeData (nodos planificados).
--
-- La logica de sync (uErpSyncRepo.ApplyRawItems) se encarga de:
--   - Insertar nuevas claves ERP no existentes en Raw_Item.
--   - Update sobre Raw_Items cuya LastErpHash haya cambiado.
--   - Marcar Activo=0 los items que YA NO vienen del ERP en la sync actual,
--     siempre que no tengan ningun nodo planificado vivo (FS_PL_NodeData).
--     Si tienen nodo, se quedan Activo=1 para no romper la planificacion.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH('FS_PL_Raw_Item', 'LastErpHash') IS NULL
    ALTER TABLE FS_PL_Raw_Item ADD LastErpHash NVARCHAR(64) NULL;
GO

IF COL_LENGTH('FS_PL_Raw_Item', 'LastErpSyncAt') IS NULL
    ALTER TABLE FS_PL_Raw_Item ADD LastErpSyncAt DATETIME2 NULL;
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FS_PL_Raw_Item_LastSync')
    CREATE INDEX IX_FS_PL_Raw_Item_LastSync
        ON FS_PL_Raw_Item (CodigoEmpresa, OrigenERP, TipoOrigen, LastErpSyncAt);
GO
