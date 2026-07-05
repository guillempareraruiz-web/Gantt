unit uPlanAnalisis;

// ============================================================================
//  Pantalla "Analisis del plan": dashboard de graficos TeeChart sobre el plan
//  ya planificado. Complementa al Gantt respondiendo preguntas de gestion.
//
//  Navegacion escalable a N graficos: arbol lateral (categorias -> graficos) +
//  PageControl con pestanas OCULTAS. Cada grafico vive en su pagina; al hacer
//  clic en el arbol se activa su pagina.
//
//  REGISTRO de graficos: cada grafico es una entrada en FGraficos con su
//  categoria, titulo y un metodo de pintado. Anadir un grafico nuevo = registrar
//  una entrada en RegistrarGraficos (no hay que tocar el DFM ni declarar tabs).
//
//  La primera pagina ("Resumen") es especial: parrilla 2x2 con 4 mini-graficos.
//  Datos: uPlanAnalisisData (reutiliza la logica de los heatmaps).
// ============================================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Graphics, Vcl.Samples.Spin,
  VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.Series,
  uPlanAnalisisData;

type
  TfrmPlanAnalisis = class(TForm)
    pnlTop: TPanel;
    lblDesde: TLabel;
    dtDesde: TDateTimePicker;
    lblGran: TLabel;
    cmbGran: TComboBox;
    lblNum: TLabel;
    spNum: TSpinEdit;
    btnActualizar: TButton;
    btnObs: TButton;
    btnAyuda: TButton;
    pnlLeft: TPanel;
    tvNav: TTreeView;
    splV: TSplitter;
    pc: TPageControl;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnActualizarClick(Sender: TObject);
    procedure btnAyudaClick(Sender: TObject);
    procedure btnObsClick(Sender: TObject);
    procedure tvNavClick(Sender: TObject);
    procedure tvNavCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode;
      State: TCustomDrawState; var DefaultDraw: Boolean);
  private
    procedure DemoChanged(Sender: TObject);   // refresco al (des)activar modo demo
  type
    // Un grafico registrado. Pintar=nil + Implementado=False -> pendiente: aparece
    // en el arbol DESHABILITADO (gris) como hoja de ruta. Cuando se implementa,
    // se le asigna el pintor y queda enabled.
    TPintor = procedure(Ch: TChart) of object;
    TGraficoDef = record
      Categoria: string;
      Titulo: string;
      Objetivo: string;    // que responde este grafico (panel Observaciones)
      PorQue: string;      // por que es util para el planificador
      Implementado: Boolean;
      Pintar: TPintor;
      Pagina: TTabSheet;   // solo si Implementado
      Chart: TChart;       // solo si Implementado
      PanelObs: TPanel;    // panel Observaciones DENTRO de su pagina (alBottom)
      MemoObs: TMemo;      // texto objetivo/utilidad de ese panel
    end;
  private
    FData: TPlanAnalisis;
    FGraficos: TList<TGraficoDef>;
    // Mini-charts de la pagina Resumen (parrilla 2x2): los 4 primeros implementados.
    FResumenPage: TTabSheet;
    FchR: array[0..3] of TChart;
    FObsVisible: Boolean;   // estado global del panel Observaciones (toggle)
    function NuevoChart(AParent: TWinControl): TChart;
    procedure Reg(const ACat, ATit: string; AP: TPintor;
      const AObjetivo: string = ''; const APorQue: string = '');
    procedure RegistrarGraficos;
    procedure ConstruirUI;          // crea paginas + arbol a partir de FGraficos
    procedure ConstruirResumen;     // pagina especial 2x2
    procedure ConstruirPanelObsEn(var G: TGraficoDef);  // panel Obs en su pagina
    procedure AplicarVisibilidadObs;                    // muestra/oculta segun estado
    procedure Recalcular;
    procedure RepintarTodo;
    procedure EstilizarSeries(Ch: TChart);  // sombra + gradiente PRO por serie
    procedure IrAPagina(AIndexPagina: Integer);
    // Pintores implementados
    procedure PintarCargaVsCapacidad(Ch: TChart);
    procedure PintarOcupacion(Ch: TChart);
    procedure PintarCargaVsCapacidadOperario(Ch: TChart);
    procedure PintarOcupacionOperario(Ch: TChart);
    procedure PintarCurva(Ch: TChart);
    procedure PintarOtd(Ch: TChart);
    procedure PintarCargaApilada(Ch: TChart);
    procedure PintarPareto(Ch: TChart);
    procedure PintarSobrecarga(Ch: TChart);
    procedure PintarRetrasos(Ch: TChart);
    procedure PintarSaludPlan(Ch: TChart);
    // Tanda 2
    procedure PintarEntregasPorSemana(Ch: TChart);
    procedure PintarTopRetrasos(Ch: TChart);
    procedure PintarMakespan(Ch: TChart);
    procedure PintarDuraciones(Ch: TChart);
    procedure PintarPorArticulo(Ch: TChart);
    procedure PintarPorOperacion(Ch: TChart);
    procedure PintarOpsPorCentro(Ch: TChart);
    procedure PintarProductivoSetup(Ch: TChart);
    procedure PintarUtilGlobal(Ch: TChart);
    // Tanda 3 (PRO)
    procedure PintarGanttResumen(Ch: TChart);
    procedure PintarCadenas(Ch: TChart);
    procedure PintarMargenEntrega(Ch: TChart);
    procedure PintarPrioridadRetraso(Ch: TChart);
    procedure PintarCrpAcumulada(Ch: TChart);
    procedure PintarBalanceLinea(Ch: TChart);
    procedure PintarProgreso(Ch: TChart);
    procedure PintarPorCliente(Ch: TChart);
    procedure PintarWipEstado(Ch: TChart);
    procedure PintarCobertura(Ch: TChart);
    procedure PintarOcupacionCalendario(Ch: TChart);
  public
    class procedure Ejecutar;
  end;

implementation

{$R *.dfm}

uses
  System.DateUtils, System.Math, System.UITypes, System.Generics.Defaults,
  VCLTee.TeeGDIPlus, VCLTee.TeCanvas,
  uDMPlanner, uDemoMode, uHelpViewer;

const
  CLR_CARGA   = $00C8924A;  // azul acero (BGR)
  CLR_CAP     = $005050A0;  // linea capacidad (rojizo suave)
  CLR_OK      = $0070C070;  // verde
  CLR_WARN    = $0040A0F0;  // ambar/naranja
  CLR_BAD     = $005050E0;  // rojo

class procedure TfrmPlanAnalisis.Ejecutar;
var
  F: TfrmPlanAnalisis;
begin
  F := TfrmPlanAnalisis.Create(Application);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmPlanAnalisis.FormCreate(Sender: TObject);
