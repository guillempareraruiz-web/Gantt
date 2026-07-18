unit uWbsCargaBand;

{
  Banda de CARGA POR OPERARIO del modulo de Ingenieria.

  Va bajo el Gantt de tareas y comparte su eje de tiempo (mismo zoom y mismo
  scroll horizontal), de modo que cada columna cae exactamente sobre el mismo
  dia que las barras de arriba: se ve de un golpe que persona esta saturada
  cuando, y por que tarea.

  Cada celda = un operario en un dia, coloreada segun su % de ocupacion:
    0%      fondo neutro (no trabaja ese dia)
    1-99%   verde  (tiene hueco)
    100%    ambar  (justo)
    >100%   rojo   (sobrecargado: dos tareas a la vez, o dedicaciones que suman
                    mas de una jornada)

  La ocupacion sale de FS_PL_TaskOperario.Dedicacion (% de jornada) sumada
  sobre las tareas que ese dia estan en curso. Solo se cuentan DIAS LABORABLES
  segun el calendario del modulo: un fin de semana no es un dia sin carga, es
  un dia que no existe para el plan.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Math, System.DateUtils,
  System.Generics.Collections, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  uWbsTypes, uCentreCalendar;

type
  // Una fila de la banda: un operario y su ocupacion dia a dia.
  TCargaFila = record
    OperatorId: Integer;
    Nombre: string;
    // % de ocupacion por dia, indexado igual que FDias.
    Ocupacion: TArray<Double>;
    // Tareas de ese operario, para el tooltip.
    Tareas: TArray<string>;
  end;

  TWbsCargaBand = class(TCustomControl)
  private
    FCarga: TWbsCargaArray;
    FFilas: TArray<TCargaFila>;
    FDias: TArray<TDateTime>;      // dias del rango, solo laborables
    FCalendar: TCentreCalendar;

    // Viewport compartido con el Gantt.
    FStartTime: TDateTime;
    FPxPerMinute: Single;
    FScrollX: Single;

    FAnchoNombres: Integer;
    FAltoFila: Integer;

    procedure Recalcular;
    function XdeFecha(const AFecha: TDateTime): Single;
    function ColorDeOcupacion(const APct: Double): TColor;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;

    // Datos y calendario (el mismo que usa el motor, para no contar dias no
    // laborables como carga cero).
    procedure SetDatos(const ACarga: TWbsCargaArray; ACal: TCentreCalendar;
      const AIni, AFin: TDateTime);
    // Sincroniza el eje de tiempo con el Gantt.
    procedure SetViewport(const AStartTime: TDateTime;
      const APxPerMinute, AScrollX: Single);

    // Ancho de la columna de nombres: debe coincidir con el panel del arbol
    // para que las celdas caigan bajo las barras correctas.
    property AnchoNombres: Integer read FAnchoNombres write FAnchoNombres;
    property AltoFila: Integer read FAltoFila write FAltoFila;
    // Alto necesario para mostrar a todos los operarios.
    function AltoDeseado: Integer;
  end;

implementation

const
  COL_CABECERA   = $00F7F7F7;
  COL_TXT        = $00595959;
  COL_SIN_CARGA  = $00FAFAFA;
  COL_HOLGADO    = $008FCFA8;   // verde: tiene hueco
  COL_JUSTO      = $000090FF;   // ambar: al 100%
  COL_SOBRECARGA = $005050E8;   // rojo: por encima de la jornada
  COL_REJILLA    = $00E0E0E0;

constructor TWbsCargaBand.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  FAnchoNombres := 200;
  FAltoFila := 20;
  FPxPerMinute := 0.05;
end;

function TWbsCargaBand.AltoDeseado: Integer;
begin
  // Cabecera + una fila por operario, con un tope para que no se coma la
  // pantalla si hay mucha gente asignada.
  Result := FAltoFila + Length(FFilas) * FAltoFila + 4;
  Result := Min(Result, FAltoFila * 9);
end;

procedure TWbsCargaBand.SetDatos(const ACarga: TWbsCargaArray;
  ACal: TCentreCalendar; const AIni, AFin: TDateTime);
var
  D: TDateTime;
  L: TList<TDateTime>;
begin
  FCarga := ACarga;
  FCalendar := ACal;

  // Eje de dias: solo LABORABLES. Un sabado no es un dia con carga cero, es un
  // dia que no cuenta, y pintarlo confundiria la lectura de la saturacion.
  L := TList<TDateTime>.Create;
  try
    D := DateOf(AIni);
    while D <= DateOf(AFin) do
    begin
      if (FCalendar = nil) or FCalendar.IsWorkingTime(D + 0.5) then
        L.Add(D);
      D := IncDay(D);
    end;
    FDias := L.ToArray;
  finally
    L.Free;
  end;

  Recalcular;
  Invalidate;
end;

procedure TWbsCargaBand.Recalcular;
var
  I, J, K, Idx: Integer;
  Ops: TDictionary<Integer, Integer>;   // OperatorId -> indice en FFilas
  F: TCargaFila;
begin
  SetLength(FFilas, 0);
  if Length(FCarga) = 0 then Exit;

  Ops := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to High(FCarga) do
    begin
      // Alta del operario la primera vez que aparece.
      if not Ops.TryGetValue(FCarga[I].OperatorId, Idx) then
      begin
        F := Default(TCargaFila);
        F.OperatorId := FCarga[I].OperatorId;
        F.Nombre := FCarga[I].Nombre;
        SetLength(F.Ocupacion, Length(FDias));
        SetLength(FFilas, Length(FFilas) + 1);
        FFilas[High(FFilas)] := F;
        Idx := High(FFilas);
        Ops.Add(FCarga[I].OperatorId, Idx);
      end;

      // Repartir su dedicacion en los dias que dura la tarea. Se ACUMULA: si
      // dos tareas coinciden en un dia, sus dedicaciones se suman, que es
      // justo como se detecta la sobrecarga.
      for J := 0 to High(FDias) do
        if (FDias[J] >= DateOf(FCarga[I].FechaInicio)) and
           (FDias[J] <= DateOf(FCarga[I].FechaFin)) then
          FFilas[Idx].Ocupacion[J] := FFilas[Idx].Ocupacion[J] +
            FCarga[I].Dedicacion;

      // Guardar el nombre de la tarea (para el tooltip), sin repetir.
      K := Length(FFilas[Idx].Tareas);
      SetLength(FFilas[Idx].Tareas, K + 1);
      FFilas[Idx].Tareas[K] := FCarga[I].Caption;
    end;
  finally
    Ops.Free;
  end;
end;

procedure TWbsCargaBand.SetViewport(const AStartTime: TDateTime;
  const APxPerMinute, AScrollX: Single);
begin
  FStartTime := AStartTime;
  FPxPerMinute := APxPerMinute;
  FScrollX := AScrollX;
  Invalidate;
end;

function TWbsCargaBand.XdeFecha(const AFecha: TDateTime): Single;
begin
  // Mismo criterio que el Gantt, para que las columnas caigan bajo las barras.
  Result := (AFecha - FStartTime) * 24 * 60 * FPxPerMinute - FScrollX
            + FAnchoNombres;
end;

function TWbsCargaBand.ColorDeOcupacion(const APct: Double): TColor;
begin
  if APct <= 0 then
    Result := COL_SIN_CARGA
  else if APct > 100.5 then
    Result := COL_SOBRECARGA
  else if APct >= 99.5 then
    Result := COL_JUSTO
  else
    Result := COL_HOLGADO;
end;

procedure TWbsCargaBand.Paint;
var
  I, J, Y: Integer;
  X1, X2: Single;
  Txt: string;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(ClientRect);

  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 8;

  // --- Cabecera ---
  Canvas.Brush.Color := COL_CABECERA;
  Canvas.FillRect(Rect(0, 0, ClientWidth, FAltoFila));
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Color := COL_TXT;
  Canvas.Font.Style := [fsBold];
  Canvas.TextOut(6, 3, 'Carga por operario');
  Canvas.Font.Style := [];

  if Length(FFilas) = 0 then
  begin
    Canvas.Font.Color := clGray;
    Canvas.TextOut(FAnchoNombres + 8, FAltoFila + 6,
      'Ninguna tarea tiene operarios asignados.');
    Exit;
  end;

  // --- Filas ---
  for I := 0 to High(FFilas) do
  begin
    Y := FAltoFila + I * FAltoFila;
    if Y > ClientHeight then Break;

    // Nombre del operario.
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := COL_TXT;
    Txt := FFilas[I].Nombre;
    Canvas.TextOut(6, Y + 3, Txt);

    // Celdas por dia.
    for J := 0 to High(FDias) do
    begin
      X1 := XdeFecha(FDias[J]);
      X2 := XdeFecha(FDias[J] + 1);
      if X2 < FAnchoNombres then Continue;   // fuera por la izquierda
      if X1 > ClientWidth then Break;        // fuera por la derecha
      if X1 < FAnchoNombres then X1 := FAnchoNombres;

      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := ColorDeOcupacion(FFilas[I].Ocupacion[J]);
      Canvas.FillRect(Rect(Round(X1), Y + 1, Round(X2) - 1, Y + FAltoFila - 1));

      // El % solo si la celda es lo bastante ancha para leerlo.
      if (X2 - X1 > 26) and (FFilas[I].Ocupacion[J] > 0) then
      begin
        Canvas.Brush.Style := bsClear;
        Canvas.Font.Color := clBlack;
        Canvas.TextOut(Round(X1) + 3, Y + 3,
          Format('%.0f', [FFilas[I].Ocupacion[J]]));
      end;
    end;

    // Separador de fila.
    Canvas.Pen.Color := COL_REJILLA;
    Canvas.MoveTo(0, Y + FAltoFila - 1);
    Canvas.LineTo(ClientWidth, Y + FAltoFila - 1);
  end;

  // Separador de la columna de nombres.
  Canvas.Pen.Color := COL_REJILLA;
  Canvas.MoveTo(FAnchoNombres, 0);
  Canvas.LineTo(FAnchoNombres, ClientHeight);
end;

end.
