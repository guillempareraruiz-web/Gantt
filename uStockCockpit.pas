unit uStockCockpit;

// ============================================================================
// Stock Cockpit — vista de listados masivos sobre el stock.
//
// PageControl con tabs:
//   - Stock cr'itico (ahora)
//   - Rupturas futuras (proyeccion agregada rapida)
//   - Stock obsoleto
//   - Cobertura (Days of Supply)
//   - Analisis ABC
//
// Filtros comunes (almacenes + familia) + SpinEdits espec'ificos por tab
// (dias horizonte, meses sin movimiento, dias historico).
// Doble-click sobre cualquier fila > abre Article Detail.
// El form NO hace queries SQL directamente: todo va v'ia IErpReader.
// ============================================================================

interface

uses
  System.SysUtils, System.StrUtils, System.Variants, System.Classes,
  System.UITypes, System.DateUtils, System.Math, System.Generics.Collections,
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
  uErpReader, uErpTypes, cxCheckBox, cxContainer, dxSkinsCore, dxSkinBasic,
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
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, dxBarBuiltInMenu;

type
  TfrmStockCockpit = class(TForm)
    pnlTop: TPanel;
    lblAlmacenes: TLabel;
    ccbAlmacenes: TcxCheckComboBox;
    lblFamilia: TLabel;
    edFamilia: TEdit;
    lblParam: TLabel;
    seParam: TcxSpinEdit;
    btnActualizar: TButton;
    pgcTabs: TcxPageControl;
    tabCritico: TcxTabSheet;
    tabRupturas: TcxTabSheet;
    tabObsoleto: TcxTabSheet;
    tabCobertura: TcxTabSheet;
    tabABC: TcxTabSheet;
    grdCritico: TcxGrid;
    grdCriticoView: TcxGridDBTableView;
    grdCriticoLevel: TcxGridLevel;
    grdRupturas: TcxGrid;
    grdRupturasView: TcxGridDBTableView;
    grdRupturasLevel: TcxGridLevel;
    grdObsoleto: TcxGrid;
    grdObsoletoView: TcxGridDBTableView;
    grdObsoletoLevel: TcxGridLevel;
    grdCobertura: TcxGrid;
    grdCoberturaView: TcxGridDBTableView;
    grdCoberturaLevel: TcxGridLevel;
    grdABC: TcxGrid;
    grdABCView: TcxGridDBTableView;
    grdABCLevel: TcxGridLevel;
    splitABC: TSplitter;
    pnlABCChart: TPanel;
    pbABC: TPaintBox;
    splitObsoleto: TSplitter;
    pnlObsoletoChart: TPanel;
    pbObsoleto: TPaintBox;
    splitCritico: TSplitter;
    pnlCriticoChart: TPanel;
    pbCritico: TPaintBox;
    splitRupturas: TSplitter;
    pnlRupturasChart: TPanel;
    pbRupturas: TPaintBox;
    splitCobertura: TSplitter;
    pnlCoberturaChart: TPanel;
    pbCobertura: TPaintBox;
    cdsCritico: TClientDataSet;
    dsCritico: TDataSource;
    cdsRupturas: TClientDataSet;
    dsRupturas: TDataSource;
    cdsObsoleto: TClientDataSet;
    dsObsoleto: TDataSource;
    cdsCobertura: TClientDataSet;
    dsCobertura: TDataSource;
    cdsABC: TClientDataSet;
    dsABC: TDataSource;
    pnlBottom: TPanel;
    btnCerrar: TButton;
    lblContador: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnActualizarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure pgcTabsChange(Sender: TObject);
    procedure grdCriticoViewDblClick(Sender: TObject);
    procedure grdRupturasViewDblClick(Sender: TObject);
    procedure grdObsoletoViewDblClick(Sender: TObject);
    procedure grdCoberturaViewDblClick(Sender: TObject);
    procedure grdABCViewDblClick(Sender: TObject);
    procedure grdCriticoViewCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
    procedure grdRupturasViewCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
    procedure grdCoberturaViewCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
    procedure grdABCViewCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
    procedure pbABCPaint(Sender: TObject);
    procedure pbObsoletoPaint(Sender: TObject);
    procedure pbCriticoPaint(Sender: TObject);
    procedure pbRupturasPaint(Sender: TObject);
    procedure pbCoberturaPaint(Sender: TObject);
  private
    FReader: IErpReader;
    procedure CargarAlmacenes;
    function AlmacenesSeleccionados: TArray<string>;
    procedure AjustarParametroPorTab;
    procedure CargarStockCritico;
    procedure CargarRupturasFuturas;
    procedure CargarStockObsoleto;
    procedure CargarCobertura;
    procedure CargarAnalisisABC;
    procedure CrearColumnasSiCal(AView: TcxGridDBTableView);
    procedure AbrirArticleDetail(const ACodigoArticulo: string);
    procedure DblClickGenerico(ACds: TClientDataSet);
  public
    class procedure Execute(const AReader: IErpReader);
  end;

implementation

uses
  uArticleDetail;

{$R *.dfm}

class procedure TfrmStockCockpit.Execute(const AReader: IErpReader);
var
  Frm: TfrmStockCockpit;
