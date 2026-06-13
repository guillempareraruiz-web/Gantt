unit uNodeLayoutEditor;

{
  TfrmNodeLayoutEditor - Editor visual de Node Layout estilo Trello.

  Clon de TfrmCardLayoutEditor (uCardLayoutEditor) adaptado al modelo de NODO
  del Gantt (uNodeCardLayout):
    - El selector NO es por categoria (TCardCategory) sino por VISTA
      (TGanttViewMode): cada vista tiene su propio TNodeCardLayout.
    - El modelo (TNodeCardLayout) NO tiene CardHeight editable (el tamano del
      nodo lo impone el Gantt). Las propiedades globales son: Name, PaddingH,
      PaddingV, CornerRadius, BgColor, BorderColor, BorderWidth, FontName.
    - La preview convierte el TNodeCardLayout a TCardLayout
      (NodeLayoutToCardLayout) y lo pinta con el RenderCard existente, sobre un
      fondo que simula una barra baja y ancha del Gantt.

  Reutiliza los dialogos auxiliares de uCardLayoutEditor (EditElementDialog,
  GetAvailableFields) que trabajan sobre TCardElement; aqui se hace conversion
  local TNodeCardElement <-> TCardElement.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.Math, System.Variants, System.StrUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Samples.Spin, Vcl.Menus,
  cxVGrid, cxInplaceContainer, cxControls, cxEdit, cxTextEdit,
  cxSpinEdit, cxColorComboBox, cxCheckBox, cxDropDownEdit, cxContainer, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters,
  uGanttTypes, uCardLayout, uNodeCardLayout, uNodeLayoutSetRepo,
  uCardLayoutEditor, uCustomFieldDefs, uHelpViewer,
  dxSkinsCore, dxSkinBasic,
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
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, cxStyles, cxFilter,
  dxScrollbarAnnotations;

type
  // Panel que representa un elemento dentro de una fila (card Trello)
  TNodeElementCard = class(TPanel)
  private
    FRowIdx: Integer;
    FElemIdx: Integer;
    FElement: TNodeCardElement;
    FOnChanged: TNotifyEvent;
    FOnDelete: TNotifyEvent;
    FOnMoveUp: TNotifyEvent;
    FOnMoveDown: TNotifyEvent;
    FOnSelect: TNotifyEvent;
    FCustomFieldDefs: TCustomFieldDefs;
    FSelected: Boolean;

    lblKind: TLabel;
    lblExpr: TLabel;
    btnEdit: TLabel;
    btnDel: TLabel;
    btnUp: TLabel;
    btnDown: TLabel;

    procedure SetSelected(AValue: Boolean);
    procedure ApplyVisualState;
    procedure HandleSelectClick(Sender: TObject);
    procedure DoEdit(Sender: TObject);
    procedure DoDel(Sender: TObject);
    procedure DoUp(Sender: TObject);
    procedure DoDown(Sender: TObject);
  public
    constructor Create(AOwner: TComponent; ARowIdx, AElemIdx: Integer;
      const AElem: TNodeCardElement); reintroduce;
    procedure UpdateFrom(const AElem: TNodeCardElement);
    property Element: TNodeCardElement read FElement;
    property RowIdx: Integer read FRowIdx;
    property ElemIdx: Integer read FElemIdx write FElemIdx;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnDelete: TNotifyEvent read FOnDelete write FOnDelete;
    property OnMoveUp: TNotifyEvent read FOnMoveUp write FOnMoveUp;
    property OnMoveDown: TNotifyEvent read FOnMoveDown write FOnMoveDown;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
    property Selected: Boolean read FSelected write SetSelected;
    property CustomFieldDefs: TCustomFieldDefs read FCustomFieldDefs write FCustomFieldDefs;
  end;

  // Panel que representa una fila (columna Trello)
  TNodeRowPanel = class(TPanel)
  private
    FRowIdx: Integer;
    FRow: TNodeCardRow;
    pnlHeader: TPanel;
    lblRowTitle: TLabel;
    lblHeight: TLabel;
    seHeight: TSpinEdit;
    btnAddElem: TLabel;
    btnRowUp: TLabel;
    btnRowDown: TLabel;
    btnRowDel: TLabel;
    pnlElements: TScrollBox;
    FElementCards: TList<TNodeElementCard>;
    FOnChanged: TNotifyEvent;
    FOnSelect: TNotifyEvent;
    FOnElemSelect: TNotifyEvent;
    FOnDelete: TNotifyEvent;
    FOnMoveUp: TNotifyEvent;
    FOnMoveDown: TNotifyEvent;
    FCustomFieldDefs: TCustomFieldDefs;
    FSelected: Boolean;

    procedure SetSelected(AValue: Boolean);
    procedure ApplyVisualState;
    procedure HandleElemSelect(Sender: TObject);
    procedure HandleRowSelectClick(Sender: TObject);

    procedure DoAddElement(Sender: TObject);
    procedure DoHeightChange(Sender: TObject);
    procedure DoRowUp(Sender: TObject);
    procedure DoRowDown(Sender: TObject);
    procedure DoRowDel(Sender: TObject);
    procedure HandleElemChanged(Sender: TObject);
    procedure HandleElemDelete(Sender: TObject);
    procedure HandleElemMoveUp(Sender: TObject);
    procedure HandleElemMoveDown(Sender: TObject);
  public
    constructor Create(AOwner: TComponent; ARowIdx: Integer;
      const ARow: TNodeCardRow); reintroduce;
    destructor Destroy; override;
    procedure RebuildElements;
    procedure RecalcHeight;
    property Row: TNodeCardRow read FRow write FRow;
    property RowIdx: Integer read FRowIdx write FRowIdx;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
    property OnElemSelect: TNotifyEvent read FOnElemSelect write FOnElemSelect;
    property OnDelete: TNotifyEvent read FOnDelete write FOnDelete;
    property OnMoveUp: TNotifyEvent read FOnMoveUp write FOnMoveUp;
    property OnMoveDown: TNotifyEvent read FOnMoveDown write FOnMoveDown;
    property Selected: Boolean read FSelected write SetSelected;
    property ElementCards: TList<TNodeElementCard> read FElementCards;
    property CustomFieldDefs: TCustomFieldDefs read FCustomFieldDefs write FCustomFieldDefs;
  end;

  TfrmNodeLayoutEditor = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    lblSetName: TLabel;
    lblVista: TLabel;
    cmbVista: TComboBox;

    pnlFooter: TPanel;
    btnAceptar: TButton;
    btnCancelar: TButton;
    pnlMain: TPanel;
    pnlLeft: TPanel;
    pnlRowsHeader: TPanel;
    lblRows: TLabel;
    btnAddRow: TLabel;
    btnDelRow: TButton;
    pnlRowsArea: TPanel;
    boxRows: TScrollBox;
    pnlRight: TPanel;
    pnlPreviewHeader: TPanel;
    lblPreview: TLabel;
    pnlPreviewArea: TPanel;
    pbPreview: TPaintBox;
    pnlProps: TPanel;
    lblProps: TLabel;
    vgProps: TcxVerticalGrid;
    procedure cmbVistaChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pbPreviewPaint(Sender: TObject);
    procedure btnAddRowClick(Sender: TObject);
    procedure btnDelRowClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
  private
    FLayout: TNodeCardLayout;
    FRowPanels: TObjectList<TNodeRowPanel>;
    FSampleData: TNodeData;
    FCustomFieldDefs: TCustomFieldDefs;
    FLayoutSet: TNodeLayoutSet;
    FCurrentView: TGanttViewMode;
    FViews: TArray<TGanttViewMode>;     // ItemIndex -> TGanttViewMode
    FLoadingView: Boolean;
    FUpdatingProps: Boolean;
    FSelectedRow: TNodeRowPanel;        // fila seleccionada (nil = cap)
    FSelectedElemRow: Integer;          // row idx de l'element seleccionat (-1 = cap)
    FSelectedElemIdx: Integer;          // col idx dins la fila

    // Row del cxVerticalGrid de propietats (solo el nombre es informativo; el
    // resto del estilo lo decide el Gantt en render).
    FRowName: TcxEditorRow;

    procedure HandleRowSelected(Sender: TObject);
    procedure HandleElemSelected(Sender: TObject);
    procedure HandleRowDeleted(Sender: TObject);
    procedure HandleRowMoveUp(Sender: TObject);
    procedure HandleRowMoveDown(Sender: TObject);
    procedure ClearAllSelections;

    procedure BuildPropsGrid;
    procedure HandlePropChanged(Sender: TObject);

    procedure BuildSampleData;
    procedure BuildSampleDataFor(V: TGanttViewMode);
    procedure RebuildRowPanels;
    procedure RestoreSelection(ARowIdx, AElemIdx: Integer);
    procedure RepositionRowPanels;
    procedure RefreshPreview;
    procedure OnRowChanged(Sender: TObject);
    procedure PopulateVistas;
    procedure CommitCurrentLayout;
    procedure LoadViewIntoUI(V: TGanttViewMode);
    function PreviewHeightPx: Integer;
  public
    procedure LayoutToUI;
    procedure SetLayoutSet(const ASet: TNodeLayoutSet);
    function GetLayoutSet: TNodeLayoutSet;
    procedure SetDisplayName(const ANombre: string; AIsCommon: Boolean);
    property Layout: TNodeCardLayout read FLayout write FLayout;
    property LayoutSet: TNodeLayoutSet read GetLayoutSet write SetLayoutSet;
    property CustomFieldDefs: TCustomFieldDefs read FCustomFieldDefs write FCustomFieldDefs;
  end;

// Punto de entrada de alto nivel: siembra el set de sistema si falta, carga el
// activo, muestra el editor y persiste si el usuario acepta.
function ShowNodeLayoutEditor(AOwner: TForm; ARepo: TNodeLayoutSetRepo): Boolean;

implementation

{$R *.dfm}

{ ---- Edicion de elemento (dialogo propio simplificado) ---- }

// Edita un TNodeCardElement con un dialogo PROPIO y SIMPLIFICADO.
//
// A diferencia del editor de elementos del Card del backlog
// (uCardLayoutEditor.EditElementDialog), aqui el usuario SOLO decide CONTENIDO
// y DISPOSICION: que campo mostrar, alineacion, ancho, enfasis (negrita) y
// visibilidad/condicion. El TAMANO y los COLORES (incluido el color del badge
// segun estado) los impone el GanttControl en tiempo de render; por eso NO se
// exponen color de fuente, color de fondo, radio ni reglas condicionales.
//
// El dialogo es propio (no se reutiliza el compartido) precisamente para no
// arrastrar al Nodo las opciones de estilo que el Card del backlog si necesita.
type
  // Mini-dialogo: solo necesita guardar referencias a edtExpr/cmbFields para el
  // handler "Insertar campo" (TNotifyEvent exige un metodo, no un anonimo).
  TfrmEditNodeField = class(TForm)
  public
    edtExpr: TEdit;
    cmbFields: TComboBox;
    procedure DoInsertField(Sender: TObject);
  end;

procedure TfrmEditNodeField.DoInsertField(Sender: TObject);
begin
  if cmbFields.ItemIndex >= 0 then
    edtExpr.Text := edtExpr.Text + '{' + cmbFields.Items[cmbFields.ItemIndex] + '}';
end;

function EditNodeElementDialog(AOwner: TForm; var AElem: TNodeCardElement;
  ACustomFieldDefs: TCustomFieldDefs): Boolean;
var
  Dlg: TfrmEditNodeField;
  lblKind, lblExpr, lblAlign, lblWidth, lblCondition, lblNote: TLabel;
  cmbKind, cmbAlign: TComboBox;
  edtCondition: TEdit;
  seWidth: TSpinEdit;
  chkBold, chkVisible: TCheckBox;
  btnInsertField, btnOk, btnCancel: TButton;
  Fields: TArray<string>;
  I, Y: Integer;
begin
  Result := False;
  Dlg := TfrmEditNodeField.CreateNew(AOwner);
  try
    Dlg.Caption := 'Campo del nodo';
    Dlg.ClientWidth := 440;
    Dlg.ClientHeight := 320;
    Dlg.Position := poOwnerFormCenter;
    Dlg.BorderStyle := bsDialog;
    Dlg.Font.Name := 'Segoe UI';
    Dlg.Font.Size := 9;

    Y := 12;

    // Tipo (solo Texto / Badge: los demas no aportan al contenido del nodo)
    lblKind := TLabel.Create(Dlg); lblKind.Parent := Dlg;
    lblKind.SetBounds(12, Y, 80, 15); lblKind.Caption := 'Tipo:';
    cmbKind := TComboBox.Create(Dlg); cmbKind.Parent := Dlg;
    cmbKind.Style := csDropDownList;
    cmbKind.SetBounds(100, Y - 2, 140, 23);
    cmbKind.Items.AddStrings(['Texto', 'Etiqueta (badge)']);
    if AElem.Kind = ceBadge then cmbKind.ItemIndex := 1
    else cmbKind.ItemIndex := 0;
    Inc(Y, 32);

    // Expresion
    lblExpr := TLabel.Create(Dlg); lblExpr.Parent := Dlg;
    lblExpr.SetBounds(12, Y, 80, 15); lblExpr.Caption := 'Contenido:';
    Dlg.edtExpr := TEdit.Create(Dlg); Dlg.edtExpr.Parent := Dlg;
    Dlg.edtExpr.SetBounds(100, Y - 2, 326, 23);
    Dlg.edtExpr.Text := AElem.FieldExpr;
    Inc(Y, 28);

    // Insertar campo
    Dlg.cmbFields := TComboBox.Create(Dlg); Dlg.cmbFields.Parent := Dlg;
    Dlg.cmbFields.Style := csDropDownList;
    Dlg.cmbFields.SetBounds(100, Y - 2, 200, 23);
    Fields := GetAvailableFields(ACustomFieldDefs);
    for I := 0 to High(Fields) do
      Dlg.cmbFields.Items.Add(Fields[I]);
    if Dlg.cmbFields.Items.Count > 0 then Dlg.cmbFields.ItemIndex := 0;
    btnInsertField := TButton.Create(Dlg); btnInsertField.Parent := Dlg;
    btnInsertField.SetBounds(310, Y - 2, 116, 23);
    btnInsertField.Caption := 'Insertar {Campo}';
    btnInsertField.OnClick := Dlg.DoInsertField;
    Inc(Y, 36);

    // Alineacion
    lblAlign := TLabel.Create(Dlg); lblAlign.Parent := Dlg;
    lblAlign.SetBounds(12, Y, 80, 15); lblAlign.Caption := 'Alineaci'#243'n:';
    cmbAlign := TComboBox.Create(Dlg); cmbAlign.Parent := Dlg;
    cmbAlign.Style := csDropDownList;
    cmbAlign.SetBounds(100, Y - 2, 120, 23);
    cmbAlign.Items.AddStrings(['Izquierda', 'Centro', 'Derecha']);
    cmbAlign.ItemIndex := Ord(AElem.HAlign);

    chkBold := TCheckBox.Create(Dlg); chkBold.Parent := Dlg;
    chkBold.SetBounds(250, Y, 100, 20); chkBold.Caption := 'Negrita';
    chkBold.Checked := AElem.FontBold;
    Inc(Y, 32);

    // Ancho %
    lblWidth := TLabel.Create(Dlg); lblWidth.Parent := Dlg;
    lblWidth.SetBounds(12, Y, 85, 15); lblWidth.Caption := 'Ancho %:';
    seWidth := TSpinEdit.Create(Dlg); seWidth.Parent := Dlg;
    seWidth.SetBounds(100, Y - 2, 60, 23);
    seWidth.MinValue := 0; seWidth.MaxValue := 100;
    seWidth.Value := AElem.WidthPct;

    chkVisible := TCheckBox.Create(Dlg); chkVisible.Parent := Dlg;
    chkVisible.SetBounds(250, Y, 100, 20); chkVisible.Caption := 'Visible';
    chkVisible.Checked := AElem.Visible;
    Inc(Y, 32);

    // Condicion (mostrar solo si el campo tiene valor / > 0)
    lblCondition := TLabel.Create(Dlg); lblCondition.Parent := Dlg;
    lblCondition.SetBounds(12, Y, 85, 15); lblCondition.Caption := 'Mostrar si:';
    edtCondition := TEdit.Create(Dlg); edtCondition.Parent := Dlg;
    edtCondition.SetBounds(100, Y - 2, 200, 23);
    edtCondition.Text := AElem.ConditionField;
    edtCondition.TextHint := 'Campo (vac'#237'o = siempre)';
    Inc(Y, 34);

    // Nota: tamano y colores los pone el Gantt
    lblNote := TLabel.Create(Dlg); lblNote.Parent := Dlg;
    lblNote.SetBounds(12, Y, 414, 30);
    lblNote.AutoSize := False;
    lblNote.WordWrap := True;
    lblNote.Font.Color := $00808080;
    lblNote.Font.Style := [fsItalic];
    lblNote.Caption := 'El tama'#241'o y los colores (incluido el de la etiqueta seg'#250'n '
      + 'el estado) los aplica el Gantt autom'#225'ticamente.';
    Inc(Y, 36);

    // Botones
    btnOk := TButton.Create(Dlg); btnOk.Parent := Dlg;
    btnOk.SetBounds(250, Y, 80, 28);
    btnOk.Caption := 'Aceptar';
    btnOk.ModalResult := mrOk;
    btnOk.Default := True;

    btnCancel := TButton.Create(Dlg); btnCancel.Parent := Dlg;
    btnCancel.SetBounds(340, Y, 80, 28);
    btnCancel.Caption := 'Cancelar';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Cancel := True;

    // Boton '?' en el caption + F1 (mismo patron que el resto de formularios).
    THelpViewer.InstallHelp(Dlg, 'uNodeLayoutEditor', 'Campo del nodo');

    if Dlg.ShowModal = mrOk then
    begin
      if cmbKind.ItemIndex = 1 then AElem.Kind := ceBadge
      else AElem.Kind := ceText;
      AElem.FieldExpr := Dlg.edtExpr.Text;
      AElem.HAlign := TCardHAlign(cmbAlign.ItemIndex);
      AElem.WidthPct := seWidth.Value;
      AElem.FontBold := chkBold.Checked;
      AElem.Visible := chkVisible.Checked;
      AElem.ConditionField := edtCondition.Text;
      // Estilo lo decide el Gantt: dejamos los campos esteticos neutros para que
      // el render no los lea como overrides del usuario.
      AElem.FontColor := 0;
      AElem.BgColor := 0;
      AElem.BgColorField := '';
      AElem.FontItalic := False;
      SetLength(AElem.StyleRules, 0);
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ ---- Datos de ejemplo ---- }

