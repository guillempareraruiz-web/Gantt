unit Main;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uGanttControl, uGanttTypes, DateUtils,
  Vcl.ExtCtrls, uCentreCalendar, Vcl.StdCtrls,
  Vcl.Menus, uPlanAutoSaver,
  System.Generics.Collections, uErpTypes,
  Data.Win.ADODB,
  uOperariosTypes, uOperariosRepo, uGestionOperaris, uOperatorAbsencesRepo,
  uHabilidadRepo, uPlanProdTypes, uPlanProdEngine, uOperationTypesRepo,
  uPesosScoringRepo, uSQLServerConnector,
  uMoldeRepo, uGestionMoldes, uGestionCalendarios,
  uCustomFieldDefs, uCustomFieldEditor, uPlanningRules, uPlanningRulesEditor,
  uDashBoard, uVistaGantt;

type

  TForm1 = class(TForm)tmr1Sec: TTimer;
    MainMenu1: TMainMenu;
    Archivo1: TMenuItem;
    Dashboard1: TMenuItem;
    N4: TMenuItem;
    Proyectos1: TMenuItem;
    ConfigEmpresa1: TMenuItem;
    SelectorErp1: TMenuItem;
    AsistenteInstalacion1: TMenuItem;
    GenerarNodosDemo1: TMenuItem;
    Salir1: TMenuItem;
    N3: TMenuItem;
    Entidades1: TMenuItem;
    Operarios1: TMenuItem;
    Centros1: TMenuItem;
    Maquinas1: TMenuItem;
    Calendarios1: TMenuItem;
    Areas1: TMenuItem;
    Departamentos1: TMenuItem;
    Ausencias1: TMenuItem;
    Habilidades1: TMenuItem;
    OperacionHabilidades1: TMenuItem;
    OperationTypes1: TMenuItem;
    Turnos1: TMenuItem;
    Moldes1: TMenuItem;
    Utillajes1: TMenuItem;
    Links1: TMenuItem;
    N10: TMenuItem;
    CamposPersonalizados1: TMenuItem;
    ReglasPlanificacion1: TMenuItem;
    Vistas1: TMenuItem;
    Kanban1: TMenuItem;
    DispatchList1: TMenuItem;
    Backlog1: TMenuItem;
    GenerarBacklogDemo1: TMenuItem;
    FiniteCapacity1: TMenuItem;
    FiniteCapacityOperaris1: TMenuItem;
    AutoPlanificacion1: TMenuItem;
    PesosScoring1: TMenuItem;
    CuadroPlanificacionDia1: TMenuItem;
    Configuracion1: TMenuItem;
    Roles1: TMenuItem;
    Usuarios1: TMenuItem;
    NDemo1: TMenuItem;
    InstalarDemos1: TMenuItem;
    Ayuda1: TMenuItem;
    Acercade1: TMenuItem;
    MnGantt: TMenuItem;
    N2: TMenuItem;
    Indicadoresdecentros1: TMenuItem;
    Funcionalidades1: TMenuItem;
    DashboardOperativo1: TMenuItem;
    N5: TMenuItem;
    StockCockpit1: TMenuItem;
    ArticleDetail1: TMenuItem;

    procedure Roles1Click(Sender: TObject);
    procedure Usuarios1Click(Sender: TObject);
    procedure InstalarDemos1Click(Sender: TObject);
    procedure Proyectos1Click(Sender: TObject);
    procedure ConfigEmpresa1Click(Sender: TObject);
    procedure SelectorErp1Click(Sender: TObject);
    procedure StockCockpit1Click(Sender: TObject);
    procedure ArticleDetail1Click(Sender: TObject);
    procedure DashboardOperativo1Click(Sender: TObject);
    procedure AsistenteInstalacion1Click(Sender: TObject);
    procedure GenerarNodosDemo1Click(Sender: TObject);
    procedure Dashboard1Click(Sender: TObject);
    procedure Areas1Click(Sender: TObject);
    procedure Departamentos1Click(Sender: TObject);
    procedure Ausencias1Click(Sender: TObject);
    procedure Habilidades1Click(Sender: TObject);
    procedure OperacionHabilidades1Click(Sender: TObject);
    procedure OperationTypes1Click(Sender: TObject);
    procedure AutoPlanificacion1Click(Sender: TObject);
    procedure PesosScoring1Click(Sender: TObject);
    procedure MostrarDashboard;
    procedure OcultarDashboard;
    procedure DashboardAbrirGantt(Sender: TObject);
    procedure MostrarVistaGantt;
    procedure LoadActivePlan;
    function HasActivePlan: Boolean;

    // Auto-save
    procedure InitAutoSaver;
    procedure DestroyAutoSaver;
    procedure GanttPlanModified(Sender: TObject; const ADataIds: TArray<Integer>);
    procedure GanttLinksModified(Sender: TObject);
    procedure SaveNodesViaConnector(AProjectId: Integer;
      const ANodes: TArray<TNode>; const ANodeData: TArray<TNodeData>);
    procedure AutoSaverStatusChange(Sender: TObject; AStatus: TAutoSaveStatus);
    procedure AutoSaverSaveStarted(Sender: TObject; ANodeCount: Integer);
    procedure AutoSaverSaveCompleted(Sender: TObject; ANodeCount: Integer);
    procedure AutoSaverSaveFailed(Sender: TObject; const AError: string);
    procedure UpdateAutoSaveLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure tmr1SecTimer(Sender: TObject);
    procedure Moldes1Click(Sender: TObject);
    procedure Calendarios1Click(Sender: TObject);
    procedure Turnos1Click(Sender: TObject);
    procedure Operarios1Click(Sender: TObject);
    procedure Centros1Click(Sender: TObject);
    procedure Maquinas1Click(Sender: TObject);
    procedure CamposPersonalizados1Click(Sender: TObject);
    procedure ReglasPlanificacion1Click(Sender: TObject);
    procedure Kanban1Click(Sender: TObject);
    procedure DispatchList1Click(Sender: TObject);
    procedure Backlog1Click(Sender: TObject);
    procedure GenerarBacklogDemo1Click(Sender: TObject);
    procedure FiniteCapacity1Click(Sender: TObject);
    procedure FiniteCapacityOperaris1Click(Sender: TObject);
    procedure CuadroPlanificacionDia1Click(Sender: TObject);
    procedure Salir1Click(Sender: TObject);
    procedure MnGanttClick(Sender: TObject);
    procedure Indicadoresdecentros1Click(Sender: TObject);
  private
    { Private declarations }

    FCustomFieldDefs: TCustomFieldDefs;
    FPlanningRuleEngine: TPlanningRuleEngine;
    FUpdatingViewport: Boolean;

    FTurnos: TArray<TTurno>;

  public
    { Public declarations }

    // Llamar despues de cada operaci'on que modifica nodos (Kanban, Inspector, Gantt).
    procedure NotifyPlanModified(const ADataIds: TArray<Integer>);

    // Acceso a repos globales (para forms hijos)
    function GetHabilidadRepo: THabilidadRepo;
    function GetOperariosRepo: TOperariosRepo;

    // Lanza la pantalla de Auto-Planificacion sobre los DataIds dados.
    // Si ANodeIds esta vacio, planifica TODO el plan activo.
    procedure LaunchAutoPlanificacion(const ANodeIds: TArray<Integer>);

  private
    FAutoSaver: TPlanAutoSaver;
    FAutoSavePanel: TPanel;
    FAutoSaveLabel: TLabel;
    FLastSaveTick: Cardinal;
    FLastSavedNodes: Integer;
  end;