begin
  Frm := TfrmStockCockpit.Create(nil);
  try
    Frm.FReader := AReader;
    Frm.CargarAlmacenes;
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TfrmStockCockpit.FormCreate(Sender: TObject);
begin
  // -- cdsCritico
  cdsCritico.FieldDefs.Clear;
  cdsCritico.FieldDefs.Add('CodigoArticulo', ftString, 30);
  cdsCritico.FieldDefs.Add('DescripcionArticulo', ftString, 100);
  cdsCritico.FieldDefs.Add('CodigoAlmacen', ftString, 20);
  cdsCritico.FieldDefs.Add('CodigoFamilia', ftString, 30);
  cdsCritico.FieldDefs.Add('UnidadSaldo', ftFloat);
  cdsCritico.FieldDefs.Add('StockReservado', ftFloat);
  cdsCritico.FieldDefs.Add('Disponible', ftFloat);
  cdsCritico.FieldDefs.Add('PendienteRecibir', ftFloat);
  cdsCritico.FieldDefs.Add('PendienteServir', ftFloat);
  cdsCritico.FieldDefs.Add('StockMinimo', ftFloat);
  cdsCritico.FieldDefs.Add('Deficit', ftFloat);
  cdsCritico.FieldDefs.Add('UnidadMedida', ftString, 10);
  cdsCritico.CreateDataSet;

  // -- cdsRupturas
  cdsRupturas.FieldDefs.Clear;
  cdsRupturas.FieldDefs.Add('CodigoArticulo', ftString, 30);
  cdsRupturas.FieldDefs.Add('DescripcionArticulo', ftString, 100);
  cdsRupturas.FieldDefs.Add('CodigoAlmacen', ftString, 20);
  cdsRupturas.FieldDefs.Add('CodigoFamilia', ftString, 30);
  cdsRupturas.FieldDefs.Add('UnidadSaldo', ftFloat);
  cdsRupturas.FieldDefs.Add('PendienteRecibir', ftFloat);
  cdsRupturas.FieldDefs.Add('ProduccionPendiente', ftFloat);
  cdsRupturas.FieldDefs.Add('PendienteServir', ftFloat);
  cdsRupturas.FieldDefs.Add('ConsumoPendiente', ftFloat);
  cdsRupturas.FieldDefs.Add('SaldoFinal', ftFloat);
  cdsRupturas.FieldDefs.Add('StockMinimo', ftFloat);
  cdsRupturas.FieldDefs.Add('Deficit', ftFloat);
  cdsRupturas.FieldDefs.Add('UnidadMedida', ftString, 10);
  cdsRupturas.CreateDataSet;

  // -- cdsObsoleto
  cdsObsoleto.FieldDefs.Clear;
  cdsObsoleto.FieldDefs.Add('CodigoArticulo', ftString, 30);
  cdsObsoleto.FieldDefs.Add('DescripcionArticulo', ftString, 100);
  cdsObsoleto.FieldDefs.Add('CodigoAlmacen', ftString, 20);
  cdsObsoleto.FieldDefs.Add('CodigoFamilia', ftString, 30);
  cdsObsoleto.FieldDefs.Add('UnidadSaldo', ftFloat);
  cdsObsoleto.FieldDefs.Add('ImporteSaldo', ftFloat);
  cdsObsoleto.FieldDefs.Add('PrecioMedio', ftFloat);
  cdsObsoleto.FieldDefs.Add('FechaUltimaEntrada', ftDateTime);
  cdsObsoleto.FieldDefs.Add('FechaUltimaSalida', ftDateTime);
  cdsObsoleto.FieldDefs.Add('DiasSinMovimiento', ftInteger);
  cdsObsoleto.FieldDefs.Add('UnidadMedida', ftString, 10);
  cdsObsoleto.CreateDataSet;

  // -- cdsCobertura
  cdsCobertura.FieldDefs.Clear;
  cdsCobertura.FieldDefs.Add('CodigoArticulo', ftString, 30);
  cdsCobertura.FieldDefs.Add('DescripcionArticulo', ftString, 100);
  cdsCobertura.FieldDefs.Add('CodigoAlmacen', ftString, 20);
  cdsCobertura.FieldDefs.Add('CodigoFamilia', ftString, 30);
  cdsCobertura.FieldDefs.Add('UnidadSaldo', ftFloat);
  cdsCobertura.FieldDefs.Add('ConsumoPeriodo', ftFloat);
  cdsCobertura.FieldDefs.Add('ConsumoDiario', ftFloat);
  cdsCobertura.FieldDefs.Add('DiasCobertura', ftFloat);
  cdsCobertura.FieldDefs.Add('StockMinimo', ftFloat);
  cdsCobertura.FieldDefs.Add('UnidadMedida', ftString, 10);
  cdsCobertura.CreateDataSet;

  // -- cdsABC
  cdsABC.FieldDefs.Clear;
  cdsABC.FieldDefs.Add('Categoria', ftString, 1);
  cdsABC.FieldDefs.Add('CodigoArticulo', ftString, 30);
  cdsABC.FieldDefs.Add('DescripcionArticulo', ftString, 100);
  cdsABC.FieldDefs.Add('CodigoFamilia', ftString, 30);
  cdsABC.FieldDefs.Add('UnidadesConsumidas', ftFloat);
  cdsABC.FieldDefs.Add('ImporteConsumido', ftFloat);
  cdsABC.FieldDefs.Add('PorcentajeIndividual', ftFloat);
  cdsABC.FieldDefs.Add('PorcentajeAcumulado', ftFloat);
  cdsABC.FieldDefs.Add('UnidadMedida', ftString, 10);
  cdsABC.CreateDataSet;

  lblContador.Caption := '';
  AjustarParametroPorTab;
end;

procedure TfrmStockCockpit.CargarAlmacenes;
var
  Almacenes: TArray<TAlmacenErp>;
  i: Integer;
  Item: TcxCheckComboBoxItem;
begin
  ccbAlmacenes.Properties.Items.Clear;
  if FReader = nil then Exit;
  try
    Almacenes := FReader.ReadAlmacenes;
  except
    on E: Exception do
    begin
      ShowMessage('Error cargando almacenes: ' + E.Message);
      Exit;
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

function TfrmStockCockpit.AlmacenesSeleccionados: TArray<string>;
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

procedure TfrmStockCockpit.AjustarParametroPorTab;
begin
  // Etiqueta + valor per defecte del SpinEdit segons la tab activa.
  case pgcTabs.ActivePageIndex of
    0: // Critico
      begin
        lblParam.Caption := '';
        lblParam.Visible := False;
        seParam.Visible := False;
      end;
    1: // Rupturas
      begin
        lblParam.Caption := 'D'#237'as horizonte:';
        lblParam.Visible := True;
        seParam.Visible := True;
        if seParam.Value <= 0 then seParam.Value := 60;
      end;
    2: // Obsoleto
      begin
        lblParam.Caption := 'Meses sin movimiento:';
        lblParam.Visible := True;
        seParam.Visible := True;
        if (seParam.Value <= 0) or (seParam.Value > 60) then seParam.Value := 12;
      end;
    3: // Cobertura
      begin
        lblParam.Caption := 'D'#237'as hist'#243'rico consumo:';
        lblParam.Visible := True;
        seParam.Visible := True;
        if seParam.Value <= 0 then seParam.Value := 90;
      end;
    4: // ABC
      begin
        lblParam.Caption := 'D'#237'as hist'#243'rico consumo:';
        lblParam.Visible := True;
        seParam.Visible := True;
        if seParam.Value <= 0 then seParam.Value := 365;
      end;
  end;
end;

procedure TfrmStockCockpit.pgcTabsChange(Sender: TObject);
begin
  AjustarParametroPorTab;
  lblContador.Caption := '';
end;

procedure TfrmStockCockpit.btnActualizarClick(Sender: TObject);
begin
  case pgcTabs.ActivePageIndex of
    0: CargarStockCritico;
    1: CargarRupturasFuturas;
    2: CargarStockObsoleto;
    3: CargarCobertura;
    4: CargarAnalisisABC;
  end;
end;

procedure TfrmStockCockpit.CrearColumnasSiCal(AView: TcxGridDBTableView);
var
  i: Integer;
begin
  if AView.ColumnCount > 0 then
  begin
    AView.ApplyBestFit;
    Exit;
  end;
  AView.BeginUpdate;
  try
    AView.DataController.CreateAllItems;
    for i := 0 to AView.ColumnCount - 1 do
    begin
      AView.Columns[i].Options.Editing := False;
      AView.Columns[i].Options.Focusing := False;
    end;
  finally
    AView.EndUpdate;
  end;
  AView.ApplyBestFit;
end;

// ---------------------------------------------------------------------------
// CARGA: Stock cr'itico
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.CargarStockCritico;
var
  Data: TArray<TStockCriticoErp>;
  i: Integer;
