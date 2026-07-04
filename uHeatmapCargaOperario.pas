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
  cxButtons,
  uGanttTypes, uCentreCalendar, uDemoMode, dxSkinsCore, dxSkinBasic,
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
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue, Vcl.Menus;

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

  // Tipos con nombre para las matrices [operarioIdx, periodoIdx]. Necesarios
  // para poder asignar entre campos y variables locales (dos `array of array`
  // anonimos son tipos incompatibles en Delphi -> E2008).
  TMatrizDbl = array of array of Double;
  TMatrizInt = array of array of Integer;

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
    btnRecalcular: TcxButton;
    lblOperarios: TLabel;
    cbOperarios: TcxCheckComboBox;
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
    procedure cbOperariosChange(Sender: TObject);
  private
    FAllOperarios: TArray<TOperarioRow>;
    FOperarios: TArray<TOperarioRow>;
    FPeriodos: TArray<TPeriodoOp>;
    // [operarioIdx, periodoIdx] -> %  (-1 si sin capacidad)
    FMatrix: TMatrizDbl;
    // Datos de detalle por celda (para el tooltip)
    FHorasPlan: TMatrizDbl;   // horas asignadas
    FHorasCap:  TMatrizDbl;   // horas de capacidad (-1 sin cap.)
    FNumNodos:  TMatrizInt;   // nº de nodos que aportan carga
    FHintCelda: TPoint;                       // celda [op,per] bajo el raton (-1,-1 = ninguna)
    FSortCol: Integer;                         // 0=nombre, 1=promedio
    FSortDesc: Boolean;
    FVerDetalle: Boolean;                      // muestra horas/nodos dentro de la celda
    FBtnExportPNG: TcxButton;
    FBtnExportCSV: TcxButton;
    FBtnDetalle: TcxButton;
    FCmbDepto: TComboBox;                       // filtro por departamento
    FLblDepto: TLabel;
    FDeptoIds: TArray<Integer>;                 // DepartmentId por indice del combo (0 = Todos)
    FDeptoSel: Integer;                         // DepartmentId activo (0 = Todos)
    FUpdatingOps: Boolean;
    FLoadingPrefs: Boolean;
    procedure BuildPeriodos;
    procedure CargarOperariosDesdeSQL;
    procedure CargarOperariosDemo;
    procedure LlenarMatrizDemo;
    procedure DemoChanged(Sender: TObject);
    procedure CargarOperariosCombo;
    procedure AplicarFiltroOperarios;
    procedure LoadPrefs;
    procedure SavePrefs;
    procedure RecalcularDatos;
    procedure pbMatrixMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbMatrixMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure OrdenarFilas;
    procedure DibujarMatriz(C: TCanvas; AWidth, AHeight: Integer);
    procedure ExportarPNGClick(Sender: TObject);
    procedure ExportarCSVClick(Sender: TObject);
    procedure DetalleClick(Sender: TObject);
    procedure EstiloBotonHeader(var ABtn: TcxButton);
    procedure CargarDepartamentosCombo;
    procedure DeptoChange(Sender: TObject);
    function RowH: Integer;                     // alto de fila (segun Ver detalle)
    function TotalH: Integer;                   // alto de la fila resumen (segun Ver detalle)
    function CeldaEnPunto(AX, AY: Integer; out AOp, APer: Integer): Boolean;
    function ColorPorPct(P: Double; out TextDark: Boolean): TColor;
    function FormatPct(P: Double): string;
    procedure ComputeMatrixSize(out AWidth, AHeight: Integer);
  public
    class procedure Execute;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uHelpViewer, System.JSON, System.IOUtils,
  Vcl.Imaging.pngimage;

