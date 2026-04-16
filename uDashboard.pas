unit uDashboard;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmDashboard = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblFechaHora: TLabel;
    pnlCards: TPanel;
    pnlEmpresa: TPanel;
    lblEmpresaCap: TLabel;
    lblEmpresaNombre: TLabel;
    lblEmpresaCodigo: TLabel;
    pnlProyecto: TPanel;
    lblProyectoCap: TLabel;
    lblProyectoNombre: TLabel;
    lblProyectoTipo: TLabel;
    pnlUsuario: TPanel;
    lblUsuarioCap: TLabel;
    lblUsuarioNombre: TLabel;
    lblUsuarioRol: TLabel;
    pnlAcciones: TPanel;
    btnAbrirGantt: TButton;
    TimerReloj: TTimer;
    pnlMetricas: TPanel;
    lblMetricasCap: TLabel;
    lblCapCalendarios: TLabel;
    lblValCalendarios: TLabel;
    lblCapCentros: TLabel;
    lblValCentros: TLabel;
    lblCapAreas: TLabel;
    lblValAreas: TLabel;
    lblCapDepartamentos: TLabel;
    lblValDepartamentos: TLabel;
    lblCapTurnos: TLabel;
    lblValTurnos: TLabel;
    lblCapCapacitaciones: TLabel;
    lblValCapacitaciones: TLabel;
    lblCapOperarios: TLabel;
    lblValOperarios: TLabel;
    pnlProyectoActivo: TPanel;
    lblProyectoActivoCap: TLabel;
    lblCapFechaInicio: TLabel;
    lblValFechaInicio: TLabel;
    lblCapFechaFin: TLabel;
    lblValFechaFin: TLabel;
    lblCapFechaBloqueo: TLabel;
    lblValFechaBloqueo: TLabel;
    lblCapNodos: TLabel;
    lblValNodos: TLabel;
    lblCapOFs: TLabel;
    lblValOFs: TLabel;
    lblCapPedidos: TLabel;
    lblValPedidos: TLabel;
    lblCapCentrosUsados: TLabel;
    lblValCentrosUsados: TLabel;
    lblCapOperariosAsignados: TLabel;
    lblValOperariosAsignados: TLabel;
    lblCapDuracionTotal: TLabel;
    lblValDuracionTotal: TLabel;
    lblCapDependencias: TLabel;
    lblValDependencias: TLabel;
    lblCapMarcadores: TLabel;
    lblValMarcadores: TLabel;
    procedure FormShow(Sender: TObject);
    procedure TimerRelojTimer(Sender: TObject);
    procedure btnAbrirGanttClick(Sender: TObject);
    procedure lblValCalendariosClick(Sender: TObject);
    procedure lblValCentrosClick(Sender: TObject);
    procedure lblValAreasClick(Sender: TObject);
    procedure lblValDepartamentosClick(Sender: TObject);
    procedure lblValTurnosClick(Sender: TObject);
    procedure lblValCapacitacionesClick(Sender: TObject);
    procedure lblValOperariosClick(Sender: TObject);
  private
    FOnAbrirGantt: TNotifyEvent;
    procedure ActualizarReloj;
    procedure RefrescarProyectoActivo;
  public
    procedure Refrescar;
    property OnAbrirGantt: TNotifyEvent read FOnAbrirGantt write FOnAbrirGantt;
  end;

implementation

{$R *.dfm}

uses
  Vcl.Dialogs, System.DateUtils,
  Data.Win.ADODB, Data.DB,
  uDMPlanner, uLogin, uGestionAreas, uGestionDepartamentos, uGestionCalendarios,
  uGestionCentres, uGestionTurnos, uGestionCapacitaciones, uGestionOperaris;

procedure TfrmDashboard.FormShow(Sender: TObject);
begin
  Refrescar;
  ActualizarReloj;
  TimerReloj.Enabled := True;
end;

procedure TfrmDashboard.TimerRelojTimer(Sender: TObject);
begin
  ActualizarReloj;
end;

