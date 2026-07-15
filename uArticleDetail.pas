unit uArticleDetail;
// ============================================================================
// Article Detail — vista profunda de UN art'iculo con multiples pesta'nas.
//
// PageControl con tabs:
//   - Projected Stock (ATP):  proyecci'on de stock futuro
//   - (futuro) Stock por partida
//   - (futuro) Movimientos / Reservado por / Historia
//
// Filtros comunes (art'iculo + almacenes) en cabecera.
// El form NO hace queries SQL directamente: todo va v'ia IErpReader.
// ============================================================================
interface
uses
  System.SysUtils, System.StrUtils, System.Classes, System.UITypes,
  System.DateUtils, System.Math, System.Variants, System.Generics.Collections,
  Winapi.Windows, Winapi.Messages,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  Data.DB, Datasnap.DBClient,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, dxCore,
  cxGridLevel, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxClasses, cxGridCustomView, cxGrid, cxDBData, cxCheckComboBox,
  cxDropDownEdit, cxTextEdit, cxMaskEdit, cxSpinEdit, cxButtons, cxPC,
  cxTL, cxTLData, cxInplaceContainer, cxTLdxBarBuiltInMenu,
  uErpReader, uErpTypes, uStockProjection, uMrpTypes, uMrpParamRepo,
  uMrpRecommender, cxCheckBox, cxContainer, dxSkinsCore,
  dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinCaramel,
  dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019Colorful,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, dxBarBuiltInMenu,
  dxGDIPlusClasses, cxImage;
type
  TfrmArticleDetail = class(TForm)
    pnlNav: TPanel;
    tvNav: TTreeView;
    btnObs: TButton;
    pgcTabs: TcxPageControl;
    tabATP: TcxTabSheet;
    tabPartidas: TcxTabSheet;
    pnlPartidasTop: TPanel;
    btnRecargarPartidas: TButton;
    chkSoloConSaldo: TCheckBox;
    grdPartidas: TcxGrid;
    grdPartidasView: TcxGridDBTableView;
    grdPartidasLevel: TcxGridLevel;
    cdsPartidas: TClientDataSet;
    dsPartidas: TDataSource;
    tabMovimientos: TcxTabSheet;
    pnlMovsFutTop: TPanel;
    lblMovsFutDesde: TLabel;
    lblMovsFutHasta: TLabel;
    dtMovsFutDesde: TDateTimePicker;
    dtMovsFutHasta: TDateTimePicker;
    chkMovFutCompras: TCheckBox;
    chkMovFutVentas: TCheckBox;
    chkMovFutOFs: TCheckBox;
    btnRecargarMovsFut: TButton;
    grdMovsFut: TcxGrid;
    grdMovsFutView: TcxGridDBTableView;
    grdMovsFutLevel: TcxGridLevel;
    cdsMovsFut: TClientDataSet;
    dsMovsFut: TDataSource;
    tabHistorico: TcxTabSheet;
    pnlHistTop: TPanel;
    lblHistMeses: TLabel;
    seHistMeses: TcxSpinEdit;
    btnRecargarHist: TButton;
    pbHistorico: TPaintBox;
    tabOFs: TcxTabSheet;
    pnlOFsTop: TPanel;
    btnRecargarOFs: TButton;
    grdOFs: TcxGrid;
    grdOFsView: TcxGridDBTableView;
    grdOFsLevel: TcxGridLevel;
    cdsOFs: TClientDataSet;
    dsOFs: TDataSource;
    tabProveedores: TcxTabSheet;
    pnlProvTop: TPanel;
    lblProvMeses: TLabel;
    seProvMeses: TcxSpinEdit;
    btnRecargarProv: TButton;
    grdProv: TcxGrid;
    grdProvView: TcxGridDBTableView;
    grdProvLevel: TcxGridLevel;
    cdsProv: TClientDataSet;
    dsProv: TDataSource;
    tabClientes: TcxTabSheet;
    pnlCliTop: TPanel;
    lblCliMeses: TLabel;
    seCliMeses: TcxSpinEdit;
    btnRecargarCli: TButton;
    grdCli: TcxGrid;
    grdCliView: TcxGridDBTableView;
    grdCliLevel: TcxGridLevel;
    cdsCli: TClientDataSet;
    dsCli: TDataSource;
    tabDondeUsa: TcxTabSheet;
    pnlDondeUsaTop: TPanel;
    btnRecargarDondeUsa: TButton;
    grdDondeUsa: TcxGrid;
    grdDondeUsaView: TcxGridDBTableView;
    grdDondeUsaLevel: TcxGridLevel;
    cdsDondeUsa: TClientDataSet;
    dsDondeUsa: TDataSource;
    tabDisponibilidad: TcxTabSheet;
    pnlDispTop: TPanel;
    lblDispCantidad: TLabel;
    lblDispFecha: TLabel;
    lblDispLeyenda: TLabel;
    seDispCantidad: TcxSpinEdit;
    dtDispFecha: TDateTimePicker;
    btnRecargarDisp: TButton;
    tlDisp: TcxTreeList;
    colDispArticulo: TcxTreeListColumn;
    colDispDescripcion: TcxTreeListColumn;
    colDispTipo: TcxTreeListColumn;
    colDispNecesario: TcxTreeListColumn;
    colDispStockActual: TcxTreeListColumn;
    colDispStockProy: TcxTreeListColumn;
    colDispFaltaActual: TcxTreeListColumn;
    colDispFaltaProy: TcxTreeListColumn;
    colDispEstado: TcxTreeListColumn;
    pnlTop: TPanel;
    lblArticulo: TLabel;
    edArticulo: TEdit;
    btnBuscarArticulo: TButton;
    lblDescripcion: TLabel;
    pnlTipoAprov: TPanel;
    lblTipoAprov: TLabel;
    lblAlmacenes: TLabel;
    ccbAlmacenes: TcxCheckComboBox;
    lblFecha: TLabel;
    dtFecha: TDateTimePicker;
    btnCalcular: TButton;
    pnlResumen: TPanel;
    lblTitResumen: TLabel;
    lblStockInicial: TLabel;
    lblValStockInicial: TLabel;
    lblTotalEntradas: TLabel;
    lblValTotalEntradas: TLabel;
    lblTotalSalidas: TLabel;
    lblValTotalSalidas: TLabel;
    lblStockFinal: TLabel;
    lblValStockFinal: TLabel;
    lblStockMinimo: TLabel;
    lblValStockMinimo: TLabel;
    pnlRecomendacion: TPanel;
    lblRecomendacion: TLabel;
    btnAccionMrp: TButton;
    grdMovs: TcxGrid;
    grdMovsView: TcxGridDBTableView;
    grdMovsLevel: TcxGridLevel;
    cdsMovs: TClientDataSet;
    dsMovs: TDataSource;
    pnlMovsContainer: TPanel;
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    btnFocus: TButton;
    imgSection: TcxImage;
    pnlKPIs: TPanel;
    pnlKPI2: TPanel;
    lblKPI2Cap: TLabel;
    lblKPI2Val: TLabel;
    lblKPI2Sub: TLabel;
    pnlKPI3: TPanel;
    lblKPI3Cap: TLabel;
    lblKPI3Val: TLabel;
    lblKPI3Sub: TLabel;
    pnlKPI4: TPanel;
    lblKPI4Cap: TLabel;
    lblKPI4Val: TLabel;
    lblKPI4Sub: TLabel;
    pnlKPI5: TPanel;
    lblKPI5Cap: TLabel;
    lblKPI5Val: TLabel;
    lblKPI5Sub: TLabel;
    pnlKPI6: TPanel;
    lblKPI6Cap: TLabel;
    lblKPI6Val: TLabel;
    lblKPI6Sub: TLabel;
    pnlKPI1: TPanel;
    lblKPI1Cap: TLabel;
    lblKPI1Sub: TLabel;
    lblKPI1Val: TLabel;
    Edit1: TEdit;
    cxTabSheet1: TcxTabSheet;
    mmoLog: TMemo;
    Panel1: TPanel;
    lblDispVeredicto: TLabel;
    Panel2: TPanel;
    lblDondeUsaResumen: TLabel;
    Panel3: TPanel;
    lblHistResumen: TLabel;
    Panel4: TPanel;
    lblOFsResumen: TLabel;
    Panel5: TPanel;
    lblProvResumen: TLabel;
    Panel6: TPanel;
    lblCliResumen: TLabel;
    Panel7: TPanel;
    lblMovsFutResumen: TLabel;
    Panel8: TPanel;
    lblPartidasResumen: TLabel;
    Panel9: TPanel;
    lblAviso: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tvNavClick(Sender: TObject);
    procedure tvNavCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure btnObsClick(Sender: TObject);
    procedure btnBuscarArticuloClick(Sender: TObject);
    procedure btnCalcularClick(Sender: TObject);
    procedure btnToggleLogClick(Sender: TObject);
    procedure btnAccionMrpClick(Sender: TObject);
    procedure grdMovsViewCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
    procedure btnRecargarPartidasClick(Sender: TObject);
    procedure chkSoloConSaldoClick(Sender: TObject);
    procedure pgcTabsChange(Sender: TObject);
    procedure btnRecargarMovsFutClick(Sender: TObject);
    procedure MovFutTipoChange(Sender: TObject);
    procedure grdMovsFutViewCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
    procedure btnRecargarDispClick(Sender: TObject);
    procedure btnRecargarDondeUsaClick(Sender: TObject);
    procedure btnRecargarHistClick(Sender: TObject);
    procedure pbHistoricoPaint(Sender: TObject);
    procedure btnRecargarOFsClick(Sender: TObject);
    procedure btnRecargarProvClick(Sender: TObject);
    procedure btnRecargarCliClick(Sender: TObject);
    procedure tlDispCustomDrawDataCell(Sender: TcxCustomTreeList;
      ACanvas: TcxCanvas; AViewInfo: TcxTreeListEditCellViewInfo;
      var ADone: Boolean);
    procedure grdPartidasViewCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
  private
    FReader: IErpReader;
    FCodigoArticulo: string;
    FDescripcionArticulo: string;
    FStockMinimo: Double;
    FObsVisible: Boolean;   // estado del panel Observaciones (toggle global)
    FPanelesObs: TList<TPanel>;   // un panel por seccion (tab)
    // MRP: ultima recomendacion calculada (para el boton de accion) y articulo
    // Sage leido en el ultimo calculo (lleva los parametros: lead time, lote...).
    FUltimaRecom: TMrpRecommendation;
    FArticuloActual: TArticuloErp;
    FArticuloLeido: Boolean;
    FPartidasCargadas: Boolean;
    FMovsFutCargados: Boolean;
    FDispCalculada: Boolean;
    FDondeUsaCargado: Boolean;
    FHistoricoCargado: Boolean;
    FHistorico: TArray<THistoricoMesErp>;
    FOFsCargadas: Boolean;
    FProvCargados: Boolean;
    FCliCargados: Boolean;
    procedure CargarAlmacenes;
    function AlmacenesSeleccionados: TArray<string>;
    procedure LimpiarResultados;
    procedure CrearColumnasMovs;
    procedure CrearColumnasPartidas;
    procedure CrearColumnasMovsFut;
    // True si la fila ARecIdx es la primera con saldo >= 0 tras una ruptura
    // (saldo anterior < 0). Para colorear la recuperacion en el Time-Phased View.
    function EsFilaRecuperacion(ARecIdx: Integer): Boolean;
    procedure RellenarMovs(const AMovs: TArray<TMovStock>);
    procedure PintarResumen(const AResumen: TResumenProyeccion);
    // Calcula y pinta la recomendacion MRP a partir de la proyeccion ya hecha.
    // AArticulo es el TArticuloErp ya leido (con los parametros de Sage).
    // Cuerpo del calculo de proyeccion (lo invoca btnCalcularClick dentro de
    // ShowBusy para animar el dialogo de "cargando").
    procedure DoCalcular;
    procedure CalcularRecomendacion(const AArticulo: TArticuloErp;
      AProjector: TStockProjector);
    procedure CargarPartidas;
    procedure AplicarFiltroPartidas;
    procedure CargarMovsFut;
    procedure AplicarFiltroMovsFut;
    procedure CalcularDisponibilidad;
    procedure CrearColumnasDondeUsa;
    procedure CargarDondeUsa;
    procedure CargarHistorico;
    procedure CrearColumnasOFs;
    procedure CrearColumnasProv;
    procedure CrearColumnasCli;
    procedure CargarOFs;
    procedure CargarProveedores;
    procedure CargarClientes;
    procedure SetKPI(APanel: TPanel; AValLbl: TLabel; const AValor: string;
      AColorFondo: TColor);
    // Pinta el badge FABRICAR / COMPRAR segun FArticuloActual.TieneFormula.
    procedure ActualizarTipoAprov;
    // Navegacion por arbol lateral (sustituye a las pestanas visibles).
    procedure ConstruirArbolNav;
    // Paneles Observaciones: uno por seccion (tab), texto fijo explicativo.
    procedure ConstruirPanelesObs;
    procedure AplicarVisibilidadObs;
    // Texto de observaciones para una pagina (tab) dada.
    function TextoObsDe(APage: TcxTabSheet): string;
    procedure ResetKPIs;
    procedure ActualizarKPIs(AStockTotal, ADisponible, APendRecibir,
      APendServir: Double);
    procedure LogInfo(const AMsg: string);
    procedure LogError(const AMsg: string);
    function TipoToStr(ATipo: TTipoMovStock): string;
    // Modo Demo: al conmutar, refresca almacenes y recalcula (si hay articulo).
    procedure DemoChanged(Sender: TObject);
    // Devuelve el siguiente codigo del catalogo demo respecto al actual (ciclo).
    function SiguienteArticuloDemo: string;
    // True si estamos en Demo. Solo lo usa el tab Disponibilidad (explosion de
    // BOM), que no tiene datos demo -> avisa y no consulta el ERP.
    function TabNoDisponibleEnDemo: Boolean;
    // En Demo, carga TODOS los tabs de golpe (llenos con datos ficticios) al
    // abrir/cambiar de articulo. Reutiliza cada CargarXxx (que ya sabe demo).
    procedure CargarTabsDemo;
    // Oculta los botones "Recargar" de cada tab en Demo (no aplican: los datos
    // ya estan y no vienen del ERP). Los restaura al salir de Demo.
    procedure AjustarBotonesRecargarDemo;
  public
    class procedure Execute(const AReader: IErpReader); overload;
    class procedure Execute(const AReader: IErpReader;
      const ACodigoArticulo: string); overload;
    // Uso como child embebido en el Main (no-modal). PrepareAsChild inicializa
    // (reader + almacenes); CargarArticulo carga y calcula un articulo concreto.
    procedure PrepareAsChild(const AReader: IErpReader);
    procedure CargarArticulo(const ACodigo: string);
  end;
implementation
uses
  uArticuloPicker, uDMPlanner, uMrpPropuestaBacklog, uGanttTypes, uBusyDialog,
  uDemoMode;
{$R *.dfm}
class procedure TfrmArticleDetail.Execute(const AReader: IErpReader);
begin
  Execute(AReader, '');
