unit uOptimizacionHub;

{ ============================================================================
  HUB / LANZADOR de la suite de OPTIMIZACION DE CORTE.

  Pantalla inicial de una pagina con una TARJETA por herramienta (nombre, que
  resuelve, sectores). Las herramientas DISPONIBLES abren su modulo; las de
  ROADMAP se muestran como "Proximamente" (atenuadas, informativas).

  Ampliar = anadir una fila a la tabla de metadatos FTools en FormCreate.

  Entrada: ShowOptimizacionHub(AOwner).
  ============================================================================ }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxScrollBox, cxClasses;

type
  TToolKind = (tkTrueShape2D, tkRectangular2D, tkCuttingStock1D, tkGuillotine,
    tkCoilSlitting, tkTrimLoss, tkCommonLine, tkCutPath, tkToolpath);

  TToolDef = record
    Kind: TToolKind;
    Titulo: string;
    Resuelve: string;
    Sectores: string;
    Disponible: Boolean;
  end;

  TfrmOptimizacionHub = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    sbTools: TcxScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    FTools: TArray<TToolDef>;
    FCards: TArray<TPanel>;
    FSelectedKind: TToolKind;
    procedure BuildTools;
    procedure BuildCards;
    procedure LayoutCards;
    procedure CardClick(Sender: TObject);
  public
    property SelectedKind: TToolKind read FSelectedKind;
  end;

function ShowOptimizacionHub(AOwner: TForm): Boolean;

implementation

{$R *.dfm}

uses
  Vcl.Dialogs, uNesting2D;

const
  CARD_W = 340;
  CARD_H = 132;
  CARD_GAP = 16;
  COL_ACCENT_OK = TColor($00A7794E);      // azul corporativo (BGR de RGB 4E79A7)
  COL_ACCENT_SOON = TColor($00BAB0AC);    // gris (proximamente)

function ShowOptimizacionHub(AOwner: TForm): Boolean;
var
  F: TfrmOptimizacionHub;
  Kind: TToolKind;
begin
  Result := False;
  F := TfrmOptimizacionHub.Create(AOwner);
  try
    if F.ShowModal <> mrOk then Exit;
    Kind := F.SelectedKind;
  finally
    F.Free;   // el hub se cierra ANTES de abrir la herramienta
  end;

  // La herramienta se abre despues, con el hub ya cerrado: queda solo la
  // herramienta en pantalla.
  case Kind of
    tkTrueShape2D:   ShowNesting2D(AOwner, nmTrueShape);
    tkRectangular2D: ShowNesting2D(AOwner, nmRectangular);
  else
    Exit;
  end;
  Result := True;
end;

{ ------------------------------------------------------------ metadatos --- }

procedure TfrmOptimizacionHub.BuildTools;
  procedure Add(AKind: TToolKind; const ATit, ARes, ASec: string; ADisp: Boolean);
  var
    T: TToolDef;
  begin
    T.Kind := AKind; T.Titulo := ATit; T.Resuelve := ARes;
    T.Sectores := ASec; T.Disponible := ADisp;
    FTools := FTools + [T];
  end;
