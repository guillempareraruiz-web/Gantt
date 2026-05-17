unit uSage200Reader;

// ============================================================================
// Implementacio concreta de IErpReader per a Sage 200.
//
// Encapsula tota la logica de connexio i totes les queries especifiques de
// Sage. Tradueix dels camps Sage (CabeceraPedidoCliente, Mat_Formula,
// Oper_Formula, etc.) als tipus neutres de uErpTypes.
//
// Cap pantalla ha de tocar TSage200Reader directament. S'instancia via
// uErpReaderFactory.GetActiveErpReader.
// ============================================================================

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Math,
  System.Generics.Collections,
  Data.Win.ADODB, Data.DB,
  uErpReader, uErpTypes, uAppConfig;

type
  TSage200Reader = class(TInterfacedObject, IErpReader)
  private
    FCfg: TErpSage200Config;
    FConn: TADOConnection;
    FCodigoEmpresa: SmallInt;
    function ParseCodigoEmpresa: SmallInt;
    function BuildConnectionString: string;
  public
    constructor Create; overload;
    constructor Create(const ACfg: TErpSage200Config); overload;
    destructor Destroy; override;

    // IErpReader
    function GetSistemaNombre: string;
    procedure EnsureConnected;
    function ReadPedidoCabecera(const ASerie: string; ANumero: Integer;
      AEjercicio: SmallInt): TPedidoCabecera;
    function ReadPedidoLineas(const ASerie: string; ANumero: Integer;
      AEjercicio: SmallInt): TArray<TPedidoLinea>;
    function ReadPedidosCabecera(AEjercicio: SmallInt; const ASerie: string;
      ANumero: Integer): TArray<TPedidoCabecera>;
    function ReadPedidosLineas(AEjercicio: SmallInt; const ASerie: string;
      ANumero: Integer): TArray<TPedidoLinea>;
    function ReadFormulaVersiones(const ACodigoArticulo: string): TArray<SmallInt>;
    function ReadFormulaCabecera(const ACodigoArticulo: string): TFormulaCabecera;
    function ReadFormulaComponentes(const ACodigoArticulo: string;
      AVersion: SmallInt): TArray<TFormulaComponente>;
    function ReadFormulaOperaciones(const ACodigoArticulo: string;
      AVersion: SmallInt): TArray<TFormulaOperacion>;
    function ReadDondeSeUsa(const ACodigoArticulo: string): TArray<TDondeSeUsaErp>;
    function ReadHistoricoMensual(const ACodigoArticulo: string;
      const AAlmacenes: TArray<string>;
      AMesesAtras: Integer): TArray<THistoricoMesErp>;
    function ReadEmpresas: TArray<TEmpresaErp>;
    function ReadArticulos(const AFiltroCodigo: string): TArray<TArticuloErp>;
    function ReadCentrosTrabajo: TArray<TCentroTrabajoErp>;
    function ReadMaquinas: TArray<TMaquinaErp>;
    function ReadOperarios: TArray<TOperarioErp>;
    function ReadCentrosMaquinas(const ACentroTrabajo: string): TArray<TCentroMaquinaErp>;
    function ReadFamilias: TArray<TFamiliaErp>;
    function ReadClientes(const AFiltroCodigo: string): TArray<TClienteErp>;
    function ReadAlmacenes: TArray<TAlmacenErp>;
    function ReadOrdenesFabricacion(AEjercicio: SmallInt; const ASerie: string;
      ANumero: Integer): TArray<TOrdenFabricacionErp>;
    function ReadOrdenesTrabajo(AEjercicioTrabajo: SmallInt;
      ANumeroTrabajo: Integer): TArray<TOrdenTrabajoErp>;
    function ReadOperacionesOT(AEjercicioTrabajo: SmallInt;
      ANumeroTrabajo: Integer): TArray<TOperacionOTErp>;
    function ReadConsumosOT(AEjercicioTrabajo: SmallInt;
      ANumeroTrabajo: Integer): TArray<TConsumoOTErp>;
    function ReadRelacionOTOF(AEjercicioFabricacion: SmallInt;
      const ASerieFabricacion: string; ANumeroFabricacion: Integer): TArray<TRelacionOTOFErp>;
    function ReadProyectos(const AFiltroCodigo: string): TArray<TProyectoErp>;
    function ReadTareasProyecto(const ACodigoProyecto: string): TArray<TTareaProyectoErp>;
    function ReadGruposHorarios: TArray<TGrupoHorarioErp>;
    function ReadModelosHorarios: TArray<TModeloHorarioErp>;
    function ReadLineasModeloHorario(AModeloHorario: Integer): TArray<TLineaModeloHorarioErp>;
    function ReadCalendarioCentro(const ACentroTrabajo: string;
      AFechaDesde, AFechaHasta: TDateTime): TArray<TCalendarioCentroErp>;
    function ReadStockArticulo(const ACodigoArticulo, ACodigoAlmacen,
      APartida: string; AEjercicio: SmallInt;
      APeriodo: SmallInt): TArray<TStockArticuloErp>;
    function ReadStockDisponible(const ACodigoArticulo,
      ACodigoAlmacen: string): TArray<TStockDisponibleErp>;
    function ReadEntradasFuturas(const ACodigoArticulo: string;
      AFechaDesde, AFechaHasta: TDateTime): TArray<TEntradaFuturaErp>;
    function ReadEntradasFuturasFiltered(const ACodigoArticulo: string;
      const AAlmacenes: TArray<string>;
      AFechaDesde, AFechaHasta: TDateTime): TArray<TEntradaFuturaErp>;
    function ReadSalidasFuturasVenta(const ACodigoArticulo: string;
      const AAlmacenes: TArray<string>;
      AFechaDesde, AFechaHasta: TDateTime): TArray<TSalidaFuturaVentaErp>;
    function ReadMovimientosOFsPendientes(const ACodigoArticulo: string;
      const AAlmacenes: TArray<string>;
      AFechaHasta: TDateTime): TArray<TMovOFErp>;
    function ReadStockCritico(const AAlmacenes: TArray<string>;
      const AFiltroFamilia: string): TArray<TStockCriticoErp>;
    function ReadStockObsoleto(const AAlmacenes: TArray<string>;
      const AFiltroFamilia: string;
      AMesesSinMovimiento: Integer): TArray<TStockObsoletoErp>;
    function ReadCobertura(const AAlmacenes: TArray<string>;
      const AFiltroFamilia: string;
      ADiasHistorico: Integer): TArray<TCoberturaErp>;
    function ReadAnalisisABC(const AFiltroFamilia: string;
      ADiasHistorico: Integer): TArray<TAnalisisABCErp>;
    function ReadRupturasFuturas(const AAlmacenes: TArray<string>;
      const AFiltroFamilia: string;
      ADiasHorizonte: Integer): TArray<TRupturaFuturaErp>;
    function ReadOFsActivasArticulo(const ACodigoArticulo: string): TArray<TOFActivaArticuloErp>;
    function ReadProveedoresArticulo(const ACodigoArticulo: string;
      AMesesAtras: Integer): TArray<TProveedorArticuloErp>;
    function ReadClientesArticulo(const ACodigoArticulo: string;
      AMesesAtras: Integer): TArray<TClienteArticuloErp>;
    function ReadCoberturaArticulo(const ACodigoArticulo: string;
      const AAlmacenes: TArray<string>): TCoberturaErp;
    function ReadCategoriaABCArticulo(const ACodigoArticulo: string): string;
    function ReadOFsActivasTop(AOrdenarPorFechaFin: Boolean;
      ALimit: Integer): TArray<TOFGlobalErp>;
    function ReadArticulosAsinStock(ALimit: Integer): TArray<TArticuloACriticoErp>;
  end;

implementation

// ---------------------------------------------------------------------------
// Helpers SQL compartits (unit-level)
// ---------------------------------------------------------------------------

function BuildAlmacenesIn(const AAlmacenes: TArray<string>;
  const AFieldExpr: string): string;
var
  i: Integer;
  Lst: TStringBuilder;
begin
  if Length(AAlmacenes) = 0 then Exit('');
  Lst := TStringBuilder.Create;
  try
    Lst.Append(' AND ').Append(AFieldExpr).Append(' IN (');
    for i := 0 to High(AAlmacenes) do
    begin
      if i > 0 then Lst.Append(',');
      // QuotedStr per evitar injection (CodigoAlmacen sol ser alfanumeric).
      Lst.Append(QuotedStr(AAlmacenes[i]));
    end;
    Lst.Append(') ');
    Result := Lst.ToString;
  finally
    Lst.Free;
  end;
end;

constructor TSage200Reader.Create;
begin
  Create(LoadErpSage200Config);
end;

constructor TSage200Reader.Create(const ACfg: TErpSage200Config);
begin
  inherited Create;
  FCfg := ACfg;
  FCodigoEmpresa := ParseCodigoEmpresa;
end;

destructor TSage200Reader.Destroy;
begin
  if FConn <> nil then
    FConn.Free;
  inherited;
end;

function TSage200Reader.GetSistemaNombre: string;
begin
  Result := 'Sage 200';
end;

function TSage200Reader.ParseCodigoEmpresa: SmallInt;
var
  CodTxt: string;
  PosSep: Integer;
begin
  CodTxt := Trim(FCfg.CodigoEmpresa);
  PosSep := Pos(' ', CodTxt);
  if PosSep > 0 then CodTxt := Copy(CodTxt, 1, PosSep - 1);
  Result := StrToIntDef(CodTxt, 0);
end;

function TSage200Reader.BuildConnectionString: string;
begin
  if FCfg.WindowsAuth then
    Result := Format(
      'Provider=SQLOLEDB.1;Data Source=%s;Initial Catalog=%s;' +
      'Integrated Security=SSPI;',
      [FCfg.Server, FCfg.Database])
  else
    Result := Format(
      'Provider=SQLOLEDB.1;Data Source=%s;Initial Catalog=%s;' +
      'User ID=%s;Password=%s;',
      [FCfg.Server, FCfg.Database, FCfg.UserName, FCfg.Password]);
end;

