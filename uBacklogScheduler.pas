unit uBacklogScheduler;

{
  Motor de auto-planificacion a partir de una seleccion del Backlog.

  Estrategia:
  - 1 fila de Backlog -> 1 nodo.
  - Siempre se usa el CentroPreferente. Si esta saturado, el nodo se apila
    igualmente (end se desplaza hasta que la capacidad en la ventana agota).
  - Si la fila no tiene CentroPreferente -> no se planifica, va a la lista
    de no planificadas.
  - Duracion = HorasEstimadas * 60 minutos. Si HorasEstimadas <= 0,
    se usa 60 min por defecto.
  - Calendarios de centro se respetan (AddWorkingMinutes / SubtractWorkingMinutes).
  - Modo Forward: el nodo arranca en el "cursor" del centro (>= FechaBase)
    y se extiende hacia adelante.
  - Modo Backward: el nodo termina en la FechaCompromiso y se extiende
    hacia atras. Si no tiene FechaCompromiso -> fallback a Forward desde
    FechaBase.
}

interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  System.Generics.Collections,
  uGanttTypes;

type
  TSchedMode = (smForward, smBackward);
  TSchedOrder = (soFechaCompromiso, soPrioridad);

  TSchedInput = record
    RawId: Int64;
    Origen: string;
    CodigoDocumento: string;
    CentroPreferente: string;
    HorasEstimadas: Double;
    FechaCompromiso: TDateTime;
    Prioridad: Integer;
    NumeroOF: Integer;
    SerieOF: string;
    NumeroPedido: Integer;
    SeriePedido: string;
    CodigoCliente: string;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    UnidadesAFabricar: Double;
    NumeroTrabajo: string;
    // Link al modelo unificado FS_PL_Raw_Item (V016)
    RawItemClaveERP: string;     // ClaveERP del item planificado (Nivel 3 en el modelo PRO)
    RawItemTipoOrigen: string;   // 'OF ','PED','PRJ' (char(3) SQL)
  end;

  TSchedStatus = (ssOK, ssSaturado, ssFueraPlazo, ssSinCentro, ssSinCalendario);

  TSchedOutput = record
    Input: TSchedInput;
    CenterId: Integer;
    CenterCode: string;
    FechaInicio: TDateTime;
    FechaFin: TDateTime;
    DuracionMin: Double;
    Status: TSchedStatus;
    Observaciones: string;
  end;

  TSchedParams = record
    Mode: TSchedMode;
    Order: TSchedOrder;
    FechaBase: TDateTime;     // usada en Forward o como fallback en Backward
  end;

  TSchedResult = record
    Items: TArray<TSchedOutput>;
    TotalPlanificados: Integer;
    TotalNoPlanificados: Integer;
    TotalSaturados: Integer;
    TotalFueraPlazo: Integer;
  end;

function RunAutoScheduling(const AInputs: TArray<TSchedInput>;
  const AParams: TSchedParams): TSchedResult;

function StatusToStr(AStatus: TSchedStatus): string;

implementation

uses
  uDMPlanner, uCentresRepo, uCentreCalendar;

function StatusToStr(AStatus: TSchedStatus): string;
begin
  case AStatus of
    ssOK:            Result := 'OK';
    ssSaturado:      Result := 'SATURADO';
    ssFueraPlazo:    Result := 'FUERA DE PLAZO';
    ssSinCentro:     Result := 'SIN CENTRO';
    ssSinCalendario: Result := 'SIN CALENDARIO';
  else
    Result := '?';
  end;
end;

type
  TCenterCursor = record
    CenterId: Integer;
    Code: string;
    Cal: TCentreCalendar;
    IsSequencial: Boolean;
    Lanes: Integer;
    // Para apilar: por cada lane, fin actual en Forward o inicio actual en Backward
    LaneCursors: TArray<TDateTime>;
  end;

function GetLanes(const C: TCentreTreball): Integer;
begin
  if C.IsSequencial then Exit(1);
  if C.MaxLaneCount <= 0 then Exit(1);
  Result := C.MaxLaneCount;
end;

// Busca el lane con el cursor mas temprano (Forward) o mas tardio (Backward)
function PickLane(const Cursor: TCenterCursor; Forward: Boolean): Integer;
var
  I: Integer;
  Best: TDateTime;
