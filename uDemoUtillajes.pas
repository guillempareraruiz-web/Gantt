unit uDemoUtillajes;

// Utillajes de demostracion (V072/V073).
//
// Crea un catalogo pequenyo de utillajes y los liga a las operaciones que
// genera la demo del Gantt (uDemoPlanEngine.OPERS). Con eso, la alerta R02
// ("mismo utillaje/molde usado a la vez") tiene datos reales que detectar en
// modo Demo sin que el usuario tenga que dar nada de alta a mano.
//
// Los utillajes son datos 100% del Planner (Sage200 no los modela), asi que
// aqui no hay nada de ERP.
//
// Se marcan con un prefijo de codigo (DEMO-) para poder limpiarlos de forma
// selectiva sin tocar los utillajes reales del usuario, igual que hace
// uDemoBacklog con OrigenERP='DEMO'.

interface

uses
  System.SysUtils, System.Classes,
  Data.Win.ADODB;

const
  // Prefijo que marca un utillaje como generado por la demo.
  DEMO_UTIL_PREFIX = 'DEMO-';

// Borra SOLO los utillajes de demo (y sus relaciones, por ON DELETE CASCADE).
// No toca los utillajes dados de alta por el usuario.
//
// Publica a proposito: hoy solo la llama GenerarUtillajesDemo (que regenera),
// pero si algun dia se anyade un "borrar proyecto demo", debe llamarse aqui
// tambien; si no, los DEMO- quedarian huerfanos en el catalogo del cliente.
procedure LimpiarUtillajesDemo(AConn: TADOConnection; ACodigoEmpresa: SmallInt);

// Crea el catalogo demo y lo liga a operaciones. Idempotente: limpia antes.
// Devuelve cuantos utillajes ha creado (0 si no aplica).
//
// AProjectId debe ser el proyecto donde se han generado los nodos: si NO es
// un proyecto demo (EsDemo=1), no se hace nada. La generacion de nodos demo
// tambien puede apuntar a un proyecto real, y ahi no toca ensuciar el
// catalogo del cliente con utillajes de mentira.
//
// Silencioso ante errores de BD (p.ej. V072/V073 sin aplicar): la demo del
// Gantt no debe romperse por los utillajes.
function GenerarUtillajesDemo(AConn: TADOConnection;
  ACodigoEmpresa: SmallInt; AProjectId: Integer): Integer;

implementation

uses
  uPlanLog;

type
  TUtilDemoDef = record
    Codigo: string;
    Descripcion: string;
    Tipo: string;
    Ubicacion: string;
    Cantidad: Integer;        // ejemplares: 1 = uso exclusivo -> genera R02
    Operacion: string;        // operacion que lo requiere (de OPERS)
    VidaTotal: Int64;
    Contador: Int64;
  end;

const
  // Ligados a operaciones que uDemoPlanEngine.OPERS genera de verdad.
  //
  // El reparto de Cantidad esta pensado para que la demo ensenye los tres
  // casos de un vistazo:
  //   - Cantidad = 1  -> cuello de botella, muchos conflictos R02.
  //   - Cantidad = 2..3 -> conflictos ocasionales.
  //   - Cantidad alta -> sin conflictos (control).
  UTILES_DEMO: array[0..5] of TUtilDemoDef = (
    (Codigo: 'DEMO-MOR-80';  Descripcion: 'Mordaza neum'#225'tica 80 mm';
     Tipo: 'Mordaza';   Ubicacion: 'Estanter'#237'a A-1'; Cantidad: 1;
     Operacion: 'CORTAR';    VidaTotal: 50000; Contador: 46500),

    (Codigo: 'DEMO-TRQ-12'; Descripcion: 'Troquel corte 12 mm';
     Tipo: 'Troquel';   Ubicacion: 'Estanter'#237'a A-2'; Cantidad: 2;
     Operacion: 'TALADRAR';  VidaTotal: 120000; Contador: 31000),

    (Codigo: 'DEMO-PLT-S1'; Descripcion: 'Plantilla soldadura chasis';
     Tipo: 'Plantilla'; Ubicacion: 'Armario B-3'; Cantidad: 1;
     Operacion: 'SOLDAR';    VidaTotal: 0; Contador: 0),

    (Codigo: 'DEMO-CAL-05'; Descripcion: 'Calibre verificaci'#243'n 0,5 mm';
     Tipo: 'Calibre';   Ubicacion: 'Laboratorio'; Cantidad: 4;
     Operacion: 'MECANIZAR'; VidaTotal: 20000; Contador: 20400),

    (Codigo: 'DEMO-BOQ-3'; Descripcion: 'Boquilla pintura 3 mm';
     Tipo: 'Boquilla';  Ubicacion: 'Cabina pintura'; Cantidad: 3;
     Operacion: 'PINTAR';    VidaTotal: 8000; Contador: 5200),

    (Codigo: 'DEMO-UTL-EMB'; Descripcion: 'Utillaje embalaje autom'#225'tico';
     Tipo: 'Utillaje';  Ubicacion: 'L'#237'nea embalaje'; Cantidad: 20;
     Operacion: 'EMBALAR';   VidaTotal: 0; Contador: 0)
  );

function QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

procedure Exec(AConn: TADOConnection; const ASQL: string);
var
  Cmd: TADOCommand;
begin
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := AConn;
    Cmd.CommandText := ASQL;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure LimpiarUtillajesDemo(AConn: TADOConnection; ACodigoEmpresa: SmallInt);
var
  CE: string;
begin
  CE := IntToStr(ACodigoEmpresa);
  // Las relaciones (Center/Article/Operation) caen solas por ON DELETE CASCADE.
  // FS_PL_MoldUtillaje NO cascadea (es una FK sin cascade), pero la demo nunca
  // liga utillajes a moldes, asi que no hay riesgo de bloqueo.
  Exec(AConn,
    'DELETE FROM FS_PL_Utillaje WHERE CodigoEmpresa = ' + CE +
    ' AND Codigo LIKE ' + QStr(DEMO_UTIL_PREFIX + '%'));
end;

// True si el proyecto esta marcado como demo (EsDemo = 1).
function EsProyectoDemo(AConn: TADOConnection; ACodigoEmpresa: SmallInt;
  AProjectId: Integer): Boolean;
var
  Q: TADOQuery;
begin
  Result := False;
  if AProjectId <= 0 then Exit;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT TOP 1 ProjectId FROM FS_PL_Project ' +
      'WHERE CodigoEmpresa = :CE AND ProjectId = :PID AND ISNULL(EsDemo, 0) = 1';
    Q.Parameters.ParamByName('CE').Value := ACodigoEmpresa;
    Q.Parameters.ParamByName('PID').Value := AProjectId;
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

function GenerarUtillajesDemo(AConn: TADOConnection;
  ACodigoEmpresa: SmallInt; AProjectId: Integer): Integer;
var
  CE: string;
  I: Integer;
  D: TUtilDemoDef;
  Q: TADOQuery;
  NewId: Integer;
begin
  Result := 0;
  CE := IntToStr(ACodigoEmpresa);

  try
    // Solo en el proyecto demo: los nodos demo tambien pueden generarse sobre
    // un proyecto real, y ahi no se toca el catalogo del cliente.
    if not EsProyectoDemo(AConn, ACodigoEmpresa, AProjectId) then Exit;

    LimpiarUtillajesDemo(AConn, ACodigoEmpresa);

    for I := Low(UTILES_DEMO) to High(UTILES_DEMO) do
    begin
      D := UTILES_DEMO[I];

      Q := TADOQuery.Create(nil);
      try
        Q.Connection := AConn;
        Q.SQL.Text :=
          'INSERT INTO FS_PL_Utillaje (CodigoEmpresa, Codigo, Descripcion, ' +
          '  Tipo, Ubicacion, Cantidad, Estado, UnidadVida, ContadorActual, ' +
          '  VidaUtilTotal, Disponible, DisponiblePlanificacion, Activo, Orden) ' +
          'OUTPUT INSERTED.UtillajeId ' +
          'VALUES (' + CE + ', ' +
          QStr(D.Codigo) + ', ' + QStr(D.Descripcion) + ', ' +
          QStr(D.Tipo) + ', ' + QStr(D.Ubicacion) + ', ' +
          IntToStr(D.Cantidad) + ', 0, 0, ' +
          IntToStr(D.Contador) + ', ' + IntToStr(D.VidaTotal) + ', ' +
          '1, 1, 1, ' + IntToStr(I) + ')';
        Q.Open;
        if Q.Eof then Continue;
        NewId := Q.Fields[0].AsInteger;
      finally
        Q.Free;
      end;

      // El requisito por OPERACION es lo que hace que los nodos ya generados
      // hereden el utillaje sin tocarlos: la vista FS_PL_V_NodeUtillaje
      // resuelve NodeData.Operacion -> utillaje.
      Exec(AConn,
        'INSERT INTO FS_PL_UtillajeOperation (CodigoEmpresa, UtillajeId, ' +
        '  Operacion, Obligatorio) VALUES (' +
        CE + ', ' + IntToStr(NewId) + ', ' + QStr(D.Operacion) + ', 1)');

      Inc(Result);
    end;

    PlanLog.Linea('utillajes demo: %d creados y ligados a operaciones', [Result]);
  except
    on E: Exception do
    begin
      // Sin V072/V073 aplicadas (o cualquier otro fallo), la demo del Gantt
      // debe seguir funcionando: los utillajes son un extra.
      PlanLog.Linea('utillajes demo: omitidos (%s)', [E.Message]);
      Result := 0;
    end;
  end;
end;

end.
