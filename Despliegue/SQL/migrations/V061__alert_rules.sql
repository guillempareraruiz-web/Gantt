-- ===========================================================================
-- V061 - FS_PL_AlertRule: configuracion de las alertas de planificacion.
--
-- El CATALOGO de tipos de alerta vive en el codigo (enum TAlertaTipo en
-- uGanttAlertas.pas): cada tipo tiene un codigo estable (A01, R02...), un
-- titulo y su logica de deteccion. Esta tabla guarda solo la CONFIGURACION que
-- el usuario puede ajustar por cada tipo:
--   - Activa: si se evalua/muestra o no.
--   - Peso  : factor de importancia 1..100 (ordena por impacto y pondera el
--             "indice de salud" del plan). No es lo mismo "fuera de plazo" que
--             "mismo utillaje".
--   - Umbral: parametro opcional del tipo (dias para "proximo a entrega",
--             % de carga para "dia sobrecargado"...). NULL = usar el del codigo.
--
-- Patron "seed + override": al arrancar, el repo inserta una fila por cada
-- codigo del enum que aun no exista (con valores por defecto). Asi anyadir un
-- tipo nuevo en el codigo aparece automaticamente aqui sin romper nada.
-- La PK es (CodigoEmpresa, AlertCode) para soportar multiempresa.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.FS_PL_AlertRule', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FS_PL_AlertRule (
        CodigoEmpresa     SMALLINT       NOT NULL,
        AlertCode         NVARCHAR(10)   NOT NULL,   -- 'A01', 'R02'... (estable)
        Activa            BIT            NOT NULL CONSTRAINT DF_AlertRule_Activa DEFAULT 1,
        Peso              INT            NOT NULL CONSTRAINT DF_AlertRule_Peso DEFAULT 50,
        Umbral            INT            NULL,       -- parametro opcional del tipo
        Orden             INT            NOT NULL CONSTRAINT DF_AlertRule_Orden DEFAULT 0,
        FechaModificacion DATETIME       NOT NULL CONSTRAINT DF_AlertRule_FMod DEFAULT GETDATE(),
        CONSTRAINT PK_FS_PL_AlertRule PRIMARY KEY (CodigoEmpresa, AlertCode),
        CONSTRAINT CK_AlertRule_Peso CHECK (Peso BETWEEN 1 AND 100)
    );
END;
GO
