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
  uMoldeRepo, uGestionMoldes, uGestionUtillajes, uGestionCalendarios,
  uHeatmapCargaCentro,
  uHeatmapCargaOperario,
  uHeatmapEntregasVsCarga,
  uPlanAnalisis,
  uHistogramasOperarios,
  uCustomFieldDefs, uCustomFieldEditor, uCustomColsManager,
  uPlanningRules, uPlanningRulesEditor,
  uCardLayoutSetRepo, uCardLayoutSetManager,
  uNodeCardLayout, uNodeLayoutSetRepo, uNodeLayoutEditor,
  uGanttHintConfig, uGanttHintConfigRepo, uGanttHintConfigEditor,
  uDashBoard, uVistaGantt, uFiniteCapacityPlanner,
  uBacklog, uFiniteCapacityOperaris, uArticleDetail, dxGDIPlusClasses,
  dxSkinsCore, dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  cxButtons;

type

  TForm1 = class(TForm)tmr1Sec: TTimer;
    MainMenu1: TMainMenu;
    Archivo1: TMenuItem;
    Dashboard1: TMenuItem;
    N4: TMenuItem;
    Proyectos1: TMenuItem;
    PuntosRestauracion1: TMenuItem;
    ConfigEmpresa1: TMenuItem;
    SelectorErp1: TMenuItem;
    SincronizarERP1: TMenuItem;
    AsistenteInstalacion1: TMenuItem;
    GenerarNodosDemo1: TMenuItem;
    RegenerarGanttDemo1: TMenuItem;
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
    Alertas1: TMenuItem;
    Links1: TMenuItem;
    N10: TMenuItem;
    CamposPersonalizados1: TMenuItem;
    ColumnasPersonalizadas1: TMenuItem;
    ReglasPlanificacion1: TMenuItem;
    NCards1: TMenuItem;
    GestionCardLayouts1: TMenuItem;
    DisenadorNodos1: TMenuItem;
    ConfigHint1: TMenuItem;
    Vistas1: TMenuItem;
    AnalisisPlan1: TMenuItem;
    AlertasPlanificacion1: TMenuItem;
    Kanban1: TMenuItem;
    DispatchList1: TMenuItem;
    Backlog1: TMenuItem;
    GenerarBacklogDemo1: TMenuItem;
    FiniteCapacity1: TMenuItem;
    FiniteCapacityOperaris1: TMenuItem;
    HeatmapCargaCentro1: TMenuItem;
    HeatmapCargaOperario1: TMenuItem;
    HeatmapEntregasVsCarga1: TMenuItem;
    HistogramasOperarios1: TMenuItem;
    AutoPlanificacion1: TMenuItem;
    PlanificacionReglas1: TMenuItem;
    PesosScoring1: TMenuItem;
    CuadroPlanificacionDia1: TMenuItem;
    Configuracion1: TMenuItem;
    Roles1: TMenuItem;
    Usuarios1: TMenuItem;
    PreferenciasGantt1: TMenuItem;
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
    N1: TMenuItem;
    N6: TMenuItem;
    Panel2: TPanel;
    btnTB_Dashboard: TcxButton;
    btnTB_BackLog: TcxButton;
    btnTB_PlaniCentros: TcxButton;
    cxButton1: TcxButton;  btnTB_PlaniOperarios: TcxButton;
    btnTB_PlaniGantt: TcxButton;
    btnTB_Help: TcxButton;
    btnLinkERP: TcxButton;
    btnTB_Demo: TcxButton;
    cxButton2: TcxButton;
    btnTB_PlaniAlertas: TcxButton;
    N7: TMenuItem;

    procedure Roles1Click(Sender: TObject);
    procedure Usuarios1Click(Sender: TObject);
    procedure InstalarDemos1Click(Sender: TObject);
    procedure Proyectos1Click(Sender: TObject);
    procedure PuntosRestauracion1Click(Sender: TObject);
    procedure ConfigEmpresa1Click(Sender: TObject);
    procedure PreferenciasGantt1Click(Sender: TObject);
    procedure SelectorErp1Click(Sender: TObject);
    procedure SincronizarERP1Click(Sender: TObject);
    procedure StockCockpit1Click(Sender: TObject);
    procedure ArticleDetail1Click(Sender: TObject);
    procedure DashboardOperativo1Click(Sender: TObject);
    procedure AsistenteInstalacion1Click(Sender: TObject);
    procedure GenerarNodosDemo1Click(Sender: TObject);
    procedure RegenerarGanttDemo1Click(Sender: TObject);
    procedure Dashboard1Click(Sender: TObject);
    procedure Areas1Click(Sender: TObject);
    procedure Departamentos1Click(Sender: TObject);
    procedure Ausencias1Click(Sender: TObject);
    procedure Habilidades1Click(Sender: TObject);
    procedure OperacionHabilidades1Click(Sender: TObject);
    procedure OperationTypes1Click(Sender: TObject);
    procedure AutoPlanificacion1Click(Sender: TObject);
    procedure PlanificacionReglas1Click(Sender: TObject);
    procedure PesosScoring1Click(Sender: TObject);
    procedure MostrarDashboard;
    procedure OcultarDashboard;
    procedure AplicarModoDemoGantt;   // entra/sale del proyecto demo y recarga
    procedure ActualizarCaption;      // "FSPlanner 2026 - Empresa - Proyecto"
    procedure MostrarBacklog;
    procedure OcultarBacklog;
    procedure MostrarFiniteCapacityOperaris;
    procedure OcultarFiniteCapacityOperaris;
    procedure DashboardAbrirGantt(Sender: TObject);
    procedure DashboardAbrirFiniteCapacity(Sender: TObject);
    procedure MostrarVistaGantt;
    procedure MostrarFiniteCapacity;
    // Muestra el Detalle de Articulo como child embebido (patron VistaGantt/
    // Dashboard). Si ACodigo<>'' calcula directamente ese articulo.
    procedure MostrarArticleDetail(const ACodigo: string = '');
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
    // Persistencia automatica de asignaciones operario<->nodo a FS_PL_OperatorAssignment
    procedure OperariosRepoAsignacionAdded(const A: TAsignacionOperario);
    procedure OperariosRepoAsignacionUpdated(const A: TAsignacionOperario);
    procedure OperariosRepoAsignacionRemoved(OperarioId, DataId: Integer);
    procedure OperariosRepoAsignacionsNodeCleared(DataId: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure tmr1SecTimer(Sender: TObject);
    procedure Moldes1Click(Sender: TObject);
    procedure Utillajes1Click(Sender: TObject);
    procedure Alertas1Click(Sender: TObject);
    procedure Calendarios1Click(Sender: TObject);
    procedure Turnos1Click(Sender: TObject);
    procedure Operarios1Click(Sender: TObject);
    procedure Centros1Click(Sender: TObject);
    procedure Maquinas1Click(Sender: TObject);
    procedure CamposPersonalizados1Click(Sender: TObject);
    procedure ColumnasPersonalizadas1Click(Sender: TObject);
    procedure ReglasPlanificacion1Click(Sender: TObject);
    procedure GestionCardLayouts1Click(Sender: TObject);
    procedure DisenadorNodos1Click(Sender: TObject);
    procedure ConfigHint1Click(Sender: TObject);
    procedure Kanban1Click(Sender: TObject);
    procedure DispatchList1Click(Sender: TObject);
    procedure Backlog1Click(Sender: TObject);
    procedure GenerarBacklogDemo1Click(Sender: TObject);
    procedure FiniteCapacity1Click(Sender: TObject);
    procedure FiniteCapacityOperaris1Click(Sender: TObject);
    procedure HeatmapCargaCentro1Click(Sender: TObject);
    procedure HeatmapCargaOperario1Click(Sender: TObject);
    procedure HeatmapEntregasVsCarga1Click(Sender: TObject);
    procedure AnalisisPlan1Click(Sender: TObject);
    procedure AlertasPlanificacion1Click(Sender: TObject);
    procedure btnTB_PlaniAlertasClick(Sender: TObject);
    procedure HistogramasOperarios1Click(Sender: TObject);
    procedure CuadroPlanificacionDia1Click(Sender: TObject);
    procedure Salir1Click(Sender: TObject);
    procedure MnGanttClick(Sender: TObject);
    procedure Indicadoresdecentros1Click(Sender: TObject);
    procedure btnTB_HelpClick(Sender: TObject);
    procedure btnLinkERPClick(Sender: TObject);
    procedure btnTB_DemoClick(Sender: TObject);
    procedure cxButton2Click(Sender: TObject);
  private
    { Private declarations }

    FCustomFieldDefs: TCustomFieldDefs;
    FPlanningRuleEngine: TPlanningRuleEngine;
    FUpdatingViewport: Boolean;

    FTurnos: TArray<TTurno>;

    // Reentrancia: True mientras se esta abriendo un form via OpenAction.
    // Evita que el usuario haga doble-click en la toolbar y dispare dos
    // aperturas en paralelo (forms pesados como Backlog/Gantt/FCP).
    FOpeningForm: Boolean;

  public
    { Public declarations }

    // Motor de reglas de planificacion del cliente (perfiles custom). Solo
    // lectura: lo consumen forms hijos (p.ej. el wizard del Backlog) para
    // listar/aplicar perfiles. La instancia la posee y libera el Main.
    property PlanningRuleEngine: TPlanningRuleEngine read FPlanningRuleEngine;

    // Envoltorio para abrir forms desde la toolbar: ignora clics nuevos
    // mientras hay una apertura en curso y muestra el BusyDialog si AShowBusy.
    // AAction recibe lo que normalmente harias en el OnClick: crear / mostrar
    // el form (modal o no-modal).
    procedure OpenAction(const ABusyMessage: string; AShowBusy: Boolean;
      AAction: TProc);

    // Llamar despues de cada operaci'on que modifica nodos (Kanban, Inspector, Gantt).
    procedure NotifyPlanModified(const ADataIds: TArray<Integer>);

    // Acceso a repos globales (para forms hijos)
    function GetHabilidadRepo: THabilidadRepo;
    function GetOperariosRepo: TOperariosRepo;

    // Lanza la pantalla de Auto-Planificacion sobre los DataIds dados.
    // Si ANodeIds esta vacio, planifica TODO el plan activo.
    procedure LaunchAutoPlanificacion(const ANodeIds: TArray<Integer>);

    // Actualiza el caption del boton de alertas de la toolbar con la salud del
    // plan recien calculada. La llama la VistaGantt tras RecalcAlertas.
    procedure ActualizarBotonAlertas(const ASalud, ATotalIncidencias: Integer);

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
  FFiniteCapacity: TfrmFiniteCapacityPlanner;
  FBacklog: uBacklog.TfrmBacklog;
  FFiniteOps: uFiniteCapacityOperaris.TfrmFiniteCapacityOperaris;
  FArticleDetail: TfrmArticleDetail;

implementation

uses uErpSampleBuilder, uGestionCentres, uGestionMaquinas, uKanbanBoard, uVistaKanban, uDispatchList,
  uAlertConfig, uRestorePoints,
  uDemoBacklog, uDemoMode,
  uOperarioAusencias,
  uGestionHabilidades, uPesosScoring, uAutoPlanificacion,
  uBacklogScheduler, uGanttConfig, uPlanningEngine, uPlanningEngineRules,
  uReglasPlanParams, uReglasPlanPreview, uReglasPlanComparativa,
  uGestionOperacionHabilidades, uGestionOperationTypes,
  uCuadroPlanificacionDelDia, uGestionTurnos,
  uDMPlanner, uGestionRoles, uGestionUsuarios, uLogin, uGestionDemos,
  uGestionProyectos, uGestionAreas, uGestionDepartamentos,
  uConfigEmpresa, uGenerarNodosDemo, uCentresKPI, uErpSelector, uSincronizarERP, uInstallWizard,
  uDataConnector, uUserPrefs,
  uErpReader, uErpReaderFactory, uStockCockpit,
  uDashboardOperativo, uBusyDialog, uHelpViewer;

{$R *.dfm}


procedure TForm1.OpenAction(const ABusyMessage: string; AShowBusy: Boolean;
  AAction: TProc);
var
  Busy: TfrmBusyDialog;
begin
  if FOpeningForm then Exit;
  if not Assigned(AAction) then Exit;

  FOpeningForm := True;
  Busy := nil;
  try
    if AShowBusy and (ABusyMessage <> '') then
      Busy := TfrmBusyDialog.Display(Self, ABusyMessage);
    try
      AAction();
    finally
      if Busy <> nil then Busy.Free;
    end;
  finally
    FOpeningForm := False;
  end;
end;


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
  OpenAction('Cargando Backlog...', True,
    procedure
    begin
      MostrarBacklog;
    end);
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
begin
  if DMPlanner.CurrentProjectId <= 0 then
  begin
    ShowMessage('No hay ningún proyecto activo.');
    Exit;
  end;
  OpenAction('Cargando Planificador de Centros...', True,
    procedure
    begin
      if Assigned(FVistaGantt) then
        FVistaGantt.Visible := False;
      MostrarFiniteCapacity;
    end);
end;

procedure TForm1.FiniteCapacityOperaris1Click(Sender: TObject);
begin
  OpenAction('Cargando Planificador de Operarios...', True,
    procedure
    begin
      MostrarFiniteCapacityOperaris;
    end);
end;

procedure TForm1.OperariosRepoAsignacionAdded(const A: TAsignacionOperario);
var
  Cmd: TADOCommand;
  CE: SmallInt;
begin
  if not Assigned(DMPlanner) or not DMPlanner.IsConnected then Exit;
  CE := DMPlanner.CodigoEmpresa;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    try
      // Borra previa (si existeix la mateixa parella op+node) i inserta neta.
      Cmd.CommandText :=
        'DELETE FROM FS_PL_OperatorAssignment ' +
        'WHERE CodigoEmpresa = ' + IntToStr(CE) +
        '  AND OperatorId = ' + IntToStr(A.OperarioId) +
        '  AND NodeId = ' + IntToStr(A.DataId);
      Cmd.Execute;
      Cmd.CommandText :=
        'INSERT INTO FS_PL_OperatorAssignment (CodigoEmpresa, OperatorId, NodeId, Horas) ' +
        'VALUES (' + IntToStr(CE) + ', ' + IntToStr(A.OperarioId) + ', ' +
        IntToStr(A.DataId) + ', ' +
        FloatToStr(A.Horas, TFormatSettings.Invariant) + ')';
      Cmd.Execute;
    except
      // Si la tabla no existe (V019 no aplicada), ignorar silenciosamente.
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TForm1.OperariosRepoAsignacionUpdated(const A: TAsignacionOperario);
var
  Cmd: TADOCommand;
  CE: SmallInt;
begin
  if not Assigned(DMPlanner) or not DMPlanner.IsConnected then Exit;
  CE := DMPlanner.CodigoEmpresa;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    try
      Cmd.CommandText :=
        'UPDATE FS_PL_OperatorAssignment SET Horas = ' +
        FloatToStr(A.Horas, TFormatSettings.Invariant) +
        ' WHERE CodigoEmpresa = ' + IntToStr(CE) +
        '   AND OperatorId = ' + IntToStr(A.OperarioId) +
        '   AND NodeId = ' + IntToStr(A.DataId);
      Cmd.Execute;
    except
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TForm1.OperariosRepoAsignacionRemoved(OperarioId, DataId: Integer);
var
  Cmd: TADOCommand;
  CE: SmallInt;
begin
  if not Assigned(DMPlanner) or not DMPlanner.IsConnected then Exit;
  CE := DMPlanner.CodigoEmpresa;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    try
      Cmd.CommandText :=
        'DELETE FROM FS_PL_OperatorAssignment ' +
        'WHERE CodigoEmpresa = ' + IntToStr(CE) +
        '  AND OperatorId = ' + IntToStr(OperarioId) +
        '  AND NodeId = ' + IntToStr(DataId);
      Cmd.Execute;
    except
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TForm1.OperariosRepoAsignacionsNodeCleared(DataId: Integer);
var
  Cmd: TADOCommand;
  CE: SmallInt;
begin
  if not Assigned(DMPlanner) or not DMPlanner.IsConnected then Exit;
  CE := DMPlanner.CodigoEmpresa;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    try
      Cmd.CommandText :=
        'DELETE FROM FS_PL_OperatorAssignment ' +
        'WHERE CodigoEmpresa = ' + IntToStr(CE) +
        '  AND NodeId = ' + IntToStr(DataId);
      Cmd.Execute;
    except
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TForm1.HeatmapCargaCentro1Click(Sender: TObject);
begin
  TfrmHeatmapCargaCentro.Execute;
end;

procedure TForm1.HeatmapCargaOperario1Click(Sender: TObject);
begin
  TfrmHeatmapCargaOperario.Execute;
end;

procedure TForm1.HeatmapEntregasVsCarga1Click(Sender: TObject);
begin
  TfrmHeatmapEntregasVsCarga.Execute;
end;

procedure TForm1.AnalisisPlan1Click(Sender: TObject);
begin
  TfrmPlanAnalisis.Ejecutar;
end;

procedure TForm1.AlertasPlanificacion1Click(Sender: TObject);
begin
  // Reaprovecha el dialogo de alertas de la VistaGantt activa (mismo Provider
  // que el KPI). Sin Gantt activo no hay nada que analizar.
  if not Assigned(FVistaGantt) or not Assigned(FVistaGantt.GanttControl) then
  begin
    ShowMessage('No hay un plan Gantt activo para analizar.');
    Exit;
  end;
  FVistaGantt.MostrarAlertas;
end;

procedure TForm1.btnTB_PlaniAlertasClick(Sender: TObject);
begin
  // Acceso directo desde la toolbar al mismo dialogo de alertas.
  AlertasPlanificacion1Click(Sender);
end;

procedure TForm1.ActualizarBotonAlertas(const ASalud,
  ATotalIncidencias: Integer);
begin
  // El boton muestra la salud del plan (semaforo) cuando esta calculada, con el
  // nº de incidencias entre parentesis. Color de fondo segun el grado de salud.
  if ASalud < 0 then
    btnTB_PlaniAlertas.Caption := 'Alertas'
  else if ATotalIncidencias = 0 then
    btnTB_PlaniAlertas.Caption := Format('Salud %d/100', [ASalud])
  else
    btnTB_PlaniAlertas.Caption := Format('Salud %d/100 (%d)',
      [ASalud, ATotalIncidencias]);

  // Color de fondo verde -> rojo segun salud (mismo criterio que el KPI).
  if ASalud < 0 then
    btnTB_PlaniAlertas.Colors.Normal := $00F0F0F0   // gris boton por defecto
  else if ASalud >= 90 then
    btnTB_PlaniAlertas.Colors.Normal := $00C8E6C8     // verde claro
  else if ASalud >= 75 then
    btnTB_PlaniAlertas.Colors.Normal := $00C8F0F8     // amarillo claro
  else if ASalud >= 50 then
    btnTB_PlaniAlertas.Colors.Normal := $00C0E0FF     // naranja claro
  else
    btnTB_PlaniAlertas.Colors.Normal := $00C8C8FF;    // rojo claro
  btnTB_PlaniAlertas.Colors.Default := btnTB_PlaniAlertas.Colors.Normal;
end;

procedure TForm1.HistogramasOperarios1Click(Sender: TObject);
begin
  TfrmHistogramasOperarios.Execute;
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


procedure TForm1.cxButton2Click(Sender: TObject);
begin
  MostrarArticleDetail;
end;

procedure TForm1.Indicadoresdecentros1Click(Sender: TObject);
begin
  // Los indicadores se calculan sobre los nodos cargados en el Gantt. Si la
  // vista Gantt aun no se ha abierto (FVistaGantt = nil), acceder a su control
  // provocaria un Access Violation, asi que avisamos al usuario.
  if not HasActivePlan then
  begin
    ShowMessage('Primero selecciona un plan activo para ver los indicadores de centros.');
    Exit;
  end;
  if (FVistaGantt = nil) or (FVistaGantt.GanttControl = nil) then
  begin
    ShowMessage('Abre primero la vista Gantt (Cronograma) para cargar el plan; '
      + 'despu'#233's podr'#225's consultar los indicadores de centros.');
    Exit;
  end;

  TfrmCentresKPI.Execute(
    Self,
    DMPlanner.CentresRepo.GetAll,
    FVistaGantt.GanttControl,
    DMPlanner.NodeDataRepo,
    FVistaGantt.FOperariosRepo,
    0);
end;

procedure TForm1.btnLinkERPClick(Sender: TObject);
begin
  ShowMessage('Enlace directo hacia el ERP');
end;

procedure TForm1.AplicarModoDemoGantt;
var
  DemoId, NumNodos, Generados: Integer;
  S: string;
begin
  // El modo demo del GANTT vive en un proyecto propio (EsDemo=1), aislado de
  // los datos reales. Entrar = cambiar el proyecto activo al demo; salir =
  // volver al real. Distinto del DemoMode "en memoria" de KPIs/graficos.
  if not DMPlanner.IsConnected then Exit;

  if uDemoMode.DemoMode.Active then
  begin
    DemoId := DMPlanner.EntrarModoDemo;
    if DemoId <= 0 then
    begin
      ShowMessage('No se ha podido preparar el proyecto de demostraci'#243'n.');
      Exit;
    end;
    // Si el proyecto demo esta vacio, preguntar cuantos nodos generar.
    if DMPlanner.ContarNodosProyecto(DemoId) = 0 then
    begin
      S := '200';
      if InputQuery('Gantt en modo demostraci'#243'n',
           'El Gantt de demostraci'#243'n est'#225' vac'#237'o.'#13#10 +
           #191'Cu'#225'ntos nodos ficticios quieres generar? (10-2000)', S) then
      begin
        NumNodos := StrToIntDef(Trim(S), 0);
        if NumNodos < 10 then NumNodos := 10;
        if NumNodos > 2000 then NumNodos := 2000;
        Generados := 0;
        ShowBusy(Self, 'Generando ' + IntToStr(NumNodos) + ' nodos de demostraci'#243'n...',
          procedure
          begin
            Generados := DMPlanner.GenerarNodosDemoEnProyecto(DemoId, NumNodos);
          end);
        if Generados <= 0 then
          ShowMessage('No se han podido generar los nodos de demostraci'#243'n.');
      end;
    end;
  end
  else
    DMPlanner.SalirModoDemo;

  // Recargar el plan activo (demo o real) recien conmutado. Usamos
  // LoadActivePlan y NO solo FVistaGantt.Inicializar porque este ultimo NO
  // recarga las asignaciones de operarios (FOperariosRepo) ni los centros: eso
  // lo hace LoadActivePlan. Si no, los nodos demo apareceran sin operarios
  // aunque esten en BD.
  LoadActivePlan;

  ActualizarCaption;   // refleja "... - ★ DEMOSTRACIÓN" o el proyecto real
end;

procedure TForm1.btnTB_DemoClick(Sender: TObject);
begin
  // Boton sticky (GroupIndex=2, AllowAllUp): su estado Down define el modo.
  // Al conmutar, DemoMode avisa a las pantallas suscritas para que se
  // repinten con datos ficticios (Down) o reales (Up).
  uDemoMode.DemoMode.Active := btnTB_Demo.Down;
  // Ademas, el GANTT usa un proyecto demo aislado: entrar/salir de el y recargar.
  AplicarModoDemoGantt;
end;

procedure TForm1.btnTB_HelpClick(Sender: TObject);
var
  TopicKey, Titulo: string;
begin
  // Determinar quina vista embedded esta visible i obrir-ne l'ajuda.
  // El ordre del if/else if reflecteix prioritat: si dos forms estiguessin
  // visibles simultaniament (no hauria de passar), guanya el primer.
  TopicKey := '';
  if Assigned(FVistaGantt) and FVistaGantt.Visible then
  begin
    TopicKey := 'uVistaGantt';
    Titulo := 'Vista Gantt';
  end
  else if Assigned(FFiniteCapacity) and FFiniteCapacity.Visible then
  begin
    TopicKey := 'uFiniteCapacityPlanner';
    Titulo := 'Planificador de Capacidad Finita';
  end
  else if Assigned(FFiniteOps) and FFiniteOps.Visible then
  begin
    TopicKey := 'uFiniteCapacityOperaris';
    Titulo := 'Planificaci'#243'n por Operario';
  end
  else if Assigned(FBacklog) and FBacklog.Visible then
  begin
    TopicKey := 'uBacklog';
    Titulo := 'Backlog / Carga pendiente';
  end
  else if Assigned(FDashboard) and FDashboard.Visible then
  begin
    TopicKey := 'uDashboard';
    Titulo := 'Panel de control';
  end;

  if TopicKey = '' then
    TopicKey := 'Main';
  if Titulo = '' then
    Titulo := 'FS Planner 2026';

  THelpViewer.Show(TopicKey, Titulo);
end;

procedure TForm1.MnGanttClick(Sender: TObject);
begin
  OpenAction('Cargando Gantt...', True,
    procedure
    begin
      //OcultarDashboard;
      MostrarVistaGantt;
    end);
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

procedure TForm1.Utillajes1Click(Sender: TObject);
begin
  TfrmGestionUtillajes.Execute;
end;

procedure TForm1.Alertas1Click(Sender: TObject);
begin
  if Assigned(DMPlanner.AlertRulesRepo) then
    TfrmAlertConfig.Ejecutar(Self, DMPlanner.AlertRulesRepo)
  else
    ShowMessage('No hay conexi'#243'n con la base de datos.');
end;

procedure TForm1.CamposPersonalizados1Click(Sender: TObject);
begin
  if TfrmCustomFieldEditor.Execute(FCustomFieldDefs) then
    FCustomFieldDefs.SaveToFile;
end;

procedure TForm1.ColumnasPersonalizadas1Click(Sender: TObject);
begin
  // Punto unico: columnas personalizadas de Backlog/Centros/Operarios/Maquinas.
  uCustomColsManager.TfrmCustomColsManager.Execute;
end;

procedure TForm1.ReglasPlanificacion1Click(Sender: TObject);
begin
  if TfrmPlanningRulesEditor.Execute(FPlanningRuleEngine) then
    FPlanningRuleEngine.SaveToFile;
end;

procedure TForm1.GestionCardLayouts1Click(Sender: TObject);
var
  Repo: TCardLayoutSetRepo;
begin
  if not DMPlanner.IsConnected then
  begin
    ShowMessage('No hay conexi'#243'n a BD.');
    Exit;
  end;
  Repo := TCardLayoutSetRepo.Create(
    DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    Repo.SeedDefaultIfEmpty;
    ShowCardLayoutSetManager(Self, Repo, FCustomFieldDefs);
  finally
    Repo.Free;
  end;
end;

procedure TForm1.DisenadorNodos1Click(Sender: TObject);
var
  Repo: TNodeLayoutSetRepo;
  ASet: TNodeLayoutSet;
begin
  if not DMPlanner.IsConnected then
  begin
    ShowMessage('No hay conexi'#243'n a BD.');
    Exit;
  end;
  Repo := TNodeLayoutSetRepo.Create(
    DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    Repo.SeedDefaultIfEmpty;
    // Editar/guardar el set de layout de nodos por Vista y, al cerrar, recargar
    // el set activo y aplicarlo al Gantt en caliente (render real, Fase 2).
    if ShowNodeLayoutEditor(Self, Repo) then
    begin
      Repo.LoadActive(ASet);
      if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
        FVistaGantt.GanttControl.SetNodeLayoutSet(ASet);
    end;
  finally
    Repo.Free;
  end;
end;

procedure TForm1.ConfigHint1Click(Sender: TObject);
var
  Repo: THintConfigSetRepo;
  ASet: THintConfigSet;
begin
  if not DMPlanner.IsConnected then
  begin
    ShowMessage('No hay conexi'#243'n a BD.');
    Exit;
  end;
  Repo := THintConfigSetRepo.Create(
    DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  try
    Repo.SeedDefaultIfEmpty;
    if ShowGanttHintConfigEditor(Self, Repo) then
    begin
      // Recarga la config activa y la aplica al Gantt en caliente.
      Repo.LoadActive(ASet);
      if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
      begin
        FVistaGantt.GanttControl.SetHintConfigSet(ASet);
        FVistaGantt.GanttControl.Invalidate;
      end;
    end;
  finally
    Repo.Free;
  end;
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

procedure TForm1.PuntosRestauracion1Click(Sender: TObject);
begin
  if not Assigned(DMPlanner) or not Assigned(DMPlanner.SnapshotRepo) then
  begin
    ShowMessage('No hay conexi'#243'n con la base de datos.');
    Exit;
  end;
  if DMPlanner.CurrentProjectId <= 0 then
  begin
    ShowMessage('No hay ning'#250'n proyecto activo.');
    Exit;
  end;

  // Vaciar cambios pendientes a BD para que los puntos reflejen el estado real.
  if Assigned(FAutoSaver) then
    FAutoSaver.Flush(True);

  // Si el usuario restaura, recargamos el plan activo en pantalla.
  if TfrmRestorePoints.Ejecutar(Self, DMPlanner.SnapshotRepo,
       DMPlanner.CurrentProjectId) then
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
  FOperariosRepo.OnAsignacionAdded := OperariosRepoAsignacionAdded;
  FOperariosRepo.OnAsignacionUpdated := OperariosRepoAsignacionUpdated;
  FOperariosRepo.OnAsignacionRemoved := OperariosRepoAsignacionRemoved;
  FOperariosRepo.OnAsignacionsNodeCleared := OperariosRepoAsignacionsNodeCleared;
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
    FDashboard.OnAbrirFiniteCapacity := DashboardAbrirFiniteCapacity;
    FDashboard.Parent := Self;
    FDashboard.Align := alClient;
  end;
  if Assigned(FFiniteCapacity) then
  begin
    FFiniteCapacity.SaveNow;  // persistir asignaciones ANTES de ocultar (OnHide no es fiable en embebido)
    FFiniteCapacity.Visible := False;
  end;
  if Assigned(FVistaGantt) then    FVistaGantt.Visible := False;
  if Assigned(FBacklog) then       FBacklog.Visible := False;
  if Assigned(FFiniteOps) then     FFiniteOps.Visible := False;
  FDashboard.Refrescar;
  FDashboard.Visible := True;
  FDashboard.BringToFront;
end;

procedure TForm1.OcultarDashboard;
begin
  if Assigned(FDashboard) then
    FDashboard.Visible := False;
end;

procedure TForm1.MostrarArticleDetail(const ACodigo: string);
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

  if FArticleDetail = nil then
  begin
    FArticleDetail := TfrmArticleDetail.Create(Self);
    FArticleDetail.Parent := Self;
    FArticleDetail.Align := alClient;
  end;
  FArticleDetail.PrepareAsChild(Reader);

  // Ocultar los demas childs hermanos.
  if Assigned(FDashboard) then      FDashboard.Visible := False;
  if Assigned(FFiniteCapacity) then
  begin
    FFiniteCapacity.SaveNow;  // persistir asignaciones ANTES de ocultar (OnHide no es fiable en embebido)
    FFiniteCapacity.Visible := False;
  end;
  if Assigned(FVistaGantt) then     FVistaGantt.Visible := False;
  if Assigned(FBacklog) then        FBacklog.Visible := False;
  if Assigned(FFiniteOps) then      FFiniteOps.Visible := False;

  FArticleDetail.Visible := True;
  FArticleDetail.BringToFront;

  if Trim(ACodigo) <> '' then
    FArticleDetail.CargarArticulo(ACodigo);
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

  if Assigned(FFiniteCapacity) then
  begin
    FFiniteCapacity.SaveNow;  // persistir asignaciones ANTES de ocultar (OnHide no es fiable en embebido)
    FFiniteCapacity.Visible := False;
  end;
  if Assigned(FDashboard) then      FDashboard.Visible := False;
  if Assigned(FBacklog) then        FBacklog.Visible := False;
  if Assigned(FFiniteOps) then      FFiniteOps.Visible := False;
  FVistaGantt.Visible := True;
  FVistaGantt.BringToFront;
end;

procedure TForm1.DashboardAbrirFiniteCapacity(Sender: TObject);
begin
  OcultarDashboard;
  MostrarFiniteCapacity;
end;

procedure TForm1.MostrarFiniteCapacity;
begin
  if not HasActivePlan then
  begin
    MostrarDashboard;
    Exit;
  end;
  if not Assigned(FOperariosRepo) then
  begin
    ShowMessage('Repositorio de operarios no inicializado.');
    Exit;
  end;
  if FFiniteCapacity = nil then
  begin
    FFiniteCapacity := TfrmFiniteCapacityPlanner.Create(Self);
    FFiniteCapacity.Parent := Self;
    FFiniteCapacity.Align := alClient;
    try
      FFiniteCapacity.Inicializar(
        DMPlanner.NodeDataRepo,
        FOperariosRepo,
        FPlanningRuleEngine,
        FCustomFieldDefs);
    except
      on E: Exception do
      begin
        ShowMessage('Error en Inicializar FiniteCapacity: ' + sLineBreak +
          E.ClassName + ': ' + E.Message);
        FreeAndNil(FFiniteCapacity);
        Exit;
      end;
    end;
  end
  else
  begin
    // Ya inicializado: re-sincronizar con BD. Al volver desde el Gantt, su
    // LoadActivePlan/LoadNodes hace Clear del NodeDataRepo compartido y solo
    // repuebla planificados, perdiendo las pendientes del Backlog del Kanban.
    try
      FFiniteCapacity.RecargarDatos;
    except
      on E: Exception do
        ShowMessage('Error al recargar FiniteCapacity: ' + sLineBreak +
          E.ClassName + ': ' + E.Message);
    end;
  end;
  if Assigned(FDashboard) then  FDashboard.Visible := False;
  if Assigned(FVistaGantt) then FVistaGantt.Visible := False;
  if Assigned(FBacklog) then    FBacklog.Visible := False;
  if Assigned(FFiniteOps) then  FFiniteOps.Visible := False;
  FFiniteCapacity.Visible := True;
  FFiniteCapacity.BringToFront;
end;

procedure TForm1.MostrarBacklog;
begin
  if not HasActivePlan then
  begin
    MostrarDashboard;
    Exit;
  end;
  if FBacklog = nil then
  begin
    FBacklog := uBacklog.TfrmBacklog.Create(Self);
    FBacklog.BorderStyle := bsNone;
    FBacklog.Parent := Self;
    FBacklog.Align := alClient;
  end;
  if Assigned(FDashboard) then      FDashboard.Visible := False;
  if Assigned(FVistaGantt) then     FVistaGantt.Visible := False;
  if Assigned(FFiniteCapacity) then
  begin
    FFiniteCapacity.SaveNow;  // persistir asignaciones ANTES de ocultar (OnHide no es fiable en embebido)
    FFiniteCapacity.Visible := False;
  end;
  if Assigned(FFiniteOps) then      FFiniteOps.Visible := False;
  FBacklog.Visible := True;
  FBacklog.BringToFront;
end;

procedure TForm1.OcultarBacklog;
begin
  if Assigned(FBacklog) then
    FBacklog.Visible := False;
end;

procedure TForm1.MostrarFiniteCapacityOperaris;
begin
  if not HasActivePlan then
  begin
    MostrarDashboard;
    Exit;
  end;
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
  if FFiniteOps = nil then
  begin
    FFiniteOps := uFiniteCapacityOperaris.TfrmFiniteCapacityOperaris.Create(Self);
    FFiniteOps.BorderStyle := bsNone;
    FFiniteOps.Parent := Self;
    FFiniteOps.Align := alClient;
    FFiniteOps.InicializarEmbedded(
      DMPlanner.NodeDataRepo,
      FOperariosRepo,
      FAbsenciasRepo,
      nil,
      FCustomFieldDefs);
  end;
  if Assigned(FDashboard) then      FDashboard.Visible := False;
  if Assigned(FVistaGantt) then     FVistaGantt.Visible := False;
  if Assigned(FFiniteCapacity) then
  begin
    FFiniteCapacity.SaveNow;  // persistir asignaciones ANTES de ocultar (OnHide no es fiable en embebido)
    FFiniteCapacity.Visible := False;
  end;
  if Assigned(FBacklog) then        FBacklog.Visible := False;
  FFiniteOps.Visible := True;
  FFiniteOps.BringToFront;
end;

procedure TForm1.OcultarFiniteCapacityOperaris;
begin
  if Assigned(FFiniteOps) then
    FFiniteOps.Visible := False;
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
    ActualizarCaption;
    MostrarDashboard;
    Exit;
  end;

  DMPlanner.NodeDataRepo.Clear;

  // Resolver proyecto activo del usuario logueado. EXCEPCION: en modo demo el
  // proyecto activo ya es el proyecto demo (fijado por EntrarModoDemo); NO hay
  // que re-resolverlo desde la sesion/master o se perderia el demo.
  if not DMPlanner.EnModoDemo then
  begin
    if CurrentSession.UserId > 0 then
      DMPlanner.LoadUserActiveProject(CurrentSession.UserId)
    else
      DMPlanner.LoadMasterProject;
  end;

  if DMPlanner.CurrentProjectId <= 0 then
  begin
    ActualizarCaption;
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
    // Vaciar las asignaciones previas: LoadActivePlan puede llamarse varias
    // veces (cambio de proyecto, entrar/salir de demo, regenerar) y sin este
    // Clear las asignaciones se ACUMULAN -> operarios duplicados por nodo.
    FOperariosRepo.ClearTodasAsignaciones;
    FOperariosRepo.BulkLoadMode := True;
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
      FOperariosRepo.BulkLoadMode := False;
    end;
  end;

  // Inicializar / re-cablear el auto-saver para el plan recien cargado
  InitAutoSaver;

  // Cargar la config del hint (que campos y orden por Vista) y aplicarla al
  // Gantt, para que el hover muestre lo que el usuario eligio.
  if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
  begin
    var HintRepo := THintConfigSetRepo.Create(
      DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
    try
      var HintSet: THintConfigSet;
      HintRepo.LoadActive(HintSet);
      FVistaGantt.GanttControl.SetHintConfigSet(HintSet);
    finally
      HintRepo.Free;
    end;
  end;

  // Cargar el Node Layout Set (contenido visual de los nodos por Vista) y
  // aplicarlo al Gantt, para que el render pinte cada nodo segun el diseno
  // elegido en el "Disenador de Nodos del Gantt".
  if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
  begin
    var NodeLayoutRepo := TNodeLayoutSetRepo.Create(
      DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
    try
      var NodeLayoutSet: TNodeLayoutSet;
      NodeLayoutRepo.LoadActive(NodeLayoutSet);
      FVistaGantt.GanttControl.SetNodeLayoutSet(NodeLayoutSet);
    finally
      NodeLayoutRepo.Free;
    end;
  end;

  // Si la VistaGantt ya existe, refrescarla con los nuevos datos
  if Assigned(FVistaGantt) and FVistaGantt.Visible then
    FVistaGantt.Inicializar;

  ActualizarCaption;
end;

procedure TForm1.ActualizarCaption;
const
  BASE = 'FSPlanner 2026';
var
  S: string;
begin
  S := BASE;
  if Assigned(DMPlanner) and DMPlanner.IsConnected then
  begin
    if DMPlanner.CurrentEmpresaNombre <> '' then
      S := S + '  -  ' + DMPlanner.CurrentEmpresaNombre;
    if DMPlanner.CurrentProjectName <> '' then
      S := S + '  -  ' + DMPlanner.CurrentProjectName;
  end;
  Caption := S;
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
  // Punto de restauracion AUTO del dia: ANTES de marcar el cambio, si hoy aun no
  // hay snapshot AUTO de este proyecto, capturamos el estado ACTUAL (el "antes"
  // de los cambios de hoy). Idempotente: solo crea el primero del dia. Va aqui
  // (hilo principal, antes de MarkDirty) para no tocar BD desde el hilo de save.
  if Assigned(DMPlanner) and Assigned(DMPlanner.SnapshotRepo) and
     (DMPlanner.CurrentProjectId > 0) then
    try
      DMPlanner.SnapshotRepo.CrearAutoDiarioSiHaceFalta(DMPlanner.CurrentProjectId);
    except
      // El punto de restauracion no debe bloquear nunca la edicion del plan.
    end;

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

procedure TForm1.PreferenciasGantt1Click(Sender: TObject);
var
  Cfg: TGanttConfig;
  Gc: TGanttControl;
begin
  Cfg := LoadGanttConfig;
  if not TfrmGanttConfig.Execute(Cfg) then Exit;

  SaveGanttConfig(Cfg);

  // Aplicar en caliente al Gantt activo (los parametros de planificacion
  // actuan como defaults y se leen al planificar; los de visualizacion se
  // aplican ya al control).
  if Assigned(FVistaGantt) and Assigned(FVistaGantt.GanttControl) then
  begin
    Gc := FVistaGantt.GanttControl;
    Gc.HideWeekends := Cfg.HideWeekends;
    Gc.LinksVisible := Cfg.LinksVisible;
    Gc.AutoMarkersEnabled := Cfg.AutoMarkers;
    if Cfg.PxPerMinute > 0 then
      Gc.PxPerMinute := Cfg.PxPerMinute;
    Gc.Invalidate;
  end;
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

procedure TForm1.SincronizarERP1Click(Sender: TObject);
var
  F: TfrmSincronizarERP;
begin
  F := TfrmSincronizarERP.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
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
begin
  MostrarArticleDetail;
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

procedure TForm1.RegenerarGanttDemo1Click(Sender: TObject);
var
  DemoId, Actual, NumNodos, Generados: Integer;
  S: string;
begin
  if not DMPlanner.IsConnected then
  begin
    ShowMessage('No hay conexi'#243'n con la base de datos.');
    Exit;
  end;

  DemoId := DMPlanner.GetOrCreateDemoProjectId;
  if DemoId <= 0 then
  begin
    ShowMessage('No se ha podido preparar el proyecto de demostraci'#243'n.');
    Exit;
  end;

  Actual := DMPlanner.ContarNodosProyecto(DemoId);
  if Actual > 0 then
    S := IntToStr(Actual)
  else
    S := '200';

  if not InputQuery('Regenerar Gantt de demostraci'#243'n',
       'Esto BORRA los nodos actuales del Gantt demo y crea otros nuevos.'#13#10 +
       'Solo afecta al proyecto de demostraci'#243'n, nunca a tus datos reales.'#13#10 +
       #191'Cu'#225'ntos nodos ficticios quieres generar? (10-2000)', S) then
    Exit;

  NumNodos := StrToIntDef(Trim(S), 0);
  if NumNodos < 10 then NumNodos := 10;
  if NumNodos > 2000 then NumNodos := 2000;

  Generados := 0;
  ShowBusy(Self, 'Generando ' + IntToStr(NumNodos) + ' nodos de demostraci'#243'n...',
    procedure
    begin
      Generados := DMPlanner.GenerarNodosDemoEnProyecto(DemoId, NumNodos);
    end);

  if Generados <= 0 then
  begin
    ShowMessage('No se han podido generar los nodos de demostraci'#243'n. '
      + #191'Hay centros de trabajo activos?');
    Exit;
  end;

  // Si estamos en modo demo, recargar el plan (LoadActivePlan recarga tambien
  // las asignaciones de operarios; FVistaGantt.Inicializar solo no basta).
  if uDemoMode.DemoMode.Active then
    LoadActivePlan;

  ShowMessage(Format('Gantt de demostraci'#243'n regenerado: %d nodos.', [Generados]));
end;

procedure TForm1.Dashboard1Click(Sender: TObject);
begin
  OpenAction('', False,
    procedure
    begin
      MostrarDashboard;
    end);
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
      FVistaGantt.RebuildOperarioLabelCache;  // refrescar rotulos operario/nodo
      FVistaGantt.GanttControl.RebuildLayout;
      FVistaGantt.GanttControl.Invalidate;
    end;
    NotifyPlanModified(Ids);
  end;
end;

procedure TForm1.PlanificacionReglas1Click(Sender: TObject);
var
  Nodes: TArray<TNodeData>;
  Inputs: TArray<TSchedInput>;
  Centros: TArray<string>;
  PerfilesCustom: TArray<string>;
  LCentros: TList<string>;
  NodeById: TDictionary<Integer, TNode>;            // DataId -> TNode (centro+duracion+fechas)
  CentreCodeById: TDictionary<Integer, string>;     // CentreId -> CodigoCentro (auxiliar)
  Centre: TCentreTreball;
  GanttNodes: TArray<TNode>;
  GNode: TNode;
  Params: TSchedParams;
  Global: TPriorityRuleSet;
  Overrides: TArray<TCenterRuleOverride>;
  PerfilSel: Integer;
  Engine: TPriorityRuleEngine;
  EngineRef: IPlanningEngine;
  Res: TSchedResult;
  I: Integer;
  TituloRegla: string;
  MR: TModalResult;

  // Convierte los nodos (en su orden actual) a TSchedInput.
  procedure NodesToInputs(const ANodes: TArray<TNodeData>);
  var
    LInputs: TList<TSchedInput>;
    Node: TNodeData;
    Input: TSchedInput;
    GN: TNode;
    HayGN: Boolean;
    Dur: Double;
    CodCentre: string;
  begin
    LInputs := TList<TSchedInput>.Create;
    try
      for Node in ANodes do
      begin
        Input := Default(TSchedInput);
        Input.RawId := Node.DataId;
        Input.CodigoDocumento := Node.Operacion;

        // El nodo planificado (centro + duracion reales) se obtiene de NodesRepo
        // via DataId. TNodeData.DurationMin / CentresTrabajo no siempre estan
        // poblados; el TNode del repo de planificacion si.
        HayGN := NodeById.TryGetValue(Node.DataId, GN);

        // Centro: codigo resuelto desde TNode.CentreId. Fallbacks: centro
        // permitido del TNodeData, o vacio (-> no planificable).
        CodCentre := '';
        if HayGN then
          CentreCodeById.TryGetValue(GN.CentreId, CodCentre);
        if (Trim(CodCentre) = '') and (Length(Node.CentresTrabajo) > 0) then
          CodCentre := Node.CentresTrabajo[0];
        Input.CentroPreferente := CodCentre;

        // Duracion: la del nodo planificado (TNode) si la hay; si no, la del
        // TNodeData. En horas para HorasEstimadas.
        if HayGN and (GN.DurationMin > 0) then
          Dur := GN.DurationMin
        else
          Dur := Node.DurationMin;
        Input.HorasEstimadas := Dur / 60.0;

        if Node.FechaNecesaria <> 0 then
          Input.FechaCompromiso := Node.FechaNecesaria
        else
          Input.FechaCompromiso := Node.FechaEntrega;
        Input.Prioridad := Node.Prioridad;
        Input.NumeroOF := Node.NumeroOrdenFabricacion;
        Input.SerieOF := Node.SerieFabricacion;
        Input.CodigoArticulo := Node.CodigoArticulo;
        Input.DescripcionArticulo := Node.DescripcionArticulo;
        Input.FechaEntrega := Node.FechaEntrega;
        Input.FechaNecesaria := Node.FechaNecesaria;
        Input.RawItemClaveERP := Node.RawItemClaveERP;
        Input.RawItemTipoOrigen := Node.RawItemTipoOrigen;
        LInputs.Add(Input);
      end;
      Inputs := LInputs.ToArray;
    finally
      LInputs.Free;
    end;
  end;

begin
  if not Assigned(DMPlanner) or not Assigned(DMPlanner.NodeDataRepo) then
  begin
    ShowMessage('Repositorio de nodos no inicializado.');
    Exit;
  end;

  Nodes := DMPlanner.NodeDataRepo.GetAllData;
  if Length(Nodes) = 0 then
  begin
    ShowMessage('No hay nodos en el plan activo.');
    Exit;
  end;

  CentreCodeById := TDictionary<Integer, string>.Create;
  NodeById := TDictionary<Integer, TNode>.Create;
  try
    // Mapa auxiliar CentreId -> CodigoCentro y lista de TODOS los centros del
    // plan (para el grid de overrides: siempre se muestran todos, tengan o no
    // nodos planificados ahora mismo).
    LCentros := TList<string>.Create;
    try
      if Assigned(DMPlanner.CentresRepo) then
        for Centre in DMPlanner.CentresRepo.GetAll do
        begin
          CentreCodeById.AddOrSetValue(Centre.Id, Centre.CodiCentre);
          if Trim(Centre.CodiCentre) <> '' then
            LCentros.Add(Centre.CodiCentre);
        end;
      Centros := LCentros.ToArray;
    finally
      LCentros.Free;
    end;

    // Mapa DataId -> TNode (centro asignado + duracion + fechas planificadas).
    // Fuente principal: NodesRepo (persistido en BD, no depende de tener el
    // Gantt abierto). Fallback: nodos en memoria del Gantt si esta cargado.
    if Assigned(DMPlanner.NodesRepo) then
    begin
      GanttNodes := DMPlanner.NodesRepo.GetAll;
      for GNode in GanttNodes do
        NodeById.AddOrSetValue(GNode.DataId, GNode);
    end;
    if (NodeById.Count = 0) and Assigned(FVistaGantt) and
       Assigned(FVistaGantt.GanttControl) then
    begin
      GanttNodes := FVistaGantt.GanttControl.GetNodes;
      for GNode in GanttNodes do
        NodeById.AddOrSetValue(GNode.DataId, GNode);
    end;

    // 1) Inputs en orden original.
    NodesToInputs(Nodes);

    // Nombres de los perfiles custom de Reglas de Planificacion (para el combo).
    SetLength(PerfilesCustom, 0);
    if Assigned(FPlanningRuleEngine) then
    begin
      SetLength(PerfilesCustom, FPlanningRuleEngine.ProfileCount);
      for I := 0 to FPlanningRuleEngine.ProfileCount - 1 do
        PerfilesCustom[I] := FPlanningRuleEngine.GetProfile(I).Name;
    end;

    // 2) Configuracion (regla global / perfil custom + overrides + direccion).
    Params := Default(TSchedParams);
    Global := DefaultRuleSet;
    SetLength(Overrides, 0);
    PerfilSel := -1;
    MR := TfrmReglasPlanParams.Execute(Centros, PerfilesCustom,
      Params, Global, Overrides, PerfilSel);
    if (MR <> mrOk) and (MR <> mrComparar) then
      Exit;

    // 3) Ejecutar (solo si NO es comparativa; en comparativa Inputs/Params ya
    // estan listos y la ventana hara las 7 reglas tras el finally).
    if MR <> mrComparar then
    begin
      if (PerfilSel >= 0) and Assigned(FPlanningRuleEngine) then
      begin
        // Perfil custom: ordenar los NODOS con el motor de Reglas de
        // Planificacion (multi-campo + campos custom) y reconstruir los inputs
        // en ESE orden. La cola ya viene ordenada -> apilar sin reordenar.
        FPlanningRuleEngine.ActiveIndex := PerfilSel;
        FPlanningRuleEngine.SortNodes(Nodes);
        NodesToInputs(Nodes);
        Params.Order := soPreordenado;
        Res := RunAutoScheduling(Inputs, Params);
        TituloRegla := FPlanningRuleEngine.GetProfile(PerfilSel).Name + ' (perfil)';
      end
      else
      begin
        // Regla canonica: via motor de reglas (ordena por centro + desempate).
        Engine := TPriorityRuleEngine.Create;
        EngineRef := Engine;  // gestion de vida via interface
        Engine.Global := Global;
        Engine.SetOverrides(Overrides);
        Res := EngineRef.Schedule(Inputs, Params);
        TituloRegla := PriorityRuleToStr(Global.Principal);
      end;
    end;
  finally
    CentreCodeById.Free;
    NodeById.Free;
  end;

  // Modo comparativa: abrir la ventana con las 7 reglas. Inputs/Params ya estan
  // listos (los maps de centro ya se aplicaron al construir Inputs).
  if MR = mrComparar then
  begin
    TfrmReglasPlanComparativa.Execute(Inputs, Params);
    Exit;
  end;

  // Aviso util: si NINGUNA operacion se pudo planificar y todas quedaron sin
  // centro, el problema son los datos (nodos sin centro asignado), no el motor.
  if (Res.TotalPlanificados = 0) and (Length(Res.Items) > 0) then
    ShowMessage(
      'Ninguna operaci'#243'n se ha podido planificar.' + sLineBreak +
      'Comprueba que las operaciones del plan tengan centro asignado ' +
      'y duraci'#243'n. El motor solo reordena lo que ya esta planificado.');

  // 4) Preview (sin aplicar). El commit queda para una fase posterior.
  TfrmReglasPlanPreview.Execute(Res, TituloRegla);
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
