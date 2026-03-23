unit uOperarioFilterPopup;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxScrollbarAnnotations,
  // Project
  uOperariosTypes, uOperariosRepo;

type
  TOnFilterChanged = procedure(Sender: TObject; const SelectedIds: TArray<Integer>) of object;

  TfrmOperarioFilterPopup = class(TForm)
  private
    FRepo: TOperariosRepo;
    FGrid: TcxGrid;
    FView: TcxGridTableView;
    FLevel: TcxGridLevel;
    FColCheck: TcxGridColumn;
    FColId: TcxGridColumn;
    FColNombre: TcxGridColumn;
    FColDepartamento: TcxGridColumn;
    FBtnAll: TButton;
    FBtnNone: TButton;
    FBtnClose: TButton;
    FLookAndFeel: TcxLookAndFeelController;
    FOnFilterChanged: TOnFilterChanged;

    procedure LoadData;
    procedure DoSelectAll(Sender: TObject);
    procedure DoSelectNone(Sender: TObject);
    procedure DoClose(Sender: TObject);
    procedure DoCheckChanged(Sender: TObject);
    procedure FireFilterChanged;
    function DeptsStr(OpId: Integer): string;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Deactivate; override;
  public
    constructor CreatePopup(AOwner: TComponent; ARepo: TOperariosRepo);

    procedure ShowAt(X, Y: Integer);
    function GetSelectedIds: TArray<Integer>;
    procedure SetSelectedIds(const AIds: TArray<Integer>);

    property OnFilterChanged: TOnFilterChanged read FOnFilterChanged write FOnFilterChanged;
  end;

implementation

{ TfrmOperarioFilterPopup }

constructor TfrmOperarioFilterPopup.CreatePopup(AOwner: TComponent; ARepo: TOperariosRepo);
begin
  inherited CreateNew(AOwner);
  FRepo := ARepo;

  BorderStyle := bsSizeToolWin;
  Caption := 'Filtro de Operarios';
  Width := 520;
  Height := 420;
  Position := poDesigned;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  KeyPreview := True;

  FLookAndFeel := TcxLookAndFeelController.Create(Self);
  FLookAndFeel.NativeStyle := False;
  FLookAndFeel.SkinName := 'Office2019Colorful';

  // Panel superior con botones
  var pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 32;
  pnlTop.BevelOuter := bvNone;

  FBtnAll := TButton.Create(Self);
  FBtnAll.Parent := pnlTop;
  FBtnAll.SetBounds(4, 3, 100, 26);
  FBtnAll.Caption := 'Marcar todo';
  FBtnAll.OnClick := DoSelectAll;

  FBtnNone := TButton.Create(Self);
  FBtnNone.Parent := pnlTop;
  FBtnNone.SetBounds(110, 3, 110, 26);
  FBtnNone.Caption := 'Desmarcar todo';
  FBtnNone.OnClick := DoSelectNone;

  FBtnClose := TButton.Create(Self);
  FBtnClose.Parent := pnlTop;
  FBtnClose.SetBounds(pnlTop.Width - 84, 3, 80, 26);
  FBtnClose.Anchors := [akTop, akRight];
  FBtnClose.Caption := 'Cerrar';
  FBtnClose.OnClick := DoClose;

  // Grid
  FGrid := TcxGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;

  FView := FGrid.CreateView(TcxGridTableView) as TcxGridTableView;
  FLevel := FGrid.Levels.Add;
  FLevel.GridView := FView;

  FView.OptionsData.Deleting := False;
  FView.OptionsData.Inserting := False;
  FView.OptionsView.GroupByBox := False;
  FView.OptionsView.Indicator := False;
  FView.OptionsSelection.MultiSelect := False;
  FView.OptionsCustomize.ColumnFiltering := True;
  FView.OptionsCustomize.ColumnSorting := True;
  FView.FilterRow.Visible := True;

  // Columna checkbox
  FColCheck := FView.CreateColumn;
  FColCheck.Caption := '';
  FColCheck.Width := 30;
  FColCheck.PropertiesClassName := 'TcxCheckBoxProperties';
  FColCheck.Options.Filtering := False;
  FColCheck.Options.Sorting := False;
  (FColCheck.Properties as TcxCheckBoxProperties).OnEditValueChanged := DoCheckChanged;

  // Columna ID
  FColId := FView.CreateColumn;
  FColId.Caption := 'ID';
  FColId.Width := 40;
  FColId.Options.Editing := False;

  // Columna Nombre
  FColNombre := FView.CreateColumn;
  FColNombre.Caption := 'Nombre';
  FColNombre.Width := 200;
  FColNombre.Options.Editing := False;

  // Columna Departamento
  FColDepartamento := FView.CreateColumn;
  FColDepartamento.Caption := 'Departamento';
  FColDepartamento.Width := 200;
  FColDepartamento.Options.Editing := False;

  LoadData;
