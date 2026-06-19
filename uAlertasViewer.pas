unit uAlertasViewer;
// Dialogo modal (bsDialog) que muestra el listado de alertas de planificacion
// detectadas por uGanttAlertas. Cada fila = un tipo de alerta con su contador y
// un badge de color por severidad. Al hacer doble clic (o "Ver en Gantt") sobre
// una alerta, el form se cierra con mrOk y expone los DataIds de los nodos
// afectados para que el caller los filtre/resalte en el Gantt.
//
// El estilo visual imita un panel de "excepciones detectadas": cabecera limpia,
// barra de filtros (gravedad / familia / buscar / solo con incidencias) y una
// tabla cxGrid con cabecera azul-gris en negrita, filas espaciadas y badges de
// gravedad como pastillas redondeadas (Critica / Alta / Media / Baja).
//
// El grid es cxGrid no-bound: se puebla desde FVisibles (las alertas que pasan
// el filtro). El badge de la columna Gravedad se pinta en OnCustomDrawCell.
//
// Ayuda contextual via THelpViewer (topic 'uAlertasViewer'), patron MD a disco.
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Types, System.UITypes, System.Variants, System.Generics.Collections,
  System.Generics.Defaults, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ImgList,
  Winapi.GDIPOBJ, Winapi.GDIPAPI,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxGridLevel,
  cxGridCustomTableView, cxGridTableView, cxGridCustomView, cxGrid, cxClasses,
  cxContainer, uGanttAlertas, System.ImageList,
  dxSkinsCore, dxSkinsDefaultPainters, dxSkinBasic, dxSkinBlack, dxSkinBlue,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
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
  dxSkinXmas2008Blue, cxNavigator, dxDateRanges, dxScrollbarAnnotations,
  cxTextEdit;

type
  // Proveedor de alertas: el caller lo implementa (delega en uGanttAlertas).
  //   AIncluirCumplidas = True -> incluye tambien los tipos sin incidencias.
  TAlertasProvider = reference to function(
    const AIncluirCumplidas: Boolean): TArray<TAlertaItem>;

  TfrmAlertasViewer = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblSalud: TLabel;
    btnConfig: TButton;
    pnlFiltros: TPanel;
    cbGravedad: TComboBox;
    cbTipo: TComboBox;
    edtBuscar: TEdit;
    chkSoloIncidencias: TCheckBox;
    Grid: TcxGrid;
    tv: TcxGridTableView;
    lv: TcxGridLevel;
    colGravedad: TcxGridColumn;
    colCodigo: TcxGridColumn;
    colFamilia: TcxGridColumn;
    colMotivo: TcxGridColumn;
    colNodos: TcxGridColumn;
    colPeso: TcxGridColumn;
    pnlBottom: TPanel;
    lblMaxRecords: TLabel;
    btnFiltrar: TButton;
    btnCerrar: TButton;
    lblResumen: TLabel;
    Button1: TButton;
    btnVerTodas: TButton;
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnFiltrarClick(Sender: TObject);
    procedure btnVerTodasClick(Sender: TObject);
    procedure btnConfigClick(Sender: TObject);
    procedure FiltroChange(Sender: TObject);
    procedure tvDblClick(Sender: TObject);
    procedure tvCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  private
    FAlertas: TArray<TAlertaItem>;       // todas las detectadas (sin filtrar)
    FVisibles: TArray<TAlertaItem>;      // las que pasan el filtro (lo que se pinta)
    FSelectedDataIds: TArray<Integer>;
    FVerTodas: Boolean;                  // estado del toggle "Ver todas"
    FRedetectar: TAlertasProvider;       // recalcula segun AIncluirCumplidas
    FOnConfig: TProc;                    // abre la config (lo provee el caller)
    FTotalNodos: Integer;                // nodos visibles, para el indice de salud
    FCargando: Boolean;                  // evita reentradas en FiltroChange
    FStyleHeader: TcxStyle;              // estilo de cabecera (azul-gris, negrita)
    FStyleSelection: TcxStyle;          // estilo de fila seleccionada (azul claro)
    procedure ConfigurarEstilos;         // crea y aplica los estilos del grid
    procedure InicializarFiltros;        // puebla los combos una sola vez
    procedure AplicarFiltro;             // FAlertas -> FVisibles segun los filtros
    procedure Poblar;
    function ColorDeSeveridad(const ASev: TAlertaSeveridad): TColor;
    function EtiquetaSeveridad(const ASev: TAlertaSeveridad): string;
    function FamiliaDe(const ACodigo: string): string;
    function AlertaDe(const ARecordIndex: Integer; out A: TAlertaItem): Boolean;
    procedure ConfirmarSeleccion;
    procedure RefrescarDesdeProveedor;
    // Dibuja un badge (pastilla redondeada) de gravedad centrado en ARect.
    procedure DibujarBadge(const ACanvas: TCanvas; const ARect: TRect;
      const AColor: TColor; const ATexto: string; const AAtenuado: Boolean);
  public
    // DataIds de la alerta elegida (vacio si se cerro sin elegir). Valido tras
    // ShowModal = mrOk.
    property SelectedDataIds: TArray<Integer> read FSelectedDataIds;
    // Punto de entrada: muestra el dialogo. ARedetectar recalcula las alertas
    // (recibe AIncluirCumplidas y devuelve la lista) -> permite el toggle
    // "Ver todas" sin acoplar el form al Gantt. La llamada inicial usa False.
    // Devuelve True (mrOk) si el usuario eligio una alerta para ver en el Gantt.
    // AOnConfig (opcional): el caller abre la config de alertas; al volver, el
    // dialogo refresca la lista (los pesos/activas pueden haber cambiado).
    class function Ejecutar(AOwner: TComponent;
      const ARedetectar: TAlertasProvider;
      out ADataIds: TArray<Integer>;
      const AOnConfig: TProc = nil;
      const ATotalNodos: Integer = 0): Boolean;
  end;

