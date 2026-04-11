unit uCentreInspector;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, System.Variants,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxStyles, cxVGrid, cxInplaceContainer,
  cxTextEdit, cxSpinEdit, cxCheckBox, cxDropDownEdit, cxMaskEdit,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxSkinBasic, dxSkinBlack, dxSkinBlue,
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
  dxSkinXmas2008Blue, cxFilter, dxScrollbarAnnotations, cxClasses,
  // Project
  uGanttTypes, uSampleDataGenerator;

type
  TfrmCentreInspector = class(TForm)
    vg: TcxVerticalGrid;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    LookAndFeel: TcxLookAndFeelController;
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FCentre: TCentreTreball;
    FReadOnly: Boolean;
    FCalNombre: string;
    FCalHorarioLV: string;
    FCalFinSemana: string;
    // Categories
    FCatGeneral: TcxCategoryRow;
    FCatCalendario: TcxCategoryRow;
    FCatLayout: TcxCategoryRow;
    FCatVisual: TcxCategoryRow;
    // Rows
    FRowId: TcxEditorRow;
    FRowCodiCentre: TcxEditorRow;
    FRowTitulo: TcxEditorRow;
    FRowSubtitulo: TcxEditorRow;
    FRowArea: TcxEditorRow;
    FRowIsSequencial: TcxEditorRow;
    FRowMaxLaneCount: TcxEditorRow;
    FRowBaseHeight: TcxEditorRow;
    FRowOrder: TcxEditorRow;
    FRowVisible: TcxEditorRow;
    FRowEnabled: TcxEditorRow;
    FRowBkColor: TcxEditorRow;
    FRowCalNombre: TcxEditorRow;
    FRowCalHorarioLV: TcxEditorRow;
    FRowCalFinSemana: TcxEditorRow;
    procedure BuildRows;
    procedure ApplyToCentre;
    function AddCategory(const ACaption: string): TcxCategoryRow;
    function AddTextRow(AParent: TcxCategoryRow; const ACaption, AValue: string;
      AReadOnly: Boolean = False): TcxEditorRow;
    function AddIntRow(AParent: TcxCategoryRow; const ACaption: string; AValue: Integer;
      AReadOnly: Boolean = False): TcxEditorRow;
    function AddFloatRow(AParent: TcxCategoryRow; const ACaption: string; AValue: Double;
      AReadOnly: Boolean = False): TcxEditorRow;
    function AddBoolRow(AParent: TcxCategoryRow; const ACaption: string; AValue: Boolean;
      AReadOnly: Boolean = False): TcxEditorRow;
    function AddColorRow(AParent: TcxCategoryRow; const ACaption: string; AValue: TColor;
      AReadOnly: Boolean = False): TcxEditorRow;
    function GetRowText(ARow: TcxEditorRow): string;
    function GetRowInt(ARow: TcxEditorRow): Integer;
    function GetRowFloat(ARow: TcxEditorRow): Double;
    function GetRowBool(ARow: TcxEditorRow): Boolean;
  public
    class function Execute(var ACentre: TCentreTreball; AReadOnly: Boolean = False;
      const ACalendario: PSampleCalendario = nil): Boolean;
  end;

implementation

{$R *.dfm}

{ TfrmCentreInspector }

class function TfrmCentreInspector.Execute(var ACentre: TCentreTreball;
  AReadOnly: Boolean; const ACalendario: PSampleCalendario): Boolean;
var
  F: TfrmCentreInspector;
  I: Integer;
  S: string;
