unit uCardLayoutEditor;

{
  TfrmCardLayoutEditor - Editor visual de Card Layout estilo Trello.

  Parte izquierda: filas del card como "columnas Trello" horizontales, cada una
  con sus elementos como "tarjetas" arrastrables.
  Parte derecha: preview en tiempo real + propiedades globales del layout.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.Math, System.Variants,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Samples.Spin, Vcl.Menus,
  cxVGrid, cxInplaceContainer, cxControls, cxEdit, cxTextEdit,
  cxSpinEdit, cxColorComboBox, cxContainer, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters,
  uGanttTypes, uCardLayout, uCustomFieldDefs, uCardLayoutSetRepo, uDragGhost,
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
  TElementCard = class(TPanel)
  private
    FRowIdx: Integer;
    FElemIdx: Integer;
    FElement: TCardElement;
    FOnChanged: TNotifyEvent;
    FOnDelete: TNotifyEvent;
    FOnMoveUp: TNotifyEvent;
    FOnMoveDown: TNotifyEvent;
    FOnSelect: TNotifyEvent;
    FCustomFieldDefs: TCustomFieldDefs;
    FSelected: Boolean;


    // Controles internos
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
      const AElem: TCardElement); reintroduce;
    procedure UpdateFrom(const AElem: TCardElement);
    property Element: TCardElement read FElement;
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
  TRowPanel = class(TPanel)
  private
    FRowIdx: Integer;
    FRow: TCardRow;
    pnlHeader: TPanel;
    lblRowTitle: TLabel;
    lblHeight: TLabel;
    seHeight: TSpinEdit;
    btnAddElem: TLabel;
    btnRowUp: TLabel;
    btnRowDown: TLabel;
    btnRowDel: TLabel;
    pnlElements: TScrollBox;
    FElementCards: TList<TElementCard>;
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
      const ARow: TCardRow); reintroduce;
    destructor Destroy; override;
    procedure RebuildElements;
    procedure RecalcHeight;
    property Row: TCardRow read FRow write FRow;
    property RowIdx: Integer read FRowIdx write FRowIdx;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
    property OnElemSelect: TNotifyEvent read FOnElemSelect write FOnElemSelect;
    property OnDelete: TNotifyEvent read FOnDelete write FOnDelete;
    property OnMoveUp: TNotifyEvent read FOnMoveUp write FOnMoveUp;
    property OnMoveDown: TNotifyEvent read FOnMoveDown write FOnMoveDown;
    property Selected: Boolean read FSelected write SetSelected;
    property ElementCards: TList<TElementCard> read FElementCards;
    property CustomFieldDefs: TCustomFieldDefs read FCustomFieldDefs write FCustomFieldDefs;
  end;

  TfrmCardLayoutEditor = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    lblSetName: TLabel;
    lblCategoria: TLabel;
    cmbCategoria: TComboBox;

    pnlFooter: TPanel;
    btnAceptar: TButton;
    btnCancelar: TButton;
    btnCargar: TButton;
    btnGuardar: TButton;
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
    dlgOpen: TOpenDialog;
    dlgSave: TSaveDialog;
    procedure cmbCategoriaChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pbPreviewPaint(Sender: TObject);
    procedure btnAddRowClick(Sender: TObject);
    procedure btnDelRowClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCargarClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
  private
    FLayout: TCardLayout;
    FRowPanels: TObjectList<TRowPanel>;
    FSampleData: TNodeData;
    FCustomFieldDefs: TCustomFieldDefs;
    FLayoutSet: TCardLayoutSet;
    FCurrentCategory: TCardCategory;
    FLoadingCategory: Boolean;
    FUpdatingProps: Boolean;
    FSelectedRow: TRowPanel;       // fila seleccionada (nil = cap)
    FSelectedElemRow: Integer;     // row idx de l'element seleccionat (-1 = cap)
    FSelectedElemIdx: Integer;     // col idx dins la fila

    // Rows del cxVerticalGrid de propietats
    FRowName: TcxEditorRow;
    FRowCardHeight: TcxEditorRow;
    FRowPaddingH: TcxEditorRow;
    FRowPaddingV: TcxEditorRow;
    FRowCornerRadius: TcxEditorRow;
    FRowBgColor: TcxEditorRow;
    FRowBorderColor: TcxEditorRow;
    FRowBorderWidth: TcxEditorRow;

    procedure HandleRowSelected(Sender: TObject);
    procedure HandleElemSelected(Sender: TObject);
    procedure HandleRowDeleted(Sender: TObject);
    procedure HandleRowMoveUp(Sender: TObject);
    procedure HandleRowMoveDown(Sender: TObject);
    procedure ClearAllSelections;

    procedure BuildPropsGrid;
    procedure HandlePropChanged(Sender: TObject);

    procedure BuildSampleData;
    procedure BuildSampleDataFor(C: TCardCategory);
    procedure RebuildRowPanels;
    procedure RestoreSelection(ARowIdx, AElemIdx: Integer);
    procedure RepositionRowPanels;
    procedure RefreshPreview;
    procedure OnRowChanged(Sender: TObject);
    procedure PopulateCategorias;
    procedure CommitCurrentLayout;
    procedure LoadCategoryIntoUI(C: TCardCategory);
  public
    procedure LayoutToUI;
    procedure SetLayoutSet(const ASet: TCardLayoutSet);
    function GetLayoutSet: TCardLayoutSet;
    procedure SetDisplayName(const ANombre: string; AIsCommon: Boolean);
    property Layout: TCardLayout read FLayout write FLayout;
    property LayoutSet: TCardLayoutSet read GetLayoutSet write SetLayoutSet;
    property CustomFieldDefs: TCustomFieldDefs read FCustomFieldDefs write FCustomFieldDefs;
  end;

