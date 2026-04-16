unit uGenerarNodosDemo;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.DateUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit,
  cxCalendar, cxContainer, cxDropDownEdit,
  Data.Win.ADODB, Data.DB;

type
  TfrmGenerarNodosDemo = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlBottom: TPanel;
    btnGenerar: TButton;
    btnCancel: TButton;
    pnlContent: TPanel;
    lblSeccionEstructura: TLabel;
    rbSimple: TRadioButton;
    rbCompleja: TRadioButton;
    lblSeccionCantidades: TLabel;
    lblNumOFs: TLabel;
    spNumOFs: TcxSpinEdit;
    lblOTsPorOF: TLabel;
    spOTsPorOF: TcxSpinEdit;
    lblOpsPorOT: TLabel;
    spOpsPorOT: TcxSpinEdit;
    lblPctPlanificados: TLabel;
    spPctPlanificados: TcxSpinEdit;
    lblSeccionFechas: TLabel;
    lblFechaInicio: TLabel;
    dtFechaInicio: TcxDateEdit;
    lblFechaFin: TLabel;
    dtFechaFin: TcxDateEdit;
    lblSeccionRecursos: TLabel;
    chkIncluirOperarios: TCheckBox;
    chkIncluirMoldes: TCheckBox;
    lblSeccionOpciones: TLabel;
    chkLimpiarExistentes: TCheckBox;
    chkGenerarDependencias: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure btnGenerarClick(Sender: TObject);
    procedure EstructuraChange(Sender: TObject);
  private
    FCenterIds: TArray<Integer>;
    FOperatorIds: TArray<Integer>;
    FMoldIds: TArray<Integer>;
    procedure LoadRecursos;
    procedure Generar;
    procedure LimpiarNodosExistentes(const AConn: TADOConnection; const ACE, APID: string);
    function InsertarNodoCompleto(const AConn: TADOConnection;
      const ACE, APID: string;
      const ACenterId: Integer;
      const AOperacion: string;
      const AFechaInicio, AFechaFin: TDateTime;
      const APlanificado: Boolean;
      const ANumOF, ANumPedido, ANumTrabajo: Integer;
      const ADuracionMin: Double): Integer;
    procedure InsertarDependencia(const AConn: TADOConnection;
      const ACE, APID: string;
      AFromNodeId, AToNodeId: Integer);
    function RandomCenter: Integer;
    function RandomOperator: Integer;
    function RandomMold: Integer;
  public
    class function Execute: Boolean;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

const
  OPERACIONES: array[0..9] of string = (
    'CORTAR', 'PULIR', 'MONTAR', 'PINTAR', 'LACAR',
    'EMBALAR', 'BRONCEAR', 'TALADRAR', 'SOLDAR', 'MECANIZAR'
  );

class function TfrmGenerarNodosDemo.Execute: Boolean;
var
  F: TfrmGenerarNodosDemo;
begin
  F := TfrmGenerarNodosDemo.Create(Application);
  try
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmGenerarNodosDemo.FormCreate(Sender: TObject);
begin
  lblSubtitle.Caption :=
    'Empresa: ' + DMPlanner.CurrentEmpresaNombre +
    '   |   Proyecto: ' + DMPlanner.CurrentProjectName;

  // Pre-seleccionar estructura de empresa
  rbSimple.Checked := DMPlanner.EstructuraNodos = enSimple;
  rbCompleja.Checked := DMPlanner.EstructuraNodos = enCompleja;

  // Pre-seleccionar recursos de empresa
  chkIncluirOperarios.Checked := DMPlanner.PlanificaOperarios;
  chkIncluirMoldes.Checked := DMPlanner.PlanificaMoldes;

  // Fechas por defecto: hoy a hoy+30
  dtFechaInicio.Date := Trunc(Now);
  dtFechaFin.Date := Trunc(Now) + 30;

  EstructuraChange(nil);
  LoadRecursos;
end;

procedure TfrmGenerarNodosDemo.EstructuraChange(Sender: TObject);
var
  Compleja: Boolean;
