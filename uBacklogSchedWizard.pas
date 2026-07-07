unit uBacklogSchedWizard;

// ============================================================================
//  Asistente (wizard) de planificacion del Backlog.
//
//  Sustituye al dialogo plano uBacklogSchedParams por un asistente visual paso
//  a paso que NO impone un metodo de planificacion: analiza la seleccion y guia
//  al usuario para que decida COMO quiere planificar (granularidad, direccion,
//  fecha, ajustes finos), mostrando ilustraciones en vivo del resultado.
//
//  Reactivo a la seleccion: los pasos y opciones se adaptan a los datos reales
//  (nº de OF/OP, centros implicados). El paso de "centro destino" solo aparece
//  si el usuario elige agrupar TODO y la seleccion abarca varios centros.
//
//  Salida: un TSchedParams (modo/orden/fecha/colocacion/umbrales) + la
//  Agrupacion elegida (agNinguna/agPorCentro/agTodo) y, si procede, el centro
//  destino. La agrupacion se aplica POST-scheduling reutilizando el motor de
//  Lotes (V057); este form solo decide, no planifica.
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections, System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Graphics, Vcl.Samples.Spin,
  dxWizardControl, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters,
  uBacklogScheduler, dxSkinsCore, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
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
  dxSkinXmas2008Blue, dxCustomWizardControl;

type
  // Resumen de la seleccion, calculado al abrir. Alimenta el wizard.
  TSeleccionInfo = record
    NumOP: Integer;                  // total de OP planificables (Nivel 3)
    NumOF: Integer;                  // OF distintas implicadas
    Centros: TArray<string>;         // codigos de centro distintos (CentroPreferente)
    NumCentros: Integer;
    MismoCentro: Boolean;            // True si todas las OP comparten centro
    DuracionTotalH: Double;          // suma estimada de horas (informativo)
  end;

  TfrmBacklogSchedWizard = class(TForm)
    wcMain: TdxWizardControl;
    pgGranularidad: TdxWizardControlPage;
    pgCentro: TdxWizardControlPage;
    pgTemporal: TdxWizardControlPage;
    pgEstrategia: TdxWizardControlPage;
    pgRegla: TdxWizardControlPage;
    pgAjustes: TdxWizardControlPage;
    pgResumen: TdxWizardControlPage;
    // --- Pagina 1: Granularidad ---
    rbGranOP: TRadioButton;
    rbGranCentro: TRadioButton;
    rbGranTodo: TRadioButton;
    lblGranOP: TLabel;
    lblGranCentro: TLabel;
    lblGranTodo: TLabel;
    pbIlustracion: TPaintBox;
    lblGranIntro: TLabel;
    // --- Pagina 2: Centro destino (contextual) ---
    lblCentroIntro: TLabel;
    cbCentroDestino: TComboBox;
    pbCentro: TPaintBox;
    // --- Pagina 3: Temporal ---
    // Direccion en su propio GroupBox: los TRadioButton se agrupan por parent.
    // El ORDEN de la cola ya no vive aqui: tiene su propio paso (pgEstrategia).
    gbDireccion: TGroupBox;
    rbForward: TRadioButton;
    rbBackward: TRadioButton;
    lblFecha: TLabel;
    dtFechaBase: TDateTimePicker;
    pbTemporal: TPaintBox;
    // --- Pagina 4: Estrategia de cola (NUEVO, paso A) ---
    // Como se ORDENA la cola de operaciones antes de apilar (FCS). Tres niveles
    // de potencia creciente; el detalle concreto se elige en pgRegla (paso B).
    lblEstrategiaIntro: TLabel;
    gbEstrategia: TGroupBox;
    rbEstrBasico: TRadioButton;
    rbEstrCanonica: TRadioButton;
    rbEstrPersonalizada: TRadioButton;
    lblEstrBasico: TLabel;
    lblEstrCanonica: TLabel;
    lblEstrPersonalizada: TLabel;
    pbEstrategia: TPaintBox;
    // --- Pagina 5: Detalle de la regla (NUEVO, paso B, contextual) ---
    // Se salta si la estrategia es "Basico". Para "Canonica" muestra el combo de
    // las 7 reglas + boton de desempates; para "Personalizada" el combo de perfiles.
    lblReglaIntro: TLabel;
    // Bloque BASICO (solo visible si estrategia=basico, aunque normalmente se salta)
    gbBasico: TGroupBox;
    rbOrdenFecha: TRadioButton;
    rbOrdenPrio: TRadioButton;
    // Bloque CANONICA
    lblReglaCanonica: TLabel;
    cbReglaCanonica: TComboBox;
    btnConfigDesempate: TButton;
    btnCompararReglas: TButton;
    // Bloque PERSONALIZADA
    lblReglaPerfil: TLabel;
    cbReglaPerfil: TComboBox;
    pbRegla: TPaintBox;
    // --- Pagina 4: Ajustes finos ---
    lblAjustesIntro: TLabel;
    lblPlacement: TLabel;
    cbPlacement: TComboBox;
    lblHueco: TLabel;
    seHueco: TSpinEdit;
    lblPct: TLabel;
    sePct: TSpinEdit;
    lblDist: TLabel;
    seDist: TSpinEdit;
    pbAjustes: TPaintBox;
    // --- Pagina 5: Resumen ---
    lblResumen: TLabel;
    pbResumen: TPaintBox;
    btnVerTiempos: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnVerTiemposClick(Sender: TObject);
    procedure wcMainButtonClick(Sender: TObject;
      AKind: TdxWizardControlButtonKind; var AHandled: Boolean);
    procedure wcMainPageChanging(Sender: TObject;
      ANewPage: TdxWizardControlCustomPage; var AAllow: Boolean);
    procedure wcMainPageChanged(Sender: TObject);
    procedure rbGranClick(Sender: TObject);
    procedure lblGranOPClick(Sender: TObject);
    procedure lblGranCentroClick(Sender: TObject);
    procedure lblGranTodoClick(Sender: TObject);
    procedure rbModoClick(Sender: TObject);
    procedure rbEstrategiaClick(Sender: TObject);
    procedure lblEstrBasicoClick(Sender: TObject);
    procedure lblEstrCanonicaClick(Sender: TObject);
    procedure lblEstrPersonalizadaClick(Sender: TObject);
    procedure btnConfigDesempateClick(Sender: TObject);
    procedure btnCompararReglasClick(Sender: TObject);
    procedure pbIlustracionPaint(Sender: TObject);
    procedure pbCentroPaint(Sender: TObject);
    procedure pbTemporalPaint(Sender: TObject);
    procedure pbEstrategiaPaint(Sender: TObject);
    procedure pbReglaPaint(Sender: TObject);
    procedure pbAjustesPaint(Sender: TObject);
    procedure pbResumenPaint(Sender: TObject);
  private
    FParams: TSchedParams;
    FInfo: TSeleccionInfo;
    FInputs: TArray<TSchedInput>;  // seleccion (OP Nivel 3) para el calculo real
    FAccepted: Boolean;
    // --- Estrategia de cola ---
    FRuleSet: TPriorityRuleSet;          // desempates de la regla canonica elegida
    FPerfilesCustom: TArray<string>;     // nombres de perfiles del cliente (entrada)
    FPerfilSeleccionado: Integer;        // -1 si no se usa perfil; >=0 indice
    FCentrosPlan: TArray<string>;        // centros del plan (para overrides del dialogo)
    // --- Planificacion Express ---
    // FExpress: abrir directo al Resumen con la ultima config precargada.
    // FEstrategiaIni/FReglaIni... : estado cargado de preferencias que ApplyToUI
    // debe reflejar (en vez de forzar siempre los defaults clasicos).
    FExpress: Boolean;
    FEstrategiaIni: Integer;             // 0=basico, 1=canonica, 2=personalizada
    FReglaCanonicaIni: Integer;          // Ord(TPriorityRule)
    FPerfilNombreIni: string;            // nombre del perfil custom (estable)
    FOrdenPrioridadIni: Boolean;
    function GranularidadElegida: TSchedAgrupacion;
    function NecesitaPasoCentro: Boolean;
    function EstrategiaEsBasico: Boolean;
    function EstrategiaEsCanonica: Boolean;
    function EstrategiaEsPersonalizada: Boolean;
    function ReglaCanonicaElegida: TPriorityRule;
    procedure ApplyToUI;
    procedure ReadFromUI;
    procedure LoadDefaults;
    procedure SaveLast;
    procedure PoblarCentros;
    procedure PoblarReglas;
    procedure ActualizarVisibilidadCentro;
    procedure ActualizarVisibilidadRegla;
    procedure RefrescarResumen;
    procedure ActualizarContadorPaso;
    function NombreCentro(const ACodigo: string): string;
    function EstrategiaTexto: string;
    function ResumenTexto: string;
  public
    // AExpress=True: abre directo a la pagina de Resumen con la ultima config
    // guardada precargada (el usuario puede ir "Atras" para ajustar).
    class function Execute(const AInputs: TArray<TSchedInput>;
      var AParams: TSchedParams; var ARuleSet: TPriorityRuleSet;
      const APerfilesCustom: TArray<string>; const ACentrosPlan: TArray<string>;
      out APerfilSeleccionado: Integer; AExpress: Boolean = False): Boolean;
    // True si hay una configuracion Express guardada (para habilitar el boton).
    class function HayConfigExpress: Boolean;
  end;

