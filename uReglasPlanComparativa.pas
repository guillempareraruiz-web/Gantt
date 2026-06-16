unit uReglasPlanComparativa;
{
  Previsualizacion COMPARATIVA del motor de planificacion por reglas.
  Ejecuta la misma cola con las 7 reglas canonicas (es barato: no toca el plan)
  y muestra:
    - Pestana "Comparativa": tabla de KPIs (una fila por regla) con la mejor de
      cada columna resaltada + un memo RTF con conclusiones y recomendacion.
    - Una pestana por regla con su orden propuesto (grid).
  Todo se construye en codigo (TcxPageControl + grids dinamicos) para no
  duplicar el DFM por cada regla.
  Solo lectura: NO modifica el plan.
}
interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Graphics,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxEdit, cxGrid, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxContainer, cxClasses, cxCustomData, cxData, cxDataStorage,
  cxNavigator, cxFilter, cxPC,
  uBacklogScheduler, dxBarBuiltInMenu, dxSkinsCore, dxSkinBasic, dxSkinBlack,
  dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue;
type
  // Resultado de una regla en la comparativa.
  TReglaRun = record
    Rule: TPriorityRule;
    Nombre: string;
    Res: TSchedResult;
    Kpis: TSchedKpis;
  end;
  TfrmReglasPlanComparativa = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pgc: TcxPageControl;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FRuns: TArray<TReglaRun>;
    FInputs: TArray<TSchedInput>;
    FParams: TSchedParams;
    procedure RunAllRules;
    procedure BuildComparativaTab;
    procedure BuildReglaTab(const ARun: TReglaRun);
    function BuildMemoRtf: string;
    procedure LoadMemoRtf(AMemo: TRichEdit);
  public
    class procedure Execute(const AInputs: TArray<TSchedInput>;
      const AParams: TSchedParams);
  end;
implementation
{$R *.dfm}
uses
  System.DateUtils, uHelpViewer, uPlanningEngine, uPlanningEngineRules;
const
  COL_BEST = $00E8F5E9;   // verde muy suave para resaltar la mejor celda
class procedure TfrmReglasPlanComparativa.Execute(
  const AInputs: TArray<TSchedInput>; const AParams: TSchedParams);
var
  F: TfrmReglasPlanComparativa;
  I: Integer;
begin
  F := TfrmReglasPlanComparativa.Create(Application);
  try
    F.FInputs := AInputs;
    F.FParams := AParams;
    F.RunAllRules;
    F.BuildComparativaTab;
    for I := 0 to High(F.FRuns) do
      F.BuildReglaTab(F.FRuns[I]);
    if F.pgc.PageCount > 0 then
      F.pgc.ActivePageIndex := 0;   // arrancar en "Comparativa"
    F.ShowModal;
  finally
    F.Free;
  end;
