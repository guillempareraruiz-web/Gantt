unit uWbsPanelEsfuerzo;

{
  Panel de ESFUERZO del proyecto (Modulo de Ingenieria, paradigma TAREAS).

  Responde a la pregunta que ni el grid ni el Gantt contestan: cuanto trabajo
  hay comprometido, cuanto se ha consumido ya y quien lo esta soportando. El
  Gantt dice CUANDO pasan las cosas; esto dice CUANTO cuestan.

  Tres bloques:
    1. Totales del plan   trabajo planificado / invertido / restante, con la
                          desviacion frente a la linea base si la hay.
    2. Por persona        carga de cada operario, con su pico de sobreasignacion
                          (lo que convierte el % de dedicacion en accionable).
    3. Por tarea          las que mas se desvian, que es donde mirar primero.

  El dialogo NO consulta la BD: recibe lo que la vista ya tiene cargado. Asi no
  duplica criterios (que es una hoja, que cuenta como avance) ni paga un segundo
  viaje por algo que esta en memoria.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  System.Generics.Collections, System.Generics.Defaults,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxClasses, cxEdit, cxGridLevel, cxGridCustomTableView,
  cxGridTableView, cxGrid, cxButtons,
  uWbsTypes;

type
  // Entrada del panel: lo que la vista ya tiene en memoria.
  TWbsEsfuerzoInput = record
    Titulo: string;                    // nombre del proyecto (o "N proyectos")
    Tareas: TWbsTaskArray;
    Cargas: TWbsCargaArray;            // asignaciones (operario x tarea)
    Sobrecargas: TWbsSobrecargaArray;
    // Desvios contra la linea base, si la hay. Puede venir nil.
    Desvios: TDictionary<Integer, TWbsDesvio>;
    JornadaMin: Integer;
  end;

  TfrmWbsPanelEsfuerzo = class(TForm)
  private
    FLblTitulo: TLabel;
    FPnlTotales: TPanel;
    FGridPersonas: TcxGrid;
    FLvlPersonas: TcxGridLevel;
    FTvPersonas: TcxGridTableView;
    FColPersona: TcxGridColumn;
    FColPlan: TcxGridColumn;
    FColInvertido: TcxGridColumn;
    FColPico: TcxGridColumn;
    FGridTareas: TcxGrid;
    FLvlTareas: TcxGridLevel;
    FTvTareas: TcxGridTableView;
    FColTarea: TcxGridColumn;
    FColTrabajo: TcxGridColumn;
    FColInv: TcxGridColumn;
    FColDesv: TcxGridColumn;
    FBtnCerrar: TcxButton;

    FData: TWbsEsfuerzoInput;

    procedure BuildUI;
    procedure PintarTotales;
    procedure LlenarPersonas;
    procedure LlenarTareas;
    // Etiqueta con estilo de KPI: valor grande arriba, rotulo pequeno debajo.
    procedure TarjetaKPI(AX: Integer; const ARotulo, AValor: string;
      AColor: TColor);
  public
    class procedure Execute(const ADatos: TWbsEsfuerzoInput);
  end;

implementation

const
  MARGEN = 16;
  ANCHO_TARJETA = 150;

type
  // Acumulado por persona, para el bloque 2.
  TAcumPersona = record
    OperatorId: Integer;
    Nombre: string;
    PlanMin: Double;        // trabajo que le toca segun su dedicacion
    InvertidoMin: Double;
    Pico: Double;           // % maximo de sobreasignacion
    NumTareas: Integer;
  end;

{ TfrmWbsPanelEsfuerzo }

class procedure TfrmWbsPanelEsfuerzo.Execute(const ADatos: TWbsEsfuerzoInput);
var
  F: TfrmWbsPanelEsfuerzo;
begin
  F := TfrmWbsPanelEsfuerzo.Create(nil);
  try
    F.FData := ADatos;
    if F.FData.JornadaMin <= 0 then F.FData.JornadaMin := 480;
    F.BuildUI;
    F.PintarTotales;
    F.LlenarPersonas;
    F.LlenarTareas;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmWbsPanelEsfuerzo.BuildUI;
begin
  Caption := 'Esfuerzo del proyecto';
  BorderStyle := bsSizeable;
  Position := poMainFormCenter;
  ClientWidth := 860;
  ClientHeight := 620;
  Color := clWhite;
  Font.Name := 'Segoe UI';
  Font.Size := 9;

  FLblTitulo := TLabel.Create(Self);
  FLblTitulo.Parent := Self;
  FLblTitulo.SetBounds(MARGEN, 12, 700, 26);
  FLblTitulo.Font.Size := 14;
  FLblTitulo.Font.Style := [fsBold];
  FLblTitulo.Caption := FData.Titulo;

  // --- Bloque 1: tarjetas de totales ---
  FPnlTotales := TPanel.Create(Self);
  FPnlTotales.Parent := Self;
  FPnlTotales.SetBounds(MARGEN, 46, ClientWidth - MARGEN * 2, 74);
  FPnlTotales.BevelOuter := bvNone;
  FPnlTotales.Color := clWhite;
  FPnlTotales.ParentBackground := False;
  FPnlTotales.Anchors := [akLeft, akTop, akRight];

  // --- Bloque 2: por persona ---
  with TLabel.Create(Self) do
  begin
    Parent := Self;
    SetBounds(MARGEN, 132, 400, 18);
    Font.Style := [fsBold];
    Caption := 'Carga por persona';
  end;

  FGridPersonas := TcxGrid.Create(Self);
  FGridPersonas.Parent := Self;
  FGridPersonas.SetBounds(MARGEN, 152, ClientWidth - MARGEN * 2, 180);
  FGridPersonas.Anchors := [akLeft, akTop, akRight];
  FLvlPersonas := FGridPersonas.Levels.Add;
  FTvPersonas := FGridPersonas.CreateView(TcxGridTableView) as TcxGridTableView;
  FLvlPersonas.GridView := FTvPersonas;
  FTvPersonas.OptionsData.Editing := False;
  FTvPersonas.OptionsData.Deleting := False;
  FTvPersonas.OptionsSelection.CellSelect := False;
  FTvPersonas.OptionsView.GroupByBox := False;

  FColPersona := FTvPersonas.CreateColumn;
  FColPersona.Caption := 'Operario';
  FColPersona.Width := 240;
  FColPlan := FTvPersonas.CreateColumn;
  FColPlan.Caption := 'Trabajo asignado';
  FColPlan.Width := 130;
  FColInvertido := FTvPersonas.CreateColumn;
  FColInvertido.Caption := 'Invertido';
  FColInvertido.Width := 110;
  FColPico := FTvPersonas.CreateColumn;
  FColPico.Caption := 'Pico de carga';
  FColPico.Width := 130;

  // --- Bloque 3: tareas que mas se desvian ---
  with TLabel.Create(Self) do
  begin
    Parent := Self;
    SetBounds(MARGEN, 344, 400, 18);
    Font.Style := [fsBold];
    Caption := 'Tareas con mayor desviaci'#243'n';
  end;

  FGridTareas := TcxGrid.Create(Self);
  FGridTareas.Parent := Self;
  FGridTareas.SetBounds(MARGEN, 364, ClientWidth - MARGEN * 2, 200);
  FGridTareas.Anchors := [akLeft, akTop, akRight, akBottom];
  FLvlTareas := FGridTareas.Levels.Add;
  FTvTareas := FGridTareas.CreateView(TcxGridTableView) as TcxGridTableView;
  FLvlTareas.GridView := FTvTareas;
  FTvTareas.OptionsData.Editing := False;
  FTvTareas.OptionsData.Deleting := False;
  FTvTareas.OptionsSelection.CellSelect := False;
  FTvTareas.OptionsView.GroupByBox := False;

  FColTarea := FTvTareas.CreateColumn;
  FColTarea.Caption := 'Tarea';
  FColTarea.Width := 300;
  FColTrabajo := FTvTareas.CreateColumn;
  FColTrabajo.Caption := 'Trabajo';
  FColTrabajo.Width := 100;
  FColInv := FTvTareas.CreateColumn;
  FColInv.Caption := 'Invertido';
  FColInv.Width := 100;
  FColDesv := FTvTareas.CreateColumn;
  FColDesv.Caption := 'Desviaci'#243'n';
  FColDesv.Width := 140;

  FBtnCerrar := TcxButton.Create(Self);
  FBtnCerrar.Parent := Self;
  FBtnCerrar.SetBounds(ClientWidth - MARGEN - 90, ClientHeight - 40, 90, 28);
  FBtnCerrar.Anchors := [akRight, akBottom];
  FBtnCerrar.Caption := 'Cerrar';
  FBtnCerrar.ModalResult := mrOk;
  FBtnCerrar.Default := True;
end;

procedure TfrmWbsPanelEsfuerzo.TarjetaKPI(AX: Integer;
  const ARotulo, AValor: string; AColor: TColor);
var
  L: TLabel;
begin
  L := TLabel.Create(Self);
  L.Parent := FPnlTotales;
  L.SetBounds(AX, 4, ANCHO_TARJETA, 30);
  L.Font.Size := 17;
  L.Font.Style := [fsBold];
  L.Font.Color := AColor;
  L.Caption := AValor;

  L := TLabel.Create(Self);
  L.Parent := FPnlTotales;
  L.SetBounds(AX, 38, ANCHO_TARJETA, 16);
  L.Font.Size := 8;
  L.Font.Color := clGray;
  L.Caption := ARotulo;
end;

procedure TfrmWbsPanelEsfuerzo.PintarTotales;
var
  I: Integer;
  PlanMin, InvMin, RestanteMin, BaseMin: Double;
  Desvio: TWbsDesvio;
  PctAvance, PctDesvio: Double;
  ColDesv: TColor;
  X: Integer;
  HayBase: Boolean;
begin
  PlanMin := 0;
  InvMin := 0;
  BaseMin := 0;
  HayBase := False;

  // Solo las HOJAS: sumar tambien los resumenes contaria cada trabajo dos
  // veces (el del resumen ya es el agregado de sus hijos).
  for I := 0 to High(FData.Tareas) do
  begin
    if FData.Tareas[I].Kind = wtkResumen then Continue;
    if FData.Tareas[I].HasChildren then Continue;

    PlanMin := PlanMin + FData.Tareas[I].TrabajoMin;
    InvMin := InvMin + FData.Tareas[I].MinutosInvertidos;

    if (FData.Desvios <> nil) and
       FData.Desvios.TryGetValue(FData.Tareas[I].NodeId, Desvio) and
       Desvio.TieneBaseline then
    begin
      BaseMin := BaseMin + Desvio.BaseTrabajoMin;
      HayBase := True;
    end;
  end;

  RestanteMin := Max(0, PlanMin - InvMin);
  if PlanMin > 0 then PctAvance := InvMin / PlanMin * 100 else PctAvance := 0;

  X := 0;
  TarjetaKPI(X, 'Trabajo planificado',
    Format('%.0f h', [PlanMin / 60]), $00595959);
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(X, Format('Invertido (%.0f %%)', [PctAvance]),
    Format('%.0f h', [InvMin / 60]), $00109010);
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(X, 'Restante', Format('%.0f h', [RestanteMin / 60]), $00CC7A10);
  Inc(X, ANCHO_TARJETA);

  // Sobrecoste de esfuerzo: lo invertido por encima de lo planificado. Es la
  // cifra que duele, y hasta ahora no la daba nadie.
  if InvMin > PlanMin then
    TarjetaKPI(X, 'Exceso sobre el plan',
      Format('+%.0f h', [(InvMin - PlanMin) / 60]), $000000CC)
  else
    TarjetaKPI(X, 'Exceso sobre el plan', '-', $00A0A0A0);
  Inc(X, ANCHO_TARJETA);

  // Desviacion contra la linea base, si esta fijada.
  if HayBase and (BaseMin > 0) then
  begin
    PctDesvio := (PlanMin - BaseMin) / BaseMin * 100;
    if PctDesvio > 5 then ColDesv := $000000CC
    else if PctDesvio < -5 then ColDesv := $00109010
    else ColDesv := $00595959;
    TarjetaKPI(X, 'vs. l'#237'nea base', Format('%+.0f %%', [PctDesvio]), ColDesv);
  end
  else
    TarjetaKPI(X, 'vs. l'#237'nea base', 'sin fijar', $00A0A0A0);
end;

procedure TfrmWbsPanelEsfuerzo.LlenarPersonas;
var
  Acum: TDictionary<Integer, TAcumPersona>;
  A: TAcumPersona;
  Lista: TList<TAcumPersona>;
  I, J, Fila: Integer;
  Dur, Inv, DedicTotal: Double;
  Encontrada: Boolean;

  // Suma de dedicaciones asignadas a una tarea. Es el denominador del
  // prorrateo: repartir el tiempo invertido sobre 100 en vez de sobre este
  // total duplicaria las horas en cuanto haya mas de una persona.
  function DedicacionDeTarea(ANodeId: Integer): Double;
  var
    K: Integer;
  begin
    Result := 0;
    for K := 0 to High(FData.Cargas) do
      if FData.Cargas[K].NodeId = ANodeId then
        Result := Result + FData.Cargas[K].Dedicacion;
  end;

begin
  Acum := TDictionary<Integer, TAcumPersona>.Create;
  Lista := TList<TAcumPersona>.Create;
  try
    for I := 0 to High(FData.Cargas) do
    begin
      if not Acum.TryGetValue(FData.Cargas[I].OperatorId, A) then
      begin
        A := Default(TAcumPersona);
        A.OperatorId := FData.Cargas[I].OperatorId;
        A.Nombre := FData.Cargas[I].Nombre;
      end;

      // Lo que le toca a esta persona de esta tarea: la duracion por su
      // dedicacion. No el trabajo total de la tarea, que se reparte entre
      // todos los asignados.
      Dur := 0;
      Inv := 0;
      Encontrada := False;
      for J := 0 to High(FData.Tareas) do
        if FData.Tareas[J].NodeId = FData.Cargas[I].NodeId then
        begin
          Dur := FData.Tareas[J].DuracionMin;
          Inv := FData.Tareas[J].MinutosInvertidos;
          Encontrada := True;
          Break;
        end;
      if not Encontrada then Continue;

      A.PlanMin := A.PlanMin + Dur * FData.Cargas[I].Dedicacion / 100;

      // El tiempo invertido es de la TAREA, no por persona. Se reparte a
      // PRORRATA de la dedicacion de cada uno sobre el TOTAL asignado a esa
      // tarea, no sobre 100: con dos personas al 100 % cada una, dividir entre
      // 100 imputaria el doble de horas de las que se han invertido y el
      // bloque "por persona" contradiria al de totales.
      DedicTotal := DedicacionDeTarea(FData.Cargas[I].NodeId);
      if DedicTotal > 0 then
        A.InvertidoMin := A.InvertidoMin +
          Inv * FData.Cargas[I].Dedicacion / DedicTotal;

      Inc(A.NumTareas);
      Acum.AddOrSetValue(A.OperatorId, A);
    end;

    // Pico de sobreasignacion de cada uno.
    for I := 0 to High(FData.Sobrecargas) do
      if Acum.TryGetValue(FData.Sobrecargas[I].OperatorId, A) then
      begin
        if FData.Sobrecargas[I].PorcentajePico > A.Pico then
          A.Pico := FData.Sobrecargas[I].PorcentajePico;
        Acum.AddOrSetValue(A.OperatorId, A);
      end;

    for A in Acum.Values do
      Lista.Add(A);

    // Mas cargado primero: es a quien hay que mirar.
    Lista.Sort(TComparer<TAcumPersona>.Construct(
      function(const X, Y: TAcumPersona): Integer
      begin
        Result := CompareValue(Y.PlanMin, X.PlanMin);
      end));

    FTvPersonas.BeginUpdate;
    try
      FTvPersonas.DataController.RecordCount := Lista.Count;
      for Fila := 0 to Lista.Count - 1 do
      begin
        A := Lista[Fila];
        FTvPersonas.DataController.Values[Fila, FColPersona.Index] :=
          Format('%s  (%d tareas)', [A.Nombre, A.NumTareas]);
        FTvPersonas.DataController.Values[Fila, FColPlan.Index] :=
          Format('%.1f h', [A.PlanMin / 60]);
        FTvPersonas.DataController.Values[Fila, FColInvertido.Index] :=
          Format('%.1f h', [A.InvertidoMin / 60]);
        if A.Pico > 100 then
          FTvPersonas.DataController.Values[Fila, FColPico.Index] :=
            Format('%.0f %%  '#$26A0, [A.Pico])
        else
          FTvPersonas.DataController.Values[Fila, FColPico.Index] := 'Correcta';
      end;
    finally
      FTvPersonas.EndUpdate;
    end;
  finally
    Lista.Free;
    Acum.Free;
  end;
end;

procedure TfrmWbsPanelEsfuerzo.LlenarTareas;
var
  I, Fila: Integer;
  Lista: TList<TWbsTask>;
  T: TWbsTask;
  Desvio: TWbsDesvio;
  Exceso: Double;
begin
  Lista := TList<TWbsTask>.Create;
  try
    // Solo hojas con trabajo: los resumenes agregan y falsearian el ranking.
    for I := 0 to High(FData.Tareas) do
    begin
      if FData.Tareas[I].Kind = wtkResumen then Continue;
      if FData.Tareas[I].HasChildren then Continue;
      if (FData.Tareas[I].TrabajoMin <= 0) and
         (FData.Tareas[I].MinutosInvertidos <= 0) then Continue;
      Lista.Add(FData.Tareas[I]);
    end;

    // Ordenar por exceso de horas invertidas sobre el trabajo previsto: lo que
    // se ha comido mas presupuesto, arriba.
    Lista.Sort(TComparer<TWbsTask>.Construct(
      function(const X, Y: TWbsTask): Integer
      begin
        Result := CompareValue(Y.MinutosInvertidos - Y.TrabajoMin,
                               X.MinutosInvertidos - X.TrabajoMin);
      end));

    FTvTareas.BeginUpdate;
    try
      // Un tope: el panel es un resumen, no un listado completo. Las 40 peores
      // son de sobra para decidir donde mirar.
      FTvTareas.DataController.RecordCount := Min(Lista.Count, 40);
      for Fila := 0 to Min(Lista.Count, 40) - 1 do
      begin
        T := Lista[Fila];
        FTvTareas.DataController.Values[Fila, FColTarea.Index] := T.Caption;
        FTvTareas.DataController.Values[Fila, FColTrabajo.Index] :=
          Format('%.1f h', [T.TrabajoMin / 60]);
        FTvTareas.DataController.Values[Fila, FColInv.Index] :=
          Format('%.1f h', [T.MinutosInvertidos / 60]);

        Exceso := T.MinutosInvertidos - T.TrabajoMin;
        if Exceso > 0 then
          FTvTareas.DataController.Values[Fila, FColDesv.Index] :=
            Format('+%.1f h', [Exceso / 60])
        else if (FData.Desvios <> nil) and
                FData.Desvios.TryGetValue(T.NodeId, Desvio) and
                Desvio.TieneBaseline and (Desvio.DesvioFinDias <> 0) then
          // Sin exceso de horas, lo relevante es si se ha ido de fechas.
          FTvTareas.DataController.Values[Fila, FColDesv.Index] :=
            Format('%+d d de plazo', [Desvio.DesvioFinDias])
        else
          FTvTareas.DataController.Values[Fila, FColDesv.Index] := '-';
      end;
    finally
      FTvTareas.EndUpdate;
    end;
  finally
    Lista.Free;
  end;
end;

end.