// Analiza la seleccion (OP ya explotadas a Nivel 3) para alimentar el wizard.
function AnalizarSeleccion(const AInputs: TArray<TSchedInput>): TSeleccionInfo;

implementation

{$R *.dfm}

uses
  System.DateUtils, System.Math, System.Generics.Defaults,
  Vcl.GraphUtil, Winapi.GDIPOBJ, Winapi.GDIPAPI, Vcl.Dialogs,
  uUserPrefs, uGanttConfig, uGanttTypes, uDMPlanner, uBacklogSchedPreview,
  uReglasPlanParams, uPlanningEngineRules, uReglasPlanComparativa;

const
  MOD_NAME = 'BACKLOG_SCHED';
  // Paleta APS pro (colores en formato TColor = BGR de Windows).
  CLR_NODO_TOP  = $00D9A45A;  // azul acero claro (gradiente top)
  CLR_NODO_BOT  = $00B5803A;  // azul acero oscuro (gradiente bottom)
  CLR_NODO_BD   = $008A5F20;  // borde nodo
  CLR_ACCENT    = $00C8924A;  // acento (mismo azul acero)
  CLR_GREEN_TOP = $006FB46A;  // verde (resultado destacado)
  CLR_GREEN_BOT = $004F9A4A;
  CLR_GREEN_BD  = $00357A30;
  CLR_TXT       = $00505050;  // texto principal
  CLR_TXT_SOFT  = $00909090;  // texto secundario
  CLR_BG        = $00FBFAF8;  // fondo lienzo (casi blanco, calido)
  CLR_PANEL     = $00F2EFEA;  // panel/zona
  CLR_PANEL_BD  = $00DAD4CC;
  CLR_FLECHA    = $00A08868;
  CLR_GRID      = $00E4DFD8;  // lineas de timeline

// ---------------------------------------------------------------------------
// Analisis de la seleccion
// ---------------------------------------------------------------------------
function AnalizarSeleccion(const AInputs: TArray<TSchedInput>): TSeleccionInfo;
var
  I: Integer;
  Cod: string;
  SetCentros: TDictionary<string, Boolean>;
  SetOF: TDictionary<string, Boolean>;
  OFKey: string;
begin
  Result := Default(TSeleccionInfo);
  Result.NumOP := Length(AInputs);

  SetCentros := TDictionary<string, Boolean>.Create;
  SetOF := TDictionary<string, Boolean>.Create;
  try
    for I := 0 to High(AInputs) do
    begin
      // Centro: normalizamos vacio -> SIN CENTRO para contar igual que planifica.
      Cod := Trim(AInputs[I].CentroPreferente);
      if Cod = '' then Cod := CENTRO_SIN_CENTRO;
      SetCentros.AddOrSetValue(UpperCase(Cod), True);

      // OF distinta: por NumeroOF+SerieOF (si no hay, por ClaveERP del padre/raw).
      OFKey := IntToStr(AInputs[I].NumeroOF) + '|' + AInputs[I].SerieOF;
      if Trim(OFKey) = '|' then OFKey := AInputs[I].RawItemClaveERP;
      SetOF.AddOrSetValue(OFKey, True);

      Result.DuracionTotalH := Result.DuracionTotalH + AInputs[I].HorasEstimadas;
    end;

    Result.NumCentros := SetCentros.Count;
    Result.NumOF := SetOF.Count;
    Result.MismoCentro := SetCentros.Count <= 1;
    Result.Centros := SetCentros.Keys.ToArray;
  finally
    SetCentros.Free;
    SetOF.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Ciclo de vida
// ---------------------------------------------------------------------------
class function TfrmBacklogSchedWizard.HayConfigExpress: Boolean;
begin
  Result := uUserPrefs.GetPrefBool(MOD_NAME, 'ExpressGuardado', False);
end;

class function TfrmBacklogSchedWizard.Execute(
  const AInputs: TArray<TSchedInput>; var AParams: TSchedParams;
  var ARuleSet: TPriorityRuleSet; const APerfilesCustom: TArray<string>;
  const ACentrosPlan: TArray<string>; out APerfilSeleccionado: Integer;
  AExpress: Boolean): Boolean;
var
  F: TfrmBacklogSchedWizard;
begin
  APerfilSeleccionado := -1;
  F := TfrmBacklogSchedWizard.Create(Application);
  try
    F.FInputs := AInputs;
    F.FInfo := AnalizarSeleccion(AInputs);
    F.FPerfilesCustom := APerfilesCustom;
    F.FCentrosPlan := ACentrosPlan;
    F.FExpress := AExpress;
    F.LoadDefaults;
    F.ApplyToUI;
    // Express: saltar directo al Resumen con todo precargado. El paso de centro
    // destino solo tiene sentido si la agrupacion guardada lo requiere; si no,
    // pgResumen es alcanzable directamente.
    if AExpress then
      F.wcMain.ActivePage := F.pgResumen;
    F.ShowModal;
    Result := F.FAccepted;
    if Result then
    begin
      F.ReadFromUI;
      F.SaveLast;
      AParams := F.FParams;
      ARuleSet := F.FRuleSet;
      APerfilSeleccionado := F.FPerfilSeleccionado;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmBacklogSchedWizard.FormCreate(Sender: TObject);
var
  P: TPlacementPolicy;
begin
  FAccepted := False;
  FPerfilSeleccionado := -1;
  cbPlacement.Items.Clear;
  for P := Low(TPlacementPolicy) to High(TPlacementPolicy) do
    cbPlacement.Items.Add(PlacementToStr(P));

  // Quitar el boton Help del pie (la ayuda ya esta en el caption/cabecera).
  wcMain.Buttons.Help.Visible := False;

  ActualizarContadorPaso;
end;

// ---------------------------------------------------------------------------
// Defaults + UI <-> Params
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedWizard.LoadDefaults;
var
  Cfg: TGanttConfig;
  FechaStr: string;
  D: TDateTime;
begin
  Cfg := LoadGanttConfig;
  ApplyConfigToSchedParams(Cfg, FParams);
  FParams.Mode := Cfg.Mode;
  FParams.Order := Cfg.Order;
  FParams.Agrupacion := agNinguna;
  FParams.CentroDestinoAgrupado := '';

  FechaStr := uUserPrefs.GetPref(MOD_NAME, 'FechaBase', '');
  if TryStrToDate(FechaStr, D) then FParams.FechaBase := D
  else FParams.FechaBase := Date;

  // Desempates de la regla canonica: por defecto los del motor de reglas.
  FRuleSet := DefaultRuleSet;
  FPerfilSeleccionado := -1;

  // --- Cargar la ultima configuracion guardada (para Express y como defaults
  //     "recordados" del wizard normal). Si no hay nada guardado, quedan los
  //     defaults clasicos de arriba.
  FParams.Agrupacion := TSchedAgrupacion(
    uUserPrefs.GetPrefInt(MOD_NAME, 'Agrupacion', Ord(agNinguna)));
  if uUserPrefs.GetPrefBool(MOD_NAME, 'Backward', False) then
    FParams.Mode := smBackward
  else
    FParams.Mode := smForward;

  FEstrategiaIni := uUserPrefs.GetPrefInt(MOD_NAME, 'Estrategia', 0);
  FOrdenPrioridadIni := uUserPrefs.GetPrefBool(MOD_NAME, 'OrdenPrioridad', False);
  FReglaCanonicaIni := uUserPrefs.GetPrefInt(MOD_NAME, 'ReglaCanonica',
    Ord(FRuleSet.Principal));
  FRuleSet.Principal := TPriorityRule(FReglaCanonicaIni);
  FRuleSet.Desempate1 := TPriorityRule(
    uUserPrefs.GetPrefInt(MOD_NAME, 'Desempate1', Ord(FRuleSet.Desempate1)));
  FRuleSet.Desempate2 := TPriorityRule(
    uUserPrefs.GetPrefInt(MOD_NAME, 'Desempate2', Ord(FRuleSet.Desempate2)));
  FPerfilNombreIni := uUserPrefs.GetPref(MOD_NAME, 'PerfilNombre', '');

  FParams.Placement := TPlacementPolicy(
    uUserPrefs.GetPrefInt(MOD_NAME, 'Placement', Ord(FParams.Placement)));
  FParams.HuecoMinimoMin := uUserPrefs.GetPrefInt(MOD_NAME, 'HuecoMin',
    FParams.HuecoMinimoMin);
  FParams.PorcentajeMinNodo := uUserPrefs.GetPrefInt(MOD_NAME, 'PctMin',
    FParams.PorcentajeMinNodo);
  FParams.DistanciaMinNodos := uUserPrefs.GetPrefInt(MOD_NAME, 'DistMin',
    FParams.DistanciaMinNodos);
