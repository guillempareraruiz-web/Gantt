unit uSyncBacklogPreview;
{
  TfrmSyncBacklogPreview - Preview y aplicacion selectiva de la sincronizacion
  ERP -> Backlog (FS_PL_Raw_Item).
  Flujo:
    1. OnShow: llama a TErpSyncRepo.PreviewBacklogOF (filtra OFs Estado IN 0,1).
    2. Pinta el resultado en un cxGrid agrupado por OF -> OT -> OP.
    3. El usuario marca/desmarca filas (checkbox por fila + select-all global).
    4. Boton "Sincronizar seleccionados" -> ApplyRawItems con los marcados.
    5. Cierra y refresca el Backlog del caller.
}
interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, cxTextEdit, cxCalendar, cxCheckBox, cxNavigator,
  cxCustomData, cxData, cxDataStorage, cxButtons,
  Data.Win.ADODB,
  uErpReader, uErpSyncRepo, uErpSyncTypes, dxSkinsCore, dxSkinBasic,
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
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, Vcl.Menus, dxDateRanges,
  dxScrollbarAnnotations;
type
  TfrmSyncBacklogPreview = class(TForm)
    pnlTop: TPanel;
    pnlBottom: TPanel;
    lblTitulo: TLabel;
    lblResumen: TLabel;
    btnSelectAll: TcxButton;
    btnDeselectAll: TcxButton;
    btnAplicar: TcxButton;
    btnCancelar: TcxButton;
    Grid: TcxGrid;
    GridLevel: TcxGridLevel;
    GridView: TcxGridTableView;
    colAplicar: TcxGridColumn;
    colTipo: TcxGridColumn;
    colOF: TcxGridColumn;
    colOT: TcxGridColumn;
    colOP: TcxGridColumn;
    colNivel: TcxGridColumn;
    btnAgrupar: TcxButton;
    colClaveERP: TcxGridColumn;
    colCodigo: TcxGridColumn;
    colDescripcion: TcxGridColumn;
    colArticulo: TcxGridColumn;
    colCantidad: TcxGridColumn;
    colCentroPref: TcxGridColumn;
    colFechaCompromiso: TcxGridColumn;
    colHorasEst: TcxGridColumn;
    colEstado: TcxGridColumn;
    colAccion: TcxGridColumn;
    procedure btnAgruparClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnDeselectAllClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure GridViewCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  private
    FConn: TADOConnection;
    FCodigoEmpresa: SmallInt;
    FErpSistema: string;
    FReader: IErpReader;
    FEjercicio: SmallInt;
    FRows: TArray<TSyncRowRawItem>;
    FApplied: Boolean;
    procedure LoadPreview;
    procedure RefreshGrid;
    procedure RefreshResumen;
    procedure SetAllAplicar(AValue: Boolean);
  public
    property Applied: Boolean read FApplied;
    class function Execute(AOwner: TComponent; AConn: TADOConnection;
      ACodigoEmpresa: SmallInt; const AErpSistema: string;
      AReader: IErpReader; AEjercicio: SmallInt): Boolean;
  end;
implementation
{$R *.dfm}
uses
  System.DateUtils;
class function TfrmSyncBacklogPreview.Execute(AOwner: TComponent;
  AConn: TADOConnection; ACodigoEmpresa: SmallInt;
  const AErpSistema: string; AReader: IErpReader;
  AEjercicio: SmallInt): Boolean;
var
  Frm: TfrmSyncBacklogPreview;
begin
  Frm := TfrmSyncBacklogPreview.Create(AOwner);
  try
    Frm.FConn := AConn;
    Frm.FCodigoEmpresa := ACodigoEmpresa;
    Frm.FErpSistema := AErpSistema;
    Frm.FReader := AReader;
    Frm.FEjercicio := AEjercicio;
    Frm.ShowModal;
    Result := Frm.Applied;
  finally
    Frm.Free;
  end;
end;
procedure TfrmSyncBacklogPreview.FormShow(Sender: TObject);
begin
  LoadPreview;
end;
procedure TfrmSyncBacklogPreview.FormDestroy(Sender: TObject);
begin
  SetLength(FRows, 0);
end;
procedure TfrmSyncBacklogPreview.LoadPreview;
var
  Repo: TErpSyncRepo;
