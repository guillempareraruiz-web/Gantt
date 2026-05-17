unit uFormulaArticuloViewer;

// ============================================================================
// Visor de formula/escandall de un articulo (multi-ERP).
//
// NO conoce el ERP origen. Habla siempre con IErpReader (uErpReaderFactory).
//
// Expansion LAZY: cada nodo "articulo" se carga al expandirlo.
//   Si un componente tiene EsSemielaborado=True => se marca como expandible
//   y al hacer doble-click se busca su formula propia.
//
// Vista: TreeView (izquierda) + dos grids (componentes/operaciones, derecha).
// Solo lectura.
// ============================================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxContainer, cxClasses,
  cxFilter, cxCustomData, cxData, cxDataStorage, cxNavigator,
  cxTL, cxTLData, cxInplaceContainer,
  dxScrollbarAnnotations, dxDateRanges,
  dxSkinsCore, dxSkinOffice2019Colorful, dxBarBuiltInMenu,
  uErpReader, uErpTypes, dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint,
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
  dxSkinXmas2008Blue, cxTLdxBarBuiltInMenu;

type
  TFormulaNodeKind = (fnkArticuloRoot, fnkComponentesGroup, fnkOperacionesGroup,
                      fnkComponenteMaterial, fnkComponenteSemielab,
                      fnkOperacion, fnkLoadingPlaceholder);

  TFormulaNodeInfo = class
  public
    Kind: TFormulaNodeKind;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    Version: SmallInt;          // versio de la formula (per articles)
    // Per operacions:
    Operacion: string;
    DescripcionOperacion: string;
    CentroTrabajo: string;
    TiempoTotal: Double;
    // Per semielab.:
    VersionFormulaComp: SmallInt;
    UnidadesNecesarias: Double;
    Loaded: Boolean; // ja s'ha fet l'expansio?
  end;

  TfrmFormulaArticuloViewer = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlMain: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    splitter: TSplitter;
    pnlLeftToolbar: TPanel;
    lblVersion: TLabel;
    cmbVersion: TComboBox;
    chkOnlyWithFormula: TCheckBox;
    tlFormula: TcxTreeList;
    colTLArticulo: TcxTreeListColumn;
    colTLTipo: TcxTreeListColumn;
    colTLUnidades: TcxTreeListColumn;
    colTLCentro: TcxTreeListColumn;
    pnlComponentes: TPanel;
    lblComponentes: TLabel;
    gridComponentes: TcxGrid;
    tvComponentes: TcxGridTableView;
    lvComponentes: TcxGridLevel;
    pnlOperaciones: TPanel;
    lblOperaciones: TLabel;
    splitterRight: TSplitter;
    gridOperaciones: TcxGrid;
    tvOperaciones: TcxGridTableView;
    lvOperaciones: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure tlFormulaExpanding(Sender: TcxCustomTreeList;
      ANode: TcxTreeListNode; var Allow: Boolean);
    procedure tlFormulaFocusedNodeChanged(Sender: TcxCustomTreeList;
      APrevFocusedNode, AFocusedNode: TcxTreeListNode);
    procedure chkOnlyWithFormulaClick(Sender: TObject);
    procedure cmbVersionChange(Sender: TObject);
  private
    FCodigoArticulo: string;
    FReader: IErpReader;
    FInfos: TObjectList<TFormulaNodeInfo>;
    FCurrentVersion: SmallInt;
    procedure LoadVersionsCombo;
    procedure RebuildTree;
    function MakeInfo: TFormulaNodeInfo;
    procedure LoadArticleNode(ANode: TcxTreeListNode);
    procedure ExpandSemielabNode(ANode: TcxTreeListNode);
    procedure SetNodeText(ANode: TcxTreeListNode; ACol: Integer; const S: string);
    procedure BuildComponentesColumns;
    procedure BuildOperacionesColumns;
    procedure ShowDetailFor(AInfo: TFormulaNodeInfo);
    procedure FillComponentesGrid(const ACodigoArticulo: string;
      AVersion: SmallInt);
    procedure FillOperacionesGrid(const ACodigoArticulo: string;
      AVersion: SmallInt);
    procedure ClearGridLineas(AView: TcxGridTableView);
  public
    class procedure Execute(const ACodigoArticulo: string);
  end;

implementation

{$R *.dfm}

uses
  uErpReaderFactory;

class procedure TfrmFormulaArticuloViewer.Execute(const ACodigoArticulo: string);
var
  Frm: TfrmFormulaArticuloViewer;
