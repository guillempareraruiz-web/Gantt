unit uSampleDataGenerator;

interface

uses
  System.SysUtils, System.DateUtils, System.UITypes,
  uGanttTypes, uOperariosTypes, uOperariosRepo, uMoldeTypes, uMoldeRepo,
  uCentreCalendar, uErpTypes;

type
  // Definicion de un periodo no laborable dentro de un dia
  TSampleNWP = record
    StartH, StartM: Word;
    EndH, EndM: Word;
  end;

  // Definicion de un calendario de ejemplo
  TSampleCalendario = record
    Nombre: string;
    // Periodos no laborables lunes-viernes (mismos para todos los dias laborables)
    PeriodosLV: TArray<TSampleNWP>;
    FinDeSemanaCompleto: Boolean; // True = sabado y domingo cerrado
  end;
  PSampleCalendario = ^TSampleCalendario;

  TSampleData = record
    // Centros / Maquinas
    Centros: TArray<TCentreTreball>;

    // Listas maestras (usadas como catalogos)
    Articulos: TArray<string>;
    Operaciones: TArray<string>;
    Utillajes: TArray<string>;
    Areas: TArray<string>;
    Departamentos: TArray<string>;

    // Calendarios de centro
    Calendarios: TArray<TSampleCalendario>;
    // Mapa: CentreId -> indice en Calendarios
    CalendarioCentro: TArray<Integer>;
    // Calendarios disponibles para operarios (nombres)
    CalendariosOperario: TArray<string>;
  end;

procedure GenerateSampleData(
  AOperariosRepo: TOperariosRepo;
  AMoldeRepo: TMoldeRepo;
  NumCentros: Integer;
  out Data: TSampleData
);

// Aplica los calendarios generados a un TGanttControl
procedure ApplyCalendariosToGantt(
  const Data: TSampleData;
  const GetCalendar: TGetCalendarFunc
);

implementation

const
  // ---- Operaciones (30) ----
  SAMPLE_OPERACIONES: array[0..29] of string = (
    'PINTAR', 'BRONCEAR', 'LACAR', 'PULIR', 'CORTAR', 'EMBALAR',
    'SOLDAR', 'FRESAR', 'TORNEAR', 'TALADRAR', 'RECTIFICAR', 'MONTAR',
    'INYECTAR', 'SOPLAR', 'EXTRUIR', 'TROQUELAR', 'PRENSAR', 'REBARBEAR',
    'TEMPLAR', 'CEMENTAR', 'GALVANIZAR', 'CROMAR', 'ANODAR', 'GRANALLADO',
    'ENSAMBLAR', 'CALIBRAR', 'VERIFICAR', 'EMBLISTERAR', 'ETIQUETAR', 'PALETIZAR'
  );

  // ---- Areas (6) ----
  SAMPLE_AREAS: array[0..5] of string = (
    'Fabricacion', 'Logistica', 'Oficina Tecnica', 'Calidad', 'Mantenimiento', 'Almacen'
  );

  // ---- Departamentos (8) ----
  SAMPLE_DEPT_NOMBRES: array[0..7] of string = (
    'Mecanizado', 'Pintura', 'Montaje', 'Acabados',
    'Expediciones', 'Calidad', 'Inyeccion', 'Mantenimiento'
  );
  SAMPLE_DEPT_DESCS: array[0..7] of string = (
    'Torno, fresa, rectificadora',
    'Cabinas de pintura y lacado',
    'Lineas de montaje',
    'Pulido y acabados finales',
    'Embalaje y expedicion',
    'Control de calidad',
    'Maquinas de inyeccion',
    'Mantenimiento preventivo y correctivo'
  );

  // ---- Nombres operarios ----
  SAMPLE_NOMBRES: array[0..9] of string = (
    'Joan', 'Maria', 'Pere', 'Anna', 'Marc',
    'Laura', 'David', 'Carla', 'Jordi', 'Marta'
  );
  SAMPLE_APELLIDOS: array[0..29] of string = (
    'Garcia', 'Lopez', 'Martinez', 'Ferrer', 'Puig', 'Roca',
    'Serra', 'Font', 'Vila', 'Soler', 'Mas', 'Torres',
    'Vidal', 'Costa', 'Pons', 'Marin', 'Ruiz', 'Navarro',
    'Gimenez', 'Romero', 'Diaz', 'Moreno', 'Alonso', 'Molina',
    'Rubio', 'Ortega', 'Delgado', 'Castro', 'Herrero', 'Campos'
  );
  // Los calendarios de operario se generan dinamicamente a partir de los calendarios de centro

  // ---- Prefijos utillajes ----
  SAMPLE_UTILLAJE_PREFIJOS: array[0..9] of string = (
    'EXPULSOR', 'CAMARA-CALIENTE', 'REFRIGERACION', 'ROBOT-EXTRACCION',
    'BOQUILLA', 'PLATO-MAGNETICO', 'MORDAZA', 'PUNZON',
    'MATRIZ', 'GUIA-POSICIONADO'
  );

  // ---- Tipos molde ----
  SAMPLE_TIPO_MOLDE: array[0..4] of TTipoMolde = (
    tmInyeccion, tmSoplado, tmCompresion, tmExtrusion, tmOtro
  );

  // ---- Ubicaciones molde ----
  SAMPLE_UBICACIONES: array[0..4] of string = (
    'ALMACEN-MOLDES', 'NAVE-1', 'NAVE-2', 'TALLER-AJUSTE', 'ZONA-MANTENIMIENTO'
  );

