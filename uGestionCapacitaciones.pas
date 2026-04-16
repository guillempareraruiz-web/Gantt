unit uGestionCapacitaciones;
interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB, dxSkinBasic, dxSkinBlack, dxSkinBlue,
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
  dxSkinXmas2008Blue;
type
  TfrmGestionCapacitaciones = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlLeft: TPanel;
    lblOperarios: TLabel;
    gridOperarios: TcxGrid;
    tvOperarios: TcxGridTableView;
    colOpId: TcxGridColumn;
    colOpNombre: TcxGridColumn;
    colOpSkillsCount: TcxGridColumn;
    lvOperarios: TcxGridLevel;
    splMain: TSplitter;
    pnlRight: TPanel;
    lblSkills: TLabel;
    pnlSkillToolbar: TPanel;
    lblNuevaSkill: TLabel;
    cmbNuevaSkill: TComboBox;
    btnAddSkill: TButton;
    btnDelSkill: TButton;
    gridSkills: TcxGrid;
    tvSkills: TcxGridTableView;
    colSkillOperacion: TcxGridColumn;
    lvSkills: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure tvOperariosFocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure btnAddSkillClick(Sender: TObject);
    procedure btnDelSkillClick(Sender: TObject);
  private
    FOperatorIds: TArray<Integer>;
    procedure LoadOperarios;
    procedure LoadSkillsCatalogo;
    procedure LoadSkillsOperario(AOperatorId: Integer);
    procedure RefreshSkillsCount(ARecIdx: Integer);
    function SelectedOperatorId: Integer;
    function SelectedOperatorRecIdx: Integer;
    function SelectedSkill: string;
    function CountSkills(AOperatorId: Integer): Integer;
    function Exec(const ASQL: string): Integer;
    function OpenQuery(const ASQL: string): TADOQuery;
    function QStr(const S: string): string;
  end;
implementation
{$R *.dfm}
uses
  uDMPlanner;
function TfrmGestionCapacitaciones.QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;
function TfrmGestionCapacitaciones.Exec(const ASQL: string): Integer;
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    Cmd.CommandText := ASQL;
    Cmd.Execute(Result, EmptyParam);
  finally
    Cmd.Free;
  end;
end;
function TfrmGestionCapacitaciones.OpenQuery(const ASQL: string): TADOQuery;
begin
  Result := TADOQuery.Create(nil);
  Result.Connection := DMPlanner.ADOConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;
procedure TfrmGestionCapacitaciones.FormCreate(Sender: TObject);
begin
  LoadSkillsCatalogo;
  LoadOperarios;
end;
procedure TfrmGestionCapacitaciones.btnCloseClick(Sender: TObject);
begin
  Close;
end;
procedure TfrmGestionCapacitaciones.LoadSkillsCatalogo;
var
  Q: TADOQuery;