begin
  Frm := TfrmFormulaArticuloViewer.Create(nil);
  try
    Frm.FCodigoArticulo := ACodigoArticulo;
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TfrmFormulaArticuloViewer.btnCloseClick(Sender: TObject);
begin
  Close;
end;

function TfrmFormulaArticuloViewer.MakeInfo: TFormulaNodeInfo;
begin
  Result := TFormulaNodeInfo.Create;
  FInfos.Add(Result);
end;

procedure TfrmFormulaArticuloViewer.BuildComponentesColumns;
  procedure AddCol(const ACaption: string; AWidth: Integer);
  var
    Col: TcxGridColumn;
  begin
    Col := tvComponentes.CreateColumn;
    Col.Caption := ACaption;
    Col.Width := AWidth;
    Col.Options.Editing := False;
  end;
begin
  tvComponentes.ClearItems;
  AddCol('Orden',          50);
  AddCol('Art'#237'culo',   110);
  AddCol('Descripci'#243'n',280);
  AddCol('Unidades',       80);
  AddCol('UM',             50);
  AddCol('Mermas',         70);
  AddCol('Coste unit.',    90);
  AddCol('Coste comp.',    90);
  AddCol('Tipo',           70);
  AddCol('Operaci'#243'n',  100);
end;

procedure TfrmFormulaArticuloViewer.BuildOperacionesColumns;
  procedure AddCol(const ACaption: string; AWidth: Integer);
  var
    Col: TcxGridColumn;
  begin
    Col := tvOperaciones.CreateColumn;
    Col.Caption := ACaption;
    Col.Width := AWidth;
    Col.Options.Editing := False;
  end;
begin
  tvOperaciones.ClearItems;
  AddCol('Orden',           50);
  AddCol('Operaci'#243'n',  120);
  AddCol('Descripci'#243'n',280);
  AddCol('Centro',          90);
  AddCol('T. Preparaci'#243'n (min)', 130);
  AddCol('T. Fabricaci'#243'n (min)', 130);
  AddCol('T. Total (min)',  120);
  AddCol('Externa',          70);
end;

procedure TfrmFormulaArticuloViewer.ClearGridLineas(AView: TcxGridTableView);
begin
  AView.DataController.RecordCount := 0;
end;

procedure TfrmFormulaArticuloViewer.SetNodeText(ANode: TcxTreeListNode;
  ACol: Integer; const S: string);
begin
  ANode.Values[ACol] := S;
end;

procedure TfrmFormulaArticuloViewer.FormShow(Sender: TObject);
begin
  Caption := 'F'#243'rmula del art'#237'culo ' + FCodigoArticulo;
  lblTitle.Caption := 'Art'#237'culo: ' + FCodigoArticulo;

  FInfos := TObjectList<TFormulaNodeInfo>.Create(True);
  FCurrentVersion := 0;
  BuildComponentesColumns;
  BuildOperacionesColumns;

  FReader := GetActiveErpReader;
  if FReader = nil then
  begin
    ShowMessage('No hay ning'#250'n ERP activo configurado.');
    Exit;
  end;
  lblSubtitle.Caption := 'Visor de escandall - ERP: ' + FReader.GetSistemaNombre;

  LoadVersionsCombo;
  RebuildTree;
end;

procedure TfrmFormulaArticuloViewer.LoadVersionsCombo;
var
  Versiones: TArray<SmallInt>;
  I: Integer;
begin
  cmbVersion.Items.BeginUpdate;
  try
    cmbVersion.Items.Clear;
    try
      Versiones := FReader.ReadFormulaVersiones(FCodigoArticulo);
    except
      on E: Exception do
      begin
        ShowMessage('Error leyendo versiones: ' + E.Message);
        SetLength(Versiones, 0);
      end;
    end;
    for I := 0 to High(Versiones) do
      cmbVersion.Items.AddObject('Versi'#243'n ' + IntToStr(Versiones[I]),
        TObject(Integer(Versiones[I])));

    if cmbVersion.Items.Count > 0 then
    begin
      cmbVersion.ItemIndex := 0;
      FCurrentVersion := SmallInt(NativeInt(cmbVersion.Items.Objects[0]));
      cmbVersion.Enabled := cmbVersion.Items.Count > 1;
    end
    else
    begin
      FCurrentVersion := 0;
      cmbVersion.Enabled := False;
    end;
  finally
    cmbVersion.Items.EndUpdate;
  end;
end;

procedure TfrmFormulaArticuloViewer.cmbVersionChange(Sender: TObject);
begin
  if cmbVersion.ItemIndex < 0 then Exit;
  FCurrentVersion := SmallInt(NativeInt(
    cmbVersion.Items.Objects[cmbVersion.ItemIndex]));
  RebuildTree;
end;

procedure TfrmFormulaArticuloViewer.RebuildTree;
var
  RootInfo: TFormulaNodeInfo;
  RootNode: TcxTreeListNode;
begin
  if FReader = nil then Exit;
  if FCurrentVersion <= 0 then
  begin
    tlFormula.Clear;
    FInfos.Clear;
    ClearGridLineas(tvComponentes);
    ClearGridLineas(tvOperaciones);
    ShowMessage('No se ha encontrado f'#243'rmula para el art'#237'culo ' +
      FCodigoArticulo);
    Exit;
  end;

  tlFormula.BeginUpdate;
  try
    tlFormula.Clear;
    FInfos.Clear;
    ClearGridLineas(tvComponentes);
    ClearGridLineas(tvOperaciones);

    RootInfo := MakeInfo;
    RootInfo.Kind := fnkArticuloRoot;
    RootInfo.CodigoArticulo := FCodigoArticulo;
    RootInfo.Version := FCurrentVersion;

    RootNode := tlFormula.Add;
    RootNode.Data := RootInfo;
    SetNodeText(RootNode, 0, FCodigoArticulo);
    SetNodeText(RootNode, 1, 'Art'#237'culo');
    SetNodeText(RootNode, 2, '');
    SetNodeText(RootNode, 3, '');
    LoadArticleNode(RootNode);
    RootNode.Expand(False);
    RootNode.Focused := True;
  finally
    tlFormula.EndUpdate;
  end;
end;

procedure TfrmFormulaArticuloViewer.chkOnlyWithFormulaClick(Sender: TObject);
begin
  RebuildTree;
end;

procedure TfrmFormulaArticuloViewer.FormDestroy(Sender: TObject);
begin
  FInfos.Free;
  FReader := nil; // alliberar referencia
end;

procedure TfrmFormulaArticuloViewer.LoadArticleNode(ANode: TcxTreeListNode);
var
  Info, ChildInfo: TFormulaNodeInfo;
  GroupComp, GroupOper, Child, PH: TcxTreeListNode;
  Comps: TArray<TFormulaComponente>;
  Opers: TArray<TFormulaOperacion>;
  C: TFormulaComponente;
  O: TFormulaOperacion;
  I: Integer;
  ArtTxt: string;
begin
  if ANode = nil then Exit;
  Info := TFormulaNodeInfo(ANode.Data);
  if (Info = nil) or Info.Loaded then Exit;
  if FReader = nil then Exit;

  tlFormula.BeginUpdate;
  try
    // ----- Componentes -----
    ChildInfo := MakeInfo;
    ChildInfo.Kind := fnkComponentesGroup;
    GroupComp := ANode.AddChild;
    GroupComp.Data := ChildInfo;
    SetNodeText(GroupComp, 0, 'Componentes');
    SetNodeText(GroupComp, 1, '');
    SetNodeText(GroupComp, 2, '');
    SetNodeText(GroupComp, 3, '');

    try
      Comps := FReader.ReadFormulaComponentes(Info.CodigoArticulo, Info.Version);
    except
      on E: Exception do
      begin
        ShowMessage('Error leyendo componentes: ' + E.Message);
        SetLength(Comps, 0);
      end;
    end;

    for I := 0 to High(Comps) do
    begin
      C := Comps[I];

      // Filtre: si l'usuari nomes vol veure components AMB formula,
      // saltar els materials sense formula propia.
      if chkOnlyWithFormula.Checked and (not C.EsSemielaborado) then
        Continue;

      ChildInfo := MakeInfo;
      if C.EsSemielaborado then
        ChildInfo.Kind := fnkComponenteSemielab
      else
        ChildInfo.Kind := fnkComponenteMaterial;
      ChildInfo.CodigoArticulo      := C.CodigoArticuloComponente;
      ChildInfo.DescripcionArticulo := C.DescripcionArticulo;
      ChildInfo.VersionFormulaComp  := C.VersionFormulaComp;
      ChildInfo.UnidadesNecesarias  := C.UnidadesNecesarias;

      ArtTxt := Format('%s - %s',
        [ChildInfo.CodigoArticulo, ChildInfo.DescripcionArticulo]);
      Child := GroupComp.AddChild;
      Child.Data := ChildInfo;
      SetNodeText(Child, 0, ArtTxt);
      if ChildInfo.Kind = fnkComponenteSemielab then
        SetNodeText(Child, 1, 'Semielab.')
      else
        SetNodeText(Child, 1, 'Material');
      SetNodeText(Child, 2, FormatFloat('#,##0.##', ChildInfo.UnidadesNecesarias));
      SetNodeText(Child, 3, '');

      // Placeholder per lazy load del semielab
      if ChildInfo.Kind = fnkComponenteSemielab then
      begin
        ChildInfo := MakeInfo;
        ChildInfo.Kind := fnkLoadingPlaceholder;
        PH := Child.AddChild;
        PH.Data := ChildInfo;
        SetNodeText(PH, 0, '(expandir...)');
      end;
    end;

    // Si el grup Components ha quedat buit (per filtre), eliminar-lo
    if GroupComp.Count = 0 then
      GroupComp.Delete;

    // ----- Operaciones -----
    ChildInfo := MakeInfo;
    ChildInfo.Kind := fnkOperacionesGroup;
    GroupOper := ANode.AddChild;
    GroupOper.Data := ChildInfo;
    SetNodeText(GroupOper, 0, 'Operaciones');

    try
      Opers := FReader.ReadFormulaOperaciones(Info.CodigoArticulo, Info.Version);
    except
      on E: Exception do
      begin
        ShowMessage('Error leyendo operaciones: ' + E.Message);
        SetLength(Opers, 0);
      end;
    end;

    for I := 0 to High(Opers) do
    begin
      O := Opers[I];
      ChildInfo := MakeInfo;
      ChildInfo.Kind := fnkOperacion;
      ChildInfo.Operacion            := O.Operacion;
      ChildInfo.DescripcionOperacion := O.DescripcionOperacion;
      ChildInfo.CentroTrabajo        := O.CentroTrabajo;
      ChildInfo.TiempoTotal          := O.TiempoTotalMin;

      Child := GroupOper.AddChild;
      Child.Data := ChildInfo;
      SetNodeText(Child, 0, Format('%d. %s - %s',
        [O.Orden, O.Operacion, O.DescripcionOperacion]));
      SetNodeText(Child, 1, Format('%.1f min', [O.TiempoTotalMin]));
      SetNodeText(Child, 2, '');
      SetNodeText(Child, 3, O.CentroTrabajo);
    end;

    Info.Loaded := True;
  finally
    tlFormula.EndUpdate;
  end;
end;

procedure TfrmFormulaArticuloViewer.ExpandSemielabNode(ANode: TcxTreeListNode);
var
  Info, ArticuloInfo, PHInfo: TFormulaNodeInfo;
  PlaceholderNode, NewRoot: TcxTreeListNode;
begin
  if ANode = nil then Exit;
  Info := TFormulaNodeInfo(ANode.Data);
  if Info = nil then Exit;
  if Info.Kind <> fnkComponenteSemielab then Exit;
  if Info.Loaded then Exit;

  // Treure el placeholder
  if ANode.Count > 0 then
  begin
    PlaceholderNode := ANode.Items[0];
    PHInfo := TFormulaNodeInfo(PlaceholderNode.Data);
    if (PHInfo <> nil) and (PHInfo.Kind = fnkLoadingPlaceholder) then
      PlaceholderNode.Delete;
  end;

  // Crear sub-node article amb la formula del semielab i carregar-lo
  ArticuloInfo := MakeInfo;
  ArticuloInfo.Kind := fnkArticuloRoot;
  ArticuloInfo.CodigoArticulo := Info.CodigoArticulo;
  ArticuloInfo.Version := Info.VersionFormulaComp;

  NewRoot := ANode.AddChild;
  NewRoot.Data := ArticuloInfo;
  SetNodeText(NewRoot, 0, Format('F'#243'rmula %d de %s',
    [Info.VersionFormulaComp, Info.CodigoArticulo]));
  SetNodeText(NewRoot, 1, 'Art'#237'culo');

  LoadArticleNode(NewRoot);
  NewRoot.Expand(False);
  Info.Loaded := True;
end;

procedure TfrmFormulaArticuloViewer.tlFormulaExpanding(Sender: TcxCustomTreeList;
  ANode: TcxTreeListNode; var Allow: Boolean);
var
  Info: TFormulaNodeInfo;
begin
  Allow := True;
  if ANode = nil then Exit;
  Info := TFormulaNodeInfo(ANode.Data);
  if Info = nil then Exit;
  if (Info.Kind = fnkComponenteSemielab) and (not Info.Loaded) then
    ExpandSemielabNode(ANode);
end;

procedure TfrmFormulaArticuloViewer.tlFormulaFocusedNodeChanged(
  Sender: TcxCustomTreeList; APrevFocusedNode, AFocusedNode: TcxTreeListNode);
var
  Info: TFormulaNodeInfo;
begin
  if AFocusedNode = nil then Exit;
  Info := TFormulaNodeInfo(AFocusedNode.Data);
  if Info = nil then Exit;
  ShowDetailFor(Info);
end;

procedure TfrmFormulaArticuloViewer.FillComponentesGrid(
  const ACodigoArticulo: string; AVersion: SmallInt);
var
  Comps: TArray<TFormulaComponente>;
  C: TFormulaComponente;
  I: Integer;
begin
  ClearGridLineas(tvComponentes);
  if FReader = nil then Exit;
  try
    Comps := FReader.ReadFormulaComponentes(ACodigoArticulo, AVersion);
  except
    on E: Exception do
    begin
      ShowMessage('Error: ' + E.Message);
      Exit;
    end;
  end;

  tvComponentes.BeginUpdate;
  try
    for I := 0 to High(Comps) do
    begin
      C := Comps[I];
      tvComponentes.DataController.RecordCount := I + 1;
      tvComponentes.DataController.Values[I, 0] := C.Orden;
      tvComponentes.DataController.Values[I, 1] := C.CodigoArticuloComponente;
      tvComponentes.DataController.Values[I, 2] := C.DescripcionArticulo;
      tvComponentes.DataController.Values[I, 3] := C.UnidadesNecesarias;
      tvComponentes.DataController.Values[I, 4] := C.UnidadMedida;
      tvComponentes.DataController.Values[I, 5] := C.Mermas;
      tvComponentes.DataController.Values[I, 6] := C.CosteUnitario;
      tvComponentes.DataController.Values[I, 7] := C.CosteComponente;
      if C.EsSemielaborado then
        tvComponentes.DataController.Values[I, 8] := 'Semielab.'
      else
        tvComponentes.DataController.Values[I, 8] := 'Material';
      tvComponentes.DataController.Values[I, 9] := C.OperacionAsociada;
    end;
  finally
    tvComponentes.EndUpdate;
  end;
end;

procedure TfrmFormulaArticuloViewer.FillOperacionesGrid(
  const ACodigoArticulo: string; AVersion: SmallInt);
var
  Opers: TArray<TFormulaOperacion>;
  O: TFormulaOperacion;
  I: Integer;
begin
  ClearGridLineas(tvOperaciones);
  if FReader = nil then Exit;
  try
    Opers := FReader.ReadFormulaOperaciones(ACodigoArticulo, AVersion);
  except
    on E: Exception do
    begin
      ShowMessage('Error: ' + E.Message);
      Exit;
    end;
  end;

  tvOperaciones.BeginUpdate;
  try
    for I := 0 to High(Opers) do
    begin
      O := Opers[I];
      tvOperaciones.DataController.RecordCount := I + 1;
      tvOperaciones.DataController.Values[I, 0] := O.Orden;
      tvOperaciones.DataController.Values[I, 1] := O.Operacion;
      tvOperaciones.DataController.Values[I, 2] := O.DescripcionOperacion;
      tvOperaciones.DataController.Values[I, 3] := O.CentroTrabajo;
      tvOperaciones.DataController.Values[I, 4] := O.TiempoPreparacionMin;
      tvOperaciones.DataController.Values[I, 5] := O.TiempoFabricacionMin;
      tvOperaciones.DataController.Values[I, 6] := O.TiempoTotalMin;
      if O.EsExterna then
        tvOperaciones.DataController.Values[I, 7] := 'S'#237
      else
        tvOperaciones.DataController.Values[I, 7] := 'No';
    end;
  finally
    tvOperaciones.EndUpdate;
  end;
end;

procedure TfrmFormulaArticuloViewer.ShowDetailFor(AInfo: TFormulaNodeInfo);
begin
  if FReader = nil then Exit;
  case AInfo.Kind of
    fnkArticuloRoot:
      begin
        FillComponentesGrid(AInfo.CodigoArticulo, AInfo.Version);
        FillOperacionesGrid(AInfo.CodigoArticulo, AInfo.Version);
      end;
    fnkComponenteSemielab:
      begin
        FillComponentesGrid(AInfo.CodigoArticulo, AInfo.VersionFormulaComp);
        FillOperacionesGrid(AInfo.CodigoArticulo, AInfo.VersionFormulaComp);
      end;
  else
    ClearGridLineas(tvComponentes);
    ClearGridLineas(tvOperaciones);
  end;
end;

end.
