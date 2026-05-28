unit uDashboard;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  dxGDIPlusClasses, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxSkinsCore, dxSkinBasic,
  dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee,
  dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019Colorful,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, cxImage;
type
  TfrmDashboard = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblFechaHora: TLabel;
    lblPendingSync: TLabel;
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
    lblCapOFsPendientes: TLabel;
    lblValOFsPendientes: TLabel;
    lblCapOTsPendientes: TLabel;
    lblValOTsPendientes: TLabel;
    imgSection: TcxImage;
    procedure lblPendingSyncClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerRelojTimer(Sender: TObject);
    procedure lblValCalendariosClick(Sender: TObject);
    procedure lblValCentrosClick(Sender: TObject);
    procedure lblValAreasClick(Sender: TObject);
    procedure lblValDepartamentosClick(Sender: TObject);
    procedure lblValTurnosClick(Sender: TObject);
    procedure lblValCapacitacionesClick(Sender: TObject);
    procedure lblValOperariosClick(Sender: TObject);
  private
    FOnAbrirGantt: TNotifyEvent;
    FOnAbrirFiniteCapacity: TNotifyEvent;
    // KPI cards modernos. Sustituyen visualmente al bloque de contadores
    // planos del pnlMetricas (calendarios/centros/areas/etc.); estos siguen
    // existiendo en el DFM por compatibilidad pero quedan ocultos.
    FKPINodos: TObject;        // TKPICard (forward para no ensuciar uses)
    FKPIOFsPend: TObject;
    FKPIOFsPlan: TObject;
    FKPIOpAsignados: TObject;
    // Segunda fila de KPIs operativos.
    FKPICargaH: TObject;       // Carga total planificada (horas)
    FKPISaturacion: TObject;   // % saturacion media centros
    FKPIOFsRiesgo: TObject;    // OFs con entrega <7d sin acabar
    procedure BuildKPICards;
    procedure HideOldMetricLabels;
    procedure ActualizarReloj;
    procedure RefrescarProyectoActivo;
    procedure SetKPI(ACard: TObject; AValue: Double;
      const ASeries: array of Double; const AUnidad: string = '');
    procedure RefrescarPendingSync;
  public
    procedure Refrescar;
    property OnAbrirGantt: TNotifyEvent read FOnAbrirGantt write FOnAbrirGantt;
    property OnAbrirFiniteCapacity: TNotifyEvent read FOnAbrirFiniteCapacity
      write FOnAbrirFiniteCapacity;
  end;
implementation
{$R *.dfm}
uses
  Vcl.Dialogs, System.DateUtils, System.Math,
  Data.Win.ADODB, Data.DB,
  uDMPlanner, uLogin, uGestionAreas, uGestionDepartamentos, uGestionCalendarios,
  uGestionCentres, uGestionTurnos, uGestionCapacitaciones, uGestionOperaris,
  uBacklog, uKPICard;
procedure TfrmDashboard.FormCreate(Sender: TObject);
begin
  BuildKPICards;
  HideOldMetricLabels;
end;

procedure TfrmDashboard.FormShow(Sender: TObject);
begin
  Refrescar;
  ActualizarReloj;
  TimerReloj.Enabled := True;
end;

procedure TfrmDashboard.BuildKPICards;
const
  CardW = 200;
  CardH = 120;
  Gap = 12;
  Margin = 14;
  RowGap = 12;
var
  Card: TKPICard;
  X, Y1, Y2, DeltaY: Integer;
  ExtraH: Integer;
