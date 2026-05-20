unit uEditarListaMolde;

// Dialogo generico para editar la lista de relaciones de un molde con atributos.
// Tres modos:
//   elkArticulos:   codigo + CavidadesActivas + Observaciones
//   elkOperaciones: codigo + CiclosPorUnidad   + Observaciones
//   elkUtillajes:   codigo + Obligatorio       + Observaciones

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxTextEdit, cxCheckBox,
  cxSpinEdit, cxButtonEdit, cxContainer, cxClasses, cxFilter,
  dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  Data.Win.ADODB, Data.DB,
  uMoldeRepoSQL;

type
  TEditarListaMoldeKind = (elkArticulos, elkOperaciones, elkUtillajes);

  TfrmEditarListaMolde = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnDel: TButton;
    gridItems: TcxGrid;
    tvItems: TcxGridTableView;
    colCodigo: TcxGridColumn;
    colNumero: TcxGridColumn;
    colCheck: TcxGridColumn;
    colObs: TcxGridColumn;
    lvItems: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure colCodigoButtonClick(Sender: TObject; AButtonIndex: Integer);
  private
    FRepo: TMoldeRepoSQL;
    FMoldId: Integer;
    FMoldCodigo: string;
    FKind: TEditarListaMoldeKind;
    procedure ConfigureColumns;
    procedure LoadItems;
    procedure SaveItems;
  public
    class function Execute(AMoldId: Integer; const AMoldCodigo: string;
      AKind: TEditarListaMoldeKind): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uErpReaderFactory, uErpReader,
  uArticuloPicker, uOperacionPicker, uUtillajePicker;

class function TfrmEditarListaMolde.Execute(AMoldId: Integer;
  const AMoldCodigo: string; AKind: TEditarListaMoldeKind): Boolean;
var
  F: TfrmEditarListaMolde;
begin
  F := TfrmEditarListaMolde.Create(Application);
  try
    F.FMoldId := AMoldId;
    F.FMoldCodigo := AMoldCodigo;
    F.FKind := AKind;
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmEditarListaMolde.FormCreate(Sender: TObject);
begin
  FRepo := TMoldeRepoSQL.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  tvItems.OptionsData.Editing := True;
  tvItems.OptionsSelection.CellSelect := True;
  // ConfigureColumns / LoadItems van a FormShow: FKind aun no esta asignado en
  // FormCreate (Execute lo pone entre Create y ShowModal).
end;

procedure TfrmEditarListaMolde.FormShow(Sender: TObject);
begin
  ConfigureColumns;
  lblSubtitle.Caption := 'Molde: ' + FMoldCodigo;
  LoadItems;
end;

procedure TfrmEditarListaMolde.FormDestroy(Sender: TObject);
begin
  FRepo.Free;
end;

procedure TfrmEditarListaMolde.ConfigureColumns;
begin
  case FKind of
    elkArticulos:
      begin
        Caption := 'Art'#237'culos del molde';
        lblTitle.Caption := 'Art'#237'culos fabricables';
        colCodigo.Caption := 'C'#243'digo art'#237'culo';
        colNumero.Caption := 'Cavidades activas';
        colNumero.Visible := True;
        colCheck.Visible := False;
        colObs.Visible := True;
      end;
    elkOperaciones:
      begin
        Caption := 'Operaciones del molde';
        lblTitle.Caption := 'Operaciones compatibles';
        colCodigo.Caption := 'Operaci'#243'n';
        colNumero.Caption := 'Ciclos / unidad';
        colNumero.Visible := True;
        colCheck.Visible := False;
        colObs.Visible := True;
      end;
    elkUtillajes:
      begin
        Caption := 'Utillajes del molde';
        lblTitle.Caption := 'Utillajes asociados';
        colCodigo.Caption := 'C'#243'digo utillaje';
        colNumero.Visible := False;
        colCheck.Caption := 'Obligatorio';
        colCheck.Visible := True;
        colObs.Visible := True;
      end;
  end;
end;

