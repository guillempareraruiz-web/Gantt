unit uHeatmapCargaOperario;

{
  Heatmap de carga por operario y periodo. Mismo estilo que el de centros
  (uHeatmapCargaCentro) pero con operarios en el eje vertical.

  Eje horizontal: periodos (dias / semanas / meses, configurable).
  Eje vertical:   operarios activos.
  Celda:          % de ocupacion = horas_asignadas / horas_capacidad.

  Fuente de datos:
    - Asignaciones del proyecto activo: FS_PL_OperatorAssignment JOIN FS_PL_Node
      (las horas del operario en un nodo se prorratean por el solapamiento
       temporal del nodo con cada periodo).
    - Capacidad del operario: calendario asignado (FS_PL_Operator.CalendarId)
      via DMPlanner.CalendarsRepo.GetById(...).WorkingMinutesBetween.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections, System.DateUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Samples.Spin,
  Data.Win.ADODB, Data.DB,
  cxCheckComboBox, cxCheckBox, cxEdit, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  uGanttTypes, uCentreCalendar, dxSkinsCore, dxSkinBasic,
  dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee,
  dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019Colorful,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue;

type
  TGranularidadOp = (goDias, goSemanas, goMeses);

  TPeriodoOp = record
    Inicio: TDateTime;
    Fin:    TDateTime;
    Label_: string;
  end;

  TOperarioRow = record
    Id: Integer;
    Nombre: string;
    CalendarId: Integer;
  end;

  TfrmHeatmapCargaOperario = class(TForm)
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
    lblOperarios: TLabel;
    cbOperarios: TcxCheckComboBox;
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
    procedure cbOperariosChange(Sender: TObject);
  private
    FAllOperarios: TArray<TOperarioRow>;
    FOperarios: TArray<TOperarioRow>;
    FPeriodos: TArray<TPeriodoOp>;
    // [operarioIdx, periodoIdx] -> %  (-1 si sin capacidad)
    FMatrix: array of array of Double;
    FUpdatingOps: Boolean;
    FLoadingPrefs: Boolean;
    procedure BuildPeriodos;
    procedure CargarOperariosDesdeSQL;
    procedure CargarOperariosCombo;
    procedure AplicarFiltroOperarios;
    procedure LoadPrefs;
    procedure SavePrefs;
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
  uDMPlanner, uHelpViewer, System.JSON;

const
  // Dimensiones
  MTX_CELL_W       = 90;
  MTX_CELL_H       = 38;
  MTX_ROW_LABEL_W  = 200;
  MTX_COL_HEADER_H = 46;
  MTX_PADDING      = 12;

const
  // Misma paleta que el heatmap por centro
  CLR_VACIO:     TColor = $00F0F0F0;
  CLR_R1_10:     TColor = $00D9F5D9;
  CLR_R11_25:    TColor = $00B5E5B5;
  CLR_R26_50:    TColor = $0085C285;
  CLR_R51_75:    TColor = $0066D9B3;
  CLR_R76_90:    TColor = $005CD0F5;
  CLR_R91_100:   TColor = $002E8FE8;
  CLR_R101_120:  TColor = $004D6FD7;
  CLR_R_SOBRE:   TColor = $002F2FC4;
  CLR_NO_CAP:    TColor = $00E8E8E8;

  CLR_TXT_LIGHT: TColor = $00404040;
  CLR_TXT_DARK:  TColor = $00FFFFFF;

  CLR_GRID_LINE: TColor = $00D0D0D0;
  CLR_HEADER_BG: TColor = $00F5F1E8;
  CLR_HEADER_TX: TColor = $00404040;
  CLR_PAPER:     TColor = $00FCFAF4;

class procedure TfrmHeatmapCargaOperario.Execute;
var
  F: TfrmHeatmapCargaOperario;
begin
  F := TfrmHeatmapCargaOperario.Create(nil);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmHeatmapCargaOperario.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  sbMatrix.DoubleBuffered := True;
  FLoadingPrefs := True;
  try
    cmbGranularidad.ItemIndex := 1;
    dtDesde.Date := Trunc(Now);
    spNumPeriodos.Value := 6;
    CargarOperariosDesdeSQL;
    CargarOperariosCombo;
    LoadPrefs;
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
  THelpViewer.InstallHelp(Self, 'uHeatmapCargaOperario',
    'Heatmap de carga por operario');
end;

procedure TfrmHeatmapCargaOperario.LoadPrefs;
var
  Js: string;
  Root: TJSONObject;
  V: TJSONValue;
  Arr: TJSONArray;
  IdsSet: TDictionary<Integer, Boolean>;
  I, Oid: Integer;
  TodosSel: Boolean;
begin
  if (DMPlanner = nil) or (DMPlanner.UserPrefs = nil) then Exit;
  Js := DMPlanner.UserPrefs.Load('HeatmapCargaOperario');
  if Js = '' then Exit;

  Root := TJSONObject.ParseJSONValue(Js) as TJSONObject;
  if Root = nil then Exit;
  try
    V := Root.GetValue('granularidad');
    if V <> nil then cmbGranularidad.ItemIndex := (V as TJSONNumber).AsInt;
    V := Root.GetValue('numPeriodos');
    if V <> nil then spNumPeriodos.Value := (V as TJSONNumber).AsInt;
    V := Root.GetValue('desde');
    if V <> nil then
      try dtDesde.Date := StrToDateTime((V as TJSONString).Value); except end;

    V := Root.GetValue('operarios');
    TodosSel := (V = nil) or (V is TJSONNull);
    FUpdatingOps := True;
    try
      if TodosSel then
      begin
        for I := 0 to cbOperarios.Properties.Items.Count - 1 do
          cbOperarios.States[I] := cbsChecked;
      end
      else if V is TJSONArray then
      begin
        Arr := V as TJSONArray;
        IdsSet := TDictionary<Integer, Boolean>.Create;
        try
          for I := 0 to Arr.Count - 1 do
            IdsSet.AddOrSetValue((Arr.Items[I] as TJSONNumber).AsInt, True);
          cbOperarios.States[0] := cbsUnchecked;
          for I := 0 to High(FAllOperarios) do
          begin
            Oid := FAllOperarios[I].Id;
            if IdsSet.ContainsKey(Oid) then
              cbOperarios.States[I + 1] := cbsChecked
            else
              cbOperarios.States[I + 1] := cbsUnchecked;
          end;
          if IdsSet.Count = Length(FAllOperarios) then
            cbOperarios.States[0] := cbsChecked
          else
            cbOperarios.States[0] := cbsUnchecked;
        finally
          IdsSet.Free;
        end;
      end;
    finally
      FUpdatingOps := False;
    end;
  finally
    Root.Free;
  end;
end;

procedure TfrmHeatmapCargaOperario.SavePrefs;
var
  Root: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
  TodosSel: Boolean;
begin
  if FLoadingPrefs then Exit;
  if (DMPlanner = nil) or (DMPlanner.UserPrefs = nil) then Exit;

  Root := TJSONObject.Create;
  try
    Root.AddPair('granularidad', TJSONNumber.Create(cmbGranularidad.ItemIndex));
    Root.AddPair('numPeriodos', TJSONNumber.Create(spNumPeriodos.Value));
    Root.AddPair('desde', FormatDateTime('yyyy-mm-dd', dtDesde.Date));

    TodosSel := (cbOperarios.Properties.Items.Count > 0) and
                (cbOperarios.States[0] = cbsChecked);
    if TodosSel then
      Root.AddPair('operarios', TJSONNull.Create)
    else
    begin
      Arr := TJSONArray.Create;
      for I := 0 to High(FAllOperarios) do
        if (I + 1 < cbOperarios.Properties.Items.Count) and
           (cbOperarios.States[I + 1] = cbsChecked) then
          Arr.AddElement(TJSONNumber.Create(FAllOperarios[I].Id));
      Root.AddPair('operarios', Arr);
    end;

    DMPlanner.UserPrefs.Save('HeatmapCargaOperario', Root.ToJSON);
  finally
    Root.Free;
  end;
end;

procedure TfrmHeatmapCargaOperario.CargarOperariosDesdeSQL;
var
  Q: TADOQuery;
  List: TList<TOperarioRow>;
  R: TOperarioRow;
begin
  SetLength(FAllOperarios, 0);
  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) or
     (not DMPlanner.ADOConnection.Connected) then
    Exit;

  List := TList<TOperarioRow>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    Q.SQL.Text :=
      'SELECT OperatorId, Nombre, ISNULL(CalendarId, 0) AS CalendarId ' +
      'FROM FS_PL_Operator ' +
      'WHERE CodigoEmpresa = :CE AND ISNULL(Activo, 1) = 1 ' +
      'ORDER BY Nombre';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    try
      Q.Open;
      while not Q.Eof do
      begin
        R.Id := Q.FieldByName('OperatorId').AsInteger;
        R.Nombre := Q.FieldByName('Nombre').AsString;
        R.CalendarId := Q.FieldByName('CalendarId').AsInteger;
        List.Add(R);
        Q.Next;
      end;
    except
      // Si la tabla no existe (instalacion sin V019), nos quedamos sin operarios
    end;
    FAllOperarios := List.ToArray;
  finally
    Q.Free;
    List.Free;
  end;
