unit uSincronizarERP;
// ============================================================================
// Form de sincronizacion ERP -> FS_PL_*.
//
// Agnostico del ERP concreto: usa GetActiveErpReader y los records neutros.
// La logica de diff/MERGE vive en uErpSyncRepo.
//
// Seleccion de filas a aplicar: nativa del cxGrid (CheckBoxVisibility =
// [cbvDataRow, cbvColumnHeader] -> el grid muestra checkbox en cada fila y
// uno en la cabecera que selecciona/desmarca todo automaticamente).
// ============================================================================
interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants, System.DateUtils,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxDropDownEdit, cxCalendar, cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxPC,
  uErpReader, uErpTypes, uErpSyncTypes, uErpSyncRepo, dxBarBuiltInMenu,
  dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinCaramel,
  dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue;
type
  TfrmSincronizarERP = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    lblErpSistema: TLabel;
    pnlToolbar: TPanel;
    btnPreview: TButton;
    btnSync: TButton;
    btnHelp: TButton;
    lblCalRango: TLabel;
    dtCalDesde: TcxDateEdit;
    dtCalHasta: TcxDateEdit;
    pnlBottom: TPanel;
    lblSummary: TLabel;
    btnClose: TButton;
    pc: TcxPageControl;
    tabResumen: TcxTabSheet;
    gridResumen: TcxGrid;
    tvResumen: TcxGridTableView;
    colREntidad: TcxGridColumn;
    colRNuevos: TcxGridColumn;
    colRActualizados: TcxGridColumn;
    colRSinCambios: TcxGridColumn;
    colRConflictos: TcxGridColumn;
    colREliminados: TcxGridColumn;
    colRTotal: TcxGridColumn;
    lvResumen: TcxGridLevel;
    tabCentros: TcxTabSheet;
    gridCentros: TcxGrid;
    tvCentros: TcxGridTableView;
    colCEstado: TcxGridColumn;
    colCCodigo: TcxGridColumn;
    colCDescripcion: TcxGridColumn;
    colCLocalTitulo: TcxGridColumn;
    colCConcurrencia: TcxGridColumn;
    colCMaquinas: TcxGridColumn;
    colCCoste: TcxGridColumn;
    colCGrupoHorario: TcxGridColumn;
    colCAccion: TcxGridColumn;
    lvCentros: TcxGridLevel;
    tabMaquinas: TcxTabSheet;
    gridMaquinas: TcxGrid;
    tvMaquinas: TcxGridTableView;
    colMEstado: TcxGridColumn;
    colMCodigo: TcxGridColumn;
    colMMarca: TcxGridColumn;
    colMModelo: TcxGridColumn;
    colMDescripcion: TcxGridColumn;
    colMCoste: TcxGridColumn;
    colMUnidHora: TcxGridColumn;
    colMLocalCodigo: TcxGridColumn;
    colMAccion: TcxGridColumn;
    lvMaquinas: TcxGridLevel;
    tabOperarios: TcxTabSheet;
    gridOperarios: TcxGrid;
    tvOperarios: TcxGridTableView;
    colOEstado: TcxGridColumn;
    colOCodigo: TcxGridColumn;
    colONombre: TcxGridColumn;
    colOCargo: TcxGridColumn;
    colOCosteNormal: TcxGridColumn;
    colOCosteExtra: TcxGridColumn;
    colOGrupoHorario: TcxGridColumn;
    colOEmail: TcxGridColumn;
    colOLocalNombre: TcxGridColumn;
    colOAccion: TcxGridColumn;
    lvOperarios: TcxGridLevel;
    tabCentroMaquina: TcxTabSheet;
    gridCentroMaquina: TcxGrid;
    tvCentroMaquina: TcxGridTableView;
    colCMEstado: TcxGridColumn;
    colCMCentro: TcxGridColumn;
    colCMMaquina: TcxGridColumn;
    colCMOrden: TcxGridColumn;
    colCMCoste: TcxGridColumn;
    colCMCorrPrep: TcxGridColumn;
    colCMCorrFab: TcxGridColumn;
    colCMError: TcxGridColumn;
    colCMAccion: TcxGridColumn;
    lvCentroMaquina: TcxGridLevel;
    tabModelos: TcxTabSheet;
    gridModelos: TcxGrid;
    tvModelos: TcxGridTableView;
    colHMEstado: TcxGridColumn;
    colHMCodigo: TcxGridColumn;
    colHMDescripcion: TcxGridColumn;
    colHMNumLineas: TcxGridColumn;
    colHMLocalNombre: TcxGridColumn;
    colHMAccion: TcxGridColumn;
    lvModelos: TcxGridLevel;
    tabAlmacenes: TcxTabSheet;
    gridAlmacenes: TcxGrid;
    tvAlmacenes: TcxGridTableView;
    colALEstado: TcxGridColumn;
    colALCodigo: TcxGridColumn;
    colALNombre: TcxGridColumn;
    colALGrupo: TcxGridColumn;
    colALResponsable: TcxGridColumn;
    colALMunicipio: TcxGridColumn;
    colALProvincia: TcxGridColumn;
    colALLocalNombre: TcxGridColumn;
    colALAccion: TcxGridColumn;
    lvAlmacenes: TcxGridLevel;
    tabFamilias: TcxTabSheet;
    gridFamilias: TcxGrid;
    tvFamilias: TcxGridTableView;
    colFAEstado: TcxGridColumn;
    colFAFamilia: TcxGridColumn;
    colFASubfamilia: TcxGridColumn;
    colFADescripcion: TcxGridColumn;
    colFATipo: TcxGridColumn;
    colFASeccion: TcxGridColumn;
    colFADepartamento: TcxGridColumn;
    colFALocalDesc: TcxGridColumn;
    colFAAccion: TcxGridColumn;
    lvFamilias: TcxGridLevel;
    tabCalendarios: TcxTabSheet;
    gridCalendarios: TcxGrid;
    tvCalendarios: TcxGridTableView;
    colCAEstado: TcxGridColumn;
    colCAGrupo: TcxGridColumn;
    colCALocalNombre: TcxGridColumn;
    colCADiasTotales: TcxGridColumn;
    colCADiasLab: TcxGridColumn;
    colCADiasFest: TcxGridColumn;
    colCAAccion: TcxGridColumn;
    lvCalendarios: TcxGridLevel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure btnSyncClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure tvCentrosStylesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure tvMaquinasStylesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure tvOperariosStylesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure tvCentroMaquinaStylesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure tvModelosStylesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure tvAlmacenesStylesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure tvFamiliasStylesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure tvCalendariosStylesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure tvResumenStylesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
  private
    FReader: IErpReader;
    FRepo: TErpSyncRepo;
    FCentros: TArray<TSyncRowCentro>;
    FMaquinas: TArray<TSyncRowMaquina>;
    FOperarios: TArray<TSyncRowOperario>;
    FCentroMaquina: TArray<TSyncRowCentroMaquina>;
    FModelos: TArray<TSyncRowShiftModel>;
    FAlmacenes: TArray<TSyncRowAlmacen>;
    FFamilias: TArray<TSyncRowFamilia>;
    FCalendarios: TArray<TSyncRowCalendario>;
    FFechaCalDesde, FFechaCalHasta: TDateTime;
    FStyleRepo: TcxStyleRepository;
    // Estils per files dels grids Centros/Maquinas
    styNuevo, styActualizado, styConflicto, styEliminado, styError: TcxStyle;
    // Estils KPI per cel.les del grid Resumen
    styKpiEntidad: TcxStyle;
    styKpiNuevos, styKpiActualizados, styKpiSinCambios,
    styKpiConflictos, styKpiEliminados, styKpiTotal: TcxStyle;
    procedure BuildStyles;
    procedure RenderResumen;
    procedure InitErp;
    procedure SetupCombos;
    procedure RenderCentros;
    procedure RenderMaquinas;
    procedure RenderOperarios;
    procedure RenderCentroMaquina;
    procedure RenderModelos;
    procedure RenderAlmacenes;
    procedure RenderFamilias;
    procedure RenderCalendarios;
    procedure CollectFromGrid;
    procedure PreSelectRows;
    function StatusByRowCentro(ARecIdx: Integer): TSyncStatus;
    function StatusByRowMaquina(ARecIdx: Integer): TSyncStatus;
    function StatusByRowOperario(ARecIdx: Integer): TSyncStatus;
    function StatusByRowCentroMaquina(ARecIdx: Integer): TSyncStatus;
    function StatusByRowModelo(ARecIdx: Integer): TSyncStatus;
    function StatusByRowAlmacen(ARecIdx: Integer): TSyncStatus;
    function StatusByRowFamilia(ARecIdx: Integer): TSyncStatus;
    function StatusByRowCalendario(ARecIdx: Integer): TSyncStatus;
    function ActionFromText(const S: string): TConflictAction;
    function ActionToText(A: TConflictAction): string;
    procedure BuildSelectionSet(AView: TcxGridTableView; out ASet: array of Boolean);
  end;
