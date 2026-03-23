unit uGestionOperaris;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst,
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
  uOperariosTypes, uOperariosRepo, dxBarBuiltInMenu, cxCustomData, cxData,
  cxDataStorage, cxNavigator, dxDateRanges;

type
  TfrmGestionOperaris = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    shpHeaderLine: TShape;
    chkDarkMode: TCheckBox;
    pnlBottom: TPanel;
    btnTancar: TButton;
    pc: TcxPageControl;
    tabDepartaments: TcxTabSheet;
    tabOperaris: TcxTabSheet;
    tabCapacitacions: TcxTabSheet;
    LookAndFeel: TcxLookAndFeelController;
    // Tab Departaments
    pnlDeptToolbar: TPanel;
    btnDeptAdd: TButton;
    btnDeptEdit: TButton;
    btnDeptDel: TButton;
    gridDepts: TcxGrid;
    tvDepts: TcxGridTableView;
    colDeptId: TcxGridColumn;
    colDeptNom: TcxGridColumn;
    colDeptDesc: TcxGridColumn;
    colDeptOperaris: TcxGridColumn;
    lvDepts: TcxGridLevel;
    // Tab Operaris
    pnlOpToolbar: TPanel;
    btnOpAdd: TButton;
    btnOpEdit: TButton;
    btnOpDel: TButton;
    gridOperaris: TcxGrid;
    tvOperaris: TcxGridTableView;
    colOpId: TcxGridColumn;
    colOpNom: TcxGridColumn;
    colOpCalendari: TcxGridColumn;
    colOpDepts: TcxGridColumn;
    colOpCaps: TcxGridColumn;
    lvOperaris: TcxGridLevel;
    // Tab Capacitacions
    splCap: TSplitter;
    pnlCapLeft: TPanel;
    lblCapOperari: TLabel;
    gridCapOperaris: TcxGrid;
    tvCapOperaris: TcxGridTableView;
    colCapOpId: TcxGridColumn;
    colCapOpNom: TcxGridColumn;
    lvCapOperaris: TcxGridLevel;
    pnlCapRight: TPanel;
    lblCapOps: TLabel;
    gridCapOps: TcxGrid;
    tvCapOps: TcxGridTableView;
    colCapOpsNom: TcxGridColumn;
    colCapOpsCheck: TcxGridColumn;
    lvCapOps: TcxGridLevel;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnTancarClick(Sender: TObject);
    procedure chkDarkModeClick(Sender: TObject);
    // Departaments
    procedure btnDeptAddClick(Sender: TObject);
    procedure btnDeptEditClick(Sender: TObject);
    procedure btnDeptDelClick(Sender: TObject);
    // Operaris
    procedure btnOpAddClick(Sender: TObject);
    procedure btnOpEditClick(Sender: TObject);
    procedure btnOpDelClick(Sender: TObject);
  private
    FRepo: TOperariosRepo;

    // Refresh
    procedure RefreshDepts;
    procedure RefreshOperaris;
    procedure RefreshCapOperaris;
    procedure RefreshCapOps;
    procedure RefreshAll;

    procedure ApplyDarkMode(ADark: Boolean);

    // Capacitacions
    procedure CapOperarisFocusChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure CapOpsCheckChanged(Sender: TObject);

    // Helpers
    function DeptOperarisStr(DeptId: Integer): string;
    function OpDeptsStr(OpId: Integer): string;
    function OpCapsStr(OpId: Integer): string;
    function GetSelectedDeptId: Integer;
    function GetSelectedOpId: Integer;
    function GetSelectedCapOperarioId: Integer;

    // Dialogs inline
    function InputDept(var Nom, Desc: string; const ATitle: string): Boolean;
    function InputOperari(var Nom, Cal: string; var DeptIds: TArray<Integer>;
      const ATitle: string): Boolean;
  public
    class procedure Execute(ARepo: TOperariosRepo);
  end;

var
  frmGestionOperaris: TfrmGestionOperaris;

implementation

{$R *.dfm}

const
  ALL_OPS: array[0..11] of string = (
    'PINTAR', 'BRONCEAR', 'LACAR', 'PULIR', 'CORTAR', 'EMBALAR',
    'SOLDAR', 'FRESAR', 'TORNEAR', 'TALADRAR', 'RECTIFICAR', 'MONTAR'
  );

