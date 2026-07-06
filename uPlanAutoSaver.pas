unit uPlanAutoSaver;

{
  Auto-save con debounce + write-behind para el plan activo.

  Patron:
    - MarkDirty(DataId) marca un nodo como modificado en memoria y reinicia
      el timer de debounce (default 2s, configurable via UserPrefs).
    - Cuando el timer expira sin nuevos cambios, se lanza el save en un
      thread secundario:
        1) Snapshot: copia los DataIds dirty actuales y limpia su flag.
        2) Recoge TNode + TNodeData de los repos para esos ids.
        3) SaveNodes (transaccional) en el connector.
        4) En 'exito: nada m'as que hacer (los flags ya estaban limpios).
        5) En error: vuelve a marcar los flags y dispara OnSaveFailed.
    - Flush(Sync) fuerza un guardado inmediato (al cerrar / cambiar de plan).
    - Si el usuario edita un nodo mientras el save est'a en marcha, su flag
      Modified vuelve a True y el siguiente ciclo lo recoger'a.
}

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections,
  Vcl.ExtCtrls, Vcl.Forms,
  uGanttTypes, uNodeDataRepo, uNodesRepo;

type
  TAutoSaveStatus = (assIdle, assDirty, assSaving, assError);

  TPlanSaveProc = reference to procedure(AProjectId: Integer;
    const ANodes: TArray<TNode>; const ANodeData: TArray<TNodeData>);
  // Persistencia ligera: SOLO posiciones (FechaInicio/Fin/CenterId) de FS_PL_Node.
  // Sin NodeData/CentresPermesos/CustomFields. Para mover/reencadenar.
  TPlanSavePosProc = reference to procedure(AProjectId: Integer;
    const ANodes: TArray<TNode>);
  TPlanGetProjectIdFunc = reference to function: Integer;
  TPlanModifiedProc = reference to procedure(const ADataIds: TArray<Integer>);

  TAutoSaveStartedEvent = procedure(Sender: TObject; ANodeCount: Integer) of object;
  TAutoSaveCompletedEvent = procedure(Sender: TObject; ANodeCount: Integer) of object;
  TAutoSaveFailedEvent = procedure(Sender: TObject; const AError: string) of object;
  TAutoSaveStatusEvent = procedure(Sender: TObject; AStatus: TAutoSaveStatus) of object;

  TPlanAutoSaver = class
  private
    FOwner: TComponent;
    FNodeDataRepo: TNodeDataRepo;
    FNodesRepo: TNodesRepo;
    FGetProjectId: TPlanGetProjectIdFunc;
    FSaveProc: TPlanSaveProc;
    FSavePosProc: TPlanSavePosProc;   // persistencia ligera de posiciones (opcional)

    FDebounceMs: Integer;
    FTimer: TTimer;
    FLock: TCriticalSection;
    FStatus: TAutoSaveStatus;
    FSaving: Boolean;
    FSavingDataIds: TArray<Integer>;

    FOnSaveStarted: TAutoSaveStartedEvent;
    FOnSaveCompleted: TAutoSaveCompletedEvent;
    FOnSaveFailed: TAutoSaveFailedEvent;
    FOnStatusChange: TAutoSaveStatusEvent;

    procedure TimerFired(Sender: TObject);
    procedure DoSaveAsync;
    procedure DoSaveSync;
    procedure SetStatus(AStatus: TAutoSaveStatus);
  public
    constructor Create(AOwner: TComponent;
      ANodeDataRepo: TNodeDataRepo; ANodesRepo: TNodesRepo;
      AGetProjectId: TPlanGetProjectIdFunc;
      ASaveProc: TPlanSaveProc);
    destructor Destroy; override;

    // AFull=True (edicion de ficha) -> persistencia completa; AFull=False
    // (mover/redimensionar) -> persistencia ligera de posiciones. Default True
    // (seguro: comportamiento previo) para los callers que no lo especifican.
    procedure MarkDirty(const ADataId: Integer; AFull: Boolean = True); overload;
    procedure MarkDirty(const ADataIds: TArray<Integer>; AFull: Boolean = True); overload;

    // Flush(True) bloquea hasta acabar el save. Llamar al cerrar / cambiar plan.
    procedure Flush(ASync: Boolean);

    procedure Cancel;

    property Status: TAutoSaveStatus read FStatus;
    property DebounceMs: Integer read FDebounceMs write FDebounceMs;
    // Persistencia ligera de posiciones (opcional). Si se asigna, los cambios
    // marcados como solo-posicion (mover/reencadenar) se guardan por aqui (rapido);
    // si es nil, TODO va por el save completo (comportamiento previo).
    property SavePosProc: TPlanSavePosProc read FSavePosProc write FSavePosProc;

    property OnSaveStarted: TAutoSaveStartedEvent
      read FOnSaveStarted write FOnSaveStarted;
    property OnSaveCompleted: TAutoSaveCompletedEvent
      read FOnSaveCompleted write FOnSaveCompleted;
    property OnSaveFailed: TAutoSaveFailedEvent
      read FOnSaveFailed write FOnSaveFailed;
    property OnStatusChange: TAutoSaveStatusEvent
      read FOnStatusChange write FOnStatusChange;
  end;