end;

procedure TfrmBacklogSchedWizard.ApplyToUI;
var
  PerfilIdx: Integer;
begin
  // Granularidad: refleja la ultima eleccion guardada (FParams.Agrupacion ya
  // viene de LoadDefaults). Por defecto agNinguna = "un nodo por operacion".
  rbGranTodo.Checked   := FParams.Agrupacion = agTodo;
  rbGranCentro.Checked := FParams.Agrupacion = agPorCentro;
  rbGranOP.Checked     := FParams.Agrupacion = agNinguna;

  // Direccion: refleja lo guardado.
  rbBackward.Checked := FParams.Mode = smBackward;
  rbForward.Checked  := FParams.Mode <> smBackward;
  if FParams.FechaBase = 0 then dtFechaBase.Date := Date
  else dtFechaBase.Date := FParams.FechaBase;

  // Combos primero (PoblarReglas necesita estar antes de seleccionar perfil).
  PoblarReglas;

  // Estrategia de cola: reconstruir desde lo guardado (FEstrategiaIni).
  rbEstrCanonica.Checked      := FEstrategiaIni = 1;
  rbEstrPersonalizada.Checked := (FEstrategiaIni = 2) and rbEstrPersonalizada.Enabled;
  rbEstrBasico.Checked        := not (rbEstrCanonica.Checked or rbEstrPersonalizada.Checked);

  rbOrdenPrio.Checked  := FOrdenPrioridadIni;
  rbOrdenFecha.Checked := not FOrdenPrioridadIni;

  // Regla canonica: indice = Ord de la regla guardada.
  if (FReglaCanonicaIni >= 0) and (FReglaCanonicaIni < cbReglaCanonica.Items.Count) then
    cbReglaCanonica.ItemIndex := FReglaCanonicaIni;

  // Perfil custom: resolver por NOMBRE (los indices no son estables).
  if FPerfilNombreIni <> '' then
  begin
    PerfilIdx := cbReglaPerfil.Items.IndexOf(FPerfilNombreIni);
    if PerfilIdx >= 0 then cbReglaPerfil.ItemIndex := PerfilIdx;
  end;

  cbPlacement.ItemIndex := Ord(FParams.Placement);
  seHueco.Value := FParams.HuecoMinimoMin;
  sePct.Value := FParams.PorcentajeMinNodo;
  seDist.Value := FParams.DistanciaMinNodos;

  PoblarCentros;
  ActualizarVisibilidadRegla;
  ActualizarContadorPaso;
  RefrescarResumen;
end;

procedure TfrmBacklogSchedWizard.ReadFromUI;
begin
  if rbBackward.Checked then FParams.Mode := smBackward
  else FParams.Mode := smForward;

  // Estrategia de cola -> Order + (regla canonica | perfil custom).
  //   Basico        -> soFechaCompromiso | soPrioridad (el FCS reordena solo).
  //   Canonica      -> soPreordenado: la cola la ordena SortInputsByRuleSet con
  //                    FRuleSet ANTES de RunAutoScheduling (lo hace el llamador).
  //   Personalizada -> soPreordenado + FPerfilSeleccionado>=0: el llamador ordena
  //                    via el perfil del cliente (FPlanningRuleEngine).
  FPerfilSeleccionado := -1;
  if EstrategiaEsCanonica then
  begin
    FParams.Order := soPreordenado;
    FRuleSet.Principal := ReglaCanonicaElegida;
    // Desempate1/Desempate2 ya vienen de FRuleSet (DefaultRuleSet o el dialogo).
  end
  else if EstrategiaEsPersonalizada then
  begin
    FParams.Order := soPreordenado;
    FPerfilSeleccionado := cbReglaPerfil.ItemIndex;
  end
  else
  begin
    if rbOrdenPrio.Checked then FParams.Order := soPrioridad
    else FParams.Order := soFechaCompromiso;
  end;

  FParams.FechaBase := dtFechaBase.Date;
  if cbPlacement.ItemIndex >= 0 then
    FParams.Placement := TPlacementPolicy(cbPlacement.ItemIndex)
  else
    FParams.Placement := ppHueco;
  FParams.HuecoMinimoMin := seHueco.Value;
  FParams.PorcentajeMinNodo := sePct.Value;
  FParams.DistanciaMinNodos := seDist.Value;

  FParams.Agrupacion := GranularidadElegida;
  if (FParams.Agrupacion = agTodo) and (not FInfo.MismoCentro) then
    FParams.CentroDestinoAgrupado := cbCentroDestino.Text
  else if FParams.Agrupacion = agTodo then
    // Mismo centro: el destino es ese unico centro.
    FParams.CentroDestinoAgrupado := FInfo.Centros[0]
  else
    FParams.CentroDestinoAgrupado := '';
end;

// Persiste TODA la configuracion elegida (no solo la fecha) para que la
// "Planificacion Express" pueda reconstruir la ultima eleccion sin pasar paso
// a paso. Se guarda el estado de la UI (granularidad/direccion/estrategia/
// regla/perfil/placement/umbrales) en preferencias de usuario (BD).
procedure TfrmBacklogSchedWizard.SaveLast;
var
  Estrategia: Integer;   // 0=basico, 1=canonica, 2=personalizada
begin
  uUserPrefs.SetPref(MOD_NAME, 'FechaBase',
    FormatDateTime('yyyy-mm-dd', FParams.FechaBase));

  // Granularidad / agrupacion.
  uUserPrefs.SetPrefInt(MOD_NAME, 'Agrupacion', Ord(GranularidadElegida));
  // Direccion.
  uUserPrefs.SetPrefBool(MOD_NAME, 'Backward', rbBackward.Checked);

  // Estrategia de cola + detalle.
  if EstrategiaEsCanonica then Estrategia := 1
  else if rbEstrPersonalizada.Checked then Estrategia := 2
  else Estrategia := 0;
  uUserPrefs.SetPrefInt(MOD_NAME, 'Estrategia', Estrategia);
  uUserPrefs.SetPrefBool(MOD_NAME, 'OrdenPrioridad', rbOrdenPrio.Checked);
  uUserPrefs.SetPrefInt(MOD_NAME, 'ReglaCanonica', Ord(ReglaCanonicaElegida));
  uUserPrefs.SetPrefInt(MOD_NAME, 'Desempate1', Ord(FRuleSet.Desempate1));
  uUserPrefs.SetPrefInt(MOD_NAME, 'Desempate2', Ord(FRuleSet.Desempate2));
  // Perfil: guardamos su NOMBRE (el indice no es estable entre sesiones).
  if (Estrategia = 2) and (cbReglaPerfil.ItemIndex >= 0) then
    uUserPrefs.SetPref(MOD_NAME, 'PerfilNombre', cbReglaPerfil.Text)
  else
    uUserPrefs.SetPref(MOD_NAME, 'PerfilNombre', '');

  // Ajustes finos.
  uUserPrefs.SetPrefInt(MOD_NAME, 'Placement', cbPlacement.ItemIndex);
  uUserPrefs.SetPrefInt(MOD_NAME, 'HuecoMin', seHueco.Value);
  uUserPrefs.SetPrefInt(MOD_NAME, 'PctMin', sePct.Value);
  uUserPrefs.SetPrefInt(MOD_NAME, 'DistMin', seDist.Value);

  // Marca de que hay una configuracion Express disponible.
  uUserPrefs.SetPrefBool(MOD_NAME, 'ExpressGuardado', True);
end;

// ---------------------------------------------------------------------------
// Granularidad
// ---------------------------------------------------------------------------
function TfrmBacklogSchedWizard.GranularidadElegida: TSchedAgrupacion;
begin
  if rbGranTodo.Checked then Result := agTodo
  else if rbGranCentro.Checked then Result := agPorCentro
  else Result := agNinguna;
end;

function TfrmBacklogSchedWizard.NecesitaPasoCentro: Boolean;
begin
  // El paso de centro destino solo aplica si se agrupa TODO y hay varios centros.
  Result := (GranularidadElegida = agTodo) and (not FInfo.MismoCentro);
end;

// Clic sobre el texto descriptivo: marca el radio correspondiente (mas comodo
// que apuntar al pequeno circulo del RadioButton).
procedure TfrmBacklogSchedWizard.lblGranOPClick(Sender: TObject);
begin
  rbGranOP.Checked := True;
  rbGranClick(rbGranOP);
end;

procedure TfrmBacklogSchedWizard.lblGranCentroClick(Sender: TObject);
begin
  rbGranCentro.Checked := True;
  rbGranClick(rbGranCentro);
end;