implementation
{$R *.dfm}
uses
  uDMPlanner, uErpReaderFactory, uHelpViewer;
{ helpers }
function TfrmSincronizarERP.ActionFromText(const S: string): TConflictAction;
begin
  if SameText(S, 'Mantener local')   then Result := caMantenerLocal
  else if SameText(S, 'Ignorar')     then Result := caIgnorar
  else                                    Result := caAplicarErp;
end;
function TfrmSincronizarERP.ActionToText(A: TConflictAction): string;
begin
  case A of
    caAplicarErp:    Result := 'Aplicar ERP';
    caMantenerLocal: Result := 'Mantener local';
    caIgnorar:       Result := 'Ignorar';
  end;
end;
procedure TfrmSincronizarERP.SetupCombos;
var
  Items: TStringList;
  Props: TcxComboBoxProperties;
begin
  Items := TStringList.Create;
  try
    Items.Add('Aplicar ERP');
    Items.Add('Mantener local');
    Items.Add('Ignorar');
    Props := TcxComboBoxProperties(colCAccion.Properties);
    Props.Items.Assign(Items);
    Props.DropDownListStyle := lsFixedList;
    Props := TcxComboBoxProperties(colMAccion.Properties);
    Props.Items.Assign(Items);
    Props.DropDownListStyle := lsFixedList;
    Props := TcxComboBoxProperties(colOAccion.Properties);
    Props.Items.Assign(Items);
    Props.DropDownListStyle := lsFixedList;
    Props := TcxComboBoxProperties(colCMAccion.Properties);
    Props.Items.Assign(Items);
    Props.DropDownListStyle := lsFixedList;
    Props := TcxComboBoxProperties(colHMAccion.Properties);
    Props.Items.Assign(Items);
    Props.DropDownListStyle := lsFixedList;
    Props := TcxComboBoxProperties(colCAAccion.Properties);
    Props.Items.Assign(Items);
    Props.DropDownListStyle := lsFixedList;
    Props := TcxComboBoxProperties(colALAccion.Properties);
    Props.Items.Assign(Items);
    Props.DropDownListStyle := lsFixedList;
    Props := TcxComboBoxProperties(colFAAccion.Properties);
    Props.Items.Assign(Items);
    Props.DropDownListStyle := lsFixedList;
  finally
    Items.Free;
  end;
end;
procedure TfrmSincronizarERP.BuildStyles;
  function MakeStyle(AColor: TColor; ATextColor: TColor = clNone;
    ABold: Boolean = False; AFontSize: Integer = 0): TcxStyle;
  begin
    Result := TcxStyle.Create(Self);
    Result.StyleRepository := FStyleRepo;
    Result.Color := AColor;
    if ATextColor <> clNone then
      Result.TextColor := ATextColor;
    if ABold then
      Result.Font.Style := Result.Font.Style + [fsBold];
    if AFontSize > 0 then
      Result.Font.Size := AFontSize;
  end;
begin
  FStyleRepo := TcxStyleRepository.Create(Self);
  // Files de Centros/Maquinas
  styNuevo       := MakeStyle($00E8F8E8);
  styActualizado := MakeStyle($00D6F4FF);
  styConflicto   := MakeStyle($00C0C0FF);
  styEliminado   := MakeStyle($00E0E0E0);
  styError       := MakeStyle($008080FF, clWhite);
  // KPI cells (BGR hex). Caja de entidad gris-azul, conceptos coloreados.
  styKpiEntidad      := MakeStyle($00F2EBE3, clBlack, True, 11);
  styKpiNuevos       := MakeStyle($0070C070, clWhite, True, 14);  // verd
  styKpiActualizados := MakeStyle($00E0A040, clWhite, True, 14);  // blau-taronja
  styKpiSinCambios   := MakeStyle($00E8E8E8, $00808080, False, 12); // gris
  styKpiConflictos   := MakeStyle($004040E0, clWhite, True, 14);  // vermell
  styKpiEliminados   := MakeStyle($00808080, clWhite, True, 12);  // gris fosc
  styKpiTotal        := MakeStyle($00333333, clWhite, True, 14);  // negre
