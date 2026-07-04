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

  Extras PRO (equivalentes al heatmap por operario):
    - Modo Demo (uDemoMode): genera centros y matriz ficticios.
    - Columna Promedio + columna Tendencia (sparkline).
    - Tooltip rico por celda (horas plan/cap + nodos + sobrecarga).
    - Fila RESUMEN TOTALES con saturaci'on global por periodo.
    - Ordenaci'on por click en cabecera (nombre / promedio).
    - Toggle "Ver detalle" (celdas con % + horas + nodos).
    - Exportar a PNG y CSV.
    - Filtro por 'Area (en lugar de departamento del heatmap por operario).
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections, System.DateUtils, System.Math,
  System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Samples.Spin, Vcl.Imaging.pngimage,
  Data.Win.ADODB, Data.DB,
  cxCheckComboBox, cxCheckBox, cxEdit, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxButtons,
  uGanttTypes, uCentresRepo, uCentreCalendar, uDemoMode, dxSkinsCore, dxSkinBasic,
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
  TGranularidad = (gDias, gSemanas, gMeses);

  TPeriodo = record
    Inicio: TDateTime;
    Fin:    TDateTime;
    Label_: string;
  end;

  // Tipos con nombre para las matrices [centroIdx, periodoIdx]. Necesarios para
  // poder asignar entre campos y variables locales (dos `array of array`
  // anonimos son tipos incompatibles en Delphi -> E2008).
  TMatrizDbl = array of array of Double;
  TMatrizInt = array of array of Integer;

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
    btnRecalcular: TcxButton;
    lblCentros: TLabel;
    cbCentros: TcxCheckComboBox;
    pnlLegend: TPanel;
    pbLegend: TPaintBox;
    pcVistas: TPageControl;
    tabMatriz: TTabSheet;
    sbMatrix: TScrollBox;
    pbMatrix: TPaintBox;
    tabPareto: TTabSheet;
    sbPareto: TScrollBox;
    pbPareto: TPaintBox;
    tabAnalisis: TTabSheet;
    sbAnalisis: TScrollBox;
    pbAnalisis: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnRecalcularClick(Sender: TObject);
    procedure ParametrosChange(Sender: TObject);
    procedure pbLegendPaint(Sender: TObject);
    procedure pbMatrixPaint(Sender: TObject);
    procedure cbCentrosChange(Sender: TObject);
    procedure pcVistasChange(Sender: TObject);
    procedure pbParetoPaint(Sender: TObject);
    procedure pbAnalisisPaint(Sender: TObject);
  private
    FAllCentres: TArray<TCentreTreball>;
    FCentres: TArray<TCentreTreball>;
    FPeriodos: TArray<TPeriodo>;
    // [centroIdx, periodoIdx] -> %  (-1 si sin capacidad)
    FMatrix: TMatrizDbl;
    // Datos de detalle por celda (para el tooltip)
    FHorasPlan: TMatrizDbl;   // horas planificadas
    FHorasCap:  TMatrizDbl;   // horas de capacidad (-1 sin cap.)
    FNumNodos:  TMatrizInt;   // nº de nodos que aportan carga
    FHintCelda: TPoint;                        // celda [cen,per] bajo el raton (-1,-1 = ninguna)
    FSortCol: Integer;                         // 0=nombre, 1=promedio
    FSortDesc: Boolean;
    FVerDetalle: Boolean;                      // muestra horas/nodos dentro de la celda
    FBtnExportPNG: TcxButton;
    FBtnExportCSV: TcxButton;
    FBtnDetalle: TcxButton;
    FCmbArea: TComboBox;                        // filtro por area
    FLblArea: TLabel;
    FAreaSel: string;                           // area activa ('' = todas)
    FUpdatingCentros: Boolean;
    FLoadingPrefs: Boolean;
    procedure BuildPeriodos;
    procedure CargarCentrosCombo;
    procedure CargarCentrosDemo;
    procedure LlenarMatrizDemo;
    procedure DemoChanged(Sender: TObject);
    procedure AplicarFiltroCentros;
    procedure LoadPrefs;
    procedure SavePrefs;
    procedure RecalcularDatos;
    procedure pbMatrixMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbMatrixMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure OrdenarFilas;
    procedure DibujarMatriz(C: TCanvas; AWidth, AHeight: Integer);
    procedure DibujarPareto(C: TCanvas; AWidth, AHeight: Integer);
    procedure DibujarAnalisis(C: TCanvas; AWidth, AHeight: Integer);
    procedure ExportarPNGClick(Sender: TObject);
    procedure ExportarCSVClick(Sender: TObject);
    procedure DetalleClick(Sender: TObject);
    procedure EstiloBotonHeader(var ABtn: TcxButton);
    procedure CargarAreasCombo;
    procedure AreaChange(Sender: TObject);
    function RowH: Integer;                     // alto de fila (segun Ver detalle)
    function TotalH: Integer;                   // alto de la fila resumen (segun Ver detalle)
    function CeldaEnPunto(AX, AY: Integer; out ACen, APer: Integer): Boolean;
    function ColorPorPct(P: Double; out TextDark: Boolean): TColor;
    function FormatPct(P: Double): string;
    procedure ComputeMatrixSize(out AWidth, AHeight: Integer);
  public
    class procedure Execute;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uHelpViewer, System.JSON,
  Winapi.GDIPOBJ, Winapi.GDIPAPI;

