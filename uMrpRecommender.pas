unit uMrpRecommender;

// ============================================================================
// Motor de recomendacion MRP simple (Fase F1 del PLAN STOCK).
//
// A partir de:
//   - la proyeccion de stock (TStockProjector, que ya detecta la ruptura y su fecha)
//   - los parametros del articulo en Sage (TArticuloErp: lead time, lote, etc.)
//   - el override propio (TMrpParamOverride de FS_PL_MrpParam)
// resuelve los parametros efectivos (TMrpParam, fusion override->Sage->default) y
// genera una TMrpRecommendation: "Comprar/Fabricar X unidades, lanzar antes de
// [fecha ruptura - lead time]".
//
// Reglas de fusion (jerarquia), por parametro:
//   override (si informado) -> Sage -> default.
// Politica compra/fabricacion (hibrido BOM + override):
//   override.TipoReposicion si esta informado; si no, TieneFormula -> fabricacion,
//   en otro caso compra.
//
// La cantidad propuesta cubre la ruptura y deja el stock de seguridad, redondeada
// a lote minimo y multiplo.
//
// NO consulta BD ni ERP: recibe los datos ya leidos. Asi es testeable y no se
// acopla al conector.
//
// TODO (fase BOM): leer lead time / merma de fabricacion reales de dbo.Formulas
// (TiempoFabricacion, %IncrementoRechazo) en vez del override/​default manual.
// ============================================================================

interface

uses
  System.SysUtils, System.Math, System.DateUtils,
  uErpTypes, uMrpTypes, uStockProjection;

const
  MRP_LEADTIME_COMPRA_DEFAULT = 7;   // dias, si Sage no da TiempoMedioReposicion
  MRP_LEADTIME_FABRIC_DEFAULT = 3;   // dias, si no hay override ni dato

type
  TMrpRecommender = class
  public
    // Resuelve los parametros efectivos para un (articulo, almacen) fusionando
    // override propio sobre los datos de Sage.
    class function ResolveParam(const AArticulo: TArticuloErp;
      const AHasOverride: Boolean; const AOverride: TMrpParamOverride;
      const ACodigoAlmacen: string): TMrpParam;

    // Genera la recomendacion a partir de la proyeccion ya calculada y los
    // parametros resueltos. AHoy = fecha de calculo (normalmente Date).
    // Si no hay ruptura en el horizonte, Accion = maNinguna.
    class function Recommend(const AParam: TMrpParam;
      const ADescripcion: string; AProjector: TStockProjector;
      AHoy: TDateTime): TMrpRecommendation;
  end;

implementation

class function TMrpRecommender.ResolveParam(const AArticulo: TArticuloErp;
  const AHasOverride: Boolean; const AOverride: TMrpParamOverride;
  const ACodigoAlmacen: string): TMrpParam;
var
  P: TMrpParam;
begin
  P := Default(TMrpParam);
  P.CodigoArticulo := AArticulo.Codigo;
  P.CodigoAlmacen := ACodigoAlmacen;
  P.IncluirEnMrp := True;

  // --- Politica de reposicion (hibrido BOM + override) ---
  if AHasOverride and AOverride.HasTipoReposicion then
    P.TipoReposicion := AOverride.TipoReposicion
  else if AArticulo.TieneFormula then
    P.TipoReposicion := trFabricacion
  else
    P.TipoReposicion := trCompra;

  // --- Stock minimo / maximo / punto pedido (Sage; override puntual) ---
  P.StockMinimo := AArticulo.StockMinimo;
  P.StockMaximo := AArticulo.StockMaximo;

  if AHasOverride and not IsNan(AOverride.PuntoPedidoOvr) then
    P.PuntoPedido := AOverride.PuntoPedidoOvr
  else
    P.PuntoPedido := AArticulo.PuntoPedido;

  // --- Stock de seguridad ---
  // override -> %seguridad de Sage sobre stock minimo -> stock minimo.
  if AHasOverride and not IsNan(AOverride.StockSeguridadOvr) then
    P.StockSeguridad := AOverride.StockSeguridadOvr
  else if AArticulo.UsarStockSeguridad and (AArticulo.PctStockSeguridad > 0) then
    P.StockSeguridad := AArticulo.StockMinimo * (1 + AArticulo.PctStockSeguridad / 100)
  else
    P.StockSeguridad := AArticulo.StockMinimo;

  // --- Lote minimo y multiplo segun tipo ---
  if P.TipoReposicion = trFabricacion then
    P.LoteMinimo := AArticulo.LoteFabricacion
  else
    P.LoteMinimo := AArticulo.LotePedido;
  if AHasOverride and not IsNan(AOverride.LoteMinimoOvr) then
    P.LoteMinimo := AOverride.LoteMinimoOvr;

  if AHasOverride and not IsNan(AOverride.MultiploCompra) then
    P.Multiplo := AOverride.MultiploCompra
  else
    P.Multiplo := 0;  // sin multiplo

  // --- Lead time segun tipo ---
  if P.TipoReposicion = trFabricacion then
  begin
    if AHasOverride and (AOverride.LeadTimeFabricacion >= 0) then
      P.LeadTimeDias := AOverride.LeadTimeFabricacion
    else
      P.LeadTimeDias := MRP_LEADTIME_FABRIC_DEFAULT;  // TODO: de Formulas.TiempoFabricacion
  end
  else
  begin
    if AHasOverride and (AOverride.LeadTimeCompraOvr >= 0) then
      P.LeadTimeDias := AOverride.LeadTimeCompraOvr
    else if AArticulo.TiempoMedioReposicion > 0 then
      P.LeadTimeDias := Round(AArticulo.TiempoMedioReposicion)
    else
      P.LeadTimeDias := MRP_LEADTIME_COMPRA_DEFAULT;
  end;

  // --- Dias cobertura objetivo / horizonte / proveedor ---
  if AHasOverride and (AOverride.DiasCoberturaObjetivo >= 0) then
    P.DiasCoberturaObjetivo := AOverride.DiasCoberturaObjetivo
  else
    P.DiasCoberturaObjetivo := 0;

  if AHasOverride and (AOverride.HorizonteDias >= 0) then
    P.HorizonteDias := AOverride.HorizonteDias
  else
    P.HorizonteDias := 0;  // 0 = usar el global del modulo

  if AHasOverride and (Trim(AOverride.ProveedorPreferenteOvr) <> '') then
    P.ProveedorPreferente := AOverride.ProveedorPreferenteOvr
  else
    P.ProveedorPreferente := AArticulo.CodigoProveedor;

  if AHasOverride then
    P.IncluirEnMrp := AOverride.IncluirEnMrp;

  Result := P;
