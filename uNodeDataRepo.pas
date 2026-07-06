unit uNodeDataRepo;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  uGAnttTypes;

type

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

    function GetAllData: TArray<TNodeData>;
    function Count: Integer;

    // Dirty tracking (para auto-save)
    function GetDirtyData: TArray<TNodeData>;
    procedure ClearModifiedFlags(const DataIds: TArray<Integer>);
    procedure SetModifiedFlags(const DataIds: TArray<Integer>);
    function HasDirty: Boolean;

    // Marca los DataIds como dirty. AFull=True (edicion de ficha) fuerza
    // FullDirty=True (persistencia completa); AFull=False (mover/reencadenar)
    // deja FullDirty como estaba (no lo baja: un cambio de ficha previo sin
    // guardar debe seguir siendo completo). Persistir limpia ambos flags.
    procedure MarkDirtyKind(const DataIds: TArray<Integer>; AFull: Boolean);
    // Dirty separados en dos grupos para el auto-save selectivo:
    //   APosOnly = solo posicion (FullDirty=False) -> UPDATE ligero de FS_PL_Node.
    //   AFull    = ficha completa (FullDirty=True)  -> SaveNodes completo.
    procedure GetDirtySplit(out APosOnly, AFull: TArray<TNodeData>);

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



function TNodeDataRepo.GetAllData: TArray<TNodeData>;
begin
  Result := Copy(FData, 0, Length(FData));
end;

function TNodeDataRepo.Count: Integer;
begin
  Result := Length(FData);
end;

function TNodeDataRepo.GetDirtyData: TArray<TNodeData>;
var
  I, K: Integer;
begin
  SetLength(Result, Length(FData));
  K := 0;
  for I := 0 to High(FData) do
    if FData[I].Modified then
    begin
      Result[K] := FData[I];
      Inc(K);
    end;
  SetLength(Result, K);
end;

procedure TNodeDataRepo.ClearModifiedFlags(const DataIds: TArray<Integer>);
var
  I, J: Integer;
  IdSet: TDictionary<Integer, Boolean>;
begin
  if Length(DataIds) = 0 then Exit;
  IdSet := TDictionary<Integer, Boolean>.Create;
  try
    for J := 0 to High(DataIds) do
      IdSet.AddOrSetValue(DataIds[J], True);
    for I := 0 to High(FData) do
      if IdSet.ContainsKey(FData[I].DataId) then
      begin
        FData[I].Modified := False;
        FData[I].FullDirty := False;   // persistido: baja tambien el flag de ficha
      end;
  finally
    IdSet.Free;
  end;
end;

procedure TNodeDataRepo.SetModifiedFlags(const DataIds: TArray<Integer>);
var
  I, J: Integer;
  IdSet: TDictionary<Integer, Boolean>;
begin
  if Length(DataIds) = 0 then Exit;
  IdSet := TDictionary<Integer, Boolean>.Create;
  try
    for J := 0 to High(DataIds) do
      IdSet.AddOrSetValue(DataIds[J], True);
    for I := 0 to High(FData) do
      if IdSet.ContainsKey(FData[I].DataId) then
        FData[I].Modified := True;
  finally
    IdSet.Free;
  end;
end;

function TNodeDataRepo.HasDirty: Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FData) do
    if FData[I].Modified then Exit(True);
  Result := False;
end;

procedure TNodeDataRepo.MarkDirtyKind(const DataIds: TArray<Integer>; AFull: Boolean);
var
  I, J: Integer;
  IdSet: TDictionary<Integer, Boolean>;
begin
  if Length(DataIds) = 0 then Exit;
  IdSet := TDictionary<Integer, Boolean>.Create;
  try
    for J := 0 to High(DataIds) do
      IdSet.AddOrSetValue(DataIds[J], True);
    for I := 0 to High(FData) do
      if IdSet.ContainsKey(FData[I].DataId) then
      begin
        FData[I].Modified := True;
        // AFull sube FullDirty; AFalse NO lo baja (un cambio de ficha pendiente
        // debe seguir siendo completo aunque despues se mueva el nodo).
        if AFull then
          FData[I].FullDirty := True;
      end;
  finally
    IdSet.Free;
  end;
end;

procedure TNodeDataRepo.GetDirtySplit(out APosOnly, AFull: TArray<TNodeData>);
var
  I, KP, KF: Integer;
begin
  SetLength(APosOnly, Length(FData));
  SetLength(AFull, Length(FData));
  KP := 0; KF := 0;
  for I := 0 to High(FData) do
    if FData[I].Modified then
    begin
      if FData[I].FullDirty then
      begin
        AFull[KF] := FData[I]; Inc(KF);
      end
      else
      begin
        APosOnly[KP] := FData[I]; Inc(KP);
      end;
    end;
  SetLength(APosOnly, KP);
  SetLength(AFull, KF);
end;

end.
