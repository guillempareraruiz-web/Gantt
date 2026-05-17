unit uDashboardOperativo;

// ============================================================================
// Dashboard operativo — vista global de la planta des de l'ERP actiu.
//
// Layout:
//   - Strip superior: 6 KPI cards (OFs curso, OFs retraso, Rupturas 30d,
//     Stock critico, Stock obsoleto, Cartera venta pendiente).
//   - Cos 2x2: top 10 ruptures / top 10 stock critic / top 10 OFs
//     imminents / top 10 articles A sense stock.
//
// Tot via IErpReader; sense queries directes a l'ERP.
// ============================================================================

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.DateUtils,
  Winapi.Windows, Winapi.Messages,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Data.DB, Datasnap.DBClient,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, dxCore,
  cxGridLevel, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxClasses, cxGridCustomView, cxGrid, cxDBData,
  uErpReader, uErpTypes, uArticleDetail, uOFInspector;

type
  TfrmDashboardOperativo = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    btnRefrescar: TButton;
    pnlKPIs: TPanel;
    pnlKPI1: TPanel;
    lblKPI1Cap: TLabel;
    lblKPI1Val: TLabel;
    lblKPI1Sub: TLabel;
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
    pnlBody: TPanel;
    pnlTopLeft: TPanel;
    lblTopRupt: TLabel;
    grdRupt: TcxGrid;
    grdRuptView: TcxGridDBTableView;
    grdRuptLevel: TcxGridLevel;
    splitV: TSplitter;
    pnlTopRight: TPanel;
    lblTopCrit: TLabel;
    grdCrit: TcxGrid;
    grdCritView: TcxGridDBTableView;
    grdCritLevel: TcxGridLevel;
    splitH: TSplitter;
    pnlBot: TPanel;
    pnlBotLeft: TPanel;
    lblTopOF: TLabel;
    grdOF: TcxGrid;
    grdOFView: TcxGridDBTableView;
    grdOFLevel: TcxGridLevel;
    splitV2: TSplitter;
    pnlBotRight: TPanel;
    lblTopA: TLabel;
    grdA: TcxGrid;
    grdAView: TcxGridDBTableView;
    grdALevel: TcxGridLevel;
    cdsRupt: TClientDataSet;
    dsRupt: TDataSource;
    cdsCrit: TClientDataSet;
    dsCrit: TDataSource;
    cdsOF: TClientDataSet;
    dsOF: TDataSource;
    cdsA: TClientDataSet;
    dsA: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnRefrescarClick(Sender: TObject);
    procedure grdRuptViewDblClick(Sender: TObject);
    procedure grdCritViewDblClick(Sender: TObject);
    procedure grdOFViewDblClick(Sender: TObject);
    procedure grdAViewDblClick(Sender: TObject);
  private
    FReader: IErpReader;
    FProgressFrm: TForm;
    FProgressLbl: TLabel;
    procedure CrearColumnas;
    procedure SetKPI(APanel: TPanel; AValLbl: TLabel; const AValor: string;
      AColorFondo: TColor);
    procedure Refrescar;
    procedure CargarKPIs;
    procedure CargarRupturas;
    procedure CargarStockCritico;
    procedure CargarOFsImminents;
    procedure CargarArticulosASinStock;
    procedure ProgressShow(const AMensaje: string);
    procedure ProgressUpdate(const AMensaje: string);
    procedure ProgressHide;
    procedure AbrirArticleDetail(const ACodArt: string);
  public
    class procedure Execute(const AReader: IErpReader);
  end;

implementation

{$R *.dfm}

const
  COLOR_NEUTRE = TColor($00404040);
  COLOR_OK     = TColor($00377D22);
  COLOR_INFO   = TColor($00A6651C);
  COLOR_WARN   = TColor($000098D8);
  COLOR_CRIT   = TColor($003C3CC8);

class procedure TfrmDashboardOperativo.Execute(const AReader: IErpReader);
var
  Frm: TfrmDashboardOperativo;
begin
  Frm := TfrmDashboardOperativo.Create(nil);
  try
    Frm.FReader := AReader;
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TfrmDashboardOperativo.FormCreate(Sender: TObject);
begin
  CrearColumnas;
end;

procedure TfrmDashboardOperativo.FormShow(Sender: TObject);
begin
  if FReader <> nil then Refrescar;
end;

procedure TfrmDashboardOperativo.btnRefrescarClick(Sender: TObject);
begin
  if FReader = nil then Exit;
  Refrescar;
