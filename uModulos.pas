unit uModulos;

{
  MODULOS POR LICENCIA.

  Que modulos del Planner tiene contratados esta empresa. El resto de la
  aplicacion pregunta SIEMPRE por aqui (IsModuleEnabled), nunca lee la tabla
  directamente: si algun dia la licencia pasa a ser un fichero firmado en vez
  de una tabla, solo cambia esta unidad.

  ---------------------------------------------------------------------------
  TRES EJES QUE NO HAY QUE MEZCLAR
  ---------------------------------------------------------------------------

                LICENCIA          USO                 PERMISO
    Decide      FactoryStart      El cliente          Admin del cliente
    Pregunta    ha pagado X?      esta fabrica usa X? puede Juan tocar X?
    Si esta off el modulo no      existe, no se usa   existe, el no entra
                existe

  Cascada: licencia (existe) -> uso (se muestra) -> permiso (se puede tocar).

  IMPORTANTE: NO reutilizar HasPermission para esto. HasPermission empieza con
  "if IsAdmin then Exit(True)", asi que el administrador de un cliente que NO
  ha comprado un modulo lo veria igualmente. Es justo lo contrario de lo que se
  quiere: los permisos son POR USUARIO, las licencias POR EMPRESA.

  ---------------------------------------------------------------------------
  QUE PASA SI ALGO FALLA
  ---------------------------------------------------------------------------

  Ante la duda, TODO ACTIVO. Si la tabla no existe (base sin migrar), si la
  consulta falla o si el modulo no esta dado de alta, IsModuleEnabled devuelve
  True.

  Es deliberado: el fallo aceptable es que un cliente vea de mas, no que un
  cliente que ha pagado se quede sin su modulo en mitad de una jornada por un
  problema de base de datos. Y ademas hace que actualizar el ejecutable sin
  aplicar la migracion no rompa nada.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.Win.ADODB;

type
  // Un modulo tal como se administra en pantalla.
  TModuloInfo = record
    Codigo: string;          // clave estable: NO renombrar
    Nombre: string;          // como se llama de cara al cliente
    Descripcion: string;     // que incluye, en una linea
    Activo: Boolean;
    FechaCaducidad: TDateTime;   // 0 = sin caducidad
    Observaciones: string;
    // False = el cliente que no lo tiene NI SE ENTERA (se oculta del menu).
    // True  = se ve en gris con una llamada a la accion.
    //
    // El criterio: lo que no le aplica a su fabrica, fuera; lo que podria
    // querer comprar, visible. Ocultarlo todo deja la interfaz limpia pero
    // el cliente no descubre nunca que existe y no lo pide.
    MostrarSiApagado: Boolean;
  end;
  TModuloInfoArray = TArray<TModuloInfo>;

// --- Consulta (lo que usa el resto de la aplicacion) ------------------------

// Esta activo este modulo? Ver arriba: ante cualquier duda, True.
function IsModuleEnabled(const ACodigo: string): Boolean;

// Se debe ENSENAR la entrada de menu de este modulo aunque este apagado?
function ModuloVisibleSiApagado(const ACodigo: string): Boolean;

// Nombre comercial del modulo, para mensajes al usuario.
function NombreModulo(const ACodigo: string): string;

// --- Carga y administracion -------------------------------------------------

// Lee los modulos de la empresa. Se llama UNA vez al conectar; a partir de ahi
// IsModuleEnabled responde de memoria y no toca base de datos.
procedure CargarModulos(const AConn: TADOConnection; const ACodigoEmpresa: Integer);

// Catalogo completo (los conocidos por esta version) con su estado actual.
// Es lo que pinta la pantalla de administracion.
function ListarModulos: TModuloInfoArray;

// Guarda el estado de todos los modulos y recarga la cache.
procedure GuardarModulos(const AConn: TADOConnection;
  const ACodigoEmpresa: Integer; const AModulos: TModuloInfoArray);

// Mensaje estandar cuando alguien entra a un modulo no contratado.
function MensajeModuloNoContratado(const ACodigo: string): string;

const
  // Codigos de modulo. Se usan como constantes en todo el codigo para que un
  // error de escritura lo cace el compilador, no el usuario en produccion.
  MOD_OPERARIOS    = 'OPERARIOS';
  MOD_INGENIERIA   = 'INGENIERIA';
  MOD_MRP          = 'MRP';
  MOD_UTILLAJES    = 'UTILLAJES';
  MOD_OPTIMIZACION = 'OPTIMIZACION';
  MOD_ANALITICA    = 'ANALITICA';
  MOD_NESTING      = 'NESTING';

implementation

type
  // Definicion de fabrica de un modulo: lo que esta version sabe vender.
  TModuloDef = record
    Codigo: string;
    Nombre: string;
    Descripcion: string;
    MostrarSiApagado: Boolean;
  end;

const
  // El CATALOGO. Anadir un modulo nuevo es anadir una linea aqui y otra al
  // INSERT de la migracion.
  //
  // Que NO esta aqui, y por que: el Gantt de produccion, los centros, los
  // calendarios, los turnos, el backlog, la planificacion manual y automatica
  // basica, el dashboard y el conector ERP son el NUCLEO. Sin ellos no hay
  // producto que vender, asi que no son un modulo: siempre estan.
  //
  // Kanban y Lista de prioridades tampoco son modulo a proposito: son VISTAS
  // del mismo plan. Cobrarlas aparte hace que el producto parezca troceado en
  // exceso y el cliente lo lee como "me cobran por mirar mis datos de otra
  // forma".
  MODULOS_DEF: array[0..6] of TModuloDef = (
    (Codigo: MOD_OPERARIOS;
     Nombre: 'Operarios';
     Descripcion: 'Planificar personas y no s'#243'lo m'#225'quinas: operarios, ' +
       'ausencias, habilidades y carga por persona.';
     // Una fabrica que planifica solo maquinas no lo necesita: fuera del menu.
     MostrarSiApagado: False),

    (Codigo: MOD_INGENIERIA;
     Nombre: 'Ingenier'#237'a (proyectos)';
     Descripcion: 'Planificaci'#243'n por tareas estilo MS Project: WBS, camino ' +
       'cr'#237'tico, l'#237'nea base y nivelaci'#243'n de recursos.';
     // Es la venta cruzada mas natural del producto: que se vea.
     MostrarSiApagado: True),

    (Codigo: MOD_MRP;
     Nombre: 'Stock y aprovisionamiento';
     Descripcion: 'Proyecci'#243'n de stock, roturas anticipadas y recomendaci'#243'n ' +
       'de compra o preparaci'#243'n.';
     MostrarSiApagado: True),

    (Codigo: MOD_UTILLAJES;
     Nombre: 'Utillajes y moldes';
     Descripcion: 'Recursos secundarios que limitan la producci'#243'n: moldes, ' +
       'utillajes y sus restricciones en el motor.';
     // Sectorial: quien no usa utillajes no quiere ni verlo.
     MostrarSiApagado: False),

    (Codigo: MOD_OPTIMIZACION;
     Nombre: 'Optimizaci'#243'n avanzada';
     Descripcion: 'Motor de reglas, tiempos de cambio y optimizador que ' +
       'busca el mejor orden de fabricaci'#243'n.';
     MostrarSiApagado: True),

    (Codigo: MOD_ANALITICA;
     Nombre: 'Anal'#237'tica y cuadros de mando';
     Descripcion: 'An'#225'lisis del plan, mapas de calor, histogramas e ' +
       'indicadores de centros.';
     MostrarSiApagado: True),

    (Codigo: MOD_NESTING;
     Nombre: 'Suite de corte (nesting)';
     Descripcion: 'Optimizaci'#243'n de corte y anidado de piezas en plancha.';
     // Muy sectorial (chapa, textil, madera): fuera si no aplica.
     MostrarSiApagado: False)
  );

var
  // Cache en memoria. Se llena al conectar y se consulta miles de veces, asi
  // que no puede ir a base de datos en cada pregunta.
  GEstado: TDictionary<string, Boolean> = nil;
  GCargado: Boolean = False;

function BuscarDef(const ACodigo: string; out ADef: TModuloDef): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(MODULOS_DEF) to High(MODULOS_DEF) do
    if SameText(MODULOS_DEF[I].Codigo, ACodigo) then
    begin
      ADef := MODULOS_DEF[I];
      Exit(True);
    end;
end;

function IsModuleEnabled(const ACodigo: string): Boolean;
var
  V: Boolean;
begin
  // Sin cache cargada (arranque, base sin migrar, fallo de conexion): TODO
  // ACTIVO. Ver la cabecera de la unidad: es preferible que se vea de mas a
  // que un cliente que ha pagado se quede sin su modulo.
  if (not GCargado) or (GEstado = nil) then Exit(True);
  if not GEstado.TryGetValue(UpperCase(ACodigo), V) then Exit(True);
  Result := V;
end;

function ModuloVisibleSiApagado(const ACodigo: string): Boolean;
var
  Def: TModuloDef;
begin
  if BuscarDef(ACodigo, Def) then
    Result := Def.MostrarSiApagado
  else
    Result := False;
end;

function NombreModulo(const ACodigo: string): string;
var
  Def: TModuloDef;
begin
  if BuscarDef(ACodigo, Def) then
    Result := Def.Nombre
  else
    Result := ACodigo;
end;

function MensajeModuloNoContratado(const ACodigo: string): string;
begin
  Result := Format(
    'El m'#243'dulo "%s" no est'#225' incluido en su licencia.'#13#10#13#10 +
    'Si le interesa, p'#243'ngase en contacto con FactoryStart y se lo ' +
    'activamos sin necesidad de reinstalar nada.',
    [NombreModulo(ACodigo)]);
end;

procedure CargarModulos(const AConn: TADOConnection; const ACodigoEmpresa: Integer);
var
  Q: TADOQuery;
  I: Integer;
begin
  if GEstado = nil then
    GEstado := TDictionary<string, Boolean>.Create;
  GEstado.Clear;
  GCargado := False;

  if AConn = nil then Exit;

  // Partir de TODO ACTIVO y solo apagar lo que la tabla diga: un modulo que
  // esta version conoce pero que no esta dado de alta (base migrada por una
  // version anterior) debe funcionar, no desaparecer.
  for I := Low(MODULOS_DEF) to High(MODULOS_DEF) do
    GEstado.AddOrSetValue(UpperCase(MODULOS_DEF[I].Codigo), True);

  Q := TADOQuery.Create(nil);
  try
    try
      Q.Connection := AConn;
      Q.SQL.Text :=
        'SELECT Codigo, Activo, FechaCaducidad FROM FS_PL_Modulo ' +
        'WHERE CodigoEmpresa = :CE';
      Q.Parameters.ParamByName('CE').Value := ACodigoEmpresa;
      Q.Open;
      while not Q.Eof do
      begin
        var Activo: Boolean := Q.FieldByName('Activo').AsBoolean;
        // Caducidad: si la hay y ya paso, el modulo se apaga aunque este
        // marcado activo. Hoy no se usa (venta perpetua), pero el dato manda
        // desde el primer dia para no tener que revisar esto luego.
        if Activo and (not Q.FieldByName('FechaCaducidad').IsNull) then
          if Q.FieldByName('FechaCaducidad').AsDateTime < Date then
            Activo := False;
        GEstado.AddOrSetValue(
          UpperCase(Q.FieldByName('Codigo').AsString), Activo);
        Q.Next;
      end;
      GCargado := True;
    except
      // Tabla inexistente (V084 sin aplicar) o cualquier otro problema: se
      // deja GCargado en False y todo queda activo. No se avisa al usuario:
      // no es culpa suya y no puede hacer nada.
      GCargado := False;
    end;
  finally
    Q.Free;
  end;
end;

function ListarModulos: TModuloInfoArray;
var
  I: Integer;
  V: Boolean;
begin
  SetLength(Result, Length(MODULOS_DEF));
  for I := Low(MODULOS_DEF) to High(MODULOS_DEF) do
  begin
    Result[I].Codigo := MODULOS_DEF[I].Codigo;
    Result[I].Nombre := MODULOS_DEF[I].Nombre;
    Result[I].Descripcion := MODULOS_DEF[I].Descripcion;
    Result[I].MostrarSiApagado := MODULOS_DEF[I].MostrarSiApagado;
    if (GEstado <> nil) and
       GEstado.TryGetValue(UpperCase(MODULOS_DEF[I].Codigo), V) then
      Result[I].Activo := V
    else
      Result[I].Activo := True;
  end;
end;

procedure GuardarModulos(const AConn: TADOConnection;
  const ACodigoEmpresa: Integer; const AModulos: TModuloInfoArray);
var
  Cmd: TADOCommand;
  I: Integer;
  Fecha: string;
begin
  if AConn = nil then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;
    for I := 0 to High(AModulos) do
    begin
      if AModulos[I].FechaCaducidad > 0 then
        Fecha := '''' + FormatDateTime('yyyy-mm-dd', AModulos[I].FechaCaducidad) + ''''
      else
        Fecha := 'NULL';

      // MERGE en dos pasos (UPDATE y, si no habia fila, INSERT): mas simple de
      // leer que un MERGE de SQL Server y sin sus rarezas con concurrencia.
      Cmd.CommandText :=
        'UPDATE FS_PL_Modulo SET Activo = ' +
          IntToStr(Ord(AModulos[I].Activo)) +
        ', FechaCaducidad = ' + Fecha +
        ', Observaciones = N''' +
          StringReplace(AModulos[I].Observaciones, '''', '''''', [rfReplaceAll]) + '''' +
        ' WHERE CodigoEmpresa = ' + IntToStr(ACodigoEmpresa) +
        ' AND Codigo = N''' + AModulos[I].Codigo + '''';
      Cmd.Execute;

      Cmd.CommandText :=
        'IF NOT EXISTS (SELECT 1 FROM FS_PL_Modulo WHERE CodigoEmpresa = ' +
          IntToStr(ACodigoEmpresa) + ' AND Codigo = N''' + AModulos[I].Codigo + ''') ' +
        'INSERT INTO FS_PL_Modulo (CodigoEmpresa, Codigo, Activo, FechaCaducidad) ' +
        'VALUES (' + IntToStr(ACodigoEmpresa) + ', N''' + AModulos[I].Codigo +
          ''', ' + IntToStr(Ord(AModulos[I].Activo)) + ', ' + Fecha + ')';
      Cmd.Execute;
    end;
  finally
    Cmd.Free;
  end;

  // Releer: la cache manda a partir de ahora y tiene que reflejar lo guardado.
  CargarModulos(AConn, ACodigoEmpresa);
end;

initialization

finalization
  GEstado.Free;

end.