var
  frmAlertasViewer: TfrmAlertasViewer;

implementation

{$R *.dfm}

uses
  uHelpViewer;

const
  COL_ALTA  = $003B3BD0;  // rojo  (BGR)  -> Critica
  COL_MEDIA = $002090E8;  // naranja      -> Alta
  COL_AVISO = $0020B0E0;  // ambar        -> Media
  COL_INFO  = $00B08020;  // azul/info    -> Baja

  CLR_TXT      = $00222222;  // texto principal
  CLR_TXT_SOFT = $008B8378;  // texto secundario
  CLR_LINK     = $00C77A2B;  // codigo tipo enlace (azul, BGR)

// --- Helpers de color (funciones libres) -----------------------------------

function GpColorA(const AColor: TColor; const AAlpha: Byte): TGPColor;
var
  c: Integer;
begin
  c := ColorToRGB(AColor);
  Result := MakeColor(AAlpha, GetRValue(c), GetGValue(c), GetBValue(c));
end;

// Mezcla AColor con blanco (0 -> AColor, 1 -> blanco): tono pastel del fondo.
// (La variable se llama 'c', no 'rgb', para no ombrear la funcion RGB.)
function MezclarConBlanco(const AColor: TColor; const AFactor: Double): TColor;
var
  c, r, g, b: Integer;
begin
  c := ColorToRGB(AColor);
  r := Round(GetRValue(c) + (255 - GetRValue(c)) * AFactor);
  g := Round(GetGValue(c) + (255 - GetGValue(c)) * AFactor);
  b := Round(GetBValue(c) + (255 - GetBValue(c)) * AFactor);
  Result := RGB(r, g, b);
end;

// Oscurece AColor mezclandolo con negro: contraste del texto del badge.
function MezclarConNegro(const AColor: TColor; const AFactor: Double): TColor;
var
  c, r, g, b: Integer;
begin
  c := ColorToRGB(AColor);
  r := Round(GetRValue(c) * (1 - AFactor));
  g := Round(GetGValue(c) * (1 - AFactor));
  b := Round(GetBValue(c) * (1 - AFactor));
  Result := RGB(r, g, b);
