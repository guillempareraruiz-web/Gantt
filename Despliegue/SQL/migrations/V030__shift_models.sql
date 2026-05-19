-- ============================================================================
-- V030 - Modelos horarios editables (estilo Sage: Modelos + Lineas)
-- ============================================================================
-- Hasta ahora FS_PL_CalendarDayRule almacenaba franjas NO laborables por dia
-- de semana, sin posibilidad de edicion desde la UI mas alla de crear/eliminar
-- el calendario (con weekend hardcoded).
--
-- Este script anade:
--   1. FS_PL_ShiftModel       - catalogo de plantillas por calendario
--                               (Jornada estandar, Nocturna, Partida...)
--   2. FS_PL_ShiftModelLine   - tramos LABORABLES de cada modelo por dia
--                               semana (inverso al CalendarDayRule actual)
--   3. Migracion: cada calendario existente recibe un modelo 'Default'
--      derivado de sus reglas actuales (los huecos entre franjas no-lab
--      pasan a ser franjas laborables del modelo Default).
--   4. FS_PL_CalendarDayRule se conserva: el repo escribe a ShiftModel /
--      ShiftModelLine y reproyecta automaticamente a CalendarDayRule, de
--      modo que el motor (uCentreCalendar) sigue funcionando sin cambios.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. FS_PL_ShiftModel : plantillas horarias asociadas a un calendario
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_ShiftModel')
CREATE TABLE FS_PL_ShiftModel (
    CodigoEmpresa   SMALLINT      NOT NULL,
    ShiftModelId    INT IDENTITY(1,1) NOT NULL,
    CalendarId      INT           NOT NULL,
    Nombre          NVARCHAR(100) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    EsDefault       BIT           NOT NULL DEFAULT 0,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_ShiftModel PRIMARY KEY (CodigoEmpresa, ShiftModelId),
    CONSTRAINT FK_FS_PL_ShiftModel_Cal FOREIGN KEY (CodigoEmpresa, CalendarId)
        REFERENCES FS_PL_Calendar(CodigoEmpresa, CalendarId) ON DELETE CASCADE,
    CONSTRAINT UQ_FS_PL_ShiftModel_Nombre UNIQUE (CodigoEmpresa, CalendarId, Nombre)
);
GO

-- ----------------------------------------------------------------------------
-- 2. FS_PL_ShiftModelLine : tramos LABORABLES por dia de semana
-- ----------------------------------------------------------------------------
-- Notas:
--   DiaSemana: 1=Lunes..7=Domingo (ISO, coherente con CalendarDayRule)
--   HoraInicio / HoraFin: TIME. Si un dia esta cerrado, NO tiene lineas.
--   Si tiene una unica linea 00:00-23:59 = laborable 24h.
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_ShiftModelLine')
CREATE TABLE FS_PL_ShiftModelLine (
    CodigoEmpresa   SMALLINT      NOT NULL,
    LineId          INT IDENTITY(1,1) NOT NULL,
    ShiftModelId    INT           NOT NULL,
    DiaSemana       INT           NOT NULL,
    HoraInicio      TIME          NOT NULL,
    HoraFin         TIME          NOT NULL,
    CONSTRAINT PK_FS_PL_ShiftModelLine PRIMARY KEY (CodigoEmpresa, LineId),
    CONSTRAINT FK_FS_PL_ShiftModelLine_Model FOREIGN KEY (CodigoEmpresa, ShiftModelId)
        REFERENCES FS_PL_ShiftModel(CodigoEmpresa, ShiftModelId) ON DELETE CASCADE
);
GO

CREATE NONCLUSTERED INDEX IX_FS_PL_ShiftModelLine_Model_Dia
    ON FS_PL_ShiftModelLine (CodigoEmpresa, ShiftModelId, DiaSemana);
GO

-- ----------------------------------------------------------------------------
-- 3. Migracion: para cada calendario existente, crear un modelo 'Default'
--    y derivar sus lineas a partir de los huecos entre CalendarDayRule.
-- ----------------------------------------------------------------------------
DECLARE @CE SMALLINT, @CalId INT, @ShiftModelId INT;
DECLARE @Dia INT, @Cursor INT;
DECLARE @PrevFin TIME, @Ini TIME, @Fin TIME;

