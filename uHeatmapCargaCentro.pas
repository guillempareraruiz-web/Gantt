unit uHeatmapCargaCentro;

{
  Heatmap de carga por centro y periodo (estilo skills-matrix de gesti'on
  visual industrial).

  Eje horizontal: periodos (d'ias / semanas / meses, configurable).
  Eje vertical:   centros de trabajo activos.
  Celda:          % de ocupaci'on = horas_planificadas / horas_capacidad.

  Codificaci'on de color:
    < 50%        Verde claro    (Libre)
    50% .. 80%   Verde medio    ('Optimo)
    80% .. 100%  Amarillo       (Alto)
    > 100%       Rojo           (Sobrecarga)

  Fuente de datos: nodos del proyecto activo (DMPlanner.CurrentProjectId)
  intersecados con la ventana del periodo. La capacidad se obtiene del
  calendario asignado al centro (WorkingMinutesBetween).
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections, System.DateUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Samples.Spin,
  Data.Win.ADODB, Data.DB,
  uGanttTypes, uCentresRepo, uCentreCalendar;

type
  TGranularidad = (gDias, gSemanas, gMeses);

  TPeriodo = record
    Inicio: TDateTime;
    Fin:    TDateTime;
    Label_: string;
  end;

  TfrmHeatmapCargaCentro = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlToolbar: TPanel;
    lblGran: TLabel;
    cmbGranularidad: TComboBox;
    lblNum: TLabel;
    spNumPeriodos: TSpinEdit;
    lblDesde: TLabel;
    dtDesde: TDateTimePicker;
    btnRecalcular: TButton;
    pnlLegend: TPanel;
    pbLegend: TPaintBox;
    pnlBottom: TPanel;
    btnClose: TButton;
    sbMatrix: TScrollBox;
    pbMatrix: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnRecalcularClick(Sender: TObject);
    procedure ParametrosChange(Sender: TObject);
    procedure pbLegendPaint(Sender: TObject);
    procedure pbMatrixPaint(Sender: TObject);
  private
    FCentres: TArray<TCentreTreball>;
    FPeriodos: TArray<TPeriodo>;
    // [centroIdx, periodoIdx] -> %  (-1 si sin capacidad)
    FMatrix: array of array of Double;
    procedure BuildPeriodos;
    procedure RecalcularDatos;
    function ColorPorPct(P: Double; out TextDark: Boolean): TColor;
    function FormatPct(P: Double): string;
    procedure ComputeMatrixSize(out AWidth, AHeight: Integer);
  public
    class procedure Execute;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner;

const
  // Dimensiones
  MTX_CELL_W       = 90;
  MTX_CELL_H       = 38;
  MTX_ROW_LABEL_W  = 180;
  MTX_COL_HEADER_H = 46;
  MTX_PADDING      = 12;

  // Umbrales (en %)
  TH_LIBRE       = 50;   // < TH_LIBRE       -> Libre
  TH_OPTIMO_HI   = 80;   // [TH_LIBRE, TH_OPTIMO_HI) -> 'Optimo
  TH_ALTO_HI     = 100;  // [TH_OPTIMO_HI, TH_ALTO_HI] -> Alto, > -> Sobrecarga

const
  // Colores estilo doc HTML
  CLR_LIBRE:     TColor = $00C9E8C9;  // verde claro (BGR)
  CLR_OPTIMO:    TColor = $0085C285;  // verde medio
  CLR_ALTO:      TColor = $0072BDF2;  // amarillo-naranja BGR ~ #F2BD72
  CLR_SOBRE:     TColor = $004142D7;  // rojo BGR ~ #D74241
  CLR_NO_CAP:    TColor = $00E8E8E8;  // gris (sense calendari)

  CLR_TXT_LIGHT: TColor = $00404040;
  CLR_TXT_DARK:  TColor = $00FFFFFF;

  CLR_GRID_LINE: TColor = $00D0D0D0;
  CLR_HEADER_BG: TColor = $00F5F1E8;
  CLR_HEADER_TX: TColor = $00404040;
  CLR_PAPER:     TColor = $00FCFAF4;

class procedure TfrmHeatmapCargaCentro.Execute;
var
  F: TfrmHeatmapCargaCentro;
begin
  F := TfrmHeatmapCargaCentro.Create(nil);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmHeatmapCargaCentro.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  sbMatrix.DoubleBuffered := True;
  cmbGranularidad.ItemIndex := 1; // Semanas por defecto
  dtDesde.Date := Trunc(Now);
  spNumPeriodos.Value := 6;
  RecalcularDatos;
end;

procedure TfrmHeatmapCargaCentro.FormDestroy(Sender: TObject);
begin
  // Nada que liberar
end;

procedure TfrmHeatmapCargaCentro.FormResize(Sender: TObject);
var
  W, H: Integer;
begin
  ComputeMatrixSize(W, H);
  pbMatrix.SetBounds(0, 0, W, H);
end;

procedure TfrmHeatmapCargaCentro.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmHeatmapCargaCentro.btnRecalcularClick(Sender: TObject);
begin
  RecalcularDatos;
end;

procedure TfrmHeatmapCargaCentro.ParametrosChange(Sender: TObject);
begin
  // Recalcular automaticament al canviar parametres
  RecalcularDatos;
end;

procedure TfrmHeatmapCargaCentro.BuildPeriodos;
var
  Gran: TGranularidad;
  NumPer, I: Integer;
  Cursor: TDateTime;
  P: TPeriodo;
  YYYY, MM, DD: Word;
begin
  Gran := TGranularidad(cmbGranularidad.ItemIndex);
  NumPer := spNumPeriodos.Value;
  if NumPer < 1 then NumPer := 1;

  SetLength(FPeriodos, NumPer);
  Cursor := Trunc(dtDesde.Date);

  // Para semanas, snap al lunes mas cercano (ISO)
  if Gran = gSemanas then
    Cursor := Cursor - ((DayOfTheWeek(Cursor) + 6) mod 7); // mou a dilluns

  // Para meses, snap al dia 1
  if Gran = gMeses then
  begin
    DecodeDate(Cursor, YYYY, MM, DD);
    Cursor := EncodeDate(YYYY, MM, 1);
  end;

  for I := 0 to NumPer - 1 do
  begin
    P.Inicio := Cursor;
    case Gran of
      gDias:
        begin
          P.Fin := IncDay(Cursor, 1);
          P.Label_ := FormatDateTime('dd/mm', Cursor);
        end;
      gSemanas:
        begin
          P.Fin := IncDay(Cursor, 7);
          P.Label_ := 'S' + IntToStr(WeekOf(Cursor));
        end;
      gMeses:
        begin
          P.Fin := IncMonth(Cursor, 1);
          P.Label_ := FormatDateTime('mmm yy', Cursor);
        end;
    end;
    FPeriodos[I] := P;
    Cursor := P.Fin;
  end;
end;

procedure TfrmHeatmapCargaCentro.RecalcularDatos;
var
  Q: TADOQuery;
  ProjectId: Integer;
  HorizonteInicio, HorizonteFin: TDateTime;
  Centres: TArray<TCentreTreball>;
  CenterIdxById: TDictionary<Integer, Integer>;
  I, J, CIdx: Integer;
  CenterId: Integer;
  NodeInicio, NodeFin: TDateTime;
  DurMin: Double;
  PI, PF, OvStart, OvEnd: TDateTime;
  OverlapMin, NodeDuracionMin, MinutsNode: Double;
  Cal: TCentreCalendar;
  CapacityMin: Integer;
  HorasPlan, HorasCap, Pct: Double;
  // Mapa [centroIdx, periodoIdx] -> horas planificadas acumuladas
  HorasMat: array of array of Double;
begin
  BuildPeriodos;
  if Length(FPeriodos) = 0 then
  begin
    SetLength(FMatrix, 0);
    pbMatrix.Invalidate;
    Exit;
  end;

  // Cargar centros activos del repo
  if DMPlanner.CentresRepo <> nil then
    Centres := DMPlanner.CentresRepo.GetAll
  else
    SetLength(Centres, 0);
  FCentres := Centres;

  SetLength(HorasMat, Length(FCentres), Length(FPeriodos));
  SetLength(FMatrix, Length(FCentres), Length(FPeriodos));

  if (Length(FCentres) = 0) then
  begin
    pbMatrix.Invalidate;
    Exit;
  end;

  CenterIdxById := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to High(FCentres) do
      CenterIdxById.AddOrSetValue(FCentres[I].Id, I);

    HorizonteInicio := FPeriodos[0].Inicio;
    HorizonteFin := FPeriodos[High(FPeriodos)].Fin;

    ProjectId := DMPlanner.CurrentProjectId;
    if ProjectId > 0 then
    begin
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := DMPlanner.ADOConnection;
        Q.SQL.Text :=
          'SELECT CenterId, FechaInicio, FechaFin, DuracionMin ' +
          'FROM FS_PL_Node ' +
          'WHERE CodigoEmpresa = :CE AND ProjectId = :PID ' +
          '  AND CenterId IS NOT NULL ' +
          '  AND FechaInicio IS NOT NULL AND FechaFin IS NOT NULL ' +
          '  AND FechaFin >= :HInicio AND FechaInicio < :HFin';
        Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
        Q.Parameters.ParamByName('PID').Value := ProjectId;
        Q.Parameters.ParamByName('HInicio').Value := HorizonteInicio;
        Q.Parameters.ParamByName('HFin').Value := HorizonteFin;
        Q.Open;
        while not Q.Eof do
        begin
          CenterId := Q.FieldByName('CenterId').AsInteger;
          if CenterIdxById.TryGetValue(CenterId, CIdx) then
          begin
            NodeInicio := Q.FieldByName('FechaInicio').AsDateTime;
            NodeFin    := Q.FieldByName('FechaFin').AsDateTime;
            DurMin     := Q.FieldByName('DuracionMin').AsFloat;
            // Si DuracionMin es 0 o falta, calcular per diferencia
            if DurMin <= 0 then
              DurMin := MinutesBetween(NodeFin, NodeInicio);
            NodeDuracionMin := MinutesBetween(NodeFin, NodeInicio);
            if NodeDuracionMin <= 0 then
            begin
              Q.Next;
              Continue;
            end;

            // Repartir DuracionMin proporcionalment al solapament amb cada periodo.
            // Premissa: la durada efectiva s'escampa linealment entre inicio i fin.
            for J := 0 to High(FPeriodos) do
            begin
              PI := FPeriodos[J].Inicio;
              PF := FPeriodos[J].Fin;
              OvStart := PI;
              if NodeInicio > OvStart then OvStart := NodeInicio;
              OvEnd := PF;
              if NodeFin < OvEnd then OvEnd := NodeFin;
              if OvEnd <= OvStart then Continue;

              OverlapMin := MinutesBetween(OvEnd, OvStart);
              MinutsNode := DurMin * (OverlapMin / NodeDuracionMin);
              HorasMat[CIdx, J] := HorasMat[CIdx, J] + (MinutsNode / 60.0);
            end;
          end;
          Q.Next;
        end;
      finally
        Q.Free;
      end;
    end;

    // Calcular % per cada (centre, periode) usant capacitat del calendari
    for I := 0 to High(FCentres) do
    begin
      Cal := nil;
      if DMPlanner.CentresRepo <> nil then
        Cal := DMPlanner.CentresRepo.GetCalendarFor(FCentres[I].Id);
      for J := 0 to High(FPeriodos) do
      begin
        HorasPlan := HorasMat[I, J];
        if Cal = nil then
        begin
          FMatrix[I, J] := -1; // sense capacitat
          Continue;
        end;
        CapacityMin := Cal.WorkingMinutesBetween(FPeriodos[J].Inicio, FPeriodos[J].Fin);
        if CapacityMin <= 0 then
        begin
          FMatrix[I, J] := -1;
          Continue;
        end;
        HorasCap := CapacityMin / 60.0;
        Pct := (HorasPlan / HorasCap) * 100.0;
        FMatrix[I, J] := Pct;
      end;
    end;
  finally
    CenterIdxById.Free;
  end;

  FormResize(nil);
  pbMatrix.Invalidate;
  pbLegend.Invalidate;
end;

function TfrmHeatmapCargaCentro.ColorPorPct(P: Double; out TextDark: Boolean): TColor;
begin
  if P < 0 then
  begin
    TextDark := True;
    Result := CLR_NO_CAP;
    Exit;
  end;
  if P < TH_LIBRE then
  begin
    TextDark := True;
    Result := CLR_LIBRE;
  end
  else if P < TH_OPTIMO_HI then
  begin
    TextDark := True;
    Result := CLR_OPTIMO;
  end
  else if P <= TH_ALTO_HI then
  begin
    TextDark := True;
    Result := CLR_ALTO;
  end
  else
  begin
    TextDark := False;
    Result := CLR_SOBRE;
  end;
end;

function TfrmHeatmapCargaCentro.FormatPct(P: Double): string;
begin
  if P < 0 then Exit('---');
  Result := FormatFloat('0', P) + '%';
end;

procedure TfrmHeatmapCargaCentro.ComputeMatrixSize(out AWidth, AHeight: Integer);
var
  NumCen, NumPer, TempW, TempH: Integer;
begin
  NumCen := Length(FCentres);
  NumPer := Length(FPeriodos);
  TempW := NumPer * MTX_CELL_W;
  TempW := TempW + MTX_ROW_LABEL_W;
  TempW := TempW + MTX_PADDING;
  TempH := NumCen * MTX_CELL_H;
  TempH := TempH + MTX_COL_HEADER_H;
  TempH := TempH + MTX_PADDING;
  AWidth := TempW;
  AHeight := TempH;
  if AWidth < sbMatrix.ClientWidth then AWidth := sbMatrix.ClientWidth;
  if AHeight < sbMatrix.ClientHeight then AHeight := sbMatrix.ClientHeight;
end;

procedure TfrmHeatmapCargaCentro.pbLegendPaint(Sender: TObject);
var
  C: TCanvas;
  X, Y, BoxW, BoxH, Gap: Integer;
  procedure Chip(AColor: TColor; const ALabel: string; ATextDark: Boolean);
  var
    R: TRect;
    TxColor: TColor;
  begin
    R := Rect(X, Y, X + BoxW, Y + BoxH);
    C.Brush.Color := AColor;
    C.FillRect(R);
    if ATextDark then TxColor := CLR_TXT_LIGHT else TxColor := CLR_TXT_DARK;
    C.Font.Color := TxColor;
    C.Font.Style := [fsBold];
    C.Brush.Style := bsClear;
    DrawText(C.Handle, PChar(ALabel), Length(ALabel), R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;
    Inc(X, BoxW + Gap);
  end;
begin
  C := pbLegend.Canvas;
  C.Font.Name := 'Segoe UI';
  C.Font.Size := 9;
  C.Brush.Color := CLR_PAPER;
  C.FillRect(pbLegend.ClientRect);

  BoxW := 160;
  BoxH := pbLegend.Height - 4;
  Gap  := 8;
  X    := 4;
  Y    := 2;

  Chip(CLR_LIBRE,  'Libre (<50%)',         True);
  Chip(CLR_OPTIMO, #211'ptimo (50-80%)',   True);
  Chip(CLR_ALTO,   'Alto (80-100%)',       True);
  Chip(CLR_SOBRE,  'Sobrecarga (>100%)',   False);
end;

procedure TfrmHeatmapCargaCentro.pbMatrixPaint(Sender: TObject);
var
  C: TCanvas;
  I, J, X, Y, NumCen, NumPer: Integer;
  R: TRect;
  Pct: Double;
  BgColor, TxColor: TColor;
  TextDark: Boolean;
  Lbl: string;
begin
  C := pbMatrix.Canvas;
  C.Font.Name := 'Segoe UI';

  C.Brush.Color := CLR_PAPER;
  C.FillRect(pbMatrix.ClientRect);

  NumCen := Length(FCentres);
  NumPer := Length(FPeriodos);

  if (NumCen = 0) or (NumPer = 0) then
  begin
    C.Font.Size := 10;
    C.Font.Color := CLR_TXT_LIGHT;
    C.Brush.Style := bsClear;
    R := pbMatrix.ClientRect;
    DrawText(C.Handle,
      PChar('No hay centros o periodos para mostrar.'),
      -1, R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;
    Exit;
  end;

  // ----- Cabecera de periodos -----
  C.Font.Size := 9;
  C.Font.Style := [fsBold];
  C.Brush.Color := CLR_HEADER_BG;
  R := Rect(MTX_ROW_LABEL_W, 0, MTX_ROW_LABEL_W + NumPer * MTX_CELL_W, MTX_COL_HEADER_H);
  C.FillRect(R);

  for J := 0 to NumPer - 1 do
  begin
    X := MTX_ROW_LABEL_W + J * MTX_CELL_W;
    R := Rect(X, 0, X + MTX_CELL_W, MTX_COL_HEADER_H);
    C.Font.Color := CLR_HEADER_TX;
    C.Brush.Style := bsClear;
    DrawText(C.Handle, PChar(FPeriodos[J].Label_), -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;
  end;

  // ----- Columna de centros (nombres) -----
  C.Brush.Color := CLR_HEADER_BG;
  R := Rect(0, MTX_COL_HEADER_H, MTX_ROW_LABEL_W, MTX_COL_HEADER_H + NumCen * MTX_CELL_H);
  C.FillRect(R);

  for I := 0 to NumCen - 1 do
  begin
    Y := MTX_COL_HEADER_H + I * MTX_CELL_H;
    R := Rect(8, Y, MTX_ROW_LABEL_W - 8, Y + MTX_CELL_H);
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_HEADER_TX;
    C.Brush.Style := bsClear;
    Lbl := FCentres[I].Titulo;
    if Trim(Lbl) = '' then Lbl := FCentres[I].CodiCentre;
    DrawText(C.Handle, PChar(Lbl), -1, R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    C.Brush.Style := bsSolid;
  end;

  // Esquina superior izquierda
  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, MTX_ROW_LABEL_W, MTX_COL_HEADER_H));

  // ----- Celdas -----
  C.Font.Style := [fsBold];
  C.Font.Size := 10;
  for I := 0 to NumCen - 1 do
    for J := 0 to NumPer - 1 do
    begin
      X := MTX_ROW_LABEL_W + J * MTX_CELL_W;
      Y := MTX_COL_HEADER_H + I * MTX_CELL_H;
      R := Rect(X + 2, Y + 2, X + MTX_CELL_W - 2, Y + MTX_CELL_H - 2);

      Pct := FMatrix[I, J];
      BgColor := ColorPorPct(Pct, TextDark);
      if TextDark then TxColor := CLR_TXT_LIGHT else TxColor := CLR_TXT_DARK;

      C.Brush.Color := BgColor;
      C.FillRect(R);

      C.Font.Color := TxColor;
      C.Brush.Style := bsClear;
      DrawText(C.Handle, PChar(FormatPct(Pct)), -1, R,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      C.Brush.Style := bsSolid;
    end;

  // ----- Lineas de grid -----
  C.Pen.Color := CLR_GRID_LINE;
  C.Pen.Style := psSolid;
  for J := 0 to NumPer do
  begin
    X := MTX_ROW_LABEL_W + J * MTX_CELL_W;
    C.MoveTo(X, 0);
    C.LineTo(X, MTX_COL_HEADER_H + NumCen * MTX_CELL_H);
  end;
  for I := 0 to NumCen do
  begin
    Y := MTX_COL_HEADER_H + I * MTX_CELL_H;
    C.MoveTo(0, Y);
    C.LineTo(MTX_ROW_LABEL_W + NumPer * MTX_CELL_W, Y);
  end;
end;

end.