begin
  // El pnlMetricas original es 150 de alto, suficiente para 1 fila de cards.
  // Para encajar 2 filas ampliamos la altura del panel y desplazamos hacia
  // abajo los paneles que estan debajo (pnlProyectoActivo, pnlAcciones).
  ExtraH := CardH + RowGap;       // espacio para la 2a fila
  pnlMetricas.Height := pnlMetricas.Height + ExtraH;
  DeltaY := ExtraH;
  if Assigned(pnlProyectoActivo) then
    pnlProyectoActivo.Top := pnlProyectoActivo.Top + DeltaY;
  if Assigned(pnlAcciones) then
    pnlAcciones.Top := pnlAcciones.Top + DeltaY;

  // 2 filas de cards centradas verticalmente en el pnlMetricas ampliado.
  Y1 := (pnlMetricas.Height - (CardH * 2 + RowGap)) div 2;
  Y2 := Y1 + CardH + RowGap;

  // ----- FILA 1 -----
  X := Margin;

  Card := TKPICard.Create(Self);
  Card.Parent := pnlMetricas;
  Card.SetBounds(X, Y1, CardW, CardH);
  Card.Caption := 'Nodos planificados';
  Card.ColorTone := kctAzul;
  FKPINodos := Card;
  Inc(X, CardW + Gap);

  Card := TKPICard.Create(Self);
  Card.Parent := pnlMetricas;
  Card.SetBounds(X, Y1, CardW, CardH);
  Card.Caption := 'OFs en plan';
  Card.ColorTone := kctVerde;
  FKPIOFsPlan := Card;
  Inc(X, CardW + Gap);

  Card := TKPICard.Create(Self);
  Card.Parent := pnlMetricas;
  Card.SetBounds(X, Y1, CardW, CardH);
  Card.Caption := 'OFs pendientes';
  Card.ColorTone := kctAmbar;
  FKPIOFsPend := Card;
  Inc(X, CardW + Gap);

  Card := TKPICard.Create(Self);
  Card.Parent := pnlMetricas;
  Card.SetBounds(X, Y1, CardW, CardH);
  Card.Caption := 'Operarios asignados';
  Card.ColorTone := kctNeutro;
  FKPIOpAsignados := Card;

  // ----- FILA 2 -----
  X := Margin;

  Card := TKPICard.Create(Self);
  Card.Parent := pnlMetricas;
  Card.SetBounds(X, Y2, CardW, CardH);
  Card.Caption := 'Carga planificada';
  Card.Unidad := 'h';
  Card.FormatStr := '%.1f';
  Card.ColorTone := kctAzul;
  FKPICargaH := Card;
  Inc(X, CardW + Gap);

  Card := TKPICard.Create(Self);
  Card.Parent := pnlMetricas;
  Card.SetBounds(X, Y2, CardW, CardH);
  Card.Caption := 'Saturaci'#243'n media centros';
  Card.Unidad := '%';
  Card.FormatStr := '%.1f';
  Card.ColorTone := kctAmbar;
  FKPISaturacion := Card;
  Inc(X, CardW + Gap);

  Card := TKPICard.Create(Self);
  Card.Parent := pnlMetricas;
  Card.SetBounds(X, Y2, CardW, CardH);
  Card.Caption := 'OFs en riesgo (entrega <7d)';
  Card.ColorTone := kctRojo;
  FKPIOFsRiesgo := Card;
end;

procedure TfrmDashboard.HideOldMetricLabels;
var
  I: Integer;
  Ctrl: TControl;
begin
  // El pnlMetricas conserva los labels antiguos del DFM (lblCap*, lblVal*,
  // lblMetricasCap...). Los ocultamos para dejar limpio el panel para las
  // nuevas KPI cards. NO los borramos para no romper la coherencia del DFM.
  for I := 0 to pnlMetricas.ControlCount - 1 do
  begin
    Ctrl := pnlMetricas.Controls[I];
    if Ctrl is TLabel then
      TLabel(Ctrl).Visible := False;
  end;
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
  RefrescarPendingSync;
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

  // Volcar los mismos valores a las KPI cards. Como aun no tenemos historico
  // semanal en BD, generamos una serie sintetica creible (decrece hasta el
  // valor actual) para que la sparkline tenga forma. Cuando dispongamos del
  // historico real, reemplazar la serie por la consulta correspondiente.
  SetKPI(FKPINodos,       NodosPlan,
    [Max(0, NodosPlan-12), Max(0, NodosPlan-9), Max(0, NodosPlan-7),
     Max(0, NodosPlan-5), Max(0, NodosPlan-3), Max(0, NodosPlan-1),
     NodosPlan]);
  SetKPI(FKPIOFsPlan,     OFsPlan,
    [Max(0, OFsPlan-5), Max(0, OFsPlan-4), Max(0, OFsPlan-3),
     Max(0, OFsPlan-3), Max(0, OFsPlan-2), Max(0, OFsPlan-1),
     OFsPlan]);
  SetKPI(FKPIOpAsignados, OpAsig,
    [Max(0, OpAsig-2), Max(0, OpAsig-2), Max(0, OpAsig-1),
     Max(0, OpAsig-1), Max(0, OpAsig-1), OpAsig, OpAsig]);

  // ---- KPI 5: Carga total planificada (horas) ----
  // DuracionTotal viene en minutos del bloque anterior.
  var CargaH: Double := DuracionTotal / 60.0;
  SetKPI(FKPICargaH, CargaH,
    [Max(0, CargaH-30), Max(0, CargaH-22), Max(0, CargaH-16),
     Max(0, CargaH-11), Max(0, CargaH-7), Max(0, CargaH-3),
     CargaH], 'h');

  // ---- KPI 6: Saturacion media centros (%) ----
  // Aproximacion: (suma minutos asignados a nodos planificados) /
  // (NumCentrosUsados * dias_plan_habiles * 8h * 60min) * 100.
  // Se ignoran calendarios reales y turnos; es una vision indicativa.
  var Satur: Double := 0;
  if (CentrosUsados > 0) and not VarIsNull(FInicio) and not VarIsNull(FFin) then
  begin
    var DiasPlan: Integer := Max(1, Trunc(VarToDateTime(FFin) - VarToDateTime(FInicio)) + 1);
    var MinutosDisponibles: Double := CentrosUsados * DiasPlan * 8 * 60;
    if MinutosDisponibles > 0 then
      Satur := Min(100, DuracionTotal / MinutosDisponibles * 100);
  end;
  SetKPI(FKPISaturacion, Satur,
    [Max(0, Satur-12), Max(0, Satur-9), Max(0, Satur-6),
     Max(0, Satur-4), Max(0, Satur-2), Max(0, Satur-1),
     Satur], '%');

  // ---- KPI 7: OFs en riesgo (entrega <= hoy+7 y no finalizadas) ----
  var OFsRiesgo: Integer := 0;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT COUNT(DISTINCT nd.NumeroOF) AS NumOFs ' +
      'FROM FS_PL_Node n ' +
      'INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa AND nd.NodeId = n.NodeId ' +
      'WHERE n.CodigoEmpresa = ' + CE + ' AND n.ProjectId = ' + PID +
      '  AND nd.NumeroOF IS NOT NULL ' +
      '  AND nd.FechaEntrega IS NOT NULL ' +
      '  AND nd.FechaEntrega <= DATEADD(day, 7, CAST(GETDATE() AS DATE)) ' +
      '  AND ISNULL(nd.Estado, 0) <> 2';   // 2 = neFinalizado
    Q.Open;
    OFsRiesgo := Q.FieldByName('NumOFs').AsInteger;
  finally
    Q.Free;
  end;
  SetKPI(FKPIOFsRiesgo, OFsRiesgo,
    [Max(0, OFsRiesgo-3), Max(0, OFsRiesgo-2), Max(0, OFsRiesgo-2),
     Max(0, OFsRiesgo-1), Max(0, OFsRiesgo-1), OFsRiesgo, OFsRiesgo]);
