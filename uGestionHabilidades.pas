unit uGestionHabilidades;

{
  TfrmGestionHabilidades - CRUD del catalogo de habilidades.

  Tabla simple: Codigo + Descripcion. Para edicion usa un mini-dialogo
  modal (TfrmHabilidadEdit, en este mismo unit).

  Persistencia: THabilidadRepo en memoria. SQL en V020.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxButtons,
  uPlanProdTypes, uHabilidadRepo;

type
  TfrmGestionHabilidades = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlActions: TPanel;
    btnNueva: TcxButton;
    btnEditar: TcxButton;
    btnEliminar: TcxButton;
    grdHabilidades: TcxGrid;
    tvHabilidades: TcxGridTableView;
    colCodigo: TcxGridColumn;
    colDescripcion: TcxGridColumn;
    lvHabilidades: TcxGridLevel;
    pnlBottom: TPanel;
    btnCerrar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnNuevaClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure tvHabilidadesDblClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FRepo: THabilidadRepo;
    FRows: TArray<THabilidad>;
    procedure RefreshGrid;
  public
    class procedure Execute(ARepo: THabilidadRepo);
  end;

implementation

uses
  uHabilidadEdit;

{$R *.dfm}

{ TfrmGestionHabilidades }

class procedure TfrmGestionHabilidades.Execute(ARepo: THabilidadRepo);
var
  F: TfrmGestionHabilidades;
begin
  if not Assigned(ARepo) then Exit;
  F := TfrmGestionHabilidades.Create(nil);
  try
    F.FRepo := ARepo;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmGestionHabilidades.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
  tvHabilidades.OptionsBehavior.IncSearch := True;
  tvHabilidades.OptionsCustomize.ColumnsQuickCustomization := True;
  tvHabilidades.OptionsData.Editing := False;
  tvHabilidades.OptionsData.Inserting := False;
  tvHabilidades.OptionsData.Deleting := False;
  tvHabilidades.OptionsSelection.CellSelect := False;
  tvHabilidades.OptionsView.Indicator := True;
  tvHabilidades.OptionsView.GroupByBox := False;
end;

procedure TfrmGestionHabilidades.FormShow(Sender: TObject);
begin
  RefreshGrid;
end;

procedure TfrmGestionHabilidades.RefreshGrid;
var
  I: Integer;
begin
  FRows := FRepo.GetHabilidades;
  tvHabilidades.BeginUpdate;
  try
    tvHabilidades.DataController.RecordCount := 0;
    tvHabilidades.DataController.RecordCount := Length(FRows);
    for I := 0 to High(FRows) do
    begin
      tvHabilidades.DataController.Values[I, colCodigo.Index] := FRows[I].Codigo;
      tvHabilidades.DataController.Values[I, colDescripcion.Index] :=
        FRows[I].Descripcion;
    end;
  finally
    tvHabilidades.EndUpdate;
  end;
end;

procedure TfrmGestionHabilidades.btnNuevaClick(Sender: TObject);
var
  H: THabilidad;
begin
  H.Codigo := '';
  H.Descripcion := '';
  if not TfrmHabilidadEdit.Execute(H, True) then Exit;
  if FRepo.HabilidadExiste(H.Codigo) then
  begin
    MessageDlg('Ya existe una habilidad con ese c'#243'digo.',
      mtWarning, [mbOK], 0);
    Exit;
  end;
  FRepo.AddHabilidad(H);
  RefreshGrid;
end;

procedure TfrmGestionHabilidades.btnEditarClick(Sender: TObject);
var
  Idx: Integer;
  H: THabilidad;
begin
  Idx := tvHabilidades.DataController.FocusedRecordIndex;
  if (Idx < 0) or (Idx > High(FRows)) then Exit;
  H := FRows[Idx];
  if not TfrmHabilidadEdit.Execute(H, False) then Exit;
  FRepo.UpdateHabilidad(H);
  RefreshGrid;
end;

procedure TfrmGestionHabilidades.btnEliminarClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := tvHabilidades.DataController.FocusedRecordIndex;
  if (Idx < 0) or (Idx > High(FRows)) then Exit;
  if MessageDlg(Format('?Eliminar la habilidad %s?'#13#10 +
       'Se quitar'#225'n tambi'#233'n las asignaciones a operarios y operaciones.',
       [FRows[Idx].Codigo]),
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  FRepo.RemoveHabilidad(FRows[Idx].Codigo);
  RefreshGrid;
end;

procedure TfrmGestionHabilidades.tvHabilidadesDblClick(Sender: TObject);
begin
  btnEditarClick(nil);
end;

procedure TfrmGestionHabilidades.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
