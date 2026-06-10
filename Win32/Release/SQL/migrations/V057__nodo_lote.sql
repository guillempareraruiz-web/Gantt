-- ===========================================================================
-- V057 - Lotes de planificacion (batch): agrupar nodos que se procesan juntos.
--
-- Un LOTE agrupa N nodos (OP) de un mismo CENTRO que se ejecutan en la misma
-- ventana temporal (p.ej. todas las piezas del mismo color en una pasada de
-- pintura, o varias piezas en una misma hornada de horno). El constraint del
-- lote no es el tiempo sino "que va junto" (mismo setup / misma carga).
--
-- Fase 1 (manual, sin criterio ni capacidad): el usuario selecciona nodos en
-- el Gantt y los agrupa. Validacion: mismo CenterId. El lote impone ventana
-- comun a sus miembros (inicio=min, fin=max). Desagrupar = LoteId NULL.
--
-- Modelo aditivo: FS_PL_Node.LoteId NULL = nodo libre (comportamiento actual
-- intacto). Solo los nodos con LoteId pertenecen a un lote.
-- ===========================================================================

SET NOCOUNT ON;
GO

-- --------- 1) Tabla de lotes -----------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Lote')
CREATE TABLE FS_PL_Lote (
    CodigoEmpresa   SMALLINT      NOT NULL,
    LoteId          INT IDENTITY(1,1) NOT NULL,
    ProjectId       INT           NOT NULL,
    CenterId        INT           NULL,        -- centro comun de los miembros
    Caption         NVARCHAR(200) NULL,
    FechaInicio     DATETIME2     NULL,        -- ventana del lote (min de miembros)
    FechaFin        DATETIME2     NULL,        -- ventana del lote (max de miembros)
    FechaCreacion   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_FS_PL_Lote PRIMARY KEY (CodigoEmpresa, LoteId),
    CONSTRAINT FK_FS_PL_Lote_Project FOREIGN KEY (CodigoEmpresa, ProjectId)
        REFERENCES FS_PL_Project(CodigoEmpresa, ProjectId),
    CONSTRAINT FK_FS_PL_Lote_Center FOREIGN KEY (CodigoEmpresa, CenterId)
        REFERENCES FS_PL_Center(CodigoEmpresa, CenterId)
);
GO

-- --------- 2) FK de nodo a lote (nullable) ---------------------------------
IF COL_LENGTH('FS_PL_Node', 'LoteId') IS NULL
    ALTER TABLE FS_PL_Node ADD LoteId INT NULL;
GO

-- ON DELETE no cascade: al borrar un lote dejamos los nodos como libres
-- (la app pone LoteId=NULL antes de borrar el lote). La FK solo garantiza
-- integridad referencial mientras el lote existe.
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FS_PL_Node_Lote')
    ALTER TABLE FS_PL_Node ADD CONSTRAINT FK_FS_PL_Node_Lote
        FOREIGN KEY (CodigoEmpresa, LoteId)
        REFERENCES FS_PL_Lote(CodigoEmpresa, LoteId);
GO

-- Indice para localizar rapido los nodos de un lote.
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FS_PL_Node_Lote')
    CREATE INDEX IX_FS_PL_Node_Lote
        ON FS_PL_Node (CodigoEmpresa, LoteId)
        WHERE LoteId IS NOT NULL;
GO
