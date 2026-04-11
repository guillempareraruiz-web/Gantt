unit uKanbanBoard;

{
  TKanbanBoard - Control Kanban interactivo estilo Trello/Jira.

  - Columnas de ancho fijo (280px) con scroll vertical independiente.
  - Scroll horizontal global cuando las columnas exceden el ancho visible.
  - Textos con ellipsis cuando no caben en la tarjeta.
  - Columnas dinámicas: añadir, eliminar, renombrar, reordenar, cambiar color.
  - 4 columnas de estado por defecto vinculadas a TNodoEstado.
  - Drag & drop de tarjetas entre columnas y reordenación dentro de columna.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.Generics.Defaults, System.Math,
  System.DateUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Menus,
  uGanttTypes, uNodeDataRepo;

type
  TKanbanColumnDef = record
    Id: Integer;
    Caption: string;
    Color: TColor;
    MappedEstado: Integer;  // -1 = libre; 0..3 = TNodoEstado
    Order: Integer;
  end;

  TKanbanColumnLayout = record
    ColId: Integer;
    Rect: TRectF;           // posición en coordenadas de contenido (antes de scrollX)
    ScreenRect: TRectF;     // posición en pantalla (después de scrollX)
    HeaderRect: TRectF;     // header en pantalla
    Caption: string;
    Color: TColor;
    CardCount: Integer;
  end;

  TKanbanCardLayout = record
    DataId: Integer;
    ColId: Integer;
    Rect: TRectF;           // en pantalla (después de scrollX y scrollY de columna)
    Priority: Integer;
    SortIndex: Integer;
    StartTime: TDateTime;
    EndTime: TDateTime;
    Hovered: Boolean;
  end;

  TKanbanCardEvent = procedure(Sender: TObject; const DataId: Integer) of object;
  TKanbanCardMoveEvent = procedure(Sender: TObject; const DataId: Integer;
    const OldState, NewState: TNodoEstado) of object;

  TGetNodeTimesFunc = reference to function(const DataId: Integer;
    out AStart, AEnd: TDateTime): Boolean;

  TKanbanFilterField = (kffNone, kffCentre, kffPrioridad, kffArticulo);

  TKanbanBoard = class(TCustomControl)
  private const
    HEADER_HEIGHT = 40;
    CARD_HEIGHT = 96;
    CARD_MARGIN = 6;
    CARD_PADDING = 8;
    COLUMN_GAP = 8;
    COLUMN_WIDTH = 280;     // ancho fijo estilo Trello
    ADD_COL_BTN_WIDTH = 280;
    SCROLLBAR_SIZE = 14;

  private
    FNodeRepo: TNodeDataRepo;

    // Columnas
    FColumnDefs: TList<TKanbanColumnDef>;
    FColumnLayouts: TArray<TKanbanColumnLayout>;
    FNextColId: Integer;

    // Cards
    FCards: TArray<TKanbanCardLayout>;

    // Scroll
    FScrollX: Single;                           // scroll horizontal global
    FScrollYMap: TDictionary<Integer, Single>;   // ColId -> scroll vertical
    FContentWidth: Single;                       // ancho total del contenido

    // Drag card
    FDragging: Boolean;
    FDragDataId: Integer;
    FDragStartColId: Integer;
    FDragOffset: TPointF;
    FDragPos: TPoint;
    FDragCardRect: TRectF;

    // Hover
    FHoverDataId: Integer;
    FHoverColId: Integer;

    // Filtro
    FFilterField: TKanbanFilterField;
    FFilterValue: string;
    FFilterCentreId: Integer;

    // Tiempos
    FGetNodeTimes: TGetNodeTimesFunc;

    // Orden (DataId -> SortIndex)
    FCardOrder: TDictionary<Integer, Integer>;
    FCardColAssign: TDictionary<Integer, Integer>;
    FNextSortIndex: Integer;

    // Popup columna
    FPopupColId: Integer;
    FColPopup: TPopupMenu;
    FmiRename: TMenuItem;
    FmiDelete: TMenuItem;
    FmiColor: TMenuItem;
    FmiMoveLeft: TMenuItem;
    FmiMoveRight: TMenuItem;

    // Column drag (reorder by header)
    FDraggingCol: Boolean;
    FDragColId: Integer;
    FDragColStartX: Integer;
    FDragColOrigOrder: Integer;
    FDragColScreenX: Single;  // posición X actual de la columna arrastrada

    // Scrollbar drag
    FDraggingHScrollbar: Boolean;
    FHScrollbarGrabX: Single;
    FHScrollbarGrabScrollX: Single;

    // Eventos
    FOnCardDblClick: TKanbanCardEvent;
    FOnCardMoved: TKanbanCardMoveEvent;
    FOnCardClick: TKanbanCardEvent;

    // Helpers
    function ColIdFromEstado(const E: TNodoEstado): Integer;
    function EstadoFromColId(const ColId: Integer; out E: TNodoEstado): Boolean;
    function GetColDefById(const ColId: Integer): TKanbanColumnDef;
    function GetColDefIndexById(const ColId: Integer): Integer;
    function GetSortedColumnDefs: TArray<TKanbanColumnDef>;
    function PriorityColor(const P: Integer): TColor;
    function PriorityText(const P: Integer): string;
    function GetColScrollY(const ColId: Integer): Single;
    procedure SetColScrollY(const ColId: Integer; const V: Single);
    function MaxScrollX: Single;
    function MaxColScrollY(const ColId: Integer): Single;

    procedure BuildLayout;
    procedure BuildCards;
    function PassFilter(const D: TNodeData): Boolean;
    function ColIdForCard(const D: TNodeData): Integer;

    function ColumnAtPoint(const P: TPoint): Integer;
    function CardAtPoint(const P: TPoint): Integer;
    function IsOnColumnHeader(const P: TPoint): Integer;
    function IsOnAddButton(const P: TPoint): Boolean;
    function IsOnHScrollbar(const P: TPoint): Boolean;

    // Drawing
    procedure DrawColumnGDI(const Canvas: TCanvas; const CL: TKanbanColumnLayout);
    procedure DrawCardGDI(const Canvas: TCanvas; const CL: TKanbanCardLayout;
      const D: TNodeData; const IsDragPreview: Boolean);
    procedure DrawAddColumnButton(const Canvas: TCanvas);
    procedure DrawHScrollbar(const Canvas: TCanvas);
    procedure DrawTextEllipsis(const Canvas: TCanvas; const AText: string;
      const ARect: TRect; const AFlags: Cardinal = DT_LEFT);

    procedure DoCardMove(const DataId: Integer; const NewColId: Integer);
    procedure ReorderCardInColumn(const DataId: Integer; const DropY: Integer;
      const ColId: Integer);
    function CardInsertIndex(const ColId: Integer; const DropY: Single): Integer;

    procedure DoAddColumn;
    procedure DoRenameColumn(const ColId: Integer);
    procedure DoDeleteColumn(const ColId: Integer);
    procedure DoChangeColumnColor(const ColId: Integer);
    procedure DoMoveColumn(const ColId: Integer; const Delta: Integer);

    procedure DropColumnAtX(const ColId: Integer; const ScreenX: Integer);
    function ColumnLayoutIndexAtX(const ScreenX: Integer): Integer; // index dins FColumnLayouts

    procedure PopupRenameClick(Sender: TObject);
    procedure PopupDeleteClick(Sender: TObject);
    procedure PopupColorClick(Sender: TObject);
    procedure PopupMoveLeftClick(Sender: TObject);
    procedure PopupMoveRightClick(Sender: TObject);

  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetNodeRepo(ARepo: TNodeDataRepo);
    procedure SetGetNodeTimes(AFunc: TGetNodeTimesFunc);
    procedure RefreshBoard;

    function AddColumn(const ACaption: string; const AColor: TColor;
      const AMappedEstado: Integer = -1): Integer;
    procedure RemoveColumn(const ColId: Integer);
    procedure RenameColumn(const ColId: Integer; const NewCaption: string);
    function ColumnCount: Integer;

    procedure FilterByCentre(const CentreId: Integer);
    procedure FilterByPrioridad(const Prioridad: Integer);
    procedure FilterByArticulo(const CodigoArticulo: string);
    procedure ClearFilter;

    property OnCardDblClick: TKanbanCardEvent read FOnCardDblClick write FOnCardDblClick;
    property OnCardMoved: TKanbanCardMoveEvent read FOnCardMoved write FOnCardMoved;
    property OnCardClick: TKanbanCardEvent read FOnCardClick write FOnCardClick;
  end;

implementation

{ ========================================================= }
{                    Constructor / Destructor                }
{ ========================================================= }

constructor TKanbanBoard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DoubleBuffered := True;
  Color := $00F0EDE8;  // fondo gris-beige estilo Trello

  FNodeRepo := nil;
  FDragging := False;
  FDragDataId := -1;
  FDraggingCol := False;
  FDragColId := -1;
  FDraggingHScrollbar := False;
  FHoverDataId := -1;
  FHoverColId := -1;
  FFilterField := kffNone;
  FFilterCentreId := -1;
  FGetNodeTimes := nil;
  FNextColId := 1;
  FNextSortIndex := 0;
  FScrollX := 0;
  FContentWidth := 0;

  FColumnDefs := TList<TKanbanColumnDef>.Create;
  FScrollYMap := TDictionary<Integer, Single>.Create;
  FCardOrder := TDictionary<Integer, Integer>.Create;
  FCardColAssign := TDictionary<Integer, Integer>.Create;

  // Columnas de estado por defecto
  AddColumn('Pendiente',  $00F1F2F4, Ord(nePendiente));
  AddColumn('En Curso',   $00F1F2F4, Ord(neEnCurso));
  AddColumn('Bloqueado',  $00F1F2F4, Ord(neBloqueado));
  AddColumn('Finalizado', $00F1F2F4, Ord(neFinalizado));

  // Popup
  FColPopup := TPopupMenu.Create(Self);

  FmiRename := TMenuItem.Create(FColPopup);
  FmiRename.Caption := 'Renombrar columna';
  FmiRename.OnClick := PopupRenameClick;
  FColPopup.Items.Add(FmiRename);

  FmiColor := TMenuItem.Create(FColPopup);
  FmiColor.Caption := 'Cambiar color';
  FmiColor.OnClick := PopupColorClick;
  FColPopup.Items.Add(FmiColor);

  var Sep := TMenuItem.Create(FColPopup);
  Sep.Caption := '-';
  FColPopup.Items.Add(Sep);

  FmiMoveLeft := TMenuItem.Create(FColPopup);
  FmiMoveLeft.Caption := 'Mover a la izquierda';
  FmiMoveLeft.OnClick := PopupMoveLeftClick;
  FColPopup.Items.Add(FmiMoveLeft);

  FmiMoveRight := TMenuItem.Create(FColPopup);
  FmiMoveRight.Caption := 'Mover a la derecha';
  FmiMoveRight.OnClick := PopupMoveRightClick;
  FColPopup.Items.Add(FmiMoveRight);

  var Sep2 := TMenuItem.Create(FColPopup);
  Sep2.Caption := '-';
  FColPopup.Items.Add(Sep2);

  FmiDelete := TMenuItem.Create(FColPopup);
  FmiDelete.Caption := 'Eliminar columna';
  FmiDelete.OnClick := PopupDeleteClick;
  FColPopup.Items.Add(FmiDelete);
end;

destructor TKanbanBoard.Destroy;
begin
  FColumnDefs.Free;
  FScrollYMap.Free;
  FCardOrder.Free;
  FCardColAssign.Free;
  inherited;
end;

{ ========================================================= }
{                     Helpers                                }
{ ========================================================= }

function TKanbanBoard.ColIdFromEstado(const E: TNodoEstado): Integer;
var
  I: Integer;
begin
  for I := 0 to FColumnDefs.Count - 1 do
    if FColumnDefs[I].MappedEstado = Ord(E) then
      Exit(FColumnDefs[I].Id);
  if FColumnDefs.Count > 0 then
    Result := FColumnDefs[0].Id
  else
    Result := -1;
end;

function TKanbanBoard.EstadoFromColId(const ColId: Integer; out E: TNodoEstado): Boolean;
var
  I: Integer;
begin
  for I := 0 to FColumnDefs.Count - 1 do
    if FColumnDefs[I].Id = ColId then
    begin
      if FColumnDefs[I].MappedEstado >= 0 then
      begin
        E := TNodoEstado(FColumnDefs[I].MappedEstado);
        Exit(True);
      end;
      Exit(False);
    end;
  Result := False;
end;

function TKanbanBoard.GetColDefById(const ColId: Integer): TKanbanColumnDef;
var
  I: Integer;
begin
  for I := 0 to FColumnDefs.Count - 1 do
    if FColumnDefs[I].Id = ColId then
      Exit(FColumnDefs[I]);
  FillChar(Result, SizeOf(Result), 0);
  Result.Id := -1;
end;

function TKanbanBoard.GetColDefIndexById(const ColId: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to FColumnDefs.Count - 1 do
    if FColumnDefs[I].Id = ColId then
      Exit(I);
  Result := -1;
end;

function TKanbanBoard.GetSortedColumnDefs: TArray<TKanbanColumnDef>;
var
  L: TList<TKanbanColumnDef>;
begin
  L := TList<TKanbanColumnDef>.Create;
  try
    L.AddRange(FColumnDefs.ToArray);
    L.Sort(TComparer<TKanbanColumnDef>.Construct(
      function(const A, B: TKanbanColumnDef): Integer
      begin
        Result := A.Order - B.Order;
      end));
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TKanbanBoard.PriorityColor(const P: Integer): TColor;
begin
  case P of
    1: Result := $004040FF;
    2: Result := $000080FF;
    3: Result := $00FF8000;
  else
    Result := $00808080;
  end;
end;

function TKanbanBoard.PriorityText(const P: Integer): string;
begin
  case P of
    1: Result := 'ALTA';
    2: Result := 'MEDIA';
    3: Result := 'BAJA';
  else
    Result := '';
  end;
end;

function TKanbanBoard.GetColScrollY(const ColId: Integer): Single;
begin
  if not FScrollYMap.TryGetValue(ColId, Result) then
    Result := 0;
end;

procedure TKanbanBoard.SetColScrollY(const ColId: Integer; const V: Single);
begin
  FScrollYMap.AddOrSetValue(ColId, Max(0, Min(V, MaxColScrollY(ColId))));
end;

function TKanbanBoard.MaxScrollX: Single;
begin
  Result := Max(0, FContentWidth - ClientWidth);
end;

function TKanbanBoard.MaxColScrollY(const ColId: Integer): Single;
var
  I, Cnt: Integer;
  AvailH: Single;
begin
  Cnt := 0;
  for I := 0 to High(FCards) do
    if FCards[I].ColId = ColId then
      Inc(Cnt);

  AvailH := ClientHeight - HEADER_HEIGHT - SCROLLBAR_SIZE;
  Result := Max(0, Cnt * (CARD_HEIGHT + CARD_MARGIN) + CARD_MARGIN - AvailH);
end;

function TKanbanBoard.PassFilter(const D: TNodeData): Boolean;
var
  I: Integer;
begin
  Result := True;
  case FFilterField of
    kffCentre:
      begin
        if FFilterCentreId < 0 then Exit(True);
        if Length(D.CentresPermesos) = 0 then Exit(True);
        Result := False;
        for I := 0 to High(D.CentresPermesos) do
          if D.CentresPermesos[I] = FFilterCentreId then
            Exit(True);
      end;
    kffPrioridad:
      Result := (D.Prioridad = StrToIntDef(FFilterValue, -1));
    kffArticulo:
      Result := SameText(D.CodigoArticulo, FFilterValue);
  end;
end;

function TKanbanBoard.ColIdForCard(const D: TNodeData): Integer;
begin
  if FCardColAssign.TryGetValue(D.DataId, Result) then
    if GetColDefIndexById(Result) >= 0 then
      Exit;
  FCardColAssign.Remove(D.DataId);
  Result := ColIdFromEstado(D.Estado);
end;

{ ========================================================= }
{                     Columnas                               }
{ ========================================================= }

function TKanbanBoard.AddColumn(const ACaption: string; const AColor: TColor;
  const AMappedEstado: Integer): Integer;
var
  Col: TKanbanColumnDef;
begin
  Col.Id := FNextColId;
  Inc(FNextColId);
  Col.Caption := ACaption;
  Col.Color := AColor;
  Col.MappedEstado := AMappedEstado;
  Col.Order := FColumnDefs.Count;
  FColumnDefs.Add(Col);
  Result := Col.Id;
end;

procedure TKanbanBoard.RemoveColumn(const ColId: Integer);
var
  Idx: Integer;
begin
  Idx := GetColDefIndexById(ColId);
  if Idx < 0 then Exit;

  if FColumnDefs[Idx].MappedEstado >= 0 then
  begin
    MessageDlg('No se pueden eliminar las columnas de estado predeterminadas.',
      mtWarning, [mbOK], 0);
    Exit;
  end;

  // Quitar asignaciones a esta columna
  var Keys: TArray<Integer>;
  SetLength(Keys, 0);
  for var Pair in FCardColAssign do
    if Pair.Value = ColId then
    begin
      SetLength(Keys, Length(Keys) + 1);
      Keys[High(Keys)] := Pair.Key;
    end;
  for var K in Keys do
    FCardColAssign.Remove(K);

  FColumnDefs.Delete(Idx);
  FScrollYMap.Remove(ColId);

  for var I := 0 to FColumnDefs.Count - 1 do
  begin
    var C := FColumnDefs[I];
    C.Order := I;
    FColumnDefs[I] := C;
  end;

  RefreshBoard;
end;

procedure TKanbanBoard.RenameColumn(const ColId: Integer; const NewCaption: string);
var
  Idx: Integer;
  C: TKanbanColumnDef;
begin
  Idx := GetColDefIndexById(ColId);
  if Idx < 0 then Exit;
  C := FColumnDefs[Idx];
  C.Caption := NewCaption;
  FColumnDefs[Idx] := C;
  RefreshBoard;
end;

function TKanbanBoard.ColumnCount: Integer;
begin
  Result := FColumnDefs.Count;
end;

procedure TKanbanBoard.DoAddColumn;
var
  S: string;
begin
  S := 'Nueva columna';
  if InputQuery('Añadir columna', 'Nombre de la columna:', S) then
  begin
    if Trim(S) = '' then Exit;
    AddColumn(S, $00F0F0F0);
    RefreshBoard;
  end;
end;

procedure TKanbanBoard.DoRenameColumn(const ColId: Integer);
var
  S: string;
  Idx: Integer;
begin
  Idx := GetColDefIndexById(ColId);
  if Idx < 0 then Exit;
  S := FColumnDefs[Idx].Caption;
  if InputQuery('Renombrar columna', 'Nuevo nombre:', S) then
  begin
    if Trim(S) = '' then Exit;
    RenameColumn(ColId, S);
  end;
end;

procedure TKanbanBoard.DoDeleteColumn(const ColId: Integer);
begin
  if MessageDlg('¿Eliminar esta columna? Las tarjetas volverán a su columna de estado.',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    RemoveColumn(ColId);
end;

procedure TKanbanBoard.DoChangeColumnColor(const ColId: Integer);
var
  Dlg: TColorDialog;
  Idx: Integer;
  C: TKanbanColumnDef;
begin
  Idx := GetColDefIndexById(ColId);
  if Idx < 0 then Exit;
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FColumnDefs[Idx].Color;
    if Dlg.Execute then
    begin
      C := FColumnDefs[Idx];
      C.Color := Dlg.Color;
      FColumnDefs[Idx] := C;
      RefreshBoard;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TKanbanBoard.DoMoveColumn(const ColId: Integer; const Delta: Integer);
var
  Sorted: TArray<TKanbanColumnDef>;
  Pos, NewPos, Idx: Integer;
  C: TKanbanColumnDef;
begin
  Sorted := GetSortedColumnDefs;
  Pos := -1;
  for var I := 0 to High(Sorted) do
    if Sorted[I].Id = ColId then begin Pos := I; Break; end;
  if Pos < 0 then Exit;

  NewPos := Pos + Delta;
  if (NewPos < 0) or (NewPos > High(Sorted)) then Exit;

  var TmpOrder := Sorted[Pos].Order;

  Idx := GetColDefIndexById(Sorted[Pos].Id);
  C := FColumnDefs[Idx];
  C.Order := Sorted[NewPos].Order;
  FColumnDefs[Idx] := C;

  Idx := GetColDefIndexById(Sorted[NewPos].Id);
  C := FColumnDefs[Idx];
  C.Order := TmpOrder;
  FColumnDefs[Idx] := C;

  RefreshBoard;
end;

{ ========================================================= }
{                     Column drag helpers                    }
{ ========================================================= }

function TKanbanBoard.ColumnLayoutIndexAtX(const ScreenX: Integer): Integer;
var
  I: Integer;
  MidX: Single;
begin
  // Retorna l'index dins FColumnLayouts on caldria inserir
  Result := Length(FColumnLayouts);
  for I := 0 to High(FColumnLayouts) do
  begin
    MidX := (FColumnLayouts[I].ScreenRect.Left + FColumnLayouts[I].ScreenRect.Right) / 2;
    if ScreenX < MidX then
      Exit(I);
  end;
end;

procedure TKanbanBoard.DropColumnAtX(const ColId: Integer; const ScreenX: Integer);
var
  Sorted: TArray<TKanbanColumnDef>;
  OldPos, NewPos, I, Idx: Integer;
  C: TKanbanColumnDef;
begin
  Sorted := GetSortedColumnDefs;

  // Posició actual
  OldPos := -1;
  for I := 0 to High(Sorted) do
    if Sorted[I].Id = ColId then begin OldPos := I; Break; end;
  if OldPos < 0 then Exit;

  // Nova posició basada en X
  NewPos := ColumnLayoutIndexAtX(ScreenX);
  if NewPos > OldPos then Dec(NewPos); // ajustar perquè la columna original desapareix
  if NewPos = OldPos then Exit;
  if NewPos < 0 then NewPos := 0;
  if NewPos > High(Sorted) then NewPos := High(Sorted);

  // Reordenar: treure de la llista i insertar a nova posició
  var Ids: TList<Integer>;
  Ids := TList<Integer>.Create;
  try
    for I := 0 to High(Sorted) do
      Ids.Add(Sorted[I].Id);

    Ids.Remove(ColId);
    Ids.Insert(NewPos, ColId);

    // Reassignar Order
    for I := 0 to Ids.Count - 1 do
    begin
      Idx := GetColDefIndexById(Ids[I]);
      if Idx >= 0 then
      begin
        C := FColumnDefs[Idx];
        C.Order := I;
        FColumnDefs[Idx] := C;
      end;
    end;
  finally
    Ids.Free;
  end;

  RefreshBoard;
end;

{ ========================================================= }
{                     Popup handlers                         }
{ ========================================================= }

procedure TKanbanBoard.PopupRenameClick(Sender: TObject);
begin DoRenameColumn(FPopupColId); end;

procedure TKanbanBoard.PopupDeleteClick(Sender: TObject);
begin DoDeleteColumn(FPopupColId); end;

procedure TKanbanBoard.PopupColorClick(Sender: TObject);
begin DoChangeColumnColor(FPopupColId); end;

procedure TKanbanBoard.PopupMoveLeftClick(Sender: TObject);
begin DoMoveColumn(FPopupColId, -1); end;

procedure TKanbanBoard.PopupMoveRightClick(Sender: TObject);
begin DoMoveColumn(FPopupColId, 1); end;

{ ========================================================= }
{                     Layout                                 }
{ ========================================================= }

procedure TKanbanBoard.BuildCards;
var
  I: Integer;
  D: TNodeData;
  CL: TKanbanCardLayout;
  List: TList<TKanbanCardLayout>;
  Counts: TDictionary<Integer, Integer>;
  Cnt: Integer;
begin
  List := TList<TKanbanCardLayout>.Create;
  Counts := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to FColumnDefs.Count - 1 do
      Counts.Add(FColumnDefs[I].Id, 0);

    var AllData := FNodeRepo.GetAllData;
    for I := 0 to High(AllData) do
    begin
      D := AllData[I];
      if not PassFilter(D) then Continue;

      FillChar(CL, SizeOf(CL), 0);
      CL.DataId := D.DataId;
      CL.ColId := ColIdForCard(D);
      CL.Priority := D.Prioridad;
      CL.Hovered := (D.DataId = FHoverDataId);

      if not FCardOrder.TryGetValue(D.DataId, CL.SortIndex) then
      begin
        CL.SortIndex := FNextSortIndex;
        FCardOrder.Add(D.DataId, FNextSortIndex);
        Inc(FNextSortIndex);
      end;

      if Assigned(FGetNodeTimes) then
        FGetNodeTimes(D.DataId, CL.StartTime, CL.EndTime);

      if Counts.ContainsKey(CL.ColId) then
      begin
        Counts[CL.ColId] := Counts[CL.ColId] + 1;
        List.Add(CL);
      end;
    end;

    List.Sort(TComparer<TKanbanCardLayout>.Construct(
      function(const A, B: TKanbanCardLayout): Integer
      begin
        Result := A.ColId - B.ColId;
        if Result = 0 then
          Result := A.SortIndex - B.SortIndex;
      end));

    FCards := List.ToArray;

    // Layouts de columna
    SetLength(FColumnLayouts, FColumnDefs.Count);
    var Sorted := GetSortedColumnDefs;
    for I := 0 to High(Sorted) do
    begin
      FColumnLayouts[I].ColId := Sorted[I].Id;
      FColumnLayouts[I].Caption := Sorted[I].Caption;
      FColumnLayouts[I].Color := Sorted[I].Color;
      if Counts.TryGetValue(Sorted[I].Id, Cnt) then
        FColumnLayouts[I].CardCount := Cnt
      else
        FColumnLayouts[I].CardCount := 0;
    end;
  finally
    Counts.Free;
    List.Free;
  end;
end;

procedure TKanbanBoard.BuildLayout;
var
  ContentX, ScreenX, Y: Single;
  I, J: Integer;
  NumCols: Integer;
  BodyH: Single;
begin
  NumCols := Length(FColumnLayouts);
  if NumCols = 0 then Exit;

  // Ancho total del contenido
  FContentWidth := COLUMN_GAP + NumCols * (COLUMN_WIDTH + COLUMN_GAP) + ADD_COL_BTN_WIDTH + COLUMN_GAP;

  // Clamp scrollX
  FScrollX := Max(0, Min(FScrollX, MaxScrollX));

  BodyH := ClientHeight - SCROLLBAR_SIZE;

  // Posiciones de columna
  for I := 0 to High(FColumnLayouts) do
  begin
    ContentX := COLUMN_GAP + I * (COLUMN_WIDTH + COLUMN_GAP);
    ScreenX := ContentX - FScrollX;

    FColumnLayouts[I].Rect := RectF(ContentX, 0, ContentX + COLUMN_WIDTH, BodyH);
    FColumnLayouts[I].ScreenRect := RectF(ScreenX, 0, ScreenX + COLUMN_WIDTH, BodyH);
    FColumnLayouts[I].HeaderRect := RectF(ScreenX, 0, ScreenX + COLUMN_WIDTH, HEADER_HEIGHT);
  end;

  // Posicionar cards en pantalla
  for I := 0 to High(FColumnLayouts) do
  begin
    var ColId := FColumnLayouts[I].ColId;
    var ScrLeft := FColumnLayouts[I].ScreenRect.Left;
    var ColBodyTop: Single := HEADER_HEIGHT;
    Y := ColBodyTop + CARD_MARGIN - GetColScrollY(ColId);

    for J := 0 to High(FCards) do
    begin
      if FCards[J].ColId <> ColId then Continue;

      var CX := ScrLeft + CARD_MARGIN;
      var CW := COLUMN_WIDTH - 2 * CARD_MARGIN;
      FCards[J].Rect := RectF(CX, Y, CX + CW, Y + CARD_HEIGHT);
      Y := Y + CARD_HEIGHT + CARD_MARGIN;
    end;
  end;
end;

procedure TKanbanBoard.SetGetNodeTimes(AFunc: TGetNodeTimesFunc);
begin
  FGetNodeTimes := AFunc;
end;

function TKanbanBoard.CardInsertIndex(const ColId: Integer;
  const DropY: Single): Integer;
var
  I, Pos: Integer;
  MidY: Single;
begin
  Pos := 0;
  for I := 0 to High(FCards) do
  begin
    if FCards[I].ColId <> ColId then Continue;
    MidY := (FCards[I].Rect.Top + FCards[I].Rect.Bottom) / 2;
    if DropY > MidY then
      Inc(Pos)
    else
      Break;
  end;
  Result := Pos;
end;

procedure TKanbanBoard.ReorderCardInColumn(const DataId: Integer;
  const DropY: Integer; const ColId: Integer);
var
  I, InsertPos, CurPos: Integer;
  ColCards: TList<Integer>;
begin
  ColCards := TList<Integer>.Create;
  try
    for I := 0 to High(FCards) do
      if FCards[I].ColId = ColId then
        ColCards.Add(FCards[I].DataId);

    CurPos := ColCards.IndexOf(DataId);
    if CurPos < 0 then Exit;

    InsertPos := CardInsertIndex(ColId, DropY);
    if InsertPos > CurPos then Dec(InsertPos);
    if InsertPos = CurPos then Exit;

    ColCards.Delete(CurPos);
    if InsertPos > ColCards.Count then
      InsertPos := ColCards.Count;
    ColCards.Insert(InsertPos, DataId);

    for I := 0 to ColCards.Count - 1 do
      FCardOrder.AddOrSetValue(ColCards[I], I);
  finally
    ColCards.Free;
  end;
end;

procedure TKanbanBoard.RefreshBoard;
begin
  if FNodeRepo = nil then Exit;
  BuildCards;
  BuildLayout;
  Invalidate;
end;

procedure TKanbanBoard.SetNodeRepo(ARepo: TNodeDataRepo);
begin
  FNodeRepo := ARepo;
  RefreshBoard;
end;

{ ========================================================= }
{                      Hit testing                           }
{ ========================================================= }

function TKanbanBoard.ColumnAtPoint(const P: TPoint): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FColumnLayouts) do
    if FColumnLayouts[I].ScreenRect.Contains(PointF(P.X, P.Y)) then
      Exit(FColumnLayouts[I].ColId);
end;

function TKanbanBoard.CardAtPoint(const P: TPoint): Integer;
var
  I: Integer;
begin
  Result := -1;
  // Solo cards visibles (dentro de la zona de body, no bajo header)
  if P.Y < HEADER_HEIGHT then Exit;
  for I := High(FCards) downto 0 do
    if FCards[I].Rect.Contains(PointF(P.X, P.Y)) then
      Exit(FCards[I].DataId);
end;

function TKanbanBoard.IsOnColumnHeader(const P: TPoint): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FColumnLayouts) do
    if FColumnLayouts[I].HeaderRect.Contains(PointF(P.X, P.Y)) then
      Exit(FColumnLayouts[I].ColId);
end;

function TKanbanBoard.IsOnAddButton(const P: TPoint): Boolean;
var
  BtnLeft: Single;
begin
  if Length(FColumnLayouts) = 0 then
    BtnLeft := COLUMN_GAP - FScrollX
  else
    BtnLeft := FColumnLayouts[High(FColumnLayouts)].ScreenRect.Right + COLUMN_GAP;

  Result := (P.X >= BtnLeft) and (P.X <= BtnLeft + ADD_COL_BTN_WIDTH) and
            (P.Y >= 8) and (P.Y <= 8 + HEADER_HEIGHT);
end;

function TKanbanBoard.IsOnHScrollbar(const P: TPoint): Boolean;
begin
  Result := (P.Y >= ClientHeight - SCROLLBAR_SIZE) and (FContentWidth > ClientWidth);
end;

{ ========================================================= }
{                        Drawing                             }
{ ========================================================= }

procedure TKanbanBoard.DrawTextEllipsis(const Canvas: TCanvas;
  const AText: string; const ARect: TRect; const AFlags: Cardinal);
var
  R: TRect;
begin
  R := ARect;
  DrawText(Canvas.Handle, PChar(AText), Length(AText), R,
    DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX or AFlags);
end;

procedure TKanbanBoard.Paint;
var
  I: Integer;
  D: TNodeData;
  ClipRgn: HRGN;
begin
  inherited;

  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  if FNodeRepo = nil then Exit;

  // Columnas
  for I := 0 to High(FColumnLayouts) do
  begin
    // Skip si fuera de pantalla
    if FColumnLayouts[I].ScreenRect.Right < 0 then Continue;
    if FColumnLayouts[I].ScreenRect.Left > ClientWidth then Continue;
    DrawColumnGDI(Canvas, FColumnLayouts[I]);
  end;

  // Botón "+"
  DrawAddColumnButton(Canvas);

  // Cards (clipped bajo header)
  ClipRgn := CreateRectRgn(0, HEADER_HEIGHT, ClientWidth, ClientHeight - SCROLLBAR_SIZE);
  SelectClipRgn(Canvas.Handle, ClipRgn);
  try
    for I := 0 to High(FCards) do
    begin
      if FDragging and (FCards[I].DataId = FDragDataId) then Continue;
      // Skip si fuera de pantalla
      if FCards[I].Rect.Right < 0 then Continue;
      if FCards[I].Rect.Left > ClientWidth then Continue;
      if FCards[I].Rect.Bottom < HEADER_HEIGHT then Continue;
      if FCards[I].Rect.Top > ClientHeight - SCROLLBAR_SIZE then Continue;

      if FNodeRepo.TryGetById(FCards[I].DataId, D) then
        DrawCardGDI(Canvas, FCards[I], D, False);
    end;
  finally
    SelectClipRgn(Canvas.Handle, 0);
    DeleteObject(ClipRgn);
  end;

  // Tarjeta arrastrada (sin clip)
  if FDragging and (FDragDataId > 0) then
  begin
    if FNodeRepo.TryGetById(FDragDataId, D) then
    begin
      var DragCL: TKanbanCardLayout;
      FillChar(DragCL, SizeOf(DragCL), 0);
      DragCL.DataId := FDragDataId;
      DragCL.Priority := D.Prioridad;
      DragCL.Rect := RectF(
        FDragPos.X - FDragOffset.X,
        FDragPos.Y - FDragOffset.Y,
        FDragPos.X - FDragOffset.X + FDragCardRect.Width,
        FDragPos.Y - FDragOffset.Y + FDragCardRect.Height);
      if Assigned(FGetNodeTimes) then
        FGetNodeTimes(FDragDataId, DragCL.StartTime, DragCL.EndTime);
      DrawCardGDI(Canvas, DragCL, D, True);
    end;
  end;

  // Drop zone + insertion line
  if FDragging then
  begin
    var ColId := ColumnAtPoint(FDragPos);
    if ColId >= 0 then
    begin
      for I := 0 to High(FColumnLayouts) do
        if FColumnLayouts[I].ColId = ColId then
        begin
          var SR := FColumnLayouts[I].ScreenRect;
          Canvas.Pen.Color := $00E89040;  // blau (BGR)
          Canvas.Pen.Width := 3;
          Canvas.Pen.Style := psSolid;
          Canvas.Brush.Style := bsClear;
          Canvas.RoundRect(
            Round(SR.Left) + 1, Round(SR.Top) + 5,
            Round(SR.Right) - 1, ClientHeight - SCROLLBAR_SIZE - 5,
            12, 12);
          Canvas.Pen.Width := 1;

          // Línea de inserción
          var InsPos := CardInsertIndex(ColId, FDragPos.Y);
          var LineY: Integer := HEADER_HEIGHT + CARD_MARGIN;
          var CardIdx: Integer := 0;
          for var J := 0 to High(FCards) do
          begin
            if FCards[J].ColId <> ColId then Continue;
            if FCards[J].DataId = FDragDataId then Continue;
            if CardIdx = InsPos then
            begin
              LineY := Round(FCards[J].Rect.Top) - CARD_MARGIN div 2;
              Break;
            end;
            Inc(CardIdx);
            LineY := Round(FCards[J].Rect.Bottom) + CARD_MARGIN div 2;
          end;

          Canvas.Pen.Color := $00FF8000;
          Canvas.Pen.Width := 3;
          Canvas.MoveTo(Round(SR.Left) + 8, LineY);
          Canvas.LineTo(Round(SR.Right) - 8, LineY);
          Canvas.Pen.Width := 1;
          Break;
        end;
    end;
  end;

  // Column drag preview (ghost semitransparent)
  if FDraggingCol and (FDragColId >= 0) then
  begin
    // Línia indicadora de posició d'inserció
    var InsIdx := ColumnLayoutIndexAtX(Round(FDragColScreenX));
    var InsX: Single;
    if InsIdx <= 0 then
      InsX := COLUMN_GAP - FScrollX - 2
    else if InsIdx > High(FColumnLayouts) then
      InsX := FColumnLayouts[High(FColumnLayouts)].ScreenRect.Right + COLUMN_GAP / 2
    else
      InsX := (FColumnLayouts[InsIdx - 1].ScreenRect.Right + FColumnLayouts[InsIdx].ScreenRect.Left) / 2;

    Canvas.Pen.Color := $00E89040;
    Canvas.Pen.Width := 3;
    Canvas.Pen.Style := psSolid;
    Canvas.MoveTo(Round(InsX), 8);
    Canvas.LineTo(Round(InsX), ClientHeight - SCROLLBAR_SIZE - 8);
    Canvas.Pen.Width := 1;

    // Renderitzar la columna + cards en un bitmap offscreen, després AlphaBlend
    for I := 0 to High(FColumnLayouts) do
      if FColumnLayouts[I].ColId = FDragColId then
      begin
        var GhostW := COLUMN_WIDTH;
        var GhostH := ClientHeight - SCROLLBAR_SIZE - 8;
        var OffBmp := TBitmap.Create;
        try
          OffBmp.SetSize(GhostW, GhostH);
          OffBmp.Canvas.Brush.Color := FColumnLayouts[I].Color;
          OffBmp.Canvas.Pen.Color := $00E0E0E0;
          OffBmp.Canvas.RoundRect(0, 0, GhostW, GhostH, 12, 12);

          // Header
          OffBmp.Canvas.Font.Size := 10;
          OffBmp.Canvas.Font.Style := [fsBold];
          OffBmp.Canvas.Font.Color := $00333333;
          OffBmp.Canvas.Brush.Style := bsClear;
          var TitleR := Rect(12, 10, GhostW - 34, HEADER_HEIGHT - 4);
          DrawText(OffBmp.Canvas.Handle,
            PChar(FColumnLayouts[I].Caption),
            Length(FColumnLayouts[I].Caption), TitleR,
            DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX);
          OffBmp.Canvas.Brush.Style := bsSolid;

          // Cards dins el ghost
          var CardY: Integer := HEADER_HEIGHT + CARD_MARGIN;
          for var J := 0 to High(FCards) do
          begin
            if FCards[J].ColId <> FDragColId then Continue;
            if CardY + CARD_HEIGHT > GhostH then Break;

            var ND: TNodeData;
            if FNodeRepo.TryGetById(FCards[J].DataId, ND) then
            begin
              // Card mini dins el ghost
              var CR := Rect(CARD_MARGIN, CardY, GhostW - CARD_MARGIN, CardY + CARD_HEIGHT);

              // Ombra
              OffBmp.Canvas.Brush.Color := $00DCDCDC;
              OffBmp.Canvas.Pen.Style := psClear;
              OffBmp.Canvas.RoundRect(CR.Left + 1, CR.Top + 2, CR.Right + 1, CR.Bottom + 2, 8, 8);
              OffBmp.Canvas.Pen.Style := psSolid;

              // Fons blanc
              OffBmp.Canvas.Brush.Color := clWhite;
              OffBmp.Canvas.Pen.Color := $00E8E8E8;
              OffBmp.Canvas.RoundRect(CR.Left, CR.Top, CR.Right, CR.Bottom, 8, 8);

              // Barra prioritat
              OffBmp.Canvas.Brush.Color := PriorityColor(ND.Prioridad);
              OffBmp.Canvas.Pen.Style := psClear;
              OffBmp.Canvas.RoundRect(CR.Left, CR.Top + 2, CR.Left + 5, CR.Bottom - 2, 3, 3);
              OffBmp.Canvas.Pen.Style := psSolid;

              // Títol
              OffBmp.Canvas.Brush.Style := bsClear;
              OffBmp.Canvas.Font.Size := 9;
              OffBmp.Canvas.Font.Style := [fsBold];
              OffBmp.Canvas.Font.Color := $00303030;
              var S := 'OF ' + IntToStr(ND.NumeroOrdenFabricacion);
              if ND.Operacion <> '' then S := S + ' - ' + ND.Operacion;
              var TextR := Rect(CR.Left + 12, CR.Top + CARD_PADDING,
                                CR.Right - CARD_PADDING, CR.Top + CARD_PADDING + 16);
              DrawText(OffBmp.Canvas.Handle, PChar(S), Length(S), TextR,
                DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX);
              OffBmp.Canvas.Brush.Style := bsSolid;

              CardY := CardY + CARD_HEIGHT + CARD_MARGIN;
            end;
          end;

          // AlphaBlend al canvas principal
          var DestX := Round(FDragColScreenX) - GhostW div 2;
          var DestY := 4;
          var BF: TBlendFunction;
          BF.BlendOp := AC_SRC_OVER;
          BF.BlendFlags := 0;
          BF.SourceConstantAlpha := 180;  // ~70% opacitat
          BF.AlphaFormat := 0;
          Winapi.Windows.AlphaBlend(
            Canvas.Handle, DestX, DestY, GhostW, GhostH,
            OffBmp.Canvas.Handle, 0, 0, GhostW, GhostH, BF);

          // Border blau sobre el ghost
          Canvas.Pen.Color := $00E89040;
          Canvas.Pen.Width := 2;
          Canvas.Pen.Style := psSolid;
          Canvas.Brush.Style := bsClear;
          Canvas.RoundRect(DestX, DestY, DestX + GhostW, DestY + GhostH, 12, 12);
          Canvas.Pen.Width := 1;
          Canvas.Brush.Style := bsSolid;
        finally
          OffBmp.Free;
        end;
        Break;
      end;
  end;

  // Scrollbar horizontal
  DrawHScrollbar(Canvas);
end;

procedure TKanbanBoard.DrawHScrollbar(const Canvas: TCanvas);
var
  TrackR, ThumbR: TRect;
  Ratio, ThumbW, ThumbX: Single;
begin
  if FContentWidth <= ClientWidth then Exit;

  TrackR := Rect(0, ClientHeight - SCROLLBAR_SIZE, ClientWidth, ClientHeight);

  // Track transparent
  Canvas.Brush.Color := Color;
  Canvas.Pen.Style := psClear;
  Canvas.FillRect(TrackR);

  // Thumb
  Ratio := ClientWidth / FContentWidth;
  ThumbW := Max(40, TrackR.Width * Ratio);
  if MaxScrollX > 0 then
    ThumbX := (FScrollX / MaxScrollX) * (TrackR.Width - ThumbW)
  else
    ThumbX := 0;

  ThumbR := Rect(
    TrackR.Left + Round(ThumbX) + 2,
    TrackR.Top + 3,
    TrackR.Left + Round(ThumbX + ThumbW) - 2,
    TrackR.Bottom - 3);

  Canvas.Brush.Color := $00C0BEB8;
  Canvas.RoundRect(ThumbR.Left, ThumbR.Top, ThumbR.Right, ThumbR.Bottom, 8, 8);
  Canvas.Pen.Style := psSolid;
end;

procedure TKanbanBoard.DrawAddColumnButton(const Canvas: TCanvas);
var
  BtnLeft: Single;
  R: TRect;
  S: string;
begin
  if Length(FColumnLayouts) = 0 then
    BtnLeft := COLUMN_GAP - FScrollX
  else
    BtnLeft := FColumnLayouts[High(FColumnLayouts)].ScreenRect.Right + COLUMN_GAP;

  if BtnLeft > ClientWidth then Exit;

  R := Rect(Round(BtnLeft), 8, Round(BtnLeft) + ADD_COL_BTN_WIDTH, 8 + HEADER_HEIGHT);

  // Fondo semi-transparent estil Trello
  Canvas.Brush.Color := $00E4E2DE;
  Canvas.Pen.Color := $00D8D6D2;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 12, 12);

  S := '+  Añadir columna';
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [];
  Canvas.Font.Color := $00666666;
  Canvas.Brush.Style := bsClear;
  var TR := Rect(R.Left + 12, R.Top + 4, R.Right - 8, R.Bottom - 4);
  DrawTextEllipsis(Canvas, S, TR);
  Canvas.Brush.Style := bsSolid;