procedure TfrmBacklogSchedWizard.lblGranTodoClick(Sender: TObject);
begin
  rbGranTodo.Checked := True;
  rbGranClick(rbGranTodo);
end;

procedure TfrmBacklogSchedWizard.rbGranClick(Sender: TObject);
begin
  pbIlustracion.Invalidate;
  pbCentro.Invalidate;   // refleja el centro destino elegido en su ilustracion
  RefrescarResumen;
  // La eleccion de granularidad puede activar/desactivar el paso de centro:
  // recalcular el contador "Paso X de Y".
  ActualizarContadorPaso;
end;

// ---------------------------------------------------------------------------
// Estrategia de cola (paso A) + detalle de la regla (paso B)
// ---------------------------------------------------------------------------
function TfrmBacklogSchedWizard.EstrategiaEsBasico: Boolean;
begin
  Result := rbEstrBasico.Checked;
end;

function TfrmBacklogSchedWizard.EstrategiaEsCanonica: Boolean;
begin
  Result := rbEstrCanonica.Checked;
end;

function TfrmBacklogSchedWizard.EstrategiaEsPersonalizada: Boolean;
begin
  // Solo si hay perfiles disponibles; si no, la opcion esta deshabilitada.
  Result := rbEstrPersonalizada.Checked and (Length(FPerfilesCustom) > 0);
end;

function TfrmBacklogSchedWizard.ReglaCanonicaElegida: TPriorityRule;
var
  Idx: Integer;
begin
  Idx := cbReglaCanonica.ItemIndex;
  if (Idx < 0) or (Idx > Ord(High(TPriorityRule))) then
    Result := prEDD
  else
    Result := TPriorityRule(Idx);
end;

procedure TfrmBacklogSchedWizard.PoblarReglas;
var
  R: TPriorityRule;
  S: string;
begin
  // Combo de reglas canonicas (las 7 del motor de reglas).
  cbReglaCanonica.Items.Clear;
  for R := Low(TPriorityRule) to High(TPriorityRule) do
    cbReglaCanonica.Items.Add(PriorityRuleToStr(R));
  // Por defecto, la principal del RuleSet cargado.
  cbReglaCanonica.ItemIndex := Ord(FRuleSet.Principal);

  // Combo de perfiles del cliente (si los hay).
  cbReglaPerfil.Items.Clear;
  for S in FPerfilesCustom do
    cbReglaPerfil.Items.Add(S);
  if cbReglaPerfil.Items.Count > 0 then
    cbReglaPerfil.ItemIndex := 0;

  // Sin perfiles -> la estrategia "Personalizada" no tiene sentido: se inhabilita.
  rbEstrPersonalizada.Enabled := Length(FPerfilesCustom) > 0;
  lblEstrPersonalizada.Enabled := rbEstrPersonalizada.Enabled;
end;

procedure TfrmBacklogSchedWizard.ActualizarVisibilidadRegla;
var
  EsCan, EsPer: Boolean;
begin
  EsCan := EstrategiaEsCanonica;
  EsPer := rbEstrPersonalizada.Checked;
  // Bloque BASICO solo cuando la estrategia es basica (normalmente pgRegla se
  // salta en ese caso, pero lo dejamos coherente por si se navega atras).
  gbBasico.Visible := EstrategiaEsBasico;
  // Bloque CANONICA
  lblReglaCanonica.Visible := EsCan;
  cbReglaCanonica.Visible := EsCan;
  btnConfigDesempate.Visible := EsCan;
  btnCompararReglas.Visible := EsCan;
  // Bloque PERSONALIZADA
  lblReglaPerfil.Visible := EsPer;
  cbReglaPerfil.Visible := EsPer;
  pbRegla.Invalidate;
end;

procedure TfrmBacklogSchedWizard.rbEstrategiaClick(Sender: TObject);
begin
  ActualizarVisibilidadRegla;
  pbEstrategia.Invalidate;
  RefrescarResumen;
  // La estrategia decide si el paso de regla aplica: recalcular "Paso X de Y".
  ActualizarContadorPaso;
end;

procedure TfrmBacklogSchedWizard.lblEstrBasicoClick(Sender: TObject);
begin
  rbEstrBasico.Checked := True;
  rbEstrategiaClick(rbEstrBasico);
end;

procedure TfrmBacklogSchedWizard.lblEstrCanonicaClick(Sender: TObject);
begin
  rbEstrCanonica.Checked := True;
  rbEstrategiaClick(rbEstrCanonica);
end;

procedure TfrmBacklogSchedWizard.lblEstrPersonalizadaClick(Sender: TObject);
begin
  if not rbEstrPersonalizada.Enabled then Exit;
  rbEstrPersonalizada.Checked := True;
  rbEstrategiaClick(rbEstrPersonalizada);
end;

// Abre el dialogo del motor de reglas SOLO para afinar los desempates (y, de
// paso, overrides por centro). La regla principal sigue mandando el combo del
// wizard; al volver, sincronizamos el combo con lo que devuelva el dialogo.
procedure TfrmBacklogSchedWizard.btnConfigDesempateClick(Sender: TObject);
var
  P: TSchedParams;
  Overrides: TArray<TCenterRuleOverride>;
  PerfilSel: Integer;
  MR: TModalResult;
begin
  P := FParams;
  P.Order := soPreordenado;
  FRuleSet.Principal := ReglaCanonicaElegida;
  MR := TfrmReglasPlanParams.Execute(FCentrosPlan, FPerfilesCustom,
    P, FRuleSet, Overrides, PerfilSel);
  if MR = mrCancel then Exit;
  // Reflejar la regla principal que pueda haber cambiado en el dialogo.
  cbReglaCanonica.ItemIndex := Ord(FRuleSet.Principal);
  pbRegla.Invalidate;
  RefrescarResumen;
end;

// Comparativa: ejecuta las 7 reglas canonicas sobre la MISMA seleccion con los
// parametros ya elegidos (direccion/fecha) y muestra KPIs + recomendacion. Es
// informativa: al cerrar, el usuario elige en el combo la regla que prefiera.
procedure TfrmBacklogSchedWizard.btnCompararReglasClick(Sender: TObject);
var
  P: TSchedParams;
begin
  if Length(FInputs) = 0 then
  begin
    ShowMessage('No hay operaciones que comparar.');
    Exit;
  end;
  // Volcar la UI (direccion, fecha, ajustes) sin tocar FParams.
  ReadFromUI;
  P := FParams;
  // La comparativa reordena internamente con cada regla: el Order de entrada es
  // indiferente, pero dejamos soPreordenado para no reordenar dos veces.
  P.Order := soPreordenado;
  TfrmReglasPlanComparativa.Execute(FInputs, P);
end;

// ---------------------------------------------------------------------------
// Centros
// ---------------------------------------------------------------------------
function TfrmBacklogSchedWizard.NombreCentro(const ACodigo: string): string;
var
  C: TCentreTreball;
  Cod: string;
begin
  Cod := Trim(ACodigo);
  if SameText(Cod, CENTRO_SIN_CENTRO) then Exit('Sin centro');
  if SameText(Cod, CENTRO_EXTERNO) then Exit('Centro externo');
  Result := Cod;
  if (DMPlanner <> nil) and (DMPlanner.CentresRepo <> nil) then
    for C in DMPlanner.CentresRepo.GetAll do
      if SameText(Trim(C.CodiCentre), Cod) then
      begin
        if Trim(C.Titulo) <> '' then Result := C.Titulo + ' (' + Cod + ')';
        Break;
      end;
end;

procedure TfrmBacklogSchedWizard.PoblarCentros;
var
  Cod: string;
begin
  cbCentroDestino.Items.Clear;
  for Cod in FInfo.Centros do
    cbCentroDestino.Items.Add(Cod);  // codigo crudo; el wizard resuelve nombre aparte
  if cbCentroDestino.Items.Count > 0 then
    cbCentroDestino.ItemIndex := 0;
end;

procedure TfrmBacklogSchedWizard.ActualizarVisibilidadCentro;
begin
  // pgCentro se salta en PageChanging si no procede; aqui solo refrescamos pinta.
  pbCentro.Invalidate;
end;

// ---------------------------------------------------------------------------
// Navegacion del wizard
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedWizard.ActualizarContadorPaso;
var
  TotalPasos, PasoActual, Idx: Integer;
begin
  // Total de pasos: todas las paginas, menos las contextuales que no apliquen
  // en esta sesion (centro destino y/o detalle de regla).
  TotalPasos := wcMain.PageCount;
  if not NecesitaPasoCentro then Dec(TotalPasos);
  if EstrategiaEsBasico then Dec(TotalPasos);

  // Paso actual: indice de la pagina activa, descontando las paginas saltadas
  // que ya hayan quedado atras.
  Idx := wcMain.ActivePageIndex;
  PasoActual := Idx + 1;
  if (not NecesitaPasoCentro) and (Idx > pgCentro.PageIndex) then
    Dec(PasoActual);
  if EstrategiaEsBasico and (Idx > pgRegla.PageIndex) then
    Dec(PasoActual);

  // El contador "Paso X de Y" se muestra en el caption de la ventana.
  Caption := Format('Asistente de planificaci'#243'n  —  Paso %d de %d',
    [PasoActual, TotalPasos]);