begin
  Screen.Cursor := crHourGlass;
  try
    Repo := TErpSyncRepo.Create(FConn, FCodigoEmpresa, FErpSistema);
    try
      FRows := Repo.PreviewBacklogOF(FReader, FEjercicio);
    finally
      Repo.Free;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  RefreshGrid;
  RefreshResumen;
end;
procedure TfrmSyncBacklogPreview.RefreshGrid;
var
  I: Integer;
  Row: TSyncRowRawItem;
  Origen, OFTxt, OTTxt, OPTxt: string;
  ByClave: TDictionary<string, TSyncRowRawItem>;
  Parent, Grand: TSyncRowRawItem;
begin
  // Indexem totes les files per ClaveERP per resoldre pares en O(1)
  ByClave := TDictionary<string, TSyncRowRawItem>.Create;
  try
    for I := 0 to High(FRows) do
      ByClave.AddOrSetValue(FRows[I].ErpData.ClaveERP, FRows[I]);
    GridView.BeginUpdate;
    try
      GridView.DataController.RecordCount := 0;
      GridView.DataController.RecordCount := Length(FRows);
      for I := 0 to High(FRows) do
      begin
        Row := FRows[I];
        case Row.ErpData.Nivel of
          1: Origen := 'OF';
          2: Origen := 'OT';
          3: Origen := 'OP';
        else
          Origen := '?';
        end;
        // Calcul OF/OT/OP pujant per ClaveERPPadre fins on calgui
        OFTxt := ''; OTTxt := ''; OPTxt := '';
        case Row.ErpData.Nivel of
          1: OFTxt := Format('%s-%d',
               [Trim(Row.ErpData.SerieDoc), Row.ErpData.NumeroDoc]);
          2: begin
               OTTxt := IntToStr(Row.ErpData.LineaDoc);
               if ByClave.TryGetValue(Row.ErpData.ClaveERPPadre, Parent) then
                 OFTxt := Format('%s-%d',
                   [Trim(Parent.ErpData.SerieDoc), Parent.ErpData.NumeroDoc]);
             end;
          3: begin
               OPTxt := IntToStr(Row.ErpData.Orden);
               if ByClave.TryGetValue(Row.ErpData.ClaveERPPadre, Parent) then
               begin
                 OTTxt := IntToStr(Parent.ErpData.LineaDoc);
                 if ByClave.TryGetValue(Parent.ErpData.ClaveERPPadre, Grand) then
                   OFTxt := Format('%s-%d',
                     [Trim(Grand.ErpData.SerieDoc), Grand.ErpData.NumeroDoc]);
               end;
             end;
        end;
        GridView.DataController.Values[I, colAplicar.Index]   := Row.Aplicar;
        GridView.DataController.Values[I, colTipo.Index]      := Origen;
        GridView.DataController.Values[I, colOF.Index]        := OFTxt;
        GridView.DataController.Values[I, colOT.Index]        := OTTxt;
        GridView.DataController.Values[I, colOP.Index]        := OPTxt;
        GridView.DataController.Values[I, colNivel.Index]     := Row.ErpData.Nivel;
        GridView.DataController.Values[I, colClaveERP.Index]  := Row.ErpData.ClaveERP;
        GridView.DataController.Values[I, colCodigo.Index]    := Row.ErpData.Codigo;
        GridView.DataController.Values[I, colDescripcion.Index] := Row.ErpData.Nombre;
        GridView.DataController.Values[I, colArticulo.Index]  := Row.ErpData.CodigoArticulo;
        GridView.DataController.Values[I, colCantidad.Index]  := Row.ErpData.Cantidad;
        GridView.DataController.Values[I, colCentroPref.Index]:= Row.ErpData.CentroPreferente;
        if Row.ErpData.FechaCompromiso > 0 then
          GridView.DataController.Values[I, colFechaCompromiso.Index] := Row.ErpData.FechaCompromiso
        else
          GridView.DataController.Values[I, colFechaCompromiso.Index] := Null;
        GridView.DataController.Values[I, colHorasEst.Index]  := Row.ErpData.HorasEstimadas;
        GridView.DataController.Values[I, colEstado.Index]    := Row.ErpData.EstadoERP;
        GridView.DataController.Values[I, colAccion.Index]    := SyncStatusToText(Row.Status);
      end;
    finally
      GridView.EndUpdate;
    end;
  finally
    ByClave.Free;
  end;
