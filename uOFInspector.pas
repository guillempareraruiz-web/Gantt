unit uOFInspector;

// ============================================================================
// Inspector de OF — VerticalGrid amb la cabecera + 3 tabs:
//   - OTs filles de la OF (RelacionOTOF)
//   - Operaciones de l'OT seleccionada
//   - Consumos de l'OT seleccionada
//
// Read-only (consulta). Tot via IErpReader.
// Usage:
//   TfrmOFInspector.Execute(Reader, AEjercicio, ASerie, ANumero);
// ============================================================================

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.DateUtils,
  System.Variants,
  Winapi.Windows, Winapi.Messages,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Data.DB, Datasnap.DBClient,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, dxCore,
  cxGridLevel, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxClasses, cxGridCustomView, cxGrid, cxDBData,
  cxContainer, cxVGrid, cxInplaceContainer,
  cxTextEdit, cxSpinEdit, cxCheckBox, cxDropDownEdit, cxCalendar,
  cxDateUtils, cxMaskEdit, cxPC,
  uErpReader, uErpTypes;

type
  TfrmOFInspector = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblCodigoOF: TLabel;
    vg: TcxVerticalGrid;
    splitV: TSplitter;
    pcDetail: TcxPageControl;
    tabOTs: TcxTabSheet;
    grdOT: TcxGrid;
    grdOTView: TcxGridDBTableView;
    grdOTLevel: TcxGridLevel;
    tabOperaciones: TcxTabSheet;
    pnlOpTop: TPanel;
    lblOpInfo: TLabel;
    grdOp: TcxGrid;
    grdOpView: TcxGridDBTableView;
    grdOpLevel: TcxGridLevel;
    tabConsumos: TcxTabSheet;
    pnlConTop: TPanel;
    lblConInfo: TLabel;
    grdCon: TcxGrid;
    grdConView: TcxGridDBTableView;
    grdConLevel: TcxGridLevel;
    pnlBottom: TPanel;
    btnVerArticulo: TButton;
    btnCerrar: TButton;
    cdsOT: TClientDataSet;
    dsOT: TDataSource;
    cdsOp: TClientDataSet;
    dsOp: TDataSource;
    cdsCon: TClientDataSet;
    dsCon: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnVerArticuloClick(Sender: TObject);
    procedure pcDetailChange(Sender: TObject);
    procedure grdOTViewDblClick(Sender: TObject);
    procedure grdConViewDblClick(Sender: TObject);
  private
    FReader: IErpReader;
    FEjercicio: SmallInt;
    FSerie: string;
    FNumero: Integer;
    FOF: TOrdenFabricacionErp;
    FOTSeleccionada: Integer;       // EjercicioTrabajo*1000000 + NumeroTrabajo
    FOTEjActual: SmallInt;
    FOTNumActual: Integer;
    procedure CrearColumnas;
    procedure CargarCabecera;
    procedure CargarOTs;
    procedure CargarOperacionesOT(AEjTrabajo: SmallInt; ANumTrabajo: Integer);
    procedure CargarConsumosOT(AEjTrabajo: SmallInt; ANumTrabajo: Integer);
    function AddCat(const ACap: string): TcxCategoryRow;
    function AddTxt(AParent: TcxCategoryRow; const ACap, AVal: string): TcxEditorRow;
    function AddInt(AParent: TcxCategoryRow; const ACap: string; AVal: Integer): TcxEditorRow;
    function AddFlt(AParent: TcxCategoryRow; const ACap: string; AVal: Double): TcxEditorRow;
    function AddDate(AParent: TcxCategoryRow; const ACap: string; AVal: TDateTime): TcxEditorRow;
    function AddBool(AParent: TcxCategoryRow; const ACap: string; AVal: Boolean): TcxEditorRow;
  public
    class procedure Execute(const AReader: IErpReader;
      AEjercicio: SmallInt; const ASerie: string; ANumero: Integer);
  end;

implementation

{$R *.dfm}

uses
  uArticleDetail;

class procedure TfrmOFInspector.Execute(const AReader: IErpReader;
  AEjercicio: SmallInt; const ASerie: string; ANumero: Integer);
var
  Frm: TfrmOFInspector;
