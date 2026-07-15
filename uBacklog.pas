unit uBacklog;

{
  TfrmBacklog - Pantalla de Backlog / Carga pendiente.

  - Muestra OFs, Comandas y Proyectos pendientes de planificar
    (vista FS_PL_vw_Backlog, que excluye lo que ya tiene nodo en el Plan MASTER).
  - Grid totalmente personalizable (cxGrid): reordenar/ocultar columnas,
    filtros por columna, multi-sort, column chooser.
  - Soporta campos personalizados por cliente (FS_PL_Cfg_GridColumns +
    FS_PL_Raw_*_Extra) resueltos con LEFT JOIN dinámico.
  - Layout persistido por usuario en FS_PL_Cfg_UserGridLayout.
  - Panel de filtros (izq.) y panel de impacto (der.) recalculado segun seleccion.
  - El impacto detallado (calendarios/torns) se implementara en una fase posterior;
    de momento ofrece agregados basicos (count, horas, fin estimado simple).
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.NetEncoding,
  System.Generics.Collections, System.DateUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, cxTextEdit, cxCalc, cxCalendar, cxCheckBox, cxButtonEdit,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  cxInplaceContainer, cxVGrid, cxGridStrs, dxCore,
  Data.Win.ADODB, Data.DB,
  uBacklogScheduler, dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019DarkGray, dxSkinOffice2019White,
  dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus,
  dxSkinSilver, dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008,
  dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue, Vcl.Menus, cxButtons, dxGDIPlusClasses, cxImage,
  Vcl.WinXCtrls, uBulkNodePersist;

const
  BACKLOG_GRID_ID = 'BACKLOG';

type
  TBacklogRow = record
    Origen: string;
    TipoOrigen: string;      // CHAR(3) del modelo Raw_Item: 'OF ','PED','PRJ'
    Nivel: Integer;          // nivel del leaf (1/2/3) tal como expone la vista
    RawId: Int64;            // RawItemId del leaf
    ParentRawItemId: Int64;  // padre del leaf
    GrandRawItemId: Int64;   // abuelo del leaf
    OrigenERP: string;
    ClaveERP: string;
    CodigoDocumento: string;
    NumeroDoc: Integer;
    SerieDoc: string;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    Cantidad: Double;
    UnidadMedida: string;
    CodigoCliente: string;
    NombreCliente: string;
    CodigoProyecto: string;
    NumeroOF: Integer;       // numero de la OF raiz (familia OF); 0 si no aplica
    SerieOF: string;         // serie de la OF raiz (familia OF); vacio si no aplica
    CodigoOT: string;        // codigo de la OT (Nivel 2); vacio si no aplica
    CodigoOP: string;        // codigo de la OP (Nivel 3); vacio si no aplica
    FechaCompromiso: TDateTime;
    FechaNecesaria: TDateTime;
    FechaEntrega: TDateTime;
    Prioridad: Integer;
    CentroPreferente: string;
    HorasEstimadas: Double;
    TiempoUnidadFabSecs: Double;
    EstadoERP: string;
    Orden: Integer;          // orden de la operacion dentro de la OT (secuencia)
    // Bloque OP (Nivel 3): campos de la operacion; vacios en OF/OT.
    OpTiempoPreparacion: Double;
    OpTiempoFabricacion: Double;
    OpUnidadesHora: Double;
    OpCosteHoraMaquina: Double;
    OpCosteHoraManoObra: Double;
    OpUnidadesFabricadas: Double;
    OpFechaInicioReal: TDateTime;
    OpFechaFinalReal: TDateTime;
    OpOperacionExterna: Variant;   // BIT nullable -> Variant (Null si no es OP)
    OpCodigoProveedor: string;
    OpSeccionFabrica: string;
    OpStatusPlanificado: Variant;  // BIT nullable
    OpObservaciones: string;
    OpPctParaSigOperacion: Double;
    OpPctDedicacionOperario: Double;
    Extras: TDictionary<string, Variant>;
    // Agregados de prevision (V055, FS_PL_vw_BacklogTree). Relevantes sobre todo
    // a Nivel 1/2: suma de duracion y conteo de OP descendientes pendientes.
    DuracionPrevistaMin: Double;
    NumOpsTotal: Integer;
    NumOpsPendientes: Integer;
    FechaCompromisoMin: TDateTime;
    // Solo se rellenan en el tab Planificados (via FS_PL_vw_BacklogPlanned)
    NodeId: Integer;
    NodeInicio: TDateTime;
    NodeFin: TDateTime;
    NodeCodigoCentro: string;
    NodeCentroNombre: string;
    // Agregados de progreso (V056, FS_PL_vw_BacklogPlannedTree). Relevantes a
    // Nivel 1/2 del tab Planificados: cuantas OP del documento ya estan en el
    // plan y en cuantos centros.
    NumOpsPlan: Integer;
    NumCentros: Integer;
  end;

  TCustomColumnDef = record
    ColumnKey: string;
    Caption: string;
    DataType: Char;
    SourceEntity: string;   // 'OF','PEDIDO','PROYECTO'
    FieldKey: string;       // = ColumnKey si SourceExpression es NULL
    AppliesToNivel: Integer; // 1/2/3, 0 = no especificado (cae al leaf)
  end;

  TfrmBacklog = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlFiltros: TPanel;
    lblFiltros: TLabel;
    lblFiltroOrigen: TLabel;
    lblFiltroCliente: TLabel;
    lblFiltroProyecto: TLabel;
    lblFiltroCentro: TLabel;
    lblFiltroEstado: TLabel;
    lblFiltroFechaDesde: TLabel;
    lblFiltroFechaHasta: TLabel;
    cmbOrigen: TComboBox;
    lblNivelVista: TLabel;
    cmbNivelVista: TComboBox;
    cmbPersistMethod: TComboBox;
    edtCliente: TEdit;
    edtProyecto: TEdit;
    edtCentro: TEdit;
    edtEstado: TEdit;
    dtFechaDesde: TDateTimePicker;
    dtFechaHasta: TDateTimePicker;
    chkUsaFechaDesde: TCheckBox;
    chkUsaFechaHasta: TCheckBox;
    btnLimpiarFiltros: TButton;
    tabMode: TTabControl;
    pnlImpacto: TPanel;
    pnlImpactoHeader: TPanel;
    lblImpacto: TLabel;
    vgResumen: TcxVerticalGrid;
    rowSelCount: TcxEditorRow;
    rowSelHoras: TcxEditorRow;
    rowFechaFinEst: TcxEditorRow;
    rowOFsFueraPlazo: TcxEditorRow;
    rowCentrosSat: TcxEditorRow;
    rowVentana: TcxEditorRow;
    lblCargaTitulo: TLabel;
    grdCargaCentro: TcxGrid;
    tvCargaCentro: TcxGridTableView;
    lvCargaCentro: TcxGridLevel;
    colCCCentro: TcxGridColumn;
    colCCHoras: TcxGridColumn;
    colCCCapacidad: TcxGridColumn;
    colCCPct: TcxGridColumn;
    grdBacklog: TcxGrid;
    tvBacklog: TcxGridTableView;
    lvBacklog: TcxGridLevel;
    PopupMenu1: TPopupMenu;
    RegenerarNodosDemo1: TMenuItem;
    RegenerarBacklogDemo1: TMenuItem;
    pnlSubTitulo: TPanel;
    btnDesplanificarSel: TButton;
    btnPlanificar: TButton;
    btnPlanificarExpress: TButton;
    btnSyncErp: TcxButton;
    PopupMenu2: TPopupMenu;
    Columnas1: TMenuItem;
    Configurar1: TMenuItem;
    Guardar1: TMenuItem;
    Restablecer1: TMenuItem;
    N3: TMenuItem;
    ConfigurarVencimiento1: TMenuItem;
    N4: TMenuItem;
    Vaciarylimpiartodalaplanificacin2: TMenuItem;
    imgSection: TcxImage;
    btnRecargar: TcxButton;
    lblCountRegs: TLabel;
    pnlKpiOF: TPanel;
    lblKpiOFVal: TLabel;
    lblKpiOFCap: TLabel;
    pnlKpiOT: TPanel;
    lblKpiOTVal: TLabel;
    lblKpiOTCap: TLabel;
    pnlKpiOP: TPanel;
    lblKpiOPVal: TLabel;
    lblKpiOPCap: TLabel;
    pnlKpiVenc: TPanel;
    lblKpiVencVal: TLabel;
    lblKpiVencCap: TLabel;
    pnlKpiPron: TPanel;
    lblKpiPronVal: TLabel;
    lblKpiPronCap: TLabel;
    pnlKpiSinF: TPanel;
    lblKpiSinFVal: TLabel;
    lblKpiSinFCap: TLabel;
    Label28: TLabel;
    cxButton9: TcxButton;
    chkVerImpacto: TcxCheckBox;
    chkVerFiltros: TcxCheckBox;
    procedure btnSyncErpClick(Sender: TObject);
    procedure RegenerarNodosDemo1Click(Sender: TObject);
    procedure RegenerarBacklogDemo1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnPlanificarClick(Sender: TObject);
    procedure btnPlanificarExpressClick(Sender: TObject);
    procedure btnLimpiarFiltrosClick(Sender: TObject);
    procedure FiltroChanged(Sender: TObject);
    procedure tvBacklogSelectionChanged(Sender: TcxCustomGridTableView);
    procedure tvBacklogCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
      AShift: TShiftState; var AHandled: Boolean);
    procedure tvBacklogCustomEditValueChanged(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
    procedure tvCargaCentroCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure tabModeChange(Sender: TObject);
    procedure cmbNivelVistaChange(Sender: TObject);
    procedure btnDesplanificarSelClick(Sender: TObject);
    procedure btnRecargarClick(Sender: TObject);
    procedure Configurar1Click(Sender: TObject);
    procedure Restablecer1Click(Sender: TObject);
    procedure Guardar1Click(Sender: TObject);
    procedure Vaciarylimpiartodalaplanificacin2Click(Sender: TObject);
    procedure chkVerImpactoPropertiesChange(Sender: TObject);
    procedure chkVerFiltrosPropertiesChange(Sender: TObject);
    procedure ConfigurarVencimiento1Click(Sender: TObject);
  private
    FRows: TList<TBacklogRow>;
    FFilteredIndices: TArray<Integer>;   // FRows index per cada fila del grid
    FStylePlanificado: TcxStyle;         // verde claro: fila planificada con holgura
    FStyleTarde: TcxStyle;               // rojo: NodeFin > FechaEntrega (llega tarde)
    FStyleRiesgo: TcxStyle;              // naranja: planificada pero ajustada al plazo
    FDiasVencimiento: Integer;           // umbral naranja (dias de margen); pref usuario
    // Cache del recordset (desconectado) por clave (tab,nivel): el toggle
    // Pendientes/Planificados y el cambio de nivel son acciones muy comunes y la
    // query es el 89% del tiempo (~1s). Con cache, el toggle solo revuelca+pinta
    // desde memoria (~100ms). Se invalida al planificar/desplanificar/filtrar/
    // refrescar. Clave = 'tab|nivel' (p.ej. '1|3').
    FRecordsetCache: TObjectDictionary<string, TCustomADODataSet>;


    FCustomCols: TArray<TCustomColumnDef>;
    FBaseColumns: TArray<TcxGridColumn>;
    FCustomColumns: TArray<TcxGridColumn>;
    FColKeyByTag: TDictionary<Integer, string>;
    FLoading: Boolean;
    FFirstShow: Boolean;
    FNivelVista: Integer;   // 1=OF/PED/PRJ, 2=OT/LINEA/TAREA, 3=OP. Tab Pendientes.

    function CacheKey: string;
    function TryLoadFromCache(out ADataSet: TCustomADODataSet): Boolean;
    procedure StoreInCache(ADataSet: TCustomADODataSet);
    procedure InvalidateDataCache;

    // Colorea de verde claro las filas ya planificadas (NodeId>0). La seleccion
    // amarilla se configura via tvBacklog.Styles.Selection (no por fila).
    procedure tvBacklogGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);

    procedure VerOFActual(ARecordIndex: Integer = -1);
    procedure VerNodeManual(ANodeId: Integer);
    procedure BuildBaseColumns;
    procedure LoadCustomColumnDefs;
    procedure BuildCustomColumns;
    procedure LoadData;
    procedure ApplyRowsToGrid;
    procedure LoadKpis;
    function BuildSQL: string;
    function ResolveExtraRawItemId(const Row: TBacklogRow;
      const ColDef: TCustomColumnDef): Int64;
    procedure SaveCustomFieldValue(ARawItemId: Int64;
      const FieldKey: string; ADataType: Char; const Value: Variant);
    function EncodeFieldValue(ADataType: Char; const V: Variant): string;
    function DecodeFieldValue(ADataType: Char; const S: string): Variant;
    function PassesFilter(const Row: TBacklogRow): Boolean;
    procedure UpdateImpacto;
    procedure UpdateCountLabel;
    procedure ClearRows;
    procedure OnColVerButtonClick(Sender: TObject; AButtonIndex: Integer);
    function GetRowFromGridIndex(AGridIdx: Integer): Integer;

    procedure LoadUserLayout;
    procedure SaveUserLayout;
    procedure EnsureNewColumnsVisible(const AKeys: array of string);
    procedure ResetLayout;

    // Nucleo de planificacion compartido por el boton normal y el Express.
    // AExpress=True abre el wizard directo al Resumen con la ultima config.
    procedure PlanificarSeleccion(AExpress: Boolean);
    function CollectSelectedInputs: TArray<TSchedInput>;
    function BuildInputFromRow(const Row: TBacklogRow): TSchedInput;
    function ExplodeToOpInputs(ARawId: Int64; ANivel: Integer): TArray<TSchedInput>;
    // Explosion en LOTE: todas las OP descendientes de un conjunto de ancestros
    // del mismo nivel, en UNA sola consulta (IN). Evita N round-trips.
    function ExplodeManyToOpInputs(const ARawIds: TArray<Int64>;
      ANivel: Integer): TArray<TSchedInput>;
    procedure CommitScheduling(const AResult: TSchedResult;
      out ACreados: TArray<TPair<Integer, Integer>>);
    // Aplica la agrupacion elegida en el wizard sobre los nodos recien creados,
    // reutilizando el motor de Lotes (V057). ACreados = (NodeId, CenterId).
    procedure AplicarAgrupacion(const AParams: TSchedParams;
      const ACreados: TArray<TPair<Integer, Integer>>);

    procedure ApplyImpactoVisible(AVisible: Boolean);
    procedure ApplyFiltrosVisible(AVisible: Boolean);
    procedure ApplyTabMode;
    function IsPlanningTab: Boolean;
    function CollectSelectedNodeIds: TArray<Integer>;
    function NodeIdsForAncestor(ARawId: Int64; ANivel: Integer): TArray<Integer>;
    procedure DoDesplanificar(const ANodeIds: TArray<Integer>);

    function UserLogin: string;
    function EmpresaCode: SmallInt;
    function QStr(const S: string): string;
  end;

procedure ShowBacklog;

implementation

{$R *.dfm}

uses
  uDMPlanner, uLogin, uGanttTypes, uCentreCalendar, uBacklogCustomCols,
  uBusyDialog, uSetupRules,
  uBacklogSchedParams, uBacklogSchedWizard, uBacklogSchedPreview, uUserPrefs,
  uGenerarNodosDemo,
  uDemoBacklog, uBacklogRegenParams, uAppConfig, uPedidoDetalle,
  uFormulaArticuloViewer, Main,
  uErpReader, uErpReaderFactory, uSyncBacklogPreview, uOFViewer, uPlanLog,
  uPlanningRules, uNodeInspector;

const
  BACKLOG_MOD = 'BACKLOG';

// Helpers de lectura tolerante de campos de la vista (FindField por robustez
// ante vistas antiguas que aun no tengan la columna).
function FieldFloat(Q: TDataSet; const AName: string): Double;
begin
  if (Q.FindField(AName) <> nil) and not Q.FieldByName(AName).IsNull then
    Result := Q.FieldByName(AName).AsFloat
  else
    Result := 0;
end;

function FieldDate(Q: TDataSet; const AName: string): TDateTime;
begin
  if (Q.FindField(AName) <> nil) and not Q.FieldByName(AName).IsNull then
    Result := Q.FieldByName(AName).AsDateTime
  else
    Result := 0;
end;

function FieldStr(Q: TDataSet; const AName: string): string;
begin
  if Q.FindField(AName) <> nil then
    Result := Q.FieldByName(AName).AsString
  else
    Result := '';
end;

// BIT nullable: Null si la columna no existe o es NULL (filas no-OP). El
// provider puede exponer BIT como Boolean o como entero segun driver; usamos
// AsVariant y normalizamos, evitando AsInteger (que lanza "Cannot access field
// as type Integer" cuando el campo es booleano).
function FieldBoolVar(Q: TDataSet; const AName: string): Variant;
var
  F: TField;
begin
  F := Q.FindField(AName);
  if (F = nil) or F.IsNull then
    Exit(Null);
  if F.DataType = ftBoolean then
    Result := F.AsBoolean
  else
    Result := F.AsInteger <> 0;
end;

// Para volcado al grid: muestra Null en vez de 0 (evita ensuciar con ceros las
// filas que no son operacion o que no tienen ese valor).
function FloatOrNull(V: Double): Variant;
begin
  if V = 0 then Result := Null else Result := V;
end;

procedure ShowBacklog;
begin
  // Backlog es ahora una vista embedded del Form1 (no modal, hermana de
  // Dashboard / Gantt / FiniteCapacity). Delegamos siempre al Main para
  // que gestione la instancia unica y el cambio de vista activa.
  if Assigned(Main.Form1) then
    Main.Form1.MostrarBacklog;
end;

{ TfrmBacklog }

function TfrmBacklog.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function TfrmBacklog.UserLogin: string;
begin
  Result := CurrentSession.Login;
  if Result = '' then
    Result := '(anon)';
end;

procedure TfrmBacklog.Vaciarylimpiartodalaplanificacin2Click(Sender: TObject);
var
  Cmd: TADOCommand;
  PID: Integer;
