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
  System.UITypes, System.DateUtils, System.Generics.Collections,
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
  finally
    Screen.Cursor := crDefault;
  end;
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