begin
  if FReader = nil then Exit;
  Screen.Cursor := crHourGlass;
  try
    try
      Data := FReader.ReadStockCritico(AlmacenesSeleccionados,
        Trim(edFamilia.Text));
    except
      on E: Exception do
      begin
        ShowMessage('Error: ' + E.Message);
        Exit;
      end;
    end;
    cdsCritico.DisableControls;
    try
      cdsCritico.EmptyDataSet;
      for i := 0 to High(Data) do
      begin
        cdsCritico.Append;
        cdsCritico.FieldByName('CodigoArticulo').AsString      := Data[i].CodigoArticulo;
        cdsCritico.FieldByName('DescripcionArticulo').AsString := Data[i].DescripcionArticulo;
        cdsCritico.FieldByName('CodigoAlmacen').AsString       := Data[i].CodigoAlmacen;
        cdsCritico.FieldByName('CodigoFamilia').AsString       := Data[i].CodigoFamilia;
        cdsCritico.FieldByName('UnidadSaldo').AsFloat          := Data[i].UnidadSaldo;
        cdsCritico.FieldByName('StockReservado').AsFloat       := Data[i].StockReservado;
        cdsCritico.FieldByName('Disponible').AsFloat           := Data[i].Disponible;
        cdsCritico.FieldByName('PendienteRecibir').AsFloat     := Data[i].PendienteRecibir;
        cdsCritico.FieldByName('PendienteServir').AsFloat      := Data[i].PendienteServir;
        cdsCritico.FieldByName('StockMinimo').AsFloat          := Data[i].StockMinimo;
        cdsCritico.FieldByName('Deficit').AsFloat              := Data[i].Deficit;
        cdsCritico.FieldByName('UnidadMedida').AsString        := Data[i].UnidadMedida;
        cdsCritico.Post;
      end;
      cdsCritico.First;
    finally
      cdsCritico.EnableControls;
    end;
    lblContador.Caption := Format('%d articulos cr'#237'ticos', [Length(Data)]);
    CrearColumnasSiCal(grdCriticoView);
    pbCritico.Invalidate;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// ---------------------------------------------------------------------------
// CARGA: Rupturas futuras
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.CargarRupturasFuturas;
var
  Data: TArray<TRupturaFuturaErp>;
  i: Integer;
begin
  if FReader = nil then Exit;
  Screen.Cursor := crHourGlass;
  try
    try
      Data := FReader.ReadRupturasFuturas(AlmacenesSeleccionados,
        Trim(edFamilia.Text), seParam.Value);
    except
      on E: Exception do
      begin
        ShowMessage('Error: ' + E.Message);
        Exit;
      end;
    end;
    cdsRupturas.DisableControls;
    try
      cdsRupturas.EmptyDataSet;
      for i := 0 to High(Data) do
      begin
        cdsRupturas.Append;
        cdsRupturas.FieldByName('CodigoArticulo').AsString      := Data[i].CodigoArticulo;
        cdsRupturas.FieldByName('DescripcionArticulo').AsString := Data[i].DescripcionArticulo;
        cdsRupturas.FieldByName('CodigoAlmacen').AsString       := Data[i].CodigoAlmacen;
        cdsRupturas.FieldByName('CodigoFamilia').AsString       := Data[i].CodigoFamilia;
        cdsRupturas.FieldByName('UnidadSaldo').AsFloat          := Data[i].UnidadSaldo;
        cdsRupturas.FieldByName('PendienteRecibir').AsFloat     := Data[i].PendienteRecibir;
        cdsRupturas.FieldByName('ProduccionPendiente').AsFloat  := Data[i].ProduccionPendiente;
        cdsRupturas.FieldByName('PendienteServir').AsFloat      := Data[i].PendienteServir;
        cdsRupturas.FieldByName('ConsumoPendiente').AsFloat     := Data[i].ConsumoPendiente;
        cdsRupturas.FieldByName('SaldoFinal').AsFloat           := Data[i].SaldoFinal;
        cdsRupturas.FieldByName('StockMinimo').AsFloat          := Data[i].StockMinimo;
        cdsRupturas.FieldByName('Deficit').AsFloat              := Data[i].Deficit;
        cdsRupturas.FieldByName('UnidadMedida').AsString        := Data[i].UnidadMedida;
        cdsRupturas.Post;
      end;
      cdsRupturas.First;
    finally
      cdsRupturas.EnableControls;
    end;
    lblContador.Caption := Format('%d articulos en ruptura en %d d'#237'as',
      [Length(Data), Integer(seParam.Value)]);
    CrearColumnasSiCal(grdRupturasView);
    pbRupturas.Invalidate;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// ---------------------------------------------------------------------------
// CARGA: Stock obsoleto
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.CargarStockObsoleto;
var
  Data: TArray<TStockObsoletoErp>;
  i: Integer;
  ValorTotal: Double;
begin
  if FReader = nil then Exit;
  Screen.Cursor := crHourGlass;
  try
    try
      Data := FReader.ReadStockObsoleto(AlmacenesSeleccionados,
        Trim(edFamilia.Text), seParam.Value);
    except
      on E: Exception do
      begin
        ShowMessage('Error: ' + E.Message);
        Exit;
      end;
    end;
    cdsObsoleto.DisableControls;
    try
      cdsObsoleto.EmptyDataSet;
      ValorTotal := 0;
      for i := 0 to High(Data) do
      begin
        cdsObsoleto.Append;
        cdsObsoleto.FieldByName('CodigoArticulo').AsString      := Data[i].CodigoArticulo;
        cdsObsoleto.FieldByName('DescripcionArticulo').AsString := Data[i].DescripcionArticulo;
        cdsObsoleto.FieldByName('CodigoAlmacen').AsString       := Data[i].CodigoAlmacen;
        cdsObsoleto.FieldByName('CodigoFamilia').AsString       := Data[i].CodigoFamilia;
        cdsObsoleto.FieldByName('UnidadSaldo').AsFloat          := Data[i].UnidadSaldo;
        cdsObsoleto.FieldByName('ImporteSaldo').AsFloat         := Data[i].ImporteSaldo;
        cdsObsoleto.FieldByName('PrecioMedio').AsFloat          := Data[i].PrecioMedio;
        if Data[i].FechaUltimaEntrada > 0 then
          cdsObsoleto.FieldByName('FechaUltimaEntrada').AsDateTime := Data[i].FechaUltimaEntrada;
        if Data[i].FechaUltimaSalida > 0 then
          cdsObsoleto.FieldByName('FechaUltimaSalida').AsDateTime := Data[i].FechaUltimaSalida;
        cdsObsoleto.FieldByName('DiasSinMovimiento').AsInteger  := Data[i].DiasSinMovimiento;
        cdsObsoleto.FieldByName('UnidadMedida').AsString        := Data[i].UnidadMedida;
        cdsObsoleto.Post;
        ValorTotal := ValorTotal + Data[i].ImporteSaldo;
      end;
      cdsObsoleto.First;
    finally
      cdsObsoleto.EnableControls;
    end;
    lblContador.Caption := Format('%d articulos obsoletos. Valor parado: %s',
      [Length(Data), FormatFloat('#,##0.00', ValorTotal)]);
    CrearColumnasSiCal(grdObsoletoView);
    pbObsoleto.Invalidate;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// ---------------------------------------------------------------------------
// CARGA: Cobertura (Days of Supply)
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.CargarCobertura;
var
  Data: TArray<TCoberturaErp>;
  i: Integer;
begin
  if FReader = nil then Exit;
  Screen.Cursor := crHourGlass;
  try
    try
      Data := FReader.ReadCobertura(AlmacenesSeleccionados,
        Trim(edFamilia.Text), seParam.Value);
    except
      on E: Exception do
      begin
        ShowMessage('Error: ' + E.Message);
        Exit;
      end;
    end;
    cdsCobertura.DisableControls;
    try
      cdsCobertura.EmptyDataSet;
      for i := 0 to High(Data) do
      begin
        cdsCobertura.Append;
        cdsCobertura.FieldByName('CodigoArticulo').AsString      := Data[i].CodigoArticulo;
        cdsCobertura.FieldByName('DescripcionArticulo').AsString := Data[i].DescripcionArticulo;
        cdsCobertura.FieldByName('CodigoAlmacen').AsString       := Data[i].CodigoAlmacen;
        cdsCobertura.FieldByName('CodigoFamilia').AsString       := Data[i].CodigoFamilia;
        cdsCobertura.FieldByName('UnidadSaldo').AsFloat          := Data[i].UnidadSaldo;
        cdsCobertura.FieldByName('ConsumoPeriodo').AsFloat       := Data[i].ConsumoPeriodo;
        cdsCobertura.FieldByName('ConsumoDiario').AsFloat        := Data[i].ConsumoDiario;
        cdsCobertura.FieldByName('DiasCobertura').AsFloat        := Data[i].DiasCobertura;
        cdsCobertura.FieldByName('StockMinimo').AsFloat          := Data[i].StockMinimo;
        cdsCobertura.FieldByName('UnidadMedida').AsString        := Data[i].UnidadMedida;
        cdsCobertura.Post;
      end;
      cdsCobertura.First;
    finally
      cdsCobertura.EnableControls;
    end;
    lblContador.Caption := Format('%d articulos', [Length(Data)]);
    CrearColumnasSiCal(grdCoberturaView);
    pbCobertura.Invalidate;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// ---------------------------------------------------------------------------
// CARGA: An'alisis ABC
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.CargarAnalisisABC;
var
  Data: TArray<TAnalisisABCErp>;
  i, NA, NB, NC: Integer;
begin
  if FReader = nil then Exit;
  Screen.Cursor := crHourGlass;
  try
    try
      Data := FReader.ReadAnalisisABC(Trim(edFamilia.Text), seParam.Value);
    except
      on E: Exception do
      begin
        ShowMessage('Error: ' + E.Message);
        Exit;
      end;
    end;
    cdsABC.DisableControls;
    NA := 0; NB := 0; NC := 0;
    try
      cdsABC.EmptyDataSet;
      for i := 0 to High(Data) do
      begin
        cdsABC.Append;
        cdsABC.FieldByName('Categoria').AsString             := Data[i].Categoria;
        cdsABC.FieldByName('CodigoArticulo').AsString        := Data[i].CodigoArticulo;
        cdsABC.FieldByName('DescripcionArticulo').AsString   := Data[i].DescripcionArticulo;
        cdsABC.FieldByName('CodigoFamilia').AsString         := Data[i].CodigoFamilia;
        cdsABC.FieldByName('UnidadesConsumidas').AsFloat     := Data[i].UnidadesConsumidas;
        cdsABC.FieldByName('ImporteConsumido').AsFloat       := Data[i].ImporteConsumido;
        cdsABC.FieldByName('PorcentajeIndividual').AsFloat   := Data[i].PorcentajeIndividual;
        cdsABC.FieldByName('PorcentajeAcumulado').AsFloat    := Data[i].PorcentajeAcumulado;
        cdsABC.FieldByName('UnidadMedida').AsString          := Data[i].UnidadMedida;
        cdsABC.Post;
        if Data[i].Categoria = 'A' then Inc(NA)
        else if Data[i].Categoria = 'B' then Inc(NB)
        else Inc(NC);
      end;
      cdsABC.First;
    finally
      cdsABC.EnableControls;
    end;
    lblContador.Caption := Format('A: %d  B: %d  C: %d  (total %d)',
      [NA, NB, NC, Length(Data)]);
    CrearColumnasSiCal(grdABCView);
    pbABC.Invalidate;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// ---------------------------------------------------------------------------
// Pintura del Pie ABC (TPaintBox, sin DevExpress charts)
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.pbABCPaint(Sender: TObject);
const
  COL_A: TColor = $004040E0;  // rojo
  COL_B: TColor = $0040A0E0;  // naranja
  COL_C: TColor = $0080C040;  // verde
  TIT_H = 28;
  LEY_H = 78;
  PAD   = 12;
var
  Cv: TCanvas;
  W, H, CX, CY, R: Integer;
  TotA, TotB, TotC, Tot: Double;
  AngA, AngB, AngC: Double;
  PctA, PctB, PctC: Double;
  PieRect: TRect;
  Bm: TBookmark;
  Cat: string;
  Imp: Double;

  procedure PintarSector(StartDeg, SweepDeg: Double; AColor: TColor);
  var
    X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer;
    Rad1, Rad2: Double;
  begin
    if SweepDeg <= 0.01 then Exit;
    Rad1 := DegToRad(StartDeg);
    Rad2 := DegToRad(StartDeg + SweepDeg);
    X1 := PieRect.Left; Y1 := PieRect.Top;
    X2 := PieRect.Right; Y2 := PieRect.Bottom;
    X3 := CX + Round(R * Cos(Rad1));
    Y3 := CY - Round(R * Sin(Rad1));
    X4 := CX + Round(R * Cos(Rad2));
    Y4 := CY - Round(R * Sin(Rad2));
    Cv.Brush.Color := AColor;
    Cv.Pen.Color   := clWhite;
    Cv.Pen.Width   := 2;
    Cv.Pie(X1, Y1, X2, Y2, X3, Y3, X4, Y4);
  end;

  procedure PintarLeyenda(ATop: Integer; AColor: TColor; const ACat: string;
    APct: Double; ATot: Double);
  var
    BoxRect, TxtRect: TRect;
  begin
    BoxRect := Rect(PAD, ATop + 3, PAD + 14, ATop + 17);
    Cv.Brush.Color := AColor;
    Cv.Pen.Color := clBlack;
    Cv.Pen.Width := 1;
    Cv.Rectangle(BoxRect);
    TxtRect := Rect(PAD + 22, ATop, W - PAD, ATop + 20);
    Cv.Brush.Style := bsClear;
    Cv.Font.Color := clBlack;
    Cv.Font.Style := [fsBold];
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
      Format('%s   %5.1f%%   %s', [ACat, APct, FormatFloat('#,##0', ATot)]));
    Cv.Font.Style := [];
  end;

