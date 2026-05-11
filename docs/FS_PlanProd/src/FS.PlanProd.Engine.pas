unit FS.PlanProd.Engine;

{
  Motor de planificación.

  CAMBIOS respecto a la versión anterior:
  - Una operación puede aceptar múltiples operarios simultáneos
    (NumOperariosMin <= asignados <= NumOperariosMax).
  - El motor calcula coste estimado por asignación.
  - El score penaliza operarios caros para tareas que no requieren su nivel.
  - PlanificarBatch puede asignar varios operarios a la misma operación.
}

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Math,
  System.Generics.Collections,
  FS.PlanProd.Types,
  FS.PlanProd.Catalogo;

type
  TFuncFechaActual = reference to function: TDateTime;
  TFuncEsFestivo = reference to function(const AFecha: TDateTime): Boolean;

  TMotorPlanificacion = class
  private
    FCatalogo: TCatalogoMaestros;
    FPesos: TPesosPlanificacion;
    FFechaActual: TFuncFechaActual;
    FEsFestivo: TFuncEsFestivo;

    function CalcularCosteEstimado(const AOperario: TOperario;
      ADuracionMin: Integer; const AFechaHora: TDateTime): Double;

    function CalcularScore(const AOperario: TOperario;
      const AOrden: TOrdenTrabajo; const AOperacion: TOperacionOrden;
      const AOperacionMaestro: TOperacion;
      const AFechaHora: TDateTime): Double;

  public
    constructor Create(ACatalogo: TCatalogoMaestros); overload;
    constructor Create(ACatalogo: TCatalogoMaestros;
      const APesos: TPesosPlanificacion); overload;

    function EsElegible(const AOperario: TOperario;
      const AOrden: TOrdenTrabajo; const AOperacion: TOperacionOrden;
      const AFechaHora: TDateTime; out AMotivo: string): Boolean;

    function MejorOrdenParaOperario(const AOperario: TOperario;
      const AOrdenes: TArray<TOrdenTrabajo>; const AFechaHora: TDateTime)
      : TAsignacion;

    function PlanificarBatch(var AOperarios: TArray<TOperario>;
      var AOrdenes: TArray<TOrdenTrabajo>; const AFechaHora: TDateTime)
      : TArray<TAsignacion>;

    procedure AplicarAsignacion(var AOperario: TOperario;
      var AOrden: TOrdenTrabajo; const AAsignacion: TAsignacion);

    procedure FinalizarOperacion(var AOperario: TOperario;
      var AOrden: TOrdenTrabajo; ANumSecuencia: Integer;
      const AHoraFinReal: TDateTime);

    property Pesos: TPesosPlanificacion read FPesos write FPesos;
    property FechaActual: TFuncFechaActual read FFechaActual
      write FFechaActual;
    property EsFestivo: TFuncEsFestivo read FEsFestivo write FEsFestivo;
  end;

implementation

constructor TMotorPlanificacion.Create(ACatalogo: TCatalogoMaestros);
begin
  Create(ACatalogo, TPesosPlanificacion.Default);
end;

constructor TMotorPlanificacion.Create(ACatalogo: TCatalogoMaestros;
  const APesos: TPesosPlanificacion);
begin
  inherited Create;
  FCatalogo := ACatalogo;
  FPesos := APesos;
  FFechaActual :=
    function: TDateTime
    begin
      Result := Now;
    end;
  FEsFestivo :=
    function(const AFecha: TDateTime): Boolean
    begin
      // Por defecto: sábado y domingo son festivos
      Result := DayOfTheWeek(AFecha) in [6, 7];
    end;
end;

function TMotorPlanificacion.CalcularCosteEstimado(const AOperario: TOperario;
  ADuracionMin: Integer; const AFechaHora: TDateTime): Double;
var
  LCosteHora: Double;
  LFestivo: Boolean;
begin
  LFestivo := FEsFestivo(AFechaHora);
  LCosteHora := AOperario.CosteEfectivoEurHora(AFechaHora, LFestivo);
  Result := LCosteHora * (ADuracionMin / 60.0);
end;

function TMotorPlanificacion.EsElegible(const AOperario: TOperario;
  const AOrden: TOrdenTrabajo; const AOperacion: TOperacionOrden;
  const AFechaHora: TDateTime; out AMotivo: string): Boolean;
var
  LOpMaestro: TOperacion;
  LCentroMaestro: TCentroTrabajo;
  LPair: TPair<string, TNivelCompetencia>;
