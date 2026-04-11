unit uGestionCentres;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxSpinEdit,
  cxCheckBox, cxContainer, cxClasses, cxFilter, cxPC,
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
  dxSkinXmas2008Blue, dxScrollbarAnnotations,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges,
  // Project
  uGanttTypes, uCentreInspector, uSampleDataGenerator;

type
  TfrmGestionCentres = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    pnlBottom: TPanel;
    btnClose: TButton;
    pc: TcxPageControl;
    LookAndFeel: TcxLookAndFeelController;
    // Tab Areas
    tabAreas: TcxTabSheet;
    pnlAreaToolbar: TPanel;
    btnAreaAdd: TButton;
    btnAreaEdit: TButton;
    btnAreaDel: TButton;
    gridAreas: TcxGrid;
    tvAreas: TcxGridTableView;
    colAreaNom: TcxGridColumn;
    colAreaCentros: TcxGridColumn;
    lvAreas: TcxGridLevel;
    // Tab Centros
    tabCentros: TcxTabSheet;
    pnlCentroToolbar: TPanel;
    btnCentroEdit: TButton;
    gridCentros: TcxGrid;
    tvCentros: TcxGridTableView;
    colCentroId: TcxGridColumn;
    colCentroCodi: TcxGridColumn;
    colCentroTitulo: TcxGridColumn;
    colCentroSubtitulo: TcxGridColumn;
    colCentroArea: TcxGridColumn;
    colCentroSeq: TcxGridColumn;
    colCentroMaxLanes: TcxGridColumn;
    colCentroOrder: TcxGridColumn;
    colCentroVisible: TcxGridColumn;
    colCentroEnabled: TcxGridColumn;
    lvCentros: TcxGridLevel;
    // Tab Asignacion
    tabAsignacion: TcxTabSheet;
    splAsig: TSplitter;
    pnlAsigLeft: TPanel;
    lblAsigCentro: TLabel;
    gridAsigCentros: TcxGrid;
    tvAsigCentros: TcxGridTableView;
    colAsigCentroId: TcxGridColumn;
    colAsigCentroTitulo: TcxGridColumn;
    lvAsigCentros: TcxGridLevel;
    pnlAsigRight: TPanel;
    lblAsigAreas: TLabel;
    gridAsigAreas: TcxGrid;
    tvAsigAreas: TcxGridTableView;
    colAsigAreaNom: TcxGridColumn;
    colAsigAreaCheck: TcxGridColumn;
    lvAsigAreas: TcxGridLevel;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCloseClick(Sender: TObject);
    // Areas
    procedure btnAreaAddClick(Sender: TObject);
    procedure btnAreaEditClick(Sender: TObject);
    procedure btnAreaDelClick(Sender: TObject);
    // Centros
    procedure btnCentroEditClick(Sender: TObject);
    procedure CentroColumnChanged(Sender: TObject);
  private
    FCentres: TArray<TCentreTreball>;
    FCalendarios: TArray<TSampleCalendario>;
    FCalendarioCentro: TArray<Integer>;
    FAreas: TList<string>;

    // Refresh
    procedure RefreshAreas;
    procedure RefreshCentros;
    procedure RefreshAsigCentros;
    procedure RefreshAsigAreas;
    procedure RefreshAll;

    // Asignacion events
    procedure AsigCentroFocusChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure AsigAreaCheckChanged(Sender: TObject);
    procedure WMRefreshAfterCheck(var Msg: TMessage); message WM_USER + 100;

    // Helpers
    function GetSelectedAreaName: string;
    function GetSelectedCentreIdx: Integer;
    function GetSelectedAsigCentreIdx: Integer;
    function CentreAreasStr(const ACentre: TCentreTreball): string;
    function AreaCentrosStr(const AArea: string): string;
    procedure RebuildAreaList;
    function InputArea(var ANombre: string; const ATitle: string): Boolean;

    // Area helpers en el camp Area del centre (CSV)
    class function AreaContains(const AAreaField, AArea: string): Boolean;
    class function AreaAdd(const AAreaField, AArea: string): string;
    class function AreaRemove(const AAreaField, AArea: string): string;
    class function AreaSplit(const AAreaField: string): TArray<string>;
  public
    class function Execute(var ACentres: TArray<TCentreTreball>;
      const ACalendarios: TArray<TSampleCalendario> = nil;
      const ACalendarioCentro: TArray<Integer> = nil): Boolean;
  end;

