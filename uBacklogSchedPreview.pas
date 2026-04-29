unit uBacklogSchedPreview;

{
  Preview modal de los resultados de auto-planificacion antes de crear nodos.
  Devuelve:
    mrOk     -> confirmar (crear nodos)
    mrRetry  -> volver al dialogo de parametros
    mrCancel -> cancelar
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  uBacklogScheduler;

type
  TfrmBacklogSchedPreview = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblKPIs: TLabel;
    pnlBottom: TPanel;
    btnConfirmar: TButton;
    btnVolver: TButton;
    btnCancel: TButton;
    grdPreview: TcxGrid;
    tvPreview: TcxGridTableView;
    lvPreview: TcxGridLevel;
    colDoc: TcxGridColumn;
    colOrigen: TcxGridColumn;
    colCentro: TcxGridColumn;
    colIni: TcxGridColumn;
    colFin: TcxGridColumn;
    colDurMin: TcxGridColumn;
    colCompromiso: TcxGridColumn;
    colEstado: TcxGridColumn;
    colObs: TcxGridColumn;
    procedure btnVolverClick(Sender: TObject);
  private
    procedure PopulateGrid(const AResult: TSchedResult);
    procedure UpdateKPIs(const AResult: TSchedResult);
  public
    class function Execute(const AResult: TSchedResult): TModalResult;
  end;

const
  mrReturnToParams = mrRetry;

implementation

{$R *.dfm}

uses
  System.DateUtils;

class function TfrmBacklogSchedPreview.Execute(
  const AResult: TSchedResult): TModalResult;
var
  F: TfrmBacklogSchedPreview;
begin
  F := TfrmBacklogSchedPreview.Create(Application);
  try
    F.UpdateKPIs(AResult);
    F.PopulateGrid(AResult);
    Result := F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmBacklogSchedPreview.btnVolverClick(Sender: TObject);
begin
  ModalResult := mrReturnToParams;
end;

procedure TfrmBacklogSchedPreview.UpdateKPIs(const AResult: TSchedResult);
begin
  lblKPIs.Caption := Format(
    'Total: %d   |   OK: %d   |   Saturados: %d   |   Fuera de plazo: %d   |   No planificables: %d',
    [Length(AResult.Items), AResult.TotalPlanificados, AResult.TotalSaturados,
     AResult.TotalFueraPlazo, AResult.TotalNoPlanificados]);
end;

procedure TfrmBacklogSchedPreview.PopulateGrid(const AResult: TSchedResult);
var
  I: Integer;
  Item: TSchedOutput;
begin
  tvPreview.BeginUpdate;
  try
    tvPreview.DataController.RecordCount := Length(AResult.Items);
    for I := 0 to High(AResult.Items) do
    begin
      Item := AResult.Items[I];
      tvPreview.DataController.Values[I, colDoc.Index] := Item.Input.CodigoDocumento;
      tvPreview.DataController.Values[I, colOrigen.Index] := Item.Input.Origen;
      tvPreview.DataController.Values[I, colCentro.Index] := Item.CenterCode;

      if Item.FechaInicio <> 0 then
        tvPreview.DataController.Values[I, colIni.Index] :=
          FormatDateTime('dd/mm/yyyy hh:nn', Item.FechaInicio)
      else
        tvPreview.DataController.Values[I, colIni.Index] := '';

      if Item.FechaFin <> 0 then
        tvPreview.DataController.Values[I, colFin.Index] :=
          FormatDateTime('dd/mm/yyyy hh:nn', Item.FechaFin)
      else
        tvPreview.DataController.Values[I, colFin.Index] := '';

      tvPreview.DataController.Values[I, colDurMin.Index] := Item.DuracionMin;

      if Item.Input.FechaCompromiso <> 0 then
        tvPreview.DataController.Values[I, colCompromiso.Index] :=
          FormatDateTime('dd/mm/yyyy', Item.Input.FechaCompromiso)
      else
        tvPreview.DataController.Values[I, colCompromiso.Index] := '';

      tvPreview.DataController.Values[I, colEstado.Index] :=
        StatusToStr(Item.Status);
      tvPreview.DataController.Values[I, colObs.Index] := Item.Observaciones;
    end;
  finally
    tvPreview.EndUpdate;
  end;
end;

end.
