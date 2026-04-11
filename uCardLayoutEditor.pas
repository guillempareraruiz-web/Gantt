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
  uGanttTypes, uCardLayout, uCustomFieldDefs;

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
    FCustomFieldDefs: TCustomFieldDefs;

    // Controles internos
    lblKind: TLabel;
    lblExpr: TLabel;
    btnEdit: TLabel;
    btnDel: TLabel;
    lblDragHandle: TLabel;

    // Drag
    FDragStartPt: TPoint;
    FDragPending: Boolean;

    procedure DoEdit(Sender: TObject);
    procedure DoDel(Sender: TObject);
    procedure HandleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HandleMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure HandleMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
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
    property CustomFieldDefs: TCustomFieldDefs read FCustomFieldDefs write FCustomFieldDefs;
  end;

  // Panel que representa una fila (columna Trello)
  TRowPanel = class(TPanel)
  private
    FRowIdx: Integer;
    FRow: TCardRow;
    pnlHeader: TPanel;
    lblRowTitle: TLabel;
    lblDragHandle: TLabel;
    lblHeight: TLabel;
    seHeight: TSpinEdit;
    btnAddElem: TButton;
    pnlElements: TScrollBox;
    FElementCards: TList<TElementCard>;
    FOnChanged: TNotifyEvent;
    FCustomFieldDefs: TCustomFieldDefs;

    // Drag de fila
    FDragStartPt: TPoint;
    FDragPending: Boolean;

    procedure DoAddElement(Sender: TObject);
    procedure DoHeightChange(Sender: TObject);
    procedure HandleElemChanged(Sender: TObject);
    procedure HandleElemDelete(Sender: TObject);
    procedure HandleElemMoveUp(Sender: TObject);
    procedure HandleElemMoveDown(Sender: TObject);
    // Drag de elementos dentro de la fila
    procedure ElemDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure ElemDragDrop(Sender, Source: TObject; X, Y: Integer);
    // Drag de fila (header)
    procedure HeaderMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HeaderMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure HeaderMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  public
    constructor Create(AOwner: TComponent; ARowIdx: Integer;
      const ARow: TCardRow); reintroduce;
    destructor Destroy; override;
    procedure RebuildElements;
    procedure RecalcHeight;
    property Row: TCardRow read FRow write FRow;
    property RowIdx: Integer read FRowIdx write FRowIdx;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property CustomFieldDefs: TCustomFieldDefs read FCustomFieldDefs write FCustomFieldDefs;
  end;

  TfrmCardLayoutEditor = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    lblTemplate: TLabel;
    cmbTemplate: TComboBox;
    btnApplyTemplate: TButton;
    pnlFooter: TPanel;
    btnAceptar: TButton;
    btnCancelar: TButton;
    btnCargar: TButton;
    btnGuardar: TButton;
    btnDefecto: TButton;
    pnlMain: TPanel;
    splitter: TSplitter;
    pnlLeft: TPanel;
    pnlRowsHeader: TPanel;
    lblRows: TLabel;
    btnAddRow: TButton;
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
    lblLayoutName: TLabel;
    lblCardHeight: TLabel;
    lblPaddingH: TLabel;
    lblPaddingV: TLabel;
    lblCornerR: TLabel;
    edtName: TEdit;
    seCardHeight: TSpinEdit;
    sePaddingH: TSpinEdit;
    sePaddingV: TSpinEdit;
    seCornerRadius: TSpinEdit;
    dlgOpen: TOpenDialog;
    dlgSave: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pbPreviewPaint(Sender: TObject);
    procedure btnAddRowClick(Sender: TObject);
    procedure btnDelRowClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCargarClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnDefectoClick(Sender: TObject);
    procedure cmbTemplateChange(Sender: TObject);
    procedure btnApplyTemplateClick(Sender: TObject);
    procedure edtNameChange(Sender: TObject);
    procedure seCardHeightChange(Sender: TObject);
    procedure sePaddingHChange(Sender: TObject);
    procedure sePaddingVChange(Sender: TObject);
    procedure seCornerRadiusChange(Sender: TObject);
  private
    FLayout: TCardLayout;
    FRowPanels: TObjectList<TRowPanel>;
    FSampleData: TNodeData;
    FCustomFieldDefs: TCustomFieldDefs;
    FTemplates: TArray<TCardLayout>;

    procedure BuildSampleData;
    procedure RebuildRowPanels;
    procedure RepositionRowPanels;
    procedure RefreshPreview;
    procedure OnRowChanged(Sender: TObject);
    // Drag & drop de files
    procedure RowDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure RowDragDrop(Sender, Source: TObject; X, Y: Integer);
  public
    procedure LayoutToUI;
    property Layout: TCardLayout read FLayout write FLayout;
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
  FDragPending := False;

  Width := 560;
  Height := 42;
  BevelOuter := bvNone;
  Color := clWhite;
  ParentBackground := False;
  Cursor := crDefault;

  // Drag handle (icona de grip)
  lblDragHandle := TLabel.Create(Self); lblDragHandle.Parent := Self;
  lblDragHandle.SetBounds(4, 4, 16, 34);
  lblDragHandle.Caption := #$2261;  // hamburger icon
  lblDragHandle.Font.Size := 14;
  lblDragHandle.Font.Color := $00BBBBBB;
  lblDragHandle.Cursor := crSizeAll;
  lblDragHandle.OnMouseDown := HandleMouseDown;
  lblDragHandle.OnMouseMove := HandleMouseMove;
  lblDragHandle.OnMouseUp := HandleMouseUp;

  // Kind label
  lblKind := TLabel.Create(Self); lblKind.Parent := Self;
  lblKind.SetBounds(24, 4, 60, 15);
  lblKind.Font.Style := [fsBold];
  lblKind.Font.Color := $00FF8000;
  lblKind.Font.Size := 8;

  // Expr label
  lblExpr := TLabel.Create(Self); lblExpr.Parent := Self;
  lblExpr.SetBounds(24, 22, 380, 15);
  lblExpr.Font.Color := $00666666;
  lblExpr.Font.Size := 8;
  lblExpr.EllipsisPosition := epEndEllipsis;
  lblExpr.AutoSize := False;
  lblExpr.Width := 380;

  // Iconos editar / borrar
  btnEdit := TLabel.Create(Self); btnEdit.Parent := Self;
  btnEdit.SetBounds(450, 8, 24, 24);
  btnEdit.Caption := #$270E;  // pencil icon
  btnEdit.Font.Size := 14;
  btnEdit.Font.Color := $00FF8000;
  btnEdit.Cursor := crHandPoint;
  btnEdit.OnClick := DoEdit;
  btnEdit.Hint := 'Editar elemento';
  btnEdit.ShowHint := True;

  btnDel := TLabel.Create(Self); btnDel.Parent := Self;
  btnDel.SetBounds(480, 8, 24, 24);
  btnDel.Caption := #$2716;  // X icon
  btnDel.Font.Size := 14;
  btnDel.Font.Color := $004040FF;
  btnDel.Cursor := crHandPoint;
  btnDel.OnClick := DoDel;
  btnDel.Hint := 'Eliminar elemento';
  btnDel.ShowHint := True;

  UpdateFrom(AElem);
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

