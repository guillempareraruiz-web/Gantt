unit uGestionUtillajes;

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
  Data.Win.ADODB, Data.DB,
  uUtillajesRepo;

type
  TfrmGestionUtillajes = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnClose: TButton;
    pnlToolbar: TPanel;
    btnAdd: TButton;
    btnDel: TButton;
    btnSave: TButton;
    gridUtil: TcxGrid;
    tvUtil: TcxGridTableView;
    colId: TcxGridColumn;
    colCodigo: TcxGridColumn;
    colDescripcion: TcxGridColumn;
    colTipo: TcxGridColumn;
    colUbicacion: TcxGridColumn;
    colDisponible: TcxGridColumn;
    colObservaciones: TcxGridColumn;
    colOrden: TcxGridColumn;
    colActivo: TcxGridColumn;
    lvUtil: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    FRepo: TUtillajesRepo;
    FIds: TArray<Integer>;
    FDeleted: TList<Integer>;
    procedure LoadGrid;
    procedure CollectRow(I: Integer; out U: TUtillaje);
  public
    class procedure Execute;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

class procedure TfrmGestionUtillajes.Execute;
var
  F: TfrmGestionUtillajes;
begin
  F := TfrmGestionUtillajes.Create(nil);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmGestionUtillajes.FormCreate(Sender: TObject);
begin
  FRepo := TUtillajesRepo.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  FDeleted := TList<Integer>.Create;
  tvUtil.OptionsData.Editing := True;
  tvUtil.OptionsSelection.CellSelect := True;
  LoadGrid;
end;

procedure TfrmGestionUtillajes.FormDestroy(Sender: TObject);
begin
  FDeleted.Free;
  FRepo.Free;
end;

procedure TfrmGestionUtillajes.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmGestionUtillajes.LoadGrid;
var
  Rows: TArray<TUtillaje>;
  I: Integer;
  U: TUtillaje;
begin
  FDeleted.Clear;
  Rows := FRepo.LoadAll;

  tvUtil.BeginUpdate;
  try
    tvUtil.DataController.RecordCount := 0;
    tvUtil.DataController.RecordCount := Length(Rows);
    SetLength(FIds, Length(Rows));
    for I := 0 to High(Rows) do
    begin
      U := Rows[I];
      FIds[I] := U.Id;
      tvUtil.DataController.Values[I, colId.Index]            := U.Id;
      tvUtil.DataController.Values[I, colCodigo.Index]        := U.Codigo;
      tvUtil.DataController.Values[I, colDescripcion.Index]   := U.Descripcion;
      tvUtil.DataController.Values[I, colTipo.Index]          := U.Tipo;
      tvUtil.DataController.Values[I, colUbicacion.Index]     := U.Ubicacion;
      tvUtil.DataController.Values[I, colDisponible.Index]    := U.Disponible;
      tvUtil.DataController.Values[I, colObservaciones.Index] := U.Observaciones;
      tvUtil.DataController.Values[I, colOrden.Index]         := U.Orden;
      tvUtil.DataController.Values[I, colActivo.Index]        := U.Activo;
    end;
  finally
    tvUtil.EndUpdate;
  end;
end;

procedure TfrmGestionUtillajes.CollectRow(I: Integer; out U: TUtillaje);
  function AsStr(AV: Variant): string;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := '' else Result := VarToStr(AV);
  end;
  function AsInt(AV: Variant; ADef: Integer): Integer;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADef else Result := Integer(AV);
  end;
  function AsBool(AV: Variant; ADef: Boolean): Boolean;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then Result := ADef else Result := Boolean(AV);
  end;
begin
  U := Default(TUtillaje);
  if I < Length(FIds) then U.Id := FIds[I] else U.Id := 0;

  U.Codigo        := AsStr(tvUtil.DataController.Values[I, colCodigo.Index]);
  U.Descripcion   := AsStr(tvUtil.DataController.Values[I, colDescripcion.Index]);
  U.Tipo          := AsStr(tvUtil.DataController.Values[I, colTipo.Index]);
  U.Ubicacion     := AsStr(tvUtil.DataController.Values[I, colUbicacion.Index]);
  U.Disponible    := AsBool(tvUtil.DataController.Values[I, colDisponible.Index], True);
  U.Observaciones := AsStr(tvUtil.DataController.Values[I, colObservaciones.Index]);
  U.Orden         := AsInt(tvUtil.DataController.Values[I, colOrden.Index], 0);
  U.Activo        := AsBool(tvUtil.DataController.Values[I, colActivo.Index], True);
end;

procedure TfrmGestionUtillajes.btnAddClick(Sender: TObject);
var
  Cnt: Integer;
  Codigo: string;
begin
  Codigo := InputBox('Nuevo utillaje', 'C'#243'digo:', '');
  if Trim(Codigo) = '' then Exit;

  Cnt := tvUtil.DataController.RecordCount;
  tvUtil.DataController.RecordCount := Cnt + 1;
  SetLength(FIds, Cnt + 1);
  FIds[Cnt] := 0;

  tvUtil.DataController.Values[Cnt, colId.Index]            := 0;
  tvUtil.DataController.Values[Cnt, colCodigo.Index]        := Codigo;
  tvUtil.DataController.Values[Cnt, colDescripcion.Index]   := '';
  tvUtil.DataController.Values[Cnt, colTipo.Index]          := '';
  tvUtil.DataController.Values[Cnt, colUbicacion.Index]     := '';
  tvUtil.DataController.Values[Cnt, colDisponible.Index]    := True;
  tvUtil.DataController.Values[Cnt, colObservaciones.Index] := '';
  tvUtil.DataController.Values[Cnt, colOrden.Index]         := 0;
  tvUtil.DataController.Values[Cnt, colActivo.Index]        := True;

  tvUtil.Controller.FocusedRecordIndex := Cnt;
end;

procedure TfrmGestionUtillajes.btnDelClick(Sender: TObject);
var
  Idx, UtilId, I: Integer;
  NewIds: TArray<Integer>;
begin
  Idx := tvUtil.Controller.FocusedRecordIndex;
  if Idx < 0 then Exit;
  if MessageDlg(#191'Eliminar el utillaje seleccionado?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;

  if Idx < Length(FIds) then
  begin
    UtilId := FIds[Idx];
    if UtilId > 0 then FDeleted.Add(UtilId);
  end;

  SetLength(NewIds, Length(FIds) - 1);
  for I := 0 to High(FIds) do
    if I < Idx then NewIds[I] := FIds[I]
    else if I > Idx then NewIds[I - 1] := FIds[I];
  FIds := NewIds;

  tvUtil.DataController.DeleteRecord(Idx);
end;

procedure TfrmGestionUtillajes.btnSaveClick(Sender: TObject);
var
  I, NewId: Integer;
  U: TUtillaje;
begin
  if tvUtil.Controller.EditingController.IsEditing then
    tvUtil.Controller.EditingController.HideEdit(True);
  tvUtil.DataController.Post(False);

  for I := 0 to FDeleted.Count - 1 do
    FRepo.Delete(FDeleted[I]);
  FDeleted.Clear;

  for I := 0 to tvUtil.DataController.RecordCount - 1 do
  begin
    CollectRow(I, U);
    if Trim(U.Codigo) = '' then Continue;

    if U.Id <= 0 then
    begin
      NewId := FRepo.Insert(U);
      if I < Length(FIds) then FIds[I] := NewId;
      tvUtil.DataController.Values[I, colId.Index] := NewId;
    end
    else
      FRepo.Update(U);
  end;

  LoadGrid;
  ShowMessage('Utillajes guardados correctamente.');
end;

end.
