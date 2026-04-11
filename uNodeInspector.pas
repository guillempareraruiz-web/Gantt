unit uNodeInspector;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.ComCtrls, System.DateUtils, System.Variants,
  System.Generics.Collections,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxStyles, cxVGrid, cxInplaceContainer,
  cxTextEdit, cxSpinEdit, cxCheckBox, cxDropDownEdit, cxCalendar,
  cxDateUtils, cxMaskEdit,
  dxSkinsCore, dxSkinMetropolis, dxSkinOffice2019Colorful,
  // Project
  uGanttTypes, uNodeDataRepo, uCustomFieldDefs, uCustomFieldEditor, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolisDark,
  dxSkinMoneyTwins, dxSkinOffice2007Black, dxSkinOffice2007Blue,
  dxSkinOffice2007Green, dxSkinOffice2007Pink, dxSkinOffice2007Silver,
  dxSkinOffice2010Black, dxSkinOffice2010Blue, dxSkinOffice2010Silver,
  dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray, dxSkinOffice2013White,
  dxSkinOffice2016Colorful, dxSkinOffice2016Dark, dxSkinOffice2019Black,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, cxFilter,
  dxScrollbarAnnotations, cxClasses;

type
  TfrmNodeInspector = class(TForm)
    pcMain: TPageControl;
    tabGeneral: TTabSheet;
    vg: TcxVerticalGrid;
    tabCustomFields: TTabSheet;
    pnlCustomTop: TPanel;
    btnEditFields: TButton;
    vgCustom: TcxVerticalGrid;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    LookAndFeel: TcxLookAndFeelController;
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    chkDarkMode: TCheckBox;
    procedure chkDarkModeClick(Sender: TObject);
    procedure btnEditFieldsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FNodeData: TNodeData;
    FReadOnly: Boolean;
    FCustomFieldDefs: TCustomFieldDefs;
    FCustomRows: TArray<TcxEditorRow>;
    FCatCustom: TcxCategoryRow;
    FStyleReadOnly: TcxStyle;
    FStyleRequired: TcxStyle;
    // Category rows
    FCatIdentitat: TcxCategoryRow;
    FCatComanda: TcxCategoryRow;
    FCatDates: TcxCategoryRow;
    FCatArticle: TcxCategoryRow;
    FCatProduccio: TcxCategoryRow;
    FCatRecursos: TcxCategoryRow;
    FCatEstat: TcxCategoryRow;
    FCatVisual: TcxCategoryRow;
    // Editor rows
    FRowDataId: TcxEditorRow;
    FRowOperacion: TcxEditorRow;
    FRowCentresTrabajo: TcxEditorRow;
    FRowCentresPermesos: TcxEditorRow;
    FRowNumeroPedido: TcxEditorRow;
    FRowSeriePedido: TcxEditorRow;
    FRowNumeroOF: TcxEditorRow;
    FRowSerieFab: TcxEditorRow;
    FRowNumeroTrabajo: TcxEditorRow;
    FRowFechaEntrega: TcxEditorRow;
    FRowFechaNecesaria: TcxEditorRow;
    FRowCodigoArticulo: TcxEditorRow;
    FRowDescripcionArticulo: TcxEditorRow;
    FRowCodigoCliente: TcxEditorRow;
    FRowCodigoColor: TcxEditorRow;
    FRowCodigoTalla: TcxEditorRow;
    FRowStock: TcxEditorRow;
    FRowPctDependencia: TcxEditorRow;
    FRowUnidadesFab: TcxEditorRow;
    FRowUnidadesAFab: TcxEditorRow;
    FRowTiempoUnidad: TcxEditorRow;
    FRowDurationMin: TcxEditorRow;
    FRowDurationMinOrig: TcxEditorRow;
    FRowOperariosNec: TcxEditorRow;
    FRowOperariosAsig: TcxEditorRow;
    FRowEstado: TcxEditorRow;
    FRowPrioridad: TcxEditorRow;
    FRowBkColor: TcxEditorRow;
    FRowBorderColor: TcxEditorRow;
    FRowSelected: TcxEditorRow;
    FRowModified: TcxEditorRow;
    FRowLibreMoviment: TcxEditorRow;
    procedure BuildRows;
    function AddCategory(const ACaption: string; AGrid: TcxVerticalGrid = nil): TcxCategoryRow;
    function AddTextRow(AParent: TcxCategoryRow; const ACaption, AValue: string;
      AReadOnly: Boolean = False; AGrid: TcxVerticalGrid = nil): TcxEditorRow;
    function AddIntRow(AParent: TcxCategoryRow; const ACaption: string; AValue: Integer;
      AReadOnly: Boolean = False; AGrid: TcxVerticalGrid = nil): TcxEditorRow;
    function AddFloatRow(AParent: TcxCategoryRow; const ACaption: string; AValue: Double;
      AReadOnly: Boolean = False; AGrid: TcxVerticalGrid = nil): TcxEditorRow;
    function AddBoolRow(AParent: TcxCategoryRow; const ACaption: string; AValue: Boolean;
      AReadOnly: Boolean = False; AGrid: TcxVerticalGrid = nil): TcxEditorRow;
    function AddDateRow(AParent: TcxCategoryRow; const ACaption: string; AValue: TDateTime;
      AReadOnly: Boolean = False; AGrid: TcxVerticalGrid = nil): TcxEditorRow;
    function AddComboRow(AParent: TcxCategoryRow; const ACaption, AValue: string;
      const AItems: array of string; AReadOnly: Boolean = False; AGrid: TcxVerticalGrid = nil): TcxEditorRow;
    function AddColorRow(AParent: TcxCategoryRow; const ACaption: string; AValue: TColor;
      AReadOnly: Boolean = False; AGrid: TcxVerticalGrid = nil): TcxEditorRow;
    procedure ApplyDarkMode(ADark: Boolean);
    procedure BuildCustomRows;
    procedure ApplyCustomFields;
    procedure ApplyToNodeData;
    function GetRowText(ARow: TcxEditorRow): string;
    function GetRowInt(ARow: TcxEditorRow): Integer;
    function GetRowFloat(ARow: TcxEditorRow): Double;
    function GetRowBool(ARow: TcxEditorRow): Boolean;
    function GetRowDate(ARow: TcxEditorRow): TDateTime;
    function EstadoToStr(E: TNodoEstado): string;
    function StrToEstado(const S: string): TNodoEstado;
  public
    class function Execute(var ANodeData: TNodeData; AReadOnly: Boolean = False;
      ACustomFieldDefs: TCustomFieldDefs = nil): Boolean;
  end;

