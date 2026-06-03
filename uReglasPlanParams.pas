unit uReglasPlanParams;

{
  Dialogo de configuracion del motor de planificacion POR REGLAS (PRO).

  Estructura de la pantalla:
    - Direccion (forward/backward) y fecha base.
    - Tipo de regla:  "Reglas canonicas" | "Reglas personalizadas"  (preparado
      para mas tipos en el futuro).
    - Regla del tipo: segun el tipo elegido, las 7 canonicas o los perfiles
      guardados en "Reglas de Planificacion".
    - Desempates (1 y 2): SOLO aplican a reglas canonicas (un perfil ya lleva
      sus criterios encadenados). Se ocultan cuando el tipo es personalizada.
    - Overrides por centro: una fila por centro del plan.

  Devuelve la configuracion lista para el motor:
    - Params (Mode + FechaBase), Global (TPriorityRuleSet), Overrides,
    - APerfilSeleccionado: -1 si regla canonica; >=0 indice del perfil custom.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxEdit, cxGrid, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxContainer, cxClasses, cxCustomData, cxData, cxDataStorage,
  cxNavigator, cxDropDownEdit, cxFilter,
  uBacklogScheduler, uPlanningEngineRules;

type
  TfrmReglasPlanParams = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnComparar: TButton;
    btnPrevisualizar: TButton;
    btnCancel: TButton;
    pnlContent: TPanel;
    lblModo: TLabel;
    lblFechaBase: TLabel;
    rbForward: TRadioButton;
    rbBackward: TRadioButton;
    dtFechaBase: TDateTimePicker;
    lblTipo: TLabel;
    cmbTipo: TComboBox;
    lblRegla: TLabel;
    cmbRegla: TComboBox;
    lblDesempate1: TLabel;
    lblDesempate2: TLabel;
    cmbDesempate1: TComboBox;
    cmbDesempate2: TComboBox;
    chkOverrides: TCheckBox;
    lblOverrides: TLabel;
    grdOverrides: TcxGrid;
    tvOverrides: TcxGridTableView;
    lvOverrides: TcxGridLevel;
    colCentro: TcxGridColumn;
    colRegla: TcxGridColumn;
    procedure FormCreate(Sender: TObject);
    procedure chkOverridesClick(Sender: TObject);
    procedure cmbTipoChange(Sender: TObject);
  private
    FParams: TSchedParams;
    FGlobal: TPriorityRuleSet;
    FOverrides: TArray<TCenterRuleOverride>;
    FCentros: TArray<string>;        // codigos de centro del plan
    FPerfilesCustom: TArray<string>; // nombres de perfiles custom (Reglas de Planificacion)
    FPerfilSeleccionado: Integer;    // -1 = regla canonica; >=0 = indice de perfil custom
    function TipoEsPersonalizada: Boolean;
    procedure FillRuleCombo(ACombo: TComboBox);
    procedure FillTipoCombo;
    procedure FillReglaCombo;
    procedure UpdateDesempatesVisible;
    procedure ApplyToUI;
    procedure ReadFromUI;
    procedure BuildOverridesGrid;
    procedure ReadOverridesFromGrid;
    procedure LoadLast;
    procedure SaveLast;
    procedure UpdateOverridesEnabled;
  public
    // Devuelve:
    //   mrOk        -> previsualizar con la regla elegida
    //   mrComparar  -> abrir comparativa de las 7 reglas canonicas
    //   mrCancel    -> cancelar
    // ACentros: codigos de los centros del plan (para overrides).
    // APerfilesCustom: nombres de los perfiles guardados en Reglas de Planificacion.
    // APerfilSeleccionado (salida): -1 si se eligio regla canonica; >=0 indice de perfil.
    class function Execute(const ACentros: TArray<string>;
      const APerfilesCustom: TArray<string>;
      var AParams: TSchedParams; var AGlobal: TPriorityRuleSet;
      var AOverrides: TArray<TCenterRuleOverride>;
      out APerfilSeleccionado: Integer): TModalResult;
  end;

const
  mrComparar = 11;   // = mrYesToAll; usado por btnComparar

implementation

{$R *.dfm}

uses
  System.DateUtils,
  uUserPrefs, uHelpViewer;

const
  MOD_NAME = 'MOTOR_REGLAS';
  GLOBAL_TXT = '(global)';

  // Indices del combo de tipo.
  TIPO_CANONICA = 0;
  TIPO_PERSONALIZADA = 1;

function RuleAtIndex(AIndex: Integer): TPriorityRule;
begin
  if (AIndex < 0) or (AIndex > Ord(High(TPriorityRule))) then
    Result := prEDD
  else
    Result := TPriorityRule(AIndex);
end;

{ TfrmReglasPlanParams }

class function TfrmReglasPlanParams.Execute(const ACentros: TArray<string>;
  const APerfilesCustom: TArray<string>;
  var AParams: TSchedParams; var AGlobal: TPriorityRuleSet;
  var AOverrides: TArray<TCenterRuleOverride>;
  out APerfilSeleccionado: Integer): TModalResult;
var
  F: TfrmReglasPlanParams;
begin
  APerfilSeleccionado := -1;
  F := TfrmReglasPlanParams.Create(Application);
  try
    F.FCentros := Copy(ACentros);
    F.FPerfilesCustom := Copy(APerfilesCustom);
    F.FParams := AParams;
    F.FGlobal := AGlobal;
    F.FOverrides := Copy(AOverrides);
    F.ApplyToUI;
    Result := F.ShowModal;
    if (Result = mrOk) or (Result = mrComparar) then
    begin
      F.ReadFromUI;
      F.ReadOverridesFromGrid;
      F.SaveLast;
      AParams := F.FParams;
      AGlobal := F.FGlobal;
      AOverrides := Copy(F.FOverrides);
      APerfilSeleccionado := F.FPerfilSeleccionado;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmReglasPlanParams.FormCreate(Sender: TObject);
var
  R: TPriorityRule;
  Props: TcxComboBoxProperties;
begin
  cmbTipo.Style   := csDropDownList;
  cmbRegla.Style  := csDropDownList;
  FillRuleCombo(cmbDesempate1);
  FillRuleCombo(cmbDesempate2);

  // Columna de regla del grid: combo de lista fija con "(global)" + 7 reglas.
  colRegla.PropertiesClass := TcxComboBoxProperties;
  Props := TcxComboBoxProperties(colRegla.Properties);
  Props.DropDownListStyle := lsFixedList;
  Props.Items.Clear;
  Props.Items.Add(GLOBAL_TXT);
  for R := Low(TPriorityRule) to High(TPriorityRule) do
    Props.Items.Add(PriorityRuleToStr(R));

  LoadLast;
  ApplyToUI;

  THelpViewer.InstallHelp(Self, 'uReglasPlanParams', 'Planificaci'#243'n por reglas');
end;

procedure TfrmReglasPlanParams.FillRuleCombo(ACombo: TComboBox);
var
  R: TPriorityRule;
begin
  ACombo.Items.Clear;
  for R := Low(TPriorityRule) to High(TPriorityRule) do
    ACombo.Items.Add(PriorityRuleToStr(R));
  ACombo.Style := csDropDownList;
end;

procedure TfrmReglasPlanParams.FillTipoCombo;
begin
  cmbTipo.Items.BeginUpdate;
  try
    cmbTipo.Items.Clear;
    cmbTipo.Items.Add('Reglas can'#243'nicas');           // TIPO_CANONICA
    cmbTipo.Items.Add('Reglas personalizadas');         // TIPO_PERSONALIZADA
  finally
    cmbTipo.Items.EndUpdate;
  end;
end;

function TfrmReglasPlanParams.TipoEsPersonalizada: Boolean;
begin
  Result := cmbTipo.ItemIndex = TIPO_PERSONALIZADA;
end;

// Rellena el combo de regla segun el tipo elegido.
procedure TfrmReglasPlanParams.FillReglaCombo;
var
  R: TPriorityRule;
  I: Integer;
begin
  cmbRegla.Items.BeginUpdate;
  try
    cmbRegla.Items.Clear;
    if TipoEsPersonalizada then
    begin
      for I := 0 to High(FPerfilesCustom) do
        cmbRegla.Items.Add(FPerfilesCustom[I]);
    end
    else
    begin
      for R := Low(TPriorityRule) to High(TPriorityRule) do
        cmbRegla.Items.Add(PriorityRuleToStr(R));
    end;
  finally
    cmbRegla.Items.EndUpdate;
  end;
  if cmbRegla.Items.Count > 0 then
    cmbRegla.ItemIndex := 0;
end;

// Los desempates solo tienen sentido con reglas canonicas.
procedure TfrmReglasPlanParams.UpdateDesempatesVisible;
var
  Vis: Boolean;
begin
  Vis := not TipoEsPersonalizada;
  lblDesempate1.Visible := Vis;
  lblDesempate2.Visible := Vis;
  cmbDesempate1.Visible := Vis;
  cmbDesempate2.Visible := Vis;
end;

procedure TfrmReglasPlanParams.cmbTipoChange(Sender: TObject);
begin
  // Si se pide personalizada pero no hay perfiles, avisar y volver a canonicas.
  if TipoEsPersonalizada and (Length(FPerfilesCustom) = 0) then
  begin
    MessageBox(Handle,
      'No hay perfiles personalizados guardados.' + sLineBreak +
      'Cr'#233'alos en Configuraci'#243'n - Reglas de Planificaci'#243'n.',
      'Reglas personalizadas', MB_ICONINFORMATION or MB_OK);
    cmbTipo.ItemIndex := TIPO_CANONICA;
  end;
  FillReglaCombo;
  UpdateDesempatesVisible;
end;

procedure TfrmReglasPlanParams.ApplyToUI;
begin
  rbForward.Checked  := FParams.Mode = smForward;
  rbBackward.Checked := FParams.Mode = smBackward;
  if FParams.FechaBase = 0 then
    dtFechaBase.Date := Date
  else
    dtFechaBase.Date := FParams.FechaBase;

  FillTipoCombo;
  cmbTipo.ItemIndex := TIPO_CANONICA;   // arranque por defecto en canonicas
  FillReglaCombo;
  cmbRegla.ItemIndex := Ord(FGlobal.Principal);

  cmbDesempate1.ItemIndex := Ord(FGlobal.Desempate1);
  cmbDesempate2.ItemIndex := Ord(FGlobal.Desempate2);
  UpdateDesempatesVisible;

  BuildOverridesGrid;
  UpdateOverridesEnabled;
end;

procedure TfrmReglasPlanParams.ReadFromUI;
begin
  if rbBackward.Checked then FParams.Mode := smBackward
  else FParams.Mode := smForward;
  FParams.FechaBase := dtFechaBase.Date;

  FPerfilSeleccionado := -1;
  if TipoEsPersonalizada then
  begin
    // El indice de regla es el indice del perfil custom.
    if (cmbRegla.ItemIndex >= 0) and (cmbRegla.ItemIndex <= High(FPerfilesCustom)) then
      FPerfilSeleccionado := cmbRegla.ItemIndex;
  end
  else
    FGlobal.Principal := RuleAtIndex(cmbRegla.ItemIndex);

  FGlobal.Desempate1 := RuleAtIndex(cmbDesempate1.ItemIndex);
  FGlobal.Desempate2 := RuleAtIndex(cmbDesempate2.ItemIndex);
end;

procedure TfrmReglasPlanParams.BuildOverridesGrid;
var
  I, J: Integer;
  Found: Boolean;
begin
  tvOverrides.BeginUpdate;
  try
    tvOverrides.DataController.RecordCount := Length(FCentros);
    for I := 0 to High(FCentros) do
    begin
      tvOverrides.DataController.Values[I, colCentro.Index] := FCentros[I];
      Found := False;
      for J := 0 to High(FOverrides) do
        if SameText(Trim(FOverrides[J].CentroCode), Trim(FCentros[I])) then
        begin
          tvOverrides.DataController.Values[I, colRegla.Index] :=
            PriorityRuleToStr(FOverrides[J].Rules.Principal);
          Found := True;
          Break;
        end;
      if not Found then
        tvOverrides.DataController.Values[I, colRegla.Index] := GLOBAL_TXT;
    end;
  finally
    tvOverrides.EndUpdate;
  end;
end;

procedure TfrmReglasPlanParams.ReadOverridesFromGrid;
var
  I, Idx: Integer;
  ReglaTxt, CentroTxt: string;
  L: TList<TCenterRuleOverride>;
  Ov: TCenterRuleOverride;
begin
  L := TList<TCenterRuleOverride>.Create;
  try
    if chkOverrides.Checked then
    begin
      for I := 0 to tvOverrides.DataController.RecordCount - 1 do
      begin
        CentroTxt := VarToStr(tvOverrides.DataController.Values[I, colCentro.Index]);
        ReglaTxt  := VarToStr(tvOverrides.DataController.Values[I, colRegla.Index]);
        if (ReglaTxt = '') or (ReglaTxt = GLOBAL_TXT) then Continue;
        Idx := TcxComboBoxProperties(colRegla.Properties).Items.IndexOf(ReglaTxt);
        if Idx <= 0 then Continue;  // 0 o no encontrado = global
        Ov.CentroCode := CentroTxt;
        // Override solo fija la regla principal; los desempates heredan del global.
        Ov.Rules.Principal  := RuleAtIndex(Idx - 1);
        Ov.Rules.Desempate1 := FGlobal.Desempate1;
        Ov.Rules.Desempate2 := FGlobal.Desempate2;
        L.Add(Ov);
      end;
    end;
    FOverrides := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmReglasPlanParams.chkOverridesClick(Sender: TObject);
begin
  UpdateOverridesEnabled;
end;

procedure TfrmReglasPlanParams.UpdateOverridesEnabled;
begin
  grdOverrides.Enabled := chkOverrides.Checked;
  lblOverrides.Enabled := chkOverrides.Checked;
end;

procedure TfrmReglasPlanParams.LoadLast;
var
  ModeVal: Integer;
  FechaStr: string;
  D: TDateTime;
begin
  ModeVal := uUserPrefs.GetPrefInt(MOD_NAME, 'Mode', Ord(smForward));
  if ModeVal = Ord(smBackward) then FParams.Mode := smBackward
  else FParams.Mode := smForward;

  FechaStr := uUserPrefs.GetPref(MOD_NAME, 'FechaBase', '');
  if TryStrToDate(FechaStr, D) then FParams.FechaBase := D
  else FParams.FechaBase := Date;

  FGlobal.Principal  := RuleAtIndex(uUserPrefs.GetPrefInt(MOD_NAME, 'Principal',  Ord(prEDD)));
  FGlobal.Desempate1 := RuleAtIndex(uUserPrefs.GetPrefInt(MOD_NAME, 'Desempate1', Ord(prFIFO)));
  FGlobal.Desempate2 := RuleAtIndex(uUserPrefs.GetPrefInt(MOD_NAME, 'Desempate2', Ord(prFIFO)));
end;

procedure TfrmReglasPlanParams.SaveLast;
begin
  uUserPrefs.SetPrefInt(MOD_NAME, 'Mode', Ord(FParams.Mode));
  uUserPrefs.SetPref(MOD_NAME, 'FechaBase',
    FormatDateTime('yyyy-mm-dd', FParams.FechaBase));
  uUserPrefs.SetPrefInt(MOD_NAME, 'Principal',  Ord(FGlobal.Principal));
  uUserPrefs.SetPrefInt(MOD_NAME, 'Desempate1', Ord(FGlobal.Desempate1));
  uUserPrefs.SetPrefInt(MOD_NAME, 'Desempate2', Ord(FGlobal.Desempate2));
end;

end.