procedure TElementCard.HandleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FDragPending := True;
    FDragStartPt := lblDragHandle.ClientToScreen(Point(X, Y));
  end;
end;

procedure TElementCard.HandleMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  Pt: TPoint;
begin
  if FDragPending and (ssLeft in Shift) then
  begin
    Pt := lblDragHandle.ClientToScreen(Point(X, Y));
    if (Abs(Pt.X - FDragStartPt.X) > 4) or (Abs(Pt.Y - FDragStartPt.Y) > 4) then
    begin
      FDragPending := False;
      Self.BeginDrag(False, 0);
    end;
  end;
end;

procedure TElementCard.HandleMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FDragPending := False;
end;

{ ---- TRowPanel ---- }

constructor TRowPanel.Create(AOwner: TComponent; ARowIdx: Integer;
  const ARow: TCardRow);
begin
  inherited Create(AOwner);
  FRowIdx := ARowIdx;
  FRow := ARow;
  FElementCards := TList<TElementCard>.Create;
  FDragPending := False;

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

  // Drag handle per moure la fila
  lblDragHandle := TLabel.Create(pnlHeader); lblDragHandle.Parent := pnlHeader;
  lblDragHandle.SetBounds(4, 4, 20, 28);
  lblDragHandle.Caption := #$2261;  // hamburger icon
  lblDragHandle.Font.Size := 16;
  lblDragHandle.Font.Color := $00999999;
  lblDragHandle.Cursor := crSizeAll;
  lblDragHandle.OnMouseDown := HeaderMouseDown;
  lblDragHandle.OnMouseMove := HeaderMouseMove;
  lblDragHandle.OnMouseUp := HeaderMouseUp;

  lblRowTitle := TLabel.Create(pnlHeader); lblRowTitle.Parent := pnlHeader;
  lblRowTitle.SetBounds(28, 8, 80, 17);
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

  btnAddElem := TButton.Create(pnlHeader); btnAddElem.Parent := pnlHeader;
  btnAddElem.SetBounds(480, 5, 90, 24);
  btnAddElem.Caption := '+ Elemento';
  btnAddElem.OnClick := DoAddElement;

  // Elements container (scrollable, accepta drag & drop)
  pnlElements := TScrollBox.Create(Self); pnlElements.Parent := Self;
  pnlElements.Align := alClient;
  pnlElements.BevelInner := bvNone;
  pnlElements.BevelOuter := bvNone;
  pnlElements.BorderStyle := bsNone;
  pnlElements.Color := $00F5F0EB;
  pnlElements.ParentBackground := False;
  pnlElements.VertScrollBar.Tracking := True;
  pnlElements.OnDragOver := ElemDragOver;
  pnlElements.OnDragDrop := ElemDragDrop;

  RebuildElements;
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
begin
  Card := Sender as TElementCard;
  if Card.ElemIdx > 0 then
  begin
    Tmp := FRow.Elements[Card.ElemIdx];
    FRow.Elements[Card.ElemIdx] := FRow.Elements[Card.ElemIdx - 1];
    FRow.Elements[Card.ElemIdx - 1] := Tmp;
    RebuildElements;
    if Assigned(FOnChanged) then FOnChanged(Self);
  end;