// Helper para crear un TSampleNWP
function NWP(SH, SM, EH, EM: Word): TSampleNWP;
begin
  Result.StartH := SH;
  Result.StartM := SM;
  Result.EndH := EH;
  Result.EndM := EM;
end;

procedure BuildCalendarios(out Cals: TArray<TSampleCalendario>);
begin
  SetLength(Cals, 5);

  // Calendario 1: Turno partido 06:00-14:00, 15:00-22:00
  Cals[0].Nombre := 'CAL-TURNO-PARTIDO';
  Cals[0].PeriodosLV := TArray<TSampleNWP>.Create(
    NWP(0, 0, 6, 0),
    NWP(14, 0, 15, 0),
    NWP(22, 0, 23, 59)
  );
  Cals[0].FinDeSemanaCompleto := True;

  // Calendario 2: Turno manana 07:00-15:00
  Cals[1].Nombre := 'CAL-TURNO-MANANA';
  Cals[1].PeriodosLV := TArray<TSampleNWP>.Create(
    NWP(0, 0, 7, 0),
    NWP(15, 0, 23, 59)
  );
  Cals[1].FinDeSemanaCompleto := True;

  // Calendario 3: Turno tarde 15:00-23:00
  Cals[2].Nombre := 'CAL-TURNO-TARDE';
  Cals[2].PeriodosLV := TArray<TSampleNWP>.Create(
    NWP(0, 0, 15, 0),
    NWP(18, 30, 18, 45),
    NWP(23, 0, 23, 59)
  );
  Cals[2].FinDeSemanaCompleto := True;

  // Calendario 4: Turno intensivo 06:00-13:30, 15:45-22:00
  Cals[3].Nombre := 'CAL-TURNO-INTENSIVO';
  Cals[3].PeriodosLV := TArray<TSampleNWP>.Create(
    NWP(0, 0, 6, 0),
    NWP(13, 30, 15, 45),
    NWP(22, 0, 23, 59)
  );
  Cals[3].FinDeSemanaCompleto := True;

  // Calendario 5: 24h (solo fines de semana cerrados)
  Cals[4].Nombre := 'CAL-24H';
  SetLength(Cals[4].PeriodosLV, 0);
  Cals[4].FinDeSemanaCompleto := True;
end;

procedure GenerateSampleData(
  AOperariosRepo: TOperariosRepo;
  AMoldeRepo: TMoldeRepo;
  NumCentros: Integer;
  out Data: TSampleData
);
var
  I, J, K: Integer;
  C: TCentreTreball;
  ArtCount, UtCount: Integer;
  Op: TOperario;
  NOperarios: Integer;
  Cap: TCapacitacion;
  NCaps: Integer;
  Dept: TDepartamento;
  DeptIds: TArray<Integer>;
  M: TMolde;
  NMoldes: Integer;
  NCentrosAsig, NOpsAsig: Integer;
