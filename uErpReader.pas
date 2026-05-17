unit uErpReader;

// ============================================================================
// Contracte neutre de lectura d'un ERP (Sage 200, SAP, Dynamics...).
//
// Les pantalles de detall (Pedido, Formula, etc.) NOMES depenen d'aquesta
// interfície. Cada implementacio concreta tradueix del dialecte propi de
// l'ERP als tipus neutres definits a uErpTypes.pas.
//
// Per obtenir el reader actiu segons la configuracio:
//   uses uErpReaderFactory;
//   var Reader := GetActiveErpReader;
//   if Reader = nil then ...   // ERP no configurat
// ============================================================================

interface

uses
  System.SysUtils, System.Classes,
  uErpTypes;

type
  IErpReader = interface
    ['{D8C2C1A0-7B6E-4F3C-9A21-1F0E3A55E901}']

    // Nom human-readable del sistema ('Sage 200', 'SAP B1', ...) per a logs/UI
    function GetSistemaNombre: string;

    // Asegura connexio amb l'ERP. Llanca Exception si no es pot connectar.
    procedure EnsureConnected;

    // -- PEDIDOS DE CLIENTE ------------------------------------------------
    // Retorna la cabecera del pedido. Si no existeix, Result.Encontrado = False.
    function ReadPedidoCabecera(const ASerie: string; ANumero: Integer;
      AEjercicio: SmallInt): TPedidoCabecera;

    // Retorna les linies del pedido en ordre. Array buit si no n'hi ha.
    function ReadPedidoLineas(const ASerie: string; ANumero: Integer;
      AEjercicio: SmallInt): TArray<TPedidoLinea>;

    // Llista de pedidos per a un exercici. Si ASerie/ANumero son buits/0,
    // no filtra per aquest camp. Usat per a UI d'exploracio (Explorer).
    function ReadPedidosCabecera(AEjercicio: SmallInt; const ASerie: string;
      ANumero: Integer): TArray<TPedidoCabecera>;
    function ReadPedidosLineas(AEjercicio: SmallInt; const ASerie: string;
      ANumero: Integer): TArray<TPedidoLinea>;

    // -- FORMULA / ESCANDALL -----------------------------------------------
    // Retorna totes les versions de formula disponibles per l'article,
    // ordenades de menor a major. Array buit si no en te cap.
    function ReadFormulaVersiones(const ACodigoArticulo: string): TArray<SmallInt>;

    // Retorna la primera versio de formula disponible per l'article.
    // Si no n'hi ha cap, Result.Encontrada = False (Version = 0).
    function ReadFormulaCabecera(const ACodigoArticulo: string): TFormulaCabecera;

    // Components (Mat_Formula en Sage) per a la versio indicada.
    function ReadFormulaComponentes(const ACodigoArticulo: string;
      AVersion: SmallInt): TArray<TFormulaComponente>;

    // Operacions/fases (Oper_Formula en Sage) per a la versio indicada.
    function ReadFormulaOperaciones(const ACodigoArticulo: string;
      AVersion: SmallInt): TArray<TFormulaOperacion>;

    // -- DONDE SE USA (where-used / pegging invers) -----------------------
    // Retorna totes les formules d'altres articles on el codi indicat
    // apareix com a component. Una fila per (articlePare, versio, ordre).
    function ReadDondeSeUsa(const ACodigoArticulo: string): TArray<TDondeSeUsaErp>;

    // -- HISTORICO MENSUAL DE UN ARTICULO ---------------------------------
    // Series mensuales (Ejercicio + Periodo 1..12) de unidades/coste de
    // entrada y salida. AMesesAtras define quantos mesos enrere comptem
    // (12, 24...). Si AAlmacenes buit = tots.
    function ReadHistoricoMensual(const ACodigoArticulo: string;
      const AAlmacenes: TArray<string>;
      AMesesAtras: Integer): TArray<THistoricoMesErp>;

    // -- EMPRESAS DEL ERP -------------------------------------------------
    // Llistat d'empreses configurades a l'ERP. Util per a UI de seleccio.
    // Ignora la CodigoEmpresa del FCfg: aquesta crida es independent del
    // filtre d'empresa activa.
    function ReadEmpresas: TArray<TEmpresaErp>;

    // -- ARTICULOS --------------------------------------------------------
    // Llistat d'articles del catalog ERP per a l'empresa configurada. Si
    // AFiltroCodigo no es buit, filtra per substring del codi (LIKE %...%).
    function ReadArticulos(const AFiltroCodigo: string): TArray<TArticuloErp>;

    // -- CENTROS DE TRABAJO -----------------------------------------------
    // Llista completa de centres de treball definits a l'ERP per a l'empresa
    // configurada. Array buit si no n'hi ha cap. L'ordre es el natural del ERP
    // (per codi).
    function ReadCentrosTrabajo: TArray<TCentroTrabajoErp>;

    // -- MAQUINAS ---------------------------------------------------------
    function ReadMaquinas: TArray<TMaquinaErp>;

    // -- OPERARIOS --------------------------------------------------------
    function ReadOperarios: TArray<TOperarioErp>;

    // -- CENTROS X MAQUINAS ----------------------------------------------
    // Assignacio N:M centre-maquina. Si ACentroTrabajo no es buit, filtra
    // pel codi del centre.
    function ReadCentrosMaquinas(const ACentroTrabajo: string): TArray<TCentroMaquinaErp>;

    // -- CATALOGOS AUX ----------------------------------------------------
    function ReadFamilias: TArray<TFamiliaErp>;
    function ReadClientes(const AFiltroCodigo: string): TArray<TClienteErp>;
    function ReadAlmacenes: TArray<TAlmacenErp>;

    // -- ORDENES DE FABRICACION -------------------------------------------
    // Llista d'OFs de l'exercici. ASerie/ANumero opcionals (buits/0 = tots).
    function ReadOrdenesFabricacion(AEjercicio: SmallInt; const ASerie: string;
      ANumero: Integer): TArray<TOrdenFabricacionErp>;

    // OTs filtrades per exercici + numero opcional.
    function ReadOrdenesTrabajo(AEjercicioTrabajo: SmallInt;
      ANumeroTrabajo: Integer): TArray<TOrdenTrabajoErp>;
    // Operacions d'una OT (ANumeroTrabajo>0 obligatori).
    function ReadOperacionesOT(AEjercicioTrabajo: SmallInt;
      ANumeroTrabajo: Integer): TArray<TOperacionOTErp>;
    // Consums d'una OT (ANumeroTrabajo>0 obligatori).
    function ReadConsumosOT(AEjercicioTrabajo: SmallInt;
      ANumeroTrabajo: Integer): TArray<TConsumoOTErp>;
    // Enllac OT<->OF. Si AEjercicioFabricacion=0 retorna tot el filtre d'OTs;
    // si es informa, filtra per OF concreta.
    function ReadRelacionOTOF(AEjercicioFabricacion: SmallInt;
      const ASerieFabricacion: string; ANumeroFabricacion: Integer): TArray<TRelacionOTOFErp>;

    // -- PROYECTOS / TAREAS -----------------------------------------------
    function ReadProyectos(const AFiltroCodigo: string): TArray<TProyectoErp>;
    // Tareas d'un projecte (ACodigoProyecto obligatori).
    function ReadTareasProyecto(const ACodigoProyecto: string): TArray<TTareaProyectoErp>;

    // -- CALENDARIOS / HORARIOS -------------------------------------------
    function ReadGruposHorarios: TArray<TGrupoHorarioErp>;
    function ReadModelosHorarios: TArray<TModeloHorarioErp>;
    // Linees del model indicat. Si AModeloHorario<=0 retorna totes les linees
    // de tots els models (util per inspeccio rapida).
    function ReadLineasModeloHorario(AModeloHorario: Integer): TArray<TLineaModeloHorarioErp>;
    // Calendari diari d'un centre entre dues dates inclosivament. Si
    // ACentroTrabajo es buit, retorna totes les files dels centres dins el
    // rang.
    function ReadCalendarioCentro(const ACentroTrabajo: string;
      AFechaDesde, AFechaHasta: TDateTime): TArray<TCalendarioCentroErp>;

    // -- STOCK ------------------------------------------------------------
    // Detall per partida/lot (AcumuladoStock). Si AEjercicio/APeriodo <= 0,
    // agafa l'ultim periode amb moviments. Filtre per article/almacen
    // opcional (buit = tots).
    function ReadStockArticulo(const ACodigoArticulo, ACodigoAlmacen,
      APartida: string; AEjercicio: SmallInt;
      APeriodo: SmallInt): TArray<TStockArticuloErp>;

    // Resum MRP per article+almacen (AcumuladoStock_Neco). Filtres opcionals.
    // Disponible = UnidadSaldo - StockReservado (calculat al reader).
    function ReadStockDisponible(const ACodigoArticulo,
      ACodigoAlmacen: string): TArray<TStockDisponibleErp>;

    // -- ENTRADAS FUTURAS (pedidos compra pendents) -----------------------
    // Linees de pedido de compra amb UnidadesPendientes>0 dins el rang de
    // FechaNecesaria. Filtre per article opcional. Si AFechaDesde=0, sense
    // limit inferior; si AFechaHasta=0, sense limit superior.
    function ReadEntradasFuturas(const ACodigoArticulo: string;
      AFechaDesde, AFechaHasta: TDateTime): TArray<TEntradaFuturaErp>;

    // Variant filtrada per almacenes (buit = tots).
    function ReadEntradasFuturasFiltered(const ACodigoArticulo: string;
      const AAlmacenes: TArray<string>;
      AFechaDesde, AFechaHasta: TDateTime): TArray<TEntradaFuturaErp>;

    // -- SALIDAS FUTURAS (pedidos venta pendents) -------------------------
    function ReadSalidasFuturasVenta(const ACodigoArticulo: string;
      const AAlmacenes: TArray<string>;
      AFechaDesde, AFechaHasta: TDateTime): TArray<TSalidaFuturaVentaErp>;

    // -- MOVIMENTS GENERATS PER OFs PENDENTS ------------------------------
    // Retorna producci'o (+) per a l'article indicat i consums (-) de l'article
    // si forma part d'alguna matriu d'OFs pendents (estat no finalitzat).
    // Si AAlmacenes buit = tots.
    function ReadMovimientosOFsPendientes(const ACodigoArticulo: string;
      const AAlmacenes: TArray<string>;
      AFechaHasta: TDateTime): TArray<TMovOFErp>;

    // -- STOCK CRITIC (Cockpit) -------------------------------------------
    // Llista articles amb Disponible < StockMinimo (StockMinimo > 0).
    // Filtre per almacen i familia opcionals.
    function ReadStockCritico(const AAlmacenes: TArray<string>;
      const AFiltroFamilia: string): TArray<TStockCriticoErp>;

    // -- STOCK OBSOLETO ---------------------------------------------------
    // Articles amb Saldo > 0 i sense moviment (entrada o salida) fa >=
    // AMesesSinMovimiento mesos.
    function ReadStockObsoleto(const AAlmacenes: TArray<string>;
      const AFiltroFamilia: string;
      AMesesSinMovimiento: Integer): TArray<TStockObsoletoErp>;

    // -- COBERTURA (Days of Supply) ---------------------------------------
    // Per cada article+almacen amb stock: dies que duraran les existencies
    // segons el consum dels ultims ADiasHistorico dies.
    function ReadCobertura(const AAlmacenes: TArray<string>;
      const AFiltroFamilia: string;
      ADiasHistorico: Integer): TArray<TCoberturaErp>;

    // -- ANALISIS ABC -----------------------------------------------------
    // Classifica articles per import de consum dels ultims ADiasHistorico
    // dies. Pol'itica: A=80% valor, B=15% segu'ent, C=la resta.
    function ReadAnalisisABC(const AFiltroFamilia: string;
      ADiasHistorico: Integer): TArray<TAnalisisABCErp>;

    // -- RUPTURAS FUTURAS (agregat rapid) ---------------------------------
    // Saldo proyectado = Saldo + ΣEntradas - ΣSalidas dins l'horitzo
    // ADiasHorizonte. Llista articles on SaldoFinal < StockMinimo.
    function ReadRupturasFuturas(const AAlmacenes: TArray<string>;
      const AFiltroFamilia: string;
      ADiasHorizonte: Integer): TArray<TRupturaFuturaErp>;

    // -- OFs ACTIVAS DE UN ARTICULO ---------------------------------------
    // OFs en curs o pendents (no finalitzades) que produeixen aquest article.
    function ReadOFsActivasArticulo(const ACodigoArticulo: string): TArray<TOFActivaArticuloErp>;

    // -- PROVEEDORES DE UN ARTICULO ---------------------------------------
    // Agregat per proveidor dels pedidos compra historics d'aquest article.
    // AMesesAtras limita l'historial (0 = tot).
    function ReadProveedoresArticulo(const ACodigoArticulo: string;
      AMesesAtras: Integer): TArray<TProveedorArticuloErp>;

    // -- CLIENTES DE UN ARTICULO ------------------------------------------
    // Agregat per client dels pedidos venda historics d'aquest article.
    function ReadClientesArticulo(const ACodigoArticulo: string;
      AMesesAtras: Integer): TArray<TClienteArticuloErp>;

    // -- KPIS INDIVIDUALS PER A LA FITXA D'ARTICLE ------------------------
    // Cobertura: Saldo / consum diari (consum=ultim Ejercicio). DiasCobertura
    // = -1 si no hi ha consum.
    function ReadCoberturaArticulo(const ACodigoArticulo: string;
      const AAlmacenes: TArray<string>): TCoberturaErp;

    // Categoria ABC d'un article concret (A/B/C o '' si no te consum).
    function ReadCategoriaABCArticulo(const ACodigoArticulo: string): string;

    // -- DASHBOARD OPERATIU -----------------------------------------------
    // Top N OFs no finalitzades. AOrdenarPorFechaFin=True ordena per
    // FechaFinalPrevista ASC (imminents primer); False ordena per
    // FechaInicioPrevista DESC (mes recents primer).
    function ReadOFsActivasTop(AOrdenarPorFechaFin: Boolean;
      ALimit: Integer): TArray<TOFGlobalErp>;

    // Articles ABC=A amb Disponible <= 0. Risc maxim de ruptura per articles
    // que pesen mes a la facturacio.
    function ReadArticulosAsinStock(ALimit: Integer): TArray<TArticuloACriticoErp>;
  end;

implementation

end.
