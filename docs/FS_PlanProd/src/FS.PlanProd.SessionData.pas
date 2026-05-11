unit FS.PlanProd.SessionData;

{
  Singleton de sesión: contiene los datos compartidos entre todos los
  formularios (catálogo, operarios, órdenes, pesos, asignaciones).

  Todo está en memoria. Cuando se cierra la app, se pierde.
  La inicialización con datos demo está en este mismo módulo para que
  la app arranque con algo visible.
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  System.Generics.Collections,
  FS.PlanProd.Types,
  FS.PlanProd.Catalogo,
  FS.PlanProd.Engine;

type
  TSession = class
  private
    FCatalogo: TCatalogoMaestros;
    FMotor: TMotorPlanificacion;
    FOperarios: TList<TOperario>;
    FOrdenes: TList<TOrdenTrabajo>;
    FPesos: TPesosPlanificacion;
    FUltimasAsignaciones: TList<TAsignacion>;
    FFechaSimulada: TDateTime;
    procedure CargarDatosDemo;
  public
    constructor Create;
    destructor Destroy; override;

    /// Reinicia el motor con los pesos actuales.
    procedure RecrearMotor;

    /// Convierte la lista interna de operarios a array para el motor.
    function OperariosAsArray: TArray<TOperario>;
    procedure ActualizarOperariosDesdeArray(const AArray: TArray<TOperario>);

    function OrdenesAsArray: TArray<TOrdenTrabajo>;
    procedure ActualizarOrdenesDesdeArray(const AArray: TArray<TOrdenTrabajo>);

    /// Ejecuta un batch sobre los datos actuales y guarda en UltimasAsignaciones.
    function EjecutarPlanificacionBatch: Integer;

    property Catalogo: TCatalogoMaestros read FCatalogo;
    property Motor: TMotorPlanificacion read FMotor;
    property Operarios: TList<TOperario> read FOperarios;
    property Ordenes: TList<TOrdenTrabajo> read FOrdenes;
    property UltimasAsignaciones: TList<TAsignacion> read FUltimasAsignaciones;
    property Pesos: TPesosPlanificacion read FPesos write FPesos;
    property FechaSimulada: TDateTime read FFechaSimulada
      write FFechaSimulada;
  end;

var
  /// Instancia global. Creada en initialization, liberada en finalization.
  Session: TSession;

implementation

constructor TSession.Create;
begin
  inherited Create;
  FCatalogo := TCatalogoMaestros.Create;
  FOperarios := TList<TOperario>.Create;
  FOrdenes := TList<TOrdenTrabajo>.Create;
  FUltimasAsignaciones := TList<TAsignacion>.Create;
  FPesos := TPesosPlanificacion.Default;
  FFechaSimulada := EncodeDateTime(2026, 5, 11, 8, 0, 0, 0); // Lunes 8:00

  CargarDatosDemo;
  RecrearMotor;
end;

destructor TSession.Destroy;
var
  I: Integer;
  LOp: TOperario;
  LOrden: TOrdenTrabajo;
begin
  for I := 0 to FOperarios.Count - 1 do
  begin
    LOp := FOperarios[I];
    LOp.Liberar;
  end;
  FOperarios.Free;

  for I := 0 to FOrdenes.Count - 1 do
  begin
    LOrden := FOrdenes[I];
    LOrden.Liberar;
  end;
  FOrdenes.Free;

  FUltimasAsignaciones.Free;
  FMotor.Free;
  FCatalogo.Free;
  inherited;
end;

procedure TSession.RecrearMotor;
var
  LFechaCapturada: TDateTime;
begin
  LFechaCapturada := FFechaSimulada;
  FreeAndNil(FMotor);
  FMotor := TMotorPlanificacion.Create(FCatalogo, FPesos);
  FMotor.FechaActual :=
    function: TDateTime
    begin
      Result := LFechaCapturada;
    end;
end;

function TSession.OperariosAsArray: TArray<TOperario>;
begin
  Result := FOperarios.ToArray;
end;

procedure TSession.ActualizarOperariosDesdeArray(
  const AArray: TArray<TOperario>);
var
  I: Integer;
begin
  for I := 0 to High(AArray) do
    if I < FOperarios.Count then
      FOperarios[I] := AArray[I];
end;

function TSession.OrdenesAsArray: TArray<TOrdenTrabajo>;
begin
  Result := FOrdenes.ToArray;
end;

procedure TSession.ActualizarOrdenesDesdeArray(
  const AArray: TArray<TOrdenTrabajo>);
var
  I: Integer;
begin
  for I := 0 to High(AArray) do
    if I < FOrdenes.Count then
      FOrdenes[I] := AArray[I];
end;

function TSession.EjecutarPlanificacionBatch: Integer;
var
  LOps: TArray<TOperario>;
  LOrdenes: TArray<TOrdenTrabajo>;
  LResultados: TArray<TAsignacion>;
  I: Integer;
begin
  RecrearMotor; // refresca pesos y fecha
  LOps := OperariosAsArray;
  LOrdenes := OrdenesAsArray;

  LResultados := FMotor.PlanificarBatch(LOps, LOrdenes, FFechaSimulada);

  ActualizarOperariosDesdeArray(LOps);
  ActualizarOrdenesDesdeArray(LOrdenes);

  FUltimasAsignaciones.Clear;
  for I := 0 to High(LResultados) do
    FUltimasAsignaciones.Add(LResultados[I]);

  Result := Length(LResultados);
end;

procedure TSession.CargarDatosDemo;
var
  LOp: TOperacion;
  LCentro: TCentroTrabajo;
  LOperario: TOperario;
  LOrden: TOrdenTrabajo;
  LAusencia: TAusencia;
  I: Integer;

  procedure AddTurno(var AOperario: TOperario; ATipo: TTipoTurno;
    AHoraIni, AHoraFin: Integer);
  begin
    AOperario.Turno.Tipo := ATipo;
    AOperario.Turno.HoraInicio := AHoraIni;
    AOperario.Turno.HoraFin := AHoraFin;
    AOperario.Turno.DiasSemanaActivos := [0, 1, 2, 3, 4];
    case ATipo of
      ttManana: AOperario.Turno.CodTurno := 'M';
      ttTarde: AOperario.Turno.CodTurno := 'T';
      ttNoche: AOperario.Turno.CodTurno := 'N';
      ttCentral: AOperario.Turno.CodTurno := 'C';
      ttPartido: AOperario.Turno.CodTurno := 'P';
    end;
  end;

begin
  // ---- OPERACIONES ----
  LOp.Init;
  LOp.CodOperacion := 'MEZCLA';
  LOp.Descripcion := 'Mezcla en reactor';
  LOp.DuracionEstandarMin := 90;
  LOp.RequerirHabilidad('MANEJO_REACTOR', 2);
  LOp.RequerirHabilidad('SEGURIDAD_QUIMICA', 2);
  FCatalogo.RegistrarOperacion(LOp);

  LOp.Init;
  LOp.CodOperacion := 'FILTRADO';
  LOp.Descripcion := 'Filtrado y clarificación';
  LOp.DuracionEstandarMin := 45;
  LOp.RequerirHabilidad('MANEJO_REACTOR', 1);
  FCatalogo.RegistrarOperacion(LOp);

  LOp.Init;
  LOp.CodOperacion := 'ENVASADO';
  LOp.Descripcion := 'Llenado en línea';
  LOp.DuracionEstandarMin := 60;
  LOp.RequerirHabilidad('LINEA_ENVASADO', 1);
  FCatalogo.RegistrarOperacion(LOp);

  LOp.Init;
  LOp.CodOperacion := 'QC_LIQUIDOS';
  LOp.Descripcion := 'Control calidad líquidos';
  LOp.DuracionEstandarMin := 30;
  LOp.RequerirHabilidad('LABORATORIO', 2);
  LOp.RequerirHabilidad('GMP', 1);
  FCatalogo.RegistrarOperacion(LOp);

  LOp.Init;
  LOp.CodOperacion := 'QC_FINAL';
  LOp.Descripcion := 'Control calidad final';
  LOp.DuracionEstandarMin := 45;
  LOp.RequerirHabilidad('LABORATORIO', 3);
  LOp.RequerirHabilidad('GMP', 2);
  FCatalogo.RegistrarOperacion(LOp);

  LOp.Init;
  LOp.CodOperacion := 'CIP';
  LOp.Descripcion := 'Limpieza CIP';
  LOp.DuracionEstandarMin := 75;
  LOp.RequerirHabilidad('CIP_LIMPIEZA', 2);
  FCatalogo.RegistrarOperacion(LOp);

  LOp.Init;
  LOp.CodOperacion := 'CARGA_MP';
  LOp.Descripcion := 'Carga materia prima';
  LOp.DuracionEstandarMin := 30;
  LOp.RequerirHabilidad('CARRETILLA', 1);
  LOp.RequerirHabilidad('SEGURIDAD_QUIMICA', 1);
  FCatalogo.RegistrarOperacion(LOp);

  LOp.Init;
  LOp.CodOperacion := 'PALETIZADO';
  LOp.Descripcion := 'Paletizado y stretch';
  LOp.DuracionEstandarMin := 30;
  LOp.RequerirHabilidad('CARRETILLA', 1);
  FCatalogo.RegistrarOperacion(LOp);

  // ---- CENTROS ----
  LCentro.Init;
  LCentro.CodCentro := 'REACT-01';
  LCentro.Descripcion := 'Reactor 5000L';
  LCentro.Capacidad := 2;
  LCentro.PermitirOperacion('CARGA_MP');
  LCentro.PermitirOperacion('MEZCLA');
  LCentro.PermitirOperacion('FILTRADO');
  LCentro.PermitirOperacion('CIP');
  FCatalogo.RegistrarCentro(LCentro);

  LCentro.Init;
  LCentro.CodCentro := 'REACT-02';
  LCentro.Descripcion := 'Reactor 3000L';
  LCentro.Capacidad := 2;
  LCentro.PermitirOperacion('CARGA_MP');
  LCentro.PermitirOperacion('MEZCLA');
  LCentro.PermitirOperacion('FILTRADO');
  LCentro.PermitirOperacion('CIP');
  FCatalogo.RegistrarCentro(LCentro);

  LCentro.Init;
  LCentro.CodCentro := 'LIN-ENV-A';
  LCentro.Descripcion := 'Línea envasado A';
  LCentro.Capacidad := 3;
  LCentro.PermitirOperacion('ENVASADO');
  LCentro.PermitirOperacion('PALETIZADO');
  FCatalogo.RegistrarCentro(LCentro);

  LCentro.Init;
  LCentro.CodCentro := 'LIN-ENV-B';
  LCentro.Descripcion := 'Línea envasado B (bidones)';
  LCentro.Capacidad := 2;
  LCentro.PermitirOperacion('ENVASADO');
  LCentro.PermitirOperacion('PALETIZADO');
  FCatalogo.RegistrarCentro(LCentro);

  LCentro.Init;
  LCentro.CodCentro := 'LAB-QC';
  LCentro.Descripcion := 'Laboratorio QC';
  LCentro.Capacidad := 3;
  LCentro.PermitirOperacion('QC_LIQUIDOS');
  LCentro.PermitirOperacion('QC_FINAL');
  FCatalogo.RegistrarCentro(LCentro);

  // Habilidades adicionales
  FCatalogo.RegistrarHabilidad('CARRETILLA');
  FCatalogo.RegistrarHabilidad('CIP_LIMPIEZA');

  // ---- OPERARIOS ----
  LOperario.Init;
  LOperario.CodOperario := 'OP001';
  LOperario.Nombre := 'Joan Puig';
  LOperario.SueldoEurHora := 24.0;
  AddTurno(LOperario, ttManana, 6, 14);
  LOperario.HabilitarCentro('REACT-01');
  LOperario.HabilitarCentro('REACT-02');
  LOperario.AddHabilidad('MANEJO_REACTOR', 3);
  LOperario.AddHabilidad('SEGURIDAD_QUIMICA', 3);
  LOperario.AddHabilidad('CIP_LIMPIEZA', 3);
  LOperario.AddHabilidad('CARRETILLA', 2);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP002';
  LOperario.Nombre := 'María Roca';
  LOperario.SueldoEurHora := 19.0;
  AddTurno(LOperario, ttManana, 6, 14);
  LOperario.HabilitarCentro('REACT-01');
  LOperario.HabilitarCentro('REACT-02');
  LOperario.AddHabilidad('MANEJO_REACTOR', 2);
  LOperario.AddHabilidad('SEGURIDAD_QUIMICA', 2);
  LOperario.AddHabilidad('CIP_LIMPIEZA', 2);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP003';
  LOperario.Nombre := 'Pere Martí';
  LOperario.SueldoEurHora := 14.0;
  AddTurno(LOperario, ttManana, 6, 14);
  LOperario.HabilitarCentro('REACT-01');
  LOperario.AddHabilidad('MANEJO_REACTOR', 1);
  LOperario.AddHabilidad('SEGURIDAD_QUIMICA', 1);
  LOperario.AddHabilidad('CARRETILLA', 1);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP004';
  LOperario.Nombre := 'Anna Vidal';
  LOperario.SueldoEurHora := 20.0;
  AddTurno(LOperario, ttManana, 6, 14);
  LOperario.HabilitarCentro('LIN-ENV-A');
  LOperario.HabilitarCentro('LIN-ENV-B');
  LOperario.AddHabilidad('LINEA_ENVASADO', 3);
  LOperario.AddHabilidad('CARRETILLA', 2);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP005';
  LOperario.Nombre := 'Lluís Serra';
  LOperario.SueldoEurHora := 17.0;
  AddTurno(LOperario, ttManana, 6, 14);
  LOperario.HabilitarCentro('LIN-ENV-A');
  LOperario.AddHabilidad('LINEA_ENVASADO', 2);
  // Lluís de vacaciones esta semana
  LAusencia.Tipo := taVacaciones;
  LAusencia.FechaInicio := IncDay(FFechaSimulada, -3);
  LAusencia.FechaFin := IncDay(FFechaSimulada, 4);
  LAusencia.Comentario := 'Vacaciones';
  LOperario.AddAusencia(LAusencia);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP006';
  LOperario.Nombre := 'Carla Llopis';
  LOperario.SueldoEurHora := 28.0;
  AddTurno(LOperario, ttCentral, 9, 18);
  LOperario.HabilitarCentro('LAB-QC');
  LOperario.AddHabilidad('LABORATORIO', 3);
  LOperario.AddHabilidad('GMP', 3);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP007';
  LOperario.Nombre := 'David Coll';
  LOperario.SueldoEurHora := 16.0;
  AddTurno(LOperario, ttManana, 6, 14);
  LOperario.HabilitarCentro('LAB-QC');
  LOperario.AddHabilidad('LABORATORIO', 2);
  LOperario.AddHabilidad('GMP', 1);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP008';
  LOperario.Nombre := 'Sergi Bosch';
  LOperario.SueldoEurHora := 19.0;
  AddTurno(LOperario, ttTarde, 14, 22);
  LOperario.HabilitarCentro('REACT-01');
  LOperario.HabilitarCentro('REACT-02');
  LOperario.AddHabilidad('MANEJO_REACTOR', 2);
  LOperario.AddHabilidad('SEGURIDAD_QUIMICA', 2);
  LOperario.AddHabilidad('CIP_LIMPIEZA', 2);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP009';
  LOperario.Nombre := 'Núria Soler';
  LOperario.SueldoEurHora := 18.0;
  AddTurno(LOperario, ttTarde, 14, 22);
  LOperario.HabilitarCentro('LIN-ENV-A');
  LOperario.HabilitarCentro('LIN-ENV-B');
  LOperario.AddHabilidad('LINEA_ENVASADO', 2);
  LOperario.AddHabilidad('CARRETILLA', 1);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP010';
  LOperario.Nombre := 'Marc Folch';
  LOperario.SueldoEurHora := 22.0;
  AddTurno(LOperario, ttNoche, 22, 6);
  LOperario.HabilitarCentro('REACT-01');
  LOperario.HabilitarCentro('REACT-02');
  LOperario.HabilitarCentro('LIN-ENV-A');
  LOperario.AddHabilidad('MANEJO_REACTOR', 2);
  LOperario.AddHabilidad('LINEA_ENVASADO', 2);
  LOperario.AddHabilidad('SEGURIDAD_QUIMICA', 2);
  LOperario.AddHabilidad('CIP_LIMPIEZA', 2);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP011';
  LOperario.Nombre := 'Eva Riera';
  LOperario.SueldoEurHora := 17.0;
  AddTurno(LOperario, ttManana, 6, 14);
  LOperario.HabilitarCentro('REACT-01');
  LOperario.HabilitarCentro('REACT-02');
  LOperario.HabilitarCentro('LIN-ENV-A');
  LOperario.HabilitarCentro('LIN-ENV-B');
  LOperario.AddHabilidad('CARRETILLA', 3);
  LOperario.AddHabilidad('SEGURIDAD_QUIMICA', 1);
  FOperarios.Add(LOperario);

  LOperario.Init;
  LOperario.CodOperario := 'OP012';
  LOperario.Nombre := 'Pol Vives';
  LOperario.SueldoEurHora := 18.0;
  AddTurno(LOperario, ttManana, 6, 14);
  LOperario.HabilitarCentro('REACT-01');
  LOperario.HabilitarCentro('REACT-02');
  LOperario.AddHabilidad('CIP_LIMPIEZA', 3);
  LOperario.AddHabilidad('SEGURIDAD_QUIMICA', 2);
  FOperarios.Add(LOperario);

  // ---- ÓRDENES DE TRABAJO ----
  LOrden.Init;
  LOrden.CodOrden := 'OT-2026-1001';
  LOrden.Descripcion := 'Producto A urgente';
  LOrden.CodCentroRequerido := 'REACT-01';
  LOrden.Estado := eoLanzada;
  LOrden.Prioridad := 9;
  LOrden.FechaCreacion := IncHour(FFechaSimulada, -8);
  LOrden.FechaPrevistaInicio := FFechaSimulada;
  LOrden.FechaCompromiso := IncHour(FFechaSimulada, 6);
  LOrden.AddOperacion(10, 'CARGA_MP', 30, 1, 2); // 1-2 operarios
  LOrden.AddOperacion(20, 'MEZCLA', 90, 1, 1); // solo 1
  LOrden.AddOperacion(30, 'FILTRADO', 45, 1, 1);
  LOrden.AddOperacion(40, 'QC_LIQUIDOS', 30, 1, 1);
  FOrdenes.Add(LOrden);

  LOrden.Init;
  LOrden.CodOrden := 'OT-2026-1002';
  LOrden.Descripcion := 'Producto B stock';
  LOrden.CodCentroRequerido := 'REACT-02';
  LOrden.Estado := eoLanzada;
  LOrden.Prioridad := 5;
  LOrden.FechaCreacion := IncHour(FFechaSimulada, -3);
  LOrden.FechaPrevistaInicio := FFechaSimulada;
  LOrden.FechaCompromiso := IncHour(FFechaSimulada, 24);
  LOrden.AddOperacion(10, 'CARGA_MP', 30, 1, 2);
  LOrden.AddOperacion(20, 'MEZCLA', 90, 1, 1);
  LOrden.AddOperacion(30, 'FILTRADO', 45, 1, 1);
  FOrdenes.Add(LOrden);

  LOrden.Init;
  LOrden.CodOrden := 'OT-2026-1003';
  LOrden.Descripcion := 'Envasado Producto A';
  LOrden.CodCentroRequerido := 'LIN-ENV-A';
  LOrden.Estado := eoLanzada;
  LOrden.Prioridad := 7;
  LOrden.FechaCreacion := IncHour(FFechaSimulada, -1);
  LOrden.FechaPrevistaInicio := FFechaSimulada;
  LOrden.FechaCompromiso := IncHour(FFechaSimulada, 8);
  LOrden.AddOperacion(10, 'ENVASADO', 60, 2, 3); // requiere 2-3 operarios
  LOrden.AddOperacion(20, 'PALETIZADO', 30, 1, 2);
  FOrdenes.Add(LOrden);

  LOrden.Init;
  LOrden.CodOrden := 'OT-2026-1004';
  LOrden.Descripcion := 'CIP preventivo Reactor 01';
  LOrden.CodCentroRequerido := 'REACT-01';
  LOrden.Estado := eoPlanificada;
  LOrden.Prioridad := 3;
  LOrden.FechaCreacion := IncDay(FFechaSimulada, -1);
  LOrden.FechaPrevistaInicio := IncHour(FFechaSimulada, 4);
  LOrden.FechaCompromiso := IncDay(FFechaSimulada, 1);
  LOrden.AddOperacion(10, 'CIP', 75, 1, 1);
  FOrdenes.Add(LOrden);

  LOrden.Init;
  LOrden.CodOrden := 'OT-2026-1005';
  LOrden.Descripcion := 'QC final lote 5478 (envío hoy)';
  LOrden.CodCentroRequerido := 'LAB-QC';
  LOrden.Estado := eoLanzada;
  LOrden.Prioridad := 10;
  LOrden.FechaCreacion := IncMinute(FFechaSimulada, -45);
  LOrden.FechaPrevistaInicio := FFechaSimulada;
  LOrden.FechaCompromiso := IncHour(FFechaSimulada, 3);
  LOrden.AddOperacion(10, 'QC_FINAL', 45, 1, 2);
  FOrdenes.Add(LOrden);

  LOrden.Init;
  LOrden.CodOrden := 'OT-2026-1006';
  LOrden.Descripcion := 'Envasado Producto C bidones';
  LOrden.CodCentroRequerido := 'LIN-ENV-B';
  LOrden.Estado := eoLanzada;
  LOrden.Prioridad := 6;
  LOrden.FechaCreacion := IncMinute(FFechaSimulada, -90);
  LOrden.FechaPrevistaInicio := FFechaSimulada;
  LOrden.FechaCompromiso := IncHour(FFechaSimulada, 12);
  LOrden.AddOperacion(10, 'ENVASADO', 60, 1, 2);
  LOrden.AddOperacion(20, 'PALETIZADO', 30, 1, 2);
  FOrdenes.Add(LOrden);
end;

initialization
  Session := TSession.Create;

finalization
  Session.Free;

end.
