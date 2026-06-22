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
    function AsegurarRuta: string;
  public
    constructor Create;
    destructor Destroy; override;
    // Marca de inicio de una sesion de planificacion (separador + cabecera).
    procedure Inicio(const ATitulo: string);
    procedure Fin;
    // Escribe una linea con timestamp. Acepta formato estilo Format().
    procedure Linea(const AMsg: string); overload;
    procedure Linea(const AFmt: string; const AArgs: array of const); overload;
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
  FPath := AsegurarRuta;
end;

destructor TPlanLog.Destroy;
begin
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

procedure TPlanLog.Linea(const AMsg: string);
var
  Linea: string;
begin
  FLock.Enter;
  try
    Linea := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + '  ' + AMsg;
    try
      TFile.AppendAllText(FPath, Linea + sLineBreak, TEncoding.UTF8);
    except
      // Nunca interrumpir la planificacion por un fallo de log.
    end;
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
  Linea('');
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
