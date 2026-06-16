unit uErpSyncRepo;

// ============================================================================
// Repositorio de sincronizacion ERP -> FS_PL_*.
//
// Calcula el preview comparando lo que devuelve IErpReader contra lo que ya
// hay en local (matching por ErpCodigo). Aplica los cambios via MERGE UPSERT
// respetando la politica de conflictos.
//
// Es agnostico del ERP: solo conoce la interfaz IErpReader y los records
// neutros de uErpTypes.
// ============================================================================

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Hash,
  Data.Win.ADODB, Data.DB,
  uErpReader, uErpTypes, uErpSyncTypes, uErpFieldMapRepo;

type
  TErpSyncRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    FErpSistema: string;

    function SqlStr(const S: string): string;
    function HashCentro(const C: TCentroTrabajoErp): string;
    function HashMaquina(const M: TMaquinaErp): string;
    procedure ExecSql(const ASql: string);

    procedure LoadLocalCentrosByErpCodigo(
      out AByErp: TDictionary<string, TSyncRowCentro>);
    procedure LoadLocalMaquinasByErpCodigo(
      out AByErp: TDictionary<string, TSyncRowMaquina>);
    procedure LoadLocalOperariosByErpCodigo(
      out AByErp: TDictionary<string, TSyncRowOperario>);
    procedure LoadLocalCentroMaquinaByKey(
      out AByKey: TDictionary<string, TSyncRowCentroMaquina>);
    procedure LoadErpCodeMaps(
      out ACentroMap: TDictionary<string, Integer>;
      out AMaquinaMap: TDictionary<string, Integer>);

    procedure ApplyCentro(const ARow: TSyncRowCentro);
    procedure ApplyMaquina(const ARow: TSyncRowMaquina);
    procedure ApplyOperario(const ARow: TSyncRowOperario);
    procedure ApplyCentroMaquinaRow(const ARow: TSyncRowCentroMaquina);
    procedure ApplyShiftModel(const ARow: TSyncRowShiftModel);
    procedure ApplyAlmacen(const ARow: TSyncRowAlmacen);
    procedure ApplyFamilia(const ARow: TSyncRowFamilia);
    procedure ApplyCalendarioRow(const ARow: TSyncRowCalendario;
      const ADias: TArray<TCalendarioLaboralErp>);
    procedure LoadLocalCalendariosByErpCodigo(
      out AByErp: TDictionary<string, TSyncRowCalendario>);
    function HashOperario(const O: TOperarioErp): string;
    function HashCentroMaquina(const CM: TCentroMaquinaErp): string;
    function HashShiftModel(const M: TModeloHorarioErp; const L: TArray<TLineaModeloHorarioErp>): string;
    function HashAlmacen(const A: TAlmacenErp): string;
    function HashFamilia(const F: TFamiliaErp): string;
    function GetErpCalendarId: Integer;
    procedure LoadLocalShiftModelsByErpCodigo(
      out AByErp: TDictionary<string, TSyncRowShiftModel>);
    procedure LoadLocalAlmacenesByErpCodigo(
      out AByErp: TDictionary<string, TSyncRowAlmacen>);
    procedure LoadLocalFamiliasByErpCodigo(
      out AByErp: TDictionary<string, TSyncRowFamilia>);

    function HashRawItem(const Item: TRawItemErp): string;
    procedure LoadLocalRawItemsByClave(const ATipoOrigen: string;
      out AByClave: TDictionary<string, TSyncRowRawItem>);
    procedure LoadLocalRawItemsFull(const ATipoOrigen: string;
      out AByClave: TDictionary<string, TRawItemErp>);
    procedure ApplyRawItem(const ARow: TSyncRowRawItem;
      const AParentLocalIds: TDictionary<string, Int64>);
    // Escribe los campos custom poblados desde el ERP (ExtraFields) en
    // FS_PL_RawItem_Extra con Source='ERP'. MERGE que respeta los overrides
    // manuales (no pisa filas con Source='MANUAL').
    procedure ApplyRawItemExtras(ARawItemId: Int64;
      const AExtras: TArray<TErpExtraValue>);
    procedure MarkRawItemObsoleto(ALocalRawItemId: Int64);
  public
    constructor Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt;
      const AErpSistema: string);

    function PreviewCentros(AReader: IErpReader): TArray<TSyncRowCentro>;
    function PreviewMaquinas(AReader: IErpReader): TArray<TSyncRowMaquina>;
    function PreviewOperarios(AReader: IErpReader): TArray<TSyncRowOperario>;
    function PreviewCentroMaquina(AReader: IErpReader): TArray<TSyncRowCentroMaquina>;
    function PreviewShiftModels(AReader: IErpReader): TArray<TSyncRowShiftModel>;
    function PreviewAlmacenes(AReader: IErpReader): TArray<TSyncRowAlmacen>;
    function PreviewFamilias(AReader: IErpReader): TArray<TSyncRowFamilia>;
    function PreviewCalendarios(AReader: IErpReader;
      AFechaDesde, AFechaHasta: TDateTime): TArray<TSyncRowCalendario>;

    function ApplyCentros(const ARows: TArray<TSyncRowCentro>): TSyncSummary;
    function ApplyMaquinas(const ARows: TArray<TSyncRowMaquina>): TSyncSummary;
    function ApplyOperarios(const ARows: TArray<TSyncRowOperario>): TSyncSummary;
    function ApplyCentroMaquina(const ARows: TArray<TSyncRowCentroMaquina>): TSyncSummary;
    function ApplyShiftModels(const ARows: TArray<TSyncRowShiftModel>): TSyncSummary;
    function ApplyAlmacenes(const ARows: TArray<TSyncRowAlmacen>): TSyncSummary;
    function ApplyFamilias(const ARows: TArray<TSyncRowFamilia>): TSyncSummary;
    function ApplyCalendarios(const ARows: TArray<TSyncRowCalendario>;
      AFechaDesde, AFechaHasta: TDateTime;
      AReader: IErpReader): TSyncSummary;

    // -- BACKLOG (Raw_Item) ----------------------------------------------
    // PreviewBacklogOF: llegeix OF->OT->OP del ERP, calcula estat respecte
    // a FS_PL_Raw_Item local. Retorna l'array jerarquic (pares abans).
    function PreviewBacklogOF(AReader: IErpReader;
      AEjercicio: SmallInt): TArray<TSyncRowRawItem>;

    // ApplyRawItems: persisteix els ARows on Aplicar=True a FS_PL_Raw_Item.
    // Marca Activo=0 (obsolet) els Raw_Items existents amb ssEliminadoErp
    // que no tinguin FS_PL_NodeData associat.
    function ApplyRawItems(const ARows: TArray<TSyncRowRawItem>): TSyncSummary;

    // Post-pass: vincula Operator.CalendarId i FS_PL_CenterCalendar segons
    // GrupoHorarioCodigo. Retorna nombre d'operaris i centres vinculats.
    procedure LinkOperatorsAndCentersToCalendars(
      out AOperariosVinculados, ACentrosVinculados: Integer);
  end;

implementation

uses
  System.StrUtils, System.DateUtils, System.Variants;

{ TErpSyncRepo }

constructor TErpSyncRepo.Create(AConnection: TADOConnection;
  ACodigoEmpresa: SmallInt; const AErpSistema: string);
begin
  inherited Create;
  FConnection := AConnection;
  FCodigoEmpresa := ACodigoEmpresa;
  FErpSistema := AErpSistema;
end;

