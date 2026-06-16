unit uAlertasViewer;
// Dialogo modal (bsDialog) que muestra el listado de alertas de planificacion
// detectadas por uGanttAlertas. Cada fila = un tipo de alerta con su contador y
// una marca de color por severidad. Al hacer doble clic (o "Ver en Gantt") sobre
// una alerta, el form se cierra con mrOk y expone los DataIds de los nodos
// afectados para que el caller los filtre/resalte en el Gantt.
//
// Ayuda contextual via THelpViewer (topic 'uAlertasViewer'), patron MD a disco.
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Types, System.UITypes, System.Generics.Collections,
  System.Generics.Defaults, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ImgList,
  Winapi.GDIPOBJ, Winapi.GDIPAPI,
  cxControls, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxListView,
  uGanttAlertas, System.ImageList, dxSkinsCore, dxSkinBasic, dxSkinBlack,
  dxSkinBlue, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
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
  dxSkinXmas2008Blue, cxContainer, cxEdit;

type
  // Proveedor de alertas: el caller lo implementa (delega en uGanttAlertas).
  //   AIncluirCumplidas = True -> incluye tambien los tipos sin incidencias.
  TAlertasProvider = reference to function(
    const AIncluirCumplidas: Boolean): TArray<TAlertaItem>;

  TfrmAlertasViewer = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblSalud: TLabel;
    btnVerTodas: TButton;
    btnConfig: TButton;
    lvAlertas: TcxListView;
    pnlBottom: TPanel;
    lblResumen: TLabel;
    btnFiltrar: TButton;
    btnCerrar: TButton;
    ilSeveridad: TImageList;
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnFiltrarClick(Sender: TObject);
    procedure btnVerTodasClick(Sender: TObject);
    procedure btnConfigClick(Sender: TObject);
    procedure lvAlertasDblClick(Sender: TObject);
    procedure lvAlertasColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvAlertasDrawItem(Sender: TCustomListView; Item: TListItem;
      Rect: TRect; State: TOwnerDrawState);
  private
    FAlertas: TArray<TAlertaItem>;
    FSelectedDataIds: TArray<Integer>;
    FVerTodas: Boolean;                  // estado del toggle "Ver todas"
    FRedetectar: TAlertasProvider;       // recalcula segun AIncluirCumplidas
    FSortCol: Integer;                   // columna de orden (-1 = orden natural)
    FSortDesc: Boolean;                  // True = descendente
    FOnConfig: TProc;                    // abre la config (lo provee el caller)
    FTotalNodos: Integer;                // nodos visibles, para el indice de salud
    procedure OrdenarAlertas;            // reordena FAlertas segun FSortCol/Desc
    procedure OcultarScrollHorizontal;   // oculta la barra horizontal del listview
    procedure Poblar;
    function ColorDeSeveridad(const ASev: TAlertaSeveridad): TColor;
    procedure ConfirmarSeleccion;
    procedure RefrescarDesdeProveedor;
    // Dibuja la marca de estado (icono PRO, antialias GDI+) en ARect.
    procedure DibujarMarcaEstado(const ACanvas: TCanvas; const ARect: TRect;
      const A: TAlertaItem; const AEsPendiente, AEsCumplida: Boolean);
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
  COL_ALTA  = $003B3BD0;  // rojo  (BGR)
  COL_MEDIA = $002090E8;  // naranja
  COL_AVISO = $0020B0E0;  // amarillo/ambar
  COL_INFO  = $00B08020;  // azul/info

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
    F.FSortCol := -1;       // orden natural (por severidad/estado)
    F.FSortDesc := False;
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
  OrdenarAlertas;   // respeta el orden de columna activo (si lo hay)
  Poblar;
end;

// Rango de estado para ordenar la columna de marca: incidencia(0) antes que
// cumplida(1) antes que pendiente(2), igual que el orden natural visible.
function RangoEstado(const A: TAlertaItem): Integer;
begin
  if not A.Implementada then Result := 2
  else if A.Count > 0 then Result := 0
  else Result := 1;
end;

