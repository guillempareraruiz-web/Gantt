unit uAutoPlanificacion;

{
  TfrmAutoPlanificacion - Preview de la planificacion automatica.

  Flujo:
    1. Recibe NodeIds candidatos (desde Gantt: seleccion / backlog) y la
       fecha hora de referencia.
    2. Lanza TPlanProdEngine.PlanificarBatch.
    3. Muestra al usuario:
       - Asignaciones propuestas (cxGrid: NodeId, Operario, Score, Coste).
       - Nodos no asignables (cxGrid).
       - Totales (count, coste total, score total).
       - Boton "Editar pesos" para ajustar y volver a calcular.
    4. Usuario decide:
       - Aplicar  -> persiste via FOpRepo.AddAsignacion.
       - Cancelar -> descarta.

  No modifica la BD hasta que pulsa Aplicar.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.DateUtils,
  System.Math, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxContainer, cxClasses,
  cxFilter, dxSkinsCore, dxSkinOffice2019Colorful,
  dxBarBuiltInMenu, cxCustomData, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxButtons,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxButtonEdit,
  uGanttTypes, uNodeDataRepo, uOperariosTypes, uOperariosRepo,
  uOperatorAbsencesRepo, uHabilidadRepo, uOperationTypesRepo,
  uPlanProdTypes, uPlanProdEngine, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
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
  dxSkinXmas2008Blue, Vcl.Menus;

type
  TfrmAutoPlanificacion = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlSettings: TPanel;
    lblFecha: TLabel;
    dtpFecha: TDateTimePicker;
    dtpHora: TDateTimePicker;
    btnEditarPesos: TcxButton;
    btnRecalcular: TcxButton;
    pcResult: TPageControl;
    tsAsigs: TTabSheet;
    tsNoAsig: TTabSheet;
    grdAsigs: TcxGrid;
    tvAsigs: TcxGridTableView;
    colA_Node: TcxGridColumn;
    colA_Operacion: TcxGridColumn;
    colA_Operario: TcxGridColumn;
    colA_Score: TcxGridColumn;
    colA_Coste: TcxGridColumn;
    colA_Inicio: TcxGridColumn;
    colA_Fin: TcxGridColumn;
    colA_Argumento: TcxGridColumn;
    lvAsigs: TcxGridLevel;
    grdNoAsig: TcxGrid;
    tvNoAsig: TcxGridTableView;
    colN_Node: TcxGridColumn;
    colN_Operacion: TcxGridColumn;
    colN_Motivo: TcxGridColumn;
    lvNoAsig: TcxGridLevel;
    pnlBottom: TPanel;
    lblTotales: TLabel;
    btnAplicar: TcxButton;
    btnCancelar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnRecalcularClick(Sender: TObject);
    procedure btnEditarPesosClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure tvAsigsDblClick(Sender: TObject);
    procedure colA_ArgumentoButtonClick(Sender: TObject;
      AButtonIndex: Integer);
  private
    FNodeRepo: TNodeDataRepo;
    FOpRepo: TOperariosRepo;
    FAbsRepo: TOperatorAbsencesRepo;
    FHabRepo: THabilidadRepo;
    FOpTypesRepo: TOperationTypesRepo;
    FGetPredecesores: TFnGetPredecesores;
    FPesos: TPesosPlanificacion;
    FNodeIds: TArray<Integer>;
    FResultado: TPlanProdResultado;
    FSortedAsigs: TArray<TPlanProdAsignacion>;  // mismo orden que el grid
    procedure Recalcular;
    procedure RefreshAsigsGrid;
    procedure RefreshNoAsigGrid;
    procedure ShowBreakdownAt(Idx: Integer);
    procedure UpdateTotales;
    procedure AplicarAsignaciones;
    function MotivoNoAsignable(NodeId: Integer): string;
  public
    class function Execute(ANodeRepo: TNodeDataRepo; AOpRepo: TOperariosRepo;
      AAbsRepo: TOperatorAbsencesRepo; AHabRepo: THabilidadRepo;
      AOpTypesRepo: TOperationTypesRepo;
      const ANodeIds: TArray<Integer>;
      var APesos: TPesosPlanificacion;
      AGetPredecesores: TFnGetPredecesores = nil): Boolean;
  end;

implementation

uses
  uPesosScoring, uScoreBreakdown, uDMPlanner, uCentreCalendar;

{$R *.dfm}

function ResolveCalendar: TCentreCalendar;
begin
  Result := nil;
  if (DMPlanner <> nil) and (DMPlanner.CalendarsRepo <> nil) then
    Result := DMPlanner.CalendarsRepo.GetDefault;
end;

class function TfrmAutoPlanificacion.Execute(ANodeRepo: TNodeDataRepo;
  AOpRepo: TOperariosRepo; AAbsRepo: TOperatorAbsencesRepo;
  AHabRepo: THabilidadRepo; AOpTypesRepo: TOperationTypesRepo;
  const ANodeIds: TArray<Integer>;
  var APesos: TPesosPlanificacion;
  AGetPredecesores: TFnGetPredecesores): Boolean;
var
  F: TfrmAutoPlanificacion;
begin
  F := TfrmAutoPlanificacion.Create(nil);
  try
    F.FNodeRepo := ANodeRepo;
    F.FOpRepo := AOpRepo;
    F.FAbsRepo := AAbsRepo;
    F.FHabRepo := AHabRepo;
    F.FOpTypesRepo := AOpTypesRepo;
    F.FGetPredecesores := AGetPredecesores;
    F.FPesos := APesos;
    F.FNodeIds := ANodeIds;
    Result := F.ShowModal = mrOk;
    if Result then
      APesos := F.FPesos;
  finally
    F.Free;
  end;
end;

procedure TfrmAutoPlanificacion.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
  pcResult.ActivePageIndex := 0;
  dtpFecha.Date := Trunc(Now);
  dtpHora.Time := EncodeTime(8, 0, 0, 0);

  // cxGrid styling
  tvAsigs.OptionsBehavior.IncSearch := True;
  tvAsigs.OptionsCustomize.ColumnsQuickCustomization := True;
  tvAsigs.OptionsData.Editing := False;
  tvAsigs.OptionsSelection.CellSelect := False;
  tvAsigs.OptionsView.Indicator := True;
  tvAsigs.OptionsView.GroupByBox := False;

  tvNoAsig.OptionsBehavior.IncSearch := True;
  tvNoAsig.OptionsData.Editing := False;
  tvNoAsig.OptionsSelection.CellSelect := False;
  tvNoAsig.OptionsView.Indicator := True;
  tvNoAsig.OptionsView.GroupByBox := False;
end;

procedure TfrmAutoPlanificacion.FormShow(Sender: TObject);
begin
  Recalcular;
end;

procedure TfrmAutoPlanificacion.Recalcular;
var
  Engine: TPlanProdEngine;
  Fecha: TDateTime;
begin
  Fecha := Trunc(dtpFecha.Date) + TimeOf(dtpHora.Time);
  Engine := TPlanProdEngine.Create(FNodeRepo, FOpRepo, FAbsRepo, FHabRepo,
    FOpTypesRepo);
  try
    Engine.CalendarioFestivos := ResolveCalendar;
    Engine.Pesos := FPesos;
    Engine.GetPredecesores := FGetPredecesores;
    FResultado := Engine.PlanificarBatch(FNodeIds, Fecha);
  finally
    Engine.Free;
  end;
  RefreshAsigsGrid;
  RefreshNoAsigGrid;
  UpdateTotales;
  // Si no hay nada para aplicar, deshabilitar Aplicar
  btnAplicar.Enabled := Length(FResultado.Asignaciones) > 0;
end;

procedure TfrmAutoPlanificacion.RefreshAsigsGrid;
var
  I, J: Integer;
  A, Tmp: TPlanProdAsignacion;
  Op: TOperario;
  Node: TNodeData;
  OpNombre: string;
  CountByNode: TDictionary<Integer, Integer>;
  NumOps: Integer;
begin
  // Ordenar por NodeDataId asc para agrupar visualmente N operarios del
  // mismo nodo en filas contiguas. Insertion sort (lista pequenya).
  FSortedAsigs := Copy(FResultado.Asignaciones);
  for I := 1 to High(FSortedAsigs) do
  begin
    Tmp := FSortedAsigs[I];
    J := I - 1;
    while (J >= 0) and (FSortedAsigs[J].NodeDataId > Tmp.NodeDataId) do
    begin
      FSortedAsigs[J + 1] := FSortedAsigs[J];
      Dec(J);
    end;
    FSortedAsigs[J + 1] := Tmp;
  end;

  // Contar operarios por nodo (para badge de paralelismo)
  CountByNode := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to High(FSortedAsigs) do
    begin
      if CountByNode.TryGetValue(FSortedAsigs[I].NodeDataId, NumOps) then
        CountByNode[FSortedAsigs[I].NodeDataId] := NumOps + 1
      else
        CountByNode.Add(FSortedAsigs[I].NodeDataId, 1);
    end;

    tvAsigs.BeginUpdate;
    try
      tvAsigs.DataController.RecordCount := 0;
      tvAsigs.DataController.RecordCount := Length(FSortedAsigs);
      for I := 0 to High(FSortedAsigs) do
      begin
        A := FSortedAsigs[I];
        if FOpRepo.GetOperarioById(A.OperarioId, Op) then
          OpNombre := Op.Nombre
        else
          OpNombre := IntToStr(A.OperarioId);

        // Si el nodo tiene mas de 1 operario, anadir badge "(NxOPS)"
        var NodeStr: string;
        if CountByNode.TryGetValue(A.NodeDataId, NumOps) and (NumOps > 1) then
          NodeStr := Format('%d  [%dx]', [A.NodeDataId, NumOps])
        else
          NodeStr := IntToStr(A.NodeDataId);

        tvAsigs.DataController.Values[I, colA_Node.Index] := NodeStr;
        if FNodeRepo.TryGetById(A.NodeDataId, Node) then
          tvAsigs.DataController.Values[I, colA_Operacion.Index] := Node.Operacion
        else
          tvAsigs.DataController.Values[I, colA_Operacion.Index] := A.Operacion;
        tvAsigs.DataController.Values[I, colA_Operario.Index] := OpNombre;
        tvAsigs.DataController.Values[I, colA_Score.Index] :=
          FormatFloat('0.00', A.Score);
        tvAsigs.DataController.Values[I, colA_Coste.Index] :=
          FormatFloat('0.00 EUR', A.CosteEstimado);
        tvAsigs.DataController.Values[I, colA_Inicio.Index] :=
          FormatDateTime('dd/mm hh:nn', A.HoraInicioPrevista);
        tvAsigs.DataController.Values[I, colA_Fin.Index] :=
          FormatDateTime('dd/mm hh:nn', A.HoraFinPrevista);
        tvAsigs.DataController.Values[I, colA_Argumento.Index] := '';
      end;
    finally
      tvAsigs.EndUpdate;
    end;
  finally
    CountByNode.Free;
  end;
end;

procedure TfrmAutoPlanificacion.RefreshNoAsigGrid;
var
  I: Integer;
  Node: TNodeData;
  Operacion: string;
begin
  tvNoAsig.BeginUpdate;
  try
    tvNoAsig.DataController.RecordCount := 0;
    tvNoAsig.DataController.RecordCount := Length(FResultado.NodosNoAsignados);
    for I := 0 to High(FResultado.NodosNoAsignados) do
    begin
      tvNoAsig.DataController.Values[I, colN_Node.Index] :=
        FResultado.NodosNoAsignados[I];
      Operacion := '';
      if FNodeRepo.TryGetById(FResultado.NodosNoAsignados[I], Node) then
        Operacion := Node.Operacion;
      tvNoAsig.DataController.Values[I, colN_Operacion.Index] := Operacion;
      tvNoAsig.DataController.Values[I, colN_Motivo.Index] :=
        MotivoNoAsignable(FResultado.NodosNoAsignados[I]);
    end;
  finally
    tvNoAsig.EndUpdate;
  end;
  tsNoAsig.Caption :=
    Format('No asignables (%d)', [Length(FResultado.NodosNoAsignados)]);
  tsAsigs.Caption :=
    Format('Asignaciones (%d)', [Length(FResultado.Asignaciones)]);
end;

function TfrmAutoPlanificacion.MotivoNoAsignable(NodeId: Integer): string;
var
  Node: TNodeData;
  Engine: TPlanProdEngine;
  Cand: TPlanProdAsignacion;
  Fecha: TDateTime;
begin
  Result := 'Sin operarios elegibles';
  if not FNodeRepo.TryGetById(NodeId, Node) then Exit;
  Fecha := Trunc(dtpFecha.Date) + TimeOf(dtpHora.Time);
  Engine := TPlanProdEngine.Create(FNodeRepo, FOpRepo, FAbsRepo, FHabRepo,
    FOpTypesRepo);
  try
    Engine.CalendarioFestivos := ResolveCalendar;
    Cand := Engine.MejorOperarioPara(Node, Fecha);
    if Cand.MotivoNoElegible <> '' then
      Result := Cand.MotivoNoElegible;
  finally
    Engine.Free;
  end;
end;

procedure TfrmAutoPlanificacion.UpdateTotales;
begin
  lblTotales.Caption := Format(
    'Asignaciones: %d   |   No asignables: %d   |   ' +
    'Coste total: %.2f '#8364'   |   Score total: %.2f',
    [Length(FResultado.Asignaciones),
     Length(FResultado.NodosNoAsignados),
     FResultado.CosteTotal,
     FResultado.ScoreTotal]);
end;

procedure TfrmAutoPlanificacion.btnRecalcularClick(Sender: TObject);
begin
  Recalcular;
end;

procedure TfrmAutoPlanificacion.btnEditarPesosClick(Sender: TObject);
begin
  if TfrmPesosScoring.Execute(FPesos) then
    Recalcular;
end;

procedure TfrmAutoPlanificacion.AplicarAsignaciones;
var
  I: Integer;
  A: TPlanProdAsignacion;
  Asig: TAsignacionOperario;
  CountByNode: TDictionary<Integer, Integer>;
  N: Integer;
  Node: TNodeData;
  Pair: TPair<Integer, Integer>;
  NodosAfectados: TDictionary<Integer, Boolean>;
  NodeIdAfectado: Integer;
begin
  // 1) Limpiar asignaciones previas de los nodos que reciben asignacion nueva,
  //    para que el plan nuevo sustituya al anterior (no se mezclen operarios
  //    viejos con nuevos). El callback del repo borra tambien en SQL.
  NodosAfectados := TDictionary<Integer, Boolean>.Create;
  try
    for I := 0 to High(FResultado.Asignaciones) do
      NodosAfectados.AddOrSetValue(FResultado.Asignaciones[I].NodeDataId, True);
    for NodeIdAfectado in NodosAfectados.Keys do
      FOpRepo.ClearAsignacionsByNode(NodeIdAfectado);
  finally
    NodosAfectados.Free;
  end;

  // 2) Persistir asignaciones nuevas (1 fila por (operario, nodo))
  CountByNode := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to High(FResultado.Asignaciones) do
    begin
      A := FResultado.Asignaciones[I];
      Asig.OperarioId := A.OperarioId;
      Asig.DataId := A.NodeDataId;
      Asig.Horas := MinutesBetween(A.HoraFinPrevista, A.HoraInicioPrevista) / 60;
      Asig.IsLocked := False;
      Asig.LockedBy := '';
      Asig.LockedAt := 0;
      FOpRepo.AddAsignacion(Asig);

      // Acumular cuantos operarios se han asignado a cada nodo
      if CountByNode.TryGetValue(A.NodeDataId, N) then
        CountByNode[A.NodeDataId] := N + 1
      else
        CountByNode.Add(A.NodeDataId, 1);
    end;

    // Actualizar TNodeData.OperariosAsignados para que el Gantt en modo
    // 'Operarios' muestre el estado correcto (verde/amarillo/rojo).
    if Assigned(FNodeRepo) then
    begin
      for Pair in CountByNode do
      begin
        if FNodeRepo.TryGetById(Pair.Key, Node) then
        begin
          Node.OperariosAsignados := Pair.Value;
          Node.Modified := True;
          FNodeRepo.AddOrUpdate(Node);
        end;
      end;
    end;
  finally
    CountByNode.Free;
  end;
end;

procedure TfrmAutoPlanificacion.btnAplicarClick(Sender: TObject);
begin
  if Length(FResultado.Asignaciones) = 0 then Exit;
  if MessageDlg(Format('?Aplicar %d asignaciones?',
       [Length(FResultado.Asignaciones)]),
     mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  AplicarAsignaciones;
  ModalResult := mrOk;
end;

procedure TfrmAutoPlanificacion.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmAutoPlanificacion.ShowBreakdownAt(Idx: Integer);
var
  A: TPlanProdAsignacion;
  Op: TOperario;
  Node: TNodeData;
  Engine: TPlanProdEngine;
  Brk: TScoreBreakdown;
  Fecha: TDateTime;
begin
  if (Idx < 0) or (Idx > High(FSortedAsigs)) then Exit;
  A := FSortedAsigs[Idx];
  if not FOpRepo.GetOperarioById(A.OperarioId, Op) then Exit;
  if not FNodeRepo.TryGetById(A.NodeDataId, Node) then Exit;

  Fecha := Trunc(dtpFecha.Date) + TimeOf(dtpHora.Time);

  // Crear motor temporal con misma config y pedirle el desglose.
  Engine := TPlanProdEngine.Create(FNodeRepo, FOpRepo, FAbsRepo, FHabRepo,
    FOpTypesRepo);
  try
    Engine.CalendarioFestivos := ResolveCalendar;
    Engine.Pesos := FPesos;
    Engine.GetPredecesores := FGetPredecesores;
    // PlanificarBatch con array vacio siembra la continuidad del repo.
    Engine.PlanificarBatch([], Fecha);
    Brk := Engine.ExplicarScore(Op, Node, Fecha);
  finally
    Engine.Free;
  end;

  TfrmScoreBreakdown.Execute(Brk);
end;

procedure TfrmAutoPlanificacion.tvAsigsDblClick(Sender: TObject);
begin
  ShowBreakdownAt(tvAsigs.DataController.FocusedRecordIndex);
end;

procedure TfrmAutoPlanificacion.colA_ArgumentoButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  ShowBreakdownAt(tvAsigs.DataController.FocusedRecordIndex);
end;

end.