end;

procedure TfrmHeatmapCargaOperario.CargarOperariosCombo;
var
  I: Integer;
  Lbl: string;
begin
  FUpdatingOps := True;
  try
    cbOperarios.Properties.Items.Clear;
    cbOperarios.Properties.Items.AddCheckItem('(Todos)');
    cbOperarios.States[0] := cbsChecked;
    for I := 0 to High(FAllOperarios) do
    begin
      Lbl := FAllOperarios[I].Nombre;
      if Trim(Lbl) = '' then Lbl := 'Operario #' + IntToStr(FAllOperarios[I].Id);
      cbOperarios.Properties.Items.AddCheckItem(Lbl);
      cbOperarios.States[I + 1] := cbsChecked;
    end;
    if Length(FAllOperarios) = 0 then
      cbOperarios.Properties.EmptySelectionText := 'Sin operarios disponibles'
    else
      cbOperarios.Properties.EmptySelectionText := 'Ningun operario seleccionado';
  finally
    FUpdatingOps := False;
  end;
end;

procedure TfrmHeatmapCargaOperario.AplicarFiltroOperarios;
var
  I, K: Integer;
begin
  SetLength(FOperarios, 0);
  K := 0;
  SetLength(FOperarios, Length(FAllOperarios));
  for I := 0 to High(FAllOperarios) do
    if (I + 1 < cbOperarios.Properties.Items.Count) and
       (cbOperarios.States[I + 1] = cbsChecked) then
    begin
      FOperarios[K] := FAllOperarios[I];
      Inc(K);
    end;
  SetLength(FOperarios, K);
