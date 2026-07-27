unit uWbsPanelEsfuerzo;

{
  RESUMEN DEL PROYECTO (Modulo de Ingenieria, paradigma TAREAS).

  Contesta "como va el proyecto" en los cuatro ejes que una direccion de
  proyecto pregunta, en este orden:

    1. CALENDARIO  cuando acaba y si llega tarde.
    2. ESFUERZO    cuanto trabajo cuesta y cuanto llevamos.
    3. COSTE       lo mismo en euros.
    4. PROGRESO    en que estado estan las tareas.

  Es el equivalente al "Project Statistics" de MS Project (Actual / Baseline /
  Variance sobre inicio, fin, duracion, trabajo y coste) mas sus informes de
  resumen. Nacio como panel de esfuerzo unicamente, y esa version se quedaba
  corta: hablaba de horas y callaba las fechas y el dinero, que son justo lo
  primero que se mira.

  Cuatro pestanas:
    General   las cifras de los cuatro ejes, en tarjetas.
    Esfuerzo  carga por persona y tareas mas desviadas.
    Costes    el detalle en euros, persona a persona.
    Riesgos   lo que hay que mirar HOY (retrasos, bloqueos, vencimientos).

  El dialogo NO consulta la BD ni calcula: recibe lo que la vista ya tiene en
  memoria y delega las cuentas en uWbsResumen. Aqui solo se pinta.

  Lo unico que se crea por codigo son las TARJETAS KPI: su numero depende de lo
  que haya que ensenar y su color cambia con el valor, asi que se pintan sobre
  los paneles contenedores que declara el .dfm.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  System.DateUtils, System.Generics.Collections, System.Generics.Defaults,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxClasses, cxEdit, cxGridLevel, cxGridCustomTableView,
  cxGridTableView, cxGrid, cxButtons, cxContainer, cxPC,
  dxSkinsCore, dxSkinsDefaultPainters,
  // TeCanvas: constantes de degradado (gdTopBottom).
  // TeeGDIPlus: render suavizado (TGDIPlusCanvas), como en Analisis del plan.
  VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.Series,
  VCLTee.TeCanvas, VCLTee.TeeGDIPlus,
  uWbsTypes, uWbsResumen;

type
  // Entrada del panel: lo que la vista ya tiene en memoria.
  TWbsEsfuerzoInput = record
    Titulo: string;                    // nombre del proyecto (o "N proyectos")
    Tareas: TWbsTaskArray;
    Cargas: TWbsCargaArray;            // asignaciones (operario x tarea)
    Sobrecargas: TWbsSobrecargaArray;
    // Desvios contra la linea base, si la hay. Puede venir nil.
    Desvios: TDictionary<Integer, TWbsDesvio>;
    // Estado declarado de cada tarea (FS_PL_TaskDetail). Puede venir nil: sin
    // el, el estado se deduce de las horas invertidas.
    Estados: TDictionary<Integer, Integer>;
    // Tareas en el camino critico. Lo sabe el motor, no la tarea, asi que lo
    // pasa la vista en vez de recalcular aqui el CPM.
    NumCriticas: Integer;
    JornadaMin: Integer;
  end;

  TfrmWbsPanelEsfuerzo = class(TForm)
    pnlHeader: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlBottom: TPanel;
    btnCerrar: TcxButton;
    pc: TcxPageControl;
    tsGeneral: TcxTabSheet;
    pnlCalendario: TPanel;
    lblCalendario: TLabel;
    pnlEsfuerzoKpi: TPanel;
    lblEsfuerzoKpi: TLabel;
    pnlCosteKpi: TPanel;
    lblCosteKpi: TLabel;
    pnlProgreso: TPanel;
    lblProgreso: TLabel;
    tsEsfuerzo: TcxTabSheet;
    pnlPersonas: TPanel;
    lblPersonas: TLabel;
    gridPersonas: TcxGrid;
    tvPersonas: TcxGridTableView;
    colPersona: TcxGridColumn;
    colPlan: TcxGridColumn;
    colInvertido: TcxGridColumn;
    colCostePersona: TcxGridColumn;
    colPico: TcxGridColumn;
    lvlPersonas: TcxGridLevel;
    pnlTareas: TPanel;
    lblTareas: TLabel;
    gridTareas: TcxGrid;
    tvTareas: TcxGridTableView;
    colTarea: TcxGridColumn;
    colTrabajo: TcxGridColumn;
    colInv: TcxGridColumn;
    colDesv: TcxGridColumn;
    lvlTareas: TcxGridLevel;
    tsCostes: TcxTabSheet;
    lblCostes: TLabel;
    lblAvisoTarifas: TLabel;
    gridCostes: TcxGrid;
    tvCostes: TcxGridTableView;
    colCostePersonaNom: TcxGridColumn;
    colTarifa: TcxGridColumn;
    colHorasPlan: TcxGridColumn;
    colCostePlan: TcxGridColumn;
    colHorasReal: TcxGridColumn;
    colCosteReal: TcxGridColumn;
    lvlCostes: TcxGridLevel;
    tsCurva: TcxTabSheet;
    pnlCurvaTop: TPanel;
    lblCurva: TLabel;
    lblCurvaNota: TLabel;
    pnlCurva: TPanel;
    tsRiesgos: TcxTabSheet;
    lblRiesgos: TLabel;
    gridRiesgos: TcxGrid;
    tvRiesgos: TcxGridTableView;
    colRiesgoTipo: TcxGridColumn;
    colRiesgoTarea: TcxGridColumn;
    colRiesgoFecha: TcxGridColumn;
    colRiesgoDetalle: TcxGridColumn;
    lvlRiesgos: TcxGridLevel;
  private
    FData: TWbsEsfuerzoInput;
    FResumen: TWbsResumen;
    // El grafico se crea por codigo (como en uPlanAnalisis): un TChart en el
    // .dfm arrastra decenas de propiedades de estilo que el disenador reescribe
    // y que aqui se fijan de una vez en ConstruirCurva.
    FChart: TChart;

    procedure ConstruirCurva;
    procedure PintarCurva;
    procedure PintarCalendario;
    procedure PintarEsfuerzo;
    procedure PintarCoste;
    procedure PintarProgreso;
    procedure LlenarPersonas;
    procedure LlenarTareas;
    procedure LlenarCostes;
    procedure LlenarRiesgos;
    // Tarjeta KPI sobre un panel: valor grande arriba, rotulo pequeno debajo.
    // AFila permite una segunda hilera de tarjetas en el mismo panel.
    procedure TarjetaKPI(APanel: TPanel; AX: Integer;
      const ARotulo, AValor: string; AColor: TColor; AFila: Integer = 0);
    procedure LimpiarPanel(APanel: TPanel);
  public
    class procedure Execute(const ADatos: TWbsEsfuerzoInput);
  end;

implementation

{$R *.dfm}

uses
  uHelpViewer;

const
  MARGEN = 16;
  ANCHO_TARJETA = 150;
  // Y de la primera linea de tarjetas dentro de su panel (bajo el rotulo del
  // bloque, que el .dfm pone en Y=8).
  TARJETA_TOP = 30;
  // Separacion entre hileras de tarjetas (valor 30 + rotulo 16 + aire).
  ALTO_FILA_KPI = 76;

  // Paleta, en BGR como pide TColor.
  COL_NEUTRO = $00595959;
  COL_BUENO  = $00109010;
  COL_AVISO  = $00CC7A10;
  COL_MALO   = $000000CC;
  COL_APAGADO = $00A0A0A0;

{ TfrmWbsPanelEsfuerzo }

class procedure TfrmWbsPanelEsfuerzo.Execute(const ADatos: TWbsEsfuerzoInput);
var
  F: TfrmWbsPanelEsfuerzo;
  Input: TWbsResumenInput;
begin
  F := TfrmWbsPanelEsfuerzo.Create(nil);
  try
    F.FData := ADatos;
    if F.FData.JornadaMin <= 0 then F.FData.JornadaMin := 480;

    // Todas las cuentas, en un solo sitio y de una sola vez.
    Input := Default(TWbsResumenInput);
    Input.Titulo := F.FData.Titulo;
    Input.Tareas := F.FData.Tareas;
    Input.Cargas := F.FData.Cargas;
    Input.Sobrecargas := F.FData.Sobrecargas;
    Input.Desvios := F.FData.Desvios;
    Input.Estados := F.FData.Estados;
    Input.JornadaMin := F.FData.JornadaMin;
    Input.Hoy := Date;
    F.FResumen := CalcularResumen(Input);
    F.FResumen.Progreso.Criticas := F.FData.NumCriticas;

    // El titulo lo fija el .dfm (es el nombre del panel); el subtitulo lleva
    // el proyecto, que es lo que cambia.
    F.lblSubtitulo.Caption := F.FData.Titulo;

    // Ayuda contextual: el boton '?' del caption y F1. Sin esta llamada el
    // boton se dibuja (BorderIcons lo trae del .dfm) pero no hace nada.
    THelpViewer.InstallHelp(F, 'uWbsPanelEsfuerzo', 'Resumen del proyecto');

    F.ConstruirCurva;

    F.PintarCalendario;
    F.PintarEsfuerzo;
    F.PintarCoste;
    F.PintarProgreso;
    F.LlenarPersonas;
    F.LlenarTareas;
    F.LlenarCostes;
    F.PintarCurva;
    F.LlenarRiesgos;

    F.pc.ActivePage := F.tsGeneral;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmWbsPanelEsfuerzo.LimpiarPanel(APanel: TPanel);
var
  I: Integer;
begin
  // Las etiquetas de las tarjetas tienen el panel como Owner; el rotulo del
  // bloque viene del .dfm y su Owner es el FORM, asi que sobrevive.
  for I := APanel.ControlCount - 1 downto 0 do
    if APanel.Controls[I].Owner = APanel then
      APanel.Controls[I].Free;
end;

procedure TfrmWbsPanelEsfuerzo.TarjetaKPI(APanel: TPanel; AX: Integer;
  const ARotulo, AValor: string; AColor: TColor; AFila: Integer);
var
  L: TLabel;
  Y: Integer;
begin
  Y := TARJETA_TOP + AFila * ALTO_FILA_KPI;

  // Owner = el panel, para poder vaciarlo sin tocar lo que trae el .dfm.
  L := TLabel.Create(APanel);
  L.Parent := APanel;
  L.SetBounds(AX, Y, ANCHO_TARJETA, 30);
  L.Font.Name := 'Segoe UI';
  L.Font.Size := 16;
  L.Font.Style := [fsBold];
  L.Font.Color := AColor;
  L.ParentFont := False;
  L.Caption := AValor;

  L := TLabel.Create(APanel);
  L.Parent := APanel;
  L.SetBounds(AX, Y + 32, ANCHO_TARJETA, 16);
  L.Font.Name := 'Segoe UI';
  L.Font.Size := 8;
  L.Font.Color := clGray;
  L.ParentFont := False;
  L.Caption := ARotulo;
end;

procedure TfrmWbsPanelEsfuerzo.PintarCalendario;
var
  X: Integer;
  C: TWbsResumenCalendario;
  Col: TColor;
begin
  LimpiarPanel(pnlCalendario);
  C := FResumen.Calendario;
  X := MARGEN;

  if C.Inicio > 0 then
    TarjetaKPI(pnlCalendario, X, 'Inicio',
      FormatDateTime('dd/mm/yyyy', C.Inicio), COL_NEUTRO)
  else
    TarjetaKPI(pnlCalendario, X, 'Inicio', '-', COL_APAGADO);
  Inc(X, ANCHO_TARJETA);

  // El fin se colorea segun la linea base: es la cifra que dice si el proyecto
  // llega a tiempo, y sin color hay que leer dos tarjetas para saberlo.
  if C.Fin > 0 then
  begin
    if C.TieneBaseline and (C.DesvioFinDias > 0) then Col := COL_MALO
    else if C.TieneBaseline then Col := COL_BUENO
    else Col := COL_NEUTRO;
    TarjetaKPI(pnlCalendario, X, 'Fin previsto',
      FormatDateTime('dd/mm/yyyy', C.Fin), Col);
  end
  else
    TarjetaKPI(pnlCalendario, X, 'Fin previsto', '-', COL_APAGADO);
  Inc(X, ANCHO_TARJETA);

  if C.TieneBaseline then
  begin
    if C.DesvioFinDias > 0 then
      TarjetaKPI(pnlCalendario, X, 'vs. l'#237'nea base',
        Format('+%d d', [C.DesvioFinDias]), COL_MALO)
    else if C.DesvioFinDias < 0 then
      TarjetaKPI(pnlCalendario, X, 'vs. l'#237'nea base',
        Format('%d d', [C.DesvioFinDias]), COL_BUENO)
    else
      TarjetaKPI(pnlCalendario, X, 'vs. l'#237'nea base', 'En fecha', COL_BUENO);
  end
  else
    TarjetaKPI(pnlCalendario, X, 'vs. l'#237'nea base', 'sin fijar', COL_APAGADO);
  Inc(X, ANCHO_TARJETA);

  // Dias restantes en negativo = el proyecto ya deberia haber acabado. Es una
  // situacion distinta de "quedan pocos dias" y merece otro rotulo.
  if C.DiasRestantes < 0 then
    TarjetaKPI(pnlCalendario, X, 'Fuera de plazo',
      Format('%d d', [Abs(C.DiasRestantes)]), COL_MALO)
  else
    TarjetaKPI(pnlCalendario, X, 'D'#237'as restantes',
      IntToStr(C.DiasRestantes), IfThen(C.DiasRestantes <= 7, COL_AVISO,
        COL_NEUTRO));
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(pnlCalendario, X, 'Calendario consumido',
    Format('%.0f %%', [C.PctTiempoConsumido]), COL_NEUTRO);
end;

procedure TfrmWbsPanelEsfuerzo.PintarEsfuerzo;
var
  X: Integer;
  E: TWbsResumenEsfuerzo;
begin
  LimpiarPanel(pnlEsfuerzoKpi);
  E := FResumen.Esfuerzo;
  X := MARGEN;

  TarjetaKPI(pnlEsfuerzoKpi, X, 'Trabajo planificado',
    FormatHoras(E.PlanMin), COL_NEUTRO);
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(pnlEsfuerzoKpi, X,
    Format('Invertido (%.0f %%)', [FResumen.Progreso.PctCompletado]),
    FormatHoras(E.InvertidoMin), COL_BUENO);
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(pnlEsfuerzoKpi, X, 'Restante',
    FormatHoras(E.RestanteMin), COL_AVISO);
  Inc(X, ANCHO_TARJETA);

  if E.ExcesoMin > 0 then
    TarjetaKPI(pnlEsfuerzoKpi, X, 'Exceso sobre el plan',
      '+' + FormatHoras(E.ExcesoMin), COL_MALO)
  else
    TarjetaKPI(pnlEsfuerzoKpi, X, 'Exceso sobre el plan', '-', COL_APAGADO);
  Inc(X, ANCHO_TARJETA);

  if E.TieneBaseline and (E.BaseMin > 0) then
    TarjetaKPI(pnlEsfuerzoKpi, X, 'vs. l'#237'nea base',
      Format('%+.0f %%', [E.DesvioPct]),
      IfThen(E.DesvioPct > 5, COL_MALO,
        IfThen(E.DesvioPct < -5, COL_BUENO, COL_NEUTRO)))
  else
    TarjetaKPI(pnlEsfuerzoKpi, X, 'vs. l'#237'nea base', 'sin fijar', COL_APAGADO);
end;

procedure TfrmWbsPanelEsfuerzo.PintarCoste;
var
  X: Integer;
  C: TWbsResumenCoste;
begin
  LimpiarPanel(pnlCosteKpi);
  C := FResumen.Coste;
  X := MARGEN;

  // Sin ninguna tarifa poblada, el bloque entero engañaria: cuatro ceros
  // parecen "el proyecto no cuesta nada" cuando significan "no lo se".
  if C.PersonasConTarifa = 0 then
  begin
    TarjetaKPI(pnlCosteKpi, X, 'Coste', 'No calculable', COL_APAGADO);
    Inc(X, ANCHO_TARJETA + 40);
    TarjetaKPI(pnlCosteKpi, X,
      'Ninguna persona asignada tiene tarifa (ficha del operario)', '', clGray);
    Exit;
  end;

  TarjetaKPI(pnlCosteKpi, X, 'Coste planificado',
    FormatEuros(C.PlanEur), COL_NEUTRO);
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(pnlCosteKpi, X, 'Incurrido',
    FormatEuros(C.IncurridoEur), COL_BUENO);
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(pnlCosteKpi, X, 'Restante',
    FormatEuros(C.RestanteEur), COL_AVISO);
  Inc(X, ANCHO_TARJETA);

  if C.DesviacionEur > 0 then
    TarjetaKPI(pnlCosteKpi, X, 'Desviaci'#243'n',
      '+' + FormatEuros(C.DesviacionEur), COL_MALO)
  else
    TarjetaKPI(pnlCosteKpi, X, 'Desviaci'#243'n', 'En presupuesto', COL_BUENO);
  Inc(X, ANCHO_TARJETA);

  // Cuando faltan tarifas se dice aqui, no en un aviso escondido: la cifra de
  // arriba es incompleta y hay que saberlo al leerla.
  if C.PersonasSinTarifa > 0 then
    TarjetaKPI(pnlCosteKpi, X, 'Personas sin tarifa',
      IntToStr(C.PersonasSinTarifa), COL_AVISO)
  else
    TarjetaKPI(pnlCosteKpi, X, 'Personas sin tarifa', '-', COL_APAGADO);
end;

procedure TfrmWbsPanelEsfuerzo.PintarProgreso;
var
  X: Integer;
  P: TWbsResumenProgreso;
begin
  LimpiarPanel(pnlProgreso);
  P := FResumen.Progreso;
  X := MARGEN;

  TarjetaKPI(pnlProgreso, X, 'Tareas', IntToStr(P.Total), COL_NEUTRO);
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(pnlProgreso, X, 'Completado',
    Format('%.0f %%', [Min(100, P.PctCompletado)]), COL_BUENO);
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(pnlProgreso, X, 'Hechas / en curso',
    Format('%d / %d', [P.Hechas, P.EnCurso]), COL_NEUTRO);
  Inc(X, ANCHO_TARJETA);

  if P.Retrasadas > 0 then
    TarjetaKPI(pnlProgreso, X, 'Retrasadas',
      IntToStr(P.Retrasadas), COL_MALO)
  else
    TarjetaKPI(pnlProgreso, X, 'Retrasadas', '0', COL_BUENO);
  Inc(X, ANCHO_TARJETA);

  if P.Bloqueadas > 0 then
    TarjetaKPI(pnlProgreso, X, 'Bloqueadas',
      IntToStr(P.Bloqueadas), COL_MALO)
  else
    TarjetaKPI(pnlProgreso, X, 'Bloqueadas', '0', COL_BUENO);

  // Segunda hilera: camino critico e hitos.
  X := MARGEN;
  TarjetaKPI(pnlProgreso, X, 'En camino cr'#237'tico',
    IntToStr(P.Criticas), IfThen(P.Criticas > 0, COL_AVISO, COL_NEUTRO), 1);
  Inc(X, ANCHO_TARJETA);

  TarjetaKPI(pnlProgreso, X, 'Hitos', IntToStr(P.Hitos), COL_NEUTRO, 1);
  Inc(X, ANCHO_TARJETA);

  if P.HitosPasados > 0 then
    TarjetaKPI(pnlProgreso, X, 'Hitos vencidos',
      IntToStr(P.HitosPasados), COL_MALO, 1)
  else
    TarjetaKPI(pnlProgreso, X, 'Hitos vencidos', '0', COL_BUENO, 1);
  Inc(X, ANCHO_TARJETA);

  if P.Canceladas > 0 then
    TarjetaKPI(pnlProgreso, X, 'Canceladas',
      IntToStr(P.Canceladas), COL_APAGADO, 1);
end;

procedure TfrmWbsPanelEsfuerzo.LlenarPersonas;
var
  I: Integer;
  P: TWbsResumenPersona;
begin
  tvPersonas.BeginUpdate;
  try
    tvPersonas.DataController.RecordCount := Length(FResumen.Personas);
    for I := 0 to High(FResumen.Personas) do
    begin
      P := FResumen.Personas[I];
      tvPersonas.DataController.Values[I, colPersona.Index] :=
        Format('%s  (%d tareas)', [P.Nombre, P.NumTareas]);
      tvPersonas.DataController.Values[I, colPlan.Index] :=
        FormatHoras(P.PlanMin);
      tvPersonas.DataController.Values[I, colInvertido.Index] :=
        FormatHoras(P.InvertidoMin);
      if P.CosteHora > 0 then
        tvPersonas.DataController.Values[I, colCostePersona.Index] :=
          FormatEuros(P.PlanEur)
      else
        tvPersonas.DataController.Values[I, colCostePersona.Index] :=
          'sin tarifa';
      if P.Pico > 100 then
        tvPersonas.DataController.Values[I, colPico.Index] :=
          Format('%.0f %%  '#$26A0, [P.Pico])
      else
        tvPersonas.DataController.Values[I, colPico.Index] := 'Correcta';
    end;
  finally
    tvPersonas.EndUpdate;
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

    // Por exceso de horas sobre lo previsto: lo que mas presupuesto se ha
    // comido, arriba.
    Lista.Sort(TComparer<TWbsTask>.Construct(
      function(const X, Y: TWbsTask): Integer
      begin
        Result := CompareValue(Y.MinutosInvertidos - Y.TrabajoMin,
                               X.MinutosInvertidos - X.TrabajoMin);
      end));

    tvTareas.BeginUpdate;
    try
      // Un tope: esto es un resumen, no un listado. Las 40 peores bastan para
      // decidir donde mirar.
      tvTareas.DataController.RecordCount := Min(Lista.Count, 40);
      for Fila := 0 to Min(Lista.Count, 40) - 1 do
      begin
        T := Lista[Fila];
        tvTareas.DataController.Values[Fila, colTarea.Index] := T.Caption;
        tvTareas.DataController.Values[Fila, colTrabajo.Index] :=
          FormatHoras(T.TrabajoMin);
        tvTareas.DataController.Values[Fila, colInv.Index] :=
          FormatHoras(T.MinutosInvertidos);

        Exceso := T.MinutosInvertidos - T.TrabajoMin;
        if Exceso > 0 then
          tvTareas.DataController.Values[Fila, colDesv.Index] :=
            '+' + FormatHoras(Exceso)
        else if (FData.Desvios <> nil) and
                FData.Desvios.TryGetValue(T.NodeId, Desvio) and
                Desvio.TieneBaseline and (Desvio.DesvioFinDias <> 0) then
          // Sin exceso de horas, lo relevante es si se ha ido de fechas.
          tvTareas.DataController.Values[Fila, colDesv.Index] :=
            Format('%+d d de plazo', [Desvio.DesvioFinDias])
        else
          tvTareas.DataController.Values[Fila, colDesv.Index] := '-';
      end;
    finally
      tvTareas.EndUpdate;
    end;
  finally
    Lista.Free;
  end;
end;

procedure TfrmWbsPanelEsfuerzo.LlenarCostes;
var
  I: Integer;
  P: TWbsResumenPersona;
begin
  tvCostes.BeginUpdate;
  try
    tvCostes.DataController.RecordCount := Length(FResumen.Personas);
    for I := 0 to High(FResumen.Personas) do
    begin
      P := FResumen.Personas[I];
      tvCostes.DataController.Values[I, colCostePersonaNom.Index] := P.Nombre;
      if P.CosteHora > 0 then
        tvCostes.DataController.Values[I, colTarifa.Index] :=
          Format('%.2f '#8364'/h', [P.CosteHora])
      else
        tvCostes.DataController.Values[I, colTarifa.Index] := 'sin tarifa';
      tvCostes.DataController.Values[I, colHorasPlan.Index] :=
        FormatHoras(P.PlanMin);
      tvCostes.DataController.Values[I, colHorasReal.Index] :=
        FormatHoras(P.InvertidoMin);
      if P.CosteHora > 0 then
      begin
        tvCostes.DataController.Values[I, colCostePlan.Index] :=
          FormatEuros(P.PlanEur);
        tvCostes.DataController.Values[I, colCosteReal.Index] :=
          FormatEuros(P.IncurridoEur);
      end
      else
      begin
        tvCostes.DataController.Values[I, colCostePlan.Index] := '-';
        tvCostes.DataController.Values[I, colCosteReal.Index] := '-';
      end;
    end;
  finally
    tvCostes.EndUpdate;
  end;

  if FResumen.Coste.PersonasSinTarifa > 0 then
    lblAvisoTarifas.Caption := Format(
      #$26A0' %d persona(s) sin tarifa: sus %s no entran en el coste. ' +
      'La tarifa se rellena en la ficha del operario.',
      [FResumen.Coste.PersonasSinTarifa,
       FormatHoras(FResumen.Coste.MinSinTarifa)])
  else
    lblAvisoTarifas.Caption :=
      'El coste sale de la tarifa por hora de cada persona asignada ' +
      '(ficha del operario).';
end;

procedure TfrmWbsPanelEsfuerzo.ConstruirCurva;
var
  Gp: TGDIPlusCanvas;
begin
  // Mismo estilo PRO que los graficos de Analisis del plan: GDI+ con
  // antialiasing, fondo en degradado suave y rejilla fina.
  FChart := TChart.Create(Self);
  FChart.Parent := pnlCurva;
  FChart.Align := alClient;

  // Render GDI+ en lugar del GDI clasico: sin esto la curva sale con los
  // bordes dentados y desentona con el resto de graficos del producto.
  Gp := TGDIPlusCanvas.Create;
  Gp.AntiAlias := True;
  Gp.AntiAliasText := gpfClearType;
  FChart.Canvas := Gp;
  FChart.BevelOuter := bvNone;
  FChart.View3D := False;
  FChart.Color := clWhite;
  FChart.Title.Visible := False;

  FChart.Legend.Visible := True;
  FChart.Legend.Alignment := laTop;
  FChart.Legend.LegendStyle := lsSeries;
  FChart.Legend.Font.Name := 'Segoe UI';
  FChart.Legend.Font.Size := 8;
  FChart.Legend.Shadow.Visible := False;
  FChart.Legend.Frame.Visible := False;
  FChart.Legend.Transparent := True;

  FChart.Gradient.Visible := True;
  FChart.Gradient.Direction := gdTopBottom;
  FChart.Gradient.StartColor := clWhite;
  FChart.Gradient.EndColor := $00F7F4EE;
  FChart.BackWall.Color := $00FCFAF4;
  FChart.BackWall.Brush.Color := $00FCFAF4;
  FChart.BackWall.Pen.Visible := False;
  FChart.BackWall.Size := 0;
  FChart.Walls.Visible := False;

  FChart.LeftAxis.Grid.Color := $00E4E0D8;
  FChart.LeftAxis.Grid.SmallDots := True;
  FChart.LeftAxis.Axis.Color := $00C0BCB4;
  FChart.LeftAxis.Title.Caption := 'Horas';
  FChart.LeftAxis.Title.Font.Name := 'Segoe UI';
  FChart.LeftAxis.Title.Font.Size := 8;
  FChart.BottomAxis.Grid.Color := $00E4E0D8;
  FChart.BottomAxis.Grid.SmallDots := True;
  FChart.BottomAxis.Axis.Color := $00C0BCB4;
  FChart.BottomAxis.LabelsAngle := 90;
  FChart.BottomAxis.LabelsFont.Name := 'Segoe UI';
  FChart.BottomAxis.LabelsFont.Size := 7;

  FChart.MarginLeft := 3;
  FChart.MarginRight := 3;
  FChart.MarginTop := 3;
  FChart.MarginBottom := 3;
end;

procedure TfrmWbsPanelEsfuerzo.PintarCurva;
var
  Area: TAreaSeries;
  LinReal: TPointSeries;
  I, Paso: Integer;
  C: TWbsResumenCurva;
  Etiqueta: string;
begin
  C := FResumen.Curva;

  if not C.HayDatos then
  begin
    lblCurva.Caption := 'Avance del trabajo';
    lblCurvaNota.Caption :=
      'No hay datos suficientes: hacen falta tareas con fechas y trabajo ' +
      'estimado.';
    Exit;
  end;

  FChart.RemoveAllSeries;

  // Curva PREVISTA: trabajo que deberia estar hecho en cada fecha. Es un dato,
  // no una estimacion: sale de las fechas y el trabajo de cada tarea.
  Area := TAreaSeries.Create(FChart);
  Area.Title := 'Previsto';
  Area.Color := $00C89A18;         // azul apagado
  Area.Transparency := 55;
  Area.LinePen.Width := 2;
  Area.LinePen.Color := $00C89A18;
  Area.Marks.Visible := False;
  Area.Pointer.Visible := False;
  FChart.AddSeries(Area);

  // Real: UN SOLO punto, el de hoy. Ver el comentario largo de TWbsPuntoCurva
  // en uWbsResumen: la trayectoria pasada no se puede saber (MinutosInvertidos
  // no lleva fecha) y dibujarla seria inventarsela. Por eso es un PUNTO suelto
  // sobre la curva prevista y no una linea: una linea sugeriria un historico
  // que nadie ha medido.
  LinReal := TPointSeries.Create(FChart);
  LinReal.Title := 'Dedicado hoy';
  LinReal.Color := $00109010;
  LinReal.Pointer.Style := psCircle;
  LinReal.Pointer.HorizSize := 7;
  LinReal.Pointer.VertSize := 7;
  LinReal.Pointer.Color := $00109010;
  LinReal.Pointer.Pen.Color := clWhite;
  LinReal.Pointer.Pen.Width := 2;
  LinReal.Marks.Visible := False;
  FChart.AddSeries(LinReal);

  // Con muchas semanas, no etiquetar todas: se solapan y no se lee ninguna.
  Paso := Max(1, Length(C.Puntos) div 26);

  for I := 0 to High(C.Puntos) do
  begin
    if (I mod Paso = 0) or C.Puntos[I].EsHoy then
      Etiqueta := C.Puntos[I].Etiqueta
    else
      Etiqueta := '';

    Area.Add(C.Puntos[I].PrevistoAcumMin / 60, Etiqueta, Area.Color);

    // El punto real se coloca en la MISMA posicion del eje X que la semana en
    // curso, para que se lea como "aqui estamos respecto a la curva".
    if C.Puntos[I].EsHoy then
      LinReal.AddXY(I, C.RealAcumMin / 60, Etiqueta, LinReal.Color);
  end;

  // Proyecto ya terminado: la semana de hoy no esta en el eje, asi que el punto
  // se ancla al final de la curva. Sin esto no se pintaria ninguno.
  if C.Terminado and (LinReal.Count = 0) and (Length(C.Puntos) > 0) then
    LinReal.AddXY(High(C.Puntos), C.RealAcumMin / 60, '', LinReal.Color);

  // El titulo resume el grafico en una frase: es lo que se lee primero y a
  // menudo lo unico que se lee, asi que no puede mentir.
  //
  // Los dos casos de borde importan mas de lo que parece: en un proyecto que
  // AUN NO HA EMPEZADO lo previsto a dia de hoy es 0, con lo que cualquier hora
  // dedicada saldria como "vas por delante", que es exactamente lo contrario de
  // lo que pasa. Y en uno TERMINADO la cifra ya no es un pronostico sino el
  // balance final.
  if C.NoIniciado then
  begin
    lblCurva.Caption := 'Avance del trabajo  '#$2022'  el proyecto a'#250'n no ha ' +
      'empezado';
    lblCurvaNota.Caption := Format(
      'Arranca el %s. Trabajo total previsto: %s'#$2022'  dedicado hasta ahora: ' +
      '%s.   La curva muestra el plan; a'#250'n no hay avance que comparar.',
      [FormatDateTime('dd/mm/yyyy', FResumen.Calendario.Inicio),
       FormatHoras(C.TotalMin), FormatHoras(C.RealAcumMin)]);
    Exit;
  end;

  if C.Terminado then
  begin
    if C.DesviacionMin > 0 then
      lblCurva.Caption := Format(
        'Avance del trabajo  '#$2022'  cerrado con %s m'#225's de lo previsto',
        [FormatHoras(C.DesviacionMin)])
    else if C.DesviacionMin < 0 then
      lblCurva.Caption := Format(
        'Avance del trabajo  '#$2022'  cerrado con %s menos de lo previsto',
        [FormatHoras(Abs(C.DesviacionMin))])
    else
      lblCurva.Caption := 'Avance del trabajo  '#$2022'  cerrado seg'#250'n lo previsto';
  end
  else if C.DesviacionMin > 0 then
    lblCurva.Caption := Format(
      'Avance del trabajo  '#$2022'  por delante de lo previsto (+%s)',
      [FormatHoras(C.DesviacionMin)])
  else if C.DesviacionMin < 0 then
    lblCurva.Caption := Format(
      'Avance del trabajo  '#$2022'  por detr'#225's de lo previsto (%s)',
      [FormatHoras(C.DesviacionMin)])
  else
    lblCurva.Caption := 'Avance del trabajo  '#$2022'  al d'#237'a';

  lblCurvaNota.Caption := Format(
    'Previsto a d'#237'a de hoy: %s de %s  '#$2022'  dedicado: %s.   ' +
    'La curva prevista reparte el trabajo de cada tarea entre sus fechas; ' +
    'del trabajo real s'#243'lo consta el total, no en qu'#233' d'#237'a se hizo.',
    [FormatHoras(C.PrevistoHoyMin), FormatHoras(C.TotalMin),
     FormatHoras(C.RealAcumMin)]);
end;

procedure TfrmWbsPanelEsfuerzo.LlenarRiesgos;
var
  I: Integer;
begin
  tvRiesgos.BeginUpdate;
  try
    tvRiesgos.DataController.RecordCount := Length(FResumen.Riesgos);
    for I := 0 to High(FResumen.Riesgos) do
    begin
      tvRiesgos.DataController.Values[I, colRiesgoTipo.Index] :=
        RiesgoTipoToStr(FResumen.Riesgos[I].Tipo);
      tvRiesgos.DataController.Values[I, colRiesgoTarea.Index] :=
        FResumen.Riesgos[I].Caption;
      if FResumen.Riesgos[I].Fecha > 0 then
        tvRiesgos.DataController.Values[I, colRiesgoFecha.Index] :=
          FormatDateTime('dd/mm/yyyy', FResumen.Riesgos[I].Fecha)
      else
        tvRiesgos.DataController.Values[I, colRiesgoFecha.Index] := '-';
      tvRiesgos.DataController.Values[I, colRiesgoDetalle.Index] :=
        FResumen.Riesgos[I].Detalle;
    end;
  finally
    tvRiesgos.EndUpdate;
  end;

  if Length(FResumen.Riesgos) = 0 then
    lblRiesgos.Caption := 'Nada que reclamar: ninguna tarea retrasada, ' +
      'bloqueada ni desviada'
  else
    lblRiesgos.Caption := Format('Lo que conviene mirar hoy (%d)',
      [Length(FResumen.Riesgos)]);
end;

end.