end;
procedure TfrmSincronizarERP.FormCreate(Sender: TObject);
begin
  tvCentros.OptionsData.Editing := True;
  tvMaquinas.OptionsData.Editing := True;
  tvOperarios.OptionsData.Editing := True;
  tvCentroMaquina.OptionsData.Editing := True;
  tvModelos.OptionsData.Editing := True;
  tvAlmacenes.OptionsData.Editing := True;
  tvFamilias.OptionsData.Editing := True;
  tvCalendarios.OptionsData.Editing := True;
  BuildStyles;
  SetupCombos;
  // Rango por defecto del calendario laboral: an~o en curso
  dtCalDesde.Date := EncodeDate(YearOf(Date), 1, 1);
  dtCalHasta.Date := EncodeDate(YearOf(Date), 12, 31);
end;
procedure TfrmSincronizarERP.FormDestroy(Sender: TObject);
begin
  FRepo.Free;
  FReader := nil;
end;
procedure TfrmSincronizarERP.FormShow(Sender: TObject);
begin
  InitErp;
end;
procedure TfrmSincronizarERP.InitErp;
begin
  try
    FReader := GetActiveErpReaderOrRaise;
    FReader.EnsureConnected;
    lblErpSistema.Caption := 'ERP: ' + FReader.GetSistemaNombre;
    if FRepo = nil then
      FRepo := TErpSyncRepo.Create(
        DMPlanner.ADOConnection,
        DMPlanner.CodigoEmpresa,
        FReader.GetSistemaNombre);
    btnPreview.Enabled := True;
    btnSync.Enabled := True;
  except
    on E: Exception do
    begin
      lblErpSistema.Caption := 'ERP: no configurado';
      btnPreview.Enabled := False;
      btnSync.Enabled := False;
      MessageDlg('No se pudo conectar al ERP:'#13#10 + E.Message,
        mtWarning, [mbOK], 0);
    end;
  end;
end;
procedure TfrmSincronizarERP.btnCloseClick(Sender: TObject);
begin
  Close;
end;
procedure TfrmSincronizarERP.btnPreviewClick(Sender: TObject);
begin
  if FReader = nil then begin InitErp; if FReader = nil then Exit; end;
  Screen.Cursor := crHourGlass;
  try
    FCentros := FRepo.PreviewCentros(FReader);
    FMaquinas := FRepo.PreviewMaquinas(FReader);
    FOperarios := FRepo.PreviewOperarios(FReader);
    FCentroMaquina := FRepo.PreviewCentroMaquina(FReader);
    FModelos := FRepo.PreviewShiftModels(FReader);
    FAlmacenes := FRepo.PreviewAlmacenes(FReader);
    FFamilias := FRepo.PreviewFamilias(FReader);
    // Calendari laboral: rang triat per l'usuari (date pickers al toolbar)
    FFechaCalDesde := Trunc(dtCalDesde.Date);
    FFechaCalHasta := Trunc(dtCalHasta.Date);
    if (FFechaCalDesde = 0) or (FFechaCalHasta = 0) or (FFechaCalDesde > FFechaCalHasta) then
    begin
      FFechaCalDesde := EncodeDate(YearOf(Date), 1, 1);
      FFechaCalHasta := EncodeDate(YearOf(Date), 12, 31);
    end;
    FCalendarios := FRepo.PreviewCalendarios(FReader, FFechaCalDesde, FFechaCalHasta);
    RenderCentros;
    RenderMaquinas;
    RenderOperarios;
    RenderCentroMaquina;
    RenderModelos;
    RenderAlmacenes;
    RenderFamilias;
    RenderCalendarios;
    PreSelectRows;
    RenderResumen;
    pc.ActivePage := tabResumen;
  finally
    Screen.Cursor := crDefault;
  end;
end;
procedure TfrmSincronizarERP.RenderCentros;
var
  I: Integer;
  R: TSyncRowCentro;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  tvCentros.BeginUpdate;
  try
    tvCentros.DataController.RecordCount := 0;
    tvCentros.DataController.RecordCount := Length(FCentros);
    for I := 0 to High(FCentros) do
    begin
      R := FCentros[I];
      tvCentros.DataController.Values[I, colCEstado.Index]       := SyncStatusToText(R.Status);
      tvCentros.DataController.Values[I, colCCodigo.Index]       := R.ErpData.Codigo;
      tvCentros.DataController.Values[I, colCDescripcion.Index]  := R.ErpData.Descripcion;
      tvCentros.DataController.Values[I, colCLocalTitulo.Index]  := R.LocalTitulo;
      if R.ErpData.PermiteConcurrencia then
        tvCentros.DataController.Values[I, colCConcurrencia.Index] := 'Paralela'
      else
        tvCentros.DataController.Values[I, colCConcurrencia.Index] := 'Secuencial';
      tvCentros.DataController.Values[I, colCMaquinas.Index]     := R.ErpData.MaquinasFabricacion;
      tvCentros.DataController.Values[I, colCCoste.Index]        := FloatToStrF(R.ErpData.CosteHoraMaquina, ffFixed, 10, 2, FS);
      tvCentros.DataController.Values[I, colCGrupoHorario.Index] := R.ErpData.GrupoHorario;
      tvCentros.DataController.Values[I, colCAccion.Index]       := ActionToText(R.ConflictAction);
    end;
  finally
    tvCentros.EndUpdate;
  end;
end;
procedure TfrmSincronizarERP.RenderMaquinas;
var
  I: Integer;
  R: TSyncRowMaquina;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  tvMaquinas.BeginUpdate;
  try
    tvMaquinas.DataController.RecordCount := 0;
    tvMaquinas.DataController.RecordCount := Length(FMaquinas);
    for I := 0 to High(FMaquinas) do
    begin
      R := FMaquinas[I];
      tvMaquinas.DataController.Values[I, colMEstado.Index]      := SyncStatusToText(R.Status);
      tvMaquinas.DataController.Values[I, colMCodigo.Index]      := R.ErpData.Codigo;
      tvMaquinas.DataController.Values[I, colMMarca.Index]       := R.ErpData.Marca;
      tvMaquinas.DataController.Values[I, colMModelo.Index]      := R.ErpData.Modelo;
      tvMaquinas.DataController.Values[I, colMDescripcion.Index] := R.ErpData.Descripcion;
      tvMaquinas.DataController.Values[I, colMCoste.Index]       := FloatToStrF(R.ErpData.CosteHoraMaquina, ffFixed, 10, 2, FS);
      tvMaquinas.DataController.Values[I, colMUnidHora.Index]    := FloatToStrF(R.ErpData.UnidadesHora, ffFixed, 10, 2, FS);
      tvMaquinas.DataController.Values[I, colMLocalCodigo.Index] := R.LocalCodigo;
      tvMaquinas.DataController.Values[I, colMAccion.Index]      := ActionToText(R.ConflictAction);
    end;
  finally
    tvMaquinas.EndUpdate;
  end;
