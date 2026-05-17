unit uStockProjection;

// ============================================================================
// Engine de projecci'on de stock (Projected Stock / ATP).
//
// Construye una timeline de movimientos futuros para un articulo y calcula el
// stock proyectado a una fecha dada. NO hace queries: recibe las listas ya
// le'idas del connector ERP (uErpReader) y las combina.
//
// Uso:
//   var Proy: TStockProjector;
//   Proy := TStockProjector.Create;
//   try
//     Proy.StockInicial := 100;
//     Proy.StockMinimo  := 20;
//     Proy.SetEntradasCompra(Compras);
//     Proy.SetSalidasVenta(Ventas);
//     Proy.SetMovimientosOF(MovsOF);
//     Stock := Proy.StockEnFecha(EncodeDate(2026, 7, 1));
//     Movs  := Proy.MovimientosOrdenados;  // para grid
//   finally
//     Proy.Free;
//   end;
// ============================================================================

interface

uses
  System.SysUtils, System.DateUtils,
  System.Generics.Collections, System.Generics.Defaults,
  uErpTypes;

type
  TTipoMovStock = (
    tmStockActual,     // base inicial
    tmCompra,          // pedido proveedor pendiente (+)
    tmVenta,           // pedido cliente pendiente (-)
    tmProduccionOF,    // OT pendiente, producto acabado (+)
    tmConsumoOF        // OT pendiente, materia prima (-)
  );

  TMovStock = record
    Fecha: TDateTime;
    Tipo: TTipoMovStock;
    Concepto: string;       // descripcion human-readable
    Referencia: string;     // codigo pedido, OF, etc.
    Articulo: string;
    Almacen: string;
    UnidadesEntrada: Double; // siempre >= 0
    UnidadesSalida: Double;  // siempre >= 0
    SaldoAcumulado: Double;  // se rellena al ordenar
    BajoMinimo: Boolean;     // True si SaldoAcumulado < StockMinimo
  end;

  TResumenProyeccion = record
    StockInicial: Double;
    TotalEntradas: Double;
    TotalSalidas: Double;
    StockFinal: Double;
    AlgunaVezBajoMinimo: Boolean;
    SaldoMinimoAlcanzado: Double;
    FechaSaldoMinimo: TDateTime;
  end;

  TStockProjector = class
  private
    FStockInicial: Double;
    FStockMinimo: Double;
    FMovimientos: TList<TMovStock>;
    FOrdenadosCalculados: Boolean;
    procedure ResetOrden;
    procedure RecalcularSaldos;
  public
    constructor Create;
    destructor Destroy; override;

    // Configuracion
    property StockInicial: Double read FStockInicial write FStockInicial;
    property StockMinimo: Double read FStockMinimo write FStockMinimo;

    // Carga de fuentes (cada Set* borra los movimientos del mismo tipo).
    procedure SetEntradasCompra(const AItems: TArray<TEntradaFuturaErp>);
    procedure SetSalidasVenta(const AItems: TArray<TSalidaFuturaVentaErp>);
    procedure SetMovimientosOF(const AItems: TArray<TMovOFErp>);

    // Consultas (recalculan si fa falta).
    function MovimientosOrdenados: TArray<TMovStock>;
    function StockEnFecha(AFecha: TDateTime): Double;
    function Resumen(AFechaCorte: TDateTime): TResumenProyeccion;
  end;

implementation

constructor TStockProjector.Create;
begin
  inherited;
  FMovimientos := TList<TMovStock>.Create;
end;

destructor TStockProjector.Destroy;
begin
  FMovimientos.Free;
  inherited;
end;

procedure TStockProjector.ResetOrden;
begin
  FOrdenadosCalculados := False;
end;

procedure TStockProjector.SetEntradasCompra(
  const AItems: TArray<TEntradaFuturaErp>);
var
  i: Integer;
  M: TMovStock;
  Fecha: TDateTime;