end;

procedure TKanbanBoard.DrawColumnGDI(const Canvas: TCanvas;
  const CL: TKanbanColumnLayout);
var
  R, HR, BtnR: TRect;
  S: string;
begin
  R := Rect(Round(CL.ScreenRect.Left), Round(CL.ScreenRect.Top) + 4,
            Round(CL.ScreenRect.Right), Round(CL.ScreenRect.Bottom) - 4);

  // Fondo columna con bordes redondeados
  Canvas.Brush.Color := CL.Color;
  Canvas.Pen.Color := $00E0E0E0;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 12, 12);

  // Header: título a la izquierda, botón "..." a la derecha
  HR := Rect(R.Left + 12, R.Top + 6, R.Right - 34, R.Top + HEADER_HEIGHT - 8);

  Canvas.Font.Size := 10;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := $00333333;
  Canvas.Brush.Style := bsClear;

  S := CL.Caption;
  DrawTextEllipsis(Canvas, S, HR);

  // Contador de cards (al costat del títol, més petit)
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [];
  Canvas.Font.Color := $00888888;
  var CountStr := IntToStr(CL.CardCount);
  var CountW := Canvas.TextWidth(CountStr);
  // Dibuixar a la dreta del títol dins el header
  var CountX := HR.Right - CountW - 2;
  if CountX < HR.Left then CountX := HR.Left;
  Canvas.TextOut(CountX, HR.Top + 2, CountStr);

  // Botó "..." (menú) a la cantonada superior dreta
  BtnR := Rect(R.Right - 30, R.Top + 8, R.Right - 8, R.Top + 28);
  Canvas.Font.Size := 12;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := $00888888;
  var DotW := Canvas.TextWidth('...');
  Canvas.TextOut(
    BtnR.Left + (BtnR.Width - DotW) div 2,
    BtnR.Top,
    '...');

  Canvas.Brush.Style := bsSolid;
