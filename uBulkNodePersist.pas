unit uBulkNodePersist;

{
  Persistencia MASIVA de nodos nuevos (FS_PL_Node + FS_PL_NodeData) para el
  camino de creacion desde el Backlog (CommitScheduling).

  Sustituye el patron clasico M1 (por cada nodo: INSERT Node + SCOPE_IDENTITY()
  + INSERT NodeData = 3 round-trips) por persistencia en lote:

    M5 (bmBulkFile)  CSV a disco + BULK INSERT (streaming en el servidor) + volcado
                     set-based. La mas rapida (~8x sobre M1).
    M4 (bmBulkADO)   #temp via recordsets ADO batch (binario) + volcado set-based.
                     Fallback fiable cuando la cuenta de servicio SQL no puede leer
                     el TEMP (BULK INSERT falla).
    M1 (bmPerRow)    Camino clasico por fila. Fallback ultimo y camino preferente
                     para lotes pequenos (< UMBRAL_BULK filas), donde el overhead
                     de crear #temp no compensa.

  Diagnostico y racional completo en la memoria reference_bulk_persist_sqlserver:
  el cuello de botella al escribir muchas filas desde ADO NO es la BD sino el
  overhead POR FILA del provider OLE DB; solo BULK INSERT desde fichero lo rompe.

  IDENTIDAD DE LOS NODOS (V086)
  Los NodeId los genera el IDENTITY de FS_PL_Node; nunca los asignamos nosotros.
  El camino masivo mete en #tmpNode un RowIdx (indice de la fila dentro del lote,
  en la columna NodeId de la #temp), inserta SIN IDENTITY_INSERT y recupera con
  'OUTPUT INSERTED.RowIdx, INSERTED.NodeId' que id le ha tocado a cada fila. Ese
  mapeo reescribe #tmpData y se devuelve al llamante en ARows[].NodeId (los usa
  AplicarAgrupacion para crear lotes).

  Antes se reservaba el rango con 'SELECT MAX(NodeId)+1'. NO era atomico: dos
  usuarios planificando a la vez reservaban el MISMO rango -> clave duplicada o
  filas mezcladas entre planes. Corrupcion silenciosa, en la ruta comercial
  central. No reintroducir ese patron.

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
    // Maquina DENTRO del centro donde el motor ha colocado la operacion (V083).
    // 0 = sin determinar (BD sin migrar): el nodo se crea solo con su centro.
    //
    // NO se escribe en el INSERT masivo: los cinco metodos de persistencia
    // (M5 fichero, M4 ADO, M1 fila a fila) construyen SQL distinto y tocarlos
    // todos por una columna es mucho riesgo para poco. Se asigna despues, con
    // un UPDATE por lotes desde los NodeId que devuelve este mismo modulo
    // (ver AsignarMaquinasANodos).
    MaquinaId: Integer;
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

// Escribe FS_PL_Node.MaquinaId de los nodos recien creados (V083). Se llama
// DESPUES de BulkInsertNodes, cuando cada Row ya tiene su NodeId, y dentro de
// la misma transaccion.
//
// Agrupa por MaquinaId y lanza un UPDATE ... WHERE NodeId IN (...) por grupo:
// con 500 nodos repartidos entre 6 maquinas son 6 sentencias, no 500. Las filas
// con MaquinaId <= 0 se saltan (se quedan con NULL, que es valido).
procedure AsignarMaquinasANodos(AConn: TADOConnection;
  ACodigoEmpresa: SmallInt; const ARows: TArray<TBulkNodeRow>);

function BulkNodeMethodName(AMethod: TBulkNodeMethod): string;

implementation

uses
  System.Generics.Collections,   // TDictionary/TPair (AsignarMaquinasANodos)
  uPlanLog;

procedure AsignarMaquinasANodos(AConn: TADOConnection;
  ACodigoEmpresa: SmallInt; const ARows: TArray<TBulkNodeRow>);
var
  PorMaquina: TDictionary<Integer, TStringBuilder>;
  Par: TPair<Integer, TStringBuilder>;
  Sb: TStringBuilder;
  Cmd: TADOCommand;
  I: Integer;
begin
  if AConn = nil then Exit;
  if Length(ARows) = 0 then Exit;

  PorMaquina := TDictionary<Integer, TStringBuilder>.Create;
  try
    // Agrupar los NodeId por la maquina que les toca.
    for I := 0 to High(ARows) do
    begin
      if ARows[I].MaquinaId <= 0 then Continue;   // sin maquina: se deja NULL
      if ARows[I].NodeId <= 0 then Continue;      // no se llego a insertar

      if not PorMaquina.TryGetValue(ARows[I].MaquinaId, Sb) then
      begin
        Sb := TStringBuilder.Create;
        PorMaquina.Add(ARows[I].MaquinaId, Sb);
      end;
      if Sb.Length > 0 then Sb.Append(',');
      Sb.Append(IntToStr(ARows[I].NodeId));
    end;

    if PorMaquina.Count = 0 then Exit;

    Cmd := TADOCommand.Create(nil);
    try
      Cmd.Connection := AConn;
      Cmd.ParamCheck := False;
      for Par in PorMaquina do
      begin
        if Par.Value.Length = 0 then Continue;
        // Ids generados por el propio INSERT: no vienen del usuario, asi que la
        // lista en el IN no tiene riesgo de inyeccion.
        Cmd.CommandText :=
          'UPDATE FS_PL_Node SET MaquinaId = ' + IntToStr(Par.Key) +
          ' WHERE CodigoEmpresa = ' + IntToStr(ACodigoEmpresa) +
          '   AND NodeId IN (' + Par.Value.ToString + ')';
        Cmd.Execute;
      end;
    finally
      Cmd.Free;
    end;
  finally
    for Par in PorMaquina do
      Par.Value.Free;
    PorMaquina.Free;
  end;
