unit uDemoPerfiles;

{
  PERFILES DE DEMOSTRACION.

  El problema que resuelve: el generador de demo siempre ha creado los mismos
  datos —operaciones CORTAR / PULIR / BRONCEAR, articulos "Pieza A grande",
  clientes CLI-001— que describen un taller metalurgico. Delante de un
  fabricante de bolsas de papel, de una inyectora de plastico o de una imprenta,
  esos nombres dicen exactamente lo contrario de lo que se quiere transmitir:
  que la herramienta no va con ellos.

  Un perfil es la respuesta: describe COMO ES UNA PLANTA y CON QUE PALABRAS se
  habla en ella, y el generador se limita a aplicarlo.

  ---------------------------------------------------------------------------
  POR QUE "PERFIL DE PLANTA" Y NO "SECTOR"
  ---------------------------------------------------------------------------

  Parece natural organizar esto por sectores ("packaging", "inyeccion",
  "mecanizado"), pero no funciona. Dos empresas del MISMO sector pueden
  necesitar demos opuestas: una convertidora de film flexible con dos lineas de
  impresion y una fabrica de bolsas con siete lineas de formato comparten
  sector y no se parecen en nada operativamente. Y al reves: una fabrica de
  bolsas y una inyectora, que no comparten sector, comparten lo que de verdad
  define el plan —lineas en paralelo, cambio de formato o molde, series largas.

  Asi que un perfil describe la FORMA de la planta:

    - cuantos centros hay y como se llaman
    - cuantos niveles tiene la ruta y con que verbos
    - que atributo provoca el cambio de preparacion (color, formato, molde)
    - en que unidad se mide la produccion
    - que vocabulario usa el cliente para sus articulos

  Con cinco o seis perfiles se cubre casi cualquier visita. Lo que cambia de un
  cliente a otro dentro del mismo perfil es el vocabulario, no la estructura.

  ---------------------------------------------------------------------------
  DONDE VIVEN
  ---------------------------------------------------------------------------

  En ficheros JSON bajo `Demo\Perfiles\*.json`, junto al ejecutable. Mismo
  criterio que la ayuda contextual: esto es PRODUCTO, no dato del cliente. Se
  versionan con git, se editan sin abrir la aplicacion, se despliegan con el
  .exe y se pueden pasar por correo a un comercial.

  Un perfil nuevo NO exige recompilar ni migrar nada: se deja el .json en la
  carpeta y aparece en la lista.
}

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils,
  System.Generics.Collections, System.Generics.Defaults;

type
  // Un centro de trabajo del perfil.
  TDemoCentro = record
    Codigo: string;
    Nombre: string;
    // Cuantos trabajos caben a la vez. 1 = linea secuencial (el caso normal en
    // impresion o inyeccion); >1 = centro con varios puestos en paralelo.
    MaxLanes: Integer;
    // Minutos de preparacion cuando cambia el atributo de setup entre dos
    // trabajos consecutivos. 0 = sin regla para este centro.
    SetupMin: Integer;
  end;
  TDemoCentroArray = TArray<TDemoCentro>;

  // Un articulo del catalogo ficticio.
  TDemoArticulo = record
    Codigo: string;
    Descripcion: string;
    // Valor del atributo que dispara el cambio de preparacion (el color de la
    // tinta, el formato de bolsa, la referencia del molde...). Dos trabajos
    // seguidos con el MISMO valor no pagan setup; si cambia, si.
    ValorSetup: string;
  end;
  TDemoArticuloArray = TArray<TDemoArticulo>;

  // Un perfil completo.
  TDemoPerfil = record
    // Identificacion (lo que ve el comercial al elegir).
    Id: string;             // nombre del fichero sin extension
    Nombre: string;         // "Fabricacion de bolsas de papel"
    Descripcion: string;    // una linea explicando para quien es
    Sector: string;         // solo para agrupar en la lista

    // --- Forma de la planta ---
    Centros: TDemoCentroArray;
    // Verbos de las operaciones, EN ORDEN DE RUTA. El generador los usa para
    // nombrar las operaciones de cada orden.
    Operaciones: TArray<string>;
    Articulos: TDemoArticuloArray;
    Clientes: TArray<string>;

    // --- Vocabulario ---
    // Como llama el cliente a sus cosas. Se usa en titulos y etiquetas para
    // que la demo hable su idioma.
    NombreAtributoSetup: string;   // "Color", "Formato", "Molde"
    UnidadProduccion: string;      // "bolsas", "m2", "piezas"
    PrefijoOrden: string;          // "OF", "OP", "LOTE"

    // --- Parametros por defecto de la generacion ---
    NumOrdenes: Integer;           // cuantas ordenes generar
    OpsPorOrden: Integer;          // operaciones por orden (niveles de ruta)
    PctPlanificado: Integer;       // % que se planifica; el resto queda en backlog

    Cargado: Boolean;              // False = perfil vacio / no encontrado
  end;
  TDemoPerfilArray = TArray<TDemoPerfil>;

