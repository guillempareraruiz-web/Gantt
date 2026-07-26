unit uUtillajeTypes;

// Tipos del subsistema de Utillajes (V072/V073).
//
// El utillaje es un RECURSO SECUNDARIO al estilo APS: no se planifica "sobre"
// el, pero una operacion lo REQUIERE y el utillaje tiene capacidad propia
// (Cantidad = ejemplares intercambiables) y disponibilidad propia.
//
// Entidad 100% Planner: Sage200 no modela utillajes, por lo que no hay
// tipos ni campos de sincronizacion ERP.

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  // Persistido como ordinal (TINYINT). No reordenar sin migracion.
  TEstadoUtillaje = (
    euDisponible,
    euMontado,
    euReservado,
    euMantenimiento,
    euAveriado,
    euBloqueado,
    euBaja
  );

  // Unidad en la que se cuenta la vida util. Ordinal (TINYINT).
  TUnidadVida = (
    uvCiclos,
    uvHoras,
    uvGolpes,
    uvPiezas
  );

  TUtillaje = record
    Id: Integer;
    Codigo: string;
    Descripcion: string;
    Tipo: string;

    // Identificacion
    Fabricante: string;
    NumeroSerie: string;
    AnyoFabricacion: Integer;      // 0 = sin informar

    // Ubicacion y estado
    Ubicacion: string;
    CentroActualId: Integer;       // 0 = sin centro
    Estado: TEstadoUtillaje;

    // Capacidad: ejemplares intercambiables.
    // 1 = uso exclusivo; N = hasta N operaciones simultaneas.
    Cantidad: Integer;

    // Tiempos de cambio (minutos)
    TiempoMontaje: Double;
    TiempoDesmontaje: Double;
    TiempoAjuste: Double;

    // Vida util y mantenimiento
    UnidadVida: TUnidadVida;
    ContadorActual: Int64;
    VidaUtilTotal: Int64;          // 0 = sin control de vida util
    FechaProxMantenimiento: TDateTime;
    FechaProxMantNull: Boolean;    // True = NULL en BD (TDateTime no es nullable)

    // Planificacion
    Disponible: Boolean;                 // flag manual del usuario (V034)
    DisponiblePlanificacion: Boolean;    // flag que lee el motor (V072)

    Observaciones: string;
    Activo: Boolean;
    Orden: Integer;
  end;

  TUtillajeArray = TArray<TUtillaje>;

  // --- Relaciones (V073) ---

  TUtillajeCentro = record
    UtillajeId: Integer;
    CenterId: Integer;
    Preferente: Boolean;
    TiempoMontajeEspecifico: Double;   // 0 = usar el tiempo general
  end;

  TUtillajeArticulo = record
    UtillajeId: Integer;
    CodigoArticulo: string;
    Obligatorio: Boolean;
    Observaciones: string;
  end;

  TUtillajeOperacion = record
    UtillajeId: Integer;
    Operacion: string;
    Obligatorio: Boolean;
    Observaciones: string;
  end;

  // Requisito de utillaje de un nodo planificado. Lo produce
  // uUtillajesRepo.LoadRequisitosPorNodo y lo consume el detector de la
  // alerta R02 (uGanttAlertas), que lo reexporta como TUtillajeReq.
  TUtillajeRequisito = record
    UtillajeId: Integer;
    Codigo: string;
    Cantidad: Integer;    // ejemplares disponibles; 1 = uso exclusivo
  end;

  // Requisito ya ligado a su nodo. Es la forma plana que devuelve el repo:
  // una fila por (nodo, utillaje). El caller la indexa como prefiera.
  TUtillajeRequisitoNodo = record
    NodeId: Integer;
    Req: TUtillajeRequisito;
  end;

  // Regla de requisito SIN nodo: "la operacion X (o el articulo Y) necesita
  // este utillaje". Es la forma que hace falta ANTES de planificar, cuando los
  // nodos todavia no existen y por tanto no hay NodeId al que atarse.
  // Clave: Operacion si Origen='OPERACION', CodigoArticulo si Origen='ARTICULO'.
  TUtillajeRegla = record
    Clave: string;          // codigo de operacion o de articulo
    PorOperacion: Boolean;  // True = la clave es una operacion; False = articulo
    Req: TUtillajeRequisito;
  end;

  // Situacion CALCULADA de un utillaje: que dice el PLAN, no el maestro.
  //
  // Ojo, no confundir con TEstadoUtillaje:
  //   - Estado  = lo que el usuario declara en la ficha (Mantenimiento...).
  //   - Situacion = lo que se deduce de los nodos planificados ahora mismo.
  // Conviven a proposito: si Estado=Mantenimiento pero hay nodos usandolo,
  // esa discrepancia es justo lo que interesa ver.
  TSituacionUtillaje = (
    suLibre,        // sin nodos planificados que lo requieran
    suEnUso,        // en uso ahora mismo
    suReservado     // no esta en uso ahora, pero tiene trabajos por delante
  );

  TUtillajeSituacion = record
    UtillajeId: Integer;
    Situacion: TSituacionUtillaje;
    NodosAhora: Integer;        // nodos que lo usan en este instante
    NodosFuturos: Integer;      // nodos planificados por delante
    LibreDesde: TDateTime;      // fin del ultimo nodo en curso; 0 = libre ya
    OFsAfectadas: TArray<string>;  // OFs que dependen de el (formato NNN/SER)
  end;

  // ---------------------------------------------------------------------------
  // Ocupacion de utillajes durante una planificacion (restriccion dura).
  //
  // OJO, dos diferencias de fondo con la ocupacion de CENTROS del scheduler:
  //
  //  1. El centro tiene LANES (N carriles con identidad; PickLane elige uno).
  //     El utillaje tiene CANTIDAD (N copias intercambiables, sin identidad):
  //     no hay que elegir cual, solo contar cuantos se solapan.
  //  2. La ocupacion de un centro es independiente de la de otro. La de un
  //     utillaje es CROSS-CENTRO: la misma mordaza puede pedirse desde dos
  //     centros distintos. Por eso esto vive fuera del diccionario de cursores
  //     del scheduler, con ambito de "toda la pasada".
  //
  // Sin BD: se precarga y se consulta en memoria, porque el optimizador corre
  // RunAutoScheduling en varios hilos.
  // ---------------------------------------------------------------------------
  TUtillajeSlot = record
    StartDT: TDateTime;
    EndDT: TDateTime;
  end;

  TUtillajeOccupancy = class
  private
    FSlots: TObjectDictionary<Integer, TList<TUtillajeSlot>>;  // UtillajeId -> intervalos
    FCantidad: TDictionary<Integer, Integer>;                  // UtillajeId -> ejemplares
  public
    constructor Create;
    destructor Destroy; override;

    // Copia independiente: mismos datos, cero memoria compartida.
    //
    // Existe porque esta clase TIENE ESTADO (se va ocupando conforme avanza la
    // pasada) y NO es thread-safe. El optimizador (uPlanOptimizer) lanza varias
    // cadenas SA en paralelo; sin una copia por hilo todas escribirian en el
    // mismo objeto y el resultado seria basura. Antes se resolvia poniendo la
    // restriccion a nil en el optimizador, es decir: el plan optimizado podia
    // violar utillajes. Con esto ya no hace falta.
    //
    // El llamante es el duenyo del objeto devuelto.
    function Clone: TUtillajeOccupancy;

    // Declara la capacidad de un utillaje. Si no se declara, se asume 1.
    procedure SetCantidad(AUtillajeId, ACantidad: Integer);

    // True si el utillaje admite un uso mas en [AStart, AEnd): los solapes
    // existentes son < Cantidad. Tocarse en el limite NO es solape.
    function Cabe(AUtillajeId: Integer; const AStart, AEnd: TDateTime): Boolean;

    // True si TODOS los utillajes de la lista caben a la vez en ese hueco.
    function CabenTodos(const AReqs: TArray<TUtillajeRequisito>;
      const AStart, AEnd: TDateTime): Boolean;

    // Registra el uso (llamar solo tras aceptar la colocacion).
    procedure Ocupar(AUtillajeId: Integer; const AStart, AEnd: TDateTime);
    procedure OcuparTodos(const AReqs: TArray<TUtillajeRequisito>;
      const AStart, AEnd: TDateTime);

    // Primer instante >= AStart en el que el utillaje se libera (fin del slot
    // solapado mas temprano). 0 = ya cabe ahora.
    function ProximoHueco(AUtillajeId: Integer;
      const AStart, AEnd: TDateTime): TDateTime;
    function ProximoHuecoTodos(const AReqs: TArray<TUtillajeRequisito>;
      const AStart, AEnd: TDateTime): TDateTime;
  end;

