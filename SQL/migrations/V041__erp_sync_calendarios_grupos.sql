-- ===========================================================================
-- V041 - Sincronizacion ERP de Calendarios desde GruposHorarios
--
-- En Sage 200 el "calendario operativo" (que dias son laborables y con que
-- modelo horario) vive en la taula `CalendarioLaboral` con clau
-- (CodigoEmpresa, GrupoHorario, Fecha). Un GrupoHorario equival al concepte
-- de calendari del nostre sistema: agrupa diversos centres i operaris que
-- comparteixen el mateix regim de jornades i festius.
--
-- Sincronitzacio plantejada:
--   1. Cada GrupoHorario amb dades a CalendarioLaboral -> 1 FS_PL_Calendar
--      (matching per ErpCodigo = GrupoHorario).
--   2. Per cada dia de la setmana (1..7) del grup, agafem el "mode dominant"
--      de Duracion segons l'historic: si la majoria son laborables (Dur>0)
--      el dia setmana queda com a laborable a CalendarDayRule; els dies
--      diferents (festius puntuals o canvis de torn) van a CalendarException.
--      Aquesta logica viu al codi (uErpSyncRepo), no al SQL.
--   3. FS_PL_Center.GrupoHorarioCodigo apunta al codi del grup horari
--      vinculat (ja venia camp similar a TCentroTrabajoErp.GrupoHorario,
--      pero no s'estava persistint).
--   4. FS_PL_Operator.GrupoHorarioCodigo ja existeix des de V037.
--
-- IMPORTANT: aquesta migracio NO toca FS_PL_ShiftModelAssignment (V040).
-- Aquella taula queda obsoleta i no s'usa des del form. Es pot droppejar
-- manualment despres si es vol netejar (no ho fem aqui per seguretat).
-- ===========================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Calendar - metadades sync ERP
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_Calendar', 'Source') IS NULL
    ALTER TABLE FS_PL_Calendar ADD Source NVARCHAR(20) NOT NULL
        CONSTRAINT DF_FS_PL_Calendar_Source DEFAULT 'MANUAL';
GO

IF COL_LENGTH('FS_PL_Calendar', 'ErpSistema') IS NULL
    ALTER TABLE FS_PL_Calendar ADD ErpSistema NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_Calendar', 'ErpCodigo') IS NULL
    ALTER TABLE FS_PL_Calendar ADD ErpCodigo NVARCHAR(30) NULL;
GO

IF COL_LENGTH('FS_PL_Calendar', 'LastErpHash') IS NULL
    ALTER TABLE FS_PL_Calendar ADD LastErpHash NVARCHAR(64) NULL;
GO

IF COL_LENGTH('FS_PL_Calendar', 'LastErpSyncAt') IS NULL
    ALTER TABLE FS_PL_Calendar ADD LastErpSyncAt DATETIME2 NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Calendar_ErpCodigo'
                 AND object_id = OBJECT_ID('FS_PL_Calendar'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Calendar_ErpCodigo
    ON FS_PL_Calendar (CodigoEmpresa, Source, ErpCodigo);
GO

-- ---------------------------------------------------------------------------
-- FS_PL_Center.GrupoHorarioCodigo
-- ---------------------------------------------------------------------------
IF COL_LENGTH('FS_PL_Center', 'GrupoHorarioCodigo') IS NULL
    ALTER TABLE FS_PL_Center ADD GrupoHorarioCodigo NVARCHAR(30) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FS_PL_Center_GrupoHorario'
                 AND object_id = OBJECT_ID('FS_PL_Center'))
CREATE NONCLUSTERED INDEX IX_FS_PL_Center_GrupoHorario
    ON FS_PL_Center (CodigoEmpresa, GrupoHorarioCodigo);
GO