end;

class function TfrmAlertasViewer.Ejecutar(AOwner: TComponent;
  const ARedetectar: TAlertasProvider;
  out ADataIds: TArray<Integer>;
  const AOnConfig: TProc;
  const ATotalNodos: Integer): Boolean;
var
  F: TfrmAlertasViewer;
begin
  ADataIds := nil;
  F := TfrmAlertasViewer.Create(AOwner);
  try
    F.FRedetectar := ARedetectar;
    F.FOnConfig := AOnConfig;
    F.FTotalNodos := ATotalNodos;
    F.btnConfig.Visible := Assigned(AOnConfig);
    F.FVerTodas := False;
    Result := F.ShowModal = mrOk;
    if Result then
      ADataIds := F.SelectedDataIds;
  finally
    F.Free;
  end;
end;

procedure TfrmAlertasViewer.RefrescarDesdeProveedor;
begin
  if Assigned(FRedetectar) then
    FAlertas := FRedetectar(FVerTodas)
  else
    FAlertas := nil;
  AplicarFiltro;    // FAlertas -> FVisibles
  Poblar;
end;

// Familia legible a partir del prefijo del codigo (A=plazos, O=operarios,
// M=material, R=recursos, C=capacidad, D=datos).
function TfrmAlertasViewer.FamiliaDe(const ACodigo: string): string;
begin
  if ACodigo = '' then Exit('');
  case ACodigo[1] of
    'A': Result := 'Plazos';
    'O': Result := 'Operarios';
    'M': Result := 'Material';
    'R': Result := 'Recursos';
    'C': Result := 'Capacidad';
    'D': Result := 'Datos';
  else
    Result := 'Otros';
  end;
end;

function TfrmAlertasViewer.EtiquetaSeveridad(
  const ASev: TAlertaSeveridad): string;
begin
  case ASev of
    asAlta:  Result := 'Cr'#237'tica';
    asMedia: Result := 'Alta';
    asAviso: Result := 'Media';
  else
    Result := 'Baja';
  end;
end;

function TfrmAlertasViewer.ColorDeSeveridad(
  const ASev: TAlertaSeveridad): TColor;
begin
  case ASev of
    asAlta:  Result := COL_ALTA;
    asMedia: Result := COL_MEDIA;
    asAviso: Result := COL_AVISO;
  else
    Result := COL_INFO;
  end;
end;

// Devuelve la alerta asociada al RecordIndex del grid (mapea sobre FVisibles
// teniendo en cuenta el orden visual actual via RowInfo no es necesario porque
// el data controller mantiene el indice de registro = indice en FVisibles).
function TfrmAlertasViewer.AlertaDe(const ARecordIndex: Integer;
  out A: TAlertaItem): Boolean;
begin
  Result := (ARecordIndex >= 0) and (ARecordIndex <= High(FVisibles));
  if Result then
    A := FVisibles[ARecordIndex];
end;

procedure TfrmAlertasViewer.ConfigurarEstilos;
begin
  // Forzamos LookAndFeel plano en el grid: con un skin activo, el skin pinta
  // la cabecera y la seleccion e IGNORA los colores de Styles.* -> sin esto el
  // fondo del header no se ve. En plano (ufmFlat) si se respetan los estilos.
  Grid.LookAndFeel.NativeStyle := False;
  Grid.LookAndFeel.Kind := lfUltraFlat;

  // Cabecera: fondo azul-gris muy claro + texto gris oscuro en negrita.
  if FStyleHeader = nil then
    FStyleHeader := TcxStyle.Create(Self);
  FStyleHeader.Color := $00F8F4F1;       // azul-gris muy claro (RGB ~F1F4F8)
  FStyleHeader.TextColor := $00504438;   // gris-azulado oscuro
  FStyleHeader.Font.Name := 'Segoe UI';
  FStyleHeader.Font.Height := -12;
  FStyleHeader.Font.Style := [fsBold];
  tv.Styles.Header := FStyleHeader;

  // Seleccion: fondo azul claro en TODA la fila + texto normal.
  if FStyleSelection = nil then
    FStyleSelection := TcxStyle.Create(Self);
  FStyleSelection.Color := $00F4E3D0;    // azul claro (BGR; RGB ~D0E3F4)
  FStyleSelection.TextColor := CLR_TXT;
  tv.Styles.Selection := FStyleSelection;