end;

procedure TKanbanBoard.DrawCardGDI(const Canvas: TCanvas;
  const CL: TKanbanCardLayout; const D: TNodeData;
  const IsDragPreview: Boolean);
var
  R: TRect;
  TR: TRect;
  TextX, TextY: Integer;
  PrioR: TRect;
  S: string;
  MaxTextW: Integer;
begin
  R := Rect(Round(CL.Rect.Left), Round(CL.Rect.Top),
            Round(CL.Rect.Right), Round(CL.Rect.Bottom));

  MaxTextW := R.Width - 12 - CARD_PADDING; // margen izq barra + padding der

  // Sombra bajo la tarjeta (estilo Trello)
  Canvas.Brush.Color := $00DCDCDC;
  Canvas.Pen.Style := psClear;
  Canvas.RoundRect(R.Left + 1, R.Top + 2, R.Right + 1, R.Bottom + 2, 8, 8);
  Canvas.Pen.Style := psSolid;

  if IsDragPreview then
  begin
    // Sombra más pronunciada al arrastrar
    Canvas.Brush.Color := $00C8C8C8;
    Canvas.Pen.Style := psClear;
    Canvas.RoundRect(R.Left + 3, R.Top + 4, R.Right + 3, R.Bottom + 4, 8, 8);
    Canvas.Pen.Style := psSolid;
  end;

  // Fondo blanco
  Canvas.Brush.Color := clWhite;
  if CL.Hovered and not IsDragPreview then
    Canvas.Brush.Color := $00F8F8F8;

  if CL.Hovered and not IsDragPreview then
  begin
    Canvas.Pen.Color := $00E89040;  // blau (BGR) al hover
    Canvas.Pen.Width := 2;
  end
  else if D.Selected then
  begin
    Canvas.Pen.Color := $00FF8000;
    Canvas.Pen.Width := 2;
  end
  else
  begin
    Canvas.Pen.Color := $00E8E8E8;
    Canvas.Pen.Width := 1;
  end;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
  Canvas.Pen.Width := 1;

  // Barra prioridad
  Canvas.Brush.Color := PriorityColor(D.Prioridad);
  Canvas.Pen.Style := psClear;
  Canvas.RoundRect(R.Left, R.Top + 2, R.Left + 5, R.Bottom - 2, 3, 3);
  Canvas.Pen.Style := psSolid;

  Canvas.Brush.Style := bsClear;

  TextX := R.Left + 12;
  TextY := R.Top + CARD_PADDING;

  // Línea 1: OF + Operación (con ellipsis)
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := $00303030;
  S := 'OF ' + IntToStr(D.NumeroOrdenFabricacion);
  if D.Operacion <> '' then
    S := S + ' - ' + D.Operacion;
  TR := Rect(TextX, TextY, TextX + MaxTextW, TextY + 16);
  DrawTextEllipsis(Canvas, S, TR);

  // Línea 2: Artículo
  TextY := TextY + 16;
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [];
  Canvas.Font.Color := $00606060;
  S := D.CodigoArticulo;
  if D.DescripcionArticulo <> '' then
    S := S + ' ' + D.DescripcionArticulo;
  TR := Rect(TextX, TextY, TextX + MaxTextW, TextY + 15);
  DrawTextEllipsis(Canvas, S, TR);

  // Línea 3: Inicio - Fin
  TextY := TextY + 14;
  Canvas.Font.Size := 7;
  Canvas.Font.Color := $00707070;
  S := '';
  if CL.StartTime > 0 then
    S := 'Inicio: ' + FormatDateTime('dd/mm/yy hh:nn', CL.StartTime);
  if CL.EndTime > 0 then
  begin
    if S <> '' then S := S + ' - ';
    S := S + 'Fin: ' + FormatDateTime('dd/mm/yy hh:nn', CL.EndTime);
  end;
  if S <> '' then
  begin
    TR := Rect(TextX, TextY, TextX + MaxTextW, TextY + 13);
    DrawTextEllipsis(Canvas, S, TR);
  end;

  // Línea 4: Entrega + Unidades
  TextY := TextY + 13;
  Canvas.Font.Size := 7;
  Canvas.Font.Color := $00808080;
  S := '';
  if D.FechaEntrega > 0 then
    S := 'Entrega: ' + FormatDateTime('dd/mm/yyyy', D.FechaEntrega);
  if D.UnidadesAFabricar > 0 then
  begin
    if S <> '' then S := S + ' | ';
    S := S + Format('%.0f/%.0f uds', [D.UnidadesFabricadas, D.UnidadesAFabricar]);
  end;
  TR := Rect(TextX, TextY, TextX + MaxTextW, TextY + 13);
  DrawTextEllipsis(Canvas, S, TR);

  // Badge prioridad
  if D.Prioridad in [1..3] then
  begin
    Canvas.Font.Size := 7;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := clWhite;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := PriorityColor(D.Prioridad);
    S := PriorityText(D.Prioridad);
    var TW := Canvas.TextWidth(S) + 8;
    PrioR := Rect(R.Right - TW - 6, R.Top + 4, R.Right - 6, R.Top + 18);
    Canvas.RoundRect(PrioR.Left, PrioR.Top, PrioR.Right, PrioR.Bottom, 4, 4);
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(PrioR.Left + 4, PrioR.Top + 1, S);
  end;

  // Barra progreso
  if D.UnidadesAFabricar > 0 then
  begin
    var Pct: Single := D.UnidadesFabricadas / D.UnidadesAFabricar;
    if Pct > 1 then Pct := 1;
    var BarY := R.Bottom - 6;
    var BarL := R.Left + 10;
    var BarR := R.Right - 10;

    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := $00E0E0E0;
    Canvas.Pen.Style := psClear;
    Canvas.RoundRect(BarL, BarY, BarR, BarY + 4, 2, 2);
    if Pct > 0 then
    begin
      Canvas.Brush.Color := $0000B050;
      Canvas.RoundRect(BarL, BarY, BarL + Round((BarR - BarL) * Pct), BarY + 4, 2, 2);
    end;
    Canvas.Pen.Style := psSolid;
  end;
