/* ============================================================================
   PURGA DE HISTORICO  -  Sage200 / LogicClass
   ----------------------------------------------------------------------------
   Elimina documentos, movimientos y produccion ANTERIORES a un ejercicio/fecha
   de corte para aligerar la BD. Reutilizable en CUALQUIER BD de cliente:
   normalmente solo hay que ajustar @EjercicioCorte / @FechaCorte.

   COMO EJECUTARLO EN OTRO CLIENTE:
     1. Hacer BACKUP de la BD (o trabajar sobre una copia). El borrado es
        IRREVERSIBLE.
     2. Ajustar los parametros de abajo (@EjercicioCorte y @FechaCorte).
     3. Ejecutar entero en SSMS / Navicat sobre esa BD.
     Nada del script depende del nombre de la BD ni de que existan todas las
     tablas: los bloques que no apliquen se saltan solos.

   QUE BORRA (todo lo anterior al corte):
     - Stock:        MovimientoStock (por Ejercicio; fallback a Fecha).
     - Albaranes y pedidos de cliente/proveedor: cabeceras + lineas (por Fecha
       de la cabecera; las lineas no tienen fecha propia).
     - Produccion:   OrdenesFabricacion, OrdenesTrabajo, OperacionesOT,
                     ConsumosOT, RelacionOTOF (por Ejercicio; hijos->padres).
     - Contable/estadistico: Movimientos, MovimientosFacturas, HistoricoCartera,
                     EstadisVenta, EstadisCompra, ConsumosIncidencia,
                     LineasOfertaCliente (por Ejercicio) e Inventarios (por Fecha).
     - Tecnicas/backup vaciadas enteras: lsysTrace (traza de auditoria) y
       CabeceraPedidoCliente_Bak (backup sin dependencias).
     - Al final: DBCC SHRINKDATABASE + sp_updatestats para recuperar disco.

   QUE **NO** TOCA:
     - AcumuladoStock -> stock VIVO (saldo actual). Borrarlo falsearia existencias.
     - Tablas *_Sync -> espejos de sincronizacion (ver TRIGGERS abajo).
     - Fichas maestras (Clientes, Proveedores, Articulos, Empresas).
     - Facturas emitidas/recibidas y contabilidad de asientos (fuera de alcance).

   DISENO / PORTABILIDAD:
     - Todo por SQL dinamico: si en una BD falta una tabla o columna, ese bloque
       se SALTA (guardas OBJECT_ID / COL_LENGTH) en vez de romper el batch.
     - Borrado por LOTES (DELETE TOP @Lote) para no inflar el log ni bloquear
       tablas de millones de filas.
     - LINEAS antes que CABECERAS; hijos antes que padres (no deja huerfanos).
     - Idempotente: se puede reejecutar; solo borra lo que quede bajo el corte.

   TRIGGERS DE SINCRONIZACION (_SyncDelete / _SyncIU):
     Muchas tablas Sage200 tienen triggers que, al borrar, insertan la baja en
     su tabla *_Sync. En un borrado masivo eso (a) es inutil en una copia local
     y (b) puede fallar por PK duplicada. Por eso CADA tabla se purga con sus
     triggers DESHABILITADOS y se REHABILITAN al terminar. En produccion con
     sincronizacion activa, valorar si se quiere conservar ese registro.
   ============================================================================ */

SET NOCOUNT ON;

/* ------------------------- PARAMETROS (AJUSTAR AQUI) ----------------------- */
DECLARE @EjercicioCorte smallint = 2025;          -- se borra Ejercicio < este
DECLARE @FechaCorte     date     = '2025-01-01';  -- se borra Fecha     < esta
DECLARE @Lote           int      = 50000;         -- filas por lote
-- (Manten ambos coherentes: @FechaCorte = 1 de enero del @EjercicioCorte.)

DECLARE @sql   nvarchar(max);
DECLARE @dbtxt varchar(200);

PRINT '=== PURGA DE HISTORICO  (' + DB_NAME() + ') ===';
PRINT '   Corte: Ejercicio < ' + CAST(@EjercicioCorte AS varchar(4))
      + '   /   Fecha < ' + CONVERT(varchar(10), @FechaCorte, 120);
PRINT '';


