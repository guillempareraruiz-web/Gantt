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
  Winapi.Windows, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Graphics,
  Vcl.Dialogs,
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
    // Scores normalizados 0..100 (mas alto = mejor), calculados sobre el conjunto
    // de reglas. Alimentan las barras de las tarjetas-resumen.
    ScCumplimiento: Double;  // % operaciones dentro de plazo
    ScCompactacion: Double;  // makespan relativo invertido (menos hueco = mejor)
    ScRetraso: Double;       // retraso total relativo invertido (menos = mejor)
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
    FIdxMejor: Integer;          // regla recomendada (menos retrasos)
    FpbCards: TPaintBox;         // tarjetas-resumen (GDI+)
    FCompactar: Boolean;         // toggle: rellenar huecos (ppHueco) al recalcular
    FchkCompactar: TCheckBox;
    FbtnOptim: TButton;          // lanza el optimizador SA (aproximacion RCPSP)
    FTieneOptim: Boolean;        // ya hay una fila "Optimizado" en FRuns
    FCompGrid: TcxGridTableView; // la vista de la tabla, para refrescarla
    FColRegla, FColIni, FColFin, FColMk: TcxGridColumn;
    FColColoc, FColPlan, FColRetr, FColRetrTot, FColFuera: TcxGridColumn;
    FMemo: TRichEdit;            // memo de conclusiones (se refresca al recalcular)
    procedure RunAllRules;
    procedure ComputeScores;     // normaliza KPIs a 0..100 para las barras
    procedure BuildComparativaTab;
    procedure BuildReglaTab(const ARun: TReglaRun);
    function BuildMemoRtf: string;
    procedure LoadMemoRtf(AMemo: TRichEdit);
    procedure pbCardsPaint(Sender: TObject);
    procedure RellenarTablaComparativa;   // vuelca FRuns a la tabla
    procedure chkCompactarClick(Sender: TObject);
    procedure btnOptimClick(Sender: TObject);   // optimizacion SA (nativa)
  public
    class procedure Execute(const AInputs: TArray<TSchedInput>;
      const AParams: TSchedParams);
  end;
implementation
{$R *.dfm}
uses
  System.DateUtils, System.Threading,
  uHelpViewer, uPlanningEngine, uPlanningEngineRules, uPlanLog,
  uPlanOptimizer, uBusyDialog;
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
    F.ComputeScores;
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
  P: TSchedParams;
begin
  // Con FCompactar activo, forzamos politica de RELLENO DE HUECOS (ppHueco): el
  // motor ya soporta compactar (PlaceForward busca huecos validos en vez de
  // encolar al final). Umbrales suaves para no fragmentar en microhuecos.
  P := FParams;
  if FCompactar then
  begin
    P.Placement := ppHueco;
    if P.HuecoMinimoMin <= 0 then P.HuecoMinimoMin := 30;
    if P.PorcentajeMinNodo <= 0 then P.PorcentajeMinNodo := 50;
  end
  else
    P.Placement := ppFinCola;   // comportamiento clasico: encolar al final

  // No usamos PlanLog.Inicio (vaciaria el fichero): queremos comparar on/off en el
  // MISMO log al alternar el toggle. Solo un separador.
  PlanLog.Linea('');
  PlanLog.Linea('=== COMPARATIVA REGLAS - Compactar=%s (Placement=%s, ' +
    'HuecoMin=%d min, PctMinNodo=%d) ===',
    [BoolToStr(FCompactar, True), PlacementToStr(P.Placement),
     P.HuecoMinimoMin, P.PorcentajeMinNodo]);

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
      Run.Res := EngineRef.Schedule(FInputs, P);
      Run.Kpis := ComputeKpis(Run.Res);
      L.Add(Run);
      EngineRef := nil;
      // Diagnostico por regla: makespan + rango + retrasos. Al alternar el toggle
      // deberia verse el makespan/fin cambiar si la compactacion encuentra huecos.
      PlanLog.Linea('  %-28s makespan=%.1f h  ini=%s  fin=%s  planif=%d  retrasos=%d  saturados=%d',
        [Run.Nombre, Run.Kpis.MakespanH,
         FormatDateTime('dd/mm hh:nn', Run.Kpis.FechaMin),
         FormatDateTime('dd/mm hh:nn', Run.Kpis.FechaMax),
         Run.Kpis.Planificados, Run.Kpis.Retrasos, Run.Kpis.Saturados]);
    end;
    FRuns := L.ToArray;
  finally
    L.Free;
  end;
