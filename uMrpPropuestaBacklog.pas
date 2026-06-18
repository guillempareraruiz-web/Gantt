unit uMrpPropuestaBacklog;

// ============================================================================
// Puente Stock -> Gantt (via Backlog).
//
// Inserta una recomendacion MRP de FABRICACION como un item de carga pendiente
// en FS_PL_Raw_Item (familia OF), para que el planificador la coloque en el Gantt
// con el flujo Backlog->Gantt ya existente.
//
// Decision de diseno (ver docs/PlanStock_MRP_AnalisisGap.md): NO se crea
// FS_PL_Node directamente. Se crea una OF "manual" (OrigenERP='MRP') de Nivel 1.
// La vista FS_PL_vw_Backlog muestra el item leaf de cada rama; una OF de Nivel 1
// sin hijos ES leaf, asi que aparece directamente como pendiente y es
// planificable. La explosion a OT/OP se deja para una fase posterior.
//
// La ClaveERP se construye unica: 'MRP-' + articulo + '-' + timestamp pasado por
// el llamador (los scripts no pueden usar Now()/Date(); aqui es codigo Delphi
// normal y SI podemos, pero para ser deterministas y trazables usamos un
// contador/secuencia sobre el propio articulo si ya existe).
// ============================================================================

interface

uses
  System.SysUtils, System.Variants, Data.Win.ADODB,
  uMrpTypes;

type
  TMrpPropuestaBacklog = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    function ExisteClave(const AClave: string): Boolean;
    function GenerarClaveUnica(const ACodigoArticulo: string): string;
    // Inserta un item de un nivel (1/2/3) y devuelve su RawItemId (-1 si falla).
    function InsertarNivel(ANivel: Integer; AParentId: Int64;
      const AClave: string; const ARec: TMrpRecommendation;
      AHorasEstimadas: Double; const ACentroPreferente: string): Int64;
  public
    constructor Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt);

    // Inserta la recomendacion como OF de fabricacion pendiente en el Backlog.
    // Devuelve el RawItemId creado, o -1 si falla / la accion no es de fabricacion.
    // AHorasEstimadas: horas planificables de la OF (si 0, el Backlog quedara sin
    // duracion y el planificador la ajustara). ACentroPreferente: centro sugerido
    // (de Oper_Formula.CentroTrabajo) o '' si no se conoce.
    function InsertarPropuesta(const ARec: TMrpRecommendation;
      AHorasEstimadas: Double; const ACentroPreferente: string): Int64;
  end;

implementation

constructor TMrpPropuestaBacklog.Create(AConnection: TADOConnection;
  ACodigoEmpresa: SmallInt);
begin
  inherited Create;
  FConnection := AConnection;
  FCodigoEmpresa := ACodigoEmpresa;
end;

function TMrpPropuestaBacklog.ExisteClave(const AClave: string): Boolean;
var
  Q: TADOQuery;
begin
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT 1 FROM FS_PL_Raw_Item WHERE CodigoEmpresa = :CE ' +
      'AND TipoOrigen = ''OF '' AND ClaveERP = :Clave';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Clave').Value := AClave;
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

function TMrpPropuestaBacklog.GenerarClaveUnica(
  const ACodigoArticulo: string): string;
var
  Base: string;
  n: Integer;
begin
  // 'MRP-<articulo>' y, si ya existe, sufijo incremental -2, -3...
  Base := 'MRP-' + ACodigoArticulo;
  Result := Base;
  n := 1;
  while ExisteClave(Result) do
  begin
    Inc(n);
    Result := Base + '-' + IntToStr(n);
  end;
end;

function TMrpPropuestaBacklog.InsertarPropuesta(
  const ARec: TMrpRecommendation; AHorasEstimadas: Double;
  const ACentroPreferente: string): Int64;
var
  Clave: string;
  OtId: Int64;
begin
  Result := -1;
  if FConnection = nil then Exit;
  if not (ARec.Accion in [maFabricar, maSubcontratar]) then Exit;

  Clave := GenerarClaveUnica(ARec.CodigoArticulo);

  // El Backlog planifica items de Nivel 3 (OP); los nodos del Gantt SOLO se lincan
  // a Nivel 3 (ver V016). Por eso creamos la jerarquia completa OF(1) -> OT(2) ->
  // OP(3), con la OP llevando las horas planificables. OF y OT son contenedores.
  // OrigenERP='OF-MRP' marca el origen (propuesta MRP), distinto de 'SAGE200'.

  // Nivel 1: cabecera OF
  Result := InsertarNivel(1, 0, Clave, ARec, AHorasEstimadas, ACentroPreferente);
  if Result <= 0 then Exit;

  // Nivel 2: OT (contenedor)
  OtId := InsertarNivel(2, Result, Clave + '-OT1', ARec, AHorasEstimadas, ACentroPreferente);
  if OtId <= 0 then Exit;

  // Nivel 3: OP planificable (lleva las horas)
  InsertarNivel(3, OtId, Clave + '-OP1', ARec, AHorasEstimadas, ACentroPreferente);