end;

{ ========================================================= }
{                       Mouse events                         }
{ ========================================================= }

procedure TKanbanBoard.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DataId, ColId: Integer;
  I: Integer;
begin
  inherited;

  // Scrollbar horizontal drag
  if (Button = mbLeft) and IsOnHScrollbar(Point(X, Y)) then
  begin
    FDraggingHScrollbar := True;
    FHScrollbarGrabX := X;
    FHScrollbarGrabScrollX := FScrollX;
    Exit;
  end;

  // Botón "+"
  if (Button = mbLeft) and IsOnAddButton(Point(X, Y)) then
  begin
    DoAddColumn;
    Exit;
  end;

  // Popup columna
  if Button = mbRight then
  begin
    ColId := IsOnColumnHeader(Point(X, Y));
    if ColId >= 0 then
    begin
      FPopupColId := ColId;
      var Def := GetColDefById(ColId);
      FmiDelete.Enabled := (Def.MappedEstado < 0);
      FColPopup.Popup(ClientToScreen(Point(X, Y)).X, ClientToScreen(Point(X, Y)).Y);
      Exit;
    end;
  end;

  if Button <> mbLeft then Exit;

  // Column header drag (reorder)
  ColId := IsOnColumnHeader(Point(X, Y));
  if (ColId >= 0) and (CardAtPoint(Point(X, Y)) < 0) then
  begin
    FDraggingCol := False; // s'activa amb threshold al MouseMove
    FDragColId := ColId;
    FDragColStartX := X;
    FDragColScreenX := X;
    Exit;
  end;

  // Card drag
  DataId := CardAtPoint(Point(X, Y));
  if DataId >= 0 then
  begin
    if Assigned(FOnCardClick) then
      FOnCardClick(Self, DataId);

    FDragging := False;
    FDragDataId := DataId;
    FDragPos := Point(X, Y);

    for I := 0 to High(FCards) do
      if FCards[I].DataId = DataId then
      begin
        FDragOffset := PointF(X - FCards[I].Rect.Left, Y - FCards[I].Rect.Top);
        FDragCardRect := FCards[I].Rect;
        FDragStartColId := FCards[I].ColId;
        Break;
      end;
  end;
