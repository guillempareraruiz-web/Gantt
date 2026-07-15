unit uDemoMode;

// ============================================================================
// Modo DEMO global (no destructivo).
//
// Un estado global conmutable que las pantallas consultan para mostrar datos
// FICTICIOS y creibles en lugar de los reales. Pensado para:
//   - Demos comerciales: nunca ensenyar KPIs vacios o a cero.
//   - Capturas / formacion: rellenar graficas y tarjetas con datos plausibles.
//
// Clave: los datos ficticios se generan AL VUELO en cada pantalla; este modulo
// NO toca la base de datos. Al desactivar el modo, todo vuelve a los datos
// reales sin rastro.
//
// Uso desde una pantalla:
//   1. En FormCreate:  DemoMode.AddListener(DemoChanged);   // TNotifyEvent
//      (y quitar en Destroy: DemoMode.RemoveListener(DemoChanged))
//   2. En el handler:  refrescar la pantalla (que consultara DemoMode.Active).
//   3. Al pintar/cargar:
//        if DemoMode.Active then <serie ficticia> else <serie real>.
//
// El boton "Demo" del toolbar (uMain) hace DemoMode.Toggle.
//
// Helpers de generacion (DemoSeries*) para producir series creibles a partir
// del valor actual, de forma DETERMINISTA (sin Random) para que no parpadeen
// entre refrescos.
// ============================================================================

interface

uses
  System.Classes, System.Generics.Collections, System.Math, System.SysUtils,
  System.DateUtils,
  uErpTypes;

type
  TDemoMode = class
  private
    FActive: Boolean;
    FListeners: TList<TNotifyEvent>;
    procedure SetActive(const AValue: Boolean);
    procedure Notify;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Toggle;
    procedure AddListener(const AHandler: TNotifyEvent);
    procedure RemoveListener(const AHandler: TNotifyEvent);

    property Active: Boolean read FActive write SetActive;
  end;

// Singleton global.
function DemoMode: TDemoMode;

// Genera una serie ficticia creible de ACount puntos que TERMINA en AEndValue,
// con una tendencia suave ascendente y una pequenya ondulacion. Determinista
// (depende solo de los parametros) para no parpadear entre refrescos.
//   AEndValue : valor final (el "real" que se muestra grande en la card).
//   ACount    : numero de puntos (p.ej. 7).
//   AAmplitud : 0..1, cuanto oscila respecto al valor final (0.15 = 15%).
function DemoSerieHaciaValor(const AEndValue: Double; ACount: Integer = 12;
  const AAmplitud: Double = 0.22; ASeed: Integer = 0): TArray<Double>;

// ============================================================================
// Datos DEMO para la ficha de articulo (PLAN STOCK / MRP).
//
// La pantalla Article Detail lee 5 conjuntos via IErpReader (articulo, stock
// disponible, entradas de compra, salidas de venta, movimientos de OFs) y a
// partir de ellos calcula la proyeccion, el time-phased view, los KPIs y la
// recomendacion MRP. En modo Demo sustituimos esas 5 lecturas por estos
// generadores, que producen un ESCENARIO COHERENTE y determinista:
//   - stock inicial medio,
//   - una tanda de ventas que hunde el saldo por debajo del minimo (ruptura),
//   - una compra + una OF en curso que lo recuperan parcialmente
// -> la ficha sale llena, con ruptura visible y una recomendacion MRP real.
//
// Todo es determinista (sin Random): depende solo del codigo de articulo y de
// AHoy, para que no parpadee entre refrescos.
// ============================================================================

// Codigos de articulo demo (catalogo pequeno y realista). El primero es el que
// carga por defecto la ficha al entrar en Demo sin codigo concreto.
function DemoArticuloCodigos: TArray<string>;

// Almacenes ficticios para el combo de la ficha (nunca vacio en Demo).
function DemoAlmacenes: TArray<TAlmacenErp>;

// Articulo demo (con parametros MRP: minimo, lote, lead time, TieneFormula...).
// Si ACodigo no esta en el catalogo, devuelve el primero.
function DemoArticulo(const ACodigo: string): TArticuloErp;

// Stock disponible actual por almacen para el articulo (una o varias filas).
function DemoStockDisponible(const ACodigo: string): TArray<TStockDisponibleErp>;

// Entradas de compra pendientes (una recepcion prevista dentro del horizonte).
function DemoEntradasCompra(const ACodigo: string;
  AHoy: TDateTime): TArray<TEntradaFuturaErp>;

// Salidas de venta pendientes (varios pedidos que consumen el stock y provocan
// la ruptura). Escalonadas en el tiempo para que el time-phased tenga relieve.
function DemoSalidasVenta(const ACodigo: string;
  AHoy: TDateTime): TArray<TSalidaFuturaVentaErp>;

// Movimientos de OFs pendientes (una OF en curso que produce el articulo y
// recupera parte del saldo). Vacio para articulos de compra pura.
function DemoMovimientosOF(const ACodigo: string;
  AHoy: TDateTime): TArray<TMovOFErp>;