/* ==========================================================================
   BLOQUE A - Tablas SIMPLES: se filtran por UNA columna (ejercicio o fecha).
   Metadatos: Tabla, Columna de filtro, Modo ('E'=ejercicio / 'F'=fecha).
   Cubre: stock, produccion, contable/estadistico.
   Cada tabla: DISABLE TRIGGER ALL -> DELETE por lotes -> ENABLE TRIGGER ALL.
   ========================================================================== */
DECLARE @simples TABLE (Orden int IDENTITY, Tabla sysname, ColFil sysname, Modo char(1));
INSERT INTO @simples (Tabla, ColFil, Modo) VALUES
  -- Stock (por ejercicio; si no hubiera Ejercicio, el propio bloque hace fallback)
  ('MovimientoStock',     'Ejercicio',          'E'),
  -- Produccion: hijos primero, luego puente, luego padres
  ('ConsumosOT',          'EjercicioTrabajo',   'E'),
  ('OperacionesOT',       'EjercicioTrabajo',   'E'),
  ('RelacionOTOF',        'EjercicioTrabajo',   'E'),
  ('OrdenesTrabajo',      'EjercicioTrabajo',   'E'),
  ('OrdenesFabricacion',  'EjercicioFabricacion','E'),
  -- Contable / estadistico / inventario
  ('Movimientos',         'Ejercicio',          'E'),
  ('MovimientosFacturas', 'Ejercicio',          'E'),
  ('HistoricoCartera',    'Ejercicio',          'E'),
  ('EstadisVenta',        'Ejercicio',          'E'),
  ('EstadisCompra',       'Ejercicio',          'E'),
  ('ConsumosIncidencia',  'EjercicioTrabajo',   'E'),
  ('LineasOfertaCliente', 'EjercicioOferta',    'E'),
  ('Inventarios',         'FechaInventario',    'F');

DECLARE @k int = 1, @kn int = (SELECT MAX(Orden) FROM @simples);
DECLARE @sTab sysname, @sCol sysname, @sModo char(1);

PRINT '=== Tablas simples (stock / produccion / contable) ===';
WHILE @k <= @kn
BEGIN
    SELECT @sTab=Tabla, @sCol=ColFil, @sModo=Modo FROM @simples WHERE Orden=@k;

    -- Stock: si no existe Ejercicio pero si Fecha, purgar por Fecha.
    IF @sTab='MovimientoStock' AND OBJECT_ID('dbo.'+@sTab) IS NOT NULL
       AND COL_LENGTH('dbo.'+@sTab,'Ejercicio') IS NULL
       AND COL_LENGTH('dbo.'+@sTab,'Fecha') IS NOT NULL
    BEGIN
        SET @sCol='Fecha'; SET @sModo='F';
    END

    IF OBJECT_ID('dbo.'+@sTab) IS NOT NULL
       AND COL_LENGTH('dbo.'+@sTab, @sCol) IS NOT NULL
    BEGIN
        PRINT '-> ' + @sTab + ' (por ' + @sCol + ') ...';
        -- Desactivar triggers de sincronizacion durante el borrado
        SET @sql = N'DISABLE TRIGGER ALL ON dbo.' + QUOTENAME(@sTab) + N';';
        EXEC sp_executesql @sql;

        SET @sql = N'
            DECLARE @f int, @t bigint = 0;
            WHILE 1=1 BEGIN
                DELETE TOP (@Lote) FROM dbo.' + QUOTENAME(@sTab) + N'
                WHERE ' + QUOTENAME(@sCol) + N' < ' + CASE WHEN @sModo='E' THEN N'@EjercicioCorte' ELSE N'@FechaCorte' END + N';
                SET @f = @@ROWCOUNT; SET @t += @f;
                IF @f = 0 BREAK;
            END
            PRINT ''   borradas: '' + CAST(@t AS varchar(20));';
        EXEC sp_executesql @sql,
             N'@EjercicioCorte smallint, @FechaCorte date, @Lote int',
             @EjercicioCorte, @FechaCorte, @Lote;

        SET @sql = N'ENABLE TRIGGER ALL ON dbo.' + QUOTENAME(@sTab) + N';';
        EXEC sp_executesql @sql;
    END

    SET @k += 1;
END


