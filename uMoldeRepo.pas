unit uMoldeRepo;

interface

uses
  System.SysUtils, System.Generics.Collections, uMoldeTypes;

type
  TMoldeRepo = class
  private
    FMoldes: TList<TMolde>;
    FMoldeCentros: TList<TMoldeCentro>;
    FMoldeOperaciones: TList<TMoldeOperacion>;
    FMoldeArticulos: TList<TMoldeArticulo>;
    FMoldeUtillajes: TList<TMoldeUtillaje>;
    FNextId: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    // --- Moldes ---
    function AddMolde(var A: TMolde): Integer;
    procedure UpdateMolde(const A: TMolde);
    procedure RemoveMolde(IdMolde: Integer);
    function GetMoldes: TArray<TMolde>;
    function GetMoldeById(IdMolde: Integer; out M: TMolde): Boolean;
    function NextMoldeId: Integer;

    // --- Relacion Molde-Centro ---
    procedure AssignCentro(IdMolde: Integer; const CodigoCentro: string; Preferente: Boolean; TiempoEspecifico: Double);
    procedure UnassignCentro(IdMolde: Integer; const CodigoCentro: string);
    function GetCentrosByMolde(IdMolde: Integer): TArray<TMoldeCentro>;
    function IsCentroAsignado(IdMolde: Integer; const CodigoCentro: string): Boolean;

    // --- Relacion Molde-Operacion ---
    procedure AssignOperacion(IdMolde: Integer; const CodigoOperacion: string; CiclosPorUnidad: Double; const Obs: string);
    procedure UnassignOperacion(IdMolde: Integer; const CodigoOperacion: string);
    function GetOperacionesByMolde(IdMolde: Integer): TArray<TMoldeOperacion>;
    function IsOperacionAsignada(IdMolde: Integer; const CodigoOperacion: string): Boolean;

    // --- Relacion Molde-Articulo ---
    procedure AssignArticulo(IdMolde: Integer; const CodigoArticulo: string; CavidadesActivas: Integer; const Obs: string);
    procedure UnassignArticulo(IdMolde: Integer; const CodigoArticulo: string);
    function GetArticulosByMolde(IdMolde: Integer): TArray<TMoldeArticulo>;
    function IsArticuloAsignado(IdMolde: Integer; const CodigoArticulo: string): Boolean;

    // --- Relacion Molde-Utillaje ---
    procedure AssignUtillaje(IdMolde: Integer; const CodigoUtillaje: string; Obligatorio: Boolean; const Obs: string);
    procedure UnassignUtillaje(IdMolde: Integer; const CodigoUtillaje: string);
    function GetUtillajesByMolde(IdMolde: Integer): TArray<TMoldeUtillaje>;
    function IsUtillajeAsignado(IdMolde: Integer; const CodigoUtillaje: string): Boolean;

    // --- Helpers resumen ---
    function GetCentrosStr(IdMolde: Integer): string;
    function GetOperacionesStr(IdMolde: Integer): string;
    function GetArticulosStr(IdMolde: Integer): string;
    function GetUtillajesStr(IdMolde: Integer): string;
  end;

implementation

{ TMoldeRepo }

constructor TMoldeRepo.Create;
begin
  inherited;
  FMoldes := TList<TMolde>.Create;
  FMoldeCentros := TList<TMoldeCentro>.Create;
  FMoldeOperaciones := TList<TMoldeOperacion>.Create;
  FMoldeArticulos := TList<TMoldeArticulo>.Create;
  FMoldeUtillajes := TList<TMoldeUtillaje>.Create;
  FNextId := 1;
end;

destructor TMoldeRepo.Destroy;
begin
  FMoldeUtillajes.Free;
  FMoldeArticulos.Free;
  FMoldeOperaciones.Free;
  FMoldeCentros.Free;
  FMoldes.Free;
  inherited;
end;

{ --- Moldes --- }

function TMoldeRepo.NextMoldeId: Integer;
begin
  Result := FNextId;
  Inc(FNextId);
end;

function TMoldeRepo.AddMolde(var A: TMolde): Integer;
begin
  if A.IdMolde = 0 then
    A.IdMolde := NextMoldeId;
  FMoldes.Add(A);
  Result := A.IdMolde;
end;

procedure TMoldeRepo.UpdateMolde(const A: TMolde);
var
  I: Integer;
begin
  for I := 0 to FMoldes.Count - 1 do
    if FMoldes[I].IdMolde = A.IdMolde then
    begin
      FMoldes[I] := A;
      Exit;
    end;
end;

procedure TMoldeRepo.RemoveMolde(IdMolde: Integer);
var
  I: Integer;