// Obtener lista de campos disponibles de TNodeData + CustomFields
function GetAvailableFields(ACustomFieldDefs: TCustomFieldDefs = nil): TArray<string>;

type
  // Form auxiliar para editar un elemento
  TfrmEditElement = class(TForm)
  private
    cmbFields: TComboBox;
    edtExpr: TEdit;
    procedure DoInsertField(Sender: TObject);
  end;

// Dialogo para editar un elemento individual
function EditElementDialog(AOwner: TForm; var AElem: TCardElement;
  ACustomFieldDefs: TCustomFieldDefs = nil): Boolean;

implementation

{$R *.dfm}

{ ---- Campos disponibles ---- }

function GetAvailableFields(ACustomFieldDefs: TCustomFieldDefs): TArray<string>;
var
  Base: TArray<string>;
  I, Cnt: Integer;
begin
  Base := TArray<string>.Create(
    'DataId',
    'Operacion',
    'NumeroPedido',
    'SeriePedido',
    'NumeroOrdenFabricacion',
    'SerieFabricacion',
    'NumeroTrabajo',
    'FechaEntrega',
    'FechaNecesaria',
    'CodigoCliente',
    'CodigoColor',
    'CodigoTalla',
    'Stock',
    'CodigoArticulo',
    'DescripcionArticulo',
    'PorcentajeDependencia',
    'UnidadesFabricadas',
    'UnidadesAFabricar',
    'DurationMin',
    'OperariosNecesarios',
    'OperariosAsignados',
    'Estado',
    'Prioridad',
    'Tipo'
  );

  // Afegir camps personalizats
  if Assigned(ACustomFieldDefs) and (ACustomFieldDefs.Count > 0) then
  begin
    Cnt := Length(Base);
    SetLength(Base, Cnt + ACustomFieldDefs.Count);
    for I := 0 to ACustomFieldDefs.Count - 1 do
      Base[Cnt + I] := ACustomFieldDefs.GetDef(I).FieldName;
  end;

  Result := Base;
end;

{ ---- Datos de ejemplo ---- }

procedure TfrmCardLayoutEditor.BuildSampleData;
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

procedure TfrmCardLayoutEditor.BuildSampleDataFor(C: TCardCategory);
begin
  BuildSampleData;
  case C of
    ccOFPend, ccOFPlan:
      FSampleData.Tipo := ntOF;
    ccPedPend, ccPedPlan:
      FSampleData.Tipo := ntPedido;
    ccProyPend, ccProyPlan:
      FSampleData.Tipo := ntProyecto;
  end;
  case C of
    ccOFPend, ccPedPend, ccProyPend:
      FSampleData.Estado := nePendiente;
  else
    FSampleData.Estado := neEnCurso;
  end;
end;

{ ---- Dialogo de edicion de elemento ---- }

{ TfrmEditElement }

procedure TfrmEditElement.DoInsertField(Sender: TObject);
begin
  if cmbFields.ItemIndex >= 0 then
    edtExpr.Text := edtExpr.Text + '{' + cmbFields.Items[cmbFields.ItemIndex] + '}';
end;

function EditElementDialog(AOwner: TForm; var AElem: TCardElement;
  ACustomFieldDefs: TCustomFieldDefs = nil): Boolean;
var
  Dlg: TfrmEditElement;
  lblKind, lblExpr, lblFontSize, lblFontColor, lblBgColor,
  lblBgColorField, lblAlign, lblWidth, lblCondition, lblRadius: TLabel;
  cmbKind: TComboBox;
  seFontSize: TSpinEdit;
  chkBold, chkItalic, chkVisible: TCheckBox;
  cmbAlign: TComboBox;
  seWidth: TSpinEdit;
  edtCondition: TEdit;
  edtBgColorField: TEdit;
  seRadius: TSpinEdit;
  btnOk, btnCancel: TButton;
  btnInsertField: TButton;
  Fields: TArray<string>;
  I, Y: Integer;
