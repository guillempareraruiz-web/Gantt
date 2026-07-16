unit uUtillajeFicha;

// Ficha de detalle de un utillaje (V072/V073).
//
// Se abre desde el listado uGestionUtillajes. Pestanyas:
//   - Datos generales : identificacion, ubicacion, estado, capacidad
//   - Vida util       : contador, vida total, proximo mantenimiento, tiempos
//   - Relaciones      : centros donde puede montarse / articulos / operaciones
//
// Los datos se cargan en FormShow (no en FormCreate): Execute asigna
// FUtillajeId entre Create y ShowModal.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxSpinEdit, cxContainer, cxClasses, cxFilter, cxDropDownEdit,
  cxCalendar, cxMaskEdit, cxButtonEdit, cxLabel, cxProgressBar,
  cxPC, dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB,
  uUtillajeTypes, uUtillajesRepo, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
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
  dxSkinXmas2008Blue, dxCore, cxDateUtils;

type
  TfrmUtillajeFicha = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    pc: TcxPageControl;
    tsDatos: TcxTabSheet;
    tsVida: TcxTabSheet;
    tsRelaciones: TcxTabSheet;

    // --- Datos generales ---
    lblCodigo: TLabel;
    edCodigo: TcxTextEdit;
    lblDescripcion: TLabel;
    edDescripcion: TcxTextEdit;
    lblTipo: TLabel;
    edTipo: TcxTextEdit;
    lblFabricante: TLabel;
    edFabricante: TcxTextEdit;
    lblNumeroSerie: TLabel;
    edNumeroSerie: TcxTextEdit;
    lblAnyo: TLabel;
    edAnyo: TcxSpinEdit;
    lblUbicacion: TLabel;
    edUbicacion: TcxTextEdit;
    lblCentroActual: TLabel;
    cbCentroActual: TcxComboBox;
    lblEstado: TLabel;
    cbEstado: TcxComboBox;
    lblCantidad: TLabel;
    edCantidad: TcxSpinEdit;
    lblCantidadHint: TLabel;
    chkDisponible: TcxCheckBox;
    chkDisponiblePlan: TcxCheckBox;
    chkActivo: TcxCheckBox;
    lblOrden: TLabel;
    edOrden: TcxSpinEdit;
    lblObservaciones: TLabel;
    memObservaciones: TMemo;

    // --- Vida util ---
    lblUnidadVida: TLabel;
    cbUnidadVida: TcxComboBox;
    lblContador: TLabel;
    edContador: TcxSpinEdit;
    lblVidaTotal: TLabel;
    edVidaTotal: TcxSpinEdit;
    lblVidaHint: TLabel;
    lblConsumo: TLabel;
    pbVida: TcxProgressBar;
    lblProxMant: TLabel;
    dtProxMant: TcxDateEdit;
    chkSinMant: TcxCheckBox;
    lblTiempos: TLabel;
    lblTMontaje: TLabel;
    edTMontaje: TcxSpinEdit;
    lblTDesmontaje: TLabel;
    edTDesmontaje: TcxSpinEdit;
    lblTAjuste: TLabel;
    edTAjuste: TcxSpinEdit;

    // --- Relaciones ---
    lblCentros: TLabel;
    gridCentros: TcxGrid;
    tvCentros: TcxGridTableView;
    colCenId: TcxGridColumn;
    colCenAsig: TcxGridColumn;
    colCenNombre: TcxGridColumn;
    colCenPref: TcxGridColumn;
    colCenTiempo: TcxGridColumn;
    lvCentros: TcxGridLevel;

    lblOperaciones: TLabel;
    gridOper: TcxGrid;
    tvOper: TcxGridTableView;
    colOpCodigo: TcxGridColumn;
    colOpObl: TcxGridColumn;
    colOpObs: TcxGridColumn;
    lvOper: TcxGridLevel;
    btnOpAdd: TButton;
    btnOpDel: TButton;

    lblArticulos: TLabel;
    gridArt: TcxGrid;
    tvArt: TcxGridTableView;
    colArtCodigo: TcxGridColumn;
    colArtObl: TcxGridColumn;
    colArtObs: TcxGridColumn;
    lvArt: TcxGridLevel;
    btnArtAdd: TButton;
    btnArtDel: TButton;

    LookAndFeel: TcxLookAndFeelController;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure chkSinMantClick(Sender: TObject);
    procedure edContadorChange(Sender: TObject);
    procedure edVidaTotalChange(Sender: TObject);
    procedure btnOpAddClick(Sender: TObject);
    procedure btnOpDelClick(Sender: TObject);
    procedure btnArtAddClick(Sender: TObject);
    procedure btnArtDelClick(Sender: TObject);
    procedure colArtCodigoButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure colOpCodigoButtonClick(Sender: TObject; AButtonIndex: Integer);
  private
    FRepo: TUtillajesRepo;
    FUtillajeId: Integer;
    FUtil: TUtillaje;
    FCenterIds: TArray<Integer>;
    FCenterNames: TArray<string>;
    procedure LoadCenters;
    procedure SetupCombos;
    procedure LoadFicha;
    procedure LoadRelaciones;
    function CollectFicha(out U: TUtillaje): Boolean;
    procedure SaveRelaciones(AUtillajeId: Integer);
    procedure UpdateVidaUI;
    function CenterIndexFromId(ACenterId: Integer): Integer;
    procedure GridAddRow(AView: TcxGridTableView; AColCodigo, AColObl: TcxGridColumn);
    procedure GridDelRow(AView: TcxGridTableView);
  public
    // AUtillajeId = 0 -> alta. Devuelve True si se guardo.
    class function Execute(AUtillajeId: Integer): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uHelpViewer, uArticuloPicker, uOperacionPicker,
  uErpReader, uErpReaderFactory;