begin
  Frm := TfrmOFInspector.Create(nil);
  try
    Frm.FReader := AReader;
    Frm.FEjercicio := AEjercicio;
    Frm.FSerie := ASerie;
    Frm.FNumero := ANumero;
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TfrmOFInspector.FormCreate(Sender: TObject);
begin
  CrearColumnas;
  FOTSeleccionada := -1;
end;

procedure TfrmOFInspector.FormShow(Sender: TObject);
begin
  if FReader = nil then Exit;
  Screen.Cursor := crHourGlass;
  try
    CargarCabecera;
    CargarOTs;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmOFInspector.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmOFInspector.btnVerArticuloClick(Sender: TObject);
begin
  if (FReader = nil) or (Trim(FOF.CodigoArticulo) = '') then Exit;
  TfrmArticleDetail.Execute(FReader, FOF.CodigoArticulo);
end;

// ---------------------------------------------------------------------------
// VerticalGrid helpers (versio compacta del NodeInspector)
// ---------------------------------------------------------------------------

function TfrmOFInspector.AddCat(const ACap: string): TcxCategoryRow;
begin
  Result := vg.Add(TcxCategoryRow) as TcxCategoryRow;
  Result.Properties.Caption := ACap;
end;

function TfrmOFInspector.AddTxt(AParent: TcxCategoryRow;
  const ACap, AVal: string): TcxEditorRow;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACap;
  Result.Properties.EditPropertiesClassName := 'TcxTextEditProperties';
  (Result.Properties.EditProperties as TcxTextEditProperties).ReadOnly := True;
  Result.Properties.Value := AVal;
end;

function TfrmOFInspector.AddInt(AParent: TcxCategoryRow;
  const ACap: string; AVal: Integer): TcxEditorRow;
var
  P: TcxSpinEditProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACap;
  Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
  P := Result.Properties.EditProperties as TcxSpinEditProperties;
  P.ValueType := vtInt;
  P.MinValue := -MaxInt;
  P.MaxValue := MaxInt;
  P.ReadOnly := True;
  Result.Properties.Value := AVal;
end;

function TfrmOFInspector.AddFlt(AParent: TcxCategoryRow;
  const ACap: string; AVal: Double): TcxEditorRow;
var
  P: TcxSpinEditProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACap;
  Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
  P := Result.Properties.EditProperties as TcxSpinEditProperties;
  P.ValueType := vtFloat;
  P.MinValue := -1E18;
  P.MaxValue := 1E18;
  P.Increment := 0.1;
  P.ReadOnly := True;
  Result.Properties.Value := AVal;
end;

function TfrmOFInspector.AddDate(AParent: TcxCategoryRow;
  const ACap: string; AVal: TDateTime): TcxEditorRow;
var
  P: TcxDateEditProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACap;
  Result.Properties.EditPropertiesClassName := 'TcxDateEditProperties';
  P := Result.Properties.EditProperties as TcxDateEditProperties;
  P.ReadOnly := True;
  P.SaveTime := True;
  P.ShowTime := True;
  P.Kind := ckDateTime;
  if AVal > 0 then
    Result.Properties.Value := AVal
  else
    Result.Properties.Value := Null;
end;

function TfrmOFInspector.AddBool(AParent: TcxCategoryRow;
  const ACap: string; AVal: Boolean): TcxEditorRow;
var
  P: TcxCheckBoxProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACap;
  Result.Properties.EditPropertiesClassName := 'TcxCheckBoxProperties';
  P := Result.Properties.EditProperties as TcxCheckBoxProperties;
  P.DisplayChecked := 'S'#237;
  P.DisplayUnchecked := 'No';
  P.ReadOnly := True;
  Result.Properties.Value := AVal;
end;

// ---------------------------------------------------------------------------
// Carrega cabecera OF
// ---------------------------------------------------------------------------

procedure TfrmOFInspector.CargarCabecera;
var
  Lista: TArray<TOrdenFabricacionErp>;
  i: Integer;
  CatId, CatArt, CatFechas, CatProd, CatEstado, CatOtros: TcxCategoryRow;
  EstadoTxt: string;