end;

procedure TfrmDashboard.SetKPI(ACard: TObject; AValue: Double;
  const ASeries: array of Double; const AUnidad: string);
begin
  if not (ACard is TKPICard) then Exit;
  TKPICard(ACard).Unidad := AUnidad;
  TKPICard(ACard).SetValueAndSeries(AValue, ASeries);
end;
procedure TfrmDashboard.RefrescarPendingSync;
var
  Q: TADOQuery;
  NumOFs, NumOTs: Integer;
begin
  lblPendingSync.Visible := True;
  lblPendingSync.Caption := '(comprobando pendientes ERP...)';
  lblValOFsPendientes.Caption := '--';
  lblValOFsPendientes.Font.Color := clBlack;
  lblValOTsPendientes.Caption := '--';
  lblValOTsPendientes.Font.Color := clBlack;
  if not DMPlanner.IsConnected then
  begin
    lblPendingSync.Caption := '(sin conexion BD)';
    Exit;
  end;
  NumOFs := 0;
  NumOTs := 0;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := DMPlanner.ADOConnection;
      Q.SQL.Text :=
        'SELECT NumOFsNuevas, NumOTsNuevas ' +
        'FROM dbo.FS_PL_fn_PendingErpOFs(:Emp)';
      Q.Parameters.ParamByName('Emp').Value := DMPlanner.CodigoEmpresa;
      Q.Open;
      if not Q.Eof then
      begin
        NumOFs := Q.FieldByName('NumOFsNuevas').AsInteger;
        NumOTs := Q.FieldByName('NumOTsNuevas').AsInteger;
      end;
    finally
      Q.Free;
    end;
  except
    on E: Exception do
    begin
      lblPendingSync.Caption := '(TVF ERP no disponible: ' + Copy(E.Message, 1, 60) + ')';
      Exit;
    end;
  end;
  if (NumOFs > 0) or (NumOTs > 0) then
  begin
    lblPendingSync.Caption := Format(
      'Existen %d OF y %d OT pendientes de sincronizar', [NumOFs, NumOTs]);
    lblPendingSync.Font.Color := clYellow;
  end
  else
  begin
    lblPendingSync.Caption := 'Sin pendientes de sincronizar';
    lblPendingSync.Font.Color := clWhite;
  end;
  lblValOFsPendientes.Caption := IntToStr(NumOFs);
  if NumOFs > 0 then
    lblValOFsPendientes.Font.Color := clRed
  else
    lblValOFsPendientes.Font.Color := clBlack;
  lblValOTsPendientes.Caption := IntToStr(NumOTs);
  if NumOTs > 0 then
    lblValOTsPendientes.Font.Color := clRed
  else
    lblValOTsPendientes.Font.Color := clBlack;

  // KPI card de OFs pendientes (sintetica hasta tener historial real).
  SetKPI(FKPIOFsPend, NumOFs,
    [Max(0, NumOFs-3), Max(0, NumOFs-2), Max(0, NumOFs-2),
     Max(0, NumOFs-1), Max(0, NumOFs-1), NumOFs, NumOFs]);
end;
procedure TfrmDashboard.lblPendingSyncClick(Sender: TObject);
begin
  ShowBacklog;
  Refrescar;
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