{ TfrmGestionOperaris }

class procedure TfrmGestionOperaris.Execute(ARepo: TOperariosRepo);
var
  F: TfrmGestionOperaris;
begin
  F := TfrmGestionOperaris.Create(Application);
  try
    F.FRepo := ARepo;
    F.RefreshAll;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmGestionOperaris.FormCreate(Sender: TObject);
begin
  tvCapOperaris.OnFocusedRecordChanged := CapOperarisFocusChanged;
  (colCapOpsCheck.Properties as TcxCheckBoxProperties).OnEditValueChanged := CapOpsCheckChanged;
end;

procedure TfrmGestionOperaris.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure TfrmGestionOperaris.btnTancarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

{ ========== Refresh ========== }

procedure TfrmGestionOperaris.RefreshAll;
begin
  RefreshDepts;
  RefreshOperaris;
  RefreshCapOperaris;
  RefreshCapOps;
end;

procedure TfrmGestionOperaris.RefreshDepts;
var
  Depts: TArray<TDepartamento>;
  I: Integer;
begin
  Depts := FRepo.GetDepartamentos;
  tvDepts.BeginUpdate;
  try
    tvDepts.DataController.RecordCount := 0;
    tvDepts.DataController.RecordCount := Length(Depts);
    for I := 0 to High(Depts) do
    begin
      tvDepts.DataController.Values[I, colDeptId.Index] := Depts[I].Id;
      tvDepts.DataController.Values[I, colDeptNom.Index] := Depts[I].Nombre;
      tvDepts.DataController.Values[I, colDeptDesc.Index] := Depts[I].Descripcion;
      tvDepts.DataController.Values[I, colDeptOperaris.Index] := DeptOperarisStr(Depts[I].Id);
    end;
  finally
    tvDepts.EndUpdate;
  end;
end;

procedure TfrmGestionOperaris.RefreshOperaris;
var
  Ops: TArray<TOperario>;
  I: Integer;
begin
  Ops := FRepo.GetOperarios;
  tvOperaris.BeginUpdate;
  try
    tvOperaris.DataController.RecordCount := 0;
    tvOperaris.DataController.RecordCount := Length(Ops);
    for I := 0 to High(Ops) do
    begin
      tvOperaris.DataController.Values[I, colOpId.Index] := Ops[I].Id;
      tvOperaris.DataController.Values[I, colOpNom.Index] := Ops[I].Nombre;
      tvOperaris.DataController.Values[I, colOpCalendari.Index] := Ops[I].Calendario;
      tvOperaris.DataController.Values[I, colOpDepts.Index] := OpDeptsStr(Ops[I].Id);
      tvOperaris.DataController.Values[I, colOpCaps.Index] := OpCapsStr(Ops[I].Id);
    end;
  finally
    tvOperaris.EndUpdate;
  end;
end;

procedure TfrmGestionOperaris.RefreshCapOperaris;
var
  Ops: TArray<TOperario>;
  I: Integer;
begin
  Ops := FRepo.GetOperarios;
  tvCapOperaris.BeginUpdate;
  try
    tvCapOperaris.DataController.RecordCount := 0;
    tvCapOperaris.DataController.RecordCount := Length(Ops);
    for I := 0 to High(Ops) do
    begin
      tvCapOperaris.DataController.Values[I, colCapOpId.Index] := Ops[I].Id;
      tvCapOperaris.DataController.Values[I, colCapOpNom.Index] := Ops[I].Nombre;
    end;
  finally
    tvCapOperaris.EndUpdate;
  end;
end;

procedure TfrmGestionOperaris.RefreshCapOps;
var
  OpId, I: Integer;
  HasCap: Boolean;
begin
  OpId := GetSelectedCapOperarioId;
  tvCapOps.BeginUpdate;
  try
    tvCapOps.DataController.RecordCount := 0;
    tvCapOps.DataController.RecordCount := Length(ALL_OPS);
    for I := 0 to High(ALL_OPS) do
    begin
      HasCap := (OpId > 0) and FRepo.OperarioPotFerOperacio(OpId, ALL_OPS[I]);
      tvCapOps.DataController.Values[I, colCapOpsNom.Index] := ALL_OPS[I];
      tvCapOps.DataController.Values[I, colCapOpsCheck.Index] := HasCap;
    end;
    // Deshabilitar edici'on si no hay operario seleccionado
    colCapOpsCheck.Options.Editing := (OpId > 0);
  finally
    tvCapOps.EndUpdate;
  end;