end;
class procedure TfrmArticleDetail.Execute(const AReader: IErpReader;
  const ACodigoArticulo: string);
var
  Frm: TfrmArticleDetail;
begin
  Frm := TfrmArticleDetail.Create(nil);
  try
    Frm.FReader := AReader;
    Frm.CargarAlmacenes;
    if ACodigoArticulo <> '' then
    begin
      Frm.FCodigoArticulo := ACodigoArticulo;
      Frm.edArticulo.Text := ACodigoArticulo;
      // Llanca el calcul automatic
      Frm.btnCalcularClick(nil);
    end;
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TfrmArticleDetail.PrepareAsChild(const AReader: IErpReader);
begin
  // Inicializacion para uso como child embebido (no-modal). El Main lo crea una
  // vez y lo reutiliza; aqui solo refrescamos el reader y los almacenes.
  FReader := AReader;
  CargarAlmacenes;
  AjustarBotonesRecargarDemo;   // el estado Demo pudo cambiar entre visitas
end;

procedure TfrmArticleDetail.CargarArticulo(const ACodigo: string);
begin
  if Trim(ACodigo) = '' then Exit;
  FCodigoArticulo := ACodigo;
  edArticulo.Text := ACodigo;
  btnCalcularClick(nil);
end;
procedure TfrmArticleDetail.FormCreate(Sender: TObject);
begin
  dtFecha.Date := IncMonth(Date, 1);
  dtMovsFutDesde.Date := Date;
  dtMovsFutHasta.Date := IncMonth(Date, 3);
  dtDispFecha.Date := IncMonth(Date, 1);
  CrearColumnasMovs;
  CrearColumnasPartidas;
  CrearColumnasMovsFut;
  CrearColumnasDondeUsa;
  CrearColumnasOFs;
  CrearColumnasProv;
  CrearColumnasCli;
  FPartidasCargadas := False;
  FMovsFutCargados := False;
  FDispCalculada := False;
  FDondeUsaCargado := False;
  FHistoricoCargado := False;
  FOFsCargadas := False;
  FProvCargados := False;
  FCliCargados := False;
  SetLength(FHistorico, 0);
  LimpiarResultados;
  btnFocus.Left := -100;
  FObsVisible := False;
  FPanelesObs := TList<TPanel>.Create;
  ConstruirArbolNav;
  ConstruirPanelesObs;
  DemoMode.AddListener(DemoChanged);
  AjustarBotonesRecargarDemo;
end;

procedure TfrmArticleDetail.FormDestroy(Sender: TObject);
begin
  DemoMode.RemoveListener(DemoChanged);
  FPanelesObs.Free;
end;

// ============================================================================
// Navegacion por arbol lateral (izquierda) + panel Observaciones
// ============================================================================

// Construye el arbol de secciones. Cada nodo-hoja lleva en Data el puntero a
// su TcxTabSheet; al hacer clic, se activa esa pagina (las pestanas del
// PageControl estan ocultas: Properties.HideTabs = True).
procedure TfrmArticleDetail.ConstruirArbolNav;
var
  NCat: TTreeNode;

  procedure Hoja(const ACaption: string; APage: TcxTabSheet);
  var
    N: TTreeNode;
  begin
    N := tvNav.Items.AddChild(NCat, ACaption);
    N.Data := APage;
  end;