end;
procedure TfrmSincronizarERP.PreSelectRows;
  procedure SelectIn(AView: TcxGridTableView; AIndexes: TArray<Integer>);
  var
    I: Integer;
    Rec: TcxCustomGridRecord;
  begin
    AView.Controller.ClearSelection;
    for I := 0 to High(AIndexes) do
    begin
      if (AIndexes[I] < 0) or (AIndexes[I] >= AView.ViewData.RecordCount) then
        Continue;
      Rec := AView.ViewData.Records[AIndexes[I]];
      if Rec <> nil then
        Rec.Selected := True;
    end;
  end;
var
  I: Integer;
  IdxC, IdxM, IdxO, IdxCM, IdxHM, IdxAL, IdxFA, IdxCC: TList<Integer>;
begin
  IdxC := TList<Integer>.Create;
  IdxM := TList<Integer>.Create;
  IdxO := TList<Integer>.Create;
  IdxCM := TList<Integer>.Create;
  IdxHM := TList<Integer>.Create;
  IdxAL := TList<Integer>.Create;
  IdxFA := TList<Integer>.Create;
  IdxCC := TList<Integer>.Create;
  try
    for I := 0 to High(FCentros) do
      if FCentros[I].Status in [ssNuevo, ssActualizado] then IdxC.Add(I);
    for I := 0 to High(FMaquinas) do
      if FMaquinas[I].Status in [ssNuevo, ssActualizado] then IdxM.Add(I);
    for I := 0 to High(FOperarios) do
      if FOperarios[I].Status in [ssNuevo, ssActualizado] then IdxO.Add(I);
    for I := 0 to High(FCentroMaquina) do
      if FCentroMaquina[I].Status in [ssNuevo, ssActualizado] then IdxCM.Add(I);
    for I := 0 to High(FModelos) do
      if FModelos[I].Status in [ssNuevo, ssActualizado] then IdxHM.Add(I);
    for I := 0 to High(FAlmacenes) do
      if FAlmacenes[I].Status in [ssNuevo, ssActualizado] then IdxAL.Add(I);
    for I := 0 to High(FFamilias) do
      if FFamilias[I].Status in [ssNuevo, ssActualizado] then IdxFA.Add(I);
    for I := 0 to High(FCalendarios) do
      if FCalendarios[I].Status in [ssNuevo, ssActualizado] then IdxCC.Add(I);
    SelectIn(tvCentros, IdxC.ToArray);
    SelectIn(tvMaquinas, IdxM.ToArray);
    SelectIn(tvOperarios, IdxO.ToArray);
    SelectIn(tvCentroMaquina, IdxCM.ToArray);
    SelectIn(tvModelos, IdxHM.ToArray);
    SelectIn(tvAlmacenes, IdxAL.ToArray);
    SelectIn(tvFamilias, IdxFA.ToArray);
    SelectIn(tvCalendarios, IdxCC.ToArray);
  finally
    IdxC.Free;
    IdxM.Free;
    IdxO.Free;
    IdxCM.Free;
    IdxHM.Free;
    IdxAL.Free;
    IdxFA.Free;
    IdxCC.Free;
  end;
end;
procedure TfrmSincronizarERP.RenderOperarios;
var
  I: Integer;
  R: TSyncRowOperario;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  tvOperarios.BeginUpdate;
  try
    tvOperarios.DataController.RecordCount := 0;
    tvOperarios.DataController.RecordCount := Length(FOperarios);
    for I := 0 to High(FOperarios) do
    begin
      R := FOperarios[I];
      tvOperarios.DataController.Values[I, colOEstado.Index]       := SyncStatusToText(R.Status);
      tvOperarios.DataController.Values[I, colOCodigo.Index]       := R.ErpData.Codigo;
      tvOperarios.DataController.Values[I, colONombre.Index]       := R.ErpData.Nombre;
      tvOperarios.DataController.Values[I, colOCargo.Index]        := R.ErpData.Cargo;
      tvOperarios.DataController.Values[I, colOCosteNormal.Index]  := FloatToStrF(R.ErpData.CosteHoraNormal, ffFixed, 10, 2, FS);
      tvOperarios.DataController.Values[I, colOCosteExtra.Index]   := FloatToStrF(R.ErpData.CosteHoraExtra, ffFixed, 10, 2, FS);
      tvOperarios.DataController.Values[I, colOGrupoHorario.Index] := R.ErpData.GrupoHorario;
      tvOperarios.DataController.Values[I, colOEmail.Index]        := R.ErpData.Email;
      tvOperarios.DataController.Values[I, colOLocalNombre.Index]  := R.LocalNombre;
      tvOperarios.DataController.Values[I, colOAccion.Index]       := ActionToText(R.ConflictAction);
    end;
  finally
    tvOperarios.EndUpdate;
  end;
end;
procedure TfrmSincronizarERP.RenderCentroMaquina;
var
  I: Integer;
  R: TSyncRowCentroMaquina;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  tvCentroMaquina.BeginUpdate;
  try
    tvCentroMaquina.DataController.RecordCount := 0;
    tvCentroMaquina.DataController.RecordCount := Length(FCentroMaquina);
    for I := 0 to High(FCentroMaquina) do
    begin
      R := FCentroMaquina[I];
      tvCentroMaquina.DataController.Values[I, colCMEstado.Index]   := SyncStatusToText(R.Status);
      tvCentroMaquina.DataController.Values[I, colCMCentro.Index]   := R.ErpData.CentroTrabajo;
      tvCentroMaquina.DataController.Values[I, colCMMaquina.Index]  := R.ErpData.Maquina;
      tvCentroMaquina.DataController.Values[I, colCMOrden.Index]    := R.ErpData.Orden;
      tvCentroMaquina.DataController.Values[I, colCMCoste.Index]    := FloatToStrF(R.ErpData.CosteHoraMaquina, ffFixed, 10, 2, FS);
      tvCentroMaquina.DataController.Values[I, colCMCorrPrep.Index] := FloatToStrF(R.ErpData.PorcentajeCorreccionPreparacion, ffFixed, 10, 2, FS);
      tvCentroMaquina.DataController.Values[I, colCMCorrFab.Index]  := FloatToStrF(R.ErpData.PorcentajeCorreccionFabricacion, ffFixed, 10, 2, FS);
      tvCentroMaquina.DataController.Values[I, colCMError.Index]    := R.ErrorMsg;
      tvCentroMaquina.DataController.Values[I, colCMAccion.Index]   := ActionToText(R.ConflictAction);
    end;
  finally
    tvCentroMaquina.EndUpdate;
  end;