end;

procedure TfrmBacklogSchedWizard.wcMainPageChanging(Sender: TObject;
  ANewPage: TdxWizardControlCustomPage; var AAllow: Boolean);
begin
  // Saltar la pagina de centro destino si no es necesaria (un solo centro o no
  // se agrupa TODO). La salta en ambas direcciones.
  if (ANewPage = pgCentro) and (not NecesitaPasoCentro) then
  begin
    AAllow := False;
    if wcMain.ActivePageIndex < pgCentro.PageIndex then
      wcMain.ActivePage := pgTemporal   // avanzando: saltar a temporal
    else
      wcMain.ActivePage := pgGranularidad;  // retrocediendo: volver a granularidad
    Exit;
  end;

  // Saltar la pagina de detalle de regla si la estrategia es "Basico" (el orden
  // basico ya se eligio en el paso de estrategia). Se salta en ambos sentidos.
  if (ANewPage = pgRegla) and EstrategiaEsBasico then
  begin
    AAllow := False;
    if wcMain.ActivePageIndex < pgRegla.PageIndex then
      wcMain.ActivePage := pgAjustes        // avanzando: saltar a ajustes
    else
      wcMain.ActivePage := pgEstrategia;    // retrocediendo: volver a estrategia
    Exit;
  end;
end;

procedure TfrmBacklogSchedWizard.wcMainPageChanged(Sender: TObject);
begin
  // Refrescos al ATERRIZAR en cada pagina (mas fiable que en PageChanging).
  ActualizarContadorPaso;
  if wcMain.ActivePage = pgResumen then RefrescarResumen;
  if wcMain.ActivePage = pgCentro then ActualizarVisibilidadCentro;
  if wcMain.ActivePage = pgTemporal then pbTemporal.Invalidate;
  if wcMain.ActivePage = pgEstrategia then pbEstrategia.Invalidate;
  if wcMain.ActivePage = pgRegla then
  begin
    ActualizarVisibilidadRegla;
    pbRegla.Invalidate;
  end;
  if wcMain.ActivePage = pgAjustes then pbAjustes.Invalidate;
end;

procedure TfrmBacklogSchedWizard.wcMainButtonClick(Sender: TObject;
  AKind: TdxWizardControlButtonKind; var AHandled: Boolean);
begin
  case AKind of
    wcbkFinish:
      begin
        FAccepted := True;
        Close;
        AHandled := True;
      end;
    wcbkCancel:
      begin
        FAccepted := False;
        Close;
        AHandled := True;
      end;
  end;
end;

procedure TfrmBacklogSchedWizard.rbModoClick(Sender: TObject);
begin
  // Handler compartido por los controles de varios pasos: repintar todas las
  // ilustraciones es barato e inofensivo (solo se ve la pagina activa).
  pbTemporal.Invalidate;
  pbRegla.Invalidate;
  pbAjustes.Invalidate;
  RefrescarResumen;
end;

// ---------------------------------------------------------------------------
// Resumen en lenguaje natural
// ---------------------------------------------------------------------------
// Frase corta que describe la estrategia de cola elegida (para el resumen).
function TfrmBacklogSchedWizard.EstrategiaTexto: string;
begin
  if EstrategiaEsCanonica then
    Result := 'ordenando por ' + PriorityRuleToStr(ReglaCanonicaElegida)
  else if EstrategiaEsPersonalizada then
  begin
    if (cbReglaPerfil.ItemIndex >= 0) then
      Result := 'ordenando por el perfil "' + cbReglaPerfil.Text + '"'
    else
      Result := 'ordenando por un perfil del cliente';
  end
  else if rbOrdenPrio.Checked then
    Result := 'ordenando por prioridad'
  else
    Result := 'ordenando por fecha de compromiso';
end;

function TfrmBacklogSchedWizard.ResumenTexto: string;
var
  Gran, Dir, Cent: string;
begin
  case GranularidadElegida of
    agTodo:
      Gran := 'agrupadas en 1 solo nodo';
    agPorCentro:
      Gran := Format('agrupadas por centro (%d nodos)', [FInfo.NumCentros]);
  else
    Gran := Format('en detalle (%d nodos, uno por operaci'#243'n)', [FInfo.NumOP]);
  end;

  if rbBackward.Checked then Dir := 'hacia atras desde la fecha de entrega'
  else Dir := 'hacia delante desde el ' + FormatDateTime('dd/mm/yyyy', dtFechaBase.Date);

  if NecesitaPasoCentro then
    Cent := ' en el centro ' + NombreCentro(cbCentroDestino.Text)
  else if (GranularidadElegida = agTodo) and (Length(FInfo.Centros) > 0) then
    Cent := ' en el centro ' + NombreCentro(FInfo.Centros[0])
  else
    Cent := '';

  // Una sola linea (el detalle completo ya se muestra dibujado debajo).
  Result := Format('Se planificar'#225'n %d operaciones (%d OF) %s%s, %s, %s.',
    [FInfo.NumOP, FInfo.NumOF, Gran, Cent, Dir, EstrategiaTexto]);
end;

procedure TfrmBacklogSchedWizard.RefrescarResumen;
begin
  if lblResumen <> nil then
    lblResumen.Caption := ResumenTexto;
  if pbResumen <> nil then
    pbResumen.Invalidate;
end;

// ---------------------------------------------------------------------------
// "Ver tiempos calculados": ejecuta el motor REAL con los parametros elegidos
// y muestra el preview (grid OP a OP + ventana temporal MIN/MAX). Calculo bajo
// demanda: solo corre si el usuario lo pide. No confirma nada; es informativo.
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedWizard.btnVerTiemposClick(Sender: TObject);
var
  P: TSchedParams;
  SR: TSchedResult;
begin
  if Length(FInputs) = 0 then
  begin
    ShowMessage('No hay operaciones que calcular.');
    Exit;
  end;
  // Volcar la UI a un TSchedParams local (sin tocar FParams ni cerrar el wizard).
  ReadFromUI;
  P := FParams;

  Screen.Cursor := crHourGlass;
  try
    SR := RunAutoScheduling(FInputs, P);
  finally
    Screen.Cursor := crDefault;
  end;

  // Modo solo-consulta: un unico boton "Cerrar"; ignoramos el ModalResult (el
  // usuario sigue en el wizard y puede ajustar parametros si la ventana no gusta).
  TfrmBacklogSchedPreview.Execute(SR, True);
end;

// ===========================================================================
//  Libreria de dibujo PRO (GDI+): antialiasing, gradientes, sombras y
//  esquinas redondeadas. Todas las ilustraciones se pintan sobre un TGPGraphics
//  creado desde el DC del PaintBox.
// ===========================================================================

// Convierte un TColor (BGR) a ARGB de GDI+ con alpha dado.
function GP(AColor: TColor; AAlpha: Byte = 255): TGPColor;
var
  R, G, B: Byte;
begin
  AColor := ColorToRGB(AColor);
  R := GetRValue(AColor); G := GetGValue(AColor); B := GetBValue(AColor);
  Result := MakeColor(AAlpha, R, G, B);
end;

// Path de rectangulo redondeado.
function RoundPath(X, Y, W, H, R: Single): TGPGraphicsPath;
var
  D: Single;
begin
  Result := TGPGraphicsPath.Create;
  D := R * 2;
  if D > W then D := W;
  if D > H then D := H;
  Result.AddArc(X, Y, D, D, 180, 90);
  Result.AddArc(X + W - D, Y, D, D, 270, 90);
  Result.AddArc(X + W - D, Y + H - D, D, D, 0, 90);
  Result.AddArc(X, Y + H - D, D, D, 90, 90);
  Result.CloseFigure;
end;

// Rectangulo redondeado con gradiente vertical + sombra suave + borde.
procedure GpNodo(G: TGPGraphics; X, Y, W, H: Single;
  CTop, CBot, CBorde: TColor; R: Single = 5);
var
  Path, Shadow: TGPGraphicsPath;
  Brush: TGPLinearGradientBrush;
  Pen: TGPPen;
  SBrush: TGPSolidBrush;
begin
  // Sombra (desplazada 2px, semitransparente)
  Shadow := RoundPath(X + 2, Y + 3, W, H, R);
  SBrush := TGPSolidBrush.Create(GP(clBlack, 28));
  G.FillPath(SBrush, Shadow);
  SBrush.Free; Shadow.Free;

  Path := RoundPath(X, Y, W, H, R);
  Brush := TGPLinearGradientBrush.Create(
    MakeRect(X, Y - 1, W, H + 2), GP(CTop), GP(CBot), LinearGradientModeVertical);
  G.FillPath(Brush, Path);
  Pen := TGPPen.Create(GP(CBorde), 1);
  G.DrawPath(Pen, Path);
  Pen.Free; Brush.Free; Path.Free;
end;

// Texto antialiased.
procedure GpText(G: TGPGraphics; const S: string; X, Y: Single;
  AColor: TColor; ASize: Single = 9; ABold: Boolean = False;
  ACenterW: Single = 0);
var
  Font: TGPFont;
  Brush: TGPSolidBrush;
  Fmt: TGPStringFormat;
  Rect: TGPRectF;
  Style: Integer;
var
  H: Single;
begin
  if ABold then Style := 1 else Style := 0;
  Font := TGPFont.Create('Segoe UI', ASize, Style, UnitPoint);
  Brush := TGPSolidBrush.Create(GP(AColor));
  Fmt := TGPStringFormat.Create;
  // Altura del rect proporcional al tamano: con fuentes grandes (p.ej. 34pt) un
  // alto fijo de 24px recortaba el glifo. ASize(pt) ~ ASize*1.6 px, con margen.
  H := ASize * 2.2 + 6;
  if ACenterW > 0 then
  begin
    Fmt.SetAlignment(StringAlignmentCenter);
    Rect := MakeRect(X, Y, ACenterW, H);
  end
  else
    Rect := MakeRect(X, Y, Single(4000.0), H);
  G.DrawString(S, -1, Font, Rect, Fmt, Brush);
  Fmt.Free; Brush.Free; Font.Free;
end;

// Flecha de flujo (linea + cabeza) horizontal o vertical.
procedure GpFlecha(G: TGPGraphics; X1, Y1, X2, Y2: Single; AColor: TColor);
var
  Pen: TGPPen;
  ang: Double;
  hx, hy: Single;
begin
  Pen := TGPPen.Create(GP(AColor), 2);
  G.DrawLine(Pen, X1, Y1, X2, Y2);
  ang := ArcTan2(Y2 - Y1, X2 - X1);
  hx := X2 - 7 * Cos(ang - 0.5); hy := Y2 - 7 * Sin(ang - 0.5);
  G.DrawLine(Pen, X2, Y2, hx, hy);
  hx := X2 - 7 * Cos(ang + 0.5); hy := Y2 - 7 * Sin(ang + 0.5);
  G.DrawLine(Pen, X2, Y2, hx, hy);
  Pen.Free;
end;

// Panel de fondo redondeado (zona/timeline).
procedure GpPanel(G: TGPGraphics; X, Y, W, H: Single; AFill, ABorde: TColor;
  R: Single = 6);
var
  Path: TGPGraphicsPath;
  B: TGPSolidBrush;
  P: TGPPen;
begin
  Path := RoundPath(X, Y, W, H, R);
  B := TGPSolidBrush.Create(GP(AFill));
  G.FillPath(B, Path);
  P := TGPPen.Create(GP(ABorde), 1);
  G.DrawPath(P, Path);
  P.Free; B.Free; Path.Free;
end;

// Crea el TGPGraphics sobre el PaintBox, limpia el fondo y devuelve el handle.
function NuevoLienzo(PB: TPaintBox): TGPGraphics;
begin
  Result := TGPGraphics.Create(PB.Canvas.Handle);
  Result.SetSmoothingMode(SmoothingModeAntiAlias);
  Result.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);
  PB.Canvas.Brush.Color := CLR_BG;
  PB.Canvas.Brush.Style := bsSolid;
  PB.Canvas.FillRect(PB.ClientRect);