end;
// Normaliza los KPIs a 0..100 (mas alto = mejor) para las barras de las tarjetas.
//   Cumplimiento = % de operaciones dentro de plazo (planificadas - retrasos).
//   Compactacion = makespan invertido y reescalado al rango [min..max] del set.
//   Retraso      = retraso total invertido y reescalado al rango del set.
// Compactacion y Retraso son RELATIVOS al conjunto de reglas: la mejor regla en
// esa dimension marca 100 y la peor 0 (si todas iguales, 100 para todas).
procedure TfrmReglasPlanComparativa.ComputeScores;
var
  I: Integer;
  MkMin, MkMax, RtMin, RtMax: Double;

  function Rescale(V, Lo, Hi: Double): Double;
  begin
    // Invertido: menos es mejor -> 100 en Lo, 0 en Hi.
    if Hi - Lo < 1e-9 then Exit(100);   // todas iguales: max score
    Result := (Hi - V) / (Hi - Lo) * 100;
    if Result < 0 then Result := 0 else if Result > 100 then Result := 100;
  end;

begin
  FIdxMejor := 0;
  if Length(FRuns) = 0 then Exit;
  MkMin := 1e18; MkMax := -1; RtMin := 1e18; RtMax := -1;
  for I := 0 to High(FRuns) do
  begin
    MkMin := Min(MkMin, FRuns[I].Kpis.MakespanH);
    MkMax := Max(MkMax, FRuns[I].Kpis.MakespanH);
    RtMin := Min(RtMin, FRuns[I].Kpis.RetrasoTotalH);
    RtMax := Max(RtMax, FRuns[I].Kpis.RetrasoTotalH);
    // Recomendada = menos retrasos (mismo criterio que el memo de conclusiones).
    if FRuns[I].Kpis.Retrasos < FRuns[FIdxMejor].Kpis.Retrasos then
      FIdxMejor := I;
  end;
  for I := 0 to High(FRuns) do
  begin
    // Cumplimiento = % de operaciones que NO llegan tarde, sobre el TOTAL. El
    // denominador es Total (no Planificados): Retrasos se cuenta sobre todas las
    // items del resultado, asi que ambos comparten base y el % queda 0..100.
    // (Con Planificados como denom. salia negativo: Retrasos >> Planificados.)
    if FRuns[I].Kpis.Total > 0 then
      FRuns[I].ScCumplimiento :=
        (FRuns[I].Kpis.Total - FRuns[I].Kpis.Retrasos) /
         FRuns[I].Kpis.Total * 100
    else
      FRuns[I].ScCumplimiento := 0;
    if FRuns[I].ScCumplimiento < 0 then FRuns[I].ScCumplimiento := 0;
    FRuns[I].ScCompactacion := Rescale(FRuns[I].Kpis.MakespanH, MkMin, MkMax);
    FRuns[I].ScRetraso      := Rescale(FRuns[I].Kpis.RetrasoTotalH, RtMin, RtMax);
  end;
end;

procedure TfrmReglasPlanComparativa.BuildComparativaTab;
var
  Tab: TcxTabSheet;
  Grid: TcxGrid;
  View: TcxGridTableView;
  Level: TcxGridLevel;
  colRegla, colColoc, colPlan, colRetr, colRetrTot, colMakespan, colFuera: TcxGridColumn;
  colIni, colFin: TcxGridColumn;
  Memo: TRichEdit;
  I: Integer;
  SB: TScrollBox;
  BarTop: TPanel;