const
  // Dimensiones
  MTX_CELL_W       = 90;
  MTX_CELL_H       = 38;   // alto de fila normal
  MTX_CELL_H_DET   = 60;   // alto de fila con "Ver detalle" activo
  MTX_ROW_LABEL_W  = 200;
  MTX_COL_HEADER_H = 46;
  MTX_PADDING      = 12;
  MTX_SPARK_W      = 130;  // columna sparkline (tendencia por operario)
  MTX_AVG_W        = 96;   // columna "Promedio" a la derecha de la matriz
  MTX_TOTAL_H      = 42;   // fila resumen (saturacion global por periodo)
  MTX_TOTAL_H_DET  = 60;   // fila resumen con "Ver detalle" activo

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
  CLR_TOTAL_BG:  TColor = $003C3630;   // banda oscura para destacar la fila TOTAL
  CLR_TOTAL_TX:  TColor = $00FFFFFF;

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
  pbMatrix.OnMouseMove := pbMatrixMouseMove;
  pbMatrix.OnMouseDown := pbMatrixMouseDown;
  pbMatrix.ShowHint := True;
  FHintCelda := Point(-1, -1);
  FSortCol := 0;      // por nombre
  FSortDesc := False;

  // Estilo comun de los botones (igual que la toolbar del header principal).
  EstiloBotonHeader(FBtnExportPNG);
  FBtnExportPNG.Parent := pnlHeader;
  FBtnExportPNG.SetBounds(pnlHeader.Width - 110, 20, 96, 25);
  FBtnExportPNG.Anchors := [akTop, akRight];
  FBtnExportPNG.Caption := 'Exportar PNG';
  FBtnExportPNG.OnClick := ExportarPNGClick;

  EstiloBotonHeader(FBtnExportCSV);
  FBtnExportCSV.Parent := pnlHeader;
  FBtnExportCSV.SetBounds(pnlHeader.Width - 212, 20, 96, 25);
  FBtnExportCSV.Anchors := [akTop, akRight];
  FBtnExportCSV.Caption := 'Exportar CSV';
  FBtnExportCSV.OnClick := ExportarCSVClick;

  // "Ver detalle": control de vista (toggle), se queda en la toolbar de filtros.
  EstiloBotonHeader(FBtnDetalle);
  FBtnDetalle.Parent := pnlToolbar;
  FBtnDetalle.SetBounds(btnRecalcular.Left - 120, btnRecalcular.Top, 110, 28);
  FBtnDetalle.Anchors := [akTop, akRight];
  FBtnDetalle.Caption := 'Ver detalle';
  FBtnDetalle.SpeedButtonOptions.GroupIndex := 5;
  FBtnDetalle.SpeedButtonOptions.AllowAllUp := True;
  FBtnDetalle.OnClick := DetalleClick;

  // Filtro por departamento (label + combo).
  FLblDepto := TLabel.Create(Self);
  FLblDepto.Parent := pnlToolbar;
  FLblDepto.SetBounds(cbOperarios.Left + cbOperarios.Width + 16, lblOperarios.Top, 90, 15);
  FLblDepto.Caption := 'Departamento:';

  FCmbDepto := TComboBox.Create(Self);
  FCmbDepto.Parent := pnlToolbar;
  FCmbDepto.SetBounds(FLblDepto.Left, cbOperarios.Top, 200, 23);
  FCmbDepto.Style := csDropDownList;
  FCmbDepto.OnChange := DeptoChange;

  FDeptoSel := 0;

  FLoadingPrefs := True;
  try
    cmbGranularidad.ItemIndex := 1;
    dtDesde.Date := Trunc(Now);
    spNumPeriodos.Value := 6;
    CargarDepartamentosCombo;
    CargarOperariosDesdeSQL;
    CargarOperariosCombo;
    LoadPrefs;
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
  DemoMode.AddListener(DemoChanged);
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

  if DemoMode.Active then
  begin
    CargarOperariosDemo;
    Exit;
  end;

  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) or
     (not DMPlanner.ADOConnection.Connected) then
    Exit;

  List := TList<TOperarioRow>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    if FDeptoSel > 0 then
      Q.SQL.Text :=
        'SELECT o.OperatorId, o.Nombre, ISNULL(o.CalendarId, 0) AS CalendarId ' +
        'FROM FS_PL_Operator o ' +
        'INNER JOIN FS_PL_OperatorDepartment od ' +
        '        ON od.CodigoEmpresa = o.CodigoEmpresa ' +
        '       AND od.OperatorId = o.OperatorId ' +
        'WHERE o.CodigoEmpresa = :CE AND ISNULL(o.Activo, 1) = 1 ' +
        '  AND od.DepartmentId = :DEP ' +
        'ORDER BY o.Nombre'
    else
      Q.SQL.Text :=
        'SELECT OperatorId, Nombre, ISNULL(CalendarId, 0) AS CalendarId ' +
        'FROM FS_PL_Operator ' +
        'WHERE CodigoEmpresa = :CE AND ISNULL(Activo, 1) = 1 ' +
        'ORDER BY Nombre';
    Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
    if FDeptoSel > 0 then
      Q.Parameters.ParamByName('DEP').Value := FDeptoSel;
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

procedure TfrmHeatmapCargaOperario.CargarOperariosDemo;
const
  NOMBRES: array[0..17] of string = (
    'Antonio Garc'#237'a', 'Manuel Fern'#225'ndez', 'Jos'#233' Mart'#237'nez',
    'Francisco L'#243'pez', 'David S'#225'nchez', 'Javier Gonz'#225'lez',
    'Carlos Rodr'#237'guez', 'Miguel P'#233'rez', 'Sergio G'#243'mez',
    'Rub'#233'n Ruiz', 'Alberto D'#237'az', 'Pablo Moreno',
    'Iv'#225'n Jim'#233'nez', 'Marta Romero', 'Laura Navarro',
    'Cristina Torres', 'Nuria Vidal', 'Sara Molina');
var
  I, K: Integer;
begin
  SetLength(FAllOperarios, Length(NOMBRES));
  K := 0;
  for I := 0 to High(NOMBRES) do
  begin
    // Reparto ficticio en 4 departamentos (por indice). En modo demo el
    // DepartmentId demo va de 1..4; 0 = Todos muestra los 18.
    if (FDeptoSel > 0) and ((I mod 4) + 1 <> FDeptoSel) then Continue;
    FAllOperarios[K].Id := 9000 + I;      // ids ficticios, no chocan con reales
    FAllOperarios[K].Nombre := NOMBRES[I];
    FAllOperarios[K].CalendarId := 0;     // irrelevante: la matriz se genera directa
    Inc(K);
  end;
  SetLength(FAllOperarios, K);
end;

procedure TfrmHeatmapCargaOperario.CargarDepartamentosCombo;
var
  Q: TADOQuery;
  Ids: TList<Integer>;
begin
  FCmbDepto.Items.BeginUpdate;
  Ids := TList<Integer>.Create;
  try
    FCmbDepto.Items.Clear;
    FCmbDepto.Items.Add('(Todos los departamentos)');
    Ids.Add(0);

    if DemoMode.Active then
    begin
      FCmbDepto.Items.Add('Mecanizado');   Ids.Add(1);
      FCmbDepto.Items.Add('Montaje');      Ids.Add(2);
      FCmbDepto.Items.Add('Pintura');      Ids.Add(3);
      FCmbDepto.Items.Add('Calidad');      Ids.Add(4);
    end
    else if (DMPlanner <> nil) and (DMPlanner.ADOConnection <> nil) and
            (DMPlanner.ADOConnection.Connected) then
    begin
      Q := TADOQuery.Create(nil);
      try
        Q.Connection := DMPlanner.ADOConnection;
        Q.SQL.Text :=
          'SELECT DepartmentId, Nombre FROM FS_PL_Department ' +
          'WHERE CodigoEmpresa = :CE ORDER BY Nombre';
        Q.Parameters.ParamByName('CE').Value := DMPlanner.CodigoEmpresa;
        try
          Q.Open;
          while not Q.Eof do
          begin
            FCmbDepto.Items.Add(Q.FieldByName('Nombre').AsString);
            Ids.Add(Q.FieldByName('DepartmentId').AsInteger);
            Q.Next;
          end;
        except
          // Si la tabla no existe, solo queda "(Todos)"
        end;
      finally
        Q.Free;
      end;
    end;

    FDeptoIds := Ids.ToArray;
    // Mantener seleccion si el depto activo sigue existiendo; si no, Todos.
    var Idx: Integer := 0;
    for var K := 0 to High(FDeptoIds) do
      if FDeptoIds[K] = FDeptoSel then begin Idx := K; Break; end;
    FCmbDepto.ItemIndex := Idx;
    FDeptoSel := FDeptoIds[Idx];
  finally
    Ids.Free;
    FCmbDepto.Items.EndUpdate;
  end;