procedure TfrmDashboard.ActualizarReloj;
begin
  lblFechaHora.Caption := FormatDateTime('dddd, d" de "mmmm" de "yyyy   hh:nn:ss', Now);
end;

procedure TfrmDashboard.Refrescar;
var
  S: TUserSession;
  Tipo: string;
  NumCal, NumCen, NumArea, NumDept, NumTurn, NumSkill, NumOp: Integer;
begin
  // Empresa
  if DMPlanner.CurrentEmpresaNombre <> '' then
    lblEmpresaNombre.Caption := DMPlanner.CurrentEmpresaNombre
  else
    lblEmpresaNombre.Caption := '--';
  lblEmpresaCodigo.Caption := 'Código: ' + IntToStr(DMPlanner.CodigoEmpresa);

  NumCal := 0;
  if DMPlanner.CalendarsRepo <> nil then
    NumCal := DMPlanner.CalendarsRepo.Count;
  NumCen := 0;
  if DMPlanner.CentresRepo <> nil then
    NumCen := DMPlanner.CentresRepo.Count;
  NumArea := DMPlanner.CountTable('FS_PL_Area');
  NumDept := DMPlanner.CountTable('FS_PL_Department');

  NumTurn := DMPlanner.CountTable('FS_PL_Shift');
  NumSkill := DMPlanner.CountTable('FS_PL_OperatorSkill');
  NumOp := DMPlanner.CountTable('FS_PL_Operator');

  lblValCalendarios.Caption := IntToStr(NumCal);
  lblValCentros.Caption := IntToStr(NumCen);
  lblValAreas.Caption := IntToStr(NumArea);
  lblValDepartamentos.Caption := IntToStr(NumDept);
  lblValTurnos.Caption := IntToStr(NumTurn);
  lblValCapacitaciones.Caption := IntToStr(NumSkill);
  lblValOperarios.Caption := IntToStr(NumOp);

  RefrescarProyectoActivo;

  // Proyecto
  if DMPlanner.CurrentProjectId > 0 then
  begin
    lblProyectoNombre.Caption := DMPlanner.CurrentProjectName;
    if DMPlanner.CurrentProjectIsMaster then
      Tipo := 'MASTER'
    else
      Tipo := 'Escenario';
    lblProyectoTipo.Caption := 'Tipo: ' + Tipo;
  end
  else
  begin
    lblProyectoNombre.Caption := 'Sin proyecto';
    lblProyectoTipo.Caption := 'Tipo: --';
  end;

  // Usuario
  S := CurrentSession;
  if S.UserId > 0 then
  begin
    if S.NombreCompleto <> '' then
      lblUsuarioNombre.Caption := S.NombreCompleto
    else
      lblUsuarioNombre.Caption := S.Login;
    lblUsuarioRol.Caption := 'Rol: ' + S.RoleNombre;
  end
  else
  begin
    lblUsuarioNombre.Caption := '--';
    lblUsuarioRol.Caption := 'Rol: --';
  end;
end;

procedure TfrmDashboard.RefrescarProyectoActivo;

  function FmtDate(const AV: Variant): string;
  begin
    if VarIsNull(AV) or VarIsEmpty(AV) then
      Result := '--'
    else
      Result := FormatDateTime('dd/mm/yyyy', TDateTime(AV));
  end;

  function FmtPct(ANum, ADen: Integer): string;
  var
    P: Double;
  begin
    if ADen <= 0 then Exit('(0%)');
    P := (ANum * 100.0) / ADen;
    Result := Format('(%.0f%%)', [P]);
  end;

  function FmtDuracion(AMinutos: Double): string;
  var
    H, M: Integer;
    Dias: Double;
  begin
    if AMinutos <= 0 then Exit('0 h');
    H := Trunc(AMinutos / 60);
    M := Round(AMinutos - H * 60);
    Dias := AMinutos / (60 * 24);
    if Dias >= 1 then
      Result := Format('%.1f días (%dh %dm)', [Dias, H mod 24, M])
    else
      Result := Format('%dh %dm', [H, M]);
  end;