class function TfrmUtillajeFicha.Execute(AUtillajeId: Integer): Boolean;
var
  F: TfrmUtillajeFicha;
begin
  F := TfrmUtillajeFicha.Create(nil);
  try
    F.FUtillajeId := AUtillajeId;
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmUtillajeFicha.FormCreate(Sender: TObject);
begin
  FRepo := TUtillajesRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  THelpViewer.InstallHelp(Self, 'uUtillajeFicha', 'Ficha de utillaje');
end;

procedure TfrmUtillajeFicha.FormDestroy(Sender: TObject);
begin
  FRepo.Free;
end;

procedure TfrmUtillajeFicha.FormShow(Sender: TObject);
begin
  LoadCenters;
  SetupCombos;
  LoadFicha;
  LoadRelaciones;
  pc.ActivePage := tsDatos;
end;

procedure TfrmUtillajeFicha.LoadCenters;
var
  Q: TADOQuery;
  L: TList<Integer>;
  N: TList<string>;
begin
  L := TList<Integer>.Create;
  N := TList<string>.Create;
  try
    // Primera entrada = "(ninguno)" para poder dejar el centro sin asignar.
    L.Add(0);
    N.Add('(ninguno)');

    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT CenterId, Titulo FROM FS_PL_Center ' +
        'WHERE CodigoEmpresa = :CE AND Visible = 1 ORDER BY Orden, Titulo';
      Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        L.Add(Q.FieldByName('CenterId').AsInteger);
        N.Add(Q.FieldByName('Titulo').AsString);
        Q.Next;
      end;
    finally
      Q.Free;
    end;

    FCenterIds := L.ToArray;
    FCenterNames := N.ToArray;
  finally
    L.Free;
    N.Free;
  end;
end;

procedure TfrmUtillajeFicha.SetupCombos;
var
  E: TEstadoUtillaje;
  V: TUnidadVida;
  I: Integer;
begin
  cbEstado.Properties.Items.Clear;
  for E := Low(TEstadoUtillaje) to High(TEstadoUtillaje) do
    cbEstado.Properties.Items.Add(EstadoUtillajeToStr(E));

  cbUnidadVida.Properties.Items.Clear;
  for V := Low(TUnidadVida) to High(TUnidadVida) do
    cbUnidadVida.Properties.Items.Add(UnidadVidaToStr(V));

  cbCentroActual.Properties.Items.Clear;
  for I := 0 to High(FCenterNames) do
    cbCentroActual.Properties.Items.Add(FCenterNames[I]);
end;

function TfrmUtillajeFicha.CenterIndexFromId(ACenterId: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FCenterIds) do
    if FCenterIds[I] = ACenterId then
      Exit(I);
  Result := 0;   // (ninguno)
end;