end;

function TMrpPropuestaBacklog.InsertarNivel(ANivel: Integer;
  AParentId: Int64; const AClave: string; const ARec: TMrpRecommendation;
  AHorasEstimadas: Double; const ACentroPreferente: string): Int64;
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  Horas: Double;
begin
  Result := -1;
  // Solo el Nivel 3 (OP) lleva las horas planificables; niveles 1 y 2 son
  // contenedores puros (HorasEstimadas NULL).
  if ANivel = 3 then Horas := AHorasEstimadas else Horas := 0;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_Raw_Item ' +
      '  (CodigoEmpresa, TipoOrigen, Nivel, ParentRawItemId, OrigenERP, ClaveERP, ' +
      '   ClaveERPPadre, Codigo, Nombre, CodigoArticulo, DescripcionArticulo, ' +
      '   Cantidad, FechaNecesaria, FechaLanzamiento, CentroPreferente, ' +
      '   HorasEstimadas, EstadoERP, Observaciones, Activo) ' +
      'VALUES (:CE, ''OF '', :Nivel, :Parent, ''OF-MRP'', :Clave, ' +
      '   :ClavePadre, :Codigo, :Nombre, :Art, :DescArt, ' +
      '   :Cant, :FNec, :FLan, :Centro, ' +
      '   :Horas, ''PENDIENTE'', :Obs, 1)';
    Cmd.ParamCheck := True;
    Cmd.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Cmd.Parameters.ParamByName('Nivel').Value := ANivel;
    if AParentId > 0 then
      Cmd.Parameters.ParamByName('Parent').Value := AParentId
    else
      Cmd.Parameters.ParamByName('Parent').Value := Null;
    Cmd.Parameters.ParamByName('Clave').Value := AClave;
    if AParentId > 0 then
      Cmd.Parameters.ParamByName('ClavePadre').Value := AClave  // referencia simple
    else
      Cmd.Parameters.ParamByName('ClavePadre').Value := Null;
    // Codigo: etiqueta corta del nivel (OT/OP) para que la vista construya el doc.
    case ANivel of
      2: Cmd.Parameters.ParamByName('Codigo').Value := 'OT1';
      3: Cmd.Parameters.ParamByName('Codigo').Value := 'OP1';
    else
      Cmd.Parameters.ParamByName('Codigo').Value := Null;
    end;
    Cmd.Parameters.ParamByName('Nombre').Value :=
      'Propuesta MRP ' + ARec.CodigoArticulo;
    Cmd.Parameters.ParamByName('Art').Value := ARec.CodigoArticulo;
    Cmd.Parameters.ParamByName('DescArt').Value := ARec.DescripcionArticulo;
    Cmd.Parameters.ParamByName('Cant').Value := ARec.Cantidad;
    if ARec.FechaNecesaria > 0 then
      Cmd.Parameters.ParamByName('FNec').Value := ARec.FechaNecesaria
    else
      Cmd.Parameters.ParamByName('FNec').Value := Null;
    if ARec.FechaLanzamiento > 0 then
      Cmd.Parameters.ParamByName('FLan').Value := ARec.FechaLanzamiento
    else
      Cmd.Parameters.ParamByName('FLan').Value := Null;
    if Trim(ACentroPreferente) <> '' then
      Cmd.Parameters.ParamByName('Centro').Value := ACentroPreferente
    else
      Cmd.Parameters.ParamByName('Centro').Value := Null;
    if Horas > 0 then
      Cmd.Parameters.ParamByName('Horas').Value := Horas
    else
      Cmd.Parameters.ParamByName('Horas').Value := Null;
    Cmd.Parameters.ParamByName('Obs').Value := ARec.Motivo;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // Recuperar el RawItemId recien creado (clave unica por (CE, TipoOrigen, Clave)).
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT RawItemId FROM FS_PL_Raw_Item WHERE CodigoEmpresa = :CE ' +
      'AND TipoOrigen = ''OF '' AND ClaveERP = :Clave';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Clave').Value := AClave;
    Q.Open;
    if not Q.Eof then
      Result := Q.FieldByName('RawItemId').AsLargeInt;
  finally
    Q.Free;
  end;
end;

end.
