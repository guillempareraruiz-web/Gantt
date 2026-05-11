unit uAsignarMaquinasCentro;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  uMaquinasRepo;

type
  TfrmAsignarMaquinasCentro = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnOk: TButton;
    btnCancel: TButton;
    gridMaquinas: TcxGrid;
    tvMaquinas: TcxGridTableView;
    colSel: TcxGridColumn;
    colCodigo: TcxGridColumn;
    colNombre: TcxGridColumn;
    lvMaquinas: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FRepo: TMaquinasRepo;
    FCenterId: Integer;
    FCenterCaption: string;
    FIds: TArray<Integer>; // MaquinaId por fila
    procedure LoadGrid;
    function CollectSelected: TArray<Integer>;
  public
    class function Execute(ACenterId: Integer;
      const ACenterCaption: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

class function TfrmAsignarMaquinasCentro.Execute(ACenterId: Integer;
  const ACenterCaption: string): Boolean;
var
  Frm: TfrmAsignarMaquinasCentro;
begin
  Frm := TfrmAsignarMaquinasCentro.Create(nil);
  try
    Frm.FCenterId := ACenterId;
    Frm.FCenterCaption := ACenterCaption;
    Result := Frm.ShowModal = mrOk;
  finally
    Frm.Free;
  end;
end;

procedure TfrmAsignarMaquinasCentro.FormCreate(Sender: TObject);
begin
  FRepo := TMaquinasRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  tvMaquinas.OptionsData.Editing := True;
  tvMaquinas.OptionsSelection.CellSelect := True;
  colSel.Options.Editing := True;
  // NO carregar grid aqui: FCenterId encara no esta assignat (Execute el posa
  // entre Create i ShowModal). El carregem a FormShow.
end;

procedure TfrmAsignarMaquinasCentro.FormShow(Sender: TObject);
begin
  LoadGrid;
end;

procedure TfrmAsignarMaquinasCentro.FormDestroy(Sender: TObject);
begin
  FRepo.Free;
end;

procedure TfrmAsignarMaquinasCentro.LoadGrid;
var
  Items: TArray<TMaquina>;
  AssignedIds: TArray<Integer>;
  Lookup: TDictionary<Integer, Boolean>;
  I: Integer;
begin
  if FCenterCaption <> '' then
    lblSubtitle.Caption := 'Centro: ' + FCenterCaption;

  FRepo.LoadFromDB;
  Items := FRepo.GetAll;
  AssignedIds := FRepo.GetMaquinaIdsForCentro(FCenterId);

  Lookup := TDictionary<Integer, Boolean>.Create;
  try
    for I := 0 to High(AssignedIds) do
      Lookup.AddOrSetValue(AssignedIds[I], True);

    SetLength(FIds, Length(Items));
    tvMaquinas.BeginUpdate;
    try
      tvMaquinas.DataController.RecordCount := 0;
      tvMaquinas.DataController.RecordCount := Length(Items);
      for I := 0 to High(Items) do
      begin
        FIds[I] := Items[I].Id;
        tvMaquinas.DataController.Values[I, colSel.Index]    := Lookup.ContainsKey(Items[I].Id);
        tvMaquinas.DataController.Values[I, colCodigo.Index] := Items[I].Codigo;
        tvMaquinas.DataController.Values[I, colNombre.Index] := Items[I].Nombre;
      end;
    finally
      tvMaquinas.EndUpdate;
    end;
  finally
    Lookup.Free;
  end;
end;

function TfrmAsignarMaquinasCentro.CollectSelected: TArray<Integer>;
var
  I: Integer;
  V: Variant;
  Sel: Boolean;
  L: TList<Integer>;
begin
  L := TList<Integer>.Create;
  try
    for I := 0 to tvMaquinas.DataController.RecordCount - 1 do
    begin
      V := tvMaquinas.DataController.Values[I, colSel.Index];
      if VarIsNull(V) or VarIsEmpty(V) then Continue;
      try
        Sel := Boolean(V);
      except
        Sel := False;
      end;
      if Sel and (I < Length(FIds)) then
        L.Add(FIds[I]);
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmAsignarMaquinasCentro.btnOkClick(Sender: TObject);
begin
  // Forzar commit de la celda en edicion (el ultimo check puede estar in-flight)
  if tvMaquinas.Controller.EditingController.IsEditing then
    tvMaquinas.Controller.EditingController.HideEdit(True);
  tvMaquinas.DataController.Post(False);

  try
    FRepo.SetMaquinasForCentro(FCenterId, CollectSelected);
  except
    on E: Exception do
    begin
      ShowMessage('No se pudo guardar la asignaci'#243'n: ' + E.Message);
      Exit;
    end;
  end;
  ModalResult := mrOk;
end;

procedure TfrmAsignarMaquinasCentro.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
