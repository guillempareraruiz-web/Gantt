unit uGenerarNodosDemo;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.DateUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit,
  cxCalendar, cxContainer, cxDropDownEdit,
  Data.Win.ADODB, Data.DB, dxSkinsCore, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
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
  dxSkinXmas2008Blue, Vcl.ComCtrls, dxCore, cxDateUtils,
  System.Generics.Collections, uCentreCalendar, uGanttTypes, uBacklogScheduler,
  uDemoPlanEngine;

type
  // Ocupacion local por lane de un centro, para el reencadenado de dependencias
  // colision-aware (no duplicamos la maquinaria interna del motor, pero si su
  // idea: buscar el primer hueco libre en algun lane a partir de un instante).
  TDemoSlot = record
    Ini, Fin: TDateTime;
    NodeId: Int64;
  end;
  TDemoLane = TList<TDemoSlot>;

  // Ocupacion de un centro: sus lanes + calendario. Es TObject para poder
  // guardarlo en un TObjectDictionary que lo libere (con sus lanes) al destruir.
  TCentroOcc = class
    Lanes: TArray<TDemoLane>;
    Cal: TCentreCalendar;   // referencia compartida (de CentresRepo), NO liberar
    destructor Destroy; override;
  end;

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
    lblSeccionRecursos: TLabel;
    chkIncluirOperarios: TCheckBox;
    chkIncluirMoldes: TCheckBox;
    lblSeccionOpciones: TLabel;
    chkLimpiarExistentes: TCheckBox;
    chkGenerarDependencias: TCheckBox;
    Label1: TLabel;
    spPctSinCentro: TcxSpinEdit;
    chkGenerarOptimizadosRandom: TCheckBox;
    chkGenerarFabricacionRandom: TCheckBox;
    lblSeccionMotor: TLabel;
    pnlMotor: TPanel;
    rbMotorClasico: TRadioButton;
    rbMotorPRO: TRadioButton;
    rbMotorPRO3: TRadioButton;
    rbMotorPRO4: TRadioButton;
    rbMotorPRO5: TRadioButton;
    procedure FormCreate(Sender: TObject);
    procedure btnGenerarClick(Sender: TObject);
    procedure EstructuraChange(Sender: TObject);
  private
    FCenterIds: TArray<Integer>;      // centros REALES (excluye __SINCENTRO__)
    FSinCentroId: Integer;            // CenterId del centro de sistema SIN CENTRO
    FOperatorIds: TArray<Integer>;
    FMoldIds: TArray<Integer>;
    FSilent: Boolean;    // ExecuteSilent: no mostrar dialogos informativos
    // Contadores del ultimo Generar, para el mensaje-resumen tras el busy.
    FLastTotalNodos, FLastTotalMotor, FLastTotalDeps, FLastTotalSinCentro: Integer;
    // --- Reencadenado colision-aware (auxiliares de PlanificarConMotor) -------
    // FOccByCenter: CenterId -> TCentroOcc (lanes ocupados). FCentroCache:
    // CenterId -> TCentreTreball. Vivos solo durante PlanificarConMotor.
    FOccByCenter: TObjectDictionary<Integer, TCentroOcc>;
    FCentroCache: TDictionary<Integer, TCentreTreball>;

    function MontarParamsPRO: TDemoGenParams;   // params para el motor PRO (M2)
    procedure LoadRecursos;
    function Generar: Integer;   // devuelve operaciones planificadas por el motor
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
    // Post-generacion: pasa TODOS los nodos del proyecto por el motor real
    // (RunAutoScheduling: colisiones/lanes/calendario) + reencadena las
    // dependencias FS, y escribe FechaInicio/FechaFin/CenterId en FS_PL_Node.
    // Devuelve el numero de operaciones que el motor pudo planificar.
    function PlanificarConMotor(const AConn: TADOConnection;
      const ACE, APID: string): Integer;

    function OccCentroDe(ACenterId: Integer): TCentroOcc;
    function OccLaneChoca(ALane: TDemoLane; const AIni, AFin: TDateTime): Boolean;
    procedure OccReconstruir(const ARes: TSchedResult;
      AIni, AFin: TDictionary<Int64, TDateTime>);
    procedure OccQuitar(ACenterId: Integer; ANodeId: Int64);
    procedure OccBuscarHueco(ACenterId: Integer; const ADesde: TDateTime;
      ADur: Double; out AIni, AFin: TDateTime);
    procedure OccColocar(ACenterId: Integer; ANodeId: Int64;
      const AIni, AFin: TDateTime);
    procedure OccVerificarSolapamientos;
  private
    FProjectId: Integer;   // proyecto destino (demo). <=0 -> CurrentProjectId
    function TargetProjectId: Integer;
  public
    // AProjectId: proyecto destino. Pasar el proyecto demo (GetOrCreateDemoProjectId)
    // para el modo demo del Gantt; 0 o negativo usa CurrentProjectId (legacy).
    class function Execute(AProjectId: Integer = 0): Boolean;
    // Genera con valores por defecto SIN mostrar el dialogo (entrada rapida al
    // modo demo). Devuelve el numero de operaciones planificadas por el motor.
    class function ExecuteSilent(AProjectId, ANumOFs, AOpsPorOT: Integer): Integer;
  end;

implementation

{$R *.dfm}

uses
  System.StrUtils,
  uDMPlanner, uBusyDialog, uPlanLog,
  uCentresRepo;