begin
  Randomize;

  // ============================================================
  // 1. AREAS
  // ============================================================
  SetLength(Data.Areas, Length(SAMPLE_AREAS));
  for I := 0 to High(SAMPLE_AREAS) do
    Data.Areas[I] := SAMPLE_AREAS[I];

  // ============================================================
  // 2. OPERACIONES (30)
  // ============================================================
  SetLength(Data.Operaciones, Length(SAMPLE_OPERACIONES));
  for I := 0 to High(SAMPLE_OPERACIONES) do
    Data.Operaciones[I] := SAMPLE_OPERACIONES[I];

  // ============================================================
  // 3. ARTICULOS (100)
  // ============================================================
  ArtCount := 100;
  SetLength(Data.Articulos, ArtCount);
  for I := 0 to ArtCount - 1 do
    Data.Articulos[I] := Format('ART-%s', [FormatFloat('000', I + 1)]);

  // ============================================================
  // 4. UTILLAJES (50)
  // ============================================================
  UtCount := 50;
  SetLength(Data.Utillajes, UtCount);
  for I := 0 to UtCount - 1 do
    Data.Utillajes[I] := Format('UT-%s-%s', [
      SAMPLE_UTILLAJE_PREFIJOS[I mod Length(SAMPLE_UTILLAJE_PREFIJOS)],
      FormatFloat('00', (I div Length(SAMPLE_UTILLAJE_PREFIJOS)) + 1)
    ]);

  // ============================================================
  // 5. CALENDARIOS (5 tipos)
  // ============================================================
  BuildCalendarios(Data.Calendarios);

  // Calendarios de operario = nombres de los calendarios de centro
  SetLength(Data.CalendariosOperario, Length(Data.Calendarios));
  for I := 0 to High(Data.Calendarios) do
    Data.CalendariosOperario[I] := Data.Calendarios[I].Nombre;

  // ============================================================
  // 6. CENTROS / MAQUINAS + asignacion de calendario
  // ============================================================
  if NumCentros < 1 then NumCentros := 10;
  SetLength(Data.Centros, NumCentros);
  SetLength(Data.CalendarioCentro, NumCentros);
  for I := 0 to NumCentros - 1 do
  begin
    C := Default(TCentreTreball);
    C.Id := I + 1;
    C.CodiCentre := Format('CENTRO-%d', [(I div 2) + 1]);
    C.Titulo := Format('CENTRO-%d', [I + 1]);
    C.Subtitulo := Format('MAQUINA-%d', [I + 1]);
    C.IsSequencial := (Random(2) = 0);
    C.Order := I;
    C.Visible := True;
    C.Enabled := True;
    if C.IsSequencial then
    begin
      C.MaxLaneCount := 0;
      C.BaseHeight := 28;
    end
    else
    begin
      C.MaxLaneCount := 2 + Random(3);
      C.BaseHeight := 28 + Random(150);
    end;
    C.Area := SAMPLE_AREAS[I mod Length(SAMPLE_AREAS)];
    case (I mod 4) of
      0: C.BkColor := TColor($005252FF);
      1: C.BkColor := TColor($002828DC);
      2: C.BkColor := TColor($00FFE6CC);
    else
      C.BkColor := TColor($003366CC);
    end;
    Data.Centros[I] := C;
    // Asignar calendario ciclicamente entre los 5 disponibles
    Data.CalendarioCentro[I] := I mod Length(Data.Calendarios);
  end;

  // ============================================================
  // 7. DEPARTAMENTOS (8)
  // ============================================================
  SetLength(DeptIds, Length(SAMPLE_DEPT_NOMBRES));
  for I := 0 to High(SAMPLE_DEPT_NOMBRES) do
  begin
    Dept.Id := 0;
    Dept.Nombre := SAMPLE_DEPT_NOMBRES[I];
    Dept.Descripcion := SAMPLE_DEPT_DESCS[I];
    DeptIds[I] := AOperariosRepo.AddDepartamento(Dept);
  end;
  SetLength(Data.Departamentos, Length(SAMPLE_DEPT_NOMBRES));
  for I := 0 to High(SAMPLE_DEPT_NOMBRES) do
    Data.Departamentos[I] := SAMPLE_DEPT_NOMBRES[I];

  // ============================================================
  // 8. OPERARIOS (50) con departamentos y capacitaciones
  // ============================================================
  NOperarios := 50;
  for I := 0 to NOperarios - 1 do
  begin
    Op.Id := AOperariosRepo.NextOperarioId;
    Op.Nombre := SAMPLE_NOMBRES[I mod Length(SAMPLE_NOMBRES)] + ' ' +
                 SAMPLE_APELLIDOS[I mod Length(SAMPLE_APELLIDOS)];
    if I >= Length(SAMPLE_NOMBRES) then
      Op.Nombre := Op.Nombre + ' ' + IntToStr((I div Length(SAMPLE_APELLIDOS)) + 1);
    Op.Calendario := Data.CalendariosOperario[I mod Length(Data.CalendariosOperario)];
    AOperariosRepo.AddOperario(Op);

    AOperariosRepo.AssignOperariToDept(Op.Id, DeptIds[I mod Length(DeptIds)]);
    if Random(3) = 0 then
      AOperariosRepo.AssignOperariToDept(Op.Id, DeptIds[(I + 3) mod Length(DeptIds)]);

    NCaps := 2 + Random(4);
    for J := 0 to NCaps - 1 do
    begin
      Cap.OperarioId := Op.Id;
      Cap.Operacion := SAMPLE_OPERACIONES[(I * 3 + J * 7) mod Length(SAMPLE_OPERACIONES)];
      AOperariosRepo.AddCapacitacion(Cap);
    end;
  end;

  // ============================================================
  // 9. MOLDES (30) con relaciones
  // ============================================================
  NMoldes := 30;
  for I := 0 to NMoldes - 1 do
  begin
    M := Default(TMolde);
    M.CodigoMolde := Format('MOL-%s', [FormatFloat('000', I + 1)]);
    M.Descripcion := Format('Molde %s %d cavidades', [
      TipoMoldeToStr(SAMPLE_TIPO_MOLDE[I mod Length(SAMPLE_TIPO_MOLDE)]),
      2 + Random(15)
    ]);
    M.TipoMolde := SAMPLE_TIPO_MOLDE[I mod Length(SAMPLE_TIPO_MOLDE)];
    case Random(10) of
      0: M.Estado := emMontado;
      1: M.Estado := emReservado;
      2: M.Estado := emMantenimiento;
    else
      M.Estado := emDisponible;
    end;
    M.UbicacionActual := SAMPLE_UBICACIONES[I mod Length(SAMPLE_UBICACIONES)];
    M.CentroTrabajoActual := Data.Centros[I mod NumCentros].Titulo;
    M.NumeroCavidades := 1 + Random(16);
    M.TiempoMontaje := 15 + Random(46);
    M.TiempoDesmontaje := 10 + Random(31);
    M.TiempoAjuste := 5 + Random(26);
    M.CiclosAcumulados := Random(50000);
    M.FechaProximoMantenimiento := Date + 30 + Random(180);
    M.DisponiblePlanificacion := (M.Estado in [emDisponible, emMontado, emReservado]);
    M.Observaciones := '';

    AMoldeRepo.AddMolde(M);

    NCentrosAsig := 2 + Random(3);
    for J := 0 to NCentrosAsig - 1 do
    begin
      K := (I * 3 + J) mod NumCentros;
      AMoldeRepo.AssignCentro(M.IdMolde, Data.Centros[K].Titulo, (J = 0), 0);
    end;

    NOpsAsig := 1 + Random(3);
    for J := 0 to NOpsAsig - 1 do
      AMoldeRepo.AssignOperacion(M.IdMolde,
        SAMPLE_OPERACIONES[(I * 5 + J * 3) mod Length(SAMPLE_OPERACIONES)], 0, '');

    for J := 0 to 1 + Random(5) do
      AMoldeRepo.AssignArticulo(M.IdMolde,
        Data.Articulos[(I * 7 + J) mod ArtCount], 0, '');

    for J := 0 to Random(3) do
      AMoldeRepo.AssignUtillaje(M.IdMolde,
        Data.Utillajes[(I * 4 + J * 2) mod UtCount], (J = 0), '');
  end;