end;

{ ========== Capacitacions events ========== }

procedure TfrmGestionOperaris.CapOperarisFocusChanged(Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  RefreshCapOps;
end;

procedure TfrmGestionOperaris.CapOpsCheckChanged(Sender: TObject);
var
  OpId, RecIdx: Integer;
  Operacio: string;
  Checked: Boolean;
  V: Variant;
  Cap: TCapacitacion;
begin
  OpId := GetSelectedCapOperarioId;
  if OpId <= 0 then Exit;

  RecIdx := tvCapOps.DataController.FocusedRecordIndex;
  if RecIdx < 0 then Exit;

  Operacio := VarToStr(tvCapOps.DataController.Values[RecIdx, colCapOpsNom.Index]);
  V := tvCapOps.DataController.Values[RecIdx, colCapOpsCheck.Index];
  if VarIsNull(V) then
    Checked := False
  else
    Checked := V;

  if Checked then
  begin
    Cap.OperarioId := OpId;
    Cap.Operacion := Operacio;
    FRepo.AddCapacitacion(Cap);
  end
  else
    FRepo.RemoveCapacitacion(OpId, Operacio);

  // Actualizar tambien el grid de operarios si visible
  RefreshOperaris;
end;

{ ========== Departaments CRUD ========== }

procedure TfrmGestionOperaris.btnDeptAddClick(Sender: TObject);
var
  Nom, Desc: string;
  D: TDepartamento;
begin
  Nom := '';
  Desc := '';
  if InputDept(Nom, Desc, 'Nuevo Departamento') then
  begin
    D.Id := 0;
    D.Nombre := Nom;
    D.Descripcion := Desc;
    FRepo.AddDepartamento(D);
    RefreshDepts;
  end;
end;

procedure TfrmGestionOperaris.btnDeptEditClick(Sender: TObject);
var
  DId: Integer;
  D: TDepartamento;
  Nom, Desc: string;
begin
  DId := GetSelectedDeptId;
  if DId <= 0 then Exit;
  if not FRepo.GetDepartamentoById(DId, D) then Exit;

  Nom := D.Nombre;
  Desc := D.Descripcion;
  if InputDept(Nom, Desc, 'Editar Departamento') then
  begin
    D.Nombre := Nom;
    D.Descripcion := Desc;
    FRepo.UpdateDepartamento(D);
    RefreshDepts;
  end;
end;

procedure TfrmGestionOperaris.btnDeptDelClick(Sender: TObject);
var
  DId: Integer;
  D: TDepartamento;
begin
  DId := GetSelectedDeptId;
  if DId <= 0 then Exit;
  if not FRepo.GetDepartamentoById(DId, D) then Exit;

  if MessageDlg('#191Eliminar departamento "' + D.Nombre + '"?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FRepo.RemoveDepartamento(DId);
    RefreshDepts;
    RefreshOperaris;
  end;
end;

{ ========== Operaris CRUD ========== }

procedure TfrmGestionOperaris.btnOpAddClick(Sender: TObject);
var
  Nom, Cal: string;
  DIds: TArray<Integer>;
  Op: TOperario;
  I: Integer;
begin
  Nom := '';
  Cal := 'STD';
  SetLength(DIds, 0);
  if InputOperari(Nom, Cal, DIds, 'Nuevo Operario') then
  begin
    Op.Id := FRepo.NextOperarioId;
    Op.Nombre := Nom;
    Op.Calendario := Cal;
    FRepo.AddOperario(Op);
    for I := 0 to High(DIds) do
      FRepo.AssignOperariToDept(Op.Id, DIds[I]);
    RefreshAll;
  end;
end;

procedure TfrmGestionOperaris.btnOpEditClick(Sender: TObject);
var
  OpId, I: Integer;
  Op: TOperario;
  Nom, Cal: string;
  DIds, OldDIds: TArray<Integer>;
  Depts: TArray<TDepartamento>;
begin
  OpId := GetSelectedOpId;
  if OpId <= 0 then Exit;
  if not FRepo.GetOperarioById(OpId, Op) then Exit;

  Nom := Op.Nombre;
  Cal := Op.Calendario;

  // Departaments actuals
  Depts := FRepo.GetDeptsByOperario(OpId);
  SetLength(OldDIds, Length(Depts));
  for I := 0 to High(Depts) do
    OldDIds[I] := Depts[I].Id;
  DIds := Copy(OldDIds);

  if InputOperari(Nom, Cal, DIds, 'Editar Operario') then
  begin
    Op.Nombre := Nom;
    Op.Calendario := Cal;
    FRepo.UpdateOperario(Op);

    // Quitar departamentos antiguos
    for I := 0 to High(OldDIds) do
      FRepo.UnassignOperariFromDept(OpId, OldDIds[I]);
    // A'nadir nuevos
    for I := 0 to High(DIds) do
      FRepo.AssignOperariToDept(OpId, DIds[I]);

    RefreshAll;
  end;
end;

procedure TfrmGestionOperaris.btnOpDelClick(Sender: TObject);
var
  OpId: Integer;
  Op: TOperario;
begin
  OpId := GetSelectedOpId;
  if OpId <= 0 then Exit;
  if not FRepo.GetOperarioById(OpId, Op) then Exit;

  if MessageDlg('#191Eliminar operario "' + Op.Nombre + '"?' + sLineBreak +
    'Se perder'#225'n todas las asignaciones y capacitaciones.',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FRepo.RemoveOperario(OpId);
    RefreshAll;
  end;
end;

{ ========== Helpers ========== }

function TfrmGestionOperaris.DeptOperarisStr(DeptId: Integer): string;
var
  Ops: TArray<TOperario>;
  I: Integer;
begin
  Ops := FRepo.GetOperarisByDept(DeptId);
  Result := '';
  for I := 0 to High(Ops) do
  begin
    if I > 0 then Result := Result + ', ';
    Result := Result + Ops[I].Nombre;
  end;
end;

function TfrmGestionOperaris.OpDeptsStr(OpId: Integer): string;
var
  Depts: TArray<TDepartamento>;
  I: Integer;
begin
  Depts := FRepo.GetDeptsByOperario(OpId);
  Result := '';
  for I := 0 to High(Depts) do
  begin
    if I > 0 then Result := Result + ', ';
    Result := Result + Depts[I].Nombre;
  end;
end;

function TfrmGestionOperaris.OpCapsStr(OpId: Integer): string;
var
  Caps: TArray<string>;
  I: Integer;
begin
  Caps := FRepo.GetCapacitacionsByOperario(OpId);
  Result := '';
  for I := 0 to High(Caps) do
  begin
    if I > 0 then Result := Result + ', ';
    Result := Result + Caps[I];
  end;
end;

function TfrmGestionOperaris.GetSelectedDeptId: Integer;
var
  Idx: Integer;
  V: Variant;
begin
  Result := -1;
  Idx := tvDepts.DataController.FocusedRecordIndex;
  if Idx < 0 then Exit;
  V := tvDepts.DataController.Values[Idx, colDeptId.Index];
  if not VarIsNull(V) then
    Result := V;
end;

function TfrmGestionOperaris.GetSelectedOpId: Integer;
var
  Idx: Integer;
  V: Variant;
begin
  Result := -1;
  Idx := tvOperaris.DataController.FocusedRecordIndex;
  if Idx < 0 then Exit;
  V := tvOperaris.DataController.Values[Idx, colOpId.Index];
  if not VarIsNull(V) then
    Result := V;
end;

function TfrmGestionOperaris.GetSelectedCapOperarioId: Integer;
var
  Idx: Integer;
  V: Variant;
begin
  Result := -1;
  Idx := tvCapOperaris.DataController.FocusedRecordIndex;
  if Idx < 0 then Exit;
  V := tvCapOperaris.DataController.Values[Idx, colCapOpId.Index];
  if not VarIsNull(V) then
    Result := V;
end;

{ ========== Input Dialogs ========== }

function TfrmGestionOperaris.InputDept(var Nom, Desc: string; const ATitle: string): Boolean;
var
  Dlg: TForm;
  edNom, edDesc: TEdit;
  lblN, lblD: TLabel;
  btnOk, btnCa: TButton;
begin
  Dlg := TForm.CreateNew(Self);
  try
    Dlg.Caption := ATitle;
    Dlg.Width := 400;
    Dlg.Height := 180;
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
    edNom.Text := Nom;

    lblD := TLabel.Create(Dlg);
    lblD.Parent := Dlg;
    lblD.SetBounds(16, 52, 80, 20);
    lblD.Caption := 'Descripci'#243'n:';

    edDesc := TEdit.Create(Dlg);
    edDesc.Parent := Dlg;
    edDesc.SetBounds(100, 50, 270, 24);
    edDesc.Text := Desc;

    btnOk := TButton.Create(Dlg);
    btnOk.Parent := Dlg;
    btnOk.SetBounds(200, 100, 80, 28);
    btnOk.Caption := 'OK';
    btnOk.Default := True;
    btnOk.ModalResult := mrOk;

    btnCa := TButton.Create(Dlg);
    btnCa.Parent := Dlg;
    btnCa.SetBounds(290, 100, 80, 28);
    btnCa.Caption := 'Cancelar';
    btnCa.Cancel := True;
    btnCa.ModalResult := mrCancel;

    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      Nom := Trim(edNom.Text);
      Desc := Trim(edDesc.Text);
      if Nom = '' then
        Result := False;
    end;
  finally
    Dlg.Free;
  end;
end;

function TfrmGestionOperaris.InputOperari(var Nom, Cal: string;
  var DeptIds: TArray<Integer>; const ATitle: string): Boolean;
var
  Dlg: TForm;
  edNom, edCal: TEdit;
  lblN, lblC, lblD: TLabel;
  clbDepts: TCheckListBox;
  btnOk, btnCa: TButton;
  Depts: TArray<TDepartamento>;
  I, J: Integer;
begin
  Dlg := TForm.CreateNew(Self);
  try
    Dlg.Caption := ATitle;
    Dlg.Width := 420;
    Dlg.Height := 340;
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
    edNom.SetBounds(110, 14, 280, 24);
    edNom.Text := Nom;

    lblC := TLabel.Create(Dlg);
    lblC.Parent := Dlg;
    lblC.SetBounds(16, 52, 80, 20);
    lblC.Caption := 'Calendario:';

    edCal := TEdit.Create(Dlg);
    edCal.Parent := Dlg;
    edCal.SetBounds(110, 50, 280, 24);
    edCal.Text := Cal;

    lblD := TLabel.Create(Dlg);
    lblD.Parent := Dlg;
    lblD.SetBounds(16, 88, 100, 20);
    lblD.Caption := 'Departamentos:';

    clbDepts := TCheckListBox.Create(Dlg);
    clbDepts.Parent := Dlg;
    clbDepts.SetBounds(110, 86, 280, 160);

    Depts := FRepo.GetDepartamentos;
    for I := 0 to High(Depts) do
    begin
      clbDepts.Items.AddObject(Depts[I].Nombre, TObject(Depts[I].Id));
      // Marcar los que ya pertenecen
      for J := 0 to High(DeptIds) do
        if Depts[I].Id = DeptIds[J] then
        begin
          clbDepts.Checked[I] := True;
          Break;
        end;
    end;

    btnOk := TButton.Create(Dlg);
    btnOk.Parent := Dlg;
    btnOk.SetBounds(220, 260, 80, 28);
    btnOk.Caption := 'OK';
    btnOk.Default := True;
    btnOk.ModalResult := mrOk;

    btnCa := TButton.Create(Dlg);
    btnCa.Parent := Dlg;
    btnCa.SetBounds(310, 260, 80, 28);
    btnCa.Caption := 'Cancelar';
    btnCa.Cancel := True;
    btnCa.ModalResult := mrCancel;

    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      Nom := Trim(edNom.Text);
      Cal := Trim(edCal.Text);
      if Nom = '' then
      begin
        Result := False;
        Exit;
      end;
      // Recoger departamentos marcados
      SetLength(DeptIds, 0);
      for I := 0 to clbDepts.Count - 1 do
        if clbDepts.Checked[I] then
        begin
          SetLength(DeptIds, Length(DeptIds) + 1);
          DeptIds[High(DeptIds)] := Integer(clbDepts.Items.Objects[I]);
        end;
    end;
  finally
    Dlg.Free;
  end;
end;

{ ========== Dark Mode ========== }

procedure TfrmGestionOperaris.chkDarkModeClick(Sender: TObject);
begin
  ApplyDarkMode(chkDarkMode.Checked);
end;

procedure TfrmGestionOperaris.ApplyDarkMode(ADark: Boolean);
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
