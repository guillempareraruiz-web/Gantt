unit uCardLayoutSetRepo;

(*
  Persistencia dels Card Layout Sets a BD (FS_PL_CardLayoutSet, V046).
  Cada fila es un set complet (6 categories) en JSON.
  UserId = 0 -> set comu disponible per a tots els usuaris.

  La logica de seleccio "quin set carregar" la fa el caller:
    1) preferent: l'usuari pot tenir mes d'un set privat. Per defecte
       carreguem el seu mes recent (Privat, ORDER BY FechaModificacion DESC).
    2) si no en te cap, carreguem el primer Comu disponible.
    3) si no n'hi ha cap, retornem el DefaultCardLayoutSet hardcoded.

  L'editor exposa al combo tots els que pot veure l'usuari (els seus + els
  comuns), i en triar Aceptar/Guardar decideix si actualitzar el set actual
  o crear-ne un de nou (privat o comu).
*)

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.Win.ADODB,
  uCardLayout;

type
  TCardLayoutSetMeta = record
    SetId: Integer;
    UserId: Integer;
    Nombre: string;
    IsCommon: Boolean;       // True si UserId = 0
    IsSystem: Boolean;       // True nomes pel set "Por defecto (sistema)"
    CreadoPor: string;       // Login de l'usuari creador (o 'Sistema')
    FechaModificacion: TDateTime;
  end;

  TCardLayoutSetRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    function GetCurrentUserId: Integer;
  public
    constructor Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt);
    property CodigoEmpresa: SmallInt read FCodigoEmpresa write FCodigoEmpresa;

    // Llistar tots els sets visibles per a l'usuari actual: els seus + els comuns
    function ListVisible: TArray<TCardLayoutSetMeta>;

    // Carrega 1 set per id
    function Load(ASetId: Integer; out ASet: TCardLayoutSet): Boolean;

    // Carrega l'actiu segons regla: privat mes recent -> comu mes recent ->
    // DefaultCardLayoutSet hardcoded. Retorna SetId carregat (-1 si default).
    function LoadActive(out ASet: TCardLayoutSet): Integer; overload;
    function LoadActive(out ASet: TCardLayoutSet; out ANombre: string;
      out AIsCommon: Boolean): Integer; overload;

    // Crea un set nou (UserId=0 si AIsCommon=True, sino el de l'usuari actual).
    // Retorna SetId creat (-1 si error).
    function Insert(const ANombre: string; AIsCommon: Boolean;
      const ASet: TCardLayoutSet): Integer;

    // Actualitza un set existent
    procedure UpdateSet(ASetId: Integer; const ANombre: string;
      const ASet: TCardLayoutSet);

    procedure Delete(ASetId: Integer);

    // Canvia scope del set: UserId=0 (comu) o UserId=usuari actual (privat).
    procedure ChangeScope(ASetId: Integer; AIsCommon: Boolean);

    // Sembra un set comu "Por defecto" si la taula encara no en te cap.
    // Pensat per cridar-se un cop al Connect, despres d'aplicar migracions.
    procedure SeedDefaultIfEmpty;

    // Set actiu per a l'usuari, persistit a FS_PL_UserPreference (ScreenKey
    // 'ActiveCardLayoutSetId'). Si no hi ha valor o el set ja no existeix,
    // s'aplica la regla per defecte (privat mes recent -> comu mes recent).
    function GetActiveSetId: Integer;
    procedure SetActiveSetId(ASetId: Integer);
  end;

implementation

uses
  System.JSON, uLogin, uUserPreferencesRepo;

const
  PrefKey_ActiveCardLayoutSet = 'ActiveCardLayoutSetId';

constructor TCardLayoutSetRepo.Create(AConnection: TADOConnection;
  ACodigoEmpresa: SmallInt);
begin
  inherited Create;
  FConnection := AConnection;
  FCodigoEmpresa := ACodigoEmpresa;
end;

function TCardLayoutSetRepo.GetCurrentUserId: Integer;
begin
  try
    Result := CurrentSession.UserId;
  except
    Result := 0;
  end;
end;