procedure TSage200Reader.EnsureConnected;
begin
  if not FCfg.IsValid then
    raise Exception.Create('Configuraci'#243'n Sage 200 no v'#225'lida.');
  if FCodigoEmpresa = 0 then
    raise Exception.Create('C'#243'digo de empresa Sage no v'#225'lido en la configuraci'#243'n.');

  if FConn = nil then
    FConn := TADOConnection.Create(nil);
  if not FConn.Connected then
  begin
    FConn.LoginPrompt := False;
    FConn.ConnectionString := BuildConnectionString;
    FConn.Connected := True;
  end;
end;

// ---------------------------------------------------------------------------
// PEDIDOS
// ---------------------------------------------------------------------------

function TSage200Reader.ReadPedidoCabecera(const ASerie: string;
  ANumero: Integer; AEjercicio: SmallInt): TPedidoCabecera;
var
  Q: TADOQuery;
begin
  Result := Default(TPedidoCabecera);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT TOP 1 NumeroPedido, SeriePedido, EjercicioPedido, FechaPedido, ' +
      '  FechaTope, NumeroLineas, CodigoCliente, RazonSocial, Nombre, CifDni, ' +
      '  Domicilio, CodigoPostal, Municipio, Provincia, Nacion, ' +
      '  FormadePago, NumeroPlazos, CodigoDivisa, FactorCambio, ' +
      '  BaseImponible, TotalIva, ImporteLiquido, StatusAprobado, ' +
      '  ObservacionesPedido AS Comentario, ' +
      '  ObservacionesCliente AS Comentarios ' +
      'FROM dbo.CabeceraPedidoCliente ' +
      'WHERE CodigoEmpresa = :CE AND EjercicioPedido = :Ej ' +
      '  AND SeriePedido = :Ser AND NumeroPedido = :Num';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Ej').Value := AEjercicio;
    Q.Parameters.ParamByName('Ser').Value := ASerie;
    Q.Parameters.ParamByName('Num').Value := ANumero;
    Q.Open;

    if Q.Eof then
    begin
      Result.Encontrado := False;
      Exit;
    end;

    Result.Encontrado       := True;
    Result.SeriePedido      := Q.FieldByName('SeriePedido').AsString;
    Result.NumeroPedido     := Q.FieldByName('NumeroPedido').AsInteger;
    Result.EjercicioPedido  := Q.FieldByName('EjercicioPedido').AsInteger;
    Result.FechaPedido      := Q.FieldByName('FechaPedido').AsDateTime;
    Result.FechaTope        := Q.FieldByName('FechaTope').AsDateTime;
    Result.NumeroLineas     := Q.FieldByName('NumeroLineas').AsInteger;
    Result.CodigoCliente    := Q.FieldByName('CodigoCliente').AsString;
    Result.RazonSocial      := Q.FieldByName('RazonSocial').AsString;
    Result.NombreComercial  := Q.FieldByName('Nombre').AsString;
    Result.CifDni           := Q.FieldByName('CifDni').AsString;
    Result.Domicilio        := Q.FieldByName('Domicilio').AsString;
    Result.CodigoPostal     := Q.FieldByName('CodigoPostal').AsString;
    Result.Municipio        := Q.FieldByName('Municipio').AsString;
    Result.Provincia        := Q.FieldByName('Provincia').AsString;
    Result.Nacion           := Q.FieldByName('Nacion').AsString;
    Result.FormaPago        := Q.FieldByName('FormadePago').AsString;
    Result.NumeroPlazos     := Q.FieldByName('NumeroPlazos').AsInteger;
    Result.CodigoDivisa     := Q.FieldByName('CodigoDivisa').AsString;
    Result.FactorCambio     := Q.FieldByName('FactorCambio').AsFloat;
    Result.BaseImponible    := Q.FieldByName('BaseImponible').AsFloat;
    Result.TotalIva         := Q.FieldByName('TotalIva').AsFloat;
    Result.ImporteLiquido   := Q.FieldByName('ImporteLiquido').AsFloat;
    Result.Aprobado         := Q.FieldByName('StatusAprobado').AsInteger = 1;
    Result.Comentario       := Q.FieldByName('Comentario').AsString;
    Result.Comentarios      := Q.FieldByName('Comentarios').AsString;
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadPedidoLineas(const ASerie: string;
  ANumero: Integer; AEjercicio: SmallInt): TArray<TPedidoLinea>;
var
  Q: TADOQuery;
  L: TPedidoLinea;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT Orden, CodigoArticulo, DescripcionArticulo, CodigoAlmacen, ' +
      '  UnidadesPedidas AS Unidades, UnidadMedida1_ AS UnidadMedida, ' +
      '  Precio, [%Descuento] AS Descuento1, [%Descuento2] AS Descuento2, ' +
      '  ImporteLiquido, FechaEntrega AS FechaServicio, FechaNecesaria, ' +
      '  UnidadesServidas, UnidadesPendientes, ' +
      '  CAST(DescripcionLinea AS NVARCHAR(MAX)) AS Comentario ' +
      'FROM dbo.LineasPedidoCliente ' +
      'WHERE CodigoEmpresa = :CE AND EjercicioPedido = :Ej ' +
      '  AND SeriePedido = :Ser AND NumeroPedido = :Num ' +
      'ORDER BY Orden';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Ej').Value := AEjercicio;
    Q.Parameters.ParamByName('Ser').Value := ASerie;
    Q.Parameters.ParamByName('Num').Value := ANumero;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      L.Orden               := Q.FieldByName('Orden').AsInteger;
      L.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
      L.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      L.CodigoAlmacen       := Q.FieldByName('CodigoAlmacen').AsString;
      L.Unidades            := Q.FieldByName('Unidades').AsFloat;
      L.UnidadMedida        := Q.FieldByName('UnidadMedida').AsString;
      L.Precio              := Q.FieldByName('Precio').AsFloat;
      L.Descuento1          := Q.FieldByName('Descuento1').AsFloat;
      L.Descuento2          := Q.FieldByName('Descuento2').AsFloat;
      L.ImporteLiquido      := Q.FieldByName('ImporteLiquido').AsFloat;
      L.FechaServicio       := Q.FieldByName('FechaServicio').AsDateTime;
      L.FechaNecesaria      := Q.FieldByName('FechaNecesaria').AsDateTime;
      L.UnidadesServidas    := Q.FieldByName('UnidadesServidas').AsFloat;
      L.UnidadesPendientes  := Q.FieldByName('UnidadesPendientes').AsFloat;
      L.Comentario          := Q.FieldByName('Comentario').AsString;
      Result[Idx] := L;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadPedidosCabecera(AEjercicio: SmallInt;
  const ASerie: string; ANumero: Integer): TArray<TPedidoCabecera>;
var
  Q: TADOQuery;
  R: TPedidoCabecera;
  Idx: Integer;
  Serie: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Serie := Trim(ASerie);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT NumeroPedido, SeriePedido, EjercicioPedido, FechaPedido, ' +
      '  FechaTope, NumeroLineas, CodigoCliente, RazonSocial, Nombre, CifDni, ' +
      '  Domicilio, CodigoPostal, Municipio, Provincia, Nacion, ' +
      '  FormadePago, NumeroPlazos, CodigoDivisa, FactorCambio, ' +
      '  BaseImponible, TotalIva, ImporteLiquido, StatusAprobado, ' +
      '  ObservacionesPedido AS Comentario, ' +
      '  ObservacionesCliente AS Comentarios ' +
      'FROM dbo.CabeceraPedidoCliente ' +
      'WHERE CodigoEmpresa = :CE AND EjercicioPedido = :Ej ';
    if Serie <> '' then
      SQL := SQL + 'AND SeriePedido = :Ser ';
    if ANumero > 0 then
      SQL := SQL + 'AND NumeroPedido = :Num ';
    SQL := SQL + 'ORDER BY SeriePedido, NumeroPedido';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Ej').Value := AEjercicio;
    if Serie <> '' then
      Q.Parameters.ParamByName('Ser').Value := Serie;
    if ANumero > 0 then
      Q.Parameters.ParamByName('Num').Value := ANumero;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      R := Default(TPedidoCabecera);
      R.Encontrado       := True;
      R.SeriePedido      := Q.FieldByName('SeriePedido').AsString;
      R.NumeroPedido     := Q.FieldByName('NumeroPedido').AsInteger;
      R.EjercicioPedido  := Q.FieldByName('EjercicioPedido').AsInteger;
      R.FechaPedido      := Q.FieldByName('FechaPedido').AsDateTime;
      R.FechaTope        := Q.FieldByName('FechaTope').AsDateTime;
      R.NumeroLineas     := Q.FieldByName('NumeroLineas').AsInteger;
      R.CodigoCliente    := Q.FieldByName('CodigoCliente').AsString;
      R.RazonSocial      := Q.FieldByName('RazonSocial').AsString;
      R.NombreComercial  := Q.FieldByName('Nombre').AsString;
      R.CifDni           := Q.FieldByName('CifDni').AsString;
      R.Domicilio        := Q.FieldByName('Domicilio').AsString;
      R.CodigoPostal     := Q.FieldByName('CodigoPostal').AsString;
      R.Municipio        := Q.FieldByName('Municipio').AsString;
      R.Provincia        := Q.FieldByName('Provincia').AsString;
      R.Nacion           := Q.FieldByName('Nacion').AsString;
      R.FormaPago        := Q.FieldByName('FormadePago').AsString;
      R.NumeroPlazos     := Q.FieldByName('NumeroPlazos').AsInteger;
      R.CodigoDivisa     := Q.FieldByName('CodigoDivisa').AsString;
      R.FactorCambio     := Q.FieldByName('FactorCambio').AsFloat;
      R.BaseImponible    := Q.FieldByName('BaseImponible').AsFloat;
      R.TotalIva         := Q.FieldByName('TotalIva').AsFloat;
      R.ImporteLiquido   := Q.FieldByName('ImporteLiquido').AsFloat;
      R.Aprobado         := Q.FieldByName('StatusAprobado').AsInteger = 1;
      R.Comentario       := Q.FieldByName('Comentario').AsString;
      R.Comentarios      := Q.FieldByName('Comentarios').AsString;
      Result[Idx] := R;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadPedidosLineas(AEjercicio: SmallInt;
  const ASerie: string; ANumero: Integer): TArray<TPedidoLinea>;
var
  Q: TADOQuery;
  L: TPedidoLinea;
  Idx: Integer;
  Serie: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Serie := Trim(ASerie);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT SeriePedido, NumeroPedido, EjercicioPedido, Orden, ' +
      '  CodigoArticulo, DescripcionArticulo, CodigoAlmacen, ' +
      '  UnidadesPedidas AS Unidades, UnidadMedida1_ AS UnidadMedida, ' +
      '  Precio, [%Descuento] AS Descuento1, [%Descuento2] AS Descuento2, ' +
      '  ImporteLiquido, FechaEntrega AS FechaServicio, FechaNecesaria, ' +
      '  UnidadesServidas, UnidadesPendientes, ' +
      '  CAST(DescripcionLinea AS NVARCHAR(MAX)) AS Comentario ' +
      'FROM dbo.LineasPedidoCliente ' +
      'WHERE CodigoEmpresa = :CE AND EjercicioPedido = :Ej ';
    if Serie <> '' then
      SQL := SQL + 'AND SeriePedido = :Ser ';
    if ANumero > 0 then
      SQL := SQL + 'AND NumeroPedido = :Num ';
    SQL := SQL + 'ORDER BY SeriePedido, NumeroPedido, Orden';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Ej').Value := AEjercicio;
    if Serie <> '' then
      Q.Parameters.ParamByName('Ser').Value := Serie;
    if ANumero > 0 then
      Q.Parameters.ParamByName('Num').Value := ANumero;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      L := Default(TPedidoLinea);
      L.Orden               := Q.FieldByName('Orden').AsInteger;
      L.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
      L.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      L.CodigoAlmacen       := Q.FieldByName('CodigoAlmacen').AsString;
      L.Unidades            := Q.FieldByName('Unidades').AsFloat;
      L.UnidadMedida        := Q.FieldByName('UnidadMedida').AsString;
      L.Precio              := Q.FieldByName('Precio').AsFloat;
      L.Descuento1          := Q.FieldByName('Descuento1').AsFloat;
      L.Descuento2          := Q.FieldByName('Descuento2').AsFloat;
      L.ImporteLiquido      := Q.FieldByName('ImporteLiquido').AsFloat;
      L.FechaServicio       := Q.FieldByName('FechaServicio').AsDateTime;
      L.FechaNecesaria      := Q.FieldByName('FechaNecesaria').AsDateTime;
      L.UnidadesServidas    := Q.FieldByName('UnidadesServidas').AsFloat;
      L.UnidadesPendientes  := Q.FieldByName('UnidadesPendientes').AsFloat;
      L.Comentario          := Q.FieldByName('Comentario').AsString;
      Result[Idx] := L;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// FORMULAS
// ---------------------------------------------------------------------------

function TSage200Reader.ReadFormulaVersiones(
  const ACodigoArticulo: string): TArray<SmallInt>;
var
  Q: TADOQuery;
  L: TList<SmallInt>;
begin
  SetLength(Result, 0);
  EnsureConnected;
  L := TList<SmallInt>.Create;
  try
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConn;
      Q.SQL.Text :=
        'SELECT Formula FROM dbo.Formulas ' +
        'WHERE CodigoEmpresa = :CE AND CodigoArticulo = :Art ' +
        'ORDER BY Formula';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('Art').Value := ACodigoArticulo;
      Q.Open;
      while not Q.Eof do
      begin
        L.Add(Q.FieldByName('Formula').AsInteger);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TSage200Reader.ReadFormulaCabecera(
  const ACodigoArticulo: string): TFormulaCabecera;
var
  Q: TADOQuery;
begin
  Result := Default(TFormulaCabecera);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT TOP 1 Formula, CodigoArticulo, DescripcionArticulo, ' +
      '  CosteArticulos ' +
      'FROM dbo.Formulas ' +
      'WHERE CodigoEmpresa = :CE AND CodigoArticulo = :Art ' +
      'ORDER BY Formula';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Art').Value := ACodigoArticulo;
    Q.Open;

    if Q.Eof then
    begin
      Result.Encontrada := False;
      Exit;
    end;
    Result.Encontrada          := True;
    Result.Version             := Q.FieldByName('Formula').AsInteger;
    Result.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
    Result.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
    Result.CosteArticulos      := Q.FieldByName('CosteArticulos').AsFloat;
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadFormulaComponentes(const ACodigoArticulo: string;
  AVersion: SmallInt): TArray<TFormulaComponente>;
var
  Q: TADOQuery;
  C: TFormulaComponente;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT Orden, ArticuloComponente, DescripcionArticulo, ' +
      '  UnidadesNecesarias, UnidadMedida1_, Mermas, CosteUnitario, ' +
      '  CosteComponente, FormulaComponente, Operacion ' +
      'FROM dbo.Mat_Formula ' +
      'WHERE CodigoEmpresa = :CE AND CodigoArticulo = :Art ' +
      '  AND Formula = :Form ' +
      'ORDER BY Orden';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Art').Value := ACodigoArticulo;
    Q.Parameters.ParamByName('Form').Value := AVersion;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      C.Orden                    := Q.FieldByName('Orden').AsInteger;
      C.CodigoArticuloComponente := Q.FieldByName('ArticuloComponente').AsString;
      C.DescripcionArticulo      := Q.FieldByName('DescripcionArticulo').AsString;
      C.UnidadesNecesarias       := Q.FieldByName('UnidadesNecesarias').AsFloat;
      C.UnidadMedida             := Q.FieldByName('UnidadMedida1_').AsString;
      C.Mermas                   := Q.FieldByName('Mermas').AsFloat;
      C.CosteUnitario            := Q.FieldByName('CosteUnitario').AsFloat;
      C.CosteComponente          := Q.FieldByName('CosteComponente').AsFloat;
      C.VersionFormulaComp       := Q.FieldByName('FormulaComponente').AsInteger;
      C.EsSemielaborado          := C.VersionFormulaComp > 0;
      C.OperacionAsociada        := Q.FieldByName('Operacion').AsString;
      Result[Idx] := C;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadFormulaOperaciones(const ACodigoArticulo: string;
  AVersion: SmallInt): TArray<TFormulaOperacion>;
var
  Q: TADOQuery;
  O: TFormulaOperacion;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT Orden, Operacion, DescripcionOperacion, CentroTrabajo, ' +
      '  TiempoPreparacion, TiempoFabricacion, TiempoTotal, OperacionExterna ' +
      'FROM dbo.Oper_Formula ' +
      'WHERE CodigoEmpresa = :CE AND CodigoArticulo = :Art ' +
      '  AND Formula = :Form ' +
      'ORDER BY Orden';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Art').Value := ACodigoArticulo;
    Q.Parameters.ParamByName('Form').Value := AVersion;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      O.Orden                := Q.FieldByName('Orden').AsInteger;
      O.Operacion            := Q.FieldByName('Operacion').AsString;
      O.DescripcionOperacion := Q.FieldByName('DescripcionOperacion').AsString;
      O.CentroTrabajo        := Q.FieldByName('CentroTrabajo').AsString;
      O.TiempoPreparacionMin := Q.FieldByName('TiempoPreparacion').AsFloat;
      O.TiempoFabricacionMin := Q.FieldByName('TiempoFabricacion').AsFloat;
      O.TiempoTotalMin       := Q.FieldByName('TiempoTotal').AsFloat;
      O.EsExterna            := Q.FieldByName('OperacionExterna').AsInteger <> 0;
      Result[Idx] := O;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// DONDE SE USA (where-used)
// ---------------------------------------------------------------------------

function TSage200Reader.ReadDondeSeUsa(
  const ACodigoArticulo: string): TArray<TDondeSeUsaErp>;
var
  Q: TADOQuery;
  D: TDondeSeUsaErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT M.CodigoArticulo, M.Formula, M.Orden, ' +
      '  M.UnidadesNecesarias, M.UnidadMedida1_ AS UnidadMedida, ' +
      '  M.Mermas, M.Operacion, ' +
      '  A.DescripcionArticulo, A.TipoArticulo ' +
      'FROM dbo.Mat_Formula M ' +
      'LEFT JOIN dbo.Articulos A ' +
      '  ON A.CodigoEmpresa = M.CodigoEmpresa ' +
      ' AND A.CodigoArticulo = M.CodigoArticulo ' +
      'WHERE M.CodigoEmpresa = :CE ' +
      '  AND M.ArticuloComponente = :Art ' +
      'ORDER BY M.CodigoArticulo, M.Formula, M.Orden';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Art').Value := ACodigoArticulo;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      D := Default(TDondeSeUsaErp);
      D.CodigoArticuloPadre      := Q.FieldByName('CodigoArticulo').AsString;
      D.DescripcionArticuloPadre := Q.FieldByName('DescripcionArticulo').AsString;
      D.TipoArticuloPadre        := Q.FieldByName('TipoArticulo').AsString;
      D.VersionFormula           := Q.FieldByName('Formula').AsInteger;
      D.Orden                    := Q.FieldByName('Orden').AsInteger;
      D.UnidadesNecesarias       := Q.FieldByName('UnidadesNecesarias').AsFloat;
      D.UnidadMedida             := Q.FieldByName('UnidadMedida').AsString;
      D.Mermas                   := Q.FieldByName('Mermas').AsFloat;
      D.Operacion                := Q.FieldByName('Operacion').AsString;
      Result[Idx] := D;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// HISTORICO MENSUAL DE UN ARTICULO
// ---------------------------------------------------------------------------

function TSage200Reader.ReadHistoricoMensual(const ACodigoArticulo: string;
  const AAlmacenes: TArray<string>;
  AMesesAtras: Integer): TArray<THistoricoMesErp>;
var
  Q, QChk: TADOQuery;
  H: THistoricoMesErp;
  Idx: Integer;
  EjActual: SmallInt;
  PerActual: SmallInt;
  EjMin: SmallInt;
  PerMin: SmallInt;
  EjMaxBD: SmallInt;
  PerMaxBD: SmallInt;
  SQL: string;
  TotalFiles: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;
  if AMesesAtras <= 0 then AMesesAtras := 12;

  // Sanity check: l'article te ALGUNA fila amb Periodo 1..12 a AcumuladoStock?
  // I quin Ejercicio/Periodo es l'ultim disponible per a aquest article?
  QChk := TADOQuery.Create(nil);
  try
    QChk.Connection := FConn;
    // CTE: total files + ultim Ejercicio + ultim Periodo dins aquell Ejercicio.
    // ADO no accepta paramentres amb el mateix nom repetits; per evitar
    // multiplicar paramentres, interpolem CE (enter) i fem servir QuotedStr
    // per a l'article (no permet injection, validem que no porti cometes).
    QChk.SQL.Text :=
      'WITH Ult AS ( ' +
      '  SELECT MAX(Ejercicio) AS EjMax ' +
      '  FROM dbo.AcumuladoStock ' +
      '  WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '    AND CodigoArticulo = ' + QuotedStr(ACodigoArticulo) + ' ' +
      '    AND Periodo BETWEEN 1 AND 12 ' +
      ') ' +
      'SELECT ' +
      '  (SELECT COUNT(*) FROM dbo.AcumuladoStock ' +
      '   WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '     AND CodigoArticulo = ' + QuotedStr(ACodigoArticulo) + ' ' +
      '     AND Periodo BETWEEN 1 AND 12) AS N, ' +
      '  Ult.EjMax, ' +
      '  (SELECT MAX(Periodo) FROM dbo.AcumuladoStock ' +
      '   WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '     AND CodigoArticulo = ' + QuotedStr(ACodigoArticulo) + ' ' +
      '     AND Periodo BETWEEN 1 AND 12 AND Ejercicio = Ult.EjMax) AS PerMaxUlt ' +
      'FROM Ult';
    QChk.Open;
    if QChk.Eof then
    begin
      TotalFiles := 0;
      EjMaxBD := 0;
      PerMaxBD := 0;
    end
    else
    begin
      TotalFiles := QChk.FieldByName('N').AsInteger;
      if QChk.FieldByName('EjMax').IsNull then EjMaxBD := 0
      else EjMaxBD := QChk.FieldByName('EjMax').AsInteger;
      if QChk.FieldByName('PerMaxUlt').IsNull then PerMaxBD := 0
      else PerMaxBD := QChk.FieldByName('PerMaxUlt').AsInteger;
    end;
  finally
    QChk.Free;
  end;

  if TotalFiles = 0 then Exit;

  // Si la BD te dades d'un Ejercicio anterior a l'actual del rellotge,
  // anclem el "ara" a l'ultim Ej/Per amb dades reals.
  EjActual := YearOf(Date);
  PerActual := MonthOf(Date);
  if (EjMaxBD > 0) and
     ((EjMaxBD < EjActual) or
      ((EjMaxBD = EjActual) and (PerMaxBD > 0) and (PerMaxBD < PerActual))) then
  begin
    EjActual := EjMaxBD;
    if PerMaxBD > 0 then
      PerActual := PerMaxBD;
  end;
  // Ej/Per minim: retrocedim AMesesAtras-1 mesos (incluint el mes actual).
  PerMin := PerActual - (AMesesAtras - 1);
  EjMin := EjActual;
  while PerMin <= 0 do
  begin
    Inc(PerMin, 12);
    Dec(EjMin);
  end;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    // Filtre temporal: (Ej > EjMin) OR (Ej = EjMin AND Per >= PerMin)
    //              AND (Ej < EjActual) OR (Ej = EjActual AND Per <= PerActual)
    SQL :=
      // NOTA: AcumuladoStock NO te CosteEntrada (Sage valora nomes la sortida).
      // CosteEntrada queda a 0; CosteSalida es el cost real consumit.
      'SELECT Ejercicio, Periodo, ' +
      '  SUM(UnidadEntrada)  AS UnidadEntrada, ' +
      '  SUM(UnidadSalida)   AS UnidadSalida, ' +
      '  SUM(CosteSalida)    AS CosteSalida ' +
      'FROM dbo.AcumuladoStock ' +
      'WHERE CodigoEmpresa = :CE ' +
      '  AND CodigoArticulo = :Art ' +
      '  AND Periodo BETWEEN 1 AND 12 ' +
      '  AND ((Ejercicio > :EjMin) OR (Ejercicio = :EjMin2 AND Periodo >= :PerMin)) ' +
      '  AND ((Ejercicio < :EjAct) OR (Ejercicio = :EjAct2 AND Periodo <= :PerAct)) ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'CodigoAlmacen');
    SQL := SQL +
      'GROUP BY Ejercicio, Periodo ' +
      'ORDER BY Ejercicio, Periodo';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Art').Value := ACodigoArticulo;
    Q.Parameters.ParamByName('EjMin').Value := EjMin;
    Q.Parameters.ParamByName('EjMin2').Value := EjMin;
    Q.Parameters.ParamByName('PerMin').Value := PerMin;
    Q.Parameters.ParamByName('EjAct').Value := EjActual;
    Q.Parameters.ParamByName('EjAct2').Value := EjActual;
    Q.Parameters.ParamByName('PerAct').Value := PerActual;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      H := Default(THistoricoMesErp);
      H.Ejercicio       := Q.FieldByName('Ejercicio').AsInteger;
      H.Periodo         := Q.FieldByName('Periodo').AsInteger;
      H.UnidadesEntrada := Q.FieldByName('UnidadEntrada').AsFloat;
      H.UnidadesSalida  := Q.FieldByName('UnidadSalida').AsFloat;
      H.CosteEntrada    := 0;
      H.CosteSalida     := Q.FieldByName('CosteSalida').AsFloat;
      Result[Idx] := H;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// EMPRESAS
// ---------------------------------------------------------------------------

function TSage200Reader.ReadEmpresas: TArray<TEmpresaErp>;
var
  Q: TADOQuery;
  E: TEmpresaErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT CodigoEmpresa, Empresa ' +
      'FROM dbo.Empresas ' +
      'ORDER BY CodigoEmpresa';
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      E.Codigo := Q.FieldByName('CodigoEmpresa').AsInteger;
      E.Nombre := Q.FieldByName('Empresa').AsString;
      Result[Idx] := E;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// ARTICULOS
// ---------------------------------------------------------------------------

function TSage200Reader.ReadArticulos(
  const AFiltroCodigo: string): TArray<TArticuloErp>;
var
  Q: TADOQuery;
  A: TArticuloErp;
  Idx: Integer;
  Filtro: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Filtro := Trim(AFiltroCodigo);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT CodigoArticulo, DescripcionArticulo, Descripcion2Articulo, ' +
      '  TipoArticulo, CodigoFamilia, CodigoSubfamilia, ' +
      '  UnidadMedida2_ AS UnidadMedida, ' +
      '  StockMinimo, StockMaximo, ' +
      '  PrecioCompra, PrecioVenta, ' +
      '  CosteFabricacionUnitario, PrecioCosteEstandar, ' +
      '  BloqueoCompra, BloqueoPedidoCompra, BloqueoPedidoVenta, ' +
      '  PublicarInternet, FechaAlta, Utilizado, ' +
      '  CAST(CASE WHEN EXISTS(SELECT 1 FROM dbo.Formulas F ' +
      '    WHERE F.CodigoEmpresa = A.CodigoEmpresa ' +
      '      AND F.CodigoArticulo = A.CodigoArticulo) THEN 1 ELSE 0 END AS bit) AS TieneFormula ' +
      'FROM dbo.Articulos A ' +
      'WHERE A.CodigoEmpresa = :CE ';
    if Filtro <> '' then
      SQL := SQL + 'AND A.CodigoArticulo LIKE :Filtro ';
    SQL := SQL + 'ORDER BY A.CodigoArticulo';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    if Filtro <> '' then
      Q.Parameters.ParamByName('Filtro').Value := '%' + Filtro + '%';
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      A := Default(TArticuloErp);
      A.Codigo                   := Q.FieldByName('CodigoArticulo').AsString;
      A.Descripcion              := Q.FieldByName('DescripcionArticulo').AsString;
      A.Descripcion2             := Q.FieldByName('Descripcion2Articulo').AsString;
      A.TipoArticulo             := Q.FieldByName('TipoArticulo').AsString;
      A.CodigoFamilia            := Q.FieldByName('CodigoFamilia').AsString;
      A.CodigoSubfamilia         := Q.FieldByName('CodigoSubfamilia').AsString;
      A.UnidadMedida             := Q.FieldByName('UnidadMedida').AsString;
      A.StockMinimo              := Q.FieldByName('StockMinimo').AsFloat;
      A.StockMaximo              := Q.FieldByName('StockMaximo').AsFloat;
      A.PrecioCompra             := Q.FieldByName('PrecioCompra').AsFloat;
      A.PrecioVenta              := Q.FieldByName('PrecioVenta').AsFloat;
      A.CosteFabricacionUnitario := Q.FieldByName('CosteFabricacionUnitario').AsFloat;
      A.PrecioCosteEstandar      := Q.FieldByName('PrecioCosteEstandar').AsFloat;
      A.BloqueoCompra            := Q.FieldByName('BloqueoCompra').AsInteger <> 0;
      A.BloqueoPedidoCompra      := Q.FieldByName('BloqueoPedidoCompra').AsInteger <> 0;
      A.BloqueoPedidoVenta       := Q.FieldByName('BloqueoPedidoVenta').AsInteger <> 0;
      A.PublicarInternet         := Q.FieldByName('PublicarInternet').AsInteger <> 0;
      if not Q.FieldByName('FechaAlta').IsNull then
        A.FechaAlta := Q.FieldByName('FechaAlta').AsDateTime;
      A.Activo := Q.FieldByName('Utilizado').AsInteger <> 0;
      A.TieneFormula := Q.FieldByName('TieneFormula').AsBoolean;
      Result[Idx] := A;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// CENTROS DE TRABAJO
// ---------------------------------------------------------------------------

function TSage200Reader.ReadCentrosTrabajo: TArray<TCentroTrabajoErp>;
var
  Q: TADOQuery;
  C: TCentroTrabajoErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    // Camps amb '%' al nom: cal envoltar amb claudators a SQL Server.
    Q.SQL.Text :=
      'SELECT CentroTrabajo, DescripcionCentro, ' +
      '  PermiteConcurrencia, MaquinasFabricacion, ' +
      '  OperariosFabricacion, OperariosPreparacion, ' +
      '  [%DedicacionOperario] AS PctDedicacionOperario, ' +
      '  [%CorreccionPreparacion] AS PctCorreccionPrep, ' +
      '  [%CorreccionFabricacion] AS PctCorreccionFab, ' +
      '  CosteHoraManoObra, CosteHoraMaquina, ' +
      '  GrupoHorario, Maquina ' +
      'FROM dbo.CentrosTrabajo ' +
      'WHERE CodigoEmpresa = :CE ' +
      'ORDER BY CentroTrabajo';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      C := Default(TCentroTrabajoErp);
      C.Codigo                          := Q.FieldByName('CentroTrabajo').AsString;
      C.Descripcion                     := Q.FieldByName('DescripcionCentro').AsString;
      C.PermiteConcurrencia             := Q.FieldByName('PermiteConcurrencia').AsInteger <> 0;
      C.MaquinasFabricacion             := Q.FieldByName('MaquinasFabricacion').AsInteger;
      C.OperariosFabricacion            := Q.FieldByName('OperariosFabricacion').AsInteger;
      C.OperariosPreparacion            := Q.FieldByName('OperariosPreparacion').AsInteger;
      C.PorcentajeDedicacionOperario    := Q.FieldByName('PctDedicacionOperario').AsFloat;
      C.PorcentajeCorreccionPreparacion := Q.FieldByName('PctCorreccionPrep').AsFloat;
      C.PorcentajeCorreccionFabricacion := Q.FieldByName('PctCorreccionFab').AsFloat;
      C.CosteHoraManoObra               := Q.FieldByName('CosteHoraManoObra').AsFloat;
      C.CosteHoraMaquina                := Q.FieldByName('CosteHoraMaquina').AsFloat;
      C.GrupoHorario                    := Q.FieldByName('GrupoHorario').AsString;
      C.MaquinaPrincipal                := Q.FieldByName('Maquina').AsString;
      Result[Idx] := C;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// MAQUINAS
// ---------------------------------------------------------------------------

function TSage200Reader.ReadMaquinas: TArray<TMaquinaErp>;
var
  Q: TADOQuery;
  M: TMaquinaErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT Maquina, MarcaMaquina, ModeloMaquina, DescripcionMaquina, ' +
      '  [%CorreccionPreparacion] AS PctCorreccionPrep, ' +
      '  [%CorreccionFabricacion] AS PctCorreccionFab, ' +
      '  CosteHoraMaquina, UnidadesHora ' +
      'FROM dbo.Maquinas ' +
      'WHERE CodigoEmpresa = :CE ' +
      'ORDER BY Maquina';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      M := Default(TMaquinaErp);
      M.Codigo                          := Q.FieldByName('Maquina').AsString;
      M.Marca                           := Q.FieldByName('MarcaMaquina').AsString;
      M.Modelo                          := Q.FieldByName('ModeloMaquina').AsString;
      M.Descripcion                     := Q.FieldByName('DescripcionMaquina').AsString;
      M.PorcentajeCorreccionPreparacion := Q.FieldByName('PctCorreccionPrep').AsFloat;
      M.PorcentajeCorreccionFabricacion := Q.FieldByName('PctCorreccionFab').AsFloat;
      M.CosteHoraMaquina                := Q.FieldByName('CosteHoraMaquina').AsFloat;
      M.UnidadesHora                    := Q.FieldByName('UnidadesHora').AsFloat;
      Result[Idx] := M;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// OPERARIOS
// ---------------------------------------------------------------------------

function TSage200Reader.ReadOperarios: TArray<TOperarioErp>;
var
  Q: TADOQuery;
  O: TOperarioErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT Operario, NombreOperario, FechaAlta, FechaBaja, ' +
      '  Cargo1 AS Cargo, CosteHoraNormal, CosteHoraExtra, ' +
      '  Turno, GrupoHorario, Telefono, EMail1 AS Email ' +
      'FROM dbo.Operarios ' +
      'WHERE CodigoEmpresa = :CE ' +
      'ORDER BY Operario';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      O := Default(TOperarioErp);
      O.Codigo := Q.FieldByName('Operario').AsInteger;
      O.Nombre := Q.FieldByName('NombreOperario').AsString;
      if not Q.FieldByName('FechaAlta').IsNull then
        O.FechaAlta := Q.FieldByName('FechaAlta').AsDateTime;
      if not Q.FieldByName('FechaBaja').IsNull then
        O.FechaBaja := Q.FieldByName('FechaBaja').AsDateTime;
      O.Cargo           := Q.FieldByName('Cargo').AsString;
      O.CosteHoraNormal := Q.FieldByName('CosteHoraNormal').AsFloat;
      O.CosteHoraExtra  := Q.FieldByName('CosteHoraExtra').AsFloat;
      O.Turno           := Q.FieldByName('Turno').AsInteger;
      O.GrupoHorario    := Q.FieldByName('GrupoHorario').AsString;
      O.Telefono        := Q.FieldByName('Telefono').AsString;
      O.Email           := Q.FieldByName('Email').AsString;
      Result[Idx] := O;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// CENTROS X MAQUINAS
// ---------------------------------------------------------------------------

function TSage200Reader.ReadCentrosMaquinas(
  const ACentroTrabajo: string): TArray<TCentroMaquinaErp>;
var
  Q: TADOQuery;
  R: TCentroMaquinaErp;
  Idx: Integer;
  Centro: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Centro := Trim(ACentroTrabajo);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT CentroTrabajo, Orden, Maquina, CosteHoraMaquina, ' +
      '  [%CorreccionPreparacion] AS PctCorreccionPrep, ' +
      '  [%CorreccionFabricacion] AS PctCorreccionFab ' +
      'FROM dbo.CentrosTrabajoMaquinas ' +
      'WHERE CodigoEmpresa = :CE ';
    if Centro <> '' then
      SQL := SQL + 'AND CentroTrabajo = :CT ';
    SQL := SQL + 'ORDER BY CentroTrabajo, Orden';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    if Centro <> '' then
      Q.Parameters.ParamByName('CT').Value := Centro;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      R := Default(TCentroMaquinaErp);
      R.CentroTrabajo                   := Q.FieldByName('CentroTrabajo').AsString;
      R.Orden                           := Q.FieldByName('Orden').AsInteger;
      R.Maquina                         := Q.FieldByName('Maquina').AsString;
      R.CosteHoraMaquina                := Q.FieldByName('CosteHoraMaquina').AsFloat;
      R.PorcentajeCorreccionPreparacion := Q.FieldByName('PctCorreccionPrep').AsFloat;
      R.PorcentajeCorreccionFabricacion := Q.FieldByName('PctCorreccionFab').AsFloat;
      Result[Idx] := R;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// FAMILIAS
// ---------------------------------------------------------------------------

function TSage200Reader.ReadFamilias: TArray<TFamiliaErp>;
var
  Q: TADOQuery;
  F: TFamiliaErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT CodigoFamilia, CodigoSubfamilia, Descripcion, ' +
      '  TipoF, CodigoSeccion, CodigoDepartamento ' +
      'FROM dbo.Familias ' +
      'WHERE CodigoEmpresa = :CE ' +
      'ORDER BY CodigoFamilia, CodigoSubfamilia';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      F := Default(TFamiliaErp);
      F.CodigoFamilia      := Q.FieldByName('CodigoFamilia').AsString;
      F.CodigoSubfamilia   := Q.FieldByName('CodigoSubfamilia').AsString;
      F.Descripcion        := Q.FieldByName('Descripcion').AsString;
      F.TipoF              := Q.FieldByName('TipoF').AsString;
      F.CodigoSeccion      := Q.FieldByName('CodigoSeccion').AsString;
      F.CodigoDepartamento := Q.FieldByName('CodigoDepartamento').AsString;
      Result[Idx] := F;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// CLIENTES
// ---------------------------------------------------------------------------

function TSage200Reader.ReadClientes(
  const AFiltroCodigo: string): TArray<TClienteErp>;
var
  Q: TADOQuery;
  C: TClienteErp;
  Idx: Integer;
  Filtro: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Filtro := Trim(AFiltroCodigo);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT CodigoCliente, RazonSocial, Nombre, CifDni, Domicilio, ' +
      '  CodigoPostal, Municipio, Provincia, Nacion, Telefono, ' +
      '  EMail1 AS Email, FormadePago, CodigoDivisa, ' +
      '  BloqueoPedido, BloqueoAlbaran, FechaAlta, ' +
      '  ObservacionesCliente AS Observaciones ' +
      'FROM dbo.Clientes ' +
      'WHERE CodigoEmpresa = :CE ';
    if Filtro <> '' then
      SQL := SQL + 'AND (CodigoCliente LIKE :Filtro OR RazonSocial LIKE :Filtro2) ';
    SQL := SQL + 'ORDER BY CodigoCliente';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    if Filtro <> '' then
    begin
      Q.Parameters.ParamByName('Filtro').Value := '%' + Filtro + '%';
      Q.Parameters.ParamByName('Filtro2').Value := '%' + Filtro + '%';
    end;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      C := Default(TClienteErp);
      C.Codigo         := Q.FieldByName('CodigoCliente').AsString;
      C.RazonSocial    := Q.FieldByName('RazonSocial').AsString;
      C.Nombre         := Q.FieldByName('Nombre').AsString;
      C.CifDni         := Q.FieldByName('CifDni').AsString;
      C.Domicilio      := Q.FieldByName('Domicilio').AsString;
      C.CodigoPostal   := Q.FieldByName('CodigoPostal').AsString;
      C.Municipio      := Q.FieldByName('Municipio').AsString;
      C.Provincia      := Q.FieldByName('Provincia').AsString;
      C.Nacion         := Q.FieldByName('Nacion').AsString;
      C.Telefono       := Q.FieldByName('Telefono').AsString;
      C.Email          := Q.FieldByName('Email').AsString;
      C.FormaPago      := Q.FieldByName('FormadePago').AsString;
      C.CodigoDivisa   := Q.FieldByName('CodigoDivisa').AsString;
      C.BloqueoPedido  := Q.FieldByName('BloqueoPedido').AsInteger <> 0;
      C.BloqueoAlbaran := Q.FieldByName('BloqueoAlbaran').AsInteger <> 0;
      if not Q.FieldByName('FechaAlta').IsNull then
        C.FechaAlta := Q.FieldByName('FechaAlta').AsDateTime;
      C.Observaciones  := Q.FieldByName('Observaciones').AsString;
      Result[Idx] := C;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// ALMACENES
// ---------------------------------------------------------------------------

function TSage200Reader.ReadAlmacenes: TArray<TAlmacenErp>;
var
  Q: TADOQuery;
  A: TAlmacenErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT CodigoAlmacen, Almacen, GrupoAlmacen, Responsable, ' +
      '  Domicilio, CodigoPostal, Municipio, Provincia, Telefono ' +
      'FROM dbo.Almacenes ' +
      'WHERE CodigoEmpresa = :CE ' +
      'ORDER BY CodigoAlmacen';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      A := Default(TAlmacenErp);
      A.Codigo       := Q.FieldByName('CodigoAlmacen').AsString;
      A.Nombre       := Q.FieldByName('Almacen').AsString;
      A.GrupoAlmacen := Q.FieldByName('GrupoAlmacen').AsString;
      A.Responsable  := Q.FieldByName('Responsable').AsString;
      A.Domicilio    := Q.FieldByName('Domicilio').AsString;
      A.CodigoPostal := Q.FieldByName('CodigoPostal').AsString;
      A.Municipio    := Q.FieldByName('Municipio').AsString;
      A.Provincia    := Q.FieldByName('Provincia').AsString;
      A.Telefono     := Q.FieldByName('Telefono').AsString;
      Result[Idx] := A;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// ORDENES DE FABRICACION
// ---------------------------------------------------------------------------

function TSage200Reader.ReadOrdenesFabricacion(AEjercicio: SmallInt;
  const ASerie: string; ANumero: Integer): TArray<TOrdenFabricacionErp>;
var
  Q: TADOQuery;
  O: TOrdenFabricacionErp;
  Idx: Integer;
  Serie: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Serie := Trim(ASerie);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT EjercicioFabricacion, SerieFabricacion, NumeroFabricacion, ' +
      '  CodigoArticulo, DescripcionArticulo, Formula, ' +
      '  FechaCreacion, FechaLanzamiento, ' +
      '  FechaInicioPrevista, FechaFinalPrevista, ' +
      '  FechaInicioReal, FechaFinalReal, FechaEntrega, ' +
      '  UnidadesAFabricar, UnidadesFabricadas, ' +
      '  EstadoOF, Prioridad, TipoFabricacion, BloqueoPlanificacion, ' +
      '  CodigoProyecto, ' +
      '  CAST(Observaciones AS NVARCHAR(MAX)) AS Observaciones ' +
      'FROM dbo.OrdenesFabricacion ' +
      'WHERE CodigoEmpresa = :CE AND EjercicioFabricacion = :Ej ';
    if Serie <> '' then
      SQL := SQL + 'AND SerieFabricacion = :Ser ';
    if ANumero > 0 then
      SQL := SQL + 'AND NumeroFabricacion = :Num ';
    SQL := SQL + 'ORDER BY SerieFabricacion, NumeroFabricacion';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Ej').Value := AEjercicio;
    if Serie <> '' then
      Q.Parameters.ParamByName('Ser').Value := Serie;
    if ANumero > 0 then
      Q.Parameters.ParamByName('Num').Value := ANumero;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      O := Default(TOrdenFabricacionErp);
      O.EjercicioFabricacion := Q.FieldByName('EjercicioFabricacion').AsInteger;
      O.SerieFabricacion     := Q.FieldByName('SerieFabricacion').AsString;
      O.NumeroFabricacion    := Q.FieldByName('NumeroFabricacion').AsInteger;
      O.CodigoArticulo       := Q.FieldByName('CodigoArticulo').AsString;
      O.DescripcionArticulo  := Q.FieldByName('DescripcionArticulo').AsString;
      O.Formula              := Q.FieldByName('Formula').AsInteger;
      if not Q.FieldByName('FechaCreacion').IsNull then
        O.FechaCreacion := Q.FieldByName('FechaCreacion').AsDateTime;
      if not Q.FieldByName('FechaLanzamiento').IsNull then
        O.FechaLanzamiento := Q.FieldByName('FechaLanzamiento').AsDateTime;
      if not Q.FieldByName('FechaInicioPrevista').IsNull then
        O.FechaInicioPrevista := Q.FieldByName('FechaInicioPrevista').AsDateTime;
      if not Q.FieldByName('FechaFinalPrevista').IsNull then
        O.FechaFinalPrevista := Q.FieldByName('FechaFinalPrevista').AsDateTime;
      if not Q.FieldByName('FechaInicioReal').IsNull then
        O.FechaInicioReal := Q.FieldByName('FechaInicioReal').AsDateTime;
      if not Q.FieldByName('FechaFinalReal').IsNull then
        O.FechaFinalReal := Q.FieldByName('FechaFinalReal').AsDateTime;
      if not Q.FieldByName('FechaEntrega').IsNull then
        O.FechaEntrega := Q.FieldByName('FechaEntrega').AsDateTime;
      O.UnidadesAFabricar    := Q.FieldByName('UnidadesAFabricar').AsFloat;
      O.UnidadesFabricadas   := Q.FieldByName('UnidadesFabricadas').AsFloat;
      O.EstadoOF             := Q.FieldByName('EstadoOF').AsInteger;
      O.Prioridad            := Q.FieldByName('Prioridad').AsString;
      O.TipoFabricacion      := Q.FieldByName('TipoFabricacion').AsString;
      O.BloqueoPlanificacion := Q.FieldByName('BloqueoPlanificacion').AsInteger <> 0;
      O.CodigoProyecto       := Q.FieldByName('CodigoProyecto').AsString;
      O.Observaciones        := Q.FieldByName('Observaciones').AsString;
      Result[Idx] := O;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// ORDENES DE TRABAJO
// ---------------------------------------------------------------------------

function TSage200Reader.ReadOrdenesTrabajo(AEjercicioTrabajo: SmallInt;
  ANumeroTrabajo: Integer): TArray<TOrdenTrabajoErp>;
var
  Q: TADOQuery;
  T: TOrdenTrabajoErp;
  Idx: Integer;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT EjercicioTrabajo, NumeroTrabajo, PeriodoFabricacion, Formula, ' +
      '  CodigoArticulo, DescripcionArticulo, NivelCompuesto, CodigoAlmacen, ' +
      '  FechaCreacion, FechaInicioPrevista, FechaFinalPrevista, ' +
      '  TiempoPreparacion, TiempoFabricacion, TiempoTotal, ' +
      '  EstadoOT, UnidadesAFabricar, ' +
      '  EjercicioFabricacion, SerieFabricacion, NumeroFabricacion ' +
      'FROM dbo.OrdenesTrabajo ' +
      'WHERE CodigoEmpresa = :CE AND EjercicioTrabajo = :Ej ';
    if ANumeroTrabajo > 0 then
      SQL := SQL + 'AND NumeroTrabajo = :NT ';
    SQL := SQL + 'ORDER BY NumeroTrabajo';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Ej').Value := AEjercicioTrabajo;
    if ANumeroTrabajo > 0 then
      Q.Parameters.ParamByName('NT').Value := ANumeroTrabajo;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      T := Default(TOrdenTrabajoErp);
      T.EjercicioTrabajo     := Q.FieldByName('EjercicioTrabajo').AsInteger;
      T.NumeroTrabajo        := Q.FieldByName('NumeroTrabajo').AsInteger;
      T.PeriodoFabricacion   := Q.FieldByName('PeriodoFabricacion').AsInteger;
      T.Formula              := Q.FieldByName('Formula').AsInteger;
      T.CodigoArticulo       := Q.FieldByName('CodigoArticulo').AsString;
      T.DescripcionArticulo  := Q.FieldByName('DescripcionArticulo').AsString;
      T.NivelCompuesto       := Q.FieldByName('NivelCompuesto').AsInteger;
      T.CodigoAlmacen        := Q.FieldByName('CodigoAlmacen').AsString;
      if not Q.FieldByName('FechaCreacion').IsNull then
        T.FechaCreacion := Q.FieldByName('FechaCreacion').AsDateTime;
      if not Q.FieldByName('FechaInicioPrevista').IsNull then
        T.FechaInicioPrevista := Q.FieldByName('FechaInicioPrevista').AsDateTime;
      if not Q.FieldByName('FechaFinalPrevista').IsNull then
        T.FechaFinalPrevista := Q.FieldByName('FechaFinalPrevista').AsDateTime;
      T.TiempoPreparacion    := Q.FieldByName('TiempoPreparacion').AsFloat;
      T.TiempoFabricacion    := Q.FieldByName('TiempoFabricacion').AsFloat;
      T.TiempoTotal          := Q.FieldByName('TiempoTotal').AsFloat;
      T.EstadoOT             := Q.FieldByName('EstadoOT').AsInteger;
      T.UnidadesAFabricar    := Q.FieldByName('UnidadesAFabricar').AsFloat;
      T.EjercicioFabricacion := Q.FieldByName('EjercicioFabricacion').AsInteger;
      T.SerieFabricacion     := Q.FieldByName('SerieFabricacion').AsString;
      T.NumeroFabricacion    := Q.FieldByName('NumeroFabricacion').AsInteger;
      Result[Idx] := T;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadOperacionesOT(AEjercicioTrabajo: SmallInt;
  ANumeroTrabajo: Integer): TArray<TOperacionOTErp>;
var
  Q: TADOQuery;
  O: TOperacionOTErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;
  if ANumeroTrabajo <= 0 then
    raise Exception.Create('NumeroTrabajo es obligatorio para leer operaciones de OT.');
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT EjercicioTrabajo, NumeroTrabajo, Orden, ' +
      '  Operacion, DescripcionOperacion, ' +
      '  CentroTrabajo, CentroTrabajoDefecto, OperacionExterna, ' +
      '  TiempoPreparacion, TiempoFabricacion, TiempoTotal, ' +
      '  UnidadesAFabricar, UnidadesFabricadas, ' +
      '  CosteHoraMaquina, CosteHoraManoObra, ' +
      '  [%ParaSigOperacion] AS PctParaSigOp, ' +
      '  [%DedicacionOperario] AS PctDedicOperario, ' +
      '  FechaInicioPrevista, FechaFinalPrevista, ' +
      '  FechaInicioReal, FechaFinalReal, ' +
      '  EstadoOperacion, StatusPlanificado ' +
      'FROM dbo.OperacionesOT ' +
      'WHERE CodigoEmpresa = :CE AND EjercicioTrabajo = :Ej AND NumeroTrabajo = :NT ' +
      'ORDER BY Orden';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Ej').Value := AEjercicioTrabajo;
    Q.Parameters.ParamByName('NT').Value := ANumeroTrabajo;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      O := Default(TOperacionOTErp);
      O.EjercicioTrabajo            := Q.FieldByName('EjercicioTrabajo').AsInteger;
      O.NumeroTrabajo               := Q.FieldByName('NumeroTrabajo').AsInteger;
      O.Orden                       := Q.FieldByName('Orden').AsInteger;
      O.Operacion                   := Q.FieldByName('Operacion').AsString;
      O.DescripcionOperacion        := Q.FieldByName('DescripcionOperacion').AsString;
      O.CentroTrabajo               := Q.FieldByName('CentroTrabajo').AsString;
      O.CentroTrabajoDefecto        := Q.FieldByName('CentroTrabajoDefecto').AsString;
      O.OperacionExterna            := Q.FieldByName('OperacionExterna').AsInteger <> 0;
      O.TiempoPreparacion           := Q.FieldByName('TiempoPreparacion').AsFloat;
      O.TiempoFabricacion           := Q.FieldByName('TiempoFabricacion').AsFloat;
      O.TiempoTotal                 := Q.FieldByName('TiempoTotal').AsFloat;
      O.UnidadesAFabricar           := Q.FieldByName('UnidadesAFabricar').AsFloat;
      O.UnidadesFabricadas          := Q.FieldByName('UnidadesFabricadas').AsFloat;
      O.CosteHoraMaquina            := Q.FieldByName('CosteHoraMaquina').AsFloat;
      O.CosteHoraManoObra           := Q.FieldByName('CosteHoraManoObra').AsFloat;
      O.PorcentajeParaSigOperacion  := Q.FieldByName('PctParaSigOp').AsFloat;
      O.PorcentajeDedicacionOperario:= Q.FieldByName('PctDedicOperario').AsFloat;
      if not Q.FieldByName('FechaInicioPrevista').IsNull then
        O.FechaInicioPrevista := Q.FieldByName('FechaInicioPrevista').AsDateTime;
      if not Q.FieldByName('FechaFinalPrevista').IsNull then
        O.FechaFinalPrevista := Q.FieldByName('FechaFinalPrevista').AsDateTime;
      if not Q.FieldByName('FechaInicioReal').IsNull then
        O.FechaInicioReal := Q.FieldByName('FechaInicioReal').AsDateTime;
      if not Q.FieldByName('FechaFinalReal').IsNull then
        O.FechaFinalReal := Q.FieldByName('FechaFinalReal').AsDateTime;
      O.EstadoOperacion   := Q.FieldByName('EstadoOperacion').AsInteger;
      O.StatusPlanificado := Q.FieldByName('StatusPlanificado').AsInteger <> 0;
      Result[Idx] := O;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadConsumosOT(AEjercicioTrabajo: SmallInt;
  ANumeroTrabajo: Integer): TArray<TConsumoOTErp>;
var
  Q: TADOQuery;
  C: TConsumoOTErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;
  if ANumeroTrabajo <= 0 then
    raise Exception.Create('NumeroTrabajo es obligatorio para leer consumos de OT.');
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT EjercicioTrabajo, NumeroTrabajo, Orden, ' +
      '  ArticuloComponente, DescripcionArticulo, CodigoAlmacen, Operacion, ' +
      '  UnidadesNecesarias, UnidadesUsadas, UnidadesEntregadas, ' +
      '  Mermas, MermasReales, CosteUnitario, CosteComponente, ' +
      '  NivelCompuesto, UnidadMedida1_ AS UnidadMedida ' +
      'FROM dbo.ConsumosOT ' +
      'WHERE CodigoEmpresa = :CE AND EjercicioTrabajo = :Ej AND NumeroTrabajo = :NT ' +
      'ORDER BY Orden';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Ej').Value := AEjercicioTrabajo;
    Q.Parameters.ParamByName('NT').Value := ANumeroTrabajo;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      C := Default(TConsumoOTErp);
      C.EjercicioTrabajo    := Q.FieldByName('EjercicioTrabajo').AsInteger;
      C.NumeroTrabajo       := Q.FieldByName('NumeroTrabajo').AsInteger;
      C.Orden               := Q.FieldByName('Orden').AsInteger;
      C.ArticuloComponente  := Q.FieldByName('ArticuloComponente').AsString;
      C.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      C.CodigoAlmacen       := Q.FieldByName('CodigoAlmacen').AsString;
      C.Operacion           := Q.FieldByName('Operacion').AsString;
      C.UnidadesNecesarias  := Q.FieldByName('UnidadesNecesarias').AsFloat;
      C.UnidadesUsadas      := Q.FieldByName('UnidadesUsadas').AsFloat;
      C.UnidadesEntregadas  := Q.FieldByName('UnidadesEntregadas').AsFloat;
      C.Mermas              := Q.FieldByName('Mermas').AsFloat;
      C.MermasReales        := Q.FieldByName('MermasReales').AsFloat;
      C.CosteUnitario       := Q.FieldByName('CosteUnitario').AsFloat;
      C.CosteComponente     := Q.FieldByName('CosteComponente').AsFloat;
      C.NivelCompuesto      := Q.FieldByName('NivelCompuesto').AsInteger;
      C.UnidadMedida        := Q.FieldByName('UnidadMedida').AsString;
      Result[Idx] := C;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadRelacionOTOF(AEjercicioFabricacion: SmallInt;
  const ASerieFabricacion: string;
  ANumeroFabricacion: Integer): TArray<TRelacionOTOFErp>;
var
  Q: TADOQuery;
  R: TRelacionOTOFErp;
  Idx: Integer;
  Serie: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Serie := Trim(ASerieFabricacion);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT EjercicioFabricacion, SerieFabricacion, NumeroFabricacion, ' +
      '  EjercicioTrabajo, NumeroTrabajo, ' +
      '  EsArticuloFinal, NumeroTrabajoFinal, ' +
      '  UnidadesAFabricar, UnidadesFabricadas ' +
      'FROM dbo.RelacionOTOF ' +
      'WHERE CodigoEmpresa = :CE ';
    if AEjercicioFabricacion > 0 then
      SQL := SQL + 'AND EjercicioFabricacion = :Ej ';
    if Serie <> '' then
      SQL := SQL + 'AND SerieFabricacion = :Ser ';
    if ANumeroFabricacion > 0 then
      SQL := SQL + 'AND NumeroFabricacion = :Num ';
    SQL := SQL + 'ORDER BY EjercicioFabricacion, SerieFabricacion, NumeroFabricacion, NumeroTrabajo';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    if AEjercicioFabricacion > 0 then
      Q.Parameters.ParamByName('Ej').Value := AEjercicioFabricacion;
    if Serie <> '' then
      Q.Parameters.ParamByName('Ser').Value := Serie;
    if ANumeroFabricacion > 0 then
      Q.Parameters.ParamByName('Num').Value := ANumeroFabricacion;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      R := Default(TRelacionOTOFErp);
      R.EjercicioFabricacion := Q.FieldByName('EjercicioFabricacion').AsInteger;
      R.SerieFabricacion     := Q.FieldByName('SerieFabricacion').AsString;
      R.NumeroFabricacion    := Q.FieldByName('NumeroFabricacion').AsInteger;
      R.EjercicioTrabajo     := Q.FieldByName('EjercicioTrabajo').AsInteger;
      R.NumeroTrabajo        := Q.FieldByName('NumeroTrabajo').AsInteger;
      R.EsArticuloFinal      := Q.FieldByName('EsArticuloFinal').AsInteger <> 0;
      R.NumeroTrabajoFinal   := Q.FieldByName('NumeroTrabajoFinal').AsInteger;
      R.UnidadesAFabricar    := Q.FieldByName('UnidadesAFabricar').AsFloat;
      R.UnidadesFabricadas   := Q.FieldByName('UnidadesFabricadas').AsFloat;
      Result[Idx] := R;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// PROYECTOS / TAREAS
// ---------------------------------------------------------------------------

function TSage200Reader.ReadProyectos(
  const AFiltroCodigo: string): TArray<TProyectoErp>;
var
  Q: TADOQuery;
  P: TProyectoErp;
  Idx: Integer;
  Filtro: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Filtro := Trim(AFiltroCodigo);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT CodigoProyecto, Proyecto, CodigoTipoProyectoLc, ' +
      '  StatusProyectoLc, PorcentajeCompletadoLc, ' +
      '  FechaInicialProyectoLc, FechaFinalProyectoLc, FechaTopeProyectoLc, ' +
      '  FechaAprobacionLc, FechaCierre, ' +
      '  CodigoResponsableLc, CodigoDepartamento, ' +
      '  CAST(Observaciones AS NVARCHAR(MAX)) AS Observaciones ' +
      'FROM dbo.Proyectos ' +
      'WHERE CodigoEmpresa = :CE ';
    if Filtro <> '' then
      SQL := SQL + 'AND (CodigoProyecto LIKE :Filtro OR Proyecto LIKE :Filtro2) ';
    SQL := SQL + 'ORDER BY CodigoProyecto';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    if Filtro <> '' then
    begin
      Q.Parameters.ParamByName('Filtro').Value := '%' + Filtro + '%';
      Q.Parameters.ParamByName('Filtro2').Value := '%' + Filtro + '%';
    end;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      P := Default(TProyectoErp);
      P.Codigo               := Q.FieldByName('CodigoProyecto').AsString;
      P.Nombre               := Q.FieldByName('Proyecto').AsString;
      P.Tipo                 := Q.FieldByName('CodigoTipoProyectoLc').AsString;
      P.Estado               := Q.FieldByName('StatusProyectoLc').AsInteger;
      P.PorcentajeCompletado := Q.FieldByName('PorcentajeCompletadoLc').AsInteger;
      if not Q.FieldByName('FechaInicialProyectoLc').IsNull then
        P.FechaInicio := Q.FieldByName('FechaInicialProyectoLc').AsDateTime;
      if not Q.FieldByName('FechaFinalProyectoLc').IsNull then
        P.FechaFinal := Q.FieldByName('FechaFinalProyectoLc').AsDateTime;
      if not Q.FieldByName('FechaTopeProyectoLc').IsNull then
        P.FechaTope := Q.FieldByName('FechaTopeProyectoLc').AsDateTime;
      if not Q.FieldByName('FechaAprobacionLc').IsNull then
        P.FechaAprobacion := Q.FieldByName('FechaAprobacionLc').AsDateTime;
      if not Q.FieldByName('FechaCierre').IsNull then
        P.FechaCierre := Q.FieldByName('FechaCierre').AsDateTime;
      P.CodigoResponsable    := Q.FieldByName('CodigoResponsableLc').AsString;
      P.CodigoDepartamento   := Q.FieldByName('CodigoDepartamento').AsString;
      P.Observaciones        := Q.FieldByName('Observaciones').AsString;
      Result[Idx] := P;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadTareasProyecto(
  const ACodigoProyecto: string): TArray<TTareaProyectoErp>;
var
  Q: TADOQuery;
  T: TTareaProyectoErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;
  if Trim(ACodigoProyecto) = '' then
    raise Exception.Create('CodigoProyecto es obligatorio para leer tareas.');
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT CodigoProyecto, ' +
      '  CONVERT(NVARCHAR(36), IdTareaLc) AS IdTarea, ' +
      '  CONVERT(NVARCHAR(36), IdTareaPadreLc) AS IdTareaPadre, ' +
      '  Orden, NombreTareaLc, HitoLc, TareaCriticaLc, ' +
      '  FechaInicialLc, FechaRealInicioLc, ' +
      '  FechaFinalLc, FechaFinalEstimadaLc, FechaRealFinalizacionLc, FechaTopeLc, ' +
      '  PrioridadLc, PorcentajeCompletadoLc, ' +
      '  DuracionPrevistaLc, DuracionEstimadaLc, ' +
      '  CodigoTipoUnidadLc, NumeroRevisionLc ' +
      'FROM dbo.LcProyectoTareas ' +
      'WHERE CodigoEmpresa = :CE AND CodigoProyecto = :CP ' +
      'ORDER BY NumeroRevisionLc DESC, Orden';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('CP').Value := Trim(ACodigoProyecto);
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      T := Default(TTareaProyectoErp);
      T.CodigoProyecto       := Q.FieldByName('CodigoProyecto').AsString;
      T.IdTarea              := Q.FieldByName('IdTarea').AsString;
      T.IdTareaPadre         := Q.FieldByName('IdTareaPadre').AsString;
      T.Orden                := Q.FieldByName('Orden').AsInteger;
      T.Nombre               := Q.FieldByName('NombreTareaLc').AsString;
      T.EsHito               := Q.FieldByName('HitoLc').AsInteger <> 0;
      T.EsCritica            := Q.FieldByName('TareaCriticaLc').AsInteger <> 0;
      if not Q.FieldByName('FechaInicialLc').IsNull then
        T.FechaInicial := Q.FieldByName('FechaInicialLc').AsDateTime;
      if not Q.FieldByName('FechaRealInicioLc').IsNull then
        T.FechaRealInicio := Q.FieldByName('FechaRealInicioLc').AsDateTime;
      if not Q.FieldByName('FechaFinalLc').IsNull then
        T.FechaFinal := Q.FieldByName('FechaFinalLc').AsDateTime;
      if not Q.FieldByName('FechaFinalEstimadaLc').IsNull then
        T.FechaFinalEstimada := Q.FieldByName('FechaFinalEstimadaLc').AsDateTime;
      if not Q.FieldByName('FechaRealFinalizacionLc').IsNull then
        T.FechaRealFinalizacion := Q.FieldByName('FechaRealFinalizacionLc').AsDateTime;
      if not Q.FieldByName('FechaTopeLc').IsNull then
        T.FechaTope := Q.FieldByName('FechaTopeLc').AsDateTime;
      T.Prioridad            := Q.FieldByName('PrioridadLc').AsInteger;
      T.PorcentajeCompletado := Q.FieldByName('PorcentajeCompletadoLc').AsInteger;
      T.DuracionPrevista     := Q.FieldByName('DuracionPrevistaLc').AsFloat;
      T.DuracionEstimada     := Q.FieldByName('DuracionEstimadaLc').AsFloat;
      T.TipoUnidad           := Q.FieldByName('CodigoTipoUnidadLc').AsString;
      T.NumeroRevision       := Q.FieldByName('NumeroRevisionLc').AsInteger;
      Result[Idx] := T;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// HORARIOS / CALENDARIO
// ---------------------------------------------------------------------------

function TSage200Reader.ReadGruposHorarios: TArray<TGrupoHorarioErp>;
var
  Q: TADOQuery;
  G: TGrupoHorarioErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT GrupoHorario, DescripcionGrupo ' +
      'FROM dbo.GruposHorarios ' +
      'WHERE CodigoEmpresa = :CE ' +
      'ORDER BY GrupoHorario';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      G := Default(TGrupoHorarioErp);
      G.Codigo      := Q.FieldByName('GrupoHorario').AsString;
      G.Descripcion := Q.FieldByName('DescripcionGrupo').AsString;
      Result[Idx] := G;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadModelosHorarios: TArray<TModeloHorarioErp>;
var
  Q: TADOQuery;
  M: TModeloHorarioErp;
  Idx: Integer;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT ModeloHorario, DescripcionModHorario ' +
      'FROM dbo.ModelosHorarios ' +
      'WHERE CodigoEmpresa = :CE ' +
      'ORDER BY ModeloHorario';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      M := Default(TModeloHorarioErp);
      M.Codigo      := Q.FieldByName('ModeloHorario').AsInteger;
      M.Descripcion := Q.FieldByName('DescripcionModHorario').AsString;
      Result[Idx] := M;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadLineasModeloHorario(
  AModeloHorario: Integer): TArray<TLineaModeloHorarioErp>;
var
  Q: TADOQuery;
  L: TLineaModeloHorarioErp;
  Idx: Integer;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT ModeloHorario, Orden, Turno, TipoTurno, ' +
      '  HoraInicio, HoraFinal, ' +
      '  HoraInicioPermitida, HoraFinPermitida, ' +
      '  HoraInicioExtra, HoraFinExtra ' +
      'FROM dbo.LineasModelosHorarios ' +
      'WHERE CodigoEmpresa = :CE ';
    if AModeloHorario > 0 then
      SQL := SQL + 'AND ModeloHorario = :MH ';
    SQL := SQL + 'ORDER BY ModeloHorario, Orden';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    if AModeloHorario > 0 then
      Q.Parameters.ParamByName('MH').Value := AModeloHorario;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      L := Default(TLineaModeloHorarioErp);
      L.ModeloHorario       := Q.FieldByName('ModeloHorario').AsInteger;
      L.Orden               := Q.FieldByName('Orden').AsInteger;
      L.Turno               := Q.FieldByName('Turno').AsInteger;
      L.TipoTurno           := Q.FieldByName('TipoTurno').AsString;
      L.HoraInicio          := Q.FieldByName('HoraInicio').AsFloat;
      L.HoraFinal           := Q.FieldByName('HoraFinal').AsFloat;
      L.HoraInicioPermitida := Q.FieldByName('HoraInicioPermitida').AsFloat;
      L.HoraFinPermitida    := Q.FieldByName('HoraFinPermitida').AsFloat;
      L.HoraInicioExtra     := Q.FieldByName('HoraInicioExtra').AsFloat;
      L.HoraFinExtra        := Q.FieldByName('HoraFinExtra').AsFloat;
      Result[Idx] := L;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadCalendarioCentro(const ACentroTrabajo: string;
  AFechaDesde, AFechaHasta: TDateTime): TArray<TCalendarioCentroErp>;
var
  Q: TADOQuery;
  C: TCalendarioCentroErp;
  Idx: Integer;
  Centro: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;

  Centro := Trim(ACentroTrabajo);

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT CentroTrabajo, Fecha, ModeloHorario, Duracion, DuracionDescanso ' +
      'FROM dbo.CalendarioCentroTrabajo ' +
      'WHERE CodigoEmpresa = :CE ' +
      '  AND Fecha BETWEEN :FD AND :FH ';
    if Centro <> '' then
      SQL := SQL + 'AND CentroTrabajo = :CT ';
    SQL := SQL + 'ORDER BY CentroTrabajo, Fecha';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('FD').Value := AFechaDesde;
    Q.Parameters.ParamByName('FH').Value := AFechaHasta;
    if Centro <> '' then
      Q.Parameters.ParamByName('CT').Value := Centro;
    Q.Open;

    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      C := Default(TCalendarioCentroErp);
      C.CentroTrabajo    := Q.FieldByName('CentroTrabajo').AsString;
      C.Fecha            := Q.FieldByName('Fecha').AsDateTime;
      C.ModeloHorario    := Q.FieldByName('ModeloHorario').AsInteger;
      C.Duracion         := Q.FieldByName('Duracion').AsFloat;
      C.DuracionDescanso := Q.FieldByName('DuracionDescanso').AsFloat;
      Result[Idx] := C;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// STOCK
// ---------------------------------------------------------------------------

function TSage200Reader.ReadStockArticulo(const ACodigoArticulo,
  ACodigoAlmacen, APartida: string; AEjercicio: SmallInt;
  APeriodo: SmallInt): TArray<TStockArticuloErp>;
var
  Q: TADOQuery;
  S: TStockArticuloErp;
  Idx: Integer;
  Articulo, Almacen, Partida: string;
  Ejercicio: SmallInt;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Articulo := Trim(ACodigoArticulo);
  Almacen  := Trim(ACodigoAlmacen);
  Partida  := Trim(APartida);
  Ejercicio := AEjercicio;

  // Si no s'indica Ejercicio, agafa l'ultim disponible per a l'empresa (sense
  // subquery: una query previa per evitar duplicar :CE i no chocar amb ADO).
  if Ejercicio <= 0 then
  begin
    Q := TADOQuery.Create(nil);
    try
      Q.Connection := FConn;
      Q.SQL.Text :=
        'SELECT MAX(Ejercicio) AS MaxEj FROM dbo.AcumuladoStock ' +
        'WHERE CodigoEmpresa = :CE';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Open;
      if (not Q.Eof) and (not Q.FieldByName('MaxEj').IsNull) then
        Ejercicio := Q.FieldByName('MaxEj').AsInteger;
    finally
      Q.Free;
    end;
    if Ejercicio <= 0 then Exit;
  end;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT Ejercicio, Periodo, CodigoArticulo, CodigoAlmacen, Partida, ' +
      '  CodigoColor_, CodigoTalla01_, ' +
      '  UnidadEntrada, UnidadSalida, UnidadSaldo, ' +
      '  UnidadCompra, UnidadConsumo, ' +
      '  ImporteSaldo, PrecioMedio, PrecioUltimaEntrada, PrecioUltimaSalida, ' +
      '  FechaUltimaEntrada, FechaUltimaSalida, FechaCaducidad, Ubicacion ' +
      'FROM dbo.AcumuladoStock ' +
      'WHERE CodigoEmpresa = :CE AND Ejercicio = :Ej ';
    if APeriodo > 0 then
      SQL := SQL + 'AND Periodo = :Pe ';
    if Articulo <> '' then
      SQL := SQL + 'AND CodigoArticulo LIKE :Art ';
    if Almacen <> '' then
      SQL := SQL + 'AND CodigoAlmacen = :Alm ';
    if Partida <> '' then
      SQL := SQL + 'AND Partida LIKE :Par ';
    SQL := SQL + 'ORDER BY CodigoArticulo, CodigoAlmacen, Partida, Periodo';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Ej').Value := Ejercicio;
    if APeriodo > 0 then
      Q.Parameters.ParamByName('Pe').Value := APeriodo;
    if Articulo <> '' then
      Q.Parameters.ParamByName('Art').Value := '%' + Articulo + '%';
    if Almacen <> '' then
      Q.Parameters.ParamByName('Alm').Value := Almacen;
    if Partida <> '' then
      Q.Parameters.ParamByName('Par').Value := '%' + Partida + '%';
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      S := Default(TStockArticuloErp);
      S.Ejercicio           := Q.FieldByName('Ejercicio').AsInteger;
      S.Periodo             := Q.FieldByName('Periodo').AsInteger;
      S.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
      S.CodigoAlmacen       := Q.FieldByName('CodigoAlmacen').AsString;
      S.Partida             := Q.FieldByName('Partida').AsString;
      S.CodigoColor         := Q.FieldByName('CodigoColor_').AsString;
      S.CodigoTalla         := Q.FieldByName('CodigoTalla01_').AsString;
      S.UnidadEntrada       := Q.FieldByName('UnidadEntrada').AsFloat;
      S.UnidadSalida        := Q.FieldByName('UnidadSalida').AsFloat;
      S.UnidadSaldo         := Q.FieldByName('UnidadSaldo').AsFloat;
      S.UnidadCompra        := Q.FieldByName('UnidadCompra').AsFloat;
      S.UnidadConsumo       := Q.FieldByName('UnidadConsumo').AsFloat;
      S.ImporteSaldo        := Q.FieldByName('ImporteSaldo').AsFloat;
      S.PrecioMedio         := Q.FieldByName('PrecioMedio').AsFloat;
      S.PrecioUltimaEntrada := Q.FieldByName('PrecioUltimaEntrada').AsFloat;
      S.PrecioUltimaSalida  := Q.FieldByName('PrecioUltimaSalida').AsFloat;
      if not Q.FieldByName('FechaUltimaEntrada').IsNull then
        S.FechaUltimaEntrada := Q.FieldByName('FechaUltimaEntrada').AsDateTime;
      if not Q.FieldByName('FechaUltimaSalida').IsNull then
        S.FechaUltimaSalida := Q.FieldByName('FechaUltimaSalida').AsDateTime;
      if not Q.FieldByName('FechaCaducidad').IsNull then
        S.FechaCaducidad := Q.FieldByName('FechaCaducidad').AsDateTime;
      S.Ubicacion := Q.FieldByName('Ubicacion').AsString;
      Result[Idx] := S;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadStockDisponible(const ACodigoArticulo,
  ACodigoAlmacen: string): TArray<TStockDisponibleErp>;
var
  Q: TADOQuery;
  S: TStockDisponibleErp;
  Idx: Integer;
  Articulo, Almacen: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Articulo := Trim(ACodigoArticulo);
  Almacen  := Trim(ACodigoAlmacen);
  // Reconstrueix camps Neco amb subqueries (Neco pot ser buida).
  // PendienteFabricar i Planificado no es poden reconstruir directament; els
  // deixem a 0 (Planificado nomes existeix amb modul MRP).
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'WITH UltEj AS ( ' +
      '  SELECT MAX(Ejercicio) AS Ej FROM dbo.AcumuladoStock ' +
      '  WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' AND Periodo = 99 ' +
      '), Saldo AS ( ' +
      '  SELECT S.CodigoArticulo, S.CodigoAlmacen, S.CodigoColor_, S.CodigoTalla01_, ' +
      '    SUM(S.UnidadSaldo) AS UnidadSaldo ' +
      '  FROM dbo.AcumuladoStock S, UltEj ' +
      '  WHERE S.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '    AND S.Periodo = 99 AND S.Ejercicio = UltEj.Ej ';
    if Articulo <> '' then
      SQL := SQL + '  AND S.CodigoArticulo LIKE ' + QuotedStr('%' + Articulo + '%') + ' ';
    if Almacen <> '' then
      SQL := SQL + '  AND S.CodigoAlmacen = ' + QuotedStr(Almacen) + ' ';
    SQL := SQL +
      '  GROUP BY S.CodigoArticulo, S.CodigoAlmacen, S.CodigoColor_, S.CodigoTalla01_ ' +
      '), PendCompra AS ( ' +
      '  SELECT L.CodigoArticulo, L.CodigoAlmacen, ' +
      '    SUM(L.UnidadesPendientes) AS Unidades ' +
      '  FROM dbo.LineasPedidoProveedor L ' +
      '  WHERE L.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' AND L.UnidadesPendientes > 0 ';
    if Articulo <> '' then
      SQL := SQL + '  AND L.CodigoArticulo LIKE ' + QuotedStr('%' + Articulo + '%') + ' ';
    if Almacen <> '' then
      SQL := SQL + '  AND L.CodigoAlmacen = ' + QuotedStr(Almacen) + ' ';
    SQL := SQL +
      '  GROUP BY L.CodigoArticulo, L.CodigoAlmacen ' +
      '), PendVenta AS ( ' +
      '  SELECT L.CodigoArticulo, L.CodigoAlmacen, ' +
      '    SUM(L.UnidadesPendientes) AS Unidades ' +
      '  FROM dbo.LineasPedidoCliente L ' +
      '  WHERE L.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' AND L.UnidadesPendientes > 0 ';
    if Articulo <> '' then
      SQL := SQL + '  AND L.CodigoArticulo LIKE ' + QuotedStr('%' + Articulo + '%') + ' ';
    if Almacen <> '' then
      SQL := SQL + '  AND L.CodigoAlmacen = ' + QuotedStr(Almacen) + ' ';
    SQL := SQL +
      '  GROUP BY L.CodigoArticulo, L.CodigoAlmacen ' +
      ') ' +
      'SELECT S.CodigoArticulo, S.CodigoAlmacen, S.CodigoColor_, S.CodigoTalla01_, ' +
      '  S.UnidadSaldo, ' +
      '  COALESCE(PC.Unidades, 0) AS PendienteRecibir, ' +
      '  COALESCE(PV.Unidades, 0) AS PendienteServir, ' +
      '  0 AS PendienteFabricar, ' +
      '  COALESCE(PV.Unidades, 0) AS StockReservado, ' +
      '  0 AS Planificado ' +
      'FROM Saldo S ' +
      'LEFT JOIN PendCompra PC ON PC.CodigoArticulo = S.CodigoArticulo AND PC.CodigoAlmacen = S.CodigoAlmacen ' +
      'LEFT JOIN PendVenta  PV ON PV.CodigoArticulo = S.CodigoArticulo AND PV.CodigoAlmacen = S.CodigoAlmacen ' +
      'ORDER BY S.CodigoArticulo, S.CodigoAlmacen';
    Q.SQL.Text := SQL;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      S := Default(TStockDisponibleErp);
      S.CodigoArticulo    := Q.FieldByName('CodigoArticulo').AsString;
      S.CodigoAlmacen     := Q.FieldByName('CodigoAlmacen').AsString;
      S.CodigoColor       := Q.FieldByName('CodigoColor_').AsString;
      S.CodigoTalla       := Q.FieldByName('CodigoTalla01_').AsString;
      S.UnidadSaldo       := Q.FieldByName('UnidadSaldo').AsFloat;
      S.PendienteRecibir  := Q.FieldByName('PendienteRecibir').AsFloat;
      S.PendienteServir   := Q.FieldByName('PendienteServir').AsFloat;
      S.PendienteFabricar := Q.FieldByName('PendienteFabricar').AsFloat;
      S.StockReservado    := Q.FieldByName('StockReservado').AsFloat;
      S.Planificado       := Q.FieldByName('Planificado').AsFloat;
      S.Disponible        := S.UnidadSaldo - S.StockReservado;
      Result[Idx] := S;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// ENTRADAS FUTURAS (pedidos compra pendents)
// ---------------------------------------------------------------------------

function TSage200Reader.ReadEntradasFuturas(const ACodigoArticulo: string;
  AFechaDesde, AFechaHasta: TDateTime): TArray<TEntradaFuturaErp>;
var
  Q: TADOQuery;
  E: TEntradaFuturaErp;
  Idx: Integer;
  Articulo: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Articulo := Trim(ACodigoArticulo);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT L.EjercicioPedido, L.SeriePedido, L.NumeroPedido, L.Orden, ' +
      '  L.FechaPedido, L.CodigoArticulo, L.DescripcionArticulo, ' +
      '  L.CodigoAlmacen, L.Partida, ' +
      '  C.CodigoProveedor, C.RazonSocial AS RazonSocialProveedor, ' +
      '  L.UnidadesPedidas, L.UnidadesRecibidas, L.UnidadesPendientes, ' +
      '  L.Precio, L.ImporteNetoPendiente, ' +
      '  L.FechaNecesaria, L.FechaRecepcion, L.FechaTope, L.Estado ' +
      'FROM dbo.LineasPedidoProveedor L ' +
      'LEFT JOIN dbo.CabeceraPedidoProveedor C ' +
      '  ON  C.CodigoEmpresa  = L.CodigoEmpresa ' +
      '  AND C.EjercicioPedido = L.EjercicioPedido ' +
      '  AND C.SeriePedido     = L.SeriePedido ' +
      '  AND C.NumeroPedido    = L.NumeroPedido ' +
      'WHERE L.CodigoEmpresa = :CE ' +
      '  AND L.UnidadesPendientes > 0 ';
    if Articulo <> '' then
      SQL := SQL + 'AND L.CodigoArticulo LIKE :Art ';
    if AFechaDesde > 0 then
      SQL := SQL + 'AND L.FechaNecesaria >= :FD ';
    if AFechaHasta > 0 then
      SQL := SQL + 'AND L.FechaNecesaria <= :FH ';
    SQL := SQL + 'ORDER BY L.FechaNecesaria, L.CodigoArticulo';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    if Articulo <> '' then
      Q.Parameters.ParamByName('Art').Value := '%' + Articulo + '%';
    if AFechaDesde > 0 then
      Q.Parameters.ParamByName('FD').Value := AFechaDesde;
    if AFechaHasta > 0 then
      Q.Parameters.ParamByName('FH').Value := AFechaHasta;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      E := Default(TEntradaFuturaErp);
      E.EjercicioPedido      := Q.FieldByName('EjercicioPedido').AsInteger;
      E.SeriePedido          := Q.FieldByName('SeriePedido').AsString;
      E.NumeroPedido         := Q.FieldByName('NumeroPedido').AsInteger;
      E.Orden                := Q.FieldByName('Orden').AsInteger;
      if not Q.FieldByName('FechaPedido').IsNull then
        E.FechaPedido := Q.FieldByName('FechaPedido').AsDateTime;
      E.CodigoArticulo       := Q.FieldByName('CodigoArticulo').AsString;
      E.DescripcionArticulo  := Q.FieldByName('DescripcionArticulo').AsString;
      E.CodigoAlmacen        := Q.FieldByName('CodigoAlmacen').AsString;
      E.Partida              := Q.FieldByName('Partida').AsString;
      E.CodigoProveedor      := Q.FieldByName('CodigoProveedor').AsString;
      E.RazonSocialProveedor := Q.FieldByName('RazonSocialProveedor').AsString;
      E.UnidadesPedidas      := Q.FieldByName('UnidadesPedidas').AsFloat;
      E.UnidadesRecibidas    := Q.FieldByName('UnidadesRecibidas').AsFloat;
      E.UnidadesPendientes   := Q.FieldByName('UnidadesPendientes').AsFloat;
      E.Precio               := Q.FieldByName('Precio').AsFloat;
      E.ImporteNetoPendiente := Q.FieldByName('ImporteNetoPendiente').AsFloat;
      if not Q.FieldByName('FechaNecesaria').IsNull then
        E.FechaNecesaria := Q.FieldByName('FechaNecesaria').AsDateTime;
      if not Q.FieldByName('FechaRecepcion').IsNull then
        E.FechaRecepcion := Q.FieldByName('FechaRecepcion').AsDateTime;
      if not Q.FieldByName('FechaTope').IsNull then
        E.FechaTope := Q.FieldByName('FechaTope').AsDateTime;
      E.Estado := Q.FieldByName('Estado').AsInteger;
      Result[Idx] := E;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Helpers locals per a llistes d'almacenes (clausula IN literal per evitar
// limits de parametres dinamics en ADO).
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// ENTRADAS FUTURAS (variant amb llista d'almacenes)
// ---------------------------------------------------------------------------

function TSage200Reader.ReadEntradasFuturasFiltered(const ACodigoArticulo: string;
  const AAlmacenes: TArray<string>;
  AFechaDesde, AFechaHasta: TDateTime): TArray<TEntradaFuturaErp>;
var
  Q: TADOQuery;
  E: TEntradaFuturaErp;
  Idx: Integer;
  Articulo: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Articulo := Trim(ACodigoArticulo);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT L.EjercicioPedido, L.SeriePedido, L.NumeroPedido, L.Orden, ' +
      '  L.FechaPedido, L.CodigoArticulo, L.DescripcionArticulo, ' +
      '  L.CodigoAlmacen, L.Partida, ' +
      '  C.CodigoProveedor, C.RazonSocial AS RazonSocialProveedor, ' +
      '  L.UnidadesPedidas, L.UnidadesRecibidas, L.UnidadesPendientes, ' +
      '  L.Precio, L.ImporteNetoPendiente, ' +
      '  L.FechaNecesaria, L.FechaRecepcion, L.FechaTope, L.Estado ' +
      'FROM dbo.LineasPedidoProveedor L ' +
      'LEFT JOIN dbo.CabeceraPedidoProveedor C ' +
      '  ON  C.CodigoEmpresa  = L.CodigoEmpresa ' +
      '  AND C.EjercicioPedido = L.EjercicioPedido ' +
      '  AND C.SeriePedido     = L.SeriePedido ' +
      '  AND C.NumeroPedido    = L.NumeroPedido ' +
      'WHERE L.CodigoEmpresa = :CE ' +
      '  AND L.UnidadesPendientes > 0 ';
    if Articulo <> '' then
      SQL := SQL + 'AND L.CodigoArticulo = :Art ';
    if AFechaDesde > 0 then
      SQL := SQL + 'AND L.FechaNecesaria >= :FD ';
    if AFechaHasta > 0 then
      SQL := SQL + 'AND L.FechaNecesaria <= :FH ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'L.CodigoAlmacen');
    SQL := SQL + 'ORDER BY L.FechaNecesaria, L.CodigoArticulo';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    if Articulo <> '' then
      Q.Parameters.ParamByName('Art').Value := Articulo;
    if AFechaDesde > 0 then
      Q.Parameters.ParamByName('FD').Value := AFechaDesde;
    if AFechaHasta > 0 then
      Q.Parameters.ParamByName('FH').Value := AFechaHasta;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      E := Default(TEntradaFuturaErp);
      E.EjercicioPedido      := Q.FieldByName('EjercicioPedido').AsInteger;
      E.SeriePedido          := Q.FieldByName('SeriePedido').AsString;
      E.NumeroPedido         := Q.FieldByName('NumeroPedido').AsInteger;
      E.Orden                := Q.FieldByName('Orden').AsInteger;
      if not Q.FieldByName('FechaPedido').IsNull then
        E.FechaPedido := Q.FieldByName('FechaPedido').AsDateTime;
      E.CodigoArticulo       := Q.FieldByName('CodigoArticulo').AsString;
      E.DescripcionArticulo  := Q.FieldByName('DescripcionArticulo').AsString;
      E.CodigoAlmacen        := Q.FieldByName('CodigoAlmacen').AsString;
      E.Partida              := Q.FieldByName('Partida').AsString;
      E.CodigoProveedor      := Q.FieldByName('CodigoProveedor').AsString;
      E.RazonSocialProveedor := Q.FieldByName('RazonSocialProveedor').AsString;
      E.UnidadesPedidas      := Q.FieldByName('UnidadesPedidas').AsFloat;
      E.UnidadesRecibidas    := Q.FieldByName('UnidadesRecibidas').AsFloat;
      E.UnidadesPendientes   := Q.FieldByName('UnidadesPendientes').AsFloat;
      E.Precio               := Q.FieldByName('Precio').AsFloat;
      E.ImporteNetoPendiente := Q.FieldByName('ImporteNetoPendiente').AsFloat;
      if not Q.FieldByName('FechaNecesaria').IsNull then
        E.FechaNecesaria := Q.FieldByName('FechaNecesaria').AsDateTime;
      if not Q.FieldByName('FechaRecepcion').IsNull then
        E.FechaRecepcion := Q.FieldByName('FechaRecepcion').AsDateTime;
      if not Q.FieldByName('FechaTope').IsNull then
        E.FechaTope := Q.FieldByName('FechaTope').AsDateTime;
      E.Estado := Q.FieldByName('Estado').AsInteger;
      Result[Idx] := E;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// SALIDAS FUTURAS (pedidos venta pendents)
// ---------------------------------------------------------------------------

function TSage200Reader.ReadSalidasFuturasVenta(const ACodigoArticulo: string;
  const AAlmacenes: TArray<string>;
  AFechaDesde, AFechaHasta: TDateTime): TArray<TSalidaFuturaVentaErp>;
var
  Q: TADOQuery;
  S: TSalidaFuturaVentaErp;
  Idx: Integer;
  Articulo: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Articulo := Trim(ACodigoArticulo);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT L.EjercicioPedido, L.SeriePedido, L.NumeroPedido, L.Orden, ' +
      '  L.FechaPedido, L.CodigoArticulo, L.DescripcionArticulo, ' +
      '  L.CodigoAlmacen, ' +
      '  C.CodigoCliente, C.RazonSocial AS RazonSocialCliente, ' +
      '  L.UnidadesPedidas, L.UnidadesServidas, L.UnidadesPendientes, ' +
      '  L.Precio, ' +
      '  L.FechaEntrega, L.FechaNecesaria, L.FechaTope, L.Estado ' +
      'FROM dbo.LineasPedidoCliente L ' +
      'LEFT JOIN dbo.CabeceraPedidoCliente C ' +
      '  ON  C.CodigoEmpresa  = L.CodigoEmpresa ' +
      '  AND C.EjercicioPedido = L.EjercicioPedido ' +
      '  AND C.SeriePedido     = L.SeriePedido ' +
      '  AND C.NumeroPedido    = L.NumeroPedido ' +
      'WHERE L.CodigoEmpresa = :CE ' +
      '  AND L.UnidadesPendientes > 0 ';
    if Articulo <> '' then
      SQL := SQL + 'AND L.CodigoArticulo = :Art ';
    if AFechaDesde > 0 then
      SQL := SQL + 'AND COALESCE(L.FechaEntrega, L.FechaNecesaria) >= :FD ';
    if AFechaHasta > 0 then
      SQL := SQL + 'AND COALESCE(L.FechaEntrega, L.FechaNecesaria) <= :FH ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'L.CodigoAlmacen');
    SQL := SQL + 'ORDER BY COALESCE(L.FechaEntrega, L.FechaNecesaria), L.CodigoArticulo';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    if Articulo <> '' then
      Q.Parameters.ParamByName('Art').Value := Articulo;
    if AFechaDesde > 0 then
      Q.Parameters.ParamByName('FD').Value := AFechaDesde;
    if AFechaHasta > 0 then
      Q.Parameters.ParamByName('FH').Value := AFechaHasta;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      S := Default(TSalidaFuturaVentaErp);
      S.EjercicioPedido      := Q.FieldByName('EjercicioPedido').AsInteger;
      S.SeriePedido          := Q.FieldByName('SeriePedido').AsString;
      S.NumeroPedido         := Q.FieldByName('NumeroPedido').AsInteger;
      S.Orden                := Q.FieldByName('Orden').AsInteger;
      if not Q.FieldByName('FechaPedido').IsNull then
        S.FechaPedido := Q.FieldByName('FechaPedido').AsDateTime;
      S.CodigoArticulo       := Q.FieldByName('CodigoArticulo').AsString;
      S.DescripcionArticulo  := Q.FieldByName('DescripcionArticulo').AsString;
      S.CodigoAlmacen        := Q.FieldByName('CodigoAlmacen').AsString;
      S.CodigoCliente        := Q.FieldByName('CodigoCliente').AsString;
      S.RazonSocialCliente   := Q.FieldByName('RazonSocialCliente').AsString;
      S.UnidadesPedidas      := Q.FieldByName('UnidadesPedidas').AsFloat;
      S.UnidadesServidas     := Q.FieldByName('UnidadesServidas').AsFloat;
      S.UnidadesPendientes   := Q.FieldByName('UnidadesPendientes').AsFloat;
      S.Precio               := Q.FieldByName('Precio').AsFloat;
      if not Q.FieldByName('FechaEntrega').IsNull then
        S.FechaServicio := Q.FieldByName('FechaEntrega').AsDateTime;
      if not Q.FieldByName('FechaNecesaria').IsNull then
        S.FechaNecesaria := Q.FieldByName('FechaNecesaria').AsDateTime;
      if not Q.FieldByName('FechaTope').IsNull then
        S.FechaTope := Q.FieldByName('FechaTope').AsDateTime;
      S.Estado := Q.FieldByName('Estado').AsInteger;
      Result[Idx] := S;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// MOVIMENTS FUTURS PER OTs PENDENTS (produccio + consums)
// ---------------------------------------------------------------------------

function TSage200Reader.ReadMovimientosOFsPendientes(const ACodigoArticulo: string;
  const AAlmacenes: TArray<string>;
  AFechaHasta: TDateTime): TArray<TMovOFErp>;
var
  Q: TADOQuery;
  M: TMovOFErp;
  Idx, Cap: Integer;
  Articulo: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Articulo := Trim(ACodigoArticulo);
  if Articulo = '' then Exit;   // Sense article no te sentit aquesta consulta

  // 1) PRODUCCIO: OTs no acabades que fabriquen aquest article.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT 0 AS EjercicioFabricacion, '#39#39' AS SerieFabricacion, ' +
      '  OT.NumeroTrabajo AS NumeroFabricacion, ' +
      '  OT.CodigoArticulo, OT.DescripcionArticulo, OT.CodigoAlmacen, ' +
      '  (OT.UnidadesAFabricar - OT.UnidadesFabricadas) AS Unidades, ' +
      '  OT.FechaFinalPrevista AS Fecha, OT.EstadoOT, ' +
      '  OT.EjercicioFabricacion, OT.SerieFabricacion, OT.NumeroFabricacion ' +
      'FROM dbo.OrdenesTrabajo OT ' +
      'WHERE OT.CodigoEmpresa = :CE ' +
      '  AND OT.CodigoArticulo = :Art ' +
      '  AND (OT.UnidadesAFabricar - OT.UnidadesFabricadas) > 0 ' +
      '  AND OT.FechaFinalPrevista IS NOT NULL ';
    if AFechaHasta > 0 then
      SQL := SQL + 'AND OT.FechaFinalPrevista <= :FH ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'OT.CodigoAlmacen');
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value  := FCodigoEmpresa;
    Q.Parameters.ParamByName('Art').Value := Articulo;
    if AFechaHasta > 0 then
      Q.Parameters.ParamByName('FH').Value := AFechaHasta;
    Q.Open;
    Cap := Q.RecordCount;
    SetLength(Result, Cap);
    Idx := 0;
    while not Q.Eof do
    begin
      M := Default(TMovOFErp);
      M.EjercicioFabricacion := Q.FieldByName('EjercicioFabricacion').AsInteger;
      M.SerieFabricacion     := Q.FieldByName('SerieFabricacion').AsString;
      M.NumeroFabricacion    := Q.FieldByName('NumeroFabricacion').AsInteger;
      M.EsProduccion         := True;
      M.CodigoArticulo       := Q.FieldByName('CodigoArticulo').AsString;
      M.DescripcionArticulo  := Q.FieldByName('DescripcionArticulo').AsString;
      M.CodigoAlmacen        := Q.FieldByName('CodigoAlmacen').AsString;
      M.Unidades             := Q.FieldByName('Unidades').AsFloat;
      if not Q.FieldByName('Fecha').IsNull then
        M.Fecha := Q.FieldByName('Fecha').AsDateTime;
      M.EstadoOF             := Q.FieldByName('EstadoOT').AsInteger;
      Result[Idx] := M;
      Inc(Idx);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  // 2) CONSUMS: ConsumosOT amb ArticuloComponente = @Art i OT no acabada.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT OT.EjercicioFabricacion, OT.SerieFabricacion, OT.NumeroFabricacion, ' +
      '  C.ArticuloComponente AS CodigoArticulo, C.DescripcionArticulo, ' +
      '  C.CodigoAlmacen, ' +
      '  (C.UnidadesNecesarias - C.UnidadesUsadas) AS Unidades, ' +
      '  OT.FechaInicioPrevista AS Fecha, OT.EstadoOT ' +
      'FROM dbo.ConsumosOT C ' +
      'INNER JOIN dbo.OrdenesTrabajo OT ' +
      '  ON  OT.CodigoEmpresa    = C.CodigoEmpresa ' +
      '  AND OT.EjercicioTrabajo = C.EjercicioTrabajo ' +
      '  AND OT.NumeroTrabajo    = C.NumeroTrabajo ' +
      'WHERE C.CodigoEmpresa = :CE ' +
      '  AND C.ArticuloComponente = :Art ' +
      '  AND (C.UnidadesNecesarias - C.UnidadesUsadas) > 0 ' +
      '  AND (OT.UnidadesAFabricar - OT.UnidadesFabricadas) > 0 ' +
      '  AND OT.FechaInicioPrevista IS NOT NULL ';
    if AFechaHasta > 0 then
      SQL := SQL + 'AND OT.FechaInicioPrevista <= :FH ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'C.CodigoAlmacen');
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value  := FCodigoEmpresa;
    Q.Parameters.ParamByName('Art').Value := Articulo;
    if AFechaHasta > 0 then
      Q.Parameters.ParamByName('FH').Value := AFechaHasta;
    Q.Open;
    // Estendre l'array per als consums.
    Cap := Length(Result);
    SetLength(Result, Cap + Q.RecordCount);
    Idx := Cap;
    while not Q.Eof do
    begin
      M := Default(TMovOFErp);
      M.EjercicioFabricacion := Q.FieldByName('EjercicioFabricacion').AsInteger;
      M.SerieFabricacion     := Q.FieldByName('SerieFabricacion').AsString;
      M.NumeroFabricacion    := Q.FieldByName('NumeroFabricacion').AsInteger;
      M.EsProduccion         := False;
      M.CodigoArticulo       := Q.FieldByName('CodigoArticulo').AsString;
      M.DescripcionArticulo  := Q.FieldByName('DescripcionArticulo').AsString;
      M.CodigoAlmacen        := Q.FieldByName('CodigoAlmacen').AsString;
      M.Unidades             := Q.FieldByName('Unidades').AsFloat;
      if not Q.FieldByName('Fecha').IsNull then
        M.Fecha := Q.FieldByName('Fecha').AsDateTime;
      M.EstadoOF             := Q.FieldByName('EstadoOT').AsInteger;
      Result[Idx] := M;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// STOCK CRITIC (Cockpit)
// ---------------------------------------------------------------------------

function TSage200Reader.ReadStockCritico(const AAlmacenes: TArray<string>;
  const AFiltroFamilia: string): TArray<TStockCriticoErp>;
var
  Q: TADOQuery;
  S: TStockCriticoErp;
  Idx: Integer;
  Familia: string;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Familia := Trim(AFiltroFamilia);
  // Reconstrueix camps Neco a partir de:
  //   Saldo = AcumuladoStock Periodo=99 ultim Ejercicio
  //   StockReservado / PendienteServir = LineasPedidoCliente.UnidadesPendientes
  //   PendienteRecibir = LineasPedidoProveedor.UnidadesPendientes
  // Tot interpolat per evitar duplicats de :CE.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'WITH UltEj AS ( ' +
      '  SELECT MAX(Ejercicio) AS Ej FROM dbo.AcumuladoStock ' +
      '  WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' AND Periodo = 99 ' +
      '), Saldo AS ( ' +
      '  SELECT S.CodigoArticulo, S.CodigoAlmacen, ' +
      '    SUM(S.UnidadSaldo) AS UnidadSaldo ' +
      '  FROM dbo.AcumuladoStock S, UltEj ' +
      '  WHERE S.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '    AND S.Periodo = 99 AND S.Ejercicio = UltEj.Ej ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'S.CodigoAlmacen');
    SQL := SQL +
      '  GROUP BY S.CodigoArticulo, S.CodigoAlmacen ' +
      '), PendCompra AS ( ' +
      '  SELECT L.CodigoArticulo, L.CodigoAlmacen, ' +
      '    SUM(L.UnidadesPendientes) AS Unidades ' +
      '  FROM dbo.LineasPedidoProveedor L ' +
      '  WHERE L.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '    AND L.UnidadesPendientes > 0 ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'L.CodigoAlmacen');
    SQL := SQL +
      '  GROUP BY L.CodigoArticulo, L.CodigoAlmacen ' +
      '), PendVenta AS ( ' +
      '  SELECT L.CodigoArticulo, L.CodigoAlmacen, ' +
      '    SUM(L.UnidadesPendientes) AS Unidades ' +
      '  FROM dbo.LineasPedidoCliente L ' +
      '  WHERE L.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '    AND L.UnidadesPendientes > 0 ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'L.CodigoAlmacen');
    SQL := SQL +
      '  GROUP BY L.CodigoArticulo, L.CodigoAlmacen ' +
      ') ' +
      'SELECT A.CodigoArticulo, A.DescripcionArticulo, ' +
      '  COALESCE(S.CodigoAlmacen, PC.CodigoAlmacen, PV.CodigoAlmacen) AS CodigoAlmacen, ' +
      '  COALESCE(S.UnidadSaldo, 0)  AS UnidadSaldo, ' +
      '  COALESCE(PV.Unidades, 0)    AS StockReservado, ' +
      '  COALESCE(PC.Unidades, 0)    AS PendienteRecibir, ' +
      '  COALESCE(PV.Unidades, 0)    AS PendienteServir, ' +
      '  A.StockMinimo, A.StockMaximo, ' +
      '  A.CodigoFamilia, A.UnidadMedida2_ AS UnidadMedida ' +
      'FROM dbo.Articulos A ' +
      'LEFT JOIN Saldo     S  ON S.CodigoArticulo  = A.CodigoArticulo ' +
      'LEFT JOIN PendCompra PC ON PC.CodigoArticulo = A.CodigoArticulo ' +
      '                       AND (S.CodigoAlmacen IS NULL OR PC.CodigoAlmacen = S.CodigoAlmacen) ' +
      'LEFT JOIN PendVenta  PV ON PV.CodigoArticulo = A.CodigoArticulo ' +
      '                       AND (S.CodigoAlmacen IS NULL OR PV.CodigoAlmacen = S.CodigoAlmacen) ' +
      'WHERE A.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ';
    if Familia <> '' then
      SQL := SQL + 'AND A.CodigoFamilia = ' + QuotedStr(Familia) + ' ';
    SQL := SQL +
      // Cr'itic: Disponible<0 OR (Minimo>0 AND Disponible<Minimo)
      'AND ((COALESCE(S.UnidadSaldo,0) - COALESCE(PV.Unidades,0)) < 0 ' +
      '  OR (A.StockMinimo > 0 ' +
      '      AND (COALESCE(S.UnidadSaldo,0) - COALESCE(PV.Unidades,0)) < A.StockMinimo)) ' +
      'AND COALESCE(S.CodigoAlmacen, PC.CodigoAlmacen, PV.CodigoAlmacen) IS NOT NULL ' +
      'ORDER BY (A.StockMinimo - (COALESCE(S.UnidadSaldo,0) - COALESCE(PV.Unidades,0))) DESC, ' +
      '         A.CodigoArticulo';
    Q.SQL.Text := SQL;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      S := Default(TStockCriticoErp);
      S.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
      S.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      S.CodigoAlmacen       := Q.FieldByName('CodigoAlmacen').AsString;
      S.UnidadSaldo         := Q.FieldByName('UnidadSaldo').AsFloat;
      S.StockReservado      := Q.FieldByName('StockReservado').AsFloat;
      S.Disponible          := S.UnidadSaldo - S.StockReservado;
      S.PendienteRecibir    := Q.FieldByName('PendienteRecibir').AsFloat;
      S.PendienteServir     := Q.FieldByName('PendienteServir').AsFloat;
      S.StockMinimo         := Q.FieldByName('StockMinimo').AsFloat;
      S.StockMaximo         := Q.FieldByName('StockMaximo').AsFloat;
      S.Deficit             := S.StockMinimo - S.Disponible;
      S.CodigoFamilia       := Q.FieldByName('CodigoFamilia').AsString;
      S.UnidadMedida        := Q.FieldByName('UnidadMedida').AsString;
      Result[Idx] := S;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// STOCK OBSOLETO
