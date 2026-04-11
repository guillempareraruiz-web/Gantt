unit uDispatchList;

{
  TDispatchListForm - Lista de prioridades por centro de trabajo.

  - Selector de centro lateral con contadores de operaciones.
  - Lista pintada en un solo TCustomControl (sin flicker).
  - Selector de periodo: Hoy, Mañana, Esta Semana, Todo.
  - Filas grandes con estado, prioridad, progreso, fechas.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.Generics.Defaults, System.Math,
  System.DateUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  uGanttTypes, uNodeDataRepo;

type
  TDispatchItem = record
    DataId: Integer;
    NodeStartTime: TDateTime;
    NodeEndTime: TDateTime;
  end;

  TGetNodeTimesFunc = reference to function(const DataId: Integer;
    out AStart, AEnd: TDateTime): Boolean;

  TDispatchPeriodo = (dpTodo, dpHoy, dpManana, dpEstaSemana);

const
  // Posiciones X compartidas entre header y list control
  DL_X0 = 10;   // #
  DL_W0 = 32;
  DL_X1 = DL_X0 + DL_W0 + 6;   // PRIO
  DL_W1 = 48;
  DL_X2 = DL_X1 + DL_W1 + 10;  // OF / OPERACION
  DL_W2 = 210;
  DL_X3 = DL_X2 + DL_W2 + 8;   // ARTICULO
  DL_W3 = 180;
  DL_X4 = DL_X3 + DL_W3 + 8;   // INICIO - FIN
  DL_W4 = 140;
  DL_X5 = DL_X4 + DL_W4 + 8;   // PROGRESO
  DL_W5 = 100;
  DL_X6 = DL_X5 + DL_W5 + 14;  // ESTADO
  DL_W6 = 90;

type

  // Control de lista custom-drawn (un sol canvas, sense flicker)
  TDispatchListControl = class(TCustomControl)
  private const
    ROW_HEIGHT = 70;
    ESTADO_BADGE_W = 90;
    SCROLLBAR_W = 14;
  private
    FItems: TArray<TDispatchItem>;
    FNodeRepo: TNodeDataRepo;
    FScrollY: Integer;
    FHoverRow: Integer;
    FOwnerForm: TForm;

    // Scrollbar drag
    FDraggingSB: Boolean;
    FSBGrabY: Integer;
    FSBGrabScrollY: Integer;

    // Row drag (modo edicion)
    FEditMode: Boolean;
    FDraggingRow: Boolean;
    FDragRowIdx: Integer;
    FDragRowStartY: Integer;
    FDragRowCurrentY: Integer;

    function RowAtY(const Y: Integer): Integer;
    function EstadoColor(const E: TNodoEstado): TColor;
    function EstadoText(const E: TNodoEstado): string;
    function PrioridadColor(const P: Integer): TColor;
    function PrioridadText(const P: Integer): string;
    procedure DrawRow(const ACanvas: TCanvas; const RowIdx: Integer;
      const ARect: TRect; const IsHover: Boolean);
    procedure DrawScrollbar(const ACanvas: TCanvas);
    procedure DrawDragRow(const ACanvas: TCanvas);
    function IsOnScrollbar(const X: Integer): Boolean;
    function RowInsertIndex(const ScreenY: Integer): Integer;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetData(ARepo: TNodeDataRepo; const AItems: TArray<TDispatchItem>);
    function MaxScrollY: Integer;
    property EditMode: Boolean read FEditMode write FEditMode;
    property Items: TArray<TDispatchItem> read FItems write FItems;
  end;

  TDispatchListForm = class(TForm)
    pnlCentres: TPanel;
    lblCentresTitle: TLabel;
    sbCentres: TScrollBox;
    pnlHeader: TPanel;
    lblCentreName: TLabel;
    lblCount: TLabel;
    pnlEditMode: TPanel;
    lblEditMode: TLabel;
    pnlPeriodContainer: TPanel;
    pnlPeriodTodo: TPanel;
    lblPeriodTodo: TLabel;
    pnlPeriodHoy: TPanel;
    lblPeriodHoy: TLabel;
    pnlPeriodManana: TPanel;
    lblPeriodManana: TLabel;
    pnlPeriodSemana: TPanel;
    lblPeriodSemana: TLabel;
    pnlSeparator: TPanel;
    pnlContainer: TPanel;
    pnlColHeader: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private const
    CENTRE_BTN_WIDTH = 230;
    HEADER_ROW_HEIGHT = 36;
    ESTADO_BADGE_W = 90;
  private
    FNodeRepo: TNodeDataRepo;
    FCentres: TArray<TCentreTreball>;
    FGetNodeTimes: TGetNodeTimesFunc;

    // UI
    FListControl: TDispatchListControl;

    FPeriodo: TDispatchPeriodo;

    // Estado
    FSelectedCentreId: Integer;

    // Cache
    FCentreOpCount: TDictionary<Integer, Integer>;

    procedure BuildCentreButtons;
    procedure BuildColumnHeaders;
    procedure UpdateCentreCounters;
    procedure OnCentreButtonClick(Sender: TObject);
    procedure SelectCentre(const CentreId: Integer);
    procedure BuildList;

    procedure OnPeriodClick(Sender: TObject);
    procedure OnEditModeClick(Sender: TObject);
    procedure UpdatePeriodButtons;
    procedure UpdateEditModeButton;
    function ItemMatchesPeriod(const Item: TDispatchItem): Boolean;

    function CountOpsForCentre(const CentreId: Integer): Integer;

  public
    class function Execute(
      ANodeRepo: TNodeDataRepo;
      const ACentres: TArray<TCentreTreball>;
      AGetNodeTimes: TGetNodeTimesFunc): Boolean;
  end;

implementation

{$R *.dfm}

{ ========================================================= }
{              TDispatchListControl                          }
{ ========================================================= }

constructor TDispatchListControl.Create(AOwner: TComponent);
begin
  inherited;
  DoubleBuffered := True;
  Color := $00FAFAF8;
  FScrollY := 0;
  FHoverRow := -1;
  FNodeRepo := nil;
  FDraggingSB := False;
  FEditMode := False;
  FDraggingRow := False;
  FDragRowIdx := -1;
end;

procedure TDispatchListControl.SetData(ARepo: TNodeDataRepo;
  const AItems: TArray<TDispatchItem>);
begin
  FNodeRepo := ARepo;
  FItems := AItems;
  FScrollY := 0;
  FHoverRow := -1;
  Invalidate;
end;

function TDispatchListControl.MaxScrollY: Integer;
begin
  Result := Max(0, Length(FItems) * ROW_HEIGHT - ClientHeight);
end;

function TDispatchListControl.IsOnScrollbar(const X: Integer): Boolean;
begin
  Result := (X >= ClientWidth - SCROLLBAR_W) and (MaxScrollY > 0);
end;

procedure TDispatchListControl.DrawScrollbar(const ACanvas: TCanvas);
var
  TrackR, ThumbR: TRect;
  Ratio, ThumbH, ThumbY, MxSY: Single;
begin
  MxSY := MaxScrollY;
  if MxSY <= 0 then Exit;

  TrackR := Rect(ClientWidth - SCROLLBAR_W, 0, ClientWidth, ClientHeight);

  // Track
  ACanvas.Brush.Color := $00F0EEEA;
  ACanvas.Pen.Style := psClear;
  ACanvas.FillRect(TrackR);

  // Thumb
  Ratio := ClientHeight / (Length(FItems) * ROW_HEIGHT);
  ThumbH := Max(30, TrackR.Height * Ratio);
  if MxSY > 0 then
    ThumbY := (FScrollY / MxSY) * (TrackR.Height - ThumbH)
  else
    ThumbY := 0;

  ThumbR := Rect(
    TrackR.Left + 3,
    TrackR.Top + Round(ThumbY) + 2,
    TrackR.Right - 3,
    TrackR.Top + Round(ThumbY + ThumbH) - 2);

  ACanvas.Brush.Color := $00C0BEB8;
  ACanvas.RoundRect(ThumbR.Left, ThumbR.Top, ThumbR.Right, ThumbR.Bottom, 6, 6);
  ACanvas.Pen.Style := psSolid;
end;

procedure TDispatchListControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Row: Integer;
begin
  inherited;
  if Button <> mbLeft then Exit;

  if IsOnScrollbar(X) then
  begin
    FDraggingSB := True;
    FSBGrabY := Y;
    FSBGrabScrollY := FScrollY;
    Exit;
  end;

  // Row drag en mode edicio
  if FEditMode then
  begin
    Row := RowAtY(Y);
    if Row >= 0 then
    begin
      FDragRowIdx := Row;
      FDragRowStartY := Y;
      FDragRowCurrentY := Y;
      FDraggingRow := False; // s'activa amb threshold
    end;
  end;
end;

procedure TDispatchListControl.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  InsIdx, OldIdx, I: Integer;
  Tmp: TDispatchItem;
begin
  inherited;

  if FDraggingSB then
  begin
    FDraggingSB := False;
    Exit;
  end;

  // Drop row
  if FDraggingRow and (FDragRowIdx >= 0) and (FDragRowIdx <= High(FItems)) then
  begin
    InsIdx := RowInsertIndex(Y);
    OldIdx := FDragRowIdx;

    if InsIdx <> OldIdx then
    begin
      // Reordenar l'array
      Tmp := FItems[OldIdx];

      if InsIdx > OldIdx then
        Dec(InsIdx);

      // Eliminar de la posicio antiga
      for I := OldIdx to High(FItems) - 1 do
        FItems[I] := FItems[I + 1];
      SetLength(FItems, Length(FItems) - 1);

      // Insertar a la nova posicio
      SetLength(FItems, Length(FItems) + 1);
      for I := High(FItems) downto InsIdx + 1 do
        FItems[I] := FItems[I - 1];
      FItems[InsIdx] := Tmp;
    end;
  end;

  FDraggingRow := False;
  FDragRowIdx := -1;
  Invalidate;
end;

function TDispatchListControl.RowAtY(const Y: Integer): Integer;
var
  Row: Integer;
begin
  Row := (Y + FScrollY) div ROW_HEIGHT;
  if (Row >= 0) and (Row <= High(FItems)) then
    Result := Row
  else
    Result := -1;
end;

function TDispatchListControl.EstadoColor(const E: TNodoEstado): TColor;
begin
  case E of
    nePendiente:  Result := $00B0B0B0;
    neEnCurso:    Result := $00E89040;
    neFinalizado: Result := $0040B040;
    neBloqueado:  Result := $004040E0;
  else Result := $00B0B0B0;
  end;
end;

function TDispatchListControl.EstadoText(const E: TNodoEstado): string;
begin
  case E of
    nePendiente:  Result := 'PENDIENTE';
    neEnCurso:    Result := 'EN CURSO';
    neFinalizado: Result := 'FINALIZADO';
    neBloqueado:  Result := 'BLOQUEADO';
  else Result := '';
  end;
end;

function TDispatchListControl.PrioridadColor(const P: Integer): TColor;
begin
  case P of
    1: Result := $004040FF;
    2: Result := $000080FF;
    3: Result := $00FF8000;
  else Result := $00B0B0B0;
  end;
end;

function TDispatchListControl.PrioridadText(const P: Integer): string;
begin
  case P of
    1: Result := 'ALTA';
    2: Result := 'MEDIA';
    3: Result := 'BAJA';
  else Result := '-';
  end;
end;

function TDispatchListControl.RowInsertIndex(const ScreenY: Integer): Integer;
var
  I, Y: Integer;
begin
  Result := Length(FItems);
  for I := 0 to High(FItems) do
  begin
    Y := I * ROW_HEIGHT - FScrollY + ROW_HEIGHT div 2;
    if ScreenY < Y then
      Exit(I);
  end;
end;

procedure TDispatchListControl.DrawDragRow(const ACanvas: TCanvas);
var
  D: TNodeData;
  GhostR: TRect;
  BF: TBlendFunction;
  OffBmp: TBitmap;
  InsIdx, InsY, I: Integer;
begin
  if not FDraggingRow then Exit;
  if (FDragRowIdx < 0) or (FDragRowIdx > High(FItems)) then Exit;
  if not FNodeRepo.TryGetById(FItems[FDragRowIdx].DataId, D) then Exit;

  // Insertion line
  InsIdx := RowInsertIndex(FDragRowCurrentY);
  if InsIdx <= 0 then
    InsY := -FScrollY
  else if InsIdx > High(FItems) then
    InsY := Length(FItems) * ROW_HEIGHT - FScrollY
  else
    InsY := InsIdx * ROW_HEIGHT - FScrollY;

  ACanvas.Pen.Color := $00E89040;
  ACanvas.Pen.Width := 3;
  ACanvas.MoveTo(10, InsY);
  ACanvas.LineTo(ClientWidth - SCROLLBAR_W - 10, InsY);
  ACanvas.Pen.Width := 1;

  // Ghost row via AlphaBlend
  OffBmp := TBitmap.Create;
  try
    OffBmp.SetSize(ClientWidth - SCROLLBAR_W, ROW_HEIGHT);
    GhostR := Rect(0, 0, OffBmp.Width, ROW_HEIGHT);
    DrawRow(OffBmp.Canvas, FDragRowIdx, GhostR, False);

    BF.BlendOp := AC_SRC_OVER;
    BF.BlendFlags := 0;
    BF.SourceConstantAlpha := 180;
    BF.AlphaFormat := 0;

    var DestY := FDragRowCurrentY - ROW_HEIGHT div 2;
    Winapi.Windows.AlphaBlend(
      ACanvas.Handle, 0, DestY, OffBmp.Width, ROW_HEIGHT,
      OffBmp.Canvas.Handle, 0, 0, OffBmp.Width, ROW_HEIGHT, BF);

    // Border blau
    ACanvas.Pen.Color := $00E89040;
    ACanvas.Pen.Width := 2;
    ACanvas.Brush.Style := bsClear;
    ACanvas.RoundRect(2, DestY, OffBmp.Width - 2, DestY + ROW_HEIGHT, 8, 8);
    ACanvas.Pen.Width := 1;
    ACanvas.Brush.Style := bsSolid;
  finally
    OffBmp.Free;
  end;
end;

procedure TDispatchListControl.Paint;
var
  I, FirstRow, LastRow, Y: Integer;
  RowR: TRect;
begin
  inherited;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  if (FNodeRepo = nil) or (Length(FItems) = 0) then
  begin
    Canvas.Font.Size := 12;
    Canvas.Font.Color := $00AAAAAA;
    Canvas.Font.Style := [];
    Canvas.Brush.Style := bsClear;
    var TR := ClientRect;
    DrawText(Canvas.Handle, 'Sin operaciones para este centro / periodo', -1, TR,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
    Exit;
  end;

  // Determinar filas visibles
  FirstRow := FScrollY div ROW_HEIGHT;
  LastRow := Min(High(FItems), (FScrollY + ClientHeight) div ROW_HEIGHT);

  for I := FirstRow to LastRow do
  begin
    // Skip la fila que s'esta arrossegant
    if FDraggingRow and (I = FDragRowIdx) then Continue;

    Y := I * ROW_HEIGHT - FScrollY;
    RowR := Rect(0, Y, ClientWidth - SCROLLBAR_W, Y + ROW_HEIGHT);
    DrawRow(Canvas, I, RowR, I = FHoverRow);

    // Icona drag handle en mode edicio
    if FEditMode then
    begin
      Canvas.Font.Size := 10;
      Canvas.Font.Color := $00CCCCCC;
      Canvas.Font.Style := [];
      Canvas.Brush.Style := bsClear;
      Canvas.TextOut(RowR.Left + 2, RowR.Top + (ROW_HEIGHT - 14) div 2, #$2261);  // hamburger icon
    end;
  end;

  // Ghost row arrastrada
  DrawDragRow(Canvas);

  // Scrollbar vertical
  DrawScrollbar(Canvas);
end;

procedure TDispatchListControl.DrawRow(const ACanvas: TCanvas;
  const RowIdx: Integer; const ARect: TRect; const IsHover: Boolean);
var
  D: TNodeData;
  Item: TDispatchItem;
  TR, BadgeR, BarR: TRect;
  S: string;
  X, RH: Integer;
  Pct: Single;
begin
  Item := FItems[RowIdx];
  if not FNodeRepo.TryGetById(Item.DataId, D) then Exit;

  RH := ARect.Height;

  // Fondo alternado
  if IsHover then
    ACanvas.Brush.Color := $00F0EDE8
  else if RowIdx mod 2 = 0 then
    ACanvas.Brush.Color := $00FAFAF8
  else
    ACanvas.Brush.Color := $00F4F2EE;
  ACanvas.Pen.Style := psClear;
  ACanvas.FillRect(ARect);
  ACanvas.Pen.Style := psSolid;

  X := ARect.Left;

  // #
  ACanvas.Font.Size := 10;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := $00BBBBBB;
  ACanvas.Brush.Style := bsClear;
  TR := Rect(X + DL_X0, ARect.Top, X + DL_X0 + DL_W0, ARect.Bottom);
  DrawText(ACanvas.Handle, PChar(IntToStr(RowIdx + 1)), -1, TR,
    DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);

  // PRIORIDAD badge
  BadgeR := Rect(X + DL_X1, ARect.Top + (RH - 24) div 2,
                 X + DL_X1 + DL_W1, ARect.Top + (RH + 24) div 2);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := PrioridadColor(D.Prioridad);
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(BadgeR.Left, BadgeR.Top, BadgeR.Right, BadgeR.Bottom, 6, 6);
  ACanvas.Pen.Style := psSolid;
  ACanvas.Font.Size := 8;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := clWhite;
  ACanvas.Brush.Style := bsClear;
  DrawText(ACanvas.Handle, PChar(PrioridadText(D.Prioridad)), -1, BadgeR,
    DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);

  // OF / OPERACION
  ACanvas.Font.Size := 10;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := $00333333;
  S := 'OF ' + IntToStr(D.NumeroOrdenFabricacion);
  if D.Operacion <> '' then S := S + ' - ' + D.Operacion;
  TR := Rect(X + DL_X2, ARect.Top + 6, X + DL_X2 + DL_W2, ARect.Top + 24);
  DrawText(ACanvas.Handle, PChar(S), -1, TR,
    DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);

  ACanvas.Font.Size := 8;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := $00888888;
  S := '';
  if D.CodigoCliente <> '' then S := D.CodigoCliente;
  if D.NumeroPedido > 0 then begin if S <> '' then S := S + ' | '; S := S + 'Ped:' + IntToStr(D.NumeroPedido); end;
  if D.NumeroTrabajo <> '' then begin if S <> '' then S := S + ' | '; S := S + 'OT:' + D.NumeroTrabajo; end;
  TR := Rect(X + DL_X2, ARect.Top + 28, X + DL_X2 + DL_W2, ARect.Top + 44);
  DrawText(ACanvas.Handle, PChar(S), -1, TR,
    DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);

  ACanvas.Font.Size := 7;
  ACanvas.Font.Color := $00AAAAAA;
  S := Format('Op: %d/%d', [D.OperariosAsignados, D.OperariosNecesarios]);
  TR := Rect(X + DL_X2, ARect.Top + 48, X + DL_X2 + DL_W2, ARect.Top + 62);
  DrawText(ACanvas.Handle, PChar(S), -1, TR, DT_SINGLELINE or DT_NOPREFIX);

  // ARTICULO
  ACanvas.Font.Size := 9;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := $00555555;
  TR := Rect(X + DL_X3, ARect.Top + 6, X + DL_X3 + DL_W3, ARect.Top + 24);
  DrawText(ACanvas.Handle, PChar(D.CodigoArticulo), -1, TR,
    DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);

  ACanvas.Font.Size := 8;
  ACanvas.Font.Color := $00888888;
  TR := Rect(X + DL_X3, ARect.Top + 26, X + DL_X3 + DL_W3, ARect.Top + 42);
  DrawText(ACanvas.Handle, PChar(D.DescripcionArticulo), -1, TR,
    DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);

  ACanvas.Font.Size := 7;
  if (D.FechaEntrega > 0) and (D.FechaEntrega < Now) then
    ACanvas.Font.Color := $004040FF
  else
    ACanvas.Font.Color := $00AAAAAA;
  if D.FechaEntrega > 0 then
    S := 'Entrega: ' + FormatDateTime('dd/mm/yyyy', D.FechaEntrega)
  else
    S := '';
  TR := Rect(X + DL_X3, ARect.Top + 46, X + DL_X3 + DL_W3, ARect.Top + 60);
  DrawText(ACanvas.Handle, PChar(S), -1, TR, DT_SINGLELINE or DT_NOPREFIX);

  // INICIO - FIN
  ACanvas.Font.Size := 9;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := $00555555;
  if Item.NodeStartTime > 0 then S := FormatDateTime('dd/mm hh:nn', Item.NodeStartTime) else S := '';
  TR := Rect(X + DL_X4, ARect.Top + 10, X + DL_X4 + DL_W4, ARect.Top + 28);
  DrawText(ACanvas.Handle, PChar(S), -1, TR, DT_SINGLELINE or DT_NOPREFIX);

  ACanvas.Font.Size := 8;
  ACanvas.Font.Color := $00888888;
  if Item.NodeEndTime > 0 then S := FormatDateTime('dd/mm hh:nn', Item.NodeEndTime) else S := '';
  TR := Rect(X + DL_X4, ARect.Top + 32, X + DL_X4 + DL_W4, ARect.Top + 48);
  DrawText(ACanvas.Handle, PChar(S), -1, TR, DT_SINGLELINE or DT_NOPREFIX);

  ACanvas.Font.Size := 7;
  ACanvas.Font.Color := $00AAAAAA;
  if D.DurationMin > 0 then
  begin
    if D.DurationMin >= 60 then S := Format('%.1fh', [D.DurationMin / 60])
    else S := Format('%.0f min', [D.DurationMin]);
    TR := Rect(X + DL_X4, ARect.Top + 50, X + DL_X4 + DL_W4, ARect.Top + 63);
    DrawText(ACanvas.Handle, PChar(S), -1, TR, DT_SINGLELINE or DT_NOPREFIX);
  end;

  // PROGRESO
  if D.UnidadesAFabricar > 0 then
  begin
    Pct := D.UnidadesFabricadas / D.UnidadesAFabricar;
    if Pct > 1 then Pct := 1;
    var ProgH := 12;
    var ProgY := ARect.Top + (RH - ProgH) div 2 - 8;

    BarR := Rect(X + DL_X5, ProgY, X + DL_X5 + DL_W5, ProgY + ProgH);
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := $00E0E0E0;
    ACanvas.Pen.Style := psClear;
    ACanvas.RoundRect(BarR.Left, BarR.Top, BarR.Right, BarR.Bottom, 6, 6);
    if Pct > 0 then
    begin
      if Pct >= 1 then ACanvas.Brush.Color := $0040B040
      else if Pct >= 0.5 then ACanvas.Brush.Color := $0000B0B0
      else ACanvas.Brush.Color := $00E89040;
      ACanvas.RoundRect(BarR.Left, BarR.Top,
        BarR.Left + Max(8, Round(DL_W5 * Pct)), BarR.Bottom, 6, 6);
    end;
    ACanvas.Pen.Style := psSolid;

    ACanvas.Font.Size := 9;
    ACanvas.Font.Style := [fsBold];
    ACanvas.Font.Color := $00555555;
    ACanvas.Brush.Style := bsClear;
    S := Format('%.0f%%', [Pct * 100]);
    TR := Rect(X + DL_X5, ProgY + ProgH + 4, X + DL_X5 + DL_W5, ProgY + ProgH + 20);
    DrawText(ACanvas.Handle, PChar(S), -1, TR,
      DT_SINGLELINE or DT_CENTER or DT_NOPREFIX);

    ACanvas.Font.Size := 7;
    ACanvas.Font.Style := [];
    ACanvas.Font.Color := $00AAAAAA;
    S := Format('%.0f/%.0f', [D.UnidadesFabricadas, D.UnidadesAFabricar]);
    TR := Rect(X + DL_X5, ProgY + ProgH + 18, X + DL_X5 + DL_W5, ProgY + ProgH + 32);
    DrawText(ACanvas.Handle, PChar(S), -1, TR,
      DT_SINGLELINE or DT_CENTER or DT_NOPREFIX);
  end;

  // ESTADO badge
  BadgeR := Rect(X + DL_X6, ARect.Top + (RH - 28) div 2,
                 X + DL_X6 + DL_W6, ARect.Top + (RH + 28) div 2);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := EstadoColor(D.Estado);
  ACanvas.Pen.Style := psClear;
  ACanvas.RoundRect(BadgeR.Left, BadgeR.Top, BadgeR.Right, BadgeR.Bottom, 8, 8);
  ACanvas.Pen.Style := psSolid;
  ACanvas.Font.Size := 9;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := clWhite;
  ACanvas.Brush.Style := bsClear;
  DrawText(ACanvas.Handle, PChar(EstadoText(D.Estado)), -1, BadgeR,
    DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);

  // Separador
  ACanvas.Pen.Color := $00E8E8E8;
  ACanvas.MoveTo(ARect.Left + 8, ARect.Bottom - 1);
  ACanvas.LineTo(ARect.Right - 8, ARect.Bottom - 1);
end;

procedure TDispatchListControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewHover: Integer;
  MxSY: Integer;
begin
  inherited;

  // Scrollbar drag
  if FDraggingSB then
  begin
    MxSY := MaxScrollY;
    if MxSY > 0 then
    begin
      var ContentH: Single := Length(FItems) * ROW_HEIGHT;
      var Ratio: Single := ContentH / ClientHeight;
      FScrollY := Max(0, Min(Round(FSBGrabScrollY + (Y - FSBGrabY) * Ratio), MxSY));
      Invalidate;
    end;
    Exit;
  end;

  // Row drag threshold + tracking
  if FEditMode and (FDragRowIdx >= 0) and not FDraggingRow then
  begin
    if Abs(Y - FDragRowStartY) > 5 then
      FDraggingRow := True;
  end;

  if FDraggingRow then
  begin
    FDragRowCurrentY := Y;
    Invalidate;
    Exit;
  end;

  NewHover := RowAtY(Y);
  if NewHover <> FHoverRow then
  begin
    FHoverRow := NewHover;
    Invalidate;
  end;

  if IsOnScrollbar(X) then
    Cursor := crHandPoint
  else if FEditMode then
    Cursor := crSizeNS
  else
    Cursor := crDefault;
end;

function TDispatchListControl.DoMouseWheel(Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := True;
  FScrollY := Max(0, Min(FScrollY - WheelDelta div 2, MaxScrollY));
  Invalidate;
end;

procedure TDispatchListControl.Resize;
begin
  inherited;
  FScrollY := Max(0, Min(FScrollY, MaxScrollY));
  Invalidate;
end;

{ ========================================================= }
{              TDispatchListForm                             }
{ ========================================================= }

class function TDispatchListForm.Execute(
  ANodeRepo: TNodeDataRepo;
  const ACentres: TArray<TCentreTreball>;
  AGetNodeTimes: TGetNodeTimesFunc): Boolean;
var
  Frm: TDispatchListForm;
begin
  Frm := TDispatchListForm.Create(nil);
  try
    Frm.FNodeRepo := ANodeRepo;
    Frm.FCentres := ACentres;
    Frm.FGetNodeTimes := AGetNodeTimes;

    // Inicialitzar tot el contingut dinamic
    Frm.BuildCentreButtons;
    Frm.UpdateCentreCounters;
    Frm.BuildColumnHeaders;

    // Connectar events dels components DFM
    Frm.pnlEditMode.OnClick := Frm.OnEditModeClick;
    Frm.lblEditMode.OnClick := Frm.OnEditModeClick;

    Frm.pnlPeriodTodo.Tag := Ord(dpTodo);
    Frm.pnlPeriodTodo.OnClick := Frm.OnPeriodClick;
    Frm.lblPeriodTodo.Tag := Ord(dpTodo);
    Frm.lblPeriodTodo.OnClick := Frm.OnPeriodClick;

    Frm.pnlPeriodHoy.Tag := Ord(dpHoy);
    Frm.pnlPeriodHoy.OnClick := Frm.OnPeriodClick;
    Frm.lblPeriodHoy.Tag := Ord(dpHoy);
    Frm.lblPeriodHoy.OnClick := Frm.OnPeriodClick;

    Frm.pnlPeriodManana.Tag := Ord(dpManana);
    Frm.pnlPeriodManana.OnClick := Frm.OnPeriodClick;
    Frm.lblPeriodManana.Tag := Ord(dpManana);
    Frm.lblPeriodManana.OnClick := Frm.OnPeriodClick;

    Frm.pnlPeriodSemana.Tag := Ord(dpEstaSemana);
    Frm.pnlPeriodSemana.OnClick := Frm.OnPeriodClick;
    Frm.lblPeriodSemana.Tag := Ord(dpEstaSemana);
    Frm.lblPeriodSemana.OnClick := Frm.OnPeriodClick;

    Frm.UpdatePeriodButtons;

    // List control
    Frm.FListControl := TDispatchListControl.Create(Frm);
    Frm.FListControl.Parent := Frm.pnlContainer; //Frm;
    Frm.FListControl.Align := alClient;
    Frm.FListControl.FOwnerForm := Frm;

    Frm.UpdateEditModeButton;

    // Seleccionar primer centre
    if Length(ACentres) > 0 then
    begin
      var FirstId := -1;
      for var CI := 0 to High(ACentres) do
        if ACentres[CI].Visible and (ACentres[CI].Id >= 0) then
        begin
          FirstId := ACentres[CI].Id;
          Break;
        end;
      if FirstId >= 0 then
        Frm.SelectCentre(FirstId);
    end;

    Frm.ShowModal;
    Result := True;
  finally
    Frm.Free;
  end;
end;

procedure TDispatchListForm.FormCreate(Sender: TObject);
begin
  FPeriodo := dpTodo;
  FCentreOpCount := TDictionary<Integer, Integer>.Create;
  FSelectedCentreId := -1;
  pnlContainer.Color := Color;
  pnlContainer.Align := alClient;
end;

procedure TDispatchListForm.FormDestroy(Sender: TObject);
begin
  FCentreOpCount.Free;
end;

procedure TDispatchListForm.BuildColumnHeaders;
var
  Lbl: TLabel;
begin
  Lbl := TLabel.Create(Self); Lbl.Parent := pnlColHeader;
  Lbl.SetBounds(DL_X0, 8, DL_W0, 20); Lbl.Caption := '#';
  Lbl.Font.Size := 8; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $00999999;

  Lbl := TLabel.Create(Self); Lbl.Parent := pnlColHeader;
  Lbl.SetBounds(DL_X1, 8, DL_W1, 20); Lbl.Caption := 'PRIO';
  Lbl.Font.Size := 8; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $00999999;

  Lbl := TLabel.Create(Self); Lbl.Parent := pnlColHeader;
  Lbl.SetBounds(DL_X2, 8, DL_W2, 20); Lbl.Caption := 'OF / OPERACI' + #$00D3 + 'N';
  Lbl.Font.Size := 8; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $00999999;

  Lbl := TLabel.Create(Self); Lbl.Parent := pnlColHeader;
  Lbl.SetBounds(DL_X3, 8, DL_W3, 20); Lbl.Caption := 'ART' + #$00CD + 'CULO';
  Lbl.Font.Size := 8; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $00999999;

  Lbl := TLabel.Create(Self); Lbl.Parent := pnlColHeader;
  Lbl.SetBounds(DL_X4, 8, DL_W4, 20); Lbl.Caption := 'INICIO - FIN';
  Lbl.Font.Size := 8; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $00999999;

  Lbl := TLabel.Create(Self); Lbl.Parent := pnlColHeader;
  Lbl.SetBounds(DL_X5, 8, DL_W5 + 14, 20); Lbl.Caption := 'PROGRESO';
  Lbl.Font.Size := 8; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $00999999;

  Lbl := TLabel.Create(Self); Lbl.Parent := pnlColHeader;
  Lbl.SetBounds(DL_X6, 8, DL_W6, 20); Lbl.Caption := 'ESTADO';
  Lbl.Font.Size := 8; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $00999999;
end;

{ ========================================================= }
{                     Centre buttons                         }
{ ========================================================= }

function TDispatchListForm.CountOpsForCentre(const CentreId: Integer): Integer;
var
  AllData: TArray<TNodeData>;
  I, K: Integer;
  D: TNodeData;
  Match: Boolean;
begin
  Result := 0;
  if FNodeRepo = nil then Exit;
  AllData := FNodeRepo.GetAllData;
  for I := 0 to High(AllData) do
  begin
    D := AllData[I];
    if D.Estado = neFinalizado then Continue;
    Match := False;
    if Length(D.CentresPermesos) = 0 then
      Match := True
    else
      for K := 0 to High(D.CentresPermesos) do
        if D.CentresPermesos[K] = CentreId then begin Match := True; Break; end;
    if Match then Inc(Result);
  end;
end;

procedure TDispatchListForm.UpdateCentreCounters;
var
  I: Integer;
begin
  FCentreOpCount.Clear;
  for I := 0 to High(FCentres) do
    if FCentres[I].Visible and (FCentres[I].Id >= 0) then
      FCentreOpCount.AddOrSetValue(FCentres[I].Id, CountOpsForCentre(FCentres[I].Id));
end;

procedure TDispatchListForm.BuildCentreButtons;
var
  I, Cnt: Integer;
  Btn: TPanel;
  LblName, LblSub, LblCount: TLabel;
begin
  for I := 0 to High(FCentres) do
  begin
    if not FCentres[I].Visible then Continue;
    if FCentres[I].Id < 0 then Continue;

    Btn := TPanel.Create(Self);
    Btn.Parent := sbCentres;
    Btn.Align := alTop;
    Btn.Height := 56;
    Btn.BevelOuter := bvNone;
    Btn.Color := $00E8E6E2;
    Btn.Cursor := crHandPoint;
    Btn.Tag := FCentres[I].Id;
    Btn.OnClick := OnCentreButtonClick;
    Btn.ParentBackground := False;

    LblName := TLabel.Create(Btn);
    LblName.Parent := Btn;
    LblName.Left := 14;
    LblName.Top := 8;
    LblName.Width := CENTRE_BTN_WIDTH - 70;
    LblName.Caption := FCentres[I].Titulo;
    LblName.Font.Size := 11;
    LblName.Font.Style := [fsBold];
    LblName.Font.Color := $00444444;
    LblName.OnClick := OnCentreButtonClick;
    LblName.Tag := FCentres[I].Id;
    LblName.Cursor := crHandPoint;

    LblSub := TLabel.Create(Btn);
    LblSub.Parent := Btn;
    LblSub.Left := 14;
    LblSub.Top := 30;
    LblSub.Width := CENTRE_BTN_WIDTH - 70;
    LblSub.Caption := FCentres[I].Subtitulo;
    if LblSub.Caption = '' then LblSub.Caption := FCentres[I].Area;
    LblSub.Font.Size := 8;
    LblSub.Font.Color := $00888888;
    LblSub.OnClick := OnCentreButtonClick;
    LblSub.Tag := FCentres[I].Id;
    LblSub.Cursor := crHandPoint;

    // Contador d'operacions (dreta)
    if FCentreOpCount.TryGetValue(FCentres[I].Id, Cnt) then
    begin
      LblCount := TLabel.Create(Btn);
      LblCount.Parent := Btn;
      LblCount.Left := CENTRE_BTN_WIDTH - 52;
      LblCount.Top := 12;
      LblCount.Width := 36;
      LblCount.Height := 24;
      LblCount.Alignment := taCenter;
      LblCount.Layout := tlCenter;
      LblCount.Caption := IntToStr(Cnt);
      LblCount.Font.Size := 10;
      LblCount.Font.Style := [fsBold];
      LblCount.Font.Color := $00666666;
      LblCount.OnClick := OnCentreButtonClick;
      LblCount.Tag := FCentres[I].Id;
      LblCount.Cursor := crHandPoint;
      LblCount.Name := 'LblCnt_' + IntToStr(FCentres[I].Id);
    end;

    // Separador
    var SepLine := TPanel.Create(Self);
    SepLine.Parent := sbCentres;
    SepLine.Align := alTop;
    SepLine.Height := 1;
    SepLine.BevelOuter := bvNone;
    SepLine.Color := $00D8D6D2;
  end;
end;

procedure TDispatchListForm.OnCentreButtonClick(Sender: TObject);
begin
  if Sender is TControl then
    SelectCentre(TControl(Sender).Tag);
end;

procedure TDispatchListForm.SelectCentre(const CentreId: Integer);
var
  I, J: Integer;
  Ctrl: TControl;
begin
  FSelectedCentreId := CentreId;

  // Highlight botones
  for I := 0 to sbCentres.ControlCount - 1 do
  begin
    Ctrl := sbCentres.Controls[I];
    if not (Ctrl is TPanel) then Continue;
    if TPanel(Ctrl).Height <= 1 then Continue; // separador

    if Ctrl.Tag = CentreId then
      TPanel(Ctrl).Color := $00E89040
    else
      TPanel(Ctrl).Color := $00E8E6E2;

    for J := 0 to TPanel(Ctrl).ControlCount - 1 do
      if TPanel(Ctrl).Controls[J] is TLabel then
      begin
        var Lbl := TLabel(TPanel(Ctrl).Controls[J]);
        if Ctrl.Tag = CentreId then
          Lbl.Font.Color := clWhite
        else if Lbl.Font.Size >= 10 then
          Lbl.Font.Color := $00444444
        else
          Lbl.Font.Color := $00888888;
      end;
  end;

  // Header
  for I := 0 to High(FCentres) do
    if FCentres[I].Id = CentreId then
    begin
      lblCentreName.Caption := FCentres[I].Titulo;
      if FCentres[I].Subtitulo <> '' then
        lblCentreName.Caption := lblCentreName.Caption + '  —  ' + FCentres[I].Subtitulo;
      Break;
    end;

  BuildList;
end;

{ ========================================================= }
{                     Periodo                                }
{ ========================================================= }

procedure TDispatchListForm.OnPeriodClick(Sender: TObject);
begin
  if Sender is TControl then
    FPeriodo := TDispatchPeriodo(TControl(Sender).Tag);
  UpdatePeriodButtons;
  BuildList;
end;

procedure TDispatchListForm.OnEditModeClick(Sender: TObject);
begin
  FListControl.EditMode := not FListControl.EditMode;
  UpdateEditModeButton;
  FListControl.Invalidate;
end;

procedure TDispatchListForm.UpdateEditModeButton;
begin
  if FListControl.EditMode then
  begin
    pnlEditMode.Color := $00E89040;
    lblEditMode.Font.Color := clWhite;
  end
  else
  begin
    pnlEditMode.Color := $00E8E6E2;
    lblEditMode.Font.Color := $00666666;
  end;
end;

procedure TDispatchListForm.UpdatePeriodButtons;

  procedure StyleBtn(APanel: TPanel; ALabel: TLabel; AActive: Boolean);
  begin
    if AActive then
    begin
      APanel.Color := $00E89040;
      ALabel.Font.Color := clWhite;
    end
    else
    begin
      APanel.Color := $00E8E6E2;
      ALabel.Font.Color := $00555555;
    end;
  end;

begin
  StyleBtn(pnlPeriodTodo, lblPeriodTodo, FPeriodo = dpTodo);
  StyleBtn(pnlPeriodHoy, lblPeriodHoy, FPeriodo = dpHoy);
  StyleBtn(pnlPeriodManana, lblPeriodManana, FPeriodo = dpManana);
  StyleBtn(pnlPeriodSemana, lblPeriodSemana, FPeriodo = dpEstaSemana);
end;

function TDispatchListForm.ItemMatchesPeriod(const Item: TDispatchItem): Boolean;
var
  Today, Tomorrow, WeekEnd: TDateTime;
begin
  case FPeriodo of
    dpTodo:
      Result := True;
    dpHoy:
      begin
        Today := DateOf(Now);
        Result := (Item.NodeStartTime >= Today) and
                  (Item.NodeStartTime < Today + 1);
      end;
    dpManana:
      begin
        Tomorrow := DateOf(Now) + 1;
        Result := (Item.NodeStartTime >= DateOf(Now)) and
                  (Item.NodeStartTime < Tomorrow + 1);
      end;
    dpEstaSemana:
      begin
        Today := DateOf(Now);
        WeekEnd := Today + (7 - DayOfTheWeek(Today));
        Result := (Item.NodeStartTime >= Today) and
                  (Item.NodeStartTime < WeekEnd + 1);
      end;
  else
    Result := True;
  end;
end;

{ ========================================================= }
{                     Build list                             }
{ ========================================================= }

procedure TDispatchListForm.BuildList;
var
  AllData: TArray<TNodeData>;
  D: TNodeData;
  Item: TDispatchItem;
  I, K: Integer;
  SortList: TList<TDispatchItem>;
  Match: Boolean;
begin
  if FNodeRepo = nil then Exit;

  SortList := TList<TDispatchItem>.Create;
  try
    AllData := FNodeRepo.GetAllData;
    for I := 0 to High(AllData) do
    begin
      D := AllData[I];
      if D.Estado = neFinalizado then Continue;

      Match := False;
      if Length(D.CentresPermesos) = 0 then
        Match := True
      else
        for K := 0 to High(D.CentresPermesos) do
          if D.CentresPermesos[K] = FSelectedCentreId then
          begin Match := True; Break; end;
      if not Match then Continue;

      FillChar(Item, SizeOf(Item), 0);
      Item.DataId := D.DataId;
      if Assigned(FGetNodeTimes) then
        FGetNodeTimes(D.DataId, Item.NodeStartTime, Item.NodeEndTime);

      // Filtrar per periodo
      if not ItemMatchesPeriod(Item) then Continue;

      SortList.Add(Item);
    end;

    SortList.Sort(TComparer<TDispatchItem>.Construct(
      function(const A, B: TDispatchItem): Integer
      var DA, DB: TNodeData; PA, PB: Integer;
      begin
        PA := 99; PB := 99;
        if FNodeRepo.TryGetById(A.DataId, DA) then PA := DA.Prioridad;
        if FNodeRepo.TryGetById(B.DataId, DB) then PB := DB.Prioridad;
        Result := PA - PB;
        if Result = 0 then
        begin
          if A.NodeStartTime < B.NodeStartTime then Result := -1
          else if A.NodeStartTime > B.NodeStartTime then Result := 1
          else Result := 0;
        end;
      end));

    lblCount.Caption := IntToStr(SortList.Count) + ' operaciones';
    FListControl.SetData(FNodeRepo, SortList.ToArray);
  finally
    SortList.Free;
  end;
end;

end.
