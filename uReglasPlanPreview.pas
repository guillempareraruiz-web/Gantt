unit uReglasPlanPreview;

{
  Preview (solo lectura) del resultado del motor de planificacion POR REGLAS.

  Muestra el orden propuesto de la cola. Los KPIs van como "tarjetas" en el
  header (mismo estilo que uFiniteCapacityPlanner):
    - Planificadas / Saturadas / Fuera de plazo
    - Retrasos previstos, Retraso total (h), Makespan (h)

  NO modifica el plan: es una previsualizacion. El commit (reescribir fechas de
  los nodos) queda para una fase posterior. Se cierra con la X o con Esc.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, cxCustomData, cxData, cxDataStorage, cxNavigator,
  uBacklogScheduler;

type
  TfrmReglasPlanPreview = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlKpiPlan: TPanel;
    lblKpiPlanVal: TLabel;
    lblKpiPlanCap: TLabel;
    pnlKpiSat: TPanel;
    lblKpiSatVal: TLabel;
    lblKpiSatCap: TLabel;
    pnlKpiFuera: TPanel;
    lblKpiFueraVal: TLabel;
    lblKpiFueraCap: TLabel;
    pnlKpiRetr: TPanel;
    lblKpiRetrVal: TLabel;
    lblKpiRetrCap: TLabel;
    pnlKpiRetrTot: TPanel;
    lblKpiRetrTotVal: TLabel;
    lblKpiRetrTotCap: TLabel;
    pnlKpiMakespan: TPanel;
    lblKpiMakespanVal: TLabel;
    lblKpiMakespanCap: TLabel;
    grdPreview: TcxGrid;
    tvPreview: TcxGridTableView;
    lvPreview: TcxGridLevel;
    colOrden: TcxGridColumn;
    colDoc: TcxGridColumn;
    colCentro: TcxGridColumn;
    colIni: TcxGridColumn;
    colFin: TcxGridColumn;
    colDurMin: TcxGridColumn;
    colCompromiso: TcxGridColumn;
    colRetraso: TcxGridColumn;
    colEstado: TcxGridColumn;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    procedure PopulateGrid(const AResult: TSchedResult);
    procedure UpdateKPIs(const AResult: TSchedResult);
  public
    class procedure Execute(const AResult: TSchedResult;
      const ATituloRegla: string);
  end;

implementation

{$R *.dfm}

uses
  System.DateUtils, uHelpViewer;

procedure TfrmReglasPlanPreview.FormCreate(Sender: TObject);
begin
  THelpViewer.InstallHelp(Self, 'uReglasPlanParams', 'Planificaci'#243'n por reglas');
end;

procedure TfrmReglasPlanPreview.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

class procedure TfrmReglasPlanPreview.Execute(const AResult: TSchedResult;
  const ATituloRegla: string);
var
  F: TfrmReglasPlanPreview;
begin
  F := TfrmReglasPlanPreview.Create(Application);
  try
    if ATituloRegla <> '' then
      F.lblSubtitle.Caption := 'Regla: ' + ATituloRegla;
    F.UpdateKPIs(AResult);
    F.PopulateGrid(AResult);
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmReglasPlanPreview.UpdateKPIs(const AResult: TSchedResult);
var
  I: Integer;
  Item: TSchedOutput;
  Retrasos: Integer;
  RetrasoTotalH: Double;
  MinIni, MaxFin: TDateTime;
  TieneRango: Boolean;
  MakespanH: Double;
begin
  Retrasos := 0;
  RetrasoTotalH := 0;
  MinIni := 0;
  MaxFin := 0;
  TieneRango := False;

  for I := 0 to High(AResult.Items) do
  begin
    Item := AResult.Items[I];

    if (Item.FechaFin <> 0) and (Item.Input.FechaCompromiso <> 0) and
       (Item.FechaFin > Item.Input.FechaCompromiso) then
    begin
      Inc(Retrasos);
      RetrasoTotalH := RetrasoTotalH +
        (Item.FechaFin - Item.Input.FechaCompromiso) * 24.0;
    end;

    if Item.FechaInicio <> 0 then
    begin
      if not TieneRango then
      begin
        MinIni := Item.FechaInicio;
        MaxFin := Item.FechaFin;
        TieneRango := True;
      end
      else
      begin
        if Item.FechaInicio < MinIni then MinIni := Item.FechaInicio;
        if Item.FechaFin > MaxFin then MaxFin := Item.FechaFin;
      end;
    end;
  end;

  if TieneRango then MakespanH := (MaxFin - MinIni) * 24.0
  else MakespanH := 0;

  lblKpiPlanVal.Caption     := IntToStr(AResult.TotalPlanificados);
  lblKpiSatVal.Caption      := IntToStr(AResult.TotalSaturados);
  lblKpiFueraVal.Caption    := IntToStr(AResult.TotalFueraPlazo);
  lblKpiRetrVal.Caption     := IntToStr(Retrasos);
  lblKpiRetrTotVal.Caption  := Format('%.1f h', [RetrasoTotalH]);
  lblKpiMakespanVal.Caption := Format('%.1f h', [MakespanH]);
end;

procedure TfrmReglasPlanPreview.PopulateGrid(const AResult: TSchedResult);
var
  I: Integer;
  Item: TSchedOutput;
  RetrasoH: Double;
begin
  tvPreview.BeginUpdate;
  try
    tvPreview.DataController.RecordCount := Length(AResult.Items);
    for I := 0 to High(AResult.Items) do
    begin
      Item := AResult.Items[I];
      tvPreview.DataController.Values[I, colOrden.Index] := I + 1;
      tvPreview.DataController.Values[I, colDoc.Index] := Item.Input.CodigoDocumento;
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

      if (Item.FechaFin <> 0) and (Item.Input.FechaCompromiso <> 0) and
         (Item.FechaFin > Item.Input.FechaCompromiso) then
      begin
        RetrasoH := (Item.FechaFin - Item.Input.FechaCompromiso) * 24.0;
        tvPreview.DataController.Values[I, colRetraso.Index] :=
          Format('%.1f h', [RetrasoH]);
      end
      else
        tvPreview.DataController.Values[I, colRetraso.Index] := '';

      tvPreview.DataController.Values[I, colEstado.Index] :=
        StatusToStr(Item.Status);
    end;
  finally
    tvPreview.EndUpdate;
  end;
end;

end.
