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
  System.Classes, System.Generics.Collections, System.Math;

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

initialization
finalization
  GDemoMode.Free;
end.
