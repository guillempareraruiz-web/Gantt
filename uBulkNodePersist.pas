unit uBulkNodePersist;

{
  Persistencia MASIVA de nodos nuevos (FS_PL_Node + FS_PL_NodeData) para el
  camino de creacion desde el Backlog (CommitScheduling).

  Sustituye el patron clasico M1 (por cada nodo: INSERT Node + SELECT MAX(NodeId)
  + INSERT NodeData = 3 round-trips) por persistencia en lote:

    M5 (bmBulkFile)  CSV a disco + BULK INSERT (streaming en el servidor) + volcado
                     set-based con IDENTITY_INSERT. La mas rapida (~8x sobre M1).
    M4 (bmBulkADO)   #temp via recordsets ADO batch (binario) + volcado set-based.
                     Fallback fiable cuando la cuenta de servicio SQL no puede leer
                     el TEMP (BULK INSERT falla).
    M1 (bmPerRow)    Camino clasico por fila. Fallback ultimo y camino preferente
                     para lotes pequenos (< UMBRAL_BULK filas), donde el overhead
                     de crear #temp no compensa.

  Diagnostico y racional completo en la memoria reference_bulk_persist_sqlserver:
  el cuello de botella al escribir muchas filas desde ADO NO es la BD sino el
  overhead POR FILA del provider OLE DB; solo BULK INSERT desde fichero lo rompe.

  El motor RESERVA el rango de NodeIds una sola vez (SELECT MAX+1) y los asigna en
  memoria (NodeId := Base + idx), por eso el volcado necesita IDENTITY_INSERT. Asi
  se eliminan los N SELECT MAX(NodeId) del camino M1 y se devuelven los NodeId
  asignados al llamante (los usa AplicarAgrupacion para crear lotes).

  El paralelo vivo de este patron es uDemoPlanEngine (modo demo). Aqui esta
  recortado a 2 tablas (Node + NodeData); alli ademas escribe asignaciones y
  dependencias. Se mantiene duplicado a proposito para no arriesgar el modo demo
  ya en produccion.
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.DateUtils,
  Data.Win.ADODB;

type
  // Metodo de persistencia. Orden = preferencia de fallback (bmBulkFile mas
  // rapido, bmPerRow mas seguro).
  TBulkNodeMethod = (bmBulkFile, bmBulkADO, bmPerRow);   // M5 / M4 / M1

  // Datos minimos para crear 1 nodo (fila de FS_PL_Node + FS_PL_NodeData). Son
  // exactamente los campos que ponia el bucle de CommitScheduling.
  TBulkNodeRow = record
    // --- FS_PL_Node ---
    CenterId: Integer;
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    DuracionMin: Double;
    Caption: string;
    // --- FS_PL_NodeData ---
    Operacion: string;
    NumeroOF: Integer;
    SerieOF: string;
    NumeroPedido: Integer;
    SeriePedido: string;
    NumeroTrabajo: string;
    FechaEntrega: TDateTime;    // 0 => NULL
    FechaNecesaria: TDateTime;  // 0 => NULL
    CodigoCliente: string;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    UnidadesAFabricar: Double;  // <= 0 => se guarda 1
    TiempoUnidadFabSecs: Double;
    Prioridad: Integer;
    RawItemClaveERP: string;    // '' => NULL
    RawItemTipoOrigen: string;  // '' => NULL
    // --- salida ---
    NodeId: Integer;            // asignado por el motor (0 a la entrada)
  end;

const
  // Colores por defecto (mismos que CommitScheduling / demo).
  COLOR_FONDO_DEF = 15251072;
  COLOR_BORDE_DEF = 11166760;
  // Separador de campos del CSV para BULK INSERT (M5). NO usar '|': los datos
  // ERP reales lo contienen (p.ej. RawItemClaveERP = 'OP|2024|793|5'), lo que
  // descoloca las columnas y hace fallar el BULK INSERT. Usamos el caracter de
  // control ASCII 31 (Unit Separator, US), disenado justamente para separar
  // campos de datos y que nunca aparece en texto. En SQL: FIELDTERMINATOR '0x1f'.
  SEP = #31;
  SEP_SQL = '0x1f';
  // Por debajo de este numero de filas no compensa montar #temp: se usa M1.
  UMBRAL_BULK = 200;
  // SQL Server admite hasta 1000 filas por INSERT ... VALUES.
  FILAS_POR_INSERT = 900;

// Inserta ARows en FS_PL_Node + FS_PL_NodeData. Asigna ARows[i].NodeId. Debe
// llamarse DENTRO de la transaccion del llamante (no abre/cierra la suya).
// APreferred es el metodo deseado (para comparativa M1/M4/M5 desde la UI); si
// falla, degrada al siguiente. Devuelve el metodo REALMENTE usado.
function BulkInsertNodes(AConn: TADOConnection;
  ACodigoEmpresa, AProjectId: Integer;
  var ARows: TArray<TBulkNodeRow>;
  APreferred: TBulkNodeMethod = bmBulkFile): TBulkNodeMethod;

function BulkNodeMethodName(AMethod: TBulkNodeMethod): string;

implementation

uses
  uPlanLog;

function BulkNodeMethodName(AMethod: TBulkNodeMethod): string;
begin
  case AMethod of
    bmBulkFile: Result := 'M5 bulk file';
    bmBulkADO:  Result := 'M4 bulk ADO';
  else          Result := 'M1 por fila';
  end;
end;

{ Helpers de formato compartidos }

function Inv: TFormatSettings;
begin
  Result := TFormatSettings.Invariant;
end;

// ISO 8601 con 'T': SQL lo interpreta igual sea cual sea el DATEFORMAT de la
// sesion (evita "fuera de intervalo" con configuracion regional dd/mm).
function DTf(const V: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', V, TFormatSettings.Invariant);
end;

function DTq(const V: TDateTime): string;
begin
  Result := QuotedStr(DTf(V));
end;

function QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function QStrOrNull(const S: string): string;
begin
  if S = '' then Result := 'NULL' else Result := QStr(S);
end;

// Unidades a fabricar efectivas (>=1, como en CommitScheduling).
function UdsEff(const R: TBulkNodeRow): Double;
begin
  if R.UnidadesAFabricar > 0 then Result := R.UnidadesAFabricar else Result := 1;
end;

// Saneado de un texto libre (ERP) para el CSV de M5: quita CR/LF (romperian el
// ROWTERMINATOR) y el propio separador SEP (por si acaso apareciera). El '|' ya
// no es separador, asi que se conserva tal cual en los datos.
function CsvSafe(const S: string): string;
begin
  Result := S;
  if Result = '' then Exit;
  Result := StringReplace(Result, #13, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, SEP, ' ', [rfReplaceAll]);
end;

{ --------------------------------------------------------------------------
  M1: camino clasico por fila. INSERT Node + SELECT MAX + INSERT NodeData.
  Es el que sustituimos, pero lo conservamos como fallback y para comparativa.
  -------------------------------------------------------------------------- }
procedure PersistPerRow(AConn: TADOConnection; ACE, APID: Integer;
  var ARows: TArray<TBulkNodeRow>);
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  I: Integer;
  R: TBulkNodeRow;
  CE, PID: string;

  function FEnt(const V: TDateTime): string;
  begin
    if V > 0 then Result := DTq(V) else Result := 'NULL';
  end;

begin
  CE := IntToStr(ACE);
  PID := IntToStr(APID);
  for I := 0 to High(ARows) do
  begin
    R := ARows[I];

    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := AConn;
      Cmd.CommandText :=
        'INSERT INTO FS_PL_Node (CodigoEmpresa, ProjectId, CenterId, ' +
        '  FechaInicio, FechaFin, DuracionMin, Caption, ColorFondo, ColorBorde) VALUES (' +
        CE + ', ' + PID + ', ' + IntToStr(R.CenterId) + ', ' +
        DTq(R.FechaInicio) + ', ' + DTq(R.FechaFin) + ', ' +
        FloatToStr(R.DuracionMin, Inv) + ', ' +
        QStr(R.Caption) + ', ' +
        IntToStr(COLOR_FONDO_DEF) + ', ' + IntToStr(COLOR_BORDE_DEF) + ')';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;

    Q := TADOQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text :=
        'SELECT MAX(NodeId) AS NewId FROM FS_PL_Node ' +
        'WHERE CodigoEmpresa = ' + CE + ' AND ProjectId = ' + PID;
      Q.Open;
      ARows[I].NodeId := Q.FieldByName('NewId').AsInteger;
      R.NodeId := ARows[I].NodeId;
    finally
      Q.Free;
    end;

    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := AConn;
      Cmd.CommandText :=
        'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, ' +
        '  NumeroOF, SerieOF, NumeroPedido, SeriePedido, NumeroTrabajo, ' +
        '  FechaEntrega, FechaNecesaria, CodigoCliente, ' +
        '  CodigoArticulo, DescripcionArticulo, ' +
        '  DuracionMin, DuracionMinOriginal, ' +
        '  UnidadesAFabricar, TiempoUnidadFabSecs, ' +
        '  OperariosNecesarios, Prioridad, ' +
        '  RawItemClaveERP, RawItemTipoOrigen, ' +
        '  ColorFondoOp, ColorBordeOp) VALUES (' +
        CE + ', ' + IntToStr(R.NodeId) + ', ' + QStr(R.Operacion) + ', ' +
        IntToStr(R.NumeroOF) + ', ' + QStr(R.SerieOF) + ', ' +
        IntToStr(R.NumeroPedido) + ', ' + QStr(R.SeriePedido) + ', ' +
        QStr(R.NumeroTrabajo) + ', ' +
        FEnt(R.FechaEntrega) + ', ' + FEnt(R.FechaNecesaria) + ', ' +
        QStr(R.CodigoCliente) + ', ' +
        QStr(R.CodigoArticulo) + ', ' + QStr(R.DescripcionArticulo) + ', ' +
        FloatToStr(R.DuracionMin, Inv) + ', ' + FloatToStr(R.DuracionMin, Inv) + ', ' +
        FloatToStr(UdsEff(R), Inv) + ', ' + FloatToStr(R.TiempoUnidadFabSecs, Inv) + ', ' +
        '1, ' + IntToStr(R.Prioridad) + ', ' +
        QStrOrNull(R.RawItemClaveERP) + ', ' + QStrOrNull(R.RawItemTipoOrigen) + ', ' +
        IntToStr(COLOR_FONDO_DEF) + ', ' + IntToStr(COLOR_BORDE_DEF) + ')';
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
  end;
end;

{ --------------------------------------------------------------------------
  Camino BULK (M5 / M4): reservar rango de NodeIds, crear #temp, llenar por el
  metodo elegido, y volcar set-based con IDENTITY_INSERT.
  -------------------------------------------------------------------------- }
procedure PersistBulk(AConn: TADOConnection; ACE, APID: Integer;
  var ARows: TArray<TBulkNodeRow>; AUseFile: Boolean);
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  BaseId, I: Integer;
  CE: string;

  procedure ExecNoRec(const ASql: string);
  begin
    // eoExecuteNoRecords + SET NOCOUNT ON: imprescindible al tocar #temp (si no:
    // "no se pudieron determinar los metadatos ... tabla temporal").
    Cmd.CommandText := 'SET NOCOUNT ON; ' + ASql;
    Cmd.ExecuteOptions := [eoExecuteNoRecords];
    Cmd.Execute;
  end;

  // M5: CSV a disco + BULK INSERT (streaming). Separador '|', CRLF, UTF-8,
  // NULLs = campo vacio (+ KEEPNULLS). Path legible por la cuenta de servicio SQL.
  procedure LlenarBulkFile;
  var
    Dir, FNode, FData: string;
    WNode, WData: TStreamWriter;
    K: Integer;
    R: TBulkNodeRow;
    Enc: TEncoding;

    procedure BulkInsert(const ATabla, AFich: string);
    begin
      ExecNoRec(Format(
        'BULK INSERT %s FROM %s WITH (FIELDTERMINATOR = ''%s'', ' +
        'ROWTERMINATOR = ''0x0d0a'', KEEPNULLS, TABLOCK, CODEPAGE = ''65001'');',
        [ATabla, QuotedStr(AFich), SEP_SQL]));
    end;

  begin
    Dir := TPath.GetTempPath;
    FNode := TPath.Combine(Dir, Format('fsbk_node_%d.csv', [APID]));
    FData := TPath.Combine(Dir, Format('fsbk_data_%d.csv', [APID]));

    // Enc = TEncoding.UTF8 (singleton RTL): NO liberar. El BOM lo salta el
    // CODEPAGE='65001' del BULK INSERT (SQL 2016+).
    Enc := TEncoding.UTF8;
    WNode := TStreamWriter.Create(FNode, False, Enc);
    WData := TStreamWriter.Create(FData, False, Enc);
    try
      WNode.NewLine := #13#10;
      WData.NewLine := #13#10;

      for K := 0 to High(ARows) do
      begin
        R := ARows[K];

        // #tmpNode: CodigoEmpresa|NodeId|ProjectId|CenterId|FechaInicio|FechaFin|
        //           DuracionMin|Caption|ColorFondo|ColorBorde
        WNode.Write(IntToStr(ACE)); WNode.Write(SEP);
        WNode.Write(IntToStr(R.NodeId)); WNode.Write(SEP);
        WNode.Write(IntToStr(APID)); WNode.Write(SEP);
        if R.CenterId > 0 then WNode.Write(IntToStr(R.CenterId));
        WNode.Write(SEP);
        if R.FechaInicio > 0 then WNode.Write(DTf(R.FechaInicio));
        WNode.Write(SEP);
        if R.FechaFin > 0 then WNode.Write(DTf(R.FechaFin));
        WNode.Write(SEP);
        WNode.Write(FloatToStr(R.DuracionMin, Inv)); WNode.Write(SEP);
        WNode.Write(CsvSafe(R.Caption)); WNode.Write(SEP);
        WNode.Write(IntToStr(COLOR_FONDO_DEF)); WNode.Write(SEP);
        WNode.Write(IntToStr(COLOR_BORDE_DEF));
        WNode.WriteLine;

        // #tmpData: CodigoEmpresa|NodeId|Operacion|NumeroOF|SerieOF|NumeroPedido|
        //   SeriePedido|NumeroTrabajo|FechaEntrega|FechaNecesaria|CodigoCliente|
        //   CodigoArticulo|DescripcionArticulo|DuracionMin|DuracionMinOriginal|
        //   UnidadesAFabricar|TiempoUnidadFabSecs|OperariosNecesarios|Prioridad|
        //   RawItemClaveERP|RawItemTipoOrigen|ColorFondoOp|ColorBordeOp
        WData.Write(IntToStr(ACE)); WData.Write(SEP);
        WData.Write(IntToStr(R.NodeId)); WData.Write(SEP);
        WData.Write(CsvSafe(R.Operacion)); WData.Write(SEP);
        WData.Write(IntToStr(R.NumeroOF)); WData.Write(SEP);
        WData.Write(CsvSafe(R.SerieOF)); WData.Write(SEP);
        WData.Write(IntToStr(R.NumeroPedido)); WData.Write(SEP);
        WData.Write(CsvSafe(R.SeriePedido)); WData.Write(SEP);
        WData.Write(CsvSafe(R.NumeroTrabajo)); WData.Write(SEP);
        if R.FechaEntrega > 0 then WData.Write(DTf(R.FechaEntrega));
        WData.Write(SEP);
        if R.FechaNecesaria > 0 then WData.Write(DTf(R.FechaNecesaria));
        WData.Write(SEP);
        WData.Write(CsvSafe(R.CodigoCliente)); WData.Write(SEP);
        WData.Write(CsvSafe(R.CodigoArticulo)); WData.Write(SEP);
        WData.Write(CsvSafe(R.DescripcionArticulo)); WData.Write(SEP);
        WData.Write(FloatToStr(R.DuracionMin, Inv)); WData.Write(SEP);
        WData.Write(FloatToStr(R.DuracionMin, Inv)); WData.Write(SEP);
        WData.Write(FloatToStr(UdsEff(R), Inv)); WData.Write(SEP);
        WData.Write(FloatToStr(R.TiempoUnidadFabSecs, Inv)); WData.Write(SEP);
        WData.Write('1'); WData.Write(SEP);
        WData.Write(IntToStr(R.Prioridad)); WData.Write(SEP);
        // RawItem*: campo vacio => NULL (KEEPNULLS). ClaveERP contiene '|' (ya
        // no es separador); CsvSafe solo limpia CR/LF/SEP.
        WData.Write(CsvSafe(R.RawItemClaveERP)); WData.Write(SEP);
        WData.Write(CsvSafe(R.RawItemTipoOrigen)); WData.Write(SEP);
        WData.Write(IntToStr(COLOR_FONDO_DEF)); WData.Write(SEP);
        WData.Write(IntToStr(COLOR_BORDE_DEF));
        WData.WriteLine;
      end;
    finally
      WNode.Free; WData.Free;
      // Enc = TEncoding.UTF8 (singleton RTL): NO liberar.
    end;

    try
      try
        BulkInsert('#tmpNode', FNode);
        BulkInsert('#tmpData', FData);
      except
        on E: Exception do
        begin
          PlanLog.Linea('  BULK_NODES M5 BULK INSERT fallo: %s', [E.Message]);
          raise;   // deja que PersistBulk degrade a M4
        end;
      end;
    finally
      if TFile.Exists(FNode) then TFile.Delete(FNode);
      if TFile.Exists(FData) then TFile.Delete(FData);
    end;
  end;

  // M4: rellena las #temp con RECORDSETS ADO en modo batch (binario via OLE DB).
  procedure LlenarBulkADO;
  var
    RsNode, RsData: TADODataSet;
    K: Integer;
    R: TBulkNodeRow;

    function NuevoRs(const ATabla: string): TADODataSet;
    begin
      Result := TADODataSet.Create(nil);
      Result.Connection := AConn;
      Result.CommandType := cmdTableDirect;
      Result.CommandText := ATabla;
      Result.CursorLocation := clUseServer;
      Result.CursorType := ctKeyset;
      Result.LockType := ltBatchOptimistic;
      Result.Open;
    end;

    procedure SetOrNull(ADataSet: TADODataSet; const AField: string; const V: TDateTime);
    begin
      if V > 0 then ADataSet.FieldByName(AField).AsDateTime := V
      else ADataSet.FieldByName(AField).Clear;
    end;

    procedure SetStrOrNull(ADataSet: TADODataSet; const AField, V: string);
    begin
      if V = '' then ADataSet.FieldByName(AField).Clear
      else ADataSet.FieldByName(AField).AsString := V;
    end;

  begin
    RsNode := NuevoRs('#tmpNode');
    RsData := NuevoRs('#tmpData');
    try
      for K := 0 to High(ARows) do
      begin
        R := ARows[K];

        RsNode.Append;
        RsNode.FieldByName('CodigoEmpresa').AsInteger := ACE;
        RsNode.FieldByName('NodeId').AsInteger := R.NodeId;
        RsNode.FieldByName('ProjectId').AsInteger := APID;
        if R.CenterId <= 0 then RsNode.FieldByName('CenterId').Clear
        else RsNode.FieldByName('CenterId').AsInteger := R.CenterId;
        SetOrNull(RsNode, 'FechaInicio', R.FechaInicio);
        SetOrNull(RsNode, 'FechaFin', R.FechaFin);
        RsNode.FieldByName('DuracionMin').AsFloat := R.DuracionMin;
        RsNode.FieldByName('Caption').AsString := R.Caption;
        RsNode.FieldByName('ColorFondo').AsInteger := COLOR_FONDO_DEF;
        RsNode.FieldByName('ColorBorde').AsInteger := COLOR_BORDE_DEF;
        RsNode.Post;

        RsData.Append;
        RsData.FieldByName('CodigoEmpresa').AsInteger := ACE;
        RsData.FieldByName('NodeId').AsInteger := R.NodeId;
        RsData.FieldByName('Operacion').AsString := R.Operacion;
        RsData.FieldByName('NumeroOF').AsInteger := R.NumeroOF;
        SetStrOrNull(RsData, 'SerieOF', R.SerieOF);
        RsData.FieldByName('NumeroPedido').AsInteger := R.NumeroPedido;
        SetStrOrNull(RsData, 'SeriePedido', R.SeriePedido);
        RsData.FieldByName('NumeroTrabajo').AsString := R.NumeroTrabajo;
        SetOrNull(RsData, 'FechaEntrega', R.FechaEntrega);
        SetOrNull(RsData, 'FechaNecesaria', R.FechaNecesaria);
        RsData.FieldByName('CodigoCliente').AsString := R.CodigoCliente;
        RsData.FieldByName('CodigoArticulo').AsString := R.CodigoArticulo;
        RsData.FieldByName('DescripcionArticulo').AsString := R.DescripcionArticulo;
        RsData.FieldByName('DuracionMin').AsFloat := R.DuracionMin;
        RsData.FieldByName('DuracionMinOriginal').AsFloat := R.DuracionMin;
        RsData.FieldByName('UnidadesAFabricar').AsFloat := UdsEff(R);
        RsData.FieldByName('TiempoUnidadFabSecs').AsFloat := R.TiempoUnidadFabSecs;
        RsData.FieldByName('OperariosNecesarios').AsInteger := 1;
        RsData.FieldByName('Prioridad').AsInteger := R.Prioridad;
        SetStrOrNull(RsData, 'RawItemClaveERP', R.RawItemClaveERP);
        SetStrOrNull(RsData, 'RawItemTipoOrigen', R.RawItemTipoOrigen);
        RsData.FieldByName('ColorFondoOp').AsInteger := COLOR_FONDO_DEF;
        RsData.FieldByName('ColorBordeOp').AsInteger := COLOR_BORDE_DEF;
        RsData.Post;
      end;
      RsNode.UpdateBatch;
      RsData.UpdateBatch;
    finally
      RsNode.Free; RsData.Free;
    end;
  end;

begin
  CE := IntToStr(ACE);
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;

    // 1) Reservar rango de NodeIds (una sola vez). Los asignamos nosotros.
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text := 'SELECT ISNULL(MAX(NodeId),0) AS M FROM FS_PL_Node WHERE CodigoEmpresa = ' + CE;
      Q.Open;
      BaseId := Q.FieldByName('M').AsInteger + 1;
    finally
      Q.Free;
    end;
    for I := 0 to High(ARows) do
      ARows[I].NodeId := BaseId + I;

    // 2) Crear #temp (misma sesion = esta conexion). Columnas y orden que
    //    espera el volcado set-based. DROP previo: si un intento anterior (p.ej.
    //    M5) fallo a mitad, las #temp sobreviven en la sesion (no en la
    //    transaccion) y el fallback a M4 chocaria con "ya existe".
    ExecNoRec('DROP TABLE IF EXISTS #tmpNode; DROP TABLE IF EXISTS #tmpData;');
    ExecNoRec(
      'CREATE TABLE #tmpNode (CodigoEmpresa INT, NodeId INT, ProjectId INT, ' +
      '  CenterId INT NULL, FechaInicio DATETIME NULL, FechaFin DATETIME NULL, ' +
      '  DuracionMin DECIMAL(12,2), Caption NVARCHAR(255), ColorFondo INT, ColorBorde INT); ' +
      'CREATE TABLE #tmpData (CodigoEmpresa INT, NodeId INT, Operacion NVARCHAR(255), ' +
      '  NumeroOF INT, SerieOF NVARCHAR(50) NULL, NumeroPedido INT, SeriePedido NVARCHAR(50) NULL, ' +
      '  NumeroTrabajo NVARCHAR(50), FechaEntrega DATETIME2 NULL, FechaNecesaria DATETIME2 NULL, ' +
      '  CodigoCliente NVARCHAR(255), CodigoArticulo NVARCHAR(255), DescripcionArticulo NVARCHAR(255), ' +
      '  DuracionMin DECIMAL(12,2), DuracionMinOriginal DECIMAL(12,2), ' +
      '  UnidadesAFabricar DECIMAL(14,4), TiempoUnidadFabSecs DECIMAL(14,4), ' +
      '  OperariosNecesarios INT, Prioridad INT, ' +
      '  RawItemClaveERP NVARCHAR(100) NULL, RawItemTipoOrigen NVARCHAR(10) NULL, ' +
      '  ColorFondoOp INT, ColorBordeOp INT);');

    // 3) Llenar #temp.
    if AUseFile then LlenarBulkFile else LlenarBulkADO;

    // 4) Volcado set-based a las tablas reales. FS_PL_Node necesita IDENTITY_INSERT.
    ExecNoRec(
      'SET IDENTITY_INSERT FS_PL_Node ON; ' +
      'INSERT INTO FS_PL_Node (CodigoEmpresa, NodeId, ProjectId, CenterId, FechaInicio, ' +
      '  FechaFin, DuracionMin, Caption, ColorFondo, ColorBorde) ' +
      'SELECT CodigoEmpresa, NodeId, ProjectId, CenterId, FechaInicio, FechaFin, ' +
      '  DuracionMin, Caption, ColorFondo, ColorBorde FROM #tmpNode; ' +
      'SET IDENTITY_INSERT FS_PL_Node OFF;');

    ExecNoRec(
      'INSERT INTO FS_PL_NodeData (CodigoEmpresa, NodeId, Operacion, NumeroOF, SerieOF, ' +
      '  NumeroPedido, SeriePedido, NumeroTrabajo, FechaEntrega, FechaNecesaria, CodigoCliente, ' +
      '  CodigoArticulo, DescripcionArticulo, DuracionMin, DuracionMinOriginal, UnidadesAFabricar, ' +
      '  TiempoUnidadFabSecs, OperariosNecesarios, Prioridad, RawItemClaveERP, RawItemTipoOrigen, ' +
      '  ColorFondoOp, ColorBordeOp) ' +
      'SELECT CodigoEmpresa, NodeId, Operacion, NumeroOF, SerieOF, NumeroPedido, SeriePedido, ' +
      '  NumeroTrabajo, FechaEntrega, FechaNecesaria, CodigoCliente, CodigoArticulo, DescripcionArticulo, ' +
      '  DuracionMin, DuracionMinOriginal, UnidadesAFabricar, TiempoUnidadFabSecs, OperariosNecesarios, ' +
      '  Prioridad, RawItemClaveERP, RawItemTipoOrigen, ColorFondoOp, ColorBordeOp FROM #tmpData;');

    // 5) Limpiar #temp (viven en la conexion; la transaccion sigue abierta).
    ExecNoRec('DROP TABLE #tmpNode; DROP TABLE #tmpData;');
  finally
    Cmd.Free;
  end;
end;

function BulkInsertNodes(AConn: TADOConnection;
  ACodigoEmpresa, AProjectId: Integer;
  var ARows: TArray<TBulkNodeRow>;
  APreferred: TBulkNodeMethod = bmBulkFile): TBulkNodeMethod;
var
  T0: TDateTime;
  N: Integer;
begin
  N := Length(ARows);
  if N = 0 then Exit(APreferred);

  // Lotes pequenos: no compensa montar #temp -> M1 directo (salvo que se pida
  // explicitamente otro para comparar). Respetamos la peticion explicita.
  if (N < UMBRAL_BULK) and (APreferred = bmBulkFile) then
    APreferred := bmPerRow;

  T0 := Now;
  Result := APreferred;
  try
    case APreferred of
      bmBulkFile: PersistBulk(AConn, ACodigoEmpresa, AProjectId, ARows, True);
      bmBulkADO:  PersistBulk(AConn, ACodigoEmpresa, AProjectId, ARows, False);
    else          PersistPerRow(AConn, ACodigoEmpresa, AProjectId, ARows);
    end;
  except
    on E: Exception do
    begin
      // Degradar: M5 -> M4 -> M1. Ojo: si PersistBulk fallo a mitad, el llamante
      // hara ROLLBACK de la transaccion; aqui solo reintentamos el metodo, la
      // reserva de IDs se recalcula dentro de PersistBulk/PersistPerRow.
      PlanLog.Linea('  BULK_NODES %s fallo (%s) -> degradando',
        [BulkNodeMethodName(APreferred), E.Message]);
      case APreferred of
        bmBulkFile:
          Result := BulkInsertNodes(AConn, ACodigoEmpresa, AProjectId, ARows, bmBulkADO);
        bmBulkADO:
          Result := BulkInsertNodes(AConn, ACodigoEmpresa, AProjectId, ARows, bmPerRow);
      else
        raise;   // M1 fallo: no hay red debajo
      end;
      Exit;
    end;
  end;

  PlanLog.Linea('BULK_NODES: %d nodos en %d ms (%s)',
    [N, MilliSecondsBetween(Now, T0), BulkNodeMethodName(Result)]);
end;

end.