procedure TfrmUtillajeFicha.LoadFicha;
begin
  if FUtillajeId > 0 then
  begin
    if not FRepo.GetById(FUtillajeId, FUtil) then
    begin
      ShowMessage('El utillaje ya no existe.');
      ModalResult := mrCancel;
      Exit;
    end;
    lblTitle.Caption := 'Utillaje ' + FUtil.Codigo;
    lblSubtitle.Caption := FUtil.Descripcion;
  end
  else
  begin
    FUtil := Default(TUtillaje);
    // Valores de alta coherentes con los DEFAULT de la tabla.
    FUtil.Cantidad := 1;
    FUtil.Activo := True;
    FUtil.Disponible := True;
    FUtil.DisponiblePlanificacion := True;
    FUtil.Estado := euDisponible;
    FUtil.UnidadVida := uvCiclos;
    FUtil.FechaProxMantNull := True;
    lblTitle.Caption := 'Nuevo utillaje';
    lblSubtitle.Caption := 'Alta en el cat'#225'logo';
  end;

  edCodigo.Text := FUtil.Codigo;
  edDescripcion.Text := FUtil.Descripcion;
  edTipo.Text := FUtil.Tipo;
  edFabricante.Text := FUtil.Fabricante;
  edNumeroSerie.Text := FUtil.NumeroSerie;
  edAnyo.Value := FUtil.AnyoFabricacion;
  edUbicacion.Text := FUtil.Ubicacion;
  cbCentroActual.ItemIndex := CenterIndexFromId(FUtil.CentroActualId);
  cbEstado.ItemIndex := Ord(FUtil.Estado);
  edCantidad.Value := FUtil.Cantidad;
  chkDisponible.Checked := FUtil.Disponible;
  chkDisponiblePlan.Checked := FUtil.DisponiblePlanificacion;
  chkActivo.Checked := FUtil.Activo;
  edOrden.Value := FUtil.Orden;
  memObservaciones.Lines.Text := FUtil.Observaciones;

  cbUnidadVida.ItemIndex := Ord(FUtil.UnidadVida);
  edContador.Value := FUtil.ContadorActual;
  edVidaTotal.Value := FUtil.VidaUtilTotal;
  chkSinMant.Checked := FUtil.FechaProxMantNull;
  if FUtil.FechaProxMantNull then
    dtProxMant.Clear
  else
    dtProxMant.Date := FUtil.FechaProxMantenimiento;
  dtProxMant.Enabled := not chkSinMant.Checked;

  edTMontaje.Value := FUtil.TiempoMontaje;
  edTDesmontaje.Value := FUtil.TiempoDesmontaje;
  edTAjuste.Value := FUtil.TiempoAjuste;

  UpdateVidaUI;
end;

procedure TfrmUtillajeFicha.UpdateVidaUI;
var
  Total, Actual, Pct: Double;
  U: TUtillaje;
begin
  Total := edVidaTotal.Value;
  Actual := edContador.Value;

  if Total <= 0 then
  begin
    pbVida.Position := 0;
    lblConsumo.Caption := 'Sin control de vida '#250'til';
    lblConsumo.Font.Color := clGrayText;
    Exit;
  end;

  U := Default(TUtillaje);
  U.ContadorActual := Round(Actual);
  U.VidaUtilTotal := Round(Total);
  Pct := PorcentajeVidaConsumida(U);

  pbVida.Position := Min(100, Round(Pct));
  lblConsumo.Caption := Format('%.0f%% consumido (%.0f de %.0f %s)',
    [Pct, Actual, Total, LowerCase(UnidadVidaToStr(TUnidadVida(Max(0, cbUnidadVida.ItemIndex))))]);

  if Pct >= 100 then
    lblConsumo.Font.Color := clRed
  else if Pct >= 80 then
    lblConsumo.Font.Color := $000080FF   // naranja
  else
    lblConsumo.Font.Color := clWindowText;
end;

procedure TfrmUtillajeFicha.edContadorChange(Sender: TObject);
begin
  UpdateVidaUI;
end;

procedure TfrmUtillajeFicha.edVidaTotalChange(Sender: TObject);
begin
  UpdateVidaUI;
end;

procedure TfrmUtillajeFicha.chkSinMantClick(Sender: TObject);
begin
  dtProxMant.Enabled := not chkSinMant.Checked;
  if chkSinMant.Checked then dtProxMant.Clear;
end;

procedure TfrmUtillajeFicha.LoadRelaciones;
var
  Centros: TArray<TUtillajeCentro>;
  Arts: TArray<TUtillajeArticulo>;
  Ops: TArray<TUtillajeOperacion>;
  I, J: Integer;
  Asignado: Boolean;
  Pref: Boolean;
  Tiempo: Double;