// --- Datos demo para los tabs secundarios de la ficha de articulo ---------
// Cada uno devuelve el mismo tipo ERP que el reader real, para reutilizar tal
// cual el mapeo de cada CargarXxx. Coherentes con el escenario del articulo.

// Partidas / lotes en stock (desglose del saldo actual por almacen+partida).
function DemoPartidas(const ACodigo: string;
  AHoy: TDateTime): TArray<TStockArticuloErp>;

// Historico mensual de entradas/salidas (ultimos AMeses meses).
function DemoHistoricoMensual(const ACodigo: string; AMeses: Integer;
  AHoy: TDateTime): TArray<THistoricoMesErp>;

// Donde se usa (formulas de otros articulos que consumen este). Solo tiene
// sentido para MP/SE; para producto acabado (PA) suele ir vacio.
function DemoDondeSeUsa(const ACodigo: string): TArray<TDondeSeUsaErp>;

// OFs activas que producen este articulo (solo si es fabricable).
function DemoOFsActivas(const ACodigo: string;
  AHoy: TDateTime): TArray<TOFActivaArticuloErp>;

// Proveedores historicos (solo articulos de compra: MP).
function DemoProveedores(const ACodigo: string;
  AHoy: TDateTime): TArray<TProveedorArticuloErp>;

// Clientes historicos (articulos que se venden: PA/SE).
function DemoClientes(const ACodigo: string;
  AHoy: TDateTime): TArray<TClienteArticuloErp>;

// KPI cabecera: dias de cobertura del articulo (>=0). Coherente con el stock
// y el consumo del escenario.
function DemoDiasCobertura(const ACodigo: string): Double;

// KPI cabecera: categoria ABC del articulo ('A' / 'B' / 'C').
function DemoCategoriaABC(const ACodigo: string): string;

implementation

var
  GDemoMode: TDemoMode = nil;

function DemoMode: TDemoMode;
begin
  if GDemoMode = nil then
    GDemoMode := TDemoMode.Create;
  Result := GDemoMode;
end;

{ TDemoMode }

constructor TDemoMode.Create;
begin
  inherited Create;
  FListeners := TList<TNotifyEvent>.Create;
  FActive := False;
end;

destructor TDemoMode.Destroy;
begin
  FListeners.Free;
  inherited;
end;

procedure TDemoMode.SetActive(const AValue: Boolean);
begin
  if FActive = AValue then Exit;
  FActive := AValue;
  Notify;
end;

procedure TDemoMode.Toggle;
begin
  Active := not FActive;
end;

procedure TDemoMode.AddListener(const AHandler: TNotifyEvent);
begin
  if FListeners.IndexOf(AHandler) < 0 then
    FListeners.Add(AHandler);
end;

procedure TDemoMode.RemoveListener(const AHandler: TNotifyEvent);
var
  I: Integer;
begin
  I := FListeners.IndexOf(AHandler);
  if I >= 0 then
    FListeners.Delete(I);
end;

procedure TDemoMode.Notify;
var
  H: TNotifyEvent;
begin
  // Copia defensiva: un listener podria (des)registrarse durante el aviso.
  for H in FListeners.ToArray do
    if Assigned(H) then
      H(Self);
end;

function DemoSerieHaciaValor(const AEndValue: Double; ACount: Integer;
  const AAmplitud: Double; ASeed: Integer): TArray<Double>;
var
  I: Integer;
  T, Base, Wave, Dip, V, Ph: Double;
begin
  if ACount < 2 then ACount := 12;   // mas puntos = sparkline mas "viva"
  SetLength(Result, ACount);

  // Fase derivada del seed: da a cada KPI una forma distinta (sin Random, para
  // no parpadear entre refrescos). El seed lo aporta el caller (p.ej. hash del
  // nombre de la columna); si es 0, se usa una fase neutra.
  Ph := (ASeed mod 7) * 0.9;

  for I := 0 to ACount - 1 do
  begin
    T := I / (ACount - 1);                       // 0..1

    // Tendencia general ascendente hacia el valor final, con arranque mas bajo.
    Base := AEndValue * (0.55 + 0.45 * T);

    // Ondulacion rica: suma de 3 senos de distinta frecuencia y fase. NO se
    // amortigua al final -> la linea sigue teniendo relieve hasta el ultimo tramo.
    Wave := AEndValue * AAmplitud *
            ( Sin(T * Pi * 2.3 + Ph)        * 0.45
            + Sin(T * Pi * 4.7 + Ph * 1.7)  * 0.30
            + Sin(T * Pi * 8.1 + Ph * 0.5)  * 0.15 );

    // Un "bache" (caida y recuperacion) situado en un tercio variable de la
    // serie: aporta una historia creible (algo fue mal y se recupero).
    var DipPos: Double := 0.35 + (ASeed mod 3) * 0.15;   // 0.35 / 0.50 / 0.65
    Dip := -AEndValue * AAmplitud * 1.2 *
           Exp(-Sqr((T - DipPos) / 0.10));               // gaussiana estrecha

    V := Base + Wave + Dip;
    if V < 0 then V := 0;
    Result[I] := V;
  end;

  // Garantizar que el ultimo punto es EXACTAMENTE el valor real mostrado.
  Result[ACount - 1] := AEndValue;