// ---------------------------------------------------------------------------

function TSage200Reader.ReadStockObsoleto(const AAlmacenes: TArray<string>;
  const AFiltroFamilia: string;
  AMesesSinMovimiento: Integer): TArray<TStockObsoletoErp>;
var
  Q: TADOQuery;
  S: TStockObsoletoErp;
  Idx: Integer;
  Familia: string;
  FechaLimite, UltimoMov, Hoy: TDateTime;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Familia := Trim(AFiltroFamilia);
  if AMesesSinMovimiento <= 0 then AMesesSinMovimiento := 12;
  FechaLimite := IncMonth(Date, -AMesesSinMovimiento);
  Hoy := Date;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    // Agreguem AcumuladoStock per article+almacen. NOTA: a Sage el saldo viu
    // queda al registre amb Periodo=99 (saldo de cloenda/permanent); els
    // periodes 1..12 son moviments del mes. Per saldo total = filtre 99.
    SQL :=
      'SELECT S.CodigoArticulo, A.DescripcionArticulo, ' +
      '  S.CodigoAlmacen, A.CodigoFamilia, A.UnidadMedida2_ AS UnidadMedida, ' +
      '  SUM(S.UnidadSaldo) AS UnidadSaldo, ' +
      '  SUM(S.ImporteSaldo) AS ImporteSaldo, ' +
      '  MAX(S.PrecioMedio) AS PrecioMedio, ' +
      '  MAX(S.FechaUltimaEntrada) AS FechaUltimaEntrada, ' +
      '  MAX(S.FechaUltimaSalida) AS FechaUltimaSalida ' +
      'FROM dbo.AcumuladoStock S ' +
      'INNER JOIN dbo.Articulos A ' +
      '  ON  A.CodigoEmpresa = S.CodigoEmpresa ' +
      '  AND A.CodigoArticulo = S.CodigoArticulo ' +
      'WHERE S.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '  AND S.Periodo = 99 ' +
      '  AND S.Ejercicio = (SELECT MAX(Ejercicio) FROM dbo.AcumuladoStock ' +
      '                     WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      '                       AND Periodo = 99) ';
    if Familia <> '' then
      SQL := SQL + 'AND A.CodigoFamilia = :Fa ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'S.CodigoAlmacen');
    // Data literal en format ISO yyyymmdd (no ambigu, no depen de regional).
    SQL := SQL +
      'GROUP BY S.CodigoArticulo, A.DescripcionArticulo, S.CodigoAlmacen, ' +
      '  A.CodigoFamilia, A.UnidadMedida2_ ' +
      'HAVING SUM(S.UnidadSaldo) > 0 ' +
      '  AND (MAX(S.FechaUltimaEntrada) IS NULL OR MAX(S.FechaUltimaEntrada) < ' +
            QuotedStr(FormatDateTime('yyyymmdd', FechaLimite)) + ') ' +
      '  AND (MAX(S.FechaUltimaSalida)  IS NULL OR MAX(S.FechaUltimaSalida)  < ' +
            QuotedStr(FormatDateTime('yyyymmdd', FechaLimite)) + ') ' +
      'ORDER BY SUM(S.ImporteSaldo) DESC';
    Q.SQL.Text := SQL;
    if Familia <> '' then
      Q.Parameters.ParamByName('Fa').Value := Familia;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      S := Default(TStockObsoletoErp);
      S.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
      S.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      S.CodigoAlmacen       := Q.FieldByName('CodigoAlmacen').AsString;
      S.CodigoFamilia       := Q.FieldByName('CodigoFamilia').AsString;
      S.UnidadMedida        := Q.FieldByName('UnidadMedida').AsString;
      S.UnidadSaldo         := Q.FieldByName('UnidadSaldo').AsFloat;
      S.ImporteSaldo        := Q.FieldByName('ImporteSaldo').AsFloat;
      S.PrecioMedio         := Q.FieldByName('PrecioMedio').AsFloat;
      if not Q.FieldByName('FechaUltimaEntrada').IsNull then
        S.FechaUltimaEntrada := Q.FieldByName('FechaUltimaEntrada').AsDateTime;
      if not Q.FieldByName('FechaUltimaSalida').IsNull then
        S.FechaUltimaSalida := Q.FieldByName('FechaUltimaSalida').AsDateTime;
      UltimoMov := Max(S.FechaUltimaEntrada, S.FechaUltimaSalida);
      if UltimoMov > 0 then
        S.DiasSinMovimiento := DaysBetween(Hoy, UltimoMov)
      else
        S.DiasSinMovimiento := 9999;
      Result[Idx] := S;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// COBERTURA (Days of Supply)