begin
  Result := False;
  Dlg := TfrmEditElement.CreateNew(AOwner);
  try
    Dlg.Caption := 'Editar Elemento';
    Dlg.ClientWidth := 440;
    Dlg.ClientHeight := 400;
    Dlg.Position := poOwnerFormCenter;
    Dlg.BorderStyle := bsDialog;
    Dlg.Font.Name := 'Segoe UI';
    Dlg.Font.Size := 9;

    Y := 12;

    // Tipo
    lblKind := TLabel.Create(Dlg); lblKind.Parent := Dlg;
    lblKind.SetBounds(12, Y, 80, 15); lblKind.Caption := 'Tipo:';
    cmbKind := TComboBox.Create(Dlg); cmbKind.Parent := Dlg;
    cmbKind.Style := csDropDownList;
    cmbKind.SetBounds(100, Y - 2, 120, 23);
    cmbKind.Items.AddStrings(['Texto', 'Badge', 'Barra progreso', 'Espaciador']);
    case AElem.Kind of
      ceText: cmbKind.ItemIndex := 0;
      ceBadge: cmbKind.ItemIndex := 1;
      ceProgressBar: cmbKind.ItemIndex := 2;
      ceSpacer: cmbKind.ItemIndex := 3;
    end;
    Inc(Y, 30);

    // Expresion
    lblExpr := TLabel.Create(Dlg); lblExpr.Parent := Dlg;
    lblExpr.SetBounds(12, Y, 80, 15); lblExpr.Caption := 'Expresi'#243'n:';
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
    Dlg.cmbFields.ItemIndex := 0;
    btnInsertField := TButton.Create(Dlg); btnInsertField.Parent := Dlg;
    btnInsertField.SetBounds(310, Y - 2, 116, 23);
    btnInsertField.Caption := 'Insertar {Campo}';
    btnInsertField.OnClick := Dlg.DoInsertField;
    Inc(Y, 34);

    // Font size
    lblFontSize := TLabel.Create(Dlg); lblFontSize.Parent := Dlg;
    lblFontSize.SetBounds(12, Y, 80, 15); lblFontSize.Caption := 'Tama'#241'o font:';
    seFontSize := TSpinEdit.Create(Dlg); seFontSize.Parent := Dlg;
    seFontSize.SetBounds(100, Y - 2, 60, 23);
    seFontSize.MinValue := 5; seFontSize.MaxValue := 24;
    seFontSize.Value := AElem.FontSize;
    if seFontSize.Value < 5 then seFontSize.Value := 8;

    chkBold := TCheckBox.Create(Dlg); chkBold.Parent := Dlg;
    chkBold.SetBounds(180, Y, 70, 20); chkBold.Caption := 'Negrita';
    chkBold.Checked := AElem.FontBold;

    chkItalic := TCheckBox.Create(Dlg); chkItalic.Parent := Dlg;
    chkItalic.SetBounds(260, Y, 70, 20); chkItalic.Caption := 'Cursiva';
    chkItalic.Checked := AElem.FontItalic;
    Inc(Y, 30);

    // Alineacion
    lblAlign := TLabel.Create(Dlg); lblAlign.Parent := Dlg;
    lblAlign.SetBounds(12, Y, 80, 15); lblAlign.Caption := 'Alineaci'#243'n:';
    cmbAlign := TComboBox.Create(Dlg); cmbAlign.Parent := Dlg;
    cmbAlign.Style := csDropDownList;
    cmbAlign.SetBounds(100, Y - 2, 120, 23);
    cmbAlign.Items.AddStrings(['Izquierda', 'Centro', 'Derecha']);
    cmbAlign.ItemIndex := Ord(AElem.HAlign);
    Inc(Y, 30);

    // Ancho %
    lblWidth := TLabel.Create(Dlg); lblWidth.Parent := Dlg;
    lblWidth.SetBounds(12, Y, 80, 15); lblWidth.Caption := 'Ancho %:';
    seWidth := TSpinEdit.Create(Dlg); seWidth.Parent := Dlg;
    seWidth.SetBounds(100, Y - 2, 60, 23);
    seWidth.MinValue := 0; seWidth.MaxValue := 100;
    seWidth.Value := AElem.WidthPct;
    Inc(Y, 30);

    // BgColorField
    lblBgColorField := TLabel.Create(Dlg); lblBgColorField.Parent := Dlg;
    lblBgColorField.SetBounds(12, Y, 85, 15); lblBgColorField.Caption := 'Color campo:';
    edtBgColorField := TEdit.Create(Dlg); edtBgColorField.Parent := Dlg;
    edtBgColorField.SetBounds(100, Y - 2, 120, 23);
    edtBgColorField.Text := AElem.BgColorField;
    Inc(Y, 30);

    // Condicion
    lblCondition := TLabel.Create(Dlg); lblCondition.Parent := Dlg;
    lblCondition.SetBounds(12, Y, 80, 15); lblCondition.Caption := 'Condici'#243'n:';
    edtCondition := TEdit.Create(Dlg); edtCondition.Parent := Dlg;
    edtCondition.SetBounds(100, Y - 2, 120, 23);
    edtCondition.Text := AElem.ConditionField;

    // Radio
    lblRadius := TLabel.Create(Dlg); lblRadius.Parent := Dlg;
    lblRadius.SetBounds(240, Y, 60, 15); lblRadius.Caption := 'Radio:';
    seRadius := TSpinEdit.Create(Dlg); seRadius.Parent := Dlg;
    seRadius.SetBounds(300, Y - 2, 50, 23);
    seRadius.MinValue := 0; seRadius.MaxValue := 20;
    seRadius.Value := AElem.RoundRadius;
    Inc(Y, 30);

    // Visible
    chkVisible := TCheckBox.Create(Dlg); chkVisible.Parent := Dlg;
    chkVisible.SetBounds(12, Y, 80, 20); chkVisible.Caption := 'Visible';
    chkVisible.Checked := AElem.Visible;
    Inc(Y, 34);

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

    if Dlg.ShowModal = mrOk then
    begin
      case cmbKind.ItemIndex of
        0: AElem.Kind := ceText;
        1: AElem.Kind := ceBadge;
        2: AElem.Kind := ceProgressBar;
        3: AElem.Kind := ceSpacer;
      end;
      AElem.FieldExpr := Dlg.edtExpr.Text;
      AElem.FontSize := seFontSize.Value;
      AElem.FontBold := chkBold.Checked;
      AElem.FontItalic := chkItalic.Checked;
      AElem.FontColor := AElem.FontColor; // se mantiene
      AElem.HAlign := TCardHAlign(cmbAlign.ItemIndex);
      AElem.WidthPct := seWidth.Value;
      AElem.BgColorField := edtBgColorField.Text;
      AElem.ConditionField := edtCondition.Text;
      AElem.RoundRadius := seRadius.Value;
      AElem.Visible := chkVisible.Checked;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ ---- TElementCard ---- }