procedure TfrmNodeLayoutEditor.BuildSampleData;
begin
  FSampleData := Default(TNodeData);
  FSampleData.DataId := 1001;
  FSampleData.NumeroOrdenFabricacion := 24350;
  FSampleData.Operacion := 'CORTE';
  FSampleData.CodigoArticulo := 'ART-001';
  FSampleData.DescripcionArticulo := 'Pieza lateral izquierda';
  FSampleData.CodigoCliente := 'CLI-100';
  FSampleData.DurationMin := 180;
  FSampleData.FechaEntrega := Date + 5;
  FSampleData.FechaNecesaria := Date + 3;
  FSampleData.Prioridad := 1;
  FSampleData.Estado := neEnCurso;
  FSampleData.Tipo := ntOF;
  FSampleData.OperariosNecesarios := 3;
  FSampleData.OperariosAsignados := 2;
  FSampleData.UnidadesAFabricar := 500;
  FSampleData.UnidadesFabricadas := 120;
  FSampleData.NumeroPedido := 8800;
  FSampleData.SeriePedido := 'A';
end;

procedure TfrmNodeLayoutEditor.BuildSampleDataFor(V: TGanttViewMode);
begin
  BuildSampleData;
  if V = gvmEstado then
    FSampleData.Estado := nePendiente
  else
    FSampleData.Estado := neEnCurso;