end;

procedure TfrmAlertasViewer.InicializarFiltros;
var
  S: TAlertaSeveridad;
begin
  cbGravedad.Items.BeginUpdate;
  try
    cbGravedad.Items.Clear;
    cbGravedad.Items.Add('Todas las gravedades');
    for S := High(TAlertaSeveridad) downto Low(TAlertaSeveridad) do
      cbGravedad.Items.Add(EtiquetaSeveridad(S));
  finally
    cbGravedad.Items.EndUpdate;
  end;
  cbGravedad.ItemIndex := 0;

  cbTipo.Items.BeginUpdate;
  try
    cbTipo.Items.Clear;
    cbTipo.Items.Add('Todas las familias');
    cbTipo.Items.Add('Plazos');
    cbTipo.Items.Add('Operarios');
    cbTipo.Items.Add('Material');
    cbTipo.Items.Add('Recursos');
    cbTipo.Items.Add('Capacidad');
    cbTipo.Items.Add('Datos');
  finally
    cbTipo.Items.EndUpdate;
  end;
  cbTipo.ItemIndex := 0;
end;

procedure TfrmAlertasViewer.AplicarFiltro;
var
  A: TAlertaItem;
  Res: TList<TAlertaItem>;
  txt, fam: string;
  okGrav, okFam, okTxt, okInc: Boolean;
begin
  txt := Trim(LowerCase(edtBuscar.Text));
  Res := TList<TAlertaItem>.Create;
  try
    for A in FAlertas do
    begin
      okGrav := (cbGravedad.ItemIndex <= 0) or
        (EtiquetaSeveridad(A.Severidad) = cbGravedad.Text);

      fam := FamiliaDe(A.Codigo);
      okFam := (cbTipo.ItemIndex <= 0) or (fam = cbTipo.Text);

      okTxt := (txt = '') or
        (Pos(txt, LowerCase(A.Codigo)) > 0) or
        (Pos(txt, LowerCase(fam)) > 0) or
        (Pos(txt, LowerCase(A.Titulo)) > 0);

      okInc := (not chkSoloIncidencias.Checked) or
        (A.Implementada and (A.Count > 0));

      if okGrav and okFam and okTxt and okInc then
        Res.Add(A);
    end;
    FVisibles := Res.ToArray;
  finally
    Res.Free;
  end;
end;

procedure TfrmAlertasViewer.FiltroChange(Sender: TObject);
begin
  if FCargando then Exit;
  AplicarFiltro;
  Poblar;
end;

procedure TfrmAlertasViewer.Poblar;
var
  A: TAlertaItem;
  row, totalNodos, conIncidencias, salud: Integer;
  s: string;
