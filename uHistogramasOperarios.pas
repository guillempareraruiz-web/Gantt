unit uHistogramasOperarios;

{
  Form con 3 histogramas para vision de equipo:

    Tab 1 - Carga por operario (barras apiladas)
            Eje X: operarios (ordenados por carga total desc).
            Eje Y: horas en el periodo.
            Barras: segmento verde-gradient hasta 100% capacidad,
                    segmento rojo apilado para el exceso (>100%).
            Linea horizontal en la capacidad real del operario.

    Tab 2 - Distribucion de ocupacion
            Eje X: rangos de % ocupacion (0-25, 25-50, 50-75, 75-100, >100).
            Eje Y: numero de operarios en cada rango.
            Una barra por rango con color del rango.

    Tab 3 - Coste laboral por operario
            Eje X: operarios (ordenados por coste desc).
            Eje Y: coste en EUR (horas planificadas x SueldoEurHora).
            Calculo basico v1 (sin recargos turno/festivo).

  Filtros compartidos: rango de fechas + filtro de operarios. Datos
  recalculados una sola vez al cambiar filtros y reutilizados en los 3 tabs.

  Patron: TPaintBox custom (mismo estilo que los heatmaps).
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.Generics.Collections, System.Generics.Defaults,
  System.DateUtils, System.Math, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  Data.Win.ADODB, Data.DB,
  cxCheckComboBox, cxCheckBox, cxEdit, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxButtons,
  uCentreCalendar, uDemoMode,
  dxSkinsCore, dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, dxSkinWXI,
  dxSkinXmas2008Blue;

type
  TOpStat = record
    Id: Integer;
    Nombre: string;
    CalendarId: Integer;
    SueldoEurHora: Double;
    HorasAsignadas: Double;    // total en el periodo
    CapacidadHoras: Double;    // del calendario en el periodo
    PctOcupacion: Double;      // HorasAsignadas / CapacidadHoras * 100
    Coste: Double;             // HorasAsignadas * SueldoEurHora
  end;

  // Un punto de la serie temporal (tab Evolucion/Proyeccion): agregado del
  // equipo por sub-periodo (semana).
  TEvolPunto = record
    Inicio: TDateTime;
    Fin:    TDateTime;
    Label_: string;
    HorasPlan: Double;    // suma de horas asignadas del equipo
    HorasCap:  Double;    // suma de capacidad del equipo
    PctMedio:  Double;    // HorasPlan / HorasCap * 100 (-1 sin capacidad)
    EsProyeccion: Boolean; // True = semana futura (mas alla de Hasta)
  end;

  // KPIs agregados del equipo para la banda superior.
  TEquipoKPI = record
    NumOperarios:    Integer;
    NumSobrecarga:   Integer;   // % > 100
    OcupacionMedia:  Double;    // media de % de los que tienen capacidad
    HorasPlanTotal:  Double;
    HorasCapTotal:   Double;
    HorasOciosas:    Double;    // max(0, cap - plan) agregado
    CosteTotal:      Double;
  end;

  TfrmHistogramasOperarios = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlToolbar: TPanel;
    lblDesde: TLabel;
    dtDesde: TDateTimePicker;
    lblHasta: TLabel;
    dtHasta: TDateTimePicker;
    lblOperarios: TLabel;
    cbOperarios: TcxCheckComboBox;
    btnRecalcular: TcxButton;
    pcTabs: TPageControl;
    tabCarga: TTabSheet;
    tabDistrib: TTabSheet;
    tabCoste: TTabSheet;
    sbCarga: TScrollBox;
    pbCarga: TPaintBox;
    sbDistrib: TScrollBox;
    pbDistrib: TPaintBox;
    sbCoste: TScrollBox;
    pbCoste: TPaintBox;
    tabComparativa: TTabSheet;
    sbComparativa: TScrollBox;
    pbComparativa: TPaintBox;
    tabEvolucion: TTabSheet;
    sbEvolucion: TScrollBox;
    pbEvolucion: TPaintBox;
    tabProyeccion: TTabSheet;
    sbProyeccion: TScrollBox;
    pbProyeccion: TPaintBox;
    tabPareto: TTabSheet;
    sbPareto: TScrollBox;
    pbPareto: TPaintBox;
    tabScatter: TTabSheet;
    sbScatter: TScrollBox;
    pbScatter: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnRecalcularClick(Sender: TObject);
    procedure ParametrosChange(Sender: TObject);
    procedure cbOperariosChange(Sender: TObject);
    procedure pbCargaPaint(Sender: TObject);
    procedure pbDistribPaint(Sender: TObject);
    procedure pbCostePaint(Sender: TObject);
    procedure pbComparativaPaint(Sender: TObject);
    procedure pbEvolucionPaint(Sender: TObject);
    procedure pbProyeccionPaint(Sender: TObject);
    procedure pbParetoPaint(Sender: TObject);
    procedure pbScatterPaint(Sender: TObject);
  private
    FAllOps: TArray<TOpStat>;
    FStatsCarga: TArray<TOpStat>;   // ordenado segun FSortCargaCol/Desc
    FStatsCoste: TArray<TOpStat>;   // ordenado segun FSortCosteCol/Desc
    FDistrib: array[0..4] of Integer; // contadores por rango
    FEvol: TArray<TEvolPunto>;      // serie temporal (tab Evolucion)
    FProy: TArray<TEvolPunto>;      // serie con proyeccion futura (tab Proyeccion)
    FProySemAlerta: Integer;        // indice de la 1a semana proyectada >100% (-1 ninguna)
    FKPI: TEquipoKPI;               // KPIs de la banda superior
    // Orden de cada tab: col 0 = nombre, 1 = valor (%/coste). Indep. por tab.
    FSortCargaCol: Integer;
    FSortCargaDesc: Boolean;
    FSortCosteCol: Integer;
    FSortCosteDesc: Boolean;
    FUpdatingOps: Boolean;
    FLoadingPrefs: Boolean;
    FBtnExportPNG: TcxButton;
    FBtnExportCSV: TcxButton;
    FCmbDepto: TComboBox;                       // filtro por departamento
    FLblDepto: TLabel;
    FDeptoIds: TArray<Integer>;                 // DepartmentId por indice del combo (0 = Todos)
    FDeptoSel: Integer;                         // DepartmentId activo (0 = Todos)
    procedure CargarOperariosDesdeSQL;
    procedure CargarOperariosDemo;
    procedure LlenarStatsDemo(AFiltrados: TList<TOpStat>);
    procedure DemoChanged(Sender: TObject);
    procedure CargarOperariosCombo;
    procedure CargarDepartamentosCombo;
    procedure DeptoChange(Sender: TObject);
    procedure RecalcularDatos;
    procedure ComputeChartSize(APaint: TPaintBox; AItemCount: Integer);
    procedure LoadPrefs;
    procedure SavePrefs;
    procedure DrawRoundedBar(ACanvas: TCanvas; const R: TRect;
      ABaseColor, AHighlightColor: TColor; ARadius: Integer);
    // Cuerpo de pintado parametrizado por canvas/tamano (para exportar a PNG).
    procedure DibujarCarga(C: TCanvas; AWidth, AHeight: Integer);
    procedure DibujarDistrib(C: TCanvas; AWidth, AHeight: Integer);
    procedure DibujarCoste(C: TCanvas; AWidth, AHeight: Integer);
    procedure DibujarComparativa(C: TCanvas; AWidth, AHeight: Integer);
    procedure DibujarEvolucion(C: TCanvas; AWidth, AHeight: Integer);
    procedure DibujarProyeccion(C: TCanvas; AWidth, AHeight: Integer);
    procedure DibujarPareto(C: TCanvas; AWidth, AHeight: Integer);
    procedure DibujarScatter(C: TCanvas; AWidth, AHeight: Integer);
    procedure CalcularProyeccion;
    // Dibuja una serie temporal (area + linea suavizada + puntos) con GDI+
    // (antialiasing). APuntos: array de la serie; ABaseY: y del eje 0.
    // ASplitReal: nº de puntos "reales" (solidos); el resto se pinta punteado.
    procedure DibujarSerieSuave(C: TCanvas; const APuntos: TArray<TPoint>;
      const APcts: TArray<Double>; ABaseY, ASplitReal: Integer);
    procedure DibujarBandaKPI(C: TCanvas; AWidth, AY, AHeight: Integer);
    procedure OrdenarStats(var AStats: TArray<TOpStat>; ACol: Integer;
      ADesc: Boolean; APorCoste: Boolean);
    procedure pbCargaMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbCosteMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure EstiloBotonHeader(var ABtn: TcxButton);
    procedure ExportarPNGClick(Sender: TObject);
    procedure ExportarCSVClick(Sender: TObject);
  public
    class procedure Execute;
  end;

implementation

{$R *.dfm}

uses
  uDMPlanner, uHelpViewer, System.IOUtils,
  Winapi.GDIPOBJ, Winapi.GDIPAPI;

const
  // Banda de KPIs del equipo (franja superior comun a los tabs de barras).
  CH_KPI_H = 76;

  // Numero de semanas futuras a proyectar mas alla del rango (tab Proyeccion).
  PROY_SEMANAS_FUTURAS = 8;

  // Card-style: zebra, header destacado, eje al 100% claro.
  CH_MARGIN_LEFT   = 220; // labels operarios (carga / coste)
  CH_MARGIN_RIGHT  = 40;
  CH_MARGIN_TOP    = 56;  // espacio para header con ejes %
  CH_MARGIN_BOTTOM = 50;
  CH_BAR_HEIGHT    = 22;
  CH_ROW_HEIGHT    = 44;  // fila completa (zebra)
  CH_BAR_RADIUS    = 6;

  // Escala uniforme 0-130%: la barra del 100% ocupa el 100/130 del area.
  CH_SCALE_MAX_PCT = 130;

  // Distribucion (vertical, barras verticales)
  CHD_MARGIN_LEFT   = 80;
  CHD_MARGIN_RIGHT  = 30;
  CHD_MARGIN_TOP    = 50;
  CHD_MARGIN_BOTTOM = 70;
  CHD_BAR_WIDTH     = 140;
  CHD_BAR_GAP       = 22;
  CHD_BAR_RADIUS    = 8;

const
  // Paleta modernizada (BGR)
  CLR_PAPER:        TColor = $00FFFFFF;  // fondo principal blanco
  CLR_ZEBRA:        TColor = $00FAFAFA;
  CLR_ROW_DIV:      TColor = $00EDEDED;

  CLR_HEADER_BG:    TColor = $00F8F4ED;
  CLR_HEADER_TX:    TColor = $005A4A36;
  CLR_AXIS_FAINT:   TColor = $00DCDCDC;
  CLR_AXIS_100:     TColor = $00808080;

  CLR_TXT_PRIMARY:  TColor = $00333333;
  CLR_TXT_MUTED:    TColor = $00888888;
  CLR_TXT_ON_BAR:   TColor = $00FFFFFF;

  CLR_LO_BASE:      TColor = $0072B870;
  CLR_LO_HIGH:      TColor = $0085C586;
  CLR_MD_BASE:      TColor = $0044B8C8;
  CLR_MD_HIGH:      TColor = $005CCDDD;
  CLR_HI_BASE:      TColor = $001A8FE0;
  CLR_HI_HIGH:      TColor = $003CA8E8;
  CLR_TOP_BASE:     TColor = $00146EBF;
  CLR_TOP_HIGH:     TColor = $002E89D6;
  CLR_OVER_BASE:    TColor = $002E2EB8;
  CLR_OVER_HIGH:    TColor = $004848D0;

  CLR_EMPTY_BAR:    TColor = $00EEEEEE;

  CLR_COST_BASE:    TColor = $00A86E2C;
  CLR_COST_HIGH:    TColor = $00BD832F;

class procedure TfrmHistogramasOperarios.Execute;
var
  F: TfrmHistogramasOperarios;
begin
  F := TfrmHistogramasOperarios.Create(nil);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmHistogramasOperarios.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  sbCarga.DoubleBuffered := True;
  sbDistrib.DoubleBuffered := True;
  sbCoste.DoubleBuffered := True;
  sbComparativa.DoubleBuffered := True;
  sbEvolucion.DoubleBuffered := True;
  sbProyeccion.DoubleBuffered := True;
  sbPareto.DoubleBuffered := True;
  sbScatter.DoubleBuffered := True;
  FDeptoSel := 0;
  FSortCargaCol := 1;  FSortCargaDesc := True;   // por % ocupacion desc
  FSortCosteCol := 1;  FSortCosteDesc := True;   // por coste desc

  // Ordenacion por clic en la cabecera de los tabs Carga y Coste.
  pbCarga.OnMouseDown := pbCargaMouseDown;
  pbCoste.OnMouseDown := pbCosteMouseDown;

  // Botones Exportar (mismo estilo que la toolbar del header principal).
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

  FLoadingPrefs := True;
  try
    // Defaults: ultimos 30 dias
    dtHasta.Date := Trunc(Now);
    dtDesde.Date := IncDay(dtHasta.Date, -30);
    CargarDepartamentosCombo;
    CargarOperariosDesdeSQL;
    CargarOperariosCombo;
    LoadPrefs;
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
  DemoMode.AddListener(DemoChanged);
  THelpViewer.InstallHelp(Self, 'uHistogramasOperarios',
    'Histogramas de operarios');
end;

procedure TfrmHistogramasOperarios.FormDestroy(Sender: TObject);
begin
  DemoMode.RemoveListener(DemoChanged);
end;

procedure TfrmHistogramasOperarios.CargarOperariosDesdeSQL;
var
  Q: TADOQuery;
  List: TList<TOpStat>;
  R: TOpStat;
begin
  SetLength(FAllOps, 0);

  if DemoMode.Active then
  begin
    CargarOperariosDemo;
    Exit;
  end;

  if (DMPlanner = nil) or (DMPlanner.ADOConnection = nil) or
     (not DMPlanner.ADOConnection.Connected) then
    Exit;

  List := TList<TOpStat>.Create;
  Q := TADOQuery.Create(nil);
  try
    Q.Connection := DMPlanner.ADOConnection;
    if FDeptoSel > 0 then
      Q.SQL.Text :=
        'SELECT o.OperatorId, o.Nombre, ISNULL(o.CalendarId, 0) AS CalendarId, ' +
        '       ISNULL(o.SueldoEurHora, 0) AS SueldoEurHora ' +
        'FROM FS_PL_Operator o ' +
        'INNER JOIN FS_PL_OperatorDepartment od ' +
        '        ON od.CodigoEmpresa = o.CodigoEmpresa ' +
        '       AND od.OperatorId = o.OperatorId ' +
        'WHERE o.CodigoEmpresa = :CE AND ISNULL(o.Activo, 1) = 1 ' +
        '  AND od.DepartmentId = :DEP ' +
        'ORDER BY o.Nombre'
    else
      Q.SQL.Text :=
        'SELECT OperatorId, Nombre, ISNULL(CalendarId, 0) AS CalendarId, ' +
        '       ISNULL(SueldoEurHora, 0) AS SueldoEurHora ' +
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
        R := Default(TOpStat);
        R.Id := Q.FieldByName('OperatorId').AsInteger;
        R.Nombre := Q.FieldByName('Nombre').AsString;
        R.CalendarId := Q.FieldByName('CalendarId').AsInteger;
        R.SueldoEurHora := Q.FieldByName('SueldoEurHora').AsFloat;
        List.Add(R);
        Q.Next;
      end;
    except
    end;
    FAllOps := List.ToArray;
  finally
    Q.Free;
    List.Free;
  end;
end;

procedure TfrmHistogramasOperarios.CargarOperariosDemo;
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
  R: TOpStat;
begin
  SetLength(FAllOps, Length(NOMBRES));
  K := 0;
  for I := 0 to High(NOMBRES) do
  begin
    // Reparto ficticio en 4 departamentos (por indice). DepartmentId demo 1..4.
    if (FDeptoSel > 0) and ((I mod 4) + 1 <> FDeptoSel) then Continue;
    R := Default(TOpStat);
    R.Id := 9000 + I;                 // ids ficticios, no chocan con reales
    R.Nombre := NOMBRES[I];
    R.CalendarId := 0;                // irrelevante: los stats se generan directos
    R.SueldoEurHora := 14 + (I mod 6) * 2;  // 14..24 EUR/h ficticios
    FAllOps[K] := R;
    Inc(K);
  end;
  SetLength(FAllOps, K);
end;

procedure TfrmHistogramasOperarios.CargarDepartamentosCombo;
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

procedure TfrmHistogramasOperarios.DeptoChange(Sender: TObject);
begin
  if FCmbDepto.ItemIndex < 0 then Exit;
  if FCmbDepto.ItemIndex <= High(FDeptoIds) then
    FDeptoSel := FDeptoIds[FCmbDepto.ItemIndex]
  else
    FDeptoSel := 0;

  FLoadingPrefs := True;
  try
    CargarOperariosDesdeSQL;
    CargarOperariosCombo;
  finally
    FLoadingPrefs := False;
  end;
  RecalcularDatos;
end;

procedure TfrmHistogramasOperarios.DemoChanged(Sender: TObject);
begin
  // Al conmutar el modo demo, recargamos departamentos y operarios (ficticios
  // en demo; reales de la BD si no) y recalculamos.
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

procedure TfrmHistogramasOperarios.CargarOperariosCombo;
var
  I: Integer;
  Lbl: string;
begin
  FUpdatingOps := True;
  try
    cbOperarios.Properties.Items.Clear;
    cbOperarios.Properties.Items.AddCheckItem('(Todos)');
    cbOperarios.States[0] := cbsChecked;
    for I := 0 to High(FAllOps) do
    begin
      Lbl := FAllOps[I].Nombre;
      if Trim(Lbl) = '' then Lbl := 'Operario #' + IntToStr(FAllOps[I].Id);
      cbOperarios.Properties.Items.AddCheckItem(Lbl);
      cbOperarios.States[I + 1] := cbsChecked;
    end;
    if Length(FAllOps) = 0 then
      cbOperarios.Properties.EmptySelectionText := 'Sin operarios disponibles'
    else
      cbOperarios.Properties.EmptySelectionText := 'Ningun operario seleccionado';
  finally
    FUpdatingOps := False;
  end;
end;

procedure TfrmHistogramasOperarios.cbOperariosChange(Sender: TObject);
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

procedure TfrmHistogramasOperarios.FormResize(Sender: TObject);
begin
  ComputeChartSize(pbCarga, Length(FStatsCarga));
  ComputeChartSize(pbCoste, Length(FStatsCoste));
  // distrib: tamano fijo segun barras
  pbDistrib.SetBounds(0, 0,
    Max(sbDistrib.ClientWidth,
        CHD_MARGIN_LEFT + CHD_MARGIN_RIGHT + 5 * (CHD_BAR_WIDTH + CHD_BAR_GAP)),
    Max(sbDistrib.ClientHeight, 360));
  // comparativa y evolucion: llenan el area visible (se redibujan a su tamano).
  pbComparativa.SetBounds(0, 0,
    Max(sbComparativa.ClientWidth, 700),
    Max(sbComparativa.ClientHeight, 420));
  pbEvolucion.SetBounds(0, 0,
    Max(sbEvolucion.ClientWidth, 700),
    Max(sbEvolucion.ClientHeight, 380));
  pbProyeccion.SetBounds(0, 0,
    Max(sbProyeccion.ClientWidth, 700),
    Max(sbProyeccion.ClientHeight, 400));
  pbPareto.SetBounds(0, 0,
    Max(sbPareto.ClientWidth, 700),
    Max(sbPareto.ClientHeight, 400));
  pbScatter.SetBounds(0, 0,
    Max(sbScatter.ClientWidth, 700),
    Max(sbScatter.ClientHeight, 400));
end;

procedure TfrmHistogramasOperarios.ComputeChartSize(APaint: TPaintBox;
  AItemCount: Integer);
var
  W, H: Integer;
  ScrollBox: TScrollBox;
begin
  ScrollBox := APaint.Parent as TScrollBox;
  W := Max(ScrollBox.ClientWidth, 800);
  H := CH_KPI_H + CH_MARGIN_TOP + CH_MARGIN_BOTTOM + AItemCount * CH_ROW_HEIGHT;
  if H < ScrollBox.ClientHeight then H := ScrollBox.ClientHeight;
  APaint.SetBounds(0, 0, W, H);
end;

procedure TfrmHistogramasOperarios.DrawRoundedBar(ACanvas: TCanvas;
  const R: TRect; ABaseColor, AHighlightColor: TColor; ARadius: Integer);
var
  HalfH, Y: Integer;
  Ratio: Double;
  Cr, Cg, Cb, Hr, Hg, Hb: Byte;
  RR, GG, BB: Integer;
begin
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;

  // Mini-gradient vertical: highlight arriba, base abajo.
  Cr := GetRValue(ABaseColor);
  Cg := GetGValue(ABaseColor);
  Cb := GetBValue(ABaseColor);
  Hr := GetRValue(AHighlightColor);
  Hg := GetGValue(AHighlightColor);
  Hb := GetBValue(AHighlightColor);

  HalfH := R.Bottom - R.Top;
  if HalfH <= 0 then Exit;

  // Pinta linea a linea con interpolacion
  for Y := R.Top to R.Bottom - 1 do
  begin
    Ratio := (Y - R.Top) / HalfH;
    RR := Hr + Round((Cr - Hr) * Ratio);
    GG := Hg + Round((Cg - Hg) * Ratio);
    BB := Hb + Round((Cb - Hb) * Ratio);
    ACanvas.Pen.Color := RGB(RR, GG, BB);
    ACanvas.MoveTo(R.Left, Y);
    ACanvas.LineTo(R.Right, Y);
  end;

  // Bordes redondeados: enmascarar las esquinas con el fondo (paper)
  if ARadius > 0 then
  begin
    ACanvas.Pen.Color := CLR_PAPER;
    ACanvas.Brush.Color := CLR_PAPER;
    // No usamos RoundRect directamente porque ya pintamos el gradient.
    // En lugar de mascara, redibujamos como TGPPath... mantenemos simple:
    // dejamos el rectangulo recto. Si quieres esquinas reales, en el caller
    // usar RoundRect en lugar de este metodo.
  end;
end;

procedure TfrmHistogramasOperarios.LlenarStatsDemo(AFiltrados: TList<TOpStat>);
var
  I: Integer;
  DiasRango: Integer;
  CapHoras, PctObjetivo: Double;
begin
  // Genera stats ficticios deterministas (sin Random) coherentes con el rango
  // de fechas seleccionado. La capacidad se estima a ~8 h laborables por dia
  // habil (aprox 5/7 del rango). El % objetivo se reparte por indice para que
  // se vean todos los rangos de la distribucion y alguna sobrecarga.
  DiasRango := Max(1, Trunc(dtHasta.Date) - Trunc(dtDesde.Date) + 1);
  for I := 0 to AFiltrados.Count - 1 do
  begin
    var Op := AFiltrados[I];
    CapHoras := DiasRango * (5.0 / 7.0) * 8.0;   // horas laborables estimadas
    // Objetivo entre ~15% y ~125% segun el id, con dispersion.
    PctObjetivo := 15 + ((Op.Id * 29) mod 111);   // 15..125
    Op.CapacidadHoras := CapHoras;
    Op.HorasAsignadas := CapHoras * PctObjetivo / 100.0;
    Op.PctOcupacion := PctObjetivo;
    Op.Coste := Op.HorasAsignadas * Op.SueldoEurHora;
    AFiltrados[I] := Op;
  end;
end;

procedure TfrmHistogramasOperarios.btnRecalcularClick(Sender: TObject);
begin
  RecalcularDatos;
end;

procedure TfrmHistogramasOperarios.ParametrosChange(Sender: TObject);
begin
  RecalcularDatos;
  SavePrefs;
end;

procedure TfrmHistogramasOperarios.RecalcularDatos;
var
  Q: TADOQuery;
  ProjectId: Integer;
  Desde, Hasta: TDateTime;
  IdxById: TDictionary<Integer, Integer>;
  I, K: Integer;
  OperatorId: Integer;
  NodeInicio, NodeFin: TDateTime;
  Horas: Double;
  NodeDuracionMin, OverlapMin, HorasParte: Double;
  OvStart, OvEnd: TDateTime;
  Cal: TCentreCalendar;
  CapMin: Integer;
  Filtrados: TList<TOpStat>;
  Idx: Integer;
  Range: Integer;
begin
  Desde := Trunc(dtDesde.Date);
  Hasta := Trunc(dtHasta.Date) + 1; // inclusivo hasta el final del dia
  if Hasta <= Desde then Exit;

  // 1) Filtrar operarios seleccionados y resetear contadores
  Filtrados := TList<TOpStat>.Create;
  try
    for I := 0 to High(FAllOps) do
      if (I + 1 < cbOperarios.Properties.Items.Count) and
         (cbOperarios.States[I + 1] = cbsChecked) then
      begin
        var Op := FAllOps[I];
        Op.HorasAsignadas := 0;
        Op.CapacidadHoras := 0;
        Op.PctOcupacion := 0;
        Op.Coste := 0;
        Filtrados.Add(Op);
      end;

    if Filtrados.Count = 0 then
    begin
      SetLength(FStatsCarga, 0);
      SetLength(FStatsCoste, 0);
      for Idx := 0 to High(FDistrib) do FDistrib[Idx] := 0;
      FormResize(nil);
      pbCarga.Invalidate;
      pbDistrib.Invalidate;
      pbCoste.Invalidate;
      Exit;
    end;

    IdxById := TDictionary<Integer, Integer>.Create;
    try
      for I := 0 to Filtrados.Count - 1 do
        IdxById.AddOrSetValue(Filtrados[I].Id, I);

      // Modo demo: rellenar horas/capacidad/coste ficticios y saltar el SQL.
      if DemoMode.Active then
        LlenarStatsDemo(Filtrados)
      else
      begin
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
          Q.Parameters.ParamByName('HInicio').Value := Desde;
          Q.Parameters.ParamByName('HFin').Value := Hasta;
          try
            Q.Open;
            while not Q.Eof do
            begin
              OperatorId := Q.FieldByName('OperatorId').AsInteger;
              if IdxById.TryGetValue(OperatorId, Idx) then
              begin
                NodeInicio := Q.FieldByName('FechaInicio').AsDateTime;
                NodeFin    := Q.FieldByName('FechaFin').AsDateTime;
                Horas      := Q.FieldByName('Horas').AsFloat;

                NodeDuracionMin := MinutesBetween(NodeFin, NodeInicio);
                if (NodeDuracionMin > 0) and (Horas > 0) then
                begin
                  // Prorratear si el nodo se sale del rango
                  OvStart := Desde;
                  if NodeInicio > OvStart then OvStart := NodeInicio;
                  OvEnd := Hasta;
                  if NodeFin < OvEnd then OvEnd := NodeFin;
                  if OvEnd > OvStart then
                  begin
                    OverlapMin := MinutesBetween(OvEnd, OvStart);
                    HorasParte := Horas * (OverlapMin / NodeDuracionMin);
                    var Op := Filtrados[Idx];
                    Op.HorasAsignadas := Op.HorasAsignadas + HorasParte;
                    Filtrados[Idx] := Op;
                  end;
                end;
              end;
              Q.Next;
            end;
          except
          end;
        finally
          Q.Free;
        end;
      end;

      // 2) Capacidad y derivados
      for I := 0 to Filtrados.Count - 1 do
      begin
        var Op := Filtrados[I];
        Cal := nil;
        if (DMPlanner.CalendarsRepo <> nil) and (Op.CalendarId > 0) then
          DMPlanner.CalendarsRepo.TryGetById(Op.CalendarId, Cal);
        if Cal <> nil then
        begin
          CapMin := Cal.WorkingMinutesBetween(Desde, Hasta);
          if CapMin > 0 then
            Op.CapacidadHoras := CapMin / 60.0
          else
            Op.CapacidadHoras := 0;
        end;
        if Op.CapacidadHoras > 0 then
          Op.PctOcupacion := (Op.HorasAsignadas / Op.CapacidadHoras) * 100.0
        else
          Op.PctOcupacion := -1; // sin capacidad
        Op.Coste := Op.HorasAsignadas * Op.SueldoEurHora;
        Filtrados[I] := Op;
      end;
      end;  // fin del bloque no-demo (else)
    finally
      IdxById.Free;
    end;

    // 3) Stats ordenados segun el criterio activo de cada tab.
    FStatsCarga := Filtrados.ToArray;
    OrdenarStats(FStatsCarga, FSortCargaCol, FSortCargaDesc, False);
    FStatsCoste := Filtrados.ToArray;
    OrdenarStats(FStatsCoste, FSortCosteCol, FSortCosteDesc, True);

    // 4) Distribucion por rangos
    for K := 0 to High(FDistrib) do FDistrib[K] := 0;
    for I := 0 to Filtrados.Count - 1 do
    begin
      var Op := Filtrados[I];
      if Op.PctOcupacion < 0 then Continue; // sin capacidad: no cuenta
      if Op.PctOcupacion < 25 then Range := 0
      else if Op.PctOcupacion < 50 then Range := 1
      else if Op.PctOcupacion < 75 then Range := 2
      else if Op.PctOcupacion <= 100 then Range := 3
      else Range := 4;
      Inc(FDistrib[Range]);
    end;

    // 5) KPIs del equipo (banda superior + tab Comparativa)
    FKPI := Default(TEquipoKPI);
    FKPI.NumOperarios := Filtrados.Count;
    begin
      var SumaPct: Double := 0; var CntPct: Integer := 0;
      for I := 0 to Filtrados.Count - 1 do
      begin
        var Op := Filtrados[I];
        FKPI.HorasPlanTotal := FKPI.HorasPlanTotal + Op.HorasAsignadas;
        FKPI.CosteTotal := FKPI.CosteTotal + Op.Coste;
        if Op.CapacidadHoras > 0 then
        begin
          FKPI.HorasCapTotal := FKPI.HorasCapTotal + Op.CapacidadHoras;
          FKPI.HorasOciosas := FKPI.HorasOciosas +
            Max(0, Op.CapacidadHoras - Op.HorasAsignadas);
          SumaPct := SumaPct + Op.PctOcupacion;
          Inc(CntPct);
          if Op.PctOcupacion > 100 then Inc(FKPI.NumSobrecarga);
        end;
      end;
      if CntPct > 0 then FKPI.OcupacionMedia := SumaPct / CntPct
                    else FKPI.OcupacionMedia := -1;
    end;

    // 6) Serie temporal para el tab Evolucion: sub-periodos semanales dentro
    //    del rango, con el % medio del equipo en cada uno.
    begin
      SetLength(FEvol, 0);
      var Cursor: TDateTime := Desde;
      // Snap al lunes de la semana de inicio.
      Cursor := Cursor - ((DayOfTheWeek(Cursor) + 6) mod 7);
      var Guard: Integer := 0;
      while (Cursor < Hasta) and (Guard < 200) do
      begin
        Inc(Guard);
        var P: TEvolPunto;
        P := Default(TEvolPunto);
        P.Inicio := Cursor;
        P.Fin := IncDay(Cursor, 7);
        if P.Fin > Hasta then P.Fin := Hasta;
        P.Label_ := 'S' + IntToStr(WeekOf(Cursor));
        FEvol := FEvol + [P];
        Cursor := IncDay(Cursor, 7);
      end;

      // En demo no hay nodos con fecha: generamos una serie semanal creible
      // por operario (oscila alrededor de su % objetivo con DemoSerieHaciaValor),
      // de modo que la linea NO salga plana. La capacidad se reparte por dias.
      if DemoMode.Active and (Length(FEvol) > 0) then
      begin
        var DiasTot: Double := Max(1, Trunc(Hasta) - Trunc(Desde));
        for I := 0 to Filtrados.Count - 1 do
        begin
          var Op := Filtrados[I];
          // Serie de % semanal alrededor del % objetivo del operario.
          var SeriePct: TArray<Double> :=
            DemoSerieHaciaValor(Op.PctOcupacion, Length(FEvol), 0.30, Op.Id);
          for var W := 0 to High(FEvol) do
          begin
            var DiasSub: Double := Trunc(FEvol[W].Fin) - Trunc(FEvol[W].Inicio);
            var CapSemana: Double := Op.CapacidadHoras * DiasSub / DiasTot;
            FEvol[W].HorasCap := FEvol[W].HorasCap + CapSemana;
            // Plan de la semana = capacidad de la semana * % de esa semana.
            FEvol[W].HorasPlan := FEvol[W].HorasPlan + CapSemana * SeriePct[W] / 100.0;
          end;
        end;
      end;

      // En modo real, poblar plan/capacidad por sub-periodo con una consulta
      // agregada por semana (evita traer todos los nodos otra vez a Pascal).
      if (not DemoMode.Active) and (Length(FEvol) > 0) and
         (DMPlanner.CurrentProjectId > 0) then
      begin
        // Capacidad por semana: suma de la de cada operario filtrado.
        for var W := 0 to High(FEvol) do
        begin
          for I := 0 to Filtrados.Count - 1 do
          begin
            var Op := Filtrados[I];
            Cal := nil;
            if (DMPlanner.CalendarsRepo <> nil) and (Op.CalendarId > 0) then
              DMPlanner.CalendarsRepo.TryGetById(Op.CalendarId, Cal);
            if Cal <> nil then
            begin
              CapMin := Cal.WorkingMinutesBetween(FEvol[W].Inicio, FEvol[W].Fin);
              if CapMin > 0 then
                FEvol[W].HorasCap := FEvol[W].HorasCap + CapMin / 60.0;
            end;
          end;
        end;

        // Horas planificadas por semana: prorrateo del solapamiento de cada
        // asignacion con cada sub-periodo.
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
          Q.Parameters.ParamByName('PID').Value := DMPlanner.CurrentProjectId;
          Q.Parameters.ParamByName('HInicio').Value := Desde;
          Q.Parameters.ParamByName('HFin').Value := Hasta;
          try
            Q.Open;
            while not Q.Eof do
            begin
              OperatorId := Q.FieldByName('OperatorId').AsInteger;
              // Solo operarios del filtro actual.
              var EnFiltro: Boolean := False;
              for I := 0 to Filtrados.Count - 1 do
                if Filtrados[I].Id = OperatorId then begin EnFiltro := True; Break; end;
              if EnFiltro then
              begin
                NodeInicio := Q.FieldByName('FechaInicio').AsDateTime;
                NodeFin    := Q.FieldByName('FechaFin').AsDateTime;
                Horas      := Q.FieldByName('Horas').AsFloat;
                NodeDuracionMin := MinutesBetween(NodeFin, NodeInicio);
                if (NodeDuracionMin > 0) and (Horas > 0) then
                  for var W := 0 to High(FEvol) do
                  begin
                    OvStart := FEvol[W].Inicio;
                    if NodeInicio > OvStart then OvStart := NodeInicio;
                    OvEnd := FEvol[W].Fin;
                    if NodeFin < OvEnd then OvEnd := NodeFin;
                    if OvEnd > OvStart then
                    begin
                      OverlapMin := MinutesBetween(OvEnd, OvStart);
                      FEvol[W].HorasPlan := FEvol[W].HorasPlan +
                        Horas * (OverlapMin / NodeDuracionMin);
                    end;
                  end;
              end;
              Q.Next;
            end;
          except
          end;
        finally
          Q.Free;
        end;
      end;

      // Derivar % medio de cada punto.
      for var W := 0 to High(FEvol) do
        if FEvol[W].HorasCap > 0 then
          FEvol[W].PctMedio := FEvol[W].HorasPlan / FEvol[W].HorasCap * 100.0
        else
          FEvol[W].PctMedio := -1;
    end;
  finally
    Filtrados.Free;
  end;

  // Proyeccion a futuro (usa FStatsCarga, ya poblado con el filtro actual).
  CalcularProyeccion;

  FormResize(nil);
  pbCarga.Invalidate;
  pbDistrib.Invalidate;
  pbCoste.Invalidate;
  pbComparativa.Invalidate;
  pbEvolucion.Invalidate;
  pbProyeccion.Invalidate;
  pbPareto.Invalidate;
  pbScatter.Invalidate;
end;

procedure TfrmHistogramasOperarios.OrdenarStats(var AStats: TArray<TOpStat>;
  ACol: Integer; ADesc: Boolean; APorCoste: Boolean);
// Col 0 = por nombre. Col 1 = por valor: coste si APorCoste, si no % ocupacion.
begin
  if Length(AStats) < 2 then Exit;
  TArray.Sort<TOpStat>(AStats,
    TComparer<TOpStat>.Construct(
      function(const A, B: TOpStat): Integer
      var
        NomA, NomB: string;
      begin
        if ACol = 0 then
        begin
          NomA := A.Nombre; if Trim(NomA) = '' then NomA := 'Operario #' + IntToStr(A.Id);
          NomB := B.Nombre; if Trim(NomB) = '' then NomB := 'Operario #' + IntToStr(B.Id);
          Result := CompareText(NomA, NomB);
        end
        else if APorCoste then
          Result := CompareValue(A.Coste, B.Coste)
        else
          Result := CompareValue(A.PctOcupacion, B.PctOcupacion);
        if ADesc then Result := -Result;
      end));
end;

procedure TfrmHistogramasOperarios.pbCargaMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NuevaCol: Integer;
begin
  if Button <> mbLeft then Exit;
  if Length(FStatsCarga) = 0 then Exit;
  // Solo la franja de cabecera del grafico (debajo de la banda KPI).
  if (Y < CH_KPI_H) or (Y >= CH_KPI_H + CH_MARGIN_TOP) then Exit;

  if X < CH_MARGIN_LEFT then NuevaCol := 0   // "Operario" -> por nombre
                        else NuevaCol := 1;  // eje -> por % ocupacion

  if NuevaCol = FSortCargaCol then
    FSortCargaDesc := not FSortCargaDesc
  else
  begin
    FSortCargaCol := NuevaCol;
    FSortCargaDesc := (NuevaCol = 1);   // por defecto valor descendente
  end;

  OrdenarStats(FStatsCarga, FSortCargaCol, FSortCargaDesc, False);
  pbCarga.Invalidate;
end;

procedure TfrmHistogramasOperarios.pbCosteMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NuevaCol: Integer;
begin
  if Button <> mbLeft then Exit;
  if Length(FStatsCoste) = 0 then Exit;
  if (Y < CH_KPI_H) or (Y >= CH_KPI_H + CH_MARGIN_TOP) then Exit;

  if X < CH_MARGIN_LEFT then NuevaCol := 0   // "Operario" -> por nombre
                        else NuevaCol := 1;  // eje -> por coste

  if NuevaCol = FSortCosteCol then
    FSortCosteDesc := not FSortCosteDesc
  else
  begin
    FSortCosteCol := NuevaCol;
    FSortCosteDesc := (NuevaCol = 1);
  end;

  OrdenarStats(FStatsCoste, FSortCosteCol, FSortCosteDesc, True);
  pbCoste.Invalidate;
end;

procedure TfrmHistogramasOperarios.pbCargaPaint(Sender: TObject);
begin
  DibujarCarga(pbCarga.Canvas, pbCarga.Width, pbCarga.Height);
end;

procedure TfrmHistogramasOperarios.DibujarCarga(C: TCanvas; AWidth, AHeight: Integer);
var
  I, RowTop, ChartX0, ChartX1, AreaW, BarTop, BarBottom: Integer;
  Op: TOpStat;
  Lbl, PctLbl, HoursLbl: string;
  R: TRect;
  Pct100Px, BarEndPx, TX: Integer;
  BaseColor, HighColor: TColor;
  Tick: Integer;
  TickPct: array[0..3] of Integer;
  PctValue, PctClamp: Double;
  PrevOrg: TPoint;
begin
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  R := Rect(0, 0, AWidth, AHeight);
  C.FillRect(R);

  // Banda de KPIs del equipo (franja superior).
  DibujarBandaKPI(C, AWidth, 0, CH_KPI_H);

  if Length(FStatsCarga) = 0 then
  begin
    C.Font.Size := 11;
    C.Font.Style := [];
    C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := Rect(0, CH_KPI_H, AWidth, AHeight);
    DrawText(C.Handle, 'Sin datos para mostrar.', -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;
    Exit;
  end;

  // Desplazar el origen para que el grafico se pinte debajo de la banda KPI
  // sin tocar todos los offsets. Se preserva el origen previo (el scrollbox
  // puede tenerlo desplazado) y se restaura al final.
  GetWindowOrgEx(C.Handle, PrevOrg);
  SetWindowOrgEx(C.Handle, PrevOrg.X, PrevOrg.Y - CH_KPI_H, nil);

  ChartX0 := CH_MARGIN_LEFT;
  ChartX1 := AWidth - CH_MARGIN_RIGHT;
  AreaW := ChartX1 - ChartX0;
  if AreaW < 100 then begin SetWindowOrgEx(C.Handle, PrevOrg.X, PrevOrg.Y, nil); Exit; end;
  Pct100Px := ChartX0 + Round(AreaW * 100 / CH_SCALE_MAX_PCT);

  // -------- Header: banda + titulo + eje % --------
  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, AWidth, CH_MARGIN_TOP));

  C.Font.Size := 10;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, 6, ChartX0 - 8, 28);
  Lbl := 'Operario';
  if FSortCargaCol = 0 then
    if FSortCargaDesc then Lbl := Lbl + '  ' + #$25BC else Lbl := Lbl + '  ' + #$25B2;
  DrawText(C.Handle, PChar(Lbl), -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  R := Rect(ChartX0, 6, ChartX1, 28);
  Lbl := '% Ocupacion (escala 0-130%)';
  if FSortCargaCol = 1 then
    if FSortCargaDesc then Lbl := Lbl + '  ' + #$25BC else Lbl := Lbl + '  ' + #$25B2;
  DrawText(C.Handle, PChar(Lbl), -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  TickPct[0] := 0;  TickPct[1] := 50;  TickPct[2] := 100;  TickPct[3] := CH_SCALE_MAX_PCT;
  C.Font.Size := 8;
  C.Font.Style := [];
  C.Font.Color := CLR_TXT_MUTED;
  for Tick := 0 to High(TickPct) do
  begin
    TX := ChartX0 + Round(AreaW * TickPct[Tick] / CH_SCALE_MAX_PCT);
    R := Rect(TX - 30, 30, TX + 30, CH_MARGIN_TOP - 2);
    DrawText(C.Handle, PChar(IntToStr(TickPct[Tick]) + '%'), -1, R,
      DT_CENTER or DT_TOP or DT_SINGLELINE);
  end;

  C.Pen.Color := CLR_ROW_DIV;
  C.Pen.Style := psSolid;
  C.MoveTo(0, CH_MARGIN_TOP);
  C.LineTo(AWidth, CH_MARGIN_TOP);

  // -------- Filas --------
  C.Brush.Style := bsSolid;
  for I := 0 to High(FStatsCarga) do
  begin
    Op := FStatsCarga[I];
    RowTop := CH_MARGIN_TOP + I * CH_ROW_HEIGHT;

    if Odd(I) then
    begin
      C.Brush.Color := CLR_ZEBRA;
      C.FillRect(Rect(0, RowTop, AWidth, RowTop + CH_ROW_HEIGHT));
    end;

    C.Pen.Color := CLR_ROW_DIV;
    C.MoveTo(ChartX0, RowTop + CH_ROW_HEIGHT - 1);
    C.LineTo(ChartX1, RowTop + CH_ROW_HEIGHT - 1);

    Lbl := Op.Nombre;
    if Trim(Lbl) = '' then Lbl := 'Operario #' + IntToStr(Op.Id);
    R := Rect(16, RowTop + 4, CH_MARGIN_LEFT - 8, RowTop + CH_ROW_HEIGHT div 2 + 4);
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_TXT_PRIMARY;
    C.Brush.Style := bsClear;
    DrawText(C.Handle, PChar(Lbl), -1, R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);

    // Sub-etiqueta hores bajo el nombre
    if Op.CapacidadHoras > 0 then
    begin
      HoursLbl := Format('%.1f h / %.0f h disp.',
        [Op.HorasAsignadas, Op.CapacidadHoras]);
      C.Font.Size := 8;
      C.Font.Style := [];
      C.Font.Color := CLR_TXT_MUTED;
      R := Rect(16, RowTop + CH_ROW_HEIGHT div 2 + 2,
                CH_MARGIN_LEFT - 8, RowTop + CH_ROW_HEIGHT - 2);
      DrawText(C.Handle, PChar(HoursLbl), -1, R,
        DT_LEFT or DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS);
    end;

    BarTop := RowTop + (CH_ROW_HEIGHT - CH_BAR_HEIGHT) div 2;
    BarBottom := BarTop + CH_BAR_HEIGHT;

    // ----- Zonas cualitativas de fondo (estilo bullet chart) -----
    // Banda de referencia detras de la barra: 0-75% claro, 75-100% medio,
    // >100% mas oscuro. Da contexto visual sin necesidad de leer numeros.
    begin
      var Z75: Integer := ChartX0 + Round(AreaW * 75 / CH_SCALE_MAX_PCT);
      var ZBandTop: Integer := BarTop - 3;
      var ZBandBot: Integer := BarBottom + 3;
      C.Brush.Style := bsSolid;
      C.Brush.Color := $00F0F0F0;   // 0-75% gris claro
      C.FillRect(Rect(ChartX0, ZBandTop, Z75, ZBandBot));
      C.Brush.Color := $00E2E2E2;   // 75-100% gris medio
      C.FillRect(Rect(Z75, ZBandTop, Pct100Px, ZBandBot));
      C.Brush.Color := $00D2D2D2;   // >100% gris mas oscuro (zona de riesgo)
      C.FillRect(Rect(Pct100Px, ZBandTop, ChartX1, ZBandBot));
    end;

    // Ticks verticales (50% suave, 100% mas marcada)
    C.Pen.Color := CLR_AXIS_FAINT;
    C.Pen.Style := psSolid;
    TX := ChartX0 + Round(AreaW * 50 / CH_SCALE_MAX_PCT);
    C.MoveTo(TX, RowTop + 4);
    C.LineTo(TX, RowTop + CH_ROW_HEIGHT - 4);
    C.Pen.Color := CLR_AXIS_100;
    C.MoveTo(Pct100Px, RowTop + 4);
    C.LineTo(Pct100Px, RowTop + CH_ROW_HEIGHT - 4);

    // Sin capacidad
    if Op.CapacidadHoras <= 0 then
    begin
      C.Font.Size := 9;
      C.Font.Style := [fsItalic];
      C.Font.Color := CLR_TXT_MUTED;
      C.Brush.Style := bsClear;
      R := Rect(ChartX0, RowTop, ChartX1, RowTop + CH_ROW_HEIGHT);
      DrawText(C.Handle, 'Sin calendario asignado', -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
      Continue;
    end;

    // Sin carga: barra placeholder muy fina + etiqueta "0%"
    if Op.HorasAsignadas <= 0 then
    begin
      C.Brush.Color := CLR_EMPTY_BAR;
      C.Pen.Color := CLR_EMPTY_BAR;
      C.RoundRect(ChartX0, BarTop, ChartX0 + 6, BarBottom,
        CH_BAR_RADIUS, CH_BAR_RADIUS);
      C.Font.Size := 9;
      C.Font.Style := [fsItalic];
      C.Font.Color := CLR_TXT_MUTED;
      C.Brush.Style := bsClear;
      R := Rect(ChartX0 + 14, BarTop, ChartX0 + 200, BarBottom);
      DrawText(C.Handle, 'Sin carga asignada', -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
      Continue;
    end;

    PctValue := Op.PctOcupacion;
    PctClamp := PctValue;
    if PctClamp > CH_SCALE_MAX_PCT then PctClamp := CH_SCALE_MAX_PCT;

    if PctValue <= 50 then
      begin BaseColor := CLR_LO_BASE;  HighColor := CLR_LO_HIGH;  end
    else if PctValue <= 75 then
      begin BaseColor := CLR_MD_BASE;  HighColor := CLR_MD_HIGH;  end
    else if PctValue <= 90 then
      begin BaseColor := CLR_HI_BASE;  HighColor := CLR_HI_HIGH;  end
    else
      begin BaseColor := CLR_TOP_BASE; HighColor := CLR_TOP_HIGH; end;

    // Barra de medida (bullet): mas fina que la banda de fondo, centrada.
    var BulTop: Integer := BarTop + 5;
    var BulBot: Integer := BarBottom - 5;
    if PctValue <= 100 then
    begin
      BarEndPx := ChartX0 + Round(AreaW * PctClamp / CH_SCALE_MAX_PCT);
      if BarEndPx > ChartX0 then
        DrawRoundedBar(C, Rect(ChartX0, BulTop, BarEndPx, BulBot),
          BaseColor, HighColor, CH_BAR_RADIUS);
    end
    else
    begin
      DrawRoundedBar(C, Rect(ChartX0, BulTop, Pct100Px, BulBot),
        CLR_TOP_BASE, CLR_TOP_HIGH, CH_BAR_RADIUS);
      BarEndPx := ChartX0 + Round(AreaW * PctClamp / CH_SCALE_MAX_PCT);
      if BarEndPx > Pct100Px then
        DrawRoundedBar(C, Rect(Pct100Px, BulTop, BarEndPx, BulBot),
          CLR_OVER_BASE, CLR_OVER_HIGH, CH_BAR_RADIUS);
    end;

    // Marca de la media del equipo (tick vertical negro estilo bullet).
    if FKPI.OcupacionMedia >= 0 then
    begin
      var Mx: Double := FKPI.OcupacionMedia;
      if Mx > CH_SCALE_MAX_PCT then Mx := CH_SCALE_MAX_PCT;
      var MxPx: Integer := ChartX0 + Round(AreaW * Mx / CH_SCALE_MAX_PCT);
      C.Pen.Color := $00303030;
      C.Pen.Width := 2;
      C.MoveTo(MxPx, BarTop - 1);
      C.LineTo(MxPx, BarBottom + 1);
      C.Pen.Width := 1;
    end;

    // Etiqueta % grande
    PctLbl := Format('%.0f%%', [PctValue]);
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Brush.Style := bsClear;
    if (BarEndPx - ChartX0) > 50 then
    begin
      C.Font.Color := CLR_TXT_ON_BAR;
      R := Rect(ChartX0 + 8, BarTop, BarEndPx - 6, BarBottom);
      DrawText(C.Handle, PChar(PctLbl), -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end
    else
    begin
      C.Font.Color := CLR_TXT_PRIMARY;
      R := Rect(BarEndPx + 8, BarTop, BarEndPx + 80, BarBottom);
      DrawText(C.Handle, PChar(PctLbl), -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end;
  end;

  // Etiqueta "media" en la cabecera, alineada con los ticks bullet por fila.
  if FKPI.OcupacionMedia >= 0 then
  begin
    var MediaClamp: Double := FKPI.OcupacionMedia;
    if MediaClamp > CH_SCALE_MAX_PCT then MediaClamp := CH_SCALE_MAX_PCT;
    var MediaX: Integer := ChartX0 + Round(AreaW * MediaClamp / CH_SCALE_MAX_PCT);
    C.Font.Size := 8;
    C.Font.Style := [fsBold];
    C.Font.Color := $00303030;
    C.Brush.Style := bsClear;
    R := Rect(MediaX - 60, CH_MARGIN_TOP - 16, MediaX + 60, CH_MARGIN_TOP - 2);
    DrawText(C.Handle, PChar(Format('| media %.0f%%', [FKPI.OcupacionMedia])),
      -1, R, DT_CENTER or DT_BOTTOM or DT_SINGLELINE);
  end;

  SetWindowOrgEx(C.Handle, PrevOrg.X, PrevOrg.Y, nil);   // restaurar origen
end;

procedure TfrmHistogramasOperarios.pbDistribPaint(Sender: TObject);
begin
  DibujarDistrib(pbDistrib.Canvas, pbDistrib.Width, pbDistrib.Height);
end;

procedure TfrmHistogramasOperarios.DibujarDistrib(C: TCanvas; AWidth, AHeight: Integer);
const
  RangeLabels: array[0..4] of string =
    ('0-25%', '25-50%', '50-75%', '75-100%', '>100%');
var
  RangeBase: array[0..4] of TColor;
  RangeHigh: array[0..4] of TColor;
  I, MaxV, X, BarTop, BarBottom, ChartTop, ChartBottom, Pix, YGrid: Integer;
  R: TRect;
  Lbl: string;
  Total: Integer;
  // Box plot (banda superior)
  BpVals: TArray<Double>;
  BpN, BpX0, BpX1: Integer;
  function BpQuant(P: Double): Double;
  var Pos, Frac: Double; Lo: Integer;
  begin
    if BpN = 1 then Exit(BpVals[0]);
    Pos := P * (BpN - 1); Lo := Trunc(Pos); Frac := Pos - Lo;
    if Lo + 1 <= BpN - 1 then Result := BpVals[Lo] + Frac * (BpVals[Lo+1] - BpVals[Lo])
                         else Result := BpVals[BpN-1];
  end;
  function BpFnX(V: Double): Integer;
  begin
    if V < 0 then V := 0; if V > 150 then V := 150;
    Result := BpX0 + Round((V / 150.0) * (BpX1 - BpX0));
  end;
begin
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  R := Rect(0, 0, AWidth, AHeight);
  C.FillRect(R);

  // Misma paleta que el tab Carga
  RangeBase[0] := CLR_LO_BASE;   RangeHigh[0] := CLR_LO_HIGH;
  RangeBase[1] := CLR_LO_BASE;   RangeHigh[1] := CLR_LO_HIGH;
  RangeBase[2] := CLR_MD_BASE;   RangeHigh[2] := CLR_MD_HIGH;
  RangeBase[3] := CLR_HI_BASE;   RangeHigh[3] := CLR_HI_HIGH;
  RangeBase[4] := CLR_OVER_BASE; RangeHigh[4] := CLR_OVER_HIGH;

  MaxV := 1;
  Total := 0;
  for I := 0 to High(FDistrib) do
  begin
    if FDistrib[I] > MaxV then MaxV := FDistrib[I];
    Inc(Total, FDistrib[I]);
  end;

  // Banda de header
  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, AWidth, CHD_MARGIN_TOP));

  C.Font.Size := 11;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, 8, AWidth - CHD_MARGIN_RIGHT,
            CHD_MARGIN_TOP - 4);
  DrawText(C.Handle,
    PChar(Format('Distribucion: %d operario(s) por rango de ocupacion',
                 [Total])),
    -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  C.Pen.Color := CLR_ROW_DIV;
  C.Pen.Style := psSolid;
  C.MoveTo(0, CHD_MARGIN_TOP);
  C.LineTo(AWidth, CHD_MARGIN_TOP);

  // ----- Box plot de la ocupacion del equipo (banda superior) -----
  // Resume mediana, cuartiles (Q1-Q3), min/max (bigotes) y outliers en una
  // sola figura, mas preciso que las 5 barras de rangos de debajo.
  SetLength(BpVals, 0);
  for I := 0 to High(FStatsCarga) do
    if FStatsCarga[I].PctOcupacion >= 0 then
      BpVals := BpVals + [FStatsCarga[I].PctOcupacion];
  BpN := Length(BpVals);
  BpX0 := CHD_MARGIN_LEFT;
  BpX1 := AWidth - CHD_MARGIN_RIGHT;
  if BpN >= 1 then
  begin
    // Ordenar ascendente (insertion sort, pocos elementos).
    for var A := 1 to BpN - 1 do
    begin
      var Key: Double := BpVals[A]; var B: Integer := A - 1;
      while (B >= 0) and (BpVals[B] > Key) do begin BpVals[B+1] := BpVals[B]; Dec(B); end;
      BpVals[B+1] := Key;
    end;
    var Q1: Double := BpQuant(0.25);
    var Q2: Double := BpQuant(0.50);
    var Q3: Double := BpQuant(0.75);
    var IQR: Double := Q3 - Q1;
    var LoW: Double := Q1 - 1.5 * IQR;
    var HiW: Double := Q3 + 1.5 * IQR;
    var WMin: Double := BpVals[0]; var WMax: Double := BpVals[BpN-1];
    for var K := 0 to BpN - 1 do
    begin
      if (BpVals[K] >= LoW) and (WMin < LoW) then WMin := BpVals[K];
      if BpVals[K] <= HiW then WMax := BpVals[K];
    end;
    if WMin < LoW then WMin := LoW;

    var BpY: Integer := CHD_MARGIN_TOP + 34;
    var BpH: Integer := 22;

    C.Font.Size := 8; C.Font.Style := []; C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := Rect(0, BpY - BpH - 2, BpX0 - 6, BpY + BpH + 2);
    DrawText(C.Handle, 'Reparto', -1, R, DT_RIGHT or DT_VCENTER or DT_SINGLELINE);

    // Bigotes
    C.Pen.Color := CLR_TXT_PRIMARY; C.Pen.Width := 1; C.Pen.Style := psSolid;
    C.MoveTo(BpFnX(WMin), BpY); C.LineTo(BpFnX(Q1), BpY);
    C.MoveTo(BpFnX(Q3), BpY); C.LineTo(BpFnX(WMax), BpY);
    C.MoveTo(BpFnX(WMin), BpY - 8); C.LineTo(BpFnX(WMin), BpY + 8);
    C.MoveTo(BpFnX(WMax), BpY - 8); C.LineTo(BpFnX(WMax), BpY + 8);
    // Caja Q1..Q3
    C.Brush.Style := bsSolid; C.Brush.Color := $00E8F0E8;
    C.Pen.Color := CLR_LO_BASE;
    C.Rectangle(BpFnX(Q1), BpY - BpH, BpFnX(Q3), BpY + BpH);
    // Mediana
    C.Pen.Color := CLR_TOP_BASE; C.Pen.Width := 3;
    C.MoveTo(BpFnX(Q2), BpY - BpH); C.LineTo(BpFnX(Q2), BpY + BpH);
    C.Pen.Width := 1;
    // Linea del 100%
    C.Pen.Color := CLR_AXIS_100; C.Pen.Style := psDot;
    C.MoveTo(BpFnX(100), BpY - BpH - 6); C.LineTo(BpFnX(100), BpY + BpH + 6);
    C.Pen.Style := psSolid;
    // Outliers
    C.Brush.Color := CLR_OVER_BASE; C.Pen.Color := CLR_OVER_BASE;
    for var K := 0 to BpN - 1 do
      if (BpVals[K] < LoW) or (BpVals[K] > HiW) then
        C.Ellipse(BpFnX(BpVals[K]) - 3, BpY - 3, BpFnX(BpVals[K]) + 3, BpY + 3);
    // Etiqueta mediana
    C.Font.Size := 7; C.Font.Style := [fsBold]; C.Font.Color := CLR_TXT_PRIMARY;
    C.Brush.Style := bsClear;
    R := Rect(BpFnX(Q2) - 30, BpY - BpH - 16, BpFnX(Q2) + 30, BpY - BpH - 2);
    DrawText(C.Handle, PChar(Format('mediana %.0f%%', [Q2])), -1, R,
      DT_CENTER or DT_BOTTOM or DT_SINGLELINE);
  end;

  ChartTop := CHD_MARGIN_TOP + 90;   // dejar sitio al box plot arriba
  ChartBottom := AHeight - CHD_MARGIN_BOTTOM;

  // Eje Y (grid muy suau)
  C.Pen.Color := CLR_AXIS_FAINT;
  C.Pen.Style := psSolid;
  for I := 0 to MaxV do
  begin
    YGrid := ChartBottom - Round((I / MaxV) * (ChartBottom - ChartTop));
    C.MoveTo(CHD_MARGIN_LEFT, YGrid);
    C.LineTo(AWidth - CHD_MARGIN_RIGHT, YGrid);
    C.Font.Size := 8;
    C.Font.Style := [];
    C.Font.Color := CLR_TXT_MUTED;
    R := Rect(0, YGrid - 8, CHD_MARGIN_LEFT - 8, YGrid + 8);
    DrawText(C.Handle, PChar(IntToStr(I)), -1, R,
      DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  end;

  // Barras
  for I := 0 to High(FDistrib) do
  begin
    X := CHD_MARGIN_LEFT + I * (CHD_BAR_WIDTH + CHD_BAR_GAP);
    Pix := Round((FDistrib[I] / MaxV) * (ChartBottom - ChartTop));
    BarBottom := ChartBottom;
    BarTop := BarBottom - Pix;

    // Barra arrodonida con gradient (solo si tiene altura)
    if Pix > 0 then
      DrawRoundedBar(C, Rect(X, BarTop, X + CHD_BAR_WIDTH, BarBottom),
        RangeBase[I], RangeHigh[I], CHD_BAR_RADIUS)
    else
    begin
      // Placeholder cuando el rango esta vacio
      C.Brush.Color := CLR_EMPTY_BAR;
      C.Pen.Color := CLR_EMPTY_BAR;
      C.RoundRect(X, BarBottom - 6, X + CHD_BAR_WIDTH, BarBottom,
        CHD_BAR_RADIUS, CHD_BAR_RADIUS);
    end;

    // Valor grande encima
    Lbl := IntToStr(FDistrib[I]);
    C.Font.Size := 14;
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_TXT_PRIMARY;
    C.Brush.Style := bsClear;
    R := Rect(X, BarTop - 32, X + CHD_BAR_WIDTH, BarTop - 4);
    DrawText(C.Handle, PChar(Lbl), -1, R,
      DT_CENTER or DT_BOTTOM or DT_SINGLELINE);

    // Etiqueta de rango bajo el eje
    R := Rect(X, BarBottom + 10, X + CHD_BAR_WIDTH, BarBottom + 32);
    C.Font.Size := 9;
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_TXT_PRIMARY;
    DrawText(C.Handle, PChar(RangeLabels[I]), -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);

    // % del total
    if Total > 0 then
    begin
      R := Rect(X, BarBottom + 30, X + CHD_BAR_WIDTH, BarBottom + 50);
      C.Font.Size := 8;
      C.Font.Style := [];
      C.Font.Color := CLR_TXT_MUTED;
      DrawText(C.Handle,
        PChar(Format('%.0f%% del equipo', [FDistrib[I] * 100.0 / Total])),
        -1, R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    end;
    C.Brush.Style := bsSolid;
  end;

  // Linea base
  C.Pen.Color := CLR_AXIS_100;
  C.MoveTo(CHD_MARGIN_LEFT, ChartBottom);
  C.LineTo(AWidth - CHD_MARGIN_RIGHT, ChartBottom);
end;

procedure TfrmHistogramasOperarios.pbCostePaint(Sender: TObject);
begin
  DibujarCoste(pbCoste.Canvas, pbCoste.Width, pbCoste.Height);
end;

procedure TfrmHistogramasOperarios.DibujarCoste(C: TCanvas; AWidth, AHeight: Integer);
var
  I, RowTop, ChartX0, ChartX1, AreaW, BarTop, BarBottom, BarEndPx: Integer;
  MaxCost, TotalCost: Double;
  Op: TOpStat;
  Lbl, CostLbl, DetailLbl: string;
  R: TRect;
  PrevOrg: TPoint;
begin
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  R := Rect(0, 0, AWidth, AHeight);
  C.FillRect(R);

  // Banda de KPIs del equipo (franja superior).
  DibujarBandaKPI(C, AWidth, 0, CH_KPI_H);

  if Length(FStatsCoste) = 0 then
  begin
    C.Font.Size := 11;
    C.Font.Style := [];
    C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := Rect(0, CH_KPI_H, AWidth, AHeight);
    DrawText(C.Handle, 'Sin datos para mostrar.', -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    Exit;
  end;

  GetWindowOrgEx(C.Handle, PrevOrg);
  SetWindowOrgEx(C.Handle, PrevOrg.X, PrevOrg.Y - CH_KPI_H, nil);

  ChartX0 := CH_MARGIN_LEFT;
  ChartX1 := AWidth - CH_MARGIN_RIGHT;
  AreaW := ChartX1 - ChartX0;
  if AreaW < 100 then begin SetWindowOrgEx(C.Handle, PrevOrg.X, PrevOrg.Y, nil); Exit; end;

  MaxCost := 0;
  TotalCost := 0;
  for I := 0 to High(FStatsCoste) do
  begin
    if FStatsCoste[I].Coste > MaxCost then MaxCost := FStatsCoste[I].Coste;
    TotalCost := TotalCost + FStatsCoste[I].Coste;
  end;
  if MaxCost < 1 then MaxCost := 1;

  // Header con banda y total
  C.Brush.Color := CLR_HEADER_BG;
  C.FillRect(Rect(0, 0, AWidth, CH_MARGIN_TOP));

  C.Font.Size := 10;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, 6, ChartX0 - 8, 28);
  Lbl := 'Operario';
  if FSortCosteCol = 0 then
    if FSortCosteDesc then Lbl := Lbl + '  ' + #$25BC else Lbl := Lbl + '  ' + #$25B2;
  DrawText(C.Handle, PChar(Lbl), -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  R := Rect(ChartX0, 6, ChartX1, 28);
  Lbl := Format('Coste laboral - Total equipo: %.0f EUR', [TotalCost]);
  if FSortCosteCol = 1 then
    if FSortCosteDesc then Lbl := Lbl + '  ' + #$25BC else Lbl := Lbl + '  ' + #$25B2;
  DrawText(C.Handle, PChar(Lbl), -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  C.Font.Size := 8;
  C.Font.Style := [];
  C.Font.Color := CLR_TXT_MUTED;
  R := Rect(ChartX0, 30, ChartX1, CH_MARGIN_TOP - 2);
  DrawText(C.Handle,
    PChar(Format('Escala: 0 - %.0f EUR (maximo del equipo)', [MaxCost])),
    -1, R, DT_LEFT or DT_TOP or DT_SINGLELINE);

  C.Pen.Color := CLR_ROW_DIV;
  C.Pen.Style := psSolid;
  C.MoveTo(0, CH_MARGIN_TOP);
  C.LineTo(AWidth, CH_MARGIN_TOP);

  // Filas
  for I := 0 to High(FStatsCoste) do
  begin
    Op := FStatsCoste[I];
    RowTop := CH_MARGIN_TOP + I * CH_ROW_HEIGHT;

    if Odd(I) then
    begin
      C.Brush.Color := CLR_ZEBRA;
      C.FillRect(Rect(0, RowTop, AWidth, RowTop + CH_ROW_HEIGHT));
    end;

    C.Pen.Color := CLR_ROW_DIV;
    C.MoveTo(ChartX0, RowTop + CH_ROW_HEIGHT - 1);
    C.LineTo(ChartX1, RowTop + CH_ROW_HEIGHT - 1);

    Lbl := Op.Nombre;
    if Trim(Lbl) = '' then Lbl := 'Operario #' + IntToStr(Op.Id);
    R := Rect(16, RowTop + 4, CH_MARGIN_LEFT - 8, RowTop + CH_ROW_HEIGHT div 2 + 4);
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_TXT_PRIMARY;
    C.Brush.Style := bsClear;
    DrawText(C.Handle, PChar(Lbl), -1, R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);

    // Subtitulo: tarifa hora
    if Op.SueldoEurHora > 0 then
    begin
      C.Font.Size := 8;
      C.Font.Style := [];
      C.Font.Color := CLR_TXT_MUTED;
      R := Rect(16, RowTop + CH_ROW_HEIGHT div 2 + 2,
                CH_MARGIN_LEFT - 8, RowTop + CH_ROW_HEIGHT - 2);
      DrawText(C.Handle,
        PChar(Format('%.2f EUR/h x %.1f h', [Op.SueldoEurHora, Op.HorasAsignadas])),
        -1, R, DT_LEFT or DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS);
    end;

    BarTop := RowTop + (CH_ROW_HEIGHT - CH_BAR_HEIGHT) div 2;
    BarBottom := BarTop + CH_BAR_HEIGHT;

    if Op.Coste <= 0 then
    begin
      C.Brush.Color := CLR_EMPTY_BAR;
      C.Pen.Color := CLR_EMPTY_BAR;
      C.RoundRect(ChartX0, BarTop, ChartX0 + 6, BarBottom,
        CH_BAR_RADIUS, CH_BAR_RADIUS);
      C.Font.Size := 9;
      C.Font.Style := [fsItalic];
      C.Font.Color := CLR_TXT_MUTED;
      C.Brush.Style := bsClear;
      R := Rect(ChartX0 + 14, BarTop, ChartX1, BarBottom);
      if Op.SueldoEurHora <= 0 then
        DrawText(C.Handle, 'Sin sueldo definido en su ficha', -1, R,
          DT_LEFT or DT_VCENTER or DT_SINGLELINE)
      else
        DrawText(C.Handle, 'Sin horas asignadas en el periodo', -1, R,
          DT_LEFT or DT_VCENTER or DT_SINGLELINE);
      Continue;
    end;

    BarEndPx := ChartX0 + Round((Op.Coste / MaxCost) * AreaW);
    if BarEndPx > ChartX0 then
      DrawRoundedBar(C, Rect(ChartX0, BarTop, BarEndPx, BarBottom),
        CLR_COST_BASE, CLR_COST_HIGH, CH_BAR_RADIUS);

    // Etiqueta cost (dentro de la barra si cabe)
    CostLbl := Format('%.0f EUR', [Op.Coste]);
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Brush.Style := bsClear;
    if (BarEndPx - ChartX0) > 80 then
    begin
      C.Font.Color := CLR_TXT_ON_BAR;
      R := Rect(ChartX0 + 8, BarTop, BarEndPx - 6, BarBottom);
      DrawText(C.Handle, PChar(CostLbl), -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end
    else
    begin
      C.Font.Color := CLR_TXT_PRIMARY;
      R := Rect(BarEndPx + 8, BarTop, BarEndPx + 200, BarBottom);
      DrawText(C.Handle, PChar(CostLbl), -1, R,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end;

    // % del total a la derecha
    if TotalCost > 0 then
    begin
      DetailLbl := Format('%.1f%% del total', [Op.Coste * 100.0 / TotalCost]);
      C.Font.Size := 8;
      C.Font.Style := [];
      C.Font.Color := CLR_TXT_MUTED;
      R := Rect(ChartX1 - 120, BarTop, ChartX1 - 4, BarBottom);
      DrawText(C.Handle, PChar(DetailLbl), -1, R,
        DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
    end;
  end;

  // -------- Linea de coste medio del equipo (vertical, discontinua) --------
  if Length(FStatsCoste) > 0 then
  begin
    var MediaCoste: Double := TotalCost / Length(FStatsCoste);
    var MediaX: Integer := ChartX0 + Round((MediaCoste / MaxCost) * AreaW);
    var YBot: Integer := CH_MARGIN_TOP + Length(FStatsCoste) * CH_ROW_HEIGHT;
    C.Pen.Color := $003C3C3C;
    C.Pen.Style := psDot;
    C.MoveTo(MediaX, CH_MARGIN_TOP);
    C.LineTo(MediaX, YBot);
    C.Pen.Style := psSolid;
    C.Font.Size := 8;
    C.Font.Style := [fsBold];
    C.Font.Color := $003C3C3C;
    C.Brush.Style := bsClear;
    R := Rect(MediaX - 70, CH_MARGIN_TOP - 16, MediaX + 70, CH_MARGIN_TOP - 2);
    DrawText(C.Handle, PChar(Format('media %.0f EUR', [MediaCoste])),
      -1, R, DT_CENTER or DT_BOTTOM or DT_SINGLELINE);
  end;

  SetWindowOrgEx(C.Handle, PrevOrg.X, PrevOrg.Y, nil);   // restaurar origen
end;

procedure TfrmHistogramasOperarios.DibujarBandaKPI(C: TCanvas;
  AWidth, AY, AHeight: Integer);
// Franja horizontal de tiles con los KPIs del equipo. AY = top, AHeight = alto.
var
  Tiles: array of record
    Titulo: string;
    Valor: string;
    Color: TColor;
  end;
  I, TileW, X: Integer;
  R: TRect;
begin
  // Fondo de la banda
  C.Brush.Style := bsSolid;
  C.Brush.Color := $00F4EFE7;   // beige suave, coherente con headers
  C.FillRect(Rect(0, AY, AWidth, AY + AHeight));
  C.Pen.Color := CLR_ROW_DIV;
  C.Pen.Style := psSolid;
  C.MoveTo(0, AY + AHeight - 1);
  C.LineTo(AWidth, AY + AHeight - 1);

  SetLength(Tiles, 5);
  Tiles[0].Titulo := 'Operarios';
  Tiles[0].Valor  := IntToStr(FKPI.NumOperarios);
  Tiles[0].Color  := CLR_TXT_PRIMARY;

  Tiles[1].Titulo := 'Ocupaci'#243'n media';
  if FKPI.OcupacionMedia >= 0 then
    Tiles[1].Valor := Format('%.0f%%', [FKPI.OcupacionMedia])
  else
    Tiles[1].Valor := '---';
  if FKPI.OcupacionMedia > 100 then Tiles[1].Color := CLR_OVER_BASE
  else if FKPI.OcupacionMedia >= 85 then Tiles[1].Color := CLR_TOP_BASE
  else Tiles[1].Color := CLR_LO_BASE;

  Tiles[2].Titulo := 'Sobrecargados';
  Tiles[2].Valor  := IntToStr(FKPI.NumSobrecarga);
  if FKPI.NumSobrecarga > 0 then Tiles[2].Color := CLR_OVER_BASE
                            else Tiles[2].Color := CLR_LO_BASE;

  Tiles[3].Titulo := 'Capacidad ociosa';
  Tiles[3].Valor  := Format('%.0f h', [FKPI.HorasOciosas]);
  Tiles[3].Color  := CLR_MD_BASE;

  Tiles[4].Titulo := 'Coste total';
  Tiles[4].Valor  := Format('%.0f EUR', [FKPI.CosteTotal]);
  Tiles[4].Color  := CLR_COST_BASE;

  TileW := (AWidth - 32) div Length(Tiles);
  for I := 0 to High(Tiles) do
  begin
    X := 16 + I * TileW;
    // Separador vertical suave entre tiles
    if I > 0 then
    begin
      C.Pen.Color := CLR_ROW_DIV;
      C.MoveTo(X, AY + 12);
      C.LineTo(X, AY + AHeight - 12);
    end;

    // Valor grande
    C.Brush.Style := bsClear;
    C.Font.Name := 'Segoe UI';
    C.Font.Size := 18;
    C.Font.Style := [fsBold];
    C.Font.Color := Tiles[I].Color;
    R := Rect(X + 12, AY + 10, X + TileW - 8, AY + 44);
    DrawText(C.Handle, PChar(Tiles[I].Valor), -1, R,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE);

    // Titulo pequeno debajo
    C.Font.Size := 9;
    C.Font.Style := [];
    C.Font.Color := CLR_TXT_MUTED;
    R := Rect(X + 12, AY + 46, X + TileW - 8, AY + AHeight - 6);
    DrawText(C.Handle, PChar(Tiles[I].Titulo), -1, R,
      DT_LEFT or DT_TOP or DT_SINGLELINE);
  end;
end;

procedure TfrmHistogramasOperarios.pbComparativaPaint(Sender: TObject);
begin
  DibujarComparativa(pbComparativa.Canvas, pbComparativa.Width, pbComparativa.Height);
end;

procedure TfrmHistogramasOperarios.DibujarComparativa(C: TCanvas;
  AWidth, AHeight: Integer);
// Dos barras verticales grandes: capacidad total del equipo vs horas
// planificadas, con el excedente / margen destacado y el % de ocupacion.
var
  R: TRect;
  CX, BaseY, TopY, MaxH, BarW, Gap, Gx1, Gx2: Integer;
  MaxVal, EscY: Double;
  PctGlobal: Double;
  function PixDe(AHoras: Double): Integer;
  begin
    if MaxVal <= 0 then Exit(0);
    Result := Round((AHoras / MaxVal) * (BaseY - TopY));
  end;
begin
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  C.FillRect(Rect(0, 0, AWidth, AHeight));

  DibujarBandaKPI(C, AWidth, 0, CH_KPI_H);

  if (FKPI.NumOperarios = 0) or (FKPI.HorasCapTotal <= 0) then
  begin
    C.Font.Size := 11;
    C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := Rect(0, CH_KPI_H, AWidth, AHeight);
    DrawText(C.Handle, 'Sin datos para mostrar.', -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;
    Exit;
  end;

  // Titulo
  C.Font.Size := 11;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, CH_KPI_H + 10, AWidth - 16, CH_KPI_H + 36);
  DrawText(C.Handle,
    'Plan vs Capacidad del equipo en el periodo', -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  // Geometria de las dos barras (centradas)
  BarW := 150;
  Gap := 120;
  TopY := CH_KPI_H + 70;
  MaxH := AHeight - TopY - 90;
  if MaxH < 80 then MaxH := 80;
  BaseY := TopY + MaxH;
  CX := AWidth div 2;
  Gx1 := CX - Gap div 2 - BarW;   // barra Capacidad (izq)
  Gx2 := CX + Gap div 2;          // barra Plan (der)

  MaxVal := Max(FKPI.HorasCapTotal, FKPI.HorasPlanTotal);
  if MaxVal <= 0 then MaxVal := 1;

  // Grid horizontal + eje Y (horas)
  C.Font.Size := 8;
  C.Font.Style := [];
  C.Font.Color := CLR_TXT_MUTED;
  C.Pen.Style := psSolid;
  for var G := 0 to 4 do
  begin
    EscY := MaxVal * G / 4;
    var Yg: Integer := BaseY - Round((G / 4) * MaxH);
    C.Pen.Color := CLR_AXIS_FAINT;
    C.MoveTo(Gx1 - 40, Yg);
    C.LineTo(Gx2 + BarW + 20, Yg);
    R := Rect(Gx1 - 90, Yg - 8, Gx1 - 44, Yg + 8);
    DrawText(C.Handle, PChar(Format('%.0f h', [EscY])), -1, R,
      DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  end;

  // Barra CAPACIDAD (verde/azul suave)
  var HCap: Integer := PixDe(FKPI.HorasCapTotal);
  DrawRoundedBar(C, Rect(Gx1, BaseY - HCap, Gx1 + BarW, BaseY),
    CLR_MD_BASE, CLR_MD_HIGH, CHD_BAR_RADIUS);

  // Barra PLAN: verde hasta capacidad, rojo apilado por encima.
  var HPlan: Integer := PixDe(FKPI.HorasPlanTotal);
  if FKPI.HorasPlanTotal <= FKPI.HorasCapTotal then
    DrawRoundedBar(C, Rect(Gx2, BaseY - HPlan, Gx2 + BarW, BaseY),
      CLR_LO_BASE, CLR_LO_HIGH, CHD_BAR_RADIUS)
  else
  begin
    var HCapEnPlan: Integer := PixDe(FKPI.HorasCapTotal);
    DrawRoundedBar(C, Rect(Gx2, BaseY - HCapEnPlan, Gx2 + BarW, BaseY),
      CLR_TOP_BASE, CLR_TOP_HIGH, CHD_BAR_RADIUS);
    DrawRoundedBar(C, Rect(Gx2, BaseY - HPlan, Gx2 + BarW, BaseY - HCapEnPlan),
      CLR_OVER_BASE, CLR_OVER_HIGH, CHD_BAR_RADIUS);
  end;

  // Valores encima de cada barra
  C.Font.Size := 13;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_TXT_PRIMARY;
  R := Rect(Gx1 - 20, BaseY - HCap - 26, Gx1 + BarW + 20, BaseY - HCap - 4);
  DrawText(C.Handle, PChar(Format('%.0f h', [FKPI.HorasCapTotal])), -1, R,
    DT_CENTER or DT_BOTTOM or DT_SINGLELINE);
  R := Rect(Gx2 - 20, BaseY - HPlan - 26, Gx2 + BarW + 20, BaseY - HPlan - 4);
  DrawText(C.Handle, PChar(Format('%.0f h', [FKPI.HorasPlanTotal])), -1, R,
    DT_CENTER or DT_BOTTOM or DT_SINGLELINE);

  // Etiquetas bajo cada barra
  C.Font.Size := 10;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_TXT_PRIMARY;
  R := Rect(Gx1 - 20, BaseY + 8, Gx1 + BarW + 20, BaseY + 28);
  DrawText(C.Handle, 'Capacidad', -1, R, DT_CENTER or DT_TOP or DT_SINGLELINE);
  R := Rect(Gx2 - 20, BaseY + 8, Gx2 + BarW + 20, BaseY + 28);
  DrawText(C.Handle, 'Planificado', -1, R, DT_CENTER or DT_TOP or DT_SINGLELINE);

  // Linea base
  C.Pen.Color := CLR_AXIS_100;
  C.MoveTo(Gx1 - 40, BaseY);
  C.LineTo(Gx2 + BarW + 20, BaseY);

  // Resumen textual (margen / exceso) a la derecha
  PctGlobal := FKPI.HorasPlanTotal / FKPI.HorasCapTotal * 100.0;
  C.Font.Size := 11;
  C.Font.Style := [fsBold];
  var Resumen: string;
  var ResColor: TColor;
  if FKPI.HorasPlanTotal <= FKPI.HorasCapTotal then
  begin
    Resumen := Format('Margen: %.0f h libres  (%.0f%% de ocupaci'#243'n)',
      [FKPI.HorasCapTotal - FKPI.HorasPlanTotal, PctGlobal]);
    ResColor := CLR_LO_BASE;
  end
  else
  begin
    Resumen := Format('Exceso: +%.0f h sobre capacidad  (%.0f%% de ocupaci'#243'n)',
      [FKPI.HorasPlanTotal - FKPI.HorasCapTotal, PctGlobal]);
    ResColor := CLR_OVER_BASE;
  end;
  C.Font.Color := ResColor;
  C.Brush.Style := bsClear;
  R := Rect(16, BaseY + 40, AWidth - 16, BaseY + 66);
  DrawText(C.Handle, PChar(Resumen), -1, R,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  C.Brush.Style := bsSolid;
end;

procedure TfrmHistogramasOperarios.DibujarSerieSuave(C: TCanvas;
  const APuntos: TArray<TPoint>; const APcts: TArray<Double>;
  ABaseY, ASplitReal: Integer);
// Pinta una serie temporal con GDI+ (antialiasing): area de relleno bajo la
// curva, linea principal (solida hasta ASplitReal, punteada despues) coloreada
// por tramo segun el % y puntos circulares. Elimina el efecto pixelado de GDI.
var
  G: TGPGraphics;
  Path: TGPGraphicsPath;
  Fill: TGPPathGradientBrush;
  AreaBrush: TGPLinearGradientBrush;
  Pen: TGPPen;
  N, I: Integer;
  function ColorTramo(APct: Double): Cardinal;
  begin
    if APct > 100 then Result := MakeColor(255, $2E, $2E, $B8)   // rojo sobre
    else if APct >= 85 then Result := MakeColor(255, $BF, $6E, $14) // naranja
    else Result := MakeColor(255, $70, $B8, $72);                 // verde
    // Nota: MakeColor es ARGB; los literales van en R,G,B reales.
  end;
begin
  N := Length(APuntos);
  if N < 1 then Exit;

  G := TGPGraphics.Create(C.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);

    // --- Area de relleno bajo la curva (degradado vertical suave) ---
    if N >= 2 then
    begin
      Path := TGPGraphicsPath.Create;
      try
        Path.StartFigure;
        for I := 0 to N - 2 do
          Path.AddLine(APuntos[I].X, APuntos[I].Y,
                       APuntos[I + 1].X, APuntos[I + 1].Y);
        // cerrar hacia la base
        Path.AddLine(APuntos[N - 1].X, APuntos[N - 1].Y, APuntos[N - 1].X, ABaseY);
        Path.AddLine(APuntos[N - 1].X, ABaseY, APuntos[0].X, ABaseY);
        Path.CloseFigure;

        AreaBrush := TGPLinearGradientBrush.Create(
          MakeRect(APuntos[0].X, APuntos[0].Y - 4, 1, ABaseY - APuntos[0].Y + 8),
          MakeColor(90, $6E, $9F, $C8),    // arriba: azul-verde translucido
          MakeColor(20, $6E, $9F, $C8),    // abajo: casi transparente
          LinearGradientModeVertical);
        try
          G.FillPath(AreaBrush, Path);
        finally
          AreaBrush.Free;
        end;
      finally
        Path.Free;
      end;
    end;

    // --- Linea principal, tramo a tramo ---
    for I := 1 to N - 1 do
    begin
      Pen := TGPPen.Create(ColorTramo(APcts[I]), 2.6);
      try
        Pen.SetLineJoin(LineJoinRound);
        Pen.SetStartCap(LineCapRound);
        Pen.SetEndCap(LineCapRound);
        // A partir del primer punto proyectado, linea punteada.
        if I >= ASplitReal then
          Pen.SetDashStyle(DashStyleDash);
        G.DrawLine(Pen, APuntos[I - 1].X, APuntos[I - 1].Y,
                        APuntos[I].X, APuntos[I].Y);
      finally
        Pen.Free;
      end;
    end;

    // --- Puntos (circulos rellenos con halo blanco) ---
    for I := 0 to N - 1 do
    begin
      var Br: TGPSolidBrush := TGPSolidBrush.Create(MakeColor(255, 255, 255, 255));
      try
        G.FillEllipse(Br, APuntos[I].X - 5, APuntos[I].Y - 5, 10, 10);
      finally
        Br.Free;
      end;
      var PenP: TGPPen := TGPPen.Create(ColorTramo(APcts[I]), 2.2);
      try
        G.DrawEllipse(PenP, APuntos[I].X - 5, APuntos[I].Y - 5, 10, 10);
      finally
        PenP.Free;
      end;
    end;
  finally
    G.Free;
  end;
end;

procedure TfrmHistogramasOperarios.pbEvolucionPaint(Sender: TObject);
begin
  DibujarEvolucion(pbEvolucion.Canvas, pbEvolucion.Width, pbEvolucion.Height);
end;

procedure TfrmHistogramasOperarios.DibujarEvolucion(C: TCanvas;
  AWidth, AHeight: Integer);
// Grafico de linea/area: % de ocupacion medio del equipo semana a semana.
const
  EV_SCALE_MAX = 150;   // eje 0..150%
var
  R: TRect;
  I, ChartX0, ChartX1, ChartTop, ChartBottom, AreaW, AreaH: Integer;
  N: Integer;
  Pts: TArray<TPoint>;
  Pcts: TArray<Double>;
  function PxX(AIdx: Integer): Integer;
  begin
    if N <= 1 then Exit(ChartX0 + AreaW div 2);
    Result := ChartX0 + Round(AreaW * AIdx / (N - 1));
  end;
  function PxY(APct: Double): Integer;
  var V: Double;
  begin
    V := APct;
    if V < 0 then V := 0;
    if V > EV_SCALE_MAX then V := EV_SCALE_MAX;
    Result := ChartBottom - Round((V / EV_SCALE_MAX) * AreaH);
  end;
begin
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  C.FillRect(Rect(0, 0, AWidth, AHeight));

  DibujarBandaKPI(C, AWidth, 0, CH_KPI_H);

  N := Length(FEvol);
  if N = 0 then
  begin
    C.Font.Size := 11;
    C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := Rect(0, CH_KPI_H, AWidth, AHeight);
    DrawText(C.Handle, 'Sin datos para mostrar.', -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;
    Exit;
  end;

  // Titulo
  C.Font.Size := 11;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, CH_KPI_H + 10, AWidth - 16, CH_KPI_H + 36);
  DrawText(C.Handle,
    'Evoluci'#243'n de la ocupaci'#243'n media del equipo (semanal)', -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  ChartX0 := 70;
  ChartX1 := AWidth - 40;
  ChartTop := CH_KPI_H + 50;
  ChartBottom := AHeight - 60;
  AreaW := ChartX1 - ChartX0;
  AreaH := ChartBottom - ChartTop;
  if (AreaW < 80) or (AreaH < 60) then Exit;

  // Grid + eje Y (%)
  C.Font.Size := 8;
  C.Font.Style := [];
  for var G := 0 to 3 do
  begin
    var Pv: Integer := G * 50;   // 0, 50, 100, 150
    var Yg: Integer := PxY(Pv);
    if Pv = 100 then C.Pen.Color := CLR_AXIS_100 else C.Pen.Color := CLR_AXIS_FAINT;
    C.Pen.Style := psSolid;
    C.MoveTo(ChartX0, Yg);
    C.LineTo(ChartX1, Yg);
    C.Font.Color := CLR_TXT_MUTED;
    R := Rect(0, Yg - 8, ChartX0 - 8, Yg + 8);
    DrawText(C.Handle, PChar(IntToStr(Pv) + '%'), -1, R,
      DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  end;

  // Preparar puntos y pintar la serie suavizada (GDI+).
  SetLength(Pts, N);
  SetLength(Pcts, N);
  for I := 0 to N - 1 do
  begin
    Pts[I] := Point(PxX(I), PxY(Max(0, FEvol[I].PctMedio)));
    Pcts[I] := FEvol[I].PctMedio;
  end;
  DibujarSerieSuave(C, Pts, Pcts, ChartBottom, N);   // todo real (solido)

  // Etiquetas de valor y de semana
  for I := 0 to N - 1 do
  begin
    var Px: Integer := PxX(I);
    if FEvol[I].PctMedio >= 0 then
    begin
      var Py: Integer := PxY(FEvol[I].PctMedio);
      C.Font.Size := 8;
      C.Font.Style := [fsBold];
      C.Font.Color := CLR_TXT_PRIMARY;
      C.Brush.Style := bsClear;
      R := Rect(Px - 30, Py - 24, Px + 30, Py - 8);
      DrawText(C.Handle, PChar(Format('%.0f%%', [FEvol[I].PctMedio])), -1, R,
        DT_CENTER or DT_BOTTOM or DT_SINGLELINE);
    end;
    C.Font.Size := 8;
    C.Font.Style := [];
    C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := Rect(Px - 40, ChartBottom + 6, Px + 40, ChartBottom + 24);
    DrawText(C.Handle, PChar(FEvol[I].Label_), -1, R,
      DT_CENTER or DT_TOP or DT_SINGLELINE);
  end;
  C.Brush.Style := bsSolid;

  // Eje X base
  C.Pen.Color := CLR_AXIS_100;
  C.Pen.Style := psSolid;
  C.MoveTo(ChartX0, ChartBottom);
  C.LineTo(ChartX1, ChartBottom);
end;

procedure TfrmHistogramasOperarios.CalcularProyeccion;
// Construye FProy = semanas reales (FEvol) + PROY_SEMANAS_FUTURAS semanas
// futuras con la carga YA comprometida en el plan. En modo real la carga
// futura sale de nodos con fecha en esas semanas; en demo se extrapola con la
// tendencia de la serie + una oscilacion suave. Marca FProySemAlerta = indice
// de la 1a semana proyectada que supera el 100%.
var
  Q: TADOQuery;
  I, W, K: Integer;
  Cursor: TDateTime;
  CapSemana: Double;
  Pendiente, Interc, SumX, SumY, SumXY, SumXX, DenReg: Double;
  NReal: Integer;
  OperatorId: Integer;
  NodeInicio, NodeFin: TDateTime;
  Horas, NodeDurMin, OvMin: Double;
  OvS, OvE: TDateTime;
begin
  SetLength(FProy, 0);
  FProySemAlerta := -1;
  NReal := Length(FEvol);
  if NReal = 0 then Exit;

  // 1) Copiar las semanas reales tal cual (marcadas como no-proyeccion).
  SetLength(FProy, NReal + PROY_SEMANAS_FUTURAS);
  for I := 0 to NReal - 1 do
  begin
    FProy[I] := FEvol[I];
    FProy[I].EsProyeccion := False;
  end;

  // 2) Crear las semanas futuras (a continuacion de la ultima real).
  Cursor := FEvol[NReal - 1].Fin;
  // snap a lunes por si acaso
  Cursor := Cursor - ((DayOfTheWeek(Cursor) + 6) mod 7);
  if Cursor < FEvol[NReal - 1].Fin then Cursor := IncDay(Cursor, 7);
  for K := 0 to PROY_SEMANAS_FUTURAS - 1 do
  begin
    var P: TEvolPunto;
    P := Default(TEvolPunto);
    P.Inicio := Cursor;
    P.Fin := IncDay(Cursor, 7);
    P.Label_ := 'S' + IntToStr(WeekOf(Cursor));
    P.EsProyeccion := True;
    FProy[NReal + K] := P;
    Cursor := IncDay(Cursor, 7);
  end;

  // 3) Capacidad de cada semana futura: suma de la de los operarios filtrados.
  for W := NReal to High(FProy) do
    for I := 0 to High(FStatsCarga) do
    begin
      var Op := FStatsCarga[I];
      if DemoMode.Active then
      begin
        // Demo: capacidad semanal ~ capacidad media del rango real.
        if NReal > 0 then
          FProy[W].HorasCap := FProy[W].HorasCap + Op.CapacidadHoras / NReal;
      end
      else
      begin
        var Cal: TCentreCalendar := nil;
        if (DMPlanner.CalendarsRepo <> nil) and (Op.CalendarId > 0) then
          DMPlanner.CalendarsRepo.TryGetById(Op.CalendarId, Cal);
        if Cal <> nil then
        begin
          CapSemana := Cal.WorkingMinutesBetween(FProy[W].Inicio, FProy[W].Fin) / 60.0;
          if CapSemana > 0 then FProy[W].HorasCap := FProy[W].HorasCap + CapSemana;
        end;
      end;
    end;

  // 4) Carga planificada de las semanas futuras.
  if DemoMode.Active then
  begin
    // Regresion lineal sobre las semanas reales para extrapolar la tendencia
    // del % medio, con una oscilacion suave para que no sea una recta perfecta.
    SumX := 0; SumY := 0; SumXY := 0; SumXX := 0;
    for I := 0 to NReal - 1 do
      if FEvol[I].PctMedio >= 0 then
      begin
        SumX := SumX + I; SumY := SumY + FEvol[I].PctMedio;
        SumXY := SumXY + I * FEvol[I].PctMedio; SumXX := SumXX + I * I;
      end;
    DenReg := (NReal * SumXX - SumX * SumX);
    if Abs(DenReg) > 0.0001 then
    begin
      Pendiente := (NReal * SumXY - SumX * SumY) / DenReg;
      Interc := (SumY - Pendiente * SumX) / NReal;
    end
    else begin Pendiente := 0; Interc := FKPI.OcupacionMedia; end;

    for K := 0 to PROY_SEMANAS_FUTURAS - 1 do
    begin
      W := NReal + K;
      var PctTend: Double := Interc + Pendiente * W;
      // Oscilacion determinista suave (sin Random) para credibilidad.
      var Osc: TArray<Double> := DemoSerieHaciaValor(PctTend, 1, 0.10, 7000 + K);
      var PctFut: Double := PctTend;
      if Length(Osc) > 0 then PctFut := Osc[0];
      if PctFut < 0 then PctFut := 0;
      FProy[W].HorasPlan := FProy[W].HorasCap * PctFut / 100.0;
    end;
  end
  else if (Length(FStatsCarga) > 0) and (DMPlanner.CurrentProjectId > 0) and
          (FProy[High(FProy)].Fin > FEvol[NReal - 1].Fin) then
  begin
    // Modo real: carga comprometida = nodos con fecha en las semanas futuras.
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
      Q.Parameters.ParamByName('PID').Value := DMPlanner.CurrentProjectId;
      Q.Parameters.ParamByName('HInicio').Value := FProy[NReal].Inicio;
      Q.Parameters.ParamByName('HFin').Value := FProy[High(FProy)].Fin;
      try
        Q.Open;
        while not Q.Eof do
        begin
          OperatorId := Q.FieldByName('OperatorId').AsInteger;
          var EnFiltro: Boolean := False;
          for I := 0 to High(FStatsCarga) do
            if FStatsCarga[I].Id = OperatorId then begin EnFiltro := True; Break; end;
          if EnFiltro then
          begin
            NodeInicio := Q.FieldByName('FechaInicio').AsDateTime;
            NodeFin    := Q.FieldByName('FechaFin').AsDateTime;
            Horas      := Q.FieldByName('Horas').AsFloat;
            NodeDurMin := MinutesBetween(NodeFin, NodeInicio);
            if (NodeDurMin > 0) and (Horas > 0) then
              for W := NReal to High(FProy) do
              begin
                OvS := FProy[W].Inicio;
                if NodeInicio > OvS then OvS := NodeInicio;
                OvE := FProy[W].Fin;
                if NodeFin < OvE then OvE := NodeFin;
                if OvE > OvS then
                begin
                  OvMin := MinutesBetween(OvE, OvS);
                  FProy[W].HorasPlan := FProy[W].HorasPlan +
                    Horas * (OvMin / NodeDurMin);
                end;
              end;
          end;
          Q.Next;
        end;
      except
      end;
    finally
      Q.Free;
    end;
  end;

  // 5) Derivar % y detectar la 1a semana proyectada en sobrecarga.
  for W := 0 to High(FProy) do
  begin
    if FProy[W].HorasCap > 0 then
      FProy[W].PctMedio := FProy[W].HorasPlan / FProy[W].HorasCap * 100.0
    else
      FProy[W].PctMedio := -1;
    if (FProySemAlerta < 0) and FProy[W].EsProyeccion and
       (FProy[W].PctMedio > 100) then
      FProySemAlerta := W;
  end;
end;

procedure TfrmHistogramasOperarios.pbProyeccionPaint(Sender: TObject);
begin
  DibujarProyeccion(pbProyeccion.Canvas, pbProyeccion.Width, pbProyeccion.Height);
end;

procedure TfrmHistogramasOperarios.DibujarProyeccion(C: TCanvas;
  AWidth, AHeight: Integer);
// Grafico de proyeccion: serie real (solida) + semanas futuras (punteadas) con
// la carga ya comprometida, banda de separacion "hoy", y alerta de la 1a
// semana en sobrecarga.
const
  EV_SCALE_MAX = 150;
var
  R: TRect;
  I, ChartX0, ChartX1, ChartTop, ChartBottom, AreaW, AreaH: Integer;
  N, NReal: Integer;
  Pts: TArray<TPoint>;
  Pcts: TArray<Double>;
  function PxX(AIdx: Integer): Integer;
  begin
    if N <= 1 then Exit(ChartX0 + AreaW div 2);
    Result := ChartX0 + Round(AreaW * AIdx / (N - 1));
  end;
  function PxY(APct: Double): Integer;
  var V: Double;
  begin
    V := APct;
    if V < 0 then V := 0;
    if V > EV_SCALE_MAX then V := EV_SCALE_MAX;
    Result := ChartBottom - Round((V / EV_SCALE_MAX) * AreaH);
  end;
begin
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  C.FillRect(Rect(0, 0, AWidth, AHeight));

  DibujarBandaKPI(C, AWidth, 0, CH_KPI_H);

  N := Length(FProy);
  if N = 0 then
  begin
    C.Font.Size := 11;
    C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := Rect(0, CH_KPI_H, AWidth, AHeight);
    DrawText(C.Handle, 'Sin datos para proyectar.', -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid;
    Exit;
  end;

  // nº de semanas reales (para el split solido/punteado)
  NReal := 0;
  for I := 0 to N - 1 do
    if not FProy[I].EsProyeccion then Inc(NReal);

  // Titulo
  C.Font.Size := 11;
  C.Font.Style := [fsBold];
  C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, CH_KPI_H + 8, AWidth - 16, CH_KPI_H + 30);
  DrawText(C.Handle,
    'Proyecci'#243'n de carga comprometida (l'#237'nea continua = plan actual · discontinua = futuro)',
    -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  ChartX0 := 70;
  ChartX1 := AWidth - 40;
  ChartTop := CH_KPI_H + 54;
  ChartBottom := AHeight - 60;
  AreaW := ChartX1 - ChartX0;
  AreaH := ChartBottom - ChartTop;
  if (AreaW < 80) or (AreaH < 60) then Exit;

  // Sombreado suave de la zona proyectada (futuro)
  if (NReal > 0) and (NReal < N) then
  begin
    var XSplit: Integer := PxX(NReal - 1);
    C.Brush.Style := bsSolid;
    C.Brush.Color := $00F7F2EA;   // beige muy suave
    C.FillRect(Rect(XSplit, ChartTop, ChartX1 + 4, ChartBottom));
    // Linea vertical "hoy / fin del plan"
    C.Pen.Color := CLR_AXIS_100;
    C.Pen.Style := psDot;
    C.MoveTo(XSplit, ChartTop);
    C.LineTo(XSplit, ChartBottom);
    C.Pen.Style := psSolid;
    C.Font.Size := 8;
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := Rect(XSplit + 4, ChartTop - 2, XSplit + 120, ChartTop + 16);
    DrawText(C.Handle, 'proyecci'#243'n '#8594, -1, R,
      DT_LEFT or DT_TOP or DT_SINGLELINE);
  end;

  // Grid + eje Y (%)
  C.Font.Size := 8;
  C.Font.Style := [];
  for var G := 0 to 3 do
  begin
    var Pv: Integer := G * 50;
    var Yg: Integer := PxY(Pv);
    if Pv = 100 then C.Pen.Color := CLR_AXIS_100 else C.Pen.Color := CLR_AXIS_FAINT;
    C.Pen.Style := psSolid;
    C.MoveTo(ChartX0, Yg);
    C.LineTo(ChartX1, Yg);
    C.Font.Color := CLR_TXT_MUTED;
    R := Rect(0, Yg - 8, ChartX0 - 8, Yg + 8);
    DrawText(C.Handle, PChar(IntToStr(Pv) + '%'), -1, R,
      DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  end;

  // Serie suavizada (solida hasta NReal, punteada despues).
  SetLength(Pts, N);
  SetLength(Pcts, N);
  for I := 0 to N - 1 do
  begin
    Pts[I] := Point(PxX(I), PxY(Max(0, FProy[I].PctMedio)));
    Pcts[I] := FProy[I].PctMedio;
  end;
  DibujarSerieSuave(C, Pts, Pcts, ChartBottom, NReal);

  // Marcador de alerta en la 1a semana de sobrecarga proyectada.
  if (FProySemAlerta >= 0) and (FProySemAlerta < N) then
  begin
    var Ax: Integer := PxX(FProySemAlerta);
    var Ay: Integer := PxY(FProy[FProySemAlerta].PctMedio);
    C.Brush.Style := bsSolid;
    C.Brush.Color := CLR_OVER_BASE;
    C.Pen.Color := CLR_PAPER;
    C.Pen.Width := 2;
    C.Ellipse(Ax - 7, Ay - 7, Ax + 7, Ay + 7);
    C.Pen.Width := 1;
    // Etiqueta de aviso
    C.Font.Size := 9;
    C.Font.Style := [fsBold];
    C.Font.Color := CLR_OVER_BASE;
    C.Brush.Style := bsClear;
    R := Rect(Ax - 90, Ay - 40, Ax + 90, Ay - 20);
    DrawText(C.Handle,
      PChar(Format(#9888' %s: %.0f%%', [FProy[FProySemAlerta].Label_,
                                        FProy[FProySemAlerta].PctMedio])),
      -1, R, DT_CENTER or DT_BOTTOM or DT_SINGLELINE);
  end;

  // Etiquetas de valor (solo cada 2 para no saturar) y de semana
  for I := 0 to N - 1 do
  begin
    var Px: Integer := PxX(I);
    if (FProy[I].PctMedio >= 0) and ((I mod 2 = 0) or (I = FProySemAlerta)) then
    begin
      var Py: Integer := PxY(FProy[I].PctMedio);
      C.Font.Size := 8;
      C.Font.Style := [fsBold];
      if FProy[I].EsProyeccion then C.Font.Color := CLR_TXT_MUTED
                               else C.Font.Color := CLR_TXT_PRIMARY;
      C.Brush.Style := bsClear;
      R := Rect(Px - 26, Py - 24, Px + 26, Py - 8);
      DrawText(C.Handle, PChar(Format('%.0f%%', [FProy[I].PctMedio])), -1, R,
        DT_CENTER or DT_BOTTOM or DT_SINGLELINE);
    end;
    C.Font.Size := 8;
    C.Font.Style := [];
    C.Font.Color := CLR_TXT_MUTED;
    C.Brush.Style := bsClear;
    R := Rect(Px - 30, ChartBottom + 6, Px + 30, ChartBottom + 24);
    DrawText(C.Handle, PChar(FProy[I].Label_), -1, R,
      DT_CENTER or DT_TOP or DT_SINGLELINE);
  end;
  C.Brush.Style := bsSolid;

  // Eje X base
  C.Pen.Color := CLR_AXIS_100;
  C.Pen.Style := psSolid;
  C.MoveTo(ChartX0, ChartBottom);
  C.LineTo(ChartX1, ChartBottom);

  // Resumen textual abajo
  C.Font.Size := 10;
  C.Font.Style := [fsBold];
  C.Brush.Style := bsClear;
  var Resumen: string;
  var ResColor: TColor;
  if FProySemAlerta >= 0 then
  begin
    Resumen := Format('Aviso: se prev'#233' sobrecarga en la semana %s (%.0f%%). '+
      'Conviene reprogramar o reforzar antes de esa fecha.',
      [FProy[FProySemAlerta].Label_, FProy[FProySemAlerta].PctMedio]);
    ResColor := CLR_OVER_BASE;
  end
  else
  begin
    Resumen := 'Sin sobrecargas previstas en el horizonte proyectado: el plan '+
      'comprometido se mantiene dentro de la capacidad.';
    ResColor := CLR_LO_BASE;
  end;
  C.Font.Color := ResColor;
  R := Rect(16, ChartBottom + 30, AWidth - 16, ChartBottom + 52);
  DrawText(C.Handle, PChar(Resumen), -1, R,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  C.Brush.Style := bsSolid;
end;

procedure TfrmHistogramasOperarios.pbParetoPaint(Sender: TObject);
begin
  DibujarPareto(pbPareto.Canvas, pbPareto.Width, pbPareto.Height);
end;

procedure TfrmHistogramasOperarios.DibujarPareto(C: TCanvas; AWidth, AHeight: Integer);
// Diagrama de Pareto sobre el coste: barras (coste por operario, orden desc) +
// linea de % acumulado + guia del 80%. Responde "que pocos operarios
// concentran la mayor parte del coste".
var
  R: TRect;
  I, N, ChartX0, ChartX1, ChartTop, ChartBottom, AreaW, AreaH: Integer;
  BarW, Gap, X, BarTop: Integer;
  Total, Acum: Double;
  Datos: TArray<TOpStat>;
  PtsAcum: TArray<TPoint>;
  Sem80: Integer;
  function PyPct(APct: Double): Integer;   // eje derecho 0..100% acumulado
  begin
    Result := ChartBottom - Round((APct / 100.0) * AreaH);
  end;
begin
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  C.FillRect(Rect(0, 0, AWidth, AHeight));
  DibujarBandaKPI(C, AWidth, 0, CH_KPI_H);

  Datos := FStatsCoste;   // ya ordenado por coste desc
  N := Length(Datos);
  Total := 0;
  for I := 0 to N - 1 do Total := Total + Datos[I].Coste;

  if (N = 0) or (Total <= 0) then
  begin
    C.Font.Size := 11; C.Font.Color := CLR_TXT_MUTED; C.Brush.Style := bsClear;
    R := Rect(0, CH_KPI_H, AWidth, AHeight);
    DrawText(C.Handle, 'Sin coste para analizar (revisa sueldos y horas).', -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid; Exit;
  end;

  C.Font.Size := 11; C.Font.Style := [fsBold]; C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, CH_KPI_H + 8, AWidth - 16, CH_KPI_H + 30);
  DrawText(C.Handle,
    'Pareto de coste: '#191'qu'#233' operarios concentran la mayor parte del coste?',
    -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  ChartX0 := 60;
  ChartX1 := AWidth - 60;
  ChartTop := CH_KPI_H + 54;
  ChartBottom := AHeight - 70;
  AreaW := ChartX1 - ChartX0;
  AreaH := ChartBottom - ChartTop;
  if (AreaW < 80) or (AreaH < 60) then Exit;

  // Grid horizontal (0..100% del eje derecho, tambien sirve de escala de barras)
  C.Font.Size := 8; C.Font.Style := [];
  for var G := 0 to 4 do
  begin
    var Pv: Integer := G * 25;
    var Yg: Integer := PyPct(Pv);
    if Pv = 80 then C.Pen.Color := CLR_OVER_BASE else C.Pen.Color := CLR_AXIS_FAINT;
    C.Pen.Style := psSolid;
    C.MoveTo(ChartX0, Yg); C.LineTo(ChartX1, Yg);
    C.Font.Color := CLR_TXT_MUTED;
    R := Rect(ChartX1 + 4, Yg - 8, ChartX1 + 56, Yg + 8);
    DrawText(C.Handle, PChar(IntToStr(Pv) + '%'), -1, R, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  end;
  // Guia explicita del 80%
  var Y80: Integer := PyPct(80);
  C.Pen.Color := CLR_OVER_BASE; C.Pen.Style := psDot;
  C.MoveTo(ChartX0, Y80); C.LineTo(ChartX1, Y80); C.Pen.Style := psSolid;

  // Barras (coste, escala 0..Total mapeada al alto)
  BarW := Max(6, (AreaW - (N + 1) * 4) div Max(1, N));
  Gap := 4;
  var CosteMax: Double := Datos[0].Coste;   // el primero es el mayor (desc)
  if CosteMax <= 0 then CosteMax := 1;
  for I := 0 to N - 1 do
  begin
    X := ChartX0 + Gap + I * (BarW + Gap);
    BarTop := ChartBottom - Round((Datos[I].Coste / CosteMax) * AreaH);
    DrawRoundedBar(C, Rect(X, BarTop, X + BarW, ChartBottom),
      CLR_COST_BASE, CLR_COST_HIGH, 4);
  end;

  // Linea de % acumulado (GDI+ suave) + puntos
  SetLength(PtsAcum, N);
  Acum := 0; Sem80 := -1;
  for I := 0 to N - 1 do
  begin
    Acum := Acum + Datos[I].Coste;
    var PctAc: Double := Acum / Total * 100.0;
    if (Sem80 < 0) and (PctAc >= 80) then Sem80 := I;
    X := ChartX0 + Gap + I * (BarW + Gap) + BarW div 2;
    PtsAcum[I] := Point(X, PyPct(PctAc));
  end;
  begin
    var Gp: TGPGraphics := TGPGraphics.Create(C.Handle);
    try
      Gp.SetSmoothingMode(SmoothingModeAntiAlias);
      var Pen: TGPPen := TGPPen.Create(MakeColor(255, $1A, $6E, $C0), 2.4);
      try
        Pen.SetLineJoin(LineJoinRound);
        for I := 1 to N - 1 do
          Gp.DrawLine(Pen, PtsAcum[I-1].X, PtsAcum[I-1].Y, PtsAcum[I].X, PtsAcum[I].Y);
      finally Pen.Free; end;
      var Br: TGPSolidBrush := TGPSolidBrush.Create(MakeColor(255, $1A, $6E, $C0));
      try
        for I := 0 to N - 1 do
          Gp.FillEllipse(Br, PtsAcum[I].X - 3, PtsAcum[I].Y - 3, 6, 6);
      finally Br.Free; end;
    finally Gp.Free; end;
  end;

  // Eje X labels (iniciales o #) y eje base
  C.Pen.Color := CLR_AXIS_100; C.Pen.Style := psSolid;
  C.MoveTo(ChartX0, ChartBottom); C.LineTo(ChartX1, ChartBottom);
  C.Font.Size := 7; C.Font.Color := CLR_TXT_MUTED; C.Brush.Style := bsClear;
  for I := 0 to N - 1 do
  begin
    X := ChartX0 + Gap + I * (BarW + Gap);
    var Ini: string := Copy(Trim(Datos[I].Nombre), 1, 3);
    if Ini = '' then Ini := IntToStr(Datos[I].Id);
    R := Rect(X - 6, ChartBottom + 4, X + BarW + 6, ChartBottom + 20);
    DrawText(C.Handle, PChar(Ini), -1, R, DT_CENTER or DT_TOP or DT_SINGLELINE);
  end;

  // Resumen: cuantos operarios hacen el 80% del coste
  C.Font.Size := 10; C.Font.Style := [fsBold]; C.Brush.Style := bsClear;
  C.Font.Color := CLR_OVER_BASE;
  var Msg: string;
  if Sem80 >= 0 then
    Msg := Format('%d de %d operarios (%.0f%%) concentran el 80%% del coste total.',
      [Sem80 + 1, N, (Sem80 + 1) * 100.0 / N])
  else
    Msg := 'El coste est'#225' repartido de forma uniforme entre el equipo.';
  R := Rect(16, ChartBottom + 26, AWidth - 16, ChartBottom + 50);
  DrawText(C.Handle, PChar(Msg), -1, R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  C.Brush.Style := bsSolid;
end;

procedure TfrmHistogramasOperarios.pbScatterPaint(Sender: TObject);
begin
  DibujarScatter(pbScatter.Canvas, pbScatter.Width, pbScatter.Height);
end;

procedure TfrmHistogramasOperarios.DibujarScatter(C: TCanvas; AWidth, AHeight: Integer);
// Dispersion ocupacion (X, 0..150%) vs coste (Y). Tamano de burbuja = horas
// asignadas. Lineas de media dividen en 4 cuadrantes para leer perfiles
// (caro+ocioso = ineficiente, etc.).
const
  SC_XMAX = 150;
var
  R: TRect;
  I, N, ChartX0, ChartX1, ChartTop, ChartBottom, AreaW, AreaH: Integer;
  MaxCoste, MaxHoras, SumPct, SumCoste: Double;
  CntPct: Integer;
  MediaPct, MediaCoste: Double;
  function PxX(APct: Double): Integer;
  var V: Double;
  begin
    V := APct; if V < 0 then V := 0; if V > SC_XMAX then V := SC_XMAX;
    Result := ChartX0 + Round((V / SC_XMAX) * AreaW);
  end;
  function PyY(ACoste: Double): Integer;
  begin
    if MaxCoste <= 0 then Exit(ChartBottom);
    Result := ChartBottom - Round((ACoste / MaxCoste) * AreaH);
  end;
begin
  C.Font.Name := 'Segoe UI';
  C.Brush.Color := CLR_PAPER;
  C.FillRect(Rect(0, 0, AWidth, AHeight));
  DibujarBandaKPI(C, AWidth, 0, CH_KPI_H);

  N := Length(FStatsCarga);
  if N = 0 then
  begin
    C.Font.Size := 11; C.Font.Color := CLR_TXT_MUTED; C.Brush.Style := bsClear;
    R := Rect(0, CH_KPI_H, AWidth, AHeight);
    DrawText(C.Handle, 'Sin datos para mostrar.', -1, R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    C.Brush.Style := bsSolid; Exit;
  end;

  C.Font.Size := 11; C.Font.Style := [fsBold]; C.Font.Color := CLR_HEADER_TX;
  C.Brush.Style := bsClear;
  R := Rect(16, CH_KPI_H + 8, AWidth - 16, CH_KPI_H + 30);
  DrawText(C.Handle,
    'Ocupaci'#243'n vs Coste (tama'#241'o = horas asignadas)', -1, R,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE);

  ChartX0 := 70;
  ChartX1 := AWidth - 40;
  ChartTop := CH_KPI_H + 54;
  ChartBottom := AHeight - 60;
  AreaW := ChartX1 - ChartX0;
  AreaH := ChartBottom - ChartTop;
  if (AreaW < 80) or (AreaH < 60) then Exit;

  MaxCoste := 0; MaxHoras := 0; SumPct := 0; SumCoste := 0; CntPct := 0;
  for I := 0 to N - 1 do
  begin
    if FStatsCarga[I].Coste > MaxCoste then MaxCoste := FStatsCarga[I].Coste;
    if FStatsCarga[I].HorasAsignadas > MaxHoras then MaxHoras := FStatsCarga[I].HorasAsignadas;
    SumCoste := SumCoste + FStatsCarga[I].Coste;
    if FStatsCarga[I].PctOcupacion >= 0 then
    begin SumPct := SumPct + FStatsCarga[I].PctOcupacion; Inc(CntPct); end;
  end;
  if MaxCoste <= 0 then MaxCoste := 1;
  if MaxHoras <= 0 then MaxHoras := 1;
  if CntPct > 0 then MediaPct := SumPct / CntPct else MediaPct := 0;
  MediaCoste := SumCoste / N;

  // Grid X (ocupacion) e Y (coste)
  C.Font.Size := 8; C.Font.Style := [];
  for var G := 0 to 3 do
  begin
    var Pv: Integer := G * 50;
    var Xg: Integer := PxX(Pv);
    if Pv = 100 then C.Pen.Color := CLR_AXIS_100 else C.Pen.Color := CLR_AXIS_FAINT;
    C.Pen.Style := psSolid;
    C.MoveTo(Xg, ChartTop); C.LineTo(Xg, ChartBottom);
    C.Font.Color := CLR_TXT_MUTED;
    R := Rect(Xg - 20, ChartBottom + 4, Xg + 20, ChartBottom + 20);
    DrawText(C.Handle, PChar(IntToStr(Pv) + '%'), -1, R, DT_CENTER or DT_TOP or DT_SINGLELINE);
  end;
  for var G := 0 to 3 do
  begin
    var Cv: Double := MaxCoste * G / 3;
    var Yg: Integer := PyY(Cv);
    C.Pen.Color := CLR_AXIS_FAINT; C.Pen.Style := psSolid;
    C.MoveTo(ChartX0, Yg); C.LineTo(ChartX1, Yg);
    C.Font.Color := CLR_TXT_MUTED;
    R := Rect(0, Yg - 8, ChartX0 - 6, Yg + 8);
    DrawText(C.Handle, PChar(Format('%.0f', [Cv])), -1, R, DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  end;

  // Lineas de media (cuadrantes)
  C.Pen.Color := $003C3C3C; C.Pen.Style := psDot;
  var Xm: Integer := PxX(MediaPct);
  C.MoveTo(Xm, ChartTop); C.LineTo(Xm, ChartBottom);
  var Ym: Integer := PyY(MediaCoste);
  C.MoveTo(ChartX0, Ym); C.LineTo(ChartX1, Ym);
  C.Pen.Style := psSolid;

  // Burbujas (GDI+ con transparencia + halo)
  begin
    var Gp: TGPGraphics := TGPGraphics.Create(C.Handle);
    try
      Gp.SetSmoothingMode(SmoothingModeAntiAlias);
      for I := 0 to N - 1 do
      begin
        var Op := FStatsCarga[I];
        if Op.PctOcupacion < 0 then Continue;
        var Bx: Integer := PxX(Op.PctOcupacion);
        var By: Integer := PyY(Op.Coste);
        var Rad: Integer := 5 + Round(14 * (Op.HorasAsignadas / MaxHoras));
        // color por nivel de ocupacion
        var Cr, Cg, Cb: Byte;
        if Op.PctOcupacion > 100 then begin Cr := $2E; Cg := $2E; Cb := $B8; end
        else if Op.PctOcupacion >= 85 then begin Cr := $BF; Cg := $6E; Cb := $14; end
        else begin Cr := $70; Cg := $B8; Cb := $72; end;
        var Br: TGPSolidBrush := TGPSolidBrush.Create(MakeColor(150, Cr, Cg, Cb));
        try Gp.FillEllipse(Br, Bx - Rad, By - Rad, Rad * 2, Rad * 2);
        finally Br.Free; end;
        var Pen: TGPPen := TGPPen.Create(MakeColor(230, Cr, Cg, Cb), 1.5);
        try Gp.DrawEllipse(Pen, Bx - Rad, By - Rad, Rad * 2, Rad * 2);
        finally Pen.Free; end;
      end;
    finally Gp.Free; end;
  end;

  // Etiquetas de cuadrante
  C.Font.Size := 8; C.Font.Style := [fsBold]; C.Brush.Style := bsClear;
  C.Font.Color := CLR_OVER_BASE;
  R := Rect(ChartX0 + 4, ChartTop + 2, Xm - 4, ChartTop + 18);
  DrawText(C.Handle, 'caro y poco ocupado', -1, R, DT_LEFT or DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS);
  C.Font.Color := CLR_LO_BASE;
  R := Rect(Xm + 4, ChartBottom - 18, ChartX1 - 4, ChartBottom - 2);
  DrawText(C.Handle, 'muy ocupado y barato', -1, R, DT_RIGHT or DT_BOTTOM or DT_SINGLELINE or DT_END_ELLIPSIS);

  // Ejes titulo
  C.Font.Size := 8; C.Font.Style := []; C.Font.Color := CLR_TXT_MUTED;
  R := Rect(ChartX0, ChartBottom + 22, ChartX1, ChartBottom + 38);
  DrawText(C.Handle, '% Ocupaci'#243'n  '#8594, -1, R, DT_CENTER or DT_TOP or DT_SINGLELINE);

  C.Brush.Style := bsSolid;
end;

procedure TfrmHistogramasOperarios.LoadPrefs;
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
  Js := DMPlanner.UserPrefs.Load('HistogramasOperarios');
  if Js = '' then Exit;

  Root := TJSONObject.ParseJSONValue(Js) as TJSONObject;
  if Root = nil then Exit;
  try
    V := Root.GetValue('desde');
    if V <> nil then
      try dtDesde.Date := StrToDateTime((V as TJSONString).Value); except end;
    V := Root.GetValue('hasta');
    if V <> nil then
      try dtHasta.Date := StrToDateTime((V as TJSONString).Value); except end;
    V := Root.GetValue('tab');
    if V <> nil then
      try pcTabs.ActivePageIndex := (V as TJSONNumber).AsInt; except end;

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
          for I := 0 to High(FAllOps) do
          begin
            Oid := FAllOps[I].Id;
            if IdsSet.ContainsKey(Oid) then
              cbOperarios.States[I + 1] := cbsChecked
            else
              cbOperarios.States[I + 1] := cbsUnchecked;
          end;
          if IdsSet.Count = Length(FAllOps) then
            cbOperarios.States[0] := cbsChecked;
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

procedure TfrmHistogramasOperarios.SavePrefs;
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
    Root.AddPair('desde', FormatDateTime('yyyy-mm-dd', dtDesde.Date));
    Root.AddPair('hasta', FormatDateTime('yyyy-mm-dd', dtHasta.Date));
    Root.AddPair('tab', TJSONNumber.Create(pcTabs.ActivePageIndex));

    TodosSel := (cbOperarios.Properties.Items.Count > 0) and
                (cbOperarios.States[0] = cbsChecked);
    if TodosSel then
      Root.AddPair('operarios', TJSONNull.Create)
    else
    begin
      Arr := TJSONArray.Create;
      for I := 0 to High(FAllOps) do
        if (I + 1 < cbOperarios.Properties.Items.Count) and
           (cbOperarios.States[I + 1] = cbsChecked) then
          Arr.AddElement(TJSONNumber.Create(FAllOps[I].Id));
      Root.AddPair('operarios', Arr);
    end;

    DMPlanner.UserPrefs.Save('HistogramasOperarios', Root.ToJSON);
  finally
    Root.Free;
  end;
end;

procedure TfrmHistogramasOperarios.EstiloBotonHeader(var ABtn: TcxButton);
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

procedure TfrmHistogramasOperarios.ExportarPNGClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  Bmp: TBitmap;
  Png: TPngImage;
  Pb: TPaintBox;
  NombreTab: string;
begin
  // Exporta el tab actualmente visible.
  Pb := nil;
  NombreTab := 'Histograma';
  case pcTabs.ActivePageIndex of
    0: begin Pb := pbCarga;       NombreTab := 'Carga'; end;
    1: begin Pb := pbDistrib;     NombreTab := 'Distribucion'; end;
    2: begin Pb := pbCoste;       NombreTab := 'Coste'; end;
    3: begin Pb := pbComparativa; NombreTab := 'PlanVsCapacidad'; end;
    4: begin Pb := pbEvolucion;   NombreTab := 'Evolucion'; end;
    5: begin Pb := pbProyeccion;  NombreTab := 'Proyeccion'; end;
    6: begin Pb := pbPareto;      NombreTab := 'Pareto'; end;
    7: begin Pb := pbScatter;     NombreTab := 'OcupacionVsCoste'; end;
  end;
  if (Pb = nil) or (Pb.Width <= 0) or (Pb.Height <= 0) then
  begin
    ShowMessage('No hay datos para exportar.');
    Exit;
  end;

  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'Imagen PNG (*.png)|*.png';
    Dlg.DefaultExt := 'png';
    Dlg.FileName := 'Histograma' + NombreTab + '_' +
      FormatDateTime('yyyymmdd', dtDesde.Date) + '.png';
    if not Dlg.Execute then Exit;

    Bmp := TBitmap.Create;
    try
      Bmp.PixelFormat := pf24bit;
      Bmp.SetSize(Pb.Width, Pb.Height);
      // Redibuja el tab activo (a su tamano real) directamente sobre el bitmap.
      case pcTabs.ActivePageIndex of
        0: DibujarCarga(Bmp.Canvas, Bmp.Width, Bmp.Height);
        1: DibujarDistrib(Bmp.Canvas, Bmp.Width, Bmp.Height);
        2: DibujarCoste(Bmp.Canvas, Bmp.Width, Bmp.Height);
        3: DibujarComparativa(Bmp.Canvas, Bmp.Width, Bmp.Height);
        4: DibujarEvolucion(Bmp.Canvas, Bmp.Width, Bmp.Height);
        5: DibujarProyeccion(Bmp.Canvas, Bmp.Width, Bmp.Height);
        6: DibujarPareto(Bmp.Canvas, Bmp.Width, Bmp.Height);
        7: DibujarScatter(Bmp.Canvas, Bmp.Width, Bmp.Height);
      end;
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
    ShowMessage('Histograma exportado a:' + sLineBreak + Dlg.FileName);
  finally
    Dlg.Free;
  end;
end;

procedure TfrmHistogramasOperarios.ExportarCSVClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  SB: TStringBuilder;
  I: Integer;
  Sep: Char;
  function Num(V: Double): string;
  begin
    Result := FormatFloat('0.0', V);
  end;
begin
  if (Length(FStatsCarga) = 0) and (Length(FStatsCoste) = 0) then
  begin
    ShowMessage('No hay datos para exportar.');
    Exit;
  end;
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'CSV (*.csv)|*.csv';
    Dlg.DefaultExt := 'csv';
    Dlg.FileName := 'HistogramaOperarios_' +
      FormatDateTime('yyyymmdd', dtDesde.Date) + '.csv';
    if not Dlg.Execute then Exit;

    Sep := ';';   // Excel-ES usa ';' cuando la coma es separador decimal
    SB := TStringBuilder.Create;
    try
      // Una fila por operario con todas las metricas (orden por carga desc).
      SB.Append('Operario').Append(Sep)
        .Append('Horas asignadas').Append(Sep)
        .Append('Capacidad h').Append(Sep)
        .Append('% Ocupacion').Append(Sep)
        .Append('EUR/h').Append(Sep)
        .Append('Coste EUR');
      SB.AppendLine;

      for I := 0 to High(FStatsCarga) do
      begin
        var Op := FStatsCarga[I];
        var Nom: string := Op.Nombre;
        if Trim(Nom) = '' then Nom := 'Operario #' + IntToStr(Op.Id);
        SB.Append(Nom).Append(Sep)
          .Append(Num(Op.HorasAsignadas)).Append(Sep)
          .Append(Num(Op.CapacidadHoras)).Append(Sep);
        if Op.PctOcupacion >= 0 then
          SB.Append(Num(Op.PctOcupacion))
        else
          SB.Append('');   // sin capacidad
        SB.Append(Sep)
          .Append(Num(Op.SueldoEurHora)).Append(Sep)
          .Append(Num(Op.Coste));
        SB.AppendLine;
      end;

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