constructor TElementCard.Create(AOwner: TComponent; ARowIdx, AElemIdx: Integer;
  const AElem: TCardElement);
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

  // Kind label
  lblKind := TLabel.Create(Self); lblKind.Parent := Self;
  lblKind.SetBounds(10, 4, 60, 15);
  lblKind.Font.Style := [fsBold];
  lblKind.Font.Color := $00FF8000;
  lblKind.Font.Size := 8;

  // Expr label
  lblExpr := TLabel.Create(Self); lblExpr.Parent := Self;
  lblExpr.SetBounds(10, 22, 380, 15);
  lblExpr.Font.Color := $00666666;
  lblExpr.Font.Size := 8;
  lblExpr.EllipsisPosition := epEndEllipsis;
  lblExpr.AutoSize := False;
  lblExpr.Width := 380;

  // Botons d'accio (nomes visibles quan la card esta seleccionada)
  // Up / Down per reordenar
  btnUp := TLabel.Create(Self); btnUp.Parent := Self;
  btnUp.SetBounds(390, 8, 24, 24);
  btnUp.Caption := #$25B2;  // triangle up
  btnUp.Font.Size := 11;
  btnUp.Font.Color := $00555555;
  btnUp.Cursor := crHandPoint;
  btnUp.OnClick := DoUp;
  btnUp.Hint := 'Subir elemento';
  btnUp.ShowHint := True;
  btnUp.Visible := False;

  btnDown := TLabel.Create(Self); btnDown.Parent := Self;
  btnDown.SetBounds(414, 8, 24, 24);
  btnDown.Caption := #$25BC;  // triangle down
  btnDown.Font.Size := 11;
  btnDown.Font.Color := $00555555;
  btnDown.Cursor := crHandPoint;
  btnDown.OnClick := DoDown;
  btnDown.Hint := 'Bajar elemento';
  btnDown.ShowHint := True;
  btnDown.Visible := False;

  btnEdit := TLabel.Create(Self); btnEdit.Parent := Self;
  btnEdit.SetBounds(450, 8, 24, 24);
  btnEdit.Caption := #$270E;  // pencil
  btnEdit.Font.Size := 14;
  btnEdit.Font.Color := $00FF8000;
  btnEdit.Cursor := crHandPoint;
  btnEdit.OnClick := DoEdit;
  btnEdit.Hint := 'Editar elemento';
  btnEdit.ShowHint := True;
  btnEdit.Visible := False;

  btnDel := TLabel.Create(Self); btnDel.Parent := Self;
  btnDel.SetBounds(480, 8, 24, 24);
  btnDel.Caption := #$2716;  // X
  btnDel.Font.Size := 14;
  btnDel.Font.Color := $004040FF;
  btnDel.Cursor := crHandPoint;
  btnDel.OnClick := DoDel;
  btnDel.Hint := 'Eliminar elemento';
  btnDel.ShowHint := True;
  btnDel.Visible := False;

  // Click a la card -> selecciona (toggle al form principal)
  Self.OnClick := HandleSelectClick;
  lblKind.OnClick := HandleSelectClick;
  lblExpr.OnClick := HandleSelectClick;

  ApplyVisualState;
  UpdateFrom(AElem);
end;

procedure TElementCard.HandleSelectClick(Sender: TObject);
begin
  if Assigned(FOnSelect) then FOnSelect(Self);
end;

procedure TElementCard.SetSelected(AValue: Boolean);
begin
  if FSelected = AValue then Exit;
  FSelected := AValue;
  ApplyVisualState;
end;

procedure TElementCard.ApplyVisualState;
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
  // Botons d'accio nomes visibles quan seleccionat
  if btnUp <> nil then btnUp.Visible := FSelected;
  if btnDown <> nil then btnDown.Visible := FSelected;
  if btnEdit <> nil then btnEdit.Visible := FSelected;
  if btnDel <> nil then btnDel.Visible := FSelected;
  if HandleAllocated then Invalidate;
end;

procedure TElementCard.UpdateFrom(const AElem: TCardElement);
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

procedure TElementCard.DoEdit(Sender: TObject);
var
  E: TCardElement;
begin
  E := FElement;
  if EditElementDialog(TForm(GetParentForm(Self)), E, FCustomFieldDefs) then
  begin
    FElement := E;
    UpdateFrom(E);
    if Assigned(FOnChanged) then FOnChanged(Self);
  end;
end;

procedure TElementCard.DoDel(Sender: TObject);
begin
  if Assigned(FOnDelete) then FOnDelete(Self);
end;

procedure TElementCard.DoUp(Sender: TObject);
begin
  if Assigned(FOnMoveUp) then FOnMoveUp(Self);
end;

procedure TElementCard.DoDown(Sender: TObject);
begin
  if Assigned(FOnMoveDown) then FOnMoveDown(Self);
end;


{ ---- TRowPanel ---- }

constructor TRowPanel.Create(AOwner: TComponent; ARowIdx: Integer;
  const ARow: TCardRow);