begin
  Tab := TcxTabSheet.Create(pgc);
  Tab.PageControl := pgc;
  Tab.Caption := 'Comparativa';

  // --- Barra superior: toggle "Compactar" + boton "Optimizar (SA)". ---
  BarTop := TPanel.Create(Tab);
  BarTop.Parent := Tab;
  BarTop.Align := alTop;
  BarTop.Height := 34;
  BarTop.BevelOuter := bvNone;
  BarTop.ParentBackground := False;
  BarTop.Color := $00F0F0F0;

  FchkCompactar := TCheckBox.Create(BarTop);
  FchkCompactar.Parent := BarTop;
  FchkCompactar.Left := 10;
  FchkCompactar.Top := 8;
  FchkCompactar.Width := 520;
  FchkCompactar.Caption :=
    ' Compactar (rellenar huecos) - recalcula makespan aprovechando los huecos';
  FchkCompactar.Checked := FCompactar;
  FchkCompactar.OnClick := chkCompactarClick;

  // Boton de optimizacion (metaheuristica SA nativa). Anade una fila
  // "Optimizado (SA)" a la comparativa, partiendo de la mejor regla.
  FbtnOptim := TButton.Create(BarTop);
  FbtnOptim.Parent := BarTop;
  FbtnOptim.Anchors := [akTop, akRight];
  FbtnOptim.Left := BarTop.Width - 210;
  FbtnOptim.Top := 4;
  FbtnOptim.Width := 200;
  FbtnOptim.Height := 26;
  FbtnOptim.Caption := 'Optimizar (SA) - aprox. RCPSP';
  FbtnOptim.OnClick := btnOptimClick;

  // --- Tarjetas-resumen GDI+ (arriba): una por regla, barras normalizadas ---
  // Dentro de un ScrollBox horizontal: 7 tarjetas no caben de golpe.
  SB := TScrollBox.Create(Tab);
  SB.Parent := Tab;
  SB.Align := alTop;
  SB.Height := 190;
  SB.BorderStyle := bsNone;
  SB.VertScrollBar.Visible := False;
  SB.Color := $00F5F5F5;
  SB.ParentColor := False;
  FpbCards := TPaintBox.Create(SB);
  FpbCards.Parent := SB;
  FpbCards.Align := alNone;
  FpbCards.Top := 10;
  FpbCards.Left := 0;
  FpbCards.Height := 164;
  // Ancho total = suma de tarjetas (CardW=236 + Gap=16); el ScrollBox aporta el
  // scroll horizontal cuando no caben todas.
  FpbCards.Width := 8 + Length(FRuns) * (236 + 16);
  FpbCards.OnPaint := pbCardsPaint;

  // --- Grid de KPIs por regla (debajo de las tarjetas) ---
  Grid := TcxGrid.Create(Tab);
  Grid.Parent := Tab;
  Grid.Align := alTop;
  Grid.Height := 220;
  Level := Grid.Levels.Add;
  View := Grid.CreateView(TcxGridTableView) as TcxGridTableView;
  Level.GridView := View;
  View.OptionsData.Editing := False;
  View.OptionsData.Deleting := False;
  View.OptionsData.Inserting := False;
  View.OptionsView.GroupByBox := False;
  View.OptionsSelection.CellSelect := False;
  colRegla    := View.CreateColumn; colRegla.Caption := 'Regla';            colRegla.Width := 220;
  // "Colocadas" = OP con fecha en el plan (Total - NoPlanificadas - Saturadas).
  // TODAS se colocan aunque lleguen tarde; deja claro que no se pierde carga.
  colColoc    := View.CreateColumn; colColoc.Caption := 'Colocadas';        colColoc.Width := 90;
  // "En plazo" = OP que terminan <= compromiso (antes 'Planificadas', confuso: TODAS
  // se colocan, pero el KPI TotalPlanificados solo cuenta las que llegan a tiempo).
  colPlan     := View.CreateColumn; colPlan.Caption := 'En plazo';          colPlan.Width := 80;
  colRetr     := View.CreateColumn; colRetr.Caption := 'Con retraso';       colRetr.Width := 90;
  colRetrTot  := View.CreateColumn; colRetrTot.Caption := 'Retraso total';  colRetrTot.Width := 110;
  colMakespan := View.CreateColumn; colMakespan.Caption := 'Makespan';      colMakespan.Width := 100;
  // Rango temporal del plan: inicio del primer nodo y fin del ultimo (con hora).
  colIni      := View.CreateColumn; colIni.Caption := 'Inicio plan.';       colIni.Width := 130;
  colFin      := View.CreateColumn; colFin.Caption := 'Fin plan.';          colFin.Width := 130;
  colFuera    := View.CreateColumn; colFuera.Caption := 'Fuera de plazo';   colFuera.Width := 110;
  // Guardar referencias para poder refrescar la tabla tras recalcular (toggle).
  FCompGrid := View;
  FColRegla := colRegla; FColColoc := colColoc; FColPlan := colPlan;
  FColRetr := colRetr; FColRetrTot := colRetrTot; FColMk := colMakespan;
  FColIni := colIni; FColFin := colFin; FColFuera := colFuera;
  RellenarTablaComparativa;

  // --- Memo RTF con conclusiones (resto) ---
  Memo := TRichEdit.Create(Tab);
  Memo.Parent := Tab;
  Memo.Align := alClient;
  Memo.BorderStyle := bsNone;
  Memo.ReadOnly := True;
  Memo.ScrollBars := ssVertical;
  FMemo := Memo;
  LoadMemoRtf(Memo);
