unit uGanttConfig;

{
  Configuracion centralizada de parametros del Gantt, por usuario.

  - TGanttConfig: record con todos los parametros configurables del Gantt.
  - LoadGanttConfig / SaveGanttConfig: persistencia por usuario en
    FS_PL_UserPreference (JSON, ScreenKey='GanttConfig') via DMPlanner.UserPrefs.
  - TfrmGanttConfig: formulario modal con un TcxVerticalGrid de categorias
    plegables para editar todos los parametros.

  Estos parametros actuan como DEFAULTS: el dialogo de planificacion por tanda
  (uBacklogSchedParams) los pre-carga de aqui y permite ajustarlos puntualmente.

  Para anadir un parametro nuevo: (1) campo en TGanttConfig, (2) leer/escribir en
  LoadGanttConfig/SaveGanttConfig, (3) fila en BuildRows + lectura en ReadFromUI.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.JSON, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  cxVGrid, cxInplaceContainer, cxControls, cxStyles, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, cxEdit,
  uBacklogScheduler, uGanttControl;

type
  // Todos los parametros configurables del Gantt (por usuario).
  TGanttConfig = record
    // --- Planificacion ---
    Mode: TSchedMode;
    Order: TSchedOrder;
    Placement: TPlacementPolicy;
    // --- Huecos ---
    HuecoMinimoMin: Integer;
    PorcentajeMinNodo: Integer;
    DistanciaMinNodos: Integer;
    // --- Visualizacion ---
    HideWeekends: Boolean;
    LinksVisible: TLinksVisible;
    AutoMarkers: Boolean;
    PxPerMinute: Double;
  end;

// Valores por defecto razonables (alineados con APS PRO).
function DefaultGanttConfig: TGanttConfig;

// Carga/guarda la configuracion del usuario actual. Si no hay nada guardado,
// devuelve DefaultGanttConfig.
function LoadGanttConfig: TGanttConfig;
procedure SaveGanttConfig(const ACfg: TGanttConfig);

// Vuelca los campos de planificacion/huecos de la config a un TSchedParams
// (deja Mode/Order/Placement/umbrales; NO toca FechaBase, que es por tanda).
procedure ApplyConfigToSchedParams(const ACfg: TGanttConfig; var AParams: TSchedParams);

type
  TfrmGanttConfig = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlBottom: TPanel;
    btnOk: TButton;
    btnCancel: TButton;
    vg: TcxVerticalGrid;
    procedure FormCreate(Sender: TObject);
  private
    FCfg: TGanttConfig;
    // Categorias
    FCatPlan, FCatHuecos, FCatVisual: TcxCategoryRow;
    // Filas editor
    FRowMode, FRowOrder, FRowPlacement: TcxEditorRow;
    FRowHuecoMin, FRowPctNodo, FRowDistMin: TcxEditorRow;
    FRowHideWE, FRowLinks, FRowAutoMarkers, FRowPxMin: TcxEditorRow;
    function AddCategory(const ACaption: string): TcxCategoryRow;
    function AddComboRow(AParent: TcxCategoryRow; const ACaption: string;
      const AItems: array of string; AIndex: Integer): TcxEditorRow;
    function AddIntRow(AParent: TcxCategoryRow; const ACaption: string;
      AValue, AMin, AMax: Integer): TcxEditorRow;
    function AddFloatRow(AParent: TcxCategoryRow; const ACaption: string;
      AValue: Double): TcxEditorRow;
    function AddBoolRow(AParent: TcxCategoryRow; const ACaption: string;
      AValue: Boolean): TcxEditorRow;
    procedure BuildRows;
    procedure ReadFromUI;
  public
    class function Execute(var ACfg: TGanttConfig): Boolean;
  end;

implementation

uses
  cxSpinEdit, cxCheckBox, cxDropDownEdit, cxTextEdit,
  uDMPlanner;

const
  SCREEN_KEY = 'GanttConfig';
  CFG_VERSION = 1;

{ ---------------- Defaults / persistencia ---------------- }

function DefaultGanttConfig: TGanttConfig;
begin
  Result.Mode := smBackward;
  Result.Order := soFechaCompromiso;
  Result.Placement := ppHueco;
  Result.HuecoMinimoMin := 30;
  Result.PorcentajeMinNodo := 50;
  Result.DistanciaMinNodos := 0;
  Result.HideWeekends := False;
  Result.LinksVisible := lvSelected;
  Result.AutoMarkers := False;
  Result.PxPerMinute := 0.05;
end;

function ClampOrd(AValue, ALo, AHi, ADef: Integer): Integer;
begin
  if (AValue >= ALo) and (AValue <= AHi) then Result := AValue
  else Result := ADef;
end;

function LoadGanttConfig: TGanttConfig;
var
  S: string;
  Root: TJSONObject;
begin
  Result := DefaultGanttConfig;
  if (DMPlanner = nil) or (DMPlanner.UserPrefs = nil) then Exit;
  S := DMPlanner.UserPrefs.Load(SCREEN_KEY);
  if Trim(S) = '' then Exit;

  Root := TJSONObject.ParseJSONValue(S) as TJSONObject;
  if Root = nil then Exit;
  try
    Result.Mode := TSchedMode(ClampOrd(
      Root.GetValue<Integer>('mode', Ord(Result.Mode)),
      Ord(Low(TSchedMode)), Ord(High(TSchedMode)), Ord(Result.Mode)));
    Result.Order := TSchedOrder(ClampOrd(
      Root.GetValue<Integer>('order', Ord(Result.Order)),
      Ord(Low(TSchedOrder)), Ord(High(TSchedOrder)), Ord(Result.Order)));
    Result.Placement := TPlacementPolicy(ClampOrd(
      Root.GetValue<Integer>('placement', Ord(Result.Placement)),
      Ord(Low(TPlacementPolicy)), Ord(High(TPlacementPolicy)), Ord(Result.Placement)));
    Result.HuecoMinimoMin := Root.GetValue<Integer>('huecoMin', Result.HuecoMinimoMin);
    Result.PorcentajeMinNodo := Root.GetValue<Integer>('pctNodo', Result.PorcentajeMinNodo);
    Result.DistanciaMinNodos := Root.GetValue<Integer>('distMin', Result.DistanciaMinNodos);
    Result.HideWeekends := Root.GetValue<Boolean>('hideWeekends', Result.HideWeekends);
    Result.LinksVisible := TLinksVisible(ClampOrd(
      Root.GetValue<Integer>('linksVisible', Ord(Result.LinksVisible)),
      Ord(Low(TLinksVisible)), Ord(High(TLinksVisible)), Ord(Result.LinksVisible)));
    Result.AutoMarkers := Root.GetValue<Boolean>('autoMarkers', Result.AutoMarkers);
    Result.PxPerMinute := Root.GetValue<Double>('pxPerMinute', Result.PxPerMinute);

    // Saneo de umbrales.
    if Result.HuecoMinimoMin < 0 then Result.HuecoMinimoMin := 0;
    if (Result.PorcentajeMinNodo < 0) or (Result.PorcentajeMinNodo > 100) then
      Result.PorcentajeMinNodo := 50;
    if Result.DistanciaMinNodos < 0 then Result.DistanciaMinNodos := 0;
    if Result.PxPerMinute <= 0 then Result.PxPerMinute := 0.05;
  finally
    Root.Free;
  end;
end;

procedure SaveGanttConfig(const ACfg: TGanttConfig);
var
  Root: TJSONObject;
begin
  if (DMPlanner = nil) or (DMPlanner.UserPrefs = nil) then Exit;
  Root := TJSONObject.Create;
  try
    Root.AddPair('version', TJSONNumber.Create(CFG_VERSION));
    Root.AddPair('mode', TJSONNumber.Create(Ord(ACfg.Mode)));
    Root.AddPair('order', TJSONNumber.Create(Ord(ACfg.Order)));
    Root.AddPair('placement', TJSONNumber.Create(Ord(ACfg.Placement)));
    Root.AddPair('huecoMin', TJSONNumber.Create(ACfg.HuecoMinimoMin));
    Root.AddPair('pctNodo', TJSONNumber.Create(ACfg.PorcentajeMinNodo));
    Root.AddPair('distMin', TJSONNumber.Create(ACfg.DistanciaMinNodos));
    Root.AddPair('hideWeekends', TJSONBool.Create(ACfg.HideWeekends));
    Root.AddPair('linksVisible', TJSONNumber.Create(Ord(ACfg.LinksVisible)));
    Root.AddPair('autoMarkers', TJSONBool.Create(ACfg.AutoMarkers));
    Root.AddPair('pxPerMinute', TJSONNumber.Create(ACfg.PxPerMinute));
    DMPlanner.UserPrefs.Save(SCREEN_KEY, Root.ToJSON);
  finally
    Root.Free;
  end;
end;

procedure ApplyConfigToSchedParams(const ACfg: TGanttConfig; var AParams: TSchedParams);
begin
  AParams.Mode := ACfg.Mode;
  AParams.Order := ACfg.Order;
  AParams.Placement := ACfg.Placement;
  AParams.HuecoMinimoMin := ACfg.HuecoMinimoMin;
  AParams.PorcentajeMinNodo := ACfg.PorcentajeMinNodo;
  AParams.DistanciaMinNodos := ACfg.DistanciaMinNodos;
end;

{ ---------------- Formulario ---------------- }

{$R *.dfm}

class function TfrmGanttConfig.Execute(var ACfg: TGanttConfig): Boolean;
var
  F: TfrmGanttConfig;
begin
  F := TfrmGanttConfig.Create(Application);
  try
    F.FCfg := ACfg;
    F.BuildRows;
    Result := F.ShowModal = mrOk;
    if Result then
    begin
      F.ReadFromUI;
      ACfg := F.FCfg;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmGanttConfig.FormCreate(Sender: TObject);
begin
  // BuildRows se llama desde Execute tras asignar FCfg.
end;

function TfrmGanttConfig.AddCategory(const ACaption: string): TcxCategoryRow;
begin
  Result := vg.Add(TcxCategoryRow) as TcxCategoryRow;
  Result.Properties.Caption := ACaption;
end;

function TfrmGanttConfig.AddComboRow(AParent: TcxCategoryRow;
  const ACaption: string; const AItems: array of string; AIndex: Integer): TcxEditorRow;
var
  I: Integer;
  Combo: TcxComboBoxProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClass := TcxComboBoxProperties;
  Combo := TcxComboBoxProperties(Result.Properties.EditProperties);
  Combo.DropDownListStyle := lsFixedList;
  Combo.Items.Clear;
  for I := 0 to High(AItems) do
    Combo.Items.Add(AItems[I]);
  if (AIndex >= 0) and (AIndex <= High(AItems)) then
    Result.Properties.Value := AItems[AIndex];
end;

function TfrmGanttConfig.AddIntRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue, AMin, AMax: Integer): TcxEditorRow;
var
  Spin: TcxSpinEditProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClass := TcxSpinEditProperties;
  Spin := TcxSpinEditProperties(Result.Properties.EditProperties);
  Spin.MinValue := AMin;
  Spin.MaxValue := AMax;
  Result.Properties.Value := AValue;
