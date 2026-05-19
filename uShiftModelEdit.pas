unit uShiftModelEdit;

// ============================================================================
// Editor visual de un modelo horario (FS_PL_ShiftModel + FS_PL_ShiftModelLine).
//
// Vista: graella 7 dias x 24 horas. El usuario pinta arrastrando con boton
// izquierdo (laborable=verde) o derecho (no laborable=gris). Al guardar,
// las franjas laborables se persisten como lineas del modelo y el repo
// reproyecta el FS_PL_CalendarDayRule del calendario.
// ============================================================================

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.UITypes, System.DateUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Menus,
  uCalendarsRepo;

type
  TfrmShiftModelEdit = class(TForm)
    pnlTop: TPanel;
    lblNombre: TLabel;
    edNombre: TEdit;
    lblDescripcion: TLabel;
    edDescripcion: TEdit;
    btnFill24: TButton;
    btnFillL_V: TButton;
    btnClear: TButton;
    lblPrecision: TLabel;
    cbPrecision: TComboBox;
    btnZoomOut: TButton;
    btnZoomFit: TButton;
    btnZoomIn: TButton;
    sbHorz: TScrollBar;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    pnlInfo: TPanel;
    lblLeyenda: TLabel;
    lblHover: TLabel;
    lblKPIs: TLabel;
    pbGrid: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pbGridPaint(Sender: TObject);
    procedure pbGridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbGridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbGridMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnFill24Click(Sender: TObject);
    procedure btnFillLVClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure cbPrecisionChange(Sender: TObject);
    procedure btnZoomOutClick(Sender: TObject);
    procedure btnZoomFitClick(Sender: TObject);
    procedure btnZoomInClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure sbHorzChange(Sender: TObject);
  private
    FRepo: TCalendarsRepo;
    FCodigoEmpresa: SmallInt;
    FCalendarId: Integer;
    FShiftModelId: Integer;
    FEsNuevo: Boolean;

    // 7 dias (1..7) x 1440 slots de 1 min = True si laborable (model intern fix)
    FMask: array of array of Boolean;  // [0..7, 0..1439] - usem 1..7

    // Snap d'edicio (5/10/15/30 min) - nomes afecta quantitzacio del drag
    FSnapMin: Integer;

    // Zoom de visualitzacio: pixels per hora. 0 = auto-fit.
    FPixelsPerHour: Single;
    FAutoFit: Boolean;
    FScrollOffsetMin: Integer;  // minuts desplacats a l'esquerra (per scrollbar)

    FPainting: Boolean;
    FPaintValue: Boolean;
    FLastDia, FLastSlot: Integer;

    // Hover (rectangle marc fi sota el cursor)
    FHoverDia, FHoverSlot: Integer;
    FHoverHeaderDia: Integer;  // 0 si no hover sobre header

    // Menu contextual sobre cap'salera de dies
    FDiaMenu: TPopupMenu;
    FDiaMenuTargetDia: Integer;
    FClipDia: Integer;
    FClipMask: array of Boolean;  // 1440 slots

    procedure SetSnap(ANewSnapMin: Integer);
    procedure SetZoomAutoFit;
    procedure SetZoomDelta(AFactor: Single);
    procedure UpdateScrollBar;
    function VisibleWidth: Integer;
    function TotalContentWidth: Integer;
    procedure ShowDiaMenuFor(ADia: Integer; AAtX, AAtY: Integer);
    function HitTestHeaderIcon(X, Y: Integer; out ADia: Integer): Boolean;
    function DayHeaderIconRect(ADia: Integer): TRect;

    procedure BuildDiaMenu;
    procedure MenuCopiarDiaClick(Sender: TObject);
    procedure MenuPegarDiaClick(Sender: TObject);
    procedure MenuCopiarALVClick(Sender: TObject);
    procedure MenuCopiarASabDomClick(Sender: TObject);
    procedure MenuCopiarATodosClick(Sender: TObject);
    procedure MenuLimpiarDiaClick(Sender: TObject);
    procedure CopiarMaskADias(const ASrcDia: Integer; const ADestDias: array of Integer);

    procedure LoadLines;
    procedure UpdateKPIs;
    function HitTest(X, Y: Integer; out ADia, ASlot: Integer): Boolean;
    function HitTestDayHeader(X, Y: Integer; out ADia: Integer): Boolean;
    function SlotRect(ADia, ASlot: Integer): TRect;
    function HeaderColWidth: Integer;
    function RightLegendWidth: Integer;
    function HeaderRowHeight: Integer;
    function SlotWidth: Integer;
    function RowHeight: Integer;
    function CollectLines: TArray<TShiftModelLineRec>;
  public
    class function Execute(ARepo: TCalendarsRepo; ACodigoEmpresa: SmallInt;
      ACalendarId: Integer; AShiftModelId: Integer): Boolean;
  end;

implementation

{$R *.dfm}