const
  // Dimensiones
  MTX_CELL_W       = 90;
  MTX_CELL_H       = 38;   // alto de fila normal
  MTX_CELL_H_DET   = 60;   // alto de fila con "Ver detalle" activo
  MTX_ROW_LABEL_W  = 180;
  MTX_COL_HEADER_H = 46;
  MTX_PADDING      = 12;
  MTX_SPARK_W      = 130;  // columna sparkline (tendencia por centro)
  MTX_AVG_W        = 96;   // columna "Promedio" a la derecha de la matriz
  MTX_TOTAL_H      = 42;   // fila resumen (saturacion global por periodo)
  MTX_TOTAL_H_DET  = 60;   // fila resumen con "Ver detalle" activo

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
  CLR_TOTAL_BG:  TColor = $003C3630;   // banda oscura para destacar la fila TOTAL
  CLR_TOTAL_TX:  TColor = $00FFFFFF;

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
  pbMatrix.OnMouseMove := pbMatrixMouseMove;
  pbMatrix.OnMouseDown := pbMatrixMouseDown;
  pbMatrix.ShowHint := True;
  FHintCelda := Point(-1, -1);
  FSortCol := 0;      // por nombre
  FSortDesc := False;
  FAreaSel := '';

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

  // Filtro por area (label + combo). Los centros no tienen departamento, pero
  // el record TCentreTreball tiene un campo Area que agrupa los centros.
  FLblArea := TLabel.Create(Self);
  FLblArea.Parent := pnlToolbar;
  FLblArea.SetBounds(cbCentros.Left + cbCentros.Width + 16, lblCentros.Top, 40, 15);
  FLblArea.Caption := #193'rea:';

  FCmbArea := TComboBox.Create(Self);
  FCmbArea.Parent := pnlToolbar;
  FCmbArea.SetBounds(FLblArea.Left, cbCentros.Top, 200, 23);
  FCmbArea.Style := csDropDownList;
  FCmbArea.OnChange := AreaChange;

  FLoadingPrefs := True;
  try
    cmbGranularidad.ItemIndex := 1; // Semanas por defecto
    dtDesde.Date := Trunc(Now);
    spNumPeriodos.Value := 6;
    CargarCentrosCombo;
    CargarAreasCombo;
    LoadPrefs; // sobreescribe los defaults con la ultima config del usuario
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
  DemoMode.AddListener(DemoChanged);
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

procedure TfrmHeatmapCargaCentro.CargarCentrosDemo;
const
  NOMBRES: array[0..12] of string = (
    'Torno CNC 1', 'Torno CNC 2', 'Fresadora 2', 'Centro Mecanizado',
    'Rectificadora', 'Soldadura', 'Corte L'#225'ser', 'Plegadora',
    'Pintura', 'Montaje', 'Ensamblaje Final', 'Control Calidad',
    'Embalaje');
  // Area ficticia por centro (3 areas): 0=Mecanizado, 1=Conformado, 2=Acabado
  AREAS: array[0..2] of string = ('Mecanizado', 'Conformado', 'Acabado');
  AREAIDX: array[0..12] of Integer = (0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2);
var
  I, K: Integer;
  Ar: string;
begin
  SetLength(FAllCentres, Length(NOMBRES));
  K := 0;
  for I := 0 to High(NOMBRES) do
  begin
    Ar := AREAS[AREAIDX[I]];
    // En modo demo el filtro de area es en memoria: si hay area seleccionada y
    // no coincide, saltamos el centro.
    if (FAreaSel <> '') and (not SameText(Ar, FAreaSel)) then Continue;
    FAllCentres[K].Id := 9000 + I;      // ids ficticios, no chocan con reales
    FAllCentres[K].CodiCentre := 'C' + IntToStr(I + 1);
    FAllCentres[K].Titulo := NOMBRES[I];
    FAllCentres[K].Area := Ar;
    Inc(K);
  end;
  SetLength(FAllCentres, K);
end;

procedure TfrmHeatmapCargaCentro.CargarAreasCombo;
var
  Fuente: TArray<TCentreTreball>;
  Vistas: TDictionary<string, Boolean>;
  I, Idx: Integer;
  Ar: string;
