-- =============================================================================
-- V079 - Avance de fabricacion por nodo (Modulo de Proyectos, paradigma TAREAS)
-- =============================================================================
-- Anade FS_PL_Node.MinutosInvertidos: el tiempo REAL dedicado a la tarea, que
-- el usuario introduce a mano (doble clic sobre el nodo -> NodeInspector).
--
-- Se guardan MINUTOS, no un porcentaje: el % de avance es un DERIVADO
-- (MinutosInvertidos / DuracionMin), no un dato independiente. Persistir ambos
-- obligaria a mantenerlos sincronizados y acabarian contradiciendose en cuanto
-- cambiase la duracion de la tarea.
--
-- Unidad: minutos, igual que DuracionMin, para no mezclar unidades en la misma
-- tabla (la UI puede pedirlo en horas y convertir).
--
-- Solo se rellena en tareas HOJA. El avance de una tarea RESUMEN no se
-- persiste: se calcula al vuelo agregando el de sus descendientes, ponderado
-- por duracion (uWbsScheduler), igual que hace MS Project.
--
-- Aditivo e idempotente: se puede reejecutar sin efecto.
-- =============================================================================

IF COL_LENGTH('FS_PL_Node', 'MinutosInvertidos') IS NULL
BEGIN
    ALTER TABLE FS_PL_Node
        ADD MinutosInvertidos DECIMAL(12,2) NOT NULL
            CONSTRAINT DF_FS_PL_Node_MinutosInvertidos DEFAULT (0);

    PRINT 'V079: FS_PL_Node.MinutosInvertidos anadida.';
END
ELSE
    PRINT 'V079: FS_PL_Node.MinutosInvertidos ya existia.';
GO

-- No se admiten tiempos negativos. NO se acota por arriba a DuracionMin: una
-- tarea puede consumir mas tiempo del estimado, y ese sobrecoste es justo la
-- informacion valiosa (avance > 100% = desviacion).
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_FS_PL_Node_MinutosInvertidos')
BEGIN
    ALTER TABLE FS_PL_Node
        ADD CONSTRAINT CK_FS_PL_Node_MinutosInvertidos
            CHECK (MinutosInvertidos >= 0);

    PRINT 'V079: CHECK MinutosInvertidos >= 0 anadido.';
END
GO