const
  OPERACIONES: array[0..9] of string = (
    'CORTAR', 'PULIR', 'MONTAR', 'PINTAR', 'LACAR',
    'EMBALAR', 'BRONCEAR', 'TALADRAR', 'SOLDAR', 'MECANIZAR'
  );
  DEMO_ARTS: array[0..7] of string = (
    'ART-1001', 'ART-1002', 'ART-2050', 'ART-2051',
    'ART-3100', 'ART-3101', 'ART-4200', 'ART-4201'
  );
  DEMO_DESCS: array[0..7] of string = (
    'Pieza A grande', 'Pieza A peque'#241'a', 'Pieza B chasis',
    'Pieza B soporte', 'Caja electronica', 'Caja sensores',
    'Conjunto C ensamblado', 'Conjunto C revision'
  );
  DEMO_CLIENTES: array[0..4] of string = (
    'CLI-001', 'CLI-002', 'CLI-003', 'CLI-004', 'CLI-005'
  );

class function TfrmGenerarNodosDemo.Execute(AProjectId: Integer): Boolean;
var
  F: TfrmGenerarNodosDemo;
begin
  F := TfrmGenerarNodosDemo.Create(Application);
  try
    F.FProjectId := AProjectId;
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

function TfrmGenerarNodosDemo.TargetProjectId: Integer;
begin
  if FProjectId > 0 then
    Result := FProjectId
  else
    Result := DMPlanner.CurrentProjectId;
end;