begin
  for I := FMoldes.Count - 1 downto 0 do
    if FMoldes[I].IdMolde = IdMolde then
      FMoldes.Delete(I);
  // Limpiar relaciones
  for I := FMoldeCentros.Count - 1 downto 0 do
    if FMoldeCentros[I].IdMolde = IdMolde then FMoldeCentros.Delete(I);
  for I := FMoldeOperaciones.Count - 1 downto 0 do
    if FMoldeOperaciones[I].IdMolde = IdMolde then FMoldeOperaciones.Delete(I);
  for I := FMoldeArticulos.Count - 1 downto 0 do
    if FMoldeArticulos[I].IdMolde = IdMolde then FMoldeArticulos.Delete(I);
  for I := FMoldeUtillajes.Count - 1 downto 0 do
    if FMoldeUtillajes[I].IdMolde = IdMolde then FMoldeUtillajes.Delete(I);
end;

function TMoldeRepo.GetMoldes: TArray<TMolde>;
begin
  Result := FMoldes.ToArray;
end;

function TMoldeRepo.GetMoldeById(IdMolde: Integer; out M: TMolde): Boolean;
var
  I: Integer;
begin
  for I := 0 to FMoldes.Count - 1 do
    if FMoldes[I].IdMolde = IdMolde then
    begin
      M := FMoldes[I];
      Exit(True);
    end;
  Result := False;
end;

{ --- Centros --- }

procedure TMoldeRepo.AssignCentro(IdMolde: Integer; const CodigoCentro: string;
  Preferente: Boolean; TiempoEspecifico: Double);
var
  R: TMoldeCentro;
begin
  if IsCentroAsignado(IdMolde, CodigoCentro) then Exit;
  R.IdMolde := IdMolde;
  R.CodigoCentro := CodigoCentro;
  R.Preferente := Preferente;
  R.TiempoMontajeEspecifico := TiempoEspecifico;
  FMoldeCentros.Add(R);
end;

procedure TMoldeRepo.UnassignCentro(IdMolde: Integer; const CodigoCentro: string);
var
  I: Integer;
begin
  for I := FMoldeCentros.Count - 1 downto 0 do
    if (FMoldeCentros[I].IdMolde = IdMolde) and
       SameText(FMoldeCentros[I].CodigoCentro, CodigoCentro) then
      FMoldeCentros.Delete(I);
end;

function TMoldeRepo.GetCentrosByMolde(IdMolde: Integer): TArray<TMoldeCentro>;
var
  I: Integer;
  L: TList<TMoldeCentro>;