end;
procedure TfrmReglasPlanComparativa.FormCreate(Sender: TObject);
begin
  THelpViewer.InstallHelp(Self, 'uReglasPlanParams', 'Planificaci'#243'n por reglas');
end;
procedure TfrmReglasPlanComparativa.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;
// Ejecuta las 7 reglas canonicas sobre la misma cola.
procedure TfrmReglasPlanComparativa.RunAllRules;
var
  R: TPriorityRule;
  Engine: TPriorityRuleEngine;
  EngineRef: IPlanningEngine;
  Run: TReglaRun;
  RS: TPriorityRuleSet;
  L: TList<TReglaRun>;
begin
  L := TList<TReglaRun>.Create;
  try
    for R := Low(TPriorityRule) to High(TPriorityRule) do
    begin
      Engine := TPriorityRuleEngine.Create;
      EngineRef := Engine;  // vida via interface
      RS.Principal  := R;
      RS.Desempate1 := prFIFO;
      RS.Desempate2 := prFIFO;
      Engine.Global := RS;
      Run.Rule := R;
      Run.Nombre := PriorityRuleToStr(R);
      Run.Res := EngineRef.Schedule(FInputs, FParams);
      Run.Kpis := ComputeKpis(Run.Res);
      L.Add(Run);
      EngineRef := nil;
    end;
    FRuns := L.ToArray;
  finally
    L.Free;
  end;
end;
procedure TfrmReglasPlanComparativa.BuildComparativaTab;
var
  Tab: TcxTabSheet;
  Grid: TcxGrid;
  View: TcxGridTableView;
  Level: TcxGridLevel;
  colRegla, colPlan, colRetr, colRetrTot, colMakespan, colFuera: TcxGridColumn;
  Memo: TRichEdit;
  I: Integer;
begin
  Tab := TcxTabSheet.Create(pgc);
  Tab.PageControl := pgc;
  Tab.Caption := 'Comparativa';
  // --- Grid de KPIs por regla (mitad superior) ---
  Grid := TcxGrid.Create(Tab);
  Grid.Parent := Tab;
  Grid.Align := alTop;
  Grid.Height := 240;
  Level := Grid.Levels.Add;
  View := Grid.CreateView(TcxGridTableView) as TcxGridTableView;
  Level.GridView := View;
  View.OptionsData.Editing := False;
  View.OptionsData.Deleting := False;
  View.OptionsData.Inserting := False;
  View.OptionsView.GroupByBox := False;
  View.OptionsSelection.CellSelect := False;
  colRegla    := View.CreateColumn; colRegla.Caption := 'Regla';            colRegla.Width := 220;
  colPlan     := View.CreateColumn; colPlan.Caption := 'Planificadas';      colPlan.Width := 100;
  colRetr     := View.CreateColumn; colRetr.Caption := 'Retrasos';          colRetr.Width := 90;
  colRetrTot  := View.CreateColumn; colRetrTot.Caption := 'Retraso total';  colRetrTot.Width := 110;
  colMakespan := View.CreateColumn; colMakespan.Caption := 'Makespan';      colMakespan.Width := 100;
  colFuera    := View.CreateColumn; colFuera.Caption := 'Fuera de plazo';   colFuera.Width := 110;
  // La mejor regla (menos retrasos) se destaca en el memo RTF de abajo.
  View.BeginUpdate;
  try
    View.DataController.RecordCount := Length(FRuns);
    for I := 0 to High(FRuns) do
    begin
      View.DataController.Values[I, colRegla.Index]    := FRuns[I].Nombre;
      View.DataController.Values[I, colPlan.Index]     := FRuns[I].Kpis.Planificados;
      View.DataController.Values[I, colRetr.Index]     := FRuns[I].Kpis.Retrasos;
      View.DataController.Values[I, colRetrTot.Index]  := Format('%.1f h', [FRuns[I].Kpis.RetrasoTotalH]);
      View.DataController.Values[I, colMakespan.Index] := Format('%.1f h', [FRuns[I].Kpis.MakespanH]);
      View.DataController.Values[I, colFuera.Index]    := FRuns[I].Kpis.FueraPlazo;
    end;
  finally
    View.EndUpdate;
  end;
  // --- Memo RTF con conclusiones (resto) ---
  Memo := TRichEdit.Create(Tab);
  Memo.Parent := Tab;
  Memo.Align := alClient;
  Memo.BorderStyle := bsNone;
  Memo.ReadOnly := True;
  Memo.ScrollBars := ssVertical;
  LoadMemoRtf(Memo);
end;
// Carga el RTF generado en el TRichEdit via stream ANSI.
procedure TfrmReglasPlanComparativa.LoadMemoRtf(AMemo: TRichEdit);
var
  RtfStr: string;
  MS: TMemoryStream;
  Bytes: TBytes;
begin
  RtfStr := BuildMemoRtf;
  MS := TMemoryStream.Create;
  try
    Bytes := TEncoding.ANSI.GetBytes(RtfStr);
    if Length(Bytes) > 0 then
      MS.WriteBuffer(Bytes[0], Length(Bytes));
    MS.Position := 0;
    AMemo.Lines.LoadFromStream(MS);
  finally
    MS.Free;
  end;
end;
// Construye el RTF del memo con colores y negritas (conclusiones + recomendacion).
function TfrmReglasPlanComparativa.BuildMemoRtf: string;
var
  I, IdxMejorRetr: Integer;
  MinRetr: Integer;
  MaxRetr: Integer;
  MinRetrTot, MaxRetrTot: Double;
  MakespanIgual: Boolean;
  Mk0: Double;
  SB: TStringBuilder;
  // Escapa texto para RTF.
  function E(const S: string): string;
  begin
    Result := StringReplace(S, '\', '\\', [rfReplaceAll]);
    Result := StringReplace(Result, '{', '\{', [rfReplaceAll]);
    Result := StringReplace(Result, '}', '\}', [rfReplaceAll]);
  end;
begin
  // Analisis.
  MinRetr := MaxInt; MaxRetr := -1; IdxMejorRetr := 0;
  MinRetrTot := 1.0e18; MaxRetrTot := -1;
  MakespanIgual := True;
  Mk0 := -1;
  for I := 0 to High(FRuns) do
  begin
    if FRuns[I].Kpis.Retrasos < MinRetr then
    begin MinRetr := FRuns[I].Kpis.Retrasos; IdxMejorRetr := I; end;
    if FRuns[I].Kpis.Retrasos > MaxRetr then MaxRetr := FRuns[I].Kpis.Retrasos;
    if FRuns[I].Kpis.RetrasoTotalH < MinRetrTot then MinRetrTot := FRuns[I].Kpis.RetrasoTotalH;
    if FRuns[I].Kpis.RetrasoTotalH > MaxRetrTot then MaxRetrTot := FRuns[I].Kpis.RetrasoTotalH;
    if Mk0 < 0 then Mk0 := FRuns[I].Kpis.MakespanH
    else if Abs(FRuns[I].Kpis.MakespanH - Mk0) > 0.01 then MakespanIgual := False;
  end;
  // Cabecera RTF + tabla de colores: cf1 negro, cf2 verde, cf3 gris.
  SB := TStringBuilder.Create;
  try
    SB.Append('{\rtf1\ansi\deff0');
    SB.Append('{\fonttbl{\f0\fswiss Segoe UI;}}');
    SB.Append('{\colortbl ;\red0\green0\blue0;\red27\green94\blue32;\red120\green120\blue120;}');
    SB.Append('\f0\fs20 ');
    // Titulo.
    SB.Append('\cf2\b\fs28 Conclusiones\b0\fs20\cf1\par\par ');
    SB.AppendFormat('Se compararon %d reglas sobre %d operaciones.\par\par ',
      [Length(FRuns), Length(FInputs)]);
    // Menos retrasos.
    SB.Append('\b Menos retrasos: \b0 ');
    SB.AppendFormat('\cf2\b %s\b0\cf1 (%d retraso(s))', [E(FRuns[IdxMejorRetr].Nombre), MinRetr]);
    if MaxRetr > MinRetr then
      SB.AppendFormat(', frente a %d en el peor caso.', [MaxRetr])
    else
      SB.Append('.');
    SB.Append('\par ');
    // Retraso total.
    SB.AppendFormat('\b Menor retraso total: \b0 \cf2\b %.1f h\b0\cf1', [MinRetrTot]);
    if MaxRetrTot > MinRetrTot then
      SB.AppendFormat(' (el peor llega a %.1f h).', [MaxRetrTot])
    else
      SB.Append('.');
    SB.Append('\par ');
    // Makespan.
    if MakespanIgual then
      SB.AppendFormat('\cf3 El makespan no cambia (%.1f h): el cuello de botella manda igual con cualquier regla.\cf1\par ', [Mk0])
    else
      SB.Append('\cf3 El makespan varia segun la regla.\cf1\par ');
    SB.Append('\par ');
    // Recomendacion.
    SB.Append('\cf2\b Recomendaci');
    SB.Append('\''f3');  // o acentuada
    SB.Append('n: \b0\cf1 ');
    if MaxRetr > MinRetr then
      SB.AppendFormat('usar \b %s\b0 minimiza los incumplimientos de entrega.',
        [E(FRuns[IdxMejorRetr].Nombre)])
    else
      SB.Append('todas las reglas dan el mismo numero de retrasos; elija por el criterio que prefiera (p.ej. SPT para vaciar antes la cola).');
    SB.Append('\par ');
    SB.Append('}');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;
procedure TfrmReglasPlanComparativa.BuildReglaTab(const ARun: TReglaRun);
var
  Tab: TcxTabSheet;
  lblK: TLabel;
  Grid: TcxGrid;
  View: TcxGridTableView;
  Level: TcxGridLevel;
  colOrden, colDoc, colCentro, colIni, colFin, colDur, colComp, colRetr, colEst: TcxGridColumn;
  I: Integer;
  Item: TSchedOutput;
  RetrasoH: Double;
begin
  Tab := TcxTabSheet.Create(pgc);
  Tab.PageControl := pgc;
  Tab.Caption := ARun.Nombre;
  // Franja de KPIs (texto compacto).
  lblK := TLabel.Create(Tab);
  lblK.Parent := Tab;
  lblK.Align := alTop;
  lblK.AlignWithMargins := True;
  lblK.Font.Style := [fsBold];
  lblK.Caption := Format(
    '  Planificadas: %d    Retrasos: %d    Retraso total: %.1f h    Makespan: %.1f h    Saturadas: %d    Fuera de plazo: %d',
    [ARun.Kpis.Planificados, ARun.Kpis.Retrasos, ARun.Kpis.RetrasoTotalH,
     ARun.Kpis.MakespanH, ARun.Kpis.Saturados, ARun.Kpis.FueraPlazo]);
  Grid := TcxGrid.Create(Tab);
  Grid.Parent := Tab;
  Grid.Align := alClient;
  Level := Grid.Levels.Add;
  View := Grid.CreateView(TcxGridTableView) as TcxGridTableView;
  Level.GridView := View;
  View.OptionsData.Editing := False;
  View.OptionsData.Deleting := False;
  View.OptionsData.Inserting := False;
  View.OptionsView.GroupByBox := False;
  colOrden  := View.CreateColumn; colOrden.Caption := '#';           colOrden.Width := 50;
  colDoc    := View.CreateColumn; colDoc.Caption := 'Documento';     colDoc.Width := 190;
  colCentro := View.CreateColumn; colCentro.Caption := 'Centro';     colCentro.Width := 130;
  colIni    := View.CreateColumn; colIni.Caption := 'Inicio';        colIni.Width := 130;
  colFin    := View.CreateColumn; colFin.Caption := 'Fin';           colFin.Width := 130;
  colDur    := View.CreateColumn; colDur.Caption := 'Dur. (min)';    colDur.Width := 80;
  colComp   := View.CreateColumn; colComp.Caption := 'Compromiso';   colComp.Width := 100;
  colRetr   := View.CreateColumn; colRetr.Caption := 'Retraso';      colRetr.Width := 80;
  colEst    := View.CreateColumn; colEst.Caption := 'Estado';        colEst.Width := 100;
  View.BeginUpdate;
  try
    View.DataController.RecordCount := Length(ARun.Res.Items);
    for I := 0 to High(ARun.Res.Items) do
    begin
      Item := ARun.Res.Items[I];
      View.DataController.Values[I, colOrden.Index]  := I + 1;
      View.DataController.Values[I, colDoc.Index]    := Item.Input.CodigoDocumento;
      View.DataController.Values[I, colCentro.Index] := Item.CenterCode;
      if Item.FechaInicio <> 0 then
        View.DataController.Values[I, colIni.Index] := FormatDateTime('dd/mm/yyyy hh:nn', Item.FechaInicio)
      else
        View.DataController.Values[I, colIni.Index] := '';
      if Item.FechaFin <> 0 then
        View.DataController.Values[I, colFin.Index] := FormatDateTime('dd/mm/yyyy hh:nn', Item.FechaFin)
      else
        View.DataController.Values[I, colFin.Index] := '';
      View.DataController.Values[I, colDur.Index] := Item.DuracionMin;
      if Item.Input.FechaCompromiso <> 0 then
        View.DataController.Values[I, colComp.Index] := FormatDateTime('dd/mm/yyyy', Item.Input.FechaCompromiso)
      else
        View.DataController.Values[I, colComp.Index] := '';
      if (Item.FechaFin <> 0) and (Item.Input.FechaCompromiso <> 0) and
         (Item.FechaFin > Item.Input.FechaCompromiso) then
      begin
        RetrasoH := (Item.FechaFin - Item.Input.FechaCompromiso) * 24.0;
        View.DataController.Values[I, colRetr.Index] := Format('%.1f h', [RetrasoH]);
      end
      else
        View.DataController.Values[I, colRetr.Index] := '';
      View.DataController.Values[I, colEst.Index] := StatusToStr(Item.Status);
    end;
  finally
    View.EndUpdate;
  end;
end;
end.