begin
  Compleja := rbCompleja.Checked;
  spOTsPorOF.Enabled := Compleja;
  lblOTsPorOF.Enabled := Compleja;
  if not Compleja then
    spOTsPorOF.Value := 1;
end;

procedure TfrmGenerarNodosDemo.LoadRecursos;
var
  Q: TADOQuery;
  I: Integer;
  CE: string;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);

  // Centros activos
  SetLength(FCenterIds, 0);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT CenterId FROM FS_PL_Center WHERE CodigoEmpresa = ' +
      CE + ' AND Visible = 1 AND Habilitado = 1 ORDER BY CenterId';
    Q.Open;
    SetLength(FCenterIds, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FCenterIds[I] := Q.FieldByName('CenterId').AsInteger;
      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  // Operarios activos
  SetLength(FOperatorIds, 0);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT OperatorId FROM FS_PL_Operator WHERE CodigoEmpresa = ' +
      CE + ' AND Activo = 1 ORDER BY OperatorId';
    Q.Open;
    SetLength(FOperatorIds, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FOperatorIds[I] := Q.FieldByName('OperatorId').AsInteger;
      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  // Moldes disponibles
  SetLength(FMoldIds, 0);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT MoldId FROM FS_PL_Mold WHERE CodigoEmpresa = ' +
      CE + ' AND DisponiblePlanificacion = 1 ORDER BY MoldId';
    Q.Open;
    SetLength(FMoldIds, Q.RecordCount);
    I := 0;
    while not Q.Eof do
    begin
      FMoldIds[I] := Q.FieldByName('MoldId').AsInteger;
      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TfrmGenerarNodosDemo.RandomCenter: Integer;
begin
  if Length(FCenterIds) = 0 then Exit(-1);
  Result := FCenterIds[Random(Length(FCenterIds))];
end;

function TfrmGenerarNodosDemo.RandomOperator: Integer;
begin
  if Length(FOperatorIds) = 0 then Exit(-1);
  Result := FOperatorIds[Random(Length(FOperatorIds))];
end;

function TfrmGenerarNodosDemo.RandomMold: Integer;
begin
  if Length(FMoldIds) = 0 then Exit(-1);
  Result := FMoldIds[Random(Length(FMoldIds))];
end;

procedure TfrmGenerarNodosDemo.LimpiarNodosExistentes(const AConn: TADOConnection;
  const ACE, APID: string);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;

    Cmd.CommandText :=
      'DELETE FROM FS_PL_OperatorAssignment WHERE CodigoEmpresa = ' + ACE +
      ' AND NodeId IN (SELECT NodeId FROM FS_PL_Node ' +
      ' WHERE CodigoEmpresa = ' + ACE + ' AND ProjectId = ' + APID + ')';
    Cmd.Execute;

    Cmd.CommandText :=
      'DELETE FROM FS_PL_Dependency WHERE CodigoEmpresa = ' + ACE +
      ' AND ProjectId = ' + APID;
    Cmd.Execute;

    Cmd.CommandText :=
      'DELETE FROM FS_PL_NodeData WHERE CodigoEmpresa = ' + ACE +
      ' AND NodeId IN (SELECT NodeId FROM FS_PL_Node ' +
      ' WHERE CodigoEmpresa = ' + ACE + ' AND ProjectId = ' + APID + ')';
    Cmd.Execute;

    Cmd.CommandText :=
      'DELETE FROM FS_PL_Node WHERE CodigoEmpresa = ' + ACE +
      ' AND ProjectId = ' + APID;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

function TfrmGenerarNodosDemo.InsertarNodoCompleto(const AConn: TADOConnection;
  const ACE, APID: string;
  const ACenterId: Integer;
  const AOperacion: string;
  const AFechaInicio, AFechaFin: TDateTime;
  const APlanificado: Boolean;
  const ANumOF, ANumPedido, ANumTrabajo: Integer;
  const ADuracionMin: Double): Integer;
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  NodeId, OpId: Integer;
  FechaIniSQL, FechaFinSQL, CenterSQL: string;

  function QStr(const S: string): string;
  begin
    Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
  end;

  function FmtDT(const T: TDateTime): string;
  begin
    Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', T) + '''';
  end;

begin
  if APlanificado then
  begin
    FechaIniSQL := FmtDT(AFechaInicio);
    FechaFinSQL := FmtDT(AFechaFin);
  end
  else
  begin
    FechaIniSQL := 'NULL';
    FechaFinSQL := 'NULL';
  end;

  if ACenterId <= 0 then
    CenterSQL := 'NULL'
  else
    CenterSQL := IntToStr(ACenterId);

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_Node (CodigoEmpresa, ProjectId, CenterId, ' +
      '  FechaInicio, FechaFin, DuracionMin, Caption) VALUES (' +
      ACE + ', ' + APID + ', ' + CenterSQL + ', ' +
      FechaIniSQL + ', ' + FechaFinSQL + ', ' +
      FloatToStr(ADuracionMin).Replace(',', '.') + ', ' +
      QStr(AOperacion) + ')';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // Obtener el ID recién insertado
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := 'SELECT MAX(NodeId) AS NewId FROM FS_PL_Node ' +
      'WHERE CodigoEmpresa = ' + ACE + ' AND ProjectId = ' + APID;
    Q.Open;
    NodeId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;

  // NodeData
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, ' +
      '  NumeroOF, NumeroPedido, NumeroTrabajo, DuracionMin, DuracionMinOriginal, ' +
      '  UnidadesAFabricar, OperariosNecesarios) VALUES (' +
      ACE + ', ' + IntToStr(NodeId) + ', ' + QStr(AOperacion) + ', ' +
      IntToStr(ANumOF) + ', ' + IntToStr(ANumPedido) + ', ' +
      QStr(IntToStr(ANumTrabajo)) + ', ' +
      FloatToStr(ADuracionMin).Replace(',', '.') + ', ' +
      FloatToStr(ADuracionMin).Replace(',', '.') + ', ' +
      IntToStr(100 + Random(900)) + ', 1)';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // Asignar operario aleatorio (si planificado y hay operarios disponibles)
  if APlanificado and chkIncluirOperarios.Checked and (Length(FOperatorIds) > 0) then
  begin
    OpId := RandomOperator;
    if OpId > 0 then
    begin
      Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := AConn;
        Cmd.CommandText :=
          'INSERT INTO FS_PL_OperatorAssignment (CodigoEmpresa, OperatorId, NodeId, Horas) ' +
          'VALUES (' + ACE + ', ' + IntToStr(OpId) + ', ' + IntToStr(NodeId) + ', ' +
          FloatToStr(ADuracionMin / 60).Replace(',', '.') + ')';
        Cmd.Execute;
      finally
        Cmd.Free;
      end;
    end;
  end;

  Result := NodeId;
end;

procedure TfrmGenerarNodosDemo.InsertarDependencia(const AConn: TADOConnection;
  const ACE, APID: string; AFromNodeId, AToNodeId: Integer);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;
    // TipoLink = 0 (FS - Finish to Start); PorcentajeDependencia = 100
    Cmd.CommandText :=
      'INSERT INTO FS_PL_Dependency (CodigoEmpresa, ProjectId, FromNodeId, ToNodeId, ' +
      '  TipoLink, PorcentajeDependencia) VALUES (' +
      ACE + ', ' + APID + ', ' + IntToStr(AFromNodeId) + ', ' +
      IntToStr(AToNodeId) + ', 0, 100)';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TfrmGenerarNodosDemo.Generar;
var
  AConn: TADOConnection;
  CE, PID: string;
  NumOFs, OTsPorOF, OpsPorOT, PctPlan: Integer;
  FIni, FFin: TDateTime;
  DuracionMin, SpanDias: Double;
  iOF, iOT, iOP: Integer;
  NumOF, NumPedido, NumTrabajo: Integer;
  Operacion: string;
  CenterId: Integer;
  FechaIni, FechaFin: TDateTime;
  Planificado: Boolean;
  TotalNodos, TotalPlan, TotalDeps: Integer;
  NodeId: Integer;
  OTNodeIds: TArray<Integer>;
  K: Integer;
  GenerarDeps: Boolean;
begin
  if Length(FCenterIds) = 0 then
  begin
    ShowMessage('No hay centros disponibles. Primero crea centros de trabajo.');
    Exit;
  end;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(DMPlanner.CurrentProjectId);

  NumOFs := spNumOFs.Value;
  OTsPorOF := spOTsPorOF.Value;
  OpsPorOT := spOpsPorOT.Value;
  PctPlan := spPctPlanificados.Value;
  FIni := dtFechaInicio.Date;
  FFin := dtFechaFin.Date;
  if FFin <= FIni then FFin := FIni + 30;
  SpanDias := FFin - FIni;

  AConn := DMPlanner.ADOConnection;
  TotalNodos := 0;
  TotalPlan := 0;
  TotalDeps := 0;
  GenerarDeps := chkGenerarDependencias.Checked;

  AConn.BeginTrans;
  try
    if chkLimpiarExistentes.Checked then
      LimpiarNodosExistentes(AConn, CE, PID);

    Randomize;
    for iOF := 1 to NumOFs do
    begin
      NumOF := 10000 + iOF;
      NumPedido := 5000 + (iOF div 3);  // ~3 OFs por pedido
      for iOT := 1 to OTsPorOF do
      begin
        NumTrabajo := iOF * 100 + iOT;
        SetLength(OTNodeIds, 0);
        for iOP := 1 to OpsPorOT do
        begin
          Operacion := OPERACIONES[Random(Length(OPERACIONES))];
          CenterId := RandomCenter;
          DuracionMin := 30 + Random(240);  // 30 min a 4.5 h
          Planificado := Random(100) < PctPlan;

          if Planificado then
          begin
            FechaIni := FIni + Random(Round(SpanDias)) +
              (Random(8) + 6) / 24.0;  // entre 6:00 y 14:00
            FechaFin := FechaIni + (DuracionMin / (24 * 60));
          end
          else
          begin
            FechaIni := 0;
            FechaFin := 0;
          end;

          NodeId := InsertarNodoCompleto(AConn, CE, PID, CenterId, Operacion,
            FechaIni, FechaFin, Planificado,
            NumOF, NumPedido, NumTrabajo, DuracionMin);

          SetLength(OTNodeIds, Length(OTNodeIds) + 1);
          OTNodeIds[High(OTNodeIds)] := NodeId;

          Inc(TotalNodos);
          if Planificado then Inc(TotalPlan);
        end;

        // Encadenar consecutivamente las OPs de esta OT (FS)
        if GenerarDeps and (Length(OTNodeIds) >= 2) then
        begin
          for K := 0 to High(OTNodeIds) - 1 do
          begin
            InsertarDependencia(AConn, CE, PID, OTNodeIds[K], OTNodeIds[K + 1]);
            Inc(TotalDeps);
          end;
        end;
      end;
    end;

    AConn.CommitTrans;
  except
    AConn.RollbackTrans;
    raise;
  end;

  ShowMessage(Format(
    'Generación completada:' + sLineBreak +
    '  %d nodos creados' + sLineBreak +
    '  %d planificados (%d%%)' + sLineBreak +
    '  %d sin planificar' + sLineBreak +
    '  %d dependencias',
    [TotalNodos, TotalPlan,
     IfThen(TotalNodos > 0, Round(TotalPlan * 100 / TotalNodos), 0),
     TotalNodos - TotalPlan,
     TotalDeps]));
end;

procedure TfrmGenerarNodosDemo.btnGenerarClick(Sender: TObject);
begin
  try
    Generar;
    ModalResult := mrOk;
  except
    on E: Exception do
    begin
      ShowMessage('Error generando nodos: ' + E.Message);
      ModalResult := mrNone;
    end;
  end;
end;

end.
