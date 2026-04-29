unit uUserPrefs;

{
  Helper para leer/escribir preferencias de usuario en FS_PL_Cfg_UserPrefs.
  Clave compuesta: (CodigoEmpresa, UserId, Module, PrefKey).
  Todos los valores se almacenan como texto; el cliente hace Cast segun necesite.
}

interface

procedure SetPref(const AModule, AKey, AValue: string);
function  GetPref(const AModule, AKey: string; const ADefault: string = ''): string;
function  GetPrefInt(const AModule, AKey: string; const ADefault: Integer = 0): Integer;
function  GetPrefBool(const AModule, AKey: string; const ADefault: Boolean = False): Boolean;
procedure SetPrefInt(const AModule, AKey: string; AValue: Integer);
procedure SetPrefBool(const AModule, AKey: string; AValue: Boolean);

implementation

uses
  System.SysUtils, System.Classes,
  Data.Win.ADODB,
  uDMPlanner, uLogin;

function QStr(const S: string): string;
begin
  Result := 'N''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function CurrentUserLogin: string;
begin
  Result := CurrentSession.Login;
  if Result = '' then Result := '(anon)';
end;

procedure SetPref(const AModule, AKey, AValue: string);
var
  Q, Exec: TADOQuery;
  CE, UL: string;
begin
  CE := IntToStr(DMPlanner.CodigoEmpresa);
  UL := CurrentUserLogin;

  Q := TADOQuery.Create(nil);
  Exec := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT 1 FROM FS_PL_Cfg_UserPrefs WHERE CodigoEmpresa = ' + CE +
      '  AND UserId = ' + QStr(UL) +
      '  AND Module = ''' + AModule + '''' +
      '  AND PrefKey = ''' + AKey + '''';
    Q.Open;

    Exec.Connection := DMPlanner.ADOConnection;
    if Q.Eof then
      Exec.SQL.Text :=
        'INSERT INTO FS_PL_Cfg_UserPrefs ' +
        '(CodigoEmpresa, UserId, Module, PrefKey, PrefValue, FechaModificacion) VALUES (' +
        CE + ', ' + QStr(UL) + ', ''' + AModule + ''', ''' + AKey +
        ''', :Val, SYSUTCDATETIME())'
    else
      Exec.SQL.Text :=
        'UPDATE FS_PL_Cfg_UserPrefs SET PrefValue = :Val, ' +
        'FechaModificacion = SYSUTCDATETIME() ' +
        'WHERE CodigoEmpresa = ' + CE +
        '  AND UserId = ' + QStr(UL) +
        '  AND Module = ''' + AModule + '''' +
        '  AND PrefKey = ''' + AKey + '''';
    Exec.Parameters.ParamByName('Val').Value := AValue;
    Exec.ExecSQL;
  finally
    Q.Free;
    Exec.Free;
  end;
end;

function GetPref(const AModule, AKey, ADefault: string): string;
var
  Q: TADOQuery;
begin
  Result := ADefault;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT PrefValue FROM FS_PL_Cfg_UserPrefs ' +
      'WHERE CodigoEmpresa = ' + IntToStr(DMPlanner.CodigoEmpresa) +
      '  AND UserId = ' + QStr(CurrentUserLogin) +
      '  AND Module = ''' + AModule + '''' +
      '  AND PrefKey = ''' + AKey + '''';
    Q.Open;
    if not Q.Eof then
      if not Q.FieldByName('PrefValue').IsNull then
        Result := Q.FieldByName('PrefValue').AsString;
  finally
    Q.Free;
  end;
end;

function GetPrefInt(const AModule, AKey: string; const ADefault: Integer): Integer;
var
  S: string;
begin
  S := GetPref(AModule, AKey, IntToStr(ADefault));
  if not TryStrToInt(S, Result) then Result := ADefault;
end;

function GetPrefBool(const AModule, AKey: string; const ADefault: Boolean): Boolean;
var
  S: string;
begin
  if ADefault then S := '1' else S := '0';
  S := GetPref(AModule, AKey, S);
  Result := (S = '1') or SameText(S, 'true');
end;

procedure SetPrefInt(const AModule, AKey: string; AValue: Integer);
begin
  SetPref(AModule, AKey, IntToStr(AValue));
end;

procedure SetPrefBool(const AModule, AKey: string; AValue: Boolean);
begin
  if AValue then SetPref(AModule, AKey, '1')
  else SetPref(AModule, AKey, '0');
end;

end.
