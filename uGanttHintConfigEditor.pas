unit uGanttHintConfigEditor;

{
  TfrmGanttHintConfigEditor - Configurador del HINT (informacion emergente) de
  los nodos del Gantt.

  UI deliberadamente SIMPLE (no reutiliza el Disenador de Nodos, que maqueta una
  barra 2D): el hint es una LISTA lineal de campos, asi que aqui solo hay:
    - Selector de Vista (TGanttViewMode) arriba.
    - Un TcxCheckListBox (DevExpress) con todos los campos: el check = visible, y
      el orden de la lista = orden en el hint.
    - Botones Subir/Bajar para reordenar.
    - Una vista previa de texto del hint resultante.

  El modelo interno FItems es la FUENTE DE VERDAD mientras se edita; el
  TcxCheckListBox es solo su reflejo (asi evitamos quirks de la lista visual).

  Persiste por usuario via THintConfigSetRepo (tabla FS_PL_HintConfigSet, V060),
  mismo patron que el Node Layout.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.StrUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxCheckListBox, cxCheckBox,
  uGanttTypes, uCardLayout,
  uGanttHintConfig, uGanttHintConfigRepo,
  uHelpViewer,
  dxSkinsCore, dxSkinBasic, dxSkinBlack, dxSkinBlue,
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
  dxSkinXmas2008Blue, dxSkinOffice2019Colorful,
  cxCustomListBox;

type
  TfrmGanttHintConfigEditor = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    lblVista: TLabel;
    cmbVista: TComboBox;
    pnlFooter: TPanel;
    btnAceptar: TButton;
    btnCancelar: TButton;
    pnlMain: TPanel;
    pnlLeft: TPanel;
    lblCampos: TLabel;
    clbCampos: TcxCheckListBox;
    pnlOrderBtns: TPanel;
    btnSubir: TButton;
    btnBajar: TButton;
    pnlRight: TPanel;
    lblPreview: TLabel;
    memPreview: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure cmbVistaChange(Sender: TObject);
    procedure btnSubirClick(Sender: TObject);
    procedure btnBajarClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure clbCamposClickCheck(Sender: TObject; AIndex: Integer;
      APrevState, ANewState: TcxCheckBoxState);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FConfigSet: THintConfigSet;
    FCurrentView: TGanttViewMode;
    FViews: TArray<TGanttViewMode>;
    FLoading: Boolean;
    FSampleData: TNodeData;
    // Modelo interno de la vista actual: FUENTE DE VERDAD mientras se edita.
    // El orden del array = orden del hint.
    FItems: TArray<THintField>;

    procedure PopulateVistas;
    procedure BuildSampleData;
    procedure LoadViewIntoUI(V: TGanttViewMode);
    procedure BuildItemsFor(V: TGanttViewMode);
    procedure SyncListFromItems(AKeepIndex: Integer);
    procedure CommitCurrentLayout;
    procedure MoveSelected(ADelta: Integer);
    procedure RefreshPreview;
  public
    procedure SetConfigSet(const ASet: THintConfigSet);
    function GetConfigSet: THintConfigSet;
    property ConfigSet: THintConfigSet read GetConfigSet write SetConfigSet;
  end;

// Punto de entrada: siembra el set de sistema si falta, carga el activo, muestra
// el editor y persiste si el usuario acepta. Devuelve True si se guardo algo.
function ShowGanttHintConfigEditor(AOwner: TForm; ARepo: THintConfigSetRepo): Boolean;

implementation

{$R *.dfm}

uses
  System.Math;

{ ---- Datos de ejemplo para la vista previa ---- }

procedure TfrmGanttHintConfigEditor.BuildSampleData;
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
  FSampleData.Stock := 42;
end;

{ ---- Form ---- }

procedure TfrmGanttHintConfigEditor.FormCreate(Sender: TObject);
begin
  FLoading := False;
  FCurrentView := gvmNormal;
  FConfigSet := DefaultHintConfigSet;
  BuildSampleData;
  PopulateVistas;
  LoadViewIntoUI(FCurrentView);
  THelpViewer.InstallHelp(Self, 'uGanttHintConfigEditor',
    'Configurar informaci'#243'n emergente');
end;

procedure TfrmGanttHintConfigEditor.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then ModalResult := mrCancel;
end;

procedure TfrmGanttHintConfigEditor.PopulateVistas;
var
  V: TGanttViewMode;
  Idx: Integer;
begin
  FLoading := True;
  try
    cmbVista.Items.Clear;
    SetLength(FViews, Ord(High(TGanttViewMode)) - Ord(Low(TGanttViewMode)) + 1);
    Idx := 0;
    for V := Low(TGanttViewMode) to High(TGanttViewMode) do
    begin
      cmbVista.Items.Add(HintGanttViewModeCaption(V));
      FViews[Idx] := V;
      Inc(Idx);
    end;
    cmbVista.ItemIndex := Ord(FCurrentView) - Ord(Low(TGanttViewMode));
  finally
    FLoading := False;
  end;
end;

// Construye FItems para la vista V: primero los campos del layout (en orden, con
// su visibilidad), luego el resto de campos disponibles no incluidos
// (desmarcados, al final) para que el usuario pueda anadirlos.
procedure TfrmGanttHintConfigEditor.BuildItemsFor(V: TGanttViewMode);
var
  Layout: THintLayout;
  Avail: TArray<string>;
  i, n: Integer;
  used: TDictionary<string, Boolean>;
begin
  Layout := FConfigSet.Layouts[V];
  used := TDictionary<string, Boolean>.Create;
  try
    SetLength(FItems, 0);
    n := 0;

    for i := 0 to High(Layout.Fields) do
    begin
      SetLength(FItems, n + 1);
      FItems[n] := Layout.Fields[i];
      used.AddOrSetValue(LowerCase(Layout.Fields[i].FieldName), True);
      Inc(n);
    end;

    Avail := HintAvailableFields;
    for i := 0 to High(Avail) do
    begin
      if used.ContainsKey(LowerCase(Avail[i])) then Continue;
      SetLength(FItems, n + 1);
      FItems[n].FieldName := Avail[i];
      FItems[n].Visible := False;
      Inc(n);
    end;
  finally
    used.Free;
  end;
end;

// Refleja FItems en el TcxCheckListBox. AKeepIndex >=0 restaura la seleccion.
procedure TfrmGanttHintConfigEditor.SyncListFromItems(AKeepIndex: Integer);
var
  i: Integer;
  it: TcxCheckListBoxItem;
begin
  FLoading := True;
  try
    clbCampos.Items.BeginUpdate;
    try
      clbCampos.Items.Clear;
      for i := 0 to High(FItems) do
      begin
        it := clbCampos.Items.Add;
        it.Text := HintFieldCaption(FItems[i].FieldName);
        it.Checked := FItems[i].Visible;
      end;
    finally
      clbCampos.Items.EndUpdate;
    end;
    if (AKeepIndex >= 0) and (AKeepIndex < clbCampos.Items.Count) then
      clbCampos.ItemIndex := AKeepIndex;
  finally
    FLoading := False;
  end;
end;

procedure TfrmGanttHintConfigEditor.LoadViewIntoUI(V: TGanttViewMode);
begin
  FCurrentView := V;
  BuildItemsFor(V);
  SyncListFromItems(-1);
  RefreshPreview;
end;

procedure TfrmGanttHintConfigEditor.CommitCurrentLayout;
var
  Layout: THintLayout;
  i: Integer;
begin
  // FItems ya es el orden + visibilidad actuales.
  SetLength(Layout.Fields, Length(FItems));
  for i := 0 to High(FItems) do
    Layout.Fields[i] := FItems[i];
  FConfigSet.Layouts[FCurrentView] := Layout;
end;

procedure TfrmGanttHintConfigEditor.cmbVistaChange(Sender: TObject);
var
  NewView: TGanttViewMode;
begin
  if FLoading then Exit;
  if cmbVista.ItemIndex < 0 then Exit;
  if cmbVista.ItemIndex > High(FViews) then Exit;
  NewView := FViews[cmbVista.ItemIndex];
  if NewView = FCurrentView then Exit;
  CommitCurrentLayout;
  LoadViewIntoUI(NewView);
end;

procedure TfrmGanttHintConfigEditor.MoveSelected(ADelta: Integer);
var
  i, j: Integer;
  tmp: THintField;
begin
  i := clbCampos.ItemIndex;
  if i < 0 then Exit;
  j := i + ADelta;
  if (j < 0) or (j > High(FItems)) then Exit;

  tmp := FItems[i];
  FItems[i] := FItems[j];
  FItems[j] := tmp;

  SyncListFromItems(j);  // mantiene seleccionado el item movido
  RefreshPreview;
end;

procedure TfrmGanttHintConfigEditor.btnSubirClick(Sender: TObject);
begin
  MoveSelected(-1);
end;

procedure TfrmGanttHintConfigEditor.btnBajarClick(Sender: TObject);
begin
  MoveSelected(1);
end;

procedure TfrmGanttHintConfigEditor.clbCamposClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
begin
  if FLoading then Exit;
  if (AIndex >= 0) and (AIndex <= High(FItems)) then
    FItems[AIndex].Visible := (ANewState = cbsChecked);
  RefreshPreview;
end;

procedure TfrmGanttHintConfigEditor.RefreshPreview;
var
  Layout: THintLayout;
  i: Integer;
  Resolver: TCardFieldResolver;
begin
  SetLength(Layout.Fields, Length(FItems));
  for i := 0 to High(FItems) do
    Layout.Fields[i] := FItems[i];

  Resolver := MakeNodeDataResolver(FSampleData);
  memPreview.Lines.Text := BuildHintText(Layout, Resolver);
end;

procedure TfrmGanttHintConfigEditor.btnAceptarClick(Sender: TObject);
begin
  CommitCurrentLayout;
  ModalResult := mrOk;
end;

procedure TfrmGanttHintConfigEditor.SetConfigSet(const ASet: THintConfigSet);
begin
  FConfigSet := ASet;
  LoadViewIntoUI(FCurrentView);
end;

function TfrmGanttHintConfigEditor.GetConfigSet: THintConfigSet;
begin
  CommitCurrentLayout;
  Result := FConfigSet;
end;

{ ---- Punto de entrada ---- }

function ShowGanttHintConfigEditor(AOwner: TForm; ARepo: THintConfigSetRepo): Boolean;
var
  F: TfrmGanttHintConfigEditor;
  ASet: THintConfigSet;
  ANombre: string;
  AIsCommon: Boolean;
  ActiveId, NewId: Integer;
begin
  Result := False;
  if ARepo = nil then Exit;

  ARepo.SeedDefaultIfEmpty;
  ActiveId := ARepo.LoadActive(ASet, ANombre, AIsCommon);

  F := TfrmGanttHintConfigEditor.Create(AOwner);
  try
    F.ConfigSet := ASet;
    if F.ShowModal <> mrOk then Exit;
    ASet := F.ConfigSet;
  finally
    F.Free;
  end;

  // Persistencia (mismo criterio que el Node Layout):
  //  - Set privado existente -> UpdateSet sobre el mismo id.
  //  - Set comun/sistema (o sin activo) -> Insert de uno privado 'Personalizado'
  //    y marcarlo activo, para no pisar el comun/sistema.
  if (ActiveId > 0) and (not AIsCommon) then
    ARepo.UpdateSet(ActiveId, IfThen(Trim(ANombre) = '', 'Personalizado', ANombre), ASet)
  else
  begin
    NewId := ARepo.Insert('Personalizado', False, ASet);
    if NewId > 0 then
      ARepo.SetActiveSetId(NewId)
    else if ActiveId > 0 then
      ARepo.UpdateSet(ActiveId,
        IfThen(Trim(ANombre) = '', 'Por defecto (sistema)', ANombre), ASet);
  end;

  Result := True;
end;

end.