procedure TfrmEditarListaMolde.LoadItems;
var
  Art: TArray<TMoldeArticleRow>;
  Op: TArray<TMoldeOperationRow>;
  Ut: TArray<TMoldeUtillajeRow>;
  I: Integer;
begin
  tvItems.BeginUpdate;
  try
    tvItems.DataController.RecordCount := 0;
    case FKind of
      elkArticulos:
        begin
          Art := FRepo.GetArticulos(FMoldId);
          tvItems.DataController.RecordCount := Length(Art);
          for I := 0 to High(Art) do
          begin
            tvItems.DataController.Values[I, colCodigo.Index] := Art[I].CodigoArticulo;
            tvItems.DataController.Values[I, colNumero.Index] := Art[I].CavidadesActivas;
            tvItems.DataController.Values[I, colObs.Index]    := Art[I].Observaciones;
          end;
        end;
      elkOperaciones:
        begin
          Op := FRepo.GetOperaciones(FMoldId);
          tvItems.DataController.RecordCount := Length(Op);
          for I := 0 to High(Op) do
          begin
            tvItems.DataController.Values[I, colCodigo.Index] := Op[I].Operacion;
            tvItems.DataController.Values[I, colNumero.Index] := Op[I].CiclosPorUnidad;
            tvItems.DataController.Values[I, colObs.Index]    := Op[I].Observaciones;
          end;
        end;
      elkUtillajes:
        begin
          Ut := FRepo.GetUtillajes(FMoldId);
          tvItems.DataController.RecordCount := Length(Ut);
          for I := 0 to High(Ut) do
          begin
            tvItems.DataController.Values[I, colCodigo.Index] := Ut[I].CodigoUtillaje;
            tvItems.DataController.Values[I, colCheck.Index]  := Ut[I].Obligatorio;
            tvItems.DataController.Values[I, colObs.Index]    := Ut[I].Observaciones;
          end;
        end;
    end;
  finally
    tvItems.EndUpdate;
  end;
end;

procedure TfrmEditarListaMolde.btnAddClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := tvItems.DataController.AppendRecord;
  tvItems.DataController.Values[Idx, colCodigo.Index] := '';
  case FKind of
    elkArticulos:   tvItems.DataController.Values[Idx, colNumero.Index] := 1;
    elkOperaciones: tvItems.DataController.Values[Idx, colNumero.Index] := 1;
    elkUtillajes:   tvItems.DataController.Values[Idx, colCheck.Index]  := True;
  end;
  tvItems.DataController.Values[Idx, colObs.Index] := '';
  tvItems.Controller.FocusedRecordIndex := Idx;
end;

procedure TfrmEditarListaMolde.btnDelClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := tvItems.Controller.FocusedRecordIndex;
  if Idx < 0 then Exit;
  tvItems.DataController.DeleteRecord(Idx);
end;

procedure TfrmEditarListaMolde.SaveItems;
var
  Art: TArray<TMoldeArticleRow>;
  Op: TArray<TMoldeOperationRow>;
  Ut: TArray<TMoldeUtillajeRow>;
  I: Integer;
  Codigo, Obs: string;
  NumF: Double;
  Obl: Boolean;
  function AsStr(AV: Variant): string;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := '' else Result := VarToStr(AV);
  end;
  function AsInt(AV: Variant; ADef: Integer): Integer;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADef else Result := Integer(AV);
  end;
  function AsFloat(AV: Variant; ADef: Double): Double;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADef else Result := Double(AV);
  end;
  function AsBool(AV: Variant; ADef: Boolean): Boolean;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADef else Result := Boolean(AV);
  end;