begin
  // Buscar la OF concreta. ReadOrdenesFabricacion retorna llista per Ejercicio;
  // filtrem per Serie+Numero.
  try
    Lista := FReader.ReadOrdenesFabricacion(FEjercicio, FSerie, FNumero);
  except
    on E: Exception do
    begin
      ShowMessage('Error cargando OF: ' + E.Message);
      Exit;
    end;
  end;

  FOF := Default(TOrdenFabricacionErp);
  for i := 0 to High(Lista) do
    if (Lista[i].EjercicioFabricacion = FEjercicio) and
       SameText(Lista[i].SerieFabricacion, FSerie) and
       (Lista[i].NumeroFabricacion = FNumero) then
    begin
      FOF := Lista[i];
      Break;
    end;

  if FOF.NumeroFabricacion = 0 then
  begin
    lblCodigoOF.Caption := Format('OF %s/%d/%d -- NO ENCONTRADA',
      [FSerie, FEjercicio, FNumero]);
    Exit;
  end;

  lblCodigoOF.Caption := Format('OF %s/%d/%d  ·  %s -- %s',
    [FOF.SerieFabricacion, FOF.EjercicioFabricacion, FOF.NumeroFabricacion,
     FOF.CodigoArticulo, FOF.DescripcionArticulo]);

  case FOF.EstadoOF of
    0: EstadoTxt := 'Alta';
    1: EstadoTxt := 'Lanzada';
    2: EstadoTxt := 'En curso';
    3: EstadoTxt := 'Finalizada';
    4: EstadoTxt := 'Anulada';
  else
    EstadoTxt := IntToStr(FOF.EstadoOF);
  end;

  vg.BeginUpdate;
  try
    vg.ClearRows;

    CatId := AddCat('Identificaci'#243'n');
    AddInt(CatId,  'Ejercicio',     FOF.EjercicioFabricacion);
    AddTxt(CatId,  'Serie',         FOF.SerieFabricacion);
    AddInt(CatId,  'N'#250'mero',   FOF.NumeroFabricacion);
    AddInt(CatId,  'F'#243'rmula',  FOF.Formula);
    AddTxt(CatId,  'Proyecto',      FOF.CodigoProyecto);

    CatArt := AddCat('Art'#237'culo fabricado');
    AddTxt(CatArt, 'C'#243'digo',       FOF.CodigoArticulo);
    AddTxt(CatArt, 'Descripci'#243'n',  FOF.DescripcionArticulo);

    CatProd := AddCat('Producci'#243'n');
    AddFlt(CatProd, 'Unidades a fabricar', FOF.UnidadesAFabricar);
    AddFlt(CatProd, 'Unidades fabricadas', FOF.UnidadesFabricadas);
    if FOF.UnidadesAFabricar > 0 then
      AddFlt(CatProd, '% Progreso',
        FOF.UnidadesFabricadas / FOF.UnidadesAFabricar * 100)
    else
      AddFlt(CatProd, '% Progreso', 0);

    CatFechas := AddCat('Fechas');
    AddDate(CatFechas, 'Creaci'#243'n',        FOF.FechaCreacion);
    AddDate(CatFechas, 'Lanzamiento',         FOF.FechaLanzamiento);
    AddDate(CatFechas, 'Inicio previsto',     FOF.FechaInicioPrevista);
    AddDate(CatFechas, 'Final previsto',      FOF.FechaFinalPrevista);
    AddDate(CatFechas, 'Inicio real',         FOF.FechaInicioReal);
    AddDate(CatFechas, 'Final real',          FOF.FechaFinalReal);
    AddDate(CatFechas, 'Entrega',             FOF.FechaEntrega);

    CatEstado := AddCat('Estado');
    AddTxt(CatEstado,  'Estado',              EstadoTxt);
    AddInt(CatEstado,  'Estado (c'#243'digo)', FOF.EstadoOF);
    AddTxt(CatEstado,  'Prioridad',           FOF.Prioridad);
    AddBool(CatEstado, 'Bloqueo planif.',     FOF.BloqueoPlanificacion);

    CatOtros := AddCat('Otros');
    AddTxt(CatOtros, 'Tipo fabricaci'#243'n',  FOF.TipoFabricacion);
    AddTxt(CatOtros, 'Observaciones',          FOF.Observaciones);
  finally
    vg.EndUpdate;
  end;
end;

// ---------------------------------------------------------------------------
// Carrega columnes (un cop al FormCreate)
// ---------------------------------------------------------------------------

procedure TfrmOFInspector.CrearColumnas;
begin
  cdsOT.FieldDefs.Clear;
  cdsOT.FieldDefs.Add('NumTrabajo', ftInteger);
  cdsOT.FieldDefs.Add('Ejercicio', ftSmallint);
  cdsOT.FieldDefs.Add('Articulo', ftString, 30);
  cdsOT.FieldDefs.Add('Descripcion', ftString, 100);
  cdsOT.FieldDefs.Add('Nivel', ftInteger);
  cdsOT.FieldDefs.Add('UnidsAFab', ftFloat);
  cdsOT.FieldDefs.Add('FechaIni', ftDate);
  cdsOT.FieldDefs.Add('FechaFin', ftDate);
  cdsOT.FieldDefs.Add('Estado', ftInteger);
  cdsOT.CreateDataSet;

  cdsOp.FieldDefs.Clear;
  cdsOp.FieldDefs.Add('Orden', ftSmallint);
  cdsOp.FieldDefs.Add('Operacion', ftString, 30);
  cdsOp.FieldDefs.Add('Descripcion', ftString, 100);
  cdsOp.FieldDefs.Add('Centro', ftString, 20);
  cdsOp.FieldDefs.Add('TPrep', ftFloat);
  cdsOp.FieldDefs.Add('TFab', ftFloat);
  cdsOp.FieldDefs.Add('TTotal', ftFloat);
  cdsOp.FieldDefs.Add('UdsAFab', ftFloat);
  cdsOp.FieldDefs.Add('UdsFab', ftFloat);
  cdsOp.FieldDefs.Add('FechaIniPrev', ftDate);
  cdsOp.FieldDefs.Add('FechaFinPrev', ftDate);
  cdsOp.FieldDefs.Add('Estado', ftInteger);
  cdsOp.CreateDataSet;

  cdsCon.FieldDefs.Clear;
  cdsCon.FieldDefs.Add('Orden', ftSmallint);
  cdsCon.FieldDefs.Add('Articulo', ftString, 30);
  cdsCon.FieldDefs.Add('Descripcion', ftString, 100);
  cdsCon.FieldDefs.Add('Almacen', ftString, 20);
  cdsCon.FieldDefs.Add('Operacion', ftString, 30);
  cdsCon.FieldDefs.Add('UdsNec', ftFloat);
  cdsCon.FieldDefs.Add('UdsUsadas', ftFloat);
  cdsCon.FieldDefs.Add('Mermas', ftFloat);
  cdsCon.FieldDefs.Add('CosteComp', ftFloat);
  cdsCon.CreateDataSet;
end;

// ---------------------------------------------------------------------------
// Tab OTs
// ---------------------------------------------------------------------------

procedure TfrmOFInspector.CargarOTs;
var
  Rels: TArray<TRelacionOTOFErp>;
  OT: TOrdenTrabajoErp;
  i: Integer;
  Llista: TArray<TOrdenTrabajoErp>;
begin
  cdsOT.DisableControls;
  try
    cdsOT.EmptyDataSet;
    try
      Rels := FReader.ReadRelacionOTOF(FEjercicio, FSerie, FNumero);
    except
      on E: Exception do
      begin
        ShowMessage('Error cargando RelacionOTOF: ' + E.Message);
        Exit;
      end;
    end;
    for i := 0 to High(Rels) do
    begin
      // Resol cada OT individual via ReadOrdenesTrabajo (1 fila per OT)
      try
        Llista := FReader.ReadOrdenesTrabajo(Rels[i].EjercicioTrabajo,
          Rels[i].NumeroTrabajo);
      except
        Llista := nil;
      end;
      if Length(Llista) > 0 then
        OT := Llista[0]
      else
      begin
        OT := Default(TOrdenTrabajoErp);
        OT.EjercicioTrabajo := Rels[i].EjercicioTrabajo;
        OT.NumeroTrabajo := Rels[i].NumeroTrabajo;
      end;
      cdsOT.Append;
      cdsOT.FieldByName('NumTrabajo').AsInteger := OT.NumeroTrabajo;
      cdsOT.FieldByName('Ejercicio').AsInteger  := OT.EjercicioTrabajo;
      cdsOT.FieldByName('Articulo').AsString    := OT.CodigoArticulo;
      cdsOT.FieldByName('Descripcion').AsString := OT.DescripcionArticulo;
      cdsOT.FieldByName('Nivel').AsInteger      := OT.NivelCompuesto;
      cdsOT.FieldByName('UnidsAFab').AsFloat    := OT.UnidadesAFabricar;
      if OT.FechaInicioPrevista > 0 then
        cdsOT.FieldByName('FechaIni').AsDateTime := OT.FechaInicioPrevista;
      if OT.FechaFinalPrevista > 0 then
        cdsOT.FieldByName('FechaFin').AsDateTime := OT.FechaFinalPrevista;
      cdsOT.FieldByName('Estado').AsInteger     := OT.EstadoOT;
      cdsOT.Post;
    end;
    cdsOT.First;
  finally
    cdsOT.EnableControls;
  end;
  if grdOTView.ColumnCount = 0 then
    grdOTView.DataController.CreateAllItems;
  grdOTView.ApplyBestFit;
end;

// ---------------------------------------------------------------------------
// Tab Operaciones (de l'OT seleccionada)
// ---------------------------------------------------------------------------

procedure TfrmOFInspector.CargarOperacionesOT(AEjTrabajo: SmallInt;
  ANumTrabajo: Integer);
var
  Ops: TArray<TOperacionOTErp>;
  i: Integer;
begin
  cdsOp.DisableControls;
  try
    cdsOp.EmptyDataSet;
    if ANumTrabajo <= 0 then
    begin
      lblOpInfo.Caption := 'Selecciona una OT en la pesta'#241'a anterior para ver sus operaciones.';
      Exit;
    end;
    try
      Ops := FReader.ReadOperacionesOT(AEjTrabajo, ANumTrabajo);
    except
      on E: Exception do
      begin
        ShowMessage('Error cargando operaciones OT: ' + E.Message);
        Exit;
      end;
    end;
    lblOpInfo.Caption := Format('Operaciones de OT %d/%d (%d filas)',
      [AEjTrabajo, ANumTrabajo, Length(Ops)]);
    for i := 0 to High(Ops) do
    begin
      cdsOp.Append;
      cdsOp.FieldByName('Orden').AsInteger      := Ops[i].Orden;
      cdsOp.FieldByName('Operacion').AsString   := Ops[i].Operacion;
      cdsOp.FieldByName('Descripcion').AsString := Ops[i].DescripcionOperacion;
      cdsOp.FieldByName('Centro').AsString      := Ops[i].CentroTrabajo;
      cdsOp.FieldByName('TPrep').AsFloat        := Ops[i].TiempoPreparacion;
      cdsOp.FieldByName('TFab').AsFloat         := Ops[i].TiempoFabricacion;
      cdsOp.FieldByName('TTotal').AsFloat       := Ops[i].TiempoTotal;
      cdsOp.FieldByName('UdsAFab').AsFloat      := Ops[i].UnidadesAFabricar;
      cdsOp.FieldByName('UdsFab').AsFloat       := Ops[i].UnidadesFabricadas;
      if Ops[i].FechaInicioPrevista > 0 then
        cdsOp.FieldByName('FechaIniPrev').AsDateTime := Ops[i].FechaInicioPrevista;
      if Ops[i].FechaFinalPrevista > 0 then
        cdsOp.FieldByName('FechaFinPrev').AsDateTime := Ops[i].FechaFinalPrevista;
      cdsOp.FieldByName('Estado').AsInteger     := Ops[i].EstadoOperacion;
      cdsOp.Post;
    end;
    cdsOp.First;
  finally
    cdsOp.EnableControls;
  end;
  if grdOpView.ColumnCount = 0 then
    grdOpView.DataController.CreateAllItems;
  grdOpView.ApplyBestFit;
end;

// ---------------------------------------------------------------------------
// Tab Consumos (de l'OT seleccionada)
// ---------------------------------------------------------------------------

procedure TfrmOFInspector.CargarConsumosOT(AEjTrabajo: SmallInt;
  ANumTrabajo: Integer);
var
  Cons: TArray<TConsumoOTErp>;
  i: Integer;
begin
  cdsCon.DisableControls;
  try
    cdsCon.EmptyDataSet;
    if ANumTrabajo <= 0 then
    begin
      lblConInfo.Caption := 'Selecciona una OT en la pesta'#241'a anterior para ver sus consumos.';
      Exit;
    end;
    try
      Cons := FReader.ReadConsumosOT(AEjTrabajo, ANumTrabajo);
    except
      on E: Exception do
      begin
        ShowMessage('Error cargando consumos OT: ' + E.Message);
        Exit;
      end;
    end;
    lblConInfo.Caption := Format('Consumos de OT %d/%d (%d filas) -- doble-clic abre la ficha del art'#237'culo',
      [AEjTrabajo, ANumTrabajo, Length(Cons)]);
    for i := 0 to High(Cons) do
    begin
      cdsCon.Append;
      cdsCon.FieldByName('Orden').AsInteger      := Cons[i].Orden;
      cdsCon.FieldByName('Articulo').AsString    := Cons[i].ArticuloComponente;
      cdsCon.FieldByName('Descripcion').AsString := Cons[i].DescripcionArticulo;
      cdsCon.FieldByName('Almacen').AsString     := Cons[i].CodigoAlmacen;
      cdsCon.FieldByName('Operacion').AsString   := Cons[i].Operacion;
      cdsCon.FieldByName('UdsNec').AsFloat       := Cons[i].UnidadesNecesarias;
      cdsCon.FieldByName('UdsUsadas').AsFloat    := Cons[i].UnidadesUsadas;
      cdsCon.FieldByName('Mermas').AsFloat       := Cons[i].Mermas;
      cdsCon.FieldByName('CosteComp').AsFloat    := Cons[i].CosteComponente;
      cdsCon.Post;
    end;
    cdsCon.First;
  finally
    cdsCon.EnableControls;
  end;
  if grdConView.ColumnCount = 0 then
    grdConView.DataController.CreateAllItems;
  grdConView.ApplyBestFit;
end;

// ---------------------------------------------------------------------------
// Selector OT: al fer doble-clic a una OT, ompla els tabs operaciones+consums
// i salta al tab Operaciones.
// ---------------------------------------------------------------------------

procedure TfrmOFInspector.grdOTViewDblClick(Sender: TObject);
begin
  if not cdsOT.Active or cdsOT.IsEmpty then Exit;
  FOTEjActual := cdsOT.FieldByName('Ejercicio').AsInteger;
  FOTNumActual := cdsOT.FieldByName('NumTrabajo').AsInteger;
  Screen.Cursor := crHourGlass;
  try
    CargarOperacionesOT(FOTEjActual, FOTNumActual);
    CargarConsumosOT(FOTEjActual, FOTNumActual);
  finally
    Screen.Cursor := crDefault;
  end;
  pcDetail.ActivePage := tabOperaciones;
end;

procedure TfrmOFInspector.pcDetailChange(Sender: TObject);
begin
  // Si l'usuari va manualment al tab Operaciones o Consumos sense haver
  // seleccionat OT, mostra missatge informatiu.
  if (pcDetail.ActivePage = tabOperaciones) and (cdsOp.IsEmpty) and
     (FOTNumActual = 0) then
    lblOpInfo.Caption := 'Selecciona una OT en la pesta'#241'a anterior para ver sus operaciones.';
  if (pcDetail.ActivePage = tabConsumos) and (cdsCon.IsEmpty) and
     (FOTNumActual = 0) then
    lblConInfo.Caption := 'Selecciona una OT en la pesta'#241'a anterior para ver sus consumos.';
end;

procedure TfrmOFInspector.grdConViewDblClick(Sender: TObject);
begin
  if not cdsCon.Active or cdsCon.IsEmpty then Exit;
  if Trim(cdsCon.FieldByName('Articulo').AsString) = '' then Exit;
  TfrmArticleDetail.Execute(FReader, cdsCon.FieldByName('Articulo').AsString);
end;

end.
