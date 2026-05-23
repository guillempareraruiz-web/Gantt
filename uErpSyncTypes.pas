unit uErpSyncTypes;

// ============================================================================
// Tipos compartidos del flujo "Sincronizar con ERP".
//
// Independiente del ERP concreto: el form trabaja sobre TSyncRowCentro /
// TSyncRowMaquina, que envuelven el record neutro de uErpTypes mas el estado
// detectado contra la BD local.
// ============================================================================

interface

uses
  System.SysUtils, System.Classes,
  uErpTypes;

type
  TSyncStatus = (
    ssNuevo,          // No existe en local (por ErpCodigo)
    ssSinCambios,     // ERP no ha cambiado desde el ultimo sync
    ssActualizado,    // ERP ha cambiado; local no estaba tocado
    ssConflicto,      // ERP ha cambiado y local tambien
    ssEliminadoErp,   // Existia en local con Source='ERP'; ERP ya no lo devuelve
    ssError           // Mapeo fallo
  );

  TConflictAction = (
    caAplicarErp,     // Sobrescribir local con valores ERP
    caMantenerLocal,  // Conservar valores locales, solo refrescar hash
    caIgnorar         // No aplicar nada esta vez
  );

  TSyncRowCentro = record
    ErpData: TCentroTrabajoErp;
    LocalCenterId: Integer;       // 0 si no existe en local
    LocalCodigoCentro: string;
    LocalTitulo: string;
    LocalSource: string;          // '', 'MANUAL', 'ERP', 'MIXED'
    LocalLastErpHash: string;
    Status: TSyncStatus;
    Aplicar: Boolean;             // True por defecto excepto en SinCambios/Conflicto
    ConflictAction: TConflictAction;
    ErrorMsg: string;
    NewHash: string;              // Hash calculado sobre ErpData
  end;

  TSyncRowMaquina = record
    ErpData: TMaquinaErp;
    LocalMaquinaId: Integer;
    LocalCodigo: string;
    LocalDescripcion: string;
    LocalSource: string;
    LocalLastErpHash: string;
    Status: TSyncStatus;
    Aplicar: Boolean;
    ConflictAction: TConflictAction;
    ErrorMsg: string;
    NewHash: string;
  end;

  TSyncRowOperario = record
    ErpData: TOperarioErp;
    LocalOperatorId: Integer;
    LocalNombre: string;
    LocalSource: string;
    LocalLastErpHash: string;
    Status: TSyncStatus;
    Aplicar: Boolean;
    ConflictAction: TConflictAction;
    ErrorMsg: string;
    NewHash: string;
  end;

  TSyncRowCentroMaquina = record
    ErpData: TCentroMaquinaErp;
    LocalCenterId: Integer;       // resuelto desde ErpData.CentroTrabajo
    LocalMaquinaId: Integer;      // resuelto desde ErpData.Maquina
    LocalSource: string;
    LocalLastErpHash: string;
    Status: TSyncStatus;
    Aplicar: Boolean;
    ConflictAction: TConflictAction;
    ErrorMsg: string;             // p.ej. "Centro/Maquina no sincronizado todavia"
    NewHash: string;
  end;

  TSyncRowShiftModel = record
    ErpModelo: TModeloHorarioErp;
    ErpLineas: TArray<TLineaModeloHorarioErp>;
    LocalShiftModelId: Integer;
    LocalNombre: string;
    LocalSource: string;
    LocalLastErpHash: string;
    NumLineas: Integer;           // count(ErpLineas) para mostrar al grid
    Status: TSyncStatus;
    Aplicar: Boolean;
    ConflictAction: TConflictAction;
    ErrorMsg: string;
    NewHash: string;
  end;

  TSyncRowAlmacen = record
    ErpData: TAlmacenErp;
    LocalAlmacenId: Integer;
    LocalNombre: string;
    LocalSource: string;
    LocalLastErpHash: string;
    Status: TSyncStatus;
    Aplicar: Boolean;
    ConflictAction: TConflictAction;
    ErrorMsg: string;
    NewHash: string;
  end;

  TSyncRowFamilia = record
    ErpData: TFamiliaErp;
    LocalFamiliaId: Integer;
    LocalDescripcion: string;
    LocalSource: string;
    LocalLastErpHash: string;
    Status: TSyncStatus;
    Aplicar: Boolean;
    ConflictAction: TConflictAction;
    ErrorMsg: string;
    NewHash: string;
  end;

  // Un GrupoHorario del ERP que es transformara en un FS_PL_Calendar amb
  // les seves regles setmanals (CalendarDayRule) i excepcions
  // (CalendarException). El hash es calcula sobre l'historic agregat de
  // CalendarioLaboral del grup, per detectar canvis entre sincronitzacions.
  TSyncRowCalendario = record
    GrupoErpCodigo: string;
    Descripcion: string;
    DiasTotales: Integer;         // dies dins el rang importat
    DiasLaborables: Integer;      // dies amb Duracion > 0
    DiasFestivos: Integer;        // dies amb Duracion = 0
    LocalCalendarId: Integer;
    LocalNombre: string;
    LocalSource: string;
    LocalLastErpHash: string;
    Status: TSyncStatus;
    Aplicar: Boolean;
    ConflictAction: TConflictAction;
    ErrorMsg: string;
    NewHash: string;
  end;

  TSyncSummary = record
    Total: Integer;
    Nuevos: Integer;
    Actualizados: Integer;
    SinCambios: Integer;
    Conflictos: Integer;
    Eliminados: Integer;
    Errores: Integer;
    Aplicados: Integer;
  end;

function SyncStatusToText(AStatus: TSyncStatus): string;
function SyncStatusColor(AStatus: TSyncStatus): Cardinal;

implementation

uses
  Vcl.Graphics;

function SyncStatusToText(AStatus: TSyncStatus): string;
begin
  case AStatus of
    ssNuevo:        Result := 'Nuevo';
    ssSinCambios:   Result := 'Sin cambios';
    ssActualizado:  Result := 'Actualizado';
    ssConflicto:    Result := 'CONFLICTO';
    ssEliminadoErp: Result := 'Eliminado en ERP';
    ssError:        Result := 'Error';
  else
    Result := '';
  end;
end;

function SyncStatusColor(AStatus: TSyncStatus): Cardinal;
begin
  case AStatus of
    ssNuevo:        Result := $00E8F8E8; // verde suave
    ssActualizado:  Result := $00FFF4D6; // amarillo suave
    ssSinCambios:   Result := clWhite;
    ssConflicto:    Result := $00D6D6FF; // rosa/rojo suave
    ssEliminadoErp: Result := $00E0E0E0; // gris
    ssError:        Result := $008080FF; // rojo
  else
    Result := clWhite;
  end;
end;

end.