end;

procedure TfrmHeatmapCargaOperario.cbOperariosChange(Sender: TObject);
var
  I: Integer;
  TodosChecked, AllReal: Boolean;
  NewState: TcxCheckBoxState;
begin
  if FUpdatingOps then Exit;
  if cbOperarios.Properties.Items.Count = 0 then
  begin
    RecalcularDatos;
    Exit;
  end;

  FUpdatingOps := True;
  try
    TodosChecked := (cbOperarios.States[0] = cbsChecked);
    AllReal := True;
    for I := 1 to cbOperarios.Properties.Items.Count - 1 do
      if cbOperarios.States[I] <> cbsChecked then
      begin
        AllReal := False;
        Break;
      end;

    if TodosChecked <> AllReal then
    begin
      if TodosChecked then NewState := cbsChecked else NewState := cbsUnchecked;
      for I := 1 to cbOperarios.Properties.Items.Count - 1 do
        cbOperarios.States[I] := NewState;
    end
    else
    begin
      if AllReal then
        cbOperarios.States[0] := cbsChecked
      else
        cbOperarios.States[0] := cbsUnchecked;
    end;
  finally
    FUpdatingOps := False;
  end;

  RecalcularDatos;
  SavePrefs;
end;

procedure TfrmHeatmapCargaOperario.FormDestroy(Sender: TObject);
begin
  // Nada que liberar