implementation

{ TPlanAutoSaver }

constructor TPlanAutoSaver.Create(AOwner: TComponent;
  ANodeDataRepo: TNodeDataRepo; ANodesRepo: TNodesRepo;
  AGetProjectId: TPlanGetProjectIdFunc;
  ASaveProc: TPlanSaveProc);
begin
  inherited Create;
  FOwner := AOwner;
  FNodeDataRepo := ANodeDataRepo;
  FNodesRepo := ANodesRepo;
  FGetProjectId := AGetProjectId;
  FSaveProc := ASaveProc;
  FDebounceMs := 2000;
  FStatus := assIdle;
  FSaving := False;
  FLock := TCriticalSection.Create;

  FTimer := TTimer.Create(AOwner);
  FTimer.Enabled := False;
  FTimer.Interval := FDebounceMs;
  FTimer.OnTimer := TimerFired;
end;

destructor TPlanAutoSaver.Destroy;
begin
  FTimer.Enabled := False;
  FTimer.Free;
  FLock.Free;
  inherited;
end;

procedure TPlanAutoSaver.SetStatus(AStatus: TAutoSaveStatus);
begin
  if FStatus = AStatus then Exit;
  FStatus := AStatus;
  if Assigned(FOnStatusChange) then
    FOnStatusChange(Self, FStatus);
end;

procedure TPlanAutoSaver.MarkDirty(const ADataId: Integer; AFull: Boolean);
begin
  MarkDirty(TArray<Integer>.Create(ADataId), AFull);
end;

procedure TPlanAutoSaver.MarkDirty(const ADataIds: TArray<Integer>; AFull: Boolean);
begin
  if (FNodeDataRepo = nil) or (Length(ADataIds) = 0) then Exit;
  // Marcar el tipo de cambio (posicion vs ficha) en el repo. El flag Modified
  // basico ya lo pueden haber puesto los callers; MarkDirtyKind ademas fija
  // FullDirty segun AFull.
  FNodeDataRepo.MarkDirtyKind(ADataIds, AFull);
  SetStatus(assDirty);
  FTimer.Enabled := False;
  FTimer.Interval := FDebounceMs;
  FTimer.Enabled := True;
end;

procedure TPlanAutoSaver.Cancel;
begin
  FTimer.Enabled := False;
end;

procedure TPlanAutoSaver.TimerFired(Sender: TObject);
begin
  FTimer.Enabled := False;
  DoSaveAsync;
end;

procedure TPlanAutoSaver.DoSaveAsync;
var
  DirtyPos, DirtyFull: TArray<TNodeData>;
  ProjectId, I, Total: Integer;
  DataIds: TArray<Integer>;
  IdsPos, IdsFull: TArray<Integer>;
  NodesPos, NodesFull: TArray<TNode>;
begin
  FLock.Enter;
  try
    if FSaving then
    begin
      // Save anterior a'un en curso. Reprogramar para 'esta + un poco m'as.
      FTimer.Interval := FDebounceMs;
      FTimer.Enabled := True;
      Exit;
    end;

    if (FNodeDataRepo = nil) or not Assigned(FGetProjectId) then Exit;
    ProjectId := FGetProjectId();
    if ProjectId <= 0 then Exit;

    // Separar dirty en solo-posicion (persistencia ligera) y ficha-completa.
    FNodeDataRepo.GetDirtySplit(DirtyPos, DirtyFull);
    Total := Length(DirtyPos) + Length(DirtyFull);
    if Total = 0 then
    begin
      SetStatus(assIdle);
      Exit;
    end;

    // Si no hay proc ligero asignado, TODO va por el save completo (seguro).
    if not Assigned(FSavePosProc) and (Length(DirtyPos) > 0) then
    begin
      DirtyFull := DirtyFull + DirtyPos;
      SetLength(DirtyPos, 0);
    end;

    // DataIds de cada grupo + snapshot combinado para limpiar/restaurar flags.
    SetLength(IdsPos, Length(DirtyPos));
    for I := 0 to High(DirtyPos) do IdsPos[I] := DirtyPos[I].DataId;
    SetLength(IdsFull, Length(DirtyFull));
    for I := 0 to High(DirtyFull) do IdsFull[I] := DirtyFull[I].DataId;
    DataIds := IdsPos + IdsFull;
    FNodeDataRepo.ClearModifiedFlags(DataIds);

    // Recoger los TNode de cada grupo (posiciones actualizadas).
    if FNodesRepo <> nil then
    begin
      NodesPos := FNodesRepo.GetByDataIds(IdsPos);
      NodesFull := FNodesRepo.GetByDataIds(IdsFull);
    end
    else
    begin
      SetLength(NodesPos, 0); SetLength(NodesFull, 0);
    end;

    FSavingDataIds := DataIds;
    FSaving := True;
    SetStatus(assSaving);
  finally
    FLock.Leave;
  end;

  if Assigned(FOnSaveStarted) then
    FOnSaveStarted(Self, Total);

  // Lanzar save en thread secundario
  TThread.CreateAnonymousThread(
    procedure
    var
      ErrMsg: string;
    begin
      ErrMsg := '';
      try
        // 1) Posiciones (ligero) para los solo-movidos/reencadenados.
        if Assigned(FSavePosProc) and (Length(NodesPos) > 0) then
          FSavePosProc(ProjectId, NodesPos);
        // 2) Ficha completa para los editados.
        if Length(DirtyFull) > 0 then
          FSaveProc(ProjectId, NodesFull, DirtyFull);
      except
        on E: Exception do ErrMsg := E.Message;
      end;

      TThread.Synchronize(nil,
        procedure
        begin
          FLock.Enter;
          try
            FSaving := False;
            if ErrMsg <> '' then
            begin
              // Restaurar flags Modified de los nodos que intentamos guardar.
              // (Si el usuario reedito alguno durante el save, lo dejamos como est'a.)
              FNodeDataRepo.SetModifiedFlags(FSavingDataIds);
              SetLength(FSavingDataIds, 0);
              SetStatus(assError);
            end
            else
            begin
              SetLength(FSavingDataIds, 0);
              if FNodeDataRepo.HasDirty then
              begin
                // Hubo nuevas ediciones durante el save; reprogramar.
                SetStatus(assDirty);
                FTimer.Interval := FDebounceMs;
                FTimer.Enabled := True;
              end
              else
                SetStatus(assIdle);
            end;
          finally
            FLock.Leave;
          end;

          if ErrMsg <> '' then
          begin
            if Assigned(FOnSaveFailed) then FOnSaveFailed(Self, ErrMsg);
          end
          else
          begin
            if Assigned(FOnSaveCompleted) then FOnSaveCompleted(Self, Total);
          end;
        end);
    end).Start;