begin
  Result := 0;
  if Length(Cursor.LaneCursors) = 0 then Exit;
  Best := Cursor.LaneCursors[0];
  for I := 1 to High(Cursor.LaneCursors) do
  begin
    if Forward then
    begin
      if Cursor.LaneCursors[I] < Best then
      begin
        Best := Cursor.LaneCursors[I];
        Result := I;
      end;
    end
    else
    begin
      if Cursor.LaneCursors[I] > Best then
      begin
        Best := Cursor.LaneCursors[I];
        Result := I;
      end;
    end;
  end;
end;

procedure SortInputs(var AInputs: TArray<TSchedInput>; AOrder: TSchedOrder);
var
  I, J: Integer;
  Tmp: TSchedInput;
  Swap: Boolean;
begin
  // Bubble sort simple (muestras pequenas, N < 200)
  for I := 0 to High(AInputs) - 1 do
    for J := 0 to High(AInputs) - 1 - I do
    begin
      Swap := False;
      case AOrder of
        soFechaCompromiso:
          begin
            if (AInputs[J].FechaCompromiso = 0) and (AInputs[J + 1].FechaCompromiso <> 0) then
              Swap := True
            else if (AInputs[J].FechaCompromiso <> 0) and (AInputs[J + 1].FechaCompromiso <> 0) then
              Swap := AInputs[J].FechaCompromiso > AInputs[J + 1].FechaCompromiso;
          end;
        soPrioridad:
          Swap := AInputs[J].Prioridad < AInputs[J + 1].Prioridad;
      end;
      if Swap then
      begin
        Tmp := AInputs[J];
        AInputs[J] := AInputs[J + 1];
        AInputs[J + 1] := Tmp;
      end;
    end;
end;

function RunAutoScheduling(const AInputs: TArray<TSchedInput>;
  const AParams: TSchedParams): TSchedResult;
var
  Inputs: TArray<TSchedInput>;
  Params: TSchedParams;
  CentresMap: TDictionary<string, TCentreTreball>;
  Cursors: TDictionary<Integer, TCenterCursor>;
  Centres: TArray<TCentreTreball>;
  C: TCentreTreball;
  Cursor: TCenterCursor;
  I, Lane: Integer;
  Input: TSchedInput;
  Output: TSchedOutput;
  DurMin: Integer;
  StartDT, EndDT: TDateTime;
  OutList: TList<TSchedOutput>;
  Key: string;
  NowDT: TDateTime;
