unit uGestionOperacionHabilidades;

{
  TfrmGestionOperacionHabilidades - editor de las habilidades requeridas
  por cada operacion-maestro.

  Layout:
    - Izquierda: lista de operaciones (de TOperationTypesRepo).
    - Derecha: grid de habilidades requeridas (codigo + nivel min) +
      botones [+] [Editar nivel] [Eliminar].

  Usa THabilidadRepo para persistir las relaciones.
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
  uOperariosTypes, uOperationTypesRepo, uPlanProdTypes, uHabilidadRepo;

type
  TfrmGestionOperacionHabilidades = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlLeft: TPanel;
    lblOperaciones: TLabel;
    lbOperaciones: TListBox;
    pnlMain: TPanel;
    pnlActions: TPanel;
    lblHabRequeridas: TLabel;
    btnAdd: TcxButton;
    btnEdit: TcxButton;
    btnRemove: TcxButton;
    grdReqs: TcxGrid;
    tvReqs: TcxGridTableView;
    colReq_Cod: TcxGridColumn;
    colReq_Desc: TcxGridColumn;
    colReq_Nivel: TcxGridColumn;
    lvReqs: TcxGridLevel;
    pnlBottom: TPanel;
    btnCerrar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lbOperacionesClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure tvReqsDblClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FTiposRepo: TOperationTypesRepo;
    FHabRepo: THabilidadRepo;
    FCurrentOperacion: string;
    FCurrentReqs: TArray<TOperacionHabilidad>;
    procedure LoadOperaciones;
    procedure RefreshReqs;
    function CurrentReqIdx: Integer;
  public
    class procedure Execute(ATiposRepo: TOperationTypesRepo;
      AHabRepo: THabilidadRepo);
  end;

implementation

uses
  uHabilidadPicker;

{$R *.dfm}

class procedure TfrmGestionOperacionHabilidades.Execute(
  ATiposRepo: TOperationTypesRepo; AHabRepo: THabilidadRepo);
var
  F: TfrmGestionOperacionHabilidades;
begin
  if not Assigned(ATiposRepo) or not Assigned(AHabRepo) then Exit;
  F := TfrmGestionOperacionHabilidades.Create(nil);
  try
    F.FTiposRepo := ATiposRepo;
    F.FHabRepo := AHabRepo;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmGestionOperacionHabilidades.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
  tvReqs.OptionsBehavior.IncSearch := True;
  tvReqs.OptionsCustomize.ColumnsQuickCustomization := True;
  tvReqs.OptionsData.Editing := False;
  tvReqs.OptionsSelection.CellSelect := False;
  tvReqs.OptionsView.Indicator := True;
  tvReqs.OptionsView.GroupByBox := False;
end;

procedure TfrmGestionOperacionHabilidades.FormShow(Sender: TObject);
begin
  LoadOperaciones;
  if lbOperaciones.Count > 0 then
  begin
    lbOperaciones.ItemIndex := 0;
    lbOperacionesClick(nil);
  end;
end;

procedure TfrmGestionOperacionHabilidades.LoadOperaciones;
var
  Tipos: TArray<TTipoOperacion>;
  I: Integer;
begin
  Tipos := FTiposRepo.GetAll;
  lbOperaciones.Items.BeginUpdate;
  try
    lbOperaciones.Items.Clear;
    for I := 0 to High(Tipos) do
      lbOperaciones.Items.Add(Tipos[I].Operacion);
  finally
    lbOperaciones.Items.EndUpdate;
  end;
end;

procedure TfrmGestionOperacionHabilidades.lbOperacionesClick(Sender: TObject);
begin
  if lbOperaciones.ItemIndex < 0 then
    FCurrentOperacion := ''
  else
    FCurrentOperacion := lbOperaciones.Items[lbOperaciones.ItemIndex];
  RefreshReqs;
end;

procedure TfrmGestionOperacionHabilidades.RefreshReqs;
var
  I: Integer;
  H: THabilidad;
  Desc: string;
begin
  if FCurrentOperacion = '' then
    SetLength(FCurrentReqs, 0)
  else
    FCurrentReqs := FHabRepo.GetHabilidadesOperacion(FCurrentOperacion);
  lblHabRequeridas.Caption :=
    Format('Habilidades requeridas por %s (%d)',
      [FCurrentOperacion, Length(FCurrentReqs)]);
  tvReqs.BeginUpdate;
  try
    tvReqs.DataController.RecordCount := 0;
    tvReqs.DataController.RecordCount := Length(FCurrentReqs);
    for I := 0 to High(FCurrentReqs) do
    begin
      tvReqs.DataController.Values[I, colReq_Cod.Index] :=
        FCurrentReqs[I].CodHabilidad;
      Desc := '';
      if FHabRepo.GetHabilidad(FCurrentReqs[I].CodHabilidad, H) then
        Desc := H.Descripcion;
      tvReqs.DataController.Values[I, colReq_Desc.Index] := Desc;
      tvReqs.DataController.Values[I, colReq_Nivel.Index] :=
        Format('%s (%d)',
          [NivelSkillToStr(FCurrentReqs[I].NivelMinimo),
           Ord(FCurrentReqs[I].NivelMinimo)]);
    end;
  finally
    tvReqs.EndUpdate;
  end;
end;

function TfrmGestionOperacionHabilidades.CurrentReqIdx: Integer;
begin
  Result := tvReqs.DataController.FocusedRecordIndex;
  if (Result < 0) or (Result > High(FCurrentReqs)) then Result := -1;
end;

procedure TfrmGestionOperacionHabilidades.btnAddClick(Sender: TObject);
var
  CodSel: string;
  Nivel: TNivelSkill;
  I: Integer;
  Excluir: TArray<string>;
begin
  if FCurrentOperacion = '' then Exit;

  // Excluir las que ya tiene
  SetLength(Excluir, Length(FCurrentReqs));
  for I := 0 to High(FCurrentReqs) do
    Excluir[I] := FCurrentReqs[I].CodHabilidad;

  if not TfrmHabilidadPicker.Execute(FHabRepo,
    Format('A'#241'adir habilidad a %s', [FCurrentOperacion]),
    CodSel, Nivel, Excluir) then Exit;

  FHabRepo.SetOperacionHabilidad(FCurrentOperacion, CodSel, Nivel);
  RefreshReqs;
end;

procedure TfrmGestionOperacionHabilidades.btnEditClick(Sender: TObject);
var
  Idx: Integer;
  NivelStr: string;
  NuevoIdx: Integer;
begin
  Idx := CurrentReqIdx;
  if Idx < 0 then Exit;
  NivelStr := IntToStr(Ord(FCurrentReqs[Idx].NivelMinimo));
  if not InputQuery('Cambiar nivel m'#237'nimo',
    Format('%s en %s'#13#10'0=Aprendiz, 1=Junior, 2=Senior, 3=Experto',
      [FCurrentReqs[Idx].CodHabilidad, FCurrentOperacion]),
    NivelStr) then Exit;
  NuevoIdx := StrToIntDef(NivelStr, -1);
  if NuevoIdx < 0 then NuevoIdx := 0
  else if NuevoIdx > 3 then NuevoIdx := 3;
  FHabRepo.SetOperacionHabilidad(FCurrentOperacion,
    FCurrentReqs[Idx].CodHabilidad, TNivelSkill(NuevoIdx));
  RefreshReqs;
end;

procedure TfrmGestionOperacionHabilidades.btnRemoveClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := CurrentReqIdx;
  if Idx < 0 then Exit;
  if MessageDlg(Format('?Quitar habilidad %s de %s?',
       [FCurrentReqs[Idx].CodHabilidad, FCurrentOperacion]),
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  FHabRepo.RemoveOperacionHabilidad(FCurrentOperacion,
    FCurrentReqs[Idx].CodHabilidad);
  RefreshReqs;
end;

procedure TfrmGestionOperacionHabilidades.tvReqsDblClick(Sender: TObject);
begin
  btnEditClick(nil);
end;

procedure TfrmGestionOperacionHabilidades.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