// Helpers de conversion (mismo patron que uMoldeTypes)
function SituacionUtillajeToStr(ASit: TSituacionUtillaje): string;
function EstadoUtillajeToStr(AEstado: TEstadoUtillaje): string;
function StrToEstadoUtillaje(const AStr: string): TEstadoUtillaje;
function UnidadVidaToStr(AUnidad: TUnidadVida): string;
function StrToUnidadVida(const AStr: string): TUnidadVida;

// True si el estado impide que el motor cuente con el utillaje.
function EstadoBloqueaPlanificacion(AEstado: TEstadoUtillaje): Boolean;

// Resuelve, en memoria, que utillajes exige una (operacion, articulo) segun las
// reglas del maestro. Sin BD: se llama dentro del bucle de planificacion, que
// corre en los hilos del optimizador.
// Un utillaje que salga por las dos vias (operacion Y articulo) se devuelve
// UNA sola vez.
function ResolverUtillajes(const AReglas: TArray<TUtillajeRegla>;
  const AOperacion, ACodigoArticulo: string): TArray<TUtillajeRequisito>;

// Porcentaje de vida consumida (0..100+). 0 si no hay control de vida util.
function PorcentajeVidaConsumida(const AUtil: TUtillaje): Double;

implementation

{ TUtillajeOccupancy }