end;

procedure TfrmHeatmapCargaOperario.FormResize(Sender: TObject);
var
  W, H: Integer;
begin
  ComputeMatrixSize(W, H);
  pbMatrix.SetBounds(0, 0, W, H);
end;

procedure TfrmHeatmapCargaOperario.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmHeatmapCargaOperario.btnRecalcularClick(Sender: TObject);
begin
  RecalcularDatos;
end;

procedure TfrmHeatmapCargaOperario.ParametrosChange(Sender: TObject);
begin
  RecalcularDatos;
  SavePrefs;
end;

procedure TfrmHeatmapCargaOperario.BuildPeriodos;
var
  Gran: TGranularidadOp;
  NumPer, I: Integer;
  Cursor: TDateTime;
  P: TPeriodoOp;
  YYYY, MM, DD: Word;
begin
  Gran := TGranularidadOp(cmbGranularidad.ItemIndex);
  NumPer := spNumPeriodos.Value;
  if NumPer < 1 then NumPer := 1;

  SetLength(FPeriodos, NumPer);
  Cursor := Trunc(dtDesde.Date);

  if Gran = goSemanas then
    Cursor := Cursor - ((DayOfTheWeek(Cursor) + 6) mod 7);

  if Gran = goMeses then
  begin
    DecodeDate(Cursor, YYYY, MM, DD);
    Cursor := EncodeDate(YYYY, MM, 1);
  end;

  for I := 0 to NumPer - 1 do
  begin
    P.Inicio := Cursor;
    case Gran of
      goDias:
        begin
          P.Fin := IncDay(Cursor, 1);
          P.Label_ := FormatDateTime('dd/mm', Cursor);
        end;
      goSemanas:
        begin
          P.Fin := IncDay(Cursor, 7);
          P.Label_ := 'S' + IntToStr(WeekOf(Cursor));
        end;
      goMeses:
        begin
          P.Fin := IncMonth(Cursor, 1);
          P.Label_ := FormatDateTime('mmm yy', Cursor);
        end;
    end;
    FPeriodos[I] := P;
    Cursor := P.Fin;
  end;
end;

procedure TfrmHeatmapCargaOperario.RecalcularDatos;
var
  Q: TADOQuery;
  ProjectId: Integer;
  HorizonteInicio, HorizonteFin: TDateTime;
  OpIdxById: TDictionary<Integer, Integer>;
  I, J, OIdx: Integer;
  OperatorId: Integer;
  NodeInicio, NodeFin: TDateTime;
  Horas: Double;
  PI, PF, OvStart, OvEnd: TDateTime;
  OverlapMin, NodeDuracionMin, HorasParte: Double;
  Cal: TCentreCalendar;
  CapacityMin: Integer;
  HorasPlan, HorasCap, Pct: Double;
  // [operarioIdx, periodoIdx] -> horas asignadas acumuladas
  HorasMat: array of array of Double;