end;

// Dibuja una fila de N nodos (con clamp visual y "+N"). Devuelve X final.
procedure GpFilaNodos(G: TGPGraphics; X, Y, MaxW: Single; N: Integer;
  CTop, CBot, CBorde: TColor; const Etiqueta: string);
const
  NW = 26; NH = 20; GAP = 6; MAXSHOW = 16;
var
  I, Shown: Integer;
  CX: Single;
begin
  if Etiqueta <> '' then
  begin
    GpText(G, Etiqueta, X, Y, CLR_TXT_SOFT, 8.5);
    Y := Y + 19;
  end;
  Shown := Min(N, MAXSHOW);
  CX := X;
  for I := 0 to Shown - 1 do
  begin
    GpNodo(G, CX, Y, NW, NH, CTop, CBot, CBorde);
    CX := CX + NW + GAP;
    if CX + NW > X + MaxW then Break;
  end;
  if N > Shown then
    GpText(G, '+' + IntToStr(N - Shown), CX + 2, Y + 2, CLR_TXT, 9, True);
end;

// ---------------------------------------------------------------------------
// Pagina 1: granularidad (origen -> flecha -> resultado)
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedWizard.pbIlustracionPaint(Sender: TObject);
var
  G: TGPGraphics;
  W: Single;
  Gran: TSchedAgrupacion;