end;

{ ---- TNodeElementCard ---- }

constructor TNodeElementCard.Create(AOwner: TComponent; ARowIdx, AElemIdx: Integer;
  const AElem: TNodeCardElement);
begin
  inherited Create(AOwner);
  FRowIdx := ARowIdx;
  FElemIdx := AElemIdx;
  FElement := AElem;

  Width := 560;
  Height := 42;
  BevelOuter := bvNone;
  Color := clWhite;
  ParentBackground := False;
  Cursor := crDefault;
  DoubleBuffered := True;

  lblKind := TLabel.Create(Self); lblKind.Parent := Self;
  lblKind.SetBounds(10, 4, 60, 15);
  lblKind.Font.Style := [fsBold];
  lblKind.Font.Color := $00FF8000;
  lblKind.Font.Size := 8;

  lblExpr := TLabel.Create(Self); lblExpr.Parent := Self;
  lblExpr.SetBounds(10, 22, 380, 15);
  lblExpr.Font.Color := $00666666;
  lblExpr.Font.Size := 8;
  lblExpr.EllipsisPosition := epEndEllipsis;
  lblExpr.AutoSize := False;
  lblExpr.Width := 380;

  btnUp := TLabel.Create(Self); btnUp.Parent := Self;
  btnUp.SetBounds(390, 8, 24, 24);
  btnUp.Caption := #$25B2;
  btnUp.Font.Size := 11;
  btnUp.Font.Color := $00555555;
  btnUp.Cursor := crHandPoint;
  btnUp.OnClick := DoUp;
  btnUp.Hint := 'Subir elemento';
  btnUp.ShowHint := True;
  btnUp.Visible := False;

  btnDown := TLabel.Create(Self); btnDown.Parent := Self;
  btnDown.SetBounds(414, 8, 24, 24);
  btnDown.Caption := #$25BC;
  btnDown.Font.Size := 11;
  btnDown.Font.Color := $00555555;
  btnDown.Cursor := crHandPoint;
  btnDown.OnClick := DoDown;
  btnDown.Hint := 'Bajar elemento';
  btnDown.ShowHint := True;
  btnDown.Visible := False;

  btnEdit := TLabel.Create(Self); btnEdit.Parent := Self;
  btnEdit.SetBounds(450, 8, 24, 24);
  btnEdit.Caption := #$270E;
  btnEdit.Font.Size := 14;
  btnEdit.Font.Color := $00FF8000;
  btnEdit.Cursor := crHandPoint;
  btnEdit.OnClick := DoEdit;
  btnEdit.Hint := 'Editar elemento';
  btnEdit.ShowHint := True;
  btnEdit.Visible := False;

  btnDel := TLabel.Create(Self); btnDel.Parent := Self;
  btnDel.SetBounds(480, 8, 24, 24);
  btnDel.Caption := #$2716;
  btnDel.Font.Size := 14;
  btnDel.Font.Color := $004040FF;
  btnDel.Cursor := crHandPoint;
  btnDel.OnClick := DoDel;
  btnDel.Hint := 'Eliminar elemento';
  btnDel.ShowHint := True;
  btnDel.Visible := False;

  Self.OnClick := HandleSelectClick;
  lblKind.OnClick := HandleSelectClick;
  lblExpr.OnClick := HandleSelectClick;

  ApplyVisualState;
  UpdateFrom(AElem);