begin
  case FKind of
    elkArticulos:
      begin
        SetLength(Art, 0);
        for I := 0 to tvItems.DataController.RecordCount - 1 do
        begin
          Codigo := Trim(AsStr(tvItems.DataController.Values[I, colCodigo.Index]));
          if Codigo = '' then Continue;
          SetLength(Art, Length(Art) + 1);
          Art[High(Art)].CodigoArticulo := Codigo;
          Art[High(Art)].CavidadesActivas := AsInt(tvItems.DataController.Values[I, colNumero.Index], 0);
          Art[High(Art)].Observaciones := AsStr(tvItems.DataController.Values[I, colObs.Index]);
        end;
        FRepo.SaveArticulos(FMoldId, Art);
      end;
    elkOperaciones:
      begin
        SetLength(Op, 0);
        for I := 0 to tvItems.DataController.RecordCount - 1 do
        begin
          Codigo := Trim(AsStr(tvItems.DataController.Values[I, colCodigo.Index]));
          if Codigo = '' then Continue;
          NumF := AsFloat(tvItems.DataController.Values[I, colNumero.Index], 1);
          if NumF <= 0 then NumF := 1;
          Obs := AsStr(tvItems.DataController.Values[I, colObs.Index]);
          SetLength(Op, Length(Op) + 1);
          Op[High(Op)].Operacion := Codigo;
          Op[High(Op)].CiclosPorUnidad := NumF;
          Op[High(Op)].Observaciones := Obs;
        end;
        FRepo.SaveOperaciones(FMoldId, Op);
      end;
    elkUtillajes:
      begin
        SetLength(Ut, 0);
        for I := 0 to tvItems.DataController.RecordCount - 1 do
        begin
          Codigo := Trim(AsStr(tvItems.DataController.Values[I, colCodigo.Index]));
          if Codigo = '' then Continue;
          Obl := AsBool(tvItems.DataController.Values[I, colCheck.Index], True);
          Obs := AsStr(tvItems.DataController.Values[I, colObs.Index]);
          SetLength(Ut, Length(Ut) + 1);
          Ut[High(Ut)].CodigoUtillaje := Codigo;
          Ut[High(Ut)].Obligatorio := Obl;
          Ut[High(Ut)].Observaciones := Obs;
        end;
        FRepo.SaveUtillajes(FMoldId, Ut);
      end;
  end;
end;

procedure TfrmEditarListaMolde.colCodigoButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  Idx: Integer;
  Cod, Desc: string;
  Reader: IErpReader;
  Picked: Boolean;
begin
  Idx := tvItems.Controller.FocusedRecordIndex;
  if Idx < 0 then Exit;

  Picked := False;
  Cod := '';
  Desc := '';

  case FKind of
    elkArticulos:
      begin
        Reader := GetActiveErpReader;
        if Reader = nil then
        begin
          ShowMessage('No hay conector ERP activo: no se puede listar art'#237'culos.');
          Exit;
        end;
        Picked := TfrmArticuloPicker.Execute(Reader, Cod, Desc);
      end;
    elkOperaciones:
      begin
        Picked := TfrmOperacionPicker.Execute(Cod, Desc);
      end;
    elkUtillajes:
      begin
        Picked := TfrmUtillajePicker.Execute(Cod, Desc);
      end;
  end;

  if not Picked then Exit;
  if Trim(Cod) = '' then Exit;

  // Forzar cierre del editor en curso y escribir el valor en la celda
  if tvItems.Controller.EditingController.IsEditing then
    tvItems.Controller.EditingController.HideEdit(True);
  tvItems.DataController.Values[Idx, colCodigo.Index] := Cod;
  // Si la fila no lleva todavia observaciones y el picker da descripcion, la prefijamos
  if (Desc <> '') and
     (Trim(VarToStr(tvItems.DataController.Values[Idx, colObs.Index])) = '') then
    tvItems.DataController.Values[Idx, colObs.Index] := Desc;
end;

procedure TfrmEditarListaMolde.btnOKClick(Sender: TObject);
begin
  if tvItems.Controller.EditingController.IsEditing then
    tvItems.Controller.EditingController.HideEdit(True);
  tvItems.DataController.Post(False);

  try
    SaveItems;
  except
    on E: Exception do
    begin
      ShowMessage('Error: ' + E.Message);
      ModalResult := mrNone;
      Exit;
    end;
  end;
  ModalResult := mrOk;
end;

end.