end;

procedure TfrmDashboardOperativo.CrearColumnas;
begin
  cdsRupt.FieldDefs.Clear;
  cdsRupt.FieldDefs.Add('Articulo', ftString, 30);
  cdsRupt.FieldDefs.Add('Descripcion', ftString, 100);
  cdsRupt.FieldDefs.Add('Almacen', ftString, 20);
  cdsRupt.FieldDefs.Add('Saldo', ftFloat);
  cdsRupt.FieldDefs.Add('SaldoFinal', ftFloat);
  cdsRupt.FieldDefs.Add('Minimo', ftFloat);
  cdsRupt.FieldDefs.Add('Deficit', ftFloat);
  cdsRupt.CreateDataSet;

  cdsCrit.FieldDefs.Clear;
  cdsCrit.FieldDefs.Add('Articulo', ftString, 30);
  cdsCrit.FieldDefs.Add('Descripcion', ftString, 100);
  cdsCrit.FieldDefs.Add('Almacen', ftString, 20);
  cdsCrit.FieldDefs.Add('Disponible', ftFloat);
  cdsCrit.FieldDefs.Add('Minimo', ftFloat);
  cdsCrit.FieldDefs.Add('Deficit', ftFloat);
  cdsCrit.CreateDataSet;

  cdsOF.FieldDefs.Clear;
  cdsOF.FieldDefs.Add('OF', ftString, 30);
  cdsOF.FieldDefs.Add('Articulo', ftString, 30);
  cdsOF.FieldDefs.Add('Descripcion', ftString, 100);
  cdsOF.FieldDefs.Add('FechaFin', ftDate);
  cdsOF.FieldDefs.Add('Desfase', ftInteger);
  cdsOF.FieldDefs.Add('Estado', ftString, 20);
  cdsOF.FieldDefs.Add('Progreso', ftFloat);
  // Camps interns per al doble-clic (no els tornem a posar al grid)
  cdsOF.FieldDefs.Add('Ejercicio', ftSmallint);
  cdsOF.FieldDefs.Add('Serie', ftString, 10);
  cdsOF.FieldDefs.Add('Numero', ftInteger);
  cdsOF.CreateDataSet;

  cdsA.FieldDefs.Clear;
  cdsA.FieldDefs.Add('Articulo', ftString, 30);
  cdsA.FieldDefs.Add('Descripcion', ftString, 100);
  cdsA.FieldDefs.Add('Familia', ftString, 30);
  cdsA.FieldDefs.Add('Disponible', ftFloat);
  cdsA.FieldDefs.Add('ImporteAno', ftFloat);
  cdsA.CreateDataSet;
end;

procedure TfrmDashboardOperativo.SetKPI(APanel: TPanel; AValLbl: TLabel;
  const AValor: string; AColorFondo: TColor);
begin
  APanel.Color := AColorFondo;
  AValLbl.Caption := AValor;
end;

