unit uAppConfig;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.IniFiles,
  System.NetEncoding, System.DateUtils;

type
  TDBConfig = record
    Server: string;
    Database: string;
    WindowsAuth: Boolean;
    UserName: string;
    Password: string;
    function IsValid: Boolean;
  end;

  TErpSage200Config = record
    Server: string;
    Database: string;
    WindowsAuth: Boolean;
    UserName: string;
    Password: string;
    GrupoEmpresa: string;
    CodigoEmpresa: string;
    Ejercicio: Integer;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    IncluirFinalizadas: Boolean;
    function IsValid: Boolean;
  end;

function GetConfigFilePath: string;
function ConfigFileExists: Boolean;
function LoadDBConfig: TDBConfig;
procedure SaveDBConfig(const ACfg: TDBConfig);

function LoadErpActivo: string;
procedure SaveErpActivo(const ACodigo: string);

function LoadErpSage200Config: TErpSage200Config;
procedure SaveErpSage200Config(const ACfg: TErpSage200Config);

implementation

const
  INI_FILENAME       = 'FSPlanner2026.ini';
  SECTION_DB         = 'Database';
  SECTION_ERP        = 'Erp';
  SECTION_ERP_SAGE200 = 'ErpSage200';
  XOR_KEY            = 'FS#Planner@2026!Key';

function GetConfigFilePath: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), INI_FILENAME);
end;

function ConfigFileExists: Boolean;
begin
  Result := TFile.Exists(GetConfigFilePath);
end;

function ObfuscateString(const S: string): string;
var
  Bytes: TBytes;
  I: Integer;
  KeyLen: Integer;
begin
  if S = '' then Exit('');
  Bytes := TEncoding.UTF8.GetBytes(S);
  KeyLen := Length(XOR_KEY);
  for I := 0 to High(Bytes) do
    Bytes[I] := Bytes[I] xor Byte(XOR_KEY[(I mod KeyLen) + 1]);
  Result := TNetEncoding.Base64.EncodeBytesToString(Bytes);
end;

function DeobfuscateString(const S: string): string;
var
  Bytes: TBytes;
  I: Integer;
  KeyLen: Integer;
begin
  if S = '' then Exit('');
  try
    Bytes := TNetEncoding.Base64.DecodeStringToBytes(S);
    KeyLen := Length(XOR_KEY);
    for I := 0 to High(Bytes) do
      Bytes[I] := Bytes[I] xor Byte(XOR_KEY[(I mod KeyLen) + 1]);
    Result := TEncoding.UTF8.GetString(Bytes);
  except
    Result := '';
  end;
end;

{ TDBConfig }

function TDBConfig.IsValid: Boolean;
begin
  Result := (Trim(Server) <> '') and (Trim(Database) <> '');
  if Result and (not WindowsAuth) then
    Result := Trim(UserName) <> '';
end;

{ TErpSage200Config }

function TErpSage200Config.IsValid: Boolean;
begin
  Result := (Trim(Server) <> '') and (Trim(Database) <> '');
  if Result and (not WindowsAuth) then
    Result := Trim(UserName) <> '';
end;

function LoadDBConfig: TDBConfig;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetConfigFilePath);
  try
    Result.Server      := Ini.ReadString(SECTION_DB, 'Server', '');
    Result.Database    := Ini.ReadString(SECTION_DB, 'Database', '');
    Result.WindowsAuth := Ini.ReadBool  (SECTION_DB, 'WindowsAuth', True);
    Result.UserName    := Ini.ReadString(SECTION_DB, 'UserName', '');
    Result.Password    := DeobfuscateString(Ini.ReadString(SECTION_DB, 'Password', ''));
  finally
    Ini.Free;
  end;
end;

procedure SaveDBConfig(const ACfg: TDBConfig);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetConfigFilePath);
  try
    Ini.WriteString(SECTION_DB, 'Server',      ACfg.Server);
    Ini.WriteString(SECTION_DB, 'Database',    ACfg.Database);
    Ini.WriteBool  (SECTION_DB, 'WindowsAuth', ACfg.WindowsAuth);
    Ini.WriteString(SECTION_DB, 'UserName',    ACfg.UserName);
    if ACfg.WindowsAuth then
      Ini.WriteString(SECTION_DB, 'Password', '')
    else
      Ini.WriteString(SECTION_DB, 'Password', ObfuscateString(ACfg.Password));
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