// ---------------------------------------------------------------------------

function TSage200Reader.ReadCobertura(const AAlmacenes: TArray<string>;
  const AFiltroFamilia: string;
  ADiasHistorico: Integer): TArray<TCoberturaErp>;
var
  Q: TADOQuery;
  R: TCoberturaErp;
  Idx: Integer;
  Familia: string;
  FechaDesde: TDateTime;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Familia := Trim(AFiltroFamilia);
  if ADiasHistorico <= 0 then ADiasHistorico := 90;
  FechaDesde := IncDay(Date, -ADiasHistorico);
  // Usem AcumuladoStock (Periodo=99 saldo viu, Periodos 1..12 consums) en
  // lloc de Neco perqu'e no totes les instal.lacions Sage mantenen Neco. Tot
  // de l'ultim Ejercicio disponible. Per evitar duplicar :CE, interpolem.
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'WITH UltEj AS ( ' +
      '  SELECT MAX(Ejercicio) AS Ej FROM dbo.AcumuladoStock ' +
      '  WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' AND Periodo = 99 ' +
      '), Saldo AS ( ' +
      '  SELECT S.CodigoArticulo, S.CodigoAlmacen, ' +
      '    SUM(S.UnidadSaldo) AS UnidadSaldo ' +
      '  FROM dbo.AcumuladoStock S, UltEj ' +
      '  WHERE S.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '    AND S.Periodo = 99 AND S.Ejercicio = UltEj.Ej ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'S.CodigoAlmacen');
    SQL := SQL +
      '  GROUP BY S.CodigoArticulo, S.CodigoAlmacen ' +
      '), Consumo AS ( ' +
      '  SELECT M.CodigoArticulo, M.CodigoAlmacen, ' +
      '    SUM(M.UnidadSalida) AS UnidadesSalida ' +
      '  FROM dbo.AcumuladoStock M, UltEj ' +
      '  WHERE M.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '    AND M.Periodo BETWEEN 1 AND 12 AND M.Ejercicio = UltEj.Ej ';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'M.CodigoAlmacen');
    SQL := SQL +
      '  GROUP BY M.CodigoArticulo, M.CodigoAlmacen ' +
      ') ' +
      'SELECT S.CodigoArticulo, A.DescripcionArticulo, ' +
      '  S.CodigoAlmacen, A.CodigoFamilia, A.UnidadMedida2_ AS UnidadMedida, ' +
      '  S.UnidadSaldo, A.StockMinimo, ' +
      '  COALESCE(C.UnidadesSalida, 0) AS ConsumoPeriodo ' +
      'FROM Saldo S ' +
      'INNER JOIN dbo.Articulos A ON A.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
                                  ' AND A.CodigoArticulo = S.CodigoArticulo ' +
      'LEFT JOIN Consumo C ON C.CodigoArticulo = S.CodigoArticulo ' +
      '                   AND C.CodigoAlmacen = S.CodigoAlmacen ' +
      'WHERE S.UnidadSaldo <> 0 ';
    if Familia <> '' then
      SQL := SQL + 'AND A.CodigoFamilia = ' + QuotedStr(Familia) + ' ';
    SQL := SQL + 'ORDER BY S.CodigoArticulo';
    Q.SQL.Text := SQL;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      R := Default(TCoberturaErp);
      R.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
      R.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      R.CodigoAlmacen       := Q.FieldByName('CodigoAlmacen').AsString;
      R.CodigoFamilia       := Q.FieldByName('CodigoFamilia').AsString;
      R.UnidadMedida        := Q.FieldByName('UnidadMedida').AsString;
      R.UnidadSaldo         := Q.FieldByName('UnidadSaldo').AsFloat;
      R.StockMinimo         := Q.FieldByName('StockMinimo').AsFloat;
      R.ConsumoPeriodo      := Q.FieldByName('ConsumoPeriodo').AsFloat;
      // Consum acumulat de l'ultim Ejercicio (periodes 1..12). El diari el
      // calculem dividint per 365 com a aproximacio (no sabem quants dies
      // del Ejercicio tenen moviment real).
      R.DiasPeriodo := 365;
      R.ConsumoDiario := R.ConsumoPeriodo / 365;
      if R.ConsumoDiario > 0 then
        R.DiasCobertura := R.UnidadSaldo / R.ConsumoDiario
      else
        R.DiasCobertura := -1;  // sense consum -> N/A
      Result[Idx] := R;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// ANALISIS ABC
