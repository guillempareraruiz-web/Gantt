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

    procedure MarkDirty(const ADataId: Integer); overload;
    procedure MarkDirty(const ADataIds: TArray<Integer>); overload;

    // Flush(True) bloquea hasta acabar el save. Llamar al cerrar / cambiar plan.
    procedure Flush(ASync: Boolean);

    procedure Cancel;

    property Status: TAutoSaveStatus read FStatus;
    property DebounceMs: Integer read FDebounceMs write FDebounceMs;

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

procedure TPlanAutoSaver.MarkDirty(const ADataId: Integer);
begin
  if FNodeDataRepo = nil then Exit;
  // El flag Modified ya lo pone el caller via FNodeRepo.AddOrUpdate(D);
  // aqu'i s'olo reiniciamos el timer.
  SetStatus(assDirty);
  FTimer.Enabled := False;
  FTimer.Interval := FDebounceMs;
  FTimer.Enabled := True;
end;

procedure TPlanAutoSaver.MarkDirty(const ADataIds: TArray<Integer>);
begin
  if Length(ADataIds) = 0 then Exit;
  MarkDirty(ADataIds[0]);
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
  Dirty: TArray<TNodeData>;
  ProjectId, I: Integer;
  DataIds: TArray<Integer>;
  Nodes: TArray<TNode>;
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

    Dirty := FNodeDataRepo.GetDirtyData;
    if Length(Dirty) = 0 then
    begin
      SetStatus(assIdle);
      Exit;
    end;

    // Snapshot de DataIds y limpieza inmediata de flags.
    // Si el usuario reedita uno durante el save, se vuelve a marcar Modified=True
    // y el siguiente ciclo lo recoger'a.
    SetLength(DataIds, Length(Dirty));
    for I := 0 to High(Dirty) do
      DataIds[I] := Dirty[I].DataId;
    FNodeDataRepo.ClearModifiedFlags(DataIds);

    // Recoger los TNode correspondientes
    if FNodesRepo <> nil then
      Nodes := FNodesRepo.GetByDataIds(DataIds)
    else
      SetLength(Nodes, 0);

    FSavingDataIds := DataIds;
    FSaving := True;
    SetStatus(assSaving);
  finally
    FLock.Leave;
  end;

  if Assigned(FOnSaveStarted) then
    FOnSaveStarted(Self, Length(Dirty));

  // Lanzar save en thread secundario
  TThread.CreateAnonymousThread(
    procedure
    var
      ErrMsg: string;
      OkCount: Integer;
    begin
      ErrMsg := '';
      OkCount := Length(Dirty);
      try
        FSaveProc(ProjectId, Nodes, Dirty);
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
            if Assigned(FOnSaveCompleted) then FOnSaveCompleted(Self, OkCount);
          end;
        end);
    end).Start;
end;

procedure TPlanAutoSaver.DoSaveSync;
var
  Dirty: TArray<TNodeData>;
  ProjectId, I: Integer;
  DataIds: TArray<Integer>;
  Nodes: TArray<TNode>;
  ErrMsg: string;
begin
  if (FNodeDataRepo = nil) or not Assigned(FGetProjectId) then Exit;
  ProjectId := FGetProjectId();
  if ProjectId <= 0 then Exit;

  Dirty := FNodeDataRepo.GetDirtyData;
  if Length(Dirty) = 0 then
  begin
    SetStatus(assIdle);
    Exit;
  end;

  SetLength(DataIds, Length(Dirty));
  for I := 0 to High(Dirty) do DataIds[I] := Dirty[I].DataId;
  FNodeDataRepo.ClearModifiedFlags(DataIds);

  if FNodesRepo <> nil then
    Nodes := FNodesRepo.GetByDataIds(DataIds)
  else
    SetLength(Nodes, 0);

  SetStatus(assSaving);
  if Assigned(FOnSaveStarted) then FOnSaveStarted(Self, Length(Dirty));

  ErrMsg := '';
  try
    FSaveProc(ProjectId, Nodes, Dirty);
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
    if Assigned(FOnSaveCompleted) then FOnSaveCompleted(Self, Length(Dirty));
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
