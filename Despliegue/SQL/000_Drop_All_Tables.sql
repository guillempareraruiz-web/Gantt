-- ============================================================================
-- FSPlanner 2026 - Eliminar todas las tablas FS_PL_*
-- EJECUTAR ANTES de 001 y 002 si las tablas ya existen sin CodigoEmpresa
-- ¡¡¡ CUIDADO: ELIMINA TODOS LOS DATOS !!!
-- ============================================================================

-- Orden inverso por dependencias (hijos primero, padres después)

-- Relaciones y detalles
IF OBJECT_ID('FS_PL_RolePermission', 'U') IS NOT NULL DROP TABLE FS_PL_RolePermission;
IF OBJECT_ID('FS_PL_AccessLog', 'U') IS NOT NULL DROP TABLE FS_PL_AccessLog;
IF OBJECT_ID('FS_PL_CustomFieldValue', 'U') IS NOT NULL DROP TABLE FS_PL_CustomFieldValue;
IF OBJECT_ID('FS_PL_NodeCenterAllowed', 'U') IS NOT NULL DROP TABLE FS_PL_NodeCenterAllowed;
IF OBJECT_ID('FS_PL_OperatorAssignment', 'U') IS NOT NULL DROP TABLE FS_PL_OperatorAssignment;
IF OBJECT_ID('FS_PL_OperatorDepartment', 'U') IS NOT NULL DROP TABLE FS_PL_OperatorDepartment;
IF OBJECT_ID('FS_PL_OperatorSkill', 'U') IS NOT NULL DROP TABLE FS_PL_OperatorSkill;
IF OBJECT_ID('FS_PL_MoldCenter', 'U') IS NOT NULL DROP TABLE FS_PL_MoldCenter;
IF OBJECT_ID('FS_PL_MoldArticle', 'U') IS NOT NULL DROP TABLE FS_PL_MoldArticle;
IF OBJECT_ID('FS_PL_MoldOperation', 'U') IS NOT NULL DROP TABLE FS_PL_MoldOperation;
IF OBJECT_ID('FS_PL_ShiftProfileSlot', 'U') IS NOT NULL DROP TABLE FS_PL_ShiftProfileSlot;
IF OBJECT_ID('FS_PL_SortRule', 'U') IS NOT NULL DROP TABLE FS_PL_SortRule;
IF OBJECT_ID('FS_PL_FilterRule', 'U') IS NOT NULL DROP TABLE FS_PL_FilterRule;
IF OBJECT_ID('FS_PL_GroupRule', 'U') IS NOT NULL DROP TABLE FS_PL_GroupRule;
IF OBJECT_ID('FS_PL_CalendarDayRule', 'U') IS NOT NULL DROP TABLE FS_PL_CalendarDayRule;
IF OBJECT_ID('FS_PL_CalendarException', 'U') IS NOT NULL DROP TABLE FS_PL_CalendarException;
IF OBJECT_ID('FS_PL_CenterCalendar', 'U') IS NOT NULL DROP TABLE FS_PL_CenterCalendar;
IF OBJECT_ID('FS_PL_Dependency', 'U') IS NOT NULL DROP TABLE FS_PL_Dependency;
IF OBJECT_ID('FS_PL_Marker', 'U') IS NOT NULL DROP TABLE FS_PL_Marker;
IF OBJECT_ID('FS_PL_Snapshot', 'U') IS NOT NULL DROP TABLE FS_PL_Snapshot;
IF OBJECT_ID('FS_PL_ErpMapping', 'U') IS NOT NULL DROP TABLE FS_PL_ErpMapping;
IF OBJECT_ID('FS_PL_AuditLog', 'U') IS NOT NULL DROP TABLE FS_PL_AuditLog;

-- Entidades con datos de negocio
IF OBJECT_ID('FS_PL_NodeData', 'U') IS NOT NULL DROP TABLE FS_PL_NodeData;
IF OBJECT_ID('FS_PL_Node', 'U') IS NOT NULL DROP TABLE FS_PL_Node;
IF OBJECT_ID('FS_PL_Mold', 'U') IS NOT NULL DROP TABLE FS_PL_Mold;
IF OBJECT_ID('FS_PL_Operator', 'U') IS NOT NULL DROP TABLE FS_PL_Operator;
IF OBJECT_ID('FS_PL_Department', 'U') IS NOT NULL DROP TABLE FS_PL_Department;
IF OBJECT_ID('FS_PL_CustomFieldDef', 'U') IS NOT NULL DROP TABLE FS_PL_CustomFieldDef;
IF OBJECT_ID('FS_PL_PlanningProfile', 'U') IS NOT NULL DROP TABLE FS_PL_PlanningProfile;
IF OBJECT_ID('FS_PL_ShiftProfile', 'U') IS NOT NULL DROP TABLE FS_PL_ShiftProfile;
IF OBJECT_ID('FS_PL_Shift', 'U') IS NOT NULL DROP TABLE FS_PL_Shift;
IF OBJECT_ID('FS_PL_Center', 'U') IS NOT NULL DROP TABLE FS_PL_Center;
IF OBJECT_ID('FS_PL_Calendar', 'U') IS NOT NULL DROP TABLE FS_PL_Calendar;
IF OBJECT_ID('FS_PL_Project', 'U') IS NOT NULL DROP TABLE FS_PL_Project;
IF OBJECT_ID('FS_PL_Area', 'U') IS NOT NULL DROP TABLE FS_PL_Area;
IF OBJECT_ID('FS_PL_Almacen', 'U') IS NOT NULL DROP TABLE FS_PL_Almacen;

-- Usuarios y seguridad
IF OBJECT_ID('FS_PL_User', 'U') IS NOT NULL DROP TABLE FS_PL_User;
IF OBJECT_ID('FS_PL_Permission', 'U') IS NOT NULL DROP TABLE FS_PL_Permission;
IF OBJECT_ID('FS_PL_Role', 'U') IS NOT NULL DROP TABLE FS_PL_Role;
IF OBJECT_ID('FS_PL_Empresa', 'U') IS NOT NULL DROP TABLE FS_PL_Empresa;

PRINT '==========================================';
PRINT 'Todas las tablas FS_PL_* eliminadas';
PRINT '==========================================';
GO