function TCardLayoutSetRepo.ListVisible: TArray<TCardLayoutSetMeta>;
var
  Q: TADOQuery;
  Lst: TList<TCardLayoutSetMeta>;
  M: TCardLayoutSetMeta;
  Uid: Integer;
begin
  Result := nil;
  if FConnection = nil then Exit;
  Uid := GetCurrentUserId;

  Lst := TList<TCardLayoutSetMeta>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT s.SetId, s.UserId, s.Nombre, s.IsCommon, s.IsSystem, ' +
      '       s.FechaModificacion, ' +
      '       CASE WHEN s.IsSystem = 1 THEN N''Sistema'' ' +
      '            WHEN u.Login IS NOT NULL THEN u.Login ' +
      '            WHEN s.UserId = 0 THEN N''(com'#250'n)'' ' +
      '            ELSE N''?'' END AS CreadoPor ' +
      'FROM FS_PL_CardLayoutSet s ' +
      'LEFT JOIN FS_PL_User u ON u.CodigoEmpresa = s.CodigoEmpresa AND u.UserId = s.UserId ' +
      'WHERE s.CodigoEmpresa = :Emp AND (s.UserId = :Uid OR s.UserId = 0) ' +
      'ORDER BY s.IsSystem DESC, s.IsCommon ASC, s.FechaModificacion DESC';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Uid').Value := Uid;
    Q.Open;
    while not Q.Eof do
    begin
      M.SetId := Q.FieldByName('SetId').AsInteger;
      M.UserId := Q.FieldByName('UserId').AsInteger;
      M.Nombre := Q.FieldByName('Nombre').AsString;
      M.IsCommon := Q.FieldByName('IsCommon').AsBoolean;
      M.IsSystem := Q.FieldByName('IsSystem').AsBoolean;
      M.CreadoPor := Q.FieldByName('CreadoPor').AsString;
      M.FechaModificacion := Q.FieldByName('FechaModificacion').AsDateTime;
      Lst.Add(M);
      Q.Next;
    end;
    Result := Lst.ToArray;
  finally
    Q.Free;
    Lst.Free;
  end;
end;

function TCardLayoutSetRepo.Load(ASetId: Integer;
  out ASet: TCardLayoutSet): Boolean;
var
  Q: TADOQuery;
  Json: string;
  Obj: TJSONObject;
begin
  Result := False;
  ASet := DefaultCardLayoutSet;
  if (FConnection = nil) or (ASetId < 0) then Exit;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT SetJson FROM FS_PL_CardLayoutSet ' +
      'WHERE CodigoEmpresa = :Emp AND SetId = :Sid';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Sid').Value := ASetId;
    Q.Open;
    if Q.Eof then Exit;
    Json := Q.FieldByName('SetJson').AsString;
  finally
    Q.Free;
  end;

  if Trim(Json) = '' then Exit;
  Obj := TJSONObject.ParseJSONValue(Json) as TJSONObject;
  if Obj = nil then Exit;
  try
    ASet := JSONToCardLayoutSet(Obj);
    Result := True;
  finally
    Obj.Free;
  end;
end;

function TCardLayoutSetRepo.LoadActive(out ASet: TCardLayoutSet): Integer;
var
  Dummy: string;
  Dum2: Boolean;
begin
  Result := LoadActive(ASet, Dummy, Dum2);
end;

function TCardLayoutSetRepo.LoadActive(out ASet: TCardLayoutSet;
  out ANombre: string; out AIsCommon: Boolean): Integer;
var
  Q: TADOQuery;
  Uid, ActiveId: Integer;