begin
  L := TList<TMoldeCentro>.Create;
  try
    for I := 0 to FMoldeCentros.Count - 1 do
      if FMoldeCentros[I].IdMolde = IdMolde then
        L.Add(FMoldeCentros[I]);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TMoldeRepo.IsCentroAsignado(IdMolde: Integer; const CodigoCentro: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to FMoldeCentros.Count - 1 do
    if (FMoldeCentros[I].IdMolde = IdMolde) and
       SameText(FMoldeCentros[I].CodigoCentro, CodigoCentro) then
      Exit(True);
  Result := False;
end;

{ --- Operaciones --- }

procedure TMoldeRepo.AssignOperacion(IdMolde: Integer; const CodigoOperacion: string;
  CiclosPorUnidad: Double; const Obs: string);
var
  R: TMoldeOperacion;
begin
  if IsOperacionAsignada(IdMolde, CodigoOperacion) then Exit;
  R.IdMolde := IdMolde;
  R.CodigoOperacion := CodigoOperacion;
  R.CiclosPorUnidad := CiclosPorUnidad;
  R.Observaciones := Obs;
  FMoldeOperaciones.Add(R);
end;

procedure TMoldeRepo.UnassignOperacion(IdMolde: Integer; const CodigoOperacion: string);
var
  I: Integer;
begin
  for I := FMoldeOperaciones.Count - 1 downto 0 do
    if (FMoldeOperaciones[I].IdMolde = IdMolde) and
       SameText(FMoldeOperaciones[I].CodigoOperacion, CodigoOperacion) then
      FMoldeOperaciones.Delete(I);
end;

function TMoldeRepo.GetOperacionesByMolde(IdMolde: Integer): TArray<TMoldeOperacion>;
var
  I: Integer;
  L: TList<TMoldeOperacion>;
begin
  L := TList<TMoldeOperacion>.Create;
  try
    for I := 0 to FMoldeOperaciones.Count - 1 do
      if FMoldeOperaciones[I].IdMolde = IdMolde then
        L.Add(FMoldeOperaciones[I]);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TMoldeRepo.IsOperacionAsignada(IdMolde: Integer; const CodigoOperacion: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to FMoldeOperaciones.Count - 1 do
    if (FMoldeOperaciones[I].IdMolde = IdMolde) and
       SameText(FMoldeOperaciones[I].CodigoOperacion, CodigoOperacion) then
      Exit(True);
  Result := False;
end;

{ --- Articulos --- }

procedure TMoldeRepo.AssignArticulo(IdMolde: Integer; const CodigoArticulo: string;
  CavidadesActivas: Integer; const Obs: string);
var
  R: TMoldeArticulo;
begin
  if IsArticuloAsignado(IdMolde, CodigoArticulo) then Exit;
  R.IdMolde := IdMolde;
  R.CodigoArticulo := CodigoArticulo;
  R.CavidadesActivas := CavidadesActivas;
  R.Observaciones := Obs;
  FMoldeArticulos.Add(R);
end;

procedure TMoldeRepo.UnassignArticulo(IdMolde: Integer; const CodigoArticulo: string);
var
  I: Integer;
begin
  for I := FMoldeArticulos.Count - 1 downto 0 do
    if (FMoldeArticulos[I].IdMolde = IdMolde) and
       SameText(FMoldeArticulos[I].CodigoArticulo, CodigoArticulo) then
      FMoldeArticulos.Delete(I);
end;

function TMoldeRepo.GetArticulosByMolde(IdMolde: Integer): TArray<TMoldeArticulo>;
var
  I: Integer;
  L: TList<TMoldeArticulo>;
begin
  L := TList<TMoldeArticulo>.Create;
  try
    for I := 0 to FMoldeArticulos.Count - 1 do
      if FMoldeArticulos[I].IdMolde = IdMolde then
        L.Add(FMoldeArticulos[I]);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TMoldeRepo.IsArticuloAsignado(IdMolde: Integer; const CodigoArticulo: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to FMoldeArticulos.Count - 1 do
    if (FMoldeArticulos[I].IdMolde = IdMolde) and
       SameText(FMoldeArticulos[I].CodigoArticulo, CodigoArticulo) then
      Exit(True);
  Result := False;
end;

{ --- Utillajes --- }

procedure TMoldeRepo.AssignUtillaje(IdMolde: Integer; const CodigoUtillaje: string;
  Obligatorio: Boolean; const Obs: string);
var
  R: TMoldeUtillaje;
begin
  if IsUtillajeAsignado(IdMolde, CodigoUtillaje) then Exit;
  R.IdMolde := IdMolde;
  R.CodigoUtillaje := CodigoUtillaje;
  R.Obligatorio := Obligatorio;
  R.Observaciones := Obs;
  FMoldeUtillajes.Add(R);
end;

procedure TMoldeRepo.UnassignUtillaje(IdMolde: Integer; const CodigoUtillaje: string);
var
  I: Integer;
begin
  for I := FMoldeUtillajes.Count - 1 downto 0 do
    if (FMoldeUtillajes[I].IdMolde = IdMolde) and
       SameText(FMoldeUtillajes[I].CodigoUtillaje, CodigoUtillaje) then
      FMoldeUtillajes.Delete(I);
end;

function TMoldeRepo.GetUtillajesByMolde(IdMolde: Integer): TArray<TMoldeUtillaje>;
var
  I: Integer;
  L: TList<TMoldeUtillaje>;
begin
  L := TList<TMoldeUtillaje>.Create;
  try
    for I := 0 to FMoldeUtillajes.Count - 1 do
      if FMoldeUtillajes[I].IdMolde = IdMolde then
        L.Add(FMoldeUtillajes[I]);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TMoldeRepo.IsUtillajeAsignado(IdMolde: Integer; const CodigoUtillaje: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to FMoldeUtillajes.Count - 1 do
    if (FMoldeUtillajes[I].IdMolde = IdMolde) and
       SameText(FMoldeUtillajes[I].CodigoUtillaje, CodigoUtillaje) then
      Exit(True);
  Result := False;
end;

{ --- Helpers resumen --- }

function TMoldeRepo.GetCentrosStr(IdMolde: Integer): string;
var
  Arr: TArray<TMoldeCentro>;
  I: Integer;
begin
  Arr := GetCentrosByMolde(IdMolde);
  Result := '';
  for I := 0 to High(Arr) do
  begin
    if I > 0 then Result := Result + ', ';
    Result := Result + Arr[I].CodigoCentro;
  end;
end;

function TMoldeRepo.GetOperacionesStr(IdMolde: Integer): string;
var
  Arr: TArray<TMoldeOperacion>;
  I: Integer;
begin
  Arr := GetOperacionesByMolde(IdMolde);
  Result := '';
  for I := 0 to High(Arr) do
  begin
    if I > 0 then Result := Result + ', ';
    Result := Result + Arr[I].CodigoOperacion;
  end;
end;

function TMoldeRepo.GetArticulosStr(IdMolde: Integer): string;
var
  Arr: TArray<TMoldeArticulo>;
  I: Integer;
begin
  Arr := GetArticulosByMolde(IdMolde);
  Result := '';
  for I := 0 to High(Arr) do
  begin
    if I > 0 then Result := Result + ', ';
    Result := Result + Arr[I].CodigoArticulo;
  end;
end;

function TMoldeRepo.GetUtillajesStr(IdMolde: Integer): string;
var
  Arr: TArray<TMoldeUtillaje>;
  I: Integer;
begin
  Arr := GetUtillajesByMolde(IdMolde);
  Result := '';
  for I := 0 to High(Arr) do
  begin
    if I > 0 then Result := Result + ', ';
    Result := Result + Arr[I].CodigoUtillaje;
  end;
end;

end.