begin
  Cv := pbABC.Canvas;
  W := pbABC.Width;
  H := pbABC.Height;

  // Fondo
  Cv.Brush.Color := clWhite;
  Cv.Brush.Style := bsSolid;
  Cv.FillRect(Rect(0, 0, W, H));

  // T'itulo
  Cv.Font.Name := 'Segoe UI';
  Cv.Font.Size := 10;
  Cv.Font.Style := [fsBold];
  Cv.Font.Color := clBlack;
  Cv.Brush.Style := bsClear;
  Cv.TextRect(Rect(0, 6, W, 6 + TIT_H), PAD, 8, 'Distribuci'#243'n ABC (importe)');

  if (cdsABC = nil) or (not cdsABC.Active) or cdsABC.IsEmpty then
  begin
    Cv.Font.Style := [];
    Cv.Font.Color := clGrayText;
    Cv.TextRect(Rect(0, H div 2 - 10, W, H div 2 + 10), PAD, H div 2 - 8,
      '(sin datos)');
    Exit;
  end;

  // Agregar por categor'ia
  TotA := 0; TotB := 0; TotC := 0;
  cdsABC.DisableControls;
  Bm := cdsABC.GetBookmark;
  try
    cdsABC.First;
    while not cdsABC.Eof do
    begin
      Cat := cdsABC.FieldByName('Categoria').AsString;
      Imp := cdsABC.FieldByName('ImporteConsumido').AsFloat;
      if Cat = 'A' then TotA := TotA + Imp
      else if Cat = 'B' then TotB := TotB + Imp
      else TotC := TotC + Imp;
      cdsABC.Next;
    end;
  finally
    if Bm <> nil then
    begin
      cdsABC.GotoBookmark(Bm);
      cdsABC.FreeBookmark(Bm);
    end;
    cdsABC.EnableControls;
  end;

  Tot := TotA + TotB + TotC;
  if Tot <= 0 then Exit;

  PctA := TotA * 100 / Tot;
  PctB := TotB * 100 / Tot;
  PctC := TotC * 100 / Tot;

  AngA := PctA * 360 / 100;
  AngB := PctB * 360 / 100;
  AngC := 360 - AngA - AngB;

  // Rect'angulo del pie (cuadrado centrado)
  R := (Min(W, H - TIT_H - LEY_H - PAD * 2) div 2) - PAD;
  if R < 30 then R := 30;
  CX := W div 2;
  CY := TIT_H + PAD + R;
  PieRect := Rect(CX - R, CY - R, CX + R, CY + R);

  // Sectores (sentido antihorario desde 90'o para que A empiece arriba)
  PintarSector(90,                  -AngA, COL_A);
  PintarSector(90 - AngA,           -AngB, COL_B);
  PintarSector(90 - AngA - AngB,    -AngC, COL_C);

  // Leyenda
  PintarLeyenda(H - LEY_H + 4,  COL_A, 'A', PctA, TotA);
  PintarLeyenda(H - LEY_H + 28, COL_B, 'B', PctB, TotB);
  PintarLeyenda(H - LEY_H + 52, COL_C, 'C', PctC, TotC);
end;

// ---------------------------------------------------------------------------
// Pintura Top-10 Obsoleto (barras horizontales por importe)
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.pbObsoletoPaint(Sender: TObject);
const
  TIT_H   = 30;
  ROW_H   = 38;
  PAD     = 10;
  LBL_W   = 130;   // ancho zona texto izquierda (cod + dias)
  VAL_W   = 90;    // ancho zona valor derecha
  BAR_COL: TColor = $004060E0; // rojo-naranja
type
  TTopItem = record
    Codigo: string;
    Dias: Integer;
    Importe: Double;
  end;
var
  Cv: TCanvas;
  W, H, i, N, BarsW, BarLeft, BarRight, Y: Integer;
  Items: array[0..9] of TTopItem;
  MaxImp, ValorTot: Double;
  Bm: TBookmark;
  Cod: string;
  Imp: Double;
  Dias: Integer;
  Inserted: Boolean;
  j, k: Integer;
  BarW: Integer;
  TxtRect: TRect;
begin
  Cv := pbObsoleto.Canvas;
  W := pbObsoleto.Width;
  H := pbObsoleto.Height;

  Cv.Brush.Color := clWhite;
  Cv.Brush.Style := bsSolid;
  Cv.FillRect(Rect(0, 0, W, H));

  Cv.Font.Name := 'Segoe UI';
  Cv.Font.Size := 10;
  Cv.Font.Style := [fsBold];
  Cv.Font.Color := clBlack;
  Cv.Brush.Style := bsClear;
  Cv.TextRect(Rect(0, 6, W, 6 + TIT_H), PAD, 8,
    'Top 10 obsoleto por importe');

  if (cdsObsoleto = nil) or (not cdsObsoleto.Active) or cdsObsoleto.IsEmpty then
  begin
    Cv.Font.Style := [];
    Cv.Font.Color := clGrayText;
    Cv.TextRect(Rect(0, H div 2 - 10, W, H div 2 + 10), PAD, H div 2 - 8,
      '(sin datos)');
    Exit;
  end;

  // Construir top-10 ordenado desc por Importe usando insercion
  N := 0;
  ValorTot := 0;
  cdsObsoleto.DisableControls;
  Bm := cdsObsoleto.GetBookmark;
  try
    cdsObsoleto.First;
    while not cdsObsoleto.Eof do
    begin
      Imp  := cdsObsoleto.FieldByName('ImporteSaldo').AsFloat;
      Cod  := cdsObsoleto.FieldByName('CodigoArticulo').AsString;
      Dias := cdsObsoleto.FieldByName('DiasSinMovimiento').AsInteger;
      ValorTot := ValorTot + Imp;

      Inserted := False;
      for j := 0 to N - 1 do
        if Imp > Items[j].Importe then
        begin
          // desplazar hacia abajo
          for k := Min(N, 9) downto j + 1 do
            Items[k] := Items[k - 1];
          Items[j].Codigo  := Cod;
          Items[j].Dias    := Dias;
          Items[j].Importe := Imp;
          if N < 10 then Inc(N);
          Inserted := True;
          Break;
        end;
      if (not Inserted) and (N < 10) then
      begin
        Items[N].Codigo  := Cod;
        Items[N].Dias    := Dias;
        Items[N].Importe := Imp;
        Inc(N);
      end;

      cdsObsoleto.Next;
    end;
  finally
    if Bm <> nil then
    begin
      cdsObsoleto.GotoBookmark(Bm);
      cdsObsoleto.FreeBookmark(Bm);
    end;
    cdsObsoleto.EnableControls;
  end;

  if N = 0 then Exit;

  MaxImp := Items[0].Importe;
  if MaxImp <= 0 then Exit;

  BarLeft  := PAD + LBL_W;
  BarRight := W - PAD - VAL_W;
  BarsW    := BarRight - BarLeft;
  if BarsW < 40 then BarsW := 40;

  Cv.Font.Style := [];
  Cv.Font.Size := 8;

  for i := 0 to N - 1 do
  begin
    Y := TIT_H + PAD + i * ROW_H;

    // Etiqueta izquierda: codigo + dias
    Cv.Font.Color := clBlack;
    Cv.Font.Style := [fsBold];
    TxtRect := Rect(PAD, Y, PAD + LBL_W - 4, Y + 16);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top, Items[i].Codigo);
    Cv.Font.Style := [];
    Cv.Font.Color := clGrayText;
    TxtRect := Rect(PAD, Y + 16, PAD + LBL_W - 4, Y + 32);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
      Format('%d d', [Items[i].Dias]));

    // Barra
    BarW := Round(BarsW * (Items[i].Importe / MaxImp));
    if BarW < 1 then BarW := 1;
    Cv.Brush.Color := BAR_COL;
    Cv.Pen.Color := BAR_COL;
    Cv.Rectangle(BarLeft, Y + 6, BarLeft + BarW, Y + 26);

    // Valor derecha
    Cv.Brush.Style := bsClear;
    Cv.Font.Color := clBlack;
    Cv.Font.Style := [fsBold];
    TxtRect := Rect(BarRight + 4, Y + 4, W - PAD, Y + 24);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
      FormatFloat('#,##0', Items[i].Importe));
    Cv.Font.Style := [];
  end;

  // Pie: valor total
  Cv.Font.Size := 9;
  Cv.Font.Color := clGrayText;
  TxtRect := Rect(PAD, H - 22, W - PAD, H - 4);
  Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
    Format('Valor total parado: %s', [FormatFloat('#,##0', ValorTot)]));
