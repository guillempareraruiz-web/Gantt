-- ===========================================================================
-- V024 - FS_PL_Cfg_GridColumns: indicar nivel del Raw_Item al que aplica
--
-- Cada definicion de columna custom dice a que NIVEL del Raw_Item se lee
-- el valor:
--   1 = OF / PEDIDO / PROYECTO (cabecera)
--   2 = OT  / LINEA  / TAREA   (intermedio)
--   3 = OP                     (operacion / leaf)
-- NULL = no especificado (caera al nivel del leaf por defecto).
--
-- Combinado con SourceEntity (OF/PEDIDO/PROYECTO) determina el RawItemId
-- contra el que se hace el JOIN en la vista del Backlog.
-- ===========================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH('FS_PL_Cfg_GridColumns', 'AppliesToNivel') IS NULL
    ALTER TABLE FS_PL_Cfg_GridColumns ADD AppliesToNivel TINYINT NULL;
GO

-- Por defecto, los campos custom existentes (que estaban acoplados a las
-- _Extra antiguas Raw_OF_Extra/Raw_Comanda_Extra/Raw_Projecte_Extra) se
-- aplican al Nivel=1 (cabecera), que era el comportamiento implicito.
UPDATE FS_PL_Cfg_GridColumns
   SET AppliesToNivel = 1
 WHERE IsCustomField = 1
   AND AppliesToNivel IS NULL
   AND SourceEntity IN ('OF','PEDIDO','PROYECTO');
GO