begin
  BuildPeriodos;
  if Length(FPeriodos) = 0 then
  begin
    SetLength(FMatrix, 0);
    pbMatrix.Invalidate;
    Exit;
  end;

  AplicarFiltroOperarios;

  SetLength(HorasMat, Length(FOperarios), Length(FPeriodos));
  SetLength(FMatrix, Length(FOperarios), Length(FPeriodos));

  if Length(FOperarios) = 0 then
  begin
    pbMatrix.Invalidate;
    Exit;
  end;

  OpIdxById := TDictionary<Integer, Integer>.Create;
  try
    for I := 0 to High(FOperarios) do
      OpIdxById.AddOrSetValue(FOperarios[I].Id, I);

    HorizonteInicio := FPeriodos[0].Inicio;
    HorizonteFin := FPeriodos[High(FPeriodos)].Fin;

    ProjectId := DMPlanner.CurrentProjectId;
    if ProjectId > 0 then
    begin
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := DMPlanner.ADOConnection;
        Q.SQL.Text :=
          'SELECT oa.OperatorId, oa.Horas, n.FechaInicio, n.FechaFin ' +
          'FROM FS_PL_OperatorAssignment oa ' +
          'INNER JOIN FS_PL_Node n ON n.CodigoEmpresa = oa.CodigoEmpresa ' +
          '                       AND n.NodeId = oa.NodeId ' +
          'WHERE oa.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
          '  AND n.FechaInicio IS NOT NULL AND n.FechaFin IS NOT NULL ' +
          '  AND n.FechaFin >= :HInicio AND n.FechaInicio < :HFin';
        Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
        Q.Parameters.ParamByName('PID').Value := ProjectId;
        Q.Parameters.ParamByName('HInicio').Value := HorizonteInicio;
        Q.Parameters.ParamByName('HFin').Value := HorizonteFin;
        try
          Q.Open;
          while not Q.Eof do
          begin
            OperatorId := Q.FieldByName('OperatorId').AsInteger;
            if OpIdxById.TryGetValue(OperatorId, OIdx) then
            begin
              NodeInicio := Q.FieldByName('FechaInicio').AsDateTime;
              NodeFin    := Q.FieldByName('FechaFin').AsDateTime;
              Horas      := Q.FieldByName('Horas').AsFloat;

              NodeDuracionMin := MinutesBetween(NodeFin, NodeInicio);
              if (NodeDuracionMin <= 0) or (Horas <= 0) then
              begin
                Q.Next;
                Continue;
              end;

              // Prorratear las horas asignadas a cada periodo segun solapamiento
              // temporal del nodo con el periodo.
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
                HorasParte := Horas * (OverlapMin / NodeDuracionMin);
                HorasMat[OIdx, J] := HorasMat[OIdx, J] + HorasParte;
              end;
            end;
            Q.Next;
          end;
        except
          // Si FS_PL_OperatorAssignment no existe, dejamos la matriz a 0
        end;
      finally
        Q.Free;
      end;
    end;

    // Calcular % usando capacidad del calendario del operario
    for I := 0 to High(FOperarios) do
    begin
      Cal := nil;
      if (DMPlanner.CalendarsRepo <> nil) and (FOperarios[I].CalendarId > 0) then
        DMPlanner.CalendarsRepo.TryGetById(FOperarios[I].CalendarId, Cal);
      for J := 0 to High(FPeriodos) do
      begin
        HorasPlan := HorasMat[I, J];
        if Cal = nil then
        begin
          FMatrix[I, J] := -1;
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
    OpIdxById.Free;
  end;

  FormResize(nil);
  pbMatrix.Invalidate;
  pbLegend.Invalidate;
end;

function TfrmHeatmapCargaOperario.ColorPorPct(P: Double; out TextDark: Boolean): TColor;
begin
  TextDark := True;
  if P < 0 then
  begin
    Result := CLR_NO_CAP;
    Exit;
  end;
  if P <= 0 then
    Result := CLR_VACIO
  else if P <= 10 then
    Result := CLR_R1_10
  else if P <= 25 then
    Result := CLR_R11_25
  else if P <= 50 then
    Result := CLR_R26_50
  else if P <= 75 then
    Result := CLR_R51_75
  else if P <= 90 then
    Result := CLR_R76_90
  else if P <= 100 then
  begin
    TextDark := False;
    Result := CLR_R91_100;
  end
  else if P <= 120 then
  begin
    TextDark := False;
    Result := CLR_R101_120;
  end
  else
  begin
    TextDark := False;
    Result := CLR_R_SOBRE;
  end;