end;

procedure TfrmHeatmapCargaOperario.DeptoChange(Sender: TObject);
begin
  if FCmbDepto.ItemIndex < 0 then Exit;
  if FCmbDepto.ItemIndex <= High(FDeptoIds) then
    FDeptoSel := FDeptoIds[FCmbDepto.ItemIndex]
  else
    FDeptoSel := 0;

  // Recargar operarios del departamento y refrescar.
  FLoadingPrefs := True;
  try
    CargarOperariosDesdeSQL;
    CargarOperariosCombo;
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
end;

procedure TfrmHeatmapCargaOperario.LlenarMatrizDemo;
var
  I, J, Seed: Integer;
  Serie: TArray<Double>;
  Objetivo: Double;
begin
  // Genera una matriz de %  creible y determinista (sin Random) para el modo
  // demo. Cada operario tiene una carga "objetivo" distinta; a lo largo de los
  // periodos oscila con DemoSerieHaciaValor. Alguna celda supera el 100%
  // (sobrecarga) para que el heatmap muestre toda la paleta.
  for I := 0 to High(FOperarios) do
  begin
    // Objetivo por operario: reparto entre ~55% y ~115% segun su posicion.
    Objetivo := 55 + ((FOperarios[I].Id * 37) mod 65);   // 55..119
    Seed := FOperarios[I].Id;
    Serie := DemoSerieHaciaValor(Objetivo, Length(FPeriodos), 0.28, Seed);
    for J := 0 to High(FPeriodos) do
    begin
      FMatrix[I, J] := Serie[J];
      // Detalle ficticio coherente con el % (capacidad ~40h/semana como base).
      FHorasCap[I, J] := 40;
      FHorasPlan[I, J] := 40 * Serie[J] / 100.0;
      FNumNodos[I, J] := 2 + ((FOperarios[I].Id + J) mod 5);   // 2..6 nodos
    end;
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

procedure TfrmHeatmapCargaOperario.OrdenarFilas;
// Reordena FOperarios y todas las matrices de detalle de forma coherente,
// segun la columna de ordenacion activa (0=nombre, 1=promedio de carga).
// Se llama al final de RecalcularDatos, cuando FMatrix ya esta poblada.
var
  N, I, J, A, B, Key, C: Integer;
  S: Double;
  Mayor: Boolean;
  Ord: TArray<Integer>;
  Prom: TArray<Double>;
  NewOps: TArray<TOperarioRow>;
  NM, NHP, NHC: TMatrizDbl;
  NNN: TMatrizInt;
begin
  N := Length(FOperarios);
  if N < 2 then Exit;

  // Promedio de carga por operario (ignora celdas sin capacidad).
  SetLength(Prom, N);
  for I := 0 to N - 1 do
  begin
    S := 0; C := 0;
    for J := 0 to High(FPeriodos) do
      if FMatrix[I, J] >= 0 then begin S := S + FMatrix[I, J]; Inc(C); end;
    if C > 0 then Prom[I] := S / C else Prom[I] := -1;
  end;

  // Orden inicial 0..N-1, insertion sort estable sobre el criterio.
  SetLength(Ord, N);
  for I := 0 to N - 1 do Ord[I] := I;

  for I := 1 to N - 1 do
  begin
    Key := Ord[I];
    J := I - 1;
    while J >= 0 do
    begin
      A := Ord[J]; B := Key;
      // Mayor = ¿A debe ir DESPUES de B?
      if FSortCol = 1 then
      begin
        if FSortDesc then Mayor := Prom[A] < Prom[B]
                     else Mayor := Prom[A] > Prom[B];
      end
      else
      begin
        if FSortDesc then Mayor := CompareText(FOperarios[A].Nombre, FOperarios[B].Nombre) < 0
                     else Mayor := CompareText(FOperarios[A].Nombre, FOperarios[B].Nombre) > 0;
      end;
      if not Mayor then Break;
      Ord[J + 1] := Ord[J];
      Dec(J);
    end;
    Ord[J + 1] := Key;
  end;

  // Aplica la permutacion a todos los arrays paralelos.
  SetLength(NewOps, N);
  SetLength(NM, N, Length(FPeriodos));
  SetLength(NHP, N, Length(FPeriodos));
  SetLength(NHC, N, Length(FPeriodos));
  SetLength(NNN, N, Length(FPeriodos));
  for I := 0 to N - 1 do
  begin
    NewOps[I] := FOperarios[Ord[I]];
    for J := 0 to High(FPeriodos) do
    begin
      NM[I, J]  := FMatrix[Ord[I], J];
      NHP[I, J] := FHorasPlan[Ord[I], J];
      NHC[I, J] := FHorasCap[Ord[I], J];
      NNN[I, J] := FNumNodos[Ord[I], J];
    end;
  end;
  FOperarios := NewOps;
  FMatrix := NM; FHorasPlan := NHP; FHorasCap := NHC; FNumNodos := NNN;
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
  DemoMode.RemoveListener(DemoChanged);
end;

procedure TfrmHeatmapCargaOperario.DemoChanged(Sender: TObject);
begin
  // Al conmutar el modo demo, recargamos departamentos y operarios (en modo
  // demo se generan ficticios; en modo real vuelven los de la BD) y recalculamos.
  FDeptoSel := 0;
  FLoadingPrefs := True;
  try
    CargarDepartamentosCombo;
    CargarOperariosDesdeSQL;
    CargarOperariosCombo;
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
end;

procedure TfrmHeatmapCargaOperario.FormResize(Sender: TObject);
var
  W, H: Integer;