end;

procedure TNodeElementCard.HandleSelectClick(Sender: TObject);
begin
  if Assigned(FOnSelect) then FOnSelect(Self);
end;

procedure TNodeElementCard.SetSelected(AValue: Boolean);
begin
  if FSelected = AValue then Exit;
  FSelected := AValue;
  ApplyVisualState;
end;

procedure TNodeElementCard.ApplyVisualState;
begin
  if FSelected then
  begin
    Color := $00FFE8C8;
    BorderWidth := 2;
  end
  else
  begin
    Color := clWhite;
    BorderWidth := 0;
  end;
  if btnUp <> nil then btnUp.Visible := FSelected;
  if btnDown <> nil then btnDown.Visible := FSelected;
  if btnEdit <> nil then btnEdit.Visible := FSelected;
  if btnDel <> nil then btnDel.Visible := FSelected;
  if HandleAllocated then Invalidate;
end;

procedure TNodeElementCard.UpdateFrom(const AElem: TNodeCardElement);
begin
  FElement := AElem;
  case AElem.Kind of
    ceText: lblKind.Caption := 'TEXTO';
    ceBadge: lblKind.Caption := 'BADGE';
    ceProgressBar: lblKind.Caption := 'BARRA';
    ceSpacer: lblKind.Caption := 'ESPACIO';
  end;
  lblExpr.Caption := AElem.FieldExpr;
  if not AElem.Visible then
    lblExpr.Caption := '(oculto) ' + lblExpr.Caption;
end;

procedure TNodeElementCard.DoEdit(Sender: TObject);
var
  E: TNodeCardElement;
begin
  E := FElement;
  if EditNodeElementDialog(TForm(GetParentForm(Self)), E, FCustomFieldDefs) then
  begin
    FElement := E;
    UpdateFrom(E);
    if Assigned(FOnChanged) then FOnChanged(Self);
  end;
end;

procedure TNodeElementCard.DoDel(Sender: TObject);
begin
  if Assigned(FOnDelete) then FOnDelete(Self);
end;

procedure TNodeElementCard.DoUp(Sender: TObject);
begin
  if Assigned(FOnMoveUp) then FOnMoveUp(Self);
end;

procedure TNodeElementCard.DoDown(Sender: TObject);
begin
  if Assigned(FOnMoveDown) then FOnMoveDown(Self);
end;

{ ---- TNodeRowPanel ---- }

constructor TNodeRowPanel.Create(AOwner: TComponent; ARowIdx: Integer;
  const ARow: TNodeCardRow);
begin
  inherited Create(AOwner);
  FRowIdx := ARowIdx;
  FRow := ARow;
  FElementCards := TList<TNodeElementCard>.Create;

  if AOwner is TWinControl then
    Parent := TWinControl(AOwner);

  Width := 580;
  Height := 200;
  BevelOuter := bvNone;
  Color := $00F5F0EB;
  ParentBackground := False;
  DoubleBuffered := True;

  pnlHeader := TPanel.Create(Self); pnlHeader.Parent := Self;
  pnlHeader.Align := alTop;
  pnlHeader.Height := 36;
  pnlHeader.BevelOuter := bvNone;
  pnlHeader.Color := $00E8E0D8;
  pnlHeader.ParentBackground := False;

  lblRowTitle := TLabel.Create(pnlHeader); lblRowTitle.Parent := pnlHeader;
  lblRowTitle.SetBounds(10, 8, 80, 17);
  lblRowTitle.Font.Style := [fsBold];
  lblRowTitle.Font.Color := $00444444;
  lblRowTitle.Caption := 'Fila ' + IntToStr(ARowIdx + 1);

  lblHeight := TLabel.Create(pnlHeader); lblHeight.Parent := pnlHeader;
  lblHeight.SetBounds(120, 10, 40, 15);
  lblHeight.Caption := 'Alto:';

  seHeight := TSpinEdit.Create(pnlHeader); seHeight.Parent := pnlHeader;
  seHeight.SetBounds(158, 6, 50, 23);
  seHeight.MinValue := 8; seHeight.MaxValue := 60;
  seHeight.Value := ARow.HeightPx;
  if seHeight.Value < 8 then seHeight.Value := 16;
  seHeight.OnChange := DoHeightChange;

  btnRowUp := TLabel.Create(pnlHeader); btnRowUp.Parent := pnlHeader;
  btnRowUp.Anchors := [akTop, akRight];
  btnRowUp.SetBounds(pnlHeader.ClientWidth - 220, 8, 24, 24);
  btnRowUp.Caption := #$25B2;
  btnRowUp.Font.Size := 12;
  btnRowUp.Font.Color := $00555555;
  btnRowUp.Cursor := crHandPoint;
  btnRowUp.OnClick := DoRowUp;
  btnRowUp.Hint := 'Subir fila';
  btnRowUp.ShowHint := True;
  btnRowUp.Visible := False;

  btnRowDown := TLabel.Create(pnlHeader); btnRowDown.Parent := pnlHeader;
  btnRowDown.Anchors := [akTop, akRight];
  btnRowDown.SetBounds(pnlHeader.ClientWidth - 195, 8, 24, 24);
  btnRowDown.Caption := #$25BC;
  btnRowDown.Font.Size := 12;
  btnRowDown.Font.Color := $00555555;
  btnRowDown.Cursor := crHandPoint;
  btnRowDown.OnClick := DoRowDown;
  btnRowDown.Hint := 'Bajar fila';
  btnRowDown.ShowHint := True;
  btnRowDown.Visible := False;

  btnRowDel := TLabel.Create(pnlHeader); btnRowDel.Parent := pnlHeader;
  btnRowDel.Anchors := [akTop, akRight];
  btnRowDel.SetBounds(pnlHeader.ClientWidth - 165, 8, 24, 24);
  btnRowDel.Caption := #$2716;
  btnRowDel.Font.Size := 14;
  btnRowDel.Font.Color := $004040FF;
  btnRowDel.Cursor := crHandPoint;
  btnRowDel.OnClick := DoRowDel;
  btnRowDel.Hint := 'Eliminar fila';
  btnRowDel.ShowHint := True;
  btnRowDel.Visible := False;

  btnAddElem := TLabel.Create(pnlHeader); btnAddElem.Parent := pnlHeader;
  btnAddElem.Anchors := [akTop, akRight];
  btnAddElem.SetBounds(pnlHeader.ClientWidth - 36, 6, 28, 28);
  btnAddElem.Caption := #$2795;
  btnAddElem.Font.Size := 14;
  btnAddElem.Font.Style := [fsBold];
  btnAddElem.Font.Color := $0040A040;
  btnAddElem.Cursor := crHandPoint;
  btnAddElem.Hint := 'Afegir element';
  btnAddElem.ShowHint := True;
  btnAddElem.OnClick := DoAddElement;

  pnlElements := TScrollBox.Create(Self); pnlElements.Parent := Self;
  pnlElements.Align := alClient;
  pnlElements.BevelInner := bvNone;
  pnlElements.BevelOuter := bvNone;
  pnlElements.BorderStyle := bsNone;
  pnlElements.Color := $00F5F0EB;
  pnlElements.ParentBackground := False;
  pnlElements.VertScrollBar.Tracking := True;

  pnlHeader.OnClick := HandleRowSelectClick;
  lblRowTitle.OnClick := HandleRowSelectClick;

  ApplyVisualState;
  RebuildElements;
