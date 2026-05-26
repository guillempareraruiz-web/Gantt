unit uFCPLayoutRepo;

(*
  Repo para layouts de Carga Finita por usuario.

  Un layout = seleccion + orden de centros para el panel de columnas. Se
  guarda como JSON: [{"CentroId":12,"Orden":0},{"CentroId":5,"Orden":1},...]

  El layout "(por defecto)" es virtual: si Load devuelve [] el form muestra
  todos los centros alfabeticamente. No se persiste.
*)

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.Win.ADODB;

type
  TFCPLayoutCentro = record
    CentroId: Integer;
    Orden: Integer;
  end;

  TFCPLayout = record
    LayoutId: Integer;       // -1 si encara no esta a BD (nou)
    Nombre: string;
    IsDefault: Boolean;
    Centros: TArray<TFCPLayoutCentro>;
  end;

  TFCPLayoutRepo = class
  private
    FConnection: TADOConnection;
    FCodigoEmpresa: SmallInt;
    function GetUserId: Integer;
    function CentrosToJson(const ACentros: TArray<TFCPLayoutCentro>): string;
    function CentrosFromJson(const AJson: string): TArray<TFCPLayoutCentro>;
  public
    constructor Create(AConnection: TADOConnection; ACodigoEmpresa: SmallInt);
    property CodigoEmpresa: SmallInt read FCodigoEmpresa write FCodigoEmpresa;

    function GetAll: TArray<TFCPLayout>;
    function Insert(const ALayout: TFCPLayout): Integer;  // retorna LayoutId nou
    procedure Update(const ALayout: TFCPLayout);
    procedure Delete(const ALayoutId: Integer);
    procedure ClearDefaultFlag;
  end;

implementation

uses
  System.JSON, uLogin;

constructor TFCPLayoutRepo.Create(AConnection: TADOConnection;
  ACodigoEmpresa: SmallInt);
begin
  inherited Create;
  FConnection := AConnection;
  FCodigoEmpresa := ACodigoEmpresa;
end;

function TFCPLayoutRepo.GetUserId: Integer;
begin
  Result := CurrentSession.UserId;
end;

function TFCPLayoutRepo.CentrosToJson(
  const ACentros: TArray<TFCPLayoutCentro>): string;
var
  Arr: TJSONArray;
  Obj: TJSONObject;
  I: Integer;
begin
  Arr := TJSONArray.Create;
  try
    for I := 0 to High(ACentros) do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('CentroId', TJSONNumber.Create(ACentros[I].CentroId));
      Obj.AddPair('Orden', TJSONNumber.Create(ACentros[I].Orden));
      Arr.AddElement(Obj);
    end;
    Result := Arr.ToJSON;
  finally
    Arr.Free;
  end;
end;

function TFCPLayoutRepo.CentrosFromJson(
  const AJson: string): TArray<TFCPLayoutCentro>;
var
  V: TJSONValue;
  Arr: TJSONArray;
  Obj: TJSONObject;
  I: Integer;
  Lst: TList<TFCPLayoutCentro>;
  C: TFCPLayoutCentro;
begin
  Result := nil;
  if Trim(AJson) = '' then Exit;

  V := TJSONObject.ParseJSONValue(AJson);
  if V = nil then Exit;
  try
    if not (V is TJSONArray) then Exit;
    Arr := TJSONArray(V);

    Lst := TList<TFCPLayoutCentro>.Create;
    try
      for I := 0 to Arr.Count - 1 do
      begin
        if not (Arr.Items[I] is TJSONObject) then Continue;
        Obj := TJSONObject(Arr.Items[I]);
        C.CentroId := Obj.GetValue<Integer>('CentroId', -1);
        C.Orden := Obj.GetValue<Integer>('Orden', I);
        if C.CentroId >= 0 then
          Lst.Add(C);
      end;
      Result := Lst.ToArray;
    finally
      Lst.Free;
    end;
  finally
    V.Free;
  end;
end;

function TFCPLayoutRepo.GetAll: TArray<TFCPLayout>;
var
  Q: TADOQuery;
  Lst: TList<TFCPLayout>;
  L: TFCPLayout;
  Uid: Integer;
