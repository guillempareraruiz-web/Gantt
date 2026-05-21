unit uUserPreferencesRepo;

{
  Repo generico para persistir preferencias UI por (Empresa, Usuario, Pantalla).

  Cada pantalla decide su propio esquema dentro del JSON. El repo solo
  guarda y lee strings.

  Uso tipico desde un form:

    // En FormCreate, despues de inicializar controles:
    Js := DMPlanner.UserPrefs.Load('HeatmapCargaCentro');
    if Js <> '' then RestoreFromJson(Js);

    // Al cambiar cualquier control (OnChange):
    if not FLoadingPrefs then
      DMPlanner.UserPrefs.Save('HeatmapCargaCentro', BuildJson);

  Robustez: si no hay conexion o no hay UserId valido, Load devuelve ''
  y Save es no-op (la pantalla simplemente no recuerda nada esa sesion).
}

interface

uses
  System.SysUtils, Data.Win.ADODB;

type
  TUserPreferencesRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    function GetUserId: Integer;
  public
    constructor Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt);
    property CodigoEmpresa: SmallInt read FCodigoEmpresa write FCodigoEmpresa;

    // Devuelve el JSON guardado para esa pantalla, o '' si no hay nada.
    function Load(const AScreenKey: string): string;

    // Guarda (upsert) el JSON para esa pantalla.
    procedure Save(const AScreenKey, AJson: string);

    // Borra la preferencia (util para "restablecer por defecto").
    procedure Delete(const AScreenKey: string);
  end;

implementation

uses
  uLogin;

constructor TUserPreferencesRepo.Create(AConnection: TADOConnection;
  ACodigoEmpresa: SmallInt);
begin
  inherited Create;
  FConnection := AConnection;
  FCodigoEmpresa := ACodigoEmpresa;
end;

function TUserPreferencesRepo.GetUserId: Integer;
begin
  Result := CurrentSession.UserId;
end;

function TUserPreferencesRepo.Load(const AScreenKey: string): string;
var
  Q: TADOQuery;
  Uid: Integer;
begin
  Result := '';
  if (FConnection = nil) or (not FConnection.Connected) then Exit;
  Uid := GetUserId;
  if Uid <= 0 then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    try
      Q.SQL.Text :=
        'SELECT PreferenceJson FROM FS_PL_UserPreference ' +
        'WHERE CodigoEmpresa = :CE AND UserId = :UID AND ScreenKey = :SK';
      Q.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('UID').Value := Uid;
      Q.Parameters.ParamByName('SK').Value := AScreenKey;
      Q.Open;
      if not Q.Eof then
        Result := Q.FieldByName('PreferenceJson').AsString;
    except
      // Si la tabla no existe (V035 no aplicada), comportamos como "sin pref"
    end;
  finally
    Q.Free;
  end;
end;

procedure TUserPreferencesRepo.Save(const AScreenKey, AJson: string);
var
  Cmd: TADOCommand;
  Uid: Integer;
begin
  if (FConnection = nil) or (not FConnection.Connected) then Exit;
  Uid := GetUserId;
  if Uid <= 0 then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.ParamCheck := True;
    try
      // Upsert atomico: UPDATE primero, INSERT si no afecto filas.
      Cmd.CommandText :=
        'UPDATE FS_PL_UserPreference SET ' +
        '  PreferenceJson = :PJ, UpdatedAt = SYSUTCDATETIME() ' +
        'WHERE CodigoEmpresa = :CE AND UserId = :UID AND ScreenKey = :SK; ' +
        'IF @@ROWCOUNT = 0 ' +
        '  INSERT INTO FS_PL_UserPreference ' +
        '    (CodigoEmpresa, UserId, ScreenKey, PreferenceJson) ' +
        '  VALUES (:CE2, :UID2, :SK2, :PJ2);';
      Cmd.Parameters.ParamByName('PJ').Value := AJson;
      Cmd.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Cmd.Parameters.ParamByName('UID').Value := Uid;
      Cmd.Parameters.ParamByName('SK').Value := AScreenKey;
      Cmd.Parameters.ParamByName('CE2').Value := FCodigoEmpresa;
      Cmd.Parameters.ParamByName('UID2').Value := Uid;
      Cmd.Parameters.ParamByName('SK2').Value := AScreenKey;
      Cmd.Parameters.ParamByName('PJ2').Value := AJson;
      Cmd.Execute;
    except
      // Silencioso: una preferencia que no se guarda no debe romper la UI.
    end;
  finally
    Cmd.Free;
  end;
end;

procedure TUserPreferencesRepo.Delete(const AScreenKey: string);
var
  Cmd: TADOCommand;
  Uid: Integer;
begin
  if (FConnection = nil) or (not FConnection.Connected) then Exit;
  Uid := GetUserId;
  if Uid <= 0 then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    try
      Cmd.CommandText :=
        'DELETE FROM FS_PL_UserPreference ' +
        'WHERE CodigoEmpresa = :CE AND UserId = :UID AND ScreenKey = :SK';
      Cmd.Parameters.ParamByName('CE').Value := FCodigoEmpresa;
      Cmd.Parameters.ParamByName('UID').Value := Uid;
      Cmd.Parameters.ParamByName('SK').Value := AScreenKey;
      Cmd.Execute;
    except
    end;
  finally
    Cmd.Free;
  end;
end;

end.