function TErpSyncRepo.SqlStr(const S: string): string;
begin
  Result := '''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

procedure TErpSyncRepo.ExecSql(const ASql: string);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.ParamCheck := False;
    Cmd.CommandText := ASql;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

function TErpSyncRepo.HashCentro(const C: TCentroTrabajoErp): string;
var
  Buf: string;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  Buf :=
    C.Codigo + '|' + C.Descripcion + '|' +
    BoolToStr(C.PermiteConcurrencia, True) + '|' +
    IntToStr(C.MaquinasFabricacion) + '|' +
    IntToStr(C.OperariosFabricacion) + '|' +
    IntToStr(C.OperariosPreparacion) + '|' +
    FloatToStr(C.PorcentajeDedicacionOperario, FS) + '|' +
    FloatToStr(C.PorcentajeCorreccionPreparacion, FS) + '|' +
    FloatToStr(C.PorcentajeCorreccionFabricacion, FS) + '|' +
    FloatToStr(C.CosteHoraManoObra, FS) + '|' +
    FloatToStr(C.CosteHoraMaquina, FS) + '|' +
    C.GrupoHorario + '|' + C.MaquinaPrincipal;
  Result := THashSHA1.GetHashString(Buf);
end;

function TErpSyncRepo.HashMaquina(const M: TMaquinaErp): string;
var
  Buf: string;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  Buf :=
    M.Codigo + '|' + M.Marca + '|' + M.Modelo + '|' + M.Descripcion + '|' +
    FloatToStr(M.PorcentajeCorreccionPreparacion, FS) + '|' +
    FloatToStr(M.PorcentajeCorreccionFabricacion, FS) + '|' +
    FloatToStr(M.CosteHoraMaquina, FS) + '|' +
    FloatToStr(M.UnidadesHora, FS);
  Result := THashSHA1.GetHashString(Buf);
end;

procedure TErpSyncRepo.LoadLocalCentrosByErpCodigo(
  out AByErp: TDictionary<string, TSyncRowCentro>);
var
  Q: TADOQuery;
  Row: TSyncRowCentro;
  ErpKey: string;
begin
  AByErp := TDictionary<string, TSyncRowCentro>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT CenterId, CodigoCentro, Titulo, ' +
      '       ISNULL(Source, ''MANUAL'') AS Source, ' +
      '       ISNULL(ErpCodigo, '''') AS ErpCodigo, ' +
      '       ISNULL(LastErpHash, '''') AS LastErpHash ' +
      'FROM FS_PL_Center ' +
      'WHERE CodigoEmpresa = :Emp';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.LocalCenterId       := Q.FieldByName('CenterId').AsInteger;
      Row.LocalCodigoCentro   := Q.FieldByName('CodigoCentro').AsString;
      Row.LocalTitulo         := Q.FieldByName('Titulo').AsString;
      Row.LocalSource         := Q.FieldByName('Source').AsString;
      Row.LocalLastErpHash    := Q.FieldByName('LastErpHash').AsString;
      ErpKey := Q.FieldByName('ErpCodigo').AsString;
      if ErpKey = '' then
        ErpKey := Row.LocalCodigoCentro;   // fallback para registros pre-V036
      AByErp.AddOrSetValue(ErpKey, Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TErpSyncRepo.LoadLocalMaquinasByErpCodigo(
  out AByErp: TDictionary<string, TSyncRowMaquina>);
var
  Q: TADOQuery;
  Row: TSyncRowMaquina;
  ErpKey: string;
begin
  AByErp := TDictionary<string, TSyncRowMaquina>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT MaquinaId, Codigo, ' +
      '       ISNULL(Descripcion, '''') AS Descripcion, ' +
      '       ISNULL(Source, ''MANUAL'') AS Source, ' +
      '       ISNULL(ErpCodigo, '''') AS ErpCodigo, ' +
      '       ISNULL(LastErpHash, '''') AS LastErpHash ' +
      'FROM FS_PL_Maquina ' +
      'WHERE CodigoEmpresa = :Emp';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.LocalMaquinaId    := Q.FieldByName('MaquinaId').AsInteger;
      Row.LocalCodigo       := Q.FieldByName('Codigo').AsString;
      Row.LocalDescripcion  := Q.FieldByName('Descripcion').AsString;
      Row.LocalSource       := Q.FieldByName('Source').AsString;
      Row.LocalLastErpHash  := Q.FieldByName('LastErpHash').AsString;
      ErpKey := Q.FieldByName('ErpCodigo').AsString;
      if ErpKey = '' then
        ErpKey := Row.LocalCodigo;
      AByErp.AddOrSetValue(ErpKey, Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TErpSyncRepo.PreviewCentros(AReader: IErpReader): TArray<TSyncRowCentro>;
var
  ErpRows: TArray<TCentroTrabajoErp>;
  Locals: TDictionary<string, TSyncRowCentro>;
  Row, LocalRow: TSyncRowCentro;
  C: TCentroTrabajoErp;
  ErpSeen: TDictionary<string, Boolean>;
  Pair: TPair<string, TSyncRowCentro>;
  ResList: TList<TSyncRowCentro>;
begin
  ErpRows := AReader.ReadCentrosTrabajo;
  LoadLocalCentrosByErpCodigo(Locals);
  ErpSeen := TDictionary<string, Boolean>.Create;
  ResList := TList<TSyncRowCentro>.Create;
  try
    for C in ErpRows do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.ErpData := C;
      Row.NewHash := HashCentro(C);
      Row.ConflictAction := caAplicarErp;
      ErpSeen.AddOrSetValue(C.Codigo, True);

      if Locals.TryGetValue(C.Codigo, LocalRow) then
      begin
        Row.LocalCenterId      := LocalRow.LocalCenterId;
        Row.LocalCodigoCentro  := LocalRow.LocalCodigoCentro;
        Row.LocalTitulo        := LocalRow.LocalTitulo;
        Row.LocalSource        := LocalRow.LocalSource;
        Row.LocalLastErpHash   := LocalRow.LocalLastErpHash;

        if Row.NewHash = Row.LocalLastErpHash then
        begin
          Row.Status := ssSinCambios;
          Row.Aplicar := False;
        end
        else if SameText(Row.LocalSource, 'ERP') and (Row.LocalLastErpHash <> '') then
        begin
          Row.Status := ssActualizado;
          Row.Aplicar := True;
        end
        else
        begin
          Row.Status := ssConflicto;
          Row.Aplicar := False;     // el usuario decide
        end;
      end
      else
      begin
        Row.Status := ssNuevo;
        Row.Aplicar := True;
      end;

      ResList.Add(Row);
    end;

    // Detectar borrados: lo que estaba con Source='ERP' y ya no aparece
    for Pair in Locals do
      if not ErpSeen.ContainsKey(Pair.Key) and
         SameText(Pair.Value.LocalSource, 'ERP') then
      begin
        Row := Pair.Value;
        Row.ErpData.Codigo := Pair.Key;
        Row.ErpData.Descripcion := Pair.Value.LocalTitulo;
        Row.Status := ssEliminadoErp;
        Row.Aplicar := False;
        ResList.Add(Row);
      end;

    Result := ResList.ToArray;
  finally
    ErpSeen.Free;
    Locals.Free;
    ResList.Free;
  end;
end;

function TErpSyncRepo.PreviewMaquinas(AReader: IErpReader): TArray<TSyncRowMaquina>;
var
  ErpRows: TArray<TMaquinaErp>;
  Locals: TDictionary<string, TSyncRowMaquina>;
  Row, LocalRow: TSyncRowMaquina;
  M: TMaquinaErp;
  ErpSeen: TDictionary<string, Boolean>;
  Pair: TPair<string, TSyncRowMaquina>;
  ResList: TList<TSyncRowMaquina>;
begin
  ErpRows := AReader.ReadMaquinas;
  LoadLocalMaquinasByErpCodigo(Locals);
  ErpSeen := TDictionary<string, Boolean>.Create;
  ResList := TList<TSyncRowMaquina>.Create;
  try
    for M in ErpRows do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.ErpData := M;
      Row.NewHash := HashMaquina(M);
      Row.ConflictAction := caAplicarErp;
      ErpSeen.AddOrSetValue(M.Codigo, True);

      if Locals.TryGetValue(M.Codigo, LocalRow) then
      begin
        Row.LocalMaquinaId   := LocalRow.LocalMaquinaId;
        Row.LocalCodigo      := LocalRow.LocalCodigo;
        Row.LocalDescripcion := LocalRow.LocalDescripcion;
        Row.LocalSource      := LocalRow.LocalSource;
        Row.LocalLastErpHash := LocalRow.LocalLastErpHash;

        if Row.NewHash = Row.LocalLastErpHash then
        begin
          Row.Status := ssSinCambios;
          Row.Aplicar := False;
        end
        else if SameText(Row.LocalSource, 'ERP') and (Row.LocalLastErpHash <> '') then
        begin
          Row.Status := ssActualizado;
          Row.Aplicar := True;
        end
        else
        begin
          Row.Status := ssConflicto;
          Row.Aplicar := False;
        end;
      end
      else
      begin
        Row.Status := ssNuevo;
        Row.Aplicar := True;
      end;

      ResList.Add(Row);
    end;

    for Pair in Locals do
      if not ErpSeen.ContainsKey(Pair.Key) and
         SameText(Pair.Value.LocalSource, 'ERP') then
      begin
        Row := Pair.Value;
        Row.ErpData.Codigo := Pair.Key;
        Row.ErpData.Descripcion := Pair.Value.LocalDescripcion;
        Row.Status := ssEliminadoErp;
        Row.Aplicar := False;
        ResList.Add(Row);
      end;

    Result := ResList.ToArray;
  finally
    ErpSeen.Free;
    Locals.Free;
    ResList.Free;
  end;
end;

procedure TErpSyncRepo.ApplyCentro(const ARow: TSyncRowCentro);
var
  Sql: string;
  EmpStr, EsSecStr, MaxLanesStr, CostStr: string;
  FS: TFormatSettings;
  EffectiveSource: string;
begin
  FS := TFormatSettings.Invariant;
  EmpStr := IntToStr(FCodigoEmpresa);
  EsSecStr := IntToStr(Ord(not ARow.ErpData.PermiteConcurrencia));
  if ARow.ErpData.PermiteConcurrencia then
    MaxLanesStr := IntToStr(ARow.ErpData.MaquinasFabricacion)
  else
    MaxLanesStr := '1';
  CostStr := FloatToStr(ARow.ErpData.CosteHoraMaquina, FS);

  if (ARow.Status = ssConflicto) and (ARow.ConflictAction = caMantenerLocal) then
    EffectiveSource := 'MIXED'
  else
    EffectiveSource := 'ERP';

  case ARow.Status of
    ssNuevo:
      begin
        Sql :=
          'INSERT INTO FS_PL_Center (CodigoEmpresa, CodigoCentro, Titulo, ' +
          '  EsSecuencial, MaxLanes, GrupoHorarioCodigo, ' +
          '  Source, ErpSistema, ErpCodigo, ' +
          '  LastErpHash, LastErpSyncAt, CostPerHour) VALUES (' +
          EmpStr + ', ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
          SqlStr(ARow.ErpData.Descripcion) + ', ' +
          EsSecStr + ', ' + MaxLanesStr + ', ' +
          SqlStr(ARow.ErpData.GrupoHorario) + ', ''ERP'', ' +
          SqlStr(FErpSistema) + ', ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
          SqlStr(ARow.NewHash) + ', SYSUTCDATETIME(), ' + CostStr + ')';
        ExecSql(Sql);
      end;

    ssActualizado:
      begin
        Sql :=
          'UPDATE FS_PL_Center SET ' +
          '  Titulo = ' + SqlStr(ARow.ErpData.Descripcion) + ', ' +
          '  EsSecuencial = ' + EsSecStr + ', ' +
          '  MaxLanes = ' + MaxLanesStr + ', ' +
          '  CostPerHour = ' + CostStr + ', ' +
          '  GrupoHorarioCodigo = ' + SqlStr(ARow.ErpData.GrupoHorario) + ', ' +
          '  Source = ''ERP'', ' +
          '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
          '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
          '  LastErpSyncAt = SYSUTCDATETIME() ' +
          'WHERE CodigoEmpresa = ' + EmpStr +
          '  AND CenterId = ' + IntToStr(ARow.LocalCenterId);
        ExecSql(Sql);
      end;

    ssConflicto:
      begin
        case ARow.ConflictAction of
          caAplicarErp:
            begin
              Sql :=
                'UPDATE FS_PL_Center SET ' +
                '  Titulo = ' + SqlStr(ARow.ErpData.Descripcion) + ', ' +
                '  EsSecuencial = ' + EsSecStr + ', ' +
                '  MaxLanes = ' + MaxLanesStr + ', ' +
                '  CostPerHour = ' + CostStr + ', ' +
                '  GrupoHorarioCodigo = ' + SqlStr(ARow.ErpData.GrupoHorario) + ', ' +
                '  Source = ''ERP'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  ErpCodigo = ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND CenterId = ' + IntToStr(ARow.LocalCenterId);
              ExecSql(Sql);
            end;
          caMantenerLocal:
            begin
              Sql :=
                'UPDATE FS_PL_Center SET ' +
                '  Source = ''MIXED'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  ErpCodigo = ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND CenterId = ' + IntToStr(ARow.LocalCenterId);
              ExecSql(Sql);
            end;
        end;
      end;
  end;
end;

procedure TErpSyncRepo.ApplyMaquina(const ARow: TSyncRowMaquina);
var
  Sql: string;
  EmpStr, CostStr, FabStr, ModeloStr, DescStr: string;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  EmpStr := IntToStr(FCodigoEmpresa);
  CostStr := FloatToStr(ARow.ErpData.CosteHoraMaquina, FS);
  FabStr := SqlStr(ARow.ErpData.Marca);
  ModeloStr := SqlStr(ARow.ErpData.Modelo);
  if ARow.ErpData.Descripcion <> '' then
    DescStr := SqlStr(ARow.ErpData.Descripcion)
  else
    DescStr := SqlStr(ARow.ErpData.Marca + ' ' + ARow.ErpData.Modelo);

  case ARow.Status of
    ssNuevo:
      begin
        Sql :=
          'INSERT INTO FS_PL_Maquina (CodigoEmpresa, Codigo, Nombre, ' +
          '  Descripcion, Fabricante, Modelo, CostPerHour, Source, ' +
          '  ErpSistema, ErpCodigo, LastErpHash, LastErpSyncAt) VALUES (' +
          EmpStr + ', ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
          SqlStr(ARow.ErpData.Codigo) + ', ' +
          DescStr + ', ' + FabStr + ', ' + ModeloStr + ', ' + CostStr + ', ' +
          '''ERP'', ' + SqlStr(FErpSistema) + ', ' +
          SqlStr(ARow.ErpData.Codigo) + ', ' + SqlStr(ARow.NewHash) +
          ', SYSUTCDATETIME())';
        ExecSql(Sql);
      end;

    ssActualizado:
      begin
        Sql :=
          'UPDATE FS_PL_Maquina SET ' +
          '  Descripcion = ' + DescStr + ', ' +
          '  Fabricante = ' + FabStr + ', ' +
          '  Modelo = ' + ModeloStr + ', ' +
          '  CostPerHour = ' + CostStr + ', ' +
          '  Source = ''ERP'', ' +
          '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
          '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
          '  LastErpSyncAt = SYSUTCDATETIME() ' +
          'WHERE CodigoEmpresa = ' + EmpStr +
          '  AND MaquinaId = ' + IntToStr(ARow.LocalMaquinaId);
        ExecSql(Sql);
      end;

    ssConflicto:
      begin
        case ARow.ConflictAction of
          caAplicarErp:
            begin
              Sql :=
                'UPDATE FS_PL_Maquina SET ' +
                '  Descripcion = ' + DescStr + ', ' +
                '  Fabricante = ' + FabStr + ', ' +
                '  Modelo = ' + ModeloStr + ', ' +
                '  CostPerHour = ' + CostStr + ', ' +
                '  Source = ''ERP'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  ErpCodigo = ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND MaquinaId = ' + IntToStr(ARow.LocalMaquinaId);
              ExecSql(Sql);
            end;
          caMantenerLocal:
            begin
              Sql :=
                'UPDATE FS_PL_Maquina SET ' +
                '  Source = ''MIXED'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  ErpCodigo = ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND MaquinaId = ' + IntToStr(ARow.LocalMaquinaId);
              ExecSql(Sql);
            end;
        end;
      end;
  end;
end;

function TErpSyncRepo.ApplyCentros(
  const ARows: TArray<TSyncRowCentro>): TSyncSummary;
var
  Row: TSyncRowCentro;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Total := Length(ARows);
  for Row in ARows do
  begin
    case Row.Status of
      ssNuevo:        Inc(Result.Nuevos);
      ssActualizado:  Inc(Result.Actualizados);
      ssSinCambios:   Inc(Result.SinCambios);
      ssConflicto:    Inc(Result.Conflictos);
      ssEliminadoErp: Inc(Result.Eliminados);
      ssError:        Inc(Result.Errores);
    end;
    if Row.Aplicar and (Row.Status in [ssNuevo, ssActualizado, ssConflicto]) then
    begin
      try
        ApplyCentro(Row);
        Inc(Result.Aplicados);
      except
        on E: Exception do
          Inc(Result.Errores);
      end;
    end;
  end;
end;

function TErpSyncRepo.ApplyMaquinas(
  const ARows: TArray<TSyncRowMaquina>): TSyncSummary;
var
  Row: TSyncRowMaquina;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Total := Length(ARows);
  for Row in ARows do
  begin
    case Row.Status of
      ssNuevo:        Inc(Result.Nuevos);
      ssActualizado:  Inc(Result.Actualizados);
      ssSinCambios:   Inc(Result.SinCambios);
      ssConflicto:    Inc(Result.Conflictos);
      ssEliminadoErp: Inc(Result.Eliminados);
      ssError:        Inc(Result.Errores);
    end;
    if Row.Aplicar and (Row.Status in [ssNuevo, ssActualizado, ssConflicto]) then
    begin
      try
        ApplyMaquina(Row);
        Inc(Result.Aplicados);
      except
        on E: Exception do
          Inc(Result.Errores);
      end;
    end;
  end;
end;

{ ---------- Operarios ---------- }

function TErpSyncRepo.HashOperario(const O: TOperarioErp): string;
var
  Buf: string;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  Buf :=
    IntToStr(O.Codigo) + '|' + O.Nombre + '|' +
    FormatDateTime('yyyy-mm-dd', O.FechaAlta, FS) + '|' +
    FormatDateTime('yyyy-mm-dd', O.FechaBaja, FS) + '|' +
    O.Cargo + '|' +
    FloatToStr(O.CosteHoraNormal, FS) + '|' +
    FloatToStr(O.CosteHoraExtra, FS) + '|' +
    IntToStr(O.Turno) + '|' +
    O.GrupoHorario + '|' + O.Telefono + '|' + O.Email;
  Result := THashSHA1.GetHashString(Buf);
end;

procedure TErpSyncRepo.LoadLocalOperariosByErpCodigo(
  out AByErp: TDictionary<string, TSyncRowOperario>);
var
  Q: TADOQuery;
  Row: TSyncRowOperario;
  ErpKey: string;
begin
  AByErp := TDictionary<string, TSyncRowOperario>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT OperatorId, Nombre, ' +
      '       ISNULL(Source, ''MANUAL'') AS Source, ' +
      '       ISNULL(ErpCodigo, '''') AS ErpCodigo, ' +
      '       ISNULL(LastErpHash, '''') AS LastErpHash ' +
      'FROM FS_PL_Operator ' +
      'WHERE CodigoEmpresa = :Emp';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.LocalOperatorId  := Q.FieldByName('OperatorId').AsInteger;
      Row.LocalNombre      := Q.FieldByName('Nombre').AsString;
      Row.LocalSource      := Q.FieldByName('Source').AsString;
      Row.LocalLastErpHash := Q.FieldByName('LastErpHash').AsString;
      ErpKey := Q.FieldByName('ErpCodigo').AsString;
      if ErpKey <> '' then
        AByErp.AddOrSetValue(ErpKey, Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TErpSyncRepo.PreviewOperarios(AReader: IErpReader): TArray<TSyncRowOperario>;
var
  ErpRows: TArray<TOperarioErp>;
  Locals: TDictionary<string, TSyncRowOperario>;
  Row, LocalRow: TSyncRowOperario;
  O: TOperarioErp;
  ErpSeen: TDictionary<string, Boolean>;
  Pair: TPair<string, TSyncRowOperario>;
  ResList: TList<TSyncRowOperario>;
  ErpKey: string;
begin
  ErpRows := AReader.ReadOperarios;
  LoadLocalOperariosByErpCodigo(Locals);
  ErpSeen := TDictionary<string, Boolean>.Create;
  ResList := TList<TSyncRowOperario>.Create;
  try
    for O in ErpRows do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.ErpData := O;
      Row.NewHash := HashOperario(O);
      Row.ConflictAction := caAplicarErp;
      ErpKey := IntToStr(O.Codigo);
      ErpSeen.AddOrSetValue(ErpKey, True);

      if Locals.TryGetValue(ErpKey, LocalRow) then
      begin
        Row.LocalOperatorId  := LocalRow.LocalOperatorId;
        Row.LocalNombre      := LocalRow.LocalNombre;
        Row.LocalSource      := LocalRow.LocalSource;
        Row.LocalLastErpHash := LocalRow.LocalLastErpHash;

        if Row.NewHash = Row.LocalLastErpHash then
        begin
          Row.Status := ssSinCambios;
          Row.Aplicar := False;
        end
        else if SameText(Row.LocalSource, 'ERP') and (Row.LocalLastErpHash <> '') then
        begin
          Row.Status := ssActualizado;
          Row.Aplicar := True;
        end
        else
        begin
          Row.Status := ssConflicto;
          Row.Aplicar := False;
        end;
      end
      else
      begin
        Row.Status := ssNuevo;
        Row.Aplicar := True;
      end;

      ResList.Add(Row);
    end;

    for Pair in Locals do
      if not ErpSeen.ContainsKey(Pair.Key) and
         SameText(Pair.Value.LocalSource, 'ERP') then
      begin
        Row := Pair.Value;
        Row.ErpData.Codigo := StrToIntDef(Pair.Key, 0);
        Row.ErpData.Nombre := Pair.Value.LocalNombre;
        Row.Status := ssEliminadoErp;
        Row.Aplicar := False;
        ResList.Add(Row);
      end;

    Result := ResList.ToArray;
  finally
    ErpSeen.Free;
    Locals.Free;
    ResList.Free;
  end;
end;

procedure TErpSyncRepo.ApplyOperario(const ARow: TSyncRowOperario);
var
  Sql: string;
  EmpStr, CostNStr, CostEStr, TurnoStr: string;
  FAltaStr, FBajaStr: string;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  EmpStr := IntToStr(FCodigoEmpresa);
  CostNStr := FloatToStr(ARow.ErpData.CosteHoraNormal, FS);
  CostEStr := FloatToStr(ARow.ErpData.CosteHoraExtra, FS);
  TurnoStr := IntToStr(ARow.ErpData.Turno);
  if ARow.ErpData.FechaAlta > 0 then
    FAltaStr := '''' + FormatDateTime('yyyy-mm-dd', ARow.ErpData.FechaAlta) + ''''
  else
    FAltaStr := 'NULL';
  if ARow.ErpData.FechaBaja > 0 then
    FBajaStr := '''' + FormatDateTime('yyyy-mm-dd', ARow.ErpData.FechaBaja) + ''''
  else
    FBajaStr := 'NULL';

  case ARow.Status of
    ssNuevo:
      begin
        Sql :=
          'INSERT INTO FS_PL_Operator (CodigoEmpresa, Nombre, Activo, ' +
          '  Cargo, CosteHoraNormal, CosteHoraExtra, GrupoHorarioCodigo, ' +
          '  Telefono, Email, FechaAlta, FechaBaja, ' +
          '  Source, ErpSistema, ErpCodigo, LastErpHash, LastErpSyncAt) VALUES (' +
          EmpStr + ', ' + SqlStr(ARow.ErpData.Nombre) + ', 1, ' +
          SqlStr(ARow.ErpData.Cargo) + ', ' + CostNStr + ', ' + CostEStr + ', ' +
          SqlStr(ARow.ErpData.GrupoHorario) + ', ' +
          SqlStr(ARow.ErpData.Telefono) + ', ' + SqlStr(ARow.ErpData.Email) + ', ' +
          FAltaStr + ', ' + FBajaStr + ', ' +
          '''ERP'', ' + SqlStr(FErpSistema) + ', ' +
          SqlStr(IntToStr(ARow.ErpData.Codigo)) + ', ' +
          SqlStr(ARow.NewHash) + ', SYSUTCDATETIME())';
        ExecSql(Sql);
      end;

    ssActualizado:
      begin
        Sql :=
          'UPDATE FS_PL_Operator SET ' +
          '  Nombre = ' + SqlStr(ARow.ErpData.Nombre) + ', ' +
          '  Cargo = ' + SqlStr(ARow.ErpData.Cargo) + ', ' +
          '  CosteHoraNormal = ' + CostNStr + ', ' +
          '  CosteHoraExtra = ' + CostEStr + ', ' +
          '  GrupoHorarioCodigo = ' + SqlStr(ARow.ErpData.GrupoHorario) + ', ' +
          '  Telefono = ' + SqlStr(ARow.ErpData.Telefono) + ', ' +
          '  Email = ' + SqlStr(ARow.ErpData.Email) + ', ' +
          '  FechaAlta = ' + FAltaStr + ', ' +
          '  FechaBaja = ' + FBajaStr + ', ' +
          '  Source = ''ERP'', ' +
          '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
          '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
          '  LastErpSyncAt = SYSUTCDATETIME() ' +
          'WHERE CodigoEmpresa = ' + EmpStr +
          '  AND OperatorId = ' + IntToStr(ARow.LocalOperatorId);
        ExecSql(Sql);
      end;

    ssConflicto:
      begin
        case ARow.ConflictAction of
          caAplicarErp:
            begin
              Sql :=
                'UPDATE FS_PL_Operator SET ' +
                '  Nombre = ' + SqlStr(ARow.ErpData.Nombre) + ', ' +
                '  Cargo = ' + SqlStr(ARow.ErpData.Cargo) + ', ' +
                '  CosteHoraNormal = ' + CostNStr + ', ' +
                '  CosteHoraExtra = ' + CostEStr + ', ' +
                '  GrupoHorarioCodigo = ' + SqlStr(ARow.ErpData.GrupoHorario) + ', ' +
                '  Telefono = ' + SqlStr(ARow.ErpData.Telefono) + ', ' +
                '  Email = ' + SqlStr(ARow.ErpData.Email) + ', ' +
                '  FechaAlta = ' + FAltaStr + ', ' +
                '  FechaBaja = ' + FBajaStr + ', ' +
                '  Source = ''ERP'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  ErpCodigo = ' + SqlStr(IntToStr(ARow.ErpData.Codigo)) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND OperatorId = ' + IntToStr(ARow.LocalOperatorId);
              ExecSql(Sql);
            end;
          caMantenerLocal:
            begin
              Sql :=
                'UPDATE FS_PL_Operator SET ' +
                '  Source = ''MIXED'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  ErpCodigo = ' + SqlStr(IntToStr(ARow.ErpData.Codigo)) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND OperatorId = ' + IntToStr(ARow.LocalOperatorId);
              ExecSql(Sql);
            end;
        end;
      end;
  end;
end;

function TErpSyncRepo.ApplyOperarios(
  const ARows: TArray<TSyncRowOperario>): TSyncSummary;
var
  Row: TSyncRowOperario;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Total := Length(ARows);
  for Row in ARows do
  begin
    case Row.Status of
      ssNuevo:        Inc(Result.Nuevos);
      ssActualizado:  Inc(Result.Actualizados);
      ssSinCambios:   Inc(Result.SinCambios);
      ssConflicto:    Inc(Result.Conflictos);
      ssEliminadoErp: Inc(Result.Eliminados);
      ssError:        Inc(Result.Errores);
    end;
    if Row.Aplicar and (Row.Status in [ssNuevo, ssActualizado, ssConflicto]) then
    begin
      try
        ApplyOperario(Row);
        Inc(Result.Aplicados);
      except
        on E: Exception do
          Inc(Result.Errores);
      end;
    end;
  end;
end;

{ ---------- CentroMaquina (relacion) ---------- }

function TErpSyncRepo.HashCentroMaquina(const CM: TCentroMaquinaErp): string;
var
  Buf: string;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  Buf :=
    CM.CentroTrabajo + '|' + CM.Maquina + '|' +
    IntToStr(CM.Orden) + '|' +
    FloatToStr(CM.CosteHoraMaquina, FS) + '|' +
    FloatToStr(CM.PorcentajeCorreccionPreparacion, FS) + '|' +
    FloatToStr(CM.PorcentajeCorreccionFabricacion, FS);
  Result := THashSHA1.GetHashString(Buf);
end;

procedure TErpSyncRepo.LoadErpCodeMaps(
  out ACentroMap: TDictionary<string, Integer>;
  out AMaquinaMap: TDictionary<string, Integer>);
var
  Q: TADOQuery;
  K: string;
begin
  ACentroMap := TDictionary<string, Integer>.Create;
  AMaquinaMap := TDictionary<string, Integer>.Create;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT CenterId, ISNULL(ErpCodigo, CodigoCentro) AS K ' +
      'FROM FS_PL_Center WHERE CodigoEmpresa = :Emp';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      K := Q.FieldByName('K').AsString;
      if K <> '' then
        ACentroMap.AddOrSetValue(K, Q.FieldByName('CenterId').AsInteger);
      Q.Next;
    end;
    Q.Close;

    Q.SQL.Text :=
      'SELECT MaquinaId, ISNULL(ErpCodigo, Codigo) AS K ' +
      'FROM FS_PL_Maquina WHERE CodigoEmpresa = :Emp';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      K := Q.FieldByName('K').AsString;
      if K <> '' then
        AMaquinaMap.AddOrSetValue(K, Q.FieldByName('MaquinaId').AsInteger);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TErpSyncRepo.LoadLocalCentroMaquinaByKey(
  out AByKey: TDictionary<string, TSyncRowCentroMaquina>);
var
  Q: TADOQuery;
  Row: TSyncRowCentroMaquina;
  CentroMap, MaquinaMap: TDictionary<string, Integer>;
  CenterId, MaquinaId: Integer;
  CentroErp, MaquinaErp: string;
  Pair: TPair<string, Integer>;
  // Mapas inversos id->ErpCodigo
  CenterIdToErp: TDictionary<Integer, string>;
  MaquinaIdToErp: TDictionary<Integer, string>;
begin
  AByKey := TDictionary<string, TSyncRowCentroMaquina>.Create;
  LoadErpCodeMaps(CentroMap, MaquinaMap);
  CenterIdToErp := TDictionary<Integer, string>.Create;
  MaquinaIdToErp := TDictionary<Integer, string>.Create;
  try
    for Pair in CentroMap do
      CenterIdToErp.AddOrSetValue(Pair.Value, Pair.Key);
    for Pair in MaquinaMap do
      MaquinaIdToErp.AddOrSetValue(Pair.Value, Pair.Key);

    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT CenterId, MaquinaId, ' +
        '       ISNULL(Source, ''MANUAL'') AS Source, ' +
        '       ISNULL(LastErpHash, '''') AS LastErpHash ' +
        'FROM FS_PL_CentroMaquina ' +
        'WHERE CodigoEmpresa = :Emp';
      Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        CenterId := Q.FieldByName('CenterId').AsInteger;
        MaquinaId := Q.FieldByName('MaquinaId').AsInteger;
        if CenterIdToErp.TryGetValue(CenterId, CentroErp) and
           MaquinaIdToErp.TryGetValue(MaquinaId, MaquinaErp) then
        begin
          FillChar(Row, SizeOf(Row), 0);
          Row.LocalCenterId    := CenterId;
          Row.LocalMaquinaId   := MaquinaId;
          Row.LocalSource      := Q.FieldByName('Source').AsString;
          Row.LocalLastErpHash := Q.FieldByName('LastErpHash').AsString;
          AByKey.AddOrSetValue(CentroErp + '|' + MaquinaErp, Row);
        end;
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    CentroMap.Free;
    MaquinaMap.Free;
    CenterIdToErp.Free;
    MaquinaIdToErp.Free;
  end;
end;

function TErpSyncRepo.PreviewCentroMaquina(AReader: IErpReader): TArray<TSyncRowCentroMaquina>;
var
  ErpRows: TArray<TCentroMaquinaErp>;
  Locals: TDictionary<string, TSyncRowCentroMaquina>;
  CentroMap, MaquinaMap: TDictionary<string, Integer>;
  Row, LocalRow: TSyncRowCentroMaquina;
  CM: TCentroMaquinaErp;
  ErpSeen: TDictionary<string, Boolean>;
  Pair: TPair<string, TSyncRowCentroMaquina>;
  ResList: TList<TSyncRowCentroMaquina>;
  Key: string;
  HasCentro, HasMaquina: Boolean;
begin
  ErpRows := AReader.ReadCentrosMaquinas('');
  LoadLocalCentroMaquinaByKey(Locals);
  LoadErpCodeMaps(CentroMap, MaquinaMap);
  ErpSeen := TDictionary<string, Boolean>.Create;
  ResList := TList<TSyncRowCentroMaquina>.Create;
  try
    for CM in ErpRows do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.ErpData := CM;
      Row.NewHash := HashCentroMaquina(CM);
      Row.ConflictAction := caAplicarErp;
      Key := CM.CentroTrabajo + '|' + CM.Maquina;
      ErpSeen.AddOrSetValue(Key, True);

      HasCentro := CentroMap.TryGetValue(CM.CentroTrabajo, Row.LocalCenterId);
      HasMaquina := MaquinaMap.TryGetValue(CM.Maquina, Row.LocalMaquinaId);

      if not (HasCentro and HasMaquina) then
      begin
        Row.Status := ssError;
        if not HasCentro then
          Row.ErrorMsg := 'Centro "' + CM.CentroTrabajo + '" no sincronizado todavia'
        else
          Row.ErrorMsg := 'Maquina "' + CM.Maquina + '" no sincronizada todavia';
        Row.Aplicar := False;
        ResList.Add(Row);
        Continue;
      end;

      if Locals.TryGetValue(Key, LocalRow) then
      begin
        Row.LocalCenterId    := LocalRow.LocalCenterId;
        Row.LocalMaquinaId   := LocalRow.LocalMaquinaId;
        Row.LocalSource      := LocalRow.LocalSource;
        Row.LocalLastErpHash := LocalRow.LocalLastErpHash;

        if Row.NewHash = Row.LocalLastErpHash then
        begin
          Row.Status := ssSinCambios;
          Row.Aplicar := False;
        end
        else if SameText(Row.LocalSource, 'ERP') and (Row.LocalLastErpHash <> '') then
        begin
          Row.Status := ssActualizado;
          Row.Aplicar := True;
        end
        else
        begin
          Row.Status := ssConflicto;
          Row.Aplicar := False;
        end;
      end
      else
      begin
        Row.Status := ssNuevo;
        Row.Aplicar := True;
      end;

      ResList.Add(Row);
    end;

    for Pair in Locals do
      if not ErpSeen.ContainsKey(Pair.Key) and
         SameText(Pair.Value.LocalSource, 'ERP') then
      begin
        Row := Pair.Value;
        Row.Status := ssEliminadoErp;
        Row.Aplicar := False;
        ResList.Add(Row);
      end;

    Result := ResList.ToArray;
  finally
    ErpSeen.Free;
    Locals.Free;
    CentroMap.Free;
    MaquinaMap.Free;
    ResList.Free;
  end;
end;

procedure TErpSyncRepo.ApplyCentroMaquinaRow(const ARow: TSyncRowCentroMaquina);
var
  Sql, EmpStr, OrdenStr, CostStr, CorrPStr, CorrFStr: string;
  FS: TFormatSettings;
begin
  if (ARow.LocalCenterId <= 0) or (ARow.LocalMaquinaId <= 0) then
    Exit;
  FS := TFormatSettings.Invariant;
  EmpStr := IntToStr(FCodigoEmpresa);
  OrdenStr := IntToStr(ARow.ErpData.Orden);
  CostStr := FloatToStr(ARow.ErpData.CosteHoraMaquina, FS);
  CorrPStr := FloatToStr(ARow.ErpData.PorcentajeCorreccionPreparacion, FS);
  CorrFStr := FloatToStr(ARow.ErpData.PorcentajeCorreccionFabricacion, FS);

  case ARow.Status of
    ssNuevo:
      begin
        Sql :=
          'INSERT INTO FS_PL_CentroMaquina (CodigoEmpresa, CenterId, MaquinaId, ' +
          '  OrdenErp, CostPerHour, PorcentajeCorreccionPrep, PorcentajeCorreccionFab, ' +
          '  Source, ErpSistema, LastErpHash, LastErpSyncAt) VALUES (' +
          EmpStr + ', ' + IntToStr(ARow.LocalCenterId) + ', ' + IntToStr(ARow.LocalMaquinaId) + ', ' +
          OrdenStr + ', ' + CostStr + ', ' + CorrPStr + ', ' + CorrFStr + ', ' +
          '''ERP'', ' + SqlStr(FErpSistema) + ', ' + SqlStr(ARow.NewHash) + ', SYSUTCDATETIME())';
        ExecSql(Sql);
      end;

    ssActualizado:
      begin
        Sql :=
          'UPDATE FS_PL_CentroMaquina SET ' +
          '  OrdenErp = ' + OrdenStr + ', ' +
          '  CostPerHour = ' + CostStr + ', ' +
          '  PorcentajeCorreccionPrep = ' + CorrPStr + ', ' +
          '  PorcentajeCorreccionFab = ' + CorrFStr + ', ' +
          '  Source = ''ERP'', ' +
          '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
          '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
          '  LastErpSyncAt = SYSUTCDATETIME() ' +
          'WHERE CodigoEmpresa = ' + EmpStr +
          '  AND CenterId = ' + IntToStr(ARow.LocalCenterId) +
          '  AND MaquinaId = ' + IntToStr(ARow.LocalMaquinaId);
        ExecSql(Sql);
      end;

    ssConflicto:
      begin
        case ARow.ConflictAction of
          caAplicarErp:
            begin
              Sql :=
                'UPDATE FS_PL_CentroMaquina SET ' +
                '  OrdenErp = ' + OrdenStr + ', ' +
                '  CostPerHour = ' + CostStr + ', ' +
                '  PorcentajeCorreccionPrep = ' + CorrPStr + ', ' +
                '  PorcentajeCorreccionFab = ' + CorrFStr + ', ' +
                '  Source = ''ERP'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND CenterId = ' + IntToStr(ARow.LocalCenterId) +
                '  AND MaquinaId = ' + IntToStr(ARow.LocalMaquinaId);
              ExecSql(Sql);
            end;
          caMantenerLocal:
            begin
              Sql :=
                'UPDATE FS_PL_CentroMaquina SET ' +
                '  Source = ''MIXED'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND CenterId = ' + IntToStr(ARow.LocalCenterId) +
                '  AND MaquinaId = ' + IntToStr(ARow.LocalMaquinaId);
              ExecSql(Sql);
            end;
        end;
      end;
  end;
