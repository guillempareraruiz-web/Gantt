-- ============================================================================
-- V015 - Procedure FS_PL_sp_ClearProjectPlan
--        Borra todo lo planificado de un proyecto (Nodes + Dependencias +
--        Markers + Snapshots) dejando el Gantt vacio. Mantiene el proyecto,
--        centros, calendarios y Backlog/staging intactos.
--        Las tablas FS_PL_NodeData, FS_PL_NodeCenterAllowed,
--        FS_PL_OperatorAssignment y FS_PL_CustomFieldValue se vacian solas
--        por ON DELETE CASCADE al borrar los nodos.
-- ============================================================================

IF OBJECT_ID('FS_PL_sp_ClearProjectPlan', 'P') IS NOT NULL
    DROP PROCEDURE FS_PL_sp_ClearProjectPlan;
GO

CREATE PROCEDURE FS_PL_sp_ClearProjectPlan
    @CodigoEmpresa SMALLINT,
    @ProjectId     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRAN;

        DELETE FROM FS_PL_Dependency
         WHERE CodigoEmpresa = @CodigoEmpresa AND ProjectId = @ProjectId;

        DELETE FROM FS_PL_Marker
         WHERE CodigoEmpresa = @CodigoEmpresa AND ProjectId = @ProjectId;

        DELETE FROM FS_PL_Snapshot
         WHERE CodigoEmpresa = @CodigoEmpresa AND ProjectId = @ProjectId;

        DELETE FROM FS_PL_Node
         WHERE CodigoEmpresa = @CodigoEmpresa AND ProjectId = @ProjectId;

    COMMIT;
END;
GO