begin
  AMotivo := '';

  if AOperario.Estado = esOcupado then
  begin
    AMotivo := Format('%s ya ocupado en %s',
      [AOperario.CodOperario, AOperario.OrdenAsignadaActual]);
    Exit(False);
  end;

  if AOperario.EstaAusenteEn(AFechaHora) then
  begin
    AMotivo := Format('%s ausente', [AOperario.CodOperario]);
    Exit(False);
  end;

  if not AOperario.EstaEnTurnoEn(AFechaHora) then
  begin
    AMotivo := Format('%s fuera de turno', [AOperario.CodOperario]);
    Exit(False);
  end;

  if not AOperario.PuedeTrabajarEnCentro(AOrden.CodCentroRequerido) then
  begin
    AMotivo := Format('%s no habilitado en %s',
      [AOperario.CodOperario, AOrden.CodCentroRequerido]);
    Exit(False);
  end;

  if not FCatalogo.GetCentro(AOrden.CodCentroRequerido, LCentroMaestro) then
  begin
    AMotivo := Format('Centro %s desconocido',
      [AOrden.CodCentroRequerido]);
    Exit(False);
  end;

  if not LCentroMaestro.PermiteOperacion(AOperacion.CodOperacion) then
  begin
    AMotivo := Format('Centro %s no permite %s',
      [AOrden.CodCentroRequerido, AOperacion.CodOperacion]);
    Exit(False);
  end;

  if not FCatalogo.GetOperacion(AOperacion.CodOperacion, LOpMaestro) then
  begin
    AMotivo := Format('Operación %s desconocida', [AOperacion.CodOperacion]);
    Exit(False);
  end;

  if (LOpMaestro.HabilidadesRequeridas <> nil) then
  begin
    for LPair in LOpMaestro.HabilidadesRequeridas do
    begin
      if not AOperario.TieneHabilidad(LPair.Key, LPair.Value) then
      begin
        AMotivo := Format('%s carece %s nivel %d',
          [AOperario.CodOperario, LPair.Key, LPair.Value]);
        Exit(False);
      end;
    end;
  end;

  Result := True;
end;

function TMotorPlanificacion.CalcularScore(const AOperario: TOperario;
  const AOrden: TOrdenTrabajo; const AOperacion: TOperacionOrden;
  const AOperacionMaestro: TOperacion; const AFechaHora: TDateTime): Double;
var
  LSobrenivel, LMinutosACompromiso, LMinutosEspera: Integer;
  LContinuidad, LCoste, LFactorCompromiso: Double;
  LPair: TPair<string, TNivelCompetencia>;
  LNivelOp: TNivelCompetencia;
  LFestivo: Boolean;
begin
  // 1. Prioridad
  Result := FPesos.PesoPrioridadOrden * AOrden.Prioridad;

  // 2. Compromiso (deadline)
  if AOrden.FechaCompromiso > 0 then
  begin
    LMinutosACompromiso := MinutesBetween(AOrden.FechaCompromiso, AFechaHora);
    if AOrden.FechaCompromiso < AFechaHora then
      LFactorCompromiso := 10
    else if LMinutosACompromiso < 60 then
      LFactorCompromiso := 8
    else if LMinutosACompromiso < 240 then
      LFactorCompromiso := 5
    else if LMinutosACompromiso < 1440 then
      LFactorCompromiso := 3
    else
      LFactorCompromiso := 1;
    Result := Result + FPesos.PesoCompromiso * LFactorCompromiso;
  end;

  // 3. Sobrequalificación: penalizar usar el senior si bastaba un junior
  LSobrenivel := 0;
  if (AOperacionMaestro.HabilidadesRequeridas <> nil) and
    (AOperario.Habilidades <> nil) then
  begin
    for LPair in AOperacionMaestro.HabilidadesRequeridas do
      if AOperario.Habilidades.TryGetValue(LPair.Key, LNivelOp) then
        Inc(LSobrenivel, Max(0, Integer(LNivelOp) - Integer(LPair.Value)));
  end;
  Result := Result + FPesos.PesoNivelCompetencia / (1 + LSobrenivel);

  // 4. Carga operario
  Result := Result - FPesos.PesoCargaOperario * AOperario.CargaJornadaHoras;

  // 5. Continuidad (mismo operario, misma orden)
  if SameText(AOperario.OrdenAsignadaActual, AOrden.CodOrden) then
    LContinuidad := 1.0
  else
    LContinuidad := 0;
  Result := Result + FPesos.PesoContinuidad * LContinuidad;

  // 6. Espera (anti-starvation)
  LMinutosEspera := MinutesBetween(AFechaHora, AOrden.FechaCreacion);
  if LMinutosEspera < 0 then
    LMinutosEspera := 0;
  Result := Result + FPesos.PesoEspera * LMinutosEspera;

  // 7. Coste mano de obra: penalizar (resta) según €/h efectivo
  LFestivo := FEsFestivo(AFechaHora);
  LCoste := AOperario.CosteEfectivoEurHora(AFechaHora, LFestivo);
  Result := Result - FPesos.PesoCosteManoObra * (LCoste / 10.0);
  // dividimos entre 10 para que un sueldo de 20€/h reste 2.0 * 2 = 4 puntos