var
  frmNodeInspector: TfrmNodeInspector;

implementation

{$R *.dfm}

{ TfrmNodeInspector }

class function TfrmNodeInspector.Execute(var ANodeData: TNodeData;
  AReadOnly: Boolean; ACustomFieldDefs: TCustomFieldDefs): Boolean;
var
  F: TfrmNodeInspector;
begin
  F := TfrmNodeInspector.Create(Application);
  try
    F.FNodeData := ANodeData;
    F.FReadOnly := AReadOnly;
    F.FCustomFieldDefs := ACustomFieldDefs;

    // Header
    F.lblTitle.Caption := 'OF ' + ANodeData.NumeroOrdenFabricacion.ToString +
      ' - ' + ANodeData.Operacion;
    F.lblSubtitle.Caption := ANodeData.CodigoArticulo + '  ' + ANodeData.DescripcionArticulo;

    if AReadOnly then
    begin
      F.btnOK.Visible := False;
      F.btnCancel.Caption := 'Cerrar';
    end;

    F.BuildRows;
    F.BuildCustomRows;

    // Ocultar tab si no hay campos personalizados
    F.tabCustomFields.TabVisible := (ACustomFieldDefs <> nil) and (ACustomFieldDefs.Count > 0);

    Result := F.ShowModal = mrOk;
    if Result then
      ANodeData := F.FNodeData;
  finally
    F.Free;
  end;
end;

procedure TfrmNodeInspector.FormCreate(Sender: TObject);
begin
  FStyleReadOnly := TcxStyle.Create(Self);
  FStyleReadOnly.Color := $00F0F0F0;       // gris clar de fons
  FStyleReadOnly.Font.Color := clGrayText;  // text gris

  FStyleRequired := TcxStyle.Create(Self);
  FStyleRequired.Font.Style := [fsBold];
  FStyleRequired.TextColor := $000060C0;    // taronja fosc per destacar
end;