end;

// ============================================================================
// Generadores DEMO para la ficha de articulo (PLAN STOCK / MRP)
// ============================================================================

type
  // Definicion compacta de un escenario MRP demo por articulo. A partir de
  // estos numeros se derivan las 5 lecturas ERP de forma coherente.
  TDemoArtDef = record
    Codigo: string;
    Descripcion: string;
    Familia: string;
    UnidadMedida: string;
    Fabricable: Boolean;      // TieneFormula -> recomendacion = fabricar (boton Gantt)
    Almacen: string;          // almacen principal donde vive el stock
    StockActual: Double;      // saldo fisico hoy
    Reservado: Double;        // reservado por pedidos venta ya confirmados
    StockMinimo: Double;      // punto de alarma (linea rosa en el time-phased)
    Lote: Integer;            // lote de compra o fabricacion (redondeo recom.)
    LeadTimeDias: Integer;    // dias compra o fabricacion
    PrecioCompra: Double;
    PrecioVenta: Double;
    // Demanda: N pedidos de venta escalonados que hunden el saldo.
    NumVentas: Integer;
    VentaBase: Double;        // unidades del primer pedido (crecen un poco)
    PrimerVentaDia: Integer;  // dias desde hoy del primer pedido
    PasoVentaDias: Integer;   // separacion entre pedidos
    // Reposicion en curso: una entrada de compra (siempre) y, si Fabricable,
    // una OF que produce el articulo.
    CompraUnid: Double;
    CompraDia: Integer;       // recepcion prevista (dias desde hoy)
    OFUnid: Double;           // solo si Fabricable
    OFDia: Integer;           // fin previsto de la OF (dias desde hoy)
    Cliente: string;
    Proveedor: string;
  end;

// Catalogo demo. Cuatro historias distintas para que cargar varios articulos
// muestre situaciones diferentes (fabricado con OF, compra pura, critico).
function DemoDefs: TArray<TDemoArtDef>;
begin
  SetLength(Result, 4);

  // 1) Producto acabado fabricable: ruptura clara, se resuelve con OF -> el
  //    boton "Fabricar -> Gantt" tiene sentido. Es el articulo por defecto.
  Result[0].Codigo := 'PA-CAJA-2040';
  Result[0].Descripcion := 'Caja plegable 200x400 negra';
  Result[0].Familia := 'PA';
  Result[0].UnidadMedida := 'ud';
  Result[0].Fabricable := True;
  Result[0].Almacen := 'GEN';
  Result[0].StockActual := 850;
  Result[0].Reservado := 120;
  Result[0].StockMinimo := 300;
  Result[0].Lote := 500;
  Result[0].LeadTimeDias := 5;
  Result[0].PrecioCompra := 0;
  Result[0].PrecioVenta := 4.75;
  Result[0].NumVentas := 5;
  Result[0].VentaBase := 260;
  Result[0].PrimerVentaDia := 4;
  Result[0].PasoVentaDias := 6;
  Result[0].CompraUnid := 0;         // fabricado: sin compra
  Result[0].CompraDia := 0;
  Result[0].OFUnid := 500;           // una OF en curso ya cubre parte
  Result[0].OFDia := 12;
  Result[0].Cliente := 'Distribuciones Valls S.L.';
  Result[0].Proveedor := '';

  // 2) Semielaborado fabricable: demanda alta y sostenida, la OF en curso NO
  //    llega a tiempo -> ruptura antes de la reposicion (recom. urgente).
  Result[1].Codigo := 'SE-TAPA-M8';
  Result[1].Descripcion := 'Tapa inyectada M8 gris RAL7035';
  Result[1].Familia := 'SE';
  Result[1].UnidadMedida := 'ud';
  Result[1].Fabricable := True;
  Result[1].Almacen := 'GEN';
  Result[1].StockActual := 1200;
  Result[1].Reservado := 300;
  Result[1].StockMinimo := 600;
  Result[1].Lote := 1000;
  Result[1].LeadTimeDias := 3;
  Result[1].PrecioCompra := 0;
  Result[1].PrecioVenta := 1.20;
  Result[1].NumVentas := 6;
  Result[1].VentaBase := 320;
  Result[1].PrimerVentaDia := 2;
  Result[1].PasoVentaDias := 4;
  Result[1].CompraUnid := 0;
  Result[1].CompraDia := 0;
  Result[1].OFUnid := 2000;
  Result[1].OFDia := 20;             // tarde: la ruptura ocurre antes
  Result[1].Cliente := 'Mecaniza Ponent S.A.';
  Result[1].Proveedor := '';

  // 3) Materia prima de COMPRA pura (sin formula): la reposicion es un pedido
  //    de compra -> recomendacion = comprar (sin boton Gantt).
  Result[2].Codigo := 'MP-GRANZA-PP01';
  Result[2].Descripcion := 'Granza PP copol'#237'mero natural (saco 25kg)';
  Result[2].Familia := 'MP';
  Result[2].UnidadMedida := 'kg';
  Result[2].Fabricable := False;
  Result[2].Almacen := 'MP';
  Result[2].StockActual := 4200;
  Result[2].Reservado := 0;
  Result[2].StockMinimo := 2500;
  Result[2].Lote := 1000;
  Result[2].LeadTimeDias := 10;
  Result[2].PrecioCompra := 1.35;
  Result[2].PrecioVenta := 0;
  Result[2].NumVentas := 4;          // "ventas" = consumo por produccion
  Result[2].VentaBase := 900;
  Result[2].PrimerVentaDia := 3;
  Result[2].PasoVentaDias := 5;
  Result[2].CompraUnid := 5000;
  Result[2].CompraDia := 11;
  Result[2].OFUnid := 0;
  Result[2].OFDia := 0;
  Result[2].Cliente := 'Consumo interno';
  Result[2].Proveedor := 'Polimeros Ibericos S.A.';

  // 4) Articulo CRITICO ya en negativo de disponible: stock por debajo del
  //    minimo hoy mismo, ruptura inmediata -> recomendacion muy urgente.
  Result[3].Codigo := 'PA-BRIDA-125';
  Result[3].Descripcion := 'Brida nylon 12.5mm (bolsa 100)';
  Result[3].Familia := 'PA';
  Result[3].UnidadMedida := 'bol';
  Result[3].Fabricable := True;
  Result[3].Almacen := 'GEN';
  Result[3].StockActual := 180;
  Result[3].Reservado := 90;
  Result[3].StockMinimo := 250;      // ya bajo minimo hoy
  Result[3].Lote := 300;
  Result[3].LeadTimeDias := 4;
  Result[3].PrecioCompra := 0;
  Result[3].PrecioVenta := 3.10;
  Result[3].NumVentas := 4;
  Result[3].VentaBase := 140;
  Result[3].PrimerVentaDia := 1;
  Result[3].PasoVentaDias := 3;
  Result[3].CompraUnid := 0;
  Result[3].CompraDia := 0;
  Result[3].OFUnid := 300;
  Result[3].OFDia := 15;
  Result[3].Cliente := 'Ferreteria Segre S.L.';
  Result[3].Proveedor := '';
