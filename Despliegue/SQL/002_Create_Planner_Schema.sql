-- ============================================================================
-- FSPlanner 2026 - Estructura de base de datos
-- Script de creación de tablas, índices y constraints
-- Prefijo: FS_PL_
-- Motor: SQL Server 2016+
-- NOTA: Todas las tablas incluyen CodigoEmpresa (SMALLINT) como parte de la PK
--       para soportar multi-empresa (multi-tenant)
-- ============================================================================

-- ============================================================================
-- 1. PROYECTO / PLANNING
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Project')
CREATE TABLE FS_PL_Project (
    CodigoEmpresa   SMALLINT      NOT NULL,
    ProjectId       INT IDENTITY(1,1) NOT NULL,
    Codigo          NVARCHAR(30)  NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Descripcion     NVARCHAR(MAX) NULL,
    FechaCreacion   DATETIME2     NOT NULL DEFAULT GETDATE(),
    FechaModificacion DATETIME2   NOT NULL DEFAULT GETDATE(),
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Project PRIMARY KEY (CodigoEmpresa, ProjectId),
    CONSTRAINT UQ_FS_PL_Project_Codigo UNIQUE (CodigoEmpresa, Codigo)
);

-- ============================================================================
-- 2. ÁREAS
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Area')
CREATE TABLE FS_PL_Area (
    CodigoEmpresa   SMALLINT      NOT NULL,
    AreaId          INT IDENTITY(1,1) NOT NULL,
    Codigo          NVARCHAR(30)  NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Orden           INT           NOT NULL DEFAULT 0,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Area PRIMARY KEY (CodigoEmpresa, AreaId),
    CONSTRAINT UQ_FS_PL_Area_Codigo UNIQUE (CodigoEmpresa, Codigo)
);

-- ============================================================================
-- 3. CENTROS DE TRABAJO
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Center')
CREATE TABLE FS_PL_Center (
    CodigoEmpresa   SMALLINT      NOT NULL,
    CenterId        INT IDENTITY(1,1) NOT NULL,
    CodigoCentro    NVARCHAR(30)  NOT NULL,
    Titulo          NVARCHAR(200) NOT NULL,
    Subtitulo       NVARCHAR(200) NULL,
    AreaId          INT           NULL,
    EsSecuencial    BIT           NOT NULL DEFAULT 0,
    MaxLanes        INT           NOT NULL DEFAULT 0,
    AlturaBase      DECIMAL(8,2)  NOT NULL DEFAULT 40,
    Orden           INT           NOT NULL DEFAULT 0,
    Visible         BIT           NOT NULL DEFAULT 1,
    Habilitado      BIT           NOT NULL DEFAULT 1,
    ColorFondo      INT           NULL,
    CONSTRAINT PK_FS_PL_Center PRIMARY KEY (CodigoEmpresa, CenterId),
    CONSTRAINT UQ_FS_PL_Center_Codigo UNIQUE (CodigoEmpresa, CodigoCentro),
    CONSTRAINT FK_FS_PL_Center_Area FOREIGN KEY (CodigoEmpresa, AreaId) REFERENCES FS_PL_Area(CodigoEmpresa, AreaId)
);