// Carpeta donde viven los perfiles (junto al .exe). Se crea si no existe.
function CarpetaPerfilesDemo: string;

// Todos los perfiles disponibles, ordenados por nombre. Nunca falla: si la
// carpeta no existe o esta vacia devuelve un array vacio, y el llamante cae al
// generador de siempre.
function CargarPerfilesDemo: TDemoPerfilArray;

// Un perfil concreto por Id (nombre de fichero). Cargado=False si no esta.
function CargarPerfilDemo(const AId: string): TDemoPerfil;

// Escribe un perfil a disco. Sirve para el editor y para sembrar los de
// fabrica la primera vez.
procedure GuardarPerfilDemo(const APerfil: TDemoPerfil);

// Crea los perfiles de fabrica si la carpeta esta vacia. Idempotente: si ya
// hay ficheros no toca nada, para no pisar los que haya retocado el comercial.
procedure SembrarPerfilesDeFabrica;

implementation

uses
  Vcl.Forms;

function CarpetaPerfilesDemo: string;
begin
  Result := TPath.Combine(
    TPath.Combine(ExtractFilePath(Application.ExeName), 'Demo'), 'Perfiles');
  if not TDirectory.Exists(Result) then
    try
      TDirectory.CreateDirectory(Result);
    except
      // Sin permisos de escritura: no es fatal, simplemente no habra perfiles
      // y el generador usara los datos de siempre.
    end;
end;

// --- Helpers de lectura tolerante ------------------------------------------
// Un JSON retocado a mano por un comercial puede tener campos ausentes o mal
// escritos. Ninguna de estas funciones lanza: devuelven el valor por defecto y
// el perfil se carga igualmente, aunque sea a medias. Un perfil incompleto
// sigue siendo mas util que un error al abrir la demo.

function LeerStr(AObj: TJSONObject; const ACampo: string;
  const ADefecto: string = ''): string;
var
  V: TJSONValue;
begin
  Result := ADefecto;
  if AObj = nil then Exit;
  V := AObj.GetValue(ACampo);
  if (V <> nil) and (not (V is TJSONNull)) then
    Result := V.Value;
end;

function LeerInt(AObj: TJSONObject; const ACampo: string;
  ADefecto: Integer): Integer;
var
  S: string;
begin
  S := LeerStr(AObj, ACampo, '');
  if (S = '') or (not TryStrToInt(S, Result)) then
    Result := ADefecto;
end;

function LeerArrayStr(AObj: TJSONObject; const ACampo: string): TArray<string>;
var
  Arr: TJSONArray;
  V: TJSONValue;
  L: TList<string>;
  I: Integer;
begin
  SetLength(Result, 0);
  if AObj = nil then Exit;
  V := AObj.GetValue(ACampo);
  if not (V is TJSONArray) then Exit;

  Arr := TJSONArray(V);
  L := TList<string>.Create;
  try
    for I := 0 to Arr.Count - 1 do
      if not (Arr.Items[I] is TJSONNull) then
        L.Add(Arr.Items[I].Value);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function ParsearPerfil(const AJson, AId: string): TDemoPerfil;
var
  Raiz: TJSONObject;
  V: TJSONValue;
  Arr: TJSONArray;
  Obj: TJSONObject;
  I: Integer;
  LC: TList<TDemoCentro>;
  C: TDemoCentro;
  LA: TList<TDemoArticulo>;
  A: TDemoArticulo;
