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
  cxDataStorage, cxNavigator, dxDateRanges,
  Data.Win.ADODB, Data.DB;

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
    FOperaciones: TArray<string>;
    FCalendarios: TArray<string>;

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
    class procedure Execute(ARepo: TOperariosRepo;
      const AOperaciones, ACalendarios: TArray<string>);
  end;

var
  frmGestionOperaris: TfrmGestionOperaris;

implementation

uses
  uDMPlanner;

{$R *.dfm}

{ TfrmGestionOperaris }

class procedure TfrmGestionOperaris.Execute(ARepo: TOperariosRepo;
  const AOperaciones, ACalendarios: TArray<string>);
var
  F: TfrmGestionOperaris;
  TempRepo: TOperariosRepo;
  OwnRepo: Boolean;
begin
  OwnRepo := False;
  TempRepo := ARepo;
  if TempRepo = nil then
  begin
    TempRepo := TOperariosRepo.Create;
    OwnRepo := True;
  end;

  F := TfrmGestionOperaris.Create(Application);
  try
    F.FRepo := TempRepo;
    F.FOperaciones := AOperaciones;
    F.FCalendarios := ACalendarios;
    F.RefreshAll;
    F.ShowModal;
  finally
    F.Free;
    if OwnRepo then
      TempRepo.Free;
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
  Q: TADOQuery;
  I: Integer;
  D: TDepartamento;
begin
  tvDepts.BeginUpdate;
  try
    tvDepts.DataController.RecordCount := 0;
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text := 'SELECT DepartmentId, Nombre, Descripcion FROM FS_PL_Department ' +
        'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) + ' ORDER BY Nombre';
      Q.Open;
      I := 0;
      while not Q.Eof do
      begin
        tvDepts.DataController.RecordCount := I + 1;
        tvDepts.DataController.Values[I, colDeptId.Index] := Q.FieldByName('DepartmentId').AsInteger;
        tvDepts.DataController.Values[I, colDeptNom.Index] := Q.FieldByName('Nombre').AsString;
        tvDepts.DataController.Values[I, colDeptDesc.Index] := Q.FieldByName('Descripcion').AsString;
        // Actualizar también el repo en memoria
        D.Id := Q.FieldByName('DepartmentId').AsInteger;
        D.Nombre := Q.FieldByName('Nombre').AsString;
        D.Descripcion := Q.FieldByName('Descripcion').AsString;
        tvDepts.DataController.Values[I, colDeptOperaris.Index] := DeptOperarisStr(D.Id);
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvDepts.EndUpdate;
  end;
end;

procedure TfrmGestionOperaris.RefreshOperaris;
var
  Q: TADOQuery;
  I, OpId: Integer;
begin
  tvOperaris.BeginUpdate;
  try
    tvOperaris.DataController.RecordCount := 0;
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT o.OperatorId, o.Nombre, ' +
        '  ISNULL((SELECT STRING_AGG(d.Nombre, '', '') FROM FS_PL_OperatorDepartment od ' +
        '    INNER JOIN FS_PL_Department d ON d.CodigoEmpresa = od.CodigoEmpresa AND d.DepartmentId = od.DepartmentId ' +
        '    WHERE od.CodigoEmpresa = o.CodigoEmpresa AND od.OperatorId = o.OperatorId), '''') AS Depts, ' +
        '  ISNULL((SELECT STRING_AGG(os.Operacion, '', '') FROM FS_PL_OperatorSkill os ' +
        '    WHERE os.CodigoEmpresa = o.CodigoEmpresa AND os.OperatorId = o.OperatorId), '''') AS Caps ' +
        'FROM FS_PL_Operator o ' +
        'WHERE o.CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) + ' AND o.Activo = 1 ' +
        'ORDER BY o.Nombre';
      Q.Open;
      I := 0;
      while not Q.Eof do
      begin
        tvOperaris.DataController.RecordCount := I + 1;
        tvOperaris.DataController.Values[I, colOpId.Index] := Q.FieldByName('OperatorId').AsInteger;
        tvOperaris.DataController.Values[I, colOpNom.Index] := Q.FieldByName('Nombre').AsString;
        tvOperaris.DataController.Values[I, colOpCalendari.Index] := '';
        tvOperaris.DataController.Values[I, colOpDepts.Index] := Q.FieldByName('Depts').AsString;
        tvOperaris.DataController.Values[I, colOpCaps.Index] := Q.FieldByName('Caps').AsString;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvOperaris.EndUpdate;
  end;