end;

function TfrmGanttConfig.AddFloatRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: Double): TcxEditorRow;
var
  Spin: TcxSpinEditProperties;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClass := TcxSpinEditProperties;
  Spin := TcxSpinEditProperties(Result.Properties.EditProperties);
  Spin.ValueType := vtFloat;
  Spin.MinValue := 0;
  Spin.MaxValue := 100;
  Spin.Increment := 0.01;
  Result.Properties.Value := AValue;
end;

function TfrmGanttConfig.AddBoolRow(AParent: TcxCategoryRow;
  const ACaption: string; AValue: Boolean): TcxEditorRow;
begin
  Result := vg.AddChild(AParent, TcxEditorRow) as TcxEditorRow;
  Result.Properties.Caption := ACaption;
  Result.Properties.EditPropertiesClass := TcxCheckBoxProperties;
  Result.Properties.Value := AValue;
end;

procedure TfrmGanttConfig.BuildRows;
begin
  vg.BeginUpdate;
  try
    vg.ClearRows;

    FCatPlan := AddCategory('Planificaci'#243'n');
    FRowMode := AddComboRow(FCatPlan, 'Modo',
      ['Forward (desde fecha base)', 'Backward (desde compromiso)'], Ord(FCfg.Mode));
    FRowOrder := AddComboRow(FCatPlan, 'Orden',
      ['Por FechaCompromiso', 'Por Prioridad'], Ord(FCfg.Order));
    FRowPlacement := AddComboRow(FCatPlan, 'Colocaci'#243'n',
      [PlacementToStr(ppFinCola), PlacementToStr(ppHueco), PlacementToStr(ppHuecoShift)],
      Ord(FCfg.Placement));

    FCatHuecos := AddCategory('Huecos');
    FRowHuecoMin := AddIntRow(FCatHuecos, 'Hueco m'#237'nimo (min)',
      FCfg.HuecoMinimoMin, 0, 100000);
    FRowPctNodo := AddIntRow(FCatHuecos, '% m'#237'nimo del nodo',
      FCfg.PorcentajeMinNodo, 0, 100);
    FRowDistMin := AddIntRow(FCatHuecos, 'M'#237'nima distancia entre nodos (min)',
      FCfg.DistanciaMinNodos, 0, 100000);

    FCatVisual := AddCategory('Visualizaci'#243'n');
    FRowHideWE := AddBoolRow(FCatVisual, 'Ocultar fines de semana', FCfg.HideWeekends);
    FRowLinks := AddComboRow(FCatVisual, 'Mostrar links',
      ['Nunca', 'Solo seleccionado', 'Siempre'], Ord(FCfg.LinksVisible));
    FRowAutoMarkers := AddBoolRow(FCatVisual, 'Marcadores autom'#225'ticos', FCfg.AutoMarkers);
    FRowPxMin := AddFloatRow(FCatVisual, 'Zoom (px/min)', FCfg.PxPerMinute);
  finally
    vg.EndUpdate;
  end;
end;

procedure TfrmGanttConfig.ReadFromUI;
  function ComboIdx(ARow: TcxEditorRow): Integer;
  var
    Combo: TcxComboBoxProperties;
  begin
    Result := -1;
    Combo := TcxComboBoxProperties(ARow.Properties.EditProperties);
    Result := Combo.Items.IndexOf(VarToStr(ARow.Properties.Value));
  end;
var
  Idx: Integer;
begin
  Idx := ComboIdx(FRowMode);
  if Idx >= 0 then FCfg.Mode := TSchedMode(Idx);
  Idx := ComboIdx(FRowOrder);
  if Idx >= 0 then FCfg.Order := TSchedOrder(Idx);
  Idx := ComboIdx(FRowPlacement);
  if Idx >= 0 then FCfg.Placement := TPlacementPolicy(Idx);

  FCfg.HuecoMinimoMin := FRowHuecoMin.Properties.Value;
  FCfg.PorcentajeMinNodo := FRowPctNodo.Properties.Value;
  FCfg.DistanciaMinNodos := FRowDistMin.Properties.Value;

  FCfg.HideWeekends := Boolean(FRowHideWE.Properties.Value);
  Idx := ComboIdx(FRowLinks);
  if Idx >= 0 then FCfg.LinksVisible := TLinksVisible(Idx);
  FCfg.AutoMarkers := Boolean(FRowAutoMarkers.Properties.Value);
  FCfg.PxPerMinute := Double(FRowPxMin.Properties.Value);
end;

end.
