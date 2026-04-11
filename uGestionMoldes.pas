unit uGestionMoldes;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst, Vcl.ComCtrls,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxSpinEdit,
  cxCheckBox, cxContainer, cxClasses, cxFilter, cxPC,
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
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue,
  dxScrollbarAnnotations,
  // Project
  uMoldeTypes, uMoldeRepo, uGanttTypes,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges;

type
  TfrmGestionMoldes = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    chkDarkMode: TCheckBox;
    pnlBottom: TPanel;
    btnCerrar: TButton;
    pc: TcxPageControl;
    LookAndFeel: TcxLookAndFeelController;
    // Tab Moldes
    tabMoldes: TcxTabSheet;
    pnlMoldeToolbar: TPanel;
    btnMoldeAdd: TButton;
    btnMoldeEdit: TButton;
    btnMoldeDel: TButton;
    gridMoldes: TcxGrid;
    tvMoldes: TcxGridTableView;
    colMoldeId: TcxGridColumn;
    colMoldeCodigo: TcxGridColumn;
    colMoldeDesc: TcxGridColumn;
    colMoldeTipo: TcxGridColumn;
    colMoldeEstado: TcxGridColumn;
    colMoldeCavidades: TcxGridColumn;
    colMoldeUbicacion: TcxGridColumn;
    colMoldeCentroActual: TcxGridColumn;
    colMoldeCentros: TcxGridColumn;
    colMoldeOperaciones: TcxGridColumn;
    lvMoldes: TcxGridLevel;
    // Tab Centros
    tabCentros: TcxTabSheet;
    splCentros: TSplitter;
    pnlCentrosLeft: TPanel;
    lblSelMoldeCentro: TLabel;
    gridCentroMoldes: TcxGrid;
    tvCentroMoldes: TcxGridTableView;
    colCentroMoldeId: TcxGridColumn;
    colCentroMoldeCodigo: TcxGridColumn;
    lvCentroMoldes: TcxGridLevel;
    pnlCentrosRight: TPanel;
    lblCentrosAsig: TLabel;
    gridCentrosAsig: TcxGrid;
    tvCentrosAsig: TcxGridTableView;
    colCentrosAsigNom: TcxGridColumn;
    colCentrosAsigCheck: TcxGridColumn;
    colCentrosAsigPreferente: TcxGridColumn;
    lvCentrosAsig: TcxGridLevel;
    // Tab Operaciones
    tabOperaciones: TcxTabSheet;
    splOperaciones: TSplitter;
    pnlOpsLeft: TPanel;
    lblSelMoldeOp: TLabel;
    gridOpMoldes: TcxGrid;
    tvOpMoldes: TcxGridTableView;
    colOpMoldeId: TcxGridColumn;
    colOpMoldeCodigo: TcxGridColumn;
    lvOpMoldes: TcxGridLevel;
    pnlOpsRight: TPanel;
    lblOpsAsig: TLabel;
    gridOpsAsig: TcxGrid;
    tvOpsAsig: TcxGridTableView;
    colOpsAsigNom: TcxGridColumn;
    colOpsAsigCheck: TcxGridColumn;
    lvOpsAsig: TcxGridLevel;
    // Tab Articulos
    tabArticulos: TcxTabSheet;
    splArticulos: TSplitter;
    pnlArtLeft: TPanel;
    lblSelMoldeArt: TLabel;
    gridArtMoldes: TcxGrid;
    tvArtMoldes: TcxGridTableView;
    colArtMoldeId: TcxGridColumn;
    colArtMoldeCodigo: TcxGridColumn;
    lvArtMoldes: TcxGridLevel;
    pnlArtRight: TPanel;
    lblArtAsig: TLabel;
    gridArtAsig: TcxGrid;
    tvArtAsig: TcxGridTableView;
    colArtAsigNom: TcxGridColumn;
    colArtAsigCheck: TcxGridColumn;
    lvArtAsig: TcxGridLevel;
    // Tab Utillajes
    tabUtillajes: TcxTabSheet;
    splUtillajes: TSplitter;
    pnlUtLeft: TPanel;
    lblSelMoldeUt: TLabel;
    gridUtMoldes: TcxGrid;
    tvUtMoldes: TcxGridTableView;
    colUtMoldeId: TcxGridColumn;
    colUtMoldeCodigo: TcxGridColumn;
    lvUtMoldes: TcxGridLevel;
    pnlUtRight: TPanel;
    lblUtAsig: TLabel;
    gridUtAsig: TcxGrid;
    tvUtAsig: TcxGridTableView;
    colUtAsigNom: TcxGridColumn;
    colUtAsigCheck: TcxGridColumn;
    colUtAsigObligatorio: TcxGridColumn;
    lvUtAsig: TcxGridLevel;
    // Events
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCerrarClick(Sender: TObject);
    procedure chkDarkModeClick(Sender: TObject);
    // Moldes CRUD
    procedure btnMoldeAddClick(Sender: TObject);
    procedure btnMoldeEditClick(Sender: TObject);
    procedure btnMoldeDelClick(Sender: TObject);
  private
    FRepo: TMoldeRepo;
    FCentrosDisponibles: TArray<string>;
    FOperacionesDisponibles: TArray<string>;
    FArticulosDisponibles: TArray<string>;
    FUtillajesDisponibles: TArray<string>;

    // Refresh
    procedure RefreshMoldes;
    procedure RefreshCentroMoldes;
    procedure RefreshCentrosAsig;
    procedure RefreshOpMoldes;
    procedure RefreshOpsAsig;
    procedure RefreshArtMoldes;
    procedure RefreshArtAsig;
    procedure RefreshUtMoldes;
    procedure RefreshUtAsig;
    procedure RefreshAll;

    procedure ApplyDarkMode(ADark: Boolean);

    // Focus changed events
    procedure CentroMoldesFocusChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure OpMoldesFocusChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure ArtMoldesFocusChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure UtMoldesFocusChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);

    // Check changed events
    procedure CentrosCheckChanged(Sender: TObject);
    procedure CentrosPreferenteChanged(Sender: TObject);
    procedure OpsCheckChanged(Sender: TObject);
    procedure ArtCheckChanged(Sender: TObject);
    procedure UtCheckChanged(Sender: TObject);
    procedure UtObligatorioChanged(Sender: TObject);

    // Helpers
    function GetSelectedMoldeId: Integer;
    function GetSelectedMoldeIdFrom(AView: TcxGridTableView; AColId: TcxGridColumn): Integer;

    // Input dialog
    function InputMolde(var M: TMolde; const ATitle: string): Boolean;
  public
    class procedure Execute(ARepo: TMoldeRepo;
      const ACentros, AOperaciones, AArticulos, AUtillajes: TArray<string>);
  end;