begin
  ComputeMatrixSize(W, H);
  pbMatrix.SetBounds(0, 0, W, H);
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
  SetLength(FHorasPlan, Length(FOperarios), Length(FPeriodos));
  SetLength(FHorasCap, Length(FOperarios), Length(FPeriodos));
  SetLength(FNumNodos, Length(FOperarios), Length(FPeriodos));
  FHintCelda := Point(-1, -1);

  if Length(FOperarios) = 0 then
  begin
    pbMatrix.Invalidate;
    Exit;
  end;

  if DemoMode.Active then
  begin
    LlenarMatrizDemo;
    OrdenarFilas;
    FormResize(nil);
    pbMatrix.Invalidate;
    pbLegend.Invalidate;
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
                Inc(FNumNodos[OIdx, J]);
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
        FHorasPlan[I, J] := HorasPlan;
        if Cal = nil then
        begin
          FMatrix[I, J] := -1;
          FHorasCap[I, J] := -1;
          Continue;
        end;
        CapacityMin := Cal.WorkingMinutesBetween(FPeriodos[J].Inicio, FPeriodos[J].Fin);
        if CapacityMin <= 0 then
        begin
          FMatrix[I, J] := -1;
          FHorasCap[I, J] := -1;
          Continue;
        end;
        HorasCap := CapacityMin / 60.0;
        FHorasCap[I, J] := HorasCap;
        Pct := (HorasPlan / HorasCap) * 100.0;
        FMatrix[I, J] := Pct;
      end;
    end;
  finally
    OpIdxById.Free;
  end;

  OrdenarFilas;
  FormResize(nil);
  pbMatrix.Invalidate;
  pbLegend.Invalidate;
end;

function TfrmHeatmapCargaOperario.CeldaEnPunto(AX, AY: Integer;
  out AOp, APer: Integer): Boolean;
var
  RelX, RelY: Integer;
begin
  Result := False;
  AOp := -1; APer := -1;
  if (AX < MTX_ROW_LABEL_W) or (AY < MTX_COL_HEADER_H) then Exit;
  RelX := AX - MTX_ROW_LABEL_W;
  RelY := AY - MTX_COL_HEADER_H;
  if RelX >= Length(FPeriodos) * MTX_CELL_W then Exit;  // fuera: sparkline/promedio
  APer := RelX div MTX_CELL_W;
  if (APer < 0) or (APer > High(FPeriodos)) then begin APer := -1; Exit; end;

  // Fila TOTAL: justo debajo de las filas de operarios -> AOp = -2
  if RelY >= Length(FOperarios) * RowH then
  begin
    if RelY < Length(FOperarios) * RowH + TotalH then
    begin
      AOp := -2;
      Result := True;
    end;
    Exit;
  end;

  AOp := RelY div RowH;
  if (AOp < 0) or (AOp > High(FOperarios)) then begin AOp := -1; Exit; end;
  Result := True;
end;

procedure TfrmHeatmapCargaOperario.pbMatrixMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  Op, Per: Integer;
  S, NombreOp: string;
  HP, HC, Pct: Double;
begin
  if not CeldaEnPunto(X, Y, Op, Per) then
  begin
    if (FHintCelda.X <> -1) or (FHintCelda.Y <> -1) then
    begin
      FHintCelda := Point(-1, -1);
      pbMatrix.Hint := '';
      Application.CancelHint;
    end;
    Exit;
  end;

  if (Op = FHintCelda.Y) and (Per = FHintCelda.X) then Exit;  // misma celda
  FHintCelda := Point(Per, Op);

  if Op = -2 then
  begin
    // Fila TOTAL: agregar horas de todos los operarios en este periodo.
    var SP: Double := 0; var SC: Double := 0; var NN: Integer := 0; var K: Integer;
    for K := 0 to High(FOperarios) do
      if FHorasCap[K, Per] >= 0 then
      begin
        SP := SP + FHorasPlan[K, Per];
        SC := SC + FHorasCap[K, Per];
        NN := NN + FNumNodos[K, Per];
      end;
    S := 'RESUMEN TOTALES · ' + FPeriodos[Per].Label_ + sLineBreak;
    if SC <= 0 then
      S := S + 'Sin capacidad'
    else
    begin
      S := S + FormatFloat('0.0', SP) + ' h / ' + FormatFloat('0.0', SC) +
           ' h  (' + FormatFloat('0', SP / SC * 100.0) + '%)' + sLineBreak +
           IntToStr(NN) + ' nodos · ' + IntToStr(Length(FOperarios)) + ' operarios';
      if SP > SC then
        S := S + sLineBreak + 'SOBRECARGA GLOBAL (+' +
             FormatFloat('0.0', SP - SC) + ' h)';
    end;
    pbMatrix.Hint := S;
    Application.CancelHint;
    Exit;
  end;

  NombreOp := FOperarios[Op].Nombre;
  if Trim(NombreOp) = '' then NombreOp := 'Operario #' + IntToStr(FOperarios[Op].Id);

  Pct := FMatrix[Op, Per];
  HC := FHorasCap[Op, Per];
  HP := FHorasPlan[Op, Per];

  S := NombreOp + ' · ' + FPeriodos[Per].Label_ + sLineBreak;
  if (Pct < 0) or (HC < 0) then
    S := S + 'Sin capacidad (sin calendario asignado)'
  else
  begin
    S := S + FormatFloat('0.0', HP) + ' h / ' + FormatFloat('0.0', HC) +
         ' h  (' + FormatFloat('0', Pct) + '%)' + sLineBreak +
         IntToStr(FNumNodos[Op, Per]) + ' nodos';
    if Pct > 100 then
      S := S + sLineBreak + 'SOBRECARGA (+' +
           FormatFloat('0.0', HP - HC) + ' h)';
  end;

  pbMatrix.Hint := S;
  Application.CancelHint;   // fuerza reaparicion inmediata del hint en la nueva celda
end;

procedure TfrmHeatmapCargaOperario.pbMatrixMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NumPer, AvgX: Integer;
  NuevaCol: Integer;