procedure TfrmDashboardOperativo.Refrescar;
begin
  Screen.Cursor := crHourGlass;
  ProgressShow('Cargando indicadores...');
  try
    ProgressUpdate('Cargando KPIs globales...');
    CargarKPIs;
    ProgressUpdate('Cargando rupturas previstas...');
    CargarRupturas;
    ProgressUpdate('Cargando stock cr'#237'tico...');
    CargarStockCritico;
    ProgressUpdate('Cargando OFs imminentes...');
    CargarOFsImminents;
    ProgressUpdate('Cargando art'#237'culos A sin stock...');
    CargarArticulosASinStock;
  finally
    ProgressHide;
    Screen.Cursor := crDefault;
  end;
end;

// ---------------------------------------------------------------------------
// Progress window: form modal lleuger sense interaccio.
// ---------------------------------------------------------------------------

procedure TfrmDashboardOperativo.ProgressShow(const AMensaje: string);
begin
  if FProgressFrm <> nil then Exit;
  FProgressFrm := TForm.Create(Self);
  FProgressFrm.BorderStyle := bsToolWindow;
  FProgressFrm.BorderIcons := [];
  FProgressFrm.FormStyle := fsStayOnTop;
  FProgressFrm.Position := poOwnerFormCenter;
  FProgressFrm.Width := 360;
  FProgressFrm.Height := 90;
  FProgressFrm.Caption := 'Dashboard operativo';
  FProgressFrm.Color := clWhite;

  FProgressLbl := TLabel.Create(FProgressFrm);
  FProgressLbl.Parent := FProgressFrm;
  FProgressLbl.Left := 24;
  FProgressLbl.Top := 28;
  FProgressLbl.Width := FProgressFrm.ClientWidth - 48;
  FProgressLbl.AutoSize := False;
  FProgressLbl.Caption := AMensaje;
  FProgressLbl.Font.Name := 'Segoe UI';
  FProgressLbl.Font.Size := 10;
  FProgressLbl.Font.Style := [fsBold];

  FProgressFrm.Show;
  FProgressFrm.Update;
  Application.ProcessMessages;
end;

procedure TfrmDashboardOperativo.ProgressUpdate(const AMensaje: string);
begin
  if FProgressLbl <> nil then
  begin
    FProgressLbl.Caption := AMensaje;
    FProgressLbl.Update;
    if FProgressFrm <> nil then FProgressFrm.Update;
    Application.ProcessMessages;
  end;
end;

procedure TfrmDashboardOperativo.ProgressHide;
begin
  if FProgressFrm <> nil then
  begin
    FProgressFrm.Close;
    FreeAndNil(FProgressFrm);
    FProgressLbl := nil;
  end;
end;

// ---------------------------------------------------------------------------
// Doble-clic: obre Article Detail amb el codi article de la fila.
// ---------------------------------------------------------------------------

procedure TfrmDashboardOperativo.AbrirArticleDetail(const ACodArt: string);
begin
  if (FReader = nil) or (Trim(ACodArt) = '') then Exit;
  TfrmArticleDetail.Execute(FReader, ACodArt);
end;

procedure TfrmDashboardOperativo.grdRuptViewDblClick(Sender: TObject);
begin
  if not cdsRupt.Active or cdsRupt.IsEmpty then Exit;
  AbrirArticleDetail(cdsRupt.FieldByName('Articulo').AsString);
end;

procedure TfrmDashboardOperativo.grdCritViewDblClick(Sender: TObject);
begin
  if not cdsCrit.Active or cdsCrit.IsEmpty then Exit;
  AbrirArticleDetail(cdsCrit.FieldByName('Articulo').AsString);
end;

procedure TfrmDashboardOperativo.grdOFViewDblClick(Sender: TObject);
begin
  if not cdsOF.Active or cdsOF.IsEmpty then Exit;
  TfrmOFInspector.Execute(FReader,
    cdsOF.FieldByName('Ejercicio').AsInteger,
    cdsOF.FieldByName('Serie').AsString,
    cdsOF.FieldByName('Numero').AsInteger);
end;

procedure TfrmDashboardOperativo.grdAViewDblClick(Sender: TObject);
begin
  if not cdsA.Active or cdsA.IsEmpty then Exit;
  AbrirArticleDetail(cdsA.FieldByName('Articulo').AsString);
end;

procedure TfrmDashboardOperativo.CargarKPIs;
var
  OFs: TArray<TOFGlobalErp>;
  Rupt: TArray<TRupturaFuturaErp>;
  Crit: TArray<TStockCriticoErp>;
  Obs: TArray<TStockObsoletoErp>;
  Ventas: TArray<TSalidaFuturaVentaErp>;
  i, OFsCurso, OFsRetraso: Integer;
  ValorObs, CarteraVenta: Double;
begin
  // KPIs 1 i 2: OFs activas vs retrasadas (top suficient per agafar-les totes)
  try
    OFs := FReader.ReadOFsActivasTop(True, 9999);
  except
    on E: Exception do
    begin
      OFs := nil;
    end;
  end;
  OFsCurso := 0; OFsRetraso := 0;
  for i := 0 to High(OFs) do
  begin
    if OFs[i].EstadoOF in [1, 2] then
    begin
      Inc(OFsCurso);
      if (OFs[i].FechaFinalPrevista > 0) and (OFs[i].FechaFinalPrevista < Date) then
        Inc(OFsRetraso);
    end;
  end;
  SetKPI(pnlKPI1, lblKPI1Val, IntToStr(OFsCurso), COLOR_NEUTRE);
  if OFsRetraso = 0 then
    SetKPI(pnlKPI2, lblKPI2Val, '0', COLOR_OK)
  else if OFsRetraso < 5 then
    SetKPI(pnlKPI2, lblKPI2Val, IntToStr(OFsRetraso), COLOR_WARN)
  else
    SetKPI(pnlKPI2, lblKPI2Val, IntToStr(OFsRetraso), COLOR_CRIT);

  // KPI 3: Rupturas 30 dies
  try
    Rupt := FReader.ReadRupturasFuturas(nil, '', 30);
  except
    Rupt := nil;
  end;
  if Length(Rupt) = 0 then
    SetKPI(pnlKPI3, lblKPI3Val, '0', COLOR_OK)
  else if Length(Rupt) < 10 then
    SetKPI(pnlKPI3, lblKPI3Val, IntToStr(Length(Rupt)), COLOR_WARN)
  else
    SetKPI(pnlKPI3, lblKPI3Val, IntToStr(Length(Rupt)), COLOR_CRIT);

  // KPI 4: Stock critico
  try
    Crit := FReader.ReadStockCritico(nil, '');
  except
    Crit := nil;
  end;
  if Length(Crit) = 0 then
    SetKPI(pnlKPI4, lblKPI4Val, '0', COLOR_OK)
  else if Length(Crit) < 20 then
    SetKPI(pnlKPI4, lblKPI4Val, IntToStr(Length(Crit)), COLOR_WARN)
  else
    SetKPI(pnlKPI4, lblKPI4Val, IntToStr(Length(Crit)), COLOR_CRIT);

  // KPI 5: Stock obsoleto (6 mesos)
  try
    Obs := FReader.ReadStockObsoleto(nil, '', 6);
  except
    Obs := nil;
  end;
  ValorObs := 0;
  for i := 0 to High(Obs) do
    ValorObs := ValorObs + Obs[i].ImporteSaldo;
  if ValorObs = 0 then
    SetKPI(pnlKPI5, lblKPI5Val, '0 '#8364, COLOR_OK)
  else
    SetKPI(pnlKPI5, lblKPI5Val, FormatFloat('#,##0 '#8364, ValorObs), COLOR_INFO);

  // KPI 6: Cartera venta pendent (90 dies)
  try
    Ventas := FReader.ReadSalidasFuturasVenta('', nil, 0, IncDay(Date, 90));
  except
    Ventas := nil;
  end;
  CarteraVenta := 0;
  for i := 0 to High(Ventas) do
    CarteraVenta := CarteraVenta + Ventas[i].UnidadesPendientes * Ventas[i].Precio;
  if CarteraVenta = 0 then
    SetKPI(pnlKPI6, lblKPI6Val, '0 '#8364, COLOR_NEUTRE)
  else
    SetKPI(pnlKPI6, lblKPI6Val, FormatFloat('#,##0 '#8364, CarteraVenta), COLOR_INFO);
end;

procedure TfrmDashboardOperativo.CargarRupturas;
var
  Data: TArray<TRupturaFuturaErp>;
  i, N: Integer;
begin
  cdsRupt.DisableControls;
  try
    cdsRupt.EmptyDataSet;
    try
      Data := FReader.ReadRupturasFuturas(nil, '', 30);
    except
      Data := nil;
    end;
    N := Length(Data);
    if N > 10 then N := 10;
    for i := 0 to N - 1 do
    begin
      cdsRupt.Append;
      cdsRupt.FieldByName('Articulo').AsString    := Data[i].CodigoArticulo;
      cdsRupt.FieldByName('Descripcion').AsString := Data[i].DescripcionArticulo;
      cdsRupt.FieldByName('Almacen').AsString     := Data[i].CodigoAlmacen;
      cdsRupt.FieldByName('Saldo').AsFloat        := Data[i].UnidadSaldo;
      cdsRupt.FieldByName('SaldoFinal').AsFloat   := Data[i].SaldoFinal;
      cdsRupt.FieldByName('Minimo').AsFloat       := Data[i].StockMinimo;
      cdsRupt.FieldByName('Deficit').AsFloat      := Data[i].Deficit;
      cdsRupt.Post;
    end;
    cdsRupt.First;
  finally
    cdsRupt.EnableControls;
  end;
  if grdRuptView.ColumnCount = 0 then
    grdRuptView.DataController.CreateAllItems;
  grdRuptView.ApplyBestFit;
end;

procedure TfrmDashboardOperativo.CargarStockCritico;
var
  Data: TArray<TStockCriticoErp>;
  i, N: Integer;
begin
  cdsCrit.DisableControls;
  try
    cdsCrit.EmptyDataSet;
    try
      Data := FReader.ReadStockCritico(nil, '');
    except
      Data := nil;
    end;
    N := Length(Data);
    if N > 10 then N := 10;
    for i := 0 to N - 1 do
    begin
      cdsCrit.Append;
      cdsCrit.FieldByName('Articulo').AsString    := Data[i].CodigoArticulo;
      cdsCrit.FieldByName('Descripcion').AsString := Data[i].DescripcionArticulo;
      cdsCrit.FieldByName('Almacen').AsString     := Data[i].CodigoAlmacen;
      cdsCrit.FieldByName('Disponible').AsFloat   := Data[i].Disponible;
      cdsCrit.FieldByName('Minimo').AsFloat       := Data[i].StockMinimo;
      cdsCrit.FieldByName('Deficit').AsFloat      := Data[i].Deficit;
      cdsCrit.Post;
    end;
    cdsCrit.First;
  finally
    cdsCrit.EnableControls;
  end;
  if grdCritView.ColumnCount = 0 then
    grdCritView.DataController.CreateAllItems;
  grdCritView.ApplyBestFit;
end;

procedure TfrmDashboardOperativo.CargarOFsImminents;
var
  Data: TArray<TOFGlobalErp>;
  i: Integer;
begin
  cdsOF.DisableControls;
  try
    cdsOF.EmptyDataSet;
    try
      Data := FReader.ReadOFsActivasTop(True, 10);
    except
      Data := nil;
    end;
    for i := 0 to High(Data) do
    begin
      cdsOF.Append;
      cdsOF.FieldByName('OF').AsString := Format('%s/%d/%d',
        [Data[i].SerieFabricacion, Data[i].EjercicioFabricacion,
         Data[i].NumeroFabricacion]);
      cdsOF.FieldByName('Articulo').AsString    := Data[i].CodigoArticulo;
      cdsOF.FieldByName('Descripcion').AsString := Data[i].DescripcionArticulo;
      if Data[i].FechaFinalPrevista > 0 then
        cdsOF.FieldByName('FechaFin').AsDateTime := Data[i].FechaFinalPrevista;
      cdsOF.FieldByName('Desfase').AsInteger  := Data[i].DiasDesfase;
      cdsOF.FieldByName('Estado').AsString    := Data[i].EstadoDescripcion;
      cdsOF.FieldByName('Progreso').AsFloat   := Data[i].PorcentajeProgreso;
      cdsOF.FieldByName('Ejercicio').AsInteger := Data[i].EjercicioFabricacion;
      cdsOF.FieldByName('Serie').AsString      := Data[i].SerieFabricacion;
      cdsOF.FieldByName('Numero').AsInteger    := Data[i].NumeroFabricacion;
      cdsOF.Post;
    end;
    cdsOF.First;
  finally
    cdsOF.EnableControls;
  end;
  if grdOFView.ColumnCount = 0 then
  begin
    grdOFView.DataController.CreateAllItems;
    // amaga camps interns Ejercicio/Serie/Numero (usats nomes pel doble-clic)
    if grdOFView.GetColumnByFieldName('Ejercicio') <> nil then
      grdOFView.GetColumnByFieldName('Ejercicio').Visible := False;
    if grdOFView.GetColumnByFieldName('Serie') <> nil then
      grdOFView.GetColumnByFieldName('Serie').Visible := False;
    if grdOFView.GetColumnByFieldName('Numero') <> nil then
      grdOFView.GetColumnByFieldName('Numero').Visible := False;
  end;
  grdOFView.ApplyBestFit;
end;

procedure TfrmDashboardOperativo.CargarArticulosASinStock;
var
  Data: TArray<TArticuloACriticoErp>;
  i: Integer;
begin
  cdsA.DisableControls;
  try
    cdsA.EmptyDataSet;
    try
      Data := FReader.ReadArticulosAsinStock(10);
    except
      Data := nil;
    end;
    for i := 0 to High(Data) do
    begin
      cdsA.Append;
      cdsA.FieldByName('Articulo').AsString    := Data[i].CodigoArticulo;
      cdsA.FieldByName('Descripcion').AsString := Data[i].DescripcionArticulo;
      cdsA.FieldByName('Familia').AsString     := Data[i].CodigoFamilia;
      cdsA.FieldByName('Disponible').AsFloat   := Data[i].Disponible;
      cdsA.FieldByName('ImporteAno').AsFloat   := Data[i].ImporteConsumidoUltAno;
      cdsA.Post;
    end;
    cdsA.First;
  finally
    cdsA.EnableControls;
  end;
  if grdAView.ColumnCount = 0 then
    grdAView.DataController.CreateAllItems;
  grdAView.ApplyBestFit;
end;

end.