procedure TfrmNodeInspector.FormDestroy(Sender: TObject);
begin
  FStyleReadOnly.Free;
  FStyleRequired.Free;
end;

procedure TfrmNodeInspector.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

{ --- Row creation helpers --- }

function TfrmNodeInspector.AddCategory(const ACaption: string; AGrid: TcxVerticalGrid): TcxCategoryRow;
var
  G: TcxVerticalGrid;
begin
  if AGrid <> nil then G := AGrid else G := vg;
  Result := G.Add(TcxCategoryRow) as TcxCategoryRow;
  Result.Properties.Caption := ACaption;
end;

function TfrmNodeInspector.AddTextRow(AParent: TcxCategoryRow;
  const ACaption, AValue: string; AReadOnly: Boolean; AGrid: TcxVerticalGrid): TcxEditorRow;
var
  G: TcxVerticalGrid;
begin
  if AGrid <> nil then G := AGrid else G := vg;
  Result := G.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxTextEditProperties';
  (Result.Properties.EditProperties as TcxTextEditProperties).ReadOnly := AReadOnly or FReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly or FReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmNodeInspector.AddIntRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: Integer; AReadOnly: Boolean; AGrid: TcxVerticalGrid): TcxEditorRow;
var
  Props: TcxSpinEditProperties;
  G: TcxVerticalGrid;
begin
  if AGrid <> nil then G := AGrid else G := vg;
  Result := G.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
  Props := Result.Properties.EditProperties as TcxSpinEditProperties;
  Props.ValueType := vtInt;
  Props.MinValue := -MaxInt;
  Props.MaxValue := MaxInt;
  Props.ReadOnly := AReadOnly or FReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly or FReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmNodeInspector.AddFloatRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: Double; AReadOnly: Boolean; AGrid: TcxVerticalGrid): TcxEditorRow;
var
  Props: TcxSpinEditProperties;
  G: TcxVerticalGrid;
begin
  if AGrid <> nil then G := AGrid else G := vg;
  Result := G.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
  Props := Result.Properties.EditProperties as TcxSpinEditProperties;
  Props.ValueType := vtFloat;
  Props.MinValue := -1E18;
  Props.MaxValue := 1E18;
  Props.Increment := 0.1;
  Props.ReadOnly := AReadOnly or FReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly or FReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmNodeInspector.AddBoolRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: Boolean; AReadOnly: Boolean; AGrid: TcxVerticalGrid): TcxEditorRow;
var
  Props: TcxCheckBoxProperties;
  G: TcxVerticalGrid;
begin
  if AGrid <> nil then G := AGrid else G := vg;
  Result := G.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxCheckBoxProperties';
  Props := Result.Properties.EditProperties as TcxCheckBoxProperties;
  Props.DisplayChecked := 'S'#237;
  Props.DisplayUnchecked := 'No';
  Props.ReadOnly := AReadOnly or FReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly or FReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmNodeInspector.AddDateRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: TDateTime; AReadOnly: Boolean; AGrid: TcxVerticalGrid): TcxEditorRow;
var
  Props: TcxDateEditProperties;
  G: TcxVerticalGrid;
begin
  if AGrid <> nil then G := AGrid else G := vg;
  Result := G.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxDateEditProperties';
  Props := Result.Properties.EditProperties as TcxDateEditProperties;
  Props.ReadOnly := AReadOnly or FReadOnly;
  Props.SaveTime := True;
  Props.ShowTime := True;
  Props.DateButtons := [btnNow, btnClear];
  Props.Kind := ckDateTime;
  Result.Properties.Value := AValue;
  if AReadOnly or FReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmNodeInspector.AddComboRow(AParent: TcxCategoryRow;
  const ACaption, AValue: string; const AItems: array of string;
  AReadOnly: Boolean; AGrid: TcxVerticalGrid): TcxEditorRow;
var
  Props: TcxComboBoxProperties;
  I: Integer;
  G: TcxVerticalGrid;
begin
  if AGrid <> nil then G := AGrid else G := vg;
  Result := G.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxComboBoxProperties';
  Props := Result.Properties.EditProperties as TcxComboBoxProperties;
  Props.DropDownListStyle := lsFixedList;
  Props.ReadOnly := AReadOnly or FReadOnly;
  for I := Low(AItems) to High(AItems) do
    Props.Items.Add(AItems[I]);
  Result.Properties.Value := AValue;
  if AReadOnly or FReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmNodeInspector.AddColorRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: TColor; AReadOnly: Boolean; AGrid: TcxVerticalGrid): TcxEditorRow;
