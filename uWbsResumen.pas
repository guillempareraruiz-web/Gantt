unit uWbsResumen;

{
  RESUMEN DEL PROYECTO (Modulo de Ingenieria, paradigma TAREAS).

  Calcula las cifras que contestan "como va el proyecto" en sus cuatro ejes:

    CALENDARIO  cuando empieza, cuando acaba, cuanto dura, cuanto queda y si
                llega tarde respecto a la linea base.
    ESFUERZO    cuanto trabajo hay comprometido, consumido y restante.
    COSTE       lo mismo en euros, con las tarifas de cada persona.
    PROGRESO    % completado y en que estado estan las tareas.

  Es el equivalente al "Project Statistics" de MS Project (el cuadro
  Actual/Baseline/Variance sobre inicio, fin, duracion, trabajo y coste), que
  hasta ahora el modulo no daba: el panel solo hablaba de esfuerzo y callaba las
  fechas y el dinero, que son las dos primeras preguntas de cualquier direccion
  de proyecto.

  Solo CALCULA: no consulta la BD ni pinta nada. Recibe lo que la vista ya tiene
  cargado (tareas, cargas, desvios, estados) y devuelve numeros. Asi los
  criterios (que es una hoja, que cuenta como avance) viven en un solo sitio y
  el dialogo se limita a presentarlos.

  Criterio de signo en las desviaciones: POSITIVO = va PEOR que el plan (mas
  tarde, mas trabajo, mas caro), igual que en TWbsDesvio.
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.DateUtils,
  System.Generics.Collections,
  uWbsTypes;

type
  // Estado de una tarea de cara al recuento (no confundir con TWbsTaskEstado,
  // que es lo que declara el usuario: esto mezcla lo declarado con lo que dicen
  // las fechas).
  TWbsResumenProgreso = record
    Total: Integer;           // hojas (los resumenes no se cuentan: agregan)
    Pendientes: Integer;
    EnCurso: Integer;
    Hechas: Integer;
    Bloqueadas: Integer;
    Canceladas: Integer;
    Hitos: Integer;
    HitosPasados: Integer;    // hitos cuya fecha ya paso y no estan hechos
    Criticas: Integer;
    // Tareas que deberian haber terminado y no constan como hechas. Es el
    // numero que de verdad duele, y no sale de ningun otro sitio.
    Retrasadas: Integer;
    PctCompletado: Double;    // 0..100, ponderado por duracion
  end;

  TWbsResumenCalendario = record
    Inicio: TDateTime;
    Fin: TDateTime;
    DuracionMin: Double;         // laborables, de inicio a fin
    // Contra la linea base. TieneBaseline = False deja las desviaciones a 0.
    TieneBaseline: Boolean;
    BaseInicio: TDateTime;
    BaseFin: TDateTime;
    DesvioFinDias: Integer;      // + = acaba mas tarde de lo previsto
    // Respecto a HOY. Negativo en DiasRestantes = el proyecto ya deberia haber
    // acabado.
    DiasTranscurridos: Integer;
    DiasRestantes: Integer;
    PctTiempoConsumido: Double;  // 0..100 del calendario, no del trabajo
  end;

  TWbsResumenEsfuerzo = record
    PlanMin: Double;
    InvertidoMin: Double;
    RestanteMin: Double;
    ExcesoMin: Double;           // invertido por encima del plan (0 si no hay)
    TieneBaseline: Boolean;
    BaseMin: Double;
    DesvioPct: Double;           // + = mas trabajo del previsto
  end;

  TWbsResumenCoste = record
    PlanEur: Double;
    IncurridoEur: Double;
    RestanteEur: Double;
    DesviacionEur: Double;       // + = mas caro que lo planificado
    TieneBaseline: Boolean;
    BaseEur: Double;
    // Personas asignadas SIN tarifa. Sin esto, un proyecto entero sin tarifas
    // daria 0 EUR y pareceria gratis en vez de "no calculable".
    PersonasSinTarifa: Integer;
    PersonasConTarifa: Integer;
    // Horas que quedan fuera del calculo por no tener tarifa.
    MinSinTarifa: Double;
  end;

  // Coste y esfuerzo acumulados por persona (bloque de detalle).
  TWbsResumenPersona = record
    OperatorId: Integer;
    Nombre: string;
    CosteHora: Double;
    PlanMin: Double;
    InvertidoMin: Double;
    PlanEur: Double;
    IncurridoEur: Double;
    Pico: Double;                // % maximo de sobreasignacion
    NumTareas: Integer;
  end;
  TWbsResumenPersonaArray = TArray<TWbsResumenPersona>;

  // Un riesgo detectado: lo que hay que mirar hoy.
  TWbsResumenRiesgoTipo = (
    wrrRetrasada,        // deberia haber acabado y no consta hecha
    wrrBloqueada,        // el usuario la ha marcado bloqueada
    wrrVenceProximo,     // acaba en los proximos N dias
    wrrSobrecarga,       // alguien pasa del 100 % en ella
    wrrHitoPasado,       // hito con fecha vencida
    wrrDesviada          // se ha comido mucho mas tiempo del estimado
  );

  TWbsResumenRiesgo = record
    Tipo: TWbsResumenRiesgoTipo;
    NodeId: Integer;
    Caption: string;
    Fecha: TDateTime;
    Detalle: string;
    Severidad: Integer;   // 2 = grave, 1 = aviso. Ordena la lista.
  end;
  TWbsResumenRiesgoArray = TArray<TWbsResumenRiesgo>;

  // --- Curva de avance (burn-up / burndown) ---------------------------------
  // Un punto de la curva: una semana del proyecto.
  //
  // AVISO IMPORTANTE sobre lo que este grafico PUEDE y NO PUEDE decir:
  //
  // La curva PREVISTA es un dato real: sale de las fechas y el trabajo de cada
  // tarea, que es exactamente lo que el plan promete.
  //
  // La curva REAL historica NO se puede dibujar, y no se dibuja. FS_PL_Node
  // guarda MinutosInvertidos como un TOTAL ACUMULADO, sin fecha de imputacion:
  // se sabe cuanto se ha dedicado, pero no que dia. Repartir ese total hacia
  // atras (linealmente, o a la fecha de fin de cada tarea) daria una curva
  // convincente e INVENTADA, que es peor que no dar ninguna: el usuario tomaria
  // decisiones sobre una trayectoria que nadie ha medido.
  //
  // Asi que se dibuja la curva prevista entera y UN SOLO punto real: donde
  // estamos hoy. Con eso ya se contesta lo que importa ("voy por encima o por
  // debajo de lo prometido"), sin fingir que se sabe el camino recorrido.
  //
  // Para tener la curva real completa haria falta una tabla de imputaciones
  // (NodeId, Fecha, Minutos). Es una funcionalidad aparte, no un detalle de
  // este grafico.
  TWbsPuntoCurva = record
    Fecha: TDateTime;          // fin de la semana
    Etiqueta: string;          // "dd/mm"
    PrevistoAcumMin: Double;   // trabajo que deberia estar hecho a esa fecha
    PrevistoRestanteMin: Double;
    EsHoy: Boolean;            // la semana en curso
  end;
  TWbsPuntoCurvaArray = TArray<TWbsPuntoCurva>;

  TWbsResumenCurva = record
    Puntos: TWbsPuntoCurvaArray;
    TotalMin: Double;          // trabajo total del proyecto (techo de la curva)
    // Situacion REAL a dia de hoy (el unico punto real que se puede afirmar).
    RealAcumMin: Double;
    PrevistoHoyMin: Double;    // lo que tocaria llevar hecho hoy
    // + = por delante de lo previsto. Es la cifra que resume el grafico.
    DesviacionMin: Double;
    HayDatos: Boolean;
    // Hoy cae FUERA del calendario del proyecto. Importa porque cambia lo que
    // el grafico puede afirmar: en un proyecto que aun no ha empezado, "vas
    // 343 h por delante" es falso (lo previsto a dia de hoy es 0, asi que
    // CUALQUIER hora dedicada saldria como adelanto), y en uno ya terminado la
    // desviacion es el balance final, no un pronostico.
    NoIniciado: Boolean;
    Terminado: Boolean;
  end;

  // Todo junto: lo que el dialogo necesita para pintarse.
  TWbsResumen = record
    Titulo: string;
    Calendario: TWbsResumenCalendario;
    Esfuerzo: TWbsResumenEsfuerzo;
    Coste: TWbsResumenCoste;
    Progreso: TWbsResumenProgreso;
    Personas: TWbsResumenPersonaArray;
    Riesgos: TWbsResumenRiesgoArray;
    Curva: TWbsResumenCurva;
  end;

  // Entrada: lo que la vista ya tiene en memoria.
  TWbsResumenInput = record
    Titulo: string;
    Tareas: TWbsTaskArray;
    Cargas: TWbsCargaArray;
    Sobrecargas: TWbsSobrecargaArray;
    Desvios: TDictionary<Integer, TWbsDesvio>;   // puede venir nil
    // Estado declarado de cada tarea (FS_PL_TaskDetail). Puede venir nil: sin
    // el, el progreso se deduce solo de las horas invertidas.
    Estados: TDictionary<Integer, Integer>;
    JornadaMin: Integer;
    // Hoy. Se pasa en vez de llamar a Date() dentro para poder calcular el
    // resumen a una fecha de corte distinta (cierre de mes, informe atrasado).
    Hoy: TDateTime;
  end;

// Calcula el resumen completo. El llamante libera Result.Personas/Riesgos
// implicitamente (son arrays gestionados).
function CalcularResumen(const AInput: TWbsResumenInput): TWbsResumen;

// Helpers de presentacion, compartidos por el dialogo.
function FormatHoras(AMin: Double): string;
function FormatEuros(AEur: Double): string;
function RiesgoTipoToStr(ATipo: TWbsResumenRiesgoTipo): string;

implementation

uses
  System.Generics.Defaults;

const
  // Ventana de "vence pronto" para el bloque de riesgos.
  DIAS_VENCE_PROXIMO = 7;
  // A partir de que desviacion se considera que una tarea se ha ido de madre.
  // 1.10 y no 1.0: con 1.0 una tarea al 102 % ya salia como riesgo y la lista
  // se llenaba de ruido (mismo criterio que el ambar del grid).
  UMBRAL_DESVIACION = 1.10;

function FormatHoras(AMin: Double): string;
begin
  if Abs(AMin) < 0.5 then
    Result := '0 h'
  else if Abs(AMin) < 60 then
    Result := Format('%.0f min', [AMin])
  else
    Result := Format('%.0f h', [AMin / 60]);
end;

function FormatEuros(AEur: Double): string;
begin
  if Abs(AEur) >= 1000 then
    Result := Format('%.1f k'#8364, [AEur / 1000])
  else
    Result := Format('%.0f '#8364, [AEur]);
end;

function RiesgoTipoToStr(ATipo: TWbsResumenRiesgoTipo): string;
begin
  case ATipo of
    wrrRetrasada:    Result := 'Retrasada';
    wrrBloqueada:    Result := 'Bloqueada';
    wrrVenceProximo: Result := 'Vence pronto';
    wrrSobrecarga:   Result := 'Sobreasignaci'#243'n';
    wrrHitoPasado:   Result := 'Hito vencido';
    wrrDesviada:     Result := 'Desviada';
  else
    Result := '';
  end;
end;

// Una tarea cuenta para los totales si es HOJA: los resumenes agregan a sus
// hijas y sumarlos contaria cada trabajo dos veces.
function EsHoja(const ATarea: TWbsTask): Boolean;
begin
  Result := (ATarea.Kind <> wtkResumen) and (not ATarea.HasChildren);
end;

// Curva de avance PREVISTA, semana a semana, mas el punto real de hoy.
//
// Como se reparte el trabajo de una tarea en el tiempo: LINEALMENTE entre su
// inicio y su fin. Una tarea de 40 h que dura 4 semanas aporta 10 h a cada una.
// No es exacto (el esfuerzo real casi nunca es plano), pero es lo unico que el
// modelo permite afirmar: la tarea no dice como se distribuye por dentro, solo
// cuando empieza, cuando acaba y cuanto cuesta. Es la misma hipotesis que usan
// MS Project y Primavera para su curva S.
function CalcularCurva(const AInput: TWbsResumenInput;
  const APlanMin, AInvertidoMin: Double;
  const AInicio, AFin, AHoy: TDateTime): TWbsResumenCurva;
var
  Sem, NumSem, I, K: Integer;
  IniSemana, FinSemana: TDateTime;
  T: TWbsTask;
  DurDias, SolapeDias: Double;
  Acum: Double;
  P: TWbsPuntoCurva;
  Puntos: TList<TWbsPuntoCurva>;
  TIni, TFin: TDateTime;
begin
  Result := Default(TWbsResumenCurva);
  Result.TotalMin := APlanMin;
  Result.RealAcumMin := AInvertidoMin;

  if (AInicio <= 0) or (AFin <= AInicio) or (APlanMin <= 0) then Exit;

  // Una barra por semana. Con proyectos muy largos se sigue usando la semana:
  // agrupar por meses perderia justo el detalle del tramo actual, que es el que
  // se mira. El eje se recorta solo al pintar.
  NumSem := Max(1, Ceil(DaysBetween(AFin, AInicio) / 7));
  // Tope de seguridad: un proyecto de 10 años no debe generar 500 puntos.
  if NumSem > 260 then NumSem := 260;

  Puntos := TList<TWbsPuntoCurva>.Create;
  try
    Acum := 0;
    for Sem := 0 to NumSem - 1 do
    begin
      IniSemana := AInicio + Sem * 7;
      FinSemana := IniSemana + 7;

      // Trabajo que cae dentro de esta semana, sumando la parte proporcional
      // de cada tarea que la solape.
      for I := 0 to High(AInput.Tareas) do
      begin
        T := AInput.Tareas[I];
        if not EsHoja(T) then Continue;
        if T.TrabajoMin <= 0 then Continue;
        if (T.FechaInicio <= 0) or (T.FechaFin <= 0) then Continue;

        TIni := T.FechaInicio;
        TFin := T.FechaFin;

        // Un hito (o una tarea de duracion cero) no se reparte: aporta todo su
        // trabajo de golpe en la semana en la que cae.
        if TFin <= TIni then
        begin
          if (TIni >= IniSemana) and (TIni < FinSemana) then
            Acum := Acum + T.TrabajoMin;
          Continue;
        end;

        // Interseccion [tarea] x [semana], en dias.
        SolapeDias := Min(TFin, FinSemana) - Max(TIni, IniSemana);
        if SolapeDias <= 0 then Continue;

        DurDias := TFin - TIni;
        if DurDias <= 0 then Continue;

        Acum := Acum + T.TrabajoMin * (SolapeDias / DurDias);
      end;

      P := Default(TWbsPuntoCurva);
      P.Fecha := FinSemana;
      P.Etiqueta := FormatDateTime('dd/mm', FinSemana);
      // El acumulado no puede pasarse del total por redondeos del reparto.
      P.PrevistoAcumMin := Min(Acum, APlanMin);
      P.PrevistoRestanteMin := Max(0, APlanMin - P.PrevistoAcumMin);
      P.EsHoy := (AHoy >= IniSemana) and (AHoy < FinSemana);
      Puntos.Add(P);
    end;

    // Con el tope de 260 semanas, la ultima podria quedar antes del fin real y
    // la curva no llegaria nunca al total: se cierra a mano para que el techo
    // sea siempre el trabajo del proyecto.
    if Puntos.Count > 0 then
    begin
      P := Puntos[Puntos.Count - 1];
      if P.Fecha < AFin then
      begin
        P.PrevistoAcumMin := APlanMin;
        P.PrevistoRestanteMin := 0;
        P.Fecha := AFin;
        P.Etiqueta := FormatDateTime('dd/mm', AFin);
        Puntos[Puntos.Count - 1] := P;
      end;
    end;

    // Lo que TOCARIA llevar hecho HOY. Se INTERPOLA dentro de la semana en
    // curso: quedarse con el acumulado a fin de esa semana adelantaria hasta 7
    // dias de trabajo y haria parecer que el proyecto va retrasado cuando puede
    // ir al dia. La cifra que el usuario lee es la desviacion, asi que este
    // detalle no es cosmetico.
    Result.PrevistoHoyMin := 0;
    if AHoy >= AFin then
      Result.PrevistoHoyMin := APlanMin
    else if AHoy > AInicio then
      for K := 0 to Puntos.Count - 1 do
        if Puntos[K].Fecha >= AHoy then
        begin
          if K = 0 then
            IniSemana := AInicio
          else
            IniSemana := Puntos[K - 1].Fecha;

          if Puntos[K].Fecha > IniSemana then
          begin
            // Parte proporcional de lo que aporta esta semana.
            if K = 0 then
              Acum := 0
            else
              Acum := Puntos[K - 1].PrevistoAcumMin;
            Result.PrevistoHoyMin := Acum +
              (Puntos[K].PrevistoAcumMin - Acum) *
              ((AHoy - IniSemana) / (Puntos[K].Fecha - IniSemana));
          end
          else
            Result.PrevistoHoyMin := Puntos[K].PrevistoAcumMin;
          Break;
        end;

    Result.NoIniciado := AHoy < AInicio;
    Result.Terminado := AHoy >= AFin;
    Result.DesviacionMin := AInvertidoMin - Result.PrevistoHoyMin;
    Result.Puntos := Puntos.ToArray;
    Result.HayDatos := Puntos.Count > 0;
  finally
    Puntos.Free;
  end;
end;

function CalcularResumen(const AInput: TWbsResumenInput): TWbsResumen;
var
  I, J: Integer;
  T: TWbsTask;
  Desvio: TWbsDesvio;
  Estado: Integer;
  Jornada: Integer;
  Hoy: TDateTime;
  Personas: TDictionary<Integer, TWbsResumenPersona>;
  P: TWbsResumenPersona;
  ListaP: TList<TWbsResumenPersona>;
  Riesgos: TList<TWbsResumenRiesgo>;
  R: TWbsResumenRiesgo;
  NodosSobrecargados: TDictionary<Integer, Boolean>;
  DedicTotal, MinPersona, Inv, Dur: Double;
  HayBaseFechas: Boolean;
  Avance: Double;

  // Suma de dedicaciones de una tarea: denominador del prorrateo del tiempo
  // invertido. Dividir por 100 en vez de por esto duplicaria las horas en
  // cuanto haya mas de una persona asignada.
  function DedicacionDeTarea(ANodeId: Integer): Double;
  var
    K: Integer;
  begin
    Result := 0;
    for K := 0 to High(AInput.Cargas) do
      if AInput.Cargas[K].NodeId = ANodeId then
        Result := Result + AInput.Cargas[K].Dedicacion;
  end;

  function BuscarTarea(ANodeId: Integer; out ATarea: TWbsTask): Boolean;
  var
    K: Integer;
  begin
    Result := False;
    for K := 0 to High(AInput.Tareas) do
      if AInput.Tareas[K].NodeId = ANodeId then
      begin
        ATarea := AInput.Tareas[K];
        Exit(True);
      end;
  end;

  // Estado declarado de una tarea, o -1 si no tiene ficha.
  function EstadoDe(ANodeId: Integer): Integer;
  begin
    Result := -1;
    if AInput.Estados <> nil then
      if not AInput.Estados.TryGetValue(ANodeId, Result) then
        Result := -1;
  end;

begin
  Result := Default(TWbsResumen);
  Result.Titulo := AInput.Titulo;

  Jornada := AInput.JornadaMin;
  if Jornada <= 0 then Jornada := 480;
  Hoy := AInput.Hoy;
  if Hoy <= 0 then Hoy := Date;

  if Length(AInput.Tareas) = 0 then Exit;

  // -------------------------------------------------------------------------
  // CALENDARIO
  // -------------------------------------------------------------------------
  HayBaseFechas := False;
  for I := 0 to High(AInput.Tareas) do
  begin
    T := AInput.Tareas[I];
    if not EsHoja(T) then Continue;

    if (T.FechaInicio > 0) and
       ((Result.Calendario.Inicio = 0) or (T.FechaInicio < Result.Calendario.Inicio)) then
      Result.Calendario.Inicio := T.FechaInicio;
    if T.FechaFin > Result.Calendario.Fin then
      Result.Calendario.Fin := T.FechaFin;

    // Rango de la linea base: el mismo agregado, sobre las fechas congeladas.
    if (AInput.Desvios <> nil) and
       AInput.Desvios.TryGetValue(T.NodeId, Desvio) and Desvio.TieneBaseline then
    begin
      HayBaseFechas := True;
      if (Desvio.BaseInicio > 0) and
         ((Result.Calendario.BaseInicio = 0) or
          (Desvio.BaseInicio < Result.Calendario.BaseInicio)) then
        Result.Calendario.BaseInicio := Desvio.BaseInicio;
      if Desvio.BaseFin > Result.Calendario.BaseFin then
        Result.Calendario.BaseFin := Desvio.BaseFin;
    end;
  end;

  Result.Calendario.TieneBaseline := HayBaseFechas;
  if HayBaseFechas and (Result.Calendario.BaseFin > 0) and
     (Result.Calendario.Fin > 0) then
    Result.Calendario.DesvioFinDias :=
      DaysBetween(Result.Calendario.Fin, Result.Calendario.BaseFin) *
      IfThen(Result.Calendario.Fin >= Result.Calendario.BaseFin, 1, -1);

  if (Result.Calendario.Inicio > 0) and (Result.Calendario.Fin > 0) then
  begin
    // Duracion en dias NATURALES de punta a punta. No se usan minutos
    // laborables aqui a proposito: el dato que se espera de un proyecto es
    // "dura 3 meses", no "dura 960 horas de trabajo" (eso es el esfuerzo).
    Result.Calendario.DuracionMin :=
      DaysBetween(Result.Calendario.Fin, Result.Calendario.Inicio) * Jornada;

    Result.Calendario.DiasTranscurridos :=
      DaysBetween(Hoy, Result.Calendario.Inicio);
    if Hoy < Result.Calendario.Inicio then
      Result.Calendario.DiasTranscurridos := 0;

    Result.Calendario.DiasRestantes :=
      DaysBetween(Result.Calendario.Fin, Hoy);
    if Hoy > Result.Calendario.Fin then
      Result.Calendario.DiasRestantes := -Result.Calendario.DiasRestantes;

    if Result.Calendario.Fin > Result.Calendario.Inicio then
      Result.Calendario.PctTiempoConsumido :=
        Min(100, Max(0,
          DaysBetween(Hoy, Result.Calendario.Inicio) /
          DaysBetween(Result.Calendario.Fin, Result.Calendario.Inicio) * 100));
    if Hoy < Result.Calendario.Inicio then
      Result.Calendario.PctTiempoConsumido := 0;
  end;

  // -------------------------------------------------------------------------
  // ESFUERZO + PROGRESO (una sola pasada por las hojas)
  // -------------------------------------------------------------------------
  for I := 0 to High(AInput.Tareas) do
  begin
    T := AInput.Tareas[I];
    if not EsHoja(T) then Continue;

    Inc(Result.Progreso.Total);

    Result.Esfuerzo.PlanMin := Result.Esfuerzo.PlanMin + T.TrabajoMin;
    Result.Esfuerzo.InvertidoMin :=
      Result.Esfuerzo.InvertidoMin + T.MinutosInvertidos;

    if (AInput.Desvios <> nil) and
       AInput.Desvios.TryGetValue(T.NodeId, Desvio) and Desvio.TieneBaseline then
    begin
      Result.Esfuerzo.TieneBaseline := True;
      Result.Esfuerzo.BaseMin := Result.Esfuerzo.BaseMin + Desvio.BaseTrabajoMin;
    end;

    if T.Kind = wtkHito then
    begin
      Inc(Result.Progreso.Hitos);
      if (T.FechaFin > 0) and (T.FechaFin < Hoy) then
        Inc(Result.Progreso.HitosPasados);
    end;

    // Estado: el declarado manda; si no hay ficha, se deduce de las horas.
    Estado := EstadoDe(T.NodeId);
    case Estado of
      Ord(wtePendiente): Inc(Result.Progreso.Pendientes);
      Ord(wteEnCurso):   Inc(Result.Progreso.EnCurso);
      Ord(wteBloqueada): Inc(Result.Progreso.Bloqueadas);
      Ord(wteHecha):     Inc(Result.Progreso.Hechas);
      Ord(wteCancelada): Inc(Result.Progreso.Canceladas);
    else
      // Sin ficha: se infiere. Es una aproximacion honesta, y mejor que dejar
      // el recuento a cero en proyectos donde nadie rellena el estado.
      Avance := AvanceTarea(T.MinutosInvertidos, T.DuracionMin);
      if Avance >= 1 then Inc(Result.Progreso.Hechas)
      else if Avance > 0 then Inc(Result.Progreso.EnCurso)
      else Inc(Result.Progreso.Pendientes);
    end;

    // Retrasada: deberia haber acabado y no consta hecha ni cancelada.
    if (T.FechaFin > 0) and (T.FechaFin < Hoy) and
       (Estado <> Ord(wteHecha)) and (Estado <> Ord(wteCancelada)) then
      if (Estado >= 0) or
         (AvanceTarea(T.MinutosInvertidos, T.DuracionMin) < 1) then
        Inc(Result.Progreso.Retrasadas);
  end;

  Result.Esfuerzo.RestanteMin :=
    Max(0, Result.Esfuerzo.PlanMin - Result.Esfuerzo.InvertidoMin);
  Result.Esfuerzo.ExcesoMin :=
    Max(0, Result.Esfuerzo.InvertidoMin - Result.Esfuerzo.PlanMin);
  if Result.Esfuerzo.TieneBaseline and (Result.Esfuerzo.BaseMin > 0) then
    Result.Esfuerzo.DesvioPct :=
      (Result.Esfuerzo.PlanMin - Result.Esfuerzo.BaseMin) /
      Result.Esfuerzo.BaseMin * 100;

  // % completado PONDERADO POR DURACION, no media simple de tareas: una tarea
  // de 10 dias no puede pesar lo mismo que una de 1 (mismo criterio que el
  // roll-up de los resumenes en uWbsScheduler).
  if Result.Esfuerzo.PlanMin > 0 then
    Result.Progreso.PctCompletado :=
      Result.Esfuerzo.InvertidoMin / Result.Esfuerzo.PlanMin * 100;

  // -------------------------------------------------------------------------
  // COSTE + PERSONAS
  // -------------------------------------------------------------------------
  Personas := TDictionary<Integer, TWbsResumenPersona>.Create;
  ListaP := TList<TWbsResumenPersona>.Create;
  try
    for I := 0 to High(AInput.Cargas) do
    begin
      if AInput.Cargas[I].OperatorId <= 0 then Continue;
      if not BuscarTarea(AInput.Cargas[I].NodeId, T) then Continue;
      if not EsHoja(T) then Continue;

      if not Personas.TryGetValue(AInput.Cargas[I].OperatorId, P) then
      begin
        P := Default(TWbsResumenPersona);
        P.OperatorId := AInput.Cargas[I].OperatorId;
        P.Nombre := AInput.Cargas[I].Nombre;
        P.CosteHora := AInput.Cargas[I].CosteHora;
      end;

      // Lo que le toca de esta tarea: su parte de la duracion segun dedicacion.
      MinPersona := T.DuracionMin * AInput.Cargas[I].Dedicacion / 100;
      P.PlanMin := P.PlanMin + MinPersona;

      // El invertido es de la TAREA: se prorratea entre los asignados segun su
      // peso sobre el total de dedicacion, no sobre 100.
      DedicTotal := DedicacionDeTarea(AInput.Cargas[I].NodeId);
      Inv := 0;
      if DedicTotal > 0 then
        Inv := T.MinutosInvertidos * AInput.Cargas[I].Dedicacion / DedicTotal;
      P.InvertidoMin := P.InvertidoMin + Inv;

      P.PlanEur := P.PlanEur + MinPersona / 60 * P.CosteHora;
      P.IncurridoEur := P.IncurridoEur + Inv / 60 * P.CosteHora;

      Inc(P.NumTareas);
      Personas.AddOrSetValue(P.OperatorId, P);
    end;

    // Pico de sobreasignacion de cada uno.
    for I := 0 to High(AInput.Sobrecargas) do
      if Personas.TryGetValue(AInput.Sobrecargas[I].OperatorId, P) then
      begin
        if AInput.Sobrecargas[I].PorcentajePico > P.Pico then
          P.Pico := AInput.Sobrecargas[I].PorcentajePico;
        Personas.AddOrSetValue(P.OperatorId, P);
      end;

    for P in Personas.Values do
    begin
      ListaP.Add(P);

      if P.CosteHora > 0 then
      begin
        Inc(Result.Coste.PersonasConTarifa);
        Result.Coste.PlanEur := Result.Coste.PlanEur + P.PlanEur;
        Result.Coste.IncurridoEur := Result.Coste.IncurridoEur + P.IncurridoEur;
      end
      else
      begin
        // Sin tarifa no se inventa nada: se cuenta aparte para poder decir
        // "el coste no incluye a N personas" en vez de dar una cifra falsa.
        Inc(Result.Coste.PersonasSinTarifa);
        Result.Coste.MinSinTarifa := Result.Coste.MinSinTarifa + P.PlanMin;
      end;
    end;

    Result.Coste.RestanteEur :=
      Max(0, Result.Coste.PlanEur - Result.Coste.IncurridoEur);
    Result.Coste.DesviacionEur :=
      Result.Coste.IncurridoEur - Result.Coste.PlanEur;

    // Coste de la linea base: se deriva del trabajo congelado con la tarifa
    // media real del proyecto. No se guarda el coste en la baseline (V082 solo
    // congela fechas y trabajo), asi que esto es una estimacion, no un dato.
    if Result.Esfuerzo.TieneBaseline and (Result.Esfuerzo.PlanMin > 0) and
       (Result.Coste.PlanEur > 0) then
    begin
      Result.Coste.TieneBaseline := True;
      Result.Coste.BaseEur := Result.Esfuerzo.BaseMin *
        (Result.Coste.PlanEur / Result.Esfuerzo.PlanMin);
    end;

    // Mas cargado primero: es a quien hay que mirar.
    ListaP.Sort(TComparer<TWbsResumenPersona>.Construct(
      function(const X, Y: TWbsResumenPersona): Integer
      begin
        Result := CompareValue(Y.PlanMin, X.PlanMin);
      end));
    Result.Personas := ListaP.ToArray;
  finally
    ListaP.Free;
    Personas.Free;
  end;

  // -------------------------------------------------------------------------
  // RIESGOS
  // -------------------------------------------------------------------------
  Riesgos := TList<TWbsResumenRiesgo>.Create;
  NodosSobrecargados := TDictionary<Integer, Boolean>.Create;
  try
    for I := 0 to High(AInput.Sobrecargas) do
      for J := 0 to High(AInput.Sobrecargas[I].NodeIds) do
        NodosSobrecargados.AddOrSetValue(AInput.Sobrecargas[I].NodeIds[J], True);

    for I := 0 to High(AInput.Tareas) do
    begin
      T := AInput.Tareas[I];
      if not EsHoja(T) then Continue;

      Estado := EstadoDe(T.NodeId);
      // Lo cancelado y lo hecho ya no es un riesgo.
      if (Estado = Ord(wteHecha)) or (Estado = Ord(wteCancelada)) then Continue;

      R := Default(TWbsResumenRiesgo);
      R.NodeId := T.NodeId;
      R.Caption := T.Caption;
      R.Fecha := T.FechaFin;

      if Estado = Ord(wteBloqueada) then
      begin
        R.Tipo := wrrBloqueada;
        R.Severidad := 2;
        R.Detalle := 'Marcada como bloqueada';
        Riesgos.Add(R);
      end
      else if (T.Kind = wtkHito) and (T.FechaFin > 0) and (T.FechaFin < Hoy) then
      begin
        R.Tipo := wrrHitoPasado;
        R.Severidad := 2;
        R.Detalle := Format('Venci'#243' hace %d d'#237'as',
          [DaysBetween(Hoy, T.FechaFin)]);
        Riesgos.Add(R);
      end
      else if (T.FechaFin > 0) and (T.FechaFin < Hoy) then
      begin
        R.Tipo := wrrRetrasada;
        R.Severidad := 2;
        R.Detalle := Format('Deb'#237'a acabar hace %d d'#237'as',
          [DaysBetween(Hoy, T.FechaFin)]);
        Riesgos.Add(R);
      end
      else if (T.FechaFin > 0) and
              (DaysBetween(T.FechaFin, Hoy) <= DIAS_VENCE_PROXIMO) and
              (T.FechaFin >= Hoy) then
      begin
        R.Tipo := wrrVenceProximo;
        R.Severidad := 1;
        R.Detalle := Format('Acaba en %d d'#237'as',
          [DaysBetween(T.FechaFin, Hoy)]);
        Riesgos.Add(R);
      end;

      // Estos dos son ADICIONALES: una tarea puede estar retrasada Y
      // sobreasignada, y ocultar lo segundo por haber informado lo primero
      // escondera justo la causa.
      if NodosSobrecargados.ContainsKey(T.NodeId) then
      begin
        R := Default(TWbsResumenRiesgo);
        R.Tipo := wrrSobrecarga;
        R.NodeId := T.NodeId;
        R.Caption := T.Caption;
        R.Fecha := T.FechaInicio;
        R.Severidad := 1;
        R.Detalle := 'Alguien supera su jornada';
        Riesgos.Add(R);
      end;

      Dur := T.DuracionMin;
      if (Dur > 0) and (T.MinutosInvertidos > Dur * UMBRAL_DESVIACION) then
      begin
        R := Default(TWbsResumenRiesgo);
        R.Tipo := wrrDesviada;
        R.NodeId := T.NodeId;
        R.Caption := T.Caption;
        R.Fecha := T.FechaFin;
        R.Severidad := 1;
        R.Detalle := Format('%.0f %% del tiempo estimado',
          [T.MinutosInvertidos / Dur * 100]);
        Riesgos.Add(R);
      end;
    end;

    // Lo grave arriba y, dentro de cada nivel, lo mas antiguo primero: lo que
    // lleva mas tiempo torcido es lo que peor pinta tiene.
    Riesgos.Sort(TComparer<TWbsResumenRiesgo>.Construct(
      function(const X, Y: TWbsResumenRiesgo): Integer
      begin
        Result := CompareValue(Y.Severidad, X.Severidad);
        if Result = 0 then Result := CompareDateTime(X.Fecha, Y.Fecha);
      end));
    Result.Riesgos := Riesgos.ToArray;
  finally
    NodosSobrecargados.Free;
    Riesgos.Free;
  end;

  // -------------------------------------------------------------------------
  // CURVA DE AVANCE
  // -------------------------------------------------------------------------
  Result.Curva := CalcularCurva(AInput, Result.Esfuerzo.PlanMin,
    Result.Esfuerzo.InvertidoMin, Result.Calendario.Inicio,
    Result.Calendario.Fin, Hoy);

  // Criticas: no vienen en TWbsTask (las marca el motor), asi que las cuenta
  // la vista y las pasa aparte si las quiere. Aqui queda a 0 y el dialogo la
  // rellena, en vez de recalcular el CPM por segunda vez.
end;

end.