/* ==========================================================================
   BLOQUE B - CABECERA + LINEAS (documentos): albaranes y pedidos.
   Las lineas no tienen fecha propia -> se borran por JOIN a su cabecera antigua.
   Enlace: CodigoEmpresa + Serie + Numero. Fecha en la cabecera.
   Orden por par: primero lineas, luego cabecera. Triggers desactivados en ambas.
   ========================================================================== */
DECLARE @docs TABLE (
    Orden     int IDENTITY,
    Cabecera  sysname, Lineas sysname,
    ColSerie  sysname, ColNumero sysname, ColFecha sysname,
    Etiqueta  varchar(60)
);
INSERT INTO @docs (Cabecera, Lineas, ColSerie, ColNumero, ColFecha, Etiqueta) VALUES
  ('CabeceraAlbaranCliente',   'LineasAlbaranCliente',   'SerieAlbaran', 'NumeroAlbaran', 'FechaAlbaran', 'Albaranes de cliente'),
  ('CabeceraAlbaranProveedor', 'LineasAlbaranProveedor', 'SerieAlbaran', 'NumeroAlbaran', 'FechaAlbaran', 'Albaranes de proveedor'),
  ('CabeceraPedidoCliente',    'LineasPedidoCliente',    'SeriePedido',  'NumeroPedido',  'FechaPedido',  'Pedidos de cliente'),
  ('CabeceraPedidoProveedor',  'LineasPedidoProveedor',  'SeriePedido',  'NumeroPedido',  'FechaPedido',  'Pedidos de proveedor');

DECLARE @i int = 1, @n int = (SELECT MAX(Orden) FROM @docs);
DECLARE @Cab sysname, @Lin sysname, @Serie sysname, @Num sysname, @Fecha sysname, @Etq varchar(60);

WHILE @i <= @n
BEGIN
    SELECT @Cab=Cabecera, @Lin=Lineas, @Serie=ColSerie, @Num=ColNumero, @Fecha=ColFecha, @Etq=Etiqueta
    FROM @docs WHERE Orden=@i;

    IF OBJECT_ID('dbo.'+@Cab) IS NOT NULL
       AND COL_LENGTH('dbo.'+@Cab, @Fecha) IS NOT NULL
    BEGIN
        PRINT '';
        PRINT '=== ' + @Etq + ' ===';

        -- LINEAS (join a cabecera antigua)
        IF OBJECT_ID('dbo.'+@Lin) IS NOT NULL
        BEGIN
            PRINT '-> ' + @Lin + ' ...';
            SET @sql = N'DISABLE TRIGGER ALL ON dbo.' + QUOTENAME(@Lin) + N';'; EXEC sp_executesql @sql;
            SET @sql = N'
                DECLARE @f int, @t bigint = 0;
                WHILE 1=1 BEGIN
                    DELETE TOP (@Lote) L
                    FROM dbo.' + QUOTENAME(@Lin) + N' L
                    JOIN dbo.' + QUOTENAME(@Cab) + N' C
                      ON  C.CodigoEmpresa = L.CodigoEmpresa
                      AND C.' + QUOTENAME(@Serie) + N' = L.' + QUOTENAME(@Serie) + N'
                      AND C.' + QUOTENAME(@Num)   + N' = L.' + QUOTENAME(@Num)   + N'
                    WHERE C.' + QUOTENAME(@Fecha) + N' < @FechaCorte;
                    SET @f = @@ROWCOUNT; SET @t += @f;
                    IF @f = 0 BREAK;
                END
                PRINT ''   borradas: '' + CAST(@t AS varchar(20));';
            EXEC sp_executesql @sql, N'@FechaCorte date, @Lote int', @FechaCorte, @Lote;
            SET @sql = N'ENABLE TRIGGER ALL ON dbo.' + QUOTENAME(@Lin) + N';'; EXEC sp_executesql @sql;
        END

        -- CABECERAS
        PRINT '-> ' + @Cab + ' ...';
        SET @sql = N'DISABLE TRIGGER ALL ON dbo.' + QUOTENAME(@Cab) + N';'; EXEC sp_executesql @sql;
        SET @sql = N'
            DECLARE @f int, @t bigint = 0;
            WHILE 1=1 BEGIN
                DELETE TOP (@Lote) FROM dbo.' + QUOTENAME(@Cab) + N'
                WHERE ' + QUOTENAME(@Fecha) + N' < @FechaCorte;
                SET @f = @@ROWCOUNT; SET @t += @f;
                IF @f = 0 BREAK;
            END
            PRINT ''   borradas: '' + CAST(@t AS varchar(20));';
        EXEC sp_executesql @sql, N'@FechaCorte date, @Lote int', @FechaCorte, @Lote;
        SET @sql = N'ENABLE TRIGGER ALL ON dbo.' + QUOTENAME(@Cab) + N';'; EXEC sp_executesql @sql;
    END

    SET @i += 1;
