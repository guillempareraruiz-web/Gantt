unit uLoteViewer;

// ============================================================================
// Visor / gestor de Lote (batch): muestra y gestiona las operaciones (OP /
// nodos) agrupadas para procesarse juntas en un mismo centro (p.ej. mismo color
// de pintura, misma hornada de horno).
//
// Se abre desde el Gantt (doble clic o "Ver lote...") con el LoteId. Permite:
//  - Ver KPIs: nº ops, duracion original (suma), duracion teorica, ahorro.
//  - Configurar el modo (secuencial/paralelo) y el setup compartido, y aplicar
//    -> recalcula la ventana del lote (DMPlanner.ActualizarLote).
//  - Quitar una OP del lote / desplanificar una OP (sacarla del plan).
//  - Doble clic en una fila -> abre el NodeInspector de esa OP.
//
// Execute devuelve True si hubo cambios, para que el Gantt recargue el plan.
// ============================================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Math, System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Dialogs,
  Data.Win.ADODB, Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxClasses, cxEdit, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxContainer,
  cxNavigator, cxDataStorage, dxSkinsCore, dxSkinOffice2019Colorful,
  dxScrollbarAnnotations;

type
  TfrmLoteViewer = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblResumen: TLabel;
    lblKpis: TLabel;
    pnlConfig: TPanel;
    lblModo: TLabel;
    lblSetup: TLabel;
    cboModo: TComboBox;
    edSetupMin: TEdit;
    btnAplicar: TButton;
    grdOps: TcxGrid;
    tvOps: TcxGridTableView;
    lvOps: TcxGridLevel;
    colNodeId: TcxGridColumn;
    colDataId: TcxGridColumn;
    colOperacion: TcxGridColumn;
    colOF: TcxGridColumn;
    colArticulo: TcxGridColumn;
    colDescripcion: TcxGridColumn;
    colInicio: TcxGridColumn;
    colFin: TcxGridColumn;
    colDuracion: TcxGridColumn;
    colDurOrig: TcxGridColumn;
    pnlBottom: TPanel;
    btnQuitar: TButton;
    btnDesplanificar: TButton;
    btnCerrar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);
    procedure btnQuitarClick(Sender: TObject);
    procedure btnDesplanificarClick(Sender: TObject);
    procedure tvOpsDblClick(Sender: TObject);
  private
    FConn: TADOConnection;
    FEmpresa: SmallInt;
    FLoteId: Integer;
    FChanged: Boolean;     // True si hubo cambios -> el Gantt debe recargar
    procedure LoadLote(ALoteId: Integer);
    function FilaSeleccionada(out ANodeId, ADataId: Integer): Boolean;
    procedure ReloadAll;
  public
    // Devuelve True si hubo cambios (el llamador debe recargar el plan).
    class function Execute(ALoteId: Integer): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uGanttTypes, uNodeInspector, Main;

function MinToStr(AMin: Double): string;
begin
  // Formato legible: horas + minutos.
  if AMin >= 60 then
    Result := Format('%.0f min (%.1f h)', [AMin, AMin / 60.0])
  else
    Result := Format('%.0f min', [AMin]);
end;

function VarToInt(const V: Variant): Integer;
begin
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := 0
  else
    Result := StrToIntDef(VarToStr(V), 0);
end;

class function TfrmLoteViewer.Execute(ALoteId: Integer): Boolean;
var
  F: TfrmLoteViewer;
begin
  F := TfrmLoteViewer.Create(Application);
  try
    F.FLoteId := ALoteId;
    F.LoadLote(ALoteId);
    F.ShowModal;
    Result := F.FChanged;
  finally
    F.Free;
  end;
end;

procedure TfrmLoteViewer.FormCreate(Sender: TObject);
begin
  FConn := DMPlanner.ADOConnection;
  FEmpresa := DMPlanner.CodigoEmpresa;
  FChanged := False;
end;

procedure TfrmLoteViewer.ReloadAll;
begin
  LoadLote(FLoteId);
end;

procedure TfrmLoteViewer.LoadLote(ALoteId: Integer);
var
  Q: TADOQuery;
  I: Integer;
  Info: TLoteInfo;
