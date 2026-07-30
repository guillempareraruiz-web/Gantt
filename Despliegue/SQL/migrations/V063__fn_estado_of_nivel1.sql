-- ===========================================================================
-- V063 - FS_PL_fn_EstadoOFNivel1: EstadoERP de la OF (Nivel 1) de un nodo.
--
-- El nodo del Gantt se vincula a un FS_PL_Raw_Item (la OP/OT/OF segun el nivel
-- planificable elegido) via (TipoOrigen, ClaveERP). Esta funcion sube por
-- ParentRawItemId hasta el Nivel 1 (la OF / PEDIDO / PROYECTO) y devuelve su
-- EstadoERP, para que el conector pueda detectar OFs ya CERRADAS en el ERP
-- (alerta D11): EstadoERP '0'=abierto, '1'=pendiente, cualquier otro = cerrada.
--
-- Devuelve NULL si no hay vinculo a Raw_Item. Robusta ante ciclos (tope de
-- saltos) aunque la jerarquia es como mucho de 3 niveles.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.FS_PL_fn_EstadoOFNivel1', 'FN') IS NOT NULL
    DROP FUNCTION dbo.FS_PL_fn_EstadoOFNivel1;
GO

CREATE FUNCTION dbo.FS_PL_fn_EstadoOFNivel1
(
    @CodigoEmpresa SMALLINT,
    @TipoOrigen    NVARCHAR(10),
    @ClaveERP      NVARCHAR(100)
)
RETURNS NVARCHAR(30)
AS
BEGIN
    IF @ClaveERP IS NULL OR @TipoOrigen IS NULL
        RETURN NULL;

    DECLARE @RawItemId       INT,
            @ParentRawItemId  INT,
            @Nivel            INT,
            @EstadoERP        NVARCHAR(30),
            @Saltos           INT = 0;

    -- Raw_Item al que se vincula el nodo.
    SELECT @RawItemId      = RawItemId,
           @ParentRawItemId = ParentRawItemId,
           @Nivel          = Nivel,
           @EstadoERP      = EstadoERP
    FROM dbo.FS_PL_Raw_Item
    WHERE CodigoEmpresa = @CodigoEmpresa
      AND TipoOrigen    = @TipoOrigen
      AND ClaveERP      = @ClaveERP;

    IF @RawItemId IS NULL
        RETURN NULL;

    -- Subir por ParentRawItemId hasta Nivel 1 (tope de saltos por seguridad).
    WHILE @Nivel > 1 AND @ParentRawItemId IS NOT NULL AND @Saltos < 10
    BEGIN
        SELECT @RawItemId       = RawItemId,
               @ParentRawItemId = ParentRawItemId,
               @Nivel           = Nivel,
               @EstadoERP       = EstadoERP
        FROM dbo.FS_PL_Raw_Item
        WHERE CodigoEmpresa = @CodigoEmpresa
          AND RawItemId     = @ParentRawItemId;

        SET @Saltos = @Saltos + 1;
    END;

    RETURN @EstadoERP;
END;
GO