begin
  tvNav.Items.BeginUpdate;
  try
    tvNav.Items.Clear;

    NCat := tvNav.Items.Add(nil, 'Proyecci'#243'n de stock');
    NCat.Data := nil;
    Hoja('Stock proyectado (ATP)', tabATP);
    Hoja('Movimientos futuros', tabMovimientos);
    Hoja('Partidas / lotes', tabPartidas);
    Hoja('Disponibilidad fabricaci'#243'n', tabDisponibilidad);

    NCat := tvNav.Items.Add(nil, 'Consumo');
    NCat.Data := nil;
    Hoja('D'#243'nde se usa', tabDondeUsa);
    Hoja('Hist'#243'rico mensual', tabHistorico);

    NCat := tvNav.Items.Add(nil, 'Fabricaci'#243'n');
    NCat.Data := nil;
    Hoja('OFs activas', tabOFs);

    NCat := tvNav.Items.Add(nil, 'Comercial');
    NCat.Data := nil;
    Hoja('Proveedores', tabProveedores);
    Hoja('Clientes', tabClientes);

    tvNav.FullExpand;
  finally
    tvNav.Items.EndUpdate;
  end;
  // Seleccion inicial: el nodo del ATP (primera hoja).
  if tvNav.Items.Count > 1 then
    tvNav.Selected := tvNav.Items[1];
end;

procedure TfrmArticleDetail.tvNavCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  DefaultDraw := True;
  // Categoria (Data=nil): negrita. Hoja (Data=TcxTabSheet): normal.
  if Node.Data = nil then
    Sender.Canvas.Font.Style := [fsBold]
  else
    Sender.Canvas.Font.Style := [];
end;

procedure TfrmArticleDetail.tvNavClick(Sender: TObject);
var
  N: TTreeNode;
begin
  N := tvNav.Selected;
  if (N = nil) or (N.Data = nil) then Exit;   // categoria: no navega
  pgcTabs.ActivePage := TcxTabSheet(N.Data);
  // pgcTabsChange se dispara con el cambio de pagina y carga el tab si toca.
  pgcTabsChange(nil);
  AplicarVisibilidadObs;
end;

// Crea un panel Observaciones (oculto) al pie de cada tab, con su texto fijo.
procedure TfrmArticleDetail.ConstruirPanelesObs;

  procedure PanelEn(APage: TcxTabSheet);
  var
    Pnl: TPanel;
    Lbl: TLabel;
    Memo: TMemo;
  begin
    Pnl := TPanel.Create(Self);
    Pnl.Parent := APage;
    Pnl.Align := alBottom;
    Pnl.Height := 130;
    Pnl.BevelOuter := bvNone;
    Pnl.Color := $00EDEDED;
    Pnl.ParentBackground := False;
    Pnl.Padding.SetBounds(12, 8, 12, 10);
    Pnl.Visible := False;   // el boton global lo conmuta

    Lbl := TLabel.Create(Self);
    Lbl.Parent := Pnl;
    Lbl.Align := alTop;
    Lbl.Caption := 'Observaciones  '#183'  ' + APage.Caption;
    Lbl.Font.Style := [fsBold];
    Lbl.Font.Size := 9;
    Lbl.Font.Color := $00404040;
    Lbl.Height := 18;
    Lbl.Layout := tlCenter;

    Memo := TMemo.Create(Self);
    Memo.Parent := Pnl;
    Memo.Align := alClient;
    Memo.BorderStyle := bsNone;
    Memo.Color := Pnl.Color;
    Memo.ReadOnly := True;
    Memo.TabStop := False;
    Memo.WordWrap := True;
    Memo.ScrollBars := ssVertical;
    Memo.Font.Size := 8;
    Memo.Font.Color := $00303030;
    Memo.Text := TextoObsDe(APage);

    FPanelesObs.Add(Pnl);
  end;

begin
  PanelEn(tabATP);
  PanelEn(tabMovimientos);
  PanelEn(tabPartidas);
  PanelEn(tabDisponibilidad);
  PanelEn(tabDondeUsa);
  PanelEn(tabHistorico);
  PanelEn(tabOFs);
  PanelEn(tabProveedores);
  PanelEn(tabClientes);
end;

procedure TfrmArticleDetail.AplicarVisibilidadObs;
var
  Pnl: TPanel;
begin
  for Pnl in FPanelesObs do
    Pnl.Visible := FObsVisible;
end;

procedure TfrmArticleDetail.btnObsClick(Sender: TObject);
begin
  FObsVisible := not FObsVisible;
  AplicarVisibilidadObs;
  if FObsVisible then btnObs.Caption := 'Ocultar observaciones'
  else btnObs.Caption := 'Observaciones';
end;

// Texto explicativo fijo por seccion (que muestra y como leerlo).
function TfrmArticleDetail.TextoObsDe(APage: TcxTabSheet): string;
begin
  if APage = tabATP then
    Result :=
      'Proyecci'#243'n de stock disponible en el tiempo (ATP): parte del saldo ' +
      'actual y aplica las entradas previstas (compras y OFs de producci'#243'n) ' +
      'y las salidas (pedidos de venta y consumos). Las filas en ROJO marcan ' +
      'rupturas (saldo negativo), en ROSA por debajo del m'#237'nimo, y en VERDE ' +
      'la recuperaci'#243'n tras una ruptura. Debajo, la recomendaci'#243'n MRP indica ' +
      'cu'#225'nto y cu'#225'ndo reponer (fabricar o comprar seg'#250'n el art'#237'culo).'
  else if APage = tabMovimientos then
    Result :=
      'Detalle cronol'#243'gico de los movimientos futuros que afectan al stock: ' +
      'entradas (+) de compras y producci'#243'n de OFs, y salidas (-) de ventas ' +
      'y consumos. Es el desglose que alimenta la proyecci'#243'n del tab ATP.'
  else if APage = tabPartidas then
    Result :=
      'Desglose del saldo f'#237'sico actual por almac'#233'n y partida/lote, con ' +
      'ubicaci'#243'n, precio medio y caducidad. Las filas resaltadas indican ' +
      'lotes con caducidad pasada o pr'#243'xima (30 d'#237'as): revisar rotaci'#243'n.'
  else if APage = tabDisponibilidad then
    Result :=
      'Comprueba si hay stock proyectado de todos los componentes para ' +
      'fabricar una cantidad objetivo a una fecha. Explosiona la f'#243'rmula ' +
      'nivel a nivel; en rojo los componentes que faltar'#237'an.'
  else if APage = tabDondeUsa then
    Result :=
      'D'#243'nde se usa (pegging inverso): f'#243'rmulas de otros art'#237'culos que ' +
      'consumen '#233'ste como componente, con la cantidad por unidad y la merma. ' +
      #218'til para valorar el impacto de una ruptura de este material.'
  else if APage = tabHistorico then
    Result :=
      'Hist'#243'rico mensual de entradas y salidas de los '#250'ltimos meses. Ayuda ' +
      'a ver la estacionalidad y la tendencia de consumo para dimensionar ' +
      'stock de seguridad y lotes de reposici'#243'n.'
  else if APage = tabOFs then
    Result :=
      #211'rdenes de fabricaci'#243'n activas (en curso o pendientes) que producen ' +
      'este art'#237'culo, con su avance y fechas previstas. Solo aplica a ' +
      'art'#237'culos fabricables (con f'#243'rmula).'
  else if APage = tabProveedores then
    Result :=
      'Proveedores hist'#243'ricos del art'#237'culo, con precio medio de compra, ' +
      'lead time y volumen. Base para elegir proveedor y estimar el plazo ' +
      'de reposici'#243'n en una recomendaci'#243'n de compra.'
  else if APage = tabClientes then
    Result :=
      'Clientes hist'#243'ricos del art'#237'culo, con unidades e importe vendido. ' +
      'Ayuda a priorizar seg'#250'n qui'#233'n depende del stock y a valorar el ' +
      'impacto comercial de una ruptura.'
  else
    Result := '';
end;

function TfrmArticleDetail.TabNoDisponibleEnDemo: Boolean;
begin
  Result := DemoMode.Active;
  if Result then
    LogInfo('La disponibilidad (explosi'#243'n de f'#243'rmula) no tiene datos demo.');
end;

procedure TfrmArticleDetail.CargarTabsDemo;
begin
  // Fuerza la recarga (marcamos como no cargados) y llena cada tab. Cada
  // CargarXxx ya usa datos demo cuando DemoMode.Active.
  FPartidasCargadas := False;  CargarPartidas;
  FMovsFutCargados := False;   CargarMovsFut;
  FDondeUsaCargado := False;   CargarDondeUsa;
  FHistoricoCargado := False;  CargarHistorico;
  FOFsCargadas := False;       CargarOFs;
  FProvCargados := False;      CargarProveedores;
  FCliCargados := False;       CargarClientes;
  // Disponibilidad (explosion BOM) no tiene datos demo: se deja sin cargar.
end;

procedure TfrmArticleDetail.AjustarBotonesRecargarDemo;
var
  Mostrar: Boolean;
begin
  // En Demo no tiene sentido "Recargar" (los datos no vienen del ERP).
  Mostrar := not DemoMode.Active;
  btnRecargarPartidas.Visible := Mostrar;
  btnRecargarMovsFut.Visible  := Mostrar;
  btnRecargarDondeUsa.Visible := Mostrar;
  btnRecargarHist.Visible     := Mostrar;
  btnRecargarOFs.Visible      := Mostrar;
  btnRecargarProv.Visible     := Mostrar;
  btnRecargarCli.Visible      := Mostrar;
  btnRecargarDisp.Visible     := Mostrar;
  // En Demo ocultamos el edit de codigo suelto (Edit1, 'AUT0801KIT'): el
  // articulo se elige con el catalogo demo (boton Buscar), no tecleandolo.
  Edit1.Visible := Mostrar;
end;

function TfrmArticleDetail.SiguienteArticuloDemo: string;
var
  Cods: TArray<string>;
  I, Idx: Integer;
begin
  Cods := uDemoMode.DemoArticuloCodigos;
  if Length(Cods) = 0 then Exit('');
  Idx := 0;
  for I := 0 to High(Cods) do
    if SameText(Cods[I], Trim(edArticulo.Text)) then
    begin
      Idx := (I + 1) mod Length(Cods);
      Break;
    end;
  Result := Cods[Idx];
end;

procedure TfrmArticleDetail.DemoChanged(Sender: TObject);
begin
  // Solo actuamos si la ficha esta visible: si el usuario conmuta Demo desde
  // otra pantalla (Gantt, etc.) no debemos disparar aqui un ShowBusy invisible.
  // Al volver a mostrar la ficha, MostrarArticleDetail ya recarga.
  if not Visible then Exit;
  AjustarBotonesRecargarDemo;
  // Al entrar/salir de Demo cambian los almacenes disponibles. Si ya hay un
  // articulo cargado, recalculamos con la nueva fuente (demo <-> ERP). Al entrar
  // en Demo sin articulo, cargamos uno por defecto para que la ficha no salga
  // vacia.
  CargarAlmacenes;
  if Trim(edArticulo.Text) <> '' then
    btnCalcularClick(nil)
  else if DemoMode.Active then
    CargarArticulo(uDemoMode.DemoArticuloCodigos[0]);
end;
procedure TfrmArticleDetail.CargarAlmacenes;
var
  Almacenes: TArray<TAlmacenErp>;
  i: Integer;
  Item: TcxCheckComboBoxItem;
begin
  ccbAlmacenes.Properties.Items.Clear;
  // En modo Demo, almacenes ficticios (no se toca el ERP).
  if DemoMode.Active then
    Almacenes := uDemoMode.DemoAlmacenes
  else
  begin
    if FReader = nil then Exit;
    try
      Almacenes := FReader.ReadAlmacenes;
    except
      on E: Exception do
      begin
        LogError('Error cargando almacenes: ' + E.Message);
        Exit;
      end;
    end;
  end;
  for i := 0 to High(Almacenes) do
  begin
    Item := ccbAlmacenes.Properties.Items.Add;
    Item.Description := Almacenes[i].Codigo + ' - ' + Almacenes[i].Nombre;
    Item.Tag := i;
    Item.ShortDescription := Almacenes[i].Codigo;
  end;
end;
function TfrmArticleDetail.AlmacenesSeleccionados: TArray<string>;
var
  i, n: Integer;
begin
  SetLength(Result, ccbAlmacenes.Properties.Items.Count);
  n := 0;
  for i := 0 to ccbAlmacenes.Properties.Items.Count - 1 do
    if ccbAlmacenes.States[i] = cbsChecked then
    begin
      Result[n] := ccbAlmacenes.Properties.Items[i].ShortDescription;
      Inc(n);
    end;
  SetLength(Result, n);
end;
procedure TfrmArticleDetail.LimpiarResultados;
begin
  lblDescripcion.Caption := '';
  pnlTipoAprov.Visible := False;
  lblValStockInicial.Caption := '-';
  lblValTotalEntradas.Caption := '-';
  lblValTotalSalidas.Caption := '-';
  lblValStockFinal.Caption := '-';
  lblValStockMinimo.Caption := '-';
  lblAviso.Caption := '';
  lblAviso.Visible := False;
  if cdsMovs.Active then cdsMovs.EmptyDataSet;
  if cdsPartidas.Active then cdsPartidas.EmptyDataSet;
  if cdsMovsFut.Active then cdsMovsFut.EmptyDataSet;
  if cdsDondeUsa.Active then cdsDondeUsa.EmptyDataSet;
  if cdsOFs.Active then cdsOFs.EmptyDataSet;
  if cdsProv.Active then cdsProv.EmptyDataSet;
  if cdsCli.Active then cdsCli.EmptyDataSet;
  ResetKPIs;
  lblPartidasResumen.Caption := '';
  lblMovsFutResumen.Caption := '';
  lblDispVeredicto.Caption := '';
  lblDondeUsaResumen.Caption := '';
  tlDisp.Clear;
  FPartidasCargadas := False;
  FMovsFutCargados := False;
  FDispCalculada := False;
  FDondeUsaCargado := False;
  FHistoricoCargado := False;
  FOFsCargadas := False;
  FProvCargados := False;
  FCliCargados := False;
  SetLength(FHistorico, 0);
  lblHistResumen.Caption := '';
  lblOFsResumen.Caption := '';
  lblProvResumen.Caption := '';
  lblCliResumen.Caption := '';
  if Assigned(pbHistorico) then pbHistorico.Invalidate;
end;
procedure TfrmArticleDetail.btnBuscarArticuloClick(Sender: TObject);
var
  Cod, Desc: string;
begin
  // En Demo el picker del ERP no aplica: rotamos por el catalogo demo (cada
  // clic pasa al siguiente articulo y recalcula), asi se ven las distintas
  // situaciones (fabricado con OF, compra pura, critico).
  if DemoMode.Active then
  begin
    Cod := SiguienteArticuloDemo;
    CargarArticulo(Cod);
    Exit;
  end;
  if FReader = nil then
  begin
    ShowMessage('No hay conector ERP activo.');
    Exit;
  end;
  if TfrmArticuloPicker.Execute(FReader, Cod, Desc) then
  begin
    FCodigoArticulo := Cod;
    FDescripcionArticulo := Desc;
    edArticulo.Text := Cod;
    lblDescripcion.Caption := Desc;
  end;
end;
procedure TfrmArticleDetail.CrearColumnasMovs;
begin
  cdsMovs.FieldDefs.Clear;
  cdsMovs.FieldDefs.Add('Fecha', ftDateTime);
  cdsMovs.FieldDefs.Add('Tipo', ftString, 20);
  cdsMovs.FieldDefs.Add('Concepto', ftString, 200);
  cdsMovs.FieldDefs.Add('Referencia', ftString, 60);
  cdsMovs.FieldDefs.Add('Almacen', ftString, 20);
  cdsMovs.FieldDefs.Add('Entrada', ftFloat);
  cdsMovs.FieldDefs.Add('Salida', ftFloat);
  cdsMovs.FieldDefs.Add('Saldo', ftFloat);
  cdsMovs.FieldDefs.Add('BajoMinimo', ftBoolean);
  cdsMovs.CreateDataSet;
end;
procedure TfrmArticleDetail.RellenarMovs(const AMovs: TArray<TMovStock>);
var
  i: Integer;
begin
  cdsMovs.DisableControls;
  try
    cdsMovs.EmptyDataSet;
    for i := 0 to High(AMovs) do
    begin
      cdsMovs.Append;
      cdsMovs.FieldByName('Fecha').AsDateTime    := AMovs[i].Fecha;
      cdsMovs.FieldByName('Tipo').AsString       := TipoToStr(AMovs[i].Tipo);
      cdsMovs.FieldByName('Concepto').AsString   := AMovs[i].Concepto;
      cdsMovs.FieldByName('Referencia').AsString := AMovs[i].Referencia;
      cdsMovs.FieldByName('Almacen').AsString    := AMovs[i].Almacen;
      cdsMovs.FieldByName('Entrada').AsFloat     := AMovs[i].UnidadesEntrada;
      cdsMovs.FieldByName('Salida').AsFloat      := AMovs[i].UnidadesSalida;
      cdsMovs.FieldByName('Saldo').AsFloat       := AMovs[i].SaldoAcumulado;
      cdsMovs.FieldByName('BajoMinimo').AsBoolean := AMovs[i].BajoMinimo;
      cdsMovs.Post;
    end;
    cdsMovs.First;
  finally
    cdsMovs.EnableControls;
  end;
  // Columnes nomes la primera vegada (evita duplicacions); read-only sempre.
  if grdMovsView.ColumnCount = 0 then
  begin
    grdMovsView.BeginUpdate;
    try
      grdMovsView.DataController.CreateAllItems;
      for i := 0 to grdMovsView.ColumnCount - 1 do
      begin
        grdMovsView.Columns[i].Options.Editing := False;
        grdMovsView.Columns[i].Options.Focusing := False;
      end;
    finally
      grdMovsView.EndUpdate;
    end;
  end;
  grdMovsView.ApplyBestFit(nil, True);
end;
function TfrmArticleDetail.TipoToStr(ATipo: TTipoMovStock): string;
begin
  case ATipo of
    tmStockActual:   Result := 'Stock actual';
    tmCompra:        Result := 'Compra';
    tmVenta:         Result := 'Venta';
    tmProduccionOF:  Result := 'Producci'#243'n';
    tmConsumoOF:     Result := 'Consumo';
  else
    Result := '';
  end;
end;
procedure TfrmArticleDetail.PintarResumen(const AResumen: TResumenProyeccion);
begin
  lblValStockInicial.Caption  := FormatFloat('#,##0.##', AResumen.StockInicial);
  lblValTotalEntradas.Caption := FormatFloat('+#,##0.##;-#,##0.##;0', AResumen.TotalEntradas);
  lblValTotalSalidas.Caption  := FormatFloat('-#,##0.##;+#,##0.##;0', AResumen.TotalSalidas);
  lblValStockFinal.Caption    := FormatFloat('#,##0.##', AResumen.StockFinal);
  lblValStockMinimo.Caption   := FormatFloat('#,##0.##', FStockMinimo);
  if AResumen.AlgunaVezBajoMinimo then
  begin
    lblAviso.Caption := Format(
      '!! Bajo m'#237'nimo el %s: saldo %s (m'#237'nimo %s)',
      [FormatDateTime('dd/mm/yyyy', AResumen.FechaSaldoMinimo),
       FormatFloat('#,##0.##', AResumen.SaldoMinimoAlcanzado),
       FormatFloat('#,##0.##', FStockMinimo)]);
    lblAviso.Font.Color := clRed;
    lblAviso.Visible := True;
  end
  else if AResumen.StockFinal < 0 then
  begin
    lblAviso.Caption := '!! Stock final negativo';
    lblAviso.Font.Color := clRed;
    lblAviso.Visible := True;
  end
  else
    lblAviso.Visible := False;
  if AResumen.StockFinal < 0 then
    lblValStockFinal.Font.Color := clRed
  else if (FStockMinimo > 0) and (AResumen.StockFinal < FStockMinimo) then
    lblValStockFinal.Font.Color := clMaroon
  else
    lblValStockFinal.Font.Color := clWindowText;
end;

procedure TfrmArticleDetail.CalcularRecomendacion(const AArticulo: TArticuloErp;
  AProjector: TStockProjector);
var
  Repo: TMrpParamRepo;
  HasOvr: Boolean;
  Ovr: TMrpParamOverride;
  Param: TMrpParam;
  Almacen: string;
  Almacenes: TArray<string>;
begin
  // Almacen para resolver parametros: si hay UN solo almacen seleccionado, se usa
  // su override/ArticulosAlmacen; si hay varios o ninguno, se usa el global ('').
  Almacenes := AlmacenesSeleccionados;
  if Length(Almacenes) = 1 then
    Almacen := Almacenes[0]
  else
    Almacen := '';

  // Override propio (FS_PL_MrpParam) desde la BD del Planner.
  HasOvr := False;
  Ovr := Default(TMrpParamOverride);
  Repo := TMrpParamRepo.Create(DMPlanner.ADOConnection);
  try
    Repo.LoadFromDB(DMPlanner.CodigoEmpresa);
    HasOvr := Repo.TryGet(AArticulo.Codigo, Almacen, Ovr);
  finally
    Repo.Free;
  end;

  // Fusiona override + Sage -> parametros efectivos, y genera la recomendacion.
  Param := TMrpRecommender.ResolveParam(AArticulo, HasOvr, Ovr, Almacen);
  FUltimaRecom := TMrpRecommender.Recommend(Param, FDescripcionArticulo,
    AProjector, Date);

  // Pinta el panel.
  if FUltimaRecom.Accion = maNinguna then
  begin
    pnlRecomendacion.Visible := False;
    Exit;
  end;

  lblRecomendacion.Caption := FUltimaRecom.Motivo;
  if FUltimaRecom.EsUrgente then
    lblRecomendacion.Font.Color := clRed
  else
    lblRecomendacion.Font.Color := clWindowText;

  // El boton solo tiene sentido para fabricacion (pont al Gantt, F2). Para compra
  // de momento queda informativo (sin boton).
  if FUltimaRecom.Accion in [maFabricar, maSubcontratar] then
  begin
    btnAccionMrp.Caption := 'Fabricar '#8594' Gantt';
    btnAccionMrp.Visible := True;
  end
  else
    btnAccionMrp.Visible := False;

  pnlRecomendacion.Visible := True;
end;

procedure TfrmArticleDetail.btnAccionMrpClick(Sender: TObject);
var
  Versiones: TArray<SmallInt>;
  Operaciones: TArray<TFormulaOperacion>;
  CentroPref: string;
  HorasUnit, HorasTotal: Double;
  i: Integer;
  Puente: TMrpPropuestaBacklog;
  RawId: Int64;
begin
  if FUltimaRecom.Accion = maNinguna then Exit;
  if not (FUltimaRecom.Accion in [maFabricar, maSubcontratar]) then Exit;

  // En Demo no se crea nada real en el Backlog (datos ficticios).
  if DemoMode.Active then
  begin
    ShowMessage(Format(
      'MODO DEMO'#13#10#13#10 +
      'Aqu'#237' se crear'#237'a una propuesta de fabricaci'#243'n en el Backlog:'#13#10#13#10 +
      'Art'#237'culo: %s'#13#10'Cantidad: %s ud.'#13#10 +
      'Lanzar antes de: %s'#13#10#13#10 +
      'En modo Demo no se crea ninguna orden real.',
      [FUltimaRecom.CodigoArticulo,
       FormatFloat('#,##0.##', FUltimaRecom.Cantidad),
       FormatDateTime('dd/mm/yyyy', FUltimaRecom.FechaLanzamiento)]));
    Exit;
  end;

  if MessageDlg(Format(
      'Crear propuesta de fabricaci'#243'n en el Backlog?'#13#10#13#10 +
      'Art'#237'culo: %s'#13#10'Cantidad: %s ud.'#13#10 +
      'Fecha necesaria: %s'#13#10'Lanzar antes de: %s',
      [FUltimaRecom.CodigoArticulo,
       FormatFloat('#,##0.##', FUltimaRecom.Cantidad),
       FormatDateTime('dd/mm/yyyy', FUltimaRecom.FechaNecesaria),
       FormatDateTime('dd/mm/yyyy', FUltimaRecom.FechaLanzamiento)]),
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  // Centro preferente + horas estimadas desde la formula (primera version),
  // sumando el tiempo de las operaciones * cantidad. Si no hay formula, queda
  // sin centro/horas y el planificador lo ajusta en el Backlog.
  CentroPref := '';
  HorasUnit := 0;
  if FReader <> nil then
  begin
    Versiones := FReader.ReadFormulaVersiones(FUltimaRecom.CodigoArticulo);
    if Length(Versiones) > 0 then
    begin
      Operaciones := FReader.ReadFormulaOperaciones(
        FUltimaRecom.CodigoArticulo, Versiones[0]);
      for i := 0 to High(Operaciones) do
      begin
        if (CentroPref = '') and (Trim(Operaciones[i].CentroTrabajo) <> '') then
          CentroPref := Operaciones[i].CentroTrabajo;  // primer centro de ruta
        HorasUnit := HorasUnit + Operaciones[i].TiempoTotalMin;
      end;
    end;
  end;
  // TiempoTotalMin de las operaciones suele ser por lote de calculo; aqui lo
  // tratamos como minutos por unidad de forma simple (horas = min/60 * cantidad).
  // TODO: refinar con UnidadesCalculo de la formula en la fase BOM.
  HorasTotal := (HorasUnit / 60.0) * FUltimaRecom.Cantidad;

  // Si la formula no da centro, aterrizar en el centro de sistema SIN CENTRO
  // (cajon de sastre); el planificador lo movera al centro real desde el Gantt.
  if Trim(CentroPref) = '' then
    CentroPref := CENTRO_SIN_CENTRO;

  Puente := TMrpPropuestaBacklog.Create(DMPlanner.ADOConnection,
    DMPlanner.CodigoEmpresa);
  try
    RawId := Puente.InsertarPropuesta(FUltimaRecom, HorasTotal, CentroPref);
  finally
    Puente.Free;
  end;

  if RawId > 0 then
    ShowMessage(Format(
      'Propuesta creada en el Backlog (OF MRP).'#13#10 +
      'Plan'#237'ficala desde la pantalla de Backlog / Carga pendiente.'#13#10#13#10 +
      'Art'#237'culo: %s  -  %s ud.',
      [FUltimaRecom.CodigoArticulo, FormatFloat('#,##0.##', FUltimaRecom.Cantidad)]))
  else
    ShowMessage('No se pudo crear la propuesta en el Backlog.');
end;

procedure TfrmArticleDetail.btnCalcularClick(Sender: TObject);
begin
  // En modo Demo no hace falta ERP (los datos son ficticios).
  if (FReader = nil) and (not DemoMode.Active) then
  begin
    ShowMessage('No hay conector ERP activo.');
    Exit;
  end;
  if Trim(edArticulo.Text) = '' then
  begin
    ShowMessage('Selecciona un art'#237'culo.');
    Exit;
  end;
  // Muestra el dialogo de "cargando" (spinner) mientras se calcula la proyeccion.
  // ShowBusy ejecuta en el hilo principal (DoCalcular toca controles de UI).
  // ShowBusy espera un TProc (metodo anonimo): envolvemos DoCalcular.
  uBusyDialog.ShowBusy(Self, 'Calculando proyecci'#243'n de stock...',
    procedure
    begin
      DoCalcular;
    end);
end;

procedure TfrmArticleDetail.DoCalcular;
var
  Almacenes: TArray<string>;
  FechaCorte: TDateTime;
  StockBase: TArray<TStockDisponibleErp>;
  Compras: TArray<TEntradaFuturaErp>;
  Ventas: TArray<TSalidaFuturaVentaErp>;
  MovsOF: TArray<TMovOFErp>;
  Articulos: TArray<TArticuloErp>;
  Proy: TStockProjector;
  StockInicial: Double;
  i: Integer;
  Resumen: TResumenProyeccion;
  StockTotal, PendRecibir, PendServir: Double;
begin
  FCodigoArticulo := Trim(edArticulo.Text);
  Almacenes := AlmacenesSeleccionados;
  FechaCorte := dtFecha.Date;
  mmoLog.Lines.Clear;
  LimpiarResultados;
  FPartidasCargadas := False;
  FMovsFutCargados := False;
  FDispCalculada := False;
  FDondeUsaCargado := False;
  FHistoricoCargado := False;
  lblDescripcion.Caption := FDescripcionArticulo;
  Screen.Cursor := crHourGlass;
  try
    try
      // ------------------------------------------------------------------
      // MODO DEMO: en vez de las 5 lecturas del ERP, generamos un escenario
      // MRP coherente y ficticio (stock + compras + ventas que provocan
      // ruptura + OF que la recupera). La proyeccion, el time-phased view,
      // los KPIs y la recomendacion se calculan igual a partir de estos datos.
      // ------------------------------------------------------------------
      if DemoMode.Active then
      begin
        LogInfo('== MODO DEMO: datos ficticios (no se consulta el ERP) ==');
        Articulos := TArray<TArticuloErp>.Create(uDemoMode.DemoArticulo(FCodigoArticulo));
        StockBase := uDemoMode.DemoStockDisponible(FCodigoArticulo);
        Compras   := uDemoMode.DemoEntradasCompra(FCodigoArticulo, Date);
        Ventas    := uDemoMode.DemoSalidasVenta(FCodigoArticulo, Date);
        MovsOF    := uDemoMode.DemoMovimientosOF(FCodigoArticulo, Date);
      end
      else
      begin
        // 1) Stock m'inimo (para alerta) + datos del articulo (parametros MRP)
        Articulos := FReader.ReadArticulos(FCodigoArticulo);
      end;
      FStockMinimo := 0;
      FDescripcionArticulo := '';
      FArticuloLeido := False;
      for i := 0 to High(Articulos) do
        if SameText(Articulos[i].Codigo, FCodigoArticulo) then
        begin
          FStockMinimo := Articulos[i].StockMinimo;
          FDescripcionArticulo := Articulos[i].Descripcion;
          FArticuloActual := Articulos[i];   // guarda parametros MRP de Sage
          FArticuloLeido := True;
          Break;
        end;
      lblDescripcion.Caption := FDescripcionArticulo;
      // Indicador FABRICAR (tiene formula) / COMPRAR (sin formula). Sirve tanto
      // en modo real como en Demo: se lee de los parametros del articulo.
      ActualizarTipoAprov;
      LogInfo(Format('Art'#237'culo %s - %s (m'#237'nimo: %s)',
        [FCodigoArticulo, FDescripcionArticulo,
         FormatFloat('#,##0.##', FStockMinimo)]));
      // 2) Stock inicial: agregat de AcumuladoStock_Neco
      //    base = Saldo - Reservado, filtrant per almacenes si n'hi ha.
      //    (En Demo StockBase ya viene de DemoStockDisponible.)
      if not DemoMode.Active then
        StockBase := FReader.ReadStockDisponible(FCodigoArticulo, '');
      StockInicial := 0;
      StockTotal := 0;
      for i := 0 to High(StockBase) do
      begin
        if (Length(Almacenes) > 0) and
           (not MatchStr(StockBase[i].CodigoAlmacen, Almacenes)) then
          Continue;
        StockInicial := StockInicial + StockBase[i].Disponible;
        StockTotal   := StockTotal + StockBase[i].UnidadSaldo;
      end;
      LogInfo(Format('Stock inicial (Saldo - Reservado): %s',
        [FormatFloat('#,##0.##', StockInicial)]));
      // 3) Compras pendents (entrades futures). En Demo ya viene generado.
      if not DemoMode.Active then
        Compras := FReader.ReadEntradasFuturasFiltered(
          FCodigoArticulo, Almacenes, 0, FechaCorte);
      PendRecibir := 0;
      for i := 0 to High(Compras) do
        PendRecibir := PendRecibir + Compras[i].UnidadesPendientes;
      LogInfo(Format('Pedidos compra pendientes: %d l'#237'neas', [Length(Compras)]));
      // 4) Ventas pendents (sortides futures). En Demo ya viene generado.
      if not DemoMode.Active then
        Ventas := FReader.ReadSalidasFuturasVenta(
          FCodigoArticulo, Almacenes, 0, FechaCorte);
      PendServir := 0;
      for i := 0 to High(Ventas) do
        PendServir := PendServir + Ventas[i].UnidadesPendientes;
      LogInfo(Format('Pedidos venta pendientes: %d l'#237'neas', [Length(Ventas)]));
      // 5) OFs pendents (producci'o + consums). En Demo ya viene generado.
      if not DemoMode.Active then
        MovsOF := FReader.ReadMovimientosOFsPendientes(
          FCodigoArticulo, Almacenes, FechaCorte);
      LogInfo(Format('Movimientos OF pendientes: %d', [Length(MovsOF)]));
    except
      on E: Exception do
      begin
        LogError(E.Message);
        Exit;
      end;
    end;
    // 6) Projecta
    Proy := TStockProjector.Create;
    try
      Proy.StockInicial := StockInicial;
      Proy.StockMinimo := FStockMinimo;
      Proy.SetEntradasCompra(Compras);
      Proy.SetSalidasVenta(Ventas);
      Proy.SetMovimientosOF(MovsOF);
      RellenarMovs(Proy.MovimientosOrdenados);
      Resumen := Proy.Resumen(FechaCorte);
      PintarResumen(Resumen);
      ActualizarKPIs(StockTotal, StockInicial, PendRecibir, PendServir);
      LogInfo(Format('Stock proyectado a %s: %s',
        [FormatDateTime('dd/mm/yyyy', FechaCorte),
         FormatFloat('#,##0.##', Resumen.StockFinal)]));
      // 7) Recomendacion MRP (necesita el articulo con sus parametros).
      if FArticuloLeido then
        CalcularRecomendacion(FArticuloActual, Proy);
    finally
      Proy.Free;
    end;
    // En Demo, llenamos tambien el resto de tabs de golpe (con datos ficticios)
    // para que toda la ficha salga completa, no solo la proyeccion.
    if DemoMode.Active then
      CargarTabsDemo;
  finally
    Screen.Cursor := crDefault;
  end;
end;
procedure TfrmArticleDetail.grdMovsViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  RecIdx: Integer;
  IsBajoMinimo: Boolean;
  Saldo: Double;
  VSaldo: Variant;
begin
  // Time-Phased Stock View: colorea cada fila segun el estado del saldo proyectado.
  //   ROJO  -> ruptura (saldo < 0): no hay stock para cubrir la demanda de esa fecha.
  //   ROSA  -> bajo minimo (saldo >= 0 pero < stock minimo): zona de riesgo.
  //   verde -> primera fila de RECUPERACION (saldo vuelve a >= 0 tras una ruptura).
  //   normal-> OK.
  RecIdx := AViewInfo.GridRecord.RecordIndex;
  if RecIdx < 0 then Exit;

  VSaldo := Sender.DataController.Values[RecIdx,
    grdMovsView.GetColumnByFieldName('Saldo').Index];
  if VarIsNull(VSaldo) then Exit;
  Saldo := VSaldo;

  IsBajoMinimo := Sender.DataController.Values[RecIdx,
    grdMovsView.GetColumnByFieldName('BajoMinimo').Index];

  if Saldo < 0 then
  begin
    // Ruptura: rojo fuerte.
    ACanvas.Brush.Color := $008080FF;  // rojo claro (BGR)
    ACanvas.Font.Color := clWhite;
  end
  else if EsFilaRecuperacion(RecIdx) then
  begin
    // Recuperacion: primera fila que vuelve a >= 0 despues de una ruptura.
    ACanvas.Brush.Color := $00C0FFC0;  // verde claro
    ACanvas.Font.Color := clGreen;
  end
  else if IsBajoMinimo then
  begin
    ACanvas.Brush.Color := $00CCCCFF;  // rosat clar
    ACanvas.Font.Color := clMaroon;
  end;
end;

function TfrmArticleDetail.EsFilaRecuperacion(ARecIdx: Integer): Boolean;
var
  VPrev, VCur: Variant;
  PrevSaldo, CurSaldo: Double;
  Col: Integer;
begin
  // Recuperacion = esta fila tiene saldo >= 0 y la ANTERIOR estaba en ruptura
  // (< 0). La fila 0 nunca es recuperacion (no hay anterior).
  Result := False;
  if ARecIdx <= 0 then Exit;

  Col := grdMovsView.GetColumnByFieldName('Saldo').Index;
  VCur := grdMovsView.DataController.Values[ARecIdx, Col];
  VPrev := grdMovsView.DataController.Values[ARecIdx - 1, Col];
  if VarIsNull(VCur) or VarIsNull(VPrev) then Exit;

  CurSaldo := VCur;
  PrevSaldo := VPrev;
  Result := (CurSaldo >= 0) and (PrevSaldo < 0);
end;
procedure TfrmArticleDetail.LogInfo(const AMsg: string);
begin
  mmoLog.Lines.Add(Format('[%s] %s',
    [FormatDateTime('hh:nn:ss', Now), AMsg]));
end;
procedure TfrmArticleDetail.LogError(const AMsg: string);
begin
  mmoLog.Lines.Add(Format('[%s] ERROR: %s',
    [FormatDateTime('hh:nn:ss', Now), AMsg]));
end;
procedure TfrmArticleDetail.btnToggleLogClick(Sender: TObject);
begin

end;
// ============================================================================
// TAB "Stock por partida / lote"
// ============================================================================
procedure TfrmArticleDetail.CrearColumnasPartidas;
begin
  cdsPartidas.FieldDefs.Clear;
  cdsPartidas.FieldDefs.Add('Almacen', ftString, 20);
  cdsPartidas.FieldDefs.Add('Partida', ftString, 40);
  cdsPartidas.FieldDefs.Add('Color', ftString, 20);
  cdsPartidas.FieldDefs.Add('Talla', ftString, 20);
  cdsPartidas.FieldDefs.Add('Ubicacion', ftString, 40);
  cdsPartidas.FieldDefs.Add('Caducidad', ftDateTime);
  cdsPartidas.FieldDefs.Add('Saldo', ftFloat);
  cdsPartidas.FieldDefs.Add('Importe', ftFloat);
  cdsPartidas.FieldDefs.Add('PrecioMedio', ftFloat);
  cdsPartidas.FieldDefs.Add('UltimaEntrada', ftDateTime);
  cdsPartidas.FieldDefs.Add('UltimaSalida', ftDateTime);
  cdsPartidas.CreateDataSet;
end;
procedure TfrmArticleDetail.pgcTabsChange(Sender: TObject);
begin
  if Trim(edArticulo.Text) = '' then Exit;
  if (pgcTabs.ActivePage = tabPartidas) and (not FPartidasCargadas) then
    CargarPartidas
  else if (pgcTabs.ActivePage = tabMovimientos) and (not FMovsFutCargados) then
    CargarMovsFut
  else if (pgcTabs.ActivePage = tabDisponibilidad) and (not FDispCalculada) then
    CalcularDisponibilidad
  else if (pgcTabs.ActivePage = tabDondeUsa) and (not FDondeUsaCargado) then
    CargarDondeUsa
  else if (pgcTabs.ActivePage = tabHistorico) and (not FHistoricoCargado) then
    CargarHistorico
  else if (pgcTabs.ActivePage = tabOFs) and (not FOFsCargadas) then
    CargarOFs
  else if (pgcTabs.ActivePage = tabProveedores) and (not FProvCargados) then
    CargarProveedores
  else if (pgcTabs.ActivePage = tabClientes) and (not FCliCargados) then
    CargarClientes;
end;
procedure TfrmArticleDetail.btnRecargarPartidasClick(Sender: TObject);
begin
  CargarPartidas;
end;
procedure TfrmArticleDetail.chkSoloConSaldoClick(Sender: TObject);
begin
  AplicarFiltroPartidas;
end;
procedure TfrmArticleDetail.CargarPartidas;
var
  Almacenes: TArray<string>;
  Data: TArray<TStockArticuloErp>;
  i, NFilas: Integer;
  TotalSaldo, TotalImporte: Double;
  AlmFiltro: string;
begin
  if (FReader = nil) and (not DemoMode.Active) then
  begin
    ShowMessage('No hay conector ERP activo.');
    Exit;
  end;
  FCodigoArticulo := Trim(edArticulo.Text);
  if FCodigoArticulo = '' then Exit;
  Almacenes := AlmacenesSeleccionados;
  Screen.Cursor := crHourGlass;
  cdsPartidas.DisableControls;
  try
    cdsPartidas.EmptyDataSet;
    try
      if DemoMode.Active then
        Data := uDemoMode.DemoPartidas(FCodigoArticulo, Date)
      else
        // Periodo=99 = acumulado del ejercicio (saldo actual por partida).
        // Ejercicio=0 -> el reader pilla el ultimo.
        Data := FReader.ReadStockArticulo(FCodigoArticulo, '', '', 0, 99);
    except
      on E: Exception do
      begin
        LogError('Error cargando partidas: ' + E.Message);
        Exit;
      end;
    end;
    NFilas := 0;
    TotalSaldo := 0;
    TotalImporte := 0;
    for i := 0 to High(Data) do
    begin
      // Filtre exacte per almacen seleccionat (si n'hi ha).
      if Length(Almacenes) > 0 then
      begin
        if not MatchStr(Trim(Data[i].CodigoAlmacen), Almacenes) then
          Continue;
      end;
      // Filtre exacte per article (ReadStockArticulo fa LIKE).
      if not SameText(Trim(Data[i].CodigoArticulo), FCodigoArticulo) then
        Continue;
      cdsPartidas.Append;
      cdsPartidas.FieldByName('Almacen').AsString    := Data[i].CodigoAlmacen;
      cdsPartidas.FieldByName('Partida').AsString    := Data[i].Partida;
      cdsPartidas.FieldByName('Color').AsString      := Data[i].CodigoColor;
      cdsPartidas.FieldByName('Talla').AsString      := Data[i].CodigoTalla;
      cdsPartidas.FieldByName('Ubicacion').AsString  := Data[i].Ubicacion;
      if Data[i].FechaCaducidad > 0 then
        cdsPartidas.FieldByName('Caducidad').AsDateTime := Data[i].FechaCaducidad
      else
        cdsPartidas.FieldByName('Caducidad').Clear;
      cdsPartidas.FieldByName('Saldo').AsFloat       := Data[i].UnidadSaldo;
      cdsPartidas.FieldByName('Importe').AsFloat     := Data[i].ImporteSaldo;
      cdsPartidas.FieldByName('PrecioMedio').AsFloat := Data[i].PrecioMedio;
      if Data[i].FechaUltimaEntrada > 0 then
        cdsPartidas.FieldByName('UltimaEntrada').AsDateTime := Data[i].FechaUltimaEntrada
      else
        cdsPartidas.FieldByName('UltimaEntrada').Clear;
      if Data[i].FechaUltimaSalida > 0 then
        cdsPartidas.FieldByName('UltimaSalida').AsDateTime := Data[i].FechaUltimaSalida
      else
        cdsPartidas.FieldByName('UltimaSalida').Clear;
      cdsPartidas.Post;
      Inc(NFilas);
      TotalSaldo := TotalSaldo + Data[i].UnidadSaldo;
      TotalImporte := TotalImporte + Data[i].ImporteSaldo;
    end;
    cdsPartidas.First;
    if Length(Almacenes) > 0 then
      AlmFiltro := ' (' + IntToStr(Length(Almacenes)) + ' almac' + #233 + 'n/es)'
    else
      AlmFiltro := ' (todos los almacenes)';
    lblPartidasResumen.Caption := Format(
      '%d partidas%s   Saldo total: %s   Importe: %s ' + #8364,
      [NFilas, AlmFiltro,
       FormatFloat('#,##0.##', TotalSaldo),
       FormatFloat('#,##0.##', TotalImporte)]);
    if grdPartidasView.ColumnCount = 0 then
    begin
      grdPartidasView.BeginUpdate;
      try
        grdPartidasView.DataController.CreateAllItems;
        for i := 0 to grdPartidasView.ColumnCount - 1 do
        begin
          grdPartidasView.Columns[i].Options.Editing := False;
          grdPartidasView.Columns[i].Options.Focusing := False;
        end;
      finally
        grdPartidasView.EndUpdate;
      end;
    end;
    AplicarFiltroPartidas;
    FPartidasCargadas := True;
  finally
    cdsPartidas.EnableControls;
    Screen.Cursor := crDefault;
  end;
  // BestFit despres de tornar a habilitar el control: aixi mesura amb les
  // dades reals ja al data controller.
  grdPartidasView.ApplyBestFit(nil, True);
end;
procedure TfrmArticleDetail.AplicarFiltroPartidas;
begin
  if not cdsPartidas.Active then Exit;
  cdsPartidas.Filtered := False;
  if chkSoloConSaldo.Checked then
  begin
    cdsPartidas.Filter := 'Saldo <> 0';
    cdsPartidas.Filtered := True;
  end
  else
    cdsPartidas.Filter := '';
end;
procedure TfrmArticleDetail.grdPartidasViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  RecIdx, ColCadIdx: Integer;
  FldCad: TField;
  CadVal: Variant;
begin
  RecIdx := AViewInfo.GridRecord.RecordIndex;
  if RecIdx < 0 then Exit;
  // Marcar en rojo claro las filas con caducidad pasada o proxima (30 dias).
  FldCad := cdsPartidas.FieldByName('Caducidad');
  ColCadIdx := grdPartidasView.GetColumnByFieldName('Caducidad').Index;
  CadVal := Sender.DataController.Values[RecIdx, ColCadIdx];
  if VarIsNull(CadVal) or VarIsClear(CadVal) then Exit;
  if not (FldCad.DataType in [ftDate, ftDateTime, ftTimeStamp]) then Exit;
  if VarToDateTime(CadVal) < Date then
  begin
    ACanvas.Brush.Color := $00CCCCFF;
    ACanvas.Font.Color := clMaroon;
  end
  else if VarToDateTime(CadVal) < Date + 30 then
  begin
    ACanvas.Brush.Color := $00CCFFFF;
  end;
end;
// ============================================================================
// TAB "Movimientos futuros"
// ============================================================================
procedure TfrmArticleDetail.CrearColumnasMovsFut;
begin
  cdsMovsFut.FieldDefs.Clear;
  cdsMovsFut.FieldDefs.Add('Fecha', ftDateTime);
  cdsMovsFut.FieldDefs.Add('Tipo', ftString, 20);
  cdsMovsFut.FieldDefs.Add('Documento', ftString, 40);
  cdsMovsFut.FieldDefs.Add('Tercero', ftString, 120);
  cdsMovsFut.FieldDefs.Add('Almacen', ftString, 20);
  cdsMovsFut.FieldDefs.Add('Partida', ftString, 40);
  cdsMovsFut.FieldDefs.Add('Unidades', ftFloat);
  cdsMovsFut.FieldDefs.Add('Precio', ftFloat);
  cdsMovsFut.FieldDefs.Add('Importe', ftFloat);
  cdsMovsFut.FieldDefs.Add('FechaTope', ftDateTime);
  cdsMovsFut.FieldDefs.Add('Estado', ftInteger);
  cdsMovsFut.CreateDataSet;
end;
procedure TfrmArticleDetail.btnRecargarMovsFutClick(Sender: TObject);
begin
  CargarMovsFut;
end;
procedure TfrmArticleDetail.MovFutTipoChange(Sender: TObject);
begin
  AplicarFiltroMovsFut;
end;
procedure TfrmArticleDetail.CargarMovsFut;
var
  Almacenes: TArray<string>;
  Compras: TArray<TEntradaFuturaErp>;
  Ventas: TArray<TSalidaFuturaVentaErp>;
  MovsOF: TArray<TMovOFErp>;
  Desde, Hasta: TDateTime;
  i, NTot: Integer;
  TotEntradas, TotSalidas: Double;
begin
  if (FReader = nil) and (not DemoMode.Active) then
  begin
    ShowMessage('No hay conector ERP activo.');
    Exit;
  end;
  FCodigoArticulo := Trim(edArticulo.Text);
  if FCodigoArticulo = '' then Exit;
  Almacenes := AlmacenesSeleccionados;
  Desde := dtMovsFutDesde.Date;
  Hasta := dtMovsFutHasta.Date;
  Screen.Cursor := crHourGlass;
  cdsMovsFut.DisableControls;
  try
    cdsMovsFut.EmptyDataSet;
    try
      if DemoMode.Active then
      begin
        // Reutiliza el mismo escenario que el ATP (compras + ventas + OF).
        Compras := uDemoMode.DemoEntradasCompra(FCodigoArticulo, Date);
        Ventas  := uDemoMode.DemoSalidasVenta(FCodigoArticulo, Date);
        MovsOF  := uDemoMode.DemoMovimientosOF(FCodigoArticulo, Date);
      end
      else
      begin
        Compras := FReader.ReadEntradasFuturasFiltered(
          FCodigoArticulo, Almacenes, Desde, Hasta);
        Ventas := FReader.ReadSalidasFuturasVenta(
          FCodigoArticulo, Almacenes, Desde, Hasta);
        MovsOF := FReader.ReadMovimientosOFsPendientes(
          FCodigoArticulo, Almacenes, Hasta);
      end;
    except
      on E: Exception do
      begin
        LogError('Error cargando movimientos futuros: ' + E.Message);
        Exit;
      end;
    end;
    NTot := 0;
    TotEntradas := 0;
    TotSalidas := 0;
    // Compras
    for i := 0 to High(Compras) do
    begin
      cdsMovsFut.Append;
      cdsMovsFut.FieldByName('Fecha').AsDateTime := Compras[i].FechaNecesaria;
      cdsMovsFut.FieldByName('Tipo').AsString    := 'Compra';
      cdsMovsFut.FieldByName('Documento').AsString :=
        Format('%s/%d', [Compras[i].SeriePedido, Compras[i].NumeroPedido]);
      cdsMovsFut.FieldByName('Tercero').AsString  :=
        Compras[i].CodigoProveedor + ' - ' + Compras[i].RazonSocialProveedor;
      cdsMovsFut.FieldByName('Almacen').AsString  := Compras[i].CodigoAlmacen;
      cdsMovsFut.FieldByName('Partida').AsString  := Compras[i].Partida;
      cdsMovsFut.FieldByName('Unidades').AsFloat  := Compras[i].UnidadesPendientes;
      cdsMovsFut.FieldByName('Precio').AsFloat    := Compras[i].Precio;
      cdsMovsFut.FieldByName('Importe').AsFloat   := Compras[i].ImporteNetoPendiente;
      if Compras[i].FechaTope > 0 then
        cdsMovsFut.FieldByName('FechaTope').AsDateTime := Compras[i].FechaTope
      else
        cdsMovsFut.FieldByName('FechaTope').Clear;
      cdsMovsFut.FieldByName('Estado').AsInteger := Compras[i].Estado;
      cdsMovsFut.Post;
      Inc(NTot);
      TotEntradas := TotEntradas + Compras[i].UnidadesPendientes;
    end;
    // Ventas
    for i := 0 to High(Ventas) do
    begin
      cdsMovsFut.Append;
      cdsMovsFut.FieldByName('Fecha').AsDateTime := Ventas[i].FechaNecesaria;
      cdsMovsFut.FieldByName('Tipo').AsString    := 'Venta';
      cdsMovsFut.FieldByName('Documento').AsString :=
        Format('%s/%d', [Ventas[i].SeriePedido, Ventas[i].NumeroPedido]);
      cdsMovsFut.FieldByName('Tercero').AsString  :=
        Ventas[i].CodigoCliente + ' - ' + Ventas[i].RazonSocialCliente;
      cdsMovsFut.FieldByName('Almacen').AsString  := Ventas[i].CodigoAlmacen;
      cdsMovsFut.FieldByName('Partida').AsString  := '';
      cdsMovsFut.FieldByName('Unidades').AsFloat  := -Ventas[i].UnidadesPendientes;
      cdsMovsFut.FieldByName('Precio').AsFloat    := Ventas[i].Precio;
      cdsMovsFut.FieldByName('Importe').AsFloat   :=
        Ventas[i].Precio * Ventas[i].UnidadesPendientes;
      if Ventas[i].FechaTope > 0 then
        cdsMovsFut.FieldByName('FechaTope').AsDateTime := Ventas[i].FechaTope
      else
        cdsMovsFut.FieldByName('FechaTope').Clear;
      cdsMovsFut.FieldByName('Estado').AsInteger := Ventas[i].Estado;
      cdsMovsFut.Post;
      Inc(NTot);
      TotSalidas := TotSalidas + Ventas[i].UnidadesPendientes;
    end;
    // OFs (producci'o = entrada; consum = sortida)
    for i := 0 to High(MovsOF) do
    begin
      // Filtre per data inicial: el reader nomes filtra per FechaHasta
      if MovsOF[i].Fecha < Desde then Continue;
      cdsMovsFut.Append;
      cdsMovsFut.FieldByName('Fecha').AsDateTime := MovsOF[i].Fecha;
      if MovsOF[i].EsProduccion then
        cdsMovsFut.FieldByName('Tipo').AsString := 'Producci' + #243 + 'n OF'
      else
        cdsMovsFut.FieldByName('Tipo').AsString := 'Consumo OF';
      cdsMovsFut.FieldByName('Documento').AsString :=
        Format('OF %s/%d', [MovsOF[i].SerieFabricacion, MovsOF[i].NumeroFabricacion]);
      cdsMovsFut.FieldByName('Tercero').AsString  := '';
      cdsMovsFut.FieldByName('Almacen').AsString  := MovsOF[i].CodigoAlmacen;
      cdsMovsFut.FieldByName('Partida').AsString  := '';
      if MovsOF[i].EsProduccion then
      begin
        cdsMovsFut.FieldByName('Unidades').AsFloat := MovsOF[i].Unidades;
        TotEntradas := TotEntradas + MovsOF[i].Unidades;
      end
      else
      begin
        cdsMovsFut.FieldByName('Unidades').AsFloat := -MovsOF[i].Unidades;
        TotSalidas := TotSalidas + MovsOF[i].Unidades;
      end;
      cdsMovsFut.FieldByName('Precio').AsFloat   := 0;
      cdsMovsFut.FieldByName('Importe').AsFloat  := 0;
      cdsMovsFut.FieldByName('FechaTope').Clear;
      cdsMovsFut.FieldByName('Estado').AsInteger := MovsOF[i].EstadoOF;
      cdsMovsFut.Post;
      Inc(NTot);
    end;
    // Ordena per fecha
    cdsMovsFut.IndexFieldNames := 'Fecha';
    cdsMovsFut.First;
    lblMovsFutResumen.Caption := Format(
      '%d movimientos   Entradas: +%s   Salidas: -%s   Neto: %s',
      [NTot,
       FormatFloat('#,##0.##', TotEntradas),
       FormatFloat('#,##0.##', TotSalidas),
       FormatFloat('+#,##0.##;-#,##0.##;0', TotEntradas - TotSalidas)]);
    if grdMovsFutView.ColumnCount = 0 then
    begin
      grdMovsFutView.BeginUpdate;
      try
        grdMovsFutView.DataController.CreateAllItems;
        for i := 0 to grdMovsFutView.ColumnCount - 1 do
        begin
          grdMovsFutView.Columns[i].Options.Editing := False;
          grdMovsFutView.Columns[i].Options.Focusing := False;
        end;
      finally
        grdMovsFutView.EndUpdate;
      end;
    end;
    AplicarFiltroMovsFut;
    FMovsFutCargados := True;
  finally
    cdsMovsFut.EnableControls;
    Screen.Cursor := crDefault;
  end;
  grdMovsFutView.ApplyBestFit(nil, True);
end;
procedure TfrmArticleDetail.AplicarFiltroMovsFut;
var
  Parts: TArray<string>;
  Filtro: string;
begin
  if not cdsMovsFut.Active then Exit;
  cdsMovsFut.Filtered := False;
  SetLength(Parts, 0);
  if chkMovFutCompras.Checked then
  begin
    SetLength(Parts, Length(Parts) + 1);
    Parts[High(Parts)] := 'Tipo = ''Compra''';
  end;
  if chkMovFutVentas.Checked then
  begin
    SetLength(Parts, Length(Parts) + 1);
    Parts[High(Parts)] := 'Tipo = ''Venta''';
  end;
  if chkMovFutOFs.Checked then
  begin
    SetLength(Parts, Length(Parts) + 1);
    Parts[High(Parts)] := 'Tipo = ''Producci' + #243 + 'n OF''';
    SetLength(Parts, Length(Parts) + 1);
    Parts[High(Parts)] := 'Tipo = ''Consumo OF''';
  end;
  if Length(Parts) = 0 then
  begin
    // Cap tipus seleccionat -> filtre que no torna res
    cdsMovsFut.Filter := 'Tipo = ''__none__''';
    cdsMovsFut.Filtered := True;
    Exit;
  end;
  Filtro := String.Join(' OR ', Parts);
  cdsMovsFut.Filter := Filtro;
  cdsMovsFut.Filtered := True;
end;
procedure TfrmArticleDetail.grdMovsFutViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  RecIdx, ColUniIdx: Integer;
  UniVal: Variant;
  Unidades: Double;
begin
  RecIdx := AViewInfo.GridRecord.RecordIndex;
  if RecIdx < 0 then Exit;
  ColUniIdx := grdMovsFutView.GetColumnByFieldName('Unidades').Index;
  UniVal := Sender.DataController.Values[RecIdx, ColUniIdx];
  if VarIsNull(UniVal) or VarIsClear(UniVal) then Exit;
  Unidades := UniVal;
  if Unidades > 0 then
    ACanvas.Font.Color := clGreen
  else if Unidades < 0 then
    ACanvas.Font.Color := clMaroon;
end;
// ============================================================================
// TAB "Disponibilidad fabricacion" (BOM availability check)
// ============================================================================
//
// Explosiona el BOM del articulo recursivamente y comprueba si hay stock
// para fabricar la cantidad objetivo a fecha actual y a fecha futura.
//
// Logica:
//   - Para cada componente: Necesario = QtyObjetivo * UnidNec * (1+Mermas/100)
//   - Si es semielab y tiene formula propia: se intenta cubrir con stock
//     proyectado del semi. Lo que falte se explosiona a su BOM con un
//     multiplicador = NecRestante (de unidades de semielab).
//   - Stock proyectado por articulo: ReadStockDisponible + TStockProjector.
//   - Cache de stock por articulo para evitar N queries.
//   - Veredicto global: OK si todas las MP/Semis tienen stock proyectado
//     >= necesario; FALTA si alguna falla.
procedure TfrmArticleDetail.btnRecargarDispClick(Sender: TObject);
begin
  CalcularDisponibilidad;
end;
procedure TfrmArticleDetail.CalcularDisponibilidad;
type
  TStockArtCache = record
    Actual: Double;
    Proyectado: Double;
  end;
var
  CacheStock: TDictionary<string, TStockArtCache>;
  FechaObjetivo: TDateTime;
  QtyObjetivo: Double;
  FaltaGlobalActual, FaltaGlobalProy: Integer;
  function GetStockArt(const ACodArt: string): TStockArtCache;
  var
    Base: TArray<TStockDisponibleErp>;
    Compras: TArray<TEntradaFuturaErp>;
    Ventas: TArray<TSalidaFuturaVentaErp>;
    MovsOF: TArray<TMovOFErp>;
    Proy: TStockProjector;
    i: Integer;
    StockIni: Double;
    Res: TResumenProyeccion;
    SC: TStockArtCache;
  begin
    if CacheStock.TryGetValue(ACodArt, Result) then Exit;
    SC.Actual := 0;
    SC.Proyectado := 0;
    try
      Base := FReader.ReadStockDisponible(ACodArt, '');
      StockIni := 0;
      for i := 0 to High(Base) do
        StockIni := StockIni + Base[i].Disponible;
      SC.Actual := StockIni;
      Compras := FReader.ReadEntradasFuturasFiltered(
        ACodArt, [], 0, FechaObjetivo);
      Ventas := FReader.ReadSalidasFuturasVenta(
        ACodArt, [], 0, FechaObjetivo);
      MovsOF := FReader.ReadMovimientosOFsPendientes(
        ACodArt, [], FechaObjetivo);
      Proy := TStockProjector.Create;
      try
        Proy.StockInicial := StockIni;
        Proy.StockMinimo := 0;
        Proy.SetEntradasCompra(Compras);
        Proy.SetSalidasVenta(Ventas);
        Proy.SetMovimientosOF(MovsOF);
        Res := Proy.Resumen(FechaObjetivo);
        SC.Proyectado := Res.StockFinal;
      finally
        Proy.Free;
      end;
    except
      on E: Exception do
        LogError('Stock ' + ACodArt + ': ' + E.Message);
    end;
    CacheStock.Add(ACodArt, SC);
    Result := SC;
  end;
  procedure SetEstadoYColor(ANode: TcxTreeListNode;
    ANecesario, AStockActual, AStockProy: Double);
  var
    FaltaA, FaltaP: Double;
    Estado: string;
  begin
    FaltaA := ANecesario - AStockActual;
    FaltaP := ANecesario - AStockProy;
    if FaltaA < 0 then FaltaA := 0;
    if FaltaP < 0 then FaltaP := 0;
    ANode.Values[colDispNecesario.ItemIndex]   := FormatFloat('#,##0.##', ANecesario);
    ANode.Values[colDispStockActual.ItemIndex] := FormatFloat('#,##0.##', AStockActual);
    ANode.Values[colDispStockProy.ItemIndex]   := FormatFloat('#,##0.##', AStockProy);
    if FaltaA > 0 then
      ANode.Values[colDispFaltaActual.ItemIndex] := FormatFloat('#,##0.##', FaltaA)
    else
      ANode.Values[colDispFaltaActual.ItemIndex] := '';
    if FaltaP > 0 then
      ANode.Values[colDispFaltaProy.ItemIndex] := FormatFloat('#,##0.##', FaltaP)
    else
      ANode.Values[colDispFaltaProy.ItemIndex] := '';
    if FaltaP > 0 then
    begin
      Estado := 'CRITICO';
      Inc(FaltaGlobalProy);
      if FaltaA > 0 then Inc(FaltaGlobalActual);
    end
    else if FaltaA > 0 then
    begin
      Estado := 'FALTA HOY';
      Inc(FaltaGlobalActual);
    end
    else
      Estado := 'OK';
    ANode.Values[colDispEstado.ItemIndex] := Estado;
  end;
  procedure ExplosionarBOM(AParent: TcxTreeListNode; const ACodArt: string;
    AVersion: SmallInt; AMultiplicador: Double; ANivel: Integer);
  var
    Comps: TArray<TFormulaComponente>;
    i: Integer;
    Child: TcxTreeListNode;
    Necesario, StockUsable, NecRestante, Mermas: Double;
    Stk: TStockArtCache;
    EsSemiConBOM: Boolean;
  begin
    if ANivel > 10 then Exit; // safety
    try
      Comps := FReader.ReadFormulaComponentes(ACodArt, AVersion);
    except
      on E: Exception do
      begin
        LogError('Formula ' + ACodArt + ' v' + IntToStr(AVersion) + ': ' + E.Message);
        Exit;
      end;
    end;
    for i := 0 to High(Comps) do
    begin
      Mermas := Comps[i].Mermas;
      if Mermas < 0 then Mermas := 0;
      Necesario := AMultiplicador * Comps[i].UnidadesNecesarias *
                   (1 + Mermas / 100.0);
      Stk := GetStockArt(Comps[i].CodigoArticuloComponente);
      EsSemiConBOM := Comps[i].EsSemielaborado and (Comps[i].VersionFormulaComp > 0);
      Child := tlDisp.AddChild(AParent);
      Child.Values[colDispArticulo.ItemIndex]    := Comps[i].CodigoArticuloComponente;
      Child.Values[colDispDescripcion.ItemIndex] := Comps[i].DescripcionArticulo;
      if EsSemiConBOM then
        Child.Values[colDispTipo.ItemIndex] := 'S'
      else
        Child.Values[colDispTipo.ItemIndex] := 'M';
      SetEstadoYColor(Child, Necesario, Stk.Actual, Stk.Proyectado);
      if EsSemiConBOM then
      begin
        // Cuanto cubrimos con stock proyectado del semi
        StockUsable := Stk.Proyectado;
        if StockUsable > Necesario then StockUsable := Necesario;
        if StockUsable < 0 then StockUsable := 0;
        NecRestante := Necesario - StockUsable;
        if NecRestante > 0 then
          ExplosionarBOM(Child, Comps[i].CodigoArticuloComponente,
            Comps[i].VersionFormulaComp, NecRestante, ANivel + 1);
        Child.Expanded := True;
      end;
    end;
  end;
var
  RootNode: TcxTreeListNode;
  Cab: TFormulaCabecera;
  StkRoot: TStockArtCache;
begin
  if TabNoDisponibleEnDemo then Exit;
  if FReader = nil then
  begin
    ShowMessage('No hay conector ERP activo.');
    Exit;
  end;
  FCodigoArticulo := Trim(edArticulo.Text);
  if FCodigoArticulo = '' then
  begin
    ShowMessage('Selecciona un art'#237'culo.');
    Exit;
  end;
  QtyObjetivo := seDispCantidad.Value;
  if QtyObjetivo <= 0 then QtyObjetivo := 1;
  FechaObjetivo := dtDispFecha.Date;
  FaltaGlobalActual := 0;
  FaltaGlobalProy := 0;
  Screen.Cursor := crHourGlass;
  tlDisp.BeginUpdate;
  CacheStock := TDictionary<string, TStockArtCache>.Create;
  try
    tlDisp.Clear;
    // 1) Cabecera de formula del articulo raiz
    Cab := FReader.ReadFormulaCabecera(FCodigoArticulo);
    if not Cab.Encontrada then
    begin
      lblDispVeredicto.Caption :=
        'El art'#237'culo no tiene f'#243'rmula de fabricaci'#243'n definida.';
      lblDispVeredicto.Font.Color := clMaroon;
      FDispCalculada := True;
      Exit;
    end;
    // 2) Nodo raiz: el propio articulo objetivo
    StkRoot := GetStockArt(FCodigoArticulo);
    RootNode := tlDisp.Add;
    RootNode.Values[colDispArticulo.ItemIndex]    := FCodigoArticulo;
    RootNode.Values[colDispDescripcion.ItemIndex] := FDescripcionArticulo;
    RootNode.Values[colDispTipo.ItemIndex]        := 'P';
    SetEstadoYColor(RootNode, QtyObjetivo, StkRoot.Actual, StkRoot.Proyectado);
    // El nodo raiz no cuenta como "falta" si tiene formula: se va a fabricar
    if FaltaGlobalActual > 0 then Dec(FaltaGlobalActual);
    if FaltaGlobalProy > 0 then Dec(FaltaGlobalProy);
    // 3) Explosi'o recursiva
    ExplosionarBOM(RootNode, FCodigoArticulo, Cab.Version, QtyObjetivo, 1);
    RootNode.Expanded := True;
    // 4) Veredicto global
    if FaltaGlobalProy = 0 then
    begin
      lblDispVeredicto.Caption := Format(
        'OK: hay stock proyectado para fabricar %s uds de %s a fecha %s',
        [FormatFloat('#,##0.##', QtyObjetivo), FCodigoArticulo,
         FormatDateTime('dd/mm/yyyy', FechaObjetivo)]);
      lblDispVeredicto.Font.Color := clGreen;
    end
    else
    begin
      lblDispVeredicto.Caption := Format(
        'FALTA: %d componente(s) sin stock proyectado a %s (de los cuales %d ya faltan hoy)',
        [FaltaGlobalProy, FormatDateTime('dd/mm/yyyy', FechaObjetivo),
         FaltaGlobalActual]);
      lblDispVeredicto.Font.Color := clMaroon;
    end;
    FDispCalculada := True;
  finally
    CacheStock.Free;
    tlDisp.EndUpdate;
    Screen.Cursor := crDefault;
  end;
end;
procedure TfrmArticleDetail.tlDispCustomDrawDataCell(
  Sender: TcxCustomTreeList; ACanvas: TcxCanvas;
  AViewInfo: TcxTreeListEditCellViewInfo; var ADone: Boolean);
var
  Node: TcxTreeListNode;
  Estado: string;
begin
  Node := AViewInfo.Node;
  if Node = nil then Exit;
  Estado := VarToStr(Node.Values[colDispEstado.ItemIndex]);
  if Estado = 'CRITICO' then
  begin
    ACanvas.Brush.Color := $00CCCCFF;
    ACanvas.Font.Color := clMaroon;
  end
  else if Estado = 'FALTA HOY' then
  begin
    ACanvas.Brush.Color := $00CCFFFF;
  end
  else if Estado = 'OK' then
  begin
    if AViewInfo.Column = colDispEstado then
      ACanvas.Font.Color := clGreen;
  end;
end;
// ============================================================================
// TAB "Donde se usa" (where-used / pegging invers)
// ============================================================================
procedure TfrmArticleDetail.CrearColumnasDondeUsa;
begin
  cdsDondeUsa.FieldDefs.Clear;
  cdsDondeUsa.FieldDefs.Add('ArticuloPadre', ftString, 30);
  cdsDondeUsa.FieldDefs.Add('Descripcion', ftString, 100);
  cdsDondeUsa.FieldDefs.Add('Tipo', ftString, 10);
  cdsDondeUsa.FieldDefs.Add('Version', ftSmallint);
  cdsDondeUsa.FieldDefs.Add('Orden', ftInteger);
  cdsDondeUsa.FieldDefs.Add('Cantidad', ftFloat);
  cdsDondeUsa.FieldDefs.Add('UnidadMedida', ftString, 10);
  cdsDondeUsa.FieldDefs.Add('Mermas', ftFloat);
  cdsDondeUsa.FieldDefs.Add('Operacion', ftString, 30);
  cdsDondeUsa.CreateDataSet;
end;
procedure TfrmArticleDetail.btnRecargarDondeUsaClick(Sender: TObject);
begin
  CargarDondeUsa;
end;
procedure TfrmArticleDetail.CargarDondeUsa;
var
  Data: TArray<TDondeSeUsaErp>;
  i: Integer;
  Padres: TDictionary<string, Boolean>;
begin
  if (FReader = nil) and (not DemoMode.Active) then Exit;
  FCodigoArticulo := Trim(edArticulo.Text);
  if FCodigoArticulo = '' then Exit;
  Screen.Cursor := crHourGlass;
  try
    cdsDondeUsa.DisableControls;
    try
      cdsDondeUsa.EmptyDataSet;
      try
        if DemoMode.Active then
          Data := uDemoMode.DemoDondeSeUsa(FCodigoArticulo)
        else
          Data := FReader.ReadDondeSeUsa(FCodigoArticulo);
      except
        on E: Exception do
        begin
          LogError('D'#243'nde se usa: ' + E.Message);
          Exit;
        end;
      end;
      for i := 0 to High(Data) do
      begin
        cdsDondeUsa.Append;
        cdsDondeUsa.FieldByName('ArticuloPadre').AsString := Data[i].CodigoArticuloPadre;
        cdsDondeUsa.FieldByName('Descripcion').AsString   := Data[i].DescripcionArticuloPadre;
        cdsDondeUsa.FieldByName('Tipo').AsString          := Data[i].TipoArticuloPadre;
        cdsDondeUsa.FieldByName('Version').AsInteger      := Data[i].VersionFormula;
        cdsDondeUsa.FieldByName('Orden').AsInteger        := Data[i].Orden;
        cdsDondeUsa.FieldByName('Cantidad').AsFloat       := Data[i].UnidadesNecesarias;
        cdsDondeUsa.FieldByName('UnidadMedida').AsString  := Data[i].UnidadMedida;
        cdsDondeUsa.FieldByName('Mermas').AsFloat         := Data[i].Mermas;
        cdsDondeUsa.FieldByName('Operacion').AsString     := Data[i].Operacion;
        cdsDondeUsa.Post;
      end;
      cdsDondeUsa.First;
      Padres := TDictionary<string, Boolean>.Create;
      try
        for i := 0 to High(Data) do
          Padres.AddOrSetValue(Data[i].CodigoArticuloPadre, True);
        lblDondeUsaResumen.Caption := Format(
          'Este art'#237'culo se usa en %d f'#243'rmula(s) de %d art'#237'culo(s) distinto(s).',
          [Length(Data), Padres.Count]);
      finally
        Padres.Free;
      end;
    finally
      cdsDondeUsa.EnableControls;
    end;
    if grdDondeUsaView.ColumnCount = 0 then
      grdDondeUsaView.DataController.CreateAllItems;
    grdDondeUsaView.ApplyBestFit;
    FDondeUsaCargado := True;
  finally
    Screen.Cursor := crDefault;
  end;
end;
// ============================================================================
// KPI cards (cabecera)
// ============================================================================
// 6 targes de salut a la cabecera: Stock, Disponible, Minimo, Pte. recibir,
// Pte. servir, Estado. Es repinten en cada Calcular. Cada tarja te color de
// fons segons salut (verd/ambar/vermell/blau-info/gris-neutre).
const
  KPI_COLOR_NEUTRE  = TColor($00404040); // gris fosc (placeholder)
  KPI_COLOR_OK      = TColor($00377D22); // verd
  KPI_COLOR_INFO    = TColor($00A6651C); // blau-info (taronja-blau corp)
  KPI_COLOR_WARN    = TColor($000098D8); // ambar/groc
  KPI_COLOR_CRIT    = TColor($003C3CC8); // vermell
procedure TfrmArticleDetail.SetKPI(APanel: TPanel; AValLbl: TLabel;
  const AValor: string; AColorFondo: TColor);
begin
  APanel.Color := AColorFondo;
  AValLbl.Caption := AValor;
end;
procedure TfrmArticleDetail.ResetKPIs;
begin
  SetKPI(pnlKPI1, lblKPI1Val, '-', KPI_COLOR_NEUTRE);
  SetKPI(pnlKPI2, lblKPI2Val, '-', KPI_COLOR_NEUTRE);
  SetKPI(pnlKPI3, lblKPI3Val, '-', KPI_COLOR_NEUTRE);
  SetKPI(pnlKPI4, lblKPI4Val, '-', KPI_COLOR_NEUTRE);
  SetKPI(pnlKPI5, lblKPI5Val, '-', KPI_COLOR_NEUTRE);
  SetKPI(pnlKPI6, lblKPI6Val, '-', KPI_COLOR_NEUTRE);
end;
procedure TfrmArticleDetail.ActualizarTipoAprov;
begin
  // Badge en la cabecera: FABRICAR (verde) si el articulo tiene formula, o
  // COMPRAR (azul) si es de aprovisionamiento externo. Si no hay articulo
  // leido aun, se oculta. Vale igual en modo real y en Demo.
  if not FArticuloLeido then
  begin
    pnlTipoAprov.Visible := False;
    Exit;
  end;
  if FArticuloActual.TieneFormula then
  begin
    lblTipoAprov.Caption := 'FABRICAR';
    pnlTipoAprov.Color := TColor($002D7D2D);   // verde
  end
  else
  begin
    lblTipoAprov.Caption := 'COMPRAR';
    pnlTipoAprov.Color := TColor($00A6651C);    // azul-info corporativo
  end;
  pnlTipoAprov.Visible := True;
end;

procedure TfrmArticleDetail.ActualizarKPIs(AStockTotal, ADisponible,
  APendRecibir, APendServir: Double);
var
  ColorStock, ColorDisp, ColorCob, ColorABC: TColor;
  Cob: TCoberturaErp;
  CobTxt, ABCTxt: string;
  ABC: string;
begin
  // 1) Stock actual: gris-neutre, salvo que sigui 0 (vermell)
  if AStockTotal <= 0 then
    ColorStock := KPI_COLOR_CRIT
  else
    ColorStock := KPI_COLOR_NEUTRE;
  SetKPI(pnlKPI1, lblKPI1Val, FormatFloat('#,##0.##', AStockTotal), ColorStock);
  // 2) Disponible: verd si >= minim, ambar si > 0 pero < minim, vermell si <= 0
  if ADisponible <= 0 then
    ColorDisp := KPI_COLOR_CRIT
  else if (FStockMinimo > 0) and (ADisponible < FStockMinimo) then
    ColorDisp := KPI_COLOR_WARN
  else
    ColorDisp := KPI_COLOR_OK;
  SetKPI(pnlKPI2, lblKPI2Val, FormatFloat('#,##0.##', ADisponible), ColorDisp);
  // 3) Dias cobertura: verd >30d, ambar 7-30d, vermell <7d, gris N/A
  if DemoMode.Active then
  begin
    Cob := Default(TCoberturaErp);
    Cob.DiasCobertura := uDemoMode.DemoDiasCobertura(FCodigoArticulo);
  end
  else
  try
    Cob := FReader.ReadCoberturaArticulo(FCodigoArticulo, AlmacenesSeleccionados);
  except
    on E: Exception do
    begin
      LogError('KPI cobertura: ' + E.Message);
      Cob := Default(TCoberturaErp);
      Cob.DiasCobertura := -1;
    end;
  end;
  if Cob.DiasCobertura < 0 then
  begin
    CobTxt := 'N/A';
    ColorCob := KPI_COLOR_NEUTRE;
  end
  else if Cob.DiasCobertura < 7 then
  begin
    CobTxt := Format('%.0f d', [Cob.DiasCobertura]);
    ColorCob := KPI_COLOR_CRIT;
  end
  else if Cob.DiasCobertura < 30 then
  begin
    CobTxt := Format('%.0f d', [Cob.DiasCobertura]);
    ColorCob := KPI_COLOR_WARN;
  end
  else if Cob.DiasCobertura > 365 then
  begin
    CobTxt := '> 1 a'#241'o';
    ColorCob := KPI_COLOR_INFO;
  end
  else
  begin
    CobTxt := Format('%.0f d', [Cob.DiasCobertura]);
    ColorCob := KPI_COLOR_OK;
  end;
  SetKPI(pnlKPI3, lblKPI3Val, CobTxt, ColorCob);
  // 4) Pendiente recibir: info (blau) si > 0, neutre si 0
  if APendRecibir > 0 then
    SetKPI(pnlKPI4, lblKPI4Val, '+' + FormatFloat('#,##0.##', APendRecibir), KPI_COLOR_INFO)
  else
    SetKPI(pnlKPI4, lblKPI4Val, '0', KPI_COLOR_NEUTRE);
  // 5) Pendiente servir: info si <= disponible+pendRecibir, warn si supera
  if APendServir <= 0 then
    SetKPI(pnlKPI5, lblKPI5Val, '0', KPI_COLOR_NEUTRE)
  else if APendServir > (ADisponible + APendRecibir) then
    SetKPI(pnlKPI5, lblKPI5Val, '-' + FormatFloat('#,##0.##', APendServir), KPI_COLOR_WARN)
  else
    SetKPI(pnlKPI5, lblKPI5Val, '-' + FormatFloat('#,##0.##', APendServir), KPI_COLOR_INFO);
  // 6) Clasificacion ABC: A=vermell-info (top valor), B=ambar, C=gris-neutre
  if DemoMode.Active then
    ABC := uDemoMode.DemoCategoriaABC(FCodigoArticulo)
  else
  try
    ABC := FReader.ReadCategoriaABCArticulo(FCodigoArticulo);
  except
    on E: Exception do
    begin
      LogError('KPI ABC: ' + E.Message);
      ABC := '';
    end;
  end;
  if ABC = 'A' then
  begin
    ABCTxt := 'A';
    ColorABC := KPI_COLOR_CRIT;   // top: maxima atencio
  end
  else if ABC = 'B' then
  begin
    ABCTxt := 'B';
    ColorABC := KPI_COLOR_WARN;
  end
  else if ABC = 'C' then
  begin
    ABCTxt := 'C';
    ColorABC := KPI_COLOR_OK;     // baix impacte: tranquils
  end
  else
  begin
    ABCTxt := 'N/A';
    ColorABC := KPI_COLOR_NEUTRE;
  end;
  SetKPI(pnlKPI6, lblKPI6Val, ABCTxt, ColorABC);
end;
// ============================================================================
// TAB "Historico" - grafic mensual entradas/sortides 12-24 mesos
// ============================================================================
// Llegeix THistoricoMesErp del reader (AcumuladoStock Periodo 1..12) i el
// dibuixa amb GDI sobre un TPaintBox. Sense dependencies de chart.
// Dues series de barres costat a costat per mes: Entradas (verd) i Salidas
// (roig fosc). Eix Y autoescalat al pic, eix X amb etiqueta MM/AA per mes.
const
  HIST_COLOR_ENT  = TColor($00377D22); // verd
  HIST_COLOR_SAL  = TColor($003C3CC8); // vermell
  HIST_COLOR_AXIS = TColor($00606060);
  HIST_COLOR_GRID = TColor($00E8E8E8);
  HIST_COLOR_BG   = clWhite;
  HIST_MARGIN_L   = 70;
  HIST_MARGIN_R   = 30;
  HIST_MARGIN_T   = 30;
  HIST_MARGIN_B   = 50;
  HIST_LEGEND_H   = 18;
procedure TfrmArticleDetail.btnRecargarHistClick(Sender: TObject);
begin
  CargarHistorico;
end;
procedure TfrmArticleDetail.CargarHistorico;
var
  Almacenes: TArray<string>;
  Meses: Integer;
  TotalEnt, TotalSal: Double;
  i: Integer;
begin
  if (FReader = nil) and (not DemoMode.Active) then Exit;
  FCodigoArticulo := Trim(edArticulo.Text);
  if FCodigoArticulo = '' then Exit;
  Almacenes := AlmacenesSeleccionados;
  Meses := Trunc(seHistMeses.Value);
  if Meses <= 0 then Meses := 12;
  Screen.Cursor := crHourGlass;
  try
    try
      if DemoMode.Active then
        FHistorico := uDemoMode.DemoHistoricoMensual(FCodigoArticulo, Meses, Date)
      else
        FHistorico := FReader.ReadHistoricoMensual(FCodigoArticulo, Almacenes, Meses);
    except
      on E: Exception do
      begin
        LogError('Hist'#243'rico: ' + E.Message);
        SetLength(FHistorico, 0);
      end;
    end;
    LogInfo(Format('Hist'#243'rico: %d filas devueltas', [Length(FHistorico)]));
    TotalEnt := 0;
    TotalSal := 0;
    for i := 0 to High(FHistorico) do
    begin
      TotalEnt := TotalEnt + FHistorico[i].UnidadesEntrada;
      TotalSal := TotalSal + FHistorico[i].UnidadesSalida;
    end;
    lblHistResumen.Caption := Format(
      '%d meses · Total entradas: %s · Total salidas: %s · Neto: %s',
      [Length(FHistorico),
       FormatFloat('#,##0.##', TotalEnt),
       FormatFloat('#,##0.##', TotalSal),
       FormatFloat('+#,##0.##;-#,##0.##;0', TotalEnt - TotalSal)]);
    FHistoricoCargado := True;
    pbHistorico.Invalidate;
  finally
    Screen.Cursor := crDefault;
  end;
end;
procedure TfrmArticleDetail.pbHistoricoPaint(Sender: TObject);
var
  C: TCanvas;
  W, H: Integer;
  PlotL, PlotR, PlotT, PlotB, PlotW, PlotH: Integer;
  N, i: Integer;
  MaxVal: Double;
  StepY, NiceMax: Double;
  GroupW, BarW, X, BarHEnt, BarHSal, Y: Integer;
  NumYTicks: Integer;
  Lbl: string;
  TxtW: Integer;
  LegX, LegY: Integer;
  function NiceCeil(AVal: Double): Double;
  var
    Exp, Frac, Nice: Double;
  begin
    if AVal <= 0 then Exit(1);
    Exp := Power(10, Floor(Log10(AVal)));
    Frac := AVal / Exp;
    if Frac <= 1 then Nice := 1
    else if Frac <= 2 then Nice := 2
    else if Frac <= 5 then Nice := 5
    else Nice := 10;
    Result := Nice * Exp;
  end;
begin
  C := pbHistorico.Canvas;
  W := pbHistorico.Width;
  H := pbHistorico.Height;
  // Fons
  C.Brush.Color := HIST_COLOR_BG;
  C.FillRect(Rect(0, 0, W, H));
  N := Length(FHistorico);
  if N = 0 then
  begin
    C.Font.Name := 'Segoe UI';
    C.Font.Size := 10;
    C.Font.Color := $00808080;
    Lbl := 'Sin datos. Pulsa Recargar tras seleccionar un art'#237'culo.';
    TxtW := C.TextWidth(Lbl);
    C.TextOut((W - TxtW) div 2, H div 2 - 10, Lbl);
    Exit;
  end;
  // Plot area
  PlotL := HIST_MARGIN_L;
  PlotR := W - HIST_MARGIN_R;
  PlotT := HIST_MARGIN_T;
  PlotB := H - HIST_MARGIN_B - HIST_LEGEND_H;
  PlotW := PlotR - PlotL;
  PlotH := PlotB - PlotT;
  if (PlotW <= 50) or (PlotH <= 50) then Exit;
  // Max
  MaxVal := 0;
  for i := 0 to N - 1 do
  begin
    if FHistorico[i].UnidadesEntrada > MaxVal then MaxVal := FHistorico[i].UnidadesEntrada;
    if FHistorico[i].UnidadesSalida > MaxVal then MaxVal := FHistorico[i].UnidadesSalida;
  end;
  if MaxVal <= 0 then MaxVal := 1;
  NiceMax := NiceCeil(MaxVal);
  // Grid horitzontal i etiquetes Y
  NumYTicks := 5;
  StepY := NiceMax / NumYTicks;
  C.Font.Name := 'Segoe UI';
  C.Font.Size := 8;
  C.Font.Color := HIST_COLOR_AXIS;
  for i := 0 to NumYTicks do
  begin
    Y := PlotB - Round(i * PlotH / NumYTicks);
    C.Pen.Color := HIST_COLOR_GRID;
    C.MoveTo(PlotL, Y);
    C.LineTo(PlotR, Y);
    Lbl := FormatFloat('#,##0.#', i * StepY);
    TxtW := C.TextWidth(Lbl);
    C.TextOut(PlotL - TxtW - 6, Y - 7, Lbl);
  end;
  // Eixos
  C.Pen.Color := HIST_COLOR_AXIS;
  C.MoveTo(PlotL, PlotT);
  C.LineTo(PlotL, PlotB);
  C.LineTo(PlotR, PlotB);
  // Barres: per cada mes 2 barres (ent, sal) costat a costat dins el GroupW
  GroupW := PlotW div N;
  if GroupW < 6 then GroupW := 6;
  BarW := (GroupW - 6) div 2;  // 3px gap entre grup, gap intern petit
  if BarW < 2 then BarW := 2;
  C.Pen.Color := clBlack;
  for i := 0 to N - 1 do
  begin
    X := PlotL + i * GroupW + (GroupW - 2 * BarW - 2) div 2;
    // Entrada
    BarHEnt := Round(FHistorico[i].UnidadesEntrada / NiceMax * PlotH);
    if BarHEnt > 0 then
    begin
      C.Brush.Color := HIST_COLOR_ENT;
      C.FillRect(Rect(X, PlotB - BarHEnt, X + BarW, PlotB));
    end;
    // Salida
    BarHSal := Round(FHistorico[i].UnidadesSalida / NiceMax * PlotH);
    if BarHSal > 0 then
    begin
      C.Brush.Color := HIST_COLOR_SAL;
      C.FillRect(Rect(X + BarW + 2, PlotB - BarHSal, X + 2 * BarW + 2, PlotB));
    end;
    // Etiqueta X: MM/AA, rotada nomes si caben pocs caracters
    Lbl := Format('%.2d/%.2d', [FHistorico[i].Periodo, FHistorico[i].Ejercicio mod 100]);
    C.Font.Color := HIST_COLOR_AXIS;
    TxtW := C.TextWidth(Lbl);
    C.TextOut(X + BarW - TxtW div 2, PlotB + 6, Lbl);
  end;
  // Llegenda a sota
  LegY := H - HIST_LEGEND_H;
  LegX := PlotL;
  C.Brush.Color := HIST_COLOR_ENT;
  C.FillRect(Rect(LegX, LegY + 2, LegX + 14, LegY + 14));
  C.Brush.Color := HIST_COLOR_BG;
  C.Font.Color := HIST_COLOR_AXIS;
  C.TextOut(LegX + 20, LegY + 1, 'Entradas (compras + producciones OF)');
  LegX := LegX + 20 + C.TextWidth('Entradas (compras + producciones OF)') + 30;
  C.Brush.Color := HIST_COLOR_SAL;
  C.FillRect(Rect(LegX, LegY + 2, LegX + 14, LegY + 14));
  C.Brush.Color := HIST_COLOR_BG;
  C.TextOut(LegX + 20, LegY + 1, 'Salidas (consumos + ventas)');
end;
// ============================================================================
// TAB "OFs activas"
// ============================================================================
procedure TfrmArticleDetail.CrearColumnasOFs;
begin
  cdsOFs.FieldDefs.Clear;
  cdsOFs.FieldDefs.Add('OF', ftString, 30);
  cdsOFs.FieldDefs.Add('Estado', ftString, 20);
  cdsOFs.FieldDefs.Add('FechaCreacion', ftDate);
  cdsOFs.FieldDefs.Add('FechaInicio', ftDate);
  cdsOFs.FieldDefs.Add('FechaFinal', ftDate);
  cdsOFs.FieldDefs.Add('FechaEntrega', ftDate);
  cdsOFs.FieldDefs.Add('AFabricar', ftFloat);
  cdsOFs.FieldDefs.Add('Fabricadas', ftFloat);
  cdsOFs.FieldDefs.Add('Progreso', ftFloat);
  cdsOFs.FieldDefs.Add('Prioridad', ftString, 10);
  cdsOFs.FieldDefs.Add('Proyecto', ftString, 30);
  cdsOFs.CreateDataSet;
end;
procedure TfrmArticleDetail.btnRecargarOFsClick(Sender: TObject);
begin
  CargarOFs;
end;
procedure TfrmArticleDetail.CargarOFs;
var
  Data: TArray<TOFActivaArticuloErp>;
  i, Curso, Pendientes: Integer;
  TotalAFab: Double;
begin
  if (FReader = nil) and (not DemoMode.Active) then Exit;
  FCodigoArticulo := Trim(edArticulo.Text);
  if FCodigoArticulo = '' then Exit;
  Screen.Cursor := crHourGlass;
  try
    cdsOFs.DisableControls;
    try
      cdsOFs.EmptyDataSet;
      try
        if DemoMode.Active then
          Data := uDemoMode.DemoOFsActivas(FCodigoArticulo, Date)
        else
          Data := FReader.ReadOFsActivasArticulo(FCodigoArticulo);
      except
        on E: Exception do
        begin
          LogError('OFs activas: ' + E.Message);
          Exit;
        end;
      end;
      Curso := 0; Pendientes := 0; TotalAFab := 0;
      for i := 0 to High(Data) do
      begin
        cdsOFs.Append;
        cdsOFs.FieldByName('OF').AsString := Format('%s/%d/%d',
          [Data[i].SerieFabricacion, Data[i].EjercicioFabricacion,
           Data[i].NumeroFabricacion]);
        cdsOFs.FieldByName('Estado').AsString := Data[i].EstadoDescripcion;
        if Data[i].FechaCreacion > 0 then
          cdsOFs.FieldByName('FechaCreacion').AsDateTime := Data[i].FechaCreacion;
        if Data[i].FechaInicioPrevista > 0 then
          cdsOFs.FieldByName('FechaInicio').AsDateTime := Data[i].FechaInicioPrevista;
        if Data[i].FechaFinalPrevista > 0 then
          cdsOFs.FieldByName('FechaFinal').AsDateTime := Data[i].FechaFinalPrevista;
        if Data[i].FechaEntrega > 0 then
          cdsOFs.FieldByName('FechaEntrega').AsDateTime := Data[i].FechaEntrega;
        cdsOFs.FieldByName('AFabricar').AsFloat   := Data[i].UnidadesAFabricar;
        cdsOFs.FieldByName('Fabricadas').AsFloat  := Data[i].UnidadesFabricadas;
        cdsOFs.FieldByName('Progreso').AsFloat    := Data[i].PorcentajeProgreso;
        cdsOFs.FieldByName('Prioridad').AsString  := Data[i].Prioridad;
        cdsOFs.FieldByName('Proyecto').AsString   := Data[i].CodigoProyecto;
        cdsOFs.Post;
        TotalAFab := TotalAFab + Data[i].UnidadesAFabricar;
        if Data[i].EstadoOF = 2 then Inc(Curso)
        else Inc(Pendientes);
      end;
      cdsOFs.First;
      lblOFsResumen.Caption := Format(
        '%d OFs activas (%d en curso, %d pendientes) · %s ud. a fabricar',
        [Length(Data), Curso, Pendientes, FormatFloat('#,##0.##', TotalAFab)]);
    finally
      cdsOFs.EnableControls;
    end;
    if grdOFsView.ColumnCount = 0 then
      grdOFsView.DataController.CreateAllItems;
    grdOFsView.ApplyBestFit;
    FOFsCargadas := True;
  finally
    Screen.Cursor := crDefault;
  end;
end;
// ============================================================================
// TAB "Proveedores"
// ============================================================================
procedure TfrmArticleDetail.CrearColumnasProv;
begin
  cdsProv.FieldDefs.Clear;
  cdsProv.FieldDefs.Add('Codigo', ftString, 30);
  cdsProv.FieldDefs.Add('RazonSocial', ftString, 100);
  cdsProv.FieldDefs.Add('PrecioMedio', ftFloat);
  cdsProv.FieldDefs.Add('LeadTimeDias', ftFloat);
  cdsProv.FieldDefs.Add('UltimaCompra', ftDate);
  cdsProv.FieldDefs.Add('UnidadesTotal', ftFloat);
  cdsProv.FieldDefs.Add('Pedidos', ftInteger);
  cdsProv.CreateDataSet;
end;
procedure TfrmArticleDetail.btnRecargarProvClick(Sender: TObject);
begin
  CargarProveedores;
end;
procedure TfrmArticleDetail.CargarProveedores;
var
  Data: TArray<TProveedorArticuloErp>;
  i, Meses: Integer;
begin
  if (FReader = nil) and (not DemoMode.Active) then Exit;
  FCodigoArticulo := Trim(edArticulo.Text);
  if FCodigoArticulo = '' then Exit;
  Meses := Trunc(seProvMeses.Value);
  Screen.Cursor := crHourGlass;
  try
    cdsProv.DisableControls;
    try
      cdsProv.EmptyDataSet;
      try
        if DemoMode.Active then
          Data := uDemoMode.DemoProveedores(FCodigoArticulo, Date)
        else
          Data := FReader.ReadProveedoresArticulo(FCodigoArticulo, Meses);
      except
        on E: Exception do
        begin
          LogError('Proveedores: ' + E.Message);
          Exit;
        end;
      end;
      for i := 0 to High(Data) do
      begin
        cdsProv.Append;
        cdsProv.FieldByName('Codigo').AsString      := Data[i].CodigoProveedor;
        cdsProv.FieldByName('RazonSocial').AsString := Data[i].RazonSocialProveedor;
        cdsProv.FieldByName('PrecioMedio').AsFloat  := Data[i].PrecioMedioCompra;
        cdsProv.FieldByName('LeadTimeDias').AsFloat := Data[i].LeadTimeMedio;
        if Data[i].FechaUltimaCompra > 0 then
          cdsProv.FieldByName('UltimaCompra').AsDateTime := Data[i].FechaUltimaCompra;
        cdsProv.FieldByName('UnidadesTotal').AsFloat := Data[i].UnidadesCompradasTotal;
        cdsProv.FieldByName('Pedidos').AsInteger    := Data[i].NumeroPedidosTotal;
        cdsProv.Post;
      end;
      cdsProv.First;
      if Meses > 0 then
        lblProvResumen.Caption := Format('%d proveedores (ult. %d meses)',
          [Length(Data), Meses])
      else
        lblProvResumen.Caption := Format('%d proveedores (todo el hist'#243'rico)',
          [Length(Data)]);
    finally
      cdsProv.EnableControls;
    end;
    if grdProvView.ColumnCount = 0 then
      grdProvView.DataController.CreateAllItems;
    grdProvView.ApplyBestFit;
    FProvCargados := True;
  finally
    Screen.Cursor := crDefault;
  end;
end;
// ============================================================================
// TAB "Clientes"
// ============================================================================
procedure TfrmArticleDetail.CrearColumnasCli;
begin
  cdsCli.FieldDefs.Clear;
  cdsCli.FieldDefs.Add('Codigo', ftString, 30);
  cdsCli.FieldDefs.Add('RazonSocial', ftString, 100);
  cdsCli.FieldDefs.Add('UnidadesTotal', ftFloat);
  cdsCli.FieldDefs.Add('ImporteTotal', ftFloat);
  cdsCli.FieldDefs.Add('PrecioMedio', ftFloat);
  cdsCli.FieldDefs.Add('UltimaVenta', ftDate);
  cdsCli.FieldDefs.Add('Pedidos', ftInteger);
  cdsCli.CreateDataSet;
end;
procedure TfrmArticleDetail.btnRecargarCliClick(Sender: TObject);
begin
  CargarClientes;
end;
procedure TfrmArticleDetail.CargarClientes;
var
  Data: TArray<TClienteArticuloErp>;
  i, Meses: Integer;
  TotalUd, TotalImp: Double;
begin
  if (FReader = nil) and (not DemoMode.Active) then Exit;
  FCodigoArticulo := Trim(edArticulo.Text);
  if FCodigoArticulo = '' then Exit;
  Meses := Trunc(seCliMeses.Value);
  Screen.Cursor := crHourGlass;
  try
    cdsCli.DisableControls;
    try
      cdsCli.EmptyDataSet;
      try
        if DemoMode.Active then
          Data := uDemoMode.DemoClientes(FCodigoArticulo, Date)
        else
          Data := FReader.ReadClientesArticulo(FCodigoArticulo, Meses);
      except
        on E: Exception do
        begin
          LogError('Clientes: ' + E.Message);
          Exit;
        end;
      end;
      TotalUd := 0; TotalImp := 0;
      for i := 0 to High(Data) do
      begin
        cdsCli.Append;
        cdsCli.FieldByName('Codigo').AsString        := Data[i].CodigoCliente;
        cdsCli.FieldByName('RazonSocial').AsString   := Data[i].RazonSocialCliente;
        cdsCli.FieldByName('UnidadesTotal').AsFloat  := Data[i].UnidadesVendidasTotal;
        cdsCli.FieldByName('ImporteTotal').AsFloat   := Data[i].ImporteVendidoTotal;
        cdsCli.FieldByName('PrecioMedio').AsFloat    := Data[i].PrecioMedio;
        if Data[i].FechaUltimaVenta > 0 then
          cdsCli.FieldByName('UltimaVenta').AsDateTime := Data[i].FechaUltimaVenta;
        cdsCli.FieldByName('Pedidos').AsInteger      := Data[i].NumeroPedidosTotal;
        cdsCli.Post;
        TotalUd := TotalUd + Data[i].UnidadesVendidasTotal;
        TotalImp := TotalImp + Data[i].ImporteVendidoTotal;
      end;
      cdsCli.First;
      if Meses > 0 then
        lblCliResumen.Caption := Format(
          '%d clientes (ult. %d meses) · %s ud. · %s '#8364,
          [Length(Data), Meses, FormatFloat('#,##0.##', TotalUd),
           FormatFloat('#,##0.##', TotalImp)])
      else
        lblCliResumen.Caption := Format(
          '%d clientes (todo el hist'#243'rico) · %s ud. · %s '#8364,
          [Length(Data), FormatFloat('#,##0.##', TotalUd),
           FormatFloat('#,##0.##', TotalImp)]);
    finally
      cdsCli.EnableControls;
    end;
    if grdCliView.ColumnCount = 0 then
      grdCliView.DataController.CreateAllItems;
    grdCliView.ApplyBestFit;
    FCliCargados := True;
  finally
    Screen.Cursor := crDefault;
  end;
end;
end.