end;

// ---------------------------------------------------------------------------
// Pintura Top-10 Stock Cr'itico (barras dobles: actual vs minimo)
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.pbCriticoPaint(Sender: TObject);
const
  TIT_H   = 30;
  ROW_H   = 42;
  PAD     = 10;
  LBL_W   = 110;
  VAL_W   = 90;
  COL_ACTUAL: TColor = $002060E0; // rojo: stock actual (bajo)
  COL_MIN:    TColor = $00A0A0A0; // gris claro: minimo (referencia)
type
  TTopItem = record
    Codigo: string;
    Stock, Minimo, Deficit: Double;
  end;
var
  Cv: TCanvas;
  W, H, i, N, BarsW, BarLeft, BarRight, Y: Integer;
  Items: array[0..9] of TTopItem;
  MaxScale: Double;
  Bm: TBookmark;
  Cod: string;
  St, Mn, Df: Double;
  Inserted: Boolean;
  j, k: Integer;
  BarW: Integer;
  TxtRect: TRect;
begin
  Cv := pbCritico.Canvas;
  W := pbCritico.Width;
  H := pbCritico.Height;

  Cv.Brush.Color := clWhite;
  Cv.Brush.Style := bsSolid;
  Cv.FillRect(Rect(0, 0, W, H));

  Cv.Font.Name := 'Segoe UI';
  Cv.Font.Size := 10;
  Cv.Font.Style := [fsBold];
  Cv.Font.Color := clBlack;
  Cv.Brush.Style := bsClear;
  Cv.TextRect(Rect(0, 6, W, 6 + TIT_H), PAD, 8,
    'Top 10 cr'#237'tico (d'#233'ficit vs m'#237'nimo)');

  if (cdsCritico = nil) or (not cdsCritico.Active) or cdsCritico.IsEmpty then
  begin
    Cv.Font.Style := [];
    Cv.Font.Color := clGrayText;
    Cv.TextRect(Rect(0, H div 2 - 10, W, H div 2 + 10), PAD, H div 2 - 8,
      '(sin datos)');
    Exit;
  end;

  // Top-10 por Deficit desc
  N := 0;
  cdsCritico.DisableControls;
  Bm := cdsCritico.GetBookmark;
  try
    cdsCritico.First;
    while not cdsCritico.Eof do
    begin
      Df  := cdsCritico.FieldByName('Deficit').AsFloat;
      St  := cdsCritico.FieldByName('UnidadSaldo').AsFloat;
      Mn  := cdsCritico.FieldByName('StockMinimo').AsFloat;
      Cod := cdsCritico.FieldByName('CodigoArticulo').AsString;

      Inserted := False;
      for j := 0 to N - 1 do
        if Df > Items[j].Deficit then
        begin
          for k := Min(N, 9) downto j + 1 do
            Items[k] := Items[k - 1];
          Items[j].Codigo  := Cod;
          Items[j].Stock   := St;
          Items[j].Minimo  := Mn;
          Items[j].Deficit := Df;
          if N < 10 then Inc(N);
          Inserted := True;
          Break;
        end;
      if (not Inserted) and (N < 10) then
      begin
        Items[N].Codigo  := Cod;
        Items[N].Stock   := St;
        Items[N].Minimo  := Mn;
        Items[N].Deficit := Df;
        Inc(N);
      end;

      cdsCritico.Next;
    end;
  finally
    if Bm <> nil then
    begin
      cdsCritico.GotoBookmark(Bm);
      cdsCritico.FreeBookmark(Bm);
    end;
    cdsCritico.EnableControls;
  end;

  if N = 0 then Exit;

  // Escala = max minimo del top
  MaxScale := 0;
  for i := 0 to N - 1 do
    if Items[i].Minimo > MaxScale then MaxScale := Items[i].Minimo;
  if MaxScale <= 0 then MaxScale := 1;

  BarLeft  := PAD + LBL_W;
  BarRight := W - PAD - VAL_W;
  BarsW    := BarRight - BarLeft;
  if BarsW < 40 then BarsW := 40;

  Cv.Font.Size := 8;

  for i := 0 to N - 1 do
  begin
    Y := TIT_H + PAD + i * ROW_H;

    // Etiqueta izquierda: codigo
    Cv.Font.Color := clBlack;
    Cv.Font.Style := [fsBold];
    TxtRect := Rect(PAD, Y + 4, PAD + LBL_W - 4, Y + 22);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top, Items[i].Codigo);

    // Barra MINIMO (gris, fina, fondo)
    Cv.Brush.Color := COL_MIN;
    Cv.Pen.Color := COL_MIN;
    BarW := Round(BarsW * (Items[i].Minimo / MaxScale));
    if BarW < 1 then BarW := 1;
    Cv.Rectangle(BarLeft, Y + 22, BarLeft + BarW, Y + 30);

    // Barra STOCK ACTUAL (rojo, gruesa, encima)
    Cv.Brush.Color := COL_ACTUAL;
    Cv.Pen.Color := COL_ACTUAL;
    BarW := Round(BarsW * (Items[i].Stock / MaxScale));
    if BarW < 1 then BarW := 1;
    Cv.Rectangle(BarLeft, Y + 8, BarLeft + BarW, Y + 22);

    // Valor derecha: deficit
    Cv.Brush.Style := bsClear;
    Cv.Font.Color := clRed;
    Cv.Font.Style := [fsBold];
    TxtRect := Rect(BarRight + 4, Y + 4, W - PAD, Y + 22);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
      Format('-%s', [FormatFloat('#,##0', Items[i].Deficit)]));
    Cv.Font.Style := [];
    Cv.Font.Color := clGrayText;
    TxtRect := Rect(BarRight + 4, Y + 22, W - PAD, Y + 38);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
      Format('%s / %s', [FormatFloat('#,##0', Items[i].Stock),
                         FormatFloat('#,##0', Items[i].Minimo)]));
  end;

  // Leyenda inferior
  Cv.Brush.Color := COL_ACTUAL;
  Cv.Pen.Color := clBlack;
  Cv.Pen.Width := 1;
  Cv.Rectangle(PAD, H - 18, PAD + 12, H - 8);
  Cv.Brush.Style := bsClear;
  Cv.Font.Color := clBlack;
  Cv.Font.Style := [];
  Cv.Font.Size := 8;
  Cv.TextRect(Rect(PAD + 18, H - 20, PAD + 90, H - 4),
    PAD + 18, H - 18, 'Stock actual');

  Cv.Brush.Color := COL_MIN;
  Cv.Rectangle(PAD + 100, H - 18, PAD + 112, H - 8);
  Cv.Brush.Style := bsClear;
  Cv.TextRect(Rect(PAD + 118, H - 20, W - PAD, H - 4),
    PAD + 118, H - 18, 'M'#237'nimo');
end;

// ---------------------------------------------------------------------------
// Pintura Top-10 Rupturas futuras (barras dobles: pendiente servir vs saldo+entradas)
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.pbRupturasPaint(Sender: TObject);
const
  TIT_H   = 30;
  ROW_H   = 42;
  PAD     = 10;
  LBL_W   = 110;
  VAL_W   = 90;
  COL_DEMANDA: TColor = $002060E0; // rojo: demanda total
  COL_SUMIN:   TColor = $0080B040; // verde: suministro disponible
type
  TTopItem = record
    Codigo: string;
    Demanda, Suministro, Deficit: Double;
  end;
var
  Cv: TCanvas;
  W, H, i, N, BarsW, BarLeft, BarRight, Y, BarW: Integer;
  Items: array[0..9] of TTopItem;
  MaxScale: Double;
  Bm: TBookmark;
  Cod: string;
  Dm, Su, Df, Sa, Pr, Pp, Ps, Cp: Double;
  Inserted: Boolean;
  j, k: Integer;
  TxtRect: TRect;
begin
  Cv := pbRupturas.Canvas;
  W := pbRupturas.Width;
  H := pbRupturas.Height;

  Cv.Brush.Color := clWhite;
  Cv.Brush.Style := bsSolid;
  Cv.FillRect(Rect(0, 0, W, H));

  Cv.Font.Name := 'Segoe UI';
  Cv.Font.Size := 10;
  Cv.Font.Style := [fsBold];
  Cv.Font.Color := clBlack;
  Cv.Brush.Style := bsClear;
  Cv.TextRect(Rect(0, 6, W, 6 + TIT_H), PAD, 8,
    'Top 10 rupturas futuras');

  if (cdsRupturas = nil) or (not cdsRupturas.Active) or cdsRupturas.IsEmpty then
  begin
    Cv.Font.Style := [];
    Cv.Font.Color := clGrayText;
    Cv.TextRect(Rect(0, H div 2 - 10, W, H div 2 + 10), PAD, H div 2 - 8,
      '(sin datos)');
    Exit;
  end;

  N := 0;
  cdsRupturas.DisableControls;
  Bm := cdsRupturas.GetBookmark;
  try
    cdsRupturas.First;
    while not cdsRupturas.Eof do
    begin
      Df := cdsRupturas.FieldByName('Deficit').AsFloat;
      Sa := cdsRupturas.FieldByName('UnidadSaldo').AsFloat;
      Pr := cdsRupturas.FieldByName('PendienteRecibir').AsFloat;
      Pp := cdsRupturas.FieldByName('ProduccionPendiente').AsFloat;
      Ps := cdsRupturas.FieldByName('PendienteServir').AsFloat;
      Cp := cdsRupturas.FieldByName('ConsumoPendiente').AsFloat;
      Cod := cdsRupturas.FieldByName('CodigoArticulo').AsString;

      Su := Sa + Pr + Pp;
      Dm := Ps + Cp;

      Inserted := False;
      for j := 0 to N - 1 do
        if Df > Items[j].Deficit then
        begin
          for k := Min(N, 9) downto j + 1 do
            Items[k] := Items[k - 1];
          Items[j].Codigo     := Cod;
          Items[j].Demanda    := Dm;
          Items[j].Suministro := Su;
          Items[j].Deficit    := Df;
          if N < 10 then Inc(N);
          Inserted := True;
          Break;
        end;
      if (not Inserted) and (N < 10) then
      begin
        Items[N].Codigo     := Cod;
        Items[N].Demanda    := Dm;
        Items[N].Suministro := Su;
        Items[N].Deficit    := Df;
        Inc(N);
      end;

      cdsRupturas.Next;
    end;
  finally
    if Bm <> nil then
    begin
      cdsRupturas.GotoBookmark(Bm);
      cdsRupturas.FreeBookmark(Bm);
    end;
    cdsRupturas.EnableControls;
  end;

  if N = 0 then Exit;

  MaxScale := 0;
  for i := 0 to N - 1 do
  begin
    if Items[i].Demanda    > MaxScale then MaxScale := Items[i].Demanda;
    if Items[i].Suministro > MaxScale then MaxScale := Items[i].Suministro;
  end;
  if MaxScale <= 0 then MaxScale := 1;

  BarLeft  := PAD + LBL_W;
  BarRight := W - PAD - VAL_W;
  BarsW    := BarRight - BarLeft;
  if BarsW < 40 then BarsW := 40;

  Cv.Font.Size := 8;

  for i := 0 to N - 1 do
  begin
    Y := TIT_H + PAD + i * ROW_H;

    Cv.Font.Color := clBlack;
    Cv.Font.Style := [fsBold];
    TxtRect := Rect(PAD, Y + 4, PAD + LBL_W - 4, Y + 22);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top, Items[i].Codigo);

    // Demanda (rojo, arriba)
    Cv.Brush.Color := COL_DEMANDA;
    Cv.Pen.Color := COL_DEMANDA;
    BarW := Round(BarsW * (Items[i].Demanda / MaxScale));
    if BarW < 1 then BarW := 1;
    Cv.Rectangle(BarLeft, Y + 6, BarLeft + BarW, Y + 20);

    // Suministro (verde, abajo)
    Cv.Brush.Color := COL_SUMIN;
    Cv.Pen.Color := COL_SUMIN;
    BarW := Round(BarsW * (Items[i].Suministro / MaxScale));
    if BarW < 1 then BarW := 1;
    Cv.Rectangle(BarLeft, Y + 22, BarLeft + BarW, Y + 36);

    Cv.Brush.Style := bsClear;
    Cv.Font.Color := clRed;
    Cv.Font.Style := [fsBold];
    TxtRect := Rect(BarRight + 4, Y + 4, W - PAD, Y + 22);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
      Format('-%s', [FormatFloat('#,##0', Items[i].Deficit)]));
    Cv.Font.Style := [];
    Cv.Font.Color := clGrayText;
    TxtRect := Rect(BarRight + 4, Y + 22, W - PAD, Y + 38);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
      Format('%s / %s', [FormatFloat('#,##0', Items[i].Suministro),
                         FormatFloat('#,##0', Items[i].Demanda)]));
  end;

  // Leyenda
  Cv.Brush.Color := COL_DEMANDA;
  Cv.Pen.Color := clBlack;
  Cv.Pen.Width := 1;
  Cv.Rectangle(PAD, H - 18, PAD + 12, H - 8);
  Cv.Brush.Style := bsClear;
  Cv.Font.Color := clBlack;
  Cv.Font.Style := [];
  Cv.Font.Size := 8;
  Cv.TextRect(Rect(PAD + 18, H - 20, PAD + 80, H - 4),
    PAD + 18, H - 18, 'Demanda');

  Cv.Brush.Color := COL_SUMIN;
  Cv.Rectangle(PAD + 90, H - 18, PAD + 102, H - 8);
  Cv.Brush.Style := bsClear;
  Cv.TextRect(Rect(PAD + 108, H - 20, W - PAD, H - 4),
    PAD + 108, H - 18, 'Suministro');