var
  frmGestionMoldes: TfrmGestionMoldes;

implementation

{$R *.dfm}

{ TfrmGestionMoldes }

class procedure TfrmGestionMoldes.Execute(ARepo: TMoldeRepo;
  const ACentros, AOperaciones, AArticulos, AUtillajes: TArray<string>);
var
  F: TfrmGestionMoldes;
begin
  F := TfrmGestionMoldes.Create(Application);
  try
    F.FRepo := ARepo;
    F.FCentrosDisponibles := ACentros;
    F.FOperacionesDisponibles := AOperaciones;
    F.FArticulosDisponibles := AArticulos;
    F.FUtillajesDisponibles := AUtillajes;
    F.RefreshAll;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmGestionMoldes.FormCreate(Sender: TObject);
begin
  // Centros tab
  tvCentroMoldes.OnFocusedRecordChanged := CentroMoldesFocusChanged;
  (colCentrosAsigCheck.Properties as TcxCheckBoxProperties).OnEditValueChanged := CentrosCheckChanged;
  (colCentrosAsigPreferente.Properties as TcxCheckBoxProperties).OnEditValueChanged := CentrosPreferenteChanged;
  // Operaciones tab
  tvOpMoldes.OnFocusedRecordChanged := OpMoldesFocusChanged;
  (colOpsAsigCheck.Properties as TcxCheckBoxProperties).OnEditValueChanged := OpsCheckChanged;
  // Articulos tab
  tvArtMoldes.OnFocusedRecordChanged := ArtMoldesFocusChanged;
  (colArtAsigCheck.Properties as TcxCheckBoxProperties).OnEditValueChanged := ArtCheckChanged;
  // Utillajes tab
  tvUtMoldes.OnFocusedRecordChanged := UtMoldesFocusChanged;
  (colUtAsigCheck.Properties as TcxCheckBoxProperties).OnEditValueChanged := UtCheckChanged;
  (colUtAsigObligatorio.Properties as TcxCheckBoxProperties).OnEditValueChanged := UtObligatorioChanged;
end;

procedure TfrmGestionMoldes.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure TfrmGestionMoldes.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

{ ========== Refresh ========== }