begin
  Result := nil;
  if FConnection = nil then Exit;
  Uid := GetUserId;
  if Uid <= 0 then Exit;

  Lst := TList<TFCPLayout>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT LayoutId, Nombre, IsDefault, CentrosJson ' +
      'FROM FS_PL_FCP_Layout ' +
      'WHERE CodigoEmpresa = :Emp AND UserId = :Uid ' +
      'ORDER BY IsDefault DESC, Nombre';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Uid').Value := Uid;
    Q.Open;
    while not Q.Eof do
    begin
      L.LayoutId := Q.FieldByName('LayoutId').AsInteger;
      L.Nombre := Q.FieldByName('Nombre').AsString;
      L.IsDefault := Q.FieldByName('IsDefault').AsBoolean;
      L.Centros := CentrosFromJson(Q.FieldByName('CentrosJson').AsString);
      Lst.Add(L);
      Q.Next;
    end;
    Result := Lst.ToArray;
  finally
    Q.Free;
    Lst.Free;
  end;
end;

function TFCPLayoutRepo.Insert(const ALayout: TFCPLayout): Integer;
var
  Cmd: TADOCommand;
  Q: TADOQuery;
  Uid: Integer;
begin
  Result := -1;
  if FConnection = nil then Exit;
  Uid := GetUserId;
  if Uid <= 0 then Exit;

  if ALayout.IsDefault then
    ClearDefaultFlag;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'INSERT INTO FS_PL_FCP_Layout ' +
      '  (CodigoEmpresa, UserId, Nombre, IsDefault, CentrosJson) ' +
      'VALUES (:Emp, :Uid, :Nombre, :IsDef, :Json)';
    Cmd.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Cmd.Parameters.ParamByName('Uid').Value := Uid;
    Cmd.Parameters.ParamByName('Nombre').Value := ALayout.Nombre;
    Cmd.Parameters.ParamByName('IsDef').Value := ALayout.IsDefault;
    Cmd.Parameters.ParamByName('Json').Value := CentrosToJson(ALayout.Centros);
    Cmd.Execute;
  finally
    Cmd.Free;
  end;

  // Recuperar LayoutId nou
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT MAX(LayoutId) AS NewId FROM FS_PL_FCP_Layout ' +
      'WHERE CodigoEmpresa = :Emp AND UserId = :Uid';
    Q.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Q.Parameters.ParamByName('Uid').Value := Uid;
    Q.Open;
    if not Q.Eof then Result := Q.FieldByName('NewId').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TFCPLayoutRepo.Update(const ALayout: TFCPLayout);
var
  Cmd: TADOCommand;
begin
  if FConnection = nil then Exit;
  if ALayout.LayoutId < 0 then Exit;

  if ALayout.IsDefault then
    ClearDefaultFlag;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_FCP_Layout SET ' +
      '  Nombre = :Nombre, IsDefault = :IsDef, CentrosJson = :Json, ' +
      '  FechaModificacion = GETDATE() ' +
      'WHERE CodigoEmpresa = :Emp AND LayoutId = :Lid';
    Cmd.Parameters.ParamByName('Nombre').Value := ALayout.Nombre;
    Cmd.Parameters.ParamByName('IsDef').Value := ALayout.IsDefault;
    Cmd.Parameters.ParamByName('Json').Value := CentrosToJson(ALayout.Centros);
    Cmd.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Cmd.Parameters.ParamByName('Lid').Value := ALayout.LayoutId;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TFCPLayoutRepo.Delete(const ALayoutId: Integer);
var
  Cmd: TADOCommand;
begin
  if FConnection = nil then Exit;
  if ALayoutId < 0 then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'DELETE FROM FS_PL_FCP_Layout ' +
      'WHERE CodigoEmpresa = :Emp AND LayoutId = :Lid';
    Cmd.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Cmd.Parameters.ParamByName('Lid').Value := ALayoutId;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

procedure TFCPLayoutRepo.ClearDefaultFlag;
var
  Cmd: TADOCommand;
  Uid: Integer;
begin
  Uid := GetUserId;
  if Uid <= 0 then Exit;

  Cmd := TADOCommand.Create(nil);
  try
    Cmd.Connection := FConnection;
    Cmd.CommandText :=
      'UPDATE FS_PL_FCP_Layout SET IsDefault = 0 ' +
      'WHERE CodigoEmpresa = :Emp AND UserId = :Uid';
    Cmd.Parameters.ParamByName('Emp').Value := FCodigoEmpresa;
    Cmd.Parameters.ParamByName('Uid').Value := Uid;
    Cmd.Execute;
  finally
    Cmd.Free;
  end;
end;

end.