end;

procedure TfrmGestionOperaris.RefreshCapOperaris;
var
  Q: TADOQuery;
  I: Integer;
begin
  tvCapOperaris.BeginUpdate;
  try
    tvCapOperaris.DataController.RecordCount := 0;
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text := 'SELECT OperatorId, Nombre FROM FS_PL_Operator ' +
        'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) + ' AND Activo = 1 ORDER BY Nombre';
      Q.Open;
      I := 0;
      while not Q.Eof do
      begin
        tvCapOperaris.DataController.RecordCount := I + 1;
        tvCapOperaris.DataController.Values[I, colCapOpId.Index] := Q.FieldByName('OperatorId').AsInteger;
        tvCapOperaris.DataController.Values[I, colCapOpNom.Index] := Q.FieldByName('Nombre').AsString;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvCapOperaris.EndUpdate;
  end;
end;

procedure TfrmGestionOperaris.RefreshCapOps;
var
  OpId, I: Integer;
  HasCap: Boolean;
  Q: TADOQuery;
  Skills: TStringList;
  Ops: TArray<string>;
  OpsList: TStringList;
begin
  OpId := GetSelectedCapOperarioId;
  tvCapOps.BeginUpdate;
  Skills := TStringList.Create;
  try
    // Si FOperaciones está vacío, cargarlas desde SQL (operaciones distintas en FS_PL_OperatorSkill)
    if (Length(FOperaciones) = 0) and DMPlanner.IsConnected then
    begin
      OpsList := TStringList.Create;
      try
        OpsList.Duplicates := dupIgnore;
        OpsList.Sorted := True;
        Q := TADOQuery.Create(nil);
        try
          Q.Connection := DMPlanner.ADOConnection;
          Q.SQL.Text := 'SELECT DISTINCT Operacion FROM FS_PL_OperatorSkill ' +
            'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
            ' ORDER BY Operacion';
          Q.Open;
          while not Q.Eof do
          begin
            OpsList.Add(Q.FieldByName('Operacion').AsString);
            Q.Next;
          end;
        finally
          Q.Free;
        end;
        SetLength(Ops, OpsList.Count);
        for I := 0 to OpsList.Count - 1 do
          Ops[I] := OpsList[I];
        FOperaciones := Ops;
      finally
        OpsList.Free;
      end;
    end;

    // Cargar skills del operario desde SQL
    if (OpId > 0) and DMPlanner.IsConnected then
    begin
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := DMPlanner.ADOConnection;
        Q.SQL.Text := 'SELECT Operacion FROM FS_PL_OperatorSkill ' +
          'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
          ' AND OperatorId = ' + IntToStr(OpId);
        Q.Open;
        while not Q.Eof do
        begin
          Skills.Add(Q.FieldByName('Operacion').AsString);
          Q.Next;
        end;
      finally
        Q.Free;
      end;
    end;

    tvCapOps.DataController.RecordCount := 0;
    tvCapOps.DataController.RecordCount := Length(FOperaciones);
    for I := 0 to High(FOperaciones) do
    begin
      HasCap := (OpId > 0) and (Skills.IndexOf(FOperaciones[I]) >= 0);
      tvCapOps.DataController.Values[I, colCapOpsNom.Index] := FOperaciones[I];
      tvCapOps.DataController.Values[I, colCapOpsCheck.Index] := HasCap;
    end;
    colCapOpsCheck.Options.Editing := (OpId > 0);
  finally
    Skills.Free;
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
  Cmd: TADOCommand;
  CE: string;
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

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := DMPlanner.ADOConnection;
    if Checked then
    begin
      Cmd.CommandText := 'IF NOT EXISTS (SELECT 1 FROM FS_PL_OperatorSkill WHERE CodigoEmpresa = ' + CE +
        ' AND OperatorId = ' + IntToStr(OpId) +
        ' AND Operacion = N''' + StringReplace(Operacio, '''', '''''', [rfReplaceAll]) + ''') ' +
        'INSERT INTO FS_PL_OperatorSkill (CodigoEmpresa, OperatorId, Operacion) VALUES (' +
        CE + ', ' + IntToStr(OpId) + ', N''' + StringReplace(Operacio, '''', '''''', [rfReplaceAll]) + ''')';
      Cap.OperarioId := OpId;
      Cap.Operacion := Operacio;
      FRepo.AddCapacitacion(Cap);
    end
    else
    begin
      Cmd.CommandText := 'DELETE FROM FS_PL_OperatorSkill WHERE CodigoEmpresa = ' + CE +
        ' AND OperatorId = ' + IntToStr(OpId) +
        ' AND Operacion = N''' + StringReplace(Operacio, '''', '''''', [rfReplaceAll]) + '''';
      FRepo.RemoveCapacitacion(OpId, Operacio);
    end;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  RefreshOperaris;
end;

{ ========== Departaments CRUD ========== }

procedure TfrmGestionOperaris.btnDeptAddClick(Sender: TObject);
var
  Nom, Desc: string;
  D: TDepartamento;
  Cmd: TADOCommand;
begin
  Nom := '';
  Desc := '';
  if InputDept(Nom, Desc, 'Nuevo Departamento') then
  begin
    // Guardar en SQL
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;
      Cmd.CommandText := 'INSERT INTO FS_PL_Department (CodigoEmpresa, Nombre, Descripcion) VALUES (' +
        IntToStr(DMPlanner.CodigoEmpresa) + ', ' +
        'N''' + StringReplace(Nom, '''', '''''', [rfReplaceAll]) + ''', ' +
        'N''' + StringReplace(Desc, '''', '''''', [rfReplaceAll]) + ''')';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
    // Actualizar también el repo en memoria
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
  Cmd: TADOCommand;
begin
  DId := GetSelectedDeptId;
  if DId <= 0 then Exit;
  if not FRepo.GetDepartamentoById(DId, D) then Exit;

  Nom := D.Nombre;
  Desc := D.Descripcion;
  if InputDept(Nom, Desc, 'Editar Departamento') then
  begin
    // Guardar en SQL
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;
      Cmd.CommandText := 'UPDATE FS_PL_Department SET ' +
        'Nombre = N''' + StringReplace(Nom, '''', '''''', [rfReplaceAll]) + ''', ' +
        'Descripcion = N''' + StringReplace(Desc, '''', '''''', [rfReplaceAll]) + '''' +
        ' WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
        ' AND DepartmentId = ' + IntToStr(DId);
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
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
  Cmd: TADOCommand;
begin
  DId := GetSelectedDeptId;
  if DId <= 0 then Exit;
  if not FRepo.GetDepartamentoById(DId, D) then Exit;

  if MessageDlg('#191Eliminar departamento "' + D.Nombre + '"?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    // Eliminar en SQL
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;
      Cmd.CommandText := 'DELETE FROM FS_PL_Department WHERE CodigoEmpresa = ' +
        IntToStr(DMPlanner.CodigoEmpresa) + ' AND DepartmentId = ' + IntToStr(DId);
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
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
  Cmd: TADOCommand;
  Q: TADOQuery;
  CE: string;
  NewId: Integer;
begin
  Nom := '';
  Cal := 'STD';
  SetLength(DIds, 0);
  if InputOperari(Nom, Cal, DIds, 'Nuevo Operario') then
  begin
    CE := IntToStr(DMPlanner.CodigoEmpresa);

    // Insertar en SQL
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;
      Cmd.CommandText := 'INSERT INTO FS_PL_Operator (CodigoEmpresa, Nombre, Activo) VALUES (' +
        CE + ', N''' + StringReplace(Nom, '''', '''''', [rfReplaceAll]) + ''', 1)';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;

    // Obtener el ID generado
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text := 'SELECT MAX(OperatorId) AS NewId FROM FS_PL_Operator WHERE CodigoEmpresa = ' + CE;
      Q.Open;
      NewId := Q.FieldByName('NewId').AsInteger;
    finally
      Q.Free;
    end;

    // Asignar departamentos en SQL
    for I := 0 to High(DIds) do
    begin
      Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := DMPlanner.ADOConnection;
        Cmd.CommandText := 'INSERT INTO FS_PL_OperatorDepartment (CodigoEmpresa, OperatorId, DepartmentId) VALUES (' +
          CE + ', ' + IntToStr(NewId) + ', ' + IntToStr(DIds[I]) + ')';
        Cmd.Execute;
      finally
        Cmd.Free;
      end;
    end;

    // Actualizar repo en memoria
    Op.Id := NewId;
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
  Cmd: TADOCommand;
  CE: string;
begin
  OpId := GetSelectedOpId;
  if OpId <= 0 then Exit;
  if not FRepo.GetOperarioById(OpId, Op) then Exit;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
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
    // Actualizar en SQL
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;
      Cmd.CommandText := 'UPDATE FS_PL_Operator SET Nombre = N''' +
        StringReplace(Nom, '''', '''''', [rfReplaceAll]) + '''' +
        ' WHERE CodigoEmpresa = ' + CE + ' AND OperatorId = ' + IntToStr(OpId);
      Cmd.Execute;
    finally
      Cmd.Free;
    end;

    // Rehacer departamentos en SQL
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;
      Cmd.CommandText := 'DELETE FROM FS_PL_OperatorDepartment WHERE CodigoEmpresa = ' +
        CE + ' AND OperatorId = ' + IntToStr(OpId);
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
    for I := 0 to High(DIds) do
    begin
      Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := DMPlanner.ADOConnection;
        Cmd.CommandText := 'INSERT INTO FS_PL_OperatorDepartment (CodigoEmpresa, OperatorId, DepartmentId) VALUES (' +
          CE + ', ' + IntToStr(OpId) + ', ' + IntToStr(DIds[I]) + ')';
        Cmd.Execute;
      finally
        Cmd.Free;
      end;
    end;

    // Actualizar repo en memoria
    Op.Nombre := Nom;
    Op.Calendario := Cal;
    FRepo.UpdateOperario(Op);
    for I := 0 to High(OldDIds) do
      FRepo.UnassignOperariFromDept(OpId, OldDIds[I]);
    for I := 0 to High(DIds) do
      FRepo.AssignOperariToDept(OpId, DIds[I]);

    RefreshAll;
  end;
end;

procedure TfrmGestionOperaris.btnOpDelClick(Sender: TObject);
var
  OpId: Integer;
  Op: TOperario;
  Cmd: TADOCommand;
  CE: string;
begin
  OpId := GetSelectedOpId;
  if OpId <= 0 then Exit;
  if not FRepo.GetOperarioById(OpId, Op) then Exit;

  if MessageDlg('#191Eliminar operario "' + Op.Nombre + '"?' + sLineBreak +
    'Se perder'#225'n todas las asignaciones y capacitaciones.',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    CE := IntToStr(DMPlanner.CodigoEmpresa);
    // Eliminar en SQL (CASCADE eliminará skills y departments)
    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := DMPlanner.ADOConnection;
      Cmd.CommandText := 'DELETE FROM FS_PL_Operator WHERE CodigoEmpresa = ' +
        CE + ' AND OperatorId = ' + IntToStr(OpId);
      Cmd.Execute;
    finally
      Cmd.Free;
    end;

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
  edNom: TEdit;
  cbCal: TComboBox;
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

    cbCal := TComboBox.Create(Dlg);
    cbCal.Parent := Dlg;
    cbCal.Style := csDropDownList;
    cbCal.SetBounds(110, 50, 280, 24);
    for I := 0 to High(FCalendarios) do
      cbCal.Items.Add(FCalendarios[I]);
    cbCal.ItemIndex := cbCal.Items.IndexOf(Cal);
    if cbCal.ItemIndex < 0 then
      cbCal.ItemIndex := 0;

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
      if cbCal.ItemIndex >= 0 then
        Cal := cbCal.Items[cbCal.ItemIndex]
      else
        Cal := '';
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