end;
procedure TfrmSyncBacklogPreview.btnAgruparClick(Sender: TObject);
var
  Agrupado: Boolean;
begin
  Agrupado := colOF.GroupIndex >= 0;
  GridView.BeginUpdate;
  try
    if Agrupado then
    begin
      colOF.GroupIndex := -1;
      colOT.GroupIndex := -1;
      colOP.GroupIndex := -1;
      btnAgrupar.Caption := 'Agrupar por OF/OT/OP';
    end
    else
    begin
      colOF.GroupIndex := 0;
      colOT.GroupIndex := 1;
      colOP.GroupIndex := 2;
      GridView.DataController.Groups.FullExpand;
      btnAgrupar.Caption := 'Desagrupar';
    end;
  finally
    GridView.EndUpdate;
  end;
end;
procedure TfrmSyncBacklogPreview.RefreshResumen;
var
  Row: TSyncRowRawItem;
  Nuevos, Actu, Sin_, Elim, Sel: Integer;
begin
  Nuevos := 0; Actu := 0; Sin_ := 0; Elim := 0; Sel := 0;
  for Row in FRows do
  begin
    case Row.Status of
      ssNuevo:        Inc(Nuevos);
      ssActualizado:  Inc(Actu);
      ssSinCambios:   Inc(Sin_);
      ssEliminadoErp: Inc(Elim);
    end;
    if Row.Aplicar then Inc(Sel);
  end;
  lblResumen.Caption :=
    Format('Total: %d   Nuevos: %d   Actualizados: %d   Sin cambios: %d   Obsoletos: %d   ' +
           'Seleccionados: %d',
           [Length(FRows), Nuevos, Actu, Sin_, Elim, Sel]);
end;
procedure TfrmSyncBacklogPreview.SetAllAplicar(AValue: Boolean);
var
  I: Integer;
begin
  for I := 0 to High(FRows) do
    if FRows[I].Status in [ssNuevo, ssActualizado, ssEliminadoErp] then
    begin
      // No marcar obsolets que tinguin node planificat
      if (FRows[I].Status = ssEliminadoErp) and FRows[I].HasPlannedNode then
        FRows[I].Aplicar := False
      else
        FRows[I].Aplicar := AValue;
    end;
  RefreshGrid;
  RefreshResumen;
end;
procedure TfrmSyncBacklogPreview.btnSelectAllClick(Sender: TObject);
begin
  SetAllAplicar(True);
end;
procedure TfrmSyncBacklogPreview.btnDeselectAllClick(Sender: TObject);
begin
  SetAllAplicar(False);
end;
procedure TfrmSyncBacklogPreview.btnAplicarClick(Sender: TObject);
var
  Repo: TErpSyncRepo;
  Summary: TSyncSummary;
  I: Integer;
  V: Variant;
begin
  // Recull el valor del checkbox del grid a l'array
  for I := 0 to High(FRows) do
  begin
    V := GridView.DataController.Values[I, colAplicar.Index];
    FRows[I].Aplicar := (not VarIsNull(V)) and Boolean(V);
  end;
  Screen.Cursor := crHourGlass;
  try
    Repo := TErpSyncRepo.Create(FConn, FCodigoEmpresa, FErpSistema);
    try
      Summary := Repo.ApplyRawItems(FRows);
    finally
      Repo.Free;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  ShowMessage(Format(
    'Sincronizacion completada.'#13#10#13#10 +
    'Aplicados: %d'#13#10 +
    'Nuevos: %d   Actualizados: %d   Obsoletos: %d   Errores: %d',
    [Summary.Aplicados, Summary.Nuevos, Summary.Actualizados,
     Summary.Eliminados, Summary.Errores]));
  FApplied := True;
  ModalResult := mrOk;
end;
procedure TfrmSyncBacklogPreview.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;
procedure TfrmSyncBacklogPreview.GridViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  Idx: Integer;
begin
  Idx := AViewInfo.GridRecord.RecordIndex;
  if (Idx >= 0) and (Idx <= High(FRows)) then
    ACanvas.Brush.Color := SyncStatusColor(FRows[Idx].Status);
end;
end.
