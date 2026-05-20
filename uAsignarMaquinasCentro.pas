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
  cxSpinEdit, cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  uMaquinasRepo, dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
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
    colPrincipal: TcxGridColumn;
    colPrioridad: TcxGridColumn;
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
    procedure SaveLinkAttributes(const ASelectedIds: TArray<Integer>);
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
  Links: TArray<TCentroMaquinaLink>;
  PrincipalMap: TDictionary<Integer, Boolean>;
  PrioridadMap: TDictionary<Integer, Integer>;
  I: Integer;
begin
  if FCenterCaption <> '' then
    lblSubtitle.Caption := 'Centro: ' + FCenterCaption;

  FRepo.LoadFromDB;
  Items := FRepo.GetAll;
  Links := FRepo.GetLinksForCentro(FCenterId);

  PrincipalMap := TDictionary<Integer, Boolean>.Create;
  PrioridadMap := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to High(Links) do
    begin
      PrincipalMap.AddOrSetValue(Links[I].MaquinaId, Links[I].EsPrincipal);
      PrioridadMap.AddOrSetValue(Links[I].MaquinaId, Links[I].Prioridad);
    end;

    SetLength(FIds, Length(Items));
    tvMaquinas.BeginUpdate;
    try
      tvMaquinas.DataController.RecordCount := 0;
      tvMaquinas.DataController.RecordCount := Length(Items);
      for I := 0 to High(Items) do
      begin
        FIds[I] := Items[I].Id;
        tvMaquinas.DataController.Values[I, colSel.Index]    := PrincipalMap.ContainsKey(Items[I].Id);
        tvMaquinas.DataController.Values[I, colCodigo.Index] := Items[I].Codigo;
        tvMaquinas.DataController.Values[I, colNombre.Index] := Items[I].Nombre;
        tvMaquinas.DataController.Values[I, colPrincipal.Index] :=
          PrincipalMap.ContainsKey(Items[I].Id) and PrincipalMap[Items[I].Id];
        if PrioridadMap.ContainsKey(Items[I].Id) then
          tvMaquinas.DataController.Values[I, colPrioridad.Index] := PrioridadMap[Items[I].Id]
        else
          tvMaquinas.DataController.Values[I, colPrioridad.Index] := 100;
      end;
    finally
      tvMaquinas.EndUpdate;
    end;
  finally
    PrincipalMap.Free;
    PrioridadMap.Free;
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

procedure TfrmAsignarMaquinasCentro.SaveLinkAttributes(
  const ASelectedIds: TArray<Integer>);
var
  Idx, I, MaquinaId, Prio: Integer;
  IsPrincipal: Boolean;
  V: Variant;
  RowByMaqId: TDictionary<Integer, Integer>;
begin
  // Construir mapeo MaquinaId -> indice de fila para localizar valores
  RowByMaqId := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to High(FIds) do
      RowByMaqId.AddOrSetValue(FIds[I], I);

    for I := 0 to High(ASelectedIds) do
    begin
      MaquinaId := ASelectedIds[I];
      if not RowByMaqId.TryGetValue(MaquinaId, Idx) then Continue;

      V := tvMaquinas.DataController.Values[Idx, colPrincipal.Index];
      if VarIsNull(V) or VarIsEmpty(V) then IsPrincipal := False
      else
        try
          IsPrincipal := Boolean(V);
        except
          IsPrincipal := False;
        end;

      V := tvMaquinas.DataController.Values[Idx, colPrioridad.Index];
      if VarIsNull(V) or VarIsEmpty(V) then Prio := 100 else Prio := Integer(V);
      if Prio <= 0 then Prio := 100;

      FRepo.SetMaquinaLink(FCenterId, MaquinaId, IsPrincipal, Prio);
    end;
  finally
    RowByMaqId.Free;
  end;
end;

procedure TfrmAsignarMaquinasCentro.btnOkClick(Sender: TObject);
var
  SelectedIds: TArray<Integer>;
begin
  // Forzar commit de la celda en edicion (el ultimo check puede estar in-flight)
  if tvMaquinas.Controller.EditingController.IsEditing then
    tvMaquinas.Controller.EditingController.HideEdit(True);
  tvMaquinas.DataController.Post(False);

  SelectedIds := CollectSelected;

  try
    // 1) Sincronizar pertenencia N:M (borra y reinserta marcadas)
    FRepo.SetMaquinasForCentro(FCenterId, SelectedIds);
    // 2) Actualizar atributos de relacion (Principal, Prioridad) para las marcadas
    SaveLinkAttributes(SelectedIds);
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