begin
  // El combo de areas se llena con los valores DISTINTOS de Area de TODOS los
  // centros (no de los ya filtrados), para que se pueda volver a "todas".
  if DemoMode.Active then
  begin
    // Reconstruir el catalogo completo (sin filtro) para listar todas las areas.
    var SavedArea: string := FAreaSel;
    FAreaSel := '';
    CargarCentrosDemo;
    Fuente := FAllCentres;
    FAreaSel := SavedArea;
  end
  else if DMPlanner.CentresRepo <> nil then
    Fuente := DMPlanner.CentresRepo.GetAll
  else
    SetLength(Fuente, 0);

  FCmbArea.Items.BeginUpdate;
  Vistas := TDictionary<string, Boolean>.Create;
  try
    FCmbArea.Items.Clear;
    FCmbArea.Items.Add('(Todas las '#225'reas)');
    for I := 0 to High(Fuente) do
    begin
      Ar := Trim(Fuente[I].Area);
      if Ar = '' then Continue;
      if not Vistas.ContainsKey(AnsiUpperCase(Ar)) then
      begin
        Vistas.AddOrSetValue(AnsiUpperCase(Ar), True);
        FCmbArea.Items.Add(Ar);
      end;
    end;

    // Mantener la seleccion si el area activa sigue existiendo; si no, Todas.
    Idx := 0;
    if FAreaSel <> '' then
      for I := 1 to FCmbArea.Items.Count - 1 do
        if SameText(FCmbArea.Items[I], FAreaSel) then begin Idx := I; Break; end;
    FCmbArea.ItemIndex := Idx;
    if Idx = 0 then FAreaSel := '' else FAreaSel := FCmbArea.Items[Idx];
  finally
    Vistas.Free;
    FCmbArea.Items.EndUpdate;
  end;
end;

procedure TfrmHeatmapCargaCentro.AreaChange(Sender: TObject);
begin
  if FCmbArea.ItemIndex <= 0 then
    FAreaSel := ''
  else
    FAreaSel := FCmbArea.Items[FCmbArea.ItemIndex];

  // Recargar centros del area y refrescar.
  FLoadingPrefs := True;
  try
    CargarCentrosCombo;
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
end;

procedure TfrmHeatmapCargaCentro.LlenarMatrizDemo;
var
  I, J, Seed: Integer;
  Serie: TArray<Double>;
  Objetivo: Double;
begin
  // Genera una matriz de %  creible y determinista (sin Random) para el modo
  // demo. Cada centro tiene una carga "objetivo" distinta; a lo largo de los
  // periodos oscila con DemoSerieHaciaValor. Alguna celda supera el 100%
  // (sobrecarga) para que el heatmap muestre toda la paleta.
  for I := 0 to High(FCentres) do
  begin
    // Objetivo por centro: reparto entre ~55% y ~119% segun su posicion.
    Objetivo := 55 + ((FCentres[I].Id * 37) mod 65);   // 55..119
    Seed := FCentres[I].Id;
    Serie := DemoSerieHaciaValor(Objetivo, Length(FPeriodos), 0.28, Seed);
    for J := 0 to High(FPeriodos) do
    begin
      FMatrix[I, J] := Serie[J];
      // Detalle ficticio coherente con el % (capacidad ~40h/semana como base).
      FHorasCap[I, J] := 40;
      FHorasPlan[I, J] := 40 * Serie[J] / 100.0;
      FNumNodos[I, J] := 2 + ((FCentres[I].Id + J) mod 5);   // 2..6 nodos
    end;
  end;
end;

procedure TfrmHeatmapCargaCentro.CargarCentrosCombo;
var
  I, K: Integer;
  Lbl: string;
  Todos: TArray<TCentreTreball>;
begin
  FUpdatingCentros := True;
  try
    if DemoMode.Active then
    begin
      // CargarCentrosDemo ya aplica el filtro de area internamente.
      CargarCentrosDemo;
    end
    else
    begin
      if DMPlanner.CentresRepo <> nil then
        Todos := DMPlanner.CentresRepo.GetAll
      else
        SetLength(Todos, 0);
      // Filtro por area en memoria (no hay SQL): dejamos solo los del area
      // seleccionada; si FAreaSel = '' pasan todos.
      SetLength(FAllCentres, Length(Todos));
      K := 0;
      for I := 0 to High(Todos) do
      begin
        if (FAreaSel <> '') and (not SameText(Trim(Todos[I].Area), FAreaSel)) then
          Continue;
        FAllCentres[K] := Todos[I];
        Inc(K);
      end;
      SetLength(FAllCentres, K);
    end;

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

procedure TfrmHeatmapCargaCentro.OrdenarFilas;
// Reordena FCentres y todas las matrices de detalle de forma coherente,
// segun la columna de ordenacion activa (0=nombre, 1=promedio de carga).
// Se llama al final de RecalcularDatos, cuando FMatrix ya esta poblada.
var
  N, I, J, A, B, Key, C: Integer;
  S: Double;
  Mayor: Boolean;
  Ord: TArray<Integer>;
  Prom: TArray<Double>;
  NewCen: TArray<TCentreTreball>;
  NM, NHP, NHC: TMatrizDbl;
  NNN: TMatrizInt;
  function NombreDe(AIdx: Integer): string;
  begin
    Result := FCentres[AIdx].Titulo;
    if Trim(Result) = '' then Result := FCentres[AIdx].CodiCentre;
  end;
begin
  N := Length(FCentres);
  if N < 2 then Exit;

  // Promedio de carga por centro (ignora celdas sin capacidad).
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
        if FSortDesc then Mayor := CompareText(NombreDe(A), NombreDe(B)) < 0
                     else Mayor := CompareText(NombreDe(A), NombreDe(B)) > 0;
      end;
      if not Mayor then Break;
      Ord[J + 1] := Ord[J];
      Dec(J);
    end;
    Ord[J + 1] := Key;
  end;

  // Aplica la permutacion a todos los arrays paralelos.
  SetLength(NewCen, N);
  SetLength(NM, N, Length(FPeriodos));
  SetLength(NHP, N, Length(FPeriodos));
  SetLength(NHC, N, Length(FPeriodos));
  SetLength(NNN, N, Length(FPeriodos));
  for I := 0 to N - 1 do
  begin
    NewCen[I] := FCentres[Ord[I]];
    for J := 0 to High(FPeriodos) do
    begin
      NM[I, J]  := FMatrix[Ord[I], J];
      NHP[I, J] := FHorasPlan[Ord[I], J];
      NHC[I, J] := FHorasCap[Ord[I], J];
      NNN[I, J] := FNumNodos[Ord[I], J];
    end;
  end;
  FCentres := NewCen;
  FMatrix := NM; FHorasPlan := NHP; FHorasCap := NHC; FNumNodos := NNN;
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
  DemoMode.RemoveListener(DemoChanged);
end;

procedure TfrmHeatmapCargaCentro.DemoChanged(Sender: TObject);
begin
  // Al conmutar el modo demo, recargamos areas y centros (en modo demo se
  // generan ficticios; en modo real vuelven los de la BD) y recalculamos.
  FAreaSel := '';
  FLoadingPrefs := True;
  try
    CargarCentrosCombo;
    CargarAreasCombo;
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
end;

procedure TfrmHeatmapCargaCentro.FormResize(Sender: TObject);
var
  W, H: Integer;
begin
  ComputeMatrixSize(W, H);
  pbMatrix.SetBounds(0, 0, W, H);
  // Pareto y Analisis: llenan el area visible (se redibujan a su tamano).
  pbPareto.SetBounds(0, 0,
    Max(sbPareto.ClientWidth, 700), Max(sbPareto.ClientHeight, 400));
  pbAnalisis.SetBounds(0, 0,
    Max(sbAnalisis.ClientWidth, 700), Max(sbAnalisis.ClientHeight, 400));
end;

procedure TfrmHeatmapCargaCentro.pcVistasChange(Sender: TObject);
begin
  // La leyenda de colores solo tiene sentido en la matriz.
  pnlLegend.Visible := (pcVistas.ActivePage = tabMatriz);
  if pcVistas.ActivePage = tabPareto then pbPareto.Invalidate
  else if pcVistas.ActivePage = tabAnalisis then pbAnalisis.Invalidate;
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
  SetLength(FHorasPlan, Length(FCentres), Length(FPeriodos));
  SetLength(FHorasCap, Length(FCentres), Length(FPeriodos));
  SetLength(FNumNodos, Length(FCentres), Length(FPeriodos));
  FHintCelda := Point(-1, -1);

  if (Length(FCentres) = 0) then
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
    pbPareto.Invalidate;
    pbAnalisis.Invalidate;
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
              // Este nodo aporta carga a la celda (para el tooltip / detalle).
              Inc(FNumNodos[CIdx, J]);
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
        FHorasPlan[I, J] := HorasPlan;
        if Cal = nil then
        begin
          FMatrix[I, J] := -1; // sense capacitat
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
    CenterIdxById.Free;
  end;

  OrdenarFilas;
  FormResize(nil);
  pbMatrix.Invalidate;
  pbLegend.Invalidate;
  pbPareto.Invalidate;
  pbAnalisis.Invalidate;
end;

function TfrmHeatmapCargaCentro.CeldaEnPunto(AX, AY: Integer;
  out ACen, APer: Integer): Boolean;
var
  RelX, RelY: Integer;
begin
  Result := False;
  ACen := -1; APer := -1;
  if (AX < MTX_ROW_LABEL_W) or (AY < MTX_COL_HEADER_H) then Exit;
  RelX := AX - MTX_ROW_LABEL_W;
  RelY := AY - MTX_COL_HEADER_H;
  if RelX >= Length(FPeriodos) * MTX_CELL_W then Exit;  // fuera: sparkline/promedio
  APer := RelX div MTX_CELL_W;
  if (APer < 0) or (APer > High(FPeriodos)) then begin APer := -1; Exit; end;

  // Fila TOTAL: justo debajo de las filas de centros -> ACen = -2
  if RelY >= Length(FCentres) * RowH then
  begin
    if RelY < Length(FCentres) * RowH + TotalH then
    begin
      ACen := -2;
      Result := True;
    end;
    Exit;
  end;

  ACen := RelY div RowH;
  if (ACen < 0) or (ACen > High(FCentres)) then begin ACen := -1; Exit; end;
  Result := True;
end;

procedure TfrmHeatmapCargaCentro.pbMatrixMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  Cen, Per: Integer;
  S, NombreCen: string;
  HP, HC, Pct: Double;
begin
  if not CeldaEnPunto(X, Y, Cen, Per) then
  begin
    if (FHintCelda.X <> -1) or (FHintCelda.Y <> -1) then
    begin
      FHintCelda := Point(-1, -1);
      pbMatrix.Hint := '';
      Application.CancelHint;
    end;
    Exit;
  end;

  if (Cen = FHintCelda.Y) and (Per = FHintCelda.X) then Exit;  // misma celda
  FHintCelda := Point(Per, Cen);

  if Cen = -2 then
  begin
    // Fila TOTAL: agregar horas de todos los centros en este periodo.
    var SP: Double := 0; var SC: Double := 0; var NN: Integer := 0; var K: Integer;
    for K := 0 to High(FCentres) do
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
           IntToStr(NN) + ' nodos · ' + IntToStr(Length(FCentres)) + ' centros';
      if SP > SC then
        S := S + sLineBreak + 'SOBRECARGA GLOBAL (+' +
             FormatFloat('0.0', SP - SC) + ' h)';
    end;
    pbMatrix.Hint := S;
    Application.CancelHint;
    Exit;
  end;

  NombreCen := FCentres[Cen].Titulo;
  if Trim(NombreCen) = '' then NombreCen := FCentres[Cen].CodiCentre;

  Pct := FMatrix[Cen, Per];
  HC := FHorasCap[Cen, Per];
  HP := FHorasPlan[Cen, Per];

  S := NombreCen + ' · ' + FPeriodos[Per].Label_ + sLineBreak;
  if (Pct < 0) or (HC < 0) then
    S := S + 'Sin capacidad (sin calendario asignado)'
  else
  begin
    S := S + FormatFloat('0.0', HP) + ' h / ' + FormatFloat('0.0', HC) +
         ' h  (' + FormatFloat('0', Pct) + '%)' + sLineBreak +
         IntToStr(FNumNodos[Cen, Per]) + ' nodos';
    if Pct > 100 then
      S := S + sLineBreak + 'SOBRECARGA (+' +
           FormatFloat('0.0', HP - HC) + ' h)';
  end;

  pbMatrix.Hint := S;
  Application.CancelHint;   // fuerza reaparicion inmediata del hint en la nueva celda
end;

procedure TfrmHeatmapCargaCentro.pbMatrixMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NumPer, AvgX: Integer;
  NuevaCol: Integer;
begin
  if Button <> mbLeft then Exit;
  if Y >= MTX_COL_HEADER_H then Exit;   // solo la fila de cabeceras
  if Length(FCentres) = 0 then Exit;

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
  TempW := TempW + MTX_SPARK_W;
  TempW := TempW + MTX_AVG_W;
  TempW := TempW + MTX_PADDING;
  TempH := NumCen * RowH;
  TempH := TempH + MTX_COL_HEADER_H;
  TempH := TempH + TotalH;
  TempH := TempH + MTX_PADDING;
  AWidth := TempW;
  AHeight := TempH;
  if AWidth < sbMatrix.ClientWidth then AWidth := sbMatrix.ClientWidth;
  if AHeight < sbMatrix.ClientHeight then AHeight := sbMatrix.ClientHeight;
end;

function TfrmHeatmapCargaCentro.RowH: Integer;
begin
  if FVerDetalle then Result := MTX_CELL_H_DET else Result := MTX_CELL_H;
end;

function TfrmHeatmapCargaCentro.TotalH: Integer;
begin
  if FVerDetalle then Result := MTX_TOTAL_H_DET else Result := MTX_TOTAL_H;
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

procedure TfrmHeatmapCargaCentro.pbMatrixPaint(Sender: TObject);
begin
  DibujarMatriz(pbMatrix.Canvas, pbMatrix.Width, pbMatrix.Height);
end;

procedure TfrmHeatmapCargaCentro.DibujarMatriz(C: TCanvas; AWidth, AHeight: Integer);
var
  I, J, X, Y, NumCen, NumPer: Integer;
  R: TRect;
  Pct: Double;
  BgColor, TxColor: TColor;
  TextDark: Boolean;
  Lbl: string;
begin
  C.Font.Name := 'Segoe UI';

  C.Brush.Color := CLR_PAPER;
  C.FillRect(Rect(0, 0, AWidth, AHeight));

  NumCen := Length(FCentres);
  NumPer := Length(FPeriodos);

  if (NumCen = 0) or (NumPer = 0) then
  begin
    C.Font.Size := 10;
    C.Font.Color := CLR_TXT_LIGHT;
    C.Brush.Style := bsClear;
    R := Rect(0, 0, AWidth, AHeight);
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
  R := Rect(0, MTX_COL_HEADER_H, MTX_ROW_LABEL_W, MTX_COL_HEADER_H + NumCen * RowH);
  C.FillRect(R);

  for I := 0 to NumCen - 1 do
  begin
    Y := MTX_COL_HEADER_H + I * RowH;
    R := Rect(8, Y, MTX_ROW_LABEL_W - 8, Y + RowH);
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_HEADER_TX;
    C.Brush.Style := bsClear;
    Lbl := FCentres[I].Titulo;
    if Trim(Lbl) = '' then Lbl := FCentres[I].CodiCentre;
    DrawText(C.Handle, PChar(Lbl), -1, R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    C.Brush.Style := bsSolid;
  end;

  // Esquina superior izquierda: cabecera "Centro" (clicable para ordenar)
  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, MTX_ROW_LABEL_W, MTX_COL_HEADER_H));
  C.Font.Style := [fsBold];
  C.Font.Size := 9;
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  Lbl := 'Centro';
  if FSortCol = 0 then
  begin
    if FSortDesc then Lbl := Lbl + '  ' + #$25BC else Lbl := Lbl + '  ' + #$25B2;
  end;
  R := Rect(8, 0, MTX_ROW_LABEL_W - 8, MTX_COL_HEADER_H);
  DrawText(C.Handle, PChar(Lbl), -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  C.Brush.Style := bsSolid;

  // ----- Celdas -----
  for I := 0 to NumCen - 1 do
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

    for I := 0 to NumCen - 1 do
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
    var TotY: Integer := MTX_COL_HEADER_H + NumCen * RowH;
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
      for I := 0 to NumCen - 1 do
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
  var GridBottom: Integer := MTX_COL_HEADER_H + NumCen * RowH;
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
  for I := 0 to NumCen do
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

procedure TfrmHeatmapCargaCentro.pbParetoPaint(Sender: TObject);
begin
  DibujarPareto(pbPareto.Canvas, pbPareto.Width, pbPareto.Height);
end;

procedure TfrmHeatmapCargaCentro.DibujarPareto(C: TCanvas; AWidth, AHeight: Integer);
// Pareto del exceso de carga: por centro, suma de horas por encima de la
// capacidad (Sum max(0, plan-cap) en todos los periodos). Barras desc + linea
// de % acumulado + guia del 80%. Responde "que pocos centros concentran la
// sobrecarga -> donde actuar primero".
type
  TExc = record Nombre: string; Exceso: Double; end;
var
  R: TRect;
  I, J, N, ChartX0, ChartX1, ChartTop, ChartBottom, AreaW, AreaH: Integer;
  Datos: TArray<TExc>;
  Total, Acum, ExcMax: Double;
  BarW, Gap, X, BarTop, Sem80: Integer;
  PtsAcum: TArray<TPoint>;
  function PyPct(APct: Double): Integer;
  begin
    Result := ChartBottom - Round((APct / 100.0) * AreaH);
  end;
begin
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  C.FillRect(Rect(0, 0, AWidth, AHeight));

  // Calcular exceso por centro.
  SetLength(Datos, Length(FCentres));
  N := 0;
  for I := 0 to High(FCentres) do
  begin
    var Exc: Double := 0;
    for J := 0 to High(FPeriodos) do
      if (FHorasCap[I, J] >= 0) and (FHorasPlan[I, J] > FHorasCap[I, J]) then
        Exc := Exc + (FHorasPlan[I, J] - FHorasCap[I, J]);
    if Exc > 0 then
    begin
      Datos[N].Nombre := FCentres[I].Titulo;
      if Trim(Datos[N].Nombre) = '' then Datos[N].Nombre := FCentres[I].CodiCentre;
      Datos[N].Exceso := Exc;
      Inc(N);
    end;
  end;
  SetLength(Datos, N);

  // Ordenar desc por exceso (insertion sort).
  for I := 1 to N - 1 do
  begin
    var Key: TExc := Datos[I]; var K: Integer := I - 1;
    while (K >= 0) and (Datos[K].Exceso < Key.Exceso) do
    begin Datos[K+1] := Datos[K]; Dec(K); end;
    Datos[K+1] := Key;
  end;

  Total := 0;
  for I := 0 to N - 1 do Total := Total + Datos[I].Exceso;

  // Titulo
  C.Font.Size := 12; C.Font.Style := [fsBold]; C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, 12, AWidth - 16, 36);
  DrawText(C.Handle,
    'Pareto de sobrecarga: '#191'qu'#233' centros concentran el exceso de carga?',
    -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  if (N = 0) or (Total <= 0) then
  begin
    C.Font.Size := 11; C.Font.Style := []; C.Font.Color := CLR_R51_75;
    R := Rect(16, 50, AWidth - 16, 90);
    DrawText(C.Handle,
      'No hay sobrecarga: ning'#250'n centro supera su capacidad en el horizonte. '#128077,
      -1, R, DT_LEFT or DT_TOP or DT_WORDBREAK);
    C.Brush.Style := bsSolid; Exit;
  end;

  ChartX0 := 60; ChartX1 := AWidth - 70;
  ChartTop := 60; ChartBottom := AHeight - 80;
  AreaW := ChartX1 - ChartX0; AreaH := ChartBottom - ChartTop;
  if (AreaW < 80) or (AreaH < 60) then Exit;

  // Grid + eje derecho (% acumulado) con guia del 80%
  C.Font.Size := 8; C.Font.Style := [];
  for var G := 0 to 4 do
  begin
    var Pv: Integer := G * 25;
    var Yg: Integer := PyPct(Pv);
    if Pv = 80 then C.Pen.Color := CLR_R_SOBRE else C.Pen.Color := CLR_GRID_LINE;
    C.Pen.Style := psSolid;
    C.MoveTo(ChartX0, Yg); C.LineTo(ChartX1, Yg);
    C.Font.Color := CLR_HEADER_TX;
    R := Rect(ChartX1 + 4, Yg - 8, ChartX1 + 66, Yg + 8);
    DrawText(C.Handle, PChar(IntToStr(Pv) + '%'), -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  end;
  var Y80: Integer := PyPct(80);
  C.Pen.Color := CLR_R_SOBRE; C.Pen.Style := psDot;
  C.MoveTo(ChartX0, Y80); C.LineTo(ChartX1, Y80); C.Pen.Style := psSolid;

  // Barras de exceso (escala 0..ExcMax)
  ExcMax := Datos[0].Exceso; if ExcMax <= 0 then ExcMax := 1;
  BarW := Max(8, (AreaW - (N + 1) * 5) div Max(1, N));
  Gap := 5;
  for I := 0 to N - 1 do
  begin
    X := ChartX0 + Gap + I * (BarW + Gap);
    BarTop := ChartBottom - Round((Datos[I].Exceso / ExcMax) * AreaH);
    C.Brush.Style := bsSolid; C.Brush.Color := CLR_R101_120;
    C.Pen.Color := CLR_R_SOBRE;
    C.RoundRect(X, BarTop, X + BarW, ChartBottom, 4, 4);
    // valor de horas encima
    C.Font.Size := 8; C.Font.Style := [fsBold]; C.Font.Color := CLR_HEADER_TX;
    C.Brush.Style := bsClear;
    R := Rect(X - 8, BarTop - 16, X + BarW + 8, BarTop - 2);
    DrawText(C.Handle, PChar(Format('%.0fh', [Datos[I].Exceso])), -1, R,
      DT_CENTER or DT_BOTTOM or DT_SINGLELINE);
  end;

  // Linea de % acumulado (GDI+ suave)
  SetLength(PtsAcum, N);
  Acum := 0; Sem80 := -1;
  for I := 0 to N - 1 do
  begin
    Acum := Acum + Datos[I].Exceso;
    var PctAc: Double := Acum / Total * 100.0;
    if (Sem80 < 0) and (PctAc >= 80) then Sem80 := I;
    X := ChartX0 + Gap + I * (BarW + Gap) + BarW div 2;
    PtsAcum[I] := Point(X, PyPct(PctAc));
  end;
  begin
    var Gp: TGPGraphics := TGPGraphics.Create(C.Handle);
    try
      Gp.SetSmoothingMode(SmoothingModeAntiAlias);
      var Pen: TGPPen := TGPPen.Create(MakeColor(255, $C4, $2F, $2F), 2.4);
      try
        Pen.SetLineJoin(LineJoinRound);
        for I := 1 to N - 1 do
          Gp.DrawLine(Pen, PtsAcum[I-1].X, PtsAcum[I-1].Y, PtsAcum[I].X, PtsAcum[I].Y);
      finally Pen.Free; end;
      var Br: TGPSolidBrush := TGPSolidBrush.Create(MakeColor(255, $C4, $2F, $2F));
      try
        for I := 0 to N - 1 do
          Gp.FillEllipse(Br, PtsAcum[I].X - 3, PtsAcum[I].Y - 3, 6, 6);
      finally Br.Free; end;
    finally Gp.Free; end;
  end;

  // Eje base + labels centros (iniciales)
  C.Pen.Color := CLR_HEADER_TX; C.Pen.Style := psSolid;
  C.MoveTo(ChartX0, ChartBottom); C.LineTo(ChartX1, ChartBottom);
  C.Font.Size := 7; C.Font.Color := CLR_HEADER_TX; C.Brush.Style := bsClear;
  for I := 0 to N - 1 do
  begin
    X := ChartX0 + Gap + I * (BarW + Gap);
    R := Rect(X - 10, ChartBottom + 4, X + BarW + 10, ChartBottom + 30);
    DrawText(C.Handle, PChar(Datos[I].Nombre), -1, R,
      DT_CENTER or DT_TOP or DT_WORDBREAK or DT_END_ELLIPSIS);
  end;

  // Resumen accionable
  C.Font.Size := 10; C.Font.Style := [fsBold]; C.Font.Color := CLR_R_SOBRE;
  C.Brush.Style := bsClear;
  var Msg: string;
  if Sem80 >= 0 then
    Msg := Format('%d de %d centros concentran el 80%% de la sobrecarga (%.0f h en total). '+
      'Actuar primero sobre ellos.', [Sem80 + 1, N, Total])
  else
    Msg := Format('La sobrecarga (%.0f h) est'#225' repartida entre los centros.', [Total]);
  R := Rect(16, AHeight - 44, AWidth - 16, AHeight - 20);
  DrawText(C.Handle, PChar(Msg), -1, R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  C.Brush.Style := bsSolid;
end;

procedure TfrmHeatmapCargaCentro.DibujarAnalisis(C: TCanvas; AWidth, AHeight: Integer);
// Diagrama de cascada (waterfall): capacidad total del taller -> se resta la
// carga planificada de cada centro -> capacidad restante. Muestra de un vistazo
// donde se consume la capacidad y cuanto margen queda.
type
  TWf = record Etiqueta: string; Valor: Double; EsTotal: Boolean; end;
var
  R: TRect;
  I, J, ChartX0, ChartX1, ChartTop, ChartBottom, AreaW, AreaH: Integer;
  Pasos: TArray<TWf>;
  CapTotal, CargaTotal, MaxAbs, Acum, PrevAcum: Double;
  N, BarW, Gap, X: Integer;
  function PyVal(V: Double): Integer;   // 0..MaxAbs mapea a alto
  begin
    if MaxAbs <= 0 then Exit(ChartBottom);
    Result := ChartBottom - Round((V / MaxAbs) * AreaH);
  end;
begin
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  C.FillRect(Rect(0, 0, AWidth, AHeight));

  // Totales
  CapTotal := 0; CargaTotal := 0;
  for I := 0 to High(FCentres) do
    for J := 0 to High(FPeriodos) do
      if FHorasCap[I, J] >= 0 then
      begin
        CapTotal := CapTotal + FHorasCap[I, J];
        CargaTotal := CargaTotal + FHorasPlan[I, J];
      end;

  // Titulo
  C.Font.Size := 12; C.Font.Style := [fsBold]; C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, 12, AWidth - 16, 36);
  DrawText(C.Handle,
    'Capacidad del taller: '#191'd'#243'nde se consume y cu'#225'nto margen queda?',
    -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  if CapTotal <= 0 then
  begin
    C.Font.Size := 11; C.Font.Style := []; C.Font.Color := CLR_HEADER_TX;
    R := Rect(16, 50, AWidth - 16, 90);
    DrawText(C.Handle, 'Sin capacidad para analizar (revisa calendarios).', -1, R,
      DT_LEFT or DT_TOP or DT_SINGLELINE);
    C.Brush.Style := bsSolid; Exit;
  end;

  // Construir pasos: [Capacidad total] - carga por centro - ... = [Restante]
  SetLength(Pasos, Length(FCentres) + 2);
  N := 0;
  Pasos[N].Etiqueta := 'Capacidad'; Pasos[N].Valor := CapTotal; Pasos[N].EsTotal := True; Inc(N);
  for I := 0 to High(FCentres) do
  begin
    var Carga: Double := 0;
    for J := 0 to High(FPeriodos) do
      if FHorasCap[I, J] >= 0 then Carga := Carga + FHorasPlan[I, J];
    if Carga > 0 then
    begin
      var Nom: string := FCentres[I].Titulo;
      if Trim(Nom) = '' then Nom := FCentres[I].CodiCentre;
      Pasos[N].Etiqueta := Nom; Pasos[N].Valor := -Carga; Pasos[N].EsTotal := False; Inc(N);
    end;
  end;
  Pasos[N].Etiqueta := 'Restante'; Pasos[N].Valor := CapTotal - CargaTotal;
  Pasos[N].EsTotal := True; Inc(N);
  SetLength(Pasos, N);

  MaxAbs := CapTotal * 1.05;
  if MaxAbs <= 0 then MaxAbs := 1;

  ChartX0 := 60; ChartX1 := AWidth - 40;
  ChartTop := 60; ChartBottom := AHeight - 80;
  AreaW := ChartX1 - ChartX0; AreaH := ChartBottom - ChartTop;
  if (AreaW < 80) or (AreaH < 60) then Exit;

  // Grid horizontal (horas)
  C.Font.Size := 8; C.Font.Style := [];
  for var G := 0 to 4 do
  begin
    var Hv: Double := MaxAbs * G / 4;
    var Yg: Integer := PyVal(Hv);
    C.Pen.Color := CLR_GRID_LINE; C.Pen.Style := psSolid;
    C.MoveTo(ChartX0, Yg); C.LineTo(ChartX1, Yg);
    C.Font.Color := CLR_HEADER_TX;
    R := Rect(0, Yg - 8, ChartX0 - 6, Yg + 8);
    DrawText(C.Handle, PChar(Format('%.0f', [Hv])), -1, R, DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  end;

  // Barras cascada
  BarW := Max(10, (AreaW - (N + 1) * 8) div Max(1, N));
  Gap := 8;
  Acum := 0;
  for I := 0 to N - 1 do
  begin
    X := ChartX0 + Gap + I * (BarW + Gap);
    var Yfrom, Yto: Integer;
    var Col: TColor;
    if Pasos[I].EsTotal then
    begin
      // Barra desde 0 hasta el valor (total absoluto)
      Yfrom := PyVal(0); Yto := PyVal(Pasos[I].Valor);
      if I = 0 then Col := CLR_R76_90        // capacidad (amarillo)
               else Col := CLR_R26_50;        // restante (verde)
      Acum := Pasos[I].Valor;
    end
    else
    begin
      // Barra flotante: de Acum a Acum+Valor (Valor es negativo = baja)
      PrevAcum := Acum;
      Acum := Acum + Pasos[I].Valor;
      Yfrom := PyVal(PrevAcum); Yto := PyVal(Acum);
      Col := CLR_R91_100;                      // consumo (naranja/azul)
    end;
    var Ytop: Integer := Min(Yfrom, Yto);
    var Ybot: Integer := Max(Yfrom, Yto);
    if Ybot - Ytop < 2 then Ybot := Ytop + 2;
    C.Brush.Style := bsSolid; C.Brush.Color := Col;
    C.Pen.Color := CLR_HEADER_TX;
    C.Rectangle(X, Ytop, X + BarW, Ybot);

    // Conector punteado con la barra siguiente (al nivel Acum)
    if (I < N - 1) and (not Pasos[I+1].EsTotal or (I = 0)) then
    begin
      C.Pen.Color := CLR_GRID_LINE; C.Pen.Style := psDot;
      var Ylink: Integer := PyVal(Acum);
      C.MoveTo(X + BarW, Ylink); C.LineTo(X + BarW + Gap, Ylink);
      C.Pen.Style := psSolid;
    end;

    // Valor
    C.Font.Size := 8; C.Font.Style := [fsBold]; C.Font.Color := CLR_HEADER_TX;
    C.Brush.Style := bsClear;
    R := Rect(X - 6, Ytop - 16, X + BarW + 6, Ytop - 2);
    var VLbl: string;
    if Pasos[I].EsTotal then VLbl := Format('%.0f', [Pasos[I].Valor])
                        else VLbl := Format('-%.0f', [-Pasos[I].Valor]);
    DrawText(C.Handle, PChar(VLbl), -1, R, DT_CENTER or DT_BOTTOM or DT_SINGLELINE);

    // Etiqueta abajo
    C.Font.Size := 7; C.Font.Style := []; C.Font.Color := CLR_HEADER_TX;
    R := Rect(X - 8, ChartBottom + 4, X + BarW + 8, ChartBottom + 30);
    DrawText(C.Handle, PChar(Pasos[I].Etiqueta), -1, R,
      DT_CENTER or DT_TOP or DT_WORDBREAK or DT_END_ELLIPSIS);
  end;

  // Eje base
  C.Pen.Color := CLR_HEADER_TX; C.Pen.Style := psSolid;
  C.MoveTo(ChartX0, ChartBottom); C.LineTo(ChartX1, ChartBottom);

  // Resumen
  C.Font.Size := 10; C.Font.Style := [fsBold]; C.Brush.Style := bsClear;
  var Pct: Double := CargaTotal / CapTotal * 100.0;
  var Msg: string;
  if CargaTotal <= CapTotal then
  begin
    C.Font.Color := CLR_R26_50;
    Msg := Format('Ocupaci'#243'n global %.0f%%: quedan %.0f h de margen sobre %.0f h de capacidad.',
      [Pct, CapTotal - CargaTotal, CapTotal]);
  end
  else
  begin
    C.Font.Color := CLR_R_SOBRE;
    Msg := Format('Ocupaci'#243'n global %.0f%%: faltan %.0f h de capacidad (taller sobrecargado).',
      [Pct, CargaTotal - CapTotal]);
  end;
  R := Rect(16, AHeight - 44, AWidth - 16, AHeight - 20);
  DrawText(C.Handle, PChar(Msg), -1, R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  C.Brush.Style := bsSolid;
end;

procedure TfrmHeatmapCargaCentro.pbAnalisisPaint(Sender: TObject);
begin
  DibujarAnalisis(pbAnalisis.Canvas, pbAnalisis.Width, pbAnalisis.Height);
end;

procedure TfrmHeatmapCargaCentro.EstiloBotonHeader(var ABtn: TcxButton);
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

procedure TfrmHeatmapCargaCentro.DetalleClick(Sender: TObject);
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

procedure TfrmHeatmapCargaCentro.ExportarPNGClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  Bmp: TBitmap;
  Png: TPngImage;
  Pb: TPaintBox;
  Sufijo: string;
begin
  if Length(FCentres) = 0 then
  begin
    ShowMessage('No hay datos para exportar.');
    Exit;
  end;
  // Exporta la vista (pesta'na) activa.
  if pcVistas.ActivePage = tabPareto then begin Pb := pbPareto; Sufijo := 'Pareto'; end
  else if pcVistas.ActivePage = tabAnalisis then begin Pb := pbAnalisis; Sufijo := 'Cascada'; end
  else begin Pb := pbMatrix; Sufijo := 'Matriz'; end;

  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'Imagen PNG (*.png)|*.png';
    Dlg.DefaultExt := 'png';
    Dlg.FileName := 'HeatmapCentros_' + Sufijo + '_' +
      FormatDateTime('yyyymmdd', dtDesde.Date) + '.png';
    if not Dlg.Execute then Exit;

    Bmp := TBitmap.Create;
    try
      Bmp.PixelFormat := pf24bit;
      Bmp.SetSize(Pb.Width, Pb.Height);
      // Redibuja la vista activa (a su tamanyo real) sobre el bitmap.
      if Pb = pbMatrix then DibujarMatriz(Bmp.Canvas, Bmp.Width, Bmp.Height)
      else if Pb = pbPareto then DibujarPareto(Bmp.Canvas, Bmp.Width, Bmp.Height)
      else DibujarAnalisis(Bmp.Canvas, Bmp.Width, Bmp.Height);
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

procedure TfrmHeatmapCargaCentro.ExportarCSVClick(Sender: TObject);
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
  if Length(FCentres) = 0 then
  begin
    ShowMessage('No hay datos para exportar.');
    Exit;
  end;
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'CSV (*.csv)|*.csv';
    Dlg.DefaultExt := 'csv';
    Dlg.FileName := 'HeatmapCentros_' +
      FormatDateTime('yyyymmdd', dtDesde.Date) + '.csv';
    if not Dlg.Execute then Exit;

    Sep := ';';   // Excel-ES usa ';' cuando la coma es separador decimal
    SB := TStringBuilder.Create;
    try
      // Cabecera
      SB.Append('Centro');
      for J := 0 to High(FPeriodos) do
        SB.Append(Sep).Append(FPeriodos[J].Label_);
      SB.Append(Sep).Append('Promedio');
      SB.AppendLine;

      // Filas de centros (valores = % de ocupacion)
      for I := 0 to High(FCentres) do
      begin
        var Nom: string := FCentres[I].Titulo;
        if Trim(Nom) = '' then Nom := FCentres[I].CodiCentre;
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
        for I := 0 to High(FCentres) do
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
