unit uHeatmapEntregasVsCarga;

{
  Heatmap de entregas comprometidas vs capacidad por centro y periodo.

  Eje horizontal: periodos (dias / semanas / meses, configurable).
  Eje vertical:   centros de trabajo activos.
  Celda:          % compromiso = horas_entrega / horas_capacidad.

  Diferencia clave respecto a uHeatmapCargaCentro:
    - El de carga reparte la duracion del nodo entre los periodos en los que
      cae fisicamente la barra del Gantt (FechaInicio..FechaFin).
    - Este reparte la duracion del nodo en el periodo en el que cae su
      FechaEntrega (el compromiso comercial), independientemente de cuando
      este planificado. Sirve para responder "?podemos aceptar mas pedidos
      para la semana X?" antes de planificar.

  Fuente de datos:
    - Nodos del proyecto activo (DMPlanner.CurrentProjectId).
    - FechaEntrega del nodo en FS_PL_NodeData.
    - Capacidad del centro: calendario asignado via WorkingMinutesBetween.
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
  TGranularidadEnt = (geDias, geSemanas, geMeses);

  TPeriodoEnt = record
    Inicio: TDateTime;
    Fin:    TDateTime;
    Label_: string;
  end;

  TfrmHeatmapEntregasVsCarga = class(TForm)
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
    FPeriodos: TArray<TPeriodoEnt>;
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
  MTX_CELL_W       = 90;
  MTX_CELL_H       = 38;
  MTX_ROW_LABEL_W  = 180;
  MTX_COL_HEADER_H = 46;
  MTX_PADDING      = 12;

const
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

class procedure TfrmHeatmapEntregasVsCarga.Execute;
var
  F: TfrmHeatmapEntregasVsCarga;
begin
  F := TfrmHeatmapEntregasVsCarga.Create(nil);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmHeatmapEntregasVsCarga.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  sbMatrix.DoubleBuffered := True;
  FLoadingPrefs := True;
  try
    cmbGranularidad.ItemIndex := 1; // Semanas
    dtDesde.Date := Trunc(Now);
    spNumPeriodos.Value := 6;
    CargarCentrosCombo;
    LoadPrefs;
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
  THelpViewer.InstallHelp(Self, 'uHeatmapEntregasVsCarga',
    'Heatmap de entregas vs capacidad');
end;

procedure TfrmHeatmapEntregasVsCarga.LoadPrefs;
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
  Js := DMPlanner.UserPrefs.Load('HeatmapEntregasVsCarga');
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
          cbCentros.States[0] := cbsUnchecked;
          for I := 0 to High(FAllCentres) do
          begin
            Cid := FAllCentres[I].Id;
            if IdsSet.ContainsKey(Cid) then
              cbCentros.States[I + 1] := cbsChecked
            else
              cbCentros.States[I + 1] := cbsUnchecked;
          end;
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

procedure TfrmHeatmapEntregasVsCarga.SavePrefs;
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

    DMPlanner.UserPrefs.Save('HeatmapEntregasVsCarga', Root.ToJSON);
  finally
    Root.Free;
  end;
end;

procedure TfrmHeatmapEntregasVsCarga.CargarCentrosCombo;
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

procedure TfrmHeatmapEntregasVsCarga.AplicarFiltroCentros;
var
  I, K: Integer;
begin
  SetLength(FCentres, 0);
  K := 0;
  SetLength(FCentres, Length(FAllCentres));
  for I := 0 to High(FAllCentres) do
    if (I + 1 < cbCentros.Properties.Items.Count) and
       (cbCentros.States[I + 1] = cbsChecked) then
    begin
      FCentres[K] := FAllCentres[I];
      Inc(K);
    end;
  SetLength(FCentres, K);
end;

procedure TfrmHeatmapEntregasVsCarga.cbCentrosChange(Sender: TObject);
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
      if TodosChecked then NewState := cbsChecked else NewState := cbsUnchecked;
      for I := 1 to cbCentros.Properties.Items.Count - 1 do
        cbCentros.States[I] := NewState;
    end
    else
    begin
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

procedure TfrmHeatmapEntregasVsCarga.FormDestroy(Sender: TObject);
begin
end;

procedure TfrmHeatmapEntregasVsCarga.FormResize(Sender: TObject);
var
  W, H: Integer;
begin
  ComputeMatrixSize(W, H);
  pbMatrix.SetBounds(0, 0, W, H);
end;

procedure TfrmHeatmapEntregasVsCarga.btnRecalcularClick(Sender: TObject);
begin
  RecalcularDatos;
end;

procedure TfrmHeatmapEntregasVsCarga.ParametrosChange(Sender: TObject);
begin
  RecalcularDatos;
  SavePrefs;
end;

procedure TfrmHeatmapEntregasVsCarga.BuildPeriodos;
var
  Gran: TGranularidadEnt;
  NumPer, I: Integer;
  Cursor: TDateTime;
  P: TPeriodoEnt;
  YYYY, MM, DD: Word;
begin
  Gran := TGranularidadEnt(cmbGranularidad.ItemIndex);
  NumPer := spNumPeriodos.Value;
  if NumPer < 1 then NumPer := 1;

  SetLength(FPeriodos, NumPer);
  Cursor := Trunc(dtDesde.Date);

  if Gran = geSemanas then
    Cursor := Cursor - ((DayOfTheWeek(Cursor) + 6) mod 7);

  if Gran = geMeses then
  begin
    DecodeDate(Cursor, YYYY, MM, DD);
    Cursor := EncodeDate(YYYY, MM, 1);
  end;

  for I := 0 to NumPer - 1 do
  begin
    P.Inicio := Cursor;
    case Gran of
      geDias:
        begin
          P.Fin := IncDay(Cursor, 1);
          P.Label_ := FormatDateTime('dd/mm', Cursor);
        end;
      geSemanas:
        begin
          P.Fin := IncDay(Cursor, 7);
          P.Label_ := 'S' + IntToStr(WeekOf(Cursor));
        end;
      geMeses:
        begin
          P.Fin := IncMonth(Cursor, 1);
          P.Label_ := FormatDateTime('mmm yy', Cursor);
        end;
    end;
    FPeriodos[I] := P;
    Cursor := P.Fin;
  end;
end;

procedure TfrmHeatmapEntregasVsCarga.RecalcularDatos;
var
  Q: TADOQuery;
  ProjectId: Integer;
  HorizonteInicio, HorizonteFin: TDateTime;
  CenterIdxById: TDictionary<Integer, Integer>;
  I, J, CIdx: Integer;
  CenterId: Integer;
  FechaEntrega: TDateTime;
  DurMin: Double;
  Cal: TCentreCalendar;
  CapacityMin: Integer;
  HorasEntrega, HorasCap, Pct: Double;
  // [centroIdx, periodoIdx] -> horas entrega acumuladas
  HorasMat: array of array of Double;
begin
  BuildPeriodos;
  if Length(FPeriodos) = 0 then
  begin
    SetLength(FMatrix, 0);
    pbMatrix.Invalidate;
    Exit;
  end;

  AplicarFiltroCentros;

  SetLength(HorasMat, Length(FCentres), Length(FPeriodos));
  SetLength(FMatrix, Length(FCentres), Length(FPeriodos));

  if Length(FCentres) = 0 then
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
        // Asignamos cada nodo al periodo en el que cae su FechaEntrega.
        // Si FechaEntrega es NULL o cae fuera del horizonte, lo ignoramos.
        Q.SQL.Text :=
          'SELECT n.CenterId, nd.FechaEntrega, nd.DuracionMin ' +
          'FROM FS_PL_Node n ' +
          'INNER JOIN FS_PL_NodeData nd ON nd.CodigoEmpresa = n.CodigoEmpresa ' +
          '                            AND nd.NodeId = n.NodeId ' +
          'WHERE n.CodigoEmpresa = :CE AND n.ProjectId = :PID ' +
          '  AND n.CenterId IS NOT NULL ' +
          '  AND nd.FechaEntrega IS NOT NULL ' +
          '  AND nd.FechaEntrega >= :HInicio AND nd.FechaEntrega < :HFin';
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
            FechaEntrega := Q.FieldByName('FechaEntrega').AsDateTime;
            DurMin := Q.FieldByName('DuracionMin').AsFloat;
            if DurMin > 0 then
            begin
              // Localizar el periodo en el que cae FechaEntrega
              for J := 0 to High(FPeriodos) do
                if (FechaEntrega >= FPeriodos[J].Inicio) and
                   (FechaEntrega < FPeriodos[J].Fin) then
                begin
                  HorasMat[CIdx, J] := HorasMat[CIdx, J] + (DurMin / 60.0);
                  Break;
                end;
            end;
          end;
          Q.Next;
        end;
      finally
        Q.Free;
      end;
    end;

    // Calcular % compromiso = horas_entrega / horas_capacidad
    for I := 0 to High(FCentres) do
    begin
      Cal := nil;
      if DMPlanner.CentresRepo <> nil then
        Cal := DMPlanner.CentresRepo.GetCalendarFor(FCentres[I].Id);
      for J := 0 to High(FPeriodos) do
      begin
        HorasEntrega := HorasMat[I, J];
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
        Pct := (HorasEntrega / HorasCap) * 100.0;
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

function TfrmHeatmapEntregasVsCarga.ColorPorPct(P: Double; out TextDark: Boolean): TColor;
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

function TfrmHeatmapEntregasVsCarga.FormatPct(P: Double): string;
begin
  if P < 0 then Exit('---');
  Result := FormatFloat('0', P) + '%';
end;

procedure TfrmHeatmapEntregasVsCarga.ComputeMatrixSize(out AWidth, AHeight: Integer);
var
  NumCen, NumPer, TempW, TempH: Integer;
begin
  NumCen := Length(FCentres);
  NumPer := Length(FPeriodos);
  TempW := NumPer * MTX_CELL_W + MTX_ROW_LABEL_W + MTX_PADDING;
  TempH := NumCen * MTX_CELL_H + MTX_COL_HEADER_H + MTX_PADDING;
  AWidth := TempW;
  AHeight := TempH;
  if AWidth < sbMatrix.ClientWidth then AWidth := sbMatrix.ClientWidth;
  if AHeight < sbMatrix.ClientHeight then AHeight := sbMatrix.ClientHeight;
end;

procedure TfrmHeatmapEntregasVsCarga.pbLegendPaint(Sender: TObject);
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

procedure TfrmHeatmapEntregasVsCarga.pbMatrixPaint(Sender: TObject);
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

  // Cabecera de periodos
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

  // Columna de centros
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

  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, MTX_ROW_LABEL_W, MTX_COL_HEADER_H));

  // Celdas
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

  // Grid
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
