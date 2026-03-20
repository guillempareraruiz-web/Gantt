unit uNodeDataRepo;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  uGAnttTypes, Vcl.Graphics;

type

  TNodeData = record
    DataId: Integer;

    Operacion: String;
    NumeroPedido: Integer;
    SeriePedido: string;

    CentroTrabajo: String;

    NumeroOrdenFabricacion: Integer;
    SerieFabricacion: string;

    NumeroTrabajo: string;

    FechaEntrega: TDateTime;
    FechaNecesaria: TDateTime;

    CodigoCliente: String;

    CodigoColor: String;

    Stock: Double;

    CodigoArticulo: string;
    DescripcionArticulo: string;

    PorcentajeDependencia: Double;

    UnidadesFabricadas: Double;
    UnidadesAFabricar: Double;
    TiempoUnidadFabSecs: Double; //...tiempo en segundos para fabricar una unidad
    DurationMin: Double; //...minutos;
    DurationMinOriginal: Double; //...minutos;
    OperariosNecesarios: Integer;
    OperariosAsignados: Integer;

    Estado: TEstadoOF;
    Prioridad: Integer;

    bkColorOp: TColor;
    borderColorOp: TColor;

    Selected: Boolean;
    Modified: Boolean;
  end;


  TNodeDataRepo = class
  private

    FData: TArray<TNodeData>;
    FIdToIndex: TDictionary<Integer, Integer>;

    // Indexos
    FIdxOF: TDictionary<string, TList<Integer>>;      // OFKey -> DataId list
    FIdxTrabajo: TDictionary<string, TList<Integer>>; // TrabajoKey -> DataId list


    function MakeOFKey(const NumeroOF: Integer; const Serie: string): string;
    function MakeTrabajoKey(const NumeroTrabajo: string): string;

    procedure IndexAdd(const AData: TNodeData);
    procedure IndexRemove(const AData: TNodeData);

    procedure RemoveFromIndex(
      const Dict: TDictionary<string, TList<Integer>>;
      const Key: string;
      const DataId: Integer);

  public

    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    procedure AddOrUpdate(const AData: TNodeData);
    procedure Remove(const DataId: Integer);

    function TryGetById(const DataId: Integer; out AData: TNodeData): Boolean;

    function FindByOF(
      const NumeroOF: Integer;
      const Serie: string): TArray<Integer>;   // retorna DataIds

    function FindByTrabajo(
      const NumeroTrabajo: string): TArray<Integer>; // retorna DataIds

  end;

implementation



{ ============================================= }
{                Constructor                    }
{ ============================================= }

constructor TNodeDataRepo.Create;
begin
  inherited;

  FIdToIndex := TDictionary<Integer, Integer>.Create;

  FIdxOF := TDictionary<string, TList<Integer>>.Create;
  FIdxTrabajo := TDictionary<string, TList<Integer>>.Create;
end;



destructor TNodeDataRepo.Destroy;
var
  kv: TPair<string, TList<Integer>>;
begin

  for kv in FIdxOF do
    kv.Value.Free;

  for kv in FIdxTrabajo do
    kv.Value.Free;

  FIdxOF.Free;
  FIdxTrabajo.Free;
  FIdToIndex.Free;

  inherited;
end;



{ ============================================= }
{                  Helpers                      }
{ ============================================= }

function TNodeDataRepo.MakeOFKey(
  const NumeroOF: Integer;
  const Serie: string): string;
begin
  Result := IntToStr(NumeroOF) + '|' + UpperCase(Trim(Serie));
end;


function TNodeDataRepo.MakeTrabajoKey(
  const NumeroTrabajo: string): string;
begin
  Result := UpperCase(Trim(NumeroTrabajo));
end;



procedure TNodeDataRepo.RemoveFromIndex(
  const Dict: TDictionary<string, TList<Integer>>;
  const Key: string;
  const DataId: Integer);
var
  list: TList<Integer>;
  p: Integer;
begin
  if not Dict.TryGetValue(Key, list) then
    Exit;

  p := list.IndexOf(DataId);
  if p >= 0 then
    list.Delete(p);

  if list.Count = 0 then
  begin
    list.Free;
    Dict.Remove(Key);
  end;