end;

procedure TPlanAutoSaver.DoSaveSync;
var
  DirtyPos, DirtyFull: TArray<TNodeData>;
  ProjectId, I, Total: Integer;
  DataIds, IdsPos, IdsFull: TArray<Integer>;
  NodesPos, NodesFull: TArray<TNode>;
  ErrMsg: string;
begin
  if (FNodeDataRepo = nil) or not Assigned(FGetProjectId) then Exit;
  ProjectId := FGetProjectId();
  if ProjectId <= 0 then Exit;

  FNodeDataRepo.GetDirtySplit(DirtyPos, DirtyFull);
  Total := Length(DirtyPos) + Length(DirtyFull);
  if Total = 0 then
  begin
    SetStatus(assIdle);
    Exit;
  end;

  // Sin proc ligero: todo por el completo.
  if not Assigned(FSavePosProc) and (Length(DirtyPos) > 0) then
  begin
    DirtyFull := DirtyFull + DirtyPos;
    SetLength(DirtyPos, 0);
  end;

  SetLength(IdsPos, Length(DirtyPos));
  for I := 0 to High(DirtyPos) do IdsPos[I] := DirtyPos[I].DataId;
  SetLength(IdsFull, Length(DirtyFull));
  for I := 0 to High(DirtyFull) do IdsFull[I] := DirtyFull[I].DataId;
  DataIds := IdsPos + IdsFull;
  FNodeDataRepo.ClearModifiedFlags(DataIds);

  if FNodesRepo <> nil then
  begin
    NodesPos := FNodesRepo.GetByDataIds(IdsPos);
    NodesFull := FNodesRepo.GetByDataIds(IdsFull);
  end
  else
  begin
    SetLength(NodesPos, 0); SetLength(NodesFull, 0);
  end;

  SetStatus(assSaving);
  if Assigned(FOnSaveStarted) then FOnSaveStarted(Self, Total);

  ErrMsg := '';
  try
    if Assigned(FSavePosProc) and (Length(NodesPos) > 0) then
      FSavePosProc(ProjectId, NodesPos);
    if Length(DirtyFull) > 0 then
      FSaveProc(ProjectId, NodesFull, DirtyFull);
  except
    on E: Exception do ErrMsg := E.Message;
  end;

  if ErrMsg <> '' then
  begin
    FNodeDataRepo.SetModifiedFlags(DataIds);
    SetStatus(assError);
    if Assigned(FOnSaveFailed) then FOnSaveFailed(Self, ErrMsg);
  end
  else
  begin
    SetStatus(assIdle);
    if Assigned(FOnSaveCompleted) then FOnSaveCompleted(Self, Total);
  end;
end;

procedure TPlanAutoSaver.Flush(ASync: Boolean);
const
  WAIT_TIMEOUT_MS = 8000;
var
  Elapsed: Cardinal;
begin
  FTimer.Enabled := False;

  if not ASync then
  begin
    DoSaveAsync;
    Exit;
  end;

  // Esperar a que termine cualquier save async en curso
  Elapsed := 0;
  while FSaving and (Elapsed < WAIT_TIMEOUT_MS) do
  begin
    Sleep(50);
    Inc(Elapsed, 50);
    // Procesar mensajes para que TThread.Synchronize del save async pueda completar
    if Application.Terminated then Break;
    Application.ProcessMessages;
  end;

  // Save final s'incrono (cualquier dirty restante)
  DoSaveSync;
end;

end.