begin
  F := TfrmCentreInspector.Create(Application);
  try
    F.FCentre := ACentre;
    F.FReadOnly := AReadOnly;

    // Preparar info del calendario
    if ACalendario <> nil then
    begin
      F.FCalNombre := ACalendario^.Nombre;

      // Construir texto de horario L-V
      if Length(ACalendario^.PeriodosLV) = 0 then
        F.FCalHorarioLV := '24h laborable'
      else
      begin
        S := '';
        for I := 0 to High(ACalendario^.PeriodosLV) do
        begin
          if I > 0 then S := S + ' | ';
          S := S + Format('%02d:%02d-%02d:%02d', [
            ACalendario^.PeriodosLV[I].StartH, ACalendario^.PeriodosLV[I].StartM,
            ACalendario^.PeriodosLV[I].EndH, ACalendario^.PeriodosLV[I].EndM
          ]);
        end;
        F.FCalHorarioLV := 'No laborable: ' + S;
      end;

      if ACalendario^.FinDeSemanaCompleto then
        F.FCalFinSemana := 'Cerrado'
      else
        F.FCalFinSemana := 'Abierto';
    end
    else
    begin
      F.FCalNombre := '(sin calendario)';
      F.FCalHorarioLV := '';
      F.FCalFinSemana := '';
    end;

    // Header
    F.lblTitle.Caption := ACentre.Titulo;
    if ACentre.Subtitulo <> '' then
      F.lblSubtitle.Caption := ACentre.Subtitulo + '  (Id: ' + ACentre.Id.ToString + ')'
    else
      F.lblSubtitle.Caption := 'Id: ' + ACentre.Id.ToString;

    if AReadOnly then
    begin
      F.btnOK.Visible := False;
      F.btnCancel.Caption := 'Cerrar';
    end;

    F.BuildRows;

    Result := F.ShowModal = mrOk;
    if Result then
      ACentre := F.FCentre;
  finally
    F.Free;
  end;
end;

procedure TfrmCentreInspector.FormCreate(Sender: TObject);
begin
  //
end;

procedure TfrmCentreInspector.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

{ --- Row creation helpers --- }

function TfrmCentreInspector.AddCategory(const ACaption: string): TcxCategoryRow;
begin
  Result := vg.Add(TcxCategoryRow) as TcxCategoryRow;
  Result.Properties.Caption := ACaption;
end;

function TfrmCentreInspector.AddTextRow(AParent: TcxCategoryRow;
  const ACaption, AValue: string; AReadOnly: Boolean): TcxEditorRow;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxTextEditProperties';
  (Result.Properties.EditProperties as TcxTextEditProperties).ReadOnly := AReadOnly or FReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly or FReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmCentreInspector.AddIntRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: Integer; AReadOnly: Boolean): TcxEditorRow;
var
  Props: TcxSpinEditProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
  Props := Result.Properties.EditProperties as TcxSpinEditProperties;
  Props.ValueType := vtInt;
  Props.MinValue := 0;
  Props.MaxValue := MaxInt;
  Props.ReadOnly := AReadOnly or FReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly or FReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmCentreInspector.AddFloatRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: Double; AReadOnly: Boolean): TcxEditorRow;
var
  Props: TcxSpinEditProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
  Props := Result.Properties.EditProperties as TcxSpinEditProperties;
  Props.ValueType := vtFloat;
  Props.MinValue := 0;
  Props.MaxValue := 1E18;
  Props.Increment := 1;
  Props.ReadOnly := AReadOnly or FReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly or FReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmCentreInspector.AddBoolRow(AParent: TcxCategoryRow;
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
  Props.ReadOnly := AReadOnly or FReadOnly;
  Result.Properties.Value := AValue;
  if AReadOnly or FReadOnly then
    Result.Styles.Content := vg.Styles.Category;
end;

function TfrmCentreInspector.AddColorRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: TColor; AReadOnly: Boolean): TcxEditorRow;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClassName := 'TcxTextEditProperties';
  (Result.Properties.EditProperties as TcxTextEditProperties).ReadOnly := True;
  Result.Properties.Value := '$' + IntToHex(AValue, 6);
  Result.Styles.Content := vg.Styles.Category;
end;

{ --- Build rows --- }

procedure TfrmCentreInspector.BuildRows;
var
  C: TCentreTreball;
