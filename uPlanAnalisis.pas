unit uPlanAnalisis;

// ============================================================================
//  Pantalla "Analisis del plan": dashboard de graficos TeeChart sobre el plan
//  ya planificado. Complementa al Gantt respondiendo preguntas de gestion.
//
//  Navegacion escalable a N graficos: arbol lateral (categorias -> graficos) +
//  PageControl con pestanas OCULTAS. Cada grafico vive en su pagina; al hacer
//  clic en el arbol se activa su pagina.
//
//  REGISTRO de graficos: cada grafico es una entrada en FGraficos con su
//  categoria, titulo y un metodo de pintado. Anadir un grafico nuevo = registrar
//  una entrada en RegistrarGraficos (no hay que tocar el DFM ni declarar tabs).
//
//  La primera pagina ("Resumen") es especial: parrilla 2x2 con 4 mini-graficos.
//  Datos: uPlanAnalisisData (reutiliza la logica de los heatmaps).
// ============================================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Graphics, Vcl.Samples.Spin,
  VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.Series,
  uPlanAnalisisData;

type
  TfrmPlanAnalisis = class(TForm)
    pnlTop: TPanel;
    lblDesde: TLabel;
    dtDesde: TDateTimePicker;
    lblGran: TLabel;
    cmbGran: TComboBox;
    lblNum: TLabel;
    spNum: TSpinEdit;
    btnActualizar: TButton;
    pnlLeft: TPanel;
    tvNav: TTreeView;
    splV: TSplitter;
    pc: TPageControl;
    procedure FormCreate(Sender: TObject);
    procedure btnActualizarClick(Sender: TObject);
    procedure tvNavClick(Sender: TObject);
    procedure tvNavCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode;
      State: TCustomDrawState; var DefaultDraw: Boolean);
  private
  type
    // Un grafico registrado. Pintar=nil + Implementado=False -> pendiente: aparece
    // en el arbol DESHABILITADO (gris) como hoja de ruta. Cuando se implementa,
    // se le asigna el pintor y queda enabled.
    TPintor = procedure(Ch: TChart) of object;
    TGraficoDef = record
      Categoria: string;
      Titulo: string;
      Implementado: Boolean;
      Pintar: TPintor;
      Pagina: TTabSheet;   // solo si Implementado
      Chart: TChart;       // solo si Implementado
    end;
  private
    FData: TPlanAnalisis;
    FGraficos: TList<TGraficoDef>;
    // Mini-charts de la pagina Resumen (parrilla 2x2): los 4 primeros implementados.
    FResumenPage: TTabSheet;
    FchR: array[0..3] of TChart;
    function NuevoChart(AParent: TWinControl): TChart;
    procedure Reg(const ACat, ATit: string; AP: TPintor);
    procedure RegistrarGraficos;
    procedure ConstruirUI;          // crea paginas + arbol a partir de FGraficos
    procedure ConstruirResumen;     // pagina especial 2x2
    procedure Recalcular;
    procedure RepintarTodo;
    procedure IrAPagina(AIndexPagina: Integer);
    // Pintores implementados
    procedure PintarCargaVsCapacidad(Ch: TChart);
    procedure PintarOcupacion(Ch: TChart);
    procedure PintarCurva(Ch: TChart);
    procedure PintarOtd(Ch: TChart);
    procedure PintarCargaApilada(Ch: TChart);
    procedure PintarPareto(Ch: TChart);
    procedure PintarSobrecarga(Ch: TChart);
    procedure PintarRetrasos(Ch: TChart);
    procedure PintarSaludPlan(Ch: TChart);
    // Tanda 2
    procedure PintarEntregasPorSemana(Ch: TChart);
    procedure PintarTopRetrasos(Ch: TChart);
    procedure PintarMakespan(Ch: TChart);
    procedure PintarDuraciones(Ch: TChart);
    procedure PintarPorArticulo(Ch: TChart);
    procedure PintarPorOperacion(Ch: TChart);
    procedure PintarOpsPorCentro(Ch: TChart);
    procedure PintarProductivoSetup(Ch: TChart);
    procedure PintarUtilGlobal(Ch: TChart);
  public
    class procedure Ejecutar;
  end;

implementation

{$R *.dfm}