end;

destructor TNodeRowPanel.Destroy;
begin
  FElementCards.Free;
  inherited;
end;

procedure TNodeRowPanel.DoRowUp(Sender: TObject);
begin
  if Assigned(FOnMoveUp) then FOnMoveUp(Self);
end;

procedure TNodeRowPanel.DoRowDown(Sender: TObject);
begin
  if Assigned(FOnMoveDown) then FOnMoveDown(Self);
end;

procedure TNodeRowPanel.DoRowDel(Sender: TObject);
begin
  if Assigned(FOnDelete) then FOnDelete(Self);
end;

procedure TNodeRowPanel.HandleRowSelectClick(Sender: TObject);
begin
  if Assigned(FOnSelect) then FOnSelect(Self);
end;

procedure TNodeRowPanel.SetSelected(AValue: Boolean);
begin
  if FSelected = AValue then Exit;
  FSelected := AValue;
  ApplyVisualState;
end;

procedure TNodeRowPanel.ApplyVisualState;
begin
  if pnlHeader = nil then Exit;
  if FSelected then
  begin
    pnlHeader.Color := $00FFD8B0;
    Color := $00FFF5E8;
  end
  else
  begin
    pnlHeader.Color := $00E8E0D8;
    Color := $00F5F0EB;
  end;
  if btnRowUp <> nil then btnRowUp.Visible := FSelected;
  if btnRowDown <> nil then btnRowDown.Visible := FSelected;
  if btnRowDel <> nil then btnRowDel.Visible := FSelected;
  if HandleAllocated then Invalidate;
  if pnlHeader.HandleAllocated then pnlHeader.Invalidate;
end;

procedure TNodeRowPanel.HandleElemSelect(Sender: TObject);
begin
  if Assigned(FOnElemSelect) then FOnElemSelect(Sender);
end;

procedure TNodeRowPanel.RebuildElements;
var
  I, Y: Integer;
  EC: TNodeElementCard;
begin
  for I := FElementCards.Count - 1 downto 0 do
    FElementCards[I].Free;
  FElementCards.Clear;

  Y := 4;
  for I := 0 to High(FRow.Elements) do
  begin
    EC := TNodeElementCard.Create(pnlElements, FRowIdx, I, FRow.Elements[I]);
    EC.Parent := pnlElements;
    EC.SetBounds(4, Y, pnlElements.Width - 24, 42);
    EC.Anchors := [akLeft, akTop, akRight];

    EC.CustomFieldDefs := FCustomFieldDefs;
    EC.OnChanged := HandleElemChanged;
    EC.OnDelete := HandleElemDelete;
    EC.OnSelect := HandleElemSelect;
    EC.OnMoveUp := HandleElemMoveUp;
    EC.OnMoveDown := HandleElemMoveDown;

    FElementCards.Add(EC);
    Y := Y + 46;
  end;

  RecalcHeight;
end;

procedure TNodeRowPanel.RecalcHeight;
var
  ElemH: Integer;
begin
  ElemH := FElementCards.Count * 46 + 12;
  Height := 36 + Max(ElemH, 54);

  if (Parent <> nil) and (Parent is TScrollBox) then
    Parent.Realign;
end;

procedure TNodeRowPanel.HandleElemChanged(Sender: TObject);
var
  Card: TNodeElementCard;
begin
  Card := Sender as TNodeElementCard;
  FRow.Elements[Card.ElemIdx] := Card.Element;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TNodeRowPanel.HandleElemDelete(Sender: TObject);
var
  Card: TNodeElementCard;
  Idx, J, K: Integer;
  NewElems: TArray<TNodeCardElement>;
begin
  Card := Sender as TNodeElementCard;
  Idx := Card.ElemIdx;
  SetLength(NewElems, Length(FRow.Elements) - 1);
  J := 0;
  for K := 0 to High(FRow.Elements) do
    if K <> Idx then
    begin
      NewElems[J] := FRow.Elements[K];
      Inc(J);
    end;
  FRow.Elements := NewElems;
  RebuildElements;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TNodeRowPanel.HandleElemMoveUp(Sender: TObject);
var
  Card: TNodeElementCard;
  Tmp: TNodeCardElement;
  NewIdx: Integer;
begin
  Card := Sender as TNodeElementCard;
  if Card.ElemIdx > 0 then
  begin
    NewIdx := Card.ElemIdx - 1;
    Tmp := FRow.Elements[Card.ElemIdx];
    FRow.Elements[Card.ElemIdx] := FRow.Elements[NewIdx];
    FRow.Elements[NewIdx] := Tmp;
    RebuildElements;
    if Assigned(FOnChanged) then FOnChanged(Self);
    if (NewIdx >= 0) and (NewIdx < FElementCards.Count) then
      if Assigned(FOnElemSelect) then FOnElemSelect(FElementCards[NewIdx]);
  end;
end;

procedure TNodeRowPanel.HandleElemMoveDown(Sender: TObject);
var
  Card: TNodeElementCard;
  Tmp: TNodeCardElement;
  NewIdx: Integer;
begin
  Card := Sender as TNodeElementCard;
  if Card.ElemIdx < High(FRow.Elements) then
  begin
    NewIdx := Card.ElemIdx + 1;
    Tmp := FRow.Elements[Card.ElemIdx];
    FRow.Elements[Card.ElemIdx] := FRow.Elements[NewIdx];
    FRow.Elements[NewIdx] := Tmp;
    RebuildElements;
    if Assigned(FOnChanged) then FOnChanged(Self);
    if (NewIdx >= 0) and (NewIdx < FElementCards.Count) then
      if Assigned(FOnElemSelect) then FOnElemSelect(FElementCards[NewIdx]);
  end;
