unit uGanttShortcuts;
// Overlay flotante (semitransparente, sin borde) con el "cheat sheet" de atajos
// de teclado, gestos de raton y acciones principales del Gantt. Se abre con
// Mayus+F1 o el boton '?' de la barra, y se cierra con Esc, click o perdiendo
// el foco. No persiste nada; es solo informativo.
//
// Todo el contenido esta definido en CAT_* (codigo), asi que ampliar/retocar la
// lista es editar un array: la pintura se adapta sola.
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Types, System.UITypes, System.Math, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms;

type
  // Una entrada del cheat sheet: tecla/gesto + descripcion.
  TShortcutItem = record
    Keys: string;     // "Ctrl+Z", "Rueda", "Doble clic"...
    Desc: string;     // que hace
  end;

  // Una seccion (titulo + lista de entradas).
  TShortcutSection = record
    Title: string;
    Items: TArray<TShortcutItem>;
  end;

  TfrmGanttShortcuts = class(TForm)
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClick(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FSections: TArray<TShortcutSection>;
    procedure BuildContent;
    procedure RedimensionarYCentrar;
  public
    // Muestra el overlay centrado sobre AOwner (modal ligero).
    class procedure Execute(AOwner: TComponent);
  end;

implementation

{$R *.dfm}

const
  // Paleta (BGR).
  CLR_BG        = $002A211C;  // fondo oscuro (azulado)
  CLR_CARD      = $00382E27;  // tarjeta de seccion
  CLR_TITLE     = $00E8C893;  // titulo de seccion (acento claro)
  CLR_KEY_BG    = $00504438;  // pastilla de tecla
  CLR_KEY_TXT   = $00FFFFFF;  // texto tecla
  CLR_DESC      = $00D8D8D8;  // descripcion
  CLR_HEADER    = $00FFFFFF;  // titulo principal
  CLR_HINT      = $009A8E80;  // pie

  COL_W   = 360;   // ancho de columna
  COL_GAP = 24;    // separacion entre columnas
  PAD     = 28;    // margen del overlay
  LINE_H  = 26;    // alto de linea por atajo
  SEC_GAP = 18;    // separacion entre secciones
  TITLE_H = 30;    // alto del titulo de seccion

class procedure TfrmGanttShortcuts.Execute(AOwner: TComponent);
var
  F: TfrmGanttShortcuts;
begin
  F := TfrmGanttShortcuts.Create(AOwner);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmGanttShortcuts.BuildContent;
  function It(const AKeys, ADesc: string): TShortcutItem;
  begin
    Result.Keys := AKeys;
    Result.Desc := ADesc;
  end;
  function Sec(const ATitle: string;
    const AItems: array of TShortcutItem): TShortcutSection;
  var
    i: Integer;
  begin
    Result.Title := ATitle;
    SetLength(Result.Items, Length(AItems));
    for i := 0 to High(AItems) do
      Result.Items[i] := AItems[i];
  end;
begin
  FSections := [
    Sec('Navegaci'#243'n y vista', [
      It('Rueda',        'Zoom (alrededor del cursor)'),
      It('Arrastre fondo','Desplazar el Gantt'),
      It('Ctrl+K',       'Compactar centros (solo con carga)'),
      It('Ctrl+E',       'Centrar la OF del nodo en pantalla'),
      It('Ctrl+H',       'Historial (l'#237'nea de tiempo de cambios)')
    ]),
    Sec('Selecci'#243'n y foco', [
      It('Clic',         'Seleccionar nodo'),
      It('Arrastre vac'#237'o','Selecci'#243'n por marco (m'#250'ltiple)'),
      It('Ctrl+F',       'Foco: resaltar la cadena de dependencias'),
      It('Ctrl+R',       'Resaltar toda la OF del nodo'),
      It('Clic fondo',   'Quitar resaltado / foco')
    ]),
    Sec('Edici'#243'n del plan', [
      It('Arrastrar nodo','Mover en el tiempo / de centro'),
      It('Arrastrar borde','Redimensionar (duraci'#243'n)'),
      It('Ctrl+arrastrar borde','Crear enlace de dependencia'),
      It('Ctrl+Z',       'Deshacer'),
      It('Ctrl+Y',       'Rehacer')
    ]),
    Sec('Acciones (clic derecho)', [
      It('Men'#250' nodo',   'Compactar OF/OT, lotes, colores, operarios...'),
      It('Men'#250' centro', 'Propiedades, calendario, marcadores...')
    ]),
    Sec('Ayuda', [
      It('F1',           'Ayuda de la pantalla'),
      It('May'#250's+F1 / ?','Este panel de atajos'),
      It('Esc',          'Cerrar este panel')
    ])
  ];
end;

// Calcula la altura total que ocuparian las secciones repartidas en 2 columnas
// (mismo balanceo que FormPaint) y dimensiona el form en consecuencia.
procedure TfrmGanttShortcuts.RedimensionarYCentrar;
var
  s: Integer;
  colY: array[0..1] of Integer;
  col, hSec, maxY: Integer;
begin
  colY[0] := PAD + 36;
  colY[1] := PAD + 36;
  for s := 0 to High(FSections) do
  begin
    if colY[0] <= colY[1] then col := 0 else col := 1;
    hSec := TITLE_H + Length(FSections[s].Items) * LINE_H + SEC_GAP + 6;
    colY[col] := colY[col] + hSec;
  end;
  maxY := Max(colY[0], colY[1]);

  ClientWidth := PAD * 2 + COL_W * 2 + COL_GAP;
  ClientHeight := maxY + PAD;

  // Centrar manualmente sobre el owner (o pantalla) tras fijar el tamanyo.
  if (Owner is TForm) and TForm(Owner).Visible then
    SetBounds(
      TForm(Owner).Left + (TForm(Owner).Width - Width) div 2,
      TForm(Owner).Top + (TForm(Owner).Height - Height) div 2,
      Width, Height)
  else
    SetBounds(
      (Screen.Width - Width) div 2,
      (Screen.Height - Height) div 2,
      Width, Height);
end;

procedure TfrmGanttShortcuts.FormShow(Sender: TObject);
begin
  BuildContent;
  RedimensionarYCentrar;
  Invalidate;
end;

procedure TfrmGanttShortcuts.FormPaint(Sender: TObject);
var
  cv: TCanvas;
  s, i, col: Integer;
  x, y: Integer;
  colX: array[0..1] of Integer;
  colY: array[0..1] of Integer;
  sec: TShortcutSection;
  item: TShortcutItem;
  keyW, keyH: Integer;
  r: TRect;
begin
  cv := Canvas;

  // Fondo redondeado.
  cv.Brush.Color := CLR_BG;
  cv.Pen.Style := psClear;
  cv.FillRect(ClientRect);

  // Titulo principal.
  cv.Brush.Style := bsClear;
  cv.Font.Name := 'Segoe UI';
  cv.Font.Color := CLR_HEADER;
  cv.Font.Size := 15;
  cv.Font.Style := [fsBold];
  cv.TextOut(PAD, PAD - 6, 'Atajos y gestos del Gantt');

  // Dos columnas; repartimos secciones alternando para equilibrar.
  colX[0] := PAD;
  colX[1] := PAD + COL_W + COL_GAP;
  colY[0] := PAD + 36;
  colY[1] := PAD + 36;

  for s := 0 to High(FSections) do
  begin
    sec := FSections[s];
    // Columna con menos altura ocupada (balanceo simple).
    if colY[0] <= colY[1] then col := 0 else col := 1;
    x := colX[col];
    y := colY[col];

    // Tarjeta de seccion (fondo).
    r := Rect(x - 10, y - 6, x + COL_W - 4,
      y + TITLE_H + Length(sec.Items) * LINE_H + 6);
    cv.Brush.Style := bsSolid;
    cv.Brush.Color := CLR_CARD;
    cv.Pen.Style := psClear;
    cv.RoundRect(r.Left, r.Top, r.Right, r.Bottom, 12, 12);
    cv.Brush.Style := bsClear;

    // Titulo de seccion.
    cv.Font.Color := CLR_TITLE;
    cv.Font.Size := 10;
    cv.Font.Style := [fsBold];
    cv.TextOut(x, y, sec.Title);
    y := y + TITLE_H;

    // Entradas.
    for i := 0 to High(sec.Items) do
    begin
      item := sec.Items[i];

      // Pastilla de tecla.
      cv.Font.Size := 9;
      cv.Font.Style := [fsBold];
      keyW := cv.TextWidth(item.Keys) + 16;
      keyH := 18;
      cv.Brush.Style := bsSolid;
      cv.Brush.Color := CLR_KEY_BG;
      cv.Pen.Style := psClear;
      cv.RoundRect(x, y + 2, x + keyW, y + 2 + keyH, 8, 8);
      cv.Brush.Style := bsClear;
      cv.Font.Color := CLR_KEY_TXT;
      cv.TextOut(x + 8, y + 3, item.Keys);

      // Descripcion.
      cv.Font.Style := [];
      cv.Font.Color := CLR_DESC;
      cv.TextOut(x + keyW + 10, y + 3, item.Desc);

      y := y + LINE_H;
    end;

    y := y + SEC_GAP;
    colY[col] := y;
  end;

  // Pie.
  cv.Font.Color := CLR_HINT;
  cv.Font.Size := 8;
  cv.Font.Style := [];
  cv.TextOut(PAD, ClientHeight - PAD + 4,
    'Pulsa Esc o haz clic para cerrar');
end;

procedure TfrmGanttShortcuts.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) or (Key = VK_F1) then
  begin
    ModalResult := mrCancel;
    Key := 0;
  end;
end;

procedure TfrmGanttShortcuts.FormClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmGanttShortcuts.FormDeactivate(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
