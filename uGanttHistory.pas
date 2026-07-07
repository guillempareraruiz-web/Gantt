unit uGanttHistory;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TGanttHistoryActionType = (
    hatUnknown,
    hatMove,
    hatResize,
    hatShiftLeft,
    hatShiftRight,
    hatResolveConstraints,
    hatEdit,
    // Lliurable B: acciones masivas y estructurales
    hatResetDuration,    // restaurar duracion original de un nodo
    hatCompactOF,        // compactar OF
    hatCompactOT,        // compactar OT
    hatBackwardOF,       // planificacion hacia atras de OF
    hatBackwardOT,       // planificacion hacia atras de OT
    hatReplanAll,        // replanificar todo desde fecha
    hatChangeCentre,     // mover nodo a otro centro
    hatCreateLote,       // agrupar nodos en lote
    hatBreakLote,        // deshacer/romper lote
    hatEditNode,         // editar propiedades de nodo (NodeInspector)
    hatCompactSel        // compactar (left-shift) los nodos seleccionados
  );

  TNodePlanSnapshot = record
    NodeIndex: Integer;
    StartTime: TDateTime;
    EndTime: TDateTime;
    Duration: Double;
    CentreId: Integer;  // Lliurable B: para deshacer cambios de centro
    LoteId: Integer;    // Lliurable B: para deshacer agrupar/romper lotes
  end;

  TNodeHistoryChange = record
    BeforeValue: TNodePlanSnapshot;
    AfterValue: TNodePlanSnapshot;
  end;

  TGanttHistoryEntry = class
  private
    FActionType: TGanttHistoryActionType;
    FCaption: string;
    FTimeStamp: TDateTime;
    FSourceNodeIndex: Integer;
    FChanges: TArray<TNodeHistoryChange>;
  public
    constructor Create;

    property ActionType: TGanttHistoryActionType read FActionType write FActionType;
    property Caption: string read FCaption write FCaption;
    property TimeStamp: TDateTime read FTimeStamp write FTimeStamp;
    property SourceNodeIndex: Integer read FSourceNodeIndex write FSourceNodeIndex;
    property Changes: TArray<TNodeHistoryChange> read FChanges write FChanges;
  end;

  TGanttHistoryManager = class
  private
    FUndoStack: TObjectList<TGanttHistoryEntry>;
    FRedoStack: TObjectList<TGanttHistoryEntry>;
    FMaxEntries: Integer;
  public
    constructor Create(AMaxEntries: Integer = 100);
    destructor Destroy; override;

    procedure Clear;

    procedure PushUndo(AEntry: TGanttHistoryEntry);
    procedure PushRedo(AEntry: TGanttHistoryEntry);
    // Empuja a undo SIN vaciar el redo. Lo usa RedoLastAction al navegar: rehacer
    // un paso no debe destruir los pasos que quedan por rehacer. (PushUndo si vacia
    // el redo, porque se usa para acciones NUEVAS del usuario, que invalidan el
    // futuro deshecho.)
    procedure PushUndoKeepRedo(AEntry: TGanttHistoryEntry);

    function PopUndo: TGanttHistoryEntry;
    function PopRedo: TGanttHistoryEntry;

    function CanUndo: Boolean;
    function CanRedo: Boolean;

    function UndoCount: Integer;
    function RedoCount: Integer;

    // Acceso de solo lectura para pintar el timeline visual. Indice 0 es la
    // entrada mas antigua del stack correspondiente.
    function GetUndoEntry(const AIndex: Integer): TGanttHistoryEntry;
    function GetRedoEntry(const AIndex: Integer): TGanttHistoryEntry;

    property MaxEntries: Integer read FMaxEntries write FMaxEntries;
  end;

function SameNodePlanSnapshot(const A, B: TNodePlanSnapshot): Boolean;

implementation

{ TGanttHistoryEntry }

constructor TGanttHistoryEntry.Create;
begin
  inherited Create;
  FTimeStamp := Now;
  FActionType := hatUnknown;
  FSourceNodeIndex := 0;
  SetLength(FChanges, 0);
end;

{ TGanttHistoryManager }

constructor TGanttHistoryManager.Create(AMaxEntries: Integer);
begin
  inherited Create;
  FUndoStack := TObjectList<TGanttHistoryEntry>.Create(True);
  FRedoStack := TObjectList<TGanttHistoryEntry>.Create(True);
  FMaxEntries := AMaxEntries;
end;

destructor TGanttHistoryManager.Destroy;
begin
  FUndoStack.Free;
  FRedoStack.Free;
  inherited;
end;

procedure TGanttHistoryManager.Clear;
begin
  FUndoStack.Clear;
  FRedoStack.Clear;
end;

function TGanttHistoryManager.CanRedo: Boolean;
begin
  Result := FRedoStack.Count > 0;
end;

function TGanttHistoryManager.CanUndo: Boolean;
begin
  Result := FUndoStack.Count > 0;
end;

function TGanttHistoryManager.PopRedo: TGanttHistoryEntry;
begin
  Result := nil;
  if FRedoStack.Count = 0 then Exit;
  Result := FRedoStack.Extract(FRedoStack.Last);
end;

function TGanttHistoryManager.PopUndo: TGanttHistoryEntry;
begin
  Result := nil;
  if FUndoStack.Count = 0 then Exit;
  Result := FUndoStack.Extract(FUndoStack.Last);
end;

procedure TGanttHistoryManager.PushRedo(AEntry: TGanttHistoryEntry);
begin
  if AEntry = nil then Exit;
  FRedoStack.Add(AEntry);
end;

procedure TGanttHistoryManager.PushUndo(AEntry: TGanttHistoryEntry);
begin
  if AEntry = nil then Exit;

  FRedoStack.Clear;
  FUndoStack.Add(AEntry);

  while FUndoStack.Count > FMaxEntries do
    FUndoStack.Delete(0);
end;

procedure TGanttHistoryManager.PushUndoKeepRedo(AEntry: TGanttHistoryEntry);
begin
  if AEntry = nil then Exit;

  FUndoStack.Add(AEntry);

  while FUndoStack.Count > FMaxEntries do
    FUndoStack.Delete(0);
end;

function TGanttHistoryManager.RedoCount: Integer;
begin
  Result := FRedoStack.Count;
end;

function TGanttHistoryManager.UndoCount: Integer;
begin
  Result := FUndoStack.Count;
end;

function TGanttHistoryManager.GetUndoEntry(const AIndex: Integer): TGanttHistoryEntry;
begin
  Result := nil;
  if (AIndex >= 0) and (AIndex < FUndoStack.Count) then
    Result := FUndoStack[AIndex];
end;

function TGanttHistoryManager.GetRedoEntry(const AIndex: Integer): TGanttHistoryEntry;
begin
  Result := nil;
  if (AIndex >= 0) and (AIndex < FRedoStack.Count) then
    Result := FRedoStack[AIndex];
end;

function SameNodePlanSnapshot(const A, B: TNodePlanSnapshot): Boolean;
const
  EPS = 1/864000; // ~0.1 ms
begin
  Result :=
    (A.NodeIndex = B.NodeIndex) and
    (Abs(A.StartTime - B.StartTime) < EPS) and
    (Abs(A.EndTime - B.EndTime) < EPS) and
    (Abs(A.Duration - B.Duration) < EPS) and
    (A.CentreId = B.CentreId) and
    (A.LoteId = B.LoteId);
end;

end.
