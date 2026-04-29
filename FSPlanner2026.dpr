program FSPlanner2026;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  uGanttTypes in 'uGanttTypes.pas',
  uGanttControl in 'uGanttControl.pas',
  uGanttControlGrupo in 'uGanttControlGrupo.pas',
  uCentreCalendar in 'uCentreCalendar.pas',
  uGanttHelpers in 'uGanttHelpers.pas',
  uGanttTimeline in 'uGanttTimeline.pas',
  uGanttCentres in 'uGanttCentres.pas',
  uNodeHelpers in 'uNodeHelpers.pas',
  uNodeDataRepo in 'uNodeDataRepo.pas',
  uGanttBuilder in 'uGanttBuilder.pas',
  uErpSampleBuilder in 'uErpSampleBuilder.pas',
  uGanttNodeHint in 'uGanttNodeHint.pas',
  uErpTypes in 'uErpTypes.pas',
  uColorPalette64LayeredPopup in 'uColorPalette64LayeredPopup.pas',
  uGanttHistory in 'uGanttHistory.pas',
  uNodeInspector in 'uNodeInspector.pas' {frmNodeInspector},
  uOperariosTypes in 'uOperariosTypes.pas',
  uOperariosRepo in 'uOperariosRepo.pas',
  uAssignOperaris in 'uAssignOperaris.pas' {frmAssignOperaris},
  uGestionOperaris in 'uGestionOperaris.pas' {frmGestionOperaris},
  uOperarioFilterPopup in 'uOperarioFilterPopup.pas',
  uLinkEditor in 'uLinkEditor.pas' {frmLinkEditor},
  uHelpGuide in 'uHelpGuide.pas' {frmHelpGuide},
  uCentreInspector in 'uCentreInspector.pas' {frmCentreInspector},
  uGestionCentres in 'uGestionCentres.pas' {frmGestionCentres},
  uMarkerEditor in 'uMarkerEditor.pas' {frmMarkerEditor},
  uGestionMarkers in 'uGestionMarkers.pas' {frmGestionMarkers},
  uMoldeTypes in 'uMoldeTypes.pas',
  uMoldeRepo in 'uMoldeRepo.pas',
  uGestionMoldes in 'uGestionMoldes.pas' {frmGestionMoldes},
  uSampleDataGenerator in 'uSampleDataGenerator.pas',
  uGestionCalendarios in 'uGestionCalendarios.pas' {frmGestionCalendarios},
  uKanbanBoard in 'uKanbanBoard.pas',
  uDispatchList in 'uDispatchList.pas' {frmDispatchList},
  uBacklog in 'uBacklog.pas' {frmBacklog},
  uDemoBacklog in 'uDemoBacklog.pas',
  uBacklogRegenParams in 'uBacklogRegenParams.pas' {frmBacklogRegenParams},
  uUserPrefs in 'uUserPrefs.pas',
  uBacklogScheduler in 'uBacklogScheduler.pas',
  uBacklogSchedParams in 'uBacklogSchedParams.pas' {frmBacklogSchedParams},
  uBacklogSchedPreview in 'uBacklogSchedPreview.pas' {frmBacklogSchedPreview},
  uFiniteCapacityPlanner in 'uFiniteCapacityPlanner.pas' {frmFiniteCapacityPlanner},
  uPlanningRulesEditor in 'uPlanningRulesEditor.pas' {frmPlanningRulesEditor},
  uCuadroPlanificacionDelDia in 'uCuadroPlanificacionDelDia.pas' {frmCuadroPlanificacionDelDia},
  uGestionTurnos in 'uGestionTurnos.pas' {frmGestionTurnos},
  uDataConnector in 'uDataConnector.pas',
  uSQLServerConnector in 'uSQLServerConnector.pas',
  uDMPlanner in 'uDMPlanner.pas' {DMPlanner: TDataModule},
  uLogin in 'uLogin.pas' {frmLogin},
  uGestionRoles in 'uGestionRoles.pas' {frmGestionRoles},
  uGestionUsuarios in 'uGestionUsuarios.pas' {frmGestionUsuarios},
  uDBMigrations in 'uDBMigrations.pas',
  uDemoDataGenerator in 'uDemoDataGenerator.pas',
  uGestionDemos in 'uGestionDemos.pas' {frmGestionDemos},
  uGestionProyectos in 'uGestionProyectos.pas' {frmGestionProyectos},
  uAsignarUsuariosProyecto in 'uAsignarUsuariosProyecto.pas' {frmAsignarUsuariosProyecto},
  uDashboard in 'uDashboard.pas' {frmDashboard},
  uVistaGantt in 'uVistaGantt.pas' {frmVistaGantt},
  uCalendarsRepo in 'uCalendarsRepo.pas',
  uCentresRepo in 'uCentresRepo.pas',
  uNodesRepo in 'uNodesRepo.pas',
  uGestionAreas in 'uGestionAreas.pas' {frmGestionAreas},
  uGestionDepartamentos in 'uGestionDepartamentos.pas' {frmGestionDepartamentos},
  uGestionCapacitaciones in 'uGestionCapacitaciones.pas' {frmGestionCapacitaciones},
  uAsignarDepartamentos in 'uAsignarDepartamentos.pas' {frmAsignarDepartamentos},
  uAsignarCentrosMolde in 'uAsignarCentrosMolde.pas' {frmAsignarCentrosMolde},
  uEditarListaMolde in 'uEditarListaMolde.pas' {frmEditarListaMolde},
  uConfigEmpresa in 'uConfigEmpresa.pas' {frmConfigEmpresa},
  uErpSelector in 'uErpSelector.pas' {frmErpSelector},
  uErpPrefsSage200 in 'uErpPrefsSage200.pas' {frmErpPrefsSage200},
  uInstallWizard in 'uInstallWizard.pas' {frmInstallWizard},
  uGenerarNodosDemo in 'uGenerarNodosDemo.pas' {frmGenerarNodosDemo},
  uCentresKPI in 'uCentresKPI.pas' {frmCentresKPI},
  uGanttDatesDialog in 'uGanttDatesDialog.pas' {frmGanttDatesDialog},
  uAppConfig in 'uAppConfig.pas',
  uDBConfig in 'uDBConfig.pas' {frmDBConfig};

{$R *.res}

var
  Cfg: TDBConfig;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDMPlanner, DMPlanner);

  // Primera instalación: si no hay configuración de BBDD válida, lanzar el wizard.
  if NeedsInstallWizard then
  begin
    if not TfrmInstallWizard.Execute then
    begin
      Application.Terminate;
      Exit;
    end;
  end;

  // Cargar configuración de BD desde INI (si existe). El login mostrará error
  // y permitirá abrir el diálogo de configuración si falla la conexión.
  Cfg := LoadDBConfig;
  DMPlanner.Server         := Cfg.Server;
  DMPlanner.Database       := Cfg.Database;
  DMPlanner.UseWindowsAuth := Cfg.WindowsAuth;
  DMPlanner.UserName       := Cfg.UserName;
  DMPlanner.Password       := Cfg.Password;

  if not DoLogin then
  begin
    Application.Terminate;
    Exit;
  end;

  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TfrmPlanningRulesEditor, frmPlanningRulesEditor);
  Application.Run;
end.