begin
  // --- Centros: se listan TODOS, con checkbox de asignacion ---
  if FUtillajeId > 0 then
    Centros := FRepo.GetCentros(FUtillajeId)
  else
    SetLength(Centros, 0);

  tvCentros.BeginUpdate;
  try
    tvCentros.DataController.RecordCount := 0;
    // Se salta el indice 0 = "(ninguno)".
    tvCentros.DataController.RecordCount := Max(0, Length(FCenterIds) - 1);
    for I := 1 to High(FCenterIds) do
    begin
      Asignado := False;
      Pref := False;
      Tiempo := 0;
      for J := 0 to High(Centros) do
        if Centros[J].CenterId = FCenterIds[I] then
        begin
          Asignado := True;
          Pref := Centros[J].Preferente;
          Tiempo := Centros[J].TiempoMontajeEspecifico;
          Break;
        end;

      // El CenterId viaja en una columna oculta: al guardar no se puede mapear
      // por posicion (si el usuario ordena, el indice de fila deja de coincidir
      // con el de registro y se asignaria el centro equivocado).
      tvCentros.DataController.Values[I - 1, colCenId.Index]     := FCenterIds[I];
      tvCentros.DataController.Values[I - 1, colCenAsig.Index]   := Asignado;
      tvCentros.DataController.Values[I - 1, colCenNombre.Index] := FCenterNames[I];
      tvCentros.DataController.Values[I - 1, colCenPref.Index]   := Pref;
      tvCentros.DataController.Values[I - 1, colCenTiempo.Index] := Tiempo;
    end;
  finally
    tvCentros.EndUpdate;
  end;

  // --- Operaciones ---
  if FUtillajeId > 0 then
    Ops := FRepo.GetOperaciones(FUtillajeId)
  else
    SetLength(Ops, 0);

  tvOper.BeginUpdate;
  try
    tvOper.DataController.RecordCount := 0;
    tvOper.DataController.RecordCount := Length(Ops);
    for I := 0 to High(Ops) do
    begin
      tvOper.DataController.Values[I, colOpCodigo.Index] := Ops[I].Operacion;
      tvOper.DataController.Values[I, colOpObl.Index]    := Ops[I].Obligatorio;
      tvOper.DataController.Values[I, colOpObs.Index]    := Ops[I].Observaciones;
    end;
  finally
    tvOper.EndUpdate;
  end;

  // --- Articulos ---
  if FUtillajeId > 0 then
    Arts := FRepo.GetArticulos(FUtillajeId)
  else
    SetLength(Arts, 0);

  tvArt.BeginUpdate;
  try
    tvArt.DataController.RecordCount := 0;
    tvArt.DataController.RecordCount := Length(Arts);
    for I := 0 to High(Arts) do
    begin
      tvArt.DataController.Values[I, colArtCodigo.Index] := Arts[I].CodigoArticulo;
      tvArt.DataController.Values[I, colArtObl.Index]    := Arts[I].Obligatorio;
      tvArt.DataController.Values[I, colArtObs.Index]    := Arts[I].Observaciones;
    end;
  finally
    tvArt.EndUpdate;
  end;
end;

