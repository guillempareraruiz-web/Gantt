unit uMarkerEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, System.UITypes, System.Variants,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxStyles, cxVGrid, cxInplaceContainer,
  cxTextEdit, cxSpinEdit, cxCheckBox, cxDropDownEdit, cxCalendar,
  cxDateUtils, cxMaskEdit, cxColorComboBox,
  dxSkinsCore, dxSkinMetropolis, dxSkinOffice2019Colorful,
  dxSkinBasic, dxSkinBlack, dxSkinBlue,
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
  dxScrollbarAnnotations, cxClasses,
  // Project
  uGanttTypes;

type
  TMarkerEditorResult = (merOK, merCancel, merDelete);

  TfrmMarkerEditor = class(TForm)
    vg: TcxVerticalGrid;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    btnDelete: TButton;
    LookAndFeel: TcxLookAndFeelController;
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    chkDarkMode: TCheckBox;
    procedure chkDarkModeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
  private
    FMarker: TGanttMarker;
    FIsNew: Boolean;
    FResult: TMarkerEditorResult;

    // Categories
    FCatGeneral: TcxCategoryRow;
    FCatVisual: TcxCategoryRow;
    FCatComportament: TcxCategoryRow;

    // Rows
    FRowId: TcxEditorRow;
    FRowCaption: TcxEditorRow;
    FRowDateTime: TcxEditorRow;
    FRowTag: TcxEditorRow;
    FRowColor: TcxEditorRow;
    FRowStyle: TcxEditorRow;
    FRowStrokeWidth: TcxEditorRow;
    FRowVisible: TcxEditorRow;
    FRowMoveable: TcxEditorRow;
    // Font
    FCatFont: TcxCategoryRow;
    FRowFontName: TcxEditorRow;
    FRowFontSize: TcxEditorRow;
    FRowFontColor: TcxEditorRow;
    FRowFontBold: TcxEditorRow;
    FRowFontItalic: TcxEditorRow;
    // Text layout
    FCatText: TcxCategoryRow;
    FRowTextOrientation: TcxEditorRow;
    FRowTextAlign: TcxEditorRow;

    procedure BuildRows;
    procedure ApplyToMarker;
    procedure ApplyDarkMode(ADark: Boolean);

    function AddCategory(const ACaption: string): TcxCategoryRow;
    function AddTextRow(AParent: TcxCategoryRow; const ACaption, AValue: string;
      AReadOnly: Boolean = False): TcxEditorRow;
    function AddIntRow(AParent: TcxCategoryRow; const ACaption: string; AValue: Integer;
      AReadOnly: Boolean = False): TcxEditorRow;
    function AddFloatRow(AParent: TcxCategoryRow; const ACaption: string; AValue: Double;
      AReadOnly: Boolean = False): TcxEditorRow;
    function AddBoolRow(AParent: TcxCategoryRow; const ACaption: string; AValue: Boolean;
      AReadOnly: Boolean = False): TcxEditorRow;
    function AddDateRow(AParent: TcxCategoryRow; const ACaption: string; AValue: TDateTime;
      AReadOnly: Boolean = False): TcxEditorRow;
    function AddComboRow(AParent: TcxCategoryRow; const ACaption, AValue: string;
      const AItems: array of string; AReadOnly: Boolean = False): TcxEditorRow;
    function AddColorRow(AParent: TcxCategoryRow; const ACaption: string;
      AValue: TColor; AReadOnly: Boolean = False): TcxEditorRow;

    function GetRowText(ARow: TcxEditorRow): string;
    function GetRowInt(ARow: TcxEditorRow): Integer;
    function GetRowFloat(ARow: TcxEditorRow): Double;
    function GetRowBool(ARow: TcxEditorRow): Boolean;
    function GetRowDate(ARow: TcxEditorRow): TDateTime;
    function GetRowColor(ARow: TcxEditorRow): TColor;

    function StyleToStr(S: TMarkerStyle): string;
    function StrToStyle(const S: string): TMarkerStyle;
    function OrientationToStr(O: TMarkerTextOrientation): string;
    function StrToOrientation(const S: string): TMarkerTextOrientation;
    function AlignToStr(A: TMarkerTextAlign): string;
    function StrToAlign(const S: string): TMarkerTextAlign;
  public
    class function Execute(var AMarker: TGanttMarker; AIsNew: Boolean = False): TMarkerEditorResult;
  end;

var
  frmMarkerEditor: TfrmMarkerEditor;

implementation

{$R *.dfm}

{ ============================================= }
{            Execute (class method)             }
{ ============================================= }