begin
  cmbNuevaSkill.Items.Clear;
  // Catálogo = skills distintas ya existentes (ayuda a mantener consistencia)
  Q := OpenQuery(
    'SELECT DISTINCT Operacion FROM FS_PL_OperatorSkill ' +
    'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
    ' ORDER BY Operacion');
  try
    while not Q.Eof do
    begin
      cmbNuevaSkill.Items.Add(Q.FieldByName('Operacion').AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;
function TfrmGestionCapacitaciones.CountSkills(AOperatorId: Integer): Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  Q := OpenQuery('SELECT COUNT(*) AS N FROM FS_PL_OperatorSkill ' +
    'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
    ' AND OperatorId = ' + IntToStr(AOperatorId));
  try
    if not Q.Eof then Result := Q.FieldByName('N').AsInteger;
  finally
    Q.Free;
  end;
end;
procedure TfrmGestionCapacitaciones.LoadOperarios;
var
  Q: TADOQuery;
  I: Integer;
begin
  tvOperarios.BeginUpdate;
  try
    tvOperarios.DataController.RecordCount := 0;
    Q := OpenQuery(
      'SELECT o.OperatorId, o.Nombre, ' +
      '  (SELECT COUNT(*) FROM FS_PL_OperatorSkill s ' +
      '   WHERE s.CodigoEmpresa = o.CodigoEmpresa AND s.OperatorId = o.OperatorId) AS SkillsCount ' +
      'FROM FS_PL_Operator o ' +
      'WHERE o.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      '  AND o.Activo = 1 ' +
      'ORDER BY o.Nombre');
    try
      SetLength(FOperatorIds, Q.RecordCount);
      I := 0;
      while not Q.Eof do
      begin
        tvOperarios.DataController.RecordCount := I + 1;
        tvOperarios.DataController.Values[I, colOpId.Index] := Q.FieldByName('OperatorId').AsInteger;
        tvOperarios.DataController.Values[I, colOpNombre.Index] := Q.FieldByName('Nombre').AsString;
        tvOperarios.DataController.Values[I, colOpSkillsCount.Index] := Q.FieldByName('SkillsCount').AsInteger;
        FOperatorIds[I] := Q.FieldByName('OperatorId').AsInteger;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvOperarios.EndUpdate;
  end;
  if tvOperarios.DataController.RecordCount > 0 then
  begin
    tvOperarios.Controller.FocusedRecordIndex := 0;
    LoadSkillsOperario(SelectedOperatorId);
  end
  else
    tvSkills.DataController.RecordCount := 0;
end;
procedure TfrmGestionCapacitaciones.LoadSkillsOperario(AOperatorId: Integer);
var
  Q: TADOQuery;
  I: Integer;
begin
  tvSkills.BeginUpdate;
  try
    tvSkills.DataController.RecordCount := 0;
    if AOperatorId <= 0 then Exit;
    Q := OpenQuery(
      'SELECT Operacion FROM FS_PL_OperatorSkill ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      '  AND OperatorId = ' + IntToStr(AOperatorId) +
      ' ORDER BY Operacion');
    try
      I := 0;
      while not Q.Eof do
      begin
        tvSkills.DataController.RecordCount := I + 1;
        tvSkills.DataController.Values[I, colSkillOperacion.Index] := Q.FieldByName('Operacion').AsString;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvSkills.EndUpdate;
  end;
end;
function TfrmGestionCapacitaciones.SelectedOperatorRecIdx: Integer;
begin
  Result := tvOperarios.Controller.FocusedRecordIndex;
end;
function TfrmGestionCapacitaciones.SelectedOperatorId: Integer;
var
  Idx: Integer;
begin
  Result := -1;
  Idx := SelectedOperatorRecIdx;
  if (Idx >= 0) and (Idx <= High(FOperatorIds)) then
    Result := FOperatorIds[Idx];
end;
function TfrmGestionCapacitaciones.SelectedSkill: string;
var
  Idx: Integer;
begin
  Result := '';
  Idx := tvSkills.Controller.FocusedRecordIndex;
  if Idx < 0 then Exit;
  Result := VarToStr(tvSkills.DataController.Values[Idx, colSkillOperacion.Index]);
end;
procedure TfrmGestionCapacitaciones.RefreshSkillsCount(ARecIdx: Integer);
var
  OpId: Integer;
begin
  if (ARecIdx < 0) or (ARecIdx > High(FOperatorIds)) then Exit;
  OpId := FOperatorIds[ARecIdx];
  tvOperarios.DataController.Values[ARecIdx, colOpSkillsCount.Index] := CountSkills(OpId);
end;
procedure TfrmGestionCapacitaciones.tvOperariosFocusedRecordChanged(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  LoadSkillsOperario(SelectedOperatorId);
end;
procedure TfrmGestionCapacitaciones.btnAddSkillClick(Sender: TObject);
var
  OpId: Integer;
  Skill: string;
  CE: string;
  Q: TADOQuery;
begin
  OpId := SelectedOperatorId;
  if OpId <= 0 then
  begin
    ShowMessage('Seleccione un operario.');
    Exit;
  end;
  Skill := Trim(cmbNuevaSkill.Text);
  if Skill = '' then
  begin
    ShowMessage('Introduzca el nombre de la operación.');
    cmbNuevaSkill.SetFocus;
    Exit;
  end;
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  // Evitar duplicados (la PK ya lo impide, pero así damos un mensaje claro)
  Q := OpenQuery('SELECT 1 FROM FS_PL_OperatorSkill WHERE CodigoEmpresa = ' +
    CE + ' AND OperatorId = ' + IntToStr(OpId) +
    ' AND Operacion = ' + QStr(Skill));
  try
    if not Q.Eof then
    begin
      ShowMessage('El operario ya tiene esta capacitación.');
      Exit;
    end;
  finally
    Q.Free;
  end;
  Exec('INSERT INTO FS_PL_OperatorSkill (CodigoEmpresa, OperatorId, Operacion) VALUES (' +
    CE + ', ' + IntToStr(OpId) + ', ' + QStr(Skill) + ')');
  cmbNuevaSkill.Text := '';
  LoadSkillsOperario(OpId);
  RefreshSkillsCount(SelectedOperatorRecIdx);
  // Si es skill nueva, añadir al catálogo (combo) para futuros usos
  if cmbNuevaSkill.Items.IndexOf(Skill) < 0 then
    cmbNuevaSkill.Items.Add(Skill);
end;
procedure TfrmGestionCapacitaciones.btnDelSkillClick(Sender: TObject);
var
  OpId: Integer;
  Skill: string;
begin
  OpId := SelectedOperatorId;
  if OpId <= 0 then Exit;
  Skill := SelectedSkill;
  if Skill = '' then
  begin
    ShowMessage('Seleccione la capacitación a eliminar.');
    Exit;
  end;
  if MessageDlg('¿Eliminar la capacitación "' + Skill + '"?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  Exec('DELETE FROM FS_PL_OperatorSkill WHERE CodigoEmpresa = ' +
    IntToStr(DMPlanner.CodigoEmpresa) +
    ' AND OperatorId = ' + IntToStr(OpId) +
    ' AND Operacion = ' + QStr(Skill));
  LoadSkillsOperario(OpId);
  RefreshSkillsCount(SelectedOperatorRecIdx);
end;
end.