const
  DEF_SLOT_MIN = 15;
  DAY_NAMES: array[1..7] of string =
    ('Lunes', 'Martes', 'Mi'#233'rcoles', 'Jueves', 'Viernes', 'S'#225'bado', 'Domingo');

class function TfrmShiftModelEdit.Execute(ARepo: TCalendarsRepo;
  ACodigoEmpresa: SmallInt; ACalendarId: Integer; AShiftModelId: Integer): Boolean;
var
  F: TfrmShiftModelEdit;
begin
  F := TfrmShiftModelEdit.Create(Application);
  try
    F.FRepo := ARepo;
    F.FCodigoEmpresa := ACodigoEmpresa;
    F.FCalendarId := ACalendarId;
    F.FShiftModelId := AShiftModelId;
    F.FEsNuevo := (AShiftModelId <= 0);
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TfrmShiftModelEdit.FormCreate(Sender: TObject);
var
  d, s: Integer;
begin
  DoubleBuffered := True;

  FSnapMin := DEF_SLOT_MIN;
  FAutoFit := True;
  FPixelsPerHour := 0;  // recalculat a SetZoomAutoFit

  SetLength(FMask, 8);
  for d := 0 to 7 do
  begin
    SetLength(FMask[d], 1440);
    for s := 0 to 1439 do
      FMask[d, s] := False;
  end;
  SetLength(FClipMask, 1440);

  FHoverDia := 0;
  FHoverSlot := -1;
  FHoverHeaderDia := 0;
  FClipDia := -1;
  FScrollOffsetMin := 0;

  BuildDiaMenu;
end;

procedure TfrmShiftModelEdit.FormShow(Sender: TObject);
begin
  if pbGrid.Parent <> nil then
    pbGrid.Parent.DoubleBuffered := True;

  if cbPrecision <> nil then
  begin
    if cbPrecision.Items.Count = 0 then
    begin
      cbPrecision.Items.Add('1 min');
      cbPrecision.Items.Add('5 min');
      cbPrecision.Items.Add('10 min');
      cbPrecision.Items.Add('15 min');
      cbPrecision.Items.Add('30 min');
      cbPrecision.Items.Add('60 min');
    end;
    cbPrecision.ItemIndex := 3;  // 15 min per defecte
  end;

  LoadLines;
  SetZoomAutoFit;
end;

procedure TfrmShiftModelEdit.SetSnap(ANewSnapMin: Integer);
const
  MIN_PX_PER_SNAP = 3;  // sota d'aixo el snap no es distingeix
var
  CurPxPerSnap: Single;
  TargetPx: Single;
begin
  if ANewSnapMin <= 0 then Exit;
  FSnapMin := ANewSnapMin;

  // Si el zoom actual no permet veure el snap, augmentar zoom auto.
  if FPixelsPerHour > 0 then
  begin
    CurPxPerSnap := FPixelsPerHour * ANewSnapMin / 60.0;
    if CurPxPerSnap < MIN_PX_PER_SNAP then
    begin
      TargetPx := MIN_PX_PER_SNAP * 60.0 / ANewSnapMin;
      if TargetPx > 240 then TargetPx := 240;
      FPixelsPerHour := TargetPx;
      FAutoFit := False;
    end;
  end;

  UpdateScrollBar;
  pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.SetZoomAutoFit;
var
  AvailW: Integer;
begin
  FAutoFit := True;
  AvailW := VisibleWidth;
  if AvailW < 24 then AvailW := 24;
  FPixelsPerHour := AvailW / 24.0;
  FScrollOffsetMin := 0;
  UpdateScrollBar;
  pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.SetZoomDelta(AFactor: Single);
begin
  FAutoFit := False;
  if FPixelsPerHour <= 0 then SetZoomAutoFit;
  FPixelsPerHour := FPixelsPerHour * AFactor;
  if FPixelsPerHour < 8  then FPixelsPerHour := 8;
  if FPixelsPerHour > 240 then FPixelsPerHour := 240;
  UpdateScrollBar;
  pbGrid.Invalidate;
end;

function TfrmShiftModelEdit.VisibleWidth: Integer;
begin
  // Ample disponible per a la zona de slots (sense headers ni llegenda)
  Result := pbGrid.Width - HeaderColWidth - RightLegendWidth - 4;
  if Result < 24 then Result := 24;
end;

function TfrmShiftModelEdit.TotalContentWidth: Integer;
begin
  Result := Round(24 * FPixelsPerHour);
end;

procedure TfrmShiftModelEdit.UpdateScrollBar;
var
  Total, Visible, MaxOffsetMin: Integer;
begin
  if sbHorz = nil then Exit;
  Total := TotalContentWidth;
  Visible := VisibleWidth;

  if Total <= Visible then
  begin
    sbHorz.Visible := False;
    FScrollOffsetMin := 0;
    Exit;
  end;

  sbHorz.Visible := True;
  // Treballem amb minuts a la scrollbar (range = 0..1440 - visibleMin)
  // visibleMin = minuts que es veuen en pantalla
  MaxOffsetMin := 1440 - Round(Visible * 60.0 / FPixelsPerHour);
  if MaxOffsetMin < 1 then MaxOffsetMin := 1;

  sbHorz.Min := 0;
  sbHorz.Max := MaxOffsetMin + 60;  // +pageSize per evitar ofuscacio
  sbHorz.PageSize := 60;
  sbHorz.LargeChange := 60;
  sbHorz.SmallChange := FSnapMin;

  if FScrollOffsetMin > MaxOffsetMin then
    FScrollOffsetMin := MaxOffsetMin;
  if FScrollOffsetMin < 0 then FScrollOffsetMin := 0;
  sbHorz.Position := FScrollOffsetMin;
end;

procedure TfrmShiftModelEdit.sbHorzChange(Sender: TObject);
begin
  FScrollOffsetMin := sbHorz.Position;
  pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.cbPrecisionChange(Sender: TObject);
var
  NewSnap: Integer;
begin
  case cbPrecision.ItemIndex of
    0: NewSnap := 1;
    1: NewSnap := 5;
    2: NewSnap := 10;
    3: NewSnap := 15;
    4: NewSnap := 30;
    5: NewSnap := 60;
  else
    NewSnap := 15;
  end;
  SetSnap(NewSnap);
end;

procedure TfrmShiftModelEdit.BuildDiaMenu;
var
  Mi: TMenuItem;
begin
  FDiaMenu := TPopupMenu.Create(Self);

  Mi := TMenuItem.Create(FDiaMenu);
  Mi.Caption := 'Copiar este d'#237'a';
  Mi.OnClick := MenuCopiarDiaClick;
  FDiaMenu.Items.Add(Mi);

  Mi := TMenuItem.Create(FDiaMenu);
  Mi.Caption := 'Pegar en este d'#237'a';
  Mi.OnClick := MenuPegarDiaClick;
  FDiaMenu.Items.Add(Mi);

  Mi := TMenuItem.Create(FDiaMenu);
  Mi.Caption := '-';
  FDiaMenu.Items.Add(Mi);

  Mi := TMenuItem.Create(FDiaMenu);
  Mi.Caption := 'Copiar este d'#237'a a L-V';
  Mi.OnClick := MenuCopiarALVClick;
  FDiaMenu.Items.Add(Mi);

  Mi := TMenuItem.Create(FDiaMenu);
  Mi.Caption := 'Copiar este d'#237'a a S-D';
  Mi.OnClick := MenuCopiarASabDomClick;
  FDiaMenu.Items.Add(Mi);

  Mi := TMenuItem.Create(FDiaMenu);
  Mi.Caption := 'Copiar este d'#237'a a TODA la semana';
  Mi.OnClick := MenuCopiarATodosClick;
  FDiaMenu.Items.Add(Mi);

  Mi := TMenuItem.Create(FDiaMenu);
  Mi.Caption := '-';
  FDiaMenu.Items.Add(Mi);

  Mi := TMenuItem.Create(FDiaMenu);
  Mi.Caption := 'Limpiar este d'#237'a';
  Mi.OnClick := MenuLimpiarDiaClick;
  FDiaMenu.Items.Add(Mi);
end;

procedure TfrmShiftModelEdit.CopiarMaskADias(const ASrcDia: Integer;
  const ADestDias: array of Integer);
var
  i, s: Integer;
begin
  if (ASrcDia < 1) or (ASrcDia > 7) then Exit;
  for i := Low(ADestDias) to High(ADestDias) do
    if (ADestDias[i] >= 1) and (ADestDias[i] <= 7) and (ADestDias[i] <> ASrcDia) then
      for s := 0 to 1439 do
        FMask[ADestDias[i], s] := FMask[ASrcDia, s];
  pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.MenuCopiarDiaClick(Sender: TObject);
var
  s: Integer;
begin
  if (FDiaMenuTargetDia < 1) or (FDiaMenuTargetDia > 7) then Exit;
  FClipDia := FDiaMenuTargetDia;
  for s := 0 to 1439 do
    FClipMask[s] := FMask[FClipDia, s];
end;

procedure TfrmShiftModelEdit.MenuPegarDiaClick(Sender: TObject);
var
  s: Integer;
begin
  if FClipDia < 0 then
  begin
    ShowMessage('Primero usa "Copiar este d'#237'a" sobre el d'#237'a origen.');
    Exit;
  end;
  if (FDiaMenuTargetDia < 1) or (FDiaMenuTargetDia > 7) then Exit;
  for s := 0 to 1439 do
    FMask[FDiaMenuTargetDia, s] := FClipMask[s];
  pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.MenuCopiarALVClick(Sender: TObject);
begin
  CopiarMaskADias(FDiaMenuTargetDia, [1, 2, 3, 4, 5]);
end;

procedure TfrmShiftModelEdit.MenuCopiarASabDomClick(Sender: TObject);
begin
  CopiarMaskADias(FDiaMenuTargetDia, [6, 7]);
end;

procedure TfrmShiftModelEdit.MenuCopiarATodosClick(Sender: TObject);
begin
  CopiarMaskADias(FDiaMenuTargetDia, [1, 2, 3, 4, 5, 6, 7]);
end;

procedure TfrmShiftModelEdit.MenuLimpiarDiaClick(Sender: TObject);
var
  s: Integer;
begin
  if (FDiaMenuTargetDia < 1) or (FDiaMenuTargetDia > 7) then Exit;
  for s := 0 to 1439 do
    FMask[FDiaMenuTargetDia, s] := False;
  pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.LoadLines;
var
  Lines: TArray<TShiftModelLineRec>;
  Models: TArray<TShiftModelRec>;
  i, d, mStart, mEnd, s: Integer;
  L: TShiftModelLineRec;
begin
  if not FEsNuevo then
  begin
    Models := FRepo.LoadShiftModels(FCodigoEmpresa, FCalendarId);
    for i := 0 to High(Models) do
      if Models[i].ShiftModelId = FShiftModelId then
      begin
        edNombre.Text := Models[i].Nombre;
        edDescripcion.Text := Models[i].Descripcion;
        Break;
      end;

    Lines := FRepo.LoadShiftModelLines(FCodigoEmpresa, FShiftModelId);
    for i := 0 to High(Lines) do
    begin
      L := Lines[i];
      d := L.DiaSemana;
      if (d < 1) or (d > 7) then Continue;
      mStart := Round(L.HoraInicio * 1440);
      mEnd   := Round(L.HoraFin    * 1440);
      if mStart < 0 then mStart := 0;
      if mEnd > 1440 then mEnd := 1440;
      for s := mStart to mEnd - 1 do
        FMask[d, s] := True;
    end;
  end
  else
  begin
    edNombre.Text := 'Nuevo modelo';
    edDescripcion.Text := '';
  end;

  pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.UpdateKPIs;
var
  d, s, CntLab, CntDays: Integer;
  HorasLab, HorasNoLab, HorasMax: Double;
  PctLab: Double;
begin
  if Length(FMask) < 8 then Exit;

  CntLab := 0;
  CntDays := 0;
  for d := 1 to 7 do
  begin
    for s := 0 to 1439 do
      if FMask[d, s] then Inc(CntLab);
    for s := 0 to 1439 do
      if FMask[d, s] then
      begin
        Inc(CntDays);
        Break;
      end;
  end;

  HorasMax   := 168;
  HorasLab   := CntLab / 60.0;
  HorasNoLab := HorasMax - HorasLab;
  PctLab := HorasLab * 100 / HorasMax;

  lblKPIs.Caption := Format(
    'Semana:  %.1f h laborables  (%.1f%%)   '#9474'   ' +
    '%.1f h no laborables   '#9474'   ' +
    '%d d'#237'as con horario   '#9474'   ' +
    'Total: %.0f h',
    [HorasLab, PctLab, HorasNoLab, CntDays, HorasMax]);
end;

function TfrmShiftModelEdit.HeaderColWidth: Integer;
begin
  Result := 100;
end;

function TfrmShiftModelEdit.RightLegendWidth: Integer;
begin
  Result := 90;
end;

function TfrmShiftModelEdit.HeaderRowHeight: Integer;
begin
  Result := 24;
end;

function TfrmShiftModelEdit.SlotWidth: Integer;
begin
  // 1 minut en pixels (minim 1 per evitar zero)
  Result := Max(1, Round(FPixelsPerHour / 60.0));
end;

function TfrmShiftModelEdit.RowHeight: Integer;
var
  AvailH: Integer;
begin
  AvailH := pbGrid.Height - HeaderRowHeight - 2;
  Result := Max(20, AvailH div 7);
end;

function TfrmShiftModelEdit.SlotRect(ADia, ASlot: Integer): TRect;
var
  X1, X2, Y: Integer;
begin
  // Calcular per posicio real per evitar errors d'arrodoniment quan minut<1px
  X1 := HeaderColWidth + Round(ASlot * FPixelsPerHour / 60.0);
  X2 := HeaderColWidth + Round((ASlot + 1) * FPixelsPerHour / 60.0);
  if X2 <= X1 then X2 := X1 + 1;
  Y := HeaderRowHeight + (ADia - 1) * RowHeight;
  Result := Rect(X1, Y, X2, Y + RowHeight);
end;

function TfrmShiftModelEdit.HitTest(X, Y: Integer; out ADia, ASlot: Integer): Boolean;
var
  RelX, Minute: Integer;
begin
  Result := False;
  if (X < HeaderColWidth) or (Y < HeaderRowHeight) then Exit;
  if FPixelsPerHour <= 0 then Exit;
  RelX := X - HeaderColWidth;
  Minute := Round(RelX * 60.0 / FPixelsPerHour) + FScrollOffsetMin;
  if Minute < 0 then Minute := 0;
  if Minute > 1439 then Minute := 1439;
  ASlot := (Minute div FSnapMin) * FSnapMin;
  ADia  := ((Y - HeaderRowHeight) div RowHeight) + 1;
  Result := (ASlot >= 0) and (ASlot < 1440) and (ADia >= 1) and (ADia <= 7);
end;

function TfrmShiftModelEdit.HitTestDayHeader(X, Y: Integer; out ADia: Integer): Boolean;
begin
  Result := False;
  if (X < 0) or (X >= HeaderColWidth) then Exit;
  if Y < HeaderRowHeight then Exit;
  ADia := ((Y - HeaderRowHeight) div RowHeight) + 1;
  Result := (ADia >= 1) and (ADia <= 7);
end;

function TfrmShiftModelEdit.DayHeaderIconRect(ADia: Integer): TRect;
var
  Y, RH, Sz: Integer;
begin
  RH := RowHeight;
  Y := HeaderRowHeight + (ADia - 1) * RH;
  Sz := 18;
  Result := Rect(HeaderColWidth - Sz - 4, Y + (RH - Sz) div 2,
                 HeaderColWidth - 4,      Y + (RH - Sz) div 2 + Sz);
end;

function TfrmShiftModelEdit.HitTestHeaderIcon(X, Y: Integer; out ADia: Integer): Boolean;
var
  d: Integer;
  R: TRect;
begin
  Result := False;
  for d := 1 to 7 do
  begin
    R := DayHeaderIconRect(d);
    if PtInRect(R, Point(X, Y)) then
    begin
      ADia := d;
      Exit(True);
    end;
  end;
end;

procedure TfrmShiftModelEdit.ShowDiaMenuFor(ADia: Integer; AAtX, AAtY: Integer);
var
  PtScr: TPoint;
begin
  FDiaMenuTargetDia := ADia;
  PtScr := pbGrid.ClientToScreen(Point(AAtX, AAtY));
  FDiaMenu.Popup(PtScr.X, PtScr.Y);
end;

procedure TfrmShiftModelEdit.pbGridPaint(Sender: TObject);
const
  COL_LAB:    TColor = $0070C070;
  COL_NOLAB:  TColor = $00E0E0E0;
  COL_BORDER: TColor = $00C0C0C0;
  COL_HOUR:   TColor = $00808080;
  COL_SNAP:   TColor = $00E8E8E8;
var
  Bmp: TBitmap;
  C: TCanvas;
  d, m, h, CntLab: Integer;
  R, TxtR: TRect;
  RH, GridRight, VisW: Integer;
  X, Y0, Y1, X0, X1: Integer;
  RunStart: Integer;
  RunValue: Boolean;

  function MinToX(AMin: Integer): Integer;
  begin
    Result := HeaderColWidth + Round((AMin - FScrollOffsetMin) * FPixelsPerHour / 60.0);
  end;

begin
  if (Length(FMask) < 8) or (FPixelsPerHour <= 0) then Exit;
  if (pbGrid.Width <= 0) or (pbGrid.Height <= 0) then Exit;

  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(pbGrid.Width, pbGrid.Height);
    C := Bmp.Canvas;
    C.Brush.Color := clWhite;
    C.FillRect(Rect(0, 0, Bmp.Width, Bmp.Height));

    RH := RowHeight;
    VisW := VisibleWidth;
    GridRight := HeaderColWidth + VisW;

    // ----- Franges per dia (un sol rectangle per run continu) -----
    for d := 1 to 7 do
    begin
      Y0 := HeaderRowHeight + (d - 1) * RH;
      Y1 := Y0 + RH;

      // Fons gris no-laborable per tota la fila
      C.Brush.Color := COL_NOLAB;
      C.Brush.Style := bsSolid;
      C.Pen.Style := psClear;
      C.FillRect(Rect(HeaderColWidth, Y0, GridRight, Y1));
      C.Pen.Style := psSolid;

      // Pintar runs laborables (verds), clipats al rang visible
      RunStart := -1;
      RunValue := False;
      for m := 0 to 1439 do
      begin
        if FMask[d, m] and (RunStart < 0) then
        begin
          RunStart := m;
          RunValue := True;
        end
        else if (not FMask[d, m]) and (RunStart >= 0) then
        begin
          X0 := MinToX(RunStart);
          X1 := MinToX(m);
          if X0 < HeaderColWidth then X0 := HeaderColWidth;
          if X1 > GridRight then X1 := GridRight;
          if X1 > X0 then
          begin
            C.Brush.Color := COL_LAB;
            C.FillRect(Rect(X0, Y0, X1, Y1));
          end;
          RunStart := -1;
        end;
      end;
      if RunStart >= 0 then
      begin
        X0 := MinToX(RunStart);
        X1 := MinToX(1440);
        if X0 < HeaderColWidth then X0 := HeaderColWidth;
        if X1 > GridRight then X1 := GridRight;
        if X1 > X0 then
        begin
          C.Brush.Color := COL_LAB;
          C.FillRect(Rect(X0, Y0, X1, Y1));
        end;
      end;
      if RunValue then ;
    end;

    // ----- Linies verticals snap (fines) -----
    C.Pen.Style := psSolid;
    if (FSnapMin > 0) and (FSnapMin < 60) and (FPixelsPerHour >= 24) then
    begin
      C.Pen.Color := COL_SNAP;
      m := FSnapMin;
      while m < 1440 do
      begin
        if (m mod 60) <> 0 then
        begin
          X := MinToX(m);
          if (X > HeaderColWidth) and (X < GridRight) then
          begin
            C.MoveTo(X, HeaderRowHeight);
            C.LineTo(X, HeaderRowHeight + 7 * RH);
          end;
        end;
        Inc(m, FSnapMin);
      end;
    end;

    // Linies fortes cada hora + etiquetes
    C.Font.Name := 'Segoe UI';
    C.Font.Size := 7;
    C.Font.Color := COL_HOUR;
    C.Pen.Color := COL_BORDER;
    for h := 0 to 24 do
    begin
      X := MinToX(h * 60);
      if (X >= HeaderColWidth) and (X <= GridRight) then
      begin
        C.MoveTo(X, HeaderRowHeight);
        C.LineTo(X, HeaderRowHeight + 7 * RH);
      end;
      if (h < 24) and (X >= HeaderColWidth - 10) and (X < GridRight) then
      begin
        if FPixelsPerHour >= 24 then
        begin
          TxtR := Rect(X, 2, X + Round(FPixelsPerHour), HeaderRowHeight - 2);
          C.Brush.Style := bsClear;
          DrawText(C.Handle, PChar(Format('%.2d', [h])), -1, TxtR,
            DT_CENTER or DT_VCENTER or DT_SINGLELINE);
        end
        else if h mod 2 = 0 then
        begin
          TxtR := Rect(X, 2, X + Round(FPixelsPerHour * 2), HeaderRowHeight - 2);
          C.Brush.Style := bsClear;
          DrawText(C.Handle, PChar(Format('%.2d', [h])), -1, TxtR,
            DT_CENTER or DT_VCENTER or DT_SINGLELINE);
        end;
      end;
    end;

    // ----- Header de dies (esquerra) + linies horitzontals -----
    C.Font.Size := 9;
    C.Font.Color := clBlack;
    for d := 0 to 7 do
    begin
      C.Pen.Color := COL_BORDER;
      C.MoveTo(HeaderColWidth, HeaderRowHeight + d * RH);
      C.LineTo(GridRight, HeaderRowHeight + d * RH);
      if d < 7 then
      begin
        if (d + 1) = FHoverHeaderDia then
          C.Brush.Color := $00F0E8DC
        else
          C.Brush.Color := $00F7F7F7;
        C.Brush.Style := bsSolid;
        C.Pen.Color := COL_BORDER;
        C.Rectangle(0, HeaderRowHeight + d * RH,
                    HeaderColWidth, HeaderRowHeight + (d + 1) * RH);

        TxtR := Rect(4, HeaderRowHeight + d * RH,
                     HeaderColWidth - 24, HeaderRowHeight + (d + 1) * RH);
        C.Brush.Style := bsClear;
        C.Font.Style := [fsBold];
        C.Font.Color := clBlack;
        DrawText(C.Handle, PChar(DAY_NAMES[d + 1]), -1, TxtR,
          DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
        C.Font.Style := [];

        // Icona menu (3 punts)
        R := DayHeaderIconRect(d + 1);
        if (d + 1) = FHoverHeaderDia then
        begin
          C.Brush.Color := $00E0D8C0;
          C.Brush.Style := bsSolid;
          C.Pen.Color := $00C0B898;
          C.Rectangle(R);
        end;
        C.Brush.Color := clBlack;
        C.Brush.Style := bsSolid;
        C.Pen.Color := clBlack;
        C.Ellipse(R.Left + 7, R.Top + 3,  R.Left + 11, R.Top + 7);
        C.Ellipse(R.Left + 7, R.Top + 8,  R.Left + 11, R.Top + 12);
        C.Ellipse(R.Left + 7, R.Top + 13, R.Left + 11, R.Top + 17);
      end;
    end;

    // Marc exterior grid
    C.Pen.Color := COL_HOUR;
    C.Brush.Style := bsClear;
    C.Rectangle(HeaderColWidth, HeaderRowHeight, GridRight, HeaderRowHeight + 7 * RH);

    // ----- Llegenda dreta: total hores per dia (verd) -----
    for d := 1 to 7 do
    begin
      CntLab := 0;
      for m := 0 to 1439 do
        if FMask[d, m] then Inc(CntLab);
      TxtR := Rect(GridRight + 6, HeaderRowHeight + (d - 1) * RH,
                   GridRight + RightLegendWidth, HeaderRowHeight + d * RH);
      C.Brush.Style := bsClear;
      C.Font.Style := [fsBold];
      C.Font.Size := 10;
      if CntLab > 0 then C.Font.Color := $00208020
      else               C.Font.Color := clSilver;
      DrawText(C.Handle, PChar(Format('%.2f h', [CntLab / 60.0])),
        -1, TxtR, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
      C.Font.Style := [];
      C.Font.Size := 9;
      C.Font.Color := clBlack;
    end;

    // ----- Hover: marc fi sobre el slot apuntat (1 cella del snap) -----
    // ----- Linia 'ara mateix' (taronja, dia setmana actual) -----
    if FPixelsPerHour > 0 then
    begin
      d := DayOfTheWeek(Now);  // 1=Lu..7=Do (ISO)
      m := MinuteOfTheDay(Now);
      X := MinToX(m);
      if (X >= HeaderColWidth) and (X <= GridRight) then
      begin
        Y0 := HeaderRowHeight + (d - 1) * RH;
        Y1 := Y0 + RH;
        C.Pen.Color := $000080FF;  // taronja
        C.Pen.Width := 2;
        C.Pen.Style := psSolid;
        C.MoveTo(X, Y0);
        C.LineTo(X, Y1);
        // Triangle a dalt
        C.Brush.Color := $000080FF;
        C.Brush.Style := bsSolid;
        C.Polygon([Point(X - 4, Y0), Point(X + 4, Y0), Point(X, Y0 + 5)]);
        C.Pen.Width := 1;
      end;
    end;

    if (FHoverDia >= 1) and (FHoverDia <= 7) and
       (FHoverSlot >= 0) and (FHoverSlot < 1440) then
    begin
      X0 := MinToX(FHoverSlot);
      X1 := MinToX(FHoverSlot + FSnapMin);
      if X1 - X0 < 2 then X1 := X0 + 2;
      if (X1 > HeaderColWidth) and (X0 < GridRight) then
      begin
        if X0 < HeaderColWidth then X0 := HeaderColWidth;
        if X1 > GridRight then X1 := GridRight;
        Y0 := HeaderRowHeight + (FHoverDia - 1) * RH;
        Y1 := Y0 + RH;
        C.Pen.Color := clHighlight;
        C.Pen.Width := 2;
        C.Brush.Style := bsClear;
        C.Rectangle(X0, Y0, X1, Y1);
        C.Pen.Width := 1;
      end;
    end;

    pbGrid.Canvas.Draw(0, 0, Bmp);
  finally
    Bmp.Free;
  end;
  UpdateKPIs;
end;

procedure TfrmShiftModelEdit.pbGridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  D, S, sa: Integer;
begin
  // Click sobre la icona ':' del header: popup
  if (Button = mbLeft) and HitTestHeaderIcon(X, Y, D) then
  begin
    ShowDiaMenuFor(D, X, Y);
    Exit;
  end;

  // Right-click sobre el header de dia: popup
  if (Button = mbRight) and HitTestDayHeader(X, Y, D) then
  begin
    ShowDiaMenuFor(D, X, Y);
    Exit;
  end;

  if not HitTest(X, Y, D, S) then Exit;
  FPainting := True;

  if Button = mbRight then
    FPaintValue := False
  else
    FPaintValue := not FMask[D, S];

  FLastDia := D;
  FLastSlot := S;
  // Escriure tot el bloc del snap a partir de S
  for sa := S to Min(S + FSnapMin - 1, 1439) do
    FMask[D, sa] := FPaintValue;
  pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.pbGridMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  D, S, sa, sb, i, Hh, Mm, Cnt: Integer;
  HoverChanged: Boolean;
  PrevDia, PrevSlot, PrevHdr: Integer;
begin
  PrevDia := FHoverDia;
  PrevSlot := FHoverSlot;
  PrevHdr := FHoverHeaderDia;

  // Hover header de dia (per ressaltar i canviar cursor)
  if HitTestDayHeader(X, Y, D) then
  begin
    FHoverHeaderDia := D;
    pbGrid.Cursor := crHandPoint;
  end
  else
  begin
    FHoverHeaderDia := 0;
    pbGrid.Cursor := crDefault;
  end;

  if HitTest(X, Y, D, S) then
  begin
    FHoverDia := D;
    FHoverSlot := S;  // S ja esta quantitzat al snap
    Hh := S div 60;
    Mm := S mod 60;
    Cnt := 0;
    for i := 0 to 1439 do
      if FMask[D, i] then Inc(Cnt);
    lblHover.Caption := Format('%s  %.2d:%.2d   ('#8226' total laborable d'#237'a: %.2f h)',
      [DAY_NAMES[D], Hh, Mm, Cnt / 60.0]);
  end
  else
  begin
    FHoverDia := 0;
    FHoverSlot := -1;
    lblHover.Caption := '';
  end;

  HoverChanged := (PrevDia <> FHoverDia) or (PrevSlot <> FHoverSlot) or (PrevHdr <> FHoverHeaderDia);

  if FPainting and HitTest(X, Y, D, S) then
  begin
    if D = FLastDia then
    begin
      if S < FLastSlot then begin sa := S; sb := FLastSlot + FSnapMin - 1; end
      else                  begin sa := FLastSlot; sb := S + FSnapMin - 1; end;
      if sb > 1439 then sb := 1439;
      for i := sa to sb do
        FMask[D, i] := FPaintValue;
    end
    else
    begin
      sb := S + FSnapMin - 1;
      if sb > 1439 then sb := 1439;
      for i := S to sb do
        FMask[D, i] := FPaintValue;
    end;

    FLastDia := D;
    FLastSlot := S;
    pbGrid.Invalidate;
  end
  else if HoverChanged then
    pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.pbGridMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FPainting := False;
end;

procedure TfrmShiftModelEdit.btnFill24Click(Sender: TObject);
var
  d, s: Integer;
begin
  for d := 1 to 7 do
    for s := 0 to 1439 do
      FMask[d, s] := True;
  pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.btnFillLVClick(Sender: TObject);
var
  d, s, s1, s2, s3, s4: Integer;
begin
  for d := 1 to 7 do
    for s := 0 to 1439 do
      FMask[d, s] := False;

  s1 := 8  * 60;
  s2 := 13 * 60;
  s3 := 14 * 60;
  s4 := 18 * 60;

  for d := 1 to 5 do
  begin
    for s := s1 to s2 - 1 do FMask[d, s] := True;
    for s := s3 to s4 - 1 do FMask[d, s] := True;
  end;
  pbGrid.Invalidate;
end;

procedure TfrmShiftModelEdit.btnClearClick(Sender: TObject);
var
  d, s: Integer;
begin
  for d := 1 to 7 do
    for s := 0 to 1439 do
      FMask[d, s] := False;
  pbGrid.Invalidate;
end;

function TfrmShiftModelEdit.CollectLines: TArray<TShiftModelLineRec>;
var
  d, s, RunStart, Cnt: Integer;
  InRun: Boolean;
  L: TShiftModelLineRec;
begin
  Cnt := 0;
  SetLength(Result, 0);

  for d := 1 to 7 do
  begin
    InRun := False;
    RunStart := 0;
    for s := 0 to 1439 do
    begin
      if FMask[d, s] and (not InRun) then
      begin
        InRun := True;
        RunStart := s;
      end
      else if (not FMask[d, s]) and InRun then
      begin
        L.DiaSemana := d;
        L.HoraInicio := RunStart / 1440.0;
        L.HoraFin    := s        / 1440.0;
        SetLength(Result, Cnt + 1); Result[Cnt] := L; Inc(Cnt);
        InRun := False;
      end;
    end;
    if InRun then
    begin
      L.DiaSemana := d;
      L.HoraInicio := RunStart / 1440.0;
      L.HoraFin    := EncodeTime(23, 59, 0, 0);
      SetLength(Result, Cnt + 1); Result[Cnt] := L; Inc(Cnt);
    end;
  end;
end;

procedure TfrmShiftModelEdit.btnOKClick(Sender: TObject);
var
  Lines: TArray<TShiftModelLineRec>;
  Nom, Desc: string;
begin
  Nom := Trim(edNombre.Text);
  Desc := Trim(edDescripcion.Text);

  if Nom = '' then
  begin
    ShowMessage('El nombre no puede estar vac'#237'o.');
    edNombre.SetFocus;
    Exit;
  end;

  try
    if FEsNuevo then
      FShiftModelId := FRepo.AddShiftModel(FCodigoEmpresa, FCalendarId, Nom, Desc)
    else
      FRepo.UpdateShiftModel(FCodigoEmpresa, FShiftModelId, Nom, Desc);

    Lines := CollectLines;
    FRepo.SaveShiftModelLines(FCodigoEmpresa, FShiftModelId, FCalendarId, Lines);

    ModalResult := mrOk;
  except
    on E: Exception do
      ShowMessage('Error al guardar: ' + E.Message);
  end;
end;

procedure TfrmShiftModelEdit.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmShiftModelEdit.btnZoomOutClick(Sender: TObject);
begin
  SetZoomDelta(1 / 1.25);
end;

procedure TfrmShiftModelEdit.btnZoomInClick(Sender: TObject);
begin
  SetZoomDelta(1.25);
end;

procedure TfrmShiftModelEdit.btnZoomFitClick(Sender: TObject);
begin
  SetZoomAutoFit;
end;

procedure TfrmShiftModelEdit.FormResize(Sender: TObject);
begin
  if FAutoFit then SetZoomAutoFit;
end;

end.