-- ============================================================================
-- 4. CALENDARIOS
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Calendar')
CREATE TABLE FS_PL_Calendar (
    CodigoEmpresa   SMALLINT      NOT NULL,
    CalendarId      INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(100) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Calendar PRIMARY KEY (CodigoEmpresa, CalendarId),
    CONSTRAINT UQ_FS_PL_Calendar_Nombre UNIQUE (CodigoEmpresa, Nombre)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_CalendarDayRule')
CREATE TABLE FS_PL_CalendarDayRule (
    CodigoEmpresa   SMALLINT      NOT NULL,
    DayRuleId       INT IDENTITY(1,1) NOT NULL,
    CalendarId      INT           NOT NULL,
    DiaSemana       INT           NOT NULL,
    HoraInicioNoLab TIME          NOT NULL,
    HoraFinNoLab    TIME          NOT NULL,
    CONSTRAINT PK_FS_PL_CalendarDayRule PRIMARY KEY (CodigoEmpresa, DayRuleId),
    CONSTRAINT FK_FS_PL_CalDayRule_Cal FOREIGN KEY (CodigoEmpresa, CalendarId) REFERENCES FS_PL_Calendar(CodigoEmpresa, CalendarId) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_CalendarException')
CREATE TABLE FS_PL_CalendarException (
    CodigoEmpresa   SMALLINT      NOT NULL,
    ExceptionId     INT IDENTITY(1,1) NOT NULL,
    CalendarId      INT           NOT NULL,
    Fecha           DATE          NOT NULL,
    EsLaborable     BIT           NOT NULL DEFAULT 0,
    HoraInicio      TIME          NULL,
    HoraFin         TIME          NULL,
    Descripcion     NVARCHAR(200) NULL,
    CONSTRAINT PK_FS_PL_CalendarException PRIMARY KEY (CodigoEmpresa, ExceptionId),
    CONSTRAINT FK_FS_PL_CalException_Cal FOREIGN KEY (CodigoEmpresa, CalendarId) REFERENCES FS_PL_Calendar(CodigoEmpresa, CalendarId) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_CenterCalendar')
CREATE TABLE FS_PL_CenterCalendar (
    CodigoEmpresa   SMALLINT      NOT NULL,
    CenterId        INT           NOT NULL,
    CalendarId      INT           NOT NULL,
    CONSTRAINT PK_FS_PL_CenterCalendar PRIMARY KEY (CodigoEmpresa, CenterId, CalendarId),
    CONSTRAINT FK_FS_PL_CenterCal_Center FOREIGN KEY (CodigoEmpresa, CenterId) REFERENCES FS_PL_Center(CodigoEmpresa, CenterId),
    CONSTRAINT FK_FS_PL_CenterCal_Cal FOREIGN KEY (CodigoEmpresa, CalendarId) REFERENCES FS_PL_Calendar(CodigoEmpresa, CalendarId)
);

-- ============================================================================
-- 5. TURNOS
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Shift')
CREATE TABLE FS_PL_Shift (
    CodigoEmpresa   SMALLINT      NOT NULL,
    ShiftId         INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(100) NOT NULL,
    HoraInicio      TIME          NOT NULL,
    HoraFin         TIME          NOT NULL,
    Color           INT           NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    Orden           INT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_Shift PRIMARY KEY (CodigoEmpresa, ShiftId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_ShiftProfile')
CREATE TABLE FS_PL_ShiftProfile (
    CodigoEmpresa   SMALLINT      NOT NULL,
    ProfileId       INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(100) NOT NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_ShiftProfile PRIMARY KEY (CodigoEmpresa, ProfileId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_ShiftProfileSlot')
CREATE TABLE FS_PL_ShiftProfileSlot (
    CodigoEmpresa   SMALLINT      NOT NULL,
    SlotId          INT IDENTITY(1,1) NOT NULL,
    ProfileId       INT           NOT NULL,
    Nombre          NVARCHAR(100) NOT NULL,
    HoraInicio      TIME          NOT NULL,
    HoraFin         TIME          NOT NULL,
    Color           INT           NULL,
    Orden           INT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_ShiftProfileSlot PRIMARY KEY (CodigoEmpresa, SlotId),
    CONSTRAINT FK_FS_PL_ShiftProfSlot_Prof FOREIGN KEY (CodigoEmpresa, ProfileId) REFERENCES FS_PL_ShiftProfile(CodigoEmpresa, ProfileId) ON DELETE CASCADE
);

-- ============================================================================
-- 6. DEPARTAMENTOS
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Department')
CREATE TABLE FS_PL_Department (
    CodigoEmpresa   SMALLINT      NOT NULL,
    DepartmentId    INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    CONSTRAINT PK_FS_PL_Department PRIMARY KEY (CodigoEmpresa, DepartmentId)
);

-- ============================================================================
-- 7. OPERARIOS
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Operator')
CREATE TABLE FS_PL_Operator (
    CodigoEmpresa   SMALLINT      NOT NULL,
    OperatorId      INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    CalendarId      INT           NULL,
    Activo          BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Operator PRIMARY KEY (CodigoEmpresa, OperatorId),
    CONSTRAINT FK_FS_PL_Operator_Cal FOREIGN KEY (CodigoEmpresa, CalendarId) REFERENCES FS_PL_Calendar(CodigoEmpresa, CalendarId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_OperatorDepartment')
CREATE TABLE FS_PL_OperatorDepartment (
    CodigoEmpresa   SMALLINT      NOT NULL,
    OperatorId      INT           NOT NULL,
    DepartmentId    INT           NOT NULL,
    CONSTRAINT PK_FS_PL_OperatorDept PRIMARY KEY (CodigoEmpresa, OperatorId, DepartmentId),
    CONSTRAINT FK_FS_PL_OpDept_Op FOREIGN KEY (CodigoEmpresa, OperatorId) REFERENCES FS_PL_Operator(CodigoEmpresa, OperatorId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_OpDept_Dept FOREIGN KEY (CodigoEmpresa, DepartmentId) REFERENCES FS_PL_Department(CodigoEmpresa, DepartmentId) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_OperatorSkill')
CREATE TABLE FS_PL_OperatorSkill (
    CodigoEmpresa   SMALLINT      NOT NULL,
    OperatorId      INT           NOT NULL,
    Operacion       NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_FS_PL_OperatorSkill PRIMARY KEY (CodigoEmpresa, OperatorId, Operacion),
    CONSTRAINT FK_FS_PL_OpSkill_Op FOREIGN KEY (CodigoEmpresa, OperatorId) REFERENCES FS_PL_Operator(CodigoEmpresa, OperatorId) ON DELETE CASCADE
);

-- ============================================================================
-- 8. NODOS (OF / OPERACIONES PLANIFICADAS)
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Node')
CREATE TABLE FS_PL_Node (
    CodigoEmpresa   SMALLINT      NOT NULL,
    NodeId          INT IDENTITY(1,1) NOT NULL,
    ProjectId       INT           NOT NULL,
    CenterId        INT           NULL,
    FechaInicio     DATETIME2     NULL,
    FechaFin        DATETIME2     NULL,
    DuracionMin     DECIMAL(12,2) NOT NULL DEFAULT 0,
    Caption         NVARCHAR(500) NULL,
    ColorFondo      INT           NULL DEFAULT 15251072,  -- BGR $00E8B880 azul cal
    ColorBorde      INT           NULL DEFAULT 11166760,  -- BGR $00AA6428 azul cal oscuro
    Visible         BIT           NOT NULL DEFAULT 1,
    Habilitado      BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_FS_PL_Node PRIMARY KEY (CodigoEmpresa, NodeId),
    CONSTRAINT FK_FS_PL_Node_Project FOREIGN KEY (CodigoEmpresa, ProjectId) REFERENCES FS_PL_Project(CodigoEmpresa, ProjectId),
    CONSTRAINT FK_FS_PL_Node_Center FOREIGN KEY (CodigoEmpresa, CenterId) REFERENCES FS_PL_Center(CodigoEmpresa, CenterId)
);

-- ============================================================================
-- 9. DATOS DE NEGOCIO DEL NODO (NodeData)
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_NodeData')
CREATE TABLE FS_PL_NodeData (
    CodigoEmpresa       SMALLINT      NOT NULL,
    NodeId              INT           NOT NULL,
    Operacion           NVARCHAR(100) NULL,
    NumeroPedido        INT           NULL,
    SeriePedido         NVARCHAR(20)  NULL,
    NumeroOF            INT           NULL,
    SerieOF             NVARCHAR(20)  NULL,
    NumeroTrabajo       NVARCHAR(50)  NULL,
    FechaEntrega        DATETIME2     NULL,
    FechaNecesaria      DATETIME2     NULL,
    CodigoCliente       NVARCHAR(50)  NULL,
    CodigoColor         NVARCHAR(50)  NULL,
    CodigoTalla         NVARCHAR(50)  NULL,
    Stock               DECIMAL(14,4) NULL DEFAULT 0,
    CodigoArticulo      NVARCHAR(50)  NULL,
    DescripcionArticulo NVARCHAR(500) NULL,
    PorcentajeDependencia DECIMAL(8,4) NULL DEFAULT 0,
    UnidadesFabricadas  DECIMAL(14,4) NULL DEFAULT 0,
    UnidadesAFabricar   DECIMAL(14,4) NULL DEFAULT 0,
    TiempoUnidadFabSecs DECIMAL(14,4) NULL DEFAULT 0,
    DuracionMin         DECIMAL(12,2) NULL DEFAULT 0,
    DuracionMinOriginal DECIMAL(12,2) NULL DEFAULT 0,
    OperariosNecesarios INT           NULL DEFAULT 0,
    OperariosAsignados  INT           NULL DEFAULT 0,
    Estado              TINYINT       NOT NULL DEFAULT 0,
    Tipo                TINYINT       NOT NULL DEFAULT 0,
    Prioridad           INT           NOT NULL DEFAULT 0,
    ColorFondoOp        INT           NULL DEFAULT 15251072,  -- azul cal
    ColorBordeOp        INT           NULL DEFAULT 11166760,  -- azul cal oscuro
    LibreMovimiento     BIT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_NodeData PRIMARY KEY (CodigoEmpresa, NodeId),
    CONSTRAINT FK_FS_PL_NodeData_Node FOREIGN KEY (CodigoEmpresa, NodeId) REFERENCES FS_PL_Node(CodigoEmpresa, NodeId) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_NodeCenterAllowed')
CREATE TABLE FS_PL_NodeCenterAllowed (
    CodigoEmpresa   SMALLINT      NOT NULL,
    NodeId          INT           NOT NULL,
    CenterId        INT           NOT NULL,
    CONSTRAINT PK_FS_PL_NodeCenterAllowed PRIMARY KEY (CodigoEmpresa, NodeId, CenterId),
    CONSTRAINT FK_FS_PL_NCA_Node FOREIGN KEY (CodigoEmpresa, NodeId) REFERENCES FS_PL_Node(CodigoEmpresa, NodeId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_NCA_Center FOREIGN KEY (CodigoEmpresa, CenterId) REFERENCES FS_PL_Center(CodigoEmpresa, CenterId)
);

-- ============================================================================
-- 10. DEPENDENCIAS / LINKS
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Dependency')
CREATE TABLE FS_PL_Dependency (
    CodigoEmpresa   SMALLINT      NOT NULL,
    DependencyId    INT IDENTITY(1,1) NOT NULL,
    ProjectId       INT           NOT NULL,
    FromNodeId      INT           NOT NULL,
    ToNodeId        INT           NOT NULL,
    TipoLink        TINYINT       NOT NULL DEFAULT 0,
    PorcentajeDependencia DECIMAL(8,4) NOT NULL DEFAULT 100,
    CONSTRAINT PK_FS_PL_Dependency PRIMARY KEY (CodigoEmpresa, DependencyId),
    CONSTRAINT FK_FS_PL_Dep_Project FOREIGN KEY (CodigoEmpresa, ProjectId) REFERENCES FS_PL_Project(CodigoEmpresa, ProjectId),
    CONSTRAINT FK_FS_PL_Dep_From FOREIGN KEY (CodigoEmpresa, FromNodeId) REFERENCES FS_PL_Node(CodigoEmpresa, NodeId),
    CONSTRAINT FK_FS_PL_Dep_To FOREIGN KEY (CodigoEmpresa, ToNodeId) REFERENCES FS_PL_Node(CodigoEmpresa, NodeId)
);

-- ============================================================================
-- 11. ASIGNACIONES DE OPERARIOS
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_OperatorAssignment')
CREATE TABLE FS_PL_OperatorAssignment (
    CodigoEmpresa   SMALLINT      NOT NULL,
    AssignmentId    INT IDENTITY(1,1) NOT NULL,
    OperatorId      INT           NOT NULL,
    NodeId          INT           NOT NULL,
    Horas           DECIMAL(8,2)  NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_OpAssignment PRIMARY KEY (CodigoEmpresa, AssignmentId),
    CONSTRAINT FK_FS_PL_OpAssign_Op FOREIGN KEY (CodigoEmpresa, OperatorId) REFERENCES FS_PL_Operator(CodigoEmpresa, OperatorId),
    CONSTRAINT FK_FS_PL_OpAssign_Node FOREIGN KEY (CodigoEmpresa, NodeId) REFERENCES FS_PL_Node(CodigoEmpresa, NodeId) ON DELETE CASCADE
);

-- ============================================================================
-- 12. CAMPOS PERSONALIZADOS - DEFINICIONES
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_CustomFieldDef')
CREATE TABLE FS_PL_CustomFieldDef (
    CodigoEmpresa   SMALLINT      NOT NULL,
    FieldDefId      INT IDENTITY(1,1) NOT NULL,
    FieldName       NVARCHAR(100) NOT NULL,
    Caption         NVARCHAR(200) NOT NULL,
    TipoCampo       TINYINT       NOT NULL DEFAULT 0,
    ValorDefecto    NVARCHAR(500) NULL,
    ValoresLista    NVARCHAR(MAX) NULL,
    Requerido       BIT           NOT NULL DEFAULT 0,
    SoloLectura     BIT           NOT NULL DEFAULT 0,
    Orden           INT           NOT NULL DEFAULT 0,
    Visible         BIT           NOT NULL DEFAULT 1,
    Grupo           NVARCHAR(100) NULL,
    Tooltip         NVARCHAR(500) NULL,
    ValorMinimo     DECIMAL(18,4) NULL,
    ValorMaximo     DECIMAL(18,4) NULL,
    FormatoMascara  NVARCHAR(100) NULL,
    CONSTRAINT PK_FS_PL_CustomFieldDef PRIMARY KEY (CodigoEmpresa, FieldDefId),
    CONSTRAINT UQ_FS_PL_CustomFieldDef_Name UNIQUE (CodigoEmpresa, FieldName)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_CustomFieldValue')
CREATE TABLE FS_PL_CustomFieldValue (
    CodigoEmpresa   SMALLINT      NOT NULL,
    NodeId          INT           NOT NULL,
    FieldDefId      INT           NOT NULL,
    Valor           NVARCHAR(MAX) NULL,
    CONSTRAINT PK_FS_PL_CustomFieldValue PRIMARY KEY (CodigoEmpresa, NodeId, FieldDefId),
    CONSTRAINT FK_FS_PL_CFVal_Node FOREIGN KEY (CodigoEmpresa, NodeId) REFERENCES FS_PL_Node(CodigoEmpresa, NodeId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_CFVal_Def FOREIGN KEY (CodigoEmpresa, FieldDefId) REFERENCES FS_PL_CustomFieldDef(CodigoEmpresa, FieldDefId)
);

-- ============================================================================
-- 13. MOLDES
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Mold')
CREATE TABLE FS_PL_Mold (
    CodigoEmpresa   SMALLINT      NOT NULL,
    MoldId          INT IDENTITY(1,1) NOT NULL,
    Codigo          NVARCHAR(30)  NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    TipoMolde       TINYINT       NOT NULL DEFAULT 0,
    Estado          TINYINT       NOT NULL DEFAULT 0,
    UbicacionActual NVARCHAR(200) NULL,
    CentroActualId  INT           NULL,
    NumeroCavidades INT           NOT NULL DEFAULT 1,
    TiempoMontaje   DECIMAL(8,2)  NULL DEFAULT 0,
    TiempoDesmontaje DECIMAL(8,2) NULL DEFAULT 0,
    TiempoAjuste    DECIMAL(8,2)  NULL DEFAULT 0,
    CiclosAcumulados INT          NOT NULL DEFAULT 0,
    FechaProxMantenimiento DATE   NULL,
    DisponiblePlanificacion BIT   NOT NULL DEFAULT 1,
    Observaciones   NVARCHAR(MAX) NULL,
    CONSTRAINT PK_FS_PL_Mold PRIMARY KEY (CodigoEmpresa, MoldId),
    CONSTRAINT UQ_FS_PL_Mold_Codigo UNIQUE (CodigoEmpresa, Codigo),
    CONSTRAINT FK_FS_PL_Mold_Center FOREIGN KEY (CodigoEmpresa, CentroActualId) REFERENCES FS_PL_Center(CodigoEmpresa, CenterId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_MoldCenter')
CREATE TABLE FS_PL_MoldCenter (
    CodigoEmpresa   SMALLINT      NOT NULL,
    MoldId          INT           NOT NULL,
    CenterId        INT           NOT NULL,
    CONSTRAINT PK_FS_PL_MoldCenter PRIMARY KEY (CodigoEmpresa, MoldId, CenterId),
    CONSTRAINT FK_FS_PL_MoldCenter_Mold FOREIGN KEY (CodigoEmpresa, MoldId) REFERENCES FS_PL_Mold(CodigoEmpresa, MoldId) ON DELETE CASCADE,
    CONSTRAINT FK_FS_PL_MoldCenter_Center FOREIGN KEY (CodigoEmpresa, CenterId) REFERENCES FS_PL_Center(CodigoEmpresa, CenterId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_MoldArticle')
CREATE TABLE FS_PL_MoldArticle (
    CodigoEmpresa   SMALLINT      NOT NULL,
    MoldId          INT           NOT NULL,
    CodigoArticulo  NVARCHAR(50)  NOT NULL,
    CONSTRAINT PK_FS_PL_MoldArticle PRIMARY KEY (CodigoEmpresa, MoldId, CodigoArticulo),
    CONSTRAINT FK_FS_PL_MoldArticle_Mold FOREIGN KEY (CodigoEmpresa, MoldId) REFERENCES FS_PL_Mold(CodigoEmpresa, MoldId) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_MoldOperation')
CREATE TABLE FS_PL_MoldOperation (
    CodigoEmpresa   SMALLINT      NOT NULL,
    MoldId          INT           NOT NULL,
    Operacion       NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_FS_PL_MoldOperation PRIMARY KEY (CodigoEmpresa, MoldId, Operacion),
    CONSTRAINT FK_FS_PL_MoldOp_Mold FOREIGN KEY (CodigoEmpresa, MoldId) REFERENCES FS_PL_Mold(CodigoEmpresa, MoldId) ON DELETE CASCADE
);

-- ============================================================================
-- 14. REGLAS DE PLANIFICACIÓN (PERFILES)
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_PlanningProfile')
CREATE TABLE FS_PL_PlanningProfile (
    CodigoEmpresa   SMALLINT      NOT NULL,
    ProfileId       INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(100) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    EsActivo        BIT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_PlanningProfile PRIMARY KEY (CodigoEmpresa, ProfileId)
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_SortRule')
CREATE TABLE FS_PL_SortRule (
    CodigoEmpresa   SMALLINT      NOT NULL,
    RuleId          INT IDENTITY(1,1) NOT NULL,
    ProfileId       INT           NOT NULL,
    FieldName       NVARCHAR(100) NOT NULL,
    Direccion       TINYINT       NOT NULL DEFAULT 0,
    Peso            INT           NOT NULL DEFAULT 1,
    Habilitado      BIT           NOT NULL DEFAULT 1,
    Orden           INT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_SortRule PRIMARY KEY (CodigoEmpresa, RuleId),
    CONSTRAINT FK_FS_PL_SortRule_Prof FOREIGN KEY (CodigoEmpresa, ProfileId) REFERENCES FS_PL_PlanningProfile(CodigoEmpresa, ProfileId) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_FilterRule')
CREATE TABLE FS_PL_FilterRule (
    CodigoEmpresa   SMALLINT      NOT NULL,
    RuleId          INT IDENTITY(1,1) NOT NULL,
    ProfileId       INT           NOT NULL,
    FieldName       NVARCHAR(100) NOT NULL,
    Operador        TINYINT       NOT NULL DEFAULT 0,
    Valor           NVARCHAR(500) NULL,
    Accion          TINYINT       NOT NULL DEFAULT 0,
    CentroDestinoId INT           NULL,
    Habilitado      BIT           NOT NULL DEFAULT 1,
    Orden           INT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_FilterRule PRIMARY KEY (CodigoEmpresa, RuleId),
    CONSTRAINT FK_FS_PL_FilterRule_Prof FOREIGN KEY (CodigoEmpresa, ProfileId) REFERENCES FS_PL_PlanningProfile(CodigoEmpresa, ProfileId) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_GroupRule')
CREATE TABLE FS_PL_GroupRule (
    CodigoEmpresa   SMALLINT      NOT NULL,
    RuleId          INT IDENTITY(1,1) NOT NULL,
    ProfileId       INT           NOT NULL,
    FieldName       NVARCHAR(100) NOT NULL,
    Modo            TINYINT       NOT NULL DEFAULT 0,
    Peso            INT           NOT NULL DEFAULT 1,
    Habilitado      BIT           NOT NULL DEFAULT 1,
    Orden           INT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_GroupRule PRIMARY KEY (CodigoEmpresa, RuleId),
    CONSTRAINT FK_FS_PL_GroupRule_Prof FOREIGN KEY (CodigoEmpresa, ProfileId) REFERENCES FS_PL_PlanningProfile(CodigoEmpresa, ProfileId) ON DELETE CASCADE
);

-- ============================================================================
-- 15. SNAPSHOTS (historial de planificaciones)
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Snapshot')
CREATE TABLE FS_PL_Snapshot (
    CodigoEmpresa   SMALLINT      NOT NULL,
    SnapshotId      INT IDENTITY(1,1) NOT NULL,
    ProjectId       INT           NOT NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Descripcion     NVARCHAR(MAX) NULL,
    FechaCreacion   DATETIME2     NOT NULL DEFAULT GETDATE(),
    CreadoPor       NVARCHAR(100) NULL,
    DatosJSON       NVARCHAR(MAX) NOT NULL,
    CONSTRAINT PK_FS_PL_Snapshot PRIMARY KEY (CodigoEmpresa, SnapshotId),
    CONSTRAINT FK_FS_PL_Snapshot_Project FOREIGN KEY (CodigoEmpresa, ProjectId) REFERENCES FS_PL_Project(CodigoEmpresa, ProjectId)
);

-- ============================================================================
-- 16. MARCADORES DEL GANTT
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_Marker')
CREATE TABLE FS_PL_Marker (
    CodigoEmpresa   SMALLINT      NOT NULL,
    MarkerId        INT IDENTITY(1,1) NOT NULL,
    ProjectId       INT           NOT NULL,
    FechaHora       DATETIME2     NOT NULL,
    Caption         NVARCHAR(200) NULL,
    Color           INT           NULL,
    Estilo          TINYINT       NOT NULL DEFAULT 0,
    GrosorLinea     DECIMAL(4,1)  NOT NULL DEFAULT 1,
    Movible         BIT           NOT NULL DEFAULT 0,
    Visible         BIT           NOT NULL DEFAULT 1,
    Tag             INT           NOT NULL DEFAULT 0,
    FontName        NVARCHAR(50)  NULL,
    FontSize        INT           NULL,
    FontColor       INT           NULL,
    FontStyle       TINYINT       NOT NULL DEFAULT 0,
    OrientacionTexto TINYINT      NOT NULL DEFAULT 0,
    AlineacionTexto  TINYINT      NOT NULL DEFAULT 0,
    CONSTRAINT PK_FS_PL_Marker PRIMARY KEY (CodigoEmpresa, MarkerId),
    CONSTRAINT FK_FS_PL_Marker_Project FOREIGN KEY (CodigoEmpresa, ProjectId) REFERENCES FS_PL_Project(CodigoEmpresa, ProjectId)
);

-- ============================================================================
-- 17. MAPEO ERP (para trazabilidad con el sistema origen)
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_ErpMapping')
CREATE TABLE FS_PL_ErpMapping (
    CodigoEmpresa   SMALLINT      NOT NULL,
    MappingId       INT IDENTITY(1,1) NOT NULL,
    TipoEntidad     NVARCHAR(50)  NOT NULL,
    EntidadId       INT           NOT NULL,
    ErpSistema      NVARCHAR(50)  NOT NULL,
    ErpTabla        NVARCHAR(200) NULL,
    ErpClave        NVARCHAR(500) NOT NULL,
    FechaSincro     DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_FS_PL_ErpMapping PRIMARY KEY (CodigoEmpresa, MappingId),
    CONSTRAINT UQ_FS_PL_ErpMapping UNIQUE (CodigoEmpresa, TipoEntidad, EntidadId, ErpSistema)
);

-- ============================================================================
-- 18. LOG DE AUDITORÍA
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FS_PL_AuditLog')
CREATE TABLE FS_PL_AuditLog (
    CodigoEmpresa   SMALLINT      NOT NULL,
    LogId           BIGINT IDENTITY(1,1) NOT NULL,
    FechaHora       DATETIME2     NOT NULL DEFAULT GETDATE(),
    Usuario         NVARCHAR(100) NULL,
    TipoEntidad     NVARCHAR(50)  NOT NULL,
    EntidadId       INT           NOT NULL,
    Accion          NVARCHAR(20)  NOT NULL,
    DatosAnterior   NVARCHAR(MAX) NULL,
    DatosNuevo      NVARCHAR(MAX) NULL,
    CONSTRAINT PK_FS_PL_AuditLog PRIMARY KEY (CodigoEmpresa, LogId)
);

-- ============================================================================
-- ÍNDICES ADICIONALES
-- ============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_Node_Project')
CREATE NONCLUSTERED INDEX IX_FS_PL_Node_Project ON FS_PL_Node(CodigoEmpresa, ProjectId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_Node_Center')
CREATE NONCLUSTERED INDEX IX_FS_PL_Node_Center ON FS_PL_Node(CodigoEmpresa, CenterId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_Node_Fechas')
CREATE NONCLUSTERED INDEX IX_FS_PL_Node_Fechas ON FS_PL_Node(CodigoEmpresa, FechaInicio, FechaFin);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_NodeData_OF')
CREATE NONCLUSTERED INDEX IX_FS_PL_NodeData_OF ON FS_PL_NodeData(CodigoEmpresa, NumeroOF, SerieOF);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_NodeData_Pedido')
CREATE NONCLUSTERED INDEX IX_FS_PL_NodeData_Pedido ON FS_PL_NodeData(CodigoEmpresa, NumeroPedido, SeriePedido);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_NodeData_Articulo')
CREATE NONCLUSTERED INDEX IX_FS_PL_NodeData_Articulo ON FS_PL_NodeData(CodigoEmpresa, CodigoArticulo);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_NodeData_Estado')
CREATE NONCLUSTERED INDEX IX_FS_PL_NodeData_Estado ON FS_PL_NodeData(CodigoEmpresa, Estado);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_NodeData_FechaEntrega')
CREATE NONCLUSTERED INDEX IX_FS_PL_NodeData_FechaEntrega ON FS_PL_NodeData(CodigoEmpresa, FechaEntrega);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_Dep_From')
CREATE NONCLUSTERED INDEX IX_FS_PL_Dep_From ON FS_PL_Dependency(CodigoEmpresa, FromNodeId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_Dep_To')
CREATE NONCLUSTERED INDEX IX_FS_PL_Dep_To ON FS_PL_Dependency(CodigoEmpresa, ToNodeId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_OpAssign_Node')
CREATE NONCLUSTERED INDEX IX_FS_PL_OpAssign_Node ON FS_PL_OperatorAssignment(CodigoEmpresa, NodeId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_OpAssign_Op')
CREATE NONCLUSTERED INDEX IX_FS_PL_OpAssign_Op ON FS_PL_OperatorAssignment(CodigoEmpresa, OperatorId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_ErpMap_Erp')
CREATE NONCLUSTERED INDEX IX_FS_PL_ErpMap_Erp ON FS_PL_ErpMapping(CodigoEmpresa, ErpSistema, ErpClave);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_Audit_Fecha')
CREATE NONCLUSTERED INDEX IX_FS_PL_Audit_Fecha ON FS_PL_AuditLog(CodigoEmpresa, FechaHora);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FS_PL_Audit_Entidad')
CREATE NONCLUSTERED INDEX IX_FS_PL_Audit_Entidad ON FS_PL_AuditLog(CodigoEmpresa, TipoEntidad, EntidadId);

-- ============================================================================
-- DATOS DEMO (solo empresa 9999)
-- ============================================================================

-- ÁREAS
INSERT INTO FS_PL_Area (CodigoEmpresa, Codigo, Nombre, Orden)
SELECT 9999, v.Codigo, v.Nombre, v.Orden
FROM (VALUES
  ('FAB',  'Fabricacion',      0),
  ('LOG',  'Logistica',        1),
  ('OFT',  'Oficina Tecnica',  2),
  ('CAL',  'Calidad',          3),
  ('MNT',  'Mantenimiento',    4),
  ('ALM',  'Almacen',          5)
) AS v(Codigo, Nombre, Orden)
WHERE NOT EXISTS (SELECT 1 FROM FS_PL_Area a WHERE a.CodigoEmpresa = 9999 AND a.Codigo = v.Codigo);

-- DEPARTAMENTOS
INSERT INTO FS_PL_Department (CodigoEmpresa, Nombre, Descripcion)
SELECT 9999, v.Nombre, v.Descripcion
FROM (VALUES
  ('Mecanizado',     'Torno, fresa, rectificadora'),
  ('Pintura',        'Cabinas de pintura y lacado'),
  ('Montaje',        'Lineas de montaje'),
  ('Acabados',       'Pulido y acabados finales'),
  ('Expediciones',   'Embalaje y expedicion'),
  ('Calidad',        'Control de calidad'),
  ('Inyeccion',      'Maquinas de inyeccion'),
  ('Mantenimiento',  'Mantenimiento preventivo y correctivo')
) AS v(Nombre, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM FS_PL_Department d WHERE d.CodigoEmpresa = 9999 AND d.Nombre = v.Nombre);

-- CALENDARIOS
INSERT INTO FS_PL_Calendar (CodigoEmpresa, Nombre, Descripcion)
SELECT 9999, v.Nombre, v.Descripcion
FROM (VALUES
  ('CAL-TURNO-PARTIDO',   'Turno partido 06:00-14:00, 15:00-22:00'),
  ('CAL-TURNO-MANANA',    'Turno mañana 07:00-15:00'),
  ('CAL-TURNO-TARDE',     'Turno tarde 15:00-23:00'),
  ('CAL-TURNO-INTENSIVO', 'Turno intensivo 06:00-13:30, 15:45-22:00'),
  ('CAL-24H',             '24 horas (solo fines de semana cerrados)')
) AS v(Nombre, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM FS_PL_Calendar c WHERE c.CodigoEmpresa = 9999 AND c.Nombre = v.Nombre);

-- Reglas L-V: CAL-TURNO-PARTIDO
INSERT INTO FS_PL_CalendarDayRule (CodigoEmpresa, CalendarId, DiaSemana, HoraInicioNoLab, HoraFinNoLab)
SELECT c.CodigoEmpresa, c.CalendarId, d.DiaSemana, v.HI, v.HF
FROM FS_PL_Calendar c
CROSS APPLY (VALUES (1),(2),(3),(4),(5)) AS d(DiaSemana)
CROSS APPLY (VALUES ('00:00:00','06:00:00'),('14:00:00','15:00:00'),('22:00:00','23:59:00')) AS v(HI, HF)
WHERE c.CodigoEmpresa = 9999 AND c.Nombre = 'CAL-TURNO-PARTIDO'
  AND NOT EXISTS (SELECT 1 FROM FS_PL_CalendarDayRule r WHERE r.CodigoEmpresa = 9999
    AND r.CalendarId = c.CalendarId AND r.DiaSemana = d.DiaSemana AND r.HoraInicioNoLab = CAST(v.HI AS TIME));

-- Reglas L-V: CAL-TURNO-MANANA
INSERT INTO FS_PL_CalendarDayRule (CodigoEmpresa, CalendarId, DiaSemana, HoraInicioNoLab, HoraFinNoLab)
SELECT c.CodigoEmpresa, c.CalendarId, d.DiaSemana, v.HI, v.HF
FROM FS_PL_Calendar c
CROSS APPLY (VALUES (1),(2),(3),(4),(5)) AS d(DiaSemana)
CROSS APPLY (VALUES ('00:00:00','07:00:00'),('15:00:00','23:59:00')) AS v(HI, HF)
WHERE c.CodigoEmpresa = 9999 AND c.Nombre = 'CAL-TURNO-MANANA'
  AND NOT EXISTS (SELECT 1 FROM FS_PL_CalendarDayRule r WHERE r.CodigoEmpresa = 9999
    AND r.CalendarId = c.CalendarId AND r.DiaSemana = d.DiaSemana AND r.HoraInicioNoLab = CAST(v.HI AS TIME));

-- Reglas L-V: CAL-TURNO-TARDE
INSERT INTO FS_PL_CalendarDayRule (CodigoEmpresa, CalendarId, DiaSemana, HoraInicioNoLab, HoraFinNoLab)
SELECT c.CodigoEmpresa, c.CalendarId, d.DiaSemana, v.HI, v.HF
FROM FS_PL_Calendar c
CROSS APPLY (VALUES (1),(2),(3),(4),(5)) AS d(DiaSemana)
CROSS APPLY (VALUES ('00:00:00','15:00:00'),('18:30:00','18:45:00'),('23:00:00','23:59:00')) AS v(HI, HF)
WHERE c.CodigoEmpresa = 9999 AND c.Nombre = 'CAL-TURNO-TARDE'
  AND NOT EXISTS (SELECT 1 FROM FS_PL_CalendarDayRule r WHERE r.CodigoEmpresa = 9999
    AND r.CalendarId = c.CalendarId AND r.DiaSemana = d.DiaSemana AND r.HoraInicioNoLab = CAST(v.HI AS TIME));

-- Reglas L-V: CAL-TURNO-INTENSIVO
INSERT INTO FS_PL_CalendarDayRule (CodigoEmpresa, CalendarId, DiaSemana, HoraInicioNoLab, HoraFinNoLab)
SELECT c.CodigoEmpresa, c.CalendarId, d.DiaSemana, v.HI, v.HF
FROM FS_PL_Calendar c
CROSS APPLY (VALUES (1),(2),(3),(4),(5)) AS d(DiaSemana)
CROSS APPLY (VALUES ('00:00:00','06:00:00'),('13:30:00','15:45:00'),('22:00:00','23:59:00')) AS v(HI, HF)
WHERE c.CodigoEmpresa = 9999 AND c.Nombre = 'CAL-TURNO-INTENSIVO'
  AND NOT EXISTS (SELECT 1 FROM FS_PL_CalendarDayRule r WHERE r.CodigoEmpresa = 9999
    AND r.CalendarId = c.CalendarId AND r.DiaSemana = d.DiaSemana AND r.HoraInicioNoLab = CAST(v.HI AS TIME));

-- Fines de semana: todos los calendarios demo cerrados sábado y domingo
INSERT INTO FS_PL_CalendarDayRule (CodigoEmpresa, CalendarId, DiaSemana, HoraInicioNoLab, HoraFinNoLab)
SELECT c.CodigoEmpresa, c.CalendarId, d.DiaSemana, '00:00:00', '23:59:00'
FROM FS_PL_Calendar c
CROSS APPLY (VALUES (6),(7)) AS d(DiaSemana)
WHERE c.CodigoEmpresa = 9999
  AND NOT EXISTS (SELECT 1 FROM FS_PL_CalendarDayRule r WHERE r.CodigoEmpresa = 9999
    AND r.CalendarId = c.CalendarId AND r.DiaSemana = d.DiaSemana AND r.HoraInicioNoLab = '00:00:00');

-- CENTROS DE TRABAJO
INSERT INTO FS_PL_Center (CodigoEmpresa, CodigoCentro, Titulo, Subtitulo, AreaId, EsSecuencial, MaxLanes, AlturaBase, Orden, Visible, Habilitado, ColorFondo)
SELECT 9999, v.CodigoCentro, v.Titulo, v.Subtitulo,
       a.AreaId,
       v.EsSecuencial, v.MaxLanes, v.AlturaBase, v.Orden, 1, 1, v.ColorFondo
FROM (VALUES
  ('CENTRO-1',  'CENTRO-1',  'MAQUINA-1',  'FAB', 1, 0, 28,  0, 5395967),
  ('CENTRO-2',  'CENTRO-2',  'MAQUINA-2',  'LOG', 0, 3, 80,  1, 2631900),
  ('CENTRO-3',  'CENTRO-3',  'MAQUINA-3',  'OFT', 1, 0, 28,  2, 16770764),
  ('CENTRO-4',  'CENTRO-4',  'MAQUINA-4',  'CAL', 0, 4, 100, 3, 3368652),
  ('CENTRO-5',  'CENTRO-5',  'MAQUINA-5',  'MNT', 1, 0, 28,  4, 5395967),
  ('CENTRO-6',  'CENTRO-6',  'MAQUINA-6',  'ALM', 0, 2, 60,  5, 2631900),
  ('CENTRO-7',  'CENTRO-7',  'MAQUINA-7',  'FAB', 1, 0, 28,  6, 16770764),
  ('CENTRO-8',  'CENTRO-8',  'MAQUINA-8',  'LOG', 0, 3, 90,  7, 3368652),
  ('CENTRO-9',  'CENTRO-9',  'MAQUINA-9',  'OFT', 1, 0, 28,  8, 5395967),
  ('CENTRO-10', 'CENTRO-10', 'MAQUINA-10', 'CAL', 0, 4, 110, 9, 2631900)
) AS v(CodigoCentro, Titulo, Subtitulo, AreaCodigo, EsSecuencial, MaxLanes, AlturaBase, Orden, ColorFondo)
LEFT JOIN FS_PL_Area a ON a.CodigoEmpresa = 9999 AND a.Codigo = v.AreaCodigo
WHERE NOT EXISTS (SELECT 1 FROM FS_PL_Center c WHERE c.CodigoEmpresa = 9999 AND c.CodigoCentro = v.CodigoCentro);

-- Asignar calendarios a centros demo (cíclicamente)
INSERT INTO FS_PL_CenterCalendar (CodigoEmpresa, CenterId, CalendarId)
SELECT c.CodigoEmpresa, c.CenterId, cal.CalendarId
FROM FS_PL_Center c
INNER JOIN (
  SELECT CalendarId, ROW_NUMBER() OVER (ORDER BY CalendarId) - 1 AS CalIdx
  FROM FS_PL_Calendar WHERE CodigoEmpresa = 9999
) cal ON cal.CalIdx = (c.Orden % (SELECT COUNT(*) FROM FS_PL_Calendar WHERE CodigoEmpresa = 9999))
WHERE c.CodigoEmpresa = 9999
  AND NOT EXISTS (SELECT 1 FROM FS_PL_CenterCalendar cc
    WHERE cc.CodigoEmpresa = 9999 AND cc.CenterId = c.CenterId);

-- OPERARIOS
INSERT INTO FS_PL_Operator (CodigoEmpresa, Nombre, Activo)
SELECT 9999, v.Nombre, 1
FROM (VALUES
  ('Joan Garcia'),('Maria Lopez'),('Pere Martinez'),('Anna Ferrer'),('Marc Puig'),
  ('Laura Roca'),('David Serra'),('Carla Font'),('Jordi Vila'),('Marta Soler'),
  ('Joan Mas'),('Maria Torres'),('Pere Vidal'),('Anna Costa'),('Marc Pons'),
  ('Laura Marin'),('David Ruiz'),('Carla Navarro'),('Jordi Gimenez'),('Marta Romero')
) AS v(Nombre)
WHERE NOT EXISTS (SELECT 1 FROM FS_PL_Operator o WHERE o.CodigoEmpresa = 9999 AND o.Nombre = v.Nombre);

-- Asignar operarios demo a departamentos (cíclicamente)
INSERT INTO FS_PL_OperatorDepartment (CodigoEmpresa, OperatorId, DepartmentId)
SELECT o.CodigoEmpresa, o.OperatorId, d.DepartmentId
FROM FS_PL_Operator o
INNER JOIN FS_PL_Department d ON d.CodigoEmpresa = 9999
WHERE o.CodigoEmpresa = 9999
  AND NOT EXISTS (SELECT 1 FROM FS_PL_OperatorDepartment od
    WHERE od.CodigoEmpresa = 9999 AND od.OperatorId = o.OperatorId)
  AND d.DepartmentId = (
    SELECT MIN(d2.DepartmentId) FROM FS_PL_Department d2
    WHERE d2.CodigoEmpresa = 9999
      AND (d2.DepartmentId - 1) % 8 = (o.OperatorId - 1) % 8
  );

-- Capacitaciones demo (2 operaciones por operario)
INSERT INTO FS_PL_OperatorSkill (CodigoEmpresa, OperatorId, Operacion)
SELECT o.CodigoEmpresa, o.OperatorId, v.Operacion
FROM FS_PL_Operator o
CROSS APPLY (VALUES
  (CASE (o.OperatorId * 3) % 10
    WHEN 0 THEN 'PINTAR' WHEN 1 THEN 'BRONCEAR' WHEN 2 THEN 'LACAR'
    WHEN 3 THEN 'PULIR' WHEN 4 THEN 'CORTAR' WHEN 5 THEN 'EMBALAR'
    WHEN 6 THEN 'SOLDAR' WHEN 7 THEN 'FRESAR' WHEN 8 THEN 'TORNEAR'
    ELSE 'TALADRAR' END),
  (CASE (o.OperatorId * 3 + 7) % 10
    WHEN 0 THEN 'RECTIFICAR' WHEN 1 THEN 'MONTAR' WHEN 2 THEN 'INYECTAR'
    WHEN 3 THEN 'SOPLAR' WHEN 4 THEN 'EXTRUIR' WHEN 5 THEN 'TROQUELAR'
    WHEN 6 THEN 'PRENSAR' WHEN 7 THEN 'REBARBEAR' WHEN 8 THEN 'TEMPLAR'
    ELSE 'CEMENTAR' END)
) AS v(Operacion)
WHERE o.CodigoEmpresa = 9999
  AND NOT EXISTS (SELECT 1 FROM FS_PL_OperatorSkill os
    WHERE os.CodigoEmpresa = 9999 AND os.OperatorId = o.OperatorId AND os.Operacion = v.Operacion);

PRINT '========================================';
PRINT 'FSPlanner 2026 - Schema creado con éxito';
PRINT '========================================';
GO
