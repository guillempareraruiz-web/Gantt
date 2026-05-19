-- V031: Una sola excepcion por (Empresa, Calendario, Fecha)
-- Si hubiera duplicados historicos, conservamos el ExceptionId mas alto (mas reciente).
IF EXISTS (
  SELECT 1
  FROM FS_PL_CalendarException
  GROUP BY CodigoEmpresa, CalendarId, Fecha
  HAVING COUNT(*) > 1
)
BEGIN
  ;WITH Dups AS (
    SELECT ExceptionId,
           ROW_NUMBER() OVER (
             PARTITION BY CodigoEmpresa, CalendarId, Fecha
             ORDER BY ExceptionId DESC
           ) AS rn
    FROM FS_PL_CalendarException
  )
  DELETE FROM FS_PL_CalendarException
  WHERE ExceptionId IN (SELECT ExceptionId FROM Dups WHERE rn > 1);
END

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'UQ_FS_PL_CalendarException_Fecha'
    AND object_id = OBJECT_ID('FS_PL_CalendarException')
)
CREATE UNIQUE INDEX UQ_FS_PL_CalendarException_Fecha
  ON FS_PL_CalendarException (CodigoEmpresa, CalendarId, Fecha);
