unit uPlanLog;
// Logger ligero y dedicado al flujo de PLANIFICACION del Backlog. Escribe, con
// timestamp, cada paso y los valores clave (NumeroOF, SerieOF, NumeroTrabajo,
// fechas...) tanto al LEER del Backlog/vista como al ESCRIBIR el NodeData.
//
// Objetivo: diagnosticar por que algunos campos (NumeroOF, FechaEntrega...) no
// llegan al NodeData. El log es append; se crea junto al .exe en \Logs\.
//
// Uso:
//   PlanLog.Inicio('Planificar 3 OF');
//   PlanLog.Linea('Input OF=%d Serie=%s', [n, s]);
//   PlanLog.Fin;
// Es seguro llamarlo aunque falle la escritura (nunca lanza excepcion al caller).

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.SyncObjs;

type
  TPlanLog = class
  private
    FLock: TCriticalSection;
    FPath: string;
    FBuffer: TStringBuilder;   // acumula lineas; flush explicito o en Fin.
    FBufferLevel: Integer;     // >0 => Linea acumula en memoria (anidable).
    function AsegurarRuta: string;
    procedure EscribirDisco(const ATexto: string);
  public
    constructor Create;
    destructor Destroy; override;
    // Marca de inicio de una sesion de planificacion (separador + cabecera).
    procedure Inicio(const ATitulo: string);
    procedure Fin;
    // Escribe una linea con timestamp. Acepta formato estilo Format().
    procedure Linea(const AMsg: string); overload;
    procedure Linea(const AFmt: string; const AArgs: array of const); overload;
    // Modo buffer: mientras esta activo, las lineas se acumulan en memoria y
    // NO se abre/cierra el fichero por cada una (evita I/O O(n) al loguear
    // muchas filas). BeginBuffer/EndBuffer se pueden anidar; EndBuffer hace
    // flush cuando se cierra el ultimo nivel. Fin tambien hace flush.
    procedure BeginBuffer;
    procedure EndBuffer;
    procedure Flush;
    // Ruta del fichero de log activo (para mostrarla al usuario).
    function RutaLog: string;
  end;

// Singleton global.
function PlanLog: TPlanLog;

implementation

var
  GPlanLog: TPlanLog = nil;

function PlanLog: TPlanLog;
begin
  if GPlanLog = nil then
    GPlanLog := TPlanLog.Create;
  Result := GPlanLog;
end;

constructor TPlanLog.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FBuffer := TStringBuilder.Create;
  FBufferLevel := 0;
  FPath := AsegurarRuta;
end;

destructor TPlanLog.Destroy;
begin
  Flush;
  FBuffer.Free;
  FLock.Free;
  inherited;
end;

function TPlanLog.AsegurarRuta: string;
var
  Dir: string;
begin
  // Carpeta \Logs junto al ejecutable.
  Dir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Logs');
  try
    if not TDirectory.Exists(Dir) then
      TDirectory.CreateDirectory(Dir);
  except
    // Si no se puede crear, caemos al directorio del exe.
    Dir := ExtractFilePath(ParamStr(0));
  end;
  Result := TPath.Combine(Dir, 'planificacion.log');
end;

function TPlanLog.RutaLog: string;
begin
  Result := FPath;
end;

procedure TPlanLog.EscribirDisco(const ATexto: string);
begin
  if ATexto = '' then Exit;
  try
    TFile.AppendAllText(FPath, ATexto, TEncoding.UTF8);
  except
    // Nunca interrumpir la planificacion por un fallo de log.
  end;
end;

procedure TPlanLog.Linea(const AMsg: string);
var
  L: string;
begin
  FLock.Enter;
  try
    L := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + '  ' + AMsg + sLineBreak;
    if FBufferLevel > 0 then
      FBuffer.Append(L)          // acumula en memoria (sin tocar disco)
    else
      EscribirDisco(L);          // modo directo (compatibilidad)
  finally
    FLock.Leave;
  end;
end;

procedure TPlanLog.BeginBuffer;
begin
  FLock.Enter;
  try
    Inc(FBufferLevel);
  finally
    FLock.Leave;
  end;
end;

procedure TPlanLog.EndBuffer;
begin
  FLock.Enter;
  try
    if FBufferLevel > 0 then Dec(FBufferLevel);
    if FBufferLevel = 0 then
    begin
      EscribirDisco(FBuffer.ToString);
      FBuffer.Clear;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TPlanLog.Flush;
begin
  FLock.Enter;
  try
    EscribirDisco(FBuffer.ToString);
    FBuffer.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure TPlanLog.Linea(const AFmt: string; const AArgs: array of const);
begin
  try
    Linea(Format(AFmt, AArgs));
  except
    Linea(AFmt);  // si el Format falla, al menos guardamos el literal
  end;
end;

procedure TPlanLog.Inicio(const ATitulo: string);
begin
  // Cada sesion de planificacion arranca con el log LIMPIO (vacia el fichero y
  // cualquier buffer pendiente), asi cada ejecucion deja datos aislados.
  FLock.Enter;
  try
    FBuffer.Clear;
    try
      TFile.WriteAllText(FPath, '', TEncoding.UTF8);   // trunca el contenido
    except
      // Si no se puede truncar, seguimos: el log se acumulara, no es critico.
    end;
  finally
    FLock.Leave;
  end;

  Linea('========================================================');
  Linea('=== ' + ATitulo);
  Linea('========================================================');
end;

procedure TPlanLog.Fin;
begin
  Linea('=== FIN ===============================================');
end;

initialization

finalization
  FreeAndNil(GPlanLog);

end.
