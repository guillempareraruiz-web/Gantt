unit uDemoBacklog;

{
  Generador de datos demo para el staging unificado FS_PL_Raw_Item (V016+).

  Crea arboles completos de 3 niveles para las 3 familias:
    - OF      (N1) -> OT    (N2) x k -> OP (N3) x m
    - PEDIDO  (N1) -> LINEA (N2) x k -> OP (N3) x m
    - PROYECTO(N1) -> TAREA (N2) x k -> OP (N3) x m

  Los nodos del Gantt solo lincan con items Nivel 3 (OP), coherente con el
  modelo: HorasEstimadas de Nivel 3 son las horas planificables.

  Se generan dependencias FS entre OPs hermanas del mismo padre en
  FS_PL_Raw_Item_Dep para simular secuencias realistas.

  Marca OrigenERP='DEMO' para poder limpiar selectivamente sin tocar datos
  de ERPs reales.
}

interface

procedure GenerarBacklogDemo; overload;
procedure GenerarBacklogDemo(ANumOFs, ANumCom, ANumPrj: Integer; AConfirmar: Boolean = True); overload;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.DateUtils,
  System.Math, System.StrUtils, System.UITypes,
  Vcl.Dialogs, Vcl.Controls,
  Data.Win.ADODB,
  uDMPlanner;

const
  CLIENTES: array[0..7] of string = (
    'Industrias Vila S.L.',
    'Metalurgica del Este',
    'Plasticos Rovira',
    'Aceros Puig',
    'Componentes Sol S.A.',
    'Talleres Marti',
    'Mecanica Pons',
    'Fabricats Moll'
  );

  COD_CLIENTES: array[0..7] of string = (
    'C001', 'C002', 'C003', 'C004', 'C005', 'C006', 'C007', 'C008'
  );

  ARTICULOS: array[0..9] of string = (
    'Pieza torneada 40mm', 'Carcasa aluminio', 'Soporte galvanizado',
    'Bastidor soldado', 'Cubierta plastica', 'Eje mecanizado',
    'Brida reforzada', 'Tapa fundicion', 'Perfil extruido',
    'Conjunto ensamblado'
  );

  COD_ARTICULOS: array[0..9] of string = (
    'ART-TRN-40', 'ART-CAR-AL', 'ART-SOP-GV', 'ART-BST-SD',
    'ART-CUB-PL', 'ART-EJE-MC', 'ART-BRD-RF', 'ART-TAP-FN',
    'ART-PRF-EX', 'ART-CNJ-EN'
  );

  ESTADOS: array[0..3] of string = ('LANZADA', 'CONFIRMADA', 'EN_COLA', 'URGENTE');

  OPERACIONES: array[0..9] of string = (
    'CORTAR', 'PULIR', 'MONTAR', 'PINTAR', 'LACAR',
    'EMBALAR', 'BRONCEAR', 'TALADRAR', 'SOLDAR', 'MECANIZAR'
  );

  TAREAS_PROYECTO: array[0..7] of string = (
    'Diseno', 'Compra materiales', 'Fabricacion prototipo',
    'Validacion cliente', 'Fabricacion serie', 'Control calidad',
    'Embalaje final', 'Entrega'
  );

function QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function QStrOrNull(const S: string): string;
begin
  if S = '' then Result := 'NULL' else Result := QStr(S);
end;