end;

procedure TNodeRowPanel.DoAddElement(Sender: TObject);
var
  E: TNodeCardElement;
begin
  E := Default(TNodeCardElement);
  E.Kind := ceText;
  E.FieldExpr := '{CodigoArticulo}';
  E.HAlign := chaLeft;
  E.Visible := True;
  // El estilo (tamano/color) lo decide el Gantt; aqui solo contenido.

  if EditNodeElementDialog(TForm(GetParentForm(Self)), E, FCustomFieldDefs) then
  begin
    SetLength(FRow.Elements, Length(FRow.Elements) + 1);
    FRow.Elements[High(FRow.Elements)] := E;
    RebuildElements;
    if Assigned(FOnChanged) then FOnChanged(Self);
  end;
end;

procedure TNodeRowPanel.DoHeightChange(Sender: TObject);
begin
  FRow.HeightPx := seHeight.Value;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

{ ---- TfrmNodeLayoutEditor ---- }

procedure TfrmNodeLayoutEditor.FormCreate(Sender: TObject);
begin
  FRowPanels := TObjectList<TNodeRowPanel>.Create(True);
  FLoadingView := False;
  FUpdatingProps := False;
  FSelectedRow := nil;
  FSelectedElemRow := -1;
  FSelectedElemIdx := -1;
  FCurrentView := gvmNormal;
  FLayoutSet := DefaultNodeLayoutSet;
  boxRows.DoubleBuffered := True;
  BuildSampleData;
  BuildPropsGrid;
  PopulateVistas;
  LoadViewIntoUI(FCurrentView);
  THelpViewer.InstallHelp(Self, 'uNodeLayoutEditor', 'Dise'#241'ador de Nodos');
end;

procedure TfrmNodeLayoutEditor.PopulateVistas;
var
  V: TGanttViewMode;
  Idx: Integer;
begin
  FLoadingView := True;
  try
    cmbVista.Items.Clear;
    SetLength(FViews, Ord(High(TGanttViewMode)) - Ord(Low(TGanttViewMode)) + 1);
    Idx := 0;
    for V := Low(TGanttViewMode) to High(TGanttViewMode) do
    begin
      cmbVista.Items.Add(GanttViewModeCaption(V));
      FViews[Idx] := V;
      Inc(Idx);
    end;
    cmbVista.ItemIndex := Ord(FCurrentView) - Ord(Low(TGanttViewMode));
  finally
    FLoadingView := False;
  end;
end;

procedure TfrmNodeLayoutEditor.CommitCurrentLayout;
begin
  FLayoutSet.Layouts[FCurrentView] := FLayout;
end;

procedure TfrmNodeLayoutEditor.LoadViewIntoUI(V: TGanttViewMode);
begin
  FCurrentView := V;
  FLayout := FLayoutSet.Layouts[V];
  BuildSampleDataFor(V);
  LayoutToUI;
end;

procedure TfrmNodeLayoutEditor.cmbVistaChange(Sender: TObject);
var
  NewView: TGanttViewMode;
begin
  if FLoadingView then Exit;
  if cmbVista.ItemIndex < 0 then Exit;
  if cmbVista.ItemIndex > High(FViews) then Exit;
  NewView := FViews[cmbVista.ItemIndex];
  if NewView = FCurrentView then Exit;
  CommitCurrentLayout;
  LoadViewIntoUI(NewView);
end;

procedure TfrmNodeLayoutEditor.SetLayoutSet(const ASet: TNodeLayoutSet);
begin
  FLayoutSet := ASet;
  LoadViewIntoUI(FCurrentView);
end;

function TfrmNodeLayoutEditor.GetLayoutSet: TNodeLayoutSet;
begin
  CommitCurrentLayout;
  Result := FLayoutSet;
end;

procedure TfrmNodeLayoutEditor.SetDisplayName(const ANombre: string;
  AIsCommon: Boolean);
var
  S: string;
begin
  if Trim(ANombre) = '' then
    S := ''
  else
  begin
    S := ANombre;
    if AIsCommon then S := S + '  [com'#250'n]'
    else S := S + '  [privado]';
  end;
  if Assigned(lblSetName) then
  begin
    lblSetName.Caption := S;
    lblSetName.AutoSize := True;
  end;
end;

procedure TfrmNodeLayoutEditor.FormDestroy(Sender: TObject);
begin
  FRowPanels.Free;
end;

procedure TfrmNodeLayoutEditor.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then ModalResult := mrCancel;
end;

procedure TfrmNodeLayoutEditor.LayoutToUI;
begin
  FUpdatingProps := True;
  try
    FRowName.Properties.Value := FLayout.Name;
  finally
    FUpdatingProps := False;
  end;
  RebuildRowPanels;
  RefreshPreview;
end;

procedure TfrmNodeLayoutEditor.RebuildRowPanels;
var
  I, Y: Integer;
  RP: TNodeRowPanel;
  Redrawing: Boolean;
begin
  FSelectedRow := nil;
  FSelectedElemRow := -1;
  FSelectedElemIdx := -1;

  Redrawing := boxRows.HandleAllocated;
  if Redrawing then
    SendMessage(boxRows.Handle, WM_SETREDRAW, 0, 0);
  boxRows.DisableAlign;
  try
    FRowPanels.Clear;
    Y := 4;
    for I := 0 to High(FLayout.Rows) do
    begin
      RP := TNodeRowPanel.Create(boxRows, I, FLayout.Rows[I]);
      RP.Parent := boxRows;
      RP.SetBounds(4, Y, boxRows.ClientWidth - 24, RP.Height);
      RP.Anchors := [akLeft, akTop, akRight];
      RP.CustomFieldDefs := FCustomFieldDefs;
      RP.OnChanged := OnRowChanged;
      RP.OnSelect := HandleRowSelected;
      RP.OnElemSelect := HandleElemSelected;
      RP.OnDelete := HandleRowDeleted;
      RP.OnMoveUp := HandleRowMoveUp;
      RP.OnMoveDown := HandleRowMoveDown;
      FRowPanels.Add(RP);
      Y := Y + RP.Height + 8;
    end;
  finally
    boxRows.EnableAlign;
    if Redrawing then
    begin
      SendMessage(boxRows.Handle, WM_SETREDRAW, 1, 0);
      RedrawWindow(boxRows.Handle, nil, 0,
        RDW_INVALIDATE or RDW_ALLCHILDREN or RDW_ERASE or RDW_UPDATENOW);
    end;
  end;
end;

procedure TfrmNodeLayoutEditor.RestoreSelection(ARowIdx, AElemIdx: Integer);
var
  RP: TNodeRowPanel;
  EC: TNodeElementCard;
begin
  if (ARowIdx < 0) or (ARowIdx >= FRowPanels.Count) then Exit;
  RP := FRowPanels[ARowIdx];
  if AElemIdx < 0 then
  begin
    ClearAllSelections;
    RP.Selected := True;
    FSelectedRow := RP;
  end
  else if (AElemIdx >= 0) and (AElemIdx < RP.ElementCards.Count) then
  begin
    ClearAllSelections;
    EC := RP.ElementCards[AElemIdx];
    EC.Selected := True;
    FSelectedElemRow := ARowIdx;
    FSelectedElemIdx := AElemIdx;
  end;
  RefreshPreview;
end;

procedure TfrmNodeLayoutEditor.RepositionRowPanels;
var
  I, Y: Integer;
begin
  boxRows.DisableAlign;
  try
    Y := 4;
    for I := 0 to FRowPanels.Count - 1 do
    begin
      FRowPanels[I].Top := Y;
      FRowPanels[I].Height := 36 + Max(Length(FRowPanels[I].Row.Elements) * 46 + 12, 54);
      Y := Y + FRowPanels[I].Height + 8;
    end;
  finally
    boxRows.EnableAlign;
  end;
end;

procedure TfrmNodeLayoutEditor.OnRowChanged(Sender: TObject);
var
  RP: TNodeRowPanel;
begin
  RP := Sender as TNodeRowPanel;
  FLayout.Rows[RP.RowIdx] := RP.Row;
  RepositionRowPanels;
  RefreshPreview;
end;

procedure TfrmNodeLayoutEditor.HandleRowMoveUp(Sender: TObject);
var
  Idx: Integer;
  Tmp: TNodeCardRow;
begin
  if not (Sender is TNodeRowPanel) then Exit;
  Idx := TNodeRowPanel(Sender).RowIdx;
  if Idx <= 0 then Exit;
  Tmp := FLayout.Rows[Idx];
  FLayout.Rows[Idx] := FLayout.Rows[Idx - 1];
  FLayout.Rows[Idx - 1] := Tmp;
  RebuildRowPanels;
  RestoreSelection(Idx - 1, -1);
end;

procedure TfrmNodeLayoutEditor.HandleRowMoveDown(Sender: TObject);
var
  Idx: Integer;
  Tmp: TNodeCardRow;
begin
  if not (Sender is TNodeRowPanel) then Exit;
  Idx := TNodeRowPanel(Sender).RowIdx;
  if Idx >= High(FLayout.Rows) then Exit;
  Tmp := FLayout.Rows[Idx];
  FLayout.Rows[Idx] := FLayout.Rows[Idx + 1];
  FLayout.Rows[Idx + 1] := Tmp;
  RebuildRowPanels;
  RestoreSelection(Idx + 1, -1);
end;

procedure TfrmNodeLayoutEditor.HandleRowDeleted(Sender: TObject);
var
  Idx, I: Integer;
  NewRows: TArray<TNodeCardRow>;
begin
  if not (Sender is TNodeRowPanel) then Exit;
  Idx := TNodeRowPanel(Sender).RowIdx;
  if (Idx < 0) or (Idx > High(FLayout.Rows)) then Exit;
  SetLength(NewRows, Length(FLayout.Rows) - 1);
  for I := 0 to High(FLayout.Rows) do
    if I < Idx then NewRows[I] := FLayout.Rows[I]
    else if I > Idx then NewRows[I - 1] := FLayout.Rows[I];
  FLayout.Rows := NewRows;
  RebuildRowPanels;
  RefreshPreview;
end;

procedure TfrmNodeLayoutEditor.RefreshPreview;
begin
  pbPreview.Invalidate;
end;

function TfrmNodeLayoutEditor.PreviewHeightPx: Integer;
begin
  // El nodo del Gantt es bajo y ancho: simulamos una barra de altura fija.
  Result := 64;
end;

procedure TfrmNodeLayoutEditor.pbPreviewPaint(Sender: TObject);
var
  R, HiR: TRect;
  CardLayout: TCardLayout;
  Resolver: TCardFieldResolver;
  HiRowIdx, HiElemIdx: Integer;
  RowY, I: Integer;
  AvailW, X, ElemW, FixedW, AutoCount, Spacing: Integer;
  Row: TNodeCardRow;
  HasHighlight: Boolean;
  H: Integer;
  BarBg: TColor;
begin
  // Fondo (simula la pista del Gantt)
  pbPreview.Canvas.Brush.Color := $00F0EDE8;
  pbPreview.Canvas.FillRect(pbPreview.ClientRect);

  // Convierte el node layout a card layout para reutilizar RenderCard.
  H := PreviewHeightPx;
  CardLayout := NodeLayoutToCardLayout(FLayout, H);

  // Area del nodo: baja y ancha, centrada verticalmente.
  R.Left := 10;
  R.Right := pbPreview.Width - 10;
  R.Top := (pbPreview.Height - H) div 2;
  if R.Top < 10 then R.Top := 10;
  R.Bottom := R.Top + H;
  if R.Bottom > pbPreview.Height - 10 then
    R.Bottom := pbPreview.Height - 10;

  // Fondo del nodo: la preview muestra COMO lo pintara el Gantt, NO lo que el
  // usuario elija. El color sale del ESTADO de la muestra (igual que en runtime
  // hara el GanttControl); el layout no aporta color ni borde aqui.
  case FSampleData.Estado of
    nePendiente:   BarBg := $00C8C8C8;  // gris
    neEnCurso:     BarBg := $0060C0F0;  // ambar/azul "en curso"
    neFinalizado:  BarBg := $0070C070;  // verde
    neBloqueado:   BarBg := $004040E0;  // rojo
  else
    BarBg := $00E8D8C0;
  end;
  pbPreview.Canvas.Brush.Color := BarBg;
  pbPreview.Canvas.Pen.Color := $00808080;
  pbPreview.Canvas.Pen.Width := 1;
  pbPreview.Canvas.Pen.Style := psSolid;
  // Radio fijo de muestra (el real lo decide el Gantt).
  pbPreview.Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 6, 6);

  // Render con el layout convertido.
  Resolver := MakeNodeDataResolver(FSampleData);
  RenderCard(pbPreview.Canvas, R, CardLayout, Resolver);

  // ---- Marc d'edicio: fila seleccionada o element seleccionat ----
  HiRowIdx := -1; HiElemIdx := -1;
  if FSelectedRow <> nil then
    HiRowIdx := FSelectedRow.RowIdx;
  if FSelectedElemRow >= 0 then
  begin
    HiRowIdx := FSelectedElemRow;
    HiElemIdx := FSelectedElemIdx;
  end;
  HasHighlight := (HiRowIdx >= 0) and (HiRowIdx <= High(FLayout.Rows));
  if not HasHighlight then Exit;

  RowY := R.Top + FLayout.PaddingV;
  for I := 0 to HiRowIdx - 1 do
    RowY := RowY + FLayout.Rows[I].HeightPx;
  Row := FLayout.Rows[HiRowIdx];

  HiR.Top := RowY - 1;
  HiR.Bottom := RowY + Row.HeightPx + 1;

  if HiElemIdx < 0 then
  begin
    HiR.Left := R.Left + FLayout.PaddingH - 1;
    HiR.Right := R.Right - FLayout.PaddingH + 1;
  end
  else
  begin
    AvailW := (R.Right - R.Left) - FLayout.PaddingH * 2;
    Spacing := Row.Spacing;
    if Spacing <= 0 then Spacing := 4;
    FixedW := 0; AutoCount := 0;
    for I := 0 to High(Row.Elements) do
    begin
      if not Row.Elements[I].Visible then Continue;
      if Row.Elements[I].WidthPct > 0 then
        FixedW := FixedW + MulDiv(AvailW, Row.Elements[I].WidthPct, 100) + Spacing
      else
        Inc(AutoCount);
    end;
    X := R.Left + FLayout.PaddingH;
    for I := 0 to High(Row.Elements) do
    begin
      if not Row.Elements[I].Visible then
      begin
        if I = HiElemIdx then Break;
        Continue;
      end;
      if Row.Elements[I].WidthPct > 0 then
        ElemW := MulDiv(AvailW, Row.Elements[I].WidthPct, 100)
      else if AutoCount > 0 then
        ElemW := Max(20, (AvailW - FixedW) div AutoCount)
      else
        ElemW := AvailW;
      if I = HiElemIdx then
      begin
        HiR.Left := X - 1;
        HiR.Right := X + ElemW + 1;
        Break;
      end;
      X := X + ElemW + Spacing;
    end;
  end;

  pbPreview.Canvas.Brush.Style := bsClear;
  pbPreview.Canvas.Pen.Color := $00FF8000;
  pbPreview.Canvas.Pen.Width := 2;
  pbPreview.Canvas.Pen.Style := psSolid;
  pbPreview.Canvas.Rectangle(HiR);
  pbPreview.Canvas.Pen.Width := 1;