var
  Q: TADOQuery;
  CE, PID: string;
  ProjectId: Integer;
  NodosPlan, NodosTotal: Integer;
  OFsPlan, OFsTotal: Integer;
  PedidosPlan, PedidosTotal: Integer;
  CentrosUsados, OpAsig, Dependencias, Marcadores: Integer;
  DuracionTotal: Double;
  FInicio, FFin: Variant;
begin
  ProjectId := DMPlanner.CurrentProjectId;
  if (ProjectId <= 0) or (not DMPlanner.IsConnected) then
  begin
    lblValFechaInicio.Caption := '--';
    lblValFechaFin.Caption := '--';
    lblValFechaBloqueo.Caption := '--';
    lblValNodos.Caption := '--';
    lblValOFs.Caption := '--';
    lblValPedidos.Caption := '--';
    lblValCentrosUsados.Caption := '--';
    lblValOperariosAsignados.Caption := '--';
    lblValDuracionTotal.Caption := '--';
    lblValDependencias.Caption := '--';
    lblValMarcadores.Caption := '--';
    Exit;
  end;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(ProjectId);

  // Nodos: planificados vs total, fechas min/max, duración
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ' +
      '  COUNT(*) AS Total, ' +
      '  SUM(CASE WHEN FechaInicio IS NOT NULL THEN 1 ELSE 0 END) AS Planificados, ' +
      '  MIN(FechaInicio) AS FInicio, ' +
      '  MAX(FechaFin) AS FFin, ' +
      '  ISNULL(SUM(CASE WHEN FechaInicio IS NOT NULL THEN DuracionMin ELSE 0 END), 0) AS DurTotal ' +
      'FROM FS_PL_Node ' +
      'WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID;
    Q.Open;
    NodosTotal := Q.FieldByName('Total').AsInteger;
    NodosPlan := Q.FieldByName('Planificados').AsInteger;
    FInicio := Q.FieldByName('FInicio').Value;
    FFin := Q.FieldByName('FFin').Value;
    DuracionTotal := Q.FieldByName('DurTotal').AsFloat;
  finally
    Q.Free;
  end;

  // OFs: distintos NumeroOF planificados vs totales
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ' +
      '  COUNT(DISTINCT nd.NumeroOF) AS Total, ' +
      '  COUNT(DISTINCT CASE WHEN n.FechaInicio IS NOT NULL THEN nd.NumeroOF END) AS Planificados ' +
      'FROM FS_PL_Node n ' +
      'INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = ' + CE + ' AND n.ProjectId = ' + PID +
      '  AND nd.NumeroOF IS NOT NULL';
    Q.Open;
    OFsTotal := Q.FieldByName('Total').AsInteger;
    OFsPlan := Q.FieldByName('Planificados').AsInteger;
  finally
    Q.Free;
  end;

  // Pedidos: distintos NumeroPedido planificados vs totales
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ' +
      '  COUNT(DISTINCT nd.NumeroPedido) AS Total, ' +
      '  COUNT(DISTINCT CASE WHEN n.FechaInicio IS NOT NULL THEN nd.NumeroPedido END) AS Planificados ' +
      'FROM FS_PL_Node n ' +
      'INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = ' + CE + ' AND n.ProjectId = ' + PID +
      '  AND nd.NumeroPedido IS NOT NULL';
    Q.Open;
    PedidosTotal := Q.FieldByName('Total').AsInteger;
    PedidosPlan := Q.FieldByName('Planificados').AsInteger;
  finally
    Q.Free;
  end;

  // Centros utilizados + operarios asignados + dependencias
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT ' +
      '  (SELECT COUNT(DISTINCT CenterId) FROM FS_PL_Node ' +
      '   WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID +
      '     AND CenterId IS NOT NULL AND FechaInicio IS NOT NULL) AS CentrosUsados, ' +
      '  (SELECT COUNT(DISTINCT oa.OperatorId) FROM FS_PL_OperatorAssignment oa ' +
      '   INNER JOIN FS_PL_Node n2 ON n2.CodigoEmpresa = oa.CodigoEmpresa AND n2.NodeId = oa.NodeId ' +
      '   WHERE n2.CodigoEmpresa = ' + CE + ' AND n2.ProjectId = ' + PID + ') AS OpAsig, ' +
      '  (SELECT COUNT(*) FROM FS_PL_Dependency ' +
      '   WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID + ') AS Deps, ' +
      '  (SELECT COUNT(*) FROM FS_PL_Marker ' +
      '   WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID + ') AS Marcadores';
    Q.Open;
    CentrosUsados := Q.FieldByName('CentrosUsados').AsInteger;
    OpAsig := Q.FieldByName('OpAsig').AsInteger;
    Dependencias := Q.FieldByName('Deps').AsInteger;
    Marcadores := Q.FieldByName('Marcadores').AsInteger;
  finally
    Q.Free;
  end;

  lblValFechaInicio.Caption := FmtDate(FInicio);
  lblValFechaFin.Caption := FmtDate(FFin);
  if DMPlanner.CurrentProjectTieneBloqueo then
    lblValFechaBloqueo.Caption := FormatDateTime('dd/mm/yyyy', DMPlanner.CurrentProjectFechaBloqueo)
  else
    lblValFechaBloqueo.Caption := '(sin bloqueo)';
  lblValNodos.Caption := Format('%d / %d  %s', [NodosPlan, NodosTotal, FmtPct(NodosPlan, NodosTotal)]);
  lblValOFs.Caption := Format('%d / %d  %s', [OFsPlan, OFsTotal, FmtPct(OFsPlan, OFsTotal)]);
  lblValPedidos.Caption := Format('%d / %d  %s', [PedidosPlan, PedidosTotal, FmtPct(PedidosPlan, PedidosTotal)]);
  lblValCentrosUsados.Caption := IntToStr(CentrosUsados);
  lblValOperariosAsignados.Caption := IntToStr(OpAsig);
  lblValDuracionTotal.Caption := FmtDuracion(DuracionTotal);
  lblValDependencias.Caption := IntToStr(Dependencias);
  lblValMarcadores.Caption := IntToStr(Marcadores);