begin
  Result := Default(TSchedResult);
  Inputs := Copy(AInputs);
  SortInputs(Inputs, AParams.Order);

  // Normalizar FechaBase: si es hoy (o anterior) usar Now(), para no planificar
  // en horas ya pasadas. Si es una fecha futura, se respeta tal cual (el usuario
  // quiere arrancar a las 00:00 de ese dia). La validacion contra FechaBloqueo
  // se hace ya en el caller (btnPlanificarClick), aqui solo nos ocupamos de
  // la hora.
  Params := AParams;
  NowDT := Now;
  if Trunc(Params.FechaBase) <= Trunc(NowDT) then
    Params.FechaBase := NowDT;

  CentresMap := TDictionary<string, TCentreTreball>.Create;
  Cursors := TDictionary<Integer, TCenterCursor>.Create;
  OutList := TList<TSchedOutput>.Create;
  try
    if DMPlanner.CentresRepo <> nil then
    begin
      Centres := DMPlanner.CentresRepo.GetAll;
      for C in Centres do
        CentresMap.AddOrSetValue(UpperCase(Trim(C.CodiCentre)), C);
    end;

    for I := 0 to High(Inputs) do
    begin
      Input := Inputs[I];
      Output := Default(TSchedOutput);
      Output.Input := Input;
      Output.CenterCode := Input.CentroPreferente;

      if Trim(Input.CentroPreferente) = '' then
      begin
        Output.Status := ssSinCentro;
        Output.Observaciones := 'Sin centro preferente';
        OutList.Add(Output);
        Inc(Result.TotalNoPlanificados);
        Continue;
      end;

      Key := UpperCase(Trim(Input.CentroPreferente));
      if not CentresMap.TryGetValue(Key, C) then
      begin
        Output.Status := ssSinCentro;
        Output.Observaciones := 'Centro ' + Input.CentroPreferente + ' no existe';
        OutList.Add(Output);
        Inc(Result.TotalNoPlanificados);
        Continue;
      end;

      // Inicializar cursor del centro si es la primera vez
      if not Cursors.TryGetValue(C.Id, Cursor) then
      begin
        Cursor := Default(TCenterCursor);
        Cursor.CenterId := C.Id;
        Cursor.Code := C.CodiCentre;
        Cursor.Cal := DMPlanner.CentresRepo.GetCalendarFor(C.Id);
        Cursor.IsSequencial := C.IsSequencial;
        Cursor.Lanes := GetLanes(C);
        SetLength(Cursor.LaneCursors, Cursor.Lanes);
        Cursors.Add(C.Id, Cursor);
      end;

      Output.CenterId := C.Id;

      if Cursor.Cal = nil then
      begin
        Output.Status := ssSinCalendario;
        Output.Observaciones := 'Centro sin calendario asignado';
        OutList.Add(Output);
        Inc(Result.TotalNoPlanificados);
        Continue;
      end;

      if Input.HorasEstimadas > 0 then
        DurMin := Round(Input.HorasEstimadas * 60)
      else
        DurMin := 60;
      Output.DuracionMin := DurMin;

      case AParams.Mode of
        smBackward:
          begin
            if Input.FechaCompromiso = 0 then
            begin
              // Fallback a Forward desde FechaBase
              Lane := PickLane(Cursor, True);
              if Cursor.LaneCursors[Lane] = 0 then
                Cursor.LaneCursors[Lane] := Params.FechaBase;
              if Cursor.LaneCursors[Lane] < Params.FechaBase then
                Cursor.LaneCursors[Lane] := Params.FechaBase;
              StartDT := Cursor.Cal.NextWorkingTime(Cursor.LaneCursors[Lane]);
              EndDT := Cursor.Cal.AddWorkingMinutes(StartDT, DurMin);
              Cursor.LaneCursors[Lane] := EndDT;
              Output.FechaInicio := StartDT;
              Output.FechaFin := EndDT;
              Output.Status := ssFueraPlazo;
              Output.Observaciones := 'Sin FechaCompromiso; planificado forward';
              Inc(Result.TotalFueraPlazo);
            end
            else
            begin
              Lane := PickLane(Cursor, False);  // lane con cursor mas tardio
              if Cursor.LaneCursors[Lane] = 0 then
                Cursor.LaneCursors[Lane] := Input.FechaCompromiso
              else if Cursor.LaneCursors[Lane] > Input.FechaCompromiso then
                Cursor.LaneCursors[Lane] := Input.FechaCompromiso;

              EndDT := Cursor.Cal.PrevWorkingTime(Cursor.LaneCursors[Lane]);
              StartDT := Cursor.Cal.SubtractWorkingMinutes(EndDT, DurMin);
              Cursor.LaneCursors[Lane] := StartDT;

              Output.FechaInicio := StartDT;
              Output.FechaFin := EndDT;
              if StartDT < Params.FechaBase then
              begin
                Output.Status := ssSaturado;
                Output.Observaciones := 'No cabe antes de FechaCompromiso';
                Inc(Result.TotalSaturados);
              end
              else
              begin
                Output.Status := ssOK;
                Inc(Result.TotalPlanificados);
              end;
            end;
          end;

        smForward:
          begin
            Lane := PickLane(Cursor, True);
            if Cursor.LaneCursors[Lane] = 0 then
              Cursor.LaneCursors[Lane] := Params.FechaBase;
            if Cursor.LaneCursors[Lane] < Params.FechaBase then
              Cursor.LaneCursors[Lane] := Params.FechaBase;

            StartDT := Cursor.Cal.NextWorkingTime(Cursor.LaneCursors[Lane]);
            EndDT := Cursor.Cal.AddWorkingMinutes(StartDT, DurMin);
            Cursor.LaneCursors[Lane] := EndDT;

            Output.FechaInicio := StartDT;
            Output.FechaFin := EndDT;

            if (Input.FechaCompromiso <> 0) and (EndDT > Input.FechaCompromiso) then
            begin
              Output.Status := ssFueraPlazo;
              Output.Observaciones := 'Supera FechaCompromiso';
              Inc(Result.TotalFueraPlazo);
            end
            else
            begin
              Output.Status := ssOK;
              Inc(Result.TotalPlanificados);
            end;
          end;
      end;

      // Guardar el cursor actualizado
      Cursors.AddOrSetValue(C.Id, Cursor);

      OutList.Add(Output);
    end;

    Result.Items := OutList.ToArray;
  finally
    CentresMap.Free;
    Cursors.Free;
    OutList.Free;
  end;
end;

end.