end;

// Vuelca FRuns a la tabla comparativa (columnas ya creadas). Reutilizable tras
// recalcular con el toggle de compactacion.
procedure TfrmReglasPlanComparativa.RellenarTablaComparativa;
var
  I: Integer;
begin
  if FCompGrid = nil then Exit;
  FCompGrid.BeginUpdate;
  try
    FCompGrid.DataController.RecordCount := Length(FRuns);
    for I := 0 to High(FRuns) do
    begin
      FCompGrid.DataController.Values[I, FColRegla.Index]   := FRuns[I].Nombre;
      // Colocadas = todas las que tienen fecha en el plan (Total - no colocadas).
      FCompGrid.DataController.Values[I, FColColoc.Index]   :=
        FRuns[I].Kpis.Total - FRuns[I].Kpis.NoPlanificados - FRuns[I].Kpis.Saturados;
      FCompGrid.DataController.Values[I, FColPlan.Index]    := FRuns[I].Kpis.Planificados;
      FCompGrid.DataController.Values[I, FColRetr.Index]    := FRuns[I].Kpis.Retrasos;
      FCompGrid.DataController.Values[I, FColRetrTot.Index] := Format('%.1f h', [FRuns[I].Kpis.RetrasoTotalH]);
      FCompGrid.DataController.Values[I, FColMk.Index]      := Format('%.1f h', [FRuns[I].Kpis.MakespanH]);
      if FRuns[I].Kpis.FechaMin <> 0 then
        FCompGrid.DataController.Values[I, FColIni.Index] :=
          FormatDateTime('dd/mm/yyyy hh:nn', FRuns[I].Kpis.FechaMin)
      else
        FCompGrid.DataController.Values[I, FColIni.Index] := '';
      if FRuns[I].Kpis.FechaMax <> 0 then
        FCompGrid.DataController.Values[I, FColFin.Index] :=
          FormatDateTime('dd/mm/yyyy hh:nn', FRuns[I].Kpis.FechaMax)
      else
        FCompGrid.DataController.Values[I, FColFin.Index] := '';
      FCompGrid.DataController.Values[I, FColFuera.Index]   := FRuns[I].Kpis.FueraPlazo;
    end;
  finally
    FCompGrid.EndUpdate;
  end;
end;