begin
  inherited Create(AOwner);
  FRowIdx := ARowIdx;
  FRow := ARow;
  FElementCards := TList<TElementCard>.Create;

  // CRITIC: assignar Parent abans de crear fills WinControl.
  // L'AOwner ha de ser un WinControl visible (boxRows). Si no n'es,
  // el caller hara d'assignar Parent despres i el dibuix fallara.
  if AOwner is TWinControl then
    Parent := TWinControl(AOwner);

  Width := 580;
  Height := 200;
  BevelOuter := bvNone;
  Color := $00F5F0EB;
  ParentBackground := False;

  // Header
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

  // Botons de fila (visibles nomes quan seleccionada)
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
  btnAddElem.Caption := #$2795;  // heavy plus sign
  btnAddElem.Font.Size := 14;
  btnAddElem.Font.Style := [fsBold];
  btnAddElem.Font.Color := $0040A040;
  btnAddElem.Cursor := crHandPoint;
  btnAddElem.Hint := 'Afegir element';
  btnAddElem.ShowHint := True;
  btnAddElem.OnClick := DoAddElement;

  // Elements container (scrollable)
  pnlElements := TScrollBox.Create(Self); pnlElements.Parent := Self;
  pnlElements.Align := alClient;
  pnlElements.BevelInner := bvNone;
  pnlElements.BevelOuter := bvNone;
  pnlElements.BorderStyle := bsNone;
  pnlElements.Color := $00F5F0EB;
  pnlElements.ParentBackground := False;
  pnlElements.VertScrollBar.Tracking := True;

  // Click al header (qualsevol lloc fora dels controls) -> selecciona fila
  pnlHeader.OnClick := HandleRowSelectClick;
  lblRowTitle.OnClick := HandleRowSelectClick;

  ApplyVisualState;
  RebuildElements;
end;

procedure TRowPanel.DoRowUp(Sender: TObject);
begin
  if Assigned(FOnMoveUp) then FOnMoveUp(Self);
end;

procedure TRowPanel.DoRowDown(Sender: TObject);
begin
  if Assigned(FOnMoveDown) then FOnMoveDown(Self);
end;

procedure TRowPanel.DoRowDel(Sender: TObject);
begin
  if Assigned(FOnDelete) then FOnDelete(Self);
end;

procedure TRowPanel.HandleRowSelectClick(Sender: TObject);
begin
  if Assigned(FOnSelect) then FOnSelect(Self);
end;

procedure TRowPanel.SetSelected(AValue: Boolean);
begin
  if FSelected = AValue then Exit;
  FSelected := AValue;
  ApplyVisualState;
end;

procedure TRowPanel.ApplyVisualState;
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

procedure TRowPanel.HandleElemSelect(Sender: TObject);
begin
  // Reemiteix cap al form principal
  if Assigned(FOnElemSelect) then FOnElemSelect(Sender);
end;

destructor TRowPanel.Destroy;
begin
  FElementCards.Free;
  inherited;
end;

procedure TRowPanel.RebuildElements;
var
  I, Y: Integer;
  EC: TElementCard;
begin
  // Eliminar cards anteriores
  for I := FElementCards.Count - 1 downto 0 do
    FElementCards[I].Free;
  FElementCards.Clear;

  Y := 4;
  for I := 0 to High(FRow.Elements) do
  begin
    EC := TElementCard.Create(pnlElements, FRowIdx, I, FRow.Elements[I]);
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

procedure TRowPanel.RecalcHeight;
var
  ElemH: Integer;
begin
  // header(36) + elements + margin
  ElemH := FElementCards.Count * 46 + 12;
  Height := 36 + Max(ElemH, 54);

  // Forzar re-layout del padre (boxRows)
  if (Parent <> nil) and (Parent is TScrollBox) then
    Parent.Realign;
end;

procedure TRowPanel.HandleElemChanged(Sender: TObject);
var
  Card: TElementCard;
begin
  Card := Sender as TElementCard;
  FRow.Elements[Card.ElemIdx] := Card.Element;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TRowPanel.HandleElemDelete(Sender: TObject);
var
  Card: TElementCard;
  Idx, J, K: Integer;
  NewElems: TArray<TCardElement>;
begin
  Card := Sender as TElementCard;
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

procedure TRowPanel.HandleElemMoveUp(Sender: TObject);
var
  Card: TElementCard;
  Tmp: TCardElement;
  NewIdx: Integer;
begin
  Card := Sender as TElementCard;
  if Card.ElemIdx > 0 then
  begin
    NewIdx := Card.ElemIdx - 1;
    Tmp := FRow.Elements[Card.ElemIdx];
    FRow.Elements[Card.ElemIdx] := FRow.Elements[NewIdx];
    FRow.Elements[NewIdx] := Tmp;
    RebuildElements;
    if Assigned(FOnChanged) then FOnChanged(Self);
    // Re-seleccionar la card a la nova posicio (sense pre-marcar, perque
    // HandleElemSelected del form fa toggle: si ja esta seleccionada,
    // la desseleccionara)
    if (NewIdx >= 0) and (NewIdx < FElementCards.Count) then
      if Assigned(FOnElemSelect) then FOnElemSelect(FElementCards[NewIdx]);
  end;
end;

procedure TRowPanel.HandleElemMoveDown(Sender: TObject);
var
  Card: TElementCard;
  Tmp: TCardElement;
  NewIdx: Integer;
begin
  Card := Sender as TElementCard;
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

procedure TRowPanel.DoAddElement(Sender: TObject);
var
  E: TCardElement;
begin
  E := Default(TCardElement);
  E.Kind := ceText;
  E.FieldExpr := '{CodigoArticulo}';
  E.FontSize := 8;
  E.FontColor := $00333333;
  E.HAlign := chaLeft;
  E.Visible := True;
  E.RoundRadius := 4;

  if EditElementDialog(TForm(GetParentForm(Self)), E, FCustomFieldDefs) then
  begin
    SetLength(FRow.Elements, Length(FRow.Elements) + 1);
    FRow.Elements[High(FRow.Elements)] := E;
    RebuildElements;
    if Assigned(FOnChanged) then FOnChanged(Self);
  end;