function FmtDT(const T: TDateTime): string;
begin
  Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', T) + '''';
end;

function FmtNum(const V: Double): string;
begin
  Result := StringReplace(FloatToStr(V), ',', '.', [rfReplaceAll]);
end;

// ---------------------------------------------------------------------------
// Limpieza de datos demo previos: Raw_Item (via cascade de Extra/Dep) + las
// 3 tablas legacy (los triggers de V016 mantienen Raw_Item sincronizado pero
// aqui borramos ambas para quedar en un estado limpio).
// ---------------------------------------------------------------------------
procedure LimpiarDemo(AConn: TADOConnection; const ACE: string);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;

    // Raw_Item: DELETE hojas primero (por el self-FK ParentRawItemId),
    // aunque el orden importe solo si los triggers de legacy ya hubieran
    // creado cabeceras. Hacemos 3 pases por Nivel descendente para satisfacer
    // el FK sin DISABLE TRIGGER.
    Cmd.CommandText :=
      'DELETE FROM FS_PL_Raw_Item_Dep WHERE CodigoEmpresa = ' + ACE +
      ' AND (FromRawItemId IN (SELECT RawItemId FROM FS_PL_Raw_Item ' +
      '      WHERE CodigoEmpresa = ' + ACE + ' AND OrigenERP = ''DEMO'')' +
      ' OR ToRawItemId IN (SELECT RawItemId FROM FS_PL_Raw_Item ' +
      '      WHERE CodigoEmpresa = ' + ACE + ' AND OrigenERP = ''DEMO''))';
    Cmd.Execute;

    Cmd.CommandText :=
      'DELETE FROM FS_PL_Raw_Item WHERE CodigoEmpresa = ' + ACE +
      ' AND OrigenERP = ''DEMO'' AND Nivel = 3';
    Cmd.Execute;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_Raw_Item WHERE CodigoEmpresa = ' + ACE +
      ' AND OrigenERP = ''DEMO'' AND Nivel = 2';
    Cmd.Execute;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_Raw_Item WHERE CodigoEmpresa = ' + ACE +
      ' AND OrigenERP = ''DEMO'' AND Nivel = 1';
    Cmd.Execute;

    // Legacy tables (los triggers actuaran pero Raw_Item ya esta vacio para DEMO)
    Cmd.CommandText :=
      'DELETE FROM FS_PL_Raw_OF WHERE CodigoEmpresa = ' + ACE +
      ' AND OrigenERP = ''DEMO''';
    Cmd.Execute;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_Raw_Comanda WHERE CodigoEmpresa = ' + ACE +
      ' AND OrigenERP = ''DEMO''';
    Cmd.Execute;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_Raw_Projecte WHERE CodigoEmpresa = ' + ACE +
      ' AND OrigenERP = ''DEMO''';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

function CentrosDisponibles(AConn: TADOConnection; const ACE: string): TArray<string>;
var
  Q: TADOQuery;
  L: TStringList;
begin
  L := TStringList.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT CodigoCentro FROM FS_PL_Center ' +
      'WHERE CodigoEmpresa = ' + ACE + ' AND Visible = 1 AND Habilitado = 1 ' +
      'ORDER BY CodigoCentro';
    Q.Open;
    while not Q.Eof do
    begin
      L.Add(Q.FieldByName('CodigoCentro').AsString);
      Q.Next;
    end;
    Result := L.ToStringArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Inserta una fila en Raw_Item y devuelve el RawItemId recien creado
// ---------------------------------------------------------------------------
function InsertarItem(AConn: TADOConnection; const ACE: string;
  const ATipoOrigen: string; ANivel: Integer; AParentId: Int64;
  const AClaveERP, AClaveERPPadre: string;
  ANumeroDoc: Integer; const ASerieDoc: string; ALineaDoc: Integer;
  const ACodigoProyecto, ACodigo, ANombre: string;
  const ACodigoArticulo, ADescArticulo: string;
  ACantidad: Double; const AUnidad: string;
  const ACodigoCliente, ANombreCliente: string;
  AFechaCompromiso, AFechaNecesaria, AFechaLanzamiento: TDateTime;
  APrioridad, AOrden: Integer;
  const ACentroPreferente: string;
  AHorasEstimadas: Double;
  const AEstado: string): Int64;
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  SQL: string;
  ParentSQL, CantSQL, HorasSQL, FCompSQL, FNecSQL, FLanzSQL: string;