constructor TUtillajeOccupancy.Create;
begin
  inherited Create;
  FSlots := TObjectDictionary<Integer, TList<TUtillajeSlot>>.Create([doOwnsValues]);
  FCantidad := TDictionary<Integer, Integer>.Create;
end;

destructor TUtillajeOccupancy.Destroy;
begin
  FCantidad.Free;
  FSlots.Free;
  inherited;
end;

function TUtillajeOccupancy.Clone: TUtillajeOccupancy;
var
  Par: TPair<Integer, TList<TUtillajeSlot>>;
  ParCant: TPair<Integer, Integer>;
  Lista: TList<TUtillajeSlot>;
  I: Integer;
begin
  Result := TUtillajeOccupancy.Create;

  // Capacidades: enteros, copia directa.
  for ParCant in FCantidad do
    Result.FCantidad.AddOrSetValue(ParCant.Key, ParCant.Value);

  // Slots: hay que crear listas NUEVAS. Copiar la referencia dejaria a las dos
  // instancias escribiendo en la misma lista, que es justo lo que se quiere
  // evitar. TUtillajeSlot es un record (tipo valor), asi que los elementos se
  // copian solos al anadirlos.
  for Par in FSlots do
  begin
    Lista := TList<TUtillajeSlot>.Create;
    for I := 0 to Par.Value.Count - 1 do
      Lista.Add(Par.Value[I]);
    Result.FSlots.AddOrSetValue(Par.Key, Lista);
  end;
end;

procedure TUtillajeOccupancy.SetCantidad(AUtillajeId, ACantidad: Integer);
begin
  if ACantidad < 1 then ACantidad := 1;
  FCantidad.AddOrSetValue(AUtillajeId, ACantidad);
end;

function TUtillajeOccupancy.Cabe(AUtillajeId: Integer;
  const AStart, AEnd: TDateTime): Boolean;
var
  L: TList<TUtillajeSlot>;
  I, Cnt, Cap: Integer;
begin
  if not FCantidad.TryGetValue(AUtillajeId, Cap) then Cap := 1;
  if not FSlots.TryGetValue(AUtillajeId, L) then Exit(True);

  Cnt := 0;
  for I := 0 to L.Count - 1 do
    // Solape estricto: tocarse en el limite (fin = inicio) no es solape.
    if (L[I].StartDT < AEnd) and (L[I].EndDT > AStart) then
    begin
      Inc(Cnt);
      if Cnt >= Cap then Exit(False);
    end;
  Result := True;
end;

function TUtillajeOccupancy.CabenTodos(const AReqs: TArray<TUtillajeRequisito>;
  const AStart, AEnd: TDateTime): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(AReqs) do
    if not Cabe(AReqs[I].UtillajeId, AStart, AEnd) then Exit(False);
  Result := True;
end;

procedure TUtillajeOccupancy.Ocupar(AUtillajeId: Integer;
  const AStart, AEnd: TDateTime);
var
  L: TList<TUtillajeSlot>;
  S: TUtillajeSlot;
begin
  if not FSlots.TryGetValue(AUtillajeId, L) then
  begin
    L := TList<TUtillajeSlot>.Create;
    FSlots.Add(AUtillajeId, L);
  end;
  S.StartDT := AStart;
  S.EndDT := AEnd;
  L.Add(S);
end;

procedure TUtillajeOccupancy.OcuparTodos(const AReqs: TArray<TUtillajeRequisito>;
  const AStart, AEnd: TDateTime);
var
  I: Integer;
begin
  for I := 0 to High(AReqs) do
    Ocupar(AReqs[I].UtillajeId, AStart, AEnd);
end;

function TUtillajeOccupancy.ProximoHueco(AUtillajeId: Integer;
  const AStart, AEnd: TDateTime): TDateTime;
var
  L: TList<TUtillajeSlot>;
  I, Cap: Integer;
  Fin: TDateTime;
