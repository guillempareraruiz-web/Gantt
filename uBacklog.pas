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
  System.Generics.Collections, System.DateUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, dxSkinsCore, dxSkinOffice2019Colorful,
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
  dxSkinXmas2008Blue, Vcl.Menus, cxButtons;

const
  BACKLOG_GRID_ID = 'BACKLOG';

type
  TBacklogRow = record
    Origen: string;
    TipoOrigen: string;      // CHAR(3) del modelo Raw_Item: 'OF ','PED','PRJ'
    RawId: Int64;
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
    FechaCompromiso: TDateTime;
    FechaNecesaria: TDateTime;
    Prioridad: Integer;
    CentroPreferente: string;
    HorasEstimadas: Double;
    EstadoERP: string;
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
  end;

  TfrmBacklog = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnPlanificar: TButton;
    btnGuardarLayout: TButton;
    btnResetLayout: TButton;
    btnClose: TButton;
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
    btnDesplanificarSel: TButton;
    btnDesplanificarTodo: TButton;
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
    btnAbrirGantt: TButton;
    btnVaciarPlan: TButton;
    btnRecargar: TcxButton;
    cxButton1: TcxButton;
    cxButton9: TcxButton;
    Label28: TLabel;
    cxButton2: TcxButton;
    PopupMenu1: TPopupMenu;
    Guardarlayoutgrid1: TMenuItem;
    Guardarlayoutgrid2: TMenuItem;
    N1: TMenuItem;
    Vaciarylimpiartodalaplanificacin1: TMenuItem;
    N2: TMenuItem;
    RegenerarNodosDemo1: TMenuItem;
    RegenerarBacklogDemo1: TMenuItem;
    lblCountRegs: TLabel;
    btnSelectAll: TButton;
    btnDeselectAll: TButton;
    procedure RegenerarNodosDemo1Click(Sender: TObject);
    procedure RegenerarBacklogDemo1Click(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnDeselectAllClick(Sender: TObject);
    procedure btnVaciarPlanClick(Sender: TObject);
    procedure btnAbrirGanttClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnPlanificarClick(Sender: TObject);
    procedure btnGuardarLayoutClick(Sender: TObject);
    procedure btnResetLayoutClick(Sender: TObject);
    procedure btnToggleImpactoClick(Sender: TObject);
    procedure btnLimpiarFiltrosClick(Sender: TObject);
    procedure FiltroChanged(Sender: TObject);
    procedure tvBacklogSelectionChanged(Sender: TcxCustomGridTableView);
    procedure tvCargaCentroCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure tabModeChange(Sender: TObject);
    procedure btnDesplanificarSelClick(Sender: TObject);
    procedure btnDesplanificarTodoClick(Sender: TObject);
    procedure btnRecargarClick(Sender: TObject);
  private
    FRows: TList<TBacklogRow>;
    FFilteredIndices: TArray<Integer>;   // FRows index per cada fila del grid
    FCustomCols: TArray<TCustomColumnDef>;
    FBaseColumns: TArray<TcxGridColumn>;
    FCustomColumns: TArray<TcxGridColumn>;
    FColKeyByTag: TDictionary<Integer, string>;
    FLoading: Boolean;

    procedure BuildBaseColumns;
    procedure LoadCustomColumnDefs;
    procedure BuildCustomColumns;
    procedure LoadData;
    procedure ApplyRowsToGrid;
    function BuildSQL: string;
    function PassesFilter(const Row: TBacklogRow): Boolean;
    procedure UpdateImpacto;
    procedure UpdateCountLabel;
    procedure ClearRows;

    procedure LoadUserLayout;
    procedure SaveUserLayout;
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
  uDMPlanner, uLogin, uGanttTypes, uCentreCalendar,
  uBacklogSchedParams, uBacklogSchedPreview, uUserPrefs, uGenerarNodosDemo,
  uDemoBacklog, uBacklogRegenParams, Main;

const
  BACKLOG_MOD = 'BACKLOG';

procedure ShowBacklog;
var
  F: TfrmBacklog;
begin
  F := TfrmBacklog.Create(Application);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
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

    BuildBaseColumns;
    LoadCustomColumnDefs;
    BuildCustomColumns;
    LoadUserLayout;
    ApplyImpactoVisible(uUserPrefs.GetPrefBool(BACKLOG_MOD, 'ImpactoVisible', True));
  finally
    FLoading := False;
  end;
  LoadData;
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

procedure TfrmBacklog.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmBacklog.btnAbrirGanttClick(Sender: TObject);
begin
  Close;
  if Form1 <> nil then
    Form1.MostrarVistaGantt;
end;

procedure TfrmBacklog.btnVaciarPlanClick(Sender: TObject);
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
      if Row.Origen = 'OF' then
      begin
        Input.NumeroOF := Row.NumeroDoc;
        Input.SerieOF := Row.SerieDoc;
      end
      else if Row.Origen = 'PEDIDO' then
      begin
        Input.NumeroPedido := Row.NumeroDoc;
        Input.SeriePedido := Row.SerieDoc;
      end;

      Input.CodigoCliente := Row.CodigoCliente;
      Input.CodigoArticulo := Row.CodigoArticulo;
      Input.DescripcionArticulo := Row.DescripcionArticulo;
      Input.UnidadesAFabricar := Row.Cantidad;
      Input.NumeroTrabajo := Row.CodigoProyecto;

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
  UdsStr, FNecStr: string;
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

      DurStr := StringReplace(FloatToStr(Item.DuracionMin), ',', '.', [rfReplaceAll]);
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
        UdsStr := StringReplace(FloatToStr(Item.Input.UnidadesAFabricar), ',', '.', [rfReplaceAll])
      else
        UdsStr := '1';
      if Item.Input.FechaCompromiso > 0 then
        FNecStr := FmtDT(Item.Input.FechaCompromiso)
      else
        FNecStr := 'NULL';
      Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := DMPlanner.ADOConnection;
        Cmd.CommandText :=
          'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, ' +
          '  NumeroOF, SerieOF, NumeroPedido, SeriePedido, NumeroTrabajo, ' +
          '  FechaEntrega, FechaNecesaria, CodigoCliente, ' +
          '  CodigoArticulo, DescripcionArticulo, ' +
          '  DuracionMin, DuracionMinOriginal, ' +
          '  UnidadesAFabricar, OperariosNecesarios, Prioridad, ' +
          '  RawItemClaveERP, RawItemTipoOrigen, ' +
          '  ColorFondoOp, ColorBordeOp) VALUES (' +
          CE + ', ' + IntToStr(NodeId) + ', ' + QS(Item.Input.CodigoDocumento) + ', ' +
          IntToStr(Item.Input.NumeroOF) + ', ' + QS(Item.Input.SerieOF) + ', ' +
          IntToStr(Item.Input.NumeroPedido) + ', ' + QS(Item.Input.SeriePedido) + ', ' +
          QS(Item.Input.NumeroTrabajo) + ', ' +
          FNecStr + ', ' + FNecStr + ', ' + QS(Item.Input.CodigoCliente) + ', ' +
          QS(Item.Input.CodigoArticulo) + ', ' + QS(Item.Input.DescripcionArticulo) + ', ' +
          DurStr + ', ' + DurStr + ', ' +
          UdsStr + ', 1, ' + IntToStr(Item.Input.Prioridad) + ', ' +
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

procedure TfrmBacklog.btnGuardarLayoutClick(Sender: TObject);
begin
  SaveUserLayout;
  ShowMessage('Layout guardado para el usuario actual.');
end;

procedure TfrmBacklog.btnRecargarClick(Sender: TObject);
begin
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

procedure TfrmBacklog.btnResetLayoutClick(Sender: TObject);
begin
  if MessageDlg('Restablecer layout por defecto del grid?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    ResetLayout;
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
      Cols.Add(AddCol('Origen',               'Origen',         70));
      Cols.Add(AddCol('CodigoDocumento',      'Documento',     120));
      Cols.Add(AddCol('DescripcionArticulo',  'Descripcion',   260));
      Cols.Add(AddCol('CodigoArticulo',       'Articulo',      110));
      Cols.Add(AddCol('Cantidad',             'Cantidad',       80));
      Cols.Add(AddCol('UnidadMedida',         'UM',             50));
      Cols.Add(AddCol('NombreCliente',        'Cliente',       180));
      Cols.Add(AddCol('CodigoProyecto',       'Proyecto',      100));
      Cols.Add(AddCol('FechaCompromiso',      'F. Compromiso', 110));
      Cols.Add(AddCol('FechaNecesaria',       'F. Necesaria',  110));
      Cols.Add(AddCol('Prioridad',            'Prio',           50));
      Cols.Add(AddCol('CentroPreferente',     'Centro pref.',  100));
      Cols.Add(AddCol('HorasEstimadas',       'Horas est.',     80));
      Cols.Add(AddCol('EstadoERP',            'Estado',         90));
      Cols.Add(AddCol('OrigenERP',            'ERP',            70));
      Cols.Add(AddCol('ClaveERP',             'Clave ERP',     120));

      // Columnas extra visibles solo en el tab Planificados
      if IsPlanningTab then
      begin
        Cols.Add(AddCol('NodeInicio',         'Inicio plan.',  130));
        Cols.Add(AddCol('NodeFin',            'Fin plan.',     130));
        Cols.Add(AddCol('NodeCentroNombre',   'Centro plan.',  140));
      end;
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
      'SELECT ColumnKey, Caption, DataType, SourceEntity, SourceExpression ' +
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
      Col.Caption := FCustomCols[I].Caption;
      Col.Name := 'colx_' + FCustomCols[I].ColumnKey;
      Col.Width := 120;
      Col.Options.Editing := False;
      Col.Tag := tvBacklog.ColumnCount - 1;
      FColKeyByTag.Add(Col.Tag, 'X:' + FCustomCols[I].ColumnKey);
      Cols.Add(Col);
    end;
    FCustomColumns := Cols.ToArray;
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
  I: Integer;
  Sel, Joins, Alias: string;
  Tbl: string;
begin
  Sel := 'b.*';
  Joins := '';
  for I := 0 to High(FCustomCols) do
  begin
    Alias := 'x' + IntToStr(I);
    if FCustomCols[I].SourceEntity = 'OF' then
      Tbl := 'FS_PL_Raw_OF_Extra'
    else if FCustomCols[I].SourceEntity = 'PEDIDO' then
      Tbl := 'FS_PL_Raw_Comanda_Extra'
    else if FCustomCols[I].SourceEntity = 'PROYECTO' then
      Tbl := 'FS_PL_Raw_Projecte_Extra'
    else
      Continue;

    Sel := Sel + ', ' + Alias + '.FieldValue AS [X_' + FCustomCols[I].ColumnKey + ']';
    Joins := Joins +
      ' LEFT JOIN ' + Tbl + ' ' + Alias +
      '   ON ' + Alias + '.CodigoEmpresa = b.CodigoEmpresa' +
      '  AND ' + Alias + '.FieldKey = ' + QStr(FCustomCols[I].FieldKey) +
      '  AND b.Origen = ''' + FCustomCols[I].SourceEntity + '''' +
      '  AND ' + Alias + '.' +
        (function: string
         begin
           if FCustomCols[I].SourceEntity = 'OF' then Result := 'RawOFId'
           else if FCustomCols[I].SourceEntity = 'PEDIDO' then Result := 'RawComandaId'
           else Result := 'RawProjecteId';
         end)() + ' = b.RawId';
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
      Row.RawId               := Q.FieldByName('RawId').AsLargeInt;
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
      if Q.FieldByName('FechaCompromiso').IsNull then Row.FechaCompromiso := 0
        else Row.FechaCompromiso := Q.FieldByName('FechaCompromiso').AsDateTime;
      if Q.FieldByName('FechaNecesaria').IsNull then Row.FechaNecesaria := 0
        else Row.FechaNecesaria := Q.FieldByName('FechaNecesaria').AsDateTime;
      Row.Prioridad           := Q.FieldByName('Prioridad').AsInteger;
      Row.CentroPreferente    := Q.FieldByName('CentroPreferente').AsString;
      Row.HorasEstimadas      := Q.FieldByName('HorasEstimadas').AsFloat;
      Row.EstadoERP           := Q.FieldByName('EstadoERP').AsString;

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
            V := Q.FieldByName(FldName).AsString;
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
    if not SameText(Row.Origen, cmbOrigen.Text) then Exit;

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
  Key: string;
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

        if Key = 'Origen' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.Origen
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
        else if Key = 'Prioridad' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.Prioridad
        else if Key = 'CentroPreferente' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.CentroPreferente
        else if Key = 'HorasEstimadas' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.HorasEstimadas
        else if Key = 'EstadoERP' then
          tvBacklog.DataController.Values[RowIdx, Col.Index] := Row.EstadoERP
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
  S: TStringStream;
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
        S := TStringStream.Create(LayoutStr, TEncoding.UTF8);
        try
          S.Position := 0;
          tvBacklog.RestoreFromStream(S);
        finally
          S.Free;
        end;
      end;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmBacklog.SaveUserLayout;
var
  Q: TADOQuery;
  S: TStringStream;
  LayoutStr: string;
  Cmd: TADOCommand;
begin
  S := TStringStream.Create('', TEncoding.UTF8);
  try
    tvBacklog.StoreToStream(S);
    LayoutStr := S.DataString;
  finally
    S.Free;
  end;

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
    Cmd.Parameters.Refresh;
    Cmd.Parameters.ParamByName('LayoutData').Value := LayoutStr;
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

end.