begin
  tv.BeginUpdate;
  try
    tv.DataController.RecordCount := Length(FVisibles);
    for row := 0 to High(FVisibles) do
    begin
      A := FVisibles[row];
      // colGravedad: el texto lo pinta el badge en CustomDrawCell, pero ponemos
      // el valor para que el sort por gravedad funcione (orden Critica..Baja).
      tv.DataController.Values[row, colGravedad.Index] := Ord(A.Severidad);
      tv.DataController.Values[row, colCodigo.Index]   := A.Codigo;
      tv.DataController.Values[row, colFamilia.Index]  := FamiliaDe(A.Codigo);
      if A.Implementada then
        tv.DataController.Values[row, colMotivo.Index] := A.Titulo
      else
        tv.DataController.Values[row, colMotivo.Index] :=
          A.Titulo + '  (pr'#243'ximamente)';
      if not A.Implementada then s := '-'
      else if A.Count = 0 then s := 'OK'
      else s := IntToStr(A.Count);
      tv.DataController.Values[row, colNodos.Index] := s;
      tv.DataController.Values[row, colPeso.Index]  := A.Peso;
    end;
  finally
    tv.EndUpdate;
  end;

  // Contadores sobre el total (no sobre lo filtrado) para el indice de salud.
  totalNodos := 0;
  conIncidencias := 0;
  for A in FAlertas do
    if A.Implementada and (A.Count > 0) then
    begin
      Inc(totalNodos, A.Count);
      Inc(conIncidencias);
    end;

  salud := CalcularSalud(FAlertas, FTotalNodos);

  lblMaxRecords.Caption := Format(
    'Mostrando %d de %d excepciones',
    [Length(FVisibles), Length(FAlertas)]);

  lblResumen.Caption := Format(
    'Salud del plan %d/100 (%s)',
    [salud, EtiquetaSalud(salud)]);

  if salud >= 90 then lblResumen.Font.Color := $00308828
  else if salud >= 75 then lblResumen.Font.Color := $00208020
  else if salud >= 50 then lblResumen.Font.Color := $002090E8
  else lblResumen.Font.Color := clRed;

  // Seleccionar la primera fila con incidencias real.
  for row := 0 to High(FVisibles) do
    if FVisibles[row].Implementada and (FVisibles[row].Count > 0) then
    begin
      tv.DataController.FocusedRecordIndex := row;
      Break;
    end;
end;

// --- Badge (pastilla redondeada) -------------------------------------------

procedure TfrmAlertasViewer.DibujarBadge(const ACanvas: TCanvas;
  const ARect: TRect; const AColor: TColor; const ATexto: string;
  const AAtenuado: Boolean);
var
  G: TGPGraphics;
  brush: TGPSolidBrush;
  bx, by, bw, bh, rad, d: Single;
  tw: Integer;
  fondo: TColor;
begin
  ACanvas.Font.Style := [fsBold];
  tw := ACanvas.TextWidth(ATexto);
  bw := tw + 30;
  bh := 28;
  bx := ARect.Left + 12;                          // padding izquierdo de la celda
  by := (ARect.Top + ARect.Bottom - bh) / 2;
  rad := 9;
  d := rad * 2;

  if AAtenuado then fondo := MezclarConBlanco(AColor, 0.90)
  else fondo := MezclarConBlanco(AColor, 0.82);

  // Rectangulo redondeado: 4 circulos en las esquinas + dos rectangulos en cruz.
  G := TGPGraphics.Create(ACanvas.Handle);
  brush := TGPSolidBrush.Create(GpColorA(fondo, 255));
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.FillEllipse(brush, bx, by, d, d);
    G.FillEllipse(brush, bx + bw - d, by, d, d);
    G.FillEllipse(brush, bx, by + bh - d, d, d);
    G.FillEllipse(brush, bx + bw - d, by + bh - d, d, d);
    G.FillRectangle(brush, bx + rad, by, bw - d, bh);
    G.FillRectangle(brush, bx, by + rad, bw, bh - d);
  finally
    brush.Free;
    G.Free;
  end;

  ACanvas.Brush.Style := bsClear;
  if AAtenuado then ACanvas.Font.Color := CLR_TXT_SOFT
  else ACanvas.Font.Color := MezclarConNegro(AColor, 0.20);
  ACanvas.TextOut(Round(bx + (bw - tw) / 2),
    Round(by + (bh - ACanvas.TextHeight(ATexto)) / 2), ATexto);
  ACanvas.Font.Style := [];
end;

procedure TfrmAlertasViewer.tvCustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  A: TAlertaItem;
  esPendiente, esCumplida: Boolean;
  col: TcxGridColumn;
