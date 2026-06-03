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
  cxInplaceContainer, cxVGrid,
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
  dxSkinXmas2008Blue, Vcl.Menus, cxButtons, dxGDIPlusClasses, cxImage;

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
    // Solo se rellenan en el tab Planificados (via FS_PL_vw_BacklogPlanned)
    NodeId: Integer;
    NodeInicio: TDateTime;
    NodeFin: TDateTime;
    NodeCodigoCentro: string;
    NodeCentroNombre: string;
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
    btnToggleImpacto: TButton;
    PopupMenu1: TPopupMenu;
    RegenerarNodosDemo1: TMenuItem;
    RegenerarBacklogDemo1: TMenuItem;
    btnSelectAll: TButton;
    btnDeselectAll: TButton;
    pnlSubTitulo: TPanel;
    btnDesplanificarSel: TButton;
    btnPlanificar: TButton;
    btnSyncErp: TcxButton;
    btnVerOF: TcxButton;
    btnDesplanificarTodo: TButton;
    PopupMenu2: TPopupMenu;
    Columnas1: TMenuItem;
    Configurar1: TMenuItem;
    Guardar1: TMenuItem;
    Restablecer1: TMenuItem;
    N3: TMenuItem;
    Vaciarylimpiartodalaplanificacin2: TMenuItem;
    imgSection: TcxImage;
    cxButton1: TcxButton;
    btnRecargar: TcxButton;
    lblCountRegs: TLabel;
    procedure btnSyncErpClick(Sender: TObject);
    procedure btnVerOFClick(Sender: TObject);
    procedure RegenerarNodosDemo1Click(Sender: TObject);
    procedure RegenerarBacklogDemo1Click(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnDeselectAllClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnPlanificarClick(Sender: TObject);
    procedure btnToggleImpactoClick(Sender: TObject);
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
    procedure btnDesplanificarSelClick(Sender: TObject);
    procedure btnDesplanificarTodoClick(Sender: TObject);
    procedure btnRecargarClick(Sender: TObject);
    procedure Configurar1Click(Sender: TObject);
    procedure Restablecer1Click(Sender: TObject);
    procedure Guardar1Click(Sender: TObject);
    procedure Vaciarylimpiartodalaplanificacin2Click(Sender: TObject);
  private
    FRows: TList<TBacklogRow>;
    FFilteredIndices: TArray<Integer>;   // FRows index per cada fila del grid
    FCustomCols: TArray<TCustomColumnDef>;
    FBaseColumns: TArray<TcxGridColumn>;
    FCustomColumns: TArray<TcxGridColumn>;
    FColKeyByTag: TDictionary<Integer, string>;
    FLoading: Boolean;
    FFirstShow: Boolean;

    procedure VerOFActual;
    procedure BuildBaseColumns;
    procedure LoadCustomColumnDefs;
    procedure BuildCustomColumns;
    procedure LoadData;
    procedure ApplyRowsToGrid;
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

    function CollectSelectedInputs: TArray<TSchedInput>;
    procedure CommitScheduling(const AResult: TSchedResult);

    procedure ApplyImpactoVisible(AVisible: Boolean);
    procedure ApplyTabMode;
    function IsPlanningTab: Boolean;
    function CollectSelectedNodeIds: TArray<Integer>;
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
  uBusyDialog,
  uBacklogSchedParams, uBacklogSchedPreview, uUserPrefs, uGenerarNodosDemo,
  uDemoBacklog, uBacklogRegenParams, uAppConfig, uPedidoDetalle,
  uFormulaArticuloViewer, Main,
  uErpReader, uErpReaderFactory, uSyncBacklogPreview, uOFViewer;

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

  LoadData;
  ShowMessage('Plan vaciado correctamente.');

end;

function TfrmBacklog.EmpresaCode: SmallInt;
begin
  Result := DMPlanner.CodigoEmpresa;
end;

procedure TfrmBacklog.FormCreate(Sender: TObject);
begin
  FRows := TList<TBacklogRow>.Create;
  FColKeyByTag := TDictionary<Integer, string>.Create;
  FLoading := True;
  try
    dtFechaDesde.Date := Date;
    dtFechaHasta.Date := IncMonth(Date, 3);
    cmbOrigen.ItemIndex := 0;

    tabMode.TabIndex := uUserPrefs.GetPrefInt(BACKLOG_MOD, 'TabIndex', 0);
    btnPlanificar.Visible := not IsPlanningTab;
    btnDesplanificarSel.Visible := IsPlanningTab;
    btnDesplanificarTodo.Visible := IsPlanningTab;
    Columnas1.Enabled := uLogin.IsAdmin;

    BuildBaseColumns;
    LoadCustomColumnDefs;
    BuildCustomColumns;
    LoadUserLayout;
    ApplyImpactoVisible(uUserPrefs.GetPrefBool(BACKLOG_MOD, 'ImpactoVisible', True));
  finally
    FLoading := False;
  end;
  FFirstShow := True;
end;

procedure TfrmBacklog.FormShow(Sender: TObject);
begin
  if not FFirstShow then Exit;
  FFirstShow := False;

  // El SELECT del backlog puede tardar varios segundos. Mostramos un dialogo
  // generico "Cargando..." que se pinta antes de bloquear el thread con la
  // query. El form se libera automaticamente al salir del bloque.
  uBusyDialog.ShowBusy(Self, 'Cargando datos del backlog...',
    procedure
    begin
      LoadData;
    end);
end;

procedure TfrmBacklog.FormDestroy(Sender: TObject);
begin
  ClearRows;
  FRows.Free;
  FColKeyByTag.Free;
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

function TfrmBacklog.CollectSelectedInputs: TArray<TSchedInput>;
var
  I, RecIdx, RowIdx: Integer;
  Row: TBacklogRow;
  L: TList<TSchedInput>;
  Input: TSchedInput;
begin
  L := TList<TSchedInput>.Create;
  try
    for I := 0 to tvBacklog.Controller.SelectedRowCount - 1 do
    begin
      RecIdx := tvBacklog.Controller.SelectedRows[I].RecordIndex;
      if (RecIdx < 0) or (RecIdx > High(FFilteredIndices)) then Continue;
      RowIdx := FFilteredIndices[RecIdx];
      if (RowIdx < 0) or (RowIdx >= FRows.Count) then Continue;

      Row := FRows[RowIdx];
      Input := Default(TSchedInput);
      Input.RawId := Row.RawId;
      Input.Origen := Row.Origen;
      Input.CodigoDocumento := Row.CodigoDocumento;
      Input.CentroPreferente := Row.CentroPreferente;
      Input.HorasEstimadas := Row.HorasEstimadas;
      Input.FechaCompromiso := Row.FechaCompromiso;
      Input.Prioridad := Row.Prioridad;

      Input.NumeroOF := 0;
      Input.SerieOF := '';
      Input.NumeroPedido := 0;
      Input.SeriePedido := '';
      // El check correcte es per familia ERP (TipoOrigen), no per nivell del leaf
      // (Origen). Per a una operacio Nivel=3, Origen val 'OP' i la familia pot
      // ser 'OF ', 'PED' o 'PRJ'. La view V048 ja propaga NumeroDoc/SerieDoc
      // heredats del pare per a Nivel=3.
      if Trim(Row.TipoOrigen) = 'OF' then
      begin
        Input.NumeroOF := Row.NumeroDoc;
        Input.SerieOF := Row.SerieDoc;
      end
      else if Trim(Row.TipoOrigen) = 'PED' then
      begin
        Input.NumeroPedido := Row.NumeroDoc;
        Input.SeriePedido := Row.SerieDoc;
      end;

      Input.CodigoCliente := Row.CodigoCliente;
      Input.CodigoArticulo := Row.CodigoArticulo;
      Input.DescripcionArticulo := Row.DescripcionArticulo;
      Input.UnidadesAFabricar := Row.Cantidad;
      Input.NumeroTrabajo := Row.CodigoProyecto;
      Input.FechaEntrega := Row.FechaCompromiso;
      Input.FechaNecesaria := Row.FechaNecesaria;
      Input.TiempoUnidadFabSecs := Row.TiempoUnidadFabSecs;

      // Link al modelo unificado Raw_Item (V016). La vista ya expone TipoOrigen.
      Input.RawItemClaveERP := Row.ClaveERP;
      Input.RawItemTipoOrigen := Row.TipoOrigen;

      L.Add(Input);
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmBacklog.CommitScheduling(const AResult: TSchedResult);
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  I: Integer;
  Item: TSchedOutput;
  CE, PID: string;
  NodeId: Integer;
  DurStr, FIniStr, FFinStr, CenterStr: string;
  UdsStr, FNecStr, FEntStr, TufStr: string;
  NumCreats: Integer;

  function QS(const S: string): string;
  begin
    Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
  end;

  function FmtDT(const T: TDateTime): string;
  begin
    Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', T) + '''';
  end;

  function QSOrNull(const S: string): string;
  begin
    if S = '' then Result := 'NULL' else Result := QS(S);
  end;

begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(DMPlanner.CurrentProjectId);
  NumCreats := 0;

  DMPlanner.ADOConnection.BeginTrans;
  try
    for I := 0 to High(AResult.Items) do
    begin
      Item := AResult.Items[I];
      // Solo planificamos los que tienen fechas y centro valido
      if (Item.Status = ssSinCentro) or (Item.Status = ssSinCalendario) then
        Continue;
      if (Item.FechaInicio = 0) or (Item.FechaFin = 0) then Continue;
      if Item.CenterId <= 0 then Continue;

      DurStr := FloatToStr(Item.DuracionMin, TFormatSettings.Invariant);
      FIniStr := FmtDT(Item.FechaInicio);
      FFinStr := FmtDT(Item.FechaFin);
      CenterStr := IntToStr(Item.CenterId);

      // Insert FS_PL_Node
      Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := DMPlanner.ADOConnection;
        Cmd.CommandText :=
          'INSERT INTO FS_PL_Node (CodigoEmpresa, ProjectId, CenterId, ' +
          '  FechaInicio, FechaFin, DuracionMin, Caption, ColorFondo, ColorBorde) VALUES (' +
          CE + ', ' + PID + ', ' + CenterStr + ', ' +
          FIniStr + ', ' + FFinStr + ', ' + DurStr + ', ' +
          QS(Item.Input.CodigoDocumento) + ', 15251072, 11166760)';
        Cmd.Execute;
      finally
        Cmd.Free;
      end;

      // Recuperar NodeId creado
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := DMPlanner.ADOConnection;
        Q.SQL.Text :=
          'SELECT MAX(NodeId) AS NewId FROM FS_PL_Node ' +
          'WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID;
        Q.Open;
        NodeId := Q.FieldByName('NewId').AsInteger;
      finally
        Q.Free;
      end;

      // Insert FS_PL_NodeData con NumeroOF / NumeroPedido para ligar al staging
      if Item.Input.UnidadesAFabricar > 0 then
        UdsStr := FloatToStr(Item.Input.UnidadesAFabricar, TFormatSettings.Invariant)
      else
        UdsStr := '1';
      if Item.Input.FechaEntrega > 0 then
        FEntStr := FmtDT(Item.Input.FechaEntrega)
      else
        FEntStr := 'NULL';
      if Item.Input.FechaNecesaria > 0 then
        FNecStr := FmtDT(Item.Input.FechaNecesaria)
      else if Item.Input.FechaCompromiso > 0 then
        FNecStr := FmtDT(Item.Input.FechaCompromiso)
      else
        FNecStr := 'NULL';
      if Item.Input.TiempoUnidadFabSecs > 0 then
        TufStr := FloatToStr(Item.Input.TiempoUnidadFabSecs, TFormatSettings.Invariant)
      else
        TufStr := '0';
      Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := DMPlanner.ADOConnection;
        Cmd.CommandText :=
          'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, ' +
          '  NumeroOF, SerieOF, NumeroPedido, SeriePedido, NumeroTrabajo, ' +
          '  FechaEntrega, FechaNecesaria, CodigoCliente, ' +
          '  CodigoArticulo, DescripcionArticulo, ' +
          '  DuracionMin, DuracionMinOriginal, ' +
          '  UnidadesAFabricar, TiempoUnidadFabSecs, ' +
          '  OperariosNecesarios, Prioridad, ' +
          '  RawItemClaveERP, RawItemTipoOrigen, ' +
          '  ColorFondoOp, ColorBordeOp) VALUES (' +
          CE + ', ' + IntToStr(NodeId) + ', ' + QS(Item.Input.CodigoDocumento) + ', ' +
          IntToStr(Item.Input.NumeroOF) + ', ' + QS(Item.Input.SerieOF) + ', ' +
          IntToStr(Item.Input.NumeroPedido) + ', ' + QS(Item.Input.SeriePedido) + ', ' +
          QS(Item.Input.NumeroTrabajo) + ', ' +
          FEntStr + ', ' + FNecStr + ', ' + QS(Item.Input.CodigoCliente) + ', ' +
          QS(Item.Input.CodigoArticulo) + ', ' + QS(Item.Input.DescripcionArticulo) + ', ' +
          DurStr + ', ' + DurStr + ', ' +
          UdsStr + ', ' + TufStr + ', 1, ' + IntToStr(Item.Input.Prioridad) + ', ' +
          QSOrNull(Item.Input.RawItemClaveERP) + ', ' +
          QSOrNull(Item.Input.RawItemTipoOrigen) + ', ' +
          '15251072, 11166760)';
        Cmd.Execute;
      finally
        Cmd.Free;
      end;

      Inc(NumCreats);
    end;

    DMPlanner.ADOConnection.CommitTrans;
  except
    on E: Exception do
    begin
      DMPlanner.ADOConnection.RollbackTrans;
      raise;
    end;
  end;

  ShowMessage(Format(
    'Planificacion confirmada: %d nodos creados en el plan actual.' + sLineBreak +
    'El Backlog se recargara.',
    [NumCreats]));
end;

procedure TfrmBacklog.Configurar1Click(Sender: TObject);
begin
  if uBacklogCustomCols.TfrmBacklogCustomCols.Execute then
  begin
    // Si ha habido altas/bajas/ediciones, recargar definiciones, columnas y datos.
    LoadCustomColumnDefs;
    BuildCustomColumns;
    LoadData;
  end;
end;

procedure TfrmBacklog.btnPlanificarClick(Sender: TObject);
var
  Inputs: TArray<TSchedInput>;
  Params: TSchedParams;
  SR: TSchedResult;
  MR: TModalResult;
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

  Inputs := CollectSelectedInputs;
  if Length(Inputs) = 0 then Exit;

  Params := Default(TSchedParams);
  while True do
  begin
    if not TfrmBacklogSchedParams.Execute(Params) then Exit;

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

    SR := RunAutoScheduling(Inputs, Params);
    MR := TfrmBacklogSchedPreview.Execute(SR);

    case MR of
      mrOk:
        begin
          try
            CommitScheduling(SR);
          except
            on E: Exception do
            begin
              ShowMessage('Error creando nodos: ' + E.Message);
              Exit;
            end;
          end;
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
  LoadData;
end;

procedure TfrmBacklog.btnVerOFClick(Sender: TObject);
begin
  VerOFActual;
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
    Reader.EnsureConnected;
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
    LoadData;
end;

procedure TfrmBacklog.RegenerarNodosDemo1Click(Sender: TObject);
begin
  if TfrmGenerarNodosDemo.Execute then
    LoadData;
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

  LoadData;
end;

procedure TfrmBacklog.ApplyImpactoVisible(AVisible: Boolean);
begin
  pnlImpacto.Visible := AVisible;
  if AVisible then
    btnToggleImpacto.Caption := 'Ocultar panel impacto'
  else
    btnToggleImpacto.Caption := 'Mostrar panel impacto';
end;

procedure TfrmBacklog.btnToggleImpactoClick(Sender: TObject);
var
  NewVis: Boolean;
begin
  NewVis := not pnlImpacto.Visible;
  ApplyImpactoVisible(NewVis);
  uUserPrefs.SetPrefBool(BACKLOG_MOD, 'ImpactoVisible', NewVis);
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
  btnDesplanificarTodo.Visible := IsPlanningTab;

  // Reconstruir columnas porque cambia el set base
  BuildBaseColumns;
  BuildCustomColumns;
  LoadUserLayout;

  // Recargar datos segun vista
  LoadData;
end;

procedure TfrmBacklog.tabModeChange(Sender: TObject);
begin
  if FLoading then Exit;
  uUserPrefs.SetPrefInt(BACKLOG_MOD, 'TabIndex', tabMode.TabIndex);
  ApplyTabMode;
end;

function TfrmBacklog.CollectSelectedNodeIds: TArray<Integer>;
var
  I, RecIdx, RowIdx: Integer;
  L: TList<Integer>;
begin
  L := TList<Integer>.Create;
  try
    for I := 0 to tvBacklog.Controller.SelectedRowCount - 1 do
    begin
      RecIdx := tvBacklog.Controller.SelectedRows[I].RecordIndex;
      if (RecIdx < 0) or (RecIdx > High(FFilteredIndices)) then Continue;
      RowIdx := FFilteredIndices[RecIdx];
      if (RowIdx < 0) or (RowIdx >= FRows.Count) then Continue;
      if FRows[RowIdx].NodeId > 0 then
        L.Add(FRows[RowIdx].NodeId);
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmBacklog.DoDesplanificar(const ANodeIds: TArray<Integer>);
var
  Cmd: TADOCommand;
  IdList: string;
  I: Integer;
  CE: string;
begin
  if Length(ANodeIds) = 0 then Exit;

  IdList := '';
  for I := 0 to High(ANodeIds) do
  begin
    if IdList <> '' then IdList := IdList + ',';
    IdList := IdList + IntToStr(ANodeIds[I]);
  end;

  CE := IntToStr(EmpresaCode);

  DMPlanner.ADOConnection.BeginTrans;
  try
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;

      // Borrar dependencias que referencian estos nodos
      Cmd.CommandText :=
        'DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa = ' + CE +
        ' AND (FromNodeId IN (' + IdList + ') OR ToNodeId IN (' + IdList + '))';
      Cmd.Execute;

      // Borrar asignaciones de operarios
      Cmd.CommandText :=
        'DELETE FROM FS_PL_OperatorAssignment WHERE CodigoEmpresa = ' + CE +
        ' AND NodeId IN (' + IdList + ')';
      Cmd.Execute;

      // Borrar NodeData
      Cmd.CommandText :=
        'DELETE FROM FS_PL_NodeData WHERE CodigoEmpresa = ' + CE +
        ' AND NodeId IN (' + IdList + ')';
      Cmd.Execute;

      // Borrar nodos
      Cmd.CommandText :=
        'DELETE FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE +
        ' AND NodeId IN (' + IdList + ')';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
    DMPlanner.ADOConnection.CommitTrans;
  except
    DMPlanner.ADOConnection.RollbackTrans;
    raise;
  end;
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
  LoadData;
  ShowMessage(Format('%d elementos desplanificados.', [Length(Ids)]));
end;

procedure TfrmBacklog.btnDesplanificarTodoClick(Sender: TObject);
var
  Q: TADOQuery;
  Ids: TList<Integer>;
  IdArr: TArray<Integer>;
  CE, PID: string;
begin
  CE := IntToStr(EmpresaCode);
  PID := IntToStr(DMPlanner.CurrentProjectId);

  // Recoger TODOS los NodeIds del plan actual que provengan del staging
  // (tengan NumeroOF o NumeroPedido que matchee una fila de Raw_OF / Raw_Comanda)
  Ids := TList<Integer>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT DISTINCT n.NodeId ' +
      'FROM FS_PL_Node n ' +
      'INNER JOIN FS_PL_NodeData nd ' +
      '  ON nd.CodigoEmpresa = n.CodigoEmpresa AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = ' + CE +
      '  AND n.ProjectId = ' + PID +
      '  AND ( ' +
      '    EXISTS (SELECT 1 FROM FS_PL_Raw_OF r ' +
      '            WHERE r.CodigoEmpresa = n.CodigoEmpresa ' +
      '              AND r.NumeroOF = nd.NumeroOF ' +
      '              AND ISNULL(r.SerieOF,'''') = ISNULL(nd.SerieOF,'''')) ' +
      '    OR ' +
      '    EXISTS (SELECT 1 FROM FS_PL_Raw_Comanda rc ' +
      '            WHERE rc.CodigoEmpresa = n.CodigoEmpresa ' +
      '              AND rc.NumeroPedido = nd.NumeroPedido ' +
      '              AND ISNULL(rc.SeriePedido,'''') = ISNULL(nd.SeriePedido,'''')) ' +
      '  )';
    Q.Open;
    while not Q.Eof do
    begin
      Ids.Add(Q.FieldByName('NodeId').AsInteger);
      Q.Next;
    end;
    IdArr := Ids.ToArray;
  finally
    Q.Free;
    Ids.Free;
  end;

  if Length(IdArr) = 0 then
  begin
    ShowMessage('No hay nodos provenientes del Backlog en el plan actual.');
    Exit;
  end;

  if MessageDlg(
      Format('Se desplanificaran %d nodos del plan actual que provienen del Backlog.' +
        sLineBreak + 'Los nodos manuales o de otras fuentes no se tocan.' +
        sLineBreak + sLineBreak + 'Continuar?', [Length(IdArr)]),
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  try
    DoDesplanificar(IdArr);
  except
    on E: Exception do
    begin
      ShowMessage('Error al desplanificar: ' + E.Message);
      Exit;
    end;
  end;
  LoadData;
  ShowMessage(Format('%d nodos desplanificados.', [Length(IdArr)]));
end;

// ---------------------------------------------------------------------------
// Construccion de columnas base (vista FS_PL_vw_Backlog)
// ---------------------------------------------------------------------------
procedure TfrmBacklog.BuildBaseColumns;

  function AddCol(const AKey, ACaption: string; AWidth: Integer): TcxGridColumn;
  begin
    Result := tvBacklog.CreateColumn;
    Result.Caption := ACaption;
    Result.Name := 'col_' + StringReplace(AKey, ' ', '_', [rfReplaceAll]);
    Result.Width := AWidth;
    Result.Options.Editing := False;
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
      Cols.Add(AddCol('Cantidad',             'Cantidad',       80));
      Cols.Add(AddCol('UnidadMedida',         'UM',             50));
      Cols.Add(AddCol('NombreCliente',        'Cliente',       180));
      Cols.Add(AddCol('CodigoProyecto',       'Proyecto',      100));
      Cols.Add(AddCol('SerieOF',              'Serie OF',       70));
      Cols.Add(AddCol('NumeroOF',             'OF',             70));
      Cols.Add(AddCol('CodigoOT',             'OT',             90));
      Cols.Add(AddCol('CodigoOP',             'OP',             90));
      Cols.Add(AddCol('FechaCompromiso',      'F. Compromiso', 110));
      Cols.Add(AddCol('FechaNecesaria',       'F. Necesaria',  110));
      Cols.Add(AddCol('FechaEntrega',         'F. Entrega',    110));
      Cols.Add(AddCol('Prioridad',            'Prio',           50));
      Cols.Add(AddCol('CentroPreferente',     'Centro pref.',  100));
      Cols.Add(AddCol('HorasEstimadas',       'Horas est.',     80));
      Cols.Add(AddCol('EstadoERP',            'Estado',         90));
      Cols.Add(AddCol('Orden',                'Orden op.',      70));
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
        Cols.Add(AddCol('NodeInicio',         'Inicio plan.',  130));
        Cols.Add(AddCol('NodeFin',            'Fin plan.',     130));
        Cols.Add(AddCol('NodeCentroNombre',   'Centro plan.',  140));
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

  if IsPlanningTab then
    Result :=
      'SELECT ' + Sel + ' FROM FS_PL_vw_BacklogPlanned b ' + Joins +
      ' WHERE b.CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      '   AND b.ProjectId = ' + IntToStr(DMPlanner.CurrentProjectId) +
      ' ORDER BY b.NodeInicio'
  else
    Result :=
      'SELECT ' + Sel + ' FROM FS_PL_vw_Backlog b ' + Joins +
      ' WHERE b.CodigoEmpresa = ' + IntToStr(EmpresaCode) +
      ' ORDER BY b.FechaCompromiso, b.Prioridad DESC';
end;

// ---------------------------------------------------------------------------
// Carga datos a la estructura interna y luego los vuelca al grid
// ---------------------------------------------------------------------------
procedure TfrmBacklog.LoadData;
var
  Q: TADOQuery;
  Row: TBacklogRow;
  I: Integer;
  FldName: string;
  V: Variant;
begin
  ClearRows;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := BuildSQL;
    Q.Open;
    while not Q.Eof do
    begin
      Row.Origen              := Q.FieldByName('Origen').AsString;
      if Q.FindField('TipoOrigen') <> nil then
        Row.TipoOrigen := Q.FieldByName('TipoOrigen').AsString
      else
        Row.TipoOrigen := '';
      if Q.FindField('Nivel') <> nil then
        Row.Nivel := Q.FieldByName('Nivel').AsInteger
      else
        Row.Nivel := 0;
      Row.RawId               := Q.FieldByName('RawId').AsLargeInt;
      if (Q.FindField('ParentRawItemId') <> nil) and
         not Q.FieldByName('ParentRawItemId').IsNull then
        Row.ParentRawItemId := Q.FieldByName('ParentRawItemId').AsLargeInt
      else
        Row.ParentRawItemId := 0;
      if (Q.FindField('GrandRawItemId') <> nil) and
         not Q.FieldByName('GrandRawItemId').IsNull then
        Row.GrandRawItemId := Q.FieldByName('GrandRawItemId').AsLargeInt
      else
        Row.GrandRawItemId := 0;
      Row.OrigenERP           := Q.FieldByName('OrigenERP').AsString;
      Row.ClaveERP            := Q.FieldByName('ClaveERP').AsString;
      Row.CodigoDocumento     := Q.FieldByName('CodigoDocumento').AsString;
      if Q.FindField('NumeroDoc') <> nil then
        Row.NumeroDoc := Q.FieldByName('NumeroDoc').AsInteger
      else
        Row.NumeroDoc := 0;
      if Q.FindField('SerieDoc') <> nil then
        Row.SerieDoc := Q.FieldByName('SerieDoc').AsString
      else
        Row.SerieDoc := '';
      Row.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
      Row.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      Row.Cantidad            := Q.FieldByName('Cantidad').AsFloat;
      Row.UnidadMedida        := Q.FieldByName('UnidadMedida').AsString;
      Row.CodigoCliente       := Q.FieldByName('CodigoCliente').AsString;
      Row.NombreCliente       := Q.FieldByName('NombreCliente').AsString;
      Row.CodigoProyecto      := Q.FieldByName('CodigoProyecto').AsString;
      if (Q.FindField('NumeroOF') <> nil) and not Q.FieldByName('NumeroOF').IsNull then
        Row.NumeroOF := Q.FieldByName('NumeroOF').AsInteger
      else
        Row.NumeroOF := 0;
      if Q.FindField('SerieOF') <> nil then
        Row.SerieOF := Q.FieldByName('SerieOF').AsString
      else
        Row.SerieOF := '';
      if Q.FindField('CodigoOT') <> nil then
        Row.CodigoOT := Q.FieldByName('CodigoOT').AsString
      else
        Row.CodigoOT := '';
      if Q.FindField('CodigoOP') <> nil then
        Row.CodigoOP := Q.FieldByName('CodigoOP').AsString
      else
        Row.CodigoOP := '';
      if Q.FieldByName('FechaCompromiso').IsNull then Row.FechaCompromiso := 0
        else Row.FechaCompromiso := Q.FieldByName('FechaCompromiso').AsDateTime;
      if Q.FieldByName('FechaNecesaria').IsNull then Row.FechaNecesaria := 0
        else Row.FechaNecesaria := Q.FieldByName('FechaNecesaria').AsDateTime;
      if (Q.FindField('FechaEntrega') <> nil) and not Q.FieldByName('FechaEntrega').IsNull then
        Row.FechaEntrega := Q.FieldByName('FechaEntrega').AsDateTime
      else
        Row.FechaEntrega := Row.FechaCompromiso;
      Row.Prioridad           := Q.FieldByName('Prioridad').AsInteger;
      Row.CentroPreferente    := Q.FieldByName('CentroPreferente').AsString;
      Row.HorasEstimadas      := Q.FieldByName('HorasEstimadas').AsFloat;
      if (Q.FindField('TiempoUnidadFabSecs') <> nil)
         and not Q.FieldByName('TiempoUnidadFabSecs').IsNull then
        Row.TiempoUnidadFabSecs := Q.FieldByName('TiempoUnidadFabSecs').AsFloat
      else
        Row.TiempoUnidadFabSecs := 0;
      Row.EstadoERP           := Q.FieldByName('EstadoERP').AsString;

      // Bloque OP (Nivel 3). FindField por robustez ante vistas pre-V053.
      if Q.FindField('Orden') <> nil then
        Row.Orden := Q.FieldByName('Orden').AsInteger
      else
        Row.Orden := 0;
      Row.OpTiempoPreparacion  := FieldFloat(Q, 'OpTiempoPreparacion');
      Row.OpTiempoFabricacion  := FieldFloat(Q, 'OpTiempoFabricacion');
      Row.OpUnidadesHora       := FieldFloat(Q, 'OpUnidadesHora');
      Row.OpCosteHoraMaquina   := FieldFloat(Q, 'OpCosteHoraMaquina');
      Row.OpCosteHoraManoObra  := FieldFloat(Q, 'OpCosteHoraManoObra');
      Row.OpUnidadesFabricadas := FieldFloat(Q, 'OpUnidadesFabricadas');
      Row.OpFechaInicioReal    := FieldDate(Q, 'OpFechaInicioReal');
      Row.OpFechaFinalReal     := FieldDate(Q, 'OpFechaFinalReal');
      Row.OpOperacionExterna   := FieldBoolVar(Q, 'OpOperacionExterna');
      Row.OpCodigoProveedor    := FieldStr(Q, 'OpCodigoProveedor');
      Row.OpSeccionFabrica     := FieldStr(Q, 'OpSeccionFabrica');
      Row.OpStatusPlanificado  := FieldBoolVar(Q, 'OpStatusPlanificado');
      Row.OpObservaciones      := FieldStr(Q, 'OpObservaciones');
      Row.OpPctParaSigOperacion   := FieldFloat(Q, 'OpPctParaSigOperacion');
      Row.OpPctDedicacionOperario := FieldFloat(Q, 'OpPctDedicacionOperario');

      // Campos del nodo (solo vw_BacklogPlanned)
      Row.NodeId := 0;
      Row.NodeInicio := 0;
      Row.NodeFin := 0;
      Row.NodeCodigoCentro := '';
      Row.NodeCentroNombre := '';
      if IsPlanningTab then
      begin
        if Q.FindField('NodeId') <> nil then
          Row.NodeId := Q.FieldByName('NodeId').AsInteger;
        if (Q.FindField('NodeInicio') <> nil) and not Q.FieldByName('NodeInicio').IsNull then
          Row.NodeInicio := Q.FieldByName('NodeInicio').AsDateTime;
        if (Q.FindField('NodeFin') <> nil) and not Q.FieldByName('NodeFin').IsNull then
          Row.NodeFin := Q.FieldByName('NodeFin').AsDateTime;
        if Q.FindField('NodeCodigoCentro') <> nil then
          Row.NodeCodigoCentro := Q.FieldByName('NodeCodigoCentro').AsString;
        if Q.FindField('NodeCentroNombre') <> nil then
          Row.NodeCentroNombre := Q.FieldByName('NodeCentroNombre').AsString;
      end;

      Row.Extras := TDictionary<string, Variant>.Create;
      for I := 0 to High(FCustomCols) do
      begin
        FldName := 'X_' + FCustomCols[I].ColumnKey;
        if Q.FindField(FldName) <> nil then
        begin
          if Q.FieldByName(FldName).IsNull then
            V := Null
          else
            // FieldValue siempre vive en BD como string en formato invariant.
            // Lo decodificamos al tipo nativo (Double/TDateTime/Boolean/string)
            // para que el editor de la celda acepte el valor sin conversion.
            V := DecodeFieldValue(FCustomCols[I].DataType,
                                  Q.FieldByName(FldName).AsString);
          Row.Extras.AddOrSetValue(FCustomCols[I].ColumnKey, V);
        end;
      end;

      FRows.Add(Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  ApplyRowsToGrid;
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
    // Row.Origen para hojas Nivel=3 siempre es 'OP'; el combo filtra por familia
    // (OF/PEDIDO/PROYECTO), que se deriva del TipoOrigen heredado del padre.
    S := UpperCase(Trim(Row.TipoOrigen));
    if      (cmbOrigen.ItemIndex = 1) and (S <> 'OF')  then Exit
    else if (cmbOrigen.ItemIndex = 2) and (S <> 'PED') then Exit
    else if (cmbOrigen.ItemIndex = 3) and (S <> 'PRJ') then Exit;
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
          // Mapeo CHAR(3) -> etiqueta legible (OF/PEDIDO/PROYECTO)
          S := UpperCase(Trim(Row.TipoOrigen));
          if      S = 'OF'  then tvBacklog.DataController.Values[RowIdx, Col.Index] := 'OF'
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
begin
  // Doble-clic en una fila de OF abre el Visor de OF (jerarquia OF/OT/OP).
  // No interferir con la columna de botones "Ver" (que tiene su propio editor).
  if AButton <> mbLeft then Exit;
  VerOFActual;
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
  except
    on E: Exception do
      ShowMessage('No se pudo guardar el valor: ' + E.Message);
  end;
end;

procedure TfrmBacklog.btnSelectAllClick(Sender: TObject);
begin
  tvBacklog.Controller.SelectAll;
end;

procedure TfrmBacklog.btnDeselectAllClick(Sender: TObject);
begin
  tvBacklog.Controller.ClearSelection;
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
procedure TfrmBacklog.VerOFActual;
var
  GridIdx, RowIdx: Integer;
  Row: TBacklogRow;
begin
  GridIdx := tvBacklog.Controller.FocusedRecordIndex;
  RowIdx := GetRowFromGridIndex(GridIdx);
  if (RowIdx < 0) or (RowIdx >= FRows.Count) then
  begin
    ShowMessage('Selecciona una fila del backlog para ver su OF.');
    Exit;
  end;
  Row := FRows[RowIdx];
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
