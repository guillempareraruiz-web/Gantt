unit uMrpParamRepo;

// ============================================================================
// Repositorio de FS_PL_MrpParam: overrides MRP por (articulo, almacen).
//
// Solo gestiona la capa de OVERRIDE persistida en la BD propia del Planner. La
// fusion con los parametros de Sage (ArticulosAlmacen/Articulos/Formulas) la hace
// el motor (uMrpRecommender), porque las tablas de Sage viven en otra BD y se leen
// via IErpReader.
//
// Lookup con fallback: TryGet(articulo, almacen) busca primero el override
// especifico de ese almacen; si no hay, el override global del articulo (almacen
// = ''); si tampoco, devuelve False (todo se hereda de Sage).
// ============================================================================

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,
  Data.Win.ADODB,
  uMrpTypes;

type
  TMrpParamRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    // clave = UpperCase(Articulo)+'|'+UpperCase(Almacen)
    FOverrides: TDictionary<string, TMrpParamOverride>;
    function MakeKey(const AArticulo, AAlmacen: string): string;
    function ReadOverride(AQuery: TADOQuery): TMrpParamOverride;
  public
    constructor Create(AConnection: TADOConnection);
    destructor Destroy; override;

    procedure LoadFromDB(ACodigoEmpresa: SmallInt);

    // Busca override especifico (articulo, almacen) y, si no, el global (almacen='').
    // Result=False si no hay ningun override (heredar 100% de Sage).
    function TryGet(const AArticulo, AAlmacen: string;
      out AOverride: TMrpParamOverride): Boolean;

    // Persiste (UPSERT) un override y refresca la copia en memoria.
    procedure Save(const AOverride: TMrpParamOverride);
    // Elimina el override (vuelve a heredar de Sage).
    procedure Delete(const AArticulo, AAlmacen: string);

    function GetAll: TArray<TMrpParamOverride>;
  end;

implementation

constructor TMrpParamRepo.Create(AConnection: TADOConnection);
begin
  inherited Create;
  FConnection := AConnection;
  FOverrides := TDictionary<string, TMrpParamOverride>.Create;
end;

destructor TMrpParamRepo.Destroy;
begin
  FOverrides.Free;
  inherited;
end;

function TMrpParamRepo.MakeKey(const AArticulo, AAlmacen: string): string;
begin
  Result := UpperCase(Trim(AArticulo)) + '|' + UpperCase(Trim(AAlmacen));
end;

function TMrpParamRepo.ReadOverride(AQuery: TADOQuery): TMrpParamOverride;
var
  O: TMrpParamOverride;
  s: string;

  function FloatOrNaN(const AField: string): Double;
  begin
    if AQuery.FieldByName(AField).IsNull then
      Result := NaN
    else
      Result := AQuery.FieldByName(AField).AsFloat;
  end;

  function IntOrMinus1(const AField: string): Integer;
  begin
    if AQuery.FieldByName(AField).IsNull then
      Result := -1
    else
      Result := AQuery.FieldByName(AField).AsInteger;
  end;

begin
  O := Default(TMrpParamOverride);
  O.CodigoArticulo := AQuery.FieldByName('CodigoArticulo').AsString;
  O.CodigoAlmacen  := AQuery.FieldByName('CodigoAlmacen').AsString;

  s := Trim(AQuery.FieldByName('TipoReposicion').AsString);
  O.HasTipoReposicion := s <> '';
  if O.HasTipoReposicion then
    case UpperCase(s)[1] of
      'C': O.TipoReposicion := trCompra;
      'F': O.TipoReposicion := trFabricacion;
      'S': O.TipoReposicion := trSubcontratacion;
    else
      O.HasTipoReposicion := False;
    end;

  O.MultiploCompra        := FloatOrNaN('MultiploCompra');
  O.DiasCoberturaObjetivo := IntOrMinus1('DiasCoberturaObjetivo');
  O.LeadTimeFabricacion   := IntOrMinus1('LeadTimeFabricacion');
  O.StockSeguridadOvr     := FloatOrNaN('StockSeguridadOvr');
  O.LeadTimeCompraOvr     := IntOrMinus1('LeadTimeCompraOvr');
  O.LoteMinimoOvr         := FloatOrNaN('LoteMinimoOvr');
  O.PuntoPedidoOvr        := FloatOrNaN('PuntoPedidoOvr');
  O.ProveedorPreferenteOvr := AQuery.FieldByName('ProveedorPreferenteOvr').AsString;
  O.HorizonteDias         := IntOrMinus1('HorizonteDias');
  O.IncluirEnMrp          := AQuery.FieldByName('IncluirEnMrp').AsBoolean;
  O.Observaciones         := AQuery.FieldByName('Observaciones').AsString;
  Result := O;