end;

procedure TRowPanel.HandleElemMoveDown(Sender: TObject);
var
  Card: TElementCard;
  Tmp: TCardElement;
begin
  Card := Sender as TElementCard;
  if Card.ElemIdx < High(FRow.Elements) then
  begin
    Tmp := FRow.Elements[Card.ElemIdx];
    FRow.Elements[Card.ElemIdx] := FRow.Elements[Card.ElemIdx + 1];
    FRow.Elements[Card.ElemIdx + 1] := Tmp;
    RebuildElements;
    if Assigned(FOnChanged) then FOnChanged(Self);
  end;
end;

{ -- Drag & drop d'elements dins la fila -- }

procedure TRowPanel.ElemDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Accept := Source is TElementCard;
end;

procedure TRowPanel.ElemDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  SrcCard: TElementCard;
  SrcIdx, DstIdx, I: Integer;
  Tmp: TCardElement;
  LocalPt: TPoint;
begin
  if not (Source is TElementCard) then Exit;
  SrcCard := TElementCard(Source);
  SrcIdx := SrcCard.ElemIdx;

  // Determinar posicio destí per Y
  LocalPt := pnlElements.ScreenToClient(
    TControl(Sender).ClientToScreen(Point(0, Y)));
  DstIdx := (LocalPt.Y + pnlElements.VertScrollBar.Position) div 46;
  if DstIdx < 0 then DstIdx := 0;
  if DstIdx > High(FRow.Elements) then DstIdx := High(FRow.Elements);

  if DstIdx = SrcIdx then Exit;

  // Moure element
  Tmp := FRow.Elements[SrcIdx];
  if DstIdx > SrcIdx then
  begin
    for I := SrcIdx to DstIdx - 1 do
      FRow.Elements[I] := FRow.Elements[I + 1];
  end
  else
  begin
    for I := SrcIdx downto DstIdx + 1 do
      FRow.Elements[I] := FRow.Elements[I - 1];
  end;
  FRow.Elements[DstIdx] := Tmp;

  RebuildElements;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

{ -- Drag de fila (header) -- }

procedure TRowPanel.HeaderMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FDragPending := True;
    FDragStartPt := lblDragHandle.ClientToScreen(Point(X, Y));
  end;
end;

procedure TRowPanel.HeaderMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  Pt: TPoint;
begin
  if FDragPending and (ssLeft in Shift) then
  begin
    Pt := lblDragHandle.ClientToScreen(Point(X, Y));
    if (Abs(Pt.X - FDragStartPt.X) > 4) or (Abs(Pt.Y - FDragStartPt.Y) > 4) then
    begin
      FDragPending := False;
      Self.BeginDrag(False, 0);
    end;
  end;
end;

procedure TRowPanel.HeaderMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FDragPending := False;
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
var
  I: Integer;
begin
  FRowPanels := TObjectList<TRowPanel>.Create(True);
  BuildSampleData;

  // Cargar plantillas predefinidas
  FTemplates := GetAllTemplateLayouts;
  cmbTemplate.Items.Clear;
  for I := 0 to High(FTemplates) do
    cmbTemplate.Items.Add(FTemplates[I].Name);
  if cmbTemplate.Items.Count > 0 then
    cmbTemplate.ItemIndex := 0;
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
begin
  edtName.Text := FLayout.Name;
  seCardHeight.Value := FLayout.CardHeight;
  sePaddingH.Value := FLayout.PaddingH;
  sePaddingV.Value := FLayout.PaddingV;
  seCornerRadius.Value := FLayout.CornerRadius;
  RebuildRowPanels;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.RebuildRowPanels;
var
  I, Y: Integer;
  RP: TRowPanel;
begin
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
    FRowPanels.Add(RP);
    Y := Y + RP.Height + 8;
  end;

  // Configurar D&D de files al boxRows
  boxRows.OnDragOver := RowDragOver;
  boxRows.OnDragDrop := RowDragDrop;
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

{ -- Drag & drop de files -- }

procedure TfrmCardLayoutEditor.RowDragOver(Sender, Source: TObject;
  X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := Source is TRowPanel;
end;

procedure TfrmCardLayoutEditor.RowDragDrop(Sender, Source: TObject;
  X, Y: Integer);
var
  SrcPanel: TRowPanel;
  SrcIdx, DstIdx, I: Integer;
  Tmp: TCardRow;
  LocalPt: TPoint;
  AccH: Integer;
begin
  if not (Source is TRowPanel) then Exit;
  SrcPanel := TRowPanel(Source);
  SrcIdx := SrcPanel.RowIdx;

  // Determinar posicio destí per Y
  LocalPt := boxRows.ScreenToClient(
    TControl(Sender).ClientToScreen(Point(0, Y)));
  // Trobar la fila destí acumulant altures
  DstIdx := 0;
  AccH := 4;
  for I := 0 to FRowPanels.Count - 1 do
  begin
    AccH := AccH + FRowPanels[I].Height + 8;
    if LocalPt.Y + boxRows.VertScrollBar.Position < AccH then
    begin
      DstIdx := I;
      Break;
    end;
    DstIdx := I;
  end;
  if DstIdx > High(FLayout.Rows) then DstIdx := High(FLayout.Rows);

  if DstIdx = SrcIdx then Exit;

  // Moure fila dins el layout
  Tmp := FLayout.Rows[SrcIdx];
  if DstIdx > SrcIdx then
  begin
    for I := SrcIdx to DstIdx - 1 do
      FLayout.Rows[I] := FLayout.Rows[I + 1];
  end
  else
  begin
    for I := SrcIdx downto DstIdx + 1 do
      FLayout.Rows[I] := FLayout.Rows[I - 1];
  end;
  FLayout.Rows[DstIdx] := Tmp;

  RebuildRowPanels;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.RefreshPreview;
begin
  pbPreview.Invalidate;
end;

procedure TfrmCardLayoutEditor.pbPreviewPaint(Sender: TObject);
var
  R: TRect;
  Resolver: TCardFieldResolver;
begin
  // Fondo
  pbPreview.Canvas.Brush.Color := $00F0EDE8;
  pbPreview.Canvas.FillRect(pbPreview.ClientRect);

  // Card area
  R := Rect(10, 10, pbPreview.Width - 10, 10 + FLayout.CardHeight);
  if R.Bottom > pbPreview.Height - 10 then
    R.Bottom := pbPreview.Height - 10;

  // Card background
  pbPreview.Canvas.Brush.Color := clWhite;
  pbPreview.Canvas.Pen.Color := $00E0E0E0;
  pbPreview.Canvas.Pen.Width := 1;
  pbPreview.Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom,
    FLayout.CornerRadius, FLayout.CornerRadius);

  // Render con el layout
  Resolver := MakeNodeDataResolver(FSampleData);
  RenderCard(pbPreview.Canvas, R, FLayout, Resolver);
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
  ModalResult := mrOk;
end;

procedure TfrmCardLayoutEditor.btnCargarClick(Sender: TObject);
begin
  if dlgOpen.Execute then
  begin
    try
      FLayout := LoadCardLayoutFromFile(dlgOpen.FileName);
      LayoutToUI;
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
      SaveCardLayoutToFile(FLayout, dlgSave.FileName);
    except
      on E: Exception do
        MessageDlg('Error al guardar: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmCardLayoutEditor.btnDefectoClick(Sender: TObject);
begin
  FLayout := DefaultCardLayout;
  LayoutToUI;
end;

procedure TfrmCardLayoutEditor.cmbTemplateChange(Sender: TObject);
begin
  // Solo cambia la seleccion, no aplica hasta pulsar el boton
end;

procedure TfrmCardLayoutEditor.btnApplyTemplateClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := cmbTemplate.ItemIndex;
  if (Idx < 0) or (Idx > High(FTemplates)) then Exit;
  FLayout := FTemplates[Idx];
  LayoutToUI;
end;

procedure TfrmCardLayoutEditor.edtNameChange(Sender: TObject);
begin
  FLayout.Name := edtName.Text;
end;

procedure TfrmCardLayoutEditor.seCardHeightChange(Sender: TObject);
begin
  FLayout.CardHeight := seCardHeight.Value;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.sePaddingHChange(Sender: TObject);
begin
  FLayout.PaddingH := sePaddingH.Value;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.sePaddingVChange(Sender: TObject);
begin
  FLayout.PaddingV := sePaddingV.Value;
  RefreshPreview;
end;

procedure TfrmCardLayoutEditor.seCornerRadiusChange(Sender: TObject);
begin
  FLayout.CornerRadius := seCornerRadius.Value;
  RefreshPreview;
end;

end.