procedure TfrmGestionMoldes.RefreshAll;
begin
  RefreshMoldes;
  RefreshCentroMoldes;
  RefreshCentrosAsig;
  RefreshOpMoldes;
  RefreshOpsAsig;
  RefreshArtMoldes;
  RefreshArtAsig;
  RefreshUtMoldes;
  RefreshUtAsig;
end;

procedure TfrmGestionMoldes.RefreshMoldes;
var
  Moldes: TArray<TMolde>;
  I: Integer;
begin
  Moldes := FRepo.GetMoldes;
  tvMoldes.BeginUpdate;
  try
    tvMoldes.DataController.RecordCount := 0;
    tvMoldes.DataController.RecordCount := Length(Moldes);
    for I := 0 to High(Moldes) do
    begin
      tvMoldes.DataController.Values[I, colMoldeId.Index] := Moldes[I].IdMolde;
      tvMoldes.DataController.Values[I, colMoldeCodigo.Index] := Moldes[I].CodigoMolde;
      tvMoldes.DataController.Values[I, colMoldeDesc.Index] := Moldes[I].Descripcion;
      tvMoldes.DataController.Values[I, colMoldeTipo.Index] := TipoMoldeToStr(Moldes[I].TipoMolde);
      tvMoldes.DataController.Values[I, colMoldeEstado.Index] := EstadoMoldeToStr(Moldes[I].Estado);
      tvMoldes.DataController.Values[I, colMoldeCavidades.Index] := Moldes[I].NumeroCavidades;
      tvMoldes.DataController.Values[I, colMoldeUbicacion.Index] := Moldes[I].UbicacionActual;
      tvMoldes.DataController.Values[I, colMoldeCentroActual.Index] := Moldes[I].CentroTrabajoActual;
      tvMoldes.DataController.Values[I, colMoldeCentros.Index] := FRepo.GetCentrosStr(Moldes[I].IdMolde);
      tvMoldes.DataController.Values[I, colMoldeOperaciones.Index] := FRepo.GetOperacionesStr(Moldes[I].IdMolde);
    end;
  finally
    tvMoldes.EndUpdate;
  end;
end;

procedure TfrmGestionMoldes.RefreshCentroMoldes;
var
  Moldes: TArray<TMolde>;
  I: Integer;
begin
  Moldes := FRepo.GetMoldes;
  tvCentroMoldes.BeginUpdate;
  try
    tvCentroMoldes.DataController.RecordCount := 0;
    tvCentroMoldes.DataController.RecordCount := Length(Moldes);
    for I := 0 to High(Moldes) do
    begin
      tvCentroMoldes.DataController.Values[I, colCentroMoldeId.Index] := Moldes[I].IdMolde;
      tvCentroMoldes.DataController.Values[I, colCentroMoldeCodigo.Index] := Moldes[I].CodigoMolde + ' - ' + Moldes[I].Descripcion;
    end;
  finally
    tvCentroMoldes.EndUpdate;
  end;
end;

procedure TfrmGestionMoldes.RefreshCentrosAsig;
var
  MoldeId, I: Integer;
  Asig: Boolean;
  Pref: Boolean;
  Centros: TArray<TMoldeCentro>;
  J: Integer;
begin
  MoldeId := GetSelectedMoldeIdFrom(tvCentroMoldes, colCentroMoldeId);
  Centros := nil;
  if MoldeId > 0 then
    Centros := FRepo.GetCentrosByMolde(MoldeId);

  tvCentrosAsig.BeginUpdate;
  try
    tvCentrosAsig.DataController.RecordCount := 0;
    tvCentrosAsig.DataController.RecordCount := Length(FCentrosDisponibles);
    for I := 0 to High(FCentrosDisponibles) do
    begin
      Asig := False;
      Pref := False;
      if MoldeId > 0 then
        for J := 0 to High(Centros) do
          if SameText(Centros[J].CodigoCentro, FCentrosDisponibles[I]) then
          begin
            Asig := True;
            Pref := Centros[J].Preferente;
            Break;
          end;
      tvCentrosAsig.DataController.Values[I, colCentrosAsigNom.Index] := FCentrosDisponibles[I];
      tvCentrosAsig.DataController.Values[I, colCentrosAsigCheck.Index] := Asig;
      tvCentrosAsig.DataController.Values[I, colCentrosAsigPreferente.Index] := Pref;
    end;
    colCentrosAsigCheck.Options.Editing := (MoldeId > 0);
    colCentrosAsigPreferente.Options.Editing := (MoldeId > 0);
  finally
    tvCentrosAsig.EndUpdate;
  end;
end;

procedure TfrmGestionMoldes.RefreshOpMoldes;
var
  Moldes: TArray<TMolde>;
  I: Integer;