// Toggle "Compactar": re-ejecuta las reglas con ppHueco/ppFinCola y refresca
// tarjetas + tabla + conclusiones. El plan real NO se toca (solo preview).
procedure TfrmReglasPlanComparativa.chkCompactarClick(Sender: TObject);
var
  OldCur: TCursor;
begin
  FCompactar := FchkCompactar.Checked;
  OldCur := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    RunAllRules;                 // recalcula con la nueva politica de placement
    ComputeScores;               // renormaliza barras
    RellenarTablaComparativa;    // refresca la tabla
    if FMemo <> nil then LoadMemoRtf(FMemo);  // conclusiones actualizadas
    if FpbCards <> nil then FpbCards.Invalidate;  // repinta tarjetas
  finally
    Screen.Cursor := OldCur;
  end;
end;

// Optimizacion SA (nativa): parte del orden de la mejor regla, busca una mejor
// permutacion con Simulated Annealing (uPlanOptimizer) minimizando retraso +
// makespan, y anade/actualiza la fila "Optimizado (SA)" en la comparativa.
// Solo preview: NO toca el plan real.
procedure TfrmReglasPlanComparativa.btnOptimClick(Sender: TObject);
var
  OptP: TOptimizerParams;
  Prog: TOptimizerProgress;
  Inicial: TArray<TSchedInput>;
  RS: TPriorityRuleSet;
  P: TSchedParams;
  Run: TReglaRun;
  Idx: Integer;
begin
  if Length(FInputs) = 0 then Exit;

  FbtnOptim.Enabled := False;
  try
    // 1) Orden de partida = la mejor regla actual (FIdxMejor).
    Inicial := Copy(FInputs, 0, Length(FInputs));
    RS := DefaultRuleSet;
    if (FIdxMejor >= 0) and (FIdxMejor <= High(FRuns)) then
      RS.Principal := FRuns[FIdxMejor].Rule;
    SortInputsByRuleSet(Inicial, RS, FParams.FechaBase);

    // 2) Params de planificacion coherentes con el toggle de compactacion.
    P := FParams;
    if FCompactar then P.Placement := ppHueco else P.Placement := ppFinCola;

    // 3) Ejecutar el optimizador DENTRO de RunBusy: corre en un hilo de fondo
    //    mientras el hilo principal anima el spinner del dialogo (feedback vivo
    //    durante los ~20 s). El optimizador ya no toca BD (usa cache) salvo
    //    BuildOccupancyCache, que corre en este hilo con COM inicializado.
    OptP := TOptimizerParams.Default;
    uBusyDialog.RunBusy(Self,
      Format('Optimizando (Simulated Annealing, %d hilos)...', [TThread.ProcessorCount]),
      procedure
      var
        LOpt: TPlanOptimizer;
      begin
        LOpt := TPlanOptimizer.Create;
        try
          Run.Res := LOpt.Optimizar(Inicial, P, OptP, Prog);
        finally
          LOpt.Free;
        end;
      end);
    Run.Rule := Low(TPriorityRule);   // marcador; no es una regla real
    Run.Nombre := 'Optimizado (SA)';
    Run.Kpis := ComputeKpis(Run.Res);

    PlanLog.Linea('=== OPTIMIZAR SA: %d hilos, %d iter total, %d mejoras, ' +
      'obj %.4f -> %.4f, %d ms | makespan=%.1f h retrasos=%d ===',
      [Prog.Hilos, Prog.Iteraciones, Prog.Mejoras, Prog.ObjInicial, Prog.ObjFinal,
       Prog.MillisUsados, Run.Kpis.MakespanH, Run.Kpis.Retrasos]);

    // 4) Anadir o reemplazar la fila "Optimizado (SA)" en FRuns.
    if FTieneOptim and (Length(FRuns) > 0) then
      FRuns[High(FRuns)] := Run    // ya existe: reemplazar la ultima
    else
    begin
      SetLength(FRuns, Length(FRuns) + 1);
      FRuns[High(FRuns)] := Run;
      FTieneOptim := True;
      // Ensanchar el PaintBox de tarjetas para la nueva.
      if FpbCards <> nil then
        FpbCards.Width := 8 + Length(FRuns) * (236 + 16);
    end;

    // 5) Recalcular scores/recomendada y refrescar todo.
    ComputeScores;
    RellenarTablaComparativa;
    if FMemo <> nil then LoadMemoRtf(FMemo);
    if FpbCards <> nil then FpbCards.Invalidate;

    // Informe breve al usuario.
    Idx := High(FRuns);
    ShowMessage(Format(
      'Optimizacion (SA) terminada en %d ms (%d iteraciones, %d mejoras).' + sLineBreak +
      'Makespan: %.1f h    Con retraso: %d    Retraso total: %.1f h' + sLineBreak + sLineBreak +
      'Se ha anadido la fila "Optimizado (SA)" a la comparativa.',
      [Prog.MillisUsados, Prog.Iteraciones, Prog.Mejoras,
       FRuns[Idx].Kpis.MakespanH, FRuns[Idx].Kpis.Retrasos, FRuns[Idx].Kpis.RetrasoTotalH]));
  finally
    FbtnOptim.Enabled := True;
  end;
