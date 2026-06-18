unit uGanttHistoryTimeline;

// Timeline visual del historico de cambios del Gantt.
// Se abre desde el boton "Deshacer" de la Vista Gantt. Muestra en una lista
// con scroll todas las acciones registradas (aplicadas + deshechas), un marcador
// de la posicion actual y un contador "Cambio N de M". Al hacer clic en un paso
// el plan navega (undo/redo en cadena) hasta dejarlo en ese punto.

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  Winapi.Windows, Winapi.Messages,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  uGanttControl, uGanttHistory;

type
  TfrmGanttHistoryTimeline = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblContador: TLabel;
    lstPasos: TListBox;
    pnlBottom: TPanel;
    btnDeshacer: TButton;
    btnRehacer: TButton;
    btnCerrar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lstPasosDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lstPasosClick(Sender: TObject);
    procedure lstPasosDblClick(Sender: TObject);
    procedure btnDeshacerClick(Sender: TObject);
    procedure btnRehacerClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FGantt: TGanttControl;
    // Total de pasos = UndoCount + RedoCount. El item visual de indice I (0-based)
    // representa el "paso" I+1. Los pasos 1..UndoCount estan aplicados; el resto,
    // deshechos. Item especial al inicio: "Estado inicial" (paso 0).
    procedure RefreshList;
    function StepCaption(const AEntry: TGanttHistoryEntry): string;
    function StepActionName(const AType: TGanttHistoryActionType): string;
    function CurrentUndoCount: Integer;
    function TotalSteps: Integer;
    procedure JumpToItem(const AItemIndex: Integer);
  public
    class procedure Execute(AOwner: TForm; AGantt: TGanttControl;
      const ANearControl: TControl = nil);
  end;

implementation

{$R *.dfm}

const
  // Colores
  CLR_APLICADO   = TColor($00333333); // texto oscuro
  CLR_DESHECHO   = TColor($00999999); // gris (acciones rehacibles)
  CLR_MARCADOR   = TColor($002F8FED); // azul posicion actual
  CLR_SELBG      = TColor($00F4E8D8); // fondo seleccion suave
  CLR_HORA       = TColor($00808080);

{ TfrmGanttHistoryTimeline }

class procedure TfrmGanttHistoryTimeline.Execute(AOwner: TForm;
  AGantt: TGanttControl; const ANearControl: TControl);
var
  Frm: TfrmGanttHistoryTimeline;
  P: TPoint;
begin
  if not Assigned(AGantt) then Exit;

  Frm := TfrmGanttHistoryTimeline.Create(AOwner);
  try
    Frm.FGantt := AGantt;

    // Posicionar cerca del control que lo invoca (el boton Deshacer), si se da.
    if Assigned(ANearControl) and Assigned(ANearControl.Parent) then
    begin
      P := ANearControl.ClientToScreen(Point(0, ANearControl.Height + 2));
      Frm.Position := poDesigned;
      Frm.Left := P.X;
      Frm.Top := P.Y;
    end
    else
      Frm.Position := poOwnerFormCenter;

    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

procedure TfrmGanttHistoryTimeline.FormCreate(Sender: TObject);
begin
  // Nada por ahora: parametros via FGantt asignado en Execute, lista en OnShow.
end;

procedure TfrmGanttHistoryTimeline.FormShow(Sender: TObject);
begin
  RefreshList;
end;

function TfrmGanttHistoryTimeline.CurrentUndoCount: Integer;
begin
  if Assigned(FGantt) then
    Result := FGantt.UndoCount
  else
    Result := 0;
end;

function TfrmGanttHistoryTimeline.TotalSteps: Integer;
begin
  if Assigned(FGantt) then
    Result := FGantt.UndoCount + FGantt.RedoCount
  else
    Result := 0;
end;

function TfrmGanttHistoryTimeline.StepActionName(
  const AType: TGanttHistoryActionType): string;