begin
  // --- Cabecera + KPIs ---
  if DMPlanner.GetLoteInfo(ALoteId, Info) then
  begin
    lblTitulo.Caption := 'Lote: ' + Info.Caption;
    lblResumen.Caption := Format('%d operaciones  -  Centro: %s  -  %s a %s',
      [Info.NumOps, Info.CentroNombre,
       FormatDateTime('dd/mm/yyyy hh:nn', Info.FechaInicio),
       FormatDateTime('dd/mm/yyyy hh:nn', Info.FechaFin)]);
    lblKpis.Caption := Format(
      'Duraci'#243'n original (suma): %s    |    Duraci'#243'n te'#243'rica del lote: %s    |    Ahorro: %s (%.0f%%)',
      [MinToStr(Info.DuracionOriginalTotal),
       MinToStr(Info.DuracionEfectiva),
       MinToStr(Info.AhorroMin), Info.AhorroPct]);

    // Reflejar modo/setup en los controles de configuracion.
    if Info.Modo = 1 then cboModo.ItemIndex := 1 else cboModo.ItemIndex := 0;
    edSetupMin.Text := Format('%.0f', [Info.SetupMin]);
  end
  else
  begin
    lblTitulo.Caption := 'Lote';
    lblResumen.Caption := 'No se encontr'#243' el lote.';
    lblKpis.Caption := ' ';
  end;

  // --- Operaciones (nodos) del lote ---
  tvOps.BeginUpdate;
  try
    tvOps.DataController.RecordCount := 0;
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConn;
      // DataId == NodeId en este modelo (el repo usa NodeId como clave de
      // NodeData: ver uNodesRepo, D.DataId := N.Id). Exponemos NodeId como DataId.
      Q.SQL.Text :=
        'SELECT n.NodeId, n.NodeId AS DataId, ' +
        '  ISNULL(nd.Operacion, '''') AS Operacion, ' +
        '  CASE WHEN ISNULL(nd.NumeroOF,0) > 0 ' +
        '    THEN CONCAT(ISNULL(nd.SerieOF,''''), ''-'', nd.NumeroOF) ELSE '''' END AS OF_, ' +
        '  ISNULL(nd.CodigoArticulo, '''') AS Articulo, ' +
        '  ISNULL(nd.DescripcionArticulo, '''') AS Descripcion, ' +
        '  n.FechaInicio, n.FechaFin, ' +
        '  ISNULL(nd.DuracionMin, 0) AS DuracionMin, ' +
        '  ISNULL(nd.DuracionMinOriginal, 0) AS DuracionMinOrig ' +
        'FROM FS_PL_Node n ' +
        'LEFT JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
        '  AND nd.NodeId = n.NodeId ' +
        'WHERE n.CodigoEmpresa = :Emp AND n.LoteId = :Lote ' +
        'ORDER BY n.FechaInicio, n.NodeId';
      Q.Parameters.ParamByName('Emp').Value := FEmpresa;
      Q.Parameters.ParamByName('Lote').Value := ALoteId;
      Q.Open;
      I := 0;
      while not Q.Eof do
      begin
        tvOps.DataController.RecordCount := I + 1;
        tvOps.DataController.Values[I, colNodeId.Index]      := Q.FieldByName('NodeId').AsInteger;
        tvOps.DataController.Values[I, colDataId.Index]      := Q.FieldByName('DataId').AsInteger;
        tvOps.DataController.Values[I, colOperacion.Index]   := Q.FieldByName('Operacion').AsString;
        tvOps.DataController.Values[I, colOF.Index]          := Q.FieldByName('OF_').AsString;
        tvOps.DataController.Values[I, colArticulo.Index]    := Q.FieldByName('Articulo').AsString;
        tvOps.DataController.Values[I, colDescripcion.Index] := Q.FieldByName('Descripcion').AsString;
        if not Q.FieldByName('FechaInicio').IsNull then
          tvOps.DataController.Values[I, colInicio.Index]    := Q.FieldByName('FechaInicio').AsDateTime;
        if not Q.FieldByName('FechaFin').IsNull then
          tvOps.DataController.Values[I, colFin.Index]       := Q.FieldByName('FechaFin').AsDateTime;
        tvOps.DataController.Values[I, colDuracion.Index]    := Q.FieldByName('DuracionMin').AsFloat;
        tvOps.DataController.Values[I, colDurOrig.Index]     := Q.FieldByName('DuracionMinOrig').AsFloat;
        Inc(I);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    tvOps.EndUpdate;
  end;
end;

function TfrmLoteViewer.FilaSeleccionada(out ANodeId, ADataId: Integer): Boolean;
var
  Rec: Integer;
begin
  Result := False;
  ANodeId := 0; ADataId := 0;
  Rec := tvOps.DataController.FocusedRecordIndex;
  if (Rec < 0) or (Rec >= tvOps.DataController.RecordCount) then Exit;
  ANodeId := VarToInt(tvOps.DataController.Values[Rec, colNodeId.Index]);
  ADataId := VarToInt(tvOps.DataController.Values[Rec, colDataId.Index]);
  Result := ANodeId > 0;
end;

procedure TfrmLoteViewer.btnAplicarClick(Sender: TObject);
var
  Modo: Integer;
  Setup: Double;
begin
  if cboModo.ItemIndex = 1 then Modo := 1 else Modo := 0;
  Setup := StrToFloatDef(Trim(edSetupMin.Text), 0);
  if Setup < 0 then Setup := 0;
  try
    DMPlanner.ActualizarLote(FLoteId, Modo, Setup);
  except
    on E: Exception do
    begin
      ShowMessage('Error al aplicar la configuraci'#243'n del lote: ' + E.Message);
      Exit;
    end;
  end;
  FChanged := True;
  ReloadAll;
end;

procedure TfrmLoteViewer.btnQuitarClick(Sender: TObject);
var
  NodeId, DataId: Integer;
begin
  if not FilaSeleccionada(NodeId, DataId) then
  begin
    ShowMessage('Selecciona una operaci'#243'n de la lista.');
    Exit;
  end;
  if MessageDlg(#191'Quitar esta operaci'#243'n del lote? Volver'#225' a su duraci'#243'n real.',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  try
    DMPlanner.QuitarNodoDeLote(NodeId);
    // Si el lote queda con menos de 2 miembros, ya no tiene sentido: desagrupar.
    if DMPlanner.ContarMiembrosLote(FLoteId) < 2 then
    begin
      DMPlanner.DesagruparLote(FLoteId);
      FChanged := True;
      ModalResult := mrOk;   // el lote ya no existe: cerrar
      Exit;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Error al quitar del lote: ' + E.Message);
      Exit;
    end;
  end;
  FChanged := True;
  ReloadAll;
end;

procedure TfrmLoteViewer.btnDesplanificarClick(Sender: TObject);
var
  NodeId, DataId: Integer;
begin
  if not FilaSeleccionada(NodeId, DataId) then
  begin
    ShowMessage('Selecciona una operaci'#243'n de la lista.');
    Exit;
  end;
  if MessageDlg(#191'Desplanificar esta operaci'#243'n? Se quitar'#225' del plan y volver'#225' al backlog.',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  try
    // DesplanificarNodes borra deps, asignaciones, NodeData y Node. Al
    // desaparecer del lote, comprobamos si quedan <2 miembros para desagrupar.
    DMPlanner.DesplanificarNodes(TArray<Integer>.Create(NodeId));
    if DMPlanner.ContarMiembrosLote(FLoteId) < 2 then
    begin
      DMPlanner.DesagruparLote(FLoteId);
      FChanged := True;
      ModalResult := mrOk;
      Exit;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Error al desplanificar: ' + E.Message);
      Exit;
    end;
  end;
  FChanged := True;
  ReloadAll;
end;

procedure TfrmLoteViewer.tvOpsDblClick(Sender: TObject);
var
  NodeId, DataId: Integer;
  D: TNodeData;
begin
  if not FilaSeleccionada(NodeId, DataId) then Exit;
  if not DMPlanner.NodeDataRepo.TryGetById(DataId, D) then
  begin
    ShowMessage('No se encontraron los datos de la operaci'#243'n.');
    Exit;
  end;
  if TfrmNodeInspector.Execute(D, False, nil) then
  begin
    D.Modified := True;
    DMPlanner.NodeDataRepo.AddOrUpdate(D);
    // Persistir el cambio del NodeData (AutoSaver), igual que el doble-clic del
    // Gantt. Si no, LoadActivePlan al cerrar recargaria desde BD y se perderia.
    if Assigned(Form1) then
      Form1.NotifyPlanModified(TArray<Integer>.Create(DataId));
    FChanged := True;
    ReloadAll;
  end;
end;

end.
