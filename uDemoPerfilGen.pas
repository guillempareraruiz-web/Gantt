unit uDemoPerfilGen;

{
  Generador de demostracion A PARTIR DE UN PERFIL.

  ---------------------------------------------------------------------------
  POR QUE ES UNA UNIDAD APARTE Y NO UN CAMBIO EN uGenerarNodosDemo
  ---------------------------------------------------------------------------

  El generador de siempre (uGenerarNodosDemo + uDemoPlanEngine) es de lo mas
  delicado del proyecto: cinco metodos de persistencia, hilo propio con su
  conexion, IDENTITY_INSERT, reencadenado de dependencias. Funciona y esta
  probado, y una demo comercial depende de el.

  Asi que no se toca. Esta unidad hace SOLO lo que el perfil aporta —crear los
  centros y los articulos con el vocabulario del cliente— y despues delega la
  generacion y la planificacion en el motor de siempre. Si algo falla aqui, el
  boton "Demo" clasico sigue intacto.

  ---------------------------------------------------------------------------
  QUE HACE, EN ORDEN
  ---------------------------------------------------------------------------

    1. Crea (o actualiza) los CENTROS del perfil con su capacidad real.
    2. Siembra las REGLAS DE TIEMPO DE CAMBIO de esas lineas, si se piden.
    3. Deja que el generador clasico cree las ordenes y las planifique.
    4. Reescribe el VOCABULARIO de los nodos generados: articulos, clientes y
       nombres de operacion salen del perfil, no de las constantes de taller.

  El paso 4 va al final a proposito: el motor de planificacion no mira el
  nombre del articulo para nada, asi que renombrar despues no altera el plan y
  evita tener que meter mano en el generador.
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,
  Data.Win.ADODB,
  uDemoPerfiles;

type
  TDemoPerfilResult = record
    Ok: Boolean;
    CentrosCreados: Integer;
    CentrosActualizados: Integer;
    ReglasSetup: Integer;
    NodosRenombrados: Integer;
    Mensaje: string;
  end;

// Prepara la planta segun el perfil: centros y reglas de setup. Se llama ANTES
// de generar los nodos, porque el generador reparte los trabajos entre los
// centros que encuentre.
function PrepararPlantaDemo(const AConn: TADOConnection; const ACE: Integer;
  const APerfil: TDemoPerfil; ACrearSetup: Boolean): TDemoPerfilResult;

// Aplica el vocabulario del perfil a los nodos ya generados de un proyecto.
// Se llama DESPUES de generar y planificar.
function AplicarVocabularioDemo(const AConn: TADOConnection;
  const ACE, AProjectId: Integer; const APerfil: TDemoPerfil): Integer;

implementation

uses
  uPlanLog;

// Escapa una cadena para SQL. Los perfiles los edita un humano a mano, asi que
// una comilla en un nombre de cliente es cuestion de tiempo.
function Q(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function PrepararPlantaDemo(const AConn: TADOConnection; const ACE: Integer;
  const APerfil: TDemoPerfil; ACrearSetup: Boolean): TDemoPerfilResult;
var
  Qy: TADOQuery;
  Cmd: TADOCommand;
  I, CentreId, EsSec: Integer;
begin
  Result := Default(TDemoPerfilResult);
  Result.Ok := False;

  if AConn = nil then
  begin
    Result.Mensaje := 'Sin conexion a la base de datos.';
    Exit;
  end;
  if Length(APerfil.Centros) = 0 then
  begin
    Result.Mensaje := 'El perfil no define ninguna linea.';
    Exit;
  end;

  Cmd := TADOCommand.Create(nil);
  Qy := TADOQuery.Create(nil);
  try
    Cmd.Connection := AConn;
    Qy.Connection := AConn;

    // --- 1. Centros -------------------------------------------------------
    // Se busca por CODIGO: si la linea ya existe (de una demo anterior o del
    // ERP real) se actualiza su capacidad en vez de duplicarla. Duplicar
    // centros ensuciaria el plan real del cliente, que es justo lo que el
    // modo demo debe evitar.
    for I := 0 to High(APerfil.Centros) do
    begin
      // MaxLanes = 1 significa linea SECUENCIAL: un trabajo detras de otro. Es
      // el caso que hace visible el tiempo de cambio, porque solo entre dos
      // trabajos consecutivos de la misma linea hay preparacion. Con lanes en
      // paralelo el hueco no se ve.
      EsSec := IfThen(APerfil.Centros[I].MaxLanes <= 1, 1, 0);

      Qy.Close;
      Qy.SQL.Text :=
        'SELECT CenterId FROM FS_PL_Center ' +
        'WHERE CodigoEmpresa = :CE AND CodigoCentro = :COD';
      Qy.Parameters.ParamByName('CE').Value := ACE;
      Qy.Parameters.ParamByName('COD').Value := APerfil.Centros[I].Codigo;
      Qy.Open;

      if not Qy.Eof then
      begin
        CentreId := Qy.FieldByName('CenterId').AsInteger;
        Qy.Close;
        Cmd.CommandText :=
          'UPDATE FS_PL_Center SET Titulo = ' + Q(APerfil.Centros[I].Nombre) +
          ', MaxLanes = ' + IntToStr(Max(1, APerfil.Centros[I].MaxLanes)) +
          ', EsSecuencial = ' + IntToStr(EsSec) +
          ', Visible = 1, Habilitado = 1' +
          ' WHERE CodigoEmpresa = ' + IntToStr(ACE) +
          ' AND CenterId = ' + IntToStr(CentreId);
        Cmd.Execute;
        Inc(Result.CentrosActualizados);
      end
      else
      begin
        Qy.Close;
        Cmd.CommandText :=
          'INSERT INTO FS_PL_Center ' +
          '  (CodigoEmpresa, CodigoCentro, Titulo, Subtitulo, EsSecuencial, ' +
          '   MaxLanes, Orden, Visible, Habilitado) ' +
          'VALUES (' + IntToStr(ACE) + ', ' +
          Q(APerfil.Centros[I].Codigo) + ', ' +
          Q(APerfil.Centros[I].Nombre) + ', ' +
          Q(APerfil.NombreAtributoSetup + ': ' +
            IntToStr(APerfil.Centros[I].SetupMin) + ' min') + ', ' +
          IntToStr(EsSec) + ', ' +
          IntToStr(Max(1, APerfil.Centros[I].MaxLanes)) + ', ' +
          IntToStr(I) + ', 1, 1)';
        Cmd.Execute;
        Inc(Result.CentrosCreados);
      end;
    end;

    // --- 2. Reglas de tiempo de cambio ------------------------------------
    // Sin esto, las franjas de setup del Gantt no aparecen y la demo pierde
    // justo el argumento que mas pesa en una planta con series largas.
    //
    // La regla se pone sobre CodigoArticulo: dos trabajos del mismo articulo
    // no pagan cambio; en cuanto cambia, si. Es una simplificacion honesta
    // del "cambio de formato" —en una planta real la regla iria sobre un campo
    // propio (Formato, Molde), y eso es exactamente lo que se ensena en el
    // editor de reglas durante la visita.
    if ACrearSetup then
    begin
      try
        // Solo se borran las reglas de las lineas de ESTE perfil, no todas:
        // si el cliente ya tenia reglas propias, se respetan.
        for I := 0 to High(APerfil.Centros) do
        begin
          if APerfil.Centros[I].SetupMin <= 0 then Continue;

          Cmd.CommandText :=
            'DELETE FROM FS_PL_SetupRule ' +
            'WHERE CodigoEmpresa = ' + IntToStr(ACE) +
            ' AND CentreCode = ' + Q(APerfil.Centros[I].Codigo);
          Cmd.Execute;

          Cmd.CommandText :=
            'INSERT INTO FS_PL_SetupRule ' +
            '  (CodigoEmpresa, AttrName, SetupMin, CentreCode, Enabled) ' +
            'VALUES (' + IntToStr(ACE) + ', ' + Q('CodigoArticulo') + ', ' +
            IntToStr(APerfil.Centros[I].SetupMin) + ', ' +
            Q(APerfil.Centros[I].Codigo) + ', 1)';
          Cmd.Execute;
          Inc(Result.ReglasSetup);
        end;
      except
        on E: Exception do
          // La tabla de reglas (V071) puede no estar aplicada. No es motivo
          // para tumbar la demo entera: se avisa y se sigue sin setup.
          Result.Mensaje := 'Las reglas de cambio no se han podido crear (' +
            E.Message + '). La demo funciona igual, pero sin las franjas de ' +
            'tiempo de cambio en el plan.';
      end;
    end;

    Result.Ok := True;
  finally
    Qy.Free;
    Cmd.Free;
  end;
end;

function AplicarVocabularioDemo(const AConn: TADOConnection;
  const ACE, AProjectId: Integer; const APerfil: TDemoPerfil): Integer;
var
  Qy: TADOQuery;
  Cmd: TADOCommand;
  Ids: TList<Integer>;
  I, K, NumArt, NumCli, NumOps, OpsLote: Integer;
  Sql: TStringBuilder;
begin
  Result := 0;
  if AConn = nil then Exit;

  NumArt := Length(APerfil.Articulos);
  NumCli := Length(APerfil.Clientes);
  NumOps := Length(APerfil.Operaciones);
  if NumArt = 0 then Exit;

  Ids := TList<Integer>.Create;
  Qy := TADOQuery.Create(nil);
  Cmd := TADOCommand.Create(nil);
  Sql := TStringBuilder.Create;
  try
    Qy.Connection := AConn;
    Cmd.Connection := AConn;

    // Los nodos EN ORDEN DE RUTA dentro de cada orden: hace falta para que el
    // nombre de la operacion siga la secuencia del perfil (IMPRIMIR va antes
    // que ACABADO) en vez de salir al azar.
    Qy.SQL.Text :=
      'SELECT n.NodeId FROM FS_PL_Node n ' +
      'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
      'ORDER BY n.NodeId';
    Qy.Parameters.ParamByName('CE').Value := ACE;
    Qy.Parameters.ParamByName('PID').Value := AProjectId;
    Qy.Open;
    while not Qy.Eof do
    begin
      Ids.Add(Qy.FieldByName('NodeId').AsInteger);
      Qy.Next;
    end;
    Qy.Close;

    if Ids.Count = 0 then Exit;

    // Cuantos nodos forman un LOTE (una OT): el generador crea 3 lotes por
    // orden, cada uno con OpsPorOrden operaciones. Los nodos vienen ordenados
    // por NodeId, que es el orden en que se crearon, asi que agrupar de
    // OpsPorOrden en OpsPorOrden reproduce los lotes.
    OpsLote := Max(1, APerfil.OpsPorOrden);

    for I := 0 to Ids.Count - 1 do
    begin
      // Un articulo POR LOTE, no por operacion: las operaciones de un mismo
      // lote comparten articulo (es lo realista) y ademas hace visible en el
      // Gantt el agrupamiento por formato, que es lo que se quiere ensenar.
      K := (I div OpsLote) mod NumArt;

      Sql.Clear;
      Sql.Append('UPDATE FS_PL_NodeData SET ');
      Sql.Append('CodigoArticulo = ').Append(Q(APerfil.Articulos[K].Codigo));
      Sql.Append(', DescripcionArticulo = ')
         .Append(Q(APerfil.Articulos[K].Descripcion));
      if NumCli > 0 then
        Sql.Append(', CodigoCliente = ')
           .Append(Q(APerfil.Clientes[(I div OpsLote) mod NumCli]));
      Sql.Append(' WHERE CodigoEmpresa = ').Append(IntToStr(ACE));
      Sql.Append(' AND NodeId = ').Append(IntToStr(Ids[I]));

      Cmd.CommandText := Sql.ToString;
      Cmd.Execute;

      // Nombre de la operacion: la posicion DENTRO del lote da el paso de la
      // ruta, de modo que IMPRIMIR sale antes que ACABADO.
      if NumOps > 0 then
      begin
        Cmd.CommandText :=
          'UPDATE FS_PL_Node SET Caption = ' +
          Q(APerfil.Operaciones[(I mod OpsLote) mod NumOps] +
            ' ' + APerfil.Articulos[K].Codigo) +
          ' WHERE CodigoEmpresa = ' + IntToStr(ACE) +
          ' AND NodeId = ' + IntToStr(Ids[I]);
        Cmd.Execute;
      end;

      Inc(Result);
    end;

    PlanLog.Linea('Demo perfil "%s": %d nodos renombrados',
      [APerfil.Nombre, Result]);
  finally
    Sql.Free;
    Cmd.Free;
    Qy.Free;
    Ids.Free;
  end;
end;

end.
