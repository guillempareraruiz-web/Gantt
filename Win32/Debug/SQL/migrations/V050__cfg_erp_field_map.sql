-- ===========================================================================
-- V050 - FS_PL_Cfg_ErpFieldMap: mapeo de campos personalizados -> expresion SQL
--        del ERP (Sage), para poblar FS_PL_RawItem_Extra durante el sync.
--
-- Lo configura el integrador (conocedor del ERP), por cliente, sin recompilar.
-- Una fila por columna custom (FieldKey): una expresion SQL libre contra Sage
-- y, opcionalmente, los JOINs que esa expresion necesite.
--
-- El valor leido se escribe en FS_PL_RawItem_Extra con Source='ERP', respetando
-- los Source='MANUAL' (override del usuario, intocable).
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('FS_PL_Cfg_ErpFieldMap', 'U') IS NULL
BEGIN
    CREATE TABLE FS_PL_Cfg_ErpFieldMap (
        CodigoEmpresa  SMALLINT      NOT NULL,
        GridId         VARCHAR(50)   NOT NULL,   -- 'BACKLOG' (extensible)
        FieldKey       VARCHAR(64)   NOT NULL,   -- = FieldKey de FS_PL_Cfg_GridColumns
        ErpSource      VARCHAR(30)   NOT NULL,   -- 'SAGE200', etc.
        SqlExpression  NVARCHAR(500) NOT NULL,   -- expresion SQL libre: 'of.CampoLibre1', 'LTRIM(c.Obs)'...
        SqlJoins       NVARCHAR(MAX)  NULL,       -- JOINs extra que la expresion necesite
        AppliesToNivel TINYINT        NULL,       -- nivel al que aplica (1/2/3); coherente con la columna
        Activo         BIT            NOT NULL CONSTRAINT DF_FS_PL_Cfg_ErpFieldMap_Activo DEFAULT 1,
        UpdatedBy      NVARCHAR(64)   NULL,
        UpdatedAt      DATETIME2      NULL,
        CONSTRAINT PK_FS_PL_Cfg_ErpFieldMap PRIMARY KEY (CodigoEmpresa, GridId, FieldKey)
    );
END
GO