end;

procedure TfrmOperarioFilterPopup.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := Params.Style or WS_THICKFRAME;
  Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW;
end;

procedure TfrmOperarioFilterPopup.Deactivate;
begin
  inherited;
  Hide;
end;

procedure TfrmOperarioFilterPopup.LoadData;
var
  Ops: TArray<TOperario>;
  I: Integer;
begin
  Ops := FRepo.GetOperarios;
  FView.BeginUpdate;
  try
    FView.DataController.RecordCount := Length(Ops);
    for I := 0 to High(Ops) do
    begin
      FView.DataController.Values[I, FColCheck.Index] := False;
      FView.DataController.Values[I, FColId.Index] := Ops[I].Id;
      FView.DataController.Values[I, FColNombre.Index] := Ops[I].Nombre;
      FView.DataController.Values[I, FColDepartamento.Index] := DeptsStr(Ops[I].Id);
    end;
  finally
    FView.EndUpdate;
  end;
end;

function TfrmOperarioFilterPopup.DeptsStr(OpId: Integer): string;
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

procedure TfrmOperarioFilterPopup.ShowAt(X, Y: Integer);
begin
  Left := X;
  Top := Y;
  Show;
end;

procedure TfrmOperarioFilterPopup.DoSelectAll(Sender: TObject);
var
  I: Integer;
begin
  FView.BeginUpdate;
  try
    for I := 0 to FView.DataController.RecordCount - 1 do
      FView.DataController.Values[I, FColCheck.Index] := True;
  finally
    FView.EndUpdate;
  end;
  FireFilterChanged;
end;

procedure TfrmOperarioFilterPopup.DoSelectNone(Sender: TObject);
var
  I: Integer;
begin
  FView.BeginUpdate;
  try
    for I := 0 to FView.DataController.RecordCount - 1 do
      FView.DataController.Values[I, FColCheck.Index] := False;
  finally
    FView.EndUpdate;
  end;
  FireFilterChanged;
end;

procedure TfrmOperarioFilterPopup.DoClose(Sender: TObject);
begin
  Hide;
end;

procedure TfrmOperarioFilterPopup.DoCheckChanged(Sender: TObject);
begin
  FireFilterChanged;
end;

procedure TfrmOperarioFilterPopup.FireFilterChanged;
begin
  if Assigned(FOnFilterChanged) then
    FOnFilterChanged(Self, GetSelectedIds);
end;

function TfrmOperarioFilterPopup.GetSelectedIds: TArray<Integer>;
var
  I: Integer;
  List: TList<Integer>;
  V: Variant;
begin
  List := TList<Integer>.Create;
  try
    for I := 0 to FView.DataController.RecordCount - 1 do
    begin
      V := FView.DataController.Values[I, FColCheck.Index];
      if (not VarIsNull(V)) and V then
        List.Add(FView.DataController.Values[I, FColId.Index]);
    end;
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

procedure TfrmOperarioFilterPopup.SetSelectedIds(const AIds: TArray<Integer>);
var
  I, J: Integer;
  IdSet: TDictionary<Integer, Byte>;
  OpId: Integer;
  V: Variant;
begin
  IdSet := TDictionary<Integer, Byte>.Create;
  try
    for I := 0 to High(AIds) do
      IdSet.AddOrSetValue(AIds[I], 1);

    FView.BeginUpdate;
    try
      for I := 0 to FView.DataController.RecordCount - 1 do
      begin
        V := FView.DataController.Values[I, FColId.Index];
        if VarIsNull(V) then Continue;
        OpId := V;
        FView.DataController.Values[I, FColCheck.Index] := IdSet.ContainsKey(OpId);
      end;
    finally
      FView.EndUpdate;
    end;
  finally
    IdSet.Free;
  end;
end;

end.
