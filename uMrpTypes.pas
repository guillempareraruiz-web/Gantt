unit uMrpTypes;

// ============================================================================
// Tipos del modulo MRP (PLAN STOCK).
//
//   TMrpParamOverride : una fila de FS_PL_MrpParam (lo que el usuario sobreescribe).
//   TMrpParam         : parametros MRP ya RESUELTOS para un (articulo, almacen),
//                       fusionando override -> Sage(ArticulosAlmacen/Articulos) ->
//                       default. Es lo que consume el motor de recomendacion.
//   TMrpRecommendation: una propuesta accionable (comprar/fabricar X antes de fecha).
//
// Sin dependencias de BD ni UI: tipos puros reutilizables por repo, motor y forms.
// ============================================================================

interface

uses
  System.SysUtils;

type
  // Politica de reposicion resuelta.
  TTipoReposicion = (trCompra, trFabricacion, trSubcontratacion);

  // Una fila de FS_PL_MrpParam. Los campos "Ovr" y los opcionales usan NaN/-1/''
  // como "no informado" (hereda de Sage). Bool IncluirEnMrp por defecto True.
  TMrpParamOverride = record
    CodigoArticulo: string;
    CodigoAlmacen: string;          // '' = override global del articulo
    // Politica: usar HasTipoReposicion para saber si esta informada.
    HasTipoReposicion: Boolean;
    TipoReposicion: TTipoReposicion;
    // Extras (NaN = no informado).
    MultiploCompra: Double;
    DiasCoberturaObjetivo: Integer; // -1 = no informado
    LeadTimeFabricacion: Integer;   // -1 = no informado
    // Overrides de parametros que tambien estan en Sage (NaN/-1 = no informado).
    StockSeguridadOvr: Double;
    LeadTimeCompraOvr: Integer;     // -1
    LoteMinimoOvr: Double;
    PuntoPedidoOvr: Double;
    ProveedorPreferenteOvr: string;
    HorizonteDias: Integer;         // -1 = no informado
    IncluirEnMrp: Boolean;
    Observaciones: string;
  end;

  // Parametros MRP ya resueltos para un (articulo, almacen) concreto.
  TMrpParam = record
    CodigoArticulo: string;
    CodigoAlmacen: string;
    TipoReposicion: TTipoReposicion;
    StockMinimo: Double;
    StockMaximo: Double;
    StockSeguridad: Double;         // calculado: max(StockMinimo, %seg sobre demanda) o override
    PuntoPedido: Double;
    LoteMinimo: Double;             // lote de compra o fabricacion segun tipo
    Multiplo: Double;               // 0 = sin multiplo
    LeadTimeDias: Integer;          // compra o fabricacion segun tipo
    DiasCoberturaObjetivo: Integer; // 0 = no aplica
    HorizonteDias: Integer;
    ProveedorPreferente: string;
    IncluirEnMrp: Boolean;
    // Origen del lead time/merma de fabricacion (para trazabilidad en UI).
    MermaFabricacionPct: Double;    // de Formulas.%IncrementoRechazo si fabrica
  end;

  // Tipo de accion recomendada.
  TMrpAccion = (
    maNinguna,        // sin problema en el horizonte
    maComprar,
    maFabricar,
    maSubcontratar,
    maAvanzarEntrada, // ya hay una entrada pero llega tarde
    maRevisar         // problema sin parametros suficientes para proponer cantidad
  );

  // Una recomendacion accionable para un (articulo, almacen).
  TMrpRecommendation = record
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    Accion: TMrpAccion;
    Cantidad: Double;               // unidades a comprar/fabricar (ya redondeada a lote/multiplo)
    FechaNecesaria: TDateTime;      // cuando se necesita el material (fecha de ruptura)
    FechaLanzamiento: TDateTime;    // fecha limite para lanzar = FechaNecesaria - LeadTime
    LeadTimeDias: Integer;
    ProveedorPreferente: string;
    SaldoEnRuptura: Double;         // saldo proyectado en el momento de la ruptura (negativo)
    Motivo: string;                 // texto explicativo para el planificador
    EsUrgente: Boolean;             // FechaLanzamiento <= hoy (hay que lanzar ya o tarde)
  end;

function TipoReposicionToStr(T: TTipoReposicion): string;
function AccionToStr(A: TMrpAccion): string;

implementation

function TipoReposicionToStr(T: TTipoReposicion): string;
begin
  case T of
    trCompra:          Result := 'Compra';
    trFabricacion:     Result := 'Fabricaci'#243'n';
    trSubcontratacion: Result := 'Subcontrataci'#243'n';
  else
    Result := '';
  end;
end;

function AccionToStr(A: TMrpAccion): string;
begin
  case A of
    maNinguna:        Result := 'Sin acci'#243'n';
    maComprar:        Result := 'Comprar';
    maFabricar:       Result := 'Fabricar';
    maSubcontratar:   Result := 'Subcontratar';
    maAvanzarEntrada: Result := 'Avanzar entrada';
    maRevisar:        Result := 'Revisar';
  else
    Result := '';
  end;
end;

end.