end;
procedure TfrmSincronizarERP.RenderModelos;
var
  I: Integer;
  R: TSyncRowShiftModel;
begin
  tvModelos.BeginUpdate;
  try
    tvModelos.DataController.RecordCount := 0;
    tvModelos.DataController.RecordCount := Length(FModelos);
    for I := 0 to High(FModelos) do
    begin
      R := FModelos[I];
      tvModelos.DataController.Values[I, colHMEstado.Index]       := SyncStatusToText(R.Status);
      tvModelos.DataController.Values[I, colHMCodigo.Index]       := R.ErpModelo.Codigo;
      tvModelos.DataController.Values[I, colHMDescripcion.Index]  := R.ErpModelo.Descripcion;
      tvModelos.DataController.Values[I, colHMNumLineas.Index]    := R.NumLineas;
      tvModelos.DataController.Values[I, colHMLocalNombre.Index]  := R.LocalNombre;
      tvModelos.DataController.Values[I, colHMAccion.Index]       := ActionToText(R.ConflictAction);
    end;
  finally
    tvModelos.EndUpdate;
  end;
end;
procedure TfrmSincronizarERP.RenderAlmacenes;
var
  I: Integer;
  R: TSyncRowAlmacen;
begin
  tvAlmacenes.BeginUpdate;
  try
    tvAlmacenes.DataController.RecordCount := 0;
    tvAlmacenes.DataController.RecordCount := Length(FAlmacenes);
    for I := 0 to High(FAlmacenes) do
    begin
      R := FAlmacenes[I];
      tvAlmacenes.DataController.Values[I, colALEstado.Index]      := SyncStatusToText(R.Status);
      tvAlmacenes.DataController.Values[I, colALCodigo.Index]      := R.ErpData.Codigo;
      tvAlmacenes.DataController.Values[I, colALNombre.Index]      := R.ErpData.Nombre;
      tvAlmacenes.DataController.Values[I, colALGrupo.Index]       := R.ErpData.GrupoAlmacen;
      tvAlmacenes.DataController.Values[I, colALResponsable.Index] := R.ErpData.Responsable;
      tvAlmacenes.DataController.Values[I, colALMunicipio.Index]   := R.ErpData.Municipio;
      tvAlmacenes.DataController.Values[I, colALProvincia.Index]   := R.ErpData.Provincia;
      tvAlmacenes.DataController.Values[I, colALLocalNombre.Index] := R.LocalNombre;
      tvAlmacenes.DataController.Values[I, colALAccion.Index]      := ActionToText(R.ConflictAction);
    end;
  finally
    tvAlmacenes.EndUpdate;
  end;
end;
procedure TfrmSincronizarERP.RenderCalendarios;
var
  I: Integer;
  R: TSyncRowCalendario;
begin
  tvCalendarios.BeginUpdate;
  try
    tvCalendarios.DataController.RecordCount := 0;
    tvCalendarios.DataController.RecordCount := Length(FCalendarios);
    for I := 0 to High(FCalendarios) do
    begin
      R := FCalendarios[I];
      tvCalendarios.DataController.Values[I, colCAEstado.Index]       := SyncStatusToText(R.Status);
      tvCalendarios.DataController.Values[I, colCAGrupo.Index]        := R.GrupoErpCodigo;
      tvCalendarios.DataController.Values[I, colCALocalNombre.Index]  := R.LocalNombre;
      tvCalendarios.DataController.Values[I, colCADiasTotales.Index]  := R.DiasTotales;
      tvCalendarios.DataController.Values[I, colCADiasLab.Index]      := R.DiasLaborables;
      tvCalendarios.DataController.Values[I, colCADiasFest.Index]     := R.DiasFestivos;
      tvCalendarios.DataController.Values[I, colCAAccion.Index]       := ActionToText(R.ConflictAction);
    end;
  finally
    tvCalendarios.EndUpdate;
  end;
end;
procedure TfrmSincronizarERP.RenderFamilias;
var
  I: Integer;
  R: TSyncRowFamilia;
begin
  tvFamilias.BeginUpdate;
  try
    tvFamilias.DataController.RecordCount := 0;
    tvFamilias.DataController.RecordCount := Length(FFamilias);
    for I := 0 to High(FFamilias) do
    begin
      R := FFamilias[I];
      tvFamilias.DataController.Values[I, colFAEstado.Index]        := SyncStatusToText(R.Status);
      tvFamilias.DataController.Values[I, colFAFamilia.Index]       := R.ErpData.CodigoFamilia;
      tvFamilias.DataController.Values[I, colFASubfamilia.Index]    := R.ErpData.CodigoSubfamilia;
      tvFamilias.DataController.Values[I, colFADescripcion.Index]   := R.ErpData.Descripcion;
      tvFamilias.DataController.Values[I, colFATipo.Index]          := R.ErpData.TipoF;
      tvFamilias.DataController.Values[I, colFASeccion.Index]       := R.ErpData.CodigoSeccion;
      tvFamilias.DataController.Values[I, colFADepartamento.Index]  := R.ErpData.CodigoDepartamento;
      tvFamilias.DataController.Values[I, colFALocalDesc.Index]     := R.LocalDescripcion;
      tvFamilias.DataController.Values[I, colFAAccion.Index]        := ActionToText(R.ConflictAction);
    end;
  finally
    tvFamilias.EndUpdate;
  end;
end;
procedure TfrmSincronizarERP.BuildSelectionSet(AView: TcxGridTableView;
  out ASet: array of Boolean);
var
  I, Idx: Integer;
begin
  for I := 0 to High(ASet) do
    ASet[I] := False;
  for I := 0 to AView.Controller.SelectedRecordCount - 1 do
  begin
    Idx := AView.Controller.SelectedRecords[I].RecordIndex;
    if (Idx >= 0) and (Idx <= High(ASet)) then
      ASet[Idx] := True;
  end;