end;

// Helper GDI+: color VCL -> TGPColor (con alpha opcional).
function GPc(C: TColor; A: Byte = 255): TGPColor;
begin
  C := ColorToRGB(C);
  Result := MakeColor(A, GetRValue(C), GetGValue(C), GetBValue(C));
end;

// Helper GDI+: anade al path un rectangulo de esquinas redondeadas.
procedure AddRoundRect(APath: TGPGraphicsPath; X, Y, W, H, R: Single);
begin
  APath.AddArc(X, Y, R, R, 180, 90);
  APath.AddArc(X + W - R, Y, R, R, 270, 90);
  APath.AddArc(X + W - R, Y + H - R, R, R, 0, 90);
  APath.AddArc(X, Y + H - R, R, R, 90, 90);
  APath.CloseFigure;
end;

// ---------------------------------------------------------------------------
// Tarjetas-resumen (GDI+): una tarjeta por regla, con titulo, chip "recomendado"
// en la mejor, y 3 barras normalizadas (Cumplimiento / Compactacion / Retraso).
// ---------------------------------------------------------------------------
procedure TfrmReglasPlanComparativa.pbCardsPaint(Sender: TObject);
const
  CardW = 236; CardH = 158; Gap = 16; PadX = 16; PadTop = 14;
  BarLabels: array[0..2] of string = ('Cumplimiento', 'Compactacion', 'Retraso');
  COL_CUMPL = $0050B848;   // verde (BGR)
  COL_COMPAC = $00D89838;  // azul
  COL_RETR  = $002098E8;   // naranja