end;

// ---------------------------------------------------------------------------
// Pintura Cobertura (DoS) — histograma por bandas de dias
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.pbCoberturaPaint(Sender: TObject);
const
  TIT_H   = 30;
  PAD     = 12;
  N_BANDS = 6;
  BAND_LABELS: array[0..N_BANDS - 1] of string = (
    '0', '1-7', '8-30', '31-90', '91-180', '>180');
  BAND_LIMS: array[0..N_BANDS - 1] of Integer = (
    0, 7, 30, 90, 180, MaxInt);
  COL_BANDS: array[0..N_BANDS - 1] of TColor = (
    $002020E0,   // 0     - rojo intenso (ruptura)
    $004060E0,   // 1-7   - rojo-naranja
    $0040A0E0,   // 8-30  - naranja
    $0040C0F0,   // 31-90 - amarillo
    $0080C040,   // 91-180- verde
    $00A0A0A0    // >180  - gris (sobre-stock)
  );
var
  Cv: TCanvas;
  W, H, ChartTop, ChartBottom, BarsAreaH, MaxBar, BarW, BarGap, X, Y, i, Total: Integer;
  Counts: array[0..N_BANDS - 1] of Integer;
  Bm: TBookmark;
  Dias: Double;
  TxtRect: TRect;
begin
  Cv := pbCobertura.Canvas;
  W := pbCobertura.Width;
  H := pbCobertura.Height;

  Cv.Brush.Color := clWhite;
  Cv.Brush.Style := bsSolid;
  Cv.FillRect(Rect(0, 0, W, H));

  Cv.Font.Name := 'Segoe UI';
  Cv.Font.Size := 10;
  Cv.Font.Style := [fsBold];
  Cv.Font.Color := clBlack;
  Cv.Brush.Style := bsClear;
  Cv.TextRect(Rect(0, 6, W, 6 + TIT_H), PAD, 8,
    'Distribuci'#243'n d'#237'as de cobertura');

  if (cdsCobertura = nil) or (not cdsCobertura.Active) or cdsCobertura.IsEmpty then
  begin
    Cv.Font.Style := [];
    Cv.Font.Color := clGrayText;
    Cv.TextRect(Rect(0, H div 2 - 10, W, H div 2 + 10), PAD, H div 2 - 8,
      '(sin datos)');
    Exit;
  end;

  for i := 0 to N_BANDS - 1 do Counts[i] := 0;
  Total := 0;

  cdsCobertura.DisableControls;
  Bm := cdsCobertura.GetBookmark;
  try
    cdsCobertura.First;
    while not cdsCobertura.Eof do
    begin
      Dias := cdsCobertura.FieldByName('DiasCobertura').AsFloat;
      for i := 0 to N_BANDS - 1 do
        if Dias <= BAND_LIMS[i] then
        begin
          Inc(Counts[i]);
          Break;
        end;
      Inc(Total);
      cdsCobertura.Next;
    end;
  finally
    if Bm <> nil then
    begin
      cdsCobertura.GotoBookmark(Bm);
      cdsCobertura.FreeBookmark(Bm);
    end;
    cdsCobertura.EnableControls;
  end;

  if Total = 0 then Exit;

  MaxBar := 0;
  for i := 0 to N_BANDS - 1 do
    if Counts[i] > MaxBar then MaxBar := Counts[i];
  if MaxBar = 0 then Exit;

  ChartTop    := TIT_H + PAD;
  ChartBottom := H - 60; // espacio para etiquetas X y leyenda total
  BarsAreaH   := ChartBottom - ChartTop;
  if BarsAreaH < 40 then BarsAreaH := 40;

  BarGap := 8;
  BarW := (W - PAD * 2 - BarGap * (N_BANDS - 1)) div N_BANDS;
  if BarW < 10 then BarW := 10;

  Cv.Font.Size := 8;

  for i := 0 to N_BANDS - 1 do
  begin
    X := PAD + i * (BarW + BarGap);
    Y := ChartBottom - Round(BarsAreaH * (Counts[i] / MaxBar));

    Cv.Brush.Color := COL_BANDS[i];
    Cv.Pen.Color := COL_BANDS[i];
    Cv.Rectangle(X, Y, X + BarW, ChartBottom);

    // Numero encima de la barra
    Cv.Brush.Style := bsClear;
    Cv.Font.Color := clBlack;
    Cv.Font.Style := [fsBold];
    TxtRect := Rect(X, Y - 16, X + BarW, Y - 2);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
      IntToStr(Counts[i]));

    // Etiqueta X
    Cv.Font.Style := [];
    Cv.Font.Color := clGrayText;
    TxtRect := Rect(X, ChartBottom + 4, X + BarW, ChartBottom + 20);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top, BAND_LABELS[i]);
    // % debajo
    TxtRect := Rect(X, ChartBottom + 20, X + BarW, ChartBottom + 34);
    Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
      Format('%d%%', [Round(Counts[i] * 100 / Total)]));
  end;

  // Total al pie
  Cv.Font.Size := 9;
  Cv.Font.Color := clGrayText;
  Cv.Font.Style := [];
  TxtRect := Rect(PAD, H - 18, W - PAD, H - 4);
  Cv.TextRect(TxtRect, TxtRect.Left, TxtRect.Top,
    Format('Total: %d art'#237'culos (d'#237'as)', [Total]));
end;

// ---------------------------------------------------------------------------
// Drill-down: doble-click obre Article Detail
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.DblClickGenerico(ACds: TClientDataSet);
var
  Codigo: string;
begin
  if (ACds = nil) or ACds.IsEmpty then Exit;
  Codigo := ACds.FieldByName('CodigoArticulo').AsString;
  if Codigo <> '' then
    AbrirArticleDetail(Codigo);
end;

procedure TfrmStockCockpit.AbrirArticleDetail(const ACodigoArticulo: string);
begin
  TfrmArticleDetail.Execute(FReader, ACodigoArticulo);
end;

procedure TfrmStockCockpit.grdCriticoViewDblClick(Sender: TObject);
begin
  DblClickGenerico(cdsCritico);
end;

procedure TfrmStockCockpit.grdRupturasViewDblClick(Sender: TObject);
begin
  DblClickGenerico(cdsRupturas);
end;

procedure TfrmStockCockpit.grdObsoletoViewDblClick(Sender: TObject);
begin
  DblClickGenerico(cdsObsoleto);
end;

procedure TfrmStockCockpit.grdCoberturaViewDblClick(Sender: TObject);
begin
  DblClickGenerico(cdsCobertura);
end;

procedure TfrmStockCockpit.grdABCViewDblClick(Sender: TObject);
begin
  DblClickGenerico(cdsABC);
end;

// ---------------------------------------------------------------------------
// Pintar fons segons valor
// ---------------------------------------------------------------------------

procedure TfrmStockCockpit.grdCriticoViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  RecIdx: Integer;
  Disp: Variant;
  DispVal: Double;
begin
  RecIdx := AViewInfo.GridRecord.RecordIndex;
  if RecIdx < 0 then Exit;
  Disp := Sender.DataController.Values[RecIdx,
    grdCriticoView.GetColumnByFieldName('Disponible').Index];
  if VarIsNull(Disp) then Exit;
  DispVal := Disp;
  if DispVal <= 0 then
  begin
    ACanvas.Brush.Color := $00CCCCFF;
    ACanvas.Font.Color := clMaroon;
  end
  else
    ACanvas.Brush.Color := $00CCE5FF;
end;

procedure TfrmStockCockpit.grdRupturasViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  RecIdx: Integer;
  Saldo: Variant;
  SaldoVal: Double;
begin
  RecIdx := AViewInfo.GridRecord.RecordIndex;
  if RecIdx < 0 then Exit;
  Saldo := Sender.DataController.Values[RecIdx,
    grdRupturasView.GetColumnByFieldName('SaldoFinal').Index];
  if VarIsNull(Saldo) then Exit;
  SaldoVal := Saldo;
  if SaldoVal <= 0 then
  begin
    ACanvas.Brush.Color := $00CCCCFF;
    ACanvas.Font.Color := clMaroon;
  end
  else
    ACanvas.Brush.Color := $00CCE5FF;
end;

procedure TfrmStockCockpit.grdCoberturaViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  RecIdx: Integer;
  Dias: Variant;
  DiasVal: Double;
begin
  RecIdx := AViewInfo.GridRecord.RecordIndex;
  if RecIdx < 0 then Exit;
  Dias := Sender.DataController.Values[RecIdx,
    grdCoberturaView.GetColumnByFieldName('DiasCobertura').Index];
  if VarIsNull(Dias) then Exit;
  DiasVal := Dias;
  if DiasVal < 0 then
    ACanvas.Brush.Color := $00E0E0E0   // sense consum: gris
  else if DiasVal < 7 then
  begin
    ACanvas.Brush.Color := $00CCCCFF;   // < 1 setmana: alerta vermella
    ACanvas.Font.Color := clMaroon;
  end
  else if DiasVal < 30 then
    ACanvas.Brush.Color := $00CCE5FF    // < 1 mes: groc clar
  else if DiasVal > 365 then
    ACanvas.Brush.Color := $00CCFFCC;   // > 1 any: verd (exces)
end;

procedure TfrmStockCockpit.grdABCViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  RecIdx: Integer;
  Cat: Variant;
begin
  RecIdx := AViewInfo.GridRecord.RecordIndex;
  if RecIdx < 0 then Exit;
  Cat := Sender.DataController.Values[RecIdx,
    grdABCView.GetColumnByFieldName('Categoria').Index];
  if VarIsNull(Cat) then Exit;
  case VarToStr(Cat)[Low(string)] of
    'A': ACanvas.Brush.Color := $00CCFFCC;  // verd
    'B': ACanvas.Brush.Color := $00CCE5FF;  // groc clar
    'C': ACanvas.Brush.Color := $00E0E0E0;  // gris
  end;
end;

procedure TfrmStockCockpit.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
