-- ============================================================================
-- V084 - Modulos por licencia
-- ============================================================================
--
-- No todos los clientes necesitan todo el Planner, y no todos lo compran. Esta
-- tabla dice QUE MODULOS tiene contratados cada empresa.
--
-- Por que una TABLA y no columnas en FS_PL_Empresa (que es lo que hizo V008 con
-- PlanificaOperarios / PlanificaMoldes): los modulos van a crecer, y una
-- columna por modulo obliga a un ALTER TABLE y una migracion cada vez que se
-- empaqueta algo nuevo. Con filas, dar de alta un modulo es un INSERT.
--
-- ---------------------------------------------------------------------------
-- QUE ES Y QUE NO ES ESTO
-- ---------------------------------------------------------------------------
--
-- Es HIGIENE DE INTERFAZ y soporte a la venta por modulos: que un cliente que
-- solo ha comprado produccion no vea media aplicacion que no le sirve, y que
-- comercialmente se pueda vender por partes.
--
-- NO es proteccion anticopia. Un administrador del cliente con acceso a SQL
-- Server puede poner Activo = 1 a mano. Se asume a conciencia: en este mercado
-- el cliente no hace eso, y si lo hiciera aparece en el contrato de
-- mantenimiento. Si algun dia hiciera falta proteccion real, la fuente de los
-- modulos se cambia por un fichero firmado SIN tocar el resto del codigo, que
-- pregunta siempre por uModulos.IsModuleEnabled.
--
-- ---------------------------------------------------------------------------
-- COMPATIBILIDAD
-- ---------------------------------------------------------------------------
--
-- Toda instalacion existente se queda con TODO ACTIVO. Nadie debe perder
-- funcionalidad por actualizar: los modulos se desactivan a mano, cuando
-- comercialmente toque, no por efecto de una migracion.
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Modulo')
CREATE TABLE FS_PL_Modulo (
    CodigoEmpresa   SMALLINT      NOT NULL,
    -- Codigo estable del modulo ('OPERARIOS', 'INGENIERIA', ...). Es la clave
    -- que usa el codigo: NO renombrar nunca uno existente.
    Codigo          NVARCHAR(30)  NOT NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_FS_PL_Modulo_Activo DEFAULT (1),
    -- Fin de licencia. NULL = sin caducidad (lo normal en venta perpetua).
    -- Se guarda aunque hoy no se compruebe: cuando se comprueben suscripciones
    -- el dato ya estara.
    FechaCaducidad  DATE          NULL,
    -- Notas del comercial: numero de pedido, condiciones, con quien se hablo.
    Observaciones   NVARCHAR(500) NULL,
    CONSTRAINT PK_FS_PL_Modulo PRIMARY KEY (CodigoEmpresa, Codigo)
);
GO

-- ----------------------------------------------------------------------------
-- Alta de los modulos conocidos, TODOS ACTIVOS, para cada empresa existente.
--
-- Idempotente: solo inserta los que falten, asi que se puede re-ejecutar y
-- ademas una version futura puede anadir modulos nuevos repitiendo el patron
-- sin pisar lo que el cliente tenga configurado.
-- ----------------------------------------------------------------------------
;WITH Modulos(Codigo) AS (
    SELECT 'OPERARIOS'    UNION ALL
    SELECT 'INGENIERIA'   UNION ALL
    SELECT 'MRP'          UNION ALL
    SELECT 'UTILLAJES'    UNION ALL
    SELECT 'OPTIMIZACION' UNION ALL
    SELECT 'ANALITICA'    UNION ALL
    SELECT 'NESTING'
)
INSERT INTO FS_PL_Modulo (CodigoEmpresa, Codigo, Activo)
SELECT e.CodigoEmpresa, m.Codigo, 1
FROM FS_PL_Empresa e
CROSS JOIN Modulos m
WHERE NOT EXISTS (
    SELECT 1 FROM FS_PL_Modulo x
    WHERE x.CodigoEmpresa = e.CodigoEmpresa AND x.Codigo = m.Codigo
);
GO