implementation

{$R *.dfm}

{ ========== Area CSV helpers ========== }

class function TfrmGestionCentres.AreaSplit(const AAreaField: string): TArray<string>;
var
  Parts: TArray<string>;
  I, N: Integer;
  S: string;
begin
  if Trim(AAreaField) = '' then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  Parts := AAreaField.Split([',']);
  N := 0;
  SetLength(Result, Length(Parts));
  for I := 0 to High(Parts) do
  begin
    S := Trim(Parts[I]);
    if S <> '' then
    begin
      Result[N] := S;
      Inc(N);
    end;
  end;
  SetLength(Result, N);
end;

class function TfrmGestionCentres.AreaContains(const AAreaField, AArea: string): Boolean;
var
  Arr: TArray<string>;
  S: string;
begin
  Result := False;
  Arr := AreaSplit(AAreaField);
  for S in Arr do
    if SameText(S, AArea) then
      Exit(True);
end;

class function TfrmGestionCentres.AreaAdd(const AAreaField, AArea: string): string;
begin
  if AreaContains(AAreaField, AArea) then
    Exit(AAreaField);
  if Trim(AAreaField) = '' then
    Result := AArea
  else
    Result := AAreaField + ', ' + AArea;
end;

class function TfrmGestionCentres.AreaRemove(const AAreaField, AArea: string): string;
var
  Arr: TArray<string>;
  S: string;
  First: Boolean;
begin
  Result := '';
  First := True;
  Arr := AreaSplit(AAreaField);
  for S in Arr do
    if not SameText(S, AArea) then
    begin
      if not First then
        Result := Result + ', ';
      Result := Result + S;
      First := False;
    end;
end;

{ ========== Execute ========== }

class function TfrmGestionCentres.Execute(var ACentres: TArray<TCentreTreball>;
  const ACalendarios: TArray<TSampleCalendario>;
  const ACalendarioCentro: TArray<Integer>): Boolean;
var
  F: TfrmGestionCentres;
begin
  F := TfrmGestionCentres.Create(Application);
  try
    F.FCentres := Copy(ACentres);
    F.FCalendarios := ACalendarios;
    F.FCalendarioCentro := ACalendarioCentro;
    F.FAreas := TList<string>.Create;
    try
      F.RebuildAreaList;
      F.RefreshAll;
      Result := F.ShowModal = mrOk;
      if Result then
        ACentres := Copy(F.FCentres);
    finally
      F.FAreas.Free;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmGestionCentres.FormCreate(Sender: TObject);
begin
  (colCentroVisible.Properties as TcxCheckBoxProperties).OnEditValueChanged := CentroColumnChanged;
  (colCentroEnabled.Properties as TcxCheckBoxProperties).OnEditValueChanged := CentroColumnChanged;
  (colCentroOrder.Properties as TcxSpinEditProperties).OnEditValueChanged := CentroColumnChanged;
  tvAsigCentros.OnFocusedRecordChanged := AsigCentroFocusChanged;
  (colAsigAreaCheck.Properties as TcxCheckBoxProperties).OnEditValueChanged := AsigAreaCheckChanged;
end;

procedure TfrmGestionCentres.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrOk;
end;

procedure TfrmGestionCentres.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

{ ========== Rebuild Area List ========== }

const
  DEFAULT_AREAS: array[0..7] of string = (
    'F'#225'brica',
    'Log'#237'stica',
    'Oficina T'#233'cnica',
    'Calidad',
    'Mantenimiento',
    'Almac'#233'n',
    'Expediciones',
    'Subcontrataci'#243'n'
  );

procedure TfrmGestionCentres.RebuildAreaList;
var
  I: Integer;
  Arr: TArray<string>;
  S: string;
begin
  FAreas.Clear;

  // Areas por defecto siempre presentes
  for I := 0 to High(DEFAULT_AREAS) do
    if not FAreas.Contains(DEFAULT_AREAS[I]) then
      FAreas.Add(DEFAULT_AREAS[I]);

  // Areas extra que vengan de los centros
  for I := 0 to High(FCentres) do
  begin
    Arr := AreaSplit(FCentres[I].Area);
    for S in Arr do
      if not FAreas.Contains(S) then
        FAreas.Add(S);
  end;
  FAreas.Sort;
end;

{ ========== Refresh ========== }