begin
  Result := -1;
  ASet := DefaultCardLayoutSet;
  ANombre := '';
  AIsCommon := False;
  if FConnection = nil then Exit;
  Uid := GetCurrentUserId;

  // Si l'usuari te SetId actiu persistit, intentem carregar-lo
  ActiveId := GetActiveSetId;
  if ActiveId > 0 then
  begin
    Q := TADOQuery.Create(nil);
    try
      try
        Q.Connection := FConnection;
        Q.SQL.Text :=
          'SELECT Nombre, UserId FROM FS_PL_CardLayoutSet ' +
          'WHERE CodigoEmpresa = :Emp AND SetId = :Sid ' +
          '  AND (UserId = :Uid OR UserId = 0)';
        Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
        Q.Parameters.ParamByName('Sid').Value := ActiveId;
        Q.Parameters.ParamByName('Uid').Value := Uid;
        Q.Open;
        if not Q.Eof then
        begin
          Result := ActiveId;
          ANombre := Q.FieldByName('Nombre').AsString;
          AIsCommon := Q.FieldByName('UserId').AsInteger = 0;
          Q.Close;
          Load(Result, ASet);
          Exit;
        end;
      except
        // Si peta, caiem a la regla per defecte
      end;
    finally
      Q.Free;
    end;
  end;

  // Defensiu: si la taula no existeix (migracio V046 pendent) caiem al default
  Q := TADOQuery.Create(nil);
  try
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT TOP 1 SetId, Nombre FROM FS_PL_CardLayoutSet ' +
        'WHERE CodigoEmpresa = :Emp AND UserId = :Uid ' +
        'ORDER BY FechaModificacion DESC';
      Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
      Q.Parameters.ParamByName('Uid').Value := Uid;
      Q.Open;
      if not Q.Eof then
      begin
        Result := Q.FieldByName('SetId').AsInteger;
        ANombre := Q.FieldByName('Nombre').AsString;
        AIsCommon := False;
        Q.Close;
        Load(Result, ASet);
        SetActiveSetId(Result);   // persisteix com a actiu
        Exit;
      end;

      // Si no -> primer comu
      Q.Close;
      Q.SQL.Text :=
        'SELECT TOP 1 SetId, Nombre FROM FS_PL_CardLayoutSet ' +
        'WHERE CodigoEmpresa = :Emp AND UserId = 0 ' +
        'ORDER BY FechaModificacion DESC';
      Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
      Q.Open;
      if not Q.Eof then
      begin
        Result := Q.FieldByName('SetId').AsInteger;
        ANombre := Q.FieldByName('Nombre').AsString;
        AIsCommon := True;
        Q.Close;
        Load(Result, ASet);
        SetActiveSetId(Result);   // persisteix com a actiu
      end;
    except
      // Taula inexistent / problema BD -> default
      Result := -1;
      ASet := DefaultCardLayoutSet;
    end;
  finally
    Q.Free;
  end;
end;

function TCardLayoutSetRepo.Insert(const ANombre: string;
  AIsCommon: Boolean; const ASet: TCardLayoutSet): Integer;
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  Uid, TargetUid: Integer;
  Obj: TJSONObject;
  Json: string;
begin
  Result := -1;
  if FConnection = nil then Exit;
  if AIsCommon then
    TargetUid := 0
  else
  begin
    Uid := GetCurrentUserId;
    if Uid <= 0 then Exit;  // no hi ha usuari -> no podem crear-ne un de privat
    TargetUid := Uid;
  end;

  Obj := CardLayoutSetToJSON(ASet);
  try
    Json := Obj.ToJSON;
  finally
    Obj.Free;
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_CardLayoutSet ' +
      '  (CodigoEmpresa, UserId, Nombre, SetJson) ' +
      'VALUES (:Emp, :Uid, :Nombre, :Json)';
    Cmd.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Cmd.Parameters.ParamByName('Uid').Value := TargetUid;
    Cmd.Parameters.ParamByName('Nombre').Value := ANombre;
    Cmd.Parameters.ParamByName('Json').Value := Json;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT MAX(SetId) AS NewId FROM FS_PL_CardLayoutSet ' +
      'WHERE CodigoEmpresa = :Emp AND UserId = :Uid';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Uid').Value := TargetUid;
    Q.Open;
    if not Q.Eof then Result := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TCardLayoutSetRepo.UpdateSet(ASetId: Integer; const ANombre: string;
  const ASet: TCardLayoutSet);
var
  Cmd: TADOCommand;
  Obj: TJSONObject;
  Json: string;