end;

procedure TfrmNodeLayoutEditor.btnAddRowClick(Sender: TObject);
var
  NewRow: TNodeCardRow;
begin
  NewRow := Default(TNodeCardRow);
  NewRow.HeightPx := 16;
  NewRow.Spacing := 4;
  SetLength(FLayout.Rows, Length(FLayout.Rows) + 1);
  FLayout.Rows[High(FLayout.Rows)] := NewRow;
  RebuildRowPanels;
  RefreshPreview;
end;

procedure TfrmNodeLayoutEditor.btnDelRowClick(Sender: TObject);
var
  I: Integer;
  NewRows: TArray<TNodeCardRow>;
begin
  if Length(FLayout.Rows) = 0 then Exit;
  SetLength(NewRows, Length(FLayout.Rows) - 1);
  for I := 0 to High(NewRows) do
    NewRows[I] := FLayout.Rows[I];
  FLayout.Rows := NewRows;
  RebuildRowPanels;
  RefreshPreview;
end;

procedure TfrmNodeLayoutEditor.btnAceptarClick(Sender: TObject);
begin
  CommitCurrentLayout;
  ModalResult := mrOk;
end;

procedure TfrmNodeLayoutEditor.ClearAllSelections;
var
  I, J: Integer;
  RP: TNodeRowPanel;