var
  Form1: TForm1;
  FOperariosRepo: TOperariosRepo;
  FAbsenciasRepo: TOperatorAbsencesRepo;
  FHabilidadRepo: THabilidadRepo;
  FOperationTypesRepo: TOperationTypesRepo;
  FPesosScoring: TPesosPlanificacion;
  FMoldeRepo: TMoldeRepo;
  FCentresRows: TArray<TCentreTreball>;
  FDashboard: TfrmDashboard;
  FVistaGantt: TfrmVistaGantt;

implementation

uses uErpSampleBuilder, uGestionCentres, uGestionMaquinas, uKanbanBoard, uVistaKanban, uDispatchList, uBacklog,
  uDemoBacklog,
  uFiniteCapacityPlanner, uFiniteCapacityOperaris, uOperarioAusencias,
  uGestionHabilidades, uPesosScoring, uAutoPlanificacion,
  uGestionOperacionHabilidades, uGestionOperationTypes,
  uCuadroPlanificacionDelDia, uGestionTurnos,
  uDMPlanner, uGestionRoles, uGestionUsuarios, uLogin, uGestionDemos,
  uGestionProyectos, uGestionAreas, uGestionDepartamentos,
  uConfigEmpresa, uGenerarNodosDemo, uCentresKPI, uErpSelector, uInstallWizard,
  uDataConnector, uUserPrefs,
  uErpReader, uErpReaderFactory, uArticleDetail, uStockCockpit,
  uDashboardOperativo;

{$R *.dfm}


procedure TForm1.tmr1SecTimer(Sender: TObject);
begin
  // Actualizar el label de auto-save ("Guardado hace Ns")
  UpdateAutoSaveLabel;
end;






procedure TForm1.Centros1Click(Sender: TObject);
var
  Frm: TfrmGestionCentres;
begin
  Frm := TfrmGestionCentres.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  DMPlanner.LoadCentres;
end;

procedure TForm1.Maquinas1Click(Sender: TObject);
begin
  TfrmGestionMaquinas.Execute;
end;

procedure TForm1.Kanban1Click(Sender: TObject);
begin
  if not HasActivePlan then
  begin
    MostrarDashboard;
    ShowMessage('Selecciona o crea un proyecto antes de abrir el Kanban.');
    Exit;
  end;

  TVistaKanbanForm.Execute(
    DMPlanner.NodeDataRepo,
    FCentresRows,
    function(const DataId: Integer; out AStart, AEnd: TDateTime): Boolean
    var
      Nodes: TArray<TNode>;
      J: Integer;
    begin
      Result := False;
      AStart := 0;
      AEnd := 0;
      if not Assigned(FVistaGantt) or not Assigned(FVistaGantt.GanttControl) then Exit;
      Nodes := FVistaGantt.GanttControl.GetNodes;
      for J := 0 to High(Nodes) do
        if Nodes[J].DataId = DataId then
        begin
          AStart := Nodes[J].StartTime;
          AEnd := Nodes[J].EndTime;
          Exit(True);
        end;
    end,
    function(const DataId: Integer; out ACentreId: Integer): Boolean
    var
      Nodes: TArray<TNode>;
      J: Integer;
    begin
      Result := False;
      ACentreId := -1;
      if not Assigned(FVistaGantt) or not Assigned(FVistaGantt.GanttControl) then Exit;
      Nodes := FVistaGantt.GanttControl.GetNodes;
      for J := 0 to High(Nodes) do
        if Nodes[J].DataId = DataId then
        begin
          ACentreId := Nodes[J].CentreId;
          Exit(True);
        end;
    end,
    procedure(const ADataIds: TArray<Integer>)
    begin
      NotifyPlanModified(ADataIds);
    end
  );

  // Tras cerrar el Kanban, refrescar Gantt por si hubo cambios de estado
  if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
    FVistaGantt.GanttControl.Invalidate;
end;

procedure TForm1.DispatchList1Click(Sender: TObject);
begin
  TDispatchListForm.Execute(
    DMPlanner.NodeDataRepo,
    FCentresRows,
    function(const DataId: Integer; out AStart, AEnd: TDateTime): Boolean
    var
      Nodes: TArray<TNode>;
      J: Integer;
    begin
      Result := False;
      AStart := 0;
      AEnd := 0;
      if not Assigned(FVistaGantt) or not Assigned(FVistaGantt.GanttControl) then Exit;
      Nodes := FVistaGantt.GanttControl.GetNodes;
      for J := 0 to High(Nodes) do
        if Nodes[J].DataId = DataId then
        begin
          AStart := Nodes[J].StartTime;
          AEnd := Nodes[J].EndTime;
          Exit(True);
        end;
    end
  );
end;

procedure TForm1.Backlog1Click(Sender: TObject);
begin
  uBacklog.ShowBacklog;
  if FVistaGantt <> nil then
    FVistaGantt.Inicializar;
end;

procedure TForm1.GenerarBacklogDemo1Click(Sender: TObject);
begin
  try
    uDemoBacklog.GenerarBacklogDemo;
  except
    on E: Exception do
      ShowMessage('Error generando Backlog demo: ' + E.Message);
  end;
end;

procedure TForm1.FiniteCapacity1Click(Sender: TObject);
var
  Assignments: TArray<TFCPAssignment>;
begin
  if not Assigned(DMPlanner.NodeDataRepo) then
  begin
    ShowMessage('Repositorio de nodos no inicializado.');
    Exit;
  end;
  if not Assigned(FOperariosRepo) then
  begin
    ShowMessage('Repositorio de operarios no inicializado.');
    Exit;
  end;
  if DMPlanner.CurrentProjectId <= 0 then
  begin
    ShowMessage('No hay ningún proyecto activo.');
    Exit;
  end;

  if TfrmFiniteCapacityPlanner.Execute(
    DMPlanner.NodeDataRepo,
    FOperariosRepo,
    Assignments,
    FPlanningRuleEngine,
    FCustomFieldDefs
  ) then
  begin
    // TODO: aplicar asignaciones al Gantt
  end;

  // Refrescar Gantt por si hubo cambios
  if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
    FVistaGantt.GanttControl.Invalidate;