end;

procedure TRowPanel.DoHeightChange(Sender: TObject);
begin
  FRow.HeightPx := seHeight.Value;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

{ ---- TfrmCardLayoutEditor ---- }

procedure TfrmCardLayoutEditor.FormCreate(Sender: TObject);
begin
  FRowPanels := TObjectList<TRowPanel>.Create(True);
  FLoadingCategory := False;
  FUpdatingProps := False;
  FSelectedRow := nil;
  FSelectedElemRow := -1;
  FSelectedElemIdx := -1;
  FCurrentCategory := ccOFPend;
  FLayoutSet := DefaultCardLayoutSet;
  BuildSampleData;
  BuildPropsGrid;
  PopulateCategorias;
end;

procedure TfrmCardLayoutEditor.PopulateCategorias;
var
  C: TCardCategory;
begin
  FLoadingCategory := True;
  try
    cmbCategoria.Items.Clear;
    for C := Low(TCardCategory) to High(TCardCategory) do
      cmbCategoria.Items.AddObject(CardCategoryCaption(C), TObject(NativeInt(Ord(C))));
    cmbCategoria.ItemIndex := Ord(FCurrentCategory);
  finally
    FLoadingCategory := False;
  end;
end;

procedure TfrmCardLayoutEditor.CommitCurrentLayout;
begin
  FLayoutSet.Layouts[FCurrentCategory] := FLayout;
end;

procedure TfrmCardLayoutEditor.LoadCategoryIntoUI(C: TCardCategory);
begin
  FCurrentCategory := C;
  FLayout := FLayoutSet.Layouts[C];
  BuildSampleDataFor(C);
  LayoutToUI;
end;

procedure TfrmCardLayoutEditor.cmbCategoriaChange(Sender: TObject);
var
  NewCat: TCardCategory;
begin
  if FLoadingCategory then Exit;
  if cmbCategoria.ItemIndex < 0 then Exit;
  NewCat := TCardCategory(cmbCategoria.ItemIndex);
  if NewCat = FCurrentCategory then Exit;
  CommitCurrentLayout;
  LoadCategoryIntoUI(NewCat);
end;

procedure TfrmCardLayoutEditor.SetLayoutSet(const ASet: TCardLayoutSet);
begin
  FLayoutSet := ASet;
  LoadCategoryIntoUI(FCurrentCategory);
end;

function TfrmCardLayoutEditor.GetLayoutSet: TCardLayoutSet;
begin
  CommitCurrentLayout;
  Result := FLayoutSet;
end;

