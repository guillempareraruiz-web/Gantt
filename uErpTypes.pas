unit uErpTypes;

interface

uses
  System.SysUtils, System.DateUtils, System.Variants,
  Winapi.Windows, Winapi.Messages,
  System.Classes, System.Types, uCentreCalendar, uGAnttTypes,
  Vcl.Graphics;

type
  TErpSistema = (
    esSage200,
    esSageX3,
    esDynamics365BC,
    esOdoo,
    esSAPB1,
    esCegidEkon,
    esInforCS
  );

  TErpSistemaInfo = record
    Sistema: TErpSistema;
    Codigo: string;        // clave persistencia ("Sage200", "SageX3", ...)
    Nombre: string;        // nombre mostrado UI
    Iniciales: string;     // 2 letras para logo placeholder
    Descripcion: string;   // descripción corta
    Disponible: Boolean;   // false = "Próximamente"
  end;

const
  ERP_SISTEMAS: array[TErpSistema] of TErpSistemaInfo = (
    (Sistema: esSage200;        Codigo: 'Sage200';        Nombre: 'Sage 200';                                Iniciales: 'S2'; Descripcion: 'ERP Sage 200 (Espa'#241'a)';                       Disponible: True),
    (Sistema: esSageX3;         Codigo: 'SageX3';         Nombre: 'Sage X3';                                 Iniciales: 'SX'; Descripcion: 'ERP Sage X3';                                    Disponible: False),
    (Sistema: esDynamics365BC;  Codigo: 'Dynamics365BC';  Nombre: 'Microsoft Dynamics 365 Business Central'; Iniciales: 'BC'; Descripcion: 'ERP Microsoft Dynamics 365 Business Central';    Disponible: False),
    (Sistema: esOdoo;           Codigo: 'Odoo';           Nombre: 'Odoo';                                    Iniciales: 'OD'; Descripcion: 'ERP Odoo';                                       Disponible: False),
    (Sistema: esSAPB1;          Codigo: 'SAPB1';          Nombre: 'SAP Business One';                        Iniciales: 'SP'; Descripcion: 'ERP SAP Business One';                           Disponible: False),
    (Sistema: esCegidEkon;      Codigo: 'CegidEkon';      Nombre: 'Cegid XRP Enterprise / Ekon';             Iniciales: 'CE'; Descripcion: 'ERP Cegid XRP Enterprise (Ekon)';                Disponible: False),
    (Sistema: esInforCS;        Codigo: 'InforCS';        Nombre: 'Infor CloudSuite';                        Iniciales: 'IF'; Descripcion: 'ERP Infor CloudSuite';                           Disponible: False)
  );

type
  TGetCalendarFunc = reference to function(const CentreId: Integer): TCentreCalendar;

  //TLinkType = (ltFinishToStart);
  TLinkType = (
  ltFinishStart,
  ltStartStart,
  ltFinishFinish,
  ltStartFinish
);

  TErpOp = record
    OpId: Integer;

    Operacion: string;
    CentresTrabajo: TArray<string>;  // centres ERP permesos; buit = tots els centres
    CodigoColor: string;
    CodigoTalla: string;

    StartTime: TDateTime;
    EndTime: TDateTime;

    NumeroOF: Integer;
    SerieOF: string;

    CodigoProyecto: String;

    NumeroOT: Integer;
    NumeroTrabajo: String;

    EjercicioPedido: SmallInt;
    NumeroPedido: Integer;
    SeriePedido: string;

    CodigoCliente: string;

    FechaEntrega: TDateTime;
    FechaNecesaria: TDateTime;
    Stock: Double;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    PorcentajeDependencia: Double;

    UnidadesFabricadas: Double;
    UnidadesAFabricar: Double;
    TiempoUnidadFabSecs: Double; //...tiempo en segundos para fabricar una unidad
    DurationMin: Double; //...Segundos;
    DurationMinOriginal: Double; //...Segundos;
    OperariosNecesarios: Integer;
    OperariosAsignados: Integer;
    Estado: TNodoEstado;
    Tipo: TNodoTipo;

    Prioridad: Integer;  // 1 = alta, 2 = mitja, 3 = baixa (exemple)

    bkColorOp: TColor;
    borderColorOp: TColor;
  end;

  TErpLink = record
    FromNodeId: Integer;
    ToNodeId: Integer;
    LinkType: TLinkType;
    PorcentajeDependencia: Double; // 0..100
  end;

  TErpRaw = record
    Ops: TArray<TErpOp>;
    Links: TArray<TErpLink>;
  end;

  // ==========================================================================
  // Tipos neutros para lectura de detalle de Pedido (multi-ERP).
  // Cada implementacion concreta (Sage 200, SAP, Dynamics...) traduce de su
  // dialecto a estos registros.
  // ==========================================================================
  TPedidoCabecera = record
    Encontrado: Boolean;     // False = no existe en el ERP
    SeriePedido: string;
    NumeroPedido: Integer;
    EjercicioPedido: SmallInt;
    FechaPedido: TDateTime;
    FechaTope: TDateTime;
    NumeroLineas: Integer;
    CodigoCliente: string;
    RazonSocial: string;
    NombreComercial: string;
    CifDni: string;
    Domicilio: string;
    CodigoPostal: string;
    Municipio: string;
    Provincia: string;
    Nacion: string;
    FormaPago: string;
    NumeroPlazos: Integer;
    CodigoDivisa: string;
    FactorCambio: Double;
    BaseImponible: Double;
    TotalIva: Double;
    ImporteLiquido: Double;
    Aprobado: Boolean;
    Comentario: string;
    Comentarios: string;
  end;

  TPedidoLinea = record
    Orden: Integer;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    Unidades: Double;
    UnidadMedida: string;
    Precio: Double;
    Descuento1: Double;
    Descuento2: Double;
    ImporteLiquido: Double;
    FechaServicio: TDateTime;
    FechaNecesaria: TDateTime;
    UnidadesServidas: Double;
    UnidadesPendientes: Double;
    Comentario: string;
  end;

  // ==========================================================================
  // Tipos neutros para lectura de Formula / Escandall (multi-ERP).
  // ==========================================================================
  TFormulaCabecera = record
    Encontrada: Boolean;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    Version: SmallInt;        // 'Formula' en Sage; identificador de version
    CosteArticulos: Double;
  end;

  TFormulaComponente = record
    Orden: Integer;
    CodigoArticuloComponente: string;
    DescripcionArticulo: string;
    UnidadesNecesarias: Double;
    UnidadMedida: string;
    Mermas: Double;
    CosteUnitario: Double;
    CosteComponente: Double;
    EsSemielaborado: Boolean;       // True si tiene formula propia
    VersionFormulaComp: SmallInt;   // version de la formula del semielab. (0 si N/A)
    OperacionAsociada: string;      // operacion donde se consume
  end;

  TFormulaOperacion = record
    Orden: Integer;
    Operacion: string;
    DescripcionOperacion: string;
    CentroTrabajo: string;
    TiempoPreparacionMin: Double;
    TiempoFabricacionMin: Double;
    TiempoTotalMin: Double;
    EsExterna: Boolean;
  end;

  // ==========================================================================
  // "Donde se usa" / Where-used: fila por cada formula de otro articulo que
  // contiene el articulo consultado como componente. Una sola fila por
  // (ArticuloPadre, Version, Orden) — si aparece en varias versiones o varias
  // veces en la misma formula salen tantas filas.
  // Origen Sage 200: Mat_Formula JOIN Articulos por el codigo padre.
  // ==========================================================================
  // ==========================================================================
  // Punto historico mensual de un articulo. Una fila por (Ejercicio, Periodo)
  // con totales de unidades entradas (compres + produccions OF) y sortides
  // (consums + vendes). Stock final = saldo viu al final del mes (si conegut).
  // Origen Sage 200: AcumuladoStock (Periodo 1..12 = mes natural; Periodo 99
  // = saldo viu del Ejercicio, no contat aqui).
  // ==========================================================================
  // ==========================================================================
  // OF activa per article: ordre de fabricacio en curs o pendent que produeix
  // aquest article. Una fila per OF. Inclou progres i data prevista final.
  // Origen Sage 200: OrdenesFabricacion filtrat per CodigoArticulo i EstadoOF
  // no finalitzat.
  // ==========================================================================
  // ==========================================================================
  // OF global (cap article concret) per al Dashboard operatiu. Inclou el codi
  // d'article fabricat i descripcio per identificar la OF d'un cop d'ull.
  // ==========================================================================
  TOFGlobalErp = record
    EjercicioFabricacion: SmallInt;
    SerieFabricacion: string;
    NumeroFabricacion: Integer;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    FechaInicioPrevista: TDateTime;
    FechaFinalPrevista: TDateTime;
    UnidadesAFabricar: Double;
    UnidadesFabricadas: Double;
    PorcentajeProgreso: Double;
    EstadoOF: Integer;
    EstadoDescripcion: string;
    DiasDesfase: Integer;             // Hoy - FechaFinalPrevista (negatiu = a temps)
  end;

  // ==========================================================================
  // Articulo clau (categoria A) sense stock disponible. Combina ABC + stock.
  // ==========================================================================
  TArticuloACriticoErp = record
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoFamilia: string;
    Disponible: Double;
    StockMinimo: Double;
    ImporteConsumidoUltAno: Double;   // facturacio derivada del consum
    UnidadMedida: string;
  end;

  TOFActivaArticuloErp = record
    EjercicioFabricacion: SmallInt;
    SerieFabricacion: string;
    NumeroFabricacion: Integer;
    FechaCreacion: TDateTime;
    FechaInicioPrevista: TDateTime;
    FechaFinalPrevista: TDateTime;
    FechaEntrega: TDateTime;
    UnidadesAFabricar: Double;
    UnidadesFabricadas: Double;
    PorcentajeProgreso: Double;     // calculat = Fabricadas / AFabricar * 100
    EstadoOF: Integer;              // 0=alta, 1=lanzada, 2=en curso, 3=finalizada...
    EstadoDescripcion: string;      // text llegible
    Prioridad: string;
    CodigoProyecto: string;
  end;

  // ==========================================================================
  // Proveedor que ha subministrat un article. Una fila per proveedor amb
  // estadistiques agregades dels pedidos de compra historics. Util per saber
  // qui te lead time mes curt, qui te millor preu, qui ha rebut menys recent.
  // Origen Sage 200: LineasPedidoProveedor + CabeceraPedidoProveedor.
  // ==========================================================================
  TProveedorArticuloErp = record
    CodigoProveedor: string;
    RazonSocialProveedor: string;
    PrecioUltimaCompra: Double;
    FechaUltimaCompra: TDateTime;
    PrecioMedioCompra: Double;       // mitjana ponderada de tots els pedidos
    LeadTimeMedio: Double;           // dies entre FechaPedido i FechaRecepcion
    UnidadesCompradasTotal: Double;
    NumeroPedidosTotal: Integer;
  end;

  // ==========================================================================
  // Client que ha comprat un article. Una fila per client amb estadistiques
  // agregades dels pedidos de venda fins fa N mesos. Util per identificar
  // clients clau abans d'una ruptura.
  // Origen Sage 200: LineasPedidoCliente + CabeceraPedidoCliente.
  // ==========================================================================
  TClienteArticuloErp = record
    CodigoCliente: string;
    RazonSocialCliente: string;
    UnidadesVendidasTotal: Double;
    ImporteVendidoTotal: Double;
    PrecioMedio: Double;
    FechaUltimaVenta: TDateTime;
    NumeroPedidosTotal: Integer;
  end;

  THistoricoMesErp = record
    Ejercicio: SmallInt;
    Periodo: SmallInt;              // 1..12
    UnidadesEntrada: Double;
    UnidadesSalida: Double;
    CosteEntrada: Double;
    CosteSalida: Double;
  end;

  TDondeSeUsaErp = record
    CodigoArticuloPadre: string;       // articulo que USA el consultado
    DescripcionArticuloPadre: string;
    TipoArticuloPadre: string;
    VersionFormula: SmallInt;
    Orden: Integer;
    UnidadesNecesarias: Double;        // cantidad de "nuestro" art. por unidad del padre
    UnidadMedida: string;
    Mermas: Double;
    Operacion: string;                 // operacion donde se consume (puede ser vacio)
  end;

  // ==========================================================================
  // Empresa definida en el ERP (multi-empresa). Para Sage 200 cada CodigoEmpresa
  // identifica un juego de datos separado en la misma BD.
  // ==========================================================================
  TEmpresaErp = record
    Codigo: Integer;
    Nombre: string;
  end;

  // ==========================================================================
  // Articulo del catalogo del ERP. Subconjunto de campos relevantes para
  // planificacion (codigo, descripcion, familia, unidad, stock objetivo,
  // precios, bloqueos). Cada conector traduce su modelo a esta forma neutra.
  // ==========================================================================
  TArticuloErp = record
    Codigo: string;
    Descripcion: string;
    Descripcion2: string;
    TipoArticulo: string;
    CodigoFamilia: string;
    CodigoSubfamilia: string;
    UnidadMedida: string;
    StockMinimo: Double;
    StockMaximo: Double;
    PrecioCompra: Double;
    PrecioVenta: Double;
    CosteFabricacionUnitario: Double;
    PrecioCosteEstandar: Double;
    BloqueoCompra: Boolean;
    BloqueoPedidoCompra: Boolean;
    BloqueoPedidoVenta: Boolean;
    PublicarInternet: Boolean;
    FechaAlta: TDateTime;
    Activo: Boolean;
    TieneFormula: Boolean;   // True si existe al menos una formula para el articulo (PA/SE fabricable)
  end;

  // ==========================================================================
  // Familia / subfamilia. A Sage l'estructura es (CodigoFamilia, CodigoSubfamilia)
  // amb totes dues a la PK; el codi de subfamilia pot ser buit per files
  // que son "familia pare". Cada conector tradueix al seu model.
  // ==========================================================================
  TFamiliaErp = record
    CodigoFamilia: string;
    CodigoSubfamilia: string;
    Descripcion: string;
    TipoF: string;
    CodigoSeccion: string;
    CodigoDepartamento: string;
  end;

  // ==========================================================================
  // Cliente. Subconjunto pragmatic de camps; el record sencer de Sage te
  // 250+ camps. Aqui els que necessitem per planificacio i contacte.
  // ==========================================================================
  TClienteErp = record
    Codigo: string;
    RazonSocial: string;
    Nombre: string;
    CifDni: string;
    Domicilio: string;
    CodigoPostal: string;
    Municipio: string;
    Provincia: string;
    Nacion: string;
    Telefono: string;
    Email: string;
    FormaPago: string;
    CodigoDivisa: string;
    BloqueoPedido: Boolean;
    BloqueoAlbaran: Boolean;
    FechaAlta: TDateTime;
    Observaciones: string;
  end;

  // ==========================================================================
  // Almacen.
  // ==========================================================================
  TAlmacenErp = record
    Codigo: string;
    Nombre: string;
    GrupoAlmacen: string;
    Responsable: string;
    Domicilio: string;
    CodigoPostal: string;
    Municipio: string;
    Provincia: string;
    Telefono: string;
  end;

  // ==========================================================================
  // Orden de fabricacion (cabecera). A Sage l'OF es una sola fila (no te
  // taula de "lineas"): les operacions venen de Oper_Formula via Formula+
  // CodigoArticulo. La planificacio normalment treballa amb aquesta cabecera
  // i resol operacions per la formula referenciada.
  // ==========================================================================
  // Valor de un campo custom poblado desde el ERP via mapeo (FS_PL_Cfg_ErpFieldMap).
  // FieldKey = el de la columna custom; Value = lo leido del ERP. Se escribe luego
  // en FS_PL_RawItem_Extra con Source='ERP' durante la sincronizacion.
  TErpExtraValue = record
    FieldKey: string;
    Value: Variant;
  end;

  // Mapeo de una columna custom (FieldKey) a una expresion SQL libre contra el
  // ERP + JOINs opcionales. Persistido en FS_PL_Cfg_ErpFieldMap (BD Planner).
  // El reader ERP solo lo RECIBE para inyectarlo; quien lo carga es la capa
  // Planner (uErpSyncRepo), que es la que conoce esa tabla.
  TErpFieldMap = record
    GridId: string;          // 'BACKLOG'
    FieldKey: string;        // = FieldKey de la columna custom
    ErpSource: string;       // 'SAGE200'
    SqlExpression: string;   // expresion SQL libre
    SqlJoins: string;        // JOINs extra (puede ser vacio)
    AppliesToNivel: Integer; // 1/2/3; 0 = no especificado
    Activo: Boolean;
  end;

  TOrdenFabricacionErp = record
    EjercicioFabricacion: SmallInt;
    SerieFabricacion: string;
    NumeroFabricacion: Integer;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    Formula: SmallInt;
    FechaCreacion: TDateTime;
    FechaLanzamiento: TDateTime;
    FechaInicioPrevista: TDateTime;
    FechaFinalPrevista: TDateTime;
    FechaInicioReal: TDateTime;
    FechaFinalReal: TDateTime;
    FechaEntrega: TDateTime;
    UnidadesAFabricar: Double;
    UnidadesFabricadas: Double;
    EstadoOF: Integer;
    Prioridad: string;
    TipoFabricacion: string;
    BloqueoPlanificacion: Boolean;
    CodigoProyecto: string;
    Observaciones: string;
    ExtraFields: TArray<TErpExtraValue>;   // campos custom mapeados (Nivel 1)
  end;

  // ==========================================================================
  // Orden de Trabajo (OT): unitat real de produccio. Una OF (article final)
  // generara N OTs (article final + tots els semielaborats que cal fabricar).
  // L'enllac OT<->OF viu a la taula RelacionOTOF.
  // ==========================================================================
  TOrdenTrabajoErp = record
    EjercicioTrabajo: SmallInt;
    NumeroTrabajo: Integer;
    PeriodoFabricacion: SmallInt;
    Formula: SmallInt;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    NivelCompuesto: Integer;
    CodigoAlmacen: string;
    FechaCreacion: TDateTime;
    FechaInicioPrevista: TDateTime;
    FechaFinalPrevista: TDateTime;
    TiempoPreparacion: Double;
    TiempoFabricacion: Double;
    TiempoTotal: Double;
    EstadoOT: Integer;
    UnidadesAFabricar: Double;
    EjercicioFabricacion: SmallInt;
    SerieFabricacion: string;
    NumeroFabricacion: Integer;
    ExtraFields: TArray<TErpExtraValue>;   // campos custom mapeados (Nivel 2)
  end;

  // ==========================================================================
  // Operacio d'una OT. Es la fila planificable: te centre, durades previstes
  // i reals, costos, dependencia amb la seguent (%ParaSigOperacion).
  // ==========================================================================
  TOperacionOTErp = record
    EjercicioTrabajo: SmallInt;
    NumeroTrabajo: Integer;
    Orden: SmallInt;
    Operacion: string;
    DescripcionOperacion: string;
    CentroTrabajo: string;
    CentroTrabajoDefecto: string;
    OperacionExterna: Boolean;
    TiempoPreparacion: Double;
    TiempoFabricacion: Double;
    TiempoTotal: Double;
    UnidadesAFabricar: Double;
    UnidadesFabricadas: Double;
    CosteHoraMaquina: Double;
    CosteHoraManoObra: Double;
    PorcentajeParaSigOperacion: Double;
    PorcentajeDedicacionOperario: Double;
    FechaInicioPrevista: TDateTime;
    FechaFinalPrevista: TDateTime;
    FechaInicioReal: TDateTime;
    FechaFinalReal: TDateTime;
    EstadoOperacion: Integer;
    StatusPlanificado: Boolean;
    // Campos extra de alto valor para el backlog (planificar/ordenar/filtrar).
    UnidadesHora: Double;
    CodigoProveedor: string;     // si OperacionExterna: proveedor subcontratista
    SeccionFabrica: string;
    Observaciones: string;
    ExtraFields: TArray<TErpExtraValue>;   // campos custom mapeados (Nivel 3)
  end;

  // ==========================================================================
  // Consum d'una OT: components materials consumits (Mat_Formula expandit
  // per a la OT real).
  // ==========================================================================
  TConsumoOTErp = record
    EjercicioTrabajo: SmallInt;
    NumeroTrabajo: Integer;
    Orden: SmallInt;
    ArticuloComponente: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    Operacion: string;
    UnidadesNecesarias: Double;
    UnidadesUsadas: Double;
    UnidadesEntregadas: Double;
    Mermas: Double;
    MermasReales: Double;
    CosteUnitario: Double;
    CosteComponente: Double;
    NivelCompuesto: Integer;
    UnidadMedida: string;
  end;

  // ==========================================================================
  // Enllac OT <-> OF (multi-OT per OF: article final + semielaborats).
  // ==========================================================================
  TRelacionOTOFErp = record
    EjercicioFabricacion: SmallInt;
    SerieFabricacion: string;
    NumeroFabricacion: Integer;
    EjercicioTrabajo: SmallInt;
    NumeroTrabajo: Integer;
    EsArticuloFinal: Boolean;
    NumeroTrabajoFinal: Integer;
    UnidadesAFabricar: Double;
    UnidadesFabricadas: Double;
  end;

  // ==========================================================================
  // Proyecto ERP. A Sage la taula es Proyectos. Es el "encargo" del client
  // (planning per projecte, no per OF).
  // ==========================================================================
  TProyectoErp = record
    Codigo: string;
    Nombre: string;
    Tipo: string;
    Estado: Integer;
    PorcentajeCompletado: Integer;
    FechaInicio: TDateTime;
    FechaFinal: TDateTime;
    FechaTope: TDateTime;
    FechaAprobacion: TDateTime;
    FechaCierre: TDateTime;
    CodigoResponsable: string;
    CodigoDepartamento: string;
    Observaciones: string;
  end;

  // ==========================================================================
  // Tarea d'un projecte. A Sage la taula es LcProyectoTareas; estructura
  // jerarquica via IdTareaPadre (uniqueidentifier). Cada tarea te durada
  // (prevista/optimista/pessimista/estimada) i % completat.
  // ==========================================================================
  TTareaProyectoErp = record
    CodigoProyecto: string;
    IdTarea: string;
    IdTareaPadre: string;
    Orden: Integer;
    Nombre: string;
    EsHito: Boolean;
    EsCritica: Boolean;
    FechaInicial: TDateTime;
    FechaRealInicio: TDateTime;
    FechaFinal: TDateTime;
    FechaFinalEstimada: TDateTime;
    FechaRealFinalizacion: TDateTime;
    FechaTope: TDateTime;
    Prioridad: Integer;
    PorcentajeCompletado: Integer;
    DuracionPrevista: Double;
    DuracionEstimada: Double;
    TipoUnidad: string;
    NumeroRevision: Integer;
  end;

  // ==========================================================================
  // Grupo horario: etiqueta que se asigna a un operario o a un centro.
  // Cataologo simple (codigo + descripcion). El contenido real de horarios
  // vive en ModelosHorarios + LineasModelosHorarios + CalendarioCentro.
  // ==========================================================================
  TGrupoHorarioErp = record
    Codigo: string;
    Descripcion: string;
  end;

  // ==========================================================================
  // Modelo horario: catalogo de tipos de jornada (turno dia, noche, partido).
  // Las lineas (LineasModelosHorarios) definen los tramos del modelo.
  // ==========================================================================
  TModeloHorarioErp = record
    Codigo: Integer;
    Descripcion: string;
  end;

  // ==========================================================================
  // Linea de modelo horario: tramo horario de un modelo concreto.
  // Las horas vienen como decimal (0..24, fraccional).
  // ==========================================================================
  TLineaModeloHorarioErp = record
    ModeloHorario: Integer;
    Orden: Integer;
    Turno: Integer;
    TipoTurno: string;
    HoraInicio: Double;
    HoraFinal: Double;
    HoraInicioPermitida: Double;
    HoraFinPermitida: Double;
    HoraInicioExtra: Double;
    HoraFinExtra: Double;
  end;

  // ==========================================================================
  // Calendario diario operativo de un centro de trabajo. Para cada (centro,
  // fecha) indica el modelo horario que aplica + duracion real de jornada
  // y descanso.
  // ==========================================================================
  // ==========================================================================
  // Una fila del calendario laboral del ERP. A Sage 200 la taula es
  // `CalendarioLaboral` amb clau (CodigoEmpresa, GrupoHorario, Fecha).
  // Per cada (grup, dia): quin model horari aplica i durada efectiva.
  // Duracion = 0 indica dia no laborable (festiu o cap de setmana).
  // ==========================================================================
  TCalendarioLaboralErp = record
    GrupoHorario: string;
    Fecha: TDateTime;
    ModeloHorario: Integer;
    Duracion: Double;
    DuracionDescanso: Double;
  end;

  // ==========================================================================
  // Maquina del ERP. Modelo simple: identificador + marca/modelo + costes y
  // factores. La asignacion a centros vive en TCentroMaquinaErp.
  // ==========================================================================
  TMaquinaErp = record
    Codigo: string;
    Marca: string;
    Modelo: string;
    Descripcion: string;
    PorcentajeCorreccionPreparacion: Double;
    PorcentajeCorreccionFabricacion: Double;
    CosteHoraMaquina: Double;
    UnidadesHora: Double;
  end;

  // ==========================================================================
  // Operario del ERP. Subconjunto de campos relevantes para planificacion
  // (identidad, costes hora normal/extra, turno, grupo horario, fechas).
  // ==========================================================================
  TOperarioErp = record
    Codigo: Integer;
    Nombre: string;
    FechaAlta: TDateTime;
    FechaBaja: TDateTime;
    Cargo: string;
    CosteHoraNormal: Double;
    CosteHoraExtra: Double;
    Turno: Integer;
    GrupoHorario: string;
    Telefono: string;
    Email: string;
  end;

  // ==========================================================================
  // Asignacion N:M Centro -> Maquina segun ERP. Inclou ordre dins el centre,
  // cost hora i percentatges de correccio especifics per a la combinacio.
  // ==========================================================================
  TCentroMaquinaErp = record
    CentroTrabajo: string;
    Orden: Integer;
    Maquina: string;
    CosteHoraMaquina: Double;
    PorcentajeCorreccionPreparacion: Double;
    PorcentajeCorreccionFabricacion: Double;
  end;

  // ==========================================================================
  // Centro de trabajo leido del ERP. Campos neutros que cualquier conector
  // ERP debe poder rellenar. Los campos especificos no estandar se mapean a
  // FS_PL_Center_Extra (Source='ERP') al importar.
  // ==========================================================================
  TCentroTrabajoErp = record
    Codigo: string;                    // identificador en el ERP
    Descripcion: string;               // nombre / descripcion humana
    PermiteConcurrencia: Boolean;      // True = se solapan tareas; False = secuencial
    MaquinasFabricacion: Integer;      // nº maquinas que tiene asignadas
    OperariosFabricacion: Integer;
    OperariosPreparacion: Integer;
    PorcentajeDedicacionOperario: Double;
    PorcentajeCorreccionPreparacion: Double;
    PorcentajeCorreccionFabricacion: Double;
    CosteHoraManoObra: Double;
    CosteHoraMaquina: Double;
    GrupoHorario: string;
    MaquinaPrincipal: string;
  end;

  // ==========================================================================
  // STOCK detallado por partida/lote. Una fila por combinacion (articulo +
  // almacen + partida + color + talla) del Ejercicio/Periodo solicitado.
  // Origen Sage 200: AcumuladoStock.
  // ==========================================================================
  TStockArticuloErp = record
    Ejercicio: SmallInt;
    Periodo: SmallInt;
    CodigoArticulo: string;
    CodigoAlmacen: string;
    Partida: string;
    CodigoColor: string;
    CodigoTalla: string;
    UnidadEntrada: Double;
    UnidadSalida: Double;
    UnidadSaldo: Double;
    UnidadCompra: Double;
    UnidadConsumo: Double;
    ImporteSaldo: Double;
    PrecioMedio: Double;
    PrecioUltimaEntrada: Double;
    PrecioUltimaSalida: Double;
    FechaUltimaEntrada: TDateTime;
    FechaUltimaSalida: TDateTime;
    FechaCaducidad: TDateTime;
    Ubicacion: string;
  end;

  // ==========================================================================
  // STOCK disponible (resumen MRP) por articulo+almacen. Una fila por
  // (articulo + almacen + color + talla) ya agregada por Sage.
  // Origen Sage 200: AcumuladoStock_Neco.
  // Campo Disponible = UnidadSaldo - StockReservado (lo calcula el reader).
  // ==========================================================================
  TStockDisponibleErp = record
    CodigoArticulo: string;
    CodigoAlmacen: string;
    CodigoColor: string;
    CodigoTalla: string;
    UnidadSaldo: Double;          // stock fisico actual
    PendienteRecibir: Double;     // pedidos compra pendientes
    PendienteServir: Double;      // pedidos cliente pendientes
    PendienteFabricar: Double;    // OFs en curso
    StockReservado: Double;       // reservado por pedidos venta
    Planificado: Double;          // necesidad MRP
    Disponible: Double;           // calculado = UnidadSaldo - StockReservado
  end;

  // ==========================================================================
  // Entrada futura prevista: linea de pedido de compra con UnidadesPendientes>0.
  // Sirve para saber que stock entrara y cuando. Origen Sage 200:
  // LineasPedidoProveedor + CabeceraPedidoProveedor.
  // ==========================================================================
  TEntradaFuturaErp = record
    EjercicioPedido: SmallInt;
    SeriePedido: string;
    NumeroPedido: Integer;
    Orden: SmallInt;
    FechaPedido: TDateTime;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    Partida: string;
    CodigoProveedor: string;
    RazonSocialProveedor: string;
    UnidadesPedidas: Double;
    UnidadesRecibidas: Double;
    UnidadesPendientes: Double;
    Precio: Double;
    ImporteNetoPendiente: Double;
    FechaNecesaria: TDateTime;
    FechaRecepcion: TDateTime;
    FechaTope: TDateTime;
    Estado: Byte;
  end;

  // ==========================================================================
  // Salida futura prevista per venda: linea de pedido client amb
  // UnidadesPendientes>0. Origen Sage 200: LineasPedidoCliente + Cabecera.
  // ==========================================================================
  TSalidaFuturaVentaErp = record
    EjercicioPedido: SmallInt;
    SeriePedido: string;
    NumeroPedido: Integer;
    Orden: SmallInt;
    FechaPedido: TDateTime;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    CodigoCliente: string;
    RazonSocialCliente: string;
    UnidadesPedidas: Double;
    UnidadesServidas: Double;
    UnidadesPendientes: Double;
    Precio: Double;
    FechaServicio: TDateTime;
    FechaNecesaria: TDateTime;
    FechaTope: TDateTime;
    Estado: Byte;
  end;

  // ==========================================================================
  // Moviment futur generat per OFs pendents (producci'o + consum).
  // Una OF en curs aporta dos tipus de moviments:
  //   - Produccio del producte acabat (+ stock) a FechaFinalPrevista
  //   - Consum de cada matriu (- stock) a FechaInicioPrevista
  // Origen Sage 200: OrdenesFabricacion + Mat_Trabajo (consums planificats).
  // ==========================================================================
  TMovOFErp = record
    EjercicioFabricacion: SmallInt;
    SerieFabricacion: string;
    NumeroFabricacion: Integer;
    EsProduccion: Boolean;        // True = producte acabat; False = consum
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    Unidades: Double;             // sempre positiu; el signe el d'ona EsProduccion
    Fecha: TDateTime;             // data prevista (final o inici segons tipus)
    EstadoOF: Integer;
  end;

  // ==========================================================================
  // Stock cr'itico: fila per article+almacen on Disponible (=Saldo-Reservado)
  // est'a per sota del StockMinimo del articulo. Usat al Stock Cockpit.
  // ==========================================================================
  TStockCriticoErp = record
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    UnidadSaldo: Double;
    StockReservado: Double;
    Disponible: Double;           // Saldo - Reservado
    PendienteRecibir: Double;
    PendienteServir: Double;
    StockMinimo: Double;
    StockMaximo: Double;
    Deficit: Double;              // StockMinimo - Disponible (positiu = crisi)
    CodigoFamilia: string;
    UnidadMedida: string;
  end;

  // ==========================================================================
  // Stock obsoleto: articulo con saldo > 0 y sin movimientos hace >= N meses.
  // Indicador del valor parado en almacen.
  // ==========================================================================
  TStockObsoletoErp = record
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    CodigoFamilia: string;
    UnidadSaldo: Double;
    ImporteSaldo: Double;         // Saldo valorado a precio medio
    PrecioMedio: Double;
    FechaUltimaEntrada: TDateTime;
    FechaUltimaSalida: TDateTime;
    DiasSinMovimiento: Integer;   // dies des de l'ultim mov (max entrada/sortida)
    UnidadMedida: string;
  end;

  // ==========================================================================
  // Cobertura (Days of Supply): saldo actual dividit pel consum diari mitja
  // dels ultims N dies. "Em duraran X dies amb el ritme actual."
  // ==========================================================================
  TCoberturaErp = record
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    CodigoFamilia: string;
    UnidadSaldo: Double;
    ConsumoPeriodo: Double;       // Total consumit als N dies
    DiasPeriodo: Integer;         // N (per a calcular consum diari)
    ConsumoDiario: Double;        // ConsumoPeriodo / DiasPeriodo
    DiasCobertura: Double;        // Saldo / ConsumoDiario (-1 si sense consum)
    StockMinimo: Double;
    UnidadMedida: string;
  end;

  // ==========================================================================
  // Analisi ABC: classificacio per import de consum dels ultims N dies.
  // Categoria: 'A' (top 80% valor), 'B' (seguent 15%), 'C' (resta).
  // ==========================================================================
  TAnalisisABCErp = record
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoFamilia: string;
    UnidadesConsumidas: Double;
    ImporteConsumido: Double;
    PorcentajeIndividual: Double; // % d'aquest article sobre el total
    PorcentajeAcumulado: Double;  // % acumulat fins aquest article (ordenat)
    Categoria: string;            // 'A' / 'B' / 'C'
    UnidadMedida: string;
  end;

  // ==========================================================================
  // Rupturas futuras (versi'on agregada r'apida): saldo proyectado al final
  // del horizonte = Saldo + PendienteRecibir + ProduccionPendiente
  //                       - PendienteServir - ConsumoPendiente.
  // Si SaldoFinal < StockMinimo -> aparece a la llista.
  // ==========================================================================
  TRupturaFuturaErp = record
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    CodigoFamilia: string;
    UnidadSaldo: Double;          // saldo actual
    PendienteRecibir: Double;     // compres pendents fins horitzo
    ProduccionPendiente: Double;  // OFs pendents (suma)
    PendienteServir: Double;      // vendes pendents fins horitzo
    ConsumoPendiente: Double;     // consums d'OFs pendents
    SaldoFinal: Double;           // calculat
    StockMinimo: Double;
    Deficit: Double;              // StockMinimo - SaldoFinal (positiu = problema)
    UnidadMedida: string;
  end;

  // ==========================================================================
  // Item neutro para sincronizacion ERP -> FS_PL_Raw_Item (Backlog).
  //
  // Unifica las 3 familias (OF/PED/PRJ) x 3 niveles (1=cabecera, 2=sub, 3=op)
  // en un solo record. El connector ERP construye un array jerarquico de
  // estos registros (padres antes que hijos) y uErpSyncRepo los persiste en
  // FS_PL_Raw_Item.
  //
  // ClaveERP debe ser unica dentro de (CodigoEmpresa, TipoOrigen). Convencion:
  //   OF nivel 1: 'OF|<Ej>|<Serie>|<Num>'
  //   OF nivel 2: 'OT|<Ej>|<NumeroTrabajo>'
  //   OF nivel 3: 'OP|<Ej>|<NumeroTrabajo>|<Orden>'
  //   PED nivel 1: 'PED|<Ej>|<Serie>|<Num>'
  //   PED nivel 2: 'LN|<Ej>|<Serie>|<Num>|<Orden>'
  //   PED nivel 3: 'OP|<Ej>|<Serie>|<Num>|<Orden>'
  //   PRJ nivel 1: 'PRJ|<CodigoProyecto>'
  //   PRJ nivel 2: 'TR|<CodigoProyecto>|<IdTarea>'
  //   PRJ nivel 3: 'OP|<CodigoProyecto>|<IdTarea>'
  // ==========================================================================
  TRawItemErp = record
    TipoOrigen: string;          // 'OF ', 'PED', 'PRJ' (char(3) en BD)
    Nivel: Byte;                 // 1, 2 o 3
    ClaveERP: string;
    ClaveERPPadre: string;       // vacio en Nivel=1

    NumeroDoc: Integer;          // NumeroOF / NumeroPedido / -
    SerieDoc: string;
    LineaDoc: Integer;           // LineaPedido / NumeroTrabajo / Orden tarea
    CodigoProyecto: string;

    Codigo: string;              // codigo interno (OT/Tarea/OP)
    Nombre: string;
    Descripcion: string;

    CodigoArticulo: string;
    DescripcionArticulo: string;
    Cantidad: Double;
    UnidadMedida: string;

    CodigoCliente: string;
    NombreCliente: string;

    FechaCompromiso: TDateTime;
    FechaNecesaria: TDateTime;
    FechaInicioPrev: TDateTime;
    FechaFinPrev: TDateTime;
    FechaLanzamiento: TDateTime;
    FechaPedido: TDateTime;
    Prioridad: Integer;
    Orden: Integer;
    CentroPreferente: string;    // auto-asignado desde Sage (CentroTrabajo de la OP)
    HorasEstimadas: Double;      // Nivel 3 = horas planificables
    EstadoERP: string;
    Observaciones: string;

    // Bloque de campos de la operacion (Nivel 3 / OP) de alto valor para el
    // backlog. Solo se rellenan en items OP; vacios/0 en OF y OT.
    OpTiempoPreparacion: Double;
    OpTiempoFabricacion: Double;
    OpUnidadesHora: Double;
    OpCosteHoraMaquina: Double;
    OpCosteHoraManoObra: Double;
    OpUnidadesFabricadas: Double;
    OpFechaInicioReal: TDateTime;
    OpFechaFinalReal: TDateTime;
    OpOperacionExterna: Boolean;
    OpCodigoProveedor: string;
    OpSeccionFabrica: string;
    OpStatusPlanificado: Boolean;
    OpObservaciones: string;
    OpPctParaSigOperacion: Double;
    OpPctDedicacionOperario: Double;

    // Campos custom poblados desde el ERP via mapeo (FS_PL_Cfg_ErpFieldMap).
    // Vacio si no hay mapeo activo para el nivel de este item.
    ExtraFields: TArray<TErpExtraValue>;
  end;

implementation

end.