function LoadErpActivo: string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetConfigFilePath);
  try
    Result := Ini.ReadString(SECTION_ERP, 'Activo', 'Sage200');
  finally
    Ini.Free;
  end;
end;

procedure SaveErpActivo(const ACodigo: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetConfigFilePath);
  try
    Ini.WriteString(SECTION_ERP, 'Activo', ACodigo);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

function LoadErpSage200Config: TErpSage200Config;
var
  Ini: TIniFile;
  S: string;
begin
  Ini := TIniFile.Create(GetConfigFilePath);
  try
    Result.Server             := Ini.ReadString (SECTION_ERP_SAGE200, 'Server', '');
    Result.Database           := Ini.ReadString (SECTION_ERP_SAGE200, 'Database', '');
    Result.WindowsAuth        := Ini.ReadBool   (SECTION_ERP_SAGE200, 'WindowsAuth', True);
    Result.UserName           := Ini.ReadString (SECTION_ERP_SAGE200, 'UserName', '');
    Result.Password           := DeobfuscateString(Ini.ReadString(SECTION_ERP_SAGE200, 'Password', ''));
    Result.GrupoEmpresa       := Ini.ReadString (SECTION_ERP_SAGE200, 'GrupoEmpresa', '');
    Result.CodigoEmpresa      := Ini.ReadString (SECTION_ERP_SAGE200, 'CodigoEmpresa', '');
    Result.Ejercicio          := Ini.ReadInteger(SECTION_ERP_SAGE200, 'Ejercicio', YearOf(Now));
    S := Ini.ReadString(SECTION_ERP_SAGE200, 'FechaDesde', '');
    if (S = '') or not TryISO8601ToDate(S, Result.FechaDesde) then
      Result.FechaDesde := 0;
    S := Ini.ReadString(SECTION_ERP_SAGE200, 'FechaHasta', '');
    if (S = '') or not TryISO8601ToDate(S, Result.FechaHasta) then
      Result.FechaHasta := 0;
    Result.IncluirFinalizadas := Ini.ReadBool(SECTION_ERP_SAGE200, 'IncluirFinalizadas', False);
  finally
    Ini.Free;
  end;
end;

procedure SaveErpSage200Config(const ACfg: TErpSage200Config);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetConfigFilePath);
  try
    Ini.WriteString (SECTION_ERP_SAGE200, 'Server',       ACfg.Server);
    Ini.WriteString (SECTION_ERP_SAGE200, 'Database',     ACfg.Database);
    Ini.WriteBool   (SECTION_ERP_SAGE200, 'WindowsAuth',  ACfg.WindowsAuth);
    Ini.WriteString (SECTION_ERP_SAGE200, 'UserName',     ACfg.UserName);
    if ACfg.WindowsAuth then
      Ini.WriteString(SECTION_ERP_SAGE200, 'Password', '')
    else
      Ini.WriteString(SECTION_ERP_SAGE200, 'Password', ObfuscateString(ACfg.Password));
    Ini.WriteString (SECTION_ERP_SAGE200, 'GrupoEmpresa', ACfg.GrupoEmpresa);
    Ini.WriteString (SECTION_ERP_SAGE200, 'CodigoEmpresa', ACfg.CodigoEmpresa);
    Ini.WriteInteger(SECTION_ERP_SAGE200, 'Ejercicio',    ACfg.Ejercicio);
    if ACfg.FechaDesde = 0 then
      Ini.WriteString(SECTION_ERP_SAGE200, 'FechaDesde', '')
    else
      Ini.WriteString(SECTION_ERP_SAGE200, 'FechaDesde', DateToISO8601(ACfg.FechaDesde, False));
    if ACfg.FechaHasta = 0 then
      Ini.WriteString(SECTION_ERP_SAGE200, 'FechaHasta', '')
    else
      Ini.WriteString(SECTION_ERP_SAGE200, 'FechaHasta', DateToISO8601(ACfg.FechaHasta, False));
    Ini.WriteBool(SECTION_ERP_SAGE200, 'IncluirFinalizadas', ACfg.IncluirFinalizadas);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

end.