begin
  SetLength(FTools, 0);
  Add(tkTrueShape2D, 'True-Shape Nesting 2D',
    'Encaja formas irregulares, con rotaciones y separaciones de corte.',
    'Chapa, textil, piel, composites, pl'#225'stico', True);
  Add(tkRectangular2D, 'Rectangular Nesting 2D',
    'Distribuye piezas rectangulares sobre planxas.',
    'Madera, vidrio, cart'#243'n, mobiliario', True);
  Add(tkCuttingStock1D, 'Cutting Stock 1D',
    'Corta barras, tubos, perfiles o bobinas minimizando sobrantes.',
    'Aluminio, acero, madera, PVC, cableado', False);
  Add(tkGuillotine, 'Guillotine Cutting',
    'Cortes que atraviesan toda la planxa (sierras).',
    'Madera, vidrio, papel, paneles', False);
  Add(tkCoilSlitting, 'Coil Slitting',
    'Divide el ancho de una bobina en tiras m'#225's estrechas.',
    'Acero, papel, film pl'#225'stico, aluminio', False);
  Add(tkTrimLoss, 'Trim-Loss Optimization',
    'Minimiza la p'#233'rdida lateral/longitudinal en formatos continuos.',
    'Papel, pl'#225'stico, textil, metal', False);
  Add(tkCommonLine, 'Common-Line Cutting',
    'Hace que dos piezas compartan una l'#237'nea de corte.',
    'L'#225'ser, plasma, oxicorte, madera', False);
  Add(tkCutPath, 'Cut-Path Optimization',
    'Ordena los cortes para reducir movimientos en vac'#237'o y tiempos.',
    'L'#225'ser, plasma, agua, CNC', False);
  Add(tkToolpath, 'Toolpath Optimization',
    'Recorridos eficientes de mecanizado seg'#250'n herramienta y geometr'#237'a.',
    'CNC, moldes, matriceria', False);
end;

{ ------------------------------------------------------------ tarjetas --- }

procedure TfrmOptimizacionHub.BuildCards;
var
  I: Integer;
  Card: TPanel;
  L: TLabel;
  Accent: TPanel;
  Estado: TLabel;
begin
  SetLength(FCards, Length(FTools));
  for I := 0 to High(FTools) do
  begin
    Card := TPanel.Create(Self);
    Card.Parent := sbTools;
    Card.BevelOuter := bvNone;
    Card.BorderStyle := bsSingle;
    Card.Width := CARD_W;
    Card.Height := CARD_H;
    Card.ParentBackground := False;
    Card.Tag := I;
    Card.OnClick := CardClick;
    // Disponibles: fondo blanco, clicables (mano). Proximamente: fondo gris
    // apagado, cursor normal, para que "pesen" menos visualmente.
    if FTools[I].Disponible then
    begin
      Card.Color := clWhite;
      Card.Cursor := crHandPoint;
    end
    else
    begin
      Card.Color := TColor($00F0F0F0);   // gris muy claro
      Card.Cursor := crDefault;
    end;

    // Barra de acento a la izquierda: mas ancha y viva en las disponibles.
    Accent := TPanel.Create(Self);
    Accent.Parent := Card;
    Accent.Align := alLeft;
    Accent.BevelOuter := bvNone;
    Accent.ParentBackground := False;
    if FTools[I].Disponible then
    begin
      Accent.Width := 10;
      Accent.Color := COL_ACCENT_OK;
    end
    else
    begin
      Accent.Width := 4;
      Accent.Color := COL_ACCENT_SOON;
    end;

    // Titulo.
    L := TLabel.Create(Self);
    L.Parent := Card;
    L.Left := 18; L.Top := 12;
    L.Font.Height := -15;
    L.Font.Name := 'Segoe UI Semibold';
    if FTools[I].Disponible then L.Font.Color := clBlack
    else L.Font.Color := clGrayText;
    L.Caption := FTools[I].Titulo;
    L.Tag := I; L.OnClick := CardClick; L.Cursor := Card.Cursor;

    // Estado (Disponible / Proximamente). En disponibles, llamada a la accion.
    Estado := TLabel.Create(Self);
    Estado.Parent := Card;
    Estado.Left := 18; Estado.Top := 36;
    Estado.Font.Height := -11;
    Estado.Font.Style := [fsBold];
    if FTools[I].Disponible then
    begin
      Estado.Caption := 'DISPONIBLE  '#9654' Abrir';
      Estado.Font.Color := COL_ACCENT_OK;
      Estado.Cursor := crHandPoint;
      Estado.OnClick := CardClick;
    end
    else
    begin
      Estado.Caption := 'PR'#211'XIMAMENTE';
      Estado.Font.Color := clGrayText;
    end;
    Estado.Tag := I;

    // Descripcion (que resuelve).
    L := TLabel.Create(Self);
    L.Parent := Card;
    L.Left := 18; L.Top := 56;
    L.Width := CARD_W - 34;
    L.AutoSize := False;
    L.Height := 40;
    L.WordWrap := True;
    L.Font.Height := -12;
    L.Font.Color := clWindowText;
    L.Caption := FTools[I].Resuelve;
    L.Tag := I; L.OnClick := CardClick; L.Cursor := Card.Cursor;

    // Sectores.
    L := TLabel.Create(Self);
    L.Parent := Card;
    L.Left := 18; L.Top := CARD_H - 26;
    L.Width := CARD_W - 34;
    L.AutoSize := False;
    L.Font.Height := -11;
    L.Font.Color := clGrayText;
    L.Caption := FTools[I].Sectores;
    L.Tag := I; L.OnClick := CardClick; L.Cursor := Card.Cursor;

    FCards[I] := Card;
  end;
end;

procedure TfrmOptimizacionHub.LayoutCards;
var
  I, Cols, Col, Row, X, Y, AvailW: Integer;
begin
  if Length(FCards) = 0 then Exit;
  AvailW := sbTools.ClientWidth - CARD_GAP;
  Cols := Max(1, AvailW div (CARD_W + CARD_GAP));
  for I := 0 to High(FCards) do
  begin
    Col := I mod Cols;
    Row := I div Cols;
    X := CARD_GAP + Col * (CARD_W + CARD_GAP);
    Y := CARD_GAP + Row * (CARD_H + CARD_GAP);
    FCards[I].SetBounds(X, Y, CARD_W, CARD_H);
  end;
end;

procedure TfrmOptimizacionHub.FormResize(Sender: TObject);
begin
  LayoutCards;
end;

procedure TfrmOptimizacionHub.CardClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := (Sender as TControl).Tag;
  if (Idx < 0) or (Idx > High(FTools)) then Exit;
  if not FTools[Idx].Disponible then
  begin
    ShowMessage('Esta herramienta estar'#225' disponible pr'#243'ximamente.');
    Exit;
  end;
  // Guardar la eleccion y cerrar el hub: quien lo abrio (Main) lanzara la
  // herramienta. Asi el hub desaparece y queda la herramienta abierta.
  FSelectedKind := FTools[Idx].Kind;
  ModalResult := mrOk;
end;

procedure TfrmOptimizacionHub.FormCreate(Sender: TObject);
begin
  BuildTools;
  BuildCards;
  LayoutCards;
end;

end.