end;

procedure TForm1.FiniteCapacityOperaris1Click(Sender: TObject);
var
  Assignments: TArray<TFCOAssignment>;
begin
  if not Assigned(DMPlanner.NodeDataRepo) then
  begin
    ShowMessage('Repositorio de nodos no inicializado.');
    Exit;
  end;
  if not Assigned(FOperariosRepo) then
  begin
    ShowMessage('Repositorio de operarios no inicializado.');
    Exit;
  end;
  if DMPlanner.CurrentProjectId <= 0 then
  begin
    ShowMessage('No hay ning'#250'n proyecto activo.');
    Exit;
  end;

  if TfrmFiniteCapacityOperaris.Execute(
    DMPlanner.NodeDataRepo,
    FOperariosRepo,
    Assignments,
    FAbsenciasRepo,
    nil,
    FCustomFieldDefs
  ) then
  begin
    // TODO: aplicar asignaciones al Gantt / persistir en BD
  end;

  if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
    FVistaGantt.GanttControl.Invalidate;
end;

procedure TForm1.CuadroPlanificacionDia1Click(Sender: TObject);
begin
  TfrmCuadroPlanificacionDelDia.Execute(
    DMPlanner.NodeDataRepo,
    FCentresRows,
    function(const DataId: Integer; out AStart, AEnd: TDateTime): Boolean
    var
      Nodes: TArray<TNode>;
      J: Integer;
    begin
      Result := False;
      AStart := 0;
      AEnd := 0;
      if not Assigned(FVistaGantt) or not Assigned(FVistaGantt.GanttControl) then Exit;
      Nodes := FVistaGantt.GanttControl.GetNodes;
      for J := 0 to High(Nodes) do
        if Nodes[J].DataId = DataId then
        begin
          AStart := Nodes[J].StartTime;
          AEnd := Nodes[J].EndTime;
          Exit(True);
        end;
    end,
    function(const CentreId: Integer): TCentreCalendar
    begin
      if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
        Result := FVistaGantt.GanttControl.GetCalendar(CentreId)
      else
        Result := nil;
    end,
    FTurnos);
end;


procedure TForm1.Indicadoresdecentros1Click(Sender: TObject);
begin

 TfrmCentresKPI.Execute(
    Self,
    DMPlanner.CentresRepo.GetAll,
    FVistaGantt.FGanttControl,
    DMPlanner.NodeDataRepo,
    FVistaGantt.FOperariosRepo,
    0);

end;

procedure TForm1.MnGanttClick(Sender: TObject);
begin
  OcultarDashboard;
  MostrarVistaGantt;
end;

procedure TForm1.Moldes1Click(Sender: TObject);
var
  Frm: TfrmGestionMoldes;
begin
  Frm := TfrmGestionMoldes.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.CamposPersonalizados1Click(Sender: TObject);
begin
  if TfrmCustomFieldEditor.Execute(FCustomFieldDefs) then
    FCustomFieldDefs.SaveToFile;
end;

procedure TForm1.ReglasPlanificacion1Click(Sender: TObject);
begin
  if TfrmPlanningRulesEditor.Execute(FPlanningRuleEngine) then
    FPlanningRuleEngine.SaveToFile;
end;

procedure TForm1.Calendarios1Click(Sender: TObject);
begin
  TfrmGestionCalendarios.Execute(YearOf(Now));
  DMPlanner.LoadCalendars;
  if Assigned(FVistaGantt) then
  begin
    FVistaGantt.AplicarCalendariosAGantt;
    if Assigned(FVistaGantt.GanttControl) then
      FVistaGantt.GanttControl.Invalidate;
  end;
end;

procedure TForm1.Turnos1Click(Sender: TObject);
begin
  TfrmGestionTurnos.Execute;
end;

procedure TForm1.Operarios1Click(Sender: TObject);
var
  Frm: TfrmGestionOperaris;
begin
  Frm := TfrmGestionOperaris.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.Roles1Click(Sender: TObject);
var
  Frm: TfrmGestionRoles;
begin
  if not HasPermission('ADMIN_ROLES') then
  begin
    ShowMessage('No tiene permisos para gestionar roles.');
    Exit;
  end;
  Frm := TfrmGestionRoles.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.Usuarios1Click(Sender: TObject);
var
  Frm: TfrmGestionUsuarios;
begin
  if not HasPermission('ADMIN_USERS') then
  begin
    ShowMessage('No tiene permisos para gestionar usuarios.');
    Exit;
  end;
  Frm := TfrmGestionUsuarios.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.InstalarDemos1Click(Sender: TObject);
var
  Frm: TfrmGestionDemos;
begin
  Frm := TfrmGestionDemos.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.Proyectos1Click(Sender: TObject);
var
  Frm: TfrmGestionProyectos;
  OldProjectId: Integer;
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede gestionar proyectos.');
    Exit;
  end;

  if Assigned(DMPlanner) then
    OldProjectId := DMPlanner.CurrentProjectId
  else
    OldProjectId := -1;

  Frm := TfrmGestionProyectos.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;

  // Si el proyecto activo ha cambiado, recargar el plan
  if Assigned(DMPlanner) and (DMPlanner.CurrentProjectId <> OldProjectId) then
    LoadActivePlan;
end;

procedure TForm1.Salir1Click(Sender: TObject);
begin
 Close;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  Randomize;
  Width := 1900;

  FCustomFieldDefs := TCustomFieldDefs.Create;
  FCustomFieldDefs.LoadFromFile(ExtractFilePath(Application.ExeName) + 'custom_fields.json');

  FPlanningRuleEngine := TPlanningRuleEngine.Create(FCustomFieldDefs);
  FPlanningRuleEngine.LoadFromFile(ExtractFilePath(Application.ExeName) + 'planning_rules.json');

  // Repo de operarios: si BD conectada, carga real desde FS_PL_Operator
  // (basico: id + nombre + calendario). Sin BD usa sample data.
  // TODO v2: extender con Departamentos + Capacitaciones + Asignaciones via
  // uSQLServerConnector (ya tiene los metodos LoadXxx).
  FOperariosRepo := TOperariosRepo.Create;
  if Assigned(DMPlanner) and DMPlanner.IsConnected then
  begin
    var QOps := TADOQuery.Create(nil);
    try
      QOps.Connection := DMPlanner.ADOConnection;
      QOps.SQL.Text :=
        'SELECT OperatorId, Nombre, ' +
        '       ISNULL(SueldoEurHora, 0) AS SueldoEurHora, ' +
        '       ISNULL(RecargoTurnoNoche, 1) AS RecargoTurnoNoche, ' +
        '       ISNULL(RecargoFestivo, 1) AS RecargoFestivo ' +
        'FROM FS_PL_Operator ' +
        'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
        '  AND Activo = 1 ' +
        'ORDER BY Nombre';
      try
        QOps.Open;
        while not QOps.Eof do
        begin
          var Op: TOperario;
          Op.Id := QOps.FieldByName('OperatorId').AsInteger;
          Op.Nombre := QOps.FieldByName('Nombre').AsString;
          Op.Calendario := '';
          Op.SueldoEurHora := QOps.FieldByName('SueldoEurHora').AsFloat;
          Op.RecargoTurnoNoche := QOps.FieldByName('RecargoTurnoNoche').AsFloat;
          Op.RecargoFestivo := QOps.FieldByName('RecargoFestivo').AsFloat;
          FOperariosRepo.AddOperario(Op);
          QOps.Next;
        end;
      except
        // Si V020 no aplicada, los campos de coste no existen. Reintenta sin
        // ellos:
        QOps.Close;
        QOps.SQL.Text :=
          'SELECT OperatorId, Nombre FROM FS_PL_Operator ' +
          'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
          '  AND Activo = 1 ORDER BY Nombre';
        QOps.Open;
        while not QOps.Eof do
        begin
          var Op: TOperario;
          Op.Id := QOps.FieldByName('OperatorId').AsInteger;
          Op.Nombre := QOps.FieldByName('Nombre').AsString;
          Op.Calendario := '';
          Op.SueldoEurHora := 0;
          Op.RecargoTurnoNoche := 1;
          Op.RecargoFestivo := 1;
          FOperariosRepo.AddOperario(Op);
          QOps.Next;
        end;
      end;
    finally
      QOps.Free;
    end;

    // Departamentos + relacion Operario-Departamento (V019+)
    var QDept := TADOQuery.Create(nil);
    try
      QDept.Connection := DMPlanner.ADOConnection;
      try
        QDept.SQL.Text :=
          'SELECT DepartmentId, Nombre, ISNULL(Descripcion, '''') AS Descripcion ' +
          'FROM FS_PL_Department ' +
          'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
          ' ORDER BY Nombre';
        QDept.Open;
        while not QDept.Eof do
        begin
          var D: TDepartamento;
          D.Id := QDept.FieldByName('DepartmentId').AsInteger;
          D.Nombre := QDept.FieldByName('Nombre').AsString;
          D.Descripcion := QDept.FieldByName('Descripcion').AsString;
          FOperariosRepo.AddDepartamento(D);
          QDept.Next;
        end;
        QDept.Close;

        QDept.SQL.Text :=
          'SELECT OperatorId, DepartmentId FROM FS_PL_OperatorDepartment ' +
          'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa);
        QDept.Open;
        while not QDept.Eof do
        begin
          FOperariosRepo.AssignOperariToDept(
            QDept.FieldByName('OperatorId').AsInteger,
            QDept.FieldByName('DepartmentId').AsInteger);
          QDept.Next;
        end;
      except
        // Tablas pueden no existir si V019 no aplicada
      end;
    finally
      QDept.Free;
    end;
  end
  else
    FOperariosRepo.LoadSampleData;
  FAbsenciasRepo := TOperatorAbsencesRepo.Create;
  FHabilidadRepo := THabilidadRepo.Create;
  FOperationTypesRepo := TOperationTypesRepo.Create;
  FPesosScoring := TPesosPlanificacion.Default;

  // Conectar repos a BD si esta disponible. Cargar lo que haya, y si esta
  // vacio, sembrar con sample data + persistirlo (asi la primera vez se
  // pobla la BD y a partir de la 2a se trabaja contra ella).
  if Assigned(DMPlanner) and DMPlanner.IsConnected then
  begin
    FHabilidadRepo.SetConnection(DMPlanner.ADOConnection,
      DMPlanner.CodigoEmpresa);
    FOperationTypesRepo.SetConnection(DMPlanner.ADOConnection,
      DMPlanner.CodigoEmpresa);
    FAbsenciasRepo.SetConnection(DMPlanner.ADOConnection,
      DMPlanner.CodigoEmpresa);
    try
      FHabilidadRepo.LoadFromDB;
    except
      on E: Exception do
        // Tabla puede no existir si V020 no aplicada
        ;
    end;
    try
      FOperationTypesRepo.LoadFromDB;
    except
      on E: Exception do
        ;
    end;
    try
      FAbsenciasRepo.LoadFromDB;
    except
      on E: Exception do
        // V019 puede no estar aplicada
        ;
    end;
    LoadPesosActivo(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa,
      FPesosScoring);
  end;

  // Fallback: si no se cargo nada (sin BD o BD vacia), usa sample
  if Length(FHabilidadRepo.GetHabilidades) = 0 then
    FHabilidadRepo.LoadSampleData;
  if Length(FOperationTypesRepo.GetAll) = 0 then
    FOperationTypesRepo.LoadSampleData;
  // Ausencias: solo sembrar con sample si NO hay BD; con BD respetar la
  // tabla aunque este vacia (nadie ha registrado ausencias todavia).
  if (Length(FAbsenciasRepo.GetAll) = 0) and
     not (Assigned(DMPlanner) and DMPlanner.IsConnected) then
  begin
    var OpIds: TArray<Integer>;
    var OpsArr := FOperariosRepo.GetOperarios;
    SetLength(OpIds, Length(OpsArr));
    for var IA := 0 to High(OpsArr) do
      OpIds[IA] := OpsArr[IA].Id;
    FAbsenciasRepo.LoadSampleData(OpIds);
  end;

  // Migrar capacitaciones in-memory (modelo viejo 1-1) a habilidades familias.
  // Solo aplica al modo SAMPLE (sin BD). Con BD, los datos vienen de las
  // tablas FS_PL_OperarioHabilidad ya pobladas (manualmente o via seed V020).
  if Assigned(FOperariosRepo) and
     not (Assigned(DMPlanner) and DMPlanner.IsConnected) then
  begin
    var YaHayHabsAsignadas := False;
    var OpsCheck := FOperariosRepo.GetOperarios;
    for var I0 := 0 to High(OpsCheck) do
      if Length(FHabilidadRepo.GetHabilidadesOperario(OpsCheck[I0].Id)) > 0 then
      begin
        YaHayHabsAsignadas := True;
        Break;
      end;

    if not YaHayHabsAsignadas then
    begin
      var Ops := FOperariosRepo.GetOperarios;
      for var I := 0 to High(Ops) do
      begin
        var Caps := FOperariosRepo.GetCapacitacionsByOperario(Ops[I].Id);
        for var J := 0 to High(Caps) do
        begin
          var Cap: TCapacitacion;
          if not FOperariosRepo.GetCapacitacioInfo(Ops[I].Id, Caps[J], Cap) then
            Continue;
          var FamHabs := FHabilidadRepo.GetHabilidadesOperacion(Cap.Operacion);
          for var K := 0 to High(FamHabs) do
            FHabilidadRepo.SetOperarioHabilidad(Ops[I].Id,
              FamHabs[K].CodHabilidad, Cap.Nivel, Cap.FactorEficiencia);
        end;
      end;
    end;
  end;

  // Migracion BD: FS_PL_OperatorSkill (modelo viejo) -> habilidades.
  // Solo si FS_PL_OperarioHabilidad esta vacia y FS_PL_OperatorSkill tiene datos.
  // Por cada (OperatorId, Operacion, Nivel) del modelo viejo:
  //   - Si la Operacion tiene habilidades familia definidas, asignar esas al
  //     operario con el nivel original.
  //   - Si no, crear habilidad homonima a la Operacion y asignarla.
  if Assigned(DMPlanner) and DMPlanner.IsConnected then
  begin
    var QChk := TADOQuery.Create(nil);
    try
      QChk.Connection := DMPlanner.ADOConnection;
      QChk.SQL.Text :=
        'SELECT (SELECT COUNT(*) FROM FS_PL_OperarioHabilidad WHERE CodigoEmpresa = ' +
        IntToStr(DMPlanner.CodigoEmpresa) + ') AS NewN, ' +
        '       (SELECT COUNT(*) FROM FS_PL_OperatorSkill WHERE CodigoEmpresa = ' +
        IntToStr(DMPlanner.CodigoEmpresa) + ') AS OldN';
      try
        QChk.Open;
        if (not QChk.Eof) and (QChk.FieldByName('NewN').AsInteger = 0) and
           (QChk.FieldByName('OldN').AsInteger > 0) then
        begin
          // Recorrer FS_PL_OperatorSkill y migrar
          QChk.Close;
          QChk.SQL.Text :=
            'SELECT OperatorId, Operacion, Nivel, ' +
            '       ISNULL(FactorEficiencia, 1.0) AS FE ' +
            'FROM FS_PL_OperatorSkill WHERE CodigoEmpresa = ' +
            IntToStr(DMPlanner.CodigoEmpresa);
          QChk.Open;
          while not QChk.Eof do
          begin
            var OpId := QChk.FieldByName('OperatorId').AsInteger;
            var Operacion := QChk.FieldByName('Operacion').AsString;
            var Nivel := TinyIntToNivelSkill(
              Byte(QChk.FieldByName('Nivel').AsInteger));
            var FactorEf := QChk.FieldByName('FE').AsFloat;
            var FamHabs := FHabilidadRepo.GetHabilidadesOperacion(Operacion);
            if Length(FamHabs) > 0 then
            begin
              // Asignar todas las familias requeridas
              for var K := 0 to High(FamHabs) do
                FHabilidadRepo.SetOperarioHabilidad(OpId,
                  FamHabs[K].CodHabilidad, Nivel, FactorEf);
            end
            else
            begin
              // Fallback: crear habilidad homonima y asignarla
              FHabilidadRepo.EnsureHabilidad(Operacion,
                'Migrada desde FS_PL_OperatorSkill');
              FHabilidadRepo.SetOperacionHabilidad(Operacion, Operacion,
                nsAprendiz);
              FHabilidadRepo.SetOperarioHabilidad(OpId, Operacion, Nivel,
                FactorEf);
            end;
            QChk.Next;
          end;
        end;
      except
        // Tabla puede no existir o V020 sin aplicar
      end;
    finally
      QChk.Free;
    end;
  end;

  MostrarDashboard;

  LoadActivePlan;

  // Conectar handler de cierre con check de dirty + flush
  Self.OnCloseQuery := FormCloseQuery;
end;

procedure TForm1.MostrarDashboard;
begin
  if FDashboard = nil then
  begin
    FDashboard := TfrmDashboard.Create(Self);
    FDashboard.OnAbrirGantt := DashboardAbrirGantt;
    FDashboard.Parent := Self;
    FDashboard.Align := alClient;
  end;
  FDashboard.Refrescar;
  FDashboard.Visible := True;
  FDashboard.BringToFront;
end;

procedure TForm1.OcultarDashboard;
begin
  if Assigned(FDashboard) then
    FDashboard.Visible := False;
end;

procedure TForm1.DashboardAbrirGantt(Sender: TObject);
begin
  OcultarDashboard;
  MostrarVistaGantt;
end;

procedure TForm1.MostrarVistaGantt;
begin
  if not HasActivePlan then
  begin
    MostrarDashboard;
    Exit;
  end;
  if FVistaGantt = nil then
  begin
    FVistaGantt := TfrmVistaGantt.CreateVista(Self,
      FOperariosRepo, FMoldeRepo,
      FCustomFieldDefs, FPlanningRuleEngine);
    FVistaGantt.Parent := Self;
    FVistaGantt.Align := alClient;
  end;
  FVistaGantt.Inicializar;

  // Cablar OnPlanModified del control interno hacia el AutoSaver del Main
  if Assigned(FVistaGantt.GanttControl) then
    FVistaGantt.GanttControl.OnPlanModified := GanttPlanModified;
  if Assigned(FVistaGantt.GanttControl) then
    FVistaGantt.GanttControl.OnLinksModified := GanttLinksModified;

  FVistaGantt.Visible := True;
  FVistaGantt.BringToFront;
end;

function TForm1.HasActivePlan: Boolean;
begin
  Result := Assigned(DMPlanner) and (DMPlanner.CurrentProjectId > 0);
end;

procedure TForm1.LoadActivePlan;
begin
  // Antes de descartar el plan en memoria, persistir cualquier dirty pendiente
  if Assigned(FAutoSaver) then
    FAutoSaver.Flush(True);

  // Tambien persistir viewport actual del Gantt antes de cargar nuevo plan
  if Assigned(FVistaGantt) then
    FVistaGantt.SaveViewportPrefs;

  // Carga el plan activo del usuario desde BD a DMPlanner.NodeDataRepo.
  // Si no hay sesion / proyecto, deja el repo vacio y muestra el Dashboard.
  if not Assigned(DMPlanner) or not DMPlanner.IsConnected then
  begin
    if Assigned(DMPlanner) and Assigned(DMPlanner.NodeDataRepo) then
      DMPlanner.NodeDataRepo.Clear;
    MostrarDashboard;
    Exit;
  end;

  DMPlanner.NodeDataRepo.Clear;

  // Resolver proyecto activo del usuario logueado
  if CurrentSession.UserId > 0 then
    DMPlanner.LoadUserActiveProject(CurrentSession.UserId)
  else
    DMPlanner.LoadMasterProject;

  if DMPlanner.CurrentProjectId <= 0 then
  begin
    MostrarDashboard;
    Exit;
  end;

  // Cargar centros de la empresa (ya cargados por DMPlanner.LoadEmpresaInfo,
  // aqu'i sincronizamos la copia local FCentresRows que usan las pantallas).
  if Assigned(DMPlanner.CentresRepo) then
    FCentresRows := Copy(DMPlanner.CentresRepo.GetAll);

  // Cargar nodos del proyecto activo a DMPlanner.NodeDataRepo
  DMPlanner.LoadNodes;

  // Cargar asignaciones de operarios del proyecto activo
  if Assigned(FOperariosRepo) then
  begin
    var QAsig := TADOQuery.Create(nil);
    try
      QAsig.Connection := DMPlanner.ADOConnection;
      try
        QAsig.SQL.Text :=
          'SELECT oa.OperatorId, oa.NodeId, oa.Horas, ' +
          '       ISNULL(oa.IsLocked, 0) AS IsLocked, ' +
          '       ISNULL(oa.LockedBy, '''') AS LockedBy, ' +
          '       oa.LockedAt ' +
          'FROM FS_PL_OperatorAssignment oa ' +
          'INNER JOIN FS_PL_Node n ON n.CodigoEmpresa = oa.CodigoEmpresa ' +
          '                       AND n.NodeId = oa.NodeId ' +
          'WHERE oa.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
          '  AND n.ProjectId = ' + IntToStr(DMPlanner.CurrentProjectId);
        QAsig.Open;
        while not QAsig.Eof do
        begin
          var Asig: TAsignacionOperario;
          Asig.OperarioId := QAsig.FieldByName('OperatorId').AsInteger;
          Asig.DataId := QAsig.FieldByName('NodeId').AsInteger;
          Asig.Horas := QAsig.FieldByName('Horas').AsFloat;
          Asig.IsLocked := QAsig.FieldByName('IsLocked').AsBoolean;
          Asig.LockedBy := QAsig.FieldByName('LockedBy').AsString;
          if QAsig.FieldByName('LockedAt').IsNull then
            Asig.LockedAt := 0
          else
            Asig.LockedAt := QAsig.FieldByName('LockedAt').AsDateTime;
          FOperariosRepo.AddAsignacion(Asig);
          QAsig.Next;
        end;
      except
        // Tabla puede no existir o no tener IsLocked si V019 no aplicada
      end;
    finally
      QAsig.Free;
    end;
  end;

  // Inicializar / re-cablear el auto-saver para el plan recien cargado
  InitAutoSaver;

  // Si la VistaGantt ya existe, refrescarla con los nuevos datos
  if Assigned(FVistaGantt) and FVistaGantt.Visible then
    FVistaGantt.Inicializar;
end;

{ ========================================================= }
{                       Auto-saver                           }
{ ========================================================= }

procedure TForm1.InitAutoSaver;
begin
  if FAutoSaver = nil then
  begin
    FAutoSaver := TPlanAutoSaver.Create(
      Self, DMPlanner.NodeDataRepo, DMPlanner.NodesRepo,
      function: Integer
      begin
        if Assigned(DMPlanner) then
          Result := DMPlanner.CurrentProjectId
        else
          Result := -1;
      end,
      procedure(AProjectId: Integer;
        const ANodes: TArray<TNode>; const ANodeData: TArray<TNodeData>)
      begin
        SaveNodesViaConnector(AProjectId, ANodes, ANodeData);
      end);

    FAutoSaver.OnStatusChange := AutoSaverStatusChange;
    FAutoSaver.OnSaveStarted := AutoSaverSaveStarted;
    FAutoSaver.OnSaveCompleted := AutoSaverSaveCompleted;
    FAutoSaver.OnSaveFailed := AutoSaverSaveFailed;

    // Configurable via UserPrefs
    FAutoSaver.DebounceMs := uUserPrefs.GetPrefInt('Planner', 'AutoSaveDebounceMs', 2000);
    if FAutoSaver.DebounceMs < 500 then FAutoSaver.DebounceMs := 500;

    // Panel de status (pie de pantalla)
    if FAutoSavePanel = nil then
    begin
      FAutoSavePanel := TPanel.Create(Self);
      FAutoSavePanel.Parent := Self;
      FAutoSavePanel.Align := alBottom;
      FAutoSavePanel.Height := 22;
      FAutoSavePanel.BevelOuter := bvNone;
      FAutoSavePanel.Color := $00F0F0F0;
      FAutoSavePanel.Caption := '';

      FAutoSaveLabel := TLabel.Create(Self);
      FAutoSaveLabel.Parent := FAutoSavePanel;
      FAutoSaveLabel.Align := alClient;
      FAutoSaveLabel.AutoSize := False;
      FAutoSaveLabel.Caption := '   Listo';
      FAutoSaveLabel.Font.Color := $00666666;
      FAutoSaveLabel.Layout := tlCenter;
    end;
  end;
  UpdateAutoSaveLabel;
end;

procedure TForm1.DestroyAutoSaver;
begin
  if Assigned(FAutoSaver) then
  begin
    FAutoSaver.Flush(True);
    FreeAndNil(FAutoSaver);
  end;
end;

procedure TForm1.SaveNodesViaConnector(AProjectId: Integer;
  const ANodes: TArray<TNode>; const ANodeData: TArray<TNodeData>);
var
  Res: TConnectorResult;
begin
  if not Assigned(DMPlanner) or not Assigned(DMPlanner.Connector) then
    raise Exception.Create('No hay conexi'#243'n a BD');

  Res := DMPlanner.Connector.SaveNodes(AProjectId, ANodes, ANodeData);
  if not Res.Success then
    raise Exception.Create(Res.ErrorMessage);
end;

procedure TForm1.AutoSaverStatusChange(Sender: TObject; AStatus: TAutoSaveStatus);
begin
  UpdateAutoSaveLabel;
end;

procedure TForm1.AutoSaverSaveStarted(Sender: TObject; ANodeCount: Integer);
begin
  FLastSavedNodes := ANodeCount;
  UpdateAutoSaveLabel;
end;

procedure TForm1.AutoSaverSaveCompleted(Sender: TObject; ANodeCount: Integer);
begin
  FLastSaveTick := GetTickCount;
  FLastSavedNodes := ANodeCount;
  UpdateAutoSaveLabel;
end;

procedure TForm1.AutoSaverSaveFailed(Sender: TObject; const AError: string);
begin
  UpdateAutoSaveLabel;
  // Solo mostramos di'alogo en errores; los reintentos los gestiona el timer.
  ShowMessage('Error al guardar el plan: ' + AError);
end;

procedure TForm1.UpdateAutoSaveLabel;
var
  S: string;
  Secs: Cardinal;
begin
  if FAutoSaveLabel = nil then Exit;
  if FAutoSaver = nil then
  begin
    FAutoSaveLabel.Caption := '   Listo';
    Exit;
  end;

  case FAutoSaver.Status of
    assIdle:
      begin
        if FLastSaveTick = 0 then
          S := '   Listo'
        else
        begin
          Secs := (GetTickCount - FLastSaveTick) div 1000;
          if Secs < 5 then
            S := Format('   Guardado (%d nodos)', [FLastSavedNodes])
          else
            S := Format('   Guardado hace %ds', [Secs]);
        end;
      end;
    assDirty:    S := '   Cambios pendientes...';
    assSaving:   S := Format('   Guardando %d nodos...', [FLastSavedNodes]);
    assError:    S := '   Error al guardar';
  end;
  FAutoSaveLabel.Caption := S;
end;

procedure TForm1.NotifyPlanModified(const ADataIds: TArray<Integer>);
begin
  if Assigned(FAutoSaver) then
    FAutoSaver.MarkDirty(ADataIds);
end;

procedure TForm1.GanttPlanModified(Sender: TObject;
  const ADataIds: TArray<Integer>);
var
  I, J: Integer;
  AllNodes: TArray<TNode>;
  Affected: TArray<TNode>;
  IdSet: TDictionary<Integer, Boolean>;
  Cnt: Integer;
  SrcGantt: TGanttControl;
begin
  // 1) Sincronizar TNodes modificados al DMPlanner.NodesRepo, para que
  //    el save batch tenga StartTime/EndTime/CentreId actualizados.
  //    Sender = TGanttControl que dispar'o el evento (esperado: VistaGantt.GanttControl).
  if not (Sender is TGanttControl) then Exit;
  SrcGantt := TGanttControl(Sender);

  if Assigned(SrcGantt) and Assigned(DMPlanner) and Assigned(DMPlanner.NodesRepo) then
  begin
    AllNodes := SrcGantt.GetNodes;
    IdSet := TDictionary<Integer, Boolean>.Create;
    try
      for J := 0 to High(ADataIds) do
        IdSet.AddOrSetValue(ADataIds[J], True);

      SetLength(Affected, Length(AllNodes));
      Cnt := 0;
      for I := 0 to High(AllNodes) do
        if IdSet.ContainsKey(AllNodes[I].DataId) then
        begin
          Affected[Cnt] := AllNodes[I];
          Inc(Cnt);
        end;
      SetLength(Affected, Cnt);

      DMPlanner.NodesRepo.UpsertNodes(Affected);
    finally
      IdSet.Free;
    end;
  end;

  // 2) Disparar el debounce del AutoSaver
  NotifyPlanModified(ADataIds);
end;

procedure TForm1.GanttLinksModified(Sender: TObject);
var
  AllLinks: TArray<TErpLink>;
  Res: TConnectorResult;
begin
  // Persistir los links del Gantt al BD inmediatamente.
  // No usamos AutoSaver (esta enfocado a nodos); operacion sincronica
  // pequenya con feedback en el statusbar.
  if not Assigned(DMPlanner) or not DMPlanner.IsConnected then Exit;
  if not Assigned(DMPlanner.Connector) then Exit;
  if DMPlanner.CurrentProjectId <= 0 then Exit;
  if not (Sender is TGanttControl) then Exit;

  if Assigned(FAutoSaveLabel) then
  begin
    FAutoSaveLabel.Caption := '   Guardando links...';
    FAutoSaveLabel.Update;
  end;

  AllLinks := TGanttControl(Sender).GetLinks;
  Res := DMPlanner.Connector.SaveLinks(DMPlanner.CurrentProjectId, AllLinks);

  if not Res.Success then
  begin
    if Assigned(FAutoSaveLabel) then
      FAutoSaveLabel.Caption := '   Error guardando links';
    ShowMessage('Error guardando links: ' + Res.ErrorMessage);
  end
  else
  begin
    if Assigned(FAutoSaveLabel) then
      FAutoSaveLabel.Caption := Format('   Links guardados (%d)',
        [Length(AllLinks)]);
  end;
end;

procedure TForm1.ConfigEmpresa1Click(Sender: TObject);
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede editar la configuración de empresa.');
    Exit;
  end;
  TfrmConfigEmpresa.Execute;
end;

procedure TForm1.SelectorErp1Click(Sender: TObject);
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede cambiar el ERP activo.');
    Exit;
  end;
  TfrmErpSelector.Execute;
end;

procedure TForm1.StockCockpit1Click(Sender: TObject);
var
  Reader: IErpReader;
begin
  Reader := GetActiveErpReader;
  if Reader = nil then
  begin
    ShowMessage('No hay ERP configurado. Configura el ERP en el men'#250
      + ' Configuraci'#243'n > Selector de ERP.');
    Exit;
  end;
  TfrmStockCockpit.Execute(Reader);
end;

procedure TForm1.DashboardOperativo1Click(Sender: TObject);
var
  Reader: IErpReader;
begin
  Reader := GetActiveErpReader;
  if Reader = nil then
  begin
    ShowMessage('No hay ERP configurado. Configura el ERP en el men'#250
      + ' Configuraci'#243'n > Selector de ERP.');
    Exit;
  end;
  TfrmDashboardOperativo.Execute(Reader);
end;

procedure TForm1.ArticleDetail1Click(Sender: TObject);
var
  Reader: IErpReader;
begin
  Reader := GetActiveErpReader;
  if Reader = nil then
  begin
    ShowMessage('No hay ERP configurado. Configura el ERP en el men'#250
      + ' Configuraci'#243'n > Selector de ERP.');
    Exit;
  end;
  TfrmArticleDetail.Execute(Reader);
end;

procedure TForm1.AsistenteInstalacion1Click(Sender: TObject);
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede ejecutar el asistente de instalaci'#243'n.');
    Exit;
  end;
  TfrmInstallWizard.Execute;
end;

procedure TForm1.GenerarNodosDemo1Click(Sender: TObject);
begin
  if not IsAdmin then
  begin
    ShowMessage('Solo el administrador puede generar nodos demo.');
    Exit;
  end;
  if DMPlanner.CurrentProjectId <= 0 then
  begin
    ShowMessage('Primero active un proyecto.');
    Exit;
  end;
  TfrmGenerarNodosDemo.Execute;
end;

procedure TForm1.Dashboard1Click(Sender: TObject);
begin
  if FDashboard <> nil then
   if FDashboard.Visible then
   begin
    FDashboard.Visible := False;
    Exit;
   end;


  MostrarDashboard;
end;

procedure TForm1.Areas1Click(Sender: TObject);
var
  Frm: TfrmGestionAreas;
begin
  Frm := TfrmGestionAreas.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TForm1.Departamentos1Click(Sender: TObject);
var
  Frm: TfrmGestionDepartamentos;
begin
  Frm := TfrmGestionDepartamentos.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;


procedure TForm1.Ausencias1Click(Sender: TObject);
begin
  if not Assigned(FOperariosRepo) or not Assigned(FAbsenciasRepo) then Exit;
  TfrmOperarioAusencias.Execute(FOperariosRepo, FAbsenciasRepo, 0);
end;

procedure TForm1.Habilidades1Click(Sender: TObject);
begin
  if not Assigned(FHabilidadRepo) then Exit;
  TfrmGestionHabilidades.Execute(FHabilidadRepo);
end;

procedure TForm1.OperacionHabilidades1Click(Sender: TObject);
begin
  if not Assigned(FOperationTypesRepo) or not Assigned(FHabilidadRepo) then Exit;
  TfrmGestionOperacionHabilidades.Execute(FOperationTypesRepo, FHabilidadRepo);
end;

procedure TForm1.OperationTypes1Click(Sender: TObject);
begin
  if not Assigned(FOperationTypesRepo) then Exit;
  TfrmGestionOperationTypes.Execute(FOperationTypesRepo);
end;

procedure TForm1.PesosScoring1Click(Sender: TObject);
begin
  if TfrmPesosScoring.Execute(FPesosScoring) then
    if Assigned(DMPlanner) and DMPlanner.IsConnected then
      SavePesosActivo(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa,
        FPesosScoring);
end;

function TForm1.GetHabilidadRepo: THabilidadRepo;
begin
  Result := FHabilidadRepo;
end;

function TForm1.GetOperariosRepo: TOperariosRepo;
begin
  Result := FOperariosRepo;
end;

procedure TForm1.AutoPlanificacion1Click(Sender: TObject);
begin
  // Sin parametros = planifica todo el plan activo
  LaunchAutoPlanificacion([]);
end;

procedure TForm1.LaunchAutoPlanificacion(const ANodeIds: TArray<Integer>);
var
  Nodes: TArray<TNodeData>;
  Ids: TArray<Integer>;
  I: Integer;
  GetPreds: TFnGetPredecesores;
begin
  if not Assigned(DMPlanner) or not Assigned(DMPlanner.NodeDataRepo) then
  begin
    ShowMessage('Repositorio de nodos no inicializado.');
    Exit;
  end;
  if not Assigned(FOperariosRepo) or not Assigned(FHabilidadRepo) then Exit;

  // Si no se han pasado IDs, agafem todo el plan activo
  if Length(ANodeIds) = 0 then
  begin
    Nodes := DMPlanner.NodeDataRepo.GetAllData;
    if Length(Nodes) = 0 then
    begin
      ShowMessage('No hay nodos en el plan activo.');
      Exit;
    end;
    SetLength(Ids, Length(Nodes));
    for I := 0 to High(Nodes) do
      Ids[I] := Nodes[I].DataId;
  end
  else
  begin
    Ids := Copy(ANodeIds);
  end;

  // Construir callback de predecesoras consultando los links del Gantt.
  // Mapea DataId -> NodeId via FindNodeIndexById, recupera links donde el
  // node es ToNodeId, y devuelve los DataIds de los FromNodeId.
  GetPreds := nil;
  if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
  begin
    GetPreds :=
      function(ADataId: Integer): TArray<Integer>
      var
        Gc: TGanttControl;
        N: TNode;
        Idx, K, FromIdx: Integer;
        AllLinks: TArray<TErpLink>;
        LinkIdxs: TArray<Integer>;
        Lst: TList<Integer>;
      begin
        SetLength(Result, 0);
        Gc := FVistaGantt.GanttControl;
        if not Assigned(Gc) then Exit;
        // Find NodeId by DataId
        var NodeId: Integer := -1;
        var AllNodes := Gc.GetNodes;
        for K := 0 to High(AllNodes) do
          if AllNodes[K].DataId = ADataId then
          begin
            NodeId := AllNodes[K].Id;
            Break;
          end;
        if NodeId < 0 then Exit;

        AllLinks := Gc.GetLinks;
        LinkIdxs := Gc.GetLinksForNode(NodeId);
        Lst := TList<Integer>.Create;
        try
          for K := 0 to High(LinkIdxs) do
          begin
            if AllLinks[LinkIdxs[K]].ToNodeId <> NodeId then Continue;
            // Es predecesor (FromNodeId -> NodeId actual)
            FromIdx := Gc.FindNodeIndexById(AllLinks[LinkIdxs[K]].FromNodeId);
            if FromIdx < 0 then Continue;
            N := Gc.GetNodeAt(FromIdx);
            Lst.Add(N.DataId);
          end;
          Result := Lst.ToArray;
        finally
          Lst.Free;
        end;
      end;
  end;

  if TfrmAutoPlanificacion.Execute(DMPlanner.NodeDataRepo, FOperariosRepo,
    FAbsenciasRepo, FHabilidadRepo, FOperationTypesRepo, Ids,
    FPesosScoring, GetPreds) then
  begin
    if Assigned(DMPlanner) and DMPlanner.IsConnected then
      SavePesosActivo(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa,
        FPesosScoring);

    if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
    begin
      FVistaGantt.GanttControl.RebuildLayout;
      FVistaGantt.GanttControl.Invalidate;
    end;
    NotifyPlanModified(Ids);
  end;
end;

// Handlers EditarLinksClick / GestionOperarisClick / AssignarOperarisClick
// migrados a uVistaGantt.pas (ahora viven en el form de la VistaGantt).

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Btn: Integer;
begin
  CanClose := True;

  if not Assigned(FAutoSaver) then Exit;
  if not Assigned(DMPlanner) or not Assigned(DMPlanner.NodeDataRepo) then Exit;
  if not DMPlanner.NodeDataRepo.HasDirty then Exit;

  // Hay cambios sin guardar. Intentar flush s'incrono.
  try
    FAutoSaver.Flush(True);
  except
    // Continuamos al chequeo de abajo
  end;

  // Si despu'es del flush a'un quedan dirty, ofrecer 3 opciones
  if DMPlanner.NodeDataRepo.HasDirty then
  begin
    Btn := MessageDlg(
      'Hay cambios sin guardar y el guardado autom'#225'tico ha fallado.' + sLineBreak +
      sLineBreak +
      'S'#237 + ': Reintentar guardar ahora.' + sLineBreak +
      'No: Salir descartando los cambios.' + sLineBreak +
      'Cancelar: Volver a la aplicaci'#243'n.',
      mtWarning, [mbYes, mbNo, mbCancel], 0);

    case Btn of
      mrYes:
        begin
          try
            FAutoSaver.Flush(True);
          except
            on E: Exception do
              ShowMessage('Persiste el error: ' + E.Message);
          end;
          // Si a'un dirty, no cerrar
          if DMPlanner.NodeDataRepo.HasDirty then
            CanClose := False;
        end;
      mrNo:    CanClose := True;   // Descartar
      mrCancel: CanClose := False;
    end;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  // Persistir viewport actual antes de liberar
  if Assigned(FVistaGantt) then
    FVistaGantt.SaveViewportPrefs;

  // Flush final del auto-saver antes de liberar repos
  DestroyAutoSaver;

  FPlanningRuleEngine.Free;
  FCustomFieldDefs.Free;
  FOperariosRepo.Free;
  FAbsenciasRepo.Free;
  FHabilidadRepo.Free;
  FOperationTypesRepo.Free;
  FMoldeRepo.Free;
end;






end.