end;
function TfrmSincronizarERP.StatusByRowCentro(ARecIdx: Integer): TSyncStatus;
begin
  if (ARecIdx < 0) or (ARecIdx > High(FCentros)) then
    Exit(ssError);
  Result := FCentros[ARecIdx].Status;
end;
function TfrmSincronizarERP.StatusByRowMaquina(ARecIdx: Integer): TSyncStatus;
begin
  if (ARecIdx < 0) or (ARecIdx > High(FMaquinas)) then
    Exit(ssError);
  Result := FMaquinas[ARecIdx].Status;
end;
function TfrmSincronizarERP.StatusByRowOperario(ARecIdx: Integer): TSyncStatus;
begin
  if (ARecIdx < 0) or (ARecIdx > High(FOperarios)) then
    Exit(ssError);
  Result := FOperarios[ARecIdx].Status;
end;
function TfrmSincronizarERP.StatusByRowCentroMaquina(ARecIdx: Integer): TSyncStatus;
begin
  if (ARecIdx < 0) or (ARecIdx > High(FCentroMaquina)) then
    Exit(ssError);
  Result := FCentroMaquina[ARecIdx].Status;
end;
function TfrmSincronizarERP.StatusByRowModelo(ARecIdx: Integer): TSyncStatus;
begin
  if (ARecIdx < 0) or (ARecIdx > High(FModelos)) then
    Exit(ssError);
  Result := FModelos[ARecIdx].Status;
end;
function TfrmSincronizarERP.StatusByRowAlmacen(ARecIdx: Integer): TSyncStatus;
begin
  if (ARecIdx < 0) or (ARecIdx > High(FAlmacenes)) then
    Exit(ssError);
  Result := FAlmacenes[ARecIdx].Status;
end;
function TfrmSincronizarERP.StatusByRowFamilia(ARecIdx: Integer): TSyncStatus;
begin
  if (ARecIdx < 0) or (ARecIdx > High(FFamilias)) then
    Exit(ssError);
  Result := FFamilias[ARecIdx].Status;
end;
function TfrmSincronizarERP.StatusByRowCalendario(ARecIdx: Integer): TSyncStatus;
begin
  if (ARecIdx < 0) or (ARecIdx > High(FCalendarios)) then
    Exit(ssError);
  Result := FCalendarios[ARecIdx].Status;
end;
procedure TfrmSincronizarERP.tvOperariosStylesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if ARecord = nil then Exit;
  case StatusByRowOperario(ARecord.RecordIndex) of
    ssNuevo:        AStyle := styNuevo;
    ssActualizado:  AStyle := styActualizado;
    ssConflicto:    AStyle := styConflicto;
    ssEliminadoErp: AStyle := styEliminado;
    ssError:        AStyle := styError;
  end;
end;
procedure TfrmSincronizarERP.tvCentroMaquinaStylesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if ARecord = nil then Exit;
  case StatusByRowCentroMaquina(ARecord.RecordIndex) of
    ssNuevo:        AStyle := styNuevo;
    ssActualizado:  AStyle := styActualizado;
    ssConflicto:    AStyle := styConflicto;
    ssEliminadoErp: AStyle := styEliminado;
    ssError:        AStyle := styError;
  end;
end;
procedure TfrmSincronizarERP.tvModelosStylesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if ARecord = nil then Exit;
  case StatusByRowModelo(ARecord.RecordIndex) of
    ssNuevo:        AStyle := styNuevo;
    ssActualizado:  AStyle := styActualizado;
    ssConflicto:    AStyle := styConflicto;
    ssEliminadoErp: AStyle := styEliminado;
    ssError:        AStyle := styError;
  end;
end;
procedure TfrmSincronizarERP.tvAlmacenesStylesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if ARecord = nil then Exit;
  case StatusByRowAlmacen(ARecord.RecordIndex) of
    ssNuevo:        AStyle := styNuevo;
    ssActualizado:  AStyle := styActualizado;
    ssConflicto:    AStyle := styConflicto;
    ssEliminadoErp: AStyle := styEliminado;
    ssError:        AStyle := styError;
  end;
end;
procedure TfrmSincronizarERP.tvFamiliasStylesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if ARecord = nil then Exit;
  case StatusByRowFamilia(ARecord.RecordIndex) of
    ssNuevo:        AStyle := styNuevo;
    ssActualizado:  AStyle := styActualizado;
    ssConflicto:    AStyle := styConflicto;
    ssEliminadoErp: AStyle := styEliminado;
    ssError:        AStyle := styError;
  end;
end;
procedure TfrmSincronizarERP.tvCalendariosStylesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if ARecord = nil then Exit;
  case StatusByRowCalendario(ARecord.RecordIndex) of
    ssNuevo:        AStyle := styNuevo;
    ssActualizado:  AStyle := styActualizado;
    ssConflicto:    AStyle := styConflicto;
    ssEliminadoErp: AStyle := styEliminado;
    ssError:        AStyle := styError;
  end;
end;
procedure TfrmSincronizarERP.tvCentrosStylesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if ARecord = nil then Exit;
  case StatusByRowCentro(ARecord.RecordIndex) of
    ssNuevo:        AStyle := styNuevo;
    ssActualizado:  AStyle := styActualizado;
    ssConflicto:    AStyle := styConflicto;
    ssEliminadoErp: AStyle := styEliminado;
    ssError:        AStyle := styError;
  end;
end;
procedure TfrmSincronizarERP.tvMaquinasStylesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if ARecord = nil then Exit;
  case StatusByRowMaquina(ARecord.RecordIndex) of
    ssNuevo:        AStyle := styNuevo;
    ssActualizado:  AStyle := styActualizado;
    ssConflicto:    AStyle := styConflicto;
    ssEliminadoErp: AStyle := styEliminado;
    ssError:        AStyle := styError;
  end;
end;
procedure TfrmSincronizarERP.tvResumenStylesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if (ARecord = nil) or (AItem = nil) then Exit;
  if AItem = colREntidad then
    AStyle := styKpiEntidad
  else if AItem = colRNuevos then
    AStyle := styKpiNuevos
  else if AItem = colRActualizados then
    AStyle := styKpiActualizados
  else if AItem = colRSinCambios then
    AStyle := styKpiSinCambios
  else if AItem = colRConflictos then
    AStyle := styKpiConflictos
  else if AItem = colREliminados then
    AStyle := styKpiEliminados
  else if AItem = colRTotal then
    AStyle := styKpiTotal;
