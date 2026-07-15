unit uDashboard;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  dxGDIPlusClasses, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxButtons, dxSkinsCore, dxSkinBasic,
  dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee,
  dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
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
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, cxImage, Vcl.Menus;
type
  TfrmDashboard = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblFechaHora: TLabel;
    lblPendingSync: TLabel;
    pnlCards: TPanel;
    pnlEmpresa: TPanel;
    lblEmpresaCap: TLabel;
    lblEmpresaNombre: TLabel;
    lblEmpresaCodigo: TLabel;
    pnlProyecto: TPanel;
    lblProyectoCap: TLabel;
    lblProyectoNombre: TLabel;
    lblProyectoTipo: TLabel;
    pnlUsuario: TPanel;
    lblUsuarioCap: TLabel;
    lblUsuarioNombre: TLabel;
    lblUsuarioRol: TLabel;
    pnlAcciones: TPanel;
    TimerReloj: TTimer;
    pnlMetricas: TPanel;
    lblMetricasCap: TLabel;
    lblCapCalendarios: TLabel;
    lblValCalendarios: TLabel;
    lblCapCentros: TLabel;
    lblValCentros: TLabel;
    lblCapAreas: TLabel;
    lblValAreas: TLabel;
    lblCapDepartamentos: TLabel;
    lblValDepartamentos: TLabel;
    lblCapTurnos: TLabel;
    lblValTurnos: TLabel;
    lblCapCapacitaciones: TLabel;
    lblValCapacitaciones: TLabel;
    lblCapOperarios: TLabel;
    lblValOperarios: TLabel;
    pnlProyectoActivo: TPanel;
    lblProyectoActivoCap: TLabel;
    lblCapFechaInicio: TLabel;
    lblValFechaInicio: TLabel;
    lblCapFechaFin: TLabel;
    lblValFechaFin: TLabel;
    lblCapFechaBloqueo: TLabel;
    lblValFechaBloqueo: TLabel;
    lblCapNodos: TLabel;
    lblValNodos: TLabel;
    lblCapOFs: TLabel;
    lblValOFs: TLabel;
    lblCapPedidos: TLabel;
    lblValPedidos: TLabel;
    lblCapCentrosUsados: TLabel;
    lblValCentrosUsados: TLabel;
    lblCapOperariosAsignados: TLabel;
    lblValOperariosAsignados: TLabel;
    lblCapDuracionTotal: TLabel;
    lblValDuracionTotal: TLabel;
    lblCapDependencias: TLabel;
    lblValDependencias: TLabel;
    lblCapMarcadores: TLabel;
    lblValMarcadores: TLabel;
    lblCapOFsPendientes: TLabel;
    lblValOFsPendientes: TLabel;
    lblCapOTsPendientes: TLabel;
    lblValOTsPendientes: TLabel;
    imgSection: TcxImage;
    btnConfig: TcxButton;
    Panel1: TPanel;
    Image1: TImage;
    procedure lblPendingSyncClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerRelojTimer(Sender: TObject);
    procedure lblValCalendariosClick(Sender: TObject);
    procedure lblValCentrosClick(Sender: TObject);
    procedure lblValAreasClick(Sender: TObject);
    procedure lblValDepartamentosClick(Sender: TObject);
    procedure lblValTurnosClick(Sender: TObject);
    procedure lblValCapacitacionesClick(Sender: TObject);
    procedure lblValOperariosClick(Sender: TObject);
    procedure btnConfigClick(Sender: TObject);
  private
    FOnAbrirGantt: TNotifyEvent;
    FOnAbrirFiniteCapacity: TNotifyEvent;
    FCargado: Boolean;   // ya se hizo un Refrescar completo (cache de refresco)
    // KPI cards modernos. Sustituyen visualmente al bloque de contadores
    // planos del pnlMetricas (calendarios/centros/areas/etc.); estos siguen
    // existiendo en el DFM por compatibilidad pero quedan ocultos.
    FKPINodos: TObject;        // TKPICard (forward para no ensuciar uses)
    FKPIOFsPend: TObject;
    FKPIOFsPlan: TObject;
    FKPIOpAsignados: TObject;
    // Segunda fila de KPIs operativos.
    FKPICargaH: TObject;       // Carga total planificada (horas)
    FKPISaturacion: TObject;   // % saturacion media centros
    FKPIOFsRiesgo: TObject;    // OFs con entrega <7d sin acabar
    FKPISalud: TObject;        // Salud del plan (0..100) + incidencias (Fase 5)
    FKPIOtif: TObject;         // % de OFs entregadas a tiempo (OTIF)
    FKPISatOperarios: TObject; // % saturacion media de operarios
    FKPICuelloBotella: TObject;// saturacion del centro mas cargado
    FKPIStockOk: TObject;      // % de OFs con material suficiente (cobertura)
    FKPIRotura: TObject;       // % de OFs con rotura de stock a su fecha
    // Periodo mostrado en las sparklines. Valores especiales: RANGO_SEMANA para
    // "esta semana" (desde el lunes); >0 = numero de dias (7/30/90).
    FRangoDias: Integer;
    FBtnRSem, FBtnR7, FBtnR30, FBtnR90: TSpeedButton;  // selector de periodo
    // --- Seccion de sincronizacion con el ERP ---
    FPnlErp: TPanel;           // contenedor de la seccion ERP (runtime)
    FErpWidget: TObject;       // TErpSyncWidget (resumen de contadores)
    FBtnComprobar: TSpeedButton;
    FBtnSincronizar: TSpeedButton;
    FBtnConfigErp: TSpeedButton;
    FTimerErp: TTimer;
    FErpIntervalMin: Integer;  // minutos entre comprobaciones automaticas (0=off)
    FErpAutoStartup: Boolean;  // comprobar al arrancar la aplicacion
    FPopupErp: TPopupMenu;     // menu del boton "Auto" (carga)
    // --- Seccion de sincronizacion de DATOS MAESTROS (cambian poco) ---
    FPnlMaestros: TPanel;
    FMaestrosWidget: TObject;  // TErpSyncWidget (resumen combinado)
    FBtnCompMaestros: TSpeedButton;
    FBtnSincMaestros: TSpeedButton;
    FBtnAutoMaestros: TSpeedButton;
    FTimerMaestros: TTimer;
    FMaestrosIntervalMin: Integer;
    FMaestrosAutoStartup: Boolean;
    FPopupMaestros: TPopupMenu;
    FStartupDone: Boolean;     // comprobaciones "al arrancar" ya lanzadas

    // --- Reordenacion de SECCIONES del dashboard (drag desde el handle) ---
    // FSectionOrder: claves en orden de presentacion ('header','kpis',
    // 'proyecto','erp','acciones'). Se persiste por usuario.
    FSectionOrder: TArray<string>;
    FHandles: TStringList;     // clave de seccion -> TDragHandle (en Objects[])
    FSectionDrag: string;      // clave de la seccion que se arrastra (o '')
    FSecDragging: Boolean;
    FSecDragStartY: Integer;   // Y inicial del arrastre (pantalla)

    // --- Layout responsive + drag-reorder de las KPI cards ---
    // FCards mantiene las cards en su ORDEN actual (el que ve el usuario).
    // El layout se recalcula por ancho disponible; el orden se persiste por
    // usuario en FS_PL_UserPreference (ScreenKey='Dashboard').
    FCards: TList;             // de TKPICard, en orden de presentacion
    FDragCard: TObject;       // card que se esta arrastrando (o nil)
    FDragStart: TPoint;       // punto inicial del arrastre (coord pantalla)
    FDragging: Boolean;       // ya superado el umbral de arrastre
    FDragDX, FDragDY: Integer;// offset del cursor dentro de la card
    FRelayouting: Boolean;    // guarda contra reentrada (resize<->height)
    FScroll: TObject;         // TcxScrollBox que envuelve el contenido scrollable
    FSpacer: TPanel;          // panel invisible al fondo: marca el alto total
    FPanning: Boolean;        // panning (arrastrar el fondo para scrollear)
    FPanStartY: Integer;      // Y inicial del panning (coord pantalla)
    FPanStartPos: Integer;    // posicion del scroll al iniciar el panning
    // --- Widgets visuales del bloque "Proyecto activo" (Fase 4) ---
    FWDonutNodos: TObject;    // TDonutWidget
    FWDonutOFs: TObject;
    FWDonutPedidos: TObject;
    FWGaugeSaturacion: TObject; // TGaugeWidget
    FWTimeline: TObject;      // TTimelineWidget
    // El cronograma es una seccion propia (tarjeta blanca), hermana de las
    // demas. pnlProyectoActivo queda solo con los indicadores (donuts+gauge).
    FCardCronograma: TPanel;

    // Builder generico del menu "Auto" (lo comparten ambas secciones).
    procedure BuildAutoMenu(APopup: TPopupMenu; AHandler: TNotifyEvent);
    procedure MarcarAutoMenu(APopup: TPopupMenu; AIntervalMin: Integer;
      AStartup: Boolean);
    procedure AutoErpMenuClick(Sender: TObject);
    procedure AutoMaestrosMenuClick(Sender: TObject);
    procedure AutoErpBtnClick(Sender: TObject);
    procedure AutoMaestrosBtnClick(Sender: TObject);

    procedure BuildSectionHandles;
    function SectionControl(const AKey: string): TControl;
    procedure SectionHandleDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SectionHandleMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure SectionHandleUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

    procedure BuildProyectoWidgets;
    procedure LayoutProyectoWidgets;
    function LayoutCronogramaSection(AX, AY, AContentW: Integer): Integer;
    procedure BuildErpSection;
    procedure LayoutErpSection(ATop: Integer);
    procedure ComprobarErp(Sender: TObject);
    procedure SincronizarErp(Sender: TObject);
    procedure AutoCheckErp(Sender: TObject);
    procedure BuildMaestrosSection;
    procedure LayoutMaestrosSection(ATop: Integer);
    procedure ComprobarMaestros(Sender: TObject);
    procedure SincronizarMaestros(Sender: TObject);
    procedure BuildRangoSelector;
    procedure AbrirConfigCards;
    procedure SetCardVisible(const AKey: string; AVisible: Boolean);
    procedure BuildScrollContainer;
    procedure BuildKPICards;
    procedure SetDescAmpliadas;
    procedure RelayoutAll;
    procedure LayoutCardsGrid;
    procedure LoadCardOrder;
    procedure SaveCardOrder;
    procedure CardMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CardMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure CardMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pnlMetricasResize(Sender: TObject);
    procedure DashboardMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure ScrollPanDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ScrollPanMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ScrollPanUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HideOldMetricLabels;
    procedure ActualizarReloj;
    procedure RefrescarProyectoActivo;
    procedure SetKPI(ACard: TObject; AValue: Double;
      const ASeries: array of Double; const AUnidad: string = '');
    procedure RefrescarPendingSync;
    // Salud del plan + alertas (Fase 5). Se calcula por SQL (sin Gantt).
    procedure RefrescarSalud;
    // KPIs avanzados: OTIF, saturacion operarios, centro cuello de botella.
    procedure RefrescarKPIsAvanzados;
    // KPIs de cobertura de material: % OFs con stock suficiente / con rotura.
    // De momento solo con datos DEMO; en real muestra N/D (calculo real PENDIENTE).
    procedure RefrescarKPIsStock;
    procedure SaludCardClick(Sender: TObject);
    procedure CardDblClick(Sender: TObject);
    // Historico real de KPIs (FS_PL_DashboardMetric, V068).
    procedure UpsertMetricDia(const AColumns: array of string;
      const AValues: array of Double);
    function LoadMetricSerie(const AColumn: string;
      ADiasMax: Integer = 0): TArray<Double>;
    // Igual que LoadMetricSerie pero devuelve tambien las fechas (para etiquetar
    // el eje X del grafico del modal de detalle).
    procedure LoadMetricSerieFechas(const AColumn: string; ADiasMax: Integer;
      out AValores: TArray<Double>; out AFechas: TArray<TDateTime>);
    // Serie para una card: real (historico) o ficticia si el modo DEMO esta
    // activo. Centraliza la decision demo/real de todas las sparklines.
    function SerieKPI(const AColumn: string; const AValorActual: Double): TArray<Double>;
    procedure DemoChanged(Sender: TObject);
    procedure DashboardResize(Sender: TObject);
    procedure RangoClick(Sender: TObject);
    procedure UpdateRangoButtons;
    function RangoDiasEfectivo: Integer;
    function SubtituloRango(ARango: Integer): string;
  public
    destructor Destroy; override;
    // AForzar=False: si ya se refresco antes, no recalcula (retorno instantaneo
    // al volver de otra pantalla). AForzar=True: recalcula siempre (cambio de
    // proyecto, toggle Demo, boton de refresco manual).
    procedure Refrescar(AForzar: Boolean = False);
    // Invalida la cache: el proximo Refrescar recalculara aunque no se fuerce.
    procedure InvalidarCache;
    // True si ya se hizo un refresco completo (Main lo usa para no repetirlo al
    // volver de otra pantalla).
    function EstaCargado: Boolean;
    // Punto UNICO de entrada desde el Main al mostrar: refresca solo si la cache
    // esta invalidada. Evita el doble refresco (MostrarDashboard + FormShow).
    procedure RefrescarSiHaceFalta;
    property OnAbrirGantt: TNotifyEvent read FOnAbrirGantt write FOnAbrirGantt;
    property OnAbrirFiniteCapacity: TNotifyEvent read FOnAbrirFiniteCapacity
      write FOnAbrirFiniteCapacity;
  end;
implementation
{$R *.dfm}
uses
  Vcl.Dialogs, System.DateUtils, System.Math, System.JSON, System.StrUtils,
  System.Generics.Collections, System.Generics.Defaults,
  cxScrollBox,
  Data.Win.ADODB, Data.DB,
  uDMPlanner, uLogin, uGestionAreas, uGestionDepartamentos, uGestionCalendarios,
  uGestionCentres, uGestionTurnos, uGestionCapacitaciones, uGestionOperaris,
  uBacklog, uKPICard, uDemoMode, uDashWidgets, uGanttAlertas, uDashboardConfig,
  uKPIDetail,
  uErpReader, uErpReaderFactory, uSyncBacklogPreview, uErpSyncRepo,
  uErpSyncTypes, uBusyDialog, uSincronizarERP, uPlanLog;

const
  DASHBOARD_PREF_KEY = 'Dashboard';
  RANGO_SEMANA = -1;   // valor especial de FRangoDias: "esta semana" (desde lunes)
  // Alto de cada card y separaciones del grid responsive.
  CARD_H   = 120;
  CARD_GAP = 14;
  CARD_MARGIN = 14;
  CARD_MIN_W = 190;   // ancho minimo de una card antes de reducir columnas
  CARD_MAX_W = 300;   // ancho maximo (evita cards gigantes en pantallas anchas)
procedure TfrmDashboard.FormCreate(Sender: TObject);
begin
  FRangoDias := 14;   // periodo por defecto (se puede sobreescribir por pref)
  // Orden por defecto de las secciones (reordenable por el usuario).
  FSectionOrder := ['header', 'kpis', 'proyecto', 'cronograma', 'erp', 'maestros', 'acciones'];
  BuildScrollContainer;
  BuildRangoSelector;
  BuildErpSection;   // antes de BuildKPICards: LoadCardOrder lee el intervalo ERP
  BuildMaestrosSection;
  // BuildProyectoWidgets crea FCardCronograma (seccion 'cronograma'); debe ir
  // ANTES de BuildKPICards -> LoadCardOrder, para que SectionControl('cronograma')
  // ya resuelva al reconciliar el orden guardado (si no, la clave se descarta).
  BuildProyectoWidgets;
  BuildKPICards;
  BuildSectionHandles;
  HideOldMetricLabels;
  // Relayout tambien desde el OnResize del FORM (maximize/restore/minimize no
  // siempre disparan el OnResize del scrollbox de forma fiable).
  Self.OnResize := DashboardResize;
  DemoMode.AddListener(DemoChanged);
end;

procedure TfrmDashboard.DashboardResize(Sender: TObject);
begin
  RelayoutAll;
end;

// Crea un handle de arrastre (icono de 6 puntos) por cada seccion. El handle
// vive en el scrollbox y flota sobre la esquina sup-izq de su seccion.
procedure TfrmDashboard.BuildSectionHandles;

  procedure NewHandle(const AKey: string);
  var
    H: TDragHandle;
    Sec: TWinControl;
  begin
    // El handle vive DENTRO del panel de su seccion (asi se pinta por encima).
    Sec := SectionControl(AKey) as TWinControl;
    if Sec = nil then Exit;
    H := TDragHandle.Create(Self);
    H.Parent := Sec;
    if Sec is TPanel then H.BackColor := TPanel(Sec).Color else H.BackColor := clWhite;
    H.SetBounds(4, 4, H.Width, H.Height);
    H.BringToFront;
    H.OnMouseDown := SectionHandleDown;
    H.OnMouseMove := SectionHandleMove;
    H.OnMouseUp := SectionHandleUp;
    FHandles.AddObject(AKey, H);
  end;

begin
  FHandles := TStringList.Create;
  NewHandle('header');    // en pnlEmpresa
  NewHandle('kpis');      // en pnlMetricas
  NewHandle('proyecto');    // en pnlProyectoActivo (indicadores)
  NewHandle('cronograma');  // en FCardCronograma
  NewHandle('erp');       // en FPnlErp
  NewHandle('maestros');  // en FPnlMaestros
  NewHandle('acciones');  // en pnlAcciones
end;

function TfrmDashboard.SectionControl(const AKey: string): TControl;
begin
  if AKey = 'header' then Result := pnlEmpresa
  else if AKey = 'kpis' then Result := pnlMetricas
  else if AKey = 'proyecto' then Result := pnlProyectoActivo
  else if AKey = 'cronograma' then Result := FCardCronograma
  else if AKey = 'erp' then Result := FPnlErp
  else if AKey = 'maestros' then Result := FPnlMaestros
  else if AKey = 'acciones' then Result := pnlAcciones
  else Result := nil;
end;

// --- Drag de secciones desde su handle ---
procedure TfrmDashboard.SectionHandleDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  if Button <> mbLeft then Exit;
  // Identificar la seccion del handle pulsado.
  FSectionDrag := '';
  if FHandles <> nil then
  begin
    Idx := FHandles.IndexOfObject(Sender);
    if Idx >= 0 then FSectionDrag := FHandles[Idx];
  end;
  FSecDragging := False;
  FSecDragStartY := Mouse.CursorPos.Y;
end;

procedure TfrmDashboard.SectionHandleMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  ScrY, CurIdx, TgtIdx, I: Integer;
  Ctrl: TControl;
  P: TPoint;