end;

procedure TKanbanBoard.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  OldHover: Integer;
  I: Integer;
begin
  inherited;

  // Scrollbar drag
  if FDraggingHScrollbar then
  begin
    var Delta := X - FHScrollbarGrabX;
    var MxSX := MaxScrollX;
    if MxSX > 0 then
    begin
      var Ratio := FContentWidth / ClientWidth;
      FScrollX := Max(0, Min(FHScrollbarGrabScrollX + Delta * Ratio, MxSX));
      BuildLayout;
      Invalidate;
    end;
    Exit;
  end;

  // Column drag threshold + move
  if (FDragColId >= 0) and not FDraggingCol then
  begin
    if Abs(X - FDragColStartX) > 6 then
    begin
      FDraggingCol := True;
      Cursor := crSizeAll;
    end;
  end;

  if FDraggingCol then
  begin
    FDragColScreenX := X;
    Invalidate;
    Exit;
  end;

  // Card drag threshold
  if (FDragDataId > 0) and not FDragging then
  begin
    if (Abs(X - FDragPos.X) > 4) or (Abs(Y - FDragPos.Y) > 4) then
      FDragging := True;
  end;

  if FDragging then
  begin
    FDragPos := Point(X, Y);
    Invalidate;
    Exit;
  end;

  // Hover
  OldHover := FHoverDataId;
  FHoverDataId := CardAtPoint(Point(X, Y));
  if FHoverDataId <> OldHover then
  begin
    for I := 0 to High(FCards) do
      FCards[I].Hovered := (FCards[I].DataId = FHoverDataId);
    Invalidate;
  end;

  if (FHoverDataId >= 0) or IsOnAddButton(Point(X, Y)) or IsOnHScrollbar(Point(X, Y)) then
    Cursor := crHandPoint
  else if IsOnColumnHeader(Point(X, Y)) >= 0 then
    Cursor := crSizeAll
  else
    Cursor := crDefault;