begin
  cmbGran.Items.Clear;
  cmbGran.Items.Add('D'#237'as');
  cmbGran.Items.Add('Semanas');
  cmbGran.Items.Add('Meses');
  cmbGran.ItemIndex := 0;
  spNum.Value := 14;
  dtDesde.Date := Date;

  FObsVisible := False;
  FGraficos := TList<TGraficoDef>.Create;
  RegistrarGraficos;
  ConstruirUI;   // crea cada pagina con su panel Observaciones (oculto)
  Recalcular;

  // Modo demo: al conmutar el boton "Demo" del toolbar se refresca el dashboard
  // con datos ficticios (o reales al desactivarlo), sin tocar la BD.
  DemoMode.AddListener(DemoChanged);

  // Boton "?" (esquina superior derecha) + F1 -> ayuda contextual.
  THelpViewer.InstallHelp(Self, 'uPlanAnalisis', 'An'#225'lisis del plan');
end;

procedure TfrmPlanAnalisis.FormDestroy(Sender: TObject);
begin
  DemoMode.RemoveListener(DemoChanged);
  FGraficos.Free;
end;

procedure TfrmPlanAnalisis.DemoChanged(Sender: TObject);
begin
  Recalcular;
end;

// ---------------------------------------------------------------------------
// Registro de graficos. Anadir uno nuevo = una linea aqui.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.Reg(const ACat, ATit: string; AP: TPintor;
  const AObjetivo, APorQue: string);
var
  G: TGraficoDef;
begin
  G := Default(TGraficoDef);
  G.Categoria := ACat;
  G.Titulo := ATit;
  G.Objetivo := AObjetivo;
  G.PorQue := APorQue;
  G.Pintar := AP;
  G.Implementado := Assigned(AP);
  FGraficos.Add(G);
end;

procedure TfrmPlanAnalisis.RegistrarGraficos;
begin
  // Catalogo completo = hoja de ruta. AP=nil -> pendiente (gris en el arbol).
  // Para implementar uno pendiente: poner su pintor en lugar de nil.

  // --- GENERAL ---
  Reg('General',   'Salud del plan',                   PintarSaludPlan,
    'Este indicador resume en un solo n'#250'mero, de 0 a 100, el estado global del '
    + 'plan, combinando de forma ponderada tres se'#241'ales: el cumplimiento de las '
    + 'entregas comprometidas, la utilizaci'#243'n media de los centros y la '
    + 'penalizaci'#243'n por sobrecarga. Funciona como un sem'#225'foro de un vistazo: '
    + 'antes de entrar en el detalle de cada gr'#225'fico, dice si el plan est'#225' sano, '
    + 'en tensi'#243'n o necesita una revisi'#243'n urgente. Es '#250'til para el planificador '
    + 'porque le da un punto de partida objetivo cada ma'#241'ana y le permite '
    + 'comparar r'#225'pidamente el efecto de una replanificaci'#243'n: si el n'#250'mero sube, '
    + 'las decisiones tomadas mejoran el conjunto; si baja, conviene revisarlas.');
  Reg('General',   'Cronograma por proyecto',          PintarGanttResumen,
    'Sit'#250'a cada proyecto del plan en el tiempo como un mini-Gantt, dibujando su '
    + 'ventana desde la primera operaci'#243'n que arranca hasta la '#250'ltima que '
    + 'termina. Permite ver de golpe qu'#233' proyectos conviven en el calendario, '
    + 'cu'#225'les se solapan y cu'#225'l ocupa m'#225's tiempo, sin necesidad de bajar al '
    + 'detalle operaci'#243'n a operaci'#243'n del Gantt principal. Es '#250'til para el '
    + 'planificador cuando gestiona varias '#243'rdenes o pedidos a la vez: de un '
    + 'vistazo detecta solapamientos que competir'#225'n por los mismos recursos, '
    + 'identifica el proyecto que marca el horizonte y decide c'#243'mo secuenciar la '
    + 'cartera para no concentrar la carga ni comprometer plazos imposibles.');
  Reg('General',   'Avance del plan',                  PintarProgreso,
    'Muestra qu'#233' porcentaje de las unidades a fabricar del plan ya est'#225' '
    + 'terminado, comparando las unidades fabricadas con las totales previstas. '
    + 'Es el progreso real de ejecuci'#243'n frente a lo planificado, expresado como '
    + 'un indicador claro de avance. Resulta '#250'til para el planificador porque '
    + 'separa lo que est'#225' dibujado en el plan de lo que de verdad se ha '
    + 'producido: permite saber si la f'#225'brica va adelantada o retrasada respecto '
    + 'al compromiso, anticipar desviaciones antes de que se conviertan en '
    + 'incumplimientos y comunicar a direcci'#243'n y a los clientes un estado de '
    + 'avance fiable, apoyado en datos de producci'#243'n y no en estimaciones.');

  // --- CAPACIDAD ---
  Reg('Capacidad', 'Carga vs capacidad por centro',    PintarCargaVsCapacidad,
    'Compara, centro a centro, las horas de trabajo planificadas con la '
    + 'capacidad realmente disponible seg'#250'n su calendario. Cada barra es la '
    + 'carga y la l'#237'nea marca el techo de capacidad, de modo que las barras que '
    + 'sobresalen se'#241'alan centros sobrecargados. Es la vista base para detectar '
    + 'cuellos de botella y el desequilibrio del taller. Resulta '#250'til para el '
    + 'planificador porque convierte una intuici'#243'n ("este centro va apretado") '
    + 'en un dato medible: identifica d'#243'nde no cabe el trabajo con los recursos '
    + 'actuales, d'#243'nde queda holgura para aceptar m'#225's carga y qu'#233' centros exigen '
    + 'una decisi'#243'n de replanificaci'#243'n, refuerzo de turnos o subcontrataci'#243'n.');
  Reg('Capacidad', 'Ocupaci'#243'n por centro',           PintarOcupacion,
    'Expresa el uso de cada centro como porcentaje de su capacidad total, con un '
    + 'c'#243'digo de color que distingue el centro saludable en verde, el que est'#225' al '
    + 'l'#237'mite en '#225'mbar y el saturado en rojo. Frente a las horas absolutas, el '
    + 'porcentaje normaliza y permite comparar centros de tama'#241'os muy distintos '
    + 'en la misma escala. Es '#250'til para el planificador porque prioriza de un '
    + 'vistazo d'#243'nde actuar: los centros en rojo requieren aliviar carga o '
    + 'reprogramar, mientras que los que est'#225'n muy por debajo revelan capacidad '
    + 'ociosa que se puede aprovechar reequilibrando el reparto de trabajo entre '
    + 'centros o adelantando operaciones que hoy esperan en otros recursos.');
  Reg('Capacidad', 'Curva de carga temporal',          PintarCurva,
    'Representa la evoluci'#243'n de la carga total del taller periodo a periodo, '
    + 'superpuesta a la capacidad disponible en cada tramo. En vez de un '
    + 'agregado '#250'nico, muestra la forma temporal de la demanda: d'#243'nde est'#225'n los '
    + 'picos que superan la capacidad y d'#243'nde los valles con recursos ociosos. '
    + 'Es '#250'til para el planificador porque el nivelado de carga vive en el '
    + 'tiempo: ver el perfil completo permite mover trabajo de las semanas '
    + 'saturadas a las descargadas, anticipar cu'#225'ndo har'#225'n falta horas extra o '
    + 'turnos adicionales y suavizar la producci'#243'n para evitar el ciclo de '
    + 'sobreesfuerzo seguido de par'#243'n que encarece y desordena el taller.');
  Reg('Capacidad', 'Carga acumulada vs capacidad (CRP)', PintarCrpAcumulada,
    'Dibuja las curvas acumuladas de carga y de capacidad a lo largo del '
    + 'horizonte, la t'#233'cnica cl'#225'sica del Capacity Requirements Planning. '
    + 'Mientras la curva de carga se mantenga por debajo de la de capacidad, el '
    + 'plan es viable; el punto donde la carga la cruza por encima marca el '
    + 'momento a partir del cual el trabajo comprometido ya no cabe con los '
    + 'recursos disponibles. Es '#250'til para el planificador porque anticipa el '
    + 'colapso antes de que ocurra: en lugar de descubrir tarde que no se llega, '
    + 've con antelaci'#243'n la fecha l'#237'mite y puede a'#241'adir capacidad, adelantar '
    + 'trabajo o renegociar plazos mientras a'#250'n hay margen de maniobra.');
  Reg('Capacidad', 'Ocupaci'#243'n por centro y periodo',  PintarOcupacionCalendario,
    'Es un mapa de calor que colorea cada combinaci'#243'n de centro y periodo seg'#250'n '
    + 'su nivel de saturaci'#243'n, del verde holgado al rojo sobrecargado. A '
    + 'diferencia de los totales, muestra el "cu'#225'ndo" de la carga: no solo qu'#233' '
    + 'centro va apretado, sino en qu'#233' semanas concretas. Resulta '#250'til para el '
    + 'planificador porque localiza los focos calientes con precisi'#243'n de celda: '
    + 'permite ver que un centro globalmente sano tiene, sin embargo, dos '
    + 'semanas imposibles, o que la sobrecarga se concentra en un tramo que '
    + 'coincide con vacaciones o mantenimiento. Con ese detalle se act'#250'a de forma '
    + 'quir'#250'rgica, moviendo solo el trabajo del periodo cr'#237'tico.');
  Reg('Capacidad', 'Carga apilada por centro',         PintarCargaApilada,
    'Desglosa la carga temporal del taller mostrando, en cada periodo, qu'#233' '
    + 'centro aporta cada tramo de la columna. Combina la visi'#243'n temporal de la '
    + 'demanda con la composici'#243'n por centro, de modo que se ve a la vez cu'#225'nta '
    + 'carga total hay y de d'#243'nde procede. Es '#250'til para el planificador porque, '
    + 'cuando un periodo aparece saturado, esta vista responde inmediatamente a '
    + 'la pregunta siguiente: qu'#233' centros son responsables de ese pico. As'#237' la '
    + 'decisi'#243'n de nivelado deja de ser general y pasa a ser concreta, '
    + 'identificando el centro cuya carga conviene adelantar o retrasar para '
    + 'alisar ese periodo sin desequilibrar el resto del taller.');
  Reg('Capacidad', 'Balance de l'#237'nea (desequilibrio)', PintarBalanceLinea,
    'Mide cu'#225'nto se aleja la ocupaci'#243'n de cada centro respecto a la media del '
    + 'taller, dibujando la desviaci'#243'n a un lado o a otro. Las barras que se van '
    + 'mucho hacia la sobrecarga o hacia la infrautilizaci'#243'n revelan un taller '
    + 'descompensado, con unos centros ahogados mientras otros est'#225'n ociosos. '
    + 'Es '#250'til para el planificador porque el objetivo de una buena '
    + 'planificaci'#243'n no es solo que quepa el trabajo, sino que fluya '
    + 'equilibrado: un desequilibrio grande alarga plazos y crea colas '
    + 'innecesarias. Detectarlo permite reequilibrar cargas entre centros, '
    + 'reasignar operaciones flexibles y acercar el conjunto a un ritmo parejo, '
    + 'que es lo que sostiene un flujo estable y predecible.');
  Reg('Capacidad', 'Pareto de carga por centro',       PintarPareto,
    'Ordena los centros de mayor a menor carga y superpone la l'#237'nea de '
    + 'porcentaje acumulado, aplicando la regla de Pareto o del 80/20. '
    + 'Habitualmente unos pocos centros concentran la mayor parte de la carga '
    + 'del taller, y el gr'#225'fico los identifica de un vistazo. Es '#250'til para el '
    + 'planificador porque enfoca el esfuerzo donde m'#225's rinde: en lugar de '
    + 'repartir la atenci'#243'n por igual, se'#241'ala los dos o tres centros cr'#237'ticos '
    + 'cuya mejora tiene el mayor impacto sobre el conjunto. Optimizar, aliviar '
    + 'o reforzar esos centros clave mueve la aguja del plan mucho m'#225's que actuar '
    + 'sobre los muchos centros que apenas aportan carga.');
  Reg('Capacidad', 'Sobrecarga por centro',            PintarSobrecarga,
    'Cuenta, para cada centro, en cu'#225'ntos periodos del horizonte su carga supera '
    + 'la capacidad disponible. Frente a un total de horas, esta vista mide la '
    + 'persistencia del problema: un centro con sobrecarga en muchos periodos '
    + 'sufre una tensi'#243'n cr'#243'nica, no un pico puntual. Es '#250'til para el '
    + 'planificador porque distingue el exceso ocasional, que se absorbe con '
    + 'algo de flexibilidad, del estructural, que exige una decisi'#243'n de fondo. '
    + 'Los centros con sobrecarga recurrente son candidatos claros a '
    + 'replanificaci'#243'n, a refuerzo estable de turnos o personal, o a '
    + 'subcontrataci'#243'n, porque ning'#250'n ajuste fino del calendario resolver'#225' un '
    + 'desajuste que se repite periodo tras periodo.');

  // --- ENTREGAS ---
  Reg('Entregas',  'Cumplimiento de entregas (OTD)',   PintarOtd,
    'Reparte las entregas del plan entre cuatro estados: a tiempo, en riesgo, '
    + 'retrasadas y sin compromiso de fecha. Es el indicador On-Time Delivery, la '
    + 'medida comercial por excelencia de una planificaci'#243'n, porque traduce todo '
    + 'el trabajo del taller a la '#250'nica pregunta que le importa al cliente: '
    + 'llegaremos a la fecha prometida. Resulta '#250'til para el planificador porque '
    + 'conecta la operativa interna con el compromiso externo: un plan '
    + 'perfectamente equilibrado en capacidad pero con muchas entregas '
    + 'retrasadas est'#225' fallando en lo esencial. Ver el reparto permite '
    + 'priorizar las '#243'rdenes en riesgo, anticipar avisos comerciales y decidir '
    + 'qu'#233' reprogramar para proteger las fechas m'#225's sensibles.');
  Reg('Entregas',  'Distribuci'#243'n de retrasos',        PintarRetrasos,
    'Es un histograma que agrupa las entregas seg'#250'n su desviaci'#243'n en d'#237'as '
    + 'respecto a la fecha comprometida, desde las que se adelantan hasta las que '
    + 'llegan muy tarde. M'#225's all'#225' de saber cu'#225'ntas se retrasan, muestra la '
    + 'gravedad y la forma del incumplimiento: no es lo mismo un d'#237'a de retraso '
    + 'que una semana. Es '#250'til para el planificador porque caracteriza el '
    + 'problema antes de atacarlo: si la mayor'#237'a de desviaciones son de uno o '
    + 'dos d'#237'as, un peque'#241'o ajuste de calendario basta; si hay una cola larga de '
    + 'retrasos graves, el plan tiene un problema estructural de capacidad o de '
    + 'fechas que requiere una intervenci'#243'n de mayor calado.');
  Reg('Entregas',  'Margen hasta la entrega',          PintarMargenEntrega,
    'Muestra las '#243'rdenes ordenadas por el colch'#243'n que les queda hasta su fecha '
    + 'de entrega, destacando las m'#225's ajustadas y las que ya van en retraso. Es '
    + 'el radar de lo que puede incumplirse: mientras el OTD da la foto global, '
    + 'esta vista se'#241'ala nominalmente qu'#233' '#243'rdenes concretas est'#225'n al borde. '
    + 'Resulta '#250'til para el planificador porque convierte el riesgo en una lista '
    + 'accionable de vigilancia diaria: las '#243'rdenes con margen negativo o casi '
    + 'nulo son las que hay que seguir de cerca, proteger de imprevistos y, si '
    + 'hace falta, priorizar por delante de otras con m'#225's holgura. Anticipar '
    + 'sobre esta lista evita que un retraso peque'#241'o se convierta en un '
    + 'incumplimiento de cliente.');
  Reg('Entregas',  'Prioridad vs retraso',             PintarPrioridadRetraso,
    'Sit'#250'a cada orden como un punto en un plano que cruza su prioridad con sus '
    + 'd'#237'as de retraso. Las '#243'rdenes del cuadrante superior derecho son las '
    + 'urgentes de verdad: importan mucho y adem'#225's van tarde. El gr'#225'fico separa '
    + 'la urgencia real de la aparente, que es una de las decisiones m'#225's dif'#237'ciles '
    + 'del d'#237'a a d'#237'a. Es '#250'til para el planificador porque evita el error de '
    + 'atender lo m'#225's ruidoso en lugar de lo m'#225's importante: concentra la '
    + 'acci'#243'n en las '#243'rdenes de alta prioridad que est'#225'n en problemas, deja para '
    + 'despu'#233's las que van tarde pero son secundarias, y da un criterio '
    + 'objetivo para justificar el orden de intervenci'#243'n.');
  Reg('Entregas',  'Entregas por semana',              PintarEntregasPorSemana,
    'Ofrece un resumen agregado del cumplimiento de entregas, con el reparto '
    + 'global entre las que van a tiempo, en riesgo y retrasadas. Es una foto '
    + 'r'#225'pida del estado de las entregas del plan, pensada para una lectura '
    + 'inmediata sin entrar en el detalle orden a orden. Resulta '#250'til para el '
    + 'planificador como term'#243'metro de seguimiento: complementa al OTD dando una '
    + 'visi'#243'n compacta que se puede consultar de un vistazo en cualquier momento '
    + 'del d'#237'a, comparar contra jornadas anteriores para ver si la tendencia de '
    + 'cumplimiento mejora o empeora, y usar como punto de arranque antes de '
    + 'profundizar en los gr'#225'ficos de margen o de '#243'rdenes retrasadas.');
  Reg('Entregas',  'Top OF m'#225's retrasadas',           PintarTopRetrasos,
    'Presenta el ranking de las '#243'rdenes de fabricaci'#243'n con m'#225's d'#237'as de retraso '
    + 'sobre su compromiso, ordenadas de peor a menos mala. Concentra la '
    + 'atenci'#243'n en el extremo del problema: las pocas '#243'rdenes que acumulan el '
    + 'mayor retraso y que, casi siempre, son las que generan las quejas de '
    + 'cliente y las llamadas inc'#243'modas. Es '#250'til para el planificador porque '
    + 'ofrece una lista corta y priorizada de intervenci'#243'n: en lugar de intentar '
    + 'arreglarlo todo, se centra en recuperar las '#243'rdenes m'#225's da'#241'inas, que son '
    + 'las que m'#225's valor tiene rescatar. Actuar primero sobre este top reduce el '
    + 'riesgo comercial y libera tensi'#243'n del resto del plan.');

  // --- DEPENDENCIAS ---
  Reg('Dependencias', 'Cadenas m'#225's largas (camino cr'#237'tico)', PintarCadenas,
    'Recorre las dependencias entre operaciones y muestra las secuencias '
    + 'encadenadas de mayor duraci'#243'n acumulada, una aproximaci'#243'n al camino '
    + 'cr'#237'tico del plan. Estas cadenas son las que fijan el plazo total: mientras '
    + 'existan, ninguna mejora fuera de ellas adelanta la fecha final de '
    + 'entrega. Es '#250'til para el planificador porque enfoca el esfuerzo de '
    + 'reducci'#243'n de plazo donde de verdad cuenta: acelerar una operaci'#243'n que no '
    + 'est'#225' en la cadena m'#225's larga no cambia el resultado, mientras que acortar, '
    + 'solapar o paralelizar las operaciones de esa cadena s'#237' comprime el '
    + 'calendario. Identificar estas secuencias evita malgastar recursos en '
    + 'optimizaciones que no mueven la fecha comprometida.');

  // --- TIEMPOS ---
  Reg('Tiempos',   'Makespan por proyecto',            PintarMakespan,
    'Mide la duraci'#243'n total de cada proyecto, desde que arranca su primera '
    + 'operaci'#243'n hasta que termina la '#250'ltima, y compara esos tiempos entre '
    + 'proyectos. El makespan es la ventana completa que un proyecto ocupa en el '
    + 'calendario, con independencia de cu'#225'ntas horas de trabajo contenga. Es '
    + #250'til para el planificador porque distingue el proyecto que consume mucho '
    + 'tiempo de calendario del que acumula muchas horas: dos cosas distintas '
    + 'que exigen respuestas distintas. Comparar makespans ayuda a comprometer '
    + 'plazos realistas, a secuenciar la cartera evitando que los proyectos '
    + 'largos se solapen en exceso y a detectar aquellos cuya ventana se estira '
    + 'por esperas y dependencias m'#225's que por trabajo efectivo.');
  Reg('Tiempos',   'Distribuci'#243'n de duraciones',      PintarDuraciones,
    'Es un histograma que agrupa las operaciones del plan por su tama'#241'o en '
    + 'minutos, mostrando cu'#225'ntas son muy cortas, cu'#225'ntas medianas y cu'#225'ntas '
    + 'largas. Revela la mezcla de trabajo del taller, que condiciona el '
    + 'esfuerzo de secuenciaci'#243'n y el peso de las preparaciones. Resulta '#250'til '
    + 'para el planificador porque un plan dominado por muchas operaciones cortas '
    + 'implica cambios frecuentes y, por tanto, mucho tiempo de setup relativo, '
    + 'mientras que uno con pocas operaciones largas es m'#225's estable pero menos '
    + 'flexible. Conocer esta distribuci'#243'n orienta decisiones de agrupaci'#243'n por '
    + 'lotes, de tama'#241'o de '#243'rdenes y de asignaci'#243'n a centros, buscando reducir '
    + 'los cambios improductivos sin perder capacidad de reacci'#243'n.');

  // --- MIX / PRODUCTO ---
  Reg('Mix',       'Carga por art'#237'culo',              PintarPorArticulo,
    'Muestra las horas de carga concentradas por art'#237'culo, con los quince que '
    + 'm'#225's capacidad consumen. Traslada la carga del plan al lenguaje del '
    + 'producto: qu'#233' referencias son las que de verdad ocupan el taller. Es '#250'til '
    + 'para el planificador y para la direcci'#243'n porque conecta la operativa con '
    + 'las decisiones de negocio: los art'#237'culos que dominan la carga son los que '
    + 'm'#225's se benefician de una mejora de proceso, de una revisi'#243'n de tiempos o '
    + 'de una negociaci'#243'n de plazos y precios. Tambi'#233'n ayuda a anticipar el '
    + 'impacto de un cambio de mezcla comercial: si crece la demanda de un '
    + 'art'#237'culo intensivo, esta vista adelanta d'#243'nde se notar'#225' la presi'#243'n de '
    + 'capacidad.');
  Reg('Mix',       'Carga por tipo de operaci'#243'n',     PintarPorOperacion,
    'Agrupa las horas de carga por tipo de operaci'#243'n, como torneado, fresado, '
    + 'soldadura o montaje, y muestra cu'#225'les dominan el trabajo del taller. '
    + 'Ofrece una lectura por proceso, transversal a productos y centros. Es '
    + #250'til para el planificador porque revela d'#243'nde se concentra realmente el '
    + 'esfuerzo productivo y, con ello, d'#243'nde una inversi'#243'n en capacidad, en '
    + 'formaci'#243'n o en mejora de m'#233'todo tendr'#237'a m'#225's retorno. Si un tipo de '
    + 'operaci'#243'n acumula una parte desproporcionada de las horas, es un '
    + 'candidato natural a automatizaci'#243'n o a refuerzo, y su saturaci'#243'n suele '
    + 'ser la que limita la capacidad global del taller para asumir m'#225's trabajo.');
  Reg('Mix',       'Carga por cliente',                PintarPorCliente,
    'Reparte las horas de carga del plan entre los clientes a los que se dedica '
    + 'la capacidad, mostrando los quince principales. Traduce el trabajo del '
    + 'taller a t'#233'rminos comerciales: a qui'#233'n estamos dedicando de verdad '
    + 'nuestros recursos. Es '#250'til para el planificador y para la direcci'#243'n '
    + 'porque hace visible la dependencia de determinados clientes y el coste en '
    + 'capacidad de servirlos: permite negociar plazos con criterio, equilibrar '
    + 'la cartera para no depender en exceso de uno solo y valorar el impacto '
    + 'real de aceptar un nuevo pedido grande. Cuando un cliente concentra una '
    + 'parte importante de la carga, sus cambios de programa afectan a todo el '
    + 'plan, y conviene tenerlo presente al comprometer fechas.');
  Reg('Mix',       'N'#186' operaciones por centro',        PintarOpsPorCentro,
    'Cuenta cu'#225'ntas operaciones distintas pasan por cada centro, con '
    + 'independencia de las horas que sumen. Complementa a la carga en tiempo con '
    + 'una medida de fragmentaci'#243'n: un centro puede tener pocas horas pero '
    + 'muchas operaciones peque'#241'as. Es '#250'til para el planificador porque el '
    + 'n'#250'mero de operaciones anticipa el n'#250'mero de cambios y preparaciones: un '
    + 'centro con muchas operaciones cortas sufre m'#225's setups, m'#225's colas y m'#225's '
    + 'riesgo de p'#233'rdida de tiempo entre trabajos, aunque su carga en horas '
    + 'parezca moderada. Detectarlo orienta decisiones de agrupaci'#243'n por lotes y '
    + 'de secuenciaci'#243'n que reducen los cambios improductivos y mejoran el flujo '
    + 'real de ese centro.');

  // --- RECURSOS ---
  Reg('Recursos',  'Carga vs capacidad por operario',  PintarCargaVsCapacidadOperario,
    'Compara, para cada operario, las horas de trabajo asignadas con su '
    + 'capacidad seg'#250'n calendario. Lleva el an'#225'lisis de capacidad del centro al '
    + 'nivel de las personas, que es donde finalmente se ejecuta el plan. Es '#250'til '
    + 'para el planificador porque un centro globalmente equilibrado puede '
    + 'esconder personas saturadas junto a otras con holgura: esta vista lo hace '
    + 'visible. Permite repartir mejor la carga entre operarios, detectar '
    + 'dependencias de una sola persona clave y anticipar el efecto de una '
    + 'ausencia o unas vacaciones. Planificar mirando tambi'#233'n a las personas, y '
    + 'no solo a las m'#225'quinas, evita cuellos de botella humanos que no aparecen '
    + 'en los agregados por centro pero que retrasan la producci'#243'n igual o m'#225's.');
  Reg('Recursos',  'Ocupaci'#243'n de operarios',          PintarOcupacionOperario,
    'Expresa la ocupaci'#243'n de cada operario como porcentaje de su capacidad, '
    + 'normalizando calendarios y jornadas distintas en una escala comparable. '
    + 'Es '#250'til para el planificador porque detecta desequilibrios de carga entre '
    + 'personas dentro de un mismo centro o departamento, que suelen pasar '
    + 'inadvertidos en los totales. Un operario sistem'#225'ticamente por encima del '
    + 'cien por cien es un riesgo de retraso, de errores y de desgaste; otro muy '
    + 'por debajo es capacidad desaprovechada. Ver ambos extremos permite '
    + 'reequilibrar asignaciones, apoyar a quien va saturado y repartir mejor las '
    + 'operaciones flexibles, buscando un reparto justo y sostenible que sostenga '
    + 'el ritmo de producci'#243'n sin quemar a las personas m'#225's cargadas.');
  Reg('Recursos',  'Cobertura de personal por centro', PintarCobertura,
    'Enfrenta, centro a centro, el n'#250'mero de operarios necesarios para ejecutar '
    + 'el plan con el n'#250'mero realmente asignado. Es una comprobaci'#243'n de '
    + 'viabilidad desde el lado de las personas: mide si hay manos suficientes '
    + 'para el trabajo programado. Resulta '#250'til para el planificador porque un '
    + 'plan puede ser correcto en horas de m'#225'quina y, sin embargo, ser '
    + 'inejecutable por falta de personal en un centro concreto. Detectar el '
    + 'd'#233'ficit con antelaci'#243'n permite reasignar operarios entre centros, '
    + 'planificar refuerzos o formaci'#243'n, o ajustar la carga a la plantilla real '
    + 'disponible. Es una de las causas m'#225's frecuentes y m'#225's ignoradas de '
    + 'retraso, porque el plan cuadra sobre el papel pero no en la planta.');
  Reg('Recursos',  'Trabajo en curso por estado (WIP)', PintarWipEstado,
    'Muestra cu'#225'ntas operaciones est'#225'n pendientes, en curso o ya terminadas, '
    + 'dando la foto del trabajo en curso o WIP del plan. La cantidad de trabajo '
    + 'simult'#225'neamente abierto es un indicador clave de salud del flujo. Es '#250'til '
    + 'para el planificador porque demasiado WIP en curso a la vez alarga los '
    + 'plazos, multiplica las colas y esconde los cuellos de botella detr'#225's de '
    + 'una aparente actividad. Controlar el trabajo en curso, liberando '
    + 'operaciones al ritmo al que el taller las puede cerrar, acorta los tiempos '
    + 'de paso y hace el plan m'#225's predecible. Esta vista ayuda a decidir cu'#225'ndo '
    + 'conviene frenar la apertura de nuevas '#243'rdenes y concentrarse en terminar '
    + 'las que ya est'#225'n en marcha.');

  // --- EFICIENCIA ---
  Reg('Eficiencia','% tiempo productivo vs setup',     PintarProductivoSetup,
    'Descompone las horas de cada centro entre el tiempo de producci'#243'n real y el '
    + 'tiempo de preparaci'#243'n o setup. El setup es tiempo que no fabrica pero que '
    + 'consume capacidad, y suele crecer sin control cuando hay muchos cambios de '
    + 'trabajo. Es '#250'til para el planificador porque cuantifica una p'#233'rdida a '
    + 'menudo invisible: si un centro dedica una parte grande de sus horas a '
    + 'preparar en vez de a producir, agrupar operaciones similares por color, '
    + 'molde o material puede liberar capacidad sin invertir un solo euro. Ver el '
    + 'reparto por centro se'#241'ala d'#243'nde la secuenciaci'#243'n y el agrupamiento por '
    + 'lotes rinden m'#225's, y convierte la reducci'#243'n de cambios en una palanca '
    + 'concreta de mejora de la capacidad efectiva.');
  Reg('Eficiencia','Utilizaci'#243'n media global',        PintarUtilGlobal,
    'Resume en un solo indicador la ocupaci'#243'n media de todo el taller, como '
    + 'term'#243'metro global de aprovechamiento de la capacidad. Es '#250'til para el '
    + 'planificador porque ofrece una referencia r'#225'pida del equilibrio del '
    + 'conjunto, teniendo en cuenta que ni la saturaci'#243'n ni la ociosidad son '
    + 'buenas: un taller al cien por cien no tiene margen para absorber '
    + 'imprevistos y encadena retrasos, mientras que uno muy por debajo '
    + 'desaprovecha recursos. El '#243'ptimo suele situarse en torno al ochenta por '
    + 'ciento, que combina buen uso de la capacidad con holgura para reaccionar. '
    + 'Seguir este indicador en el tiempo permite ver si las decisiones de '
    + 'planificaci'#243'n acercan o alejan al taller de ese punto de equilibrio.');
end;

// ---------------------------------------------------------------------------
// Construccion de la UI a partir del registro
// ---------------------------------------------------------------------------
function TfrmPlanAnalisis.NuevoChart(AParent: TWinControl): TChart;
begin
  Result := TChart.Create(Self);
  Result.Parent := AParent;
  Result.Align := alClient;
  // Render GDI+ (antialiasing) en lugar del GDI clasico -> lineas, barras,
  // tartas y texto suavizados. TGDIPlusCanvas.AntiAlias ya es True por defecto;
  // activamos ademas el suavizado de texto (ClearType).
  var Gp: TGDIPlusCanvas := TGDIPlusCanvas.Create;
  Gp.AntiAlias := True;
  Gp.AntiAliasText := gpfClearType;
  Result.Canvas := Gp;
  Result.BevelOuter := bvNone;
  Result.Legend.Visible := False;
  Result.View3D := False;
  Result.Title.Visible := True;
  Result.Title.Font.Name := 'Segoe UI';
  Result.Title.Font.Size := 10;
  Result.Title.Font.Style := [fsBold];
  Result.Title.Font.Color := $00404040;

  // --- Estilo PRO: fondo con gradiente suave y paredes limpias ---
  Result.Color := clWhite;
  // Gradiente vertical muy sutil (blanco -> gris papel) en el fondo del panel.
  Result.Gradient.Visible := True;
  Result.Gradient.Direction := gdTopBottom;
  Result.Gradient.StartColor := clWhite;
  Result.Gradient.EndColor := $00F7F4EE;   // crema/gris papel casi imperceptible
  // Pared de fondo (area de trazado) plana y clara, sin marco 3D duro.
  Result.BackWall.Color := $00FCFAF4;
  Result.BackWall.Brush.Color := $00FCFAF4;
  Result.BackWall.Pen.Visible := False;
  Result.BackWall.Size := 0;
  Result.Walls.Visible := False;

  // Ejes discretos: rejilla fina gris claro, sin lineas negras duras.
  Result.LeftAxis.Grid.Color := $00E4E0D8;
  Result.LeftAxis.Grid.SmallDots := True;
  Result.LeftAxis.Axis.Color := $00C0BCB4;
  Result.LeftAxis.Axis.Width := 1;
  Result.BottomAxis.Grid.Color := $00E4E0D8;
  Result.BottomAxis.Grid.SmallDots := True;
  Result.BottomAxis.Axis.Color := $00C0BCB4;
  Result.BottomAxis.Axis.Width := 1;

  Result.MarginLeft := 3;
  Result.MarginRight := 3;
  Result.MarginTop := 3;
  Result.MarginBottom := 3;
end;

procedure TfrmPlanAnalisis.ConstruirUI;
const
  DATA_CATEGORIA = -1;
  DATA_PENDIENTE = -2;
var
  I: Integer;
  G: TGraficoDef;
  Page: TTabSheet;
  CatNodes: TDictionary<string, TTreeNode>;
  CatNode: TTreeNode;
begin
  pc.Style := tsTabs;  // las paginas llevan TabVisible:=False -> no se ven pestanas

  CatNodes := TDictionary<string, TTreeNode>.Create;
  tvNav.Items.BeginUpdate;
  try
    tvNav.Items.Clear;

    // --- Pagina 0: Resumen (especial 2x2). Nodo raiz, Data=0 (indice de pagina).
    FResumenPage := TTabSheet.Create(pc);
    FResumenPage.PageControl := pc;
    FResumenPage.TabVisible := False;
    ConstruirResumen;
    tvNav.Items.AddObject(nil, 'Resumen', TObject(0));

    // --- Un nodo por grafico, agrupados por categoria. ---
    // Implementado: crea pagina+chart, Data = indice de pagina (>=1).
    // Pendiente:    no crea pagina, Data = DATA_PENDIENTE (gris, no navega).
    for I := 0 to FGraficos.Count - 1 do
    begin
      G := FGraficos[I];

      if not CatNodes.TryGetValue(G.Categoria, CatNode) then
      begin
        CatNode := tvNav.Items.AddObject(nil, G.Categoria, TObject(DATA_CATEGORIA));
        CatNodes.AddOrSetValue(G.Categoria, CatNode);
      end;

      if G.Implementado then
      begin
        Page := TTabSheet.Create(pc);
        Page.PageControl := pc;
        Page.TabVisible := False;
        G.Pagina := Page;
        // Orden importa: primero el panel Obs (alBottom), luego el chart
        // (alClient) para que el chart ocupe el resto. El panel arranca oculto.
        ConstruirPanelObsEn(G);
        G.Chart := NuevoChart(Page);
        FGraficos[I] := G;
        // Data = indice de la pagina recien creada en el PageControl.
        tvNav.Items.AddChildObject(CatNode, G.Titulo, TObject(Page.PageIndex));
      end
      else
        tvNav.Items.AddChildObject(CatNode, G.Titulo + '   (pendiente)',
          TObject(DATA_PENDIENTE));
    end;

    tvNav.FullExpand;
  finally
    tvNav.Items.EndUpdate;
    CatNodes.Free;
  end;

  pc.ActivePageIndex := 0;
end;

procedure TfrmPlanAnalisis.ConstruirResumen;
var
  Cont, Fila: TPanel;
  I: Integer;

  function NuevoPanel(AParent: TWinControl; AAlign: TAlign): TPanel;
  begin
    Result := TPanel.Create(Self);
    Result.Parent := AParent;
    Result.Align := AAlign;
    Result.BevelOuter := bvLowered;
    Result.Caption := '';
  end;

begin
  // Dos filas (alTop + alClient); cada fila, dos celdas (alLeft + alClient).
  Cont := NuevoPanel(FResumenPage, alClient);
  Cont.BevelOuter := bvNone;

  Fila := NuevoPanel(Cont, alTop);
  Fila.Height := 300;
  Fila.BevelOuter := bvNone;
  FchR[0] := NuevoChart(NuevoPanel(Fila, alLeft));
  FchR[0].Parent.Width := 500;
  FchR[1] := NuevoChart(NuevoPanel(Fila, alClient));

  Fila := NuevoPanel(Cont, alClient);
  Fila.BevelOuter := bvNone;
  FchR[2] := NuevoChart(NuevoPanel(Fila, alLeft));
  FchR[2].Parent.Width := 500;
  FchR[3] := NuevoChart(NuevoPanel(Fila, alClient));

  // Los mini del resumen muestran los 4 primeros graficos registrados.
  for I := 0 to 3 do
    FchR[I].Title.Font.Size := 8;
end;

// ---------------------------------------------------------------------------
// Panel "Observaciones" DENTRO de la pagina del grafico (alBottom): asi no
// penaliza el ancho del arbol de la izquierda. Se rellena de una vez con el
// objetivo/utilidad de ESE grafico y se muestra/oculta con el boton global.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.ConstruirPanelObsEn(var G: TGraficoDef);
var
  Pnl: TPanel;
  Lbl: TLabel;
  Memo: TMemo;
  Txt: string;
begin
  Pnl := TPanel.Create(Self);
  Pnl.Parent := G.Pagina;
  Pnl.Align := alBottom;
  Pnl.Height := 150;
  Pnl.BevelOuter := bvNone;
  Pnl.Color := $00EDEDED;   // gris claro
  Pnl.ParentBackground := False;
  Pnl.Padding.SetBounds(12, 8, 12, 10);
  Pnl.Visible := False;     // arranca oculto; el boton global lo conmuta

  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.Align := alTop;
  Lbl.Caption := 'Observaciones  ·  ' + G.Titulo;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Size := 9;
  Lbl.Font.Color := $00404040;
  Lbl.Height := 18;
  Lbl.Layout := tlCenter;

  Memo := TMemo.Create(Self);
  Memo.Parent := Pnl;
  Memo.Align := alClient;
  Memo.BorderStyle := bsNone;
  Memo.Color := Pnl.Color;
  Memo.ReadOnly := True;
  Memo.TabStop := False;
  Memo.WordWrap := True;
  Memo.ScrollBars := ssVertical;
  Memo.Font.Size := 8;
  Memo.Font.Color := $00303030;

  // Contenido fijo del grafico (no cambia entre refrescos de datos): un unico
  // parrafo continuo que hila objetivo y utilidad (~100 palabras).
  Txt := Trim(G.Objetivo);
  if G.PorQue <> '' then
  begin
    if Txt <> '' then Txt := Txt + ' ';
    Txt := Txt + Trim(G.PorQue);
  end;
  if Txt = '' then
    Txt := 'Sin descripci'#243'n disponible para este gr'#225'fico.';
  Memo.Text := Txt;

  G.PanelObs := Pnl;
  G.MemoObs := Memo;
end;

// Aplica el estado global FObsVisible a los paneles de todos los graficos.
procedure TfrmPlanAnalisis.AplicarVisibilidadObs;
var
  I: Integer;
begin
  for I := 0 to FGraficos.Count - 1 do
    if FGraficos[I].PanelObs <> nil then
      FGraficos[I].PanelObs.Visible := FObsVisible;
end;

procedure TfrmPlanAnalisis.btnObsClick(Sender: TObject);
begin
  FObsVisible := not FObsVisible;
  AplicarVisibilidadObs;
  if FObsVisible then btnObs.Caption := 'Ocultar observaciones'
  else btnObs.Caption := 'Observaciones';
end;

procedure TfrmPlanAnalisis.tvNavClick(Sender: TObject);
var
  N: TTreeNode;
  Idx: Integer;
begin
  N := tvNav.Selected;
  if N = nil then Exit;
  Idx := Integer(N.Data);
  if Idx < 0 then Exit;  // nodo de categoria: no navega
  IrAPagina(Idx);
end;

procedure TfrmPlanAnalisis.IrAPagina(AIndexPagina: Integer);
begin
  if (AIndexPagina >= 0) and (AIndexPagina < pc.PageCount) then
    pc.ActivePageIndex := AIndexPagina;
end;

procedure TfrmPlanAnalisis.tvNavCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Idx: Integer;
begin
  DefaultDraw := True;
  Idx := Integer(Node.Data);
  if Idx = -1 then
    // Categoria: negrita, color suave.
    Sender.Canvas.Font.Style := [fsBold]
  else if Idx = -2 then
  begin
    // Pendiente: gris, cursiva (hoja de ruta de lo que falta).
    Sender.Canvas.Font.Color := clSilver;
    Sender.Canvas.Font.Style := [fsItalic];
  end
  else
    Sender.Canvas.Font.Style := [];
end;

procedure TfrmPlanAnalisis.btnActualizarClick(Sender: TObject);
begin
  Recalcular;
end;

procedure TfrmPlanAnalisis.btnAyudaClick(Sender: TObject);
begin
  THelpViewer.Show('uPlanAnalisis', 'An'#225'lisis del plan');
end;

procedure TfrmPlanAnalisis.Recalcular;
var
  Periodos: TArray<TPeriodoPlan>;
begin
  Screen.Cursor := crHourGlass;
  try
    Periodos := BuildPeriodosPlan(dtDesde.Date, spNum.Value,
      TGranularidadPlan(cmbGran.ItemIndex));
    FData := CalcularPlanAnalisis(Periodos);
    RepintarTodo;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmPlanAnalisis.RepintarTodo;
var
  I: Integer;
  G: TGraficoDef;
begin
  // Paginas de detalle
  for I := 0 to FGraficos.Count - 1 do
  begin
    G := FGraficos[I];
    if Assigned(G.Pintar) and (G.Chart <> nil) then
    begin
      G.Pintar(G.Chart);
      EstilizarSeries(G.Chart);
    end;
  end;
  // Resumen 2x2: los 4 primeros registrados
  for I := 0 to 3 do
    if (I < FGraficos.Count) and Assigned(FGraficos[I].Pintar) then
    begin
      FGraficos[I].Pintar(FchR[I]);
      EstilizarSeries(FchR[I]);
    end;
end;

// ---------------------------------------------------------------------------
// Estilo PRO comun a todas las series: sombra proyectada suave + gradiente en
// las barras y tartas. Se aplica de forma centralizada tras pintar cada
// grafico, sin tocar los 31 pintores uno a uno.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.EstilizarSeries(Ch: TChart);
var
  K: Integer;
  S: TChartSeries;
  Bar: TBarSeries;
  HBar: THorizBarSeries;
  Pie: TPieSeries;
  Lin: TLineSeries;

  // La propiedad Shadow NO existe en TChartSeries base: se declara en cada
  // subclase concreta. Este helper la configura una vez tenemos el TTeeShadow.
  procedure PonSombra(const Sh: TTeeShadow);
  begin
    Sh.Visible := True;
    Sh.Color := $00B8B0A8;
    Sh.HorizSize := 2;
    Sh.VertSize := 2;
    Sh.Transparency := 55;
  end;

begin
  for K := 0 to Ch.SeriesCount - 1 do
  begin
    S := Ch.Series[K];

    // Series intencionadamente invisibles (p.ej. la barra base del cronograma):
    // no aplicar sombra ni gradiente, dejarian un fantasma.
    if S.Transparency >= 100 then Continue;

    // Sombra + gradiente por tipo de serie (via cast concreto, nunca sobre la
    // base). OJO API: en barras el borde es BarPen (no Pen); el pie usa un
    // TTeeGradient distinto (sin Direction/Start/End) -> solo Visible.
    if S is THorizBarSeries then     // debe ir ANTES que TBarSeries (es subclase)
    begin
      HBar := THorizBarSeries(S);
      PonSombra(HBar.Shadow);
      HBar.BarStyle := bsRectangle;
      HBar.Gradient.Visible := True;
      HBar.Gradient.Direction := gdLeftRight;
      HBar.Gradient.StartColor := clWhite;
      HBar.Gradient.MidColor := HBar.SeriesColor;
      HBar.Gradient.EndColor := HBar.SeriesColor;
      HBar.BarPen.Color := $00909090;
      HBar.BarPen.Width := 1;
    end
    else if S is TBarSeries then
    begin
      Bar := TBarSeries(S);
      PonSombra(Bar.Shadow);
      Bar.BarStyle := bsRectangle;
      Bar.Gradient.Visible := True;
      Bar.Gradient.Direction := gdTopBottom;
      Bar.Gradient.StartColor := clWhite;      // brillo arriba
      Bar.Gradient.MidColor := Bar.SeriesColor;
      Bar.Gradient.EndColor := Bar.SeriesColor;
      Bar.BarPen.Color := $00909090;
      Bar.BarPen.Width := 1;
    end
    else if S is TPieSeries then
    begin
      Pie := TPieSeries(S);
      PonSombra(Pie.Shadow);
      Pie.Gradient.Visible := True;   // TTeeGradient del pie: solo activarlo
    end
    else if S is TLineSeries then
    begin
      Lin := TLineSeries(S);
      PonSombra(Lin.Shadow);
      Lin.LinePen.Width := 3;      // trazo mas grueso y limpio
    end;
  end;
end;

// ---------------------------------------------------------------------------
// 1. Carga vs Capacidad por centro
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarCargaVsCapacidad(Ch: TChart);
var
  Bar: TBarSeries;
  Lin: TLineSeries;
  I: Integer;
  C: TCargaCentro;
  Carga, Cap: Double;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Carga vs capacidad por centro (h)';

  Bar := TBarSeries.Create(Ch);
  Bar.Title := 'Carga';
  Bar.Marks.Visible := False;
  Bar.BarWidthPercent := 70;
  Ch.AddSeries(Bar);

  Lin := TLineSeries.Create(Ch);
  Lin.Title := 'Capacidad';
  Lin.Color := CLR_CAP;
  Lin.LinePen.Width := 2;
  Lin.Pointer.Visible := False;
  Ch.AddSeries(Lin);

  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    Carga := C.TotalCarga;
    Cap := C.TotalCapacidad;
    if (Carga <= 0) and (Cap <= 0) then Continue;
    if (Cap > 0) and (Carga > Cap) then Color := CLR_BAD else Color := CLR_CARGA;
    Bar.Add(Carga, C.Nombre, Color);
    Lin.Add(Cap, C.Nombre, CLR_CAP);
  end;
end;

// ---------------------------------------------------------------------------
// 2. Ocupacion por centro
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarOcupacion(Ch: TChart);
var
  Bar: THorizBarSeries;
  I: Integer;
  C: TCargaCentro;
  Pct: Double;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Ocupaci'#243'n por centro (%)';

  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Bar.BarWidthPercent := 60;
  Ch.AddSeries(Bar);

  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    if C.TotalCapacidad <= 0 then Continue;
    Pct := C.OcupacionPct;
    if Pct >= 100 then Color := CLR_BAD
    else if Pct >= 80 then Color := CLR_WARN
    else Color := CLR_OK;
    Bar.Add(Pct, C.Nombre, Color);
  end;
end;

// ---------------------------------------------------------------------------
// Recursos 1. Carga vs capacidad por operario
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarCargaVsCapacidadOperario(Ch: TChart);
var
  Bar: TBarSeries;
  Lin: TLineSeries;
  I: Integer;
  O: TCargaOperario;
  Carga, Cap: Double;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Carga vs capacidad por operario (h)';

  Bar := TBarSeries.Create(Ch);
  Bar.Title := 'Carga';
  Bar.Marks.Visible := False;
  Bar.BarWidthPercent := 70;
  Ch.AddSeries(Bar);

  Lin := TLineSeries.Create(Ch);
  Lin.Title := 'Capacidad';
  Lin.Color := CLR_CAP;
  Lin.LinePen.Width := 2;
  Lin.Pointer.Visible := False;
  Ch.AddSeries(Lin);

  for I := 0 to High(FData.Operarios) do
  begin
    O := FData.Operarios[I];
    Carga := O.TotalCarga;
    Cap := O.TotalCapacidad;
    if (Carga <= 0) and (Cap <= 0) then Continue;
    if (Cap > 0) and (Carga > Cap) then Color := CLR_BAD else Color := CLR_CARGA;
    Bar.Add(Carga, O.Nombre, Color);
    Lin.Add(Cap, O.Nombre, CLR_CAP);
  end;
end;

// ---------------------------------------------------------------------------
// Recursos 2. Ocupacion de operarios
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarOcupacionOperario(Ch: TChart);
var
  Bar: THorizBarSeries;
  I: Integer;
  O: TCargaOperario;
  Pct: Double;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Ocupaci'#243'n de operarios (%)';

  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Bar.BarWidthPercent := 60;
  Ch.AddSeries(Bar);

  for I := 0 to High(FData.Operarios) do
  begin
    O := FData.Operarios[I];
    if O.TotalCapacidad <= 0 then Continue;
    Pct := O.OcupacionPct;
    if Pct >= 100 then Color := CLR_BAD
    else if Pct >= 80 then Color := CLR_WARN
    else Color := CLR_OK;
    Bar.Add(Pct, O.Nombre, Color);
  end;
end;

// ---------------------------------------------------------------------------
// 3. Curva de carga temporal
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarCurva(Ch: TChart);
var
  Area: TAreaSeries;
  Lin: TLineSeries;
  J: Integer;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Carga total por periodo (h)';

  Area := TAreaSeries.Create(Ch);
  Area.Title := 'Carga';
  Area.Color := CLR_CARGA;
  Area.Transparency := 40;
  Area.Marks.Visible := False;
  Ch.AddSeries(Area);

  Lin := TLineSeries.Create(Ch);
  Lin.Title := 'Capacidad';
  Lin.Color := CLR_CAP;
  Lin.LinePen.Width := 2;
  Lin.Pointer.Visible := False;
  Ch.AddSeries(Lin);

  for J := 0 to High(FData.Periodos) do
  begin
    Area.Add(FData.CargaTotalPorPeriodo[J], FData.Periodos[J].Etiqueta, CLR_CARGA);
    Lin.Add(FData.CapacidadTotalPorPeriodo[J], FData.Periodos[J].Etiqueta, CLR_CAP);
  end;
end;

// ---------------------------------------------------------------------------
// 4. On-Time Delivery
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarOtd(Ch: TChart);
var
  Pie: TPieSeries;
  O: TOtdResultado;
begin
  Ch.RemoveAllSeries;
  O := FData.Otd;
  if O.RetrasoMedioDias > 0 then
    Ch.Title.Text.Text := Format('Entregas  ·  retraso medio %.1f d'#237'as',
      [O.RetrasoMedioDias])
  else
    Ch.Title.Text.Text := 'Cumplimiento de entregas';

  Pie := TPieSeries.Create(Ch);
  Pie.Marks.Visible := True;
  Pie.Marks.Style := smsLabelPercent;
  Pie.Circled := True;
  Ch.AddSeries(Pie);

  if O.ATiempo > 0 then       Pie.Add(O.ATiempo, 'A tiempo', CLR_OK);
  if O.EnRiesgo > 0 then      Pie.Add(O.EnRiesgo, 'En riesgo', CLR_WARN);
  if O.Retrasadas > 0 then    Pie.Add(O.Retrasadas, 'Retrasadas', CLR_BAD);
  if O.SinCompromiso > 0 then Pie.Add(O.SinCompromiso, 'Sin compromiso', $00B0B0B0);
end;

// ---------------------------------------------------------------------------
// 5. Carga apilada por centro x periodo (una serie de barras por centro)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarCargaApilada(Ch: TChart);
var
  I, J: Integer;
  C: TCargaCentro;
  Bar: TBarSeries;
  Paleta: array[0..9] of TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Carga apilada por centro (h)';
  Paleta[0] := $00C8924A; Paleta[1] := $0070C070; Paleta[2] := $004080F0;
  Paleta[3] := $00B05CD0; Paleta[4] := $0040C0C0; Paleta[5] := $005050E0;
  Paleta[6] := $00A0A040; Paleta[7] := $00E08020; Paleta[8] := $008080C0;
  Paleta[9] := $0060A0A0;

  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    if C.TotalCarga <= 0 then Continue;
    Bar := TBarSeries.Create(Ch);
    Bar.Title := C.Nombre;
    Bar.MultiBar := mbStacked;        // apilar las series
    Bar.Marks.Visible := False;
    Bar.SeriesColor := Paleta[I mod 10];
    Ch.AddSeries(Bar);
    for J := 0 to High(FData.Periodos) do
      Bar.Add(C.HorasCarga[J], FData.Periodos[J].Etiqueta, Paleta[I mod 10]);
  end;
  Ch.Legend.Visible := True;
  Ch.Legend.Alignment := laBottom;
end;

// ---------------------------------------------------------------------------
// 6. Pareto de carga por centro (barras desc. + linea % acumulado)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarPareto(Ch: TChart);
var
  I: Integer;
  Bar: TBarSeries;
  Lin: TLineSeries;
  Orden: TList<Integer>;
  Total, Acum: Double;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Pareto de carga por centro';

  // Ordenar indices por carga descendente.
  Orden := TList<Integer>.Create;
  try
    Total := 0;
    for I := 0 to High(FData.Centros) do
      if FData.Centros[I].TotalCarga > 0 then
      begin
        Orden.Add(I);
        Total := Total + FData.Centros[I].TotalCarga;
      end;
    Orden.Sort(TComparer<Integer>.Construct(
      function(const A, B: Integer): Integer
      begin
        Result := CompareValue(FData.Centros[B].TotalCarga,
                               FData.Centros[A].TotalCarga);
      end));

    Bar := TBarSeries.Create(Ch);
    Bar.Title := 'Carga (h)';
    Bar.Marks.Visible := False;
    Ch.AddSeries(Bar);

    Lin := TLineSeries.Create(Ch);
    Lin.Title := '% acumulado';
    Lin.Color := CLR_BAD;
    Lin.LinePen.Width := 2;
    Ch.AddSeries(Lin);

    Acum := 0;
    for I := 0 to Orden.Count - 1 do
    begin
      Bar.Add(FData.Centros[Orden[I]].TotalCarga,
              FData.Centros[Orden[I]].Nombre, CLR_CARGA);
      Acum := Acum + FData.Centros[Orden[I]].TotalCarga;
      if Total > 0 then
        Lin.Add(Acum / Total * 100.0, FData.Centros[Orden[I]].Nombre, CLR_BAD);
    end;
  finally
    Orden.Free;
  end;
end;

// ---------------------------------------------------------------------------
// 7. Sobrecarga por centro (nº periodos por encima del 100% de capacidad)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarSobrecarga(Ch: TChart);
var
  I, J, NSobre: Integer;
  C: TCargaCentro;
  Bar: THorizBarSeries;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Periodos en sobrecarga por centro';

  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);

  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    NSobre := 0;
    for J := 0 to High(FData.Periodos) do
      if (C.HorasCapacidad[J] > 0) and (C.HorasCarga[J] > C.HorasCapacidad[J]) then
        Inc(NSobre);
    if NSobre > 0 then
      Bar.Add(NSobre, C.Nombre, CLR_BAD);
  end;
end;

// ---------------------------------------------------------------------------
// 8. Distribucion de retrasos (histograma de buckets de dias)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarRetrasos(Ch: TChart);
const
  Etiq: array[0..6] of string =
    ('<=-3d', '-2d', '-1d', 'A tiempo', '+1d', '+2d', '>=+3d');
var
  Bar: TBarSeries;
  I: Integer;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Distribuci'#243'n de desviaci'#243'n vs compromiso';

  Bar := TBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);

  for I := 0 to 6 do
  begin
    if I < 3 then Color := CLR_OK          // adelantadas / a tiempo
    else if I = 3 then Color := CLR_OK
    else if I = 4 then Color := CLR_WARN    // +1d
    else Color := CLR_BAD;                  // +2d, +3d o mas
    Bar.Add(FData.Otd.Buckets[I], Etiq[I], Color);
  end;
end;

// ---------------------------------------------------------------------------
// 9. Salud del plan (gauge sintetico 0-100)
//    Combina: OTD (% a tiempo), utilizacion media y penalizacion por sobrecarga.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarSaludPlan(Ch: TChart);
var
  Pie: TPieSeries;
  I, J, NConCompromiso, NSobre, NCeldas: Integer;
  PctOTD, UtilMedia, PenalSobre, Salud, SumaUtil: Double;
  C: TCargaCentro;
  ColorSalud: TColor;
begin
  Ch.RemoveAllSeries;

  // 1) OTD: % a tiempo sobre las que tienen compromiso.
  NConCompromiso := FData.Otd.ATiempo + FData.Otd.EnRiesgo + FData.Otd.Retrasadas;
  if NConCompromiso > 0 then
    PctOTD := FData.Otd.ATiempo / NConCompromiso * 100.0
  else
    PctOTD := 100;

  // 2) Utilizacion media de los centros con capacidad (ideal ~75-85%).
  SumaUtil := 0; NCeldas := 0;
  for I := 0 to High(FData.Centros) do
    if FData.Centros[I].TotalCapacidad > 0 then
    begin
      SumaUtil := SumaUtil + FData.Centros[I].OcupacionPct;
      Inc(NCeldas);
    end;
  if NCeldas > 0 then UtilMedia := SumaUtil / NCeldas else UtilMedia := 0;
  // Puntuacion de utilizacion: 100 en el optimo 80%, cae a los extremos.
  UtilMedia := Max(0, 100 - Abs(UtilMedia - 80) * 1.5);

  // 3) Penalizacion por sobrecarga (celdas centro/periodo por encima de cap).
  NSobre := 0;
  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    for J := 0 to High(FData.Periodos) do
      if (C.HorasCapacidad[J] > 0) and (C.HorasCarga[J] > C.HorasCapacidad[J]) then
        Inc(NSobre);
  end;
  PenalSobre := Min(100, NSobre * 5);  // cada celda sobrecargada resta 5

  // Indice compuesto (ponderado): 50% OTD + 30% util + 20% (100-penal).
  Salud := PctOTD * 0.5 + UtilMedia * 0.3 + (100 - PenalSobre) * 0.2;
  Salud := Max(0, Min(100, Salud));

  if Salud >= 75 then ColorSalud := CLR_OK
  else if Salud >= 50 then ColorSalud := CLR_WARN
  else ColorSalud := CLR_BAD;

  Ch.Title.Text.Text := Format('Salud del plan:  %d / 100', [Round(Salud)]);

  // "Gauge" simple: tarta con la porcion de salud coloreada y el resto en gris.
  // (El % exacto y el color semaforo van en el titulo; no usamos donut para
  //  ser compatibles con esta version de TeeChart.)
  Pie := TPieSeries.Create(Ch);
  Pie.Marks.Visible := False;
  Pie.Circled := True;
  Ch.AddSeries(Pie);
  Pie.Add(Salud, 'Salud', ColorSalud);
  Pie.Add(100 - Salud, '', $00ECECEC);
end;

// ---------------------------------------------------------------------------
// Helper: barras horizontales de TItemHoras (top N por Horas o por Conteo).
// ---------------------------------------------------------------------------
procedure BarrasItemHoras(Ch: TChart; const AItems: TArray<TItemHoras>;
  const ATitulo: string; APorConteo: Boolean; AMax: Integer; ABaseColor: TColor);
var
  Bar: THorizBarSeries;
  I, N: Integer;
  V: Double;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := ATitulo;
  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  N := Length(AItems);
  if (AMax > 0) and (N > AMax) then N := AMax;
  for I := 0 to N - 1 do
  begin
    if APorConteo then V := AItems[I].Conteo else V := AItems[I].Horas;
    Bar.Add(V, AItems[I].Clave, ABaseColor);
  end;
end;

procedure TfrmPlanAnalisis.PintarPorArticulo(Ch: TChart);
begin
  BarrasItemHoras(Ch, FData.PorArticulo, 'Carga por art'#237'culo (h) - top 15',
    False, 15, CLR_CARGA);
end;

procedure TfrmPlanAnalisis.PintarPorOperacion(Ch: TChart);
begin
  BarrasItemHoras(Ch, FData.PorOperacion, 'Carga por tipo de operaci'#243'n (h) - top 15',
    False, 15, $00B05CD0);
end;

procedure TfrmPlanAnalisis.PintarOpsPorCentro(Ch: TChart);
begin
  BarrasItemHoras(Ch, FData.OpsPorCentro, 'N'#186' operaciones por centro',
    True, 0, $0040C0C0);
end;

// ---------------------------------------------------------------------------
// Top OF mas retrasadas (barras horizontales de dias de retraso)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarTopRetrasos(Ch: TChart);
var
  Bar: THorizBarSeries;
  I: Integer;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Top OF m'#225's retrasadas (d'#237'as)';
  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  for I := 0 to High(FData.TopRetrasos) do
    Bar.Add(FData.TopRetrasos[I].RetrasoDias, FData.TopRetrasos[I].Etiqueta, CLR_BAD);
end;

// ---------------------------------------------------------------------------
// Entregas por semana: a tiempo vs retrasadas (barras apiladas en el tiempo).
// Aproximacion: usamos los buckets globales de OTD repartidos no es posible por
// semana sin re-consulta; aqui mostramos el reparto agregado a tiempo/riesgo/
// retraso como barras (visión rapida). Para detalle temporal real se ampliaria.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarEntregasPorSemana(Ch: TChart);
var
  Bar: TBarSeries;
  O: TOtdResultado;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Entregas: cumplimiento (resumen)';
  O := FData.Otd;
  Bar := TBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  Bar.Add(O.ATiempo, 'A tiempo', CLR_OK);
  Bar.Add(O.EnRiesgo, 'En riesgo', CLR_WARN);
  Bar.Add(O.Retrasadas, 'Retrasadas', CLR_BAD);
  Bar.Add(O.SinCompromiso, 'Sin compr.', $00B0B0B0);
end;

// ---------------------------------------------------------------------------
// Makespan por proyecto (horas de ventana inicio->fin)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarMakespan(Ch: TChart);
var
  Bar: THorizBarSeries;
  I: Integer;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Makespan por proyecto (h)';
  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  for I := 0 to High(FData.Makespans) do
    Bar.Add(FData.Makespans[I].HorasSpan, FData.Makespans[I].Nombre, CLR_CARGA);
end;

// ---------------------------------------------------------------------------
// Distribucion de duraciones de operacion (histograma por buckets de minutos)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarDuraciones(Ch: TChart);
const
  Etiq: array[0..7] of string =
    ('<15m', '15-30m', '30-60m', '1-2h', '2-4h', '4-8h', '8-16h', '>16h');
var
  Bar: TBarSeries;
  I: Integer;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Distribuci'#243'n de duraciones de operaci'#243'n';
  Bar := TBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  for I := 0 to 7 do
    Bar.Add(FData.Duraciones[I], Etiq[I], CLR_CARGA);
end;

// ---------------------------------------------------------------------------
// % tiempo productivo vs setup por centro (barras apiladas)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarProductivoSetup(Ch: TChart);
var
  BarP, BarS: TBarSeries;
  I: Integer;
  PS: TProductivoSetup;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Tiempo productivo vs setup por centro (h)';

  BarP := TBarSeries.Create(Ch);
  BarP.Title := 'Productivo';
  BarP.MultiBar := mbStacked;
  BarP.SeriesColor := CLR_OK;
  BarP.Marks.Visible := False;
  Ch.AddSeries(BarP);

  BarS := TBarSeries.Create(Ch);
  BarS.Title := 'Setup';
  BarS.MultiBar := mbStacked;
  BarS.SeriesColor := CLR_WARN;
  BarS.Marks.Visible := False;
  Ch.AddSeries(BarS);

  for I := 0 to High(FData.ProductivoSetup) do
  begin
    PS := FData.ProductivoSetup[I];
    BarP.Add(PS.HorasProductivo, PS.Nombre, CLR_OK);
    BarS.Add(PS.HorasSetup, PS.Nombre, CLR_WARN);
  end;
  Ch.Legend.Visible := True;
  Ch.Legend.Alignment := laBottom;
end;

// ---------------------------------------------------------------------------
// Utilizacion media global (gauge/tarta con el % medio)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarUtilGlobal(Ch: TChart);
var
  Pie: TPieSeries;
  U: Double;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  U := FData.UtilMediaGlobal;
  if U > 100 then U := 100;
  if U >= 100 then Color := CLR_BAD
  else if U >= 80 then Color := CLR_WARN
  else Color := CLR_OK;
  Ch.Title.Text.Text := Format('Utilizaci'#243'n media global:  %.0f%%',
    [FData.UtilMediaGlobal]);
  Pie := TPieSeries.Create(Ch);
  Pie.Marks.Visible := False;
  Pie.Circled := True;
  Ch.AddSeries(Pie);
  Pie.Add(U, 'Utilizado', Color);
  Pie.Add(Max(0, 100 - U), 'Libre', $00ECECEC);
end;

// ===========================================================================
//  TANDA 3 (PRO)
// ===========================================================================

// ---------------------------------------------------------------------------
// Cronograma por proyecto (mini-Gantt): barra desde su inicio hasta su fin.
// Truco: barra base invisible = offset desde el inicio del horizonte;
// barra visible apilada encima = duracion. Compatible con esta version de
// TeeChart (sin TGanttSeries).
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarGanttResumen(Ch: TChart);
var
  BarBase, BarDur: THorizBarSeries;
  I: Integer;
  T0, Offset, Span: Double;
  G: TGanttResumen;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Cronograma por proyecto (d'#237'as)';
  if Length(FData.GanttResumen) = 0 then Exit;

  // Origen de tiempos = inicio mas temprano de todos los proyectos.
  T0 := FData.GanttResumen[0].Inicio;
  for I := 1 to High(FData.GanttResumen) do
    if FData.GanttResumen[I].Inicio < T0 then T0 := FData.GanttResumen[I].Inicio;

  BarBase := THorizBarSeries.Create(Ch);
  BarBase.MultiBar := mbStacked;
  BarBase.Marks.Visible := False;
  BarBase.SeriesColor := clWhite;
  BarBase.Transparency := 100;   // invisible: solo empuja la barra visible
  Ch.AddSeries(BarBase);

  BarDur := THorizBarSeries.Create(Ch);
  BarDur.MultiBar := mbStacked;
  BarDur.Marks.Visible := True;
  BarDur.Marks.Style := smsValue;
  BarDur.SeriesColor := CLR_CARGA;
  Ch.AddSeries(BarDur);

  for I := 0 to High(FData.GanttResumen) do
  begin
    G := FData.GanttResumen[I];
    Offset := G.Inicio - T0;          // dias desde el origen
    Span := G.Fin - G.Inicio;         // duracion en dias
    if Span <= 0 then Span := 0.5;
    BarBase.Add(Offset, G.Nombre, clWhite);
    BarDur.Add(Span, G.Nombre, CLR_CARGA);
  end;
end;

// ---------------------------------------------------------------------------
// Cadenas de dependencias mas largas (aproximacion al camino critico).
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarCadenas(Ch: TChart);
var
  Bar: THorizBarSeries;
  I: Integer;
  Etq: string;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Cadenas de dependencias m'#225's largas (h)';
  if Length(FData.Cadenas) = 0 then
  begin
    Ch.Title.Text.Text := 'Sin dependencias entre operaciones en el plan';
    Exit;
  end;
  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  for I := 0 to High(FData.Cadenas) do
  begin
    Etq := FData.Cadenas[I].Etiqueta +
      Format('  (%d ops)', [FData.Cadenas[I].NumOps]);
    Bar.Add(FData.Cadenas[I].HorasTotal, Etq, CLR_BAD);
  end;
end;

// ---------------------------------------------------------------------------
// Margen (holgura) hasta la fecha de entrega: barras divergentes.
//   Verde a la derecha = colchon; rojo a la izquierda = ya va tarde.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarMargenEntrega(Ch: TChart);
var
  Bar: THorizBarSeries;
  I: Integer;
  M: TMargenOF;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Margen hasta la entrega (d'#237'as) - los 15 m'#225's ajustados';
  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  for I := 0 to High(FData.MargenEntrega) do
  begin
    M := FData.MargenEntrega[I];
    if M.MargenDias < 0 then Color := CLR_BAD
    else if M.MargenDias < 2 then Color := CLR_WARN
    else Color := CLR_OK;
    Bar.Add(M.MargenDias, M.Etiqueta, Color);
  end;
end;

// ---------------------------------------------------------------------------
// Prioridad vs retraso (scatter): arriba-derecha = alta prioridad y tarde.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarPrioridadRetraso(Ch: TChart);
var
  Pts: TPointSeries;
  I: Integer;
  P: TPrioridadRetraso;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Prioridad vs retraso (arriba-dcha = urgente)';
  Pts := TPointSeries.Create(Ch);
  Pts.Pointer.Style := psCircle;
  Pts.Pointer.Size := 4;
  Pts.Marks.Visible := False;
  Ch.AddSeries(Pts);
  for I := 0 to High(FData.PrioridadRetraso) do
  begin
    P := FData.PrioridadRetraso[I];
    if (P.RetrasoDias > 0) and (P.Prioridad >= 4) then Color := CLR_BAD
    else if P.RetrasoDias > 0 then Color := CLR_WARN
    else Color := CLR_OK;
    // X = retraso (dias), Y = prioridad.
    Pts.AddXY(P.RetrasoDias, P.Prioridad, '', Color);
  end;
  Ch.BottomAxis.Title.Caption := 'Retraso (d'#237'as)';
  Ch.LeftAxis.Title.Caption := 'Prioridad';
end;

// ---------------------------------------------------------------------------
// CRP: carga acumulada vs capacidad acumulada (curva clasica de Capacity
// Requirements Planning). Si la carga cruza por encima de la capacidad, a
// partir de ese punto el plan es inviable con la capacidad actual.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarCrpAcumulada(Ch: TChart);
var
  LinCarga, LinCap: TLineSeries;
  J: Integer;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Carga acumulada vs capacidad acumulada (h)';

  LinCap := TLineSeries.Create(Ch);
  LinCap.Title := 'Capacidad acum.';
  LinCap.Color := CLR_OK;
  LinCap.LinePen.Width := 2;
  Ch.AddSeries(LinCap);

  LinCarga := TLineSeries.Create(Ch);
  LinCarga.Title := 'Carga acum.';
  LinCarga.Color := CLR_BAD;
  LinCarga.LinePen.Width := 2;
  Ch.AddSeries(LinCarga);

  for J := 0 to High(FData.Periodos) do
  begin
    LinCap.Add(FData.CapacidadAcumulada[J], FData.Periodos[J].Etiqueta, CLR_OK);
    LinCarga.Add(FData.CargaAcumulada[J], FData.Periodos[J].Etiqueta, CLR_BAD);
  end;
  Ch.Legend.Visible := True;
  Ch.Legend.Alignment := laBottom;
end;

// ---------------------------------------------------------------------------
// Balance de linea: desviacion de la ocupacion de cada centro respecto a la
// media. Barras que se van a un lado (sobrecargado) u otro (infrautilizado)
// revelan el desequilibrio del taller.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarBalanceLinea(Ch: TChart);
var
  Bar: THorizBarSeries;
  I, N: Integer;
  Media, Desv: Double;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Balance de l'#237'nea: desviaci'#243'n vs ocupaci'#243'n media (%)';

  // Media de ocupacion de los centros con capacidad.
  Media := 0; N := 0;
  for I := 0 to High(FData.Centros) do
    if FData.Centros[I].TotalCapacidad > 0 then
    begin Media := Media + FData.Centros[I].OcupacionPct; Inc(N); end;
  if N > 0 then Media := Media / N;

  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  for I := 0 to High(FData.Centros) do
    if FData.Centros[I].TotalCapacidad > 0 then
    begin
      Desv := FData.Centros[I].OcupacionPct - Media;
      if Abs(Desv) < 10 then Color := CLR_OK       // equilibrado
      else if Desv > 0 then Color := CLR_BAD       // por encima de la media
      else Color := CLR_WARN;                      // por debajo
      Bar.Add(Desv, FData.Centros[I].Nombre, Color);
    end;
end;

// ---------------------------------------------------------------------------
// Avance del plan: gauge de unidades fabricadas / a fabricar.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarProgreso(Ch: TChart);
var
  Pie: TPieSeries;
  Pct, Hechas, Total, Falta: Double;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Hechas := FData.Progreso.UnidadesFabricadas;
  Total := FData.Progreso.UnidadesAFabricar;
  if Total <= 0 then
  begin
    Ch.Title.Text.Text := 'Avance del plan: sin unidades registradas';
    Exit;
  end;
  Pct := Hechas / Total * 100.0;
  if Pct > 100 then Pct := 100;
  Falta := Max(0, Total - Hechas);
  if Pct >= 75 then Color := CLR_OK
  else if Pct >= 40 then Color := CLR_WARN
  else Color := CLR_BAD;
  Ch.Title.Text.Text := Format('Avance del plan:  %.0f%%  (%.0f / %.0f uds.)',
    [Pct, Hechas, Total]);
  Pie := TPieSeries.Create(Ch);
  Pie.Marks.Visible := False;
  Pie.Circled := True;
  Ch.AddSeries(Pie);
  Pie.Add(Hechas, 'Fabricado', Color);
  Pie.Add(Falta, 'Pendiente', $00ECECEC);
end;

// ---------------------------------------------------------------------------
// Carga por cliente (top 15).
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarPorCliente(Ch: TChart);
begin
  BarrasItemHoras(Ch, FData.PorCliente, 'Carga por cliente (h) - top 15',
    False, 15, $00E08020);
end;

// ---------------------------------------------------------------------------
// Trabajo en curso por estado (embudo aproximado con barras).
//   Estados: 0 Pendiente, 1 En curso, 2 Hecho, 3+ Otro.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarWipEstado(Ch: TChart);
const
  Etiq: array[0..4] of string =
    ('Pendiente', 'En curso', 'Hecho', 'Otro', 'Otro 2');
  Colores: array[0..4] of TColor =
    ($00B0B0B0, $0040A0F0, $0070C070, $00A0A040, $00C0C0C0);
var
  Bar: TBarSeries;
  I: Integer;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Trabajo en curso por estado (nº operaciones)';
  Bar := TBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  for I := 0 to 3 do   // agrupamos el 4 dentro de "Otro"
    Bar.Add(FData.Progreso.NodosPorEstado[I] +
            IfThen(I = 3, FData.Progreso.NodosPorEstado[4], 0),
            Etiq[I], Colores[I]);
end;

// ---------------------------------------------------------------------------
// Cobertura de personal por centro: operarios necesarios vs asignados.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarCobertura(Ch: TChart);
var
  BarNec, BarAsig: TBarSeries;
  I: Integer;
  C: TCoberturaCentro;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Cobertura de personal por centro (operarios)';

  BarNec := TBarSeries.Create(Ch);
  BarNec.Title := 'Necesarios';
  BarNec.SeriesColor := CLR_CAP;
  BarNec.Marks.Visible := False;
  Ch.AddSeries(BarNec);

  BarAsig := TBarSeries.Create(Ch);
  BarAsig.Title := 'Asignados';
  BarAsig.SeriesColor := CLR_CARGA;
  BarAsig.Marks.Visible := False;
  Ch.AddSeries(BarAsig);

  for I := 0 to High(FData.Cobertura) do
  begin
    C := FData.Cobertura[I];
    BarNec.Add(C.Necesarios, C.Nombre, CLR_CAP);
    BarAsig.Add(C.Asignados, C.Nombre, CLR_CARGA);
  end;
  Ch.Legend.Visible := True;
  Ch.Legend.Alignment := laBottom;
end;

// ---------------------------------------------------------------------------
// Ocupacion por centro y periodo (heatmap): una serie de barras apiladas por
// periodo, coloreada por nivel de saturacion. Da el "cuando" de la carga.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarOcupacionCalendario(Ch: TChart);

  function ColorSat(Pct: Double): TColor;
  begin
    if Pct >= 100 then Result := CLR_BAD
    else if Pct >= 80 then Result := CLR_WARN
    else if Pct >= 40 then Result := $0060C0C0    // verde-amarillo
    else Result := CLR_OK;
  end;

var
  I, J: Integer;
  C: TCargaCentro;
  Bar: TBarSeries;
  Pct, Cap: Double;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Ocupaci'#243'n por centro y periodo (%)';

  // Una serie apilada por centro; cada punto va coloreado por su saturacion.
  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    if C.TotalCapacidad <= 0 then Continue;
    Bar := TBarSeries.Create(Ch);
    Bar.Title := C.Nombre;
    Bar.MultiBar := mbStacked;
    Bar.Marks.Visible := False;
    Ch.AddSeries(Bar);
    for J := 0 to High(FData.Periodos) do
    begin
      Cap := C.HorasCapacidad[J];
      if Cap > 0 then Pct := C.HorasCarga[J] / Cap * 100.0 else Pct := 0;
      // Apilamos "1" por centro (peso igual) y coloreamos por saturacion, de
      // modo que la altura total = nº de centros y el color revela el periodo
      // caliente. El valor real (%) va en el tooltip via mark deshabilitada.
      Bar.Add(1, FData.Periodos[J].Etiqueta, ColorSat(Pct));
    end;
  end;
end;

end.