begin
  for I := 0 to FRowPanels.Count - 1 do
  begin
    RP := FRowPanels[I];
    RP.Selected := False;
    for J := 0 to RP.ElementCards.Count - 1 do
      RP.ElementCards[J].Selected := False;
  end;
  FSelectedRow := nil;
  FSelectedElemRow := -1;
  FSelectedElemIdx := -1;
end;

procedure TfrmNodeLayoutEditor.HandleRowSelected(Sender: TObject);
var
  RP: TNodeRowPanel;
  WasSelected: Boolean;
begin
  RP := Sender as TNodeRowPanel;
  WasSelected := RP.Selected;
  ClearAllSelections;
  if not WasSelected then
  begin
    RP.Selected := True;
    FSelectedRow := RP;
  end;
  RefreshPreview;
end;

procedure TfrmNodeLayoutEditor.HandleElemSelected(Sender: TObject);
var
  EC: TNodeElementCard;
  WasSelected: Boolean;
begin
  EC := Sender as TNodeElementCard;
  WasSelected := EC.Selected;
  ClearAllSelections;
  if not WasSelected then
  begin
    EC.Selected := True;
    FSelectedElemRow := EC.RowIdx;
    FSelectedElemIdx := EC.ElemIdx;
  end;
  RefreshPreview;
end;

procedure TfrmNodeLayoutEditor.BuildPropsGrid;

  function AddTextRow(const ACaption, AValue: string;
    AReadOnly: Boolean = False): TcxEditorRow;
  begin
    Result := vgProps.Add(TcxEditorRow) as TcxEditorRow;
    Result.Properties.Caption := ACaption;
    Result.Properties.EditPropertiesClassName := 'TcxTextEditProperties';
    Result.Properties.Value := AValue;
    (Result.Properties.EditProperties as TcxTextEditProperties).ReadOnly := AReadOnly;
    (Result.Properties.EditProperties as TcxTextEditProperties).ImmediatePost := True;
    Result.Properties.EditProperties.OnEditValueChanged := HandlePropChanged;
    if AReadOnly then
      Result.Styles.Content := vgProps.Styles.Category;
  end;

begin
  // Las propiedades de ESTILO del nodo (tamano, colores, borde, padding, fuente)
  // NO se editan aqui: las decide el GanttControl en tiempo de render segun el
  // estado del nodo. Este editor solo define CONTENIDO (que campos y como se
  // disponen en filas). Por eso el panel solo muestra el nombre (informativo) y
  // una nota aclaratoria.
  vgProps.BeginUpdate;
  try
    vgProps.ClearRows;
    FRowName := AddTextRow('Nombre', '', True);
    AddTextRow('Estilo',
      'Tama'#241'o y colores los aplica el Gantt seg'#250'n el estado del nodo.', True);
  finally
    vgProps.EndUpdate;
  end;
end;

procedure TfrmNodeLayoutEditor.HandlePropChanged(Sender: TObject);
begin
  if FUpdatingProps then Exit;
  // Las filas del panel son informativas (read-only): el unico estado real que
  // edita este formulario son las filas y elementos del nodo. No hay nada que
  // volcar a FLayout desde aqui; solo refrescamos la vista previa por si acaso.
  RefreshPreview;
end;

{ ---- Punto de entrada ---- }

function ShowNodeLayoutEditor(AOwner: TForm; ARepo: TNodeLayoutSetRepo): Boolean;
var
  F: TfrmNodeLayoutEditor;
  ASet: TNodeLayoutSet;
  ANombre: string;
  AIsCommon: Boolean;
  ActiveId, NewId: Integer;
begin
  Result := False;
  if ARepo = nil then Exit;

  ARepo.SeedDefaultIfEmpty;
  ActiveId := ARepo.LoadActive(ASet, ANombre, AIsCommon);

  F := TfrmNodeLayoutEditor.Create(AOwner);
  try
    F.LayoutSet := ASet;
    F.SetDisplayName(ANombre, AIsCommon);
    if F.ShowModal <> mrOk then Exit;
    ASet := F.LayoutSet;
  finally
    F.Free;
  end;

  // Persistencia (Fase 1, simplificada):
  //  - Set privado existente -> UpdateSet sobre el mismo id.
  //  - Set comun o de sistema (o sin activo) -> Insert de uno privado nuevo
  //    'Personalizado' y marcarlo como activo, para no pisar el comun/sistema.
  if (ActiveId > 0) and (not AIsCommon) then
    ARepo.UpdateSet(ActiveId, IfThen(Trim(ANombre) = '', 'Personalizado', ANombre), ASet)
  else
  begin
    NewId := ARepo.Insert('Personalizado', False, ASet);
    if NewId > 0 then
      ARepo.SetActiveSetId(NewId)
    else if ActiveId > 0 then
      // No hay usuario para crear privado (Insert fallo): caemos a actualizar
      // el set comun/sistema activo.
      ARepo.UpdateSet(ActiveId, IfThen(Trim(ANombre) = '', 'Por defecto (sistema)', ANombre), ASet);
  end;

  Result := True;
end;

end.