begin
  // Borra existents d'aquest tipus
  for i := FMovimientos.Count - 1 downto 0 do
    if FMovimientos[i].Tipo = tmCompra then
      FMovimientos.Delete(i);

  for i := 0 to High(AItems) do
  begin
    // Prioritzem FechaNecesaria; si no, FechaRecepcion; si no, FechaPedido.
    Fecha := AItems[i].FechaNecesaria;
    if Fecha = 0 then Fecha := AItems[i].FechaRecepcion;
    if Fecha = 0 then Fecha := AItems[i].FechaPedido;
    if Fecha = 0 then Continue;

    M := Default(TMovStock);
    M.Fecha := Fecha;
    M.Tipo := tmCompra;
    M.Concepto := 'Pedido compra ' + AItems[i].SeriePedido +
                  IntToStr(AItems[i].NumeroPedido);
    if AItems[i].RazonSocialProveedor <> '' then
      M.Concepto := M.Concepto + ' - ' + AItems[i].RazonSocialProveedor;
    M.Referencia := Format('%d/%s/%d-%d',
      [AItems[i].EjercicioPedido, AItems[i].SeriePedido,
       AItems[i].NumeroPedido, AItems[i].Orden]);
    M.Articulo := AItems[i].CodigoArticulo;
    M.Almacen := AItems[i].CodigoAlmacen;
    M.UnidadesEntrada := AItems[i].UnidadesPendientes;
    FMovimientos.Add(M);
  end;
  ResetOrden;
end;

procedure TStockProjector.SetSalidasVenta(
  const AItems: TArray<TSalidaFuturaVentaErp>);
var
  i: Integer;
  M: TMovStock;
  Fecha: TDateTime;
begin
  for i := FMovimientos.Count - 1 downto 0 do
    if FMovimientos[i].Tipo = tmVenta then
      FMovimientos.Delete(i);

  for i := 0 to High(AItems) do
  begin
    Fecha := AItems[i].FechaServicio;
    if Fecha = 0 then Fecha := AItems[i].FechaNecesaria;
    if Fecha = 0 then Fecha := AItems[i].FechaPedido;
    if Fecha = 0 then Continue;

    M := Default(TMovStock);
    M.Fecha := Fecha;
    M.Tipo := tmVenta;
    M.Concepto := 'Pedido venta ' + AItems[i].SeriePedido +
                  IntToStr(AItems[i].NumeroPedido);
    if AItems[i].RazonSocialCliente <> '' then
      M.Concepto := M.Concepto + ' - ' + AItems[i].RazonSocialCliente;
    M.Referencia := Format('%d/%s/%d-%d',
      [AItems[i].EjercicioPedido, AItems[i].SeriePedido,
       AItems[i].NumeroPedido, AItems[i].Orden]);
    M.Articulo := AItems[i].CodigoArticulo;
    M.Almacen := AItems[i].CodigoAlmacen;
    M.UnidadesSalida := AItems[i].UnidadesPendientes;
    FMovimientos.Add(M);
  end;
  ResetOrden;
end;

procedure TStockProjector.SetMovimientosOF(const AItems: TArray<TMovOFErp>);
var
  i: Integer;
  M: TMovStock;
begin
  for i := FMovimientos.Count - 1 downto 0 do
    if FMovimientos[i].Tipo in [tmProduccionOF, tmConsumoOF] then
      FMovimientos.Delete(i);

  for i := 0 to High(AItems) do
  begin
    if AItems[i].Fecha = 0 then Continue;

    M := Default(TMovStock);
    M.Fecha := AItems[i].Fecha;
    M.Articulo := AItems[i].CodigoArticulo;
    M.Almacen := AItems[i].CodigoAlmacen;
    M.Referencia := Format('OF %d/%s/%d',
      [AItems[i].EjercicioFabricacion, AItems[i].SerieFabricacion,
       AItems[i].NumeroFabricacion]);
    if AItems[i].EsProduccion then
    begin
      M.Tipo := tmProduccionOF;
      M.Concepto := 'Fabricaci'#243'n ' + M.Referencia;
      M.UnidadesEntrada := AItems[i].Unidades;
    end
    else
    begin
      M.Tipo := tmConsumoOF;
      M.Concepto := 'Consumo ' + M.Referencia;
      M.UnidadesSalida := AItems[i].Unidades;
    end;
    FMovimientos.Add(M);
  end;
  ResetOrden;