end;



{ ============================================= }
{                  Index                        }
{ ============================================= }

procedure TNodeDataRepo.IndexAdd(const AData: TNodeData);
var
  key: string;
  list: TList<Integer>;
begin

  // ===== Index OF =====

  key := MakeOFKey(AData.NumeroOrdenFabricacion, AData.SerieFabricacion);

  if not FIdxOF.TryGetValue(key, list) then
  begin
    list := TList<Integer>.Create;
    FIdxOF.Add(key, list);
  end;

  list.Add(AData.DataId);



  // ===== Index Trabajo =====

  key := MakeTrabajoKey(AData.NumeroTrabajo);

  if key <> '' then
  begin
    if not FIdxTrabajo.TryGetValue(key, list) then
    begin
      list := TList<Integer>.Create;
      FIdxTrabajo.Add(key, list);
    end;

    list.Add(AData.DataId);
  end;

end;



procedure TNodeDataRepo.IndexRemove(const AData: TNodeData);
var
  key: string;
begin

  key := MakeOFKey(AData.NumeroOrdenFabricacion, AData.SerieFabricacion);
  RemoveFromIndex(FIdxOF, key, AData.DataId);

  key := MakeTrabajoKey(AData.NumeroTrabajo);

  if key <> '' then
    RemoveFromIndex(FIdxTrabajo, key, AData.DataId);

end;



{ ============================================= }
{                 Public API                    }
{ ============================================= }

procedure TNodeDataRepo.Clear;
var
  kv: TPair<string, TList<Integer>>;
begin

  SetLength(FData, 0);
  FIdToIndex.Clear;

  for kv in FIdxOF do
    kv.Value.Free;
  FIdxOF.Clear;

  for kv in FIdxTrabajo do
    kv.Value.Free;
  FIdxTrabajo.Clear;

end;



procedure TNodeDataRepo.AddOrUpdate(const AData: TNodeData);
var
  idx: Integer;
  old: TNodeData;
begin

  if AData.DataId = 0 then
    raise Exception.Create('DataId ha de ser > 0');


  if FIdToIndex.TryGetValue(AData.DataId, idx) then
  begin
    // UPDATE

    old := FData[idx];

    IndexRemove(old);

    FData[idx] := AData;

    IndexAdd(AData);
  end
  else
  begin
    // ADD

    idx := Length(FData);

    SetLength(FData, idx + 1);

    FData[idx] := AData;

    FIdToIndex.Add(AData.DataId, idx);

    IndexAdd(AData);
  end;

end;



procedure TNodeDataRepo.Remove(const DataId: Integer);
var
  idx: Integer;
  last: Integer;
  moved: TNodeData;
begin

  if not FIdToIndex.TryGetValue(DataId, idx) then
    Exit;

  IndexRemove(FData[idx]);

  last := High(FData);

  if idx <> last then
  begin
    moved := FData[last];
    FData[idx] := moved;

    FIdToIndex[moved.DataId] := idx;
  end;

  SetLength(FData, last);

  FIdToIndex.Remove(DataId);

end;



function TNodeDataRepo.TryGetById(
  const DataId: Integer;
  out AData: TNodeData): Boolean;
var
  idx: Integer;
begin
  Result := FIdToIndex.TryGetValue(DataId, idx);

  if Result then
    AData := FData[idx];
end;



function TNodeDataRepo.FindByOF(
  const NumeroOF: Integer;
  const Serie: string): TArray<Integer>;
var
  key: string;
  list: TList<Integer>;
begin

  key := MakeOFKey(NumeroOF, Serie);

  if FIdxOF.TryGetValue(key, list) then
    Result := list.ToArray
  else
    SetLength(Result, 0);

end;



function TNodeDataRepo.FindByTrabajo(
  const NumeroTrabajo: string): TArray<Integer>;
var
  key: string;
  list: TList<Integer>;
begin

  key := MakeTrabajoKey(NumeroTrabajo);

  if (key <> '') and FIdxTrabajo.TryGetValue(key, list) then
    Result := list.ToArray
  else
    SetLength(Result, 0);

end;



end.