end;

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

    // SCOPE_IDENTITY() = el IDENTITY generado por ESTA sesion (misma AConn que
    // el INSERT de arriba). NO usar MAX(NodeId): con dos usuarios planificando
    // a la vez leia la fila del OTRO y el NodeData se enganchaba al nodo
    // equivocado. Tampoco @@IDENTITY: cruza ambitos.
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text := 'SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewId';
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
  Camino BULK (M5 / M4): crear #temp, llenar por el metodo elegido, volcar
  set-based dejando que el IDENTITY genere los NodeId, y recuperarlos por
  OUTPUT via RowIdx (ver cabecera del unit).
  -------------------------------------------------------------------------- }
procedure PersistBulk(AConn: TADOConnection; ACE, APID: Integer;
  var ARows: TArray<TBulkNodeRow>; AUseFile: Boolean);
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  I: Integer;
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

    // 1) NO reservamos rango: los NodeId los genera el IDENTITY de FS_PL_Node
    //    en el propio INSERT (paso 4) y los recuperamos con OUTPUT.
    //
    //    Antes esto hacia 'SELECT MAX(NodeId)+1' y asignaba los ids a mano. NO
    //    era atomico: dos usuarios planificando a la vez reservaban el MISMO
    //    rango -> clave duplicada o filas mezcladas entre planes (corrupcion
    //    silenciosa). Se descarto la alternativa de una tabla de secuencia
    //    porque convivir con el IDENTITY deja DOS fuentes de ids que hay que
    //    mantener sincronizadas para siempre (y obliga a reseeds).
    //
    //    La columna NodeId de #tmpNode pasa a ser RowIdx: el indice de la fila
    //    dentro de ARows. Es la clave que permite casar cada fila de entrada
    //    con el NodeId que le ha tocado (el orden del OUTPUT no esta
    //    garantizado, asi que no se puede casar por posicion).
    for I := 0 to High(ARows) do
      ARows[I].NodeId := I;

    // 2) Crear #temp (misma sesion = esta conexion). Columnas y orden que
    //    espera el volcado set-based. DROP previo: si un intento anterior (p.ej.
    //    M5) fallo a mitad, las #temp sobreviven en la sesion (no en la
    //    transaccion) y el fallback a M4 chocaria con "ya existe".
    ExecNoRec('DROP TABLE IF EXISTS #tmpNode; DROP TABLE IF EXISTS #tmpData; ' +
              'DROP TABLE IF EXISTS #tmpMap;');
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

    // 4) Volcado set-based. SIN IDENTITY_INSERT: el IDENTITY genera los NodeId
    //    y OUTPUT nos devuelve cual le ha tocado a cada fila.
    //
    //    #tmpMap (RowIdx -> NodeId) es la pieza clave. OUTPUT no garantiza el
    //    orden de las filas devueltas, por eso arrastramos RowIdx (que viaja en
    //    la columna NodeId de #tmpNode) hasta la tabla de mapeo: casar por
    //    posicion seria incorrecto.
    //
    //    ORDER BY RowIdx en el SELECT de origen no garantiza que el IDENTITY se
    //    asigne en ese orden, pero SI hace que los ids salgan contiguos en la
    //    practica; el mapeo es correcto en cualquier caso.
    ExecNoRec('CREATE TABLE #tmpMap (RowIdx INT PRIMARY KEY, NodeId INT);');

    //    RowIdx viaja como columna REAL de FS_PL_Node (V086) porque OUTPUT solo
    //    sabe devolver columnas de la tabla destino. Se descarto 'MERGE ON 1=0'
    //    (que si permite OUTPUT de la origen): MERGE arrastra bugs conocidos
    //    bajo concurrencia y es justo lo que este arreglo viene a blindar.
    ExecNoRec(
      'INSERT INTO FS_PL_Node (CodigoEmpresa, ProjectId, CenterId, FechaInicio, ' +
      '  FechaFin, DuracionMin, Caption, ColorFondo, ColorBorde, RowIdx) ' +
      'OUTPUT INSERTED.RowIdx, INSERTED.NodeId INTO #tmpMap (RowIdx, NodeId) ' +
      'SELECT CodigoEmpresa, ProjectId, CenterId, FechaInicio, FechaFin, ' +
      '  DuracionMin, Caption, ColorFondo, ColorBorde, NodeId FROM #tmpNode;');

    // 4b) Reescribir #tmpData.NodeId (que aun lleva RowIdx) con el id real.
    ExecNoRec(
      'UPDATE D SET D.NodeId = M.NodeId ' +
      'FROM #tmpData D INNER JOIN #tmpMap M ON M.RowIdx = D.NodeId;');

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

    // 4c) Devolver los NodeId reales al llamante (AplicarAgrupacion los usa
    //     para crear lotes). Hasta aqui ARows[I].NodeId valia I (RowIdx).
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text := 'SELECT RowIdx, NodeId FROM #tmpMap';
      Q.Open;
      while not Q.Eof do
      begin
        I := Q.FieldByName('RowIdx').AsInteger;
        if (I >= 0) and (I <= High(ARows)) then
          ARows[I].NodeId := Q.FieldByName('NodeId').AsInteger;
        Q.Next;
      end;
    finally
      Q.Free;
    end;

    // 5) Limpiar #temp (viven en la conexion; la transaccion sigue abierta).
    ExecNoRec('DROP TABLE #tmpNode; DROP TABLE #tmpData; DROP TABLE #tmpMap;');
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