end;

procedure TMrpParamRepo.LoadFromDB(ACodigoEmpresa: SmallInt);
var
  Q: TADOQuery;
  O: TMrpParamOverride;
begin
  FCodigoEmpresa := ACodigoEmpresa;
  FOverrides.Clear;
  if FConnection = nil then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT CodigoArticulo, CodigoAlmacen, TipoReposicion, MultiploCompra, ' +
      '  DiasCoberturaObjetivo, LeadTimeFabricacion, StockSeguridadOvr, ' +
      '  LeadTimeCompraOvr, LoteMinimoOvr, PuntoPedidoOvr, ProveedorPreferenteOvr, ' +
      '  HorizonteDias, IncluirEnMrp, Observaciones ' +
      'FROM FS_PL_MrpParam WHERE CodigoEmpresa = :CE';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      O := ReadOverride(Q);
      FOverrides.AddOrSetValue(MakeKey(O.CodigoArticulo, O.CodigoAlmacen), O);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TMrpParamRepo.TryGet(const AArticulo, AAlmacen: string;
  out AOverride: TMrpParamOverride): Boolean;
begin
  // 1) override especifico del almacen
  Result := FOverrides.TryGetValue(MakeKey(AArticulo, AAlmacen), AOverride);
  if Result then Exit;
  // 2) override global del articulo (almacen = '')
  if AAlmacen <> '' then
    Result := FOverrides.TryGetValue(MakeKey(AArticulo, ''), AOverride);
end;

procedure TMrpParamRepo.Save(const AOverride: TMrpParamOverride);
var
  Cmd: TADOCommand;
  tipoSql: string;

  function FloatSql(const V: Double): string;
  begin
    if IsNan(V) then Result := 'NULL'
    else Result := FloatToStr(V, TFormatSettings.Invariant);
  end;

  function IntSql(const V: Integer): string;
  begin
    if V < 0 then Result := 'NULL' else Result := IntToStr(V);
  end;

  function StrSql(const V: string): string;
  begin
    if Trim(V) = '' then Result := 'NULL'
    else Result := '''' + StringReplace(V, '''', '''''', [rfReplaceAll]) + '''';
  end;