end;

{ ApplyCalendariosToGantt }

procedure ApplyCalendariosToGantt(
  const Data: TSampleData;
  const GetCalendar: TGetCalendarFunc
);
var
  I, J, D: Integer;
  Cal: TCentreCalendar;
  CalIdx: Integer;
  SampleCal: TSampleCalendario;
  Periods: TArray<TNonWorkingPeriod>;
  FullDay: TArray<TNonWorkingPeriod>;
begin
  // Preparar periodo de dia completo (cerrado)
  SetLength(FullDay, 1);
  FullDay[0].StartTimeOfDay := EncodeTime(0, 0, 0, 0);
  FullDay[0].EndTimeOfDay := EncodeTime(23, 59, 59, 999);

  for I := 0 to High(Data.Centros) do
  begin
    CalIdx := Data.CalendarioCentro[I];
    SampleCal := Data.Calendarios[CalIdx];
    Cal := GetCalendar(Data.Centros[I].Id);

    Cal.Name := SampleCal.Nombre;

    // Convertir TSampleNWP a TNonWorkingPeriod
    SetLength(Periods, Length(SampleCal.PeriodosLV));
    for J := 0 to High(SampleCal.PeriodosLV) do
    begin
      Periods[J].StartTimeOfDay := EncodeTime(
        SampleCal.PeriodosLV[J].StartH, SampleCal.PeriodosLV[J].StartM, 0, 0);
      if (SampleCal.PeriodosLV[J].EndH = 23) and (SampleCal.PeriodosLV[J].EndM = 59) then
        Periods[J].EndTimeOfDay := EncodeTime(23, 59, 59, 999)
      else
        Periods[J].EndTimeOfDay := EncodeTime(
          SampleCal.PeriodosLV[J].EndH, SampleCal.PeriodosLV[J].EndM, 0, 0);
    end;

    // Lunes a viernes
    for D := 1 to 5 do
      Cal.SetDayNonWorkingPeriods(D, Periods);

    // Fin de semana
    if SampleCal.FinDeSemanaCompleto then
    begin
      Cal.SetDayNonWorkingPeriods(6, FullDay);
      Cal.SetDayNonWorkingPeriods(7, FullDay);
    end;
  end;
end;

end.