end;

// Localiza la definicion de un codigo (o la primera si no se encuentra).
function DemoDefDe(const ACodigo: string): TDemoArtDef;
var
  Defs: TArray<TDemoArtDef>;
  I: Integer;
begin
  Defs := DemoDefs;
  for I := 0 to High(Defs) do
    if SameText(Defs[I].Codigo, ACodigo) then
      Exit(Defs[I]);
  Result := Defs[0];
end;

function DemoArticuloCodigos: TArray<string>;
var
  Defs: TArray<TDemoArtDef>;
  I: Integer;
begin
  Defs := DemoDefs;
  SetLength(Result, Length(Defs));
  for I := 0 to High(Defs) do
    Result[I] := Defs[I].Codigo;
end;

function DemoAlmacenes: TArray<TAlmacenErp>;
begin
  SetLength(Result, 3);
  Result[0].Codigo := 'GEN'; Result[0].Nombre := 'Almac'#233'n general';
  Result[1].Codigo := 'MP';  Result[1].Nombre := 'Materias primas';
  Result[2].Codigo := 'EXP'; Result[2].Nombre := 'Expediciones';
end;

function DemoArticulo(const ACodigo: string): TArticuloErp;
var
  D: TDemoArtDef;
begin
  D := DemoDefDe(ACodigo);
  Result := Default(TArticuloErp);
  Result.Codigo := D.Codigo;
  Result.Descripcion := D.Descripcion;
  Result.TipoArticulo := D.Familia;
  Result.CodigoFamilia := D.Familia;
  Result.UnidadMedida := D.UnidadMedida;
  Result.StockMinimo := D.StockMinimo;
  Result.StockMaximo := D.StockMinimo * 4;
  Result.PrecioCompra := D.PrecioCompra;
  Result.PrecioVenta := D.PrecioVenta;
  Result.CosteFabricacionUnitario := D.PrecioVenta * 0.55;
  Result.Activo := True;
  Result.TieneFormula := D.Fabricable;
  // Parametros MRP de "Sage": punto de pedido, lote, lead time, seguridad.
  Result.PuntoPedido := D.StockMinimo * 1.2;
  if D.Fabricable then
    Result.LoteFabricacion := D.Lote
  else
    Result.LotePedido := D.Lote;
  Result.UsarStockSeguridad := True;
  Result.PctStockSeguridad := 15;
  Result.TiempoMedioReposicion := D.LeadTimeDias;
  Result.CodigoProveedor := D.Proveedor;
end;

function DemoStockDisponible(const ACodigo: string): TArray<TStockDisponibleErp>;
var
  D: TDemoArtDef;
begin
  D := DemoDefDe(ACodigo);
  SetLength(Result, 1);
  Result[0] := Default(TStockDisponibleErp);
  Result[0].CodigoArticulo := D.Codigo;
  Result[0].CodigoAlmacen := D.Almacen;
  Result[0].UnidadSaldo := D.StockActual;
  Result[0].StockReservado := D.Reservado;
  Result[0].Disponible := D.StockActual - D.Reservado;