begin
  if FConnection = nil then Exit;

  if AOverride.HasTipoReposicion then
    case AOverride.TipoReposicion of
      trCompra:          tipoSql := '''C''';
      trFabricacion:     tipoSql := '''F''';
      trSubcontratacion: tipoSql := '''S''';
    end
  else
    tipoSql := 'NULL';

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.ParamCheck := False;
    // UPSERT por PK (Empresa, Articulo, Almacen).
    Cmd.CommandText :=
      'MERGE FS_PL_MrpParam AS T ' +
      'USING (SELECT ' + IntToStr(FCodigoEmpresa) + ' AS CodigoEmpresa, ' +
      StrSql(AOverride.CodigoArticulo) + ' AS CodigoArticulo, ' +
      StrSql(AOverride.CodigoAlmacen) + ' AS CodigoAlmacen) AS S ' +
      'ON  T.CodigoEmpresa = S.CodigoEmpresa ' +
      'AND T.CodigoArticulo = S.CodigoArticulo ' +
      'AND T.CodigoAlmacen = S.CodigoAlmacen ' +
      'WHEN MATCHED THEN UPDATE SET ' +
      '  TipoReposicion = ' + tipoSql + ', ' +
      '  MultiploCompra = ' + FloatSql(AOverride.MultiploCompra) + ', ' +
      '  DiasCoberturaObjetivo = ' + IntSql(AOverride.DiasCoberturaObjetivo) + ', ' +
      '  LeadTimeFabricacion = ' + IntSql(AOverride.LeadTimeFabricacion) + ', ' +
      '  StockSeguridadOvr = ' + FloatSql(AOverride.StockSeguridadOvr) + ', ' +
      '  LeadTimeCompraOvr = ' + IntSql(AOverride.LeadTimeCompraOvr) + ', ' +
      '  LoteMinimoOvr = ' + FloatSql(AOverride.LoteMinimoOvr) + ', ' +
      '  PuntoPedidoOvr = ' + FloatSql(AOverride.PuntoPedidoOvr) + ', ' +
      '  ProveedorPreferenteOvr = ' + StrSql(AOverride.ProveedorPreferenteOvr) + ', ' +
      '  HorizonteDias = ' + IntSql(AOverride.HorizonteDias) + ', ' +
      '  IncluirEnMrp = ' + IntToStr(Ord(AOverride.IncluirEnMrp)) + ', ' +
      '  Observaciones = ' + StrSql(AOverride.Observaciones) + ', ' +
      '  FechaModificacion = GETDATE() ' +
      'WHEN NOT MATCHED THEN INSERT (CodigoEmpresa, CodigoArticulo, CodigoAlmacen, ' +
      '  TipoReposicion, MultiploCompra, DiasCoberturaObjetivo, LeadTimeFabricacion, ' +
      '  StockSeguridadOvr, LeadTimeCompraOvr, LoteMinimoOvr, PuntoPedidoOvr, ' +
      '  ProveedorPreferenteOvr, HorizonteDias, IncluirEnMrp, Observaciones) ' +
      'VALUES (' + IntToStr(FCodigoEmpresa) + ', ' +
      StrSql(AOverride.CodigoArticulo) + ', ' + StrSql(AOverride.CodigoAlmacen) + ', ' +
      tipoSql + ', ' + FloatSql(AOverride.MultiploCompra) + ', ' +
      IntSql(AOverride.DiasCoberturaObjetivo) + ', ' + IntSql(AOverride.LeadTimeFabricacion) + ', ' +
      FloatSql(AOverride.StockSeguridadOvr) + ', ' + IntSql(AOverride.LeadTimeCompraOvr) + ', ' +
      FloatSql(AOverride.LoteMinimoOvr) + ', ' + FloatSql(AOverride.PuntoPedidoOvr) + ', ' +
      StrSql(AOverride.ProveedorPreferenteOvr) + ', ' + IntSql(AOverride.HorizonteDias) + ', ' +
      IntToStr(Ord(AOverride.IncluirEnMrp)) + ', ' + StrSql(AOverride.Observaciones) + ');';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
  FOverrides.AddOrSetValue(
    MakeKey(AOverride.CodigoArticulo, AOverride.CodigoAlmacen), AOverride);
end;

procedure TMrpParamRepo.Delete(const AArticulo, AAlmacen: string);
var
  Cmd: TADOCommand;
begin
  if FConnection = nil then Exit;
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.ParamCheck := False;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_MrpParam WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      ' AND CodigoArticulo = ''' + StringReplace(AArticulo, '''', '''''', [rfReplaceAll]) + '''' +
      ' AND CodigoAlmacen = ''' + StringReplace(AAlmacen, '''', '''''', [rfReplaceAll]) + '''';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
  FOverrides.Remove(MakeKey(AArticulo, AAlmacen));
end;

function TMrpParamRepo.GetAll: TArray<TMrpParamOverride>;
begin
  Result := FOverrides.Values.ToArray;
end;

end.