begin
  if FSectionDrag = '' then Exit;
  if not (ssLeft in Shift) then Exit;

  ScrY := Mouse.CursorPos.Y;
  if (not FSecDragging) and (Abs(ScrY - FSecDragStartY) < 8) then Exit;
  FSecDragging := True;

  // Indice actual de la seccion arrastrada.
  CurIdx := -1;
  for I := 0 to High(FSectionOrder) do
    if FSectionOrder[I] = FSectionDrag then begin CurIdx := I; Break; end;
  if CurIdx < 0 then Exit;

  // Determinar sobre que seccion esta el cursor (por su centro vertical).
  P := TcxScrollBox(FScroll).ScreenToClient(Point(Mouse.CursorPos.X, ScrY));
  TgtIdx := -1;
  for I := 0 to High(FSectionOrder) do
  begin
    Ctrl := SectionControl(FSectionOrder[I]);
    if Ctrl = nil then Continue;
    if (P.Y >= Ctrl.Top) and (P.Y < Ctrl.Top + Ctrl.Height) then
    begin
      TgtIdx := I;
      Break;
    end;
  end;

  if (TgtIdx >= 0) and (TgtIdx <> CurIdx) then
  begin
    // Mover la clave en el array y re-disponer.
    var Tmp := FSectionOrder[CurIdx];
    if TgtIdx > CurIdx then
      for I := CurIdx to TgtIdx - 1 do FSectionOrder[I] := FSectionOrder[I + 1]
    else
      for I := CurIdx downto TgtIdx + 1 do FSectionOrder[I] := FSectionOrder[I - 1];
    FSectionOrder[TgtIdx] := Tmp;
    RelayoutAll;
  end;
end;

procedure TfrmDashboard.SectionHandleUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FSectionDrag = '' then Exit;
  if FSecDragging then
    SaveCardOrder;   // persiste el nuevo orden de secciones
  FSectionDrag := '';
  FSecDragging := False;
end;

procedure TfrmDashboard.btnConfigClick(Sender: TObject);
begin
  AbrirConfigCards;
end;

// Callback que el dialogo invoca cuando el usuario marca/desmarca una card:
// aplica la visibilidad EN DIRECTO, persiste y recoloca (sin botones Aceptar).
procedure TfrmDashboard.SetCardVisible(const AKey: string; AVisible: Boolean);
var
  I: Integer;
  Card: TKPICard;
begin
  if FCards = nil then Exit;
  for I := 0 to FCards.Count - 1 do
  begin
    Card := TKPICard(FCards[I]);
    if Card.Key = AKey then
    begin
      if Card.Visible <> AVisible then
      begin
        Card.Visible := AVisible;
        SaveCardOrder;   // persiste visibilidad (y orden)
        RelayoutAll;
      end;
      Break;
    end;
  end;
end;

// Abre el dialogo de configuracion de tarjetas (grid Visible|Titulo|Descripcion
// |Categoria). Aplica los cambios en directo via callback; se cierra con la X.
procedure TfrmDashboard.AbrirConfigCards;
var
  Items: TArray<TDashCardInfo>;
  I: Integer;
  Card: TKPICard;
begin
  if (FCards = nil) or (FCards.Count = 0) then Exit;

  SetLength(Items, FCards.Count);
  for I := 0 to FCards.Count - 1 do
  begin
    Card := TKPICard(FCards[I]);
    Items[I].Key := Card.Key;
    Items[I].Titulo := Card.Caption;
    Items[I].Descripcion := Card.Descripcion;
    Items[I].Categoria := Card.Categoria;
    Items[I].Visible := Card.Visible;
  end;

  TfrmDashboardConfig.Editar(Self, Items, SetCardVisible);
end;

// Franja de widgets visuales sobre el detalle textual de "Proyecto activo":
// 3 donuts de progreso (Nodos / OFs / Pedidos), gauge de saturacion y timeline
// del proyecto. Se crean en la parte superior de pnlProyectoActivo y se empuja
// hacia abajo el texto existente (que queda como detalle).
procedure TfrmDashboard.BuildProyectoWidgets;
var
  I: Integer;
  Ctrl: TControl;

  function NewDonut(const ACaption: string; ATone: TDashTone): TDonutWidget;
  begin
    Result := TDonutWidget.Create(Self);
    Result.Parent := pnlProyectoActivo;   // seccion "indicadores" (blanca)
    Result.Caption := ACaption;
    Result.Tone := ATone;
    Result.BackColor := pnlProyectoActivo.Color;
  end;