procedure TfrmCardLayoutEditor.SetDisplayName(const ANombre: string;
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

procedure TfrmCardLayoutEditor.FormDestroy(Sender: TObject);
begin
  FRowPanels.Free;
end;

procedure TfrmCardLayoutEditor.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then ModalResult := mrCancel;
end;

procedure TfrmCardLayoutEditor.LayoutToUI;
var
  BgC, BorC: TColor;
begin
  // Defaults visuals si encara no estan informats
  BgC := FLayout.BgColor;
  if BgC = 0 then BgC := clWhite;
  BorC := FLayout.BorderColor;
  if BorC = 0 then BorC := $00E0E0E0;

  FUpdatingProps := True;
  try
    FRowName.Properties.Value         := FLayout.Name;
    FRowCardHeight.Properties.Value   := FLayout.CardHeight;
    FRowPaddingH.Properties.Value     := FLayout.PaddingH;
    FRowPaddingV.Properties.Value     := FLayout.PaddingV;
    FRowCornerRadius.Properties.Value := FLayout.CornerRadius;
    FRowBgColor.Properties.Value      := BgC;
    FRowBorderColor.Properties.Value  := BorC;
    FRowBorderWidth.Properties.Value  := Max(0, FLayout.BorderWidth);
  finally
    FUpdatingProps := False;
  end;
  RebuildRowPanels;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.RebuildRowPanels;
var
  I, Y: Integer;
  RP: TRowPanel;
begin
  // Invalida punters: els TRowPanel actuals seran destruits
  FSelectedRow := nil;
  FSelectedElemRow := -1;
  FSelectedElemIdx := -1;
  FRowPanels.Clear;
  Y := 4;
  for I := 0 to High(FLayout.Rows) do
  begin
    RP := TRowPanel.Create(boxRows, I, FLayout.Rows[I]);
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

end;

procedure TfrmCardLayoutEditor.RestoreSelection(ARowIdx, AElemIdx: Integer);
var
  RP: TRowPanel;
  EC: TElementCard;
begin
  if (ARowIdx < 0) or (ARowIdx >= FRowPanels.Count) then Exit;
  RP := FRowPanels[ARowIdx];
  if AElemIdx < 0 then
  begin
    // Selecciona la fila
    ClearAllSelections;
    RP.Selected := True;
    FSelectedRow := RP;
  end
  else if (AElemIdx >= 0) and (AElemIdx < RP.ElementCards.Count) then
  begin
    // Selecciona l'element
    ClearAllSelections;
    EC := RP.ElementCards[AElemIdx];
    EC.Selected := True;
    FSelectedElemRow := ARowIdx;
    FSelectedElemIdx := AElemIdx;
  end;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.RepositionRowPanels;
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

procedure TfrmCardLayoutEditor.OnRowChanged(Sender: TObject);
var
  RP: TRowPanel;
begin
  RP := Sender as TRowPanel;
  // Actualizar fila del layout
  FLayout.Rows[RP.RowIdx] := RP.Row;
  // Reposicionar per si ha canviat l'altura
  RepositionRowPanels;
  RefreshPreview;
end;

// ---- Handlers de fletxes / eliminar de fila (cridats per botons de TRowPanel) ----

procedure TfrmCardLayoutEditor.HandleRowMoveUp(Sender: TObject);
var
  Idx: Integer;
  Tmp: TCardRow;
begin
  if not (Sender is TRowPanel) then Exit;
  Idx := TRowPanel(Sender).RowIdx;
  if Idx <= 0 then Exit;
  Tmp := FLayout.Rows[Idx];
  FLayout.Rows[Idx] := FLayout.Rows[Idx - 1];
  FLayout.Rows[Idx - 1] := Tmp;
  RebuildRowPanels;
  RestoreSelection(Idx - 1, -1);
end;

procedure TfrmCardLayoutEditor.HandleRowMoveDown(Sender: TObject);
var
  Idx: Integer;
  Tmp: TCardRow;
begin
  if not (Sender is TRowPanel) then Exit;
  Idx := TRowPanel(Sender).RowIdx;
  if Idx >= High(FLayout.Rows) then Exit;
  Tmp := FLayout.Rows[Idx];
  FLayout.Rows[Idx] := FLayout.Rows[Idx + 1];
  FLayout.Rows[Idx + 1] := Tmp;
  RebuildRowPanels;
  RestoreSelection(Idx + 1, -1);
end;

procedure TfrmCardLayoutEditor.HandleRowDeleted(Sender: TObject);
var
  Idx, I: Integer;
  NewRows: TArray<TCardRow>;
begin
  if not (Sender is TRowPanel) then Exit;
  Idx := TRowPanel(Sender).RowIdx;
  if (Idx < 0) or (Idx > High(FLayout.Rows)) then Exit;
  SetLength(NewRows, Length(FLayout.Rows) - 1);
  for I := 0 to High(FLayout.Rows) do
    if I < Idx then NewRows[I] := FLayout.Rows[I]
    else if I > Idx then NewRows[I - 1] := FLayout.Rows[I];
  FLayout.Rows := NewRows;
  RebuildRowPanels;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.RefreshPreview;
begin
  pbPreview.Invalidate;
end;

procedure TfrmCardLayoutEditor.pbPreviewPaint(Sender: TObject);
var
  R, HiR: TRect;
  Resolver: TCardFieldResolver;
  HiRowIdx, HiElemIdx: Integer;
  RowY, I: Integer;
  AvailW, X, ElemW, FixedW, AutoCount, Spacing: Integer;
  Row: TCardRow;
  HasHighlight: Boolean;
begin
  // Fondo
  pbPreview.Canvas.Brush.Color := $00F0EDE8;
  pbPreview.Canvas.FillRect(pbPreview.ClientRect);

  // Card area
  R := Rect(10, 10, pbPreview.Width - 10, 10 + FLayout.CardHeight);
  if R.Bottom > pbPreview.Height - 10 then
    R.Bottom := pbPreview.Height - 10;

  // Card background (configurable per layout)
  if FLayout.BgColor <> 0 then
    pbPreview.Canvas.Brush.Color := FLayout.BgColor
  else
    pbPreview.Canvas.Brush.Color := clWhite;
  if FLayout.BorderColor <> 0 then
    pbPreview.Canvas.Pen.Color := FLayout.BorderColor
  else
    pbPreview.Canvas.Pen.Color := $00E0E0E0;
  if FLayout.BorderWidth > 0 then
  begin
    pbPreview.Canvas.Pen.Width := FLayout.BorderWidth;
    pbPreview.Canvas.Pen.Style := psSolid;
  end
  else
  begin
    pbPreview.Canvas.Pen.Width := 1;
    pbPreview.Canvas.Pen.Style := psClear;
  end;
  pbPreview.Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom,
    FLayout.CornerRadius, FLayout.CornerRadius);
  pbPreview.Canvas.Pen.Style := psSolid;
  pbPreview.Canvas.Pen.Width := 1;

  // Render con el layout
  Resolver := MakeNodeDataResolver(FSampleData);
  RenderCard(pbPreview.Canvas, R, FLayout, Resolver);

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
    // Marc sobre tota la fila
    HiR.Left := R.Left + FLayout.PaddingH - 1;
    HiR.Right := R.Right - FLayout.PaddingH + 1;
  end
  else
  begin
    // Calcul X+W de l'element (mateix algoritme que RenderCard)
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

procedure TfrmCardLayoutEditor.btnAddRowClick(Sender: TObject);
var
  NewRow: TCardRow;
begin
  NewRow := Default(TCardRow);
  NewRow.HeightPx := 16;
  NewRow.Spacing := 4;
  SetLength(FLayout.Rows, Length(FLayout.Rows) + 1);
  FLayout.Rows[High(FLayout.Rows)] := NewRow;
  RebuildRowPanels;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.btnDelRowClick(Sender: TObject);
var
  I: Integer;
  NewRows: TArray<TCardRow>;
begin
  if Length(FLayout.Rows) = 0 then Exit;
  // Eliminar la ultima fila
  SetLength(NewRows, Length(FLayout.Rows) - 1);
  for I := 0 to High(NewRows) do
    NewRows[I] := FLayout.Rows[I];
  FLayout.Rows := NewRows;
  RebuildRowPanels;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.btnAceptarClick(Sender: TObject);