end;

procedure TKanbanBoard.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ColId: Integer;
begin
  inherited;

  if FDraggingHScrollbar then
  begin
    FDraggingHScrollbar := False;
    Exit;
  end;

  // Column drop
  if (FDraggingCol or (FDragColId >= 0)) then
  begin
    if FDraggingCol and (FDragColId >= 0) then
      DropColumnAtX(FDragColId, X);
    FDraggingCol := False;
    FDragColId := -1;
    Cursor := crDefault;
    RefreshBoard;
    Exit;
  end;

  if FDragging and (FDragDataId > 0) then
  begin
    ColId := ColumnAtPoint(Point(X, Y));
    if ColId >= 0 then
    begin
      if ColId <> FDragStartColId then
        DoCardMove(FDragDataId, ColId);
      ReorderCardInColumn(FDragDataId, Y, ColId);
    end;
  end;

  FDragging := False;
  FDragDataId := -1;
  RefreshBoard;
end;

procedure TKanbanBoard.DblClick;
begin
  inherited;
  if (FHoverDataId > 0) and Assigned(FOnCardDblClick) then
    FOnCardDblClick(Self, FHoverDataId);
end;

function TKanbanBoard.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  ColId: Integer;
  LP: TPoint;
begin
  Result := inherited;
  LP := ScreenToClient(MousePos);

  if ssShift in Shift then
  begin
    // Shift+Wheel = scroll horizontal
    FScrollX := Max(0, Min(FScrollX - WheelDelta / 3, MaxScrollX));
    BuildLayout;
    Invalidate;
    Result := True;
    Exit;
  end;

  // Wheel normal = scroll vertical de la columna bajo el cursor
  ColId := ColumnAtPoint(LP);
  if ColId < 0 then Exit;

  SetColScrollY(ColId, GetColScrollY(ColId) - WheelDelta / 3);
  BuildLayout;
  Invalidate;
  Result := True;