begin
  G := NuevoLienzo(pbIlustracion);
  try
    W := pbIlustracion.ClientWidth - 24;
    Gran := GranularidadElegida;

    // Origen
    GpPanel(G, 8, 6, W + 8, 52, CLR_PANEL, CLR_PANEL_BD);
    GpFilaNodos(G, 18, 12, W - 8, FInfo.NumOP,
      CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD,
      Format('Selecci'#243'n:  %d operaciones (OP)  ·  %d OF', [FInfo.NumOP, FInfo.NumOF]));

    // Flecha de transformacion
    GpFlecha(G, 30, 64, 30, 82, CLR_FLECHA);
    case Gran of
      agTodo:     GpText(G, 'agrupar todo', 44, 66, CLR_ACCENT, 8.5, True);
      agPorCentro:GpText(G, 'agrupar por centro', 44, 66, CLR_ACCENT, 8.5, True);
    else          GpText(G, 'sin agrupar', 44, 66, CLR_ACCENT, 8.5, True);
    end;

    // Resultado destacado (verde)
    GpPanel(G, 8, 88, W + 8, 52, CLR_PANEL, CLR_PANEL_BD);
    case Gran of
      agTodo:
        GpFilaNodos(G, 18, 94, W - 8, 1, CLR_GREEN_TOP, CLR_GREEN_BOT, CLR_GREEN_BD,
          'Resultado:  1 nodo  (suma de duraciones)');
      agPorCentro:
        GpFilaNodos(G, 18, 94, W - 8, FInfo.NumCentros, CLR_GREEN_TOP, CLR_GREEN_BOT, CLR_GREEN_BD,
          Format('Resultado:  %d nodos  (uno por centro)', [FInfo.NumCentros]));
    else
        GpFilaNodos(G, 18, 94, W - 8, FInfo.NumOP, CLR_GREEN_TOP, CLR_GREEN_BOT, CLR_GREEN_BD,
          Format('Resultado:  %d nodos  (uno por operaci'#243'n)', [FInfo.NumOP]));
    end;
  finally
    G.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Pagina 2: centro destino (varios centros -> 1)
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedWizard.pbCentroPaint(Sender: TObject);
var
  G: TGPGraphics;
  I, NC: Integer;
  Y, ColX, DestX, DestY: Single;
  Destino: string;
begin
  G := NuevoLienzo(pbCentro);
  try
    NC := Min(Length(FInfo.Centros), 5);
    GpText(G, Format('%d operaciones en %d centros  →  1 nodo en el centro elegido',
      [FInfo.NumOP, FInfo.NumCentros]), 12, 6, CLR_TXT, 9, True);

    // Columna izquierda: centros origen
    ColX := 20; Y := 34;
    for I := 0 to NC - 1 do
    begin
      GpNodo(G, ColX, Y, 150, 24, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD, 5);
      GpText(G, NombreCentro(FInfo.Centros[I]), ColX + 10, Y + 4, clWhite, 8.5);
      // flecha hacia el destino
      GpFlecha(G, ColX + 158, Y + 12, 320, 96, CLR_FLECHA);
      Y := Y + 32;
    end;
    if Length(FInfo.Centros) > NC then
      GpText(G, Format('+%d centros m'#225's', [Length(FInfo.Centros) - NC]),
        ColX + 4, Y, CLR_TXT_SOFT, 8.5);

    // Nodo destino (verde, grande)
    if Trim(cbCentroDestino.Text) <> '' then Destino := NombreCentro(cbCentroDestino.Text)
    else Destino := '(elige centro)';
    DestX := 330; DestY := 78;
    GpNodo(G, DestX, DestY, 210, 40, CLR_GREEN_TOP, CLR_GREEN_BOT, CLR_GREEN_BD, 6);
    GpText(G, '1 nodo agrupado', DestX, DestY + 5, clWhite, 9, True, 210);
    GpText(G, Destino, DestX, DestY + 21, clWhite, 8.5, False, 210);
  finally
    G.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Pagina 3: temporal (forward vs backward sobre un timeline)
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedWizard.pbTemporalPaint(Sender: TObject);
var
  G: TGPGraphics;
  W, BaseY, X: Single;
  I: Integer;
  EsForward: Boolean;
begin
  G := NuevoLienzo(pbTemporal);
  try
    EsForward := rbForward.Checked;
    W := pbTemporal.ClientWidth - 24;

    // Timeline (panel + marcas de dia)
    GpPanel(G, 12, 40, W, 70, CLR_PANEL, CLR_PANEL_BD);
    BaseY := 70;
    for I := 0 to 6 do
    begin
      X := 24 + I * ((W - 24) / 6);
      GpText(G, 'd'+IntToStr(I+1), X - 6, 92, CLR_TXT_SOFT, 7.5);
    end;

    if EsForward then
    begin
      GpText(G, 'HACIA DELANTE — empieza en la fecha base y avanza ocupando huecos',
        16, 14, CLR_ACCENT, 9, True);
      // Marcador "hoy" a la izquierda + nodos crecientes hacia la derecha
      GpText(G, 'inicio', 20, 50, CLR_TXT_SOFT, 7.5);
      for I := 0 to 3 do
        GpNodo(G, 26 + I * 64, BaseY - 6, 52, 22, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD);
      GpFlecha(G, 24, BaseY + 24, W - 6, BaseY + 24, CLR_ACCENT);
    end
    else
    begin
      GpText(G, 'HACIA ATR'#193'S — termina en la fecha de entrega y retrocede',
        16, 14, CLR_ACCENT, 9, True);
      GpText(G, 'entrega', W - 50, 50, CLR_TXT_SOFT, 7.5);
      for I := 0 to 3 do
        GpNodo(G, (W - 52) - I * 64, BaseY - 6, 52, 22, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD);
      GpFlecha(G, W - 6, BaseY + 24, 24, BaseY + 24, CLR_ACCENT);
    end;
  finally
    G.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Pagina 4: estrategia de cola - tres niveles (basico / canonica / perfil).
// Ilustra una "cola" de tarjetas-OP y como cada estrategia decide su orden.
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedWizard.pbEstrategiaPaint(Sender: TObject);
var
  G: TGPGraphics;
  W, Y: Single;
  I: Integer;
  Titulo, Sub: string;
begin
  G := NuevoLienzo(pbEstrategia);
  try
    W := pbEstrategia.ClientWidth - 24;

    if EstrategiaEsCanonica then
    begin
      Titulo := 'Reglas industriales';
      Sub := 'La cola se ordena por una regla profesional (EDD, SPT, Slack...). '+
             'Elegir'#225's la regla concreta en el siguiente paso.';
    end
    else if rbEstrPersonalizada.Checked then
    begin
      Titulo := 'Perfiles del cliente';
      Sub := 'La cola se ordena con un perfil propio (campos a medida, '+
             'multicriterio). Elegir'#225's el perfil en el siguiente paso.';
    end
    else
    begin
      Titulo := 'B'#225'sico';
      Sub := 'La cola se ordena por fecha de compromiso o por prioridad. '+
             'Sencillo y suficiente para la mayor'#237'a de casos.';
    end;

    GpText(G, Titulo, 12, 8, CLR_ACCENT, 12, True);
    GpText(G, Sub, 12, 34, CLR_TXT, 9.5);

    // Cola ilustrada: una fila de tarjetas-OP con una flecha de "orden".
    Y := 80;
    GpText(G, 'Cola de operaciones (orden de entrada al apilado FCS):',
      12, Y, CLR_TXT_SOFT, 9, True);
    GpPanel(G, 12, Y + 24, W, 70, CLR_PANEL, CLR_PANEL_BD);
    for I := 0 to Min(6, FInfo.NumOP) - 1 do
      GpNodo(G, 28 + I * 96, Y + 40, 80, 30,
        CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD);
    if FInfo.NumOP > 7 then
      GpText(G, '...', 28 + 7 * 96, Y + 46, CLR_TXT, 12, True);
    GpFlecha(G, 28, Y + 108, W - 12, Y + 108, CLR_ACCENT);
    GpText(G, '1'#186, 30, Y + 112, CLR_TXT_SOFT, 8);
    GpText(G, #250'ltimo', W - 60, Y + 112, CLR_TXT_SOFT, 8);

    // Pista del impacto.
    GpText(G,
      'El orden de la cola decide QUE se planifica primero cuando varias '+
      'operaciones compiten por el mismo centro.',
      12, Y + 140, CLR_TXT_SOFT, 9);
  finally
    G.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Pagina 5: detalle de la regla - vista previa de la cola REORDENADA en vivo.
// Para reglas canonicas reordena una copia de FInputs con SortInputsByRuleSet y
// muestra las primeras OP en el orden que produciria la regla.
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedWizard.pbReglaPaint(Sender: TObject);
var
  G: TGPGraphics;
  W, Y: Single;
  I, NShow: Integer;
  Copia: TArray<TSchedInput>;
  RS: TPriorityRuleSet;
  Etiqueta, Titulo: string;
begin
  G := NuevoLienzo(pbRegla);
  try
    W := pbRegla.ClientWidth - 24;

    if rbEstrPersonalizada.Checked then
    begin
      Titulo := 'Perfil:  ' + cbReglaPerfil.Text;
      GpText(G, Titulo, 12, 8, CLR_ACCENT, 12, True);
      GpText(G,
        'El perfil del cliente ordena los NODOS con sus campos a medida. '+
        'En esta primera planificaci'#243'n se aplicar'#225' al crear los nodos; el '+
        'detalle multicriterio se gestiona en "Reglas de Planificaci'#243'n".',
        12, 36, CLR_TXT, 9.5);
      Exit;
    end;

    // Canonica: vista previa real de la cola reordenada.
    Titulo := 'Regla:  ' + PriorityRuleToStr(ReglaCanonicaElegida);
    GpText(G, Titulo, 12, 8, CLR_ACCENT, 12, True);
    GpText(G, 'Vista previa de las primeras operaciones, ya ordenadas por la regla:',
      12, 36, CLR_TXT, 9.5);

    // Reordenar una COPIA (no tocar FInputs) con el RuleSet vigente.
    Copia := Copy(FInputs, 0, Length(FInputs));
    RS := FRuleSet;
    RS.Principal := ReglaCanonicaElegida;
    SortInputsByRuleSet(Copia, RS, dtFechaBase.Date);

    Y := 66;
    NShow := Min(7, Length(Copia));
    // Panel alto suficiente para los NShow nodos + la linea "... y N mas":
    // 12 (margen sup) + NShow*28 (nodos) + 26 (linea resumen + margen inf).
    GpPanel(G, 12, Y, W, 12 + NShow * 28 + 26, CLR_PANEL, CLR_PANEL_BD);
    for I := 0 to NShow - 1 do
    begin
      GpNodo(G, 28, Y + 12 + I * 28, 40, 22,
        CLR_GREEN_TOP, CLR_GREEN_BOT, CLR_GREEN_BD);
      GpText(G, IntToStr(I + 1) + #186, 28, Y + 16 + I * 28, clWhite, 8.5, True, 40);
      // Etiqueta legible de la OP: documento + fecha compromiso + horas.
      Etiqueta := Copia[I].CodigoDocumento;
      if Trim(Etiqueta) = '' then Etiqueta := 'OP ' + IntToStr(Copia[I].RawId);
      if Copia[I].FechaCompromiso > 0 then
        Etiqueta := Etiqueta + '   ·   entrega ' +
          FormatDateTime('dd/mm', Copia[I].FechaCompromiso);
      Etiqueta := Etiqueta + Format('   ·   %.1f h   ·   prio %d',
        [Copia[I].HorasEstimadas, Copia[I].Prioridad]);
      GpText(G, Etiqueta, 80, Y + 15 + I * 28, CLR_TXT, 9);
    end;
    if Length(Copia) > NShow then
      GpText(G, Format('... y %d operaciones m'#225's', [Length(Copia) - NShow]),
        80, Y + 14 + NShow * 28, CLR_TXT_SOFT, 9);

    // Texto de ayuda por DEBAJO del panel (panel alto = 12+NShow*28+26).
    GpText(G,
      'Usa "Configurar desempates..." para afinar c'#243'mo se rompen los empates '+
      'y los overrides por centro.',
      12, Y + (12 + NShow * 28 + 26) + 10, CLR_TXT_SOFT, 9);
  finally
    G.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Pagina 6: ajustes - ilustracion ESPECIFICA de cada politica de colocacion.
// Una "pista" con dos nodos existentes (A y B) y un hueco entre ellos; segun la
// politica elegida en cbPlacement se muestra donde aterriza el nodo nuevo (N).
//   ppFinCola    -> N siempre detras del ultimo (ignora el hueco)
//   ppHueco      -> N entra en el hueco (si cabe segun umbrales)
//   ppHuecoShift -> N entra en el hueco y empuja a los posteriores
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedWizard.pbAjustesPaint(Sender: TObject);
var
  G: TGPGraphics;
  W, Y, PistaX, PistaW: Single;
  Pol: Integer;
  Titulo, Desc: string;

  procedure NodoEtq(X, Yn, Wn: Single; CT, CB, CBd: TColor; const Et: string;
    ECol: TColor);
  begin
    GpNodo(G, X, Yn, Wn, 26, CT, CB, CBd);
    GpText(G, Et, X, Yn + 5, ECol, 9, True, Wn);
  end;

begin
  G := NuevoLienzo(pbAjustes);
  try
    W := pbAjustes.ClientWidth - 24;
    Pol := cbPlacement.ItemIndex;
    if Pol < 0 then Pol := 1; // por defecto ppHueco

    case Pol of
      0: begin Titulo := 'Encolar al final';
               Desc := 'El nodo nuevo se coloca SIEMPRE detr'#225's del '#250'ltimo. No se '+
                       'aprovechan huecos: plan m'#225's simple y predecible.'; end;
      2: begin Titulo := 'Rellenar huecos y desplazar';
               Desc := 'El nodo nuevo entra en el hueco y EMPUJA a los nodos '+
                       'posteriores no bloqueados para hacerle sitio.'; end;
    else
         begin Titulo := 'Rellenar huecos';
               Desc := 'El nodo nuevo ocupa el primer hueco v'#225'lido (seg'#250'n los '+
                       'umbrales). Compacta el plan sin mover lo dem'#225's.'; end;
    end;

    GpText(G, 'Colocaci'#243'n:  ' + Titulo, 12, 6, CLR_ACCENT, 11, True);
    PistaX := 28; PistaW := W - 24;

    // ---- Pista ANTES (situacion de partida) ----
    Y := 44;
    GpText(G, 'ANTES', 16, Y, CLR_TXT_SOFT, 8.5, True);
    GpPanel(G, 12, Y + 22, W, 58, CLR_PANEL, CLR_PANEL_BD);
    NodoEtq(PistaX, Y + 36, 110, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD, 'A', clWhite);
    GpText(G, '·  hueco  ·', PistaX + 132, Y + 42, CLR_TXT_SOFT, 9, True);
    NodoEtq(PistaX + 270, Y + 36, 110, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD, 'B', clWhite);

    // ---- Pista DESPUES (resultado segun politica) ----
    Y := 150;
    GpText(G, 'DESPU'#201'S', 16, Y, CLR_TXT_SOFT, 8.5, True);
    GpPanel(G, 12, Y + 22, W, 58, CLR_PANEL, CLR_PANEL_BD);
    case Pol of
      0: // fin de cola: A, B y luego N al final
        begin
          NodoEtq(PistaX, Y + 36, 110, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD, 'A', clWhite);
          GpText(G, '·  hueco  ·', PistaX + 132, Y + 42, CLR_TXT_SOFT, 9, True);
          NodoEtq(PistaX + 270, Y + 36, 110, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD, 'B', clWhite);
          NodoEtq(PistaX + 390, Y + 36, 110, CLR_GREEN_TOP, CLR_GREEN_BOT, CLR_GREEN_BD, 'N', clWhite);
        end;
      2: // hueco + desplazar: A, N en el hueco, B empujado a la derecha
        begin
          NodoEtq(PistaX, Y + 36, 110, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD, 'A', clWhite);
          NodoEtq(PistaX + 122, Y + 36, 110, CLR_GREEN_TOP, CLR_GREEN_BOT, CLR_GREEN_BD, 'N', clWhite);
          GpFlecha(G, PistaX + 240, Y + 26, PistaX + 270, Y + 26, CLR_ACCENT);
          NodoEtq(PistaX + 250, Y + 36, 110, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD, 'B', clWhite);
        end;
    else // hueco: A, N en el hueco, B donde estaba
        begin
          NodoEtq(PistaX, Y + 36, 110, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD, 'A', clWhite);
          NodoEtq(PistaX + 132, Y + 36, 110, CLR_GREEN_TOP, CLR_GREEN_BOT, CLR_GREEN_BD, 'N', clWhite);
          NodoEtq(PistaX + 270, Y + 36, 110, CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD, 'B', clWhite);
        end;
    end;

    // ---- Descripcion + umbrales (con margen amplio bajo la pista) ----
    GpText(G, Desc, 14, Y + 96, CLR_TXT, 9.5);
    GpText(G,
      Format('Hueco m'#237'n. %d min      %d%% del nodo m'#237'n. en el hueco      '+
             'distancia entre nodos %d min',
        [seHueco.Value, sePct.Value, seDist.Value]),
      14, Y + 120, CLR_TXT_SOFT, 9);
  finally
    G.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Pagina 5: resumen (tarjeta de resultado destacada)
// ---------------------------------------------------------------------------
procedure TfrmBacklogSchedWizard.pbResumenPaint(Sender: TObject);
const
  CardX = 12; CardY = 10; CardW = 168; CardH = 108;
var
  G: TGPGraphics;
  W: Single;
  N: Integer;
  Dir, Cent, Etiq: string;
begin
  G := NuevoLienzo(pbResumen);
  try
    W := pbResumen.ClientWidth - 24;
    case GranularidadElegida of
      agTodo: N := 1;
      agPorCentro: N := FInfo.NumCentros;
    else N := FInfo.NumOP;
    end;

    // ---- Tarjeta-resultado grande (verde) ----
    GpPanel(G, CardX, CardY, CardW, CardH, CLR_GREEN_TOP, CLR_GREEN_BD, 10);
    // numero protagonista, centrado horizontal y vertical dentro de la tarjeta
    GpText(G, IntToStr(N), CardX, CardY + 14, clWhite, 40, True, CardW);
    if N = 1 then Etiq := 'NODO EN EL GANTT' else Etiq := 'NODOS EN EL GANTT';
    GpText(G, Etiq, CardX, CardY + 82, clWhite, 8.5, True, CardW);

    // ---- Detalle a la derecha de la tarjeta ----
    GpText(G, Format('%d operaciones (OP)', [FInfo.NumOP]), 198, CardY + 6, CLR_TXT, 11, True);
    GpText(G, Format('en %d '#243'rden(es) de fabricaci'#243'n', [FInfo.NumOF]), 198, CardY + 28, CLR_TXT_SOFT, 9);

    if rbBackward.Checked then Dir := 'Direcci'#243'n:  hacia atr'#225's (desde la entrega)'
    else Dir := 'Direcci'#243'n:  hacia delante (desde ' + FormatDateTime('dd/mm/yyyy', dtFechaBase.Date) + ')';
    GpText(G, Dir, 198, CardY + 52, CLR_TXT, 9);

    if NecesitaPasoCentro then Cent := 'Centro:  ' + NombreCentro(cbCentroDestino.Text)
    else if (GranularidadElegida = agTodo) and (Length(FInfo.Centros) > 0) then
      Cent := 'Centro:  ' + NombreCentro(FInfo.Centros[0])
    else if GranularidadElegida = agPorCentro then Cent := 'Agrupaci'#243'n:  un nodo por centro'
    else Cent := 'Agrupaci'#243'n:  cada OP en su centro';
    GpText(G, Cent, 198, CardY + 74, CLR_TXT, 9);

    case GranularidadElegida of
      agTodo:      Etiq := 'Agrupaci'#243'n:  toda la selecci'#243'n en 1 nodo';
      agPorCentro: Etiq := Format('Resultado:  %d lote(s) por centro', [FInfo.NumCentros]);
    else           Etiq := 'Resultado:  m'#225'ximo detalle (1 nodo por OP)';
    end;
    GpText(G, Etiq, 198, CardY + 96, CLR_TXT_SOFT, 9);

    // ---- Mini-flujo abajo: OP de origen  ->  nodos resultantes ----
    // Con el lienzo mas alto, separamos bien las dos filas para que ni los
    // nodos ni sus etiquetas queden cortados.
    GpText(G, 'Transformaci'#243'n de la selecci'#243'n', 14, 150, CLR_TXT, 10, True);
    GpPanel(G, 12, 176, W, 150, CLR_PANEL, CLR_PANEL_BD);
    GpFilaNodos(G, 28, 190, W - 32, FInfo.NumOP,
      CLR_NODO_TOP, CLR_NODO_BOT, CLR_NODO_BD,
      Format('%d operaciones seleccionadas (OP)', [FInfo.NumOP]));
    GpFlecha(G, 44, 246, 44, 268, CLR_FLECHA);
    GpFilaNodos(G, 28, 262, W - 32, N,
      CLR_GREEN_TOP, CLR_GREEN_BOT, CLR_GREEN_BD,
      Format('%d nodo(s) que se crear'#225'n en el Gantt', [N]));

    // Pista hacia el boton "Ver tiempos calculados".
    GpText(G,
      'Para ver el inicio y fin reales de cada operaci'#243'n (y la ventana total),'+
      ' pulsa "Ver tiempos calculados".',
      14, 360, CLR_TXT_SOFT, 9);
  finally
    G.Free;
  end;
end;

end.