end;

procedure TfrmDashboard.btnAbrirGanttClick(Sender: TObject);
begin
  if Assigned(FOnAbrirGantt) then
    FOnAbrirGantt(Self);
end;

procedure TfrmDashboard.lblValCalendariosClick(Sender: TObject);
begin
  TfrmGestionCalendarios.Execute(YearOf(Now));
  DMPlanner.LoadCalendars;
  Refrescar;
end;

procedure TfrmDashboard.lblValCentrosClick(Sender: TObject);
var
  Frm: TfrmGestionCentres;
begin
  Frm := TfrmGestionCentres.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  DMPlanner.LoadCentres;
  Refrescar;
end;

procedure TfrmDashboard.lblValAreasClick(Sender: TObject);
var
  Frm: TfrmGestionAreas;
begin
  Frm := TfrmGestionAreas.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  Refrescar;
end;

procedure TfrmDashboard.lblValDepartamentosClick(Sender: TObject);
var
  Frm: TfrmGestionDepartamentos;
begin
  Frm := TfrmGestionDepartamentos.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  Refrescar;
end;

procedure TfrmDashboard.lblValTurnosClick(Sender: TObject);
begin
  TfrmGestionTurnos.Execute;
  Refrescar;
end;

procedure TfrmDashboard.lblValCapacitacionesClick(Sender: TObject);
var
  Frm: TfrmGestionCapacitaciones;
begin
  Frm := TfrmGestionCapacitaciones.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  Refrescar;
end;

procedure TfrmDashboard.lblValOperariosClick(Sender: TObject);
var
  Frm: TfrmGestionOperaris;
begin
  Frm := TfrmGestionOperaris.Create(Self);
  try
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
  Refrescar;
end;

end.
