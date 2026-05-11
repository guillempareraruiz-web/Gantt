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
  System.SysUtils, System.Classes, System.Generics.Collections,
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
    constructor Create;
    destructor Destroy; override;

    // IErpReader
    function GetSistemaNombre: string;
    procedure EnsureConnected;
    function ReadPedidoCabecera(const ASerie: string; ANumero: Integer;
      AEjercicio: SmallInt): TPedidoCabecera;
    function ReadPedidoLineas(const ASerie: string; ANumero: Integer;
      AEjercicio: SmallInt): TArray<TPedidoLinea>;
    function ReadFormulaVersiones(const ACodigoArticulo: string): TArray<SmallInt>;
    function ReadFormulaCabecera(const ACodigoArticulo: string): TFormulaCabecera;
    function ReadFormulaComponentes(const ACodigoArticulo: string;
      AVersion: SmallInt): TArray<TFormulaComponente>;
    function ReadFormulaOperaciones(const ACodigoArticulo: string;
      AVersion: SmallInt): TArray<TFormulaOperacion>;
  end;

implementation

constructor TSage200Reader.Create;
begin
  inherited Create;
  FCfg := LoadErpSage200Config;
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
      '  Comentario, Comentarios ' +
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
      '  Unidades, UnidadMedida, Precio, Descuento1, Descuento2, ' +
      '  ImporteLiquido, FechaServicio, FechaNecesaria, ' +
      '  UnidadesServidas, UnidadesPendientes, Comentario ' +
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

end.