end;

function TMotorPlanificacion.MejorOrdenParaOperario(const AOperario: TOperario;
  const AOrdenes: TArray<TOrdenTrabajo>; const AFechaHora: TDateTime)
  : TAsignacion;
var
  LOrden: TOrdenTrabajo;
  LIdxOperacion: Integer;
  LOperacion: TOperacionOrden;
  LOpMaestro: TOperacion;
  LScore, LMejorScore: Double;
  LMotivo: string;
  LEncontrado: Boolean;
begin
  Result := TAsignacion.Vacio;
  Result.CodOperario := AOperario.CodOperario;

  LMejorScore := -MaxDouble;
  LEncontrado := False;

  for LOrden in AOrdenes do
  begin
    if LOrden.Estado in [eoFinalizada, eoCancelada, eoPausada] then
      Continue;

    LIdxOperacion := LOrden.ProximaOperacionPendiente;
    if LIdxOperacion = -1 then
      Continue;

    LOperacion := LOrden.Operaciones[LIdxOperacion];

    // CAMBIO: aceptamos operaciones ya iniciadas si tienen sitio para más
    if LOperacion.Iniciada and (not LOperacion.TieneSitioParaMas) then
      Continue;

    // No volver a asignar al mismo operario que ya está en esta operación
    if (LOperacion.OperariosAsignados <> nil) and
      (LOperacion.OperariosAsignados.IndexOf(AOperario.CodOperario) >= 0) then
      Continue;

    if not EsElegible(AOperario, LOrden, LOperacion, AFechaHora, LMotivo) then
      Continue;

    if not FCatalogo.GetOperacion(LOperacion.CodOperacion, LOpMaestro) then
      Continue;

    LScore := CalcularScore(AOperario, LOrden, LOperacion, LOpMaestro,
      AFechaHora);

    if LScore > LMejorScore then
    begin
      LMejorScore := LScore;
      Result.CodOrden := LOrden.CodOrden;
      Result.NumSecuenciaOperacion := LOperacion.NumSecuencia;
      Result.CodOperacion := LOperacion.CodOperacion;
      Result.CodCentro := LOrden.CodCentroRequerido;
      Result.Score := LScore;
      Result.HoraInicioPrevista := AFechaHora;
      Result.HoraFinPrevista := IncMinute(AFechaHora, LOperacion.DuracionMin);
      Result.CosteEstimado := CalcularCosteEstimado(AOperario,
        LOperacion.DuracionMin, AFechaHora);
      Result.Elegible := True;
      LEncontrado := True;
    end;
  end;

  if not LEncontrado then
    Result.MotivoNoElegible := 'Sin orden elegible';
end;

function TMotorPlanificacion.PlanificarBatch(var AOperarios: TArray<TOperario>;
  var AOrdenes: TArray<TOrdenTrabajo>; const AFechaHora: TDateTime)
  : TArray<TAsignacion>;
var
  LResultados: TList<TAsignacion>;
  LMejorOp, LMejorOrden, I, J, LIdxOperacion, LIdxOpProx: Integer;
  LMejorScore, LScore: Double;
  LMotivo: string;
  LOperacion: TOperacionOrden;
  LOpMaestro: TOperacion;
  LRes: TAsignacion;
  LAsignados: TList<Integer>;