begin
  C := FCentre;
  vg.BeginUpdate;
  try
    vg.ClearRows;

    // ── General ──
    FCatGeneral := AddCategory('General');
    FRowId          := AddIntRow(FCatGeneral, 'Id', C.Id, True);
    FRowCodiCentre  := AddTextRow(FCatGeneral, 'C'#243'digo Centro', C.CodiCentre);
    FRowTitulo      := AddTextRow(FCatGeneral, 'T'#237'tulo', C.Titulo);
    FRowSubtitulo   := AddTextRow(FCatGeneral, 'Subt'#237'tulo', C.Subtitulo);
    FRowArea        := AddTextRow(FCatGeneral, #193'rea', C.Area);

    // ── Calendario ──
    FCatCalendario := AddCategory('Calendario');
    FRowCalNombre    := AddTextRow(FCatCalendario, 'Nombre', FCalNombre, True);
    FRowCalHorarioLV := AddTextRow(FCatCalendario, 'Horario L-V', FCalHorarioLV, True);
    FRowCalFinSemana := AddTextRow(FCatCalendario, 'Fin de Semana', FCalFinSemana, True);

    // ── Layout ──
    FCatLayout := AddCategory('Layout');
    FRowIsSequencial := AddBoolRow(FCatLayout, 'Secuencial', C.IsSequencial);
    FRowMaxLaneCount := AddIntRow(FCatLayout, 'M'#225'x. Lanes (0=sin l'#237'mite)', C.MaxLaneCount);
    FRowBaseHeight   := AddFloatRow(FCatLayout, 'Altura Base (px)', C.BaseHeight);
    FRowOrder        := AddIntRow(FCatLayout, 'Orden', C.Order);

    // ── Visual ──
    FCatVisual := AddCategory('Visual');
    FRowVisible := AddBoolRow(FCatVisual, 'Visible', C.Visible);
    FRowEnabled := AddBoolRow(FCatVisual, 'Habilitado', C.Enabled);
    FRowBkColor := AddColorRow(FCatVisual, 'Color Fondo', C.BkColor, True);

  finally
    vg.EndUpdate;
  end;
end;

{ --- Value getters --- }

function TfrmCentreInspector.GetRowText(ARow: TcxEditorRow): string;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := ''
  else
    Result := VarToStr(ARow.Properties.Value);
end;

function TfrmCentreInspector.GetRowInt(ARow: TcxEditorRow): Integer;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := 0
  else
    Result := ARow.Properties.Value;
end;

function TfrmCentreInspector.GetRowFloat(ARow: TcxEditorRow): Double;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := 0
  else
    Result := ARow.Properties.Value;
end;

function TfrmCentreInspector.GetRowBool(ARow: TcxEditorRow): Boolean;
begin
  if VarIsNull(ARow.Properties.Value) then
    Result := False
  else
    Result := ARow.Properties.Value;
end;

{ --- Apply changes back --- }

procedure TfrmCentreInspector.ApplyToCentre;
begin
  FCentre.CodiCentre    := GetRowText(FRowCodiCentre);
  FCentre.Titulo        := GetRowText(FRowTitulo);
  FCentre.Subtitulo     := GetRowText(FRowSubtitulo);
  FCentre.Area          := GetRowText(FRowArea);
  FCentre.IsSequencial  := GetRowBool(FRowIsSequencial);
  FCentre.MaxLaneCount  := GetRowInt(FRowMaxLaneCount);
  FCentre.BaseHeight    := GetRowFloat(FRowBaseHeight);
  FCentre.Order         := GetRowInt(FRowOrder);
  FCentre.Visible       := GetRowBool(FRowVisible);
  FCentre.Enabled       := GetRowBool(FRowEnabled);
end;

procedure TfrmCentreInspector.btnOKClick(Sender: TObject);
begin
  ApplyToCentre;
  ModalResult := mrOk;
end;

procedure TfrmCentreInspector.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