begin
  case AType of
    hatMove:               Result := 'Mover';
    hatResize:             Result := 'Redimensionar';
    hatShiftLeft:          Result := 'Desplazar a la izquierda';
    hatShiftRight:         Result := 'Desplazar a la derecha';
    hatResolveConstraints: Result := 'Resolver dependencias';
    hatEdit:               Result := 'Editar';
    hatResetDuration:      Result := 'Restaurar duracion';
    hatCompactOF:          Result := 'Compactar OF';
    hatCompactOT:          Result := 'Compactar OT';
    hatBackwardOF:         Result := 'Planificar hacia atras (OF)';
    hatBackwardOT:         Result := 'Planificar hacia atras (OT)';
    hatReplanAll:          Result := 'Replanificar todo';
    hatChangeCentre:       Result := 'Cambiar de centro';
    hatCreateLote:         Result := 'Agrupar en lote';
    hatBreakLote:          Result := 'Deshacer lote';
    hatEditNode:           Result := 'Editar nodo';
  else
    Result := 'Cambio';
  end;
end;

function TfrmGanttHistoryTimeline.StepCaption(
  const AEntry: TGanttHistoryEntry): string;
var
  N: Integer;
begin
  if AEntry = nil then
  begin
    Result := 'Cambio';
    Exit;
  end;
  if AEntry.Caption <> '' then
    Result := AEntry.Caption
  else
    Result := StepActionName(AEntry.ActionType);

  N := Length(AEntry.Changes);
  if N > 0 then
    Result := Result + Format(' (%d nodos)', [N]);
end;

procedure TfrmGanttHistoryTimeline.RefreshList;
var
  i, Total, Cur: Integer;
begin
  Total := TotalSteps;
  Cur := CurrentUndoCount;

  lstPasos.Items.BeginUpdate;
  try
    lstPasos.Clear;
    // Item 0 => "Estado inicial" (paso 0, antes del primer cambio).
    lstPasos.Items.Add('__INICIAL__');
    // Items 1..Total => cada accion del historico, mas antigua arriba.
    for i := 1 to Total do
      lstPasos.Items.Add(IntToStr(i));
  finally
    lstPasos.Items.EndUpdate;
  end;

  // Seleccionar el item que representa la posicion actual (Cur).
  if (Cur >= 0) and (Cur < lstPasos.Items.Count) then
    lstPasos.ItemIndex := Cur;

  // Contador en la cabecera.
  if Total = 0 then
    lblContador.Caption := 'Sin cambios registrados'
  else
    lblContador.Caption := Format('Cambio %d de %d', [Cur, Total]);

  btnDeshacer.Enabled := Assigned(FGantt) and FGantt.CanUndo;
  btnRehacer.Enabled  := Assigned(FGantt) and FGantt.CanRedo;

  lstPasos.Invalidate;
end;

procedure TfrmGanttHistoryTimeline.lstPasosDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Cv: TCanvas;
  StepNo, Cur: Integer;
  Entry: TGanttHistoryEntry;
  Aplicado: Boolean;
  Txt, HoraTxt: string;
  TxtRect: TRect;
  DotY, DotX: Integer;