begin
  LResultados := TList<TAsignacion>.Create;
  LAsignados := TList<Integer>.Create;
  try
    while True do
    begin
      LMejorScore := -MaxDouble;
      LMejorOp := -1;
      LMejorOrden := -1;
      LIdxOperacion := -1;

      for I := 0 to High(AOperarios) do
      begin
        if LAsignados.IndexOf(I) >= 0 then
          Continue;
        if AOperarios[I].Estado <> esLibre then
          Continue;

        for J := 0 to High(AOrdenes) do
        begin
          if AOrdenes[J].Estado in [eoFinalizada, eoCancelada, eoPausada] then
            Continue;

          LIdxOpProx := AOrdenes[J].ProximaOperacionPendiente;
          if LIdxOpProx = -1 then
            Continue;

          LOperacion := AOrdenes[J].Operaciones[LIdxOpProx];

          // Si la operación ya está iniciada, solo aceptar si tiene sitio
          if LOperacion.Iniciada and (not LOperacion.TieneSitioParaMas) then
            Continue;

          // Y que el operario no esté ya en esta operación
          if (LOperacion.OperariosAsignados <> nil) and
            (LOperacion.OperariosAsignados.IndexOf(AOperarios[I].CodOperario)
            >= 0) then
            Continue;

          if not EsElegible(AOperarios[I], AOrdenes[J], LOperacion, AFechaHora,
            LMotivo) then
            Continue;

          if not FCatalogo.GetOperacion(LOperacion.CodOperacion, LOpMaestro)
          then
            Continue;

          LScore := CalcularScore(AOperarios[I], AOrdenes[J], LOperacion,
            LOpMaestro, AFechaHora);
          if LScore > LMejorScore then
          begin
            LMejorScore := LScore;
            LMejorOp := I;
            LMejorOrden := J;
            LIdxOperacion := LIdxOpProx;
          end;
        end;
      end;

      if LMejorOp = -1 then
        Break;

      LOperacion := AOrdenes[LMejorOrden].Operaciones[LIdxOperacion];

      LRes := TAsignacion.Vacio;
      LRes.CodOperario := AOperarios[LMejorOp].CodOperario;
      LRes.CodOrden := AOrdenes[LMejorOrden].CodOrden;
      LRes.NumSecuenciaOperacion := LOperacion.NumSecuencia;
      LRes.CodOperacion := LOperacion.CodOperacion;
      LRes.CodCentro := AOrdenes[LMejorOrden].CodCentroRequerido;
      LRes.Score := LMejorScore;
      LRes.HoraInicioPrevista := AFechaHora;
      LRes.HoraFinPrevista := IncMinute(AFechaHora, LOperacion.DuracionMin);
      LRes.CosteEstimado := CalcularCosteEstimado(AOperarios[LMejorOp],
        LOperacion.DuracionMin, AFechaHora);
      LRes.Elegible := True;

      AplicarAsignacion(AOperarios[LMejorOp], AOrdenes[LMejorOrden], LRes);

      LResultados.Add(LRes);
      LAsignados.Add(LMejorOp);
    end;

    Result := LResultados.ToArray;
  finally
    LAsignados.Free;
    LResultados.Free;
  end;
end;

procedure TMotorPlanificacion.AplicarAsignacion(var AOperario: TOperario;
  var AOrden: TOrdenTrabajo; const AAsignacion: TAsignacion);
var
  I: Integer;
  LOperacion: TOperacionOrden;
begin
  AOperario.Estado := esOcupado;
  AOperario.OrdenAsignadaActual := AAsignacion.CodOrden;
  AOperario.OperacionEnCurso := AAsignacion.CodOperacion;
  AOperario.HoraFinPrevistaOcupacion := AAsignacion.HoraFinPrevista;

  for I := 0 to AOrden.Operaciones.Count - 1 do
  begin
    if AOrden.Operaciones[I].NumSecuencia = AAsignacion.NumSecuenciaOperacion
    then
    begin
      LOperacion := AOrden.Operaciones[I];
      LOperacion.AsignarOperario(AOperario.CodOperario);
      if not LOperacion.Iniciada then
      begin
        LOperacion.Iniciada := True;
        LOperacion.HoraInicioReal := AAsignacion.HoraInicioPrevista;
      end;
      AOrden.Operaciones[I] := LOperacion;
      Break;
    end;
  end;

  if AOrden.Estado in [eoPlanificada, eoLanzada] then
    AOrden.Estado := eoEnCurso;
end;

procedure TMotorPlanificacion.FinalizarOperacion(var AOperario: TOperario;
  var AOrden: TOrdenTrabajo; ANumSecuencia: Integer;
  const AHoraFinReal: TDateTime);
var
  I: Integer;
  LOperacion: TOperacionOrden;
  LDuracionHoras: Double;
begin
  for I := 0 to AOrden.Operaciones.Count - 1 do
  begin
    if AOrden.Operaciones[I].NumSecuencia = ANumSecuencia then
    begin
      LOperacion := AOrden.Operaciones[I];
      LOperacion.DesasignarOperario(AOperario.CodOperario);

      // Si era el último operario, marcar finalizada
      if LOperacion.NumOperariosActuales = 0 then
      begin
        LOperacion.Finalizada := True;
        LOperacion.HoraFinReal := AHoraFinReal;
      end;

      LDuracionHoras := MinutesBetween(AHoraFinReal, LOperacion.HoraInicioReal)
        / 60.0;
      AOperario.CargaJornadaHoras := AOperario.CargaJornadaHoras +
        LDuracionHoras;

      AOrden.Operaciones[I] := LOperacion;
      Break;
    end;
  end;

  AOperario.Estado := esLibre;
  AOperario.OrdenAsignadaActual := '';
  AOperario.OperacionEnCurso := '';
  AOperario.HoraFinPrevistaOcupacion := 0;

  if AOrden.EstaCompleta then
    AOrden.Estado := eoFinalizada;
end;

end.