class function TfrmMarkerEditor.Execute(var AMarker: TGanttMarker; AIsNew: Boolean): TMarkerEditorResult;
var
  F: TfrmMarkerEditor;
begin
  F := TfrmMarkerEditor.Create(Application);
  try
    F.FMarker := AMarker;
    F.FIsNew := AIsNew;
    F.FResult := merCancel;

    // Header
    if AIsNew then
    begin
      F.lblTitle.Caption := 'Nuevo Marcador';
      F.lblSubtitle.Caption := 'Crear un nuevo marcador en el Gantt';
      F.btnDelete.Visible := False;
    end
    else
    begin
      F.lblTitle.Caption := 'Marcador: ' + AMarker.Caption;
      F.lblSubtitle.Caption := 'ID ' + AMarker.Id.ToString +
        '  -  ' + FormatDateTime('dd/mm/yyyy hh:nn', AMarker.DateTime);
      F.btnDelete.Visible := True;
    end;

    F.BuildRows;
    F.ShowModal;

    Result := F.FResult;
    if Result = merOK then
      AMarker := F.FMarker;
  finally
    F.Free;
  end;
end;

{ ============================================= }
{               Form events                     }
{ ============================================= }

procedure TfrmMarkerEditor.FormCreate(Sender: TObject);
begin
  //
end;

procedure TfrmMarkerEditor.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    FResult := merCancel;
    ModalResult := mrCancel;
  end;
end;

procedure TfrmMarkerEditor.btnOKClick(Sender: TObject);
begin
  ApplyToMarker;
  FResult := merOK;
  ModalResult := mrOk;
end;

procedure TfrmMarkerEditor.btnCancelClick(Sender: TObject);
begin
  FResult := merCancel;
  ModalResult := mrCancel;
end;

procedure TfrmMarkerEditor.btnDeleteClick(Sender: TObject);
begin
  if MessageDlg('Eliminar este marcador?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FResult := merDelete;
    ModalResult := mrOk;
  end;
end;

{ ============================================= }
{          Row creation helpers                 }
{ ============================================= }

function TfrmMarkerEditor.AddCategory(const ACaption: string): TcxCategoryRow;
begin
  Result := vg.Add(TcxCategoryRow) as TcxCategoryRow;
  Result.Properties.Caption := ACaption;
end;

function TfrmMarkerEditor.AddTextRow(AParent: TcxCategoryRow;
  const ACaption, AValue: string; AReadOnly: Boolean): TcxEditorRow;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxTextEditProperties';
  (Result.Properties.EditProperties as TcxTextEditProperties).ReadOnly := AReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmMarkerEditor.AddIntRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: Integer; AReadOnly: Boolean): TcxEditorRow;
var
  Props: TcxSpinEditProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
  Props := Result.Properties.EditProperties as TcxSpinEditProperties;
  Props.ValueType := vtInt;
  Props.MinValue := -MaxInt;
  Props.MaxValue := MaxInt;
  Props.ReadOnly := AReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmMarkerEditor.AddFloatRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: Double; AReadOnly: Boolean): TcxEditorRow;
var
  Props: TcxSpinEditProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
  Props := Result.Properties.EditProperties as TcxSpinEditProperties;
  Props.ValueType := vtFloat;
  Props.MinValue := 0.1;
  Props.MaxValue := 20.0;
  Props.Increment := 0.5;
  Props.ReadOnly := AReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmMarkerEditor.AddBoolRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: Boolean; AReadOnly: Boolean): TcxEditorRow;
var
  Props: TcxCheckBoxProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxCheckBoxProperties';
  Props := Result.Properties.EditProperties as TcxCheckBoxProperties;
  Props.DisplayChecked := 'S'#237;
  Props.DisplayUnchecked := 'No';
  Props.ReadOnly := AReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmMarkerEditor.AddDateRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: TDateTime; AReadOnly: Boolean): TcxEditorRow;
var
  Props: TcxDateEditProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxDateEditProperties';
  Props := Result.Properties.EditProperties as TcxDateEditProperties;
  Props.ReadOnly := AReadOnly;
  Props.SaveTime := True;
  Props.ShowTime := True;
  Props.DateButtons := [btnNow, btnClear];
  Props.Kind := ckDateTime;
  Result.Properties.Value := AValue;
  if AReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmMarkerEditor.AddComboRow(AParent: TcxCategoryRow;
  const ACaption, AValue: string; const AItems: array of string;
  AReadOnly: Boolean): TcxEditorRow;