// ---------------------------------------------------------------------------

function TSage200Reader.ReadAnalisisABC(const AFiltroFamilia: string;
  ADiasHistorico: Integer): TArray<TAnalisisABCErp>;
var
  Q: TADOQuery;
  R: TAnalisisABCErp;
  Idx, i: Integer;
  Familia: string;
  FechaDesde: TDateTime;
  TotalImporte, AcumImporte: Double;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Familia := Trim(AFiltroFamilia);
  if ADiasHistorico <= 0 then ADiasHistorico := 365;
  FechaDesde := IncDay(Date, -ADiasHistorico);
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    // Consum valorat per article. Agreguem nomes periodes 1..12 (mesos) de
    // l'ultim Ejercicio disponible. Periodo=99 es saldo viu, no moviment.
    SQL :=
      'SELECT S.CodigoArticulo, A.DescripcionArticulo, ' +
      '  A.CodigoFamilia, A.UnidadMedida2_ AS UnidadMedida, ' +
      '  SUM(S.UnidadSalida)  AS UnidadesConsumidas, ' +
      '  SUM(S.CosteSalida)   AS ImporteConsumido ' +
      'FROM dbo.AcumuladoStock S ' +
      'INNER JOIN dbo.Articulos A ' +
      '  ON  A.CodigoEmpresa = S.CodigoEmpresa ' +
      '  AND A.CodigoArticulo = S.CodigoArticulo ' +
      'WHERE S.CodigoEmpresa = :CE ' +
      '  AND S.Periodo BETWEEN 1 AND 12 ' +
      '  AND S.Ejercicio = (SELECT MAX(Ejercicio) FROM dbo.AcumuladoStock ' +
      '                     WHERE CodigoEmpresa = S.CodigoEmpresa ' +
      '                       AND Periodo BETWEEN 1 AND 12) ';
    if Familia <> '' then
      SQL := SQL + 'AND A.CodigoFamilia = :Fa ';
    SQL := SQL +
      'GROUP BY S.CodigoArticulo, A.DescripcionArticulo, ' +
      '  A.CodigoFamilia, A.UnidadMedida2_ ' +
      'HAVING SUM(S.CosteSalida) > 0 ' +
      'ORDER BY SUM(S.CosteSalida) DESC';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    if Familia <> '' then
      Q.Parameters.ParamByName('Fa').Value := Familia;
    Q.Open;
    SetLength(Result, Q.RecordCount);

    // Primera passada: omplir + total
    TotalImporte := 0;
    Idx := 0;
    while not Q.Eof do
    begin
      R := Default(TAnalisisABCErp);
      R.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
      R.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      R.CodigoFamilia       := Q.FieldByName('CodigoFamilia').AsString;
      R.UnidadMedida        := Q.FieldByName('UnidadMedida').AsString;
      R.UnidadesConsumidas  := Q.FieldByName('UnidadesConsumidas').AsFloat;
      R.ImporteConsumido    := Q.FieldByName('ImporteConsumido').AsFloat;
      TotalImporte := TotalImporte + R.ImporteConsumido;
      Result[Idx] := R;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);

    // Segona passada: % individual, % acumulat, categoria.
    if TotalImporte > 0 then
    begin
      AcumImporte := 0;
      for i := 0 to High(Result) do
      begin
        Result[i].PorcentajeIndividual := Result[i].ImporteConsumido / TotalImporte * 100;
        AcumImporte := AcumImporte + Result[i].ImporteConsumido;
        Result[i].PorcentajeAcumulado := AcumImporte / TotalImporte * 100;
        if Result[i].PorcentajeAcumulado <= 80 then
          Result[i].Categoria := 'A'
        else if Result[i].PorcentajeAcumulado <= 95 then
          Result[i].Categoria := 'B'
        else
          Result[i].Categoria := 'C';
      end;
    end;
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// RUPTURAS FUTURAS (agregat r'apid)
// ---------------------------------------------------------------------------