begin
  Moldes := FRepo.GetMoldes;
  tvOpMoldes.BeginUpdate;
  try
    tvOpMoldes.DataController.RecordCount := 0;
    tvOpMoldes.DataController.RecordCount := Length(Moldes);
    for I := 0 to High(Moldes) do
    begin
      tvOpMoldes.DataController.Values[I, colOpMoldeId.Index] := Moldes[I].IdMolde;
      tvOpMoldes.DataController.Values[I, colOpMoldeCodigo.Index] := Moldes[I].CodigoMolde + ' - ' + Moldes[I].Descripcion;
    end;
  finally
    tvOpMoldes.EndUpdate;
  end;
end;

procedure TfrmGestionMoldes.RefreshOpsAsig;
var
  MoldeId, I: Integer;
  Asig: Boolean;
begin
  MoldeId := GetSelectedMoldeIdFrom(tvOpMoldes, colOpMoldeId);
  tvOpsAsig.BeginUpdate;
  try
    tvOpsAsig.DataController.RecordCount := 0;
    tvOpsAsig.DataController.RecordCount := Length(FOperacionesDisponibles);
    for I := 0 to High(FOperacionesDisponibles) do
    begin
      Asig := (MoldeId > 0) and FRepo.IsOperacionAsignada(MoldeId, FOperacionesDisponibles[I]);
      tvOpsAsig.DataController.Values[I, colOpsAsigNom.Index] := FOperacionesDisponibles[I];
      tvOpsAsig.DataController.Values[I, colOpsAsigCheck.Index] := Asig;
    end;
    colOpsAsigCheck.Options.Editing := (MoldeId > 0);
  finally
    tvOpsAsig.EndUpdate;
  end;
end;

procedure TfrmGestionMoldes.RefreshArtMoldes;
var
  Moldes: TArray<TMolde>;
  I: Integer;
begin
  Moldes := FRepo.GetMoldes;
  tvArtMoldes.BeginUpdate;
  try
    tvArtMoldes.DataController.RecordCount := 0;
    tvArtMoldes.DataController.RecordCount := Length(Moldes);
    for I := 0 to High(Moldes) do
    begin
      tvArtMoldes.DataController.Values[I, colArtMoldeId.Index] := Moldes[I].IdMolde;
      tvArtMoldes.DataController.Values[I, colArtMoldeCodigo.Index] := Moldes[I].CodigoMolde + ' - ' + Moldes[I].Descripcion;
    end;
  finally
    tvArtMoldes.EndUpdate;
  end;
end;

procedure TfrmGestionMoldes.RefreshArtAsig;
var
  MoldeId, I: Integer;
  Asig: Boolean;
begin
  MoldeId := GetSelectedMoldeIdFrom(tvArtMoldes, colArtMoldeId);
  tvArtAsig.BeginUpdate;
  try
    tvArtAsig.DataController.RecordCount := 0;
    tvArtAsig.DataController.RecordCount := Length(FArticulosDisponibles);
    for I := 0 to High(FArticulosDisponibles) do
    begin
      Asig := (MoldeId > 0) and FRepo.IsArticuloAsignado(MoldeId, FArticulosDisponibles[I]);
      tvArtAsig.DataController.Values[I, colArtAsigNom.Index] := FArticulosDisponibles[I];
      tvArtAsig.DataController.Values[I, colArtAsigCheck.Index] := Asig;
    end;
    colArtAsigCheck.Options.Editing := (MoldeId > 0);
  finally
    tvArtAsig.EndUpdate;
  end;
end;

procedure TfrmGestionMoldes.RefreshUtMoldes;
var
  Moldes: TArray<TMolde>;
  I: Integer;
begin
  Moldes := FRepo.GetMoldes;
  tvUtMoldes.BeginUpdate;
  try
    tvUtMoldes.DataController.RecordCount := 0;
    tvUtMoldes.DataController.RecordCount := Length(Moldes);
    for I := 0 to High(Moldes) do
    begin
      tvUtMoldes.DataController.Values[I, colUtMoldeId.Index] := Moldes[I].IdMolde;
      tvUtMoldes.DataController.Values[I, colUtMoldeCodigo.Index] := Moldes[I].CodigoMolde + ' - ' + Moldes[I].Descripcion;
    end;
  finally
    tvUtMoldes.EndUpdate;
  end;
end;

procedure TfrmGestionMoldes.RefreshUtAsig;
var
  MoldeId, I, J: Integer;
  Asig, Oblig: Boolean;
  Uts: TArray<TMoldeUtillaje>;