procedure TfrmGenerarNodosDemo.FormCreate(Sender: TObject);
begin
  if FProjectId > 0 then
    lblSubtitle.Caption :=
      'Empresa: ' + DMPlanner.CurrentEmpresaNombre +
      '   |   Proyecto DEMO (a'#237'slado de tus datos reales)'
  else
    lblSubtitle.Caption :=
      'Empresa: ' + DMPlanner.CurrentEmpresaNombre +
      '   |   Proyecto: ' + DMPlanner.CurrentProjectName;

  // Pre-seleccionar estructura de empresa
  rbSimple.Checked := DMPlanner.EstructuraNodos = enSimple;
  rbCompleja.Checked := DMPlanner.EstructuraNodos = enCompleja;

  // Pre-seleccionar recursos de empresa
  chkIncluirOperarios.Checked := DMPlanner.PlanificaOperarios;
  chkIncluirMoldes.Checked := DMPlanner.PlanificaMoldes;

  // Inicio de planificacion por defecto: hoy. El motor calcula el fin.
  dtFechaInicio.Date := Trunc(Now);

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

  // Centros REALES (excluye el centro de sistema __SINCENTRO__, que se asigna
  // aparte segun spPctSinCentro). Guardamos su CenterId en FSinCentroId.
  SetLength(FCenterIds, 0);
  FSinCentroId := 0;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text := 'SELECT CenterId, CodigoCentro FROM FS_PL_Center WHERE CodigoEmpresa = ' +
      CE + ' AND Visible = 1 AND Habilitado = 1 ORDER BY CenterId';
    Q.Open;
    I := 0;
    while not Q.Eof do
    begin
      if SameText(Q.FieldByName('CodigoCentro').AsString, CENTRO_SIN_CENTRO) then
        FSinCentroId := Q.FieldByName('CenterId').AsInteger
      else
      begin
        SetLength(FCenterIds, I + 1);
        FCenterIds[I] := Q.FieldByName('CenterId').AsInteger;
        Inc(I);
      end;
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

  // Duracion REAL vs ORIGINAL (3 estados de optimizacion) si se pide. La barra
  // del Gantt usa DuracionMin (real); DuracionMinOriginal es el teorico:
  //   ~35% OPTIMIZADO (real 70-90% orig) / ~35% igual / ~30% NO optimizado
  //   (real 115-140% orig). Si no se pide: real = original. Se calcula ANTES del
  //   INSERT de FS_PL_Node para que ese nodo lleve ya la duracion real (aunque
  //   el motor la recalcula/recoloca despues, mantenemos coherencia).
  var DurOriginal: Double := ADuracionMin;
  var DurReal: Double := ADuracionMin;
  if chkGenerarOptimizadosRandom.Checked then
  begin
    var KOpt: Integer := Random(100);
    if KOpt < 35 then
      DurReal := DurOriginal * (0.70 + Random(21) / 100.0)
    else if KOpt < 70 then
      DurReal := DurOriginal
    else
      DurReal := DurOriginal * (1.15 + Random(26) / 100.0);
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_Node (CodigoEmpresa, ProjectId, CenterId, ' +
      '  FechaInicio, FechaFin, DuracionMin, Caption, ColorFondo, ColorBorde) VALUES (' +
      ACE + ', ' + APID + ', ' + CenterSQL + ', ' +
      FechaIniSQL + ', ' + FechaFinSQL + ', ' +
      FloatToStr(DurReal, TFormatSettings.Invariant) + ', ' +
      QStr(AOperacion) + ', 15251072, 11166760)';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // Obtener el ID recién insertado
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := AConn;
    // SCOPE_IDENTITY(): el IDENTITY de ESTA sesion (misma AConn que el INSERT).
    // NO usar MAX(NodeId): leeria la fila de otro usuario concurrente y el
    // NodeData se enganchaba al nodo equivocado.
    Q.SQL.Text := 'SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewId';
    Q.Open;
    NodeId := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;

  // NodeData - poblamos campos adicionales para que el motor de scoring
  // y la vista 'Operarios' del Gantt tengan datos realistas:
  //   Prioridad (1..5), FechaEntrega/FechaNecesaria, CodigoArticulo,
  //   DescripcionArticulo, CodigoCliente, OperariosNecesarios.
  var Prio: Integer := 1 + Random(5);
  var DiasACompromiso: Integer := 5 + Random(60);
  var FechaEntregaCalc: TDateTime := Date + DiasACompromiso;
  var FechaNecCalc: TDateTime := FechaEntregaCalc - 2 - Random(5);
  var FechaEntSQL: string := FmtDT(FechaEntregaCalc);
  var FechaNecSQL: string := FmtDT(FechaNecCalc);
  var ArtIdx: Integer := Random(Length(DEMO_ARTS));
  var CliIdx: Integer := Random(Length(DEMO_CLIENTES));
  var NumOpsNec: Integer := 1 + Random(3);
  var UnidTotal: Integer := 100 + Random(900);

  // Unidades ya fabricadas (avance) si se pide: ~40% 0% / ~50% parcial / ~10%
  // completo. Si no se pide: 0 (sin empezar).
  var UnidHechas: Integer := 0;
  if chkGenerarFabricacionRandom.Checked then
  begin
    var KFab: Integer := Random(10);
    if KFab < 4 then      UnidHechas := 0
    else if KFab < 9 then UnidHechas := Random(UnidTotal)
    else                  UnidHechas := UnidTotal;
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, ' +
      '  NumeroOF, NumeroPedido, NumeroTrabajo, DuracionMin, DuracionMinOriginal, ' +
      '  UnidadesAFabricar, UnidadesFabricadas, OperariosNecesarios, ' +
      '  ColorFondoOp, ColorBordeOp, Prioridad, FechaEntrega, FechaNecesaria, ' +
      '  CodigoArticulo, DescripcionArticulo, CodigoCliente) VALUES (' +
      ACE + ', ' + IntToStr(NodeId) + ', ' + QStr(AOperacion) + ', ' +
      IntToStr(ANumOF) + ', ' + IntToStr(ANumPedido) + ', ' +
      QStr(IntToStr(ANumTrabajo)) + ', ' +
      FloatToStr(DurReal, TFormatSettings.Invariant) + ', ' +
      FloatToStr(DurOriginal, TFormatSettings.Invariant) + ', ' +
      IntToStr(UnidTotal) + ', ' + IntToStr(UnidHechas) + ', ' +
      IntToStr(NumOpsNec) + ', 15251072, 11166760, ' +
      IntToStr(Prio) + ', ' + FechaEntSQL + ', ' + FechaNecSQL + ', ' +
      QStr(DEMO_ARTS[ArtIdx]) + ', ' +
      QStr(DEMO_DESCS[ArtIdx]) + ', ' +
      QStr(DEMO_CLIENTES[CliIdx]) + ')';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // Asignar operario aleatorio a las operaciones planificables (con centro),
  // haya o no fecha aun: el motor las colocara despues.
  if (ACenterId > 0) and chkIncluirOperarios.Checked and (Length(FOperatorIds) > 0) then
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
          FloatToStr(ADuracionMin / 60, TFormatSettings.Invariant) + ')';
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

function TfrmGenerarNodosDemo.PlanificarConMotor(const AConn: TADOConnection;
  const ACE, APID: string): Integer;
var
  Q: TADOQuery;
  Cmd: TADOCommand;
  Inputs: TArray<TSchedInput>;
  LInputs: TList<TSchedInput>;
  Inp: TSchedInput;
  Params: TSchedParams;
  Res: TSchedResult;
  OutItem: TSchedOutput;
  I, J, Iter: Integer;
  // Estado por NodeId tras el scheduling, para el reencadenado de dependencias.
  IniById: TDictionary<Int64, TDateTime>;
  FinById: TDictionary<Int64, TDateTime>;
  CenterById: TDictionary<Int64, Integer>;
  DurById: TDictionary<Int64, Double>;
  Deps: TList<TPair<Int64, Int64>>;   // (FromNodeId -> ToNodeId)
  Cambio: Boolean;
  FromN, ToN: Int64;
  FinFrom, IniTo, NuevoIni, NuevoFin: TDateTime;
  Dur: Double;
  CenterTo: Integer;
  ProyectoPrevio: Integer;

  function FmtDT(const T: TDateTime): string;
  begin
    Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', T) + '''';
  end;

begin
  Result := 0;

  // 1) Leer las operaciones del proyecto como TSchedInput. Se apoya en la vista
  //    NodeData (duracion, prioridad, fechas de compromiso, OF, articulo...) y
  //    en el centro preferente ya escrito en FS_PL_Node.
  LInputs := TList<TSchedInput>.Create;
  IniById := TDictionary<Int64, TDateTime>.Create;
  FinById := TDictionary<Int64, TDateTime>.Create;
  CenterById := TDictionary<Int64, Integer>.Create;
  DurById := TDictionary<Int64, Double>.Create;
  Deps := TList<TPair<Int64, Int64>>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text :=
        'SELECT n.NodeId, n.CenterId, c.CodigoCentro AS CentroCode, ' +
        '  d.DuracionMin, d.Prioridad, d.NumeroOF, d.FechaEntrega, d.FechaNecesaria, ' +
        '  d.CodigoArticulo, d.DescripcionArticulo ' +
        'FROM FS_PL_Node n ' +
        'LEFT JOIN FS_PL_NodeData d ON d.CodigoEmpresa = n.CodigoEmpresa AND d.NodeId = n.NodeId ' +
        'LEFT JOIN FS_PL_Center c ON c.CodigoEmpresa = n.CodigoEmpresa AND c.CenterId = n.CenterId ' +
        'WHERE n.CodigoEmpresa = ' + ACE + ' AND n.ProjectId = ' + APID;
      Q.Open;
      while not Q.Eof do
      begin
        Inp := Default(TSchedInput);
        Inp.RawId := Q.FieldByName('NodeId').AsLargeInt;
        Inp.CentroPreferente := Q.FieldByName('CentroCode').AsString;
        Inp.HorasEstimadas := Q.FieldByName('DuracionMin').AsFloat / 60.0;
        Inp.Prioridad := Q.FieldByName('Prioridad').AsInteger;
        Inp.NumeroOF := Q.FieldByName('NumeroOF').AsInteger;
        Inp.FechaEntrega := Q.FieldByName('FechaEntrega').AsDateTime;
        Inp.FechaNecesaria := Q.FieldByName('FechaNecesaria').AsDateTime;
        if Inp.FechaNecesaria <> 0 then
          Inp.FechaCompromiso := Inp.FechaNecesaria
        else
          Inp.FechaCompromiso := Inp.FechaEntrega;
        Inp.CodigoArticulo := Q.FieldByName('CodigoArticulo').AsString;
        Inp.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
        LInputs.Add(Inp);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Inputs := LInputs.ToArray;

    if Length(Inputs) = 0 then Exit;

    // Dependencias FS del proyecto (para el reencadenado post-scheduling).
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text :=
        'SELECT FromNodeId, ToNodeId FROM FS_PL_Dependency ' +
        'WHERE CodigoEmpresa = ' + ACE + ' AND ProjectId = ' + APID;
      Q.Open;
      while not Q.Eof do
      begin
        Deps.Add(TPair<Int64, Int64>.Create(
          Q.FieldByName('FromNodeId').AsLargeInt,
          Q.FieldByName('ToNodeId').AsLargeInt));
        Q.Next;
      end;
    finally
      Q.Free;
    end;

    // 2) Ejecutar el motor: Forward, orden por fecha de compromiso, rellenando
    //    huecos. Colisiones/lanes/calendario los resuelve RunAutoScheduling.
    //    IMPORTANTE: RunAutoScheduling->LoadExistingOccupancy lee la ocupacion
    //    del proyecto ACTIVO (CurrentProjectId). Fijamos temporalmente el
    //    proyecto destino (demo) como activo para que el motor solo considere la
    //    ocupacion de ESTE proyecto, no la del real. SetCurrentProject solo hace
    //    un SELECT y asigna campos (no repinta), asi que es barato y seguro.
    Params := Default(TSchedParams);
    Params.Mode := smForward;
    Params.Order := soFechaCompromiso;
    // Inicio de planificacion elegido en el dialogo. RunAutoScheduling normaliza:
    // si es hoy o anterior usa Now(); si es futura, arranca a las 00:00 de ese dia.
    Params.FechaBase := Trunc(dtFechaInicio.Date);
    Params.Placement := ppHueco;
    Params.HuecoMinimoMin := 30;
    Params.PorcentajeMinNodo := 50;

    PlanLog.Linea('--- SCHEDULING: %d inputs, %d dependencias, FechaBase=%s ---',
      [Length(Inputs), Deps.Count, FormatDateTime('yyyy-mm-dd', Params.FechaBase)]);

    if (FProjectId > 0) and (DMPlanner.CurrentProjectId <> FProjectId) then
    begin
      ProyectoPrevio := DMPlanner.CurrentProjectId;
      DMPlanner.SetCurrentProject(FProjectId);
      try
        Res := RunAutoScheduling(Inputs, Params);
      finally
        DMPlanner.SetCurrentProject(ProyectoPrevio);
      end;
    end
    else
      Res := RunAutoScheduling(Inputs, Params);

    PlanLog.Linea('    motor: %d items, %d planificados, %d no-planif, %d saturados',
      [Length(Res.Items), Res.TotalPlanificados, Res.TotalNoPlanificados,
       Res.TotalSaturados]);

    // Volcar el resultado a los diccionarios por NodeId.
    for I := 0 to High(Res.Items) do
    begin
      OutItem := Res.Items[I];
      if OutItem.Status = ssSinCentro then Continue;   // pendiente: no se toca
      IniById.AddOrSetValue(OutItem.Input.RawId, OutItem.FechaInicio);
      FinById.AddOrSetValue(OutItem.Input.RawId, OutItem.FechaFin);
      CenterById.AddOrSetValue(OutItem.Input.RawId, OutItem.CenterId);
      DurById.AddOrSetValue(OutItem.Input.RawId, OutItem.DuracionMin);
    end;

    // 3) Reencadenar dependencias FS colision-aware. El motor coloco cada OP en
    //    su centro sin conocer las dependencias, asi que un successor puede
    //    empezar antes de que acabe su predecessor. Al desplazarlo NO lo dejamos
    //    caer ciegamente sobre FinFrom (eso causaba solapamientos): reconstruimos
    //    la ocupacion por centro/lane y buscamos el primer hueco libre >= FinFrom.
    FOccByCenter := TObjectDictionary<Integer, TCentroOcc>.Create([doOwnsValues]);
    FCentroCache := TDictionary<Integer, TCentreTreball>.Create;
    try
      OccReconstruir(Res, IniById, FinById);
      PlanLog.Linea('--- REENCADENADO dependencias (colision-aware) ---');
      for Iter := 1 to 40 do
      begin
        Cambio := False;
        for J := 0 to Deps.Count - 1 do
        begin
          FromN := Deps[J].Key;
          ToN := Deps[J].Value;
          if not FinById.TryGetValue(FromN, FinFrom) then Continue;
          if not IniById.TryGetValue(ToN, IniTo) then Continue;
          if IniTo >= FinFrom - OneSecond then Continue;   // ya cumple FS (tolerancia)

          Dur := 0; CenterTo := 0;
          DurById.TryGetValue(ToN, Dur);
          CenterById.TryGetValue(ToN, CenterTo);

          // Sacar el successor de su hueco actual, buscar el primer hueco libre
          // en su centro a partir de FinFrom, y recolocarlo alli.
          OccQuitar(CenterTo, ToN);
          OccBuscarHueco(CenterTo, FinFrom, Dur, NuevoIni, NuevoFin);
          OccColocar(CenterTo, ToN, NuevoIni, NuevoFin);

          IniById.AddOrSetValue(ToN, NuevoIni);
          FinById.AddOrSetValue(ToN, NuevoFin);
          Cambio := True;
        end;
        if not Cambio then
        begin
          PlanLog.Linea('    convergido en %d iteraciones', [Iter]);
          Break;
        end;
        if Iter = 40 then
          PlanLog.Linea('    AVISO: no converge en 40 iteraciones (posibles ciclos)');
      end;

      // Verificacion final: contar solapamientos reales por centro/lane y volcar
      // al log los primeros para diagnostico.
      OccVerificarSolapamientos;
    finally
      FCentroCache.Free;
      FOccByCenter.Free;   // doOwnsValues libera cada TCentroOcc (y sus lanes)
    end;

    // 4) Escribir fechas + centro en FS_PL_Node (solo los planificados).
    AConn.BeginTrans;
    try
      Cmd := TADOCommand.Create(nil);
      try
        Cmd.Connection := AConn;
        for Inp in Inputs do
        begin
          if not IniById.TryGetValue(Inp.RawId, NuevoIni) then Continue;
          NuevoFin := 0; CenterTo := 0;
          FinById.TryGetValue(Inp.RawId, NuevoFin);
          CenterById.TryGetValue(Inp.RawId, CenterTo);
          Cmd.CommandText :=
            'UPDATE FS_PL_Node SET FechaInicio = ' + FmtDT(NuevoIni) +
            ', FechaFin = ' + FmtDT(NuevoFin) +
            ', CenterId = ' + IntToStr(CenterTo) +
            ' WHERE CodigoEmpresa = ' + ACE +
            ' AND NodeId = ' + IntToStr(Inp.RawId);
          Cmd.Execute;
          Inc(Result);
        end;
      finally
        Cmd.Free;
      end;
      AConn.CommitTrans;
    except
      AConn.RollbackTrans;
      raise;
    end;
  finally
    Deps.Free;
    DurById.Free;
    CenterById.Free;
    FinById.Free;
    IniById.Free;
    LInputs.Free;
  end;
end;

destructor TCentroOcc.Destroy;
var L: Integer;
begin
  for L := 0 to High(Lanes) do
    Lanes[L].Free;   // Cal es referencia compartida: NO liberar
  inherited;
end;

function TfrmGenerarNodosDemo.OccCentroDe(ACenterId: Integer): TCentroOcc;
var
  C, Cx: TCentreTreball;
  L: Integer;

  // Replica de GetLanes (uBacklogScheduler, no expuesto en interface): numero
  // de lanes del centro. Secuencial -> 1; sin limite -> 1; si no, MaxLaneCount.
  function LanesDe(const AC: TCentreTreball): Integer;
  begin
    if AC.IsSequencial then Exit(1);
    if AC.MaxLaneCount <= 0 then Exit(1);
    Result := AC.MaxLaneCount;
  end;

begin
  if FOccByCenter.TryGetValue(ACenterId, Result) then Exit;

  // Resolver el centro (cacheado) para saber lanes y secuencialidad.
  if not FCentroCache.TryGetValue(ACenterId, C) then
  begin
    C := Default(TCentreTreball);
    if Assigned(DMPlanner.CentresRepo) then
      for Cx in DMPlanner.CentresRepo.GetAll do
        if Cx.Id = ACenterId then begin C := Cx; Break; end;
    FCentroCache.AddOrSetValue(ACenterId, C);
  end;

  Result := TCentroOcc.Create;
  Result.Cal := nil;
  if (ACenterId > 0) and Assigned(DMPlanner.CentresRepo) then
    Result.Cal := DMPlanner.CentresRepo.GetCalendarFor(ACenterId);
  SetLength(Result.Lanes, Max(1, LanesDe(C)));
  for L := 0 to High(Result.Lanes) do
    Result.Lanes[L] := TDemoLane.Create;
  FOccByCenter.AddOrSetValue(ACenterId, Result);
end;

function TfrmGenerarNodosDemo.OccLaneChoca(ALane: TDemoLane;
  const AIni, AFin: TDateTime): Boolean;
var S: TDemoSlot;
begin
  Result := False;
  for S in ALane do
    if (AFin > S.Ini) and (AIni < S.Fin) then Exit(True);
end;

procedure TfrmGenerarNodosDemo.OccReconstruir(const ARes: TSchedResult;
  AIni, AFin: TDictionary<Int64, TDateTime>);
var
  K, L: Integer;
  O: TSchedOutput;
  H: TCentroOcc;
  Slot: TDemoSlot;
  Colocado: Boolean;
  Ini, Fin: TDateTime;
begin
  for K := 0 to High(ARes.Items) do
  begin
    O := ARes.Items[K];
    if O.Status = ssSinCentro then Continue;
    if not AIni.TryGetValue(O.Input.RawId, Ini) then Continue;
    if not AFin.TryGetValue(O.Input.RawId, Fin) then Continue;
    H := OccCentroDe(O.CenterId);
    Slot.Ini := Ini; Slot.Fin := Fin; Slot.NodeId := O.Input.RawId;
    // first-fit: primer lane donde no choque (igual que el motor).
    Colocado := False;
    for L := 0 to High(H.Lanes) do
      if not OccLaneChoca(H.Lanes[L], Ini, Fin) then
      begin
        H.Lanes[L].Add(Slot); Colocado := True; Break;
      end;
    if not Colocado then
      H.Lanes[0].Add(Slot);
  end;
end;

procedure TfrmGenerarNodosDemo.OccQuitar(ACenterId: Integer; ANodeId: Int64);
var H: TCentroOcc; L, I2: Integer;
begin
  if not FOccByCenter.ContainsKey(ACenterId) then Exit;
  H := OccCentroDe(ACenterId);
  for L := 0 to High(H.Lanes) do
    for I2 := H.Lanes[L].Count - 1 downto 0 do
      if H.Lanes[L][I2].NodeId = ANodeId then
        H.Lanes[L].Delete(I2);
end;

procedure TfrmGenerarNodosDemo.OccBuscarHueco(ACenterId: Integer;
  const ADesde: TDateTime; ADur: Double; out AIni, AFin: TDateTime);
var
  H: TCentroOcc;
  Cand, CandFin, ProxLibre: TDateTime;
  L, Intentos: Integer;
  Cabe: Boolean;
  S: TDemoSlot;
begin
  H := OccCentroDe(ACenterId);
  if H.Cal <> nil then Cand := H.Cal.NextWorkingTime(ADesde)
  else Cand := ADesde;

  for Intentos := 0 to 5000 do
  begin
    if H.Cal <> nil then CandFin := H.Cal.AddWorkingMinutes(Cand, Round(ADur))
    else CandFin := Cand + ADur / (24 * 60);

    Cabe := False;
    for L := 0 to High(H.Lanes) do
      if not OccLaneChoca(H.Lanes[L], Cand, CandFin) then
      begin
        Cabe := True; Break;
      end;

    if Cabe then
    begin
      AIni := Cand; AFin := CandFin; Exit;
    end;

    // Avanzar al primer fin de slot solapante (proximo instante potencialmente libre).
    ProxLibre := 0;
    for L := 0 to High(H.Lanes) do
      for S in H.Lanes[L] do
        if (CandFin > S.Ini) and (Cand < S.Fin) then
          if (ProxLibre = 0) or (S.Fin < ProxLibre) then
            ProxLibre := S.Fin;
    if ProxLibre <= Cand then ProxLibre := Cand + OneMinute;
    if H.Cal <> nil then Cand := H.Cal.NextWorkingTime(ProxLibre)
    else Cand := ProxLibre;
  end;

  AIni := Cand;
  if H.Cal <> nil then AFin := H.Cal.AddWorkingMinutes(Cand, Round(ADur))
  else AFin := Cand + ADur / (24 * 60);
end;

procedure TfrmGenerarNodosDemo.OccColocar(ACenterId: Integer; ANodeId: Int64;
  const AIni, AFin: TDateTime);
var H: TCentroOcc; L: Integer; Slot: TDemoSlot;
begin
  H := OccCentroDe(ACenterId);
  Slot.Ini := AIni; Slot.Fin := AFin; Slot.NodeId := ANodeId;
  for L := 0 to High(H.Lanes) do
    if not OccLaneChoca(H.Lanes[L], AIni, AFin) then
    begin
      H.Lanes[L].Add(Slot); Exit;
    end;
  H.Lanes[0].Add(Slot);   // no deberia: OccBuscarHueco garantiza sitio
end;

procedure TfrmGenerarNodosDemo.OccVerificarSolapamientos;
var
  H: TCentroOcc;
  L, A, B, NSolap, NVolcados, Cid: Integer;
  S1, S2: TDemoSlot;
begin
  NSolap := 0; NVolcados := 0;
  for Cid in FOccByCenter.Keys do
  begin
    if not FOccByCenter.TryGetValue(Cid, H) then Continue;
    for L := 0 to High(H.Lanes) do
      for A := 0 to H.Lanes[L].Count - 1 do
        for B := A + 1 to H.Lanes[L].Count - 1 do
        begin
          S1 := H.Lanes[L][A]; S2 := H.Lanes[L][B];
          if (S1.Fin > S2.Ini) and (S1.Ini < S2.Fin) then
          begin
            Inc(NSolap);
            if NVolcados < 15 then
            begin
              PlanLog.Linea('    SOLAP centro=%d lane=%d: nodo %d [%s..%s] vs nodo %d [%s..%s]',
                [Cid, L, S1.NodeId,
                 FormatDateTime('mm-dd hh:nn', S1.Ini), FormatDateTime('mm-dd hh:nn', S1.Fin),
                 S2.NodeId,
                 FormatDateTime('mm-dd hh:nn', S2.Ini), FormatDateTime('mm-dd hh:nn', S2.Fin)]);
              Inc(NVolcados);
            end;
          end;
        end;
  end;
  if NSolap = 0 then
    PlanLog.Linea('--- VERIFICACION: 0 solapamientos. Plan limpio. ---')
  else
    PlanLog.Linea('--- VERIFICACION: %d SOLAPAMIENTOS detectados (ver arriba) ---', [NSolap]);
end;

function TfrmGenerarNodosDemo.Generar: Integer;
var
  AConn: TADOConnection;
  CE, PID: string;
  NumOFs, OTsPorOF, OpsPorOT, PctPlan, PctSinCentro: Integer;
  DuracionMin: Double;
  iOF, iOT, iOP, Dado: Integer;
  NumOF, NumPedido, NumTrabajo: Integer;
  Operacion: string;
  CenterId: Integer;
  TotalNodos, TotalDeps, TotalMotor, TotalSinCentro: Integer;
  NodeId: Integer;
  OTNodeIds: TArray<Integer>;
  K: Integer;
  GenerarDeps: Boolean;
begin
  Result := 0;
  if Length(FCenterIds) = 0 then
  begin
    if not FSilent then
      ShowMessage('No hay centros disponibles. Primero crea centros de trabajo.');
    Exit;
  end;

  CE := IntToStr(DMPlanner.CodigoEmpresa);
  PID := IntToStr(TargetProjectId);

  PlanLog.Inicio(Format('GENERAR NODOS DEMO  -  proyecto %s (silent=%s)',
    [PID, BoolToStr(FSilent, True)]));

  NumOFs := spNumOFs.Value;
  OTsPorOF := spOTsPorOF.Value;
  OpsPorOT := spOpsPorOT.Value;
  // Tres grupos de TODOS los nodos:
  //   PctSinCentro -> centro de sistema __SINCENTRO__ (el motor los apila alli).
  //   del resto, PctPlan -> centro real (el motor los planifica).
  //   los demas -> pendientes puros (sin centro, backlog que el motor no coloca).
  PctPlan := spPctPlanificados.Value;
  PctSinCentro := spPctSinCentro.Value;

  AConn := DMPlanner.ADOConnection;
  TotalNodos := 0;
  TotalDeps := 0;
  TotalMotor := 0;
  TotalSinCentro := 0;
  GenerarDeps := chkGenerarDependencias.Checked;

  // FASE 1: generar los nodos SIN fechas (FechaInicio/Fin = NULL). El motor los
  // colocara despues. A los que se dejan "pendientes" (segun PctPlan) se les
  // quita el centro para que el motor NO los planifique (quedan como backlog).
  AConn.BeginTrans;
  try
    // Regenerar: el proyecto demo se limpia siempre. En modo legacy (proyecto
    // real) se respeta el checkbox.
    if (FProjectId > 0) or chkLimpiarExistentes.Checked then
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
          DuracionMin := 30 + Random(240);  // 30 min a 4.5 h

          // Decision de centro en 3 grupos (ver arriba). Dado 0..99.
          Dado := Random(100);
          if (Dado < PctSinCentro) and (FSinCentroId > 0) then
          begin
            CenterId := FSinCentroId;   // __SINCENTRO__: el motor lo apila alli
            Inc(TotalSinCentro);
          end
          else if Random(100) < PctPlan then
            CenterId := RandomCenter    // centro real: el motor lo planifica
          else
            CenterId := -1;             // pendiente puro: sin centro (backlog)

          NodeId := InsertarNodoCompleto(AConn, CE, PID, CenterId, Operacion,
            0, 0, False,   // sin fechas: el motor las asigna
            NumOF, NumPedido, NumTrabajo, DuracionMin);

          SetLength(OTNodeIds, Length(OTNodeIds) + 1);
          OTNodeIds[High(OTNodeIds)] := NodeId;

          Inc(TotalNodos);
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

  PlanLog.Linea('--- FASE 1 (generacion) OK: %d operaciones, %d dependencias, ' +
    'estructura=%s, %d centros reales, %d operarios, %d en __SINCENTRO__ ' +
    '(opt=%s, fabr=%s) ---',
    [TotalNodos, TotalDeps,
     IfThen(rbCompleja.Checked, 'compleja', 'simple'),
     Length(FCenterIds), Length(FOperatorIds), TotalSinCentro,
     BoolToStr(chkGenerarOptimizadosRandom.Checked, True),
     BoolToStr(chkGenerarFabricacionRandom.Checked, True)]);

  // FASE 2: planificar con el motor real (colisiones/lanes/calendario) +
  // reencadenar dependencias FS, y escribir fechas/centro en FS_PL_Node.
  TotalMotor := PlanificarConMotor(AConn, CE, PID);
  Result := TotalMotor;

  PlanLog.Linea('--- FASE 2 (planificacion) OK: %d operaciones planificadas por el motor ---',
    [TotalMotor]);
  PlanLog.Linea('Log completo en: %s', [PlanLog.RutaLog]);
  PlanLog.Fin;

  // Guardar contadores para el mensaje-resumen (lo muestra el caller DESPUES de
  // cerrar el busy dialog; asi no aparece un popup encima del "Cargando...").
  FLastTotalNodos := TotalNodos;
  FLastTotalMotor := TotalMotor;
  FLastTotalDeps := TotalDeps;
  FLastTotalSinCentro := TotalSinCentro;
end;

function TfrmGenerarNodosDemo.MontarParamsPRO: TDemoGenParams;
begin
  Result := Default(TDemoGenParams);
  Result.CodigoEmpresa := DMPlanner.CodigoEmpresa;
  Result.ProjectId := TargetProjectId;
  Result.NumOFs := spNumOFs.Value;
  Result.OTsPorOF := spOTsPorOF.Value;
  Result.OpsPorOT := spOpsPorOT.Value;
  Result.PctPlanificados := spPctPlanificados.Value;
  Result.PctSinCentro := spPctSinCentro.Value;
  Result.FechaBase := Trunc(dtFechaInicio.Date);
  Result.IncluirOperarios := chkIncluirOperarios.Checked;
  Result.GenerarDependencias := chkGenerarDependencias.Checked;
  Result.OptimizadosRandom := chkGenerarOptimizadosRandom.Checked;
  Result.FabricacionRandom := chkGenerarFabricacionRandom.Checked;
  // El proyecto demo se limpia siempre; en legacy respeta el checkbox.
  Result.LimpiarAntes := (FProjectId > 0) or chkLimpiarExistentes.Checked;
  // Metodo de persistencia segun el radio (M5 bulk file por defecto).
  if rbMotorPRO.Checked then
    Result.PersistMethod := pmMultifila       // M2
  else if rbMotorPRO3.Checked then
    Result.PersistMethod := pmStaging         // M3
  else if rbMotorPRO4.Checked then
    Result.PersistMethod := pmBulkADO         // M4
  else
    Result.PersistMethod := pmBulkFile;       // M5 (default)
end;

procedure TfrmGenerarNodosDemo.btnGenerarClick(Sender: TObject);
var
  P: TDemoGenParams;
  R: TDemoGenResult;
  SMet: string;
begin
  try
    if not rbMotorClasico.Checked then
    begin
      // MOTOR PRO (M2..M5): todo en RAM + persistencia masiva, en un worker
      // thread (RunBusy) con conexion propia. La UI no se congela.
      P := MontarParamsPRO;
      R := Default(TDemoGenResult);
      uBusyDialog.RunBusy(Self, 'Generando y planificando (motor PRO)...',
        procedure
        begin
          R := EjecutarDemoPlanEngine(P);
        end);

      case P.PersistMethod of
        pmMultifila: SMet := 'PRO multifila M2';
        pmStaging:   SMet := 'PRO staging M3';
        pmBulkADO:   SMet := 'PRO bulk ADO M4';
      else           SMet := 'PRO bulk file M5';
      end;

      if R.TotalNodos > 0 then
        ShowMessage(Format(
          'Generaci'#243'n completada (%s):' + sLineBreak +
          '  %d operaciones creadas' + sLineBreak +
          '  %d planificadas (%d en "Sin centro")' + sLineBreak +
          '  %d pendientes sin planificar' + sLineBreak +
          '  %d dependencias' + sLineBreak +
          '  %d solapamientos' + sLineBreak + sLineBreak +
          'Tiempos: generar %d ms, planificar %d ms, guardar %d ms  (total %d ms)',
          [SMet,
           R.TotalNodos, R.TotalPlanificados, R.TotalSinCentro,
           R.TotalPendientes, R.TotalDependencias, R.TotalSolapamientos,
           R.MillisGenerar, R.MillisPlanificar, R.MillisPersistir, R.MillisTotal]));
    end
    else
    begin
      // MOTOR CLASICO (M1): flujo actual (planificacion + BD). ShowBusy sincrono
      // porque Generar usa la conexion compartida DMPlanner.ADOConnection.
      FLastTotalNodos := 0; FLastTotalMotor := 0; FLastTotalDeps := 0;
      FLastTotalSinCentro := 0;
      ShowBusy(Self, 'Generando y planificando nodos de demostraci'#243'n...',
        procedure
        begin
          Generar;
        end);

      if FLastTotalNodos > 0 then
        ShowMessage(Format(
          'Generaci'#243'n completada (motor cl'#225'sico):' + sLineBreak +
          '  %d operaciones creadas' + sLineBreak +
          '  %d planificadas por el motor' + sLineBreak +
          '  %d en centro "Sin centro"' + sLineBreak +
          '  %d pendientes sin planificar' + sLineBreak +
          '  %d dependencias',
          [FLastTotalNodos, FLastTotalMotor,
           FLastTotalSinCentro,
           FLastTotalNodos - FLastTotalMotor,
           FLastTotalDeps]));
    end;

    ModalResult := mrOk;
  except
    on E: Exception do
    begin
      ShowMessage('Error generando nodos: ' + E.Message);
      ModalResult := mrNone;
    end;
  end;
end;

class function TfrmGenerarNodosDemo.ExecuteSilent(
  AProjectId, ANumOFs, AOpsPorOT: Integer): Integer;
var
  P: TDemoGenParams;
  R: TDemoGenResult;
begin
  // Entrada rapida al modo demo (sin dialogo): usa directamente el motor PRO
  // con persistencia STAGING (M3, el mas rapido). El caller (AplicarModoDemoGantt
  // / RegenerarGanttDemo1Click) ya envuelve esta llamada en un ShowBusy, asi que
  // aqui NO abrimos otro busy; el motor corre sincrono con su propia conexion.
  P := Default(TDemoGenParams);
  P.CodigoEmpresa := DMPlanner.CodigoEmpresa;
  P.ProjectId := AProjectId;
  P.NumOFs := ANumOFs;
  P.OTsPorOF := 3;
  P.OpsPorOT := AOpsPorOT;
  P.PctPlanificados := 80;    // de los NO sin-centro, 80% planificable
  P.PctSinCentro := 10;       // ~10% al centro __SINCENTRO__
  P.FechaBase := Trunc(Now);
  P.IncluirOperarios := DMPlanner.PlanificaOperarios;
  P.GenerarDependencias := True;
  P.OptimizadosRandom := True;
  P.FabricacionRandom := True;
  P.LimpiarAntes := True;   // proyecto demo: siempre regenerar
  P.PersistMethod := pmBulkFile;   // M5 (el mas rapido)
  R := EjecutarDemoPlanEngine(P);
  Result := R.TotalPlanificados;
end;

end.
