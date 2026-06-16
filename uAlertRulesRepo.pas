unit uAlertRulesRepo;
// Repositorio de FS_PL_AlertRule: configuracion (activa + peso + umbral) de cada
// tipo de alerta de planificacion. El CATALOGO de tipos vive en uGanttAlertas
// (enum). Esta clase solo gestiona la config persistida, con patron seed+override:
//   - SeedDesdeCatalogo: inserta una fila por cada codigo del enum que no exista.
//   - LoadFromDB: carga las filas a un diccionario en memoria (lookup O(1)).
//   - Save: persiste una fila editada.
// El motor (uGanttAlertas.DetectarAlertas) consulta via un callback que delega
// en TryGet, asi no se acopla a la BD.
interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.Win.ADODB,
  uGanttAlertas;

type
  TAlertRuleRec = record
    Codigo: string;
    Activa: Boolean;
    Peso: Integer;      // 1..100
    Umbral: Integer;    // -1 = NULL (usar el del codigo)
    Orden: Integer;
  end;

  TAlertRulesRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    FReglas: TDictionary<string, TAlertRuleRec>;  // clave = Codigo
    procedure SeedDesdeCatalogo;
  public
    constructor Create(AConnection: TADOConnection);
    destructor Destroy; override;

    // Hace el seed de los codigos que falten y carga todo a memoria.
    procedure LoadFromDB(ACodigoEmpresa: SmallInt);

    // Lookup en memoria. Result=False si el codigo no esta cargado.
    function TryGet(const ACodigo: string; out ARule: TAlertRuleRec): Boolean;
    // Todas las reglas cargadas (para el form de configuracion).
    function GetAll: TArray<TAlertRuleRec>;
    // Persiste (UPDATE) una regla editada y refresca la copia en memoria.
    procedure Save(const ARule: TAlertRuleRec);

    // Callback listo para pasar a DetectarAlertas (delega en TryGet).
    function ConfigLookup: TAlertConfigLookup;
  end;

implementation

constructor TAlertRulesRepo.Create(AConnection: TADOConnection);
begin
  inherited Create;
  FConnection := AConnection;
  FReglas := TDictionary<string, TAlertRuleRec>.Create;
end;

destructor TAlertRulesRepo.Destroy;
begin
  FReglas.Free;
  inherited;
end;

procedure TAlertRulesRepo.SeedDesdeCatalogo;
var
  T: TAlertaTipo;
  Cmd: TADOCommand;
  cod: string;
begin
  if FConnection = nil then Exit;
  // Inserta una fila por cada tipo del enum que aun NO tenga config para esta
  // empresa. WHERE NOT EXISTS evita duplicar y respeta lo ya editado.
  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.ParamCheck := False;
    for T := Low(TAlertaTipo) to High(TAlertaTipo) do
    begin
      cod := CodigoDe(T);
      if cod = '' then Continue;
      Cmd.CommandText :=
        'IF NOT EXISTS (SELECT 1 FROM FS_PL_AlertRule WHERE CodigoEmpresa = ' +
        IntToStr(FCodigoEmpresa) + ' AND AlertCode = ''' + cod + ''') ' +
        'INSERT INTO FS_PL_AlertRule (CodigoEmpresa, AlertCode, Activa, Peso, ' +
        '  Umbral, Orden) VALUES (' +
        IntToStr(FCodigoEmpresa) + ', ''' + cod + ''', 1, ' +
        IntToStr(PesoDefectoDe(T)) + ', NULL, ' + IntToStr(Ord(T)) + ')';
      Cmd.Execute;
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TAlertRulesRepo.LoadFromDB(ACodigoEmpresa: SmallInt);
var
  Q: TADOQuery;
  R: TAlertRuleRec;
begin
  FCodigoEmpresa := ACodigoEmpresa;
  FReglas.Clear;
  if FConnection = nil then Exit;

  SeedDesdeCatalogo;  // asegura una fila por cada codigo del enum

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT AlertCode, Activa, Peso, Umbral, Orden ' +
      'FROM FS_PL_AlertRule WHERE CodigoEmpresa = :CE';
    Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
    Q.Open;
    while not Q.Eof do
    begin
      R.Codigo := Q.FieldByName('AlertCode').AsString;
      R.Activa := Q.FieldByName('Activa').AsBoolean;
      R.Peso   := Q.FieldByName('Peso').AsInteger;
      if Q.FieldByName('Umbral').IsNull then
        R.Umbral := -1
      else
        R.Umbral := Q.FieldByName('Umbral').AsInteger;
      R.Orden  := Q.FieldByName('Orden').AsInteger;
      FReglas.AddOrSetValue(R.Codigo, R);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TAlertRulesRepo.TryGet(const ACodigo: string;
  out ARule: TAlertRuleRec): Boolean;
begin
  Result := FReglas.TryGetValue(ACodigo, ARule);
end;

function TAlertRulesRepo.GetAll: TArray<TAlertRuleRec>;
begin
  Result := FReglas.Values.ToArray;
end;

procedure TAlertRulesRepo.Save(const ARule: TAlertRuleRec);
var
  Cmd: TADOCommand;
  umbralSql: string;
begin
  if FConnection = nil then Exit;
  if ARule.Umbral < 0 then umbralSql := 'NULL' else umbralSql := IntToStr(ARule.Umbral);

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.ParamCheck := False;
    Cmd.CommandText :=
      'UPDATE FS_PL_AlertRule SET Activa = ' + IntToStr(Ord(ARule.Activa)) +
      ', Peso = ' + IntToStr(ARule.Peso) +
      ', Umbral = ' + umbralSql +
      ', Orden = ' + IntToStr(ARule.Orden) +
      ', FechaModificacion = GETDATE() ' +
      'WHERE CodigoEmpresa = ' + IntToStr(FCodigoEmpresa) +
      ' AND AlertCode = ''' + ARule.Codigo + '''';
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
  FReglas.AddOrSetValue(ARule.Codigo, ARule);
end;

function TAlertRulesRepo.ConfigLookup: TAlertConfigLookup;
begin
  Result :=
    function(const ACodigo: string; out AActiva: Boolean;
      out APeso: Integer): Boolean
    var
      R: TAlertRuleRec;
    begin
      Result := FReglas.TryGetValue(ACodigo, R);
      if Result then
      begin
        AActiva := R.Activa;
        APeso := R.Peso;
      end
      else
      begin
        AActiva := True;
        APeso := 0;
      end;
    end;
end;

end.
