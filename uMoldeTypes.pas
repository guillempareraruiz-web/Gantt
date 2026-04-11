unit uMoldeTypes;

interface

uses
  System.SysUtils, System.DateUtils;

type
  TEstadoMolde = (
    emDisponible,
    emMontado,
    emReservado,
    emMantenimiento,
    emAveriado,
    emBloqueado,
    emBaja
  );

  TTipoMolde = (
    tmInyeccion,
    tmSoplado,
    tmCompresion,
    tmExtrusion,
    tmOtro
  );

  TMolde = record
    IdMolde: Integer;
    CodigoMolde: string;
    Descripcion: string;
    TipoMolde: TTipoMolde;
    Estado: TEstadoMolde;

    // Ubicacion
    UbicacionActual: string;
    CentroTrabajoActual: string;

    // Caracteristicas tecnicas
    NumeroCavidades: Integer;
    TiempoMontaje: Double;      // minutos
    TiempoDesmontaje: Double;   // minutos
    TiempoAjuste: Double;       // minutos

    // Mantenimiento
    CiclosAcumulados: Integer;
    FechaProximoMantenimiento: TDateTime;

    // Planificacion
    DisponiblePlanificacion: Boolean;
    Observaciones: string;

    // Relaciones
    CentrosTrabajoPermitidos: TArray<string>;   // codigos de centros donde puede montarse
    ArticulosAsociados: TArray<string>;          // codigos de articulos que fabrica
    OperacionesAsociadas: TArray<string>;        // codigos de operaciones compatibles
    UtillajesAsociados: TArray<string>;          // codigos de utillajes necesarios
  end;

  TMoldeArray = TArray<TMolde>;

  // Relacion Molde-Centro de Trabajo (detalle)
  TMoldeCentro = record
    IdMolde: Integer;
    CodigoCentro: string;
    Preferente: Boolean;         // si es el centro preferente para este molde
    TiempoMontajeEspecifico: Double;  // tiempo montaje especifico en este centro (0 = usar el general)
  end;

  // Relacion Molde-Operacion (detalle)
  TMoldeOperacion = record
    IdMolde: Integer;
    CodigoOperacion: string;
    CiclosPorUnidad: Double;     // ciclos necesarios por unidad fabricada
    Observaciones: string;
  end;

  // Relacion Molde-Articulo (detalle)
  TMoldeArticulo = record
    IdMolde: Integer;
    CodigoArticulo: string;
    CavidadesActivas: Integer;   // cavidades activas para este articulo (puede ser menor que NumeroCavidades)
    Observaciones: string;
  end;

  // Relacion Molde-Utillaje
  TMoldeUtillaje = record
    IdMolde: Integer;
    CodigoUtillaje: string;
    Obligatorio: Boolean;        // si el utillaje es obligatorio para usar el molde
    Observaciones: string;
  end;

// Helpers
function EstadoMoldeToStr(AEstado: TEstadoMolde): string;
function StrToEstadoMolde(const AStr: string): TEstadoMolde;
function TipoMoldeToStr(ATipo: TTipoMolde): string;

implementation

function EstadoMoldeToStr(AEstado: TEstadoMolde): string;
begin
  case AEstado of
    emDisponible:     Result := 'Disponible';
    emMontado:        Result := 'Montado';
    emReservado:      Result := 'Reservado';
    emMantenimiento:  Result := 'Mantenimiento';
    emAveriado:       Result := 'Averiado';
    emBloqueado:      Result := 'Bloqueado';
    emBaja:           Result := 'Baja';
  else
    Result := 'Desconocido';
  end;
end;

function StrToEstadoMolde(const AStr: string): TEstadoMolde;
var
  S: string;
begin
  S := LowerCase(Trim(AStr));
  if S = 'disponible' then Result := emDisponible
  else if S = 'montado' then Result := emMontado
  else if S = 'reservado' then Result := emReservado
  else if S = 'mantenimiento' then Result := emMantenimiento
  else if S = 'averiado' then Result := emAveriado
  else if S = 'bloqueado' then Result := emBloqueado
  else if S = 'baja' then Result := emBaja
  else Result := emDisponible;
end;

function TipoMoldeToStr(ATipo: TTipoMolde): string;
begin
  case ATipo of
    tmInyeccion:   Result := 'Inyeccion';
    tmSoplado:     Result := 'Soplado';
    tmCompresion:  Result := 'Compresion';
    tmExtrusion:   Result := 'Extrusion';
    tmOtro:        Result := 'Otro';
  else
    Result := 'Otro';
  end;
end;

end.