end;

procedure TStockProjector.RecalcularSaldos;
var
  i: Integer;
  Saldo: Double;
  Lista: TList<TMovStock>;
  M: TMovStock;
begin
  // Ordena per data + tipus (entrades abans que sortides el mateix dia, criteri
  // pessimista no: optimista. Per ser conservadors, processem sortides primer
  // si volem assegurar que no quedem en negatiu inesperat. Triem ENTRADES
  // primer, que es el comportament esperat per l'usuari: "que entrara fins X"
  // i despres es consumeix).
  Lista := TList<TMovStock>.Create;
  try
    Lista.AddRange(FMovimientos);
    Lista.Sort(TComparer<TMovStock>.Construct(
      function(const A, B: TMovStock): Integer
      begin
        Result := CompareDateTime(A.Fecha, B.Fecha);
        if Result = 0 then
          Result := Integer(A.Tipo) - Integer(B.Tipo);
      end));

    Saldo := FStockInicial;
    FMovimientos.Clear;
    for i := 0 to Lista.Count - 1 do
    begin
      M := Lista[i];
      Saldo := Saldo + M.UnidadesEntrada - M.UnidadesSalida;
      M.SaldoAcumulado := Saldo;
      M.BajoMinimo := (FStockMinimo > 0) and (Saldo < FStockMinimo);
      FMovimientos.Add(M);
    end;
    FOrdenadosCalculados := True;
  finally
    Lista.Free;
  end;
end;

function TStockProjector.MovimientosOrdenados: TArray<TMovStock>;
begin
  if not FOrdenadosCalculados then
    RecalcularSaldos;
  Result := FMovimientos.ToArray;
end;

function TStockProjector.StockEnFecha(AFecha: TDateTime): Double;
var
  i: Integer;
  Movs: TArray<TMovStock>;
begin
  Movs := MovimientosOrdenados;
  Result := FStockInicial;
  for i := 0 to High(Movs) do
  begin
    if Movs[i].Fecha > AFecha then Break;
    Result := Result + Movs[i].UnidadesEntrada - Movs[i].UnidadesSalida;
  end;
end;

function TStockProjector.Resumen(AFechaCorte: TDateTime): TResumenProyeccion;
var
  i: Integer;
  Movs: TArray<TMovStock>;
  Saldo: Double;
begin
  Result := Default(TResumenProyeccion);
  Result.StockInicial := FStockInicial;
  Result.SaldoMinimoAlcanzado := FStockInicial;
  Result.StockFinal := FStockInicial;

  Movs := MovimientosOrdenados;
  Saldo := FStockInicial;
  for i := 0 to High(Movs) do
  begin
    if (AFechaCorte > 0) and (Movs[i].Fecha > AFechaCorte) then Break;
    Result.TotalEntradas := Result.TotalEntradas + Movs[i].UnidadesEntrada;
    Result.TotalSalidas := Result.TotalSalidas + Movs[i].UnidadesSalida;
    Saldo := Saldo + Movs[i].UnidadesEntrada - Movs[i].UnidadesSalida;
    if Saldo < Result.SaldoMinimoAlcanzado then
    begin
      Result.SaldoMinimoAlcanzado := Saldo;
      Result.FechaSaldoMinimo := Movs[i].Fecha;
    end;
    if (FStockMinimo > 0) and (Saldo < FStockMinimo) then
      Result.AlgunaVezBajoMinimo := True;
  end;
  Result.StockFinal := Saldo;
end;

end.