function TfrmUtillajeFicha.CollectFicha(out U: TUtillaje): Boolean;
begin
  Result := False;
  U := FUtil;   // conserva Id

  U.Codigo := Trim(edCodigo.Text);
  if U.Codigo = '' then
  begin
    ShowMessage('El c'#243'digo es obligatorio.');
    pc.ActivePage := tsDatos;
    edCodigo.SetFocus;
    Exit;
  end;

  if FRepo.CodigoExists(U.Codigo, FUtillajeId) then
  begin
    ShowMessage('Ya existe otro utillaje con el c'#243'digo ' + U.Codigo + '.');
    pc.ActivePage := tsDatos;
    edCodigo.SetFocus;
    Exit;
  end;

  U.Descripcion := Trim(edDescripcion.Text);
  U.Tipo := Trim(edTipo.Text);
  U.Fabricante := Trim(edFabricante.Text);
  U.NumeroSerie := Trim(edNumeroSerie.Text);
  U.AnyoFabricacion := edAnyo.Value;
  U.Ubicacion := Trim(edUbicacion.Text);

  if (cbCentroActual.ItemIndex >= 0) and (cbCentroActual.ItemIndex <= High(FCenterIds)) then
    U.CentroActualId := FCenterIds[cbCentroActual.ItemIndex]
  else
    U.CentroActualId := 0;

  U.Estado := TEstadoUtillaje(Max(0, cbEstado.ItemIndex));

  U.Cantidad := edCantidad.Value;
  if U.Cantidad < 1 then U.Cantidad := 1;

  U.Disponible := chkDisponible.Checked;
  U.DisponiblePlanificacion := chkDisponiblePlan.Checked;
  U.Activo := chkActivo.Checked;
  U.Orden := edOrden.Value;
  U.Observaciones := Trim(memObservaciones.Lines.Text);

  U.UnidadVida := TUnidadVida(Max(0, cbUnidadVida.ItemIndex));
  U.ContadorActual := Round(edContador.Value);
  U.VidaUtilTotal := Round(edVidaTotal.Value);

  // VarIsNull, no "= Null": comparar un Variant con Null devuelve Null (no
  // False) y revienta al evaluarlo como Boolean.
  U.FechaProxMantNull := chkSinMant.Checked or VarIsNull(dtProxMant.EditValue);
  if U.FechaProxMantNull then
    U.FechaProxMantenimiento := 0
  else
    U.FechaProxMantenimiento := dtProxMant.Date;

  U.TiempoMontaje := edTMontaje.Value;
  U.TiempoDesmontaje := edTDesmontaje.Value;
  U.TiempoAjuste := edTAjuste.Value;

  Result := True;
end;

procedure TfrmUtillajeFicha.SaveRelaciones(AUtillajeId: Integer);
var
  Centros: TArray<TUtillajeCentro>;
  Arts: TArray<TUtillajeArticulo>;
  Ops: TArray<TUtillajeOperacion>;
  I: Integer;
  V: Variant;

  function AsBoolDef(AV: Variant; ADef: Boolean): Boolean;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADef else Result := Boolean(AV);
  end;
  function AsStrDef(AV: Variant): string;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := '' else Result := VarToStr(AV);
  end;
  function AsFloatDef(AV: Variant): Double;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := 0 else Result := Double(AV);
  end;

begin
  // --- Centros: solo los marcados ---
  SetLength(Centros, 0);
  for I := 0 to tvCentros.DataController.RecordCount - 1 do
  begin
    V := tvCentros.DataController.Values[I, colCenAsig.Index];
    if not AsBoolDef(V, False) then Continue;

    // El CenterId se lee de su columna, no de FCenterIds por posicion.
    V := tvCentros.DataController.Values[I, colCenId.Index];
    if VarIsNull(V) or VarIsEmpty(V) then Continue;

    SetLength(Centros, Length(Centros) + 1);
    Centros[High(Centros)].UtillajeId := AUtillajeId;
    Centros[High(Centros)].CenterId := V;
    Centros[High(Centros)].Preferente :=
      AsBoolDef(tvCentros.DataController.Values[I, colCenPref.Index], False);
    Centros[High(Centros)].TiempoMontajeEspecifico :=
      AsFloatDef(tvCentros.DataController.Values[I, colCenTiempo.Index]);
  end;
  FRepo.SaveCentros(AUtillajeId, Centros);

  // --- Operaciones ---
  SetLength(Ops, 0);
  for I := 0 to tvOper.DataController.RecordCount - 1 do
  begin
    if Trim(AsStrDef(tvOper.DataController.Values[I, colOpCodigo.Index])) = '' then
      Continue;
    SetLength(Ops, Length(Ops) + 1);
    Ops[High(Ops)].UtillajeId := AUtillajeId;
    Ops[High(Ops)].Operacion :=
      Trim(AsStrDef(tvOper.DataController.Values[I, colOpCodigo.Index]));
    Ops[High(Ops)].Obligatorio :=
      AsBoolDef(tvOper.DataController.Values[I, colOpObl.Index], True);
    Ops[High(Ops)].Observaciones :=
      AsStrDef(tvOper.DataController.Values[I, colOpObs.Index]);
  end;
  FRepo.SaveOperaciones(AUtillajeId, Ops);

  // --- Articulos ---
  SetLength(Arts, 0);
  for I := 0 to tvArt.DataController.RecordCount - 1 do
  begin
    if Trim(AsStrDef(tvArt.DataController.Values[I, colArtCodigo.Index])) = '' then
      Continue;
    SetLength(Arts, Length(Arts) + 1);
    Arts[High(Arts)].UtillajeId := AUtillajeId;
    Arts[High(Arts)].CodigoArticulo :=
      Trim(AsStrDef(tvArt.DataController.Values[I, colArtCodigo.Index]));
    Arts[High(Arts)].Obligatorio :=
      AsBoolDef(tvArt.DataController.Values[I, colArtObl.Index], True);
    Arts[High(Arts)].Observaciones :=
      AsStrDef(tvArt.DataController.Values[I, colArtObs.Index]);
  end;
  FRepo.SaveArticulos(AUtillajeId, Arts);
end;

procedure TfrmUtillajeFicha.btnOKClick(Sender: TObject);
var
  U: TUtillaje;
  NewId: Integer;
begin
  // Cerrar cualquier edicion en curso en los grids antes de leer valores.
  if tvCentros.Controller.EditingController.IsEditing then
    tvCentros.Controller.EditingController.HideEdit(True);
  if tvOper.Controller.EditingController.IsEditing then
    tvOper.Controller.EditingController.HideEdit(True);
  if tvArt.Controller.EditingController.IsEditing then
    tvArt.Controller.EditingController.HideEdit(True);
  tvCentros.DataController.Post(False);
  tvOper.DataController.Post(False);
  tvArt.DataController.Post(False);

  if not CollectFicha(U) then Exit;

  if FUtillajeId <= 0 then
  begin
    NewId := FRepo.Insert(U);
    if NewId <= 0 then
    begin
      ShowMessage('No se ha podido crear el utillaje.');
      Exit;
    end;
    FUtillajeId := NewId;
  end
  else
    FRepo.Update(U);

  SaveRelaciones(FUtillajeId);
  ModalResult := mrOk;
end;

procedure TfrmUtillajeFicha.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

// --- Grids de operaciones / articulos -------------------------------------

procedure TfrmUtillajeFicha.GridAddRow(AView: TcxGridTableView;
  AColCodigo, AColObl: TcxGridColumn);
var
  Cnt: Integer;
begin
  Cnt := AView.DataController.RecordCount;
  AView.DataController.RecordCount := Cnt + 1;
  AView.DataController.Values[Cnt, AColCodigo.Index] := '';
  AView.DataController.Values[Cnt, AColObl.Index] := True;
  AView.Controller.FocusedRecordIndex := Cnt;
end;

procedure TfrmUtillajeFicha.GridDelRow(AView: TcxGridTableView);
var
  Idx: Integer;
begin
  // Estos grids llevan ColumnSorting = False, asi que el indice de fila y el
  // de registro coinciden y FocusedRecordIndex es seguro aqui.
  Idx := AView.Controller.FocusedRecordIndex;
  if Idx < 0 then Exit;
  AView.DataController.DeleteRecord(Idx);
end;

procedure TfrmUtillajeFicha.btnOpAddClick(Sender: TObject);
begin
  GridAddRow(tvOper, colOpCodigo, colOpObl);
end;

procedure TfrmUtillajeFicha.btnOpDelClick(Sender: TObject);
begin
  GridDelRow(tvOper);
end;

procedure TfrmUtillajeFicha.btnArtAddClick(Sender: TObject);
begin
  GridAddRow(tvArt, colArtCodigo, colArtObl);
end;

procedure TfrmUtillajeFicha.btnArtDelClick(Sender: TObject);
begin
  GridDelRow(tvArt);
end;

procedure TfrmUtillajeFicha.colOpCodigoButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  Cod, Desc: string;
  Idx: Integer;
begin
  Idx := tvOper.Controller.FocusedRecordIndex;
  if Idx < 0 then Exit;
  if TfrmOperacionPicker.Execute(Cod, Desc) then
    tvOper.DataController.Values[Idx, colOpCodigo.Index] := Cod;
end;

procedure TfrmUtillajeFicha.colArtCodigoButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  Cod, Desc: string;
  Idx: Integer;
  Reader: IErpReader;
begin
  Idx := tvArt.Controller.FocusedRecordIndex;
  if Idx < 0 then Exit;

  Reader := GetActiveErpReader;
  if Reader = nil then
  begin
    ShowMessage('No hay ning'#250'n ERP activo para seleccionar art'#237'culos. ' +
      'Escriba el c'#243'digo manualmente.');
    Exit;
  end;

  if TfrmArticuloPicker.Execute(Reader, Cod, Desc) then
    tvArt.DataController.Values[Idx, colArtCodigo.Index] := Cod;
end;

end.