begin
  CommitCurrentLayout;
  ModalResult := mrOk;
end;

procedure TfrmCardLayoutEditor.btnCargarClick(Sender: TObject);
begin
  if dlgOpen.Execute then
  begin
    try
      // Si el fitxer es un set sencer, carrega tot; si es un layout solt
      // l'apliquem nomes a la categoria actual.
      try
        FLayoutSet := LoadCardLayoutSetFromFile(dlgOpen.FileName);
        LoadCategoryIntoUI(FCurrentCategory);
      except
        FLayout := LoadCardLayoutFromFile(dlgOpen.FileName);
        CommitCurrentLayout;
        LayoutToUI;
      end;
    except
      on E: Exception do
        MessageDlg('Error al cargar: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmCardLayoutEditor.btnGuardarClick(Sender: TObject);
begin
  if dlgSave.Execute then
  begin
    try
      CommitCurrentLayout;
      // Guardamos el set completo (6 categorias) en un solo fichero.
      SaveCardLayoutSetToFile(FLayoutSet, dlgSave.FileName);
    except
      on E: Exception do
        MessageDlg('Error al guardar: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmCardLayoutEditor.ClearAllSelections;
var
  I, J: Integer;
  RP: TRowPanel;
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

procedure TfrmCardLayoutEditor.HandleRowSelected(Sender: TObject);
var
  RP: TRowPanel;
  WasSelected: Boolean;
begin
  RP := Sender as TRowPanel;
  WasSelected := RP.Selected;
  ClearAllSelections;
  if not WasSelected then
  begin
    RP.Selected := True;
    FSelectedRow := RP;
  end;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.HandleElemSelected(Sender: TObject);
var
  EC: TElementCard;
  WasSelected: Boolean;
begin
  EC := Sender as TElementCard;
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

procedure TfrmCardLayoutEditor.BuildPropsGrid;

  function AddTextRow(const ACaption, AValue: string;
    AReadOnly: Boolean = False): TcxEditorRow;
  begin
    Result := vgProps.Add(TcxEditorRow) as TcxEditorRow;
    Result.Properties.Caption := ACaption;
    Result.Properties.EditPropertiesClassName := 'TcxTextEditProperties';
    Result.Properties.Value := AValue;
    (Result.Properties.EditProperties as TcxTextEditProperties).ReadOnly := AReadOnly;
    Result.Properties.EditProperties.OnEditValueChanged := HandlePropChanged;
    if AReadOnly then
      Result.Styles.Content := vgProps.Styles.Category;
  end;

  function AddIntRow(const ACaption: string; AMin, AMax, AValue: Integer): TcxEditorRow;
  var
    P: TcxSpinEditProperties;
  begin
    Result := vgProps.Add(TcxEditorRow) as TcxEditorRow;
    Result.Properties.Caption := ACaption;
    Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
    P := Result.Properties.EditProperties as TcxSpinEditProperties;
    P.ValueType := vtInt;
    P.MinValue := AMin;
    P.MaxValue := AMax;
    Result.Properties.Value := AValue;
    P.OnEditValueChanged := HandlePropChanged;
  end;

  function AddColorRow(const ACaption: string; AValue: TColor): TcxEditorRow;
  var
    P: TcxColorComboBoxProperties;
  begin
    Result := vgProps.Add(TcxEditorRow) as TcxEditorRow;
    Result.Properties.Caption := ACaption;
    Result.Properties.EditPropertiesClassName := 'TcxColorComboBoxProperties';
    P := Result.Properties.EditProperties as TcxColorComboBoxProperties;
    P.AllowSelectColor := True;
    P.ColorDialogType := cxcdtAdvanced;
    Result.Properties.Value := AValue;
    P.OnEditValueChanged := HandlePropChanged;
  end;

begin
  vgProps.BeginUpdate;
  try
    vgProps.ClearRows;
    FRowName         := AddTextRow('Nombre', '', True);
    FRowCardHeight   := AddIntRow('Altura card',     30, 300, 88);
    FRowPaddingH     := AddIntRow('Padding H',        0,  40,  6);
    FRowPaddingV     := AddIntRow('Padding V',        0,  40,  6);
    FRowCornerRadius := AddIntRow('Radio borde',      0,  30,  6);
    FRowBgColor      := AddColorRow('Color fondo',    clWhite);
    FRowBorderColor  := AddColorRow('Color borde',    $00E0E0E0);
    FRowBorderWidth  := AddIntRow('Grosor borde',     0,  10,  1);
  finally
    vgProps.EndUpdate;
  end;
end;

procedure TfrmCardLayoutEditor.HandlePropChanged(Sender: TObject);
begin
  if FUpdatingProps then Exit;
  FLayout.Name         := VarToStr(FRowName.Properties.Value);
  FLayout.CardHeight   := FRowCardHeight.Properties.Value;
  FLayout.PaddingH     := FRowPaddingH.Properties.Value;
  FLayout.PaddingV     := FRowPaddingV.Properties.Value;
  FLayout.CornerRadius := FRowCornerRadius.Properties.Value;
  FLayout.BgColor      := TColor(Integer(FRowBgColor.Properties.Value));
  FLayout.BorderColor  := TColor(Integer(FRowBorderColor.Properties.Value));
  FLayout.BorderWidth  := FRowBorderWidth.Properties.Value;
  RefreshPreview;
end;

end.