begin
  Result := Default(TDemoPerfil);
  Result.Id := AId;
  Result.Cargado := False;

  Raiz := nil;
  try
    Raiz := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  except
    // JSON invalido: se ignora el perfil en vez de tumbar la carga entera.
    Raiz := nil;
  end;
  if Raiz = nil then Exit;

  try
    Result.Nombre := LeerStr(Raiz, 'nombre', AId);
    Result.Descripcion := LeerStr(Raiz, 'descripcion');
    Result.Sector := LeerStr(Raiz, 'sector');

    Result.NombreAtributoSetup := LeerStr(Raiz, 'atributoSetup', 'Formato');
    Result.UnidadProduccion := LeerStr(Raiz, 'unidad', 'unidades');
    Result.PrefijoOrden := LeerStr(Raiz, 'prefijoOrden', 'OF');

    Result.NumOrdenes := LeerInt(Raiz, 'numOrdenes', 12);
    Result.OpsPorOrden := LeerInt(Raiz, 'opsPorOrden', 3);
    Result.PctPlanificado := LeerInt(Raiz, 'pctPlanificado', 80);

    Result.Operaciones := LeerArrayStr(Raiz, 'operaciones');
    Result.Clientes := LeerArrayStr(Raiz, 'clientes');

    // Centros.
    V := Raiz.GetValue('centros');
    if V is TJSONArray then
    begin
      Arr := TJSONArray(V);
      LC := TList<TDemoCentro>.Create;
      try
        for I := 0 to Arr.Count - 1 do
          if Arr.Items[I] is TJSONObject then
          begin
            Obj := TJSONObject(Arr.Items[I]);
            C := Default(TDemoCentro);
            C.Codigo := LeerStr(Obj, 'codigo');
            C.Nombre := LeerStr(Obj, 'nombre', C.Codigo);
            C.MaxLanes := LeerInt(Obj, 'maxLanes', 1);
            C.SetupMin := LeerInt(Obj, 'setupMin', 0);
            if C.Codigo <> '' then LC.Add(C);
          end;
        Result.Centros := LC.ToArray;
      finally
        LC.Free;
      end;
    end;

    // Articulos.
    V := Raiz.GetValue('articulos');
    if V is TJSONArray then
    begin
      Arr := TJSONArray(V);
      LA := TList<TDemoArticulo>.Create;
      try
        for I := 0 to Arr.Count - 1 do
          if Arr.Items[I] is TJSONObject then
          begin
            Obj := TJSONObject(Arr.Items[I]);
            A := Default(TDemoArticulo);
            A.Codigo := LeerStr(Obj, 'codigo');
            A.Descripcion := LeerStr(Obj, 'descripcion', A.Codigo);
            A.ValorSetup := LeerStr(Obj, 'valorSetup');
            if A.Codigo <> '' then LA.Add(A);
          end;
        Result.Articulos := LA.ToArray;
      finally
        LA.Free;
      end;
    end;

    // Un perfil sin articulos ni operaciones no puede generar nada util.
    Result.Cargado := (Length(Result.Articulos) > 0) and
                      (Length(Result.Operaciones) > 0);
  finally
    Raiz.Free;
  end;
end;

function CargarPerfilDemo(const AId: string): TDemoPerfil;
var
  Ruta: string;
begin
  Result := Default(TDemoPerfil);
  Result.Id := AId;
  Ruta := TPath.Combine(CarpetaPerfilesDemo, AId + '.json');
  if not TFile.Exists(Ruta) then Exit;

  try
    Result := ParsearPerfil(TFile.ReadAllText(Ruta, TEncoding.UTF8), AId);
  except
    Result.Cargado := False;
  end;
end;

function CargarPerfilesDemo: TDemoPerfilArray;
var
  Ficheros: TArray<string>;
  I: Integer;
  L: TList<TDemoPerfil>;
  P: TDemoPerfil;
begin
  SetLength(Result, 0);
  SembrarPerfilesDeFabrica;

  try
    Ficheros := TDirectory.GetFiles(CarpetaPerfilesDemo, '*.json');
  except
    Exit;
  end;

  L := TList<TDemoPerfil>.Create;
  try
    for I := 0 to High(Ficheros) do
    begin
      P := CargarPerfilDemo(TPath.GetFileNameWithoutExtension(Ficheros[I]));
      if P.Cargado then L.Add(P);
    end;

    L.Sort(TComparer<TDemoPerfil>.Construct(
      function(const X, Y: TDemoPerfil): Integer
      begin
        Result := CompareText(X.Nombre, Y.Nombre);
      end));

    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