begin
  // 0 = no hay que esperar.
  Result := 0;
  if Cabe(AUtillajeId, AStart, AEnd) then Exit;
  if not FCantidad.TryGetValue(AUtillajeId, Cap) then Cap := 1;
  if not FSlots.TryGetValue(AUtillajeId, L) then Exit;

  // El primer momento en que PUEDE quedar sitio es cuando acaba alguno de los
  // usos que se solapan. Se devuelve el fin mas temprano: el caller reintenta
  // desde ahi (y volvera a preguntar si aun no cabe, p.ej. con Cantidad > 1).
  Fin := 0;
  for I := 0 to L.Count - 1 do
    if (L[I].StartDT < AEnd) and (L[I].EndDT > AStart) then
      if (Fin = 0) or (L[I].EndDT < Fin) then
        Fin := L[I].EndDT;
  Result := Fin;
end;

function TUtillajeOccupancy.ProximoHuecoTodos(
  const AReqs: TArray<TUtillajeRequisito>;
  const AStart, AEnd: TDateTime): TDateTime;
var
  I: Integer;
  H: TDateTime;
begin
  // El nodo necesita TODOS sus utillajes a la vez: hay que esperar al mas
  // tardio de los primeros huecos.
  Result := 0;
  for I := 0 to High(AReqs) do
  begin
    H := ProximoHueco(AReqs[I].UtillajeId, AStart, AEnd);
    if H > Result then Result := H;
  end;
end;

function SituacionUtillajeToStr(ASit: TSituacionUtillaje): string;
begin
  case ASit of
    suLibre:     Result := 'Libre';
    suEnUso:     Result := 'En uso';
    suReservado: Result := 'Reservado';
  else
    Result := 'Libre';
  end;
end;

function EstadoUtillajeToStr(AEstado: TEstadoUtillaje): string;
begin
  case AEstado of
    euDisponible:    Result := 'Disponible';
    euMontado:       Result := 'Montado';
    euReservado:     Result := 'Reservado';
    euMantenimiento: Result := 'Mantenimiento';
    euAveriado:      Result := 'Averiado';
    euBloqueado:     Result := 'Bloqueado';
    euBaja:          Result := 'Baja';
  else
    Result := 'Desconocido';
  end;
end;

function StrToEstadoUtillaje(const AStr: string): TEstadoUtillaje;
var
  S: string;
begin
  S := LowerCase(Trim(AStr));
  if S = 'disponible' then Result := euDisponible
  else if S = 'montado' then Result := euMontado
  else if S = 'reservado' then Result := euReservado
  else if S = 'mantenimiento' then Result := euMantenimiento
  else if S = 'averiado' then Result := euAveriado
  else if S = 'bloqueado' then Result := euBloqueado
  else if S = 'baja' then Result := euBaja
  else Result := euDisponible;
end;

function UnidadVidaToStr(AUnidad: TUnidadVida): string;
begin
  case AUnidad of
    uvCiclos: Result := 'Ciclos';
    uvHoras:  Result := 'Horas';
    uvGolpes: Result := 'Golpes';
    uvPiezas: Result := 'Piezas';
  else
    Result := 'Ciclos';
  end;
end;

function StrToUnidadVida(const AStr: string): TUnidadVida;
var
  S: string;
begin
  S := LowerCase(Trim(AStr));
  if S = 'ciclos' then Result := uvCiclos
  else if S = 'horas' then Result := uvHoras
  else if S = 'golpes' then Result := uvGolpes
  else if S = 'piezas' then Result := uvPiezas
  else Result := uvCiclos;
end;

function EstadoBloqueaPlanificacion(AEstado: TEstadoUtillaje): Boolean;
begin
  Result := AEstado in [euMantenimiento, euAveriado, euBloqueado, euBaja];
end;

function ResolverUtillajes(const AReglas: TArray<TUtillajeRegla>;
  const AOperacion, ACodigoArticulo: string): TArray<TUtillajeRequisito>;
var
  I, J: Integer;
  Op, Art: string;
  Coincide, YaEsta: Boolean;
begin
  SetLength(Result, 0);
  Op := Trim(AOperacion);
  Art := Trim(ACodigoArticulo);
  if (Op = '') and (Art = '') then Exit;

  for I := 0 to High(AReglas) do
  begin
    if AReglas[I].PorOperacion then
      Coincide := (Op <> '') and SameText(AReglas[I].Clave, Op)
    else
      Coincide := (Art <> '') and SameText(AReglas[I].Clave, Art);
    if not Coincide then Continue;

    // Dedup: el mismo utillaje puede exigirse por operacion Y por articulo.
    YaEsta := False;
    for J := 0 to High(Result) do
      if Result[J].UtillajeId = AReglas[I].Req.UtillajeId then
      begin
        YaEsta := True;
        Break;
      end;
    if YaEsta then Continue;

    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := AReglas[I].Req;
  end;
end;

function PorcentajeVidaConsumida(const AUtil: TUtillaje): Double;
begin
  if AUtil.VidaUtilTotal <= 0 then
    Result := 0
  else
    Result := (AUtil.ContadorActual / AUtil.VidaUtilTotal) * 100;
end;

end.