uses
  System.DateUtils, System.Math, System.UITypes, System.Generics.Defaults,
  uDMPlanner;

const
  CLR_CARGA   = $00C8924A;  // azul acero (BGR)
  CLR_CAP     = $005050A0;  // linea capacidad (rojizo suave)
  CLR_OK      = $0070C070;  // verde
  CLR_WARN    = $0040A0F0;  // ambar/naranja
  CLR_BAD     = $005050E0;  // rojo

class procedure TfrmPlanAnalisis.Ejecutar;
var
  F: TfrmPlanAnalisis;
begin
  F := TfrmPlanAnalisis.Create(Application);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmPlanAnalisis.FormCreate(Sender: TObject);
begin
  cmbGran.Items.Clear;
  cmbGran.Items.Add('D'#237'as');
  cmbGran.Items.Add('Semanas');
  cmbGran.Items.Add('Meses');
  cmbGran.ItemIndex := 0;
  spNum.Value := 14;
  dtDesde.Date := Date;

  FGraficos := TList<TGraficoDef>.Create;
  RegistrarGraficos;
  ConstruirUI;
  Recalcular;
end;

// ---------------------------------------------------------------------------
// Registro de graficos. Anadir uno nuevo = una linea aqui.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.Reg(const ACat, ATit: string; AP: TPintor);
var
  G: TGraficoDef;
begin
  G := Default(TGraficoDef);
  G.Categoria := ACat;
  G.Titulo := ATit;
  G.Pintar := AP;
  G.Implementado := Assigned(AP);
  FGraficos.Add(G);
end;

procedure TfrmPlanAnalisis.RegistrarGraficos;
begin
  // Catalogo completo = hoja de ruta. AP=nil -> pendiente (gris en el arbol).
  // Para implementar uno pendiente: poner su pintor en lugar de nil.

  // --- GENERAL ---
  Reg('General',   'Salud del plan',                   PintarSaludPlan);

  // --- CAPACIDAD ---
  Reg('Capacidad', 'Carga vs capacidad por centro',    PintarCargaVsCapacidad);
  Reg('Capacidad', 'Ocupaci'#243'n por centro',           PintarOcupacion);
  Reg('Capacidad', 'Curva de carga temporal',          PintarCurva);
  Reg('Capacidad', 'Carga apilada por centro',         PintarCargaApilada);
  Reg('Capacidad', 'Pareto de carga por centro',       PintarPareto);
  Reg('Capacidad', 'Sobrecarga por centro',            PintarSobrecarga);

  // --- ENTREGAS ---
  Reg('Entregas',  'Cumplimiento de entregas (OTD)',   PintarOtd);
  Reg('Entregas',  'Distribuci'#243'n de retrasos',        PintarRetrasos);
  Reg('Entregas',  'Entregas por semana',              PintarEntregasPorSemana);
  Reg('Entregas',  'Top OF m'#225's retrasadas',           PintarTopRetrasos);

  // --- TIEMPOS ---
  Reg('Tiempos',   'Makespan por proyecto',            PintarMakespan);
  Reg('Tiempos',   'Distribuci'#243'n de duraciones',      PintarDuraciones);

  // --- MIX / PRODUCTO ---
  Reg('Mix',       'Carga por art'#237'culo',              PintarPorArticulo);
  Reg('Mix',       'Carga por tipo de operaci'#243'n',     PintarPorOperacion);
  Reg('Mix',       'N'#186' operaciones por centro',        PintarOpsPorCentro);

  // --- RECURSOS ---
  Reg('Recursos',  'Carga vs capacidad por operario',  nil);  // pendiente
  Reg('Recursos',  'Ocupaci'#243'n de operarios',          nil);  // pendiente

  // --- EFICIENCIA ---
  Reg('Eficiencia','% tiempo productivo vs setup',     PintarProductivoSetup);
  Reg('Eficiencia','Utilizaci'#243'n media global',        PintarUtilGlobal);
end;

// ---------------------------------------------------------------------------
// Construccion de la UI a partir del registro
// ---------------------------------------------------------------------------
function TfrmPlanAnalisis.NuevoChart(AParent: TWinControl): TChart;
begin
  Result := TChart.Create(Self);
  Result.Parent := AParent;
  Result.Align := alClient;
  Result.BevelOuter := bvNone;
  Result.Legend.Visible := False;
  Result.View3D := False;
  Result.Title.Visible := True;
  Result.Color := clWhite;
  Result.BackWall.Color := clWhite;
  Result.BackWall.Brush.Color := clWhite;
  Result.Gradient.Visible := False;
  Result.MarginLeft := 2;
  Result.MarginRight := 2;
end;

procedure TfrmPlanAnalisis.ConstruirUI;
const
  DATA_CATEGORIA = -1;
  DATA_PENDIENTE = -2;
var
  I: Integer;
  G: TGraficoDef;
  Page: TTabSheet;
  CatNodes: TDictionary<string, TTreeNode>;
  CatNode: TTreeNode;
begin
  pc.Style := tsTabs;  // las paginas llevan TabVisible:=False -> no se ven pestanas

  CatNodes := TDictionary<string, TTreeNode>.Create;
  tvNav.Items.BeginUpdate;
  try
    tvNav.Items.Clear;

    // --- Pagina 0: Resumen (especial 2x2). Nodo raiz, Data=0 (indice de pagina).
    FResumenPage := TTabSheet.Create(pc);
    FResumenPage.PageControl := pc;
    FResumenPage.TabVisible := False;
    ConstruirResumen;
    tvNav.Items.AddObject(nil, 'Resumen', TObject(0));

    // --- Un nodo por grafico, agrupados por categoria. ---
    // Implementado: crea pagina+chart, Data = indice de pagina (>=1).
    // Pendiente:    no crea pagina, Data = DATA_PENDIENTE (gris, no navega).
    for I := 0 to FGraficos.Count - 1 do
    begin
      G := FGraficos[I];

      if not CatNodes.TryGetValue(G.Categoria, CatNode) then
      begin
        CatNode := tvNav.Items.AddObject(nil, G.Categoria, TObject(DATA_CATEGORIA));
        CatNodes.AddOrSetValue(G.Categoria, CatNode);
      end;

      if G.Implementado then
      begin
        Page := TTabSheet.Create(pc);
        Page.PageControl := pc;
        Page.TabVisible := False;
        G.Pagina := Page;
        G.Chart := NuevoChart(Page);
        FGraficos[I] := G;
        // Data = indice de la pagina recien creada en el PageControl.
        tvNav.Items.AddChildObject(CatNode, G.Titulo, TObject(Page.PageIndex));
      end
      else
        tvNav.Items.AddChildObject(CatNode, G.Titulo + '   (pendiente)',
          TObject(DATA_PENDIENTE));
    end;

    tvNav.FullExpand;
  finally
    tvNav.Items.EndUpdate;
    CatNodes.Free;
  end;

  pc.ActivePageIndex := 0;
end;

procedure TfrmPlanAnalisis.ConstruirResumen;
var
  Cont, Fila: TPanel;
  I: Integer;

  function NuevoPanel(AParent: TWinControl; AAlign: TAlign): TPanel;
  begin
    Result := TPanel.Create(Self);
    Result.Parent := AParent;
    Result.Align := AAlign;
    Result.BevelOuter := bvLowered;
    Result.Caption := '';
  end;

begin
  // Dos filas (alTop + alClient); cada fila, dos celdas (alLeft + alClient).
  Cont := NuevoPanel(FResumenPage, alClient);
  Cont.BevelOuter := bvNone;

  Fila := NuevoPanel(Cont, alTop);
  Fila.Height := 300;
  Fila.BevelOuter := bvNone;
  FchR[0] := NuevoChart(NuevoPanel(Fila, alLeft));
  FchR[0].Parent.Width := 500;
  FchR[1] := NuevoChart(NuevoPanel(Fila, alClient));

  Fila := NuevoPanel(Cont, alClient);
  Fila.BevelOuter := bvNone;
  FchR[2] := NuevoChart(NuevoPanel(Fila, alLeft));
  FchR[2].Parent.Width := 500;
  FchR[3] := NuevoChart(NuevoPanel(Fila, alClient));

  // Los mini del resumen muestran los 4 primeros graficos registrados.
  for I := 0 to 3 do
    FchR[I].Title.Font.Size := 8;
end;

procedure TfrmPlanAnalisis.tvNavClick(Sender: TObject);
var
  N: TTreeNode;
  Idx: Integer;
begin
  N := tvNav.Selected;
  if N = nil then Exit;
  Idx := Integer(N.Data);
  if Idx < 0 then Exit;  // nodo de categoria: no navega
  IrAPagina(Idx);
end;

procedure TfrmPlanAnalisis.IrAPagina(AIndexPagina: Integer);
begin
  if (AIndexPagina >= 0) and (AIndexPagina < pc.PageCount) then
    pc.ActivePageIndex := AIndexPagina;
end;

procedure TfrmPlanAnalisis.tvNavCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Idx: Integer;
begin
  DefaultDraw := True;
  Idx := Integer(Node.Data);
  if Idx = -1 then
    // Categoria: negrita, color suave.
    Sender.Canvas.Font.Style := [fsBold]
  else if Idx = -2 then
  begin
    // Pendiente: gris, cursiva (hoja de ruta de lo que falta).
    Sender.Canvas.Font.Color := clSilver;
    Sender.Canvas.Font.Style := [fsItalic];
  end
  else
    Sender.Canvas.Font.Style := [];
end;

procedure TfrmPlanAnalisis.btnActualizarClick(Sender: TObject);
begin
  Recalcular;
end;

procedure TfrmPlanAnalisis.Recalcular;
var
  Periodos: TArray<TPeriodoPlan>;
begin
  Screen.Cursor := crHourGlass;
  try
    Periodos := BuildPeriodosPlan(dtDesde.Date, spNum.Value,
      TGranularidadPlan(cmbGran.ItemIndex));
    FData := CalcularPlanAnalisis(Periodos);
    RepintarTodo;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmPlanAnalisis.RepintarTodo;
var
  I: Integer;
  G: TGraficoDef;
begin
  // Paginas de detalle
  for I := 0 to FGraficos.Count - 1 do
  begin
    G := FGraficos[I];
    if Assigned(G.Pintar) and (G.Chart <> nil) then
      G.Pintar(G.Chart);
  end;
  // Resumen 2x2: los 4 primeros registrados
  for I := 0 to 3 do
    if (I < FGraficos.Count) and Assigned(FGraficos[I].Pintar) then
      FGraficos[I].Pintar(FchR[I]);
end;

// ---------------------------------------------------------------------------
// 1. Carga vs Capacidad por centro
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarCargaVsCapacidad(Ch: TChart);
var
  Bar: TBarSeries;
  Lin: TLineSeries;
  I: Integer;
  C: TCargaCentro;
  Carga, Cap: Double;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Carga vs capacidad por centro (h)';

  Bar := TBarSeries.Create(Ch);
  Bar.Title := 'Carga';
  Bar.Marks.Visible := False;
  Bar.BarWidthPercent := 70;
  Ch.AddSeries(Bar);

  Lin := TLineSeries.Create(Ch);
  Lin.Title := 'Capacidad';
  Lin.Color := CLR_CAP;
  Lin.LinePen.Width := 2;
  Lin.Pointer.Visible := False;
  Ch.AddSeries(Lin);

  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    Carga := C.TotalCarga;
    Cap := C.TotalCapacidad;
    if (Carga <= 0) and (Cap <= 0) then Continue;
    if (Cap > 0) and (Carga > Cap) then Color := CLR_BAD else Color := CLR_CARGA;
    Bar.Add(Carga, C.Nombre, Color);
    Lin.Add(Cap, C.Nombre, CLR_CAP);
  end;
end;

// ---------------------------------------------------------------------------
// 2. Ocupacion por centro
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarOcupacion(Ch: TChart);
var
  Bar: THorizBarSeries;
  I: Integer;
  C: TCargaCentro;
  Pct: Double;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Ocupaci'#243'n por centro (%)';

  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Bar.BarWidthPercent := 60;
  Ch.AddSeries(Bar);

  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    if C.TotalCapacidad <= 0 then Continue;
    Pct := C.OcupacionPct;
    if Pct >= 100 then Color := CLR_BAD
    else if Pct >= 80 then Color := CLR_WARN
    else Color := CLR_OK;
    Bar.Add(Pct, C.Nombre, Color);
  end;
end;

// ---------------------------------------------------------------------------
// 3. Curva de carga temporal
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarCurva(Ch: TChart);
var
  Area: TAreaSeries;
  Lin: TLineSeries;
  J: Integer;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Carga total por periodo (h)';

  Area := TAreaSeries.Create(Ch);
  Area.Title := 'Carga';
  Area.Color := CLR_CARGA;
  Area.Transparency := 40;
  Area.Marks.Visible := False;
  Ch.AddSeries(Area);

  Lin := TLineSeries.Create(Ch);
  Lin.Title := 'Capacidad';
  Lin.Color := CLR_CAP;
  Lin.LinePen.Width := 2;
  Lin.Pointer.Visible := False;
  Ch.AddSeries(Lin);

  for J := 0 to High(FData.Periodos) do
  begin
    Area.Add(FData.CargaTotalPorPeriodo[J], FData.Periodos[J].Etiqueta, CLR_CARGA);
    Lin.Add(FData.CapacidadTotalPorPeriodo[J], FData.Periodos[J].Etiqueta, CLR_CAP);
  end;
end;

// ---------------------------------------------------------------------------
// 4. On-Time Delivery
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarOtd(Ch: TChart);
var
  Pie: TPieSeries;
  O: TOtdResultado;
begin
  Ch.RemoveAllSeries;
  O := FData.Otd;
  if O.RetrasoMedioDias > 0 then
    Ch.Title.Text.Text := Format('Entregas  ·  retraso medio %.1f d'#237'as',
      [O.RetrasoMedioDias])
  else
    Ch.Title.Text.Text := 'Cumplimiento de entregas';

  Pie := TPieSeries.Create(Ch);
  Pie.Marks.Visible := True;
  Pie.Marks.Style := smsLabelPercent;
  Pie.Circled := True;
  Ch.AddSeries(Pie);

  if O.ATiempo > 0 then       Pie.Add(O.ATiempo, 'A tiempo', CLR_OK);
  if O.EnRiesgo > 0 then      Pie.Add(O.EnRiesgo, 'En riesgo', CLR_WARN);
  if O.Retrasadas > 0 then    Pie.Add(O.Retrasadas, 'Retrasadas', CLR_BAD);
  if O.SinCompromiso > 0 then Pie.Add(O.SinCompromiso, 'Sin compromiso', $00B0B0B0);
end;

// ---------------------------------------------------------------------------
// 5. Carga apilada por centro x periodo (una serie de barras por centro)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarCargaApilada(Ch: TChart);
var
  I, J: Integer;
  C: TCargaCentro;
  Bar: TBarSeries;
  Paleta: array[0..9] of TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Carga apilada por centro (h)';
  Paleta[0] := $00C8924A; Paleta[1] := $0070C070; Paleta[2] := $004080F0;
  Paleta[3] := $00B05CD0; Paleta[4] := $0040C0C0; Paleta[5] := $005050E0;
  Paleta[6] := $00A0A040; Paleta[7] := $00E08020; Paleta[8] := $008080C0;
  Paleta[9] := $0060A0A0;

  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    if C.TotalCarga <= 0 then Continue;
    Bar := TBarSeries.Create(Ch);
    Bar.Title := C.Nombre;
    Bar.MultiBar := mbStacked;        // apilar las series
    Bar.Marks.Visible := False;
    Bar.SeriesColor := Paleta[I mod 10];
    Ch.AddSeries(Bar);
    for J := 0 to High(FData.Periodos) do
      Bar.Add(C.HorasCarga[J], FData.Periodos[J].Etiqueta, Paleta[I mod 10]);
  end;
  Ch.Legend.Visible := True;
  Ch.Legend.Alignment := laBottom;
end;

// ---------------------------------------------------------------------------
// 6. Pareto de carga por centro (barras desc. + linea % acumulado)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarPareto(Ch: TChart);
var
  I: Integer;
  Bar: TBarSeries;
  Lin: TLineSeries;
  Orden: TList<Integer>;
  Total, Acum: Double;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Pareto de carga por centro';

  // Ordenar indices por carga descendente.
  Orden := TList<Integer>.Create;
  try
    Total := 0;
    for I := 0 to High(FData.Centros) do
      if FData.Centros[I].TotalCarga > 0 then
      begin
        Orden.Add(I);
        Total := Total + FData.Centros[I].TotalCarga;
      end;
    Orden.Sort(TComparer<Integer>.Construct(
      function(const A, B: Integer): Integer
      begin
        Result := CompareValue(FData.Centros[B].TotalCarga,
                               FData.Centros[A].TotalCarga);
      end));

    Bar := TBarSeries.Create(Ch);
    Bar.Title := 'Carga (h)';
    Bar.Marks.Visible := False;
    Ch.AddSeries(Bar);

    Lin := TLineSeries.Create(Ch);
    Lin.Title := '% acumulado';
    Lin.Color := CLR_BAD;
    Lin.LinePen.Width := 2;
    Ch.AddSeries(Lin);

    Acum := 0;
    for I := 0 to Orden.Count - 1 do
    begin
      Bar.Add(FData.Centros[Orden[I]].TotalCarga,
              FData.Centros[Orden[I]].Nombre, CLR_CARGA);
      Acum := Acum + FData.Centros[Orden[I]].TotalCarga;
      if Total > 0 then
        Lin.Add(Acum / Total * 100.0, FData.Centros[Orden[I]].Nombre, CLR_BAD);
    end;
  finally
    Orden.Free;
  end;
end;

// ---------------------------------------------------------------------------
// 7. Sobrecarga por centro (nº periodos por encima del 100% de capacidad)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarSobrecarga(Ch: TChart);
var
  I, J, NSobre: Integer;
  C: TCargaCentro;
  Bar: THorizBarSeries;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Periodos en sobrecarga por centro';

  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);

  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    NSobre := 0;
    for J := 0 to High(FData.Periodos) do
      if (C.HorasCapacidad[J] > 0) and (C.HorasCarga[J] > C.HorasCapacidad[J]) then
        Inc(NSobre);
    if NSobre > 0 then
      Bar.Add(NSobre, C.Nombre, CLR_BAD);
  end;
end;

// ---------------------------------------------------------------------------
// 8. Distribucion de retrasos (histograma de buckets de dias)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarRetrasos(Ch: TChart);
const
  Etiq: array[0..6] of string =
    ('<=-3d', '-2d', '-1d', 'A tiempo', '+1d', '+2d', '>=+3d');
var
  Bar: TBarSeries;
  I: Integer;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Distribuci'#243'n de desviaci'#243'n vs compromiso';

  Bar := TBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);

  for I := 0 to 6 do
  begin
    if I < 3 then Color := CLR_OK          // adelantadas / a tiempo
    else if I = 3 then Color := CLR_OK
    else if I = 4 then Color := CLR_WARN    // +1d
    else Color := CLR_BAD;                  // +2d, +3d o mas
    Bar.Add(FData.Otd.Buckets[I], Etiq[I], Color);
  end;
end;

// ---------------------------------------------------------------------------
// 9. Salud del plan (gauge sintetico 0-100)
//    Combina: OTD (% a tiempo), utilizacion media y penalizacion por sobrecarga.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarSaludPlan(Ch: TChart);
var
  Pie: TPieSeries;
  I, J, NConCompromiso, NSobre, NCeldas: Integer;
  PctOTD, UtilMedia, PenalSobre, Salud, SumaUtil: Double;
  C: TCargaCentro;
  ColorSalud: TColor;
begin
  Ch.RemoveAllSeries;

  // 1) OTD: % a tiempo sobre las que tienen compromiso.
  NConCompromiso := FData.Otd.ATiempo + FData.Otd.EnRiesgo + FData.Otd.Retrasadas;
  if NConCompromiso > 0 then
    PctOTD := FData.Otd.ATiempo / NConCompromiso * 100.0
  else
    PctOTD := 100;

  // 2) Utilizacion media de los centros con capacidad (ideal ~75-85%).
  SumaUtil := 0; NCeldas := 0;
  for I := 0 to High(FData.Centros) do
    if FData.Centros[I].TotalCapacidad > 0 then
    begin
      SumaUtil := SumaUtil + FData.Centros[I].OcupacionPct;
      Inc(NCeldas);
    end;
  if NCeldas > 0 then UtilMedia := SumaUtil / NCeldas else UtilMedia := 0;
  // Puntuacion de utilizacion: 100 en el optimo 80%, cae a los extremos.
  UtilMedia := Max(0, 100 - Abs(UtilMedia - 80) * 1.5);

  // 3) Penalizacion por sobrecarga (celdas centro/periodo por encima de cap).
  NSobre := 0;
  for I := 0 to High(FData.Centros) do
  begin
    C := FData.Centros[I];
    for J := 0 to High(FData.Periodos) do
      if (C.HorasCapacidad[J] > 0) and (C.HorasCarga[J] > C.HorasCapacidad[J]) then
        Inc(NSobre);
  end;
  PenalSobre := Min(100, NSobre * 5);  // cada celda sobrecargada resta 5

  // Indice compuesto (ponderado): 50% OTD + 30% util + 20% (100-penal).
  Salud := PctOTD * 0.5 + UtilMedia * 0.3 + (100 - PenalSobre) * 0.2;
  Salud := Max(0, Min(100, Salud));

  if Salud >= 75 then ColorSalud := CLR_OK
  else if Salud >= 50 then ColorSalud := CLR_WARN
  else ColorSalud := CLR_BAD;

  Ch.Title.Text.Text := Format('Salud del plan:  %d / 100', [Round(Salud)]);

  // "Gauge" simple: tarta con la porcion de salud coloreada y el resto en gris.
  // (El % exacto y el color semaforo van en el titulo; no usamos donut para
  //  ser compatibles con esta version de TeeChart.)
  Pie := TPieSeries.Create(Ch);
  Pie.Marks.Visible := False;
  Pie.Circled := True;
  Ch.AddSeries(Pie);
  Pie.Add(Salud, 'Salud', ColorSalud);
  Pie.Add(100 - Salud, '', $00ECECEC);
end;

// ---------------------------------------------------------------------------
// Helper: barras horizontales de TItemHoras (top N por Horas o por Conteo).
// ---------------------------------------------------------------------------
procedure BarrasItemHoras(Ch: TChart; const AItems: TArray<TItemHoras>;
  const ATitulo: string; APorConteo: Boolean; AMax: Integer; ABaseColor: TColor);
var
  Bar: THorizBarSeries;
  I, N: Integer;
  V: Double;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := ATitulo;
  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  N := Length(AItems);
  if (AMax > 0) and (N > AMax) then N := AMax;
  for I := 0 to N - 1 do
  begin
    if APorConteo then V := AItems[I].Conteo else V := AItems[I].Horas;
    Bar.Add(V, AItems[I].Clave, ABaseColor);
  end;
end;

procedure TfrmPlanAnalisis.PintarPorArticulo(Ch: TChart);
begin
  BarrasItemHoras(Ch, FData.PorArticulo, 'Carga por art'#237'culo (h) - top 15',
    False, 15, CLR_CARGA);
end;

procedure TfrmPlanAnalisis.PintarPorOperacion(Ch: TChart);
begin
  BarrasItemHoras(Ch, FData.PorOperacion, 'Carga por tipo de operaci'#243'n (h) - top 15',
    False, 15, $00B05CD0);
end;

procedure TfrmPlanAnalisis.PintarOpsPorCentro(Ch: TChart);
begin
  BarrasItemHoras(Ch, FData.OpsPorCentro, 'N'#186' operaciones por centro',
    True, 0, $0040C0C0);
end;

// ---------------------------------------------------------------------------
// Top OF mas retrasadas (barras horizontales de dias de retraso)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarTopRetrasos(Ch: TChart);
var
  Bar: THorizBarSeries;
  I: Integer;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Top OF m'#225's retrasadas (d'#237'as)';
  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  for I := 0 to High(FData.TopRetrasos) do
    Bar.Add(FData.TopRetrasos[I].RetrasoDias, FData.TopRetrasos[I].Etiqueta, CLR_BAD);
end;

// ---------------------------------------------------------------------------
// Entregas por semana: a tiempo vs retrasadas (barras apiladas en el tiempo).
// Aproximacion: usamos los buckets globales de OTD repartidos no es posible por
// semana sin re-consulta; aqui mostramos el reparto agregado a tiempo/riesgo/
// retraso como barras (visión rapida). Para detalle temporal real se ampliaria.
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarEntregasPorSemana(Ch: TChart);
var
  Bar: TBarSeries;
  O: TOtdResultado;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Entregas: cumplimiento (resumen)';
  O := FData.Otd;
  Bar := TBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  Bar.Add(O.ATiempo, 'A tiempo', CLR_OK);
  Bar.Add(O.EnRiesgo, 'En riesgo', CLR_WARN);
  Bar.Add(O.Retrasadas, 'Retrasadas', CLR_BAD);
  Bar.Add(O.SinCompromiso, 'Sin compr.', $00B0B0B0);
end;

// ---------------------------------------------------------------------------
// Makespan por proyecto (horas de ventana inicio->fin)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarMakespan(Ch: TChart);
var
  Bar: THorizBarSeries;
  I: Integer;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Makespan por proyecto (h)';
  Bar := THorizBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  for I := 0 to High(FData.Makespans) do
    Bar.Add(FData.Makespans[I].HorasSpan, FData.Makespans[I].Nombre, CLR_CARGA);
end;

// ---------------------------------------------------------------------------
// Distribucion de duraciones de operacion (histograma por buckets de minutos)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarDuraciones(Ch: TChart);
const
  Etiq: array[0..7] of string =
    ('<15m', '15-30m', '30-60m', '1-2h', '2-4h', '4-8h', '8-16h', '>16h');
var
  Bar: TBarSeries;
  I: Integer;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Distribuci'#243'n de duraciones de operaci'#243'n';
  Bar := TBarSeries.Create(Ch);
  Bar.Marks.Visible := True;
  Bar.Marks.Style := smsValue;
  Ch.AddSeries(Bar);
  for I := 0 to 7 do
    Bar.Add(FData.Duraciones[I], Etiq[I], CLR_CARGA);
end;

// ---------------------------------------------------------------------------
// % tiempo productivo vs setup por centro (barras apiladas)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarProductivoSetup(Ch: TChart);
var
  BarP, BarS: TBarSeries;
  I: Integer;
  PS: TProductivoSetup;
begin
  Ch.RemoveAllSeries;
  Ch.Title.Text.Text := 'Tiempo productivo vs setup por centro (h)';

  BarP := TBarSeries.Create(Ch);
  BarP.Title := 'Productivo';
  BarP.MultiBar := mbStacked;
  BarP.SeriesColor := CLR_OK;
  BarP.Marks.Visible := False;
  Ch.AddSeries(BarP);

  BarS := TBarSeries.Create(Ch);
  BarS.Title := 'Setup';
  BarS.MultiBar := mbStacked;
  BarS.SeriesColor := CLR_WARN;
  BarS.Marks.Visible := False;
  Ch.AddSeries(BarS);

  for I := 0 to High(FData.ProductivoSetup) do
  begin
    PS := FData.ProductivoSetup[I];
    BarP.Add(PS.HorasProductivo, PS.Nombre, CLR_OK);
    BarS.Add(PS.HorasSetup, PS.Nombre, CLR_WARN);
  end;
  Ch.Legend.Visible := True;
  Ch.Legend.Alignment := laBottom;
end;

// ---------------------------------------------------------------------------
// Utilizacion media global (gauge/tarta con el % medio)
// ---------------------------------------------------------------------------
procedure TfrmPlanAnalisis.PintarUtilGlobal(Ch: TChart);
var
  Pie: TPieSeries;
  U: Double;
  Color: TColor;
begin
  Ch.RemoveAllSeries;
  U := FData.UtilMediaGlobal;
  if U > 100 then U := 100;
  if U >= 100 then Color := CLR_BAD
  else if U >= 80 then Color := CLR_WARN
  else Color := CLR_OK;
  Ch.Title.Text.Text := Format('Utilizaci'#243'n media global:  %.0f%%',
    [FData.UtilMediaGlobal]);
  Pie := TPieSeries.Create(Ch);
  Pie.Marks.Visible := False;
  Pie.Circled := True;
  Ch.AddSeries(Pie);
  Pie.Add(U, 'Utilizado', Color);
  Pie.Add(Max(0, 100 - U), 'Libre', $00ECECEC);
end;

end.
