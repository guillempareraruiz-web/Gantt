-- ===========================================================================
-- V064 - FS_PL_MrpParam: parametros MRP por articulo (capa de OVERRIDE + EXTRAS).
--
-- Sage200 (dbo.Articulos) ya tiene casi todos los parametros de aprovisionamiento:
--   StockMinimo, StockMaximo, PuntoPedido, LotePedido, LoteFabricacion,
--   UsarStockSeg, %StockSeguridad, TiempoMedioReposicion, CodigoProveedor.
-- Por eso esta tabla NO duplica todo: guarda SOLO lo que el usuario quiere
-- sobreescribir de Sage, o lo que Sage NO tiene de forma clara:
--   - Multiplo de compra/fabricacion (redondeo de cantidad propuesta).
--   - Dias de cobertura objetivo (politica "cubrir N dias de demanda").
--   - Lead time de FABRICACION separado (Sage solo da TiempoMedioReposicion,
--     mas orientado a compra).
--   - Politica de reposicion (compra / fabricacion / subcontratacion). Por
--     defecto se deduce del BOM (si tiene formula -> fabrica; si no -> compra);
--     este campo permite FORZARLA. Patron hibrido BOM + override.
--   - Overrides opcionales de stock seguridad / lead time compra / lote, por si
--     el dato de Sage no es fiable para un articulo concreto.
--
-- La FUSION Sage + override NO se hace en una vista: las tablas de Sage viven en
-- OTRA base de datos (la del ERP), y las FS_PL_* en la BD propia del Planner. La
-- combinacion (COALESCE override -> Sage -> default) se hace en el conector/codigo
-- (IErpReader), respetando que ninguna pantalla consulta SQL del ERP directamente.
--
-- Solo hay fila para los articulos/almacenes con algun override; el resto hereda
-- 100% de Sage. PK (CodigoEmpresa, CodigoArticulo, CodigoAlmacen); CodigoAlmacen=''
-- es el override global del articulo. Los parametros MRP en Sage son por almacen
-- (ArticulosAlmacen) con fallback global (Articulos): respetamos esa jerarquia.
--
-- NOTA: el lead time y la merma de FABRICACION se leen de dbo.Formulas
-- (TiempoFabricacion, %IncrementoRechazo) cuando el articulo se fabrica; el campo
-- LeadTimeFabricacion de esta tabla queda como OVERRIDE manual opcional.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.FS_PL_MrpParam', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FS_PL_MrpParam (
        CodigoEmpresa        SMALLINT       NOT NULL,
        CodigoArticulo       VARCHAR(40)    NOT NULL,
        -- Almacen al que aplica el override. Cadena vacia '' = override GLOBAL del
        -- articulo (todos los almacenes). Asi soportamos el mismo nivel que Sage,
        -- que tiene parametros por almacen (ArticulosAlmacen) y globales (Articulos).
        -- Jerarquia de fusion en el conector, por (articulo, almacen):
        --   FS_PL_MrpParam(art,almacen) -> FS_PL_MrpParam(art,'') ->
        --   ArticulosAlmacen(art,almacen) -> Articulos(art) -> default.
        CodigoAlmacen        VARCHAR(10)    NOT NULL CONSTRAINT DF_MrpParam_Alm DEFAULT '',

        -- Politica de reposicion. NULL = deducir del BOM (formula -> fabricacion,
        -- sin formula -> compra). 'C' compra, 'F' fabricacion, 'S' subcontratacion.
        TipoReposicion       CHAR(1)        NULL,

        -- Extras que Sage no cubre bien (NULL = no aplicar).
        MultiploCompra       DECIMAL(18,4)  NULL,   -- redondear cantidad propuesta a multiplo
        DiasCoberturaObjetivo INT           NULL,   -- politica "cubrir N dias de demanda"
        LeadTimeFabricacion  INT            NULL,   -- dias (separado de compra)

        -- Overrides opcionales de parametros que SI estan en Sage, por si el dato
        -- del ERP no es fiable para este articulo. NULL = usar el de Sage.
        StockSeguridadOvr    DECIMAL(18,4)  NULL,
        LeadTimeCompraOvr    INT            NULL,   -- dias (override de TiempoMedioReposicion)
        LoteMinimoOvr        DECIMAL(18,4)  NULL,
        PuntoPedidoOvr       DECIMAL(18,4)  NULL,
        ProveedorPreferenteOvr VARCHAR(40)  NULL,

        -- Horizonte de planificacion propio del articulo (dias). NULL = usar el
        -- horizonte global del modulo.
        HorizonteDias        INT            NULL,

        -- Si False, el articulo se EXCLUYE del calculo MRP (no genera alertas ni
        -- recomendaciones). Util para obsoletos/no planificables.
        IncluirEnMrp         BIT            NOT NULL CONSTRAINT DF_MrpParam_Incluir DEFAULT 1,

        Observaciones        NVARCHAR(500)  NULL,
        FechaModificacion    DATETIME       NOT NULL CONSTRAINT DF_MrpParam_FMod DEFAULT GETDATE(),
        UsuarioModificacion  VARCHAR(50)    NULL,

        CONSTRAINT PK_FS_PL_MrpParam PRIMARY KEY (CodigoEmpresa, CodigoArticulo, CodigoAlmacen),
        CONSTRAINT CK_MrpParam_TipoRepo
            CHECK (TipoReposicion IS NULL OR TipoReposicion IN ('C','F','S'))
    );
END;
GO