end;
procedure TfrmSincronizarERP.CollectFromGrid;
var
  I: Integer;
  V: Variant;
  SelC, SelM, SelO, SelCM, SelHM, SelAL, SelFA, SelCC: array of Boolean;
begin
  SetLength(SelC, Length(FCentros));
  BuildSelectionSet(tvCentros, SelC);
  for I := 0 to High(FCentros) do
  begin
    FCentros[I].Aplicar := SelC[I] and
      (FCentros[I].Status in [ssNuevo, ssActualizado, ssConflicto]);
    V := tvCentros.DataController.Values[I, colCAccion.Index];
    if not VarIsNull(V) then
      FCentros[I].ConflictAction := ActionFromText(VarToStr(V));
  end;
  SetLength(SelM, Length(FMaquinas));
  BuildSelectionSet(tvMaquinas, SelM);
  for I := 0 to High(FMaquinas) do
  begin
    FMaquinas[I].Aplicar := SelM[I] and
      (FMaquinas[I].Status in [ssNuevo, ssActualizado, ssConflicto]);
    V := tvMaquinas.DataController.Values[I, colMAccion.Index];
    if not VarIsNull(V) then
      FMaquinas[I].ConflictAction := ActionFromText(VarToStr(V));
  end;
  SetLength(SelO, Length(FOperarios));
  BuildSelectionSet(tvOperarios, SelO);
  for I := 0 to High(FOperarios) do
  begin
    FOperarios[I].Aplicar := SelO[I] and
      (FOperarios[I].Status in [ssNuevo, ssActualizado, ssConflicto]);
    V := tvOperarios.DataController.Values[I, colOAccion.Index];
    if not VarIsNull(V) then
      FOperarios[I].ConflictAction := ActionFromText(VarToStr(V));
  end;
  SetLength(SelCM, Length(FCentroMaquina));
  BuildSelectionSet(tvCentroMaquina, SelCM);
  for I := 0 to High(FCentroMaquina) do
  begin
    FCentroMaquina[I].Aplicar := SelCM[I] and
      (FCentroMaquina[I].Status in [ssNuevo, ssActualizado, ssConflicto]);
    V := tvCentroMaquina.DataController.Values[I, colCMAccion.Index];
    if not VarIsNull(V) then
      FCentroMaquina[I].ConflictAction := ActionFromText(VarToStr(V));
  end;
  SetLength(SelHM, Length(FModelos));
  BuildSelectionSet(tvModelos, SelHM);
  for I := 0 to High(FModelos) do
  begin
    FModelos[I].Aplicar := SelHM[I] and
      (FModelos[I].Status in [ssNuevo, ssActualizado, ssConflicto]);
    V := tvModelos.DataController.Values[I, colHMAccion.Index];
    if not VarIsNull(V) then
      FModelos[I].ConflictAction := ActionFromText(VarToStr(V));
  end;
  SetLength(SelAL, Length(FAlmacenes));
  BuildSelectionSet(tvAlmacenes, SelAL);
  for I := 0 to High(FAlmacenes) do
  begin
    FAlmacenes[I].Aplicar := SelAL[I] and
      (FAlmacenes[I].Status in [ssNuevo, ssActualizado, ssConflicto]);
    V := tvAlmacenes.DataController.Values[I, colALAccion.Index];
    if not VarIsNull(V) then
      FAlmacenes[I].ConflictAction := ActionFromText(VarToStr(V));
  end;
  SetLength(SelFA, Length(FFamilias));
  BuildSelectionSet(tvFamilias, SelFA);
  for I := 0 to High(FFamilias) do
  begin
    FFamilias[I].Aplicar := SelFA[I] and
      (FFamilias[I].Status in [ssNuevo, ssActualizado, ssConflicto]);
    V := tvFamilias.DataController.Values[I, colFAAccion.Index];
    if not VarIsNull(V) then
      FFamilias[I].ConflictAction := ActionFromText(VarToStr(V));
  end;
  SetLength(SelCC, Length(FCalendarios));
  BuildSelectionSet(tvCalendarios, SelCC);
  for I := 0 to High(FCalendarios) do
  begin
    FCalendarios[I].Aplicar := SelCC[I] and
      (FCalendarios[I].Status in [ssNuevo, ssActualizado, ssConflicto]);
    V := tvCalendarios.DataController.Values[I, colCAAccion.Index];
    if not VarIsNull(V) then
      FCalendarios[I].ConflictAction := ActionFromText(VarToStr(V));
  end;
end;
procedure TfrmSincronizarERP.btnSyncClick(Sender: TObject);
var
  SumC, SumM, SumO, SumCM, SumHM, SumAL, SumFA, SumCC: TSyncSummary;
  OpLinked, CtLinked: Integer;
