unit uAsignarCentrosMolde;

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
  uMoldeRepoSQL;

type
  TfrmAsignarCentrosMolde = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    gridCentros: TcxGrid;
    tvCentros: TcxGridTableView;
    colAsig: TcxGridColumn;
    colCentroId: TcxGridColumn;
    colCentro: TcxGridColumn;
    colPreferente: TcxGridColumn;
    colTEspec: TcxGridColumn;
    lvCentros: TcxGridLevel;
    LookAndFeel: TcxLookAndFeelController;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    FRepo: TMoldeRepoSQL;
    FMoldId: Integer;
    FMoldCodigo: string;
    FCenterIds: TArray<Integer>;
    procedure LoadGrid;
    function CollectRows: TArray<TMoldeCenterRow>;
  public
    class function Execute(AMoldId: Integer; const AMoldCodigo: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

class function TfrmAsignarCentrosMolde.Execute(AMoldId: Integer;
  const AMoldCodigo: string): Boolean;
var
  F: TfrmAsignarCentrosMolde;
begin
  F := TfrmAsignarCentrosMolde.Create(Application);
  try
    F.FMoldId := AMoldId;
    F.FMoldCodigo := AMoldCodigo;
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmAsignarCentrosMolde.FormCreate(Sender: TObject);
begin
  FRepo := TMoldeRepoSQL.Create(DMPlanner.ADOConnection, DMPlanner.CodigoEmpresa);
  tvCentros.OptionsData.Editing := True;
  tvCentros.OptionsSelection.CellSelect := True;
end;

procedure TfrmAsignarCentrosMolde.FormShow(Sender: TObject);
begin
  lblSubtitle.Caption := 'Molde: ' + FMoldCodigo;
  LoadGrid;
end;

procedure TfrmAsignarCentrosMolde.FormDestroy(Sender: TObject);
begin
  FRepo.Free;
end;

procedure TfrmAsignarCentrosMolde.LoadGrid;
var
  Q: TADOQuery;
  Existing: TArray<TMoldeCenterRow>;
  PrefMap: TDictionary<Integer, Boolean>;
  TimeMap: TDictionary<Integer, Double>;
  AsigSet: TDictionary<Integer, Boolean>;
  CenterId, I: Integer;
begin
  Existing := FRepo.GetCentros(FMoldId);
  PrefMap := TDictionary<Integer, Boolean>.Create;
  TimeMap := TDictionary<Integer, Double>.Create;
  AsigSet := TDictionary<Integer, Boolean>.Create;
  try
    for I := 0 to High(Existing) do
    begin
      AsigSet.AddOrSetValue(Existing[I].CenterId, True);
      PrefMap.AddOrSetValue(Existing[I].CenterId, Existing[I].Preferente);
      TimeMap.AddOrSetValue(Existing[I].CenterId, Existing[I].TiempoMontajeEspecifico);
    end;

    SetLength(FCenterIds, 0);
    tvCentros.BeginUpdate;
    try
      tvCentros.DataController.RecordCount := 0;
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := DMPlanner.ADOConnection;
        Q.SQL.Text :=
          'SELECT CenterId, Titulo FROM FS_PL_Center ' +
          'WHERE CodigoEmpresa = :CE AND Visible = 1 ' +
          'ORDER BY Orden, Titulo';
        Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
        Q.Open;
        I := 0;
        while not Q.Eof do
        begin
          CenterId := Q.FieldByName('CenterId').AsInteger;
          tvCentros.DataController.RecordCount := I + 1;
          SetLength(FCenterIds, I + 1);
          FCenterIds[I] := CenterId;

          tvCentros.DataController.Values[I, colAsig.Index]      := AsigSet.ContainsKey(CenterId);
          tvCentros.DataController.Values[I, colCentroId.Index]  := CenterId;
          tvCentros.DataController.Values[I, colCentro.Index]    := Q.FieldByName('Titulo').AsString;
          if PrefMap.ContainsKey(CenterId) then
            tvCentros.DataController.Values[I, colPreferente.Index] := PrefMap[CenterId]
          else
            tvCentros.DataController.Values[I, colPreferente.Index] := False;
          if TimeMap.ContainsKey(CenterId) then
            tvCentros.DataController.Values[I, colTEspec.Index] := TimeMap[CenterId]
          else
            tvCentros.DataController.Values[I, colTEspec.Index] := 0;

          Inc(I);
          Q.Next;
        end;
      finally
        Q.Free;
      end;
    finally
      tvCentros.EndUpdate;
    end;
  finally
    AsigSet.Free;
    TimeMap.Free;
    PrefMap.Free;
  end;
end;

function TfrmAsignarCentrosMolde.CollectRows: TArray<TMoldeCenterRow>;
var
  I: Integer;
  V: Variant;
  L: TList<TMoldeCenterRow>;
  R: TMoldeCenterRow;
  Asig: Boolean;
begin
  L := TList<TMoldeCenterRow>.Create;
  try
    for I := 0 to tvCentros.DataController.RecordCount - 1 do
    begin
      if I > High(FCenterIds) then Continue;

      V := tvCentros.DataController.Values[I, colAsig.Index];
      if VarIsNull(V) or VarIsEmpty(V) then Asig := False
      else
        try
          Asig := Boolean(V);
        except
          Asig := False;
        end;
      if not Asig then Continue;

      R.CenterId := FCenterIds[I];

      V := tvCentros.DataController.Values[I, colPreferente.Index];
      if VarIsNull(V) or VarIsEmpty(V) then R.Preferente := False
      else
        try
          R.Preferente := Boolean(V);
        except
          R.Preferente := False;
        end;

      V := tvCentros.DataController.Values[I, colTEspec.Index];
      if VarIsNull(V) or VarIsEmpty(V) then R.TiempoMontajeEspecifico := 0
      else R.TiempoMontajeEspecifico := Double(V);

      L.Add(R);
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure TfrmAsignarCentrosMolde.btnOKClick(Sender: TObject);
begin
  if tvCentros.Controller.EditingController.IsEditing then
    tvCentros.Controller.EditingController.HideEdit(True);
  tvCentros.DataController.Post(False);

  try
    FRepo.SaveCentros(FMoldId, CollectRows);
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
