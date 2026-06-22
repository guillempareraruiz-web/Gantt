-- ===========================================================================
-- Reparacion puntual (NO es migracion de esquema): rellena en FS_PL_NodeData
-- los campos NumeroOF / SerieOF / NumeroTrabajo / FechaEntrega / FechaNecesaria
-- de los nodos YA CREADOS, tomandolos de la cadena de herencia del Raw_Item
-- (OP -> OT(p1) -> OF(p2)), igual que hace ahora el wizard de planificacion.
--
-- Motivo: nodos planificados antes del fix de codigo guardaban NumeroOF=0
-- (COALESCE no salta el 0 de los niveles OT/OP) y NumeroTrabajo/fechas vacios.
-- Aqui usamos CASE por nivel (como la vista V052), no COALESCE, para el numero.
--
-- IMPORTANTE: recargar el plan en la app DESPUES de ejecutar esto, para que el
-- repo en memoria lea los valores reparados y el autosaver no los pise.
-- ===========================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET NOCOUNT ON;
GO

UPDATE nd SET
  nd.NumeroOF = CASE ri.Nivel WHEN 1 THEN ri.NumeroDoc WHEN 2 THEN p1.NumeroDoc WHEN 3 THEN p2.NumeroDoc END,
  nd.SerieOF  = CASE ri.Nivel WHEN 1 THEN ri.SerieDoc  WHEN 2 THEN p1.SerieDoc  WHEN 3 THEN p2.SerieDoc  END,
  nd.NumeroTrabajo  = CASE WHEN ISNULL(p1.Codigo,'') <> '' THEN p1.Codigo ELSE nd.NumeroTrabajo END,
  nd.FechaEntrega   = COALESCE(ri.FechaCompromiso, p1.FechaCompromiso, p2.FechaCompromiso, nd.FechaEntrega),
  nd.FechaNecesaria = COALESCE(ri.FechaCompromiso, p1.FechaCompromiso, p2.FechaCompromiso, nd.FechaNecesaria)
FROM FS_PL_NodeData nd
JOIN FS_PL_Raw_Item ri
  ON ri.CodigoEmpresa = nd.CodigoEmpresa
 AND ri.TipoOrigen    = nd.RawItemTipoOrigen
 AND ri.ClaveERP      = nd.RawItemClaveERP
LEFT JOIN FS_PL_Raw_Item p1
  ON p1.CodigoEmpresa = ri.CodigoEmpresa AND p1.RawItemId = ri.ParentRawItemId
LEFT JOIN FS_PL_Raw_Item p2
  ON p2.CodigoEmpresa = p1.CodigoEmpresa AND p2.RawItemId = p1.ParentRawItemId
WHERE ri.TipoOrigen = 'OF ';
GO