begin
  MoldeId := GetSelectedMoldeIdFrom(tvUtMoldes, colUtMoldeId);
  Uts := nil;
  if MoldeId > 0 then
    Uts := FRepo.GetUtillajesByMolde(MoldeId);

  tvUtAsig.BeginUpdate;
  try
    tvUtAsig.DataController.RecordCount := 0;
    tvUtAsig.DataController.RecordCount := Length(FUtillajesDisponibles);
    for I := 0 to High(FUtillajesDisponibles) do
    begin
      Asig := False;
      Oblig := False;
      if MoldeId > 0 then
        for J := 0 to High(Uts) do
          if SameText(Uts[J].CodigoUtillaje, FUtillajesDisponibles[I]) then
          begin
            Asig := True;
            Oblig := Uts[J].Obligatorio;
            Break;
          end;
      tvUtAsig.DataController.Values[I, colUtAsigNom.Index] := FUtillajesDisponibles[I];
      tvUtAsig.DataController.Values[I, colUtAsigCheck.Index] := Asig;
      tvUtAsig.DataController.Values[I, colUtAsigObligatorio.Index] := Oblig;
    end;
    colUtAsigCheck.Options.Editing := (MoldeId > 0);
    colUtAsigObligatorio.Options.Editing := (MoldeId > 0);
  finally
    tvUtAsig.EndUpdate;
  end;
end;

{ ========== Focus changed ========== }