procedure TfrmAlertasViewer.OrdenarAlertas;
const
  CAPS: array[0..4] of string = ('', 'C'#243'd.', 'Peso', 'N', 'Alerta');
var
  C: Integer;
  flecha: string;
begin
  // Indicador visual de orden en los headers (flecha en la columna activa).
  for C := 0 to lvAlertas.Columns.Count - 1 do
  begin
    if (C = FSortCol) and (FSortCol >= 0) and (C <= High(CAPS)) then
    begin
      if FSortDesc then flecha := '  '#$25BC else flecha := '  '#$25B2;
      lvAlertas.Columns[C].Caption := CAPS[C] + flecha;
    end
    else if C <= High(CAPS) then
      lvAlertas.Columns[C].Caption := CAPS[C];
  end;

  // FSortCol = -1 -> orden natural (el que ya trae el proveedor: por estado y
  // peso). En otro caso, ordena por la columna clicada (asc/desc).
  if FSortCol < 0 then Exit;

  TArray.Sort<TAlertaItem>(FAlertas, TComparer<TAlertaItem>.Construct(
    function(const L, R: TAlertaItem): Integer
    begin
      case FSortCol of
        // Marca: por estado (incidencia/cumplida/pendiente) y, dentro, por peso.
        0: begin
             Result := RangoEstado(L) - RangoEstado(R);
             if Result = 0 then Result := R.Peso - L.Peso;
           end;
        1:   Result := CompareText(L.Codigo, R.Codigo);   // codigo
        2:   Result := L.Peso - R.Peso;                   // peso
        3:   Result := L.Count - R.Count;                 // contador
        4:   Result := CompareText(L.Titulo, R.Titulo);   // alerta
      else
        Result := 0;
      end;
      if Result = 0 then  // desempate estable por codigo
        Result := CompareText(L.Codigo, R.Codigo);
      if FSortDesc then
        Result := -Result;
    end));
end;

procedure TfrmAlertasViewer.lvAlertasColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  // Click en la misma columna -> alterna asc/desc; en otra -> asc.
  if FSortCol = Column.Index then
    FSortDesc := not FSortDesc
  else
  begin
    FSortCol := Column.Index;
    FSortDesc := False;
  end;
  OrdenarAlertas;
  Poblar;
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

procedure TfrmAlertasViewer.Poblar;
var
  A: TAlertaItem;
  Li: TListItem;
  totalNodos, conIncidencias, I, salud: Integer;
begin
  lvAlertas.Items.BeginUpdate;
  try
    lvAlertas.Items.Clear;
    totalNodos := 0;
    conIncidencias := 0;
    for A in FAlertas do
    begin
      Li := lvAlertas.Items.Add;
      Li.Caption := '';                      // col 0: marca de color (owner-draw)
      Li.SubItems.Add(A.Codigo);             // col 1: codigo (A01...)
      Li.SubItems.Add(IntToStr(A.Peso));     // col 2: peso
      // Pendientes sin contador (roadmap); implementadas con su numero.
      if A.Implementada then
        Li.SubItems.Add(IntToStr(A.Count))   // col 3: contador
      else
        Li.SubItems.Add('-');
      Li.SubItems.Add(A.Titulo);             // col 4: descripcion
      Li.Data := Pointer(Ord(A.Tipo));
      if A.Implementada and (A.Count > 0) then
      begin
        Inc(totalNodos, A.Count);
        Inc(conIncidencias);
      end;
    end;
  finally
    lvAlertas.Items.EndUpdate;
  end;

  // Indice de salud del plan (0..100): bajo el titulo, en color segun el grado.
  salud := CalcularSalud(FAlertas, FTotalNodos);
  lblSalud.Caption := Format('Salud del plan %d/100 (%s)',
    [salud, EtiquetaSalud(salud)]);
  if salud >= 90 then lblSalud.Font.Color := $00308828        // verde
  else if salud >= 75 then lblSalud.Font.Color := $00208020   // verde oscuro
  else if salud >= 50 then lblSalud.Font.Color := $002090E8   // naranja
  else lblSalud.Font.Color := clRed;                          // rojo (malo/critico)

  // En pnlBottom, solo el detalle de incidencias.
  if conIncidencias = 0 then
    lblResumen.Caption := 'Sin incidencias activas. '#161'Planificaci'#243'n correcta!'
  else
    lblResumen.Caption := Format(
      '%d tipos con incidencias, %d nodos afectados.  ' +
      'Doble clic para verlos en el Gantt.',
      [conIncidencias, totalNodos]);

  // Seleccionar la primera alerta con incidencias real (no una cumplida/pendiente).
  for I := 0 to High(FAlertas) do
    if FAlertas[I].Implementada and (FAlertas[I].Count > 0) then
    begin
      lvAlertas.Items[I].Selected := True;
      Break;
    end;

  // La columna 'Alerta' es AutoSize, asi que el ancho total nunca excede el
  // cliente; pero el listview puede mostrar igualmente la barra horizontal por
  // calculo interno. La forzamos oculta tras repoblar.
  OcultarScrollHorizontal;
end;

procedure TfrmAlertasViewer.OcultarScrollHorizontal;
begin
  // El owner-draw + AutoSize puede dejar una barra horizontal residual. La
  // ocultamos directamente sobre el handle del listview interno del cxListView.
  if lvAlertas.InnerListView.HandleAllocated then
    ShowScrollBar(lvAlertas.InnerListView.Handle, SB_HORZ, False);
end;

// Convierte un TColor (BGR) a ARGB de GDI+ opaco.
function GpColor(const AColor: TColor): TGPColor;
var
  rgb: Integer;
begin
  rgb := ColorToRGB(AColor);
  Result := MakeColor(255, GetRValue(rgb), GetGValue(rgb), GetBValue(rgb));
end;

procedure TfrmAlertasViewer.DibujarMarcaEstado(const ACanvas: TCanvas;
  const ARect: TRect; const A: TAlertaItem;
  const AEsPendiente, AEsCumplida: Boolean);
var
  G: TGPGraphics;
  Brush: TGPSolidBrush;
  Pen: TGPPen;
  cx, cy, rad: Single;
  tri: array[0..2] of TGPPointF;
  tick: array[0..2] of TGPPointF;
begin
  cx := (ARect.Left + ARect.Right) / 2;
  cy := (ARect.Top + ARect.Bottom) / 2;
  rad := 9;

  G := TGPGraphics.Create(ACanvas.Handle);
  Brush := TGPSolidBrush.Create(MakeColor(0, 0, 0, 0));
  Pen := TGPPen.Create(MakeColor(255, 255, 255, 255), 2.2);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    Pen.SetStartCap(LineCapRound);
    Pen.SetEndCap(LineCapRound);
    Pen.SetLineJoin(LineJoinRound);

    if AEsPendiente then
    begin
      // Reloj: disco gris claro con borde gris + dos manecillas.
      Brush.SetColor(MakeColor(255, 228, 228, 228));
      G.FillEllipse(Brush, cx - rad, cy - rad, rad * 2, rad * 2);
      Pen.SetColor(MakeColor(255, 130, 130, 130));
      Pen.SetWidth(1.4);
      G.DrawEllipse(Pen, cx - rad, cy - rad, rad * 2, rad * 2);
      Pen.SetColor(MakeColor(255, 96, 96, 96));
      Pen.SetWidth(1.6);
      G.DrawLine(Pen, cx, cy, cx, cy - rad + 3);     // manecilla larga
      G.DrawLine(Pen, cx, cy, cx + 4, cy);           // manecilla corta
    end
    else if AEsCumplida then
    begin
      // Disco verde con tic blanco.
      Brush.SetColor(MakeColor(255, 40, 136, 48));
      G.FillEllipse(Brush, cx - rad, cy - rad, rad * 2, rad * 2);
      Pen.SetColor(MakeColor(255, 255, 255, 255));
      Pen.SetWidth(2.2);
      tick[0] := MakePoint(cx - 4.0, cy + 0.5);
      tick[1] := MakePoint(cx - 1.0, cy + 3.5);
      tick[2] := MakePoint(cx + 4.5, cy - 3.5);
      G.DrawLines(Pen, PGPPointF(@tick[0]), Length(tick));
    end
    else if A.Severidad = asAlta then
    begin
      // Triangulo de aviso con "!" blanco.
      Brush.SetColor(GpColor(ColorDeSeveridad(A.Severidad)));
      tri[0] := MakePoint(cx, cy - rad);
      tri[1] := MakePoint(cx - rad, cy + rad - 1);
      tri[2] := MakePoint(cx + rad, cy + rad - 1);
      G.FillPolygon(Brush, PGPPointF(@tri[0]), Length(tri));
      Pen.SetColor(MakeColor(255, 255, 255, 255));
      Pen.SetWidth(2.0);
      G.DrawLine(Pen, cx, cy - 3, cx, cy + 2);       // barra "!"
      Brush.SetColor(MakeColor(255, 255, 255, 255));
      G.FillEllipse(Brush, cx - 1.1, cy + 4, 2.2, 2.2); // punto "!"
    end
    else
    begin
      // Disco de color (media/aviso/info) con "!" blanco.
      Brush.SetColor(GpColor(ColorDeSeveridad(A.Severidad)));
      G.FillEllipse(Brush, cx - rad, cy - rad, rad * 2, rad * 2);
      Pen.SetColor(MakeColor(255, 255, 255, 255));
      Pen.SetWidth(2.0);
      G.DrawLine(Pen, cx, cy - 4, cx, cy + 1);       // barra "!"
      Brush.SetColor(MakeColor(255, 255, 255, 255));
      G.FillEllipse(Brush, cx - 1.1, cy + 3, 2.2, 2.2); // punto "!"
    end;
  finally
    Pen.Free;
    Brush.Free;
    G.Free;
  end;
end;

procedure TfrmAlertasViewer.lvAlertasDrawItem(Sender: TCustomListView;
  Item: TListItem; Rect: TRect; State: TOwnerDrawState);
var
  cv: TCanvas;
  A: TAlertaItem;
  r0, r1, r2, r3, r4: TRect;
  s: string;
  esPendiente, esCumplida: Boolean;
begin
  cv := Sender.Canvas;

  if (Item.Index < 0) or (Item.Index > High(FAlertas)) then
  begin
    cv.Brush.Color := clWhite;
    cv.FillRect(Rect);
    Exit;
  end;
  A := FAlertas[Item.Index];

  // Clasificacion de la fila por estado:
  //   pendiente  -> gris, cursiva, texto "Pendiente" (roadmap).
  //   cumplida   -> verde tenue (implementada con Count=0).
  //   incidencia -> color de severidad (implementada con Count>0).
  esPendiente := not A.Implementada;
  esCumplida  := A.Implementada and (A.Count = 0);

  // Fondo (seleccion). Las pendientes no se resaltan al seleccionar.
  if (odSelected in State) and not esPendiente then
    cv.Brush.Color := $00F2E6D8   // selección suave
  else
    cv.Brush.Color := clWhite;
  cv.FillRect(Rect);

  // Color de texto segun estado.
  if esPendiente then
    cv.Font.Color := clGrayText           // desactivado
  else if esCumplida then
    cv.Font.Color := $00707070            // gris medio
  else
    cv.Font.Color := clBlack;

  // Columna 0: icono de estado PRO (antialias GDI+).
  r0 := Rect;
  r0.Right := r0.Left + lvAlertas.Columns[0].Width;
  DibujarMarcaEstado(cv, r0, A, esPendiente, esCumplida);

  cv.Brush.Style := bsClear;

  // Columna 1: codigo (A01...), en negrita.
  r1 := Rect;
  r1.Left := r0.Right + 4;
  r1.Right := r0.Right + lvAlertas.Columns[1].Width;
  cv.Font.Style := [fsBold];
  cv.TextRect(r1, A.Codigo, [tfLeft, tfVerticalCenter, tfSingleLine]);

  // Columna 2: peso (alineado a la derecha, normal).
  r2 := Rect;
  r2.Left := r0.Right + lvAlertas.Columns[1].Width;
  r2.Right := r2.Left + lvAlertas.Columns[2].Width;
  cv.Font.Style := [];
  s := IntToStr(A.Peso);
  cv.TextRect(r2, s, [tfRight, tfVerticalCenter, tfSingleLine]);

  // Columna 3: contador (negrita; "-" en pendientes, "OK" en cumplidas).
  r3 := Rect;
  r3.Left := r2.Right;
  r3.Right := r3.Left + lvAlertas.Columns[3].Width;
  cv.Font.Style := [fsBold];
  if esPendiente then s := '-'
  else if esCumplida then s := 'OK'
  else s := IntToStr(A.Count);
  cv.TextRect(r3, s, [tfRight, tfVerticalCenter, tfSingleLine]);

  // Columna 4: titulo (cursiva si pendiente).
  r4 := Rect;
  r4.Left := r3.Right + 8;
  if esPendiente then
  begin
    cv.Font.Style := [fsItalic];
    s := A.Titulo + '  (pr'#243'ximamente)';
  end
  else
  begin
    cv.Font.Style := [];
    s := A.Titulo;
  end;
  cv.TextRect(r4, s, [tfLeft, tfVerticalCenter, tfSingleLine, tfEndEllipsis]);
  cv.Brush.Style := bsSolid;
end;

procedure TfrmAlertasViewer.ConfirmarSeleccion;
var
  idx: Integer;
begin
  idx := lvAlertas.ItemIndex;
  if (idx < 0) or (idx > High(FAlertas)) then Exit;
  // Solo tiene sentido "ver en el Gantt" alertas implementadas con incidencias.
  if (not FAlertas[idx].Implementada) or (FAlertas[idx].Count = 0) then Exit;
  FSelectedDataIds := FAlertas[idx].DataIds;
  ModalResult := mrOk;
end;

procedure TfrmAlertasViewer.btnVerTodasClick(Sender: TObject);
begin
  FVerTodas := not FVerTodas;
  if FVerTodas then
    btnVerTodas.Caption := 'Solo incidencias'
  else
    btnVerTodas.Caption := 'Ver todas';
  RefrescarDesdeProveedor;
end;

procedure TfrmAlertasViewer.btnConfigClick(Sender: TObject);
begin
  if not Assigned(FOnConfig) then Exit;
  FOnConfig();                  // el caller abre la config y guarda
  RefrescarDesdeProveedor;      // releer con los nuevos pesos/activas
end;

procedure TfrmAlertasViewer.FormShow(Sender: TObject);
begin
  RefrescarDesdeProveedor;
  lvAlertas.SetFocus;
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
    // ConfirmarSeleccion solo actua sobre una alerta valida (implementada con
    // incidencias); seguro llamarlo sin comprobar el foco del cxListView.
    ConfirmarSeleccion;
    Key := 0;
  end;
end;

procedure TfrmAlertasViewer.lvAlertasDblClick(Sender: TObject);
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