begin
  if not AlertaDe(AViewInfo.GridRecord.RecordIndex, A) then Exit;

  esPendiente := not A.Implementada;
  esCumplida  := A.Implementada and (A.Count = 0);
  col := TcxGridColumn(AViewInfo.Item);

  // Solo la columna Gravedad se pinta como badge; el resto usa el render por
  // defecto, pero ajustamos el color de texto segun el estado de la fila.
  if col = colGravedad then
  begin
    // Fondo: azul claro si la fila esta seleccionada (igual que el resto de la
    // fila), blanco en otro caso, para que el badge no rompa la seleccion.
    if AViewInfo.Selected and Assigned(FStyleSelection) then
      ACanvas.FillRect(AViewInfo.Bounds, FStyleSelection.Color)
    else
      ACanvas.FillRect(AViewInfo.Bounds, clWhite);
    DibujarBadge(ACanvas.Canvas, AViewInfo.Bounds,
      ColorDeSeveridad(A.Severidad), EtiquetaSeveridad(A.Severidad),
      esPendiente or esCumplida);
    ADone := True;
    Exit;
  end;

  // Columna Nodos con alerta cumplida (Count=0): badge verde "OK".
  if (col = colNodos) and esCumplida then
  begin
    if AViewInfo.Selected and Assigned(FStyleSelection) then
      ACanvas.FillRect(AViewInfo.Bounds, FStyleSelection.Color)
    else
      ACanvas.FillRect(AViewInfo.Bounds, clWhite);
    DibujarBadge(ACanvas.Canvas, AViewInfo.Bounds, $00308828, 'OK', False);
    ADone := True;
    Exit;
  end;

  // Color de texto del resto de columnas segun estado.
  if esPendiente then
    ACanvas.Font.Color := clGrayText
  else if esCumplida then
    ACanvas.Font.Color := CLR_TXT_SOFT
  else if col = colCodigo then
    ACanvas.Font.Color := CLR_LINK            // codigo en azul (enlace)
  else
    ACanvas.Font.Color := CLR_TXT;

  if (col = colCodigo) and not (esPendiente or esCumplida) then
    ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
  if (col = colNodos) and esCumplida then
    ACanvas.Font.Color := $00308828;          // "OK" en verde
end;

procedure TfrmAlertasViewer.ConfirmarSeleccion;
var
  A: TAlertaItem;
begin
  if not AlertaDe(tv.DataController.FocusedRecordIndex, A) then Exit;
  // Solo tiene sentido "ver en el Gantt" alertas implementadas con incidencias.
  if (not A.Implementada) or (A.Count = 0) then Exit;
  FSelectedDataIds := A.DataIds;
  ModalResult := mrOk;
end;

procedure TfrmAlertasViewer.btnVerTodasClick(Sender: TObject);
begin
  // Menu "..." : alterna entre incluir cumplidas o no (releer del proveedor).
  FVerTodas := not FVerTodas;
  RefrescarDesdeProveedor;
end;

procedure TfrmAlertasViewer.btnConfigClick(Sender: TObject);
begin
  if not Assigned(FOnConfig) then Exit;
  FOnConfig();
  RefrescarDesdeProveedor;
end;

procedure TfrmAlertasViewer.FormShow(Sender: TObject);
begin
  FCargando := True;
  try
    ConfigurarEstilos;
    InicializarFiltros;
    lblTitulo.Caption := 'Excepciones detectadas';
  finally
    FCargando := False;
  end;
  RefrescarDesdeProveedor;
  Grid.SetFocus;
end;

procedure TfrmAlertasViewer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_F1 then
  begin
    THelpViewer.Show('uAlertasViewer', 'Alertas de planificaci'#243'n');
    Key := 0;
  end
  else if Key = VK_RETURN then
  begin
    ConfirmarSeleccion;
    Key := 0;
  end;
end;

procedure TfrmAlertasViewer.tvDblClick(Sender: TObject);
begin
  ConfirmarSeleccion;
end;

procedure TfrmAlertasViewer.btnFiltrarClick(Sender: TObject);
begin
  ConfirmarSeleccion;
end;

procedure TfrmAlertasViewer.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