end;

function TfrmHeatmapCargaOperario.FormatPct(P: Double): string;
begin
  if P < 0 then Exit('---');
  Result := FormatFloat('0', P) + '%';
end;

procedure TfrmHeatmapCargaOperario.ComputeMatrixSize(out AWidth, AHeight: Integer);
var
  NumOp, NumPer, TempW, TempH: Integer;
begin
  NumOp := Length(FOperarios);
  NumPer := Length(FPeriodos);
  TempW := NumPer * MTX_CELL_W;
  TempW := TempW + MTX_ROW_LABEL_W;
  TempW := TempW + MTX_PADDING;
  TempH := NumOp * MTX_CELL_H;
  TempH := TempH + MTX_COL_HEADER_H;
  TempH := TempH + MTX_PADDING;
  AWidth := TempW;
  AHeight := TempH;
  if AWidth < sbMatrix.ClientWidth then AWidth := sbMatrix.ClientWidth;
  if AHeight < sbMatrix.ClientHeight then AHeight := sbMatrix.ClientHeight;
end;

procedure TfrmHeatmapCargaOperario.pbLegendPaint(Sender: TObject);
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

  BoxW := 78;
  BoxH := pbLegend.Height - 4;
  Gap  := 4;
  X    := 4;
  Y    := 2;

  Chip(CLR_VACIO,    '0%',         True);
  Chip(CLR_R1_10,    '1-10%',      True);
  Chip(CLR_R11_25,   '11-25%',     True);
  Chip(CLR_R26_50,   '26-50%',     True);
  Chip(CLR_R51_75,   '51-75%',     True);
  Chip(CLR_R76_90,   '76-90%',     True);
  Chip(CLR_R91_100,  '91-100%',    False);
  Chip(CLR_R101_120, '101-120%',   False);
  Chip(CLR_R_SOBRE,  '>120%',      False);
end;

procedure TfrmHeatmapCargaOperario.pbMatrixPaint(Sender: TObject);
var
  C: TCanvas;
  I, J, X, Y, NumOp, NumPer: Integer;
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

  NumOp := Length(FOperarios);
  NumPer := Length(FPeriodos);

  if (NumOp = 0) or (NumPer = 0) then
  begin
    C.Font.Size := 10;
    C.Font.Color := CLR_TXT_LIGHT;
    C.Brush.Style := bsClear;
    R := pbMatrix.ClientRect;
    DrawText(C.Handle,
      PChar('No hay operarios o periodos para mostrar.'),
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

  // ----- Columna de operarios (nombres) -----
  C.Brush.Color := CLR_HEADER_BG;
  R := Rect(0, MTX_COL_HEADER_H, MTX_ROW_LABEL_W, MTX_COL_HEADER_H + NumOp * MTX_CELL_H);
  C.FillRect(R);

  for I := 0 to NumOp - 1 do
  begin
    Y := MTX_COL_HEADER_H + I * MTX_CELL_H;
    R := Rect(8, Y, MTX_ROW_LABEL_W - 8, Y + MTX_CELL_H);
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_HEADER_TX;
    C.Brush.Style := bsClear;
    Lbl := FOperarios[I].Nombre;
    if Trim(Lbl) = '' then Lbl := 'Operario #' + IntToStr(FOperarios[I].Id);
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
  for I := 0 to NumOp - 1 do
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
    C.LineTo(X, MTX_COL_HEADER_H + NumOp * MTX_CELL_H);
  end;
  for I := 0 to NumOp do
  begin
    Y := MTX_COL_HEADER_H + I * MTX_CELL_H;
    C.MoveTo(0, Y);
    C.LineTo(MTX_ROW_LABEL_W + NumPer * MTX_CELL_W, Y);
  end;
end;

end.