end;

function DemoEntradasCompra(const ACodigo: string;
  AHoy: TDateTime): TArray<TEntradaFuturaErp>;
var
  D: TDemoArtDef;
begin
  D := DemoDefDe(ACodigo);
  if D.CompraUnid <= 0 then Exit(nil);
  SetLength(Result, 1);
  Result[0] := Default(TEntradaFuturaErp);
  Result[0].EjercicioPedido := YearOf(AHoy);
  Result[0].SeriePedido := 'C';
  Result[0].NumeroPedido := 4210;
  Result[0].CodigoArticulo := D.Codigo;
  Result[0].DescripcionArticulo := D.Descripcion;
  Result[0].CodigoAlmacen := D.Almacen;
  Result[0].CodigoProveedor := D.Proveedor;
  Result[0].RazonSocialProveedor := D.Proveedor;
  Result[0].UnidadesPedidas := D.CompraUnid;
  Result[0].UnidadesRecibidas := 0;
  Result[0].UnidadesPendientes := D.CompraUnid;
  Result[0].Precio := D.PrecioCompra;
  Result[0].ImporteNetoPendiente := D.CompraUnid * D.PrecioCompra;
  Result[0].FechaPedido := IncDay(AHoy, -3);
  Result[0].FechaNecesaria := IncDay(AHoy, D.CompraDia);
  Result[0].FechaRecepcion := IncDay(AHoy, D.CompraDia);
  Result[0].Estado := 1;
end;

function DemoSalidasVenta(const ACodigo: string;
  AHoy: TDateTime): TArray<TSalidaFuturaVentaErp>;
var
  D: TDemoArtDef;
  I: Integer;
  Uds: Double;
begin
  D := DemoDefDe(ACodigo);
  if D.NumVentas <= 0 then Exit(nil);
  SetLength(Result, D.NumVentas);
  for I := 0 to D.NumVentas - 1 do
  begin
    // Las unidades crecen suavemente pedido a pedido (determinista).
    Uds := D.VentaBase * (1 + 0.10 * I);
    Result[I] := Default(TSalidaFuturaVentaErp);
    Result[I].EjercicioPedido := YearOf(AHoy);
    Result[I].SeriePedido := 'V';
    Result[I].NumeroPedido := 9800 + I;
    Result[I].Orden := 1;
    Result[I].CodigoArticulo := D.Codigo;
    Result[I].DescripcionArticulo := D.Descripcion;
    Result[I].CodigoAlmacen := D.Almacen;
    Result[I].CodigoCliente := 'CLI001';
    Result[I].RazonSocialCliente := D.Cliente;
    Result[I].UnidadesPedidas := Uds;
    Result[I].UnidadesServidas := 0;
    Result[I].UnidadesPendientes := Uds;
    Result[I].Precio := D.PrecioVenta;
    Result[I].FechaPedido := IncDay(AHoy, -2);
    Result[I].FechaNecesaria := IncDay(AHoy, D.PrimerVentaDia + I * D.PasoVentaDias);
    Result[I].FechaServicio := Result[I].FechaNecesaria;
    Result[I].Estado := 1;
  end;
end;

function DemoMovimientosOF(const ACodigo: string;
  AHoy: TDateTime): TArray<TMovOFErp>;
var
  D: TDemoArtDef;
begin
  D := DemoDefDe(ACodigo);
  if D.OFUnid <= 0 then Exit(nil);
  SetLength(Result, 1);
  Result[0] := Default(TMovOFErp);
  Result[0].EjercicioFabricacion := YearOf(AHoy);
  Result[0].SerieFabricacion := 'F';
  Result[0].NumeroFabricacion := 3350;
  Result[0].EsProduccion := True;    // produce el articulo (+ stock)
  Result[0].CodigoArticulo := D.Codigo;
  Result[0].DescripcionArticulo := D.Descripcion;
  Result[0].CodigoAlmacen := D.Almacen;
  Result[0].Unidades := D.OFUnid;
  Result[0].Fecha := IncDay(AHoy, D.OFDia);
  Result[0].EstadoOF := 0;           // en curso
end;

// ---------------------------------------------------------------------------
// Tabs secundarios
// ---------------------------------------------------------------------------

