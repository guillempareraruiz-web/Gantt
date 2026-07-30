-- ===========================================================================
-- V065 - Centros de sistema por defecto: SIN CENTRO y CENTRO EXTERNO.
--
-- Dos centros "de sistema" que existen siempre en el Gantt para que ninguna OP/
-- OT/OF se quede fuera del plan por no tener centro asignado:
--
--   __SINCENTRO__  "Sin centro"     : cajon de sastre. Toda carga sin centro
--                                     valido aterriza aqui y el planificador la
--                                     arrastra manualmente al centro real.
--   __EXTERNO__    "Centro externo" : trabajo subcontratado / fabricado en
--                                     talleres externos.
--
-- Codigos con dobles guiones bajos para no colisionar con codigos de centro del
-- ERP. Orden muy alto para que aparezcan al final del Gantt. MaxLanes alto en
-- SIN CENTRO (acumula muchas OP en paralelo sin saturar). Color gris/naranja
-- suave para distinguirlos visualmente.
--
-- Seed idempotente por empresa: inserta solo si el CodigoCentro no existe ya.
-- Se siembra para cada CodigoEmpresa que ya tenga algun centro (multiempresa).
-- ===========================================================================

SET NOCOUNT ON;
GO

-- Para cada empresa con centros, asegurar los dos centros de sistema.
;WITH Empresas AS (
    SELECT DISTINCT CodigoEmpresa FROM dbo.FS_PL_Center
)
INSERT INTO dbo.FS_PL_Center
    (CodigoEmpresa, CodigoCentro, Titulo, Subtitulo, EsSecuencial, MaxLanes,
     AlturaBase, Orden, Visible, Habilitado, ColorFondo)
SELECT e.CodigoEmpresa, v.CodigoCentro, v.Titulo, v.Subtitulo, 0, v.MaxLanes,
       40, v.Orden, 1, 1, v.ColorFondo
FROM Empresas e
CROSS JOIN (VALUES
    ('__SINCENTRO__', 'Sin centro',     'Carga sin centro asignado', 999, 99,
        15790320),   -- gris claro (BGR ~ $00F0F0F0)
    ('__EXTERNO__',   'Centro externo', 'Trabajo subcontratado',     998, 8,
        7186930)     -- naranja suave
) AS v(CodigoCentro, Titulo, Subtitulo, Orden, MaxLanes, ColorFondo)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.FS_PL_Center c
    WHERE c.CodigoEmpresa = e.CodigoEmpresa
      AND c.CodigoCentro  = v.CodigoCentro);
GO

-- Si la BD aun no tiene NINGUN centro (instalacion nueva sin sync), sembrar al
-- menos para la empresa 1, para que el Gantt nunca quede sin estos dos centros.
IF NOT EXISTS (SELECT 1 FROM dbo.FS_PL_Center WHERE CodigoCentro = '__SINCENTRO__')
INSERT INTO dbo.FS_PL_Center
    (CodigoEmpresa, CodigoCentro, Titulo, Subtitulo, EsSecuencial, MaxLanes,
     AlturaBase, Orden, Visible, Habilitado, ColorFondo)
VALUES
    (1, '__SINCENTRO__', 'Sin centro',     'Carga sin centro asignado', 0, 99, 40, 999, 1, 1, 15790320),
    (1, '__EXTERNO__',   'Centro externo', 'Trabajo subcontratado',     0,  8, 40, 998, 1, 1, 7186930);
GO