begin
  if Button <> mbLeft then Exit;
  if Y >= MTX_COL_HEADER_H then Exit;   // solo la fila de cabeceras
  if Length(FOperarios) = 0 then Exit;

  NumPer := Length(FPeriodos);
  AvgX := MTX_ROW_LABEL_W + NumPer * MTX_CELL_W + MTX_SPARK_W;

  NuevaCol := -1;
  if X < MTX_ROW_LABEL_W then
    NuevaCol := 0                                   // cabecera de nombres -> por nombre
  else if (X >= AvgX) and (X < AvgX + MTX_AVG_W) then
    NuevaCol := 1;                                  // cabecera Promedio -> por carga

  if NuevaCol < 0 then Exit;

  if NuevaCol = FSortCol then
    FSortDesc := not FSortDesc
  else
  begin
    FSortCol := NuevaCol;
    FSortDesc := (NuevaCol = 1);   // promedio por defecto descendente (mas cargados arriba)
  end;

  OrdenarFilas;
  pbMatrix.Invalidate;
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
  TempW := TempW + MTX_SPARK_W;
  TempW := TempW + MTX_AVG_W;
  TempW := TempW + MTX_PADDING;
  TempH := NumOp * RowH;
  TempH := TempH + MTX_COL_HEADER_H;
  TempH := TempH + TotalH;
  TempH := TempH + MTX_PADDING;
  AWidth := TempW;
  AHeight := TempH;
  if AWidth < sbMatrix.ClientWidth then AWidth := sbMatrix.ClientWidth;
  if AHeight < sbMatrix.ClientHeight then AHeight := sbMatrix.ClientHeight;
end;

function TfrmHeatmapCargaOperario.RowH: Integer;
begin
  if FVerDetalle then Result := MTX_CELL_H_DET else Result := MTX_CELL_H;
end;

function TfrmHeatmapCargaOperario.TotalH: Integer;
begin
  if FVerDetalle then Result := MTX_TOTAL_H_DET else Result := MTX_TOTAL_H;
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
  // Fondo = color del panel padre (no blanco), para que el espacio sobrante
  // de la leyenda se funda con la barra en lugar de destacar como un rectangulo.
  C.Brush.Color := pnlLegend.Color;
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
begin
  DibujarMatriz(pbMatrix.Canvas, pbMatrix.Width, pbMatrix.Height);
end;

procedure TfrmHeatmapCargaOperario.DibujarMatriz(C: TCanvas; AWidth, AHeight: Integer);
var
  I, J, X, Y, NumOp, NumPer: Integer;
  R: TRect;
  Pct: Double;
  BgColor, TxColor: TColor;
  TextDark: Boolean;
  Lbl: string;