begin
  PID := DMPlanner.CurrentProjectId;
  if PID <= 0 then
  begin
    ShowMessage('No hay proyecto activo.');
    Exit;
  end;

  if MessageDlg(
       'Se borrara TODO lo planificado del proyecto activo (nodos, dependencias, '
       + 'marcadores y snapshots). El Backlog y los centros no se tocan.' + sLineBreak +
       sLineBreak + 'Seguro que quieres vaciar el plan?',
       mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText := 'EXEC FS_PL_sp_ClearProjectPlan :CodigoEmpresa, :ProjectId';
    Cmd.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
    Cmd.Parameters.ParamByName('ProjectId').Value := PID;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  InvalidateDataCache;   // se vacio el plan: datos de ambos tabs cambian
  LoadData;
  ShowMessage('Plan vaciado correctamente.');

end;

function TfrmBacklog.EmpresaCode: SmallInt;
begin
  Result := DMPlanner.CodigoEmpresa;
end;

procedure TfrmBacklog.tvBacklogGetContentStyle(Sender: TcxCustomGridTableView;
  ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
  var AStyle: TcxStyle);
var
  RecIdx, RowIdx: Integer;
  Row: TBacklogRow;
  FEntrega, FRef: TDateTime;
  Planificada: Boolean;
begin
  if ARecord = nil then Exit;
  RecIdx := ARecord.RecordIndex;
  if (RecIdx < 0) or (RecIdx > High(FFilteredIndices)) then Exit;
  RowIdx := FFilteredIndices[RecIdx];
  if (RowIdx < 0) or (RowIdx >= FRows.Count) then Exit;
  Row := FRows[RowIdx];

  // Semaforo de cumplimiento (rojo > naranja > verde). La fecha objetivo es
  // FechaEntrega (cae a FechaCompromiso en el volcado si no habia entrega).
  //  - Planificados: se compara con NodeFin (fin de la planificacion).
  //  - Pendientes:   se compara con HOY (aun no hay fin planificado).
  FEntrega := Row.FechaEntrega;
  if FEntrega <= 0 then Exit;   // sin fecha objetivo no hay semaforo

  if IsPlanningTab then
    FRef := Row.NodeFin           // fin planificado (0 si aun no hay, p.ej. Nivel 1/2 sin rango)
  else
    FRef := Date;                 // pendiente: referencia = hoy

  if FRef > 0 then
  begin
    if FRef > FEntrega then
    begin
      AStyle := FStyleTarde;      // ROJO: se termina/vence despues del plazo
      Exit;
    end
    else if FEntrega - FRef <= FDiasVencimiento then
    begin
      AStyle := FStyleRiesgo;     // NARANJA: dentro del margen de riesgo
      Exit;
    end;
  end;

  // Sin retraso ni riesgo: en Planificados, verde si la fila esta planificada.
  Planificada := (Row.NodeId > 0) or (Row.NumOpsPlan > 0);
  if IsPlanningTab and Planificada then
    AStyle := FStylePlanificado;  // VERDE: planificada con holgura
end;

procedure TfrmBacklog.FormCreate(Sender: TObject);
begin
  FRows := TList<TBacklogRow>.Create;
  FColKeyByTag := TDictionary<Integer, string>.Create;
  // Cache de recordsets por (tab,nivel). doOwnsValues: libera cada TADODataSet al
  // reemplazar/vaciar/destruir. Ver LoadData/InvalidateDataCache.
  FRecordsetCache := TObjectDictionary<string, TCustomADODataSet>.Create([doOwnsValues]);

  // Colores de fila personalizados. IMPRESCINDIBLE NativeStyle=False: con el skin
  // nativo activo, DevExpress ignora el Color de los estilos y las filas salen
  // blancas (mismo patron que el grid de uSincronizarERP, que si funciona).
  tvBacklog.LookAndFeel.NativeStyle := False;
  // Semaforo de cumplimiento por fila (tab Planificados), aplicado via
  // OnGetContentStyle. Prioridad: rojo (tarde) > naranja (ajustado) > verde
  // (holgura). Colores BGR.
  FStylePlanificado := TcxStyle.Create(Self);
  FStylePlanificado.Color := $00D8F5D8;      // verde claro = planificada con holgura
  FStylePlanificado.TextColor := clWindowText;
  FStyleTarde := TcxStyle.Create(Self);
  FStyleTarde.Color := $00CACAFF;            // rojo claro = NodeFin > FechaEntrega
  FStyleTarde.TextColor := clWindowText;
  FStyleRiesgo := TcxStyle.Create(Self);
  FStyleRiesgo.Color := $0080D0FF;           // naranja = ajustada al plazo (riesgo)
  FStyleRiesgo.TextColor := clWindowText;
  FDiasVencimiento := 7;                      // se refresca en cada LoadData
  tvBacklog.Styles.OnGetContentStyle := tvBacklogGetContentStyle;
  // Filas seleccionadas en amarillo (una sola vez; sirve para ambos tabs).
  if tvBacklog.Styles.Selection = nil then
    tvBacklog.Styles.Selection := TcxStyle.Create(Self);
  tvBacklog.Styles.Selection.Color := $0000F5FF;   // amarillo (BGR)
  tvBacklog.Styles.Selection.TextColor := clBlack;
  // Seleccion multi-fila via checkboxes: uno por fila + uno en la cabecera que
  // marca/desmarca TODO (persistente). Sustituye los botones Seleccionar/
  // Deseleccionar todo. El resto del codigo usa Controller.SelectedRows, que
  // funciona igual con seleccion por checkbox.
  tvBacklog.OptionsSelection.MultiSelect := True;
  tvBacklog.OptionsSelection.CheckBoxVisibility := [cbvDataRow, cbvColumnHeader];
  FLoading := True;
  try
    dtFechaDesde.Date := Date;
    dtFechaHasta.Date := IncMonth(Date, 3);
    cmbOrigen.ItemIndex := 0;

    tabMode.TabIndex := uUserPrefs.GetPrefInt(BACKLOG_MOD, 'TabIndex', 0);
    btnPlanificar.Visible := not IsPlanningTab;
    btnDesplanificarSel.Visible := IsPlanningTab;

    // Nivel de vista (1/2/3). Por defecto 3 (OP), comportamiento previo.
    FNivelVista := uUserPrefs.GetPrefInt(BACKLOG_MOD, 'NivelVista', 3);
    if (FNivelVista < 1) or (FNivelVista > 3) then FNivelVista := 3;
    cmbNivelVista.ItemIndex := FNivelVista - 1;
    // El nivel de vista aplica a ambos tabs (Pendientes y Planificados).
    cmbNivelVista.Visible := True;
    lblNivelVista.Visible := True;

    Columnas1.Enabled := uLogin.IsAdmin;

    // Traduccion al castellano de los textos por defecto del cxGrid (afectan a
    // todos los grids de la app; basta hacerlo una vez).
    cxSetResourceString(@scxGridGroupByBoxCaption,
      'Arrastre aqu'#237' una columna para agrupar por ella');
    cxSetResourceString(@scxGridNoDataInfoText, '<Sin datos que mostrar>');

    BuildBaseColumns;
    LoadCustomColumnDefs;
    BuildCustomColumns;
    LoadUserLayout;
    ApplyImpactoVisible(uUserPrefs.GetPrefBool(BACKLOG_MOD, 'ImpactoVisible', True));
    ApplyFiltrosVisible(uUserPrefs.GetPrefBool(BACKLOG_MOD, 'FiltrosVisible', True));
  finally
    FLoading := False;
  end;
  FFirstShow := True;
end;

procedure TfrmBacklog.FormShow(Sender: TObject);
begin
  if not FFirstShow then Exit;
  FFirstShow := False;

  // LoadData ya muestra su propio dialogo de carga (con spinner animado por
  // thread); no hace falta envolverlo aqui.
  LoadData;
end;

procedure TfrmBacklog.FormDestroy(Sender: TObject);
begin
  ClearRows;
  FRows.Free;
  FColKeyByTag.Free;
  FRecordsetCache.Free;   // doOwnsValues libera los recordsets cacheados
end;

procedure TfrmBacklog.ClearRows;
var
  I: Integer;
begin
  for I := 0 to FRows.Count - 1 do
    if FRows[I].Extras <> nil then
      FRows[I].Extras.Free;
  FRows.Clear;
end;

procedure TfrmBacklog.btnLimpiarFiltrosClick(Sender: TObject);
begin
  FLoading := True;
  try
    cmbOrigen.ItemIndex := 0;
    edtCliente.Text := '';
    edtProyecto.Text := '';
    edtCentro.Text := '';
    edtEstado.Text := '';
    chkUsaFechaDesde.Checked := False;
    chkUsaFechaHasta.Checked := False;
  finally
    FLoading := False;
  end;
  ApplyRowsToGrid;
end;

procedure TfrmBacklog.FiltroChanged(Sender: TObject);
begin
  if FLoading then Exit;
  ApplyRowsToGrid;
end;

// Construye la lista de atributos de un trabajo para el motor de tiempo de
// cambio (uSetupRules): builtin relevantes + todos los campos personalizados
// (Extras). Generico: no hardcodea 'Color'/'Substrato', expone lo que haya y el
// motor usa solo los atributos que sus reglas referencien.
function BuildSetupAttrs(const Row: TBacklogRow): TSetupAttrList;
var
  L: TList<TSetupPair>;
  P: TSetupPair;
  Pair: TPair<string, Variant>;
begin
  L := TList<TSetupPair>.Create;
  try
    // Builtin util para secuenciacion.
    P.Name := 'CodigoArticulo'; P.Value := Row.CodigoArticulo; L.Add(P);
    P.Name := 'DescripcionArticulo'; P.Value := Row.DescripcionArticulo; L.Add(P);
    P.Name := 'CodigoCliente'; P.Value := Row.CodigoCliente; L.Add(P);
    // Campos personalizados del backlog (Substrato, Color, AnchoBobina, ...).
    if Row.Extras <> nil then
      for Pair in Row.Extras do
      begin
        P.Name := Pair.Key;
        P.Value := VarToStr(Pair.Value);
        L.Add(P);
      end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

// Mapea una fila del backlog (cualquier nivel) a un TSchedInput. Para filas de
// OP (Nivel 3) el input es planificable directamente. Para OF/OT (Nivel 1/2) el
// input solo sirve de portador; quien planifica debe explosionarlo a OPs antes.
function TfrmBacklog.BuildInputFromRow(const Row: TBacklogRow): TSchedInput;
begin
  Result := Default(TSchedInput);
  Result.RawId := Row.RawId;
  Result.Origen := Row.Origen;
  Result.CodigoDocumento := Row.CodigoDocumento;
  Result.CentroPreferente := Row.CentroPreferente;
  Result.HorasEstimadas := Row.HorasEstimadas;
  Result.FechaCompromiso := Row.FechaCompromiso;
  Result.Prioridad := Row.Prioridad;

  Result.NumeroOF := 0;
  Result.SerieOF := '';
  Result.NumeroPedido := 0;
  Result.SeriePedido := '';
  // El check correcte es per familia ERP (TipoOrigen), no per nivell del leaf
  // (Origen). Per a una operacio Nivel=3, Origen val 'OP' i la familia pot
  // ser 'OF ', 'PED' o 'PRJ'.
  if Trim(Row.TipoOrigen) = 'OF' then
  begin
    // IMPORTANTE: usar NumeroOF/SerieOF (que la vista calcula con CASE por nivel,
    // tomando el valor de la OF raiz/abuelo), NO NumeroDoc/SerieDoc, que vienen
    // de COALESCE y devuelven 0 porque OT/OP tienen NumeroDoc=0 (no NULL).
    Result.NumeroOF := Row.NumeroOF;
    Result.SerieOF := Row.SerieOF;
  end
  else if Trim(Row.TipoOrigen) = 'PED' then
  begin
    Result.NumeroPedido := Row.NumeroDoc;
    Result.SeriePedido := Row.SerieDoc;
  end;

  Result.CodigoCliente := Row.CodigoCliente;
  Result.CodigoArticulo := Row.CodigoArticulo;
  Result.DescripcionArticulo := Row.DescripcionArticulo;
  Result.UnidadesAFabricar := Row.Cantidad;
  // NumeroTrabajo = codigo de la OT (heredado por la OP). Antes CodigoProyecto,
  // que queda vacio si el cliente no usa proyectos.
  Result.NumeroTrabajo := Row.CodigoOT;
  if Result.NumeroTrabajo = '' then
    Result.NumeroTrabajo := Row.CodigoProyecto;
  Result.FechaEntrega := Row.FechaCompromiso;
  Result.FechaNecesaria := Row.FechaNecesaria;
  Result.TiempoUnidadFabSecs := Row.TiempoUnidadFabSecs;

  // Tiempos reales de la operacion para CalcDuracionOpMin (cascada V054).
  Result.OpTiempoFabricacion := Row.OpTiempoFabricacion;
  Result.OpUnidadesHora := Row.OpUnidadesHora;
  Result.OpTiempoPreparacion := Row.OpTiempoPreparacion;
  Result.Cantidad := Row.Cantidad;

  // Link al modelo unificado Raw_Item (V016). La vista ya expone TipoOrigen.
  Result.RawItemClaveERP := Row.ClaveERP;
  Result.RawItemTipoOrigen := Row.TipoOrigen;

  // Atributos para el tiempo de cambio secuencia-dependiente (uSetupRules):
  // builtin relevantes + todos los campos personalizados del backlog (Extras).
  // Asi cualquier regla de setup que referencie 'Color', 'Substrato',
  // 'AnchoBobina'... (custom) o 'CodigoArticulo' (builtin) encuentra su valor.
  Result.SetupAttrs := BuildSetupAttrs(Row);

  PlanLog.Linea('BUILD_FROM_ROW: Tipo=[%s] Nivel=%d | Row.NumeroOF=%d ' +
    'Row.SerieOF=%s Row.NumeroDoc=%d Row.CodigoOT=%s Row.CodigoProyecto=%s | ' +
    'Row.FCompromiso=%s Row.FNecesaria=%s -> NumOF=%d SerieOF=%s NumTrab=%s ' +
    'FEntrega=%s FNecesaria=%s',
    [Row.TipoOrigen, Row.Nivel, Row.NumeroOF, Row.SerieOF, Row.NumeroDoc,
     Row.CodigoOT, Row.CodigoProyecto,
     DateToStr(Row.FechaCompromiso), DateToStr(Row.FechaNecesaria),
     Result.NumeroOF, Result.SerieOF, Result.NumeroTrabajo,
     DateToStr(Result.FechaEntrega), DateToStr(Result.FechaNecesaria)]);
end;

// Explosiona un nodo Nivel 1 (OF/PED/PRJ) o Nivel 2 (OT/LINEA/TAREA) a la lista
// de sus OP descendientes PENDIENTES (sin node), ordenadas por OT y luego por el
// Orden de la operacion dentro de la OT (la ruta de fabricacion). Cada OP se
// devuelve como un TSchedInput planificable. Reusa FS_PL_vw_Backlog (que ya solo
// expone leafs sin node y propaga los campos heredados del padre/abuelo).
function TfrmBacklog.ExplodeToOpInputs(ARawId: Int64;
  ANivel: Integer): TArray<TSchedInput>;
begin
  // Compatibilidad: explosion de un unico ancestro. Delega en la version en
  // lote para no duplicar la logica de mapeo.
  Result := ExplodeManyToOpInputs([ARawId], ANivel);
end;

function TfrmBacklog.ExplodeManyToOpInputs(const ARawIds: TArray<Int64>;
  ANivel: Integer): TArray<TSchedInput>;
var
  Q: TADOQuery;
  L: TList<TSchedInput>;
  Inp: TSchedInput;
  AncestorJoin, IdList: string;
  K: Integer;
begin
  L := TList<TSchedInput>.Create;
  Q := TADOQuery.Create(nil);
  try
    if Length(ARawIds) = 0 then Exit(nil);

    // Lista de ancestros para IN(...). UNA sola consulta para TODOS los
    // seleccionados del mismo nivel (antes: 1 consulta por OF -> N round-trips,
    // que congelaba la UI antes de abrir el wizard con selecciones grandes).
    IdList := '';
    for K := 0 to High(ARawIds) do
    begin
      if IdList <> '' then IdList := IdList + ',';
      IdList := IdList + IntToStr(ARawIds[K]);
    end;

    // Filtro de ancestro segun el nivel del nodo seleccionado:
    //   Nivel 1 -> la OP cuelga de una OT cuyo padre esta en la lista (abuelo).
    //   Nivel 2 -> la OP cuelga directamente de un ancestro de la lista (padre).
    if ANivel <= 1 then
      AncestorJoin :=
        ' JOIN FS_PL_Raw_Item op ON op.RawItemId = b.RawId' +
        '   AND op.CodigoEmpresa = b.CodigoEmpresa' +
        ' JOIN FS_PL_Raw_Item ot ON ot.RawItemId = op.ParentRawItemId' +
        ' WHERE b.CodigoEmpresa = ' + IntToStr(EmpresaCode) +
        '   AND b.Nivel = 3 AND ot.ParentRawItemId IN (' + IdList + ')'
    else
      AncestorJoin :=
        ' JOIN FS_PL_Raw_Item op ON op.RawItemId = b.RawId' +
        '   AND op.CodigoEmpresa = b.CodigoEmpresa' +
        ' WHERE b.CodigoEmpresa = ' + IntToStr(EmpresaCode) +
        '   AND b.Nivel = 3 AND op.ParentRawItemId IN (' + IdList + ')';

    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT b.* FROM FS_PL_vw_Backlog b' + AncestorJoin +
      ' ORDER BY op.ParentRawItemId, b.Orden, b.RawId';
    Q.Open;
    while not Q.Eof do
    begin
      Inp := Default(TSchedInput);
      Inp.RawId := Q.FieldByName('RawId').AsLargeInt;
      Inp.Origen := Q.FieldByName('Origen').AsString;
      Inp.CodigoDocumento := Q.FieldByName('CodigoDocumento').AsString;
      Inp.CentroPreferente := Q.FieldByName('CentroPreferente').AsString;
      Inp.HorasEstimadas := Q.FieldByName('HorasEstimadas').AsFloat;
      if not Q.FieldByName('FechaCompromiso').IsNull then
        Inp.FechaCompromiso := Q.FieldByName('FechaCompromiso').AsDateTime;
      Inp.Prioridad := Q.FieldByName('Prioridad').AsInteger;

      if Trim(Q.FieldByName('TipoOrigen').AsString) = 'OF' then
      begin
        // NumeroOF/SerieOF: la vista ya los expone explicitos para la OP (heredados
        // del abuelo OF). Usarlos directamente es mas fiable que NumeroDoc.
        Inp.NumeroOF := Q.FieldByName('NumeroOF').AsInteger;
        Inp.SerieOF := Q.FieldByName('SerieOF').AsString;
      end
      else if Trim(Q.FieldByName('TipoOrigen').AsString) = 'PED' then
      begin
        Inp.NumeroPedido := Q.FieldByName('NumeroDoc').AsInteger;
        Inp.SeriePedido := Q.FieldByName('SerieDoc').AsString;
      end;

      Inp.CodigoCliente := Q.FieldByName('CodigoCliente').AsString;
      Inp.CodigoArticulo := Q.FieldByName('CodigoArticulo').AsString;
      Inp.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      Inp.UnidadesAFabricar := Q.FieldByName('Cantidad').AsFloat;
      // NumeroTrabajo = codigo de la OT (la ruta/orden de trabajo), heredado por
      // la OP. Antes se usaba CodigoProyecto, que queda vacio si no hay proyectos.
      Inp.NumeroTrabajo := Q.FieldByName('CodigoOT').AsString;
      if Inp.NumeroTrabajo = '' then
        Inp.NumeroTrabajo := Q.FieldByName('CodigoProyecto').AsString;
      if not Q.FieldByName('FechaCompromiso').IsNull then
        Inp.FechaEntrega := Q.FieldByName('FechaCompromiso').AsDateTime;
      if not Q.FieldByName('FechaNecesaria').IsNull then
        Inp.FechaNecesaria := Q.FieldByName('FechaNecesaria').AsDateTime;
      if Q.FindField('TiempoUnidadFabSecs') <> nil then
        Inp.TiempoUnidadFabSecs := Q.FieldByName('TiempoUnidadFabSecs').AsFloat;

      // Tiempos reales (cascada V054).
      Inp.OpTiempoFabricacion := Q.FieldByName('OpTiempoFabricacion').AsFloat;
      Inp.OpUnidadesHora := Q.FieldByName('OpUnidadesHora').AsFloat;
      Inp.OpTiempoPreparacion := Q.FieldByName('OpTiempoPreparacion').AsFloat;
      Inp.Cantidad := Q.FieldByName('Cantidad').AsFloat;

      Inp.RawItemClaveERP := Q.FieldByName('ClaveERP').AsString;
      Inp.RawItemTipoOrigen := Q.FieldByName('TipoOrigen').AsString;

      L.Add(Inp);
      Q.Next;
    end;
    Result := L.ToArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

function TfrmBacklog.CollectSelectedInputs: TArray<TSchedInput>;
var
  I, RecIdx, RowIdx: Integer;
  Row: TBacklogRow;
  L: TList<TSchedInput>;
  Exploded: TArray<TSchedInput>;
  J: Integer;
  AncN1, AncN2: TList<Int64>;   // ancestros a explosionar, agrupados por nivel
begin
  L := TList<TSchedInput>.Create;
  AncN1 := TList<Int64>.Create;
  AncN2 := TList<Int64>.Create;
  try
    // 1er barrido: separar OP directas (Nivel 3) de los ancestros a explosionar
    // (Nivel 1/2). Los ancestros se acumulan para explosionarlos en UNA consulta
    // por nivel (antes: 1 consulta por fila -> N round-trips = pantalla congelada
    // con selecciones grandes, p.ej. 312 OF).
    for I := 0 to tvBacklog.Controller.SelectedRowCount - 1 do
    begin
      RecIdx := tvBacklog.Controller.SelectedRows[I].RecordIndex;
      if (RecIdx < 0) or (RecIdx > High(FFilteredIndices)) then Continue;
      RowIdx := FFilteredIndices[RecIdx];
      if (RowIdx < 0) or (RowIdx >= FRows.Count) then Continue;

      Row := FRows[RowIdx];

      if Row.Nivel <= 1 then
        AncN1.Add(Row.RawId)          // Nivel 1 (OF / Pedido / Proyecto)
      else if Row.Nivel = 2 then
        AncN2.Add(Row.RawId)          // Nivel 2 (OT / Linea / Tarea)
      else
        // Nivel 3 (OP): planificable directamente, sin consulta.
        L.Add(BuildInputFromRow(Row));
    end;

    // 2o: explosion en LOTE (1 consulta por nivel con los ancestros via IN).
    if AncN1.Count > 0 then
    begin
      Exploded := ExplodeManyToOpInputs(AncN1.ToArray, 1);
      for J := 0 to High(Exploded) do
        L.Add(Exploded[J]);
    end;
    if AncN2.Count > 0 then
    begin
      Exploded := ExplodeManyToOpInputs(AncN2.ToArray, 2);
      for J := 0 to High(Exploded) do
        L.Add(Exploded[J]);
    end;

    Result := L.ToArray;
  finally
    AncN1.Free;
    AncN2.Free;
    L.Free;
  end;
end;

procedure TfrmBacklog.CommitScheduling(const AResult: TSchedResult;
  out ACreados: TArray<TPair<Integer, Integer>>);
var
  I: Integer;
  Item: TSchedOutput;
  NumCreats: Integer;
  Creados: TList<TPair<Integer, Integer>>;
  Rows: TArray<TBulkNodeRow>;
  Row: TBulkNodeRow;
  MetodoPref, MetodoUsado: TBulkNodeMethod;
  FechaObjetivo: TFunc<TSchedInput, TDateTime>;
begin
  NumCreats := 0;
  Creados := TList<TPair<Integer, Integer>>.Create;
  try

  // Fecha objetivo del nodo (entrega/necesaria) = FechaCompromiso del backlog
  // (la fecha objetivo de la OF). Si no hay compromiso, caemos a los campos
  // especificos del input como respaldo. Devuelve 0 si no hay ninguna (=> NULL).
  FechaObjetivo :=
    function(AInput: TSchedInput): TDateTime
    begin
      if AInput.FechaCompromiso > 0 then Result := AInput.FechaCompromiso
      else if AInput.FechaEntrega > 0 then Result := AInput.FechaEntrega
      else Result := 0;
    end;

  // 1) Mapear los items PLANIFICABLES a filas de persistencia masiva. El motor
  //    BulkInsertNodes asigna los NodeId y crea Node + NodeData en lote.
  SetLength(Rows, 0);
  for I := 0 to High(AResult.Items) do
  begin
    Item := AResult.Items[I];
    // Solo planificamos los que tienen fechas y centro valido
    if (Item.Status = ssSinCentro) or (Item.Status = ssSinCalendario) then
      Continue;
    if (Item.FechaInicio = 0) or (Item.FechaFin = 0) then Continue;
    if Item.CenterId <= 0 then Continue;

    SetLength(Rows, Length(Rows) + 1);
    Row := Default(TBulkNodeRow);
    Row.CenterId := Item.CenterId;
    Row.FechaInicio := Item.FechaInicio;
    Row.FechaFin := Item.FechaFin;
    Row.DuracionMin := Item.DuracionMin;
    Row.Caption := Item.Input.CodigoDocumento;
    Row.Operacion := Item.Input.CodigoDocumento;
    Row.NumeroOF := Item.Input.NumeroOF;
    Row.SerieOF := Item.Input.SerieOF;
    Row.NumeroPedido := Item.Input.NumeroPedido;
    Row.SeriePedido := Item.Input.SeriePedido;
    Row.NumeroTrabajo := Item.Input.NumeroTrabajo;
    Row.FechaEntrega := FechaObjetivo(Item.Input);
    Row.FechaNecesaria := FechaObjetivo(Item.Input);
    Row.CodigoCliente := Item.Input.CodigoCliente;
    Row.CodigoArticulo := Item.Input.CodigoArticulo;
    Row.DescripcionArticulo := Item.Input.DescripcionArticulo;
    Row.UnidadesAFabricar := Item.Input.UnidadesAFabricar;
    Row.TiempoUnidadFabSecs := Item.Input.TiempoUnidadFabSecs;
    Row.Prioridad := Item.Input.Prioridad;
    Row.RawItemClaveERP := Item.Input.RawItemClaveERP;
    Row.RawItemTipoOrigen := Item.Input.RawItemTipoOrigen;
    Rows[High(Rows)] := Row;
  end;

  // Metodo de persistencia. El combo cmbPersistMethod esta OCULTO (Visible=False):
  // sirvio para la comparativa M1/M4/M5 (M5 ~3x sobre M4, validado). En produccion
  // va siempre por M5 (ItemIndex=0), con fallback automatico M5->M4->M1 dentro de
  // BulkInsertNodes. Para volver a diagnosticar, poner el combo Visible=True.
  case cmbPersistMethod.ItemIndex of
    1: MetodoPref := bmBulkADO;
    2: MetodoPref := bmPerRow;
  else MetodoPref := bmBulkFile;
  end;

  DMPlanner.ADOConnection.BeginTrans;
  try
    if Length(Rows) > 0 then
    begin
      // Persistencia masiva (Node + NodeData). Asigna Rows[i].NodeId.
      MetodoUsado := BulkInsertNodes(DMPlanner.ADOConnection,
        DMPlanner.CodigoEmpresa, DMPlanner.CurrentProjectId, Rows, MetodoPref);

      // Resumen (sin log por-fila: 1194 lineas de I/O son ruido y lentitud).
      for I := 0 to High(Rows) do
      begin
        Creados.Add(TPair<Integer, Integer>.Create(Rows[I].NodeId, Rows[I].CenterId));
        Inc(NumCreats);
      end;
      PlanLog.Linea('=== PERSISTENCIA: %d nodos, metodo pedido=%s, usado=%s ' +
        '(NodeId %d..%d) ===',
        [NumCreats, BulkNodeMethodName(MetodoPref), BulkNodeMethodName(MetodoUsado),
         Rows[0].NodeId, Rows[High(Rows)].NodeId]);
    end;

    DMPlanner.ADOConnection.CommitTrans;
  except
    on E: Exception do
    begin
      DMPlanner.ADOConnection.RollbackTrans;
      raise;
    end;
  end;

    ACreados := Creados.ToArray;
  finally
    Creados.Free;
  end;

  PlanLog.Linea('=== COMMIT terminado: %d nodos creados ===', [NumCreats]);
  PlanLog.Fin;

  ShowMessage(Format(
    'Planificacion confirmada: %d nodos creados en el plan actual.' + sLineBreak +
    'El Backlog se recargara.',
    [NumCreats]));
end;

procedure TfrmBacklog.AplicarAgrupacion(const AParams: TSchedParams;
  const ACreados: TArray<TPair<Integer, Integer>>);
var
  PorCentro: TDictionary<Integer, TList<Integer>>;
  P: TPair<Integer, Integer>;
  Par: TPair<Integer, TList<Integer>>;
  IdsTodos: TList<Integer>;
  CentroDestId: Integer;
  C: TCentreTreball;
  Cmd: TADOCommand;

  procedure CrearLoteSiProcede(const AIds: TArray<Integer>);
  begin
    // CrearLote exige >=2 nodos y mismo centro; con 1 no hay nada que agrupar.
    if Length(AIds) >= 2 then
      DMPlanner.CrearLote(AIds);
  end;

begin
  if AParams.Agrupacion = agNinguna then Exit;
  if Length(ACreados) = 0 then Exit;

  if AParams.Agrupacion = agPorCentro then
  begin
    // Un lote por cada centro con 2+ nodos.
    PorCentro := TDictionary<Integer, TList<Integer>>.Create;
    try
      for P in ACreados do
      begin
        if not PorCentro.ContainsKey(P.Value) then
          PorCentro.Add(P.Value, TList<Integer>.Create);
        PorCentro[P.Value].Add(P.Key);
      end;
      for Par in PorCentro do
        CrearLoteSiProcede(Par.Value.ToArray);
    finally
      for Par in PorCentro do
        Par.Value.Free;
      PorCentro.Free;
    end;
    Exit;
  end;

  // agTodo: un unico lote con todos los nodos.
  // Si caen en varios centros, primero los reubicamos al centro destino elegido
  // por el usuario (CrearLote exige mismo centro). El reflow del Gantt afina la
  // posicion al recargar; aqui solo reasignamos CenterId.
  IdsTodos := TList<Integer>.Create;
  try
    CentroDestId := 0;
    if Trim(AParams.CentroDestinoAgrupado) <> '' then
      if (DMPlanner.CentresRepo <> nil) then
        for C in DMPlanner.CentresRepo.GetAll do
          if SameText(Trim(C.CodiCentre), Trim(AParams.CentroDestinoAgrupado)) then
          begin
            CentroDestId := C.Id;
            Break;
          end;

    for P in ACreados do
    begin
      IdsTodos.Add(P.Key);
      // Reubicar al centro destino si difiere y lo conocemos.
      if (CentroDestId > 0) and (P.Value <> CentroDestId) then
      begin
        Cmd := TADOCommand.Create(nil);
        try
          Cmd.Connection := DMPlanner.ADOConnection;
          Cmd.CommandText :=
            'UPDATE FS_PL_Node SET CenterId = ' + IntToStr(CentroDestId) +
            ' WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
            ' AND NodeId = ' + IntToStr(P.Key);
          Cmd.Execute;
        finally
          Cmd.Free;
        end;
      end;
    end;
    CrearLoteSiProcede(IdsTodos.ToArray);
  finally
    IdsTodos.Free;
  end;
end;

procedure TfrmBacklog.Configurar1Click(Sender: TObject);
begin
  if uBacklogCustomCols.TfrmBacklogCustomCols.Execute then
  begin
    // Si ha habido altas/bajas/ediciones, recargar definiciones, columnas y datos.
    // Cambian las columnas custom -> cambia BuildSQL -> el recordset cacheado ya
    // no sirve (le faltarian columnas): invalidar.
    InvalidateDataCache;
    LoadCustomColumnDefs;
    BuildCustomColumns;
    LoadData;
  end;
end;

procedure TfrmBacklog.btnPlanificarClick(Sender: TObject);
begin
  PlanificarSeleccion(False);
end;

procedure TfrmBacklog.btnPlanificarExpressClick(Sender: TObject);
begin
  // Express: salta el paso a paso y abre el wizard en el Resumen con la ultima
  // configuracion. Si aun no hay ninguna guardada, cae al asistente completo.
  if not TfrmBacklogSchedWizard.HayConfigExpress then
  begin
    ShowMessage('A'#250'n no hay una configuraci'#243'n guardada. Planifica una vez con '+
      'el asistente y la "Planificaci'#243'n Express" recordar'#225' tus opciones.');
    PlanificarSeleccion(False);
    Exit;
  end;
  PlanificarSeleccion(True);
end;

procedure TfrmBacklog.PlanificarSeleccion(AExpress: Boolean);
var
  Inputs: TArray<TSchedInput>;
  Params: TSchedParams;
  SR: TSchedResult;
  MR: TModalResult;
  Creados: TArray<TPair<Integer, Integer>>;
  TCol: TDateTime;
  RuleSet, EddRuleSet: TPriorityRuleSet;
  PerfilesCustom, CentrosPlan: TArray<string>;
  PerfilSel, PCI: Integer;
  C: TCentreTreball;
  SetupEngine: TSetupRuleEngine;
begin
  if tvBacklog.Controller.SelectedRowCount = 0 then
  begin
    ShowMessage('Selecciona al menos una fila del backlog para planificar.');
    Exit;
  end;

  if DMPlanner.CurrentProjectId <= 0 then
  begin
    ShowMessage('No hay proyecto activo al que crear nodos.');
    Exit;
  end;

  PlanLog.Inicio(Format('PLANIFICAR  -  %d filas seleccionadas, ProjectId=%d',
    [tvBacklog.Controller.SelectedRowCount, DMPlanner.CurrentProjectId]));

  // Recogida + explosion a OP. Instrumentado: con selecciones grandes (Nivel 1)
  // esta fase era el cuello de botella (1 consulta por OF). Ahora es 1 consulta
  // por nivel. El detalle por-fila se elimino (I/O de log O(n) congelaba la UI).
  TCol := Now;
  Inputs := CollectSelectedInputs;
  PlanLog.Linea('--- INPUTS recogidos: %d operaciones (OP) en %d ms ---',
    [Length(Inputs), MilliSecondsBetween(Now, TCol)]);

  if Length(Inputs) = 0 then
  begin
    // A Nivel 1/2 puede pasar que la seleccion no tenga OP pendientes (todas ya
    // planificadas). Damos feedback en vez de salir en silencio.
    ShowMessage('La selecci'#243'n no tiene operaciones (OP) pendientes de ' +
      'planificar.');
    Exit;
  end;

  // Perfiles del cliente (motor de reglas) para el paso "Estrategia de cola"
  // del wizard: nombres de los perfiles guardados en "Reglas de Planificacion".
  PerfilesCustom := nil;
  if Assigned(Main.Form1) and Assigned(Main.Form1.PlanningRuleEngine) then
  begin
    SetLength(PerfilesCustom, Main.Form1.PlanningRuleEngine.ProfileCount);
    for PCI := 0 to Main.Form1.PlanningRuleEngine.ProfileCount - 1 do
      PerfilesCustom[PCI] := Main.Form1.PlanningRuleEngine.GetProfile(PCI).Name;
  end;

  // Centros del plan (para overrides por centro en el dialogo de desempates).
  CentrosPlan := nil;
  if DMPlanner.CentresRepo <> nil then
    for C in DMPlanner.CentresRepo.GetAll do
      if Trim(C.CodiCentre) <> '' then
        CentrosPlan := CentrosPlan + [Trim(C.CodiCentre)];

  RuleSet := DefaultRuleSet;
  // RuleSet de fallback para perfiles custom: EDD puro (fecha de compromiso).
  EddRuleSet.Principal := prEDD;
  EddRuleSet.Desempate1 := prEDD;
  EddRuleSet.Desempate2 := prEDD;
  PerfilSel := -1;

  Params := Default(TSchedParams);
  while True do
  begin
    // Asistente visual: analiza la seleccion y deja que el usuario decida COMO
    // planificar (granularidad/agrupacion + direccion + fecha + ajustes +
    // estrategia de cola: orden basico / regla canonica / perfil del cliente).
    if not TfrmBacklogSchedWizard.Execute(Inputs, Params, RuleSet,
       PerfilesCustom, CentrosPlan, PerfilSel, AExpress) then Exit;
    // El salto-a-Resumen solo aplica a la PRIMERA apertura: si el bucle reabre
    // el wizard (fecha invalida o preview no aceptado), va paso a paso normal.
    AExpress := False;

    // Validacion: la fecha base no puede ser anterior a la fecha de bloqueo
    // del proyecto activo (si la tiene). La fecha de bloqueo marca el corte
    // a partir del cual aun se puede replanificar; todo lo anterior esta
    // consolidado y no se toca.
    if DMPlanner.CurrentProjectTieneBloqueo and
       (Trunc(Params.FechaBase) < Trunc(DMPlanner.CurrentProjectFechaBloqueo)) then
    begin
      ShowMessage(Format(
        'La fecha seleccionada (%s) es anterior a la fecha de bloqueo ' +
        'del proyecto (%s).' + sLineBreak +
        'No se puede planificar antes de la fecha de bloqueo.',
        [FormatDateTime('dd/mm/yyyy', Params.FechaBase),
         FormatDateTime('dd/mm/yyyy', DMPlanner.CurrentProjectFechaBloqueo)]));
      Continue;  // vuelve a abrir el modal de params
    end;

    // Estrategia de cola: si el wizard pidio orden PREordenado, la cola se
    // ordena AQUI (antes del FCS, que respeta soPreordenado y no reordena).
    //   PerfilSel < 0  -> regla canonica via SortInputsByRuleSet (RuleSet).
    //   PerfilSel >= 0 -> perfil del cliente: ordena NODOS, no inputs; en esta
    //                     primera planificacion aplicamos un orden equivalente
    //                     por fecha de compromiso (EDD) como aproximacion y el
    //                     perfil completo se aplicara al re-planificar el Gantt.
    if Params.Order = soPreordenado then
    begin
      if PerfilSel < 0 then
      begin
        SortInputsByRuleSet(Inputs, RuleSet, Params.FechaBase);
        PlanLog.Linea('--- COLA: regla canonica Principal=%d (preordenado) ---',
          [Ord(RuleSet.Principal)]);
      end
      else
      begin
        // Perfil del cliente: ordena NODOS (no inputs). En la 1a planificacion
        // aproximamos con EDD (fecha de compromiso asc.) via el RuleSet publico.
        SortInputsByRuleSet(Inputs, EddRuleSet, Params.FechaBase);
        PlanLog.Linea('--- COLA: perfil cliente #%d (fallback EDD en 1a planif.) ---',
          [PerfilSel]);
      end;
    end;

    PlanLog.Linea('--- SCHEDULING: Mode=%d Order=%d FechaBase=%s Agrupacion=%d ---',
      [Ord(Params.Mode), Ord(Params.Order), DateToStr(Params.FechaBase),
       Ord(Params.Agrupacion)]);
    TCol := Now;
    // Motor de tiempo de cambio secuencia-dependiente (uSetupRules). Carga el
    // perfil de reglas activo; si no hay reglas, SetupEngine actua como nil
    // (comportamiento clasico con DistanciaMinNodos fija). El scheduler NO es
    // propietario del engine: lo liberamos aqui tras planificar.
    SetupEngine := TSetupRuleEngine.Create;
    try
      SetupEngine.LoadProfile(DMPlanner.GetActiveSetupProfile);
      Params.SetupEngine := SetupEngine;
      SR := RunAutoScheduling(Inputs, Params);
    finally
      Params.SetupEngine := nil;
      SetupEngine.Free;
    end;
    PlanLog.Linea('--- RESULTADO scheduling: %d items, %d planificados en %d ms ---',
      [Length(SR.Items), SR.TotalPlanificados, MilliSecondsBetween(Now, TCol)]);

    MR := TfrmBacklogSchedPreview.Execute(SR);

    case MR of
      mrOk:
        begin
          try
            CommitScheduling(SR, Creados);
            // Agrupacion elegida en el wizard (via Lotes V057), si procede.
            AplicarAgrupacion(Params, Creados);
          except
            on E: Exception do
            begin
              ShowMessage('Error creando nodos: ' + E.Message);
              Exit;
            end;
          end;
          InvalidateDataCache;  // se crearon nodos: datos de ambos tabs cambian
          LoadData;  // recarga -> los planificados desaparecen del backlog
          Exit;
        end;
      mrRetry:
        Continue;  // vuelve al dialogo de parametros
    else
      Exit;
    end;
  end;
end;

procedure TfrmBacklog.btnRecargarClick(Sender: TObject);
begin
  InvalidateDataCache;   // "Refrescar" = el usuario quiere datos frescos de BD
  LoadData;
end;

procedure TfrmBacklog.btnSyncErpClick(Sender: TObject);
var
  Reader: IErpReader;
  Ejercicio: SmallInt;
begin
  Reader := GetActiveErpReader;
  if Reader = nil then
  begin
    ShowMessage('No hay ERP configurado. Configura el ERP en el men'#250
      + ' Configuraci'#243'n > Selector de ERP.');
    Exit;
  end;
  try
    // La conexion al ERP puede tardar: feedback visual con el dialogo Busy.
    // El reader crea su propia conexion ADO, asi que es seguro hacerlo en el
    // hilo de trabajo de RunBusy (que inicializa COM y propaga la excepcion).
    uBusyDialog.RunBusy(Self, 'Conectando con el ERP...',
      procedure
      begin
        Reader.EnsureConnected;
      end);
  except
    on E: Exception do
    begin
      MessageDlg('No se pudo conectar al ERP:'#13#10 + E.Message,
        mtWarning, [mbOK], 0);
      Exit;
    end;
  end;

  // Ejercicio=0 -> el reader descobreix tots els exercicis amb OFs vives
  Ejercicio := 0;
  if TfrmSyncBacklogPreview.Execute(
       Self, DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa,
       Reader.GetSistemaNombre, Reader, Ejercicio) then
  begin
    InvalidateDataCache;   // sync ERP cambio el staging
    LoadData;
  end;
end;

procedure TfrmBacklog.RegenerarNodosDemo1Click(Sender: TObject);
begin
  if TfrmGenerarNodosDemo.Execute then
  begin
    InvalidateDataCache;   // se regeneraron datos
    LoadData;
  end;
end;

procedure TfrmBacklog.RegenerarBacklogDemo1Click(Sender: TObject);
var
  NumOFs, NumCom, NumPrj, PID: Integer;
  VaciarPlan: Boolean;
  Cmd: TADOCommand;
begin
  if not TfrmBacklogRegenParams.Execute(NumOFs, NumCom, NumPrj, VaciarPlan) then
    Exit;

  if VaciarPlan then
  begin
    PID := DMPlanner.CurrentProjectId;
    if PID > 0 then
    begin
      Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := DMPlanner.ADOConnection;
        Cmd.CommandText := 'EXEC FS_PL_sp_ClearProjectPlan :CodigoEmpresa, :ProjectId';
        Cmd.Parameters.ParamByName('CodigoEmpresa').Value := DMPlanner.CodigoEmpresa;
        Cmd.Parameters.ParamByName('ProjectId').Value := PID;
        Cmd.Execute;
      finally
        Cmd.Free;
      end;
    end;
  end;

  uDemoBacklog.GenerarBacklogDemo(NumOFs, NumCom, NumPrj, False);

  InvalidateDataCache;   // se regenero el backlog (y quiza se vacio el plan)
  LoadData;
end;

procedure TfrmBacklog.ApplyImpactoVisible(AVisible: Boolean);
begin
  pnlImpacto.Visible := AVisible;

  // Mantener el checkbox sincronizado (sin redisparar su OnChange).
  if chkVerImpacto.Checked <> AVisible then
  begin
    chkVerImpacto.Properties.OnChange := nil;
    chkVerImpacto.Checked := AVisible;
    chkVerImpacto.Properties.OnChange := chkVerImpactoPropertiesChange;
  end;
end;

procedure TfrmBacklog.ApplyFiltrosVisible(AVisible: Boolean);
begin
  pnlFiltros.Visible := AVisible;
  if chkVerFiltros.Checked <> AVisible then
  begin
    chkVerFiltros.Properties.OnChange := nil;
    chkVerFiltros.Checked := AVisible;
    chkVerFiltros.Properties.OnChange := chkVerFiltrosPropertiesChange;
  end;
end;

procedure TfrmBacklog.chkVerImpactoPropertiesChange(Sender: TObject);
begin
  if FLoading then Exit;
  ApplyImpactoVisible(chkVerImpacto.Checked);
  uUserPrefs.SetPrefBool(BACKLOG_MOD, 'ImpactoVisible', chkVerImpacto.Checked);
end;

procedure TfrmBacklog.chkVerFiltrosPropertiesChange(Sender: TObject);
begin
  if FLoading then Exit;
  ApplyFiltrosVisible(chkVerFiltros.Checked);
  uUserPrefs.SetPrefBool(BACKLOG_MOD, 'FiltrosVisible', chkVerFiltros.Checked);
end;

function TfrmBacklog.IsPlanningTab: Boolean;
begin
  Result := tabMode.TabIndex = 1;
end;

procedure TfrmBacklog.ApplyTabMode;
begin
  // Visibilidad de botones segun tab
  btnPlanificar.Visible := not IsPlanningTab;
  btnDesplanificarSel.Visible := IsPlanningTab;

  // El nivel de vista aplica a ambos tabs (Pendientes y Planificados).
  cmbNivelVista.Visible := True;
  lblNivelVista.Visible := True;

  // Reconstruir columnas porque cambia el set base
  BuildBaseColumns;
  BuildCustomColumns;
  LoadUserLayout;

  // Recargar datos segun vista
  LoadData;
end;

procedure TfrmBacklog.tabModeChange(Sender: TObject);
var
  T: TDateTime;
begin
  if FLoading then Exit;
  uUserPrefs.SetPrefInt(BACKLOG_MOD, 'TabIndex', tabMode.TabIndex);
  PlanLog.Inicio(Format('TOGGLE TAB -> %d (0=Pend,1=Planif)', [tabMode.TabIndex]));
  T := Now;
  ApplyTabMode;
  PlanLog.Linea('=== TOGGLE total: %d ms ===', [MilliSecondsBetween(Now, T)]);
  PlanLog.Fin;
end;

procedure TfrmBacklog.cmbNivelVistaChange(Sender: TObject);
begin
  if FLoading then Exit;
  FNivelVista := cmbNivelVista.ItemIndex + 1;
  if (FNivelVista < 1) or (FNivelVista > 3) then FNivelVista := 3;
  uUserPrefs.SetPrefInt(BACKLOG_MOD, 'NivelVista', FNivelVista);
  LoadData;
end;

// Devuelve los NodeId de las OP planificadas que cuelgan de un nodo Nivel 1/2.
// Usado para desplanificar una OF/OT entera (todos sus nodos a la vez).
function TfrmBacklog.NodeIdsForAncestor(ARawId: Int64;
  ANivel: Integer): TArray<Integer>;
var
  Q: TADOQuery;
  L: TList<Integer>;
  AncestorFilter: string;
begin
  L := TList<Integer>.Create;
  Q := TADOQuery.Create(nil);
  try
    if ANivel <= 1 then
      AncestorFilter :=
        ' JOIN FS_PL_Raw_Item ot ON ot.RawItemId = op.ParentRawItemId' +
        ' WHERE ot.ParentRawItemId = ' + IntToStr(ARawId)
    else
      AncestorFilter :=
        ' WHERE op.ParentRawItemId = ' + IntToStr(ARawId);

    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT n.NodeId FROM FS_PL_Raw_Item op' +
      ' JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = op.CodigoEmpresa' +
      '   AND nd.RawItemTipoOrigen = op.TipoOrigen' +
      '   AND nd.RawItemClaveERP = op.ClaveERP' +
      ' JOIN FS_PL_Node n ON n.CodigoEmpresa = nd.CodigoEmpresa' +
      '   AND n.NodeId = nd.NodeId' +
      AncestorFilter +
      '   AND op.CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '   AND op.Nivel = 3 AND op.Activo = 1';
    Q.Open;
    while not Q.Eof do
    begin
      L.Add(Q.FieldByName('NodeId').AsInteger);
      Q.Next;
    end;
    Result := L.ToArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

function TfrmBacklog.CollectSelectedNodeIds: TArray<Integer>;
var
  I, J, RecIdx, RowIdx: Integer;
  L: TList<Integer>;
  Row: TBacklogRow;
  NodeIds: TArray<Integer>;
begin
  L := TList<Integer>.Create;
  try
    for I := 0 to tvBacklog.Controller.SelectedRowCount - 1 do
    begin
      RecIdx := tvBacklog.Controller.SelectedRows[I].RecordIndex;
      if (RecIdx < 0) or (RecIdx > High(FFilteredIndices)) then Continue;
      RowIdx := FFilteredIndices[RecIdx];
      if (RowIdx < 0) or (RowIdx >= FRows.Count) then Continue;
      Row := FRows[RowIdx];
      if Row.Nivel < 3 then
      begin
        // OF/OT: desplanificar todos los nodos de sus OP descendientes.
        NodeIds := NodeIdsForAncestor(Row.RawId, Row.Nivel);
        for J := 0 to High(NodeIds) do
          L.Add(NodeIds[J]);
      end
      else if Row.NodeId > 0 then
        L.Add(Row.NodeId);
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmBacklog.DoDesplanificar(const ANodeIds: TArray<Integer>);
begin
  // Logica compartida con el Gantt (uVistaGantt): borra Node + NodeData +
  // dependencias + asignaciones en una transaccion.
  DMPlanner.DesplanificarNodes(ANodeIds);
end;

procedure TfrmBacklog.btnDesplanificarSelClick(Sender: TObject);
var
  Ids: TArray<Integer>;
begin
  Ids := CollectSelectedNodeIds;
  if Length(Ids) = 0 then
  begin
    ShowMessage('Selecciona al menos una fila planificada para desplanificar.');
    Exit;
  end;

  if MessageDlg(
      Format('Se desplanificaran %d elementos (se borraran los nodos del plan).' +
        sLineBreak + sLineBreak + 'Continuar?', [Length(Ids)]),
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  try
    DoDesplanificar(Ids);
  except
    on E: Exception do
    begin
      ShowMessage('Error al desplanificar: ' + E.Message);
      Exit;
    end;
  end;
  InvalidateDataCache;   // se borraron nodos: datos de ambos tabs cambian
  LoadData;
  ShowMessage(Format('%d elementos desplanificados.', [Length(Ids)]));
end;


// ---------------------------------------------------------------------------
// Construccion de columnas base (vista FS_PL_vw_Backlog)
// ---------------------------------------------------------------------------
procedure TfrmBacklog.BuildBaseColumns;

  // AValueType: '' = texto (por defecto), 'Float' = numerico, 'Integer',
  // 'DateTime'. Fija DataBinding.ValueType para que el grid ORDENE y formatee por
  // tipo (si no, una columna unbound ordena siempre como string: "10" < "2").
  function AddCol(const AKey, ACaption: string; AWidth: Integer;
    const AValueType: string = ''): TcxGridColumn;
  begin
    Result := tvBacklog.CreateColumn;
    Result.Caption := ACaption;
    Result.Name := 'col_' + StringReplace(AKey, ' ', '_', [rfReplaceAll]);
    Result.Width := AWidth;
    Result.Options.Editing := False;
    if AValueType <> '' then
      Result.DataBinding.ValueType := AValueType;
    Result.Tag := tvBacklog.ColumnCount - 1;
    FColKeyByTag.Add(Result.Tag, AKey);
  end;

var
  Cols: TList<TcxGridColumn>;
begin
  tvBacklog.BeginUpdate;
  try
    tvBacklog.ClearItems;
    FColKeyByTag.Clear;
    Cols := TList<TcxGridColumn>.Create;
    try
      Cols.Add(AddCol('TipoOrigen',           'Tipo',           80));
      Cols.Add(AddCol('CodigoDocumento',      'Documento',     120));
      Cols.Add(AddCol('DescripcionArticulo',  'Descripcion',   260));
      Cols.Add(AddCol('CodigoArticulo',       'Articulo',      110));
      Cols.Add(AddCol('Cantidad',             'Cantidad',       80, 'Float'));
      Cols.Add(AddCol('UnidadMedida',         'UM',             50));
      Cols.Add(AddCol('NombreCliente',        'Cliente',       180));
      Cols.Add(AddCol('CodigoProyecto',       'Proyecto',      100));
      Cols.Add(AddCol('SerieOF',              'Serie OF',       70));
      Cols.Add(AddCol('NumeroOF',             'OF',             70, 'Integer'));
      Cols.Add(AddCol('CodigoOT',             'OT',             90));
      Cols.Add(AddCol('CodigoOP',             'OP',             90));
      Cols.Add(AddCol('FechaCompromiso',      'F. Compromiso', 110, 'DateTime'));
      Cols.Add(AddCol('FechaNecesaria',       'F. Necesaria',  110, 'DateTime'));
      Cols.Add(AddCol('FechaEntrega',         'F. Entrega',    110, 'DateTime'));
      Cols.Add(AddCol('Prioridad',            'Prio',           50, 'Integer'));
      Cols.Add(AddCol('CentroPreferente',     'Centro pref.',  100));
      Cols.Add(AddCol('HorasEstimadas',       'Horas est.',     80, 'Float'));
      Cols.Add(AddCol('EstadoERP',            'Estado',         90));
      Cols.Add(AddCol('Orden',                'Orden op.',      70, 'Integer'));

      // Prevision agregada (V055): solo aporta a Nivel 1/2 (cada fila resume
      // sus OP descendientes pendientes). A Nivel 3 una fila ya es una OP.
      if (not IsPlanningTab) and (FNivelVista < 3) then
      begin
        Cols.Add(AddCol('NumOpsPendientes',     'OP pend.',       70));
        Cols.Add(AddCol('NumOpsTotal',          'OP total',       70));
        Cols.Add(AddCol('DuracionPrevistaMin',  'Dur. prev. (h)', 100));
        Cols.Add(AddCol('FechaCompromisoMin',   'F. Compr. min', 110));
      end;

      // Bloque OP (Nivel 3): solo con valor en filas de operacion.
      Cols.Add(AddCol('OpTiempoPreparacion',  'T. Prep.',       70));
      Cols.Add(AddCol('OpTiempoFabricacion',  'T. Fab.',        70));
      Cols.Add(AddCol('OpUnidadesHora',       'Uds/hora',       70));
      Cols.Add(AddCol('OpCosteHoraMaquina',   'C/h Maq.',       70));
      Cols.Add(AddCol('OpCosteHoraManoObra',  'C/h M.Obra',     80));
      Cols.Add(AddCol('OpUnidadesFabricadas', 'Uds fabr.',      70));
      Cols.Add(AddCol('OpFechaInicioReal',    'Inicio real',   110));
      Cols.Add(AddCol('OpFechaFinalReal',     'Fin real',      110));
      Cols.Add(AddCol('OpOperacionExterna',   'Externa',        60));
      Cols.Add(AddCol('OpCodigoProveedor',    'Proveedor',     100));
      Cols.Add(AddCol('OpSeccionFabrica',     'Secci'#243'n',       80));
      Cols.Add(AddCol('OpStatusPlanificado',  'Planif.',        60));
      Cols.Add(AddCol('OpObservaciones',      'Obs. op.',      180));
      Cols.Add(AddCol('OpPctParaSigOperacion','% Sig.Op',       70));
      Cols.Add(AddCol('OpPctDedicacionOperario','% Dedic.',     70));
      Cols.Add(AddCol('OrigenERP',            'ERP',            70));
      Cols.Add(AddCol('ClaveERP',             'Clave ERP',     120));

      // Columnas extra visibles solo en el tab Planificados
      if IsPlanningTab then
      begin
        // Rango/centro: a Nivel 3 es el del node; a Nivel 1/2 es agregado
        // (rango inicio-fin del conjunto). Las cabeceras valen para ambos.
        Cols.Add(AddCol('NodeInicio',         'Inicio plan.',  130));
        Cols.Add(AddCol('NodeFin',            'Fin plan.',     130));
        if FNivelVista >= 3 then
          Cols.Add(AddCol('NodeCentroNombre', 'Centro plan.',  140))
        else
        begin
          // Indicador de progreso (V056): OP planificadas / total y nº centros.
          Cols.Add(AddCol('Progreso',         'Progreso OP',   110));
          Cols.Add(AddCol('NumCentros',       'Centros',        70));
        end;
      end;

      // Columna "Ver" - dos botons: Pedido (boto 0) + Formula (boto 1)
      var ColVer := AddCol('VerDetalle', 'Ver', 130);
      ColVer.Options.Editing := True;
      ColVer.Options.ShowEditButtons := isebAlways;
      ColVer.PropertiesClass := TcxButtonEditProperties;
      with TcxButtonEditProperties(ColVer.Properties) do
      begin
        ReadOnly := True;
        ViewStyle := vsButtonsAutoWidth;
        Buttons.Clear;
        with Buttons.Add do
        begin
          Default := True;
          Kind := bkText;
          Caption := 'Pedido';
          Width := 55;
        end;
        with Buttons.Add do
        begin
          Kind := bkText;
          Caption := 'F'#243'rm.';
          Width := 55;
        end;
        OnButtonClick := OnColVerButtonClick;
      end;
      Cols.Add(ColVer);

      FBaseColumns := Cols.ToArray;
    finally
      Cols.Free;
    end;
  finally
    tvBacklog.EndUpdate;
  end;
end;

// ---------------------------------------------------------------------------
// Carga catalogo de columnas custom definidas para este grid
// ---------------------------------------------------------------------------
procedure TfrmBacklog.LoadCustomColumnDefs;
var
  Q: TADOQuery;
  L: TList<TCustomColumnDef>;
  Def: TCustomColumnDef;
  DT: string;
begin
  L := TList<TCustomColumnDef>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ColumnKey, Caption, DataType, SourceEntity, SourceExpression, ' +
      '       AppliesToNivel ' +
      'FROM FS_PL_Cfg_GridColumns ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND GridId = ''' + BACKLOG_GRID_ID + '''' +
      '  AND IsCustomField = 1 AND Activo = 1 ' +
      'ORDER BY OrderDefault, ColumnKey';
    Q.Open;
    while not Q.Eof do
    begin
      Def.ColumnKey := Q.FieldByName('ColumnKey').AsString;
      Def.Caption   := Q.FieldByName('Caption').AsString;
      DT := Q.FieldByName('DataType').AsString;
      if DT = '' then
        Def.DataType := 'S'
      else
        Def.DataType := DT[1];
      Def.SourceEntity := UpperCase(Q.FieldByName('SourceEntity').AsString);
      if Q.FieldByName('SourceExpression').IsNull or
         (Trim(Q.FieldByName('SourceExpression').AsString) = '') then
        Def.FieldKey := Def.ColumnKey
      else
        Def.FieldKey := Q.FieldByName('SourceExpression').AsString;
      if Q.FieldByName('AppliesToNivel').IsNull then
        Def.AppliesToNivel := 0
      else
        Def.AppliesToNivel := Q.FieldByName('AppliesToNivel').AsInteger;
      L.Add(Def);
      Q.Next;
    end;
    FCustomCols := L.ToArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

procedure TfrmBacklog.BuildCustomColumns;
var
  I: Integer;
  Col: TcxGridColumn;
  Cols: TList<TcxGridColumn>;
begin
  Cols := TList<TcxGridColumn>.Create;
  tvBacklog.BeginUpdate;
  try
    for I := 0 to High(FCustomCols) do
    begin
      Col := tvBacklog.CreateColumn;
      // Sufijo visual para distinguir columnas custom editables del resto.
      Col.Caption := FCustomCols[I].Caption + '  '#9998;  // U+270E (lapiz)
      Col.HeaderHint := 'Campo personalizado editable. Doble clic para modificar el valor.';
      Col.Name := 'colx_' + FCustomCols[I].ColumnKey;
      Col.Width := 120;
      // Editor segun DataType. Asignamos la clase concreta para que DevExpress
      // construya el TcxCustomEditProperties correcto y dispare OnEditValueChanged.
      case UpCase(FCustomCols[I].DataType) of
        'N': Col.PropertiesClass := TcxCalcEditProperties;
        'D': Col.PropertiesClass := TcxDateEditProperties;
        'B': Col.PropertiesClass := TcxCheckBoxProperties;
      else
        Col.PropertiesClass := TcxTextEditProperties;
      end;
      Col.Options.Editing := True;
      Col.Tag := tvBacklog.ColumnCount - 1;
      FColKeyByTag.Add(Col.Tag, 'X:' + FCustomCols[I].ColumnKey);
      Cols.Add(Col);
    end;
    FCustomColumns := Cols.ToArray;

    // Habilitar edicion en la vista solo si hay alguna columna custom.
    // Las columnas base ya tienen Options.Editing=False, asi que no se podran
    // editar aunque la vista lo permita.
    // CellSelect=True es imprescindible para que DevExpress entre en modo
    // edicion cell-by-cell; sin esto el doble clic solo selecciona la fila
    // entera y no abre el editor.
    if Length(FCustomCols) > 0 then
    begin
      tvBacklog.OptionsData.Editing := True;
      tvBacklog.OptionsSelection.CellSelect := True;
      tvBacklog.OptionsBehavior.CellHints := True;
      tvBacklog.OptionsBehavior.ColumnHeaderHints := True;
    end
    else
    begin
      tvBacklog.OptionsData.Editing := False;
      // CellSelect lo dejamos como esta en el DFM (False) si no hay customs.
    end;
    tvBacklog.OnEditValueChanged := tvBacklogCustomEditValueChanged;
  finally
    tvBacklog.EndUpdate;
    Cols.Free;
  end;
end;

// ---------------------------------------------------------------------------
// SQL de la vista + JOINs dinamicos para campos custom
// ---------------------------------------------------------------------------
function TfrmBacklog.BuildSQL: string;
var
  I, Nivel: Integer;
  Sel, Joins, Alias, RawIdExpr, TipoFiltro: string;
  NeedsAncestors: Boolean;
begin
  // Solo unimos parent/grandparent si hay alguna columna custom que lo necesite.
  // Asi en arranque rapido (sin custom cols) la consulta queda al nivel pre-PR.
  NeedsAncestors := Length(FCustomCols) > 0;

  if NeedsAncestors then
    Sel := 'b.*, gp.RawItemId AS GrandRawItemId'
  else
    Sel := 'b.*';
  Joins := '';

  if NeedsAncestors then
  begin
    // Un solo JOIN al padre (Nivel=2) y otro al abuelo (Nivel=1). Reutilizables
    // por todos los JOINs de columnas custom.
    Joins :=
      ' LEFT JOIN FS_PL_Raw_Item pp ' +
      '   ON pp.CodigoEmpresa = b.CodigoEmpresa AND pp.RawItemId = b.ParentRawItemId' +
      ' LEFT JOIN FS_PL_Raw_Item gp ' +
      '   ON gp.CodigoEmpresa = pp.CodigoEmpresa AND gp.RawItemId = pp.ParentRawItemId';
  end;

  for I := 0 to High(FCustomCols) do
  begin
    Alias := 'x' + IntToStr(I);

    // Nivel del Raw_Item al que aplica el campo. Si no se ha especificado,
    // por defecto se busca al nivel del leaf que muestra el backlog (3).
    Nivel := FCustomCols[I].AppliesToNivel;
    if Nivel = 0 then Nivel := 3;

    // El leaf no siempre esta a Nivel=3: puede ser una OF Nivel=1 sin OTs
    // creadas, una OT Nivel=2 sin OPs, etc. Por eso el join debe escoger el
    // RawItemId segun la diferencia entre b.Nivel y el nivel objetivo.
    //   diff=0 -> el propio leaf
    //   diff=1 -> padre del leaf
    //   diff=2 -> abuelo
    //   resto -> NULL (no hace match, columna queda vacia para esta fila)
    RawIdExpr :=
      'CASE (b.Nivel - ' + IntToStr(Nivel) + ')' +
      '  WHEN 0 THEN b.RawId' +
      '  WHEN 1 THEN b.ParentRawItemId' +
      '  WHEN 2 THEN gp.RawItemId' +
      '  ELSE NULL END';

    // Filtrar por TipoOrigen segun SourceEntity (un campo de PEDIDO no debe
    // pintarse en filas de OF). Lo metemos dentro del ON, no en el WHERE,
    // para que LEFT JOIN no se convierta en filtro de la fila base.
    if FCustomCols[I].SourceEntity = 'OF' then
      TipoFiltro := '''OF '''
    else if FCustomCols[I].SourceEntity = 'PEDIDO' then
      TipoFiltro := '''PED'''
    else if FCustomCols[I].SourceEntity = 'PROYECTO' then
      TipoFiltro := '''PRJ'''
    else
      TipoFiltro := '';

    Sel := Sel + ', ' + Alias + '.FieldValue AS [X_' + FCustomCols[I].ColumnKey + ']';

    Joins := Joins +
      ' LEFT JOIN FS_PL_RawItem_Extra ' + Alias +
      '   ON ' + Alias + '.CodigoEmpresa = b.CodigoEmpresa' +
      '  AND ' + Alias + '.RawItemId = ' + RawIdExpr +
      '  AND ' + Alias + '.FieldKey  = ' + QStr(FCustomCols[I].FieldKey);
    if TipoFiltro <> '' then
      Joins := Joins +
      '  AND b.TipoOrigen = ' + TipoFiltro;
  end;

  if IsPlanningTab and (FNivelVista >= 3) then
    // Nivel 3 (OP): 1 fila por OP planificada, con su node. Vista ligera que ya
    // filtra por ProjectId.
    Result :=
      'SELECT ' + Sel + ' FROM FS_PL_vw_BacklogPlanned b ' + Joins +
      ' WHERE b.CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '   AND b.ProjectId = ' + IntToStr(DMPlanner.CurrentProjectId) +
      ' ORDER BY b.NodeInicio'
  else if IsPlanningTab then
    // Nivel 1/2: vista multinivel de planificados con agregados de progreso
    // (V056): rango NodeInicio/NodeFin, NumOpsPlan/Total, NumCentros.
    // Filtramos por ProjectId igual que la rama Nivel 3, para no mezclar el
    // progreso de OP planificadas en otros proyectos (la vista expone ProjectId).
    Result :=
      'SELECT ' + Sel + ' FROM FS_PL_vw_BacklogPlannedTree b ' + Joins +
      ' WHERE b.CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '   AND b.ProjectId = ' + IntToStr(DMPlanner.CurrentProjectId) +
      '   AND b.Nivel = ' + IntToStr(FNivelVista) +
      ' ORDER BY b.NodeInicio'
  else if FNivelVista >= 3 then
    // Nivel 3 (OP): no necesita los agregados de prevision, y FS_PL_vw_BacklogTree
    // a este nivel es ~100x mas lenta (calcula agregados que no se usan). Usamos
    // la vista ligera FS_PL_vw_Backlog (leafs sin node) filtrando Nivel=3.
    Result :=
      'SELECT ' + Sel + ' FROM FS_PL_vw_Backlog b ' + Joins +
      ' WHERE b.CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '   AND b.Nivel = 3' +
      ' ORDER BY b.FechaCompromiso, b.Prioridad DESC'
  else
    // Nivel 1/2: vista multinivel con agregados de prevision (V055).
    // FS_PL_vw_BacklogTree expone las mismas columnas que FS_PL_vw_Backlog mas
    // DuracionPrevistaMin, NumOps*, FechaCompromisoMin.
    Result :=
      'SELECT ' + Sel + ' FROM FS_PL_vw_BacklogTree b ' + Joins +
      ' WHERE b.CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '   AND b.Nivel = ' + IntToStr(FNivelVista) +
      ' ORDER BY b.FechaCompromiso, b.Prioridad DESC';
end;

// ---------------------------------------------------------------------------
// Cache del recordset por (tab, nivel). El toggle Pendientes/Planificados y el
// cambio de nivel son muy comunes y la query es ~89% del tiempo (~1s). La cache
// guarda SOLO datos (recordset desconectado); el layout de columnas (orden,
// anchos, ocultas) es independiente (lo gestiona DevExpress + FS_PL_Cfg_UserGridLayout)
// y NO se ve afectado: al hacer toggle las columnas se reconstruyen igual.
// ---------------------------------------------------------------------------
function TfrmBacklog.CacheKey: string;
begin
  Result := IntToStr(tabMode.TabIndex) + '|' + IntToStr(FNivelVista);
end;

function TfrmBacklog.TryLoadFromCache(out ADataSet: TCustomADODataSet): Boolean;
begin
  ADataSet := nil;
  Result := (FRecordsetCache <> nil) and
            FRecordsetCache.TryGetValue(CacheKey, ADataSet) and
            (ADataSet <> nil) and ADataSet.Active;
end;

// Adopta el recordset (ya desconectado) en la cache bajo la clave actual. La
// cache es TObjectDictionary con doOwnsValues: al reemplazar o vaciar, libera el
// anterior automaticamente. El recordset es client-side/desconectado, asi que se
// puede rebobinar (First) y releer en cada toggle sin volver a BD.
procedure TfrmBacklog.StoreInCache(ADataSet: TCustomADODataSet);
begin
  if (FRecordsetCache = nil) or (ADataSet = nil) then Exit;
  FRecordsetCache.AddOrSetValue(CacheKey, ADataSet);  // libera el previo si habia
end;

// Vacia toda la cache: fuerza que el proximo LoadData vaya a BD. Se llama cuando
// los DATOS cambian (planificar, desplanificar, cambiar filtros, refrescar).
// El layout de columnas NO pasa por aqui (es independiente).
procedure TfrmBacklog.InvalidateDataCache;
begin
  if FRecordsetCache <> nil then
    FRecordsetCache.Clear;   // doOwnsValues libera cada recordset
end;

// ---------------------------------------------------------------------------
// Carga datos a la estructura interna y luego los vuelca al grid
// ---------------------------------------------------------------------------
procedure TfrmBacklog.LoadData;
var
  Q: TADOQuery;          // creado solo si vamos a BD; su propiedad pasa a la cache
  DS: TCustomADODataSet; // fuente a volcar: Q nuevo o el recordset cacheado
  Cached: TCustomADODataSet;
  Row: TBacklogRow;
  I: Integer;
  FldName: string;
  V: Variant;
  SQLText, ConnStr: string;
  TQuery, TVolcado, TPintado: TDateTime;
begin
  ClearRows;
  Q := nil;
  SQLText := BuildSQL;
  ConnStr := DMPlanner.ConnectionStringForThreads;

  TQuery := Now;
  if TryLoadFromCache(Cached) then
  begin
    // Servido desde memoria: nada de thread ni BD. Rebobinar el recordset
    // (desconectado -> se puede releer). La propiedad sigue en la cache.
    DS := Cached;
    DS.First;
    PlanLog.Linea('LOADDATA query (tab=%d nivel=%d): %d ms [CACHE]',
      [tabMode.TabIndex, FNivelVista, MilliSecondsBetween(Now, TQuery)]);
  end
  else
  begin
    // La query (parte lenta) se ejecuta en un thread con conexion ADO propia y
    // cursor client-side: asi se desconecta y se puede leer desde el hilo
    // principal, que mientras tanto anima el spinner del dialogo de carga.
    Q := TADOQuery.Create(nil);
    uBusyDialog.RunBusy(Self, 'Cargando backlog...',
      procedure
      var
        ThConn: TADOConnection;
      begin
        ThConn := TADOConnection.Create(nil);
        try
          ThConn.LoginPrompt := False;
          ThConn.ConnectionString := ConnStr;
          ThConn.Open;
          Q.Connection := ThConn;
          Q.CursorLocation := clUseClient;
          Q.SQL.Text := SQLText;
          Q.Open;
          // Desconectar el recordset para poder leerlo en el hilo principal
          // una vez cerrada la conexion del thread.
          Q.Connection := nil;
        finally
          ThConn.Free;
        end;
      end);
    DS := Q;
    // La cache ADOPTA Q (TObjectDictionary doOwnsValues lo liberara). Por eso
    // NO se libera aqui: sobrevive para el proximo toggle desde memoria.
    StoreInCache(Q);
    PlanLog.Linea('LOADDATA query (tab=%d nivel=%d): %d ms [BD]',
      [tabMode.TabIndex, FNivelVista, MilliSecondsBetween(Now, TQuery)]);
  end;
  TVolcado := Now;

    // A partir de aqui, ya en el hilo principal, volcamos el recordset
    // (desconectado) a las filas y al grid.
    while not DS.Eof do
    begin
      Row.Origen              := DS.FieldByName('Origen').AsString;
      if DS.FindField('TipoOrigen') <> nil then
        Row.TipoOrigen := DS.FieldByName('TipoOrigen').AsString
      else
        Row.TipoOrigen := '';
      if DS.FindField('Nivel') <> nil then
        Row.Nivel := DS.FieldByName('Nivel').AsInteger
      else
        Row.Nivel := 0;
      Row.RawId               := DS.FieldByName('RawId').AsLargeInt;
      if (DS.FindField('ParentRawItemId') <> nil) and
         not DS.FieldByName('ParentRawItemId').IsNull then
        Row.ParentRawItemId := DS.FieldByName('ParentRawItemId').AsLargeInt
      else
        Row.ParentRawItemId := 0;
      if (DS.FindField('GrandRawItemId') <> nil) and
         not DS.FieldByName('GrandRawItemId').IsNull then
        Row.GrandRawItemId := DS.FieldByName('GrandRawItemId').AsLargeInt
      else
        Row.GrandRawItemId := 0;
      Row.OrigenERP           := DS.FieldByName('OrigenERP').AsString;
      Row.ClaveERP            := DS.FieldByName('ClaveERP').AsString;
      Row.CodigoDocumento     := DS.FieldByName('CodigoDocumento').AsString;
      if DS.FindField('NumeroDoc') <> nil then
        Row.NumeroDoc := DS.FieldByName('NumeroDoc').AsInteger
      else
        Row.NumeroDoc := 0;
      if DS.FindField('SerieDoc') <> nil then
        Row.SerieDoc := DS.FieldByName('SerieDoc').AsString
      else
        Row.SerieDoc := '';
      Row.CodigoArticulo      := DS.FieldByName('CodigoArticulo').AsString;
      Row.DescripcionArticulo := DS.FieldByName('DescripcionArticulo').AsString;
      Row.Cantidad            := DS.FieldByName('Cantidad').AsFloat;
      Row.UnidadMedida        := DS.FieldByName('UnidadMedida').AsString;
      Row.CodigoCliente       := DS.FieldByName('CodigoCliente').AsString;
      Row.NombreCliente       := DS.FieldByName('NombreCliente').AsString;
      Row.CodigoProyecto      := DS.FieldByName('CodigoProyecto').AsString;
      if (DS.FindField('NumeroOF') <> nil) and not DS.FieldByName('NumeroOF').IsNull then
        Row.NumeroOF := DS.FieldByName('NumeroOF').AsInteger
      else
        Row.NumeroOF := 0;
      if DS.FindField('SerieOF') <> nil then
        Row.SerieOF := DS.FieldByName('SerieOF').AsString
      else
        Row.SerieOF := '';
      if DS.FindField('CodigoOT') <> nil then
        Row.CodigoOT := DS.FieldByName('CodigoOT').AsString
      else
        Row.CodigoOT := '';
      if DS.FindField('CodigoOP') <> nil then
        Row.CodigoOP := DS.FieldByName('CodigoOP').AsString
      else
        Row.CodigoOP := '';
      if DS.FieldByName('FechaCompromiso').IsNull then Row.FechaCompromiso := 0
        else Row.FechaCompromiso := DS.FieldByName('FechaCompromiso').AsDateTime;
      if DS.FieldByName('FechaNecesaria').IsNull then Row.FechaNecesaria := 0
        else Row.FechaNecesaria := DS.FieldByName('FechaNecesaria').AsDateTime;
      if (DS.FindField('FechaEntrega') <> nil) and not DS.FieldByName('FechaEntrega').IsNull then
        Row.FechaEntrega := DS.FieldByName('FechaEntrega').AsDateTime
      else
        Row.FechaEntrega := Row.FechaCompromiso;
      Row.Prioridad           := DS.FieldByName('Prioridad').AsInteger;
      Row.CentroPreferente    := DS.FieldByName('CentroPreferente').AsString;
      Row.HorasEstimadas      := DS.FieldByName('HorasEstimadas').AsFloat;
      if (DS.FindField('TiempoUnidadFabSecs') <> nil)
         and not DS.FieldByName('TiempoUnidadFabSecs').IsNull then
        Row.TiempoUnidadFabSecs := DS.FieldByName('TiempoUnidadFabSecs').AsFloat
      else
        Row.TiempoUnidadFabSecs := 0;
      Row.EstadoERP           := DS.FieldByName('EstadoERP').AsString;

      // Bloque OP (Nivel 3). FindField por robustez ante vistas pre-V053.
      if DS.FindField('Orden') <> nil then
        Row.Orden := DS.FieldByName('Orden').AsInteger
      else
        Row.Orden := 0;
      Row.OpTiempoPreparacion  := FieldFloat(DS, 'OpTiempoPreparacion');
      Row.OpTiempoFabricacion  := FieldFloat(DS, 'OpTiempoFabricacion');
      Row.OpUnidadesHora       := FieldFloat(DS, 'OpUnidadesHora');
      Row.OpCosteHoraMaquina   := FieldFloat(DS, 'OpCosteHoraMaquina');
      Row.OpCosteHoraManoObra  := FieldFloat(DS, 'OpCosteHoraManoObra');
      Row.OpUnidadesFabricadas := FieldFloat(DS, 'OpUnidadesFabricadas');
      Row.OpFechaInicioReal    := FieldDate(DS, 'OpFechaInicioReal');
      Row.OpFechaFinalReal     := FieldDate(DS, 'OpFechaFinalReal');
      Row.OpOperacionExterna   := FieldBoolVar(DS, 'OpOperacionExterna');
      Row.OpCodigoProveedor    := FieldStr(DS, 'OpCodigoProveedor');
      Row.OpSeccionFabrica     := FieldStr(DS, 'OpSeccionFabrica');
      Row.OpStatusPlanificado  := FieldBoolVar(DS, 'OpStatusPlanificado');
      Row.OpObservaciones      := FieldStr(DS, 'OpObservaciones');
      Row.OpPctParaSigOperacion   := FieldFloat(DS, 'OpPctParaSigOperacion');
      Row.OpPctDedicacionOperario := FieldFloat(DS, 'OpPctDedicacionOperario');

      // Agregados de prevision (V055, solo vw_BacklogTree). FindField por
      // robustez: vw_BacklogPlanned no los trae.
      Row.DuracionPrevistaMin := FieldFloat(DS, 'DuracionPrevistaMin');
      if DS.FindField('NumOpsTotal') <> nil then
        Row.NumOpsTotal := DS.FieldByName('NumOpsTotal').AsInteger
      else
        Row.NumOpsTotal := 0;
      if DS.FindField('NumOpsPendientes') <> nil then
        Row.NumOpsPendientes := DS.FieldByName('NumOpsPendientes').AsInteger
      else
        Row.NumOpsPendientes := 0;
      Row.FechaCompromisoMin := FieldDate(DS, 'FechaCompromisoMin');

      // Campos del nodo (solo vw_BacklogPlanned / vw_BacklogPlannedTree)
      Row.NodeId := 0;
      Row.NodeInicio := 0;
      Row.NodeFin := 0;
      Row.NodeCodigoCentro := '';
      Row.NodeCentroNombre := '';
      Row.NumOpsPlan := 0;
      Row.NumCentros := 0;
      if IsPlanningTab then
      begin
        if DS.FindField('NodeId') <> nil then
          Row.NodeId := DS.FieldByName('NodeId').AsInteger;
        if (DS.FindField('NodeInicio') <> nil) and not DS.FieldByName('NodeInicio').IsNull then
          Row.NodeInicio := DS.FieldByName('NodeInicio').AsDateTime;
        if (DS.FindField('NodeFin') <> nil) and not DS.FieldByName('NodeFin').IsNull then
          Row.NodeFin := DS.FieldByName('NodeFin').AsDateTime;
        if DS.FindField('NodeCodigoCentro') <> nil then
          Row.NodeCodigoCentro := DS.FieldByName('NodeCodigoCentro').AsString;
        if DS.FindField('NodeCentroNombre') <> nil then
          Row.NodeCentroNombre := DS.FieldByName('NodeCentroNombre').AsString;
        // Agregados de progreso (V056, solo a Nivel 1/2 via vw_BacklogPlannedTree).
        if DS.FindField('NumOpsPlan') <> nil then
          Row.NumOpsPlan := DS.FieldByName('NumOpsPlan').AsInteger;
        if DS.FindField('NumCentros') <> nil then
          Row.NumCentros := DS.FieldByName('NumCentros').AsInteger;
      end;

      Row.Extras := TDictionary<string, Variant>.Create;
      for I := 0 to High(FCustomCols) do
      begin
        FldName := 'X_' + FCustomCols[I].ColumnKey;
        if DS.FindField(FldName) <> nil then
        begin
          if DS.FieldByName(FldName).IsNull then
            V := Null
          else
            // FieldValue siempre vive en BD como string en formato invariant.
            // Lo decodificamos al tipo nativo (Double/TDateTime/Boolean/string)
            // para que el editor de la celda acepte el valor sin conversion.
            V := DecodeFieldValue(FCustomCols[I].DataType,
                                  DS.FieldByName(FldName).AsString);
          Row.Extras.AddOrSetValue(FCustomCols[I].ColumnKey, V);
        end;
      end;

      FRows.Add(Row);
      DS.Next;
    end;
  // No se libera DS: su propiedad esta en FRecordsetCache (viene de cache o Q
  // recien adoptado). Se liberara al invalidar la cache o al destruir el form.
  PlanLog.Linea('LOADDATA volcado %d filas: %d ms',
    [FRows.Count, MilliSecondsBetween(Now, TVolcado)]);
  // Umbral naranja del semaforo de fila (mismo que el KPI 'Vencen Nd'). Se lee
  // aqui para que OnGetContentStyle no toque las prefs en cada celda.
  FDiasVencimiento := uUserPrefs.GetPrefInt(BACKLOG_MOD, 'DiasVencimiento', 7);
  if FDiasVencimiento <= 0 then FDiasVencimiento := 7;
  TPintado := Now;
  ApplyRowsToGrid;
  LoadKpis;
  PlanLog.Linea('LOADDATA pintado+KPIs: %d ms', [MilliSecondsBetween(Now, TPintado)]);
  // UpdateCountLabel (dins ApplyRowsToGrid) ya ha puesto el conteo real.
end;

// ---------------------------------------------------------------------------
// KPIs de cabecera: OF / OT / OP pendientes vs planificadas (globales, no
// afectados por los filtros de la barra lateral). Una OF/OT cuenta como
// pendiente si tiene alguna OP sin node, y como planificada si tiene alguna OP
// con node (puede contar en ambas si esta a medias).
// ---------------------------------------------------------------------------
// Configura el umbral de dias de la franja 'a punto de vencer' (KPI ambar
// 'Vencen Nd'). NO afecta a 'Vencidas' (siempre = FechaCompromiso < hoy).
procedure TfrmBacklog.ConfigurarVencimiento1Click(Sender: TObject);
var
  S: string;
  Dias, Actual: Integer;
begin
  Actual := uUserPrefs.GetPrefInt(BACKLOG_MOD, 'DiasVencimiento', 7);
  if Actual <= 0 then Actual := 7;
  S := IntToStr(Actual);
  if not InputQuery('Aviso de vencimiento',
       'Marcar como '#39'pr'#243'ximas a vencer'#39' las operaciones cuya fecha de ' +
       'compromiso est'#233' dentro de los pr'#243'ximos N d'#237'as:', S) then
    Exit;

  if not TryStrToInt(Trim(S), Dias) or (Dias <= 0) or (Dias > 365) then
  begin
    ShowMessage('Introduce un n'#250'mero de d'#237'as v'#225'lido (entre 1 y 365).');
    Exit;
  end;

  uUserPrefs.SetPrefInt(BACKLOG_MOD, 'DiasVencimiento', Dias);
  FDiasVencimiento := Dias;
  LoadKpis;                    // recalcula el semaforo KPI de cabecera
  tvBacklog.Site.Invalidate;   // repinta el grid con el nuevo umbral (sin recargar)
end;

procedure TfrmBacklog.LoadKpis;
var
  Q: TADOQuery;
  ofP, ofPl, ofT, otP, otPl, otT, opP, opPl, opT: Integer;
  vencidas, proximas, sinFecha, diasVenc: Integer;
begin
  ofP := 0; ofPl := 0; ofT := 0; otP := 0; otPl := 0; otT := 0;
  opP := 0; opPl := 0; opT := 0;
  vencidas := 0; proximas := 0; sinFecha := 0;
  // Umbral 'a punto de vencer' en dias (configurable por usuario; default 7).
  diasVenc := uUserPrefs.GetPrefInt(BACKLOG_MOD, 'DiasVencimiento', 7);
  if diasVenc <= 0 then diasVenc := 7;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    // Estado por OP (Nivel 3): planificada si tiene node, pendiente si no.
    // OF/OT: pendientes/planificadas = documentos distintos con alguna OP en ese
    // estado (una OF a medias cuenta en ambos). El total (Tot) es el numero de
    // documentos DISTINTOS, sin doble conteo del solapamiento.
    // Ademas, sobre las OP PENDIENTES, clasificamos por FechaCompromiso en tres
    // franjas: vencidas (< hoy), proximas (hoy..hoy+N) y sin fecha (NULL).
    Q.SQL.Text :=
      'WITH OpState AS ('#13#10 +
      '  SELECT op.RawItemId, op.ParentRawItemId AS N2,'#13#10 +
      '    op.FechaCompromiso AS FCompromiso,'#13#10 +
      '    (SELECT p1.ParentRawItemId FROM FS_PL_Raw_Item p1'#13#10 +
      '      WHERE p1.RawItemId = op.ParentRawItemId) AS N1,'#13#10 +
      '    CASE WHEN EXISTS (SELECT 1 FROM FS_PL_NodeData nd'#13#10 +
      '          WHERE nd.CodigoEmpresa = op.CodigoEmpresa'#13#10 +
      '            AND nd.RawItemTipoOrigen = op.TipoOrigen'#13#10 +
      '            AND nd.RawItemClaveERP = op.ClaveERP)'#13#10 +
      '         THEN 1 ELSE 0 END AS Planif'#13#10 +
      '  FROM FS_PL_Raw_Item op'#13#10 +
      '  WHERE op.Nivel = 3 AND op.Activo = 1'#13#10 +
      '    AND op.CodigoEmpresa = ' + IntToStr(EmpresaCode) + #13#10 +
      ')'#13#10 +
      'SELECT'#13#10 +
      '  COUNT(DISTINCT CASE WHEN Planif=0 THEN N1 END) AS OfPend,'#13#10 +
      '  COUNT(DISTINCT CASE WHEN Planif=1 THEN N1 END) AS OfPlan,'#13#10 +
      '  COUNT(DISTINCT N1)                             AS OfTot,'#13#10 +
      '  COUNT(DISTINCT CASE WHEN Planif=0 THEN N2 END) AS OtPend,'#13#10 +
      '  COUNT(DISTINCT CASE WHEN Planif=1 THEN N2 END) AS OtPlan,'#13#10 +
      '  COUNT(DISTINCT N2)                             AS OtTot,'#13#10 +
      '  SUM(CASE WHEN Planif=0 THEN 1 ELSE 0 END)      AS OpPend,'#13#10 +
      '  SUM(CASE WHEN Planif=1 THEN 1 ELSE 0 END)      AS OpPlan,'#13#10 +
      '  COUNT(*)                                       AS OpTot,'#13#10 +
      '  SUM(CASE WHEN Planif=0 AND FCompromiso IS NOT NULL'#13#10 +
      '            AND CAST(FCompromiso AS DATE) < CAST(GETDATE() AS DATE)'#13#10 +
      '           THEN 1 ELSE 0 END)                    AS Vencidas,'#13#10 +
      '  SUM(CASE WHEN Planif=0 AND FCompromiso IS NOT NULL'#13#10 +
      '            AND CAST(FCompromiso AS DATE) >= CAST(GETDATE() AS DATE)'#13#10 +
      '            AND CAST(FCompromiso AS DATE) <= DATEADD(DAY, ' + IntToStr(diasVenc) + ', CAST(GETDATE() AS DATE))'#13#10 +
      '           THEN 1 ELSE 0 END)                    AS Proximas,'#13#10 +
      '  SUM(CASE WHEN Planif=0 AND FCompromiso IS NULL'#13#10 +
      '           THEN 1 ELSE 0 END)                    AS SinFecha'#13#10 +
      'FROM OpState';
    Q.Open;
    if not Q.Eof then
    begin
      ofP  := Q.FieldByName('OfPend').AsInteger;
      ofPl := Q.FieldByName('OfPlan').AsInteger;
      ofT  := Q.FieldByName('OfTot').AsInteger;
      otP  := Q.FieldByName('OtPend').AsInteger;
      otPl := Q.FieldByName('OtPlan').AsInteger;
      otT  := Q.FieldByName('OtTot').AsInteger;
      opP  := Q.FieldByName('OpPend').AsInteger;
      opPl := Q.FieldByName('OpPlan').AsInteger;
      opT  := Q.FieldByName('OpTot').AsInteger;
      vencidas := Q.FieldByName('Vencidas').AsInteger;
      proximas := Q.FieldByName('Proximas').AsInteger;
      sinFecha := Q.FieldByName('SinFecha').AsInteger;
    end;
  except
    // Si falla la consulta, dejamos los KPIs a 0 (no bloquea el Backlog).
  end;
  Q.Free;

  // Valor grande = pendientes; caption = planificadas / total de documentos.
  // Valor grande = pendientes; caption compacto = 'OF  plan/tot' (cabe en 95px).
  lblKpiOFVal.Caption := IntToStr(ofP);
  lblKpiOFCap.Caption := Format('OF  %d/%d', [ofPl, ofT]);
  lblKpiOTVal.Caption := IntToStr(otP);
  lblKpiOTCap.Caption := Format('OT  %d/%d', [otPl, otT]);
  lblKpiOPVal.Caption := IntToStr(opP);
  lblKpiOPCap.Caption := Format('OP  %d/%d', [opPl, opT]);

  // Semaforo de vencimiento sobre las OP pendientes (rojo / ambar / gris).
  lblKpiVencVal.Caption := IntToStr(vencidas);
  lblKpiVencCap.Caption := 'Vencidas';
  lblKpiPronVal.Caption := IntToStr(proximas);
  lblKpiPronCap.Caption := Format('Vencen %dd', [diasVenc]);
  lblKpiSinFVal.Caption := IntToStr(sinFecha);
  lblKpiSinFCap.Caption := 'Sin fecha';
end;

// ---------------------------------------------------------------------------
// Filtro local en memoria (barra lateral)
// ---------------------------------------------------------------------------
function TfrmBacklog.PassesFilter(const Row: TBacklogRow): Boolean;
var
  S: string;
begin
  Result := False;
  if cmbOrigen.ItemIndex > 0 then
  begin
    // Row.Origen para hojas Nivel=3 ERP siempre es 'OP'; el combo filtra por
    // familia (OF/PEDIDO/PROYECTO), derivada del TipoOrigen heredado del padre.
    // Los nodos MANUALES (V067) no tienen TipoOrigen: se filtran por Origen.
    S := UpperCase(Trim(Row.TipoOrigen));
    if      (cmbOrigen.ItemIndex = 1) and (S <> 'OF')  then Exit
    else if (cmbOrigen.ItemIndex = 2) and (S <> 'PED') then Exit
    else if (cmbOrigen.ItemIndex = 3) and (S <> 'PRJ') then Exit
    else if (cmbOrigen.ItemIndex = 4) and
            (UpperCase(Trim(Row.Origen)) <> 'MANUAL')  then Exit;
  end;

  S := Trim(edtCliente.Text);
  if (S <> '') and (Pos(UpperCase(S), UpperCase(Row.NombreCliente + ' ' + Row.CodigoCliente)) = 0) then Exit;
  S := Trim(edtProyecto.Text);
  if (S <> '') and (Pos(UpperCase(S), UpperCase(Row.CodigoProyecto)) = 0) then Exit;
  S := Trim(edtCentro.Text);
  if (S <> '') and (Pos(UpperCase(S), UpperCase(Row.CentroPreferente)) = 0) then Exit;
  S := Trim(edtEstado.Text);
  if (S <> '') and (Pos(UpperCase(S), UpperCase(Row.EstadoERP)) = 0) then Exit;

  if chkUsaFechaDesde.Checked and (Row.FechaCompromiso <> 0) then
    if Row.FechaCompromiso < dtFechaDesde.Date then Exit;
  if chkUsaFechaHasta.Checked and (Row.FechaCompromiso <> 0) then
    if Row.FechaCompromiso > dtFechaHasta.Date then Exit;

  Result := True;
end;

procedure TfrmBacklog.ApplyRowsToGrid;
var
  I, RowIdx, K: Integer;
  Key, S: string;
  Col: TcxGridColumn;
  Row: TBacklogRow;
  V: Variant;
  FilteredList: TList<Integer>;
begin
  FilteredList := TList<Integer>.Create;
  tvBacklog.BeginUpdate;
  try
    tvBacklog.DataController.RecordCount := 0;
    RowIdx := 0;
    for I := 0 to FRows.Count - 1 do
    begin
      Row := FRows[I];
      if not PassesFilter(Row) then Continue;

      FilteredList.Add(I);
      tvBacklog.DataController.RecordCount := RowIdx + 1;
      for K := 0 to tvBacklog.ColumnCount - 1 do
      begin
        Col := tvBacklog.Columns[K];
        if not FColKeyByTag.TryGetValue(Col.Tag, Key) then Continue;

        if Key = 'TipoOrigen' then
        begin
          // Mapeo CHAR(3) -> etiqueta legible (OF/PEDIDO/PROYECTO). Los nodos
          // manuales no tienen TipoOrigen: se etiquetan por su Origen='MANUAL'.
          S := UpperCase(Trim(Row.TipoOrigen));
          if      UpperCase(Trim(Row.Origen)) = 'MANUAL' then
                            tvBacklog.DataController.Values[RowIdx, Col.Index] := 'MANUAL'
          else if S = 'OF'  then tvBacklog.DataController.Values[RowIdx, Col.Index] := 'OF'
          else if S = 'PED' then tvBacklog.DataController.Values[RowIdx, Col.Index] := 'PEDIDO'
          else if S = 'PRJ' then tvBacklog.DataController.Values[RowIdx, Col.Index] := 'PROYECTO'
          else                   tvBacklog.DataController.Values[RowIdx, Col.Index] := S;
        end
        else if Key = 'CodigoDocumento' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.CodigoDocumento
        else if Key = 'DescripcionArticulo' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.DescripcionArticulo
        else if Key = 'CodigoArticulo' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.CodigoArticulo
        else if Key = 'Cantidad' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.Cantidad
        else if Key = 'UnidadMedida' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.UnidadMedida
        else if Key = 'NombreCliente' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.NombreCliente
        else if Key = 'CodigoProyecto' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.CodigoProyecto
        else if Key = 'NumeroOF' then
        begin
          if Row.NumeroOF = 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.NumeroOF;
        end
        else if Key = 'SerieOF' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.SerieOF
        else if Key = 'CodigoOT' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.CodigoOT
        else if Key = 'CodigoOP' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.CodigoOP
        else if Key = 'FechaCompromiso' then
        begin
          if Row.FechaCompromiso = 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.FechaCompromiso;
        end
        else if Key = 'FechaNecesaria' then
        begin
          if Row.FechaNecesaria = 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.FechaNecesaria;
        end
        else if Key = 'FechaEntrega' then
        begin
          if Row.FechaEntrega = 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.FechaEntrega;
        end
        else if Key = 'Prioridad' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.Prioridad
        else if Key = 'CentroPreferente' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.CentroPreferente
        else if Key = 'HorasEstimadas' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.HorasEstimadas
        else if Key = 'EstadoERP' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.EstadoERP
        else if Key = 'Orden' then
        begin
          if Row.Orden = 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.Orden;
        end
        else if Key = 'NumOpsPendientes' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.NumOpsPendientes
        else if Key = 'NumOpsTotal' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.NumOpsTotal
        else if Key = 'DuracionPrevistaMin' then
        begin
          // Se almacena en minutos; se muestra en horas (1 decimal).
          if Row.DuracionPrevistaMin <= 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] :=
              Round(Row.DuracionPrevistaMin / 6.0) / 10.0;
        end
        else if Key = 'FechaCompromisoMin' then
        begin
          if Row.FechaCompromisoMin = 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.FechaCompromisoMin;
        end
        else if Key = 'OpTiempoPreparacion' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := FloatOrNull(Row.OpTiempoPreparacion)
        else if Key = 'OpTiempoFabricacion' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := FloatOrNull(Row.OpTiempoFabricacion)
        else if Key = 'OpUnidadesHora' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := FloatOrNull(Row.OpUnidadesHora)
        else if Key = 'OpCosteHoraMaquina' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := FloatOrNull(Row.OpCosteHoraMaquina)
        else if Key = 'OpCosteHoraManoObra' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := FloatOrNull(Row.OpCosteHoraManoObra)
        else if Key = 'OpUnidadesFabricadas' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := FloatOrNull(Row.OpUnidadesFabricadas)
        else if Key = 'OpFechaInicioReal' then
        begin
          if Row.OpFechaInicioReal = 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.OpFechaInicioReal;
        end
        else if Key = 'OpFechaFinalReal' then
        begin
          if Row.OpFechaFinalReal = 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.OpFechaFinalReal;
        end
        else if Key = 'OpOperacionExterna' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.OpOperacionExterna
        else if Key = 'OpCodigoProveedor' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.OpCodigoProveedor
        else if Key = 'OpSeccionFabrica' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.OpSeccionFabrica
        else if Key = 'OpStatusPlanificado' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.OpStatusPlanificado
        else if Key = 'OpObservaciones' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.OpObservaciones
        else if Key = 'OpPctParaSigOperacion' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := FloatOrNull(Row.OpPctParaSigOperacion)
        else if Key = 'OpPctDedicacionOperario' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := FloatOrNull(Row.OpPctDedicacionOperario)
        else if Key = 'OrigenERP' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.OrigenERP
        else if Key = 'ClaveERP' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.ClaveERP
        else if Key = 'NodeInicio' then
        begin
          if Row.NodeInicio = 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.NodeInicio;
        end
        else if Key = 'NodeFin' then
        begin
          if Row.NodeFin = 0 then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.NodeFin;
        end
        else if Key = 'NodeCentroNombre' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.NodeCentroNombre
        else if Key = 'Progreso' then
          // Indicador de progreso: OP planificadas / total del documento.
          tvBacklog.DataController.Values[RowIdx, Col.Index] :=
            Format('%d / %d', [Row.NumOpsPlan, Row.NumOpsTotal])
        else if Key = 'NumCentros' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.NumCentros
        else if Copy(Key, 1, 2) = 'X:' then
        begin
          if (Row.Extras <> nil) and Row.Extras.TryGetValue(Copy(Key, 3, MaxInt), V) then
            tvBacklog.DataController.Values[RowIdx, Col.Index] := V
          else
            tvBacklog.DataController.Values[RowIdx, Col.Index] := Null;
        end;
      end;
      Inc(RowIdx);
    end;
    FFilteredIndices := FilteredList.ToArray;
  finally
    tvBacklog.EndUpdate;
    FilteredList.Free;
  end;
  UpdateCountLabel;
  UpdateImpacto;
end;

procedure TfrmBacklog.UpdateCountLabel;
var
  Total, Sel: Integer;
begin
  Total := Length(FFilteredIndices);
  Sel := tvBacklog.Controller.SelectedRowCount;
  if Sel > 0 then
    lblCountRegs.Caption := Format('%d registros  (%d seleccionados)', [Total, Sel])
  else
    lblCountRegs.Caption := Format('%d registros', [Total]);
end;

// ---------------------------------------------------------------------------
// Impacto (version basica - sera ampliada con calendarios/torns en Pas 3)
// ---------------------------------------------------------------------------
procedure TfrmBacklog.tvBacklogSelectionChanged(Sender: TcxCustomGridTableView);
begin
  UpdateCountLabel;
  UpdateImpacto;
end;

procedure TfrmBacklog.tvBacklogCellDblClick(Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
  AShift: TShiftState; var AHandled: Boolean);
var
  RecIdx: Integer;
begin
  // Doble-clic en una fila de OF abre el Visor de OF (jerarquia OF/OT/OP).
  // No interferir con la columna de botones "Ver" (que tiene su propio editor).
  if AButton <> mbLeft then Exit;

  // Usar el RecordIndex de la CELDA clicada (no FocusedRecordIndex): con sort u
  // orden activo el foco puede no coincidir con la fila pulsada y se abria la OF
  // de OTRA fila. ACellViewInfo apunta exactamente a la fila del doble-clic.
  RecIdx := -1;
  if (ACellViewInfo <> nil) and (ACellViewInfo.GridRecord <> nil) then
    RecIdx := ACellViewInfo.GridRecord.RecordIndex;

  VerOFActual(RecIdx);
  AHandled := True;
end;

// ---------------------------------------------------------------------------
// Resuelve el RawItemId al que aplica un campo custom para una fila concreta,
// segun el AppliesToNivel definido en el catalogo (mismo mapeo que BuildSQL).
// ---------------------------------------------------------------------------
function TfrmBacklog.ResolveExtraRawItemId(const Row: TBacklogRow;
  const ColDef: TCustomColumnDef): Int64;
var
  TargetNivel, Diff: Integer;
begin
  // Nivel objetivo del campo. 0 = no especificado -> usamos el nivel del leaf.
  TargetNivel := ColDef.AppliesToNivel;
  if TargetNivel = 0 then TargetNivel := Row.Nivel;

  // Cuantos saltos hacia el padre necesitamos: si la fila ya esta en el
  // nivel objetivo, ninguno; si esta mas profundo, subimos.
  Diff := Row.Nivel - TargetNivel;
  case Diff of
    0: Result := Row.RawId;            // mismo nivel
    1: Result := Row.ParentRawItemId;  // padre
    2: Result := Row.GrandRawItemId;   // abuelo
  else
    // Diff < 0 -> el campo aplica a un nivel mas profundo que la fila actual,
    // que no tiene sentido (un campo de OP no puede vivir en una OF leaf sin
    // OPs hijas). Diff > 2 -> mas de 3 niveles, no aplica al modelo actual.
    Result := 0;
  end;
end;

procedure TfrmBacklog.Restablecer1Click(Sender: TObject);
begin
  if MessageDlg('Restablecer layout por defecto del grid?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    ResetLayout;
end;

// ---------------------------------------------------------------------------
// Encode/Decode FieldValue: garantiza formato invariant en BD para que un
// numero/fecha/bool guardado en una cultura se lea identico en otra.
// ---------------------------------------------------------------------------
function TfrmBacklog.EncodeFieldValue(ADataType: Char; const V: Variant): string;
var
  D: Double;
  Dt: TDateTime;
begin
  Result := '';
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  case UpCase(ADataType) of
    'N':
      begin
        // Numerico: formato invariant ('.' decimal, sin separador de miles).
        D := V;
        Result := FloatToStr(D, TFormatSettings.Invariant);
      end;
    'D':
      begin
        // Fecha: ISO 8601.
        Dt := V;
        Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', Dt);
      end;
    'B':
      begin
        if Boolean(V) then Result := '1' else Result := '0';
      end;
  else
    // Texto: tal cual.
    Result := VarToStr(V);
  end;
end;

function TfrmBacklog.DecodeFieldValue(ADataType: Char; const S: string): Variant;
var
  D: Double;
  Dt: TDateTime;
begin
  Result := Null;
  if S = '' then Exit;
  case UpCase(ADataType) of
    'N':
      begin
        // Primero invariant ('.' decimal, formato actual). Fallback al regional
        // para tolerar valores antiguos guardados con FormatSettings local.
        if TryStrToFloat(S, D, TFormatSettings.Invariant) then
          Result := D
        else if TryStrToFloat(S, D) then
          Result := D
        else
          Result := Null;
      end;
    'D':
      begin
        // Aceptamos ISO 8601 o, como fallback, el formato regional.
        if TryStrToDateTime(S, Dt, TFormatSettings.Invariant) then
          Result := Dt
        else if TryStrToDateTime(S, Dt) then
          Result := Dt
        else
          Result := Null;
      end;
    'B':
      begin
        Result := (S = '1') or SameText(S, 'true');
      end;
  else
    Result := S;
  end;
end;

// ---------------------------------------------------------------------------
// UPSERT a FS_PL_RawItem_Extra con Source='MANUAL'.
// Si Value es Null/'' borra el override (volver al valor que aporte el ERP).
// ---------------------------------------------------------------------------
procedure TfrmBacklog.SaveCustomFieldValue(ARawItemId: Int64;
  const FieldKey: string; ADataType: Char; const Value: Variant);
var
  Cmd: TADOCommand;
  IsEmpty: Boolean;
  StrVal: string;
begin
  if ARawItemId <= 0 then
  begin
    ShowMessage('No se puede guardar el valor: la fila no tiene un Raw_Item asociado al nivel solicitado.');
    Exit;
  end;

  IsEmpty := VarIsNull(Value) or VarIsEmpty(Value);
  if not IsEmpty then
  begin
    StrVal := EncodeFieldValue(ADataType, Value);
    if Trim(StrVal) = '' then IsEmpty := True;
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    if IsEmpty then
    begin
      Cmd.CommandText :=
        'DELETE FROM FS_PL_RawItem_Extra ' +
        'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
        '  AND RawItemId = ' + IntToStr(ARawItemId) +
        '  AND FieldKey = ' + QStr(FieldKey) +
        '  AND Source = ''MANUAL''';
      Cmd.Execute;
    end
    else
    begin
      // MERGE upsert: respeta filas con Source='ERP' sobreescribiendolas con MANUAL.
      // Importante: ADO/OLEDB usa parametros posicionales (?). Para no tener que
      // duplicarlos, los pasamos UNA SOLA VEZ via la fuente del USING.
      Cmd.CommandText :=
        'MERGE FS_PL_RawItem_Extra AS T ' +
        'USING (SELECT ' + IntToStr(EmpresaCode) + ' AS CodigoEmpresa, ' +
        IntToStr(ARawItemId) + ' AS RawItemId, ' +
        QStr(FieldKey) + ' AS FieldKey, ' +
        '       :V AS FieldValue, :U AS UpdatedBy) AS S ' +
        '  ON T.CodigoEmpresa = S.CodigoEmpresa AND T.RawItemId = S.RawItemId AND T.FieldKey = S.FieldKey ' +
        'WHEN MATCHED THEN UPDATE SET ' +
        '  FieldValue = S.FieldValue, Source = ''MANUAL'', ' +
        '  UpdatedBy = S.UpdatedBy, UpdatedAt = SYSUTCDATETIME() ' +
        'WHEN NOT MATCHED THEN INSERT (CodigoEmpresa, RawItemId, FieldKey, FieldValue, Source, UpdatedBy, UpdatedAt) ' +
        '  VALUES (S.CodigoEmpresa, S.RawItemId, S.FieldKey, S.FieldValue, ''MANUAL'', S.UpdatedBy, SYSUTCDATETIME());';
      Cmd.Parameters.Clear;
      with Cmd.Parameters.AddParameter do
      begin
        Name := 'V';
        DataType := ftWideMemo;
        Direction := pdInput;
        Value := StrVal;
      end;
      with Cmd.Parameters.AddParameter do
      begin
        Name := 'U';
        DataType := ftWideString;
        Direction := pdInput;
        Value := UserLogin;
      end;
      Cmd.Execute;
    end;
  finally
    Cmd.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Handler de edicion inline para columnas custom.
// ---------------------------------------------------------------------------
procedure TfrmBacklog.tvBacklogCustomEditValueChanged(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem);
var
  Key, ColumnKey: string;
  RecIdx, RowIdx, I: Integer;
  Row: TBacklogRow;
  ColDef: TCustomColumnDef;
  Found: Boolean;
  RawItemId: Int64;
  NewVal: Variant;
begin
  if AItem = nil then Exit;
  if not FColKeyByTag.TryGetValue(AItem.Tag, Key) then Exit;
  if Copy(Key, 1, 2) <> 'X:' then Exit;

  ColumnKey := Copy(Key, 3, MaxInt);
  Found := False;
  ColDef := Default(TCustomColumnDef);
  for I := 0 to High(FCustomCols) do
    if SameText(FCustomCols[I].ColumnKey, ColumnKey) then
    begin
      ColDef := FCustomCols[I];
      Found := True;
      Break;
    end;
  if not Found then Exit;

  RecIdx := Sender.Controller.FocusedRecordIndex;
  if (RecIdx < 0) or (RecIdx > High(FFilteredIndices)) then Exit;
  RowIdx := FFilteredIndices[RecIdx];
  if (RowIdx < 0) or (RowIdx >= FRows.Count) then Exit;

  Row := FRows[RowIdx];

  if (ColDef.SourceEntity = 'OF')       and (Trim(Row.TipoOrigen) <> 'OF')  then Exit;
  if (ColDef.SourceEntity = 'PEDIDO')   and (Trim(Row.TipoOrigen) <> 'PED') then Exit;
  if (ColDef.SourceEntity = 'PROYECTO') and (Trim(Row.TipoOrigen) <> 'PRJ') then Exit;

  RawItemId := ResolveExtraRawItemId(Row, ColDef);

  // En DevExpress, AItem.EditValue suele ser el valor cacheado del controller,
  // que durante OnEditValueChanged aun esta vacio. El valor "en vivo" del
  // editor activo se obtiene del EditingController. Si no hay edicion activa
  // (p.ej. checkbox que se commitea inmediato), caemos a AItem.EditValue.
  NewVal := Null;
  if (Sender.Controller <> nil) and
     (Sender.Controller.EditingController <> nil) and
     (Sender.Controller.EditingController.Edit <> nil) then
    NewVal := Sender.Controller.EditingController.Edit.EditingValue;
  if VarIsNull(NewVal) or VarIsEmpty(NewVal) then
    NewVal := AItem.EditValue;

  // Diagnostico temporal: si el RawItemId resuelve a 0/negativo, el guardado
  // se cancela silenciosamente y el usuario no entiende por que no persiste.
  if RawItemId <= 0 then
  begin
    ShowMessage(
      'No se puede guardar "' + ColDef.Caption + '" en esta fila.' + sLineBreak +
      sLineBreak +
      'Motivo: la columna esta definida a nivel ' + IntToStr(ColDef.AppliesToNivel) +
      ' (entidad ' + ColDef.SourceEntity + ') pero la fila actual es de nivel ' +
      IntToStr(Row.Nivel) + ' (' + Row.TipoOrigen + ').' + sLineBreak +
      'No hay ancestro al nivel solicitado.');
    Exit;
  end;

  try
    SaveCustomFieldValue(RawItemId, ColDef.FieldKey, ColDef.DataType, NewVal);
    // Reflejar el nuevo valor en la fila en memoria para no recargar todo.
    if Row.Extras = nil then
      Row.Extras := TDictionary<string, Variant>.Create;
    if VarIsNull(NewVal) or VarIsEmpty(NewVal) or (VarToStr(NewVal) = '') then
      Row.Extras.AddOrSetValue(ColumnKey, Null)
    else
      Row.Extras.AddOrSetValue(ColumnKey, NewVal);
    FRows[RowIdx] := Row;
    // El recordset cacheado de este (tab,nivel) queda desactualizado respecto al
    // valor recien editado: invalidar para que el proximo toggle relea de BD.
    InvalidateDataCache;
  except
    on E: Exception do
      ShowMessage('No se pudo guardar el valor: ' + E.Message);
  end;
end;

procedure TfrmBacklog.UpdateImpacto;
var
  I, SelCount, FueraPlazo, Sats: Integer;
  RecIdx, RowIdx, GridIdx: Integer;
  TotalHoras: Double;
  FechaMax, WindowEnd: TDateTime;
  Cargas: TDictionary<string, Double>;
  CentreByCode: TDictionary<string, TCentreTreball>;
  Row: TBacklogRow;
  Key: string;
  Pair: TPair<string, Double>;
  Centres: TArray<TCentreTreball>;
  C: TCentreTreball;
  Cal: TCentreCalendar;
  Lanes: Integer;
  CapacitatMin: Integer;
  CapacitatHoras, PctOcup: Double;
begin
  SelCount := 0;
  TotalHoras := 0;
  FechaMax := 0;
  FueraPlazo := 0;

  Cargas := TDictionary<string, Double>.Create;
  CentreByCode := TDictionary<string, TCentreTreball>.Create;
  try
    if DMPlanner.CentresRepo <> nil then
    begin
      Centres := DMPlanner.CentresRepo.GetAll;
      for C in Centres do
        CentreByCode.AddOrSetValue(UpperCase(Trim(C.CodiCentre)), C);
    end;

    for I := 0 to tvBacklog.Controller.SelectedRowCount - 1 do
    begin
      RecIdx := tvBacklog.Controller.SelectedRows[I].RecordIndex;
      if (RecIdx < 0) or (RecIdx > High(FFilteredIndices)) then Continue;
      RowIdx := FFilteredIndices[RecIdx];
      if (RowIdx < 0) or (RowIdx >= FRows.Count) then Continue;

      Row := FRows[RowIdx];
      Inc(SelCount);
      TotalHoras := TotalHoras + Row.HorasEstimadas;

      Key := Row.CentroPreferente;
      if Trim(Key) = '' then Key := '(sin centro)';
      if Cargas.ContainsKey(Key) then
        Cargas[Key] := Cargas[Key] + Row.HorasEstimadas
      else
        Cargas.Add(Key, Row.HorasEstimadas);

      if Row.FechaCompromiso <> 0 then
      begin
        if Row.FechaCompromiso > FechaMax then FechaMax := Row.FechaCompromiso;
        if Row.FechaCompromiso < Now then Inc(FueraPlazo);
      end;
    end;

    // Ventana de capacidad
    if FechaMax <= Now then
      WindowEnd := IncDay(Now, 30)
    else
      WindowEnd := FechaMax;

    // Llenar grid de detalle por centro y calcular centros saturados
    Sats := 0;
    tvCargaCentro.BeginUpdate;
    try
      tvCargaCentro.DataController.RecordCount := 0;
      GridIdx := 0;
      for Pair in Cargas do
      begin
        CapacitatHoras := -1;
        if (Pair.Key <> '(sin centro)') and
           CentreByCode.TryGetValue(UpperCase(Trim(Pair.Key)), C) then
        begin
          if C.IsSequencial then Lanes := 1
          else if C.MaxLaneCount <= 0 then Lanes := 1
          else Lanes := C.MaxLaneCount;

          Cal := DMPlanner.CentresRepo.GetCalendarFor(C.Id);
          if Cal <> nil then
          begin
            CapacitatMin := Cal.WorkingMinutesBetween(Now, WindowEnd);
            CapacitatHoras := (CapacitatMin / 60.0) * Lanes;
          end;
        end;

        tvCargaCentro.DataController.RecordCount := GridIdx + 1;
        tvCargaCentro.DataController.Values[GridIdx, colCCCentro.Index] := Pair.Key;
        tvCargaCentro.DataController.Values[GridIdx, colCCHoras.Index] :=
          Format('%.1f', [Pair.Value]);
        if CapacitatHoras >= 0 then
        begin
          tvCargaCentro.DataController.Values[GridIdx, colCCCapacidad.Index] :=
            Format('%.1f', [CapacitatHoras]);
          if CapacitatHoras > 0 then
            PctOcup := (Pair.Value / CapacitatHoras) * 100
          else
            PctOcup := 100;
          tvCargaCentro.DataController.Values[GridIdx, colCCPct.Index] := PctOcup;
          if Pair.Value > CapacitatHoras then Inc(Sats);
        end
        else
        begin
          tvCargaCentro.DataController.Values[GridIdx, colCCCapacidad.Index] := '-';
          tvCargaCentro.DataController.Values[GridIdx, colCCPct.Index] := Null;
        end;
        Inc(GridIdx);
      end;
    finally
      tvCargaCentro.EndUpdate;
    end;

    // Resumen vertical grid
    vgResumen.BeginUpdate;
    try
      rowSelCount.Properties.Value := SelCount;
      rowSelHoras.Properties.Value := Format('%.2f h', [TotalHoras]);
      if FechaMax = 0 then
        rowFechaFinEst.Properties.Value := '-'
      else
        rowFechaFinEst.Properties.Value := FormatDateTime('dd/mm/yyyy', FechaMax);
      rowOFsFueraPlazo.Properties.Value := FueraPlazo;
      rowCentrosSat.Properties.Value := Sats;
      rowVentana.Properties.Value :=
        FormatDateTime('dd/mm', Now) + ' - ' + FormatDateTime('dd/mm/yyyy', WindowEnd);
    finally
      vgResumen.EndUpdate;
    end;
  finally
    Cargas.Free;
    CentreByCode.Free;
  end;
end;

procedure TfrmBacklog.tvCargaCentroCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  Pct: Double;
  V: Variant;
  R, BarRect: TRect;
  Col: TcxGridColumn;
  BarColor, BgColor: TColor;
  W: Integer;
  Txt: string;
begin
  ADone := False;
  if not (AViewInfo.Item is TcxGridColumn) then Exit;
  Col := TcxGridColumn(AViewInfo.Item);
  if Col <> colCCPct then Exit;

  V := AViewInfo.Value;
  if VarIsNull(V) or VarIsEmpty(V) then Exit;
  try
    Pct := Double(V);
  except
    Exit;
  end;

  R := AViewInfo.Bounds;

  // Fondo gris claro
  BgColor := $00E8E8E8;
  ACanvas.FillRect(R, BgColor);

  // Color barra segun ocupacion
  if Pct < 70 then      BarColor := $0070C070   // verde
  else if Pct < 95 then BarColor := $0030A0E0   // azul
  else if Pct <= 100 then BarColor := $0020B0E0 // mostaza ok
  else                  BarColor := $004040D0;  // rojo (BGR)

  W := Round((R.Right - R.Left) * (Pct / 100.0));
  if W < 0 then W := 0;
  if W > (R.Right - R.Left) then W := R.Right - R.Left;

  BarRect := R;
  BarRect.Right := R.Left + W;
  ACanvas.FillRect(BarRect, BarColor);

  // Borde
  ACanvas.Canvas.Pen.Color := $00C0C0C0;
  ACanvas.Canvas.Brush.Style := bsClear;
  ACanvas.Canvas.Rectangle(R.Left, R.Top, R.Right, R.Bottom);

  // Texto centrado con porcentaje
  Txt := Format('%.0f %%', [Pct]);
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Color := clBlack;
  ACanvas.DrawText(Txt, R, cxAlignCenter or cxAlignVCenter or cxSingleLine);

  ADone := True;
end;

// ---------------------------------------------------------------------------
// Persistencia del layout del grid (por usuario)
// ---------------------------------------------------------------------------
procedure TfrmBacklog.LoadUserLayout;
var
  Q: TADOQuery;
  MS: TMemoryStream;
  Bytes: TBytes;
  LayoutStr: string;
begin
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT LayoutData FROM FS_PL_Cfg_UserGridLayout ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND UserId = ' + QStr(UserLogin) +
      '  AND GridId = ''' + BACKLOG_GRID_ID + '''';
    Q.Open;
    if not Q.Eof then
    begin
      LayoutStr := Q.FieldByName('LayoutData').AsString;
      if LayoutStr <> '' then
      begin
        try
          // Datos guardados con SaveUserLayout (Base64 sobre bytes binarios).
          Bytes := TNetEncoding.Base64.DecodeStringToBytes(LayoutStr);
          MS := TMemoryStream.Create;
          try
            if Length(Bytes) > 0 then
              MS.WriteBuffer(Bytes[0], Length(Bytes));
            MS.Position := 0;
            tvBacklog.RestoreFromStream(MS);
          finally
            MS.Free;
          end;
        except
          // Si los datos antiguos no son Base64 validos, los ignoramos en
          // silencio y el usuario tendra el layout por defecto. La proxima
          // vez que pulse "Guardar layout" se reescribira en Base64.
        end;
      end;
    end;
  finally
    Q.Free;
  end;

  // Columnas nuevas que un layout antiguo (guardado antes de existir ellas)
  // pudo dejar ocultas: las forzamos visibles para que aparezcan. El usuario
  // puede reordenarlas/ocultarlas luego y se guardara a su gusto.
  EnsureNewColumnsVisible(['SerieOF', 'NumeroOF', 'Orden',
    'OpTiempoPreparacion', 'OpTiempoFabricacion', 'OpUnidadesHora',
    'OpCosteHoraMaquina', 'OpCosteHoraManoObra', 'OpUnidadesFabricadas',
    'OpFechaInicioReal', 'OpFechaFinalReal', 'OpOperacionExterna',
    'OpCodigoProveedor', 'OpSeccionFabrica', 'OpStatusPlanificado',
    'OpObservaciones', 'OpPctParaSigOperacion', 'OpPctDedicacionOperario']);
end;

// Marca como visibles las columnas cuyo Key este en AKeys (util tras restaurar
// un layout antiguo que no las contenia).
procedure TfrmBacklog.EnsureNewColumnsVisible(const AKeys: array of string);
var
  I, K: Integer;
  Key: string;
  Col: TcxGridColumn;
begin
  for I := 0 to tvBacklog.ColumnCount - 1 do
  begin
    Col := tvBacklog.Columns[I];
    if not FColKeyByTag.TryGetValue(Col.Tag, Key) then Continue;
    for K := 0 to High(AKeys) do
      if SameText(Key, AKeys[K]) then
      begin
        Col.Visible := True;
        Break;
      end;
  end;
end;

procedure TfrmBacklog.SaveUserLayout;
var
  Q: TADOQuery;
  MS: TMemoryStream;
  Bytes: TBytes;
  LayoutStr: string;
  Cmd: TADOCommand;
begin
  // DevExpress StoreToStream escribe bytes binarios (no texto UTF-8 valido).
  // Codificamos en Base64 para garantizar que el LayoutData sea ASCII puro y
  // sobreviva cualquier conversion ANSI/Unicode del provider OLEDB.
  MS := TMemoryStream.Create;
  try
    tvBacklog.StoreToStream(MS);
    SetLength(Bytes, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Bytes[0], MS.Size);
    end;
  finally
    MS.Free;
  end;
  LayoutStr := TNetEncoding.Base64.EncodeBytesToString(Bytes);

  Q := TADOQuery.Create(nil);
  Cmd := TADOCommand.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT 1 FROM FS_PL_Cfg_UserGridLayout ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND UserId = ' + QStr(UserLogin) +
      '  AND GridId = ''' + BACKLOG_GRID_ID + '''';
    Q.Open;

    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.Parameters.Clear;
    if Q.Eof then
    begin
      Cmd.CommandText :=
        'INSERT INTO FS_PL_Cfg_UserGridLayout ' +
        '(CodigoEmpresa, UserId, GridId, LayoutData, FechaModificacion) VALUES (' +
        IntToStr(EmpresaCode) + ', ' + QStr(UserLogin) + ', ''' + BACKLOG_GRID_ID +
        ''', :LayoutData, SYSUTCDATETIME())';
    end
    else
    begin
      Cmd.CommandText :=
        'UPDATE FS_PL_Cfg_UserGridLayout SET LayoutData = :LayoutData, ' +
        'FechaModificacion = SYSUTCDATETIME() ' +
        'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
        '  AND UserId = ' + QStr(UserLogin) +
        '  AND GridId = ''' + BACKLOG_GRID_ID + '''';
    end;
    // LayoutData es NVARCHAR(MAX): forzar el tipo del parametro a ftWideMemo
    // para evitar 'No mapping for the Unicode character' al pasar por ANSI.
    Cmd.Parameters.Clear;
    with Cmd.Parameters.AddParameter do
    begin
      Name := 'LayoutData';
      DataType := ftWideMemo;
      Direction := pdInput;
      Value := LayoutStr;
    end;
    Cmd.Execute;
  finally
    Q.Free;
    Cmd.Free;
  end;
end;

procedure TfrmBacklog.ResetLayout;
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_Cfg_UserGridLayout ' +
      'WHERE CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND UserId = ' + QStr(UserLogin) +
      '  AND GridId = ''' + BACKLOG_GRID_ID + '''';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
  tvBacklog.BeginUpdate;
  try
    BuildBaseColumns;
    BuildCustomColumns;
  finally
    tvBacklog.EndUpdate;
  end;
  ApplyRowsToGrid;
end;

// ---------------------------------------------------------------------------
// Boto "Ver" - obre el form modal de detall (segons TipoOrigen)
// ---------------------------------------------------------------------------

function TfrmBacklog.GetRowFromGridIndex(AGridIdx: Integer): Integer;
begin
  Result := -1;
  if (AGridIdx < 0) or (AGridIdx > High(FFilteredIndices)) then Exit;
  Result := FFilteredIndices[AGridIdx];
end;

// Abre el Visor de OF para la fila enfocada del grid. El visor resuelve la OF
// raiz a partir del RawId (sea OF/OT/OP) y muestra toda la jerarquia.
procedure TfrmBacklog.VerOFActual(ARecordIndex: Integer);
var
  GridIdx, RowIdx: Integer;
  Row: TBacklogRow;
begin
  // ARecordIndex < 0 (llamada sin fila concreta, p.ej. desde un boton): caemos
  // al record enfocado. En el doble-clic siempre llega el RecordIndex de la celda.
  if ARecordIndex >= 0 then
    GridIdx := ARecordIndex
  else
    GridIdx := tvBacklog.Controller.FocusedRecordIndex;
  RowIdx := GetRowFromGridIndex(GridIdx);
  if (RowIdx < 0) or (RowIdx >= FRows.Count) then
  begin
    ShowMessage('Selecciona una fila del backlog para ver su OF.');
    Exit;
  end;
  Row := FRows[RowIdx];

  // Nodo manual (no tiene OF detras): abrimos el NodeInspector en consulta.
  if UpperCase(Trim(Row.Origen)) = 'MANUAL' then
  begin
    VerNodeManual(Row.NodeId);
    Exit;
  end;

  if Trim(Row.TipoOrigen) <> 'OF' then
  begin
    ShowMessage('El visor de OF solo aplica a filas de '#243'rdenes de fabricaci'#243'n.');
    Exit;
  end;
  if Row.RawId <= 0 then
  begin
    ShowMessage('Esta fila no tiene un identificador v'#225'lido.');
    Exit;
  end;
  TfrmOFViewer.Execute(Row.RawId);
end;

// Abre el NodeInspector (solo lectura) para un nodo manual del tab Planificados.
// Lee el TNodeData de BD por NodeId; la edicion real del nodo se hace en el Gantt.
procedure TfrmBacklog.VerNodeManual(ANodeId: Integer);
var
  D: TNodeData;
  Q: TADOQuery;
  Ini, Fin: TDateTime;
begin
  if ANodeId <= 0 then
  begin
    ShowMessage('Este nodo manual no tiene un identificador v'#225'lido.');
    Exit;
  end;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT n.FechaInicio, n.FechaFin, ' +
      '  ISNULL(nd.Operacion, ISNULL(n.Caption, '''')) AS Operacion, ' +
      '  ISNULL(nd.DuracionMin, n.DuracionMin) AS DuracionMin, ' +
      '  ISNULL(nd.DuracionMinOriginal, n.DuracionMin) AS DuracionMinOriginal, ' +
      '  nd.FechaEntrega, nd.FechaNecesaria, ' +
      '  ISNULL(nd.CodigoArticulo, '''') AS CodigoArticulo, ' +
      '  ISNULL(nd.DescripcionArticulo, '''') AS DescripcionArticulo, ' +
      '  ISNULL(nd.CodigoCliente, '''') AS CodigoCliente, ' +
      '  ISNULL(nd.Prioridad, 0) AS Prioridad, ' +
      '  ISNULL(nd.Estado, 0) AS Estado, ' +
      '  ISNULL(nd.OperariosNecesarios, 0) AS OperariosNecesarios, ' +
      '  ISNULL(nd.OperariosAsignados, 0) AS OperariosAsignados, ' +
      '  ISNULL(nd.LibreMovimiento, 1) AS LibreMovimiento ' +
      'FROM FS_PL_Node n ' +
      'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
      '  AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '  AND n.NodeId = ' + IntToStr(ANodeId);
    Q.Open;
    if Q.Eof then
    begin
      ShowMessage('No se ha encontrado el nodo manual.');
      Exit;
    end;

    FillChar(D, SizeOf(D), 0);
    D.DataId := ANodeId;
    D.Operacion := Q.FieldByName('Operacion').AsString;
    D.DurationMin := Q.FieldByName('DuracionMin').AsFloat;
    D.DurationMinOriginal := Q.FieldByName('DuracionMinOriginal').AsFloat;
    if not Q.FieldByName('FechaEntrega').IsNull then
      D.FechaEntrega := Q.FieldByName('FechaEntrega').AsDateTime;
    if not Q.FieldByName('FechaNecesaria').IsNull then
      D.FechaNecesaria := Q.FieldByName('FechaNecesaria').AsDateTime;
    D.CodigoArticulo := Q.FieldByName('CodigoArticulo').AsString;
    D.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
    D.CodigoCliente := Q.FieldByName('CodigoCliente').AsString;
    D.Prioridad := Q.FieldByName('Prioridad').AsInteger;
    D.Estado := TNodoEstado(Q.FieldByName('Estado').AsInteger);
    D.OperariosNecesarios := Q.FieldByName('OperariosNecesarios').AsInteger;
    D.OperariosAsignados := Q.FieldByName('OperariosAsignados').AsInteger;
    D.LibreMoviment := Q.FieldByName('LibreMovimiento').AsBoolean;
    Ini := Q.FieldByName('FechaInicio').AsDateTime;
    Fin := Q.FieldByName('FechaFin').AsDateTime;
  finally
    Q.Free;
  end;

  // Read-only (consulta) + marcado como MANUAL. La edicion se hace en el Gantt.
  TfrmNodeInspector.Execute(D, Ini, Fin, True, nil, True);
end;

procedure TfrmBacklog.Guardar1Click(Sender: TObject);
begin
  SaveUserLayout;
  ShowMessage('Layout guardado para el usuario actual.');
end;

procedure TfrmBacklog.OnColVerButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  GridIdx, RowIdx: Integer;
  Row: TBacklogRow;
  Tipo: string;
  Cfg: TErpSage200Config;
begin
  GridIdx := tvBacklog.Controller.FocusedRecordIndex;
  RowIdx := GetRowFromGridIndex(GridIdx);
  if (RowIdx < 0) or (RowIdx >= FRows.Count) then Exit;
  Row := FRows[RowIdx];

  // Boto 1 = Ver formula del article (el reader resol la connexio i empresa)
  if AButtonIndex = 1 then
  begin
    if Trim(Row.CodigoArticulo) = '' then
    begin
      ShowMessage('Esta fila no tiene art'#237'culo asociado.');
      Exit;
    end;
    TfrmFormulaArticuloViewer.Execute(Row.CodigoArticulo);
    Exit;
  end;

  // Boto 0 = Ver Pedido/OF/Proyecto segons TipoOrigen
  Tipo := Trim(Row.TipoOrigen);
  if Tipo = 'PED' then
  begin
    if (Row.NumeroDoc <= 0) or (Trim(Row.SerieDoc) = '') then
    begin
      ShowMessage('Pedido sin n'#250'mero/serie identificable.');
      Exit;
    end;
    // L'ejercicio segueix venint del config Sage; quan IErpReader tingui
    // GetEjercicioActivo es mourà alla.
    Cfg := LoadErpSage200Config;
    TfrmPedidoDetalle.Execute(Cfg.Ejercicio, Row.SerieDoc, Row.NumeroDoc);
  end
  else if Tipo = 'OF' then
    ShowMessage('Detalle de OF: pr'#243'ximamente.')
  else if Tipo = 'PRJ' then
    ShowMessage('Detalle de proyecto: pr'#243'ximamente.')
  else
    ShowMessage('Tipo de origen no soportado: ' + Tipo);
end;

end.