end;

class function TMrpRecommender.Recommend(const AParam: TMrpParam;
  const ADescripcion: string; AProjector: TStockProjector;
  AHoy: TDateTime): TMrpRecommendation;
var
  R: TMrpRecommendation;
  Movs: TArray<TMovStock>;
  i: Integer;
  FechaRuptura: TDateTime;
  SaldoRuptura: Double;
  Necesario: Double;
  Cantidad: Double;
begin
  R := Default(TMrpRecommendation);
  R.CodigoArticulo := AParam.CodigoArticulo;
  R.DescripcionArticulo := ADescripcion;
  R.CodigoAlmacen := AParam.CodigoAlmacen;
  R.Accion := maNinguna;
  R.LeadTimeDias := AParam.LeadTimeDias;
  R.ProveedorPreferente := AParam.ProveedorPreferente;

  if not AParam.IncluirEnMrp then Exit;  // articulo excluido del MRP

  // Buscar la PRIMERA fecha de ruptura: saldo proyectado por debajo del stock de
  // seguridad (si no hay seguridad, por debajo de 0).
  Movs := AProjector.MovimientosOrdenados;
  FechaRuptura := 0;
  SaldoRuptura := 0;
  for i := 0 to High(Movs) do
  begin
    if Movs[i].SaldoAcumulado < AParam.StockSeguridad then
    begin
      FechaRuptura := Movs[i].Fecha;
      SaldoRuptura := Movs[i].SaldoAcumulado;
      Break;
    end;
  end;

  if FechaRuptura = 0 then Exit;  // sin problema en el horizonte -> maNinguna

  R.FechaNecesaria := FechaRuptura;
  R.SaldoEnRuptura := SaldoRuptura;
  R.FechaLanzamiento := IncDay(FechaRuptura, -AParam.LeadTimeDias);
  R.EsUrgente := R.FechaLanzamiento <= AHoy;

  // Cantidad necesaria: subir el saldo desde el de ruptura hasta el objetivo.
  // Objetivo = stock de seguridad (o stock maximo si esta definido y es mayor).
  Necesario := AParam.StockSeguridad - SaldoRuptura;
  if (AParam.StockMaximo > 0) and (AParam.StockMaximo > AParam.StockSeguridad) then
    Necesario := AParam.StockMaximo - SaldoRuptura;
  if Necesario < 0 then Necesario := 0;

  // Redondeo a lote minimo y multiplo.
  Cantidad := Necesario;
  if AParam.LoteMinimo > 0 then
    Cantidad := Max(Cantidad, AParam.LoteMinimo);
  if AParam.Multiplo > 0 then
    Cantidad := Ceil(Cantidad / AParam.Multiplo) * AParam.Multiplo;
  R.Cantidad := Cantidad;

  // Accion segun politica.
  case AParam.TipoReposicion of
    trFabricacion:     R.Accion := maFabricar;
    trSubcontratacion: R.Accion := maSubcontratar;
  else
    R.Accion := maComprar;
  end;

  // Motivo legible.
  R.Motivo := Format(
    '%s %s ud. antes del %s (rotura el %s, saldo %s; lead time %d d'#237'as)',
    [AccionToStr(R.Accion), FormatFloat('#,##0.##', R.Cantidad),
     FormatDateTime('dd/mm/yyyy', R.FechaLanzamiento),
     FormatDateTime('dd/mm/yyyy', R.FechaNecesaria),
     FormatFloat('#,##0.##', SaldoRuptura), AParam.LeadTimeDias]);

  if R.EsUrgente then
    R.Motivo := '[URGENTE] ' + R.Motivo;

  Result := R;
end;

end.