var
  Props: TcxComboBoxProperties;
  I: Integer;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxComboBoxProperties';
  Props := Result.Properties.EditProperties as TcxComboBoxProperties;
  Props.DropDownListStyle := lsFixedList;
  Props.ReadOnly := AReadOnly;
  for I := Low(AItems) to High(AItems) do
    Props.Items.Add(AItems[I]);
  Result.Properties.Value := AValue;
  if AReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmMarkerEditor.AddColorRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: TColor; AReadOnly: Boolean): TcxEditorRow;
var
  Props: TcxColorComboBoxProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxColorComboBoxProperties';
  Props := Result.Properties.EditProperties as TcxColorComboBoxProperties;
  Props.AllowSelectColor := True;
  Props.ColorDialogType := cxcdtAdvanced;
  Props.ReadOnly := AReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

{ ============================================= }
{              Build rows                       }
{ ============================================= }

procedure TfrmMarkerEditor.BuildRows;
var
  M: TGanttMarker;
begin
  M := FMarker;
  vg.BeginUpdate;
  try
    vg.ClearRows;

    // -- General --
    FCatGeneral := AddCategory('General');
    FRowId       := AddIntRow(FCatGeneral, 'ID', M.Id, True);
    FRowCaption  := AddTextRow(FCatGeneral, 'Nombre', M.Caption);
    FRowDateTime := AddDateRow(FCatGeneral, 'Fecha / Hora', M.DateTime);
    FRowTag      := AddIntRow(FCatGeneral, 'Tag', M.Tag);

    // -- Visual --
    FCatVisual := AddCategory('Visual');
    FRowColor       := AddColorRow(FCatVisual, 'Color', M.Color);
    FRowStyle       := AddComboRow(FCatVisual, 'Estilo',
      StyleToStr(M.Style), ['L'#237'nea', 'Discontinua', 'Punteada']);
    FRowStrokeWidth := AddFloatRow(FCatVisual, 'Grosor', M.StrokeWidth);
    FRowVisible     := AddBoolRow(FCatVisual, 'Visible', M.Visible);

    // -- Fuente --
    FCatFont := AddCategory('Fuente');
    FRowFontName   := AddTextRow(FCatFont, 'Nombre Fuente', M.FontName);
    FRowFontSize   := AddIntRow(FCatFont, 'Tama'#241'o', M.FontSize);
    FRowFontColor  := AddColorRow(FCatFont, 'Color Texto', M.FontColor);
    FRowFontBold   := AddBoolRow(FCatFont, 'Negrita', fsBold in M.FontStyle);
    FRowFontItalic := AddBoolRow(FCatFont, 'Cursiva', fsItalic in M.FontStyle);

    // -- Texto --
    FCatText := AddCategory('Texto');
    FRowTextOrientation := AddComboRow(FCatText, 'Orientaci'#243'n',
      OrientationToStr(M.TextOrientation), ['Horizontal', 'Vertical']);
    FRowTextAlign := AddComboRow(FCatText, 'Alineaci'#243'n',
      AlignToStr(M.TextAlign), ['Superior', 'Centro', 'Inferior']);

    // -- Comportamiento --
    FCatComportament := AddCategory('Comportamiento');
    FRowMoveable := AddBoolRow(FCatComportament, 'Movible', M.Moveable);

  finally
    vg.EndUpdate;
  end;
end;

{ ============================================= }
{              Value getters                    }
{ ============================================= }

function TfrmMarkerEditor.GetRowText(ARow: TcxEditorRow): string;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := ''
  else
    Result := VarToStr(ARow.Properties.Value);
end;

function TfrmMarkerEditor.GetRowInt(ARow: TcxEditorRow): Integer;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := 0
  else
    Result := ARow.Properties.Value;
end;

function TfrmMarkerEditor.GetRowFloat(ARow: TcxEditorRow): Double;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := 0
  else
    Result := ARow.Properties.Value;
end;

function TfrmMarkerEditor.GetRowBool(ARow: TcxEditorRow): Boolean;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := False
  else
    Result := ARow.Properties.Value;
end;

function TfrmMarkerEditor.GetRowDate(ARow: TcxEditorRow): TDateTime;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := 0
  else
    Result := VarToDateTime(ARow.Properties.Value);
end;

function TfrmMarkerEditor.GetRowColor(ARow: TcxEditorRow): TColor;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := clRed
  else
    Result := ARow.Properties.Value;
end;

{ ============================================= }
{            Style conversion                   }
{ ============================================= }

function TfrmMarkerEditor.StyleToStr(S: TMarkerStyle): string;
begin
  case S of
    msLine:   Result := 'L'#237'nea';
    msDashed: Result := 'Discontinua';
    msDotted: Result := 'Punteada';
  else
    Result := 'L'#237'nea';
  end;
end;

function TfrmMarkerEditor.StrToStyle(const S: string): TMarkerStyle;
begin
  if SameText(S, 'Discontinua') then Result := msDashed
  else if SameText(S, 'Punteada') then Result := msDotted
  else Result := msLine;
end;

function TfrmMarkerEditor.OrientationToStr(O: TMarkerTextOrientation): string;
begin
  case O of
    mtoHorizontal: Result := 'Horizontal';
    mtoVertical:   Result := 'Vertical';
  else
    Result := 'Horizontal';
  end;
end;

function TfrmMarkerEditor.StrToOrientation(const S: string): TMarkerTextOrientation;
begin
  if SameText(S, 'Vertical') then Result := mtoVertical
  else Result := mtoHorizontal;
end;

function TfrmMarkerEditor.AlignToStr(A: TMarkerTextAlign): string;
begin
  case A of
    mtaTop:    Result := 'Superior';
    mtaCenter: Result := 'Centro';
    mtaBottom: Result := 'Inferior';
  else
    Result := 'Superior';
  end;
end;

function TfrmMarkerEditor.StrToAlign(const S: string): TMarkerTextAlign;
begin
  if SameText(S, 'Centro') then Result := mtaCenter
  else if SameText(S, 'Inferior') then Result := mtaBottom
  else Result := mtaTop;
end;

{ ============================================= }
{            Apply to marker                    }
{ ============================================= }

procedure TfrmMarkerEditor.ApplyToMarker;
var
  fs: TFontStyles;
begin
  FMarker.Caption     := GetRowText(FRowCaption);
  FMarker.DateTime    := GetRowDate(FRowDateTime);
  FMarker.Tag         := GetRowInt(FRowTag);
  FMarker.Color       := GetRowColor(FRowColor);
  FMarker.Style       := StrToStyle(GetRowText(FRowStyle));
  FMarker.StrokeWidth := GetRowFloat(FRowStrokeWidth);
  FMarker.Visible     := GetRowBool(FRowVisible);
  FMarker.Moveable    := GetRowBool(FRowMoveable);

  // Font
  FMarker.FontName  := GetRowText(FRowFontName);
  FMarker.FontSize  := GetRowInt(FRowFontSize);
  FMarker.FontColor := GetRowColor(FRowFontColor);
  fs := [];
  if GetRowBool(FRowFontBold) then Include(fs, fsBold);
  if GetRowBool(FRowFontItalic) then Include(fs, fsItalic);
  FMarker.FontStyle := fs;

  // Text layout
  FMarker.TextOrientation := StrToOrientation(GetRowText(FRowTextOrientation));
  FMarker.TextAlign       := StrToAlign(GetRowText(FRowTextAlign));
end;

{ ============================================= }
{             Dark mode                         }
{ ============================================= }

procedure TfrmMarkerEditor.chkDarkModeClick(Sender: TObject);
begin
  ApplyDarkMode(chkDarkMode.Checked);
end;

procedure TfrmMarkerEditor.ApplyDarkMode(ADark: Boolean);
const
  DARK_BG      = $00302C28;
  DARK_HEADER  = $003C3836;
  DARK_TEXT    = $00F0F0F0;
  DARK_SUB     = $00A0A0A0;
  DARK_LINE    = $00504840;
  LIGHT_HEADER = clWhite;
  LIGHT_TITLE  = 4474440;
begin
  if ADark then
  begin
    LookAndFeel.SkinName := 'Office2019Black';
    pnlHeader.Color := DARK_HEADER;
    lblTitle.Font.Color := DARK_TEXT;
    lblSubtitle.Font.Color := DARK_SUB;
    shpHeaderLine.Brush.Color := DARK_LINE;
    chkDarkMode.Font.Color := DARK_TEXT;
    pnlBottom.Color := DARK_HEADER;
    Color := DARK_BG;
  end
  else
  begin
    LookAndFeel.SkinName := 'Office2019Colorful';
    pnlHeader.Color := LIGHT_HEADER;
    lblTitle.Font.Color := LIGHT_TITLE;
    lblSubtitle.Font.Color := clGray;
    shpHeaderLine.Brush.Color := 15061727;
    chkDarkMode.Font.Color := clWindowText;
    pnlBottom.Color := clBtnFace;
    Color := clBtnFace;
  end;
end;

end.