begin
  // La seccion "Proyecto activo" queda solo con los indicadores (donuts+gauge).
  // Ocultamos el titulo y todo el detalle textual (peticion del usuario).
  lblProyectoActivoCap.Visible := False;
  for I := 0 to pnlProyectoActivo.ControlCount - 1 do
  begin
    Ctrl := pnlProyectoActivo.Controls[I];
    if Ctrl is TLabel then Ctrl.Visible := False;
  end;
  pnlProyectoActivo.Color := clWhite;   // se mantiene como tarjeta blanca

  FWDonutNodos   := NewDonut('Nodos planificados', dtAzul);
  FWDonutOFs     := NewDonut(#211'rdenes de fabricaci'#243'n', dtVerde);
  FWDonutPedidos := NewDonut('Pedidos', dtAmbar);

  var Gauge := TGaugeWidget.Create(Self);
  Gauge.Parent := pnlProyectoActivo;
  Gauge.Caption := 'Saturaci'#243'n media';
  Gauge.BackColor := pnlProyectoActivo.Color;
  FWGaugeSaturacion := Gauge;

  // El cronograma es una SECCION PROPIA (tarjeta blanca), hermana de las demas
  // (parent = scrollbox), colocada en RelayoutAll justo tras "Proyecto activo".
  FCardCronograma := TPanel.Create(Self);
  FCardCronograma.Parent := TWinControl(FScroll);
  FCardCronograma.BevelOuter := bvNone;
  FCardCronograma.Color := clWhite;
  FCardCronograma.ParentBackground := False;

  var Tl := TTimelineWidget.Create(Self);
  Tl.Parent := FCardCronograma;
  Tl.Caption := 'Cronograma carga semanal';
  Tl.Tone := dtAzul;
  Tl.BackColor := FCardCronograma.Color;
  FWTimeline := Tl;

  LayoutProyectoWidgets;
end;

// Coloca los indicadores (donuts + gauge) dentro de la seccion "Proyecto
// activo" (tarjeta blanca). El cronograma es seccion aparte (LayoutCronogramaSection).
procedure TfrmDashboard.LayoutProyectoWidgets;
const
  CardPad = 8;    // padding interior de la tarjeta
  Gap = 12;       // separacion entre donuts
  RowH = 130;     // alto de un donut/gauge
var
  ContentW, ColW, X, Y: Integer;
begin
  if FWDonutNodos = nil then Exit;

  // Seccion "Proyecto activo" = solo indicadores (donuts + gauge), tarjeta blanca.
  ContentW := pnlProyectoActivo.ClientWidth - CardPad * 2;
  if ContentW < 400 then ContentW := 400;

  ColW := (ContentW - Gap * 3) div 4;
  Y := CardPad;
  X := CardPad;
  TDonutWidget(FWDonutNodos).SetBounds(X, Y, ColW, RowH);   Inc(X, ColW + Gap);
  TDonutWidget(FWDonutOFs).SetBounds(X, Y, ColW, RowH);     Inc(X, ColW + Gap);
  TDonutWidget(FWDonutPedidos).SetBounds(X, Y, ColW, RowH); Inc(X, ColW + Gap);
  TGaugeWidget(FWGaugeSaturacion).SetBounds(X, Y, ColW, RowH);

  pnlProyectoActivo.Height := RowH + CardPad * 2;
end;

// Coloca la seccion propia del cronograma (tarjeta blanca) en (AX, AY) con el
// ancho de contenido dado. Devuelve su alto para que RelayoutAll avance la Y.
function TfrmDashboard.LayoutCronogramaSection(AX, AY, AContentW: Integer): Integer;
const
  CardPad = 8; TlH = 178;
begin
  Result := TlH + CardPad * 2;
  if FCardCronograma = nil then Exit;
  FCardCronograma.SetBounds(AX, AY, AContentW, Result);
  TTimelineWidget(FWTimeline).SetBounds(CardPad, CardPad,
    AContentW - CardPad * 2, TlH);
end;

// El modo DEMO ha cambiado: repintar KPIs (usaran serie ficticia o real).
procedure TfrmDashboard.DemoChanged(Sender: TObject);
begin
  // El toggle Demo cambia todos los datos: SOLO invalidamos la cache. NO
  // refrescamos aqui porque este evento se dispara ANTES de que el Main termine
  // de conmutar el proyecto (EntrarModoDemo/LoadActivePlan): refrescar ahora
  // pintaria datos a medio conmutar. El refresco unico lo hace el Main
  // (btnTB_DemoClick) cuando ya esta todo listo, o MostrarDashboard al abrirlo.
  InvalidarCache;
end;

// Envuelve todo el contenido de pnlCards en un TcxScrollBox con scroll vertical
// (como el body de una web). La cabecera (pnlTitulo) queda fija arriba porque
// esta fuera de pnlCards. Reparentamos en runtime para no tocar el DFM grande.
procedure TfrmDashboard.BuildScrollContainer;
var
  SB: TcxScrollBox;
  I: Integer;
  Kids: array of TControl;
begin
  SB := TcxScrollBox.Create(Self);
  SB.Parent := pnlCards;
  SB.Align := alClient;
  SB.BorderStyle := cxcbsNone;
  // AutoScroll: el scrollbox calcula el rango vertical desde los hijos. Mas
  // robusto que gestionarlo a mano (evita saltos al hacer scroll + resize).
  SB.AutoScroll := True;
  SB.HorzScrollBar.Visible := False;
  SB.VertScrollBar.Visible := True;
  SB.Color := pnlCards.Color;
  // Re-layout responsive cada vez que cambia el ancho/alto del scrollbox.
  SB.OnResize := pnlMetricasResize;
  FScroll := SB;

  // La rueda del raton sobre las cards no llega al scrollbox (las cards
  // capturan el mensaje). Capturamos la rueda a nivel de form y desplazamos el
  // scrollbox nosotros.
  Self.OnMouseWheel := DashboardMouseWheel;

  // Panning: arrastrar el fondo del scrollbox (zona vacia) desplaza vertical,
  // como en movil/web. Sobre las cards manda su drag-reorder, no el panning.
  SB.OnMouseDown := ScrollPanDown;
  SB.OnMouseMove := ScrollPanMove;
  SB.OnMouseUp := ScrollPanUp;

  // El panel que contiene las KPI cards debe tener el MISMO color que el fondo
  // scrollable: asi el margen (donde se difumina la sombra de cada card) se
  // funde con el dashboard y no se ve un recuadro claro alrededor de la card.
  pnlMetricas.Color := SB.Color;

  // Mover todos los hijos actuales de pnlCards dentro del scrollbox,
  // conservando su posicion (Left/Top absolutos no cambian al reparentar).
  SetLength(Kids, pnlCards.ControlCount);
  for I := 0 to pnlCards.ControlCount - 1 do
    Kids[I] := pnlCards.Controls[I];
  for I := 0 to High(Kids) do
    if Kids[I] <> SB then
      Kids[I].Parent := SB;

  // Panel "spacer" invisible al fondo del contenido. RelayoutAll lo coloca en
  // el borde inferior real del contenido -> el scrollbox deriva SIEMPRE de el
  // el rango vertical, de forma determinista (independiente de resize/maximize/
  // reordenar secciones). Es 1px de alto y del color del fondo (no se ve).
  FSpacer := TPanel.Create(Self);
  FSpacer.Parent := SB;
  FSpacer.BevelOuter := bvNone;
  FSpacer.Height := 1;
  FSpacer.Width := 10;
  FSpacer.Color := SB.Color;
end;

destructor TfrmDashboard.Destroy;
begin
  DemoMode.RemoveListener(DemoChanged);
  // Las cards y handles son owned por el form (se liberan solos); solo liberamos
  // los contenedores de orden.
  FCards.Free;
  FHandles.Free;
  inherited;
end;

procedure TfrmDashboard.FormShow(Sender: TObject);
var
  T0: TDateTime;
begin
  PlanLog.Linea('DASH.FormShow INICIO (EstaCargado=%s)', [BoolToStr(FCargado, True)]);
  T0 := Now;
  // Refresco condicionado a la cache (idempotente): si el Main ya llamo a
  // RefrescarSiHaceFalta no recalcula nada. Cubre el arranque de la app cuando
  // el Dashboard es lo primero que se muestra.
  RefrescarSiHaceFalta;
  PlanLog.Linea('  DASH.FormShow.Refrescar: %d ms', [MilliSecondsBetween(Now, T0)]);
  T0 := Now;
  ActualizarReloj;
  TimerReloj.Enabled := True;
  // Cuando el form ya tiene sus dimensiones reales, relayout responsive (el
  // OnResize del scrollbox no siempre dispara con el ancho definitivo al abrir).
  RelayoutAll;
  PlanLog.Linea('  DASH.FormShow.RelayoutAll: %d ms', [MilliSecondsBetween(Now, T0)]);

  // "Al arrancar la aplicacion": comprobar una sola vez por sesion.
  if not FStartupDone then
  begin
    FStartupDone := True;
    if FErpAutoStartup then ComprobarErp(nil);
    if FMaestrosAutoStartup then ComprobarMaestros(nil);
  end;
end;

procedure TfrmDashboard.BuildKPICards;

  function NewCard(const AKey, ACaption, ADescripcion, ACategoria: string;
    ATone: TKPIColorTone; const AUnidad: string = '';
    const AFormat: string = ''): TKPICard;
  begin
    Result := TKPICard.Create(Self);
    Result.Parent := pnlMetricas;
    Result.Key := AKey;
    Result.Caption := ACaption;
    Result.Descripcion := ADescripcion;
    Result.Categoria := ACategoria;
    Result.ColorTone := ATone;
    // Fondo alrededor de la card = color del contenedor (para que la sombra se
    // funda y no se vea recuadro). pnlMetricas ya tiene el color del scrollbox.
    Result.BackColor := pnlMetricas.Color;
    if AUnidad <> '' then Result.Unidad := AUnidad;
    if AFormat <> '' then Result.FormatStr := AFormat;
    // Drag-reorder: escuchamos el raton de cada card desde el form.
    Result.OnMouseDown := CardMouseDown;
    Result.OnMouseMove := CardMouseMove;
    Result.OnMouseUp := CardMouseUp;
    // Doble clic en cualquier card -> modal de detalle del KPI.
    Result.OnDblClickEx := CardDblClick;
    FCards.Add(Result);
  end;

begin
  FCards := TList.Create;

  // Catalogo de KPIs, ordenado por FAMILIA (lo que un gestor mira primero):
  //   Salud (resumen) -> Terminos/plazos -> Volumen -> Recursos -> ERP.
  // El grid de configuracion lee estas mismas cards; el usuario puede reordenar
  // por drag (el orden guardado, si existe, prevalece sobre este por defecto).

  // -- Salud (resumen del plan, lo primero) --
  FKPISalud      := NewCard('Salud', 'Salud del plan',
    #205'ndice de salud del plan (0-100) seg'#250'n las incidencias detectadas.', 'Salud', kctVerde);
  TKPICard(FKPISalud).DescAmpliada :=
    'La SALUD DEL PLAN resume en un solo n'#250'mero (0-100) el estado global de la '+
    'planificaci'#243'n. Parte de 100 y descuenta puntos por cada incidencia '+
    'detectada (nodos activos antes de hoy, OF fuera de plazo, sin operarios, '+
    'sin stock, etc.), ponderando cada tipo por su gravedad.'#13#10#13#10+
    'Sirve para saber de un vistazo si el plan es fiable: 90-100 excelente, '+
    '75-89 bueno, 50-74 regular, por debajo hay que revisarlo. Haz doble clic '+
    'en el Gantt para ver el detalle de las alertas y corregirlas.';

  // -- Plazos / riesgo --
  FKPIOtif       := NewCard('Otif', 'Entregas a tiempo (OTIF)',
    'Porcentaje de OF que terminan dentro de su fecha de entrega.', 'Plazos',
    kctVerde, '%', '%.0f');
  FKPIOFsRiesgo  := NewCard('OFsRiesgo', 'OFs en riesgo (entrega <7d)',
    #211'rdenes con entrega en 7 d'#237'as y a'#250'n no finalizadas.', 'Plazos', kctRojo);

  // -- Volumen --
  FKPIOFsPlan    := NewCard('OFsPlan', 'OFs en plan',
    #211'rdenes de fabricaci'#243'n con al menos una operaci'#243'n planificada.', 'Volumen', kctVerde);
  FKPINodos      := NewCard('Nodos', 'Nodos planificados',
    'N'#250'mero total de nodos planificados en el proyecto activo.', 'Volumen', kctAzul);

  // -- Recursos --
  FKPICargaH     := NewCard('CargaH', 'Carga planificada',
    'Horas totales de trabajo planificado (suma de duraciones).', 'Recursos', kctAzul, 'h', '%.1f');
  FKPIOpAsignados:= NewCard('OpAsig', 'Operarios asignados',
    'Operarios distintos asignados a nodos del plan.', 'Recursos', kctNeutro);
  FKPISaturacion := NewCard('Saturacion', 'Saturaci'#243'n media centros',
    'Ocupaci'#243'n media estimada de los centros utilizados.', 'Recursos', kctAmbar, '%', '%.1f');
  FKPICuelloBotella := NewCard('CuelloBotella', 'Centro cuello de botella',
    'Saturaci'#243'n del centro m'#225's cargado (el que limita el plan).', 'Recursos',
    kctRojo, '%', '%.0f');
  FKPISatOperarios := NewCard('SatOperarios', 'Saturaci'#243'n operarios',
    'Ocupaci'#243'n media de los operarios respecto a su jornada.', 'Recursos',
    kctAmbar, '%', '%.0f');

  // -- Materiales (cobertura de stock) --
  FKPIStockOk    := NewCard('StockOk', 'OFs con stock suficiente',
    'Porcentaje de OF cuyo material est'#225' disponible para su fecha.', 'Materiales',
    kctVerde, '%', '%.0f');
  FKPIRotura     := NewCard('Rotura', 'OFs con rotura de stock',
    'Porcentaje de OF con alg'#250'n material en rotura a su fecha.', 'Materiales',
    kctRojo, '%', '%.0f');

  // -- ERP --
  FKPIOFsPend    := NewCard('OFsPend', 'OFs pendientes',
    #211'rdenes de fabricaci'#243'n pendientes de sincronizar desde el ERP.', 'ERP', kctAmbar);

  SetDescAmpliadas;  // descripciones largas (~100 palabras) para el modal
  LoadCardOrder;     // aplica el orden guardado por el usuario (si hay)
  RelayoutAll;       // primer layout con el ancho actual
end;

// Descripciones ampliadas ("que mide y para que sirve") de cada KPI, para el
// modal de detalle. Texto de negocio, ~100 palabras, en castellano.
procedure TfrmDashboard.SetDescAmpliadas;
begin
  TKPICard(FKPIOtif).DescAmpliada :=
    'El OTIF (On Time In Full) mide el porcentaje de '#243'rdenes de fabricaci'#243'n '+
    'que, seg'#250'n la planificaci'#243'n actual, terminar'#225'n dentro de su fecha de '+
    'entrega comprometida. Se calcula comparando, para cada OF, la fecha de fin '+
    'de su '#250'ltima operaci'#243'n con la fecha de entrega solicitada.'#13#10#13#10+
    'Es el indicador de servicio m'#225's importante de cara al cliente: un OTIF '+
    'alto significa que el plan cumple los plazos; uno bajo anticipa retrasos y '+
    'penalizaciones antes de que ocurran. Vig'#237'lalo tras cada replanificaci'#243'n: '+
    'si baja, revisa los cuellos de botella y la carga de los centros cr'#237'ticos, '+
    'porque suelen ser la causa de que las entregas se desplacen.';

  TKPICard(FKPIOFsRiesgo).DescAmpliada :=
    'Cuenta las '#243'rdenes de fabricaci'#243'n cuya fecha de entrega cae dentro de los '+
    'pr'#243'ximos 7 d'#237'as y que todav'#237'a no est'#225'n finalizadas. Son las '#243'rdenes que '+
    'necesitan atenci'#243'n inmediata: cualquier incidencia (falta de material, de '+
    'operarios o de capacidad) puede convertirlas en un incumplimiento.'#13#10#13#10+
    'Sirve como lista de vigilancia a corto plazo. A diferencia del OTIF, que da '+
    'una foto global, este indicador te dice cu'#225'ntos pedidos est'#225'n "en la zona '+
    'roja" ahora mismo. Un valor creciente indica que se est'#225'n acumulando '+
    'entregas ajustadas; conviene adelantarlas, reasignar recursos o negociar '+
    'plazos antes de que venzan.';

  TKPICard(FKPIOFsPlan).DescAmpliada :=
    'N'#250'mero de '#243'rdenes de fabricaci'#243'n que tienen al menos una operaci'#243'n '+
    'planificada (con fecha de inicio asignada) en el proyecto activo. Refleja '+
    'el volumen de trabajo que ya ha entrado en el plan frente al que a'#250'n est'#225' '+
    'pendiente de programar.'#13#10#13#10+
    'Es una medida de avance de la propia planificaci'#243'n: cuando todas las OF '+
    'necesarias est'#225'n en plan, el trabajo de programaci'#243'n est'#225' completo. Si el '+
    'n'#250'mero se queda corto respecto a la cartera de pedidos, quedan '#243'rdenes sin '+
    'programar que habr'#225' que incorporar. '#218'salo junto con "OFs pendientes" para '+
    'ver cu'#225'nto queda por meter en el plan.';

  TKPICard(FKPINodos).DescAmpliada :=
    'Cantidad total de nodos planificados en el proyecto activo. Un nodo es la '+
    'unidad m'#237'nima de trabajo programado en el Gantt: normalmente una operaci'#243'n '+
    'de una orden en un centro, con su inicio, fin y duraci'#243'n.'#13#10#13#10+
    'Da una idea del tama'#241'o y la granularidad del plan: cuantos m'#225's nodos, m'#225's '+
    'detallada y compleja es la programaci'#243'n. Es '#250'til para dimensionar el '+
    'esfuerzo de replanificaci'#243'n y para detectar de un vistazo si el plan ha '+
    'crecido o menguado respecto a d'#237'as anteriores. Combinado con la carga en '+
    'horas, ayuda a entender si el trabajo est'#225' muy fragmentado o concentrado en '+
    'pocas operaciones grandes.';

  TKPICard(FKPICargaH).DescAmpliada :=
    'Suma de las horas de trabajo de todos los nodos planificados, es decir, el '+
    'total de tiempo productivo que el plan tiene programado. Se obtiene sumando '+
    'la duraci'#243'n de cada operaci'#243'n incluida en el plan.'#13#10#13#10+
    'Es la magnitud de la carga comprometida: cu'#225'nto trabajo, en horas, hay que '+
    'sacar adelante. Comparada con la capacidad disponible de centros y '+
    'operarios, indica si el plan es realista o est'#225' sobrecargado. Su evoluci'#243'n '+
    'en el tiempo muestra si entra m'#225's trabajo del que se cierra. Es la base '+
    'para calcular la saturaci'#243'n y para negociar plazos: si la carga sube por '+
    'encima de la capacidad, algo tendr'#225' que ceder (fechas, turnos o recursos).';

  TKPICard(FKPIOpAsignados).DescAmpliada :=
    'N'#250'mero de operarios distintos que tienen al menos una asignaci'#243'n de '+
    'trabajo en el plan activo. Mide cu'#225'nta mano de obra est'#225' realmente '+
    'implicada en ejecutar la planificaci'#243'n actual.'#13#10#13#10+
    'Es un indicador de recursos humanos: pocos operarios para mucha carga '+
    'anticipa cuellos por falta de personal; muchos operarios infrautilizados '+
    'sugiere margen para asumir m'#225's trabajo. Conviene leerlo junto con la '+
    'saturaci'#243'n de operarios, que relaciona las horas asignadas con la jornada '+
    'disponible. Un cambio brusco en este n'#250'mero suele reflejar reasignaciones '+
    'o ausencias que conviene revisar para asegurar que el plan sigue siendo '+
    'ejecutable con la plantilla real.';

  TKPICard(FKPISaturacion).DescAmpliada :=
    'Ocupaci'#243'n media estimada de los centros de trabajo utilizados en el plan. '+
    'Compara las horas de trabajo asignadas a cada centro con su jornada '+
    'disponible y promedia el resultado sobre los centros en uso.'#13#10#13#10+
    'Da una visi'#243'n general de cu'#225'n lleno est'#225' el plan: valores bajos indican '+
    'holgura; cercanos al 100%, un plan al l'#237'mite. Ojo: al ser una media, puede '+
    'ocultar desequilibrios (un centro saturado y varios casi vac'#237'os), por eso '+
    'conviene mirarla junto al "Centro cuello de botella", que se'#241'ala el m'#225's '+
    'cargado. Es clave para decidir si se puede aceptar m'#225's trabajo o si hay que '+
    'redistribuir carga entre centros.';

  TKPICard(FKPICuelloBotella).DescAmpliada :=
    'Muestra la saturaci'#243'n del centro de trabajo M'#193'S cargado del plan, es decir, '+
    'el que limita el ritmo de toda la f'#225'brica. A diferencia de la saturaci'#243'n '+
    'media, no diluye el dato: se'#241'ala d'#243'nde est'#225' realmente el problema.'#13#10#13#10+
    'Seg'#250'n la teor'#237'a de las limitaciones, el rendimiento del conjunto lo marca '+
    'su cuello de botella: de nada sirve tener capacidad libre en otros centros '+
    'si '#233'ste va saturado. Si su valor se acerca al 100%, es el primer sitio '+
    'donde actuar (a'#241'adir turnos, desviar carga o priorizar). Vigilarlo evita '+
    'prometer plazos que el centro cr'#237'tico no podr'#225' cumplir por mucho que el '+
    'resto de la planta tenga hueco.';

  TKPICard(FKPISatOperarios).DescAmpliada :=
    'Ocupaci'#243'n media de los operarios: relaciona las horas de trabajo que tienen '+
    'asignadas con las horas de jornada disponibles en el horizonte del plan. Es '+
    'el equivalente en personas a la saturaci'#243'n de centros.'#13#10#13#10+
    'Permite saber si la plantilla est'#225' bien dimensionada para la carga: valores '+
    'altos avisan de sobrecarga y riesgo de horas extra o retrasos; valores '+
    'bajos, de capacidad ociosa. Junto con "Operarios asignados" ayuda a '+
    'equilibrar el reparto de trabajo. Si sube por encima de lo razonable, hay '+
    'que reforzar personal, redistribuir tareas o revisar los tiempos, porque un '+
    'plan que exige m'#225's horas de las que la gente tiene disponibles no se '+
    'cumplir'#225' en la pr'#225'ctica.';

  TKPICard(FKPIOFsPend).DescAmpliada :=
    'N'#250'mero de '#243'rdenes de fabricaci'#243'n que existen en el ERP pero que a'#250'n no se '+
    'han sincronizado con el planificador, es decir, trabajo real que todav'#237'a no '+
    'est'#225' reflejado en el plan.'#13#10#13#10+
    'Es un indicador de al d'#237'a que est'#225' la planificaci'#243'n respecto a la realidad '+
    'del ERP. Un valor distinto de cero significa que hay pedidos nuevos o '+
    'cambios que faltan por incorporar: hasta hacerlo, el plan est'#225' incompleto y '+
    'las dem'#225's m'#233'tricas pueden quedarse cortas. Conviene sincronizar con '+
    'frecuencia para que el Gantt refleje siempre la carga real; si este n'#250'mero '+
    'crece, es se'#241'al de que el plan se est'#225' quedando desfasado frente a los '+
    'pedidos que entran.';

  TKPICard(FKPIStockOk).DescAmpliada :=
    'Porcentaje de '#243'rdenes de fabricaci'#243'n del plan cuyo material necesario '+
    '(componentes del escandallo) est'#225' DISPONIBLE a la fecha en que la orden '+
    'debe empezar, seg'#250'n la proyecci'#243'n de stock.'#13#10#13#10+
    'Es el indicador de aprovisionamiento clave: un valor alto significa que el '+
    'plan es EJECUTABLE, que no se parar'#225' una l'#237'nea por falta de un ingrediente '+
    'o un envase. Compras y log'#237'stica lo vigilan junto con "OFs con rotura": si '+
    'baja, hay material por reponer antes de que la producci'#243'n lo necesite.';

  TKPICard(FKPIRotura).DescAmpliada :=
    'Porcentaje de '#243'rdenes de fabricaci'#243'n con AL MENOS UN material en rotura '+
    '(stock proyectado por debajo de lo necesario) en la fecha en que la orden '+
    'lo consume. Es el complementario de "OFs con stock suficiente".'#13#10#13#10+
    'Se'#241'ala el riesgo de aprovisionamiento del plan: cada punto son '#243'rdenes '+
    'que, si no se repone el material a tiempo, se retrasar'#225'n por falta de '+
    'existencias, no por capacidad. Es la lista de trabajo de compras: prioriza '+
    'las reposiciones de los materiales que bloquean m'#225's '#243'rdenes y con fecha '+
    'm'#225's cercana.';
end;

procedure TfrmDashboard.pnlMetricasResize(Sender: TObject);
begin
  RelayoutAll;
end;

// Selector de periodo (Semana / 7d / 30d / 90d) en la cabecera: cambia el rango
// de TODAS las sparklines a la vez. Se persiste por usuario.
procedure TfrmDashboard.BuildRangoSelector;

  function NewRango(const ACap: string; ATag, ALeft, AW: Integer): TSpeedButton;
  begin
    Result := TSpeedButton.Create(Self);
    Result.Parent := pnlTitulo;
    Result.GroupIndex := 5;
    Result.AllowAllUp := False;
    Result.Caption := ACap;
    Result.Tag := ATag;
    Result.Flat := True;
    Result.Anchors := [akTop, akRight];
    Result.SetBounds(ALeft, 44, AW, 20);
    Result.Font.Color := clWhite;
    Result.OnClick := RangoClick;
  end;

begin
  // A la izquierda del boton de configuracion (btnConfig, Left=867).
  FBtnRSem := NewRango('Semana', RANGO_SEMANA, 675, 56);
  FBtnR7   := NewRango('7d',  7,  735, 36);
  FBtnR30  := NewRango('30d', 30, 773, 36);
  FBtnR90  := NewRango('90d', 90, 811, 36);

  UpdateRangoButtons;
end;

// Refleja FRangoDias en el estado Down de los botones del selector.
procedure TfrmDashboard.UpdateRangoButtons;
begin
  if FBtnR7 = nil then Exit;
  FBtnRSem.Down := FRangoDias = RANGO_SEMANA;
  FBtnR7.Down   := FRangoDias = 7;
  FBtnR30.Down  := FRangoDias = 30;
  FBtnR90.Down  := FRangoDias = 90;
  // Si el valor guardado no coincide con ninguno (p.ej. 14 antiguo), por defecto 7d.
  if not (FBtnRSem.Down or FBtnR7.Down or FBtnR30.Down or FBtnR90.Down) then
  begin
    FRangoDias := 7;
    FBtnR7.Down := True;
  end;
end;

// Traduce FRangoDias a numero de dias efectivo para la consulta TOP N. Para
// "esta semana" = dias transcurridos desde el lunes (1..7).
function TfrmDashboard.RangoDiasEfectivo: Integer;
var
  DiaSemana: Integer;
begin
  if FRangoDias = RANGO_SEMANA then
  begin
    DiaSemana := DayOfTheWeek(Date);   // lunes=1 .. domingo=7 (ISO)
    Result := DiaSemana;               // desde el lunes hasta hoy, inclusive
  end
  else
    Result := FRangoDias;
end;

procedure TfrmDashboard.RangoClick(Sender: TObject);
begin
  if not (Sender is TSpeedButton) then Exit;
  FRangoDias := TSpeedButton(Sender).Tag;
  SaveCardOrder;   // persiste tambien el rango (ver Save/Load)
  Refrescar;       // recalcula sparklines con el nuevo periodo
end;

function TfrmDashboard.SubtituloRango(ARango: Integer): string;
begin
  if ARango = RANGO_SEMANA then
    Result := 'Evoluci'#243'n - esta semana'
  else
    Result := Format('Evoluci'#243'n - '#250'ltimos %d d'#237'as', [ARango]);
end;

// ============================================================================
// Seccion de sincronizacion con el ERP: resumen de contadores + botones
// Comprobar / Sincronizar + comprobacion automatica configurable.
// ============================================================================

procedure TfrmDashboard.BuildErpSection;
var
  W: TErpSyncWidget;
  lblCap: TLabel;
begin
  FErpIntervalMin := 0;   // por defecto sin auto-comprobacion (se carga de pref)

  FPnlErp := TPanel.Create(Self);
  FPnlErp.Parent := TWinControl(FScroll);
  FPnlErp.BevelOuter := bvNone;
  FPnlErp.ParentBackground := False;
  FPnlErp.Color := clWhite;

  lblCap := TLabel.Create(Self);
  lblCap.Parent := FPnlErp;
  lblCap.SetBounds(16, 12, 300, 14);
  lblCap.Caption := 'SINCRONIZACI'#211'N CARGA TRABAJO DEL ERP';
  lblCap.Font.Name := 'Segoe UI Semibold';
  lblCap.Font.Height := -11;
  lblCap.Font.Color := clGray;

  W := TErpSyncWidget.Create(Self);
  W.Parent := FPnlErp;
  W.BackColor := clWhite;
  W.SetEstado('Nunca comprobado. Pulsa "Comprobar" para consultar el ERP.');
  FErpWidget := W;

  // Botones estilo "segmented" plano, iguales a los del modal de detalle
  // (Linea/Area/Barras): TSpeedButton flat.
  FBtnComprobar := TSpeedButton.Create(Self);
  FBtnComprobar.Parent := FPnlErp;
  FBtnComprobar.Caption := 'Comprobar';
  FBtnComprobar.Flat := True;
  FBtnComprobar.OnClick := ComprobarErp;

  FBtnSincronizar := TSpeedButton.Create(Self);
  FBtnSincronizar.Parent := FPnlErp;
  FBtnSincronizar.Caption := 'Sincronizar';
  FBtnSincronizar.Flat := True;
  FBtnSincronizar.OnClick := SincronizarErp;

  FBtnConfigErp := TSpeedButton.Create(Self);
  FBtnConfigErp.Parent := FPnlErp;
  FBtnConfigErp.Caption := 'Auto';
  FBtnConfigErp.Flat := True;
  FBtnConfigErp.Hint := 'Configurar comprobaci'#243'n autom'#225'tica';
  FBtnConfigErp.ShowHint := True;
  FBtnConfigErp.OnClick := AutoErpBtnClick;

  // Menu desplegable "Auto" con los intervalos.
  FPopupErp := TPopupMenu.Create(Self);
  BuildAutoMenu(FPopupErp, AutoErpMenuClick);

  // Timer de comprobacion automatica (ligera).
  FTimerErp := TTimer.Create(Self);
  FTimerErp.Enabled := False;
  FTimerErp.OnTimer := AutoCheckErp;
end;

// Posiciona la seccion ERP (widget de contadores + botones) a lo ancho, en la
// coordenada ATop dada por RelayoutAll. Devuelve nada; el alto es fijo.
procedure TfrmDashboard.LayoutErpSection(ATop: Integer);
const
  M = 24; H = 118;
var
  ContentW, BtnY: Integer;
begin
  if FPnlErp = nil then Exit;
  ContentW := TcxScrollBox(FScroll).ClientWidth - M * 2;
  if ContentW < 300 then ContentW := 300;
  FPnlErp.SetBounds(M, ATop, ContentW, H);

  // Botones "segmented" en una fila arriba-derecha (como Linea/Area/Barras).
  BtnY := 8;
  FBtnComprobar.SetBounds(ContentW - 260, BtnY, 90, 24);
  FBtnSincronizar.SetBounds(ContentW - 166, BtnY, 90, 24);
  FBtnConfigErp.SetBounds(ContentW - 72, BtnY, 56, 24);

  // Widget de contadores ocupa todo el ancho, bajo los botones.
  TErpSyncWidget(FErpWidget).SetBounds(12, 34, ContentW - 24, H - 40);
end;

// ============================================================================
// Seccion de sincronizacion de DATOS MAESTROS (Centros, Maquinas, Operarios,
// Almacenes, Familias, Calendarios, Modelos horarios). Cambian poco, por eso va
// separada de la carga de trabajo (OF). Reutiliza el form TfrmSincronizarERP.
// ============================================================================
procedure TfrmDashboard.BuildMaestrosSection;
var
  lblCap: TLabel;
  W: TErpSyncWidget;
begin
  FPnlMaestros := TPanel.Create(Self);
  FPnlMaestros.Parent := TWinControl(FScroll);
  FPnlMaestros.BevelOuter := bvNone;
  FPnlMaestros.ParentBackground := False;
  FPnlMaestros.Color := clWhite;

  lblCap := TLabel.Create(Self);
  lblCap.Parent := FPnlMaestros;
  lblCap.SetBounds(16, 12, 400, 14);
  lblCap.Caption := 'SINCRONIZACI'#211'N MAESTROS DEL ERP';
  lblCap.Font.Name := 'Segoe UI Semibold';
  lblCap.Font.Height := -11;
  lblCap.Font.Color := clGray;

  W := TErpSyncWidget.Create(Self);
  W.Parent := FPnlMaestros;
  W.BackColor := clWhite;
  W.SetEstado('Centros, m'#225'quinas, operarios, almacenes, familias y calendarios. '+
    'Pulsa "Comprobar" para ver los cambios en el ERP.');
  FMaestrosWidget := W;

  FBtnCompMaestros := TSpeedButton.Create(Self);
  FBtnCompMaestros.Parent := FPnlMaestros;
  FBtnCompMaestros.Caption := 'Comprobar';
  FBtnCompMaestros.Flat := True;
  FBtnCompMaestros.OnClick := ComprobarMaestros;

  FBtnSincMaestros := TSpeedButton.Create(Self);
  FBtnSincMaestros.Parent := FPnlMaestros;
  FBtnSincMaestros.Caption := 'Sincronizar';
  FBtnSincMaestros.Flat := True;
  FBtnSincMaestros.OnClick := SincronizarMaestros;

  FBtnAutoMaestros := TSpeedButton.Create(Self);
  FBtnAutoMaestros.Parent := FPnlMaestros;
  FBtnAutoMaestros.Caption := 'Auto';
  FBtnAutoMaestros.Flat := True;
  FBtnAutoMaestros.Hint := 'Comprobaci'#243'n autom'#225'tica de maestros';
  FBtnAutoMaestros.ShowHint := True;
  FBtnAutoMaestros.OnClick := AutoMaestrosBtnClick;

  FPopupMaestros := TPopupMenu.Create(Self);
  BuildAutoMenu(FPopupMaestros, AutoMaestrosMenuClick);

  // Timer propio (independiente del de carga). En cada disparo comprueba.
  FTimerMaestros := TTimer.Create(Self);
  FTimerMaestros.Enabled := False;
  FTimerMaestros.OnTimer := ComprobarMaestros;
end;

procedure TfrmDashboard.LayoutMaestrosSection(ATop: Integer);
const
  M = 24; H = 118;
var
  ContentW: Integer;
begin
  if FPnlMaestros = nil then Exit;
  ContentW := TcxScrollBox(FScroll).ClientWidth - M * 2;
  if ContentW < 300 then ContentW := 300;
  FPnlMaestros.SetBounds(M, ATop, ContentW, H);
  // Botones en una fila arriba-derecha (igual que la seccion de carga).
  FBtnCompMaestros.SetBounds(ContentW - 260, 8, 90, 24);
  FBtnSincMaestros.SetBounds(ContentW - 166, 8, 90, 24);
  FBtnAutoMaestros.SetBounds(ContentW - 72, 8, 56, 24);
  TErpSyncWidget(FMaestrosWidget).SetBounds(12, 34, ContentW - 24, H - 40);
end;

// Comprobacion de MAESTROS: llama a los mismos Preview* que el boton
// "Previsualizar" del form de sincronizacion, agrega el resumen combinado de
// todas las entidades y lo muestra en el widget.
procedure TfrmDashboard.ComprobarMaestros(Sender: TObject);
var
  Reader: IErpReader;
  Total, Nuevos, Actu, SinC, Obs: Integer;
  // Estados agregados de todas las entidades (rellenados en el hilo, contados
  // despues en el hilo principal para no llamar codigo de UI desde el worker).
  Estados: TArray<TSyncStatus>;
  I: Integer;
begin
  Reader := GetActiveErpReader;
  if Reader = nil then
  begin
    MessageDlg('No hay ERP configurado.', mtInformation, [mbOK], 0);
    Exit;
  end;

  Total := 0; Nuevos := 0; Actu := 0; SinC := 0; Obs := 0;
  Estados := nil;
  TErpSyncWidget(FMaestrosWidget).SetEstado('Comprobando datos maestros...');
  try
    uBusyDialog.RunBusy(Self, 'Consultando datos maestros en el ERP...',
      procedure
      var
        R: TErpSyncRepo;
        J: Integer;
        FDesde, FHasta: TDate;
        Cen: TArray<TSyncRowCentro>;
        Maq: TArray<TSyncRowMaquina>;
        Ope: TArray<TSyncRowOperario>;
        CenMaq: TArray<TSyncRowCentroMaquina>;
        Mods: TArray<TSyncRowShiftModel>;
        Alm: TArray<TSyncRowAlmacen>;
        Fam: TArray<TSyncRowFamilia>;
        Cal: TArray<TSyncRowCalendario>;

        procedure Push(AStatus: TSyncStatus);
        begin
          SetLength(Estados, Length(Estados) + 1);
          Estados[High(Estados)] := AStatus;
        end;

      begin
        Reader.EnsureConnected;
        R := TErpSyncRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa,
          Reader.GetSistemaNombre);
        try
          Cen := R.PreviewCentros(Reader);
          Maq := R.PreviewMaquinas(Reader);
          Ope := R.PreviewOperarios(Reader);
          CenMaq := R.PreviewCentroMaquina(Reader);
          Mods := R.PreviewShiftModels(Reader);
          Alm := R.PreviewAlmacenes(Reader);
          Fam := R.PreviewFamilias(Reader);
          FDesde := EncodeDate(YearOf(Date), 1, 1);
          FHasta := EncodeDate(YearOf(Date), 12, 31);
          Cal := R.PreviewCalendarios(Reader, FDesde, FHasta);
          for J := 0 to High(Cen) do Push(Cen[J].Status);
          for J := 0 to High(Maq) do Push(Maq[J].Status);
          for J := 0 to High(Ope) do Push(Ope[J].Status);
          for J := 0 to High(CenMaq) do Push(CenMaq[J].Status);
          for J := 0 to High(Mods) do Push(Mods[J].Status);
          for J := 0 to High(Alm) do Push(Alm[J].Status);
          for J := 0 to High(Fam) do Push(Fam[J].Status);
          for J := 0 to High(Cal) do Push(Cal[J].Status);
        finally
          R.Free;
        end;
      end);
  except
    on E: Exception do
    begin
      TErpSyncWidget(FMaestrosWidget).SetEstado('Error al comprobar: ' +
        Copy(E.Message, 1, 80));
      Exit;
    end;
  end;

  // Contar en el hilo principal.
  for I := 0 to High(Estados) do
  begin
    Inc(Total);
    case Estados[I] of
      ssNuevo:        Inc(Nuevos);
      ssActualizado:  Inc(Actu);
      ssSinCambios:   Inc(SinC);
      ssEliminadoErp: Inc(Obs);
    end;
  end;

  TErpSyncWidget(FMaestrosWidget).SetResumen(Total, Nuevos, Actu, SinC, Obs,
    'Comprobado ' + FormatDateTime('dd/mm/yyyy hh:nn', Now));
  FBtnSincMaestros.Enabled := (Nuevos > 0) or (Actu > 0) or (Obs > 0);
end;

// Reutiliza el mismo form de sincronizacion de maestros que el menu principal.
procedure TfrmDashboard.SincronizarMaestros(Sender: TObject);
var
  F: TfrmSincronizarERP;
begin
  F := TfrmSincronizarERP.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
  ComprobarMaestros(nil);   // refrescar contadores tras sincronizar
  Refrescar;                // por si cambiaron centros/operarios en KPIs
end;

// Comprobacion COMPLETA (bajo demanda): conecta al ERP, calcula el resumen
// (Total/Nuevos/Actualizados/SinCambios/Obsoletos) y lo muestra en el widget.
procedure TfrmDashboard.ComprobarErp(Sender: TObject);
var
  Reader: IErpReader;
  Rows: TArray<TSyncRowRawItem>;
  Total, Nuevos, Actu, SinC, Obs: Integer;
  I: Integer;
begin
  Reader := GetActiveErpReader;
  if Reader = nil then
  begin
    MessageDlg('No hay ERP configurado.', mtInformation, [mbOK], 0);
    Exit;
  end;

  TErpSyncWidget(FErpWidget).SetEstado('Comprobando con el ERP...');
  Rows := nil;
  try
    // La lectura del ERP puede tardar: dialogo Busy en hilo con ADO propio.
    uBusyDialog.RunBusy(Self, 'Consultando '#243'rdenes en el ERP...',
      procedure
      var
        R: TErpSyncRepo;
      begin
        Reader.EnsureConnected;
        R := TErpSyncRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa,
          Reader.GetSistemaNombre);
        try
          Rows := R.PreviewBacklogOF(Reader, 0);   // 0 = todos los ejercicios vivos
        finally
          R.Free;
        end;
      end);
  except
    on E: Exception do
    begin
      TErpSyncWidget(FErpWidget).SetEstado('Error al comprobar: ' +
        Copy(E.Message, 1, 80));
      Exit;
    end;
  end;

  // Contar por estado.
  Total := Length(Rows); Nuevos := 0; Actu := 0; SinC := 0; Obs := 0;
  for I := 0 to High(Rows) do
    case Rows[I].Status of
      ssNuevo:        Inc(Nuevos);
      ssActualizado:  Inc(Actu);
      ssSinCambios:   Inc(SinC);
      ssEliminadoErp: Inc(Obs);
    end;

  TErpSyncWidget(FErpWidget).SetResumen(Total, Nuevos, Actu, SinC, Obs,
    'Comprobado ' + FormatDateTime('dd/mm/yyyy hh:nn', Now));

  // Resaltar el boton Sincronizar si hay novedades.
  FBtnSincronizar.Enabled := (Nuevos > 0) or (Actu > 0) or (Obs > 0);
end;

// Sincronizacion REAL: reutiliza el mismo dialogo de preview/aplicacion que el
// Backlog (no duplica logica). Tras aplicar, vuelve a comprobar el resumen.
procedure TfrmDashboard.SincronizarErp(Sender: TObject);
var
  Reader: IErpReader;
  Ejercicio: SmallInt;
begin
  Reader := GetActiveErpReader;
  if Reader = nil then
  begin
    MessageDlg('No hay ERP configurado.', mtInformation, [mbOK], 0);
    Exit;
  end;
  try
    uBusyDialog.RunBusy(Self, 'Conectando con el ERP...',
      procedure begin Reader.EnsureConnected; end);
  except
    on E: Exception do
    begin
      MessageDlg('No se pudo conectar al ERP:'#13#10 + E.Message,
        mtWarning, [mbOK], 0);
      Exit;
    end;
  end;

  Ejercicio := 0;
  if TfrmSyncBacklogPreview.Execute(Self, DMPlanner.ADOConnection,
       DMPlanner.CodigoEmpresa, Reader.GetSistemaNombre, Reader, Ejercicio) then
  begin
    ComprobarErp(nil);   // refrescar contadores tras sincronizar
    Refrescar;           // y los KPIs (pueden haber entrado OF nuevas)
  end;
end;

// Comprobacion AUTOMATICA ligera (timer): consulta la TVF local de pendientes
// (sin abrir conexion ERP). Si hay novedades, lo refleja en el estado del
// widget y resalta el boton Comprobar.
procedure TfrmDashboard.AutoCheckErp(Sender: TObject);
var
  Q: TADOQuery;
  NumOFs, NumOTs: Integer;
begin
  if not DMPlanner.IsConnected then Exit;
  NumOFs := 0; NumOTs := 0;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    try
      Q.SQL.Text :=
        'SELECT NumOFsNuevas, NumOTsNuevas FROM dbo.FS_PL_fn_PendingErpOFs(:Emp)';
      Q.Parameters.ParamByName('Emp').Value := DMPlanner.CodigoEmpresa;
      Q.Open;
      if not Q.Eof then
      begin
        NumOFs := Q.FieldByName('NumOFsNuevas').AsInteger;
        NumOTs := Q.FieldByName('NumOTsNuevas').AsInteger;
      end;
    except
      Exit;   // TVF ausente -> no molestar
    end;
  finally
    Q.Free;
  end;

  if (NumOFs > 0) or (NumOTs > 0) then
  begin
    TErpSyncWidget(FErpWidget).SetEstado(Format(
      'Hay %d OF y %d OT nuevas en el ERP. Pulsa "Comprobar".', [NumOFs, NumOTs]));
    // Resaltar el boton Comprobar (TSpeedButton: negrita + color de fuente).
    FBtnComprobar.Font.Style := [fsBold];
    FBtnComprobar.Font.Color := $000060E0;   // naranja
  end
  else
  begin
    FBtnComprobar.Font.Style := [];
    FBtnComprobar.Font.Color := clWindowText;
  end;
end;

// ---- Menu "Auto" (comun a las secciones ERP carga y ERP maestros) ----
// Cada item de intervalo lleva en Tag los minutos (0=Desactivado). El item
// "Al arrancar la aplicacion" es un checkbox con Tag=-1.
procedure TfrmDashboard.BuildAutoMenu(APopup: TPopupMenu; AHandler: TNotifyEvent);

  procedure AddItem(const ACap: string; ATag: Integer; ASep: Boolean = False);
  var
    MI: TMenuItem;
  begin
    MI := TMenuItem.Create(APopup);
    MI.Caption := ACap;
    MI.Tag := ATag;
    MI.RadioItem := ATag >= 0;   // los intervalos son radio; el startup no
    MI.OnClick := AHandler;
    APopup.Items.Add(MI);
    if ASep then
    begin
      MI := TMenuItem.Create(APopup);
      MI.Caption := '-';
      APopup.Items.Add(MI);
    end;
  end;

begin
  AddItem('Al arrancar la aplicaci'#243'n', -1, True);   // checkbox
  AddItem('Desactivado', 0);
  AddItem('Cada 5 minutos', 5);
  AddItem('Cada 15 minutos', 15);
  AddItem('Cada 30 minutos', 30);
  AddItem('Cada 1 hora', 60);
  AddItem('Cada 2 horas', 120);
  AddItem('Cada 3 horas', 180);
  AddItem('Cada 4 horas', 240);
end;

// Refleja el estado (intervalo + startup) en las marcas del menu.
procedure TfrmDashboard.MarcarAutoMenu(APopup: TPopupMenu; AIntervalMin: Integer;
  AStartup: Boolean);
var
  I: Integer;
  MI: TMenuItem;
begin
  for I := 0 to APopup.Items.Count - 1 do
  begin
    MI := APopup.Items[I];
    if MI.Caption = '-' then Continue;
    if MI.Tag = -1 then
      MI.Checked := AStartup                    // startup: check independiente
    else
      MI.Checked := (MI.Tag = AIntervalMin);    // intervalo: radio
  end;
end;

// Aplica un item de intervalo/startup a un estado (timer + flags) y persiste.
procedure TfrmDashboard.AutoErpMenuClick(Sender: TObject);
var
  Tg: Integer;
begin
  Tg := TMenuItem(Sender).Tag;
  if Tg = -1 then
    FErpAutoStartup := not FErpAutoStartup
  else
  begin
    FErpIntervalMin := Tg;
    FTimerErp.Enabled := Tg > 0;
    if Tg > 0 then FTimerErp.Interval := Tg * 60 * 1000;
  end;
  MarcarAutoMenu(FPopupErp, FErpIntervalMin, FErpAutoStartup);
  SaveCardOrder;
end;

procedure TfrmDashboard.AutoMaestrosMenuClick(Sender: TObject);
var
  Tg: Integer;
begin
  Tg := TMenuItem(Sender).Tag;
  if Tg = -1 then
    FMaestrosAutoStartup := not FMaestrosAutoStartup
  else
  begin
    FMaestrosIntervalMin := Tg;
    FTimerMaestros.Enabled := Tg > 0;
    if Tg > 0 then FTimerMaestros.Interval := Tg * 60 * 1000;
  end;
  MarcarAutoMenu(FPopupMaestros, FMaestrosIntervalMin, FMaestrosAutoStartup);
  SaveCardOrder;
end;

// Muestra el menu "Auto" bajo el boton correspondiente.
procedure TfrmDashboard.AutoErpBtnClick(Sender: TObject);
var
  P: TPoint;
begin
  MarcarAutoMenu(FPopupErp, FErpIntervalMin, FErpAutoStartup);
  P := FBtnConfigErp.ClientToScreen(Point(0, FBtnConfigErp.Height));
  FPopupErp.Popup(P.X, P.Y);
end;

procedure TfrmDashboard.AutoMaestrosBtnClick(Sender: TObject);
var
  P: TPoint;
begin
  MarcarAutoMenu(FPopupMaestros, FMaestrosIntervalMin, FMaestrosAutoStartup);
  P := FBtnAutoMaestros.ClientToScreen(Point(0, FBtnAutoMaestros.Height));
  FPopupMaestros.Popup(P.X, P.Y);
end;

// Rueda del raton: desplaza el scrollbox verticalmente. Se engancha al form
// para funcionar tambien cuando el cursor esta sobre una card (que captura el
// WM_MOUSEWHEEL y no lo reenvia al scrollbox).
procedure TfrmDashboard.DashboardMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
const
  STEP = 48;   // pixeles por muesca de rueda
var
  SB: TcxScrollBox;
begin
  if FScroll = nil then Exit;
  SB := TcxScrollBox(FScroll);
  // WheelDelta > 0 = rueda hacia arriba (scroll hacia arriba).
  SB.VertScrollBar.Position := SB.VertScrollBar.Position -
    (WheelDelta div 120) * STEP;
  Handled := True;
end;

// ---- Panning: arrastrar el fondo vacio del scrollbox para scrollear ----
procedure TfrmDashboard.ScrollPanDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FPanning := True;
  FPanStartY := Mouse.CursorPos.Y;                       // Y en pantalla
  FPanStartPos := TcxScrollBox(FScroll).VertScrollBar.Position;
end;

procedure TfrmDashboard.ScrollPanMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  DY: Integer;
begin
  if not FPanning then Exit;
  if not (ssLeft in Shift) then Exit;
  // Arrastrar hacia abajo muestra contenido superior (position disminuye).
  DY := Mouse.CursorPos.Y - FPanStartY;
  TcxScrollBox(FScroll).VertScrollBar.Position := FPanStartPos - DY;
end;

procedure TfrmDashboard.ScrollPanUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FPanning := False;
end;

// Layout maestro: recoloca TODO el contenido scrollable a lo ancho del
// scrollbox (responsive) y apila verticalmente las secciones. Fija anchos
// explicitos para que el scrollbox calcule bien el rango vertical y no aparezca
// barra horizontal. Se dispara desde el OnResize del scrollbox.
procedure TfrmDashboard.RelayoutAll;
const
  M = 24;          // margen lateral del contenido (como el DFM original)
  HeaderH = 100;   // altura de la fila de cabecera (Empresa/Proyecto/Usuario)
var
  SB: TcxScrollBox;
  ContentW, X, Y, HdrW, Gap3, SecIdx: Integer;
  Key: string;
begin
  if FScroll = nil then Exit;
  if FRelayouting then Exit;
  SB := TcxScrollBox(FScroll);
  // Ignorar tamanyos transitorios (p.ej. mientras aparece/desaparece la barra
  // vertical durante un resize) que provocarian un layout intermedio erroneo.
  if SB.ClientWidth < 50 then Exit;
  FRelayouting := True;
  // Recordar la posicion de scroll y llevarla a 0 mientras recolocamos: asi los
  // hijos se posicionan en un marco limpio (sin desfase por scroll) y el
  // scrollbox recalcula bien su rango. Al final restauramos una posicion valida.
  var PrevPos: Integer := SB.VertScrollBar.Position;
  SB.VertScrollBar.Position := 0;
  try
    ContentW := SB.ClientWidth - M * 2;
    if ContentW < 300 then ContentW := 300;
    Gap3 := 16;
    Y := 24;

    // Recorrer las secciones EN EL ORDEN actual (reordenable por el usuario).
    for SecIdx := 0 to High(FSectionOrder) do
    begin
      Key := FSectionOrder[SecIdx];

      if Key = 'header' then
      begin
        // Empresa | Proyecto | Usuario en 3 columnas iguales.
        HdrW := (ContentW - Gap3 * 2) div 3;
        X := M;
        // Altura reducida para la fila de cabecera (antes 140 en el DFM).
        pnlEmpresa.SetBounds(X, Y, HdrW, HeaderH);
        Inc(X, HdrW + Gap3);
        pnlProyecto.SetBounds(X, Y, HdrW, HeaderH);
        Inc(X, HdrW + Gap3);
        pnlUsuario.SetBounds(X, Y, M + ContentW - X, HeaderH);
        Y := Y + HeaderH + 20;
      end
      else if Key = 'kpis' then
      begin
        pnlMetricas.SetBounds(M, Y, ContentW, pnlMetricas.Height);
        LayoutCardsGrid;
        Y := pnlMetricas.Top + pnlMetricas.Height + 20;
      end
      else if (Key = 'proyecto') and Assigned(pnlProyectoActivo) then
      begin
        pnlProyectoActivo.SetBounds(M, Y, ContentW, pnlProyectoActivo.Height);
        LayoutProyectoWidgets;
        Y := pnlProyectoActivo.Top + pnlProyectoActivo.Height + 16;
      end
      else if (Key = 'cronograma') and (FCardCronograma <> nil) then
      begin
        // Seccion propia y dragable (tarjeta blanca con el mini-Gantt).
        Y := Y + LayoutCronogramaSection(M, Y, ContentW) + 16;
      end
      else if (Key = 'erp') and (FPnlErp <> nil) then
      begin
        LayoutErpSection(Y);
        Y := FPnlErp.Top + FPnlErp.Height + 16;
      end
      else if (Key = 'maestros') and (FPnlMaestros <> nil) then
      begin
        LayoutMaestrosSection(Y);
        Y := FPnlMaestros.Top + FPnlMaestros.Height + 16;
      end
      else if (Key = 'acciones') and Assigned(pnlAcciones) then
      begin
        // Altura fija (no acumular): NO sumar a pnlAcciones.Height en cada pasada.
        pnlAcciones.SetBounds(M, Y, ContentW, pnlAcciones.Height);
        Y := pnlAcciones.Top + pnlAcciones.Height + 24;   // margen inferior
      end;
    end;

    // El spacer marca el borde inferior REAL del contenido -> el scrollbox
    // deriva de el un rango vertical determinista (independiente de como se
    // llegue: resize, maximize, minimize/restore, reordenar secciones).
    if FSpacer <> nil then
    begin
      FSpacer.SetBounds(0, Y, 10, 1);
      FSpacer.SendToBack;   // no tapa nada
    end;

    // Restaurar la posicion de scroll, CLAMPADA al nuevo rango. Si el contenido
    // ahora cabe (Y <= alto visible), queda en 0 (primera seccion pegada al top,
    // sin hueco). Si no, se limita al maximo valido (evita el gran hueco tras
    // hacer scroll al fondo y luego resize).
    var MaxPos: Integer := Y - SB.ClientHeight;
    if MaxPos < 0 then MaxPos := 0;
    if PrevPos > MaxPos then PrevPos := MaxPos;
    SB.VertScrollBar.Position := PrevPos;
  finally
    FRelayouting := False;
  end;
end;

// Coloca las cards en un grid responsive dentro de pnlMetricas y ajusta el
// alto de pnlMetricas al numero de filas. NO empuja las secciones de abajo:
// de eso se encarga RelayoutAll (que llama aqui). Asume que pnlMetricas ya
// tiene su ancho definitivo.
procedure TfrmDashboard.LayoutCardsGrid;
var
  I, Cols, Rows, ColW, X, Y, Row, Col, Idx: Integer;
  AvailW, NumVis: Integer;
  Card: TKPICard;
begin
  if (FCards = nil) or (FCards.Count = 0) then Exit;

  // Solo cuentan/posicionan las cards VISIBLES (las ocultas por el usuario no
  // ocupan celda). Ademas, ocultarlas de verdad como controles.
  NumVis := 0;
  for I := 0 to FCards.Count - 1 do
    if TKPICard(FCards[I]).Visible then Inc(NumVis);
  if NumVis = 0 then
  begin
    pnlMetricas.Height := CARD_MARGIN * 2 + CARD_H;
    Exit;
  end;

  AvailW := pnlMetricas.ClientWidth - CARD_MARGIN * 2;
  if AvailW < CARD_MIN_W then AvailW := CARD_MIN_W;

  // Columnas = cuantas cards de ancho minimo caben (con separacion), acotado
  // a [1 .. NumVisibles].
  Cols := (AvailW + CARD_GAP) div (CARD_MIN_W + CARD_GAP);
  if Cols < 1 then Cols := 1;
  if Cols > NumVis then Cols := NumVis;

  // Ancho de columna repartiendo el espacio sobrante (cards elasticas), con
  // tope maximo para que no se vuelvan gigantes.
  ColW := (AvailW - CARD_GAP * (Cols - 1)) div Cols;
  if ColW > CARD_MAX_W then ColW := CARD_MAX_W;

  Rows := (NumVis + Cols - 1) div Cols;

  // Alto de pnlMetricas segun filas (sin empujar nada; lo hace RelayoutAll).
  pnlMetricas.Height := CARD_MARGIN * 2 + Rows * CARD_H + (Rows - 1) * CARD_GAP;

  // Posicionar cada card VISIBLE en su celda (salvo la que se esta arrastrando).
  Idx := 0;
  for I := 0 to FCards.Count - 1 do
  begin
    Card := TKPICard(FCards[I]);
    if not Card.Visible then Continue;   // ocultas no ocupan celda
    if Card = FDragCard then begin Inc(Idx); Continue; end;
    Row := Idx div Cols;
    Col := Idx mod Cols;
    Inc(Idx);
    X := CARD_MARGIN + Col * (ColW + CARD_GAP);
    Y := CARD_MARGIN + Row * (CARD_H + CARD_GAP);
    Card.SetBounds(X, Y, ColW, CARD_H);
  end;
end;

// ---- Persistencia del orden de las cards (por usuario) ----
procedure TfrmDashboard.LoadCardOrder;
var
  Js, K: string;
  RootVal: TJSONValue;
  Arr: TJSONArray;
  V: TJSONValue;
  I, J: Integer;
  Ordered: TList;
  Card: TKPICard;
begin
  Js := DMPlanner.UserPrefs.Load(DASHBOARD_PREF_KEY);
  if Js = '' then Exit;

  RootVal := nil;
  try
    RootVal := TJSONObject.ParseJSONValue(Js);
    try
      if not (RootVal is TJSONObject) then Exit;

      // --- Orden (opcional) ---
      Arr := TJSONObject(RootVal).GetValue('cardOrder') as TJSONArray;
      if Arr <> nil then
      begin
        // Reconstruir FCards en el orden guardado; las cards no listadas quedan
        // al final en su orden actual (robusto ante cambios de catalogo).
        Ordered := TList.Create;
        try
          for V in Arr do
          begin
            K := V.Value;
            for I := 0 to FCards.Count - 1 do
            begin
              Card := TKPICard(FCards[I]);
              if (Card.Key = K) and (Ordered.IndexOf(Card) < 0) then
              begin
                Ordered.Add(Card);
                Break;
              end;
            end;
          end;
          for J := 0 to FCards.Count - 1 do
            if Ordered.IndexOf(FCards[J]) < 0 then
              Ordered.Add(FCards[J]);
          FCards.Clear;
          for J := 0 to Ordered.Count - 1 do
            FCards.Add(Ordered[J]);
        finally
          Ordered.Free;
        end;
      end;

      // --- Visibilidad (opcional): las cards cuyo Key este en "hidden" se ocultan ---
      Arr := TJSONObject(RootVal).GetValue('hidden') as TJSONArray;
      if Arr <> nil then
        for V in Arr do
        begin
          K := V.Value;
          for I := 0 to FCards.Count - 1 do
          begin
            Card := TKPICard(FCards[I]);
            if Card.Key = K then
            begin
              Card.Visible := False;
              Break;
            end;
          end;
        end;

      // --- Periodo de las sparklines (opcional) ---
      var RangoVal := TJSONObject(RootVal).GetValue('rangoDias');
      if RangoVal <> nil then
      begin
        FRangoDias := StrToIntDef(RangoVal.Value, FRangoDias);
        UpdateRangoButtons;   // reflejar en los botones (ya creados)
      end;

      // --- Comprobacion automatica: ERP carga y ERP maestros (opcional) ---
      var ErpVal := TJSONObject(RootVal).GetValue('erpIntervalMin');
      if (ErpVal <> nil) and (FTimerErp <> nil) then
      begin
        FErpIntervalMin := StrToIntDef(ErpVal.Value, 0);
        FTimerErp.Enabled := FErpIntervalMin > 0;
        if FErpIntervalMin > 0 then
          FTimerErp.Interval := FErpIntervalMin * 60 * 1000;
      end;
      var ErpSu := TJSONObject(RootVal).GetValue('erpAutoStartup');
      if ErpSu is TJSONBool then FErpAutoStartup := TJSONBool(ErpSu).AsBoolean;

      var MaeVal := TJSONObject(RootVal).GetValue('maestrosIntervalMin');
      if (MaeVal <> nil) and (FTimerMaestros <> nil) then
      begin
        FMaestrosIntervalMin := StrToIntDef(MaeVal.Value, 0);
        FTimerMaestros.Enabled := FMaestrosIntervalMin > 0;
        if FMaestrosIntervalMin > 0 then
          FTimerMaestros.Interval := FMaestrosIntervalMin * 60 * 1000;
      end;
      var MaeSu := TJSONObject(RootVal).GetValue('maestrosAutoStartup');
      if MaeSu is TJSONBool then FMaestrosAutoStartup := TJSONBool(MaeSu).AsBoolean;

      // --- Orden de las secciones (opcional) ---
      Arr := TJSONObject(RootVal).GetValue('sectionOrder') as TJSONArray;
      if Arr <> nil then
      begin
        // Reconstruir respetando solo claves conocidas; anadir al final las que
        // falten (robusto ante cambios de catalogo de secciones).
        var Nuevas: TArray<string>;
        SetLength(Nuevas, 0);
        for V in Arr do
        begin
          K := V.Value;
          if (SectionControl(K) <> nil) or (K = 'header') then
          begin
            SetLength(Nuevas, Length(Nuevas) + 1);
            Nuevas[High(Nuevas)] := K;
          end;
        end;
        // Anadir las secciones por defecto que no estuvieran en el guardado.
        for K in FSectionOrder do
          if IndexStr(K, Nuevas) < 0 then
          begin
            SetLength(Nuevas, Length(Nuevas) + 1);
            Nuevas[High(Nuevas)] := K;
          end;
        if Length(Nuevas) > 0 then
          FSectionOrder := Nuevas;
      end;
    finally
      RootVal.Free;
    end;
  except
    // JSON corrupto -> orden por defecto, sin romper la pantalla.
  end;
end;

procedure TfrmDashboard.SaveCardOrder;
var
  Root: TJSONObject;
  ArrOrder, ArrHidden: TJSONArray;
  I: Integer;
  Card: TKPICard;
begin
  Root := TJSONObject.Create;
  try
    // Orden (todas las cards, visibles u ocultas) + lista de ocultas por Key.
    ArrOrder := TJSONArray.Create;
    ArrHidden := TJSONArray.Create;
    for I := 0 to FCards.Count - 1 do
    begin
      Card := TKPICard(FCards[I]);
      ArrOrder.Add(Card.Key);
      if not Card.Visible then
        ArrHidden.Add(Card.Key);
    end;
    Root.AddPair('cardOrder', ArrOrder);
    Root.AddPair('hidden', ArrHidden);
    Root.AddPair('rangoDias', TJSONNumber.Create(FRangoDias));
    Root.AddPair('erpIntervalMin', TJSONNumber.Create(FErpIntervalMin));
    Root.AddPair('erpAutoStartup', TJSONBool.Create(FErpAutoStartup));
    Root.AddPair('maestrosIntervalMin', TJSONNumber.Create(FMaestrosIntervalMin));
    Root.AddPair('maestrosAutoStartup', TJSONBool.Create(FMaestrosAutoStartup));
    // Orden de las secciones del dashboard.
    var ArrSec := TJSONArray.Create;
    for I := 0 to High(FSectionOrder) do
      ArrSec.Add(FSectionOrder[I]);
    Root.AddPair('sectionOrder', ArrSec);
    DMPlanner.UserPrefs.Save(DASHBOARD_PREF_KEY, Root.ToJSON);
  finally
    Root.Free;
  end;
end;

// ---- Drag & drop para reordenar las cards ----
procedure TfrmDashboard.CardMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FDragCard := Sender;
  FDragging := False;
  FDragStart := TKPICard(Sender).ClientToScreen(Point(X, Y));
  FDragDX := X;
  FDragDY := Y;
end;

procedure TfrmDashboard.CardMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  ScrPt, PanelPt, CenterPnl: TPoint;
  Card: TKPICard;
  TargetIdx, DragIdx, I: Integer;
  Other: TKPICard;
begin
  if FDragCard <> Sender then Exit;
  if not (ssLeft in Shift) then Exit;

  Card := TKPICard(FDragCard);
  ScrPt := Card.ClientToScreen(Point(X, Y));

  // Umbral: no consideramos arrastre hasta mover unos pixeles (evita micro-
  // desplazamientos al hacer clic).
  if (not FDragging) and
     (Abs(ScrPt.X - FDragStart.X) + Abs(ScrPt.Y - FDragStart.Y) < 6) then Exit;

  if not FDragging then
  begin
    FDragging := True;
    // Reparentar la card al scrollbox (contenedor de todo el area scrollable)
    // para que NO la recorte pnlMetricas ni la tapen los paneles de abajo
    // mientras se arrastra. Se devuelve a pnlMetricas al soltar (RelayoutAll).
    if FScroll <> nil then
      Card.Parent := TWinControl(FScroll);
    Card.BringToFront;
  end;

  // Mover la card siguiendo el cursor, en coordenadas de su parent ACTUAL
  // (el scrollbox durante el arrastre).
  PanelPt := Card.Parent.ScreenToClient(ScrPt);
  Card.Left := PanelPt.X - FDragDX;
  Card.Top := PanelPt.Y - FDragDY;

  // Para la deteccion de reordenacion, comparamos el centro de la card (en
  // coordenadas de pnlMetricas) con las celdas de las demas cards, que siguen
  // dentro de pnlMetricas.
  CenterPnl := pnlMetricas.ScreenToClient(
    Card.Parent.ClientToScreen(
      Point(Card.Left + Card.Width div 2, Card.Top + Card.Height div 2)));

  DragIdx := FCards.IndexOf(FDragCard);
  TargetIdx := -1;
  for I := 0 to FCards.Count - 1 do
  begin
    Other := TKPICard(FCards[I]);
    if Other = Card then Continue;
    if not Other.Visible then Continue;
    if PtInRect(Other.BoundsRect, CenterPnl) then
    begin
      TargetIdx := I;
      Break;
    end;
  end;

  if (TargetIdx >= 0) and (TargetIdx <> DragIdx) then
  begin
    FCards.Move(DragIdx, TargetIdx);
    LayoutCardsGrid;   // recoloca todas menos la arrastrada (FDragCard)
  end;
end;

procedure TfrmDashboard.CardMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FDragCard <> Sender then Exit;
  if FDragging then
  begin
    // Devolver la card a su contenedor real antes de recolocar.
    if (Sender is TKPICard) and (TKPICard(Sender).Parent <> pnlMetricas) then
    begin
      TKPICard(Sender).Parent := pnlMetricas;
      TKPICard(Sender).BackColor := pnlMetricas.Color;
    end;
    FDragCard := nil;
    RelayoutAll;     // encaja la card soltada y reasienta todo
    SaveCardOrder;   // persiste el nuevo orden
  end
  else
  begin
    // Fue un clic simple (no arrastre): disparar la accion de la card si tiene.
    FDragCard := nil;
    if (Sender is TKPICard) and Assigned(TKPICard(Sender).OnClickEx) then
      TKPICard(Sender).OnClickEx(Sender);
  end;
  FDragging := False;
end;

procedure TfrmDashboard.HideOldMetricLabels;
var
  I: Integer;
  Ctrl: TControl;
begin
  // El pnlMetricas conserva los labels antiguos del DFM (lblCap*, lblVal*,
  // lblMetricasCap...). Los ocultamos para dejar limpio el panel para las
  // nuevas KPI cards. NO los borramos para no romper la coherencia del DFM.
  for I := 0 to pnlMetricas.ControlCount - 1 do
  begin
    Ctrl := pnlMetricas.Controls[I];
    if Ctrl is TLabel then
      TLabel(Ctrl).Visible := False;
  end;
end;
procedure TfrmDashboard.TimerRelojTimer(Sender: TObject);
begin
  ActualizarReloj;
end;
procedure TfrmDashboard.ActualizarReloj;
begin
  lblFechaHora.Caption := FormatDateTime('dddd d" de "mmmm" de "yyyy   hh:nn:ss', Now);
end;
procedure TfrmDashboard.InvalidarCache;
begin
  FCargado := False;
end;

function TfrmDashboard.EstaCargado: Boolean;
begin
  Result := FCargado;
end;

procedure TfrmDashboard.RefrescarSiHaceFalta;
begin
  if not FCargado then
    Refrescar;
end;

procedure TfrmDashboard.Refrescar(AForzar: Boolean = False);
var
  S: TUserSession;
  Tipo: string;
  NumCal, NumCen, NumArea, NumDept, NumTurn, NumSkill, NumOp: Integer;
  T0, TGlobal: TDateTime;

  procedure Tic(const AEtapa: string);
  begin
    PlanLog.Linea('  DASH.%s: %d ms', [AEtapa, MilliSecondsBetween(Now, T0)]);
    T0 := Now;
  end;

begin
  TGlobal := Now;
  T0 := Now;
  PlanLog.Linea('DASH.Refrescar INICIO (Forzar=%s Demo=%s)',
    [BoolToStr(AForzar, True), BoolToStr(DemoMode.Active, True)]);
  // AForzar solo lo respeta MostrarDashboard (Main) para evitar recalcular al
  // volver de otra pantalla si ya se cargo. Los refrescos internos (cambio de
  // periodo, botones, FormShow) llaman sin forzar pero SIEMPRE deben recalcular,
  // por eso la cache solo corta cuando el llamante es MostrarDashboard, que usa
  // PuedeSaltarRefresco. Aqui simplemente marcamos que ya hay datos.
  FCargado := True;
  // Empresa
  if DMPlanner.CurrentEmpresaNombre <> '' then
    lblEmpresaNombre.Caption := DMPlanner.CurrentEmpresaNombre
  else
    lblEmpresaNombre.Caption := '--';
  lblEmpresaCodigo.Caption := 'Código: ' + IntToStr(DMPlanner.CodigoEmpresa);
  if DemoMode.Active then
  begin
    // Modo Demo: contadores de configuracion ficticios (no se toca la BD; los 5
    // COUNT(*) eran el mayor coste de cada refresco al volver al Dashboard).
    NumCal := 6; NumCen := 10; NumArea := 4; NumDept := 5;
    NumTurn := 3; NumSkill := 8; NumOp := 18;
  end
  else
  begin
    NumCal := 0;
    if DMPlanner.CalendarsRepo <> nil then
      NumCal := DMPlanner.CalendarsRepo.Count;
    NumCen := 0;
    if DMPlanner.CentresRepo <> nil then
      NumCen := DMPlanner.CentresRepo.Count;
    // Un UNICO round-trip para los 5 contadores (antes eran 5 COUNT(*)
    // separados = 5x latencia; en BD real remota eso era ~1,2s). Cada subconsulta
    // se protege por si una tabla no existe (migracion no aplicada): si falla el
    // conjunto, caemos a los CountTable individuales.
    NumArea := 0; NumDept := 0; NumTurn := 0; NumSkill := 0; NumOp := 0;
    var QC := TADOQuery.Create(nil);
    try
      QC.Connection := DMPlanner.ADOConnection;
      var CEc := IntToStr(DMPlanner.CodigoEmpresa);
      QC.SQL.Text :=
        'SELECT ' +
        '  (SELECT COUNT(*) FROM FS_PL_Area WHERE CodigoEmpresa=' + CEc + ') AS NArea, ' +
        '  (SELECT COUNT(*) FROM FS_PL_Department WHERE CodigoEmpresa=' + CEc + ') AS NDept, ' +
        '  (SELECT COUNT(*) FROM FS_PL_Shift WHERE CodigoEmpresa=' + CEc + ') AS NTurn, ' +
        '  (SELECT COUNT(*) FROM FS_PL_OperatorSkill WHERE CodigoEmpresa=' + CEc + ') AS NSkill, ' +
        '  (SELECT COUNT(*) FROM FS_PL_Operator WHERE CodigoEmpresa=' + CEc + ') AS NOp';
      try
        QC.Open;
        NumArea := QC.FieldByName('NArea').AsInteger;
        NumDept := QC.FieldByName('NDept').AsInteger;
        NumTurn := QC.FieldByName('NTurn').AsInteger;
        NumSkill := QC.FieldByName('NSkill').AsInteger;
        NumOp := QC.FieldByName('NOp').AsInteger;
      except
        // Fallback individual (alguna tabla puede no existir).
        NumArea := DMPlanner.CountTable('FS_PL_Area');
        NumDept := DMPlanner.CountTable('FS_PL_Department');
        NumTurn := DMPlanner.CountTable('FS_PL_Shift');
        NumSkill := DMPlanner.CountTable('FS_PL_OperatorSkill');
        NumOp := DMPlanner.CountTable('FS_PL_Operator');
      end;
    finally
      QC.Free;
    end;
  end;
  lblValCalendarios.Caption := IntToStr(NumCal);
  lblValCentros.Caption := IntToStr(NumCen);
  lblValAreas.Caption := IntToStr(NumArea);
  lblValDepartamentos.Caption := IntToStr(NumDept);
  lblValTurnos.Caption := IntToStr(NumTurn);
  lblValCapacitaciones.Caption := IntToStr(NumSkill);
  lblValOperarios.Caption := IntToStr(NumOp);
  Tic('Contadores');
  RefrescarProyectoActivo;
  Tic('ProyectoActivo');
  RefrescarPendingSync;
  Tic('PendingSync');
  RefrescarSalud;
  Tic('Salud');
  RefrescarKPIsAvanzados;
  Tic('KPIsAvanzados');
  RefrescarKPIsStock;
  Tic('KPIsStock');
  // Proyecto
  if DMPlanner.CurrentProjectId > 0 then
  begin
    lblProyectoNombre.Caption := DMPlanner.CurrentProjectName;
    if DMPlanner.CurrentProjectIsMaster then
      Tipo := 'MASTER'
    else
      Tipo := 'Escenario';
    lblProyectoTipo.Caption := 'Tipo: ' + Tipo;
  end
  else
  begin
    lblProyectoNombre.Caption := 'Sin proyecto';
    lblProyectoTipo.Caption := 'Tipo: --';
  end;
  // Usuario
  S := CurrentSession;
  if S.UserId > 0 then
  begin
    if S.NombreCompleto <> '' then
      lblUsuarioNombre.Caption := S.NombreCompleto
    else
      lblUsuarioNombre.Caption := S.Login;
    lblUsuarioRol.Caption := 'Rol: ' + S.RoleNombre;
  end
  else
  begin
    lblUsuarioNombre.Caption := '--';
    lblUsuarioRol.Caption := 'Rol: --';
  end;
  PlanLog.Linea('DASH.Refrescar TOTAL: %d ms', [MilliSecondsBetween(Now, TGlobal)]);
end;

// Resumen del plan para el mini-Gantt del cronograma: por cada centro con
// carga, su ocupacion (%) semana a semana, y la saturacion global por semana.
// Ocupacion = horas_carga / horas_capacidad. Capacidad aproximada a 40h/semana
// por centro (vision indicativa, coherente con el KPI de saturacion del panel).
// Devuelve hasta AMaxCentros filas, ordenadas por carga total desc.
// Centros ficticios para el modo DEMO: 6 centros, 12 semanas, ocupacion variada
// y determinista (incluye tramos vacios y sobrecarga roja). Sin BD.
function DemoGanttCentros: TArray<TTimelineCentroRow>;
const
  NOMBRES: array[0..5] of string =
    ('Torno CNC', 'Fresadora', 'Soldadura', 'Montaje', 'Pintura', 'Control');
var
  I, J: Integer;
  Base, Onda: Double;
begin
  SetLength(Result, 6);
  for I := 0 to 5 do
  begin
    Result[I].Nombre := NOMBRES[I];
    SetLength(Result[I].OcupPct, 12);
    Base := 40 + I * 14;   // cada centro parte de un nivel distinto
    for J := 0 to 11 do
    begin
      Onda := Base + 55 * Sin((J + I) * 0.6) + 20 * Cos(J * 0.9 + I);
      // Algunos huecos al principio/final segun el centro (escalonado).
      if (J < I - 1) or (J > 11 - (5 - I)) then
        Result[I].OcupPct[J] := -1
      else if Onda < 0 then
        Result[I].OcupPct[J] := 5
      else
        Result[I].OcupPct[J] := Onda;
    end;
  end;
end;

procedure GanttResumenPlan(const AInicio, AFin: TDateTime;
  const ACE, APID: string; AMaxCentros: Integer;
  out ACentros: TArray<TTimelineCentroRow>; out ASatur: TArray<Double>);
const
  CAP_SEMANA_H = 40.0;   // capacidad aproximada por centro y semana
var
  Q: TADOQuery;
  NumSem, Idx, Sem, NumCen, I: Integer;
  CenId: Integer;
  Horas: Double;
  // acumuladores por centro
  Nombres: TDictionary<Integer, string>;
  CargaCen: TDictionary<Integer, TArray<Double>>;
  TotalCen: TDictionary<Integer, Double>;
  Arr: TArray<Double>;
  Orden: TList<Integer>;
  CargaGlobal: TArray<Double>;
begin
  SetLength(ACentros, 0);
  SetLength(ASatur, 0);
  NumSem := Max(1, Ceil((Trunc(AFin) - Trunc(AInicio) + 1) / 7));
  if NumSem > 104 then NumSem := 104;

  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) or
     (not DMPlanner.ADOConnection.Connected) then Exit;

  Nombres := TDictionary<Integer, string>.Create;
  CargaCen := TDictionary<Integer, TArray<Double>>.Create;
  TotalCen := TDictionary<Integer, Double>.Create;
  Orden := TList<Integer>.Create;
  SetLength(CargaGlobal, NumSem);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT n.CenterId, ' +
      '  DATEDIFF(day, :Ini, n.FechaInicio) / 7 AS Semana, ' +
      '  SUM(ISNULL(n.DuracionMin, 0)) / 60.0 AS Horas ' +
      'FROM FS_PL_Node n ' +
      'WHERE n.CodigoEmpresa = ' + ACE + ' AND n.ProjectId = ' + APID +
      '  AND n.FechaInicio IS NOT NULL AND n.CenterId IS NOT NULL ' +
      'GROUP BY n.CenterId, DATEDIFF(day, :Ini, n.FechaInicio) / 7';
    Q.Parameters.ParamByName('Ini').Value := Trunc(AInicio);
    try
      Q.Open;
      while not Q.Eof do
      begin
        CenId := Q.FieldByName('CenterId').AsInteger;
        Sem := Q.FieldByName('Semana').AsInteger;
        Horas := Q.FieldByName('Horas').AsFloat;
        if (Sem >= 0) and (Sem < NumSem) then
        begin
          if not CargaCen.TryGetValue(CenId, Arr) then
          begin
            SetLength(Arr, NumSem);
            Orden.Add(CenId);
          end;
          Arr[Sem] := Arr[Sem] + Horas;
          CargaCen.AddOrSetValue(CenId, Arr);
          var TAcum: Double := 0;
          TotalCen.TryGetValue(CenId, TAcum);
          TotalCen.AddOrSetValue(CenId, TAcum + Horas);
          CargaGlobal[Sem] := CargaGlobal[Sem] + Horas;
        end;
        Q.Next;
      end;
    except
      // tabla ausente o error: devolvemos vacio
    end;

    // Nombres de centro (desde el repo, evita otra query).
    if DMPlanner.CentresRepo <> nil then
    begin
      var Todos := DMPlanner.CentresRepo.GetAll;
      for I := 0 to High(Todos) do
        if Trim(Todos[I].Titulo) <> '' then
          Nombres.AddOrSetValue(Todos[I].Id, Todos[I].Titulo)
        else
          Nombres.AddOrSetValue(Todos[I].Id, Todos[I].CodiCentre);
    end;

    // Ordenar centros por carga total desc.
    Orden.Sort(TComparer<Integer>.Construct(
      function(const A, B: Integer): Integer
      var TA, TB: Double;
      begin
        TA := 0; TB := 0;
        TotalCen.TryGetValue(A, TA); TotalCen.TryGetValue(B, TB);
        Result := CompareValue(TB, TA);
      end));

    NumCen := Orden.Count;
    if NumCen > AMaxCentros then NumCen := AMaxCentros;
    SetLength(ACentros, NumCen);
    for I := 0 to NumCen - 1 do
    begin
      CenId := Orden[I];
      if not Nombres.TryGetValue(CenId, ACentros[I].Nombre) then
        ACentros[I].Nombre := 'Centro ' + IntToStr(CenId);
      CargaCen.TryGetValue(CenId, Arr);
      SetLength(ACentros[I].OcupPct, NumSem);
      for Idx := 0 to NumSem - 1 do
        if Arr[Idx] <= 0 then ACentros[I].OcupPct[Idx] := -1  // sin actividad
        else ACentros[I].OcupPct[Idx] := Arr[Idx] / CAP_SEMANA_H * 100.0;
    end;

    // Saturacion global por semana = carga total / (nº centros activos * 40h).
    NumCen := Orden.Count;
    SetLength(ASatur, NumSem);
    for Idx := 0 to NumSem - 1 do
      if (NumCen <= 0) or (CargaGlobal[Idx] <= 0) then ASatur[Idx] := -1
      else ASatur[Idx] := CargaGlobal[Idx] / (NumCen * CAP_SEMANA_H) * 100.0;
  finally
    Q.Free;
    Nombres.Free;
    CargaCen.Free;
    TotalCen.Free;
    Orden.Free;
  end;
end;

procedure TfrmDashboard.RefrescarProyectoActivo;
  function FmtDate(const AV: Variant): string;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then
      Result := '--'
    else
      Result := FormatDateTime('dd/mm/yyyy', TDateTime(AV));
  end;
  function FmtPct(ANum, ADen: Integer): string;
  var
    P: Double;
  begin
    if ADen <= 0 then Exit('(0%)');
    P := (ANum * 100.0) / ADen;
    Result := Format('(%.0f%%)', [P]);
  end;
  function FmtDuracion(AMinutos: Double): string;
  var
    H, M: Integer;
    Dias: Double;
  begin
    if AMinutos <= 0 then Exit('0 h');
    H := Trunc(AMinutos / 60);
    M := Round(AMinutos - H * 60);
    Dias := AMinutos / (60 * 24);
    if Dias >= 1 then
      Result := Format('%.1f días (%dh %dm)', [Dias, H mod 24, M])
    else
      Result := Format('%dh %dm', [H, M]);
  end;
var
  Q: TADOQuery;
  CE, PID: string;
  ProjectId: Integer;
  NodosPlan, NodosTotal: Integer;
  OFsPlan, OFsTotal: Integer;
  PedidosPlan, PedidosTotal: Integer;
  CentrosUsados, OpAsig, Dependencias, Marcadores: Integer;
  DuracionTotal: Double;
  FInicio, FFin: Variant;
begin
  ProjectId := DMPlanner.CurrentProjectId;
  if (ProjectId <= 0) or (not DMPlanner.IsConnected) then
  begin
    lblValFechaInicio.Caption := '--';
    lblValFechaFin.Caption := '--';
    lblValFechaBloqueo.Caption := '--';
    lblValNodos.Caption := '--';
    lblValOFs.Caption := '--';
    lblValPedidos.Caption := '--';
    lblValCentrosUsados.Caption := '--';
    lblValOperariosAsignados.Caption := '--';
    lblValDuracionTotal.Caption := '--';
    lblValDependencias.Caption := '--';
    lblValMarcadores.Caption := '--';
    // Widgets a cero / vacio.
    if FWDonutNodos <> nil then
    begin
      TDonutWidget(FWDonutNodos).SetData(0, 0);
      TDonutWidget(FWDonutOFs).SetData(0, 0);
      TDonutWidget(FWDonutPedidos).SetData(0, 0);
      TGaugeWidget(FWGaugeSaturacion).SetData(0, '%');
      TTimelineWidget(FWTimeline).SetData(0, 0, False, 0);
    end;
    Exit;
  end;
  // En Demo NO tocamos la BD: estos 4 SELECT sobre FS_PL_Node/NodeData eran el
  // grueso del tiempo (ProyectoActivo ~1300 ms en real). Valores ficticios; los
  // widgets del mini-Gantt los rellena la rama Demo de mas abajo.
  if DemoMode.Active then
  begin
    NodosTotal := 128; NodosPlan := 112;
    OFsTotal := 24;    OFsPlan := 21;
    PedidosTotal := 17; PedidosPlan := 15;
    CentrosUsados := 9; OpAsig := 14; Dependencias := 72; Marcadores := 5;
    DuracionTotal := 304 * 60.0;              // 304 h en minutos
    FInicio := Trunc(Date) - 21;
    FFin := Trunc(Date) + 63;
  end
  else
  begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(ProjectId);
  // UN SOLO round-trip para TODOS los indicadores del proyecto activo. Antes
  // eran 4 queries separadas sobre FS_PL_Node/NodeData (la tabla grande) = 4x
  // latencia; en BD real remota eso era ~1,8s. Ahora una sola sentencia con
  // subconsultas correlacionadas. El JOIN NodeData solo se hace para OFs/Pedidos.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ' +
      '  (SELECT COUNT(*) FROM FS_PL_Node WHERE CodigoEmpresa=' + CE + ' AND ProjectId=' + PID + ') AS Total, ' +
      '  (SELECT COUNT(*) FROM FS_PL_Node WHERE CodigoEmpresa=' + CE + ' AND ProjectId=' + PID + ' AND FechaInicio IS NOT NULL) AS Planificados, ' +
      '  (SELECT MIN(FechaInicio) FROM FS_PL_Node WHERE CodigoEmpresa=' + CE + ' AND ProjectId=' + PID + ') AS FInicio, ' +
      '  (SELECT MAX(FechaFin) FROM FS_PL_Node WHERE CodigoEmpresa=' + CE + ' AND ProjectId=' + PID + ') AS FFin, ' +
      '  (SELECT ISNULL(SUM(DuracionMin),0) FROM FS_PL_Node WHERE CodigoEmpresa=' + CE + ' AND ProjectId=' + PID + ' AND FechaInicio IS NOT NULL) AS DurTotal, ' +
      '  (SELECT COUNT(DISTINCT nd.NumeroOF) FROM FS_PL_Node n INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa=n.CodigoEmpresa AND nd.NodeId=n.NodeId ' +
      '   WHERE n.CodigoEmpresa=' + CE + ' AND n.ProjectId=' + PID + ' AND nd.NumeroOF IS NOT NULL) AS OFsTotal, ' +
      '  (SELECT COUNT(DISTINCT CASE WHEN n.FechaInicio IS NOT NULL THEN nd.NumeroOF END) FROM FS_PL_Node n INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa=n.CodigoEmpresa AND nd.NodeId=n.NodeId ' +
      '   WHERE n.CodigoEmpresa=' + CE + ' AND n.ProjectId=' + PID + ' AND nd.NumeroOF IS NOT NULL) AS OFsPlan, ' +
      '  (SELECT COUNT(DISTINCT nd.NumeroPedido) FROM FS_PL_Node n INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa=n.CodigoEmpresa AND nd.NodeId=n.NodeId ' +
      '   WHERE n.CodigoEmpresa=' + CE + ' AND n.ProjectId=' + PID + ' AND nd.NumeroPedido IS NOT NULL) AS PedidosTotal, ' +
      '  (SELECT COUNT(DISTINCT CASE WHEN n.FechaInicio IS NOT NULL THEN nd.NumeroPedido END) FROM FS_PL_Node n INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa=n.CodigoEmpresa AND nd.NodeId=n.NodeId ' +
      '   WHERE n.CodigoEmpresa=' + CE + ' AND n.ProjectId=' + PID + ' AND nd.NumeroPedido IS NOT NULL) AS PedidosPlan, ' +
      '  (SELECT COUNT(DISTINCT CenterId) FROM FS_PL_Node WHERE CodigoEmpresa=' + CE + ' AND ProjectId=' + PID + ' AND CenterId IS NOT NULL AND FechaInicio IS NOT NULL) AS CentrosUsados, ' +
      '  (SELECT COUNT(DISTINCT oa.OperatorId) FROM FS_PL_OperatorAssignment oa INNER JOIN FS_PL_Node n2 ON n2.CodigoEmpresa=oa.CodigoEmpresa AND n2.NodeId=oa.NodeId ' +
      '   WHERE n2.CodigoEmpresa=' + CE + ' AND n2.ProjectId=' + PID + ') AS OpAsig, ' +
      '  (SELECT COUNT(*) FROM FS_PL_Dependency WHERE CodigoEmpresa=' + CE + ' AND ProjectId=' + PID + ') AS Deps, ' +
      '  (SELECT COUNT(*) FROM FS_PL_Marker WHERE CodigoEmpresa=' + CE + ' AND ProjectId=' + PID + ') AS Marcadores';
    Q.Open;
    NodosTotal := Q.FieldByName('Total').AsInteger;
    NodosPlan := Q.FieldByName('Planificados').AsInteger;
    FInicio := Q.FieldByName('FInicio').Value;
    FFin := Q.FieldByName('FFin').Value;
    DuracionTotal := Q.FieldByName('DurTotal').AsFloat;
    OFsTotal := Q.FieldByName('OFsTotal').AsInteger;
    OFsPlan := Q.FieldByName('OFsPlan').AsInteger;
    PedidosTotal := Q.FieldByName('PedidosTotal').AsInteger;
    PedidosPlan := Q.FieldByName('PedidosPlan').AsInteger;
    CentrosUsados := Q.FieldByName('CentrosUsados').AsInteger;
    OpAsig := Q.FieldByName('OpAsig').AsInteger;
    Dependencias := Q.FieldByName('Deps').AsInteger;
    Marcadores := Q.FieldByName('Marcadores').AsInteger;
  finally
    Q.Free;
  end;
  end;  // else (no Demo)
  lblValFechaInicio.Caption := FmtDate(FInicio);
  lblValFechaFin.Caption := FmtDate(FFin);
  if DMPlanner.CurrentProjectTieneBloqueo then
    lblValFechaBloqueo.Caption := FormatDateTime('dd/mm/yyyy', DMPlanner.CurrentProjectFechaBloqueo)
  else
    lblValFechaBloqueo.Caption := '(sin bloqueo)';
  lblValNodos.Caption := Format('%d / %d  %s', [NodosPlan, NodosTotal, FmtPct(NodosPlan, NodosTotal)]);
  lblValOFs.Caption := Format('%d / %d  %s', [OFsPlan, OFsTotal, FmtPct(OFsPlan, OFsTotal)]);
  lblValPedidos.Caption := Format('%d / %d  %s', [PedidosPlan, PedidosTotal, FmtPct(PedidosPlan, PedidosTotal)]);
  lblValCentrosUsados.Caption := IntToStr(CentrosUsados);
  lblValOperariosAsignados.Caption := IntToStr(OpAsig);
  lblValDuracionTotal.Caption := FmtDuracion(DuracionTotal);
  lblValDependencias.Caption := IntToStr(Dependencias);
  lblValMarcadores.Caption := IntToStr(Marcadores);

  // ---- KPI 5: Carga total planificada (horas) ----
  // DuracionTotal viene en minutos del bloque anterior.
  var CargaH: Double := DuracionTotal / 60.0;

  // ---- KPI 6: Saturacion media centros (%) ----
  // Aproximacion: (suma minutos asignados a nodos planificados) /
  // (NumCentrosUsados * dias_plan_habiles * 8h * 60min) * 100.
  // Se ignoran calendarios reales y turnos; es una vision indicativa.
  var Satur: Double := 0;
  if (CentrosUsados > 0) and not VarIsNull(FInicio) and not VarIsNull(FFin) then
  begin
    var DiasPlan: Integer := Max(1, Trunc(VarToDateTime(FFin) - VarToDateTime(FInicio)) + 1);
    // OJO: forzar Double desde el primer factor. Si se dejan los 4 operandos como
    // Integer, Delphi calcula el producto en aritmetica de 32 bits y solo al final
    // promociona a Double; con {$Q+} (Debug) un DiasPlan grande (fechas de nodo
    // disparatadas) hace que CentrosUsados*DiasPlan*8*60 rebase 2^31 -> EIntOverflow
    // ("Integer overflow"). En Release el wrap-around es silencioso pero da mal.
    var MinutosDisponibles: Double := CentrosUsados * DiasPlan * 8.0 * 60.0;
    if MinutosDisponibles > 0 then
      Satur := Min(100, DuracionTotal / MinutosDisponibles * 100);
  end;

  // ---- Modo DEMO: datos ficticios ricos para el bloque "Proyecto activo" ----
  // Sin tocar la BD. El objetivo es que el mini-Gantt del cronograma LUZCA aunque
  // el proyecto real sea pequeno (o vacio): rango amplio (~3 meses), varios
  // centros con ocupacion variada (incluida sobrecarga roja). Determinista.
  var DemoInicio, DemoFin: TDateTime;
  var DemoCentros: TArray<TTimelineCentroRow> := nil;
  var DemoSatur: TArray<Double> := nil;
  if DemoMode.Active then
  begin
    DemoInicio := Trunc(Date) - 21;          // empezo hace 3 semanas
    DemoFin := Trunc(Date) + 63;             // ~12 semanas totales
    NodosTotal := 128; NodosPlan := 112;
    OFsTotal := 24;    OFsPlan := 21;
    PedidosTotal := 17; PedidosPlan := 15;
    Satur := 82;
    OpAsig := 14;                             // operarios asignados (demo)
    CargaH := 304;                            // carga planificada (h) (demo)
    DemoCentros := DemoGanttCentros;         // helper local
    SetLength(DemoSatur, 12);
    for var K := 0 to 11 do
      DemoSatur[K] := 55 + 45 * Abs(Sin((K + 1) * 0.7));  // ola 55..100
  end;

  // ---- Widgets visuales del bloque "Proyecto activo" (Fase 4) ----
  if FWDonutNodos <> nil then
  begin
    TDonutWidget(FWDonutNodos).SetData(NodosPlan, NodosTotal);
    TDonutWidget(FWDonutOFs).SetData(OFsPlan, OFsTotal);
    TDonutWidget(FWDonutPedidos).SetData(PedidosPlan, PedidosTotal);
    TGaugeWidget(FWGaugeSaturacion).SetData(Satur, '%');
    if DemoMode.Active then
    begin
      TTimelineWidget(FWTimeline).SetData(DemoInicio, DemoFin, False, 0);
      TTimelineWidget(FWTimeline).SetGantt(DemoCentros, DemoSatur);
    end
    else if VarIsNull(FInicio) or VarIsNull(FFin) then
    begin
      TTimelineWidget(FWTimeline).SetData(0, 0,
        DMPlanner.CurrentProjectTieneBloqueo, DMPlanner.CurrentProjectFechaBloqueo);
      TTimelineWidget(FWTimeline).SetGantt(nil, nil);
    end
    else
    begin
      TTimelineWidget(FWTimeline).SetData(VarToDateTime(FInicio),
        VarToDateTime(FFin), DMPlanner.CurrentProjectTieneBloqueo,
        DMPlanner.CurrentProjectFechaBloqueo);
      var RCentros: TArray<TTimelineCentroRow>;
      var RSatur: TArray<Double>;
      GanttResumenPlan(VarToDateTime(FInicio), VarToDateTime(FFin), CE, PID,
        6, RCentros, RSatur);
      TTimelineWidget(FWTimeline).SetGantt(RCentros, RSatur);
    end;
  end;

  // ---- KPI 7: OFs en riesgo (entrega <= hoy+7 y no finalizadas) ----
  var OFsRiesgo: Integer := 0;
  if DemoMode.Active then
    OFsRiesgo := 3                            // OFs en riesgo (demo)
  else
  begin
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT COUNT(DISTINCT nd.NumeroOF) AS NumOFs ' +
        'FROM FS_PL_Node n ' +
        'INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa AND nd.NodeId = n.NodeId ' +
        'WHERE n.CodigoEmpresa = ' + CE + ' AND n.ProjectId = ' + PID +
        '  AND nd.NumeroOF IS NOT NULL ' +
        '  AND nd.FechaEntrega IS NOT NULL ' +
        '  AND nd.FechaEntrega <= DATEADD(day, 7, CAST(GETDATE() AS DATE)) ' +
        '  AND ISNULL(nd.Estado, 0) <> 2';   // 2 = neFinalizado
      Q.Open;
      OFsRiesgo := Q.FieldByName('NumOFs').AsInteger;
    finally
      Q.Free;
    end;
  end;

  // 1) Registrar el valor REAL de hoy (upsert). OFsPendientes se guarda aparte
  //    en RefrescarPendingSync (misma fila diaria). Asi la sparkline es
  //    historico verdadero, no una serie inventada.
  UpsertMetricDia(
    ['NodosPlanificados', 'OFsEnPlan', 'OperariosAsignados',
     'CargaPlanificadaH', 'SaturacionMedia', 'OFsEnRiesgo'],
    [NodosPlan, OFsPlan, OpAsig, CargaH, Satur, OFsRiesgo]);

  // 2) Pintar cada card con su serie (real historica, o ficticia en modo DEMO).
  SetKPI(FKPINodos,       NodosPlan, SerieKPI('NodosPlanificados', NodosPlan));
  SetKPI(FKPIOFsPlan,     OFsPlan,   SerieKPI('OFsEnPlan', OFsPlan));
  SetKPI(FKPIOpAsignados, OpAsig,    SerieKPI('OperariosAsignados', OpAsig));
  SetKPI(FKPICargaH,      CargaH,    SerieKPI('CargaPlanificadaH', CargaH), 'h');
  SetKPI(FKPISaturacion,  Satur,     SerieKPI('SaturacionMedia', Satur), '%');
  SetKPI(FKPIOFsRiesgo,   OFsRiesgo, SerieKPI('OFsEnRiesgo', OFsRiesgo));
end;

procedure TfrmDashboard.SetKPI(ACard: TObject; AValue: Double;
  const ASeries: array of Double; const AUnidad: string);
begin
  if not (ACard is TKPICard) then Exit;
  TKPICard(ACard).Unidad := AUnidad;
  TKPICard(ACard).SetValueAndSeries(AValue, ASeries);
end;

// Upsert de la fila de HOY en FS_PL_DashboardMetric con las columnas/valores
// dados (idempotente: si ya existe, actualiza esas columnas). Los KPIs se
// calculan en varias pasadas (proyecto activo + pendientes ERP), por eso se
// permite actualizar solo un subconjunto de columnas cada vez.
procedure TfrmDashboard.UpsertMetricDia(const AColumns: array of string;
  const AValues: array of Double);
var
  Cmd: TADOCommand;
  CE, PID, SetList, InsCols, InsVals: string;
  I: Integer;

  function Num(const V: Double): string;
  begin
    Result := StringReplace(FloatToStr(V), ',', '.', [rfReplaceAll]);
  end;

begin
  if (not DMPlanner.IsConnected) or (DMPlanner.CurrentProjectId <= 0) then Exit;
  if Length(AColumns) = 0 then Exit;
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(DMPlanner.CurrentProjectId);

  SetList := '';
  InsCols := '';
  InsVals := '';
  for I := 0 to High(AColumns) do
  begin
    if I > 0 then
    begin
      SetList := SetList + ', ';
      InsCols := InsCols + ', ';
      InsVals := InsVals + ', ';
    end;
    SetList := SetList + AColumns[I] + ' = ' + Num(AValues[I]);
    InsCols := InsCols + AColumns[I];
    InsVals := InsVals + Num(AValues[I]);
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.ParamCheck := False;
    try
      // UPDATE de hoy; si no afecta filas, INSERT. FechaActualizacion siempre.
      Cmd.CommandText :=
        'UPDATE FS_PL_DashboardMetric SET ' + SetList +
        ', FechaActualizacion = GETDATE() ' +
        'WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID +
        '  AND FechaDia = CAST(GETDATE() AS DATE); ' +
        'IF @@ROWCOUNT = 0 ' +
        '  INSERT INTO FS_PL_DashboardMetric ' +
        '    (CodigoEmpresa, ProjectId, FechaDia, ' + InsCols + ') ' +
        '  VALUES (' + CE + ', ' + PID + ', CAST(GETDATE() AS DATE), ' +
        InsVals + ');';
      Cmd.Execute;
    except
      // Si la tabla no existe (V068 no aplicada) o falla, no rompemos el panel.
    end;
  finally
    Cmd.Free;
  end;
end;

// Devuelve los ultimos ADiasMax dias del KPI indicado (columna) para el
// proyecto actual, en orden cronologico (antiguo -> reciente). Vacio si no hay
// historico (primeros dias): en ese caso la card no pinta sparkline.
function TfrmDashboard.LoadMetricSerie(const AColumn: string;
  ADiasMax: Integer): TArray<Double>;
var
  Fechas: TArray<TDateTime>;
begin
  LoadMetricSerieFechas(AColumn, ADiasMax, Result, Fechas);
end;

procedure TfrmDashboard.LoadMetricSerieFechas(const AColumn: string;
  ADiasMax: Integer; out AValores: TArray<Double>;
  out AFechas: TArray<TDateTime>);
var
  Q: TADOQuery;
  N, Dias: Integer;
begin
  AValores := nil;
  AFechas := nil;
  if (not DMPlanner.IsConnected) or (DMPlanner.CurrentProjectId <= 0) then Exit;

  // ADiasMax = 0 -> usar el periodo seleccionado en el dashboard.
  Dias := ADiasMax;
  if Dias <= 0 then Dias := RangoDiasEfectivo;
  if Dias <= 0 then Dias := 7;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    try
      // Subconsulta TOP N mas recientes, reordenada ascendente para la serie.
      Q.SQL.Text :=
        'SELECT val, FechaDia FROM (' +
        '  SELECT TOP ' + IntToStr(Dias) + ' ' + AColumn + ' AS val, FechaDia ' +
        '  FROM FS_PL_DashboardMetric ' +
        '  WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
        '    AND ProjectId = ' + IntToStr(DMPlanner.CurrentProjectId) +
        '  ORDER BY FechaDia DESC) t ' +
        'ORDER BY t.FechaDia ASC';
      Q.Open;
      N := 0;
      while not Q.Eof do
      begin
        SetLength(AValores, N + 1);
        SetLength(AFechas, N + 1);
        AValores[N] := Q.FieldByName('val').AsFloat;
        AFechas[N] := Q.FieldByName('FechaDia').AsDateTime;
        Inc(N);
        Q.Next;
      end;
    except
      // Tabla ausente / error -> sin serie.
    end;
  finally
    Q.Free;
  end;
end;

// Decide la serie de una card: si el modo DEMO esta activo, una serie ficticia
// creible hacia el valor actual (para demos / no mostrar sparklines vacias);
// si no, el historico real de BD.
function TfrmDashboard.SerieKPI(const AColumn: string;
  const AValorActual: Double): TArray<Double>;
var
  Seed: UInt64;
  I: Integer;
begin
  if DemoMode.Active then
  begin
    // Seed determinista por nombre de columna: cada KPI tiene una forma de
    // sparkline distinta (no todas iguales), pero estable entre refrescos.
    // OJO {$Q+} (Debug): con Seed:Cardinal, "Seed * 31" tambien dispara
    // EIntOverflow cuando el producto rebasa 2^32 -el chequeo de overflow salta
    // ANTES del "and", que llega tarde-. Acumulamos en UInt64 (32 bits nunca se
    // desbordan al multiplicar por 31) y enmascaramos a 31 bits en cada paso.
    Seed := 0;
    for I := 1 to Length(AColumn) do
      Seed := (Seed * 31 + UInt64(Ord(AColumn[I]))) and $7FFFFFFF;
    // Nº de puntos demo segun el periodo (acotado para no saturar la sparkline).
    var Pts: Integer := RangoDiasEfectivo;
    if Pts < 7 then Pts := 7;
    if Pts > 30 then Pts := 30;
    Result := DemoSerieHaciaValor(AValorActual, Pts, 0.22, Integer(Seed));
  end
  else
    Result := LoadMetricSerie(AColumn);
end;

procedure TfrmDashboard.RefrescarPendingSync;
var
  Q: TADOQuery;
  NumOFs, NumOTs: Integer;
begin
  // El label de estado de sincronizacion ya no se muestra en el header (la
  // informacion vive en los KPIs OFs/OTs pendientes). Se mantiene oculto; el
  // resto de la logica sigue actualizando los KPIs.
  lblPendingSync.Visible := False;
  lblValOFsPendientes.Caption := '--';
  lblValOFsPendientes.Font.Color := clBlack;
  lblValOTsPendientes.Caption := '--';
  lblValOTsPendientes.Font.Color := clBlack;

  // ---- Modo DEMO: pendientes ficticios (sin tocar BD). ----
  if DemoMode.Active then
  begin
    lblValOFsPendientes.Caption := '4';
    lblValOFsPendientes.Font.Color := clRed;
    lblValOTsPendientes.Caption := '9';
    lblValOTsPendientes.Font.Color := clRed;
    SetKPI(FKPIOFsPend, 4, SerieKPI('OFsPendientes', 4));
    Exit;
  end;

  if not DMPlanner.IsConnected then
  begin
    lblPendingSync.Caption := '(sin conexion BD)';
    Exit;
  end;
  NumOFs := 0;
  NumOTs := 0;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT NumOFsNuevas, NumOTsNuevas ' +
        'FROM dbo.FS_PL_fn_PendingErpOFs(:Emp)';
      Q.Parameters.ParamByName('Emp').Value := DMPlanner.CodigoEmpresa;
      Q.Open;
      if not Q.Eof then
      begin
        NumOFs := Q.FieldByName('NumOFsNuevas').AsInteger;
        NumOTs := Q.FieldByName('NumOTsNuevas').AsInteger;
      end;
    finally
      Q.Free;
    end;
  except
    on E: Exception do
    begin
      lblPendingSync.Caption := '(TVF ERP no disponible: ' + Copy(E.Message, 1, 60) + ')';
      Exit;
    end;
  end;
  if (NumOFs > 0) or (NumOTs > 0) then
  begin
    lblPendingSync.Caption := Format(
      'Existen %d OF y %d OT pendientes de sincronizar', [NumOFs, NumOTs]);
    lblPendingSync.Font.Color := clYellow;
  end
  else
  begin
    lblPendingSync.Caption := 'Sin pendientes de sincronizar';
    lblPendingSync.Font.Color := clWhite;
  end;
  lblValOFsPendientes.Caption := IntToStr(NumOFs);
  if NumOFs > 0 then
    lblValOFsPendientes.Font.Color := clRed
  else
    lblValOFsPendientes.Font.Color := clBlack;
  lblValOTsPendientes.Caption := IntToStr(NumOTs);
  if NumOTs > 0 then
    lblValOTsPendientes.Font.Color := clRed
  else
    lblValOTsPendientes.Font.Color := clBlack;

  // KPI card de OFs pendientes: registrar valor real de hoy (misma fila diaria)
  // y pintar con la serie (real, o ficticia en modo DEMO).
  UpsertMetricDia(['OFsPendientes'], [NumOFs]);
  SetKPI(FKPIOFsPend, NumOFs, SerieKPI('OFsPendientes', NumOFs));
end;

// Salud del plan + incidencias, calculado por SQL (sin necesidad de un Gantt
// vivo). Solo evalua los tipos de alerta que son comprobables directamente
// sobre los datos (FS_PL_Node/NodeData); los geometricos (solapamientos, zona
// no laborable...) requieren el Gantt y quedan fuera de este resumen. El indice
// de salud usa la MISMA ponderacion que el Gantt (CalcularSalud + pesos), para
// que el numero sea coherente entre pantallas.
procedure TfrmDashboard.RefrescarSalud;
var
  Q: TADOQuery;
  CE, PID: string;
  TotalNodos, Incidencias, Salud: Integer;
  Alertas: TArray<TAlertaItem>;

  // Anyade un TAlertaItem sintetico con ACount incidencias del tipo dado (peso
  // por defecto del catalogo), para alimentar CalcularSalud.
  procedure AddAlerta(ATipo: TAlertaTipo; ACount: Integer);
  var
    It: TAlertaItem;
    Ids: TArray<Integer>;
    K: Integer;
  begin
    if ACount <= 0 then Exit;
    // CalcularSalud solo mira Count (=Length(DataIds)) y Peso; no los ids reales.
    SetLength(Ids, ACount);
    for K := 0 to ACount - 1 do Ids[K] := K + 1;
    It := Default(TAlertaItem);
    It.Tipo := ATipo;
    It.Codigo := CodigoDe(ATipo);
    It.Implementada := True;
    It.Peso := PesoDefectoDe(ATipo);
    It.DataIds := Ids;
    SetLength(Alertas, Length(Alertas) + 1);
    Alertas[High(Alertas)] := It;
    Inc(Incidencias, ACount);
  end;

begin
  if FKPISalud = nil then Exit;
  Incidencias := 0;
  TotalNodos := 0;
  Alertas := nil;

  // Modo Demo: salud ficticia realista, sin query pesada ni UpsertMetricDia
  // (escritura a BD). Era ~500 ms en real.
  if DemoMode.Active then
  begin
    TKPICard(FKPISalud).ColorTone := kctVerde;
    TKPICard(FKPISalud).Caption := 'Salud del plan - Bueno';
    SetKPI(FKPISalud, 88, SerieKPI('Salud', 88));
    Exit;
  end;

  if (not DMPlanner.IsConnected) or (DMPlanner.CurrentProjectId <= 0) then
  begin
    SetKPI(FKPISalud, 0, SerieKPI('Salud', 0));
    Exit;
  end;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(DMPlanner.CurrentProjectId);

  // Un unico query con los contadores de cada tipo comprobable por datos.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    try
      Q.SQL.Text :=
        'SELECT ' +
        '  COUNT(*) AS TotalNodos, ' +
        // A01 activo antes de hoy (empieza en pasado y no finalizado)
        '  SUM(CASE WHEN n.FechaInicio < GETDATE() AND ISNULL(nd.Estado,0)<>2 ' +
        '           THEN 1 ELSE 0 END) AS ActivoAntes, ' +
        // A02 fuera de plazo (termina despues de FechaEntrega)
        '  SUM(CASE WHEN nd.FechaEntrega IS NOT NULL AND n.FechaFin > nd.FechaEntrega ' +
        '           THEN 1 ELSE 0 END) AS FueraPlazo, ' +
        // A04 sin fecha de entrega
        '  SUM(CASE WHEN nd.FechaEntrega IS NULL THEN 1 ELSE 0 END) AS SinFecha, ' +
        // O01 sin operarios (necesita y tiene 0)
        '  SUM(CASE WHEN nd.OperariosNecesarios>0 AND ISNULL(nd.OperariosAsignados,0)=0 ' +
        '           THEN 1 ELSE 0 END) AS SinOperarios, ' +
        // M01 sin stock suficiente
        '  SUM(CASE WHEN nd.UnidadesAFabricar>0 AND ISNULL(nd.Stock,0)<nd.UnidadesAFabricar ' +
        '           THEN 1 ELSE 0 END) AS SinStock, ' +
        // D03 duracion cero / sin unidades
        '  SUM(CASE WHEN ISNULL(n.DuracionMin,0)<=0 OR ISNULL(nd.UnidadesAFabricar,0)<=0 ' +
        '           THEN 1 ELSE 0 END) AS DuracionCero ' +
        'FROM FS_PL_Node n ' +
        'INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa=n.CodigoEmpresa AND nd.NodeId=n.NodeId ' +
        'WHERE n.CodigoEmpresa=' + CE + ' AND n.ProjectId=' + PID +
        '  AND n.FechaInicio IS NOT NULL';   // solo nodos planificados
      Q.Open;
      TotalNodos := Q.FieldByName('TotalNodos').AsInteger;
      AddAlerta(atActivoAntesHoy,   Q.FieldByName('ActivoAntes').AsInteger);
      AddAlerta(atFueraPlazoEntrega,Q.FieldByName('FueraPlazo').AsInteger);
      AddAlerta(atSinFechaEntrega,  Q.FieldByName('SinFecha').AsInteger);
      AddAlerta(atSinOperarios,     Q.FieldByName('SinOperarios').AsInteger);
      AddAlerta(atSinStock,         Q.FieldByName('SinStock').AsInteger);
      AddAlerta(atDuracionCero,     Q.FieldByName('DuracionCero').AsInteger);
    except
      // Sin datos / error -> salud neutra.
    end;
  finally
    Q.Free;
  end;

  Salud := CalcularSalud(Alertas, TotalNodos);

  // Tono semaforo del card segun la salud.
  if Salud >= 90 then TKPICard(FKPISalud).ColorTone := kctVerde
  else if Salud >= 75 then TKPICard(FKPISalud).ColorTone := kctAmbar
  else if Salud >= 50 then TKPICard(FKPISalud).ColorTone := kctAmbar
  else TKPICard(FKPISalud).ColorTone := kctRojo;

  // Caption con la etiqueta + nº de incidencias como pista.
  if Incidencias = 0 then
    TKPICard(FKPISalud).Caption := 'Salud del plan - ' + EtiquetaSalud(Salud)
  else
    TKPICard(FKPISalud).Caption := Format('Salud del plan - %d incidencias',
      [Incidencias]);

  // Registrar salud en el historico (para su sparkline) y pintar.
  UpsertMetricDia(['Salud'], [Salud]);
  SetKPI(FKPISalud, Salud, SerieKPI('Salud', Salud));
end;

procedure TfrmDashboard.SaludCardClick(Sender: TObject);
begin
  // La salud/alertas completas viven en la VistaGantt (motor con el Gantt vivo).
  // Abrir el Gantt es la accion natural: alli esta el dialogo de alertas.
  if Assigned(FOnAbrirGantt) then
    FOnAbrirGantt(Self);
end;

// Doble clic en una KPI card -> modal de detalle (drill-down): titulo, categoria,
// valor, grafico ampliado/anotado y descripcion ampliada del KPI.
procedure TfrmDashboard.CardDblClick(Sender: TObject);

  // Nombre de la columna del historico para la Key de la card.
  function ColumnaDe(const AKey: string): string;
  begin
    if AKey = 'Nodos' then Result := 'NodosPlanificados'
    else if AKey = 'OFsPlan' then Result := 'OFsEnPlan'
    else if AKey = 'OFsPend' then Result := 'OFsPendientes'
    else if AKey = 'OpAsig' then Result := 'OperariosAsignados'
    else if AKey = 'CargaH' then Result := 'CargaPlanificadaH'
    else if AKey = 'Saturacion' then Result := 'SaturacionMedia'
    else if AKey = 'OFsRiesgo' then Result := 'OFsEnRiesgo'
    else if AKey = 'StockOk' then Result := 'CoberturaStockOk'
    else if AKey = 'Rotura' then Result := 'RoturaStock'
    else Result := AKey;   // Salud, Otif, CuelloBotella, SatOperarios coinciden
  end;

var
  Card: TKPICard;
  Info: TKPIDetailInfo;
  Vals: TArray<Double>;
  Fechas: TArray<TDateTime>;
begin
  if not (Sender is TKPICard) then Exit;
  Card := TKPICard(Sender);

  Info := Default(TKPIDetailInfo);
  Info.Titulo := Card.Caption;
  Info.Categoria := Card.Categoria;
  Info.Descripcion := Card.Descripcion;
  Info.DescAmpliada := Card.DescAmpliada;
  Info.Unidad := Card.Unidad;
  Info.FormatStr := Card.FormatStr;
  Info.Value := Card.Value;
  Info.Tone := Card.Tone;

  if DemoMode.Active then
  begin
    // Demo: serie ficticia. El selector de periodo tambien funciona (regenera
    // la serie con mas/menos puntos y fechas ficticias hacia atras desde hoy).
    var KeyD: string := Card.Key;
    var ValD: Double := Card.Value;
    Info.RangoActual := FRangoDias;
    Info.Subtitulo := 'Datos de demostraci'#243'n - ' + SubtituloRango(FRangoDias);
    Info.OnCargarRango :=
      function(ADias: Integer): TKPIRangoData
      var
        DiasEf, K, I: Integer;
        Seed: Cardinal;   // sin signo: "Seed * 31" puede rebasar 2^31 (evita EIntOverflow con {$Q+})
      begin
        if ADias = RANGO_SEMANA then DiasEf := DayOfTheWeek(Date) else DiasEf := ADias;
        if DiasEf < 2 then DiasEf := 7;
        Seed := 0;
        for K := 1 to Length(KeyD) do Seed := (Seed * 31 + Cardinal(Ord(KeyD[K]))) and $7FFFFFFF;
        Result.Series := DemoSerieHaciaValor(ValD, DiasEf, 0.22, Integer(Seed));
        // Fechas ficticias: los ultimos DiasEf dias hasta hoy.
        SetLength(Result.Fechas, Length(Result.Series));
        for I := 0 to High(Result.Series) do
          Result.Fechas[I] := Date - (High(Result.Series) - I);
        Result.Subtitulo := 'Datos de demostraci'#243'n - ' + SubtituloRango(ADias);
      end;
    // Carga inicial con el rango actual.
    var D0 := Info.OnCargarRango(FRangoDias);
    Info.Series := D0.Series;
    Info.Fechas := D0.Fechas;
  end
  else
  begin
    // Real: serie + fechas del historico segun el periodo actual, y callback
    // para recargar cuando el usuario cambie el periodo DENTRO del modal.
    var Col: string := ColumnaDe(Card.Key);
    LoadMetricSerieFechas(Col, RangoDiasEfectivo, Vals, Fechas);
    Info.Series := Vals;
    Info.Fechas := Fechas;
    Info.RangoActual := FRangoDias;
    Info.Subtitulo := SubtituloRango(FRangoDias);
    Info.OnCargarRango :=
      function(ADias: Integer): TKPIRangoData
      var
        DiasEf: Integer;
      begin
        if ADias = RANGO_SEMANA then DiasEf := DayOfTheWeek(Date) else DiasEf := ADias;
        LoadMetricSerieFechas(Col, DiasEf, Result.Series, Result.Fechas);
        Result.Subtitulo := SubtituloRango(ADias);
      end;
  end;

  // Para la card de Salud, el modal ofrece abrir el Gantt (donde estan las
  // alertas completas). El resto no tiene accion extra.
  if Card.Key = 'Salud' then
  begin
    Info.AccionCaption := 'Ver alertas en el Gantt';
    Info.Accion := procedure begin SaludCardClick(nil); end;
  end;

  TfrmKPIDetail.Mostrar(Self, Info);
end;

// KPIs avanzados de valor para produccion, calculados por SQL:
//   OTIF          : % de OF que terminan dentro de su fecha de entrega.
//   Cuello botella: saturacion del centro MAS cargado (no la media, que diluye).
//   Sat. operarios: horas asignadas / jornada disponible de los operarios.
procedure TfrmDashboard.RefrescarKPIsAvanzados;
var
  Q: TADOQuery;
  CE, PID: string;
  Otif, SatOp, Cuello: Double;
  CuelloNombre: string;
  DiasPlan: Integer;
  FInicio, FFin: Variant;
begin
  if FKPIOtif = nil then Exit;

  if (not DMPlanner.IsConnected) or (DMPlanner.CurrentProjectId <= 0) then
  begin
    SetKPI(FKPIOtif, 0, SerieKPI('Otif', 0), '%');
    SetKPI(FKPICuelloBotella, 0, SerieKPI('CuelloBotella', 0), '%');
    SetKPI(FKPISatOperarios, 0, SerieKPI('SatOperarios', 0), '%');
    Exit;
  end;

  // ---- Modo DEMO: valores ficticios creibles (sin tocar BD). ----
  if DemoMode.Active then
  begin
    Otif := 91; SatOp := 78; Cuello := 94; CuelloNombre := 'Soldadura';
    TKPICard(FKPICuelloBotella).ColorTone := kctRojo;
    TKPICard(FKPICuelloBotella).Caption := 'Cuello: ' + CuelloNombre;
    TKPICard(FKPIOtif).ColorTone := kctAmbar;
    SetKPI(FKPIOtif,          Otif,   SerieKPI('Otif', Otif), '%');
    SetKPI(FKPICuelloBotella, Cuello, SerieKPI('CuelloBotella', Cuello), '%');
    SetKPI(FKPISatOperarios,  SatOp,  SerieKPI('SatOperarios', SatOp), '%');
    Exit;
  end;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(DMPlanner.CurrentProjectId);
  Otif := 0; SatOp := 0; Cuello := 0; CuelloNombre := '';

  // Rango de fechas del plan (para calcular jornada disponible).
  DiasPlan := 1;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT MIN(FechaInicio) AS FIni, MAX(FechaFin) AS FFin FROM FS_PL_Node ' +
      'WHERE CodigoEmpresa=' + CE + ' AND ProjectId=' + PID +
      '  AND FechaInicio IS NOT NULL';
    Q.Open;
    FInicio := Q.FieldByName('FIni').Value;
    FFin := Q.FieldByName('FFin').Value;
    if not (VarIsNull(FInicio) or VarIsNull(FFin)) then
      DiasPlan := Max(1, Trunc(VarToDateTime(FFin) - VarToDateTime(FInicio)) + 1);
  finally
    Q.Free;
  end;

  // ---- OTIF: % de OF a tiempo (FechaFin de la OF <= su FechaEntrega) ----
  // Una OF esta "a tiempo" si su ultima operacion termina en plazo. Agregamos
  // por NumeroOF: MAX(FechaFin) <= MAX(FechaEntrega) de esa OF.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ' +
      '  COUNT(*) AS TotalOF, ' +
      '  SUM(CASE WHEN UltimaFin <= FechaEnt THEN 1 ELSE 0 END) AS OFsATiempo ' +
      'FROM ( ' +
      '  SELECT nd.NumeroOF, MAX(n.FechaFin) AS UltimaFin, MAX(nd.FechaEntrega) AS FechaEnt ' +
      '  FROM FS_PL_Node n ' +
      '  INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa=n.CodigoEmpresa AND nd.NodeId=n.NodeId ' +
      '  WHERE n.CodigoEmpresa=' + CE + ' AND n.ProjectId=' + PID +
      '    AND nd.NumeroOF IS NOT NULL AND nd.FechaEntrega IS NOT NULL ' +
      '    AND n.FechaFin IS NOT NULL ' +
      '  GROUP BY nd.NumeroOF ' +
      ') t';
    Q.Open;
    var TotalOF: Integer := Q.FieldByName('TotalOF').AsInteger;
    if TotalOF > 0 then
      Otif := Q.FieldByName('OFsATiempo').AsInteger * 100.0 / TotalOF;
  finally
    Q.Free;
  end;

  // ---- Cuello de botella: centro con mas minutos planificados / disponibles ----
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    // Minutos por centro; disponible = DiasPlan * 8h * 60 (indicativo, ignora
    // calendarios reales, igual que la saturacion media existente).
    Q.SQL.Text :=
      'SELECT TOP 1 c.Titulo AS Centro, ' +
      '  SUM(n.DuracionMin) AS MinCarga ' +
      'FROM FS_PL_Node n ' +
      'INNER JOIN FS_PL_Center c ON c.CodigoEmpresa=n.CodigoEmpresa AND c.CenterId=n.CenterId ' +
      'WHERE n.CodigoEmpresa=' + CE + ' AND n.ProjectId=' + PID +
      '  AND n.CenterId IS NOT NULL AND n.FechaInicio IS NOT NULL ' +
      'GROUP BY c.CenterId, c.Titulo ' +
      'ORDER BY SUM(n.DuracionMin) DESC';
    Q.Open;
    if not Q.Eof then
    begin
      CuelloNombre := Q.FieldByName('Centro').AsString;
      var MinDisp: Double := DiasPlan * 8.0 * 60.0;
      if MinDisp > 0 then
        Cuello := Min(100, Q.FieldByName('MinCarga').AsFloat / MinDisp * 100);
    end;
  finally
    Q.Free;
  end;

  // ---- Saturacion de operarios: horas asignadas / jornada disponible ----
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT COUNT(DISTINCT oa.OperatorId) AS NumOp, ' +
      '  ISNULL(SUM(oa.Horas),0) AS HorasTot ' +
      'FROM FS_PL_OperatorAssignment oa ' +
      'INNER JOIN FS_PL_Node n ON n.CodigoEmpresa=oa.CodigoEmpresa AND n.NodeId=oa.NodeId ' +
      'WHERE n.CodigoEmpresa=' + CE + ' AND n.ProjectId=' + PID;
    Q.Open;
    var NumOp: Integer := Q.FieldByName('NumOp').AsInteger;
    var HorasTot: Double := Q.FieldByName('HorasTot').AsFloat;
    if NumOp > 0 then
    begin
      var HorasDisp: Double := NumOp * DiasPlan * 8.0;   // 8h/dia
      if HorasDisp > 0 then
        SatOp := Min(100, HorasTot / HorasDisp * 100);
    end;
  finally
    Q.Free;
  end;

  // Tono semaforo para cuello de botella y saturacion (rojo si muy alto).
  if Cuello >= 90 then TKPICard(FKPICuelloBotella).ColorTone := kctRojo
  else if Cuello >= 70 then TKPICard(FKPICuelloBotella).ColorTone := kctAmbar
  else TKPICard(FKPICuelloBotella).ColorTone := kctVerde;
  if CuelloNombre <> '' then
    TKPICard(FKPICuelloBotella).Caption := 'Cuello: ' + CuelloNombre;

  // OTIF: verde alto, rojo bajo (al reves que saturacion).
  if Otif >= 95 then TKPICard(FKPIOtif).ColorTone := kctVerde
  else if Otif >= 80 then TKPICard(FKPIOtif).ColorTone := kctAmbar
  else TKPICard(FKPIOtif).ColorTone := kctRojo;

  // Registrar en el historico y pintar.
  UpsertMetricDia(['Otif', 'CuelloBotella', 'SatOperarios'],
    [Otif, Cuello, SatOp]);
  SetKPI(FKPIOtif,          Otif,   SerieKPI('Otif', Otif), '%');
  SetKPI(FKPICuelloBotella, Cuello, SerieKPI('CuelloBotella', Cuello), '%');
  SetKPI(FKPISatOperarios,  SatOp,  SerieKPI('SatOperarios', SatOp), '%');
end;

procedure TfrmDashboard.RefrescarKPIsStock;
var
  StockOk, Rotura: Double;
begin
  if FKPIStockOk = nil then Exit;

  // ---- Modo DEMO: cobertura de material ficticia y coherente. ----
  // % con stock suficiente + % con rotura suman 100. Escenario "buen plan con
  // algunas roturas por resolver" (lo que un jefe de compras querria ver).
  if DemoMode.Active then
  begin
    StockOk := 86;
    Rotura := 100 - StockOk;   // 14
    // Restaurar formato numerico (un refresco real previo pudo dejar 'N/D').
    TKPICard(FKPIStockOk).FormatStr := '%.0f';
    TKPICard(FKPIRotura).FormatStr := '%.0f';
    TKPICard(FKPIStockOk).ColorTone := kctVerde;
    TKPICard(FKPIRotura).ColorTone := kctRojo;
    SetKPI(FKPIStockOk, StockOk, SerieKPI('StockOk', StockOk), '%');
    SetKPI(FKPIRotura,  Rotura,  SerieKPI('Rotura',  Rotura),  '%');
    Exit;
  end;

  // ---- Real: calculo PENDIENTE (requiere explotar escandallo + proyeccion de
  // stock por componente, coste alto). De momento mostramos N/D en gris para no
  // dar un numero falso. El KPI queda registrado en el catalogo y listo para
  // conectar el calculo real cuando se implemente. Truco: FormatStr sin '%f'
  // hace que Format() ignore el valor y pinte el literal 'N/D'.
  TKPICard(FKPIStockOk).ColorTone := kctNeutro;
  TKPICard(FKPIRotura).ColorTone := kctNeutro;
  TKPICard(FKPIStockOk).Unidad := '';
  TKPICard(FKPIRotura).Unidad := '';
  TKPICard(FKPIStockOk).FormatStr := 'N/D';
  TKPICard(FKPIStockOk).SetValueAndSeries(0, []);
  TKPICard(FKPIRotura).FormatStr := 'N/D';
  TKPICard(FKPIRotura).SetValueAndSeries(0, []);
end;

procedure TfrmDashboard.lblPendingSyncClick(Sender: TObject);
begin
  ShowBacklog;
  Refrescar;
end;
procedure TfrmDashboard.lblValCalendariosClick(Sender: TObject);
begin
  TfrmGestionCalendarios.Execute(YearOf(Now));
  DMPlanner.LoadCalendars;
  Refrescar;
end;
procedure TfrmDashboard.lblValCentrosClick(Sender: TObject);
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
  Refrescar;
end;
procedure TfrmDashboard.lblValAreasClick(Sender: TObject);
var
  Frm: TfrmGestionAreas;
begin
  Frm := TfrmGestionAreas.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  Refrescar;
end;
procedure TfrmDashboard.lblValDepartamentosClick(Sender: TObject);
var
  Frm: TfrmGestionDepartamentos;
begin
  Frm := TfrmGestionDepartamentos.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  Refrescar;
end;
procedure TfrmDashboard.lblValTurnosClick(Sender: TObject);
begin
  TfrmGestionTurnos.Execute;
  Refrescar;
end;
procedure TfrmDashboard.lblValCapacitacionesClick(Sender: TObject);
var
  Frm: TfrmGestionCapacitaciones;
begin
  Frm := TfrmGestionCapacitaciones.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  Refrescar;
end;
procedure TfrmDashboard.lblValOperariosClick(Sender: TObject);
var
  Frm: TfrmGestionOperaris;
begin
  Frm := TfrmGestionOperaris.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  Refrescar;
end;
end.