begin
  C.Font.Name := 'Segoe UI';

  C.Brush.Color := CLR_PAPER;
  C.FillRect(Rect(0, 0, AWidth, AHeight));

  NumOp := Length(FOperarios);
  NumPer := Length(FPeriodos);

  if (NumOp = 0) or (NumPer = 0) then
  begin
    C.Font.Size := 10;
    C.Font.Color := CLR_TXT_LIGHT;
    C.Brush.Style := bsClear;
    R := Rect(0, 0, AWidth, AHeight);
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
  R := Rect(0, MTX_COL_HEADER_H, MTX_ROW_LABEL_W, MTX_COL_HEADER_H + NumOp * RowH);
  C.FillRect(R);

  for I := 0 to NumOp - 1 do
  begin
    Y := MTX_COL_HEADER_H + I * RowH;
    R := Rect(8, Y, MTX_ROW_LABEL_W - 8, Y + RowH);
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_HEADER_TX;
    C.Brush.Style := bsClear;
    Lbl := FOperarios[I].Nombre;
    if Trim(Lbl) = '' then Lbl := 'Operario #' + IntToStr(FOperarios[I].Id);
    DrawText(C.Handle, PChar(Lbl), -1, R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    C.Brush.Style := bsSolid;
  end;

  // Esquina superior izquierda: cabecera "Operario" (clicable para ordenar)
  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, MTX_ROW_LABEL_W, MTX_COL_HEADER_H));
  C.Font.Style := [fsBold];
  C.Font.Size := 9;
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  Lbl := 'Operario';
  if FSortCol = 0 then
  begin
    if FSortDesc then Lbl := Lbl + '  ' + #$25BC else Lbl := Lbl + '  ' + #$25B2;
  end;
  R := Rect(8, 0, MTX_ROW_LABEL_W - 8, MTX_COL_HEADER_H);
  DrawText(C.Handle, PChar(Lbl), -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  C.Brush.Style := bsSolid;

  // ----- Celdas -----
  for I := 0 to NumOp - 1 do
    for J := 0 to NumPer - 1 do
    begin
      X := MTX_ROW_LABEL_W + J * MTX_CELL_W;
      Y := MTX_COL_HEADER_H + I * RowH;
      R := Rect(X + 2, Y + 2, X + MTX_CELL_W - 2, Y + RowH - 2);

      Pct := FMatrix[I, J];
      BgColor := ColorPorPct(Pct, TextDark);
      if TextDark then TxColor := CLR_TXT_LIGHT else TxColor := CLR_TXT_DARK;

      C.Brush.Color := BgColor;
      C.FillRect(R);
      C.Font.Color := TxColor;
      C.Brush.Style := bsClear;

      if FVerDetalle then
      begin
        // % grande arriba + horas y nodos debajo.
        C.Font.Style := [fsBold];
        C.Font.Size := 11;
        R := Rect(X + 2, Y + 4, X + MTX_CELL_W - 2, Y + 24);
        DrawText(C.Handle, PChar(FormatPct(Pct)), -1, R,
          DT_CENTER or DT_TOP or DT_SINGLELINE);
        C.Font.Style := [];
        C.Font.Size := 8;
        if FHorasCap[I, J] >= 0 then
        begin
          R := Rect(X + 2, Y + 26, X + MTX_CELL_W - 2, Y + 41);
          DrawText(C.Handle,
            PChar(FormatFloat('0', FHorasPlan[I, J]) + '/' +
                  FormatFloat('0', FHorasCap[I, J]) + ' h'), -1, R,
            DT_CENTER or DT_TOP or DT_SINGLELINE);
          R := Rect(X + 2, Y + 40, X + MTX_CELL_W - 2, Y + RowH - 3);
          DrawText(C.Handle, PChar(IntToStr(FNumNodos[I, J]) + ' nodos'), -1, R,
            DT_CENTER or DT_TOP or DT_SINGLELINE);
        end;
      end
      else
      begin
        C.Font.Style := [fsBold];
        C.Font.Size := 10;
        DrawText(C.Handle, PChar(FormatPct(Pct)), -1, R,
          DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      end;
      C.Brush.Style := bsSolid;
    end;

  // ----- Columnas resumen: Sparkline (tendencia) + Promedio -----
  begin
    var SparkX: Integer := MTX_ROW_LABEL_W + NumPer * MTX_CELL_W;
    var AvgX: Integer := SparkX + MTX_SPARK_W;

    // Cabeceras
    C.Font.Style := [fsBold];
    C.Font.Size := 9;
    C.Brush.Color := CLR_HEADER_BG;
    C.FillRect(Rect(SparkX, 0, AvgX + MTX_AVG_W, MTX_COL_HEADER_H));
    C.Font.Color := CLR_HEADER_TX;
    C.Brush.Style := bsClear;
    R := Rect(SparkX, 0, SparkX + MTX_SPARK_W, MTX_COL_HEADER_H);
    DrawText(C.Handle, PChar('Tendencia'), -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    var LblProm: string := 'Promedio';
    if FSortCol = 1 then
    begin
      if FSortDesc then LblProm := LblProm + ' ' + #$25BC else LblProm := LblProm + ' ' + #$25B2;
    end;
    R := Rect(AvgX, 0, AvgX + MTX_AVG_W, MTX_COL_HEADER_H);
    DrawText(C.Handle, PChar(LblProm), -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;

    for I := 0 to NumOp - 1 do
    begin
      Y := MTX_COL_HEADER_H + I * RowH;

      // --- Sparkline de la fila: linea continua multicolor de % ---
      C.Brush.Color := CLR_PAPER;
      C.FillRect(Rect(SparkX, Y, SparkX + MTX_SPARK_W, Y + RowH));
      if NumPer >= 2 then
      begin
        // Escala vertical fija 0..150% para que las filas sean comparables.
        var SPARK_MAX: Double := 150.0;
        var PadX: Integer := 8;
        var PadY: Integer := 6;
        var GraphW: Integer := MTX_SPARK_W - 2 * PadX;
        var GraphH: Integer := RowH - 2 * PadY;
        var BaseY: Integer := Y + RowH - PadY;

        // Linea guia del 100%
        var Y100: Integer := BaseY - Round(GraphH * (100.0 / SPARK_MAX));
        C.Pen.Color := $00CFCFCF;
        C.Pen.Style := psDot;
        C.MoveTo(SparkX + PadX, Y100);
        C.LineTo(SparkX + PadX + GraphW, Y100);
        C.Pen.Style := psSolid;

        var Prev: TPoint;
        var HasPrev: Boolean := False;
        C.Pen.Width := 2;
        for J := 0 to NumPer - 1 do
        begin
          Pct := FMatrix[I, J];
          if Pct < 0 then begin HasPrev := False; Continue; end;
          var VClamp: Double := Pct;
          if VClamp > SPARK_MAX then VClamp := SPARK_MAX;
          var PX: Integer := SparkX + PadX + Round(GraphW * (J / (NumPer - 1)));
          var PY: Integer := BaseY - Round(GraphH * (VClamp / SPARK_MAX));
          if HasPrev then
          begin
            // Color del tramo segun el % de destino (verde ok / azul carga / rojo sobre)
            C.Pen.Color := ColorPorPct(Pct, TextDark);
            C.MoveTo(Prev.X, Prev.Y);
            C.LineTo(PX, PY);
          end;
          Prev := Point(PX, PY);
          HasPrev := True;
        end;
        C.Pen.Width := 1;
      end;

      // --- Promedio de la fila ---
      var Suma: Double := 0;
      var Cnt: Integer := 0;
      for J := 0 to NumPer - 1 do
        if FMatrix[I, J] >= 0 then
        begin
          Suma := Suma + FMatrix[I, J];
          Inc(Cnt);
        end;
      if Cnt > 0 then Pct := Suma / Cnt else Pct := -1;

      R := Rect(AvgX + 2, Y + 2, AvgX + MTX_AVG_W - 2, Y + RowH - 2);
      BgColor := ColorPorPct(Pct, TextDark);
      if TextDark then TxColor := CLR_TXT_LIGHT else TxColor := CLR_TXT_DARK;
      C.Brush.Color := BgColor;
      C.FillRect(R);
      C.Font.Style := [fsBold];
      C.Font.Size := 10;
      C.Font.Color := TxColor;
      C.Brush.Style := bsClear;
      DrawText(C.Handle, PChar(FormatPct(Pct)), -1, R,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      C.Brush.Style := bsSolid;
    end;
  end;

  // ----- Fila TOTAL: saturacion global del taller por periodo -----
  begin
    var TotY: Integer := MTX_COL_HEADER_H + NumOp * RowH;
    var TotHt: Integer := TotalH;
    var SparkXt: Integer := MTX_ROW_LABEL_W + NumPer * MTX_CELL_W;
    var AvgXt: Integer := SparkXt + MTX_SPARK_W;

    // Banda de fondo destacada para toda la fila (mas oscura que la cabecera).
    C.Brush.Color := CLR_TOTAL_BG;
    C.FillRect(Rect(0, TotY, AvgXt + MTX_AVG_W, TotY + TotHt));

    // Etiqueta de la fila
    C.Font.Style := [fsBold];
    C.Font.Size := 11;
    C.Font.Color := CLR_TOTAL_TX;
    C.Brush.Style := bsClear;
    R := Rect(10, TotY, MTX_ROW_LABEL_W - 8, TotY + TotHt);
    DrawText(C.Handle, PChar('RESUMEN TOTALES'), -1, R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;

    var SumaPlanTot: Double := 0;
    var SumaCapTot: Double := 0;
    var NodosTot: Integer := 0;
    for J := 0 to NumPer - 1 do
    begin
      var SumPlan: Double := 0;
      var SumCap: Double := 0;
      var SumNod: Integer := 0;
      for I := 0 to NumOp - 1 do
        if FHorasCap[I, J] >= 0 then
        begin
          SumPlan := SumPlan + FHorasPlan[I, J];
          SumCap := SumCap + FHorasCap[I, J];
          SumNod := SumNod + FNumNodos[I, J];
        end;
      SumaPlanTot := SumaPlanTot + SumPlan;
      SumaCapTot := SumaCapTot + SumCap;
      NodosTot := NodosTot + SumNod;

      if SumCap > 0 then Pct := (SumPlan / SumCap) * 100.0 else Pct := -1;

      X := MTX_ROW_LABEL_W + J * MTX_CELL_W;
      R := Rect(X + 2, TotY + 3, X + MTX_CELL_W - 2, TotY + TotHt - 3);
      BgColor := ColorPorPct(Pct, TextDark);
      if TextDark then TxColor := CLR_TXT_LIGHT else TxColor := CLR_TXT_DARK;
      C.Brush.Color := BgColor;
      C.FillRect(R);
      C.Font.Color := TxColor;
      C.Brush.Style := bsClear;

      if FVerDetalle then
      begin
        C.Font.Style := [fsBold];
        C.Font.Size := 11;
        R := Rect(X + 2, TotY + 5, X + MTX_CELL_W - 2, TotY + 26);
        DrawText(C.Handle, PChar(FormatPct(Pct)), -1, R, DT_CENTER or DT_TOP or DT_SINGLELINE);
        C.Font.Style := [];
        C.Font.Size := 8;
        if SumCap > 0 then
        begin
          R := Rect(X + 2, TotY + 28, X + MTX_CELL_W - 2, TotY + 43);
          DrawText(C.Handle,
            PChar(FormatFloat('0', SumPlan) + '/' + FormatFloat('0', SumCap) + ' h'),
            -1, R, DT_CENTER or DT_TOP or DT_SINGLELINE);
          R := Rect(X + 2, TotY + 42, X + MTX_CELL_W - 2, TotY + TotHt - 3);
          DrawText(C.Handle, PChar(IntToStr(SumNod) + ' nodos'), -1, R,
            DT_CENTER or DT_TOP or DT_SINGLELINE);
        end;
      end
      else
      begin
        C.Font.Style := [fsBold];
        C.Font.Size := 10;
        DrawText(C.Handle, PChar(FormatPct(Pct)), -1, R,
          DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      end;
      C.Brush.Style := bsSolid;
    end;

    // Total global -> alineado EXACTAMENTE con la columna Promedio (no el sparkline).
    var GTotPct: Double;
    if SumaCapTot > 0 then GTotPct := (SumaPlanTot / SumaCapTot) * 100.0 else GTotPct := -1;
    R := Rect(AvgXt + 2, TotY + 3, AvgXt + MTX_AVG_W - 2, TotY + TotHt - 3);
    BgColor := ColorPorPct(GTotPct, TextDark);
    if TextDark then TxColor := CLR_TXT_LIGHT else TxColor := CLR_TXT_DARK;
    C.Brush.Color := BgColor;
    C.FillRect(R);
    C.Font.Color := TxColor;
    C.Brush.Style := bsClear;

    if FVerDetalle then
    begin
      C.Font.Style := [fsBold];
      C.Font.Size := 11;
      R := Rect(AvgXt + 2, TotY + 5, AvgXt + MTX_AVG_W - 2, TotY + 26);
      DrawText(C.Handle, PChar(FormatPct(GTotPct)), -1, R, DT_CENTER or DT_TOP or DT_SINGLELINE);
      C.Font.Style := [];
      C.Font.Size := 8;
      if SumaCapTot > 0 then
      begin
        R := Rect(AvgXt + 2, TotY + 28, AvgXt + MTX_AVG_W - 2, TotY + 43);
        DrawText(C.Handle,
          PChar(FormatFloat('0', SumaPlanTot) + '/' + FormatFloat('0', SumaCapTot) + ' h'),
          -1, R, DT_CENTER or DT_TOP or DT_SINGLELINE);
        R := Rect(AvgXt + 2, TotY + 42, AvgXt + MTX_AVG_W - 2, TotY + TotHt - 3);
        DrawText(C.Handle, PChar(IntToStr(NodosTot) + ' nodos'), -1, R,
          DT_CENTER or DT_TOP or DT_SINGLELINE);
      end;
    end
    else
    begin
      C.Font.Style := [fsBold];
      C.Font.Size := 11;
      DrawText(C.Handle, PChar(FormatPct(GTotPct)), -1, R,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    end;
    C.Brush.Style := bsSolid;
  end;

  // ----- Lineas de grid -----
  var GridBottom: Integer := MTX_COL_HEADER_H + NumOp * RowH;
  var GridBottomTot: Integer := GridBottom + TotalH;
  var GridRight: Integer := MTX_ROW_LABEL_W + NumPer * MTX_CELL_W + MTX_SPARK_W + MTX_AVG_W;
  C.Pen.Color := CLR_GRID_LINE;
  C.Pen.Style := psSolid;
  for J := 0 to NumPer do
  begin
    X := MTX_ROW_LABEL_W + J * MTX_CELL_W;
    C.MoveTo(X, 0);
    C.LineTo(X, GridBottomTot);
  end;
  // Separadores de las columnas resumen (sparkline | promedio) y borde derecho
  X := MTX_ROW_LABEL_W + NumPer * MTX_CELL_W + MTX_SPARK_W;
  C.MoveTo(X, 0);
  C.LineTo(X, GridBottomTot);
  X := X + MTX_AVG_W;
  C.MoveTo(X, 0);
  C.LineTo(X, GridBottomTot);
  for I := 0 to NumOp do
  begin
    Y := MTX_COL_HEADER_H + I * RowH;
    C.MoveTo(0, Y);
    C.LineTo(GridRight, Y);
  end;
  // Separador reforzado encima de la fila TOTAL
  C.Pen.Color := CLR_HEADER_TX;
  C.MoveTo(0, GridBottom);
  C.LineTo(GridRight, GridBottom);
  C.MoveTo(0, GridBottomTot);
  C.LineTo(GridRight, GridBottomTot);
end;

procedure TfrmHeatmapCargaOperario.EstiloBotonHeader(var ABtn: TcxButton);
begin
  ABtn := TcxButton.Create(Self);
  ABtn.LookAndFeel.Kind := lfUltraFlat;
  ABtn.LookAndFeel.NativeStyle := False;
  ABtn.LookAndFeel.SkinName := 'Office2010Silver';
  ABtn.SpeedButtonOptions.CanBeFocused := False;
  ABtn.Font.Name := 'Segoe UI';
  ABtn.Font.Height := -11;
  ABtn.Font.Style := [fsBold];
  ABtn.Font.Color := clBlack;
end;

procedure TfrmHeatmapCargaOperario.DetalleClick(Sender: TObject);
begin
  FVerDetalle := FBtnDetalle.Down;
  if FVerDetalle then FBtnDetalle.Caption := 'Ocultar detalle'
                 else FBtnDetalle.Caption := 'Ver detalle';
  FHintCelda := Point(-1, -1);
  // Al cambiar el alto de las filas cambia el alto del paintbox. Si el scroll
  // estaba desplazado, hay que resetearlo ANTES de redimensionar; si no, el
  // scrollbox deja un hueco en blanco arriba (no reajusta la posicion).
  sbMatrix.VertScrollBar.Position := 0;
  sbMatrix.HorzScrollBar.Position := 0;
  FormResize(nil);      // recalcula alto (RowH cambia) y redimensiona el paintbox
  pbMatrix.Invalidate;
end;

procedure TfrmHeatmapCargaOperario.ExportarPNGClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  Bmp: TBitmap;
  Png: TPngImage;
begin
  if Length(FOperarios) = 0 then
  begin
    ShowMessage('No hay datos para exportar.');
    Exit;
  end;
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'Imagen PNG (*.png)|*.png';
    Dlg.DefaultExt := 'png';
    Dlg.FileName := 'HeatmapOperarios_' +
      FormatDateTime('yyyymmdd', dtDesde.Date) + '.png';
    if not Dlg.Execute then Exit;

    Bmp := TBitmap.Create;
    try
      Bmp.PixelFormat := pf24bit;
      Bmp.SetSize(pbMatrix.Width, pbMatrix.Height);
      // Redibuja la matriz completa (a su tamanyo real, no solo lo visible)
      // directamente sobre el bitmap.
      DibujarMatriz(Bmp.Canvas, Bmp.Width, Bmp.Height);
      Png := TPngImage.Create;
      try
        Png.Assign(Bmp);
        Png.SaveToFile(Dlg.FileName);
      finally
        Png.Free;
      end;
    finally
      Bmp.Free;
    end;
    ShowMessage('Heatmap exportado a:' + sLineBreak + Dlg.FileName);
  finally
    Dlg.Free;
  end;
end;

procedure TfrmHeatmapCargaOperario.ExportarCSVClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  SB: TStringBuilder;
  I, J: Integer;
  Sep: Char;
  function Num(V: Double): string;
  begin
    if V < 0 then Exit('');
    Result := FormatFloat('0.0', V);
    // separador decimal local ya lo aplica FormatFloat; para CSV usamos ';'
  end;
begin
  if Length(FOperarios) = 0 then
  begin
    ShowMessage('No hay datos para exportar.');
    Exit;
  end;
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'CSV (*.csv)|*.csv';
    Dlg.DefaultExt := 'csv';
    Dlg.FileName := 'HeatmapOperarios_' +
      FormatDateTime('yyyymmdd', dtDesde.Date) + '.csv';
    if not Dlg.Execute then Exit;

    Sep := ';';   // Excel-ES usa ';' cuando la coma es separador decimal
    SB := TStringBuilder.Create;
    try
      // Cabecera
      SB.Append('Operario');
      for J := 0 to High(FPeriodos) do
        SB.Append(Sep).Append(FPeriodos[J].Label_);
      SB.Append(Sep).Append('Promedio');
      SB.AppendLine;

      // Filas de operarios (valores = % de ocupacion)
      for I := 0 to High(FOperarios) do
      begin
        var Nom: string := FOperarios[I].Nombre;
        if Trim(Nom) = '' then Nom := 'Operario #' + IntToStr(FOperarios[I].Id);
        SB.Append(Nom);
        var S: Double := 0; var C: Integer := 0;
        for J := 0 to High(FPeriodos) do
        begin
          SB.Append(Sep).Append(Num(FMatrix[I, J]));
          if FMatrix[I, J] >= 0 then begin S := S + FMatrix[I, J]; Inc(C); end;
        end;
        if C > 0 then SB.Append(Sep).Append(Num(S / C))
                 else SB.Append(Sep);
        SB.AppendLine;
      end;

      // Fila TOTAL (saturacion global por periodo)
      SB.Append('RESUMEN TOTALES');
      var GPlan: Double := 0; var GCap: Double := 0;
      for J := 0 to High(FPeriodos) do
      begin
        var SP: Double := 0; var SC: Double := 0;
        for I := 0 to High(FOperarios) do
          if FHorasCap[I, J] >= 0 then
          begin
            SP := SP + FHorasPlan[I, J];
            SC := SC + FHorasCap[I, J];
          end;
        GPlan := GPlan + SP; GCap := GCap + SC;
        if SC > 0 then SB.Append(Sep).Append(Num(SP / SC * 100.0))
                  else SB.Append(Sep);
      end;
      if GCap > 0 then SB.Append(Sep).Append(Num(GPlan / GCap * 100.0))
                  else SB.Append(Sep);
      SB.AppendLine;

      TFile.WriteAllText(Dlg.FileName, SB.ToString, TEncoding.UTF8);
    finally
      SB.Free;
    end;
    ShowMessage('Datos exportados a:' + sLineBreak + Dlg.FileName);
  finally
    Dlg.Free;
  end;
end;

end.
