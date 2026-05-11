unit uGestionOperationTypes;

{
  TfrmGestionOperationTypes - CRUD de tipos de operacion (paralelismo).

  Tabla simple: Operacion + MaxOperariosParalelos + FactorParalelismo +
  Descripcion. Persiste via TOperationTypesRepo (SQL si conectado, in-memory
  si no).
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxButtons,
  uOperariosTypes, uOperationTypesRepo;

type
  TfrmGestionOperationTypes = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlActions: TPanel;
    btnNueva: TcxButton;
    btnEditar: TcxButton;
    btnEliminar: TcxButton;
    grdOps: TcxGrid;
    tvOps: TcxGridTableView;
    colOpCodigo: TcxGridColumn;
    colOpMax: TcxGridColumn;
    colOpFactor: TcxGridColumn;
    colOpDesc: TcxGridColumn;
    lvOps: TcxGridLevel;
    pnlBottom: TPanel;
    btnCerrar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnNuevaClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure tvOpsDblClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FRepo: TOperationTypesRepo;
    FRows: TArray<TTipoOperacion>;
    procedure RefreshGrid;
  public
    class procedure Execute(ARepo: TOperationTypesRepo);
  end;

implementation

uses
  uOperationTypeEdit;

{$R *.dfm}

class procedure TfrmGestionOperationTypes.Execute(ARepo: TOperationTypesRepo);
var
  F: TfrmGestionOperationTypes;
begin
  if not Assigned(ARepo) then Exit;
  F := TfrmGestionOperationTypes.Create(nil);
  try
    F.FRepo := ARepo;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmGestionOperationTypes.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
  tvOps.OptionsBehavior.IncSearch := True;
  tvOps.OptionsCustomize.ColumnsQuickCustomization := True;
  tvOps.OptionsData.Editing := False;
  tvOps.OptionsSelection.CellSelect := False;
  tvOps.OptionsView.Indicator := True;
  tvOps.OptionsView.GroupByBox := False;
end;

procedure TfrmGestionOperationTypes.FormShow(Sender: TObject);
begin
  RefreshGrid;
end;

procedure TfrmGestionOperationTypes.RefreshGrid;
var
  I: Integer;
begin
  FRows := FRepo.GetAll;
  tvOps.BeginUpdate;
  try
    tvOps.DataController.RecordCount := 0;
    tvOps.DataController.RecordCount := Length(FRows);
    for I := 0 to High(FRows) do
    begin
      tvOps.DataController.Values[I, colOpCodigo.Index] := FRows[I].Operacion;
      tvOps.DataController.Values[I, colOpMax.Index] :=
        FRows[I].MaxOperariosParalelos;
      tvOps.DataController.Values[I, colOpFactor.Index] :=
        FormatFloat('0.0000', FRows[I].FactorParalelismo);
      tvOps.DataController.Values[I, colOpDesc.Index] := FRows[I].Descripcion;
    end;
  finally
    tvOps.EndUpdate;
  end;
end;

procedure TfrmGestionOperationTypes.btnNuevaClick(Sender: TObject);
var
  Op: TTipoOperacion;
begin
  Op.Operacion := '';
  Op.MaxOperariosParalelos := 1;
  Op.FactorParalelismo := 1.0;
  Op.Descripcion := '';
  if not TfrmOperationTypeEdit.Execute(Op, True) then Exit;
  if FRepo.Exists(Op.Operacion) then
  begin
    MessageDlg('Ya existe una operaci'#243'n con ese c'#243'digo.',
      mtWarning, [mbOK], 0);
    Exit;
  end;
  FRepo.AddOrUpdate(Op);
  RefreshGrid;
end;

procedure TfrmGestionOperationTypes.btnEditarClick(Sender: TObject);
var
  Idx: Integer;
  Op: TTipoOperacion;
begin
  Idx := tvOps.DataController.FocusedRecordIndex;
  if (Idx < 0) or (Idx > High(FRows)) then Exit;
  Op := FRows[Idx];
  if not TfrmOperationTypeEdit.Execute(Op, False) then Exit;
  FRepo.AddOrUpdate(Op);
  RefreshGrid;
end;

procedure TfrmGestionOperationTypes.btnEliminarClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := tvOps.DataController.FocusedRecordIndex;
  if (Idx < 0) or (Idx > High(FRows)) then Exit;
  if MessageDlg(Format('?Eliminar la operaci'#243'n %s?',
       [FRows[Idx].Operacion]),
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  FRepo.Remove(FRows[Idx].Operacion);
  RefreshGrid;
end;

procedure TfrmGestionOperationTypes.tvOpsDblClick(Sender: TObject);
begin
  btnEditarClick(nil);
end;

procedure TfrmGestionOperationTypes.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