function TSage200Reader.ReadRupturasFuturas(const AAlmacenes: TArray<string>;
  const AFiltroFamilia: string;
  ADiasHorizonte: Integer): TArray<TRupturaFuturaErp>;
var
  Q: TADOQuery;
  R: TRupturaFuturaErp;
  Idx: Integer;
  Familia: string;
  FechaHasta: TDateTime;
  CE, FH, FaClause: string;
  SQL, AlmacenesIn: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Familia := Trim(AFiltroFamilia);
  if ADiasHorizonte <= 0 then ADiasHorizonte := 60;
  FechaHasta := IncDay(Date, ADiasHorizonte);
  AlmacenesIn := BuildAlmacenesIn(AAlmacenes, 'CodigoAlmacen');

  // ADO no permet duplicar params dins una mateixa query (i el CTE en t'e
  // m'ultiples). Interpolem els valors com a literals (Int i Date son segurs;
  // la familia s'i ve d'usuari, l'escapem amb QuotedStr).
  CE := IntToStr(FCodigoEmpresa);
  FH := QuotedStr(FormatDateTime('yyyymmdd', FechaHasta));
  if Familia <> '' then
    FaClause := 'AND A.CodigoFamilia = ' + QuotedStr(Familia) + ' '
  else
    FaClause := '';

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'WITH UltEj AS ( ' +
      '  SELECT MAX(Ejercicio) AS Ej FROM dbo.AcumuladoStock ' +
      '  WHERE CodigoEmpresa = ' + CE + ' AND Periodo = 99 ' +
      '), StockBase AS ( ' +
      '  SELECT N.CodigoArticulo, N.CodigoAlmacen, ' +
      '    SUM(N.UnidadSaldo) AS Saldo ' +
      '  FROM dbo.AcumuladoStock N, UltEj ' +
      '  WHERE N.CodigoEmpresa = ' + CE + ' ' +
      '    AND N.Periodo = 99 AND N.Ejercicio = UltEj.Ej ';
    if AlmacenesIn <> '' then
      SQL := SQL + StringReplace(AlmacenesIn, 'CodigoAlmacen', 'N.CodigoAlmacen', [rfReplaceAll]);
    SQL := SQL +
      '  GROUP BY N.CodigoArticulo, N.CodigoAlmacen ' +
      '), Compras AS ( ' +
      '  SELECT L.CodigoArticulo, L.CodigoAlmacen, ' +
      '    SUM(L.UnidadesPendientes) AS Unidades ' +
      '  FROM dbo.LineasPedidoProveedor L ' +
      '  WHERE L.CodigoEmpresa = ' + CE + ' ' +
      '    AND L.UnidadesPendientes > 0 ' +
      '    AND (L.FechaNecesaria IS NULL OR L.FechaNecesaria <= ' + FH + ') ';
    if AlmacenesIn <> '' then
      SQL := SQL + StringReplace(AlmacenesIn, 'CodigoAlmacen', 'L.CodigoAlmacen', [rfReplaceAll]);
    SQL := SQL +
      '  GROUP BY L.CodigoArticulo, L.CodigoAlmacen ' +
      '), Ventas AS ( ' +
      '  SELECT L.CodigoArticulo, L.CodigoAlmacen, ' +
      '    SUM(L.UnidadesPendientes) AS Unidades ' +
      '  FROM dbo.LineasPedidoCliente L ' +
      '  WHERE L.CodigoEmpresa = ' + CE + ' ' +
      '    AND L.UnidadesPendientes > 0 ' +
      '    AND (COALESCE(L.FechaEntrega, L.FechaNecesaria) IS NULL ' +
      '         OR COALESCE(L.FechaEntrega, L.FechaNecesaria) <= ' + FH + ') ';
    if AlmacenesIn <> '' then
      SQL := SQL + StringReplace(AlmacenesIn, 'CodigoAlmacen', 'L.CodigoAlmacen', [rfReplaceAll]);
    SQL := SQL +
      '  GROUP BY L.CodigoArticulo, L.CodigoAlmacen ' +
      '), Produccion AS ( ' +
      '  SELECT OT.CodigoArticulo, OT.CodigoAlmacen, ' +
      '    SUM(OT.UnidadesAFabricar - OT.UnidadesFabricadas) AS Unidades ' +
      '  FROM dbo.OrdenesTrabajo OT ' +
      '  WHERE OT.CodigoEmpresa = ' + CE + ' ' +
      '    AND (OT.UnidadesAFabricar - OT.UnidadesFabricadas) > 0 ' +
      '    AND (OT.FechaFinalPrevista IS NULL OR OT.FechaFinalPrevista <= ' + FH + ') ';
    if AlmacenesIn <> '' then
      SQL := SQL + StringReplace(AlmacenesIn, 'CodigoAlmacen', 'OT.CodigoAlmacen', [rfReplaceAll]);
    SQL := SQL +
      '  GROUP BY OT.CodigoArticulo, OT.CodigoAlmacen ' +
      '), Consumos AS ( ' +
      '  SELECT C.ArticuloComponente AS CodigoArticulo, C.CodigoAlmacen, ' +
      '    SUM(C.UnidadesNecesarias - C.UnidadesUsadas) AS Unidades ' +
      '  FROM dbo.ConsumosOT C ' +
      '  INNER JOIN dbo.OrdenesTrabajo OT ' +
      '    ON  OT.CodigoEmpresa = C.CodigoEmpresa ' +
      '    AND OT.EjercicioTrabajo = C.EjercicioTrabajo ' +
      '    AND OT.NumeroTrabajo = C.NumeroTrabajo ' +
      '  WHERE C.CodigoEmpresa = ' + CE + ' ' +
      '    AND (C.UnidadesNecesarias - C.UnidadesUsadas) > 0 ' +
      '    AND (OT.UnidadesAFabricar - OT.UnidadesFabricadas) > 0 ' +
      '    AND (OT.FechaInicioPrevista IS NULL OR OT.FechaInicioPrevista <= ' + FH + ') ';
    if AlmacenesIn <> '' then
      SQL := SQL + StringReplace(AlmacenesIn, 'CodigoAlmacen', 'C.CodigoAlmacen', [rfReplaceAll]);
    SQL := SQL +
      '  GROUP BY C.ArticuloComponente, C.CodigoAlmacen ' +
      ') ' +
      'SELECT A.CodigoArticulo, A.DescripcionArticulo, A.CodigoFamilia, ' +
      '  A.UnidadMedida2_ AS UnidadMedida, A.StockMinimo, ' +
      '  COALESCE(SB.CodigoAlmacen, CP.CodigoAlmacen, VT.CodigoAlmacen, ' +
      '           PR.CodigoAlmacen, CN.CodigoAlmacen) AS CodigoAlmacen, ' +
      '  COALESCE(SB.Saldo, 0)     AS Saldo, ' +
      '  COALESCE(CP.Unidades, 0)  AS PendienteRecibir, ' +
      '  COALESCE(VT.Unidades, 0)  AS PendienteServir, ' +
      '  COALESCE(PR.Unidades, 0)  AS Produccion, ' +
      '  COALESCE(CN.Unidades, 0)  AS Consumo ' +
      'FROM dbo.Articulos A ' +
      'LEFT JOIN StockBase  SB ON SB.CodigoArticulo = A.CodigoArticulo ' +
      'LEFT JOIN Compras    CP ON CP.CodigoArticulo = A.CodigoArticulo ' +
      '                       AND (SB.CodigoAlmacen IS NULL OR CP.CodigoAlmacen = SB.CodigoAlmacen) ' +
      'LEFT JOIN Ventas     VT ON VT.CodigoArticulo = A.CodigoArticulo ' +
      '                       AND (SB.CodigoAlmacen IS NULL OR VT.CodigoAlmacen = SB.CodigoAlmacen) ' +
      'LEFT JOIN Produccion PR ON PR.CodigoArticulo = A.CodigoArticulo ' +
      '                       AND (SB.CodigoAlmacen IS NULL OR PR.CodigoAlmacen = SB.CodigoAlmacen) ' +
      'LEFT JOIN Consumos   CN ON CN.CodigoArticulo = A.CodigoArticulo ' +
      '                       AND (SB.CodigoAlmacen IS NULL OR CN.CodigoAlmacen = SB.CodigoAlmacen) ' +
      'WHERE A.CodigoEmpresa = ' + CE + ' ' +
      FaClause +
      // Ruptura = saldo final negatiu OR (Minimo>0 AND saldo final < Minimo)
      'AND ((COALESCE(SB.Saldo,0) + COALESCE(CP.Unidades,0) + COALESCE(PR.Unidades,0) ' +
      '      - COALESCE(VT.Unidades,0) - COALESCE(CN.Unidades,0)) < 0 ' +
      '  OR (A.StockMinimo > 0 ' +
      '      AND (COALESCE(SB.Saldo,0) + COALESCE(CP.Unidades,0) + COALESCE(PR.Unidades,0) ' +
      '           - COALESCE(VT.Unidades,0) - COALESCE(CN.Unidades,0)) < A.StockMinimo)) ' +
      'ORDER BY A.CodigoArticulo';
    Q.SQL.Text := SQL;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      R := Default(TRupturaFuturaErp);
      R.CodigoArticulo      := Q.FieldByName('CodigoArticulo').AsString;
      R.DescripcionArticulo := Q.FieldByName('DescripcionArticulo').AsString;
      R.CodigoFamilia       := Q.FieldByName('CodigoFamilia').AsString;
      R.UnidadMedida        := Q.FieldByName('UnidadMedida').AsString;
      R.CodigoAlmacen       := Q.FieldByName('CodigoAlmacen').AsString;
      R.UnidadSaldo         := Q.FieldByName('Saldo').AsFloat;
      R.PendienteRecibir    := Q.FieldByName('PendienteRecibir').AsFloat;
      R.PendienteServir     := Q.FieldByName('PendienteServir').AsFloat;
      R.ProduccionPendiente := Q.FieldByName('Produccion').AsFloat;
      R.ConsumoPendiente    := Q.FieldByName('Consumo').AsFloat;
      R.StockMinimo         := Q.FieldByName('StockMinimo').AsFloat;
      R.SaldoFinal := R.UnidadSaldo + R.PendienteRecibir + R.ProduccionPendiente
                                    - R.PendienteServir  - R.ConsumoPendiente;
      R.Deficit := R.StockMinimo - R.SaldoFinal;
      Result[Idx] := R;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// OFs ACTIVAS DE UN ARTICULO