end;

{ ========================================================= }
{                     Card state change                      }
{ ========================================================= }

procedure TKanbanBoard.DoCardMove(const DataId: Integer; const NewColId: Integer);
var
  D: TNodeData;
  OldEstado, NewEstado: TNodoEstado;
begin
  if FNodeRepo = nil then Exit;
  if not FNodeRepo.TryGetById(DataId, D) then Exit;

  OldEstado := D.Estado;

  if EstadoFromColId(NewColId, NewEstado) then
  begin
    D.Estado := NewEstado;
    D.Modified := True;
    FNodeRepo.AddOrUpdate(D);
    FCardColAssign.Remove(DataId);
    if Assigned(FOnCardMoved) then
      FOnCardMoved(Self, DataId, OldEstado, NewEstado);
  end
  else
    FCardColAssign.AddOrSetValue(DataId, NewColId);
end;

{ ========================================================= }
{                       Resize                               }
{ ========================================================= }

procedure TKanbanBoard.Resize;
begin
  inherited;
  if FNodeRepo <> nil then
  begin
    BuildLayout;
    Invalidate;
  end;
end;

{ ========================================================= }
{                       Filtros                              }
{ ========================================================= }

procedure TKanbanBoard.FilterByCentre(const CentreId: Integer);
begin
  FFilterField := kffCentre;
  FFilterCentreId := CentreId;
  FFilterValue := '';
  RefreshBoard;
end;

procedure TKanbanBoard.FilterByPrioridad(const Prioridad: Integer);
begin
  FFilterField := kffPrioridad;
  FFilterValue := IntToStr(Prioridad);
  FFilterCentreId := -1;
  RefreshBoard;
end;

procedure TKanbanBoard.FilterByArticulo(const CodigoArticulo: string);
begin
  FFilterField := kffArticulo;
  FFilterValue := CodigoArticulo;
  FFilterCentreId := -1;
  RefreshBoard;
end;

procedure TKanbanBoard.ClearFilter;
begin
  FFilterField := kffNone;
  FFilterValue := '';
  FFilterCentreId := -1;
  RefreshBoard;
end;

end.