procedure TfrmGestionCentres.RefreshAll;
begin
  RefreshAreas;
  RefreshCentros;
  RefreshAsigCentros;
  RefreshAsigAreas;
end;

procedure TfrmGestionCentres.RefreshAreas;
var
  I: Integer;
begin
  tvAreas.BeginUpdate;
  try
    tvAreas.DataController.RecordCount := 0;
    tvAreas.DataController.RecordCount := FAreas.Count;
    for I := 0 to FAreas.Count - 1 do
    begin
      tvAreas.DataController.Values[I, colAreaNom.Index] := FAreas[I];
      tvAreas.DataController.Values[I, colAreaCentros.Index] := AreaCentrosStr(FAreas[I]);
    end;
  finally
    tvAreas.EndUpdate;
  end;
end;

procedure TfrmGestionCentres.RefreshCentros;
var
  I: Integer;
  C: TCentreTreball;
begin
  tvCentros.BeginUpdate;
  try
    tvCentros.DataController.RecordCount := 0;
    tvCentros.DataController.RecordCount := Length(FCentres);
    for I := 0 to High(FCentres) do
    begin
      C := FCentres[I];
      tvCentros.DataController.Values[I, colCentroId.Index] := C.Id;
      tvCentros.DataController.Values[I, colCentroCodi.Index] := C.CodiCentre;
      tvCentros.DataController.Values[I, colCentroTitulo.Index] := C.Titulo;
      tvCentros.DataController.Values[I, colCentroSubtitulo.Index] := C.Subtitulo;
      tvCentros.DataController.Values[I, colCentroArea.Index] := C.Area;
      if C.IsSequencial then
        tvCentros.DataController.Values[I, colCentroSeq.Index] := 'S'#237
      else
        tvCentros.DataController.Values[I, colCentroSeq.Index] := 'No';
      tvCentros.DataController.Values[I, colCentroMaxLanes.Index] := C.MaxLaneCount;
      tvCentros.DataController.Values[I, colCentroOrder.Index] := C.Order;
      tvCentros.DataController.Values[I, colCentroVisible.Index] := C.Visible;
      tvCentros.DataController.Values[I, colCentroEnabled.Index] := C.Enabled;
    end;
  finally
    tvCentros.EndUpdate;
  end;
end;

procedure TfrmGestionCentres.RefreshAsigCentros;
var
  I: Integer;
begin
  tvAsigCentros.BeginUpdate;
  try
    tvAsigCentros.DataController.RecordCount := 0;
    tvAsigCentros.DataController.RecordCount := Length(FCentres);
    for I := 0 to High(FCentres) do
    begin
      tvAsigCentros.DataController.Values[I, colAsigCentroId.Index] := FCentres[I].Id;
      tvAsigCentros.DataController.Values[I, colAsigCentroTitulo.Index] := FCentres[I].Titulo;
    end;
  finally
    tvAsigCentros.EndUpdate;
  end;
end;

procedure TfrmGestionCentres.RefreshAsigAreas;
var
  CIdx, I: Integer;
  HasArea: Boolean;
begin
  CIdx := GetSelectedAsigCentreIdx;
  tvAsigAreas.BeginUpdate;
  try
    tvAsigAreas.DataController.RecordCount := 0;
    tvAsigAreas.DataController.RecordCount := FAreas.Count;
    for I := 0 to FAreas.Count - 1 do
    begin
      HasArea := (CIdx >= 0) and AreaContains(FCentres[CIdx].Area, FAreas[I]);
      tvAsigAreas.DataController.Values[I, colAsigAreaNom.Index] := FAreas[I];
      tvAsigAreas.DataController.Values[I, colAsigAreaCheck.Index] := HasArea;
    end;
    colAsigAreaCheck.Options.Editing := (CIdx >= 0);
  finally
    tvAsigAreas.EndUpdate;
  end;
end;

{ ========== Asignacion events ========== }