end;

function TErpSyncRepo.ApplyCentroMaquina(
  const ARows: TArray<TSyncRowCentroMaquina>): TSyncSummary;
var
  Row: TSyncRowCentroMaquina;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Total := Length(ARows);
  for Row in ARows do
  begin
    case Row.Status of
      ssNuevo:        Inc(Result.Nuevos);
      ssActualizado:  Inc(Result.Actualizados);
      ssSinCambios:   Inc(Result.SinCambios);
      ssConflicto:    Inc(Result.Conflictos);
      ssEliminadoErp: Inc(Result.Eliminados);
      ssError:        Inc(Result.Errores);
    end;
    if Row.Aplicar and (Row.Status in [ssNuevo, ssActualizado, ssConflicto]) then
    begin
      try
        ApplyCentroMaquinaRow(Row);
        Inc(Result.Aplicados);
      except
        on E: Exception do
          Inc(Result.Errores);
      end;
    end;
  end;
end;

{ ---------- ShiftModels ---------- }

function TErpSyncRepo.HashShiftModel(const M: TModeloHorarioErp;
  const L: TArray<TLineaModeloHorarioErp>): string;
var
  Buf: string;
  FS: TFormatSettings;
  Ln: TLineaModeloHorarioErp;
begin
  FS := TFormatSettings.Invariant;
  Buf := IntToStr(M.Codigo) + '|' + M.Descripcion;
  for Ln in L do
    Buf := Buf + '|' + IntToStr(Ln.Orden) + ':' +
      FloatToStr(Ln.HoraInicio, FS) + '-' + FloatToStr(Ln.HoraFinal, FS);
  Result := THashSHA1.GetHashString(Buf);