-- Iterar calendarios sin modelo Default
DECLARE CalCur CURSOR FOR
    SELECT c.CodigoEmpresa, c.CalendarId
    FROM FS_PL_Calendar c
    WHERE NOT EXISTS (
        SELECT 1 FROM FS_PL_ShiftModel sm
        WHERE sm.CodigoEmpresa = c.CodigoEmpresa
          AND sm.CalendarId    = c.CalendarId
          AND sm.EsDefault     = 1
    );

OPEN CalCur;
FETCH NEXT FROM CalCur INTO @CE, @CalId;
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Crear modelo Default
    INSERT INTO FS_PL_ShiftModel (CodigoEmpresa, CalendarId, Nombre, Descripcion, EsDefault, Activo)
    VALUES (@CE, @CalId, N'Default', N'Modelo derivado de las reglas iniciales del calendario', 1, 1);

    SET @ShiftModelId = SCOPE_IDENTITY();

    -- Para cada dia 1..7 derivar tramos laborables = complementario de los no-lab
    SET @Dia = 1;
    WHILE @Dia <= 7
    BEGIN
        -- Estrategia: ordenar las franjas no-lab por inicio, ir generando
        -- los huecos entre ellas como franjas laborables.
        DECLARE @Tramos TABLE (Ini TIME, Fin TIME);
        DELETE FROM @Tramos;

        INSERT INTO @Tramos (Ini, Fin)
        SELECT HoraInicioNoLab, HoraFinNoLab
        FROM FS_PL_CalendarDayRule
        WHERE CodigoEmpresa = @CE AND CalendarId = @CalId AND DiaSemana = @Dia
        ORDER BY HoraInicioNoLab;

        IF NOT EXISTS (SELECT 1 FROM @Tramos)
        BEGIN
            -- Dia 100% laborable: una sola linea 00:00 - 23:59
            INSERT INTO FS_PL_ShiftModelLine (CodigoEmpresa, ShiftModelId, DiaSemana, HoraInicio, HoraFin)
            VALUES (@CE, @ShiftModelId, @Dia, '00:00:00', '23:59:00');
        END
        ELSE
        BEGIN
            -- Generar huecos: antes de la primera, entre tramos, despues de la ultima.
            DECLARE @Acum TABLE (Ord INT IDENTITY(1,1), Ini TIME, Fin TIME);
            DELETE FROM @Acum;
            INSERT INTO @Acum (Ini, Fin) SELECT Ini, Fin FROM @Tramos ORDER BY Ini;

            DECLARE @i INT = 1, @last INT = (SELECT MAX(Ord) FROM @Acum);
            DECLARE @cursorIni TIME = '00:00:00';

            WHILE @i <= @last
            BEGIN
                DECLARE @tIni TIME, @tFin TIME;
                SELECT @tIni = Ini, @tFin = Fin FROM @Acum WHERE Ord = @i;

                IF @cursorIni < @tIni
                BEGIN
                    INSERT INTO FS_PL_ShiftModelLine (CodigoEmpresa, ShiftModelId, DiaSemana, HoraInicio, HoraFin)
                    VALUES (@CE, @ShiftModelId, @Dia, @cursorIni, @tIni);
                END;

                IF @tFin > @cursorIni SET @cursorIni = @tFin;
                SET @i = @i + 1;
            END;

            -- Cola: del ultimo Fin hasta 23:59
            IF @cursorIni < '23:59:00'
            BEGIN
                INSERT INTO FS_PL_ShiftModelLine (CodigoEmpresa, ShiftModelId, DiaSemana, HoraInicio, HoraFin)
                VALUES (@CE, @ShiftModelId, @Dia, @cursorIni, '23:59:00');
            END;
        END;

        SET @Dia = @Dia + 1;
    END;

    FETCH NEXT FROM CalCur INTO @CE, @CalId;
END;

CLOSE CalCur;
DEALLOCATE CalCur;
GO