var
  G: TGPGraphics;
  I: Integer;
  X: Single;
  Scores: array[0..2] of Double;
  Cols: array[0..2] of TColor;

  procedure Card(AIdx: Integer; AX: Single);
  var
    Path: TGPGraphicsPath;
    Br: TGPSolidBrush;
    Pen: TGPPen;
    F: TGPFont; Fmt, FmtR: TGPStringFormat;
    EsMejor: Boolean;
    BarY, TrackW, FillW: Single;
    K: Integer;
  begin
    EsMejor := (AIdx = FIdxMejor);
    // Fondo de tarjeta (blanco) + borde (azul si recomendada).
    Path := TGPGraphicsPath.Create;
    AddRoundRect(Path, AX, 0, CardW, CardH, 16);
    Br := TGPSolidBrush.Create(GPc($00FFFFFF));
    G.FillPath(Br, Path); Br.Free;
    if EsMejor then Pen := TGPPen.Create(GPc($00E8A030), 2)
    else Pen := TGPPen.Create(GPc($00E0E0E0), 1);
    G.DrawPath(Pen, Path); Pen.Free; Path.Free;

    Fmt := TGPStringFormat.Create;
    // Titulo de la regla (recortado a la primera palabra clave si es largo).
    F := TGPFont.Create('Segoe UI', 11, 1, UnitPoint);
    Br := TGPSolidBrush.Create(GPc($00303030));
    Fmt.SetFormatFlags(StringFormatFlagsNoWrap);
    Fmt.SetTrimming(StringTrimmingEllipsisCharacter);
    G.DrawString(FRuns[AIdx].Nombre, -1, F,
      MakeRect(AX + PadX, Single(PadTop), Single(CardW - PadX * 2 - 4), Single(22.0)), Fmt, Br);
    Br.Free; F.Free;

    // Chip "recomendado" bajo el titulo (solo la mejor).
    if EsMejor then
    begin
      Path := TGPGraphicsPath.Create;
      AddRoundRect(Path, AX + PadX, PadTop + 26, 92, 18, 9);
      Br := TGPSolidBrush.Create(GPc($00FCE8CC));
      G.FillPath(Br, Path); Br.Free; Path.Free;
      F := TGPFont.Create('Segoe UI', 7.5, 1, UnitPoint);
      Br := TGPSolidBrush.Create(GPc($00C07818));
      G.DrawString('RECOMENADA', -1, F,
        MakeRect(AX + PadX, Single(PadTop + 27), Single(92.0), Single(16.0)), Fmt, Br);
      Br.Free; F.Free;
    end;

    // 3 barras normalizadas.
    Scores[0] := FRuns[AIdx].ScCumplimiento;
    Scores[1] := FRuns[AIdx].ScCompactacion;
    Scores[2] := FRuns[AIdx].ScRetraso;
    TrackW := CardW - PadX * 2;
    BarY := PadTop + 56;
    FmtR := TGPStringFormat.Create;   // alineado a la derecha (valor numerico)
    FmtR.SetAlignment(StringAlignmentFar);
    FmtR.SetFormatFlags(StringFormatFlagsNoWrap);
    for K := 0 to 2 do
    begin
      // etiqueta (izquierda)
      F := TGPFont.Create('Segoe UI', 8, 0, UnitPoint);
      Br := TGPSolidBrush.Create(GPc($00707070));
      G.DrawString(BarLabels[K], -1, F,
        MakeRect(AX + PadX, BarY, Single(TrackW - 40), Single(15.0)), Fmt, Br);
      Br.Free; F.Free;
      // valor numerico (derecha, alineado)
      F := TGPFont.Create('Segoe UI', 9, 1, UnitPoint);
      Br := TGPSolidBrush.Create(GPc(Cols[K]));
      G.DrawString(IntToStr(Round(Scores[K])), -1, F,
        MakeRect(AX + PadX, BarY, Single(TrackW), Single(15.0)), FmtR, Br);
      Br.Free; F.Free;
      // track (fondo gris) + fill (color) redondeados
      Path := TGPGraphicsPath.Create;
      AddRoundRect(Path, AX + PadX, BarY + 17, TrackW, 7, 7);
      Br := TGPSolidBrush.Create(GPc($00ECECEC));
      G.FillPath(Br, Path); Br.Free; Path.Free;
      FillW := TrackW * (Scores[K] / 100);
      if FillW < 7 then FillW := 7;
      Path := TGPGraphicsPath.Create;
      AddRoundRect(Path, AX + PadX, BarY + 17, FillW, 7, 7);
      Br := TGPSolidBrush.Create(GPc(Cols[K]));
      G.FillPath(Br, Path); Br.Free; Path.Free;
      BarY := BarY + 31;
    end;
    FmtR.Free;
    Fmt.Free;
  end;

begin
  Cols[0] := COL_CUMPL; Cols[1] := COL_COMPAC; Cols[2] := COL_RETR;
  G := TGPGraphics.Create(FpbCards.Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);
    X := 4;
    for I := 0 to High(FRuns) do
    begin
      Card(I, X);
      X := X + CardW + Gap;
    end;
  finally
    G.Free;
  end;
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