begin
  Cv := lstPasos.Canvas;
  if not Assigned(FGantt) then Exit;
  Cur := CurrentUndoCount;
  StepNo := Index; // item 0 = paso 0 (inicial); item I = paso I

  // Fondo
  if odSelected in State then
    Cv.Brush.Color := CLR_SELBG
  else
    Cv.Brush.Color := clWindow;
  Cv.FillRect(Rect);

  // Punto / linea vertical de timeline a la izquierda
  DotX := Rect.Left + 14;
  DotY := (Rect.Top + Rect.Bottom) div 2;
  // linea conectora
  Cv.Pen.Color := TColor($00D8D8D8);
  Cv.MoveTo(DotX, Rect.Top);
  Cv.LineTo(DotX, Rect.Bottom);

  Aplicado := StepNo <= Cur;

  // Punto: relleno azul si es la posicion actual, relleno oscuro si aplicado,
  // hueco gris si deshecho.
  if StepNo = Cur then
  begin
    Cv.Brush.Color := CLR_MARCADOR;
    Cv.Pen.Color := CLR_MARCADOR;
    Cv.Ellipse(DotX - 6, DotY - 6, DotX + 6, DotY + 6);
  end
  else if Aplicado then
  begin
    Cv.Brush.Color := CLR_APLICADO;
    Cv.Pen.Color := CLR_APLICADO;
    Cv.Ellipse(DotX - 4, DotY - 4, DotX + 4, DotY + 4);
  end
  else
  begin
    Cv.Brush.Color := clWindow;
    Cv.Pen.Color := CLR_DESHECHO;
    Cv.Ellipse(DotX - 4, DotY - 4, DotX + 4, DotY + 4);
  end;

  // Texto
  TxtRect := Rect;
  TxtRect.Left := DotX + 16;
  TxtRect.Right := TxtRect.Right - 6;

  Cv.Brush.Style := bsClear;
  HoraTxt := '';

  if StepNo = 0 then
  begin
    Txt := 'Estado inicial';
    if Aplicado then Cv.Font.Color := CLR_APLICADO
    else Cv.Font.Color := CLR_DESHECHO;
  end
  else
  begin
    // El stack de undo guarda 1..UndoCount (0=mas antiguo). El de redo guarda
    // las acciones deshechas, con la mas reciente deshecha en su tope.
    if Aplicado then
    begin
      Entry := FGantt.History.GetUndoEntry(StepNo - 1);
      Cv.Font.Color := CLR_APLICADO;
    end
    else
    begin
      // Paso StepNo (> Cur). Acciones deshechas: el paso Cur+1 es el ultimo
      // deshecho = tope de redo (indice RedoCount-1). El paso Total es el
      // primero que se deshizo (indice 0 de redo).
      Entry := FGantt.History.GetRedoEntry(TotalSteps - StepNo);
      Cv.Font.Color := CLR_DESHECHO;
    end;

    Txt := Format('%d. %s', [StepNo, StepCaption(Entry)]);
    if Entry <> nil then
      HoraTxt := FormatDateTime('hh:nn:ss', Entry.TimeStamp);
  end;

  if StepNo = Cur then
  begin
    Cv.Font.Style := [fsBold];
    Cv.Font.Color := CLR_MARCADOR;
  end
  else
    Cv.Font.Style := [];

  // Caption (linea superior)
  Cv.TextRect(TxtRect, TxtRect.Left, Rect.Top + 6, Txt);

  // Hora (linea inferior, gris)
  if HoraTxt <> '' then
  begin
    Cv.Font.Style := [];
    Cv.Font.Color := CLR_HORA;
    Cv.TextRect(TxtRect, TxtRect.Left, Rect.Top + 24, HoraTxt);
  end;

  Cv.Brush.Style := bsSolid;
end;

procedure TfrmGanttHistoryTimeline.JumpToItem(const AItemIndex: Integer);
begin
  if not Assigned(FGantt) then Exit;
  if AItemIndex < 0 then Exit;
  // El item I representa el paso I => dejar I acciones aplicadas.
  FGantt.JumpToHistoryStep(AItemIndex);
  RefreshList;
end;

procedure TfrmGanttHistoryTimeline.lstPasosClick(Sender: TObject);
begin
  // Solo navega con doble clic para evitar saltos accidentales al hacer scroll
  // con seleccion de teclado. (Se deja Click vacio a proposito.)
end;

procedure TfrmGanttHistoryTimeline.lstPasosDblClick(Sender: TObject);
begin
  JumpToItem(lstPasos.ItemIndex);
end;

procedure TfrmGanttHistoryTimeline.btnDeshacerClick(Sender: TObject);
begin
  if Assigned(FGantt) and FGantt.CanUndo then
  begin
    FGantt.UndoLastAction;
    RefreshList;
  end;
end;

procedure TfrmGanttHistoryTimeline.btnRehacerClick(Sender: TObject);
begin
  if Assigned(FGantt) and FGantt.CanRedo then
  begin
    FGantt.RedoLastAction;
    RefreshList;
  end;
end;

procedure TfrmGanttHistoryTimeline.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