END


/* ==========================================================================
   BLOQUE C - TABLAS TECNICAS / BACKUP: se vacian ENTERAS (no son negocio).
      - lsysTrace                : traza de auditoria de LogicClass.
      - CabeceraPedidoCliente_Bak: backup de tabla (_Bak), sin FKs.
   TRUNCATE (instantaneo). Si falla (permisos/FK), cae a DELETE por lotes.
   Anade aqui otras tablas *_Bak / traza que quieras vaciar en cada cliente.
   ========================================================================== */
PRINT '';
PRINT '=== Tablas tecnicas / backup (vaciado completo) ===';

DECLARE @vaciar TABLE (Orden int IDENTITY, Tabla sysname);
INSERT INTO @vaciar (Tabla) VALUES
  ('lsysTrace'),
  ('CabeceraPedidoCliente_Bak');

DECLARE @v int = 1, @vn int = (SELECT MAX(Orden) FROM @vaciar);
DECLARE @vTab sysname;

WHILE @v <= @vn
BEGIN
    SELECT @vTab=Tabla FROM @vaciar WHERE Orden=@v;
    IF OBJECT_ID('dbo.'+@vTab) IS NOT NULL
    BEGIN
        PRINT '-> ' + @vTab + ' (TRUNCATE) ...';
        BEGIN TRY
            SET @sql = N'TRUNCATE TABLE dbo.' + QUOTENAME(@vTab) + N';';
            EXEC sp_executesql @sql;
            PRINT '   ok (truncate)';
        END TRY
        BEGIN CATCH
            PRINT '   truncate fallo, borrando por lotes: ' + ERROR_MESSAGE();
            SET @sql = N'DISABLE TRIGGER ALL ON dbo.' + QUOTENAME(@vTab) + N';'; EXEC sp_executesql @sql;
            SET @sql = N'
                DECLARE @f int, @t bigint = 0;
                WHILE 1=1 BEGIN
                    DELETE TOP (@Lote) FROM dbo.' + QUOTENAME(@vTab) + N';
                    SET @f = @@ROWCOUNT; SET @t += @f;
                    IF @f = 0 BREAK;
                END
                PRINT ''   borradas: '' + CAST(@t AS varchar(20));';
            EXEC sp_executesql @sql, N'@Lote int', @Lote;
            SET @sql = N'ENABLE TRIGGER ALL ON dbo.' + QUOTENAME(@vTab) + N';'; EXEC sp_executesql @sql;
        END CATCH
    END
    SET @v += 1;
END

PRINT '';
PRINT '=== PURGA COMPLETADA ===';
GO


/* ==========================================================================
   BLOQUE D - RECUPERAR ESPACIO EN DISCO + estadisticas.
   Tras borrar millones de filas el fichero de datos NO se encoge solo.
   Usa DB_NAME() -> funciona en cualquier cliente sin editar el nombre.
   (En produccion, valorar: el shrink fragmenta indices; reconstruir despues.)
   ========================================================================== */
PRINT '';
PRINT '=== Recuperando espacio y actualizando estadisticas ===';
DECLARE @db sysname = DB_NAME();
DBCC SHRINKDATABASE (@db) WITH NO_INFOMSGS;
EXEC sp_updatestats;
PRINT '=== Mantenimiento completado ===';
GO


/* ============================================================================
   NOTA - Tablas *_Sync (MovimientoStock_Sync, Movimientos_Sync, ...):
     Espejos de sincronizacion de LogicClass. No se purgan aqui. Si en la copia
     local se quiere reducir su tamano y NO se va a sincronizar, vaciarlas de
     forma explicita, p.ej.:
       -- TRUNCATE TABLE dbo.MovimientoStock_Sync;
       -- TRUNCATE TABLE dbo.Movimientos_Sync;
   ============================================================================ */
