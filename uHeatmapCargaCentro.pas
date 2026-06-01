unit uHeatmapCargaCentro;

{
  Heatmap de carga por centro y periodo (estilo skills-matrix de gesti'on
  visual industrial).

  Eje horizontal: periodos (d'ias / semanas / meses, configurable).
  Eje vertical:   centros de trabajo activos.
  Celda:          % de ocupaci'on = horas_planificadas / horas_capacidad.

  Codificaci'on de color (gradiente fino):
       0%        Vac'io          (gris muy claro)
     1..10%      Verde muy claro
    11..25%      Verde claro
    26..50%      Verde
    51..75%      Verde-Amarillo
    76..90%      Amarillo
    91..100%     Naranja
   101..120%     Rojo claro
     >120%      Rojo intenso (sobrecarga grave)

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
  cxCheckComboBox, cxCheckBox, cxEdit, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  uGanttTypes, uCentresRepo, uCentreCalendar, dxSkinsCore, dxSkinBasic,
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
    lblCentros: TLabel;
    cbCentros: TcxCheckComboBox;
    pnlLegend: TPanel;
    pbLegend: TPaintBox;
    sbMatrix: TScrollBox;
    pbMatrix: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnRecalcularClick(Sender: TObject);
    procedure ParametrosChange(Sender: TObject);
    procedure pbLegendPaint(Sender: TObject);
    procedure pbMatrixPaint(Sender: TObject);
    procedure cbCentrosChange(Sender: TObject);
  private
    FAllCentres: TArray<TCentreTreball>;
    FCentres: TArray<TCentreTreball>;
    FPeriodos: TArray<TPeriodo>;
    // [centroIdx, periodoIdx] -> %  (-1 si sin capacidad)
    FMatrix: array of array of Double;
    FUpdatingCentros: Boolean;
    FLoadingPrefs: Boolean;
    procedure BuildPeriodos;
    procedure CargarCentrosCombo;
    procedure AplicarFiltroCentros;
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
  MTX_ROW_LABEL_W  = 180;
  MTX_COL_HEADER_H = 46;
  MTX_PADDING      = 12;

const
  // Paleta gradiente (BGR). 9 rangos: 0, 1-10, 11-25, 26-50, 51-75, 76-90, 91-100, 101-120, >120
  CLR_VACIO:     TColor = $00F0F0F0;  // gris muy claro (0%)
  CLR_R1_10:     TColor = $00D9F5D9;  // verde muy claro
  CLR_R11_25:    TColor = $00B5E5B5;  // verde claro
  CLR_R26_50:    TColor = $0085C285;  // verde
  CLR_R51_75:    TColor = $0066D9B3;  // verde-amarillo
  CLR_R76_90:    TColor = $005CD0F5;  // amarillo
  CLR_R91_100:   TColor = $002E8FE8;  // naranja
  CLR_R101_120:  TColor = $004D6FD7;  // rojo claro
  CLR_R_SOBRE:   TColor = $002F2FC4;  // rojo intenso (>120%)
  CLR_NO_CAP:    TColor = $00E8E8E8;  // gris (sin calendario)

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
  FLoadingPrefs := True;
  try
    cmbGranularidad.ItemIndex := 1; // Semanas por defecto
    dtDesde.Date := Trunc(Now);
    spNumPeriodos.Value := 6;
    CargarCentrosCombo;
    LoadPrefs; // sobreescribe los defaults con la ultima config del usuario
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
  THelpViewer.InstallHelp(Self, 'uHeatmapCargaCentro',
    'Heatmap de carga por centro');
end;

procedure TfrmHeatmapCargaCentro.LoadPrefs;
var
  Js: string;
  Root: TJSONObject;
  V: TJSONValue;
  Arr: TJSONArray;
  IdsSet: TDictionary<Integer, Boolean>;
  I, Cid: Integer;
  TodosSel: Boolean;
begin
  if (DMPlanner = nil) or (DMPlanner.UserPrefs = nil) then Exit;
  Js := DMPlanner.UserPrefs.Load('HeatmapCargaCentro');
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

    // Centros: null/ausente => Todos seleccionados (estado especial).
    //          array => lista explicita de IDs.
    V := Root.GetValue('centros');
    TodosSel := (V = nil) or (V is TJSONNull);
    FUpdatingCentros := True;
    try
      if TodosSel then
      begin
        for I := 0 to cbCentros.Properties.Items.Count - 1 do
          cbCentros.States[I] := cbsChecked;
      end
      else if V is TJSONArray then
      begin
        Arr := V as TJSONArray;
        IdsSet := TDictionary<Integer, Boolean>.Create;
        try
          for I := 0 to Arr.Count - 1 do
            IdsSet.AddOrSetValue((Arr.Items[I] as TJSONNumber).AsInt, True);
          cbCentros.States[0] := cbsUnchecked; // sera ajustado segun coincidencia
          for I := 0 to High(FAllCentres) do
          begin
            Cid := FAllCentres[I].Id;
            if IdsSet.ContainsKey(Cid) then
              cbCentros.States[I + 1] := cbsChecked
            else
              cbCentros.States[I + 1] := cbsUnchecked;
          end;
          // Sincronizar el "(Todos)" segun estado real
          if IdsSet.Count = Length(FAllCentres) then
            cbCentros.States[0] := cbsChecked
          else
            cbCentros.States[0] := cbsUnchecked;
        finally
          IdsSet.Free;
        end;
      end;
    finally
      FUpdatingCentros := False;
    end;
  finally
    Root.Free;
  end;
end;

procedure TfrmHeatmapCargaCentro.SavePrefs;
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

    // Si "(Todos)" esta marcado, persistimos null para que centros nuevos
    // aparezcan automaticamente la proxima vez.
    TodosSel := (cbCentros.Properties.Items.Count > 0) and
                (cbCentros.States[0] = cbsChecked);
    if TodosSel then
      Root.AddPair('centros', TJSONNull.Create)
    else
    begin
      Arr := TJSONArray.Create;
      for I := 0 to High(FAllCentres) do
        if (I + 1 < cbCentros.Properties.Items.Count) and
           (cbCentros.States[I + 1] = cbsChecked) then
          Arr.AddElement(TJSONNumber.Create(FAllCentres[I].Id));
      Root.AddPair('centros', Arr);
    end;

    DMPlanner.UserPrefs.Save('HeatmapCargaCentro', Root.ToJSON);
  finally
    Root.Free;
  end;
end;

procedure TfrmHeatmapCargaCentro.CargarCentrosCombo;
var
  I: Integer;
  Lbl: string;
begin
  FUpdatingCentros := True;
  try
    if DMPlanner.CentresRepo <> nil then
      FAllCentres := DMPlanner.CentresRepo.GetAll
    else
      SetLength(FAllCentres, 0);

    cbCentros.Properties.Items.Clear;
    // Item 0: pseudo "Todos" - marca/desmarca el resto
    cbCentros.Properties.Items.AddCheckItem('(Todos)');
    cbCentros.States[0] := cbsChecked;
    for I := 0 to High(FAllCentres) do
    begin
      Lbl := FAllCentres[I].Titulo;
      if Trim(Lbl) = '' then Lbl := FAllCentres[I].CodiCentre;
      cbCentros.Properties.Items.AddCheckItem(Lbl);
      cbCentros.States[I + 1] := cbsChecked;
    end;
    if Length(FAllCentres) = 0 then
      cbCentros.Properties.EmptySelectionText := 'Sin centros disponibles'
    else
      cbCentros.Properties.EmptySelectionText := 'Ningun centro seleccionado';
  finally
    FUpdatingCentros := False;
  end;
end;

procedure TfrmHeatmapCargaCentro.AplicarFiltroCentros;
var
  I, K: Integer;
begin
  SetLength(FCentres, 0);
  K := 0;
  SetLength(FCentres, Length(FAllCentres));
  // Indices 1..N corresponden a centros (0 es "(Todos)")
  for I := 0 to High(FAllCentres) do
    if (I + 1 < cbCentros.Properties.Items.Count) and
       (cbCentros.States[I + 1] = cbsChecked) then
    begin
      FCentres[K] := FAllCentres[I];
      Inc(K);
    end;
  SetLength(FCentres, K);
end;

procedure TfrmHeatmapCargaCentro.cbCentrosChange(Sender: TObject);
var
  I: Integer;
  TodosChecked, AllReal: Boolean;
  NewState: TcxCheckBoxState;
begin
  if FUpdatingCentros then Exit;
  if cbCentros.Properties.Items.Count = 0 then
  begin
    RecalcularDatos;
    Exit;
  end;

  FUpdatingCentros := True;
  try
    TodosChecked := (cbCentros.States[0] = cbsChecked);
    AllReal := True;
    for I := 1 to cbCentros.Properties.Items.Count - 1 do
      if cbCentros.States[I] <> cbsChecked then
      begin
        AllReal := False;
        Break;
      end;

    if TodosChecked <> AllReal then
    begin
      // El usuario clico "(Todos)": propagar al resto
      if TodosChecked then NewState := cbsChecked else NewState := cbsUnchecked;
      for I := 1 to cbCentros.Properties.Items.Count - 1 do
        cbCentros.States[I] := NewState;
    end
    else
    begin
      // El usuario clico un centro: sincronizar "(Todos)" segun estado real
      if AllReal then
        cbCentros.States[0] := cbsChecked
      else
        cbCentros.States[0] := cbsUnchecked;
    end;
  finally
    FUpdatingCentros := False;
  end;

  RecalcularDatos;
  SavePrefs;
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

procedure TfrmHeatmapCargaCentro.btnRecalcularClick(Sender: TObject);
begin
  RecalcularDatos;
end;

procedure TfrmHeatmapCargaCentro.ParametrosChange(Sender: TObject);
begin
  // Recalcular automaticament al canviar parametres
  RecalcularDatos;
  SavePrefs;
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

  // Aplicar filtro del CheckComboBox sobre los centros cargados
  AplicarFiltroCentros;

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
