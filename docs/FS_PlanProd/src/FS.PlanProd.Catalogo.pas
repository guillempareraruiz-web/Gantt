unit FS.PlanProd.Catalogo;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  FS.PlanProd.Types;

type
  TCatalogoMaestros = class
  private
    FOperaciones: TDictionary<string, TOperacion>;
    FCentros: TDictionary<string, TCentroTrabajo>;
    FHabilidadesConocidas: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegistrarOperacion(const AOperacion: TOperacion);
    procedure RegistrarCentro(const ACentro: TCentroTrabajo);
    procedure RegistrarHabilidad(const ACodHabilidad: string);

    function GetOperacion(const ACodOperacion: string;
      out AOperacion: TOperacion): Boolean;
    function GetCentro(const ACodCentro: string;
      out ACentro: TCentroTrabajo): Boolean;

    function ListaCodOperaciones: TArray<string>;
    function ListaCodCentros: TArray<string>;
    function ListaHabilidades: TArray<string>;

    function NumOperaciones: Integer;
    function NumCentros: Integer;
  end;

implementation

constructor TCatalogoMaestros.Create;
begin
  inherited Create;
  FOperaciones := TDictionary<string, TOperacion>.Create;
  FCentros := TDictionary<string, TCentroTrabajo>.Create;
  FHabilidadesConocidas := TList<string>.Create;
end;

destructor TCatalogoMaestros.Destroy;
var
  LOp: TOperacion;
  LC: TCentroTrabajo;
begin
  for LOp in FOperaciones.Values do
    LOp.Liberar;
  FOperaciones.Free;

  for LC in FCentros.Values do
    LC.Liberar;
  FCentros.Free;

  FHabilidadesConocidas.Free;
  inherited;
end;

procedure TCatalogoMaestros.RegistrarOperacion(const AOperacion: TOperacion);
var
  LOpAnterior: TOperacion;
  LHab: string;
begin
  if FOperaciones.TryGetValue(AOperacion.CodOperacion, LOpAnterior) then
    LOpAnterior.Liberar;
  FOperaciones.AddOrSetValue(AOperacion.CodOperacion, AOperacion);

  // Registrar habilidades implícitas en el catálogo de habilidades conocidas
  if AOperacion.HabilidadesRequeridas <> nil then
    for LHab in AOperacion.HabilidadesRequeridas.Keys do
      RegistrarHabilidad(LHab);
end;

procedure TCatalogoMaestros.RegistrarCentro(const ACentro: TCentroTrabajo);
var
  LCentroAnterior: TCentroTrabajo;
begin
  if FCentros.TryGetValue(ACentro.CodCentro, LCentroAnterior) then
    LCentroAnterior.Liberar;
  FCentros.AddOrSetValue(ACentro.CodCentro, ACentro);
end;

procedure TCatalogoMaestros.RegistrarHabilidad(const ACodHabilidad: string);
begin
  if FHabilidadesConocidas.IndexOf(ACodHabilidad) = -1 then
    FHabilidadesConocidas.Add(ACodHabilidad);
end;

function TCatalogoMaestros.GetOperacion(const ACodOperacion: string;
  out AOperacion: TOperacion): Boolean;
begin
  Result := FOperaciones.TryGetValue(ACodOperacion, AOperacion);
end;

function TCatalogoMaestros.GetCentro(const ACodCentro: string;
  out ACentro: TCentroTrabajo): Boolean;
begin
  Result := FCentros.TryGetValue(ACodCentro, ACentro);
end;

function TCatalogoMaestros.ListaCodOperaciones: TArray<string>;
var
  LList: TList<string>;
  LK: string;
begin
  LList := TList<string>.Create;
  try
    for LK in FOperaciones.Keys do
      LList.Add(LK);
    LList.Sort;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TCatalogoMaestros.ListaCodCentros: TArray<string>;
var
  LList: TList<string>;
  LK: string;
begin
  LList := TList<string>.Create;
  try
    for LK in FCentros.Keys do
      LList.Add(LK);
    LList.Sort;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TCatalogoMaestros.ListaHabilidades: TArray<string>;
begin
  FHabilidadesConocidas.Sort;
  Result := FHabilidadesConocidas.ToArray;
end;

function TCatalogoMaestros.NumOperaciones: Integer;
begin
  Result := FOperaciones.Count;
end;

function TCatalogoMaestros.NumCentros: Integer;
begin
  Result := FCentros.Count;
end;

end.