// ---------------------------------------------------------------------------

function TSage200Reader.ReadOFsActivasArticulo(
  const ACodigoArticulo: string): TArray<TOFActivaArticuloErp>;
var
  Q: TADOQuery;
  O: TOFActivaArticuloErp;
  Idx, Estado: Integer;
  AFab: Double;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    // EstadoOF a Sage: 0=alta, 1=lanzada, 2=en curso, 3=finalizada, 4=anulada
    // "actives" = no 3 (finalitzada) ni 4 (anul.lada)
    Q.SQL.Text :=
      'SELECT EjercicioFabricacion, SerieFabricacion, NumeroFabricacion, ' +
      '  FechaCreacion, FechaInicioPrevista, FechaFinalPrevista, FechaEntrega, ' +
      '  UnidadesAFabricar, UnidadesFabricadas, ' +
      '  EstadoOF, Prioridad, CodigoProyecto ' +
      'FROM dbo.OrdenesFabricacion ' +
      'WHERE CodigoEmpresa = :CE AND CodigoArticulo = :Art ' +
      '  AND EstadoOF NOT IN (3, 4) ' +
      'ORDER BY FechaFinalPrevista, EjercicioFabricacion, NumeroFabricacion';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Art').Value := ACodigoArticulo;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      O := Default(TOFActivaArticuloErp);
      O.EjercicioFabricacion := Q.FieldByName('EjercicioFabricacion').AsInteger;
      O.SerieFabricacion     := Q.FieldByName('SerieFabricacion').AsString;
      O.NumeroFabricacion    := Q.FieldByName('NumeroFabricacion').AsInteger;
      if not Q.FieldByName('FechaCreacion').IsNull then
        O.FechaCreacion := Q.FieldByName('FechaCreacion').AsDateTime;
      if not Q.FieldByName('FechaInicioPrevista').IsNull then
        O.FechaInicioPrevista := Q.FieldByName('FechaInicioPrevista').AsDateTime;
      if not Q.FieldByName('FechaFinalPrevista').IsNull then
        O.FechaFinalPrevista := Q.FieldByName('FechaFinalPrevista').AsDateTime;
      if not Q.FieldByName('FechaEntrega').IsNull then
        O.FechaEntrega := Q.FieldByName('FechaEntrega').AsDateTime;
      O.UnidadesAFabricar  := Q.FieldByName('UnidadesAFabricar').AsFloat;
      O.UnidadesFabricadas := Q.FieldByName('UnidadesFabricadas').AsFloat;
      AFab := O.UnidadesAFabricar;
      if AFab > 0 then
        O.PorcentajeProgreso := O.UnidadesFabricadas / AFab * 100
      else
        O.PorcentajeProgreso := 0;
      Estado := Q.FieldByName('EstadoOF').AsInteger;
      O.EstadoOF := Estado;
      case Estado of
        0: O.EstadoDescripcion := 'Alta';
        1: O.EstadoDescripcion := 'Lanzada';
        2: O.EstadoDescripcion := 'En curso';
        3: O.EstadoDescripcion := 'Finalizada';
        4: O.EstadoDescripcion := 'Anulada';
      else
        O.EstadoDescripcion := IntToStr(Estado);
      end;
      O.Prioridad      := Q.FieldByName('Prioridad').AsString;
      O.CodigoProyecto := Q.FieldByName('CodigoProyecto').AsString;
      Result[Idx] := O;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// PROVEEDORES DE UN ARTICULO
