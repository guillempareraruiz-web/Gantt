unit FS.PlanProd.Types;

{
  Tipos base del Planificador de Producción (versión VCL).

  NOVEDADES respecto de la versión anterior:
  - TOperacionOrden ahora tiene NumOperariosMin y NumOperariosMax
    (cuántos operarios distintos pueden trabajar simultáneamente).
  - TOperario tiene SueldoEurHora y bonificaciones por turno/festivo.
  - TPesosPlanificacion incluye PesoCosteManoObra.
  - El motor calcula coste estimado por asignación.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TNivelCompetencia = 0 .. 3;

  TEstadoOrden = (eoPlanificada, eoLanzada, eoEnCurso, eoPausada, eoFinalizada,
    eoCancelada);

  TEstadoOperario = (esLibre, esOcupado, esAusente, esFueraTurno);

  TTipoTurno = (ttManana, ttTarde, ttNoche, ttPartido, ttCentral);

  TTipoAusencia = (taVacaciones, taBaja, taPermisoRetribuido, taFormacion,
    taOtros);

  // ============================================================
  // OPERACIÓN MAESTRO (catálogo)
  // ============================================================

  TOperacion = record
    CodOperacion: string;
    Descripcion: string;
    DuracionEstandarMin: Integer;
    HabilidadesRequeridas: TDictionary<string, TNivelCompetencia>;
    procedure Init;
    procedure Liberar;
    procedure RequerirHabilidad(const ACodHabilidad: string;
      ANivel: TNivelCompetencia);
  end;

  // ============================================================
  // CENTRO DE TRABAJO
  // ============================================================

  TCentroTrabajo = record
    CodCentro: string;
    Descripcion: string;
    Capacidad: Integer;
    OperacionesPermitidas: TList<string>;
    procedure Init;
    procedure Liberar;
    procedure PermitirOperacion(const ACodOperacion: string);
    function PermiteOperacion(const ACodOperacion: string): Boolean;
  end;

  // ============================================================
  // TURNO Y AUSENCIAS
  // ============================================================

  TTurno = record
    CodTurno: string;
    Tipo: TTipoTurno;
    HoraInicio: Integer;
    HoraFin: Integer;
    DiasSemanaActivos: set of 0 .. 6;
    function EstaActivoEn(const AFechaHora: TDateTime): Boolean;
    function NombreLargo: string;
  end;

  TAusencia = record
    Tipo: TTipoAusencia;
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    Comentario: string;
    function CubreFecha(const AFecha: TDateTime): Boolean;
  end;

  // ============================================================
  // OPERARIO (con cost data)
  // ============================================================

  TOperario = record
    CodOperario: string;
    Nombre: string;
    CentrosHabilitados: TList<string>;
    Habilidades: TDictionary<string, TNivelCompetencia>;
    Turno: TTurno;
    Ausencias: TList<TAusencia>;

    /// COSTE LABORAL
    SueldoEurHora: Double; // sueldo base €/h
    RecargoTurnoNoche: Double; // multiplicador, ej. 1.25 = +25%
    RecargoFestivo: Double; // multiplicador, ej. 1.75 = +75%

    /// ESTADO RUNTIME
    Estado: TEstadoOperario;
    OrdenAsignadaActual: string;
    OperacionEnCurso: string;
    HoraFinPrevistaOcupacion: TDateTime;
    CargaJornadaHoras: Double;

    procedure Init;
    procedure Liberar;
    procedure AddHabilidad(const ACodHabilidad: string;
      ANivel: TNivelCompetencia);
    procedure HabilitarCentro(const ACodCentro: string);
    procedure AddAusencia(const AAusencia: TAusencia);
    function TieneHabilidad(const ACodHabilidad: string;
      ANivelMinimo: TNivelCompetencia): Boolean;
    function PuedeTrabajarEnCentro(const ACodCentro: string): Boolean;
    function EstaAusenteEn(const AFecha: TDateTime): Boolean;
    function EstaEnTurnoEn(const AFechaHora: TDateTime): Boolean;
    function EstaDisponibleEn(const AFechaHora: TDateTime): Boolean;
    /// Calcula coste/hora según el momento (aplica recargos si toca)
    function CosteEfectivoEurHora(const AFechaHora: TDateTime;
      AEsFestivo: Boolean): Double;
  end;

  // ============================================================
  // OPERACIÓN DENTRO DE UNA ORDEN (con #operarios mín/máx)
  // ============================================================

  TOperacionOrden = record
    NumSecuencia: Integer;
    CodOperacion: string;
    DuracionMin: Integer;

    /// NUEVO: cuántos operarios distintos pueden trabajar simultáneamente.
    /// NumOperariosMin = mínimo necesario para arrancar la operación
    /// NumOperariosMax = capacidad máxima útil (más no aporta)
    NumOperariosMin: Integer;
    NumOperariosMax: Integer;

    /// Estado
    Iniciada: Boolean;
    Finalizada: Boolean;
    /// Lista de operarios actualmente asignados (puede ser >1 si max>1)
    OperariosAsignados: TList<string>;
    HoraInicioReal: TDateTime;
    HoraFinReal: TDateTime;

    procedure Init;
    procedure Liberar;
    procedure AsignarOperario(const ACodOperario: string);
    procedure DesasignarOperario(const ACodOperario: string);
    function NumOperariosActuales: Integer;
    function TieneSitioParaMas: Boolean;
    function TieneMinimoCubierto: Boolean;
  end;

  // ============================================================
  // ORDEN DE TRABAJO
  // ============================================================

  TOrdenTrabajo = record
    CodOrden: string;
    Descripcion: string;
    CodCentroRequerido: string;
    Estado: TEstadoOrden;
    Prioridad: Integer;
    FechaCreacion: TDateTime;
    FechaPrevistaInicio: TDateTime;
    FechaPrevistaFin: TDateTime;
    FechaCompromiso: TDateTime;
    Operaciones: TList<TOperacionOrden>;

    procedure Init;
    procedure Liberar;
    procedure AddOperacion(ANumSecuencia: Integer;
      const ACodOperacion: string; ADuracionMin: Integer;
      ANumOpMin: Integer = 1; ANumOpMax: Integer = 1);
    function ProximaOperacionPendiente: Integer;
    function EstaCompleta: Boolean;
  end;

  // ============================================================
  // PESOS DE SCORING (con coste laboral)
  // ============================================================

  TPesosPlanificacion = record
    PesoPrioridadOrden: Double;
    PesoCompromiso: Double;
    PesoNivelCompetencia: Double;
    PesoCargaOperario: Double;
    PesoContinuidad: Double;
    PesoEspera: Double;
    /// NUEVO: penaliza operarios caros para tareas que no lo necesitan
    PesoCosteManoObra: Double;
    class function Default: TPesosPlanificacion; static;
  end;

  // ============================================================
  // RESULTADO DE ASIGNACIÓN
  // ============================================================

  TAsignacion = record
    CodOperario: string;
    CodOrden: string;
    NumSecuenciaOperacion: Integer;
    CodOperacion: string;
    CodCentro: string;
    HoraInicioPrevista: TDateTime;
    HoraFinPrevista: TDateTime;
    Score: Double;
    /// NUEVO: coste estimado de esta asignación (€)
    CosteEstimado: Double;
    MotivoNoElegible: string;
    Elegible: Boolean;
    class function Vacio: TAsignacion; static;
  end;

implementation

uses
  System.DateUtils,
  System.Math;

// ============================================================
// TOperacion
// ============================================================

procedure TOperacion.Init;
begin
  CodOperacion := '';
  Descripcion := '';
  DuracionEstandarMin := 30;
  HabilidadesRequeridas := TDictionary<string, TNivelCompetencia>.Create;
end;

procedure TOperacion.Liberar;
begin
  FreeAndNil(HabilidadesRequeridas);
end;

procedure TOperacion.RequerirHabilidad(const ACodHabilidad: string;
  ANivel: TNivelCompetencia);
begin
  if HabilidadesRequeridas = nil then
    Init;
  HabilidadesRequeridas.AddOrSetValue(ACodHabilidad, ANivel);
end;

// ============================================================
// TCentroTrabajo
// ============================================================

procedure TCentroTrabajo.Init;
begin
  CodCentro := '';
  Descripcion := '';
  Capacidad := 1;
  OperacionesPermitidas := TList<string>.Create;
end;

procedure TCentroTrabajo.Liberar;
begin
  FreeAndNil(OperacionesPermitidas);
end;

procedure TCentroTrabajo.PermitirOperacion(const ACodOperacion: string);
begin
  if OperacionesPermitidas = nil then
    Init;
  if OperacionesPermitidas.IndexOf(ACodOperacion) = -1 then
    OperacionesPermitidas.Add(ACodOperacion);
end;

function TCentroTrabajo.PermiteOperacion(const ACodOperacion: string): Boolean;
begin
  Result := (OperacionesPermitidas <> nil) and
    (OperacionesPermitidas.IndexOf(ACodOperacion) >= 0);
end;

// ============================================================
// TTurno
// ============================================================

function TTurno.EstaActivoEn(const AFechaHora: TDateTime): Boolean;
var
  LDiaSemana, LHora: Integer;
begin
  Result := False;
  LDiaSemana := DayOfTheWeek(AFechaHora) - 1;
  if not(LDiaSemana in DiasSemanaActivos) then
    Exit;
  LHora := HourOf(AFechaHora);
  if HoraFin > HoraInicio then
    Result := (LHora >= HoraInicio) and (LHora < HoraFin)
  else if HoraFin < HoraInicio then
    Result := (LHora >= HoraInicio) or (LHora < HoraFin)
  else
    Result := True;
end;

function TTurno.NombreLargo: string;
begin
  case Tipo of
    ttManana: Result := 'Mañana';
    ttTarde: Result := 'Tarde';
    ttNoche: Result := 'Noche';
    ttPartido: Result := 'Partido';
    ttCentral: Result := 'Central';
  else
    Result := '?';
  end;
end;

// ============================================================
// TAusencia
// ============================================================

function TAusencia.CubreFecha(const AFecha: TDateTime): Boolean;
var
  LDia, LIni, LFin: TDate;
begin
  LDia := DateOf(AFecha);
  LIni := DateOf(FechaInicio);
  LFin := DateOf(FechaFin);
  Result := (LDia >= LIni) and (LDia <= LFin);
end;

// ============================================================
// TOperario
// ============================================================

procedure TOperario.Init;
begin
  CodOperario := '';
  Nombre := '';
  CentrosHabilitados := TList<string>.Create;
  Habilidades := TDictionary<string, TNivelCompetencia>.Create;
  Ausencias := TList<TAusencia>.Create;

  SueldoEurHora := 18.0; // sueldo base por defecto
  RecargoTurnoNoche := 1.25;
  RecargoFestivo := 1.75;

  Estado := esLibre;
  OrdenAsignadaActual := '';
  OperacionEnCurso := '';
  HoraFinPrevistaOcupacion := 0;
  CargaJornadaHoras := 0;

  Turno.CodTurno := 'CENTRAL';
  Turno.Tipo := ttCentral;
  Turno.HoraInicio := 9;
  Turno.HoraFin := 18;
  Turno.DiasSemanaActivos := [0, 1, 2, 3, 4];
end;

procedure TOperario.Liberar;
begin
  FreeAndNil(CentrosHabilitados);
  FreeAndNil(Habilidades);
  FreeAndNil(Ausencias);
end;

procedure TOperario.AddHabilidad(const ACodHabilidad: string;
  ANivel: TNivelCompetencia);
begin
  if Habilidades = nil then
    Init;
  Habilidades.AddOrSetValue(ACodHabilidad, ANivel);
end;

procedure TOperario.HabilitarCentro(const ACodCentro: string);
begin
  if CentrosHabilitados = nil then
    Init;
  if CentrosHabilitados.IndexOf(ACodCentro) = -1 then
    CentrosHabilitados.Add(ACodCentro);
end;

procedure TOperario.AddAusencia(const AAusencia: TAusencia);
begin
  if Ausencias = nil then
    Init;
  Ausencias.Add(AAusencia);
end;

function TOperario.TieneHabilidad(const ACodHabilidad: string;
  ANivelMinimo: TNivelCompetencia): Boolean;
var
  LNivel: TNivelCompetencia;
begin
  Result := False;
  if Habilidades = nil then
    Exit;
  if Habilidades.TryGetValue(ACodHabilidad, LNivel) then
    Result := LNivel >= ANivelMinimo;
end;

function TOperario.PuedeTrabajarEnCentro(const ACodCentro: string): Boolean;
begin
  Result := (CentrosHabilitados <> nil) and
    (CentrosHabilitados.IndexOf(ACodCentro) >= 0);
end;

function TOperario.EstaAusenteEn(const AFecha: TDateTime): Boolean;
var
  LAusencia: TAusencia;
begin
  Result := False;
  if Ausencias = nil then
    Exit;
  for LAusencia in Ausencias do
    if LAusencia.CubreFecha(AFecha) then
      Exit(True);
end;

function TOperario.EstaEnTurnoEn(const AFechaHora: TDateTime): Boolean;
begin
  Result := Turno.EstaActivoEn(AFechaHora);
end;

function TOperario.EstaDisponibleEn(const AFechaHora: TDateTime): Boolean;
begin
  Result := (Estado = esLibre) and (not EstaAusenteEn(AFechaHora)) and
    EstaEnTurnoEn(AFechaHora);
end;

function TOperario.CosteEfectivoEurHora(const AFechaHora: TDateTime;
  AEsFestivo: Boolean): Double;
begin
  Result := SueldoEurHora;
  if AEsFestivo then
    Result := Result * RecargoFestivo
  else if Turno.Tipo = ttNoche then
    Result := Result * RecargoTurnoNoche;
end;

// ============================================================
// TOperacionOrden
// ============================================================

procedure TOperacionOrden.Init;
begin
  NumSecuencia := 0;
  CodOperacion := '';
  DuracionMin := 30;
  NumOperariosMin := 1;
  NumOperariosMax := 1;
  Iniciada := False;
  Finalizada := False;
  OperariosAsignados := TList<string>.Create;
  HoraInicioReal := 0;
  HoraFinReal := 0;
end;

procedure TOperacionOrden.Liberar;
begin
  FreeAndNil(OperariosAsignados);
end;

procedure TOperacionOrden.AsignarOperario(const ACodOperario: string);
begin
  if OperariosAsignados = nil then
    Init;
  if OperariosAsignados.IndexOf(ACodOperario) = -1 then
    OperariosAsignados.Add(ACodOperario);
end;

procedure TOperacionOrden.DesasignarOperario(const ACodOperario: string);
var
  LIdx: Integer;
begin
  if OperariosAsignados = nil then
    Exit;
  LIdx := OperariosAsignados.IndexOf(ACodOperario);
  if LIdx >= 0 then
    OperariosAsignados.Delete(LIdx);
end;

function TOperacionOrden.NumOperariosActuales: Integer;
begin
  if OperariosAsignados = nil then
    Result := 0
  else
    Result := OperariosAsignados.Count;
end;

function TOperacionOrden.TieneSitioParaMas: Boolean;
begin
  Result := NumOperariosActuales < NumOperariosMax;
end;

function TOperacionOrden.TieneMinimoCubierto: Boolean;
begin
  Result := NumOperariosActuales >= NumOperariosMin;
end;

// ============================================================
// TOrdenTrabajo
// ============================================================

procedure TOrdenTrabajo.Init;
begin
  CodOrden := '';
  Descripcion := '';
  CodCentroRequerido := '';
  Estado := eoPlanificada;
  Prioridad := 5;
  FechaCreacion := Now;
  FechaPrevistaInicio := 0;
  FechaPrevistaFin := 0;
  FechaCompromiso := 0;
  Operaciones := TList<TOperacionOrden>.Create;
end;

procedure TOrdenTrabajo.Liberar;
var
  I: Integer;
  LOp: TOperacionOrden;
begin
  if Operaciones <> nil then
  begin
    // Liberar las TList<string> internas de cada operación
    for I := 0 to Operaciones.Count - 1 do
    begin
      LOp := Operaciones[I];
      LOp.Liberar;
    end;
    FreeAndNil(Operaciones);
  end;
end;

procedure TOrdenTrabajo.AddOperacion(ANumSecuencia: Integer;
  const ACodOperacion: string; ADuracionMin: Integer; ANumOpMin: Integer;
  ANumOpMax: Integer);
var
  LOp: TOperacionOrden;
begin
  if Operaciones = nil then
    Init;
  LOp.Init;
  LOp.NumSecuencia := ANumSecuencia;
  LOp.CodOperacion := ACodOperacion;
  LOp.DuracionMin := ADuracionMin;
  LOp.NumOperariosMin := Max(1, ANumOpMin);
  LOp.NumOperariosMax := Max(LOp.NumOperariosMin, ANumOpMax);
  Operaciones.Add(LOp);
end;

function TOrdenTrabajo.ProximaOperacionPendiente: Integer;
var
  I: Integer;
begin
  Result := -1;
  if Operaciones = nil then
    Exit;
  for I := 0 to Operaciones.Count - 1 do
    if not Operaciones[I].Finalizada then
      Exit(I);
end;

function TOrdenTrabajo.EstaCompleta: Boolean;
begin
  Result := ProximaOperacionPendiente = -1;
end;

// ============================================================
// TPesosPlanificacion
// ============================================================

class function TPesosPlanificacion.Default: TPesosPlanificacion;
begin
  Result.PesoPrioridadOrden := 10.0;
  Result.PesoCompromiso := 8.0;
  Result.PesoNivelCompetencia := 3.0;
  Result.PesoCargaOperario := 0.5;
  Result.PesoContinuidad := 4.0;
  Result.PesoEspera := 0.05;
  Result.PesoCosteManoObra := 2.0;
end;

// ============================================================
// TAsignacion
// ============================================================

class function TAsignacion.Vacio: TAsignacion;
begin
  Result.CodOperario := '';
  Result.CodOrden := '';
  Result.NumSecuenciaOperacion := 0;
  Result.CodOperacion := '';
  Result.CodCentro := '';
  Result.HoraInicioPrevista := 0;
  Result.HoraFinPrevista := 0;
  Result.Score := 0;
  Result.CosteEstimado := 0;
  Result.MotivoNoElegible := '';
  Result.Elegible := False;
end;

end.