// Seed determinista a partir del codigo (para variar sin parpadear).
function CodSeed(const ACodigo: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(ACodigo) do
    Result := (Result * 31 + Ord(ACodigo[I])) and $7FFFFFFF;
end;

function DemoPartidas(const ACodigo: string;
  AHoy: TDateTime): TArray<TStockArticuloErp>;
const
  ALMS: array[0..2] of string = ('GEN', 'MP', 'EXP');
var
  D: TDemoArtDef;
  NLotes, I, Seed: Integer;
  Restante, Uds, Peso, SumaPesos, Precio: Double;
  Pesos: TArray<Double>;
begin
  D := DemoDefDe(ACodigo);
  Seed := CodSeed(ACodigo);
  Precio := IfThen(D.PrecioCompra > 0, D.PrecioCompra, D.PrecioVenta * 0.55);
  // Repartimos el saldo fisico en 5-6 partidas/lotes (distintos almacenes,
  // fechas y caducidades) para que el tab se vea bien lleno.
  NLotes := 5 + (Seed mod 2);   // 5 o 6
  SetLength(Result, NLotes);
  // Pesos decrecientes normalizados: el reparto siempre suma StockActual y
  // ningun lote es negativo.
  SetLength(Pesos, NLotes);
  SumaPesos := 0;
  for I := 0 to NLotes - 1 do
  begin
    Pesos[I] := NLotes - I + ((Seed + I) mod 3);
    SumaPesos := SumaPesos + Pesos[I];
  end;
  Restante := D.StockActual;
  for I := 0 to NLotes - 1 do
  begin
    if I = NLotes - 1 then
      Uds := Restante
    else
      Uds := Round(D.StockActual * Pesos[I] / SumaPesos);
    if Uds < 0 then Uds := 0;
    Restante := Restante - Uds;

    Result[I] := Default(TStockArticuloErp);
    Result[I].Ejercicio := YearOf(AHoy);
    Result[I].Periodo := 99;
    Result[I].CodigoArticulo := D.Codigo;
    // Reparte entre 2 almacenes (el principal y otro) para dar variedad.
    if I mod 3 = 1 then
      Result[I].CodigoAlmacen := ALMS[(Seed + I) mod Length(ALMS)]
    else
      Result[I].CodigoAlmacen := D.Almacen;
    Result[I].Partida := Format('L%d%.4d', [YearOf(AHoy) mod 100, 1200 + I * 37 + (Seed mod 50)]);
    Result[I].Ubicacion := Format('%s-%.2d-%s', [Result[I].CodigoAlmacen, 3 + I, Chr(Ord('A') + (I mod 6))]);
    Result[I].UnidadSaldo := Uds;
    Result[I].PrecioMedio := Precio * (0.97 + 0.02 * I);
    Result[I].ImporteSaldo := Uds * Result[I].PrecioMedio;
    Result[I].FechaUltimaEntrada := IncDay(AHoy, -(15 + I * 22));
    Result[I].FechaUltimaSalida := IncDay(AHoy, -(3 + I * 4));
    // El primer lote caduca pronto (12 dias) -> fila resaltada; los otros lejos.
    if I = 0 then
      Result[I].FechaCaducidad := IncDay(AHoy, 12)
    else
      Result[I].FechaCaducidad := IncDay(AHoy, 90 + I * 70);
  end;
end;

function DemoHistoricoMensual(const ACodigo: string; AMeses: Integer;
  AHoy: TDateTime): TArray<THistoricoMesErp>;
var
  D: TDemoArtDef;
  I, Idx: Integer;
  F: TDateTime;
  Base, EntFactor, SalFactor: Double;
  Precio: Double;
begin
  D := DemoDefDe(ACodigo);
  if AMeses <= 0 then AMeses := 12;
  SetLength(Result, AMeses);
  Base := D.VentaBase * D.NumVentas;   // volumen mensual de referencia
  Precio := IfThen(D.PrecioCompra > 0, D.PrecioCompra, D.PrecioVenta * 0.55);

  // Del mes mas antiguo al actual. Ondulacion determinista (senos) + estacional.
  for I := 0 to AMeses - 1 do
  begin
    Idx := AMeses - 1 - I;             // 0 = mes actual
    F := IncMonth(AHoy, -Idx);
    EntFactor := 0.85 + 0.30 * Abs(Sin(I * 0.7 + 1.0));
    SalFactor := 0.80 + 0.35 * Abs(Sin(I * 0.9 + 0.3));
    Result[I] := Default(THistoricoMesErp);
    Result[I].Ejercicio := YearOf(F);
    Result[I].Periodo := MonthOf(F);
    Result[I].UnidadesEntrada := Round(Base * EntFactor);
    Result[I].UnidadesSalida := Round(Base * SalFactor);
    Result[I].CosteEntrada := Result[I].UnidadesEntrada * Precio;
    Result[I].CosteSalida := Result[I].UnidadesSalida * Precio;
  end;
end;

function DemoDondeSeUsa(const ACodigo: string): TArray<TDondeSeUsaErp>;
const
  // Catalogo de posibles articulos "padre" que consumen el consultado.
  PADRES: array[0..7] of array[0..2] of string = (
    ('PA-CAJA-2040',  'Caja plegable 200x400 negra',      'PA'),
    ('SE-TAPA-M8',    'Tapa inyectada M8 gris RAL7035',   'SE'),
    ('PA-BRIDA-125',  'Brida nylon 12.5mm (bolsa 100)',   'PA'),
    ('PA-CONJ-500',   'Conjunto montado 500',             'PA'),
    ('SE-BASE-A3',    'Base inyectada A3 antracita',      'SE'),
    ('PA-KIT-MONTA',  'Kit de montaje universal',         'PA'),
    ('PA-EMBAL-30',   'Embalaje expositor 30u',           'PA'),
    ('SE-CLIP-R2',    'Clip retencion R2 reforzado',      'SE'));
  OPERS: array[0..3] of string = ('Inyecci'#243'n', 'Montaje', 'Ensamblado', 'Acabado');
var
  D: TDemoArtDef;
  Seed, N, I, PIdx: Integer;
begin
  D := DemoDefDe(ACodigo);
  // Solo MP/SE se consumen como componentes en formulas de otros articulos.
  // Un producto acabado (PA) no suele ser componente -> tab vacio (coherente).
  if SameText(D.Familia, 'PA') then Exit(nil);
  Seed := CodSeed(ACodigo);
  // Aparece usado en varias formulas (5-7 padres) para llenar el tab.
  N := 5 + (Seed mod 3);   // 5, 6 o 7
  SetLength(Result, N);
  for I := 0 to N - 1 do
  begin
    PIdx := (Seed + I * 3) mod Length(PADRES);
    if SameText(PADRES[PIdx][0], D.Codigo) then
      PIdx := (PIdx + 1) mod Length(PADRES);
    Result[I] := Default(TDondeSeUsaErp);
    Result[I].CodigoArticuloPadre := PADRES[PIdx][0];
    Result[I].DescripcionArticuloPadre := PADRES[PIdx][1];
    Result[I].TipoArticuloPadre := PADRES[PIdx][2];
    Result[I].VersionFormula := 1 + (I mod 2);
    Result[I].Orden := 10 + I * 10;
    // Cantidad segun unidad: MP en kg (pequena), resto en ud.
    if SameText(D.Familia, 'MP') then
      Result[I].UnidadesNecesarias := 0.020 + ((Seed + I) mod 40) / 100
    else
      Result[I].UnidadesNecesarias := 1 + ((Seed + I) mod 4);
    Result[I].UnidadMedida := D.UnidadMedida;
    Result[I].Mermas := 1 + ((Seed + I) mod 5);
    Result[I].Operacion := OPERS[(Seed + I) mod Length(OPERS)];
  end;
end;

function DemoOFsActivas(const ACodigo: string;
  AHoy: TDateTime): TArray<TOFActivaArticuloErp>;
var
  D: TDemoArtDef;
  I, N: Integer;
  Fabricadas: Double;

  function EstadoTxt(AEstado: Integer): string;
  begin
    case AEstado of
      0: Result := 'Alta';
      1: Result := 'Lanzada';
      2: Result := 'En curso';
    else Result := 'Pendiente';
    end;
  end;

var
  Seed: Integer;
  UdsBase, AFab, Prog: Double;
  Prioridades: array[0..2] of string;
begin
  D := DemoDefDe(ACodigo);
  if not D.Fabricable then Exit(nil);   // solo articulos con formula
  Prioridades[0] := 'Alta'; Prioridades[1] := 'Normal'; Prioridades[2] := 'Baja';
  Seed := CodSeed(ACodigo);
  UdsBase := D.OFUnid;
  if UdsBase <= 0 then UdsBase := D.Lote;
  N := 4 + (Seed mod 2);   // 4 o 5 OFs
  SetLength(Result, N);
  for I := 0 to N - 1 do
  begin
    AFab := UdsBase * (0.8 + 0.35 * I);
    Result[I] := Default(TOFActivaArticuloErp);
    Result[I].EjercicioFabricacion := YearOf(AHoy);
    Result[I].SerieFabricacion := 'F';
    Result[I].NumeroFabricacion := 3350 + I + (Seed mod 40);
    Result[I].FechaCreacion := IncDay(AHoy, -(20 - I * 4));
    Result[I].FechaInicioPrevista := IncDay(AHoy, -3 + I * 5);
    Result[I].FechaFinalPrevista := IncDay(AHoy, D.OFDia + I * 7);
    Result[I].FechaEntrega := IncDay(AHoy, D.OFDia + 3 + I * 7);
    Result[I].UnidadesAFabricar := AFab;
    // Progreso decreciente: las primeras van mas avanzadas.
    Prog := Max(0, 0.75 - 0.20 * I);
    Fabricadas := Round(AFab * Prog);
    Result[I].UnidadesFabricadas := Fabricadas;
    Result[I].PorcentajeProgreso := Fabricadas / AFab * 100;
    // Estados variados: en curso las avanzadas, lanzadas/alta las nuevas.
    if I = 0 then Result[I].EstadoOF := 2
    else if I <= 2 then Result[I].EstadoOF := 1
    else Result[I].EstadoOF := 0;
    Result[I].EstadoDescripcion := EstadoTxt(Result[I].EstadoOF);
    Result[I].Prioridad := Prioridades[I mod 3];
    Result[I].CodigoProyecto := '';
  end;
end;

function DemoProveedores(const ACodigo: string;
  AHoy: TDateTime): TArray<TProveedorArticuloErp>;
const
  PROV: array[0..6] of array[0..1] of string = (
    ('PR0007', 'Polimeros Ibericos S.A.'),
    ('PR0021', 'Distri Qu'#237'micos del Ebro S.L.'),
    ('PR0034', 'Suministros Industriales Segre'),
    ('PR0048', 'Comercial Plasticos Nordeste'),
    ('PR0055', 'Aditivos y Masterbatch S.L.'),
    ('PR0063', 'Metalurgia Ponent S.A.'),
    ('PR0072', 'Embalajes T'#233'cnicos Lleida'));
var
  D: TDemoArtDef;
  Seed, N, I, PIdx: Integer;
  PrecioBase: Double;
begin
  D := DemoDefDe(ACodigo);
  Seed := CodSeed(ACodigo);
  // Todos los articulos tienen proveedores (un fabricado tambien compra sus
  // componentes/consumibles). 4-6 filas para que el tab se vea lleno.
  PrecioBase := D.PrecioCompra;
  if PrecioBase <= 0 then PrecioBase := D.PrecioVenta * 0.45;
  N := 4 + (Seed mod 3);   // 4, 5 o 6
  SetLength(Result, N);
  for I := 0 to N - 1 do
  begin
    PIdx := (Seed + I * 2) mod Length(PROV);
    Result[I] := Default(TProveedorArticuloErp);
    Result[I].CodigoProveedor := PROV[PIdx][0];
    Result[I].RazonSocialProveedor := PROV[PIdx][1];
    Result[I].PrecioUltimaCompra := PrecioBase * (0.95 + 0.03 * I);
    Result[I].PrecioMedioCompra := PrecioBase * (0.93 + 0.03 * I);
    Result[I].LeadTimeMedio := D.LeadTimeDias + I * 2;
    Result[I].UnidadesCompradasTotal := 8000 + ((Seed + I * 7) mod 40) * 1000;
    Result[I].NumeroPedidosTotal := 3 + ((Seed + I) mod 15);
    Result[I].FechaUltimaCompra := IncDay(Trunc(AHoy), -(9 + I * 17));
  end;
end;

function DemoClientes(const ACodigo: string;
  AHoy: TDateTime): TArray<TClienteArticuloErp>;
const
  CLI: array[0..8] of array[0..1] of string = (
    ('CLI001', 'Distribuciones Valls S.L.'),
    ('CLI002', 'Mecaniza Ponent S.A.'),
    ('CLI003', 'Ferreteria Segre S.L.'),
    ('CLI004', 'Industrias del Pirineo S.A.'),
    ('CLI005', 'Comercial Garrigues S.L.'),
    ('CLI006', 'Talleres Urgell Hnos.'),
    ('CLI007', 'Montajes Noguera S.L.'),
    ('CLI008', 'Suministros Balaguer S.A.'),
    ('CLI009', 'Grupo Industrial Ebro'));
var
  D: TDemoArtDef;
  Seed, N, I, CIdx: Integer;
  PrecioBase: Double;
begin
  D := DemoDefDe(ACodigo);
  // Solo articulos que se venden (PA/SE). Las MP (compra) no tienen clientes.
  if SameText(D.Familia, 'MP') then Exit(nil);
  Seed := CodSeed(ACodigo);
  PrecioBase := D.PrecioVenta;
  if PrecioBase <= 0 then PrecioBase := D.PrecioCompra * 1.4;
  // Cartera de clientes amplia (6-8) para llenar el tab.
  N := 6 + (Seed mod 3);   // 6, 7 u 8
  SetLength(Result, N);
  for I := 0 to N - 1 do
  begin
    CIdx := (Seed + I) mod Length(CLI);
    Result[I] := Default(TClienteArticuloErp);
    Result[I].CodigoCliente := CLI[CIdx][0];
    Result[I].RazonSocialCliente := CLI[CIdx][1];
    Result[I].UnidadesVendidasTotal := Round(D.VentaBase * (N - I) * (2 + (Seed mod 3)));
    Result[I].PrecioMedio := PrecioBase * (1.02 - 0.015 * I);
    Result[I].ImporteVendidoTotal :=
      Result[I].UnidadesVendidasTotal * Result[I].PrecioMedio;
    Result[I].NumeroPedidosTotal := 4 + ((Seed + I * 3) mod 18);
    Result[I].FechaUltimaVenta := IncDay(Trunc(AHoy), -(4 + I * 9));
  end;
end;

function DemoDiasCobertura(const ACodigo: string): Double;
var
  D: TDemoArtDef;
  ConsumoDiario: Double;
begin
  D := DemoDefDe(ACodigo);
  // Consumo diario aproximado = demanda total del escenario / ~30 dias.
  ConsumoDiario := (D.VentaBase * D.NumVentas) / 30;
  if ConsumoDiario <= 0 then Exit(60);
  Result := (D.StockActual - D.Reservado) / ConsumoDiario;
  if Result < 0 then Result := 0;
end;

function DemoCategoriaABC(const ACodigo: string): string;
var
  D: TDemoArtDef;
  Valor: Double;
begin
  D := DemoDefDe(ACodigo);
  // Valor de rotacion = demanda * precio. A = alto valor, B = medio, C = bajo.
  Valor := D.VentaBase * D.NumVentas *
    IfThen(D.PrecioVenta > 0, D.PrecioVenta, D.PrecioCompra);
  if Valor >= 8000 then Result := 'A'
  else if Valor >= 2500 then Result := 'B'
  else Result := 'C';
end;

initialization
finalization
  GDemoMode.Free;
end.