procedure TfrmGestionCentres.AsigCentroFocusChanged(Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  RefreshAsigAreas;
end;

procedure TfrmGestionCentres.AsigAreaCheckChanged(Sender: TObject);
var
  CIdx, RecIdx: Integer;
  AreaName: string;
  Checked: Boolean;
  V: Variant;
begin
  if not Assigned(FAreas) then Exit;

  CIdx := GetSelectedAsigCentreIdx;
  if CIdx < 0 then Exit;

  RecIdx := tvAsigAreas.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  AreaName := VarToStr(tvAsigAreas.DataController.Values[RecIdx, colAsigAreaNom.Index]);

  // El valor al DataController encara és l'antic; invertim-lo
  V := tvAsigAreas.DataController.Values[RecIdx, colAsigAreaCheck.Index];
  if VarIsNull(V) then
    Checked := True   // si era null (no marcat), ara serà marcat
  else
    Checked := not Boolean(V);

  if Checked then
    FCentres[CIdx].Area := AreaAdd(FCentres[CIdx].Area, AreaName)
  else
    FCentres[CIdx].Area := AreaRemove(FCentres[CIdx].Area, AreaName);

  // Actualizar grids dependientes (posposar per evitar conflicte amb l'edicio en curs)
  PostMessage(Handle, WM_USER + 100, 0, 0);
end;

procedure TfrmGestionCentres.WMRefreshAfterCheck(var Msg: TMessage);
begin
  RefreshCentros;
  RefreshAreas;
end;

{ ========== Areas CRUD ========== }

procedure TfrmGestionCentres.btnAreaAddClick(Sender: TObject);
var
  Nom: string;
begin
  Nom := '';
  if InputArea(Nom, 'Nueva '#193'rea') then
  begin
    if not FAreas.Contains(Nom) then
      FAreas.Add(Nom);
    FAreas.Sort;
    RefreshAreas;
    RefreshAsigAreas;
  end;
end;

procedure TfrmGestionCentres.btnAreaEditClick(Sender: TObject);
var
  OldNom, NewNom: string;
  I: Integer;
begin
  OldNom := GetSelectedAreaName;
  if OldNom = '' then Exit;

  NewNom := OldNom;
  if InputArea(NewNom, 'Editar '#193'rea') and (NewNom <> OldNom) then
  begin
    // Renombrar en todos los centros
    for I := 0 to High(FCentres) do
      if AreaContains(FCentres[I].Area, OldNom) then
      begin
        FCentres[I].Area := AreaRemove(FCentres[I].Area, OldNom);
        FCentres[I].Area := AreaAdd(FCentres[I].Area, NewNom);
      end;

    // Renombrar en la lista
    I := FAreas.IndexOf(OldNom);
    if I >= 0 then
      FAreas[I] := NewNom;
    FAreas.Sort;

    RefreshAll;
  end;
end;

procedure TfrmGestionCentres.btnAreaDelClick(Sender: TObject);
var
  Nom: string;
  I: Integer;
begin
  Nom := GetSelectedAreaName;
  if Nom = '' then Exit;

  if MessageDlg(#191'Eliminar '#225'rea "' + Nom + '"?' + sLineBreak +
    'Se desasignar'#225' de todos los centros.',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    // Quitar de todos los centros
    for I := 0 to High(FCentres) do
      if AreaContains(FCentres[I].Area, Nom) then
        FCentres[I].Area := AreaRemove(FCentres[I].Area, Nom);

    FAreas.Remove(Nom);
    RefreshAll;
  end;
end;

{ ========== Centros ========== }

procedure TfrmGestionCentres.CentroColumnChanged(Sender: TObject);
var
  RecIdx, I: Integer;
  V: Variant;
  CId: Integer;
begin
  RecIdx := tvCentros.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  V := tvCentros.DataController.Values[RecIdx, colCentroId.Index];
  if VarIsNull(V) then Exit;
  CId := V;

  // Trobar index a FCentres
  for I := 0 to High(FCentres) do
    if FCentres[I].Id = CId then
    begin
      // Llegir tots els camps editables
      V := tvCentros.DataController.Values[RecIdx, colCentroVisible.Index];
      if not VarIsNull(V) then
        FCentres[I].Visible := Boolean(V);

      V := tvCentros.DataController.Values[RecIdx, colCentroEnabled.Index];
      if not VarIsNull(V) then
        FCentres[I].Enabled := Boolean(V);

      V := tvCentros.DataController.Values[RecIdx, colCentroOrder.Index];
      if not VarIsNull(V) then
        FCentres[I].Order := Integer(V);

      Break;
    end;
end;

procedure TfrmGestionCentres.btnCentroEditClick(Sender: TObject);
var
  CIdx, CalIdx: Integer;
  C: TCentreTreball;
  PCal: PSampleCalendario;
begin
  CIdx := GetSelectedCentreIdx;
  if CIdx < 0 then Exit;

  C := FCentres[CIdx];

  // Buscar calendario asociado a este centro
  PCal := nil;
  if (Length(FCalendarioCentro) > CIdx) and (Length(FCalendarios) > 0) then
  begin
    CalIdx := FCalendarioCentro[CIdx];
    if (CalIdx >= 0) and (CalIdx <= High(FCalendarios)) then
      PCal := @FCalendarios[CalIdx];
  end;

  if TfrmCentreInspector.Execute(C, False, PCal) then
  begin
    FCentres[CIdx] := C;
    RebuildAreaList;
    RefreshAll;
  end;
end;

{ ========== Helpers ========== }

function TfrmGestionCentres.GetSelectedAreaName: string;
var
  Idx: Integer;
  V: Variant;
begin
  Result := '';
  Idx := tvAreas.DataController.FocusedRecordIndex;
  if Idx < 0 then Exit;
  V := tvAreas.DataController.Values[Idx, colAreaNom.Index];
  if not VarIsNull(V) then
    Result := VarToStr(V);
end;

function TfrmGestionCentres.GetSelectedCentreIdx: Integer;
var
  Idx: Integer;
  V: Variant;
  CId, I: Integer;
begin
  Result := -1;
  Idx := tvCentros.DataController.FocusedRecordIndex;
  if Idx < 0 then Exit;
  V := tvCentros.DataController.Values[Idx, colCentroId.Index];
  if VarIsNull(V) then Exit;
  CId := V;
  for I := 0 to High(FCentres) do
    if FCentres[I].Id = CId then
      Exit(I);
end;

function TfrmGestionCentres.GetSelectedAsigCentreIdx: Integer;
var
  Idx: Integer;
  V: Variant;
  CId, I: Integer;
begin
  Result := -1;
  Idx := tvAsigCentros.DataController.FocusedRecordIndex;
  if Idx < 0 then Exit;
  V := tvAsigCentros.DataController.Values[Idx, colAsigCentroId.Index];
  if VarIsNull(V) then Exit;
  CId := V;
  for I := 0 to High(FCentres) do
    if FCentres[I].Id = CId then
      Exit(I);
end;

function TfrmGestionCentres.CentreAreasStr(const ACentre: TCentreTreball): string;
begin
  Result := ACentre.Area;
end;

function TfrmGestionCentres.AreaCentrosStr(const AArea: string): string;
var
  I: Integer;
  First: Boolean;
begin
  Result := '';
  First := True;
  for I := 0 to High(FCentres) do
    if AreaContains(FCentres[I].Area, AArea) then
    begin
      if not First then
        Result := Result + ', ';
      Result := Result + FCentres[I].Titulo;
      First := False;
    end;
end;

function TfrmGestionCentres.InputArea(var ANombre: string; const ATitle: string): Boolean;
var
  Dlg: TForm;
  edNom: TEdit;
  lblN: TLabel;
  btnOk, btnCa: TButton;
begin
  Dlg := TForm.CreateNew(Self);
  try
    Dlg.Caption := ATitle;
    Dlg.Width := 400;
    Dlg.Height := 130;
    Dlg.Position := poScreenCenter;
    Dlg.BorderStyle := bsDialog;
    Dlg.Font.Name := 'Segoe UI';
    Dlg.Font.Size := 9;

    lblN := TLabel.Create(Dlg);
    lblN.Parent := Dlg;
    lblN.SetBounds(16, 16, 60, 20);
    lblN.Caption := 'Nombre:';

    edNom := TEdit.Create(Dlg);
    edNom.Parent := Dlg;
    edNom.SetBounds(100, 14, 270, 24);
    edNom.Text := ANombre;

    btnOk := TButton.Create(Dlg);
    btnOk.Parent := Dlg;
    btnOk.SetBounds(200, 56, 80, 28);
    btnOk.Caption := 'OK';
    btnOk.Default := True;
    btnOk.ModalResult := mrOk;

    btnCa := TButton.Create(Dlg);
    btnCa.Parent := Dlg;
    btnCa.SetBounds(290, 56, 80, 28);
    btnCa.Caption := 'Cancelar';
    btnCa.Cancel := True;
    btnCa.ModalResult := mrCancel;

    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      ANombre := Trim(edNom.Text);
      if ANombre = '' then
        Result := False;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
