unit uErpExplorer;

// ============================================================================
// Explorador ERP: form unic de configuracio i diagnostic de qualsevol ERP
// integrat al planner. Funciona contra IErpReader (uErpReaderFactory), aixi
// que el codi del form NO depen del ERP concret.
//
// Dues pestanyes:
//   - Configuracion: parametres de connexio i empresa (avui Sage 200; futurs
//                    ERPs reutilitzaran el mateix patro adaptant els camps).
//   - Explorador:    llista d'entitats a l'esquerra, panell de parametres
//                    (si l'entitat ho requereix), grid din'amic via RTTI i
//                    memo de log.
// ============================================================================

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.DateUtils,
  System.Generics.Collections,
  Winapi.Windows, Winapi.Messages,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Data.DB, Datasnap.DBClient,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, dxCore,
  cxGridLevel, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxClasses, cxGridCustomView, cxGrid, cxPC, cxSpinEdit, cxMaskEdit,
  uAppConfig, uErpReader, uErpTypes, dxSkinsCore, dxSkinBasic, dxSkinBlack,
  dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
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
  dxSkinXmas2008Blue, cxDBData, dxBarBuiltInMenu, cxContainer, cxTextEdit;

type
  TEntidadExplorador = (
    eeEmpresas,
    eeArticulos,
    eeFamilias,
    eeClientes,
    eeAlmacenes,
    eeCentrosTrabajo,
    eeMaquinas,
    eeOperarios,
    eeCentrosMaquinas,
    eeGruposHorarios,
    eeModelosHorarios,
    eeLineasModeloHorario,
    eeCalendarioCentro,
    eeOrdenesFabricacion,
    eeOrdenesTrabajo,
    eeOperacionesOT,
    eeConsumosOT,
    eeRelacionOTOF,
    eeProyectos,
    eeTareasProyecto,
    eePedidoCabecera,
    eePedidoLineas,
    eeFormulaVersiones,
    eeFormulaCabecera,
    eeFormulaComponentes,
    eeFormulaOperaciones,
    eeStockArticulo,
    eeStockDisponible,
    eeEntradasFuturas
  );

  TParametrosNecesarios = set of (pnSerieNumeroEjercicio, pnCodigoArticulo,
                                  pnCodigoArticuloVersion, pnFiltroCodigo,
                                  pnIdNumerico, pnRangoFechas);

  TEntidadInfo = record
    Caption: string;
    Parametros: TParametrosNecesarios;
  end;

  TfrmErpExplorer = class(TForm)
    pgcMain: TcxPageControl;
    tabConfiguracion: TcxTabSheet;
    tabExplorador: TcxTabSheet;
    pnlBotones: TPanel;
    btnGuardar: TButton;
    btnCerrar: TButton;

    // --- Configuracion ---
    pnlErpActivo: TPanel;
    lblErpActivo: TLabel;
    pgcErpConfig: TcxPageControl;
    tabSage200: TcxTabSheet;
    tabErpProximamente: TcxTabSheet;
    lblProximamente: TLabel;
    pnlConexion: TGroupBox;
    lblServer: TLabel;
    lblDatabase: TLabel;
    lblUserName: TLabel;
    lblPassword: TLabel;
    edServer: TEdit;
    edDatabase: TEdit;
    chkWindowsAuth: TCheckBox;
    edUserName: TEdit;
    edPassword: TEdit;

    pnlEmpresa: TGroupBox;
    lblCodigoEmpresa: TLabel;
    lblEjercicio: TLabel;
    cmbCodigoEmpresa: TComboBox;
    btnCargarEmpresas: TButton;
    edEjercicio: TEdit;

    pnlPruebaConexion: TPanel;
    btnProbarConexion: TButton;
    lblResultadoConexion: TLabel;

    // --- Explorador ---
    pnlEntidades: TPanel;
    lblEntidades: TLabel;
    lstEntidades: TListBox;
    pnlExploradorDerecho: TPanel;
    pnlParametros: TPanel;
    pnlBotonesLeer: TPanel;
    btnLeer: TButton;
    btnLimpiar: TButton;
    pgcParametros: TcxPageControl;
    tabParamNinguno: TcxTabSheet;
    tabParamSerieNumEj: TcxTabSheet;
    lblSerie: TLabel;
    edSerie: TEdit;
    lblNumero: TLabel;
    edNumero: TEdit;
    lblEjercicioP: TLabel;
    edEjercicioP: TEdit;
    tabParamArtVer: TcxTabSheet;
    lblArticulo: TLabel;
    edArticulo: TEdit;
    lblVersion: TLabel;
    edVersion: TEdit;
    lblEjercicioStock: TLabel;
    seEjercicioStock: TcxSpinEdit;
    tabParamFiltro: TcxTabSheet;
    lblFiltro: TLabel;
    edFiltro: TEdit;
    tabParamIdNum: TcxTabSheet;
    lblIdNum: TLabel;
    edIdNum: TEdit;
    tabParamFiltroFechas: TcxTabSheet;
    lblFiltro2: TLabel;
    edFiltro2: TEdit;
    lblFechaDesde: TLabel;
    dtFechaDesde: TDateTimePicker;
    lblFechaHasta: TLabel;
    dtFechaHasta: TDateTimePicker;
    splitVertical: TSplitter;
    grdResultados: TcxGrid;
    grdResultadosView: TcxGridDBTableView;
    grdResultadosLevel: TcxGridLevel;
    mmoLog: TMemo;
    pnlGridYMemo: TPanel;
    splitGridMemo: TSplitter;
    dsResultados: TDataSource;
    cdsResultados: TClientDataSet;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure chkWindowsAuthClick(Sender: TObject);
    procedure btnProbarConexionClick(Sender: TObject);
    procedure btnCargarEmpresasClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure lstEntidadesClick(Sender: TObject);
    procedure btnLeerClick(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
  private
    procedure CargarEnControles(const ACfg: TErpSage200Config);
    function LeerDeControles: TErpSage200Config;
    procedure ActualizarHabilitacionAuth;
    function BuildConnectionString(const ACfg: TErpSage200Config): string;
    procedure SetResultadoConexion(const AMsg: string; AColor: TColor);
    procedure AplicarErpActivo;
    function MostrarCargando(const AMsg: string): TForm;
    procedure OcultarCargando(var AFrm: TForm);
    procedure LlenarListaEntidades;
    function EntidadActual: TEntidadExplorador;
    function InfoEntidad(AEntidad: TEntidadExplorador): TEntidadInfo;
    procedure AjustarParametros;
    function CrearReader: IErpReader;
    procedure LogInfo(const AMsg: string);
    procedure LogError(const AMsg: string);
    procedure LogResultado(const AEntidad: string; ACount: Integer; AMs: Int64);
    procedure LeerEmpresas(AReader: IErpReader);
    procedure LeerArticulos(AReader: IErpReader);
    procedure LeerCentros(AReader: IErpReader);
    procedure LeerMaquinas(AReader: IErpReader);
    procedure LeerOperarios(AReader: IErpReader);
    procedure LeerCentrosMaquinas(AReader: IErpReader);
    procedure LeerGruposHorarios(AReader: IErpReader);
    procedure LeerModelosHorarios(AReader: IErpReader);
    procedure LeerLineasModeloHorario(AReader: IErpReader);
    procedure LeerCalendarioCentro(AReader: IErpReader);
    procedure LeerFamilias(AReader: IErpReader);
    procedure LeerClientes(AReader: IErpReader);
    procedure LeerAlmacenes(AReader: IErpReader);
    procedure LeerOrdenesFabricacion(AReader: IErpReader);
    procedure LeerOrdenesTrabajo(AReader: IErpReader);
    procedure LeerOperacionesOT(AReader: IErpReader);
    procedure LeerConsumosOT(AReader: IErpReader);
    procedure LeerRelacionOTOF(AReader: IErpReader);
    procedure LeerProyectos(AReader: IErpReader);
    procedure LeerTareasProyecto(AReader: IErpReader);
    procedure LeerPedidoCabecera(AReader: IErpReader);
    procedure LeerPedidoLineas(AReader: IErpReader);
    procedure LeerFormulaVersiones(AReader: IErpReader);
    procedure LeerFormulaCabecera(AReader: IErpReader);
    procedure LeerFormulaComponentes(AReader: IErpReader);
    procedure LeerFormulaOperaciones(AReader: IErpReader);
    procedure LeerStockArticulo(AReader: IErpReader);
    procedure LeerStockDisponible(AReader: IErpReader);
    procedure LeerEntradasFuturas(AReader: IErpReader);
  public
    class function Execute: Boolean;
  end;

implementation

uses
  System.Diagnostics,
  Data.Win.ADODB,
  uSage200Reader, uRttiGridFiller;

{$R *.dfm}

const
  MAX_COLUMN_WIDTH = 300;

  ENTIDAD_INFO: array[TEntidadExplorador] of TEntidadInfo = (
    (Caption: 'Empresas';                  Parametros: []),
    (Caption: 'Art'#237'culos';                 Parametros: [pnFiltroCodigo]),
    (Caption: 'Familias / Subfamilias';    Parametros: []),
    (Caption: 'Clientes';                  Parametros: [pnFiltroCodigo]),
    (Caption: 'Almacenes';                 Parametros: []),
    (Caption: 'Centros de trabajo';        Parametros: []),
    (Caption: 'M'#225'quinas';                  Parametros: []),
    (Caption: 'Operarios';                 Parametros: []),
    (Caption: 'Centros x M'#225'quinas';        Parametros: [pnFiltroCodigo]),
    (Caption: 'Grupos horarios';           Parametros: []),
    (Caption: 'Modelos horarios';          Parametros: []),
    (Caption: 'L'#237'neas modelo horario';      Parametros: [pnIdNumerico]),
    (Caption: 'Calendario centro';         Parametros: [pnFiltroCodigo, pnRangoFechas]),
    (Caption: 'OFs (cabecera)';            Parametros: [pnSerieNumeroEjercicio]),
    (Caption: 'OTs';                       Parametros: [pnSerieNumeroEjercicio]),
    (Caption: 'Operaciones OT';            Parametros: [pnSerieNumeroEjercicio]),
    (Caption: 'Consumos OT';               Parametros: [pnSerieNumeroEjercicio]),
    (Caption: 'Relaci'#243'n OT<->OF';          Parametros: [pnSerieNumeroEjercicio]),
    (Caption: 'Proyectos';                 Parametros: [pnFiltroCodigo]),
    (Caption: 'Tareas de proyecto';        Parametros: [pnFiltroCodigo]),
    (Caption: 'Pedido (cabecera)';         Parametros: [pnSerieNumeroEjercicio]),
    (Caption: 'Pedido (l'#237'neas)';            Parametros: [pnSerieNumeroEjercicio]),
    (Caption: 'F'#243'rmula - versiones';       Parametros: [pnCodigoArticulo]),
    (Caption: 'F'#243'rmula - cabecera';        Parametros: [pnCodigoArticulo]),
    (Caption: 'F'#243'rmula - componentes';     Parametros: [pnCodigoArticuloVersion]),
    (Caption: 'F'#243'rmula - operaciones';     Parametros: [pnCodigoArticuloVersion]),
    (Caption: 'Stock por partida';         Parametros: [pnCodigoArticulo]),
    (Caption: 'Stock disponible (MRP)';    Parametros: [pnCodigoArticulo]),
    (Caption: 'Entradas futuras (compras)'; Parametros: [pnFiltroCodigo, pnRangoFechas])
  );

class function TfrmErpExplorer.Execute: Boolean;
var
  Frm: TfrmErpExplorer;
begin
  Frm := TfrmErpExplorer.Create(nil);
  try
    Result := Frm.ShowModal = mrOk;
  finally
    Frm.Free;
  end;
end;

procedure TfrmErpExplorer.FormCreate(Sender: TObject);
begin
  dtFechaDesde.Date := StartOfTheMonth(Now);
  dtFechaHasta.Date := EndOfTheMonth(Now);
  CargarEnControles(LoadErpSage200Config);
  ActualizarHabilitacionAuth;
  LlenarListaEntidades;
  AjustarParametros;
  AplicarErpActivo;
  pgcMain.ActivePageIndex := 0;
end;

procedure TfrmErpExplorer.AplicarErpActivo;
var
  Codigo: string;
  Sis: TErpSistema;
  Info: TErpSistemaInfo;
  EsSage200: Boolean;
begin
  Codigo := LoadErpActivo;
  Info := Default(TErpSistemaInfo);
  Info.Nombre := 'Ninguno';
  Info.Disponible := False;
  for Sis := Low(TErpSistema) to High(TErpSistema) do
    if SameText(ERP_SISTEMAS[Sis].Codigo, Codigo) then
    begin
      Info := ERP_SISTEMAS[Sis];
      Break;
    end;

  EsSage200 := SameText(Codigo, 'Sage200');

  if Codigo = '' then
    lblErpActivo.Caption := 'ERP activo: ninguno configurado'
  else if Info.Disponible then
    lblErpActivo.Caption := 'ERP activo: ' + Info.Nombre
  else
    lblErpActivo.Caption := 'ERP activo: ' + Info.Nombre + ' (no implementado)';

  if EsSage200 then
    pgcErpConfig.ActivePage := tabSage200
  else
    pgcErpConfig.ActivePage := tabErpProximamente;

  // Inhabilita botones que solo aplican al unico ERP soportado hoy.
  btnProbarConexion.Enabled := EsSage200;
  btnCargarEmpresas.Enabled := EsSage200;
end;

procedure TfrmErpExplorer.FormDestroy(Sender: TObject);
begin
  if cdsResultados.Active then
    cdsResultados.Close;
end;

procedure TfrmErpExplorer.CargarEnControles(const ACfg: TErpSage200Config);
begin
  edServer.Text          := ACfg.Server;
  edDatabase.Text        := ACfg.Database;
  chkWindowsAuth.Checked := ACfg.WindowsAuth;
  edUserName.Text        := ACfg.UserName;
  edPassword.Text        := ACfg.Password;
  cmbCodigoEmpresa.Text  := ACfg.CodigoEmpresa;
  if ACfg.Ejercicio > 0 then
    edEjercicio.Text := IntToStr(ACfg.Ejercicio)
  else
    edEjercicio.Text := IntToStr(YearOf(Now));
end;

function TfrmErpExplorer.LeerDeControles: TErpSage200Config;
begin
  Result := Default(TErpSage200Config);
  Result.Server        := Trim(edServer.Text);
  Result.Database      := Trim(edDatabase.Text);
  Result.WindowsAuth   := chkWindowsAuth.Checked;
  Result.UserName      := Trim(edUserName.Text);
  Result.Password      := edPassword.Text;
  Result.CodigoEmpresa := Trim(cmbCodigoEmpresa.Text);
  Result.Ejercicio     := StrToIntDef(edEjercicio.Text, YearOf(Now));
end;

procedure TfrmErpExplorer.ActualizarHabilitacionAuth;
begin
  edUserName.Enabled := not chkWindowsAuth.Checked;
  edPassword.Enabled := not chkWindowsAuth.Checked;
end;

procedure TfrmErpExplorer.chkWindowsAuthClick(Sender: TObject);
begin
  ActualizarHabilitacionAuth;
end;

function TfrmErpExplorer.BuildConnectionString(
  const ACfg: TErpSage200Config): string;
begin
  if ACfg.WindowsAuth then
    Result := Format(
      'Provider=SQLOLEDB.1;Data Source=%s;Initial Catalog=%s;' +
      'Integrated Security=SSPI;',
      [ACfg.Server, ACfg.Database])
  else
    Result := Format(
      'Provider=SQLOLEDB.1;Data Source=%s;Initial Catalog=%s;' +
      'User ID=%s;Password=%s;',
      [ACfg.Server, ACfg.Database, ACfg.UserName, ACfg.Password]);
end;

procedure TfrmErpExplorer.SetResultadoConexion(const AMsg: string;
  AColor: TColor);
begin
  lblResultadoConexion.Font.Color := AColor;
  lblResultadoConexion.Caption := AMsg;
  Application.ProcessMessages;
end;

procedure TfrmErpExplorer.btnProbarConexionClick(Sender: TObject);
var
  Cfg: TErpSage200Config;
  Conn: TADOConnection;
begin
  Cfg := LeerDeControles;
  if not Cfg.IsValid then
  begin
    SetResultadoConexion('Faltan datos de conexi'#243'n.', clRed);
    Exit;
  end;

  SetResultadoConexion('Probando conexi'#243'n...', clBlue);
  Conn := TADOConnection.Create(nil);
  try
    Conn.LoginPrompt := False;
    Conn.ConnectionString := BuildConnectionString(Cfg);
    try
      Conn.Connected := True;
      SetResultadoConexion('Conexi'#243'n SQL correcta.', clGreen);
    except
      on E: Exception do
        SetResultadoConexion('Error: ' + E.Message, clRed);
    end;
  finally
    Conn.Free;
  end;
end;

procedure TfrmErpExplorer.btnCargarEmpresasClick(Sender: TObject);
var
  Cfg: TErpSage200Config;
  Reader: IErpReader;
  Empresas: TArray<TEmpresaErp>;
  CodigoActual: string;
  i: Integer;
begin
  Cfg := LeerDeControles;
  if not Cfg.IsValid then
  begin
    SetResultadoConexion('Faltan datos de conexi'#243'n.', clRed);
    Exit;
  end;

  CodigoActual := cmbCodigoEmpresa.Text;
  SetResultadoConexion('Cargando empresas...', clBlue);

  try
    Reader := TSage200Reader.Create(Cfg);
    Empresas := Reader.ReadEmpresas;
  except
    on E: Exception do
    begin
      SetResultadoConexion('Error: ' + E.Message, clRed);
      Exit;
    end;
  end;

  cmbCodigoEmpresa.Items.BeginUpdate;
  try
    cmbCodigoEmpresa.Items.Clear;
    for i := 0 to High(Empresas) do
      cmbCodigoEmpresa.Items.Add(
        Format('%d - %s', [Empresas[i].Codigo, Empresas[i].Nombre]));
  finally
    cmbCodigoEmpresa.Items.EndUpdate;
  end;
  if CodigoActual <> '' then
    cmbCodigoEmpresa.Text := CodigoActual;
  SetResultadoConexion(
    Format('Cargadas %d empresas.', [Length(Empresas)]), clGreen);
end;

procedure TfrmErpExplorer.btnGuardarClick(Sender: TObject);
var
  Cfg: TErpSage200Config;
begin
  Cfg := LeerDeControles;
  if not Cfg.IsValid then
  begin
    ShowMessage('Faltan datos de conexi'#243'n SQL (servidor, base de datos y, ' +
      'si no es autenticaci'#243'n Windows, el usuario).');
    Exit;
  end;
  SaveErpSage200Config(Cfg);
  ModalResult := mrOk;
end;

procedure TfrmErpExplorer.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

// ---------------------------------------------------------------------------
// EXPLORADOR
// ---------------------------------------------------------------------------

procedure TfrmErpExplorer.LlenarListaEntidades;
var
  E: TEntidadExplorador;
begin
  lstEntidades.Items.BeginUpdate;
  try
    lstEntidades.Items.Clear;
    for E := Low(TEntidadExplorador) to High(TEntidadExplorador) do
      lstEntidades.Items.Add(ENTIDAD_INFO[E].Caption);
  finally
    lstEntidades.Items.EndUpdate;
  end;
  lstEntidades.ItemIndex := 0;
end;

function TfrmErpExplorer.EntidadActual: TEntidadExplorador;
begin
  if lstEntidades.ItemIndex < 0 then
    Result := eeEmpresas
  else
    Result := TEntidadExplorador(lstEntidades.ItemIndex);
end;

function TfrmErpExplorer.InfoEntidad(AEntidad: TEntidadExplorador): TEntidadInfo;
begin
  Result := ENTIDAD_INFO[AEntidad];
end;

procedure TfrmErpExplorer.AjustarParametros;
var
  Info: TEntidadInfo;
  TabIdx: Integer;
begin
  Info := InfoEntidad(EntidadActual);

  // Cada combinacio de parametres mapea a un tab del PageControl
  if pnSerieNumeroEjercicio in Info.Parametros then
    TabIdx := tabParamSerieNumEj.PageIndex
  else if (pnCodigoArticulo in Info.Parametros) or
          (pnCodigoArticuloVersion in Info.Parametros) then
    TabIdx := tabParamArtVer.PageIndex
  else if (pnFiltroCodigo in Info.Parametros) and (pnRangoFechas in Info.Parametros) then
    TabIdx := tabParamFiltroFechas.PageIndex
  else if pnFiltroCodigo in Info.Parametros then
    TabIdx := tabParamFiltro.PageIndex
  else if pnIdNumerico in Info.Parametros then
    TabIdx := tabParamIdNum.PageIndex
  else
    TabIdx := tabParamNinguno.PageIndex;

  pgcParametros.ActivePageIndex := TabIdx;

  // Al tab ArtVer, el segon camp es reutilitza com a Versi'on (Formula) o
  // Partida (Stock). El SpinEdit Ejercicio nomes es visible per Stock.
  if TabIdx = tabParamArtVer.PageIndex then
  begin
    case EntidadActual of
      eeStockArticulo:
        begin
          lblVersion.Caption := 'Partida:';
          edVersion.NumbersOnly := False;
          lblEjercicioStock.Visible := True;
          seEjercicioStock.Visible := True;
          if seEjercicioStock.Value = 0 then
            seEjercicioStock.Value := YearOf(Now);
        end;
      eeStockDisponible:
        begin
          // AcumuladoStock_Neco no te Ejercicio (estat actual): camp ocult.
          lblVersion.Caption := 'Partida:';
          edVersion.NumbersOnly := False;
          lblEjercicioStock.Visible := False;
          seEjercicioStock.Visible := False;
        end;
    else
      lblVersion.Caption := 'Versi'#243'n:';
      edVersion.NumbersOnly := True;
      lblEjercicioStock.Visible := False;
      seEjercicioStock.Visible := False;
    end;
  end;

  // Al tab FiltroFechas, el camp text es Centro (calendari) o C'odigo
  // d'article (entrades futures). Adaptem label segons entitat.
  if TabIdx = tabParamFiltroFechas.PageIndex then
  begin
    case EntidadActual of
      eeEntradasFuturas:
        begin
          lblFiltro2.Caption := 'C'#243'd. art'#237'culo:';
          edFiltro2.TextHint := 'Vac'#237'o = todos los art'#237'culos';
        end;
    else
      lblFiltro2.Caption := 'Centro (filtro):';
      edFiltro2.TextHint := 'Vac'#237'o = todos los centros';
    end;
  end;

  if (pnSerieNumeroEjercicio in Info.Parametros) and (Trim(edEjercicioP.Text) = '') then
    edEjercicioP.Text := IntToStr(YearOf(Now));
end;

procedure TfrmErpExplorer.lstEntidadesClick(Sender: TObject);
begin
  AjustarParametros;
end;

function TfrmErpExplorer.CrearReader: IErpReader;
var
  Cfg: TErpSage200Config;
begin
  Cfg := LeerDeControles;
  if not Cfg.IsValid then
    raise Exception.Create('Faltan datos de conexi'#243'n. Revisa la pesta'#241'a Configuraci'#243'n.');
  if Trim(Cfg.CodigoEmpresa) = '' then
    raise Exception.Create('Selecciona primero una empresa.');
  Result := TSage200Reader.Create(Cfg);
end;

procedure TfrmErpExplorer.LogInfo(const AMsg: string);
begin
  mmoLog.Lines.Add(Format('[%s] %s',
    [FormatDateTime('hh:nn:ss', Now), AMsg]));
end;

procedure TfrmErpExplorer.LogError(const AMsg: string);
begin
  mmoLog.Lines.Add(Format('[%s] ERROR: %s',
    [FormatDateTime('hh:nn:ss', Now), AMsg]));
end;

procedure TfrmErpExplorer.LogResultado(const AEntidad: string; ACount: Integer;
  AMs: Int64);
begin
  LogInfo(Format('%s -> %d registros (%d ms)', [AEntidad, ACount, AMs]));
end;

procedure TfrmErpExplorer.btnLimpiarClick(Sender: TObject);
begin
  mmoLog.Lines.Clear;
  grdResultadosView.BeginUpdate;
  try
    grdResultadosView.ClearItems;
    grdResultadosView.DataController.DataSource.DataSet := nil;
  finally
    grdResultadosView.EndUpdate;
  end;
  if cdsResultados.Active then
    cdsResultados.Close;
  cdsResultados.FieldDefs.Clear;
  cdsResultados.Fields.Clear;
end;

function TfrmErpExplorer.MostrarCargando(const AMsg: string): TForm;
var
  Pnl: TPanel;
  Lbl: TLabel;
begin
  Result := TForm.Create(Self);
  Result.BorderStyle := bsNone;
  Result.FormStyle := fsStayOnTop;
  Result.Position := poOwnerFormCenter;
  Result.Width := 320;
  Result.Height := 90;
  Result.Color := clBtnFace;
  Pnl := TPanel.Create(Result);
  Pnl.Parent := Result;
  Pnl.Align := alClient;
  Pnl.BevelOuter := bvLowered;
  Pnl.BevelInner := bvRaised;
  Lbl := TLabel.Create(Result);
  Lbl.Parent := Pnl;
  Lbl.Align := alClient;
  Lbl.Alignment := taCenter;
  Lbl.Layout := tlCenter;
  Lbl.Caption := AMsg;
  Lbl.Font.Size := 11;
  Lbl.Font.Style := [fsBold];
  Result.Show;
  Application.ProcessMessages;
end;

procedure TfrmErpExplorer.OcultarCargando(var AFrm: TForm);
begin
  if AFrm <> nil then
  begin
    AFrm.Close;
    FreeAndNil(AFrm);
  end;
end;

procedure TfrmErpExplorer.btnLeerClick(Sender: TObject);
var
  Reader: IErpReader;
  FrmCargando: TForm;
begin
  try
    Reader := CrearReader;
  except
    on E: Exception do
    begin
      LogError(E.Message);
      Exit;
    end;
  end;

  Screen.Cursor := crHourGlass;
  FrmCargando := MostrarCargando('Cargando ' +
    InfoEntidad(EntidadActual).Caption + '...');
  try
    try
      case EntidadActual of
        eeEmpresas:             LeerEmpresas(Reader);
        eeArticulos:            LeerArticulos(Reader);
        eeCentrosTrabajo:       LeerCentros(Reader);
        eeMaquinas:             LeerMaquinas(Reader);
        eeOperarios:            LeerOperarios(Reader);
        eeCentrosMaquinas:      LeerCentrosMaquinas(Reader);
        eeGruposHorarios:       LeerGruposHorarios(Reader);
        eeModelosHorarios:      LeerModelosHorarios(Reader);
        eeLineasModeloHorario:  LeerLineasModeloHorario(Reader);
        eeCalendarioCentro:     LeerCalendarioCentro(Reader);
        eeFamilias:             LeerFamilias(Reader);
        eeClientes:             LeerClientes(Reader);
        eeAlmacenes:            LeerAlmacenes(Reader);
        eeOrdenesFabricacion:   LeerOrdenesFabricacion(Reader);
        eeOrdenesTrabajo:       LeerOrdenesTrabajo(Reader);
        eeOperacionesOT:        LeerOperacionesOT(Reader);
        eeConsumosOT:           LeerConsumosOT(Reader);
        eeRelacionOTOF:         LeerRelacionOTOF(Reader);
        eeProyectos:            LeerProyectos(Reader);
        eeTareasProyecto:       LeerTareasProyecto(Reader);
        eePedidoCabecera:       LeerPedidoCabecera(Reader);
        eePedidoLineas:         LeerPedidoLineas(Reader);
        eeFormulaVersiones:     LeerFormulaVersiones(Reader);
        eeFormulaCabecera:      LeerFormulaCabecera(Reader);
        eeFormulaComponentes:   LeerFormulaComponentes(Reader);
        eeFormulaOperaciones:   LeerFormulaOperaciones(Reader);
        eeStockArticulo:        LeerStockArticulo(Reader);
        eeStockDisponible:      LeerStockDisponible(Reader);
        eeEntradasFuturas:      LeerEntradasFuturas(Reader);
      end;
    except
      on E: Exception do
        LogError(E.Message);
    end;
  finally
    OcultarCargando(FrmCargando);
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmErpExplorer.LeerEmpresas(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TEmpresaErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadEmpresas;
  SW.Stop;
  TRttiGridFiller.Fill<TEmpresaErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Empresas', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerArticulos(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TArticuloErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadArticulos(Trim(edFiltro.Text));
  SW.Stop;
  TRttiGridFiller.Fill<TArticuloErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Art'#237'culos', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerCentros(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TCentroTrabajoErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadCentrosTrabajo;
  SW.Stop;
  TRttiGridFiller.Fill<TCentroTrabajoErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Centros de trabajo', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerMaquinas(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TMaquinaErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadMaquinas;
  SW.Stop;
  TRttiGridFiller.Fill<TMaquinaErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('M'#225'quinas', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerOperarios(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TOperarioErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadOperarios;
  SW.Stop;
  TRttiGridFiller.Fill<TOperarioErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Operarios', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerCentrosMaquinas(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TCentroMaquinaErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadCentrosMaquinas(Trim(edFiltro.Text));
  SW.Stop;
  TRttiGridFiller.Fill<TCentroMaquinaErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Centros x M'#225'quinas', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerGruposHorarios(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TGrupoHorarioErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadGruposHorarios;
  SW.Stop;
  TRttiGridFiller.Fill<TGrupoHorarioErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Grupos horarios', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerModelosHorarios(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TModeloHorarioErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadModelosHorarios;
  SW.Stop;
  TRttiGridFiller.Fill<TModeloHorarioErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Modelos horarios', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerLineasModeloHorario(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TLineaModeloHorarioErp>;
  Modelo: Integer;
begin
  Modelo := StrToIntDef(edIdNum.Text, 0);
  if Modelo <= 0 then
  begin
    LogError('Indica el ID del modelo horario.');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadLineasModeloHorario(Modelo);
  SW.Stop;
  TRttiGridFiller.Fill<TLineaModeloHorarioErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('L'#237'neas modelo horario', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerCalendarioCentro(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TCalendarioCentroErp>;
  Centro: string;
  FD, FH: TDateTime;
begin
  Centro := Trim(edFiltro2.Text);
  FD := dtFechaDesde.Date;
  FH := dtFechaHasta.Date;
  if (FD = 0) or (FH = 0) then
  begin
    LogError('Indica rango de fechas.');
    Exit;
  end;
  if FD > FH then
  begin
    LogError('Fecha desde > fecha hasta.');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadCalendarioCentro(Centro, FD, FH);
  SW.Stop;
  TRttiGridFiller.Fill<TCalendarioCentroErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Calendario centro', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerFamilias(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TFamiliaErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadFamilias;
  SW.Stop;
  TRttiGridFiller.Fill<TFamiliaErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Familias', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerClientes(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TClienteErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadClientes(Trim(edFiltro.Text));
  SW.Stop;
  TRttiGridFiller.Fill<TClienteErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Clientes', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerAlmacenes(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TAlmacenErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadAlmacenes;
  SW.Stop;
  TRttiGridFiller.Fill<TAlmacenErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Almacenes', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerOrdenesFabricacion(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TOrdenFabricacionErp>;
  Ejercicio: SmallInt;
  Serie: string;
  Numero: Integer;
begin
  Ejercicio := StrToIntDef(edEjercicioP.Text, 0);
  if Ejercicio = 0 then
  begin
    LogError('Indica Ejercicio.');
    Exit;
  end;
  Serie := Trim(edSerie.Text);
  Numero := StrToIntDef(edNumero.Text, 0);
  SW := TStopwatch.StartNew;
  Data := AReader.ReadOrdenesFabricacion(Ejercicio, Serie, Numero);
  SW.Stop;
  TRttiGridFiller.Fill<TOrdenFabricacionErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('OFs cabecera', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerOrdenesTrabajo(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TOrdenTrabajoErp>;
  Ejercicio: SmallInt;
  Numero: Integer;
begin
  Ejercicio := StrToIntDef(edEjercicioP.Text, 0);
  if Ejercicio = 0 then
  begin
    LogError('Indica Ejercicio (Trabajo).');
    Exit;
  end;
  Numero := StrToIntDef(edNumero.Text, 0);
  SW := TStopwatch.StartNew;
  Data := AReader.ReadOrdenesTrabajo(Ejercicio, Numero);
  SW.Stop;
  TRttiGridFiller.Fill<TOrdenTrabajoErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('OTs', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerOperacionesOT(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TOperacionOTErp>;
  Ejercicio: SmallInt;
  Numero: Integer;
begin
  Ejercicio := StrToIntDef(edEjercicioP.Text, 0);
  Numero := StrToIntDef(edNumero.Text, 0);
  if (Ejercicio = 0) or (Numero <= 0) then
  begin
    LogError('Indica Ejercicio y N'#250'mero de Trabajo (OT).');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadOperacionesOT(Ejercicio, Numero);
  SW.Stop;
  TRttiGridFiller.Fill<TOperacionOTErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Operaciones OT', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerConsumosOT(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TConsumoOTErp>;
  Ejercicio: SmallInt;
  Numero: Integer;
begin
  Ejercicio := StrToIntDef(edEjercicioP.Text, 0);
  Numero := StrToIntDef(edNumero.Text, 0);
  if (Ejercicio = 0) or (Numero <= 0) then
  begin
    LogError('Indica Ejercicio y N'#250'mero de Trabajo (OT).');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadConsumosOT(Ejercicio, Numero);
  SW.Stop;
  TRttiGridFiller.Fill<TConsumoOTErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Consumos OT', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerRelacionOTOF(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TRelacionOTOFErp>;
  Ejercicio: SmallInt;
  Serie: string;
  Numero: Integer;
begin
  Ejercicio := StrToIntDef(edEjercicioP.Text, 0);
  Serie := Trim(edSerie.Text);
  Numero := StrToIntDef(edNumero.Text, 0);
  // Tot opcional aqui: si tot es buit retorna tota la taula (potser gran).
  SW := TStopwatch.StartNew;
  Data := AReader.ReadRelacionOTOF(Ejercicio, Serie, Numero);
  SW.Stop;
  TRttiGridFiller.Fill<TRelacionOTOFErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Relaci'#243'n OT<->OF', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerProyectos(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TProyectoErp>;
begin
  SW := TStopwatch.StartNew;
  Data := AReader.ReadProyectos(Trim(edFiltro.Text));
  SW.Stop;
  TRttiGridFiller.Fill<TProyectoErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Proyectos', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerTareasProyecto(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TTareaProyectoErp>;
  CodProy: string;
begin
  CodProy := Trim(edFiltro.Text);
  if CodProy = '' then
  begin
    LogError('Indica el c'#243'digo del proyecto en el filtro.');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadTareasProyecto(CodProy);
  SW.Stop;
  TRttiGridFiller.Fill<TTareaProyectoErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Tareas de proyecto', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerPedidoCabecera(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TPedidoCabecera>;
  Serie: string;
  Numero: Integer;
  Ejercicio: SmallInt;
begin
  Serie := Trim(edSerie.Text);
  Numero := StrToIntDef(edNumero.Text, 0);
  Ejercicio := StrToIntDef(edEjercicioP.Text, 0);
  if Ejercicio = 0 then
  begin
    LogError('Indica Ejercicio.');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadPedidosCabecera(Ejercicio, Serie, Numero);
  SW.Stop;
  TRttiGridFiller.Fill<TPedidoCabecera>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Pedidos cabecera', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerPedidoLineas(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TPedidoLinea>;
  Serie: string;
  Numero: Integer;
  Ejercicio: SmallInt;
begin
  Serie := Trim(edSerie.Text);
  Numero := StrToIntDef(edNumero.Text, 0);
  Ejercicio := StrToIntDef(edEjercicioP.Text, 0);
  if Ejercicio = 0 then
  begin
    LogError('Indica Ejercicio.');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadPedidosLineas(Ejercicio, Serie, Numero);
  SW.Stop;
  TRttiGridFiller.Fill<TPedidoLinea>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Pedidos l'#237'neas', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerFormulaVersiones(AReader: IErpReader);
type
  TVersionRow = record Version: SmallInt; end;
var
  SW: TStopwatch;
  Versions: TArray<SmallInt>;
  Rows: TArray<TVersionRow>;
  i: Integer;
  Articulo: string;
begin
  Articulo := Trim(edArticulo.Text);
  if Articulo = '' then
  begin
    LogError('Indica el c'#243'digo de art'#237'culo.');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Versions := AReader.ReadFormulaVersiones(Articulo);
  SW.Stop;
  SetLength(Rows, Length(Versions));
  for i := 0 to High(Versions) do
    Rows[i].Version := Versions[i];
  TRttiGridFiller.Fill<TVersionRow>(cdsResultados, grdResultadosView, Rows, MAX_COLUMN_WIDTH);
  LogResultado('F'#243'rmula versiones', Length(Rows), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerFormulaCabecera(AReader: IErpReader);
var
  SW: TStopwatch;
  Cab: TFormulaCabecera;
  Arr: TArray<TFormulaCabecera>;
  Articulo: string;
begin
  Articulo := Trim(edArticulo.Text);
  if Articulo = '' then
  begin
    LogError('Indica el c'#243'digo de art'#237'culo.');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Cab := AReader.ReadFormulaCabecera(Articulo);
  SW.Stop;
  if Cab.Encontrada then
  begin
    SetLength(Arr, 1);
    Arr[0] := Cab;
  end
  else
    SetLength(Arr, 0);
  TRttiGridFiller.Fill<TFormulaCabecera>(cdsResultados, grdResultadosView, Arr, MAX_COLUMN_WIDTH);
  LogResultado('F'#243'rmula cabecera', Length(Arr), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerFormulaComponentes(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TFormulaComponente>;
  Articulo: string;
  Version: SmallInt;
begin
  Articulo := Trim(edArticulo.Text);
  Version := StrToIntDef(edVersion.Text, 0);
  if Articulo = '' then
  begin
    LogError('Indica el c'#243'digo de art'#237'culo.');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadFormulaComponentes(Articulo, Version);
  SW.Stop;
  TRttiGridFiller.Fill<TFormulaComponente>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('F'#243'rmula componentes', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerFormulaOperaciones(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TFormulaOperacion>;
  Articulo: string;
  Version: SmallInt;
begin
  Articulo := Trim(edArticulo.Text);
  Version := StrToIntDef(edVersion.Text, 0);
  if Articulo = '' then
  begin
    LogError('Indica el c'#243'digo de art'#237'culo.');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadFormulaOperaciones(Articulo, Version);
  SW.Stop;
  TRttiGridFiller.Fill<TFormulaOperacion>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('F'#243'rmula operaciones', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerStockArticulo(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TStockArticuloErp>;
  Articulo, Partida: string;
  Ejercicio: SmallInt;
begin
  // edArticulo i edVersion (re-labelat com 'Partida') son filtres LIKE.
  // Buits = sense filtre. Ejercicio ve del SpinEdit (0 = ultim disponible).
  Articulo := Trim(edArticulo.Text);
  Partida  := Trim(edVersion.Text);
  Ejercicio := seEjercicioStock.Value;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadStockArticulo(Articulo, '', Partida, Ejercicio, 0);
  SW.Stop;
  TRttiGridFiller.Fill<TStockArticuloErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Stock por partida', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerStockDisponible(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TStockDisponibleErp>;
  Articulo: string;
begin
  // Stock disponible (Neco) ja ve agregat per article+almacen, no per partida:
  // edVersion no s'usa aqui (label tampoc no l'ensenya com a Partida util).
  Articulo := Trim(edArticulo.Text);
  SW := TStopwatch.StartNew;
  Data := AReader.ReadStockDisponible(Articulo, '');
  SW.Stop;
  TRttiGridFiller.Fill<TStockDisponibleErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Stock disponible', Length(Data), SW.ElapsedMilliseconds);
end;

procedure TfrmErpExplorer.LeerEntradasFuturas(AReader: IErpReader);
var
  SW: TStopwatch;
  Data: TArray<TEntradaFuturaErp>;
  Articulo: string;
  FD, FH: TDateTime;
begin
  Articulo := Trim(edFiltro2.Text);
  FD := dtFechaDesde.Date;
  FH := dtFechaHasta.Date;
  if (FD > 0) and (FH > 0) and (FD > FH) then
  begin
    LogError('Fecha desde > fecha hasta.');
    Exit;
  end;
  SW := TStopwatch.StartNew;
  Data := AReader.ReadEntradasFuturas(Articulo, FD, FH);
  SW.Stop;
  TRttiGridFiller.Fill<TEntradaFuturaErp>(cdsResultados, grdResultadosView, Data, MAX_COLUMN_WIDTH);
  LogResultado('Entradas futuras', Length(Data), SW.ElapsedMilliseconds);
end;

end.