procedure TfrmGestionMoldes.CentroMoldesFocusChanged(Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  RefreshCentrosAsig;
end;

procedure TfrmGestionMoldes.OpMoldesFocusChanged(Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  RefreshOpsAsig;
end;

procedure TfrmGestionMoldes.ArtMoldesFocusChanged(Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  RefreshArtAsig;
end;

procedure TfrmGestionMoldes.UtMoldesFocusChanged(Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  RefreshUtAsig;
end;

{ ========== Check changed ========== }

procedure TfrmGestionMoldes.CentrosCheckChanged(Sender: TObject);
var
  MoldeId, RecIdx: Integer;
  Centro: string;
  Checked: Boolean;
  V: Variant;
begin
  MoldeId := GetSelectedMoldeIdFrom(tvCentroMoldes, colCentroMoldeId);
  if MoldeId <= 0 then Exit;
  RecIdx := tvCentrosAsig.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  Centro := VarToStr(tvCentrosAsig.DataController.Values[RecIdx, colCentrosAsigNom.Index]);
  V := tvCentrosAsig.DataController.Values[RecIdx, colCentrosAsigCheck.Index];
  Checked := not VarIsNull(V) and Boolean(V);

  if Checked then
    FRepo.AssignCentro(MoldeId, Centro, False, 0)
  else
    FRepo.UnassignCentro(MoldeId, Centro);

  RefreshMoldes;
end;

procedure TfrmGestionMoldes.CentrosPreferenteChanged(Sender: TObject);
var
  MoldeId, RecIdx: Integer;
  Centro: string;
  Checked: Boolean;
  V: Variant;
begin
  MoldeId := GetSelectedMoldeIdFrom(tvCentroMoldes, colCentroMoldeId);
  if MoldeId <= 0 then Exit;
  RecIdx := tvCentrosAsig.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  Centro := VarToStr(tvCentrosAsig.DataController.Values[RecIdx, colCentrosAsigNom.Index]);
  V := tvCentrosAsig.DataController.Values[RecIdx, colCentrosAsigPreferente.Index];
  Checked := not VarIsNull(V) and Boolean(V);

  // Solo aplica si el centro ya esta asignado
  if FRepo.IsCentroAsignado(MoldeId, Centro) then
  begin
    FRepo.UnassignCentro(MoldeId, Centro);
    FRepo.AssignCentro(MoldeId, Centro, Checked, 0);
  end;
end;

procedure TfrmGestionMoldes.OpsCheckChanged(Sender: TObject);
var
  MoldeId, RecIdx: Integer;
  Operacion: string;
  Checked: Boolean;
  V: Variant;
begin
  MoldeId := GetSelectedMoldeIdFrom(tvOpMoldes, colOpMoldeId);
  if MoldeId <= 0 then Exit;
  RecIdx := tvOpsAsig.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  Operacion := VarToStr(tvOpsAsig.DataController.Values[RecIdx, colOpsAsigNom.Index]);
  V := tvOpsAsig.DataController.Values[RecIdx, colOpsAsigCheck.Index];
  Checked := not VarIsNull(V) and Boolean(V);

  if Checked then
    FRepo.AssignOperacion(MoldeId, Operacion, 0, '')
  else
    FRepo.UnassignOperacion(MoldeId, Operacion);

  RefreshMoldes;
end;

procedure TfrmGestionMoldes.ArtCheckChanged(Sender: TObject);
var
  MoldeId, RecIdx: Integer;
  Articulo: string;
  Checked: Boolean;
  V: Variant;
begin
  MoldeId := GetSelectedMoldeIdFrom(tvArtMoldes, colArtMoldeId);
  if MoldeId <= 0 then Exit;
  RecIdx := tvArtAsig.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  Articulo := VarToStr(tvArtAsig.DataController.Values[RecIdx, colArtAsigNom.Index]);
  V := tvArtAsig.DataController.Values[RecIdx, colArtAsigCheck.Index];
  Checked := not VarIsNull(V) and Boolean(V);

  if Checked then
    FRepo.AssignArticulo(MoldeId, Articulo, 0, '')
  else
    FRepo.UnassignArticulo(MoldeId, Articulo);

  RefreshMoldes;
end;

procedure TfrmGestionMoldes.UtCheckChanged(Sender: TObject);
var
  MoldeId, RecIdx: Integer;
  Utillaje: string;
  Checked: Boolean;
  V: Variant;
begin
  MoldeId := GetSelectedMoldeIdFrom(tvUtMoldes, colUtMoldeId);
  if MoldeId <= 0 then Exit;
  RecIdx := tvUtAsig.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  Utillaje := VarToStr(tvUtAsig.DataController.Values[RecIdx, colUtAsigNom.Index]);
  V := tvUtAsig.DataController.Values[RecIdx, colUtAsigCheck.Index];
  Checked := not VarIsNull(V) and Boolean(V);

  if Checked then
    FRepo.AssignUtillaje(MoldeId, Utillaje, False, '')
  else
    FRepo.UnassignUtillaje(MoldeId, Utillaje);

  RefreshMoldes;
end;

procedure TfrmGestionMoldes.UtObligatorioChanged(Sender: TObject);
var
  MoldeId, RecIdx: Integer;
  Utillaje: string;
  Checked: Boolean;
  V: Variant;
begin
  MoldeId := GetSelectedMoldeIdFrom(tvUtMoldes, colUtMoldeId);
  if MoldeId <= 0 then Exit;
  RecIdx := tvUtAsig.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  Utillaje := VarToStr(tvUtAsig.DataController.Values[RecIdx, colUtAsigNom.Index]);
  V := tvUtAsig.DataController.Values[RecIdx, colUtAsigObligatorio.Index];
  Checked := not VarIsNull(V) and Boolean(V);

  if FRepo.IsUtillajeAsignado(MoldeId, Utillaje) then
  begin
    FRepo.UnassignUtillaje(MoldeId, Utillaje);
    FRepo.AssignUtillaje(MoldeId, Utillaje, Checked, '');
  end;
end;

{ ========== Moldes CRUD ========== }

procedure TfrmGestionMoldes.btnMoldeAddClick(Sender: TObject);
var
  M: TMolde;
begin
  FillChar(M, SizeOf(M), 0);
  M.Estado := emDisponible;
  M.DisponiblePlanificacion := True;
  M.NumeroCavidades := 1;
  if InputMolde(M, 'Nuevo Molde') then
  begin
    FRepo.AddMolde(M);
    RefreshAll;
  end;
end;

procedure TfrmGestionMoldes.btnMoldeEditClick(Sender: TObject);
var
  MId: Integer;
  M: TMolde;
begin
  MId := GetSelectedMoldeId;
  if MId <= 0 then Exit;
  if not FRepo.GetMoldeById(MId, M) then Exit;

  if InputMolde(M, 'Editar Molde') then
  begin
    FRepo.UpdateMolde(M);
    RefreshAll;
  end;
end;

procedure TfrmGestionMoldes.btnMoldeDelClick(Sender: TObject);
var
  MId: Integer;
  M: TMolde;
begin
  MId := GetSelectedMoldeId;
  if MId <= 0 then Exit;
  if not FRepo.GetMoldeById(MId, M) then Exit;

  if MessageDlg('Eliminar molde "' + M.CodigoMolde + ' - ' + M.Descripcion + '"?' + sLineBreak +
    'Se eliminar'#225'n todas las relaciones asociadas.',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FRepo.RemoveMolde(MId);
    RefreshAll;
  end;
end;

{ ========== Helpers ========== }

function TfrmGestionMoldes.GetSelectedMoldeId: Integer;
begin
  Result := GetSelectedMoldeIdFrom(tvMoldes, colMoldeId);
end;

function TfrmGestionMoldes.GetSelectedMoldeIdFrom(AView: TcxGridTableView; AColId: TcxGridColumn): Integer;
var
  Idx: Integer;
  V: Variant;
begin
  Result := -1;
  Idx := AView.DataController.FocusedRecordIndex;
  if Idx < 0 then Exit;
  V := AView.DataController.Values[Idx, AColId.Index];
  if not VarIsNull(V) then
    Result := V;
end;

{ ========== Input Dialog ========== }

function TfrmGestionMoldes.InputMolde(var M: TMolde; const ATitle: string): Boolean;
var
  Dlg: TForm;
  edCodigo, edDesc, edUbicacion, edCentroActual, edObs: TEdit;
  edCavidades: TEdit;
  edTiempoMontaje, edTiempoDesmontaje, edTiempoAjuste: TEdit;
  cbTipo, cbEstado: TComboBox;
  chkDisponible: TCheckBox;
  lbls: array[0..11] of TLabel;
  btnOk, btnCa: TButton;
  I, Y: Integer;

  procedure AddRow(AIdx: Integer; const ACaption: string; ATop: Integer);
  begin
    lbls[AIdx] := TLabel.Create(Dlg);
    lbls[AIdx].Parent := Dlg;
    lbls[AIdx].SetBounds(16, ATop + 2, 130, 20);
    lbls[AIdx].Caption := ACaption;
  end;

begin
  Dlg := TForm.CreateNew(Self);
  try
    Dlg.Caption := ATitle;
    Dlg.Width := 520;
    Dlg.Height := 480;
    Dlg.Position := poScreenCenter;
    Dlg.BorderStyle := bsDialog;
    Dlg.Font.Name := 'Segoe UI';
    Dlg.Font.Size := 9;

    Y := 14;

    // Codigo
    AddRow(0, 'C'#243'digo:', Y);
    edCodigo := TEdit.Create(Dlg);
    edCodigo.Parent := Dlg;
    edCodigo.SetBounds(150, Y, 340, 24);
    edCodigo.Text := M.CodigoMolde;
    Inc(Y, 32);

    // Descripcion
    AddRow(1, 'Descripci'#243'n:', Y);
    edDesc := TEdit.Create(Dlg);
    edDesc.Parent := Dlg;
    edDesc.SetBounds(150, Y, 340, 24);
    edDesc.Text := M.Descripcion;
    Inc(Y, 32);

    // Tipo
    AddRow(2, 'Tipo:', Y);
    cbTipo := TComboBox.Create(Dlg);
    cbTipo.Parent := Dlg;
    cbTipo.Style := csDropDownList;
    cbTipo.SetBounds(150, Y, 200, 24);
    cbTipo.Items.Add('Inyeccion');
    cbTipo.Items.Add('Soplado');
    cbTipo.Items.Add('Compresion');
    cbTipo.Items.Add('Extrusion');
    cbTipo.Items.Add('Otro');
    cbTipo.ItemIndex := Ord(M.TipoMolde);
    Inc(Y, 32);

    // Estado
    AddRow(3, 'Estado:', Y);
    cbEstado := TComboBox.Create(Dlg);
    cbEstado.Parent := Dlg;
    cbEstado.Style := csDropDownList;
    cbEstado.SetBounds(150, Y, 200, 24);
    cbEstado.Items.Add('Disponible');
    cbEstado.Items.Add('Montado');
    cbEstado.Items.Add('Reservado');
    cbEstado.Items.Add('Mantenimiento');
    cbEstado.Items.Add('Averiado');
    cbEstado.Items.Add('Bloqueado');
    cbEstado.Items.Add('Baja');
    cbEstado.ItemIndex := Ord(M.Estado);
    Inc(Y, 32);

    // Ubicacion
    AddRow(4, 'Ubicaci'#243'n:', Y);
    edUbicacion := TEdit.Create(Dlg);
    edUbicacion.Parent := Dlg;
    edUbicacion.SetBounds(150, Y, 340, 24);
    edUbicacion.Text := M.UbicacionActual;
    Inc(Y, 32);

    // Centro actual
    AddRow(5, 'Centro Actual:', Y);
    edCentroActual := TEdit.Create(Dlg);
    edCentroActual.Parent := Dlg;
    edCentroActual.SetBounds(150, Y, 340, 24);
    edCentroActual.Text := M.CentroTrabajoActual;
    Inc(Y, 32);

    // Cavidades
    AddRow(6, 'N'#186' Cavidades:', Y);
    edCavidades := TEdit.Create(Dlg);
    edCavidades.Parent := Dlg;
    edCavidades.SetBounds(150, Y, 80, 24);
    edCavidades.Text := IntToStr(M.NumeroCavidades);
    Inc(Y, 32);

    // Tiempos
    AddRow(7, 'T. Montaje (min):', Y);
    edTiempoMontaje := TEdit.Create(Dlg);
    edTiempoMontaje.Parent := Dlg;
    edTiempoMontaje.SetBounds(150, Y, 80, 24);
    edTiempoMontaje.Text := FormatFloat('0.##', M.TiempoMontaje);
    Inc(Y, 32);

    AddRow(8, 'T. Desmontaje (min):', Y);
    edTiempoDesmontaje := TEdit.Create(Dlg);
    edTiempoDesmontaje.Parent := Dlg;
    edTiempoDesmontaje.SetBounds(150, Y, 80, 24);
    edTiempoDesmontaje.Text := FormatFloat('0.##', M.TiempoDesmontaje);
    Inc(Y, 32);

    AddRow(9, 'T. Ajuste (min):', Y);
    edTiempoAjuste := TEdit.Create(Dlg);
    edTiempoAjuste.Parent := Dlg;
    edTiempoAjuste.SetBounds(150, Y, 80, 24);
    edTiempoAjuste.Text := FormatFloat('0.##', M.TiempoAjuste);
    Inc(Y, 32);

    // Disponible planificacion
    chkDisponible := TCheckBox.Create(Dlg);
    chkDisponible.Parent := Dlg;
    chkDisponible.SetBounds(150, Y, 200, 20);
    chkDisponible.Caption := 'Disponible para planificaci'#243'n';
    chkDisponible.Checked := M.DisponiblePlanificacion;
    Inc(Y, 32);

    // Observaciones
    AddRow(10, 'Observaciones:', Y);
    edObs := TEdit.Create(Dlg);
    edObs.Parent := Dlg;
    edObs.SetBounds(150, Y, 340, 24);
    edObs.Text := M.Observaciones;
    Inc(Y, 40);

    // Botones
    btnOk := TButton.Create(Dlg);
    btnOk.Parent := Dlg;
    btnOk.SetBounds(320, Y, 80, 28);
    btnOk.Caption := 'OK';
    btnOk.Default := True;
    btnOk.ModalResult := mrOk;

    btnCa := TButton.Create(Dlg);
    btnCa.Parent := Dlg;
    btnCa.SetBounds(410, Y, 80, 28);
    btnCa.Caption := 'Cancelar';
    btnCa.Cancel := True;
    btnCa.ModalResult := mrCancel;

    Dlg.ClientHeight := Y + 40;

    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      M.CodigoMolde := Trim(edCodigo.Text);
      M.Descripcion := Trim(edDesc.Text);
      if M.CodigoMolde = '' then
      begin
        Result := False;
        Exit;
      end;
      M.TipoMolde := TTipoMolde(cbTipo.ItemIndex);
      M.Estado := TEstadoMolde(cbEstado.ItemIndex);
      M.UbicacionActual := Trim(edUbicacion.Text);
      M.CentroTrabajoActual := Trim(edCentroActual.Text);
      M.NumeroCavidades := StrToIntDef(edCavidades.Text, 1);
      M.TiempoMontaje := StrToFloatDef(edTiempoMontaje.Text, 0);
      M.TiempoDesmontaje := StrToFloatDef(edTiempoDesmontaje.Text, 0);
      M.TiempoAjuste := StrToFloatDef(edTiempoAjuste.Text, 0);
      M.DisponiblePlanificacion := chkDisponible.Checked;
      M.Observaciones := Trim(edObs.Text);
    end;
  finally
    Dlg.Free;
  end;
end;

{ ========== Dark Mode ========== }

procedure TfrmGestionMoldes.chkDarkModeClick(Sender: TObject);
begin
  ApplyDarkMode(chkDarkMode.Checked);
end;

procedure TfrmGestionMoldes.ApplyDarkMode(ADark: Boolean);
const
  DARK_BG     = $00302C28;
  DARK_HEADER = $003C3836;
  DARK_TEXT   = $00F0F0F0;
  DARK_SUB    = $00A0A0A0;
  DARK_LINE   = $00504840;
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
    pnlHeader.Color := clWhite;
    lblTitle.Font.Color := 4474440;
    lblSubtitle.Font.Color := clGray;
    shpHeaderLine.Brush.Color := 15061727;
    chkDarkMode.Font.Color := clWindowText;
    pnlBottom.Color := clBtnFace;
    Color := clBtnFace;
  end;
end;

end.
