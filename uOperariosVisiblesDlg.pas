unit uOperariosVisiblesDlg;

{
  TfrmOperariosVisibles - dialog para escoger que operarios estan visibles
  en TfrmFiniteCapacityOperaris.

  Permite combinar:
   - Filtros por Area (placeholder, requiere mapping operario->area cuando exista)
   - Filtro por Departamento
   - Filtro por Capacitacion (operacion concreta)
   - Seleccion manual (checklist con todos los operarios)

  Devuelve un TArray<Integer> con los IDs de operarios visibles.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxButtons,
  uOperariosTypes, uOperariosRepo, uHelpViewer;

type
  TfrmOperariosVisibles = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblDept: TLabel;
    cbDept: TComboBox;
    lblCap: TLabel;
    cbCap: TComboBox;
    btnAplicarCriterios: TcxButton;
    pnlList: TPanel;
    lblOperarios: TLabel;
    clOperarios: TCheckListBox;
    pnlBottom: TPanel;
    btnTodos: TcxButton;
    btnNinguno: TcxButton;
    btnOK: TcxButton;
    btnCancel: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnAplicarCriteriosClick(Sender: TObject);
    procedure btnTodosClick(Sender: TObject);
    procedure btnNingunoClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FRepo: TOperariosRepo;
    FOperarios: TArray<TOperario>;
    FResult: TArray<Integer>;
    FInicialIds: TArray<Integer>;
    procedure LoadCombos;
    procedure LoadOperariosList;
    function IsInInicial(Id: Integer): Boolean;
  public
    class function Execute(ARepo: TOperariosRepo;
      const AInicialIds: TArray<Integer>;
      out AVisibleIds: TArray<Integer>): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmOperariosVisibles.Execute(ARepo: TOperariosRepo;
  const AInicialIds: TArray<Integer>;
  out AVisibleIds: TArray<Integer>): Boolean;
var
  F: TfrmOperariosVisibles;
begin
  Result := False;
  SetLength(AVisibleIds, 0);
  F := TfrmOperariosVisibles.Create(nil);
  try
    F.FRepo := ARepo;
    F.FInicialIds := Copy(AInicialIds, 0, Length(AInicialIds));
    F.LoadCombos;
    F.LoadOperariosList;
    if F.ShowModal = mrOk then
    begin
      AVisibleIds := F.FResult;
      Result := True;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmOperariosVisibles.FormCreate(Sender: TObject);
begin
  Caption := 'Operarios visibles';
  Position := poScreenCenter;
  // Ayuda contextual: boton '?' en el caption + F1 (patron MD a disco).
  THelpViewer.InstallHelp(Self, 'uOperariosVisiblesDlg', 'Operarios visibles');
end;

procedure TfrmOperariosVisibles.LoadCombos;
var
  Depts: TArray<TDepartamento>;
  Caps: TArray<string>;
  I: Integer;
begin
  cbDept.Items.Clear;
  cbDept.Items.AddObject('(Todos los departamentos)', TObject(0));
  if Assigned(FRepo) then
  begin
    Depts := FRepo.GetDepartamentos;
    for I := 0 to High(Depts) do
      cbDept.Items.AddObject(Depts[I].Nombre, TObject(Depts[I].Id));
  end;
  cbDept.ItemIndex := 0;

  cbCap.Items.Clear;
  cbCap.Items.Add('(Cualquier capacitaci'#243'n)');
  if Assigned(FRepo) then
  begin
    Caps := FRepo.GetAllOperacions;
    for I := 0 to High(Caps) do
      cbCap.Items.Add(Caps[I]);
  end;
  cbCap.ItemIndex := 0;
end;

function TfrmOperariosVisibles.IsInInicial(Id: Integer): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FInicialIds) do
    if FInicialIds[I] = Id then Exit(True);
  Result := False;
end;

procedure TfrmOperariosVisibles.LoadOperariosList;
var
  I: Integer;
begin
  clOperarios.Items.BeginUpdate;
  try
    clOperarios.Clear;
    if Assigned(FRepo) then
    begin
      FOperarios := FRepo.GetOperarios;
      for I := 0 to High(FOperarios) do
      begin
        clOperarios.Items.AddObject(FOperarios[I].Nombre,
          TObject(FOperarios[I].Id));
        // Marcar segun seleccion inicial. Si no hay inicial, todos marcados.
        if Length(FInicialIds) = 0 then
          clOperarios.Checked[I] := True
        else
          clOperarios.Checked[I] := IsInInicial(FOperarios[I].Id);
      end;
    end;
  finally
    clOperarios.Items.EndUpdate;
  end;
end;

procedure TfrmOperariosVisibles.btnAplicarCriteriosClick(Sender: TObject);
var
  I: Integer;
  DeptId: Integer;
  Cap: string;
  Depts: TArray<TDepartamento>;
  J: Integer;
  EnDept: Boolean;
  Pasa: Boolean;
begin
  // Marcar segun criterios de combos
  if cbDept.ItemIndex > 0 then
    DeptId := Integer(cbDept.Items.Objects[cbDept.ItemIndex])
  else
    DeptId := 0;
  if cbCap.ItemIndex > 0 then
    Cap := cbCap.Items[cbCap.ItemIndex]
  else
    Cap := '';

  for I := 0 to High(FOperarios) do
  begin
    Pasa := True;
    if (DeptId > 0) and Assigned(FRepo) then
    begin
      Depts := FRepo.GetDeptsByOperario(FOperarios[I].Id);
      EnDept := False;
      for J := 0 to High(Depts) do
        if Depts[J].Id = DeptId then
        begin
          EnDept := True;
          Break;
        end;
      if not EnDept then Pasa := False;
    end;
    if Pasa and (Cap <> '') and Assigned(FRepo) then
      if not FRepo.OperarioPotFerOperacio(FOperarios[I].Id, Cap) then
        Pasa := False;
    clOperarios.Checked[I] := Pasa;
  end;
end;

procedure TfrmOperariosVisibles.btnTodosClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to clOperarios.Items.Count - 1 do
    clOperarios.Checked[I] := True;
end;

procedure TfrmOperariosVisibles.btnNingunoClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to clOperarios.Items.Count - 1 do
    clOperarios.Checked[I] := False;
end;

procedure TfrmOperariosVisibles.btnOKClick(Sender: TObject);
var
  L: TList<Integer>;
  I: Integer;
begin
  L := TList<Integer>.Create;
  try
    for I := 0 to clOperarios.Items.Count - 1 do
      if clOperarios.Checked[I] then
        L.Add(Integer(clOperarios.Items.Objects[I]));
    FResult := L.ToArray;
  finally
    L.Free;
  end;
  ModalResult := mrOk;
end;

procedure TfrmOperariosVisibles.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