procedure GuardarPerfilDemo(const APerfil: TDemoPerfil);
var
  Raiz: TJSONObject;
  ArrOps, ArrCli, ArrCen, ArrArt: TJSONArray;
  Obj: TJSONObject;
  I: Integer;
begin
  Raiz := TJSONObject.Create;
  try
    Raiz.AddPair('nombre', APerfil.Nombre);
    Raiz.AddPair('descripcion', APerfil.Descripcion);
    Raiz.AddPair('sector', APerfil.Sector);
    Raiz.AddPair('atributoSetup', APerfil.NombreAtributoSetup);
    Raiz.AddPair('unidad', APerfil.UnidadProduccion);
    Raiz.AddPair('prefijoOrden', APerfil.PrefijoOrden);
    Raiz.AddPair('numOrdenes', TJSONNumber.Create(APerfil.NumOrdenes));
    Raiz.AddPair('opsPorOrden', TJSONNumber.Create(APerfil.OpsPorOrden));
    Raiz.AddPair('pctPlanificado', TJSONNumber.Create(APerfil.PctPlanificado));

    ArrOps := TJSONArray.Create;
    for I := 0 to High(APerfil.Operaciones) do
      ArrOps.Add(APerfil.Operaciones[I]);
    Raiz.AddPair('operaciones', ArrOps);

    ArrCli := TJSONArray.Create;
    for I := 0 to High(APerfil.Clientes) do
      ArrCli.Add(APerfil.Clientes[I]);
    Raiz.AddPair('clientes', ArrCli);

    ArrCen := TJSONArray.Create;
    for I := 0 to High(APerfil.Centros) do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('codigo', APerfil.Centros[I].Codigo);
      Obj.AddPair('nombre', APerfil.Centros[I].Nombre);
      Obj.AddPair('maxLanes', TJSONNumber.Create(APerfil.Centros[I].MaxLanes));
      Obj.AddPair('setupMin', TJSONNumber.Create(APerfil.Centros[I].SetupMin));
      ArrCen.Add(Obj);
    end;
    Raiz.AddPair('centros', ArrCen);

    ArrArt := TJSONArray.Create;
    for I := 0 to High(APerfil.Articulos) do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('codigo', APerfil.Articulos[I].Codigo);
      Obj.AddPair('descripcion', APerfil.Articulos[I].Descripcion);
      Obj.AddPair('valorSetup', APerfil.Articulos[I].ValorSetup);
      ArrArt.Add(Obj);
    end;
    Raiz.AddPair('articulos', ArrArt);

    TFile.WriteAllText(
      TPath.Combine(CarpetaPerfilesDemo, APerfil.Id + '.json'),
      Raiz.Format(2), TEncoding.UTF8);
  finally
    Raiz.Free;
  end;
end;

procedure SembrarPerfilesDeFabrica;
var
  Carpeta: string;

  // Escribe un perfil solo si NO existe: si el comercial ha retocado el suyo,
  // no se le pisa nunca.
  procedure Sembrar(const AId, AJson: string);
  var
    Ruta: string;
  begin
    Ruta := TPath.Combine(Carpeta, AId + '.json');
    if TFile.Exists(Ruta) then Exit;
    try
      TFile.WriteAllText(Ruta, AJson, TEncoding.UTF8);
    except
      // Sin permisos: se sigue sin este perfil.
    end;
  end;