end;

function TErpSyncRepo.GetErpCalendarId: Integer;
var
  Q: TADOQuery;
begin
  Result := 0;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT TOP 1 CalendarId FROM FS_PL_Calendar ' +
      'WHERE CodigoEmpresa = :Emp AND Nombre = ''ERP''';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    if not Q.Eof then
      Result := Q.FieldByName('CalendarId').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TErpSyncRepo.LoadLocalShiftModelsByErpCodigo(
  out AByErp: TDictionary<string, TSyncRowShiftModel>);
var
  Q: TADOQuery;
  Row: TSyncRowShiftModel;
  ErpKey: string;
begin
  AByErp := TDictionary<string, TSyncRowShiftModel>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT ShiftModelId, Nombre, ' +
      '       ISNULL(Source, ''MANUAL'') AS Source, ' +
      '       ISNULL(ErpCodigo, '''') AS ErpCodigo, ' +
      '       ISNULL(LastErpHash, '''') AS LastErpHash ' +
      'FROM FS_PL_ShiftModel ' +
      'WHERE CodigoEmpresa = :Emp';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.LocalShiftModelId := Q.FieldByName('ShiftModelId').AsInteger;
      Row.LocalNombre       := Q.FieldByName('Nombre').AsString;
      Row.LocalSource       := Q.FieldByName('Source').AsString;
      Row.LocalLastErpHash  := Q.FieldByName('LastErpHash').AsString;
      ErpKey := Q.FieldByName('ErpCodigo').AsString;
      if ErpKey <> '' then
        AByErp.AddOrSetValue(ErpKey, Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TErpSyncRepo.PreviewShiftModels(AReader: IErpReader): TArray<TSyncRowShiftModel>;
var
  ErpModelos: TArray<TModeloHorarioErp>;
  Locals: TDictionary<string, TSyncRowShiftModel>;
  Row, LocalRow: TSyncRowShiftModel;
  M: TModeloHorarioErp;
  ErpSeen: TDictionary<string, Boolean>;
  Pair: TPair<string, TSyncRowShiftModel>;
  ResList: TList<TSyncRowShiftModel>;
  ErpKey: string;
begin
  ErpModelos := AReader.ReadModelosHorarios;
  LoadLocalShiftModelsByErpCodigo(Locals);
  ErpSeen := TDictionary<string, Boolean>.Create;
  ResList := TList<TSyncRowShiftModel>.Create;
  try
    for M in ErpModelos do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.ErpModelo := M;
      Row.ErpLineas := AReader.ReadLineasModeloHorario(M.Codigo);
      Row.NumLineas := Length(Row.ErpLineas);
      Row.NewHash := HashShiftModel(M, Row.ErpLineas);
      Row.ConflictAction := caAplicarErp;
      ErpKey := IntToStr(M.Codigo);
      ErpSeen.AddOrSetValue(ErpKey, True);

      if Locals.TryGetValue(ErpKey, LocalRow) then
      begin
        Row.LocalShiftModelId := LocalRow.LocalShiftModelId;
        Row.LocalNombre       := LocalRow.LocalNombre;
        Row.LocalSource       := LocalRow.LocalSource;
        Row.LocalLastErpHash  := LocalRow.LocalLastErpHash;

        if Row.NewHash = Row.LocalLastErpHash then
        begin
          Row.Status := ssSinCambios;
          Row.Aplicar := False;
        end
        else if SameText(Row.LocalSource, 'ERP') and (Row.LocalLastErpHash <> '') then
        begin
          Row.Status := ssActualizado;
          Row.Aplicar := True;
        end
        else
        begin
          Row.Status := ssConflicto;
          Row.Aplicar := False;
        end;
      end
      else
      begin
        Row.Status := ssNuevo;
        Row.Aplicar := True;
      end;

      ResList.Add(Row);
    end;

    for Pair in Locals do
      if not ErpSeen.ContainsKey(Pair.Key) and
         SameText(Pair.Value.LocalSource, 'ERP') then
      begin
        Row := Pair.Value;
        Row.ErpModelo.Codigo := StrToIntDef(Pair.Key, 0);
        Row.ErpModelo.Descripcion := Pair.Value.LocalNombre;
        Row.Status := ssEliminadoErp;
        Row.Aplicar := False;
        ResList.Add(Row);
      end;

    Result := ResList.ToArray;
  finally
    ErpSeen.Free;
    Locals.Free;
    ResList.Free;
  end;
end;

procedure TErpSyncRepo.ApplyShiftModel(const ARow: TSyncRowShiftModel);
var
  Sql, EmpStr, CalStr, NombreStr, EmpresaInt: string;
  CalId, ModelId: Integer;
  Q: TADOQuery;
  Ln: TLineaModeloHorarioErp;
  Dia: Integer;
  function FloatHourToTime(H: Double): string;
  var
    Hh, Mm: Integer;
  begin
    if H < 0 then H := 0;
    if H >= 24 then H := 23.9833;
    Hh := Trunc(H);
    Mm := Round((H - Hh) * 60);
    if Mm = 60 then begin Mm := 0; Inc(Hh); end;
    Result := Format('''%2.2d:%2.2d:00''', [Hh, Mm]);
  end;
begin
  EmpresaInt := IntToStr(FCodigoEmpresa);
  CalId := GetErpCalendarId;
  if CalId = 0 then
    raise Exception.Create('Calendario "ERP" no existe. Ejecuta la V038.');
  CalStr := IntToStr(CalId);
  NombreStr := ARow.ErpModelo.Descripcion;
  if NombreStr = '' then
    NombreStr := 'Modelo ' + IntToStr(ARow.ErpModelo.Codigo);

  case ARow.Status of
    ssNuevo:
      begin
        Sql :=
          'INSERT INTO FS_PL_ShiftModel (CodigoEmpresa, CalendarId, Nombre, ' +
          '  Descripcion, EsDefault, Activo, Source, ErpSistema, ErpCodigo, ' +
          '  LastErpHash, LastErpSyncAt) VALUES (' +
          EmpresaInt + ', ' + CalStr + ', ' + SqlStr(NombreStr) + ', ' +
          SqlStr(ARow.ErpModelo.Descripcion) + ', 0, 1, ''ERP'', ' +
          SqlStr(FErpSistema) + ', ' + SqlStr(IntToStr(ARow.ErpModelo.Codigo)) + ', ' +
          SqlStr(ARow.NewHash) + ', SYSUTCDATETIME())';
        ExecSql(Sql);
        // Obtener el ShiftModelId nuevo
        Q := TADOQuery.Create(nil);
        try
          Q.Connection := FConnection;
          Q.SQL.Text :=
            'SELECT ShiftModelId FROM FS_PL_ShiftModel ' +
            'WHERE CodigoEmpresa = :E AND ErpCodigo = :C';
          Q.Parameters.ParamByName('E').Value := FCodigoEmpresa;
          Q.Parameters.ParamByName('C').Value := IntToStr(ARow.ErpModelo.Codigo);
          Q.Open;
          if Q.Eof then Exit;
          ModelId := Q.FieldByName('ShiftModelId').AsInteger;
        finally
          Q.Free;
        end;
      end;

    ssActualizado, ssConflicto:
      begin
        if (ARow.Status = ssConflicto) and (ARow.ConflictAction = caMantenerLocal) then
        begin
          // Solo refrescar metadata
          Sql :=
            'UPDATE FS_PL_ShiftModel SET ' +
            '  Source = ''MIXED'', ' +
            '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
            '  ErpCodigo = ' + SqlStr(IntToStr(ARow.ErpModelo.Codigo)) + ', ' +
            '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
            '  LastErpSyncAt = SYSUTCDATETIME() ' +
            'WHERE CodigoEmpresa = ' + EmpresaInt +
            '  AND ShiftModelId = ' + IntToStr(ARow.LocalShiftModelId);
          ExecSql(Sql);
          Exit;
        end;
        // Conflicto+AplicarErp o Actualizado: sobreescribir cabecera + reemplazar lineas
        ModelId := ARow.LocalShiftModelId;
        Sql :=
          'UPDATE FS_PL_ShiftModel SET ' +
          '  Nombre = ' + SqlStr(NombreStr) + ', ' +
          '  Descripcion = ' + SqlStr(ARow.ErpModelo.Descripcion) + ', ' +
          '  Source = ''ERP'', ' +
          '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
          '  ErpCodigo = ' + SqlStr(IntToStr(ARow.ErpModelo.Codigo)) + ', ' +
          '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
          '  LastErpSyncAt = SYSUTCDATETIME() ' +
          'WHERE CodigoEmpresa = ' + EmpresaInt +
          '  AND ShiftModelId = ' + IntToStr(ModelId);
        ExecSql(Sql);
        ExecSql('DELETE FROM FS_PL_ShiftModelLine WHERE CodigoEmpresa = ' +
          EmpresaInt + ' AND ShiftModelId = ' + IntToStr(ModelId));
      end;
  else
    Exit;
  end;

  // Generar lineas: las franjas del ERP las replicamos a los 7 dias
  // (Sage no asocia el modelo a dias concretos; eso vive en CalendarioCentro).
  for Dia := 1 to 7 do
    for Ln in ARow.ErpLineas do
    begin
      if Ln.HoraFinal <= Ln.HoraInicio then Continue;
      Sql :=
        'INSERT INTO FS_PL_ShiftModelLine (CodigoEmpresa, ShiftModelId, ' +
        '  DiaSemana, HoraInicio, HoraFin) VALUES (' +
        EmpresaInt + ', ' + IntToStr(ModelId) + ', ' + IntToStr(Dia) + ', ' +
        FloatHourToTime(Ln.HoraInicio) + ', ' + FloatHourToTime(Ln.HoraFinal) + ')';
      ExecSql(Sql);
    end;
end;

function TErpSyncRepo.ApplyShiftModels(
  const ARows: TArray<TSyncRowShiftModel>): TSyncSummary;
var
  Row: TSyncRowShiftModel;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Total := Length(ARows);
  for Row in ARows do
  begin
    case Row.Status of
      ssNuevo:        Inc(Result.Nuevos);
      ssActualizado:  Inc(Result.Actualizados);
      ssSinCambios:   Inc(Result.SinCambios);
      ssConflicto:    Inc(Result.Conflictos);
      ssEliminadoErp: Inc(Result.Eliminados);
      ssError:        Inc(Result.Errores);
    end;
    if Row.Aplicar and (Row.Status in [ssNuevo, ssActualizado, ssConflicto]) then
    begin
      try
        ApplyShiftModel(Row);
        Inc(Result.Aplicados);
      except
        on E: Exception do
          Inc(Result.Errores);
      end;
    end;
  end;
end;

{ ---------- Almacenes ---------- }

function TErpSyncRepo.HashAlmacen(const A: TAlmacenErp): string;
var
  Buf: string;
begin
  Buf := A.Codigo + '|' + A.Nombre + '|' + A.GrupoAlmacen + '|' +
    A.Responsable + '|' + A.Domicilio + '|' + A.CodigoPostal + '|' +
    A.Municipio + '|' + A.Provincia + '|' + A.Telefono;
  Result := THashSHA1.GetHashString(Buf);
end;

procedure TErpSyncRepo.LoadLocalAlmacenesByErpCodigo(
  out AByErp: TDictionary<string, TSyncRowAlmacen>);
var
  Q: TADOQuery;
  Row: TSyncRowAlmacen;
  ErpKey: string;
begin
  AByErp := TDictionary<string, TSyncRowAlmacen>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT AlmacenId, Codigo, Nombre, ' +
      '       ISNULL(Source, ''MANUAL'') AS Source, ' +
      '       ISNULL(ErpCodigo, '''') AS ErpCodigo, ' +
      '       ISNULL(LastErpHash, '''') AS LastErpHash ' +
      'FROM FS_PL_Almacen ' +
      'WHERE CodigoEmpresa = :Emp';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.LocalAlmacenId   := Q.FieldByName('AlmacenId').AsInteger;
      Row.LocalNombre      := Q.FieldByName('Nombre').AsString;
      Row.LocalSource      := Q.FieldByName('Source').AsString;
      Row.LocalLastErpHash := Q.FieldByName('LastErpHash').AsString;
      ErpKey := Q.FieldByName('ErpCodigo').AsString;
      if ErpKey = '' then
        ErpKey := Q.FieldByName('Codigo').AsString;
      AByErp.AddOrSetValue(ErpKey, Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TErpSyncRepo.PreviewAlmacenes(AReader: IErpReader): TArray<TSyncRowAlmacen>;
var
  ErpRows: TArray<TAlmacenErp>;
  Locals: TDictionary<string, TSyncRowAlmacen>;
  Row, LocalRow: TSyncRowAlmacen;
  A: TAlmacenErp;
  ErpSeen: TDictionary<string, Boolean>;
  Pair: TPair<string, TSyncRowAlmacen>;
  ResList: TList<TSyncRowAlmacen>;
begin
  ErpRows := AReader.ReadAlmacenes;
  LoadLocalAlmacenesByErpCodigo(Locals);
  ErpSeen := TDictionary<string, Boolean>.Create;
  ResList := TList<TSyncRowAlmacen>.Create;
  try
    for A in ErpRows do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.ErpData := A;
      Row.NewHash := HashAlmacen(A);
      Row.ConflictAction := caAplicarErp;
      ErpSeen.AddOrSetValue(A.Codigo, True);

      if Locals.TryGetValue(A.Codigo, LocalRow) then
      begin
        Row.LocalAlmacenId   := LocalRow.LocalAlmacenId;
        Row.LocalNombre      := LocalRow.LocalNombre;
        Row.LocalSource      := LocalRow.LocalSource;
        Row.LocalLastErpHash := LocalRow.LocalLastErpHash;

        if Row.NewHash = Row.LocalLastErpHash then
        begin
          Row.Status := ssSinCambios;
          Row.Aplicar := False;
        end
        else if SameText(Row.LocalSource, 'ERP') and (Row.LocalLastErpHash <> '') then
        begin
          Row.Status := ssActualizado;
          Row.Aplicar := True;
        end
        else
        begin
          Row.Status := ssConflicto;
          Row.Aplicar := False;
        end;
      end
      else
      begin
        Row.Status := ssNuevo;
        Row.Aplicar := True;
      end;

      ResList.Add(Row);
    end;

    for Pair in Locals do
      if not ErpSeen.ContainsKey(Pair.Key) and
         SameText(Pair.Value.LocalSource, 'ERP') then
      begin
        Row := Pair.Value;
        Row.ErpData.Codigo := Pair.Key;
        Row.ErpData.Nombre := Pair.Value.LocalNombre;
        Row.Status := ssEliminadoErp;
        Row.Aplicar := False;
        ResList.Add(Row);
      end;

    Result := ResList.ToArray;
  finally
    ErpSeen.Free;
    Locals.Free;
    ResList.Free;
  end;
end;

procedure TErpSyncRepo.ApplyAlmacen(const ARow: TSyncRowAlmacen);
var
  Sql, EmpStr: string;
begin
  EmpStr := IntToStr(FCodigoEmpresa);

  case ARow.Status of
    ssNuevo:
      begin
        Sql :=
          'INSERT INTO FS_PL_Almacen (CodigoEmpresa, Codigo, Nombre, ' +
          '  Direccion, GrupoAlmacen, Responsable, CodigoPostal, Municipio, ' +
          '  Provincia, Telefono, Activo, ' +
          '  Source, ErpSistema, ErpCodigo, LastErpHash, LastErpSyncAt) VALUES (' +
          EmpStr + ', ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
          SqlStr(ARow.ErpData.Nombre) + ', ' + SqlStr(ARow.ErpData.Domicilio) + ', ' +
          SqlStr(ARow.ErpData.GrupoAlmacen) + ', ' + SqlStr(ARow.ErpData.Responsable) + ', ' +
          SqlStr(ARow.ErpData.CodigoPostal) + ', ' + SqlStr(ARow.ErpData.Municipio) + ', ' +
          SqlStr(ARow.ErpData.Provincia) + ', ' + SqlStr(ARow.ErpData.Telefono) + ', 1, ' +
          '''ERP'', ' + SqlStr(FErpSistema) + ', ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
          SqlStr(ARow.NewHash) + ', SYSUTCDATETIME())';
        ExecSql(Sql);
      end;

    ssActualizado:
      begin
        Sql :=
          'UPDATE FS_PL_Almacen SET ' +
          '  Nombre = ' + SqlStr(ARow.ErpData.Nombre) + ', ' +
          '  Direccion = ' + SqlStr(ARow.ErpData.Domicilio) + ', ' +
          '  GrupoAlmacen = ' + SqlStr(ARow.ErpData.GrupoAlmacen) + ', ' +
          '  Responsable = ' + SqlStr(ARow.ErpData.Responsable) + ', ' +
          '  CodigoPostal = ' + SqlStr(ARow.ErpData.CodigoPostal) + ', ' +
          '  Municipio = ' + SqlStr(ARow.ErpData.Municipio) + ', ' +
          '  Provincia = ' + SqlStr(ARow.ErpData.Provincia) + ', ' +
          '  Telefono = ' + SqlStr(ARow.ErpData.Telefono) + ', ' +
          '  Source = ''ERP'', ' +
          '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
          '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
          '  LastErpSyncAt = SYSUTCDATETIME() ' +
          'WHERE CodigoEmpresa = ' + EmpStr +
          '  AND AlmacenId = ' + IntToStr(ARow.LocalAlmacenId);
        ExecSql(Sql);
      end;

    ssConflicto:
      begin
        case ARow.ConflictAction of
          caAplicarErp:
            begin
              Sql :=
                'UPDATE FS_PL_Almacen SET ' +
                '  Nombre = ' + SqlStr(ARow.ErpData.Nombre) + ', ' +
                '  Direccion = ' + SqlStr(ARow.ErpData.Domicilio) + ', ' +
                '  GrupoAlmacen = ' + SqlStr(ARow.ErpData.GrupoAlmacen) + ', ' +
                '  Responsable = ' + SqlStr(ARow.ErpData.Responsable) + ', ' +
                '  CodigoPostal = ' + SqlStr(ARow.ErpData.CodigoPostal) + ', ' +
                '  Municipio = ' + SqlStr(ARow.ErpData.Municipio) + ', ' +
                '  Provincia = ' + SqlStr(ARow.ErpData.Provincia) + ', ' +
                '  Telefono = ' + SqlStr(ARow.ErpData.Telefono) + ', ' +
                '  Source = ''ERP'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  ErpCodigo = ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND AlmacenId = ' + IntToStr(ARow.LocalAlmacenId);
              ExecSql(Sql);
            end;
          caMantenerLocal:
            begin
              Sql :=
                'UPDATE FS_PL_Almacen SET ' +
                '  Source = ''MIXED'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  ErpCodigo = ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND AlmacenId = ' + IntToStr(ARow.LocalAlmacenId);
              ExecSql(Sql);
            end;
        end;
      end;
  end;
end;

function TErpSyncRepo.ApplyAlmacenes(
  const ARows: TArray<TSyncRowAlmacen>): TSyncSummary;
var
  Row: TSyncRowAlmacen;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Total := Length(ARows);
  for Row in ARows do
  begin
    case Row.Status of
      ssNuevo:        Inc(Result.Nuevos);
      ssActualizado:  Inc(Result.Actualizados);
      ssSinCambios:   Inc(Result.SinCambios);
      ssConflicto:    Inc(Result.Conflictos);
      ssEliminadoErp: Inc(Result.Eliminados);
      ssError:        Inc(Result.Errores);
    end;
    if Row.Aplicar and (Row.Status in [ssNuevo, ssActualizado, ssConflicto]) then
    begin
      try
        ApplyAlmacen(Row);
        Inc(Result.Aplicados);
      except
        on E: Exception do
          Inc(Result.Errores);
      end;
    end;
  end;
end;

{ ---------- Familias ---------- }

function TErpSyncRepo.HashFamilia(const F: TFamiliaErp): string;
var
  Buf: string;
begin
  Buf := F.CodigoFamilia + '|' + F.CodigoSubfamilia + '|' + F.Descripcion + '|' +
    F.TipoF + '|' + F.CodigoSeccion + '|' + F.CodigoDepartamento;
  Result := THashSHA1.GetHashString(Buf);
end;

procedure TErpSyncRepo.LoadLocalFamiliasByErpCodigo(
  out AByErp: TDictionary<string, TSyncRowFamilia>);
var
  Q: TADOQuery;
  Row: TSyncRowFamilia;
  ErpKey: string;
begin
  AByErp := TDictionary<string, TSyncRowFamilia>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT FamiliaId, CodigoFamilia, CodigoSubfamilia, Descripcion, ' +
      '       ISNULL(Source, ''MANUAL'') AS Source, ' +
      '       ISNULL(ErpCodigo, '''') AS ErpCodigo, ' +
      '       ISNULL(LastErpHash, '''') AS LastErpHash ' +
      'FROM FS_PL_Familia ' +
      'WHERE CodigoEmpresa = :Emp';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.LocalFamiliaId   := Q.FieldByName('FamiliaId').AsInteger;
      Row.LocalDescripcion := Q.FieldByName('Descripcion').AsString;
      Row.LocalSource      := Q.FieldByName('Source').AsString;
      Row.LocalLastErpHash := Q.FieldByName('LastErpHash').AsString;
      ErpKey := Q.FieldByName('ErpCodigo').AsString;
      if ErpKey = '' then
        ErpKey := Q.FieldByName('CodigoFamilia').AsString + '|' +
                  Q.FieldByName('CodigoSubfamilia').AsString;
      AByErp.AddOrSetValue(ErpKey, Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TErpSyncRepo.PreviewFamilias(AReader: IErpReader): TArray<TSyncRowFamilia>;
var
  ErpRows: TArray<TFamiliaErp>;
  Locals: TDictionary<string, TSyncRowFamilia>;
  Row, LocalRow: TSyncRowFamilia;
  F: TFamiliaErp;
  ErpSeen: TDictionary<string, Boolean>;
  Pair: TPair<string, TSyncRowFamilia>;
  ResList: TList<TSyncRowFamilia>;
  ErpKey: string;
  FamPart, SubPart: string;
  PipePos: Integer;
begin
  ErpRows := AReader.ReadFamilias;
  LoadLocalFamiliasByErpCodigo(Locals);
  ErpSeen := TDictionary<string, Boolean>.Create;
  ResList := TList<TSyncRowFamilia>.Create;
  try
    for F in ErpRows do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.ErpData := F;
      Row.NewHash := HashFamilia(F);
      Row.ConflictAction := caAplicarErp;
      ErpKey := F.CodigoFamilia + '|' + F.CodigoSubfamilia;
      ErpSeen.AddOrSetValue(ErpKey, True);

      if Locals.TryGetValue(ErpKey, LocalRow) then
      begin
        Row.LocalFamiliaId   := LocalRow.LocalFamiliaId;
        Row.LocalDescripcion := LocalRow.LocalDescripcion;
        Row.LocalSource      := LocalRow.LocalSource;
        Row.LocalLastErpHash := LocalRow.LocalLastErpHash;

        if Row.NewHash = Row.LocalLastErpHash then
        begin
          Row.Status := ssSinCambios;
          Row.Aplicar := False;
        end
        else if SameText(Row.LocalSource, 'ERP') and (Row.LocalLastErpHash <> '') then
        begin
          Row.Status := ssActualizado;
          Row.Aplicar := True;
        end
        else
        begin
          Row.Status := ssConflicto;
          Row.Aplicar := False;
        end;
      end
      else
      begin
        Row.Status := ssNuevo;
        Row.Aplicar := True;
      end;

      ResList.Add(Row);
    end;

    for Pair in Locals do
      if not ErpSeen.ContainsKey(Pair.Key) and
         SameText(Pair.Value.LocalSource, 'ERP') then
      begin
        Row := Pair.Value;
        PipePos := Pos('|', Pair.Key);
        if PipePos > 0 then
        begin
          FamPart := Copy(Pair.Key, 1, PipePos - 1);
          SubPart := Copy(Pair.Key, PipePos + 1, MaxInt);
        end
        else
        begin
          FamPart := Pair.Key;
          SubPart := '';
        end;
        Row.ErpData.CodigoFamilia := FamPart;
        Row.ErpData.CodigoSubfamilia := SubPart;
        Row.ErpData.Descripcion := Pair.Value.LocalDescripcion;
        Row.Status := ssEliminadoErp;
        Row.Aplicar := False;
        ResList.Add(Row);
      end;

    Result := ResList.ToArray;
  finally
    ErpSeen.Free;
    Locals.Free;
    ResList.Free;
  end;
end;

procedure TErpSyncRepo.ApplyFamilia(const ARow: TSyncRowFamilia);
var
  Sql, EmpStr, ErpKey: string;
begin
  EmpStr := IntToStr(FCodigoEmpresa);
  ErpKey := ARow.ErpData.CodigoFamilia + '|' + ARow.ErpData.CodigoSubfamilia;

  case ARow.Status of
    ssNuevo:
      begin
        Sql :=
          'INSERT INTO FS_PL_Familia (CodigoEmpresa, CodigoFamilia, ' +
          '  CodigoSubfamilia, Descripcion, TipoF, CodigoSeccion, ' +
          '  CodigoDepartamento, Activo, ' +
          '  Source, ErpSistema, ErpCodigo, LastErpHash, LastErpSyncAt) VALUES (' +
          EmpStr + ', ' + SqlStr(ARow.ErpData.CodigoFamilia) + ', ' +
          SqlStr(ARow.ErpData.CodigoSubfamilia) + ', ' +
          SqlStr(ARow.ErpData.Descripcion) + ', ' +
          SqlStr(ARow.ErpData.TipoF) + ', ' +
          SqlStr(ARow.ErpData.CodigoSeccion) + ', ' +
          SqlStr(ARow.ErpData.CodigoDepartamento) + ', 1, ' +
          '''ERP'', ' + SqlStr(FErpSistema) + ', ' + SqlStr(ErpKey) + ', ' +
          SqlStr(ARow.NewHash) + ', SYSUTCDATETIME())';
        ExecSql(Sql);
      end;

    ssActualizado:
      begin
        Sql :=
          'UPDATE FS_PL_Familia SET ' +
          '  Descripcion = ' + SqlStr(ARow.ErpData.Descripcion) + ', ' +
          '  TipoF = ' + SqlStr(ARow.ErpData.TipoF) + ', ' +
          '  CodigoSeccion = ' + SqlStr(ARow.ErpData.CodigoSeccion) + ', ' +
          '  CodigoDepartamento = ' + SqlStr(ARow.ErpData.CodigoDepartamento) + ', ' +
          '  Source = ''ERP'', ' +
          '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
          '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
          '  LastErpSyncAt = SYSUTCDATETIME() ' +
          'WHERE CodigoEmpresa = ' + EmpStr +
          '  AND FamiliaId = ' + IntToStr(ARow.LocalFamiliaId);
        ExecSql(Sql);
      end;

    ssConflicto:
      begin
        case ARow.ConflictAction of
          caAplicarErp:
            begin
              Sql :=
                'UPDATE FS_PL_Familia SET ' +
                '  Descripcion = ' + SqlStr(ARow.ErpData.Descripcion) + ', ' +
                '  TipoF = ' + SqlStr(ARow.ErpData.TipoF) + ', ' +
                '  CodigoSeccion = ' + SqlStr(ARow.ErpData.CodigoSeccion) + ', ' +
                '  CodigoDepartamento = ' + SqlStr(ARow.ErpData.CodigoDepartamento) + ', ' +
                '  Source = ''ERP'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  ErpCodigo = ' + SqlStr(ErpKey) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND FamiliaId = ' + IntToStr(ARow.LocalFamiliaId);
              ExecSql(Sql);
            end;
          caMantenerLocal:
            begin
              Sql :=
                'UPDATE FS_PL_Familia SET ' +
                '  Source = ''MIXED'', ' +
                '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
                '  ErpCodigo = ' + SqlStr(ErpKey) + ', ' +
                '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
                '  LastErpSyncAt = SYSUTCDATETIME() ' +
                'WHERE CodigoEmpresa = ' + EmpStr +
                '  AND FamiliaId = ' + IntToStr(ARow.LocalFamiliaId);
              ExecSql(Sql);
            end;
        end;
      end;
  end;
end;

function TErpSyncRepo.ApplyFamilias(
  const ARows: TArray<TSyncRowFamilia>): TSyncSummary;
var
  Row: TSyncRowFamilia;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Total := Length(ARows);
  for Row in ARows do
  begin
    case Row.Status of
      ssNuevo:        Inc(Result.Nuevos);
      ssActualizado:  Inc(Result.Actualizados);
      ssSinCambios:   Inc(Result.SinCambios);
      ssConflicto:    Inc(Result.Conflictos);
      ssEliminadoErp: Inc(Result.Eliminados);
      ssError:        Inc(Result.Errores);
    end;
    if Row.Aplicar and (Row.Status in [ssNuevo, ssActualizado, ssConflicto]) then
    begin
      try
        ApplyFamilia(Row);
        Inc(Result.Aplicados);
      except
        on E: Exception do
          Inc(Result.Errores);
      end;
    end;
  end;
end;

{ ---------- Calendarios (per GrupoHorario) ---------- }

procedure TErpSyncRepo.LoadLocalCalendariosByErpCodigo(
  out AByErp: TDictionary<string, TSyncRowCalendario>);
var
  Q: TADOQuery;
  Row: TSyncRowCalendario;
  ErpKey: string;
begin
  AByErp := TDictionary<string, TSyncRowCalendario>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT CalendarId, Nombre, ' +
      '       ISNULL(Source, ''MANUAL'') AS Source, ' +
      '       ISNULL(ErpCodigo, '''') AS ErpCodigo, ' +
      '       ISNULL(LastErpHash, '''') AS LastErpHash ' +
      'FROM FS_PL_Calendar ' +
      'WHERE CodigoEmpresa = :Emp';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.LocalCalendarId  := Q.FieldByName('CalendarId').AsInteger;
      Row.LocalNombre      := Q.FieldByName('Nombre').AsString;
      Row.LocalSource      := Q.FieldByName('Source').AsString;
      Row.LocalLastErpHash := Q.FieldByName('LastErpHash').AsString;
      ErpKey := Q.FieldByName('ErpCodigo').AsString;
      if ErpKey <> '' then
        AByErp.AddOrSetValue(ErpKey, Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

// Calcula hash sobre la sequencia ordenada de (data,model,duracion) del grup,
// per detectar canvis significatius entre sincronitzacions.
function ComputeHashFromDias(const ADias: TArray<TCalendarioLaboralErp>): string;
var
  Buf, Dia: string;
  D: TCalendarioLaboralErp;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  Buf := '';
  for D in ADias do
  begin
    Dia := FormatDateTime('yyyy-mm-dd', D.Fecha) + ':' +
           IntToStr(D.ModeloHorario) + '/' +
           FloatToStr(D.Duracion, FS) + '/' +
           FloatToStr(D.DuracionDescanso, FS);
    Buf := Buf + Dia + '|';
  end;
  Result := THashSHA1.GetHashString(Buf);
end;

function TErpSyncRepo.PreviewCalendarios(AReader: IErpReader;
  AFechaDesde, AFechaHasta: TDateTime): TArray<TSyncRowCalendario>;
var
  ErpRows: TArray<TCalendarioLaboralErp>;
  Locals: TDictionary<string, TSyncRowCalendario>;
  GroupedDias: TDictionary<string, TList<TCalendarioLaboralErp>>;
  Row, LocalRow: TSyncRowCalendario;
  D: TCalendarioLaboralErp;
  Pair: TPair<string, TList<TCalendarioLaboralErp>>;
  PairLocal: TPair<string, TSyncRowCalendario>;
  ResList: TList<TSyncRowCalendario>;
  ErpSeen: TDictionary<string, Boolean>;
  Lab: Integer;
begin
  ErpRows := AReader.ReadCalendarioLaboral('', AFechaDesde, AFechaHasta);
  LoadLocalCalendariosByErpCodigo(Locals);
  ErpSeen := TDictionary<string, Boolean>.Create;
  GroupedDias := TDictionary<string, TList<TCalendarioLaboralErp>>.Create;
  ResList := TList<TSyncRowCalendario>.Create;
  try
    // Agrupar dies per GrupoHorario
    for D in ErpRows do
    begin
      if not GroupedDias.ContainsKey(D.GrupoHorario) then
        GroupedDias.Add(D.GrupoHorario, TList<TCalendarioLaboralErp>.Create);
      GroupedDias[D.GrupoHorario].Add(D);
    end;

    // Per cada grup, calcular metriques i status
    for Pair in GroupedDias do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.GrupoErpCodigo := Pair.Key;
      Row.Descripcion := '';
      Row.DiasTotales := Pair.Value.Count;
      Lab := 0;
      for D in Pair.Value.ToArray do
        if D.Duracion > 0 then Inc(Lab);
      Row.DiasLaborables := Lab;
      Row.DiasFestivos := Row.DiasTotales - Lab;
      Row.NewHash := ComputeHashFromDias(Pair.Value.ToArray);
      Row.ConflictAction := caAplicarErp;
      ErpSeen.AddOrSetValue(Pair.Key, True);

      if Locals.TryGetValue(Pair.Key, LocalRow) then
      begin
        Row.LocalCalendarId  := LocalRow.LocalCalendarId;
        Row.LocalNombre      := LocalRow.LocalNombre;
        Row.LocalSource      := LocalRow.LocalSource;
        Row.LocalLastErpHash := LocalRow.LocalLastErpHash;

        if Row.NewHash = Row.LocalLastErpHash then
        begin
          Row.Status := ssSinCambios;
          Row.Aplicar := False;
        end
        else if SameText(Row.LocalSource, 'ERP') and (Row.LocalLastErpHash <> '') then
        begin
          Row.Status := ssActualizado;
          Row.Aplicar := True;
        end
        else
        begin
          Row.Status := ssConflicto;
          Row.Aplicar := False;
        end;
      end
      else
      begin
        Row.Status := ssNuevo;
        Row.Aplicar := True;
      end;

      ResList.Add(Row);
    end;

    // Detectar grups eliminats (existeixen en local com a ERP pero ja no surten)
    for PairLocal in Locals do
      if not ErpSeen.ContainsKey(PairLocal.Key) and
         SameText(PairLocal.Value.LocalSource, 'ERP') then
      begin
        Row := PairLocal.Value;
        Row.GrupoErpCodigo := PairLocal.Key;
        Row.Status := ssEliminadoErp;
        Row.Aplicar := False;
        ResList.Add(Row);
      end;

    Result := ResList.ToArray;
  finally
    for Pair in GroupedDias do
      Pair.Value.Free;
    GroupedDias.Free;
    ErpSeen.Free;
    Locals.Free;
    ResList.Free;
  end;
end;

// Donat el llistat de dies d'un grup, deriva:
//   - DiaSemana dominant: laborable o festiu (segons majoria de dies d'aquell
//     dia setmana)
//   - per cada dia que difereixi del patro dominant del seu DiaSemana, genera
//     una excepcio (laborable o festiu, depenent del patro)
//
// Escriu a FS_PL_CalendarDayRule (regles setmanals NO laborables, equivalent
// a "cap de setmana") i FS_PL_CalendarException (excepcions puntuals).
procedure TErpSyncRepo.ApplyCalendarioRow(const ARow: TSyncRowCalendario;
  const ADias: TArray<TCalendarioLaboralErp>);
var
  Sql, EmpStr, CalStr, NombreStr: string;
  CalId, Dia, I, TotalDies: Integer;
  Q: TADOQuery;
  CountLab, CountFest: array[1..7] of Integer;
  DiaDominantLaborable: array[1..7] of Boolean;
  DowD: Integer;
  EsExcepcion: Boolean;
  D: TCalendarioLaboralErp;
begin
  EmpStr := IntToStr(FCodigoEmpresa);
  NombreStr := ARow.GrupoErpCodigo;

  // 1. INSERT o UPDATE del FS_PL_Calendar (cabecera)
  if ARow.LocalCalendarId = 0 then
  begin
    ExecSql(
      'INSERT INTO FS_PL_Calendar (CodigoEmpresa, Nombre, Descripcion, ' +
      '  Activo, Source, ErpSistema, ErpCodigo, LastErpHash, LastErpSyncAt) VALUES (' +
      EmpStr + ', ' + SqlStr(NombreStr) + ', ' +
      SqlStr('Grupo horario ' + ARow.GrupoErpCodigo + ' (importado de ' + FErpSistema + ')') + ', ' +
      '1, ''ERP'', ' + SqlStr(FErpSistema) + ', ' + SqlStr(ARow.GrupoErpCodigo) + ', ' +
      SqlStr(ARow.NewHash) + ', SYSUTCDATETIME())');

    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT CalendarId FROM FS_PL_Calendar WHERE CodigoEmpresa = :E AND ErpCodigo = :C';
      Q.Parameters.ParamByName('E').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('C').Value := ARow.GrupoErpCodigo;
      Q.Open;
      if Q.Eof then Exit;
      CalId := Q.FieldByName('CalendarId').AsInteger;
    finally
      Q.Free;
    end;
  end
  else
  begin
    CalId := ARow.LocalCalendarId;
    if (ARow.Status = ssConflicto) and (ARow.ConflictAction = caMantenerLocal) then
    begin
      ExecSql(
        'UPDATE FS_PL_Calendar SET Source = ''MIXED'', ' +
        '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
        '  ErpCodigo = ' + SqlStr(ARow.GrupoErpCodigo) + ', ' +
        '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
        '  LastErpSyncAt = SYSUTCDATETIME() ' +
        'WHERE CodigoEmpresa = ' + EmpStr + ' AND CalendarId = ' + IntToStr(CalId));
      Exit;
    end;

    ExecSql(
      'UPDATE FS_PL_Calendar SET Source = ''ERP'', ' +
      '  ErpSistema = ' + SqlStr(FErpSistema) + ', ' +
      '  ErpCodigo = ' + SqlStr(ARow.GrupoErpCodigo) + ', ' +
      '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
      '  LastErpSyncAt = SYSUTCDATETIME() ' +
      'WHERE CodigoEmpresa = ' + EmpStr + ' AND CalendarId = ' + IntToStr(CalId));
  end;

  CalStr := IntToStr(CalId);

  // 2. Esborrar regles setmanals i excepcions actuals
  ExecSql('DELETE FROM FS_PL_CalendarDayRule WHERE CodigoEmpresa = ' + EmpStr +
    ' AND CalendarId = ' + CalStr);
  ExecSql('DELETE FROM FS_PL_CalendarException WHERE CodigoEmpresa = ' + EmpStr +
    ' AND CalendarId = ' + CalStr);

  // 3. Comptar dies laborables/festius per dia setmana ISO (1=Lu..7=Diu)
  TotalDies := 0;
  for Dia := 1 to 7 do
  begin
    CountLab[Dia] := 0;
    CountFest[Dia] := 0;
  end;
  for D in ADias do
  begin
    DowD := DayOfTheWeek(D.Fecha); // 1=Lu .. 7=Diu (Delphi DayOfTheWeek = ISO)
    if (DowD >= 1) and (DowD <= 7) then
    begin
      Inc(TotalDies);
      if D.Duracion > 0 then Inc(CountLab[DowD])
      else Inc(CountFest[DowD]);
    end;
  end;

  // Guarda: si el grup horari no porta CAP dada (rang buit / any sense omplir a
  // CalendarioLaboral, veure project_gantt_calendariolaboral_year_gap), NO
  // apliquem el criteri de tancament -> deixariem el calendari 100% tancat i
  // bloquejaria tota la planificacio. Sortim deixant-lo "obert" (sense regles).
  if TotalDies = 0 then Exit;

  // 4. Determinar patro dominant per dia setmana
  //    Laborable ("obert", sense regla NO-LAB) NOMES si hi ha com a minim un
  //    dia laborable real I son majoria. Tot el demes -> "tancat" (regla NO-LAB
  //    00:00-23:59). IMPORTANT: un dia setmanal SENSE cap registre a
  //    CalendarioLaboral (CountLab=0, CountFest=0) NO s'ha de presumir laborable
  //    -> queda tancat. Abans (CountLab >= CountFest) un empat 0-0 el deixava
  //    obert i el cap de setmana sense dades comptava nodes al Summary del Gantt.
  for Dia := 1 to 7 do
  begin
    DiaDominantLaborable[Dia] := (CountLab[Dia] > 0) and
                                 (CountLab[Dia] >= CountFest[Dia]);
    if not DiaDominantLaborable[Dia] then
    begin
      ExecSql(
        'INSERT INTO FS_PL_CalendarDayRule (CodigoEmpresa, CalendarId, ' +
        '  DiaSemana, HoraInicioNoLab, HoraFinNoLab) VALUES (' +
        EmpStr + ', ' + CalStr + ', ' + IntToStr(Dia) + ', ''00:00:00'', ''23:59:00'')');
    end;
  end;

  // 5. Generar excepcions per cada dia que difereixi del patro del seu DiaSemana
  for D in ADias do
  begin
    DowD := DayOfTheWeek(D.Fecha);
    if (DowD < 1) or (DowD > 7) then Continue;
    EsExcepcion := False;
    if DiaDominantLaborable[DowD] then
      EsExcepcion := D.Duracion = 0      // patro laborable, pero aquest dia es festiu
    else
      EsExcepcion := D.Duracion > 0;     // patro festiu, pero aquest dia es laborable

    if EsExcepcion then
    begin
      Sql :=
        'INSERT INTO FS_PL_CalendarException (CodigoEmpresa, CalendarId, ' +
        '  Fecha, EsLaborable, HoraInicio, HoraFin) VALUES (' +
        EmpStr + ', ' + CalStr + ', ' +
        '''' + FormatDateTime('yyyy-mm-dd', D.Fecha) + ''', ' +
        IntToStr(Ord(D.Duracion > 0)) + ', NULL, NULL)';
      ExecSql(Sql);
    end;
  end;
end;

function TErpSyncRepo.ApplyCalendarios(const ARows: TArray<TSyncRowCalendario>;
  AFechaDesde, AFechaHasta: TDateTime;
  AReader: IErpReader): TSyncSummary;
var
  Row: TSyncRowCalendario;
  AllDias: TArray<TCalendarioLaboralErp>;
  DiasGrupo: TList<TCalendarioLaboralErp>;
  D: TCalendarioLaboralErp;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Total := Length(ARows);
  if Length(ARows) = 0 then Exit;

  // Carregar dies un sol cop (rang complet, sense filtre per grup)
  AllDias := AReader.ReadCalendarioLaboral('', AFechaDesde, AFechaHasta);

  for Row in ARows do
  begin
    case Row.Status of
      ssNuevo:        Inc(Result.Nuevos);
      ssActualizado:  Inc(Result.Actualizados);
      ssSinCambios:   Inc(Result.SinCambios);
      ssConflicto:    Inc(Result.Conflictos);
      ssEliminadoErp: Inc(Result.Eliminados);
      ssError:        Inc(Result.Errores);
    end;
    if Row.Aplicar and (Row.Status in [ssNuevo, ssActualizado, ssConflicto]) then
    begin
      DiasGrupo := TList<TCalendarioLaboralErp>.Create;
      try
        for D in AllDias do
          if D.GrupoHorario = Row.GrupoErpCodigo then
            DiasGrupo.Add(D);
        try
          ApplyCalendarioRow(Row, DiasGrupo.ToArray);
          Inc(Result.Aplicados);
        except
          on E: Exception do
            Inc(Result.Errores);
        end;
      finally
        DiasGrupo.Free;
      end;
    end;
  end;
end;

procedure TErpSyncRepo.LinkOperatorsAndCentersToCalendars(
  out AOperariosVinculados, ACentrosVinculados: Integer);
var
  EmpStr: string;
  Q: TADOQuery;
begin
  AOperariosVinculados := 0;
  ACentrosVinculados := 0;
  EmpStr := IntToStr(FCodigoEmpresa);

  // 1. Operator.CalendarId  <-  Calendar amb ErpCodigo = Operator.GrupoHorarioCodigo
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'UPDATE op SET op.CalendarId = c.CalendarId ' +
      'FROM FS_PL_Operator op ' +
      'INNER JOIN FS_PL_Calendar c ' +
      '  ON c.CodigoEmpresa = op.CodigoEmpresa ' +
      '  AND c.ErpCodigo = op.GrupoHorarioCodigo ' +
      'WHERE op.CodigoEmpresa = ' + EmpStr +
      '  AND op.GrupoHorarioCodigo IS NOT NULL ' +
      '  AND op.GrupoHorarioCodigo <> '''' ' +
      '  AND (op.CalendarId IS NULL OR op.CalendarId <> c.CalendarId)';
    Q.ExecSQL;
    AOperariosVinculados := Q.RowsAffected;
  finally
    Q.Free;
  end;

  // 2. FS_PL_CenterCalendar: INSERT vinculacio centre <-> calendar segons
  //    Center.GrupoHorarioCodigo, si no existeix encara.
  //    Tambe esborra vinculacions stale (centre vinculat a calendar que ja
  //    no es el del seu grup).
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    // Esborrar links stale (Source ERP no documentat a CenterCalendar: usem
    // logica per cobertura - eliminem links de centres que tenen grup
    // assignat pero el calendar vinculat ja no es el del seu grup).
    Q.SQL.Text :=
      'DELETE cc FROM FS_PL_CenterCalendar cc ' +
      'INNER JOIN FS_PL_Center ct ' +
      '  ON ct.CodigoEmpresa = cc.CodigoEmpresa AND ct.CenterId = cc.CenterId ' +
      'LEFT JOIN FS_PL_Calendar c ' +
      '  ON c.CodigoEmpresa = ct.CodigoEmpresa AND c.ErpCodigo = ct.GrupoHorarioCodigo ' +
      'WHERE cc.CodigoEmpresa = ' + EmpStr +
      '  AND ct.GrupoHorarioCodigo IS NOT NULL ' +
      '  AND ct.GrupoHorarioCodigo <> '''' ' +
      '  AND (c.CalendarId IS NULL OR c.CalendarId <> cc.CalendarId)';
    Q.ExecSQL;

    // Inserir el nou link si no existeix
    Q.SQL.Text :=
      'INSERT INTO FS_PL_CenterCalendar (CodigoEmpresa, CenterId, CalendarId) ' +
      'SELECT ct.CodigoEmpresa, ct.CenterId, c.CalendarId ' +
      'FROM FS_PL_Center ct ' +
      'INNER JOIN FS_PL_Calendar c ' +
      '  ON c.CodigoEmpresa = ct.CodigoEmpresa ' +
      '  AND c.ErpCodigo = ct.GrupoHorarioCodigo ' +
      'WHERE ct.CodigoEmpresa = ' + EmpStr +
      '  AND ct.GrupoHorarioCodigo IS NOT NULL ' +
      '  AND ct.GrupoHorarioCodigo <> '''' ' +
      '  AND NOT EXISTS (' +
      '    SELECT 1 FROM FS_PL_CenterCalendar cc ' +
      '    WHERE cc.CodigoEmpresa = ct.CodigoEmpresa ' +
      '      AND cc.CenterId = ct.CenterId ' +
      '      AND cc.CalendarId = c.CalendarId)';
    Q.ExecSQL;
    ACentrosVinculados := Q.RowsAffected;
  finally
    Q.Free;
  end;
end;

{ ---------- Backlog (Raw_Item) ---------- }

function TErpSyncRepo.HashRawItem(const Item: TRawItemErp): string;
var
  Buf: string;
  FS: TFormatSettings;
  Extras: TArray<string>;
  EV: TErpExtraValue;
  I: Integer;
begin
  FS := TFormatSettings.Invariant;
  Buf :=
    Item.TipoOrigen + '|' + IntToStr(Item.Nivel) + '|' +
    Item.ClaveERP + '|' + Item.ClaveERPPadre + '|' +
    IntToStr(Item.NumeroDoc) + '|' + Item.SerieDoc + '|' +
    IntToStr(Item.LineaDoc) + '|' + Item.CodigoProyecto + '|' +
    Item.Codigo + '|' + Item.Nombre + '|' + Item.Descripcion + '|' +
    Item.CodigoArticulo + '|' + Item.DescripcionArticulo + '|' +
    FloatToStr(Item.Cantidad, FS) + '|' + Item.UnidadMedida + '|' +
    Item.CodigoCliente + '|' + Item.NombreCliente + '|' +
    FormatDateTime('yyyymmddhhnnss', Item.FechaCompromiso, FS) + '|' +
    FormatDateTime('yyyymmddhhnnss', Item.FechaNecesaria, FS) + '|' +
    FormatDateTime('yyyymmddhhnnss', Item.FechaInicioPrev, FS) + '|' +
    FormatDateTime('yyyymmddhhnnss', Item.FechaFinPrev, FS) + '|' +
    IntToStr(Item.Prioridad) + '|' + IntToStr(Item.Orden) + '|' +
    Item.CentroPreferente + '|' +
    FloatToStr(Item.HorasEstimadas, FS) + '|' +
    Item.EstadoERP + '|' +
    // Bloque OP: que un cambio en estos campos marque ssActualizado y se
    // reescriba (p.ej. UnidadesFabricadas avanza, cambia el coste...).
    FloatToStr(Item.OpTiempoPreparacion, FS) + '|' +
    FloatToStr(Item.OpTiempoFabricacion, FS) + '|' +
    FloatToStr(Item.OpUnidadesHora, FS) + '|' +
    FloatToStr(Item.OpCosteHoraMaquina, FS) + '|' +
    FloatToStr(Item.OpCosteHoraManoObra, FS) + '|' +
    FloatToStr(Item.OpUnidadesFabricadas, FS) + '|' +
    FormatDateTime('yyyymmddhhnnss', Item.OpFechaInicioReal, FS) + '|' +
    FormatDateTime('yyyymmddhhnnss', Item.OpFechaFinalReal, FS) + '|' +
    BoolToStr(Item.OpOperacionExterna, True) + '|' +
    Item.OpCodigoProveedor + '|' + Item.OpSeccionFabrica + '|' +
    BoolToStr(Item.OpStatusPlanificado, True) + '|' +
    Item.OpObservaciones + '|' +
    FloatToStr(Item.OpPctParaSigOperacion, FS) + '|' +
    FloatToStr(Item.OpPctDedicacionOperario, FS);

  // Campos custom mapeados desde el ERP: si cambia el valor de uno (o aparece
  // un mapeo nuevo), el hash cambia y el item pasa a ssActualizado, de modo
  // que el sync reescribe FS_PL_RawItem_Extra. Se ordenan por FieldKey para
  // que el hash no dependa del orden de los mapeos.
  SetLength(Extras, Length(Item.ExtraFields));
  for I := 0 to High(Item.ExtraFields) do
  begin
    EV := Item.ExtraFields[I];
    Extras[I] := EV.FieldKey + '=' + VarToStrDef(EV.Value, '');
  end;
  TArray.Sort<string>(Extras);
  for I := 0 to High(Extras) do
    Buf := Buf + '|' + Extras[I];

  Result := THashSHA1.GetHashString(Buf);
end;

procedure TErpSyncRepo.LoadLocalRawItemsByClave(const ATipoOrigen: string;
  out AByClave: TDictionary<string, TSyncRowRawItem>);
var
  Q: TADOQuery;
  Row: TSyncRowRawItem;
  Clave: string;
begin
  AByClave := TDictionary<string, TSyncRowRawItem>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT ri.RawItemId, ri.ClaveERP, ' +
      '       ISNULL(ri.LastErpHash, '''') AS LastErpHash, ' +
      '       CASE WHEN EXISTS (SELECT 1 FROM FS_PL_NodeData nd ' +
      '                          WHERE nd.CodigoEmpresa = ri.CodigoEmpresa ' +
      '                            AND nd.RawItemTipoOrigen = ri.TipoOrigen ' +
      '                            AND nd.RawItemClaveERP = ri.ClaveERP) ' +
      '            THEN 1 ELSE 0 END AS HasNode ' +
      'FROM FS_PL_Raw_Item ri ' +
      'WHERE ri.CodigoEmpresa = :Emp AND ri.TipoOrigen = :Tipo';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Tipo').Value := ATipoOrigen;
    Q.Open;
    while not Q.Eof do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.LocalRawItemId    := Q.FieldByName('RawItemId').AsLargeInt;
      Row.LocalLastErpHash  := Q.FieldByName('LastErpHash').AsString;
      Row.HasPlannedNode    := Q.FieldByName('HasNode').AsInteger = 1;
      Clave := Q.FieldByName('ClaveERP').AsString;
      AByClave.AddOrSetValue(Clave, Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TErpSyncRepo.LoadLocalRawItemsFull(const ATipoOrigen: string;
  out AByClave: TDictionary<string, TRawItemErp>);
var
  Q: TADOQuery;
  Item: TRawItemErp;
begin
  AByClave := TDictionary<string, TRawItemErp>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT ClaveERP, ClaveERPPadre, Nivel, NumeroDoc, SerieDoc, LineaDoc, ' +
      '       CodigoProyecto, Codigo, Nombre, Descripcion, ' +
      '       CodigoArticulo, DescripcionArticulo, Cantidad, UnidadMedida, ' +
      '       CodigoCliente, NombreCliente, ' +
      '       FechaCompromiso, FechaNecesaria, FechaInicioPrev, FechaFinPrev, ' +
      '       FechaLanzamiento, FechaPedido, Prioridad, Orden, ' +
      '       CentroPreferente, HorasEstimadas, EstadoERP, Observaciones ' +
      'FROM FS_PL_Raw_Item ' +
      'WHERE CodigoEmpresa = :Emp AND TipoOrigen = :Tipo';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Tipo').Value := ATipoOrigen;
    Q.Open;
    while not Q.Eof do
    begin
      Item := Default(TRawItemErp);
      Item.TipoOrigen          := ATipoOrigen;
      Item.ClaveERP            := Q.FieldByName('ClaveERP').AsString;
      Item.ClaveERPPadre       := Q.FieldByName('ClaveERPPadre').AsString;
      Item.Nivel               := Q.FieldByName('Nivel').AsInteger;
      Item.NumeroDoc           := Q.FieldByName('NumeroDoc').AsInteger;
      Item.SerieDoc            := Q.FieldByName('SerieDoc').AsString;
      Item.LineaDoc            := Q.FieldByName('LineaDoc').AsInteger;
      Item.CodigoProyecto      := Q.FieldByName('CodigoProyecto').AsString;
      Item.Codigo              := Q.FieldByName('Codigo').AsString;
      Item.Nombre              := Q.FieldByName('Nombre').AsString;
      Item.Descripcion         := Q.FieldByName('Descripcion').AsString;
      Item.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
      Item.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      Item.Cantidad            := Q.FieldByName('Cantidad').AsFloat;
      Item.UnidadMedida        := Q.FieldByName('UnidadMedida').AsString;
      Item.CodigoCliente       := Q.FieldByName('CodigoCliente').AsString;
      Item.NombreCliente       := Q.FieldByName('NombreCliente').AsString;
      if not Q.FieldByName('FechaCompromiso').IsNull then
        Item.FechaCompromiso   := Q.FieldByName('FechaCompromiso').AsDateTime;
      if not Q.FieldByName('FechaNecesaria').IsNull then
        Item.FechaNecesaria    := Q.FieldByName('FechaNecesaria').AsDateTime;
      if not Q.FieldByName('FechaInicioPrev').IsNull then
        Item.FechaInicioPrev   := Q.FieldByName('FechaInicioPrev').AsDateTime;
      if not Q.FieldByName('FechaFinPrev').IsNull then
        Item.FechaFinPrev      := Q.FieldByName('FechaFinPrev').AsDateTime;
      if not Q.FieldByName('FechaLanzamiento').IsNull then
        Item.FechaLanzamiento  := Q.FieldByName('FechaLanzamiento').AsDateTime;
      if not Q.FieldByName('FechaPedido').IsNull then
        Item.FechaPedido       := Q.FieldByName('FechaPedido').AsDateTime;
      Item.Prioridad           := Q.FieldByName('Prioridad').AsInteger;
      Item.Orden               := Q.FieldByName('Orden').AsInteger;
      Item.CentroPreferente    := Q.FieldByName('CentroPreferente').AsString;
      Item.HorasEstimadas      := Q.FieldByName('HorasEstimadas').AsFloat;
      Item.EstadoERP           := Q.FieldByName('EstadoERP').AsString;
      Item.Observaciones       := Q.FieldByName('Observaciones').AsString;
      AByClave.AddOrSetValue(Item.ClaveERP, Item);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TErpSyncRepo.PreviewBacklogOF(AReader: IErpReader;
  AEjercicio: SmallInt): TArray<TSyncRowRawItem>;
var
  ErpItems: TArray<TRawItemErp>;
  Locals: TDictionary<string, TSyncRowRawItem>;
  ErpSeen: TDictionary<string, Boolean>;
  Pair: TPair<string, TSyncRowRawItem>;
  ResList: TList<TSyncRowRawItem>;
  Row, LocalRow: TSyncRowRawItem;
  Item, FullData: TRawItemErp;
  LocalFull: TDictionary<string, TRawItemErp>;
  MapRepo: TErpFieldMapRepo;
  Maps: TArray<TErpFieldMap>;
begin
  SetLength(Result, 0);
  // Los mapeos custom viven en la BD Planner (FS_PL_Cfg_ErpFieldMap); se cargan
  // aqui con FConnection y se pasan al reader, que solo los inyecta. Asi el
  // reader ERP no necesita conocer ninguna tabla FS_PL_*.
  MapRepo := TErpFieldMapRepo.Create(FConnection, FCodigoEmpresa);
  try
    Maps := MapRepo.LoadActive('BACKLOG');
  finally
    MapRepo.Free;
  end;
  ErpItems := AReader.ReadBacklogOF(AEjercicio, Maps);
  LoadLocalRawItemsByClave('OF ', Locals);
  ErpSeen := TDictionary<string, Boolean>.Create;
  ResList := TList<TSyncRowRawItem>.Create;
  try
    for Item in ErpItems do
    begin
      FillChar(Row, SizeOf(Row), 0);
      Row.ErpData := Item;
      Row.NewHash := HashRawItem(Item);
      ErpSeen.AddOrSetValue(Item.ClaveERP, True);

      if Locals.TryGetValue(Item.ClaveERP, LocalRow) then
      begin
        Row.LocalRawItemId   := LocalRow.LocalRawItemId;
        Row.LocalLastErpHash := LocalRow.LocalLastErpHash;
        Row.HasPlannedNode   := LocalRow.HasPlannedNode;
        if Row.NewHash = Row.LocalLastErpHash then
        begin
          Row.Status := ssSinCambios;
          Row.Aplicar := False;
        end
        else
        begin
          Row.Status := ssActualizado;
          Row.Aplicar := True;
        end;
      end
      else
      begin
        Row.Status := ssNuevo;
        Row.Aplicar := True;
      end;

      ResList.Add(Row);
    end;

    // Obsolets: locals que no apareixen al ERP. Si no tenen node, els marcarem
    // Activo=0 al ApplyRawItems. Si tenen node, els deixem desmarcats i
    // l'usuari decideix.
    // Carreguem dades reals dels Raw_Item locals per poder mostrar-les al grid.
    LoadLocalRawItemsFull('OF ', LocalFull);
    try
      for Pair in Locals do
        if not ErpSeen.ContainsKey(Pair.Key) then
        begin
          Row := Pair.Value;
          if LocalFull.TryGetValue(Pair.Key, FullData) then
            Row.ErpData := FullData
          else
          begin
            FillChar(Row.ErpData, SizeOf(Row.ErpData), 0);
            Row.ErpData.ClaveERP := Pair.Key;
            Row.ErpData.TipoOrigen := 'OF ';
          end;
          Row.Status := ssEliminadoErp;
          Row.Aplicar := not Row.HasPlannedNode;
          ResList.Add(Row);
        end;
    finally
      LocalFull.Free;
    end;

    Result := ResList.ToArray;
  finally
    ErpSeen.Free;
    Locals.Free;
    ResList.Free;
  end;
end;

procedure TErpSyncRepo.MarkRawItemObsoleto(ALocalRawItemId: Int64);
var
  Sql: string;
begin
  Sql :=
    'UPDATE FS_PL_Raw_Item SET Activo = 0, LastErpSyncAt = SYSUTCDATETIME() ' +
    'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
    '  AND RawItemId = ' + IntToStr(ALocalRawItemId);
  ExecSql(Sql);
end;

procedure TErpSyncRepo.ApplyRawItem(const ARow: TSyncRowRawItem;
  const AParentLocalIds: TDictionary<string, Int64>);
var
  Sql, EmpStr, NivelStr, NumDocStr, LinDocStr, PriStr, OrdStr: string;
  CantStr, HorasStr: string;
  FechaCompStr, FechaNecStr, FechaIniStr, FechaFinStr, FechaLanzStr, FechaPedStr: string;
  ParentClauseInsert, ParentClauseUpdate: string;
  ParentId: Int64;
  FS: TFormatSettings;
  CentroPrefSql: string;
  IsOp: Boolean;
  // Bloque OP: columnas y valores (solo en Nivel 3; NULL en OF/OT).
  OpCols, OpValsIns, OpSetUpd: string;

  function DateOrNull(D: TDateTime): string;
  begin
    if D > 0 then
      Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', D) + ''''
    else
      Result := 'NULL';
  end;

  // Decimal o NULL (NULL si no es OP, para no ensuciar OF/OT con ceros).
  function NumOrNull(V: Double): string;
  begin
    if IsOp then Result := FloatToStr(V, FS) else Result := 'NULL';
  end;

  // Fecha OP o NULL.
  function OpDateOrNull(D: TDateTime): string;
  begin
    if IsOp and (D > 0) then
      Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', D) + ''''
    else
      Result := 'NULL';
  end;

  // Bit OP o NULL.
  function BitOrNull(B: Boolean): string;
  begin
    if not IsOp then Result := 'NULL'
    else if B then Result := '1' else Result := '0';
  end;

  // Texto OP o NULL.
  function StrOrNull(const S: string): string;
  begin
    if IsOp and (Trim(S) <> '') then Result := SqlStr(S) else Result := 'NULL';
  end;

begin
  FS := TFormatSettings.Invariant;
  EmpStr   := IntToStr(FCodigoEmpresa);
  NivelStr := IntToStr(ARow.ErpData.Nivel);
  NumDocStr := IntToStr(ARow.ErpData.NumeroDoc);
  LinDocStr := IntToStr(ARow.ErpData.LineaDoc);
  PriStr   := IntToStr(ARow.ErpData.Prioridad);
  OrdStr   := IntToStr(ARow.ErpData.Orden);
  CantStr  := FloatToStr(ARow.ErpData.Cantidad, FS);
  HorasStr := FloatToStr(ARow.ErpData.HorasEstimadas, FS);
  FechaCompStr := DateOrNull(ARow.ErpData.FechaCompromiso);
  FechaNecStr  := DateOrNull(ARow.ErpData.FechaNecesaria);
  FechaIniStr  := DateOrNull(ARow.ErpData.FechaInicioPrev);
  FechaFinStr  := DateOrNull(ARow.ErpData.FechaFinPrev);
  FechaLanzStr := DateOrNull(ARow.ErpData.FechaLanzamiento);
  FechaPedStr  := DateOrNull(ARow.ErpData.FechaPedido);

  // Resol ParentRawItemId si tenim el pare a la sessio actual
  if (ARow.ErpData.ClaveERPPadre <> '') and
     AParentLocalIds.TryGetValue(ARow.ErpData.ClaveERPPadre, ParentId) then
  begin
    ParentClauseInsert := IntToStr(ParentId);
    ParentClauseUpdate := 'ParentRawItemId = ' + IntToStr(ParentId) + ', ';
  end
  else
  begin
    ParentClauseInsert := 'NULL';
    ParentClauseUpdate := '';
  end;

  if Trim(ARow.ErpData.CentroPreferente) = '' then
    CentroPrefSql := 'NULL'
  else
    CentroPrefSql := SqlStr(ARow.ErpData.CentroPreferente);

  // Bloque OP: solo aplica a Nivel 3 (operaciones). En OF/OT, los helpers
  // *OrNull devuelven NULL, asi que estas columnas quedan vacias en esos niveles.
  IsOp := ARow.ErpData.Nivel = 3;
  OpCols :=
    'OpTiempoPreparacion, OpTiempoFabricacion, OpUnidadesHora, ' +
    'OpCosteHoraMaquina, OpCosteHoraManoObra, OpUnidadesFabricadas, ' +
    'OpFechaInicioReal, OpFechaFinalReal, OpOperacionExterna, ' +
    'OpCodigoProveedor, OpSeccionFabrica, OpStatusPlanificado, ' +
    'OpObservaciones, OpPctParaSigOperacion, OpPctDedicacionOperario';
  OpValsIns :=
    NumOrNull(ARow.ErpData.OpTiempoPreparacion) + ', ' +
    NumOrNull(ARow.ErpData.OpTiempoFabricacion) + ', ' +
    NumOrNull(ARow.ErpData.OpUnidadesHora) + ', ' +
    NumOrNull(ARow.ErpData.OpCosteHoraMaquina) + ', ' +
    NumOrNull(ARow.ErpData.OpCosteHoraManoObra) + ', ' +
    NumOrNull(ARow.ErpData.OpUnidadesFabricadas) + ', ' +
    OpDateOrNull(ARow.ErpData.OpFechaInicioReal) + ', ' +
    OpDateOrNull(ARow.ErpData.OpFechaFinalReal) + ', ' +
    BitOrNull(ARow.ErpData.OpOperacionExterna) + ', ' +
    StrOrNull(ARow.ErpData.OpCodigoProveedor) + ', ' +
    StrOrNull(ARow.ErpData.OpSeccionFabrica) + ', ' +
    BitOrNull(ARow.ErpData.OpStatusPlanificado) + ', ' +
    StrOrNull(ARow.ErpData.OpObservaciones) + ', ' +
    NumOrNull(ARow.ErpData.OpPctParaSigOperacion) + ', ' +
    NumOrNull(ARow.ErpData.OpPctDedicacionOperario);
  OpSetUpd :=
    'OpTiempoPreparacion = ' + NumOrNull(ARow.ErpData.OpTiempoPreparacion) + ', ' +
    'OpTiempoFabricacion = ' + NumOrNull(ARow.ErpData.OpTiempoFabricacion) + ', ' +
    'OpUnidadesHora = ' + NumOrNull(ARow.ErpData.OpUnidadesHora) + ', ' +
    'OpCosteHoraMaquina = ' + NumOrNull(ARow.ErpData.OpCosteHoraMaquina) + ', ' +
    'OpCosteHoraManoObra = ' + NumOrNull(ARow.ErpData.OpCosteHoraManoObra) + ', ' +
    'OpUnidadesFabricadas = ' + NumOrNull(ARow.ErpData.OpUnidadesFabricadas) + ', ' +
    'OpFechaInicioReal = ' + OpDateOrNull(ARow.ErpData.OpFechaInicioReal) + ', ' +
    'OpFechaFinalReal = ' + OpDateOrNull(ARow.ErpData.OpFechaFinalReal) + ', ' +
    'OpOperacionExterna = ' + BitOrNull(ARow.ErpData.OpOperacionExterna) + ', ' +
    'OpCodigoProveedor = ' + StrOrNull(ARow.ErpData.OpCodigoProveedor) + ', ' +
    'OpSeccionFabrica = ' + StrOrNull(ARow.ErpData.OpSeccionFabrica) + ', ' +
    'OpStatusPlanificado = ' + BitOrNull(ARow.ErpData.OpStatusPlanificado) + ', ' +
    'OpObservaciones = ' + StrOrNull(ARow.ErpData.OpObservaciones) + ', ' +
    'OpPctParaSigOperacion = ' + NumOrNull(ARow.ErpData.OpPctParaSigOperacion) + ', ' +
    'OpPctDedicacionOperario = ' + NumOrNull(ARow.ErpData.OpPctDedicacionOperario);

  case ARow.Status of
    ssNuevo:
      begin
        Sql :=
          'INSERT INTO FS_PL_Raw_Item (CodigoEmpresa, TipoOrigen, Nivel, ' +
          '  ParentRawItemId, OrigenERP, ClaveERP, ClaveERPPadre, ' +
          '  NumeroDoc, SerieDoc, LineaDoc, CodigoProyecto, ' +
          '  Codigo, Nombre, Descripcion, ' +
          '  CodigoArticulo, DescripcionArticulo, Cantidad, UnidadMedida, ' +
          '  CodigoCliente, NombreCliente, ' +
          '  FechaCompromiso, FechaNecesaria, FechaInicioPrev, FechaFinPrev, ' +
          '  FechaLanzamiento, FechaPedido, ' +
          '  Prioridad, Orden, CentroPreferente, HorasEstimadas, ' +
          '  EstadoERP, Observaciones, ' + OpCols + ', ' +
          '  Activo, LastErpHash, LastErpSyncAt) VALUES (' +
          EmpStr + ', ' + SqlStr(ARow.ErpData.TipoOrigen) + ', ' + NivelStr + ', ' +
          ParentClauseInsert + ', ' + SqlStr(FErpSistema) + ', ' +
          SqlStr(ARow.ErpData.ClaveERP) + ', ' + SqlStr(ARow.ErpData.ClaveERPPadre) + ', ' +
          NumDocStr + ', ' + SqlStr(ARow.ErpData.SerieDoc) + ', ' +
          LinDocStr + ', ' + SqlStr(ARow.ErpData.CodigoProyecto) + ', ' +
          SqlStr(ARow.ErpData.Codigo) + ', ' + SqlStr(ARow.ErpData.Nombre) + ', ' +
          SqlStr(ARow.ErpData.Descripcion) + ', ' +
          SqlStr(ARow.ErpData.CodigoArticulo) + ', ' +
          SqlStr(ARow.ErpData.DescripcionArticulo) + ', ' +
          CantStr + ', ' + SqlStr(ARow.ErpData.UnidadMedida) + ', ' +
          SqlStr(ARow.ErpData.CodigoCliente) + ', ' +
          SqlStr(ARow.ErpData.NombreCliente) + ', ' +
          FechaCompStr + ', ' + FechaNecStr + ', ' + FechaIniStr + ', ' + FechaFinStr + ', ' +
          FechaLanzStr + ', ' + FechaPedStr + ', ' +
          PriStr + ', ' + OrdStr + ', ' + CentroPrefSql + ', ' + HorasStr + ', ' +
          SqlStr(ARow.ErpData.EstadoERP) + ', ' + SqlStr(ARow.ErpData.Observaciones) + ', ' +
          OpValsIns + ', ' +
          '1, ' + SqlStr(ARow.NewHash) + ', SYSUTCDATETIME())';
        ExecSql(Sql);
      end;

    ssActualizado:
      begin
        Sql :=
          'UPDATE FS_PL_Raw_Item SET ' +
          ParentClauseUpdate +
          '  NumeroDoc = ' + NumDocStr + ', ' +
          '  SerieDoc = ' + SqlStr(ARow.ErpData.SerieDoc) + ', ' +
          '  LineaDoc = ' + LinDocStr + ', ' +
          '  CodigoProyecto = ' + SqlStr(ARow.ErpData.CodigoProyecto) + ', ' +
          '  Codigo = ' + SqlStr(ARow.ErpData.Codigo) + ', ' +
          '  Nombre = ' + SqlStr(ARow.ErpData.Nombre) + ', ' +
          '  Descripcion = ' + SqlStr(ARow.ErpData.Descripcion) + ', ' +
          '  CodigoArticulo = ' + SqlStr(ARow.ErpData.CodigoArticulo) + ', ' +
          '  DescripcionArticulo = ' + SqlStr(ARow.ErpData.DescripcionArticulo) + ', ' +
          '  Cantidad = ' + CantStr + ', ' +
          '  UnidadMedida = ' + SqlStr(ARow.ErpData.UnidadMedida) + ', ' +
          '  CodigoCliente = ' + SqlStr(ARow.ErpData.CodigoCliente) + ', ' +
          '  NombreCliente = ' + SqlStr(ARow.ErpData.NombreCliente) + ', ' +
          '  FechaCompromiso = ' + FechaCompStr + ', ' +
          '  FechaNecesaria = ' + FechaNecStr + ', ' +
          '  FechaInicioPrev = ' + FechaIniStr + ', ' +
          '  FechaFinPrev = ' + FechaFinStr + ', ' +
          '  FechaLanzamiento = ' + FechaLanzStr + ', ' +
          '  FechaPedido = ' + FechaPedStr + ', ' +
          '  Prioridad = ' + PriStr + ', ' +
          '  Orden = ' + OrdStr + ', ' +
          '  CentroPreferente = ' + CentroPrefSql + ', ' +
          '  HorasEstimadas = ' + HorasStr + ', ' +
          '  EstadoERP = ' + SqlStr(ARow.ErpData.EstadoERP) + ', ' +
          '  Observaciones = ' + SqlStr(ARow.ErpData.Observaciones) + ', ' +
          '  ' + OpSetUpd + ', ' +
          '  Activo = 1, ' +
          '  LastErpHash = ' + SqlStr(ARow.NewHash) + ', ' +
          '  LastErpSyncAt = SYSUTCDATETIME() ' +
          'WHERE CodigoEmpresa = ' + EmpStr +
          '  AND RawItemId = ' + IntToStr(ARow.LocalRawItemId);
        ExecSql(Sql);
      end;
  end;
end;

procedure TErpSyncRepo.ApplyRawItemExtras(ARawItemId: Int64;
  const AExtras: TArray<TErpExtraValue>);
var
  EV: TErpExtraValue;
  ValSql, Sql: string;
  FS: TFormatSettings;

  // Convierte el Variant leido del ERP a literal SQL para NVARCHAR(MAX).
  function VariantToSqlValue(const V: Variant): string;
  begin
    if VarIsNull(V) or VarIsEmpty(V) then
      Exit('NULL');
    case VarType(V) and varTypeMask of
      varDate:
        Result := SqlStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', VarToDateTime(V)));
      varSingle, varDouble, varCurrency:
        Result := SqlStr(FloatToStr(Double(V), FS));
      varBoolean:
        if Boolean(V) then Result := SqlStr('1') else Result := SqlStr('0');
    else
      Result := SqlStr(VarToStr(V));
    end;
  end;

begin
  if (ARawItemId <= 0) or (Length(AExtras) = 0) then Exit;
  FS := TFormatSettings.Invariant;
  for EV in AExtras do
  begin
    if Trim(EV.FieldKey) = '' then Continue;
    ValSql := VariantToSqlValue(EV.Value);
    // MERGE: solo escribe/actualiza si la fila no es un override MANUAL.
    // Asi una importacion ERP nunca pisa lo que el usuario fijo a mano.
    Sql :=
      'MERGE FS_PL_RawItem_Extra AS T ' +
      'USING (SELECT ' + IntToStr(FCodigoEmpresa) + ' AS CodigoEmpresa, ' +
      IntToStr(ARawItemId) + ' AS RawItemId, ' +
      SqlStr(EV.FieldKey) + ' AS FieldKey) AS S ' +
      '  ON (T.CodigoEmpresa = S.CodigoEmpresa AND T.RawItemId = S.RawItemId ' +
      '      AND T.FieldKey = S.FieldKey) ' +
      'WHEN MATCHED AND T.Source <> ''MANUAL'' THEN UPDATE SET ' +
      '  FieldValue = ' + ValSql + ', Source = ''ERP'', ' +
      '  UpdatedBy = ' + SqlStr(FErpSistema) + ', UpdatedAt = SYSUTCDATETIME() ' +
      'WHEN NOT MATCHED THEN INSERT ' +
      '  (CodigoEmpresa, RawItemId, FieldKey, FieldValue, Source, UpdatedBy, UpdatedAt) ' +
      '  VALUES (' + IntToStr(FCodigoEmpresa) + ', ' + IntToStr(ARawItemId) + ', ' +
      SqlStr(EV.FieldKey) + ', ' + ValSql + ', ''ERP'', ' +
      SqlStr(FErpSistema) + ', SYSUTCDATETIME());';
    ExecSql(Sql);
  end;
end;

function TErpSyncRepo.ApplyRawItems(
  const ARows: TArray<TSyncRowRawItem>): TSyncSummary;
var
  Row: TSyncRowRawItem;
  ParentIds: TDictionary<string, Int64>;
  Q: TADOQuery;
  NewId: Int64;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Total := Length(ARows);
  ParentIds := TDictionary<string, Int64>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;

    // Carrega tots els RawItemIds existents perque els fills puguin trobar
    // els seus pares ja persistits.
    Q.SQL.Text :=
      'SELECT RawItemId, ClaveERP FROM FS_PL_Raw_Item ' +
      'WHERE CodigoEmpresa = :Emp AND TipoOrigen = ''OF ''';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      ParentIds.AddOrSetValue(Q.FieldByName('ClaveERP').AsString,
                              Q.FieldByName('RawItemId').AsLargeInt);
      Q.Next;
    end;
    Q.Close;

    for Row in ARows do
    begin
      case Row.Status of
        ssNuevo:        Inc(Result.Nuevos);
        ssActualizado:  Inc(Result.Actualizados);
        ssSinCambios:   Inc(Result.SinCambios);
        ssEliminadoErp: Inc(Result.Eliminados);
        ssError:        Inc(Result.Errores);
      end;

      if not Row.Aplicar then Continue;

      try
        if Row.Status = ssEliminadoErp then
        begin
          // Marcar obsolet nomes si NO te node planificat
          if (Row.LocalRawItemId > 0) and (not Row.HasPlannedNode) then
          begin
            MarkRawItemObsoleto(Row.LocalRawItemId);
            Inc(Result.Aplicados);
          end;
        end
        else if Row.Status in [ssNuevo, ssActualizado] then
        begin
          ApplyRawItem(Row, ParentIds);
          if Row.Status = ssNuevo then
          begin
            NewId := 0;
            // Recupera el nou RawItemId per si te fills en aquest mateix lot
            Q.SQL.Text :=
              'SELECT RawItemId FROM FS_PL_Raw_Item ' +
              'WHERE CodigoEmpresa = :Emp AND TipoOrigen = :Tipo AND ClaveERP = :Clv';
            Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
            Q.Parameters.ParamByName('Tipo').Value := Row.ErpData.TipoOrigen;
            Q.Parameters.ParamByName('Clv').Value := Row.ErpData.ClaveERP;
            Q.Open;
            if not Q.Eof then
            begin
              NewId := Q.FieldByName('RawItemId').AsLargeInt;
              ParentIds.AddOrSetValue(Row.ErpData.ClaveERP, NewId);
            end;
            Q.Close;
            // Camps custom poblats des de l'ERP per a l'item nou.
            ApplyRawItemExtras(NewId, Row.ErpData.ExtraFields);
          end
          else
            // ssActualizado: ja tenim el RawItemId local.
            ApplyRawItemExtras(Row.LocalRawItemId, Row.ErpData.ExtraFields);
          Inc(Result.Aplicados);
        end;
      except
        on E: Exception do
          Inc(Result.Errores);
      end;
    end;
  finally
    Q.Free;
    ParentIds.Free;
  end;
end;

end.