var
  G: TcxVerticalGrid;
begin
  if AGrid <> nil then G := AGrid else G := vg;
  Result := G.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxTextEditProperties';
  (Result.Properties.EditProperties as TcxTextEditProperties).ReadOnly := True;
  Result.Properties.Value := '$' + IntToHex(AValue, 6);
  Result.Styles.Content := vg.Styles.Category;
end;

{ --- Build all rows --- }

procedure TfrmNodeInspector.BuildRows;
var
  D: TNodeData;

  function ArrayToStr(const A: TArray<string>): string;
  var I: Integer;
  begin
    Result := '';
    for I := 0 to High(A) do
    begin
      if I > 0 then Result := Result + ', ';
      Result := Result + A[I];
    end;
  end;

  function IntArrayToStr(const A: TArray<Integer>): string;
  var I: Integer;
  begin
    Result := '';
    for I := 0 to High(A) do
    begin
      if I > 0 then Result := Result + ', ';
      Result := Result + A[I].ToString;
    end;
  end;

begin
  D := FNodeData;
  vg.BeginUpdate;
  try
    vg.ClearRows;

    // ── Identidad ──
    FCatIdentitat := AddCategory('Identificaci'#243'n');
    FRowDataId        := AddIntRow(FCatIdentitat, 'DataId', D.DataId, True);
    FRowOperacion     := AddTextRow(FCatIdentitat, 'Operaci'#243'n', D.Operacion);
    FRowCentresTrabajo := AddTextRow(FCatIdentitat, 'Centros Trabajo', ArrayToStr(D.CentresTrabajo), True);
    FRowCentresPermesos := AddTextRow(FCatIdentitat, 'Centros Permitidos', IntArrayToStr(D.CentresPermesos), True);

    // ── Pedido / OF ──
    FCatComanda := AddCategory('Pedido / OF');
    FRowNumeroPedido  := AddIntRow(FCatComanda, 'N'#250'm. Pedido', D.NumeroPedido, True);
    FRowSeriePedido   := AddTextRow(FCatComanda, 'Serie Pedido', D.SeriePedido, True);
    FRowNumeroOF      := AddIntRow(FCatComanda, 'N'#250'm. Orden Fabricaci'#243'n', D.NumeroOrdenFabricacion, True);
    FRowSerieFab      := AddTextRow(FCatComanda, 'Serie Fabricaci'#243'n', D.SerieFabricacion, True);
    FRowNumeroTrabajo := AddTextRow(FCatComanda, 'N'#250'm. Trabajo', D.NumeroTrabajo, True);

    // ── Fechas ──
    FCatDates := AddCategory('Fechas');
    FRowFechaEntrega    := AddDateRow(FCatDates, 'Fecha Entrega', D.FechaEntrega);
    FRowFechaNecesaria  := AddDateRow(FCatDates, 'Fecha Necesaria', D.FechaNecesaria);

    // ── Art'iculo ──
    FCatArticle := AddCategory('Art'#237'culo');
    FRowCodigoArticulo     := AddTextRow(FCatArticle, 'C'#243'digo Art'#237'culo', D.CodigoArticulo, True);
    FRowDescripcionArticulo := AddTextRow(FCatArticle, 'Descripci'#243'n', D.DescripcionArticulo, True);
    FRowCodigoCliente      := AddTextRow(FCatArticle, 'C'#243'digo Cliente', D.CodigoCliente, True);
    FRowCodigoColor        := AddTextRow(FCatArticle, 'Color', D.CodigoColor, True);
    FRowCodigoTalla        := AddTextRow(FCatArticle, 'Talla', D.CodigoTalla, True);
    FRowStock              := AddFloatRow(FCatArticle, 'Stock', D.Stock);

    // ── Producci'on ──
    FCatProduccio := AddCategory('Producci'#243'n');
    FRowPctDependencia := AddFloatRow(FCatProduccio, '% Dependencia', D.PorcentajeDependencia);
    FRowUnidadesFab    := AddFloatRow(FCatProduccio, 'Unidades Fabricadas', D.UnidadesFabricadas);
    FRowUnidadesAFab   := AddFloatRow(FCatProduccio, 'Unidades a Fabricar', D.UnidadesAFabricar);
    FRowTiempoUnidad   := AddFloatRow(FCatProduccio, 'Tiempo/Unidad (seg)', D.TiempoUnidadFabSecs);
    FRowDurationMin    := AddFloatRow(FCatProduccio, 'Duraci'#243'n (min)', D.DurationMin);
    FRowDurationMinOrig := AddFloatRow(FCatProduccio, 'Duraci'#243'n Original (min)', D.DurationMinOriginal, True);

    // ── Recursos ──
    FCatRecursos := AddCategory('Recursos');
    FRowOperariosNec  := AddIntRow(FCatRecursos, 'Operarios Necesarios', D.OperariosNecesarios);
    FRowOperariosAsig := AddIntRow(FCatRecursos, 'Operarios Asignados', D.OperariosAsignados);

    // ── Estado ──
    FCatEstat := AddCategory('Estado');
    FRowEstado    := AddComboRow(FCatEstat, 'Estado', EstadoToStr(D.Estado),
      ['Pendiente', 'EnCurso', 'Finalizado', 'Bloqueado']);
    FRowPrioridad := AddIntRow(FCatEstat, 'Prioridad', D.Prioridad);
    FRowModified  := AddBoolRow(FCatEstat, 'Modificado', D.Modified, True);
    FRowLibreMoviment := AddBoolRow(FCatEstat, 'Libre Movimiento', D.LibreMoviment);

    // ── Visual ──
    FCatVisual := AddCategory('Visual');
    FRowBkColor     := AddColorRow(FCatVisual, 'Color Fondo', D.bkColorOp, True);
    FRowBorderColor := AddColorRow(FCatVisual, 'Color Borde', D.borderColorOp, True);
    FRowSelected    := AddBoolRow(FCatVisual, 'Seleccionado', D.Selected, True);

  finally
    vg.EndUpdate;
  end;
end;

{ --- Value getters --- }

function TfrmNodeInspector.GetRowText(ARow: TcxEditorRow): string;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := ''
  else
    Result := VarToStr(ARow.Properties.Value);
end;

function TfrmNodeInspector.GetRowInt(ARow: TcxEditorRow): Integer;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := 0
  else
    Result := ARow.Properties.Value;
end;

function TfrmNodeInspector.GetRowFloat(ARow: TcxEditorRow): Double;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := 0
  else
    Result := ARow.Properties.Value;
end;

function TfrmNodeInspector.GetRowBool(ARow: TcxEditorRow): Boolean;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := False
  else
    Result := ARow.Properties.Value;
end;

function TfrmNodeInspector.GetRowDate(ARow: TcxEditorRow): TDateTime;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := 0
  else
    Result := VarToDateTime(ARow.Properties.Value);
end;

function TfrmNodeInspector.EstadoToStr(E: TNodoEstado): string;
begin
  case E of
    nePendiente:   Result := 'Pendiente';
    neEnCurso:     Result := 'EnCurso';
    neFinalizado:  Result := 'Finalizado';
    neBloqueado:   Result := 'Bloqueado';
  else
    Result := 'Pendiente';
  end;
end;

function TfrmNodeInspector.StrToEstado(const S: string): TNodoEstado;
begin
  if SameText(S, 'EnCurso') then Result := neEnCurso
  else if SameText(S, 'Finalizado') then Result := neFinalizado
  else if SameText(S, 'Bloqueado') then Result := neBloqueado
  else Result := nePendiente;
end;

{ --- Custom fields --- }

procedure TfrmNodeInspector.BuildCustomRows;
var
  Defs: TArray<TCustomFieldDef>;
  I: Integer;
  D: TCustomFieldDef;
  V: Variant;
  Row: TcxEditorRow;
  GrupoMap: TDictionary<string, TcxCategoryRow>;
  ParentCat: TcxCategoryRow;
  GrupoKey: string;
begin
  if FCustomFieldDefs = nil then Exit;

  Defs := FCustomFieldDefs.GetVisibleDefs;
  if Length(Defs) = 0 then Exit;

  GrupoMap := TDictionary<string, TcxCategoryRow>.Create;
  try
  vgCustom.BeginUpdate;
  try
    vgCustom.ClearRows;

    SetLength(FCustomRows, Length(Defs));

    for I := 0 to High(Defs) do
    begin
      D := Defs[I];
      V := GetCustomFieldValue(FNodeData.CustomFields, D.FieldName);
      if VarIsNull(V) or VarIsEmpty(V) then
        V := D.DefaultValue;

      // Determinar categoria per grup
      if D.Grupo <> '' then
        GrupoKey := D.Grupo
      else
        GrupoKey := 'Campos Personalizados';

      if not GrupoMap.TryGetValue(GrupoKey, ParentCat) then
      begin
        ParentCat := AddCategory(GrupoKey, vgCustom);
        GrupoMap.Add(GrupoKey, ParentCat);
      end;

      case D.FieldType of
        cftString:
          Row := AddTextRow(ParentCat, D.Caption, VarToStr(V), D.ReadOnly, vgCustom);
        cftInteger:
        begin
          if VarIsNull(V) or VarIsEmpty(V) then
            Row := AddIntRow(ParentCat, D.Caption, 0, D.ReadOnly, vgCustom)
          else
            Row := AddIntRow(ParentCat, D.Caption, V, D.ReadOnly, vgCustom);
        end;
        cftFloat:
        begin
          if VarIsNull(V) or VarIsEmpty(V) then
            Row := AddFloatRow(ParentCat, D.Caption, 0, D.ReadOnly, vgCustom)
          else
            Row := AddFloatRow(ParentCat, D.Caption, Double(V), D.ReadOnly, vgCustom);
        end;
        cftDate:
        begin
          if VarIsNull(V) or VarIsEmpty(V) then
            Row := AddDateRow(ParentCat, D.Caption, 0, D.ReadOnly, vgCustom)
          else
            Row := AddDateRow(ParentCat, D.Caption, VarToDateTime(V), D.ReadOnly, vgCustom);
        end;
        cftBoolean:
        begin
          if VarIsNull(V) or VarIsEmpty(V) then
            Row := AddBoolRow(ParentCat, D.Caption, False, D.ReadOnly, vgCustom)
          else
            Row := AddBoolRow(ParentCat, D.Caption, Boolean(V), D.ReadOnly, vgCustom);
        end;
        cftList:
          Row := AddComboRow(ParentCat, D.Caption, VarToStr(V), D.ListValues, D.ReadOnly, vgCustom);
      else
        Row := AddTextRow(ParentCat, D.Caption, VarToStr(V), D.ReadOnly, vgCustom);
      end;

      // Aplicar MinValue/MaxValue para numèrics
      if (D.FieldType in [cftInteger, cftFloat]) and
         ((D.MinValue <> 0) or (D.MaxValue <> 0)) then
      begin
        if Row.Properties.EditProperties is TcxSpinEditProperties then
        begin
          (Row.Properties.EditProperties as TcxSpinEditProperties).MinValue := D.MinValue;
          (Row.Properties.EditProperties as TcxSpinEditProperties).MaxValue := D.MaxValue;
        end;
      end;

      // Aplicar Tooltip
      if D.Tooltip <> '' then
        Row.Properties.Hint := D.Tooltip;

      // Estilo visual ReadOnly
      if D.ReadOnly then
        Row.Styles.Content := FStyleReadOnly;

      // Estilo visual Required (negreta + color al header)
      if D.Required then
      begin
        Row.Styles.Header := FStyleRequired;
        Row.Properties.Caption := D.Caption + ' *';
      end;

      FCustomRows[I] := Row;
    end;
  finally
    vgCustom.EndUpdate;
  end;
  finally
    GrupoMap.Free;
  end;
end;

procedure TfrmNodeInspector.ApplyCustomFields;
var
  Defs: TArray<TCustomFieldDef>;
  I: Integer;
  D: TCustomFieldDef;
  Row: TcxEditorRow;
begin
  if FCustomFieldDefs = nil then Exit;

  Defs := FCustomFieldDefs.GetVisibleDefs;
  for I := 0 to High(Defs) do
  begin
    if I > High(FCustomRows) then Break;
    D := Defs[I];
    Row := FCustomRows[I];

    case D.FieldType of
      cftString, cftList:
        SetCustomFieldValue(FNodeData.CustomFields, D.FieldName, GetRowText(Row));
      cftInteger:
        SetCustomFieldValue(FNodeData.CustomFields, D.FieldName, GetRowInt(Row));
      cftFloat:
        SetCustomFieldValue(FNodeData.CustomFields, D.FieldName, GetRowFloat(Row));
      cftDate:
        SetCustomFieldValue(FNodeData.CustomFields, D.FieldName, GetRowDate(Row));
      cftBoolean:
        SetCustomFieldValue(FNodeData.CustomFields, D.FieldName, GetRowBool(Row));
    end;
  end;
end;

{ --- Edit custom field definitions --- }

procedure TfrmNodeInspector.btnEditFieldsClick(Sender: TObject);
begin
  if FCustomFieldDefs = nil then Exit;
  if TfrmCustomFieldEditor.Execute(FCustomFieldDefs) then
  begin
    FCustomFieldDefs.SaveToFile;
    BuildCustomRows;
    tabCustomFields.TabVisible := FCustomFieldDefs.Count > 0;
  end;
end;

{ --- Apply changes back --- }

procedure TfrmNodeInspector.chkDarkModeClick(Sender: TObject);
begin
  ApplyDarkMode(chkDarkMode.Checked);
end;

procedure TfrmNodeInspector.ApplyDarkMode(ADark: Boolean);
const
  DARK_BG     = $00302C28;  // fons fosc
  DARK_HEADER = $003C3836;
  DARK_TEXT   = $00F0F0F0;
  DARK_SUB    = $00A0A0A0;
  DARK_LINE   = $00504840;
  LIGHT_BG    = clWhite;
  LIGHT_HEADER = clWhite;
  LIGHT_TITLE  = 4474440;
begin
  if ADark then
  begin
    LookAndFeel.SkinName := 'Office2019Black';
    // Header
    pnlHeader.Color := DARK_HEADER;
    lblTitle.Font.Color := DARK_TEXT;
    lblSubtitle.Font.Color := DARK_SUB;
    shpHeaderLine.Brush.Color := DARK_LINE;
    chkDarkMode.Font.Color := DARK_TEXT;
    // Bottom
    pnlBottom.Color := DARK_HEADER;
    // Form
    Color := DARK_BG;
  end
  else
  begin
    LookAndFeel.SkinName := 'Office2019Colorful';
    // Header
    pnlHeader.Color := LIGHT_HEADER;
    lblTitle.Font.Color := LIGHT_TITLE;
    lblSubtitle.Font.Color := clGray;
    shpHeaderLine.Brush.Color := 15061727;
    chkDarkMode.Font.Color := clWindowText;
    // Bottom
    pnlBottom.Color := clBtnFace;
    // Form
    Color := clBtnFace;
  end;
end;

procedure TfrmNodeInspector.ApplyToNodeData;
begin
  FNodeData.Operacion           := GetRowText(FRowOperacion);
  FNodeData.FechaEntrega        := GetRowDate(FRowFechaEntrega);
  FNodeData.FechaNecesaria      := GetRowDate(FRowFechaNecesaria);
  FNodeData.Stock               := GetRowFloat(FRowStock);
  FNodeData.PorcentajeDependencia := GetRowFloat(FRowPctDependencia);
  FNodeData.UnidadesFabricadas  := GetRowFloat(FRowUnidadesFab);
  FNodeData.UnidadesAFabricar   := GetRowFloat(FRowUnidadesAFab);
  FNodeData.TiempoUnidadFabSecs := GetRowFloat(FRowTiempoUnidad);
  FNodeData.DurationMin         := GetRowFloat(FRowDurationMin);
  FNodeData.OperariosNecesarios := GetRowInt(FRowOperariosNec);
  FNodeData.OperariosAsignados  := GetRowInt(FRowOperariosAsig);
  FNodeData.Estado              := StrToEstado(GetRowText(FRowEstado));
  FNodeData.Prioridad           := GetRowInt(FRowPrioridad);
  FNodeData.LibreMoviment       := GetRowBool(FRowLibreMoviment);
  ApplyCustomFields;
end;

procedure TfrmNodeInspector.btnOKClick(Sender: TObject);
begin
  ApplyToNodeData;
  ModalResult := mrOk;
end;

procedure TfrmNodeInspector.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