begin
  Carpeta := CarpetaPerfilesDemo;
  if not TDirectory.Exists(Carpeta) then Exit;

  // --- Bolsas de papel (Innovaciones Subbetica y similares) ---------------
  // Siete lineas de formato, cambio de preparacion al cambiar el formato de
  // bolsa. Ruta corta: imprimir, formar, asa, acabado.
  Sembrar('bolsas-papel',
    '{'#13#10 +
    '  "nombre": "Bolsas de papel",'#13#10 +
    '  "descripcion": "Varias lineas de formato en paralelo. El cambio de formato es el coste principal.",'#13#10 +
    '  "sector": "Packaging",'#13#10 +
    '  "atributoSetup": "Formato",'#13#10 +
    '  "unidad": "bolsas",'#13#10 +
    '  "prefijoOrden": "OF",'#13#10 +
    '  "numOrdenes": 18,'#13#10 +
    '  "opsPorOrden": 4,'#13#10 +
    '  "pctPlanificado": 80,'#13#10 +
    '  "operaciones": ["IMPRIMIR", "FORMAR", "COLOCAR ASA", "ACABADO"],'#13#10 +
    '  "clientes": ["RETAIL NORTE", "PANADERIAS UNIDAS", "MODA & CO", "GOURMET SELECT", "FARMACIAS DEL SUR"],'#13#10 +
    '  "centros": ['#13#10 +
    '    { "codigo": "DEMO-L1", "nombre": "Linea 1 - Asa rizada",  "maxLanes": 1, "setupMin": 45 },'#13#10 +
    '    { "codigo": "DEMO-L2", "nombre": "Linea 2 - Asa rizada",  "maxLanes": 1, "setupMin": 45 },'#13#10 +
    '    { "codigo": "DEMO-L3", "nombre": "Linea 3 - Asa plana",   "maxLanes": 1, "setupMin": 60 },'#13#10 +
    '    { "codigo": "DEMO-L4", "nombre": "Linea 4 - Asa plana",   "maxLanes": 1, "setupMin": 60 },'#13#10 +
    '    { "codigo": "DEMO-L5", "nombre": "Linea 5 - SOS",         "maxLanes": 1, "setupMin": 40 },'#13#10 +
    '    { "codigo": "DEMO-L6", "nombre": "Linea 6 - Industrial",  "maxLanes": 1, "setupMin": 75 },'#13#10 +
    '    { "codigo": "DEMO-L7", "nombre": "Linea 7 - Versatil",    "maxLanes": 1, "setupMin": 50 }'#13#10 +
    '  ],'#13#10 +
    '  "articulos": ['#13#10 +
    '    { "codigo": "BOL-2232", "descripcion": "Bolsa asa rizada 22x32 kraft",   "valorSetup": "22x32" },'#13#10 +
    '    { "codigo": "BOL-2232B","descripcion": "Bolsa asa rizada 22x32 blanca",  "valorSetup": "22x32" },'#13#10 +
    '    { "codigo": "BOL-3241", "descripcion": "Bolsa asa rizada 32x41 kraft",   "valorSetup": "32x41" },'#13#10 +
    '    { "codigo": "BOL-1826", "descripcion": "Bolsa asa plana 18x26 blanca",   "valorSetup": "18x26" },'#13#10 +
    '    { "codigo": "BOL-1826K","descripcion": "Bolsa asa plana 18x26 kraft",    "valorSetup": "18x26" },'#13#10 +
    '    { "codigo": "BOL-4050", "descripcion": "Bolsa asa plana 40x50 reforzada","valorSetup": "40x50" },'#13#10 +
    '    { "codigo": "SOS-1220", "descripcion": "Bolsa SOS 12x20 panaderia",      "valorSetup": "12x20" },'#13#10 +
    '    { "codigo": "SOS-1830", "descripcion": "Bolsa SOS 18x30 alimentacion",   "valorSetup": "18x30" },'#13#10 +
    '    { "codigo": "IND-5070", "descripcion": "Bolsa industrial doble capa",    "valorSetup": "50x70" },'#13#10 +
    '    { "codigo": "REG-2535", "descripcion": "Bolsa regalo 25x35 plastificada","valorSetup": "25x35" }'#13#10 +
    '  ]'#13#10 +
    '}');

  // --- Packaging flexible (Universal Sleeve y similares) ------------------
  // Pocas lineas, muy caras, y el cambio lo dispara el COLOR.
  Sembrar('packaging-flexible',
    '{'#13#10 +
    '  "nombre": "Packaging flexible / impresion",'#13#10 +
    '  "descripcion": "Pocas lineas de impresion. El cambio de color y substrato manda.",'#13#10 +
    '  "sector": "Packaging",'#13#10 +
    '  "atributoSetup": "Color",'#13#10 +
    '  "unidad": "m2",'#13#10 +
    '  "prefijoOrden": "OF",'#13#10 +
    '  "numOrdenes": 14,'#13#10 +
    '  "opsPorOrden": 4,'#13#10 +
    '  "pctPlanificado": 80,'#13#10 +
    '  "operaciones": ["IMPRIMIR", "LAMINAR", "CORTAR", "SLEEVING"],'#13#10 +
    '  "clientes": ["BEBIDAS DEL SUR", "LACTEOS NORTE", "CONSERVAS MAR", "HIGIENE PLUS", "SNACKS IBERIA"],'#13#10 +
    '  "centros": ['#13#10 +
    '    { "codigo": "DEMO-FLEXO1", "nombre": "Flexo 8 colores",   "maxLanes": 1, "setupMin": 90 },'#13#10 +
    '    { "codigo": "DEMO-HUECO1", "nombre": "Huecograbado",      "maxLanes": 1, "setupMin": 120 },'#13#10 +
    '    { "codigo": "DEMO-LAM",    "nombre": "Laminadora",        "maxLanes": 1, "setupMin": 30 },'#13#10 +
    '    { "codigo": "DEMO-CORTE",  "nombre": "Corte y rebobinado","maxLanes": 2, "setupMin": 20 }'#13#10 +
    '  ],'#13#10 +
    '  "articulos": ['#13#10 +
    '    { "codigo": "SLV-0100", "descripcion": "Sleeve refresco 500ml",     "valorSetup": "AZUL" },'#13#10 +
    '    { "codigo": "SLV-0101", "descripcion": "Sleeve refresco 1,5L",      "valorSetup": "AZUL" },'#13#10 +
    '    { "codigo": "SLV-0200", "descripcion": "Sleeve yogur pack 4",       "valorSetup": "BLANCO" },'#13#10 +
    '    { "codigo": "SLV-0201", "descripcion": "Sleeve yogur familiar",     "valorSetup": "BLANCO" },'#13#10 +
    '    { "codigo": "DOY-0300", "descripcion": "Doypack salsa 250g",        "valorSetup": "ROJO" },'#13#10 +
    '    { "codigo": "DOY-0301", "descripcion": "Doypack detergente 1kg",    "valorSetup": "VERDE" },'#13#10 +
    '    { "codigo": "FLM-0400", "descripcion": "Film snacks 40 micras",     "valorSetup": "NEGRO" },'#13#10 +
    '    { "codigo": "FLM-0401", "descripcion": "Film conserva 60 micras",   "valorSetup": "NEGRO" }'#13#10 +
    '  ]'#13#10 +
    '}');

  // --- Inyeccion de plastico ---------------------------------------------
  // El cambio de MOLDE es largo y define la secuencia.
  Sembrar('inyeccion-plastico',
    '{'#13#10 +
    '  "nombre": "Inyeccion de plastico",'#13#10 +
    '  "descripcion": "Maquinas de inyeccion. El cambio de molde es largo y manda en la secuencia.",'#13#10 +
    '  "sector": "Transformacion de plastico",'#13#10 +
    '  "atributoSetup": "Molde",'#13#10 +
    '  "unidad": "piezas",'#13#10 +
    '  "prefijoOrden": "OF",'#13#10 +
    '  "numOrdenes": 15,'#13#10 +
    '  "opsPorOrden": 3,'#13#10 +
    '  "pctPlanificado": 80,'#13#10 +
    '  "operaciones": ["INYECTAR", "DESBARBAR", "MONTAR", "EMBALAR"],'#13#10 +
    '  "clientes": ["AUTOMOCION LEVANTE", "ELECTRO HOGAR", "JARDIN VERDE", "MENAJE SUR", "JUGUETES ALFA"],'#13#10 +
    '  "centros": ['#13#10 +
    '    { "codigo": "DEMO-INY-150", "nombre": "Inyectora 150T", "maxLanes": 1, "setupMin": 120 },'#13#10 +
    '    { "codigo": "DEMO-INY-300", "nombre": "Inyectora 300T", "maxLanes": 1, "setupMin": 150 },'#13#10 +
    '    { "codigo": "DEMO-INY-500", "nombre": "Inyectora 500T", "maxLanes": 1, "setupMin": 180 },'#13#10 +
    '    { "codigo": "DEMO-ACAB",    "nombre": "Acabado",        "maxLanes": 3, "setupMin": 15 }'#13#10 +
    '  ],'#13#10 +
    '  "articulos": ['#13#10 +
    '    { "codigo": "PZA-1000", "descripcion": "Carcasa frontal",    "valorSetup": "MOLDE-A1" },'#13#10 +
    '    { "codigo": "PZA-1001", "descripcion": "Carcasa trasera",    "valorSetup": "MOLDE-A1" },'#13#10 +
    '    { "codigo": "PZA-2000", "descripcion": "Tapa contenedor",    "valorSetup": "MOLDE-B2" },'#13#10 +
    '    { "codigo": "PZA-2001", "descripcion": "Base contenedor",    "valorSetup": "MOLDE-B2" },'#13#10 +
    '    { "codigo": "PZA-3000", "descripcion": "Soporte tecnico",    "valorSetup": "MOLDE-C3" },'#13#10 +
    '    { "codigo": "PZA-4000", "descripcion": "Conjunto bisagra",   "valorSetup": "MOLDE-D4" },'#13#10 +
    '    { "codigo": "PZA-5000", "descripcion": "Maceta 30cm",        "valorSetup": "MOLDE-E5" },'#13#10 +
    '    { "codigo": "PZA-5001", "descripcion": "Plato maceta 30cm",  "valorSetup": "MOLDE-E5" }'#13#10 +
    '  ]'#13#10 +
    '}');

  // --- Mecanizado / taller (el comportamiento clasico de siempre) ---------
  Sembrar('mecanizado',
    '{'#13#10 +
    '  "nombre": "Mecanizado y taller",'#13#10 +
    '  "descripcion": "Taller con varias secciones y rutas largas. El cambio de utillaje marca el ritmo.",'#13#10 +
    '  "sector": "Metal",'#13#10 +
    '  "atributoSetup": "Utillaje",'#13#10 +
    '  "unidad": "piezas",'#13#10 +
    '  "prefijoOrden": "OF",'#13#10 +
    '  "numOrdenes": 12,'#13#10 +
    '  "opsPorOrden": 5,'#13#10 +
    '  "pctPlanificado": 80,'#13#10 +
    '  "operaciones": ["CORTAR", "MECANIZAR", "TALADRAR", "SOLDAR", "PINTAR", "EMBALAR"],'#13#10 +
    '  "clientes": ["INDUSTRIAS ROCA", "TALLERES MB", "MONTAJES NORTE", "FERRETERIA MAYOR", "OBRAS Y GRUAS"],'#13#10 +
    '  "centros": ['#13#10 +
    '    { "codigo": "DEMO-CNC1",  "nombre": "Centro CNC 1",  "maxLanes": 1, "setupMin": 45 },'#13#10 +
    '    { "codigo": "DEMO-CNC2",  "nombre": "Centro CNC 2",  "maxLanes": 1, "setupMin": 45 },'#13#10 +
    '    { "codigo": "DEMO-TORNO", "nombre": "Torneado",      "maxLanes": 2, "setupMin": 30 },'#13#10 +
    '    { "codigo": "DEMO-SOLD",  "nombre": "Soldadura",     "maxLanes": 2, "setupMin": 20 },'#13#10 +
    '    { "codigo": "DEMO-PINT",  "nombre": "Pintura",       "maxLanes": 1, "setupMin": 60 }'#13#10 +
    '  ],'#13#10 +
    '  "articulos": ['#13#10 +
    '    { "codigo": "ART-1001", "descripcion": "Pieza A grande",        "valorSetup": "UTIL-1" },'#13#10 +
    '    { "codigo": "ART-1002", "descripcion": "Pieza A pequena",       "valorSetup": "UTIL-1" },'#13#10 +
    '    { "codigo": "ART-2050", "descripcion": "Pieza B chasis",        "valorSetup": "UTIL-2" },'#13#10 +
    '    { "codigo": "ART-2051", "descripcion": "Pieza B soporte",       "valorSetup": "UTIL-2" },'#13#10 +
    '    { "codigo": "ART-3100", "descripcion": "Caja electronica",      "valorSetup": "UTIL-3" },'#13#10 +
    '    { "codigo": "ART-4200", "descripcion": "Conjunto C ensamblado", "valorSetup": "UTIL-4" }'#13#10 +
    '  ]'#13#10 +
    '}');
end;

end.