begin
  if FConnection = nil then Exit;
  if ASetId < 0 then Exit;

  Obj := CardLayoutSetToJSON(ASet);
  try
    Json := Obj.ToJSON;
  finally
    Obj.Free;
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_CardLayoutSet SET ' +
      '  Nombre = :Nombre, SetJson = :Json, FechaModificacion = GETDATE() ' +
      'WHERE CodigoEmpresa = :Emp AND SetId = :Sid';
    Cmd.Parameters.ParamByName('Nombre').Value := ANombre;
    Cmd.Parameters.ParamByName('Json').Value := Json;
    Cmd.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Cmd.Parameters.ParamByName('Sid').Value := ASetId;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

function TCardLayoutSetRepo.GetActiveSetId: Integer;
var
  Prefs: TUserPreferencesRepo;
  S: string;
begin
  Result := -1;
  if FConnection = nil then Exit;
  Prefs := TUserPreferencesRepo.Create(FConnection, FCodigoEmpresa);
  try
    S := Prefs.Load(PrefKey_ActiveCardLayoutSet);
  finally
    Prefs.Free;
  end;
  if Trim(S) = '' then Exit;
  Result := StrToIntDef(S, -1);
end;

procedure TCardLayoutSetRepo.SetActiveSetId(ASetId: Integer);
var
  Prefs: TUserPreferencesRepo;
begin
  if FConnection = nil then Exit;
  Prefs := TUserPreferencesRepo.Create(FConnection, FCodigoEmpresa);
  try
    Prefs.Save(PrefKey_ActiveCardLayoutSet, IntToStr(ASetId));
  finally
    Prefs.Free;
  end;
end;

procedure TCardLayoutSetRepo.SeedDefaultIfEmpty;
var
  Q: TADOQuery;
  Cmd: TADOCommand;
  Cnt: Integer;
  Obj: TJSONObject;
  Json: string;
begin
  if FConnection = nil then Exit;

  Cnt := -1;
  Q := TADOQuery.Create(nil);
  try
    try
      Q.Connection := FConnection;
      // Comptem nomes els de sistema. Si no n'hi ha, el sembrem.
      Q.SQL.Text :=
        'SELECT COUNT(*) AS N FROM FS_PL_CardLayoutSet ' +
        'WHERE CodigoEmpresa = :Emp AND IsSystem = 1';
      Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
      Q.Open;
      if not Q.Eof then Cnt := Q.FieldByName('N').AsInteger;
    except
      Exit;
    end;
  finally
    Q.Free;
  end;

  if Cnt > 0 then Exit;

  Obj := CardLayoutSetToJSON(DefaultCardLayoutSet);
  try
    Json := Obj.ToJSON;
  finally
    Obj.Free;
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_CardLayoutSet ' +
      '  (CodigoEmpresa, UserId, Nombre, IsSystem, SetJson) ' +
      'VALUES (:Emp, 0, N''Por defecto (sistema)'', 1, :Json)';
    Cmd.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Cmd.Parameters.ParamByName('Json').Value := Json;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TCardLayoutSetRepo.ChangeScope(ASetId: Integer; AIsCommon: Boolean);
var
  Cmd: TADOCommand;
  TargetUid, Uid: Integer;
begin
  if FConnection = nil then Exit;
  if ASetId < 0 then Exit;
  if AIsCommon then
    TargetUid := 0
  else
  begin
    Uid := GetCurrentUserId;
    if Uid <= 0 then Exit;
    TargetUid := Uid;
  end;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_CardLayoutSet SET UserId = :Uid, FechaModificacion = GETDATE() ' +
      'WHERE CodigoEmpresa = :Emp AND SetId = :Sid';
    Cmd.Parameters.ParamByName('Uid').Value := TargetUid;
    Cmd.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Cmd.Parameters.ParamByName('Sid').Value := ASetId;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TCardLayoutSetRepo.Delete(ASetId: Integer);
var
  Cmd: TADOCommand;
begin
  if FConnection = nil then Exit;
  if ASetId < 0 then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_CardLayoutSet ' +
      'WHERE CodigoEmpresa = :Emp AND SetId = :Sid';
    Cmd.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Cmd.Parameters.ParamByName('Sid').Value := ASetId;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

end.
