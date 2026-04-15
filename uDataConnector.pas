unit uDataConnector;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  uGanttTypes, uErpTypes, uOperariosTypes, uMoldeTypes, uCentreCalendar,
  uPlanningRules;

type
  // ── Progreso de carga/guardado ──
  TConnectorProgressEvent = procedure(Sender: TObject;
    const Paso: string; Porcentaje: Integer) of object;

  // ── Resultado de operación ──
  TConnectorResult = record
    Success: Boolean;
    ErrorMessage: string;
    AffectedRows: Integer;
    class function OK(ARows: Integer = 0): TConnectorResult; static;
    class function Fail(const AMsg: string): TConnectorResult; static;
  end;

  // ── Datos completos de un proyecto ──
  TProjectInfo = record
    ProjectId: Integer;
    Codigo: string;
    Nombre: string;
    Descripcion: string;
    FechaCreacion: TDateTime;
    FechaModificacion: TDateTime;
    Activo: Boolean;
  end;

  // ── Snapshot de todo el planning ──
  TPlanningData = record
    Project: TProjectInfo;
    Centres: TArray<TCentreTreball>;
    Nodes: TArray<TNode>;
    NodeDataList: TArray<TNodeData>;
    Links: TArray<TErpLink>;
    Markers: TArray<TGanttMarker>;
    Shifts: TArray<TTurno>;
    Operarios: TArray<TOperario>;
    Departamentos: TArray<TDepartamento>;
    OperarioDepts: TArray<TOperarioDepartamento>;
    Capacitaciones: TArray<TCapacitacion>;
    Asignaciones: TArray<TAsignacionOperario>;
    Moldes: TArray<TMolde>;
    CustomFieldDefs: TArray<TCustomFieldDef>;
    PlanningProfiles: TArray<TPlanningProfile>;
    ActiveProfileIndex: Integer;
  end;

  // ── Interfaz base del conector ──
  IGanttDataConnector = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']

    // --- Conexión ---
    function Connect: TConnectorResult;
    procedure Disconnect;
    function IsConnected: Boolean;

    // --- Proyectos ---
    function GetProjects: TArray<TProjectInfo>;
    function CreateProject(var AProject: TProjectInfo): TConnectorResult;
    function DeleteProject(AProjectId: Integer): TConnectorResult;

    // --- Carga completa ---
    function LoadPlanning(AProjectId: Integer; out AData: TPlanningData): TConnectorResult;

    // --- Guardado completo ---
    function SavePlanning(const AData: TPlanningData): TConnectorResult;

    // --- Guardado incremental (solo lo modificado) ---
    function SaveNodes(AProjectId: Integer; const ANodes: TArray<TNode>;
      const ANodeData: TArray<TNodeData>): TConnectorResult;
    function SaveCentres(const ACentres: TArray<TCentreTreball>): TConnectorResult;
    function SaveLinks(AProjectId: Integer; const ALinks: TArray<TErpLink>): TConnectorResult;
    function SaveMarkers(AProjectId: Integer; const AMarkers: TArray<TGanttMarker>): TConnectorResult;
    function SaveOperarios(const AOperarios: TArray<TOperario>;
      const ADepts: TArray<TDepartamento>;
      const ARelaciones: TArray<TOperarioDepartamento>;
      const ACapacitaciones: TArray<TCapacitacion>;
      const AAsignaciones: TArray<TAsignacionOperario>): TConnectorResult;
    function SaveShifts(const AShifts: TArray<TTurno>): TConnectorResult;
    function SaveMoldes(const AMoldes: TArray<TMolde>): TConnectorResult;
    function SaveCustomFieldDefs(const ADefs: TArray<TCustomFieldDef>): TConnectorResult;
    function SavePlanningProfiles(const AProfiles: TArray<TPlanningProfile>;
      AActiveIndex: Integer): TConnectorResult;

    // --- Snapshots ---
    function CreateSnapshot(AProjectId: Integer; const ANombre: string;
      const ADescripcion: string): TConnectorResult;
    function GetSnapshots(AProjectId: Integer): TArray<TProjectInfo>; // reutilizamos para listar
    function LoadSnapshot(ASnapshotId: Integer; out AData: TPlanningData): TConnectorResult;

    // --- Mapeo ERP ---
    function SetErpMapping(const ATipoEntidad: string; AEntidadId: Integer;
      const AErpSistema, AErpClave: string): TConnectorResult;
    function GetErpMapping(const ATipoEntidad: string; AEntidadId: Integer;
      const AErpSistema: string): string; // devuelve ErpClave o vacío

    // --- Eventos ---
    function GetOnProgress: TConnectorProgressEvent;
    procedure SetOnProgress(AValue: TConnectorProgressEvent);
    property OnProgress: TConnectorProgressEvent read GetOnProgress write SetOnProgress;
  end;

implementation

{ TConnectorResult }

class function TConnectorResult.OK(ARows: Integer): TConnectorResult;
begin
  Result.Success := True;
  Result.ErrorMessage := '';
  Result.AffectedRows := ARows;
end;

class function TConnectorResult.Fail(const AMsg: string): TConnectorResult;
begin
  Result.Success := False;
  Result.ErrorMessage := AMsg;
  Result.AffectedRows := 0;
end;

end.