// ---------------------------------------------------------------------------

function TSage200Reader.ReadProveedoresArticulo(
  const ACodigoArticulo: string;
  AMesesAtras: Integer): TArray<TProveedorArticuloErp>;
var
  Q: TADOQuery;
  P: TProveedorArticuloErp;
  Idx: Integer;
  FechaDesde: TDateTime;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT C.CodigoProveedor, ' +
      '  MAX(C.RazonSocial) AS RazonSocialProveedor, ' +
      '  SUM(L.UnidadesPedidas)  AS UnidadesCompradasTotal, ' +
      '  COUNT(DISTINCT L.NumeroPedido) AS NumeroPedidosTotal, ' +
      '  MAX(L.FechaPedido)      AS FechaUltimaCompra, ' +
      '  SUM(L.UnidadesPedidas * L.Precio) / NULLIF(SUM(L.UnidadesPedidas), 0) AS PrecioMedioCompra, ' +
      '  AVG(CASE WHEN L.FechaRecepcion IS NOT NULL AND L.FechaPedido IS NOT NULL ' +
      '    THEN DATEDIFF(day, L.FechaPedido, L.FechaRecepcion) END) AS LeadTimeMedio ' +
      'FROM dbo.LineasPedidoProveedor L ' +
      'INNER JOIN dbo.CabeceraPedidoProveedor C ' +
      '  ON  C.CodigoEmpresa   = L.CodigoEmpresa ' +
      '  AND C.EjercicioPedido = L.EjercicioPedido ' +
      '  AND C.SeriePedido     = L.SeriePedido ' +
      '  AND C.NumeroPedido    = L.NumeroPedido ' +
      'WHERE L.CodigoEmpresa = :CE ' +
      '  AND L.CodigoArticulo = :Art ';
    if AMesesAtras > 0 then
    begin
      FechaDesde := IncMonth(Date, -AMesesAtras);
      SQL := SQL + 'AND L.FechaPedido >= :FD ';
    end;
    SQL := SQL +
      'GROUP BY C.CodigoProveedor ' +
      'ORDER BY MAX(L.FechaPedido) DESC';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Art').Value := ACodigoArticulo;
    if AMesesAtras > 0 then
      Q.Parameters.ParamByName('FD').Value := FechaDesde;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      P := Default(TProveedorArticuloErp);
      P.CodigoProveedor        := Q.FieldByName('CodigoProveedor').AsString;
      P.RazonSocialProveedor   := Q.FieldByName('RazonSocialProveedor').AsString;
      P.UnidadesCompradasTotal := Q.FieldByName('UnidadesCompradasTotal').AsFloat;
      P.NumeroPedidosTotal     := Q.FieldByName('NumeroPedidosTotal').AsInteger;
      if not Q.FieldByName('FechaUltimaCompra').IsNull then
        P.FechaUltimaCompra := Q.FieldByName('FechaUltimaCompra').AsDateTime;
      if not Q.FieldByName('PrecioMedioCompra').IsNull then
        P.PrecioMedioCompra := Q.FieldByName('PrecioMedioCompra').AsFloat;
      if not Q.FieldByName('LeadTimeMedio').IsNull then
        P.LeadTimeMedio := Q.FieldByName('LeadTimeMedio').AsFloat;
      // PrecioUltimaCompra: el del pedido amb FechaPedido = FechaUltimaCompra
      // Per evitar segona query, deixem 0 i ja sortira a "PrecioMedio".
      // (Si el client el demana, afegirem subquery dedicada.)
      P.PrecioUltimaCompra := P.PrecioMedioCompra;
      Result[Idx] := P;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// CLIENTES DE UN ARTICULO
// ---------------------------------------------------------------------------

function TSage200Reader.ReadClientesArticulo(
  const ACodigoArticulo: string;
  AMesesAtras: Integer): TArray<TClienteArticuloErp>;
var
  Q: TADOQuery;
  Cl: TClienteArticuloErp;
  Idx: Integer;
  FechaDesde: TDateTime;
  SQL: string;
begin
  SetLength(Result, 0);
  EnsureConnected;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT C.CodigoCliente, ' +
      '  MAX(C.RazonSocial) AS RazonSocialCliente, ' +
      '  SUM(L.UnidadesPedidas) AS UnidadesVendidasTotal, ' +
      '  SUM(L.UnidadesPedidas * L.Precio) AS ImporteVendidoTotal, ' +
      '  COUNT(DISTINCT L.NumeroPedido) AS NumeroPedidosTotal, ' +
      '  MAX(L.FechaPedido) AS FechaUltimaVenta, ' +
      '  SUM(L.UnidadesPedidas * L.Precio) / NULLIF(SUM(L.UnidadesPedidas), 0) AS PrecioMedio ' +
      'FROM dbo.LineasPedidoCliente L ' +
      'INNER JOIN dbo.CabeceraPedidoCliente C ' +
      '  ON  C.CodigoEmpresa   = L.CodigoEmpresa ' +
      '  AND C.EjercicioPedido = L.EjercicioPedido ' +
      '  AND C.SeriePedido     = L.SeriePedido ' +
      '  AND C.NumeroPedido    = L.NumeroPedido ' +
      'WHERE L.CodigoEmpresa = :CE ' +
      '  AND L.CodigoArticulo = :Art ';
    if AMesesAtras > 0 then
    begin
      FechaDesde := IncMonth(Date, -AMesesAtras);
      SQL := SQL + 'AND L.FechaPedido >= :FD ';
    end;
    SQL := SQL +
      'GROUP BY C.CodigoCliente ' +
      'ORDER BY SUM(L.UnidadesPedidas) DESC';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Art').Value := ACodigoArticulo;
    if AMesesAtras > 0 then
      Q.Parameters.ParamByName('FD').Value := FechaDesde;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      Cl := Default(TClienteArticuloErp);
      Cl.CodigoCliente         := Q.FieldByName('CodigoCliente').AsString;
      Cl.RazonSocialCliente    := Q.FieldByName('RazonSocialCliente').AsString;
      Cl.UnidadesVendidasTotal := Q.FieldByName('UnidadesVendidasTotal').AsFloat;
      Cl.ImporteVendidoTotal   := Q.FieldByName('ImporteVendidoTotal').AsFloat;
      Cl.NumeroPedidosTotal    := Q.FieldByName('NumeroPedidosTotal').AsInteger;
      if not Q.FieldByName('FechaUltimaVenta').IsNull then
        Cl.FechaUltimaVenta := Q.FieldByName('FechaUltimaVenta').AsDateTime;
      if not Q.FieldByName('PrecioMedio').IsNull then
        Cl.PrecioMedio := Q.FieldByName('PrecioMedio').AsFloat;
      Result[Idx] := Cl;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// KPIs INDIVIDUALS PER ARTICLE
// ---------------------------------------------------------------------------

function TSage200Reader.ReadCoberturaArticulo(const ACodigoArticulo: string;
  const AAlmacenes: TArray<string>): TCoberturaErp;
var
  Q: TADOQuery;
  SQL: string;
begin
  Result := Default(TCoberturaErp);
  Result.CodigoArticulo := ACodigoArticulo;
  Result.DiasPeriodo := 365;
  Result.DiasCobertura := -1;
  EnsureConnected;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'WITH UltEj AS ( ' +
      '  SELECT MAX(Ejercicio) AS Ej FROM dbo.AcumuladoStock ' +
      '  WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' AND Periodo = 99 ' +
      ') ' +
      'SELECT ' +
      '  COALESCE(SUM(CASE WHEN S.Periodo = 99 THEN S.UnidadSaldo ELSE 0 END), 0) AS UnidadSaldo, ' +
      '  COALESCE(SUM(CASE WHEN S.Periodo BETWEEN 1 AND 12 THEN S.UnidadSalida ELSE 0 END), 0) AS Consumo ' +
      'FROM dbo.AcumuladoStock S, UltEj ' +
      'WHERE S.CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) + ' ' +
      '  AND S.CodigoArticulo = ' + QuotedStr(ACodigoArticulo) + ' ' +
      '  AND S.Ejercicio = UltEj.Ej';
    SQL := SQL + BuildAlmacenesIn(AAlmacenes, 'S.CodigoAlmacen');
    Q.SQL.Text := SQL;
    Q.Open;
    if not Q.Eof then
    begin
      Result.UnidadSaldo    := Q.FieldByName('UnidadSaldo').AsFloat;
      Result.ConsumoPeriodo := Q.FieldByName('Consumo').AsFloat;
      Result.ConsumoDiario  := Result.ConsumoPeriodo / 365;
      if Result.ConsumoDiario > 0 then
        Result.DiasCobertura := Result.UnidadSaldo / Result.ConsumoDiario;
    end;
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadCategoriaABCArticulo(
  const ACodigoArticulo: string): string;
var
  Q: TADOQuery;
  TotalImporte, AcumImporte, ImporteArt: Double;
  CodArt: string;
  Trobat: Boolean;
begin
  Result := '';
  EnsureConnected;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT S.CodigoArticulo, SUM(S.CosteSalida) AS Importe ' +
      'FROM dbo.AcumuladoStock S ' +
      'WHERE S.CodigoEmpresa = :CE ' +
      '  AND S.Periodo BETWEEN 1 AND 12 ' +
      '  AND S.Ejercicio = (SELECT MAX(Ejercicio) FROM dbo.AcumuladoStock ' +
      '                     WHERE CodigoEmpresa = S.CodigoEmpresa ' +
      '                       AND Periodo BETWEEN 1 AND 12) ' +
      'GROUP BY S.CodigoArticulo ' +
      'HAVING SUM(S.CosteSalida) > 0 ' +
      'ORDER BY SUM(S.CosteSalida) DESC';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;
    TotalImporte := 0;
    Q.First;
    while not Q.Eof do
    begin
      TotalImporte := TotalImporte + Q.FieldByName('Importe').AsFloat;
      Q.Next;
    end;
    if TotalImporte <= 0 then Exit;
    AcumImporte := 0;
    Trobat := False;
    ImporteArt := 0;
    Q.First;
    while not Q.Eof do
    begin
      CodArt := Q.FieldByName('CodigoArticulo').AsString;
      ImporteArt := Q.FieldByName('Importe').AsFloat;
      AcumImporte := AcumImporte + ImporteArt;
      if SameText(CodArt, ACodigoArticulo) then
      begin
        Trobat := True;
        if AcumImporte / TotalImporte * 100 <= 80 then
          Result := 'A'
        else if AcumImporte / TotalImporte * 100 <= 95 then
          Result := 'B'
        else
          Result := 'C';
        Break;
      end;
      Q.Next;
    end;
    if not Trobat then Result := ''; // article sense consum
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------
// DASHBOARD OPERATIU
// ---------------------------------------------------------------------------

function TSage200Reader.ReadOFsActivasTop(AOrdenarPorFechaFin: Boolean;
  ALimit: Integer): TArray<TOFGlobalErp>;
var
  Q: TADOQuery;
  O: TOFGlobalErp;
  Idx, Estado: Integer;
  SQL: string;
  AFab: Double;
begin
  SetLength(Result, 0);
  EnsureConnected;
  if ALimit <= 0 then ALimit := 50;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConn;
    SQL :=
      'SELECT TOP ' + IntToStr(ALimit) + ' ' +
      '  EjercicioFabricacion, SerieFabricacion, NumeroFabricacion, ' +
      '  CodigoArticulo, DescripcionArticulo, ' +
      '  FechaInicioPrevista, FechaFinalPrevista, ' +
      '  UnidadesAFabricar, UnidadesFabricadas, EstadoOF ' +
      'FROM dbo.OrdenesFabricacion ' +
      'WHERE CodigoEmpresa = :CE ' +
      '  AND EstadoOF NOT IN (3, 4) ';
    if AOrdenarPorFechaFin then
      SQL := SQL + 'ORDER BY FechaFinalPrevista ASC, EjercicioFabricacion, NumeroFabricacion'
    else
      SQL := SQL + 'ORDER BY FechaInicioPrevista DESC, EjercicioFabricacion DESC, NumeroFabricacion DESC';
    Q.SQL.Text := SQL;
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;
    SetLength(Result, Q.RecordCount);
    Idx := 0;
    while not Q.Eof do
    begin
      O := Default(TOFGlobalErp);
      O.EjercicioFabricacion := Q.FieldByName('EjercicioFabricacion').AsInteger;
      O.SerieFabricacion     := Q.FieldByName('SerieFabricacion').AsString;
      O.NumeroFabricacion    := Q.FieldByName('NumeroFabricacion').AsInteger;
      O.CodigoArticulo       := Q.FieldByName('CodigoArticulo').AsString;
      O.DescripcionArticulo  := Q.FieldByName('DescripcionArticulo').AsString;
      if not Q.FieldByName('FechaInicioPrevista').IsNull then
        O.FechaInicioPrevista := Q.FieldByName('FechaInicioPrevista').AsDateTime;
      if not Q.FieldByName('FechaFinalPrevista').IsNull then
        O.FechaFinalPrevista := Q.FieldByName('FechaFinalPrevista').AsDateTime;
      O.UnidadesAFabricar  := Q.FieldByName('UnidadesAFabricar').AsFloat;
      O.UnidadesFabricadas := Q.FieldByName('UnidadesFabricadas').AsFloat;
      AFab := O.UnidadesAFabricar;
      if AFab > 0 then
        O.PorcentajeProgreso := O.UnidadesFabricadas / AFab * 100;
      Estado := Q.FieldByName('EstadoOF').AsInteger;
      O.EstadoOF := Estado;
      case Estado of
        0: O.EstadoDescripcion := 'Alta';
        1: O.EstadoDescripcion := 'Lanzada';
        2: O.EstadoDescripcion := 'En curso';
      else
        O.EstadoDescripcion := IntToStr(Estado);
      end;
      if O.FechaFinalPrevista > 0 then
        O.DiasDesfase := Trunc(Date - O.FechaFinalPrevista)
      else
        O.DiasDesfase := 0;
      Result[Idx] := O;
      Inc(Idx);
      Q.Next;
    end;
    SetLength(Result, Idx);
  finally
    Q.Free;
  end;
end;

function TSage200Reader.ReadArticulosAsinStock(
  ALimit: Integer): TArray<TArticuloACriticoErp>;
var
  A: TArticuloACriticoErp;
  ABC: TArray<TAnalisisABCErp>;
  i, Cont: Integer;
  Disp: TArray<TStockDisponibleErp>;
  DispMap: TDictionary<string, Double>;
  Codi: string;
  DispTot: Double;
begin
  SetLength(Result, 0);
  if ALimit <= 0 then ALimit := 10;

  // ABC complet (l'ordre ja ve per import DESC, primer els A mes grans).
  ABC := ReadAnalisisABC('', 365);

  // Indexem stock disponible per article (sumant per almacen) per evitar N queries.
  Disp := ReadStockDisponible('', '');
  DispMap := TDictionary<string, Double>.Create;
  try
    for i := 0 to High(Disp) do
    begin
      Codi := Disp[i].CodigoArticulo;
      if DispMap.ContainsKey(Codi) then
        DispMap[Codi] := DispMap[Codi] + Disp[i].Disponible
      else
        DispMap.Add(Codi, Disp[i].Disponible);
    end;

    SetLength(Result, ALimit);
    Cont := 0;
    for i := 0 to High(ABC) do
    begin
      if ABC[i].Categoria <> 'A' then Continue;
      DispTot := 0;
      DispMap.TryGetValue(ABC[i].CodigoArticulo, DispTot);
      if DispTot > 0 then Continue;
      A := Default(TArticuloACriticoErp);
      A.CodigoArticulo         := ABC[i].CodigoArticulo;
      A.DescripcionArticulo    := ABC[i].DescripcionArticulo;
      A.CodigoFamilia          := ABC[i].CodigoFamilia;
      A.UnidadMedida           := ABC[i].UnidadMedida;
      A.Disponible             := DispTot;
      A.ImporteConsumidoUltAno := ABC[i].ImporteConsumido;
      Result[Cont] := A;
      Inc(Cont);
      if Cont >= ALimit then Break;
    end;
    SetLength(Result, Cont);
  finally
    DispMap.Free;
  end;
end;

end.