begin
  if (FRepo = nil) or
     ((Length(FCentros) = 0) and (Length(FMaquinas) = 0) and
      (Length(FOperarios) = 0) and (Length(FCentroMaquina) = 0) and
      (Length(FModelos) = 0) and (Length(FAlmacenes) = 0) and
      (Length(FFamilias) = 0) and (Length(FCalendarios) = 0)) then
  begin
    MessageDlg('Pulsa "Previsualizar" antes de sincronizar.',
      mtInformation, [mbOK], 0);
    Exit;
  end;
  if MessageDlg('Aplicar los cambios marcados a la base de datos local?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  CollectFromGrid;
  Screen.Cursor := crHourGlass;
  try
    // Orden importante: Centros y Maquinas antes que CentroMaquina (relacion)
    SumC := FRepo.ApplyCentros(FCentros);
    SumM := FRepo.ApplyMaquinas(FMaquinas);
    SumO := FRepo.ApplyOperarios(FOperarios);
    SumCM := FRepo.ApplyCentroMaquina(FCentroMaquina);
    SumHM := FRepo.ApplyShiftModels(FModelos);
    SumAL := FRepo.ApplyAlmacenes(FAlmacenes);
    SumFA := FRepo.ApplyFamilias(FFamilias);
    SumCC := FRepo.ApplyCalendarios(FCalendarios, FFechaCalDesde, FFechaCalHasta, FReader);
    // Post-pass: vincula Operator.CalendarId i FS_PL_CenterCalendar segons GrupoHorarioCodigo
    FRepo.LinkOperatorsAndCentersToCalendars(OpLinked, CtLinked);
  finally
    Screen.Cursor := crDefault;
  end;
  lblSummary.Caption := Format(
    'Centros:%d / M'#225'q:%d / Op:%d / C'#215'M:%d / Mod:%d / Alm:%d / Fam:%d / Calend:%d. ' +
    'Vinculados: %d operarios + %d centros a sus calendarios.',
    [SumC.Aplicados, SumM.Aplicados, SumO.Aplicados, SumCM.Aplicados,
     SumHM.Aplicados, SumAL.Aplicados, SumFA.Aplicados, SumCC.Aplicados,
     OpLinked, CtLinked]);
  btnPreviewClick(nil);
end;
procedure TfrmSincronizarERP.RenderResumen;
  procedure SetRow(ARowIdx: Integer; const AEntidad: string;
    ANuevos, AActualizados, ASinCambios, AConflictos, AEliminados: Integer);
  begin
    tvResumen.DataController.Values[ARowIdx, colREntidad.Index]      := AEntidad;
    tvResumen.DataController.Values[ARowIdx, colRNuevos.Index]       := ANuevos;
    tvResumen.DataController.Values[ARowIdx, colRActualizados.Index] := AActualizados;
    tvResumen.DataController.Values[ARowIdx, colRSinCambios.Index]   := ASinCambios;
    tvResumen.DataController.Values[ARowIdx, colRConflictos.Index]   := AConflictos;
    tvResumen.DataController.Values[ARowIdx, colREliminados.Index]   := AEliminados;
    tvResumen.DataController.Values[ARowIdx, colRTotal.Index]        :=
      ANuevos + AActualizados + ASinCambios + AConflictos + AEliminados;
  end;
var
  NC, AC, SC, CC, EC: Integer;
  NM, AM, SM, CM, EM: Integer;
  NO, AO, SO, CO, EO: Integer;
  NCM, ACM, SCM, CCM, ECM: Integer;
  NHM, AHM, SHM, CHM, EHM: Integer;
  NAL, AAL, SAL, CAL, EAL: Integer;
  NFA, AFA, SFA, CFA, EFA: Integer;
  NCC, ACC, SCC, CCC, ECC: Integer;
  I: Integer;
begin
  NC := 0; AC := 0; SC := 0; CC := 0; EC := 0;
  for I := 0 to High(FCentros) do
    case FCentros[I].Status of
      ssNuevo:        Inc(NC);
      ssActualizado:  Inc(AC);
      ssSinCambios:   Inc(SC);
      ssConflicto:    Inc(CC);
      ssEliminadoErp: Inc(EC);
    end;
  NM := 0; AM := 0; SM := 0; CM := 0; EM := 0;
  for I := 0 to High(FMaquinas) do
    case FMaquinas[I].Status of
      ssNuevo:        Inc(NM);
      ssActualizado:  Inc(AM);
      ssSinCambios:   Inc(SM);
      ssConflicto:    Inc(CM);
      ssEliminadoErp: Inc(EM);
    end;
  NO := 0; AO := 0; SO := 0; CO := 0; EO := 0;
  for I := 0 to High(FOperarios) do
    case FOperarios[I].Status of
      ssNuevo:        Inc(NO);
      ssActualizado:  Inc(AO);
      ssSinCambios:   Inc(SO);
      ssConflicto:    Inc(CO);
      ssEliminadoErp: Inc(EO);
    end;
  NCM := 0; ACM := 0; SCM := 0; CCM := 0; ECM := 0;
  for I := 0 to High(FCentroMaquina) do
    case FCentroMaquina[I].Status of
      ssNuevo:        Inc(NCM);
      ssActualizado:  Inc(ACM);
      ssSinCambios:   Inc(SCM);
      ssConflicto:    Inc(CCM);
      ssEliminadoErp: Inc(ECM);
    end;
  NHM := 0; AHM := 0; SHM := 0; CHM := 0; EHM := 0;
  for I := 0 to High(FModelos) do
    case FModelos[I].Status of
      ssNuevo:        Inc(NHM);
      ssActualizado:  Inc(AHM);
      ssSinCambios:   Inc(SHM);
      ssConflicto:    Inc(CHM);
      ssEliminadoErp: Inc(EHM);
    end;
  NAL := 0; AAL := 0; SAL := 0; CAL := 0; EAL := 0;
  for I := 0 to High(FAlmacenes) do
    case FAlmacenes[I].Status of
      ssNuevo:        Inc(NAL);
      ssActualizado:  Inc(AAL);
      ssSinCambios:   Inc(SAL);
      ssConflicto:    Inc(CAL);
      ssEliminadoErp: Inc(EAL);
    end;
  NFA := 0; AFA := 0; SFA := 0; CFA := 0; EFA := 0;
  for I := 0 to High(FFamilias) do
    case FFamilias[I].Status of
      ssNuevo:        Inc(NFA);
      ssActualizado:  Inc(AFA);
      ssSinCambios:   Inc(SFA);
      ssConflicto:    Inc(CFA);
      ssEliminadoErp: Inc(EFA);
    end;
  NCC := 0; ACC := 0; SCC := 0; CCC := 0; ECC := 0;
  for I := 0 to High(FCalendarios) do
    case FCalendarios[I].Status of
      ssNuevo:        Inc(NCC);
      ssActualizado:  Inc(ACC);
      ssSinCambios:   Inc(SCC);
      ssConflicto:    Inc(CCC);
      ssEliminadoErp: Inc(ECC);
    end;
  tvResumen.BeginUpdate;
  try
    tvResumen.DataController.RecordCount := 0;
    tvResumen.DataController.RecordCount := 8;
    SetRow(0, 'Centros de trabajo', NC, AC, SC, CC, EC);
    SetRow(1, 'M'#225'quinas',          NM, AM, SM, CM, EM);
    SetRow(2, 'Operarios',          NO, AO, SO, CO, EO);
    SetRow(3, 'Centros '#215' M'#225'quinas', NCM, ACM, SCM, CCM, ECM);
    SetRow(4, 'Modelos horarios',   NHM, AHM, SHM, CHM, EHM);
    SetRow(5, 'Almacenes',          NAL, AAL, SAL, CAL, EAL);
    SetRow(6, 'Familias',           NFA, AFA, SFA, CFA, EFA);
    SetRow(7, 'Calendarios (grupos)', NCC, ACC, SCC, CCC, ECC);
  finally
    tvResumen.EndUpdate;
  end;
end;
procedure TfrmSincronizarERP.btnHelpClick(Sender: TObject);
begin
  THelpViewer.Show('uSincronizarERP', 'Sincronizar con ERP');
end;
end.
