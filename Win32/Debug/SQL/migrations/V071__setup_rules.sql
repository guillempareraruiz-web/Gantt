-- ===========================================================================
-- V071 - Reglas de tiempo de cambio (setup) SECUENCIA-DEPENDIENTE.
--
-- Modela el tiempo muerto entre dos trabajos consecutivos en la misma linea
-- segun EN QUE se diferencian. Cada regla dice: "si cambia el atributo AttrName
-- del trabajo anterior al siguiente -> sumar SetupMin minutos".
--
--   AttrName    Nombre del atributo que dispara el cambio. Puede ser un campo
--               builtin del nodo (CodigoArticulo, CodigoColor...) o un campo
--               personalizado del backlog (Substrato, AnchoBobina, Molde...).
--               Generico: NO se hardcodea el sector.
--   SetupMin    Minutos de setup si ese atributo cambia (aditivo: varias reglas
--               que disparen se suman).
--   CentreCode  '' (vacio) = aplica a todas las lineas; si no, solo a esa linea.
--   Enabled     Regla activa.
--
-- El motor de planificacion (uSetupRules + uBacklogScheduler) usa estas reglas
-- para dejar el hueco REAL entre nodos consecutivos, de modo que el plan refleje
-- el tiempo de cambio de verdad. Si no hay reglas, el planificador se comporta
-- como antes (DistanciaMinNodos fija).
--
-- Idempotente: crea la tabla solo si no existe.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = 'FS_PL_SetupRule' AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    CREATE TABLE dbo.FS_PL_SetupRule (
        Id             INT IDENTITY(1,1) NOT NULL,
        CodigoEmpresa  SMALLINT      NOT NULL,
        AttrName       NVARCHAR(100) NOT NULL,
        SetupMin       INT           NOT NULL CONSTRAINT DF_FS_PL_SetupRule_Min DEFAULT (0),
        CentreCode     NVARCHAR(50)  NOT NULL CONSTRAINT DF_FS_PL_SetupRule_Centre DEFAULT (''),
        Enabled        BIT           NOT NULL CONSTRAINT DF_FS_PL_SetupRule_Enabled DEFAULT (1),
        CreatedAt      DATETIME2(0)  NOT NULL CONSTRAINT DF_FS_PL_SetupRule_Created DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_FS_PL_SetupRule PRIMARY KEY CLUSTERED (Id)
    );

    -- Consulta habitual: reglas activas por empresa.
    CREATE INDEX IX_FS_PL_SetupRule_Emp
        ON dbo.FS_PL_SetupRule (CodigoEmpresa, Enabled)
        INCLUDE (AttrName, SetupMin, CentreCode);
END
GO