begin
  if AParentId > 0 then ParentSQL := IntToStr(AParentId) else ParentSQL := 'NULL';
  if ALineaDoc > 0 then CantSQL := IntToStr(ALineaDoc) else CantSQL := 'NULL';
  if ACantidad > 0 then CantSQL := FmtNum(ACantidad) else CantSQL := 'NULL';
  if AHorasEstimadas > 0 then HorasSQL := FmtNum(AHorasEstimadas) else HorasSQL := 'NULL';
  if AFechaCompromiso > 0 then FCompSQL := FmtDT(AFechaCompromiso) else FCompSQL := 'NULL';
  if AFechaNecesaria > 0 then FNecSQL := FmtDT(AFechaNecesaria) else FNecSQL := 'NULL';
  if AFechaLanzamiento > 0 then FLanzSQL := FmtDT(AFechaLanzamiento) else FLanzSQL := 'NULL';

  SQL :=
    'INSERT INTO FS_PL_Raw_Item (CodigoEmpresa, TipoOrigen, Nivel, ParentRawItemId, ' +
    '  OrigenERP, ClaveERP, ClaveERPPadre, NumeroDoc, SerieDoc, LineaDoc, ' +
    '  CodigoProyecto, Codigo, Nombre, ' +
    '  CodigoArticulo, DescripcionArticulo, Cantidad, UnidadMedida, ' +
    '  CodigoCliente, NombreCliente, ' +
    '  FechaCompromiso, FechaNecesaria, FechaLanzamiento, ' +
    '  Prioridad, Orden, CentroPreferente, HorasEstimadas, EstadoERP) VALUES (' +
    ACE + ', ' + QStr(ATipoOrigen) + ', ' + IntToStr(ANivel) + ', ' + ParentSQL + ', ' +
    '''DEMO'', ' + QStr(AClaveERP) + ', ' + QStrOrNull(AClaveERPPadre) + ', ' +
    IfThen(ANumeroDoc > 0, IntToStr(ANumeroDoc), 'NULL') + ', ' +
    QStrOrNull(ASerieDoc) + ', ' +
    IfThen(ALineaDoc > 0, IntToStr(ALineaDoc), 'NULL') + ', ' +
    QStrOrNull(ACodigoProyecto) + ', ' +
    QStrOrNull(ACodigo) + ', ' +
    QStrOrNull(ANombre) + ', ' +
    QStrOrNull(ACodigoArticulo) + ', ' +
    QStrOrNull(ADescArticulo) + ', ' +
    CantSQL + ', ' +
    QStrOrNull(AUnidad) + ', ' +
    QStrOrNull(ACodigoCliente) + ', ' +
    QStrOrNull(ANombreCliente) + ', ' +
    FCompSQL + ', ' + FNecSQL + ', ' + FLanzSQL + ', ' +
    IfThen(APrioridad > 0, IntToStr(APrioridad), 'NULL') + ', ' +
    IfThen(AOrden > 0, IntToStr(AOrden), 'NULL') + ', ' +
    QStrOrNull(ACentroPreferente) + ', ' +
    HorasSQL + ', ' +
    QStrOrNull(AEstado) + ')';

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;
    Cmd.CommandText := SQL;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := 'SELECT SCOPE_IDENTITY() AS NewId';
    Q.Open;
    Result := Q.FieldByName('NewId').AsLargeInt;
  finally
    Q.Free;
  end;
end;

procedure InsertarDep(AConn: TADOConnection; const ACE: string;
  AFromId, AToId: Int64; APct: Integer);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_Raw_Item_Dep (CodigoEmpresa, FromRawItemId, ToRawItemId, ' +
      '  TipoLink, PorcentajeDependencia) VALUES (' +
      ACE + ', ' + IntToStr(AFromId) + ', ' + IntToStr(AToId) + ', 0, ' +
      IntToStr(APct) + ')';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Genera un arbol OF -> OTs -> OPs
// ---------------------------------------------------------------------------
procedure GenerarOF(AConn: TADOConnection; const ACE: string;
  AIdx: Integer; const ACentros: TArray<string>);
var
  ClienteIdx, ArtIdx, EstIdx: Integer;
  NumOFVal, NumOTs, NumOPs, iOT, iOP: Integer;
  Horas, HorasPorOP: Double;
  Cant: Double;
  FComp, FNec, FLanz: TDateTime;
  ClaveOF, ClaveOT, ClaveOP, SerieOF, CodArt, Centro: string;
  OFId, OTId, OPAnterior, OPId: Int64;
  Operacion: string;
begin
  ClienteIdx := Random(Length(CLIENTES));
  ArtIdx := Random(Length(ARTICULOS));
  EstIdx := Random(Length(ESTADOS));
  NumOFVal := 20000 + AIdx;
  SerieOF := 'A';
  CodArt := COD_ARTICULOS[ArtIdx];
  Cant := 50 + Random(1950);
  Horas := 2 + Random(80);
  FComp := IncDay(Date, 5 + Random(90));
  FNec  := IncDay(FComp, -2 - Random(5));
  FLanz := IncDay(Date, -Random(10));

  if Length(ACentros) > 0 then
    Centro := ACentros[Random(Length(ACentros))]
  else
    Centro := '';

  ClaveOF := Format('DEMO-OF-%.5d', [AIdx]);

  OFId := InsertarItem(AConn, ACE, 'OF ', 1, 0,
    ClaveOF, '',
    NumOFVal, SerieOF, 0,
    '', '', ARTICULOS[ArtIdx],
    CodArt, ARTICULOS[ArtIdx], Cant, 'UD',
    COD_CLIENTES[ClienteIdx], CLIENTES[ClienteIdx],
    FComp, FNec, FLanz,
    1 + Random(5), 0,
    Centro, Horas,
    ESTADOS[EstIdx]);

  NumOTs := 1 + Random(3);   // 1..3 OTs por OF
  for iOT := 1 to NumOTs do
  begin
    ClaveOT := Format('%s-OT%.2d', [ClaveOF, iOT]);
    OTId := InsertarItem(AConn, ACE, 'OF ', 2, OFId,
      ClaveOT, ClaveOF,
      NumOFVal, SerieOF, iOT,
      '', Format('OT-%d', [iOT]), ARTICULOS[ArtIdx],
      CodArt, ARTICULOS[ArtIdx], Cant / NumOTs, 'UD',
      COD_CLIENTES[ClienteIdx], CLIENTES[ClienteIdx],
      FComp, FNec, FLanz,
      0, iOT,
      Centro, Horas / NumOTs,
      ESTADOS[EstIdx]);

    NumOPs := 2 + Random(4);  // 2..5 OPs por OT
    HorasPorOP := (Horas / NumOTs) / NumOPs;
    OPAnterior := 0;
    for iOP := 1 to NumOPs do
    begin
      Operacion := OPERACIONES[Random(Length(OPERACIONES))];
      ClaveOP := Format('%s-OP%.2d', [ClaveOT, iOP]);
      if Length(ACentros) > 0 then
        Centro := ACentros[Random(Length(ACentros))];

      OPId := InsertarItem(AConn, ACE, 'OF ', 3, OTId,
        ClaveOP, ClaveOT,
        NumOFVal, SerieOF, iOP,
        '', Operacion, Operacion,
        '', '', 0, '',   // OPs no tienen articulo
        COD_CLIENTES[ClienteIdx], CLIENTES[ClienteIdx],
        FComp, FNec, 0,
        0, iOP,
        Centro, HorasPorOP,
        ESTADOS[EstIdx]);

      if OPAnterior > 0 then
        InsertarDep(AConn, ACE, OPAnterior, OPId, 100);
      OPAnterior := OPId;
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Genera un arbol PEDIDO -> LINEAs -> OPs
// ---------------------------------------------------------------------------
procedure GenerarPedido(AConn: TADOConnection; const ACE: string;
  AIdx: Integer; const ACentros: TArray<string>);
var
  ClienteIdx, EstIdx: Integer;
  NumPed, NumLineas, NumOPs, iLin, iOP: Integer;
  Horas, HorasPorOP: Double;
  Cant: Double;
  FComp, FPed: TDateTime;
  ClavePed, ClaveLin, ClaveOP, SeriePed, Centro: string;
  ArtIdx: Integer;
  PedId, LinId, OPAnterior, OPId: Int64;
  Operacion: string;
begin
  ClienteIdx := Random(Length(CLIENTES));
  EstIdx := Random(Length(ESTADOS));
  NumPed := 30000 + AIdx;
  SeriePed := 'V';
  FComp := IncDay(Date, 10 + Random(60));
  FPed  := IncDay(Date, -Random(20));

  if Length(ACentros) > 0 then
    Centro := ACentros[Random(Length(ACentros))]
  else
    Centro := '';

  ClavePed := Format('DEMO-PED-%.5d', [AIdx]);

  PedId := InsertarItem(AConn, ACE, 'PED', 1, 0,
    ClavePed, '',
    NumPed, SeriePed, 0,
    '', '', 'Pedido comercial ' + IntToStr(AIdx),
    '', '', 0, '',
    COD_CLIENTES[ClienteIdx], CLIENTES[ClienteIdx],
    FComp, 0, 0,
    1 + Random(5), 0,
    Centro, 0,
    ESTADOS[EstIdx]);

  NumLineas := 1 + Random(4);  // 1..4 lineas por pedido
  for iLin := 1 to NumLineas do
  begin
    ArtIdx := Random(Length(ARTICULOS));
    Cant := 10 + Random(500);
    Horas := 1 + Random(40);
    ClaveLin := Format('%s-L%.2d', [ClavePed, iLin]);

    LinId := InsertarItem(AConn, ACE, 'PED', 2, PedId,
      ClaveLin, ClavePed,
      NumPed, SeriePed, iLin,
      '', Format('Linea %d', [iLin]), ARTICULOS[ArtIdx],
      COD_ARTICULOS[ArtIdx], ARTICULOS[ArtIdx], Cant, 'UD',
      COD_CLIENTES[ClienteIdx], CLIENTES[ClienteIdx],
      FComp, 0, 0,
      0, iLin,
      Centro, Horas,
      ESTADOS[EstIdx]);

    NumOPs := 1 + Random(4);  // 1..4 OPs por linea
    HorasPorOP := Horas / NumOPs;
    OPAnterior := 0;
    for iOP := 1 to NumOPs do
    begin
      Operacion := OPERACIONES[Random(Length(OPERACIONES))];
      ClaveOP := Format('%s-OP%.2d', [ClaveLin, iOP]);
      if Length(ACentros) > 0 then
        Centro := ACentros[Random(Length(ACentros))];

      OPId := InsertarItem(AConn, ACE, 'PED', 3, LinId,
        ClaveOP, ClaveLin,
        NumPed, SeriePed, iOP,
        '', Operacion, Operacion,
        '', '', 0, '',
        COD_CLIENTES[ClienteIdx], CLIENTES[ClienteIdx],
        FComp, 0, 0,
        0, iOP,
        Centro, HorasPorOP,
        ESTADOS[EstIdx]);

      if OPAnterior > 0 then
        InsertarDep(AConn, ACE, OPAnterior, OPId, 100);
      OPAnterior := OPId;
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Genera un arbol PROYECTO -> TAREAs -> OPs
// ---------------------------------------------------------------------------
procedure GenerarProyecto(AConn: TADOConnection; const ACE: string;
  AIdx: Integer; const ACentros: TArray<string>);
var
  ClienteIdx, EstIdx: Integer;
  NumTareas, NumOPs, iTar, iOP: Integer;
  Horas, HorasPorOP, HorasPorTarea: Double;
  FInicio, FComp: TDateTime;
  ClavePrj, ClaveTar, ClaveOP, CodPrj, Centro, NomTarea: string;
  PrjId, TarId, OPAnterior, OPId: Int64;
  Operacion: string;
begin
  ClienteIdx := Random(Length(CLIENTES));
  EstIdx := Random(Length(ESTADOS));
  Horas := 100 + Random(400);
  FInicio := IncDay(Date, -Random(30));
  FComp := IncDay(Date, 30 + Random(120));

  if Length(ACentros) > 0 then
    Centro := ACentros[Random(Length(ACentros))]
  else
    Centro := '';

  CodPrj := Format('DEMO-PRJ-%.3d', [AIdx]);
  ClavePrj := CodPrj;

  PrjId := InsertarItem(AConn, ACE, 'PRJ', 1, 0,
    ClavePrj, '',
    0, '', 0,
    CodPrj, CodPrj, 'Proyecto demo ' + IntToStr(AIdx),
    '', '', 0, '',
    COD_CLIENTES[ClienteIdx], CLIENTES[ClienteIdx],
    FComp, 0, FInicio,
    1 + Random(5), 0,
    Centro, Horas,
    ESTADOS[EstIdx]);

  NumTareas := 2 + Random(4);  // 2..5 tareas por proyecto
  HorasPorTarea := Horas / NumTareas;
  for iTar := 1 to NumTareas do
  begin
    NomTarea := TAREAS_PROYECTO[Random(Length(TAREAS_PROYECTO))];
    ClaveTar := Format('%s-T%.2d', [ClavePrj, iTar]);

    TarId := InsertarItem(AConn, ACE, 'PRJ', 2, PrjId,
      ClaveTar, ClavePrj,
      0, '', iTar,
      CodPrj, Format('T%.2d', [iTar]), NomTarea,
      '', '', 0, '',   // tareas pueden no tener articulo
      COD_CLIENTES[ClienteIdx], CLIENTES[ClienteIdx],
      FComp, 0, 0,
      0, iTar,
      Centro, HorasPorTarea,
      ESTADOS[EstIdx]);

    NumOPs := 1 + Random(3);  // 1..3 OPs por tarea
    HorasPorOP := HorasPorTarea / NumOPs;
    OPAnterior := 0;
    for iOP := 1 to NumOPs do
    begin
      Operacion := OPERACIONES[Random(Length(OPERACIONES))];
      ClaveOP := Format('%s-OP%.2d', [ClaveTar, iOP]);
      if Length(ACentros) > 0 then
        Centro := ACentros[Random(Length(ACentros))];

      OPId := InsertarItem(AConn, ACE, 'PRJ', 3, TarId,
        ClaveOP, ClaveTar,
        0, '', iOP,
        CodPrj, Operacion, Operacion,
        '', '', 0, '',
        COD_CLIENTES[ClienteIdx], CLIENTES[ClienteIdx],
        FComp, 0, 0,
        0, iOP,
        Centro, HorasPorOP,
        ESTADOS[EstIdx]);

      if OPAnterior > 0 then
        InsertarDep(AConn, ACE, OPAnterior, OPId, 100);
      OPAnterior := OPId;
    end;
  end;
end;

procedure GenerarBacklogDemo;
begin
  GenerarBacklogDemo(25, 12, 4, True);
end;

procedure GenerarBacklogDemo(ANumOFs, ANumCom, ANumPrj: Integer; AConfirmar: Boolean = True);
var
  AConn: TADOConnection;
  CE: string;
  Centros: TArray<string>;
  I, NumOFs, NumCom, NumPrj: Integer;
  TotalOFs, TotalPed, TotalPrj, TotalItems: Integer;
  Q: TADOQuery;
begin
  AConn := DMPlanner.ADOConnection;
  CE := IntToStr(DMPlanner.CodigoEmpresa);

  if AConfirmar then
  begin
    if MessageDlg(
         'Se generaran arboles demo en FS_PL_Raw_Item ' +
         '(OF>OT>OP, PEDIDO>LINEA>OP, PROYECTO>TAREA>OP; OrigenERP=DEMO).' + sLineBreak +
         'Se borraran los datos demo anteriores.' + sLineBreak + sLineBreak +
         'Continuar?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
  end;

  Centros := CentrosDisponibles(AConn, CE);

  NumOFs := Max(0, ANumOFs);
  NumCom := Max(0, ANumCom);
  NumPrj := Max(0, ANumPrj);

  AConn.BeginTrans;
  try
    LimpiarDemo(AConn, CE);

    Randomize;
    TotalOFs := 0; TotalPed := 0; TotalPrj := 0;
    for I := 1 to NumOFs do
    begin
      GenerarOF(AConn, CE, I, Centros);
      Inc(TotalOFs);
    end;
    for I := 1 to NumCom do
    begin
      GenerarPedido(AConn, CE, I, Centros);
      Inc(TotalPed);
    end;
    for I := 1 to NumPrj do
    begin
      GenerarProyecto(AConn, CE, I, Centros);
      Inc(TotalPrj);
    end;

    AConn.CommitTrans;
  except
    AConn.RollbackTrans;
    raise;
  end;

  // Conteo total para el mensaje
  TotalItems := 0;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := 'SELECT COUNT(*) AS N FROM FS_PL_Raw_Item ' +
                  'WHERE CodigoEmpresa = ' + CE + ' AND OrigenERP = ''DEMO''';
    Q.Open;
    TotalItems := Q.FieldByName('N').AsInteger;
  finally
    Q.Free;
  end;

  if AConfirmar then
    ShowMessage(Format(
      'Backlog demo generado:' + sLineBreak +
      '  %d OFs (con OTs y OPs)' + sLineBreak +
      '  %d Pedidos (con Lineas y OPs)' + sLineBreak +
      '  %d Proyectos (con Tareas y OPs)' + sLineBreak +
      '  %d items totales en Raw_Item',
      [TotalOFs, TotalPed, TotalPrj, TotalItems]));
end;

end.
